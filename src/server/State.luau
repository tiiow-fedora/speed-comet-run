--!strict
-- Mirrors each player's profile into replicated Player attributes + leaderstats.
-- The profile (server memory) is authoritative; attributes are display-only for clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)

local State = {}

local function ownedString(p: DataService.Profile): string
	local list = {}
	for i = 1, #Config.Boots do
		if p.Boots[tostring(i)] then
			table.insert(list, tostring(i))
		end
	end
	return table.concat(list, ",")
end

function State.setupLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, name in { "Speed", "Wins", "Rebirths" } do
		local v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	ls.Parent = player
end

-- Push every profile field the client cares about.
function State.sync(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	player:SetAttribute("Speed", math.floor(p.Speed))
	player:SetAttribute("Wins", math.floor(p.Wins))
	player:SetAttribute("Rebirths", p.Rebirths)
	player:SetAttribute("Boot", p.Boot)
	player:SetAttribute("OwnedBoots", ownedString(p))
	player:SetAttribute("PotionLeft", math.floor(p.PotionLeft))
	player:SetAttribute("BestStage", p.BestStage)
	player:SetAttribute("TutorialDone", p.TutorialDone)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls:FindFirstChild("Speed") :: IntValue).Value = math.floor(p.Speed);
		(ls:FindFirstChild("Wins") :: IntValue).Value = math.floor(p.Wins);
		(ls:FindFirstChild("Rebirths") :: IntValue).Value = p.Rebirths
	end
end

-- Cheap path used by the 1 s speed tick.
function State.syncSpeed(player: Player, p: DataService.Profile)
	local s = math.floor(p.Speed)
	player:SetAttribute("Speed", s)
	player:SetAttribute("PotionLeft", math.floor(p.PotionLeft))
	local ls = player:FindFirstChild("leaderstats")
	local v = ls and ls:FindFirstChild("Speed") :: IntValue?
	if v then
		v.Value = s
	end
end

return State
