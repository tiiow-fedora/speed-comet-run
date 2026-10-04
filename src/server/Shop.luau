--!strict
-- Boots shop, rebirth and daily reward. All inputs are validated server-side.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Gameplay = require(script.Parent.Gameplay)

local Shop = {}

local function validIndex(i: any): number?
	if typeof(i) ~= "number" or i ~= i or i % 1 ~= 0 or i < 1 or i > #Config.Boots then
		return nil
	end
	return i
end

function Shop.buyBoot(player: Player, raw: any)
	local i = validIndex(raw)
	local p = DataService.get(player)
	if not i or not p then
		return
	end
	local key = tostring(i)
	if p.Boots[key] then
		return Shop.equipBoot(player, i)
	end
	local boot = Config.Boots[i]
	if p.Wins < boot.Cost then
		Gameplay.notify(player, "error", "Need " .. Format.commas(boot.Cost - p.Wins) .. " more Wins")
		return
	end
	p.Wins -= boot.Cost
	p.Boots[key] = true
	p.Boot = i
	State.sync(player)
	Gameplay.applyTrail(player)
	Gameplay.notify(player, "buy", "Equipped " .. boot.Name .. " (x" .. boot.Mult .. " Speed)")
end

function Shop.equipBoot(player: Player, raw: any)
	local i = validIndex(raw)
	local p = DataService.get(player)
	if not i or not p or not p.Boots[tostring(i)] then
		return
	end
	p.Boot = i
	State.sync(player)
	Gameplay.applyTrail(player)
end

function Shop.rebirth(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	local cost = Config.RebirthCost(p.Rebirths)
	if p.Speed < cost then
		Gameplay.notify(player, "error", "Need " .. Format.commas(cost) .. " Speed to rebirth")
		return
	end
	p.Rebirths += 1
	p.Speed = 0
	p.Wins = 0
	State.sync(player)
	Gameplay.applyWalkSpeed(player, p)
	Gameplay.resetLap(player)
	Gameplay.teleport(player, Gameplay.layout().SpawnCFrame)
	Gameplay.notify(player, "rebirth", "Rebirth " .. p.Rebirths .. "! Speed gain is now x" .. (1 + p.Rebirths) .. " from rebirths")
end

function Shop.dailyState(p: DataService.Profile): (boolean, number)
	local now = os.time()
	local ready = now - p.LastDaily >= Config.DailyCooldown
	local nextStreak = if now - p.LastDaily <= Config.DailyStreakWindow then p.DailyStreak + 1 else 1
	return ready, math.min(nextStreak, Config.DailyMaxDay)
end

function Shop.refreshDaily(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	local ready, day = Shop.dailyState(p)
	player:SetAttribute("DailyReady", ready)
	player:SetAttribute("DailyDay", day)
end

function Shop.claimDaily(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	local ready, day = Shop.dailyState(p)
	if not ready then
		return
	end
	local now = os.time()
	p.DailyStreak = if now - p.LastDaily <= Config.DailyStreakWindow then p.DailyStreak + 1 else 1
	p.LastDaily = now
	local wins = Config.DailyWinsPerDay * day
	p.Wins += wins
	p.TotalWins += wins
	local msg = "Day " .. day .. " reward: +" .. wins .. " Wins"
	if day >= Config.DailyMaxDay then
		p.PotionLeft += Config.PotionSeconds
		msg ..= " + free 3x Speed Potion!"
	end
	State.sync(player)
	Shop.refreshDaily(player)
	Gameplay.notify(player, "daily", msg)
end

return Shop
