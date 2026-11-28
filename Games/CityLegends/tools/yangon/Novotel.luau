--[[
	Novotel (2026-11-28, owner: "Novotel Yangon Max is in the wrong position; the real one has an underground car park,
	a lobby and stuff", then "you dont need to build the rooms. just build the swimming pool area and car parking and
	hotel lobby", "also build the basketball court").

	The real Novotel Yangon Max, 459 Pyay Road (OSM way 471327865), on its real outline and facing Pyay Road (east).
	Built as Parts by this file into Workspace.Yangon1to1.Landmarks.NovotelYangonMax (or a staging parent):
	  * massing only for the towers and the front block (no rooms),
	  * the lobby (ground floor of the front block) from the current official photos,
	  * the pool deck and the sports court on the podium roof (the real pool is on the 6th floor),
	  * the car park under the lobby level: the site falls to the west, so it is entered at grade from the north lane
	    and lies below the Pyay Road forecourt,
	  * a lift B1 / L / 6 (tag "MallLift": src/server/MallMovers.server.lua runs it).
	Sources (dated): novotelyangonmax.com gallery (files of 2026-06 and 2026-08), all.accor.com/hotel/9045, the hotel's
	Google Maps owner photo of Jun 2026, Esri satellite. Notes: vault `City Legends/2026-11-28 Novotel Yangon Max -
	real layout.md`.

	Frame: a runs toward Pyay Road (east-north-east), b to the right of that (south-south-east), from the outline's
	south-west corner. All parts are square to that frame. Faces keep >= 0.05 apart or butt.
	Run in Studio Edit:  local N = require(ClaudeTools.Novotel:Clone())  N.build()  /  N.build(game.ServerStorage)  /  N.undo()
]]
local M = {}
local CollectionService = game:GetService("CollectionService")

local NAME = "NovotelYangonMax"
local ORIGIN = Vector3.new(27215.6, 0, 30211.9)
local U = Vector3.new(0.96044, 0, -0.27851)
local V = Vector3.new(0.27851, 0, 0.96044)
local F = CFrame.fromMatrix(ORIGIN, U, Vector3.yAxis, V)

-- levels
local YP = 54.5 -- car park floor (the lot plate's top)
local YL = 63.5 -- lobby floor
local YC = 85.5 -- lobby ceiling (double height)
local Y6 = 117.5 -- podium roof: pool deck, court
local YT = 190 -- towers' roof

local STONE = Color3.fromRGB(150, 146, 140)
local STONE_D = Color3.fromRGB(118, 114, 108)
local WHITE = Color3.fromRGB(236, 236, 230)
local TAUPE = Color3.fromRGB(146, 124, 108)
local GLASS = Color3.fromRGB(96, 124, 140)
local DARKGLASS = Color3.fromRGB(44, 56, 64)
local CHAR = Color3.fromRGB(46, 46, 50)
local CONC = Color3.fromRGB(158, 158, 156)
local CONC_D = Color3.fromRGB(110, 110, 112)
local MARBLE = Color3.fromRGB(226, 214, 190)
local TIMBER = Color3.fromRGB(198, 150, 92)
local TIMBER_D = Color3.fromRGB(128, 86, 50)
local BRONZE = Color3.fromRGB(150, 112, 64)
local BLUE = Color3.fromRGB(26, 70, 170)
local TILE = Color3.fromRGB(70, 190, 200)
local WATER = Color3.fromRGB(60, 190, 215)
local TERRA = Color3.fromRGB(160, 84, 60)
local DECK = Color3.fromRGB(120, 84, 62)
local COURT_R = Color3.fromRGB(176, 78, 62)
local COURT_G = Color3.fromRGB(56, 128, 72)
local LINE_W = Color3.fromRGB(240, 240, 236)
local LINE_Y = Color3.fromRGB(232, 200, 50)
local WARM = Color3.fromRGB(255, 226, 170)

local count = 0
local function raw(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = size.X * size.Y * size.Z > 4000
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p.Parent = parent
	count += 1
	return p
end
-- a box from a0..a1, y0..y1, b0..b1 in the hotel's frame
local function box(parent: Instance, name: string, a0: number, a1: number, y0: number, y1: number, b0: number, b1: number, color: Color3, mat: Enum.Material?, props: { [string]: any }?): Part
	return raw(parent, name, Vector3.new(a1 - a0, y1 - y0, b1 - b0), F * CFrame.new((a0 + a1) / 2, (y0 + y1) / 2, (b0 + b1) / 2), color, mat, props)
end
-- an upright cylinder
local function cyl(parent: Instance, name: string, a: number, b: number, y0: number, y1: number, d: number, color: Color3, mat: Enum.Material?, props: { [string]: any }?): Part
	local o = props or {}
	o.Shape = Enum.PartType.Cylinder
	return raw(parent, name, Vector3.new(y1 - y0, d, d), F * CFrame.new(a, (y0 + y1) / 2, b) * CFrame.Angles(0, 0, math.pi / 2), color, mat, o)
end
local NOHIT = { CanCollide = false, CanQuery = false, CanTouch = false }
local function deco(t: { [string]: any }?): { [string]: any }
	local o = table.clone(NOHIT)
	for k, v in t or {} do
		o[k] = v
	end
	return o
end
local function text(p: BasePart, face: Enum.NormalId, str: string, color: Color3, pps: number?, font: Enum.Font?, light: number?)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pps or 20
	g.LightInfluence = light or 0.4
	g.MaxDistance = 600
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextColor3 = color
	t.Font = font or Enum.Font.GothamMedium
	t.TextScaled = true
	t.Text = str
	t.Parent = g
end
local function lamp(p: BasePart, range: number, bright: number, color: Color3?)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Shadows = range, bright, false
	l.Color = color or WARM
	l.Parent = p
end
local function folder(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

---------------------------------------------------------------- massing (no rooms)
local function windows(parent: Instance, a0: number, a1: number, b0: number, b1: number, y0: number, y1: number, step: number)
	-- vertical dark window strips on the four faces of a block, 0.15 proud of the wall
	local function strip(aa0, aa1, bb0, bb1)
		box(parent, "Windows", aa0, aa1, y0, y1, bb0, bb1, DARKGLASS, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.12 }))
	end
	local a = a0 + step / 2
	while a + 3 < a1 do
		strip(a, a + 4, b0 - 0.15, b0 + 0.05)
		strip(a, a + 4, b1 - 0.05, b1 + 0.15)
		a += step
	end
	local b = b0 + step / 2
	while b + 3 < b1 do
		strip(a0 - 0.15, a0 + 0.05, b, b + 4)
		strip(a1 - 0.05, a1 + 0.15, b, b + 4)
		b += step
	end
end
local function tower(parent: Instance, name: string, a0: number, a1: number, b0: number, b1: number, y0: number, y1: number, bandColor: Color3)
	local t = folder(parent, name)
	box(t, "Tower", a0, a1, y0, y1, b0, b1, WHITE, Enum.Material.Concrete)
	windows(t, a0, a1, b0, b1, y0 + 12, y1 - 8, 11)
	-- taupe floor bands every other floor and a taupe cap
	for y = y0 + 30, y1 - 20, 30 do
		box(t, "Band", a0 - 0.2, a1 + 0.2, y, y + 1.2, b0 - 0.2, b1 + 0.2, bandColor, Enum.Material.Concrete, deco())
	end
	box(t, "Cap", a0 - 0.4, a1 + 0.4, y1, y1 + 2.5, b0 - 0.4, b1 + 0.4, bandColor, Enum.Material.Concrete, deco())
end

local function massing(root: Instance)
	local m = folder(root, "Massing")
	-- towers (12 levels over the lobby level); the western two stand on the low ground
	tower(m, "TowerW1", 6, 62, -222, -150, 48, YT, TAUPE)
	tower(m, "TowerW2", 6, 62, -140, -76, 48, YT, TAUPE)
	box(m, "TowerLink", 20, 50, 48, 160, -150, -140, TAUPE, Enum.Material.Concrete)
	tower(m, "TowerN", 70, 212, -222, -176, YL, YT, TAUPE)
	-- the middle block (its roof carries the small pool), the ballroom block (white roof), the court block
	box(m, "MidBlock", 75, 215, YL, Y6, -168, -72, WHITE, Enum.Material.Concrete)
	windows(m, 75, 215, -168, -72, YL + 8, Y6 - 6, 12)
	box(m, "LinkBlock", 215, 232, YL, Y6, -112, -72, STONE, Enum.Material.Concrete)
	box(m, "SmallPoolDeck", 146, 182, Y6, Y6 + 0.3, -156, -120, DECK, Enum.Material.WoodPlanks, deco())
	box(m, "SmallPool", 150, 178, Y6 + 0.3, Y6 + 0.5, -152, -124, WATER, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.2 }))
	box(m, "Ballroom", 64, 128, YL, 100, -72, -17, WHITE, Enum.Material.Concrete)
	box(m, "CourtBlock", 128, 232, YL, Y6 - 0.3, -72, -17, STONE, Enum.Material.Concrete)
	-- the pool podium (south-east); its east end stands on the ground by the drive
	box(m, "PoolPodium", 232, 265, YL, Y6 - 3, -112, -17, STONE, Enum.Material.Concrete)
	box(m, "PoolPodiumEast", 265, 348, 54, Y6 - 3, -112, -17, STONE, Enum.Material.Concrete)
	box(m, "PodiumGlass", 348, 348.3, YL + 2, YL + 16, -104, -24, GLASS, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.25 }))
	for y = YL + 26, Y6 - 12, 12 do
		box(m, "PodiumWindows", 348, 348.2, y, y + 5, -104, -24, DARKGLASS, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.15 }))
	end
	-- the south strip past the lot plate stands on the ground (retaining side of the car park)
	box(m, "SouthSkirt", 62, 348, 53, Y6 - 3, -17, -6, STONE_D, Enum.Material.Concrete)
	-- front block above the lobby, notched round the lift shaft (217.4..225, -125.6..-118)
	box(m, "FrontBlock", 227, 300, YC, Y6, -222, -112, STONE, Enum.Material.Concrete)
	box(m, "FrontBlockW", 215, 227, YC, Y6, -222, -125.6, STONE, Enum.Material.Concrete)
	box(m, "FrontBlockS", 215, 227, YC, Y6, -118, -112, STONE, Enum.Material.Concrete)
	box(m, "FrontBlockLift", 225, 227, YC, Y6, -125.6, -118, STONE, Enum.Material.Concrete)
	box(m, "FrontRoofFill", 215, 217.4, YC, Y6, -125.6, -118, STONE, Enum.Material.Concrete)
	-- its glass wall to Pyay Road (three floors of glass with bronze fins), the parapet with the name
	box(m, "FrontGlass", 300, 300.3, YC + 3, Y6 - 6.5, -216, -128, GLASS, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.3 }))
	for b = -216, -128, 8 do
		box(m, "Fin", 300.3, 301.1, YC + 3, Y6 - 6.5, b - 0.3, b + 0.3, BRONZE, Enum.Material.Metal, deco())
	end
	for y = YC + 13, Y6 - 12, 10 do
		box(m, "Spandrel", 300.3, 300.5, y, y + 0.8, -216, -128, CHAR, Enum.Material.Metal, deco())
	end
	local name = box(m, "NameBand", 300.5, 300.8, Y6 - 6, Y6 + 3.4, -216, -128, STONE, Enum.Material.Concrete, deco())
	text(name, Enum.NormalId.Right, "NOVOTEL", WHITE, 12, Enum.Font.GothamMedium, 0.1)
	box(m, "Parapet", 214.5, 300.5, Y6, Y6 + 3.4, -222.5, -222, STONE, Enum.Material.Concrete)
	box(m, "ParapetW", 214.5, 215, Y6, Y6 + 3.4, -222, -112, STONE, Enum.Material.Concrete)
	box(m, "ParapetE", 300, 300.5, Y6, Y6 + 3.4, -222, -112, STONE, Enum.Material.Concrete)
	-- north skirt of the front block east of the lot plate, and the lobby's floor there
	box(m, "FrontSkirtN", 265, 300, 54, YL - 1, -222, -221, STONE_D, Enum.Material.Concrete)
	box(m, "FrontSkirtE", 299, 300, 54, YL - 1, -221, -112, STONE_D, Enum.Material.Concrete)
