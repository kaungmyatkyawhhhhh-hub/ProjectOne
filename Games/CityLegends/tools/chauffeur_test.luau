-- Lune test for src/shared/ChauffeurRoute.lua: routes over the real lane graph
--   lune run tools/chauffeur_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
local env = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, CFrame = roblox.CFrame, Enum = roblox.Enum }
local loaded = {}
local function load(name: string): any
	if loaded[name] then
		return loaded[name]
	end
	local src = fs.readFile(root .. "/src/shared/" .. name .. ".lua")
	local e = table.clone(env)
	e.script = { Parent = setmetatable({}, { __index = function(_, k) return { name = k } end }) }
	e.require = function(x) return load(x.name) end
	local m = luau.load(src, { debugName = name, environment = e })()
	loaded[name] = m
	return m
end

local Config = load("Config")
local CityLayout = load("CityLayout")
local WestLayout = load("WestLayout")
local Route = load("ChauffeurRoute")

local failures = 0
local function check(ok: boolean, msg: string)
	if not ok then
		failures += 1
		print("FAIL: " .. msg)
	end
end

local t0 = os.clock()
local g = Route.graph()
local nBeside = 0
for _ in g.lanesBeside do
	nBeside += 1
end
print(string.format("graph: %d segments, %d with a lane beside, %.2fs", #g.all, nBeside, os.clock() - t0))
check(nBeside > 100, "lane changes found")

-- a route's legs join up: the end of one is the start of the next (or a lane apart)
local function continuous(route): boolean
	for k = 2, #route.legs do
		local prev, leg = route.legs[k - 1], route.legs[k]
		local a = CityLayout.sample(prev.seg, prev.s1)
		local b = CityLayout.sample(leg.seg, leg.s0)
		local gap = (a - b).Magnitude
		if leg.shift then
			if gap > Config.City.LaneWidth * 1.7 then
				print("  lane change gap", gap)
				return false
			end
		elseif gap > 1 then
			print("  gap", gap, "between legs", k - 1, k)
			return false
		end
	end
	return true
end

-- every place: a road there (Downtown and the islands only once the west's lanes are in)
local reach = {}
for _, place in WestLayout.places() do
	local spot = Route.nearest(place.cf.Position, 45, place.cf.LookVector, true)
	reach[place.id] = spot
	print(string.format("  %-22s %s", place.name, if spot then string.format("lane %d dir %d, %.1f studs off", spot.seg.lane, spot.seg.dir, spot.dist) else "no road yet"))
end
check(reach.city ~= nil and reach.bank ~= nil, "city places on the graph")

-- routes between all reachable places
local tries, found, totalTime = 0, 0, 0
for _, a in WestLayout.places() do
	for _, b in WestLayout.places() do
		if a.id ~= b.id and reach[a.id] and reach[b.id] then
			tries += 1
			local t = os.clock()
			local route = Route.find(reach[a.id], reach[b.id])
			totalTime += os.clock() - t
			if route then
				found += 1
				check(continuous(route), "continuous " .. a.id .. " -> " .. b.id)
				local last = route.legs[#route.legs]
				local endPos = CityLayout.sample(last.seg, last.s1)
				check((endPos - CityLayout.sample(reach[b.id].seg, reach[b.id].s)).Magnitude < 2, "ends at " .. b.id)
				check(route.time > 0 and route.length > 0, "time and length " .. a.id .. " -> " .. b.id)
			else
				check(false, "route " .. a.id .. " -> " .. b.id)
			end
		end
	end
end
print(string.format("routes: %d / %d found, %.1f ms each", found, tries, totalTime / math.max(tries, 1) * 1000))

-- random lane spots across the graph (both lanes, city and highway)
local seed = 7
local rng = {
	NextInteger = function(_, a: number, b: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return a + seed % (b - a + 1)
	end,
	NextNumber = function(_, a: number, b: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return a + (seed / 2147483648) * (b - a)
	end,
}
local lanes = {}
for _, seg in g.all do
	-- (not the loop's outer ring: no ramp leaves it, ChauffeurRoute.connect steps round it)
	if seg.kind ~= "turn" and seg.dir ~= 12 then
		table.insert(lanes, seg)
	end
end
local rtries, rfound, rchanges = 0, 0, 0
local missing = {}
for _ = 1, 300 do
	local a = lanes[rng:NextInteger(1, #lanes)]
	local b = lanes[rng:NextInteger(1, #lanes)]
	local from = { seg = a, s = rng:NextNumber(0, a.length), dist = 0 }
	local to = { seg = b, s = rng:NextNumber(0, b.length), dist = 0 }
	if a ~= b then
		rtries += 1
		local route = Route.find(from, to)
		if not route then
			local key = a.dir .. ">" .. b.dir
			missing[key] = (missing[key] or 0) + 1
		end
		if route then
			rfound += 1
			check(continuous(route), "random route continuous")
			for _, leg in route.legs do
				if leg.shift then
					rchanges += 1
				end
			end
		end
	end
end
for k, n in missing do
	print("  no route", k, n)
end
print(string.format("random: %d / %d found, %d lane changes", rfound, rtries, rchanges))
check(rfound >= rtries * 0.97, "nearly every lane reaches every other")

-- a called car starts up the road and can drive to the pick-up
local spot = reach.city
local start = Route.backFrom(spot, Config.Chauffeur.ArriveFrom)
local approach = Route.find(start, spot)
check(approach ~= nil, "approach route")
if approach then
	print(string.format("approach: %.0f studs (asked %d)", approach.length, Config.Chauffeur.ArriveFrom))
	check(math.abs(approach.length - Config.Chauffeur.ArriveFrom) < 40, "approach about ArriveFrom long")
end

-- a pick-up by the loop's outer ring still finds a way into town
do
	local ring = nil
	for _, seg in g.all do
		if seg.dir == 12 and seg.kind == "lane" then
			ring = seg
			break
		end
	end
	local p = CityLayout.sample(ring, ring.length / 2)
	local a, b, route = Route.connect(Route.nearestList(p, 90, nil, true, 6), Route.nearestList(reach.city.seg.p0, 45, nil, true, 4))
	check(route ~= nil and a.seg.dir ~= 12, "from beside the outer ring")
	local _ = b
end

-- no road: a place far from any lane
check(Route.nearest(roblox.Vector3.new(0, 0, 50000), 45, nil, nil) == nil, "nowhere near a road")

if failures == 0 then
	print("ALL OK")
else
	print(failures .. " FAILED")
	process.exit(1)
end
