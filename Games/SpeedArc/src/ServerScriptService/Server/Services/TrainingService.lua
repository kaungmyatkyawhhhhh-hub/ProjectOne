-- TrainingService: AFK step machines (28 Oct pivot; tapping is gone). Walk up to a machine, press
-- TRAIN and it steps for you: Course.AfkStepsPerSecond steps a second (x3 with the Auto Run pass),
-- each paid like a running step x the machine's Mult (StepService.pay).
-- Stations live in workspace.<Area>.Training.<StationId>; each spot is a part named "Slot".
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local Format = require(Shared.Util.Format)
local PlayerData = require(script.Parent.PlayerData)
local StepService = require(script.Parent.StepService)
local Course = require(Shared.Config.Course)

local TrainingService = {}

local active = {} -- [player] = { station, slot, auto, autoSince, afkAsked }
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
		Toast:FireClient(player, ("Reach %s SPEED to use the %s"):format(Format.short(station.MinSpeed), station.Name), "Denied")
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
		auto = data.AutoTrain == true and data.Passes.AutoTrain == true,
		autoSince = os.clock(),
	}
	TrainState:FireClient(player, station.Id)
	return true
end

local AUTO = require(Shared.Config.Store).AutoTrain

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
	prompt.ActionText = "AFK STEPS"
	prompt.ObjectText = if station.MinSpeed > 0
		then ("%s  (%s SPEED)"):format(station.Name, Format.short(station.MinSpeed))
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

	-- Auto Run (pass, Store key AutoTrain): toggled by the player, machines step x3 faster, checks you're still there
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
		local step = 1 / Course.AfkStepsPerSecond
		while true do
			task.wait(step)
			local now = os.clock()
			for player, s in active do
				local data = PlayerData.get(player)
				if data then
					StepService.pay(player, data, if s.auto then Course.AutoRunMult else 1, s.station.Mult)
				end
				if s.auto then
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