end

---------------------------------------------------------------- car park (under the lobby level)
local SA0, SA1, SB0, SB1 = 217.4, 225, -125.6, -118 -- the lift shaft's outer rectangle

local function carPark(root: Instance)
	local c = folder(root, "CarPark")
	-- ceiling slab = the lobby level's floor, in four pieces round the lift shaft
	local function slab(a0, a1, b0, b1)
		box(c, "Slab", a0, a1, YL - 1, YL, b0, b1, CONC, Enum.Material.Concrete)
	end
	slab(64, SA0, -222, -17)
	slab(SA1, 265, -222, -17)
	slab(SA0, SA1, -222, SB0)
	slab(SA0, SA1, SB1, -17)
	box(c, "SlabEast", 265, 300, YL - 1, YL, -222, -112, CONC, Enum.Material.Concrete)
	-- walls; the gate (a 150..190) is in the north wall, on the north lane
	box(c, "WallN", 64, 150, YP, YL - 1, -222, -221, CONC, Enum.Material.Concrete)
	box(c, "WallN", 190, 265, YP, YL - 1, -222, -221, CONC, Enum.Material.Concrete)
	box(c, "WallW", 64, 65, YP, YL - 1, -221, -18, CONC, Enum.Material.Concrete)
	box(c, "WallE", 264, 265, YP, YL - 1, -221, -18, CONC, Enum.Material.Concrete)
	box(c, "WallS", 64, 265, YP, YL - 1, -18, -17, CONC, Enum.Material.Concrete)
	local head = box(c, "GateHead", 150, 190, YL - 3, YL - 1, -222, -221, CHAR, Enum.Material.Metal)
	text(head, Enum.NormalId.Front, "P   CAR PARK", WHITE, 16, Enum.Font.GothamBold, 0.2)
	box(c, "HeightBar", 152, 188, YL - 3.6, YL - 3.2, -222.6, -222.2, LINE_Y, Enum.Material.Metal, deco())
	-- apron from the lane up to the plate (the lane is about 1 lower)
	box(c, "Apron", 148, 192, YP - 4.6, YP - 0.02, -225.9, -223.6, CONC_D, Enum.Material.Asphalt)
	-- columns on a 40 grid
	for a = 90, 250, 40 do
		for b = -200, -40, 40 do
			if not (a > 150 and a < 190) and not (a > 210 and a < 232 and b > -130 and b < -110) then
				box(c, "Column", a - 0.9, a + 0.9, YP, YL - 1, b - 0.9, b + 0.9, CONC, Enum.Material.Concrete)
				box(c, "ColumnBand", a - 0.95, a + 0.95, YP, YP + 3, b - 0.95, b + 0.95, LINE_Y, Enum.Material.SmoothPlastic, deco())
			end
		end
	end
	-- bays 9 x 18 on both sides of two cross aisles (b -192..-168 and -76..-52); the spine aisle is a 158..182
	local lines = folder(c, "Lines")
	for _, row in { { -210, -192 }, { -168, -150 }, { -94, -76 }, { -52, -34 } } do
		for _, span in { { 70, 151 }, { 189, 261 } } do
			local a = span[1]
			while a <= span[2] do
				box(lines, "BayLine", a - 0.2, a + 0.2, YP, YP + 0.06, row[1], row[2], LINE_W, Enum.Material.SmoothPlastic, deco())
				a += 9
			end
		end
	end
	for _, b in { -180, -64 } do
		for a = 80, 250, 34 do
			if not (a > 150 and a < 190) then
				box(lines, "Arrow", a - 3, a + 3, YP, YP + 0.06, b - 0.3, b + 0.3, LINE_W, Enum.Material.SmoothPlastic, deco())
			end
		end
	end
	-- strip lights
	for _, b in { -180, -122, -64 } do
		for a = 100, 240, 70 do
			local l = box(c, "Light", a - 6, a + 6, YL - 1.25, YL - 1.05, b - 0.4, b + 0.4, Color3.fromRGB(240, 246, 255), Enum.Material.Neon, deco())
			lamp(l, 46, 1.1, Color3.fromRGB(236, 242, 255))
		end
	end
	local sg = box(c, "LiftSign", SA1 + 0.3, SA1 + 0.4, YP + 6.9, YP + 7.9, SB0 - 2, SB1 + 2, BLUE, Enum.Material.SmoothPlastic, deco())
	text(sg, Enum.NormalId.Right, "LIFT   LOBBY · POOL", WHITE, 30, Enum.Font.GothamBold, 0.2)
