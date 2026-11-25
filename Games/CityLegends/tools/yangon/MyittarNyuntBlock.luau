--[[
	MyittarNyuntBlock.luau (Studio, Edit; owner 26 Nov: "from the video clips that u had to watch, make the interior of
	that building too, its in myita nyunt"). Clips IMG_0927 (outside, carport, arched entrance, dog-leg stair, flat door)
	and IMG_0928 (inside the flat); vault note City Legends/2026-11-26 Myittar Nyunt block - walkable stair and flat.md.

	The building: OSM way 1430305132 (20 m from the clips' GPS 16.803, 96.1859; the only building there with an inner
	corner, where the clip's green glass stair strip stands). The 1:1 map had it as two 1-storey shell boxes (KWG); the
	clip shows ground + 4 floors with a flat roof. This replaces them with a part-built block:
	  Exterior (Default streaming): walls on the OSM outline, 5 storeys of 10 studs, windows with hoods / AC, carport,
	    arched entrance, green stair strip, roof tanks.
	  Inside (Atomic streaming: arrives as one piece when a player comes within the streaming radius): the dog-leg stair
	    (8 flights, landings, black rails, meters, cables, lights), locked flats behind brown collapsible gates, and the
	    walkable flat on floor 3 (entrance, corridor, long back room, bedroom). Privacy: generic furniture only, no
	    names / numbers / posters / photos / whiteboard text / trophies / PC look-alike (see the vault note).
	Local frame: origin = OSM corner A on the ground floor level (y 18.9), +X along A->F (the road face, 80 long),
	+Z along A->B (towards the compound, 28.6 deep); the wing is x 52.4..80, z 28.6..44.2. 3 studs a metre.

	local B = require(game.ServerStorage.ClaudeTools.MyittarNyuntBlock:Clone())
	B.hideShell()   -- old shell boxes -> ServerStorage.YangonSiteHidden.MyittarNyuntBlock + YgnKit.KeepOut boxes
	B.build()       -- (re)builds Workspace.Yangon1to1.Walkable.MyittarNyuntBlock; returns a count line
	B.check()       -- overlap check inside the model and against the map; returns a report line
	B.undo()        -- removes the build, puts the shells back, drops the KeepOut boxes
]]

local M = {}
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialService = game:GetService("MaterialService")

M.NAME = "MyittarNyuntBlock"
M.ORIGIN = Vector3.new(44660.2, 18.9, 35594.8)
M.U = Vector3.new(65.5, 0, -45.6).Unit
M.FRAME = CFrame.fromMatrix(M.ORIGIN, M.U, Vector3.yAxis)
M.SHELL_POINTS = { Vector3.new(44684.5, 22.7, 35595.0), Vector3.new(44722.0, 22.7, 35578.6) }

local F = M.FRAME
local H = 10 -- storey
local FLOORS = 5
local TOP = 52.5 -- parapet top
local T = 0.6 -- wall
local FLAT_K = 3 -- the walkable flat's floor
local FY = FLAT_K * H

local C = {
	cream = Color3.fromRGB(205, 200, 170), wing = Color3.fromRGB(178, 176, 152), plinth = Color3.fromRGB(118, 116, 104),
	mould = Color3.fromRGB(92, 98, 80), band = Color3.fromRGB(214, 210, 186),
	stair = Color3.fromRGB(220, 210, 165), ceil = Color3.fromRGB(235, 235, 230), step = Color3.fromRGB(125, 125, 120),
	nose = Color3.fromRGB(226, 222, 205), rail = Color3.fromRGB(30, 30, 30), landing = Color3.fromRGB(172, 168, 158),
	dirt = Color3.fromRGB(88, 84, 74), wood = Color3.fromRGB(160, 115, 60), green = Color3.fromRGB(105, 148, 122),
	frost = Color3.fromRGB(182, 192, 186), steel = Color3.fromRGB(45, 48, 50), honey = Color3.fromRGB(190, 130, 50),
	gateW = Color3.fromRGB(210, 205, 195), gateB = Color3.fromRGB(100, 55, 45), zinc = Color3.fromRGB(200, 200, 195),
	truss = Color3.fromRGB(130, 55, 40), floorD = Color3.fromRGB(85, 35, 25), floorB = Color3.fromRGB(128, 78, 48),
	skirt = Color3.fromRGB(70, 35, 22), hall = Color3.fromRGB(230, 230, 225), lroom = Color3.fromRGB(70, 80, 75),
	mint = Color3.fromRGB(170, 190, 180), blue = Color3.fromRGB(175, 195, 210), frameRB = Color3.fromRGB(100, 30, 25),
	white = Color3.fromRGB(238, 238, 235), black = Color3.fromRGB(25, 25, 27), pine = Color3.fromRGB(214, 180, 128),
	brown = Color3.fromRGB(72, 45, 30), red = Color3.fromRGB(170, 40, 35), galv = Color3.fromRGB(160, 165, 165),
	yellowWood = Color3.fromRGB(210, 165, 70), curtain = Color3.fromRGB(222, 226, 178), tank = Color3.fromRGB(40, 70, 120),
}
local Mat = Enum.Material

local parent: Instance
local count = 0
local hasVariant = {}

local function variant(p: BasePart?, name: string?)
	if not p or not name then
		return
	end
	if hasVariant[name] == nil then
		hasVariant[name] = MaterialService:FindFirstChild(name, true) ~= nil
	end
	if hasVariant[name] then
		p.MaterialVariant = name
	end
end

-- a part at local cf; deco = no collision, no touch, no shadow
local function P(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, deco: boolean?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = F * cf
	p.Color = color
	p.Material = mat or Mat.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if deco then
		p.CanCollide = false
		p.CanTouch = false
		p.CastShadow = false
	end
	p.Parent = parent
	count += 1
	return p
end

local function box(name, x0, y0, z0, x1, y1, z1, color, mat, deco): Part?
	if x1 - x0 < 0.005 or y1 - y0 < 0.005 or z1 - z0 < 0.005 then
		return nil
	end
	return P(name, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), color, mat, deco)
end

-- a box between s0..s1 along the face axis ("X" = along local X, normal Z), n0..n1 across it
local function sbox(axis, name, s0, s1, y0, y1, n0, n1, color, mat, deco)
	local a, b = math.min(n0, n1), math.max(n0, n1)
	if axis == "X" then
		return box(name, s0, y0, a, s1, y1, b, color, mat, deco)
	end
	return box(name, a, y0, s0, b, y1, s1, color, mat, deco)
end

-- a wall from s a..b, y lo..hi, across n0..n1, with rectangular openings { s0, s1, y0, y1 }
local function wall(axis, name, a, b, n0, n1, lo, hi, opens, color, mat, deco, var)
	local cuts = { a, b }
	for _, o in opens do
		table.insert(cuts, math.clamp(o[1], a, b))
		table.insert(cuts, math.clamp(o[2], a, b))
	end
	table.sort(cuts)
	local made = {}
	for i = 1, #cuts - 1 do
		local s0, s1 = cuts[i], cuts[i + 1]
		if s1 - s0 > 0.005 then
			local mid = (s0 + s1) / 2
			local ys = {}
			for _, o in opens do
				if mid > o[1] and mid < o[2] then
					table.insert(ys, { o[3], o[4] })
				end
			end
			table.sort(ys, function(p, q)
				return p[1] < q[1]
			end)
			local y = lo
			for _, r in ys do
				if r[1] - y > 0.005 then
					table.insert(made, sbox(axis, name, s0, s1, y, math.min(r[1], hi), n0, n1, color, mat, deco))
				end
				y = math.max(y, r[2])
			end
			if hi - y > 0.005 then
				table.insert(made, sbox(axis, name, s0, s1, y, hi, n0, n1, color, mat, deco))
			end
		end
	end
	for _, p in made do
		variant(p, var)
	end
	return made
end

-- a face-oriented CFrame: +X along the face, +Y up, +Z outward (sg = outward sign along the normal axis)
local function faceCF(axis, s, y, n, sg): CFrame
	local pos = if axis == "X" then Vector3.new(s, y, n) else Vector3.new(n, y, s)
	local out = if axis == "X" then Vector3.new(0, 0, sg) else Vector3.new(sg, 0, 0)
	local right = Vector3.yAxis:Cross(out) -- X = Y x Z
	return CFrame.fromMatrix(pos, right, Vector3.yAxis, out)
end

local function text(p: BasePart, face: Enum.NormalId, str: string, color: Color3, bg: Color3?, font: Enum.Font?)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 60
	g.MaxDistance = 60
	g.LightInfluence = 1
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = if bg then 0 else 1
	t.BackgroundColor3 = bg or Color3.new()
	t.TextColor3 = color
	t.TextScaled = true
	t.Font = font or Enum.Font.GothamBold
	t.Text = str
	t.Parent = g
	g.Parent = p
end

local function light(p: BasePart, range: number, bright: number, color: Color3)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = bright
	l.Color = color
	l.Shadows = false
	l.Parent = p
end

-- ===== exterior =====
-- faces: axis, fixed outer coordinate c, outward sign, from a to b, colour, window list (s centres), ground openings
local FACES = {
	{ id = "FA", axis = "X", c = 0, sg = -1, a = 0, b = 80, col = "cream", wins = { 6, 16, 32, 46, 58, 70 }, ground = "wins" },
	{ id = "AB", axis = "Z", c = 0, sg = -1, a = 0.6, b = 28.0, col = "cream", wins = { 9, 19.6 }, ground = "wins" },
	{ id = "BC", axis = "X", c = 28.6, sg = 1, a = 0, b = 53.0, db = 52.22, col = "cream", wins = { 5, 15, 27.75, 37 }, ground = "bc" },
	{ id = "CD", axis = "Z", c = 52.4, sg = -1, a = 28.6, b = 44.2, col = "wing", wins = { 36.4 }, ground = "wins" },
	{ id = "DE", axis = "X", c = 44.2, sg = 1, a = 53.0, b = 80, col = "wing", wins = { 59, 66, 73 }, ground = "de" },
	{ id = "EF", axis = "Z", c = 80, sg = 1, a = 0.6, b = 43.6, col = "wing", wins = { 8, 20, 36 }, ground = "wins" },
}
local WIN_W, WIN_Y0, WIN_Y1 = 4.2, 3.2, 8.0
local STRIP = { 47.8, 51.8 } -- the green glass stair strip on BC, y 10.6 .. 49.4
local ARCH = { 43.0, 47.4, 6.6, 2.2 } -- s0, s1, rectangle top, radius

local function windowAt(f, s0, s1, y0, y1, glass: Color3, hood: boolean, ac: boolean)
	local n_out = f.c
	local n_in = f.c - f.sg * T
	local mid0, mid1 = n_out - f.sg * 0.15, n_out - f.sg * 0.45 -- frame depth inside the opening
	local fw = 0.25
	sbox(f.axis, "WinFrame", s0, s0 + fw, y0, y1, mid0, mid1, C.wood, Mat.Wood, true)
	sbox(f.axis, "WinFrame", s1 - fw, s1, y0, y1, mid0, mid1, C.wood, Mat.Wood, true)
	sbox(f.axis, "WinFrame", s0 + fw, s1 - fw, y0, y0 + fw, mid0, mid1, C.wood, Mat.Wood, true)
	sbox(f.axis, "WinFrame", s0 + fw, s1 - fw, y1 - fw, y1, mid0, mid1, C.wood, Mat.Wood, true)
	local sm = (s0 + s1) / 2
	sbox(f.axis, "WinFrame", sm - 0.1, sm + 0.1, y0 + fw, y1 - fw, mid0, mid1, C.wood, Mat.Wood, true)
	local g0, g1 = n_out - f.sg * 0.27, n_out - f.sg * 0.33
	local gl = sbox(f.axis, "WinGlass", s0 + fw, sm - 0.1, y0 + fw, y1 - fw, g0, g1, glass, Mat.SmoothPlastic, true)
	local gr = sbox(f.axis, "WinGlass", sm + 0.1, s1 - fw, y0 + fw, y1 - fw, g0, g1, glass, Mat.SmoothPlastic, true)
	for _, g in { gl, gr } do
		if g then
			g.Reflectance = 0.08
			g.CanCollide = true -- (ground windows: no walking into the hollow block)
		end
	end
	-- mould drip under the sill, on the outer face
	local w = (s1 - s0) * 0.6
	local floorY = math.floor(y0 / H) * H
	if floorY > 0 then
		sbox(f.axis, "MouldDrip", sm - w / 2, sm + w / 2, floorY + 0.4, y0, n_out, n_out + f.sg * 0.04, C.mould, Mat.Plaster, true)
	end
	if hood then
		-- small grey corrugated hood on two brackets
		local hw, hd = (s1 - s0) + 1.0, 1.7
		local cf = faceCF(f.axis, sm, y1 + 0.95, n_out, f.sg) * CFrame.new(0, 0, 0.12 + hd / 2 * math.cos(math.rad(25))) * CFrame.Angles(math.rad(25), 0, 0)
		local h = P("Hood", Vector3.new(hw, 0.1, hd), cf, C.zinc, Mat.Metal, true)
		variant(h, "YgnCorrugatedZinc")
		for _, ds in { -hw / 2 + 0.4, hw / 2 - 0.4 } do
			local bcf = faceCF(f.axis, sm + ds, y1 + 0.3, n_out, f.sg) * CFrame.new(0, 0, 0.62) * CFrame.Angles(math.rad(-50), 0, 0)
			P("HoodBracket", Vector3.new(0.08, 0.08, 1.0), bcf, C.steel, Mat.Metal, true)
		end
	end
	if ac then
		local acs = s1 + 1.6
		local cf = faceCF(f.axis, acs, y0 + 1.2, n_out, f.sg)
		P("ACUnit", Vector3.new(2.4, 1.8, 0.9), cf * CFrame.new(0, 0, 0.75), C.white, Mat.SmoothPlastic, true)
		P("ACFan", Vector3.new(0.05, 1.3, 1.3), cf * CFrame.new(0.3, 0, 1.225) * CFrame.Angles(0, math.rad(90), 0), C.galv, Mat.Metal, true, Enum.PartType.Cylinder)
		P("ACBracket", Vector3.new(2.0, 0.1, 1.2), cf * CFrame.new(0, -0.95, 0.6), C.steel, Mat.Metal, true)
	end
	local _ = n_in
end

local function exterior()
	for _, f in FACES do
		local col = C[f.col]
		local opens = {}
		local wins = {}
		for k = 1, FLOORS - 1 do
			for _, s in f.wins do
				table.insert(opens, { s - WIN_W / 2, s + WIN_W / 2, k * H + WIN_Y0, k * H + WIN_Y1 })
				table.insert(wins, { s, k })
			end
		end
		if f.ground == "wins" then
			for _, s in f.wins do
				table.insert(opens, { s - WIN_W / 2, s + WIN_W / 2, WIN_Y0, WIN_Y1 })
				table.insert(wins, { s, 0 })
			end
		elseif f.ground == "bc" then
			table.insert(opens, { 6, 18, 0, 8 }) -- ground unit shutter
			table.insert(opens, { 26, 40, 0, 8 }) -- ground unit with the folding gate
			table.insert(opens, { ARCH[1], ARCH[2], 0, ARCH[3] + ARCH[4] }) -- the arch (spandrels added below)
			table.insert(opens, { STRIP[1], STRIP[2], 10.6, 49.4 })
		elseif f.ground == "de" then
			table.insert(opens, { 57, 69, 0, 8 })
		end
		local n0, n1 = f.c, f.c - f.sg * T
		wall(f.axis, "Wall_" .. f.id, f.a, f.b, n0, n1, 0, TOP, opens, col, Mat.Plaster, false, "YgnRenderStained")
		wall(f.axis, "Plinth_" .. f.id, f.a, f.b, n0, n1, -2.2, 0, {}, C.plinth, Mat.Concrete, false, "YgnConcreteStained")
		-- base mould band, floor bands (cut at the openings that cross them: none do), parapet coping
		local bOut = f.c + f.sg * 0.04
		local da, db = f.a, f.db or f.b -- decorations stop short of the wing's wall
		local skip = {}
		if f.ground == "bc" then
			skip = { { 6, 18 }, { 26, 40 }, { ARCH[1] - 0.5, ARCH[2] + 0.5 } }
		elseif f.ground == "de" then
			skip = { { 57, 69 } }
		end
		local mo = {}
		for _, s in skip do
			table.insert(mo, { s[1], s[2], 0, 2.8 })
		end
		wall(f.axis, "MouldBase", da, db, f.c, bOut, 0, 2.8, mo, C.mould, Mat.Plaster, true)
		for k = 1, FLOORS - 1 do
			local o = {}
			if f.ground == "bc" then
				table.insert(o, { STRIP[1], STRIP[2], 0, 99 })
			end
			wall(f.axis, "FloorBand", da, db, f.c, f.c + f.sg * 0.18, k * H - 0.35, k * H + 0.35, o, C.band, Mat.Plaster, true)
		end
		wall(f.axis, "Coping", da, db, f.c, f.c + f.sg * 0.18, TOP - 0.5, TOP, {}, C.band, Mat.Plaster, true)
		-- louvred vents under the coping, one in two windows
		for i, s in f.wins do
			if i % 2 == 1 then
				local v = sbox(f.axis, "Vent", s - 1, s + 1, 49.8, 50.9, f.c, f.c + f.sg * 0.06, C.steel, Mat.Metal, true)
				if v then
					variant(v, "YgnRollerShutter")
				end
			end
		end
		-- windows
		for i, w in wins do
			local s, k = w[1], w[2]
			local ourBed = f.id == "BC" and k == FLAT_K and math.abs(s - 27.75) < 0.1
			local ourLong = f.id == "FA" and k == FLAT_K and math.abs(s - 32) < 0.1
			local glass = if ourBed or ourLong then C.frost else C.green
			local ac = (f.id == "BC" or f.id == "DE") and k >= 2 and (i % 3 == 0)
			windowAt(f, s - WIN_W / 2, s + WIN_W / 2, k * H + WIN_Y0, k * H + WIN_Y1, glass, k >= 1, ac)
		end
	end
	-- corner columns where two faces meet on the outside (the bands stop short of them)
end

-- the arch: spandrels (a stepped curve), the raised trim, the old grid gate standing open
local function arch()
	local s0, s1, rTop, r = ARCH[1], ARCH[2], ARCH[3], ARCH[4]
	local cx = (s0 + s1) / 2
	local steps = 10
	for i = 0, steps - 1 do
		local y0 = rTop + r * i / steps
		local y1 = rTop + r * (i + 1) / steps
		local hw = math.sqrt(math.max(0, r * r - (y0 + (y1 - y0) / 2 - rTop) ^ 2))
		box("ArchFill", s0, y0, 28.0, cx - hw, y1, 28.6, C.cream, Mat.Plaster)
		box("ArchFill", cx + hw, y0, 28.0, s1, y1, 28.6, C.cream, Mat.Plaster)
	end
	-- trim: 9 short segments round the arc + two jamb strips, standing 0.15 proud
	for i = 0, 8 do
		local a = math.rad(i * 180 / 9 + 10)
		local px, py = cx + math.cos(a) * (r + 0.2), rTop + math.sin(a) * (r + 0.2)
		P("ArchTrim", Vector3.new(0.35, 0.62, 0.15), CFrame.new(px, py, 28.675) * CFrame.Angles(0, 0, a), C.band, Mat.Plaster, true)
	end
	box("ArchTrim", s0 - 0.4, 0, 28.6, s0, rTop, 28.75, C.band, Mat.Plaster, true)
	box("ArchTrim", s1, 0, 28.6, s1 + 0.4, rTop, 28.75, C.band, Mat.Plaster, true)
	-- the old steel grid gate, folded open flat against the facade left of the arch (verticals and rails in two layers)
	local gx0, gx1 = 40.1, 42.5
	for i = 0, 4 do
		local x = gx0 + 0.05 + i * (gx1 - gx0 - 0.1) / 4
		box("ArchGate", x - 0.05, 0.1, 28.64, x + 0.05, 7.0, 28.72, C.steel, Mat.Metal, true)
	end
	for j = 0, 9 do
		local y = 0.3 + j * 0.74
		box("ArchGate", gx0, y - 0.05, 28.72, gx1, y + 0.05, 28.8, C.steel, Mat.Metal, true)
	end
end

local function groundUnits()
	-- BC ground: silver roll-up shutter x 6..18 and x 26..40 with the red-brown folding lattice gate in front of the second
	for _, o in { { 6, 18 }, { 26, 40 } } do
		local sh = box("Shutter", o[1], 0, 28.0, o[2], 8, 28.1, C.galv, Mat.Metal)
		if sh then
			variant(sh, "YgnRollerShutter")
		end
	end
	-- lattice gate on x 26..40: uprights (layer 1) and diagonals (layers 2 and 3)
	local x0, x1 = 26.1, 39.9
	local n = 16
	for i = 0, n do
		local x = x0 + (x1 - x0) * i / n
		box("FoldGate", x - 0.06, 0.05, 28.3, x + 0.06, 7.9, 28.38, C.gateB, Mat.Metal, true)
	end
	local bay = (x1 - x0) / n
	for i = 0, n - 1 do
		local cx = x0 + bay * (i + 0.5)
		for tier = 0, 2 do
			local y = 1.4 + tier * 2.6
			local len = math.sqrt(bay * bay + 2.4 * 2.4) - 0.2
			local ang = math.atan2(2.4, bay)
			P("FoldGateX", Vector3.new(len, 0.07, 0.04), CFrame.new(cx, y, 28.4) * CFrame.Angles(0, 0, ang), C.gateB, Mat.Metal, true)
			P("FoldGateX", Vector3.new(len, 0.07, 0.04), CFrame.new(cx, y, 28.44) * CFrame.Angles(0, 0, -ang), C.gateB, Mat.Metal, true)
		end
	end
	box("FoldGateRail", x0, 7.92, 28.18, x1, 8.0, 28.46, C.gateB, Mat.Metal, true)
	-- the white notice on it (generic: "no parking")
	local sign = box("Notice", 31, 5.6, 28.46, 34, 7.0, 28.5, C.white, Mat.SmoothPlastic, true)
	if sign then
		text(sign, Enum.NormalId.Back, "ကားမရပ်ရ", Color3.fromRGB(20, 20, 20), C.white)
	end
	-- DE ground opening x 57..69: a shutter
	variant(box("Shutter", 57, 0, 43.6, 69, 8, 43.7, C.galv, Mat.Metal), "YgnRollerShutter")
end

local function carport()
	-- concrete pad, roof on a red-brown truss, scalloped edge on the wall, blue PVC pipes, breeze block pile
	box("CarportPad", 10, -1.9, 28.6, 52.4, 0, 43.0, C.landing, Mat.Concrete)
	local z0, z1, yW, yF = 28.6, 42.6, 9.1, 8.5
	local run = z1 - z0
	local slope = math.atan2(yW - yF, run)
	local len = run / math.cos(slope)
	local roof = P("CarportRoof", Vector3.new(42.4, 0.12, len), CFrame.new(31.2, (yW + yF) / 2 + 0.3, (z0 + z1) / 2) * CFrame.Angles(-slope, 0, 0), C.zinc, Mat.Metal)
	variant(roof, "YgnCorrugatedZinc")
	roof.Size = Vector3.new(42.2, 0.12, len - 0.05)
	-- front beam (truss top chord), bottom chord, Z diagonals, posts
	box("TrussTop", 10.2, yF - 0.35, 42.3, 52.2, yF, 42.6, C.truss, Mat.Metal)
	box("TrussBottom", 10.2, yF - 1.6, 42.3, 52.2, yF - 1.3, 42.6, C.truss, Mat.Metal)
	local bays = 14
	local bw = (52.2 - 10.2) / bays
	for i = 0, bays - 1 do
		local cx = 10.2 + bw * (i + 0.5)
		local dy = 0.95
		local l = math.sqrt(bw * bw + dy * dy) - 0.15
		P("TrussDiag", Vector3.new(l, 0.18, 0.2), CFrame.new(cx, yF - 0.825, 42.45) * CFrame.Angles(0, 0, (if i % 2 == 0 then 1 else -1) * math.atan2(dy, bw)), C.truss, Mat.Metal, true)
	end
	for _, x in { 10.4, 24.4, 38.4, 52.0 } do
		box("CarportPost", x - 0.2, 0, 42.25, x + 0.2, yF - 1.6, 42.65, C.truss, Mat.Metal)
	end
	-- rafters from wall to beam
	for _, x in { 16, 24.4, 31.2, 38.4, 45.5 } do
		P("Rafter", Vector3.new(0.18, 0.3, len - 0.6), CFrame.new(x, (yW + yF) / 2 + 0.06, (z0 + z1) / 2 - 0.1) * CFrame.Angles(-slope, 0, 0), C.truss, Mat.Metal, true)
	end
	-- scalloped brown edging where the roof meets the wall
	for x = 11, 51.5, 1.5 do
		P("Scallop", Vector3.new(0.7, 1.2, 1.2), CFrame.new(x, 10.15, 29.6), Color3.fromRGB(120, 72, 52), Mat.Slate, true, Enum.PartType.Cylinder)
	end
	-- blue PVC drainpipe down beside the arch and across above it
	box("PipeBlue", 48.9, 0.2, 28.64, 49.25, 9.2, 28.99, Color3.fromRGB(150, 185, 205), Mat.SmoothPlastic, true)
	box("PipeBlue", 43.0, 9.2, 28.64, 49.25, 9.55, 28.99, Color3.fromRGB(150, 185, 205), Mat.SmoothPlastic, true)
	-- junction box with wires above the band
	box("JunctionBox", 40.2, 10.5, 28.6, 41.4, 11.9, 28.95, C.galv, Mat.Metal, true)
	-- breeze blocks, loose
	local r = Random.new(927)
	for i = 0, 9 do
		local x = 20 + (i % 5) * 1.5 + r:NextNumber(-0.1, 0.1)
		local z = 33 + math.floor(i / 5) * 1.2
		local b = box("BreezeBlock", x, 0, z, x + 1.2, 0.45, z + 0.6, Color3.fromRGB(165, 160, 150), Mat.Concrete, true)
		if b then
			b.CFrame = b.CFrame * CFrame.Angles(0, r:NextNumber(-0.2, 0.2), 0)
		end
	end
end

local function roof()
	box("RoofSlab", T, 49.4, T, 80 - T, 50, 28.0, C.landing, Mat.Concrete)
	box("RoofSlab", 53.0, 49.4, 28.0, 80 - T, 50, 44.2 - T, C.landing, Mat.Concrete)
	for i = 0, 7 do
		local x = 6 + i * 9
		P("RoofTank", Vector3.new(2.6, 2.4, 2.4), CFrame.new(x, 51.3, 8) * CFrame.Angles(0, 0, math.rad(90)), if i % 3 == 0 then C.black else C.tank, Mat.SmoothPlastic, true, Enum.PartType.Cylinder)
	end
	-- the stair strip: green glass panes with steel mullions, one pane per storey band
	for k = 1, FLOORS - 1 do
		local y0, y1 = math.max(10.6, k * H + 0.6), math.min(49.4, (k + 1) * H + 0.6)
		if k == FLOORS - 1 then
			y1 = 49.4
		end
		box("StripMullion", STRIP[1], y0, 28.15, STRIP[2], y0 + 0.2, 28.45, C.steel, Mat.Metal, true)
		for _, x in { STRIP[1], (STRIP[1] + STRIP[2]) / 2 - 0.08, STRIP[2] - 0.16 } do
			box("StripMullion", x, y0 + 0.2, 28.15, x + 0.16, y1, 28.45, C.steel, Mat.Metal, true)
		end
		local g = box("StripGlass", STRIP[1] + 0.16, y0 + 0.2, 28.27, (STRIP[1] + STRIP[2]) / 2 - 0.08, y1, 28.33, C.green, Mat.SmoothPlastic, true)
		local g2 = box("StripGlass", (STRIP[1] + STRIP[2]) / 2 + 0.08, y0 + 0.2, 28.27, STRIP[2] - 0.16, y1, 28.33, C.green, Mat.SmoothPlastic, true)
		for _, q in { g, g2 } do
			if q then
				q.Reflectance = 0.1
				q.CanCollide = true
			end
		end
	end
end

-- ===== inside: the stair core x 42.4..52.4, z 11.6..28.0 =====
local SX0, SX1, SZ0, SZ1 = 42.4, 52.4, 11.6, 28.0
local LAND_Z = 24.0 -- floor landings z 24..28 (at the facade), half landings z 11.6..16.5 (at the back)
local HALF_Z = 16.5
local FB = { 42.4, 46.8 } -- flight B (half -> floor), up towards the facade
local FA_ = { 48.0, 52.4 } -- flight A (floor -> half), up towards the back
local PB = { 46.8, 47.25 }
local PA = { 47.55, 48.0 }
local RISE, NSTEP = 5, 8
local TREAD = (LAND_Z - HALF_Z) / NSTEP
local DOOR = { 24.3, 27.7, 7.2 }

local function stairWalls()
	local opensW, opensE = {}, {}
	for k = 1, FLOORS - 1 do
		table.insert(opensW, { DOOR[1], DOOR[2], k * H, k * H + DOOR[3] })
		table.insert(opensE, { DOOR[1], DOOR[2], k * H, k * H + DOOR[3] })
	end
	wall("Z", "StairWall", 11.0, 28.0, 41.8, 42.4, 0, 49.4, opensW, C.stair, Mat.Plaster, false, "YgnRenderStained")
	wall("Z", "StairWall", 11.0, 28.0, 52.4, 53.0, 0, 49.4, opensE, C.stair, Mat.Plaster, false, "YgnRenderStained")
	box("StairWall", 42.4, 0, 11.0, 52.4, 49.4, 11.6, C.stair, Mat.Plaster)
	box("StairGround", 42.4, -1.9, 11.6, 52.4, 0, 28.0, C.landing, Mat.Concrete)
	for k = 1, FLOORS - 1 do
		local l = box("Landing", 42.4, k * H - 0.6, LAND_Z, 52.4, k * H, 28.0, C.landing, Mat.Concrete)
		variant(l :: Part, "YgnConcreteStained")
	end
	for k = 0, FLOORS - 2 do
		local y = k * H + RISE
		local l = box("HalfLanding", 42.4, y - 0.6, SZ0, 52.4, y, HALF_Z, C.landing, Mat.Concrete)
		variant(l :: Part, "YgnConcreteStained")
	end
	-- dirt band along the walls of each landing (plates on the wall faces)
	for k = 0, FLOORS - 1 do
		local y = k * H
		box("DirtBand", 52.35, y, LAND_Z, 52.4, y + 0.45, DOOR[1] - 0.1, C.dirt, Mat.Plaster, true)
		if k > 0 then
			box("DirtBand", 42.4, y, LAND_Z, 42.45, y + 0.45, DOOR[1] - 0.1, C.dirt, Mat.Plaster, true)
			box("DirtBand", 42.45, y, 27.95, 47.8, y + 0.45, 28.0, C.dirt, Mat.Plaster, true)
		end
		if k < FLOORS - 1 then
			box("DirtBand", 42.4, y + RISE, 11.6, 52.4, y + RISE + 0.45, 11.65, C.dirt, Mat.Plaster, true)
		end
	end
end

local function rail(x, z0, y0, z1, y1)
	-- black flat-bar rail over a sloping parapet top, from (z0,y0) to (z1,y1); posts, top rail, one diagonal per bay
	local dz, dy = z1 - z0, y1 - y0
	local len = math.sqrt(dz * dz + dy * dy)
	local ang = math.atan2(dy, dz)
	local h = 3.0
	local mz, my = (z0 + z1) / 2, (y0 + y1) / 2
	P("RailTop", Vector3.new(0.14, 0.1, len), CFrame.new(x, my + h + 0.05, mz) * CFrame.Angles(-ang, 0, 0), C.rail, Mat.Metal, true)
	local nb = 3
	for i = 0, nb do
		local t = i / nb
		local z, y = z0 + dz * t, y0 + dy * t
		local ph = h - 0.06
		box("RailPost", x - 0.06, y, z - 0.06, x + 0.06, y + ph, z + 0.06, C.rail, Mat.Metal, true)
		if i < nb then
			local t2 = (i + 1) / nb
			local za, ya = z + 0.15 * math.sign(dz), y + 0.3
			local zb, yb = z0 + dz * t2 - 0.15 * math.sign(dz), y0 + dy * t2 + h - 0.45
			local l = math.sqrt((zb - za) ^ 2 + (yb - ya) ^ 2)
			P("RailDiag", Vector3.new(0.05, 0.12, l), CFrame.lookAt(Vector3.new(x + 0.09, (ya + yb) / 2, (za + zb) / 2), Vector3.new(x + 0.09, yb, zb)), C.rail, Mat.Metal, true)
		end
	end
end

-- which way a WedgePart's slope rises, read once from a probe wedge (rays on its two halves)
local wedgeUpPlusZ: boolean? = nil
local function wedgeRisesPlusZ(): boolean
	if wedgeUpPlusZ == nil then
		local w = Instance.new("WedgePart")
		w.Anchored = true
		w.Size = Vector3.new(4, 4, 4)
		w.CFrame = CFrame.new(0, -5000, 0)
		w.Parent = workspace
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { w }
		local hp = workspace:Raycast(Vector3.new(0, -4990, 1.5), Vector3.new(0, -20, 0), rp)
		local hm = workspace:Raycast(Vector3.new(0, -4990, -1.5), Vector3.new(0, -20, 0), rp)
		wedgeUpPlusZ = (if hp then hp.Position.Y else -1e9) > (if hm then hm.Position.Y else -1e9)
		w:Destroy()
	end
	return wedgeUpPlusZ :: boolean
end

local function flight(name, xr, pr, zFrom, zTo, base)
	local dir = if zTo > zFrom then 1 else -1
	for i = 1, NSTEP do
		local za = zFrom + dir * (i - 1) * TREAD
		local zb = zFrom + dir * i * TREAD
		local top = base + i * RISE / NSTEP
		local bot = math.max(top - 1.25, base)
		local s = box(name, xr[1], bot, math.min(za, zb), xr[2], top, math.max(za, zb), C.step, Mat.Concrete)
		variant(s :: Part, "YgnConcreteStained")
		-- white painted nosing line on the riser top
		local zf = math.min(za, zb)
		if dir < 0 then
			zf = math.max(za, zb)
		end
		local nz0 = if dir > 0 then zf - 0.03 else zf
		box("Nosing", xr[1] + 0.2, top - 0.08, nz0, xr[2] - 0.2, top, nz0 + 0.03, C.nose, Mat.SmoothPlastic, true)
	end
	-- the low sloping side wall: a wedge under the slope + a 0.6 cap on it
	local run = math.abs(zTo - zFrom)
	local w = Instance.new("WedgePart")
	w.Name = "Parapet"
	w.Size = Vector3.new(pr[2] - pr[1], RISE, run)
	-- WedgePart slope rises towards -Z of its own frame; turn it so it rises towards zTo
	local turn = (dir > 0) ~= wedgeRisesPlusZ()
	w.CFrame = F * CFrame.new((pr[1] + pr[2]) / 2, base + RISE / 2, (zFrom + zTo) / 2) * (if turn then CFrame.Angles(0, math.pi, 0) else CFrame.new())
	w.Color = C.stair
	w.Material = Mat.Plaster
	w.Anchored = true
	w.Parent = parent
	count += 1
	local ang = math.atan2(RISE, run)
	local L = math.sqrt(run * run + RISE * RISE)
	local cap = 0.6
	local mz = (zFrom + zTo) / 2
	local my = base + RISE / 2
	local nrm = Vector3.new(0, math.cos(ang), -dir * math.sin(ang)) -- up and back along the flight
	local c = Vector3.new((pr[1] + pr[2]) / 2, my, mz) + nrm * (cap / 2)
	P("ParapetCap", Vector3.new(pr[2] - pr[1], cap, L), CFrame.new(c) * CFrame.Angles(dir * ang * -1, 0, 0), C.stair, Mat.Plaster)
	-- rail posts sit on the cap top
	local top0 = Vector3.new(0, base, zFrom) + nrm * cap
	local top1 = Vector3.new(0, base + RISE, zTo) + nrm * cap
	rail((pr[1] + pr[2]) / 2, top0.Z, top0.Y + 0.05, top1.Z, top1.Y + 0.05)
end

local function stairs()
	for k = 0, FLOORS - 2 do
		flight("StepA", FA_, PA, LAND_Z, HALF_Z, k * H)
		flight("StepB", FB, PB, HALF_Z, LAND_Z, k * H + RISE)
	end
	-- top landing: a square rail across the stairwell end at floor 4
	local y = (FLOORS - 1) * H
	box("TopRail", 47.3, y + 2.95, LAND_Z, 52.4, y + 3.05, LAND_Z + 0.12, C.rail, Mat.Metal)
	for x = 47.5, 52, 1.1 do
		box("TopRailPost", x, y, LAND_Z + 0.02, x + 0.1, y + 2.95, LAND_Z + 0.1, C.rail, Mat.Metal, true)
	end
end

local function stairProps()
	-- ground lobby: meter cabinets, a new LCD meter, a cable bundle, the padlocked grille under flight B
	for i = 0, 2 do
		local z = 24.4 + i * 1.15
		local c = box("MeterCabinet", 42.4, 4.4, z, 42.75, 6.6, z + 1.0, C.galv, Mat.Metal, true)
		if c then
			variant(c, "YgnSteelPainted")
		end
		for j = 0, 1 do
			box("MeterWindow", 42.75, 4.8 + j * 0.9, z + 0.25, 42.78, 5.3 + j * 0.9, z + 0.75, Color3.fromRGB(140, 160, 165), Mat.SmoothPlastic, true)
		end
		box("MeterTag", 42.75, 6.65, z + 0.4, 42.78, 6.85, z + 0.6, C.red, Mat.SmoothPlastic, true)
	end
	box("LCDMeter", 52.0, 4.6, 25.2, 52.4, 6.0, 26.0, Color3.fromRGB(210, 212, 215), Mat.SmoothPlastic, true)
	box("Breaker", 52.05, 3.9, 25.4, 52.4, 4.4, 25.8, C.black, Mat.SmoothPlastic, true)
	for i = 0, 2 do
		local a = Vector3.new(42.5 + 0.1 * i, 6.8, 25.0 + i * 0.6)
		local b = Vector3.new(42.5 + 0.1 * i, 9.35, 27.6 - i * 0.2)
		local l = (b - a).Magnitude
		P("Cable", Vector3.new(0.08, 0.08, l), CFrame.lookAt((a + b) / 2, b), C.black, Mat.Rubber, true)
	end
	-- under-stair store front: grille panel + infill above
	for i = 0, 7 do
		local y = 0.4 + i * 0.85
		box("StoreGrille", 42.5, y - 0.05, 23.9, 46.7, y + 0.05, 23.97, C.galv, Mat.Metal, true)
	end
	for _, x in { 42.45, 44.55, 46.7 } do
		box("StoreGrilleFrame", x, 0, 23.97, x + 0.1, 7.2, 24.0, C.galv, Mat.Metal, true)
	end
	box("StoreInfill", 42.4, 7.2, 23.8, 46.8, 8.75, 24.0, C.stair, Mat.Plaster)
	box("Padlock", 44.4, 3.4, 24.0, 44.7, 3.8, 24.12, Color3.fromRGB(190, 190, 195), Mat.Metal, true)
	-- junk inside: an old bicycle wheel
	P("BikeWheel", Vector3.new(0.12, 2.0, 2.0), CFrame.new(44.0, 1.05, 20.5), C.black, Mat.Rubber, true, Enum.PartType.Cylinder)
	-- landings: batten lights, plates, cabinets, sack, broom
	for k = 0, FLOORS - 1 do
		local y = k * H
		local bat = box("Batten", 52.25, y + 8.2, 25.2, 52.4, y + 8.4, 27.0, C.white, Mat.SmoothPlastic, true)
		local tube = box("BattenTube", 52.17, y + 8.24, 25.3, 52.25, y + 8.36, 26.9, Color3.fromRGB(240, 245, 250), Mat.Neon, true)
		if tube and (k == 0 or k == 2 or k == FLAT_K or k == 4) then
			light(tube, 18, 0.9, Color3.fromRGB(235, 240, 255))
		end
		local _ = bat
	end
	-- red plates with generic Burmese text ("no littering") at ~1.5 m
	for _, k in { 2, 3 } do
		local p = box("RedPlate", 47.9, k * H + RISE + 4.3, 11.6, 49.1, k * H + RISE + 4.7, 11.64, C.red, Mat.SmoothPlastic, true)
		if p then
			text(p, Enum.NormalId.Back, "အမှိုက်မပစ်ရ", Color3.new(1, 1, 1), C.red)
		end
	end
	-- half landing 1: tall black cabinet and a TV back
	box("BlackCabinet", 49.5, RISE, 11.66, 51.2, RISE + 5.4, 12.86, C.black, Mat.SmoothPlastic)
	box("BlackPanel", 47.0, RISE, 11.66, 48.6, RISE + 3.2, 12.06, Color3.fromRGB(35, 35, 38), Mat.SmoothPlastic)
	-- half landing 2: a white woven sack and an orange broom
	box("Sack", 51.2, H + RISE, 11.66, 52.35, H + RISE + 1.4, 12.6, Color3.fromRGB(225, 222, 210), Mat.Fabric, true)
	P("Broom", Vector3.new(0.12, 4.6, 0.12), CFrame.new(42.7, H + RISE + 2.35, 12.0) * CFrame.Angles(0.15, 0, 0), Color3.fromRGB(230, 120, 30), Mat.Plastic, true)
end

-- a closed flat door with a brown collapsible gate in front (locked flats), on the wall at x (landing side sgn)
local function lockedDoor(k, xw0, xw1, side)
	local y = k * H
	box("FlatDoor", xw0 + 0.15, y, DOOR[1], xw1 - 0.15, y + DOOR[3], DOOR[2], C.honey, Mat.Wood)
	local face = if side > 0 then xw1 else xw0
	local n = 8
	for i = 0, n do
		local z = DOOR[1] + (DOOR[2] - DOOR[1]) * i / n
		local a, b = face, face + side * 0.07
		box("GateUpright", math.min(a, b), y + 0.02, z - 0.05, math.max(a, b), y + DOOR[3] - 0.1, z + 0.05, C.gateB, Mat.Metal, true)
	end
	local bay = (DOOR[2] - DOOR[1]) / n
	for i = 0, n - 1 do
		local cz = DOOR[1] + bay * (i + 0.5)
		for tier = 0, 1 do
			local cy = y + 1.8 + tier * 3.4
			local ang = math.atan2(3.0, bay)
			local len = math.sqrt(bay * bay + 9) - 0.25
			P("GateX", Vector3.new(0.035, len, 0.06), CFrame.new(face + side * 0.09, cy, cz) * CFrame.Angles(ang - math.pi / 2, 0, 0), C.gateB, Mat.Metal, true)
			P("GateX", Vector3.new(0.035, len, 0.06), CFrame.new(face + side * 0.13, cy, cz) * CFrame.Angles(-(ang - math.pi / 2), 0, 0), C.gateB, Mat.Metal, true)
		end
	end
	P("Padlock", Vector3.new(0.15, 0.4, 0.3), CFrame.new(face + side * 0.25, y + 3.4, DOOR[1] + 0.5), C.galv, Mat.Metal, true)
end

local function ourDoor()
	local y = FY
	-- door leaf open 90 degrees inward, standing by the facade wall inside the flat
	local leaf = box("OurDoor", 41.8 - 3.4, y, 27.68, 41.8, y + DOOR[3] - 0.05, 27.88, C.honey, Mat.Wood)
	if leaf then
		leaf.Reflectance = 0.06
	end
	-- arch panel + two rectangular panels on the leaf's open face (towards the hall, -z)
	box("DoorPanel", 41.8 - 2.9, y + 4.2, 27.62, 41.8 - 0.5, y + 6.4, 27.68, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	box("DoorPanel", 41.8 - 2.9, y + 0.6, 27.62, 41.8 - 1.8, y + 3.8, 27.68, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	box("DoorPanel", 41.8 - 1.6, y + 0.6, 27.62, 41.8 - 0.5, y + 3.8, 27.68, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	P("Knob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(41.8 - 3.15, y + 3.3, 27.5), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
	-- raised white step in the opening, white frame round it on the landing side
	box("Threshold", 41.8, y, DOOR[1], 42.4, y + 0.3, DOOR[2], C.white, Mat.SmoothPlastic)
	box("DoorFrame", 42.4, y, DOOR[1] - 0.25, 42.47, y + DOOR[3] + 0.25, DOOR[1], C.white, Mat.SmoothPlastic, true)
	box("DoorFrame", 42.4, y, DOOR[2], 42.47, y + DOOR[3] + 0.25, DOOR[2] + 0.25, C.white, Mat.SmoothPlastic, true)
	box("DoorFrame", 42.4, y + DOOR[3], DOOR[1], 42.47, y + DOOR[3] + 0.25, DOOR[2], C.white, Mat.SmoothPlastic, true)
	-- the off-white collapsible gate, folded and stacked on the left (towards the facade), in a floor track
	box("GateTrack", 42.4, y, DOOR[1], 42.75, y + 0.05, DOOR[2], C.galv, Mat.Metal, true)
	for i = 0, 5 do
		local z = 27.72 + i * 0.045
		box("GateFolded", 42.47 + (i % 2) * 0.12, y + 0.05, z, 42.6 + (i % 2) * 0.12, y + DOOR[3], z + 0.04, C.gateW, Mat.Metal, true)
	end
	local stamp = box("GateStamp", 42.72, y + 4.2, 27.765, 42.73, y + 6.0, 27.805, C.gateW, Mat.Metal, true)
	if stamp then
		text(stamp, Enum.NormalId.Right, "ZAYA SUPER", Color3.fromRGB(150, 145, 135))
	end
	-- the dried leaf and twig bundle tied at eye height
	P("TwigBundle", Vector3.new(1.2, 0.4, 0.4), CFrame.new(43.3, y + 5.6, 27.4) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 85, 60), Mat.Wood, true, Enum.PartType.Cylinder)
	local r = Random.new(1106)
	for i = 0, 6 do
		local a = i * math.pi * 2 / 7
		P("DryLeaf", Vector3.new(0.05, 0.55, 0.4), CFrame.new(43.3 + math.cos(a) * 0.42, y + 5.2 + r:NextNumber(0, 0.6), 27.4 + math.sin(a) * 0.32) * CFrame.Angles(0, a, r:NextNumber(-0.5, 0.5)), Color3.fromRGB(125, 95, 65), Mat.Fabric, true)
	end
	-- bare LED bulb in a plain wall holder above the gate
	box("BulbHolder", 42.4, y + 8.0, 25.8, 42.6, y + 8.25, 26.1, C.white, Mat.SmoothPlastic, true)
	local bulb = P("Bulb", Vector3.new(0.3, 0.3, 0.3), CFrame.new(42.75, y + 8.12, 25.95), Color3.fromRGB(255, 250, 235), Mat.Neon, true, Enum.PartType.Ball)
	light(bulb, 12, 0.7, Color3.fromRGB(255, 240, 215))
end

-- ===== the flat (floor 3): flat coords fx = 41.8 - x (0 at the stair wall), fz = z =====
local function fb(name, fx0, fx1, z0, z1, y0, y1, color, mat, deco)
	return box(name, 41.8 - fx1, FY + y0, z0, 41.8 - fx0, FY + y1, z1, color, mat, deco)
end
local CEIL = 9.4

local function flatShell()
	-- floor (dark boards; the bedroom lighter), ceiling, flat walls; linings give each room its own paint
	local f1 = fb("FloorBoards", 0, 19.4, 0.6, 28.0, -0.6, 0, C.floorD, Mat.WoodPlanks)
	if f1 then
		f1.Reflectance = 0.04
	end
	-- (the bedroom boards are a separate plate on top: 0.02 thick)
	fb("FloorBoardsBed", 9.05, 19.35, 13.65, 27.95, 0, 0.02, C.floorB, Mat.WoodPlanks, true)
	fb("Ceiling", 0, 19.4, 0.6, 28.0, CEIL, CEIL + 0.6, C.ceil, Mat.Plaster)
	-- outer partition to the next flat (west) and the stair-side wall below the stair core
	fb("FlatWall", 19.4, 20.0, 0.6, 28.0, 0, CEIL, C.hall, Mat.Plaster)
	fb("FlatWall", -0.6, 0, 0.6, 11.0, 0, CEIL, C.hall, Mat.Plaster)
	-- inner walls
	local doorK = { 14.0, 17.4 }
	wall("Z", "W1", 10.4, 19.5, 41.8 - 5.4, 41.8 - 4.8, FY, FY + CEIL, { { doorK[1], doorK[2], FY, FY + 7.0 } }, C.hall, Mat.Plaster)
	fb("W2", 5.4, 8.4, 18.9, 19.5, 0, CEIL, C.hall, Mat.Plaster)
	wall("Z", "W3", 13.0, 28.0, 41.8 - 9.0, 41.8 - 8.4, FY, FY + CEIL, { { 20.4, 23.8, FY, FY + 7.0 } }, C.hall, Mat.Plaster)
	fb("W4", 9.0, 19.4, 13.0, 13.6, 0, CEIL, C.hall, Mat.Plaster)
	fb("W5", 4.8, 19.4, 9.8, 10.4, 0, CEIL, C.hall, Mat.Plaster)
	-- closed kitchen / bath door in W1
	fb("KDoor", 4.95, 5.25, doorK[1], doorK[2], 0, 7.0, Color3.fromRGB(150, 120, 60), Mat.Wood)
	P("Knob", Vector3.new(0.28, 0.28, 0.28), CFrame.new(36.99, FY + 3.3, doorK[1] + 0.5), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
end

-- lining plates (0.05) on a room's four walls, with openings; side = which wall
local function lining(name, fx0, fx1, z0, z1, color, opens)
	local d = 0.05
	-- walls along fz (at fx0 and fx1): axis Z
	wall("Z", name, z0, z1, 41.8 - fx0 - d, 41.8 - fx0, FY, FY + CEIL, opens.fx0 or {}, color, Mat.Plaster, true)
	wall("Z", name, z0, z1, 41.8 - fx1, 41.8 - fx1 + d, FY, FY + CEIL, opens.fx1 or {}, color, Mat.Plaster, true)
	wall("X", name, 41.8 - fx1 + d, 41.8 - fx0 - d, z0, z0 + d, FY, FY + CEIL, opens.z0 or {}, color, Mat.Plaster, true)
	wall("X", name, 41.8 - fx1 + d, 41.8 - fx0 - d, z1 - d, z1, FY, FY + CEIL, opens.z1 or {}, color, Mat.Plaster, true)
end

local function skirting(fx0, fx1, z0, z1, gaps)
	local d, s, h = 0.05, 0.08, 0.35
	local function run(axis, a, b, n0, n1, g)
		wall(axis, "Skirting", a, b, n0, n1, FY, FY + h, g or {}, C.skirt, Mat.Wood, true)
	end
	run("Z", z0 + d, z1 - d, 41.8 - fx0 - d - s, 41.8 - fx0 - d, gaps.fx0)
	run("Z", z0 + d, z1 - d, 41.8 - fx1 + d, 41.8 - fx1 + d + s, gaps.fx1)
	run("X", 41.8 - fx1 + d + s, 41.8 - fx0 - d - s, z0 + d, z0 + d + s, gaps.z0)
	run("X", 41.8 - fx1 + d + s, 41.8 - fx0 - d - s, z1 - d - s, z1 - d, gaps.z1)
end

local function rooms()
	local o = function(a, b, y0, y1)
		return { a, b, FY + y0, FY + y1 }
	end
	-- window openings in the outer walls (as x ranges for "X" walls)
	local bedWin = o(25.65, 29.85, 3.2, 8.0)
	local hallWin = o(34.9, 39.1, 3.2, 8.0)
	local longWin = o(29.9, 34.1, 3.2, 8.0)
	local skG = function(a, b)
		return { a, b, FY, FY + 1 }
	end
	-- hall + corridor (white): E fx 0..8.4 z 19.5..28 ; C fx 0..4.8 z 10.4..19.5 (open to each other)
	lining("LinE", 0, 8.4, 19.5, 28.0, C.hall, {
		fx0 = { o(DOOR[1], DOOR[2], 0, DOOR[3]) },
		fx1 = { o(20.4, 23.8, 0, 7.0) },
		z0 = { o(41.8 - 4.8, 41.8 + 1, 0, CEIL + 1) }, -- open to the corridor
		z1 = { hallWin },
	})
	lining("LinC", 0, 4.8, 10.4, 19.5, C.hall, {
		fx1 = { o(14.0, 17.4, 0, 7.0) },
		z0 = { o(30, 50, 0, CEIL + 1) }, -- open to the long room
		z1 = { o(30, 50, 0, CEIL + 1) }, -- open to the hall
	})
	skirting(0, 8.4, 19.5, 28.0, { fx0 = { skG(DOOR[1], DOOR[2]) }, fx1 = { skG(20.1, 24.1) }, z0 = { skG(41.8 - 4.8 - 0.2, 42) } })
	skirting(0, 4.8, 10.4, 19.5, { fx1 = { skG(14.0, 17.4) }, z0 = { skG(30, 50) }, z1 = { skG(30, 50) } })
	-- long back room (dark green-grey): fx 0..19.4 z 0.6..9.8
	lining("LinL", 0, 19.4, 0.6, 9.8, C.lroom, { z0 = { longWin }, z1 = { o(41.8 - 4.8, 42, 0, CEIL + 1) } })
	skirting(0, 19.4, 0.6, 9.8, { z1 = { skG(41.8 - 4.8 - 0.2, 42) } })
	-- bedroom (mint, the window wall light blue): fx 9..19.4 z 13.6..28
	lining("LinB", 9.0, 19.4, 13.6, 28.0, C.mint, { fx0 = { o(20.4, 23.8, 0, 7.0) }, z1 = { bedWin } })
	skirting(9.0, 19.4, 13.6, 28.0, { fx0 = { skG(20.4, 23.8) } })
	-- the window wall's blue paint is a second plate over the mint lining (0.02 in front)
	wall("X", "LinBBlue", 41.8 - 19.4 + 0.05 + 0.08, 41.8 - 9.0 - 0.05 - 0.08, 28.0 - 0.07, 28.0 - 0.05, FY + 0.35, FY + CEIL, { bedWin }, C.blue, Mat.Plaster, true)
end

local function windowsInside()
	-- bedroom window: grille bars, curtains on a chrome rail, the split AC above
	local x0, x1 = 25.65, 29.85
	for i = 1, 9 do
		local y = FY + 3.2 + i * 0.48
		box("Grille", x0, y - 0.04, 27.85, x1, y + 0.04, 27.95, Color3.fromRGB(215, 215, 210), Mat.Metal, true)
	end
	box("Grille", (x0 + x1) / 2 - 0.05, FY + 3.2, 27.8, (x0 + x1) / 2 + 0.05, FY + 8.0, 27.85, Color3.fromRGB(215, 215, 210), Mat.Metal, true)
	box("CurtainRail", x0 - 1.2, FY + 8.45, 27.6, x1 + 1.2, FY + 8.55, 27.7, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	for _, c in { { x0 - 1.1, x0 + 0.9 }, { x1 - 0.9, x1 + 1.1 } } do
		local cu = box("Curtain", c[1], FY + 2.2, 27.5, c[2], FY + 8.4, 27.58, C.curtain, Mat.Fabric, true)
		local _ = cu
	end
	local ac = box("SplitAC", x0 + 0.2, FY + 8.6, 27.15, x1 - 0.2, FY + 9.35, 27.93, C.white, Mat.SmoothPlastic, true)
	if ac then
		text(box("ACLogo", x0 + 1.6, FY + 8.95, 27.12, x1 - 1.6, FY + 9.2, 27.15, C.white, Mat.SmoothPlastic, true) :: Part, Enum.NormalId.Front, "KOOLA", Color3.fromRGB(80, 110, 160))
	end
	-- long room window: grille on the inside
	local lx0, lx1 = 29.9, 34.1
	for i = 1, 9 do
		local y = FY + 3.2 + i * 0.48
		box("Grille", lx0, y - 0.04, 0.65, lx1, y + 0.04, 0.75, Color3.fromRGB(215, 215, 210), Mat.Metal, true)
	end
	box("Grille", (lx0 + lx1) / 2 - 0.05, FY + 3.2, 0.75, (lx0 + lx1) / 2 + 0.05, FY + 8.0, 0.8, Color3.fromRGB(215, 215, 210), Mat.Metal, true)
end

local function books(name, fx0, fx1, z0, z1, y, h, seed)
	-- a row of book blocks on a shelf (no titles)
	local r = Random.new(seed)
	local cols = { Color3.fromRGB(190, 60, 50), Color3.fromRGB(60, 90, 160), Color3.fromRGB(230, 200, 80), Color3.fromRGB(240, 240, 235), Color3.fromRGB(80, 140, 90), Color3.fromRGB(150, 110, 170) }
	local alongZ = (z1 - z0) > (fx1 - fx0)
	local a, b = if alongZ then z0 else fx0, if alongZ then z1 else fx1
	local s = a
	while s < b - 0.3 do
		local w = r:NextNumber(0.18, 0.4)
		local bh = h * r:NextNumber(0.65, 0.95)
		local e = math.min(s + w, b)
		if alongZ then
			fb(name, fx0, fx1, s, e - 0.01, y, y + bh, cols[r:NextInteger(1, #cols)], Mat.SmoothPlastic, true)
		else
			fb(name, s, e - 0.01, z0, z1, y, y + bh, cols[r:NextInteger(1, #cols)], Mat.SmoothPlastic, true)
		end
		s = e
	end
end

local function furniture()
	-- hall: folding screen (plain paper panels), white drawer tower, bicycle, slippers
	for i = 0, 2 do
		local z0 = 24.3 + i * 1.2
		fb("ScreenFrame", 7.9, 8.15, z0, z0 + 1.15, 0, 6.2, C.brown, Mat.Wood)
		fb("ScreenPaper", 7.85, 7.9, z0 + 0.12, z0 + 1.03, 0.6, 5.9, Color3.fromRGB(200, 180, 140), Mat.Fabric, true)
	end
	fb("DrawerTower", 5.5, 6.9, 19.64, 20.69, 0, 4.2, C.white, Mat.Plastic)
	for i = 0, 3 do
		fb("DrawerHandle", 5.9, 6.5, 20.69, 20.75, 0.6 + i * 1.0, 0.75 + i * 1.0, Color3.fromRGB(80, 80, 85), Mat.Plastic, true)
	end
	fb("ClothesPile", 5.6, 6.8, 19.69, 20.59, 4.2, 4.6, Color3.fromRGB(120, 140, 170), Mat.Fabric, true)
	-- bicycle against the facade wall (two wheels, a frame)
	for _, fxw in { 3.9, 6.1 } do
		P("BikeWheel", Vector3.new(0.12, 2.2, 2.2), CFrame.new(41.8 - fxw, FY + 1.1, 27.6) * CFrame.Angles(0, math.rad(90), 0), C.black, Mat.Rubber, true, Enum.PartType.Cylinder)
	end
	P("BikeFrame", Vector3.new(2.4, 0.14, 0.14), CFrame.new(41.8 - 5.0, FY + 1.9, 27.4) * CFrame.Angles(0, 0, math.rad(8)), C.white, Mat.Metal, true)
	P("BikeSeat", Vector3.new(0.7, 0.15, 0.3), CFrame.new(41.8 - 5.6, FY + 2.6, 27.4), C.black, Mat.Fabric, true)
	fb("Slippers", 1.0, 1.7, 22.9, 23.2, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	fb("Slippers", 1.0, 1.7, 23.3, 23.6, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	-- hall ceiling lamp
	local lamp = fb("CeilingLamp", 3.6, 4.6, 23.4, 24.4, CEIL - 0.25, CEIL, Color3.fromRGB(250, 248, 240), Mat.Neon, true)
	if lamp then
		light(lamp, 16, 0.8, Color3.fromRGB(255, 244, 225))
	end
	-- corridor: pine bookshelf with books, a maroon folding chair, a rattan-back chair, a blank wall calendar
	local x = 0.14
	fb("Bookshelf", x, x + 1.0, 12.0, 12.15, 0, 6.6, C.pine, Mat.Wood)
	fb("Bookshelf", x, x + 1.0, 17.85, 18.0, 0, 6.6, C.pine, Mat.Wood)
	fb("BookshelfBack", x, x + 0.08, 12.15, 17.85, 0, 6.6, C.pine, Mat.Wood)
	for i = 0, 4 do
		local y = 0.1 + i * 1.6
		fb("Shelf", x + 0.08, x + 1.0, 12.15, 17.85, y, y + 0.1, C.pine, Mat.Wood)
		if i < 4 then
			books("Book", x + 0.2, x + 0.95, 12.2, 17.8, y + 0.1, 1.35, 30 + i)
		end
	end
	fb("ChairMaroon", 3.4, 4.6, 17.4, 18.6, 1.4, 1.6, Color3.fromRGB(110, 30, 40), Mat.Fabric)
	fb("ChairMaroonBack", 4.4, 4.6, 17.4, 18.6, 1.6, 3.4, Color3.fromRGB(110, 30, 40), Mat.Fabric)
	for _, p in { { 3.45, 17.45 }, { 4.45, 17.45 }, { 3.45, 18.45 }, { 4.45, 18.45 } } do
		fb("ChairLeg", p[1], p[1] + 0.1, p[2], p[2] + 0.1, 0, 1.4, Color3.fromRGB(40, 40, 42), Mat.Metal, true)
	end
	fb("CalendarPage", 4.7, 4.75, 11.0, 12.4, 4.5, 6.4, C.white, Mat.SmoothPlastic, true)
	for i = 0, 4 do
		fb("CalendarLine", 4.69, 4.7, 11.1, 12.3, 4.7 + i * 0.3, 4.72 + i * 0.3, Color3.fromRGB(170, 170, 170), Mat.SmoothPlastic, true)
	end
	-- long room: red vinyl chair, round white side table, wicker stool, bags, boxes, tall wardrobe, tube light, plain frame
	fb("RedChairSeat", 3.0, 4.5, 4.6, 6.1, 1.5, 1.8, Color3.fromRGB(175, 45, 40), Mat.Fabric)
	fb("RedChairBack", 3.0, 4.5, 6.0, 6.25, 1.8, 3.8, Color3.fromRGB(175, 45, 40), Mat.Fabric)
	for _, p in { { 3.05, 4.65 }, { 4.35, 4.65 }, { 3.05, 5.9 }, { 4.35, 5.9 } } do
		fb("ChairLeg", p[1], p[1] + 0.1, p[2], p[2] + 0.1, 0, 1.5, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	end
	P("SideTable", Vector3.new(0.15, 1.8, 1.8), CFrame.new(41.8 - 6.0, FY + 2.0, 5.3) * CFrame.Angles(0, 0, math.rad(90)), C.white, Mat.Plastic, false, Enum.PartType.Cylinder)
	fb("SideTableLeg", 5.95, 6.05, 5.25, 5.35, 0, 1.92, C.white, Mat.Plastic, true)
	P("WickerStool", Vector3.new(1.4, 1.2, 1.2), CFrame.new(41.8 - 7.8, FY + 0.6, 7.6) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 150, 90), Mat.Fabric, false, Enum.PartType.Cylinder)
	fb("ShoppingBag", 8.8, 10.0, 8.3, 9.6, 0, 1.6, Color3.fromRGB(200, 170, 120), Mat.Fabric, true)
	fb("ShoppingBag", 10.1, 11.0, 8.5, 9.6, 0, 1.3, C.white, Mat.Plastic, true)
	fb("Box", 12.8, 15.2, 0.75, 2.6, 0, 1.6, Color3.fromRGB(170, 130, 85), Mat.Cardboard)
	fb("Box", 13.2, 14.9, 0.9, 2.4, 1.6, 2.8, Color3.fromRGB(160, 120, 80), Mat.Cardboard)
	P("RedTub", Vector3.new(0.9, 1.4, 1.4), CFrame.new(41.8 - 11.8, FY + 0.45, 1.6) * CFrame.Angles(0, 0, math.rad(90)), C.red, Mat.Plastic, true, Enum.PartType.Cylinder)
	fb("TallWardrobe", 16.4, 19.25, 3.4, 6.6, 0, 7.4, Color3.fromRGB(55, 35, 25), Mat.Wood)
	fb("WardrobeHandle", 16.33, 16.4, 4.9, 5.1, 3.4, 4.0, Color3.fromRGB(180, 150, 80), Mat.Metal, true)
	local tube = fb("TubeLight", 19.2, 19.35, 1.6, 3.4, 7.6, 7.75, Color3.fromRGB(240, 245, 250), Mat.Neon, true)
	if tube then
		light(tube, 18, 0.7, Color3.fromRGB(230, 240, 255))
	end
	fb("TubeConduit", 19.25, 19.35, 2.45, 2.55, 7.75, CEIL, C.white, Mat.Plastic, true)
	local frame = P("PlainFrame", Vector3.new(2.4, 1.8, 0.08), CFrame.new(41.8 - 12.0, FY + 5.6, 9.71) * CFrame.Angles(0, 0, math.rad(3)), Color3.fromRGB(110, 80, 50), Mat.Wood, true)
	P("FrameMat", Vector3.new(2.0, 1.4, 0.02), CFrame.new(41.8 - 12.0, FY + 5.6, 9.66) * CFrame.Angles(0, 0, math.rad(3)), Color3.fromRGB(205, 195, 170), Mat.Fabric, true)
	local _ = frame
	-- bedroom
	-- bed against the far wall (fx 19.4), honey-yellow frame
	fb("BedBase", 13.6, 19.0, 14.0, 17.0, 0, 1.4, C.yellowWood, Mat.Wood)
	fb("Headboard", 19.0, 19.25, 13.9, 17.1, 0, 3.6, C.yellowWood, Mat.Wood)
	fb("Mattress", 13.7, 19.0, 14.05, 16.95, 1.4, 2.2, Color3.fromRGB(240, 236, 232), Mat.Fabric)
	local r = Random.new(928)
	for i = 0, 7 do
		local fx = r:NextNumber(14.0, 18.4)
		local z = r:NextNumber(14.2, 16.6)
		fb("SheetFlower", fx, fx + 0.25, z, z + 0.25, 2.2, 2.21, Color3.fromRGB(230, 150, 170), Mat.Fabric, true)
	end
	fb("Pillow", 17.6, 18.9, 14.4, 16.6, 2.2, 2.7, Color3.fromRGB(235, 228, 205), Mat.Fabric, true)
	fb("Blanket", 14.2, 16.4, 14.3, 16.2, 2.21, 2.75, Color3.fromRGB(120, 130, 175), Mat.Fabric, true)
	fb("Blanket", 15.0, 16.0, 14.8, 15.9, 2.75, 3.05, Color3.fromRGB(110, 120, 168), Mat.Fabric, true)
	-- air cooler with a square grid front
	fb("AirCooler", 12.0, 13.2, 14.0, 15.0, 0.25, 3.2, C.white, Mat.Plastic)
	fb("CoolerCastor", 12.1, 13.1, 14.1, 14.9, 0, 0.25, Color3.fromRGB(60, 60, 60), Mat.Rubber, true)
	for i = 0, 3 do
		fb("CoolerGrid", 12.2, 13.0, 15.0, 15.04, 0.8 + i * 0.55, 1.15 + i * 0.55, Color3.fromRGB(150, 155, 160), Mat.Plastic, true)
	end
	-- side table (pine top, white legs) with a clamp lamp and tissues
	fb("SideTop", 17.6, 19.3, 17.2, 18.6, 2.1, 2.25, C.pine, Mat.Wood)
	for _, p in { { 17.7, 17.3 }, { 19.1, 17.3 }, { 17.7, 18.4 }, { 19.1, 18.4 } } do
		fb("SideLeg", p[1], p[1] + 0.1, p[2], p[2] + 0.1, 0, 2.1, C.white, Mat.Metal, true)
	end
	fb("Tissues", 17.8, 18.4, 17.4, 17.8, 2.25, 2.6, Color3.fromRGB(240, 220, 110), Mat.Cardboard, true)
	P("ClampLamp", Vector3.new(0.5, 0.5, 0.5), CFrame.new(41.8 - 18.9, FY + 2.5, 18.3), C.white, Mat.Plastic, true, Enum.PartType.Ball)
	-- white X-braced shelf unit with pine shelves and books
	fb("ShelfPost", 18.0, 18.12, 18.9, 19.02, 0, 6.0, C.white, Mat.Metal)
	fb("ShelfPost", 19.15, 19.27, 18.9, 19.02, 0, 6.0, C.white, Mat.Metal)
	fb("ShelfPost", 18.0, 18.12, 22.3, 22.42, 0, 6.0, C.white, Mat.Metal)
	fb("ShelfPost", 19.15, 19.27, 22.3, 22.42, 0, 6.0, C.white, Mat.Metal)
	for i = 0, 3 do
		local y = 0.3 + i * 1.8
		fb("PineShelf", 18.0, 19.27, 19.02, 22.3, y, y + 0.1, C.pine, Mat.Wood)
		books("Book", 18.15, 19.15, 19.1, 22.2, y + 0.1, 1.4, 40 + i)
	end
	-- X braces on both sides of the unit (two layers so the bars never cross inside each other)
	local bl = math.sqrt(1.27 ^ 2 + 5.6 ^ 2) - 0.3
	local ba = math.atan2(1.27, 5.6)
	for _, z in { 18.86, 22.46 } do
		local sz = if z < 20 then -1 else 1
		P("ShelfBrace", Vector3.new(0.06, bl, 0.04), CFrame.new(41.8 - 18.635, FY + 3.0, z) * CFrame.Angles(0, 0, ba), C.white, Mat.Metal, true)
		P("ShelfBrace", Vector3.new(0.06, bl, 0.04), CFrame.new(41.8 - 18.635, FY + 3.0, z + sz * 0.04) * CFrame.Angles(0, 0, -ba), C.white, Mat.Metal, true)
	end
	-- dark brown wardrobe with a brass handle and a box on top
	fb("Wardrobe", 17.4, 19.25, 22.7, 26.0, 0, 6.8, Color3.fromRGB(70, 42, 28), Mat.Wood)
	fb("WardrobeHandle", 17.34, 17.4, 24.25, 24.45, 3.2, 3.8, Color3.fromRGB(190, 155, 80), Mat.Metal, true)
	fb("BoxOnTop", 17.6, 19.1, 23.0, 25.4, 6.8, 7.9, Color3.fromRGB(165, 125, 80), Mat.Cardboard, true)
	fb("BoxTape", 17.6, 19.1, 24.1, 24.3, 7.9, 7.92, Color3.fromRGB(235, 200, 60), Mat.Plastic, true)
	-- desk with a drawer pedestal, a dark monitor, keyboard, mouse, grey mat; a black tower; an office chair
	fb("DeskTop", 9.14, 11.4, 14.0, 18.2, 2.45, 2.65, C.brown, Mat.Wood)
	fb("DeskPedestal", 9.14, 11.2, 14.0, 15.4, 0, 2.45, Color3.fromRGB(62, 40, 28), Mat.Wood)
	fb("DeskLeg", 9.14, 9.34, 18.0, 18.2, 0, 2.45, C.brown, Mat.Wood)
	fb("DeskLeg", 11.2, 11.4, 18.0, 18.2, 0, 2.45, C.brown, Mat.Wood)
	for i = 0, 2 do
		fb("DrawerFront", 11.2, 11.24, 14.1, 15.3, 0.2 + i * 0.75, 0.85 + i * 0.75, Color3.fromRGB(78, 52, 36), Mat.Wood, true)
	end
	fb("DeskMat", 9.8, 11.2, 15.4, 17.6, 2.65, 2.67, Color3.fromRGB(110, 110, 112), Mat.Fabric, true)
	fb("MonitorStand", 9.3, 9.6, 16.3, 16.7, 2.65, 3.1, C.black, Mat.Metal, true)
	fb("Monitor", 9.25, 9.4, 15.0, 18.0, 3.1, 4.8, C.black, Mat.SmoothPlastic, true)
	fb("Keyboard", 10.2, 10.6, 15.6, 17.4, 2.67, 2.75, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	fb("Mouse", 10.3, 10.55, 17.6, 17.8, 2.67, 2.78, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	fb("Tower", 9.14, 10.6, 18.35, 19.15, 0, 2.2, Color3.fromRGB(28, 28, 30), Mat.SmoothPlastic)
	fb("OfficeSeat", 11.8, 13.2, 15.3, 16.7, 1.6, 1.85, C.black, Mat.Fabric)
	fb("OfficeBack", 13.0, 13.2, 15.3, 16.7, 1.85, 4.2, C.black, Mat.Fabric)
	fb("OfficeStem", 12.45, 12.55, 15.95, 16.05, 0.2, 1.6, Color3.fromRGB(60, 60, 62), Mat.Metal, true)
	fb("OfficeBase", 11.9, 13.1, 15.4, 16.6, 0, 0.2, C.black, Mat.Plastic, true)
	-- upright piano (dark wood) by the door wall, a blank whiteboard with green tape corners
	fb("Piano", 9.14, 10.69, 24.2, 27.6, 0, 3.9, Color3.fromRGB(58, 36, 26), Mat.Wood)
	fb("PianoKeys", 10.69, 11.49, 24.3, 27.5, 2.2, 2.35, Color3.fromRGB(245, 245, 240), Mat.SmoothPlastic)
	for i = 0, 10 do
		local z = 24.5 + i * 0.28
		fb("PianoBlackKey", 10.79, 11.24, z, z + 0.1, 2.35, 2.45, C.black, Mat.SmoothPlastic, true)
	end
	fb("PianoLid", 9.14, 10.69, 24.2, 27.6, 3.9, 3.95, Color3.fromRGB(58, 36, 26), Mat.Wood, true)
	fb("MusicStack", 9.3, 10.3, 25.0, 26.4, 3.95, 4.5, Color3.fromRGB(240, 238, 230), Mat.SmoothPlastic, true)
	fb("Whiteboard", 9.6, 12.0, 13.65, 13.72, 4.6, 6.4, C.white, Mat.SmoothPlastic, true)
	for _, p in { { 9.6, 4.6 }, { 11.7, 4.6 }, { 9.6, 6.1 }, { 11.7, 6.1 } } do
		fb("GreenTape", p[1], p[1] + 0.3, 13.72, 13.73, p[2], p[2] + 0.3, Color3.fromRGB(70, 160, 80), Mat.Plastic, true)
	end
	-- round wall light (white diffuser, blue-silver rim) on surface conduit, a square clock above it
	P("WallLightRim", Vector3.new(0.08, 1.6, 1.6), CFrame.new(41.8 - 15.5, FY + 6.4, 13.69) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(140, 165, 200), Mat.Metal, true, Enum.PartType.Cylinder)
	local wl = P("WallLight", Vector3.new(0.06, 1.2, 1.2), CFrame.new(41.8 - 15.5, FY + 6.4, 13.76) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(250, 250, 248), Mat.Neon, true, Enum.PartType.Cylinder)
	light(wl, 18, 0.8, Color3.fromRGB(245, 248, 255))
	fb("Conduit", 15.45, 15.55, 13.65, 13.73, 7.2, CEIL, C.white, Mat.Plastic, true)
	fb("ClockFrame", 16.2, 17.2, 13.65, 13.73, 7.6, 8.6, Color3.fromRGB(70, 45, 30), Mat.Wood, true)
	fb("ClockFace", 16.32, 17.08, 13.73, 13.75, 7.72, 8.48, C.white, Mat.SmoothPlastic, true)
	fb("ClockHand", 16.67, 16.73, 13.75, 13.76, 8.1, 8.4, C.black, Mat.SmoothPlastic, true)
	-- mint drop beam across the ceiling, board-panel joints on the bedroom walls, the twisted red/black wire
	fb("DropBeam", 9.05, 19.35, 20.9, 21.6, CEIL - 0.7, CEIL, C.mint, Mat.Plaster)
	for z = 16, 26, 4 do
		fb("PanelJoint", 19.33, 19.35, z, z + 0.06, 3.0, CEIL - 0.01, Color3.fromRGB(150, 170, 160), Mat.Plaster, true)
	end
	for fx = 12, 18, 4 do
		fb("PanelJoint", fx, fx + 0.06, 13.65, 13.67, 0.36, 4.5, Color3.fromRGB(150, 170, 160), Mat.Plaster, true)
	end
	fb("TwistedWire", 19.28, 19.33, 27.88, 27.93, 0.36, CEIL, Color3.fromRGB(120, 25, 25), Mat.Rubber, true)
	-- bedroom door: dark red-brown frame on the hall side, panelled leaf open into the bedroom
	box("DoorFrameRB", 33.45, FY, 20.15, 33.51, FY + 7.25, 20.4, C.frameRB, Mat.Wood, true)
	box("DoorFrameRB", 33.45, FY, 23.8, 33.51, FY + 7.25, 24.05, C.frameRB, Mat.Wood, true)
	box("DoorFrameRB", 33.45, FY + 7.0, 20.4, 33.51, FY + 7.25, 23.8, C.frameRB, Mat.Wood, true)
	fb("BedDoor", 9.14, 12.4, 23.85, 24.05, 0, 6.95, Color3.fromRGB(150, 115, 55), Mat.Wood)
	fb("BedDoorPanel", 9.5, 12.0, 23.80, 23.85, 3.9, 6.4, Color3.fromRGB(135, 100, 45), Mat.Wood, true)
	fb("BedDoorPanel", 9.5, 12.0, 23.80, 23.85, 0.6, 3.5, Color3.fromRGB(135, 100, 45), Mat.Wood, true)
	P("Knob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(41.8 - 12.2, FY + 3.3, 23.68), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
	-- two bags on hooks by the bedroom door (W3, bedroom side)
	fb("HookBag", 9.05, 9.5, 18.6, 19.4, 3.4, 4.6, C.black, Mat.Fabric, true)
end

local function container(): (Model, Model)
	local root = workspace:FindFirstChild("Yangon1to1") or workspace
	if root:IsA("Model") and root.ModelStreamingMode ~= Enum.ModelStreamingMode.Default then
		root = workspace -- (a Persistent / Atomic parent would send the inside to every client at once)
	end
	local walk = root:FindFirstChild("Walkable") or Instance.new("Folder")
	walk.Name = "Walkable"
	walk.Parent = root
	local old = walk:FindFirstChild(M.NAME)
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = M.NAME
	m:SetAttribute("OsmWay", 1430305132)
	m:SetAttribute("Source", "clips IMG_0927 / IMG_0928 (23 Nov 2026)")
	local ext = Instance.new("Model")
	ext.Name = "Exterior"
	ext.ModelStreamingMode = Enum.ModelStreamingMode.Default
	ext.Parent = m
	local ins = Instance.new("Model")
	ins.Name = "Inside"
	ins.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	ins.Parent = m
	m.Parent = walk
	return ext, ins
end

function M.build(): string
	count = 0
	local ext, ins = container()
	parent = ext
	exterior()
	task.wait()
	arch()
	groundUnits()
	carport()
	roof()
	task.wait()
	parent = ins
	stairWalls()
	stairs()
	task.wait()
	stairProps()
	for k = 1, FLOORS - 1 do
		if k ~= FLAT_K then
			lockedDoor(k, 41.8, 42.4, 1)
		end
		lockedDoor(k, 52.4, 53.0, -1)
	end
	ourDoor()
	task.wait()
	flatShell()
	rooms()
	windowsInside()
	furniture()
	return string.format("built %d parts (exterior %d, inside %d)", count, #ext:GetDescendants(), #ins:GetDescendants())
end

-- move the old 1-storey shell boxes to ServerStorage and keep the clients' kit detail out of the footprint + carport
function M.hideShell(): string
	local hidden = ServerStorage:FindFirstChild("YangonSiteHidden") or Instance.new("Folder")
	hidden.Name = "YangonSiteHidden"
	hidden.Parent = ServerStorage
	local keep = hidden:FindFirstChild(M.NAME) or Instance.new("Folder")
	keep.Name = M.NAME
	keep.Parent = hidden
	local ko = ReplicatedStorage.YgnKit:FindFirstChild("KeepOut")
	local moved = 0
	for _, pt in M.SHELL_POINTS do
		local parts = workspace:GetPartBoundsInBox(CFrame.new(pt), Vector3.new(2, 2, 2))
		for _, q in parts do
			if q:IsDescendantOf(workspace.Yangon1to1.Buildings.Shell) then
				q:SetAttribute("FromPath", q.Parent:GetFullName())
				local b = Instance.new("Part")
				b.Name = "MyittarNyunt_" .. moved
				b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch = true, false, false, false
				b.Transparency = 1
				b.Size = q.Size + Vector3.new(4, 8, 4)
				b.CFrame = q.CFrame
				b.Parent = ko
				q.Parent = keep
				moved += 1
			end
		end
	end
	if not ko:FindFirstChild("MyittarNyunt_carport") then
		local b = Instance.new("Part")
		b.Name = "MyittarNyunt_carport"
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch = true, false, false, false
		b.Transparency = 1
		b.Size = Vector3.new(44, 40, 16)
		b.CFrame = F * CFrame.new(31.2, 10, 36)
		b.Parent = ko
	end
	return "shell boxes moved: " .. moved
end

function M.undo(): string
	local walk = workspace:FindFirstChild("Walkable", true)
	local m = walk and walk:FindFirstChild(M.NAME)
	if m then
		m:Destroy()
	end
	local keep = ServerStorage:FindFirstChild("YangonSiteHidden") and ServerStorage.YangonSiteHidden:FindFirstChild(M.NAME)
	local n = 0
	for _, q in (if keep then keep:GetChildren() else {}) do
		local path = q:GetAttribute("FromPath")
		local cell = workspace.Yangon1to1.Buildings.Shell:FindFirstChild(string.match(path or "", "[^%.]+$") or "")
		if cell then
			q.Parent = cell
			n += 1
		end
	end
	for _, b in ReplicatedStorage.YgnKit.KeepOut:GetChildren() do
		if string.sub(b.Name, 1, 13) == "MyittarNyunt_" then
			b:Destroy()
		end
	end
	return "undone, shells back: " .. n
end

-- overlap check: parts of the model against each other (local boxes for frame-aligned parts, GetPartsInPart for the
-- rest) and against the map. Thin decor plates that only touch are fine; anything sharing > 0.02 studs in every axis is listed.
function M.check(): string
	local m = workspace:FindFirstChild(M.NAME, true)
	local parts = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
		end
	end
	local inv = F:Inverse()
	local aligned, other = {}, {}
	for _, p in parts do
		local rel = inv * p.CFrame
		local rx, ry, rz = rel:ToOrientation()
		local ok = p:IsA("Part") and p.Shape == Enum.PartType.Block and math.abs(rx) < 1e-3 and math.abs(rz) < 1e-3 and (math.abs(ry) < 1e-3 or math.abs(math.abs(ry) - math.pi / 2) < 1e-3)
		if ok then
			local s = p.Size
			if math.abs(math.abs(ry) - math.pi / 2) < 1e-3 then
				s = Vector3.new(s.Z, s.Y, s.X)
			end
			table.insert(aligned, { p = p, lo = rel.Position - s / 2, hi = rel.Position + s / 2 })
		else
			table.insert(other, p)
		end
	end
	local bad = {}
	local tol = 0.02
	for i = 1, #aligned do
		local a = aligned[i]
		for j = i + 1, #aligned do
			local b = aligned[j]
			if a.lo.X < b.hi.X - tol and b.lo.X < a.hi.X - tol and a.lo.Y < b.hi.Y - tol and b.lo.Y < a.hi.Y - tol and a.lo.Z < b.hi.Z - tol and b.lo.Z < a.hi.Z - tol then
				table.insert(bad, a.p.Name .. "~" .. b.p.Name .. string.format(" @%.1f,%.1f,%.1f", (a.lo.X + a.hi.X) / 2, (a.lo.Y + a.hi.Y) / 2, (a.lo.Z + a.hi.Z) / 2))
			end
		end
		if i % 400 == 0 then
			task.wait()
		end
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { m }
	local seen = {}
	for _, p in other do
		for _, q in workspace:GetPartsInPart(p, op) do
			local key = if p:GetDebugId() < q:GetDebugId() then p:GetDebugId() .. q:GetDebugId() else q:GetDebugId() .. p:GetDebugId()
			if q ~= p and not seen[key] then
				seen[key] = true
				table.insert(bad, "(rot) " .. p.Name .. "~" .. q.Name .. string.format(" @%.1f,%.1f,%.1f", (inv * p.CFrame).X, (inv * p.CFrame).Y, (inv * p.CFrame).Z))
			end
		end
	end
	-- against the map (everything outside the model; terrain is not a part)
	local op2 = OverlapParams.new()
	op2.FilterType = Enum.RaycastFilterType.Exclude
	op2.FilterDescendantsInstances = { m, ReplicatedStorage }
	local world = {}
	for _, p in m.Exterior:GetChildren() do
		if p:IsA("BasePart") and p.Size.Magnitude > 3 then
			for _, q in workspace:GetPartsInPart(p, op2) do
				world[q:GetFullName()] = true
			end
		end
	end
	local wl = {}
	for k in world do
		table.insert(wl, k)
	end
	return string.format("%d parts, %d overlaps inside, %d map parts touched\n%s\nMAP: %s", #parts, #bad, #wl, table.concat(bad, "\n", 1, math.min(#bad, 60)), table.concat(wl, ", ", 1, math.min(#wl, 20)))
end

return M
