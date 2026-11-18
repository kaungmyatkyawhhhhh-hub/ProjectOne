-- Lune test for the jobs' numbers and sums (Config.Jobs, shared/JobRules.lua).
--   lune run tools/jobs_test.luau <path to Games/CityLegends>
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
local R = load("src/shared/JobRules.lua")
local J = Config.Jobs

local fails = 0
local function check(ok: boolean, what: string)
	print((if ok then "ok   " else "FAIL ") .. what)
	if not ok then
		fails += 1
	end
end

-- the table itself
local ids, bad = {}, {}
for _, job in J.List do
	if ids[job.id] then
		table.insert(bad, "duplicate " .. job.id)
	end
	ids[job.id] = true
	if #job.ranks ~= #J.RankXp or #job.ranks ~= #J.RankMult then
		table.insert(bad, job.id .. ": rank count")
	end
	if job.kind == "post" and typeof(job.post) ~= "Vector3" then
		table.insert(bad, job.id .. ": no post")
	end
	if job.kind ~= "post" and job.kind ~= "active" then
		table.insert(bad, job.id .. ": kind")
	end
end
check(#bad == 0 and #J.List == 8, "8 jobs, 5 ranks each, posts placed " .. table.concat(bad, "; "))
for i = 2, #J.RankXp do
	check(J.RankXp[i] > J.RankXp[i - 1] and J.RankMult[i] > J.RankMult[i - 1], "rank " .. i .. " needs more XP and pays more")
end

-- ranks
local r, into, span = R.rank(J, 0)
check(r == 1 and into == 0 and span == J.RankXp[2], "0 XP: rank 1")
r = R.rank(J, J.RankXp[2] - 0.01)
check(r == 1, "just under rank 2's XP: still rank 1")
r, into = R.rank(J, J.RankXp[3] + 10)
check(r == 3 and into == 10, "rank 3 + 10 XP")
r, into, span = R.rank(J, 1e9)
check(r == 5 and span == 0, "top rank: nothing more to reach")

-- pay
local taxi, bus, police, tea = R.byId(J, "taxi"), R.byId(J, "bus"), R.byId(J, "police"), R.byId(J, "tea")
check(R.paycheck(J, tea, 1) == 200 and R.paycheck(J, tea, 1, true) == 400, "post paycheck 200, Double Pay 400")
check(R.paycheck(J, tea, 5) == math.floor(200 * J.RankMult[3] + 0.5) and R.paycheck(J, tea, 3) == R.paycheck(J, tea, 5), "a post's pay stops rising after rank 3 (19 Nov)")
check(R.paycheck(J, taxi, 5) == math.floor(taxi.paycheck * J.RankMult[5] + 0.5), "a field job's rank 5 paycheck uses RankMult")
check(R.taskPay(J, bus, 1, -50) == bus.base, "a negative leg pays just the base")

-- per-minute targets at rank 1 (design: active about 600 a minute, posts about 200, 17 Nov note)
-- a car averaging 70 studs/s between stops, stopping 4 s at each
local function perMinute(job: any, leg: number, extra: number): number
	local secs = leg / 70 + 4 + extra
	return R.taskPay(J, job, 1, leg) * 60 / secs + R.paycheck(J, job, 1)
end
local busMin = perMinute(bus, 1400, 0)
local policeMin = perMinute(police, 1100, J.RadarSeconds)
-- taxi: drive to the pickup (unpaid) then the fare
local taxiMin = R.taskPay(J, taxi, 1, 1500) * 60 / (800 / 70 + 1500 / 70 + 8) + R.paycheck(J, taxi, 1)
print(string.format("     rank 1 per minute: bus %d, police %d, taxi %d, post %d", busMin, policeMin, taxiMin, R.paycheck(J, tea, 1)))
for name, v in { bus = busMin, police = policeMin, taxi = taxiMin } do
	check(v >= 450 and v <= 850, name .. ": about 600 a minute at rank 1")
end
check(R.paycheck(J, tea, 1) * 3 <= busMin * 1.4 and R.paycheck(J, tea, 1) * 2.5 >= busMin * 0.6, "posts pay about a third of active")
check(perMinute(bus, 1400, 0) * J.RankMult[5] * 60 >= 80000, "rank 5 active about 100k an hour")

-- anti-teleport (19 Nov: posts have no daily cap any more: JobsData's shift check)
check(R.minLegSeconds(J, 3000) == 3000 / J.MaxSps, "a 3000-stud leg can't take under 10 s")

-- the bus line: every leg a real drive (not two stops on top of each other)
local short = 0
for i, s in J.BusStops do
	local n = J.BusStops[i % #J.BusStops + 1]
	local d = Vector3.new(s.pos.X - n.pos.X, 0, s.pos.Z - n.pos.Z).Magnitude
	if d < 300 then
		short += 1
	end
end
check(#J.BusStops >= 5 and short == 0, #J.BusStops .. " bus stops, every leg 300+ studs")

-- the Goals hook
local hasTask = false
for _, t in Config.Goals.Tasks do
	hasTask = hasTask or t.stat == "paychecks"
end
check(hasTask, "a daily task counts job paychecks")

print(if fails == 0 then "ALL OK" else fails .. " FAILED")
process.exit(if fails == 0 then 0 else 1)