end

---------------------------------------------------------------- lobby (from the official photos)
local function lobby(root: Instance)
	local l = folder(root, "Lobby")
	-- floor finish (cream marble) on the slab, timber in the lounge half
	box(l, "Marble", 216, 299, YL, YL + 0.12, -221, -160, MARBLE, Enum.Material.SmoothPlastic, deco({ CanCollide = true, CanQuery = true, Reflectance = 0.12 }))
	box(l, "LoungeFloor", 227, 299, YL, YL + 0.12, -160, -113, TIMBER_D, Enum.Material.WoodPlanks, deco({ CanCollide = true, CanQuery = true }))
	box(l, "LoungeFloor", 216, 227, YL, YL + 0.12, -160, -127, TIMBER_D, Enum.Material.WoodPlanks, deco({ CanCollide = true, CanQuery = true }))
	-- walls: north, south, west (behind reception); east = glass with the entrance (b -200..-184)
	box(l, "WallN", 215, 300, YL, YC, -222, -221, MARBLE, Enum.Material.SmoothPlastic)
	box(l, "WallS", 227, 300, YL, YC, -113, -112, MARBLE, Enum.Material.SmoothPlastic)
	box(l, "WallS", 215, 227, YL, YC, -116, -112, MARBLE, Enum.Material.SmoothPlastic)
	box(l, "WallW", 215, 216, YL, YC, -221, SB0, MARBLE, Enum.Material.SmoothPlastic)
	box(l, "WallW", 215, 217.4, YL, YC, SB1, -116, MARBLE, Enum.Material.SmoothPlastic)
	local glass = { Transparency = 0.72, Reflectance = 0.2 }
	box(l, "GlassE", 299.5, 299.8, YL, YC, -221, -200, GLASS, Enum.Material.SmoothPlastic, glass)
	box(l, "GlassE", 299.5, 299.8, YL, YC, -184, -113, GLASS, Enum.Material.SmoothPlastic, glass)
	box(l, "GlassHead", 299.5, 299.8, YL + 10, YC, -200, -184, GLASS, Enum.Material.SmoothPlastic, glass)
	for _, b in { -221, -200, -184, -160, -136, -113 } do
		box(l, "Mullion", 299.4, 299.9, YL, YC, b - 0.25, b + 0.25, WHITE, Enum.Material.Metal, deco())
	end
	box(l, "DoorHead", 299.3, 300, YL + 9.6, YL + 10.4, -200, -184, WHITE, Enum.Material.Metal, deco())
	box(l, "Mat", 290, 299, YL + 0.12, YL + 0.2, -198, -186, Color3.fromRGB(92, 64, 44), Enum.Material.Fabric, deco())
	-- the security scanner by the door, and the two big dark pots
	box(l, "Scanner", 292, 296, YL + 0.12, YL + 4.4, -182, -176, CHAR, Enum.Material.Metal)
	for _, b in { -203, -181 } do
		cyl(l, "Pot", 296.5, b, YL + 0.12, YL + 3.6, 3.4, Color3.fromRGB(40, 26, 20), Enum.Material.SmoothPlastic, { Reflectance = 0.25 })
		cyl(l, "PotPlant", 296.5, b, YL + 3.6, YL + 9, 0.5, Color3.fromRGB(70, 110, 50), Enum.Material.Grass, deco())
		raw(l, "PotLeaves", Vector3.new(7, 4, 7), F * CFrame.new(296.5, YL + 10, b), Color3.fromRGB(62, 120, 52), Enum.Material.Grass, deco({ Shape = Enum.PartType.Ball }))
	end
	-- timber ceiling soffit with the dark ring over the reception
	box(l, "Ceiling", 227, 299.4, YC - 0.5, YC, -221, -113, Color3.fromRGB(214, 180, 128), Enum.Material.Wood, deco())
	box(l, "Ceiling", 216, 227, YC - 0.5, YC, -221, -127, Color3.fromRGB(214, 180, 128), Enum.Material.Wood, deco())
	cyl(l, "CeilingRing", 240, -192, YC - 1.3, YC - 0.5, 44, CHAR, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.3 }))
	cyl(l, "CeilingDisc", 240, -192, YC - 1.7, YC - 1.3, 39, Color3.fromRGB(230, 196, 140), Enum.Material.Wood, deco())
	-- the reception wall: timber panels with tall dark glossy panels (sparkle lights) between
	for i = 0, 6 do
		local b0 = -219 + i * 8.2
		if i % 2 == 0 then
			box(l, "TimberPanel", 216, 216.6, YL, YC - 1.8, b0, b0 + 8, TIMBER, Enum.Material.Wood, deco())
		else
			local p = box(l, "DarkPanel", 216, 216.5, YL, YC - 1.8, b0, b0 + 8, Color3.fromRGB(24, 24, 28), Enum.Material.SmoothPlastic, deco({ Reflectance = 0.35 }))
			for k = 1, 7 do
				local yy = YL + 2 + k * 2.3
				local bb = b0 + 1.2 + ((k * 37) % 56) / 10
				box(p, "Sparkle", 216.5, 216.56, yy, yy + 0.22, bb, bb + 0.22, Color3.fromRGB(255, 250, 235), Enum.Material.Neon, deco())
			end
		end
	end
	-- three desk pods: white tops, timber fronts
	for _, b in { -205, -192, -179 } do
		box(l, "Desk", 224, 228, YL + 0.12, YL + 3.6, b - 5, b + 5, WHITE, Enum.Material.SmoothPlastic)
		box(l, "DeskFront", 228, 228.3, YL + 0.12, YL + 2.6, b - 4.6, b + 4.6, TIMBER, Enum.Material.Wood, deco())
		box(l, "DeskTop", 223.8, 228.5, YL + 3.6, YL + 3.8, b - 5.2, b + 5.2, WHITE, Enum.Material.SmoothPlastic, deco())
	end
	local sign = box(l, "DeskSign", 216.6, 216.7, YL + 9, YL + 12, -197, -187, WHITE, Enum.Material.SmoothPlastic, deco())
	text(sign, Enum.NormalId.Right, "NOVOTEL", Color3.fromRGB(20, 40, 110), 30, Enum.Font.GothamMedium, 0.2)
	-- the lounge in front of the desks: round dark rug, round black table, blue-grey tub chairs
	cyl(l, "Rug", 258, -192, YL + 0.12, YL + 0.2, 22, Color3.fromRGB(52, 52, 60), Enum.Material.Fabric, deco())
	cyl(l, "Table", 258, -192, YL + 0.2, YL + 1.5, 7, Color3.fromRGB(18, 18, 20), Enum.Material.SmoothPlastic, { Reflectance = 0.4 })
	for i = 0, 3 do
		local ang = math.rad(45 + i * 90)
		local a, b = 258 + math.cos(ang) * 8, -192 + math.sin(ang) * 8
		cyl(l, "Chair", a, b, YL + 0.2, YL + 1.5, 3.6, Color3.fromRGB(96, 128, 172), Enum.Material.Fabric)
		raw(l, "ChairBack", Vector3.new(0.6, 2.4, 3.4), F * CFrame.new(a + math.cos(ang) * 1.7, YL + 2.6, b + math.sin(ang) * 1.7) * CFrame.Angles(0, -ang, 0), Color3.fromRGB(96, 128, 172), Enum.Material.Fabric, deco())
	end
	-- branch pendants (warm globes) over the desks
	for _, b in { -208, -192, -176 } do
		local g = raw(l, "Pendant", Vector3.new(0.9, 0.9, 0.9), F * CFrame.new(232, YL + 12, b), WARM, Enum.Material.Neon, deco({ Shape = Enum.PartType.Ball }))
		lamp(g, 26, 0.9)
		box(l, "PendantRod", 231.95, 232.05, YL + 12.4, YC - 1.7, b - 0.05, b + 0.05, CHAR, Enum.Material.Metal, deco())
	end
	-- the lobby lounge (south half, timber floor): wire armchairs with turquoise cushions, purple rugs, sparkle balls,
	-- the deli counter on the south wall
	for i, pos in { { 250, -146 }, { 270, -146 }, { 250, -128 }, { 270, -128 } } do
		box(l, "PurpleRug", pos[1] - 8, pos[1] + 8, YL + 0.12, YL + 0.18, pos[2] - 6, pos[2] + 6, Color3.fromRGB(96, 60, 150), Enum.Material.Fabric, deco())
		cyl(l, "LowTable", pos[1], pos[2], YL + 0.18, YL + 1.4, 3.2, Color3.fromRGB(110, 40, 36), Enum.Material.Wood)
		for _, s in { -1, 1 } do
			box(l, "WireChair", pos[1] + s * 4.4 - 1.5, pos[1] + s * 4.4 + 1.5, YL + 0.18, YL + 2.6, pos[2] - 1.6, pos[2] + 1.6, Color3.fromRGB(40, 40, 44), Enum.Material.DiamondPlate)
			box(l, "Cushion", pos[1] + s * 4.4 - 1.2, pos[1] + s * 4.4 + 1.2, YL + 1.3, YL + 1.8, pos[2] - 1.3, pos[2] + 1.3, Color3.fromRGB(70, 196, 206), Enum.Material.Fabric, deco())
		end
		local ball = raw(l, "SparkleBall", Vector3.new(3.2, 3.2, 3.2), F * CFrame.new(pos[1], YC - 5 - (i % 2) * 2.5, pos[2]), Color3.fromRGB(255, 252, 240), Enum.Material.Neon, deco({ Shape = Enum.PartType.Ball, Transparency = 0.15 }))
		lamp(ball, 30, 0.8)
	end
	box(l, "Deli", 262, 290, YL + 0.12, YL + 3.6, -119, -114.5, Color3.fromRGB(60, 44, 36), Enum.Material.Wood)
	box(l, "DeliGlass", 264, 288, YL + 3.6, YL + 5.6, -118.6, -115, Color3.fromRGB(190, 220, 230), Enum.Material.SmoothPlastic, { Transparency = 0.6 })
	local menu = box(l, "DeliBoard", 266, 286, YL + 8, YL + 12, -113.2, -113.05, CHAR, Enum.Material.SmoothPlastic, deco())
	text(menu, Enum.NormalId.Front, "GOURMET BAR", WHITE, 24, Enum.Font.GothamMedium, 0.3)
	for b = -216, -120, 24 do
		local d = box(l, "Downlight", 280, 281, YC - 0.56, YC - 0.5, b, b + 1, WARM, Enum.Material.Neon, deco())
		lamp(d, 36, 0.7)
	end
