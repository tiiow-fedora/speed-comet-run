--!strict
-- HUD, side buttons, panels (Shop, Rebirth, Store, Daily), toasts and hint banner.
-- Mobile-friendly: everything sized in offsets on a 1000x600 reference, scaled by UIScale.

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Theme = require(script.Parent.Theme)
local Sfx = require(script.Parent.Sfx)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local new = Theme.new

local Hud = {}

local gui: ScreenGui
local root: Frame
local speedLabel: TextLabel
local gainLabel: TextLabel
local winsLabel: TextLabel
local rebirthLabel: TextLabel
local barFill: Frame
local barText: TextLabel
local skipButton: TextButton
local boostRow: Frame
local hintFrame: Frame
local hintLabel: TextLabel
local toastHolder: Frame
local panels: { [string]: Frame } = {}
local sideButtons: { [string]: TextButton } = {}
local refreshers: { () -> () } = {}
local stripDots: { Frame } = {}
local popHolder: Frame
local musicOn = true

local function attr(name: string, default: any): any
	local v = player:GetAttribute(name)
	if v == nil then
		return default
	end
	return v
end

local function ownedBoots(): { [number]: boolean }
	local t = {}
	for s in string.gmatch(attr("OwnedBoots", "1"), "%d+") do
		t[tonumber(s) :: number] = true
	end
	return t
end

local function tweenPop(inst: GuiObject)
	local scale = inst:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = inst })
	scale.Scale = 1.15
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- ===== panels =====

local function closeAll()
	for _, p in panels do
		p.Visible = false
	end
end

local function openPanel(name: string)
	local p = panels[name]
	if not p then
		return
	end
	local wasOpen = p.Visible
	closeAll()
	if wasOpen then
		return
	end
	p.Visible = true
	tweenPop(p)
	for _, r in refreshers do
		r()
	end
end
Hud.openPanel = openPanel

