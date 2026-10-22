--[[
	Activities (server)
	Time-trial races, delivery jobs and Legends chips (owner, 2026-10-22: "make the game way more
	fun with exciting things to do that involve driving and others"). The client drives them; the
	server keeps the clock, checks you're really where you say, pays and saves.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local A = Config.Activities

local Activities = {}

type Run = { kind: string, id: string?, t0: number, dest: number?, deadline: number?, dist: number?, cp: number }
local runs: { [Player]: Run } = {}
local ctx: any

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
	PlayerData.addCash(player, cash)
	ctx.grantXp(player, A.RaceXp[medal], "race")
	task.spawn(PlayerData.save, player)
	return { ok = true, time = t, medal = medal, cash = cash, best = if act then act.races[race.id] else t, newBest = newBest }
end

handlers.cancel = function(player)
	runs[player] = nil
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
	task.spawn(PlayerData.save, player)
	return { ok = true, cash = cash, count = count, total = #ActivityData.chips }
end

function Activities.init(c: any)
	ctx = c
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
	end)
end

return Activities
