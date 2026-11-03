--!strict
-- Trophies (v5): free achievements. The server compares lifetime stats with Config.Trophies on its 1 s tick and
-- awards each trophy once (Wins + toast, and a Roblox badge if the owner filled in Config.BadgeIds).
-- Progress is mirrored to two display-only Player attributes: TrophyData and TrophiesDone.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Quests = require(script.Parent.Quests)

local Achievements = {}

local notify: ((Player, string, string) -> ())? = nil
function Achievements.setNotify(fn: (Player, string, string) -> ())
	notify = fn
end

local function count(t: { [string]: boolean }): number
	local n = 0
	for _, v in t do
		if v then
			n += 1
		end
	end
	return n
end

function Achievements.stat(p: DataService.Profile, name: string): number
	if name == "BestStage" then
		return p.BestStage
	elseif name == "Pets" then
		return count(p.Pets)
	elseif name == "Boots" then
		return count(p.Boots)
	elseif name == "Rebirths" then
		return p.Rebirths
	elseif name == "TrioStreak" then
		return if p.TrioDay >= Quests.today() - 1 then p.TrioStreak else 0
	elseif name == "PlayMinutes" then
		return p.PlaySeconds // 60
	end
	return p.Stats[name] or 0 -- Shards, Finishes, HighFives
end

-- Add to a lifetime counter (the 1 s check turns it into trophies).
function Achievements.bump(p: DataService.Profile, name: string, amount: number?)
	p.Stats[name] = (p.Stats[name] or 0) + (amount or 1)
end

local function dataString(p: DataService.Profile): string
	local parts = {}
	for i, name in Config.TrophyStats do
		parts[i] = tostring(math.floor(Achievements.stat(p, name)))
	end
	return table.concat(parts, ",")
end

local function doneString(p: DataService.Profile): string
	local list = {}
	for i, t in Config.Trophies do
		if p.Trophies[t.Id] then
			table.insert(list, tostring(i))
		end
	end
	return table.concat(list, ",")
end

local function awardBadge(player: Player, id: string)
	local badge = Config.BadgeIds[id]
	if badge and badge > 0 then
		task.spawn(function()
			pcall(function()
				game:GetService("BadgeService"):AwardBadge(player.UserId, badge)
			end)
		end)
	end
end

-- Returns how many trophies were newly awarded.
function Achievements.check(player: Player): number
	local p = DataService.get(player)
	if not p then
		return 0
	end
	local awarded = 0
	local totalWins = 0
	local lastName = ""
	for _, t in Config.Trophies do
		if not p.Trophies[t.Id] and Achievements.stat(p, t.Stat) >= t.Target then
			p.Trophies[t.Id] = true
			awarded += 1
			local wins = Quests.winsFor(p, t.WinsMult)
			p.Wins += wins
			p.TotalWins += wins
			totalWins += wins
			lastName = t.Name
			awardBadge(player, t.Id)
		end
	end
	if awarded > 0 then
		State.sync(player)
		if notify then
			-- one toast per check, so an existing player joining with ten finished goals is not spammed
			local text = if awarded == 1 then "TROPHY: " .. lastName .. "! +" else awarded .. " TROPHIES unlocked! +"
			notify(player, "trophy", text .. Format.commas(totalWins) .. " Wins")
		end
	end
	local data = dataString(p)
	if player:GetAttribute("TrophyData") ~= data then
		player:SetAttribute("TrophyData", data)
	end
	if awarded > 0 or player:GetAttribute("TrophiesDone") == nil then
		player:SetAttribute("TrophiesDone", doneString(p))
	end
	return awarded
end

return Achievements
