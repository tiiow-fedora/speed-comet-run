--!strict
-- Client entry: HUD, gates, onboarding guide beam + hints, notifications, VIP chat tag.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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
Sfx.startMusic()

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
	local wall = Gates.find(stage)
	if wall then
		-- v3: visible feedback when a gate opens
		local att = Instance.new("Attachment")
		att.Parent = wall
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Rate = 0
		pe.Speed = NumberRange.new(15, 30)
		pe.Lifetime = NumberRange.new(0.6, 1.1)
		pe.SpreadAngle = Vector2.new(70, 70)
		pe.Size = NumberSequence.new(1.4, 0)
		pe.Color = ColorSequence.new(Theme.Green)
		pe.Parent = att
		pe:Emit(60)
		task.delay(1.5, function()
			att:Destroy()
		end)
	end
	Hud.toast("Gate " .. stage .. " is OPEN!", Theme.Green)
end)

-- Guide: a bobbing arrow over the next target (gate, or pad once the gate is open),
-- plus a thin beam only while the target is far away (up close a beam fills the screen).
local beam: Beam? = nil
local targetAtt = Instance.new("Attachment")
targetAtt.Name = "GuideTarget"
targetAtt.Parent = workspace.Terrain

local marker = Instance.new("BillboardGui")
marker.Name = "GuideMarker"
marker.Adornee = targetAtt
marker.Size = UDim2.fromOffset(90, 90)
marker.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
marker.AlwaysOnTop = true
marker.LightInfluence = 0
marker.Enabled = false
marker.Parent = player:WaitForChild("PlayerGui")
local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.fromScale(1, 1)
arrow.BackgroundTransparency = 1
arrow.Text = "⬇"
arrow.TextScaled = true
arrow.Font = Enum.Font.FredokaOne
arrow.TextColor3 = Theme.Gold
arrow.TextStrokeTransparency = 0
arrow.Parent = marker
task.spawn(function()
	local up = true
	while marker.Parent do
		TweenService:Create(marker, TweenInfo.new(0.6, Enum.EasingStyle.Sine), {
			StudsOffsetWorldSpace = Vector3.new(0, if up then 11 else 8, 0),
		}):Play()
		up = not up
		task.wait(0.6)
	end
end)

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
	b.Width0 = 0.3
	b.Width1 = 0.3
	b.FaceCamera = true
	b.LightEmission = 0
	b.Color = ColorSequence.new(Theme.Gold)
	b.Transparency = NumberSequence.new(0.5, 0.9)
	b.Segments = 1
	b.Parent = hrp
	beam = b
	return b
end

local jumpShort = if UserInputService.TouchEnabled then "Tap ⬆ to jump" else "SPACE to jump"

local function hintText(): string?
	local speed = (player:GetAttribute("Speed") :: number?) or 0
	local cp = (player:GetAttribute("Checkpoint") :: number?) or 0
	local n = Hud.nextStage()
	local req1 = Config.Stages[1].Req
	-- the tutorial step follows real (server) state so it can never go stale
	if tutorialStep < 3 then
		local derived = if cp >= 1 or (player:GetAttribute("BestStage") :: number? or 0) >= 1 then 3 elseif speed >= req1 then 2 else 1
		if derived == 3 and tutorialStep < 3 then
			Hud.pulse("Shop")
		end
		tutorialStep = derived
	end
	-- v3: short hints (<= ~6 words), and always a concrete next goal after the tutorial
	if tutorialStep == 1 then
		return "Grab ⚡ shards, run to the gate! " .. math.min(speed, req1) .. "/" .. req1
	elseif tutorialStep == 2 then
		return "Gate open! " .. jumpShort .. " to the 🏆 pad"
	elseif tutorialStep == 3 then
		return "Buy faster Boots! 👟"
	end
	return Hud.nextGoal()
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
	local showGuide = tutorialStep < 99 or (player:GetAttribute("BestStage") :: number? or 0) < 3
	local target = nil
	if n and showGuide then
		target = if speed >= Config.Stages[n].Req then Gates.findPad(n) else Gates.find(n)
	end
	if target then
		targetAtt.WorldPosition = Vector3.new(0, Config.TrackY + 0.5, target.Position.Z)
		marker.Enabled = true
		arrow.TextColor3 = if speed >= Config.Stages[n :: number].Req then Theme.Gold else Theme.Red
		if b then
			b.Enabled = false -- v3: the beam read as a yellow strip on the floor; the marker is enough
		end
	else
		marker.Enabled = false
		if b then
			b.Enabled = false
		end
	end
	Hud.hint(hintText())
