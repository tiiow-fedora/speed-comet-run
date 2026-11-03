local ENV = setmetatable({ ARGS = ARGS, __exists = __exists, __loadfile = __loadfile }, { __index = _G })
local M = __loadfile(ARGS[1] .. "/tools/luau_harness/mock.lua", ENV)()
local ROOT = ARGS[1]
local task, workspace = M.task, M.workspace
local Vector3, CFrame = M.globals.Vector3, M.globals.CFrame

local pass, fail = 0, 0
local function check(name, cond, detail)
	if cond then pass = pass + 1; print("PASS " .. name) else fail = fail + 1; print("FAIL " .. name .. (detail ~= nil and (" :: " .. tostring(detail)) or "")) end
end

local test = function()
	local Config = M.require(M.sharedDir.Config)
	-- stubs for Studio-only / instance-heavy modules
	local stages = {}
	for i, st in ipairs(Config.Stages) do
		stages[i] = { Index = i, StartZ = (i - 1) * 300 + 40, GateZ = i * 300 - 100, PadZ = i * 300 - 60, PadRadius = 11, Req = st.Req, Wins = st.Wins }
	end
	local shards = {}
	for k = 1, 40 do shards[k] = { Id = "1_" .. k, Pos = Vector3.new(0, 203, 30 + k * 6) } end
	local layout = { Stages = stages, Shards = shards, SpawnCFrame = CFrame.lookAt(Vector3.new(0, 204, -20), Vector3.new(0, 204, 100)), EndZ = 5000, PartCount = 1500 }
	M.stub("MapBuilder.luau", { build = function() return layout end })
	M.stub("Leaderboard.luau", { build = function() end, start = function() end, submit = function() end, submitTo = function() end })
	M.stub("PropLoader.luau", { load = function() end })
	workspace.Map = M.inst("Folder", "Map"); workspace.Map.Parent = workspace

	-- run the real server entry point
	local mainFn = __loadfile(ROOT .. "/src/server/Main.server.luau", setmetatable({ script = M.serverDir.Main, require = M.require }, { __index = M.globals }))
	-- Main.server uses script.Parent.X
	M.serverDir.Main = { Name = "Main", Parent = M.serverDir }
	local menv = setmetatable({ script = { Name = "Main", Parent = M.serverDir }, require = M.require }, { __index = M.globals })
	mainFn = __loadfile(ROOT .. "/src/server/Main.server.luau", menv)
	mainFn()
	check("server entry point ran", true)

	local RS = M.game:GetService("ReplicatedStorage")
	local Players = M.game:GetService("Players")
	local remotes = RS:FindFirstChild("Remotes")
	check("remotes created incl. v4", remotes and remotes:FindFirstChild("BuyPet") and remotes:FindFirstChild("EquipPet") and remotes:FindFirstChild("ClaimGift") and remotes:FindFirstChild("ClaimQuest"))

	local DataService = M.require(M.serverDir.DataService)
	local Quests = M.require(M.serverDir.Quests)
	local Goal = M.require(M.serverDir.Goal)
	local Gifts = M.require(M.serverDir.Gifts)
	local Gameplay = M.require(M.serverDir.Gameplay)

	local function join(name)
		local plr, hrp = M.newPlayer(name)
		plr.Parent = Players
		Players.PlayerAdded:Fire(plr)
		M.advance(0.5)
		return plr, hrp
	end
	local p1, hrp1 = join("Alice")
	local prof = DataService.get(p1)
	check("profile exists with v4 defaults", prof and prof.Pet == 0 and type(prof.Pets) == "table" and prof.GiftSeconds >= 0, prof and prof.Pet)
	check("player marked loaded", p1:GetAttribute("Loaded") == true)
	check("v4 attrs after join", p1:GetAttribute("Pet") == 0 and p1:GetAttribute("OwnedPets") == "" and p1:GetAttribute("GiftReady") == false and p1:GetAttribute("TrioDone") == false)
	check("3 quests assigned", #prof.Quests == 3)
	check("goal attrs published", RS:GetAttribute("GoalTarget") == Config.GoalTarget(1) and RS:GetAttribute("GoalProgress") == 0)

	-- speed tick baseline
	prof.Speed = 0
	M.advance(3)
	local base = prof.Speed
	check("speed ticks (~1/s x1)", base >= 2 and base <= 4.5, base)

	-- companions through the real remotes
	prof.Wins = 10
	remotes.BuyPet.OnServerEvent:Fire(p1, 1)
	M.advance(0.1)
	check("pet purchase rejected when poor", prof.Pet == 0 and prof.Wins == 10)
	prof.Wins = 1200
	remotes.BuyPet.OnServerEvent:Fire(p1, 2)
	M.advance(0.1)
	check("pet 2 bought via remote", prof.Pet == 2 and prof.Pets["2"] and prof.Wins == 200 and p1:GetAttribute("Pet") == 2 and p1:GetAttribute("OwnedPets") == "2", prof.Wins)
	local s0 = prof.Speed
	M.advance(4)
	local gain = (prof.Speed - s0) / 4
	check("pet bonus raises gain by 25%", math.abs(gain - 1.25) < 0.01, gain)
	remotes.BuyPet.OnServerEvent:Fire(p1, "x"); remotes.BuyPet.OnServerEvent:Fire(p1, 0); remotes.BuyPet.OnServerEvent:Fire(p1, 7); remotes.EquipPet.OnServerEvent:Fire(p1, 4)
	M.advance(0.1)
	check("bad pet remote args ignored", prof.Pet == 2 and prof.Wins == 200)
	remotes.EquipPet.OnServerEvent:Fire(p1, 0)
	M.advance(0.1)
	check("unequip via remote", prof.Pet == 0 and p1:GetAttribute("Pet") == 0)
	remotes.EquipPet.OnServerEvent:Fire(p1, 2)
	M.advance(0.1)
	check("re-equip owned via remote", prof.Pet == 2)

	-- shards: real Gameplay position check -> speed, quest progress, goal progress
	prof.Speed = 100
	prof.Quests = { { Id = "shards20", P = 0, C = false }, { Id = "pads15", P = 0, C = false }, { Id = "shards100", P = 0, C = false } }
	prof.QuestDay = Quests.today()
	local g0 = Goal.progress()
	for k = 1, 5 do
		hrp1.Position = shards[k].Pos
		M.advance(0.2)
	end
	check("5 shards collected -> goal progress +5", Goal.progress() == g0 + 5, Goal.progress())
	check("5 shards -> quest progress 5/5", prof.Quests[1].P == 5 and prof.Quests[3].P == 5, prof.Quests[1].P)
	check("shard gave speed", prof.Speed > 100 + 5 * Config.ShardMin)
	local shardNotifies = 0
	for _, f in ipairs(M.fired) do if f.args[1] == nil then end end
	hrp1.Position = shards[1].Pos
	local gp = Goal.progress()
	M.advance(0.3)
	check("same shard not collected twice per lap", Goal.progress() == gp)

	-- goal completes via many shards (direct adds) -> boost + broadcast to players
	local firedBefore = #M.fired
	for _ = 1, Goal.target() do Goal.add(1) end
	check("goal boost active after fill", Goal.boostActive())
	local sawGoalMsg = false
	for i = firedBefore + 1, #M.fired do if M.fired[i].remote == "Notify" and M.fired[i].args[1] == "goal" then sawGoalMsg = true end end
	check("goal broadcast reached the player", sawGoalMsg)
	check("goal boost end replicated", RS:GetAttribute("GoalBoostEnds") > workspace:GetServerTimeNow())
	local s1 = prof.Speed
	M.advance(4)
	check("gain x1.5*1.25 during boost", math.abs((prof.Speed - s1) / 4 - 1.25 * 1.5) < 0.01, (prof.Speed - s1) / 4)
	M.advance(Config.Goal.BoostSeconds + 2)
	check("boost expires", not Goal.boostActive())

	-- first-clear bonus: pad pays base once more the very first time a stage is cleared
	local rt1 = Gameplay.runtime(p1)
	rt1.grace = math.huge
	prof.BestStage = 0; prof.Speed = Config.Stages[1].Req + 1
	local wc = prof.Wins
	hrp1.Position = Vector3.new(0, 204, stages[1].PadZ)
	M.advance(0.3)
	local baseWins = math.floor(stages[1].Wins * Gameplay.winsMultiplier(p1))
	check("first clear pays pad + one-time bonus", prof.Wins - wc == baseWins + stages[1].Wins and prof.BestStage == 1, prof.Wins - wc)
	Gameplay.resetLap(p1)
	wc = prof.Wins
	hrp1.Position = Vector3.new(0, 204, stages[1].PadZ - 40); M.advance(0.2)
	hrp1.Position = Vector3.new(0, 204, stages[1].PadZ); M.advance(0.3)
	check("second clear pays the base only", prof.Wins - wc == baseWins, prof.Wins - wc)
	Gameplay.resetLap(p1)
	hrp1.Position = Vector3.new(0, 204, 0); M.advance(0.2)

	-- Roblox Premium perk (free, small)
	prof.Speed = 0
	M.advance(3)
	local noPrem = prof.Speed / 3
	p1.MembershipType = M.globals.Enum.MembershipType.Premium
	prof.Speed = 0
	M.advance(3)
	check("Premium members get +10% gain", math.abs((prof.Speed / 3) / noPrem - Config.PremiumMult) < 0.02, (prof.Speed / 3) / noPrem)
	p1.MembershipType = nil

	-- second player changes the goal target (and they are friends: both get a toast)
	p1.IsFriendsWith = function() return true end
	local firedBeforeJoin = #M.fired
	local p2 = join("Bob")
	p2.IsFriendsWith = function() return true end
	M.advance(0.1)
	local friendToast = false
	for i = firedBeforeJoin + 1, #M.fired do
		local f = M.fired[i]
		if f.remote == "Notify" and f.player == p1 and f.args[1] == "announce" and string.find(f.args[2], "friend") then friendToast = true end
	end
	check("friend joining shows a boost toast", friendToast)
	check("goal target scales with 2 players", RS:GetAttribute("GoalTarget") == Config.GoalTarget(2), RS:GetAttribute("GoalTarget"))

	-- gifts: unlock by play time through the real tick
	local prof2 = DataService.get(p2)
	prof2.GiftSeconds = 0
	M.advance(Config.Gifts[1].Minutes * 60 + 2)
	check("gift ready after 3 min of ticks", p2:GetAttribute("GiftReady") == true, prof2.GiftSeconds)
	local w = prof2.Wins
	remotes.ClaimGift.OnServerEvent:Fire(p2, 1)
	M.advance(0.1)
	check("gift claim via remote pays", prof2.Wins > w and prof2.GiftClaims["1"] and p2:GetAttribute("GiftClaimed") == "1", prof2.Wins - w)
	local w2 = prof2.Wins
	remotes.ClaimGift.OnServerEvent:Fire(p2, 1); remotes.ClaimGift.OnServerEvent:Fire(p2, 3); remotes.ClaimGift.OnServerEvent:Fire(p2, "a")
	M.advance(0.1)
	check("gift double/locked claims ignored", prof2.Wins == w2)

	-- quests: trio via remote
	prof.BestStage = 4
	prof.Quests = { { Id = "pads15", P = 15, C = false }, { Id = "play25", P = 1500, C = false }, { Id = "shards100", P = 100, C = false } }
	prof.QuestDay = Quests.today(); prof.TrioDay = 0; prof.TrioStreak = 0
	Quests.sync(p1)
	check("quest ready flag", p1:GetAttribute("QuestReady") == true)
	local wq = prof.Wins
	for i = 1, 3 do remotes.ClaimQuest.OnServerEvent:Fire(p1, i); M.advance(0.6) end
	check("trio completed", prof.TrioStreak == 1 and p1:GetAttribute("TrioDone") == true and prof.Wins > wq, prof.TrioStreak)

	-- rebirth + boots events reach quests
	prof.Speed = 1e6; prof.Wins = 1e5
	prof.Quests = { { Id = "rebirth1", P = 0, C = false }, { Id = "newboots", P = 0, C = false }, { Id = "adopt", P = 0, C = false } }
	prof.QuestDay = Quests.today()
	remotes.Rebirth.OnServerEvent:Fire(p1)
	M.advance(0.1)
	check("rebirth event completes rebirth quest", prof.Quests[1].P == 1, prof.Quests[1].P)
	prof.Wins = 1e5
	remotes.BuyBoot.OnServerEvent:Fire(p1, 3)
	remotes.BuyPet.OnServerEvent:Fire(p1, 3)
	M.advance(0.1)
	check("boots + companion events complete quests", prof.Quests[2].P == 1 and prof.Quests[3].P == 1, prof.Quests[2].P .. "," .. prof.Quests[3].P)

	-- save format: v4 fields survive a reconcile round-trip
	local snapshot = {}
	for k, v in pairs(prof) do snapshot[k] = v end
	local back = DataService.reconcile(snapshot)
	check("v4 profile fields round-trip", back.Pet == prof.Pet and back.Pets["2"] == prof.Pets["2"] and back.TrioStreak == prof.TrioStreak and back.GiftSeconds == prof.GiftSeconds)

	-- leaving: runtime cleaned, goal target refreshed
	Players.PlayerRemoving:Fire(p2)
	table.remove(M.players, 2)
	M.advance(2)
	check("goal target shrinks after a player leaves", RS:GetAttribute("GoalTarget") == Config.GoalTarget(1), RS:GetAttribute("GoalTarget"))
end

local co = coroutine.create(test)
local ok, err = coroutine.resume(co)
local guard = 0
while coroutine.status(co) ~= "dead" and guard < 100000 do
	guard = guard + 1
	M.advance(0.1)
end
if not ok then print("TEST ERROR: " .. tostring(err) .. "\n" .. debug.traceback(co)); fail = fail + 1 end
print(string.format("HARNESS DONE: %d pass, %d fail, %d thread errors", pass, fail, M.failures()))
if fail > 0 or M.failures() > 0 then error("harness failed") end
