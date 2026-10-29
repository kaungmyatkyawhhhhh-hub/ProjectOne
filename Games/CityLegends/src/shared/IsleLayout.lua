--[[
	IsleLayout (shared)
	Legends Isle (owner, 2026-10-29: "one big island" with a big mountain, in place of Legends Key,
	Palm Isle and Coral Cay). Everything that needs to know where things are on it reads this
	module: the lane graph (CityLayout.addWest), the build (Isle: terrain and roads), the house
	plots and places (WestLayout), the gate (Gate), the minimap.

	From the shore up (local x east, z south, from the island's centre):
	  * a sand beach all round running into the sea, then the low ground with the island ring
	    road; the low tier's street lots sit inside the ring by the causeway (east)
	  * the mountain (terrain, about 400 high): gentle lower slopes up to the mid terrace (a shelf at
	    Mid.y round the mountain, the mid ring road on it and the mid tier's lots outside the
	    road), a steeper rock face above, and the flat top (Top.y) with the top ring road and the
	    gated community's lots; rock cliffs drop to the sea on the west
	  * the low climb: five curved switchbacks up the east face, from the island ring to the mid
	    ring; the high climb: from the mid ring through the gate, five more up the west face to the
	    top ring (private: traffic stays out, Gate checks who drives in)
	Every road is 1 + 1 lanes (Road wide) and climbs at about 10%; the hairpins are level.

	IsleLayout.surface(x, z) is the ground's height everywhere on the island: the mountain's natural
	shape with the roads, terraces and lots flattened into it. Isle writes the terrain from it.
]]

local Config = require(script.Parent.Config)

local C = Config.City
local I = Config.West.Isle

local IsleLayout = {}

IsleLayout.Center = Vector3.new(I.x, 0, I.z)
local CX, CZ = I.x, I.z

local function world(x: number, z: number, y: number?): Vector3
	return Vector3.new(CX + x, y or 0, CZ + z)
end
IsleLayout.world = world

local function polar(r: number, a: number, y: number?): Vector3
	return world(math.cos(a) * r, math.sin(a) * r, y)
end
IsleLayout.polar = polar

local HALF = I.Road / 2
IsleLayout.Road = I.Road
IsleLayout.Flat = 14 -- how far a leg stays level next to a hairpin at its low end
-- ... and at its high end: more than half the road's width, so the level run between the two
-- hairpins (which crosses the leg's end) never stands above the leg (owner, 2026-10-29: the car
-- jerked going up and down; it was 14 there too and the corner stood up to a stud proud)
IsleLayout.FlatHigh = 20
IsleLayout.SeaLevel = -2

---------------------------------------------------------------------
-- Rings (round roads): centre, radius (the road's middle), height
---------------------------------------------------------------------
export type Ring = { id: string, center: Vector3, radius: number, y: number, private: boolean }
IsleLayout.Rings = {
	isle = { id = "isle", center = world(0, 0, 0), radius = I.Ring, y = 0, private = false },
	mid = { id = "mid", center = world(0, 0, I.Mid.y), radius = I.Mid.ring, y = I.Mid.y, private = false },
	top = { id = "top", center = world(0, 0, I.Top.y), radius = I.Top.ring, y = I.Top.y, private = true },
} :: { [string]: Ring }
local R = IsleLayout.Rings

---------------------------------------------------------------------
-- The climbs: corner points with heights; `level` marks the hairpins (turns there are level)
---------------------------------------------------------------------
export type Road = {
	id: string,
	pts: { Vector3 }, -- world corners, first and last on a ring's edge
	level: { boolean }, -- per corner: a hairpin (the legs either side are level near it)
	from: string,
	to: string,
	fromAngle: number,
	toAngle: number,
	private: boolean,
	rails: boolean,
}

-- switchbacks: from ring `from` (its edge facing the mountain) round arcs at each radius, joined
-- by level hairpins, to ring `to`. Each arc climbs an equal share; arcs are cut into ~11 degree
-- pieces.
local function switchbacks(id: string, spec: any, from: Ring, fromOut: boolean, to: Ring, toOut: boolean, y0: number, y1: number, private: boolean): Road
	local radii = spec.radii
	local rise = (y1 - y0) / #radii
	local pts: { Vector3 } = {}
	local level: { boolean } = {}
	local function add(p: Vector3, lv: boolean)
		table.insert(pts, p)
		table.insert(level, lv)
	end
	local a = spec.center + (spec.length / radii[1]) / 2
	local fromAngle = a
	add(polar(from.radius + (if fromOut then HALF else -HALF), a, y0), false)
	local y = y0
	local dir = -1
	for _, r in radii do
		local span = spec.length / r
		local steps = math.max(2, math.ceil(span / 0.2))
		-- the climb shared out over the run (the first and last pieces are level next to the
		-- hairpins), so every piece climbs at the same grade
		local piece = 2 * r * math.sin(span / steps / 2)
		local run = piece * steps - IsleLayout.Flat - IsleLayout.FlatHigh
		local function yAt(q: number): number
			local done = math.clamp(piece * q - IsleLayout.Flat, 0, run)
			return y + rise * done / run
		end
		add(polar(r, a, y), true) -- a hairpin (or the start)
		for q = 1, steps - 1 do
			add(polar(r, a + dir * span * q / steps, yAt(q)), false)
		end
		a += dir * span
		y += rise
		add(polar(r, a, y), true)
		dir = -dir
	end
	add(polar(to.radius + (if toOut then HALF else -HALF), a, y1), false)
	return { id = id, pts = pts, level = level, from = from.id, to = to.id, fromAngle = fromAngle, toAngle = a, private = private, rails = true }
end

IsleLayout.Roads = {
	switchbacks("climb_low", I.Lower, R.isle, false, R.mid, true, 0, I.Mid.y, false),
	switchbacks("climb_high", I.Upper, R.mid, false, R.top, true, I.Mid.y, I.Top.y, true),
} :: { Road }

-- where the causeway meets the island ring (east)
IsleLayout.CausewayAngle = 0
IsleLayout.CausewayEnd = CX + I.Ring + HALF

-- each ring's junctions: angle, the gap either side (radians) and which road meets it
export type Join = { angle: number, gap: number, road: string }
function IsleLayout.joins(ringId: string): { Join }
	local ring = R[ringId]
	local out: { Join } = {}
	if ringId == "isle" then
		table.insert(out, { angle = IsleLayout.CausewayAngle, gap = (C.RoadWidth / 2 + 12) / ring.radius, road = "causeway" })
	end
	for _, rd in IsleLayout.Roads do
		if rd.from == ringId then
			table.insert(out, { angle = rd.fromAngle, gap = (HALF + 14) / ring.radius, road = rd.id })
		end
		if rd.to == ringId then
			table.insert(out, { angle = rd.toAngle, gap = (HALF + 14) / ring.radius, road = rd.id })
		end
	end
	return out
end

-- a corner's turn (radians) and how far the legs stop short of it for the turn
local function turnAt(pts: { Vector3 }, k: number): number
	local a, b, c = pts[k - 1], pts[k], pts[k + 1]
	local d1 = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Unit
	local d2 = Vector3.new(c.X - b.X, 0, c.Z - b.Z).Unit
	return math.acos(math.clamp(d1:Dot(d2), -1, 1))
end
IsleLayout.turnAt = turnAt
function IsleLayout.trim(pts: { Vector3 }, k: number): number
	if k <= 1 or k >= #pts then
		return 0
	end
	return 4 + 8 * math.clamp(turnAt(pts, k) / (math.pi / 2), 0, 1)
end

-- how far a leg stays level at each end (next to a hairpin: Flat at its low end, FlatHigh at
-- its high end; elsewhere 0)
function IsleLayout.flats(y0: number, y1: number, flat0: boolean, flat1: boolean): (number, number)
	local f0 = if flat0 then (if y0 > y1 then IsleLayout.FlatHigh else IsleLayout.Flat) else 0
	local f1 = if flat1 then (if y1 > y0 then IsleLayout.FlatHigh else IsleLayout.Flat) else 0
	return f0, f1
end

-- a leg's height at distance d along it: an even slope, level next to a hairpin
function IsleLayout.legY(y0: number, y1: number, len: number, d: number, flat0: boolean, flat1: boolean): number
	local f0, f1 = IsleLayout.flats(y0, y1, flat0, flat1)
	if len <= f0 + f1 + 1 then
		return y0
	end
	return y0 + (y1 - y0) * math.clamp((d - f0) / (len - f0 - f1), 0, 1)
end

-- the steepest leg (the graph test keeps it drivable)
function IsleLayout.maxGrade(): number
	local worst = 0
	for _, rd in IsleLayout.Roads do
		for k = 1, #rd.pts - 1 do
			local a, b = rd.pts[k], rd.pts[k + 1]
			local len = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
			local f0, f1 = IsleLayout.flats(a.Y, b.Y, rd.level[k], rd.level[k + 1])
			local run = len - f0 - f1
			if run > 1 then
				worst = math.max(worst, math.abs(b.Y - a.Y) / run)
			end
		end
	end
	return worst
end

---------------------------------------------------------------------
-- The gate (on the high climb's first stub, just in from the mid ring) and the private area
---------------------------------------------------------------------
do
	local rd = IsleLayout.Roads[2]
	local a, b = rd.pts[1], rd.pts[2]
	local mid = (a + b) / 2
	IsleLayout.GateCFrame = CFrame.lookAt(mid, mid + (b - a) * Vector3.new(1, 0, 1)) -- facing in, up the climb
end
IsleLayout.GateRadius = I.Mid.ring - HALF - 8 -- inside this, above the mid terrace, is the gated community

function IsleLayout.inGated(p: Vector3): boolean
	local flat = Vector3.new(p.X - CX, 0, p.Z - CZ).Magnitude
	return flat < IsleLayout.GateRadius and p.Y > I.Mid.y - 6
end

function IsleLayout.onIsle(p: Vector3): boolean
	return Vector3.new(p.X - CX, 0, p.Z - CZ).Magnitude < I.r
end

---------------------------------------------------------------------
-- Spots on the island
---------------------------------------------------------------------
local function angDiff(a: number, b: number): number
	local d = (a - b) % (2 * math.pi)
	return math.min(d, 2 * math.pi - d)
end
IsleLayout.angDiff = angDiff

-- how far round from west the high climb reaches (the top's lots keep clear of it)
local UPPER_SPAN = 0
for _, p in IsleLayout.Roads[2].pts do
	UPPER_SPAN = math.max(UPPER_SPAN, angDiff(math.atan2(p.Z - CZ, p.X - CX), I.Upper.center))
end
IsleLayout.UpperSpan = UPPER_SPAN

IsleLayout.LookoutAngle = 0 -- east: back over the bay to Downtown
IsleLayout.HelipadAngle = math.pi * 0.5
function IsleLayout.helipad(): Vector3
	return polar(I.Top.ring - HALF - 42, IsleLayout.HelipadAngle, I.Top.y)
end
function IsleLayout.lookout(): Vector3
	return polar(I.Top.ring + HALF + 97, IsleLayout.LookoutAngle, I.Top.y)
end
IsleLayout.FountainAngle = -0.12
function IsleLayout.fountain(): Vector3
	return polar(I.Ring - HALF - 46, IsleLayout.FountainAngle, 0)
end

---------------------------------------------------------------------
-- House lots by tier (WestLayout.housePlots passes these on). Owner, 2026-10-29: High lots spread
-- over the top, each on its own spot with its own curved private driveway, about 150+ studs
-- apart; waterfront lots with a dock; Mid and Low along their roads but not in a perfect row.
---------------------------------------------------------------------
export type Lot = {
	id: string,
	zone: string, -- "low" | "mid" | "high"
	tier: number, -- 0 low, 1 mid, 2 high
	number: number, -- the lot number on its sign
	water: boolean, -- on the beach, with a dock out the back
	frame: CFrame, -- the pad's middle, looking out of the front (towards the drive)
	width: number,
	depth: number,
	drive: { Vector3 }, -- the private driveway, road edge to the front of the lot (surface points)
	driveWidth: number,
}

local function angleClear(a: number, list: { number }, gap: number): boolean
	for _, j in list do
		if angDiff(a, j) < gap then
			return false
		end
	end
	return true
end

-- the same jitter every server (and in the tests): a small hash of the lot's id
local function wobble(id: string, salt: number): number
	local h = salt * 131
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 100003
	end
	return (h / 100003) * 2 - 1
end

-- a curve from a to b leaving a towards `aim` (both surface points); the height changes evenly
-- along its length, so every piece has the same grade
local function curve(a: Vector3, aim: Vector3, b: Vector3, steps: number): { Vector3 }
	local flatPts = {}
	local lens = { 0 }
	for k = 0, steps do
		local t = k / steps
		local u = 1 - t
		local p = a * (u * u) + aim * (2 * u * t) + b * (t * t)
		table.insert(flatPts, Vector3.new(p.X, 0, p.Z))
		if k > 0 then
			table.insert(lens, lens[k] + (flatPts[k + 1] - flatPts[k]).Magnitude)
		end
	end
	local total = lens[#lens]
	local pts = {}
	for k, p in flatPts do
		table.insert(pts, Vector3.new(p.X, a.Y + (b.Y - a.Y) * lens[k] / total, p.Z))
	end
	return pts
end

-- a lot whose front looks at `toward` (turned a little by `turn`), with its driveway
local function lot(id: string, zone: string, tier: number, center: Vector3, toward: Vector3, width: number, depth: number, drive: { Vector3 }, driveWidth: number, water: boolean?, turn: number?): Lot
	local look = Vector3.new(toward.X - center.X, 0, toward.Z - center.Z).Unit
	return {
		id = id,
		zone = zone,
		tier = tier,
		number = 0,
		water = water == true,
		frame = CFrame.lookAt(center, center + look) * CFrame.Angles(0, turn or 0, 0),
		width = width,
		depth = depth,
		drive = drive,
		driveWidth = driveWidth,
	}
end

-- the summit lots: {angle, radius of the lot's middle, pad height, how far round the drive starts}
-- (no lot reaches past about 388 from the middle: beyond that the mid ring's banks cut the ridge
-- down towards its terrace, and a lot would end at a cliff)
IsleLayout.SummitLots = {
	-- (every drive on the north side bends one way and on the south side the other, so no drive
	-- crosses another one or a lot; none starts in the gap where the high climb joins, at 2.45)
	{ -2.05, 300, 400, 0.32 },
	{ -1.6, 320, 406, 0.18 }, -- up on the north ridge
	{ -1.05, 300, 400, 0.32 },
	{ -0.55, 285, 392, 0.32 }, -- looking back over the bay to Downtown
	{ 0.4, 285, 392, -0.32 },
	{ 0.95, 300, 400, -0.32 },
	{ 1.45, 320, 404, -0.18 }, -- out on the south ridge
	{ 2.05, 300, 400, -0.32 },
}
-- the waterfront lots: {angle, tier}
IsleLayout.WaterLots = { { -1.85, 2 }, { -1.35, 2 }, { 1.35, 2 }, { 1.85, 2 }, { -2.4, 1 }, { 2.4, 1 }, { 0.9, 1 } }

local lotsCache: { Lot }? = nil
function IsleLayout.lots(): { Lot }
	if lotsCache then
		return lotsCache
	end
	local out: { Lot } = {}
	-- low tier: inside the island ring either side of the causeway (street houses), the gaps,
	-- setbacks and angles a little uneven like a real street
	local isleJoins = {}
	for _, j in IsleLayout.joins("isle") do
		table.insert(isleJoins, j.angle)
	end
	table.insert(isleJoins, IsleLayout.FountainAngle)
	local L = I.Low
	local rLow = I.Ring - HALF - 8 - L.depth / 2
	local n = 0
	local a = -L.arc
	while a <= L.arc + 1e-6 do
		local step = (L.width + 14 + 6 * (wobble(`lowgap{n}`, 1) + 1)) / rLow
		if math.abs(a) > L.skip and angleClear(a, isleJoins, step * 0.9) then
			n += 1
			local id = `low_{n}`
			local r = rLow - 3 * (wobble(id, 2) + 1) -- set back 0 to 6 studs
			local c = polar(r, a, 0)
			table.insert(out, lot(id, "low", 0, c, polar(I.Ring, a, 0), L.width, L.depth, {}, 0, false, math.rad(4) * wobble(id, 3)))
		end
		a += step
	end
	-- mid tier: outside the mid ring on the terrace, looking out to sea, unevenly spaced
	local midJoins = {}
	for _, j in IsleLayout.joins("mid") do
		table.insert(midJoins, j.angle)
	end
	local M = I.Mid
	for k = 0, M.lots - 1 do
		local id = `mid_{k + 1}`
		local am = (k + 0.5) / M.lots * 2 * math.pi + 0.07 * wobble(id, 4)
		local rMid = M.ring + HALF + 10 + M.lotDepth / 2 + 6 * wobble(id, 5)
		-- (and none where the low climb's last bend runs along under the terrace's edge)
		if angleClear(am, midJoins, (M.lotWidth / 2 + HALF + 20) / rMid) and math.abs(angDiff(am, 0)) > 0.42 then
			local c = polar(rMid, am, M.y)
			local frontAt = polar(M.ring + HALF, am, M.y)
			local frontEdge = polar(rMid - M.lotDepth / 2, am, M.y)
			table.insert(out, lot(id, "mid", 1, c, frontAt, M.lotWidth, M.lotDepth, { frontAt, frontEdge }, 16, false, math.rad(4) * wobble(id, 6)))
		end
	end
	-- high tier on the summit: each on its own spot round the top (two out on the ridge), at
	-- different heights, with a curved private drive off the summit ring
	local T = I.Top
	for i, s in IsleLayout.SummitLots do
		local am, r, y, bend = s[1], s[2], s[3], s[4]
		local c = polar(r, am, y)
		local frontEdge = polar(r - T.lotDepth / 2, am, y)
		local start = polar(T.ring + HALF, am + bend, T.y)
		local aim = polar((T.ring + HALF + r - T.lotDepth / 2) / 2, am + bend, (T.y + y) / 2)
		local pts = curve(start, aim, frontEdge, 8)
		table.insert(out, lot(`high_{i}`, "high", 2, c, polar(T.ring, am, y), T.lotWidth, T.lotDepth, pts, 18))
	end
	-- the waterfront: on the beach side of the island ring at the long ends, a short drive in from
	-- the ring, the back of the lot at the top of the sand (a dock goes on into the water)
	local wl, wm = 0, 0
	for _, s in IsleLayout.WaterLots do
		local am, tier = s[1], s[2]
		local W = if tier == 2 then T else M
		local depth = if tier == 2 then T.lotDepth else M.lotDepth
		-- (the back at the top of the sand, or if the beach is narrow, the front kept off the road)
		local r = math.max(IsleLayout.shore(am) - 92 - depth / 2, I.Ring + HALF + 16 + depth / 2)
		local id
		if tier == 2 then
			wl += 1
			id = `high_w{wl}`
		else
			wm += 1
			id = `mid_w{wm}`
		end
		local y = 0.6
		local c = polar(r, am, y)
		local start = polar(I.Ring + HALF, am, 0)
		local frontEdge = polar(r - depth / 2, am, y)
		table.insert(out, lot(id, if tier == 2 then "high" else "mid", tier, c, start, W.lotWidth, depth, { start, frontEdge }, 18, true))
	end
	-- numbers on the signs: low first, then mid, then high
	local num = 0
	for _, tier in { 0, 1, 2 } do
		for _, l in out do
			if l.tier == tier then
				num += 1
				l.number = num
			end
		end
	end
	lotsCache = out
	return out
end

---------------------------------------------------------------------
-- Named places (chauffeur, map labels): a spot on a ring road's outer lane, heading round
---------------------------------------------------------------------
local function onRing(ring: Ring, a: number): CFrame
	-- the clockwise lane runs outside the ring's middle (CityLayout's islandRing)
	local p = polar(ring.radius + C.LaneWidth / 2, a, ring.y)
	local tangent = Vector3.new(math.sin(a), 0, -math.cos(a)) -- clockwise (decreasing angle)
	return CFrame.lookAt(p, p + tangent)
end
function IsleLayout.places(): { { id: string, name: string, cf: CFrame } }
	return {
		{ id = "isle", name = "Legends Isle", cf = onRing(R.isle, 0.4) },
		{ id = "isle_mid", name = "Legends Isle Heights", cf = onRing(R.mid, 0.6) },
		{ id = "isle_top", name = "The Summit (gated)", cf = onRing(R.top, IsleLayout.Roads[2].toAngle + 0.8) },
	}
end

---------------------------------------------------------------------
-- The ground: the mountain's natural shape, then the roads, terraces and lots flattened into it
---------------------------------------------------------------------
local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- the shore's distance from the centre at angle a: longer north-south than east-west, uneven
function IsleLayout.shore(a: number): number
	return I.r + 170 * math.sin(a) ^ 2 + 45 * math.noise(math.cos(a) * 1.3, math.sin(a) * 1.3, 2.2) + 25 * math.noise(math.cos(a) * 4, math.sin(a) * 4, 5.5)
end
IsleLayout.MaxShore = I.r + 260

-- the peaks: the main one just off the middle (inside the top ring), lower ones along a ridge
-- running north-south. {x, z, height, radius}
IsleLayout.Peaks = {
	{ -38, -52, 505, 82 },
	{ -40, -430, 380, 150 },
	{ -70, -760, 300, 190 },
	{ 60, 770, 275, 180 },
	{ 110, 470, 330, 160 },
}

-- ridged noise: sharp crests where plain noise crosses zero
local function ridged(x: number, z: number, seed: number): number
	return 1 - math.abs(math.noise(x, z, seed))
end

-- the mountain as nature made it, at local x, z: a big off-centre ridge with peaks, gullies
-- running down the sides, rocky crests between them, cliffs to the sea and a gentler face east
-- towards the bridge (where the road goes up). The roads, terraces and lots are carved in after.
function IsleLayout.natural(x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	local a = math.atan2(z, x)
	-- the main mass: an ellipse, longer north-south
	local R = I.Foot + 70 * math.sin(a) ^ 2
	local rho = r / R
	local east = smooth((math.cos(a) - 0.35) / 0.45) -- 1 facing the bridge, 0 facing the sea
	local h = 0
	if rho < 1 then
		local gentle = 470 * (1 - rho) ^ 0.95 -- even slopes up from the low ground
		local cliff = 470 * (1 - rho ^ 2.1) -- standing high, dropping hard at the foot
		h = cliff + (gentle - cliff) * east
	end
	-- the ridge along the north-south spine, wandering a little
	local spine = 60 * math.sin(z / 380) - 30
	local dr = math.abs(x - spine)
	local along = math.clamp(1 - math.abs(z) / 1150, 0, 1)
	h = math.max(h, 410 * along ^ 0.6 * math.max(0, 1 - dr / 420) ^ 1.6)
	-- the peaks
	for _, pk in IsleLayout.Peaks do
		local d = math.sqrt((x - pk[1]) ^ 2 + (z - pk[2]) ^ 2)
		if d < pk[4] * 2.2 then
			h = math.max(h, pk[3] - (pk[3] - h) * smooth(d / (pk[4] * 2.2)))
		end
	end
	-- rough ground: big shapes, medium bumps and small detail, sharp crests, and gullies
	-- running down the sides (noise stretched along the slope); none on the low ground
	local rough = smooth(h / 70)
	if rough > 0 then
		local n = 34 * math.noise(x / 420, z / 420, 1.7) + 15 * math.noise(x / 150, z / 150, 3.1) + 5 * math.noise(x / 45, z / 45, 8.3)
		n += 30 * ridged(x / 240, z / 240, 9.2) ^ 3
		-- (round the mountain: crests every so often, gullies between them, running downhill)
		local g = 1 - math.abs(math.noise(math.cos(a) * 2.6, math.sin(a) * 2.6, r / 520 + 4.4))
		n -= 46 * (1 - g) ^ 0.5 * smooth((h - 40) / 120) * (1 - smooth((h - 380) / 60))
		h += n * rough * (0.55 + 0.45 * (1 - east))
	end
	-- the low ground, the beach and the sea floor
	local shore = IsleLayout.shore(a)
	if r > shore - 90 then
		local t = (r - (shore - 90)) / 90
		h = math.min(h, 1.2 - t * 4.2)
	end
	if r > shore then
		h = math.max(-16, -3 - (r - shore) * 0.06)
	end
	return h
end

-- the flattening: a flat zone at height y (out to `flat` from its line), with banks no steeper
-- than k (rise per run) out from there
type Zone = { kind: string, y: number, flat: number, k: number, a: Vector3?, b: Vector3?, y1: number?, r0: number?, r1: number?, frame: CFrame?, w: number?, d: number?, f0: boolean?, f1: boolean?, reach: number?, box: { number } }
local zones: { Zone }? = nil
local CELL = 96
local grid: { [number]: { Zone } } = {}
local REACH = 150 -- how far a zone's banks can reach
-- (a house lot's banks reach less far: a summit lot 200 studs above a terrace lot must not tilt
-- the ground of the one below, nor the other way round)
local LOT_REACH = 100
local LOT_SLOPE = 0.8 -- its banks: gentle enough to read as a garden slope, not a cliff

local function key(gx: number, gz: number): number
	return gx * 65536 + gz
end

local function addZone(z: Zone)
	table.insert(zones :: { Zone }, z)
	local b = z.box
	for gx = math.floor(b[1] / CELL), math.floor(b[3] / CELL) do
		for gz = math.floor(b[2] / CELL), math.floor(b[4] / CELL) do
			local k = key(gx, gz)
			grid[k] = grid[k] or {}
			table.insert(grid[k], z)
		end
	end
end

local function buildZones()
	zones = {}
	local M, T = I.Mid, I.Top
	-- terraces and lots first (the roads win where they meet)
	addZone({ kind = "annulus", y = M.y - 0.3, flat = 0, k = 1.3, r0 = M.inner, r1 = M.outer, box = { -M.outer - REACH, -M.outer - REACH, M.outer + REACH, M.outer + REACH } })
	addZone({ kind = "top", y = T.y - 0.3, flat = 0, k = 1.3, r0 = 0, r1 = T.r, box = { -T.r - REACH, -T.r - REACH, T.r + REACH, T.r + REACH } })
	addZone({ kind = "annulus", y = -0.3, flat = 0, k = 0.6, r0 = I.Foot + 20, r1 = I.r - 95, box = { -I.r, -I.r, I.r, I.r } })
	-- the lookout's own flat (out on the east edge of the top) and the path to it
	do
		local p = IsleLayout.lookout()
		local f = CFrame.lookAt(p, Vector3.new(CX, p.Y, CZ))
		addZone({ kind = "lot", y = p.Y - 0.3, flat = 4, k = LOT_SLOPE, reach = LOT_REACH, frame = f * CFrame.new(0, 0, -30), w = 60, d = 120, box = { p.X - CX - 220, p.Z - CZ - 220, p.X - CX + 220, p.Z - CZ + 220 } })
	end
	-- the gate's yard (the guard house and the guards stand beside the road)
	do
		local g = IsleLayout.GateCFrame
		local p = g.Position
		addZone({ kind = "lot", y = p.Y - 0.3, flat = 2, k = 1.4, frame = g, w = 96, d = 50, box = { p.X - CX - 220, p.Z - CZ - 220, p.X - CX + 220, p.Z - CZ + 220 } })
	end
	for _, l in IsleLayout.lots() do
		local p = l.frame.Position
		local rad = math.max(l.width, l.depth) / 2 + REACH
		addZone({ kind = "lot", y = p.Y - 0.3, flat = 4, k = LOT_SLOPE, reach = LOT_REACH, frame = l.frame, w = l.width, d = l.depth, box = { p.X - CX - rad, p.Z - CZ - rad, p.X - CX + rad, p.Z - CZ + rad } })
		-- its private driveway, flat across like a road
		for k = 1, #l.drive - 1 do
			local a, b = l.drive[k], l.drive[k + 1]
			local reach = l.driveWidth / 2 + REACH
			addZone({ kind = "leg", y = a.Y - 0.4, y1 = b.Y - 0.4, flat = l.driveWidth / 2 + 3, k = 1.5, a = a, b = b, f0 = false, f1 = false,
				box = { math.min(a.X, b.X) - CX - reach, math.min(a.Z, b.Z) - CZ - reach, math.max(a.X, b.X) - CX + reach, math.max(a.Z, b.Z) - CZ + reach } })
		end
	end
	-- the roads: rings and the climbs' legs, low to high
	for _, ring in { R.isle, R.mid, R.top } do
		local rr = ring.radius + HALF + REACH
		addZone({ kind = "ring", y = ring.y - 0.4, flat = HALF + 5, k = 1.5, r0 = ring.radius, box = { -rr, -rr, rr, rr } })
	end
	for _, rd in IsleLayout.Roads do
		for k = 1, #rd.pts - 1 do
			local a, b = rd.pts[k], rd.pts[k + 1]
			local x0, x1 = math.min(a.X, b.X) - CX, math.max(a.X, b.X) - CX
			local z0, z1 = math.min(a.Z, b.Z) - CZ, math.max(a.Z, b.Z) - CZ
			local reach = HALF + REACH
			addZone({ kind = "leg", y = a.Y - 0.4, y1 = b.Y - 0.4, flat = HALF + 5, k = 1.5, a = a, b = b, f0 = rd.level[k], f1 = rd.level[k + 1], box = { x0 - reach, z0 - reach, x1 + reach, z1 + reach } })
		end
	end
end

-- a zone's target height at a point, and how far outside its flat part the point is
local function zoneAt(z: Zone, x: number, zz: number, r: number, a: number): (number, number, number)
	if z.kind == "annulus" then
		local d = if r < (z.r0 :: number) then (z.r0 :: number) - r elseif r > (z.r1 :: number) then r - (z.r1 :: number) else 0
		return z.y, d, d
	elseif z.kind == "top" then
		-- the top is smaller on the west face, where the high climb's last legs come up
		local rr = (z.r1 :: number) - 90 * smooth(1 - (angDiff(a, I.Upper.center) - UPPER_SPAN + 0.1) / 0.5)
		return z.y, math.max(0, r - rr), r - rr
	elseif z.kind == "ring" then
		local d = math.abs(r - (z.r0 :: number))
		return z.y, math.max(0, d - z.flat), d
	elseif z.kind == "lot" then
		local f = z.frame :: CFrame
		local rel = f:PointToObjectSpace(Vector3.new(CX + x, f.Position.Y, CZ + zz))
		local dx = math.max(0, math.abs(rel.X) - (z.w :: number) / 2 - z.flat)
		local dz = math.max(0, math.abs(rel.Z) - (z.d :: number) / 2 - z.flat)
		local d = math.sqrt(dx * dx + dz * dz)
		return z.y, d, d
	end
	local a3, b3 = z.a :: Vector3, z.b :: Vector3
	local ax, az = a3.X - CX, a3.Z - CZ
	local abx, abz = b3.X - a3.X, b3.Z - a3.Z
	local len2 = abx * abx + abz * abz
	local t = math.clamp(((x - ax) * abx + (zz - az) * abz) / len2, 0, 1)
	local px, pz = ax + abx * t, az + abz * t
	local d = math.sqrt((x - px) ^ 2 + (zz - pz) ^ 2)
	local len = math.sqrt(len2)
	-- (past its ends a leg reaches round as a disc, so the corners are flat too)
	return IsleLayout.legY(z.y, z.y1 :: number, len, t * len, z.f0 :: boolean, z.f1 :: boolean), math.max(0, d - z.flat), d
end

-- the ground's height at local x, z (from the island's centre)
function IsleLayout.surface(x: number, z: number): number
	if not zones then
		buildZones()
	end
	local r = math.sqrt(x * x + z * z)
	local a = math.atan2(z, x)
	local h = IsleLayout.natural(x, z)
	if r > IsleLayout.MaxShore then
		return h
	end
	local list = grid[key(math.floor(x / CELL), math.floor(z / CELL))]
	if not list then
		return h
	end
	-- banks first (each zone keeps the ground within its slope of its height), then the flat
	-- parts of the roads again on top (so a bank never lifts or buries a road)
	for _, zn in list do
		local y, e = zoneAt(zn, x, z, r, a)
		if e < (zn.reach or REACH) then
			h = math.clamp(h, y - zn.k * e, y + zn.k * e)
		end
	end
	-- a lot's pad is flat whatever banks reach over it
	for _, zn in list do
		if zn.kind == "lot" then
			local y, e = zoneAt(zn, x, z, r, a)
			if e <= 0 then
				h = y
			end
		end
	end
	-- (where two pieces' flats overlap at a bend, the nearer piece's line decides)
	local best = math.huge
	for _, zn in list do
		if zn.kind == "leg" or zn.kind == "ring" then
			local y, e, d = zoneAt(zn, x, z, r, a)
			if e <= 0 and d < best then
				best = d
				h = y
			end
		end
	end
	return h
end

-- on the flat ground of a road, terrace or lot, or within `margin` of it (no trees there)
function IsleLayout.inZone(x: number, z: number, margin: number): boolean
	if not zones then
		buildZones()
	end
	local r = math.sqrt(x * x + z * z)
	local a = math.atan2(z, x)
	local list = grid[key(math.floor(x / CELL), math.floor(z / CELL))]
	for _, zn in list or {} do
		if not (zn.kind == "annulus" and zn.y < 1) then
			local _, e = zoneAt(zn, x, z, r, a)
			if e < margin then
				return true
			end
		end
	end
	return false
end

return IsleLayout
