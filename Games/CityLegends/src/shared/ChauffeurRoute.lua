--[[
	ChauffeurRoute
	Route finding for the chauffeur service, over the same lane graph NPC traffic drives
	(CityLayout.buildGraph). Shared: the server checks a route exists before it sends a car, the
	rider's client plans and drives it.

	  * the graph's own links (lanes, turns, highway ramps) plus lane changes between parallel lanes
	    of the same road, so a car on the inner lane can still reach a kerb on the outer one
	  * Dijkstra on travel time (city / highway speeds, slow turns)
	  * a route is a list of legs {seg, s0, s1}; a lane change starts the next leg part-way along
	    the parallel lane, with `shift` (the sideways step) for the driver to ease out

	Nothing here knows the map: any lanes added to the graph later (the west highway, Downtown,
	the island causeway) are used as soon as they're in it.
]]

local Config = require(script.Parent.Config)
local CityLayout = require(script.Parent.CityLayout)

type Segment = CityLayout.Segment

local CH = Config.Chauffeur
local C = Config.City

local ChauffeurRoute = {}

export type Leg = {
	seg: Segment,
	s0: number,
	s1: number,
	shift: Vector3?, -- this leg starts with a lane change: where the car was, minus where it now is
}
export type Route = {
	legs: { Leg },
	length: number, -- studs
	time: number, -- seconds at the planned speeds (no traffic)
}

