--!strict
-- Studio-only self test. Run from the command bar (Server context) during Play:
--   game.ServerScriptService.DevRun:Invoke()
-- (requiring it directly from the command bar gets a separate module cache with no players loaded)
-- It drives the first player through gates/pads/shop/rebirth/fall/products and
-- prints PASS/FAIL lines, then restores the player's original progress.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Gameplay = require(script.Parent.Gameplay)
local Shop = require(script.Parent.Shop)
local Monetization = require(script.Parent.Monetization)
local Quests = require(script.Parent.Quests)
local Goal = require(script.Parent.Goal)
local Gifts = require(script.Parent.Gifts)

local DevTest = {}

function DevTest.run()
	assert(RunService:IsStudio(), "DevTest is Studio-only")
	local player = Players:GetPlayers()[1]
	assert(player, "no player")
	local p = DataService.get(player) :: DataService.Profile
	local backup = table.clone(p)
	backup.Boots = table.clone(p.Boots)
	backup.Receipts = table.clone(p.Receipts)
	backup.Quests = table.clone(p.Quests)
	backup.Pets = table.clone(p.Pets)
	backup.GiftClaims = table.clone(p.GiftClaims)
	local layout = Gameplay.layout()
	local results = { pass = 0, fail = 0 }
	local function check(name: string, cond: boolean, detail: any?)
		if cond then
			results.pass += 1
			print("PASS " .. name)
		else
			results.fail += 1
			warn("FAIL " .. name .. (if detail ~= nil then " :: " .. tostring(detail) else ""))
		end
	end
	local function hrp(): BasePart
		return (player.Character :: Model):WaitForChild("HumanoidRootPart") :: BasePart
	end
	local function tp(z: number, y: number?)
		local rt = Gameplay.runtime(player)
		if rt then
			rt.grace = 0
		end
		hrp().AssemblyLinearVelocity = Vector3.zero;
		(player.Character :: Model):PivotTo(CFrame.lookAt(Vector3.new(0, y or Config.TrackY + 4, z), Vector3.new(0, y or Config.TrackY + 4, z + 10)))
		local rt2 = Gameplay.runtime(player)
		if rt2 then
			rt2.sampleFrom = nil
		end
	end

	-- 0. map sanity (v2): part budget, jump signs, decor has no touch/query
	check("map part count under 4000", (layout.PartCount or 0) > 0 and (layout.PartCount or 0) < 4000, layout.PartCount)
	local jumpSigns, touchyDecor = 0, 0
	for _, d in workspace.Map:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "JumpSign" then
				jumpSigns += 1
			end
			if not d.CanCollide and d.CanTouch then
				touchyDecor += 1
			end
		end
	end
	check("2 jump signs", jumpSigns == 2, jumpSigns)
	check("non-colliding map parts have CanTouch off", touchyDecor == 0, touchyDecor)

	Gameplay.resetLap(player)
	local s1 = layout.Stages[1]
	-- 1. gate blocks without speed
	p.Speed = 0
	tp(s1.GateZ + 10)
	task.wait(0.6)
	check("gate1 rejects speed 0", hrp().Position.Z < s1.GateZ, hrp().Position.Z)

	-- 2. pad pays with enough speed
	p.Speed = s1.Req + 1
	local w0 = p.Wins
	tp(s1.PadZ)
	task.wait(0.6)
	check("pad1 pays wins", p.Wins == w0 + math.floor(s1.Wins * Gameplay.winsMultiplier(player)), p.Wins - w0)
	check("checkpoint=1", (Gameplay.runtime(player) :: any).checkpoint == 1)
	-- 3. no double claim
	local w1 = p.Wins
	tp(s1.PadZ - 15)
	task.wait(0.3)
	tp(s1.PadZ)
	task.wait(0.6)
	check("pad1 no double claim", p.Wins == w1, p.Wins - w1)

	-- 4. boots
	p.Wins = 10
	Shop.buyBoot(player, 2)
	check("boot rejected when poor", p.Boot ~= 2 and not p.Boots["2"])
	p.Wins = 100
	Shop.buyBoot(player, 2)
	check("boot bought", p.Boot == 2 and p.Boots["2"] == true and p.Wins == 50, p.Wins)
	Shop.buyBoot(player, 99)
	Shop.buyBoot(player, 1.5)
	Shop.buyBoot(player, "2")
	check("bad boot args ignored", p.Boot == 2 and p.Wins == 50)
	Shop.equipBoot(player, 1)
	check("equip owned boot", p.Boot == 1)
	Shop.equipBoot(player, 5)
	check("equip unowned rejected", p.Boot == 1)

	-- 5. speed tick uses the multiplier
	p.Boot = 2
	p.Speed = 0
	task.wait(2.1)
	check("tick adds >= 2/s with x2 boots", p.Speed >= 4, p.Speed)

	-- 6. rebirth
	p.Speed = 10
	local r0 = p.Rebirths
	Shop.rebirth(player)
	check("rebirth rejected when slow", p.Rebirths == r0)
	p.Speed = Config.RebirthCost(r0) + 5
	Shop.rebirth(player)
	check("rebirth works", p.Rebirths == r0 + 1 and p.Speed < 10 and p.Wins == 0, p.Rebirths)
	task.wait(1.6)

	-- 7. falling returns to checkpoint (spawn after rebirth)
	tp(200, Config.KillY - 10)
	task.wait(0.6)
	check("fall returns to track", hrp().Position.Y > Config.TrackY, hrp().Position.Y)

	-- 8. later gate rejection (stage 5) and the server movement check
	p.Speed = 1000
	tp(layout.Stages[5].GateZ + 30)
	task.wait(0.6)
	check("gate5 rejects 1000 speed", hrp().Position.Z < layout.Stages[5].GateZ, hrp().Position.Z)

	-- 9. finish pad: wins + lap reset + back to spawn
	p.Speed = 1e7
	local last = layout.Stages[#layout.Stages]
	local wf = p.Wins
	tp(last.PadZ)
	task.wait(0.6)
	check("finish pays", p.Wins > wf, p.Wins - wf)
	task.wait(3)
	check("finish returns to spawn", hrp().Position.Z < 0, hrp().Position.Z)
	check("lap reset", (Gameplay.runtime(player) :: any).checkpoint == 0)

	-- 9b. daily reward: ready -> pays day-1 wins once; second claim is rejected
	p.LastDaily = 0
	p.DailyStreak = 0
	Shop.refreshDaily(player)
	check("daily ready attr", player:GetAttribute("DailyReady") == true)
	local wd = p.Wins
	Shop.claimDaily(player)
	check("daily pays day 1", p.Wins == wd + Config.DailyWinsPerDay, p.Wins - wd)
	Shop.claimDaily(player)
	check("daily second claim rejected", p.Wins == wd + Config.DailyWinsPerDay and player:GetAttribute("DailyReady") == false)

	-- 10. product handlers (direct) and receipt de-dupe
	p.Speed = 100
	Monetization.handlers.WinsS(player, p)
	check("WinsS handler", p.Wins >= 750)
	local pl0 = p.PotionLeft
	Monetization.handlers.Potion3x(player, p)
	check("potion handler", p.PotionLeft == pl0 + Config.PotionSeconds)
	local sp0 = p.Speed
	Monetization.handlers.SpeedBurst(player, p)
	check("burst handler", p.Speed >= sp0 + Config.BurstMin, p.Speed - sp0)
	Gameplay.resetLap(player)
	p.Speed = 0
	Monetization.handlers.SkipStage(player, p)
	task.wait(0.6)
	check("skip handler sets speed", p.Speed >= layout.Stages[1].Req)
	check("skip handler teleports past gate", hrp().Position.Z > layout.Stages[1].GateZ, hrp().Position.Z)
	if Monetization.processReceipt then
		for _, key in Config.ProductOrder do
			local prod = Config.Products[key]
			if prod.Id ~= 0 then
				local id = "devtest-" .. key .. "-" .. os.clock()
				local function snap()
					return string.format("%.0f|%.0f|%.0f|%d", p.Speed, p.Wins, p.PotionLeft, #p.Receipts)
				end
				local before = snap()
				local d1 = Monetization.processReceipt({ PlayerId = player.UserId, ProductId = prod.Id, PurchaseId = id })
				local mid = snap()
				local d2 = Monetization.processReceipt({ PlayerId = player.UserId, ProductId = prod.Id, PurchaseId = id })
				local after = snap()
				local G = Enum.ProductPurchaseDecision.PurchaseGranted
				check("receipt " .. key .. " granted exactly once", d1 == G and d2 == G and before ~= mid and mid == after, before .. " -> " .. mid .. " -> " .. after)
			end
		end
	end

	-- 11. save migration (v2): an old-format (v1) save keeps its values and gains v2 defaults
	local oldSave = {
		Speed = 123456, Wins = 789, TotalWins = 9999, Rebirths = 2, Boots = { ["1"] = true, ["2"] = true, ["3"] = true },
		Boot = 3, PotionLeft = 30, DailyStreak = 4, LastDaily = 1791000000, BestStage = 7,
		Receipts = { "abc", "def" }, TutorialDone = true, PlaySeconds = 3600,
	}
	local m = DataService.reconcile(oldSave)
	check("migration keeps v1 values", m.Speed == 123456 and m.Wins == 789 and m.Rebirths == 2 and m.Boot == 3 and m.Boots["3"] == true and #m.Receipts == 2 and m.BestStage == 7 and m.TutorialDone == true)
	check("migration adds v2 defaults", m.BestSpeed == 0 and m.QuestDay == 0 and type(m.Quests) == "table" and #m.Quests == 0)
	local junk = DataService.reconcile({ Speed = "lots", Quests = 5, Boots = {} })
	check("migration rejects wrong types", junk.Speed == 0 and type(junk.Quests) == "table" and junk.Boots["1"] == true)

	-- 12. daily quests: generation, progress from events, claim once, bad args
	p.QuestDay = 0
	Quests.ensure(player, p)
	check("3 quests for today", #p.Quests == 3 and p.QuestDay == Quests.today())
	local tiers = {}
	for _, q in p.Quests do
		local d = Quests.def(q.Id)
		tiers[#tiers + 1] = d and d.Tier or 0
	end
	check("one quest per tier", tiers[1] == 1 and tiers[2] == 2 and tiers[3] == 3, table.concat(tiers, ","))
	p.Quests = { { Id = "pads15", P = 0, C = false }, { Id = "play25", P = 0, C = false }, { Id = "finish1", P = 0, C = false } }
	for _ = 1, 15 do
		Quests.event(player, "pad", 1)
	end
	Quests.event(player, "play", 30)
	check("pad quest progressed to target", p.Quests[1].P == 15, p.Quests[1].P)
	check("play quest progressed", p.Quests[2].P == 30, p.Quests[2].P)
	local wq = p.Wins
	local expected = Quests.reward(p, Quests.def("pads15") :: any)
	Quests.claim(player, 1)
	check("quest claim pays", p.Wins == wq + expected and p.Quests[1].C == true, p.Wins - wq)
	Quests.claim(player, 1)
	Quests.claim(player, 2)
	Quests.claim(player, 9)
	Quests.claim(player, "1")
	check("quest double/unfinished/bad claims ignored", p.Wins == wq + expected)
	check("Quests attribute synced", type(player:GetAttribute("Quests")) == "string" and string.find(player:GetAttribute("Quests") :: string, "Step on 15") ~= nil)

	-- 13. best speed tracking for the Top Speed board
	p.BestSpeed = 0
	p.Speed = 5000
	task.wait(1.2)
	check("BestSpeed follows Speed", p.BestSpeed >= 5000, p.BestSpeed)

	-- 14. v3 map: bright palette, daytime atmosphere, landmark, gentle first gaps
	local fl = Config.Zones[1].Floor
	check("bright palette (Moon floor luminance)", 0.2126 * fl.R + 0.7152 * fl.G + 0.0722 * fl.B > 0.55)
	local lighting = game:GetService("Lighting")
	check("daytime sky + atmosphere", lighting.ClockTime > 8 and lighting.ClockTime < 17 and lighting:FindFirstChildOfClass("Atmosphere") ~= nil)
	local decor = workspace.Map:FindFirstChild("Decor")
	check("comet landmark + spawn arch", decor ~= nil and decor:FindFirstChild("CometLandmark") ~= nil and decor:FindFirstChild("SpawnArch") ~= nil)
	check("landmark uses Blender meshes", decor ~= nil and decor:FindFirstChild("CometLandmark") ~= nil and (decor :: any).CometLandmark:FindFirstChild("Tail") ~= nil)

	-- 15. v3 Comet Shards: +Speed once per lap, server-validated by position, reset by a new lap
	game:GetService("ReplicatedStorage"):SetAttribute("ForceEvent", 2) -- Wins Rush: shard mult 1
	check("shards placed in first stages", #layout.Shards >= 15, #layout.Shards)
	Gameplay.resetLap(player)
	local lap0 = (player:GetAttribute("Lap") :: number?) or 0
	local sh = layout.Shards[1]
	for _, cand in layout.Shards do
		if math.abs(cand.Pos.X) < 0.5 and cand.Pos.Z > 60 then -- the test teleport puts the player at X = 0
			sh = cand
			break
		end
	end
	p.Speed = 100
	local expectShard = math.floor(math.max(Config.ShardMin, Gameplay.multiplier(player, p) * Config.ShardSeconds))
	tp(sh.Pos.Z, sh.Pos.Y)
	task.wait(0.4)
	local got = p.Speed - 100
	check("shard gives speed", got >= expectShard and got < expectShard + 20, got)
	local afterFirst = p.Speed
	tp(sh.Pos.Z - 10)
	task.wait(0.3)
	tp(sh.Pos.Z, sh.Pos.Y)
	task.wait(0.4)
	check("shard only once per lap", p.Speed - afterFirst < expectShard, p.Speed - afterFirst)
	Gameplay.resetLap(player)
	check("new lap bumps Lap attr", ((player:GetAttribute("Lap") :: number?) or 0) == lap0 + 1)
	local beforeLap = p.Speed
	tp(sh.Pos.Z, sh.Pos.Y)
	task.wait(0.4)
	check("shard collectable again after new lap", p.Speed - beforeLap >= expectShard, p.Speed - beforeLap)

	-- 16. v3 weekly rotation: deterministic by UTC week, multipliers applied, schedule cycles
	local t0 = 1791158400 -- a Monday 00:00 UTC
	check("event index stable within a week", Config.EventIndexAt(t0) == Config.EventIndexAt(t0 + 6 * 86400 + 86399))
	check("event index advances weekly", Config.EventIndexAt(t0 + 7 * 86400) == (Config.EventIndexAt(t0) % #Config.WeeklyEvents) + 1)
	check("event ends at next Monday", Config.EventEndsAt(t0 + 3600) == t0 + 7 * 86400)
	local RS = game:GetService("ReplicatedStorage")
	RS:SetAttribute("ForceEvent", 2)
	local baseMult = Gameplay.multiplier(player, p)
	RS:SetAttribute("ForceEvent", 4) -- Speed Week x1.25
	check("Speed Week multiplies gain", math.abs(Gameplay.multiplier(player, p) - baseMult * 1.25) < 1e-6)
	RS:SetAttribute("ForceEvent", 3) -- Quest Bonus x2
	local qd = Quests.def("pads15") :: any
	local qBonus = Quests.reward(p, qd)
	RS:SetAttribute("ForceEvent", 2)
	check("Quest Bonus doubles quest reward", qBonus == 2 * Quests.reward(p, qd), qBonus)
	RS:SetAttribute("ForceEvent", nil)

	-- 17. v4 companions: fixed price, bonus applied to the Speed multiplier, bad input ignored
	do
		local comps = Config.Companions
		local ascending = #comps >= 4
		for i = 2, #comps do
			ascending = ascending and comps[i].Cost > comps[i - 1].Cost and comps[i].Bonus > comps[i - 1].Bonus
		end
		check("companions: prices and bonuses ascend", ascending)
		Goal.resetForTest()
		p.Pets = {}
		p.Pet = 0
		p.Wins = 10
		local m0 = Gameplay.multiplier(player, p)
		Shop.buyPet(player, 1)
		check("pet rejected when poor", p.Pet == 0 and not p.Pets["1"] and p.Wins == 10)
		p.Wins = comps[1].Cost + 25
		Shop.buyPet(player, 1)
		check("pet bought + equipped", p.Pet == 1 and p.Pets["1"] == true and p.Wins == 25, p.Wins)
		check("pet attrs synced", player:GetAttribute("Pet") == 1 and player:GetAttribute("OwnedPets") == "1")
		check("pet bonus multiplies Speed gain", math.abs(Gameplay.multiplier(player, p) - m0 * (1 + comps[1].Bonus)) < 1e-6)
		Shop.buyPet(player, 1)
		check("owned pet is not charged twice", p.Wins == 25)
		Shop.buyPet(player, 99)
		Shop.buyPet(player, 0)
		Shop.buyPet(player, 1.5)
		Shop.buyPet(player, "2")
		Shop.buyPet(player, -1)
		Shop.equipPet(player, 3)
		check("bad pet args and unowned equip ignored", p.Pet == 1 and not p.Pets["2"] and not p.Pets["3"] and p.Wins == 25)
		Shop.equipPet(player, 0)
		check("pet can be unequipped", p.Pet == 0 and math.abs(Gameplay.multiplier(player, p) - m0) < 1e-6)
		Shop.equipPet(player, 1)
		check("pet can be re-equipped", p.Pet == 1)
		-- client model builder (pure instance creation, safe to run on the server)
		local okPets, PetsMod = pcall(function()
			return require((game:GetService("StarterPlayer").StarterPlayerScripts :: any).Client.Pets)
		end)
		check("client Pets module loads", okPets)
		if okPets then
			local allOk = true
			for i = 1, #comps do
				local mdl = (PetsMod :: any).build(i) :: Model
				local n = 0
				for _, d in mdl:GetDescendants() do
					if d:IsA("BasePart") then
						n += 1
						if d.CanCollide or d.CanTouch or d.CanQuery then
							allOk = false
						end
					end
				end
				allOk = allOk and mdl.PrimaryPart ~= nil and n >= 6
				mdl:Destroy()
			end
			check("every companion model builds (>= 6 parts, no collision)", allOk)
		end
		p.Pet = 0
	end

	-- 18. v4 server shard goal: shared bar, boost on completion, boost not stacked, resets cleanly
	do
		Goal.resetForTest()
		local target = Goal.target()
		check("goal target for the test server", target == Config.GoalTarget(#Players:GetPlayers()) and target >= Config.Goal.BaseTarget, target)
		check("goal target scales with players", Config.GoalTarget(3) == Config.Goal.BaseTarget + 2 * Config.Goal.PerPlayer and Config.GoalTarget(500) == Config.Goal.MaxTarget)
		local mBefore = Gameplay.multiplier(player, p)
		for _ = 1, target - 1 do
			Goal.add(1)
		end
		check("goal not complete one shard early", not Goal.boostActive() and Goal.progress() == target - 1)
		check("goal attrs replicate", game:GetService("ReplicatedStorage"):GetAttribute("GoalProgress") == target - 1 and game:GetService("ReplicatedStorage"):GetAttribute("GoalTarget") == target)
		Goal.add(1)
		check("goal completes -> boost active", Goal.boostActive() and Goal.progress() == 0 and Goal.triggers() >= 1)
		check("goal boost multiplies gain", math.abs(Gameplay.multiplier(player, p) - mBefore * Config.Goal.BoostMult) < 1e-6)
		Goal.add(5)
		check("shards during boost are not counted", Goal.progress() == 0)
		Goal.resetForTest()
		check("goal reset", not Goal.boostActive() and math.abs(Gameplay.multiplier(player, p) - mBefore) < 1e-6)
	end

	-- 19. v4 quests: shard/boots/rebirth events, MinStage filtering, Daily Trio bonus + streak
	do
		p.BestStage = 0
		local leaked = 0
		for day = 20000, 20059 do
			Quests.ensure(player, p, day)
			for _, q in p.Quests do
				local d = Quests.def(q.Id)
				if d and d.MinStage and d.MinStage > 0 then
					leaked += 1
				end
			end
		end
		check("new players never get quests that need later stages", leaked == 0, leaked)
		p.BestStage = 15
		local sawLate = false
		for day = 20000, 20059 do
			Quests.ensure(player, p, day)
			for _, q in p.Quests do
				local d = Quests.def(q.Id)
				if d and d.MinStage and d.MinStage >= 5 then
					sawLate = true
				end
			end
		end
		check("late-game quests do appear for advanced players", sawLate)
		local tiersOk = true
		for _, q in Config.QuestPool do
			if q.Tier < 1 or q.Tier > 3 then
				tiersOk = false
			end
		end
		for tier = 1, 3 do
			local n = 0
			for _, q in Config.QuestPool do
				if q.Tier == tier and q.MinStage == nil then
					n += 1
				end
			end
			tiersOk = tiersOk and n >= 1 -- every tier keeps at least one quest anyone can do
		end
		check("every quest tier has a quest with no stage requirement", tiersOk)
		p.BestStage = 3
		p.QuestDay = Quests.today()
		p.Quests = { { Id = "shards20", P = 0, C = false }, { Id = "newboots", P = 0, C = false }, { Id = "shards100", P = 0, C = false } }
		for _ = 1, 20 do
			Quests.event(player, "shard", 1)
		end
		check("shard quests progress together", p.Quests[1].P == 20 and p.Quests[3].P == 20, p.Quests[3].P)
		p.Wins = 1e6
		p.Boots = { ["1"] = true }
		p.Boot = 1
		Shop.buyBoot(player, 2)
		check("buying boots progresses the boots quest", p.Quests[2].P == 1)
		Quests.event(player, "shard", 80)
		-- trio: claim all three; first completion starts a streak
		p.TrioDay = 0
		p.TrioStreak = 0
		Quests.claim(player, 1)
		Quests.claim(player, 2)
		local wTrio = p.Wins
		local bestReward = Quests.reward(p, Quests.def("shards100") :: any)
		Quests.claim(player, 3)
		local gotTrio = p.Wins - wTrio
		check("Daily Trio pays reward + bonus", gotTrio == bestReward + bestReward * Config.TrioMult, gotTrio)
		check("Daily Trio starts a streak", p.TrioStreak == 1 and p.TrioDay == Quests.today() and player:GetAttribute("TrioDone") == true)
		local wAgain = p.Wins
		Quests.checkTrio(player, p)
		check("Daily Trio only once per day", p.Wins == wAgain)
		-- streak continues from yesterday and the 7th day gives a potion
		p.TrioDay = Quests.today() - 1
		p.TrioStreak = Config.TrioStreakDays - 1
		p.Quests = { { Id = "pads15", P = 15, C = true }, { Id = "play25", P = 1500, C = true }, { Id = "shards100", P = 100, C = false } }
		local potion0 = p.PotionLeft
		Quests.claim(player, 3)
		check("7-day Trio streak gives a potion", p.TrioStreak == Config.TrioStreakDays and p.PotionLeft >= potion0 + Config.PotionSeconds - 2, p.PotionLeft - potion0)
		-- a missed day restarts the streak
		p.TrioDay = Quests.today() - 3
		p.TrioStreak = 5
		p.Quests = { { Id = "pads15", P = 15, C = true }, { Id = "play25", P = 1500, C = true }, { Id = "shards100", P = 100, C = false } }
		Quests.claim(player, 3)
		check("missed day restarts the Trio streak", p.TrioStreak == 1, p.TrioStreak)
	end

	-- 20. v4 playtime gifts: unlock by minutes played today, claim once, persist across rejoin, reset next UTC day
	do
		local today = Quests.today()
		p.BestStage = 3
		p.GiftDay = today
		p.GiftSeconds = 100
		p.GiftClaims = {}
		Gifts.sync(player)
		check("gift not ready too early", player:GetAttribute("GiftReady") == false)
		local gw0 = p.Wins
		Gifts.claim(player, 1)
		check("early gift claim rejected", p.Wins == gw0 and not p.GiftClaims["1"])
		p.GiftSeconds = Config.Gifts[1].Minutes * 60 + 5
		Gifts.sync(player)
		check("gift becomes ready", player:GetAttribute("GiftReady") == true)
		Gifts.claim(player, 1)
		check("gift pays the quest-scale reward", p.Wins == gw0 + Quests.winsFor(p, Config.Gifts[1].Mult) and p.GiftClaims["1"] == true, p.Wins - gw0)
		local gw1 = p.Wins
		Gifts.claim(player, 1)
		Gifts.claim(player, 2)
		Gifts.claim(player, 0)
		Gifts.claim(player, 99)
		Gifts.claim(player, "1")
		Gifts.claim(player, 1.5)
		check("double/locked/bad gift claims ignored", p.Wins == gw1)
		check("gift attrs synced", player:GetAttribute("GiftClaimed") == "1" and player:GetAttribute("GiftReady") == false)
		p.GiftSeconds = 60 * 60 + 1
		local pot = p.PotionLeft
		Gifts.claim(player, #Config.Gifts)
		check("top gift also grants a potion", p.PotionLeft >= pot + Config.Gifts[#Config.Gifts].PotionSeconds - 2, p.PotionLeft - pot)
		p.GiftDay = today - 1
		Gifts.sync(player)
		check("gifts reset on a new UTC day", p.GiftDay == today and p.GiftSeconds == 0 and next(p.GiftClaims) == nil)
		local s0 = p.GiftSeconds
		task.wait(2.1)
		check("gift timer ticks with play time", p.GiftSeconds >= s0 + 1, p.GiftSeconds)
	end

	-- 21. v4 migration + scenery + zone ambience
	do
		local m4 = DataService.reconcile({ Speed = 5, Boots = { ["1"] = true }, Quests = {}, BestSpeed = 3 })
		check("migration adds v4 defaults", m4.Pet == 0 and next(m4.Pets) == nil and m4.GiftSeconds == 0 and next(m4.GiftClaims) == nil and m4.TrioStreak == 0 and m4.TrioDay == 0)
		local junk4 = DataService.reconcile({ Pet = "cat", Pets = 3, GiftClaims = "x", TrioStreak = {} })
		check("migration rejects wrong v4 types", junk4.Pet == 0 and type(junk4.Pets) == "table" and type(junk4.GiftClaims) == "table" and junk4.TrioStreak == 0)
		local kept = DataService.reconcile({ Pet = 2, Pets = { ["1"] = true, ["2"] = true }, TrioStreak = 4, GiftSeconds = 77 })
		check("migration keeps v4 values", kept.Pet == 2 and kept.Pets["2"] == true and kept.TrioStreak == 4 and kept.GiftSeconds == 77)
		local clouds, lanterns, flags = 0, 0, 0
		for _, d in workspace.Map.Decor:GetChildren() do
			if d.Name == "Cloud" then
				clouds += 1
			elseif d.Name == "Lantern" then
				lanterns += 1
			elseif d.Name == "PennantFlag" then
				flags += 1
			end
		end
		check("v4 scenery built (clouds, lanterns, 2 flags per stage)", clouds >= #Config.Stages * 5 and lanterns >= #Config.Stages * 6 and flags == #Config.Stages * 2, clouds .. "/" .. lanterns .. "/" .. flags)
		check("scenery stays under the part budget", (layout.PartCount or 0) < 3000, layout.PartCount)
		check("one sky tint per zone", #Config.ZoneSky == #Config.Zones)
		local okAmb, Amb = pcall(function()
			return require((game:GetService("StarterPlayer").StarterPlayerScripts :: any).Client.Ambience)
		end)
		check("client Ambience module loads", okAmb)
		if okAmb then
			local zs = {}
			for _, st in layout.Stages do
				zs[st.Index] = st.GateZ
			end
			local z1 = (Amb :: any).zoneAtZ(zs, 0)
			local zLast = (Amb :: any).zoneAtZ(zs, layout.EndZ)
			local zMid = (Amb :: any).zoneAtZ(zs, layout.Stages[3].PadZ)
			check("zone lookup by Z", z1 == 1 and zLast == Config.Stages[#Config.Stages].Zone and zMid == Config.Stages[3].Zone, z1 .. "," .. zMid .. "," .. zLast)
		end
	end

	-- restore
	for k, v in backup do
		(p :: any)[k] = v
	end
	Gameplay.resetLap(player)
	State.sync(player)
	Shop.refreshDaily(player)
	Quests.sync(player)
	Gameplay.applyWalkSpeed(player, p)
	Gameplay.applyTrail(player)
	tp(-20)
	print(("DEVTEST DONE: %d pass, %d fail"):format(results.pass, results.fail))
	return results
end

return DevTest