end

---------------------------------------------------------------- forecourt and porte-cochere
local function forecourt(root: Instance)
	local f = folder(root, "Forecourt")
	-- paved court from the doors down to the lane. The lane climbs south (about 60.3 at b -176, 61.8 at b -108), so
	-- the main court is one plane falling east (P) and rising south (Q); the door piece only falls east.
	local P, Q = -0.076, 0.025
	local PAVE = Color3.fromRGB(150, 150, 146)
	local function plane(name: string, a0: number, a1: number, b0: number, b1: number, q: number, bRef: number)
		local ac, bc = (a0 + a1) / 2, (b0 + b1) / 2
		local top = YL + 0.1 + P * (ac - 300) + q * (bc - bRef)
		local xv = F:VectorToWorldSpace(Vector3.new(1, P, 0).Unit)
		local zv = F:VectorToWorldSpace(Vector3.new(0, q, 1).Unit)
		local yv = zv:Cross(xv).Unit
		local pos = F * Vector3.new(ac, top, bc) - yv * 0.5
		raw(f, name, Vector3.new(a1 - a0 + 0.1, 1, b1 - b0), CFrame.fromMatrix(pos, xv, yv), PAVE, Enum.Material.Cobblestone)
	end
	plane("Paving", 300, 349, -180, -108, Q, -180)
	plane("PavingN", 300, 331, -214, -180, 0, -180)
	plane("PavingNW", 300, 322, -222, -214, 0, -180)
	box(f, "Fill", 300, 349, 54, 58.6, -180, -108, STONE_D, Enum.Material.Concrete)
	box(f, "FillN", 300, 331, 54, 60.1, -214, -180, STONE_D, Enum.Material.Concrete)
	box(f, "FillNW", 300, 322, 54, 60.8, -222, -214, STONE_D, Enum.Material.Concrete)
	box(f, "KerbN", 330.4, 331, 60.1, YL - 1.6, -214, -180, STONE, Enum.Material.Concrete)
	box(f, "KerbN3", 322, 330.4, 60.1, YL - 1.3, -214, -213.4, STONE, Enum.Material.Concrete)
	box(f, "KerbN4", 321.4, 322, 60.8, YL - 1.0, -222, -214, STONE, Enum.Material.Concrete)
	box(f, "KerbN2", 300, 321.4, 60.8, YL + 0.7, -222, -221.4, STONE, Enum.Material.Concrete)
	-- hedge planter along the lounge's glass (the court rises there)
	box(f, "Planter", 300.9, 305, YL - 1, YL + 2.6, -176, -112, STONE, Enum.Material.Concrete)
	box(f, "Hedge", 301.2, 304.7, YL + 2.6, YL + 4.2, -175.6, -112.4, Color3.fromRGB(58, 112, 50), Enum.Material.Grass, deco())
	-- the canopy: a white soffit with a round front on tall bronze columns, the name over the doors
	box(f, "Canopy", 300, 312, YL + 13, YL + 14.2, -212, -172, WHITE, Enum.Material.SmoothPlastic)
	cyl(f, "CanopyRound", 312, -192, YL + 13, YL + 14.2, 40, WHITE, Enum.Material.SmoothPlastic)
	cyl(f, "CanopyGlow", 312, -192, YL + 12.9, YL + 13, 30, WARM, Enum.Material.Neon, deco({ Transparency = 0.3 }))
	local glow = box(f, "CanopyLight", 311, 313, YL + 12.5, YL + 12.9, -193, -191, WARM, Enum.Material.Neon, deco())
	lamp(glow, 50, 1.2)
	for _, p in { { 311, -210.5 }, { 327, -203 }, { 327, -181 }, { 311, -173.5 } } do
		cyl(f, "Column", p[1], p[2], YL - 3.2, YL + 13, 2.2, BRONZE, Enum.Material.Metal, { Reflectance = 0.15 })
	end
	local band = box(f, "EntranceSign", 300.4, 300.7, YL + 14.6, YL + 17.6, -204, -180, STONE, Enum.Material.Concrete, deco())
	text(band, Enum.NormalId.Right, "NOVOTEL", WHITE, 20, Enum.Font.GothamMedium, 0.1)
	-- a fountain basin on the court, flagpoles along its south side
	local b0 = -128
	box(f, "Basin", 310, 328, YL - 2.2, YL + 1.4, b0 - 7, b0 + 7, CHAR, Enum.Material.Slate)
	box(f, "BasinWater", 311, 327, YL + 1.4, YL + 1.5, b0 - 6, b0 + 6, WATER, Enum.Material.SmoothPlastic, deco({ Reflectance = 0.3 }))
	for a = 313, 325, 4 do
		local j = box(f, "Jet", a - 0.2, a + 0.2, YL + 1.5, YL + 3.8, b0 - 0.2, b0 + 0.2, Color3.fromRGB(230, 244, 255), Enum.Material.Neon, deco({ Transparency = 0.45 }))
		lamp(j, 10, 0.5, Color3.fromRGB(230, 240, 255))
	end
	for a = 320, 345, 5 do
		cyl(f, "Flagpole", a, -110, YL - 3, YL + 24, 0.4, Color3.fromRGB(200, 200, 204), Enum.Material.Metal, deco({ CanCollide = true }))
	end
