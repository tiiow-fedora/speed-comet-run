--!strict
-- Builds the whole course from Config at server start, so the map lives in git.
-- Returns a Layout table the other services use for zones, gates and pads.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local MapBuilder = {}

export type StageLayout = {
	Index: number,
	StartZ: number, -- checkpoint at the start of this stage
	GateZ: number,
	PadZ: number,
	PadRadius: number,
	Req: number,
	Wins: number,
}
export type Layout = { Stages: { StageLayout }, SpawnCFrame: CFrame, EndZ: number }

local Y = Config.TrackY
local W = Config.TrackWidth
local rng = Random.new(20261003)

local mapFolder: Folder

local function part(props: { [string]: any }, parent: Instance?): BasePart
	local p: BasePart
	if props.Shape == "Cylinder" or props.Shape == "Ball" then
		local pp = Instance.new("Part")
		pp.Shape = if props.Shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Cylinder
		p = pp
	elseif props.Wedge then
		p = Instance.new("WedgePart")
	else
		p = Instance.new("Part")
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Shape" and k ~= "Wedge" then
			(p :: any)[k] = v
		end
	end
	p.Parent = parent or mapFolder
	return p
end

-- Props from Blender (if they were imported into ServerStorage.Props), else primitives.
local function propsFolder(): Folder?
	return ServerStorage:FindFirstChild("Props") :: Folder?
end

local function rock(pos: Vector3, size: number, color: Color3, parent: Instance)
	local lib = propsFolder()
	local template = lib and (lib:FindFirstChild("Rock" .. rng:NextInteger(1, 3)) :: BasePart?)
	if template then
		local r = template:Clone()
		r.Anchored = true
		r.Size = r.Size * (size / math.max(r.Size.X, r.Size.Y, r.Size.Z))
		r.Color = color
		r.CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), 0)
		r.Parent = parent
		return
	end
	part({
		Name = "Rock",
		Size = Vector3.new(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.7, 1.1)),
		CFrame = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28)),
		Color = color,
		Material = Enum.Material.Slate,
		CanCollide = false,
		CastShadow = false,
	}, parent)
end

local function crystal(pos: Vector3, h: number, color: Color3, parent: Instance)
	local lib = propsFolder()
	local template = lib and (lib:FindFirstChild("Crystal") :: BasePart?)
	if template then
		local c = template:Clone()
		c.Anchored = true
		c.Size = c.Size * (h / c.Size.Y)
		c.Color = color
		c.Material = Enum.Material.Neon
		c.CanCollide = false
		c.CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3))
		c.Parent = parent
		return
	end
	part({
		Name = "Crystal",
		Size = Vector3.new(h * 0.3, h, h * 0.3),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3)),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
	}, parent)
end

local function floor(z0: number, z1: number, zone: Config.Zone, parent: Instance, name: string?)
	local len = z1 - z0
	part({
		Name = name or "Floor",
		Size = Vector3.new(W, 4, len),
		CFrame = CFrame.new(0, Y - 2, z0 + len / 2),
		Color = zone.Floor,
		Material = zone.Material,
	}, parent)
	-- glowing edge rails keep players on the track
	for _, side in { -1, 1 } do
		part({
			Name = "Rail",
			Size = Vector3.new(1, 2, len),
			CFrame = CFrame.new(side * (W / 2 + 0.5), Y + 1 - 2 + 1, z0 + len / 2),
			Color = zone.Accent,
			Material = Enum.Material.Neon,
		}, parent)
	end
	-- underside chunk so the track reads as a floating asteroid strip
	part({
		Name = "Underside",
		Size = Vector3.new(W * 0.8, 10, len * 0.95),
		CFrame = CFrame.new(0, Y - 9, z0 + len / 2),
		Color = zone.Rock,
		Material = Enum.Material.Slate,
		CanCollide = false,
	}, parent)
end

local function island(zc: number, len: number, zone: Config.Zone, parent: Instance)
	part({
		Name = "Island",
		Shape = "Cylinder",
		Size = Vector3.new(4, len, len),
		CFrame = CFrame.new(0, Y - 2, zc) * CFrame.Angles(0, 0, math.rad(90)),
		Color = zone.Floor,
		Material = zone.Material,
	}, parent)
	part({
		Name = "IslandRim",
		Shape = "Cylinder",
		Size = Vector3.new(0.4, len + 1, len + 1),
		CFrame = CFrame.new(0, Y - 0.1, zc) * CFrame.Angles(0, 0, math.rad(90)),
		Color = zone.Accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, parent)
end

local function label(parentPart: BasePart, face: Enum.NormalId, text: string, color: Color3)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.Parent = parentPart
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 0.35)
	t.Position = UDim2.fromScale(0, 0.3)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Parent = sg
	return t
end

