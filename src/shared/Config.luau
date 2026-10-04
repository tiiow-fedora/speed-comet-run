--!strict
-- Single source of truth for balance, stages, boots and monetization IDs.
-- Server and client both read this; the server is the only one that acts on it.

local Config = {}

Config.GameName = "+1 Speed Comet Run"
Config.DataStoreName = "CometRun_Player_v1"
Config.Gravity = 80
Config.JumpHeight = 16
Config.BaseWalkSpeed = 16
Config.MaxWalkSpeed = 140
Config.SlowWalkSpeed = 45 -- optional 'slow mode' cap for precise jumps
Config.TrackY = 200
Config.TrackWidth = 40
Config.KillY = 120 -- below this you fell into space

-- Displayed Speed grows without bound; real WalkSpeed grows logarithmically.
function Config.WalkSpeedFor(speed: number): number
	local ws = Config.BaseWalkSpeed + 12 * math.log(1 + math.max(speed, 0) / 5)
	return math.min(ws, Config.MaxWalkSpeed)
end

export type Zone = { Name: string, Floor: Color3, Accent: Color3, Rock: Color3, Material: Enum.Material }
Config.Zones = {
	{ Name = "Moon", Floor = Color3.fromRGB(150, 152, 165), Accent = Color3.fromRGB(80, 220, 255), Rock = Color3.fromRGB(105, 108, 122), Material = Enum.Material.Slate },
	{ Name = "Mars", Floor = Color3.fromRGB(196, 98, 58), Accent = Color3.fromRGB(255, 160, 60), Rock = Color3.fromRGB(140, 62, 40), Material = Enum.Material.Sand },
	{ Name = "Ice Planet", Floor = Color3.fromRGB(200, 230, 255), Accent = Color3.fromRGB(120, 200, 255), Rock = Color3.fromRGB(150, 190, 230), Material = Enum.Material.Glacier },
	{ Name = "Nebula", Floor = Color3.fromRGB(95, 60, 150), Accent = Color3.fromRGB(255, 90, 230), Rock = Color3.fromRGB(70, 40, 120), Material = Enum.Material.SmoothPlastic },
	{ Name = "Star Core", Floor = Color3.fromRGB(240, 200, 90), Accent = Color3.fromRGB(255, 255, 200), Rock = Color3.fromRGB(200, 140, 50), Material = Enum.Material.Marble },
	{ Name = "Event Horizon", Floor = Color3.fromRGB(120, 95, 165), Accent = Color3.fromRGB(255, 140, 40), Rock = Color3.fromRGB(70, 55, 100), Material = Enum.Material.Slate },
} :: { Zone }

export type Stage = { Req: number, Wins: number, Zone: number }
Config.Stages = {
	{ Req = 25, Wins = 5, Zone = 1 },
	{ Req = 75, Wins = 10, Zone = 1 },
	{ Req = 200, Wins = 25, Zone = 2 },
	{ Req = 500, Wins = 60, Zone = 2 },
	{ Req = 1200, Wins = 150, Zone = 3 },
	{ Req = 3000, Wins = 400, Zone = 3 },
	{ Req = 7500, Wins = 1000, Zone = 4 },
	{ Req = 18000, Wins = 2500, Zone = 4 },
	{ Req = 45000, Wins = 6000, Zone = 5 },
	{ Req = 100000, Wins = 15000, Zone = 5 },
	-- Galaxy 2 (added 01:10): long-term goals for rebirthed players
	{ Req = 220000, Wins = 35000, Zone = 6 },
	{ Req = 500000, Wins = 80000, Zone = 6 },
	{ Req = 1100000, Wins = 180000, Zone = 6 },
	{ Req = 2500000, Wins = 400000, Zone = 6 },
	{ Req = 6000000, Wins = 1000000, Zone = 6 },
} :: { Stage }

export type Boot = { Name: string, Mult: number, Cost: number, Color: Color3 }
Config.Boots = {
	{ Name = "Starter Boots", Mult = 1, Cost = 0, Color = Color3.fromRGB(200, 200, 210) },
	{ Name = "Moon Boots", Mult = 2, Cost = 50, Color = Color3.fromRGB(80, 220, 255) },
	{ Name = "Rocket Boots", Mult = 4, Cost = 300, Color = Color3.fromRGB(255, 120, 50) },
	{ Name = "Comet Boots", Mult = 8, Cost = 1500, Color = Color3.fromRGB(120, 255, 140) },
	{ Name = "Nova Boots", Mult = 16, Cost = 7500, Color = Color3.fromRGB(255, 80, 220) },
	{ Name = "Galaxy Boots", Mult = 32, Cost = 35000, Color = Color3.fromRGB(150, 110, 255) },
	{ Name = "Quasar Boots", Mult = 64, Cost = 175000, Color = Color3.fromRGB(255, 150, 40) },
	{ Name = "Event Horizon Boots", Mult = 128, Cost = 900000, Color = Color3.fromRGB(255, 255, 255) },
} :: { Boot }

function Config.RebirthCost(rebirths: number): number
	return 2500 * (rebirths + 1)
end

Config.FriendBoostPer = 0.10
Config.FriendBoostMax = 0.30
Config.DailyWinsPerDay = 25
Config.DailyMaxDay = 7
Config.DailyCooldown = 20 * 3600
Config.DailyStreakWindow = 48 * 3600

-- Monetization. IDs are filled in after creation (see MONETIZATION.md).
export type Pass = { Id: number, Name: string, Price: number, Desc: string }
Config.Passes = {
	Speed2x = { Id = 2006253072, Name = "2x Speed", Price = 149, Desc = "Double Speed gain forever" },
	Wins2x = { Id = 2005263080, Name = "2x Wins", Price = 199, Desc = "Double Wins from every pad" },
	VIP = { Id = 2004981019, Name = "VIP", Price = 99, Desc = "Gold VIP trail, 1.25x Speed, [VIP] tag" },
} :: { [string]: Pass }
Config.PassOrder = { "Speed2x", "Wins2x", "VIP" }

export type Product = { Id: number, Name: string, Price: number, Desc: string }
Config.Products = {
	SpeedBurst = { Id = 3716391390, Name = "Speed Burst", Price = 25, Desc = "Instantly get 5 minutes of Speed" },
	SkipStage = { Id = 3716391393, Name = "Skip Stage", Price = 29, Desc = "Jump past the next gate" },
	Potion3x = { Id = 3716391395, Name = "3x Speed Potion", Price = 39, Desc = "3x Speed gain for 10 minutes" },
	WinsS = { Id = 3716391399, Name = "750 Wins", Price = 49, Desc = "+750 Wins" },
	WinsL = { Id = 3716391402, Name = "5,000 Wins", Price = 149, Desc = "+5,000 Wins" },
} :: { [string]: Product }
Config.ProductOrder = { "SpeedBurst", "SkipStage", "Potion3x", "WinsS", "WinsL" }

Config.PotionSeconds = 600
Config.WelcomePotionSeconds = 120 -- free 3x boost on a player's very first join
Config.PotionMult = 3
Config.BurstSeconds = 300
Config.BurstMin = 250
Config.VipMult = 1.25

return Config
