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
local LeagueService = require(Services.LeagueService)
local AreaService = require(Services.AreaService)
local RetentionService = require(Services.RetentionService)
local Analytics = require(Services.Analytics)
local TutorialService = require(Services.TutorialService)
local SocialService = require(Services.SocialService)
local LeaderboardService = require(Services.LeaderboardService)
local StoreService = require(Services.StoreService)
local CosmeticsService = require(Services.CosmeticsService)

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
-- lesson: destroy the character of a player who left (old characters kept memory growing)
Players.PlayerRemoving:Connect(function(player)
	task.defer(function()
		local char = player.Character
		if char and char.Parent then
			char:Destroy()
		end
	end)
end)

PlayerData.start()
TrainingService.start()
RaceService.start()
LockerService.start()
CoachService.start()
LeagueService.start()
AreaService.start()
RetentionService.start()
Analytics.start()
TutorialService.start()
SocialService.start()
LeaderboardService.start()
StoreService.start()
CosmeticsService.start()

-- Studio soak test: Workspace TestSoak = true logs server memory every 2 min into the attribute SoakLog
if game:GetService("RunService"):IsStudio() then
	task.spawn(function()
		local Stats = game:GetService("Stats")
		local started = os.clock()
		while true do
			task.wait(120)
			if workspace:GetAttribute("TestSoak") then
				local line = ("%dmin %.0fMB inst=%d"):format((os.clock() - started) // 60, Stats:GetTotalMemoryUsageMb(), Stats.InstanceCount)
				workspace:SetAttribute("SoakLog", (workspace:GetAttribute("SoakLog") or "") .. line .. "; ")
			end
		end
	end)
end