local function gate(z: number, stageIndex: number, req: number, zone: Config.Zone, parent: Instance)
	local g = Instance.new("Model")
	g.Name = "Gate" .. stageIndex
	g.Parent = parent
	local wall = part({
		Name = "Barrier",
		Size = Vector3.new(W + 120, 90, 2),
		CFrame = CFrame.new(0, Y + 15, z),
		Color = Color3.fromRGB(255, 70, 90),
		Material = Enum.Material.ForceField,
		Transparency = 0.15,
		CastShadow = false,
	}, g)
	wall:SetAttribute("Req", req)
	wall:SetAttribute("Stage", stageIndex)
	CollectionService:AddTag(wall, "Gate")
	-- big readable requirement on both faces (only the middle strip over the track)
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(W, 14, 0.2),
		CFrame = CFrame.new(0, Y + 12, z),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
	}, g)
	label(sign, Enum.NormalId.Front, "⚡ " .. Format.commas(req), Color3.new(1, 1, 1))
	label(sign, Enum.NormalId.Back, "⚡ " .. Format.commas(req), Color3.new(1, 1, 1))
	for _, side in { -1, 1 } do
		part({
			Name = "Pillar",
			Size = Vector3.new(4, 30, 4),
			CFrame = CFrame.new(side * (W / 2 + 2), Y + 15 - 2, z),
			Color = zone.Accent,
			Material = Enum.Material.Neon,
		}, g)
	end
	part({
		Name = "Beam",
		Size = Vector3.new(W + 8, 3, 4),
		CFrame = CFrame.new(0, Y + 29, z),
		Color = zone.Accent,
		Material = Enum.Material.Neon,
	}, g)
end

local function pad(z: number, stageIndex: number, wins: number, zone: Config.Zone, final: boolean, parent: Instance)
	local p = part({
		Name = "WinsPad" .. stageIndex,
		Shape = "Cylinder",
		Size = Vector3.new(1, 22, 22),
		CFrame = CFrame.new(0, Y + 0.2, z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 220, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, parent)
	p:SetAttribute("Stage", stageIndex)
	CollectionService:AddTag(p, "WinsPad")
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 70)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 250
	bb.LightInfluence = 0
	bb.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = (if final then "FINISH! " else "") .. "+" .. tostring(wins) .. " 🏆"
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.fromRGB(255, 230, 90)
	t.TextStrokeTransparency = 0
	t.Parent = bb
	local att = Instance.new("Attachment")
	att.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 12
	pe.Lifetime = NumberRange.new(1, 1.6)
	pe.Speed = NumberRange.new(4, 8)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.EmissionDirection = Enum.NormalId.Right -- cylinder axis is X, rotated to point up
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90))
	pe.Size = NumberSequence.new(0.8, 0)
	pe.LightEmission = 1
	pe.Parent = att
	if final then
		-- finish arch
		for _, side in { -1, 1 } do
			part({
				Name = "ArchLeg",
				Size = Vector3.new(3, 26, 3),
				CFrame = CFrame.new(side * 14, Y + 13, z),
				Color = Color3.fromRGB(255, 230, 90),
				Material = Enum.Material.Neon,
			}, parent)
		end
		local top = part({
			Name = "ArchTop",
			Size = Vector3.new(31, 5, 3),
			CFrame = CFrame.new(0, Y + 27, z),
			Color = Color3.fromRGB(40, 30, 70),
			Material = Enum.Material.SmoothPlastic,
		}, parent)
		label(top, Enum.NormalId.Front, "FINISH", Color3.fromRGB(255, 230, 90)).Size = UDim2.fromScale(1, 1)
		label(top, Enum.NormalId.Back, "FINISH", Color3.fromRGB(255, 230, 90)).Size = UDim2.fromScale(1, 1)
	end
end

local function zoneSign(z: number, zone: Config.Zone, parent: Instance)
	local s = part({
		Name = "ZoneSign",
		Size = Vector3.new(30, 6, 1),
		CFrame = CFrame.new(-(W / 2 + 22), Y + 10, z) * CFrame.Angles(0, math.rad(200), 0),
		Color = Color3.fromRGB(20, 20, 40),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	}, parent)
	local t = label(s, Enum.NormalId.Back, zone.Name:upper(), zone.Accent)
	t.Size = UDim2.fromScale(1, 1)
	t.Position = UDim2.fromScale(0, 0)
end

local function decorate(z0: number, z1: number, zone: Config.Zone, parent: Instance)
	local z = z0
	while z < z1 do
		for _, side in { -1, 1 } do
			if rng:NextNumber() < 0.7 then
				local x = side * rng:NextNumber(W / 2 + 12, W / 2 + 70)
				rock(Vector3.new(x, Y + rng:NextNumber(-30, 25), z + rng:NextNumber(-10, 10)), rng:NextNumber(4, 14), zone.Rock, parent)
			end
			if rng:NextNumber() < 0.35 then
				crystal(Vector3.new(side * (W / 2 - 3), Y, z + rng:NextNumber(-8, 8)), rng:NextNumber(3, 7), zone.Accent, parent)
			end
		end
		z += 22
	end
end

