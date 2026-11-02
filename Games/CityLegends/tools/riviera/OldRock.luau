--[[
	Old Rock (Studio, Edit mode): the palace square and the old town on the rock inside the Old Rock
	loop (owner 2026-11-02: "do both" -> the next big job, the Old Rock palace and old town).
	Fictional names only: the Rock Palace (Palais du Rocher), St Aurel Cathedral.

	Inside the loop (free ground about x 12880-13170, z 1060-1400):
	  * the palace square: cobbles at height 52, stone edges, cannons with shot piles, lanterns,
	    benches; a ramp up from the north side of the loop so cars can drive up
	  * the Rock Palace on the west side, facing the square: three floors of ochre with stone window
	    surrounds, battlements, a crenellated corner tower with a flag, the great gate with a
	    balcony over it, two striped sentry boxes
	  * St Aurel Cathedral south of the square: white stone nave, gable front with three portals and a
	    rose window, two bell towers, the dome and the round apse
	  * the old town: narrow 4-5 storey houses (the Buildings kit's Belle Epoque, low) packed along
	    lanes east, south and north of the square, cobbled lanes
	Everything in parent (a Model "OldRock"); small detail tagged LOD. The loop's old inner buildings go.

	OldRock.build(parent, kit, data, rng, buildings, dressing, roads) -> counts
]]

local CollectionService = game:GetService("CollectionService")

local OldRock = {}

local SQUARE_Y = 52
local SQUARE = { 12960, 1220, 13100, 1340 } -- x0, z0, x1, z1
local PALACE = { 12885, 1215, 12957, 1345 }
local CATHEDRAL = { 13008, 1100, 13056, 1205 } -- front (north) at z1
local STONE = Color3.fromRGB(236, 228, 210)
local OCHRE = Color3.fromRGB(222, 180, 122)
local COBBLE = Color3.fromRGB(172, 160, 142)
local BRONZE = Color3.fromRGB(60, 54, 44)

local function inPoly(poly: { Vector2 }, p: Vector2): boolean
	local c = false
	local j = #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if ((a.Y > p.Y) ~= (b.Y > p.Y)) and (p.X < (b.X - a.X) * (p.Y - a.Y) / (b.Y - a.Y) + a.X) then
			c = not c
		end
		j = i
	end
	return c
end

function OldRock.build(parent: Instance, kit, data, rng: Random, buildings: Instance, dressing: Instance, roads: Instance): { [string]: number }
	local part, small, quiet, face, faces, core = kit.part, kit.small, kit.quiet, kit.face, kit.faces, kit.core
	local n = { removed = 0, houses = 0, dressingRemoved = 0 }
	local loop
	local roadPts = {}
	for _, r in data.roads do
		if r.name == "Old Rock" then
			loop = r
		end
		for i, s in r.s do
			if i % 2 == 0 then
				table.insert(roadPts, Vector2.new(s[1], s[3]))
			end
		end
	end
	local poly = {}
	for _, s in loop.s do
		table.insert(poly, Vector2.new(s[1], s[3]))
	end
	local function roadDist(p: Vector2): number
		local best = math.huge
		for _, q in roadPts do
			local d = (q - p).Magnitude
			if d < best then
				best = d
			end
		end
		return best
	end

	-- the loop's old inner buildings go
	for _, m in buildings:GetChildren() do
		local s = m:GetAttribute("Shell")
		if typeof(s) == "CFrame" and inPoly(poly, Vector2.new(s.Position.X, s.Position.Z)) then
			m:Destroy()
			n.removed += 1
		end
	end
	local old = parent:FindFirstChild("OldRock")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "OldRock"
	local det = Instance.new("Model")
	det.Name = "Detail"
	det:SetAttribute("Center", Vector3.new(13030, SQUARE_Y, 1250))
	det:SetAttribute("Range", 700)
	CollectionService:AddTag(det, "LOD")

	local T = workspace.Terrain
	local terrainRay = RaycastParams.new()
	terrainRay.FilterType = Enum.RaycastFilterType.Include
	terrainRay.FilterDescendantsInstances = { T }
	local function groundAt(x: number, z: number): number
		local hit = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -500, 0), terrainRay)
		return if hit then hit.Position.Y else 30
	end
	local function rect(r, y0: number, y1: number, mat: Enum.Material, grow: number?)
		local g = grow or 0
		local cx, cz = (r[1] + r[3]) / 2, (r[2] + r[4]) / 2
		T:FillBlock(CFrame.new(cx, (y0 + y1) / 2, cz), Vector3.new(r[3] - r[1] + 2 * g, y1 - y0, r[4] - r[2] + 2 * g), mat)
	end

	-- terrain: the square, the palace and the cathedral on one flat top; air above it
	for _, r in { SQUARE, PALACE, CATHEDRAL, { 13000, 1200, 13070, 1222 } } do
		rect(r, SQUARE_Y - 14, SQUARE_Y - 0.5, Enum.Material.Limestone, 2)
		rect(r, SQUARE_Y - 0.5, SQUARE_Y + 80, Enum.Material.Air, 2)
	end

	-- the square: cobbles, a stone edge, a low parapet where the rock drops
	local sx, sz = (SQUARE[1] + SQUARE[3]) / 2, (SQUARE[2] + SQUARE[4]) / 2
	local sw, sd = SQUARE[3] - SQUARE[1], SQUARE[4] - SQUARE[2]
	local floor = part({ Name = "Square", Size = Vector3.new(sw + 18, 2, sd + 4), CFrame = CFrame.new(sx - 9, SQUARE_Y - 1, sz), Material = Enum.Material.Pavement, MaterialVariant = "RivCobble", Color = COBBLE, CastShadow = false }, root)
	local _ = floor
	part({ Name = "Parvis", Size = Vector3.new(60, 2, 24), CFrame = CFrame.new((CATHEDRAL[1] + CATHEDRAL[3]) / 2, SQUARE_Y - 1, CATHEDRAL[4] + 8), Material = Enum.Material.Pavement, MaterialVariant = "RivCobble", Color = COBBLE, CastShadow = false }, root)
	-- the ramp up from the loop's north side
	do
		local x = 13032
		local hit = workspace:Raycast(Vector3.new(x, 300, 1467), Vector3.new(0, -400, 0), (function()
			local p = RaycastParams.new()
			p.FilterType = Enum.RaycastFilterType.Include
			p.FilterDescendantsInstances = { roads }
			return p
		end)())
		local roadY = if hit then hit.Position.Y else 44
		local a = Vector3.new(x, roadY + 0.02, 1437)
		local b = Vector3.new(x, SQUARE_Y, SQUARE[4] - 1)
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -1, 0)
		T:FillBlock(CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, 20, 0), Vector3.new(34, 40, len), Enum.Material.Air)
		T:FillBlock(CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, -6, 0), Vector3.new(30, 10, len), Enum.Material.Limestone)
		part({ Name = "Ramp", Size = Vector3.new(28, 2, len + 2), CFrame = cf, Material = Enum.Material.Pavement, MaterialVariant = "RivCobble", Color = COBBLE, CastShadow = false }, root)
		for _, side in { -1, 1 } do
			part({ Name = "RampWall", Size = Vector3.new(1.6, 3, len), CFrame = cf * CFrame.new(side * 14.8, 2, 0), Material = Enum.Material.Limestone, Color = STONE }, root)
		end
		-- street furniture in the way goes
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Include
		op.FilterDescendantsInstances = { dressing }
		for _, p in workspace:GetPartBoundsInBox(cf * CFrame.new(0, 6, 0), Vector3.new(32, 16, len + 4), op) do
			local m = p
			while m.Parent and m.Parent ~= dressing and not (m.Parent:IsA("Folder") or m.Parent:IsA("Model") and m.Parent.Parent == dressing) do
				m = m.Parent
			end
			if m.Parent then
				m:Destroy()
				n.dressingRemoved += 1
			end
		end
	end

	---------------------------------------------------------------------
	-- the Rock Palace: west side of the square, facing east
	---------------------------------------------------------------------
	do
		local m = Instance.new("Model")
		m.Name = "RockPalace"
		local W = PALACE[4] - PALACE[2]
		local D = PALACE[3] - PALACE[1]
		local front = Vector3.new(PALACE[3], SQUARE_Y, (PALACE[2] + PALACE[4]) / 2)
		local cf = CFrame.lookAt(front, front + Vector3.new(1, 0, 0))
		local H = 40
		local low = math.min(groundAt(PALACE[1] + 2, PALACE[2] + 2), groundAt(PALACE[1] + 2, PALACE[4] - 2)) - SQUARE_Y
		local bottom = math.min(-2, low - 2)
		core(m, cf, W, D, bottom, H, OCHRE)
		local rows = {}
		for i = math.floor(-bottom / 12), 1, -1 do
			table.insert(rows, { -i * 12 + 3, -i * 12 + 9.5 })
		end
		table.insert(rows, { 3, 11.5 })
		table.insert(rows, { 16, 25 })
		table.insert(rows, { 29, 36 })
		for i, fc in faces(cf, W, D) do
			local g = if i == 1 then 0 elseif i == 2 then low else low * 0.6
			face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = math.max(2, math.floor(fc.width / 9)), ww = 4.2, rows = rows, gf = 14, share = 0.5 }, OCHRE, Enum.Material.Plaster, m, det)
		end
		-- stone window surrounds on the front, a cornice, battlements
		local cols = math.floor(W / 9)
		local step = W / cols
		for _, r in { { 16, 25 }, { 29, 36 } } do
			for c = 1, cols do
				local x = -W / 2 + (c - 0.5) * step
				small(part({ Name = "Surround", Size = Vector3.new(5.6, r[2] - r[1] + 1.4, 0.5), CFrame = cf * CFrame.new(x, (r[1] + r[2]) / 2 + 0.3, -0.05), Material = Enum.Material.Limestone, Color = STONE, Transparency = 0 }, det))
				small(part({ Name = "Pediment", Size = Vector3.new(6.4, 0.8, 1), CFrame = cf * CFrame.new(x, r[2] + 1.4, -0.2), Material = Enum.Material.Limestone, Color = STONE }, det))
			end
		end
		-- (the surrounds sit on the skin: the opening shows through as a slightly deeper frame)
		for _, d in det:GetChildren() do
			if d.Name == "Surround" then
				d.Size = Vector3.new(d.Size.X, d.Size.Y, 0.3)
				d.Transparency = 0
				-- a frame, not a slab: four thin bars instead
				local cfd = d.CFrame
				local w, h = d.Size.X, d.Size.Y
				for _, b in { { 0, h / 2 - 0.35, w, 0.7 }, { 0, -h / 2 + 0.35, w, 0.7 }, { -w / 2 + 0.35, 0, 0.7, h }, { w / 2 - 0.35, 0, 0.7, h } } do
					small(part({ Name = "Frame", Size = Vector3.new(b[3], b[4], 0.4), CFrame = cfd * CFrame.new(b[1], b[2], 0), Material = Enum.Material.Limestone, Color = STONE }, det))
				end
				d:Destroy()
			end
		end
		part({ Name = "Cornice", Size = Vector3.new(W + 2, 1.6, D + 2), CFrame = cf * CFrame.new(0, H + 0.8, D / 2), Material = Enum.Material.Limestone, Color = STONE }, m)
		part({ Name = "Roof", Size = Vector3.new(W - 4, 1, D - 4), CFrame = cf * CFrame.new(0, H + 2, D / 2), Material = Enum.Material.ClayRoofTiles, Color = kit.TILE }, m)
		for k = 0, math.floor(W / 4.5) do
			local x = -W / 2 + 1 + k * 4.5
			if x < W / 2 then
				small(part({ Name = "Merlon", Size = Vector3.new(2.4, 3, 1.4), CFrame = cf * CFrame.new(x, H + 3.1, 0.2), Material = Enum.Material.Limestone, Color = STONE }, det))
			end
		end
		quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.4, 2.2, kit.R + 0.4), CFrame = cf * CFrame.new(0, 1.1, kit.R / 2 - 0.2), Material = Enum.Material.Limestone, Color = Color3.fromRGB(200, 188, 166) }, m))
		-- the great gate: stone frame, round arch, dark doors, a balcony with balusters over it
		local gate = cf * CFrame.new(0, 0, 0)
		part({ Name = "GateFrame", Size = Vector3.new(16, 18, 1.6), CFrame = gate * CFrame.new(0, 9, -0.4), Material = Enum.Material.Limestone, Color = STONE }, m)
		part({ Name = "GateDoor", Size = Vector3.new(9, 11, 1.8), CFrame = gate * CFrame.new(0, 5.5, -0.5), Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 46, 32) }, m)
		part({ Name = "GateArch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 9, 9), CFrame = gate * CFrame.new(0, 11, -0.5) * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 46, 32) }, m)
		part({ Name = "Arms", Size = Vector3.new(5, 5, 0.6), CFrame = gate * CFrame.new(0, 16.2, -1.4), Material = Enum.Material.Marble, Color = Color3.fromRGB(240, 236, 226) }, m)
		small(part({ Name = "Balcony", Size = Vector3.new(20, 0.8, 4), CFrame = gate * CFrame.new(0, 18.4, -2), Material = Enum.Material.Limestone, Color = STONE }, det))
		small(part({ Name = "BalconyRail", Size = Vector3.new(20, 0.5, 0.8), CFrame = gate * CFrame.new(0, 21.6, -3.6), Material = Enum.Material.Limestone, Color = STONE }, det))
		for k = -9, 9, 1.5 do
			small(part({ Name = "Baluster", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 0.6, 0.6), CFrame = gate * CFrame.new(k, 20.1, -3.6) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Limestone, Color = STONE }, det))
		end
		-- the corner tower (south-east corner, on the square) with battlements and the flag
		local tcf = cf * CFrame.new(-W / 2 + 9, 0, 9)
		local TH = H + 22
		part({ Name = "Tower", Size = Vector3.new(19, TH - bottom, 19), CFrame = tcf * CFrame.new(0, (TH + bottom) / 2, 0), Material = Enum.Material.Limestone, Color = Color3.fromRGB(222, 206, 172) }, m)
		for k = 1, 4 do
			local rot = tcf * CFrame.Angles(0, (k - 1) * math.pi / 2, 0)
			for j = -2, 2 do
				small(part({ Name = "Merlon", Size = Vector3.new(2.6, 3.2, 1.6), CFrame = rot * CFrame.new(j * 4, TH + 1.6, -9.6), Material = Enum.Material.Limestone, Color = STONE }, det))
			end
			for _, y in { H - 8, H + 8 } do
				small(part({ Name = "Slit", Size = Vector3.new(1.4, 5, 0.3), CFrame = rot * CFrame.new(0, y, -9.55), Material = Enum.Material.SmoothPlastic, Color = kit.CORE }, det))
			end
		end
		part({ Name = "Flagpole", Size = Vector3.new(0.5, 16, 0.5), CFrame = tcf * CFrame.new(0, TH + 8, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(220, 220, 214) }, m)
		part({ Name = "FlagRed", Size = Vector3.new(0.15, 3, 9), CFrame = tcf * CFrame.new(0, TH + 14.2, 4.8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(206, 30, 40), CastShadow = false }, m)
		part({ Name = "FlagWhite", Size = Vector3.new(0.15, 3, 9), CFrame = tcf * CFrame.new(0, TH + 11.2, 4.8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(244, 244, 240), CastShadow = false }, m)
		-- two sentry boxes, red and white stripes
		for _, side in { -1, 1 } do
			local b = cf * CFrame.new(side * 12, 0, -5)
			for k = 0, 5 do
				small(part({ Name = "SentryStripe", Size = Vector3.new(0.7, 8, 4), CFrame = b * CFrame.new(-1.75 + k * 0.7, 4, 0), Material = Enum.Material.Wood, Color = if k % 2 == 0 then Color3.fromRGB(196, 32, 40) else Color3.fromRGB(244, 240, 232) }, det)).CanCollide = true
			end
			small(part({ Class = "WedgePart", Name = "SentryRoof", Size = Vector3.new(4.6, 1.6, 2.4), CFrame = b * CFrame.new(0, 8.8, -1.2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(196, 32, 40) }, det))
			small(part({ Class = "WedgePart", Name = "SentryRoof", Size = Vector3.new(4.6, 1.6, 2.4), CFrame = b * CFrame.new(0, 8.8, 1.2), Material = Enum.Material.Wood, Color = Color3.fromRGB(196, 32, 40) }, det))
		end
		m:SetAttribute("Shell", cf * CFrame.new(0, (H + bottom) / 2, D / 2))
		m:SetAttribute("ShellSize", Vector3.new(W, H - bottom, D))
		m:SetAttribute("Wall", OCHRE)
		m:SetAttribute("Recess", kit.R)
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Body" and d.Name ~= "Tower" then
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		m.Parent = root
	end

	-- cannons, shot piles, lanterns, benches on the square
	for k = 0, 3 do
		local p = Vector3.new(SQUARE[3] - 6, SQUARE_Y, SQUARE[2] + 22 + k * 26)
		local cf = CFrame.lookAt(p, p + Vector3.new(1, 0, 0))
		small(part({ Class = "WedgePart", Name = "Carriage", Size = Vector3.new(3.2, 2.4, 6), CFrame = cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(86, 60, 40) }, det)).CanCollide = true
		small(part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 1.6, 1.6), CFrame = cf * CFrame.new(0, 3, -1.5) * CFrame.Angles(0.12, math.pi / 2, 0), Material = Enum.Material.Metal, Color = BRONZE }, det))
		for _, side in { -1, 1 } do
			small(part({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 3, 3), CFrame = cf * CFrame.new(side * 1.9, 1.5, 0.8), Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 48, 32) }, det))
		end
		local pile = cf * CFrame.new(-5, 0, 2)
		local levels = { { 3, 1 }, { 2, 2.05 }, { 1, 3.1 } }
		for _, l in levels do
			for i = 1, l[1] do
				for j = 1, l[1] do
					small(part({ Name = "Shot", Shape = Enum.PartType.Ball, Size = Vector3.new(1.1, 1.1, 1.1), CFrame = pile * CFrame.new((i - (l[1] + 1) / 2) * 1.1, l[2] - 0.45, (j - (l[1] + 1) / 2) * 1.1), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 42) }, det))
				end
			end
		end
	end
	for k, p in { Vector3.new(SQUARE[1] + 8, 0, SQUARE[2] + 6), Vector3.new(SQUARE[1] + 8, 0, SQUARE[4] - 6), Vector3.new(sx, 0, SQUARE[2] + 6), Vector3.new(sx, 0, SQUARE[4] - 6), Vector3.new(SQUARE[3] - 8, 0, SQUARE[2] + 6), Vector3.new(SQUARE[3] - 8, 0, SQUARE[4] - 6) } do
		local base = Vector3.new(p.X, SQUARE_Y, p.Z)
		part({ Name = "LanternPost", Size = Vector3.new(0.7, 13, 0.7), CFrame = CFrame.new(base + Vector3.new(0, 6.5, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 34, 32) }, root)
		local head = part({ Name = "Lantern", Size = Vector3.new(1.8, 2.4, 1.8), CFrame = CFrame.new(base + Vector3.new(0, 14, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 196, 120), CanCollide = false }, root)
		CollectionService:AddTag(head, "LampGlow")
		local l = Instance.new("PointLight")
		l.Range = 34
		l.Brightness = 1.6
		l.Color = Color3.fromRGB(255, 176, 100)
		l.Parent = head
		CollectionService:AddTag(l, "LODLight")
		CollectionService:AddTag(l, "DayOff")
		local _ = k
	end
	for _, z in { SQUARE[2] + 40, SQUARE[4] - 40 } do
		local p = Vector3.new(sx - 10, SQUARE_Y, z)
		local b = (game:GetService("ServerStorage"):FindFirstChild("RivieraAssets") :: any)
		local bench = b and b:FindFirstChild("Props") and b.Props:FindFirstChild("Bench")
		if bench then
			local m = bench:Clone()
			local cf = CFrame.lookAt(p, p + Vector3.new(0, 0, if z < sz then 1 else -1))
			if m:IsA("BasePart") then
				m.Anchored = true
				m.CFrame = cf * CFrame.new(0, m.Size.Y / 2, 0)
			else
				m:PivotTo(cf)
				local box, bs = m:GetBoundingBox()
				m:PivotTo(m:GetPivot() + Vector3.new(p.X - box.Position.X, p.Y - (box.Position.Y - bs.Y / 2), p.Z - box.Position.Z))
			end
			m.Parent = det
		end
	end

	---------------------------------------------------------------------
	-- St Aurel Cathedral: south of the square, front facing the square (north)
	---------------------------------------------------------------------
	do
		local m = Instance.new("Model")
		m.Name = "StAurelCathedral"
		local W = CATHEDRAL[3] - CATHEDRAL[1]
		local D = CATHEDRAL[4] - CATHEDRAL[2]
		local front = Vector3.new((CATHEDRAL[1] + CATHEDRAL[3]) / 2, SQUARE_Y, CATHEDRAL[4])
		local cf = CFrame.lookAt(front, front + Vector3.new(0, 0, 1))
		local H = 36
		local low = groundAt(front.X, CATHEDRAL[2] + 4) - SQUARE_Y
		local bottom = math.min(-2, low - 2)
		local white = Color3.fromRGB(238, 232, 218)
		part({ Name = "Body", Size = Vector3.new(W, H - bottom, D), CFrame = cf * CFrame.new(0, (H + bottom) / 2, D / 2), Material = Enum.Material.Limestone, Color = white }, m)
		-- steps up to the portals
		for k = 1, 3 do
			small(part({ Name = "Step", Size = Vector3.new(W - 6, 0.6 * k, 2.2), CFrame = cf * CFrame.new(0, 0.3 * k, -(4 - k) * 2.2 + 1.1), Material = Enum.Material.Limestone, Color = white }, det)).CanCollide = true
		end
		-- gable front
		for _, side in { -1, 1 } do
			part({ Class = "WedgePart", Name = "Gable", Size = Vector3.new(2, 12, W / 2), CFrame = cf * CFrame.new(side * W / 4, H + 6, 0) * CFrame.Angles(0, side * math.pi / 2, 0), Material = Enum.Material.Limestone, Color = white }, m)
			part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(D, 12, W / 2 + 1), CFrame = cf * CFrame.new(side * (W / 4 + 0.5), H + 6, D / 2) * CFrame.Angles(0, side * math.pi / 2, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(120, 116, 110) }, m)
		end
		-- three portals and the rose window
		for k, x in { -W / 3, 0, W / 3 } do
			local big = k == 2
			local w, h = if big then 7 else 5, if big then 13 else 10
			small(part({ Name = "PortalFrame", Size = Vector3.new(w + 3, h + 3, 1.2), CFrame = cf * CFrame.new(x, (h + 3) / 2 + 1.8, -0.5), Material = Enum.Material.Limestone, Color = Color3.fromRGB(214, 206, 190) }, det))
			part({ Name = "Door", Size = Vector3.new(w, h, 1.4), CFrame = cf * CFrame.new(x, h / 2 + 1.8, -0.7), Material = Enum.Material.Wood, Color = Color3.fromRGB(78, 52, 36) }, m)
			part({ Name = "DoorArch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, w, w), CFrame = cf * CFrame.new(x, h + 1.8, -0.7) * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(78, 52, 36) }, m)
		end
		part({ Name = "RoseFrame", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 13, 13), CFrame = cf * CFrame.new(0, H - 6, -0.3) * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Limestone, Color = Color3.fromRGB(214, 206, 190) }, m)
		local rose = part({ Name = "Rose", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 10, 10), CFrame = cf * CFrame.new(0, H - 6, -0.4) * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(70, 60, 96) }, m)
		CollectionService:AddTag(rose, "Window")
		-- tall windows down the sides
		for _, side in { -1, 1 } do
			for k = 1, 6 do
				local z = k * D / 7
				local w = small(part({ Name = "Glass", Size = Vector3.new(0.3, 12, 3.4), CFrame = cf * CFrame.new(side * (W / 2 + 0.05), 18, z), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(64, 56, 80) }, m))
				CollectionService:AddTag(w, "Window")
			end
		end
		-- bell towers at the front corners
		for _, side in { -1, 1 } do
			local t = cf * CFrame.new(side * (W / 2 - 4), 0, 4)
			part({ Name = "BellTower", Size = Vector3.new(9, H + 16 - bottom, 9), CFrame = t * CFrame.new(0, (H + 16 + bottom) / 2, 0), Material = Enum.Material.Limestone, Color = white }, m)
			small(part({ Name = "Belfry", Size = Vector3.new(9.2, 5, 3), CFrame = t * CFrame.new(0, H + 11, -3.5), Material = Enum.Material.SmoothPlastic, Color = kit.CORE }, det))
			for k = 1, 4 do
				part({ Class = "WedgePart", Name = "Spire", Size = Vector3.new(9, 7, 4.5), CFrame = t * CFrame.Angles(0, (k - 1) * math.pi / 2, 0) * CFrame.new(0, H + 19.5, -2.25) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(110, 106, 100) }, m)
			end
		end
		-- the dome over the crossing and the round apse at the back
		part({ Name = "Drum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 22, 22), CFrame = cf * CFrame.new(0, H + 10, D * 0.62) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Limestone, Color = white }, m)
		part({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(22, 22, 22), CFrame = cf * CFrame.new(0, H + 14, D * 0.62), Material = Enum.Material.Slate, Color = Color3.fromRGB(116, 112, 106) }, m)
		part({ Name = "Lantern", Size = Vector3.new(2, 5, 2), CFrame = cf * CFrame.new(0, H + 27, D * 0.62), Material = Enum.Material.Limestone, Color = white }, m)
		part({ Name = "Apse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(H - 6 - bottom, W * 0.8, W * 0.8), CFrame = cf * CFrame.new(0, (H - 6 + bottom) / 2, D) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Limestone, Color = white }, m)
		m:SetAttribute("Shell", cf * CFrame.new(0, (H + bottom) / 2, D / 2))
		m:SetAttribute("ShellSize", Vector3.new(W, H - bottom, D))
		m:SetAttribute("Wall", white)
		m.Parent = root
	end

	---------------------------------------------------------------------
	-- the old town: narrow houses packed along lanes
	---------------------------------------------------------------------
	local houses = Instance.new("Folder")
	houses.Name = "OldTown"
	houses.Parent = root
	local reserved = {
		{ SQUARE[1] - 20, SQUARE[2] - 6, SQUARE[3] + 10, SQUARE[4] + 4 },
		{ PALACE[1] - 2, PALACE[2] - 2, PALACE[3] + 2, PALACE[4] + 2 },
		{ CATHEDRAL[1] - 8, CATHEDRAL[2] - 30, CATHEDRAL[3] + 8, CATHEDRAL[4] + 20 },
		{ 13012, 1340, 13052, 1440 }, -- the ramp
	}
	local placed = {}
	local function free(cx: number, cz: number, hw: number, hd: number): boolean
		for _, r in reserved do
			if cx + hw > r[1] and cx - hw < r[3] and cz + hd > r[2] and cz - hd < r[4] then
				return false
			end
		end
		for _, b in placed do
			if math.abs(cx - b[1]) < hw + b[3] - 0.5 and math.abs(cz - b[2]) < hd + b[4] - 0.5 then
				return false
			end
		end
		for _, c in { { -hw, -hd }, { hw, -hd }, { -hw, hd }, { hw, hd } } do
			local p = Vector2.new(cx + c[1], cz + c[2])
			if not inPoly(poly, p) or roadDist(p) < 43 then
				return false
			end
		end
		return true
	end
	-- rows: { start, finish, the line the fronts are on, facing } (axis-aligned lanes)
	local rowsDef = {
		-- east of the square, facing west across a lane
		{ axis = "z", from = 1080, to = 1390, line = SQUARE[3] + 14, face = Vector3.new(-1, 0, 0) },
		-- south-west, two rows on an east-west lane at z 1150
		{ axis = "x", from = 12880, to = 13002, line = 1156, face = Vector3.new(0, 0, -1) },
		{ axis = "x", from = 12880, to = 13002, line = 1144, face = Vector3.new(0, 0, 1) },
		-- south, between the cathedral and the east row
		{ axis = "z", from = 1070, to = 1215, line = CATHEDRAL[3] + 16, face = Vector3.new(-1, 0, 0) },
		-- north of the square, facing it
		{ axis = "x", from = 12960, to = 13110, line = SQUARE[4] + 12, face = Vector3.new(0, 0, -1) },
	}
	for _, row in rowsDef do
		local t = row.from
		while t < row.to do
			local W = rng:NextNumber(18, 26)
			local D = rng:NextNumber(20, 28)
			local along = if row.axis == "z" then Vector3.new(0, 0, 1) else Vector3.new(1, 0, 0)
			local centreAlong = t + W / 2
			local front = if row.axis == "z" then Vector3.new(row.line, 0, centreAlong) else Vector3.new(centreAlong, 0, row.line)
			local c = front - row.face * (D / 2)
			local hw = if row.axis == "z" then D / 2 else W / 2
			local hd = if row.axis == "z" then W / 2 else D / 2
			if free(c.X, c.Z, hw, hd) then
				local floorY = math.floor(groundAt(front.X + row.face.X * 3, front.Z + row.face.Z * 3) + 0.5)
				local cf = CFrame.lookAt(Vector3.new(front.X, floorY, front.Z), Vector3.new(front.X, floorY, front.Z) + row.face)
				-- corners in the kit's order: front-left, front-right, back-left, back-right (cf's -X / +X)
				local gnd = {}
				for k, o in { { -W / 2, 0 }, { W / 2, 0 }, { -W / 2, D }, { W / 2, D } } do
					local p = (cf * CFrame.new(o[1], 0, o[2])).Position
					gnd[k] = math.min(0, groundAt(p.X, p.Z) - floorY)
				end
				local m = kit.belle(cf, W, D, gnd, rng, houses, true)
				m.Name = "OldTownHouse"
				workspace.Terrain:FillBlock(cf * CFrame.new(0, 40, D / 2), Vector3.new(W - 1, 79, D - 1), Enum.Material.Air)
				table.insert(placed, { c.X, c.Z, hw, hd })
				n.houses += 1
				t += W + rng:NextNumber(0, 1.5)
			else
				t += 4
			end
		end
		task.wait()
	end
	-- cobbled lanes in front of the old-town rows
	for _, row in rowsDef do
		local len = row.to - row.from
		local mid = (row.from + row.to) / 2
		local c = if row.axis == "z" then Vector3.new(row.line + row.face.X * 6, 0, mid) else Vector3.new(mid, 0, row.line + row.face.Z * 6)
		local y = groundAt(c.X, c.Z)
		local _ = y
		local size = if row.axis == "z" then Vector3.new(12, 1, len) else Vector3.new(len, 1, 12)
		-- (a strip following the ground in 20-stud steps)
		local steps = math.ceil(len / 20)
		for k = 1, steps do
			local tpos = row.from + (k - 0.5) * len / steps
			local p = if row.axis == "z" then Vector3.new(c.X, 0, tpos) else Vector3.new(tpos, 0, c.Z)
			if inPoly(poly, Vector2.new(p.X, p.Z)) and roadDist(Vector2.new(p.X, p.Z)) > 38 then
				local gy = groundAt(p.X, p.Z)
				local sz = if row.axis == "z" then Vector3.new(12, 1, len / steps + 0.5) else Vector3.new(len / steps + 0.5, 1, 12)
				part({ Name = "Lane", Size = sz, CFrame = CFrame.new(p.X, gy + 0.05, p.Z), Material = Enum.Material.Pavement, MaterialVariant = "RivCobble", Color = COBBLE, CastShadow = false }, root)
			end
		end
		local _ = size
	end

	det.Parent = root
	root.Parent = parent
	return n
end

return OldRock
