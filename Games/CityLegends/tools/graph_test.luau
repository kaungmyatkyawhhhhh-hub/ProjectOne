-- Lune test for the lane graph (src/shared/CityLayout.lua): every lane leads somewhere, pieces
-- join up end to end, and you can drive from the city to Downtown, the islands and back
--   lune run tools/graph_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
-- Lune's CFrame.lookAt is transposed (its turn comes out mirrored); Roblox's is right, so the
-- shared code gets a correct one here (as in world_test)
local CFrameFixed = setmetatable({
	lookAt = function(at, target, up)
		local look = (target - at).Unit
		local upV = up or roblox.Vector3.new(0, 1, 0)
		if math.abs(look:Dot(upV)) > 0.9999 then
			upV = roblox.Vector3.new(0, 0, 1)
		end
		local right = look:Cross(upV).Unit
		return roblox.CFrame.fromMatrix(at, right, right:Cross(look), -look)
	end,
}, { __index = roblox.CFrame })
local env = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = CFrameFixed, math = math, string = string, table = table, print = print, warn = warn, error = error }
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
	-- (a turn on Legends Isle's climbs may keep climbing gently through a bend)
	if seg.kind == "turn" and math.abs(seg.p0.Y - seg.p2.Y) > math.max(1, seg.length * 0.15) then
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

-- every house lot and its driveway sits on flat ground at its own height (owner, 2026-10-29:
-- lots spread over the mountain at different heights; one lot's banks must not tilt another's)
do
	local Isle = load("IsleLayout")
	local off, worstLot = 0, ""
	for _, l in Isle.lots() do
		local p = l.frame.Position
		for _, sx in { -0.9, 0, 0.9 } do
			for _, sz in { -0.9, 0, 0.9 } do
				local q = (l.frame * roblox.CFrame.new(sx * l.width / 2, 0, sz * l.depth / 2)).Position
				local d = math.abs(Isle.surface(q.X - Isle.Center.X, q.Z - Isle.Center.Z) - (p.Y - 0.3))
				if d > off then
					off, worstLot = d, l.id
				end
			end
		end
		for _, q in l.drive do
			local d = math.abs(Isle.surface(q.X - Isle.Center.X, q.Z - Isle.Center.Z) - (q.Y - 0.4))
			if d > off then
				off, worstLot = d, l.id .. " drive"
			end
		end
	end
	check(off < 0.6, string.format("house lots and drives on flat ground (worst %.2f at %s)", off, worstLot))
	-- no driveway runs into another lot or another lot's driveway, and none is steeper than 12%
	local clash, steep = "", 0
	local function flat(v)
		return roblox.Vector3.new(v.X, 0, v.Z)
	end
	for _, a in Isle.lots() do
		for k, q in a.drive do
			if k > 1 then
				local run = (flat(q) - flat(a.drive[k - 1])).Magnitude
				if run > 0.5 then
					steep = math.max(steep, math.abs(q.Y - a.drive[k - 1].Y) / run)
				end
			end
			for _, b in Isle.lots() do
				if b ~= a then
					local rel = b.frame:PointToObjectSpace(roblox.Vector3.new(q.X, b.frame.Y, q.Z))
					if math.abs(rel.X) < b.width / 2 + a.driveWidth / 2 + 4 and math.abs(rel.Z) < b.depth / 2 + a.driveWidth / 2 + 4 then
						clash = a.id .. " drive into lot " .. b.id
					end
					for _, r in b.drive do
						if (flat(q) - flat(r)).Magnitude < (a.driveWidth + b.driveWidth) / 2 + 2 and math.abs(q.Y - r.Y) < 30 then
							clash = a.id .. " drive into " .. b.id .. "'s drive"
						end
					end
				end
			end
		end
	end
	check(clash == "", "driveways clear of other lots and drives " .. clash)
	check(steep <= 0.12, string.format("driveways no steeper than 12%% (%.1f%%)", steep * 100))
	-- and no lot ends at a cliff: 20 studs past its edge the ground is within 20 of the pad
	local pillar, pillarAt = 0, ""
	for _, l in Isle.lots() do
		for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			for t = -0.8, 0.81, 0.4 do
				local ox = if side[1] ~= 0 then side[1] * (l.width / 2 + 20) else t * l.width / 2
				local oz = if side[2] ~= 0 then side[2] * (l.depth / 2 + 20) else t * l.depth / 2
				local q = (l.frame * roblox.CFrame.new(ox, 0, oz)).Position
				local d = math.abs(Isle.surface(q.X - Isle.Center.X, q.Z - Isle.Center.Z) - l.frame.Y)
				if d > pillar then
					pillar, pillarAt = d, l.id
				end
			end
		end
	end
	check(pillar <= 20, string.format("no lot ends at a cliff (worst %.0f studs at %s)", pillar, pillarAt))
end
print(`{#graph.all} segments, {#graph.lanes} lanes`)
if fails > 0 then
	print(`{fails} FAILED`)
	process.exit(1)
end
print("ALL OK")
