-- RaceService: a race on the School Track every 3 minutes for everyone on the server (GDD 8).
-- Server-authoritative: the server moves every runner; clients only send JOIN and BOOST taps.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Race = require(Shared.Config.Race)
local Palette = require(Shared.Config.Palette)
local Formulas = require(Shared.Util.Formulas)
local TrackPath = require(Shared.Util.TrackPath)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local TrainingService = require(script.Parent.TrainingService)

local RaceService = {}

local IS_STUDIO = RunService:IsStudio()
local LANE_ORDER = { 3, 4, 2, 5, 1, 6 }

local RaceEvent = Net.get("RaceEvent")
local RaceTick = Net.get("RaceTick")
local Toast = Net.get("Toast")

local state -- Folder with attributes the clients read: Phase, EndsAt, Type, Laps, RaceId
local joined = {} -- [player] = true during the join window
local runners = {} -- list of runner records during a race
local runnerByPlayer = {}
local raceId = 0
local rotation = 0
local raceStartClock = 0 -- os.clock() when GO was given

local npcPool -- Folder in ServerStorage holding idle NPC models
local npcModels = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function setPhase(phase, duration)
	state:SetAttribute("Phase", phase)
	state:SetAttribute("EndsAt", now() + (duration or 0))
end

----------------------------------------------------------------------------
-- NPC runners (original characters, made once and reused)
----------------------------------------------------------------------------
local NPC_LOOKS = {
	{ skin = "#E8B48A", shirt = Palette.ElectricBlue, shorts = Palette.SpeedBlack },
	{ skin = "#8D5A3B", shirt = Palette.Gold, shorts = Palette.Carbon },
	{ skin = "#F2CDA8", shirt = Palette.White, shorts = Palette.DeepBlue },
	{ skin = "#B97A50", shirt = Palette.BrightBlue, shorts = Palette.SpeedBlack },
	{ skin = "#5E3A26", shirt = Palette.DeepGold, shorts = Palette.Carbon },
	{ skin = "#E0A981", shirt = Palette.DeepBlue, shorts = Palette.Graphite },
	{ skin = "#C68B62", shirt = Palette.Graphite, shorts = Palette.SpeedBlack },
	{ skin = "#F5D4B5", shirt = Palette.DangerRed, shorts = Palette.Carbon },
}

local function makeNpc(i)
	local look = NPC_LOOKS[(i - 1) % #NPC_LOOKS + 1]
	local desc = Instance.new("HumanoidDescription")
	local skin = Color3.fromHex(look.skin)
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = look.shirt
	desc.LeftLegColor = look.shorts
	desc.RightLegColor = look.shorts
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[RaceService] NPC build failed:", model)
		return nil
	end
	model.Name = "Runner_" .. Race.NpcNames[i]
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.DisplayName = Race.NpcNames[i]
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
		end
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	model.PrimaryPart.Anchored = true
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Npc", true)
	model.Parent = npcPool
	return model
end

local function getNpc(i)
	if not npcModels[i] then
		npcModels[i] = makeNpc(i)
	end
	return npcModels[i]
end

----------------------------------------------------------------------------
-- Race flow
----------------------------------------------------------------------------
local function playRun(r)
	local animator = r.hum and r.hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = Race.RunAnimation
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.2)
		r.track = track
	end
end

local function stopRun(r)
	if r.track then
		r.track:Stop(0.3)
		r.track = nil
	end
end

local function placeRunner(r, progress)
	if r.root and r.root.Parent then
		r.root.CFrame = TrackPath.runnerCFrame(r.lane, progress, r.laps)
	end
end

