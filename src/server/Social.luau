--!strict
-- High-fives (v5): two players standing close together can high-five once per pair every PairCooldown seconds.
-- Both get HighFiveSeconds of their own Speed gain (double between Roblox friends). The server checks the
-- distance itself, rate limits each player per hour, and never trusts anything the client says except
-- "I want to high-five that player".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Gameplay = require(script.Parent.Gameplay)
local Achievements = require(script.Parent.Achievements)

local Social = {}

local pairLast: { [string]: number } = {} -- "lowId:highId" -> os.clock() of the last high-five
local history: { [Player]: { number } } = {} -- os.clock() stamps of this player's recent high-fives

local function hrpOf(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function recent(player: Player, now: number): number
	local list = history[player] or {}
	local keep = {}
	for _, t in list do
		if now - t < 3600 then
			table.insert(keep, t)
		end
	end
	history[player] = keep
	return #keep
end

local function grant(player: Player, other: Player, mult: number, t: number)
	local p = DataService.get(player)
	if not p then
		return 0
	end
	local amount = math.floor(math.max(Config.ShardMin, Gameplay.multiplier(player, p) * Config.HighFive.Seconds * mult))
	p.Speed += amount
	Achievements.bump(p, "HighFives")
	State.syncSpeed(player, p)
	Gameplay.notify(player, "highfive", "🙌 High five with " .. other.DisplayName .. "! +" .. Format.short(amount) .. " ⚡")
	table.insert(history[player], t)
	return amount
end

-- Returns true when the high-five happened. `now` is injectable for tests.
function Social.highFive(player: Player, target: any, now: number?): boolean
	local t = now or os.clock()
	if typeof(target) ~= "Instance" or not (target :: Instance):IsA("Player") then
		return false
	end
	local other = target :: Player
	if other == player or other.Parent ~= Players or not DataService.get(other) or not DataService.get(player) then
		return false
	end
	local a, b = hrpOf(player), hrpOf(other)
	if not a or not b or (a.Position - b.Position).Magnitude > Config.HighFive.Range then
		return false
	end
	local lo, hi = math.min(player.UserId, other.UserId), math.max(player.UserId, other.UserId)
	local key = lo .. ":" .. hi
	if pairLast[key] and t - pairLast[key] < Config.HighFive.PairCooldown then
		Gameplay.notify(player, "error", "You already high-fived " .. other.DisplayName .. " a moment ago")
		return false
	end
	if recent(player, t) >= Config.HighFive.PerHour or recent(other, t) >= Config.HighFive.PerHour then
		Gameplay.notify(player, "error", "High-five limit reached for now. Try again later")
		return false
	end
	pairLast[key] = t
	local ok, friends = pcall(player.IsFriendsWith, player, other.UserId)
	local mult = if ok and friends then Config.HighFive.FriendMult else 1
	grant(player, other, mult, t)
	grant(other, player, mult, t)
	return true
end

function Social.clear(player: Player)
	history[player] = nil
	local id = tostring(player.UserId)
	for key in pairLast do
		local lo, hi = string.match(key, "^(%d+):(%d+)$")
		if lo == id or hi == id then
			pairLast[key] = nil
		end
	end
end

function Social.addPlayer(player: Player)
	history[player] = {}
end

return Social
