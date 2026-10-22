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

local cachedGraph: { lanes: { Segment }, all: { Segment } }? = nil

function CityLayout.buildGraph(): { lanes: { Segment }, all: { Segment } }
	if cachedGraph then
		return cachedGraph
	end
	local all: { Segment } = {}
	local lanes: { Segment } = {}
	local byKey: { [string]: Segment } = {}
	local lanesPerSide = C.LanesPerSide

	-- straight lane segments between intersections
	for i = 0, N do
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

	-- the highway: the spur from the city's east edge to the loop, and the loop itself
	CityLayout.addHighway(all, lanes, byKey)

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
	local flat = Vector3.new(pos.X, 0, pos.Z)
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