local function makePanel(name: string, title: string, accent: Color3): (Frame, ScrollingFrame)
	local p = new("Frame", {
		Name = name .. "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 560, 0.88, 0),
		BackgroundColor3 = Theme.Panel,
		Visible = false,
		ZIndex = 20,
		Parent = root,
	})
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 420), Parent = p })
	Theme.corner(18).Parent = p
	Theme.stroke(accent, 3).Parent = p
	Theme.label({
		Text = title,
		Size = UDim2.new(1, -120, 0, 44),
		Position = UDim2.fromOffset(20, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = accent,
		ZIndex = 21,
		Parent = p,
	})
	local close = Theme.button({
		Text = "X",
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.new(1, -56, 0, 10),
		BackgroundColor3 = Theme.Red,
		ZIndex = 21,
		Parent = p,
	})
	close.Activated:Connect(closeAll)
	local list = new("ScrollingFrame", {
		Size = UDim2.new(1, -32, 1, -76),
		Position = UDim2.fromOffset(16, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 21,
		Parent = p,
	})
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	panels[name] = p
	return p, list
end

local function row(list: ScrollingFrame, order: number, height: number?): Frame
	local r = new("Frame", {
		Size = UDim2.new(1, -12, 0, height or 64),
		BackgroundColor3 = Theme.PanelLight,
		LayoutOrder = order,
		ZIndex = 22,
		Parent = list,
	})
	Theme.corner(12).Parent = r
	return r
end

local function buildShop()
	local _, list = makePanel("Shop", "👟 BOOTS", Theme.Accent)
	local rows = {}
	for i, boot in Config.Boots do
		local r = row(list, i)
		new("Frame", {
			Size = UDim2.fromOffset(14, 44),
			Position = UDim2.fromOffset(10, 10),
			BackgroundColor3 = boot.Color,
			ZIndex = 23,
			Parent = r,
		}, { Theme.corner(6) })
		Theme.label({
			Text = boot.Name,
			Size = UDim2.new(0.5, -40, 0, 30),
			Position = UDim2.fromOffset(34, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 23,
			Parent = r,
		})
		Theme.label({
			Text = "x" .. boot.Mult .. " Speed gain",
			Size = UDim2.new(0.5, -40, 0, 22),
			Position = UDim2.fromOffset(34, 36),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Green,
			Font = Theme.BodyFont,
			ZIndex = 23,
			Parent = r,
		})
		local b = Theme.button({
			Size = UDim2.fromOffset(170, 46),
			Position = UDim2.new(1, -180, 0, 9),
			ZIndex = 23,
			Parent = r,
		})
		b.Activated:Connect(function()
			local owned = ownedBoots()
			if owned[i] then
				remotes.EquipBoot:FireServer(i)
			else
				if attr("Wins", 0) < boot.Cost then
					Sfx.play("error")
					Hud.toast("Need " .. Format.commas(boot.Cost - attr("Wins", 0)) .. " more Wins", Theme.Red)
					return
				end
				remotes.BuyBoot:FireServer(i)
			end
		end)
		rows[i] = b
	end
	table.insert(refreshers, function()
		local owned = ownedBoots()
		local equipped = attr("Boot", 1)
		local wins = attr("Wins", 0)
		for i, b in rows do
			local boot = Config.Boots[i]
			if equipped == i then
				b.Text = "EQUIPPED"
				b.BackgroundColor3 = Theme.Muted
			elseif owned[i] then
				b.Text = "EQUIP"
				b.BackgroundColor3 = Theme.Accent
			else
				b.Text = "🏆 " .. Format.short(boot.Cost)
				b.BackgroundColor3 = if wins >= boot.Cost then Theme.Green else Theme.PanelLight
			end
		end
	end)
end

local function buildRebirth()
	local _, list = makePanel("Rebirth", "🔁 REBIRTH", Theme.Pink)
	local r = row(list, 1, 150)
	local info = Theme.label({
		Size = UDim2.new(1, -24, 0, 90),
		Position = UDim2.fromOffset(12, 8),
		Font = Theme.BodyFont,
		TextWrapped = true,
		ZIndex = 23,
		Parent = r,
	})
	local b = Theme.button({
		Text = "REBIRTH",
		Size = UDim2.fromOffset(220, 44),
		Position = UDim2.new(0.5, -110, 1, -52),
		BackgroundColor3 = Theme.Pink,
		ZIndex = 23,
		Parent = r,
	})
	b.Activated:Connect(function()
		remotes.Rebirth:FireServer()
		closeAll()
	end)
	table.insert(refreshers, function()
		local reb = attr("Rebirths", 0)
		local cost = Config.RebirthCost(reb)
		info.Text = string.format(
			"Reset Speed and Wins (you keep your Boots) for a permanent boost.\nNow: x%d   →   After: x%d Speed gain\nNeeds ⚡ %s Speed (you have %s)",
			1 + reb,
			2 + reb,
			Format.commas(cost),
			Format.commas(attr("Speed", 0))
		)
		local ready = attr("Speed", 0) >= cost
		b.BackgroundColor3 = if ready then Theme.Pink else Theme.PanelLight
		b.Text = if ready then "REBIRTH" else "NOT YET"
	end)
end

local function buildStore()
	local _, list = makePanel("Store", "💎 STORE", Theme.Gold)
	local order = 0
	local passButtons: { [string]: TextButton } = {}
	local function header(text: string)
		order += 1
		Theme.label({
			Text = text,
			Size = UDim2.new(1, -12, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Muted,
			LayoutOrder = order,
			ZIndex = 22,
			Parent = list,
		})
	end
	local function item(name: string, desc: string, price: number, onBuy: () -> ()): TextButton
		order += 1
		local r = row(list, order)
		Theme.label({
			Text = name,
			Size = UDim2.new(1, -200, 0, 28),
			Position = UDim2.fromOffset(14, 6),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 23,
			Parent = r,
		})
		Theme.label({
			Text = desc,
			Size = UDim2.new(1, -200, 0, 22),
			Position = UDim2.fromOffset(14, 36),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Muted,
			Font = Theme.BodyFont,
			ZIndex = 23,
			Parent = r,
		})
		local b = Theme.button({
			Text = "R$ " .. price,
			Size = UDim2.fromOffset(150, 46),
			Position = UDim2.new(1, -160, 0, 9),
			BackgroundColor3 = Theme.Green,
			ZIndex = 23,
			Parent = r,
		})
		b.Activated:Connect(onBuy)
		return b
	end
	header("GAME PASSES (forever)")
	for _, key in Config.PassOrder do
		local pass = Config.Passes[key]
		passButtons[key] = item(pass.Name, pass.Desc, pass.Price, function()
			if pass.Id == 0 then
				Hud.toast("Coming soon", Theme.Muted)
				return
			end
			if attr("Pass_" .. key, false) then
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		end)
	end
	header("BOOSTS")
	for _, key in Config.ProductOrder do
		local prod = Config.Products[key]
		item(prod.Name, prod.Desc, prod.Price, function()
			Hud.promptProduct(key)
		end)
	end
	table.insert(refreshers, function()
		for key, b in passButtons do
			if attr("Pass_" .. key, false) then
				b.Text = "OWNED"
				b.BackgroundColor3 = Theme.Muted
			end
		end
	end)
end

function Hud.promptProduct(key: string)
	local prod = Config.Products[key]
	if not prod or prod.Id == 0 then
		Hud.toast("Coming soon", Theme.Muted)
		return
	end
	MarketplaceService:PromptProductPurchase(player, prod.Id)
end

local function buildDaily()
	local _, list = makePanel("Daily", "🎁 DAILY REWARD", Theme.Green)
	-- v3: 7-day streak strip so the reason to come back tomorrow is visible
	local streakRow = row(list, 0, 64)
	local dayBoxes = {}
	for d = 1, Config.DailyMaxDay do
		local box = Theme.label({
			Text = "Day " .. d .. "\n🏆" .. (Config.DailyWinsPerDay * d) .. (if d == Config.DailyMaxDay then "+🧪" else ""),
			Size = UDim2.new(1 / Config.DailyMaxDay, -6, 1, -10),
			Position = UDim2.new((d - 1) / Config.DailyMaxDay, 3, 0, 5),
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Bg,
			Font = Theme.BodyFont,
			ZIndex = 23,
			Parent = streakRow,
		})
		Theme.corner(8).Parent = box
		dayBoxes[d] = box
	end
	table.insert(refreshers, function()
		local day = attr("DailyDay", 1)
		for d, box in dayBoxes do
			box.BackgroundColor3 = if d < day then Theme.Green elseif d == day then Theme.Gold else Theme.Bg
			box.TextColor3 = if d == day then Color3.fromRGB(40, 30, 10) else Theme.Text
		end
	end)
	local r = row(list, 1, 200)
	local info = Theme.label({
		Size = UDim2.new(1, -24, 0, 120),
		Position = UDim2.fromOffset(12, 8),
		Font = Theme.BodyFont,
		TextWrapped = true,
		ZIndex = 23,
		Parent = r,
	})
	local b = Theme.button({
		Text = "CLAIM",
		Size = UDim2.fromOffset(220, 48),
		Position = UDim2.new(0.5, -110, 1, -58),
		BackgroundColor3 = Theme.Green,
		ZIndex = 23,
		Parent = r,
	})
	b.Activated:Connect(function()
		remotes.ClaimDaily:FireServer()
		closeAll()
	end)
	table.insert(refreshers, function()
		local day = attr("DailyDay", 1)
		local ready = attr("DailyReady", false)
		local reward = "+" .. (Config.DailyWinsPerDay * day) .. " Wins"
		if day >= Config.DailyMaxDay then
			reward ..= " + free 3x Speed Potion"
		end
		info.Text = string.format(
			"Come back every day to grow your streak!\nDay %d of %d: %s\n%s",
			day,
			Config.DailyMaxDay,
			reward,
			if ready then "Ready to claim!" else "Already claimed. Come back tomorrow."
		)
		b.BackgroundColor3 = if ready then Theme.Green else Theme.PanelLight
		b.Text = if ready then "CLAIM" else "CLAIMED"
	end)
end

local function buildQuests()
	local _, list = makePanel("Quests", "📜 DAILY QUESTS", Color3.fromRGB(255, 170, 90))
	local note = Theme.label({
		Text = "New quests every day. Rewards grow as you reach further stages!",
		Size = UDim2.new(1, -12, 0, 24),
		TextColor3 = Theme.Muted,
		Font = Theme.BodyFont,
		LayoutOrder = 0,
		ZIndex = 22,
		Parent = list,
	})
	note.TextWrapped = true
	local rows = {}
	for i = 1, 3 do
		local r = row(list, i, 76)
		local title = Theme.label({ Size = UDim2.new(1, -200, 0, 28), Position = UDim2.fromOffset(14, 6), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = r })
		local barBg = new("Frame", { Size = UDim2.new(1, -200, 0, 18), Position = UDim2.fromOffset(14, 40), BackgroundColor3 = Theme.Bg, ZIndex = 23, Parent = r }, { Theme.corner(9) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Green, ZIndex = 24, Parent = barBg }, { Theme.corner(9) })
		local prog = Theme.label({ Size = UDim2.new(1, -8, 1, -2), Position = UDim2.fromOffset(4, 1), Font = Theme.BodyFont, ZIndex = 25, Parent = barBg })
		local b = Theme.button({ Size = UDim2.fromOffset(170, 50), Position = UDim2.new(1, -180, 0, 13), ZIndex = 23, Parent = r })
		b.Activated:Connect(function()
			remotes.ClaimQuest:FireServer(i)
		end)
		rows[i] = { title = title, fill = fill, prog = prog, button = b, frame = r }
	end
	table.insert(refreshers, function()
		local ok, data = pcall(HttpService.JSONDecode, HttpService, attr("Quests", "[]"))
		if not ok or type(data) ~= "table" then
			data = {}
		end
		for i, rw in rows do
			local q = data[i]
			rw.frame.Visible = q ~= nil
			if q then
				rw.title.Text = q.text
				local frac = math.clamp(q.progress / math.max(q.target, 1), 0, 1)
				rw.fill.Size = UDim2.fromScale(frac, 1)
				rw.prog.Text = q.progress .. " / " .. q.target .. (if q.unit ~= "" then " " .. q.unit else "")
				if q.claimed then
					rw.button.Text = "DONE ✓"
					rw.button.BackgroundColor3 = Theme.Muted
				elseif frac >= 1 then
					rw.button.Text = "CLAIM 🏆 " .. Format.short(q.reward)
					rw.button.BackgroundColor3 = Theme.Green
				else
					rw.button.Text = "🏆 " .. Format.short(q.reward)
					rw.button.BackgroundColor3 = Theme.PanelLight
				end
			end
		end
	end)
end

-- ===== HUD =====

local function chip(parent: Instance, size: UDim2, pos: UDim2, color: Color3): Frame
	local f = new("Frame", {
		Size = size,
		Position = pos,
		BackgroundColor3 = Theme.Bg,
		BackgroundTransparency = 0.15,
		Parent = parent,
	})
	Theme.corner(14).Parent = f
	Theme.stroke(color, 2, 0.2).Parent = f
	return f
end

local function buildTop()
	local top = new("Frame", {
		Name = "Top",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(600, 104),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local winsChip = chip(top, UDim2.fromOffset(140, 56), UDim2.fromOffset(0, 4), Theme.Gold)
	Theme.label({ Text = "WINS", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 4), TextColor3 = Theme.Muted, Font = Theme.BodyFont, Parent = winsChip })
	winsLabel = Theme.label({ Text = "🏆 0", Size = UDim2.new(1, -12, 0, 30), Position = UDim2.fromOffset(6, 21), TextColor3 = Theme.Gold, Parent = winsChip })

	local speedChip = chip(top, UDim2.fromOffset(300, 64), UDim2.fromOffset(150, 0), Theme.Accent)
	speedLabel = Theme.label({ Text = "⚡ 0", Size = UDim2.new(0.68, 0, 0, 46), Position = UDim2.fromOffset(10, 9), TextXAlignment = Enum.TextXAlignment.Left, Parent = speedChip })
	gainLabel = Theme.label({ Text = "+1/s", Size = UDim2.new(0.3, -8, 0, 26), Position = UDim2.new(0.7, 0, 0, 19), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Theme.Green, Parent = speedChip })

	local rebChip = chip(top, UDim2.fromOffset(140, 56), UDim2.fromOffset(460, 4), Theme.Pink)
	Theme.label({ Text = "REBIRTHS", Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 4), TextColor3 = Theme.Muted, Font = Theme.BodyFont, Parent = rebChip })
	rebirthLabel = Theme.label({ Text = "🔁 0", Size = UDim2.new(1, -12, 0, 30), Position = UDim2.fromOffset(6, 21), TextColor3 = Theme.Pink, Parent = rebChip })

	-- progress bar to the next gate
	local bar = new("Frame", {
		Size = UDim2.fromOffset(300, 26),
		Position = UDim2.fromOffset(150, 70),
		BackgroundColor3 = Theme.Bg,
		BackgroundTransparency = 0.15,
		ClipsDescendants = true,
		Parent = top,
	})
	Theme.corner(13).Parent = bar
	Theme.stroke(Theme.Accent, 2, 0.3).Parent = bar
	barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent, Parent = bar })
	Theme.corner(13).Parent = barFill
	barText = Theme.label({ Text = "", Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), ZIndex = 3, Parent = bar })
	skipButton = Theme.button({
		Text = "SKIP ⏩",
		Size = UDim2.fromOffset(90, 30),
		Position = UDim2.fromOffset(460, 68),
		BackgroundColor3 = Color3.fromRGB(235, 140, 30),
		Parent = top,
	})
	skipButton.Activated:Connect(function()
		Hud.promptProduct("SkipStage")
	end)

	-- v3 galaxy progress strip: one dot per stage in its zone color; filled = reached
	local strip = new("Frame", {
		Name = "GalaxyStrip",
		Size = UDim2.fromOffset(15 * 20, 14),
		Position = UDim2.fromOffset(150, 130),
		BackgroundTransparency = 1,
		Parent = top,
	})
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip })
	for i, st in Config.Stages do
		local dot = new("Frame", {
			Name = "Dot" .. i,
			Size = UDim2.fromOffset(16, 12),
			BackgroundColor3 = Config.Zones[st.Zone].Accent,
			LayoutOrder = i,
			Parent = strip,
		})
		Theme.corner(6).Parent = dot
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 0, Parent = dot })
		stripDots[i] = dot
	end

	boostRow = new("Frame", {
		Size = UDim2.fromOffset(600, 24),
		Position = UDim2.fromOffset(0, 102),
		BackgroundTransparency = 1,
		Parent = top,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = boostRow,
	})
