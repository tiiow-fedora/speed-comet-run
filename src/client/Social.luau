--!strict
-- High-fives (v5), client side: every other player's character gets a local ProximityPrompt. Using it only
-- tells the server who you want to high-five; the server checks the distance, the cooldowns and pays both
-- players. Nothing here is authoritative.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Social = {}

local player = Players.LocalPlayer
local connections: { [Player]: { RBXScriptConnection } } = {}

local function attach(other: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hrp or hrp:FindFirstChild("HighFivePrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HighFivePrompt"
	prompt.ActionText = "High five"
	prompt.ObjectText = other.DisplayName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.HighFive.Range - 4 -- the server allows a little more, for latency
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, 40)
	prompt.Parent = hrp
	prompt.Triggered:Connect(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local remote = remotes and remotes:FindFirstChild("HighFive") :: RemoteEvent?
		if remote then
			remote:FireServer(other)
		end
		-- brief local lockout so a double tap does not spam the remote; the server enforces the real cooldown
		prompt.Enabled = false
		task.delay(20, function()
			if prompt.Parent then
				prompt.Enabled = true
			end
		end)
	end)
end

local function watch(other: Player)
	if other == player then
		return
	end
	local list = {}
	table.insert(
		list,
		other.CharacterAdded:Connect(function(character)
			task.spawn(attach, other, character)
		end)
	)
	connections[other] = list
	if other.Character then
		task.spawn(attach, other, other.Character)
	end
end

function Social.start()
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(other)
		local list = connections[other]
		if list then
			for _, c in list do
				c:Disconnect()
			end
			connections[other] = nil
		end
	end)
end

return Social
