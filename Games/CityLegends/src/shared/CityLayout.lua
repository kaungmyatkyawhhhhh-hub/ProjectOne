--[[
	CityLayout
	Pure maths shared by server (building the city) and client (traffic AI):
	  * grid / road coordinates
	  * deterministic traffic-light phases (driven by synced server time, so every
	    client sees the same lights at the same moment)
	  * the lane graph that NPC cars drive on (lanes + turn connectors as
	    quadratic bezier curves)
]]

local Config = require(script.Parent.Config)
local IsleLayout = require(script.Parent.IsleLayout)

local CityLayout = {}

local C = Config.City
local N = C.Blocks
local HALF_ROAD = C.RoadWidth / 2

CityLayout.N = N
CityLayout.HalfRoad = HALF_ROAD
CityLayout.StopLineGap = 3

-- 1 = East(+X), 2 = South(+Z), 3 = West(-X), 4 = North(-Z)
CityLayout.Dirs = {
	Vector3.new(1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, -1),
}
local DI = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }

-- road i's coordinate (x for i, z for j). Downtown in the west has its own grid along x: road
-- indices from Config.West.IndexBase (100 .. 106), the same z roads as the city
local DT_BASE = Config.West.IndexBase
local DT_X = Config.West.DowntownX
function CityLayout.roadCoord(i: number): number
	if i >= DT_BASE - 1 then
		return DT_X + (i - DT_BASE - N / 2) * C.BlockSize
	end
	return (i - N / 2) * C.BlockSize
end
CityLayout.DowntownBase = DT_BASE

function CityLayout.intersectionPos(i: number, j: number): Vector3
	return Vector3.new(CityLayout.roadCoord(i), 0, CityLayout.roadCoord(j))
end

function CityLayout.inGrid(i: number, j: number): boolean
	return ((i >= 0 and i <= N) or (i >= DT_BASE and i <= DT_BASE + N)) and j >= 0 and j <= N
end

-- the grids' first road indices along x (the city, Downtown)
CityLayout.GridBases = { 0, DT_BASE }

function CityLayout.laneOffset(lane: number): number
	return C.LaneWidth * (lane - 0.5)
end

-- the east-side intersection where the highway leaves the city
CityLayout.HighwayJ = math.floor(N / 2)
CityLayout.HighwayStartX = CityLayout.roadCoord(N) + HALF_ROAD

---------------------------------------------------------------------
-- Monorail loop (rounded square around the city, shared by server + client)
---------------------------------------------------------------------
local function monorailDims(): (number, number, number)
	local R = C.HalfExtent + HALF_ROAD + Config.Monorail.Offset
	local rc = Config.Monorail.CornerRadius
	local side = 2 * (R - rc)
	return R, rc, side
end

function CityLayout.monorailLength(): number
	local _, rc, side = monorailDims()
	return 4 * side + 2 * math.pi * rc
end

-- Position (at track height) and travel direction at distance s along the loop
function CityLayout.monorailSample(s: number): (Vector3, Vector3)
	local R, rc, side = monorailDims()
	local arc = math.pi / 2 * rc
	local h = Config.Monorail.Height
	local c = R - rc
	s = s % CityLayout.monorailLength()
	-- side starts / directions, then the corner after each side
	local sides = {
		{ Vector3.new(R, h, -c), Vector3.new(0, 0, 1), Vector3.new(c, h, c), 0 },
		{ Vector3.new(c, h, R), Vector3.new(-1, 0, 0), Vector3.new(-c, h, c), math.pi / 2 },
		{ Vector3.new(-R, h, c), Vector3.new(0, 0, -1), Vector3.new(-c, h, -c), math.pi },
		{ Vector3.new(-c, h, -R), Vector3.new(1, 0, 0), Vector3.new(c, h, -c), math.pi * 1.5 },
	}
	for _, sd in sides do
		if s <= side then
			return sd[1] + sd[2] * s, sd[2]
		end
		s -= side
		if s <= arc then
			local a = sd[4] + s / rc
			return sd[3] + Vector3.new(math.cos(a), 0, math.sin(a)) * rc, Vector3.new(-math.sin(a), 0, math.cos(a))
		end
		s -= arc
	end
	return sides[1][1], sides[1][2]
end

---------------------------------------------------------------------
-- Legends Loop: the highway ring round the map (rounded square, clockwise seen from above:
-- down the east side towards +Z, west along the south, up the west side, east along the north)
---------------------------------------------------------------------
local LOOP_S = C.LoopHalf
local LOOP_R = C.LoopCorner
local LOOP_C = LOOP_S - LOOP_R
local LOOP_SIDE = 2 * LOOP_C
local LOOP_ARC = math.pi / 2 * LOOP_R
CityLayout.LoopHalf = LOOP_S
CityLayout.LoopCorner = LOOP_R

function CityLayout.loopLength(): number
	return 4 * (LOOP_SIDE + LOOP_ARC)
end