local function buildRunners(raceType)
	local laps = Race.Types[raceType].Laps
	table.clear(runners)
	table.clear(runnerByPlayer)

	local humans = {}
	for player in joined do
		if player.Parent and PlayerData.get(player) and player.Character then
			table.insert(humans, player)
		end
	end
	table.sort(humans, function(a, b)
		return a.UserId < b.UserId
	end)
	while #humans > Race.MaxRunners do
		table.remove(humans)
	end

	local speeds = {}
	for _, player in humans do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum then
			local stationId, slot = TrainingService.current(player)
			if stationId then
				TrainingService.leave(player)
			end
			local r = {
				id = "p" .. player.UserId,
				name = player.DisplayName,
				player = player,
				userId = player.UserId,
				model = char,
				root = root,
				hum = hum,
				speed = PlayerData.get(player).Speed,
				returnCFrame = root.CFrame,
				returnSlot = slot,
			}
			table.insert(runners, r)
			runnerByPlayer[player] = r
			table.insert(speeds, r.speed)
			player:SetAttribute("InRace", true)
		end
	end
	if #runners == 0 then
		return false
	end

	-- NPCs fill up to MinRunners, at speeds around the joined players' middle speed
	table.sort(speeds)
	local mid = math.max(Race.NpcMinSpeed, speeds[math.ceil(#speeds / 2)])
	local npcCount = math.max(0, Race.MinRunners - #runners)
	local used = {}
	for n = 1, npcCount do
		local idx
		repeat
			idx = math.random(1, #Race.NpcNames)
		until not used[idx]
		used[idx] = true
		local model = getNpc(idx)
		if model then
			local lo, hi = Race.NpcSpeedRange[1], Race.NpcSpeedRange[2]
			model.Parent = workspace.Runtime
			table.insert(runners, {
				id = "n" .. idx,
				name = Race.NpcNames[idx],
				npc = true,
				model = model,
				root = model.PrimaryPart,
				hum = model:FindFirstChildOfClass("Humanoid"),
				speed = mid * (lo + (hi - lo) * math.random()),
				nextBoostAt = 2 + math.random() * 3,
			})
		end
	end

	for i, r in runners do
		r.lane = LANE_ORDER[i] or i
		r.laps = laps
		r.progress = 0
		r.finished = false
		r.charges = Race.Boost.Charges
		r.chargeAt = 0
		r.boostUntil = 0
		r.lastBoost = 0
		r.root.Anchored = true
		placeRunner(r, 0)
	end
	return true
end

local function rosterForClients(raceType)
	local list = {}
	for i, r in runners do
		list[i] = {
			id = r.id,
			name = r.name,
			lane = r.lane,
			userId = r.userId,
			npc = r.npc == true,
			model = r.model,
		}
	end
	return {
		raceId = raceId,
		type = raceType,
		name = Race.Types[raceType].Name,
		laps = Race.Types[raceType].Laps,
		runners = list,
	}
end

local function simulate(raceType)
	local laps = Race.Types[raceType].Laps
	local length = TrackPath.raceLength(laps)
	local startT = os.clock()
	raceStartClock = startT
	local lastTick = 0
	local packed = table.create(#runners, 0)

	while true do
		local dt = task.wait()
		local t = os.clock() - startT
		local allDone = true

		for _, r in runners do
			if r.finished then
				continue
			end
			if not (r.root and r.root.Parent) then
				r.finished = true
				r.dnf = true
				continue
			end
			allDone = false

			-- charges refill
			if r.charges < Race.Boost.Charges and t - r.chargeAt >= Race.Boost.RefillSeconds then
				r.charges += 1
				r.chargeAt = t
			end
			-- NPCs use their boosts too, at a calm rhythm
			if r.npc and t >= r.nextBoostAt and r.charges > 0 then
				r.charges -= 1
				if r.charges == Race.Boost.Charges - 1 then
					r.chargeAt = t
				end
				r.boostUntil = math.max(t, r.boostUntil) + Race.Boost.Seconds
				r.nextBoostAt = t + 1.5 + math.random() * 2.5
			end

			local pace = Formulas.pace(r.speed, 1)
			local mult = 1
			if t < r.boostUntil then
				mult += Race.Boost.Mult
			end
			-- slipstream: someone just ahead (within Distance studs)
			for _, o in runners do
				if o ~= r and not o.finished then
					local gap = (o.progress - r.progress) * length
					if gap > 0 and gap <= Race.Slipstream.Distance then
						mult += Race.Slipstream.Mult
						break
					end
				end
			end
			local before = r.progress
			r.progress += pace * mult * dt / length
			if r.progress >= 1 then
				-- exact crossing time inside this frame
				local frac = (1 - before) / (r.progress - before)
				r.finishTime = t - dt + dt * frac
				r.progress = 1
				r.finished = true
				stopRun(r)
			end
		end

		if t - lastTick >= 1 / Race.TickRate or allDone then
			lastTick = t
			for i, r in runners do
				packed[i] = r.progress
				placeRunner(r, r.progress)
			end
			RaceTick:FireAllClients(raceId, packed, t)
		end

		if allDone or t >= Race.MaxRaceSeconds then
			return t
		end
	end
end

local function standings()
	local list = table.clone(runners)
	table.sort(list, function(a, b)
		if a.finishTime and b.finishTime then
			return a.finishTime < b.finishTime
		elseif a.finishTime or b.finishTime then
			return a.finishTime ~= nil
		end
		return a.progress > b.progress
	end)
	return list
end

local function reward(raceType, list)
	local day = math.floor(os.time() / 86400)
	local rows = {}
	for place, r in list do
		rows[place] = { name = r.name, id = r.id, time = r.finishTime, npc = r.npc == true }
	end
	for place, r in list do
		local player = r.player
		local data = player and player.Parent and PlayerData.get(player)
		if not data then
			continue
		end
		local minutes = (Race.RewardMinutes[place] or 0) + Race.FinishMinutes
		local firstOfDay = data.LastRaceDay ~= day
		if firstOfDay then
			minutes *= 1 + Race.FirstRaceOfDayBonus
		end
		local coins = Formulas.minutesOfCoins(minutes, data.League)
		data.LastRaceDay = day
		data.Stats.Races += 1
		local medal = nil
		if place == 1 then
			data.Medals.Gold += 1
			data.Stats.Wins += 1
			medal = "Gold"
		elseif place == 2 then
			data.Medals.Silver += 1
			medal = "Silver"
		elseif place == 3 then
			data.Medals.Bronze += 1
			medal = "Bronze"
		end
		local pb = false
		if r.finishTime then
			local best = data.BestTimes[raceType]
			if best and r.finishTime < best then
				pb = true
			end
			if not best or r.finishTime < best then
				data.BestTimes[raceType] = r.finishTime
			end
		end
		PlayerData.set(player, "Coins", data.Coins + coins)
		PlayerData.refresh(player)
		RaceEvent:FireClient(player, "results", {
			raceId = raceId,
			place = place,
			total = #list,
			coins = coins,
			medal = medal,
			time = r.finishTime,
			pb = pb,
			firstOfDay = firstOfDay,
			rows = rows,
			youId = r.id,
		})
	end
end

local function cleanup()
	for _, r in runners do
		stopRun(r)
		if r.npc then
			r.model.Parent = npcPool
		elseif r.player then
			r.player:SetAttribute("InRace", nil)
			if r.root and r.root.Parent then
				r.root.Anchored = false
				r.root.CFrame = r.returnCFrame
				if r.returnSlot then
					TrainingService.enter(r.player, r.returnSlot)
				end
			end
		end
	end
	table.clear(runners)
	table.clear(runnerByPlayer)
	RaceEvent:FireAllClients("ended", { raceId = raceId })
end

local function waitUntil(t)
	while now() < t do
		if IS_STUDIO and workspace:GetAttribute("TestRaceNow") then
			workspace:SetAttribute("TestRaceNow", false)
			return
		end
		task.wait(0.25)
	end
end

local function interval()
	local test = IS_STUDIO and workspace:GetAttribute("TestRaceInterval")
	return if type(test) == "number" and test > 0 then test else Race.IntervalSeconds
end

local function runRace()
	rotation = rotation % #Race.Rotation + 1
	local raceType = Race.Rotation[rotation]
	raceId += 1
	state:SetAttribute("RaceId", raceId)
	state:SetAttribute("Type", raceType)
	state:SetAttribute("TypeName", Race.Types[raceType].Name)

	-- join window
	table.clear(joined)
	setPhase("Join", Race.JoinSeconds)
	task.wait(Race.JoinSeconds)

	if not next(joined) or not buildRunners(raceType) then
		table.clear(joined)
		return
	end
	table.clear(joined)

	RaceEvent:FireAllClients("start", rosterForClients(raceType))
	setPhase("Countdown", Race.CountdownSeconds)
	task.wait(Race.CountdownSeconds)

	setPhase("Running", Race.MaxRaceSeconds)
	for _, r in runners do
		playRun(r)
	end
	simulate(raceType)

	local list = standings()
	setPhase("Results", Race.ResultsSeconds)
	reward(raceType, list)
	task.wait(3)
	cleanup()
	task.wait(math.max(0, Race.ResultsSeconds - 3))
end

----------------------------------------------------------------------------
function RaceService.start()
	state = Instance.new("Folder")
	state.Name = "RaceState"
	state.Parent = ReplicatedStorage

	npcPool = Instance.new("Folder")
	npcPool.Name = "RaceNpcPool"
	npcPool.Parent = ServerStorage

	if not workspace:FindFirstChild("Runtime") then
		local f = Instance.new("Folder")
		f.Name = "Runtime"
		f.Parent = workspace
	end

	Net.get("RaceJoin").OnServerEvent:Connect(function(player)
		if state:GetAttribute("Phase") ~= "Join" or joined[player] then
			return
		end
		if not PlayerData.get(player) then
			return
		end
		local count = 0
		for _ in joined do
			count += 1
		end
		if count >= Race.MaxRunners then
			Toast:FireClient(player, "This race is full. Next one soon!", "Denied")
			return
		end
		joined[player] = true
		RaceEvent:FireClient(player, "joined", { raceId = raceId })
	end)

	Net.get("RaceBoost").OnServerEvent:Connect(function(player)
		local r = runnerByPlayer[player]
		if not r or r.finished or state:GetAttribute("Phase") ~= "Running" then
			return
		end
		local t = now()
		if t - r.lastBoost < 1 / Race.Boost.MaxTapsPerSecond then
			return
		end
		r.lastBoost = t
		if r.charges <= 0 then
			RaceEvent:FireClient(player, "boost", { charges = 0, ok = false })
			return
		end
		local raceT = os.clock() - raceStartClock -- boost times are in race seconds
		r.charges -= 1
		if r.charges == Race.Boost.Charges - 1 then
			r.chargeAt = raceT
		end
		r.boostUntil = math.max(raceT, r.boostUntil) + Race.Boost.Seconds
		RaceEvent:FireClient(player, "boost", { charges = r.charges, ok = true })
	end)

	Players.PlayerRemoving:Connect(function(player)
		joined[player] = nil
		local r = runnerByPlayer[player]
		if r then
			r.finished = true
			r.dnf = true
			runnerByPlayer[player] = nil
		end
	end)

	task.spawn(function()
		local nextAt = now() + Race.FirstRaceDelay
		state:SetAttribute("Phase", "Waiting")
		while true do
			state:SetAttribute("Phase", "Waiting")
			state:SetAttribute("EndsAt", nextAt)
			waitUntil(nextAt)
			local startedAt = now()
			local ok, err = pcall(runRace)
			if not ok then
				warn("[RaceService] race error:", err)
				pcall(cleanup)
			end
			nextAt = startedAt + interval()
			if nextAt < now() + 5 then
				nextAt = now() + 5
			end
		end
	end)
end

return RaceService
