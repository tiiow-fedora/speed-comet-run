--!strict
-- Plain DataStore persistence: retries + pcall, UpdateAsync, a soft session lock,
-- autosave, save on leave and on server shutdown (BindToClose).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}

export type Profile = {
	Speed: number,
	Wins: number,
	TotalWins: number,
	Rebirths: number,
	Boots: { [string]: boolean }, -- owned boot indexes as string keys
	Boot: number,
	PotionLeft: number,
	DailyStreak: number,
	LastDaily: number,
	BestStage: number,
	Receipts: { string }, -- recent PurchaseIds already granted (ring buffer)
	TutorialDone: boolean,
	PlaySeconds: number,
	-- v2 fields (added 2026-10-04). reconcile() fills them with defaults for old saves.
	BestSpeed: number,
	QuestDay: number,
	Quests: { { Id: string, P: number, C: boolean } },
	-- v4 fields (added 2026-11). Old saves get these defaults from reconcile(); nothing existing is renamed.
	Pets: { [string]: boolean }, -- owned companion indexes as string keys
	Pet: number, -- equipped companion index (0 = none)
	TrioDay: number, -- UTC day on which the Daily Trio (all 3 quests) was last completed
	TrioStreak: number, -- consecutive UTC days with a completed Trio
	GiftDay: number, -- UTC day the playtime-gift counters below belong to
	GiftSeconds: number, -- seconds played on GiftDay
	GiftClaims: { [string]: boolean }, -- claimed gift indexes on GiftDay
}

local function defaultProfile(): Profile
	return {
		Speed = 0,
		Wins = 0,
		TotalWins = 0,
		Rebirths = 0,
		Boots = { ["1"] = true },
		Boot = 1,
		PotionLeft = 0,
		DailyStreak = 0,
		LastDaily = 0,
		BestStage = 0,
		Receipts = {},
		TutorialDone = false,
		PlaySeconds = 0,
		BestSpeed = 0,
		QuestDay = 0,
		Quests = {},
		Pets = {},
		Pet = 0,
		TrioDay = 0,
		TrioStreak = 0,
		GiftDay = 0,
		GiftSeconds = 0,
		GiftClaims = {},
	}
end

local LOCK_TIMEOUT = 180
local MAX_RECEIPTS = 100
local JOB = if RunService:IsStudio() then "studio-" .. HttpService:GenerateGUID(false) else game.JobId

local store: DataStore? = nil
local storeOk, storeErr = pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)
if not storeOk then
	warn("[Data] DataStore unavailable (" .. tostring(storeErr) .. "); progress will not save this session")
end

local profiles: { [Player]: Profile } = {}
local loaded: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}

local function key(userId: number): string
	return "u_" .. userId
end

local function retry<T>(label: string, attempts: number, fn: () -> T): (boolean, T?)
	local lastErr
	for i = 1, attempts do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		lastErr = res
		local msg = tostring(res)
		if msg:find("StudioAccessToApisNotAllowed") or msg:find("not allowed") or msg:find("403") then
			break -- permanent; retrying only delays the player
		end
		task.wait(math.min(2 ^ i, 8))
	end
	warn("[Data] " .. label .. " failed: " .. tostring(lastErr))
	return false, nil
end

-- Fill in any fields added since the profile was first saved.
local function reconcile(data: any): Profile
	local d = defaultProfile()
	if type(data) ~= "table" then
		return d
	end
	for k, v in pairs(d) do
		if data[k] ~= nil and type(data[k]) == type(v) then
			(d :: any)[k] = data[k]
		end
	end
	if not d.Boots["1"] then
		d.Boots["1"] = true
	end
	return d
end

-- Exposed for the migration test in DevTest (old-format save -> current Profile).
DataService.reconcile = reconcile

function DataService.load(player: Player): Profile
	local profile = defaultProfile()
	if not store then
		profiles[player] = profile
		loaded[player] = false -- never save a blank profile over real data
		return profile
	end
	local ds = store :: DataStore
	local stolen = false
	local ok = false
	for attempt = 1, 4 do
		local result: any = nil
		local success = retry("load " .. player.UserId, 3, function()
			return ds:UpdateAsync(key(player.UserId), function(old: any)
				old = old or {}
				local lock = old.Lock
				if lock and lock.Job ~= JOB and os.time() - (lock.Time or 0) < LOCK_TIMEOUT and attempt < 4 then
					result = "locked"
					return nil -- cancel write; someone else still holds the session
				end
				if lock and lock.Job ~= JOB and attempt == 4 then
					stolen = true
				end
				old.Lock = { Job = JOB, Time = os.time() }
				result = old
				return old
			end)
		end)
		if not success then
			break
		end
		if result ~= "locked" then
			profile = reconcile(result and result.Data)
			ok = true
			break
		end
		task.wait(5)
	end
	if stolen then
		warn("[Data] took over stale session lock for " .. player.UserId)
	end
	profiles[player] = profile
	loaded[player] = ok
	if not ok then
		warn("[Data] could not load " .. player.UserId .. "; this session will not overwrite saved data")
	end
	return profile
end

-- Studio test helper: replace a player's in-memory profile with a brand-new one.
function DataService.resetForTest(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local fresh = defaultProfile()
	for k in pairs(p) do
		(p :: any)[k] = nil
	end
	for k, v in pairs(fresh) do
		(p :: any)[k] = v
	end
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

function DataService.isLoaded(player: Player): boolean
	return loaded[player] == true
end

-- Returns true if the write reached the DataStore.
function DataService.save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile or not loaded[player] or not store then
		return false
	end
	local ds = store :: DataStore
	while saving[player] do
		task.wait(0.1)
	end
	saving[player] = true
	local snapshot = table.clone(profile)
	local ok = retry("save " .. player.UserId, 4, function()
		return ds:UpdateAsync(key(player.UserId), function(old: any)
			old = old or {}
			if old.Lock and old.Lock.Job ~= JOB and os.time() - (old.Lock.Time or 0) < LOCK_TIMEOUT then
				-- another server took the session over; don't clobber it
				return nil
			end
			old.Data = snapshot
			old.Lock = if release then nil else { Job = JOB, Time = os.time() }
			old.SavedAt = os.time()
			return old
		end)
	end)
	saving[player] = nil
	return ok
end

function DataService.addReceipt(profile: Profile, purchaseId: string)
	table.insert(profile.Receipts, purchaseId)
	while #profile.Receipts > MAX_RECEIPTS do
		table.remove(profile.Receipts, 1)
	end
end

function DataService.hasReceipt(profile: Profile, purchaseId: string): boolean
	return table.find(profile.Receipts, purchaseId) ~= nil
end

function DataService.release(player: Player)
	DataService.save(player, true)
	profiles[player] = nil
	loaded[player] = nil
end

function DataService.start(onBeforeSave: (Player) -> ())
	Players.PlayerRemoving:Connect(function(player)
		onBeforeSave(player)
		DataService.release(player)
	end)

	task.spawn(function()
		while true do
			task.wait(60)
			for player in profiles do
				task.spawn(function()
					onBeforeSave(player)
					DataService.save(player)
				end)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				onBeforeSave(player)
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
