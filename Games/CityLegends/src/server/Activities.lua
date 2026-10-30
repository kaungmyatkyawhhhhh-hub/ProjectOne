--[[
	Activities (server)
	Time-trial races, delivery jobs and Legends chips (owner, 2026-10-22: "make the game way more
	fun with exciting things to do that involve driving and others"). The client drives them; the
	server keeps the clock, checks you're really where you say, pays and saves.
	Racing other players (owner, 2026-10-30, Config.Activities): race lobbies at the race rings
	(several players start together and share a pot by place) and duels (challenge a driver next
	to you to a sprint across town). RacePush tells clients about lobbies, starts and results.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local A = Config.Activities

local Activities = {}

type Run = { kind: string, id: string?, t0: number, dest: number?, deadline: number?, dist: number?, cp: number, lobby: string? }
local runs: { [Player]: Run } = {}
local ctx: any
local Push: RemoteEvent? = nil

-- a race ring's lobby: players waiting, then racing together
type Lobby = { id: string, players: { Player }, startAt: number, racing: boolean, racers: number, finished: number, t0: number, friends: { [Player]: boolean } }
local lobbies: { [string]: Lobby } = {}
-- duels: two players racing to one junction
type Duel = { a: Player, b: Player, finish: Vector3, t0: number, winner: Player? }
local duels: { [Player]: Duel } = {}
local pending: { [Player]: { from: Player, at: number } } = {}
local lastAsk: { [Player]: number } = {}

local function where(player: Player): Vector3?
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		return hrp.Position
	end
	local car = ctx.getCar(player)
	return if car and car.PrimaryPart then car.PrimaryPart.Position else nil
end

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function data(player: Player): { [string]: any }?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	local act = (profile :: any).Activities
	if type(act) ~= "table" then
		act = {}
		;(profile :: any).Activities = act
	end
	if type(act.races) ~= "table" then
		act.races = {}
	end
	if type(act.chips) ~= "table" then
		act.chips = {}
	end
	return act
end

local function snapshot(player: Player): { [string]: any }
	local act = data(player) or { races = {}, chips = {} }
	local chips = {}
	for k in act.chips do
		local n = tonumber(k)
		if n then
			table.insert(chips, n)
		end
	end
	return { races = act.races, chips = chips }
end

local handlers: { [string]: (Player, any) -> any } = {}

handlers.state = function(player)
	return snapshot(player)
end

handlers.raceStart = function(player, id)
	local race = if type(id) == "string" then ActivityData.raceById[id] else nil
	local car = ctx.getCar(player)
	if not race or not car or player.Character then
		return { ok = false }
	end
	local pos = car.PrimaryPart and car.PrimaryPart.Position
	if not pos or flatDist(pos, race.start) > 45 then
		return { ok = false, message = "Drive to the start line" }
	end
	runs[player] = { kind = "race", id = race.id, t0 = os.clock(), cp = 0 }
	return { ok = true }
end

handlers.raceFinish = function(player, clientTime)
	local run = runs[player]
	if not run or run.kind ~= "race" or not run.id then
		return { ok = false }
	end
	runs[player] = nil
	local race = ActivityData.raceById[run.id]
	local pos = where(player)
	if not pos or flatDist(pos, race.checkpoints[#race.checkpoints]) > A.CheckpointRadius * 2.5 then
		return { ok = false, message = "Not at the finish" }
	end
	local elapsed = os.clock() - run.t0
	-- the client's own clock is fairer (no network delay) but never faster than the server's by
	-- more than a moment, and nobody does the route at 260 mph
	local t = if type(clientTime) == "number" then math.clamp(clientTime, elapsed - 1.5, elapsed) else elapsed
	if t < race.length / Config.mphToSps(260) then
		return { ok = false, message = "Too fast" }
	end
	local medal = if t <= race.gold then "Gold" elseif t <= race.silver then "Silver" elseif t <= race.bronze then "Bronze" else "Finish"
	local act = data(player)
	local best = if act then act.races[race.id] else nil
	local newBest = type(best) ~= "number" or t < best
	if act and newBest then
		act.races[race.id] = math.floor(t * 100) / 100
	end
	local cash = A.RaceRewards[medal]
	ctx.grantXp(player, A.RaceXp[medal], "race")
	ctx.note(player, "races", 1)
	if medal == "Gold" then
		ctx.note(player, "gold", 1)
	end
	-- racing other players: the place, and its share of the pot
	local place, racers, pot = nil, 1, 0
	local l = if run.lobby then lobbies[run.lobby] else nil
	if l and l.racing then
		l.finished += 1
		place = l.finished
		racers = l.racers
		if racers >= 2 then
			local share = A.PotShares[math.min(place, #A.PotShares)]
			pot = math.floor(A.PotPerRacer * racers * share * (if l.friends[player] then A.FriendBonus else 1))
			ctx.note(player, "pvp", 1)
			if place == 1 then
				ctx.note(player, "pvpwins", 1)
			end
			for _, q in l.players do
				if q ~= player and q.Parent and Push then
					Push:FireClient(q, { kind = "finished", name = player.DisplayName, place = place })
				end
			end
		end
	end
	cash += pot
	PlayerData.addCash(player, cash)
	task.spawn(PlayerData.save, player)
	return { ok = true, time = t, medal = medal, cash = cash, best = if act then act.races[race.id] else t, newBest = newBest, place = place, racers = racers, pot = pot, friend = l ~= nil and l.friends[player] == true }
end

---------------------------------------------------------------------
-- Race lobbies
---------------------------------------------------------------------
local function lobbyList(): { [string]: any }
	local now = os.clock()
	local list = {}
	for id, l in lobbies do
		list[id] = { count = if l.racing then l.racers else #l.players, startsIn = math.max(0, l.startAt - now), racing = l.racing }
	end
	return list
end

local function broadcast()
	if Push then
		Push:FireAllClients({ kind = "lobbies", list = lobbyList() })
	end
end

local function leaveLobby(player: Player)
	for id, l in lobbies do
		if not l.racing then
			local k = table.find(l.players, player)
			if k then
				table.remove(l.players, k)
				if #l.players == 0 then
					lobbies[id] = nil
				end
				broadcast()
			end
		end
	end
end

handlers.raceJoin = function(player, id)
	local race = if type(id) == "string" then ActivityData.raceById[id] else nil
	local car = ctx.getCar(player)
	if not race or not car or player.Character or runs[player] then
		return { ok = false }
	end
	local pos = car.PrimaryPart and car.PrimaryPart.Position
	if not pos or flatDist(pos, race.start) > 45 then
		return { ok = false, message = "Drive into the race ring" }
	end
	local now = os.clock()
	local l = lobbies[race.id]
	if l and l.racing then
		return { ok = false, message = "A race is on here: wait for it to finish" }
	end
	if not l then
		l = { id = race.id, players = {}, startAt = now + A.LobbySeconds, racing = false, racers = 0, finished = 0, t0 = 0, friends = {} }
		lobbies[race.id] = l
	end
	if not table.find(l.players, player) then
		leaveLobby(player)
		table.insert(l.players, player)
		if #l.players >= A.LobbyMax then
			l.startAt = math.min(l.startAt, now + 2)
		end
	end
	broadcast()
	return { ok = true, startsIn = l.startAt - now, count = #l.players }
end

handlers.raceLeave = function(player)
	leaveLobby(player)
	return { ok = true }
end

-- a lobby whose time has come: everyone still in the ring races (3-2-1 on every screen at once)
local function startLobby(l: Lobby)
	local race = ActivityData.raceById[l.id]
	local racers = {}
	for _, p in l.players do
		local car = if p.Parent then ctx.getCar(p) else nil
		local pos = car and car.PrimaryPart and car.PrimaryPart.Position
		if pos and not p.Character and not runs[p] and flatDist(pos, race.start) <= 45 then
			table.insert(racers, p)
		end
	end
	if #racers == 0 then
		lobbies[l.id] = nil
		broadcast()
		return
	end
	l.racing = true
	l.players = racers
	l.racers = #racers
	l.t0 = os.clock() + 3
	for _, p in racers do
		runs[p] = { kind = "race", id = race.id, t0 = l.t0, cp = 0, lobby = l.id }
		if Push then
			Push:FireClient(p, { kind = "go", id = race.id, racers = #racers, t0in = 3 })
		end
	end
	broadcast()
	-- racing with a friend pays more (looked up after the start: it can take a moment)
	task.spawn(function()
		for _, p in racers do
			for _, q in racers do
				if p ~= q and not l.friends[p] then
					local ok, yes = pcall(function()
						return p:IsFriendsWith(q.UserId)
					end)
					if ok and yes then
						l.friends[p] = true
					end
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- Duels
---------------------------------------------------------------------
local function freeDriver(p: Player): Vector3?
	local car = if p.Parent then ctx.getCar(p) else nil
	if not car or p.Character or runs[p] or ((p:GetAttribute("Wanted") :: number?) or 0) > 0 then
		return nil
	end
	return car.PrimaryPart and car.PrimaryPart.Position
end

-- a junction of the city grid far enough away, but not too far
local function pickFinish(from: Vector3): Vector3?
	local options = {}
	for i = 0, Config.City.Blocks do
		for j = 0, Config.City.Blocks do
			local p = CityLayout.intersectionPos(i, j)
			local d = flatDist(p, from)
			if d >= A.DuelMinDist and d <= A.DuelMaxDist then
				table.insert(options, p)
			end
		end
	end
	if #options == 0 then
		return nil
	end
	return options[math.random(1, #options)]
end

handlers.duelAsk = function(player, uid)
	local target = if type(uid) == "number" then Players:GetPlayerByUserId(uid) else nil
	local now = os.clock()
	if not target or target == player then
		return { ok = false }
	end
	if lastAsk[player] and now - lastAsk[player] < 8 then
		return { ok = false, message = "Wait a moment before challenging again" }
	end
	local a, b = freeDriver(player), freeDriver(target)
	if not a or not b then
		return { ok = false, message = "You both need to be driving, free and clear of the police" }
	end
	if flatDist(a, b) > A.DuelRange then
		return { ok = false, message = "Get closer to them first" }
	end
	local p = pending[target]
	if p and now - p.at < A.DuelAskSeconds then
		return { ok = false, message = target.DisplayName .. " already has a challenge" }
	end
	lastAsk[player] = now
	pending[target] = { from = player, at = now }
	if Push then
		Push:FireClient(target, { kind = "duelAsk", from = player.DisplayName, fromId = player.UserId, seconds = A.DuelAskSeconds })
	end
	return { ok = true }
end

handlers.duelAnswer = function(player, yes)
	local p = pending[player]
	pending[player] = nil
	if not p or os.clock() - p.at > A.DuelAskSeconds + 1 then
		return { ok = false, message = "The challenge ran out" }
	end
	local from = p.from
	if yes ~= true then
		if Push and from.Parent then
			Push:FireClient(from, { kind = "duelNo", name = player.DisplayName })
		end
		return { ok = true }
	end
	local a, b = freeDriver(from), freeDriver(player)
	if not a or not b then
		return { ok = false, message = "The race can't start: one of you isn't free" }
	end
	local finish = pickFinish((a + b) / 2)
	if not finish then
		return { ok = false, message = "No finish line from here" }
	end
	local duel: Duel = { a = from, b = player, finish = finish, t0 = os.clock() + 3 }
	for _, q in { from, player } do
		duels[q] = duel
		runs[q] = { kind = "duel", t0 = duel.t0, cp = 0 }
		if Push then
			Push:FireClient(q, { kind = "duelGo", finish = finish, vs = (if q == from then player else from).DisplayName, t0in = 3 })
		end
	end
	return { ok = true }
end

handlers.duelFinish = function(player)
	local run = runs[player]
	local duel = duels[player]
	if not run or run.kind ~= "duel" or not duel then
		return { ok = false }
	end
	local pos = where(player)
	if not pos or flatDist(pos, duel.finish) > A.CheckpointRadius * 2 or os.clock() < duel.t0 + 5 then
		return { ok = false, message = "Not at the finish" }
	end
	runs[player] = nil
	duels[player] = nil
	ctx.note(player, "pvp", 1)
	local other = if duel.a == player then duel.b else duel.a
	if not duel.winner then
		duel.winner = player
		PlayerData.addCash(player, A.DuelPot)
		ctx.grantXp(player, 250, "duel")
		ctx.note(player, "pvpwins", 1)
		if Push and other.Parent then
			Push:FireClient(other, { kind = "duelLost", name = player.DisplayName })
		end
		return { ok = true, place = 1, cash = A.DuelPot, time = os.clock() - duel.t0 }
	end
	PlayerData.addCash(player, A.DuelSecondCash)
	ctx.grantXp(player, 80, "duel")
	return { ok = true, place = 2, cash = A.DuelSecondCash, time = os.clock() - duel.t0 }
end

handlers.cancel = function(player)
	runs[player] = nil
	duels[player] = nil
	leaveLobby(player)
	return { ok = true }
end

handlers.jobStart = function(player, which)
	local d = if type(which) == "number" then ActivityData.dispatch[which] else nil
	local car = ctx.getCar(player)
	if not d or not car or player.Character then
		return { ok = false }
	end
	local pos = car.PrimaryPart and car.PrimaryPart.Position
	if not pos or flatDist(pos, d.pos) > 40 then
		return { ok = false, message = "Drive to the dispatch point" }
	end
	local options = {}
	for k, p in ActivityData.dropPoints do
		if flatDist(p.pos, d.pos) >= A.JobMinDistance then
			table.insert(options, k)
		end
	end
	if #options == 0 then
		return { ok = false }
	end
	local dest = options[math.random(1, #options)]
	local dist = flatDist(ActivityData.dropPoints[dest].pos, d.pos)
	local limit = dist / Config.mphToSps(A.JobMph) + A.JobGrace
	runs[player] = { kind = "job", t0 = os.clock(), dest = dest, deadline = os.clock() + limit, dist = dist, cp = 0 }
	return { ok = true, dest = dest, limit = limit }
end

handlers.jobFinish = function(player)
	local run = runs[player]
	if not run or run.kind ~= "job" or not run.dest then
		return { ok = false }
	end
	local drop = ActivityData.dropPoints[run.dest]
	local pos = where(player)
	if not pos or flatDist(pos, drop.pos) > 40 then
		return { ok = false, message = "Not at the drop point" }
	end
	runs[player] = nil
	local now = os.clock()
	if now > (run.deadline :: number) + 1 then
		return { ok = true, late = true, cash = 0 }
	end
	local left = (run.deadline :: number) - now
	local cash = math.floor((run.dist :: number) * A.JobPayPerStud + math.max(0, left) * A.JobTimeBonus)
	PlayerData.addCash(player, cash)
	ctx.grantXp(player, 80, "job")
	ctx.note(player, "jobs", 1)
	return { ok = true, cash = cash, left = left }
end

handlers.chip = function(player, index)
	local k = tonumber(index)
	local pos = if k then ActivityData.chips[k] else nil
	local here = where(player)
	local act = data(player)
	if not (pos and here and act) or (pos - here).Magnitude > 16 then
		return { ok = false }
	end
	if act.chips[tostring(k)] then
		return { ok = false }
	end
	act.chips[tostring(k)] = true
	local count = 0
	for _ in act.chips do
		count += 1
	end
	local cash = A.ChipCash + (if count >= #ActivityData.chips then A.ChipAllBonus else 0)
	PlayerData.addCash(player, cash)
	ctx.note(player, "chips", 1)
	task.spawn(PlayerData.save, player)
	return { ok = true, cash = cash, count = count, total = #ActivityData.chips }
end

function Activities.init(c: any)
	ctx = c
	Push = ctx.remote("RemoteEvent", "RacePush")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "ActivityCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	Players.PlayerRemoving:Connect(function(player)
		runs[player] = nil
		duels[player] = nil
		pending[player] = nil
		lastAsk[player] = nil
		leaveLobby(player)
	end)
	Players.PlayerAdded:Connect(function(player)
		if Push then
			Push:FireClient(player, { kind = "lobbies", list = lobbyList() })
		end
	end)
	-- lobbies start, and finish when everyone's through (or time's up); duels time out
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local now = os.clock()
		for id, l in lobbies do
			local race = ActivityData.raceById[id]
			if not l.racing then
				if now >= l.startAt then
					startLobby(l)
				end
			else
				local still = 0
				for _, p in l.players do
					local r = runs[p]
					if r and r.lobby == id then
						still += 1
					end
				end
				if still == 0 or now > l.t0 + race.bronze * 3 + 10 then
					lobbies[id] = nil
					broadcast()
				end
			end
		end
		for p, duel in duels do
			if now > duel.t0 + A.DuelTimeout then
				duels[p] = nil
				if runs[p] and runs[p].kind == "duel" then
					runs[p] = nil
				end
				if Push and p.Parent then
					Push:FireClient(p, { kind = "duelEnd" })
				end
			end
		end
	end)
	-- the goals that need racing other players can show from now on
	if ctx.goals then
		ctx.goals.feature("pvp")
	end
end

return Activities
