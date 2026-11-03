--!strict
-- Zone ambience (v4): eases the sky haze and ambient light toward the colors of the zone the local
-- player is running through, so each planet feels different. Client-only and cosmetic; if the
-- Atmosphere or the gates are missing it does nothing.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local player = Players.LocalPlayer

local Ambience = {}

local function gateZs(): { number }
	local zs: { number } = {}
	for _, wall in CollectionService:GetTagged("Gate") do
		local stage = wall:GetAttribute("Stage")
		if typeof(stage) == "number" and wall:IsA("BasePart") then
			zs[stage] = wall.Position.Z
		end
	end
	return zs
end

-- Zone index for a Z position: everything up to 50 studs past a stage's gate (its Wins pad) belongs to that stage.
function Ambience.zoneAtZ(zs: { number }, z: number): number
	for stage = 1, #Config.Stages do
		local gz = zs[stage]
		if gz and z < gz + 50 then
			return Config.Stages[stage].Zone
		end
	end
	return Config.Stages[#Config.Stages].Zone
end

function Ambience.start()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		return
	end
	local current = 0
	local zs: { number } = {}
	task.spawn(function()
		while true do
			task.wait(0.5)
			if #zs < #Config.Stages then
				zs = gateZs()
			end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and #zs >= #Config.Stages then
				local zone = Ambience.zoneAtZ(zs, hrp.Position.Z)
				local sky = Config.ZoneSky[zone]
				if zone ~= current and sky then
					current = zone
					local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					TweenService:Create(atmosphere, info, { Color = sky.Haze, Decay = sky.Decay }):Play()
					TweenService:Create(Lighting, info, { Ambient = sky.Ambient, OutdoorAmbient = sky.Ambient:Lerp(Color3.new(1, 1, 1), 0.12) }):Play()
				end
			end
		end
	end)
end

return Ambience