end

local function buildSide()
	-- 2-column grid on the left. Touch: near the top (chat is collapsed on mobile and the
	-- thumbstick owns the bottom-left). Desktop: below the Roblox chat window, which
	-- opens top-left and would otherwise cover these buttons and eat their clicks.
	-- (screen height too: Studio's phone emulator and some phones report a keyboard)
	local cam = workspace.CurrentCamera
	local shortScreen = cam ~= nil and cam.ViewportSize.Y < 520
	local touchFirst = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) or shortScreen
	local side = new("Frame", {
		Name = "Side",
		Position = UDim2.fromOffset(8, if touchFirst then 72 else 236),
		Size = UDim2.fromOffset(2 * 76 + 8, 3 * 80),
		BackgroundTransparency = 1,
		Parent = root,
	})
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(72, 72),
		CellPadding = UDim2.fromOffset(8, 8),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = side,
	})
	-- right column: social / settings, clear of the jump button (bottom-right)
	local right = new("Frame", {
		Name = "SideRight",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 72),
		Size = UDim2.fromOffset(72, 3 * 80),
		BackgroundTransparency = 1,
		Parent = root,
	})
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
	local defs = {
		{ "Shop", "👟", "BOOTS", Theme.Accent },
		{ "Rebirth", "🔁", "REBIRTH", Theme.Pink },
		{ "Store", "💎", "STORE", Theme.Gold },
		{ "Daily", "🎁", "DAILY", Theme.Green },
		{ "Restart", "↩️", "RESTART", Color3.fromRGB(120, 200, 255) },
		{ "Quests", "📜", "QUESTS", Color3.fromRGB(255, 170, 90) },
		{ "Invite", "👥", "+10%", Color3.fromRGB(150, 120, 255) },
		{ "Slow", "🐢", "SLOW: OFF", Color3.fromRGB(140, 220, 140) },
		{ "Music", "🎵", "MUSIC: ON", Color3.fromRGB(255, 170, 90) },
	}
	for i, d in defs do
		local b = new("TextButton", {
			Name = d[1],
			Size = UDim2.fromOffset(72, 72),
			BackgroundColor3 = Theme.Bg,
			BackgroundTransparency = 0.1,
			Text = "",
			LayoutOrder = i,
			AutoButtonColor = true,
			Parent = if d[1] == "Invite" or d[1] == "Slow" or d[1] == "Music" then right else side,
		})
		Theme.corner(16).Parent = b
		Theme.stroke(d[4], 3).Parent = b
		Theme.label({ Text = d[2], Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 4), Parent = b })
		Theme.label({ Name = "Label", Text = d[3], Size = UDim2.new(1, -6, 0, 20), Position = UDim2.new(0, 3, 1, -24), TextColor3 = d[4], Parent = b })
		local dot = new("Frame", {
			Name = "Dot",
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.new(1, -14, 0, -4),
			BackgroundColor3 = Theme.Red,
			Visible = false,
			Parent = b,
		})
		Theme.corner(9).Parent = dot
		sideButtons[d[1]] = b
		b.Activated:Connect(function()
			if d[1] == "Music" then
				musicOn = not musicOn
				Sfx.setMusic(musicOn)
				local lbl = b:FindFirstChild("Label") :: TextLabel?
				if lbl then
					lbl.Text = if musicOn then "MUSIC: ON" else "MUSIC: OFF"
				end
			elseif d[1] == "Slow" then
				local on = not player:GetAttribute("Slow")
				remotes.SetSlow:FireServer(on)
				Hud.toast(if on then "Slow mode ON: easier jumps" else "Slow mode OFF: full speed!", Theme.Green)
			elseif d[1] == "Restart" then
				remotes.RestartLap:FireServer()
				Hud.toast("Back to the start! Wins pads pay out again", Theme.Accent)
			elseif d[1] == "Invite" then
				local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
				if ok and can then
					pcall(SocialService.PromptGameInvite, SocialService, player)
				else
					Hud.toast("Invites aren't available here", Theme.Muted)
				end
			else
				openPanel(d[1])
			end
		end)
	end
