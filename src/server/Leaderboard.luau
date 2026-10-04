--!strict
-- Global "Top Runners" board (OrderedDataStore of TotalWins) beside the spawn.
-- All DataStore calls are pcall'd; the board just shows "loading" if they fail.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Leaderboard = {}

local store: OrderedDataStore? = nil
pcall(function()
	store = DataStoreService:GetOrderedDataStore("CometRun_TopWins_v1")
end)

local rows: { TextLabel } = {}
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

function Leaderboard.build(parent: Instance)
	local Y = Config.TrackY
	local W = Config.TrackWidth
	local board = Instance.new("Part")
	board.Name = "TopRunnersBoard"
	board.Anchored = true
	board.Size = Vector3.new(22, 26, 1)
	-- beside the spawn (opposite the zone sign), angled toward players leaving the spawn
	board.CFrame = CFrame.new(W / 2 + 18, Y + 13, 12) * CFrame.Angles(0, math.rad(40), 0) -- +X is screen-left when facing +Z
	board.Color = Color3.fromRGB(20, 22, 48)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = parent
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.Parent = board
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.12, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏆 TOP RUNNERS"
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.fromRGB(255, 214, 70)
	title.Parent = sg
	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, 0, 0.06, 0)
	sub.Position = UDim2.fromScale(0, 0.12)
	sub.BackgroundTransparency = 1
	sub.Text = "Total Wins, all servers"
	sub.TextScaled = true
	sub.Font = Enum.Font.GothamBold
	sub.TextColor3 = Color3.fromRGB(170, 175, 210)
	sub.Parent = sg
	for i = 1, 10 do
		local r = Instance.new("TextLabel")
		r.Size = UDim2.new(0.92, 0, 0.075, 0)
		r.Position = UDim2.new(0.04, 0, 0.19 + (i - 1) * 0.08, 0)
		r.BackgroundTransparency = 1
		r.TextXAlignment = Enum.TextXAlignment.Left
		r.TextScaled = true
		r.Font = Enum.Font.GothamBold
		r.TextColor3 = if i == 1 then Color3.fromRGB(255, 214, 70) elseif i <= 3 then Color3.fromRGB(200, 220, 255) else Color3.fromRGB(235, 236, 255)
		r.Text = if i == 1 then "Loading…" else ""
		r.Parent = sg
		rows[i] = r
	end
end

function Leaderboard.submit(userId: number, totalWins: number)
	if not store or userId <= 0 or totalWins <= 0 then
		return
	end
	local s = store :: OrderedDataStore
	pcall(function()
		s:SetAsync(tostring(userId), math.floor(totalWins))
	end)
end

function Leaderboard.refresh()
	if not store then
		return
	end
	local s = store :: OrderedDataStore
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
			rows[i].Text = string.format("%d. %s  —  %s", i, nameOf(tonumber(e.key) or 0), Format.short(e.value))
		else
			rows[i].Text = if i == 1 and #entries == 0 then "Be the first on the board!" else ""
		end
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
