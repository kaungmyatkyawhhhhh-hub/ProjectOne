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
local pieceId: number? = nil -- set while one piece of furniture is made (M.grow moves it as one)
local pieceN = 0
-- an openable (src/server/Openables.server.lua): a Model tagged Openable with its parts and a tiny invisible Hinge
-- part at the hinge line (or the drawer's corner); attrs = Kind, Angle / SlideL, BuiltOpen, Sound, Label
local openN = 0
local function openable(name: string, attrs: { [string]: any }, hx: number, hy: number, hz: number, fn)
	openN += 1
	local m = Instance.new("Model")
	m.Name = name
	for k, v in attrs do
		m:SetAttribute(k, v)
	end
	local prev = parent
	m.Parent = prev
	parent = m
	fn()
	local h = Instance.new("Part")
	h.Name = "Hinge"
	h.Size = Vector3.new(0.02, 0.02, 0.02)
	h.CFrame = F * CFrame.new(hx, hy, hz)
	h.Anchored, h.CanCollide, h.CanQuery, h.CanTouch = true, false, false, false
	h.Transparency = 1
	if pieceId then
		h:SetAttribute("Piece", pieceId)
	end
	h.Parent = m
	parent = prev
	game:GetService("CollectionService"):AddTag(m, "Openable")
	return m
end

local function asPiece(f)
	pieceN += 1
	local prev = pieceId
	pieceId = pieceN
	f()
	pieceId = prev
end
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
	if pieceId then
		p:SetAttribute("Piece", pieceId)
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

local function windowAt(f, s0, s1, y0, y1, glass: Color3, hood: boolean, ac: boolean, win: string?)
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
			if win then
				-- the flat's panes: real see-through glass that a click / tap frosts (src/server/FlatWindows.server.lua)
				g.Name = "FlatPane"
				g.Color = Color3.fromRGB(205, 225, 222)
				g.Transparency = 0.6
				g.Reflectance = 0.12
				g:SetAttribute("Win", win)
				game:GetService("CollectionService"):AddTag(g, "FlatWindowPane")
				local cd = Instance.new("ClickDetector")
				cd.MaxActivationDistance = 16
				cd.Parent = g
			end
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
			windowAt(f, s - WIN_W / 2, s + WIN_W / 2, k * H + WIN_Y0, k * H + WIN_Y1, glass, k >= 1, ac, if ours then f.id .. "_" .. s else nil)
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
	-- the honey teak door, built closed in its opening; it turns -90 deg on its north jamb into the flat (Openables)
	openable("FrontDoor", { Kind = "hinge", Angle = -90, BuiltOpen = false, Sound = "door", Label = "Door", Reach = 8 }, 41.85, y + 3.6, 24.35, function()
		local leaf = box("OurDoor", 41.85, y + 0.3, 24.35, 42.05, y + DOOR[3] - 0.05, 27.65, C.honey, Mat.Wood)
		if leaf then
			leaf.Reflectance = 0.06
		end
		local PNL = Color3.fromRGB(176, 118, 44)
		for _, xf in { { 41.79, 41.85 }, { 42.05, 42.11 } } do
			-- the big round-topped panel and two lower panels, both faces
			box("DoorPanel", xf[1], y + 4.2, 24.85, xf[2], y + 6.4, 27.15, PNL, Mat.Wood, true)
			box("DoorPanel", xf[1], y + 0.9, 24.85, xf[2], y + 3.8, 25.95, PNL, Mat.Wood, true)
			box("DoorPanel", xf[1], y + 0.9, 26.05, xf[2], y + 3.8, 27.15, PNL, Mat.Wood, true)
		end
		P("Knob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(41.64, y + 3.3, 27.25), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
		P("Knob", Vector3.new(0.3, 0.3, 0.3), CFrame.new(42.26, y + 3.3, 27.25), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
		P("Peephole", Vector3.new(0.06, 0.16, 0.16), CFrame.new(42.14, y + 5.2, 26.0), Color3.fromRGB(190, 150, 70), Mat.Metal, true, Enum.PartType.Cylinder)
	end)
	-- raised white step in the opening, white frame round it on the landing side
	box("Threshold", 41.8, y, DOOR[1], 42.4, y + 0.3, DOOR[2], C.white, Mat.SmoothPlastic)
	box("DoorFrame", 42.4, y, DOOR[1] - 0.25, 42.47, y + DOOR[3] + 0.25, DOOR[1], C.white, Mat.SmoothPlastic, true)
	box("DoorFrame", 42.4, y, DOOR[2], 42.47, y + DOOR[3] + 0.25, DOOR[2] + 0.25, C.white, Mat.SmoothPlastic, true)
	box("DoorFrame", 42.4, y + DOOR[3], DOOR[1], 42.47, y + DOOR[3] + 0.25, DOOR[2], C.white, Mat.SmoothPlastic, true)
	-- the off-white collapsible gate in its floor track: built folded on the left (towards the facade); closing it slides
	-- every upright across the opening and shows the X lattice (Openables, Kind gate)
	box("GateTrack", 42.4, y, DOOR[1], 42.75, y + 0.05, DOOR[2], C.galv, Mat.Metal, true)
	box("GateTopRail", 42.47, y + DOOR[3] - 0.05, DOOR[1], 42.72, y + DOOR[3] + 0.05, DOOR[2] + 0.25, C.gateW, Mat.Metal, true)
	openable("FrontGate", { Kind = "gate", BuiltOpen = true, Sound = "gate", Label = "Gate", Reach = 8 }, 42.6, y + 3.6, 27.7, function()
		local n = 8
		for i = 0, n do
			local zc = DOOR[1] + 0.03 + i * (DOOR[2] - DOOR[1] - 0.06) / n -- spread (closed) middle
			local zf = 27.66 + math.floor(i / 2) * 0.07 -- folded middle (two layers)
			local x0 = if i % 2 == 0 then 42.47 else 42.6
			local u = box("GateUpright", x0, y + 0.06, zf - 0.03, x0 + 0.12, y + DOOR[3] - 0.06, zf + 0.03, C.gateW, Mat.Metal, true)
			if u then
				u:SetAttribute("GateFold", Vector3.new(0, 0, zc - zf))
				if i == 0 then
					text(u, Enum.NormalId.Right, "ZAYA SUPER", Color3.fromRGB(150, 145, 135))
				end
			end
		end
		local bay = (DOOR[2] - DOOR[1] - 0.06) / n
		for i = 0, n - 1 do
			local cz = DOOR[1] + 0.03 + bay * (i + 0.5)
			for tier = 0, 1 do
				local cy = y + 1.9 + tier * 3.3
				local ang = math.atan2(3.0, bay)
				local len = math.sqrt(bay * bay + 9) - 0.3
				for k, sx in { 42.74, 42.78 } do
					local xpart = P("GateX", Vector3.new(0.035, len, 0.05), CFrame.new(sx, cy, cz) * CFrame.Angles((if k == 1 then 1 else -1) * (ang - math.pi / 2), 0, 0), C.gateW, Mat.Metal, true)
					xpart:SetAttribute("LatticeX", true)
					xpart.Transparency = 1
				end
			end
		end
	end)
	-- the dried leaf and twig bundle tied at eye height
	P("TwigBundle", Vector3.new(1.2, 0.3, 0.3), CFrame.new(43.3, y + 5.6, 26.75) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 85, 60), Mat.Wood, true, Enum.PartType.Cylinder)
	local r = Random.new(1106)
	for i = 0, 6 do
		-- dried leaves hung in thin layers (each its own z slice, turned only in its plane)
		P("DryLeaf", Vector3.new(0.45, 0.6, 0.05), CFrame.new(43.3 + r:NextNumber(-0.2, 0.2), y + 5.3 + r:NextNumber(0, 0.6), 26.95 + i * 0.1) * CFrame.Angles(0, 0, r:NextNumber(-0.8, 0.8)), Color3.fromRGB(125, 95, 65), Mat.Fabric, true)
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
	local function nq(p: Part?)
		if p then
			p.CanQuery = false
		end
	end
	local function rowX(x0, x1, zb0, zb1, zu0, zu1)
		for i = 1, 9 do
			local y = WY0 + i * 0.48
			nq(xb("Grille", x0, x1, zb0, zb1, y - 0.04, y + 0.04, gc, Mat.Metal, true))
		end
		local m = (x0 + x1) / 2
		nq(xb("Grille", m - 0.05, m + 0.05, zu0, zu1, WY0, WY1, gc, Mat.Metal, true))
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
			nq(xb("Grille", 0.65, 0.75, s[1], s[2], y - 0.04, y + 0.04, gc, Mat.Metal, true))
		end
		local m = (s[1] + s[2]) / 2
		nq(xb("Grille", 0.75, 0.8, m - 0.05, m + 0.05, WY0, WY1, gc, Mat.Metal, true))
	end
end

local function booksX(x0, x1, z0, z1, y, h, seed)
	books("Book", 41.8 - x1, 41.8 - x0, z0, z1, y, h, seed)
end

-- ===== furniture (26 Nov, pass 2: owner "the furniture looks like placeholder blocks") =====
-- Every piece is made of its real parts (legs, frames, doors with seams, handles, cushions, panels) and they only
-- butt together: nothing overlaps (B.check). Colours and kinds from the clips; nothing personal (see the vault note).
local SP, WD, MT = Mat.SmoothPlastic, Mat.Wood, Mat.Metal
local TEAK = Color3.fromRGB(130, 80, 40)
local DARKWOOD = Color3.fromRGB(70, 42, 28)
local CHROME = Color3.fromRGB(200, 200, 205)
local GOLD = Color3.fromRGB(212, 172, 60)

local function cyl(name, x, y0, y1, z, d, color, mat, deco)
	return xp(name, Vector3.new(y1 - y0, d, d), x, (y0 + y1) / 2, z, color, mat, deco, Enum.PartType.Cylinder, VCYL)
end
local function ball(name, x, y, z, d, color, mat, deco)
	return xp(name, Vector3.new(d, d, d), x, y, z, color, mat, deco, Enum.PartType.Ball)
end

-- a part in a turned frame: c = local CFrame of the piece's origin on the floor (yaw only), o = offset, s = size
local function rp(name, c: CFrame, ox, oy, oz, sx, sy, sz, color, mat, deco, shape)
	return P(name, Vector3.new(sx, sy, sz), c * CFrame.new(ox, oy, oz), color, mat, deco, shape)
end
local YAW = { [1] = -math.pi / 2, [-1] = math.pi / 2, [2] = math.pi, [-2] = 0 } -- face +x, -x, +z, -z

-- a wooden / vinyl chair: legs, seat, cushion, back posts, top rail, two slats; "face" = the way the sitter looks
local function chairRaw(x, z, face, color, mat, cushion, legColor)
	local c = CFrame.new(x, FY, z) * CFrame.Angles(0, YAW[face], 0)
	local lc = legColor or color
	for _, o in { { -0.47, -0.47 }, { 0.47, -0.47 }, { -0.47, 0.47 }, { 0.47, 0.47 } } do
		rp("ChairLeg", c, o[1], 0.725, o[2], 0.1, 1.45, 0.1, lc, mat, true)
	end
	rp("ChairSeat", c, 0, 1.51, 0, 1.1, 0.12, 1.1, color, mat)
	if cushion then
		rp("ChairCushion", c, 0, 1.645, -0.05, 1.0, 0.15, 0.95, cushion, SP, true)
	end
	for _, sx in { -0.47, 0.47 } do
		rp("ChairPost", c, sx, 2.47, 0.47, 0.1, 1.8, 0.1, lc, mat, true)
	end
	rp("ChairRail", c, 0, 3.15, 0.47, 0.84, 0.3, 0.1, color, mat, true)
	for _, sx in { -0.15, 0.15 } do
		rp("ChairSlat", c, sx, 2.36, 0.47, 0.12, 1.28, 0.06, color, mat, true)
	end
end

-- a desk / office chair on a five-star base
local function officeChairRaw(x, z, face, color)
	local c = CFrame.new(x, FY, z) * CFrame.Angles(0, YAW[face], 0)
	rp("ChairHub", c, 0, 0.16, 0, 0.12, 0.5, 0.5, C.black, Mat.Plastic, true, Enum.PartType.Cylinder).CFrame = F * c * CFrame.new(0, 0.16, 0) * VCYL
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		local leg = c * CFrame.Angles(0, a, 0)
		rp("ChairStarLeg", leg, 0, 0.17, -0.68, 0.12, 0.1, 0.62, C.black, Mat.Plastic, true)
		rp("ChairCaster", leg, 0, 0.06, -0.95, 0.12, 0.12, 0.12, C.black, Mat.Rubber, true, Enum.PartType.Ball)
	end
	rp("ChairGasLift", c, 0, 0.885, 0, 1.33, 0.14, 0.14, Color3.fromRGB(60, 60, 62), MT, true, Enum.PartType.Cylinder).CFrame = F * c * CFrame.new(0, 0.885, 0) * VCYL
	rp("ChairSeat", c, 0, 1.7, 0, 1.4, 0.3, 1.35, color, SP)
	rp("ChairBackBar", c, 0, 1.9, 0.6, 0.25, 0.1, 0.15, C.black, MT, true)
	rp("ChairBack", c, 0, 3.0, 0.62, 1.3, 2.1, 0.2, color, SP)
end

-- a two-door wardrobe facing +z or +x: body, doors with a seam, raised panels, handles, cornice
local function wardrobeRaw(x0, x1, z0, z1, h, front, color)
	local function fb2(name, s0, s1, n0, n1, y0, y1, col, mat, deco)
		if front == "+z" then
			return xb(name, s0, s1, n0, n1, y0, y1, col, mat, deco)
		end
		return xb(name, n0, n1, s0, s1, y0, y1, col, mat, deco)
	end
	local s0, s1, n0, n1 = x0, x1, z0, z1
	if front == "+x" then
		s0, s1, n0, n1 = z0, z1, x0, x1
	end
	local sm = (s0 + s1) / 2
	-- a hollow carcass (back, sides, top, plinth) with a shelf, a hanging rail, clothes on it, folded clothes and a shoe box
	-- (owner: "make the wardrobe open too with clothes inside"); everything stays inside the closed doors
	local nb = n1 - 0.06
	fb2("WardrobeBack", s0, s1, n0, n0 + 0.08, 0, h, color, WD)
	fb2("WardrobeSide", s0, s0 + 0.08, n0 + 0.08, nb, 0, h, color, WD)
	fb2("WardrobeSide", s1 - 0.08, s1, n0 + 0.08, nb, 0, h, color, WD)
	fb2("WardrobeTop", s0 + 0.08, s1 - 0.08, n0 + 0.08, nb, h - 0.1, h, color, WD)
	fb2("WardrobePlinth", s0 + 0.08, s1 - 0.08, n0 + 0.08, nb, 0, 0.3, color:Lerp(Color3.new(0, 0, 0), 0.25), WD)
	fb2("WardrobeShelf", s0 + 0.08, s1 - 0.08, n0 + 0.08, nb, 1.5, 1.56, color:Lerp(Color3.new(1, 1, 1), 0.1), WD, true)
	local nm = (n0 + 0.08 + nb) / 2
	local railY = h - 0.6
	local inner0, inner1 = s0 + 0.08, s1 - 0.08
	if front == "+z" then
		P("WardrobeRail", Vector3.new(inner1 - inner0, 0.08, 0.08), CFrame.new((inner0 + inner1) / 2, FY + railY, nm), Color3.fromRGB(190, 190, 195), MT, true, Enum.PartType.Cylinder)
	else
		P("WardrobeRail", Vector3.new(inner1 - inner0, 0.08, 0.08), CFrame.new(nm, FY + railY, (inner0 + inner1) / 2) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(190, 190, 195), MT, true, Enum.PartType.Cylinder)
	end
	local CLOTHES = { Color3.fromRGB(70, 80, 95), Color3.fromRGB(150, 140, 120), Color3.fromRGB(95, 60, 55), Color3.fromRGB(60, 85, 70), Color3.fromRGB(200, 195, 185), Color3.fromRGB(110, 70, 90) }
	local count = math.floor((inner1 - inner0 - 0.3) / 0.5)
	local depth = math.min(1.25, (nb - n0 - 0.08) - 0.3)
	for i = 0, count - 1 do
		local sc = inner0 + 0.35 + i * 0.5
		local long = (i % 3 == 1) -- a longyi or a long jacket now and then
		local top = railY - 0.04
		local bot = if long then 1.75 else 2.6 + (i % 2) * 0.2
		local th = 0.12 + (i % 2) * 0.05
		local d = depth - (i % 3) * 0.08
		local yaw = math.rad(((i * 37) % 9) - 4)
		local col = CLOTHES[(i % #CLOTHES) + 1]
		local cf = if front == "+z" then CFrame.new(sc, FY + (top + bot) / 2, nm) * CFrame.Angles(0, yaw, 0) else CFrame.new(nm, FY + (top + bot) / 2, sc) * CFrame.Angles(0, math.rad(90) + yaw, 0)
		P("HangingCloth", Vector3.new(th, top - bot, d), cf, col, SP, true)
	end
	-- folded clothes on the shelf, a shoe box on the plinth
	local fw = math.min(1.0, (inner1 - inner0) / 2 - 0.1)
	fb2("FoldedClothes", inner0 + 0.1, inner0 + 0.1 + fw, nm - 0.45, nm + 0.45, 1.56, 1.76, CLOTHES[2], SP, true)
	fb2("FoldedClothes", inner0 + 0.14, inner0 + 0.06 + fw, nm - 0.4, nm + 0.4, 1.76, 1.94, CLOTHES[4], SP, true)
	fb2("FoldedClothes", inner1 - 0.1 - fw, inner1 - 0.1, nm - 0.45, nm + 0.45, 1.56, 1.78, CLOTHES[5], SP, true)
	fb2("ShoeBox", inner0 + 0.15, inner0 + 1.05, nm - 0.45, nm + 0.35, 0.3, 0.75, Color3.fromRGB(170, 130, 85), Mat.Cardboard, true)
	for i, d in { { s0 + 0.06, sm - 0.02 }, { sm + 0.02, s1 - 0.06 } } do
		-- each door turns on its outer edge; front +z: left door -100, right +100; front +x: left +100, right -100
		local hs = if i == 1 then d[1] else d[2]
		local ang = if front == "+z" then (if i == 1 then -100 else 100) else (if i == 1 then 100 else -100)
		local hx, hz = if front == "+z" then hs else n1, if front == "+z" then n1 else hs
		openable("WardrobeDoor", { Kind = "hinge", Angle = ang, BuiltOpen = false, Sound = "wardrobe", Label = "Wardrobe" }, hx, FY + h * 0.5, hz, function()
			fb2("WardrobeDoor", d[1], d[2], n1 - 0.06, n1, 0.3, h - 0.12, color, WD)
			fb2("WardrobePanel", d[1] + 0.2, d[2] - 0.2, n1, n1 + 0.03, h * 0.55, h - 0.55, color:Lerp(Color3.new(0, 0, 0), 0.12), WD, true)
			fb2("WardrobePanel", d[1] + 0.2, d[2] - 0.2, n1, n1 + 0.03, 0.65, h * 0.5, color:Lerp(Color3.new(0, 0, 0), 0.12), WD, true)
			local e = if i == 1 then d[2] - 0.16 else d[1] + 0.1
			fb2("WardrobeHandle", e, e + 0.06, n1 + 0.03, n1 + 0.09, h * 0.45, h * 0.57, Color3.fromRGB(190, 155, 80), MT, true)
		end)
	end
	fb2("WardrobeCornice", s0 - 0.06, s1 + 0.06, n0, n1 + 0.1, h, h + 0.12, color:Lerp(Color3.new(0, 0, 0), 0.2), WD)
end

-- a bed with its head at z0: posts, headboard, footboard, rails, mattress, pillow, folded blanket
local function bedRaw(x0, x1, z0, z1, frame, sheet, blanket, seed)
	-- a box frame standing on the floor (no legs), headboard posts at the head
	for _, x in { x0, x1 - 0.25 } do
		xb("BedPost", x, x + 0.25, z0, z0 + 0.25, 0, 3.8, frame, WD)
	end
	xb("Headboard", x0 + 0.25, x1 - 0.25, z0 + 0.05, z0 + 0.2, 0, 3.4, frame, WD)
	xb("HeadboardRail", x0 + 0.25, x1 - 0.25, z0, z0 + 0.25, 3.4, 3.6, frame, WD)
	xb("BedFrameSide", x0, x0 + 0.15, z0 + 0.25, z1, 0, 1.0, frame, WD)
	xb("BedFrameSide", x1 - 0.15, x1, z0 + 0.25, z1, 0, 1.0, frame, WD)
	xb("BedFrameFoot", x0 + 0.15, x1 - 0.15, z1 - 0.15, z1, 0, 1.0, frame, WD)
	xb("BedFrameTrim", x0, x1, z1, z1 + 0.04, 0.85, 1.0, frame:Lerp(Color3.new(0, 0, 0), 0.25), WD, true)
	xb("BedSlats", x0 + 0.15, x1 - 0.15, z0 + 0.25, z1 - 0.15, 0.8, 1.0, frame:Lerp(Color3.new(0, 0, 0), 0.3), WD)
	xb("Mattress", x0 + 0.15, x1 - 0.15, z0 + 0.3, z1 - 0.3, 1.0, 1.75, sheet, SP)
	xb("Pillow", x0 + 0.4, x1 - 0.4, z0 + 0.45, z0 + 1.35, 1.75, 2.05, Color3.fromRGB(236, 230, 210), SP, true)
	xb("PillowTop", x0 + 0.5, x1 - 0.5, z0 + 0.55, z0 + 1.25, 2.05, 2.2, Color3.fromRGB(236, 230, 210), SP, true)
	xb("BlanketFolded", x0 + 0.2, x1 - 0.2, z1 - 1.7, z1 - 0.35, 1.75, 2.0, blanket, SP, true)
	xb("BlanketFold", x0 + 0.3, x1 - 0.3, z1 - 1.6, z1 - 0.9, 2.0, 2.12, blanket:Lerp(Color3.new(1, 1, 1), 0.15), SP, true)
	if seed then
		local r = Random.new(seed)
		for _ = 1, 8 do
			local x = r:NextNumber(x0 + 0.3, x1 - 0.55)
			local z = r:NextNumber(z0 + 1.5, z1 - 1.95)
			xb("SheetFlower", x, x + 0.22, z, z + 0.22, 1.75, 1.76, Color3.fromRGB(230, 150, 170), SP, true)
		end
	end
end

local function bedXRaw(x0, x1, z0, z1, frame, sheet, blanket, seed)
	-- a box frame standing on the floor (no legs: owner), the yellow headboard with its posts at the head
	for _, z in { z0, z1 - 0.25 } do
		xb("BedPost", x0, x0 + 0.25, z, z + 0.25, 0, 3.8, frame, WD)
	end
	xb("Headboard", x0 + 0.05, x0 + 0.2, z0 + 0.25, z1 - 0.25, 0, 3.4, frame, WD)
	xb("HeadboardRail", x0, x0 + 0.25, z0 + 0.25, z1 - 0.25, 3.4, 3.6, frame, WD)
	xb("BedFrameSide", x0 + 0.25, x1, z0, z0 + 0.15, 0, 1.0, frame, WD)
	xb("BedFrameSide", x0 + 0.25, x1, z1 - 0.15, z1, 0, 1.0, frame, WD)
	xb("BedFrameFoot", x1 - 0.15, x1, z0 + 0.15, z1 - 0.15, 0, 1.0, frame, WD)
	xb("BedFrameTrim", x1, x1 + 0.04, z0, z1, 0.85, 1.0, frame:Lerp(Color3.new(0, 0, 0), 0.25), WD, true)
	xb("BedSlats", x0 + 0.25, x1 - 0.15, z0 + 0.15, z1 - 0.15, 0.8, 1.0, frame:Lerp(Color3.new(0, 0, 0), 0.3), WD)
	xb("Mattress", x0 + 0.3, x1 - 0.3, z0 + 0.15, z1 - 0.15, 1.0, 1.75, sheet, SP)
	local zm = (z0 + z1) / 2
	for _, pz in { { z0 + 0.35, zm - 0.1 }, { zm + 0.1, z1 - 0.35 } } do
		xb("Pillow", x0 + 0.45, x0 + 1.35, pz[1], pz[2], 1.75, 2.05, Color3.fromRGB(236, 230, 210), SP, true)
		xb("PillowTop", x0 + 0.55, x0 + 1.25, pz[1] + 0.1, pz[2] - 0.1, 2.05, 2.2, Color3.fromRGB(236, 230, 210), SP, true)
	end
	xb("BlanketFolded", x1 - 1.7, x1 - 0.35, z0 + 0.2, z1 - 0.2, 1.75, 2.0, blanket, SP, true)
	xb("BlanketFold", x1 - 1.6, x1 - 0.9, z0 + 0.3, z1 - 0.3, 2.0, 2.12, blanket:Lerp(Color3.new(1, 1, 1), 0.15), SP, true)
	if seed then
		local r = Random.new(seed)
		for _ = 1, 8 do
			local x = r:NextNumber(x0 + 1.5, x1 - 1.95)
			local z = r:NextNumber(z0 + 0.3, z1 - 0.55)
			xb("SheetFlower", x, x + 0.22, z, z + 0.22, 1.75, 1.76, Color3.fromRGB(230, 150, 170), SP, true)
		end
	end
end

local function chair(x, z, face, color, mat, cushion, legColor)
	asPiece(function()
		chairRaw(x, z, face, color, mat, cushion, legColor)
	end)
end

local function officeChair(x, z, face, color)
	asPiece(function()
		officeChairRaw(x, z, face, color)
	end)
end

local function wardrobe(x0, x1, z0, z1, h, front, color)
	asPiece(function()
		wardrobeRaw(x0, x1, z0, z1, h, front, color)
	end)
end

local function bed(x0, x1, z0, z1, frame, sheet, blanket, seed)
	asPiece(function()
		bedRaw(x0, x1, z0, z1, frame, sheet, blanket, seed)
	end)
end

local function bedX(x0, x1, z0, z1, frame, sheet, blanket, seed)
	asPiece(function()
		bedXRaw(x0, x1, z0, z1, frame, sheet, blanket, seed)
	end)
end

local function flushLamp(name, x, z, range)
	cyl(name .. "Rim", x, CEIL - 0.15, CEIL, z, 1.6, Color3.fromRGB(225, 225, 220), SP, true)
	local d = cyl(name, x, CEIL - 0.25, CEIL - 0.15, z, 1.3, Color3.fromRGB(255, 250, 238), Mat.Neon, true)
	light(d, range or 16, 0.75, Color3.fromRGB(255, 244, 225))
end

local function tubeLight(name, x0, x1, z0, z1, lit)
	-- a ceiling batten with its tube
	xb(name .. "Batten", x0, x1, z0, z1, CEIL - 0.15, CEIL, C.white, SP, true)
	local alongX = (x1 - x0) > (z1 - z0)
	local t = if alongX
		then xb(name, x0 + 0.2, x1 - 0.2, (z0 + z1) / 2 - 0.06, (z0 + z1) / 2 + 0.06, CEIL - 0.27, CEIL - 0.15, Color3.fromRGB(240, 245, 250), Mat.Neon, true)
		else xb(name, (x0 + x1) / 2 - 0.06, (x0 + x1) / 2 + 0.06, z0 + 0.2, z1 - 0.2, CEIL - 0.27, CEIL - 0.15, Color3.fromRGB(240, 245, 250), Mat.Neon, true)
	if lit and t then
		light(t, 16, 0.7, Color3.fromRGB(232, 240, 255))
	end
end

local function ceilingFanRaw(x, z)
	cyl("FanRod", x, CEIL - 1.0, CEIL, z, 0.12, Color3.fromRGB(235, 235, 230), MT, true)
	cyl("FanMotor", x, CEIL - 1.4, CEIL - 1.0, z, 0.7, Color3.fromRGB(235, 235, 230), MT, true)
	for i = 0, 2 do
		local c = CFrame.new(x, FY + CEIL - 1.25, z) * CFrame.Angles(0, i * math.pi * 2 / 3 + 0.4, 0)
		rp("FanBlade", c, 0, 0, -1.6, 0.45, 0.05, 2.0, Color3.fromRGB(240, 240, 236), SP, true)
	end
end

local function curtainsRaw(x0, x1, zc)
	-- rail and two pale panels drawn to the sides of a window on the south (BC) wall
	xb("CurtainRail", x0 - 1.0, x1 + 1.0, zc + 0.1, zc + 0.2, 8.45, 8.55, CHROME, MT, true)
	xb("Curtain", x0 - 1.0, x0 + 0.5, zc, zc + 0.08, 2.6, 8.4, C.curtain, SP, true).CanQuery = false
	xb("Curtain", x1 - 0.5, x1 + 1.0, zc, zc + 0.08, 2.6, 8.4, C.curtain, SP, true).CanQuery = false
end

local function ceilingFan(x, z)
	asPiece(function()
		ceilingFanRaw(x, z)
	end)
end
local function curtains(x0, x1, zc)
	asPiece(function()
		curtainsRaw(x0, x1, zc)
	end)
end

-- a bicycle standing along x in the plane z = zb (its middle at x = xc): spoked wheels with knobbly tyres, a pink
-- frame (main triangle in the plane, stays and fork either side of the wheels), white fork, saddle, bars, cranks, pedals
local function bicycleRaw(xc, zb, flip: boolean?)
	-- flip: upside down, resting on the saddle and the handlebar grips, wheels up (owner); y -> TOP - y
	local TOP = 3.17
	local function fy(y)
		return if flip then TOP - y else y
	end
	local PINK, WHITE, TYRE = Color3.fromRGB(226, 118, 160), Color3.fromRGB(238, 238, 235), Color3.fromRGB(26, 26, 28)
	local R = 1.1
	local function tube(name, a: Vector2, b: Vector2, dz, th, col, ca: number?, cb: number?)
		-- (ends cut short so tubes meeting at a joint never run into each other)
		local d = b - a
		local u = d.Unit
		a, b = a + u * (ca or 0.22), b - u * (cb or 0.22)
		d = b - a
		local len = d.Magnitude
		local mid = (a + b) / 2
		local ang = math.atan2(d.Y, d.X)
		if flip then
			ang = -ang
		end
		P(name, Vector3.new(len, th, 0.08), CFrame.new(xc + mid.X, FY + fy(mid.Y), zb + dz) * CFrame.Angles(0, 0, ang), col, MT, true)
	end
	for _, hx in { -1.65, 1.65 } do
		local hub = Vector2.new(hx, R)
		xp("BikeHub", Vector3.new(0.2, 0.25, 0.25), xc + hx, fy(R), zb, CHROME, MT, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
		for k = 0, 11 do
			local a = k * math.pi / 6
			local c = CFrame.new(xc + hx, FY + fy(R), zb) * CFrame.Angles(0, 0, a)
			P("BikeTyre", Vector3.new(0.5, 0.16, 0.12), c * CFrame.new(0, R - 0.08, 0), TYRE, Mat.Rubber, true)
		end
		for k = 0, 7 do
			local a = k * math.pi / 4 + 0.2
			local c = CFrame.new(xc + hx, FY + fy(R), zb) * CFrame.Angles(0, 0, a)
			P("BikeSpoke", Vector3.new(0.025, R - 0.16 - 0.17, 0.025), c * CFrame.new(0, 0.17 + (R - 0.16 - 0.17) / 2, 0), CHROME, MT, true)
		end
		local _ = hub
	end
	local BB, ST, HT, HB = Vector2.new(-0.2, 0.95), Vector2.new(-0.55, 2.6), Vector2.new(0.95, 2.75), Vector2.new(1.0, 2.3)
	local RH, FH = Vector2.new(-1.65, R), Vector2.new(1.65, R)
	tube("BikeSeatTube", BB, ST, 0, 0.13, PINK)
	tube("BikeTopTube", ST, HT, 0, 0.12, PINK, 0.22, 0.3)
	tube("BikeDownTube", BB, HB, 0, 0.14, PINK, 0.22, 0.3)
	tube("BikeHeadTube", HB, HT, 0, 0.16, PINK, 0, 0)
	for _, dz in { -0.15, 0.15 } do
		tube("BikeChainStay", BB, RH, dz, 0.08, PINK)
		tube("BikeSeatStay", ST, RH, dz, 0.07, PINK)
		tube("BikeFork", HB, FH, dz, 0.09, WHITE, 0.1, 0.22)
	end
	-- seat post + saddle, stem + handlebar with grips
	tube("BikeSeatPost", ST, ST + Vector2.new(-0.06, 0.42), 0, 0.07, CHROME, 0.12, 0)
	xb("BikeSaddle", xc + ST.X - 0.45, xc + ST.X + 0.25, zb - 0.14, zb + 0.14, math.min(fy(ST.Y + 0.42), fy(ST.Y + 0.55)), math.max(fy(ST.Y + 0.42), fy(ST.Y + 0.55)), C.black, SP, true)
	tube("BikeStem", HT, HT + Vector2.new(0.05, 0.3), 0, 0.07, CHROME, 0.05, 0)
	xb("BikeBar", xc + HT.X - 0.0, xc + HT.X + 0.12, zb - 0.6, zb + 0.6, math.min(fy(HT.Y + 0.3), fy(HT.Y + 0.4)), math.max(fy(HT.Y + 0.3), fy(HT.Y + 0.4)), C.black, MT, true)
	xb("BikeGrip", xc + HT.X - 0.02, xc + HT.X + 0.14, zb - 0.75, zb - 0.6, math.min(fy(HT.Y + 0.28), fy(HT.Y + 0.42)), math.max(fy(HT.Y + 0.28), fy(HT.Y + 0.42)), C.black, Mat.Rubber, true)
	xb("BikeGrip", xc + HT.X - 0.02, xc + HT.X + 0.14, zb + 0.6, zb + 0.75, math.min(fy(HT.Y + 0.28), fy(HT.Y + 0.42)), math.max(fy(HT.Y + 0.28), fy(HT.Y + 0.42)), C.black, Mat.Rubber, true)
	-- chainring, cranks and pedals
	xp("BikeChainring", Vector3.new(0.04, 0.6, 0.6), xc + BB.X, fy(BB.Y), zb + 0.22, Color3.fromRGB(70, 70, 74), MT, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	xb("BikeCrank", xc + BB.X - 0.04, xc + BB.X + 0.04, zb + 0.25, zb + 0.31, math.min(fy(BB.Y - 0.5), fy(BB.Y - 0.05)), math.max(fy(BB.Y - 0.5), fy(BB.Y - 0.05)), CHROME, MT, true)
	xb("BikeCrank", xc + BB.X - 0.04, xc + BB.X + 0.04, zb - 0.31, zb - 0.25, math.min(fy(BB.Y + 0.05), fy(BB.Y + 0.5)), math.max(fy(BB.Y + 0.05), fy(BB.Y + 0.5)), CHROME, MT, true)
	xb("BikePedal", xc + BB.X - 0.2, xc + BB.X + 0.2, zb + 0.31, zb + 0.55, math.min(fy(BB.Y - 0.58), fy(BB.Y - 0.5)), math.max(fy(BB.Y - 0.58), fy(BB.Y - 0.5)), C.black, Mat.Plastic, true)
	xb("BikePedal", xc + BB.X - 0.2, xc + BB.X + 0.2, zb - 0.55, zb - 0.31, math.min(fy(BB.Y + 0.5), fy(BB.Y + 0.58)), math.max(fy(BB.Y + 0.5), fy(BB.Y + 0.58)), C.black, Mat.Plastic, true)
end
local function bicycle(xc, zb, flip)
	asPiece(function()
		bicycleRaw(xc, zb, flip)
	end)
end

local function doorLeaf(name, x0, x1, z0, z1, color)
	xb(name, x0, x1, z0, z1, 0.05, 6.95, color, WD)
end

local function furniture()
	-- ---------- living room (owner's mark-up 26 Nov: couch on the yellow room's wall, TV between the windows) ----------
	xb("Rug", 27.5, 30.6, 19.2, 24.8, 0, 0.03, Color3.fromRGB(140, 50, 40), SP, true)
	xb("RugField", 27.8, 30.3, 19.5, 24.5, 0.03, 0.035, Color3.fromRGB(190, 150, 90), SP, true)
	-- TV cabinet on the window wall, doors and knobs facing the room (-z); TV on a stand, thin bezel, dim picture
	for _, x in { 30.45, 34.15 } do
		for _, z in { 26.6, 27.6 } do
			xb("CabinetLeg", x, x + 0.15, z, z + 0.15, 0, 0.3, DARKWOOD, WD, true)
		end
	end
	xb("TVCabinet", 30.35, 34.4, 26.5, 27.85, 0.3, 1.75, TEAK, WD)
	xb("TVCabinetTop", 30.3, 34.45, 26.4, 27.85, 1.75, 1.85, TEAK:Lerp(Color3.new(0, 0, 0), 0.15), WD)
	for i, d in { { 30.45, 32.33 }, { 32.42, 34.3 } } do
		local hx = if i == 1 then d[1] else d[2]
		openable("CabinetDoor", { Kind = "hinge", Angle = if i == 1 then 100 else -100, BuiltOpen = false, Sound = "cabinet", Label = "Cabinet" }, hx, FY + 1.0, 26.45, function()
			xb("CabinetDoor", d[1], d[2], 26.45, 26.5, 0.4, 1.65, TEAK:Lerp(Color3.new(1, 1, 1), 0.06), WD)
			local k = if i == 1 then 32.15 else 32.47
			xb("CabinetKnob", k, k + 0.13, 26.39, 26.45, 0.95, 1.1, GOLD, MT, true)
		end)
	end
	xb("TVStandBase", 32.0, 32.8, 26.9, 27.5, 1.85, 1.9, C.black, MT, true)
	xb("TVStandNeck", 32.3, 32.5, 27.05, 27.2, 1.9, 2.3, C.black, MT, true)
	xb("TVPanel", 30.5, 34.3, 27.05, 27.2, 2.3, 4.5, Color3.fromRGB(18, 18, 20), SP)
	xb("TVScreenSky", 30.6, 34.2, 27.02, 27.05, 3.45, 4.4, Color3.fromRGB(34, 46, 64), Mat.Neon, true)
	xb("TVScreenLand", 30.6, 34.2, 27.02, 27.05, 2.4, 3.45, Color3.fromRGB(30, 42, 32), Mat.Neon, true)
	cyl("PlantPot", 34.0, 1.85, 2.25, 26.7, 0.35, Color3.fromRGB(170, 90, 60), SP, true)
	ball("PlantLeaves", 34.0, 2.5, 26.7, 0.5, Color3.fromRGB(60, 120, 60), SP, true)
	-- coffee table on the rug
	for _, x in { 28.05, 29.8 } do
		for _, z in { 20.35, 23.5 } do
			xb("TableLeg", x, x + 0.15, z, z + 0.15, 0.035, 1.35, TEAK, WD, true)
		end
	end
	xb("CoffeeShelf", 28.2, 29.8, 20.35, 23.65, 0.4, 0.5, TEAK, WD, true)
	xb("CoffeeTop", 28.0, 30.0, 20.3, 23.7, 1.35, 1.5, TEAK, WD)
	cyl("FruitBowl", 29.0, 1.5, 1.68, 21.5, 0.7, Color3.fromRGB(235, 235, 230), SP, true)
	xb("Magazine", 28.5, 29.3, 22.6, 23.2, 1.5, 1.52, Color3.fromRGB(200, 70, 60), SP, true)
	-- couch (teak frame, maroon cushions) against the yellow room's wall, facing into the room
	for _, x in { 24.7, 26.9 } do
		for _, z in { 18.9, 24.9 } do
			xb("CouchLeg", x, x + 0.2, z, z + 0.2, 0, 0.35, DARKWOOD, WD, true)
		end
	end
	xb("CouchBase", 24.6, 27.2, 18.8, 25.2, 0.35, 1.0, TEAK, WD)
	xb("CouchArm", 24.6, 27.2, 18.8, 19.35, 1.0, 2.3, TEAK, WD)
	xb("CouchArm", 24.6, 27.2, 24.65, 25.2, 1.0, 2.3, TEAK, WD)
	xb("CouchArmPad", 25.15, 27.2, 18.8, 19.35, 2.3, 2.4, Color3.fromRGB(110, 40, 40), SP, true)
	xb("CouchArmPad", 25.15, 27.2, 24.65, 25.2, 2.3, 2.4, Color3.fromRGB(110, 40, 40), SP, true)
	xb("CouchBack", 24.6, 25.15, 19.35, 24.65, 1.0, 3.0, TEAK, WD)
	for _, z in { { 19.38, 21.08 }, { 21.15, 22.85 }, { 22.92, 24.62 } } do
		xb("SeatCushion", 25.15, 27.1, z[1], z[2], 1.0, 1.6, Color3.fromRGB(110, 40, 40), SP)
		xb("BackCushion", 25.15, 25.65, z[1], z[2], 1.6, 2.95, Color3.fromRGB(118, 44, 44), SP, true)
	end
	xb("ThrowPillow", 25.65, 26.0, 19.5, 20.3, 1.6, 2.4, Color3.fromRGB(210, 170, 90), SP, true)
	xb("ThrowPillow", 25.65, 26.0, 23.7, 24.5, 1.6, 2.4, Color3.fromRGB(210, 170, 90), SP, true)
	-- treadmill in the far (north-east) corner: deck, belt, side rails, motor hood, uprights, handrails, console
	xb("TreadmillFoot", 37.45, 37.75, 13.3, 15.3, 0, 0.15, C.black, Mat.Rubber, true)
	xb("TreadmillFoot", 40.25, 40.55, 13.3, 15.3, 0, 0.15, C.black, Mat.Rubber, true)
	xb("TreadmillDeck", 37.4, 40.6, 13.3, 15.3, 0.15, 0.5, Color3.fromRGB(60, 63, 68), SP)
	xb("TreadmillBelt", 37.55, 40.5, 13.6, 15.0, 0.5, 0.55, Color3.fromRGB(22, 22, 24), Mat.Rubber, true)
	xb("TreadmillRail", 37.4, 40.6, 13.3, 13.6, 0.5, 0.58, Color3.fromRGB(150, 155, 160), MT, true)
	xb("TreadmillRail", 37.4, 40.6, 15.0, 15.3, 0.5, 0.58, Color3.fromRGB(150, 155, 160), MT, true)
	xb("TreadmillHood", 40.6, 41.5, 13.3, 15.3, 0.15, 0.9, Color3.fromRGB(45, 47, 52), SP)
	for _, z in { 13.35, 15.05 } do
		xb("TreadmillUpright", 41.0, 41.2, z, z + 0.2, 0.9, 3.8, Color3.fromRGB(70, 72, 76), MT)
		xb("TreadmillHandrail", 39.6, 41.0, z, z + 0.2, 3.3, 3.45, Color3.fromRGB(40, 40, 44), Mat.Rubber, true)
	end
	xb("TreadmillConsole", 40.7, 41.3, 13.55, 15.05, 3.8, 4.4, Color3.fromRGB(35, 36, 40), SP)
	xb("TreadmillDisplay", 40.66, 40.7, 13.9, 14.7, 4.0, 4.3, Color3.fromRGB(60, 150, 110), Mat.Neon, true)
	xb("TreadmillKey", 40.64, 40.7, 14.8, 14.9, 3.9, 4.0, C.red, SP, true)
	-- entrance things from the clip: drawer tower, slippers (the folding screen is gone: owner's mark-up)
	xb("DrawerTowerTop", 40.2, 41.6, 17.0, 18.05, 4.05, 4.2, C.white, Mat.Plastic)
	xb("DrawerTowerFrame", 40.3, 41.6, 17.0, 18.05, 0, 4.05, Color3.fromRGB(225, 225, 222), Mat.Plastic)
	for i = 0, 3 do
		openable("Drawer", { Kind = "drawer", SlideL = Vector3.new(-0.8, 0, 0), BuiltOpen = false, Sound = "drawer", Label = "Drawer", Reach = 6 }, 40.24, FY + 0.1 + i * 1.0, 17.05, function()
			xb("Drawer", 40.24, 40.3, 17.05, 18.0, 0.1 + i * 1.0, 0.95 + i * 1.0, Color3.fromRGB(240, 240, 238), Mat.Plastic)
			xb("DrawerHandle", 40.18, 40.24, 17.3, 17.75, 0.45 + i * 1.0, 0.6 + i * 1.0, Color3.fromRGB(80, 80, 85), Mat.Plastic, true)
		end)
	end
	xb("ClothesPile", 40.3, 41.5, 17.1, 17.95, 4.2, 4.6, Color3.fromRGB(120, 140, 170), SP, true)
	-- the folding screen beside the front door on its hinge side (owner's mark-up), clear of the open leaf
	asPiece(function()
		for i = 0, 2 do
			local z0 = 18.35 + i * 1.1
			xb("ScreenFrame", 39.9, 40.15, z0, z0 + 1.05, 0, 6.2, C.brown, WD)
			xb("ScreenPaper", 39.85, 39.9, z0 + 0.12, z0 + 0.93, 0.6, 5.9, Color3.fromRGB(200, 180, 140), SP, true)
		end
	end)
	xb("Slippers", 39.5, 40.2, 25.0, 25.3, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	xb("Slippers", 39.5, 40.2, 25.4, 25.7, 0, 0.12, Color3.fromRGB(205, 185, 150), Mat.Rubber, true)
	curtains(25.65, 29.85, 27.5)
	curtains(34.9, 39.1, 27.5)
	flushLamp("LivingLamp", 33.0, 20.5, 20)
	ceilingFan(33.0, 15.8)
	xb("ClockFrame", 31.0, 32.0, 12.9, 12.98, 7.0, 8.0, DARKWOOD, WD, true)
	xb("ClockFace", 31.12, 31.88, 12.98, 13.0, 7.12, 7.88, C.white, SP, true)
	xb("ClockHand", 31.47, 31.53, 13.0, 13.01, 7.5, 7.8, C.black, SP, true)
	-- the shrine: cabinet with doors, stepped tiers with gold trim, a backdrop, a small seated figure with a lit halo,
	-- two small pagodas, flowers, a candle and water cups (generic, nothing copied)
	local shrineWood = Color3.fromRGB(95, 32, 26)
	xb("ShrineCabinet", 0.75, 5.2, 25.46, 27.75, 0, 2.4, shrineWood, WD)
	for i, d in { { 0.9, 2.9 }, { 3.05, 5.05 } } do
		local hx = if i == 1 then d[1] else d[2]
		openable("ShrineDoor", { Kind = "hinge", Angle = if i == 1 then 100 else -100, BuiltOpen = false, Sound = "cabinet", Label = "Cabinet" }, hx, FY + 1.2, 25.4, function()
			xb("ShrineDoor", d[1], d[2], 25.4, 25.46, 0.3, 2.1, shrineWood:Lerp(Color3.new(0, 0, 0), 0.1), WD)
			local k = if i == 1 then 2.75 else 3.1
			xb("ShrineKnob", k, k + 0.1, 25.34, 25.4, 1.15, 1.3, GOLD, MT, true)
		end)
	end
	xb("ShrineTop", 0.7, 5.25, 25.35, 27.75, 2.4, 2.5, shrineWood, WD)
	xb("ShrineTier", 0.85, 5.1, 26.3, 27.75, 2.5, 3.0, shrineWood, WD)
	xb("ShrineTrim", 0.85, 5.1, 26.27, 26.3, 2.9, 3.0, GOLD, MT, true)
	xb("ShrineTier", 0.85, 5.1, 26.3, 27.75, 3.0, 3.1, GOLD, MT)
	xb("ShrineTier", 1.4, 4.55, 26.9, 27.75, 3.1, 3.6, shrineWood, WD)
	xb("ShrineTrim", 1.4, 4.55, 26.87, 26.9, 3.5, 3.6, GOLD, MT, true)
	xb("ShrineTier", 1.4, 4.55, 26.9, 27.75, 3.6, 3.7, GOLD, MT)
	xb("ShrineBackdrop", 1.2, 4.75, 27.7, 27.75, 3.7, 5.6, Color3.fromRGB(150, 40, 30), SP)
	xb("ShrineBackdropTrim", 1.2, 4.75, 27.66, 27.7, 5.45, 5.6, GOLD, MT, true)
	cyl("FigureLotus", 2.975, 3.7, 3.9, 27.3, 0.8, GOLD, SP, true)
	xb("FigureLegs", 2.55, 3.4, 27.05, 27.55, 3.9, 4.15, GOLD, SP, true)
	xb("FigureBody", 2.7, 3.25, 27.15, 27.45, 4.15, 4.75, GOLD, SP, true)
	ball("FigureHead", 2.975, 4.94, 27.3, 0.38, GOLD, SP, true)
	cyl("FigureTop", 2.975, 5.13, 5.25, 27.3, 0.12, GOLD, SP, true)
	xp("FigureHalo", Vector3.new(0.03, 0.9, 0.9), 2.975, 4.9, 27.635, Color3.fromRGB(255, 205, 130), Mat.Neon, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	for _, x in { 1.1, 4.8 } do
		cyl("PagodaBase", x, 3.1, 3.25, 27.2, 0.5, GOLD, SP, true)
		cyl("PagodaTerrace", x, 3.25, 3.37, 27.2, 0.4, GOLD, SP, true)
		ball("PagodaBell", x, 3.56, 27.2, 0.38, GOLD, SP, true)
		cyl("PagodaSpire", x, 3.75, 4.2, 27.2, 0.08, GOLD, SP, true)
		ball("PagodaTip", x, 4.26, 27.2, 0.1, GOLD, SP, true)
	end
	for _, x in { 2.0, 3.95 } do
		cyl("Vase", x, 3.1, 3.5, 26.55, 0.28, Color3.fromRGB(40, 110, 70), SP, true)
		for i = -1, 1 do
			ball("Flower", x + i * 0.21, 3.62, 26.55, 0.2, if i == 0 then Color3.fromRGB(240, 200, 60) else Color3.fromRGB(235, 235, 225), SP, true)
		end
	end
	cyl("Candle", 2.97, 3.1, 3.45, 26.55, 0.15, Color3.fromRGB(245, 240, 225), SP, true)
	ball("CandleFlame", 2.97, 3.5, 26.55, 0.08, Color3.fromRGB(255, 190, 90), Mat.Neon, true)
	for _, x in { 1.8, 2.97, 4.15 } do
		cyl("WaterCup", x, 2.5, 2.62, 25.7, 0.16, CHROME, MT, true)
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
	chair(3.1, 13.9, -2, Color3.fromRGB(110, 30, 40), SP, nil, Color3.fromRGB(40, 40, 44)) -- maroon folding chair
	chair(6.2, 13.9, -2, Color3.fromRGB(150, 110, 60), WD, Color3.fromRGB(190, 160, 110)) -- rattan-back chair
	xb("Towel", 5.65, 6.75, 14.52, 14.56, 2.2, 3.3, Color3.fromRGB(220, 120, 50), SP, true)
	xb("CalendarPage", 2.5, 3.9, 12.9, 12.95, 4.5, 6.4, C.white, SP, true)
	for i = 0, 4 do
		xb("CalendarLine", 2.6, 3.8, 12.95, 12.96, 4.7 + i * 0.3, 4.72 + i * 0.3, Color3.fromRGB(170, 170, 170), SP, true)
	end
	flushLamp("HallLamp", 6.0, 15.0, 14)
	-- ---------- back room W (the clip's dark storage room) ----------
	wardrobe(0.75, 3.55, 0.75, 2.6, 7.2, "+z", Color3.fromRGB(55, 35, 25))
	xb("Box", 8.8, 11.2, 0.75, 2.6, 0, 1.6, Color3.fromRGB(170, 130, 85), Mat.Cardboard)
	xb("BoxTape", 9.9, 10.1, 0.75, 2.6, 1.6, 1.61, Color3.fromRGB(225, 200, 120), Mat.Plastic, true)
	xb("Box", 9.1, 10.9, 0.9, 2.4, 1.61, 2.8, Color3.fromRGB(160, 120, 80), Mat.Cardboard)
	xb("BoxTape", 9.1, 10.9, 1.55, 1.75, 2.8, 2.81, Color3.fromRGB(225, 200, 120), Mat.Plastic, true)
	cyl("RedTub", 6.0, 0, 0.9, 1.6, 1.4, C.red, Mat.Plastic, true)
	cyl("RedTubRim", 6.0, 0.9, 1.0, 1.6, 1.5, C.red, Mat.Plastic, true)
	chair(5.2, 5.7, -2, Color3.fromRGB(175, 45, 40), SP, nil, CHROME)
	cyl("SideTableBase", 7.6, 0, 0.1, 5.6, 0.9, C.white, Mat.Plastic, true)
	cyl("SideTableStem", 7.6, 0.1, 1.93, 5.6, 0.14, C.white, Mat.Plastic, true)
	cyl("SideTableTop", 7.6, 1.93, 2.08, 5.6, 1.8, C.white, Mat.Plastic)
	cyl("Stool", 9.6, 0, 0.25, 8.0, 1.2, Color3.fromRGB(150, 110, 60), WD)
	cyl("Stool", 9.6, 0.25, 1.15, 8.0, 1.0, Color3.fromRGB(195, 160, 100), WD)
	cyl("Stool", 9.6, 1.15, 1.35, 8.0, 1.2, Color3.fromRGB(150, 110, 60), WD)
	xb("ShoppingBag", 1.0, 2.2, 9.4, 10.6, 0, 1.6, Color3.fromRGB(200, 170, 120), SP, true)
	xb("BagHandle", 1.5, 1.7, 9.6, 9.65, 1.6, 2.0, Color3.fromRGB(200, 170, 120), SP, true)
	xb("BagHandle", 1.5, 1.7, 10.35, 10.4, 1.6, 2.0, Color3.fromRGB(200, 170, 120), SP, true)
	xb("ShoppingBag", 1.0, 1.9, 10.8, 11.9, 0, 1.3, C.white, Mat.Plastic, true)
	tubeLight("BackTube", 5.2, 7.6, 4.2, 4.5, true)
	xp("PlainFrame", Vector3.new(0.08, 1.8, 2.4), 12.01, 5.6, 8.7, Color3.fromRGB(110, 80, 50), WD, true, nil, CFrame.Angles(math.rad(3), 0, 0))
	xp("FrameMat", Vector3.new(0.02, 1.4, 2.0), 11.96, 5.6, 8.7, Color3.fromRGB(205, 195, 170), SP, true, nil, CFrame.Angles(math.rad(3), 0, 0))
	openable("RoomDoorW", { Kind = "hinge", Angle = 90, BuiltOpen = true, Sound = "door", Label = "Door" }, 11.0, FY + 3.5, 12.3, function()
		doorLeaf("RoomDoor", 10.8, 11.0, 9.55, 12.3, Color3.fromRGB(150, 115, 55))
		P("Knob", Vector3.new(0.28, 0.28, 0.28), CFrame.new(10.66, FY + 3.3, 9.9), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
	end)
	-- ---------- bedroom M ----------
	bed(21.5, 24.35, 0.76, 7.0, Color3.fromRGB(120, 80, 45), Color3.fromRGB(235, 232, 225), Color3.fromRGB(150, 120, 160))
	wardrobe(12.85, 14.75, 3.0, 6.4, 6.8, "+x", DARKWOOD)
	xb("SmallTable", 16.5, 18.5, 7.5, 8.7, 2.4, 2.55, C.pine, WD)
	for _, o in { { 16.55, 7.55 }, { 18.35, 7.55 }, { 16.55, 8.55 }, { 18.35, 8.55 } } do
		xb("TableLeg", o[1], o[1] + 0.1, o[2], o[2] + 0.1, 0, 2.4, C.white, MT, true)
	end
	cyl("TableLampBase", 17.0, 2.55, 2.65, 7.9, 0.4, C.white, SP, true)
	cyl("TableLampStem", 17.0, 2.65, 3.3, 7.9, 0.06, C.white, SP, true)
	cyl("TableLampShade", 17.0, 3.3, 3.75, 7.9, 0.6, Color3.fromRGB(240, 230, 200), SP, true)
	chair(17.5, 9.8, -2, TEAK, WD)
	flushLamp("RoomMLamp", 18.6, 6.4, 14)
	openable("RoomDoorM", { Kind = "hinge", Angle = 90, BuiltOpen = true, Sound = "door", Label = "Door" }, 19.6, FY + 3.5, 12.3, function()
		doorLeaf("RoomDoor", 19.4, 19.6, 9.55, 12.3, Color3.fromRGB(150, 115, 55))
		P("Knob", Vector3.new(0.28, 0.28, 0.28), CFrame.new(19.26, FY + 3.3, 9.9), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
	end)
	-- ---------- dining room: fridge in the outer wall's kitchen-side corner (owner), round wooden table by the living-room door, a sideboard ----------
	-- hollow body: back, sides, top, bottom, a divider; shelves and plain food inside; a lamp lit while a door is open
	local FW, FIN = Color3.fromRGB(205, 205, 202), Color3.fromRGB(232, 236, 238)
	xb("FridgeBack", 32.3, 34.3, 0.75, 0.85, 0.25, 5.6, FW, SP)
	xb("FridgeSide", 32.3, 32.4, 0.85, 2.45, 0.25, 5.6, FW, SP)
	xb("FridgeSide", 34.2, 34.3, 0.85, 2.45, 0.25, 5.6, FW, SP)
	xb("FridgeBase", 32.3, 34.3, 0.75, 2.45, 0, 0.25, FW, SP)
	xb("FridgeTop", 32.4, 34.2, 0.85, 2.45, 5.5, 5.6, FW, SP)
	xb("FridgeBottom", 32.4, 34.2, 0.85, 2.45, 0.25, 0.35, FIN, SP, true)
	xb("FridgeDivider", 32.4, 34.2, 0.85, 2.45, 3.85, 3.9, FIN, SP)
	for _, y in { 1.4, 2.6, 4.7 } do
		xb("FridgeShelf", 32.4, 34.2, 0.85, 2.4, y, y + 0.04, Color3.fromRGB(215, 230, 235), SP, true)
	end
	cyl("FridgeBottle", 32.7, 0.35, 1.25, 1.6, 0.25, Color3.fromRGB(90, 160, 90), SP, true)
	cyl("FridgeBottle", 33.05, 0.35, 1.15, 1.6, 0.25, Color3.fromRGB(230, 230, 235), SP, true)
	xb("FridgeBox", 33.4, 34.0, 1.2, 2.0, 0.35, 0.75, Color3.fromRGB(230, 170, 80), SP, true)
	xb("FridgeTub", 32.6, 33.3, 1.1, 1.9, 1.44, 1.74, Color3.fromRGB(240, 235, 210), SP, true)
	ball("FridgeFruit", 33.7, 1.6, 1.5, 0.32, Color3.fromRGB(220, 90, 60), SP, true)
	ball("FridgeFruit", 33.9, 1.6, 1.9, 0.3, Color3.fromRGB(240, 200, 60), SP, true)
	xb("FridgeCarton", 32.6, 33.0, 1.1, 1.5, 2.64, 3.24, Color3.fromRGB(240, 240, 240), SP, true)
	cyl("FridgeJar", 33.6, 2.64, 3.04, 1.6, 0.35, Color3.fromRGB(200, 120, 60), SP, true)
	xb("FreezerTray", 32.6, 34.0, 1.0, 2.2, 4.74, 4.94, Color3.fromRGB(210, 225, 235), SP, true)
	local lamp = xb("FridgeLamp", 33.1, 33.5, 1.0, 1.3, 3.75, 3.85, Color3.fromRGB(235, 245, 255), Mat.Neon, true)
	if lamp then
		local l = Instance.new("PointLight")
		l.Range, l.Brightness, l.Color, l.Shadows, l.Enabled = 6, 1.2, Color3.fromRGB(225, 240, 255), false, false
		l.Parent = lamp
		game:GetService("CollectionService"):AddTag(lamp, "FridgeLight")
	end
	xb("FridgeKick", 32.35, 34.25, 2.45, 2.5, 0, 0.25, Color3.fromRGB(60, 60, 62), SP, true)
	for i, dd in { { 0.25, 3.85, 1.6, 3.4 }, { 3.9, 5.6, 4.1, 5.0 } } do
		openable(if i == 1 then "FridgeDoor" else "FreezerDoor", { Kind = "hinge", Angle = 88, BuiltOpen = false, Sound = "fridge", Label = "Fridge", LightTag = "FridgeLight" }, 34.3, FY + (dd[1] + dd[2]) / 2, 2.6, function()
			xb(if i == 1 then "FridgeDoor" else "FreezerDoor", 32.3, 34.3, 2.45, 2.6, dd[1], dd[2], Color3.fromRGB(238, 238, 235), SP)
			xb("FridgeHandle", 32.55, 32.65, 2.66, 2.72, dd[3], dd[4], CHROME, MT, true)
			xb("FridgeHandleFoot", 32.55, 32.65, 2.6, 2.66, dd[3], dd[3] + 0.1, CHROME, MT, true)
			xb("FridgeHandleFoot", 32.55, 32.65, 2.6, 2.66, dd[4] - 0.1, dd[4], CHROME, MT, true)
			if i == 1 then
				xb("FridgeMagnetNote", 33.2, 33.7, 2.6, 2.61, 2.0, 2.6, Color3.fromRGB(250, 240, 150), SP, true)
			end
		end)
	end
	cyl("TableTop", 30.7, 2.48, 2.63, 9.0, 3.6, Color3.fromRGB(145, 92, 50), WD)
	cyl("TableColumn", 30.7, 0.12, 2.48, 9.0, 0.35, Color3.fromRGB(110, 70, 40), WD)
	xb("TableFoot", 29.8, 31.6, 8.9, 9.1, 0, 0.12, Color3.fromRGB(110, 70, 40), WD, true)
	xb("TableFoot", 30.6, 30.8, 8.1, 8.9, 0, 0.12, Color3.fromRGB(110, 70, 40), WD, true)
	xb("TableFoot", 30.6, 30.8, 9.1, 9.9, 0, 0.12, Color3.fromRGB(110, 70, 40), WD, true)
	cyl("Thermos", 30.2, 2.63, 3.4, 8.7, 0.35, Color3.fromRGB(200, 60, 60), SP, true)
	cyl("Cup", 31.2, 2.63, 2.85, 9.3, 0.22, C.white, SP, true)
	chair(27.55, 9.0, 1, TEAK, WD, Color3.fromRGB(200, 170, 120))
	chair(33.85, 9.0, -1, TEAK, WD, Color3.fromRGB(200, 170, 120))
	chair(30.7, 5.95, 2, TEAK, WD, Color3.fromRGB(200, 170, 120))
	xb("PendantCord", 30.65, 30.75, 8.95, 9.05, 7.9, CEIL, C.black, SP, true)
	cyl("PendantShade", 30.7, 7.4, 7.9, 9.0, 1.4, Color3.fromRGB(225, 205, 160), SP, true)
	local bulb = ball("PendantBulb", 30.7, 7.25, 9.0, 0.3, Color3.fromRGB(255, 240, 210), Mat.Neon, true)
	light(bulb, 16, 0.75, Color3.fromRGB(255, 236, 205))
	xb("Sideboard", 25.2, 26.4, 4.0, 8.0, 0.2, 2.5, TEAK, WD)
	xb("SideboardPlinth", 25.2, 26.3, 4.0, 8.0, 0, 0.2, DARKWOOD, WD)
	for i, d in { { 4.08, 5.98 }, { 6.02, 7.92 } } do
		local hz = if i == 1 then d[1] else d[2]
		openable("SideboardDoor", { Kind = "hinge", Angle = if i == 1 then 100 else -100, BuiltOpen = false, Sound = "cabinet", Label = "Cabinet" }, 26.45, FY + 1.3, hz, function()
			xb("SideboardDoor", 26.4, 26.45, d[1], d[2], 0.3, 2.4, TEAK:Lerp(Color3.new(1, 1, 1), 0.06), WD)
			local k = if i == 1 then 5.85 else 6.05
			xb("SideboardKnob", 26.45, 26.5, k, k + 0.1, 1.3, 1.45, GOLD, MT, true)
		end)
	end
	cyl("Jar", 25.8, 2.5, 3.1, 4.6, 0.4, Color3.fromRGB(230, 200, 120), SP, true)
	cyl("Jar", 25.8, 2.5, 2.9, 5.3, 0.35, Color3.fromRGB(200, 120, 70), SP, true)
	-- ---------- kitchen: base cabinets with doors, a counter top with a steel sink, the gas stove with a pot ----------
	local CAB = Color3.fromRGB(205, 195, 172)
	xb("KitchenCabinet", 35.1, 37.9, 0.75, 2.5, 0, 2.9, CAB, WD)
	xb("KitchenCabinet", 37.9, 39.3, 0.75, 2.5, 0, 2.4, CAB, WD)
	xb("KitchenCabinet", 39.3, 41.7, 0.75, 2.5, 0, 2.9, CAB, WD)
	for _, d in { { 35.15, 36.48 }, { 36.52, 37.85 }, { 37.95, 39.25 }, { 39.35, 40.48 }, { 40.52, 41.65 } } do
		openable("KitchenDoor", { Kind = "hinge", Angle = -100, BuiltOpen = false, Sound = "cabinet", Label = "Cupboard" }, d[1], FY + 1.2, 2.56, function()
			xb("KitchenDoor", d[1], d[2], 2.5, 2.56, 0.2, 2.3, CAB:Lerp(Color3.new(1, 1, 1), 0.15), WD)
			xb("KitchenHandle", d[2] - 0.5, d[2] - 0.1, 2.56, 2.6, 2.0, 2.1, CHROME, MT, true)
		end)
	end
	local TOP = Color3.fromRGB(110, 115, 118)
	xb("CounterTop", 35.05, 37.9, 0.7, 2.65, 2.9, 3.05, TOP, Mat.Slate)
	xb("CounterTop", 39.3, 41.7, 0.7, 2.65, 2.9, 3.05, TOP, Mat.Slate)
	xb("CounterTop", 37.9, 39.3, 0.7, 1.0, 2.9, 3.05, TOP, Mat.Slate)
	xb("CounterTop", 37.9, 39.3, 2.3, 2.65, 2.9, 3.05, TOP, Mat.Slate)
	xb("SinkBottom", 37.95, 39.25, 1.05, 2.25, 2.4, 2.5, CHROME, MT)
	xb("SinkWall", 37.95, 39.25, 1.05, 1.11, 2.5, 3.0, CHROME, MT, true)
	xb("SinkWall", 37.95, 39.25, 2.19, 2.25, 2.5, 3.0, CHROME, MT, true)
	xb("SinkWall", 37.95, 38.01, 1.11, 2.19, 2.5, 3.0, CHROME, MT, true)
	xb("SinkWall", 39.19, 39.25, 1.11, 2.19, 2.5, 3.0, CHROME, MT, true)
	cyl("Tap", 38.6, 3.05, 3.6, 0.85, 0.1, CHROME, MT, true)
	xb("TapSpout", 38.55, 38.65, 0.9, 1.35, 3.5, 3.6, CHROME, MT, true)
	xb("SideCabinet", 39.85, 41.7, 2.65, 6.3, 0, 2.9, CAB, WD)
	for _, d in { { 2.8, 4.4 }, { 4.5, 6.2 } } do
		openable("KitchenDoor", { Kind = "hinge", Angle = -100, BuiltOpen = false, Sound = "cabinet", Label = "Cupboard" }, 39.79, FY + 1.2, d[1], function()
			xb("KitchenDoor", 39.79, 39.85, d[1], d[2], 0.2, 2.3, CAB:Lerp(Color3.new(1, 1, 1), 0.15), WD)
			xb("KitchenHandle", 39.75, 39.79, d[2] - 0.5, d[2] - 0.1, 2.0, 2.1, CHROME, MT, true)
		end)
	end
	xb("CounterTop", 39.7, 41.75, 2.65, 6.35, 2.9, 3.05, TOP, Mat.Slate)
	xb("GasStove", 40.0, 41.5, 3.0, 5.6, 3.05, 3.3, Color3.fromRGB(28, 28, 30), MT)
	for _, z in { 3.7, 4.9 } do
		cyl("Burner", 40.75, 3.3, 3.36, z, 0.6, Color3.fromRGB(70, 70, 72), MT, true)
		xp("StoveKnob", Vector3.new(0.05, 0.16, 0.16), 39.975, 3.18, z, CHROME, MT, true, Enum.PartType.Cylinder)
	end
	cyl("Pot", 40.75, 3.36, 3.96, 3.7, 0.8, Color3.fromRGB(185, 185, 190), MT, true)
	cyl("PotLid", 40.75, 3.96, 4.0, 3.7, 0.82, Color3.fromRGB(165, 165, 170), MT, true)
	ball("PotKnob", 40.75, 4.05, 3.7, 0.1, C.black, SP, true)
	xb("PotHandle", 40.68, 40.82, 3.28, 3.29, 3.75, 3.82, C.black, SP, true)
	xb("PotHandle", 40.68, 40.82, 4.11, 4.12, 3.75, 3.82, C.black, SP, true)
	cyl("Kettle", 40.75, 3.36, 3.9, 4.9, 0.6, Color3.fromRGB(200, 60, 50), MT, true)
	cyl("RiceCooker", 36.2, 3.05, 3.75, 1.7, 0.8, C.white, SP, true)
	cyl("RiceCookerLid", 36.2, 3.75, 3.85, 1.7, 0.7, Color3.fromRGB(190, 190, 192), SP, true)
	xb("WallShelf", 35.3, 37.6, 0.65, 1.3, 6.0, 6.1, CAB, WD, true)
	for i, x in { 35.6, 36.2, 36.8, 37.3 } do
		cyl("ShelfJar", x, 6.1, 6.5 + (i % 2) * 0.15, 0.95, 0.3, Color3.fromRGB(220, 200 - i * 20, 120), SP, true)
	end
	xb("WaterDispenser", 35.2, 36.2, 4.8, 5.8, 0, 3.4, C.white, SP)
	xb("DispenserTap", 35.6, 35.8, 4.74, 4.8, 2.2, 2.4, Color3.fromRGB(60, 120, 200), SP, true)
	cyl("WaterBottle", 35.7, 3.4, 4.7, 5.3, 0.85, Color3.fromRGB(120, 175, 215), SP, true)
	tubeLight("KitchenTube", 37.2, 37.5, 2.5, 5.5, true)
	-- ---------- bathroom: a sitting toilet, the shower pipe with valve and head, a water drum with dipper, a bucket ----------
	xb("ToiletPedestal", 40.6, 41.25, 10.85, 11.45, 0, 0.9, C.white, SP)
	xb("ToiletBowl", 40.35, 41.25, 10.7, 11.6, 0.9, 1.35, C.white, SP)
	cyl("ToiletSeat", 40.8, 1.35, 1.41, 11.15, 0.85, Color3.fromRGB(245, 245, 242), SP, true)
	xb("ToiletLid", 41.18, 41.24, 10.75, 11.55, 1.41, 2.3, Color3.fromRGB(245, 245, 242), SP, true)
	xb("ToiletTank", 41.25, 41.7, 10.55, 11.75, 1.25, 2.6, C.white, SP)
	cyl("FlushButton", 41.47, 2.6, 2.65, 11.15, 0.18, CHROME, MT, true)
	xb("ShowerPipe", 41.55, 41.65, 9.0, 9.1, 0.5, 6.4, CHROME, MT, true)
	xp("ShowerValve", Vector3.new(0.1, 0.3, 0.3), 41.5, 3.8, 9.05, CHROME, MT, true, Enum.PartType.Cylinder)
	xb("ShowerArm", 41.2, 41.55, 8.95, 9.15, 6.4, 6.55, CHROME, MT, true)
	cyl("ShowerHead", 41.15, 6.31, 6.39, 9.05, 0.5, CHROME, MT, true)
	cyl("WaterDrum", 39.3, 0, 2.0, 11.5, 1.2, Color3.fromRGB(50, 110, 190), Mat.Plastic, true)
	cyl("Dipper", 39.3, 2.0, 2.2, 11.5, 0.45, Color3.fromRGB(240, 200, 60), Mat.Plastic, true)
	cyl("Bucket", 40.6, 0, 0.8, 9.0, 0.8, Color3.fromRGB(60, 120, 200), Mat.Plastic, true)
	cyl("FloorDrain", 40.0, 0, 0.01, 10.0, 0.3, Color3.fromRGB(150, 150, 152), MT, true)
	for _, y in { 3.0, 6.0 } do
		xb("TileLine", 41.74, 41.75, 7.05, 12.25, y, y + 0.03, Color3.fromRGB(95, 130, 115), SP, true)
		xb("TileLine", 38.65, 41.75, 7.05, 7.06, y, y + 0.03, Color3.fromRGB(95, 130, 115), SP, true)
		xb("TileLine", 38.65, 41.75, 12.24, 12.25, y, y + 0.03, Color3.fromRGB(95, 130, 115), SP, true)
	end
	local bb = ball("BathBulb", 40.2, CEIL - 0.2, 9.8, 0.3, Color3.fromRGB(255, 245, 225), Mat.Neon, true)
	cyl("BathBulbHolder", 40.2, CEIL - 0.05, CEIL, 9.8, 0.25, C.white, SP, true)
	light(bb, 10, 0.6, Color3.fromRGB(255, 240, 215))
	-- the sink outside the bathroom, in the kitchen / dining corner
	xb("SinkPedestal", 35.6, 36.0, 11.6, 12.0, 0, 2.4, C.white, SP)
	xb("SinkBasin", 35.1, 36.5, 11.1, 12.25, 2.4, 2.9, C.white, SP)
	xb("SinkBowl", 35.3, 36.3, 11.25, 12.05, 2.9, 2.91, Color3.fromRGB(205, 210, 212), SP, true)
	xb("SinkTap", 35.75, 35.85, 12.08, 12.25, 2.9, 3.25, CHROME, MT, true)
	xb("MirrorFrame", 35.1, 36.5, 12.27, 12.3, 3.5, 5.5, DARKWOOD, WD, true)
	xb("Mirror", 35.2, 36.4, 12.25, 12.27, 3.6, 5.4, Color3.fromRGB(180, 200, 205), SP, true).Reflectance = 0.3
	xb("SoapShelf", 35.3, 36.3, 12.0, 12.25, 3.25, 3.32, C.white, SP, true)
	-- ---------- yellow room (the clip's room with the desk) ----------
	-- owner's mark-up: wardrobe in the north-west corner, small shelves next to it, the big book shelf between the
	-- wardrobe and the bed, the bed's head on the west wall (lower left), piano on the east wall, PC desk + chair in the
	-- south-east corner
	bedX(9.35, 15.6, 22.0, 26.3, C.yellowWood, Color3.fromRGB(240, 236, 232), Color3.fromRGB(120, 130, 175), 928)
	xb("SideTop", 9.35, 10.75, 26.4, 27.8, 2.1, 2.25, C.pine, WD)
	xb("SideShelf", 9.5, 10.6, 26.55, 27.65, 0.8, 0.88, C.pine, WD, true)
	for _, o in { { 9.4, 26.45 }, { 10.6, 26.45 }, { 9.4, 27.65 }, { 10.6, 27.65 } } do
		xb("SideLeg", o[1], o[1] + 0.1, o[2], o[2] + 0.1, 0, 2.1, C.white, MT, true)
	end
	xb("Tissues", 9.5, 10.0, 26.6, 27.0, 2.25, 2.6, Color3.fromRGB(240, 220, 110), Mat.Cardboard, true)
	cyl("LampBase", 10.4, 2.25, 2.33, 27.3, 0.35, C.black, MT, true)
	cyl("LampStem", 10.4, 2.33, 3.0, 27.3, 0.05, C.black, MT, true)
	ball("LampHead", 10.4, 3.2, 27.3, 0.4, C.white, SP, true)
	-- the big book shelf (white X-braced frame, pine shelves): back on the west wall, shelves facing into the room
	-- (owner's sketch), between the wardrobe and the bed's head
	for _, p in { { 9.35, 20.0 }, { 10.53, 20.0 }, { 9.35, 21.83 }, { 10.53, 21.83 } } do
		xb("ShelfPost", p[1], p[1] + 0.12, p[2], p[2] + 0.12, 0, 6.0, C.white, MT)
	end
	for i = 0, 3 do
		local y = 0.3 + i * 1.8
		xb("PineShelf", 9.35, 10.65, 20.12, 21.83, y, y + 0.1, C.pine, WD)
		booksX(9.45, 10.55, 20.2, 21.75, y + 0.1, 1.4, 40 + i)
	end
	local bl = math.sqrt(1.06 ^ 2 + 5.6 ^ 2) - 0.3
	local ba = math.atan2(1.06, 5.6)
	xp("ShelfBrace", Vector3.new(0.06, bl, 0.02), 10.0, 3.0, 19.965, C.white, MT, true, nil, CFrame.Angles(0, 0, ba))
	xp("ShelfBrace", Vector3.new(0.06, bl, 0.02), 10.0, 3.0, 19.985, C.white, MT, true, nil, CFrame.Angles(0, 0, -ba))
	-- the small shelves by the wardrobe (two low open units with decorations)
	for i, x0 in { 13.3, 14.75 } do
		xb("SmallShelfSide", x0, x0 + 0.08, 17.95, 19.15, 0, 3.0, C.white, Mat.Plastic)
		xb("SmallShelfSide", x0 + 1.27, x0 + 1.35, 17.95, 19.15, 0, 3.0, C.white, Mat.Plastic)
		for _, y in { 0, 1.45, 2.9 } do
			xb("SmallShelfBoard", x0 + 0.08, x0 + 1.27, 17.95, 19.15, y, y + 0.1, C.pine, WD)
		end
		booksX(x0 + 0.15, x0 + 1.2, 18.05, 19.05, 0.1, 1.15, 50 + i)
	end
	ball("SoftToy", 13.7, 1.8, 18.6, 0.5, Color3.fromRGB(150, 190, 230), SP, true)
	cyl("PenMug", 14.3, 1.55, 1.85, 18.5, 0.3, Color3.fromRGB(230, 80, 70), SP, true)
	cyl("Jar", 15.3, 1.55, 2.05, 18.5, 0.35, Color3.fromRGB(240, 220, 170), SP, true)
	xb("Planter", 15.6, 16.0, 18.3, 18.8, 3.0, 3.35, Color3.fromRGB(220, 215, 200), SP, true)
	ball("PlanterLeaves", 15.8, 3.6, 18.55, 0.5, Color3.fromRGB(130, 170, 70), SP, true)
	-- air cooler by the bed's foot: castors, body, louvres (facing the bed), water window, top cap with buttons
	for _, x in { 16.4, 17.3 } do
		for _, z in { 25.15, 25.85 } do
			ball("Castor", x, 0.1, z, 0.2, C.black, Mat.Rubber, true)
		end
	end
	xb("AirCooler", 16.25, 17.45, 25.0, 26.0, 0.2, 3.0, Color3.fromRGB(235, 235, 232), Mat.Plastic)
	xb("CoolerCap", 16.3, 17.4, 25.05, 25.95, 3.0, 3.2, Color3.fromRGB(215, 215, 212), Mat.Plastic)
	xb("CoolerButtons", 16.55, 17.15, 25.6, 25.8, 3.2, 3.23, Color3.fromRGB(60, 140, 200), Mat.Neon, true)
	for i = 0, 5 do
		xb("CoolerLouvre", 16.21, 16.25, 25.1, 25.9, 1.1 + i * 0.3, 1.22 + i * 0.3, Color3.fromRGB(150, 155, 160), Mat.Plastic, true)
	end
	xb("CoolerWater", 16.22, 16.25, 25.2, 25.8, 0.45, 0.85, Color3.fromRGB(150, 190, 220), Mat.Plastic, true)
	-- round wall light (white diffuser, blue-silver rim) on surface conduit, a square clock, a ceiling fan
	xp("WallLightRim", Vector3.new(0.08, 1.6, 1.6), 13.6, 6.4, 17.94, Color3.fromRGB(140, 165, 200), MT, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	local wl = xp("WallLight", Vector3.new(0.06, 1.2, 1.2), 13.6, 6.4, 18.01, Color3.fromRGB(250, 250, 248), Mat.Neon, true, Enum.PartType.Cylinder, CFrame.Angles(0, math.rad(90), 0))
	light(wl, 18, 0.8, Color3.fromRGB(245, 248, 255))
	xb("Conduit", 13.55, 13.65, 17.9, 17.98, 7.2, CEIL, C.white, Mat.Plastic, true)
	xb("ClockFrame", 10.0, 11.0, 17.9, 17.98, 7.6, 8.6, DARKWOOD, WD, true)
	xb("ClockFace", 10.12, 10.88, 17.98, 18.0, 7.72, 8.48, C.white, SP, true)
	xb("ClockHand", 10.47, 10.53, 18.0, 18.01, 8.1, 8.4, C.black, SP, true)
	ceilingFan(17.0, 25.6)
	wardrobe(9.35, 12.9, 18.0, 19.85, 6.8, "+z", DARKWOOD)
	xb("BoxOnTop", 9.6, 12.6, 18.1, 19.6, 6.92, 7.9, Color3.fromRGB(165, 125, 80), Mat.Cardboard, true)
	xb("BoxTape", 9.6, 12.6, 18.75, 18.95, 7.9, 7.91, Color3.fromRGB(235, 200, 60), Mat.Plastic, true)
	-- PC desk in the south-east corner with its back on the south wall: you sit facing that wall (owner: "the pc set up &
	-- chair needs to face the other wall"). Wide top (1.35 m) with the monitor, keyboard, mouse and the PC case on it.
	xb("DeskTop", 19.8, 23.85, 25.15, 27.8, 2.45, 2.65, C.brown, WD)
	xb("DeskPedestal", 22.35, 23.85, 25.4, 27.8, 0, 2.45, Color3.fromRGB(62, 40, 28), WD)
	xb("DeskLeg", 19.85, 20.05, 25.2, 25.4, 0, 2.45, C.brown, WD)
	xb("DeskLeg", 19.85, 20.05, 27.6, 27.8, 0, 2.45, C.brown, WD)
	xb("DeskModesty", 20.05, 22.35, 27.6, 27.8, 0.6, 2.45, C.brown, WD)
	for i = 0, 2 do
		openable("Drawer", { Kind = "drawer", SlideL = Vector3.new(0, 0, -0.9), BuiltOpen = false, Sound = "drawer", Label = "Drawer", Reach = 6 }, 22.45, FY + 0.2 + i * 0.75, 25.34, function()
			xb("DrawerFront", 22.45, 23.75, 25.34, 25.4, 0.2 + i * 0.75, 0.85 + i * 0.75, Color3.fromRGB(78, 52, 36), WD)
			xb("DrawerPull", 22.9, 23.3, 25.3, 25.34, 0.5 + i * 0.75, 0.58 + i * 0.75, GOLD, MT, true)
		end)
	end
	xb("DeskMat", 20.7, 22.9, 25.5, 26.8, 2.65, 2.67, Color3.fromRGB(110, 110, 112), SP, true)
	xb("MonitorStand", 21.4, 22.0, 27.3, 27.7, 2.65, 2.7, C.black, MT, true)
	xb("MonitorNeck", 21.65, 21.75, 27.45, 27.55, 2.7, 3.1, C.black, MT, true)
	xb("Monitor", 20.5, 22.9, 27.2, 27.35, 3.1, 4.8, Color3.fromRGB(18, 18, 20), SP, true)
	xb("MonitorScreen", 20.58, 22.82, 27.17, 27.2, 3.18, 4.72, Color3.fromRGB(34, 44, 66), Mat.Neon, true)
	xb("Webcam", 21.6, 21.8, 27.23, 27.33, 4.8, 4.9, C.black, SP, true)
	xb("Keyboard", 20.8, 22.6, 25.7, 26.1, 2.67, 2.75, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	xb("Mouse", 22.7, 22.9, 25.75, 26.0, 2.67, 2.78, Color3.fromRGB(35, 35, 38), Mat.Plastic, true)
	xb("Tower", 23.0, 23.65, 26.1, 27.45, 2.65, 4.05, Color3.fromRGB(28, 28, 30), SP)
	xb("TowerButton", 23.25, 23.35, 26.06, 26.1, 3.75, 3.85, Color3.fromRGB(120, 200, 255), Mat.Neon, true)
	xb("TowerVent", 23.1, 23.55, 26.06, 26.1, 2.8, 3.5, Color3.fromRGB(55, 55, 60), SP, true)
	officeChair(21.3, 23.95, 2, C.black)
	-- the digital upright piano, white plastic, full 88-key width (1.4 m): cheeks, key bed, white keys, black keys,
	-- fallboard with the gold strip, music desk, kickboard, 3 pedals, lid
	local PW = Color3.fromRGB(242, 242, 238)
	local Z0, Z1 = 18.95, 23.35
	xb("PianoBody", 22.95, 23.85, Z0 + 0.15, Z1 - 0.15, 0, 3.9, PW, SP)
	xb("PianoCheek", 22.35, 23.85, Z0, Z0 + 0.15, 0, 2.6, PW, SP)
	xb("PianoCheek", 22.35, 23.85, Z1 - 0.15, Z1, 0, 2.6, PW, SP)
	xb("PianoCheekTop", 22.95, 23.85, Z0, Z0 + 0.15, 2.6, 3.9, PW, SP)
	xb("PianoCheekTop", 22.95, 23.85, Z1 - 0.15, Z1, 2.6, 3.9, PW, SP)
	xb("PianoKeyBed", 22.35, 22.95, Z0 + 0.15, Z1 - 0.15, 2.0, 2.2, PW, SP)
	xb("PianoKeys", 22.4, 22.85, Z0 + 0.2, Z1 - 0.2, 2.2, 2.28, Color3.fromRGB(250, 250, 248), SP)
	do
		local w = (Z1 - Z0 - 0.4) / 52
		local k = 0
		for i = 1, 51 do
			local inOct = (i - 1) % 7 -- black keys after C, D, F, G, A
			if inOct == 0 or inOct == 1 or inOct == 3 or inOct == 4 or inOct == 5 then
				if i > 1 or true then
					local z = Z0 + 0.2 + i * w
					xb("PianoBlackKey", 22.6, 22.85, z - w * 0.3, z + w * 0.3, 2.28, 2.36, C.black, SP, true)
					k += 1
				end
			end
		end
	end
	xb("PianoFallboard", 22.85, 22.95, Z0 + 0.15, Z1 - 0.15, 2.2, 2.55, PW, SP)
	xb("PianoGoldStrip", 22.82, 22.85, Z0 + 0.2, Z1 - 0.2, 2.45, 2.5, GOLD, MT, true)
	xb("PianoMusicDesk", 22.8, 22.95, Z0 + 0.6, Z1 - 0.6, 2.55, 3.4, PW, SP, true)
	xb("SheetMusic", 22.77, 22.8, Z0 + 1.2, Z1 - 1.4, 2.7, 3.3, Color3.fromRGB(245, 243, 235), SP, true)
	xb("PianoKick", 22.8, 22.95, Z0 + 0.15, Z1 - 0.15, 0.3, 2.0, Color3.fromRGB(228, 228, 224), SP)
	for _, z in { 20.75, 21.15, 21.55 } do
		xb("PianoPedal", 22.5, 22.8, z, z + 0.15, 0.15, 0.25, GOLD, MT, true)
	end
	xb("PianoLid", 22.9, 23.85, Z0 + 0.15, Z1 - 0.15, 3.9, 3.98, Color3.fromRGB(235, 235, 231), SP)
	xb("MusicStack", 23.05, 23.7, 20.2, 21.6, 3.98, 4.5, Color3.fromRGB(240, 238, 230), SP, true)
	xb("WhiteboardFrame", 23.9, 23.95, 19.4, 22.9, 4.5, 6.5, Color3.fromRGB(170, 172, 175), MT, true)
	xb("Whiteboard", 23.88, 23.9, 19.5, 22.8, 4.6, 6.4, C.white, SP, true)
	for _, p in { { 19.5, 4.6 }, { 22.5, 4.6 }, { 19.5, 6.1 }, { 22.5, 6.1 } } do
		xb("GreenTape", 23.87, 23.88, p[1], p[1] + 0.3, p[2], p[2] + 0.3, Color3.fromRGB(70, 160, 80), Mat.Plastic, true)
	end
	-- window: curtains on a chrome rail, the split AC above (brand made up)
	curtains(12.9, 17.1, 27.5)
	xb("SplitAC", 13.1, 16.9, 27.15, 27.93, 8.6, 9.35, C.white, SP, true)
	xb("ACVent", 13.3, 16.7, 27.12, 27.15, 8.62, 8.72, Color3.fromRGB(190, 192, 195), SP, true)
	local logo = xb("ACLogo", 14.5, 15.5, 27.12, 27.15, 8.95, 9.2, C.white, SP, true)
	if logo then
		text(logo, Enum.NormalId.Front, "KOOLA", Color3.fromRGB(80, 110, 160))
	end
	-- mint drop beam, board-panel joints, the twisted red / black wire in a corner
	xb("DropBeam", 9.25, 23.95, 22.6, 23.3, CEIL - 0.7, CEIL, C.mint, SP)
	for _, z in { 21.6, 24.0 } do
		xb("PanelJoint", 9.25, 9.27, z, z + 0.06, 3.85, CEIL - 0.01, Color3.fromRGB(150, 170, 160), SP, true)
	end
	xb("TwistedWire", 23.9, 23.95, 27.85, 27.9, 0.36, CEIL, Color3.fromRGB(120, 25, 25), Mat.Rubber, true)
	-- the yellow room's door: dark red-brown frame on the hall side, panelled leaf open into the room
	xb("DoorFrameRB", 18.75, 19.0, 17.14, 17.2, 0, 7.25, C.frameRB, WD, true)
	xb("DoorFrameRB", 22.4, 22.65, 17.14, 17.2, 0, 7.25, C.frameRB, WD, true)
	xb("DoorFrameRB", 19.0, 22.4, 17.14, 17.2, 7.0, 7.25, C.frameRB, WD, true)
	openable("YellowDoor", { Kind = "hinge", Angle = 90, BuiltOpen = true, Sound = "door", Label = "Door" }, 19.0, FY + 3.5, 17.8, function()
		doorLeaf("YellowDoor", 19.0, 19.2, 17.8, 21.2, Color3.fromRGB(150, 115, 55))
		xb("DoorPanel", 19.2, 19.26, 18.3, 20.8, 3.9, 6.4, Color3.fromRGB(135, 100, 45), WD, true)
		xb("DoorPanel", 19.2, 19.26, 18.3, 20.8, 0.6, 3.5, Color3.fromRGB(135, 100, 45), WD, true)
		P("Knob", Vector3.new(0.28, 0.28, 0.28), CFrame.new(19.4, FY + 3.3, 20.85), Color3.fromRGB(95, 70, 45), Mat.Metal, true, Enum.PartType.Ball)
	end)
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

-- ===== spacious (owner 26 Nov: "the building is bigger in real life", "its spacious. in game its so tight") =====
-- After the build, the block west of the stair wall (x < 41.8) and north of the front-door line (z < 24) is stretched by
-- GROW in plan: walls, slabs, linings, windows, grilles and doors stretch; furniture keeps its true size and moves as
-- whole pieces (each piece keeps its gap to the wall it stands at); the stair core and its landings never move.
M.GROW = 1.3
local XB, ZB = 41.8, 24.0
local function tx(x: number): number
	return if x < XB then XB - (XB - x) * M.GROW else x
end
local function tz(z: number): number
	return if z < ZB then ZB - (ZB - z) * M.GROW else z
end
local STRUCT = { "^Wall", "^Lin", "^Skirting", "^FloorBoards", "^Ceiling", "^FlatWall", "^Grille", "^RoomDoor", "^BathDoor",
	"^YellowDoor", "^DoorPanel", "^DoorFrameRB", "^OurDoor", "^PanelJoint", "^DropBeam", "^TileLine", "^TwistedWire" }
local function isStruct(n: string): boolean
	for _, pat in STRUCT do
		if string.match(n, pat) then
			return true
		end
	end
	return false
end
local CARPORT = { CarportPad = true, CarportRoof = true, TrussTop = true, TrussBottom = true, TrussDiag = true, CarportPost = true,
	Rafter = true, Scallop = true, PipeBlue = true, JunctionBox = true, BreezeBlock = true }

local function localBox(p: BasePart, inv: CFrame): (Vector3, Vector3)
	local cf = inv * p.CFrame
	local s = p.Size / 2
	local ext = Vector3.new(
		math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
		math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
		math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
	return cf.Position - ext, cf.Position + ext
end

-- stretch one part: its axes that lie along the frame's X / Z take the new extent; the rest only move
local function stretch(p: BasePart, inv: CFrame)
	local cf = inv * p.CFrame
	local lo, hi = localBox(p, inv)
	local block = not p:IsA("Part") or (p :: Part).Shape == Enum.PartType.Block
	local nx0, nx1, nz0, nz1 = tx(lo.X), tx(hi.X), tz(lo.Z), tz(hi.Z)
	local size = p.Size
	local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
	local comps = { size.X, size.Y, size.Z }
	if block and p:IsA("Part") then
		for i, a in axes do
			if math.abs(a.X) > 0.999 then
				comps[i] = nx1 - nx0
			elseif math.abs(a.Z) > 0.999 then
				comps[i] = nz1 - nz0
			end
		end
	end
	local c = cf.Position
	local nc = Vector3.new(if block then (nx0 + nx1) / 2 else tx(c.X), c.Y, if block then (nz0 + nz1) / 2 else tz(c.Z))
	p.Size = Vector3.new(comps[1], comps[2], comps[3])
	p.CFrame = F * (CFrame.new(nc) * (cf - cf.Position))
end

function M.grow(): string
	local m = workspace:FindFirstChild(M.NAME, true)
	local inv = F:Inverse()
	local flatLo, flatHi = FY - 1.0, FY + CEIL + 0.7
	local furniture, moved, rigid = {}, 0, 0
	local walls = {} -- structural boxes of the flat (before the stretch) for the anchors
	for _, p in m:GetDescendants() do
		if not p:IsA("BasePart") then
			continue
		end
		local lo, hi = localBox(p, inv)
		local stairCore = p:IsDescendantOf(m.Inside) and lo.X >= XB - 0.001 and lo.Z >= 10.99
		if stairCore or CARPORT[p.Name] then
			rigid += 1
		elseif p:IsDescendantOf(m.Inside) and (lo.Y + hi.Y) / 2 > flatLo and (lo.Y + hi.Y) / 2 < flatHi and not isStruct(p.Name) then
			table.insert(furniture, { p = p, lo = lo, hi = hi })
		else
			if p:IsDescendantOf(m.Inside) and isStruct(p.Name) then
				table.insert(walls, { lo = lo, hi = hi })
			end
			stretch(p, inv)
			moved += 1
		end
	end
	-- furniture: pieces = parts that touch (union-find on boxes 0.06 apart); each piece moves as one
	local n = #furniture
	local parentOf = {}
	for i = 1, n do
		parentOf[i] = i
	end
	local function find(i)
		while parentOf[i] ~= i do
			parentOf[i] = parentOf[parentOf[i]]
			i = parentOf[i]
		end
		return i
	end
	local tol = 0.06
	for i = 1, n do
		local a = furniture[i]
		for j = i + 1, n do
			local b = furniture[j]
			if a.lo.X <= b.hi.X + tol and b.lo.X <= a.hi.X + tol and a.lo.Y <= b.hi.Y + tol and b.lo.Y <= a.hi.Y + tol and a.lo.Z <= b.hi.Z + tol and b.lo.Z <= a.hi.Z + tol then
				parentOf[find(i)] = find(j)
			end
		end
		if i % 300 == 0 then
			task.wait()
		end
	end
	local firstOf = {}
	for i = 1, n do
		local pid = furniture[i].p:GetAttribute("Piece")
		if pid then
			if firstOf[pid] then
				parentOf[find(i)] = find(firstOf[pid])
			else
				firstOf[pid] = i
			end
		end
	end
	local groups = {}
	for i = 1, n do
		local r = find(i)
		local g = groups[r]
		if not g then
			g = { parts = {}, lo = furniture[i].lo, hi = furniture[i].hi }
			groups[r] = g
		end
		table.insert(g.parts, furniture[i].p)
		g.lo = g.lo:Min(furniture[i].lo)
		g.hi = g.hi:Max(furniture[i].hi)
	end
	-- the nearest wall face on each side of a piece (within 1.5 studs): keep that gap; otherwise move its middle
	local function gapSide(g, axis): string
		local best, side = 1.5, "mid"
		for _, w in walls do
			local overlapY = w.lo.Y < g.hi.Y and g.lo.Y < w.hi.Y
			if overlapY then
				if axis == "X" and w.lo.Z < g.hi.Z and g.lo.Z < w.hi.Z then
					local d1, d2 = g.lo.X - w.hi.X, w.lo.X - g.hi.X
					if d1 >= -0.01 and d1 < best then
						best, side = d1, "lo"
					end
					if d2 >= -0.01 and d2 < best then
						best, side = d2, "hi"
					end
				elseif axis == "Z" and w.lo.X < g.hi.X and g.lo.X < w.hi.X then
					local d1, d2 = g.lo.Z - w.hi.Z, w.lo.Z - g.hi.Z
					if d1 >= -0.01 and d1 < best then
						best, side = d1, "lo"
					end
					if d2 >= -0.01 and d2 < best then
						best, side = d2, "hi"
					end
				end
			end
		end
		return side
	end
	local pieces = 0
	for _, g in groups do
		local sx, sz = gapSide(g, "X"), gapSide(g, "Z")
		local dx = if sx == "lo" then tx(g.lo.X) - g.lo.X elseif sx == "hi" then tx(g.hi.X) - g.hi.X else tx((g.lo.X + g.hi.X) / 2) - (g.lo.X + g.hi.X) / 2
		local dz = if sz == "lo" then tz(g.lo.Z) - g.lo.Z elseif sz == "hi" then tz(g.hi.Z) - g.hi.Z else tz((g.lo.Z + g.hi.Z) / 2) - (g.lo.Z + g.hi.Z) / 2
		local shift = F:VectorToWorldSpace(Vector3.new(dx, 0, dz))
		for _, p in g.parts do
			p.CFrame = p.CFrame + shift
		end
		pieces += 1
	end
	-- close the slot the stretch opens between the flat's stair-side wall and the stair core's west wall
	parent = m.Inside
	box("FlatWall", 41.8, FY, tz(11.0), 42.4, FY + CEIL, 11.0, C.hall, Mat.SmoothPlastic)
	-- keep the clients' kit detail out of the bigger footprint
	local ko = ReplicatedStorage.YgnKit:FindFirstChild("KeepOut")
	local old = ko and ko:FindFirstChild("MyittarNyunt_grown")
	if old then
		old:Destroy()
	end
	if ko then
		local b = Instance.new("Part")
		b.Name = "MyittarNyunt_grown"
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch = true, false, false, false
		b.Transparency = 1
		local x0, x1, z0, z1 = tx(0) - 3, 83, tz(0) - 3, 47
		b.Size = Vector3.new(x1 - x0, 80, z1 - z0)
		b.CFrame = F * CFrame.new((x0 + x1) / 2, 25, (z0 + z1) / 2)
		b.Parent = ko
	end
	return string.format("grown x%.2f: %d stretched, %d rigid, %d furniture parts in %d pieces", M.GROW, moved, rigid, n, pieces)
end

-- ===== the owner's own furniture placing (26 Nov) =====
-- He moved the living room and bathroom furniture by hand in Studio. Those parts are kept in
-- tools/yangon/MyittarNyuntOwnerEdits.luau (ServerStorage.ClaudeTools.MyittarNyuntOwnerEdits): every rebuild removes its
-- own furniture in those two rooms and puts his parts back exactly; the TV cabinet's doors and the drawer tower's
-- drawers become openables where he put them.
local KEEP = { Knob = true, Peephole = true, Hinge = true }
local function inLiving(c: Vector3)
	return c.X >= 19.4 and c.X < 41.8 and c.Z >= 9.5
end
local function inBath(c: Vector3)
	return c.X >= 37.0 and c.X < 41.8 and c.Z >= 1.8 and c.Z <= 8.85
end
local function ownerEdits(ins: Instance): string
	local mod = ServerStorage:FindFirstChild("ClaudeTools") and ServerStorage.ClaudeTools:FindFirstChild("MyittarNyuntOwnerEdits")
	if not mod then
		return "owner edits: data missing (kept the builder's furniture)"
	end
	local rows = require(mod:Clone())
	local inv = F:Inverse()
	local removed = 0
	-- the builder's own openables in those rooms go too (not the front door or its gate)
	for _, m in ins:GetChildren() do
		local h = m:IsA("Model") and m:GetAttribute("Kind") and m:FindFirstChild("Hinge")
		if h and m.Name ~= "FrontDoor" and m.Name ~= "FrontGate" then
			local c = (inv * h.CFrame).Position
			if c.Y > FY - 1 and c.Y < FY + CEIL + 0.7 and (inLiving(c) or inBath(c)) then
				m:Destroy()
				removed += 1
			end
		end
	end
	for _, p in ins:GetDescendants() do
		if p:IsA("BasePart") and not KEEP[p.Name] and not isStruct(p.Name) and not p:FindFirstAncestorWhichIsA("Model"):GetAttribute("Kind") then
			local c = (inv * p.CFrame).Position
			if c.Y > FY - 1 and c.Y < FY + CEIL + 0.7 and (inLiving(c) or inBath(c)) then
				p:Destroy()
				removed += 1
			end
		end
	end
	local made = {}
	parent = ins
	for _, r in rows do
		local q = Instance.new("Part")
		q.Name = r.n
		q.Shape = Enum.PartType[r.shape]
		q.Size = Vector3.new(r.s[1], r.s[2], r.s[3])
		q.CFrame = F * CFrame.new(table.unpack(r.cf))
		q.Color = Color3.fromRGB(r.c[1], r.c[2], r.c[3])
		q.Material = Enum.Material[r.mat]
		q.Reflectance, q.Transparency = r.refl, r.tr
		q.CanCollide, q.CastShadow, q.CanQuery = r.col, r.sh, r.q
		q.CanTouch = r.col
		q.Anchored = true
		q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if r.n == "TVScreenSky" then
			q.Color = Color3.fromRGB(34, 46, 64) -- a dim picture (his place, our brightness)
		elseif r.n == "TVScreenLand" then
			q.Color = Color3.fromRGB(30, 42, 32)
		end
		if r.light then
			light(q, r.light[1], r.light[2], Color3.fromRGB(r.light[3], r.light[4], r.light[5]))
		end
		q.Parent = ins
		table.insert(made, q)
	end
	-- his TV cabinet doors and drawer-tower drawers become openables where they stand
	local function nearest(name: string, to: BasePart): BasePart?
		local best, bd = nil, 1.2
		for _, q in made do
			if q.Name == name and q.Parent == ins then
				local d = (q.Position - to.Position).Magnitude
				if d < bd then
					best, bd = q, d
				end
			end
		end
		return best
	end
	local function wrap(name: string, attrs, hingeWorld: Vector3, parts: { BasePart })
		local m = Instance.new("Model")
		m.Name = name
		for k, v in attrs do
			m:SetAttribute(k, v)
		end
		m.Parent = ins
		for _, q in parts do
			q.Parent = m
		end
		local h = Instance.new("Part")
		h.Name = "Hinge"
		h.Size = Vector3.new(0.02, 0.02, 0.02)
		h.CFrame = F.Rotation + hingeWorld
		h.Anchored, h.CanCollide, h.CanQuery, h.CanTouch = true, false, false, false
		h.Transparency = 1
		h.Parent = m
		game:GetService("CollectionService"):AddTag(m, "Openable")
	end
	local cab
	for _, q in made do
		if q.Name == "TVCabinet" then
			cab = q
		end
	end
	local nOpen = 0
	for _, q in made do
		if q.Name == "CabinetDoor" and cab and q.Parent == ins then
			-- hinge on the door's outer end (away from the cabinet's middle along the door), swinging away from the cabinet
			local right = q.CFrame.RightVector
			local side = if (q.Position - cab.Position):Dot(right) >= 0 then 1 else -1
			local hingeW = q.Position + right * side * q.Size.X / 2
			local out = q.Position - cab.Position
			out = (out - right * out:Dot(right)).Unit
			local best, ang = -1e9, 100
			for _, a in { 100, -100 } do
				local moved = (CFrame.new(hingeW) * CFrame.Angles(0, math.rad(a), 0) * CFrame.new(-hingeW) * q.CFrame).Position
				local score = (moved - q.Position):Dot(out)
				if score > best then
					best, ang = score, a
				end
			end
			local parts = { q }
			local k = nearest("CabinetKnob", q)
			if k then
				table.insert(parts, k)
			end
			wrap("CabinetDoor", { Kind = "hinge", Angle = ang, BuiltOpen = false, Sound = "cabinet", Label = "Cabinet" }, hingeW, parts)
			nOpen += 1
		end
	end
	local frame
	for _, q in made do
		if q.Name == "DrawerTowerFrame" then
			frame = q
		end
	end
	for _, q in made do
		if q.Name == "Drawer" and frame and q.Parent == ins then
			local thin = q.CFrame.RightVector
			local dir = if (q.Position - frame.Position):Dot(thin) >= 0 then thin else -thin
			local slideL = F:VectorToObjectSpace(dir * 0.8)
			local parts = { q }
			local hnd = nearest("DrawerHandle", q)
			if hnd then
				table.insert(parts, hnd)
			end
			wrap("Drawer", { Kind = "drawer", SlideL = slideL, BuiltOpen = false, Sound = "drawer", Label = "Drawer", Reach = 6 }, q.Position, parts)
			nOpen += 1
		end
	end
	return string.format("owner edits: %d builder parts out, %d of his back, %d openables", removed, #made, nOpen)
end

-- things made after the owner's furniture: the upside-down bike and the bathroom's sliding door (post-grow coordinates)
local function extras(ins: Instance): string
	parent = ins
	-- the bicycle (pink, as in the clip): upside down on its saddle and grips under the window by the door, front wheel
	-- towards the door (owner's mark-up)
	bicycle(35.6, 26.45, true)
	-- the bathroom's sliding door (owner: "the bathroom door is supposed to be a sliding door") on the dining side of its
	-- wall, under a top track; it slides along the wall
	local wx0 = tx(38.0) -- the wall's dining-side face
	local z0, z1 = tz(8.0), tz(11.0)
	box("SlideTrack", wx0 - 0.26, FY + 7.25, z0 - 4.3, wx0, FY + 7.37, z1 + 0.15, C.galv, Mat.Metal, true)
	openable("BathDoor", { Kind = "drawer", SlideL = Vector3.new(0, 0, -(z1 - z0)), BuiltOpen = false, Sound = "slider", Label = "Bathroom", Reach = 8 }, wx0 - 0.2, FY + 3.5, z1, function()
		box("BathSlider", wx0 - 0.2, FY + 0.05, z0 - 0.1, wx0 - 0.04, FY + 7.2, z1 + 0.1, Color3.fromRGB(170, 175, 170), Mat.Wood)
		box("BathSliderPanel", wx0 - 0.26, FY + 0.8, z0 + 0.3, wx0 - 0.2, FY + 6.4, z1 - 0.3, Color3.fromRGB(155, 160, 155), Mat.Wood, true)
		box("BathSliderPull", wx0 - 0.32, FY + 2.9, z1 - 0.45, wx0 - 0.26, FY + 4.1, z1 - 0.35, C.galv, Mat.Metal, true)
		for _, zz in { z0 + 0.4, z1 - 0.4 } do
			P("SlideRoller", Vector3.new(0.08, 0.18, 0.18), CFrame.new(wx0 - 0.12, FY + 7.29, zz), C.galv, Mat.Metal, true, Enum.PartType.Cylinder)
		end
	end)
	return "extras: bike + bath slider"
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
	local g = if M.GROW ~= 1 then M.grow() else ""
	g ..= " | " .. ownerEdits(ins) .. " | " .. extras(ins)
	return string.format("built %d parts (exterior %d, inside %d); %s", count, #ext:GetDescendants(), #ins:GetDescendants(), g)
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
