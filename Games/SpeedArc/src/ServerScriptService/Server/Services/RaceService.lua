-- RaceService: every area runs its own race every 3 minutes, offset from the others (GDD 8, M3).
-- Server-authoritative: the server moves every runner; clients only send JOIN, BOOST and JUMP taps.
-- Hurdle races (League 3+) put hurdles across the lanes: a JUMP near one = clean, a miss = a short slowdown.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local Race = require(Shared.Config.Race)
local Areas = require(Shared.Config.Areas)
local Palette = require(Shared.Config.Palette)
local Formulas = require(Shared.Util.Formulas)
local Boosts = require(Shared.Util.Boosts)
local TrackPath = require(Shared.Util.TrackPath)
local Net = require(Shared.Util.Net)
local Retention = require(Shared.Config.Retention)
local PlayerData = require(script.Parent.PlayerData)
local TrainingService = require(script.Parent.TrainingService)

local RaceService = {}
RaceService.Won = Instance.new("BindableEvent") -- (player, area, place, info) info = { pb, time, raceType, kind }
RaceService.Joined = Instance.new("BindableEvent") -- (player, area) a scheduled race was joined
RaceService.Skipped = Instance.new("BindableEvent") -- (player, area) a JOIN window passed without joining

local IS_STUDIO = RunService:IsStudio()
local LANE_ORDER = { 3, 4, 2, 5, 1, 6, 7, 8 }

local RaceEvent = Net.get("RaceEvent")
local RaceTick = Net.get("RaceTick")
local Toast = Net.get("Toast")

local stateRoot
local areas = {} -- [areaId] = A
local playerRunner = {} -- [player] = { A = A, r = r }
local nextRaceId = 0

local function now()
	return workspace:GetServerTimeNow()
end

local function playersIn(A)
	if A.members then
		local list = {}
		for _, p in A.members do
			if p.Parent then
				table.insert(list, p)
			end
		end
		return list
	end
	local list = {}
	for _, p in Players:GetPlayers() do
		if (p:GetAttribute("Area") or "Hub") == A.area.Id then
			table.insert(list, p)
		end
	end
	return list
end

local function setPhase(A, phase, duration)
	A.state:SetAttribute("Phase", phase)
	A.state:SetAttribute("EndsAt", now() + (duration or 0))
end

----------------------------------------------------------------------------
-- NPC runners (original names), a small pool per area
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

local function makeNpc(A, i)
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
	model.Name = A.area.Id .. "_Runner_" .. Race.NpcNames[i]
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
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
	local head = model:FindFirstChild("Head")
	if head then
		local tag = Instance.new("BillboardGui")
		tag.Name = "NameTag"
		tag.Size = UDim2.fromOffset(120, 26)
		tag.StudsOffset = Vector3.new(0, 2.2, 0)
		tag.MaxDistance = 70
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
		label.Text = string.upper(Race.NpcNames[i])
		label.TextScaled = true
		label.TextColor3 = Palette.White
		local stroke = Instance.new("UIStroke")
		stroke.Color = Palette.SpeedBlack
		stroke.Thickness = 2
		stroke.Parent = label
		label.Parent = tag
		tag.Parent = head
	end
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart")
	model.PrimaryPart.Anchored = true
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Npc", true)
	model.Parent = A.npcPool
	return model
end

local function getNpc(A, i)
	if not A.npcs[i] then
		A.npcs[i] = makeNpc(A, i)
	end
	return A.npcs[i]
end

----------------------------------------------------------------------------
-- runners
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

local function placeRunner(A, r, progress)
	if r.root and r.root.Parent then
		r.root.CFrame = A.path.runnerCFrame(r.lane, progress, r.laps)
	end
end

