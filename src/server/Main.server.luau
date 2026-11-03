--!strict
-- Server entry point: build the map, wire remotes, load/save players.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage.Shared.Config)
local MapBuilder = require(script.Parent.MapBuilder)
local PropLoader = require(script.Parent.PropLoader)
local Leaderboard = require(script.Parent.Leaderboard)
local Quests = require(script.Parent.Quests)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Passes = require(script.Parent.Passes)
local RateLimit = require(script.Parent.RateLimit)
local Gameplay = require(script.Parent.Gameplay)
local Shop = require(script.Parent.Shop)
local Monetization = require(script.Parent.Monetization)
local Goal = require(script.Parent.Goal)
local Gifts = require(script.Parent.Gifts)

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
local claimQuest = remote("ClaimQuest")
local buyPet = remote("BuyPet")
local equipPet = remote("EquipPet")
local claimGift = remote("ClaimGift")
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
	Quests.event(player, "restart", 1)
end))
claimQuest.OnServerEvent:Connect(guarded("ClaimQuest", 2, Quests.claim))
buyPet.OnServerEvent:Connect(guarded("BuyPet", 3, Shop.buyPet))
equipPet.OnServerEvent:Connect(guarded("EquipPet", 3, Shop.equipPet))
claimGift.OnServerEvent:Connect(guarded("ClaimGift", 3, Gifts.claim))
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
Quests.setNotify(Gameplay.notify)
Gifts.setNotify(Gameplay.notify)
Goal.setAnnounce(function(text: string)
	Gameplay.broadcast("goal", text)
end)
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
	local firstJoin = Gameplay.welcomeIfNew(player)
	Gameplay.addPlayer(player)
	State.sync(player)
	Shop.refreshDaily(player)
	local prof = DataService.get(player)
	if prof then
		Quests.ensure(player, prof)
		Quests.sync(player)
		Gifts.sync(player)
	end
	player:SetAttribute("Loaded", true)
	if firstJoin then
		task.delay(3, function()
			Gameplay.notify(player, "welcome", "Welcome! Gift: 3x Speed for 2 minutes!")
		end)
	end
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
		Leaderboard.submitTo("TopSpeed", player.UserId, p.BestSpeed)
	end
end)

-- Studio-only hook so the command bar can run the self test inside the game's VM:
--   game.ServerScriptService.DevRun:Invoke()
if game:GetService("RunService"):IsStudio() then
	local devRun = Instance.new("BindableFunction")
	devRun.Name = "DevRun"
	devRun.OnInvoke = function(what: string?, arg: any?)
		if what == "fresh" then
			-- wipe player N's profile in memory (Studio only) to replay the new-player flow
			local player = Players:GetPlayers()[tonumber(arg) or 1]
			DataService.resetForTest(player)
			local welcomed = Gameplay.welcomeIfNew(player)
			Gameplay.resetLap(player)
			State.sync(player)
			Shop.refreshDaily(player)
			player:LoadCharacter()
			return player.Name .. " welcomed=" .. tostring(welcomed) .. " potion=" .. tostring((DataService.get(player) :: any).PotionLeft)
		end
		if what == "welcome" then
			-- replay the first-join welcome (toast + camera intro) for player N
			Gameplay.notify(Players:GetPlayers()[tonumber(arg) or 1], "welcome", "Welcome! Gift: 3x Speed for 2 minutes!")
			return true
		end
		if what == "tp" then
			-- legit server teleport (sets anti-cheat grace) to just before gate `arg`
			local player = Players:GetPlayers()[1]
			local st = layout.Stages[tonumber(arg) or 1]
			Gameplay.teleport(player, CFrame.lookAt(Vector3.new(0, Config.TrackY + 4, st.GateZ - 60), Vector3.new(0, Config.TrackY + 4, st.GateZ)))
			return true
		end
		return require(script.Parent.DevTest).run()
	end
	devRun.Parent = game:GetService("ServerScriptService")
end

print("[CometRun] server ready, " .. #layout.Stages .. " stages, track length " .. math.floor(layout.EndZ) .. ", map parts " .. tostring(layout.PartCount))
