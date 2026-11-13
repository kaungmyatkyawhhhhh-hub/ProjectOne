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
	paver = Color3.fromRGB(150, 146, 136),
	-- (poured concrete. Tried on the roundabout, 13 Nov: Roblox's Pavement draws small pavers, and it and the
	-- place's Concrete show each triangle's own texture direction on bends; Sandstone reads as plain, slightly
	-- stained concrete and shows no seams)
	paverMaterial = Enum.Material.Sandstone,
	kerb = Color3.fromRGB(232, 228, 218),
	kerbBand = Color3.fromRGB(195, 47, 45) :: Color3?,
	kerbSplit = 2,
	kerbMaterial = Enum.Material.Concrete,
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

------------------------------------------------------------------------------------------------
-- data
------------------------------------------------------------------------------------------------

function M.load()
	M.Roads = require(SS.ClaudeTools.Roads:Clone())
	M.RoadLines = require(SS.ClaudeTools.RoadLines:Clone())
	local YD = SS.YangonData
	local parts, k = {}, 1
	while YD:FindFirstChild("Roads_" .. k) do
		parts[k] = require(YD["Roads_" .. k]:Clone())
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
		local o = { index = ri, name = r.name, kind = r.kind, rank = r.rank, half = r.half, s = r.s, n = #r.s, chain = chain }
		M.R[r.name] = o
		M.list[ri] = o
	end

	-- cuts. M.cut[road][sample] = why (a flyover's name, or the roundabout's)
	M.cut = {}
	for _, o in M.list do
		M.cut[o.name] = {}
	end
	local W = M.CORRIDOR
	for _, f in M.design.flyovers do
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
				if d < best then
					best, fx, fz = d, x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
				end
			end
		end
	end
	if best == math.huge and not nx then
		local a = o.s[i]
		best, fx, fz = hyp(px - a[1], pz - a[3]), a[1], a[3]
	end
	return best, fx, fz
end
M.polyDist = polyDist

-- Roads.build's opts.sideZone: must this road's kerb / pavement stay out of this spot?
function M.sideZone(name: string, pos: Vector3, what: string): boolean
	local px, pz = pos.X, pos.Z
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

-- The whole of step 3 in one go (run it through M.spawn, it takes about half a minute):
-- the bank, the three main roads with their mouths, the roundabout, the lines.
function M.step3()
	local log = {}
	table.insert(log, "cleared " .. M.clear(M.MAIN))
	task.wait()
	table.insert(log, M.bank(M.MAIN))
	task.wait()
	table.insert(log, M.buildRoads(M.MAIN))
	task.wait()
	table.insert(log, M.buildRoundabout())
	task.wait()
	table.insert(log, "lines " .. M.buildLines(M.MAIN))
	return table.concat(log, "\n")
end

function M.buildLines(names: { string })
	return M.RoadLines.build(M.data, M.folder(), setOf(names), { cut = M.cut, paint = M.palette.paint, centre = M.centre, clearMouths = true })
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
	local dome = part({ Name = "IslandMound", Size = Vector3.new(112, 4, 112), CFrame = CFrame.new(C.X, Y0 + 0.45, C.Z), Material = Enum.Material.Grass, Color = grass })
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
										if not (mf and sidesUnder(x, qy, z, mf)) then
											-- (another road's mouth, or the roundabout, right beside this one is no fault)
											local other = hyp(x - C.X, z - C.Z) < M.RING_V + M.WALK + 0.5
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
										local ns = M.near(q.X, q.Z, 2)[S.index]
										if ns and polyDist(S, ns[2], q.X, q.Z) < h - 0.3 then
											inMouth += 1
											break
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
