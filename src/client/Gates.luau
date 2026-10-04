--!strict
-- Opens gates locally once your Speed meets the requirement. Only this client's
-- simulation sees the gate as passable; the server separately rejects anyone who
-- crosses a gate without the Speed.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Sfx = require(script.Parent.Sfx)

local player = Players.LocalPlayer

local Gates = {}

local opened: { [BasePart]: boolean } = {}
local onOpen: ((stage: number) -> ())? = nil

local function update(wall: BasePart, initial: boolean)
	local req = wall:GetAttribute("Req") :: number? or math.huge
	local speed = (player:GetAttribute("Speed") :: number?) or 0
	local open = speed >= req
	if opened[wall] == open then
		return
	end
	opened[wall] = open
	wall.CanCollide = not open
	local goal = if open
		then { Color = Theme.Green, Transparency = 0.93 }
		else { Color = Color3.fromRGB(255, 60, 80), Transparency = 0.45 }
	if initial then
		wall.Color = goal.Color
		wall.Transparency = goal.Transparency
	else
		TweenService:Create(wall, TweenInfo.new(0.4), goal):Play()
		if open then
			Sfx.play("gate")
			if onOpen then
				onOpen(wall:GetAttribute("Stage") :: number)
			end
		end
	end
end

local function updateAll(initial: boolean)
	for _, wall in CollectionService:GetTagged("Gate") do
		if wall:IsA("BasePart") then
			update(wall, initial)
		end
	end
end

function Gates.start(openCallback: (stage: number) -> ())
	onOpen = openCallback
	CollectionService:GetInstanceAddedSignal("Gate"):Connect(function(w)
		if w:IsA("BasePart") then
			update(w, true)
		end
	end)
	updateAll(true)
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		updateAll(false)
	end)
end

function Gates.find(stage: number): BasePart?
	for _, wall in CollectionService:GetTagged("Gate") do
		if wall:GetAttribute("Stage") == stage then
			return wall :: BasePart
		end
	end
	return nil
end

function Gates.findPad(stage: number): BasePart?
	for _, pad in CollectionService:GetTagged("WinsPad") do
		if pad:GetAttribute("Stage") == stage then
			return pad :: BasePart
		end
	end
	return nil
end

return Gates
