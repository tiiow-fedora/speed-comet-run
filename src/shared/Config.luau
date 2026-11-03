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
	-- v3 "bright cosmos" palette: cool saturated grounds, warm interactive objects (gold pads, red/green gates)
	{ Name = "Moon", Floor = Color3.fromRGB(230, 220, 255), Accent = Color3.fromRGB(80, 230, 255), Rock = Color3.fromRGB(120, 90, 220), Material = Enum.Material.SmoothPlastic },
	{ Name = "Mars", Floor = Color3.fromRGB(255, 115, 80), Accent = Color3.fromRGB(255, 215, 90), Rock = Color3.fromRGB(200, 60, 55), Material = Enum.Material.Sand },
	{ Name = "Ice Planet", Floor = Color3.fromRGB(175, 235, 255), Accent = Color3.fromRGB(60, 170, 255), Rock = Color3.fromRGB(110, 190, 255), Material = Enum.Material.Glacier },
	{ Name = "Nebula", Floor = Color3.fromRGB(185, 110, 255), Accent = Color3.fromRGB(255, 110, 230), Rock = Color3.fromRGB(120, 60, 210), Material = Enum.Material.SmoothPlastic },
	{ Name = "Star Core", Floor = Color3.fromRGB(255, 200, 80), Accent = Color3.fromRGB(255, 90, 60), Rock = Color3.fromRGB(255, 140, 40), Material = Enum.Material.Marble },
	{ Name = "Event Horizon", Floor = Color3.fromRGB(150, 120, 255), Accent = Color3.fromRGB(255, 150, 60), Rock = Color3.fromRGB(90, 60, 190), Material = Enum.Material.SmoothPlastic },
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

-- Daily quests (v2). One quest is drawn from each tier per UTC day. Rewards scale
-- with the player's best stage: Mult x that stage's pad Wins (min 25).
export type QuestDef = { Id: string, Text: string, Event: string, Target: number, Mult: number, Tier: number, MinStage: number? }
Config.QuestPool = {
	{ Id = "pads15", Text = "Step on 15 Wins pads", Event = "pad", Target = 15, Mult = 2, Tier = 1 },
	{ Id = "play10", Text = "Play for 10 minutes", Event = "play", Target = 600, Mult = 2, Tier = 1 },
	{ Id = "restart5", Text = "Restart a lap 5 times", Event = "restart", Target = 5, Mult = 2, Tier = 1 },
	{ Id = "shards20", Text = "Collect 20 Comet Shards", Event = "shard", Target = 20, Mult = 2, Tier = 1 },
	{ Id = "pads40", Text = "Step on 40 Wins pads", Event = "pad", Target = 40, Mult = 4, Tier = 2 },
	{ Id = "play25", Text = "Play for 25 minutes", Event = "play", Target = 1500, Mult = 4, Tier = 2 },
	{ Id = "shards50", Text = "Collect 50 Comet Shards", Event = "shard", Target = 50, Mult = 4, Tier = 2 },
	{ Id = "newboots", Text = "Buy a new pair of Boots", Event = "boots", Target = 1, Mult = 4, Tier = 2, MinStage = 1 },
	{ Id = "adopt", Text = "Adopt a new Companion", Event = "companion", Target = 1, Mult = 4, Tier = 2, MinStage = 2 },
	{ Id = "finish1", Text = "Reach the FINISH", Event = "finish", Target = 1, Mult = 8, Tier = 3, MinStage = 6 },
	{ Id = "pads80", Text = "Step on 80 Wins pads", Event = "pad", Target = 80, Mult = 8, Tier = 3 },
	{ Id = "shards100", Text = "Collect 100 Comet Shards", Event = "shard", Target = 100, Mult = 8, Tier = 3 },
	{ Id = "rebirth1", Text = "Rebirth once", Event = "rebirth", Target = 1, Mult = 8, Tier = 3, MinStage = 5 },
} :: { QuestDef }
-- v4: claiming all three quests in one UTC day completes the "Daily Trio": a bonus (x TrioMult of the
-- best quest reward) and a streak. Seven days in a row also gives a free potion.
Config.TrioMult = 2
Config.TrioStreakDays = 7
Config.QuestMinBase = 25

-- Comet Shards (v3): pickups along stages 1-3, once per lap, +Speed = max(ShardMin, gain x ShardSeconds)
Config.ShardStages = 3
Config.ShardSpacing = 18
Config.ShardMin = 5
Config.ShardSeconds = 3

-- Weekly rotation (v3): one event per UTC week (weeks start Monday 00:00 UTC); cycles with no new build.
export type WeeklyEvent = { Name: string, Desc: string, SpeedMult: number, WinsMult: number, ShardMult: number, QuestMult: number }
Config.WeeklyEvents = {
	{ Name = "Comet Shower", Desc = "Comet Shards give 3x Speed", SpeedMult = 1, WinsMult = 1, ShardMult = 3, QuestMult = 1 },
	{ Name = "Wins Rush", Desc = "+50% Wins from pads", SpeedMult = 1, WinsMult = 1.5, ShardMult = 1, QuestMult = 1 },
	{ Name = "Quest Bonus", Desc = "Quest rewards x2", SpeedMult = 1, WinsMult = 1, ShardMult = 1, QuestMult = 2 },
	{ Name = "Speed Week", Desc = "+25% Speed gain", SpeedMult = 1.25, WinsMult = 1, ShardMult = 1, QuestMult = 1 },
} :: { WeeklyEvent }

