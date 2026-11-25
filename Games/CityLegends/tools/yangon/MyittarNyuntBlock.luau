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
	cream = Color3.fromRGB(218, 206, 160), wing = Color3.fromRGB(190, 182, 148), plinth = Color3.fromRGB(118, 116, 104),
	mould = Color3.fromRGB(112, 116, 98), band = Color3.fromRGB(214, 210, 186),
	stair = Color3.fromRGB(220, 210, 165), ceil = Color3.fromRGB(235, 235, 230), step = Color3.fromRGB(125, 125, 120),
	nose = Color3.fromRGB(226, 222, 205), rail = Color3.fromRGB(30, 30, 30), landing = Color3.fromRGB(172, 168, 158),
	dirt = Color3.fromRGB(88, 84, 74), wood = Color3.fromRGB(160, 115, 60), green = Color3.fromRGB(78, 118, 98),
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
local ARCH = { 43.0, 47.4, 6.3, 2.2 } -- s0, s1, rectangle top, radius

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
	-- (no drip plates: flat dark plates read as holes in Play; the stained render already carries the mould)
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
		P("ACFan", Vector3.new(0.05, 1.3, 1.3), cf * CFrame.new(0.3, 0, 1.24) * CFrame.Angles(0, math.rad(90), 0), C.galv, Mat.Metal, true, Enum.PartType.Cylinder)
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
			local ours = k == FLAT_K and (f.id == "AB" or ((f.id == "FA" or f.id == "BC") and s < 42))
			local glass = if ours then C.frost else C.green
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
		variant(box("ArchFill", s0, y0, 28.0, cx - hw, y1, 28.6, C.cream, Mat.Plaster), "YgnRenderStained")
		variant(box("ArchFill", cx + hw, y0, 28.0, s1, y1, 28.6, C.cream, Mat.Plaster), "YgnRenderStained")
	end
	-- trim: 9 short segments round the arc + two jamb strips, standing 0.15 proud
	for i = 0, 8 do
		local a = math.rad(i * 180 / 9 + 10)
		local px, py = cx + math.cos(a) * (r + 0.15), rTop + math.sin(a) * (r + 0.15)
		P("ArchTrim", Vector3.new(0.32, 0.5, 0.13), CFrame.new(px, py, 28.685) * CFrame.Angles(0, 0, a), C.band, Mat.Plaster, true)
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
		box("FoldGate", x - 0.06, 0.05, 28.3, x + 0.06, 7.9, 28.375, C.gateB, Mat.Metal, true)
	end
	local bay = (x1 - x0) / n
	for i = 0, n - 1 do
		local cx = x0 + bay * (i + 0.5)
		for tier = 0, 2 do
			local y = 1.4 + tier * 2.6
			local len = math.sqrt(bay * bay + 2.4 * 2.4) - 0.2
			local ang = math.atan2(2.4, bay)
			P("FoldGateX", Vector3.new(len, 0.07, 0.04), CFrame.new(cx, y, 28.4) * CFrame.Angles(0, 0, ang), C.gateB, Mat.Metal, true)
			P("FoldGateX", Vector3.new(len, 0.07, 0.04), CFrame.new(cx, y, 28.445) * CFrame.Angles(0, 0, -ang), C.gateB, Mat.Metal, true)
		end
	end
	box("FoldGateRail", x0, 7.92, 28.18, x1, 8.0, 28.46, C.gateB, Mat.Metal, true)
	-- the white notice on it (generic: "no parking")
	local sign = box("Notice", 31, 5.6, 28.47, 34, 7.0, 28.51, C.white, Mat.SmoothPlastic, true)
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
	local roof = P("CarportRoof", Vector3.new(42.4, 0.12, len), CFrame.new(31.2, (yW + yF) / 2 + 0.3, (z0 + z1) / 2) * CFrame.Angles(slope, 0, 0), C.zinc, Mat.Metal)
	variant(roof, "YgnCorrugatedZinc")
	roof.Size = Vector3.new(42.2, 0.12, len - 0.05)
	-- front beam (truss top chord), bottom chord, Z diagonals, posts
	box("TrussTop", 10.2, yF - 0.35, 42.3, 52.2, yF, 42.6, C.truss, Mat.Metal)
	box("TrussBottom", 10.2, yF - 1.6, 42.3, 52.2, yF - 1.3, 42.6, C.truss, Mat.Metal)
	local bays = 14
	local bw = (52.2 - 10.2) / bays
	for i = 0, bays - 1 do
		local cx = 10.2 + bw * (i + 0.5)
		local dy = 0.72
		local l = math.sqrt(bw * bw + dy * dy) - 0.15
		P("TrussDiag", Vector3.new(l, 0.18, 0.2), CFrame.new(cx, yF - 0.825, 42.45) * CFrame.Angles(0, 0, (if i % 2 == 0 then 1 else -1) * math.atan2(dy, bw)), C.truss, Mat.Metal, true)
	end
	for _, x in { 10.4, 24.4, 38.4, 52.0 } do
		box("CarportPost", x - 0.2, 0, 42.25, x + 0.2, yF - 1.6, 42.65, C.truss, Mat.Metal)
	end
	-- rafters from wall to beam
	for _, x in { 16, 24.4, 31.2, 38.4, 45.5 } do
		P("Rafter", Vector3.new(0.18, 0.3, len - 0.6), CFrame.new(x, (yW + yF) / 2 + 0.06, (z0 + z1) / 2 - 0.1) * CFrame.Angles(slope, 0, 0), C.truss, Mat.Metal, true)
	end
	-- scalloped brown edging where the roof meets the wall
	for x = 11, 51.5, 1.5 do
		P("Scallop", Vector3.new(0.7, 1.2, 1.2), CFrame.new(x, 10.15, 29.6), Color3.fromRGB(150, 88, 62), Mat.SmoothPlastic, true, Enum.PartType.Cylinder)
	end
	-- blue PVC drainpipe down beside the arch and across above it
	box("PipeBlue", 48.9, 0.2, 28.64, 49.25, 8.55, 28.99, Color3.fromRGB(150, 185, 205), Mat.SmoothPlastic, true)
	box("PipeBlue", 47.9, 8.55, 28.64, 49.25, 8.9, 28.99, Color3.fromRGB(150, 185, 205), Mat.SmoothPlastic, true)
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
	-- (painted inside walls: SmoothPlastic; the place's Plaster override reads as sand and the stained variant as grey)
	wall("Z", "StairWall", 11.0, 28.0, 41.8, 42.4, 0, 49.4, opensW, C.stair, Mat.SmoothPlastic, false)
	wall("Z", "StairWall", 11.0, 28.0, 52.4, 53.0, 0, 49.4, opensE, C.stair, Mat.SmoothPlastic, false)
	box("StairWall", 42.4, 0, 11.0, 52.4, 49.4, 11.6, C.stair, Mat.SmoothPlastic)
	box("StairGround", 42.4, -1.9, 11.6, 52.4, 0, 28.0, C.landing, Mat.Concrete)
	for k = 1, FLOORS - 1 do
		box("Landing", 42.4, k * H - 0.6, LAND_Z, 52.4, k * H, 28.0, C.landing, Mat.Concrete)
		box("Soffit", 42.4, k * H - 0.64, LAND_Z, 52.4, k * H - 0.6, 28.0, C.ceil, Mat.SmoothPlastic, true)
	end
	for k = 0, FLOORS - 2 do
		local y = k * H + RISE
		box("HalfLanding", 42.4, y - 0.6, SZ0, 52.4, y, HALF_Z, C.landing, Mat.Concrete)
		box("Soffit", 42.4, y - 0.64, SZ0, 52.4, y - 0.6, HALF_Z, C.ceil, Mat.SmoothPlastic, true)
	end
	-- the facade's inside face in the stair gets the stair paint (a 0.01 sheet; the arch and the glass strip left open)
	wall("X", "StairFacadePaint", 42.4, 52.4, 27.99, 28.0, 0, 49.4, { { ARCH[1], ARCH[2], 0, ARCH[3] + ARCH[4] }, { STRIP[1], STRIP[2], 10.6, 49.4 } }, C.stair, Mat.SmoothPlastic, true)
	-- dirt band along the walls of each landing (plates on the wall faces)
	for k = 0, FLOORS - 1 do
		local y = k * H
		box("DirtBand", 52.35, y, LAND_Z, 52.4, y + 0.45, DOOR[1] - 0.1, C.dirt, Mat.Plaster, true)
		if k > 0 then
			box("DirtBand", 42.8, y, 27.95, 47.8, y + 0.45, 27.99, C.dirt, Mat.Plaster, true)
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
	w.Material = Mat.SmoothPlastic
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
	P("ParapetCap", Vector3.new(pr[2] - pr[1], cap, L), CFrame.new(c) * CFrame.Angles(dir * ang * -1, 0, 0), C.stair, Mat.SmoothPlastic)
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
	box("StoreInfill", 42.4, 7.2, 23.8, 46.8, 8.75, 24.0, C.stair, Mat.SmoothPlastic)
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
	P("Broom", Vector3.new(0.12, 4.6, 0.12), CFrame.new(42.95, H + RISE + 2.4, 12.4) * CFrame.Angles(0.15, 0, 0), Color3.fromRGB(230, 120, 30), Mat.Plastic, true)
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
	-- door leaf open 90 degrees inward, standing against the stair wall north of the opening (hinge at its north jamb)
	local leaf = box("OurDoor", 41.45, y + 0.05, 20.85, 41.65, y + DOOR[3] - 0.05, DOOR[1] - 0.05, C.honey, Mat.Wood)
	if leaf then
		leaf.Reflectance = 0.06
	end
	-- arch panel + two rectangular panels on the leaf's room face (-x)
	box("DoorPanel", 41.39, y + 4.2, 21.3, 41.45, y + 6.4, 23.8, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	box("DoorPanel", 41.39, y + 0.6, 21.3, 41.45, y + 3.8, 22.4, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	box("DoorPanel", 41.39, y + 0.6, 22.7, 41.45, y + 3.8, 23.8, Color3.fromRGB(176, 118, 44), Mat.Wood, true)
	P("Knob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(41.22, y + 3.3, 21.1), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
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
	P("TwigBundle", Vector3.new(1.2, 0.3, 0.3), CFrame.new(43.0, y + 5.6, 26.75) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 85, 60), Mat.Wood, true, Enum.PartType.Cylinder)
	local r = Random.new(1106)
	for i = 0, 6 do
		-- dried leaves hung in thin layers (each its own z slice, turned only in its plane)
		P("DryLeaf", Vector3.new(0.45, 0.6, 0.05), CFrame.new(43.0 + r:NextNumber(-0.25, 0.25), y + 5.3 + r:NextNumber(0, 0.6), 26.95 + i * 0.1) * CFrame.Angles(0, 0, r:NextNumber(-0.8, 0.8)), Color3.fromRGB(125, 95, 65), Mat.Fabric, true)
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

local function lining(name, fx0, fx1, z0, z1, color, opens)
	local d = 0.05
	-- walls along fz (at fx0 and fx1): axis Z
	wall("Z", name, z0, z1, 41.8 - fx0 - d, 41.8 - fx0, FY, FY + CEIL, opens.fx0 or {}, color, Mat.SmoothPlastic, true)
	wall("Z", name, z0, z1, 41.8 - fx1, 41.8 - fx1 + d, FY, FY + CEIL, opens.fx1 or {}, color, Mat.SmoothPlastic, true)
	wall("X", name, 41.8 - fx1 + d, 41.8 - fx0 - d, z0, z0 + d, FY, FY + CEIL, opens.z0 or {}, color, Mat.SmoothPlastic, true)
	wall("X", name, 41.8 - fx1 + d, 41.8 - fx0 - d, z1 - d, z1, FY, FY + CEIL, opens.z1 or {}, color, Mat.SmoothPlastic, true)
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

-- ===== the flat, owner's plan (26 Nov, vault refs_2026-11-26_owner_flat_layout): floor 3, x 0.6..41.8 =====
-- North of the hall wall (z 12.3..12.9), west to east: back room W, bedroom M, dining, kitchen (NE), bathroom.
-- South of it: the hall strip, the yellow (gaming) room x 9.2..24.0 with its door on the hall, the shrine table in the
-- south-west corner, and the living room up to the stair wall, where the front door is.
local function xb(name, x0, x1, z0, z1, y0, y1, color, mat, deco)
	return box(name, x0, FY + y0, z0, x1, FY + y1, z1, color, mat, deco)
end
local function xp(name, size, x, y, z, color, mat, deco, shape, rot)
	return P(name, size, CFrame.new(x, FY + y, z) * (rot or CFrame.new()), color, mat, deco, shape)
end
local VCYL = CFrame.Angles(0, 0, math.rad(90)) -- a Cylinder standing up

-- a rectangular room's lining + skirting; opens e / w = z ranges on its east (x1) / west (x0) side, n / s = x ranges
-- on its z0 / z1 side; entries { a, b, y0?, y1? } (no y = full height)
local function room(name, x0, x1, z0, z1, color, opens, noSkirt)
	local function oz(list)
		local o = {}
		for _, r in list or {} do
			table.insert(o, { r[1], r[2], FY + (r[3] or 0), FY + (r[4] or CEIL + 1) })
		end
		return o
	end
	lining(name, 41.8 - x1, 41.8 - x0, z0, z1, color, { fx0 = oz(opens.e), fx1 = oz(opens.w), z0 = oz(opens.n), z1 = oz(opens.s) })
	if not noSkirt then
		local function g(list)
			local o = {}
			for _, r in list or {} do
				if (r[3] or 0) < 0.35 then
					table.insert(o, { r[1] - 0.15, r[2] + 0.15, FY, FY + 1 })
				end
			end
			return o
		end
		skirting(41.8 - x1, 41.8 - x0, z0, z1, { fx0 = g(opens.e), fx1 = g(opens.w), z0 = g(opens.n), z1 = g(opens.s) })
	end
end

local WY0, WY1 = 3.2, 8.0
local function flatShell()
	-- floor boards (the yellow room lighter, bathroom and kitchen tiled), ceiling
	for _, r in {
		{ 8.6, 24.6, 17.8, 28.0, C.floorB, Mat.WoodPlanks }, { 0.6, 8.6, 17.8, 28.0, C.floorD, Mat.WoodPlanks },
		{ 24.6, 41.8, 17.8, 28.0, C.floorD, Mat.WoodPlanks }, { 0.6, 38.0, 6.4, 17.8, C.floorD, Mat.WoodPlanks },
		{ 38.0, 41.8, 12.3, 17.8, C.floorD, Mat.WoodPlanks }, { 0.6, 35.0, 0.6, 6.4, C.floorD, Mat.WoodPlanks },
		{ 38.0, 41.8, 6.4, 12.3, Color3.fromRGB(150, 155, 150), Mat.Slate }, { 35.0, 41.8, 0.6, 6.4, Color3.fromRGB(205, 200, 190), Mat.SmoothPlastic },
	} do
		local f = xb("FloorBoards", r[1], r[2], r[3], r[4], -0.6, 0, r[5], r[6])
		if f and r[6] == Mat.WoodPlanks then
			f.Reflectance = 0.04
		end
	end
	xb("Ceiling", 0.6, 41.8, 0.6, 28.0, CEIL, CEIL + 0.6, C.ceil, Mat.SmoothPlastic)
	xb("FlatWall", 41.8, 42.4, 0.6, 11.0, 0, CEIL, C.hall, Mat.SmoothPlastic) -- below the stair core's end
	local Y0, Y1 = FY, FY + CEIL
	local function d(a, b, h)
		return { a, b, FY, FY + (h or 7.0) }
	end
	wall("X", "WallHall", 0.6, 41.8, 12.3, 12.9, Y0, Y1, { d(8.2, 11.0), d(16.8, 19.6), d(28.2, 33.2, 7.4) }, C.hall, Mat.SmoothPlastic)
	xb("WallRooms", 12.1, 12.7, 0.6, 12.3, 0, CEIL, C.hall, Mat.SmoothPlastic)
	xb("WallRooms", 24.5, 25.1, 0.6, 12.3, 0, CEIL, C.hall, Mat.SmoothPlastic)
	xb("WallKitchen", 34.4, 35.0, 0.6, 6.0, 0, CEIL, C.hall, Mat.SmoothPlastic)
	wall("Z", "WallBath", 6.4, 12.3, 38.0, 38.6, Y0, Y1, { d(8.0, 11.0) }, C.hall, Mat.SmoothPlastic)
	xb("WallBath", 38.6, 41.8, 6.4, 7.0, 0, CEIL, C.hall, Mat.SmoothPlastic)
	wall("X", "WallYellow", 8.6, 24.6, 17.2, 17.8, Y0, Y1, { d(19.0, 22.4) }, C.hall, Mat.SmoothPlastic)
	xb("WallYellow", 8.6, 9.2, 17.8, 28.0, 0, CEIL, C.hall, Mat.SmoothPlastic)
	xb("WallYellow", 24.0, 24.6, 17.8, 28.0, 0, CEIL, C.hall, Mat.SmoothPlastic)
end

local function rooms()
	local function w(a, b)
		return { a, b, WY0, WY1 }
	end
	room("LinBack", 0.6, 12.1, 0.6, 12.3, C.lroom, { n = { w(3.9, 8.1) }, w = { w(6.9, 11.1) }, s = { { 8.2, 11.0, 0, 7.0 } } })
	room("LinRoomM", 12.7, 24.5, 0.6, 12.3, C.blue, { n = { w(13.9, 18.1) }, s = { { 16.8, 19.6, 0, 7.0 } } })
	room("LinYellow", 9.2, 24.0, 17.8, 28.0, C.mint, { n = { { 19.0, 22.4, 0, 7.0 } }, s = { w(12.9, 17.1) } })
	room("LinBath", 38.6, 41.8, 7.0, 12.3, Color3.fromRGB(120, 160, 140), { w = { { 8.0, 11.0, 0, 7.0 } } }, true)
	-- the open rooms: only the outer walls and the stair wall get a painted sheet (inner walls are painted parts)
	local L = 0.05
	wall("X", "LinOpen", 25.1, 34.4, 0.6, 0.6 + L, FY, FY + CEIL, { { 29.9, 34.1, FY + WY0, FY + WY1 } }, C.hall, Mat.SmoothPlastic, true)
	wall("X", "LinOpen", 35.0, 41.8, 0.6, 0.6 + L, FY, FY + CEIL, {}, C.hall, Mat.SmoothPlastic, true)
	wall("Z", "LinOpen", 12.9, 27.95, 0.6, 0.6 + L, FY, FY + CEIL, { { 17.5, 21.7, FY + WY0, FY + WY1 } }, C.hall, Mat.SmoothPlastic, true)
	wall("X", "LinOpen", 0.6 + L, 8.6, 27.95, 28.0, FY, FY + CEIL, { { 2.9, 7.1, FY + WY0, FY + WY1 } }, C.hall, Mat.SmoothPlastic, true)
	wall("X", "LinOpen", 24.6, 41.75, 27.95, 28.0, FY, FY + CEIL, { { 25.65, 29.85, FY + WY0, FY + WY1 }, { 34.9, 39.1, FY + WY0, FY + WY1 } }, C.hall, Mat.SmoothPlastic, true)
	wall("Z", "LinOpen", 12.9, 28.0, 41.75, 41.8, FY, FY + CEIL, { { DOOR[1], DOOR[2], FY, FY + DOOR[3] } }, C.hall, Mat.SmoothPlastic, true)
	-- the yellow room's window wall is light blue (a second sheet over the mint)
	wall("X", "LinYellowBlue", 9.33, 23.87, 27.93, 27.95, FY + 0.35, FY + CEIL, { { 12.9, 17.1, FY + WY0, FY + WY1 } }, C.blue, Mat.SmoothPlastic, true)
end

-- window grilles inside every flat window: horizontal bars in the lining's hole, one upright behind them
local function grilles()
	local gc = Color3.fromRGB(215, 215, 210)
	local function rowX(x0, x1, zb0, zb1, zu0, zu1)
		for i = 1, 9 do
			local y = WY0 + i * 0.48
			xb("Grille", x0, x1, zb0, zb1, y - 0.04, y + 0.04, gc, Mat.Metal, true)
		end
		local m = (x0 + x1) / 2
		xb("Grille", m - 0.05, m + 0.05, zu0, zu1, WY0, WY1, gc, Mat.Metal, true)
	end
	for _, s in { { 3.9, 8.1 }, { 13.9, 18.1 }, { 29.9, 34.1 } } do
		rowX(s[1], s[2], 0.65, 0.75, 0.75, 0.8)
	end
	for _, s in { { 2.9, 7.1 }, { 12.9, 17.1 }, { 25.65, 29.85 }, { 34.9, 39.1 } } do
		rowX(s[1], s[2], 27.85, 27.95, 27.8, 27.85)
	end
	for _, s in { { 6.9, 11.1 }, { 17.5, 21.7 } } do
		for i = 1, 9 do
			local y = WY0 + i * 0.48
			xb("Grille", 0.65, 0.75, s[1], s[2], y - 0.04, y + 0.04, gc, Mat.Metal, true)
		end
		local m = (s[1] + s[2]) / 2
		xb("Grille", 0.75, 0.8, m - 0.05, m + 0.05, WY0, WY1, gc, Mat.Metal, true)
	end
end

local function booksX(x0, x1, z0, z1, y, h, seed)
	books("Book", 41.8 - x1, 41.8 - x0, z0, z1, y, h, seed)
end

local function chair(x, z, face, color, mat)
	-- a simple chair: seat, 4 legs, back on the side away from "face" (+1: faces +x, -1: -x, 2: +z, -2: -z)
	xb("ChairSeat", x - 0.55, x + 0.55, z - 0.55, z + 0.55, 1.45, 1.65, color, mat)
	for _, o in { { -0.5, -0.5 }, { 0.4, -0.5 }, { -0.5, 0.4 }, { 0.4, 0.4 } } do
		xb("ChairLeg", x + o[1], x + o[1] + 0.1, z + o[2], z + o[2] + 0.1, 0, 1.45, Color3.fromRGB(60, 45, 35), Mat.Wood, true)
	end
	if face == 1 then
		xb("ChairBack", x - 0.55, x - 0.4, z - 0.55, z + 0.55, 1.65, 3.4, color, mat)
	elseif face == -1 then
		xb("ChairBack", x + 0.4, x + 0.55, z - 0.55, z + 0.55, 1.65, 3.4, color, mat)
	elseif face == 2 then
		xb("ChairBack", x - 0.55, x + 0.55, z - 0.55, z - 0.4, 1.65, 3.4, color, mat)
	else
		xb("ChairBack", x - 0.55, x + 0.55, z + 0.4, z + 0.55, 1.65, 3.4, color, mat)
	end
end

local function doorLeaf(name, x0, x1, z0, z1, color)
	xb(name, x0, x1, z0, z1, 0.05, 6.95, color, Mat.Wood)
end

local function furniture()
	local SP, WD = Mat.SmoothPlastic, Mat.Wood
	local gold = Color3.fromRGB(212, 172, 60)
	-- ---------- living room ----------
	-- TV on a low cabinet against the yellow room's wall, facing the front door; the couch along the same wall
	xb("TVCabinet", 24.6, 26.0, 21.0, 25.6, 0, 1.8, Color3.fromRGB(80, 50, 32), WD)
	xb("TV", 25.1, 25.25, 21.3, 25.3, 1.8, 4.6, C.black, SP)
	xb("CouchBase", 24.6, 27.0, 17.9, 20.8, 0, 1.4, Color3.fromRGB(95, 100, 118), SP)
	xb("CouchBack", 24.6, 25.2, 17.9, 20.8, 1.4, 3.0, Color3.fromRGB(95, 100, 118), SP)
	xb("CouchArm", 25.2, 27.0, 17.9, 18.3, 1.4, 2.2, Color3.fromRGB(95, 100, 118), SP)
	xb("CouchArm", 25.2, 27.0, 20.4, 20.8, 1.4, 2.2, Color3.fromRGB(95, 100, 118), SP)
	-- treadmill in the far (north-east) corner, away from the door
	xb("Treadmill", 37.4, 41.5, 13.3, 15.3, 0, 0.55, Color3.fromRGB(55, 58, 62), SP)
	xb("TreadmillBelt", 37.8, 41.1, 13.6, 15.0, 0.55, 0.6, C.black, Mat.Rubber, true)
	xb("TreadmillPost", 40.9, 41.1, 13.4, 13.6, 0.55, 3.8, Color3.fromRGB(70, 72, 76), Mat.Metal)
	xb("TreadmillPost", 40.9, 41.1, 15.0, 15.2, 0.55, 3.8, Color3.fromRGB(70, 72, 76), Mat.Metal)
	xb("TreadmillConsole", 40.6, 41.2, 13.4, 15.2, 3.8, 4.3, C.black, SP)
	-- the entrance things from the clip: folding screen (plain panels), white drawer tower, bicycle, slippers
	for i = 0, 2 do
		local z0 = 24.6 + i * 1.1
		xb("ScreenFrame", 35.6, 35.85, z0, z0 + 1.05, 0, 6.2, C.brown, WD)
		xb("ScreenPaper", 35.55, 35.6, z0 + 0.12, z0 + 0.93, 0.6, 5.9, Color3.fromRGB(200, 180, 140), SP, true)
	end
	xb("DrawerTower", 40.2, 41.6, 17.0, 18.05, 0, 4.2, C.white, Mat.Plastic)
	for i = 0, 3 do
		xb("DrawerHandle", 40.14, 40.2, 17.25, 17.8, 0.6 + i * 1.0, 0.75 + i * 1.0, Color3.fromRGB(80, 80, 85), Mat.Plastic, true)
	end
	xb("ClothesPile", 40.3, 41.5, 17.1, 17.95, 4.2, 4.6, Color3.fromRGB(120, 140, 170), SP, true)
	for _, x in { 31.5, 33.7 } do
		xp("BikeWheel", Vector3.new(0.12, 2.2, 2.2), x, 1.1, 27.6, C.black, Mat.Rubber, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	end
	xp("BikeFrame", Vector3.new(2.4, 0.14, 0.14), 32.6, 1.9, 27.4, C.white, Mat.Metal, true, nil, CFrame.Angles(0, 0, math.rad(8)))
	xp("BikeSeat", Vector3.new(0.7, 0.15, 0.3), 33.2, 2.6, 27.4, C.black, SP, true)
	xb("Slippers", 39.5, 40.2, 25.0, 25.3, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	xb("Slippers", 39.5, 40.2, 25.4, 25.7, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	local lamp = xb("CeilingLamp", 32.5, 33.5, 19.5, 20.5, CEIL - 0.25, CEIL, Color3.fromRGB(250, 248, 240), Mat.Neon, true)
	if lamp then
		light(lamp, 20, 0.8, Color3.fromRGB(255, 244, 225))
	end
	-- the shrine table in the south-west corner (generic: a seated figure and two small stupas, flowers)
	xb("ShrineTable", 0.75, 5.2, 25.4, 27.75, 0, 2.8, Color3.fromRGB(85, 30, 25), WD)
	xb("ShrineTier", 0.75, 5.2, 26.9, 27.75, 2.8, 3.6, Color3.fromRGB(85, 30, 25), WD)
	xb("ShrineFigureBase", 2.4, 3.5, 27.0, 27.7, 3.6, 3.85, gold, SP).Reflectance = 0.15
	xb("ShrineFigure", 2.6, 3.3, 27.1, 27.6, 3.85, 4.55, gold, SP).Reflectance = 0.15
	xp("ShrineFigureHead", Vector3.new(0.42, 0.42, 0.42), 2.95, 4.76, 27.35, gold, SP, true, Enum.PartType.Ball)
	for _, x in { 1.4, 4.4 } do
		xp("StupaBase", Vector3.new(0.25, 0.6, 0.6), x, 3.725, 27.35, gold, SP, true, Enum.PartType.Cylinder, VCYL)
		xp("StupaBell", Vector3.new(0.5, 0.5, 0.5), x, 4.1, 27.35, gold, SP, true, Enum.PartType.Ball)
		xp("StupaSpire", Vector3.new(0.55, 0.12, 0.12), x, 4.63, 27.35, gold, SP, true, Enum.PartType.Cylinder, VCYL)
	end
	for _, x in { 1.3, 4.6 } do
		xp("Vase", Vector3.new(0.6, 0.4, 0.4), x, 3.1, 26.2, Color3.fromRGB(40, 110, 70), SP, true, Enum.PartType.Cylinder, VCYL)
		xp("Flowers", Vector3.new(0.5, 0.5, 0.5), x, 3.67, 26.2, Color3.fromRGB(240, 200, 60), SP, true, Enum.PartType.Ball)
	end
	-- ---------- hall ----------
	xb("Bookshelf", 10.0, 10.15, 16.15, 17.15, 0, 6.6, C.pine, WD)
	xb("Bookshelf", 15.85, 16.0, 16.15, 17.15, 0, 6.6, C.pine, WD)
	xb("BookshelfBack", 10.15, 15.85, 17.07, 17.15, 0, 6.6, C.pine, WD)
	for i = 0, 4 do
		local y = 0.1 + i * 1.6
		xb("Shelf", 10.15, 15.85, 16.15, 17.07, y, y + 0.1, C.pine, WD)
		if i < 4 then
			booksX(10.2, 15.8, 16.2, 17.0, y + 0.1, 1.35, 30 + i)
		end
	end
	chair(3.1, 13.9, -2, Color3.fromRGB(110, 30, 40), SP) -- the maroon folding chair
	chair(6.2, 13.9, -2, Color3.fromRGB(150, 110, 60), WD) -- the rattan-back chair
	xb("Towel", 5.65, 6.75, 14.45, 14.5, 2.2, 3.3, Color3.fromRGB(220, 120, 50), SP, true)
	xb("CalendarPage", 2.5, 3.9, 12.9, 12.95, 4.5, 6.4, C.white, SP, true)
	for i = 0, 4 do
		xb("CalendarLine", 2.6, 3.8, 12.95, 12.96, 4.7 + i * 0.3, 4.72 + i * 0.3, Color3.fromRGB(170, 170, 170), SP, true)
	end
	-- ---------- back room W (the clip's long dark room: storage and clutter) ----------
	xb("TallWardrobe", 0.75, 3.65, 0.75, 2.6, 0, 7.4, Color3.fromRGB(55, 35, 25), WD)
	xb("WardrobeHandle", 3.65, 3.71, 1.6, 1.8, 3.4, 4.0, Color3.fromRGB(180, 150, 80), Mat.Metal, true)
	xb("Box", 8.8, 11.2, 0.75, 2.6, 0, 1.6, Color3.fromRGB(170, 130, 85), Mat.Cardboard)
	xb("Box", 9.1, 10.9, 0.9, 2.4, 1.6, 2.8, Color3.fromRGB(160, 120, 80), Mat.Cardboard)
	xp("RedTub", Vector3.new(0.9, 1.4, 1.4), 6.0, 0.45, 1.6, C.red, Mat.Plastic, true, Enum.PartType.Cylinder, VCYL)
	chair(5.2, 5.7, -2, Color3.fromRGB(175, 45, 40), SP) -- red vinyl chair
	xp("SideTable", Vector3.new(0.15, 1.8, 1.8), 7.6, 2.0, 5.6, C.white, Mat.Plastic, false, Enum.PartType.Cylinder, VCYL)
	xb("SideTableLeg", 7.55, 7.65, 5.55, 5.65, 0, 1.92, C.white, Mat.Plastic, true)
	xp("WickerStool", Vector3.new(1.4, 1.2, 1.2), 9.6, 0.7, 8.0, Color3.fromRGB(190, 150, 90), WD, false, Enum.PartType.Cylinder, VCYL)
	xb("ShoppingBag", 1.0, 2.2, 9.4, 10.6, 0, 1.6, Color3.fromRGB(200, 170, 120), SP, true)
	xb("ShoppingBag", 1.0, 1.9, 10.8, 11.9, 0, 1.3, C.white, Mat.Plastic, true)
	local tube = xb("TubeLight", 11.9, 12.05, 4.0, 5.8, 7.6, 7.75, Color3.fromRGB(240, 245, 250), Mat.Neon, true)
	if tube then
		light(tube, 16, 0.7, Color3.fromRGB(230, 240, 255))
	end
	xb("TubeConduit", 11.95, 12.05, 4.85, 4.95, 7.75, CEIL, C.white, Mat.Plastic, true)
	xp("PlainFrame", Vector3.new(0.08, 1.8, 2.4), 12.01, 5.6, 8.7, Color3.fromRGB(110, 80, 50), WD, true, nil, CFrame.Angles(math.rad(3), 0, 0))
	xp("FrameMat", Vector3.new(0.02, 1.4, 2.0), 11.96, 5.6, 8.7, Color3.fromRGB(205, 195, 170), SP, true, nil, CFrame.Angles(math.rad(3), 0, 0))
	doorLeaf("RoomDoor", 10.85, 11.05, 9.45, 12.2, Color3.fromRGB(150, 115, 55))
	-- ---------- bedroom M (generic) ----------
	xb("BedHead", 21.5, 24.35, 0.76, 1.06, 0, 3.4, Color3.fromRGB(120, 80, 45), WD)
	xb("BedBase", 21.5, 24.35, 1.06, 7.0, 0, 1.3, Color3.fromRGB(120, 80, 45), WD)
	xb("Mattress", 21.6, 24.3, 1.1, 6.95, 1.3, 2.0, Color3.fromRGB(235, 232, 225), SP)
	xb("Pillow", 22.0, 23.9, 1.3, 2.4, 2.0, 2.45, Color3.fromRGB(230, 225, 205), SP, true)
	xb("Blanket", 21.7, 24.2, 3.6, 6.6, 2.0, 2.3, Color3.fromRGB(150, 120, 160), SP, true)
	xb("Wardrobe", 12.85, 14.75, 3.0, 6.4, 0, 6.8, Color3.fromRGB(70, 42, 28), WD)
	xb("SmallTable", 16.5, 18.5, 7.5, 8.7, 2.4, 2.55, C.pine, WD)
	for _, o in { { 16.55, 7.55 }, { 18.35, 7.55 }, { 16.55, 8.55 }, { 18.35, 8.55 } } do
		xb("TableLeg", o[1], o[1] + 0.1, o[2], o[2] + 0.1, 0, 2.4, C.white, Mat.Metal, true)
	end
	doorLeaf("RoomDoor", 19.4, 19.6, 9.45, 12.2, Color3.fromRGB(150, 115, 55))
	-- ---------- dining room: fridge by the outer wall, round wooden table by the door to the living room ----------
	xb("Fridge", 25.3, 27.3, 0.75, 2.6, 0, 5.6, Color3.fromRGB(232, 232, 228), SP)
	xb("FridgeHandle", 26.9, 27.0, 2.6, 2.66, 2.5, 4.0, Color3.fromRGB(150, 150, 155), Mat.Metal, true)
	xp("DiningTable", Vector3.new(0.15, 3.6, 3.6), 30.7, 2.55, 9.0, Color3.fromRGB(140, 90, 50), WD, false, Enum.PartType.Cylinder, VCYL)
	xb("DiningTableLeg", 30.6, 30.8, 8.9, 9.1, 0, 2.475, Color3.fromRGB(110, 70, 40), WD)
	chair(27.55, 9.0, 1, Color3.fromRGB(140, 90, 50), WD)
	chair(33.85, 9.0, -1, Color3.fromRGB(140, 90, 50), WD)
	chair(30.7, 5.95, 2, Color3.fromRGB(140, 90, 50), WD)
	xb("PendantCord", 30.65, 30.75, 8.95, 9.05, 7.6, CEIL, C.black, SP, true)
	local shade = xp("PendantShade", Vector3.new(0.6, 1.2, 1.2), 30.7, 7.3, 9.0, Color3.fromRGB(250, 245, 230), Mat.Neon, true, Enum.PartType.Cylinder, VCYL)
	light(shade, 18, 0.7, Color3.fromRGB(255, 240, 215))
	-- ---------- kitchen ----------
	xb("Counter", 35.1, 41.7, 0.75, 2.6, 0, 2.9, Color3.fromRGB(200, 190, 170), WD)
	xb("Counter", 39.8, 41.7, 2.6, 6.3, 0, 2.9, Color3.fromRGB(200, 190, 170), WD)
	xb("CounterTop", 35.1, 41.7, 0.75, 2.6, 2.9, 3.0, Color3.fromRGB(120, 125, 125), Mat.Slate)
	xb("CounterTop", 39.8, 41.7, 2.6, 6.3, 2.9, 3.0, Color3.fromRGB(120, 125, 125), Mat.Slate)
	xb("GasStove", 36.0, 37.6, 1.0, 2.3, 3.0, 3.25, C.black, Mat.Metal)
	xp("Pot", Vector3.new(0.6, 0.9, 0.9), 36.5, 3.55, 1.65, Color3.fromRGB(180, 180, 185), Mat.Metal, true, Enum.PartType.Cylinder, VCYL)
	xp("RiceCooker", Vector3.new(0.8, 0.9, 0.9), 40.7, 3.4, 4.0, C.white, SP, true, Enum.PartType.Cylinder, VCYL)
	xb("WaterDispenser", 35.2, 36.2, 4.8, 5.8, 0, 3.6, C.white, SP)
	xp("WaterBottle", Vector3.new(1.2, 0.8, 0.8), 35.7, 4.2, 5.3, Color3.fromRGB(110, 170, 220), SP, true, Enum.PartType.Cylinder, VCYL)
	-- ---------- bathroom: toilet, shower pipe, a bucket; its door opens out into the dining room ----------
	xb("ToiletBowl", 40.4, 41.2, 10.8, 11.6, 0, 1.2, C.white, SP)
	xb("ToiletTank", 41.2, 41.65, 10.5, 11.9, 1.0, 2.6, C.white, SP)
	xb("ShowerPipe", 41.55, 41.65, 8.0, 8.1, 0.5, 6.4, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	xb("ShowerArm", 41.2, 41.55, 7.95, 8.15, 6.4, 6.55, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	xp("ShowerHead", Vector3.new(0.08, 0.5, 0.5), 41.15, 6.35, 8.05, Color3.fromRGB(200, 200, 205), Mat.Metal, true, Enum.PartType.Cylinder, VCYL)
	xp("Bucket", Vector3.new(0.9, 0.8, 0.8), 39.4, 0.45, 7.8, Color3.fromRGB(60, 120, 200), Mat.Plastic, true, Enum.PartType.Cylinder, VCYL)
	doorLeaf("BathDoor", 34.7, 37.95, 8.0, 8.2, Color3.fromRGB(170, 175, 170))
	-- the sink outside the bathroom, in the corner by the kitchen / dining
	xb("SinkPedestal", 35.6, 36.0, 11.6, 12.0, 0, 2.4, C.white, SP)
	xb("SinkBasin", 35.1, 36.5, 11.1, 12.25, 2.4, 2.9, C.white, SP)
	xb("SinkTap", 35.75, 35.85, 12.0, 12.25, 2.9, 3.25, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	xb("SinkMirror", 35.2, 36.4, 12.25, 12.3, 3.6, 5.4, Color3.fromRGB(180, 200, 205), SP, true).Reflectance = 0.3
	-- ---------- yellow room (the clip's room with the desk) ----------
	xb("Headboard", 9.35, 12.25, 17.95, 18.2, 0, 3.6, C.yellowWood, WD)
	xb("BedBase", 9.35, 12.25, 18.2, 24.1, 0, 1.4, C.yellowWood, WD)
	xb("Mattress", 9.45, 12.15, 18.25, 24.05, 1.4, 2.2, Color3.fromRGB(240, 236, 232), SP)
	local r = Random.new(928)
	for _ = 0, 7 do
		local x = r:NextNumber(9.6, 11.8)
		local z = r:NextNumber(19.8, 23.6)
		xb("SheetFlower", x, x + 0.25, z, z + 0.25, 2.2, 2.21, Color3.fromRGB(230, 150, 170), SP, true)
	end
	xb("Pillow", 9.7, 11.9, 18.35, 19.6, 2.2, 2.7, Color3.fromRGB(235, 228, 205), SP, true)
	xb("Blanket", 9.8, 11.7, 20.2, 22.4, 2.21, 2.75, Color3.fromRGB(120, 130, 175), SP, true)
	xb("SideTop", 9.35, 10.75, 24.3, 25.7, 2.1, 2.25, C.pine, WD)
	for _, o in { { 9.4, 24.35 }, { 10.6, 24.35 }, { 9.4, 25.55 }, { 10.6, 25.55 } } do
		xb("SideLeg", o[1], o[1] + 0.1, o[2], o[2] + 0.1, 0, 2.1, C.white, Mat.Metal, true)
	end
	xb("Tissues", 9.5, 10.0, 24.5, 24.9, 2.25, 2.6, Color3.fromRGB(240, 220, 110), Mat.Cardboard, true)
	xp("ClampLamp", Vector3.new(0.5, 0.5, 0.5), 10.4, 2.5, 25.3, C.white, Mat.Plastic, true, Enum.PartType.Ball)
	for _, p in { { 9.35, 25.9 }, { 10.53, 25.9 }, { 9.35, 27.68 }, { 10.53, 27.68 } } do
		xb("ShelfPost", p[1], p[1] + 0.12, p[2], p[2] + 0.12, 0, 6.0, C.white, Mat.Metal)
	end
	for i = 0, 3 do
		local y = 0.3 + i * 1.8
		xb("PineShelf", 9.35, 10.65, 26.02, 27.68, y, y + 0.1, C.pine, WD)
		booksX(9.45, 10.55, 26.1, 27.6, y + 0.1, 1.4, 40 + i)
	end
	local bl = math.sqrt(1.3 ^ 2 + 5.6 ^ 2) - 0.3
	local ba = math.atan2(1.3, 5.6)
	xp("ShelfBrace", Vector3.new(0.06, bl, 0.04), 10.0, 3.0, 25.86, C.white, Mat.Metal, true, nil, CFrame.Angles(0, 0, ba))
	xp("ShelfBrace", Vector3.new(0.06, bl, 0.04), 10.0, 3.0, 25.82, C.white, Mat.Metal, true, nil, CFrame.Angles(0, 0, -ba))
	xb("AirCooler", 12.6, 13.8, 18.0, 19.0, 0.25, 3.2, C.white, Mat.Plastic)
	xb("CoolerCastor", 12.7, 13.7, 18.1, 18.9, 0, 0.25, Color3.fromRGB(60, 60, 60), Mat.Rubber, true)
	for i = 0, 3 do
		xb("CoolerGrid", 12.8, 13.6, 19.0, 19.04, 0.8 + i * 0.55, 1.15 + i * 0.55, Color3.fromRGB(150, 155, 160), Mat.Plastic, true)
	end
	-- round wall light (white diffuser, blue-silver rim) on surface conduit, a square clock
	xp("WallLightRim", Vector3.new(0.08, 1.6, 1.6), 13.0, 6.4, 17.94, Color3.fromRGB(140, 165, 200), Mat.Metal, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	local wl = xp("WallLight", Vector3.new(0.06, 1.2, 1.2), 13.0, 6.4, 18.01, Color3.fromRGB(250, 250, 248), Mat.Neon, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	light(wl, 18, 0.8, Color3.fromRGB(245, 248, 255))
	xb("Conduit", 12.95, 13.05, 17.9, 17.98, 7.2, CEIL, C.white, Mat.Plastic, true)
	xb("ClockFrame", 10.0, 11.0, 17.9, 17.98, 7.6, 8.6, Color3.fromRGB(70, 45, 30), WD, true)
	xb("ClockFace", 10.12, 10.88, 17.98, 18.0, 7.72, 8.48, C.white, SP, true)
	xb("ClockHand", 10.47, 10.53, 18.0, 18.01, 8.1, 8.4, C.black, SP, true)
	xb("Wardrobe", 14.2, 17.6, 17.95, 19.85, 0, 6.8, Color3.fromRGB(70, 42, 28), WD)
	xb("WardrobeHandle", 15.8, 16.0, 19.85, 19.91, 3.2, 3.8, Color3.fromRGB(190, 155, 80), Mat.Metal, true)
	xb("BoxOnTop", 14.5, 17.2, 18.1, 19.6, 6.8, 7.9, Color3.fromRGB(165, 125, 80), Mat.Cardboard, true)
	-- desk with a drawer pedestal, a dark monitor, keyboard, mouse; a black tower under it; an office chair
	xb("DeskTop", 21.55, 23.85, 21.3, 24.2, 2.45, 2.65, C.brown, WD)
	xb("DeskPedestal", 21.75, 23.85, 22.9, 24.2, 0, 2.45, Color3.fromRGB(62, 40, 28), WD)
	xb("DeskLeg", 21.55, 21.75, 21.3, 21.5, 0, 2.45, C.brown, WD)
	xb("DeskLeg", 23.65, 23.85, 21.3, 21.5, 0, 2.45, C.brown, WD)
	for i = 0, 2 do
		xb("DrawerFront", 21.69, 21.75, 23.0, 24.1, 0.2 + i * 0.75, 0.85 + i * 0.75, Color3.fromRGB(78, 52, 36), WD, true)
	end
	xb("DeskMat", 22.0, 23.2, 21.6, 23.8, 2.65, 2.67, Color3.fromRGB(110, 110, 112), SP, true)
	xb("MonitorStand", 23.45, 23.75, 22.6, 23.0, 2.65, 3.1, C.black, Mat.Metal, true)
	xb("Monitor", 23.3, 23.45, 21.6, 24.0, 3.1, 4.8, C.black, SP, true)
	xb("Keyboard", 22.2, 22.6, 21.8, 23.6, 2.67, 2.75, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	xb("Mouse", 22.25, 22.5, 23.7, 23.9, 2.67, 2.78, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	xb("Tower", 22.3, 23.5, 21.55, 22.35, 0, 2.2, Color3.fromRGB(28, 28, 30), SP)
	xb("OfficeSeat", 19.9, 21.3, 22.0, 23.4, 1.6, 1.85, C.black, SP)
	xb("OfficeBack", 19.9, 20.1, 22.0, 23.4, 1.85, 4.2, C.black, SP)
	xb("OfficeStem", 20.55, 20.65, 22.65, 22.75, 0.2, 1.6, Color3.fromRGB(60, 60, 62), Mat.Metal, true)
	xb("OfficeBase", 20.0, 21.2, 22.1, 23.3, 0, 0.2, C.black, Mat.Plastic, true)
	-- upright piano (dark wood) against the east wall, a blank whiteboard over it with green tape corners
	xb("Piano", 22.3, 23.85, 24.5, 27.8, 0, 3.9, Color3.fromRGB(58, 36, 26), WD)
	xb("PianoKeys", 21.5, 22.3, 24.6, 27.7, 2.2, 2.35, Color3.fromRGB(245, 245, 240), SP)
	for i = 0, 10 do
		local z = 24.8 + i * 0.28
		xb("PianoBlackKey", 21.6, 22.05, z, z + 0.1, 2.35, 2.45, C.black, SP, true)
	end
	xb("MusicStack", 22.6, 23.6, 25.2, 26.6, 3.9, 4.5, Color3.fromRGB(240, 238, 230), SP, true)
	xb("Whiteboard", 23.88, 23.95, 24.8, 27.2, 4.6, 6.4, C.white, SP, true)
	for _, p in { { 24.8, 4.6 }, { 26.9, 4.6 }, { 24.8, 6.1 }, { 26.9, 6.1 } } do
		xb("GreenTape", 23.87, 23.88, p[1], p[1] + 0.3, p[2], p[2] + 0.3, Color3.fromRGB(70, 160, 80), Mat.Plastic, true)
	end
	-- window: curtains on a chrome rail, the split AC above (brand made up)
	xb("CurtainRail", 11.7, 18.3, 27.6, 27.7, 8.45, 8.55, Color3.fromRGB(200, 200, 205), Mat.Metal, true)
	xb("Curtain", 11.6, 13.6, 27.5, 27.58, 2.2, 8.4, C.curtain, SP, true)
	xb("Curtain", 16.4, 18.4, 27.5, 27.58, 2.2, 8.4, C.curtain, SP, true)
	xb("SplitAC", 13.1, 16.9, 27.15, 27.93, 8.6, 9.35, C.white, SP, true)
	local logo = xb("ACLogo", 14.5, 15.5, 27.12, 27.15, 8.95, 9.2, C.white, SP, true)
	if logo then
		text(logo, Enum.NormalId.Front, "KOOLA", Color3.fromRGB(80, 110, 160))
	end
	-- mint drop beam, board-panel joints, the twisted red / black wire in a corner
	xb("DropBeam", 9.25, 23.95, 22.6, 23.3, CEIL - 0.7, CEIL, C.mint, SP)
	for _, z in { 20.0, 24.0 } do
		xb("PanelJoint", 9.25, 9.27, z, z + 0.06, 3.7, CEIL - 0.01, Color3.fromRGB(150, 170, 160), SP, true)
	end
	xb("TwistedWire", 23.9, 23.95, 27.85, 27.9, 0.36, CEIL, Color3.fromRGB(120, 25, 25), Mat.Rubber, true)
	-- the yellow room's door: dark red-brown frame on the hall side, panelled leaf open into the room
	xb("DoorFrameRB", 18.75, 19.0, 17.14, 17.2, 0, 7.25, C.frameRB, WD, true)
	xb("DoorFrameRB", 22.4, 22.65, 17.14, 17.2, 0, 7.25, C.frameRB, WD, true)
	xb("DoorFrameRB", 19.0, 22.4, 17.14, 17.2, 7.0, 7.25, C.frameRB, WD, true)
	doorLeaf("YellowDoor", 22.2, 22.4, 17.95, 21.2, Color3.fromRGB(150, 115, 55))
	xb("DoorPanel", 22.14, 22.2, 18.3, 20.8, 3.9, 6.4, Color3.fromRGB(135, 100, 45), WD, true)
	xb("DoorPanel", 22.14, 22.2, 18.3, 20.8, 0.6, 3.5, Color3.fromRGB(135, 100, 45), WD, true)
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
	grilles()
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
	-- exact box-box test (separating axes) with a tolerance; GetPartsInPart only proposes the pairs (it has a margin)
	local function deep(p: BasePart, q: BasePart): boolean
		local A, Bc = p.CFrame, q.CFrame
		local ha, hb = p.Size / 2, q.Size / 2
		local ax = { A.RightVector, A.UpVector, A.LookVector }
		local bx = { Bc.RightVector, Bc.UpVector, Bc.LookVector }
		local axes = {}
		for _, v in ax do
			table.insert(axes, v)
		end
		for _, v in bx do
			table.insert(axes, v)
		end
		for _, u in ax do
			for _, v in bx do
				local c = u:Cross(v)
				if c.Magnitude > 1e-4 then
					table.insert(axes, c.Unit)
				end
			end
		end
		local d = Bc.Position - A.Position
		for _, L in axes do
			local ra = math.abs(ax[1]:Dot(L)) * ha.X + math.abs(ax[2]:Dot(L)) * ha.Y + math.abs(ax[3]:Dot(L)) * ha.Z
			local rb = math.abs(bx[1]:Dot(L)) * hb.X + math.abs(bx[2]:Dot(L)) * hb.Y + math.abs(bx[3]:Dot(L)) * hb.Z
			if math.abs(d:Dot(L)) > ra + rb - 0.01 then
				return false
			end
		end
		return true
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { m }
	local seen = {}
	for _, p in other do
		local size = p.Size
		p.Size = size - Vector3.new(0.04, 0.04, 0.04) -- touching faces are fine; real overlaps only
		local hits = workspace:GetPartsInPart(p, op)
		p.Size = size
		for _, q in hits do
			local key = if p:GetDebugId() < q:GetDebugId() then p:GetDebugId() .. q:GetDebugId() else q:GetDebugId() .. p:GetDebugId()
			local wedgePair = p:IsA("WedgePart") or q:IsA("WedgePart")
			if q ~= p and not seen[key] and not wedgePair and deep(p, q) then
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
	local groups, gl = {}, {}
	for _, b in bad do
		local k = string.match(b, "^(.-) @")
		groups[k] = (groups[k] or 0) + 1
	end
	for k, n in groups do
		table.insert(gl, n .. " " .. k)
	end
	table.sort(gl)
	return string.format("%d parts, %d overlaps inside, %d map parts touched\nGROUPS: %s\n%s\nMAP: %s", #parts, #bad, #wl, table.concat(gl, "; "), table.concat(bad, "\n", 1, math.min(#bad, 30)), table.concat(wl, ", ", 1, math.min(#wl, 20)))
end

return M