end

---------------------------------------------------------------- pool deck (6th floor) and the roof walk from the lift
local function poolDeck(root: Instance)
	local d = folder(root, "PoolDeck")
	local y0, y1 = Y6 - 3, Y6
	-- deck round the pool (main a 244..340, b -78..-52; shallow wing a 244..290, b -52..-34)
	box(d, "DeckN", 232, 348, y0, y1, -112, -78, DECK, Enum.Material.WoodPlanks)
	box(d, "DeckS", 232, 348, y0, y1, -34, -17, TERRA, Enum.Material.Brick)
	box(d, "DeckS2", 232, 348, y0, y1, -17, -6, TERRA, Enum.Material.Brick)
	box(d, "DeckW", 232, 244, y0, y1, -78, -34, DECK, Enum.Material.WoodPlanks)
	box(d, "DeckE", 340, 348, y0, y1, -78, -52, TERRA, Enum.Material.Brick)
	box(d, "DeckSE", 290, 348, y0, y1, -52, -34, TERRA, Enum.Material.Brick)
	box(d, "PoolFloor", 244, 340, y0, y0 + 0.2, -78, -52, TILE, Enum.Material.SmoothPlastic)
	box(d, "PoolFloor", 244, 290, y0, y0 + 0.2, -52, -34, TILE, Enum.Material.SmoothPlastic)
	local water = { Transparency = 0.45, Reflectance = 0.25, CanCollide = false, CanTouch = false }
	box(d, "Water", 244, 340, y0 + 0.2, y1 - 0.4, -78, -52, WATER, Enum.Material.Glass, water)
	box(d, "Water", 244, 290, y0 + 0.2, y1 - 0.4, -51.95, -34, WATER, Enum.Material.Glass, water)
	for _, e in { { 244, 340, -78.3, -78 }, { 290, 340, -52, -51.7 }, { 244, 290, -34, -33.7 } } do
		box(d, "Coping", e[1], e[2], y1, y1 + 0.12, e[3], e[4], WHITE, Enum.Material.SmoothPlastic, deco())
	end
	-- glass rail round the deck's open edges, hedge planters along the north edge
	local rail = { Transparency = 0.7, Reflectance = 0.15 }
	box(d, "Rail", 347.7, 348, y1, y1 + 3.8, -112, -6, GLASS, Enum.Material.SmoothPlastic, rail)
	box(d, "Rail", 232, 347.7, y1, y1 + 3.8, -6.3, -6, GLASS, Enum.Material.SmoothPlastic, rail)
	box(d, "Rail", 300.5, 347.7, y1, y1 + 3.8, -112, -111.7, GLASS, Enum.Material.SmoothPlastic, rail)
	for a = 306, 340, 17 do
		box(d, "Planter", a, a + 12, y1, y1 + 1.6, -110.5, -107.5, Color3.fromRGB(96, 100, 104), Enum.Material.Concrete)
		box(d, "Hedge", a + 0.3, a + 11.7, y1 + 1.6, y1 + 3.4, -110.2, -107.8, Color3.fromRGB(58, 112, 50), Enum.Material.Grass, deco())
	end
	-- loungers (blue on black frames) and blue umbrellas on the timber side
	for a = 250, 334, 12 do
		box(d, "Lounger", a, a + 2.6, y1 + 0.5, y1 + 0.9, -90, -83, CHAR, Enum.Material.Fabric)
		box(d, "LoungerPad", a + 0.15, a + 2.45, y1 + 0.9, y1 + 1.2, -89.8, -83.2, BLUE, Enum.Material.Fabric, deco())
		raw(d, "LoungerBack", Vector3.new(2.3, 0.3, 2.6), F * CFrame.new(a + 1.3, y1 + 1.9, -90.6) * CFrame.Angles(math.rad(-50), 0, 0), BLUE, Enum.Material.Fabric, deco())
	end
	for a = 256, 328, 24 do
		cyl(d, "UmbrellaPole", a + 7, -93, y1, y1 + 8.4, 0.3, Color3.fromRGB(200, 200, 204), Enum.Material.Metal, deco({ CanCollide = true }))
		cyl(d, "Umbrella", a + 7, -93, y1 + 8.4, y1 + 8.9, 11, BLUE, Enum.Material.Fabric, deco())
	end
	-- two striped cabanas on the terracotta side
	for _, a in { 300, 322 } do
		for _, p in { { 0, 0 }, { 10, 0 }, { 0, 8 }, { 10, 8 } } do
			box(d, "CabanaPost", a + p[1] - 0.2, a + p[1] + 0.2, y1, y1 + 8, -30 + p[2] - 0.2, -30 + p[2] + 0.2, CHAR, Enum.Material.Metal)
		end
		box(d, "CabanaTop", a - 0.6, a + 10.6, y1 + 8, y1 + 8.4, -30.6, -21.4, BLUE, Enum.Material.Fabric, deco())
		for k = 0, 3 do
			box(d, "CabanaStripe", a + 0.4 + k * 2.8, a + 1.8 + k * 2.8, y1 + 8.4, y1 + 8.46, -30.6, -21.4, WHITE, Enum.Material.Fabric, deco())
		end
		box(d, "CabanaBed", a + 1, a + 9, y1, y1 + 1.4, -29, -23, BLUE, Enum.Material.Fabric)
	end
	-- the pool bar pavilion at the west end (white, gold lattice screen)
	box(d, "BarBack", 232, 233, y1, y1 + 9, -74, -40, WHITE, Enum.Material.SmoothPlastic)
	box(d, "BarRoof", 232, 243, y1 + 9, y1 + 9.6, -75, -39, WHITE, Enum.Material.SmoothPlastic)
	box(d, "BarCounter", 239, 241, y1, y1 + 3.6, -70, -44, WHITE, Enum.Material.SmoothPlastic)
	box(d, "BarLattice", 233, 233.2, y1 + 1, y1 + 8, -66, -48, Color3.fromRGB(196, 160, 70), Enum.Material.DiamondPlate, deco())
	for _, b in { -74.5, -39.5 } do
		box(d, "BarPost", 242.2, 242.8, y1, y1 + 9, b - 0.3, b + 0.3, WHITE, Enum.Material.SmoothPlastic)
	end
	-- the walk from the lift over the front block's roof to the deck
	box(d, "RoofWalk", 226, 240, Y6, Y6 + 0.15, -126, -112, DECK, Enum.Material.WoodPlanks, deco({ CanCollide = true, CanQuery = true }))
	local sg = box(d, "PoolSign", 232.2, 232.4, y1 + 10, y1 + 12.4, -68, -46, WHITE, Enum.Material.SmoothPlastic, deco())
	text(sg, Enum.NormalId.Right, "POOL BAR", BLUE, 24, Enum.Font.GothamMedium, 0.3)