function Config.WeekIndex(t: number): number
	return (t + 3 * 86400) // 604800 -- the Unix epoch was a Thursday; shift so weeks start on Monday
end

function Config.EventIndexAt(t: number): number
	return Config.WeekIndex(t) % #Config.WeeklyEvents + 1
end

-- Current event; Studio tests can force one with the ReplicatedStorage attribute ForceEvent.
function Config.CurrentEvent(): WeeklyEvent
	local forced = game:GetService("ReplicatedStorage"):GetAttribute("ForceEvent")
	local idx = if typeof(forced) == "number" and Config.WeeklyEvents[forced] then forced else Config.EventIndexAt(os.time())
	return Config.WeeklyEvents[idx]
end

function Config.EventEndsAt(t: number): number
	return (Config.WeekIndex(t) + 1) * 604800 - 3 * 86400
end

-- Companions (v4): bought once with Wins, never random, never paid. One is equipped at a time and adds
-- Bonus to Speed gain (x(1 + Bonus)). They persist through rebirth like Boots.
export type Companion = { Id: string, Name: string, Cost: number, Bonus: number, Color: Color3, Glow: Color3, Kind: string, Blurb: string }
Config.Companions = {
	{ Id = "glowbug", Name = "Glow Bug", Cost = 150, Bonus = 0.10, Color = Color3.fromRGB(150, 255, 120), Glow = Color3.fromRGB(230, 255, 140), Kind = "bug", Blurb = "A tiny lantern bug" },
	{ Id = "cometpup", Name = "Comet Pup", Cost = 1000, Bonus = 0.25, Color = Color3.fromRGB(255, 170, 90), Glow = Color3.fromRGB(255, 230, 120), Kind = "pup", Blurb = "Chases its own tail" },
	{ Id = "starfox", Name = "Star Fox", Cost = 6000, Bonus = 0.50, Color = Color3.fromRGB(255, 120, 190), Glow = Color3.fromRGB(255, 240, 250), Kind = "fox", Blurb = "Fast and fluffy" },
	{ Id = "nebulacat", Name = "Nebula Cat", Cost = 40000, Bonus = 1.00, Color = Color3.fromRGB(165, 110, 255), Glow = Color3.fromRGB(120, 220, 255), Kind = "cat", Blurb = "Purrs in starlight" },
	{ Id = "voiddragon", Name = "Void Dragon", Cost = 250000, Bonus = 2.00, Color = Color3.fromRGB(70, 60, 140), Glow = Color3.fromRGB(255, 150, 60), Kind = "dragon", Blurb = "Tiny, proud, fiery" },
} :: { Companion }

-- Server goal (v4): every Comet Shard anyone collects fills one shared bar. When it fills, everyone on the
-- server gets BoostMult Speed gain for BoostSeconds. Target grows with the player count so it stays reachable.
Config.Goal = { BaseTarget = 30, PerPlayer = 15, MaxTarget = 150, BoostSeconds = 120, BoostMult = 1.5 }
function Config.GoalTarget(players: number): number
	return math.min(Config.Goal.MaxTarget, Config.Goal.BaseTarget + Config.Goal.PerPlayer * math.max(players - 1, 0))
end

-- Playtime gifts (v4): cumulative minutes played today (UTC day). Reward Wins = Mult x max(QuestMinBase, best stage Wins).
export type Gift = { Minutes: number, Mult: number, PotionSeconds: number }
Config.Gifts = {
	{ Minutes = 3, Mult = 1, PotionSeconds = 0 },
	{ Minutes = 8, Mult = 2, PotionSeconds = 0 },
	{ Minutes = 15, Mult = 3, PotionSeconds = 0 },
	{ Minutes = 25, Mult = 5, PotionSeconds = 120 },
	{ Minutes = 40, Mult = 8, PotionSeconds = 0 },
	{ Minutes = 60, Mult = 12, PotionSeconds = 300 },
} :: { Gift }

-- Per-zone sky tint (v4): the client eases the Atmosphere/ambient toward the zone the player is in.
export type ZoneSky = { Haze: Color3, Decay: Color3, Ambient: Color3 }
Config.ZoneSky = {
	{ Haze = Color3.fromRGB(150, 110, 255), Decay = Color3.fromRGB(255, 150, 210), Ambient = Color3.fromRGB(150, 140, 190) }, -- Moon
	{ Haze = Color3.fromRGB(255, 140, 90), Decay = Color3.fromRGB(255, 190, 110), Ambient = Color3.fromRGB(190, 140, 120) }, -- Mars
	{ Haze = Color3.fromRGB(110, 190, 255), Decay = Color3.fromRGB(190, 240, 255), Ambient = Color3.fromRGB(130, 160, 200) }, -- Ice
	{ Haze = Color3.fromRGB(210, 110, 255), Decay = Color3.fromRGB(255, 130, 230), Ambient = Color3.fromRGB(170, 130, 200) }, -- Nebula
	{ Haze = Color3.fromRGB(255, 190, 80), Decay = Color3.fromRGB(255, 120, 70), Ambient = Color3.fromRGB(200, 160, 110) }, -- Star Core
	{ Haze = Color3.fromRGB(120, 100, 255), Decay = Color3.fromRGB(255, 160, 90), Ambient = Color3.fromRGB(140, 130, 200) }, -- Event Horizon
} :: { ZoneSky }

-- Roblox Premium members get a small free perk (a documented, allowed use of Premium); it is not a purchase in this game.
Config.PremiumMult = 1.1
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
