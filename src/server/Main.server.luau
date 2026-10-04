--!strict
-- Server entry point: build the map, wire remotes, load/save players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local PropLoader = require(script.Parent.PropLoader)
local Leaderboard = require(script.Parent.Leaderboard)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Passes = require(script.Parent.Passes)
local RateLimit = require(script.Parent.RateLimit)
local Gameplay = require(script.Parent.Gameplay)
local Shop = require(script.Parent.Shop)
local Monetization = require(script.Parent.Monetization)

StarterPlayer.CharacterUseJumpPower = false
StarterPlayer.CharacterJumpHeight = Config.JumpHeight
StarterPlayer.CharacterWalkSpeed = Config.BaseWalkSpeed

PropLoader.load(8)
local layout = MapBuilder.build()
Leaderboard.build(workspace:WaitForChild("Map"))
Leaderboard.start()

-- Remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local notify = remote("Notify")
local buyBoot = remote("BuyBoot")
local equipBoot = remote("EquipBoot")
local rebirth = remote("Rebirth")
local claimDaily = remote("ClaimDaily")
local tutorialDone = remote("TutorialDone")
local restartLap = remote("RestartLap")
local setSlow = remote("SetSlow")
remotes.Parent = ReplicatedStorage

local function guarded(name: string, rate: number, fn: (Player, ...any) -> ())
	return function(player: Player, ...)
		if not DataService.get(player) then
			return
		end
		if not RateLimit.allow(player, name, rate, 4) then
			return
		end
		fn(player, ...)
	end
end

buyBoot.OnServerEvent:Connect(guarded("BuyBoot", 3, Shop.buyBoot))
equipBoot.OnServerEvent:Connect(guarded("EquipBoot", 3, Shop.equipBoot))
rebirth.OnServerEvent:Connect(guarded("Rebirth", 1, Shop.rebirth))
claimDaily.OnServerEvent:Connect(guarded("ClaimDaily", 1, Shop.claimDaily))
restartLap.OnServerEvent:Connect(guarded("RestartLap", 0.5, function(player: Player)
	Gameplay.resetLap(player)
	Gameplay.teleport(player, layout.SpawnCFrame)
end))
setSlow.OnServerEvent:Connect(guarded("SetSlow", 2, function(player: Player, on: any)
	Gameplay.setSlow(player, on == true)
end))
tutorialDone.OnServerEvent:Connect(guarded("TutorialDone", 1, function(player: Player)
	local p = DataService.get(player)
	if p and not p.TutorialDone then
		p.TutorialDone = true
		player:SetAttribute("TutorialDone", true)
	end
end))

Gameplay.start(layout, notify)
Monetization.start()

local function onPlayerAdded(player: Player)
	State.setupLeaderstats(player)
	DataService.load(player)
	if player.Parent == nil then
		-- left while loading
		DataService.release(player)
		return
	end
	Passes.load(player)
	Gameplay.addPlayer(player)
	State.sync(player)
	Shop.refreshDaily(player)
	player:SetAttribute("Loaded", true)
	player:SetAttribute("DataSaving", DataService.isLoaded(player))
	player.CharacterAdded:Connect(function(character)
		Gameplay.onCharacter(player, character)
	end)
	if player.Character then
		Gameplay.onCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	Gameplay.removePlayer(player)
	Passes.clear(player)
	RateLimit.clear(player)
end)

DataService.start(function(player: Player)
	local p = DataService.get(player)
	if p and DataService.isLoaded(player) then
		Leaderboard.submit(player.UserId, p.TotalWins)
	end
end)

-- Studio-only hook so the command bar can run the self test inside the game's VM:
--   game.ServerScriptService.DevRun:Invoke()
if game:GetService("RunService"):IsStudio() then
	local devRun = Instance.new("BindableFunction")
	devRun.Name = "DevRun"
	devRun.OnInvoke = function(what: string?)
		return require(script.Parent.DevTest).run()
	end
	devRun.Parent = game:GetService("ServerScriptService")
end

print("[CometRun] server ready, " .. #layout.Stages .. " stages, track length " .. math.floor(layout.EndZ))
