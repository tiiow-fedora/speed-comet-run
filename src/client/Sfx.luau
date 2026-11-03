--!strict
-- Self-generated sound effects (uploaded via Open Cloud; IDs in ASSETS.md).
-- An ID of 0 means "no sound", so the game still works if an upload failed.

local SoundService = game:GetService("SoundService")

local Sfx = {}

local IDS: { [string]: number } = {
	tick = 0,
	gate = 82508232118513,
	wins = 84896431530730,
	buy = 110411125682552,
	error = 120527728848426,
	rebirth = 124698389615184,
	lap = 133366217740292,
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

-- Background music (synthesized loop, asset id in ASSETS.md)
local MUSIC_ID = 125033965097301
local music: Sound? = nil

function Sfx.startMusic()
	if music then
		return
	end
	local m = Instance.new("Sound")
	m.Name = "CometMusic"
	m.SoundId = "rbxassetid://" .. MUSIC_ID
	m.Looped = true
	m.Volume = 0.22
	m.Parent = SoundService
	m:Play()
	music = m
end

function Sfx.setMusic(on: boolean)
	if music then
		music.Volume = if on then 0.22 else 0
	end
end

return Sfx