end

---------------------------------------------------------------- the court (tennis + basketball lines, as on the photo)
local function court(root: Instance)
	local c = folder(root, "Court")
	local y = Y6
	box(c, "Surround", 128, 232, y - 0.3, y, -72, -17, COURT_R, Enum.Material.SmoothPlastic)
	box(c, "CourtDeckS", 128, 232, y - 3, y, -17, -6, COURT_R, Enum.Material.SmoothPlastic)
	-- tennis court 71.3 x 32.9 (doubles), centred a 180, b -40
	local ca, cb = 180, -40
	local L, W, S = 35.65, 16.45, 12.35 -- half length, half width (doubles), singles half width
	box(c, "Green", ca - L - 9, ca + L + 9, y, y + 0.04, cb - W - 5, cb + W + 5, COURT_G, Enum.Material.SmoothPlastic, deco())
	local function line(a0, a1, b0, b1, color)
		box(c, "Line", a0, a1, y + 0.04, y + 0.08, b0, b1, color or LINE_W, Enum.Material.SmoothPlastic, deco())
	end
	local t = 0.25
	line(ca - L, ca + L, cb - W - t, cb - W + t) line(ca - L, ca + L, cb + W - t, cb + W + t)
	line(ca - L, ca + L, cb - S - t, cb - S + t) line(ca - L, ca + L, cb + S - t, cb + S + t)
	line(ca - L - t, ca - L + t, cb - W, cb + W) line(ca + L - t, ca + L + t, cb - W, cb + W)
	line(ca - 19.2 - t, ca - 19.2 + t, cb - S, cb + S) line(ca + 19.2 - t, ca + 19.2 + t, cb - S, cb + S)
	line(ca - 19.2, ca + 19.2, cb - t, cb + t)
	-- the net
	for _, b in { cb - W - 2.7, cb + W + 2.7 } do
		cyl(c, "NetPost", ca, b, y, y + 3.4, 0.4, CHAR, Enum.Material.Metal)
	end
	box(c, "Net", ca - 0.05, ca + 0.05, y + 0.5, y + 3.1, cb - W - 2.7, cb + W + 2.7, Color3.fromRGB(30, 30, 32), Enum.Material.DiamondPlate, { Transparency = 0.45 })
	box(c, "NetTape", ca - 0.1, ca + 0.1, y + 3.1, y + 3.3, cb - W - 2.7, cb + W + 2.7, WHITE, Enum.Material.Fabric, deco())
	-- basketball lines in yellow (boundary and a three-point arc at each end) and a hoop at each end
	local BL, BW = 42, 21.5
	line(ca - BL, ca + BL, cb - BW - t, cb - BW + t, LINE_Y) line(ca - BL, ca + BL, cb + BW - t, cb + BW + t, LINE_Y)
	line(ca - BL - t, ca - BL + t, cb - BW, cb + BW, LINE_Y) line(ca + BL - t, ca + BL + t, cb - BW, cb + BW, LINE_Y)
	for _, s in { -1, 1 } do
		local hoopA = ca + s * (BL - 4.7)
		local R = 20.2
		for k = -8, 7 do
			local t0, t1 = math.rad(k * 10), math.rad((k + 1) * 10)
			local a0, b0 = hoopA - s * math.cos(t0) * R, cb + math.sin(t0) * R
			local a1, b1 = hoopA - s * math.cos(t1) * R, cb + math.sin(t1) * R
			local mid = F * CFrame.new((a0 + a1) / 2, y + 0.06, (b0 + b1) / 2)
			local dir = F:VectorToWorldSpace(Vector3.new(a1 - a0, 0, b1 - b0))
			raw(c, "Arc", Vector3.new(0.5, 0.04, dir.Magnitude + 0.1), CFrame.lookAt(mid.Position, mid.Position + dir), LINE_Y, Enum.Material.SmoothPlastic, deco())
		end
		local poleA = ca + s * (BL + 3)
		cyl(c, "HoopPole", poleA, cb, y, y + 10.5, 0.7, CHAR, Enum.Material.Metal)
		box(c, "HoopArm", math.min(poleA, poleA - s * 5), math.max(poleA, poleA - s * 5), y + 10.2, y + 10.7, cb - 0.25, cb + 0.25, CHAR, Enum.Material.Metal)
		local bbA = poleA - s * 5
		box(c, "Backboard", bbA - 0.12, bbA + 0.12, y + 8.6, y + 12.2, cb - 2.8, cb + 2.8, WHITE, Enum.Material.SmoothPlastic)
		box(c, "BackboardSquare", bbA - s * 0.14 - 0.02, bbA - s * 0.14 + 0.02, y + 9.2, y + 10.6, cb - 0.9, cb + 0.9, Color3.fromRGB(200, 50, 40), Enum.Material.SmoothPlastic, deco())
		for k = 0, 9 do
			local t0 = math.rad(k * 36)
			local ra, rb = bbA - s * 1.6 + math.cos(t0) * 0.75, cb + math.sin(t0) * 0.75
			raw(c, "Rim", Vector3.new(0.12, 0.12, 0.5), F * CFrame.new(ra, y + 9.15, rb) * CFrame.Angles(0, -t0, 0), Color3.fromRGB(230, 110, 40), Enum.Material.Metal, deco())
		end
	end
	-- white kerb and the tall dark-green mesh fence
	local fenceC = Color3.fromRGB(34, 60, 44)
	for _, e in { { 128, 232, -72, -71.6 }, { 128, 232, -6.4, -6 }, { 128, 128.4, -71.6, -6.4 }, { 231.6, 232, -71.6, -42 }, { 231.6, 232, -30, -6.4 } } do
		box(c, "Kerb", e[1], e[2], y, y + 0.6, e[3], e[4], WHITE, Enum.Material.Concrete)
		local mesh = { Transparency = 0.5, CastShadow = false }
		if e[2] - e[1] > e[4] - e[3] then
			local bm = (e[3] + e[4]) / 2
			box(c, "Fence", e[1], e[2], y + 0.6, y + 12, bm - 0.05, bm + 0.05, fenceC, Enum.Material.DiamondPlate, mesh)
		else
			local am = (e[1] + e[2]) / 2
			box(c, "Fence", am - 0.05, am + 0.05, y + 0.6, y + 12, e[3], e[4], fenceC, Enum.Material.DiamondPlate, mesh)
		end
	end