end)

-- First-join intro: 3 s camera fly-down of the track, then back to the player.
local function playIntro()
	local cam = workspace.CurrentCamera
	local g1 = Gates.find(1)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not g1 or not hrp then
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	local y = Config.TrackY
	cam.CFrame = CFrame.lookAt(Vector3.new(-40, y + 60, g1.Position.Z + 120), Vector3.new(0, y, g1.Position.Z))
	local tw = TweenService:Create(cam, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		-- end behind the player, looking down the track (+Z)
		CFrame = CFrame.lookAt(hrp.Position + Vector3.new(0, 7, -16), hrp.Position + Vector3.new(0, 0, 10)),
	})
	tw:Play()
	tw.Completed:Wait()
	cam.CameraType = Enum.CameraType.Custom
end

-- re-show this player's shards when a new lap starts (server bumps the Lap attribute)
player:GetAttributeChangedSignal("Lap"):Connect(function()
	for _, sh in CollectionService:GetTagged("Shard") do
		if sh:IsA("BasePart") then
			sh.LocalTransparencyModifier = 0
		end
	end
end)

-- slowly spinning shards (client-side visual only; ~30 parts, 10 Hz)
task.spawn(function()
	local angle = 0
	while true do
		task.wait(0.1)
		angle += 0.25
		for _, sh in CollectionService:GetTagged("Shard") do
			if sh:IsA("BasePart") then
				local pos = sh.Position
				sh.CFrame = CFrame.new(pos) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
			end
		end
	end
end)

-- ambient sparkles around the camera (cheap: one emitter, low rate)
do
	local holder = Instance.new("Part")
	holder.Name = "AmbientSparkles"
	holder.Anchored = true
	holder.CanCollide, holder.CanTouch, holder.CanQuery = false, false, false
	holder.Transparency = 1
	holder.Size = Vector3.new(60, 20, 60)
	holder.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 6
	pe.Lifetime = NumberRange.new(3, 5)
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 255), Color3.fromRGB(180, 240, 255))
	pe.LightEmission = 0.4
	pe.Parent = holder
	RunService.RenderStepped:Connect(function()
		holder.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position)
	end)
end

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
	elseif kind == "shard" then
		Sfx.play("buy", 0.35)
		Hud.popText(text)
		local id = extra and extra.id
		for _, sh in CollectionService:GetTagged("Shard") do
			if sh:GetAttribute("Id") == id and sh:IsA("BasePart") then
				sh.LocalTransparencyModifier = 1
				local burst = Instance.new("ParticleEmitter")
				burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				burst.Rate = 0
				burst.Speed = NumberRange.new(8, 14)
				burst.Lifetime = NumberRange.new(0.4, 0.7)
				burst.SpreadAngle = Vector2.new(180, 180)
				burst.Size = NumberSequence.new(0.7, 0)
				burst.Color = ColorSequence.new(Color3.fromRGB(120, 255, 240))
				burst.Parent = sh
				burst:Emit(18)
				task.delay(1, function()
					burst:Destroy()
				end)
			end
		end
	elseif kind == "quest" then
		Sfx.play("gate")
		Hud.toast(text, Color3.fromRGB(255, 170, 90))
		Hud.pulse("Quests")
	elseif kind == "welcome" then
		Sfx.play("buy")
		Hud.toast(text, Theme.Green)
		task.spawn(playIntro)
	elseif kind == "announce" then
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