-- the loop's centre line at distance s (from the east side's north end): position and direction
-- of clockwise travel; s also gives the offset to the right of that direction
function CityLayout.loopSample(s: number, offset: number?): (Vector3, Vector3)
	s = s % CityLayout.loopLength()
	local sides = {
		{ Vector3.new(LOOP_S, 0, -LOOP_C), Vector3.new(0, 0, 1), Vector3.new(LOOP_C, 0, LOOP_C), 0 },
		{ Vector3.new(LOOP_C, 0, LOOP_S), Vector3.new(-1, 0, 0), Vector3.new(-LOOP_C, 0, LOOP_C), math.pi / 2 },
		{ Vector3.new(-LOOP_S, 0, LOOP_C), Vector3.new(0, 0, -1), Vector3.new(-LOOP_C, 0, -LOOP_C), math.pi },
		{ Vector3.new(-LOOP_C, 0, -LOOP_S), Vector3.new(1, 0, 0), Vector3.new(LOOP_C, 0, -LOOP_C), math.pi * 1.5 },
	}
	local off = offset or 0
	for _, sd in sides do
		if s <= LOOP_SIDE then
			local dir = sd[2]
			return sd[1] + dir * s + dir:Cross(Vector3.yAxis) * off, dir
		end
		s -= LOOP_SIDE
		if s <= LOOP_ARC then
			local a = sd[4] + s / LOOP_R
			local radial = Vector3.new(math.cos(a), 0, math.sin(a))
			local dir = Vector3.new(-math.sin(a), 0, math.cos(a))
			-- right of clockwise travel is towards the centre of the corner
			return sd[3] + radial * (LOOP_R - off), dir
		end
		s -= LOOP_ARC
	end
	return sides[1][1], sides[1][2]
end

---------------------------------------------------------------------
-- Traffic lights
---------------------------------------------------------------------
-- axis: "X" for traffic moving along X (east/west), "Z" otherwise
function CityLayout.lightState(i: number, j: number, axis: string, t: number): string
	local L = Config.Lights
	local half = L.Green + L.Yellow + L.AllRed
	local offset = ((i + j) % 4) * (L.Cycle / 4)
	local ph = (t + offset) % L.Cycle
	local localT = if axis == "X" then ph else (ph - half) % L.Cycle
	if localT < L.Green then
		return "G"
	elseif localT < L.Green + L.Yellow then
		return "Y"
	end
	return "R"
end

-- time left in the current state (used so cars can decide to run a yellow)
function CityLayout.lightTimeLeft(i: number, j: number, axis: string, t: number): number
	local L = Config.Lights
	local half = L.Green + L.Yellow + L.AllRed
	local offset = ((i + j) % 4) * (L.Cycle / 4)
	local ph = (t + offset) % L.Cycle
	local localT = if axis == "X" then ph else (ph - half) % L.Cycle
	if localT < L.Green then
		return L.Green - localT
	elseif localT < L.Green + L.Yellow then
		return L.Green + L.Yellow - localT
	end
	return L.Cycle - localT
end

---------------------------------------------------------------------
-- Lane graph
---------------------------------------------------------------------
export type Segment = {
	id: number,
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	length: number,
	kind: string, -- "lane" | "turn"
	i: number, -- intersection this lane leads to (lanes) / is inside (turns)
	j: number,
	axis: string,
	dir: number,
	lane: number,
	turning: boolean, -- connector that changes direction
	signal: boolean, -- a traffic light stands at its end (city lanes)
	speedK: number, -- traffic's speed on it, times its normal speed (highway: faster)
	private: boolean?, -- in the gated community (traffic keeps out)
	mountain: boolean?, -- Legends Isle's climbs and mid ring (traffic keeps it quiet)
	turnSpeed: number?, -- mph for this connector (highway ramps), else the city's turn speed
	next: { Segment },
	samples: { number }, -- cumulative arc length per sample (for turns)
}

local SAMPLES = 12

local function bezier(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	local u = 1 - t
	return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t)
end