end

---------------------------------------------------------------- the lift B1 / L / 6 (MCLift's layout, turned to this frame)
local function lift(root: Instance)
	local T = 0.3
	local OPEN_W, OPEN_H, CAR_W, CAR_H = 3.6, 6.7, 6.8, 7.4
	local STOPS = { { "B1", YP }, { "L", YL }, { "6", Y6 } }
	local TOP = Y6 + 9
	local ca, cb = (SA0 + SA1) / 2, (SB0 + SB1) / 2
	local H = (SA1 - SA0) / 2
	-- lift frame: +z is the door side (toward Pyay Road), x is the doors' slide axis
	local LF = F * CFrame.new(ca, 0, cb) * CFrame.Angles(0, math.pi / 2, 0)
	local function part(parent: Instance, name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3, props: { [string]: any }?): Part
		return raw(parent, name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), LF * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, Enum.Material.SmoothPlastic, props)
	end
	local LW, GREY, STEEL, DARK = Color3.fromRGB(236, 236, 232), Color3.fromRGB(196, 198, 200), Color3.fromRGB(150, 154, 160), Color3.fromRGB(40, 40, 44)
	local Lm = Instance.new("Model")
	Lm.Name = "Lift"
	Lm:SetAttribute("CarHeight", CAR_H)
	Lm:SetAttribute("DoorSlide", OPEN_W / 2 - 0.2)
	Lm:SetAttribute("At", 2)
	local shaft = folder(Lm, "Shaft")
	part(shaft, "WallBack", -H, H, YP, TOP, -H, -H + T, LW)
	part(shaft, "WallL", -H, -H + T, YP, TOP, -H + T, H - T, LW)
	part(shaft, "WallR", H - T, H, YP, TOP, -H + T, H - T, LW)
	part(shaft, "Roof", -H, H, TOP, TOP + 0.4, -H, H, LW)
	local ox0, ox1 = -OPEN_W / 2, OPEN_W / 2
	part(shaft, "Jamb", -H, ox0, YP, TOP, H - T, H, LW)
	part(shaft, "Jamb", ox1, H, YP, TOP, H - T, H, LW)
	local stops = Instance.new("Folder")
	stops.Name = "Stops"
	stops.Parent = Lm
	for i, s in STOPS do
		local yTop = s[2] + OPEN_H
		local yNext = STOPS[i + 1] and STOPS[i + 1][2] or TOP
		part(shaft, "Lintel", ox0, ox1, yTop, yNext, H - T, H, LW)
		local d0, d1 = H + 0.02, H + 0.14
		part(Lm, "DoorL" .. i, ox0, 0, s[2], s[2] + OPEN_H, d0, d1, STEEL, { Reflectance = 0.08 })
		part(Lm, "DoorR" .. i, 0, ox1, s[2], s[2] + OPEN_H, d0, d1, STEEL, { Reflectance = 0.08 })
		local panel = part(Lm, "Call" .. i, ox1 + 0.5, ox1 + 1.1, s[2] + 3.4, s[2] + 4.4, H, H + 0.12, DARK)
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Call lift"
		pr.ObjectText = "Lift " .. s[1]
		pr.HoldDuration = 0
		pr.MaxActivationDistance = 10
		pr.RequiresLineOfSight = false
		pr.Parent = panel
		part(panel, "Light", ox1 + 0.68, ox1 + 0.92, s[2] + 3.78, s[2] + 4.02, H + 0.12, H + 0.16, Color3.fromRGB(255, 214, 120), { Material = Enum.Material.Neon, CanCollide = false })
		local sg = part(Lm, "Sign" .. i, ox0 - 0.4, ox1 + 0.4, s[2] + OPEN_H + 0.3, s[2] + OPEN_H + 1.1, H, H + 0.06, GREY, { CanCollide = false })
		text(sg, Enum.NormalId.Back, "LIFT  B1 · L · 6", Color3.fromRGB(40, 42, 46), 50, Enum.Font.GothamBold, 0.3)
		local stop = Instance.new("Part")
		stop.Name = "Stop" .. i
		stop.Anchored, stop.CanCollide, stop.CanQuery, stop.CanTouch = true, false, false, false
		stop.Transparency = 1
		stop.Size = Vector3.new(1, 0.2, 1)
		stop.CFrame = LF * CFrame.new(0, s[2], 0)
		stop:SetAttribute("Label", s[1])
		stop.Parent = stops
	end
	local car = Instance.new("Model")
	car.Name = "Car"
	car.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local y = STOPS[2][2]
	local c0, c1 = -CAR_W / 2, CAR_W / 2
	local wall = Color3.fromRGB(172, 174, 178)
	local floor = part(car, "Floor", c0, c1, y - 0.4, y, c0, c1, Color3.fromRGB(58, 58, 62), { Material = Enum.Material.Slate })
	part(car, "Roof", c0, c1, y + CAR_H, y + CAR_H + 0.3, c0, c1, LW)
	part(car, "Back", c0, c1, y, y + CAR_H, c0, c0 + 0.2, wall, { Reflectance = 0.05 })
	part(car, "SideL", c0, c0 + 0.2, y, y + CAR_H, c0 + 0.2, c1, wall, { Reflectance = 0.05 })
	part(car, "SideR", c1 - 0.2, c1, y, y + CAR_H, c0 + 0.2, c1, wall, { Reflectance = 0.05 })
	part(car, "Front", c0 + 0.2, ox0, y, y + CAR_H, c1 - 0.2, c1, wall)
	part(car, "Front", ox1, c1 - 0.2, y, y + CAR_H, c1 - 0.2, c1, wall)
	part(car, "FrontHead", ox0, ox1, y + OPEN_H, y + CAR_H, c1 - 0.2, c1, wall)
	local lm = part(car, "Lamp", -1.6, 1.6, y + CAR_H - 0.06, y + CAR_H, -1.6, 1.6, Color3.fromRGB(255, 246, 228), { Material = Enum.Material.Neon, CanCollide = false })
	lamp(lm, 10, 1.2, Color3.fromRGB(255, 246, 228))
	part(car, "CarDoorL", ox0, 0, y, y + OPEN_H, c1 - 0.42, c1 - 0.3, STEEL, { Reflectance = 0.08 })
	part(car, "CarDoorR", 0, ox1, y, y + OPEN_H, c1 - 0.42, c1 - 0.3, STEEL, { Reflectance = 0.08 })
	car.PrimaryPart = floor
	car.Parent = Lm
	Lm.Parent = root
	CollectionService:AddTag(Lm, "MallLift")
