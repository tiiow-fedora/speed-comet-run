--!strict
-- Self-generated sound effects (uploaded via Open Cloud; IDs in ASSETS.md).
-- An ID of 0 means "no sound", so the game still works if an upload failed.

local SoundService = game:GetService("SoundService")

local Sfx = {}

local IDS: { [string]: number } = {
	tick = 0,
	gate = 0,
	wins = 0,
	buy = 0,
	error = 0,
	rebirth = 0,
	lap = 0,
}
Sfx.IDS = IDS

local cache: { [string]: Sound } = {}

function Sfx.play(name: string, volume: number?)
	local id = IDS[name]
	if not id or id == 0 then
		return
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. id
		s.Volume = volume or 0.6
		s.Parent = SoundService
		cache[name] = s
	end
	SoundService:PlayLocalSound(s)
end

return Sfx
