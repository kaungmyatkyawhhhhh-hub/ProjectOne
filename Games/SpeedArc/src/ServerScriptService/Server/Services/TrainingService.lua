-- TrainingService: walk up to a station, TRAIN, tap to gain SPEED (GDD 7).
-- Stations live in workspace.Hub.Training.<StationId>; each spot is a part named "Slot".
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)

local TrainingService = {}

local active = {} -- [player] = { station, slot, lastTap, streakStart, recent = {}, coinFrac, bucket, bucketAt }
local slotOwner = {} -- [slot] = player

local TrainState = Net.get("TrainState")
local Toast = Net.get("Toast")

local function rootOf(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if hum and root and hum.Health > 0 then
		return root, hum
	end
	return nil
end

local function standCFrame(slot, hum, root)
	local up = slot.Size.Y / 2 + hum.HipHeight + root.Size.Y / 2
	return slot.CFrame * CFrame.new(0, up, 0)
end

function TrainingService.current(player)
	local s = active[player]
	return s and s.station.Id, s and s.slot
end

function TrainingService.leave(player, silent)
	local s = active[player]
	if not s then
		return
	end
	active[player] = nil
	slotOwner[s.slot] = nil
	local prompt = s.slot:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end
	local root = rootOf(player)
	if root then
		root.Anchored = false
		-- step off to the side of the station so you don't land back on the prompt
		local exit = s.slot:FindFirstChild("Exit")
		if exit then
			root.CFrame = exit.WorldCFrame + Vector3.new(0, 3, 0)
		end
	end
	if not silent then
		TrainState:FireClient(player, nil)
	end
end

function TrainingService.enter(player, slot)
	if player:GetAttribute("InRace") then
		return false
	end
	local data = PlayerData.get(player)
	local station = Formulas.station(slot:GetAttribute("StationId"))
	local root, hum = rootOf(player)
	if not data or not station or not root then
		return false
	end
	if data.Speed < station.MinSpeed then
		Toast:FireClient(player, ("Reach %d MPH to use the %s"):format(station.MinSpeed, station.Name), "Denied")
		return false
	end
	if slotOwner[slot] and slotOwner[slot] ~= player then
		Toast:FireClient(player, "This spot is taken. Try the one next to it!", "Denied")
		return false
	end
	TrainingService.leave(player, true)

	slotOwner[slot] = player
	local prompt = slot:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end
	root.Anchored = true
	root.CFrame = standCFrame(slot, hum, root)
	active[player] = {
		station = station,
		slot = slot,
		lastTap = 0,
		streakStart = 0,
		recent = {},
		coinFrac = 0,
		bucket = GameConfig.Speed.MaxTapsPerSecond,
		bucketAt = os.clock(),
	}
	TrainState:FireClient(player, station.Id)
	return true
end

local function onTap(player)
	local s = active[player]
	if not s then
		return
	end
	local now = os.clock()
	-- token bucket: at most MaxTapsPerSecond counted
	local maxRate = GameConfig.Speed.MaxTapsPerSecond
	s.bucket = math.min(maxRate, s.bucket + (now - s.bucketAt) * maxRate)
	s.bucketAt = now
	if s.bucket < 1 then
		return
	end
	s.bucket -= 1

	-- combo: steady = at least MinTapsPerSecond, no gap over MaxGap
	local c = GameConfig.Combo
	if now - s.lastTap > c.MaxGap then
		s.streakStart = now
		table.clear(s.recent)
	end
	s.lastTap = now
	table.insert(s.recent, now)
	if #s.recent > c.MinTapsPerSecond then
		table.remove(s.recent, 1)
	end
	local steady = #s.recent >= c.MinTapsPerSecond and now - s.recent[1] <= 1
	local combo = if steady then Formulas.combo(now - s.streakStart) else 1

	local data = PlayerData.get(player)
	if not data then
		return
	end
	local gain = s.station.Gain * combo
	PlayerData.set(player, "Speed", data.Speed + gain)
	data.Stats.Taps += 1

	s.coinFrac += Formulas.coinsPerTap(data.League)
	if s.coinFrac >= 1 then
		local whole = math.floor(s.coinFrac)
		s.coinFrac -= whole
		PlayerData.set(player, "Coins", data.Coins + whole)
	end
end

local function setupSlot(slot)
	local station = Formulas.station(slot:GetAttribute("StationId"))
	if not station then
		return
	end
	local prompt = slot:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = slot
	end
	prompt.ActionText = "TRAIN"
	prompt.ObjectText = if station.MinSpeed > 0
		then ("%s  (%d MPH)"):format(station.Name, station.MinSpeed)
		else station.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Triggered:Connect(function(player)
		TrainingService.enter(player, slot)
	end)
end

function TrainingService.start()
	local training = workspace:WaitForChild("Hub"):WaitForChild("Training")
	for _, d in training:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Slot" then
			setupSlot(d)
		end
	end

	Net.get("TrainTap").OnServerEvent:Connect(onTap)
	Net.get("TrainLeave").OnServerEvent:Connect(function(player)
		TrainingService.leave(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterRemoving:Connect(function()
			TrainingService.leave(player, true)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterRemoving:Connect(function()
			TrainingService.leave(player, true)
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		TrainingService.leave(player, true)
	end)
end

return TrainingService
