--!strict
-- Companions (v4), drawn on the client only: every player's equipped companion (Player attribute "Pet" =
-- index into Config.Companions) floats beside them. Nothing here is authoritative: the server owns
-- ownership and the Speed bonus; this module only renders. Models are built from primitives, so the
-- same builder also feeds the preview icons in the Pets panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local Pets = {}

type Rig = { model: Model, index: number, pos: Vector3?, phase: number }

local rigs: { [Player]: Rig } = {}
local folder: Folder? = nil

local function add(model: Model, shape: Enum.PartType, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, transparency: number?): Part
	local p = Instance.new("Part")
	-- Ball parts are always round (uniform size). A stretched sphere is a block with a Sphere SpecialMesh instead.
	local uniform = math.abs(size.X - size.Y) < 0.01 and math.abs(size.Y - size.Z) < 0.01
	if shape == Enum.PartType.Ball and not uniform then
		p.Shape = Enum.PartType.Block
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = p
	else
		p.Shape = shape
	end
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = offset
	p.Parent = model
	return p
end

local BALL = Enum.PartType.Ball
local BLOCK = Enum.PartType.Block

local function eyes(model: Model, z: number, y: number, spread: number, size: number)
	for _, side in { -1, 1 } do
		add(model, BALL, Vector3.one * size, CFrame.new(side * spread, y, z), Color3.new(1, 1, 1))
		add(model, BALL, Vector3.one * size * 0.55, CFrame.new(side * spread, y, z - size * 0.28), Color3.fromRGB(20, 20, 40))
	end
end

-- Model space: body centered at the origin, the pet faces -Z (CFrame.lookAt convention), +Y up.
function Pets.build(index: number): Model
	local def = Config.Companions[index]
	local model = Instance.new("Model")
	model.Name = "Companion"
	if not def then
		return model
	end
	local c, glow = def.Color, def.Glow
	local body: Part
	if def.Kind == "bug" then
		body = add(model, BALL, Vector3.new(1.5, 1.3, 1.9), CFrame.new(), c)
		add(model, BALL, Vector3.new(1.1, 1.1, 1.1), CFrame.new(0, 0.1, -1.1), c:Lerp(Color3.new(1, 1, 1), 0.25))
		add(model, BALL, Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, -0.1, 1.2), glow, Enum.Material.Neon)
		eyes(model, -1.55, 0.3, 0.32, 0.38)
		for _, side in { -1, 1 } do
			add(model, BLOCK, Vector3.new(1.6, 0.08, 1.0), CFrame.new(side * 1.0, 0.7, 0.1) * CFrame.Angles(0, 0, side * math.rad(-20)), Color3.new(1, 1, 1), Enum.Material.Glass, 0.45)
		end
	elseif def.Kind == "pup" then
		body = add(model, BALL, Vector3.new(1.7, 1.5, 2.1), CFrame.new(), c)
		add(model, BALL, Vector3.new(1.5, 1.4, 1.4), CFrame.new(0, 0.55, -1.2), c:Lerp(Color3.new(1, 1, 1), 0.2))
		add(model, BALL, Vector3.new(0.7, 0.55, 0.55), CFrame.new(0, 0.3, -1.85), Color3.fromRGB(255, 235, 215))
		add(model, BALL, Vector3.new(0.25, 0.2, 0.2), CFrame.new(0, 0.5, -2.1), Color3.fromRGB(30, 25, 40))
		eyes(model, -1.75, 0.95, 0.42, 0.34)
		for _, side in { -1, 1 } do
			add(model, BLOCK, Vector3.new(0.3, 0.8, 0.6), CFrame.new(side * 0.78, 0.9, -1.0) * CFrame.Angles(0, 0, side * math.rad(-25)), c:Lerp(Color3.new(0, 0, 0), 0.25))
		end
		add(model, BALL, Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0.5, 1.25), glow, Enum.Material.Neon)
	elseif def.Kind == "fox" then
		body = add(model, BALL, Vector3.new(1.5, 1.4, 2.3), CFrame.new(), c)
		add(model, BALL, Vector3.new(1.4, 1.3, 1.4), CFrame.new(0, 0.5, -1.25), c)
		add(model, BALL, Vector3.new(0.7, 0.55, 0.9), CFrame.new(0, 0.28, -1.95), Color3.new(1, 1, 1))
		add(model, BALL, Vector3.new(0.25, 0.2, 0.2), CFrame.new(0, 0.35, -2.4), Color3.fromRGB(30, 25, 40))
		eyes(model, -1.85, 0.85, 0.4, 0.32)
		for _, side in { -1, 1 } do
			local ear = add(model, BLOCK, Vector3.new(0.5, 1.0, 0.25), CFrame.new(side * 0.5, 1.45, -1.1) * CFrame.Angles(0, 0, side * math.rad(-12)), c)
			ear.Material = Enum.Material.SmoothPlastic
		end
		add(model, BALL, Vector3.new(1.0, 1.0, 2.2), CFrame.new(0, 0.5, 1.9) * CFrame.Angles(math.rad(-20), 0, 0), c)
		add(model, BALL, Vector3.new(0.8, 0.8, 0.9), CFrame.new(0, 0.9, 2.9), glow, Enum.Material.Neon)
	elseif def.Kind == "cat" then
		body = add(model, BALL, Vector3.new(1.6, 1.5, 2.2), CFrame.new(), c)
		add(model, BALL, Vector3.new(1.6, 1.4, 1.4), CFrame.new(0, 0.6, -1.2), c:Lerp(Color3.new(1, 1, 1), 0.12))
		eyes(model, -1.85, 0.85, 0.45, 0.4)
		for _, side in { -1, 1 } do
			add(model, BLOCK, Vector3.new(0.45, 0.7, 0.3), CFrame.new(side * 0.62, 1.55, -1.1) * CFrame.Angles(0, 0, side * math.rad(-18)), c:Lerp(Color3.new(0, 0, 0), 0.2))
		end
		add(model, BALL, Vector3.new(0.35, 0.35, 0.2), CFrame.new(0, 1.2, -1.85), glow, Enum.Material.Neon)
		add(model, BLOCK, Vector3.new(0.3, 0.3, 2.0), CFrame.new(0, 0.9, 1.7) * CFrame.Angles(math.rad(35), 0, 0), c)
		add(model, BALL, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 1.7, 2.35), glow, Enum.Material.Neon)
		add(model, BALL, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, -0.1, 0), glow, Enum.Material.Neon, 0.6)
	else -- dragon
		body = add(model, BALL, Vector3.new(1.6, 1.5, 2.2), CFrame.new(), c)
		add(model, BALL, Vector3.new(1.4, 1.3, 1.5), CFrame.new(0, 0.6, -1.25), c:Lerp(Color3.new(1, 1, 1), 0.1))
		add(model, BALL, Vector3.new(0.9, 0.6, 0.8), CFrame.new(0, 0.35, -1.95), c:Lerp(Color3.new(1, 1, 1), 0.2))
		eyes(model, -1.9, 0.95, 0.42, 0.36)
		for _, side in { -1, 1 } do
			add(model, BLOCK, Vector3.new(0.2, 0.7, 0.2), CFrame.new(side * 0.45, 1.45, -1.2) * CFrame.Angles(math.rad(-20), 0, side * math.rad(-15)), glow, Enum.Material.Neon)
			add(model, BLOCK, Vector3.new(2.0, 0.12, 1.5), CFrame.new(side * 1.5, 0.75, 0.3) * CFrame.Angles(0, side * math.rad(-15), side * math.rad(-28)), glow, Enum.Material.Neon, 0.15)
		end
		add(model, BLOCK, Vector3.new(0.45, 0.45, 2.0), CFrame.new(0, 0.1, 1.9) * CFrame.Angles(math.rad(15), 0, 0), c)
		add(model, BALL, Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 0.4, 2.95), glow, Enum.Material.Neon)
	end
	model.PrimaryPart = body
	return model
