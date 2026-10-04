--!strict
-- Game passes + developer products. ProcessReceipt grants exactly once:
-- the PurchaseId is stored in the player's profile and the profile is saved
-- before PurchaseGranted is returned. If the save fails, the grant is rolled
-- back and NotProcessedYet is returned so Roblox retries later.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local DataService = require(script.Parent.DataService)
local State = require(script.Parent.State)
local Passes = require(script.Parent.Passes)
local Gameplay = require(script.Parent.Gameplay)

local Monetization = {}

local function productKey(id: number): string?
	for key, prod in Config.Products do
		if prod.Id == id and id ~= 0 then
			return key
		end
	end
	return nil
end

-- Each handler mutates the profile and returns a message for the player.
local handlers: { [string]: (Player, DataService.Profile) -> string } = {
	SpeedBurst = function(player, p)
		local amount = math.max(Config.BurstMin, Gameplay.multiplier(player, p) * Config.BurstSeconds)
		p.Speed += amount
		return "Speed Burst! +" .. Format.commas(amount) .. " Speed"
	end,
	SkipStage = function(player, p)
		local rt = Gameplay.runtime(player)
		local layout = Gameplay.layout()
		local nextIndex = (if rt then rt.checkpoint else 0) + 1
		local st = layout.Stages[nextIndex]
		if not st then
			local amount = math.max(Config.BurstMin, Gameplay.multiplier(player, p) * Config.BurstSeconds)
			p.Speed += amount
			return "No gate left this lap, so you got a Speed Burst instead: +" .. Format.commas(amount)
		end
		if p.Speed < st.Req then
			p.Speed = st.Req
		end
		task.defer(function()
			Gameplay.teleport(player, CFrame.new(0, Config.TrackY + 4, st.PadZ - 16))
		end)
		return "Skipped to stage " .. st.Index .. "! Grab the Wins pad"
	end,
	Potion3x = function(_player, p)
		p.PotionLeft += Config.PotionSeconds
		return "3x Speed Potion active for " .. Format.time(p.PotionLeft)
	end,
	WinsS = function(_player, p)
		p.Wins += 750
		p.TotalWins += 750
		return "+750 Wins!"
	end,
	WinsL = function(_player, p)
		p.Wins += 5000
		p.TotalWins += 5000
		return "+5,000 Wins!"
	end,
}
Monetization.handlers = handlers

local function processReceipt(receipt: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local p = DataService.get(player)
	if not p or not DataService.isLoaded(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if DataService.hasReceipt(p, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = productKey(receipt.ProductId)
	local handler = key and handlers[key]
	if not handler then
		warn("[Monetization] unknown product " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local before = { Speed = p.Speed, Wins = p.Wins, TotalWins = p.TotalWins, PotionLeft = p.PotionLeft }
	local ok, msg = pcall(handler, player, p)
	if not ok then
		warn("[Monetization] handler error: " .. tostring(msg))
		for k, v in before do
			(p :: any)[k] = v
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	DataService.addReceipt(p, purchaseId)
	if not DataService.save(player) then
		-- roll back so the retry doesn't double-grant
		for k, v in before do
			(p :: any)[k] = v
		end
		local idx = table.find(p.Receipts, purchaseId)
		if idx then
			table.remove(p.Receipts, idx)
		end
		State.sync(player)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	State.sync(player)
	Gameplay.applyWalkSpeed(player, p)
	Gameplay.notify(player, "purchase", msg :: string)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Monetization.processReceipt = processReceipt

function Monetization.start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = Passes.keyForId(passId)
		if key then
			Passes.grant(player, key)
			Gameplay.applyTrail(player)
			Gameplay.notify(player, "purchase", "Thanks! " .. Config.Passes[key].Name .. " unlocked")
		end
	end)
end

return Monetization
