--!strict
-- Playtime gifts (v4): cumulative minutes played per UTC day unlock free gifts (Wins, sometimes a potion).
-- Progress lives in the profile (GiftDay / GiftSeconds / GiftClaims), so rejoining does not reset the timer
-- and does not give the gifts twice. Free for everyone; nothing here is purchasable.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Quests = require(script.Parent.Quests)

local Gifts = {}

local notify: ((Player, string, string) -> ())? = nil
function Gifts.setNotify(fn: (Player, string, string) -> ())
	notify = fn
end

local function rollDay(p: DataService.Profile)
	local today = Quests.today()
	if p.GiftDay ~= today then
		p.GiftDay = today
		p.GiftSeconds = 0
		p.GiftClaims = {}
	end
end

local function unlocked(p: DataService.Profile, i: number): boolean
	local g = Config.Gifts[i]
	return g ~= nil and p.GiftSeconds >= g.Minutes * 60
end

local function readyCount(p: DataService.Profile): number
	local n = 0
	for i = 1, #Config.Gifts do
		if unlocked(p, i) and not p.GiftClaims[tostring(i)] then
			n += 1
		end
	end
	return n
end

local function claimedString(p: DataService.Profile): string
	local list = {}
	for i = 1, #Config.Gifts do
		if p.GiftClaims[tostring(i)] then
			table.insert(list, tostring(i))
		end
	end
	return table.concat(list, ",")
end

function Gifts.sync(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	rollDay(p)
	player:SetAttribute("GiftSec", p.GiftSeconds)
	player:SetAttribute("GiftClaimed", claimedString(p))
	player:SetAttribute("GiftReady", readyCount(p) > 0)
end

-- Called once per second from the speed tick. Attributes only change when a value really changes.
function Gifts.tick(player: Player, p: DataService.Profile)
	rollDay(p)
	p.GiftSeconds += 1
	player:SetAttribute("GiftSec", p.GiftSeconds)
	local ready = readyCount(p) > 0
	if ready ~= player:GetAttribute("GiftReady") then
		player:SetAttribute("GiftReady", ready)
		if ready and notify then
			notify(player, "gift", "A free gift is ready! Open 🎁 DAILY")
		end
	end
end

function Gifts.claim(player: Player, raw: any)
	local p = DataService.get(player)
	if not p or typeof(raw) ~= "number" or raw ~= raw or raw % 1 ~= 0 or raw < 1 or raw > #Config.Gifts then
		return
	end
	rollDay(p)
	local key = tostring(raw)
	if p.GiftClaims[key] or not unlocked(p, raw) then
		return
	end
	local g = Config.Gifts[raw]
	p.GiftClaims[key] = true
	local wins = Quests.winsFor(p, g.Mult * Config.CurrentEvent().GiftMult)
	p.Wins += wins
	p.TotalWins += wins
	local msg = "Gift: +" .. Format.commas(wins) .. " Wins"
	if g.PotionSeconds > 0 then
		p.PotionLeft += g.PotionSeconds
		msg ..= " + " .. Format.time(g.PotionSeconds) .. " of 3x Speed!"
	end
	State.sync(player)
	Gifts.sync(player)
	if notify then
		notify(player, "buy", msg)
	end
end

return Gifts