end

-- Camera for the preview icons: frames the model's bounding box from the front-right, whatever its size
-- (so a long tail or tall ears can never be cropped). Falls back to a fixed view if the box is unusable.
function Pets.previewCamera(model: Model, fov: number): CFrame
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	local fallback = CFrame.lookAt(Vector3.new(1.4, 1.6, -7.5), Vector3.new(0, 0.2, 0))
	if not ok or typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" or size.Magnitude < 0.1 then
		return fallback
	end
	local center = (cf :: CFrame).Position
	local radius = (size :: Vector3).Magnitude * 0.5
	local dist = radius / math.tan(math.rad(fov) * 0.5) * 1.1
	local dir = Vector3.new(0.22, 0.22, -1).Unit
	return CFrame.lookAt(center + dir * dist, center)
end

local function petFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "Companions"
		f.Parent = workspace
		folder = f
	end
	return folder :: Folder
end

local function removeRig(player: Player)
	local rig = rigs[player]
	if rig then
		rig.model:Destroy()
		rigs[player] = nil
	end
end

local function refresh(player: Player)
	local idx = player:GetAttribute("Pet")
	if typeof(idx) ~= "number" or not Config.Companions[idx] then
		removeRig(player)
		return
	end
	local rig = rigs[player]
	if rig and rig.index == idx then
		return
	end
	removeRig(player)
	local model = Pets.build(idx)
	model.Name = player.Name .. "_Companion"
	local sparkle = Instance.new("Attachment")
	sparkle.Parent = model.PrimaryPart
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 4
	pe.Lifetime = NumberRange.new(0.6, 1)
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.5, 0)
	pe.Color = ColorSequence.new(Config.Companions[idx].Glow)
	pe.LightEmission = 0.5
	pe.Parent = sparkle
	model.Parent = petFolder()
	rigs[player] = { model = model, index = idx, pos = nil, phase = (player.UserId % 7) * 0.9 }
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Pet"):Connect(function()
		refresh(player)
	end)
	refresh(player)
end

function Pets.start()
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(removeRig)
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		for player, rig in rigs do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and rig.model.PrimaryPart then
				local cf = hrp.CFrame
				local speed = hrp.AssemblyLinearVelocity.Magnitude
				-- beside and a little behind; stiffer when the runner is fast so the companion keeps up
				local target = cf:PointToWorldSpace(Vector3.new(3.4, 1.0 + math.sin(t * 3 + rig.phase) * 0.35, 3.8))
				local pos = rig.pos
				if not pos or (pos - target).Magnitude > 60 then
					pos = target
				else
					local k = math.min(1, dt * (9 + speed * 0.4))
					pos = pos:Lerp(target, k)
				end
				rig.pos = pos
				local face = cf.LookVector
				local flat = Vector3.new(face.X, 0, face.Z)
				if flat.Magnitude < 0.01 then
					flat = Vector3.zAxis
				end
				rig.model:PivotTo(CFrame.lookAt(pos, pos + flat) * CFrame.Angles(math.sin(t * 2.2 + rig.phase) * 0.06, 0, math.sin(t * 1.7 + rig.phase) * 0.08))
			end
		end
	end)
end

return Pets
