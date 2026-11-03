--!strict
-- Speed tick, gates, wins pads, laps, falling, checkpoints, trails, friend boost.
-- Every decision about currency/progress happens here on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Passes = require(script.Parent.Passes)
local MapBuilder = require(script.Parent.MapBuilder)
local Quests = require(script.Parent.Quests)
local Goal = require(script.Parent.Goal)
local Gifts = require(script.Parent.Gifts)

local Gameplay = {}

type Runtime = {
	claimed: { [number]: boolean },
	checkpoint: number, -- last pad claimed this lap (0 = spawn)
	friends: number,
	grace: number, -- os.clock() until which movement checks are skipped (after teleports)
	sampleFrom: Vector3?,
	sampleT: number,
	finishing: boolean,
	slow: boolean,
	shards: { [string]: boolean },
}

local layout: MapBuilder.Layout
local runtime: { [Player]: Runtime } = {}
local notify: RemoteEvent

function Gameplay.runtime(player: Player): Runtime?
	return runtime[player]
end

function Gameplay.layout(): MapBuilder.Layout
	return layout
end

function Gameplay.notify(player: Player, kind: string, text: string, extra: any?)
	notify:FireClient(player, kind, text, extra)
end

-- First-ever join (loaded profile, never played, never earned): free 3x potion.
function Gameplay.welcomeIfNew(player: Player): boolean
	local p = DataService.get(player)
	if p and DataService.isLoaded(player) and p.PlaySeconds == 0 and p.TotalWins == 0 then
		p.PotionLeft += Config.WelcomePotionSeconds
		return true
	end
	return false
end

-- Same message of `kind` to every player on this server.
function Gameplay.broadcast(kind: string, text: string)
	for p in runtime do
		notify:FireClient(p, kind, text)
	end
end

-- Server-wide toast for everyone except `except` (who gets their own message).
function Gameplay.announce(text: string, except: Player?)
	for p in runtime do
		if p ~= except then
			notify:FireClient(p, "announce", text)
		end
	end
end

function Gameplay.multiplier(player: Player, p: DataService.Profile): number
	local boot = Config.Boots[p.Boot] or Config.Boots[1]
	local m = boot.Mult * (1 + p.Rebirths)
	if Passes.has(player, "Speed2x") then
		m *= 2
	end
	if Passes.has(player, "VIP") then
		m *= Config.VipMult
	end
	if p.PotionLeft > 0 then
		m *= Config.PotionMult
	end
	local rt = runtime[player]
	if rt then
		m *= 1 + math.min(rt.friends * Config.FriendBoostPer, Config.FriendBoostMax)
	end
	m *= Config.CurrentEvent().SpeedMult
	local pet = Config.Companions[p.Pet]
	if pet then
		m *= 1 + pet.Bonus
	end
	m *= Goal.multiplier()
	return m
end

function Gameplay.winsMultiplier(player: Player): number
	return (if Passes.has(player, "Wins2x") then 2 else 1) * Config.CurrentEvent().WinsMult
end

local function hrpOf(player: Player): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Gameplay.teleport(player: Player, cf: CFrame)
	local c = player.Character
	local hrp = hrpOf(player)
	local rt = runtime[player]
	if not c or not hrp then
		return
	end
	if rt then
		rt.grace = os.clock() + 1.5
		rt.sampleFrom = nil
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	c:PivotTo(cf)
end

local function checkpointCFrame(rt: Runtime): CFrame
	if rt.checkpoint <= 0 then
		return layout.SpawnCFrame
	end
	local st = layout.Stages[rt.checkpoint]
	return CFrame.lookAt(Vector3.new(0, Config.TrackY + 4, st.PadZ + 6), Vector3.new(0, Config.TrackY + 4, st.PadZ + 100))
end

function Gameplay.applyWalkSpeed(player: Player, p: DataService.Profile)
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if hum then
		local ws = Config.WalkSpeedFor(p.Speed)
		local rt = runtime[player]
		if rt and rt.slow then
			ws = math.min(ws, Config.SlowWalkSpeed)
		end
		hum.WalkSpeed = ws
	end
end

