-- TrainingService: walk up to a station, TRAIN, tap to gain SPEED (GDD 7).
-- Stations live in workspace.Hub.Training.<StationId>; each spot is a part named "Slot".
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Config.GameConfig)
local Formulas = require(Shared.Util.Formulas)
local Boosts = require(Shared.Util.Boosts)
local Net = require(Shared.Util.Net)
local Format = require(Shared.Util.Format)
local PlayerData = require(script.Parent.PlayerData)
local SessionBoosts = require(script.Parent.SessionBoosts)

local TrainingService = {}
TrainingService.Tapped = Instance.new("BindableEvent") -- (player, totalTaps, combo)

local active = {} -- [player] = { station, slot, lastTap, streakStart, recent = {}, coinFrac, bucket, bucketAt }
local slotOwner = {} -- [slot] = player
local allSlots = {} -- [slot] = true

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

-- a free spot of a station (GO TO / GO TRAIN buttons), nearest first to `near`
function TrainingService.freeSlot(stationId, near)
	local best, bestD = nil, math.huge
	for slot in allSlots do
		if slot:GetAttribute("StationId") == stationId and not slotOwner[slot] and slot.Parent then
			local d = if near then (slot.Position - near).Magnitude else slot:GetAttribute("Index") or 1
			if d < bestD then
				best, bestD = slot, d
			end
		end
	end
	return best
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
		Toast:FireClient(player, ("Reach %s MPH to use the %s"):format(Format.short(station.MinSpeed), station.Name), "Denied")
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
		auto = data.AutoTrain == true and data.Passes.AutoTrain == true,
		autoSince = os.clock(),
	}
	TrainState:FireClient(player, station.Id)
	return true
end

local applyGain
local AUTO = require(Shared.Config.Store).AutoTrain

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

	if s.auto then
		return -- Auto Train is tapping for you (your own taps don't add on top)
	end
	applyGain(player, s, combo)
end

-- one tap's worth of SPEED and coins (a real tap or an Auto Train tap)
function applyGain(player, s, combo)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local b = Boosts.compute(data)
	local gain = s.station.Gain * combo * b.Train * SessionBoosts.trainMult(player, data)
	PlayerData.set(player, "Speed", data.Speed + gain)
	data.Stats.Taps += 1
	TrainingService.Tapped:Fire(player, data.Stats.Taps, combo)

	s.coinFrac += Formulas.coinsPerTap(data.League) * b.Coins
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
	allSlots[slot] = true
	local prompt = slot:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = slot
	end
	prompt.ActionText = "TRAIN"
	prompt.ObjectText = if station.MinSpeed > 0
		then ("%s  (%s MPH)"):format(station.Name, Format.short(station.MinSpeed))
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
	-- stations in every area (hub, City Park, Stadium ...)
	local Areas = require(Shared.Config.Areas)
	for _, id in Areas.Order do
		local model = workspace:FindFirstChild(Areas[id].Model)
		local training = model and model:FindFirstChild("Training")
		if training then
			for _, d in training:GetDescendants() do
				if d:IsA("BasePart") and d.Name == "Slot" then
					setupSlot(d)
				end
			end
		end
	end

	Net.get("TrainTap").OnServerEvent:Connect(onTap)

	-- Auto Train (pass): toggled by the player, works on any station, checks you're still there
	local StoreEvent = Net.get("StoreEvent")
	Net.on("SetAutoTrain", function(player, on)
		local data = PlayerData.get(player)
		if not data or not data.Passes.AutoTrain then
			return false, "pass"
		end
		data.AutoTrain = on == true
		player:SetAttribute("AutoTrain", data.AutoTrain)
		local s = active[player]
		if s then
			s.auto = data.AutoTrain
			s.autoSince = os.clock()
		end
		return true, data.AutoTrain
	end)
	Net.on("AfkOk", function(player)
		local s = active[player]
		if s then
			s.autoSince = os.clock()
			s.afkAsked = nil
		end
		return true
	end)
	task.spawn(function()
		local step = 1 / AUTO.TapsPerSecond
		while true do
			task.wait(step)
			local now = os.clock()
			for player, s in active do
				if s.auto then
					applyGain(player, s, AUTO.Combo)
					if not s.afkAsked and now - (s.autoSince or now) > AUTO.AfkCheckSeconds then
						s.afkAsked = now
						StoreEvent:FireClient(player, "afk", { Seconds = AUTO.AfkAnswerSeconds })
					elseif s.afkAsked and now - s.afkAsked > AUTO.AfkAnswerSeconds then
						-- no answer: stop (the station stays yours, just no more auto taps)
						s.auto = false
						s.afkAsked = nil
						local data = PlayerData.get(player)
						if data then
							data.AutoTrain = false
						end
						player:SetAttribute("AutoTrain", false)
						StoreEvent:FireClient(player, "afkStopped", {})
					end
				end
			end
		end
	end)
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