end

function Hud.setDot(name: string, on: boolean)
	local b = sideButtons[name]
	local dot = b and b:FindFirstChild("Dot") :: Frame?
	if dot then
		dot.Visible = on
	end
end

function Hud.pulse(name: string)
	local b = sideButtons[name]
	if b then
		tweenPop(b)
	end
end

function Hud.toast(text: string, color: Color3?)
	local t = Theme.label({
		Text = text,
		Size = UDim2.fromOffset(520, 40),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 1),
		TextColor3 = color or Theme.Text,
		Parent = toastHolder,
	})
	TweenService:Create(t, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.4) }):Play()
	task.delay(2.2, function()
		local tw = TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1, Position = UDim2.fromScale(0.5, 0) })
		tw:Play()
		tw.Completed:Wait()
		t:Destroy()
	end)
end

function Hud.hint(text: string?)
	if not text or text == "" then
		hintFrame.Visible = false
		return
	end
	if hintLabel.Text ~= text or not hintFrame.Visible then
		hintLabel.Text = text
		hintFrame.Visible = true
		tweenPop(hintFrame)
	end
end

-- v3: one short, concrete next goal (shown under the HUD when the tutorial is done)
function Hud.nextGoal(): string?
	local wins = attr("Wins", 0)
	local owned = ownedBoots()
	for i, boot in Config.Boots do
		if not owned[i] and wins >= boot.Cost then
			return "Next: buy " .. boot.Name .. " 👟"
		end
	end
	local n = Hud.nextStage()
	if not n then
		return "Next: reach the FINISH 🏁"
	end
	local req = Config.Stages[n].Req
	local speed = attr("Speed", 0)
	if speed >= req then
		return "Next: Gate " .. n .. " pad 🏆"
	elseif speed < req * 0.5 and n > 2 then
		return "Next: ⚡" .. Format.short(req) .. ". Tip: ↩️ RESTART farms Wins"
	end
	return "Next: ⚡" .. Format.short(req) .. " opens Gate " .. n
