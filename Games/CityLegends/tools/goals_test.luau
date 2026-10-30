-- Lune test for the goals' numbers (Config.Goals): Legends Path, the daily streak, daily tasks.
--   lune run tools/goals_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local env = {
	Color3 = roblox.Color3,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	CFrame = roblox.CFrame,
	Enum = roblox.Enum,
	UDim2 = roblox.UDim2,
	Instance = roblox.Instance,
	os = os,
}
setmetatable(env, { __index = _G })
local function load(path: string): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local Config = load("src/shared/Config.lua")
env.require = function()
	return Config
end
local okCars, Cars = pcall(load, "src/shared/Cars.lua")

local fails = 0
local function check(ok: boolean, what: string)
	print((if ok then "ok   " else "FAIL ") .. what)
	if not ok then
		fails += 1
	end
end

local G = Config.Goals
local STATS = { miles = true, cuts = true, combo = true, races = true, gold = true, traps = true, trapgold = true, drifts = true, jumps = true, jobs = true, chips = true, customs = true, escapes = true, bank = true, house = true, pvp = true, pvpwins = true, level = true, cars = true, brands = true }

local ids, bad, cashUp = {}, {}, true
for i, g in G.Path do
	if ids[g.id] then
		table.insert(bad, "duplicate " .. g.id)
	end
	ids[g.id] = true
	if not STATS[g.stat] then
		table.insert(bad, g.id .. ": unknown stat " .. tostring(g.stat))
	end
	if not (g.need > 0 or g.need == -1) or g.cash <= 0 or g.xp < 0 or type(g.text) ~= "string" then
		table.insert(bad, g.id .. ": bad numbers")
	end
end
check(#bad == 0, "Legends Path: " .. #G.Path .. " goals, ids unique, stats known, numbers sane " .. table.concat(bad, "; "))
check(#G.Path >= 25, "Legends Path has 25+ goals")
-- the same stat's goals come in rising order (a later goal never easier than an earlier one)
local last = {}
local order = true
for _, g in G.Path do
	local n = if g.need < 0 then math.huge else g.need
	if last[g.stat] and n <= last[g.stat] then
		order = false
		print("   out of order: " .. g.id)
	end
	last[g.stat] = n
end
check(order, "goals on the same stat get harder down the path")
-- the first goals are quick (first minutes): small needs, early in the list
check(G.Path[1].stat == "miles" and G.Path[1].need <= 1 and G.Path[2].need <= 10, "the first goals take a minute or two")

check(#G.Streak == 6, "streak: 6 cash days, then the car on day 7")
local rising = true
for d = 2, #G.Streak do
	rising = rising and G.Streak[d] > G.Streak[d - 1]
end
check(rising, "streak cash rises every day (" .. table.concat(G.Streak, ", ") .. ")")
check(G.StreakGrace > G.StreakCooldown and G.StreakCooldown <= 24 * 3600, "streak: a claim every day, a missed day forgiven")

local tids, tbad = {}, {}
for _, t in G.Tasks do
	if tids[t.id] then
		table.insert(tbad, "duplicate " .. t.id)
	end
	tids[t.id] = true
	if not STATS[t.stat] or t.need <= 0 or t.cash <= 0 or not string.find(t.text, "%%d") then
		table.insert(tbad, t.id)
	end
end
check(#tbad == 0 and #G.Tasks >= G.TasksPerDay + 3, "daily tasks: " .. #G.Tasks .. " in the pool, all sane " .. table.concat(tbad, "; "))
check(Config.taskCash(6000, 1) == 6000 and Config.taskCash(6000, 200) == 18000, "task cash: x1 at level 1, at most x3")

if okCars and type(Cars) == "table" and Cars.List then
	local pool = 0
	for _, spec in Cars.List do
		if spec.Tier == "Mid" and spec.Price <= G.StreakCarMaxPrice then
			pool += 1
		end
	end
	check(pool >= 3, "day-7 cars to give: " .. pool .. " Mid cars at or under " .. G.StreakCarMaxPrice)
else
	print("skip day-7 car pool (Cars.lua did not load here)")
end

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("ALL OK")
