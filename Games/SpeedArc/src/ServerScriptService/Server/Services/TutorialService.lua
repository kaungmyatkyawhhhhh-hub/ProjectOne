-- TutorialService (M4, GDD 21): the first 15 minutes, step by step. The server keeps the step
-- (saved, so a rejoin carries on) and judges every step it can see: the first tap, the tutorial
-- race, the first shoes, Silver rank and the first coach roll. The client draws the hints.
-- Also the GO TO / GO TRAIN teleports, used by the tutorial and after it.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Shoes = require(Shared.Config.Shoes)
local Areas = require(Shared.Config.Areas)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local TrainingService = require(script.Parent.TrainingService)
local RaceService = require(script.Parent.RaceService)
local AreaService = require(script.Parent.AreaService)
local LockerService = require(script.Parent.LockerService)
local Analytics = require(script.Parent.Analytics)

local TutorialService = {}
local T = Retention.Tutorial
local Event = Net.get("Tutorial")
local Moment = Net.get("Moment")

-- step numbers (the client has the same list)
local S = { Welcome = 1, FirstTap = 2, Combo = 3, Race = 4, Podium = 5, Shoes = 6, Silver = 7, Roll = 8, Done = 99 }
TutorialService.Steps = S
local rollsAtStart = {} -- [player] = CoachRolls when the Roll step began

local function setStep(player, n)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	data.Tutorial = n
	player:SetAttribute("Tut", n)
	if n == S.Shoes then
		-- "exact coins given" for the first shoes
		local price = 0
		for _, s in Shoes.List do
			if s.Id == T.ShoeId then
				price = s.Price
			end
		end
		if data.Coins < price then
			PlayerData.set(player, "Coins", price)
		end
	elseif n == S.Roll then
		rollsAtStart[player] = data.CoachRolls or 0
	end
	Event:FireClient(player, n)
end
TutorialService.setStep = setStep

function TutorialService.inTutorial(player)
	local data = PlayerData.get(player)
	return data ~= nil and data.Tutorial > 0 and data.Tutorial < S.Done
end

local function begin(player)
	local data = PlayerData.get(player)
	if not data or data.Tutorial ~= 0 then
		return
	end
	data.Boost.NewRunner = Retention.NewRunnerBoost.Seconds
	setStep(player, S.Welcome)
end

----------------------------------------------------------------------------
-- GO TO / GO TRAIN
----------------------------------------------------------------------------
local function promptSpot(opens)
	local hub = workspace:FindFirstChild("Hub")
	if not hub then
		return nil
	end
	for _, d in hub:GetDescendants() do
		if d:IsA("ProximityPrompt") and d:GetAttribute("Opens") == opens and d.Parent:IsA("BasePart") then
			return d.Parent
		end
	end
end

local function ensureArea(player, areaId)
	if (player:GetAttribute("Area") or "Hub") ~= areaId then
		return AreaService.teleport(player, areaId)
	end
	return true
end