end

-- v3: small floating "+N ⚡" near the center for pickups
function Hud.popText(text: string)
	if not popHolder then
		return
	end
	local t = Theme.label({
		Text = text,
		Size = UDim2.fromOffset(200, 34),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.6),
		TextColor3 = Color3.fromRGB(120, 255, 240),
		Parent = popHolder,
	})
	TweenService:Create(t, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Position = UDim2.fromScale(0.5, 0.3), TextTransparency = 1 }):Play()
	task.delay(0.8, function()
		t:Destroy()
	end)
end

-- Which gate is next for this player, based on the server's checkpoint.
function Hud.nextStage(): number?
	local cp = attr("Checkpoint", 0)
	if cp >= #Config.Stages then
		return nil
	end
	return cp + 1
end

local lastSpeed = 0
local function refreshTop()
	local speed = attr("Speed", 0)
	speedLabel.Text = "⚡ " .. Format.commas(speed)
	gainLabel.Text = "+" .. Format.short(attr("Gain", 1)) .. "/s"
	winsLabel.Text = "🏆 " .. Format.short(attr("Wins", 0))
	rebirthLabel.Text = "🔁 " .. attr("Rebirths", 0)
	if speed > lastSpeed and speed - lastSpeed < 1e12 then
		tweenPop(speedLabel)
	end
	lastSpeed = speed
	local n = Hud.nextStage()
	if n then
		local req = Config.Stages[n].Req
		local prev = if n > 1 then Config.Stages[n - 1].Req else 0
		local frac = math.clamp((speed - prev) / math.max(req - prev, 1), 0, 1)
		if speed >= req then
			frac = 1
		end
		barFill.Size = UDim2.fromScale(frac, 1)
		barFill.BackgroundColor3 = if speed >= req then Theme.Green else Theme.Accent
		barText.Text = if speed >= req then ("Gate " .. n .. " OPEN! Run!") else ("Gate " .. n .. "  ⚡ " .. Format.short(req))
		skipButton.Visible = speed < req
	else
		barFill.Size = UDim2.fromScale(1, 1)
		barFill.BackgroundColor3 = Theme.Gold
		barText.Text = "All gates open! Reach the FINISH"
		skipButton.Visible = false
	end
	local best = attr("BestStage", 0)
	local cpNow = attr("Checkpoint", 0)
	for i, dot in stripDots do
		dot.BackgroundTransparency = if i <= best then 0 else 0.65
		local stroke = dot:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if i == cpNow + 1 then 2 else 0
		end
	end
	-- boosts row: only rebuilt when its contents change (it used to be rebuilt every tick)
	local boosts: { { string | Color3 } } = {}
	local ev = Config.CurrentEvent()
	table.insert(boosts, { "🎉 " .. ev.Name, Color3.fromRGB(255, 170, 230) })
	if attr("PotionLeft", 0) > 0 then
		table.insert(boosts, { "🧪 3x " .. Format.time(attr("PotionLeft", 0)), Theme.Pink })
	end
	local friends = attr("Friends", 0)
	if friends > 0 then
		table.insert(boosts, { "👥 +" .. math.floor(math.min(friends * Config.FriendBoostPer, Config.FriendBoostMax) * 100) .. "% friends", Theme.Accent })
	end
	if attr("Pass_Speed2x", false) then
		table.insert(boosts, { "⚡ 2x Speed", Theme.Green })
	end
	if attr("Pass_VIP", false) then
		table.insert(boosts, { "⭐ VIP", Theme.Gold })
	end
	local labels = {}
	for _, c in boostRow:GetChildren() do
		if c:IsA("TextLabel") then
			table.insert(labels, c)
		end
	end
	table.sort(labels, function(x, y)
		return x.LayoutOrder < y.LayoutOrder
	end)
	for i, bdef in boosts do
		local l = labels[i]
		if not l then
			l = Theme.label({ Size = UDim2.fromOffset(150, 22), LayoutOrder = i, Parent = boostRow })
		end
		l.Text = bdef[1] :: string
		l.TextColor3 = bdef[2] :: Color3
	end
	for i = #boosts + 1, #labels do
		labels[i]:Destroy()
	end
	-- red dots
	local wins = attr("Wins", 0)
	local owned = ownedBoots()
	local canBuy = false
	for i, boot in Config.Boots do
		if not owned[i] and wins >= boot.Cost then
			canBuy = true
		end
	end
	Hud.setDot("Shop", canBuy)
	Hud.setDot("Rebirth", speed >= Config.RebirthCost(attr("Rebirths", 0)))
	Hud.setDot("Daily", attr("DailyReady", false))
	Hud.setDot("Quests", attr("QuestReady", false))
	local slowBtn = sideButtons["Slow"]
	local slowLabel = slowBtn and slowBtn:FindFirstChild("Label") :: TextLabel?
	if slowLabel then
		slowLabel.Text = if attr("Slow", false) then "SLOW: ON" else "SLOW: OFF"
	end
