-- SPEED ARC server boot. Starts every service in order.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)

local Services = script.Parent.Services
local PlayerData = require(Services.PlayerData)
local TrainingService = require(Services.TrainingService)
local RaceService = require(Services.RaceService)
local LockerService = require(Services.LockerService)
local CoachService = require(Services.CoachService)

Net.get("Toast") -- creates the remotes before any client asks for them

-- Hub walk speed grows slowly with SPEED and is capped (GDD 6.3)
local function applyWalkSpeed(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local data = PlayerData.get(player)
	if hum and data then
		hum.WalkSpeed = Formulas.walkSpeed(data.Speed)
	end
end

PlayerData.Changed.Event:Connect(function(player, key)
	if key == "Speed" then
		applyWalkSpeed(player)
	end
end)
PlayerData.Loaded.Event:Connect(applyWalkSpeed)

local function onPlayer(player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid")
		applyWalkSpeed(player)
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	onPlayer(p)
end

PlayerData.start()
TrainingService.start()
RaceService.start()
LockerService.start()
CoachService.start()
