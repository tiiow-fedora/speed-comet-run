-- Minimal Roblox mock for running the server modules outside Studio (logic checks only).
local M = {}
local ROOT = ARGS[1]

-- ---------- scheduler ----------
local now = 0
local threads = {}
local failures = 0
local function report(co, err)
	failures = failures + 1
	print("THREAD ERROR: " .. tostring(err) .. "\n" .. debug.traceback(co))
end
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then report(co, err) end
end
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ fns = {} }, Signal) end
function Signal:Connect(fn) table.insert(self.fns, fn); return { Disconnect = function() end } end
function Signal:Wait() local co = coroutine.running(); table.insert(self.fns, function(...) resume(co, ...) end); return coroutine.yield() end
function Signal:Fire(...) for _, f in ipairs({ table.unpack(self.fns) }) do local co = coroutine.create(f); resume(co, ...) end end
M.Signal = Signal

local task = {}
function task.wait(t)
	local co = coroutine.running()
	table.insert(threads, { co = co, wake = now + (t or 0.03) })
	coroutine.yield()
	return t or 0.03
end
function task.spawn(f, ...)
	local co = coroutine.create(f); resume(co, ...); return co
end
function task.defer(f, ...) table.insert(threads, { co = coroutine.create(f), wake = now, args = { ... } }) end
function task.delay(t, f, ...) table.insert(threads, { co = coroutine.create(f), wake = now + t, args = { ... } }) end
M.task = task

local heartbeat = Signal.new()
-- advance simulated time by dt seconds in 0.1 s heartbeats
function M.advance(dt)
	local target = now + dt
	while now < target - 1e-9 do
		now = math.min(target, now + 0.1)
		heartbeat:Fire(0.1)
		-- run due threads (they may schedule more)
		local progress = true
		while progress do
			progress = false
			table.sort(threads, function(a, b) return a.wake < b.wake end)
			for i, th in ipairs(threads) do
				if th.wake <= now + 1e-9 then
					table.remove(threads, i)
					if coroutine.status(th.co) == "suspended" then resume(th.co, table.unpack(th.args or {})) end
					progress = true
					break
				end
			end
		end
	end
end
function M.now() return now end

-- ---------- data types ----------
local Vector3 = {}
Vector3.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X ^ 2 + v.Y ^ 2 + v.Z ^ 2) end
	if k == "Unit" then local m = math.sqrt(v.X ^ 2 + v.Y ^ 2 + v.Z ^ 2); return Vector3.new(v.X / m, v.Y / m, v.Z / m) end
	return rawget(Vector3, k)
end
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3) end
Vector3.zero = Vector3.new(0, 0, 0); Vector3.one = Vector3.new(1, 1, 1)
Vector3.xAxis = Vector3.new(1, 0, 0); Vector3.yAxis = Vector3.new(0, 1, 0); Vector3.zAxis = Vector3.new(0, 0, 1)
Vector3.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3.__mul = function(a, b)
	if type(a) == "number" then return Vector3.new(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
Vector3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
Vector3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
function Vector3.Lerp(a, b, t) return a + (b - a) * t end
local CFrame = {}
CFrame.__index = function(c, k)
	if k == "Position" then return rawget(c, "p") end
	if k == "LookVector" then return rawget(c, "look") or Vector3.new(0, 0, 1) end
	return rawget(CFrame, k)
end
function CFrame.new(x, y, z)
	local p
	if type(x) == "table" then p = x else p = Vector3.new(x or 0, y or 0, z or 0) end
	return setmetatable({ p = p }, CFrame)
end
function CFrame.lookAt(a, b) local c = CFrame.new(a); rawset(c, "look", (b - a).Magnitude > 0 and (b - a).Unit or Vector3.zAxis); return c end
function CFrame.Angles() return CFrame.new(0, 0, 0) end
CFrame.__mul = function(a, b) if getmetatable(b) == Vector3 then return a.Position + b end return CFrame.new(a.Position + b.Position) end
function CFrame.PointToWorldSpace(c, v) return c.Position + v end
local Color3 = {}
Color3.__index = function(c, k) if k == "Lerp" then return function(a) return a end end return rawget(Color3, k) end
function Color3.fromRGB(r, g, b) return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, Color3) end
function Color3.new(r, g, b) return setmetatable({ R = r, G = g, B = b }, Color3) end
function Color3.Lerp(a) return a end
Color3.__index = Color3

