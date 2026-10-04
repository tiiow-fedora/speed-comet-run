--!strict
-- Game pass ownership cache. Checked once on join, updated on in-game purchase.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Passes = {}
local owned: { [Player]: { [string]: boolean } } = {}

function Passes.load(player: Player)
	owned[player] = {}
	for key, pass in Config.Passes do
		if pass.Id ~= 0 then
			task.spawn(function()
				local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
				if ok and has then
					Passes.grant(player, key)
				end
			end)
		end
	end
end

function Passes.grant(player: Player, key: string)
	local t = owned[player]
	if not t then
		return
	end
	t[key] = true
	player:SetAttribute("Pass_" .. key, true)
end

function Passes.has(player: Player, key: string): boolean
	local t = owned[player]
	return t ~= nil and t[key] == true
end

function Passes.keyForId(id: number): string?
	for key, pass in Config.Passes do
		if pass.Id == id and id ~= 0 then
			return key
		end
	end
	return nil
end

function Passes.clear(player: Player)
	owned[player] = nil
end

return Passes