local function goTo(player, target)
	local data = PlayerData.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not root or RaceService.inRace(player) then
		return false
	end
	if target == "SprintLane" or target == "Train" then
		local station = if target == "SprintLane" then Formulas.station("SprintLane") else Formulas.bestStation(data.Speed, data.League)
		if not station then
			return false
		end
		local area = "Hub"
		for _, id in Areas.Order do
			if Areas[id].League == station.League then
				area = id
			end
		end
		if not ensureArea(player, area) then
			return false
		end
		local slot = TrainingService.freeSlot(station.Id, root.Position)
		if not slot then
			return false, "full"
		end
		return TrainingService.enter(player, slot), station.Id
	end
	local spot = promptSpot(target) -- "ShoeShop" / "TrailBooth" / "CoachCorner"
	if not spot or not ensureArea(player, "Hub") then
		return false
	end
	TrainingService.leave(player)
	local stand = spot.Position + Vector3.new(7, 0, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(Vector3.new(stand.X, 3.2, stand.Z), Vector3.new(spot.Position.X, 3.2, spot.Position.Z))
	return true, target
end

----------------------------------------------------------------------------
local function startRace(player)
	local data = PlayerData.get(player)
	if not data or data.Tutorial ~= S.Race or RaceService.inRace(player) then
		return false
	end
	TrainingService.leave(player)
	if (player:GetAttribute("Area") or "Hub") ~= "Hub" then
		return false
	end
	return RaceService.private({ player }, { kind = "tutorial", raceType = "Sprint", npcs = 3, npcRange = T.RaceNpcSpeed, paceMult = T.RacePace, rig = true })
end

function TutorialService.start()
	Net.on("Tutorial", function(player, action, arg)
		local data = PlayerData.get(player)
		if not data then
			return false
		end
		if action == "play" then
			Analytics.step(player, "menu_play")
			begin(player)
			return true, data.Tutorial
		elseif action == "advance" then
			-- only the steps the client judges (the welcome line, the combo hint, the podium)
			if type(arg) == "number" and data.Tutorial == arg and (arg == S.Welcome or arg == S.Combo or arg == S.Podium) then
				setStep(player, arg + 1)
				return true
			end
			return false
		elseif action == "race" then
			return startRace(player)
		elseif action == "skip" then
			-- the client's safety timeout ran out twice: move on (never stuck)
			local step = data.Tutorial
			if type(arg) ~= "number" or arg ~= step or step < S.FirstTap or step > S.Roll then
				return false
			end
			if step == S.Race then
				return startRace(player) -- the race is never skipped, it starts by itself
			elseif step == S.Silver then
				data.FreeRolls = (data.FreeRolls or 0) + T.SilverRoll
				LockerService.push(player)
			end
			setStep(player, if step == S.Roll then S.Done else step + 1)
			return true
		end
		return false
	end)
	Net.on("GoTo", goTo)

	PlayerData.Loaded.Event:Connect(function(player)
		local data = PlayerData.get(player)
		player:SetAttribute("Tut", data.Tutorial)
		if data.Tutorial == S.Podium then
			setStep(player, S.Shoes) -- left during the podium: carry on with the shoes
		end
		-- safety: if the menu never reports PLAY (old client, error), start anyway
		task.delay(25, function()
			if player.Parent then
				begin(player)
			end
		end)
	end)

	TrainingService.Tapped.Event:Connect(function(player, taps)
		local data = PlayerData.get(player)
		if taps == 1 or (data and data.Tutorial == S.FirstTap) then
			Analytics.step(player, "first_tap")
		end
		if data and data.Tutorial == S.FirstTap then
			PlayerData.set(player, "Coins", data.Coins + T.FirstTapCoins)
			PlayerData.set(player, "Speed", data.Speed + T.FirstTapSpeed)
			Moment:FireClient(player, "FirstStep", { Coins = T.FirstTapCoins, Speed = T.FirstTapSpeed })
			setStep(player, S.Combo)
		end
	end)

	RaceService.Won.Event:Connect(function(player, _, _, info)
		local data = PlayerData.get(player)
		if data and info and info.kind == "tutorial" and data.Tutorial == S.Race then
			setStep(player, S.Podium)
		end
	end)

	-- the steps the server sees in the save
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local data = PlayerData.get(player)
				if not data then
					continue
				end
				local step = data.Tutorial
				if step == S.Shoes and data.OwnedShoes[T.ShoeId] then
					setStep(player, S.Silver)
				elseif step == S.Silver and (data.Rank or 1) >= 2 then
					data.FreeRolls = (data.FreeRolls or 0) + T.SilverRoll
					LockerService.push(player)
					setStep(player, S.Roll)
				elseif step == S.Roll and (data.CoachRolls or 0) > (rollsAtStart[player] or 0) then
					setStep(player, S.Done)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		rollsAtStart[p] = nil
	end)
end

return TutorialService
