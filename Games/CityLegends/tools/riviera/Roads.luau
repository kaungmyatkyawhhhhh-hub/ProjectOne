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

local function newPart(props: { [string]: any }, parent: Instance): BasePart
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
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1 }
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

local function inBox(box, p: Vector3): boolean
	return box == nil or (p.X >= box[1] and p.X <= box[3] and p.Z >= box[2] and p.Z <= box[4])
end

-- a flat box whose top face runs from a to b (both on the road's centre line), shifted sideways
local function stripCF(a: Vector3, b: Vector3, side: number, up: number): CFrame
	local cf = CFrame.lookAt(a, b)
	local mid = (a + b) / 2
	return CFrame.new(mid) * cf.Rotation * CFrame.new(side, up, 0)
end

function Roads.build(data, opts)
	opts = opts or {}
	local box = opts.box
	local parent = opts.parent
	local roads, grid = prepare(data)
	local count = 0
	for ri, r in roads do
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
		for i, p in pts do
			local right = Vector3.new(-p.dir.Z, 0, p.dir.X).Unit * HALF
			edgeL[i], edgeR[i] = p.pos - right, p.pos + right
			if i > 1 then
				local d = pts[i].pos - pts[i - 1].pos
				d = Vector3.new(d.X, 0, d.Z)
				if (edgeL[i] - edgeL[i - 1]):Dot(d) <= 0 then
					edgeL[i] = Vector3.new(edgeL[i - 1].X, p.pos.Y, edgeL[i - 1].Z)
				end
				if (edgeR[i] - edgeR[i - 1]):Dot(d) <= 0 then
					edgeR[i] = Vector3.new(edgeR[i - 1].X, p.pos.Y, edgeR[i - 1].Z)
				end
			end
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
				count += triangle(la, rra, rrb, SLAB, props, folder)
				count += triangle(la, rrb, lb, SLAB, props, folder)
				-- no terrain may stand above the road surface (it would be a bump). Terrain clears whole
				-- 4-stud voxels by their centres, so clear from 4 studs under the top up
				workspace.Terrain:FillBlock(cf * CFrame.new(0, SLAB / 2 - 4 + 11, 0), Vector3.new((HALF + WALK) * 2, 22, len + grow), Enum.Material.Air)
			end
			-- outside the town: flush concrete shoulders (the ground under them is cleared too)
			if not town then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					if otherNear(roads, grid, mid + right * side * (HALF + WALK / 2), ri, HALF + 2) == nil then
						local cf = stripCF(a2, b2, side * (HALF + WALK / 2), -3 - 0.02)
						newPart({ Name = "Shoulder", Size = Vector3.new(WALK, 6, len + grow), CFrame = cf, Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 146, 138) }, folder)
						count += 1
					end
				end
			end
			-- pavements and kerbs, each side
			if town then
				for _, side in { -1, 1 } do
					local mid = (a.pos + b.pos) / 2
					local right = Vector3.new(-(b.pos - a.pos).Z, 0, (b.pos - a.pos).X).Unit
					local sidePos = mid + right * side * (HALF + WALK / 2)
					if otherNear(roads, grid, sidePos, ri, HALF + 2) == nil and not a.tunnel then
						-- 6 studs deep: the terrain under the road is cleared 4 studs down
						local walkCF = stripCF(a2, b2, side * (HALF + WALK / 2), CURB_UP - 3)
						newPart({ Name = "Pavement", Size = Vector3.new(WALK, 6, len + grow), CFrame = walkCF, Material = Enum.Material.Pavement, Color = paver }, folder)
						local kerbCF = stripCF(a2, b2, side * (HALF + 0.45), CURB_UP + 0.02 - 3)
						local k = newPart({ Name = "Kerb", Size = Vector3.new(0.9, 6.04, len + grow), CFrame = kerbCF, Material = Enum.Material.Granite, Color = KERB }, folder)
						k.CastShadow = false
						count += 2
					end
				end
			end
			-- lines (painted on the slab's own plane)
			if not (inJunction[i] or inJunction[i + 1]) then
				dash += 1
				local lines = {}
				table.insert(lines, { x = HALF - 1.2, w = 0.6, solid = true })
				table.insert(lines, { x = -(HALF - 1.2), w = 0.6, solid = true })
				if dash % 2 == 0 then
					table.insert(lines, { x = 0, w = 0.5 })
					table.insert(lines, { x = HALF / 2, w = 0.4 })
					table.insert(lines, { x = -HALF / 2, w = 0.4 })
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
			-- zebra crossing where the road leaves a junction (town streets)
			if town and i > 1 and inJunction[i - 1] and not inJunction[i] and not zebraDone[i] then
				zebraDone[i] = true
				local cf = stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, -len / 2 + 7)
				for k = -6, 6 do
					local p = newPart({ Name = "Zebra", Size = Vector3.new(2.6, LINE_T, 10), CFrame = cf * CFrame.new(k * 4.8, 0, 0), Material = Enum.Material.SmoothPlastic, Color = PAINT }, folder)
					decor(p)
					count += 1
				end
			end
			if i < n - 1 and inJunction[i + 1] and not inJunction[i] then
				local cf = stripCF(a.pos, b.pos, 0, LINE_T / 2 + 0.04) * CFrame.new(0, 0, len / 2 - 7)
				for k = -6, 6 do
					local p = newPart({ Name = "Zebra", Size = Vector3.new(2.6, LINE_T, 10), CFrame = cf * CFrame.new(k * 4.8, 0, 0), Material = Enum.Material.SmoothPlastic, Color = PAINT }, folder)
					decor(p)
					count += 1
				end
			end
			if i % 40 == 0 then
				task.wait()
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
