-- AreaService: separate areas linked by teleports (GDD 4). Portal Plaza gates in the hub, a
-- BACK TO HUB gate in every league area, the player's current area (attribute "Area"), and each
-- area's leaderboard board (top runners in this server, every 10 s).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Config.Areas)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local TrainingService = require(script.Parent.TrainingService)
local RaceService = require(script.Parent.RaceService)

local AreaService = {}
local Toast = Net.get("Toast")
local Moment = Net.get("Moment")
local cooldown = {}

function AreaService.canEnter(player, areaId)
	local area = Areas[areaId]
	local data = PlayerData.get(player)
	if not area or not data then
		return false
	end
	return (data.BestLeague or 1) >= area.League
end

function AreaService.teleport(player, areaId)
	local area = Areas[areaId]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not area or not root or RaceService.inRace(player) then
		return false
	end
	TrainingService.leave(player)
	pcall(function()
		player:RequestStreamAroundAsync(area.Spawn, 5)
	end)
	if not player.Parent or not root.Parent then
		return false
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(area.Spawn, area.SpawnLook)
	player:SetAttribute("Area", areaId)
	Moment:FireClient(player, "Arrive", { Area = areaId, Name = area.Name, League = area.League })
	return true
end

local function hookGate(trigger)
	local target = trigger:GetAttribute("GateArea")
	trigger.Touched:Connect(function(hit)
		local char = hit:FindFirstAncestorOfClass("Model")
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player or (cooldown[player] and os.clock() - cooldown[player] < 3) then
			return
		end
		cooldown[player] = os.clock()
		if target == "Soon" then
			Toast:FireClient(player, "Coming soon! Tap NOTIFY ME to hear when it opens", "Gold")
		elseif AreaService.canEnter(player, target) then
			AreaService.teleport(player, target)
		else
			local area = Areas[target]
			Toast:FireClient(player, ("GO PRO from League %d to open %s"):format((area and area.League or 2) - 1, area and area.Name or "this area"), "Denied")
		end
	end)
end

local function updateBoards()
	for _, id in Areas.Order do
		local area = Areas[id]
		local model = workspace:FindFirstChild(area.Model)
		local board = model and model:FindFirstChild("Leaderboard", true)
		local gui = board and board:FindFirstChildOfClass("SurfaceGui")
		local list = gui and gui:FindFirstChild("Rows", true)
		if list then
			local rows = {}
			for _, p in Players:GetPlayers() do
				local data = PlayerData.get(p)
				if data and data.League == area.League then
					table.insert(rows, { name = p.DisplayName, speed = data.Speed })
				end
			end
			table.sort(rows, function(a, b)
				return a.speed > b.speed
			end)
			for i = 1, 5 do
				local label = list:FindFirstChild("Row" .. i)
				if label then
					local r = rows[i]
					label.Text = if r then ("%d.  %s   %s MPH"):format(i, r.name, Format.short(r.speed)) else ("%d.  -"):format(i)
				end
			end
		end
	end
end

function AreaService.start()
	Net.on("TeleportArea", function(player, areaId)
		if type(areaId) ~= "string" or not AreaService.canEnter(player, areaId) then
			return false, "locked"
		end
		return AreaService.teleport(player, areaId)
	end)
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("GateArea") then
			hookGate(d)
		end
	end
	local function onPlayer(player)
		player:SetAttribute("Area", "Hub")
		player.CharacterAdded:Connect(function()
			player:SetAttribute("Area", "Hub") -- respawns are at the school steps
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		cooldown[p] = nil
	end)
	task.spawn(function()
		while true do
			pcall(updateBoards)
			task.wait(10)
		end
	end)
end

return AreaService
