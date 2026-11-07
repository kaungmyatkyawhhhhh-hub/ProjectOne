-- Lune: a normal player's money over time (2026-11-07, Prompts/Real car prices and harder cash.md).
-- The mix below is a player who isn't grinding: an hour of driving about with some races, jobs and stunts,
-- 1.5 hours a day, spending nothing. It prints what each way of earning pays an hour and when the
-- targets are reached, and fails if one is more than 25% outside its range.
--   lune run tools/progression_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local env = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame, NumberRange = roblox.NumberRange, NumberSequence = roblox.NumberSequence, NumberSequenceKeypoint = roblox.NumberSequenceKeypoint, ColorSequence = roblox.ColorSequence, ColorSequenceKeypoint = roblox.ColorSequenceKeypoint }
local Config = load("src/shared/Config.lua", env)
local E, A, Ch, R, G, P, B = Config.Economy, Config.Activities, Config.Challenges, Config.Rewards, Config.Goals, Config.Progression, Config.Bank

-- a normal hour
local MIX = {
	driveSeconds = 1800, mph = 80,
	cuts = 150, comboAvg = 3, closeness = 0.5,
	races = 2, jobs = 2, jobStuds = 1500, jobLeft = 20,
	drifts = 4, driftPoints = 2500,
	jumps = 4, jumpAir = 2, jumpStuds = 150,
	heists = 0.4, heistShare = 0.7,
	escapes = 0.5,
}
local HOURS_A_DAY = 1.5

local cut = E.CutBase * (0.6 + 0.8 * MIX.closeness) * (MIX.mph / 100) * (1 + E.ComboStep * (MIX.comboAvg - 1))
local jobCash = MIX.jobStuds * A.JobPayPerStud + MIX.jobLeft * A.JobTimeBonus
local RATES = {
	{ "driving", MIX.driveSeconds * MIX.mph * E.DrivePerSecond },
	{ "cut-ups", MIX.cuts * cut },
	{ "races (silver)", MIX.races * A.RaceRewards.Silver },
	{ "delivery jobs", MIX.jobs * jobCash },
	{ "drift", MIX.drifts * MIX.driftPoints * Ch.DriftCashPerPoint },
	{ "jumps", MIX.jumps * (MIX.jumpAir * Ch.StuntCashPerSecond + MIX.jumpStuds * Ch.StuntCashPerStud) },
	{ "bank heist", MIX.heists * B.MaxLoot * MIX.heistShare },
	{ "police escapes", MIX.escapes * Config.Police.EscapeBounty[2] },
}
local active = 0
print("a normal hour:")
for _, r in RATES do
	active += r[2]
	print(string.format("  %-16s $%d", r[1], r[2]))
end
print(string.format("  %-16s $%d", "active total", active))

local function wheelValue(wheel: any): number
	local v = 0
	for _, p in wheel.prizes do
		v += (p.cash or p.flexCash or p.carCash or 0) * p.weight / 100
	end
	return v * wheel.reels
end
local wheelDay, wheelWeek = wheelValue(R.Wheels.wheel), wheelValue(R.Wheels.super)
print(string.format("a free SPIN is worth $%d, a free SUPER SPIN $%d", wheelDay, wheelWeek))

-- one minute at a time
local cash, level, xp = Config.Economy.StartingCash, 1, 0
local stats = { miles = 0, cuts = 0, races = 0, jobs = 0, drifts = 0, jumps = 0, combo = 0, level = 1, traps = 0, trapgold = 0, gold = 0, bank = 0, escapes = 0, customs = 0, chips = 0, cars = 1 }
local goalDone = {}
local minute, dayMinute, day = 0, 0, 1
local TARGETS = {
	{ "first car, $30K", 30000, 0.5, 1 },
	{ "a good Mid car, $100K", 100000, 3, 5 },
	{ "a top Mid car, $250K", 250000, 8, 12 },
	{ "a first High car, $500K", 500000, 15, 25 },
	{ "a $1M car", 1000000, 35, 60 },
	{ "a $3M hypercar", 3000000, 100, 150 },
}
local reached = {}
local partAt: number? = nil
local function gift(n: number)
	cash += n
end
local dayStart = true
local xpHour = MIX.driveSeconds * MIX.mph * P.DriveXpPerSecond + MIX.cuts * math.min(cut * P.CutXpPerCash, P.CutXpMax) + MIX.races * A.RaceXp.Silver + MIX.jobs * 80 + 200
while minute < 200 * 60 and #reached < #TARGETS do
	if dayStart then
		dayStart = false
		local streakDay = (day - 1) % 7 + 1
		gift(G.Streak[streakDay] or 0)
		gift(wheelDay)
		if (day - 1) % 7 == 0 and day > 1 then
			gift(R.Weekly)
			gift(wheelWeek)
		end
		local boost = math.min(3, 1 + G.TaskLevelBoost * (level - 1))
		gift(math.floor(3 * G.Tasks[1].cash * boost))
	end
	minute += 1
	dayMinute += 1
	for _, p in R.Playtime do
		if dayMinute == p.minutes then
			gift(p.cash)
		end
	end
	cash += active / 60
	xp += xpHour / 60
	stats.miles += MIX.driveSeconds * MIX.mph / 3600 / 60
	stats.cuts += MIX.cuts / 60
	stats.races += MIX.races / 60
	stats.jobs += MIX.jobs / 60
	stats.drifts += MIX.drifts / 60
	stats.jumps += MIX.jumps / 60
	stats.traps += 4 / 60
	stats.gold += 0.5 / 60
	stats.chips += 1 / 60
	stats.escapes += MIX.escapes / 60
	stats.combo = if minute > 30 then 12 elseif minute > 8 then 5 else 0
	stats.customs = if minute > 40 then 1 else 0
	while xp >= Config.xpForLevel(level) do
		xp -= Config.xpForLevel(level)
		level += 1
		gift(Config.levelReward(level) + R.LevelCash * level + (if level % R.ChestEvery == 0 then R.ChestCash * level else 0))
	end
	stats.level = level
	for _, g in G.Path do
		if not goalDone[g.id] and stats[g.stat] and g.need > 0 and stats[g.stat] >= g.need then
			goalDone[g.id] = true
			cash += g.cash
		end
	end
	if not partAt and cash >= 750 and minute >= 1 then
		partAt = minute
	end
	for i, t in TARGETS do
		if not reached[i] and cash >= t[2] then
			reached[i] = minute / 60
		end
	end
	if dayMinute >= HOURS_A_DAY * 60 then
		dayMinute = 0
		day += 1
		dayStart = true
	end
end

local fails = 0
print(string.format("level at the end: %d after %.0f hours, day %d", level, minute / 60, day))
print(string.format("a first part ($750): minute %d", partAt or -1))
for i, t in TARGETS do
	local at = reached[i]
	local ok = at ~= nil and at >= t[3] * 0.75 and at <= t[4] * 1.25
	print(string.format("%-3s %-26s target %g-%g h, here %.1f h", if ok then "ok" else "FAIL", t[1], t[3], t[4], at or -1))
	if not ok then
		fails += 1
	end
end
print(if fails == 0 then "ALL OK" else fails .. " FAILED")
