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
	check("pad1 pays wins", p.Wins == w0 + s1.Wins * Gameplay.winsMultiplier(player), p.Wins - w0)
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