function Gameplay.applyTrail(player: Player)
	local p = DataService.get(player)
	local c = player.Character
	local hrp = hrpOf(player)
	if not p or not c or not hrp then
		return
	end
	local old = hrp:FindFirstChild("BootTrail")
	if old then
		old:Destroy()
	end
	for _, n in { "TrailA0", "TrailA1" } do
		local a = hrp:FindFirstChild(n)
		if a then
			a:Destroy()
		end
	end
	local vip = Passes.has(player, "VIP")
	local color = if vip then Color3.fromRGB(255, 210, 60) else (Config.Boots[p.Boot] or Config.Boots[1]).Color
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0.8, 0.4)
	a0.Parent = hrp
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, -1.6, 0.4)
	a1.Parent = hrp
	local tr = Instance.new("Trail")
	tr.Name = "BootTrail"
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = if vip then 0.7 else 0.45
	tr.LightEmission = 1
	tr.FaceCamera = true
	tr.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
	tr.Transparency = NumberSequence.new(0.1, 1)
	tr.WidthScale = NumberSequence.new(1, 0.2)
	tr.MinLength = 0.2
	tr.Parent = hrp
end

local function countFriends(player: Player): number
	local n = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
			if ok and isFriend then
				n += 1
			end
		end
	end
	return n
end

local function refreshFriends()
	for player, rt in runtime do
		task.spawn(function()
			rt.friends = countFriends(player)
			player:SetAttribute("Friends", rt.friends)
		end)
	end
end

local function claimPad(player: Player, p: DataService.Profile, rt: Runtime, st: MapBuilder.StageLayout)
	rt.claimed[st.Index] = true
	rt.checkpoint = st.Index
	player:SetAttribute("Checkpoint", st.Index)
	local gained = math.floor(st.Wins * Gameplay.winsMultiplier(player))
	p.Wins += gained
	p.TotalWins += gained
	if st.Index > p.BestStage then
		p.BestStage = st.Index
	end
	State.sync(player)
	local final = st.Index == #layout.Stages
	Quests.event(player, "pad", 1)
	if final then
		Quests.event(player, "finish", 1)
	end
	Gameplay.notify(player, "wins", "+" .. Format.commas(gained) .. " Wins!", { stage = st.Index, final = final })
	if final then
		Gameplay.announce(player.DisplayName .. " reached the FINISH! 🏁", player)
		rt.finishing = true
		task.delay(2.5, function()
			if runtime[player] ~= rt then
				return
			end
			Gameplay.resetLap(player)
			rt.finishing = false
			Gameplay.teleport(player, layout.SpawnCFrame)
			Gameplay.notify(player, "lap", "Lap complete! Run it again for more Wins")
		end)
	end
end

-- Position checks: falling, gate validation, pads, movement sanity.
local function checkPlayer(player: Player, rt: Runtime, p: DataService.Profile)
	local hrp = hrpOf(player)
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	local pos = hrp.Position
	local now = os.clock()

	if pos.Y < Config.KillY then
		Gameplay.teleport(player, checkpointCFrame(rt))
		Gameplay.notify(player, "fall", "Whoops! Back to your checkpoint")
		return
	end

	if now >= rt.grace then
		-- gate crossing without the speed → send back in front of that gate
		for _, st in layout.Stages do
			if pos.Z > st.GateZ + 2 and p.Speed < st.Req then
				Gameplay.teleport(player, CFrame.lookAt(Vector3.new(0, Config.TrackY + 4, st.GateZ - 14), Vector3.new(0, Config.TrackY + 4, st.GateZ)))
				return
			end
		end

		-- horizontal speed sanity over ~1 s windows
		if rt.sampleFrom == nil then
			rt.sampleFrom = pos
			rt.sampleT = now
		elseif now - rt.sampleT >= 1 then
			local from = rt.sampleFrom :: Vector3
			local d = Vector3.new(pos.X - from.X, 0, pos.Z - from.Z).Magnitude
			local allowed = (Config.WalkSpeedFor(p.Speed) * 2 + 40) * (now - rt.sampleT)
			if d > allowed then
				warn(("[AntiCheat] %s moved %.0f studs in %.1fs (allowed %.0f)"):format(player.Name, d, now - rt.sampleT, allowed))
				Gameplay.teleport(player, CFrame.new(from + Vector3.new(0, 3, 0)))
				return
			end
			rt.sampleFrom = pos
			rt.sampleT = now
		end
	end

	if rt.finishing then
		return
	end
	-- Comet Shards: +Speed once per lap each (server decides by position)
	if pos.Z < 1400 then
		for _, sh in layout.Shards do
			if not rt.shards[sh.Id] and (pos - sh.Pos).Magnitude < 6 then
				rt.shards[sh.Id] = true
				local amount = math.floor(math.max(Config.ShardMin, Gameplay.multiplier(player, p) * Config.ShardSeconds) * Config.CurrentEvent().ShardMult)
				p.Speed += amount
				State.syncSpeed(player, p)
				Gameplay.notify(player, "shard", "+" .. Format.short(amount) .. " ⚡", { id = sh.Id })
				Quests.event(player, "shard", 1)
				Goal.add(1)
			end
		end
	end
	for _, st in layout.Stages do
		if not rt.claimed[st.Index] then
			local dz = pos.Z - st.PadZ
			if math.abs(dz) < st.PadRadius and math.abs(pos.X) < st.PadRadius and pos.Y < Config.TrackY + 12 and pos.Y > Config.TrackY - 2 then
				if p.Speed >= st.Req then
					claimPad(player, p, rt, st)
				end
			end
		end
	end