local function planet(pos: Vector3, radius: number, color: Color3, ringColor: Color3?, parent: Instance)
	part({
		Name = "Planet",
		Shape = "Ball",
		Size = Vector3.one * radius * 2,
		CFrame = CFrame.new(pos),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
	}, parent)
	if ringColor then
		part({
			Name = "Ring",
			Shape = "Cylinder",
			Size = Vector3.new(1, radius * 3.4, radius * 3.4),
			CFrame = CFrame.new(pos) * CFrame.Angles(math.rad(20), 0, math.rad(90 + 15)),
			Color = ringColor,
			Material = Enum.Material.Neon,
			Transparency = 0.35,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
		}, parent)
	end
end

local function lighting()
	Lighting.ClockTime = 0
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(95, 90, 130)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 115, 160)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.FogEnd = 100000
	for _, c in Lighting:GetChildren() do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("BloomEffect") or c:IsA("ColorCorrectionEffect") then
			c:Destroy()
		end
	end
	local sky = Instance.new("Sky")
	sky.StarCount = 5000
	sky.CelestialBodiesShown = false
	sky.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting
end

function MapBuilder.build(): Layout
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	-- template leftovers would give players a second spawn far below the track
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") or child.Name == "Baseplate" then
			child:Destroy()
		end
	end
	mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = workspace

	workspace.Gravity = Config.Gravity
	lighting()

	local track = Instance.new("Folder")
	track.Name = "Track"
	track.Parent = mapFolder
	local deco = Instance.new("Folder")
	deco.Name = "Decor"
	deco.Parent = mapFolder

	-- spawn platform
	local zone1 = Config.Zones[1]
	floor(-40, 40, zone1, track, "SpawnFloor")
	part({
		Name = "BackWall",
		Size = Vector3.new(W + 4, 40, 2),
		CFrame = CFrame.new(0, Y + 18, -41),
		Transparency = 0.8,
		Color = zone1.Accent,
		Material = Enum.Material.ForceField,
	}, track)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, Y + 0.5, -20) * CFrame.Angles(0, math.pi, 0) -- face +Z (down the track)
	spawn.Color = Color3.fromRGB(40, 110, 140)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Transparency = 0.2
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = track
	zoneSign(10, zone1, deco)

	local T = 2 * math.sqrt(2 * Config.Gravity * Config.JumpHeight) / Config.Gravity
	local layout: Layout = { Stages = {}, SpawnCFrame = CFrame.lookAt(Vector3.new(0, Y + 4, -20), Vector3.new(0, Y + 4, 100)), EndZ = 0 }
	local z = 40
	local lastZone = 1
	for i, st in Config.Stages do
		local zone = Config.Zones[st.Zone]
		if st.Zone ~= lastZone then
			zoneSign(z + 10, zone, deco)
			lastZone = st.Zone
		end
		local stageStart = z
		local prevReq = if i > 1 then Config.Stages[i - 1].Req else 0
		local gap = math.clamp(Config.WalkSpeedFor(prevReq) * T * 0.5, 8, 45)
		local segA = 60 + 8 * i
		floor(z, z + segA, zone, track)
		z += segA
		-- two crater islands separated by gaps
		local islandLen = 22 + i
		for _ = 1, 2 do
			z += gap
			island(z + islandLen / 2, islandLen, zone, track)
			z += islandLen
		end
		z += gap
		local segB = 70 + 10 * i
		floor(z, z + segB, zone, track)
		z += segB
		local gateZ = z - 6
		gate(gateZ, i, st.Req, zone, track)
		local final = i == #Config.Stages
		local padLen = if final then 70 else 50
		floor(z, z + padLen, zone, track, "PadFloor")
		local padZ = z + 25
		pad(padZ, i, st.Wins, zone, final, track)
		decorate(stageStart, z + padLen, zone, deco)
		z += padLen
		table.insert(layout.Stages, {
			Index = i,
			StartZ = stageStart,
			GateZ = gateZ,
			PadZ = padZ,
			PadRadius = 11,
			Req = st.Req,
			Wins = st.Wins,
		})
	end
	layout.EndZ = z
	-- end wall
	part({
		Name = "EndWall",
		Size = Vector3.new(W + 4, 40, 2),
		CFrame = CFrame.new(0, Y + 18, z + 1),
		Transparency = 0.8,
		Color = Color3.fromRGB(255, 230, 90),
		Material = Enum.Material.ForceField,
	}, track)

	-- background planets, one per zone, alternating sides
	local planets = Instance.new("Folder")
	planets.Name = "Planets"
	planets.Parent = mapFolder
	local zoneZ: { [number]: number } = {}
	for _, s in layout.Stages do
		local zi = Config.Stages[s.Index].Zone
		zoneZ[zi] = zoneZ[zi] or s.StartZ
	end
	for zi, zz in zoneZ do
		local zn = Config.Zones[zi]
		local side = if zi % 2 == 0 then 1 else -1
		planet(Vector3.new(side * 700, Y + 150, zz + 300), 220, zn.Rock, if zi % 2 == 1 then zn.Accent else nil, planets)
	end
	planet(Vector3.new(400, Y - 500, z * 0.5), 300, Color3.fromRGB(60, 90, 200), Color3.fromRGB(140, 200, 255), planets)

	return layout
end

return MapBuilder
