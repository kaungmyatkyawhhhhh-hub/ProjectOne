--[[
	Yangon roads (Studio, Edit mode). Build step 3, 13 Nov 2026: the three main roads, the Hanthawaddy
	Roundabout and the road lines. Later steps (flyovers, streets) call the same tool.

	Lives in ServerStorage.ClaudeTools.YangonRoads next to Roads and RoadLines (tools/riviera). Use:
	  local Y = require(game.ServerStorage.ClaudeTools.YangonRoads:Clone())
	  Y.load()                       -- data, cuts, eased roundabout arms, mouths (prints nothing, returns a summary)
	  Y.spawn("roads", function() return Y.buildRoads(Y.MAIN) end)   -- long jobs run in the background:
	  Y.status()                     -- ... and this reads how far they are
	  Y.buildRoundabout()
	  Y.buildLines(Y.MAIN)
	  Y.checkBumps(), Y.checkPoints(200), Y.checkJunctions(), Y.checkMainMain(), Y.partCount(), Y.surfaceCheck(spots)

	What it adds to Roads.luau for Yangon:
	  * cuts: nothing is built inside a flyover corridor (70 studs either side of a deck's centre line) or
	    inside the roundabout. Y.cut is Roads.build's opts.cut; Y.cutEnds lists every cut end.
	  * the roundabout: a flat ring at the design height, an island, kerbs, pavement with a gap at each arm,
	    its lines. Roads that end in it are eased onto its height over EASE studs and end exactly on its edge.
	  * mouths: where a built road ends on a bigger one (New Road and University Avenue on the loop) its
	    slab stops exactly on the bigger road's edge: one slab only in the junction, no overlap, no hole.
	  * Y.sideZone: where a road's kerb and pavement must stop (Roads.build's opts.sideZone): at a smaller
	    road's carriageway edge (so a street mouth is as wide as the street), and for the smaller road at
	    the bigger road's kerb / pavement edge, so corners are covered once.
]]

local M = {}

local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")