end

function Gameplay.onCharacter(player: Player, character: Model)
	local hum = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local p = DataService.get(player)
	local rt = runtime[player]
	if not hum or not p or not rt then
		return
	end
	hum.UseJumpPower = false
	hum.JumpHeight = Config.JumpHeight
	Gameplay.applyWalkSpeed(player, p)
	task.defer(function()
		Gameplay.applyTrail(player)
		-- always place (and face) the character down the track
		task.wait(0.1)
		Gameplay.teleport(player, checkpointCFrame(rt))
	end)
end

function Gameplay.addPlayer(player: Player)
	runtime[player] = {
		claimed = {},
		checkpoint = 0,
		friends = 0,
		grace = os.clock() + 3,
		sampleFrom = nil,
		sampleT = 0,
		finishing = false,
		slow = false,
		shards = {},
	}
	player:SetAttribute("Checkpoint", 0)
	refreshFriends()
	Goal.refresh()
end

function Gameplay.removePlayer(player: Player)
	runtime[player] = nil
	refreshFriends()
	task.delay(1, Goal.refresh) -- Players:GetPlayers() still lists the leaver during PlayerRemoving
end

function Gameplay.setSlow(player: Player, on: boolean)
	local rt = runtime[player]
	local p = DataService.get(player)
	if rt and p then
		rt.slow = on
		player:SetAttribute("Slow", on)
		Gameplay.applyWalkSpeed(player, p)
	end
end

function Gameplay.resetLap(player: Player)
	local rt = runtime[player]
	if rt then
		table.clear(rt.claimed)
		table.clear(rt.shards)
		rt.checkpoint = 0
		player:SetAttribute("Checkpoint", 0)
		player:SetAttribute("Lap", ((player:GetAttribute("Lap") :: number?) or 0) + 1) -- client re-shows shards
	end
end

function Gameplay.start(builtLayout: MapBuilder.Layout, notifyRemote: RemoteEvent)
	layout = builtLayout
	notify = notifyRemote

	-- 1 s speed tick
	task.spawn(function()
		while true do
			task.wait(1)
			for player, _rt in runtime do
				local p = DataService.get(player)
				if p then
					local m = Gameplay.multiplier(player, p)
					p.Speed += m
					p.PlaySeconds += 1
					if p.Speed > p.BestSpeed then
						p.BestSpeed = p.Speed
					end
					Quests.event(player, "play", 1)
					if p.PotionLeft > 0 then
						p.PotionLeft = math.max(0, p.PotionLeft - 1)
					end
					Gifts.tick(player, p)
					player:SetAttribute("Gain", m)
					State.syncSpeed(player, p)
					Gameplay.applyWalkSpeed(player, p)
				end
			end
		end
	end)

	-- 10 Hz position checks
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		for player, rt in runtime do
			local p = DataService.get(player)
			if p then
				checkPlayer(player, rt, p)
			end
		end
	end)
end

return Gameplay
