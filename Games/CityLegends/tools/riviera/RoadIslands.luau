--[[
	Riviera road islands (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP and run
	on build/riviera/roads.json after Roads.build (and after CurveWalls.clearLanes).

	(owner, 2026-11-03, picture of Upper Street meeting Harbour Street: "fix the road here and do the
	boulder properly, the road became 3.5 lane"): where two different roads run side by side, the
	network narrows each one's facing side and Roads.build stood a thin leg wall on the line between
	them. Between the two narrowed edges there is often a gap (with the ground, lower, showing
	through: a pit) and the roads can stand at different heights. clearLanes then took the wall
	pieces standing in a lane away, leaving broken bits over the pit.

	Here the gap gets a proper island: a paved (town) or concrete top ISLAND_UP over each road's own
	edge (it slopes across when the roads differ in height), kerbs along both edges, and down the
	middle a continuous low stone wall (the "boulder") where the island is at least WALL_MIN wide,
	stopping short of its ends. A wall piece never stands within CLEAR of a traffic lane. The old leg
	walls over each island are removed; no terrain is left poking up through an island.

	RoadIslands.build(data, lanes, roadsFolder, parent) -> island pieces, wall pieces, leg walls removed
	(parent: e.g. Workspace.Riviera.Dressing; the pieces go in a folder "RoadIslands", rebuilt each run)
]]

local RoadIslands = {}

local HALF = 32
local MAXGAP = 34 -- look this far past a road's edge for the other road
local MINGAP = 1.2 -- narrower than this: the roads touch, no island
local ISLAND_UP = 0.42 -- island top over the road edge (0.08 under a pavement's top: no flicker)
local KERB_UP = 0.5
local WALK = 10 -- a road's pavement width
local EXTEND = 5 -- samples the island may carry on past the narrowed stretch
local EXTEND_GAP = 26 -- ...while the gap is at most this
local SLAB = 8
local WALL_MIN = 5 -- island width for the wall
local WALL_UP = 2.6
local WALL_DOWN = 8
local THICK = 1.2
local CLEAR = 5.5 -- no wall this close to a lane's centre line
local PAVER = Color3.fromRGB(176, 104, 92)
local CONCRETE = Color3.fromRGB(150, 146, 138)
local KERB = Color3.fromRGB(205, 202, 194)
local ASPHALT = Color3.fromRGB(46, 47, 50)
local PATCH = 6 -- a gap never wider than this is a crack: asphalt, not an island
local STONE = Color3.fromRGB(222, 214, 196)

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- a triangle (a, b, c) as two wedges whose top faces are exactly the triangle, `th` thick below it
-- (the same as Roads.luau's)
local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, props, parent: Instance): number
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
	if nUp.Y < 0.6 then
		return 0 -- a sliver standing on edge (its slab would stick up out of the road)
	end
	local drop = -nUp * (th / 2)
	local w1 = Instance.new("WedgePart")
	w1.Size = Vector3.new(th, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + drop, right, up, back)
	local w2 = Instance.new("WedgePart")
	w2.Size = Vector3.new(th, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back)
	for _, w in { w1, w2 } do
		w.Anchored = true
		w.CastShadow = false
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(w :: any)[k] = v
		end
		w.Parent = parent
	end
	return 2
end

local function bar(a: Vector3, b: Vector3, width: number, height: number, props, parent: Instance): BasePart?
	-- a box from a to b (their tops), `width` wide, `height` tall below the tops
	local len = (b - a).Magnitude
	if len < 0.2 then
		return nil
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Size = Vector3.new(width, height, len + 0.3)
	p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -height / 2, 0)
	p.Parent = parent
	return p
end

-- opts.hairpins = { { road = name, from = i, to = j, side = -1 | 1 }, ... }: build only these, each
-- the gap between two legs of the same road (owner, 2026-11-03, West Switchbacks: "there is a
-- massive hole here and it's also causing traffic"), into folder opts.folder (default "RoadIslands")
function RoadIslands.build(data, lanes, roadsFolder: Instance, parent: Instance, opts: any?): (number, number, number)
	opts = opts or {}
	local roads = {}
	for ri, r in data.roads do
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), wl = s[7] or HALF, wr = s[8] or HALF }
		end
		roads[ri] = { name = r.name, kind = r.kind, pts = pts }
	end

	local roadParts = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Road" or d.Name == "TurningCircle") then
			table.insert(roadParts, d)
		end
	end
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Include
	down.FilterDescendantsInstances = roadParts
	local function surface(p: Vector3): (string?, number?)
		local hit = workspace:Raycast(Vector3.new(p.X, p.Y + 12, p.Z), Vector3.new(0, -30, 0), down)
		if hit and hit.Instance.Parent then
			return hit.Instance.Parent.Name, hit.Position.Y
		end
		return nil, nil
	end

	-- 1. every road side that faces another road across a gap: E (this edge), F (the other's edge)
	-- (pave: the side has its pavement here, WALK wide past w: look from the pavement's outer edge)
	local function probe(r, i: number, side: number, w: number, pave: boolean?, allowSelf: boolean?)
		local p = r.pts[i]
		if p.dir.Magnitude < 0.01 then
			return nil
		end
		local d = flat(p.dir).Unit
		local out = Vector3.new(-d.Z, 0, d.X) * side
		local e = p.pos + out * (if pave then w + WALK else w)
		local own, yE = surface(p.pos + out * (w - 0.6))
		if own ~= r.name or not yE then
			return nil
		end
		local t = 0.6
		local sawGap = false -- (same road: only past a real gap, not the road's own edge running on)
		while t <= MAXGAP do
			local name, y = surface(e + out * t)
			if not name then
				sawGap = true
			end
			if name and y then
				if name == r.name then
					if t > 2 and not allowSelf then
						return nil -- this road again (a hairpin: its leg walls stay)
					end
				end
				if name ~= r.name or (allowSelf and t > 2 and sawGap) then
					if t < MINGAP then
						return false -- touching: no island
					end
					local f = e + out * t
					-- step back to the other road's very edge
					local lo, hi = t - 0.5, t
					for _ = 1, 5 do
						local mid = (lo + hi) / 2
						if surface(e + out * mid) == name then
							hi = mid
						else
							lo = mid
						end
					end
					f = e + out * hi
					return { e = Vector3.new(e.X, yE, e.Z), f = Vector3.new(f.X, y, f.Z), other = name, gap = hi, k = i, pave = pave }
				end
			end
			t += 0.5
		end
		return nil
	end

	local paveQuery = OverlapParams.new()
	paveQuery.FilterType = Enum.RaycastFilterType.Include
	local function pavementAt(r, k: number, side: number, w: number): boolean
		local folderR = roadsFolder:FindFirstChild(r.name)
		local p = r.pts[k]
		if not folderR or p.dir.Magnitude < 0.01 then
			return false
		end
		local d = flat(p.dir).Unit
		local at = p.pos + Vector3.new(-d.Z, 0, d.X) * side * (w + WALK / 2) + Vector3.new(0, 0.5, 0)
		paveQuery.FilterDescendantsInstances = { folderR }
		for _, part in workspace:GetPartBoundsInRadius(at, 2, paveQuery) do
			if part.Name == "Pavement" then
				return true
			end
		end
		return false
	end
	-- (owner's junction, Upper / Harbour Street) past the narrowed stretch the gap goes on beside the
	-- road's pavement, the ground showing as a pit: the island carries on from the pavement's outer
	-- edge while the other road is still near
	local function extend(run, r, side: number)
		local n = #r.pts
		for _, dir in { -1, 1 } do
			local endPr = if dir < 0 then run.list[1] else run.list[#run.list]
			local k = endPr.k + dir
			for _ = 1, EXTEND do
				if k < 1 or k > n then
					break
				end
				local p = r.pts[k]
				local w = if side < 0 then p.wl else p.wr
				local pr = probe(r, k, side, w, pavementAt(r, k, side, w), run.allowSelf)
				if not pr or pr.other ~= run.other or pr.gap > EXTEND_GAP then
					break
				end
				if dir < 0 then
					table.insert(run.list, 1, pr)
				else
					table.insert(run.list, pr)
				end
				k += dir
			end
		end
	end

	local runs = {} -- { road, other, side, list of probes }
	for _, h in opts.hairpins or {} do
		for _, r in roads do
			if r.name == h.road then
				local cur = { road = r.name, kind = r.kind, other = r.name, list = {}, allowSelf = true }
				for k = h.from, h.to do
					local p = r.pts[k]
					local pr = probe(r, k, h.side, if h.side < 0 then p.wl else p.wr, nil, true)
					if pr then
						table.insert(cur.list, pr)
					end
				end
				if #cur.list >= 2 then
					extend(cur, r, h.side)
					table.insert(runs, cur)
				end
			end
		end
	end
	for _, r in (if opts.hairpins then {} else roads) do
		local n = #r.pts
		for _, side in { -1, 1 } do
			local narrowed = {}
			for i, p in r.pts do
				narrowed[i] = (if side < 0 then p.wl else p.wr) < HALF - 0.5
			end
			local i = 1
			while i <= n do
				if narrowed[i] then
					local j = i
					while j < n and narrowed[j + 1] do
						j += 1
					end
					-- the narrowed stretch i..j, plus one full-width sample at each end (closes the gap
					-- to the pavement there)
					local cur = nil
					for k = math.max(1, i - 1), math.min(n, j + 1) do
						local p = r.pts[k]
						local w = if side < 0 then p.wl else p.wr
						local pr = probe(r, k, side, w)
						if pr and (cur == nil or cur.other == pr.other) then
							cur = cur or { road = r.name, kind = r.kind, other = pr.other, list = {} }
							table.insert(cur.list, pr)
						else
							if cur and #cur.list >= 2 then
								extend(cur, r, side)
								table.insert(runs, cur)
							end
							cur = nil
							if pr then
								cur = { road = r.name, kind = r.kind, other = pr.other, list = { pr } }
							end
						end
					end
					if cur and #cur.list >= 2 then
						extend(cur, r, side)
						table.insert(runs, cur)
					end
					i = j + 1
				else
					i += 1
				end
			end
			task.wait()
		end
	end

	-- 2. both roads often find the same gap (each from its own edge, each covering a part of it):
	-- the side with more of it is built first, the other 0.25 lower (its top stays under the
	-- first's: no flicker), with no kerb where the first has one and no wall
	local total = {}
	for _, run in runs do
		local key = run.road .. "|" .. run.other
		total[key] = (total[key] or 0) + #run.list
	end
	local kindOf = {}
	for _, r in roads do
		kindOf[r.name] = r.kind
	end
	local keep = {}
	for _, run in runs do
		local mine = total[run.road .. "|" .. run.other] or 0
		local theirs = total[run.other .. "|" .. run.road] or 0
		run.second = run.road ~= run.other and not (mine > theirs or (mine == theirs and run.road < run.other))
		run.otherKind = kindOf[run.other]
		table.insert(keep, run)
	end
	table.sort(keep, function(a, b)
		return (if a.second then 1 else 0) < (if b.second then 1 else 0)
	end)

	RoadIslands.lastRuns = keep -- (for checking)
	-- 3. build
	local folderName = opts.folder or "RoadIslands"
	local folder = parent:FindFirstChild(folderName)
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent

	local query = OverlapParams.new()
	query.FilterType = Enum.RaycastFilterType.Include
	local kerbs = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Kerb" then
			table.insert(kerbs, d)
		end
	end
	table.insert(kerbs, folder)
	query.FilterDescendantsInstances = kerbs
	local function has(p: Vector3, radius: number, names: { [string]: boolean }): boolean
		for _, part in workspace:GetPartBoundsInRadius(p, radius, query) do
			if names[part.Name] then
				return true
			end
		end
		return false
	end
	local KERBS = { Kerb = true, IslandKerb = true }

	local pieces, walls = 0, 0
	local wallParts = {}
	local areas = {}
	for _, run in keep do
		local model = Instance.new("Model")
		model.Name = run.road .. " / " .. run.other
		model.Parent = folder
		-- (both islands of a gap look the same: pavers when either road is a town street)
		local town = run.kind == "street" or run.otherKind == "street"
		local top = { Name = "Island", Material = Enum.Material.Pavement, Color = if town then PAVER else CONCRETE }
		local kerbProps = { Name = "IslandKerb", Material = Enum.Material.Concrete, Color = KERB }
		local L = run.list
		local up = Vector3.new(0, if run.second then ISLAND_UP - 0.25 else ISLAND_UP, 0)
		-- a thin crack between two road surfaces (never wider than PATCH): filled with asphalt just
		-- under the roads' edges, no kerbs (a kerbed sliver stood in the middle of a junction)
		local widest = 0
		for _, pr in L do
			widest = math.max(widest, pr.gap)
		end
		local patch = widest < PATCH
		if patch then
			top = { Name = "IslandPatch", Material = Enum.Material.Asphalt, Color = ASPHALT }
			up = Vector3.new(0, if run.second then -0.14 else -0.07, 0)
		end
		for k = 1, #L - 1 do
			local a, b = L[k], L[k + 1]
			local ea, eb, fa, fb = a.e + up, b.e + up, a.f + up, b.f + up
			pieces += triangle(ea, eb, fb, SLAB, top, model)
			pieces += triangle(ea, fb, fa, SLAB, top, model)
			-- kerbs on both edges, set 0.45 in from the road (none where a kerb stands already)
			for side, pair in { { a.e, b.e, a.f, b.f }, { a.f, b.f, a.e, b.e } } do
				if patch then
					break
				end
				if side == 1 and (a.pave or b.pave) then
					continue -- the pavement's outer edge: no kerb
				end
				local p0, p1 = pair[1], pair[2]
				local in0 = flat(pair[3] - p0).Unit * 0.45
				local in1 = flat(pair[4] - p1).Unit * 0.45
				local m0 = p0 + in0 + Vector3.new(0, KERB_UP, 0)
				local m1 = p1 + in1 + Vector3.new(0, KERB_UP, 0)
				if not has((m0 + m1) / 2 - Vector3.new(0, KERB_UP, 0), 1.5, KERBS) then
					if bar(m0, m1, 0.9, 4, kerbProps, model) then
						pieces += 1
					end
				end
			end
			table.insert(areas, { a.e, b.e, b.f, a.f })
		end
		-- the wall down the middle, where the island is wide enough, one sample short of each end
		for k = 2, #L - 2 do
			local a, b = L[k], L[k + 1]
			local ma = (a.e + a.f) / 2 + up
			local mb = (b.e + b.f) / 2 + up
			-- (only on the first island of a gap, and not beside a pavement: one clean wall)
			if not patch and a.gap >= WALL_MIN and b.gap >= WALL_MIN and not run.second and not (a.pave or b.pave) then
				local w = bar(ma + Vector3.new(0, WALL_UP, 0), mb + Vector3.new(0, WALL_UP, 0), THICK, WALL_UP + WALL_DOWN, { Name = "IslandWall", Material = Enum.Material.Limestone, Color = STONE }, model)
				if w then
					table.insert(wallParts, w)
					walls += 1
				end
			end
		end
	end

	-- no ground may poke up through an island (it showed as rock patches): clear the terrain from 4
	-- under each island piece's top (the slab hides what's left) to 10 over it
	for _, d in folder:GetDescendants() do
		if d:IsA("WedgePart") and (d.Name == "Island" or d.Name == "IslandPatch") then
			-- the wedge's triangle (local y, z): (-Y/2, -Z/2), (-Y/2, Z/2), (Y/2, Z/2), on its top side
			local sx = if d.CFrame.RightVector.Y >= 0 then d.Size.X / 2 else -d.Size.X / 2
			local hy, hz = d.Size.Y / 2, d.Size.Z / 2
			local a = d.CFrame:PointToWorldSpace(Vector3.new(sx, -hy, -hz))
			local b = d.CFrame:PointToWorldSpace(Vector3.new(sx, -hy, hz))
			local c = d.CFrame:PointToWorldSpace(Vector3.new(sx, hy, hz))
			local mid = (a + b + c) / 3
			for _, q in { mid, (a + mid) / 2, (b + mid) / 2, (c + mid) / 2 } do
				workspace.Terrain:FillBlock(CFrame.new(q + Vector3.new(0, 3, 0)), Vector3.new(4, 14, 4), Enum.Material.Air)
			end
		end
	end

	-- 4. no wall piece near a lane
	if lanes then
		local cells = {}
		for _, l in lanes.lanes do
			local pts = l.pts
			for k = 1, #pts // 3 - 1 do
				local a = Vector3.new(pts[3 * k - 2], pts[3 * k - 1], pts[3 * k])
				local b = Vector3.new(pts[3 * k + 1], pts[3 * k + 2], pts[3 * k + 3])
				local n = math.max(1, math.ceil((b - a).Magnitude / 2))
				for i = 0, n - 1 do
					local q = a:Lerp(b, i / n)
					local key = math.floor(q.X / 32) .. "," .. math.floor(q.Z / 32)
					cells[key] = cells[key] or {}
					table.insert(cells[key], q)
				end
			end
		end
		for _, w in wallParts do
			local half = w.Size.Z / 2
			local y = w.Position.Y + w.Size.Y / 2 - WALL_UP
			local hit = false
			for _, f in { -1, -0.5, 0, 0.5, 1 } do
				local q = w.CFrame:PointToWorldSpace(Vector3.new(0, 0, half * f))
				local cx, cz = math.floor(q.X / 32), math.floor(q.Z / 32)
				for dx = -1, 1 do
					for dz = -1, 1 do
						for _, p in cells[(cx + dx) .. "," .. (cz + dz)] or {} do
							if math.abs(p.Y - y) < 12 and Vector2.new(p.X - q.X, p.Z - q.Z).Magnitude < CLEAR then
								hit = true
							end
						end
					end
				end
			end
			if hit then
				w:Destroy()
				walls -= 1
			end
		end
	end

	-- 5. the old leg walls standing over an island go
	local function inQuad(q: { Vector3 }, p: Vector3): boolean
		local sign = 0
		for k = 1, 4 do
			local a, b = q[k], q[k % 4 + 1]
			local c = (b.X - a.X) * (p.Z - a.Z) - (b.Z - a.Z) * (p.X - a.X)
			if math.abs(c) > 1e-6 then
				local s = if c > 0 then 1 else -1
				if sign == 0 then
					sign = s
				elseif s ~= sign then
					return false
				end
			end
		end
		return true
	end
	local gone = 0
	for _, d in roadsFolder:GetDescendants() do
		if d.Name == "LegWall" and d:IsA("BasePart") then
			local p = d.Position
			for _, q in areas do
				-- grow the quad a little: the wall stood on its edge line
				local c = (q[1] + q[2] + q[3] + q[4]) / 4
				local g = {}
				for k = 1, 4 do
					g[k] = c + (q[k] - c) * 1.25
				end
				if inQuad(g, p) and math.abs(p.Y - c.Y) < 15 then
					d:Destroy()
					gone += 1
					break
				end
			end
		end
	end
	return pieces, walls, gone
end

return RoadIslands