local Any
Any = setmetatable({}, {
	__index = function(_, k) return Any end,
	__call = function() return Any end,
})

-- ---------- instances ----------
local baseClass = { Part = "BasePart", WedgePart = "BasePart", SpawnLocation = "BasePart", Folder = "Instance", IntValue = "ValueBase" }
local Instance = {}
local function isA(obj, cls)
	local c = rawget(obj, "ClassName")
	return c == cls or baseClass[c] == cls or cls == "Instance"
end
local instMT = {}
instMT.__index = function(o, k)
	local props = rawget(o, "_props")
	local v = props[k]
	if v ~= nil then return v end
	for _, ch in ipairs(rawget(o, "_children")) do if ch.Name == k then return ch end end
	local m = instMT[k]
	if m then return m end
	return nil
end
instMT.__newindex = function(o, k, v)
	if k == "Parent" then
		local old = rawget(o, "_props").Parent
		if old then for i, ch in ipairs(rawget(old, "_children")) do if ch == o then table.remove(rawget(old, "_children"), i); break end end end
		rawget(o, "_props").Parent = v
		if v then table.insert(rawget(v, "_children"), o) end
		return
	end
	rawget(o, "_props")[k] = v
end
function instMT.FindFirstChild(o, name) for _, ch in ipairs(rawget(o, "_children")) do if ch.Name == name then return ch end end return nil end
function instMT.WaitForChild(o, name) return instMT.FindFirstChild(o, name) end
function instMT.FindFirstChildOfClass(o, cls) for _, ch in ipairs(rawget(o, "_children")) do if isA(ch, cls) then return ch end end return nil end
function instMT.GetChildren(o) return { table.unpack(rawget(o, "_children")) } end
function instMT.GetDescendants(o)
	local out = {}
	local function walk(x) for _, ch in ipairs(rawget(x, "_children")) do table.insert(out, ch); walk(ch) end end
	walk(o); return out
end
function instMT.IsA(o, cls) return isA(o, cls) end
function instMT.Destroy(o) o.Parent = nil end
function instMT.SetAttribute(o, k, v)
	local a = rawget(o, "_attrs")
	if a[k] == v then return end
	a[k] = v
	local s = rawget(o, "_sigs")[k]
	if s then s:Fire() end
end
function instMT.GetAttribute(o, k) return rawget(o, "_attrs")[k] end
function instMT.GetAttributeChangedSignal(o, k)
	local sigs = rawget(o, "_sigs")
	sigs[k] = sigs[k] or Signal.new()
	return sigs[k]
end
function instMT.PivotTo(o, cf) o.CFrame = cf; local hrp = instMT.FindFirstChild(o, "HumanoidRootPart"); if hrp then hrp.Position = cf.Position; hrp.CFrame = cf end end
M.fired = {}
function Instance.new(cls)
	local o = setmetatable({ _props = { ClassName = cls, Name = cls }, _children = {}, _attrs = {}, _sigs = {} }, instMT)
	rawset(o, "ClassName", cls)
	if cls == "RemoteEvent" then
		o._props.OnServerEvent = Signal.new()
		o._props.FireClient = function(self, plr, ...) table.insert(M.fired, { remote = self.Name, player = plr, args = { ... } }) end
	elseif baseClass[cls] == "BasePart" then
		o._props.Size = Vector3.new(2, 1, 4); o._props.CFrame = CFrame.new(0, 0, 0); o._props.Position = Vector3.new(0, 0, 0)
		o._props.Transparency = 0; o._props.CanCollide = true; o._props.CanTouch = true; o._props.CanQuery = true
	elseif cls == "BindableFunction" then
		o._props.Invoke = function() end
	end
	return o
