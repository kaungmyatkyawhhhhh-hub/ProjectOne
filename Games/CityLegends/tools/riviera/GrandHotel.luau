--[[
	GrandHotel (Studio, Edit mode; 2026-11-04): the Grand Hairpin Hotel on its terrace west of the hairpin,
	on the spot the owner marked. A Belle Epoque grand hotel in the owner's photos' style: cream stone,
	six floors of tall windows with iron balconies, slate mansard roofs with dormers, a domed pavilion
	at each corner and a bigger one over the middle, an iron-and-glass marquise over the steps, and a
	pale stone forecourt with marked bays for players' cars, palms and clipped planters. The door takes you up to
	the roof terrace (src/server/HairpinHotel.lua), which looks down on the bend.

	GrandHotel.build(propsFolder) -> Model   (replaces Workspace.Riviera.Dressing.GrandHairpin)
]]

local GrandHotel = {}

local SITE = Vector3.new(10530, 40, 750) -- (the terrace's ground stands at 40)
local CREAM = Color3.fromRGB(248, 232, 198)
local STONE = Color3.fromRGB(238, 220, 186)
local TRIM = Color3.fromRGB(246, 240, 226)
local SLATE = Color3.fromRGB(58, 64, 74)
local COPPER = Color3.fromRGB(96, 150, 128)
local IRON = Color3.fromRGB(26, 30, 30)
local GOLD = Color3.fromRGB(214, 172, 92)
local PANE = Color3.fromRGB(44, 58, 74)
local SHOP = Color3.fromRGB(28, 44, 40)
local PAVE = Color3.fromRGB(206, 194, 172)
local RED = Color3.fromRGB(150, 22, 38)
local LEAF = Color3.fromRGB(44, 88, 44)

local FRONT = -30 -- the front wall (local z)
local BACK = 40
local HALF_W = 100
local GF = 15 -- ground floor height
local FH = 12 -- the floors above
local FLOORS = 5
local TOP = GF + FH * FLOORS
local BAY = 15

-- the drive from the bend's outer edge straight up to the forecourt (EntranceRamp reads the road bed's
-- asphalt terrain as road and stopped short). The road climbs along the bend, so the low end is tilted
-- to its edge (just under it) and the slab untwists to the flat forecourt: two strips of triangles.
function GrandHotel.driveHeight(x: number, z: number): number
	local t = math.clamp((10778 - x) / 80, 0, 1)
	local edge = 36.6 + (750 - z) * 0.0505 - 0.06
	return edge * (1 - t) + 40.2 * t
end

function GrandHotel.drive(model: Model): Model
	local old = model:FindFirstChild("HotelDrive")
	if old then
		old:Destroy()
	end
	local d = Instance.new("Model")
	d.Name = "HotelDrive"
	local function style(p: BasePart, solid: boolean)
		p.Anchored = true
		p.CanCollide = solid
		p.CanQuery = solid
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = d
	end
	-- a triangle a, b, c from two wedges, its top face through the corners
	local function tri(a: Vector3, b: Vector3, c: Vector3)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local th = 2
		-- (the thickness goes below the surface)
		local down = if right.Y > 0 then -right else right
		for k = 1, 2 do
			local w = Instance.new("WedgePart")
			w.Name = "DriveSlab"
			w.Color = Color3.fromRGB(236, 226, 214)
			w.Material = Enum.Material.Pavement
			w.MaterialVariant = "RivPaveHerring"
			if k == 1 then
				w.Size = Vector3.new(th, height, math.abs(ab:Dot(back)))
				w.CFrame = CFrame.fromMatrix((a + b) / 2 + down * th / 2, right, up, back)
			else
				w.Size = Vector3.new(th, height, math.abs(ac:Dot(back)))
				w.CFrame = CFrame.fromMatrix((a + c) / 2 + down * th / 2, -right, up, -back)
			end
			style(w, true)
		end
	end
	local H = GrandHotel.driveHeight
	local z0, z1 = 728, 772
	local xs = { 10778, 10738, 10698 }
	for k = 1, 2 do
		local x0, x1 = xs[k], xs[k + 1]
		local a = Vector3.new(x0, H(x0, z0), z0)
		local b = Vector3.new(x0, H(x0, z1), z1)
		local c = Vector3.new(x1, H(x1, z1), z1)
		local e = Vector3.new(x1, H(x1, z0), z0)
		tri(a, b, c)
		tri(a, c, e)
	end
	-- the stone edges
	for _, z in { z0 - 0.7, z1 + 0.7 } do
		for k = 1, 2 do
			local a = Vector3.new(xs[k], H(xs[k], z) - 0.9, z)
			local b = Vector3.new(xs[k + 1], H(xs[k + 1], z) - 0.9, z)
			local p = Instance.new("Part")
			p.Name = "DriveEdge"
			p.Color = Color3.fromRGB(176, 172, 164)
			p.Material = Enum.Material.Concrete
			p.Size = Vector3.new(1.4, 2.2, (b - a).Magnitude + 0.2)
			p.CFrame = CFrame.lookAt((a + b) / 2, b)
			style(p, false)
		end
	end
	d.Parent = model
	return d
