--[[
	Riviera road builder (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP and
	run on build/riviera/roads.json (tools/map_plan/export_roads.py).

	Every road becomes parts that follow its samples exactly:
	  * the carriageway: one asphalt slab per run of samples, its top face passing through the road's
	    centre heights, so consecutive slabs meet edge to edge with no step (owner, 2026-11-01: "no
	    bumps or extra studs on the road"). A smaller road's slab stops where it enters a bigger
	    road's carriageway; the bigger one carries on (heights there were made equal in network.py).
	  * pavements (red-pink pavers, Monaco) with light granite kerbs, left out at junction mouths
	  * white lines: dashed centre and lane lines, solid edges, zebra crossings at junction
	    approaches (no collision, no shadows)
	The terrain under roads sits 1.5 studs lower (terrain_build.py) so it never pokes through.

	Roads.build(data, opts) -> part count;  opts.box = {x0, z0, x1, z1} builds only samples inside
	Roads.check(data, opts) -> list of bumps found by raycasting each lane every stud
]]

local Roads = {}

local HALF = 32 -- half the carriageway (2 + 2 lanes of 16)
local WALK = 10 -- pavement
local SLAB = 2 -- slab thickness
local CURB_UP = 0.5 -- pavement top above the road
local LINE_T = 0.04

local ASPHALT = Color3.fromRGB(46, 47, 50)
local PAVER = Color3.fromRGB(176, 104, 92) -- Monaco's red-pink pavements
local STONE_PAVER = Color3.fromRGB(196, 186, 168) -- casino quarter
local KERB = Color3.fromRGB(205, 202, 194)
local PAINT = Color3.fromRGB(232, 232, 226)
-- sidewalk patterns per street (MaterialVariants on Pavement, kept in the place's MaterialService:
-- RivPaveBasket two-tone basket weave, RivPaveHerring grey blocks, RivCobble small cobbles)
local PATTERNS = {
	["Casino Avenue"] = { "RivPaveBasket", Color3.fromRGB(235, 228, 218) },
	["Casino Climb"] = { "RivPaveBasket", Color3.fromRGB(235, 228, 218) },
	["Beach Avenue"] = { "RivPaveHerring", Color3.fromRGB(236, 226, 214) },
	["Harbour Street"] = { "RivPaveHerring", Color3.fromRGB(236, 226, 214) },
	["Old Rock"] = { "RivCobble", Color3.fromRGB(230, 222, 210) },
	["Rock Climb"] = { "RivCobble", Color3.fromRGB(230, 222, 210) },
}

local function newPart(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	-- flat on the ground: its shadow never shows, and ~64k shadow casters cost every frame
	-- (performance pass 2026-11-02)
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function decor(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

-- a triangle (a, b, c) as two wedges whose top faces are exactly the triangle, `th` thick below it.
-- Neighbouring triangles share their edges, so a road built from them has no steps or overlaps.
local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, props, parent: Instance)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 then
		return 0
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	local drop = -nUp * (th / 2)
	local w1 = Instance.new("WedgePart")
	w1.Size = Vector3.new(th, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + drop, right, up, back)
	local w2 = Instance.new("WedgePart")
	w2.Size = Vector3.new(th, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back)
	for _, w in { w1, w2 } do
		w.Anchored = true
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(w :: any)[k] = v
		end
		if Roads.debugSeg then
			w:SetAttribute("Seg", Roads.debugSeg)
		end
		w.Parent = parent
	end
	return 2
end

-- samples as vectors, per road
local function prepare(data)
	local roads = {}
	for ri, r in data.roads do
		local pts = {}
		for i, s in r.s do
			-- s[7], s[8]: left and right half widths (narrower where a hairpin's legs run side by side)
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1, wl = s[7] or HALF, wr = s[8] or HALF }
		end
		roads[ri] = { name = r.name, kind = r.kind, rank = r.rank, closed = r.closed, pts = pts }
	end
	-- a 24-stud grid of every sample, for "is this point on another road?"
	local grid = {}
	for ri, r in roads do
		for i, p in r.pts do
			local key = math.floor(p.pos.X / 24) .. "," .. math.floor(p.pos.Z / 24)
			local cell = grid[key]
			if not cell then
				cell = {}
				grid[key] = cell
			end
			table.insert(cell, { ri, i })
		end
	end
	return roads, grid
end

-- nearest sample of another road (optionally only bigger roads) within radius of a point
local function otherNear(roads, grid, pos: Vector3, self: number, radius: number, biggerThan: number?): (number?, number?)
	local best, bestD = nil, radius
	local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
	local reach = math.ceil(radius / 24)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local cell = grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					local rj = e[1]
					if rj ~= self and (biggerThan == nil or roads[rj].rank < biggerThan) then
						local q = roads[rj].pts[e[2]].pos
						local d = Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude
						if d < bestD then
							best, bestD = rj, d
						end
					end
				end
			end
		end
	end
	return best, if best then bestD else nil
end

-- is a point within radius of this road's own centre line, away from sample i (a tight bend or
-- hairpin folding back over itself)?
local function selfNear(roads, grid, pos: Vector3, self: number, i: number, radius: number): boolean
	local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
	local reach = math.ceil(radius / 24)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local cell = grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					if e[1] == self and math.abs(e[2] - i) >= 2 then
						local q = roads[self].pts[e[2]].pos
						if Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude < radius then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- the surface height of a bigger road (rank below `rank`) at a point on its carriageway, or nil.
-- Roads are flat side to side, so it is the centre line's height where the point meets it square-on.
local function bigSurface(roads, grid, pos: Vector3, self: number, rank: number, radius: number?): number?
	local rj = otherNear(roads, grid, pos, self, radius or (HALF - 0.5), rank)
	if rj == nil then
		return nil
	end
	local pts = roads[rj].pts
	-- nearest sample of that road, then project onto the segments either side of it
	local best, bestD = 1, math.huge
	local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
	for dx = -2, 2 do
		for dz = -2, 2 do
			local cell = grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					if e[1] == rj then
						local q = pts[e[2]].pos
						local dd = Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude
						if dd < bestD then
							best, bestD = e[2], dd
						end
					end
				end
			end
		end
	end
	for _, pair in { { best - 1, best }, { best, best + 1 } } do
		local a, b = pts[pair[1]], pts[pair[2]]
		if a and b then
			local v = Vector2.new(b.pos.X - a.pos.X, b.pos.Z - a.pos.Z)
			local t = Vector2.new(pos.X - a.pos.X, pos.Z - a.pos.Z):Dot(v) / math.max(v:Dot(v), 1e-9)
			if t >= 0 and t <= 1 then
				return a.pos.Y + (b.pos.Y - a.pos.Y) * t
			end
		end
	end
	return pts[best].pos.Y
end

local function inBox(box, p: Vector3): boolean
	return box == nil or (p.X >= box[1] and p.X <= box[3] and p.Z >= box[2] and p.Z <= box[4])
end

-- a flat box whose top face runs from a to b (both on the road's centre line), shifted sideways
local function stripCF(a: Vector3, b: Vector3, side: number, up: number): CFrame
	local cf = CFrame.lookAt(a, b)
	local mid = (a + b) / 2
	return CFrame.new(mid) * cf.Rotation * CFrame.new(side, up, 0)
end

-- (owner, 2026-11-02: "the road isnt aligned properly here. most of the roads arent aligned
-- properly"): where a road meets or crosses a bigger one, its own height there (from the map data)
-- could be a stud or two off the bigger road's surface, a step across the junction mouth. Every
-- road's heights are eased onto the bigger road's surface at each mouth, the change fading out
-- along the road over at least 40 studs (at most a 6% change of grade). Biggest roads first, so a
-- road always meets its bigger roads' final heights.
local function alignJunctions(roads, grid)
	local order = {}
	for ri in roads do
		table.insert(order, ri)
	end
	table.sort(order, function(a, b)
		return roads[a].rank < roads[b].rank
	end)
	for _, ri in order do
		local r = roads[ri]
		local pts = r.pts
		local n = #pts
		local arc = { 0 }
		for i = 2, n do
			local d = pts[i].pos - pts[i - 1].pos
			arc[i] = arc[i - 1] + Vector2.new(d.X, d.Z).Magnitude
		end
		-- the junction mouths: runs of samples within the bigger road's reach. Inside a run every sample
		-- sits on the bigger road's surface (so this road's slab meets the bigger one's edge level);
		-- outside, the change at the run's end fades out along the road. A run where this road is
		-- narrowed all through is a road running alongside behind a wall, not a mouth: left alone.
		local events = {}
		local cur = nil
		for i = 1, n do
			local rj = otherNear(roads, grid, pts[i].pos, ri, HALF + 6, r.rank)
			if rj then
				if cur and cur.rj == rj and cur.last == i - 1 then
					cur.last = i
				else
					cur = { rj = rj, first = i, last = i, wide = false }
					table.insert(events, cur)
				end
				if pts[i].wl >= HALF - 0.5 and pts[i].wr >= HALF - 0.5 then
					cur.wide = true
				end
			else
				cur = nil
			end
		end
		local target = {}
		local offs = table.create(n, 0)
		local weight = table.create(n, 0)
		local any = false
		for _, e in events do
			if not e.wide then
				continue
			end
			any = true
			for i = e.first, e.last do
				local y = bigSurface(roads, grid, pts[i].pos, ri, r.rank, HALF + 6)
				if y then
					target[i] = y
				end
			end
			local d0 = if target[e.first] then target[e.first] - pts[e.first].pos.Y else 0
			local d1 = if target[e.last] then target[e.last] - pts[e.last].pos.Y else 0
			for j = 1, n do
				if j < e.first or j > e.last then
					local gap = if j < e.first then arc[e.first] - arc[j] else arc[j] - arc[e.last]
					local d = if j < e.first then d0 else d1
					local L = math.max(40, math.abs(d) / 0.06)
					local w = math.clamp(1 - gap / L, 0, 1)
					if w > weight[j] then
						weight[j], offs[j] = w, d * w
					end
				end
			end
		end
		-- a road that curls back over itself (a hooked end, a tight hairpin without a wall): where its
		-- earlier part lies on its later part, the earlier part takes the later part's surface
		-- (a junction mouth always keeps its own)
		do
			local runFirst, runLast, dEnd = nil, nil, 0
			local function closeRun()
				if runFirst then
					for _, k in { { runFirst, -1 }, { runLast, 1 } } do
						local edgeI = k[1]
						local d = (target[edgeI] or pts[edgeI].pos.Y) - pts[edgeI].pos.Y
						local L = math.max(40, math.abs(d) / 0.06)
						for j = 1, n do
							local gap = if k[2] < 0 then arc[edgeI] - arc[j] else arc[j] - arc[edgeI]
							if gap > 0 then
								local w = math.clamp(1 - gap / L, 0, 1)
								if w > weight[j] then
									weight[j], offs[j] = w, d * w
								end
							end
						end
					end
					any = true
				end
				runFirst, runLast = nil, nil
			end
			for i = 1, n do
				local hit = nil
				if not target[i] and pts[i].wl >= HALF - 0.5 and pts[i].wr >= HALF - 0.5 then
					local cx, cz = math.floor(pts[i].pos.X / 24), math.floor(pts[i].pos.Z / 24)
					-- (the two parts' carriageways overlap once their centres are under two half widths apart)
					local bestD = 2 * HALF - 2
					for dx = -3, 3 do
						for dz = -3, 3 do
							for _, e in grid[(cx + dx) .. "," .. (cz + dz)] or {} do
								if e[1] == ri and e[2] >= i + 10 then
									local q = pts[e[2]].pos
									local dd = Vector2.new(q.X - pts[i].pos.X, q.Z - pts[i].pos.Z).Magnitude
									-- (really curled back: heading the other way, further along the road than across)
									local opposed = pts[e[2]].dir.Unit:Dot(pts[i].dir.Unit) < -0.2
									if dd < bestD and opposed and arc[e[2]] - arc[i] > 1.15 * dd then
										bestD, hit = dd, e[2]
									end
								end
							end
						end
					end
				end
				if hit then
					target[i] = target[hit] or pts[hit].pos.Y
					runFirst = runFirst or i
					runLast = i
				else
					closeRun()
				end
			end
			closeRun()
		end
		if any then
			for j = 1, n do
				local p = pts[j].pos
				if target[j] then
					pts[j].pos = Vector3.new(p.X, target[j], p.Z)
					pts[j].mouth = true
				elseif offs[j] ~= 0 then
					pts[j].pos = Vector3.new(p.X, p.Y + offs[j], p.Z)
				end
			end
		end
	end
end

-- (debugging) the roads as the build sees them: samples after the junction alignment
function Roads.prepared(data)
	local roads, grid = prepare(data)
	alignJunctions(roads, grid)
	return roads
end

function Roads.build(data, opts)
	opts = opts or {}
	local box = opts.box
	local parent = opts.parent
	local roads, grid = prepare(data)
	alignJunctions(roads, grid)
	local count = 0
	local zebraSpots: { Vector3 } = {}
	for ri, r in roads do
		if opts.only and not opts.only[r.name] then
			continue
		end
		local folder = Instance.new("Folder")
		folder.Name = r.name
		local pts = r.pts
		local n = #pts
		local town = r.kind == "street" or r.name == "Town Road" or r.name == "Coast Road"
		local paver = if string.find(r.name, "Casino") then STONE_PAVER else PAVER
		-- per sample: is it inside a bigger road (slab skipped), in a junction (lines skipped)?
		local insideBig, inJunction = {}, {}
		for i, p in pts do
			insideBig[i] = otherNear(roads, grid, p.pos, ri, HALF - 2, r.rank) ~= nil
			inJunction[i] = otherNear(roads, grid, p.pos, ri, HALF + 6) ~= nil
		end
		-- each cross-section's left and right road edges; on a bend tighter than half the road the
		-- inner edge would run backwards and fold the surface over, so it waits at its last point
		local edgeL, edgeR = {}, {}
		local waitL, waitR = {}, {}
		for i, p in pts do
			local right = Vector3.new(-p.dir.Z, 0, p.dir.X).Unit
			edgeL[i], edgeR[i] = p.pos - right * p.wl, p.pos + right * p.wr
			if i > 1 then
				local d = pts[i].pos - pts[i - 1].pos
				d = Vector3.new(d.X, 0, d.Z)
				if (edgeL[i] - edgeL[i - 1]):Dot(d) <= 0.05 * d.Magnitude then
					edgeL[i] = Vector3.new(edgeL[i - 1].X, p.pos.Y, edgeL[i - 1].Z)
					waitL[i] = true
				end
				if (edgeR[i] - edgeR[i - 1]):Dot(d) <= 0.05 * d.Magnitude then
					edgeR[i] = Vector3.new(edgeR[i - 1].X, p.pos.Y, edgeR[i - 1].Z)
					waitR[i] = true
				end
			end
		end
		-- a waiting edge is one point (the pivot of a fan of triangles round the bend's inside): it
		-- gets one height, the mean of the run, or the surface would have a vertical step there
		local fanL, fanR = {}, {}
		local function settle(edge, waited, fan)
			local i = 2
			while i <= n do
				if waited[i] then
					local j = i
					while j < n and waited[j + 1] do
						j += 1
					end
					-- (a junction mouth's samples keep the bigger road's height: the pivot takes theirs)
					local sum, cnt, msum, mcnt = 0, 0, 0, 0
					for k = i - 1, j do
						sum += edge[k].Y
						cnt += 1
					end
					-- (a fan that starts or ends next to a mouth: the mouth's height, or its edge would
					-- sit below the bigger road's)
					for k = math.max(1, i - 4), math.min(n, j + 4) do
						if pts[k].mouth then
							msum += pts[k].pos.Y
							mcnt += 1
						end
					end
					local y = if mcnt > 0 then msum / mcnt else sum / cnt
					for k = i - 1, j do
						edge[k] = Vector3.new(edge[k].X, y, edge[k].Z)
						fan[k] = true
					end
					i = j + 1
				else
					i += 1
				end
			end
		end
		settle(edgeL, waitL, fanL)
		settle(edgeR, waitR, fanR)
		-- where this road's edge lies on a bigger road (a junction mouth), it takes that road's surface
		-- height, so both surfaces are one plane there and the joint has no step
		local pinL, pinR = {}, {}
		for i = 1, n do
			for side, edge in { edgeL, edgeR } do
				if (if side == 1 then pts[i].wl else pts[i].wr) < HALF - 0.5 then
					continue -- a narrowed edge stops at the wall between this road and the next
				end
				local y = bigSurface(roads, grid, edge[i], ri, r.rank, HALF + 8) -- (a little past its edge: the joint stays level)
				if y then
					edge[i] = Vector3.new(edge[i].X, y, edge[i].Z)
					;(if side == 1 then pinL else pinR)[i] = true
				end
			end
		end
		-- (owner, 2026-11-02: "the road isnt aligned properly here. most of the roads arent aligned
		-- properly"): a pinned edge (on a bigger road) could sit a stud or two off its neighbours, a
		-- step at the junction mouth. The free edge points ease in: along each edge no more than
		-- GRADE between neighbours, and across the road no more than CROSS, worked out from the pinned
		-- points (they never move) by passes back and forth until nothing changes
		local GRADE, CROSS = 0.19, 0.06 -- (GRADE: over the steepest climb, 16%)
		-- (a fan's pivot is one point: it moves as one, all its copies keep one height; spacing is
		-- measured between the edge points themselves)
		local function relax(edge, pin, fan)
			-- nodes: runs of fan points (one pivot) or single points
			local nodes = {}
			local i = 1
			while i <= n do
				local j = i
				if fan[i] then
					while j < n and fan[j + 1] and (Vector2.new(edge[j + 1].X - edge[i].X, edge[j + 1].Z - edge[i].Z)).Magnitude < 0.5 do
						j += 1
					end
				end
				local held = false
				for k = i, j do
					if pin[k] then
						held = true
					end
				end
				table.insert(nodes, { i = i, j = j, held = held })
				i = j + 1
			end
			local function setY(nd, y)
				for k = nd.i, nd.j do
					edge[k] = Vector3.new(edge[k].X, y, edge[k].Z)
				end
			end
			local function dist(a, b)
				local p, q = edge[a.j], edge[b.i]
				return Vector2.new(p.X - q.X, p.Z - q.Z).Magnitude
			end
			for _ = 1, 4 do
				for k = 2, #nodes do
					local nd, pv = nodes[k], nodes[k - 1]
					if not nd.held then
						local d = dist(pv, nd)
						local y0 = edge[pv.j].Y
						setY(nd, math.clamp(edge[nd.i].Y, y0 - GRADE * d - 0.02, y0 + GRADE * d + 0.02))
					end
				end
				for k = #nodes - 1, 1, -1 do
					local nd, nx = nodes[k], nodes[k + 1]
					if not nd.held then
						local d = dist(nd, nx)
						local y0 = edge[nx.i].Y
						setY(nd, math.clamp(edge[nd.i].Y, y0 - GRADE * d - 0.02, y0 + GRADE * d + 0.02))
					end
				end
			end
		end
		for _ = 1, 3 do
			relax(edgeL, pinL, fanL)
			relax(edgeR, pinR, fanR)
			for i = 1, n do
				local w = Vector2.new(edgeR[i].X - edgeL[i].X, edgeR[i].Z - edgeL[i].Z).Magnitude
				local lim = CROSS * w + 0.02
				local dy = edgeR[i].Y - edgeL[i].Y
				if math.abs(dy) > lim then
					local fixedL, fixedR = pinL[i] or fanL[i], pinR[i] or fanR[i]
					if fixedL and fixedR then
						-- both held
					elseif fixedL then
						edgeR[i] = Vector3.new(edgeR[i].X, edgeL[i].Y + math.sign(dy) * lim, edgeR[i].Z)
					elseif fixedR then
						edgeL[i] = Vector3.new(edgeL[i].X, edgeR[i].Y - math.sign(dy) * lim, edgeL[i].Z)
					else
						local mid = (edgeL[i].Y + edgeR[i].Y) / 2
						edgeL[i] = Vector3.new(edgeL[i].X, mid - math.sign(dy) * lim / 2, edgeL[i].Z)
						edgeR[i] = Vector3.new(edgeR[i].X, mid + math.sign(dy) * lim / 2, edgeR[i].Z)
					end
				end
			end
		end
		if opts.debug then
			Roads.debugEdges = Roads.debugEdges or {}
			Roads.debugEdges[r.name] = { L = edgeL, R = edgeR, waitL = waitL, waitR = waitR, pinL = pinL, pinR = pinR }
		end
		local dash = 0
		local zebraDone = {}
		for i = 1, n - 1 do
			local a, b = pts[i], pts[i + 1]
			if not (inBox(box, a.pos) or inBox(box, b.pos)) then
				continue
			end
			local flat = Vector2.new(b.pos.X - a.pos.X, b.pos.Z - a.pos.Z).Magnitude
			if flat < 0.05 then
				continue
			end
			-- extra length to close the gap on the outside of a bend
			local turn = 0
			if i > 1 then
				local d0 = (a.pos - pts[i - 1].pos) * Vector3.new(1, 0, 1)
				local d1 = (b.pos - a.pos) * Vector3.new(1, 0, 1)
				if d0.Magnitude > 0 and d1.Magnitude > 0 then
					turn = math.acos(math.clamp(d0.Unit:Dot(d1.Unit), -1, 1))
				end
			end
			local grow = math.min(math.tan(turn / 2) * (HALF + WALK) * 2, 24)
			local len = (b.pos - a.pos).Magnitude
			local a2 = a.pos - (b.pos - a.pos).Unit * (grow / 2)
			local b2 = b.pos + (b.pos - a.pos).Unit * (grow / 2)
			-- carriageway: two triangles between this cross-section and the next (flat side to side).
			-- Left out only when all four corners lie on a bigger road (never leaves a hole).
			local covered = insideBig[i] and insideBig[i + 1]
			if covered then
				for _, c in { edgeL[i], edgeR[i], edgeL[i + 1], edgeR[i + 1] } do
					if otherNear(roads, grid, c, ri, HALF - 4, r.rank) == nil then
						covered = false
						break
					end
				end
			end
			if not covered then
				local cf = stripCF(a2, b2, 0, -SLAB / 2)
				local la, lb, rra, rrb = edgeL[i], edgeL[i + 1], edgeR[i], edgeR[i + 1]
				local props = { Name = "Road", Material = Enum.Material.Asphalt, Color = ASPHALT }
				-- a climbing bend twists the quad (its 4 corners aren't in one plane), so its 2 triangles
				-- meet at a crease felt as a bump; split it side to side into strips until each crease
				-- is under 0.05 studs
				local nrm = (rra - la):Cross(rrb - la)
				local strips = 1
				if math.abs(nrm.Y) > 1e-6 then
					local dev = math.abs((lb - la):Dot(nrm) / nrm.Y)
					strips = math.clamp(math.ceil(dev / 0.05), 1, 6)
				end
				if opts.debug then
					Roads.debugSeg = i
				end
				for k = 0, strips - 1 do
					local t0, t1 = k / strips, (k + 1) / strips
					local pa0, pa1 = la:Lerp(rra, t0), la:Lerp(rra, t1)
					local pb0, pb1 = lb:Lerp(rrb, t0), lb:Lerp(rrb, t1)
					count += triangle(pa0, pa1, pb1, SLAB, props, folder)
					count += triangle(pa0, pb1, pb0, SLAB, props, folder)
				end
				-- no terrain may stand above the road surface (it would be a bump). Terrain clears whole
				-- 4-stud voxels by their centres, so clear from 4 studs under the top up
				workspace.Terrain:FillBlock(cf * CFrame.new(0, SLAB / 2 - 4 + 11, 0), Vector3.new((HALF + WALK) * 2, 22, len + grow), Enum.Material.Air)
			end
			-- outside the town: flush concrete shoulders (the ground under them is cleared too)
			if not town then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					local sidePos = mid + right * side * (HALF + WALK / 2)
					local narrow = math.min(if side < 0 then a.wl else a.wr, if side < 0 then b.wl else b.wr) < HALF - 0.5
					if otherNear(roads, grid, sidePos, ri, HALF + 2) == nil and not selfNear(roads, grid, sidePos, ri, i, HALF + 1) and not narrow then
						local cf = stripCF(a2, b2, side * (HALF + WALK / 2), -3 - 0.02)
						newPart({ Name = "Shoulder", Size = Vector3.new(WALK, 6, len + grow), CFrame = cf, Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 146, 138) }, folder)
						count += 1
					end
				end
			end
			-- pavements and kerbs, each side
			-- where a hairpin's two legs run side by side (narrowed edge), a cream stone wall on the line
			-- between them, from well below to 2.5 above this leg (each leg builds its own)
			for _, side in { -1, 1 } do
				local wa = if side < 0 then a.wl else a.wr
				local wb = if side < 0 then b.wl else b.wr
				if wa < HALF - 0.5 and wb < HALF - 0.5 then
					local ea = if side < 0 then edgeL[i] else edgeR[i]
					local eb = if side < 0 then edgeL[i + 1] else edgeR[i + 1]
					local flatLen = Vector2.new(eb.X - ea.X, eb.Z - ea.Z).Magnitude
					-- never across another road (at a junction the legs meet that road instead)
					if flatLen > 0.05 and otherNear(roads, grid, (ea + eb) / 2, ri, HALF + WALK) == nil then
						local top = math.max(ea.Y, eb.Y) + 2.5
						local bottom = math.min(ea.Y, eb.Y) - 9
						local mid = Vector3.new((ea.X + eb.X) / 2, (top + bottom) / 2, (ea.Z + eb.Z) / 2)
						local look = Vector3.new(eb.X, mid.Y, eb.Z)
						newPart({ Name = "LegWall", Size = Vector3.new(1, top - bottom, flatLen + 0.6), CFrame = CFrame.lookAt(mid, look), Material = Enum.Material.Limestone, Color = Color3.fromRGB(222, 214, 196) }, folder)
						count += 1
					end
				end
			end
			if town then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					local sidePos = mid + right * side * (HALF + WALK / 2)
					local kerbPos = mid + right * side * (HALF + 0.45)
					local narrow = math.min(if side < 0 then a.wl else a.wr, if side < 0 then b.wl else b.wr) < HALF - 0.5
					if otherNear(roads, grid, sidePos, ri, HALF + 2) == nil and not a.tunnel and not narrow
						and not selfNear(roads, grid, sidePos, ri, i, HALF + 1) and not selfNear(roads, grid, kerbPos, ri, i, HALF - 1) then
						-- 6 studs deep: the terrain under the road is cleared 4 studs down.
						-- (owner, 2026-11-02: "the curbs are glitching out") the kerb and pavement follow the
						-- road's own edge (its height can differ from the centre line's at junctions now),
						-- and neighbouring pieces differ by a hair in width and height so their overlaps
						-- never share a face (that flickered). A fan's pivot (the inside of a tight bend,
						-- where the edge stands still) keeps the old centre-line strip.
						local ea = if side < 0 then edgeL[i] else edgeR[i]
						local eb = if side < 0 then edgeL[i + 1] else edgeR[i + 1]
						local edgeLen = Vector2.new(eb.X - ea.X, eb.Z - ea.Z).Magnitude
						local alt = if i % 2 == 0 then 1 else 0
						local walkCF, kerbCF, walkLen, kerbLen
						if edgeLen > 0.5 then
							local out = right * side
							local extra = math.min(grow, 8) + 0.3
							local function along(offset: number, y: number): (CFrame, number)
								local pa = ea + out * offset + Vector3.new(0, y, 0)
								local pb = eb + out * offset + Vector3.new(0, y, 0)
								return CFrame.lookAt((pa + pb) / 2, pb), (pb - pa).Magnitude + extra
							end
							local wcf, wl2 = along(WALK / 2, CURB_UP - 3 + alt * 0.006)
							walkCF, walkLen = wcf, wl2
							kerbCF, kerbLen = along(0.45, CURB_UP + 0.02 - 3 + alt * 0.006)
						else
							walkCF = stripCF(a2, b2, side * (HALF + WALK / 2), CURB_UP - 3 + alt * 0.006)
							kerbCF = stripCF(a2, b2, side * (HALF + 0.45), CURB_UP + 0.02 - 3 + alt * 0.006)
							walkLen = len + grow
							kerbLen = len + grow
						end
						local pv = newPart({ Name = "Pavement", Size = Vector3.new(WALK - alt * 0.01, 6, walkLen), CFrame = walkCF, Material = Enum.Material.Pavement, Color = paver }, folder)
						-- patterned paving in some quarters (owner 2026-11-02: "add some sidewalk
						-- patterns"); MaterialVariants in MaterialService (Creator Store textures)
						local pattern = PATTERNS[r.name]
						if pattern then
							pv.MaterialVariant = pattern[1]
							pv.Color = pattern[2]
						end
						local k = newPart({ Name = "Kerb", Size = Vector3.new(0.9 - alt * 0.01, 6.04, kerbLen), CFrame = kerbCF, Material = Enum.Material.Granite, Color = KERB }, folder)
						k.CastShadow = false
						count += 2
					end
				end
			end
			-- lines (painted on the slab's own plane)
			if not (inJunction[i] or inJunction[i + 1]) then
				dash += 1
				local lines = {}
				local wl, wr = math.min(a.wl, b.wl), math.min(a.wr, b.wr)
				table.insert(lines, { x = wr - 1.2, w = 0.6, solid = true })
				table.insert(lines, { x = -(wl - 1.2), w = 0.6, solid = true })
				if dash % 2 == 0 then
					table.insert(lines, { x = 0, w = 0.5 })
					if wr > HALF / 2 + 2 then
						table.insert(lines, { x = HALF / 2, w = 0.4 })
					end
					if wl > HALF / 2 + 2 then
						table.insert(lines, { x = -HALF / 2, w = 0.4 })
					end
				end
				for _, l in lines do
					local cf = stripCF(a.pos, b.pos, l.x, LINE_T / 2 + 0.04)
					local p = newPart({ Name = "Line", Size = Vector3.new(l.w, LINE_T, if l.solid then len + 0.3 else len * 0.9), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = PAINT }, folder)
					decor(p)
					count += 1
				end
			else
				dash = 0
			end
			-- zebra crossing where the road leaves a junction (town streets). (owner, 2026-11-02: two
			-- side roads leaving one junction side by side painted their crossings over each other,
			-- across each other's lanes) A crossing is left out when any stripe would lie on another
			-- road's carriageway or near a crossing already painted; stripes stop at a narrowed edge.
			local function zebra(cf: CFrame, w: { number })
				local stripes = {}
				for k = -6, 6 do
					local off = k * 4.8
					if off < -(w[1] - 3) or off > w[2] - 3 then
						continue
					end
					local sc = cf * CFrame.new(off, 0, 0)
					if otherNear(roads, grid, sc.Position, ri, HALF - 2) ~= nil then
						return
					end
					table.insert(stripes, sc)
				end
				local centre = cf.Position
				for _, z in zebraSpots do
					if Vector2.new(z.X - centre.X, z.Z - centre.Z).Magnitude < 24 then
						return
					end
				end
				table.insert(zebraSpots, centre)
				for _, sc in stripes do
					local p = newPart({ Name = "Zebra", Size = Vector3.new(2.6, LINE_T, 10), CFrame = sc, Material = Enum.Material.SmoothPlastic, Color = PAINT }, folder)
					decor(p)
					count += 1
				end
			end
			if town and i > 1 and inJunction[i - 1] and not inJunction[i] and not zebraDone[i] then
				zebraDone[i] = true
				-- (left / right as the road runs a -> b: the crossing's stripes run across it)
				zebra(stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, -len / 2 + 7), { math.min(a.wl, b.wl), math.min(a.wr, b.wr) })
			end
			if i < n - 1 and inJunction[i + 1] and not inJunction[i] then
				zebra(stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, len / 2 - 7), { math.min(a.wl, b.wl), math.min(a.wr, b.wr) })
			end
			if i % 40 == 0 then
				task.wait()
			end
		end
		-- a street that ends on no other road gets a round turning circle, flush with the road (no
		-- drop off the slab's end)
		if not r.closed then
			for _, e in { { pts[1], -1 }, { pts[n], 1 } } do
				local p = e[1]
				if inBox(box, p.pos) and otherNear(roads, grid, p.pos, ri, HALF + WALK) == nil then
					local r0 = HALF + WALK
					local centre = p.pos + p.dir.Unit * e[2] * (r0 - HALF)
					newPart({ Name = "TurningCircle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(SLAB, r0 * 2, r0 * 2), CFrame = CFrame.new(centre - Vector3.new(0, SLAB / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Asphalt, Color = ASPHALT }, folder)
					workspace.Terrain:FillBlock(CFrame.new(centre + Vector3.new(0, 11 - 4 + 0.01, 0)), Vector3.new(r0 * 2, 22, r0 * 2), Enum.Material.Air)
					count += 1
				end
			end
		end
		if #folder:GetChildren() > 0 then
			folder.Parent = parent
		else
			folder:Destroy()
		end
	end
	return count
end

-- drive every lane a stud at a time (raycasts) and report steps: the surface jumping by more than
-- `limit` studs (plus what a 16% grade allows) between neighbouring points
function Roads.check(data, opts)
	opts = opts or {}
	local box = opts.box
	local limit = opts.limit or 0.12
	local roads = prepare(data)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { opts.parent, workspace.Terrain }
	local bumps = {}
	local checked = 0
	for _, r in roads do
		local pts = r.pts
		for _, lane in { -24, -8, 8, 24 } do
			local last: Vector3? = nil
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				if not inBox(box, a.pos) then
					last = nil
					continue
				end
				local d = b.pos - a.pos
				local right = Vector3.new(-d.Z, 0, d.X).Unit
				local steps = math.max(1, math.floor(Vector2.new(d.X, d.Z).Magnitude))
				for k = 0, steps - 1 do
					-- consecutive points along the lane: the surface may climb at most the steepest
					-- grade (16%) between them; more than that plus `limit` is a step (a bump)
					local p = a.pos + d * (k / steps) + right * lane
					local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
					checked += 1
					if hit then
						local here = hit.Position
						if last then
							local dd = Vector2.new(here.X - last.X, here.Z - last.Z).Magnitude
							if dd < 2.5 and math.abs(here.Y - last.Y) > 0.17 * dd + limit then
								table.insert(bumps, { road = r.name, lane = lane, at = p, step = here.Y - last.Y })
							end
						end
						last = here
					else
						last = nil
					end
				end
			end
		end
	end
	return bumps, checked
end

return Roads