end
function M.inst(cls, name, props)
	local o = Instance.new(cls)
	o.Name = name or cls
	for k, v in pairs(props or {}) do o[k] = v end
	return o
end

-- ---------- services ----------
local function dirRef(path, name, parent) -- lazily resolves files/subfolders under a directory
	local ref = { __dir = path, Name = name, Parent = parent }
	return setmetatable(ref, { __index = function(t, k)
		local f = path .. "/" .. k .. ".luau"
		if __exists(f) then local r = { __file = f, Name = k, Parent = t }; rawset(t, k, r); return r end
		local d = dirRef(path .. "/" .. k, k, t)
		rawset(t, k, d); return d
	end })
end
local sharedDir = dirRef(ROOT .. "/src/shared", "Shared")
local serverDir = dirRef(ROOT .. "/src/server", "Server")
local clientDir = dirRef(ROOT .. "/src/client", "Client")
M.serverDir, M.clientDir, M.sharedDir = serverDir, clientDir, sharedDir

local RS = M.inst("Folder", "ReplicatedStorage"); rawget(RS, "_children")[1] = sharedDir
local players = {}
local PlayersSvc = M.inst("Folder", "Players")
PlayersSvc.GetPlayers = function() return { table.unpack(players) } end
PlayersSvc.PlayerAdded = Signal.new(); PlayersSvc.PlayerRemoving = Signal.new()
PlayersSvc.GetPlayerByUserId = function(_, id) for _, p in ipairs(players) do if p.UserId == id then return p end end return nil end
PlayersSvc.GetNameFromUserIdAsync = function() return "Someone" end
M.players = players
local RunService = { IsStudio = function() return true end, Heartbeat = heartbeat, RenderStepped = Signal.new() }
local Http = { GenerateGUID = function() return "guid" end, JSONEncode = function(_, v)
	local function enc(x)
		if type(x) == "table" then
			if #x > 0 then local t = {}; for _, e in ipairs(x) do table.insert(t, enc(e)) end return "[" .. table.concat(t, ",") .. "]" end
			local t = {}; for k, e in pairs(x) do table.insert(t, '"' .. k .. '":' .. enc(e)) end return "{" .. table.concat(t, ",") .. "}"
		elseif type(x) == "string" then return '"' .. x .. '"' else return tostring(x) end
	end
	return enc(v)
end, JSONDecode = function(_, str)
	local pos = 1
	local function ws() pos = str:find("%S", pos) or #str + 1 end
	local value
	local function parseString()
		local e = str:find('"', pos + 1, true)
		local v = str:sub(pos + 1, e - 1); pos = e + 1; return v
	end
	function value()
		ws()
		local c = str:sub(pos, pos)
		if c == "{" then
			local t = {}; pos = pos + 1; ws()
			if str:sub(pos, pos) == "}" then pos = pos + 1; return t end
			while true do
				ws(); local k = parseString(); ws(); pos = pos + 1 -- ':'
				t[k] = value(); ws()
				local d = str:sub(pos, pos); pos = pos + 1
				if d == "}" then return t end
			end
		elseif c == "[" then
			local t = {}; pos = pos + 1; ws()
			if str:sub(pos, pos) == "]" then pos = pos + 1; return t end
			while true do
				table.insert(t, value()); ws()
				local d = str:sub(pos, pos); pos = pos + 1
				if d == "]" then return t end
			end
		elseif c == '"' then return parseString()
		elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
		elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
		else
			local num = str:match("^-?[%d%.eE+-]+", pos); pos = pos + #num; return tonumber(num)
		end
	end
	return value()
end }
local services = {
	ReplicatedStorage = RS, Players = PlayersSvc, RunService = RunService, HttpService = Http,
	DataStoreService = { GetDataStore = function() error("no datastore in harness") end, GetOrderedDataStore = function() error("none") end },
	MarketplaceService = { UserOwnsGamePassAsync = function() return false end, PromptGamePassPurchaseFinished = Signal.new(), PromptProductPurchaseFinished = Signal.new() },
	Lighting = M.inst("Folder", "Lighting"), ServerStorage = M.inst("Folder", "ServerStorage"),
	CollectionService = { AddTag = function() end, GetTagged = function() return {} end },
	StarterPlayer = M.inst("Folder", "StarterPlayer"), ServerScriptService = M.inst("Folder", "ServerScriptService"), SocialService = Any, TweenService = Any, UserInputService = Any,
	TextChatService = Any, SoundService = Any, ContentProvider = Any,
}
local workspace = M.inst("Folder", "Workspace")
workspace.GetServerTimeNow = function() return 1.7e9 + now end
workspace.Gravity = 80
M.workspace = workspace
local game = { GetService = function(_, n) return assert(services[n], "no service " .. n) end, JobId = "job1", BindToClose = function() end }
game.BindToClose = function() end
M.game = game

