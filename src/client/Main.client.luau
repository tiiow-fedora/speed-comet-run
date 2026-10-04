--!strict
-- Client entry: HUD, gates, onboarding guide beam + hints, notifications, VIP chat tag.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)
local Sfx = require(script.Parent.Sfx)
local Hud = require(script.Parent.Hud)
local Gates = require(script.Parent.Gates)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

while not player:GetAttribute("Loaded") do
	player:GetAttributeChangedSignal("Loaded"):Wait()
end

Hud.build()

-- ===== onboarding =====
-- Steps: 1 run to gate, 2 gate open -> go through to the pad, 3 got wins -> open the shop, done.
local tutorialStep = if player:GetAttribute("TutorialDone") then 99 else 1
local firstWinsSeen = false

local function setStep(n: number)
	tutorialStep = n
	if n >= 99 then
		Hud.hint(nil)
		remotes.TutorialDone:FireServer()
	end
end

Gates.start(function(stage)
	if tutorialStep == 1 and stage == 1 then
		setStep(2)
	end
	Hud.toast("Gate " .. stage .. " is OPEN!", Theme.Green)
end)

-- Guide beam from the character to the next target (gate, or pad once the gate is open).
local beam: Beam? = nil
local targetAtt = Instance.new("Attachment")
targetAtt.Name = "GuideTarget"
targetAtt.Parent = workspace.Terrain

local function ensureBeam(): Beam?
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	if beam and beam.Parent == hrp then
		return beam
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "GuideFrom"
	a0.Position = Vector3.new(0, -2.5, 0)
	a0.Parent = hrp
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = targetAtt
	b.Width0 = 0.5
	b.Width1 = 0.5
	b.FaceCamera = true
	b.LightEmission = 0.3
	b.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	b.TextureMode = Enum.TextureMode.Static
	b.TextureLength = 4
	b.TextureSpeed = 2
	b.Color = ColorSequence.new(Theme.Gold)
	b.Transparency = NumberSequence.new(0.35, 0.8)
	b.Segments = 1
	b.Parent = hrp
	beam = b
	return b
end

local function hintText(): string?
	local speed = (player:GetAttribute("Speed") :: number?) or 0
	local n = Hud.nextStage()
	if tutorialStep == 1 and speed >= Config.Stages[1].Req then
		setStep(2)
	end
	if tutorialStep == 1 then
		local req = Config.Stages[1].Req
		return "Every second you get +⚡ Speed! Reach ⚡" .. req .. " to open the gate (" .. math.min(speed, req) .. "/" .. req .. ")"
	elseif tutorialStep == 2 then
		return "The gate is open! Run through and step on the 🏆 Wins pad"
	elseif tutorialStep == 3 then
		return "Spend Wins on faster Boots! Tap 👟 BOOTS"
	end
	if n then
		local req = Config.Stages[n].Req
		if speed < req * 0.5 and n > 2 then
			return "Gate " .. n .. " needs ⚡" .. Format.short(req) .. ". Tap ↩️ RESTART to farm Wins pads, then buy faster Boots!"
		end
	end
	return nil
end

local lastBeamUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastBeamUpdate < 0.2 then
		return
	end
	lastBeamUpdate = now
	local n = Hud.nextStage()
	local speed = (player:GetAttribute("Speed") :: number?) or 0
	local b = ensureBeam()
	local showBeam = tutorialStep < 99 or (player:GetAttribute("BestStage") :: number? or 0) < 3
	if b then
		if n and showBeam then
			local target = if speed >= Config.Stages[n].Req then Gates.findPad(n) else Gates.find(n)
			if target then
				local pos = target.Position
				targetAtt.WorldPosition = Vector3.new(0, Config.TrackY + 0.5, pos.Z)
				b.Enabled = true
			else
				b.Enabled = false
			end
		else
			b.Enabled = false
		end
	end
	Hud.hint(hintText())
end)

-- point the camera down the track after each spawn/teleport to spawn
local function faceCamera(char: Model)
	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp then
		return
	end
	task.wait(0.35) -- server places the character first
	local cam = workspace.CurrentCamera
	local look = hrp.CFrame.LookVector
	cam.CFrame = CFrame.lookAt(hrp.Position - look * 16 + Vector3.new(0, 7, 0), hrp.Position + look * 10)
end
player.CharacterAdded:Connect(faceCamera)
if player.Character then
	task.spawn(faceCamera, player.Character)
end

-- ===== notifications from the server =====
remotes.Notify.OnClientEvent:Connect(function(kind: string, text: string, extra: any)
	if kind == "wins" then
		Sfx.play("wins")
		Hud.toast(text, Theme.Gold)
		if not firstWinsSeen then
			firstWinsSeen = true
			if tutorialStep <= 2 then
				setStep(3)
				Hud.pulse("Shop")
			end
		end
		if extra and extra.final then
			Hud.toast("🏁 FINISH! Returning to start…", Theme.Gold)
		end
	elseif kind == "error" then
		Sfx.play("error")
		Hud.toast(text, Theme.Red)
	elseif kind == "buy" or kind == "purchase" then
		Sfx.play("buy")
		Hud.toast(text, Theme.Green)
	elseif kind == "rebirth" then
		Sfx.play("rebirth")
		if player.Character then
			task.spawn(faceCamera, player.Character)
		end
		Hud.toast(text, Theme.Pink)
	elseif kind == "lap" then
		Sfx.play("lap")
		if player.Character then
			task.spawn(faceCamera, player.Character)
		end
		Hud.toast(text, Theme.Accent)
	elseif kind == "daily" then
		Sfx.play("buy")
		Hud.toast(text, Theme.Green)
	else
		Hud.toast(text, Theme.Text)
	end
end)

-- finish the tutorial once the player has looked at the shop
local shopPanelSeen = false
task.spawn(function()
	while tutorialStep < 99 do
		task.wait(0.5)
		local gui = player.PlayerGui:FindFirstChild("CometHud")
		local panel = gui and gui:FindFirstChild("ShopPanel", true) :: Frame?
		if tutorialStep == 3 and panel and panel.Visible then
			shopPanelSeen = true
		end
		if shopPanelSeen and panel and not panel.Visible then
			setStep(99)
		end
	end
end)

-- daily reward popup on join
task.delay(4, function()
	if player:GetAttribute("DailyReady") and tutorialStep >= 99 then
		Hud.openPanel("Daily")
	end
end)

-- [VIP] chat tag
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local src = message.TextSource
	if src then
		local plr = Players:GetPlayerByUserId(src.UserId)
		if plr and plr:GetAttribute("Pass_VIP") then
			props.PrefixText = '<font color="#FFD23C">[VIP]</font> ' .. message.PrefixText
		end
	end
	return props
end

if not player:GetAttribute("DataSaving") then
	task.delay(3, function()
		Hud.toast("Progress can't be saved right now (Roblox data issue)", Theme.Red)
	end)
end