end

local function applyScale(scale: UIScale, v: Vector2)
	local s = math.clamp(math.min(v.X / 1000, v.Y / 600), 0.5, 1.4)
	if UserInputService.TouchEnabled and v.Y < 520 then
		-- small touch screens: use a smaller reference canvas so text stays readable
		s = math.min(v.X / 820, v.Y / 470)
	end
	scale.Scale = s
end

function Hud.build()
	gui = new("ScreenGui", {
		Name = "CometHud",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	-- root is a reference-size canvas centred on screen and scaled to fit
	root = new("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(1000, 600),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local scale = new("UIScale", { Parent = root })
	-- keep the root covering the whole (inset-adjusted) screen at any aspect ratio
	local function fit()
		local v = gui.AbsoluteSize
		if v.X < 2 then
			return
		end
		applyScale(scale, v)
		root.Size = UDim2.fromOffset(v.X / scale.Scale, v.Y / scale.Scale)
	end
	fit()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

	popHolder = new("Frame", {
		Name = "Pops",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(300, 300),
		BackgroundTransparency = 1,
		Parent = root,
	})
	toastHolder = new("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.22),
		Size = UDim2.fromOffset(520, 220),
		BackgroundTransparency = 1,
		ZIndex = 30,
		Parent = root,
	})

	hintFrame = new("Frame", {
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 152),
		Size = UDim2.fromOffset(440, 40),
		BackgroundColor3 = Theme.Bg,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = root,
	})
	Theme.corner(14).Parent = hintFrame
	Theme.stroke(Theme.Gold, 2).Parent = hintFrame
	hintLabel = Theme.label({ Text = "", Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), TextColor3 = Theme.Gold, Parent = hintFrame })

	buildTop()
	buildSide()
	buildShop()
	buildRebirth()
	buildStore()
	buildDaily()
	buildQuests()

	local function refreshAll()
		refreshTop()
		for _, p in panels do
			if p.Visible then
				for _, r in refreshers do
					r()
				end
				break
			end
		end
	end
	for _, name in { "Speed", "Gain", "Wins", "Rebirths", "Boot", "OwnedBoots", "PotionLeft", "Checkpoint", "Friends", "DailyReady", "DailyDay", "Pass_Speed2x", "Pass_Wins2x", "Pass_VIP", "Slow", "Quests", "QuestReady" } do
		player:GetAttributeChangedSignal(name):Connect(refreshAll)
	end
	refreshAll()
end

return Hud
