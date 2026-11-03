-- Client smoke test: builds the HUD against the permissive mock and drives its refresh paths with
-- different attribute states. It cannot judge layout or visuals; it catches nil errors and typos.
local ENV = setmetatable({ ARGS = ARGS, __exists = __exists, __loadfile = __loadfile }, { __index = _G })
local ROOT = ARGS[1]
local M = __loadfile(ROOT .. "/tools/luau_harness/mock.lua", ENV)()
local pass, fail = 0, 0
local function check(name, cond, detail)
	if cond then pass = pass + 1; print("PASS " .. name) else fail = fail + 1; print("FAIL " .. name .. (detail ~= nil and (" :: " .. tostring(detail)) or "")) end
end

local test = function()
	local G = M.globals
	local Vector3 = G.Vector3
	local RS = M.game:GetService("ReplicatedStorage")
	local Players = M.game:GetService("Players")
	-- remotes the client expects
	local remotes = M.inst("Folder", "Remotes")
	local fired = {}
	for _, n in ipairs({ "Notify", "BuyBoot", "EquipBoot", "Rebirth", "ClaimDaily", "TutorialDone", "RestartLap", "SetSlow", "ClaimQuest", "BuyPet", "EquipPet", "ClaimGift" }) do
		local r = M.inst("RemoteEvent", n); r.FireServer = function(_, ...) table.insert(fired, { n, ... }) end; r.OnClientEvent = M.Signal.new(); r.Parent = remotes
	end
	remotes.Parent = RS
	local plr = M.inst("Folder", "Local")
	plr.UserId = 5; plr.Parent = Players
	plr.PlayerGui = nil
	local pg = M.inst("Folder", "PlayerGui"); pg.Parent = plr
	Players.LocalPlayer = plr
	local cam = M.inst("Folder", "Camera"); cam.ViewportSize = { X = 1280, Y = 720 }; M.workspace.CurrentCamera = cam
	-- every class gets the signals/props the UI code touches
	local mt = getmetatable(M.inst("Folder", "x"))
	local oldNew = M.globals.Instance.new
	M.globals.Instance.new = function(cls)
		local o = oldNew(cls)
		local p = rawget(o, "_props")
		p.Activated = M.Signal.new(); p.MouseButton1Click = M.Signal.new(); p.InputBegan = M.Signal.new(); p.Changed = M.Signal.new()
		p.AbsoluteSize = { X = 1280, Y = 720 }; p.TextBounds = { X = 100, Y = 20 }; p.AbsolutePosition = { X = 0, Y = 0 }
		p.GetPropertyChangedSignal = function() return M.Signal.new() end
		p.Play = function() end
		return o
	end
	M.globals.Instance.new = M.globals.Instance.new
	local UserInputService = { TouchEnabled = false, KeyboardEnabled = true, InputBegan = M.Signal.new() }
	-- services used by the client modules
	local svc = M.game
	local oldGet = svc.GetService
	svc.GetService = function(self, n)
		if n == "UserInputService" then return UserInputService end
		if n == "MarketplaceService" then return { PromptGamePassPurchase = function() end, PromptProductPurchase = function() end } end
		if n == "SocialService" then return { CanSendGameInviteAsync = function() return true end, PromptGameInvite = function() end } end
		local ok, v = pcall(oldGet, self, n)
		if ok then return v end
		return setmetatable({}, { __index = function() return function() return nil end end })
	end

	local Config = M.require(M.sharedDir.Config)
	-- Sfx touches SoundService; stub it
	M.stub("client/Sfx.luau", { play = function() end, startMusic = function() end, setMusic = function() end })
	local Hud = M.require(M.clientDir.Hud)
	Hud.build()
	check("Hud.build ran", true)
	local gui = pg:FindFirstChild("CometHud")
	check("HUD gui created", gui ~= nil)

	local function panelNamed(name)
		for _, d in ipairs(gui:GetDescendants()) do if d.Name == name then return d end end
	end
	for _, n in ipairs({ "ShopPanel", "PetsPanel", "StorePanel", "DailyPanel", "QuestsPanel", "RebirthPanel" }) do
		check("panel built: " .. n, panelNamed(n) ~= nil)
	end

	-- drive the refresh paths with different attribute states
	local states = {
		{ Speed = 0, Wins = 0, Pet = 0, OwnedPets = "", GiftSec = 0, GiftClaimed = "", GiftReady = false },
		{ Speed = 5000, Wins = 200, Pet = 1, OwnedPets = "1", GiftSec = 200, GiftClaimed = "", GiftReady = true, Checkpoint = 2, BestStage = 2 },
		{ Speed = 1e9, Wins = 1e9, Pet = 5, OwnedPets = "1,2,3,4,5", GiftSec = 4000, GiftClaimed = "1,2,3", GiftReady = true, Checkpoint = 15, BestStage = 15, Rebirths = 3, Gain = 1234567 },
	}
	for i, st in ipairs(states) do
		for k, v in pairs(st) do plr:SetAttribute(k, v) end
		plr:SetAttribute("Quests", '[{"text":"Collect 20 Comet Shards","progress":3,"target":20,"unit":"","reward":50,"claimed":false}]')
		plr:SetAttribute("TrioStreak", i)
		plr:SetAttribute("TrioDone", i == 3)
		RS:SetAttribute("GoalProgress", i * 3); RS:SetAttribute("GoalTarget", 30)
		RS:SetAttribute("GoalBoostEnds", i == 3 and (M.workspace:GetServerTimeNow() + 90) or 0)
		check("refresh with state " .. i, M.failures() == 0)
		check("next goal text state " .. i, type(Hud.nextGoal()) == "string" or Hud.nextGoal() == nil)
	end
	-- panels only refresh while open: open each one (openPanel toggles, so open -> next one closes it)
	for _, n in ipairs({ "Shop", "Pets", "Store", "Daily", "Quests", "Rebirth" }) do Hud.openPanel(n) end
	-- the last state (everything owned, boost running) must be reflected in the UI texts
	local function anyText(sub)
		for _, d in ipairs(gui:GetDescendants()) do
			local t = rawget(d, "_props").Text
			if type(t) == "string" and string.find(t, sub, 1, true) then return true end
		end
		return false
	end
	check("UI shows equipped companion", anyText("EQUIPPED"))
	check("UI shows running server boost chip", anyText("BOOST x1.5"))
	check("UI shows claimed gifts", anyText("DONE"))
	check("UI shows a ready gift", anyText("CLAIM"))
	check("UI shows quest text + trio line", anyText("Collect 20 Comet Shards") and anyText("DAILY TRIO done today"))
	check("UI shows companion chip", anyText("Void Dragon +200%"))
	check("store shows live Speed Burst amount", anyText("Speed now (5 min of your gain)"))
	-- button handlers: click every Activated signal in the panels
	local clicks = 0
	for _, d in ipairs(gui:GetDescendants()) do
		local a = rawget(d, "_props").Activated
		if a and #a.fns > 0 then a:Fire(); clicks = clicks + 1 end
	end
	check("clicked " .. clicks .. " buttons without errors", clicks > 20 and M.failures() == 0, clicks)
	local names = {}
	for _, f in ipairs(fired) do names[f[1]] = true end
	check("pet / gift / quest remotes fired from the UI", names.BuyPet or names.EquipPet, nil)
	check("gift claim remote fired from the UI", names.ClaimGift == true)

	-- Pets.build for every companion (client module)
	local Pets = M.require(M.clientDir.Pets)
	for i = 1, #Config.Companions do
		local m = Pets.build(i)
		local parts, bad = 0, 0
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then parts = parts + 1; if d.CanCollide ~= false or d.CanTouch ~= false or d.CanQuery ~= false then bad = bad + 1 end end
		end
		check("Pets.build(" .. i .. ") parts>=6 non-colliding", parts >= 6 and bad == 0 and m.PrimaryPart ~= nil, parts .. "/" .. bad)
	end
	-- Ambience zone lookup
	local Amb = M.require(M.clientDir.Ambience)
	local zs = {}
	for i = 1, #Config.Stages do zs[i] = i * 300 end
	check("Ambience.zoneAtZ", Amb.zoneAtZ(zs, 0) == 1 and Amb.zoneAtZ(zs, 1e6) == Config.Stages[#Config.Stages].Zone and Amb.zoneAtZ(zs, 3 * 300 + 10) == Config.Stages[3].Zone)
end

local co = coroutine.create(test)
local ok, err = coroutine.resume(co)
if not ok then print("TEST ERROR: " .. tostring(err) .. "\n" .. debug.traceback(co)); fail = fail + 1 end
M.advance(1)
print(string.format("CLIENT SMOKE DONE: %d pass, %d fail, %d thread errors", pass, fail, M.failures()))
if fail > 0 or M.failures() > 0 then error("client smoke failed") end