M.globals = {
	game = game, workspace = workspace, task = task, Instance = Instance, Vector3 = Vector3, CFrame = CFrame, Color3 = Color3,
	Random = { new = function(seed) local s = seed or 1; return { NextInteger = function(_, a, b) s = (s * 1103515245 + 12345) % 2147483648; return a + s % (b - a + 1) end, NextNumber = function(_, a, b) s = (s * 1103515245 + 12345) % 2147483648; return (a or 0) + (s / 2147483648) * ((b or 1) - (a or 0)) end } end },
	Enum = Any, UDim2 = Any, UDim = Any, Vector2 = Any, TweenInfo = Any, NumberRange = Any, NumberSequence = Any, ColorSequence = Any, NumberSequenceKeypoint = Any,
	warn = function(...) print("WARN", ...) end, print = print, pairs = pairs, ipairs = ipairs, next = next, type = type, typeof = function(v) if type(v) == "table" and getmetatable(v) == Vector3 then return "Vector3" end return type(v) end,
	tostring = tostring, tonumber = tonumber, math = math, string = string, table = table, os = setmetatable({ clock = function() return now end }, { __index = os }), select = select, error = error, assert = assert, pcall = pcall, xpcall = xpcall,
	setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget, rawset = rawset, unpack = table.unpack, coroutine = coroutine, utf8 = utf8, debug = debug,
}

-- ---------- require ----------
local cache = {}
local stubs = {}
function M.stub(fileSuffix, value) stubs[fileSuffix] = value end
local function load(ref)
	local file = ref.__file
	for suffix, v in pairs(stubs) do if file:sub(-#suffix) == suffix then return v end end
	if cache[file] ~= nil then return cache[file] end
	local env = setmetatable({ script = ref, require = M.require }, { __index = M.globals })
	local fn = __loadfile(file, env)
	local result = fn()
	cache[file] = result
	return result
end
function M.require(ref) assert(ref and ref.__file, "require of non-module"); return load(ref) end
function M.setGlobalOverride(k, v) M.globals[k] = v end

-- ---------- players ----------
local nextId = 1000
function M.newPlayer(name)
	nextId = nextId + 1
	local p = M.inst("Folder", name)
	p.UserId = nextId; p.DisplayName = name
	p.IsFriendsWith = function() return false end
	p.CharacterAdded = Signal.new(); p.CharacterRemoving = Signal.new()
	local char = M.inst("Folder", "Character")
	local hum = M.inst("Humanoid", "Humanoid"); hum.Health = 100; hum.Parent = char
	local hrp = M.inst("Part", "HumanoidRootPart"); hrp.Position = Vector3.new(0, 204, -20); hrp.CFrame = CFrame.new(0, 204, -20); hrp.AssemblyLinearVelocity = Vector3.zero; hrp.Parent = char
	char.PivotTo = function(c, cf) hrp.Position = cf.Position; hrp.CFrame = cf end
	p.Character = char
	table.insert(players, p)
	return p, hrp
end
function M.failures() return failures end
return M