local function bezierTangent(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	return (p1 - p0) * (2 * (1 - t)) + (p2 - p1) * (2 * t)
end

local function newSegment(list: { Segment }, p0: Vector3, p1: Vector3, p2: Vector3, kind: string): Segment
	local samples = { 0 }
	local total = 0
	local prev = p0
	for k = 1, SAMPLES do
		local pt = bezier(p0, p1, p2, k / SAMPLES)
		total += (pt - prev).Magnitude
		samples[k + 1] = total
		prev = pt
	end
	local seg: Segment = {
		id = #list + 1,
		p0 = p0,
		p1 = p1,
		p2 = p2,
		length = total,
		kind = kind,
		i = 0,
		j = 0,
		axis = "X",
		dir = 1,
		lane = 1,
		turning = false,
		signal = false,
		speedK = 1,
		next = {},
		samples = samples,
	}
	table.insert(list, seg)
	return seg
end

-- distance along -> bezier parameter t
local function distToT(seg: Segment, s: number): number
	if seg.kind == "lane" then
		return math.clamp(s / seg.length, 0, 1)
	end
	local samples = seg.samples
	if s <= 0 then
		return 0
	end
	for k = 2, #samples do
		if samples[k] >= s then
			local a, b = samples[k - 1], samples[k]
			local f = if b > a then (s - a) / (b - a) else 0
			return ((k - 2) + f) / SAMPLES
		end
	end
	return 1
end

-- Returns world position (on the ground) and unit forward direction
function CityLayout.sample(seg: Segment, s: number): (Vector3, Vector3)
	local t = distToT(seg, s)
	local pos = bezier(seg.p0, seg.p1, seg.p2, t)
	local tan = bezierTangent(seg.p0, seg.p1, seg.p2, t)
	if tan.Magnitude < 1e-4 then
		tan = seg.p2 - seg.p0
	end
	return pos, tan.Unit
end

-- quadratic pieces along the loop for one lane: offset to the right of clockwise travel, and
-- the travel direction (1 clockwise, -1 the other way); from loop distance s0 to s1
local function loopPieces(list: { Segment }, s0: number, s1: number, offset: number, way: number): { Segment }
	local out = {}
	local L = CityLayout.loopLength()
	-- cut at every side / corner boundary, corners in 15 degree pieces
	local cuts = { s0 }
	local edge = 0
	local bounds = {}
	for _ = 1, 4 do
		table.insert(bounds, edge + LOOP_SIDE)
		for k = 1, 6 do
			table.insert(bounds, edge + LOOP_SIDE + LOOP_ARC * k / 6)
		end
		edge += LOOP_SIDE + LOOP_ARC
	end
	for _, b in bounds do
		for _, bb in { b, b + L } do
			if bb > s0 + 0.5 and bb < s1 - 0.5 then
				table.insert(cuts, bb)
			end
		end
	end
	table.insert(cuts, s1)
	table.sort(cuts)
	for k = 1, #cuts - 1 do
		local a, b = cuts[k], cuts[k + 1]
		local pa, da = CityLayout.loopSample(a, offset)
		local pb, db = CityLayout.loopSample(b, offset)
		-- control point: where the two tangents meet (a straight piece: the middle)
		local p1 = (pa + pb) / 2
		local cross = da:Cross(db).Y
		if math.abs(cross) > 1e-4 then
			local t = (pb - pa):Cross(db).Y / cross
			p1 = pa + da * t
		end
		local seg = if way == 1 then newSegment(list, pa, p1, pb, if math.abs(cross) > 1e-4 then "hwy" else "lane") else newSegment(list, pb, p1, pa, if math.abs(cross) > 1e-4 then "hwy" else "lane")
		table.insert(out, seg)
	end
	if way == -1 then
		local rev = {}
		for k = #out, 1, -1 do
			table.insert(rev, out[k])
		end
		out = rev
	end
	return out
end

local function chain(segs: { Segment })
	for k = 1, #segs - 1 do
		table.insert(segs[k].next, segs[k + 1])
	end
end

local function connector(list: { Segment }, a: Segment, b: Segment, corner: Vector3?, turnSpeed: number?): Segment
	local p0, p2 = a.p2, b.p0
	local con = newSegment(list, p0, corner or (p0 + p2) / 2, p2, "turn")
	con.i, con.j = -1, -1
	con.dir = b.dir
	con.lane = b.lane
	con.turning = corner ~= nil
	con.turnSpeed = turnSpeed
	con.speedK = C.HighwaySpeedK
	con.next = { b }
	table.insert(a.next, con)
	return con
end

-- Builds the highway lanes (owner, 2026-10-17: traffic on the highway). The spur meets the loop's
-- east side at z = 0 with two right turns only (spur -> loop clockwise, loop clockwise -> spur), so
-- no traffic ever crosses another lane. Westbound, the spur's two inner lanes run into the city
-- (with the city's light at its edge); its outer lane merges first.
function CityLayout.addHighway(all: { Segment }, lanes: { Segment }, byKey: { [string]: Segment })
	local LW = C.LaneWidth
	local nL = C.HighwayLanesPerSide
	local HWh = C.HighwayWidth / 2
	local L = CityLayout.loopLength()
	local xCity = CityLayout.HighwayStartX -- the city's road edge
	local xEnd = LOOP_S - HWh - 50 -- where the spur's lanes end / start at the loop
	local zTurn = 86 -- the loop lanes split / join this far either side of the spur
	local j = CityLayout.HighwayJ
	local function mark(seg: Segment, dir: number, lane: number)
		seg.i, seg.j = -1, -1
		seg.dir = dir
		seg.lane = lane
		seg.axis = "X"
		seg.speedK = C.HighwaySpeedK
		table.insert(lanes, seg)
	end
	-- loop distance of a point on the east side at z (east side runs from z = -LOOP_C at s = 0)
	local function eastS(z: number): number
		return z + LOOP_C
	end
	local cw: { { Segment } } = {}
	for l = 1, nL do
		local off = LW * (l - 0.5)
		-- clockwise: three runs on the east side's junction stretch, then all the way round
		local a = loopPieces(all, eastS(zTurn), eastS(-zTurn) + L, off, 1)
		local b = loopPieces(all, eastS(-zTurn), eastS(zTurn), off, 1)
		for _, sg in a do
			mark(sg, 11, l)
		end
		for _, sg in b do
			mark(sg, 11, l)
		end
		chain(a)
		chain(b)
		table.insert(a[#a].next, b[1])
		table.insert(b[#b].next, a[1])
		cw[l] = { a[#a], a[1] } -- the piece before the split, and the piece after the join
		-- the other way round: one closed ring
		local r = loopPieces(all, 0, L, -off, -1) -- (on the outer half: its own right)
		for _, sg in r do
			mark(sg, 12, l)
		end
		chain(r)
		table.insert(r[#r].next, r[1])
	end
	-- the spur
	local xSplit = xCity + 250 -- westbound: the outer lane has merged by here
	local westNear: { Segment } = {}
	for l = 1, nL do
		local z = LW * (l - 0.5)
		-- eastbound (on +Z): from the city's edge to the loop; the outer lane starts past the city
		local x0 = if l <= C.LanesPerSide then xCity else xSplit
		local east = newSegment(all, Vector3.new(x0, 0, z), Vector3.new((x0 + xEnd) / 2, 0, z), Vector3.new(xEnd, 0, z), "lane")
		mark(east, 13, l)
		if l <= C.LanesPerSide then
			byKey[`{N},{j},1,{l}`] = east
		end
		-- right turn onto the clockwise loop (each lane's turn round the same corner)
		connector(all, east, cw[l][2], Vector3.new(LOOP_S - z, 0, z), 45)
		-- westbound (on -Z): a right turn off the clockwise loop, then towards the city
		local westStart = Vector3.new(xEnd, 0, -z)
		local farEnd = if l <= C.LanesPerSide then xSplit else xSplit + 140 -- (room to merge)
		local far = newSegment(all, westStart, Vector3.new((xEnd + farEnd) / 2, 0, -z), Vector3.new(farEnd, 0, -z), "lane")
		mark(far, 14, l)
		connector(all, cw[l][1], far, Vector3.new(LOOP_S - z, 0, -z), 45)
		if l <= C.LanesPerSide then
			local stop = Vector3.new(xCity + CityLayout.StopLineGap, 0, -z)
			local near = newSegment(all, Vector3.new(xSplit, 0, -z), Vector3.new((xSplit + stop.X) / 2, 0, -z), stop, "lane")
			mark(near, 3, l)
			-- the city's light at its edge: the east approach into the edge intersection
			near.i, near.j = N, j
			near.signal = true
			table.insert(far.next, near)
			westNear[l] = near
		else
			-- the outer lane merges into the one beside it
			local con = connector(all, far, westNear[C.LanesPerSide], nil, nil)
			con.dir = 14
		end
	end
end

---------------------------------------------------------------------
-- The west (Config.West, WestLayout): road heights and lanes
---------------------------------------------------------------------
local WEST = Config.West

-- smooth ramp between two heights (no kink at either end)
local function ramp(v: number, a: number, b: number, y0: number, y1: number): number
	local t = math.clamp((v - a) / (b - a), 0, 1)
	t = t * t * (3 - 2 * t)
	return y0 + (y1 - y0) * t
end

-- the coastal highway's deck height at x (0 on the ground): up onto the viaduct over the harbour,
-- the suburbs and the loop, down in the countryside, up over the river on the bridge, down into
-- Downtown
function CityLayout.westRoadY(x: number): number
	if x > WEST.ViaductUp[1] then
		return 0
	elseif x > WEST.ViaductUp[2] then
		return ramp(x, WEST.ViaductUp[1], WEST.ViaductUp[2], 0, WEST.ViaductY)
	elseif x > WEST.ViaductDown[1] then
		return WEST.ViaductY
	elseif x > WEST.ViaductDown[2] then
		return ramp(x, WEST.ViaductDown[1], WEST.ViaductDown[2], WEST.ViaductY, 0)
	elseif x > WEST.BridgeUp[1] then
		return 0
	elseif x > WEST.BridgeUp[2] then
		return ramp(x, WEST.BridgeUp[1], WEST.BridgeUp[2], 0, WEST.DeckY)
	elseif x > WEST.BridgeDown[1] then
		return WEST.DeckY
	elseif x > WEST.BridgeDown[2] then
		return ramp(x, WEST.BridgeDown[1], WEST.BridgeDown[2], WEST.DeckY, 0)
	end
	return 0
end

-- island roads over the sea (the causeway and the bridges between the islands), at distance d
-- along a road of length len: up off the land at its start (landA long), level over the sea, down
-- onto the land at its end (landB long)
function CityLayout.seaRoadY(d: number, len: number, landA: number, landB: number): number
	local y = WEST.CausewayY
	if d < landA + 120 then
		return ramp(d, landA - 40, landA + 120, 0, y)
	elseif d > len - landB - 120 then
		return ramp(d, len - landB - 120, len - landB + 40, y, 0)
	end
	return y
end

-- where two lanes' straight lines meet (a turn's control point); the middle if they're parallel
local function cornerOf(a: Segment, b: Segment): Vector3
	local pa, pb = a.p2, b.p0
	local da = (a.p2 - a.p1)
	local db = (b.p1 - b.p0)
	da = Vector3.new(da.X, 0, da.Z)
	db = Vector3.new(db.X, 0, db.Z)
	if da.Magnitude < 1e-3 or db.Magnitude < 1e-3 then
		return (pa + pb) / 2
	end
	da, db = da.Unit, db.Unit
	local cross = da:Cross(db).Y
	if math.abs(cross) < 1e-3 then
		return (pa + pb) / 2
	end
	local t = (pb - pa):Cross(db).Y / cross
	local c = pa + da * t
	return Vector3.new(c.X, (pa.Y + pb.Y) / 2, c.Z)
end

-- one direction of a straight road from a to b (centre line, y from yAt(distance)), nL lanes to
-- the right of travel; cut into short pieces where the height changes, long ones where it's
-- level. Returns each lane's pieces, chained, in travel order.
local function oneWay(all: { Segment }, lanes: { Segment }, a: Vector3, b: Vector3, nL: number, yAt: (number) -> number, code: number, speedK: number, endGap: number?): { { Segment } }
	local flatDir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flatDir.Magnitude - (endGap or 0)
	local dir = flatDir.Unit
	local right = dir:Cross(Vector3.yAxis)
	local STEP = 40
	-- the cut distances
	local cuts = { 0 }
	local d = 0
	while d < len do
		local nd = math.min(d + STEP, len)
		local level = math.abs(yAt(d) - yAt(nd)) < 1e-3 and math.abs(yAt((d + nd) / 2) - yAt(d)) < 1e-3
		local last = cuts[#cuts]
		-- merge level steps into the piece before (when that one is level too), up to 1200 long
		if level and #cuts >= 2 and nd - cuts[#cuts - 1] <= 1200 and math.abs(yAt(cuts[#cuts - 1]) - yAt(last)) < 1e-3 and math.abs(yAt((cuts[#cuts - 1] + last) / 2) - yAt(last)) < 1e-3 then
			cuts[#cuts] = nd
		else
			table.insert(cuts, nd)
		end
		d = nd
	end
	local out: { { Segment } } = {}
	for l = 1, nL do
		local off = right * (C.LaneWidth * (l - 0.5))
		local chainL: { Segment } = {}
		for k = 1, #cuts - 1 do
			local d0, d1 = cuts[k], cuts[k + 1]
			local function at(dd: number): Vector3
				local p = a + dir * dd + off
				return Vector3.new(p.X, yAt(dd), p.Z)
			end
			local seg = newSegment(all, at(d0), at((d0 + d1) / 2), at(d1), "lane")
			seg.i, seg.j = -1, -1
			seg.dir = code
			seg.lane = l
			seg.axis = if math.abs(dir.X) > 0.5 then "X" else "Z"
			seg.speedK = speedK
			table.insert(lanes, seg)
			table.insert(chainL, seg)
		end
		chain(chainL)
		out[l] = chainL
	end
	return out
end

-- an island's ring road, one lane each way, cut either side of each junction angle. Returns, per
-- junction: the pieces leaving it and arriving at it in each direction.
type RingJoin = { ccwOut: Segment, ccwIn: Segment, cwOut: Segment, cwIn: Segment }
local function islandRing(all: { Segment }, lanes: { Segment }, center: Vector3, radius: number, joinsAt: { number }, gaps: { number }): { RingJoin }
	local TAU = 2 * math.pi
	local cuts: { number } = {}
	local function near(a: number): boolean
		for k, j in joinsAt do
			local dd = (a - j) % TAU
			dd = math.min(dd, TAU - dd)
			if dd < gaps[k] + 0.05 then
				return true
			end
		end
		return false
	end
	for k = 0, 23 do
		local a = k / 24 * TAU
		if not near(a) then
			table.insert(cuts, a)
		end
	end
	for k, j in joinsAt do
		table.insert(cuts, (j - gaps[k]) % TAU)
		table.insert(cuts, (j + gaps[k]) % TAU)
	end
	table.sort(cuts)
	local n = #cuts
	local function piece(a0: number, a1: number, rr: number, way: number): Segment
		-- a0 -> a1 going the `way` round (1 = increasing angle)
		local span = if way == 1 then (a1 - a0) % TAU else -((a0 - a1) % TAU)
		local function p(a: number): Vector3
			return center + Vector3.new(math.cos(a), 0, math.sin(a)) * rr
		end
		local mid = a0 + span / 2
		-- control point: where the end tangents meet (on the bisector, rr / cos(half span) out)
		local c = center + Vector3.new(math.cos(mid), 0, math.sin(mid)) * (rr / math.cos(span / 2))
		local seg = newSegment(all, p(a0), c, p(a0 + span), "hwy")
		seg.i, seg.j = -1, -1
		seg.dir = if way == 1 then 31 else 32
		seg.lane = 1
		seg.axis = "X"
		seg.speedK = 0.75
		table.insert(lanes, seg)
		return seg
	end
	local ccw: { Segment } = {}
	local cw: { Segment } = {}
	local LW2 = C.LaneWidth / 2
	for k = 1, n do
		local a0, a1 = cuts[k], cuts[(k % n) + 1]
		-- right of anticlockwise (increasing angle) travel is towards the centre
		ccw[k] = piece(a0, a1, radius - LW2, 1)
		cw[k] = piece(a1, a0, radius + LW2, -1)
	end
	for k = 1, n do
		table.insert(ccw[k].next, ccw[(k % n) + 1])
		table.insert(cw[(k % n) + 1].next, cw[k])
	end
	local function startsAt(list: { Segment }, a: number, rr: number): Segment
		local target = center + Vector3.new(math.cos(a), 0, math.sin(a)) * rr
		local best, bd = list[1], math.huge
		for _, sg in list do
			local dd = (sg.p0 - target).Magnitude
			if dd < bd then
				best, bd = sg, dd
			end
		end
		return best
	end
	local function endsAt(list: { Segment }, a: number, rr: number): Segment
		local target = center + Vector3.new(math.cos(a), 0, math.sin(a)) * rr
		local best, bd = list[1], math.huge
		for _, sg in list do
			local dd = (sg.p2 - target).Magnitude
			if dd < bd then
				best, bd = sg, dd
			end
		end
		return best
	end
	local out: { RingJoin } = {}
	for k, j in joinsAt do
		local g = gaps[k]
		out[k] = {
			ccwOut = startsAt(ccw, j + g, radius - LW2),
			ccwIn = endsAt(ccw, j - g, radius - LW2),
			cwOut = startsAt(cw, j - g, radius + LW2),
			cwIn = endsAt(cw, j + g, radius + LW2),
		}
	end
	return out
end

-- a spur's lanes meeting a ring road at a junction: in -> both ways round, both ways round -> out
local function joinRing(all: { Segment }, join: RingJoin, spurIn: { { Segment } }, spurOut: { { Segment } })
	local nL = #spurIn
	local inR, inL = spurIn[nL][#spurIn[nL]], spurIn[1][#spurIn[1]]
	connector(all, inR, join.cwOut, cornerOf(inR, join.cwOut), 18).speedK = 1
	connector(all, inL, join.ccwOut, cornerOf(inL, join.ccwOut), 18).speedK = 1
	local outR, outL = spurOut[#spurOut][1], spurOut[1][1]
	connector(all, join.cwIn, outR, cornerOf(join.cwIn, outR), 18).speedK = 1
	connector(all, join.ccwIn, outL, cornerOf(join.ccwIn, outL), 18).speedK = 1
	-- (and from the ring into the other lane too: lanes never change elsewhere, so with every spur
	-- two lanes wide the network would split in two, the inside lanes' and the outside lanes')
	if outL ~= outR then
		connector(all, join.cwIn, outL, cornerOf(join.cwIn, outL), 18).speedK = 1
		connector(all, join.ccwIn, outR, cornerOf(join.ccwIn, outR), 18).speedK = 1
	end
end

-- an island road (IsleLayout.Roads): straight legs between its corners, one lane each way, joined
-- by turns (the climbs' arcs bend a little at each corner and keep climbing through it; the
-- hairpins are level). Returns the lanes along the corners' order and back, as oneWay does (one
-- lane: { { first .. last } }).
local function isleRoad(all: { Segment }, lanes: { Segment }, rd: IsleLayout.Road, code: number): ({ { Segment } }, { { Segment } })
	local function build(pts: { Vector3 }, level: { boolean }, c: number): { Segment }
		local chainAll: { Segment } = {}
		local prevLast: Segment? = nil
		for k = 1, #pts - 1 do
			local a, b = pts[k], pts[k + 1]
			local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			local len = flat.Magnitude
			local dir = flat.Unit
			local t0, t1 = IsleLayout.trim(pts, k), IsleLayout.trim(pts, k + 1)
			local y0, y1, f0, f1 = a.Y, b.Y, level[k], level[k + 1]
			local out = oneWay(all, lanes, Vector3.new(a.X, 0, a.Z) + dir * t0, Vector3.new(b.X, 0, b.Z) - dir * t1, 1, function(d)
				return IsleLayout.legY(y0, y1, len, d + t0, f0, f1)
			end, c, 0.8)
			local chainL = out[1]
			if prevLast then
				connector(all, prevLast, chainL[1], cornerOf(prevLast, chainL[1]), 18)
			end
			for _, sg in chainL do
				table.insert(chainAll, sg)
			end
			prevLast = chainL[#chainL]
		end
		return chainAll
	end
	local back, backLevel = {}, {}
	for k = #rd.pts, 1, -1 do
		table.insert(back, rd.pts[k])
		table.insert(backLevel, rd.level[k])
	end
	return { build(rd.pts, rd.level, code) }, { build(back, backLevel, code + 1) }
end

-- The west's lanes (owner, 2026-10-22): the coastal highway from the city's west edge to
-- Downtown's east edge (two lanes each way, joining both grids' lights), the causeway from Ocean
-- Drive to Legends Isle and the island's ring roads and climbs (IsleLayout)
function CityLayout.addWest(all: { Segment }, lanes: { Segment }, byKey: { [string]: Segment })
	local j = CityLayout.HighwayJ
	local nL = C.LanesPerSide
	local gap = CityLayout.StopLineGap
	local cityEdge = Vector3.new(CityLayout.roadCoord(0) - HALF_ROAD, 0, CityLayout.roadCoord(j))
	local dtE = DT_BASE + N
	local dtEdge = Vector3.new(CityLayout.roadCoord(dtE) + HALF_ROAD, 0, CityLayout.roadCoord(j))
	local function hwyY(xStart: number, sign: number): (number) -> number
		return function(d: number): number
			return CityLayout.westRoadY(xStart + sign * d)
		end
	end
	-- westbound, city -> Downtown
	local west = oneWay(all, lanes, cityEdge, dtEdge, nL, hwyY(cityEdge.X, -1), 15, C.HighwaySpeedK, gap)
	-- eastbound, Downtown -> city
	local east = oneWay(all, lanes, dtEdge, cityEdge, nL, hwyY(dtEdge.X, 1), 16, C.HighwaySpeedK, gap)
	for l = 1, nL do
		byKey[`0,{j},3,{l}`] = west[l][1]
		local wl = west[l][#west[l]]
		wl.i, wl.j, wl.dir, wl.signal = dtE, j, 3, true
		byKey[`{dtE},{j},1,{l}`] = east[l][1]
		local el = east[l][#east[l]]
		el.i, el.j, el.dir, el.signal = 0, j, 1, true
	end

	-- the causeway, Ocean Drive -> Legends Isle's ring road (and back)
	local I = WEST.Isle
	local beachEdge = Vector3.new(CityLayout.roadCoord(DT_BASE) - HALF_ROAD, 0, CityLayout.roadCoord(j))
	local isleEnd = Vector3.new(IsleLayout.CausewayEnd, 0, CityLayout.roadCoord(j))
	local cLen = beachEdge.X - isleEnd.X
	local seaA = beachEdge.X - WEST.BeachWest -- the beach, then the sea
	local seaB = (I.x + I.r) - isleEnd.X -- the island's shore to the ring road
	local cwW = oneWay(all, lanes, beachEdge, isleEnd, nL, function(d)
		return CityLayout.seaRoadY(d, cLen, seaA, seaB)
	end, 21, 1.1)
	local cwE = oneWay(all, lanes, isleEnd, beachEdge, nL, function(d)
		return CityLayout.seaRoadY(d, cLen, seaB, seaA)
	end, 22, 1.1, gap)
	for l = 1, nL do
		byKey[`{DT_BASE},{j},3,{l}`] = cwW[l][1]
		local last = cwE[l][#cwE[l]]
		last.i, last.j, last.dir, last.signal = DT_BASE, j, 1, true
	end

	-- Legends Isle (IsleLayout): its ring roads and the climbs between them. The gated community's
	-- roads are private (traffic stays out; Gate checks who drives in).
	local function markPrivate(from: number)
		for k = from + 1, #all do
			all[k].private = true
		end
	end
	local function markMountain(from: number)
		for k = from + 1, #all do
			all[k].mountain = true
		end
	end
	local rings: { [string]: { RingJoin } } = {}
	local joinIdx: { [string]: { [string]: number } } = {}
	for id, ring in IsleLayout.Rings do
		local js = IsleLayout.joins(id)
		local angles, gaps = {}, {}
		joinIdx[id] = {}
		for k, jn in js do
			angles[k], gaps[k] = jn.angle, jn.gap
			joinIdx[id][jn.road] = k
		end
		local before = #all
		rings[id] = islandRing(all, lanes, ring.center, ring.radius, angles, gaps)
		if ring.private then
			markPrivate(before)
		end
		if id ~= "isle" then
			markMountain(before)
		end
	end
	joinRing(all, rings.isle[joinIdx.isle.causeway], cwW, cwE)
	for k, rd in IsleLayout.Roads do
		local before = #all
		local fwd, back = isleRoad(all, lanes, rd, 40 + k * 2)
		markMountain(before)
		joinRing(all, rings[rd.from][joinIdx[rd.from][rd.id]], back, fwd)
		joinRing(all, rings[rd.to][joinIdx[rd.to][rd.id]], fwd, back)
		if rd.private then
			markPrivate(before)
		end
	end
end

local cachedGraph: { lanes: { Segment }, all: { Segment } }? = nil

function CityLayout.buildGraph(): { lanes: { Segment }, all: { Segment } }
	if cachedGraph then
		return cachedGraph
	end
	local all: { Segment } = {}
	local lanes: { Segment } = {}
	local byKey: { [string]: Segment } = {}
	local lanesPerSide = C.LanesPerSide

	-- straight lane segments between intersections (the city's grid and Downtown's)
	for _, ib in CityLayout.GridBases do
		for i = ib, ib + N do
			for j = 0, N do
				local a = CityLayout.intersectionPos(i, j)
				for k = 1, 4 do
					local ni, nj = i + DI[k][1], j + DI[k][2]
					if CityLayout.inGrid(ni, nj) then
						local dir = CityLayout.Dirs[k]
						local right = dir:Cross(Vector3.yAxis)
						local b = CityLayout.intersectionPos(ni, nj)
						for l = 1, lanesPerSide do
							local off = right * CityLayout.laneOffset(l)
							local p0 = a + dir * HALF_ROAD + off
							local p2 = b - dir * (HALF_ROAD + CityLayout.StopLineGap) + off
							local seg = newSegment(all, p0, (p0 + p2) / 2, p2, "lane")
							seg.i, seg.j = ni, nj
							seg.dir = k
							seg.lane = l
							seg.axis = if k % 2 == 1 then "X" else "Z"
							seg.signal = true
							byKey[`{i},{j},{k},{l}`] = seg
							table.insert(lanes, seg)
						end
					end
				end
			end
		end
	end

	-- the highway: the spur from the city's east edge to the loop, and the loop itself
	CityLayout.addHighway(all, lanes, byKey)
	-- the west: the coastal highway to Downtown, the causeway and the islands
	CityLayout.addWest(all, lanes, byKey)

	-- connectors through each intersection
	for _, seg in lanes do
		if seg.i < 0 then
			continue -- highway lanes are joined up by addHighway
		end
		local bi, bj = seg.i, seg.j
		local k = seg.dir
		local dir = CityLayout.Dirs[k]
		local options = {}
		local fallback = {}
		for _, turn in { "straight", "right", "left" } do
			local k2 = if turn == "straight" then k elseif turn == "right" then (k % 4) + 1 else ((k + 2) % 4) + 1
			local ni, nj = bi + DI[k2][1], bj + DI[k2][2]
			-- (straight on out of the grid only where the highway leaves it)
			if CityLayout.inGrid(ni, nj) or byKey[`{bi},{bj},{k2},{seg.lane}`] then
				local allowed = turn == "straight" or (turn == "right" and seg.lane == lanesPerSide) or (turn == "left" and seg.lane == 1)
				local targetLane = seg.lane
				local target = byKey[`{bi},{bj},{k2},{targetLane}`]
				if target then
					table.insert(if allowed then options else fallback, { target = target, straight = turn == "straight" })
				end
			end
		end
		if #options == 0 then
			options = fallback
		end
		for _, opt in options do
			local p0 = seg.p2
			local p2 = opt.target.p0
			local p1 = if opt.straight then (p0 + p2) / 2 else p0 + dir * (p2 - p0):Dot(dir)
			local con = newSegment(all, p0, p1, p2, "turn")
			con.i, con.j = bi, bj
			con.dir = opt.target.dir
			con.lane = opt.target.lane
			con.axis = seg.axis
			con.turning = not opt.straight
			con.next = { opt.target }
			table.insert(seg.next, con)
		end
	end

	cachedGraph = { lanes = lanes, all = all }
	return cachedGraph :: any
end

-- Closest lane position + heading to a world point (used for car resets)
function CityLayout.nearestLaneCFrame(pos: Vector3): CFrame
	local graph = CityLayout.buildGraph()
	local best, bestDist = nil, math.huge
	local flat = pos - Vector3.new(0, 2, 0) -- (a car's middle sits about 2 above its lane)
	for _, seg in graph.lanes do
		if seg.kind == "lane" then
			local ab = seg.p2 - seg.p0
			local t = math.clamp((flat - seg.p0):Dot(ab) / ab:Dot(ab), 0.05, 0.95)
			local p = seg.p0 + ab * t
			local dist = (p - flat).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = CFrame.lookAt(p, p + ab.Unit)
			end
		elseif (seg.p1 - flat).Magnitude < seg.length + bestDist then
			-- a curved highway piece: the nearest of points along it
			for k = 1, 15 do
				local p, dir = CityLayout.sample(seg, seg.length * k / 16)
				local dist = (p - flat).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = CFrame.lookAt(p, p + dir)
				end
			end
		end
	end
	return best or CFrame.new()
end

return CityLayout
