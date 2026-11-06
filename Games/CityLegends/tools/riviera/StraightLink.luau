--[[
	StraightLink (Studio, Edit mode; owner, 2026-11-06, a picture with two red lines: "make the road like this"):
	the Mountain Road carries straight on into the West Switchbacks' top bend. It used to end at a junction
	and turn back through a tight bend and a long leg; the new stretch is a straight, about 220 studs long, climbing
	at the same 10% as the bend it runs into. Width as the road on both sides: 32 each side of the middle, kerb, 10 of pavement.

	StraightLink.backup()    copies the ground into ServerStorage.StraightLinkGround
	StraightLink.clear()     moves the old stretch to ServerStorage.StraightLinkOld (roads, the island, what stood on it)
	StraightLink.ground()    cuts the hillside for the new road and fills the old road's bed back to a green bank
	StraightLink.build(y0, y1) lays the road, kerbs, pavements and lines; y0, y1: the road's height at each end
	StraightLink.patchWest(y0, y1) closes the gap to the old surface at the bend
	StraightLink.fillBed()   grass over what was left of the old road's bed by the Mountain Road
	StraightLink.join()      lines and shoulder across the old junction's mouth, to the Mountain Road's own
	StraightLink.lamps(y0, y1) street lamps along the new stretch
	StraightLink.planter(y0, y1) moves the planter left on the bank onto the new pavement
	StraightLink.undo()      puts it all back

	Order: backup, clear, ground, build, patchWest, fillBed, join, lamps, planter. Used with y0 = 193.23, y1 = 214.66.
	The lanes are moved in src/shared/RivieraLanes.lua (same number of points, so no junction link changes).
	After it the road meshes need a new export and upload (tools/road_mesh/); join's lines and shoulder are
	plain parts, not meshes. The map tile comes from tools/minimap_art.py (it draws the same straight).
]]

local ServerStorage = game:GetService("ServerStorage")

local StraightLink = {}

local X0, X1 = 10905, 11150 -- the new road's ends (it overlaps the old road a little at each)
local Z0, Z1 = -176, -174.1
local CUT_WEST, CUT_EAST = 10914, 11134 -- old pieces between these go (the road surface from 10907: the old bend leans there)
local HALF = 32
local KERB_W, WALK = 0.9, 10
local STEP = 8
local KERB_STEP, PAVE_STEP = 5, 6
local KERB_UP, PAVE_UP = 0.58, 0.5
local THICK = 4
local PAINT = Color3.fromRGB(232, 232, 226)
local ASPHALT = Color3.fromRGB(46, 47, 50)
local PAVER = Color3.fromRGB(176, 104, 92)
local KERB = Color3.fromRGB(205, 202, 194)
local C = 4 -- terrain voxel
local BOX_MIN = Vector3.new(10860, 160, -320)
local BOX_MAX = Vector3.new(11204, 340, -20)
local SLOPE_CUT, SLOPE_FILL = 1.35, 0.7
-- the old road's middle (samples 384 to 426), for the green bank
local OLD = {
	{ 10922, 194.9, -175 }, { 10959, 198.7, -165 }, { 11002, 203.4, -148 }, { 11045, 208.1, -128 }, { 11084, 212.2, -112 },
	{ 11112, 214.7, -104 }, { 11131, 214.7, -127 }, { 11120, 214.7, -176 },
}

local function zAt(x: number): number
	return Z0 + (Z1 - Z0) * (x - X0) / (X1 - X0)
end

local function holding(name: string): Folder
	local f = ServerStorage:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = ServerStorage
	end
	return f :: Folder
end