local function buildRunners(A, raceType)
	local laps = Race.Types[raceType].Laps
	table.clear(A.runners)
	local humans = {}
	for player in A.joined do
		if player.Parent and PlayerData.get(player) and player.Character then
			table.insert(humans, player)
		end
	end
	table.sort(humans, function(a, b)
		return a.UserId < b.UserId
	end)
	local maxRunners = math.min(Race.MaxRunners, A.area.Track.Lanes)
	while #humans > maxRunners do
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
			local data = PlayerData.get(player)
			local r = {
				id = "p" .. player.UserId,
				name = player.DisplayName,
				player = player,
				userId = player.UserId,
				model = char,
				root = root,
				hum = hum,
				speed = data.Speed,
				paceMult = Boosts.compute(data).Pace, -- shoes + coaches (capped)
				returnCFrame = root.CFrame,
				returnSlot = slot,
			}
			table.insert(A.runners, r)
			playerRunner[player] = { A = A, r = r }
			table.insert(speeds, r.speed)
			player:SetAttribute("InRace", true)
		end
	end
	if #A.runners == 0 then
		return false
	end
	-- NPCs fill up to MinRunners, at speeds around the joined players' middle speed
	table.sort(speeds)
	local mid = math.max(if A.npcRange then 1 else Race.NpcMinSpeed, speeds[math.ceil(#speeds / 2)])
	local minRunners = Race.MinRunners
	local testRunners = IS_STUDIO and workspace:GetAttribute("TestRaceRunners") -- Studio: full 8-runner races
	if type(testRunners) == "number" then
		minRunners = testRunners
	end
	local npcCount = if A.npcCount then A.npcCount else math.max(0, math.min(minRunners, maxRunners) - #A.runners)
	local used = {}
	for _ = 1, npcCount do
		local idx
		repeat
			idx = math.random(1, #Race.NpcNames)
		until not used[idx]
		used[idx] = true
		local model = getNpc(A, idx)
		if model then
			local range = A.npcRange or Race.NpcSpeedRange
			local lo, hi = range[1], range[2]
			model.Parent = workspace.Runtime
			table.insert(A.runners, {
				id = "n" .. idx,
				name = Race.NpcNames[idx],
				npc = true,
				model = model,
				root = model.PrimaryPart,
				hum = model:FindFirstChildOfClass("Humanoid"),
				speed = mid * (lo + (hi - lo) * math.random()),
				paceMult = 1,
				nextBoostAt = 2 + math.random() * 3,
			})
		end
	end
	for i, r in A.runners do
		-- private races use the outside lanes so they don't sit on top of the area race
		r.lane = if A.members then math.max(1, A.area.Track.Lanes + 1 - i) else LANE_ORDER[i] or i
		r.laps = laps
		r.progress = 0
		r.finished = false
		r.charges = Race.Boost.Charges
		r.chargeAt = 0
		r.boostUntil = 0
		r.slowUntil = 0
		r.lastBoost = 0
		r.lastJump = -1
		r.nextHurdle = 1
		r.root.Anchored = true
		placeRunner(A, r, 0)
	end
	return true
end

----------------------------------------------------------------------------
-- hurdles (shown only during hurdle races)
----------------------------------------------------------------------------
local function hurdleProgress(n)
	local list = {}
	for i = 1, n do
		list[i] = 0.08 + (i - 1) * (0.84 / math.max(1, n - 1))
	end
	return list
end

local function placeHurdles(A, list, laps)
	local folder = Instance.new("Folder")
	folder.Name = "RaceHurdles"
	for _, hp in list do
		for lane = 1, A.area.Track.Lanes do
			local cf = A.path.runnerCFrame(lane, hp, laps) * CFrame.new(0, -A.area.Track.HipY, 0)
			local bar = Instance.new("Part")
			bar.Name = "HurdleBar"
			bar.Anchored = true
			bar.CanCollide = false
			bar.CanQuery = false
			bar.CanTouch = false
			bar.CastShadow = false
			bar.Material = Enum.Material.SmoothPlastic
			bar.Color = Palette.White
			bar.Size = Vector3.new(A.area.Track.LaneWidth - 0.4, 0.35, 0.2)
			bar.CFrame = cf * CFrame.new(0, 2.6, 0)
			bar.Parent = folder
			local base = bar:Clone()
			base.Name = "HurdleBase"
			base.Color = Palette.SpeedBlack
			base.Size = Vector3.new(A.area.Track.LaneWidth - 0.6, 2.4, 0.12)
			base.Transparency = 0.0
			base.CFrame = cf * CFrame.new(0, 1.25, 0.05)
			base.Parent = folder
		end
	end
	folder.Parent = workspace.Runtime
	return folder
end

----------------------------------------------------------------------------
-- the race
----------------------------------------------------------------------------
local function rosterForClients(A, raceType, hurdles)
	local list = {}
	for i, r in A.runners do
		list[i] = { id = r.id, name = r.name, lane = r.lane, userId = r.userId, npc = r.npc == true, model = r.model, modelName = r.model and r.model.Name }
	end
	return { raceId = A.raceId, areaId = A.area.Id, private = A.members ~= nil, stateName = A.state.Name, kind = A.kind, type = raceType, name = Race.Types[raceType].Name, laps = Race.Types[raceType].Laps, runners = list, hurdles = hurdles, length = A.path.raceLength(Race.Types[raceType].Laps) }
end

local function simulate(A, raceType, hurdles)
	local laps = Race.Types[raceType].Laps
	local length = A.path.raceLength(laps)
	local H = Race.Hurdle
	local startT = os.clock()
	A.raceStartClock = startT
	local lastTick = 0
	local packed = table.create(#A.runners, 0)
	while true do
		local dt = task.wait()
		local t = os.clock() - startT
		local allDone = true
		for _, r in A.runners do
			if r.finished then
				continue
			end
			if not (r.root and r.root.Parent) then
				r.finished = true
				r.dnf = true
				continue
			end
			allDone = false
			if r.charges < Race.Boost.Charges and t - r.chargeAt >= Race.Boost.RefillSeconds then
				r.charges += 1
				r.chargeAt = t
			end
			if r.npc and t >= r.nextBoostAt and r.charges > 0 then
				r.charges -= 1
				if r.charges == Race.Boost.Charges - 1 then
					r.chargeAt = t
				end
				r.boostUntil = math.max(t, r.boostUntil) + Race.Boost.Seconds
				r.nextBoostAt = t + 1.5 + math.random() * 2.5
			end
			local pace = Formulas.pace(r.speed, A.area.League) * (r.paceMult or 1) * (A.paceMult or 1)
			local mult = 1
			if t < r.boostUntil then
				mult += Race.Boost.Mult
			end
			if t < r.slowUntil then
				mult *= H.MissMult
			end
			for _, o in A.runners do
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
			-- hurdles: decide just after each one
			if hurdles and r.nextHurdle <= #hurdles then
				local hp = hurdles[r.nextHurdle]
				if r.progress >= hp + H.LateWindow / length then
					local clean
					if r.npc then
						clean = math.random() < H.NpcCleanChance
					else
						clean = r.lastJump >= hp - H.Window / length and r.lastJump <= hp + H.LateWindow / length
					end
					if not clean then
						r.slowUntil = t + H.MissSeconds
					end
					if r.player then
						RaceEvent:FireClient(r.player, "hurdle", { clean = clean, index = r.nextHurdle })
					end
					r.nextHurdle += 1
				end
			end
			-- tutorial: a close race the new runner always wins (NPCs stay near, never ahead at the end)
			if A.rigFor and r.npc and not A.rigFor.finished then
				local me = A.rigFor.progress
				local ahead = if me < 0.75 then 0.025 else -0.004 * (r.rigIndex or 1)
				r.progress = math.clamp(r.progress, me - 0.05, me + ahead)
			end
			if r.progress >= 1 then
				local frac = (1 - before) / (r.progress - before)
				r.finishTime = t - dt + dt * frac
				r.progress = 1
				r.finished = true
				stopRun(r)
			end
		end
		if t - lastTick >= 1 / Race.TickRate or allDone then
			lastTick = t
			for i, r in A.runners do
				packed[i] = r.progress
				placeRunner(A, r, r.progress)
			end
			for _, p in playersIn(A) do
				RaceTick:FireClient(p, A.raceId, packed, t)
			end
		end
		if allDone or t >= Race.MaxRaceSeconds then
			return t
		end
	end
end

local function standings(A)
	local list = table.clone(A.runners)
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

local function reward(A, raceType, list)
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
		local firstOfDay = data.LastRaceDay ~= day and A.kind ~= "challenge"
		if firstOfDay then
			minutes *= 1 + Race.FirstRaceOfDayBonus
		end
		if A.kind == "challenge" then
			-- RACE THEM: coins only for the first few a day, no medals or league wins (no farming)
			local c = data.Challenge
			if c.Day ~= day then
				c.Day, c.Paid = day, 0
			end
			if c.Paid < Retention.Social.ChallengePaidPerDay then
				c.Paid += 1
				minutes = Retention.Social.ChallengeMinutes[place] or 0
			else
				minutes = 0
			end
			data.Stats.Challenges = (data.Stats.Challenges or 0) + 1
		end
		-- a lower league's area pays at that league's rate, and less (visiting friends is fine)
		local lower = A.area.League < (data.League or 1)
		local coins = Formulas.minutesOfCoins(minutes, if lower then A.area.League else data.League) * Boosts.compute(data).Coins
		if lower then
			coins *= Areas.LowerLeagueRewardMult
		end
		coins = math.floor(coins + 0.5)
		if A.kind ~= "challenge" then
			data.LastRaceDay = day
		end
		data.Stats.Races += 1
		if place <= 3 and A.kind ~= "challenge" then
			data.Stats.Podiums = (data.Stats.Podiums or 0) + 1
		end
		local medal = nil
		if A.kind == "challenge" then
			medal = nil
		elseif place == 1 then
			data.Medals.Gold += 1
			data.Stats.Wins += 1
			medal = "Gold"
			if not lower and A.kind ~= "tutorial" then -- the tutorial win doesn't count for Go Pro
				data.LeagueWins = (data.LeagueWins or 0) + 1
			end
		elseif place == 2 then
			data.Medals.Silver += 1
			medal = "Silver"
		elseif place == 3 then
			data.Medals.Bronze += 1
			medal = "Bronze"
		end
		local pb = false
		local key = A.area.Id .. "_" .. raceType
		if r.finishTime then
			local best = data.BestTimes[key]
			if best and r.finishTime < best then
				pb = true
				data.Stats.PBs = (data.Stats.PBs or 0) + 1
			end
			if not best or r.finishTime < best then
				data.BestTimes[key] = r.finishTime
			end
		end
		PlayerData.set(player, "Coins", data.Coins + coins)
		PlayerData.refresh(player)
		RaceService.Won:Fire(player, A.area, place, { pb = pb, time = r.finishTime, raceType = raceType, kind = A.kind or "race" })
		RaceEvent:FireClient(player, "results", {
			raceId = A.raceId,
			areaId = A.area.Id,
			place = place,
			total = #list,
			coins = coins,
			medal = medal,
			time = r.finishTime,
			pb = pb,
			firstOfDay = firstOfDay,
			lower = lower,
			rows = rows,
			youId = r.id,
			kind = A.kind,
			capped = A.kind == "challenge" and coins == 0,
		})
	end
end

local function cleanup(A)
	for _, r in A.runners do
		stopRun(r)
		if r.npc then
			if A.members then
				r.model:Destroy()
			else
				r.model.Parent = A.npcPool
			end
		elseif r.player then
			playerRunner[r.player] = nil
			r.player:SetAttribute("InRace", nil)
			if r.root and r.root.Parent then
				r.root.Anchored = false
				r.root.CFrame = r.returnCFrame
				if r.returnSlot then
					TrainingService.enter(r.player, r.returnSlot)
				end
				RaceEvent:FireClient(r.player, "return", { cframe = r.root.CFrame })
			end
		end
	end
	table.clear(A.runners)
	if A.hurdleFolder then
		A.hurdleFolder:Destroy()
		A.hurdleFolder = nil
	end
	if A.members then
		for _, p in playersIn(A) do
			RaceEvent:FireClient(p, "ended", { raceId = A.raceId, areaId = A.area.Id })
		end
		A.state:Destroy()
	else
		RaceEvent:FireAllClients("ended", { raceId = A.raceId, areaId = A.area.Id })
	end
end

local function waitUntil(A, t)
	while now() < t do
		if IS_STUDIO and (workspace:GetAttribute("TestRaceNow") == true or workspace:GetAttribute("TestRaceNow") == A.area.Id) then
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

local function runRace(A)
	A.rotation = A.rotation % #A.area.Types + 1
	local raceType = A.area.Types[A.rotation]
	local forced = IS_STUDIO and workspace:GetAttribute("TestRaceType")
	if type(forced) == "string" and Race.Types[forced] then
		raceType = forced
	end
	nextRaceId += 1
	A.raceId = nextRaceId
	A.state:SetAttribute("RaceId", A.raceId)
	A.state:SetAttribute("Type", raceType)
	A.state:SetAttribute("TypeName", Race.Types[raceType].Name)
	table.clear(A.joined)
	setPhase(A, "Join", Race.JoinSeconds)
	task.wait(Race.JoinSeconds)
	for _, p in playersIn(A) do
		if PlayerData.get(p) and not playerRunner[p] then
			if A.joined[p] then
				RaceService.Joined:Fire(p, A.area)
			else
				RaceService.Skipped:Fire(p, A.area)
			end
		end
	end
	if not next(A.joined) or not buildRunners(A, raceType) then
		table.clear(A.joined)
		return
	end
	table.clear(A.joined)
	local hurdles = nil
	local def = Race.Types[raceType]
	if def.Hurdles then
		hurdles = hurdleProgress(def.Hurdles)
		A.hurdleFolder = placeHurdles(A, hurdles, def.Laps)
	end
	RaceEvent:FireAllClients("start", rosterForClients(A, raceType, hurdles))
	setPhase(A, "Countdown", Race.CountdownSeconds)
	task.wait(Race.CountdownSeconds)
	setPhase(A, "Running", Race.MaxRaceSeconds)
	for _, r in A.runners do
		playRun(r)
	end
	simulate(A, raceType, hurdles)
	local list = standings(A)
	setPhase(A, "Results", Race.ResultsSeconds)
	reward(A, raceType, list)
	task.wait(3)
	cleanup(A)
	task.wait(math.max(0, Race.ResultsSeconds - 3))
end

local function startArea(area)
	local A = {
		area = area,
		path = TrackPath.for_(area.Track),
		state = Instance.new("Folder"),
		joined = {},
		runners = {},
		npcs = {},
		raceId = 0,
		rotation = 0,
		raceStartClock = 0,
	}
	A.state.Name = area.Id
	A.state:SetAttribute("League", area.League)
	A.state.Parent = stateRoot
	A.npcPool = Instance.new("Folder")
	A.npcPool.Name = area.Id .. "NpcPool"
	A.npcPool.Parent = ServerStorage
	areas[area.Id] = A
	task.spawn(function()
		local nextAt = now() + Race.FirstRaceDelay + (area.RaceOffset or 0)
		while true do
			A.state:SetAttribute("Phase", "Waiting")
			A.state:SetAttribute("EndsAt", nextAt)
			waitUntil(A, nextAt)
			local startedAt = now()
			local ok, err = pcall(runRace, A)
			if not ok then
				warn("[RaceService] race error in " .. area.Id .. ":", err)
				pcall(cleanup, A)
			end
			nextAt = startedAt + interval()
			if nextAt < now() + 5 then
				nextAt = now() + 5
			end
		end
	end)
end

----------------------------------------------------------------------------
function RaceService.start()
	stateRoot = Instance.new("Folder")
	stateRoot.Name = "RaceState"
	stateRoot.Parent = ReplicatedStorage
	if not workspace:FindFirstChild("Runtime") then
		local f = Instance.new("Folder")
		f.Name = "Runtime"
		f.Parent = workspace
	end

	Net.get("RaceJoin").OnServerEvent:Connect(function(player)
		local A = areas[player:GetAttribute("Area") or "Hub"]
		if not A or A.state:GetAttribute("Phase") ~= "Join" or A.joined[player] or playerRunner[player] or not PlayerData.get(player) then
			return
		end
		local count = 0
		for _ in A.joined do
			count += 1
		end
		if count >= math.min(Race.MaxRunners, A.area.Track.Lanes) then
			Toast:FireClient(player, "This race is full. Next one soon!", "Denied")
			return
		end
		A.joined[player] = true
		RaceEvent:FireClient(player, "joined", { raceId = A.raceId, areaId = A.area.Id })
	end)

	Net.get("RaceBoost").OnServerEvent:Connect(function(player, kind)
		local pr = playerRunner[player]
		if not pr then
			return
		end
		local A, r = pr.A, pr.r
		if r.finished or A.state:GetAttribute("Phase") ~= "Running" then
			return
		end
		local raceT = os.clock() - A.raceStartClock
		if kind == "jump" then
			r.lastJump = r.progress -- judged when the runner passes the hurdle
			return
		end
		if raceT - (r.lastBoostT or -10) < 1 / Race.Boost.MaxTapsPerSecond then
			return
		end
		r.lastBoostT = raceT
		if r.charges <= 0 then
			RaceEvent:FireClient(player, "boost", { charges = 0, ok = false })
			return
		end
		r.charges -= 1
		if r.charges == Race.Boost.Charges - 1 then
			r.chargeAt = raceT
		end
		r.boostUntil = math.max(raceT, r.boostUntil) + Race.Boost.Seconds
		local data = PlayerData.get(player)
		if data then
			data.Stats.Boosts = (data.Stats.Boosts or 0) + 1
		end
		RaceEvent:FireClient(player, "boost", { charges = r.charges, ok = true })
	end)

	Players.PlayerRemoving:Connect(function(player)
		for _, A in areas do
			A.joined[player] = nil
		end
		local pr = playerRunner[player]
		if pr then
			pr.r.finished = true
			pr.r.dnf = true
			playerRunner[player] = nil
		end
	end)

	for _, id in Areas.Order do
		startArea(Areas[id])
	end
end

-- A private race on the members' area track: the tutorial race (vs slow NPCs, a close win) or
-- RACE THEM (1v1 sprint). opts = { kind, raceType, npcs, npcRange, paceMult, rig }
function RaceService.private(members, opts)
	local first = members[1]
	local base = areas[first:GetAttribute("Area") or "Hub"]
	if not base then
		return false
	end
	for _, p in members do
		if playerRunner[p] or not p.Character or (p:GetAttribute("Area") or "Hub") ~= base.area.Id then
			return false
		end
	end
	nextRaceId += 1
	local A = {
		area = base.area,
		path = base.path,
		state = Instance.new("Folder"),
		joined = {},
		runners = {},
		npcs = {},
		raceId = nextRaceId,
		raceStartClock = 0,
		members = members,
		kind = opts.kind,
		npcCount = opts.npcs or 0,
		npcRange = opts.npcRange,
		paceMult = opts.paceMult,
		npcPool = Instance.new("Folder"),
	}
	A.state.Name = "Private" .. A.raceId
	A.state:SetAttribute("Private", true)
	A.state.Parent = stateRoot
	A.npcPool.Name = "PrivateNpcs" .. A.raceId
	A.npcPool.Parent = ServerStorage
	local raceType = opts.raceType or "Sprint"
	for _, p in members do
		A.joined[p] = true
	end
	if not buildRunners(A, raceType) then
		A.state:Destroy()
		A.npcPool:Destroy()
		return false
	end
	if opts.rig then
		local n = 0
		for _, r in A.runners do
			if r.player == first then
				A.rigFor = r
			elseif r.npc then
				n += 1
				r.rigIndex = n
			end
		end
	end
	task.spawn(function()
		local ok, err = pcall(function()
			for _, p in playersIn(A) do
				RaceEvent:FireClient(p, "start", rosterForClients(A, raceType, nil))
			end
			setPhase(A, "Countdown", Race.CountdownSeconds)
			task.wait(Race.CountdownSeconds)
			setPhase(A, "Running", Race.MaxRaceSeconds)
			for _, r in A.runners do
				playRun(r)
			end
			simulate(A, raceType, nil)
			local list = standings(A)
			setPhase(A, "Results", Race.ResultsSeconds)
			reward(A, raceType, list)
			task.wait(3)
		end)
		if not ok then
			warn("[RaceService] private race error:", err)
		end
		pcall(cleanup, A)
		A.npcPool:Destroy()
	end)
	return true
end

function RaceService.inRace(player)
	return playerRunner[player] ~= nil
end

return RaceService
