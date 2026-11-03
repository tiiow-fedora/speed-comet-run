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
	shards[41] = { Id = "9_41", Pos = Vector3.new(0, 203, 3000) } -- far down the track (v3 only paid shards before Z 1400)
	shards[42] = { Id = "9_42", Pos = Vector3.new(0, 203, 3200) }
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
	-- trophies pay Wins on the tick; the economy checks below need exact numbers, so start with them all awarded (tested separately with Bob)
	for _, t in ipairs(Config.Trophies) do prof.Trophies[t.Id] = true end
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
	check("pet 2 bought via remote", prof.Pet == 2 and prof.Pets["2"] and prof.Wins == 1200 - Config.Companions[2].Cost and p1:GetAttribute("Pet") == 2 and p1:GetAttribute("OwnedPets") == "2", prof.Wins)
	local s0 = prof.Speed
	M.advance(4)
	local gain = (prof.Speed - s0) / 4
	check("pet bonus raises gain by 25%", math.abs(gain - 1.25) < 0.01, gain)
	remotes.BuyPet.OnServerEvent:Fire(p1, "x"); remotes.BuyPet.OnServerEvent:Fire(p1, 0); remotes.BuyPet.OnServerEvent:Fire(p1, 7); remotes.EquipPet.OnServerEvent:Fire(p1, 4)
	M.advance(0.1)
	check("bad pet remote args ignored", prof.Pet == 2 and prof.Wins == 1200 - Config.Companions[2].Cost)
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

	-- swept pickup: a fast runner that jumps over a shard between two 10 Hz samples still collects it; late-game shards pay too
	Gameplay.resetLap(p1)
	prof.Speed = 1e12 -- past every gate, so the gate check cannot interfere
	Gameplay.runtime(p1).grace = math.huge
	local sp0 = Goal.progress()
	hrp1.Position = Vector3.new(0, 204, 2985); M.advance(0.2)
	hrp1.Position = Vector3.new(0, 204, 3003); M.advance(0.2)
	check("fast runner collects a shard it jumped over (swept check, Z 3000)", Goal.progress() == sp0 + 1, Goal.progress() - sp0)
	local sp1 = Goal.progress()
	hrp1.Position = Vector3.new(30, 204, 3200); M.advance(0.3)
	check("a shard far off the lane is not collected", Goal.progress() == sp1)
	hrp1.Position = Vector3.new(0, 204, 3200); M.advance(0.3)
	check("shards past Z 1400 pay with a normal pass too", Goal.progress() == sp1 + 1, Goal.progress() - sp1)
	Gameplay.resetLap(p1)
	hrp1.Position = Vector3.new(0, 204, 0); M.advance(0.2)

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
	local p2, hrp2 = join("Bob")
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

	-- ===== v5: config integrity =====
	do
		local ok = true
		local prevReq = 0
		for i, st in ipairs(Config.Stages) do
			if st.Req <= prevReq or not Config.Zones[st.Zone] or not Config.ZoneSky[st.Zone] then ok = false end
			prevReq = st.Req
		end
		check("stages: increasing Req, every zone has colors and sky", ok and #Config.Stages == 20 and #Config.Zones == #Config.ZoneSky)
		local boots = true
		for i = 2, #Config.Boots do if Config.Boots[i].Mult <= Config.Boots[i - 1].Mult or Config.Boots[i].Cost <= Config.Boots[i - 1].Cost then boots = false end end
		check("boots: Mult and Cost strictly increase", boots)
		local ids, statsOk = {}, true
		local known = {}
		for _, n in ipairs(Config.TrophyStats) do known[n] = true end
		for _, t in ipairs(Config.Trophies) do
			if ids[t.Id] or not known[t.Stat] or t.Target <= 0 then statsOk = false end
			ids[t.Id] = true
		end
		check("trophies: unique ids, known stats, positive targets", statsOk)
		check("events: all have Pet/Gift multipliers", (function() for _, e in ipairs(Config.WeeklyEvents) do if not e.PetMult or not e.GiftMult then return false end end return true end)())
		check("head start grows with rebirths and is 0 before the first", Config.HeadStart(0) == 0 and Config.HeadStart(1) == 250 and Config.HeadStart(5) > Config.HeadStart(4))
		check("star mult: x1 below 5 rebirths, +20% per 5", Config.StarMult(4) == 1 and math.abs(Config.StarMult(5) - 1.2) < 1e-9 and math.abs(Config.StarMult(10) - 1.4) < 1e-9)
		check("titles: none before rebirth 1, Risen at 4", Config.RebirthTitle(0) == nil and Config.RebirthTitle(1) == "Reborn" and Config.RebirthTitle(4) == "Risen" and Config.NextMilestone(50) == nil and Config.NextMilestone(4).At == 5)
	end

	do
		local Format = M.require(M.sharedDir.Format)
		check("Format.mult: whole and fractional multipliers", Format.mult(8) == "8" and Format.mult(7.2) == "7.2" and Format.mult(1234) == "1.23K" and Format.mult(6 * 1.2) == "7.2")
	end

	-- ===== v5: finish quest is only offered to players who can reach the FINISH =====
	do
		prof.BestStage = 0
		local leaked = 0
		for day = 30000, 30119 do
			Quests.ensure(p1, prof, day)
			for _, q in ipairs(prof.Quests) do if q.Id == "finish1" then leaked = leaked + 1 end end
		end
		check("finish quest never offered below stage 19", leaked == 0, leaked)
		prof.BestStage = 19
		local seen = 0
		for day = 30000, 30119 do
			Quests.ensure(p1, prof, day)
			for _, q in ipairs(prof.Quests) do if q.Id == "finish1" then seen = seen + 1 end end
		end
		check("finish quest offered at stage 19", seen > 0)
		prof.BestStage = 4
		Quests.ensure(p1, prof, Quests.today())
	end

	-- ===== v5: trophies (fresh player Bob) =====
	do
		local pb = DataService.get(p2)
		check("v5 defaults on a new profile", type(pb.Stats) == "table" and type(pb.Trophies) == "table" and next(pb.Trophies) == nil)
		pb.BestStage = 3
		local fired0 = #M.fired
		local wBefore = pb.Wins
		M.advance(1.2)
		check("stage trophies awarded (1 and 3, not 5)", pb.Trophies.stage1 and pb.Trophies.stage3 and not pb.Trophies.stage5)
		check("trophy Wins paid", pb.Wins >= wBefore + Quests.winsFor(pb, 2) + Quests.winsFor(pb, 3))
		local toasts = 0
		for i = fired0 + 1, #M.fired do local f = M.fired[i]; if f.remote == "Notify" and f.player == p2 and f.args[1] == "trophy" then toasts = toasts + 1 end end
		check("several trophies at once give one toast", toasts == 1, toasts)
		check("trophy attributes replicated", p2:GetAttribute("TrophiesDone") ~= "" and string.match(p2:GetAttribute("TrophyData") or "", "^3,") ~= nil, p2:GetAttribute("TrophyData"))
		local wAfter = pb.Wins
		M.advance(3)
		check("a trophy is never awarded twice", pb.Trophies.stage1 and pb.Wins - wAfter < Quests.winsFor(pb, 2))
		pb.Stats.Shards = 49
		M.advance(1.2)
		check("shard trophy not yet at 49", not pb.Trophies.shards50)
		pb.Stats.Shards = 50
		M.advance(1.2)
		check("shard trophy at 50", pb.Trophies.shards50 == true)
		pb.Pets = { ["1"] = true }
		M.advance(1.2)
		check("adopting a companion earns Best Friend", pb.Trophies.pet1 == true)
		-- a configured badge id must not break awarding (BadgeService is pcall'd and only touched when an id is set)
		Config.BadgeIds.pet5 = 12345
		pb.Pets = { ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true }
		M.advance(1.2)
		check("trophy with a badge id still awards", pb.Trophies.pet5 == true)
		Config.BadgeIds.pet5 = nil
		-- real shard pickup bumps the lifetime counter
		local s0 = prof.Stats.Shards or 0
		check("p1 shard pickups counted in Stats", s0 >= 5, s0)
	end

	-- ===== v5: rebirth depth =====
	do
		prof.Rebirths = 0
		prof.PotionLeft = 0
		prof.Speed = Config.RebirthCost(0)
		prof.Wins = 999
		prof.BestStage = 4
		remotes.Rebirth.OnServerEvent:Fire(p1)
		M.advance(0.1)
		check("rebirth 1: head start Speed", prof.Rebirths == 1 and prof.Speed == Config.HeadStart(1), prof.Speed)
		check("rebirth 1: milestone purse + potion, old Wins wiped", prof.Wins == Quests.winsFor(prof, Config.RebirthMilestones[1].WinsMult) and prof.PotionLeft >= Config.RebirthMilestones[1].PotionSeconds - 1, prof.Wins)
		prof.Speed = Config.RebirthCost(1); prof.Wins = 50; prof.PotionLeft = 0
		M.advance(1.5)
		remotes.Rebirth.OnServerEvent:Fire(p1)
		M.advance(0.1)
		check("rebirth 2: no milestone, Wins reset to 0", prof.Rebirths == 2 and prof.Wins == 0 and prof.PotionLeft == 0, prof.Wins)
		-- the star bonus: rebirth 5 raises gain by 20% on top of x(1+r)
		prof.Rebirths = 4; prof.Boot = 1; prof.Pet = 0; prof.PotionLeft = 0
		local g4 = Gameplay.multiplier(p1, prof)
		prof.Rebirths = 5
		local g5 = Gameplay.multiplier(p1, prof)
		check("rebirth 5 star: gain x(6/5) x1.2", math.abs(g5 / g4 - (6 / 5) * 1.2) < 1e-6, g5 / g4)
		prof.Rebirths = 0
		prof.Speed = 5; prof.Wins = 0
	end

	-- ===== v5: new weekly events change companions and gifts =====
	do
		prof.Pet = 4; prof.Pets["4"] = true; prof.Rebirths = 0; prof.PotionLeft = 0
		RS:SetAttribute("ForceEvent", 5)
		local craze = Gameplay.multiplier(p1, prof)
		RS:SetAttribute("ForceEvent", 1)
		local normal = Gameplay.multiplier(p1, prof)
		check("Companion Craze doubles the companion bonus", math.abs(craze / normal - (1 + 2 * Config.Companions[4].Bonus) / (1 + Config.Companions[4].Bonus)) < 1e-6, craze / normal)
		local pb = DataService.get(p2)
		pb.GiftDay = Quests.today(); pb.GiftSeconds = 10 * 3600; pb.GiftClaims = {}; pb.BestStage = 4
		RS:SetAttribute("ForceEvent", 1)
		local w0 = pb.Wins
		remotes.ClaimGift.OnServerEvent:Fire(p2, 1)
		M.advance(0.1)
		local normalGift = pb.Wins - w0
		RS:SetAttribute("ForceEvent", 6)
		w0 = pb.Wins
		remotes.ClaimGift.OnServerEvent:Fire(p2, 2)
		M.advance(0.1)
		local weekGift = pb.Wins - w0
		RS:SetAttribute("ForceEvent", nil)
		check("Gift Week pays double", weekGift == Quests.winsFor(pb, Config.Gifts[2].Mult * 2) and normalGift == Quests.winsFor(pb, Config.Gifts[1].Mult), normalGift .. "/" .. weekGift)
		prof.Pet = 2
	end

	-- ===== v5: high-fives =====
	do
		local pa, pb = DataService.get(p1), DataService.get(p2)
		hrp1.Position = Vector3.new(0, 204, 100); hrp2.Position = Vector3.new(4, 204, 102)
		Gameplay.runtime(p1).grace = math.huge; Gameplay.runtime(p2).grace = math.huge
		local sa, sb = pa.Speed, pb.Speed
		remotes.HighFive.OnServerEvent:Fire(p1, p2)
		M.advance(0.1)
		check("high five pays both players and counts", pa.Speed > sa and pb.Speed > sb and pa.Stats.HighFives == 1 and pb.Stats.HighFives == 1, (pa.Speed - sa) .. "/" .. (pb.Speed - sb))
		M.advance(30)
		local sa2 = pa.Speed
		remotes.HighFive.OnServerEvent:Fire(p2, p1)
		M.advance(0.1)
		check("same pair is on cooldown (either direction)", pa.Stats.HighFives == 1 and math.abs(pa.Speed - sa2) < 40)
		M.advance(Config.HighFive.PairCooldown + 5)
		hrp2.Position = Vector3.new(60, 204, 100)
		remotes.HighFive.OnServerEvent:Fire(p1, p2)
		M.advance(0.1)
		check("too far apart: rejected", pa.Stats.HighFives == 1)
		hrp2.Position = Vector3.new(3, 204, 100)
		remotes.HighFive.OnServerEvent:Fire(p1, p1); remotes.HighFive.OnServerEvent:Fire(p1, "Bob"); remotes.HighFive.OnServerEvent:Fire(p1, 42); remotes.HighFive.OnServerEvent:Fire(p1, nil)
		M.advance(0.1)
		check("self / non-player targets rejected", pa.Stats.HighFives == 1)
		M.advance(6) -- the remote is rate limited (1/s, burst 4); the junk calls above used the burst
		remotes.HighFive.OnServerEvent:Fire(p1, p2)
		M.advance(0.1)
		check("after the cooldown they can high-five again", pa.Stats.HighFives == 2)
		local Social = M.require(M.serverDir.Social)
		local fake = 1e6
		local n = 0
		local realCap = Config.HighFive.PerHour
		Config.HighFive.PerHour = 3 -- one pair can only reach 6/hour, so lower the cap to exercise it
		for i = 1, 8 do
			fake = fake + Config.HighFive.PairCooldown + 1
			if Social.highFive(p1, p2, fake) then n = n + 1 end
		end
		Config.HighFive.PerHour = realCap
		check("hourly cap stops a farmed high-five chain", n >= 3 and n < 8, n)
		hrp1.Position = Vector3.new(0, 204, 0); hrp2.Position = Vector3.new(0, 204, 0)
	end

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
