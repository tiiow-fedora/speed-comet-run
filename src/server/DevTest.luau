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

local DevTest = {}

function DevTest.run()
	assert(RunService:IsStudio(), "DevTest is Studio-only")
	local player = Players:GetPlayers()[1]
	assert(player, "no player")
	local p = DataService.get(player) :: DataService.Profile
	local backup = table.clone(p)
	backup.Boots = table.clone(p.Boots)
	backup.Receipts = table.clone(p.Receipts)
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
		(player.Character :: Model):PivotTo(CFrame.new(0, y or Config.TrackY + 4, z))
		local rt2 = Gameplay.runtime(player)
		if rt2 then
			rt2.sampleFrom = nil
		end
	end

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

	-- restore
	for k, v in backup do
		(p :: any)[k] = v
	end
	Gameplay.resetLap(player)
	State.sync(player)
	Shop.refreshDaily(player)
	Gameplay.applyWalkSpeed(player, p)
	Gameplay.applyTrail(player)
	tp(-20)
	print(("DEVTEST DONE: %d pass, %d fail"):format(results.pass, results.fail))
	return results
end

return DevTest
