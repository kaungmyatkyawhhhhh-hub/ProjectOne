--[[
	IsleLayout (shared)
	Legends Isle (owner, 2026-10-29: "one big island" in place of Legends Key, Palm Isle and Coral
	Cay): a round island at the end of the causeway with a mountain in the middle. Everything that
	needs to know where things are on it reads this module: the lane graph (CityLayout.addWest),
	the build (Isle), the house plots and places (WestLayout), the gate (Gate), the minimap.

	The plan, from the shore up (local x east, z south, from the island's centre):
	  * a beach all round, a lawn, and the island ring road (r = Ring) with the causeway landing on
	    its east side; the low tier's street houses stand inside the ring near the causeway
	  * the mountain (terrain): a lower slope up to the mid terrace (y = Mid.y), the mid ring road
	    on the terrace with the mid tier's lots outside it, then a steeper face up to the top
	    plateau (y = Top.y) and a rocky summit
	  * the low climb: switchbacks up the east face from the island ring to the mid ring
	  * the high climb: through the gate on the mid ring, switchbacks up the west face to the top
	    ring, the gated community (private: traffic stays out, Gate checks who drives in)
	Every road is 1 + 1 lanes (Road wide); every leg rises at most ~9% and turns are level.
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

local function angleOf(x: number, z: number): number
	return math.atan2(z, x)
end

local HALF = I.Road / 2
IsleLayout.Road = I.Road
-- (the corners' turn: legs stop this far short of a corner, and are level for that far)
IsleLayout.Trim = 12

---------------------------------------------------------------------
-- Rings (round roads): centre, radius (the road's middle), height
---------------------------------------------------------------------
export type Ring = { id: string, center: Vector3, radius: number, y: number, private: boolean }
IsleLayout.Rings = {
	isle = { id = "isle", center = world(0, 0, 0), radius = I.Ring, y = 0, private = false },
	mid = { id = "mid", center = world(0, 0, I.Mid.y), radius = I.Mid.ring, y = I.Mid.y, private = false },
	top = { id = "top", center = world(0, 0, I.Top.y), radius = I.Top.ring, y = I.Top.y, private = true },
} :: { [string]: Ring }

---------------------------------------------------------------------
-- Roads between the rings: corner points (local x, z, height)
---------------------------------------------------------------------
export type Road = {
	id: string,
	pts: { Vector3 }, -- world corners, first and last on a ring's edge
	from: string, -- ring ids at each end
	to: string,
	fromAngle: number,
	toAngle: number,
	private: boolean,
	rails: boolean, -- guard rails along the drops
}

-- the low climb: from the island ring (inner edge) up the east face's three switchbacks, then
-- straight in to the mid ring (outer edge)
local LOW = {
	{ 790, 220, 0 },
	{ 790, -220, 34 },
	{ 745, -220, 34 },
	{ 745, 220, 68 },
	{ 700, 220, 68 },
	{ 700, -220, I.Mid.y },
}
-- the high climb: from the mid ring (inner edge) through the gate, up the west face's five
-- switchbacks, then in to the top ring (outer edge)
local HIGH = {
	{ -370, -170, I.Mid.y },
	{ -370, 170, I.Mid.y + 28 },
	{ -330, 170, I.Mid.y + 28 },
	{ -330, -170, I.Mid.y + 56 },
	{ -290, -170, I.Mid.y + 56 },
	{ -290, 170, I.Mid.y + 84 },
	{ -250, 170, I.Mid.y + 84 },
	{ -250, -170, I.Mid.y + 112 },
	{ -210, -170, I.Mid.y + 112 },
	{ -210, 170, I.Top.y },
}

-- a road's corners: an end on a ring's edge on the line through the first / last corner
local function road(id: string, list: { { number } }, from: Ring, fromOut: boolean, to: Ring, toOut: boolean, private: boolean): Road
	local pts: { Vector3 } = {}
	local first, last = list[1], list[#list]
	local a0 = angleOf(first[1], first[2])
	local a1 = angleOf(last[1], last[2])
	table.insert(pts, polar(from.radius + (if fromOut then HALF else -HALF), a0, from.y))
	for _, p in list do
		table.insert(pts, world(p[1], p[2], p[3]))
	end
	table.insert(pts, polar(to.radius + (if toOut then HALF else -HALF), a1, to.y))
	return { id = id, pts = pts, from = from.id, to = to.id, fromAngle = a0, toAngle = a1, private = private, rails = true }
end

local R = IsleLayout.Rings
IsleLayout.Roads = {
	road("climb_low", LOW, R.isle, false, R.mid, true, false),
	road("climb_high", HIGH, R.mid, false, R.top, true, true),
} :: { Road }

-- where the causeway meets the island ring (east)
IsleLayout.CausewayAngle = 0
IsleLayout.CausewayEnd = CX + I.Ring + HALF

-- each ring's junctions: angle, the gap either side (radians) and which road / spur meets it
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

-- how high a road leg is at distance d along it (level for Trim at each end, an even slope between)
function IsleLayout.legY(y0: number, y1: number, len: number, d: number): number
	local t = IsleLayout.Trim
	if len <= t * 2 + 1 then
		return y0
	end
	local k = math.clamp((d - t) / (len - t * 2), 0, 1)
	return y0 + (y1 - y0) * k
end

-- the steepest leg (the graph test keeps it drivable)
function IsleLayout.maxGrade(): number
	local worst = 0
	for _, rd in IsleLayout.Roads do
		for k = 1, #rd.pts - 1 do
			local a, b = rd.pts[k], rd.pts[k + 1]
			local len = (Vector3.new(b.X - a.X, 0, b.Z - a.Z)).Magnitude
			local run = len - IsleLayout.Trim * 2
			if run > 0 then
				worst = math.max(worst, math.abs(b.Y - a.Y) / run)
			end
		end
	end
	return worst
end

---------------------------------------------------------------------
-- The mountain's shape (Isle builds it in terrain): ground height at a distance from the centre
---------------------------------------------------------------------
function IsleLayout.groundY(r: number): number
	local M, T = I.Mid, I.Top
	if r >= I.Foot then
		return 0
	elseif r >= M.outer then
		return M.y * (I.Foot - r) / (I.Foot - M.outer)
	elseif r >= M.inner then
		return M.y
	elseif r >= T.r then
		return M.y + (T.y - M.y) * (M.inner - r) / (M.inner - T.r)
	end
	return T.y
end

---------------------------------------------------------------------
-- The gate (on the high climb's first leg, just in from the mid ring) and the private area
---------------------------------------------------------------------
do
	local rd = IsleLayout.Roads[2]
	local a, b = rd.pts[1], rd.pts[2]
	local mid = (a + b) / 2
	IsleLayout.GateCFrame = CFrame.lookAt(mid, mid + (b - a) * Vector3.new(1, 0, 1)) -- facing in, up the climb
end
IsleLayout.GateRadius = I.Mid.inner - 8 -- inside this, above the mid terrace, is the gated community

function IsleLayout.inGated(p: Vector3): boolean
	local flat = Vector3.new(p.X - CX, 0, p.Z - CZ).Magnitude
	return flat < IsleLayout.GateRadius and p.Y > I.Mid.y - 6
end

function IsleLayout.onIsle(p: Vector3): boolean
	return Vector3.new(p.X - CX, 0, p.Z - CZ).Magnitude < I.r
end

---------------------------------------------------------------------
-- Spots: things that sit on the island (centre of each, facing)
---------------------------------------------------------------------
-- the top: lots, the helipad and the lookout share slots round the top ring
local TOP_SLOTS = 9
local function topSlot(k: number): number
	return IsleLayout.Roads[2].toAngle + k * 2 * math.pi / TOP_SLOTS
end
IsleLayout.HelipadAngle = topSlot(3)
IsleLayout.LookoutAngle = topSlot(5)
function IsleLayout.helipad(): Vector3
	return polar(I.Top.ring + HALF + 50, IsleLayout.HelipadAngle, I.Top.y)
end
function IsleLayout.lookout(): Vector3
	return polar(I.Top.r - 30, IsleLayout.LookoutAngle, I.Top.y)
end
-- the fountain plaza: inside the island ring, just south of the causeway's landing
IsleLayout.FountainAngle = -0.11
function IsleLayout.fountain(): Vector3
	return polar(I.Ring - HALF - 42, IsleLayout.FountainAngle, 0)
end

---------------------------------------------------------------------
-- House plots by tier (WestLayout.housePlots passes these on)
---------------------------------------------------------------------
export type Lot = { id: string, zone: string, frame: CFrame, width: number, depth: number }

local function angleClear(a: number, list: { number }, gap: number): boolean
	for _, j in list do
		local d = (a - j) % (2 * math.pi)
		if math.min(d, 2 * math.pi - d) < gap then
			return false
		end
	end
	return true
end

-- a lot at radius r (middle) and angle a, facing the ring road (in: the road is further in)
local function lot(id: string, zone: string, ring: Ring, r: number, a: number, roadIn: boolean, width: number, depth: number): Lot
	local p = polar(r, a, ring.y)
	local towardRoad = (polar(ring.radius, a, ring.y) - p).Unit
	local _ = roadIn
	return { id = id, zone = zone, frame = CFrame.lookAt(p, p + towardRoad), width = width, depth = depth }
end

function IsleLayout.lots(): { Lot }
	local out: { Lot } = {}
	-- low tier: inside the island ring either side of the causeway (street houses)
	local isleJoins = {}
	for _, j in IsleLayout.joins("isle") do
		table.insert(isleJoins, j.angle)
	end
	table.insert(isleJoins, IsleLayout.FountainAngle)
	local L = I.Low
	local rLow = I.Ring - HALF - 8 - L.depth / 2
	local n = 0
	local step = (L.width + 14) / rLow
	local a = -L.arc
	while a <= L.arc + 1e-6 do
		-- (clear of the junctions and the low climb's first switchback)
		if math.abs(a) > L.skip and angleClear(a, isleJoins, step * 0.9) then
			n += 1
			table.insert(out, lot(`low_{n}`, "low", R.isle, rLow, a, false, L.width, L.depth))
		end
		a += step
	end
	-- mid tier: outside the mid ring on the terrace, looking out to sea
	local midJoins = {}
	for _, j in IsleLayout.joins("mid") do
		table.insert(midJoins, j.angle)
	end
	local M = I.Mid
	local rMid = M.ring + HALF + 8 + M.lotDepth / 2
	for k = 0, M.lots - 1 do
		local am = (k + 0.5) / M.lots * 2 * math.pi
		if angleClear(am, midJoins, (M.lotWidth / 2 + HALF + 20) / rMid) then
			table.insert(out, lot(`mid_{k + 1}`, "mid", R.mid, rMid, am, false, M.lotWidth, M.lotDepth))
		end
	end
	-- high tier: round the top ring, in the gated community
	local T = I.Top
	local rTop = T.ring + HALF + 6 + T.lotDepth / 2
	local h = 0
	for k = 1, TOP_SLOTS - 1 do
		local at = topSlot(k)
		if at ~= IsleLayout.HelipadAngle and at ~= IsleLayout.LookoutAngle then
			h += 1
			table.insert(out, lot(`high_{h}`, "high", R.top, rTop, at, false, T.lotWidth, T.lotDepth))
		end
	end
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
		{ id = "isle", name = "Legends Isle", cf = onRing(R.isle, 0.32) },
		{ id = "isle_mid", name = "Legends Isle Heights", cf = onRing(R.mid, 0.4) },
		{ id = "isle_top", name = "The Summit (gated)", cf = onRing(R.top, IsleLayout.Roads[2].toAngle + 0.6) },
	}
end

return IsleLayout
