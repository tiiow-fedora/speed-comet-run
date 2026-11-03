--!strict
-- Global boards beside the spawn, each backed by an OrderedDataStore.
-- All DataStore calls are pcall'd; a board just shows "Loading…" if they fail.
-- Board 1 ("Top Runners", TotalWins) keeps its original store name so existing
-- entries survive; board 2 ("Top Speed", BestSpeed) was added in v2.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Leaderboard = {}

type Board = { store: OrderedDataStore?, rows: { TextLabel }, emptyText: string }
local boards: { [string]: Board } = {}
local names: { [number]: string } = {}

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local name = if ok and n then n else ("Player " .. userId)
	names[userId] = name
	return name
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

local function makeBoard(key: string, storeName: string, title: string, subtitle: string, cf: CFrame, color: Color3, parent: Instance)
	local store: OrderedDataStore? = nil
	pcall(function()
		store = DataStoreService:GetOrderedDataStore(storeName)
	end)
	local board = Instance.new("Part")
	board.Name = key .. "Board"
	board.Anchored = true
	board.Size = Vector3.new(22, 26, 1)
	board.CFrame = cf
	board.Color = Color3.fromRGB(20, 22, 48)
	board.Material = Enum.Material.SmoothPlastic
	board.CanTouch = false
	board.Parent = parent
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.Parent = board
	label(sg, { Size = UDim2.new(1, 0, 0.12, 0), Text = title, Font = Enum.Font.FredokaOne, TextColor3 = color })
	label(sg, { Size = UDim2.new(1, 0, 0.06, 0), Position = UDim2.fromScale(0, 0.12), Text = subtitle, TextColor3 = Color3.fromRGB(170, 175, 210) })
	local rows = {}
	for i = 1, 10 do
		rows[i] = label(sg, {
			Size = UDim2.new(0.92, 0, 0.075, 0),
			Position = UDim2.new(0.04, 0, 0.19 + (i - 1) * 0.08, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if i == 1 then Color3.fromRGB(255, 214, 70) elseif i <= 3 then Color3.fromRGB(200, 220, 255) else Color3.fromRGB(235, 236, 255),
			Text = if i == 1 then "Loading…" else "",
		})
	end
	boards[key] = { store = store, rows = rows, emptyText = "Be the first on the board!" }
end

function Leaderboard.build(parent: Instance)
	local Y = Config.TrackY
	local W = Config.TrackWidth
	-- beside the spawn (opposite the zone sign), angled toward players leaving the spawn; +X is screen-left facing +Z
	makeBoard(
		"TopWins",
		"CometRun_TopWins_v1",
		"🏆 TOP RUNNERS",
		"Total Wins, all servers",
		CFrame.new(W / 2 + 18, Y + 13, 12) * CFrame.Angles(0, math.rad(40), 0),
		Color3.fromRGB(255, 214, 70),
		parent
	)
	makeBoard(
		"TopSpeed",
		"CometRun_TopSpeed_v1",
		"⚡ TOP SPEED",
		"Best Speed ever reached",
		CFrame.new(W / 2 + 30, Y + 13, 36) * CFrame.Angles(0, math.rad(55), 0),
		Color3.fromRGB(80, 220, 255),
		parent
	)
	-- v5: third board, further along the same side
	makeBoard(
		"TopRebirths",
		"CometRun_TopRebirths_v1",
		"🔁 TOP REBIRTHS",
		"Most rebirths, all servers",
		CFrame.new(W / 2 + 40, Y + 13, 62) * CFrame.Angles(0, math.rad(65), 0),
		Color3.fromRGB(255, 90, 220),
		parent
	)
end

-- Kept for compatibility with existing callers: submits Total Wins.
function Leaderboard.submit(userId: number, totalWins: number)
	Leaderboard.submitTo("TopWins", userId, totalWins)
end

function Leaderboard.submitTo(key: string, userId: number, value: number)
	local b = boards[key]
	if not b or not b.store or userId <= 0 or value <= 0 then
		return
	end
	local s = b.store :: OrderedDataStore
	pcall(function()
		-- OrderedDataStore values must be integers; cap well inside int64
		s:SetAsync(tostring(userId), math.floor(math.min(value, 9e15)))
	end)
end

local function refreshBoard(b: Board)
	if not b.store then
		return
	end
	local s = b.store :: OrderedDataStore
	local ok, pages = pcall(function()
		return s:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then
		return
	end
	local entries = (pages :: DataStorePages):GetCurrentPage()
	for i = 1, 10 do
		local e = entries[i]
		if e then
			b.rows[i].Text = string.format("%d. %s  —  %s", i, nameOf(tonumber(e.key) or 0), Format.short(e.value))
		else
			b.rows[i].Text = if i == 1 and #entries == 0 then b.emptyText else ""
		end
	end
end

function Leaderboard.refresh()
	for _, b in boards do
		refreshBoard(b)
	end
end

function Leaderboard.start()
	task.spawn(function()
		while true do
			Leaderboard.refresh()
			task.wait(120)
		end
	end)
end

return Leaderboard
