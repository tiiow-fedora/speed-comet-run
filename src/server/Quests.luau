--!strict
-- Daily quests (v2): three per UTC day, one from each tier, free to complete.
-- Progress comes only from server-side events (pads, finish, play time, restarts).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)

local Quests = {}

local notify: ((Player, string, string) -> ())? = nil
function Quests.setNotify(fn: (Player, string, string) -> ())
	notify = fn
end

function Quests.today(): number
	return os.time() // 86400
end

local function def(id: string): Config.QuestDef?
	for _, q in Config.QuestPool do
		if q.Id == id then
			return q
		end
	end
	return nil
end
Quests.def = def

function Quests.reward(p: DataService.Profile, d: Config.QuestDef): number
	local st = Config.Stages[math.clamp(p.BestStage, 1, #Config.Stages)]
	return d.Mult * math.max(Config.QuestMinBase, st.Wins)
end

-- Make sure the profile holds today's three quests (new day -> new quests).
function Quests.ensure(player: Player, p: DataService.Profile): boolean
	local day = Quests.today()
	if p.QuestDay == day and #p.Quests == 3 and def(p.Quests[1].Id) then
		return false
	end
	local rng = Random.new(day * 7919 + (math.abs(player.UserId) % 100003))
	local list = {}
	for tier = 1, 3 do
		local pool = {}
		for _, q in Config.QuestPool do
			if q.Tier == tier then
				table.insert(pool, q)
			end
		end
		local pick = pool[rng:NextInteger(1, #pool)]
		table.insert(list, { Id = pick.Id, P = 0, C = false })
	end
	p.Quests = list
	p.QuestDay = day
	return true
end

function Quests.sync(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	local out = {}
	local claimable = false
	for i, q in p.Quests do
		local d = def(q.Id)
		if d then
			local done = q.P >= d.Target
			if done and not q.C then
				claimable = true
			end
			out[i] = {
				text = d.Text,
				progress = if d.Event == "play" then math.floor(q.P / 60) else q.P,
				target = if d.Event == "play" then math.floor(d.Target / 60) else d.Target,
				unit = if d.Event == "play" then "min" else "",
				reward = Quests.reward(p, d),
				claimed = q.C,
			}
		end
	end
	player:SetAttribute("Quests", HttpService:JSONEncode(out))
	player:SetAttribute("QuestReady", claimable)
end

-- Server-side progress event. `amount` defaults to 1.
function Quests.event(player: Player, event: string, amount: number?)
	local p = DataService.get(player)
	if not p then
		return
	end
	local changed = Quests.ensure(player, p)
	for _, q in p.Quests do
		local d = def(q.Id)
		if d and d.Event == event and not q.C and q.P < d.Target then
			local before = q.P
			q.P = math.min(d.Target, q.P + (amount or 1))
			-- play time ticks every second; only resync when the shown minute changes or it completes
			if event ~= "play" or q.P // 60 ~= before // 60 or q.P >= d.Target then
				changed = true
			end
			if q.P >= d.Target and before < d.Target and notify then
				notify(player, "quest", "Quest complete: " .. d.Text .. "! Claim it in 📜 QUESTS")
			end
		end
	end
	if changed then
		Quests.sync(player)
	end
end

function Quests.claim(player: Player, raw: any)
	local p = DataService.get(player)
	if not p or typeof(raw) ~= "number" or raw ~= raw or raw % 1 ~= 0 or raw < 1 or raw > 3 then
		return
	end
	Quests.ensure(player, p)
	local q = p.Quests[raw]
	local d = q and def(q.Id)
	if not q or not d or q.C or q.P < d.Target then
		return
	end
	q.C = true
	local wins = Quests.reward(p, d)
	p.Wins += wins
	p.TotalWins += wins
	State.sync(player)
	Quests.sync(player)
	if notify then
		notify(player, "buy", "Quest reward: +" .. Format.commas(wins) .. " Wins!")
	end
end

return Quests
