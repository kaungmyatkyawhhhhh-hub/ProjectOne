--[[
	HoleFill (Studio, Edit mode; 2026-11-03, smooth roads): fills a small gap in the asphalt (the ground
	showing between two road surfaces at a junction corner) found by LaneCheck. Around the spot, a grid
	of rays a stud apart finds the gap's cells (terrain lower than the road round it) and the road hits
	(their plane, fitted by least squares); the gap's outline (its convex hull, grown half a stud) is
	filled with asphalt triangles on that plane, 0.05 under it where it overlaps the road (no flicker).
	Parts are named Road with the attribute HoleFill.

	HoleFill.at(pos, folder, radius?) -> parts made
]]

local HoleFill = {}

local ASPHALT = Color3.fromRGB(46, 47, 50)
local SURFACES = { Road = true, IslandPatch = true }

local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, parent: Instance): number
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
		w.Name = "Road"
		w.Anchored = true
		w.CastShadow = false
		w.Material = Enum.Material.Asphalt
		w.Color = ASPHALT
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w:SetAttribute("HoleFill", true)
		w.Parent = parent
	end
	return 2
end

-- 2D convex hull (x, z) of points
local function hull(pts: { Vector2 }): { Vector2 }
	table.sort(pts, function(a, b)
		return a.X < b.X or (a.X == b.X and a.Y < b.Y)
	end)
	local function cross(o: Vector2, a: Vector2, b: Vector2): number
		return (a.X - o.X) * (b.Y - o.Y) - (a.Y - o.Y) * (b.X - o.X)
	end
	local lower, upper = {}, {}
	for _, p in pts do
		while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 0 do
			table.remove(lower)
		end
		table.insert(lower, p)
	end
	for i = #pts, 1, -1 do
		local p = pts[i]
		while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 0 do
			table.remove(upper)
		end
		table.insert(upper, p)
	end
	table.remove(lower)
	table.remove(upper)
	for _, p in upper do
		table.insert(lower, p)
	end
	return lower
end

function HoleFill.at(pos: Vector3, folder: Instance, radius: number?): number
	local R = radius or 7
	local riv = workspace:FindFirstChild("Riviera")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { riv, workspace.Terrain }
	params.RespectCanCollide = true
	local holes: { Vector3 } = {}
	local road: { Vector3 } = {}
	for dx = -R, R do
		for dz = -R, R do
			local q = pos + Vector3.new(dx, 0, dz)
			local hit = workspace:Raycast(q + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), params)
			if hit then
				if hit.Instance == workspace.Terrain then
					table.insert(holes, hit.Position)
				elseif SURFACES[hit.Instance.Name] then
					table.insert(road, hit.Position)
				end
			end
		end
	end
	if #holes == 0 or #road < 6 then
		return 0
	end
	-- the road's plane y = a + b x + c z (least squares, centred on pos)
	local sxx, sxz, szz, sx, sz, sy, sxy, szy, n = 0, 0, 0, 0, 0, 0, 0, 0, #road
	for _, p in road do
		local x, z = p.X - pos.X, p.Z - pos.Z
		sxx += x * x
		sxz += x * z
		szz += z * z
		sx += x
		sz += z
		sy += p.Y
		sxy += x * p.Y
		szy += z * p.Y
	end
	-- normal equations [n sx sz; sx sxx sxz; sz sxz szz] [a b c] = [sy sxy szy]
	local m = { { n, sx, sz, sy }, { sx, sxx, sxz, sxy }, { sz, sxz, szz, szy } }
	for col = 1, 3 do
		local piv = col
		for r = col + 1, 3 do
			if math.abs(m[r][col]) > math.abs(m[piv][col]) then
				piv = r
			end
		end
		m[col], m[piv] = m[piv], m[col]
		if math.abs(m[col][col]) < 1e-9 then
			return 0
		end
		for r = 1, 3 do
			if r ~= col then
				local f = m[r][col] / m[col][col]
				for c = col, 4 do
					m[r][c] -= f * m[col][c]
				end
			end
		end
	end
	local a, b, c = m[1][4] / m[1][1], m[2][4] / m[2][2], m[3][4] / m[3][3]
	local function planeY(x: number, z: number): number
		return a + b * (x - pos.X) + c * (z - pos.Z)
	end
	-- only cells where the ground is under the road (a real gap, not a lane leaving the road)
	local cells: { Vector2 } = {}
	for _, h in holes do
		if planeY(h.X, h.Z) - h.Y > 0.2 then
			for _, o in { Vector2.new(-0.6, -0.6), Vector2.new(0.6, -0.6), Vector2.new(0.6, 0.6), Vector2.new(-0.6, 0.6) } do
				table.insert(cells, Vector2.new(h.X, h.Z) + o)
			end
		end
	end
	if #cells < 3 then
		return 0
	end
	local poly = hull(cells)
	if #poly < 3 then
		return 0
	end
	local cx, cz = 0, 0
	for _, p in poly do
		cx += p.X
		cz += p.Y
	end
	cx /= #poly
	cz /= #poly
	local function at3(x: number, z: number): Vector3
		return Vector3.new(x, planeY(x, z) - 0.05, z)
	end
	local made = 0
	local centre = at3(cx, cz)
	for i = 1, #poly do
		local p, q = poly[i], poly[i % #poly + 1]
		made += triangle(centre, at3(p.X, p.Y), at3(q.X, q.Y), 2, folder)
	end
	return made
end

return HoleFill