function StraightLink.backup()
	local t = workspace.Terrain
	local region = Region3int16.new(
		Vector3int16.new(BOX_MIN.X // C, BOX_MIN.Y // C, BOX_MIN.Z // C),
		Vector3int16.new(BOX_MAX.X // C, BOX_MAX.Y // C, BOX_MAX.Z // C)
	)
	local copy = t:CopyRegion(region)
	copy.Name = "StraightLinkGround"
	copy:SetAttribute("Corner", BOX_MIN)
	copy.Parent = ServerStorage
end

-- the old stretch: everything of the two roads between the cuts, high up
function StraightLink.clear(): number
	local keep = holding("StraightLinkOld")
	local roads = workspace.Riviera.Roads
	local n = 0
	local function moveFrom(road: Instance, test: (BasePart) -> boolean)
		local f = keep:FindFirstChild(road.Name)
		if not f then
			f = Instance.new("Folder")
			f.Name = road.Name
			f.Parent = keep
		end
		for _, p in road:GetChildren() do
			if p:IsA("BasePart") and test(p) then
				p.Parent = f
				n += 1
			end
		end
	end
	moveFrom(roads["West Switchbacks"], function(p)
		local from = if p.Name == "Road" then 10907 else CUT_WEST
		return p.Position.Y > 190 and p.Position.X > from and p.Position.Z < -40 and p:GetAttribute("StraightLink") == nil
	end)
	moveFrom(roads["Mountain Road"], function(p)
		return p.Position.X < CUT_EAST and p.Position.Z > -260 and p.Position.Z < -60
	end)
	local dressing = workspace.Riviera.Dressing
	local isl = dressing:FindFirstChild("HairpinIslands")
	if isl then
		isl.Parent = keep
		n += 1
	end
	-- what stood on the old road or stands on the new one
	for _, d in dressing:GetChildren() do
		if d:IsA("Model") or d:IsA("BasePart") then
			local at = if d:IsA("Model") then d:GetPivot().Position else (d :: BasePart).Position
			if at.Y > 188 and at.Y < 245 and at.X > CUT_WEST and at.X < 11175 and at.Z > -245 and at.Z < -55 then
				d.Parent = keep
				n += 1
			end
		end
	end
	return n
end

-- the ground: (height the column should stop at, or nil: leave it), and what it's made of
local function roadY(x: number, y0: number, y1: number): number
	-- a straight climb that eases out into the flat top
	local top = 11120
	local ease = 22
	local grade = (y1 - y0) / (top - ease / 2 - X0)
	if x <= top - ease then
		return y0 + grade * (x - X0)
	elseif x >= top then
		return y1
	end
	local t = (top - x) / ease
	return y1 - grade * ease * t * t / 2
end
StraightLink.roadY = roadY

function StraightLink.ground(y0: number, y1: number): number
	local t = workspace.Terrain
	local region = Region3.new(BOX_MIN, BOX_MAX):ExpandToGrid(C)
	local mats, occ = t:ReadVoxels(region, C)
	local sz = mats.Size
	local low = region.CFrame.Position - region.Size / 2
	local edge = HALF + KERB_W + WALK
	local changed = 0
	for ix = 1, sz.X do
		local x = low.X + (ix - 0.5) * C
		for iz = 1, sz.Z do
			local z = low.Z + (iz - 0.5) * C
			-- the ground's top here
			local g = low.Y
			local topMat = Enum.Material.Ground
			for iy = sz.Y, 1, -1 do
				if occ[ix][iy][iz] > 0.02 and mats[ix][iy][iz] ~= Enum.Material.Water then
					g = low.Y + (iy - 1 + occ[ix][iy][iz]) * C
					topMat = mats[ix][iy][iz]
					break
				end
			end
			local want = g
			local mat = nil
			-- the old road's bed: back up to the road's old height, in grass
			local nearOld, oldY = math.huge, 0
			for k = 1, #OLD - 1 do
				local a, b = OLD[k], OLD[k + 1]
				local dx, dz = b[1] - a[1], b[3] - a[3]
				local u = math.clamp(((x - a[1]) * dx + (z - a[3]) * dz) / (dx * dx + dz * dz), 0, 1)
				local d = math.sqrt((x - a[1] - dx * u) ^ 2 + (z - a[3] - dz * u) ^ 2)
				if d < nearOld then
					nearOld, oldY = d, a[2] + (b[2] - a[2]) * u
				end
			end
			-- (not past the new road's end: the Mountain Road's own bed is there)
			if x < X1 - 4 and x > CUT_WEST + 6 and nearOld < edge + 4 and want < oldY - 0.4 then
				want = oldY - 0.4
				mat = Enum.Material.Grass
			elseif x < X1 - 4 and x > CUT_WEST + 6 and nearOld < edge + 4 and topMat == Enum.Material.Asphalt then
				mat = Enum.Material.Grass
			end
			-- the new road
			if x >= X0 and x <= X1 + 8 then
				local cx = math.clamp(x, X0, X1)
				local h = roadY(cx, y0, y1)
				local d = math.abs(z - zAt(cx))
				if d <= HALF then
					want = h - 4
					mat = Enum.Material.Asphalt
				elseif d <= edge + 1 then
					want = h - 1.4
					mat = Enum.Material.Ground
				else
					local e = d - edge - 1
					local top = h - 1.4 + e * SLOPE_CUT
					local bottom = h - 1.4 - e * SLOPE_FILL
					if want > top then
						want = top
						mat = Enum.Material.Rock
					elseif want < bottom then
						want = bottom
						mat = Enum.Material.Ground
					end
				end
			end
			if math.abs(want - g) > 0.05 or mat then
				changed += 1
				for iy = 1, sz.Y do
					local yb = low.Y + (iy - 1) * C
					local o = math.clamp((want - yb) / C, 0, 1)
					occ[ix][iy][iz] = o
					if o <= 0 then
						mats[ix][iy][iz] = Enum.Material.Air
					elseif mat and yb + C >= want - C then
						mats[ix][iy][iz] = mat
					elseif mats[ix][iy][iz] == Enum.Material.Air then
						mats[ix][iy][iz] = mat or topMat
					end
				end
			end
		end
	end
	t:WriteVoxels(region, C, mats, occ)
	return changed
end

-- a triangle (a, b, c) as two wedges, as Roads.luau builds them
local function triangle(a: Vector3, b: Vector3, c: Vector3, parent: Instance)
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
		return
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	local drop = -nUp * (THICK / 2)
	local w1 = Instance.new("WedgePart")
	w1.Size = Vector3.new(THICK, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + drop, right, up, back)
	local w2 = Instance.new("WedgePart")
	w2.Size = Vector3.new(THICK, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back)
	for _, w in { w1, w2 } do
		w.Name = "Road"
		w.Anchored = true
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w.Material = Enum.Material.Asphalt
		w.Color = ASPHALT
		w.CastShadow = false
		w:SetAttribute("StraightLink", true)
		w.Parent = parent
	end
end

local function box(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean, parent: Instance)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid
	p.CanTouch = false
	p.CanQuery = solid
	p.CastShadow = false
	p:SetAttribute("StraightLink", true)
	p.Parent = parent
end

function StraightLink.build(y0: number, y1: number): number
	local road = workspace.Riviera.Roads["West Switchbacks"]
	local function at(x: number, off: number, up: number): Vector3
		return Vector3.new(x, roadY(x, y0, y1) + up, zAt(x) + off)
	end
	-- the surface: two strips
	local x = X0
	while x < X1 do
		local nx = math.min(x + STEP, X1)
		for _, s in { { -HALF, 0 }, { 0, HALF } } do
			local a, b = at(x, s[1], 0), at(x, s[2], 0)
			local c, d = at(nx, s[1], 0), at(nx, s[2], 0)
			triangle(a, b, d, road)
			triangle(a, d, c, road)
		end
		x = nx
	end
	-- kerbs and pavements (they start where the old ones stop)
	for _, side in { -1, 1 } do
		local kx = CUT_WEST - 6
		while kx < CUT_EAST do
			local nx = math.min(kx + KERB_STEP, CUT_EAST)
			local a, b = at(kx, side * (HALF + 0.4), KERB_UP - 3.02), at(nx, side * (HALF + 0.4), KERB_UP - 3.02)
			box("Kerb", Vector3.new(KERB_W, 6.04, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), KERB, Enum.Material.Concrete, true, road)
			kx = nx
		end
		local px = CUT_WEST - 6
		while px < CUT_EAST do
			local nx = math.min(px + PAVE_STEP, CUT_EAST)
			local off = side * (HALF + KERB_W - 0.4 + WALK / 2 - 0.05)
			local a, b = at(px, off, PAVE_UP - 3), at(nx, off, PAVE_UP - 3)
			box("Pavement", Vector3.new(WALK, 6, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), PAVER, Enum.Material.Pavement, true, road)
			px = nx
		end
	end
	-- lines: solid edges, a dashed middle
	local lift = 0.1
	for _, side in { -1, 1 } do
		local lx = CUT_WEST - 6
		while lx < CUT_EAST do
			local nx = math.min(lx + 6, CUT_EAST)
			local a, b = at(lx, side * (HALF - 1.5), lift), at(nx, side * (HALF - 1.5), lift)
			box("Line", Vector3.new(0.6, 0.04, (b - a).Magnitude + 0.3), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
			lx = nx
		end
	end
	local dx = CUT_WEST - 6
	while dx < CUT_EAST - 8 do
		local a, b = at(dx, 0, lift), at(dx + 7, 0, lift)
		box("Line", Vector3.new(0.5, 0.04, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
		dx += 15
	end
	local n = 0
	for _, p in road:GetChildren() do
		if p:GetAttribute("StraightLink") then
			n += 1
		end
	end
	return n
end

-- the road's top at (x, z), or nil
local function surface(x: number, z: number): number?
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Riviera.Roads }
	local y = 240
	for _ = 1, 8 do
		local r = workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -40, 0), rp)
		if not r then
			return nil
		end
		if r.Instance.Name == "Road" then
			return r.Position.Y
		end
		y = r.Position.Y - 0.01
	end
	return nil
end

-- the new surface starts at 10905; the bend's own ends at about 10896
function StraightLink.patchWest(y0: number, y1: number)
	local road = workspace.Riviera.Roads["West Switchbacks"]
	local xw, xe = 10896, 10905.5
	local a = Vector3.new(xw, surface(xw, -207) or 192.67, -208)
	local b = Vector3.new(xw, surface(xw, -176) or 192.34, -176)
	local c = Vector3.new(xw, surface(xw, -145) or 191.77, -144)
	local h = roadY(X0, y0, y1)
	local d, e, f = Vector3.new(xe, h, -208), Vector3.new(xe, h, -176), Vector3.new(xe, h, -144)
	triangle(a, b, e, road)
	triangle(a, e, d, road)
	triangle(b, c, f, road)
	triangle(b, f, e, road)
end

-- the old road left the Mountain Road here and went round; its bed stayed open beside the join. Grass, levelled
-- in from what's round it (a few hundred rounds of "the average of your neighbours")
function StraightLink.fillBed(): number
	local t = workspace.Terrain
	local region = Region3.new(Vector3.new(11116, 188, -140), Vector3.new(11200, 250, -44)):ExpandToGrid(C)
	local mats, occ = t:ReadVoxels(region, C)
	local sz = mats.Size
	local low = region.CFrame.Position - region.Size / 2
	local function front(x: number): number -- along the shoulder: just under its top
		return 212.86 + (210.5 - 212.86) * math.clamp((x - 11168) / 16, 0, 1)
	end
	local H, bed, fixed = {}, {}, {}
	for ix = 1, sz.X do
		H[ix], bed[ix], fixed[ix] = {}, {}, {}
		local x = low.X + (ix - 0.5) * C
		for iz = 1, sz.Z do
			local z = low.Z + (iz - 0.5) * C
			local g, m = nil, nil
			for iy = sz.Y, 1, -1 do
				if occ[ix][iy][iz] > 0.02 and mats[ix][iy][iz] ~= Enum.Material.Water then
					g = low.Y + (iy - 1 + occ[ix][iy][iz]) * C
					m = mats[ix][iy][iz]
					break
				end
			end
			H[ix][iz] = g
			if g and x >= 11132 and x <= 11186 and z >= -131 and z <= -58 then
				local soft = m == Enum.Material.Ground or m == Enum.Material.Grass
				if m == Enum.Material.Asphalt or m == Enum.Material.Pavement or (soft and g < 213.6) then
					bed[ix][iz] = true
					fixed[ix][iz] = z < -127
					H[ix][iz] = if z < -127 then front(x) else 214
				end
			end
		end
	end
	for _ = 1, 300 do
		for ix = 1, sz.X do
			for iz = 1, sz.Z do
				if bed[ix][iz] and not fixed[ix][iz] then
					local s, n = 0, 0
					for _, o in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
						local a = H[ix + o[1]]
						local v = a and a[iz + o[2]]
						if v then
							s += v
							n += 1
						end
					end
					if n > 0 then
						H[ix][iz] = s / n
					end
				end
			end
		end
	end
	local changed = 0
	for ix = 1, sz.X do
		for iz = 1, sz.Z do
			if bed[ix][iz] then
				local want = H[ix][iz]
				changed += 1
				for iy = 1, sz.Y do
					local yb = low.Y + (iy - 1) * C
					local o = math.clamp((want - yb) / C, 0, 1)
					occ[ix][iy][iz] = o
					if o <= 0 then
						mats[ix][iy][iz] = Enum.Material.Air
					elseif yb + C >= want - C then
						mats[ix][iy][iz] = Enum.Material.Grass
					elseif mats[ix][iy][iz] == Enum.Material.Air then
						mats[ix][iy][iz] = Enum.Material.Ground
					end
				end
			end
		end
	end
	t:WriteVoxels(region, C, mats, occ)
	return changed
end

-- a curve from (ax, az) to (bx, bz) that leaves and arrives along each road's own heading
local function curve(ax: number, az: number, adz: number, bx: number, bz: number, bdz: number, u: number): (number, number)
	local l = bx - ax
	local u2, u3 = u * u, u * u * u
	return ax + l * u, (2 * u3 - 3 * u2 + 1) * az + (u3 - 2 * u2 + u) * adz * l + (-2 * u3 + 3 * u2) * bz + (u3 - u2) * bdz * l
end

function StraightLink.join(): number
	local roads = workspace.Riviera.Roads
	local road = roads["West Switchbacks"]
	local before = #road:GetChildren()
	local function edgeLine(ax: number, az: number, adz: number, bx: number, bz: number, bdz: number)
		local n = math.ceil((bx - ax) / 4)
		local px, pz = ax, az
		for i = 1, n do
			local x, z = curve(ax, az, adz, bx, bz, bdz, i / n)
			local ya, yb = surface(px, pz), surface(x, z)
			if ya and yb then
				local a, b = Vector3.new(px, ya + 0.1, pz), Vector3.new(x, yb + 0.1, z)
				box("Line", Vector3.new(0.6, 0.04, (b - a).Magnitude + 0.3), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
			end
			px, pz = x, z
		end
	end
	-- (the Mountain Road's own edge lines start at these ends)
	edgeLine(CUT_EAST, zAt(CUT_EAST) - (HALF - 1.5), 0.0078, 11160.7, -203.98, 0.081)
	edgeLine(CUT_EAST, zAt(CUT_EAST) + (HALF - 1.5), 0.0078, 11168.5, -141.49, 0.086)
	-- the middle: two more dashes, up to the Mountain Road's first
	local function mid(x: number): number
		return -174.2 + 1.45 * (x - 11125) / 40.1
	end
	for _, x in { 11133, 11148 } do
		local a = Vector3.new(x, (surface(x, mid(x)) :: number) + 0.1, mid(x))
		local b = Vector3.new(x + 7, (surface(x + 7, mid(x + 7)) :: number) + 0.1, mid(x + 7))
		box("Line", Vector3.new(0.5, 0.04, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
	end
	-- the south shoulder across the old mouth (the north side has one). Near the Mountain Road the road edge stands
	-- higher than that road's own shoulder (the mouth was level), so this stays flush with the road, then comes down onto it
	local EDGE = { { 11134, -142.5 }, { 11150, -142.4 }, { 11165, -140.9 }, { 11180, -139.6 }, { 11192, -138.6 } }
	local function edgeZ(x: number): number
		for i = 1, #EDGE - 1 do
			local a, b = EDGE[i], EDGE[i + 1]
			if x <= b[1] then
				return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
			end
		end
		return EDGE[#EDGE][2]
	end
	local own = {}
	for _, p in roads["Mountain Road"]:GetChildren() do
		if p.Name == "Shoulder" and p.Position.Z > -160 and p.Position.Z < -100 and p.Position.X > 11150 and p.Position.X < 11215 then
			table.insert(own, { p.Position.X, p.Position.Y + 3 })
		end
	end
	table.sort(own, function(a, b)
		return a[1] < b[1]
	end)
	local function top(x: number): number
		local y = (surface(x, edgeZ(x) - 0.8) or surface(x, edgeZ(x) - 2)) :: number
		local t = y - 0.1
		for i = 1, #own - 1 do
			local a, b = own[i], own[i + 1]
			if x >= a[1] and x <= b[1] then
				t = math.max(t, a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) + 0.08)
			end
		end
		return t
	end
	local x = CUT_EAST
	while x < 11190 do
		local nx = math.min(x + 6, 11190)
		local a = Vector3.new(x, top(x) - 3, edgeZ(x) + 5)
		local b = Vector3.new(nx, top(nx) - 3, edgeZ(nx) + 5)
		box("Shoulder", Vector3.new(10.4, 6, (b - a).Magnitude + 0.2), CFrame.lookAt((a + b) / 2, b), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete, true, road)
		x = nx
	end
	return #road:GetChildren() - before
end

-- 55 studs apart, turn about (the road's own lamps run 60-70), on the back of the pavement, facing the road
function StraightLink.lamps(y0: number, y1: number): number
	local dressing = workspace.Riviera.Dressing
	local src
	for _, c in dressing:GetChildren() do
		if c.Name == "StreetLamp" and math.abs(c:GetPivot().X - 10913.4) < 1 and math.abs(c:GetPivot().Z + 140.3) < 1 then
			src = c
			break
		end
	end
	local base = src:GetPivot()
	local foot = base:PointToObjectSpace(src.Foot.Position)
	local boxCF, size = src:GetBoundingBox()
	local drop = base.Y - (boxCF.Y - size.Y / 2)
	local n = 0
	for _, l in { { 10965, -1 }, { 11020, 1 }, { 11075, -1 }, { 11130, 1 } } do
		local x, side = l[1], l[2]
		local c = src:Clone()
		local at = CFrame.new(x, roadY(x, y0, y1) + PAVE_UP + drop - 0.1, zAt(x) + side * (HALF + 8))
		c:PivotTo(at * CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -side)) * CFrame.new(-foot.X, 0, -foot.Z))
		c:SetAttribute("StraightLink", true)
		c.Parent = dressing
		n += 1
	end
	return n
end

-- the stone planter by the old road: its bottom middle set down at a place, its long side along a direction
local function setPlanter(m: Model, at: Vector3, along: Vector3, up: Vector3)
	local brick, centre, n, bottom = nil, Vector3.zero, 0, math.huge
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Part" then
			centre += p.Position
			n += 1
			bottom = math.min(bottom, p.Position.Y - p.Size.Y / 2)
			if p.Size.X > 9 and p.Material == Enum.Material.Brick then
				brick = p
			end
		end
	end
	centre /= n
	local now = CFrame.fromMatrix(Vector3.new(centre.X, bottom, centre.Z), brick.CFrame.RightVector, brick.CFrame.UpVector, -brick.CFrame.LookVector)
	local goal = CFrame.fromMatrix(at, along, up, along:Cross(up).Unit)
	m:PivotTo(goal * now:Inverse() * m:GetPivot())
end

local function planterModel(): Model?
	for _, c in workspace.Riviera.Dressing:GetChildren() do
		if c.Name == "Furniture" then
			for _, e in c:GetChildren() do
				if e.Name == "PlanterStone" then
					local cf = e:GetBoundingBox()
					if e:GetAttribute("StraightLinkMoved") or (math.abs(cf.X - 10940) < 8 and math.abs(cf.Z + 130) < 8) then
						return e
					end
				end
			end
		end
	end
	return nil
end

function StraightLink.planter(y0: number, y1: number)
	local m = planterModel()
	if m then
		local x = 10992
		local along = Vector3.new(1, roadY(x + 1, y0, y1) - roadY(x, y0, y1), (Z1 - Z0) / (X1 - X0)).Unit
		local up = along:Cross(Vector3.yAxis):Cross(along).Unit
		setPlanter(m, Vector3.new(x, roadY(x, y0, y1) + PAVE_UP - 0.05, zAt(x) + HALF + KERB_W - 0.4 + WALK / 2 - 0.05), along, if up.Y < 0 then -up else up)
		m:SetAttribute("StraightLinkMoved", true)
	end
end

function StraightLink.undo()
	local keep = ServerStorage:FindFirstChild("StraightLinkOld")
	local roads = workspace.Riviera.Roads
	for _, d in workspace.Riviera.Dressing:GetChildren() do
		if d:GetAttribute("StraightLink") then
			d:Destroy()
		end
	end
	local m = planterModel()
	if m then
		setPlanter(m, Vector3.new(10939.9, 198.55, -130.2), Vector3.new(0.975, 0, 0.22).Unit, Vector3.yAxis)
		m:SetAttribute("StraightLinkMoved", nil)
	end
	for _, road in { roads["West Switchbacks"], roads["Mountain Road"] } do
		for _, p in road:GetChildren() do
			if p:GetAttribute("StraightLink") then
				p:Destroy()
			end
		end
	end
	if keep then
		for _, f in keep:GetChildren() do
			if f:IsA("Folder") and roads:FindFirstChild(f.Name) then
				for _, p in f:GetChildren() do
					p.Parent = roads[f.Name]
				end
			else
				f.Parent = workspace.Riviera.Dressing
			end
		end
	end
	local copy = ServerStorage:FindFirstChild("StraightLinkGround")
	if copy then
		local c = copy:GetAttribute("Corner")
		workspace.Terrain:PasteRegion(copy, Vector3int16.new(c.X // C, c.Y // C, c.Z // C), true)
	end
end

return StraightLink
