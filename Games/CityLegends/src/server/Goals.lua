--[[
	Goals (owner, 2026-10-30, from the driving games research: Midnight Racing's milestones and
	daily rewards, Car Dealership Tycoon's daily tasks; Config.Goals)
	  * Legends Path: one-off goals; each pays the moment it's done, and the next one is on the HUD
	  * the daily streak (replaces the flat daily gift): day 1..6 cash, day 7 a free Mid car
	  * 3 daily tasks, new each day (UTC)
	The gameplay modules report what happened with ctx.note(player, stat, amount) (Goals.note);
	levels, owned cars and brands and houses are read from the profile. Saved as profile.Goals.
	Remotes: GoalsCall (state, claim the streak), GoalsPush (state updates and "done" moments).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local G = Config.Goals

local Goals = {}

type TaskState = { id: string, have: number, done: boolean }
type Data = {
	Done: { [string]: boolean },
	Stat: { [string]: number },
	Streak: { Day: number, Last: number },
	Tasks: { Date: string, List: { TaskState } },
}

local ctx: any = nil
local Push: RemoteEvent? = nil
local dirty: { [Player]: boolean } = {}
-- features that some goals need (race lobbies for "pvp"): goals needing one that isn't on are
-- skipped on the HUD and never dealt as a daily task
local features: { [string]: boolean } = {}
local NEEDS = { pvp = "pvp", pvpwins = "pvp" }

local TASK_BY_ID: { [string]: any } = {}
for _, t in G.Tasks do
	TASK_BY_ID[t.id] = t
end

local function today(): string
	return os.date("!%Y-%m-%d") :: string
end

local function secondsToNextDay(): number
	local t = os.date("!*t") :: any
	return (23 - t.hour) * 3600 + (59 - t.min) * 60 + (60 - t.sec)
end

local function data(profile: any): Data
	local g = profile.Goals
	if type(g) ~= "table" then
		g = {}
		profile.Goals = g
	end
	if type(g.Done) ~= "table" then
		g.Done = {}
	end
	if type(g.Stat) ~= "table" then
		g.Stat = {}
	end
	if type(g.Streak) ~= "table" then
		-- (an old save: its last daily gift starts the streak's clock, at day 0)
		g.Streak = { Day = 0, Last = tonumber(profile.LastDaily) or 0 }
	end
	g.Streak.Day = math.clamp(math.floor(tonumber(g.Streak.Day) or 0), 0, 7)
	g.Streak.Last = math.clamp(math.floor(tonumber(g.Streak.Last) or 0), 0, os.time())
	if type(g.Tasks) ~= "table" or type(g.Tasks.List) ~= "table" then
		g.Tasks = { Date = "", List = {} }
	end
	return g :: Data
end

local function available(stat: string): boolean
	local need = NEEDS[stat]
	return need == nil or features[need] == true
end

-- how far the player is on a stat
local function value(profile: any, g: Data, stat: string): number
	if stat == "level" then
		return profile.Level or 1
	elseif stat == "cars" then
		local n = 0
		for _ in profile.Owned do
			n += 1
		end
		return n
	elseif stat == "brands" then
		local set, n = {}, 0
		for id in profile.Owned do
			local at = Cars.SeriesOf[id]
			local brand = at and at.series.Brand
			if brand and not set[brand] then
				set[brand] = true
				n += 1
			end
		end
		return n
	elseif stat == "house" then
		local n = 0
		for _ in profile.Houses or {} do
			n += 1
		end
		return n
	end
	return g.Stat[stat] or 0
end

local function needOf(goal: any): number
	return if goal.need < 0 then #Cars.List else goal.need
end

-- today's tasks (dealt again when the UTC day changes; the same three for the whole day)
local function tasks(player: Player, g: Data): { TaskState }
	local date = today()
	if g.Tasks.Date ~= date then
		local pool = {}
		for _, t in G.Tasks do
			if available(t.stat) then
				table.insert(pool, t.id)
			end
		end
		local seed = 0
		for i = 1, #date do
			seed = (seed * 31 + string.byte(date, i)) % 2147483647
		end
		local rng = Random.new(seed + player.UserId % 100000)
		local list = {}
		for _ = 1, math.min(G.TasksPerDay, #pool) do
			local id = table.remove(pool, rng:NextInteger(1, #pool))
			table.insert(list, { id = id, have = 0, done = false })
		end
		g.Tasks = { Date = date, List = list }
	end
	return g.Tasks.List
end

local function pay(player: Player, cash: number, xp: number)
	if cash > 0 then
		PlayerData.addCash(player, cash)
	end
	if xp > 0 and ctx then
		ctx.grantXp(player, xp, "goal")
	end
end

-- pays every Legends Path goal and daily task that's done (one "done" message each)
local function check(player: Player)
	local profile = PlayerData.get(player) :: any
	if not profile or not profile.Loaded then
		return
	end
	local g = data(profile)
	local paid = false
	for _, goal in G.Path do
		if not g.Done[goal.id] and available(goal.stat) and value(profile, g, goal.stat) >= needOf(goal) then
			g.Done[goal.id] = true
			pay(player, goal.cash, goal.xp)
			paid = true
			if Push then
				Push:FireClient(player, { kind = "done", what = "path", text = goal.text, cash = goal.cash, xp = goal.xp })
			end
		end
	end
	for _, t in tasks(player, g) do
		local spec = TASK_BY_ID[t.id]
		if spec and not t.done and t.have >= spec.need then
			t.done = true
			local cash = Config.taskCash(spec.cash, profile.Level or 1)
			pay(player, cash, spec.xp)
			paid = true
			if Push then
				Push:FireClient(player, { kind = "done", what = "task", text = string.format(spec.text, spec.need), cash = cash, xp = spec.xp })
			end
		end
	end
	if paid then
		task.spawn(PlayerData.save, player)
	end
	dirty[player] = true
end

-- something happened: `stat` went up by `amount` (for "combo", the combo reached)
function Goals.note(player: Player, stat: string, amount: number?)
	local profile = PlayerData.get(player) :: any
	if not profile or not profile.Loaded then
		return
	end
	local n = amount or 1
	if type(n) ~= "number" or n ~= n or n <= 0 then
		return
	end
	local g = data(profile)
	if stat == "combo" then
		g.Stat.combo = math.max(g.Stat.combo or 0, n)
	else
		g.Stat[stat] = (g.Stat[stat] or 0) + n
	end
	for _, t in tasks(player, g) do
		local spec = TASK_BY_ID[t.id]
		if spec and spec.stat == stat and not t.done then
			t.have = if spec.best then math.max(t.have, n) else t.have + n
		end
	end
	check(player)
end

-- a goal needing this feature can be shown and dealt from now on
function Goals.feature(name: string)
	features[name] = true
end

---------------------------------------------------------------------
-- The daily streak
---------------------------------------------------------------------
-- (the day you'd claim next, seconds until you can)
function Goals.streak(player: Player): (number, number)
	local profile = PlayerData.get(player) :: any
	if not profile then
		return 1, G.StreakCooldown
	end
	local s = data(profile).Streak
	local now = os.time()
	if s.Last <= 0 or now - s.Last > G.StreakGrace then
		return 1, 0
	end
	return (s.Day % 7) + 1, math.max(0, s.Last + G.StreakCooldown - now)
end

-- the day-7 car: a Mid car from the dealer you don't own, at or under the price cap
local function streakCar(profile: any): string?
	local pick = {}
	for _, spec in Cars.List do
		if spec.Tier == "Mid" and spec.Price <= G.StreakCarMaxPrice and not profile.Owned[spec.Id] and not Cars.isMarketOnly(spec.Id) then
			table.insert(pick, spec.Id)
		end
	end
	if #pick == 0 then
		return nil
	end
	return pick[math.random(1, #pick)]
end

function Goals.claimStreak(player: Player): { [string]: any }
	local profile = PlayerData.get(player) :: any
	if not profile or not profile.Loaded then
		return { ok = false, message = "Your data is still loading" }
	end
	local day, readyIn = Goals.streak(player)
	if readyIn > 0 then
		return { ok = false, message = "Your next streak day isn't ready yet", readyIn = readyIn, day = day }
	end
	local g = data(profile)
	local result: { [string]: any } = { ok = true, day = day }
	if day <= #G.Streak then
		local cash = G.Streak[day]
		PlayerData.addCash(player, cash)
		result.amount = cash
	else
		local id = streakCar(profile)
		if id then
			profile.Owned[id] = true
			result.car = Cars.ById[id].Name
			result.carId = id
		else
			PlayerData.addCash(player, G.StreakCarCash)
			result.amount = G.StreakCarCash
		end
	end
	g.Streak.Day = day
	g.Streak.Last = os.time()
	profile.LastDaily = g.Streak.Last
	task.spawn(PlayerData.save, player)
	local nextDay, nextIn = Goals.streak(player)
	result.next = nextDay
	result.readyIn = nextIn
	dirty[player] = true
	return result
end

---------------------------------------------------------------------
-- What the client shows
---------------------------------------------------------------------
function Goals.state(player: Player): { [string]: any }?
	local profile = PlayerData.get(player) :: any
	if not profile or not profile.Loaded then
		return nil
	end
	local g = data(profile)
	local path, nextGoal, doneCount, total = {}, nil, 0, 0
	for _, goal in G.Path do
		if available(goal.stat) then
			total += 1
			local done = g.Done[goal.id] == true
			if done then
				doneCount += 1
			end
			local need = needOf(goal)
			local entry = { text = goal.text, need = need, have = math.min(need, value(profile, g, goal.stat)), cash = goal.cash, done = done }
			table.insert(path, entry)
			if not done and not nextGoal then
				nextGoal = entry
			end
		end
	end
	local list = {}
	for _, t in tasks(player, g) do
		local spec = TASK_BY_ID[t.id]
		if spec then
			table.insert(list, {
				text = string.format(spec.text, spec.need),
				have = math.min(spec.need, if spec.stat == "miles" then math.floor(t.have * 10) / 10 else t.have),
				need = spec.need,
				cash = Config.taskCash(spec.cash, profile.Level or 1),
				done = t.done,
			})
		end
	end
	local day, readyIn = Goals.streak(player)
	local rewards = {}
	for d = 1, 7 do
		rewards[d] = if d <= #G.Streak then G.Streak[d] else "car"
	end
	return {
		path = path,
		next = nextGoal,
		done = doneCount,
		total = total,
		tasks = list,
		tasksIn = secondsToNextDay(),
		streak = { day = day, readyIn = readyIn, rewards = rewards, last = data(profile).Streak.Day },
	}
end

function Goals.init(c: any)
	ctx = c
	Push = c.remote("RemoteEvent", "GoalsPush")
	local call: RemoteFunction = c.remote("RemoteFunction", "GoalsCall")
	call.OnServerInvoke = function(player: Player, what: any)
		if what == "state" then
			return Goals.state(player)
		elseif what == "streak" then
			return Goals.claimStreak(player)
		end
		return nil
	end
	-- levels, cars, brands and houses change in many places: look every few seconds; and send
	-- each player's new state at most twice a second
	task.spawn(function()
		local tick = 0
		while true do
			task.wait(0.5)
			tick += 1
			if tick % 10 == 0 then
				for _, p in Players:GetPlayers() do
					check(p)
				end
			end
			for p in dirty do
				dirty[p] = nil
				if p.Parent and Push then
					local st = Goals.state(p)
					if st then
						Push:FireClient(p, { kind = "state", state = st })
					end
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		dirty[p] = nil
	end)
end

return Goals