end

function GrandHotel.build(props: Instance): Model
	local riv = workspace.Riviera
	local old = riv.Dressing:FindFirstChild("GrandHairpin")
	if old then
		old:Destroy()
	end
	local group = Instance.new("Folder")
	group.Name = "GrandHairpin"
	local model = Instance.new("Model")
	model.Name = "GrandHairpinHotel"
	local base = CFrame.lookAt(SITE, SITE + Vector3.new(1, 0, 0)) -- -z: the front, towards the hairpin
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local count = 0
	local function part(size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean?, name: string?, parent: Instance?): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = solid == true
		p.CanTouch = false
		p.CanQuery = solid == true
		p.CastShadow = solid == true
		p.Name = name or "Hotel"
		p.Parent = parent or model
		count += 1
		return p
	end
	local function wedge(size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material)
		local w = Instance.new("WedgePart")
		w.Anchored = true
		w.Size = size
		w.CFrame = cf
		w.Color = color
		w.Material = mat
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w.CastShadow = true
		w.CanTouch = false
		w.Parent = model
		count += 1
	end
	local function ball(cf: CFrame, sx: number, sy: number, sz: number, color: Color3, mat: Enum.Material, name: string?)
		local p = part(Vector3.new(sx, sy, sz), cf, color, mat, false, name or "Dome")
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
		p.CastShadow = true
	end
	local function cylinder(r: number, h: number, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean?)
		local p = part(Vector3.new(h, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.pi / 2), color, mat, solid, "Round")
		p.Shape = Enum.PartType.Cylinder
		p.CastShadow = true
		return p
	end

	-------------------------------------------------------------------
	-- the body
	-------------------------------------------------------------------
	local depth = BACK - FRONT
	local midZ = (FRONT + BACK) / 2
	part(Vector3.new(HALF_W * 2, TOP, depth), at(0, TOP / 2, midZ), CREAM, Enum.Material.Plaster, true, "Body")
	-- a rusticated ground floor: a stone plinth and joints
	part(Vector3.new(HALF_W * 2 + 1.2, GF, depth + 1.2), at(0, GF / 2, midZ), STONE, Enum.Material.Limestone, true, "Base")
	for k = 1, 3 do
		part(Vector3.new(HALF_W * 2 + 1.4, 0.3, 0.2), at(0, k * GF / 4, FRONT - 0.7), Color3.fromRGB(190, 176, 150), Enum.Material.Limestone)
	end
	-- string courses and the cornice
	part(Vector3.new(HALF_W * 2 + 2.4, 1.2, depth + 2.4), at(0, GF + 0.6, midZ), TRIM, Enum.Material.Limestone)
	part(Vector3.new(HALF_W * 2 + 2, 0.8, depth + 2), at(0, GF + FH * 3 + 0.4, midZ), TRIM, Enum.Material.Limestone)
	part(Vector3.new(HALF_W * 2 + 5, 1.6, depth + 5), at(0, TOP + 0.8, midZ), TRIM, Enum.Material.Limestone, true)
	part(Vector3.new(HALF_W * 2 + 3, 1, depth + 3), at(0, TOP - 0.5, midZ), STONE, Enum.Material.Limestone)

	-------------------------------------------------------------------
	-- windows: tall, with stone surrounds, shutters, hoods; iron balconies
	-------------------------------------------------------------------
	local function window(cf: CFrame, w: number, h: number, hood: boolean, balcony: boolean)
		-- cf: the middle of the opening on the wall's face, -z out
		part(Vector3.new(w + 1.6, h + 1.6, 0.5), cf * CFrame.new(0, 0, -0.1), TRIM, Enum.Material.Limestone)
		local g = part(Vector3.new(w, h, 0.3), cf * CFrame.new(0, 0, -0.3), PANE, Enum.Material.SmoothPlastic, false, "Window")
		g.Reflectance = 0.18
		part(Vector3.new(0.3, h, 0.2), cf * CFrame.new(0, 0, -0.5), TRIM, Enum.Material.SmoothPlastic)
		part(Vector3.new(w, 0.3, 0.2), cf * CFrame.new(0, h * 0.18, -0.5), TRIM, Enum.Material.SmoothPlastic)
		if hood then
			part(Vector3.new(w + 3, 0.7, 1.6), cf * CFrame.new(0, h / 2 + 1.1, -0.7), STONE, Enum.Material.Limestone)
			part(Vector3.new(1.6, 1.3, 0.8), cf * CFrame.new(0, h / 2 + 0.3, -0.5), GOLD, Enum.Material.Limestone)
		end
		if balcony then
			part(Vector3.new(w + 3.4, 0.5, 3.2), cf * CFrame.new(0, -h / 2 - 0.3, -1.6), STONE, Enum.Material.Limestone)
			part(Vector3.new(w + 3.2, 0.25, 0.25), cf * CFrame.new(0, -h / 2 + 2.6, -3), IRON, Enum.Material.Metal)
			part(Vector3.new(w + 3.2, 2.4, 0.08), cf * CFrame.new(0, -h / 2 + 1.4, -3), IRON, Enum.Material.Metal).Transparency = 0
		else
			part(Vector3.new(w + 2, 0.4, 1), cf * CFrame.new(0, -h / 2 - 0.2, -0.5), STONE, Enum.Material.Limestone)
		end
	end
	local function face(cfOf: (number, number) -> CFrame, x0: number, x1: number, skip: { number }?)
		local n = math.floor((x1 - x0) / BAY)
		for i = 0, n do
			local x = x0 + (x1 - x0) * i / n
			if not (skip and x > skip[1] and x < skip[2]) then
				-- the ground floor: tall arched glass, dark green frames (a winter-garden front)
				local g = cfOf(x, GF / 2 - 0.4)
				part(Vector3.new(11.4, GF - 3.4, 0.5), g * CFrame.new(0, -0.6, -0.1), SHOP, Enum.Material.Metal)
				local gl = part(Vector3.new(10, GF - 4.6, 0.3), g * CFrame.new(0, -0.6, -0.3), PANE, Enum.Material.SmoothPlastic, false, "Window")
				gl.Reflectance = 0.2
				local arch = part(Vector3.new(0.5, 11.4, 5.7), g * CFrame.new(0, (GF - 3.4) / 2 - 0.6, -0.1) * CFrame.Angles(0, math.pi / 2, 0), SHOP, Enum.Material.Metal)
				arch.Shape = Enum.PartType.Cylinder
				for fl = 1, FLOORS do
					local y = GF + (fl - 1) * FH + FH / 2 + 0.2
					window(cfOf(x, y), 7, FH - 4.2, fl <= 3, fl == 1 or fl == 3 or fl == 5)
				end
			end
		end
	end
	local frontCf = function(x: number, y: number): CFrame
		return at(x, y, FRONT - 0.6) * CFrame.Angles(0, 0, 0)
	end
	local backwards = function(x: number, y: number): CFrame
		return at(x, y, BACK + 0.6) * CFrame.Angles(0, math.pi, 0)
	end
	face(frontCf, -82, 82, { -26, 26 })
	face(backwards, -82, 82)
	for _, s in { -1, 1 } do
		face(function(zz: number, y: number): CFrame
			return at(s * (HALF_W + 0.6), y, zz) * CFrame.Angles(0, -s * math.pi / 2, 0)
		end, FRONT + 10, BACK - 10)
		-- tall pilasters either side of the middle
		for _, x in { 28, 76 } do
			part(Vector3.new(2.6, TOP - GF - 1, 1.2), at(s * x, GF + (TOP - GF) / 2, FRONT - 0.6), TRIM, Enum.Material.Limestone)
		end
	end
	task.wait()

	-------------------------------------------------------------------
	-- the slate mansard with dormers
	-------------------------------------------------------------------
	local R0, MH = TOP + 1.6, 15
	local inset = 11
	part(Vector3.new(HALF_W * 2 - inset * 2, MH, depth - inset * 2), at(0, R0 + MH / 2, midZ), SLATE, Enum.Material.Slate, true, "RoofBody")
	-- the sloped faces
	wedge(Vector3.new(HALF_W * 2, MH, inset), at(0, R0 + MH / 2, FRONT + inset / 2), SLATE, Enum.Material.Slate)
	wedge(Vector3.new(HALF_W * 2, MH, inset), at(0, R0 + MH / 2, BACK - inset / 2) * CFrame.Angles(0, math.pi, 0), SLATE, Enum.Material.Slate)
	for _, s in { -1, 1 } do
		wedge(Vector3.new(depth, MH, inset), at(s * (HALF_W - inset / 2), R0 + MH / 2, midZ) * CFrame.Angles(0, s * math.pi / 2, 0), SLATE, Enum.Material.Slate)
	end
	local function dormer(cf: CFrame)
		part(Vector3.new(6.4, 7, 5), cf, CREAM, Enum.Material.Plaster, false, "Dormer").CastShadow = true
		local g = part(Vector3.new(3.8, 4.6, 0.3), cf * CFrame.new(0, -0.4, -2.6), PANE, Enum.Material.SmoothPlastic, false, "Window")
		g.Reflectance = 0.18
		part(Vector3.new(7.4, 0.5, 6), cf * CFrame.new(0, 3.6, -0.2), TRIM, Enum.Material.Limestone)
		wedge(Vector3.new(7.4, 2.4, 3), cf * CFrame.new(0, 5.1, -1.5) * CFrame.Angles(0, math.pi, 0), SLATE, Enum.Material.Slate)
		wedge(Vector3.new(7.4, 2.4, 3), cf * CFrame.new(0, 5.1, 1.5), SLATE, Enum.Material.Slate)
	end
	for x = -75, 75, BAY do
		if math.abs(x) > 24 then
			dormer(at(x, R0 + 5, FRONT + 4))
		end
	end
	-- chimneys
	for _, x in { -60, -20, 20, 60 } do
		part(Vector3.new(7, 7, 3.6), at(x, R0 + MH + 3.5, BACK - 16), CREAM, Enum.Material.Plaster, true, "Chimney")
		part(Vector3.new(7.8, 0.8, 4.4), at(x, R0 + MH + 7.4, BACK - 16), TRIM, Enum.Material.Limestone)
	end
	task.wait()

	-------------------------------------------------------------------
	-- the pavilions: a rotunda at each front corner, the middle under a big dome
	-------------------------------------------------------------------
	local function cupola(x: number, z: number, r: number, h: number, big: boolean)
		cylinder(r, h, at(x, h / 2, z), CREAM, Enum.Material.Plaster, true)
		cylinder(r + 0.5, GF, at(x, GF / 2, z), STONE, Enum.Material.Limestone, true)
		for k = 0, 2 do
			cylinder(r + 0.9, 1, at(x, GF + k * FH * 2 + 0.5, z), TRIM, Enum.Material.Limestone)
		end
		cylinder(r + 2, 1.8, at(x, h + 0.9, z), TRIM, Enum.Material.Limestone)
		-- windows round it
		local nw = if big then 12 else 8
		for k = 1, nw do
			local a = (k - 0.5) * math.pi * 2 / nw
			for fl = 1, FLOORS do
				local y = GF + (fl - 1) * FH + FH / 2
				if y < h - 3 then
					local p = at(x + math.sin(a) * (r + 0.2), y, z - math.cos(a) * (r + 0.2))
					window(CFrame.lookAt(p.Position, p.Position + (p.Position - at(x, y, z).Position)), 4.6, FH - 4.4, false, false)
				end
			end
		end
		-- a drum, the slate dome with gold ribs, a lantern and a finial
		local dy = h + 1.8
		cylinder(r - 1.5, 7, at(x, dy + 3.5, z), TRIM, Enum.Material.Limestone, true)
		local dr = r - 0.6
		ball(at(x, dy + 7, z), dr * 2, dr * 2.5, dr * 2, if big then COPPER else SLATE, Enum.Material.Slate)
		for k = 1, 8 do
			local a = k * math.pi / 4
			part(Vector3.new(0.3, dr * 1.1, 0.5), at(x + math.sin(a) * dr * 0.72, dy + 7 + dr * 0.85, z + math.cos(a) * dr * 0.72) * CFrame.Angles(math.cos(a) * math.rad(36), 0, -math.sin(a) * math.rad(36)), GOLD, Enum.Material.Metal)
		end
		cylinder(2.2, 4, at(x, dy + 7 + dr * 1.25 + 2, z), TRIM, Enum.Material.Limestone)
		ball(at(x, dy + 7 + dr * 1.25 + 5, z), 3.6, 4.4, 3.6, SLATE, Enum.Material.Slate)
		part(Vector3.new(0.4, 5, 0.4), at(x, dy + 7 + dr * 1.25 + 8.6, z), GOLD, Enum.Material.Metal)
	end
	for _, s in { -1, 1 } do
		cupola(s * HALF_W, FRONT + 4, 15, TOP + 2, false)
	end
	task.wait()
	-- the middle: it stands proud of the front, with a pediment, the name, a clock, a great dome
	local CW, CD = 52, 10
	part(Vector3.new(CW, TOP + 5, CD + 2), at(0, (TOP + 5) / 2, FRONT - CD / 2 + 1), CREAM, Enum.Material.Plaster, true, "Pavilion")
	part(Vector3.new(CW + 1, GF, CD + 3), at(0, GF / 2, FRONT - CD / 2 + 1), STONE, Enum.Material.Limestone, true)
	part(Vector3.new(CW + 3, 1.6, CD + 5), at(0, TOP + 5.8, FRONT - CD / 2 + 1), TRIM, Enum.Material.Limestone)
	local zf = FRONT - CD
	for _, x in { -22, -11, 0, 11, 22 } do
		for fl = 1, FLOORS do
			local y = GF + (fl - 1) * FH + FH / 2 + 0.2
			window(at(x, y, zf - 0.6), 6.4, FH - 4.2, true, fl == 1 or fl == 3)
		end
	end
	for _, x in { -16.5, -5.5, 5.5, 16.5 } do
		part(Vector3.new(2.2, TOP - GF - 1, 1.2), at(x, GF + (TOP - GF) / 2, zf - 0.6), TRIM, Enum.Material.Limestone)
	end
	local frieze = part(Vector3.new(44, 4.2, 0.6), at(0, TOP + 2.4, zf - 0.5), TRIM, Enum.Material.Limestone, false, "Name")
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(1100, 105)
	sg.LightInfluence = 0.2
	sg.MaxDistance = 700
	sg.Parent = frieze
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = "GRAND HAIRPIN HOTEL"
	tl.TextColor3 = Color3.fromRGB(150, 108, 44)
	tl.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
	tl.TextScaled = true
	tl.Parent = sg
	-- the pediment
	for _, s in { -1, 1 } do
		wedge(Vector3.new(4, 9, CW / 2 + 2), at(s * (CW / 4 + 1), TOP + 11.1, zf + 1) * CFrame.Angles(0, -s * math.pi / 2, 0), TRIM, Enum.Material.Limestone)
	end
	local clock = cylinder(3.4, 0.5, at(0, TOP + 10.6, zf - 1.1) * CFrame.Angles(math.pi / 2, 0, 0), GOLD, Enum.Material.Metal)
	clock.Name = "Clock"
	cupola(0, FRONT + 26, 24, TOP + 9, true)
	task.wait()

	-------------------------------------------------------------------
	-- the forecourt: pale stone, bays, palms, planters, steps and the marquise
	-------------------------------------------------------------------
	local FZ0, FZ1 = -160, FRONT - CD
	local mid = (FZ0 + FZ1) / 2
	local yard = part(Vector3.new(232, 2, FZ1 - FZ0 + 30), at(0, -0.8, mid + 8), PAVE, Enum.Material.Pavement, true, "Forecourt")
	yard.MaterialVariant = "RivPaveHerring"
	yard.Color = Color3.fromRGB(236, 226, 214)
	yard.CastShadow = false
	-- a dark stone band round it
	-- steps up to the doors
	local SY = 3.2
	for k = 0, 4 do
		part(Vector3.new(46 - k * 2, SY * (5 - k) / 5, 3), at(0, SY * (5 - k) / 10 + 0.2, zf - 3 - (4 - k) * 3 + 2), TRIM, Enum.Material.Marble, true, "Steps")
	end
	part(Vector3.new(10, 0.1, 18), at(0, SY + 0.26, zf - 2), RED, Enum.Material.Fabric)
	-- the doors
	local dy = SY + 6
	local door = part(Vector3.new(18, 12, 0.8), at(0, dy, zf - 0.5), SHOP, Enum.Material.Metal, true, "LobbyDoor")
	door.CanQuery = true
	part(Vector3.new(20.4, 13.6, 0.5), at(0, dy + 0.4, zf - 0.2), GOLD, Enum.Material.Metal)
	for _, x in { -6, 0, 6 } do
		local gl = part(Vector3.new(4.6, 10, 0.2), at(x, dy, zf - 1), Color3.fromRGB(255, 220, 160), Enum.Material.SmoothPlastic)
		gl.Reflectance = 0.1
	end
	-- the marquise: iron-and-glass, tipped to the street, on two iron columns, lanterns under it
	local canopy = at(0, SY + 15.5, zf - 12) * CFrame.Angles(math.rad(-7), 0, 0)
	local top = part(Vector3.new(44, 0.3, 22), canopy, Color3.fromRGB(170, 200, 208), Enum.Material.SmoothPlastic, true, "Marquise")
	top.Reflectance = 0.25
	for k = -5, 5 do
		part(Vector3.new(0.4, 0.5, 22.4), canopy * CFrame.new(k * 4, -0.3, 0), IRON, Enum.Material.Metal)
	end
	for k = -2, 2 do
		part(Vector3.new(44.4, 0.5, 0.4), canopy * CFrame.new(0, -0.3, k * 5), IRON, Enum.Material.Metal)
	end
	part(Vector3.new(44.8, 1.8, 0.6), canopy * CFrame.new(0, -0.8, -11), IRON, Enum.Material.Metal)
	part(Vector3.new(44.8, 0.3, 0.7), canopy * CFrame.new(0, 0.2, -11), GOLD, Enum.Material.Metal)
	for _, x in { -20, 20 } do
		part(Vector3.new(1, SY + 14, 1), at(x, (SY + 14) / 2, zf - 21), IRON, Enum.Material.Metal, true, "Column")
		part(Vector3.new(1.6, 0.8, 1.6), at(x, SY + 13.6, zf - 21), GOLD, Enum.Material.Metal)
	end
	for _, x in { -14, -5, 5, 14 } do
		part(Vector3.new(0.2, 2.6, 0.2), at(x, SY + 12.6, zf - 19), IRON, Enum.Material.Metal)
		local lamp = part(Vector3.new(2, 2.8, 2), at(x, SY + 10.4, zf - 19), Color3.fromRGB(255, 228, 170), Enum.Material.SmoothPlastic, false, "Lantern")
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 208, 150)
		pl.Range = 26
		pl.Brightness = 1.4
		pl.Parent = lamp
	end
	-- planters of red flowers and clipped balls either side of the steps
	for _, s in { -1, 1 } do
		for k = 0, 2 do
			local x = s * (28 + k * 9)
			part(Vector3.new(7, 2.2, 3.6), at(x, 1.1, FRONT - 3), Color3.fromRGB(198, 150, 92), Enum.Material.Wood, true, "Planter")
			part(Vector3.new(6.4, 0.9, 3), at(x, 2.5, FRONT - 3), RED, Enum.Material.Grass)
			ball(at(x, 5, FRONT - 3), 4, 4, 4, LEAF, Enum.Material.Grass, "Topiary")
		end
		-- the row of bays beside the steps
	end
	-- marked bays for players' own cars (owner, 2026-11-04: no parked cars here), side by side along
	-- the front, either side of the steps
	for _, s in { -1, 1 } do
		for k = 0, 4 do
			local x = s * (40 + k * 13)
			local z = FRONT - 18
			part(Vector3.new(0.6, 0.08, 20), at(x + 6.5, 0.26, z), GOLD, Enum.Material.SmoothPlastic)
			part(Vector3.new(0.6, 0.08, 20), at(x - 6.5, 0.26, z), GOLD, Enum.Material.SmoothPlastic)
		end
	end
	-- (owner's photo of the real hairpin hotel: a long row of cars right beside the bend, behind a hedge
	-- and a red-brick pavement; a green glass-and-steel roof along the hotel's front)
	local BRICK = Color3.fromRGB(176, 104, 92)
	for _, s in { -1, 1 } do
		for k = 0, 5 do
			local x = s * (32 + k * 13)
			local z = FZ0 + 16
			part(Vector3.new(0.6, 0.08, 20), at(x + 6.5, 0.26, z), GOLD, Enum.Material.SmoothPlastic)
			part(Vector3.new(0.6, 0.08, 20), at(x - 6.5, 0.26, z), GOLD, Enum.Material.SmoothPlastic)
		end
		-- the kerbed red-brick pavement and the hedge behind the row, on the bend's side
		local x0, x1 = 26, 116
		local cx = s * (x0 + x1) / 2
		part(Vector3.new(x1 - x0, 0.5, 11), at(cx, 0.45, FZ0 + 0.5), BRICK, Enum.Material.Pavement, true, "Pavement").CastShadow = false
		part(Vector3.new(x1 - x0, 0.7, 1.2), at(cx, 0.55, FZ0 + 6.6), Color3.fromRGB(205, 202, 194), Enum.Material.Concrete, true, "Kerb").CastShadow = false
		part(Vector3.new(x1 - x0 - 4, 3.2, 4), at(cx, 2.1, FZ0 + 2), LEAF, Enum.Material.Grass, true, "Hedge")
		-- the glass-and-steel roof
		local rx0, rx1 = 30, 98
		local rc = s * (rx0 + rx1) / 2
		local rz = FRONT - 15
		local glass = part(Vector3.new(rx1 - rx0, 0.3, 30), at(rc, 17, rz) * CFrame.Angles(math.rad(-4), 0, 0), Color3.fromRGB(108, 150, 132), Enum.Material.SmoothPlastic, true, "GlassRoof")
		glass.Reflectance = 0.3
		glass.CastShadow = true
		for k = 0, 8 do
			local x = s * (rx0 + k * (rx1 - rx0) / 8)
			part(Vector3.new(0.5, 0.7, 30.6), at(x, 16.5, rz) * CFrame.Angles(math.rad(-4), 0, 0), Color3.fromRGB(214, 216, 218), Enum.Material.Metal)
		end
		-- a steel lattice along its street edge
		local ez = FRONT - 30
		part(Vector3.new(rx1 - rx0, 0.5, 0.5), at(rc, 16.2, ez), Color3.fromRGB(214, 216, 218), Enum.Material.Metal)
		part(Vector3.new(rx1 - rx0, 0.5, 0.5), at(rc, 13.2, ez), Color3.fromRGB(214, 216, 218), Enum.Material.Metal)
		for k = 0, 11 do
			local x = s * (rx0 + (k + 0.5) * (rx1 - rx0) / 12)
			local tilt = if k % 2 == 0 then 45 else -45
			part(Vector3.new(4.4, 0.35, 0.35), at(x, 14.7, ez) * CFrame.Angles(0, 0, math.rad(tilt)), Color3.fromRGB(214, 216, 218), Enum.Material.Metal)
		end
		for k = 0, 3 do
			local x = s * (rx0 + k * (rx1 - rx0) / 3)
			part(Vector3.new(1, 14, 1), at(x, 7, ez), Color3.fromRGB(214, 216, 218), Enum.Material.Metal, true, "Column")
		end
	end
	-- black-and-gold bollards along the bays' front, palms down both sides and along the street
	local palm = props:FindFirstChild("PalmA")
	local _, psz = (palm :: Model):GetBoundingBox()
	local function addPalm(x: number, z: number, sc: number)
		local m = (palm :: Model):Clone()
		m:ScaleTo(sc)
		m:PivotTo(CFrame.new(at(x, psz.Y * sc / 2 - 0.5, z).Position) * CFrame.Angles(0, (x * 7 + z) % 6.28, 0))
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.Anchored = true
				d.CanTouch = false
			end
		end
		m.Parent = model
	end
	for _, s in { -1, 1 } do
		for _, z in { FRONT - 44, FRONT - 74, FRONT - 104 } do
			addPalm(s * 108, z, 0.95)
		end
		addPalm(s * 34, FZ0 + 4, 0.9)
		addPalm(s * 64, FZ0 + 4, 1)
		addPalm(s * 94, FZ0 + 4, 0.85)
		for k = 0, 5 do
			local x = s * (40 + k * 13)
			local b = cylinder(0.5, 2.6, at(x - s * 6.5, 1.3, FRONT - 30), IRON, Enum.Material.Metal, true)
			b.Name = "Bollard"
			part(Vector3.new(1.3, 0.3, 1.3), at(x - s * 6.5, 2.5, FRONT - 30), GOLD, Enum.Material.Metal)
		end
	end
	task.wait()

	-------------------------------------------------------------------
	-- the roof terrace over the middle wing, looking at the hairpin
	-------------------------------------------------------------------
	local RT = R0 + MH
	local rz0, rz1 = FRONT + inset - 2, BACK - inset + 2
	local deck = part(Vector3.new(HALF_W * 2 - inset * 2 + 4, 0.8, rz1 - rz0), at(0, RT + 0.4, (rz0 + rz1) / 2), Color3.fromRGB(198, 170, 130), Enum.Material.WoodPlanks, true, "Deck")
	deck.CastShadow = false
	local w = HALF_W - inset + 2
	local function rail(a: Vector3, b: Vector3)
		local c = (a + b) / 2
		local r = part(Vector3.new(0.3, 3.6, (b - a).Magnitude), CFrame.lookAt(c, b), Color3.fromRGB(190, 208, 216), Enum.Material.SmoothPlastic, true, "Rail")
		r.Reflectance = 0.2
		r.Transparency = 0.5
		part(Vector3.new(0.5, 0.3, (b - a).Magnitude), CFrame.lookAt(c, b) * CFrame.new(0, 1.9, 0), GOLD, Enum.Material.Metal)
	end
	local y = RT + 0.8 + 1.8
	local A, B, C, D = at(-w, y, rz0).Position, at(w, y, rz0).Position, at(w, y, rz1).Position, at(-w, y, rz1).Position
	rail(A, B)
	rail(B, C)
	rail(C, D)
	rail(D, A)
	local bench, pot = props:FindFirstChild("Bench"), props:FindFirstChild("PlanterPot")
	for _, x in { -60, -30, 30, 60 } do
		if bench then
			local b = (bench :: BasePart):Clone()
			b.Anchored = true
			b.CFrame = at(x, RT + 0.8 + b.Size.Y / 2, rz0 + 7) * CFrame.Angles(0, 0, 0)
			b.Parent = model
		end
	end
	for _, x in { -75, -45, -15, 15, 45, 75 } do
		if pot then
			local m = (pot :: Model):Clone()
			local cf, sz = m:GetBoundingBox()
			local t = at(x, RT + 0.8, rz0 + 3).Position
			m:PivotTo(m:GetPivot() + (t - Vector3.new(cf.X, cf.Y - sz.Y / 2, cf.Z)))
			m.Parent = model
		end
	end
	local kbase = at(0, RT + 0.8, rz1 - 6)
	part(Vector3.new(16, 10, 8), kbase * CFrame.new(0, 5, 0), CREAM, Enum.Material.Plaster, true, "Kiosk")
	part(Vector3.new(18, 0.8, 10), kbase * CFrame.new(0, 10.4, 0), SLATE, Enum.Material.Slate, true)
	local td = part(Vector3.new(9, 8.4, 0.5), kbase * CFrame.new(0, 4.2, -4.2), SHOP, Enum.Material.Metal, true, "TerraceDoor")
	td.CanQuery = true
	local function spot(name: string, cf: CFrame)
		local p = part(Vector3.new(2, 1, 2), cf, IRON, Enum.Material.SmoothPlastic, false, name)
		p.Transparency = 1
		p.CanQuery = false
	end
	spot("StreetSpot", at(0, 4, zf - 14))
	spot("TerraceSpot", at(0, RT + 4.4, rz0 + 12))
	model.Parent = group
	group.Parent = riv.Dressing
	return model, count
end

return GrandHotel