local LANE_CHANGE_SECONDS = 2.5 -- the cost of a lane change in the search (so it isn't free)

---------------------------------------------------------------------
-- Speeds
---------------------------------------------------------------------
-- the most a chauffeur drives on a segment (studs/s)
function ChauffeurRoute.speedOf(seg: Segment): number
	if seg.kind == "turn" and seg.turning then
		return Config.mphToSps(seg.turnSpeed or CH.TurnMph)
	end
	if seg.speedK > 1 then
		return Config.mphToSps(CH.HighwayMph)
	end
	return Config.mphToSps(CH.CityMph)
end

---------------------------------------------------------------------
-- The graph, with the extra links the search needs
---------------------------------------------------------------------
type Graph = {
	all: { Segment },
	lanesBeside: { [Segment]: { Segment } }, -- parallel lanes a car can change to
}
local cached: Graph? = nil

local function midpoint(seg: Segment): Vector3
	return CityLayout.sample(seg, seg.length / 2)
end

local function graph(): Graph
	if cached then
		return cached
	end
	local g = CityLayout.buildGraph()
	local all = g.all
	-- parallel lanes: same road and direction, a lane apart, side by side, about the same length
	local buckets: { [string]: { Segment } } = {}
	local CELL = 60
	local function key(p: Vector3): (number, number)
		return math.floor(p.X / CELL), math.floor(p.Z / CELL)
	end
	for _, seg in all do
		if seg.kind ~= "turn" then
			local bx, bz = key(midpoint(seg))
			local k = bx .. "," .. bz
			local list = buckets[k]
			if not list then
				list = {}
				buckets[k] = list
			end
			table.insert(list, seg)
		end
	end
	local beside: { [Segment]: { Segment } } = {}
	for _, seg in all do
		if seg.kind == "turn" then
			continue
		end
		local m, dir = CityLayout.sample(seg, seg.length / 2)
		local bx, bz = key(m)
		local found = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				local list = buckets[(bx + dx) .. "," .. (bz + dz)]
				if list then
					for _, other in list do
						if other ~= seg and other.dir == seg.dir and math.abs(other.lane - seg.lane) == 1 then
							local om, odir = CityLayout.sample(other, other.length / 2)
							local ratio = other.length / seg.length
							if (om - m).Magnitude < C.LaneWidth * 1.6 and odir:Dot(dir) > 0.97 and ratio > 0.8 and ratio < 1.25 then
								table.insert(found, other)
							end
						end
					end
				end
			end
		end
		if #found > 0 then
			beside[seg] = found
		end
	end
	local built: Graph = { all = all, lanesBeside = beside }
	cached = built
	return built
end
ChauffeurRoute.graph = graph

---------------------------------------------------------------------
-- Nearest lane to a point
---------------------------------------------------------------------
-- the closest point on a segment (by samples; exact enough for picking a lane)
local function closestOn(seg: Segment, p: Vector3): (number, number, Vector3)
	local best, bestS, bestDir = math.huge, 0, Vector3.zAxis
	local steps = math.clamp(math.ceil(seg.length / 6), 4, 60)
	for k = 0, steps do
		local s = seg.length * k / steps
		local q, d = CityLayout.sample(seg, s)
		local dv = q - p
		-- height counts more: the viaduct runs over the loop
		local dist = math.sqrt(dv.X * dv.X + dv.Z * dv.Z + (dv.Y * 1.5) ^ 2)
		if dist < best then
			best, bestS, bestDir = dist, s, d
		end
	end
	return best, bestS, bestDir
end

export type Spot = { seg: Segment, s: number, dist: number }

-- lanes near `p` (within maxDist), best first, at most `count`. `heading`: prefer lanes going that
-- way. `kerb`: prefer the lane nearest the kerb (the highest lane number on its road). One spot
-- per segment.
function ChauffeurRoute.nearestList(p: Vector3, maxDist: number, heading: Vector3?, kerb: boolean?, count: number?): { Spot }
	local g = graph()
	local scored: { { spot: Spot, score: number } } = {}
	for _, seg in g.all do
		if seg.kind == "turn" then
			continue
		end
		-- quick reject on the segment's rough bounds
		local mid = seg.p1
		if (Vector3.new(mid.X, 0, mid.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude > seg.length + maxDist then
			continue
		end
		local dist, s, dir = closestOn(seg, p)
		if dist <= maxDist then
			local score = dist
			if heading and heading.Magnitude > 0.01 then
				score += (1 - dir:Dot(heading.Unit)) * 40
			end
			if kerb and g.lanesBeside[seg] then
				for _, other in g.lanesBeside[seg] do
					if other.lane > seg.lane then
						score += C.LaneWidth * 0.8 -- an outer lane beside it is nearer the kerb
					end
				end
			end
			table.insert(scored, { spot = { seg = seg, s = s, dist = dist }, score = score })
		end
	end
	table.sort(scored, function(a, b)
		return a.score < b.score
	end)
	local out: { Spot } = {}
	for k = 1, math.min(#scored, count or 8) do
		table.insert(out, scored[k].spot)
	end
	return out
end

function ChauffeurRoute.nearest(p: Vector3, maxDist: number, heading: Vector3?, kerb: boolean?): Spot?
	return ChauffeurRoute.nearestList(p, maxDist, heading, kerb, 1)[1]
end

---------------------------------------------------------------------
-- Dijkstra (binary heap on travel time)
---------------------------------------------------------------------
type HeapItem = { t: number, seg: Segment }
local function push(heap: { HeapItem }, item: HeapItem)
	table.insert(heap, item)
	local i = #heap
	while i > 1 do
		local parent = i // 2
		if heap[parent].t <= heap[i].t then
			break
		end
		heap[parent], heap[i] = heap[i], heap[parent]
		i = parent
	end
end
local function pop(heap: { HeapItem }): HeapItem?
	local n = #heap
	if n == 0 then
		return nil
	end
	local top = heap[1]
	heap[1] = heap[n]
	heap[n] = nil
	n -= 1
	local i = 1
	while true do
		local l, r = i * 2, i * 2 + 1
		local m = i
		if l <= n and heap[l].t < heap[m].t then
			m = l
		end
		if r <= n and heap[r].t < heap[m].t then
			m = r
		end
		if m == i then
			break
		end
		heap[m], heap[i] = heap[i], heap[m]
		i = m
	end
	return top
end

type Via = { from: Segment, change: boolean }

-- the quickest way from a spot to a spot (nil when the graph doesn't join them)
function ChauffeurRoute.find(from: Spot, to: Spot): Route?
	local g = graph()
	-- time at which the car enters each segment (the start segment: as if entered before `from.s`)
	local entry: { [Segment]: number } = {}
	local via: { [Segment]: Via } = {}
	local heap: { HeapItem } = {}
	local t0 = -from.s / ChauffeurRoute.speedOf(from.seg)
	entry[from.seg] = t0
	push(heap, { t = t0, seg = from.seg })
	local done: { [Segment]: boolean } = {}
	local best, bestT = nil :: Segment?, math.huge
	while true do
		local item = pop(heap)
		if not item then
			break
		end
		local seg = item.seg
		if done[seg] or item.t > (entry[seg] or math.huge) then
			continue
		end
		done[seg] = true
		if item.t >= bestT then
			break -- nothing left can arrive sooner
		end
		local v = ChauffeurRoute.speedOf(seg)
		if seg == to.seg then
			local arrive = item.t + to.s / v
			-- (on the start segment the goal must be ahead of the car)
			if (seg ~= from.seg or to.s > from.s + 4) and arrive < bestT then
				best, bestT = seg, arrive
			end
		end
		local leave = item.t + seg.length / v
		for _, nxt in seg.next do
			if leave < (entry[nxt] or math.huge) then
				entry[nxt] = leave
				via[nxt] = { from = seg, change = false }
				push(heap, { t = leave, seg = nxt })
			end
		end
		local side = g.lanesBeside[seg]
		if side then
			local tc = item.t + LANE_CHANGE_SECONDS
			for _, other in side do
				if tc < (entry[other] or math.huge) then
					entry[other] = tc
					via[other] = { from = seg, change = true }
					push(heap, { t = tc, seg = other })
				end
			end
		end
	end
	if not best then
		return nil
	end
	-- walk back to the start, then lay the legs out forwards
	local chain: { { seg: Segment, change: boolean } } = {}
	local cur: Segment? = best
	local guard = 0
	while cur do
		guard += 1
		if guard > 5000 then
			return nil
		end
		-- (every segment reached has a `via`, except the start)
		local v = via[cur]
		table.insert(chain, 1, { seg = cur, change = v ~= nil and v.change })
		cur = if v then v.from else nil
	end
	local legs: { Leg } = {}
	local s = from.s
	for k, link in chain do
		local seg = link.seg
		local nextLink = chain[k + 1]
		local s1 = seg.length
		if k == #chain then
			s1 = math.max(s, to.s)
		elseif nextLink.change then
			-- change lanes a little way on (half of what's left, at most 60 studs on)
			s1 = math.min(s + math.max(20, (seg.length - s) * 0.5), s + 60, seg.length - 2)
			s1 = math.max(s1, s)
		end
		local leg: Leg = { seg = seg, s0 = s, s1 = s1, shift = nil }
		if link.change and k > 1 then
			local prev = legs[#legs]
			local was = CityLayout.sample(prev.seg, prev.s1)
			local now = CityLayout.sample(seg, s)
			leg.shift = was - now
		end
		table.insert(legs, leg)
		-- where the next leg starts on its segment
		if nextLink then
			if nextLink.change then
				s = math.clamp(s1 * nextLink.seg.length / seg.length, 0, nextLink.seg.length)
			else
				s = 0
			end
		end
	end
	local length, time = 0, 0
	for _, leg in legs do
		local d = math.max(0, leg.s1 - leg.s0)
		length += d
		time += d / ChauffeurRoute.speedOf(leg.seg)
	end
	return { legs = legs, length = length, time = time }
end

-- the best joined-up pair from two candidate lists (some lanes lead nowhere useful, like the
-- loop's outer ring, which no ramp leaves): the pick-up / drop-off and the route between them
function ChauffeurRoute.connect(froms: { Spot }, tos: { Spot }): (Spot?, Spot?, Route?)
	for _, a in froms do
		for _, b in tos do
			local route = ChauffeurRoute.find(a, b)
			if route then
				return a, b, route
			end
		end
	end
	return nil, nil, nil
end

-- a spot this many studs back up the road from `spot` (where a called car starts, out of sight)
function ChauffeurRoute.backFrom(spot: Spot, distance: number): Spot
	local g = graph()
	-- the graph only links forwards: find what leads into a segment
	local into: { [Segment]: { Segment } } = {}
	for _, seg in g.all do
		for _, nxt in seg.next do
			local list = into[nxt]
			if not list then
				list = {}
				into[nxt] = list
			end
			table.insert(list, seg)
		end
	end
	local seg, s = spot.seg, spot.s
	local left = distance
	local seen: { [Segment]: boolean } = {}
	while left > 0 do
		if s >= left then
			return { seg = seg, s = s - left, dist = 0 }
		end
		left -= s
		seen[seg] = true
		local options = into[seg]
		local pick: Segment? = nil
		if options then
			-- prefer a straight run in (not a turn) so the car arrives heading along the kerb
			for _, o in options do
				if not seen[o] and not (o.kind == "turn" and o.turning) then
					pick = o
					break
				end
			end
			if not pick then
				for _, o in options do
					if not seen[o] then
						pick = o
						break
					end
				end
			end
		end
		if not pick then
			return { seg = seg, s = 0, dist = 0 }
		end
		seg = pick
		s = pick.length
	end
	return { seg = seg, s = s, dist = 0 }
end

-- position and heading `d` studs into a route (and the leg it's on)
function ChauffeurRoute.at(route: Route, d: number): (Vector3, Vector3, number)
	local acc = 0
	for k, leg in route.legs do
		local len = math.max(0, leg.s1 - leg.s0)
		if d <= acc + len or k == #route.legs then
			local s = math.clamp(leg.s0 + (d - acc), leg.s0, leg.s1)
			local p, dir = CityLayout.sample(leg.seg, s)
			return p, dir, k
		end
		acc += len
	end
	local last = route.legs[#route.legs]
	local p, dir = CityLayout.sample(last.seg, last.s1)
	return p, dir, #route.legs
end

return ChauffeurRoute
