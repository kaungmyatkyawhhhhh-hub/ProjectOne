--[[
	Riviera road builder (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP and
	run on build/riviera/roads.json (tools/map_plan/export_roads.py).

	Every road becomes parts that follow its samples exactly:
	  * the carriageway: one asphalt slab per run of samples, its top face passing through the road's
	    centre heights, so consecutive slabs meet edge to edge with no step (owner, 2026-11-01: "no
	    bumps or extra studs on the road"). A smaller road's slab stops where it enters a bigger
	    road's carriageway; the bigger one carries on (heights there were made equal in network.py).
	  * pavements (red-pink pavers, Monaco) with light stone kerbs (Concrete: Granite's speckle
	    looked grainy, owner 2026-11-03), left out at junction mouths
	  * white lines: dashed centre and lane lines, solid edges, zebra crossings at junction
	    approaches (no collision, no shadows)
	The terrain under roads sits 1.5 studs lower (terrain_build.py) so it never pokes through.

	Roads.build(data, opts) -> part count;  opts.box = {x0, z0, x1, z1} builds only samples inside
	  (opts.noLines: no chord lines, RoadLines draws them; opts.noLegWalls: no walls on narrowed edges,
	  tools/riviera/Parapets.luau builds them; opts.surfaceOnly: only the road's slabs)
	Roads.check(data, opts) -> list of bumps found by raycasting each lane every stud

	Yangon (2026-11-13). A road may carry its own half width: `half` on the road in the data (streets
	16, a true 1+1 road with kerbs and pavements). Every distance that was HALF is then that road's own
	half, and "near another road" is measured with the other road's half. Without `half` nothing
	changes (Monaco: every road is HALF). Options added for it, all off unless given:
	  opts.pave = true or { [road name] = true }: kerbs and pavements on a "route" (not grey shoulders)
	  opts.palette = { asphalt, paver, paverMaterial, paverVariant, kerb, kerbBand, kerbSplit, kerbMaterial, paint }
	    (kerbBand: a painted kerb's second colour; kerbSplit: bands per 6.4-stud piece)
	  opts.cut = { [road name] = { [sample] = true } }: those samples are not built and are not seen by
	    any other road (a flyover corridor, the inside of a roundabout). A cut end is square.
	  opts.noSlab = { [road name] = { [i] = true } }: no slab between samples i and i + 1 (a mouth some
	    other tool builds); kerbs and pavements are still made there
	  opts.sideZone = function(road name, position, "Kerb" | "Pavement") -> true where this road's kerb
	    or pavement must not be. Pieces are cut exactly on the zone's edge.
	  opts.noZebra, opts.noTurningCircle, opts.noShadows (slabs cast no shadow)
	  opts.live: the road's folder is parented first and filled a chunk at a time
	  opts.keepEdges: Roads.debugEdges[road name] = { L, R } (edge points with their final heights);
	    opts.edgesFor = { [road name] = true }: also for roads that are not built in this call
	Roads.check also takes opts.only = { [road name] = true } (drive only those roads), opts.lanes =
	  { [road name] = { offsets } } (a street's lanes are not a main road's) and opts.cut as above.
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

-- (Yangon 2026-11-13) the widest road's half width over HALF: how much further "near" can reach
local maxDh = 0

-- the part of a polygon outside a zone (inside(p) -> boolean): every corner outside comes back as it
-- is, and each side that crosses the zone's edge is cut on the edge (found by halving).
-- Returns (polygon or nil, untouched)
local function clipPoly(c: { Vector3 }, inside: (Vector3) -> boolean): ({ Vector3 }?, boolean)
	local flag, nIn = {}, 0
	for k = 1, #c do
		flag[k] = inside(c[k])
		if flag[k] then
			nIn += 1
		end
	end
	if nIn == 0 then
		return c, true
	elseif nIn == #c then
		return nil, false
	end
	local out = {}
	for k = 1, #c do
		local k2 = k % #c + 1
		local p, q = c[k], c[k2]
		if not flag[k] then
			table.insert(out, p)
		end
		if flag[k] ~= flag[k2] then
			local lo, hi = 0, 1 -- (lo: still on p's side of the zone's edge)
			for _ = 1, 18 do
				local mid = (lo + hi) / 2
				if inside(p:Lerp(q, mid)) == flag[k] then
					lo = mid
				else
					hi = mid
				end
			end
			table.insert(out, p:Lerp(q, if flag[k] then hi else lo))
		end
	end
	return out, false
end
Roads.clipPoly = clipPoly

-- (13 Nov) a quad { in0, out0, out1, in1 } cut by a zone, as a list of polygons. clipPoly cuts each side
-- where it crosses the zone's edge and joins the cuts with a straight line, so where the zone's own edge
-- bends inside the quad (two zones meeting: a mouth and a round corner) it takes a triangle too much: a
-- V-shaped gap. A quad that is only partly cut is halved along its length and each half cut again, down to
-- `depth` halvings, so the straight joins become short. Returns (pieces, whole) where whole means the quad
-- came through untouched as the one piece.
local function clipPieces(q: { Vector3 }, inside: (Vector3) -> boolean, depth: number): ({ { Vector3 } }, boolean)
	local poly, whole = clipPoly(q, inside)
	if whole then
		return { q }, true
	end
	if poly == nil and depth <= 0 then
		return {}, false
	end
	if depth <= 0 or (q[1] - q[4]).Magnitude < 0.3 then
		return if poly then { poly } else {}, false
	end
	-- (a quad wholly inside at its corners can still be partly outside in its middle: halve it too)
	local m1, m2 = q[1]:Lerp(q[4], 0.5), q[2]:Lerp(q[3], 0.5)
	local out = {}
	for _, half in { { q[1], q[2], m2, m1 }, { m1, m2, q[3], q[4] } } do
		local pieces = clipPieces(half, inside, depth - 1)
		for _, piece in pieces do
			table.insert(out, piece)
		end
	end
	return out, false
end
Roads.clipPieces = clipPieces

-- a triangle under 0.03 studs across is not worth a part: its plane is set by rounding, so its wedges
-- (as thick as the slab, along that plane's normal) can lean any way at all and stick out sideways
local function sliver(a: Vector3, b: Vector3, c: Vector3): boolean
	local long = math.max((b - a).Magnitude, (c - a).Magnitude, (c - b).Magnitude)
	return long < 1e-6 or (b - a):Cross(c - a).Magnitude / long < 0.03
end
Roads.sliver = sliver

-- samples as vectors, per road
local function prepare(data, cut)
	local roads = {}
	maxDh = 0
	for ri, r in data.roads do
		-- (r.half: this road's own half carriageway, Yangon; without it every road is HALF wide)
		local half = r.half
		local pts = {}
		for i, s in r.s do
			-- s[7], s[8]: left and right half widths (narrower where a hairpin's legs run side by side)
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1, wl = s[7] or half or HALF, wr = s[8] or half or HALF }
		end
		roads[ri] = { name = r.name, kind = r.kind, rank = r.rank, closed = r.closed, pts = pts, aligned = r.aligned, half = half, dh = (half or HALF) - HALF, cut = if cut then cut[r.name] else nil }
		maxDh = math.max(maxDh, roads[ri].dh)
	end
	-- a 24-stud grid of every sample, for "is this point on another road?"
	local grid = {}
	for ri, r in roads do
		for i, p in r.pts do
			-- (a cut sample is not there for any other road: a flyover deck 14 studs up is no junction
			-- for the road passing under it)
			if r.cut and r.cut[i] then
				continue
			end
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

-- nearest sample of another road (optionally only bigger roads) within radius of a point.
-- (the radius is written for a road HALF wide: for a road with its own half it is that much less or
-- more, `dh`, so "HALF + 6" always means "6 past that road's edge")
local function otherNear(roads, grid, pos: Vector3, self: number, radius: number, biggerThan: number?): (number?, number?)
	local best, bestD = nil, math.huge
	local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
	local reach = math.ceil((radius + maxDh) / 24)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local cell = grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					local rj = e[1]
					if rj ~= self and (biggerThan == nil or roads[rj].rank < biggerThan) then
						local q = roads[rj].pts[e[2]].pos
						local d = Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude
						if d < radius + roads[rj].dh and d < bestD then
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
		-- (r.aligned: its heights were already worked out against the roads it joins, north_roads.py)
		if r.aligned then
			continue
		end
		local pts = r.pts
		local n = #pts
		local H = r.half or HALF -- (this road's own half width)
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
				if pts[i].wl >= H - 0.5 and pts[i].wr >= H - 0.5 then
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
				if not target[i] and pts[i].wl >= H - 0.5 and pts[i].wr >= H - 0.5 then
					local cx, cz = math.floor(pts[i].pos.X / 24), math.floor(pts[i].pos.Z / 24)
					-- (the two parts' carriageways overlap once their centres are under two half widths apart)
					local bestD = 2 * H - 2
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
Roads.triangle = triangle

function Roads.prepared(data, cut)
	local roads, grid = prepare(data, cut)
	alignJunctions(roads, grid)
	return roads
end

function Roads.build(data, opts)
	opts = opts or {}
	local box = opts.box
	local parent = opts.parent
	local roads, grid = prepare(data, opts.cut)
	alignJunctions(roads, grid)
	local count = 0
	local zebraSpots: { Vector3 } = {}
	-- (Yangon 2026-11-13) colours and options that are nil for Monaco
	local pal = opts.palette or {}
	local asphalt = pal.asphalt or ASPHALT
	local paint = pal.paint or PAINT
	local zone = opts.sideZone
	if opts.keepEdges then
		Roads.debugEdges = {}
	end
	for ri, r in roads do
		local buildIt = not (opts.only and not opts.only[r.name])
		if not buildIt and not (opts.keepEdges and opts.edgesFor and opts.edgesFor[r.name]) then
			continue
		end
		local folder = Instance.new("Folder")
		folder.Name = r.name
		-- (opts.live: the real folder is in the place from the start and gets each chunk as it is made;
		-- `folder` is then only the chunk being built)
		local live: Instance? = nil
		if opts.live and buildIt then
			live = (parent :: Instance):FindFirstChild(r.name)
			if not live then
				local f = Instance.new("Folder")
				f.Name = r.name
				f.Parent = parent
				live = f
			end
		end
		local function flush()
			if live then
				for _, c in folder:GetChildren() do
					c.Parent = live
				end
			end
		end
		local pts = r.pts
		local n = #pts
		local H = r.half or HALF -- (this road's own half width)
		local cutSet = r.cut
		local noSlab = if opts.noSlab then opts.noSlab[r.name] else nil
		local town = r.kind == "street" or r.name == "Town Road" or r.name == "Coast Road"
			or (opts.pave ~= nil and (opts.pave == true or (type(opts.pave) == "table" and opts.pave[r.name] == true)))
		local paver = pal.paver or (if string.find(r.name, "Casino") then STONE_PAVER else PAVER)
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
				if (if side == 1 then pts[i].wl else pts[i].wr) < H - 0.5 then
					continue -- a narrowed edge stops at the wall between this road and the next
				end
				local y = bigSurface(roads, grid, edge[i], ri, r.rank, if r.aligned then HALF + 1 else HALF + 8) -- (a little past its edge: the joint stays level)
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
		local GRADE, CROSS = opts.edgeGrade or 0.19, 0.06 -- (GRADE: over the steepest climb, 16%)
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
		if opts.debug or opts.keepEdges then
			Roads.debugEdges = Roads.debugEdges or {}
			Roads.debugEdges[r.name] = { L = edgeL, R = edgeR, waitL = waitL, waitR = waitR, pinL = pinL, pinR = pinR }
		end
		if not buildIt then
			folder:Destroy()
			continue -- (opts.edgesFor: only its edges were wanted)
		end
		local dash = 0
		local zebraDone = {}
		for i = 1, n - 1 do
			local a, b = pts[i], pts[i + 1]
			if not (inBox(box, a.pos) or inBox(box, b.pos)) then
				continue
			end
			-- (opts.cut: nothing at all between cut samples; the last piece before a cut ends square)
			if cutSet and (cutSet[i] or cutSet[i + 1]) then
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
			local grow = math.min(math.tan(turn / 2) * (H + WALK) * 2, 24)
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
				local props: { [string]: any } = { Name = "Road", Material = Enum.Material.Asphalt, Color = asphalt }
				if opts.noShadows then
					props.CastShadow = false
				end
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
				-- (opts.noSlab: this piece of surface is a mouth built by another tool)
				if noSlab and noSlab[i] then
					strips = 0
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
				-- (2026-11-04: as wide as this road, not a full one: on the 1+1 Summit Pass the full width
				-- carved under the next hairpin leg up)
				local wide = math.max(a.wl, a.wr, b.wl, b.wr) + WALK
				workspace.Terrain:FillBlock(cf * CFrame.new(0, SLAB / 2 - 4 + 11, 0), Vector3.new(wide * 2, 22, len + grow), Enum.Material.Air)
			end
			-- outside the town: flush concrete shoulders (the ground under them is cleared too)
			if not town and not opts.surfaceOnly then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					local sidePos = mid + right * side * (H + WALK / 2)
					local narrow = math.min(if side < 0 then a.wl else a.wr, if side < 0 then b.wl else b.wr) < H - 0.5
					if otherNear(roads, grid, sidePos, ri, HALF + 2) == nil and not selfNear(roads, grid, sidePos, ri, i, H + 1) and not narrow then
						local cf = stripCF(a2, b2, side * (H + WALK / 2), -3 - 0.02)
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
				if wa < H - 0.5 and wb < H - 0.5 and not opts.noLegWalls then
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
			if town and not opts.surfaceOnly then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					local sidePos = mid + right * side * (H + WALK / 2)
					local kerbPos = mid + right * side * (H + 0.45)
					local narrow = math.min(if side < 0 then a.wl else a.wr, if side < 0 then b.wl else b.wr) < H - 0.5
					-- (opts.sideZone: the zone says where another road is, and cuts the pieces exactly)
					if (zone ~= nil or otherNear(roads, grid, sidePos, ri, HALF + 2) == nil) and not a.tunnel and not narrow
						and not selfNear(roads, grid, sidePos, ri, i, H + 1) and not selfNear(roads, grid, kerbPos, ri, i, H - 1) then
						-- 6 studs deep: the terrain under the road is cleared 4 studs down.
						-- (owner, 2026-11-02: "the curbs are glitching out") the kerb and pavement follow the
						-- road's own edge (its height can differ from the centre line's at junctions now),
						-- and neighbouring pieces differ by a hair in width and height so their overlaps
						-- never share a face (that flickered). A fan's pivot (the inside of a tight bend,
						-- where the edge stands still) keeps the old centre-line strip.
						-- (owner, 2026-11-03: kerbs still flickered) the kerb's road face sat exactly on the
						-- pavement's and the road's edge, and its top only 0.04 over the pavers: it now
						-- stands 0.05 nearer the road and 0.1 over the pavers.
						local ea = if side < 0 then edgeL[i] else edgeR[i]
						local eb = if side < 0 then edgeL[i + 1] else edgeR[i + 1]
						local edgeLen = Vector2.new(eb.X - ea.X, eb.Z - ea.Z).Magnitude
						local alt = if i % 2 == 0 then 1 else 0
						local walkCF, kerbCF, walkLen, kerbLen
						local paveProps: { [string]: any } = { Name = "Pavement", Material = pal.paverMaterial or Enum.Material.Pavement, Color = paver }
						if pal.paverVariant then
							paveProps.MaterialVariant = pal.paverVariant
						end
						-- (a painted kerb: every second piece in the band colour)
						local kerbColor = if pal.kerbBand and alt == 1 then pal.kerbBand else (pal.kerb or KERB)
						local kerbMaterial = pal.kerbMaterial or Enum.Material.Concrete
						local wholeWalk, wholeKerb = true, true
						if zone and edgeLen > 0.5 then
							-- (Yangon 2026-11-13) exact mouths. The pavement is the strip from the road's edge to
							-- WALK out; what lies in a zone (another road's mouth, a roundabout) is cut off on the
							-- zone's own edge, so a street mouth is exactly as wide as the street. A cut piece is
							-- made of triangles; a whole piece is the usual block.
							-- Each piece reaches out along its own two samples' right vectors, so neighbours share
							-- their ends exactly, bend or not: nothing overlaps (the old blocks overlap on bends
							-- with tops 0.006 apart, which is under the flicker rule's 0.05) and nothing is longer
							-- than its slab at a cut end. A straight whole piece is one block, any other triangles.
							local outA = Vector3.new(-a.dir.Z, 0, a.dir.X).Unit * side
							local outB = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit * side
							-- (the pavement starts at the kerb's back face, 0.85 out, not under the kerb: at a mouth or
							-- a cut end the two end faces would lie in one plane over each other and flicker)
							local lift = Vector3.new(0, CURB_UP, 0)
							local inner = 0.85
							local quad = { ea + outA * inner + lift, ea + outA * WALK + lift, eb + outB * WALK + lift, eb + outB * inner + lift }
							local pieces, whole = clipPieces(quad, function(p)
								return zone(r.name, p, "Pavement")
							end, 5)
							wholeWalk = false -- (laid here)
							paveProps.CastShadow = false
							local run = (eb - ea) * Vector3.new(1, 0, 1)
							if whole and (outA - outB).Magnitude < 2e-3 and math.abs(run.Unit:Dot(outA)) < 2e-3 then -- (off square by under 0.02 studs over the pavement's width)
								local drop = Vector3.new(0, CURB_UP - 3, 0)
								local pa, pb = ea + outA * ((WALK + inner) / 2) + drop, eb + outB * ((WALK + inner) / 2) + drop
								paveProps.Size = Vector3.new(WALK - inner, 6, (pb - pa).Magnitude)
								paveProps.CFrame = CFrame.lookAt((pa + pb) / 2, pb)
								newPart(paveProps, folder)
								count += 1
							else
								for _, poly in pieces do
									for k = 2, #poly - 1 do
										if not sliver(poly[1], poly[k], poly[k + 1]) then
											count += triangle(poly[1], poly[k], poly[k + 1], 6, paveProps, folder)
										end
									end
								end
							end
							-- The kerb, exact as well: pal.kerbSplit bands to a piece (pal.kerbBand is every second
							-- band's colour: a painted kerb). Each band's footprint runs from 0.05 inside the road's
							-- edge to 0.85 outside it, between the two samples' own right vectors, and is cut on a
							-- zone's edge like the pavement. So bands butt end to end with no overlap (two colours
							-- lying over each other would flicker), a cut end follows the mouth however it slants,
							-- and the red and white rhythm does not restart at a cut. A square whole band is a
							-- block, any other triangles.
							wholeKerb = false -- (laid here)
							local nb = pal.kerbSplit or 1
							local kTop = Vector3.new(0, CURB_UP + 0.1, 0)
							local kIn0, kIn1 = ea - outA * 0.05 + kTop, eb - outB * 0.05 + kTop
							local kOut0, kOut1 = ea + outA * 0.85 + kTop, eb + outB * 0.85 + kTop
							local kSquare = (outA - outB).Magnitude < 0.02 and math.abs(run.Unit:Dot(outA)) < 0.02 -- (under 0.02 studs off over its 0.9 width)
							for kb = 0, nb - 1 do
								local t0, t1 = kb / nb, (kb + 1) / nb
								local second = if nb > 1 then kb % 2 == 1 else alt == 1
								local kerbProps: { [string]: any } = { Name = "Kerb", Material = kerbMaterial, Color = if second and pal.kerbBand then pal.kerbBand else (pal.kerb or KERB), CastShadow = false }
								local kq = { kIn0:Lerp(kIn1, t0), kOut0:Lerp(kOut1, t0), kOut0:Lerp(kOut1, t1), kIn0:Lerp(kIn1, t1) }
								local kpieces, kwhole = clipPieces(kq, function(p)
									return zone(r.name, p, "Kerb")
								end, 4)
								if kwhole and kSquare then
									local c0, c1 = (kq[1] + kq[2]) / 2, (kq[4] + kq[3]) / 2
									local down = Vector3.new(0, -3.02, 0)
									kerbProps.Size = Vector3.new(0.9, 6.04, (c1 - c0).Magnitude)
									kerbProps.CFrame = CFrame.lookAt((c0 + c1) / 2 + down, c1 + down)
									newPart(kerbProps, folder)
									count += 1
								else
									for _, kpoly in kpieces do
										for k = 2, #kpoly - 1 do
											if not sliver(kpoly[1], kpoly[k], kpoly[k + 1]) then
												count += triangle(kpoly[1], kpoly[k], kpoly[k + 1], 6.04, kerbProps, folder)
											end
										end
									end
								end
							end
						end
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
							kerbCF, kerbLen = along(0.4, CURB_UP + 0.08 - 3 + alt * 0.006)
						else
							walkCF = stripCF(a2, b2, side * (H + WALK / 2), CURB_UP - 3 + alt * 0.006)
							kerbCF = stripCF(a2, b2, side * (H + 0.4), CURB_UP + 0.08 - 3 + alt * 0.006)
							walkLen = len + grow
							kerbLen = len + grow
							-- (a fan's pivot has no edge to cut along: the whole piece is in or out)
							if zone and zone(r.name, sidePos, "Pavement") then
								wholeWalk, wholeKerb = false, false
							end
						end
						if wholeWalk then
							paveProps.Size = Vector3.new(WALK - alt * 0.01, 6, walkLen)
							paveProps.CFrame = walkCF
							local pv = newPart(paveProps, folder)
							-- patterned paving in some quarters (owner 2026-11-02: "add some sidewalk
							-- patterns"); MaterialVariants in MaterialService (Creator Store textures)
							local pattern = PATTERNS[r.name]
							if pattern then
								pv.MaterialVariant = pattern[1]
								pv.Color = pattern[2]
							end
							count += 1
						end
						if wholeKerb then
							local k = newPart({ Name = "Kerb", Size = Vector3.new(0.9 - alt * 0.01, 6.04, kerbLen), CFrame = kerbCF, Material = kerbMaterial, Color = kerbColor }, folder)
							k.CastShadow = false
							count += 1
						end
					end
				end
			end
			-- lines (painted on the slab's own plane). (2026-11-03) These chord-shifted lines cross on tight
			-- bends and point the wrong way: after a build, run RoadLines.build (tools/riviera/RoadLines.luau),
			-- which replaces them with lines that follow the curve and sit on the road by raycast.
			if opts.noLines then
				-- (RoadLines draws them)
			elseif not (inJunction[i] or inJunction[i + 1]) then
				dash += 1
				local lines = {}
				local wl, wr = math.min(a.wl, b.wl), math.min(a.wr, b.wr)
				table.insert(lines, { x = wr - 1.2, w = 0.6, solid = true })
				table.insert(lines, { x = -(wl - 1.2), w = 0.6, solid = true })
				if dash % 2 == 0 then
					table.insert(lines, { x = 0, w = 0.5 })
					if wr > H / 2 + 2 then
						table.insert(lines, { x = H / 2, w = 0.4 })
					end
					if wl > H / 2 + 2 then
						table.insert(lines, { x = -H / 2, w = 0.4 })
					end
				end
				for _, l in lines do
					local cf = stripCF(a.pos, b.pos, l.x, LINE_T / 2 + 0.04)
					local p = newPart({ Name = "Line", Size = Vector3.new(l.w, LINE_T, if l.solid then len + 0.3 else len * 0.9), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = paint }, folder)
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
				-- (owner, 2026-11-03: "remove cross walk on wide curves and only put cross walk on the
				-- main part of the city map"): none on the hill roads, above the town (92 up) or where
				-- the road bends more than 20 degrees over about 70 studs
				local hill = r.name == "Mountain Road" or string.find(r.name, "Hairpin") ~= nil or string.find(r.name, "Terrace") ~= nil or string.find(r.name, "Switchbacks") ~= nil
				local da, db = pts[math.max(1, i - 6)].dir, pts[math.min(n, i + 6)].dir
				local bend = if da.Magnitude > 0 and db.Magnitude > 0 then math.deg(math.acos(math.clamp(da.Unit:Dot(db.Unit), -1, 1))) else 0
				if hill or cf.Position.Y > 92 or bend > 20 then
					return
				end
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
					local p = newPart({ Name = "Zebra", Size = Vector3.new(2.6, LINE_T, 10), CFrame = sc, Material = Enum.Material.SmoothPlastic, Color = paint }, folder)
					decor(p)
					count += 1
				end
			end
			if town and i > 1 and inJunction[i - 1] and not inJunction[i] and not zebraDone[i] and not opts.surfaceOnly and not opts.noZebra then
				zebraDone[i] = true
				-- (left / right as the road runs a -> b: the crossing's stripes run across it)
				zebra(stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, -len / 2 + 7), { math.min(a.wl, b.wl), math.min(a.wr, b.wr) })
			end
			if i < n - 1 and inJunction[i + 1] and not inJunction[i] and not opts.surfaceOnly and not opts.noZebra then
				zebra(stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, len / 2 - 7), { math.min(a.wl, b.wl), math.min(a.wr, b.wr) })
			end
			if i % 40 == 0 then
				flush()
				task.wait()
			end
		end
		-- a street that ends on no other road gets a round turning circle, flush with the road (no
		-- drop off the slab's end)
		if not r.closed and not opts.noTurningCircle then
			for _, e in { { pts[1], -1 }, { pts[n], 1 } } do
				local p = e[1]
				-- (a cut end is no dead end: the road goes on in another tool's hands)
				if inBox(box, p.pos) and otherNear(roads, grid, p.pos, ri, HALF + WALK) == nil and not (cutSet and cutSet[if e[2] < 0 then 1 else n]) then
					local r0 = H + WALK
					local centre = p.pos + p.dir.Unit * e[2] * (r0 - H)
					newPart({ Name = "TurningCircle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(SLAB, r0 * 2, r0 * 2), CFrame = CFrame.new(centre - Vector3.new(0, SLAB / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Asphalt, Color = asphalt }, folder)
					workspace.Terrain:FillBlock(CFrame.new(centre + Vector3.new(0, 11 - 4 + 0.01, 0)), Vector3.new(r0 * 2, 22, r0 * 2), Enum.Material.Air)
					count += 1
				end
			end
		end
		if live then
			flush()
			folder:Destroy()
			if #live:GetChildren() == 0 then
				live:Destroy()
			end
		elseif #folder:GetChildren() > 0 then
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
	local roads = prepare(data, opts.cut)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { opts.parent, workspace.Terrain }
	local bumps = {}
	local checked = 0
	for _, r in roads do
		-- (Yangon 2026-11-13: opts.only = the roads to drive; opts.lanes = { [road name] = { offsets } },
		-- a street's lanes are not a main road's; opts.cut as in Roads.build)
		if opts.only and not opts.only[r.name] then
			continue
		end
		local pts = r.pts
		for _, lane in (opts.lanes and opts.lanes[r.name]) or { -24, -8, 8, 24 } do
			local last: Vector3? = nil
			for i = 1, #pts - 1 do
				local a, b = pts[i], pts[i + 1]
				if not inBox(box, a.pos) or (r.cut and (r.cut[i] or r.cut[i + 1])) then
					last = nil
					continue
				end
				local d = b.pos - a.pos
				local right = Vector3.new(-d.Z, 0, d.X).Unit
				local steps = math.max(1, math.floor(Vector2.new(d.X, d.Z).Magnitude))
				-- (the first point after a cut stands exactly on the slab's square end: a ray there can
				-- slip past the edge, which is no bump)
				for k = (if r.cut and r.cut[i - 1] then 1 else 0), steps - 1 do
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
