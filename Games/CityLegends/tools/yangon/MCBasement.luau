--[[
	MCBasement (2026-11-17, owner: "these are underground parking in real life")
	Myanmar Centre's basement car park at 1:1 (Workspace.Yangon1to1.Landmarks.MyanmarCentre.Basement).
	No public photos or plans of Myanmar Plaza's basement were found, so it is a plain standard car park:
	one level 3.5 m under the site (the ramps' depth), 2.5 x 5 m bays (7.5 x 15 studs) in back-to-back
	rows, 6 m aisles, columns every 3 bays, strip lights over the aisles, EXIT signs, a lift / stair core.
	Fed by the three ramps of mc3d.py (ramp_in, ramp_out under the podium's west edge, the Melia ramp);
	mc3d.py at 1:1 no longer builds their dark end walls; the placed meshes lost them through
	city/mc_portal_strip.py (Model 89861432633803: the west DRK and the ramps' RED mesh, swapped in with
	MeshPart:ApplyMesh, old ids in attribute OldMeshId) and M.dropPortals() for their collision.
	Everything is laid in the pavement plane's frame (onetoone.plane_y with mc1_meta.json's plane), so the
	floor meets each ramp's flat end (plane - 10.5) everywhere; the floor top sits 0.1 under it (no flicker).
	Run in Studio Edit: paste this file into execute_luau and call M.build() (about 1 s), M.undo() removes it.
	Parking (server) puts parked cars on the "ParkBay" markers (Config.Parking.ParkedPerGarage).
]]

local M = {}

local A, B, C0 = 0.010750665929110522, 0.010526870203554915, 40.40851827031085
local function py(X: number, Z: number): number
	return C0 - A * (X - 34875) - B * (Z - 27468.75)
end
local U0, W0 = 34671, 27448 -- local u = world X - U0, w ~ world Z - W0
local n = Vector3.new(A, 1, B).Unit
local xa = (Vector3.xAxis - n * n.X).Unit
local F = CFrame.fromMatrix(Vector3.new(U0, py(U0, W0) - 10.5, W0), xa, n) -- local y 0 = plane - 10.5

local FLOOR, CEIL, ROOF = -0.1, 8.2, 9.4 -- floor top, ceiling underside, ceiling top (plane - 1.1)
local OPEN_TOP = 6.8 -- ramp openings (the ramp roof slab's underside is at 7.0)
local BAY, DEPTH = 7.5, 15

local GREY = Color3.fromRGB(206, 204, 198)
local FLOORC = Color3.fromRGB(150, 150, 148) -- Concrete renders far darker than its colour
local LINE = Color3.fromRGB(236, 236, 230)
local YELLOW = Color3.fromRGB(226, 184, 36)

local root: Model

local function box(name, u0, u1, h0, h1, w0, w1, color, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(u1 - u0, h1 - h0, w1 - w0)
	p.CFrame = F * CFrame.new((u0 + u1) / 2, (h0 + h1) / 2, (w0 + w1) / 2)
	p.Color = color
	p.Material = opts.mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.deco then
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
	end
	p.Parent = opts.parent or root
	return p
end

local function label(p: BasePart, face, text, bg, fg)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = bg
	t.TextColor3 = fg
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Text = text
	t.Parent = g
	g.Parent = p
end

-- an EXIT sign on a wall face: at local u (facing +u or -u) or w (facing +w)
local function exitSign(u0, u1, w0, w1, face)
	local s = box("ExitSign", u0, u1, 7.0, 7.9, w0, w1, Color3.fromRGB(30, 150, 70), { deco = true })
	label(s, face, "EXIT", Color3.fromRGB(30, 150, 70), Color3.new(1, 1, 1))
end

-- a wall along w at u0..u1 from w0 to w1, with openings { {a, b} } (ramp mouths) up to OPEN_TOP
local function wallW(name, u0, u1, w0, w1, openings)
	local cuts = {}
	for _, o in openings do
		table.insert(cuts, o)
	end
	table.sort(cuts, function(x, y)
		return x[1] < y[1]
	end)
	local w = w0
	for _, o in cuts do
		box(name, u0, u1, FLOOR, CEIL, w, o[1], GREY)
		box(name .. "Lintel", u0, u1, OPEN_TOP, CEIL, o[1], o[2], GREY)
		w = o[2]
	end
	box(name, u0, u1, FLOOR, CEIL, w, w1, GREY)
end

local function bayRow(w0, w1, ua, ub, cols)
	-- lines across the row every bay, a marker per bay facing the aisle side (w0 side if cols at w1)
	local nb = math.floor((ub - ua) / BAY + 0.5)
	for k = 0, nb do
		local u = ua + k * BAY
		box("BayLine", u - 0.125, u + 0.125, FLOOR, FLOOR + 0.05, w0, w1, LINE, { deco = true })
	end
	return nb
end

local function markers(folder, w0, w1, ua, nb, outSign)
	for k = 0, nb - 1 do
		local u = ua + (k + 0.5) * BAY
		local c = F * Vector3.new(u, FLOOR, (w0 + w1) / 2)
		local out = F:VectorToWorldSpace(Vector3.new(0, 0, outSign))
		local p = Instance.new("Part")
		p.Name = "ParkBay"
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(BAY - 1, 1, DEPTH - 1)
		p.CFrame = CFrame.lookAt(c, c + out)
		p.Parent = folder
	end
end

local function column(u, w)
	box("Column", u - 1.2, u + 1.2, FLOOR, 2.9, w - 1.2, w + 1.2, YELLOW)
	box("Column", u - 1.2, u + 1.2, 2.9, CEIL, w - 1.2, w + 1.2, GREY)
end

local lights = 0
local function fixture(u, w, alongU)
	local du, dw = 2.4, 0.4
	if not alongU then
		du, dw = 0.4, 2.4
	end
	local p = box("StripLight", u - du, u + du, CEIL - 0.3, CEIL, w - dw, w + dw, Color3.fromRGB(236, 242, 250),
		{ deco = true, mat = Enum.Material.Neon })
	lights += 1
	if lights % 2 == 1 then
		local l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Bottom
		l.Range = 22
		l.Brightness = 1.4
		l.Angle = 120
		l.Color = Color3.fromRGB(240, 246, 255)
		l.Shadows = false
		l.Parent = p
	end
end

-- the ramp mouths (world centre where each ramp meets the wall, inner width / cos(angle))
-- (the south edge sits on the ramp's south inner wall face at the wall's inner face, or terrain shows past it)
local MOUTH_A = { 153.6, 174.2 } -- ramp_in, z 27611.6
local MOUTH_B = { 114.2, 134.8 } -- ramp_out, z 27572.2
local MOUTH_M = { 229.1, 248.3 } -- the Melia ramp, z 27686.1

-- terrain out of the basement and the three ramp trenches (the site's ground sits at plane - 4)
function M.terrain()
	local T = workspace.Terrain
	-- 6 studs past every wall (smooth terrain bulges ~2 studs through a wall it touches)
	T:FillBlock(F * CFrame.new(119.5, 2.7, 89), Vector3.new(257, 13.4, 194), Enum.Material.Air)
	T:FillBlock(F * CFrame.new(154.5, 2.7, 220), Vector3.new(187, 13.4, 80), Enum.Material.Air)
	-- trenches: between each ramp's two side-wall collision boxes (10.97 tall, 1.5 thick)
	local col = workspace.Yangon1to1.Landmarks.MyanmarCentre.Collide
	local walls = {}
	for _, p in col:GetChildren() do
		if p:IsA("BasePart") and math.abs(p.Size.Y - 10.97) < 0.05 and math.abs(p.Size.Z - 1.5) < 0.05 and p.Size.X > 30 then
			table.insert(walls, p)
		end
	end
	local done = 0
	for i, a in walls do
		for j = i + 1, #walls do
			local b = walls[j]
			local d = (a.Position - b.Position) * Vector3.new(1, 0, 1)
			if d.Magnitude < 30 and math.abs(a.Size.X - b.Size.X) < 0.5 then
				local mid = (a.Position + b.Position) / 2
				local bot = math.min(a.Position.Y, b.Position.Y) - 10.97 / 2
				local rot = a.CFrame - a.Position
				local sep = math.abs(a.CFrame:PointToObjectSpace(b.Position).Z)
				local h0, h1 = bot - 4, bot + 10.97 - 3.6 -- up to the site's ground (plane - 4), 4 past each wall
				T:FillBlock(CFrame.new(mid.X, (h0 + h1) / 2, mid.Z) * rot, Vector3.new(a.Size.X, h1 - h0, sep + 9.5),
					Enum.Material.Air)
				done += 1
			end
		end
	end
	return done
end

-- the dark end walls' collision boxes (mc3d.py no longer makes them at 1:1)
function M.dropPortals()
	local col = workspace.Yangon1to1.Landmarks.MyanmarCentre.Collide
	local gone = 0
	for _, at in { Vector3.new(34669.5, 0, 27611.3), Vector3.new(34669.5, 0, 27572.0), Vector3.new(34740.7, 0, 27686.5) } do
		for _, p in col:GetChildren() do
			if p:IsA("BasePart") and math.abs(p.Size.X - 1.5) < 0.05 and math.abs(p.Size.Y - 10.97) < 0.05
				and ((p.Position - at) * Vector3.new(1, 0, 1)).Magnitude < 1 then
				p:Destroy()
				gone += 1
			end
		end
	end
	return gone
end

function M.build()
	local mc = workspace.Yangon1to1.Landmarks.MyanmarCentre
	local old = mc:FindFirstChild("Basement")
	if old then
		old:Destroy()
	end
	root = Instance.new("Model")
	root.Name = "Basement"
	lights = 0

	-- slabs: R1 under the podium's west half, R2 under the Melia's west half
	box("Floor", -3, 242, -3.1, FLOOR, -2, 180, FLOORC, { mat = Enum.Material.Concrete })
	box("Floor", 67, 242, -3.1, FLOOR, 180, 254, FLOORC, { mat = Enum.Material.Concrete })
	box("Ceiling", -3, 242, CEIL, ROOF, -2, 180, GREY)
	box("Ceiling", 67, 242, CEIL, ROOF, 180, 254, GREY)
	-- walls
	box("Wall", -3, 242, FLOOR, CEIL, -2, 0, GREY) -- south
	box("Wall", 240, 242, FLOOR, CEIL, 0, 252, GREY) -- east
	box("Wall", -3, 67, FLOOR, CEIL, 177, 180, GREY) -- north of R1 (west part)
	box("Wall", 67, 242, FLOOR, CEIL, 252, 254, GREY) -- north of R2
	wallW("Wall", -3, 0, 0, 177, { MOUTH_B, MOUTH_A }) -- west, the two podium ramps
	wallW("Wall", 67, 70, 177, 252, { MOUTH_M }) -- R2's west, the Melia ramp
	exitSign(0, 0.3, MOUTH_B[1] + 7, MOUTH_B[2] - 7, Enum.NormalId.Right)
	exitSign(70, 70.3, MOUTH_M[1] + 7, MOUTH_M[2] - 7, Enum.NormalId.Right)

	-- bays (back-to-back pairs with columns on their middle line), parking markers
	local bays = Instance.new("Folder")
	bays.Name = "Bays"
	bays.Parent = root
	local R1a, R1b, R2a = 24, 211.5, 91.5
	local total = 0
	for _, pair in { 18, 66, 114 } do
		local nb = bayRow(pair, pair + 30, R1a, R1b)
		markers(bays, pair, pair + 15, R1a, nb, -1)
		markers(bays, pair + 15, pair + 30, R1a, nb, 1)
		total += 2 * nb
		for u = R1a, R1b - 1, 22.5 do
			column(u, pair + 15)
		end
	end
	local nb = bayRow(162, 177, R1a, R1b)
	markers(bays, 162, 177, R1a, nb, -1)
	total += nb
	nb = bayRow(177, 192, R2a, R1b)
	markers(bays, 177, 192, R2a, nb, 1)
	total += nb
	nb = bayRow(210, 225, R2a, R1b)
	markers(bays, 210, 225, R2a, nb, 1)
	total += nb
	for u = R2a, R1b - 1, 22.5 do
		column(u, 177)
		column(u, 210)
	end

	-- strip lights over the aisles (every 24 studs), the cross aisles
	for _, w in { 9, 57, 105, 153 } do
		for u = 12, 228, 24 do
			fixture(u, w, true)
		end
	end
	for _, w in { 201, 238.5 } do
		for u = 82, 228, 24 do
			fixture(u, w, true)
		end
	end
	for _, w in { 33, 81, 129 } do
		fixture(12, w, false)
		fixture(226, w, false)
	end
	fixture(226, 177, false)
	fixture(226, 220, false)

	-- the lift / stair core in the south-east corner (under tower A): lift doors, stair door, EXIT
	box("Core", 222, 240, FLOOR, CEIL, 0, 14, Color3.fromRGB(222, 220, 214))
	box("LiftDoor", 225, 231, FLOOR, 6.6, 14, 14.15, Color3.fromRGB(150, 154, 160), { deco = true })
	label(box("LiftSign", 225.5, 230.5, 6.9, 7.7, 14, 14.12, GREY, { deco = true }), Enum.NormalId.Back, "LIFT  MALL",
		Color3.fromRGB(60, 62, 66), Color3.new(1, 1, 1))
	box("StairDoor", 233.5, 237.5, FLOOR, 6.6, 14, 14.15, Color3.fromRGB(96, 104, 112), { deco = true })
	exitSign(233.5, 237.5, 14, 14.3, Enum.NormalId.Back)
	box("LiftButton", 231.6, 232.2, 3.4, 4.4, 14, 14.12, Color3.fromRGB(40, 40, 44), { deco = true })
	root:SetAttribute("Bays", total)
	root:SetAttribute("Source", "tools/yangon/MCBasement.luau")
	root.Parent = mc
	return total, lights, #root:GetDescendants()
end

function M.undo()
	local b = workspace.Yangon1to1.Landmarks.MyanmarCentre:FindFirstChild("Basement")
	if b then
		b:Destroy()
	end
end

return M
