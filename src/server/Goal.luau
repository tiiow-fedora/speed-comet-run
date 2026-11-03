--!strict
-- Server-wide shard goal (v4): every Comet Shard any player collects fills one shared bar.
-- When it fills, everyone currently on the server gets Config.Goal.BoostMult Speed gain for
-- Config.Goal.BoostSeconds. Nothing here is saved or paid: it is a free, temporary, shared boost.
-- State is mirrored to ReplicatedStorage attributes for the HUD (display only).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Goal = {}

local progress = 0
local boostUntil = 0 -- workspace:GetServerTimeNow() seconds; same clock on server and clients
local announceFn: ((string) -> ())? = nil
local triggers = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

function Goal.setAnnounce(fn: (string) -> ())
	announceFn = fn
end

function Goal.target(): number
	return Config.GoalTarget(#Players:GetPlayers())
end

function Goal.boostActive(): boolean
	return now() < boostUntil
end

function Goal.multiplier(): number
	return if Goal.boostActive() then Config.Goal.BoostMult else 1
end

function Goal.progress(): number
	return progress
end

function Goal.triggers(): number
	return triggers
end

local function publish()
	ReplicatedStorage:SetAttribute("GoalProgress", progress)
	ReplicatedStorage:SetAttribute("GoalTarget", Goal.target())
	ReplicatedStorage:SetAttribute("GoalBoostEnds", boostUntil)
end

-- Call when the player count changes: the target scales with it.
function Goal.refresh()
	publish()
end

-- Shards (or `amount` of them) collected. Shards collected while a boost is running are not counted,
-- so the bar always restarts from empty after the boost ends.
function Goal.add(amount: number?)
	if Goal.boostActive() then
		return
	end
	progress += amount or 1
	if progress >= Goal.target() then
		progress = 0
		triggers += 1
		boostUntil = math.floor(now()) + Config.Goal.BoostSeconds
		if announceFn then
			announceFn("COMET BOOST! Server shard goal reached: x" .. Config.Goal.BoostMult .. " Speed for " .. math.floor(Config.Goal.BoostSeconds / 60) .. " min!")
		end
		-- clear the "ends" marker for late joiners once it is over
		task.delay(Config.Goal.BoostSeconds + 1, publish)
	end
	publish()
end

-- Studio tests only.
function Goal.resetForTest()
	progress = 0
	boostUntil = 0
	publish()
end

publish()

return Goal