M.SPM = 1.6 -- studs per metre
M.C = Vector3.new(29072, 47.27, 1172.8) -- roundabout centre, at the ring's road height
M.R_IN, M.R_OUT = 60, 108 -- island radius, the ring's outer radius
M.RING_V = 108.06 -- the outer polygon's corners (its sides then pass 108 at their middle: nothing of an arm is closer than 108)
M.N = 96 -- sides of the ring
M.R_CUT = 94 -- samples nearer the centre than this are cut (not built, not seen by other roads)
M.WALK, M.KERB_W, M.CURB_UP, M.SLAB = 10, 0.9, 0.5, 2 -- as in Roads.luau
M.CORRIDOR = 70 -- flyover corridor: this far either side of the deck's centre line
M.EASE = 128 -- an arm reaches the ring's height over this many studs ...
M.FLAT = 12 -- ... and is already flat at it this far outside the ring (its pavement meets the ring's pavement level)
M.LINE_T, M.LIFT = 0.04, 0.08 -- paint: thickness, and how far over the road (flicker rule)
M.MAIN = { "Yangon Loop", "New Road", "University Avenue" }

-- the Yangon look (Roblox Playbook/2026-11-13 Research - Yangon road look.md)
-- 43 street photos: plain grey concrete pavement, red and white kerb bands of about 1 m (a quarter of a
-- car: 3.2 studs for our 3-studs-a-metre cars), every line white, one solid centre line.
-- The asphalt stays the game's own dark one (the real one is a lighter warm grey: the owner's call).
M.palette = {
	asphalt = Color3.fromRGB(46, 47, 50),
	paver = Color3.fromRGB(128, 124, 116), -- (the photos' mid grey, at the darker end: at 150 the white kerb bands sank into it)
	-- (poured concrete. Tried on the roundabout, 13 Nov: Roblox's Pavement draws small pavers, and it and the
	-- place's Concrete show each triangle's own texture direction on bends; Sandstone reads as plain, slightly
	-- stained concrete and shows no seams)
	paverMaterial = Enum.Material.Sandstone,
	-- (owner, 13 Nov: the white bands read blue in shade. Tried on the Pyay Road straight: the place's Concrete
	-- texture (RivConcrete2) is blue-grey, and the shade light is blue. Smooth paint and a white a touch warm
	-- read white in shade and in sun)
	kerb = Color3.fromRGB(255, 228, 192), -- (reads neutral white in the blue shade, a warm white in sun)
	kerbBand = Color3.fromRGB(200, 40, 38) :: Color3?,
	kerbSplit = 2,
	kerbMaterial = Enum.Material.SmoothPlastic,
	paint = Color3.fromRGB(235, 235, 230),
}
M.centre = { solid = true } :: { [string]: any }? -- the middle line (RoadLines opts.centre): one solid white line

local C = M.C
local TAU = 2 * math.pi

local function hyp(x: number, z: number): number
	return math.sqrt(x * x + z * z)
end

local function radius(s): number
	return hyp(s[1] - C.X, s[3] - C.Z)
end

-- distance from a point to the segment a-b (flat), and where along it (0..1)
local function segDist(px, pz, ax, az, bx, bz): (number, number)
	local vx, vz = bx - ax, bz - az
	local L = vx * vx + vz * vz
	local t = if L > 1e-12 then math.clamp(((px - ax) * vx + (pz - az) * vz) / L, 0, 1) else 0
	return hyp(px - ax - t * vx, pz - az - t * vz), t
end

local function rightOf(s): (number, number)
	local L = hyp(s[4], s[5])
	return -s[5] / L, s[4] / L
end

-- a road's edge at sample i (side -1 left, 1 right, 0 the centre), flat, exactly as Roads.build lays it
local function edgeXZ(o, i: number, side: number): (number, number)
	local s = o.s[i]
	local rx, rz = rightOf(s)
	return s[1] + rx * o.half * side, s[3] + rz * o.half * side
end

-- a road's half width at sample i (the wider side: step 4 widens the loop where side lanes leave it)
function M.halfAt(o, i: number): number
	local s = o.s[i]
	return math.max(s[7] or o.half, s[8] or o.half)
end

------------------------------------------------------------------------------------------------
-- data
------------------------------------------------------------------------------------------------

function M.load()
	M.Roads = require(SS.ClaudeTools.Roads:Clone())
	M.RoadLines = require(SS.ClaudeTools.RoadLines:Clone())
	local YD = SS.YangonData
	-- (step 4: Roads2_* = ygn_roads_v2.json from tools/yangon/d7_flyovers.py: the side lanes, explicit cuts,
	-- the decks; without it the step 3 data and its flyover corridors)
	local pre = if YD:FindFirstChild("Roads2_1") then "Roads2_" else "Roads_"
	M.v2 = pre == "Roads2_"
	local parts, k = {}, 1
	while YD:FindFirstChild(pre .. k) do
		parts[k] = require(YD[pre .. k]:Clone())
		k += 1
	end
	M.data = Http:JSONDecode(table.concat(parts))
	M.design = Http:JSONDecode(require(YD.Design:Clone()))
	M.R, M.list = {}, {}
	local seen = {}
	for ri, r in M.data.roads do
		assert(r.half, "no half width on " .. r.name .. ": run tools/yangon/patch_ranks.py and patch YangonData")
		assert(not seen[r.rank], "two roads share rank " .. r.rank)
		seen[r.rank] = true
		local chain = { 0 }
		for i = 2, #r.s do
			chain[i] = chain[i - 1] + hyp(r.s[i][1] - r.s[i - 1][1], r.s[i][3] - r.s[i - 1][3])
		end
		local o = { index = ri, name = r.name, kind = r.kind, rank = r.rank, half = r.half, s = r.s, n = #r.s, chain = chain,
			startsOnEnd = r.startsOnEnd, endsOnEnd = r.endsOnEnd, walkL = r.walkL, walkR = r.walkR }
		M.R[r.name] = o
		M.list[ri] = o
	end

	-- cuts. M.cut[road][sample] = why (a flyover's name, or the roundabout's)
	M.cut = {}
	for _, o in M.list do
		M.cut[o.name] = {}
	end
	local W = M.CORRIDOR
	if M.v2 then
		-- (explicit: the decks' own samples and the loop between a side lanes' split and where it resumes;
		-- the lists are 0-based sample numbers from Python)
		M.MAIN = { "Yangon Loop", "New Road", "University Avenue", "Pyay Flyover West Lane", "Pyay Flyover East Lane 1",
			"Pyay Flyover East Lane 2", "Kabar Aye East Lane", "Kabar Aye West Lane" }
		for road, list in M.data.cut do
			for _, i in list do
				M.cut[road][i + 1] = "flyover"
			end
		end
	end
	for _, f in (if M.v2 then {} else M.design.flyovers) do
		local r = M.R[f.road]
		local from, to = f.from_m * M.SPM, f.to_m * M.SPM
		-- (Kabar Aye: the deck ends at 2,729 m, then New Road runs 92 m more on the loop's own line down
		-- to where it lands. A road that ends within 100 m of its deck is in the corridor to its end.)
		if r.chain[r.n] - to < 100 * M.SPM then
			to = math.huge
		end
		local deck = {}
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for i = 1, r.n do
			if r.chain[i] >= from and r.chain[i] <= to then
				table.insert(deck, i)
				M.cut[r.name][i] = f.name
				x0, x1 = math.min(x0, r.s[i][1]), math.max(x1, r.s[i][1])
				z0, z1 = math.min(z0, r.s[i][3]), math.max(z1, r.s[i][3])
			end
		end
		for _, o in M.list do
			if o ~= r then
				-- (a sample is in the corridor when any of its cross-section is: the carriageway and both
				-- pavements, not only its middle; a road meeting the corridor at a slant would poke in)
				local reach = o.half + M.WALK
				for i = 1, o.n do
					local px, pz = o.s[i][1], o.s[i][3]
					if px > x0 - W - reach and px < x1 + W + reach and pz > z0 - W - reach and pz < z1 + W + reach and not M.cut[o.name][i] then
						local rx, rz = rightOf(o.s[i])
						for _, lat in { 0, -reach, reach, -reach / 2, reach / 2 } do
							local qx, qz = px + rx * lat, pz + rz * lat
							for d = 1, #deck - 1 do
								local a, b = r.s[deck[d]], r.s[deck[d + 1]]
								if segDist(qx, qz, a[1], a[3], b[1], b[3]) < W then
									M.cut[o.name][i] = f.name
									break
								end
							end
							if M.cut[o.name][i] then
								break
							end
						end
					end
				end
			end
		end
	end
	for _, o in M.list do
		for i = 1, o.n do
			if radius(o.s[i]) < M.R_CUT and not M.cut[o.name][i] then
				M.cut[o.name][i] = "Hanthawaddy Roundabout"
			end
		end
	end
	-- roads that end in the roundabout: eased onto the ring's height (the ring is flat at C.Y)
	M.arms = {}
	for _, o in M.list do
		for _, e in { { 1, 1 }, { o.n, -1 } } do
			local i0, step = e[1], e[2]
			if radius(o.s[i0]) < M.R_OUT then
				-- flat at the ring's height out to R0 (past the ring's own pavement), eased from there
				local R0 = M.R_OUT + M.FLAT
				local i = i0
				while radius(o.s[i]) < R0 do
					i += step
				end
				local a, b = o.s[i - step], o.s[i]
				local ra, rb = radius(a), radius(b)
				local yRing = a[2] + (b[2] - a[2]) * (R0 - ra) / (rb - ra)
				local shift = C.Y - yRing
				local j = i0
				while j >= 1 and j <= o.n do
					local rr = radius(o.s[j])
					if rr < R0 then
						o.s[j][2] = C.Y
					elseif rr - R0 < M.EASE then
						local u = (rr - R0) / M.EASE
						o.s[j][2] += shift * (1 - u * u * (3 - 2 * u))
					else
						break
					end
					j += step
				end
				table.insert(M.arms, { road = o.name, o = o, i0 = i0, step = step, first = i, shift = shift })
			end
		end
	end

	-- every cut end: the last sample that is built, next to one that is not (heights after the easing)
	M.cutEnds = {}
	for _, o in M.list do
		local cut = M.cut[o.name]
		for i = 1, o.n do
			if not cut[i] then
				local why = (i > 1 and cut[i - 1]) or (i < o.n and cut[i + 1])
				if why and why ~= "Hanthawaddy Roundabout" then
					local s = o.s[i]
					table.insert(M.cutEnds, { road = o.name, sample = i, m = o.chain[i] / M.SPM, x = s[1], y = s[2], z = s[3], why = why, cutIs = if i > 1 and cut[i - 1] then "before" else "after" })
				end
			end
		end
	end

	-- a 24-stud grid of every sample that is not cut
	M.grid = {}
	for _, o in M.list do
		local cut = M.cut[o.name]
		for i = 1, o.n do
			if not cut[i] then
				local key = math.floor(o.s[i][1] / 24) .. "," .. math.floor(o.s[i][3] / 24)
				local cell = M.grid[key]
				if not cell then
					cell = {}
					M.grid[key] = cell
				end
				table.insert(cell, { o.index, i })
			end
		end
	end
	M.findMouths(M.MAIN)
	M.findCorners()
	local nCut = 0
	for _, o in M.list do
		for _ in M.cut[o.name] do
			nCut += 1
		end
	end
	return string.format("%d roads, %d cut samples, %d cut ends, %d roundabout arms, %d mouths", #M.list, nCut, #M.cutEnds, #M.arms, #M.mouths)
end

-- the nearest kept sample of every road within `reach` cells of a point: { [road index] = { distance, sample } }
function M.near(px: number, pz: number, reach: number)
	local best = {}
	local cx, cz = math.floor(px / 24), math.floor(pz / 24)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local cell = M.grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					local s = M.list[e[1]].s[e[2]]
					local d = hyp(s[1] - px, s[3] - pz)
					local b = best[e[1]]
					if not b then
						best[e[1]] = { d, e[2] }
					elseif d < b[1] then
						b[1], b[2] = d, e[2]
					end
				end
			end
		end
	end
	return best
end

-- exact distance from a point to road o's centre line near its sample i. With (ax, az, nx, nz) only the
-- part of the line on the n side of the point a counts (a street is cut at the main road's middle).
-- Also returns the foot point.
local function polyDist(o, i: number, px, pz, ax: number?, az: number?, nx: number?, nz: number?): (number, number?, number?)
	local best, fx, fz = math.huge, nil, nil
	local cut = M.cut[o.name]
	local skipped = false
	for j = math.max(1, i - 2), math.min(o.n - 1, i + 1) do
		if not cut[j] and not cut[j + 1] then
			local a, b = o.s[j], o.s[j + 1]
			local x1, z1, x2, z2 = a[1], a[3], b[1], b[3]
			local ok = true
			if nx and nz and ax and az then
				local s1 = (x1 - ax) * nx + (z1 - az) * nz
				local s2 = (x2 - ax) * nx + (z2 - az) * nz
				if s1 < 0 and s2 < 0 then
					ok = false
				elseif s1 < 0 then
					local t = s1 / (s1 - s2)
					x1, z1 = x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
				elseif s2 < 0 then
					local t = s2 / (s2 - s1)
					x2, z2 = x2 + (x1 - x2) * t, z2 + (z1 - z2) * t
				end
			end
			if ok then
				local d, t = segDist(px, pz, x1, z1, x2, z2)
				-- (a road ends square at a cut: nothing of it lies past that end. Step 4's side lanes start
				-- right there, beside it)
				if (t >= 1 - 1e-9 and j + 2 <= o.n and cut[j + 2]) or (t <= 1e-9 and j - 1 >= 1 and cut[j - 1]) then
					skipped = true
					d = math.huge
				end
				if d < best then
					best, fx, fz = d, x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
				end
			end
		end
	end
	if best == math.huge and not nx and not skipped then
		local a = o.s[i]
		best, fx, fz = hyp(px - a[1], pz - a[3]), a[1], a[3]
	end
	return best, fx, fz
end
M.polyDist = polyDist

-- Roads.build's opts.sideZone: must this road's kerb / pavement stay out of this spot?
function M.sideZone(name: string, pos: Vector3, what: string): boolean
	local px, pz = pos.X, pos.Z
	-- a round corner takes over here
	if M.inCorner(px, pz) then
		return true
	end
	-- just past a round corner, the joining road's own kerb and pavement (the other road's go)
	local owner = M.ownedBy(px, pz)
	if owner then
		return owner ~= name
	end
	-- the roundabout: an arm's kerb stops at the ring's kerb, its pavement at the ring's pavement
	if hyp(px - C.X, pz - C.Z) < M.RING_V + (if what == "Kerb" then M.KERB_W else M.WALK) then
		return true
	end
	local me = M.R[name]
	local near = M.near(px, pz, 3)
	local mine = near[me.index]
	local ax, az, nx, nz = nil, nil, nil, nil
	for oi, b in near do
		if oi == me.index or b[1] > 72 then
			continue
		end
		local o = M.list[oi]
		if me.kind == "side" and o.kind == "side" then
			-- (step 4: two side lanes splitting from one road end: neither's kerb or pavement on the other)
			if polyDist(o, b[2], px, pz) < o.half + 1 then
				return true
			end
			continue
		end
		if o.rank < me.rank then
			-- a bigger road: my kerb stops at its kerb, my pavement at its pavement's far edge
			if polyDist(o, b[2], px, pz) < o.half + (if what == "Kerb" then M.KERB_W else M.WALK) then
				return true
			end
		else
			-- a smaller road: only its carriageway (the mouth is as wide as the road), and only the part
			-- of it on my side of my own centre line (a T's far side keeps its kerb)
			if ax == nil and mine then
				local _, fx, fz = polyDist(me, mine[2], px, pz)
				if fx and fz then
					local L = hyp(px - fx, pz - fz)
					if L > 1e-6 then
						ax, az, nx, nz = fx, fz, (px - fx) / L, (pz - fz) / L
					end
				end
			end
			if polyDist(o, b[2], px, pz, ax, az, nx, nz) < o.half - 0.01 then
				return true
			end
		end
	end
	return false
end

------------------------------------------------------------------------------------------------
-- mouths: a road that ends on a bigger road, or in the roundabout
------------------------------------------------------------------------------------------------

-- For each end: k = the first cross-section that lies wholly outside the bigger road (or the ring).
-- Roads.build lays no slab between the end and k (M.noSlab); buildMouth lays it, cut on the edge.
function M.findMouths(names: { string })
	M.mouths, M.noSlab = {}, {}
	for _, name in names do
		local o = M.R[name]
		M.noSlab[name] = {}
		for _, e in { { 1, 1 }, { o.n, -1 } } do
			local i0, step = e[1], e[2]
			if (i0 == 1 and o.startsOnEnd) or (i0 == o.n and o.endsOnEnd) then
				continue -- (step 4: it carries on from that road's cut end, square on, no junction)
			end
			local s0 = o.s[i0]
			local m = nil
			if radius(s0) < M.R_OUT then
				m = { road = name, i0 = i0, step = step, ring = true, on = "Hanthawaddy Roundabout" }
			elseif not M.cut[name][i0] then
				local bestRank = nil
				for oi, b in M.near(s0[1], s0[3], 2) do
					local big = M.list[oi]
					if big.rank < o.rank and polyDist(big, b[2], s0[1], s0[3]) < big.half and (not bestRank or big.rank < bestRank) then
						bestRank = big.rank
						m = { road = name, i0 = i0, step = step, big = big, bigI = b[2], on = big.name }
					end
				end
			end
			if m then
				local function outside(px, pz): boolean
					if m.ring then
						return hyp(px - C.X, pz - C.Z) > M.RING_V + 0.5
					end
					local b = M.near(px, pz, 3)[m.big.index]
					if not b then
						return true
					end
					return polyDist(m.big, b[2], px, pz) > m.big.half + 0.5
				end
				local k = i0
				while true do
					local all = not M.cut[name][k]
					if all then
						local lx, lz = edgeXZ(o, k, -1)
						local rx, rz = edgeXZ(o, k, 1)
						for t = 0, 8 do
							if not outside(lx + (rx - lx) * t / 8, lz + (rz - lz) * t / 8) then
								all = false
								break
							end
						end
					end
					if all then
						break
					end
					k += step
					assert(k >= 1 and k <= o.n, "mouth: " .. name .. " never leaves " .. m.on)
				end
				m.k = k
				for i = math.min(i0, k), math.max(i0, k) - 1 do
					M.noSlab[name][i] = true
				end
				table.insert(M.mouths, m)
			end
		end
	end
end

-- the ring's outer edge: N corners at RING_V
function M.ringOuter(): { Vector3 }
	local B = {}
	for j = 1, M.N do
		local a = TAU * (j - 1) / M.N
		B[j] = Vector3.new(C.X + M.RING_V * math.cos(a), C.Y, C.Z + M.RING_V * math.sin(a))
	end
	return B
end

-- where p-q crosses a-b (flat): t along p-q, u along a-b
local function segX(p: Vector3, q: Vector3, a: Vector3, b: Vector3): (number?, number?)
	local rX, rZ = q.X - p.X, q.Z - p.Z
	local sX, sZ = b.X - a.X, b.Z - a.Z
	local den = rX * sZ - rZ * sX
	if math.abs(den) < 1e-9 then
		return nil, nil
	end
	local t = ((a.X - p.X) * sZ - (a.Z - p.Z) * sX) / den
	local u = ((a.X - p.X) * rZ - (a.Z - p.Z) * rX) / den
	if t >= -1e-6 and t <= 1 + 1e-6 and u >= -1e-6 and u <= 1 + 1e-6 then
		return t, u
	end
	return nil, nil
end

local function firstHit(p: Vector3, q: Vector3, B: { Vector3 }, closed: boolean): (Vector3?, number?)
	local bestT, bestJ, bestU = nil, nil, nil
	local nB = #B
	for j = 1, (if closed then nB else nB - 1) do
		local t, u = segX(p, q, B[j], B[j % nB + 1])
		if t and u and (not bestT or t < bestT) then
			bestT, bestJ, bestU = t, j, u
		end
	end
	if bestT and bestJ and bestU then
		local u = math.clamp(bestU, 0, 1)
		return B[bestJ]:Lerp(B[bestJ % nB + 1], u), bestJ + u
	end
	return nil, nil
end

-- a simple polygon (flat outline, each corner with its own height) as triangles
local function earClip(poly: { Vector3 }): { { Vector3 } }
	local n = #poly
	local area = 0
	for i = 1, n do
		local p, q = poly[i], poly[i % n + 1]
		area += p.X * q.Z - q.X * p.Z
	end
	local idx = {}
	for i = 1, n do
		idx[i] = if area > 0 then i else n + 1 - i
	end
	local function cross(o: Vector3, a: Vector3, b: Vector3): number
		return (a.X - o.X) * (b.Z - o.Z) - (a.Z - o.Z) * (b.X - o.X)
	end
	local tris = {}
	local guard = 0
	while #idx > 3 and guard < 20000 do
		guard += 1
		local clipped = false
		local m = #idx
		for k = 1, m do
			local ia, ib, ic = idx[(k - 2) % m + 1], idx[k], idx[k % m + 1]
			local a, b, c = poly[ia], poly[ib], poly[ic]
			if cross(a, b, c) > 1e-6 then
				local ear = true
				for _, j in idx do
					if j ~= ia and j ~= ib and j ~= ic then
						local p = poly[j]
						if cross(a, b, p) > 1e-6 and cross(b, c, p) > 1e-6 and cross(c, a, p) > 1e-6 then
							ear = false
							break
						end
					end
				end
				if ear then
					table.insert(tris, { a, b, c })
					table.remove(idx, k)
					clipped = true
					break
				end
			end
		end
		if not clipped then
			-- nothing to clip: drop a corner that lies on a straight line (no area lost)
			local dropped = false
			for k = 1, m do
				local a, b, c = poly[idx[(k - 2) % m + 1]], poly[idx[k]], poly[idx[k % m + 1]]
				if math.abs(cross(a, b, c)) <= 1e-6 then
					table.remove(idx, k)
					dropped = true
					break
				end
			end
			if not dropped then
				break
			end
		end
	end
	if #idx == 3 then
		table.insert(tris, { poly[idx[1]], poly[idx[2]], poly[idx[3]] })
	end
	return tris
end
M.earClip = earClip

-- the slab between a road's cross-section k and the edge of what it ends on. Needs Roads.debugEdges
-- (Roads.build with keepEdges) for this road and, for a road mouth, the bigger road.
function M.buildMouth(m, folder: Instance)
	local o = M.R[m.road]
	local E = M.Roads.debugEdges[m.road]
	assert(E, "buildMouth: no edges kept for " .. m.road)
	local B: { Vector3 }, closed = {}, false
	if m.ring then
		B, closed = M.ringOuter(), true
	else
		local big = m.big
		local EB = M.Roads.debugEdges[big.name]
		assert(EB, "buildMouth: no edges kept for " .. big.name)
		-- (which side of the bigger road this road leaves on)
		local sk, sb = o.s[m.k], big.s[m.bigI]
		local rx, rz = rightOf(sb)
		local side = if (sk[1] - sb[1]) * rx + (sk[3] - sb[3]) * rz > 0 then "R" else "L"
		m.side = side
		local lo, hi = m.bigI, m.bigI
		local cutB = M.cut[big.name]
		while lo > 1 and not cutB[lo - 1] and m.bigI - lo < 60 do
			lo -= 1
		end
		while hi < big.n and not cutB[hi + 1] and hi - m.bigI < 60 do
			hi += 1
		end
		for i = lo, hi do
			table.insert(B, EB[side][i])
		end
	end
	local nB = #B
	-- an edge of this road, from k towards the end, up to where it meets B
	local function chain(edge: { Vector3 }): ({ Vector3 }, Vector3, number)
		local pts = { edge[m.k] }
		local i = m.k
		while true do
			local j = i - m.step
			if j < 1 or j > o.n then
				error("mouth: an edge of " .. m.road .. " never meets " .. m.on)
			end
			local X, at = firstHit(edge[i], edge[j], B, closed)
			if X and at then
				return pts, X, at
			end
			table.insert(pts, edge[j])
			i = j
		end
	end
	local ptsL, XL, atL = chain(E.L)
	local ptsR, XR, atR = chain(E.R)
	-- B's corners between XR and XL
	local between = {}
	local function walk(from: number, to: number)
		if from < to then
			for j = math.floor(from + 1e-6) + 1, math.ceil(to - 1e-6) - 1 do
				table.insert(between, B[(j - 1) % nB + 1])
			end
		else
			for j = math.ceil(from - 1e-6) - 1, math.floor(to + 1e-6) + 1, -1 do
				table.insert(between, B[(j - 1) % nB + 1])
			end
		end
	end
	if closed then
		local fwd = (atL - atR) % nB
		if fwd <= nB / 2 then
			walk(atR, atR + fwd)
		else
			walk(atR, atR - (nB - fwd))
		end
	else
		walk(atR, atL)
	end
	local poly = { XL }
	for i = #ptsL, 1, -1 do
		table.insert(poly, ptsL[i])
	end
	for i = 1, #ptsR do
		table.insert(poly, ptsR[i])
	end
	table.insert(poly, XR)
	for _, p in between do
		table.insert(poly, p)
	end
	-- (no two corners on one spot)
	local clean = {}
	for _, p in poly do
		local last = clean[#clean]
		if not last or hyp(p.X - last.X, p.Z - last.Z) > 0.01 then
			table.insert(clean, p)
		end
	end
	if #clean > 1 and hyp(clean[1].X - clean[#clean].X, clean[1].Z - clean[#clean].Z) <= 0.01 then
		table.remove(clean)
	end
	local outline = 0
	for i = 1, #clean do
		local p, q = clean[i], clean[i % #clean + 1]
		outline += p.X * q.Z - q.X * p.Z
	end
	outline = math.abs(outline) / 2
	local props = { Name = "Road", Material = Enum.Material.Asphalt, Color = M.palette.asphalt, CastShadow = false }
	local made, area = 0, 0
	for _, t in earClip(clean) do
		-- (a hair-thin triangle along the bigger road's edge would lean under that road's surface)
		if not M.Roads.sliver(t[1], t[2], t[3]) then
			made += M.Roads.triangle(t[1], t[2], t[3], M.SLAB, props, folder)
		end
		area += math.abs((t[2].X - t[1].X) * (t[3].Z - t[1].Z) - (t[2].Z - t[1].Z) * (t[3].X - t[1].X)) / 2
	end
	m.corners, m.area, m.outline, m.parts = #clean, area, outline, made
	m.poly = clean
	return made
end

------------------------------------------------------------------------------------------------
-- round corners (owner, 13 Nov: "fix sharp corners ... until theyre right")
------------------------------------------------------------------------------------------------
-- Where a road ends on a bigger road or in the roundabout, each of its two kerb lines meets the other
-- road's kerb line at a point P. The pavement fills the wedge between them (angle theta). A round
-- corner is a circle of radius r inside that wedge, touching both kerb lines (at TA on this road, TB on
-- the other): the kerb follows the arc from TA to TB, asphalt fills the space between the arc and P, the
-- pavement follows the arc on the inside. r = T * tan(theta / 2), so every corner starts about T studs
-- before P: a narrow nose (the New Road fork) gets a small r, a wide elbow a big one.
M.CORNER_T = 16 -- studs from P to where the curve starts, road on road...
M.CORNER_T_RING = 22 -- ...and on the roundabout
M.corners = {}

-- the foot of a point on a polyline { {x, z, i = index, f = fraction}... } (open): (distance, x, z, segment, t)
local function footOn(pts, px: number, pz: number): (number, number, number, number, number)
	local best, bx, bz, bs, bt = math.huge, 0, 0, 1, 0
	for k = 1, #pts - 1 do
		local a, b = pts[k], pts[k + 1]
		local d, t = segDist(px, pz, a[1], a[2], b[1], b[2])
		if d < best then
			best, bs, bt = d, k, t
			bx, bz = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
		end
	end
	return best, bx, bz, bs, bt
end

-- where two polylines cross: (x, z, segment on a, t on a, segment on b, t on b), the first along a
local function crossOf(a, b)
	for k = 1, #a - 1 do
		local p, q = Vector3.new(a[k][1], 0, a[k][2]), Vector3.new(a[k + 1][1], 0, a[k + 1][2])
		for j = 1, #b - 1 do
			local t, u = segX(p, q, Vector3.new(b[j][1], 0, b[j][2]), Vector3.new(b[j + 1][1], 0, b[j + 1][2]))
			if t and u then
				return p.X + (q.X - p.X) * t, p.Z + (q.Z - p.Z) * t, k, t, j, u
			end
		end
	end
	return nil
end

local function cross2(ax: number, az: number, bx: number, bz: number): number
	return ax * bz - az * bx
end

function M.findCorners()
	M.corners, M.cornerSpan = {}, {}
	local ringPts = M.ringOuter()
	for _, m in M.mouths do
		local S = M.R[m.road]
		local sideP = {}
		for _, side in { -1, 1 } do
			-- this road's edge, from its end outward (about 60 samples)
			local ePts = {}
			local i = m.i0
			while i >= 1 and i <= S.n and math.abs(i - m.i0) <= 60 do
				local x, z = edgeXZ(S, i, side)
				table.insert(ePts, { x, z, i = i })
				i += m.step
			end
			-- the other road's kerb line near here
			local bPts, sb = {}, 0
			if m.ring then
				local s0 = S.s[m.k]
				local a0 = math.atan2(s0[3] - C.Z, s0[1] - C.X)
				local j0 = math.floor((a0 % TAU) / TAU * M.N + 0.5)
				for j = j0 - 24, j0 + 24 do
					local p = ringPts[(j % M.N) + 1]
					table.insert(bPts, { p.X, p.Z, j = (j % M.N) + 1 })
				end
			else
				local B = m.big
				local sk = S.s[m.k]
				local bs = B.s[m.bigI]
				local rx, rz = rightOf(bs)
				sb = if (sk[1] - bs[1]) * rx + (sk[3] - bs[3]) * rz > 0 then 1 else -1
				for j = math.max(1, m.bigI - 40), math.min(B.n, m.bigI + 40) do
					if not M.cut[B.name][j] then
						local x, z = edgeXZ(B, j, sb)
						table.insert(bPts, { x, z, j = j })
					end
				end
			end
			local px, pz, ka, ta, kb, tb = crossOf(ePts, bPts)
			assert(px, "corner: " .. m.road .. " side " .. side .. " never meets " .. m.on)
			sideP[side] = { px = px, pz = pz, ePts = ePts, bPts = bPts, ka = ka, ta = ta, kb = kb, tb = tb, sb = sb }
		end
		for _, side in { -1, 1 } do
			local c = sideP[side]
			local other = sideP[-side]
			-- the two rays of the pavement wedge: along this road away from the other, along the other
			-- road's kerb away from this road's other corner
			local e1, e2 = c.ePts[c.ka], c.ePts[c.ka + 1]
			local ux, uz = e2[1] - e1[1], e2[2] - e1[2]
			local L = hyp(ux, uz)
			ux, uz = ux / L, uz / L
			local b1, b2 = c.bPts[c.kb], c.bPts[c.kb + 1]
			local vx, vz = b2[1] - b1[1], b2[2] - b1[2]
			L = hyp(vx, vz)
			vx, vz = vx / L, vz / L
			if (other.px - c.px) * vx + (other.pz - c.pz) * vz > 0 then
				vx, vz = -vx, -vz
			end
			local theta = math.acos(math.clamp(ux * vx + uz * vz, -1, 1))
			local T = if m.ring then M.CORNER_T_RING else M.CORNER_T
			local r = T * math.tan(theta / 2)
			-- the circle's centre on the wedge's bisector, then pulled until it is r from both kerb lines
			-- (they are not quite straight: the ring is round, the loop bends)
			local bx, bz = ux + vx, uz + vz
			L = hyp(bx, bz)
			bx, bz = bx / L, bz / L
			local ox, oz = c.px + bx * r / math.sin(theta / 2), c.pz + bz * r / math.sin(theta / 2)
			for _ = 1, 40 do
				local dA, fax, faz = footOn(c.ePts, ox, oz)
				local dB, fbx, fbz = footOn(c.bPts, ox, oz)
				local nax, naz = (ox - fax) / math.max(dA, 1e-6), (oz - faz) / math.max(dA, 1e-6)
				local nbx, nbz = (ox - fbx) / math.max(dB, 1e-6), (oz - fbz) / math.max(dB, 1e-6)
				ox += nax * (r - dA) * 0.7 + nbx * (r - dB) * 0.7
				oz += naz * (r - dA) * 0.7 + nbz * (r - dB) * 0.7
			end
			local dA, tax, taz, sa, sta = footOn(c.ePts, ox, oz)
			local dB, tbx, tbz, sbb, stb = footOn(c.bPts, ox, oz)
			-- the arc from TA to TB the way that passes P
			local aA = math.atan2(taz - oz, tax - ox)
			local aB = math.atan2(tbz - oz, tbx - ox)
			local aP = math.atan2(c.pz - oz, c.px - ox)
			local sweep = (aB - aA) % TAU
			if ((aP - aA) % TAU) > sweep then
				sweep -= TAU
			end
			local corner = {
				road = m.road, side = side, on = m.on, ring = m.ring, big = m.big, sb = c.sb,
				r = r, theta = theta, ox = ox, oz = oz, px = c.px, pz = c.pz,
				tax = tax, taz = taz, tbx = tbx, tbz = tbz, aA = aA, sweep = sweep,
				ePts = c.ePts, bPts = c.bPts, ka = c.ka, ta = c.ta, kb = c.kb, tb = c.tb, sa = sa, sta = sta, sbb = sbb, stb = stb,
				rin = math.max(r - M.WALK, 0) - 0.3, rout = hyp(c.px - ox, c.pz - oz) + M.WALK + 2, err = math.max(math.abs(dA - r), math.abs(dB - r)),
			}
			table.insert(M.corners, corner)
			if m.ring then
				-- (the ring's own kerb and pavement stop where the round corner starts)
				local key = m.road .. "@" .. m.i0
				M.cornerSpan[key] = M.cornerSpan[key] or {}
				table.insert(M.cornerSpan[key], math.atan2(tbz - C.Z, tbx - C.X))
			end
		end
	end
	return #M.corners
end

-- is a flat point inside a corner's wedge (between the rays O->TA and O->TB, on P's side), at a distance
-- from O between lo and hi?
local function inWedge(c, px: number, pz: number, lo: number, hi: number): boolean
	local dx, dz = px - c.ox, pz - c.oz
	local d = hyp(dx, dz)
	if d < lo or d > hi then
		return false
	end
	local a = math.atan2(dz, dx)
	local f = (a - c.aA) % TAU
	if c.sweep >= 0 then
		return f <= c.sweep
	end
	return f == 0 or f >= TAU + c.sweep
end
M.inWedge = inWedge

-- Past a corner's TA (on the far side of the ray O->TA, up to 60 studs on), in the joining road's own
-- kerb and pavement band on that side: that road owns it. (At a slanting join the bigger road's pavement
-- band overlaps it there: its pavement would bury the joining road's kerb.)
function M.ownedBy(px: number, pz: number): (string?, any)
	for _, c in M.corners do
		local tx, tz = c.tax - c.px, c.taz - c.pz
		local L = hyp(tx, tz)
		if L > 1e-6 and hyp(px - c.tax, pz - c.taz) < 60 and (px - c.tax) * tx + (pz - c.taz) * tz > 0 then
			local S = M.R[c.road]
			local b = M.near(px, pz, 3)[S.index]
			if b then
				local d, fx, fz = polyDist(S, b[2], px, pz)
				local s = S.s[b[2]]
				local rx, rz = rightOf(s)
				if fx and fz and d > S.half - 0.3 and d < S.half + M.WALK + 0.5 and ((px - fx) * rx + (pz - fz) * rz) * c.side > 0 then
					return c.road, c
				end
			end
		end
	end
	return nil
end

-- in any corner's way (for the kerbs, pavements and edge lines of the straight roads)?
function M.inCorner(px: number, pz: number): boolean
	for _, c in M.corners do
		if inWedge(c, px, pz, c.rin, c.rout) then
			return true
		end
	end
	return false
end

-- a point on a corner's arc at fraction u (0 at TA, 1 at TB), radius rho, and its road height
local function arcPoint(c, u: number, rho: number): (number, number)
	local a = c.aA + c.sweep * u
	return c.ox + rho * math.cos(a), c.oz + rho * math.sin(a)
end

-- the asphalt between the arc and P, the kerb and pavement along the arc, an edge line along it
function M.buildCorners()
	local E = M.Roads.debugEdges
	local pal = M.palette
	local made = 0
	local lines = {}
	for _, c in M.corners do
		local S = M.R[c.road]
		local folder = M.folder():FindFirstChild(c.road) :: Instance
		local ES = E[c.road][if c.side < 0 then "L" else "R"]
		local function sY(seg: number, t: number): number
			local a, b = c.ePts[seg], c.ePts[seg + 1]
			return ES[a.i].Y + (ES[b.i].Y - ES[a.i].Y) * t
		end
		local function bY(seg: number, t: number): number
			if c.ring then
				return C.Y
			end
			local EB = E[c.big.name][if c.sb < 0 then "L" else "R"]
			local a, b = c.bPts[seg], c.bPts[seg + 1]
			return EB[a.j].Y + (EB[b.j].Y - EB[a.j].Y) * t
		end
		local yA, yB = sY(c.sa, c.sta), bY(c.sbb, c.stb)
		local yP = sY(c.ka, c.ta)
		-- the asphalt: TA, this road's kerb line back to P, P, the other road's kerb line on to TB, the arc back
		local poly = { Vector3.new(c.tax, yA, c.taz) }
		for k = c.sa, c.ka + 1, -1 do -- (ePts run outward from the road's end: TA is further out than P)
			if k ~= c.sa or c.sta < 1 then
				local p = c.ePts[k]
				if k <= c.sa and k > c.ka then
					table.insert(poly, Vector3.new(p[1], ES[p.i].Y, p[2]))
				end
			end
		end
		table.insert(poly, Vector3.new(c.px, yP, c.pz))
		-- the other road's kerb line from P to TB
		if c.kb ~= c.sbb then
			local stepB = if c.sbb > c.kb then 1 else -1
			local k = if stepB > 0 then c.kb + 1 else c.kb
			while (stepB > 0 and k <= c.sbb) or (stepB < 0 and k > c.sbb) do
				local p = c.bPts[k]
				local y = if c.ring then C.Y else E[c.big.name][if c.sb < 0 then "L" else "R"][p.j].Y
				table.insert(poly, Vector3.new(p[1], y, p[2]))
				k += stepB
			end
		end
		table.insert(poly, Vector3.new(c.tbx, yB, c.tbz))
		local n = math.max(4, math.ceil(math.abs(c.sweep) * c.r / 2))
		for q = n - 1, 1, -1 do
			local u = q / n
			local x, z = arcPoint(c, u, c.r)
			table.insert(poly, Vector3.new(x, yA + (yB - yA) * u, z))
		end
		local clean = {}
		for _, p in poly do
			local last = clean[#clean]
			if not last or hyp(p.X - last.X, p.Z - last.Z) > 0.01 then
				table.insert(clean, p)
			end
		end
		if #clean > 1 and hyp(clean[1].X - clean[#clean].X, clean[1].Z - clean[#clean].Z) <= 0.01 then
			table.remove(clean)
		end
		local road = { Name = "Road", Material = Enum.Material.Asphalt, Color = pal.asphalt, CastShadow = false }
		-- (corner points on a straight run of kerb line make hair-thin triangles that lean: drop the
		-- middle ones first)
		local kept = {}
		for k = 1, #clean do
			local a, b, d = clean[(k - 2) % #clean + 1], clean[k], clean[k % #clean + 1]
			local ab = Vector3.new(d.X - a.X, 0, d.Z - a.Z)
			local off = if ab.Magnitude > 1e-6 then math.abs((b.X - a.X) * ab.Z - (b.Z - a.Z) * ab.X) / ab.Magnitude else 0
			if off > 0.02 then
				table.insert(kept, b)
			end
		end
		for _, t in earClip(kept) do
			if not M.Roads.sliver(t[1], t[2], t[3]) then
				made += M.Roads.triangle(t[1], t[2], t[3], M.SLAB, road, folder)
			end
		end
		-- the kerb (bands about 3.2 long) and the pavement along the arc: the kerb from 0.05 on the road
		-- side of the arc to 0.85 inside it, the pavement from there to WALK inside (or to the centre)
		local len = math.abs(c.sweep) * c.r
		local nb = math.max(1, math.floor(len / 3.2 + 0.5))
		local pave: { [string]: any } = { Name = "Pavement", Material = pal.paverMaterial, Color = pal.paver, CastShadow = false }
		local pIn = math.max(c.r - M.WALK, 0)
		for q = 0, nb - 1 do
			local u0, u1 = q / nb, (q + 1) / nb
			local y0, y1 = yA + (yB - yA) * u0, yA + (yB - yA) * u1
			local function pt(u: number, rho: number, y: number): Vector3
				local x, z = arcPoint(c, u, rho)
				return Vector3.new(x, y, z)
			end
			local kTop = M.CURB_UP + 0.1
			local kerb = { Name = "Kerb", Material = pal.kerbMaterial, Color = if q % 2 == 1 and pal.kerbBand then pal.kerbBand else pal.kerb, CastShadow = false }
			local o0, o1 = pt(u0, c.r + 0.05, y0 + kTop), pt(u1, c.r + 0.05, y1 + kTop)
			local i0, i1 = pt(u0, math.max(c.r - 0.85, 0), y0 + kTop), pt(u1, math.max(c.r - 0.85, 0), y1 + kTop)
			for _, t in { { o0, o1, i1 }, { o0, i1, i0 } } do
				if not M.Roads.sliver(t[1], t[2], t[3]) then
					made += M.Roads.triangle(t[1], t[2], t[3], 6.04, kerb, folder)
				end
			end
			if c.r - 0.85 > 0.05 then
				local a0, a1 = pt(u0, c.r - 0.85, y0 + M.CURB_UP), pt(u1, c.r - 0.85, y1 + M.CURB_UP)
				local b0, b1 = pt(u0, pIn, y0 + M.CURB_UP), pt(u1, pIn, y1 + M.CURB_UP)
				for _, t in { { a0, a1, b1 }, { a0, b1, b0 } } do
					if not M.Roads.sliver(t[1], t[2], t[3]) then
						made += M.Roads.triangle(t[1], t[2], t[3], 6, pave, folder)
					end
				end
			end
		end
		table.insert(lines, string.format("%s %s side %d: theta %.0f, r %.1f (fit %.2f), %d corners in the asphalt", c.road, c.on, c.side, math.deg(c.theta), c.r, c.err, #clean))
		task.wait()
	end
	return string.format("corners: %d parts\n  %s", made, table.concat(lines, "\n  "))
end

-- each round corner's solid edge line, 1.2 in from the kerb, joining the two roads' edge lines (after
-- RoadLines: it moves every "Line" in the road folders away first)
function M.cornerLines()
	local E = M.Roads.debugEdges
	local pal = M.palette
	local made = 0
	for _, c in M.corners do
		local folder = M.folder():FindFirstChild(c.road) :: Instance
		local ES = E[c.road][if c.side < 0 then "L" else "R"]
		local a1, a2 = c.ePts[c.sa], c.ePts[math.min(c.sa + 1, #c.ePts)]
		local yA = ES[a1.i].Y + (ES[a2.i].Y - ES[a1.i].Y) * c.sta
		local yB = C.Y
		if not c.ring then
			local EB = E[c.big.name][if c.sb < 0 then "L" else "R"]
			local b1, b2 = c.bPts[c.sbb], c.bPts[math.min(c.sbb + 1, #c.bPts)]
			yB = EB[b1.j].Y + (EB[b2.j].Y - EB[b1.j].Y) * c.stb
		end
		local len = math.abs(c.sweep) * c.r
		-- the solid edge line, 1.2 in from the kerb, joining the two roads' edge lines
		local nl = math.max(2, math.ceil(len / 4))
		for q = 0, nl - 1 do
			local x0, z0 = arcPoint(c, q / nl, c.r + 1.2)
			local x1, z1 = arcPoint(c, (q + 1) / nl, c.r + 1.2)
			local y0 = yA + (yB - yA) * (q / nl) + M.LIFT + M.LINE_T / 2
			local y1 = yA + (yB - yA) * ((q + 1) / nl) + M.LIFT + M.LINE_T / 2
			local p0, p1 = Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1)
			local p = Instance.new("Part")
			p.Name = "Line"
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.SmoothPlastic
			p.Color = pal.paint
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
			p.Size = Vector3.new(0.6, M.LINE_T, (p1 - p0).Magnitude + 0.12)
			p.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
			p.Parent = folder
			made += 1
		end
	end
	return "corner lines: " .. made
end

-- The grass beside the pavement up to road height (it stood 2 to 3 studs lower: the pavement's side
-- showed as a tall wall), out to VERGE past the pavement. Never on a carriageway, the roundabout or a
-- corner. Run after the roads, before the lines.
M.VERGE_W = 16
-- (the box's top under the road: smooth terrain shows about 2 studs over a FillBlock's top, less where
-- lower ground pulls the surface down; -1.7 puts the grass 0.1 to 0.5 under the pavement's top)
M.VERGE_TOP = -1.7
function M.verge(names: { string })
	local made = 0
	-- (the ring's carriageway and its kerb and pavement between the arms; an arm's gap is the arm's)
	local ringSecs = M._sectors(M.RING_V)
	local function onRing(x: number, z: number): boolean
		local d = hyp(x - C.X, z - C.Z)
		if d < M.RING_V + 0.5 then
			return true
		elseif d > M.RING_V + M.WALK + 1 then
			return false
		end
		local a = math.atan2(z - C.Z, x - C.X)
		for _, sec in ringSecs do
			local f = (a - sec[1]) % TAU
			if f <= sec[2] - sec[1] + 0.01 then
				return true
			end
		end
		return false
	end
	local function clear(x: number, z: number, self): boolean
		if onRing(x, z) then
			return false
		end
		if M.inCorner(x, z) then
			return false
		end
		for oi, b in M.near(x, z, 3) do
			local o = M.list[oi]
			if (o.kind == "route" or o.kind == "side") and not M.cut[o.name][b[2]] and polyDist(o, b[2], x, z) < M.halfAt(o, b[2]) + M.WALK + (if o == self then -0.2 else 1) then
				return false
			end
		end
		return true
	end
	for _, name in names do
		local o = M.R[name]
		for i = 1, o.n - 1 do
			if M.cut[name][i] or M.cut[name][i + 1] then
				continue
			end
			local a, b = o.s[i], o.s[i + 1]
			for _, side in { -1, 1 } do
				if side < 0 and o.walkL then
					continue -- (a flyover side lane's inner side: the deck's ramp and piers stand there)
				end
				local rx, rz = rightOf(a)
				local ok = true
				local hw = math.max(M.halfAt(o, i), M.halfAt(o, i + 1)) -- (a widened end: the verge moves out with it)
				for _, f in { 0, 0.5, 1 } do
					for _, lat in { hw + M.WALK + 0.5, hw + M.WALK + M.VERGE_W / 2, hw + M.WALK + M.VERGE_W } do
						local x = a[1] + (b[1] - a[1]) * f + rx * side * lat
						local z = a[3] + (b[3] - a[3]) * f + rz * side * lat
						if not clear(x, z, o) then
							ok = false
						end
					end
				end
				if ok then
					-- (FillBlock's top shows 2 studs higher on smooth terrain: the grass lands 0.1 under the road)
					local y = math.min(a[2], b[2]) + M.VERGE_TOP
					local len = hyp(b[1] - a[1], b[3] - a[3])
					local mid = Vector3.new((a[1] + b[1]) / 2, (y + y - 10) / 2, (a[3] + b[3]) / 2)
					-- (from 4 studs under the pavement out: smooth terrain is 4-stud voxels, and one whose centre
					-- lies in the road's cleared trench pulls the surface down right at the pavement's edge,
					-- 1 to 2 studs of pavement side showing. Under the pavement the grass is hidden.)
					local cf = CFrame.lookAt(mid, Vector3.new(b[1], mid.Y, b[3])) * CFrame.new(side * (hw + M.WALK - 4 + (M.VERGE_W + 4) / 2), 0, 0)
					workspace.Terrain:FillBlock(cf, Vector3.new(M.VERGE_W + 4, 10, len + 1), Enum.Material.Grass)
					made += 1
				end
			end
			if i % 150 == 0 then
				task.wait()
			end
		end
	end
	-- round the roundabout, between the arms, and inside the round corners at the ring
	for j = 0, M.N - 1 do
		local a = (j + 0.5) * TAU / M.N
		local rho = M.RING_V + M.WALK + M.VERGE_W / 2
		local x, z = C.X + rho * math.cos(a), C.Z + rho * math.sin(a)
		local ok = not M.inCorner(x, z)
		for oi, b in M.near(x, z, 3) do
			local o = M.list[oi]
			if (o.kind == "route" or o.kind == "side") and not M.cut[o.name][b[2]] and polyDist(o, b[2], x, z) < M.halfAt(o, b[2]) + M.WALK + M.VERGE_W / 2 + 1 then
				ok = false
			end
		end
		if ok then
			local len = TAU * rho / M.N + 1
			local cf = CFrame.new(x, C.Y + M.VERGE_TOP - 5, z) * CFrame.Angles(0, -a, 0)
			workspace.Terrain:FillBlock(cf, Vector3.new(M.VERGE_W, 10, len), Enum.Material.Grass)
			made += 1
		end
	end
	-- inside each round corner: strips along the curve, like the strips along the roads (a round fill
	-- came out up to a stud too high or too low)
	for _, c in M.corners do
		local inner = c.r - M.WALK
		if inner > 0.5 then
			local w = math.min(M.VERGE_W, inner)
			local rho = inner - w / 2
			local S = M.R[c.road]
			local yA = S.s[c.ePts[c.sa].i][2]
			local yB = if c.ring then C.Y else c.big.s[c.bPts[c.sbb].j][2]
			local n = math.max(2, math.ceil(math.abs(c.sweep) * inner / 6))
			for q = 0, n - 1 do
				local u0, u1 = q / n, (q + 1) / n
				local x0, z0 = arcPoint(c, u0, rho)
				local x1, z1 = arcPoint(c, u1, rho)
				local y = math.min(yA + (yB - yA) * u0, yA + (yB - yA) * u1) + M.VERGE_TOP
				local mid = Vector3.new((x0 + x1) / 2, y - 5, (z0 + z1) / 2)
				local len = hyp(x1 - x0, z1 - z0) + 1
				if len > 0.5 then
					-- (air first: an earlier fill may stand too high here)
					local cf = CFrame.lookAt(mid, Vector3.new(x1, mid.Y, z1))
					workspace.Terrain:FillBlock(cf * CFrame.new(0, 5 - 1.3 + 12.5, 0), Vector3.new(w, 25, len), Enum.Material.Air)
					workspace.Terrain:FillBlock(cf, Vector3.new(w, 10, len), Enum.Material.Grass)
					made += 1
				end
			end
		end
	end
	return "verge: " .. made .. " pieces"
end

------------------------------------------------------------------------------------------------
-- building
------------------------------------------------------------------------------------------------

function M.folder(): Instance
	local model = workspace:FindFirstChild("Yangon")
	if not model then
		model = Instance.new("Model")
		model.Name = "Yangon"
		model.Parent = workspace
	end
	local roads = model:FindFirstChild("Roads")
	if not roads then
		roads = Instance.new("Folder")
		roads.Name = "Roads"
		roads.Parent = model
	end
	return roads
end

local function setOf(names: { string }): { [string]: boolean }
	local set = {}
	for _, n in names do
		set[n] = true
	end
	return set
end

-- long jobs: run in the background, read with M.status()
function M.spawn(label: string, fn: () -> any)
	local YD = SS.YangonData
	YD:SetAttribute("BuildStatus", label .. ": running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		YD:SetAttribute("BuildStatus", string.format("%s: %s after %.0f s: %s", label, if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("BuildStatus"))
end

-- takes a road's folder out, a chunk at a time
function M.clear(names: { string })
	local roads = M.folder()
	local n = 0
	for _, name in names do
		local f = roads:FindFirstChild(name)
		if f then
			for i, c in f:GetChildren() do
				c:Destroy()
				n += 1
				if i % 3000 == 0 then
					task.wait()
				end
			end
			f:Destroy()
		end
	end
	return n
end

-- Where the lake or a pond comes under a road's pavement there is no ground (step 2 wrote water
-- wherever the map has water, and the game's roads are twice as wide as the real ones): the pavement
-- would hang over the water. Run this BEFORE buildRoads: on each such side it fills a grass bank from
-- the lake bed up to 1 stud under the road, out to VERGE studs past the pavement.
M.VERGE = 12
function M.bank(names: { string })
	local T = require(SS.YangonData.Tools.YangonTerrain:Clone())
	T.prepare()
	local made, where = 0, {}
	for _, name in names do
		local o = M.R[name]
		local cut = M.cut[name]
		local reach = o.half + M.WALK + M.VERGE
		for i = 1, o.n - 1 do
			if cut[i] or cut[i + 1] then
				continue
			end
			local a, b = o.s[i], o.s[i + 1]
			for _, side in { -1, 1 } do
				local wet = false
				for _, s in { a, b } do
					local rx, rz = rightOf(s)
					for lat = 0, reach + 4, 2 do
						if T.isWater(s[1] + rx * lat * side, s[3] + rz * lat * side) then
							wet = true
							break
						end
					end
					if wet then
						break
					end
				end
				if wet then
					-- (FillBlock's top shows 2 studs higher on smooth terrain: YangonTerrain's SOLID_LIFT)
					local top = math.min(a[2], b[2]) - 1 - 2
					local bottom = 8
					local len = hyp(b[1] - a[1], b[3] - a[3])
					local mx, mz = (a[1] + b[1]) / 2, (a[3] + b[3]) / 2
					local cf = CFrame.lookAt(Vector3.new(mx, (top + bottom) / 2, mz), Vector3.new(b[1], (top + bottom) / 2, b[3])) * CFrame.new(side * reach / 2, 0, 0)
					workspace.Terrain:FillBlock(cf, Vector3.new(reach, top - bottom, len + 4), Enum.Material.Grass)
					made += 1
					table.insert(where, i)
				end
			end
			if i % 200 == 0 then
				task.wait()
			end
		end
	end
	return string.format("bank: %d pieces (samples %s..%s)", made, tostring(where[1]), tostring(where[#where]))
end

function M.buildRoads(names: { string })
	local only = setOf(names)
	local parent = M.folder()
	local edgesFor = {}
	for _, m in M.mouths do
		if m.big then
			edgesFor[m.big.name] = true
		end
	end
	local count = M.Roads.build(M.data, {
		parent = parent,
		only = only,
		noLines = true,
		noLegWalls = true,
		noZebra = true,
		noTurningCircle = true,
		noShadows = true,
		pave = true,
		palette = M.palette,
		cut = M.cut,
		noSlab = M.noSlab,
		sideZone = M.sideZone,
		live = true,
		keepEdges = true,
		edgesFor = edgesFor,
	})
	local lines = { string.format("Roads.build: %d parts", count) }
	for _, m in M.mouths do
		if only[m.road] then
			local made = M.buildMouth(m, parent:FindFirstChild(m.road) :: Instance)
			table.insert(lines, string.format("mouth %s on %s: k %d, %d corners, %d wedges, area %.1f of %.1f", m.road, m.on, m.k, m.corners, made, m.area, m.outline))
			task.wait()
		end
	end
	return table.concat(lines, "; ")
end

-- The ground just past each cut end of a built road, back to 1 stud under the road. The builder's trench
-- (and any earlier build that reached further) leaves a dip of a stud or two right at the end; step 4 butts
-- up to these ends, and until then there must be no drop. Only ever adds ground, never above the road.
function M.mendCutEnds(names: { string })
	local built = setOf(names)
	local n = 0
	for _, e in M.cutEnds do
		if built[e.road] then
			local o = M.R[e.road]
			local s = o.s[e.sample]
			local L = hyp(s[4], s[5])
			local sign = if e.cutIs == "after" then 1 else -1
			local dx, dz = s[4] / L * sign, s[5] / L * sign
			-- (FillBlock's top shows 2 studs higher on smooth terrain: measured on the bank, 13 Nov)
			local top, bottom = s[2] - 1 - 2, s[2] - 12
			local len = 24
			local mid = Vector3.new(s[1] + dx * len / 2, (top + bottom) / 2, s[3] + dz * len / 2)
			workspace.Terrain:FillBlock(CFrame.lookAt(mid, mid + Vector3.new(dx, 0, dz)), Vector3.new((o.half + M.WALK + 4) * 2, top - bottom, len), Enum.Material.Grass)
			n += 1
		end
	end
	return "cut ends mended: " .. n
end

-- The whole of step 3 in one go (run it through M.spawn, it takes about half a minute):
-- the bank, the three main roads with their mouths, the ground at the cut ends, the roundabout, the lines.
function M.step3()
	local log = {}
	table.insert(log, "cleared " .. M.clear(M.MAIN))
	task.wait()
	table.insert(log, M.bank(M.MAIN))
	task.wait()
	table.insert(log, M.buildRoads(M.MAIN))
	table.insert(log, M.mendCutEnds(M.MAIN))
	task.wait()
	table.insert(log, M.buildCorners())
	task.wait()
	table.insert(log, M.verge(M.MAIN))
	task.wait()
	table.insert(log, M.buildRoundabout())
	task.wait()
	table.insert(log, "lines " .. M.buildLines(M.MAIN))
	table.insert(log, M.cornerLines())
	-- (RoadLines keeps the lines it replaced in ServerStorage.OldRoadLines: Yangon's are not wanted)
	local old = SS:FindFirstChild("OldRoadLines")
	if old then
		for _, name in M.MAIN do
			local f = old:FindFirstChild(name)
			if f then
				f:Destroy()
			end
		end
	end
	return table.concat(log, "\n")
end

------------------------------------------------------------------------------------------------
-- step 4: the flyover decks (data.decks from d7_flyovers.py)
------------------------------------------------------------------------------------------------
M.DECK_CLEAR = 9 -- surface this far over the ground or more: a girder on piers; less: walls down to the ground
M.GIRDER = 3 -- the box girder's depth under the slab
M.PIER_EVERY = 8 -- samples between piers (about 51 studs)
M.PARAPET = 2.6 -- the parapet's top over the deck's edge
M.deckLook = {
	wall = { Material = Enum.Material.Sandstone, Color = Color3.fromRGB(158, 154, 146) },
	girder = { Material = Enum.Material.Sandstone, Color = Color3.fromRGB(132, 128, 122) },
}

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function M.decksFolder(): Instance
	local model = M.folder().Parent :: Instance
	local f = model:FindFirstChild("Decks")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Decks"
		f.Parent = model
	end
	return f
end

function M.buildDecks()
	local F = M.decksFolder()
	for i, c in F:GetChildren() do
		c:Destroy()
		if i % 3000 == 0 then
			task.wait()
		end
	end
	local data = { roads = {} }
	for k, d in M.data.decks do
		table.insert(data.roads, { name = d.name, kind = "deck", rank = -k, half = 32, closed = false, s = d.s })
	end
	local count = M.Roads.build(data, {
		parent = F,
		noLines = true,
		noLegWalls = true,
		noZebra = true,
		noTurningCircle = true,
		surfaceOnly = true,
		palette = M.palette,
		live = true,
		keepEdges = true,
		clearHalf = 33,
	})
	local E = M.Roads.debugEdges
	local log = { string.format("deck surfaces: %d parts", count) }
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local function groundY(x: number, z: number, top: number): number
		local r = workspace:Raycast(Vector3.new(x, top + 40, z), Vector3.new(0, -300, 0), rp)
		return if r then r.Position.Y else top - 30
	end
	-- is a spot under the deck on a road (any road of the map, built now or later)?
	local function onRoad(x: number, z: number, margin: number): string?
		for oi, b in M.near(x, z, 3) do
			local o = M.list[oi]
			if polyDist(o, b[2], x, z) < M.halfAt(o, b[2]) + margin then
				return o.name
			end
		end
		return nil
	end
	for _, d in M.data.decks do
		local folder = F:FindFirstChild(d.name) :: Instance
		local ED = E[d.name]
		local s = d.s
		local n = #s
		local made, piers, skipped, ramp = 0, 0, {}, 0
		-- per segment: elevated or not (the ground under the middle and 2 studs past both edges)
		local elevated = {}
		for i = 1, n - 1 do
			local cL = (ED.L[i] + ED.L[i + 1]) / 2
			local cR = (ED.R[i] + ED.R[i + 1]) / 2
			local mid = (cL + cR) / 2
			local out = ((cR - cL) * Vector3.new(1, 0, 1)).Unit
			local g = math.max(groundY(mid.X, mid.Z, mid.Y), groundY(cL.X - out.X * 2, cL.Z - out.Z * 2, mid.Y), groundY(cR.X + out.X * 2, cR.Z + out.Z * 2, mid.Y))
			elevated[i] = mid.Y - g >= M.DECK_CLEAR
		end
		for i = 1, n - 1 do
			-- the walls: a parapet on each edge; on a ramp it goes down into the ground (a retaining wall),
			-- elevated it is a fascia over the slab's side
			for _, side in { "L", "R" } do
				local other = if side == "L" then "R" else "L"
				local e0, e1 = ED[side][i], ED[side][i + 1]
				local o0, o1 = ED[other][i], ED[other][i + 1]
				local inward = (((o0 + o1) / 2 - (e0 + e1) / 2) * Vector3.new(1, 0, 1)).Unit
				local p0, p1 = e0 + inward * 0.45, e1 + inward * 0.45 -- (outer face 0.05 past the slab's side)
				local len = (p1 - p0).Magnitude
				if len < 0.05 then
					continue
				end
				local below
				if elevated[i] then
					below = M.SLAB + 1.5
				else
					local g = math.min(groundY(e0.X - inward.X * 2, e0.Z - inward.Z * 2, e0.Y), groundY(e1.X - inward.X * 2, e1.Z - inward.Z * 2, e1.Y))
					below = math.max(M.SLAB + 1.5, math.max(e0.Y, e1.Y) - g + 3)
					ramp += 1
				end
				local cf = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, (M.PARAPET - below) / 2, 0)
				local props = table.clone(M.deckLook.wall)
				props.Name = if elevated[i] then "Parapet" else "RampWall"
				props.Size = Vector3.new(1, M.PARAPET + below, len)
				props.CFrame = cf
				props.CastShadow = true
				part(props, folder)
				made += 1
			end
			-- elevated: the box girder under the slab (neighbours a hair different, so overlaps never flicker)
			if elevated[i] then
				local a, b = s[i], s[i + 1]
				local ya = (ED.L[i].Y + ED.R[i].Y) / 2 - M.SLAB - M.GIRDER / 2
				local yb = (ED.L[i + 1].Y + ED.R[i + 1].Y) / 2 - M.SLAB - M.GIRDER / 2
				local pa, pb = Vector3.new(a[1], ya, a[3]), Vector3.new(b[1], yb, b[3])
				local alt = (i % 2) * 0.06
				local props = table.clone(M.deckLook.girder)
				props.Name = "Girder"
				props.Size = Vector3.new(64 - 14 - alt * 2, M.GIRDER - alt, (pb - pa).Magnitude + 0.3)
				props.CFrame = CFrame.lookAt((pa + pb) / 2, pb) * CFrame.new(0, alt / 2, 0)
				part(props, folder)
				made += 1
			end
			if i % 40 == 0 then
				task.wait()
			end
		end
		-- piers: every PIER_EVERY samples on the elevated part, moved along (up to 3 samples either way)
		-- off any road below
		local i = M.PIER_EVERY
		while i <= n - 1 do
			local placed = false
			for _, di in { 0, 1, -1, 2, -2, 3, -3 } do
				local k = i + di
				if k < 2 or k > n - 1 or not (elevated[k - 1] and elevated[k]) then
					continue
				end
				local c = s[k]
				local rx, rz = rightOf(c)
				local L = hyp(c[4], c[5])
				local fx, fz = c[4] / L, c[5] / L
				local hit = nil
				for _, lat in { -30, -15, 0, 15, 30 } do
					for _, along in { -4, 0, 4 } do
						hit = hit or onRoad(c[1] + rx * lat + fx * along, c[3] + rz * lat + fz * along, 3)
					end
				end
				if hit then
					skipped[hit] = (skipped[hit] or 0) + 1
					continue
				end
				local top = (ED.L[k].Y + ED.R[k].Y) / 2 - M.SLAB - M.GIRDER
				local g = math.min(groundY(c[1], c[3], top), groundY(c[1] + rx * 6, c[3] + rz * 6, top), groundY(c[1] - rx * 6, c[3] - rz * 6, top))
				local look = CFrame.lookAt(Vector3.zero, Vector3.new(fx, 0, fz)).Rotation
				local cap = table.clone(M.deckLook.girder)
				cap.Name = "PierCap"
				cap.Size = Vector3.new(58, 2.5, 6)
				cap.CFrame = CFrame.new(c[1], top - 1.25, c[3]) * look
				part(cap, folder)
				local colTop, colBot = top - 2.5, g - 4
				local col = table.clone(M.deckLook.wall)
				col.Name = "Pier"
				col.Size = Vector3.new(12, colTop - colBot, 5)
				col.CFrame = CFrame.new(c[1], (colTop + colBot) / 2, c[3]) * look
				part(col, folder)
				made += 2
				piers += 1
				placed = true
				break
			end
			i += if placed then M.PIER_EVERY else 1
		end
		local sk = {}
		for name, k in skipped do
			table.insert(sk, name .. " " .. k)
		end
		table.insert(log, string.format("%s: %d parts, %d piers (moved off: %s), %d ramp wall pieces", d.name, made, piers, table.concat(sk, ", "), ramp))
	end
	-- the lines on the decks
	local only = {}
	for _, d in M.data.decks do
		only[d.name] = true
	end
	table.insert(log, "deck lines " .. tostring(M.RoadLines.build(data, F, only, { paint = M.palette.paint, centre = M.centre })))
	local old = SS:FindFirstChild("OldRoadLines")
	if old then
		for _, d in M.data.decks do
			local f = old:FindFirstChild(d.name)
			if f then
				f:Destroy()
			end
		end
	end
	return table.concat(log, "\n")
end

-- the clearance under each deck (girder included) over every road that passes under it, from the data
function M.deckClearance()
	local out = {}
	for _, d in M.data.decks do
		local s = d.s
		local worst = {}
		for _, o in M.list do
			for i = 1, o.n do
				if M.cut[o.name][i] then
					continue
				end
				local p = o.s[i]
				for k = 1, #s - 1 do
					local dd, t = segDist(p[1], p[3], s[k][1], s[k][3], s[k + 1][1], s[k + 1][3])
					if dd < 32 then
						local y = s[k][2] + (s[k + 1][2] - s[k][2]) * t
						local c = y - M.SLAB - M.GIRDER - p[2]
						if c < 30 and (not worst[o.name] or c < worst[o.name]) then
							worst[o.name] = c
						end
						break
					end
				end
			end
		end
		for name, c in worst do
			table.insert(out, string.format("%s over %s: %.1f", d.name, name, c))
		end
	end
	return table.concat(out, "; ")
end

-- the whole of step 4: step 3 again with the side lanes (and the widened loop ends), then the decks
function M.step4()
	local log = { M.step3() }
	task.wait()
	table.insert(log, M.buildDecks())
	return table.concat(log, "\n")
end

function M.buildLines(names: { string })
	return M.RoadLines.build(M.data, M.folder(), setOf(names), { cut = M.cut, paint = M.palette.paint, centre = M.centre, clearMouths = true, edgeSkip = function(p: Vector3): boolean
		return M.inCorner(p.X, p.Z) -- (the round corners paint their own edge line along the curve)
	end })
end

------------------------------------------------------------------------------------------------
-- the roundabout
------------------------------------------------------------------------------------------------

-- where an arm's edge (side -1 / 0 / 1) crosses the circle of radius rho: the angle
local function armAngle(arm, side: number, rho: number): number
	local o = arm.o
	local i = arm.i0
	local px, pz = edgeXZ(o, i, side)
	for _ = 1, 200 do
		local j = i + arm.step
		local qx, qz = edgeXZ(o, j, side)
		if hyp(px - C.X, pz - C.Z) < rho and hyp(qx - C.X, qz - C.Z) >= rho then
			local lo, hi = 0, 1
			for _ = 1, 40 do
				local mid = (lo + hi) / 2
				if hyp(px + (qx - px) * mid - C.X, pz + (qz - pz) * mid - C.Z) < rho then
					lo = mid
				else
					hi = mid
				end
			end
			return math.atan2(pz + (qz - pz) * hi - C.Z, px + (qx - px) * hi - C.X)
		end
		i, px, pz = j, qx, qz
	end
	error("roundabout: an edge of " .. arm.road .. " never reaches radius " .. rho)
end

-- an arm's two edge angles at rho, low then high, both within half a turn of its centre angle
local function armSpan(arm, rho: number): (number, number)
	local c = armAngle(arm, 0, rho)
	local function near(a: number): number
		while a - c > math.pi do
			a -= TAU
		end
		while a - c < -math.pi do
			a += TAU
		end
		return a
	end
	-- (an arm with round corners: the ring's kerb and pavement stop where the corners start, the same
	-- angle at every radius, so their ends are square to the ring)
	local span = M.cornerSpan and M.cornerSpan[arm.road .. "@" .. arm.i0]
	if span and #span == 2 then
		local a, b = near(span[1]), near(span[2])
		return math.min(a, b), math.max(a, b)
	end
	local a, b = near(armAngle(arm, -1, rho)), near(armAngle(arm, 1, rho))
	return math.min(a, b), math.max(a, b)
end

-- the stretches between the arms at radius rho: { { from angle, to angle } }, anticlockwise in angle
local function sectors(rho: number): { { number } }
	local arms = table.clone(M.arms)
	table.sort(arms, function(a, b)
		return armAngle(a, 0, M.R_OUT + 5) < armAngle(b, 0, M.R_OUT + 5)
	end)
	local out = {}
	for p = 1, #arms do
		local _, a0 = armSpan(arms[p], rho)
		local b0 = armSpan(arms[p % #arms + 1], rho)
		while b0 <= a0 do
			b0 += TAU
		end
		while b0 - a0 > TAU do
			b0 -= TAU
		end
		out[p] = { a0, b0 }
	end
	return out
end

M._sectors = sectors

local function ringPoint(rho: number, a: number, y: number): Vector3
	return Vector3.new(C.X + rho * math.cos(a), y, C.Z + rho * math.sin(a))
end

function M.buildRoundabout()
	local roads = M.folder()
	local old = roads:FindFirstChild("Hanthawaddy Roundabout")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Hanthawaddy Roundabout"
	local pal = M.palette
	local function T(a: Vector3, b: Vector3, c: Vector3, th: number, props, parent: Instance): number
		return if M.Roads.sliver(a, b, c) then 0 else M.Roads.triangle(a, b, c, th, props, parent)
	end
	local Y0 = C.Y
	local step = TAU / M.N
	local count = 0
	local function part(props: { [string]: any }): BasePart
		local p = Instance.new("Part")
		p.Anchored = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(p :: any)[k] = v
		end
		p.Parent = folder
		count += 1
		return p
	end
	-- a kerb piece from p0 to p1 (its middle line, at the road's height), in pal.kerbSplit bands
	local function kerb(p0: Vector3, p1: Vector3, alt: number)
		local nb = if pal.kerbBand then ((pal :: any).kerbSplit or 1) else 1
		local up = Vector3.new(0, M.CURB_UP + 0.08 - 3, 0)
		for kb = 0, nb - 1 do
			local q0, q1 = p0:Lerp(p1, kb / nb), p0:Lerp(p1, (kb + 1) / nb)
			if (q1 - q0).Magnitude > 0.05 then
				local second = if nb > 1 then kb % 2 == 1 else alt == 1
				part({ Name = "Kerb", Size = Vector3.new(M.KERB_W, 6.04, (q1 - q0).Magnitude), CFrame = CFrame.lookAt((q0 + q1) / 2 + up, q1 + up), Material = pal.kerbMaterial, Color = if second and pal.kerbBand then pal.kerbBand else pal.kerb })
			end
		end
	end
	local function line(p0: Vector3, p1: Vector3, w: number)
		local up = Vector3.new(0, M.LIFT + M.LINE_T / 2, 0)
		local p = part({ Name = "Line", Size = Vector3.new(w, M.LINE_T, (p1 - p0).Magnitude), CFrame = CFrame.lookAt((p0 + p1) / 2 + up, p1 + up), Material = Enum.Material.SmoothPlastic, Color = pal.paint })
		p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	end
	-- no ground may stand in the ring: clear from 4 studs under the road up, out to the pavement's edge
	workspace.Terrain:FillCylinder(CFrame.new(C.X, Y0 - 4 + 11, C.Z), 22, M.RING_V + M.WALK + 0.3, Enum.Material.Air)

	-- the ring: flat, N quads from the island to the outer edge
	local road = { Name = "Road", Material = Enum.Material.Asphalt, Color = pal.asphalt, CastShadow = false }
	for j = 0, M.N - 1 do
		local a0, a1 = j * step, (j + 1) * step
		local i0, i1 = ringPoint(M.R_IN - 0.6, a0, Y0), ringPoint(M.R_IN - 0.6, a1, Y0) -- (runs on under the island's kerb)
		local o0, o1 = ringPoint(M.RING_V, a0, Y0), ringPoint(M.RING_V, a1, Y0)
		count += T(i0, o0, o1, M.SLAB, road, folder)
		count += T(i0, o1, i1, M.SLAB, road, folder)
	end

	-- the island: a kerb ring, a grass disc and a low dome on it (nothing tall: cars across the ring stay in view)
	local grass = workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
	local NK = M.N -- (one kerb piece per side of the ring: it covers the slab's inner edge all the way)
	for j = 0, NK - 1 do
		kerb(ringPoint(M.R_IN - 0.4, j * TAU / NK, Y0), ringPoint(M.R_IN - 0.4, (j + 1) * TAU / NK, Y0), j % 2)
	end
	part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, (M.R_IN - 0.1) * 2, (M.R_IN - 0.1) * 2), CFrame = CFrame.new(C.X, Y0 + 0.45 - 1.5, C.Z) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Grass, Color = grass })
	-- (as wide as the disc: a smaller dome left a dark ring where it met the disc)
	local dome = part({ Name = "IslandMound", Size = Vector3.new((M.R_IN - 0.5) * 2, 5, (M.R_IN - 0.5) * 2), CFrame = CFrame.new(C.X, Y0 + 0.45, C.Z), Material = Enum.Material.Grass, Color = grass })
	dome.CanCollide, dome.CanQuery, dome.CanTouch = false, false, false -- (its box is wider than the dome: no ray may stop on it)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = dome

	-- outside: kerb and pavement between the arms. Each stretch ends on the arms' own edge lines, so the
	-- gap at an arm is exactly as wide as that road.
	-- (the pavement starts at the kerb's back face, as on the roads)
	local RHO_I, RHO_O, RHO_K = M.RING_V + 0.85, M.RING_V + M.WALK, M.RING_V + 0.4
	local secI, secO, secK = sectors(RHO_I), sectors(RHO_O), sectors(RHO_K)
	local pave: { [string]: any } = { Name = "Pavement", Material = pal.paverMaterial, Color = pal.paver, CastShadow = false }
	if (pal :: any).paverVariant then
		pave.MaterialVariant = (pal :: any).paverVariant
	end
	local piece = 0
	for p = 1, #secI do
		local i0, i1 = secI[p][1], secI[p][2]
		local o0, o1 = secO[p][1], secO[p][2]
		local k0, k1 = secK[p][1], secK[p][2]
		-- (the three radii's ends are the same arm edge seen at three radii: bring them onto one turn)
		local function same(a: number, ref: number): number
			while a - ref > math.pi do
				a -= TAU
			end
			while a - ref < -math.pi do
				a += TAU
			end
			return a
		end
		o0, k0, o1, k1 = same(o0, i0), same(k0, i0), same(o1, i1), same(k1, i1)
		local cuts = { { i0, o0, k0 } }
		local j = math.ceil((math.max(i0, o0, k0) + 0.004) / step)
		while j * step < math.min(i1, o1, k1) - 0.004 do
			table.insert(cuts, { j * step, j * step, j * step })
			j += 1
		end
		table.insert(cuts, { i1, o1, k1 })
		for q = 1, #cuts - 1 do
			piece += 1
			local alt = piece % 2
			local y = Y0 + M.CURB_UP -- (the pieces share their ends exactly: one height, nothing overlaps)
			local a, b = cuts[q], cuts[q + 1]
			local pi0, po0 = ringPoint(RHO_I, a[1], y), ringPoint(RHO_O, a[2], y)
			local pi1, po1 = ringPoint(RHO_I, b[1], y), ringPoint(RHO_O, b[2], y)
			count += T(pi0, po0, po1, 6, pave, folder)
			count += T(pi0, po1, pi1, 6, pave, folder)
			kerb(ringPoint(RHO_K, a[3], Y0), ringPoint(RHO_K, b[3], Y0), alt)
		end
	end

	-- lines: solid edges (the outer one broken at every arm), two dashed lane circles, a give-way line
	-- across the entry lanes of each main-road arm
	local yl = Y0
	for j = 0, M.N - 1 do
		line(ringPoint(M.R_IN + 1.2, j * step, yl), ringPoint(M.R_IN + 1.2, (j + 1) * step, yl), 0.6)
	end
	for _, s in sectors(M.R_OUT - 1.2) do
		local a = s[1] + 0.5 / M.R_OUT
		local stop = s[2] - 0.5 / M.R_OUT
		while a < stop - 1e-4 do
			local b = math.min((math.floor(a / step + 1e-6) + 1) * step, stop)
			line(ringPoint(M.R_OUT - 1.2, a, yl), ringPoint(M.R_OUT - 1.2, b, yl), 0.6)
			a = b
		end
	end
	for _, rho in { M.R_IN + 16, M.R_IN + 32 } do
		local n = math.floor(TAU * rho / 12.8 + 0.5)
		for j = 0, n - 1 do
			local a = j * TAU / n
			line(ringPoint(rho, a, yl), ringPoint(rho, a + 5.76 / rho, yl), 0.4)
		end
	end
	local giveWay = 0
	for _, arm in M.arms do
		if arm.o.kind == "route" then
			-- (traffic keeps right: the lanes coming in are on the left of a road that starts here, on the
			-- right of a road that ends here)
			local rho = M.R_OUT - 1.4
			local c = armAngle(arm, 0, rho)
			local e = armAngle(arm, if arm.step == 1 then -1 else 1, rho)
			while e - c > math.pi do
				e -= TAU
			end
			while e - c < -math.pi do
				e += TAU
			end
			local dir = if e > c then 1 else -1
			local len = math.abs(e - c) * rho - 2.4 -- (1.2 clear of the middle line and of the edge)
			local nd = math.floor((len + 2) / 4.4)
			local pad = (len - (nd * 4.4 - 2)) / 2 + 1.2
			for d = 0, nd - 1 do
				local a0 = c + dir * (pad + d * 4.4) / rho
				local a1 = a0 + dir * 2.4 / rho
				line(ringPoint(rho, a0, yl), ringPoint(rho, a1, yl), 1.2)
				giveWay += 1
			end
		end
	end
	folder.Parent = roads
	return string.format("roundabout: %d parts, %d give-way dashes, %d sectors", count, giveWay, #secI)
end

------------------------------------------------------------------------------------------------
-- checks
------------------------------------------------------------------------------------------------

function M.checkBumps()
	local lanes = {}
	for _, o in M.list do
		lanes[o.name] = if o.half >= 32 then { -24, -8, 8, 24 } else { -8, 8 }
	end
	local bumps, checked = M.Roads.check(M.data, { parent = M.folder(), only = setOf(M.MAIN), cut = M.cut, lanes = lanes })
	local lines = { string.format("Roads.check: %d bumps in %d points", #bumps, checked) }
	for i = 1, math.min(#bumps, 25) do
		local b = bumps[i]
		table.insert(lines, string.format("  %s lane %d at %.0f, %.1f, %.0f step %.2f", b.road, b.lane, b.at.X, b.at.Y, b.at.Z, b.step))
	end
	return table.concat(lines, "\n"), bumps
end

-- n random points on the built main roads: the first thing under each must be the road (no grass
-- through it), and just past the pavement the ground must stand against the pavement's side (no road
-- hanging in the air)
function M.checkPoints(n: number, seed: number?)
	local rng = Random.new(seed or 20261113)
	local roads = M.folder()
	local onRoad = RaycastParams.new()
	onRoad.FilterType = Enum.RaycastFilterType.Include
	onRoad.FilterDescendantsInstances = { roads, workspace.Terrain }
	local ground = RaycastParams.new()
	ground.FilterType = Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances = { workspace.Terrain }
	ground.IgnoreWater = false
	local pool = {}
	for _, name in M.MAIN do
		local o = M.R[name]
		for i = 1, o.n - 1 do
			if not M.cut[name][i] and not M.cut[name][i + 1] and not M.noSlab[name][i] then
				table.insert(pool, { o, i })
			end
		end
	end
	local grass, miss, off, float, water = 0, 0, 0, 0, 0
	local worstOff, worstGap, sumGap, gaps = 0, -math.huge, 0, 0
	local bad = {}
	for _ = 1, n do
		local pick = pool[rng:NextInteger(1, #pool)]
		local o, i = pick[1], pick[2]
		local a, b = o.s[i], o.s[i + 1]
		local t = rng:NextNumber()
		local rx, rz = rightOf(a)
		local lat = rng:NextNumber(-(o.half - 1), o.half - 1)
		local x, z = a[1] + (b[1] - a[1]) * t + rx * lat, a[3] + (b[3] - a[3]) * t + rz * lat
		local want = a[2] + (b[2] - a[2]) * t
		local hit = workspace:Raycast(Vector3.new(x, want + 40, z), Vector3.new(0, -80, 0), onRoad)
		if not hit then
			miss += 1
			table.insert(bad, string.format("nothing under %.0f, %.0f (%s)", x, z, o.name))
		elseif hit.Instance == workspace.Terrain then
			grass += 1
			table.insert(bad, string.format("ground on top at %.0f, %.0f (%s) %.2f over the road", x, z, o.name, hit.Position.Y - want))
		else
			local d = math.abs(hit.Position.Y - want)
			worstOff = math.max(worstOff, d)
			if hit.Instance.Name ~= "Road" or d > 0.6 then
				off += 1
				table.insert(bad, string.format("%s %.2f off at %.0f, %.0f (%s)", hit.Instance.Name, hit.Position.Y - want, x, z, o.name))
			end
		end
		-- the ground 1.5 studs past the pavement, on a random side
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local gx = a[1] + (b[1] - a[1]) * t + rx * side * (o.half + M.WALK + 1.5)
		local gz = a[3] + (b[3] - a[3]) * t + rz * side * (o.half + M.WALK + 1.5)
		local g = workspace:Raycast(Vector3.new(gx, want + 40, gz), Vector3.new(0, -120, 0), ground)
		if g then
			local gap = (want + M.CURB_UP) - g.Position.Y -- the pavement's top over the ground beside it
			if g.Material == Enum.Material.Water then
				water += 1
			end
			sumGap += gap
			gaps += 1
			worstGap = math.max(worstGap, gap)
			if gap > 5.5 then -- (the pavement is 6 deep: more than this and you see under it)
				float += 1
				table.insert(bad, string.format("pavement %.1f over the ground at %.0f, %.0f (%s)", gap, gx, gz, o.name))
			end
		else
			float += 1
			table.insert(bad, string.format("no ground beside the road at %.0f, %.0f (%s)", gx, gz, o.name))
		end
	end
	local head = string.format("%d points: ground through the road %d, nothing under %d, wrong part or height %d (worst %.3f off the sample height), floating %d, pavement top over the ground beside it: mean %.2f, most %.2f; water beside %d", n, grass, miss, off, worstOff, float, sumGap / math.max(gaps, 1), worstGap, water)
	for i = 1, math.min(#bad, 20) do
		head ..= "\n  " .. bad[i]
	end
	return head
end

-- every Pavement / Kerb under a spot (looks through the road slabs)
local function sidesUnder(x: number, y: number, z: number, folder: Instance): string?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local from = Vector3.new(x, y + 12, z)
	for _ = 1, 6 do
		local hit = workspace:Raycast(from, Vector3.new(0, -24, 0), params)
		if not hit then
			return nil
		end
		if hit.Instance.Name == "Pavement" or hit.Instance.Name == "Kerb" then
			return hit.Instance.Name
		end
		from = hit.Position - Vector3.new(0, 0.01, 0)
	end
	return nil
end

local function roadTop(x: number, y: number, z: number, folder: Instance): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local from = Vector3.new(x, y + 12, z)
	for _ = 1, 6 do
		local hit = workspace:Raycast(from, Vector3.new(0, -24, 0), params)
		if not hit then
			return nil
		end
		if hit.Instance.Name == "Road" then
			return hit.Position.Y
		end
		from = hit.Position - Vector3.new(0, 0.01, 0)
	end
	return nil
end

-- the 28 main-road junctions of the design: at each one outside the corridors, every mouth must be
-- open (no pavement, kerb or line of the main road inside the joining road's carriageway), the main
-- road's kerb and pavement must be there again right beside it, and the heights must match:
--   a joining road that is built: its own surface just outside the main road's edge against the main
--     road's surface just inside it;
--   a street that is not built yet: the height Roads.build will give it there (its samples after
--     alignJunctions) against the main road's surface. The street's raw data height is listed too.
function M.checkJunctions()
	local roads = M.folder()
	local lines = {}
	local total = { junctions = 0, corridor = 0, mouths = 0, crossing = 0, missing = 0, height = 0, lines = 0 }
	local worstH, worstRaw = 0, 0
	local aligned = {}
	for _, r in M.Roads.prepared(M.data, M.cut) do
		aligned[r.name] = r.pts
	end
	-- the main roads' Line parts, in a 48-stud grid
	local lineGrid = {}
	for _, name in M.MAIN do
		local f = roads:FindFirstChild(name)
		if f then
			for _, p in f:GetChildren() do
				if p.Name == "Line" then
					local key = math.floor(p.Position.X / 48) .. "," .. math.floor(p.Position.Z / 48)
					lineGrid[key] = lineGrid[key] or {}
					table.insert(lineGrid[key], p)
				end
			end
		end
	end
	for _, j in M.design.junctions do
		if not j.on_main then
			continue
		end
		total.junctions += 1
		local wx, wz = 30000 + j.pos_m[1] * M.SPM, -j.pos_m[2] * M.SPM
		local label = table.concat(j.roads, " + ")
		-- in a corridor: its main road's nearest sample is cut
		local corridor = false
		for _, name in j.roads do
			local o = M.R[name]
			if o.kind == "route" then
				local bi, bd = 1, math.huge
				for i = 1, o.n do
					local d = hyp(o.s[i][1] - wx, o.s[i][3] - wz)
					if d < bd then
						bi, bd = i, d
					end
				end
				if bd < 40 and M.cut[name][bi] then
					corridor = true
				end
			end
		end
		if corridor then
			total.corridor += 1
			table.insert(lines, "corridor (step 4): " .. label)
			continue
		end
		local notes, info = {}, {}
		for _, mainName in j.roads do
			local main = M.R[mainName]
			if main.kind ~= "route" then
				continue
			end
			local mf = roads:FindFirstChild(mainName)
			for _, sName in j.roads do
				local S = M.R[sName]
				if S.rank <= main.rank then
					continue
				end
				local sf = roads:FindFirstChild(sName)
				-- where S crosses main's edge line: one mouth each time
				for i = 1, S.n - 1 do
					local a, b = S.s[i], S.s[i + 1]
					if hyp(a[1] - wx, a[3] - wz) > 140 or M.cut[sName][i] or M.cut[sName][i + 1] then
						continue
					end
					local na, nb = M.near(a[1], a[3], 3)[main.index], M.near(b[1], b[3], 3)[main.index]
					if not na or not nb then
						continue
					end
					local da, db = polyDist(main, na[2], a[1], a[3]), polyDist(main, nb[2], b[1], b[3])
					if (da < main.half) == (db < main.half) then
						continue
					end
					-- Q: on main's edge; v: along S, away from main
					local t = (main.half - da) / (db - da)
					local qx, qz = a[1] + (b[1] - a[1]) * t, a[3] + (b[3] - a[3]) * t
					local qy = a[2] + (b[2] - a[2]) * t
					local vx, vz = b[1] - a[1], b[3] - a[3]
					if db < da then
						vx, vz = -vx, -vz
					end
					local L = hyp(vx, vz)
					vx, vz = vx / L, vz / L
					total.mouths += 1
					local h = S.half
					-- (a) the main road's kerb and pavement band on this side, 0.8 studs apart, as far along
					-- the main road as the mouth can reach (a slanted mouth is longer: h / sin of the angle).
					-- Inside S's carriageway: nothing of main's kerb or pavement. 1.2 to 1.8 past S's edge:
					-- they must be there again.
					local crossing, missing = 0, 0
					local iq = if da < db then nb[2] else na[2]
					local ms = main.s[iq]
					local mrx, mrz = rightOf(ms)
					local side = if (qx - ms[1]) * mrx + (qz - ms[3]) * mrz > 0 then 1 else -1
					local sinA = math.abs(vx * ms[5] - vz * ms[4]) / hyp(ms[4], ms[5])
					local reach = math.min(h / math.max(sinA, 0.2) + 14, 180)
					local span = math.ceil(reach / 6.4)
					for idx = math.max(1, iq - span), math.min(main.n - 1, iq + span) do
						if M.cut[mainName][idx] or M.cut[mainName][idx + 1] then
							continue
						end
						local p0, p1 = main.s[idx], main.s[idx + 1]
						local r0x, r0z = rightOf(p0)
						local r1x, r1z = rightOf(p1)
						for sub = 0, 7 do
							local u = (sub + 0.5) / 8 -- (never on a sample's own cross-section: pieces meet there, and a ray on a seam proves nothing)
							local axx, azz = p0[1] + (p1[1] - p0[1]) * u, p0[3] + (p1[3] - p0[3]) * u
							local rx, rz = r0x + (r1x - r0x) * u, r0z + (r1z - r0z) * u
							local lat = main.half + 0.3
							while lat < main.half + M.WALK - 0.3 do
								local x, z = axx + rx * side * lat, azz + rz * side * lat
								local near = M.near(x, z, 2)
								local ns = near[S.index]
								if ns then
									local ds = polyDist(S, ns[2], x, z)
									if ds < h - 0.4 then
										if mf and sidesUnder(x, qy, z, mf) then
											crossing += 1
										end
									elseif ds > h + 1.2 and ds < h + 1.8 then
										-- (any road's kerb or pavement: past a round corner the joining road's own)
										if not sidesUnder(x, qy, z, roads) then
											-- (another road's mouth, or the roundabout, right beside this one is no fault)
											local other = hyp(x - C.X, z - C.Z) < M.RING_V + M.WALK + 0.5 or M.inCorner(x, z)
											for oi, bb in near do
												local o2 = M.list[oi]
												if o2 ~= main and o2 ~= S and polyDist(o2, bb[2], x, z) < o2.half + (if o2.rank < main.rank then M.WALK else 0.3) then
													other = true
												end
											end
											if not other then
												missing += 1
											end
										end
									end
								end
								lat += 0.8
							end
						end
					end
					task.wait()
					-- (c) heights
					local top = mf and roadTop(qx - vx * 0.5, qy, qz - vz * 0.5, mf)
					local dh, how = math.huge, ""
					local sTop = sf and roadTop(qx + vx * 0.5, qy, qz + vz * 0.5, sf)
					if top and sTop then
						dh, how = math.abs(top - sTop), "built"
					elseif top then
						local pa, pb = aligned[sName][i].pos, aligned[sName][i + 1].pos
						dh, how = math.abs(top - (pa.Y + (pb.Y - pa.Y) * t)), "builder"
					end
					local raw = if top then math.abs(top - qy) else math.huge
					if dh ~= math.huge then
						worstH = math.max(worstH, dh)
					end
					if raw ~= math.huge then
						worstRaw = math.max(worstRaw, raw)
					end
					-- (d) no line of main inside S's carriageway
					local inMouth = 0
					local cx, cz = math.floor(qx / 48), math.floor(qz / 48)
					for dx = -2, 2 do
						for dz = -2, 2 do
							for _, p in lineGrid[(cx + dx) .. "," .. (cz + dz)] or {} do
								if p.Parent == mf then
									for u = -2, 2 do
										local q = p.Position + p.CFrame.LookVector * (p.Size.Z / 2 * u / 2)
										local near = M.near(q.X, q.Z, 2)
										local ns, nmq = near[S.index], near[main.index]
										if ns and nmq then
											-- (RoadLines' rule: the middle line is never broken by a smaller road, and
											-- a line off the middle is only in the way of the part of S on its own
											-- side of main's centre line, 4 studs or more out: at a T the far side's
											-- lines run on)
											local dq, fx, fz = polyDist(main, nmq[2], q.X, q.Z)
											local dS = math.huge
											if dq > 1 and fx and fz then
												local nx, nz = (q.X - fx) / dq, (q.Z - fz) / dq
												dS = polyDist(S, ns[2], q.X, q.Z, fx + nx * 4, fz + nz * 4, nx, nz)
											end
											if dS < h - 0.3 then
												inMouth += 1
												break
											end
										end
									end
								end
							end
						end
					end
					total.crossing += crossing
					total.missing += missing
					total.lines += inMouth
					if dh > 0.05 then
						total.height += 1
					end
					table.insert(info, string.format("%s %.3f (%s, raw %.2f)", sName, dh, how, raw))
					if crossing > 0 or missing > 0 or inMouth > 0 or dh > 0.05 then
						table.insert(notes, string.format("%s into %s at %.0f, %.0f: in the mouth %d, missing beside it %d, lines %d, height off %.3f (%s)", sName, mainName, qx, qz, crossing, missing, inMouth, dh, how))
					end
				end
			end
		end
		if #info == 0 then
			table.insert(notes, "no mouth found")
			total.missing += 1
		end
		table.insert(lines, (if #notes == 0 then "ok: " else "FAULT: ") .. label .. " | heights: " .. table.concat(info, "; ") .. (if #notes > 0 then "\n    " .. table.concat(notes, "\n    ") else ""))
	end
	local head = string.format("junctions on main roads %d: %d in a corridor, %d checked with %d mouths. Kerb or pavement in a mouth: %d spots. Missing right beside a mouth: %d spots. Lines in a mouth: %d. Heights more than 0.05 off: %d (worst %.3f; the streets' raw data is up to %.2f off before the builder eases them).", total.junctions, total.corridor, total.junctions - total.corridor, total.mouths, total.crossing, total.missing, total.lines, total.height, worstH, worstRaw)
	return head .. "\n" .. table.concat(lines, "\n")
end

-- every road slab under a spot, top first: { { road folder's name, height, the part } }. Looks through
-- kerbs and pavements, and sees two slabs lying in one plane (each hit is taken out and the ray cast again).
local function roadTops(x: number, y: number, z: number, roads: Instance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = {}
	local tops = {}
	for _ = 1, 10 do
		params.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(Vector3.new(x, y + 30, z), Vector3.new(0, -60, 0), params)
		if not hit or not hit.Instance:IsDescendantOf(roads) then
			break
		end
		if hit.Instance.Name == "Road" then
			table.insert(tops, { hit.Instance.Parent.Name, hit.Position.Y, hit.Instance })
		end
		table.insert(skip, hit.Instance)
	end
	return tops
end

-- main road on main road: over each mouth, every spot on either road has one slab (never two roads'
-- slabs on one spot, never none), and the two roads' heights match
function M.checkMainMain()
	local roads = M.folder()
	local out = {}
	for _, m in M.mouths do
		local o = M.R[m.road]
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for i = math.min(m.i0, m.k), math.max(m.i0, m.k) do
			for _, side in { -1, 1 } do
				local ex, ez = edgeXZ(o, i, side)
				x0, x1 = math.min(x0, ex), math.max(x1, ex)
				z0, z1 = math.min(z0, ez), math.max(z1, ez)
			end
		end
		x0, x1, z0, z1 = x0 - 30, x1 + 30, z0 - 30, z1 + 30
		local spots, double, holes, worst = 0, 0, 0, 0
		local firstBad = nil
		local x = x0 + 0.37 -- (off the 6.4-stud sample grid: a ray on a seam between two wedges proves nothing)
		while x <= x1 do
			local z = z0 + 0.37
			while z <= z1 do
				-- on either road's carriageway (or the ring)?
				local on = false
				local near = M.near(x, z, 3)
				local nMe = near[o.index]
				if nMe and polyDist(o, nMe[2], x, z) < o.half - 0.4 then
					on = true
				end
				if m.big then
					local nb = near[m.big.index]
					if nb and polyDist(m.big, nb[2], x, z) < m.big.half - 0.4 then
						on = true
					end
				else
					local rr = hyp(x - C.X, z - C.Z)
					if rr < M.R_OUT - 0.4 and rr > M.R_IN + 0.4 then
						on = true
					elseif rr <= M.R_IN + 0.4 then
						on = false
					end
				end
				if on then
					spots += 1
					local tops = roadTops(x, o.s[m.k][2], z, roads)
					if #tops == 0 then
						holes += 1
						firstBad = firstBad or string.format("hole at %.0f, %.0f", x, z)
					else
						for q = 2, #tops do
							if tops[q][1] ~= tops[1][1] and math.abs(tops[q][2] - tops[1][2]) < 0.3 then
								double += 1
								worst = math.max(worst, math.abs(tops[q][2] - tops[1][2]))
								firstBad = firstBad or string.format("two slabs at %.0f, %.0f (%s and %s, %.3f apart)", x, z, tops[1][1], tops[q][1], math.abs(tops[q][2] - tops[1][2]))
								break
							end
						end
					end
				end
				z += 2
			end
			x += 2
		end
		-- heights where the two meet: the road's end sample against the bigger road's surface
		local s0 = o.s[m.i0]
		local hNote = ""
		if m.big then
			local f = roads:FindFirstChild(m.big.name)
			local top = f and roadTop(s0[1], s0[2], s0[3], f)
			hNote = string.format(", heights at the join: %s %.2f in the data, %s surface %s", m.road, s0[2], m.big.name, if top then string.format("%.2f", top) else "none")
		end
		table.insert(out, string.format("%s on %s: %d spots (2-stud grid), two roads' slabs on one spot %d, holes %d%s%s", m.road, m.on, spots, double, holes, hNote, if firstBad then " | first: " .. firstBad else ""))
	end
	return table.concat(out, "\n")
end

function M.partCount()
	local roads = M.folder()
	local byName, perRoad, total = {}, {}, 0
	for _, f in roads:GetChildren() do
		local n = 0
		for _, p in f:GetDescendants() do
			if p:IsA("BasePart") then
				byName[p.Name] = (byName[p.Name] or 0) + 1
				n += 1
			end
		end
		perRoad[f.Name] = n
		total += n
	end
	local a, b = {}, {}
	for k, v in byName do
		table.insert(a, k .. " " .. v)
	end
	for k, v in perRoad do
		table.insert(b, k .. " " .. v)
	end
	table.sort(a)
	table.sort(b)
	local riv = workspace:FindFirstChild("Riviera")
	return string.format("Yangon.Roads: %d parts. By name: %s. By road: %s. Riviera descendants: %d", total, table.concat(a, ", "), table.concat(b, ", "), if riv then #riv:GetDescendants() else -1)
end

-- Doubled faces within `reach` studs of each spot.
--   blocks (pavement, kerb, line): SurfaceCheck's "fight" (two faces looking the same way, under 0.05
--     apart, lying over each other). Its "step" (under 0.3 apart) is listed apart: a kerb standing 0.1
--     over its own pavement is one by design, so kerb-on-pavement pairs are not counted.
--   road slabs (wedges, which SurfaceCheck does not read): a 2-stud grid of rays; two slab tops under
--     0.05 apart on one spot is a doubled face.
function M.surfaceCheck(spots: { { any } }, reach: number?)
	local SC = require(SS.ClaudeTools.SurfaceCheck:Clone())
	local roads = M.folder()
	local R = reach or 120
	local out = {}
	local fights, steps, slabs = 0, 0, 0
	for _, s in spots do
		local at = s[2] :: Vector3
		local found = SC.run(roads, {
			rows = 0,
			skip = function(p: BasePart)
				return hyp(p.Position.X - at.X, p.Position.Z - at.Z) > R
			end,
		})
		local f, st, eg = 0, 0, nil
		for _, e in found do
			if e.kind == "fight" then
				f += 1
				eg = eg or string.format("%s on %s at %.0f, %.0f gap %.3f", e.a.Name, e.b.Name, e.at.X, e.at.Z, e.gap)
			elseif not ((e.a.Name == "Kerb" and e.b.Name == "Pavement") or (e.a.Name == "Pavement" and e.b.Name == "Kerb")) then
				st += 1
				eg = eg or string.format("step: %s on %s at %.0f, %.0f gap %.3f", e.a.Name, e.b.Name, e.at.X, e.at.Z, e.gap)
			end
		end
		local dbl, rays, seams = 0, 0, 0
		local egSlab = nil
		local x = at.X - R + 0.37
		while x <= at.X + R do
			local z = at.Z - R + 0.37
			while z <= at.Z + R do
				if hyp(x - at.X, z - at.Z) <= R then
					local tops = roadTops(x, at.Y, z, roads)
					if #tops > 0 then
						rays += 1
					end
					for q = 2, #tops do
						if math.abs(tops[q][2] - tops[1][2]) < 0.05 then
							-- (a ray on the seam between two triangles sees both: a real doubled face is still
							-- double a hand's width to each side)
							local wide = true
							for _, d in { { 0.13, 0.07 }, { -0.07, 0.13 }, { -0.11, -0.09 } } do
								local t2 = roadTops(x + d[1], at.Y, z + d[2], roads)
								if not (t2[2] and math.abs(t2[2][2] - t2[1][2]) < 0.05) then
									wide = false
								end
							end
							if not wide then
								seams += 1
								break
							end
							dbl += 1
							egSlab = egSlab or string.format("two slabs at %.2f, %.2f (%s %.3f size %s, %s %.3f size %s)", x, z, tops[1][1], tops[1][2], tostring(tops[1][3].Size), tops[q][1], tops[q][2], tostring(tops[q][3].Size))
							break
						end
					end
				end
				z += 2
			end
			x += 2
		end
		fights += f
		steps += st
		slabs += dbl
		table.insert(out, string.format("%s: blocks fighting %d, other thin steps %d, doubled slab spots %d of %d (rays on a seam: %d)%s", s[1], f, st, dbl, rays, seams, (if eg then " | " .. eg else "") .. (if egSlab then " | " .. egSlab else "")))
		task.wait()
	end
	return string.format("doubled faces at %d spots: blocks fighting %d, thin steps %d, doubled slab spots %d\n%s", #spots, fights, steps, slabs, table.concat(out, "\n"))
end

return M
