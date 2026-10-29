-- Lune test for the lane graph (src/shared/CityLayout.lua): every lane leads somewhere, pieces
-- join up end to end, and you can drive from the city to Downtown, the islands and back
--   lune run tools/graph_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
local env = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame, math = math, string = string, table = table, print = print, warn = warn, error = error }
local modules = {}
local function load(name: string): any
	if modules[name] then
		return modules[name]
	end
	local src = fs.readFile(root .. "/src/shared/" .. name .. ".lua")
	local e = table.clone(env)
	e.script = { Parent = setmetatable({}, { __index = function(_, k)
		return { name = k }
	end }) }
	e.require = function(x)
		return load(x.name)
	end
	modules[name] = luau.load(src, { debugName = name, environment = e })()
	return modules[name]
end

local CityLayout = load("CityLayout")
local WestLayout = load("WestLayout")
local graph = CityLayout.buildGraph()

local fails = 0
local function check(cond, msg)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

-- every segment leads on, and its next ones start where it ends
local dead, gaps, worst = 0, 0, 0
for _, seg in graph.all do
	if #seg.next == 0 then
		dead += 1
		if dead <= 5 then
			print("  dead end at", seg.p2, "dir", seg.dir)
		end
	end
	for _, n in seg.next do
		local d = (n.p0 - seg.p2).Magnitude
		worst = math.max(worst, d)
		if d > 1 then
			gaps += 1
			if gaps <= 5 then
				print("  gap", d, "from", seg.p2, "to", n.p0, "dirs", seg.dir, n.dir)
			end
		end
	end
end
check(dead == 0, `no dead ends ({dead})`)
local jumps = 0
for _, seg in graph.all do
	if seg.kind == "turn" and math.abs(seg.p0.Y - seg.p2.Y) > 1 then
		jumps += 1
		print("  turn jumps", seg.p0, seg.p2)
	end
end
check(jumps == 0, `turns stay level ({jumps})`)
check(gaps == 0, `pieces join up (worst gap {math.floor(worst * 100) / 100})`)

-- reachability between the places
local function nearest(p)
	local best, bd = nil, math.huge
	for _, seg in graph.lanes do
		local ab = seg.p2 - seg.p0
		local t = math.clamp((p - seg.p0):Dot(ab) / ab:Dot(ab), 0, 1)
		local d = (seg.p0 + ab * t - p).Magnitude
		if d < bd then
			best, bd = seg, d
		end
	end
	return best, bd
end
local function reach(from)
	local seen = { [from] = true }
	local q = { from }
	local k = 1
	while k <= #q do
		local s = q[k]
		k += 1
		for _, n in s.next do
			if not seen[n] then
				seen[n] = true
				table.insert(q, n)
			end
		end
	end
	return seen
end
local places = WestLayout.places()
local city = nearest(places[1].cf.Position)
local fromCity = reach(city)
for _, pl in places do
	local seg, d = nearest(pl.cf.Position)
	check(d < 120, `{pl.name}: a lane nearby ({math.floor(d)})`)
	check(fromCity[seg] == true, `{pl.name}: reachable from the city`)
	check(reach(seg)[city] == true, `{pl.name}: back to the city`)
end

-- heights: the bridge deck and the viaduct are up, Downtown is on the ground
-- heights: off the island the bridge deck is the highest; on it the summit's ring
local IsleLayout = load("IsleLayout")
local isleX = load("Config").West.Isle.x + load("Config").West.Isle.r
local maxY, isleMax = 0, 0
for _, seg in graph.all do
	if seg.p0.X < isleX and seg.p2.X < isleX then
		isleMax = math.max(isleMax, seg.p0.Y, seg.p2.Y)
	else
		maxY = math.max(maxY, seg.p0.Y, seg.p2.Y)
	end
end
check(maxY > 39 and maxY < 41, `highest lane off the island is the bridge deck ({maxY})`)
check(math.abs(isleMax - load("Config").West.Isle.Top.y) < 1, `the island's highest lane is the summit ring ({isleMax})`)
local grade = IsleLayout.maxGrade()
check(grade <= 0.12, `the island's climbs are drivable (steepest {math.floor(grade * 1000) / 10}%)`)
-- the gated community: private lanes, and traffic can always go on somewhere public
local private, trapped = 0, 0
for _, seg in graph.all do
	if seg.private then
		private += 1
	elseif seg.kind ~= "turn" then
		local public = false
		for _, n in seg.next do
			if not n.private then
				public = true
			end
		end
		if not public then
			trapped += 1
		end
	end
end
check(private > 20, `the gated community's lanes are private ({private})`)
check(trapped == 0, `public lanes always lead on somewhere public ({trapped})`)
check(#WestLayout.housePlots() > 15, `house plots ({#WestLayout.housePlots()})`)
print(`{#graph.all} segments, {#graph.lanes} lanes`)
if fails > 0 then
	print(`{fails} FAILED`)
	process.exit(1)
end
print("ALL OK")