end

function M.frame(): CFrame
	return F
end

function M.undo(): string
	local n = 0
	for _, parent in { workspace.Yangon1to1.Landmarks, game:GetService("ServerStorage") } do
		local old = parent:FindFirstChild(NAME)
		if old then
			old:Destroy()
			n += 1
		end
	end
	return "removed " .. n
end

function M.build(parent: Instance?): string
	M.undo()
	count = 0
	local root = Instance.new("Model")
	root.Name = NAME
	root:SetAttribute("Built", "2026-11-28")
	root:SetAttribute("Source", "tools/yangon/Novotel.luau")
	massing(root)
	task.wait()
	carPark(root)
	task.wait()
	lobby(root)
	task.wait()
	forecourt(root)
	poolDeck(root)
	task.wait()
	court(root)
	lift(root)
	-- marker parts for the game's venue code (valet bay under the canopy, the door, the board)
	local marks = folder(root, "Markers")
	for name, v in { ValetBay = { 318, YL - 1.1, -192 }, Entrance = { 304, YL, -192 }, Desk = { 232, YL, -192 }, CarParkGate = { 170, YP, -226 } } do
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
		p.Transparency = 1
		p.Size = Vector3.new(1, 1, 1)
		p.CFrame = F * CFrame.new(v[1], v[2], v[3])
		p.Parent = marks
	end
	root.Parent = parent or workspace.Yangon1to1.Landmarks
	return string.format("%s built: %d parts in %s", NAME, count, root.Parent:GetFullName())
end

return M
