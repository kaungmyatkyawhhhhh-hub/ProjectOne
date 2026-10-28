-- SPEED ARC: builds the Hub (Hometown Track) in Studio. Run in edit mode as loadstring(this)(builder_lib)
-- (the wall course comes from the shared builder library).
-- v3 (28 Oct): "+1 SPEED every step" + the bright candy look: an open spawn plaza, the wall course,
-- kiosks, a row of portals, AFK treadmills. Smooth parts + CSG for the curved track; Blender meshes
-- (ServerStorage.Meshes) for trees, treadmills, bleachers and the crowd when they're imported.
-- Re-running replaces workspace.Hub (the old one is moved to ServerStorage as a dated backup).
local L = assert(..., "run as loadstring(build_hub)(builder_lib)")
local GeometryService = game:GetService("GeometryService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette:Clone())
local Race = require(ReplicatedStorage.Shared.Config.Race:Clone())
local Stations = require(ReplicatedStorage.Shared.Config.Stations:Clone())
local W = Palette.World
local T = Race.Track
local rng = Random.new(28)

local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local BODY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

----------------------------------------------------------------------------
-- helpers
----------------------------------------------------------------------------
local function part(props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = props.CastShadow or false
	p.CanCollide = props.CanCollide ~= false
	p.CanQuery = props.CanQuery ~= false
	p.CanTouch = false
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Size = props.Size
	p.CFrame = props.CFrame or CFrame.new(props.Pos or Vector3.zero)
	p.Color = props.Color or Palette.White
	p.Transparency = props.Transparency or 0
	p.Name = props.Name or "Part"
	p.Parent = props.Parent
	return p
end

local function block(parent, name, size, pos, color, extra)
	extra = extra or {}
	extra.Parent = parent
	extra.Name = name
	extra.Size = size
	extra.Pos = pos
	extra.Color = color
	return part(extra)
end

-- vertical cylinder (axis = Y)
local function cyl(parent, name, radius, height, pos, color, extra)
	extra = extra or {}
	extra.Parent = parent
	extra.Name = name
	extra.Shape = Enum.PartType.Cylinder
	extra.Size = Vector3.new(height, radius * 2, radius * 2)
	extra.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	extra.Color = color
	return part(extra)
end

local function ball(parent, name, d, pos, color, extra)
	extra = extra or {}
	extra.Parent = parent
	extra.Name = name
	extra.Shape = Enum.PartType.Ball
	extra.Size = Vector3.new(d, d, d)
	extra.Pos = pos
	extra.Color = color
	return part(extra)
end

local function union(list, name, parent, color)
	local main = list[1]
	local others = table.move(list, 2, #list, 1, {})
	local ok, res = pcall(function()
		return GeometryService:UnionAsync(main, others, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false })
	end)
	if not ok then
		warn("union failed", name, res)
		return nil
	end
	for _, p in list do
		p:Destroy()
	end
	local u = res[1]
	u.Name = name
	u.Anchored = true
	u.UsePartColor = true
	u.Color = color or main.Color
	u.CastShadow = false
	u.Parent = parent
	return u
end

local function subtract(main, cutters, name, parent, color)
	local ok, res = pcall(function()
		return GeometryService:SubtractAsync(main, cutters, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false })
	end)
	if not ok then
		warn("subtract failed", name, res)
		return nil
	end
	main:Destroy()
	for _, c in cutters do
		c:Destroy()
	end
	local u = res[1]
	u.Name = name
	u.Anchored = true
	u.UsePartColor = true
	u.Color = color or Palette.White
	u.CastShadow = false
	u.Parent = parent
	return u
end

-- Blender props imported by the owner live in ServerStorage.Meshes.<Name> (one MeshPart each).
-- Blender X = Roblox X, Blender Y = Roblox Z, up = Y; each mesh's bottom sits on y = 0 of its CFrame.
local MeshLib = ServerStorage:FindFirstChild("Meshes")
local function meshTemplate(name)
	local m = MeshLib and MeshLib:FindFirstChild(name)
	return m and (if m:IsA("MeshPart") then m else m:FindFirstChildWhichIsA("MeshPart"))
end
-- place a mesh with its bottom-centre at cf (offset = bounding-box centre relative to the Blender origin)
local function mesh(name, parent, cf, opts)
	local t = meshTemplate(name)
	if not t then
		return nil
	end
	opts = opts or {}
	local m = t:Clone()
	local scale = opts.Scale or 1
	m.Size = t.Size * scale
	local off = (opts.Offset or Vector3.zero) * scale
	m.CFrame = cf * CFrame.new(off.X, m.Size.Y / 2 + off.Y, off.Z)
	m.Anchored = true
	m.CanTouch = false
	m.CastShadow = opts.CastShadow or false
	m.CanCollide = opts.CanCollide ~= false
	m.CanQuery = opts.CanCollide ~= false
	m.Name = opts.Name or name
	m.Parent = parent
	return m
end

-- solid oval ("stadium") of the track's shape, radius r, from y0 to y0 + h
local function stadium(r, h, y0, color, tmp)
	local c = T.Center
	local y = y0 + h / 2
	local rect = block(tmp, "R", Vector3.new(T.Straight, h, r * 2), c + Vector3.new(0, y, 0), color)
	local a = cyl(tmp, "A", r, h, c + Vector3.new(T.Straight / 2, y, 0), color)
	local b = cyl(tmp, "B", r, h, c + Vector3.new(-T.Straight / 2, y, 0), color)
	return union({ rect, a, b }, "Stadium", tmp, color)
end

-- flat oval ring between radius r1 and r2
local function ring(name, parent, r1, r2, h, y0, color, tmp)
	local outer = stadium(r2, h, y0, color, tmp)
	local inner = stadium(r1, h + 1, y0 - 0.5, color, tmp)
	return subtract(outer, { inner }, name, parent, color)
end

local function surfaceText(parent, face, lines, opts)
	opts = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.PPS or 30
	gui.LightInfluence = opts.LightInfluence or 0.2
	gui.Brightness = opts.Brightness or 1.2
	gui.MaxDistance = opts.MaxDistance or 160
	gui.ZOffset = 0.1
	gui.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, opts.Padding or 4)
	layout.Parent = gui
	for i, l in lines do
		local t = Instance.new("TextLabel")
		t.Name = l.Name or ("Line" .. i)
		t.LayoutOrder = i
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -20, l.Height or 0.3, 0)
		t.Text = l.Text
		t.TextScaled = true
		t.FontFace = l.Font or MONTSERRAT
		t.TextColor3 = l.Color or Palette.White
		t.Parent = gui
		if l.Stroke then
			local s = Instance.new("UIStroke")
			s.Color = l.Stroke
			s.Thickness = l.StrokeThickness or 3
			s.Parent = t
		end
	end
	return gui
end

----------------------------------------------------------------------------
-- setup
----------------------------------------------------------------------------
local stamp = os.date("!%Y%m%d_%H%M")
local today = os.date("!%Y%m%d")
local old = workspace:FindFirstChild("Hub")
if old then
	if old:GetAttribute("BuildDay") == today then
		old:Destroy() -- a rebuild from the same day's builder run: nothing hand-made to keep
	else
		old.Name = "HubBackup_" .. stamp
		old.Parent = ServerStorage
	end
end
for _, name in { "Baseplate", "SpawnLocation" } do
	local o = workspace:FindFirstChild(name)
	if o then
		o.Name = name .. "Backup_" .. stamp
		o.Parent = ServerStorage
	end
end

local hub = Instance.new("Model")
hub.Name = "Hub"
hub:SetAttribute("BuildDay", today)
local tmp = Instance.new("Folder")
tmp.Name = "_tmp"
tmp.Parent = workspace

local function folder(name, parent)
	local f = Instance.new(if parent == hub then "Model" else "Folder")
	f.Name = name
	f.Parent = parent or hub
	return f
end

local ground = folder("Ground")
local track = folder("Track")
local training = folder("Training")
local stands = folder("Stands")
local school = folder("School")
local props = folder("Props")
local life = folder("Life")
local flagsF = folder("Flags", life)
local crowdF = folder("Crowd", life)

----------------------------------------------------------------------------
-- layout v3 (28 Oct, "+1 SPEED every step" + candy look): a big open spawn plaza, everything spaced
-- far apart with a giant floating name. You spawn facing south down the WALL COURSE. Behind you
-- (north) the race track, to the right (west) SHOPS, to the left (east) PORTALS, either side of the
-- course start the AFK TREADMILLS and the LEADERBOARDS. No small clutter.
----------------------------------------------------------------------------
local Course = require(ReplicatedStorage.Shared.Config.Course)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Format = require(ReplicatedStorage.Shared.Util.Format)
local PLAZA = Vector3.new(0, 0, 140)
local PLAZA_R = 36
local C = Course.Areas.Hub
local WALLS = #Course.WallShares
local COURSE_END = C.Start.Z + WALLS * Course.StageLength

local function modelIn(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- a giant floating name (BillboardGui sized in studs, so it reads like a sign in the world)
local function floatLabel(parent, pos, text, sub, color, w, h)
	local anchor = part({ Parent = parent, Name = "LabelAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Name = "FloatLabel"
	bb.Size = UDim2.fromScale(w, h)
	bb.LightInfluence = 0
	bb.MaxDistance = 700
	bb.Parent = anchor
	local function line(t, y, hgt, col, stroke)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, hgt)
		l.Text = t
		l.TextScaled = true
		l.FontFace = MONTSERRAT
		l.TextColor3 = col
		l.Parent = bb
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 3
		s.Parent = l
	end
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.45)
	line(text, 0, if sub then 0.68 else 1, Palette.White, dark)
	if sub then
		line(sub, 0.7, 0.3, color, Palette.White)
	end
	return anchor
end

----------------------------------------------------------------------------
-- ground: bright grass with mowing stripes, the long strip under the course, hills
----------------------------------------------------------------------------
block(ground, "Grass", Vector3.new(400, 4, 410), Vector3.new(0, -2, 90), W.Grass)
block(ground, "CourseGrass", Vector3.new(180, 4, COURSE_END - 280 + 80), Vector3.new(0, -2, (290 + COURSE_END + 80) / 2), W.Grass)
block(ground, "Outskirts", Vector3.new(2600, 4, 2600), Vector3.new(0, -2.25, 400), Color3.fromHex("#6CC94A"))
local hillCols = { Color3.fromHex("#8BE06A"), Color3.fromHex("#6CC94A"), Color3.fromHex("#A2E87F") }
for i = 0, 17 do
	local side = if i % 2 == 0 then -1 else 1
	local size = rng:NextNumber(160, 260)
	ball(ground, "Hill", size, Vector3.new(side * rng:NextNumber(330, 430), -size * 0.32, -320 + i * 95), hillCols[i % 3 + 1], { CanCollide = false, CanQuery = false })
end
for _, x in { -260, 0, 260 } do
	local size = rng:NextNumber(220, 300)
	ball(ground, "Hill", size, Vector3.new(x, -size * 0.32, -420), hillCols[1], { CanCollide = false, CanQuery = false })
	ball(ground, "Hill", size, Vector3.new(x, -size * 0.32, COURSE_END + 300), hillCols[2], { CanCollide = false, CanQuery = false })
end
for i = 0, 19 do
	if i % 2 == 0 then
		block(ground, "Stripe", Vector3.new(10, 0.06, 404), Vector3.new(-200 + i * 20 + 5, 0.03, 90), W.GrassDark, { CanCollide = false })
	end
end
-- infield (lighter, with its own stripes)
local infield = stadium(T.InnerRadius - 0.3, 0.12, 0, W.Infield, tmp)
infield.Name = "Infield"
infield.Parent = ground
for i = 0, 9 do
	if i % 2 == 0 then
		block(ground, "InfieldStripe", Vector3.new(10, 0.04, (T.InnerRadius - 0.5) * 2), Vector3.new(-50 + i * 10 + 5, 0.14, 0), W.TreeLeafLight, { CanCollide = false })
	end
end

-- a cream path from a to b with low kerbs in its zone's colour
local function path(name, a, b, width, color)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	part({ Parent = ground, Name = name, Size = Vector3.new(width, 0.3, len), CFrame = cf * CFrame.new(0, 0.15, 0), Color = Color3.fromHex("#F3DFB8") })
	for side = -1, 1, 2 do
		part({ Parent = ground, Name = "Kerb", Size = Vector3.new(1.2, 0.5, len), CFrame = cf * CFrame.new(side * (width / 2 + 0.6), 0.25, 0), Color = color })
	end
end
path("TrackPath", PLAZA - Vector3.new(0, 0, PLAZA_R - 2), Vector3.new(0, 0, 57.8), 30, Palette.Sky)
path("ShopPath", PLAZA - Vector3.new(PLAZA_R - 2, 0, 0), Vector3.new(-86, 0, PLAZA.Z), 26, Palette.Orange)
path("PortalPath", PLAZA + Vector3.new(PLAZA_R - 2, 0, 0), Vector3.new(86, 0, PLAZA.Z), 26, Palette.Purple)
path("CoursePath", PLAZA + Vector3.new(0, 0, PLAZA_R - 2), C.Start + Vector3.new(0, 0, 1), 30, Palette.Pink)

-- the spawn plaza: big, round and empty, a sky-blue band and the SPEED ARC emblem
cyl(ground, "PlazaEdge", PLAZA_R + 1.2, 0.5, PLAZA + Vector3.new(0, 0.25, 0), Palette.Sky)
cyl(ground, "Plaza", PLAZA_R, 0.56, PLAZA + Vector3.new(0, 0.28, 0), Color3.fromHex("#E4EAF6"))
cyl(ground, "PlazaBand", 26, 0.57, PLAZA + Vector3.new(0, 0.285, 0), Palette.Sky)
cyl(ground, "PlazaInner", 24.5, 0.58, PLAZA + Vector3.new(0, 0.29, 0), Color3.fromHex("#E4EAF6"))
cyl(ground, "EmblemGold", 12, 0.6, PLAZA + Vector3.new(0, 0.3, 0), Palette.Gold, { CanCollide = false })
cyl(ground, "Emblem", 11, 0.62, PLAZA + Vector3.new(0, 0.31, 0), Palette.Carbon, { CanCollide = false })
local emblemTop = block(ground, "EmblemText", Vector3.new(20, 0.05, 20), PLAZA + Vector3.new(0, 0.64, 0), Palette.Carbon, { Transparency = 1, CanCollide = false })
local eg = Instance.new("SurfaceGui")
eg.Face = Enum.NormalId.Top
eg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
eg.PixelsPerStud = 14
eg.MaxDistance = 200
eg.LightInfluence = 1
eg.Parent = emblemTop
for _, l in { { "SPEED", Palette.White, 0.36 }, { "ARC", Palette.Gold, 0.64 } } do
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(l[3], 0.5)
	t.Size = UDim2.fromScale(0.8, 0.28)
	t.Rotation = -90 -- reads for you standing at the spawn, looking south
	t.Text = l[1]
	t.TextScaled = true
	t.FontFace = MONTSERRAT
	t.TextColor3 = l[2]
	t.Parent = eg
end

----------------------------------------------------------------------------
-- track: blue oval, white lane lines, curbs, gold start/finish, lane numbers
----------------------------------------------------------------------------
local outerR = T.InnerRadius + T.LaneWidth * T.Lanes
ring("Surface", track, T.InnerRadius, outerR, T.SurfaceY, 0, W.TrackBlue, tmp)
ring("Apron", track, outerR, outerR + 3, T.SurfaceY - 0.08, 0, W.TrackBlueDark, tmp)
for i = 0, T.Lanes do
	local r = T.InnerRadius + i * T.LaneWidth
	if i > 0 and i < T.Lanes then
		ring("Line" .. i, track, r - 0.15, r + 0.15, T.SurfaceY + 0.03, 0, W.LaneWhite, tmp)
	end
	task.wait()
end
ring("InnerCurb", track, T.InnerRadius - 0.7, T.InnerRadius, T.SurfaceY + 0.35, 0, W.Aluminium, tmp)
ring("OuterCurb", track, outerR + 3, outerR + 3.6, T.SurfaceY + 0.3, 0, W.LaneWhite, tmp)

local lineZ = T.InnerRadius + T.LaneWidth * T.Lanes / 2
block(track, "StartFinish", Vector3.new(1.2, T.SurfaceY + 0.06, T.LaneWidth * T.Lanes), Vector3.new(T.StartX, (T.SurfaceY + 0.06) / 2, lineZ), Palette.Gold)
block(track, "StartGlow", Vector3.new(0.3, T.SurfaceY + 0.08, T.LaneWidth * T.Lanes), Vector3.new(T.StartX - 0.8, (T.SurfaceY + 0.08) / 2, lineZ), Palette.Gold, { Material = Enum.Material.Neon })
-- lane numbers painted behind the line
local nums = block(track, "LaneNumbers", Vector3.new(6, 0.05, T.LaneWidth * T.Lanes), Vector3.new(T.StartX - 5, T.SurfaceY + 0.03, lineZ), W.TrackBlue, { Transparency = 1, CanCollide = false })
local ng = Instance.new("SurfaceGui")
ng.Face = Enum.NormalId.Top
ng.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
ng.PixelsPerStud = 20
ng.MaxDistance = 140
ng.LightInfluence = 1
ng.Parent = nums
for lane = 1, T.Lanes do
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Top face: X across the part's X, Y along its Z
	t.Position = UDim2.fromScale(0.5, (lane - 0.5) / T.Lanes)
	t.Size = UDim2.fromScale(1, 1 / T.Lanes * 0.85)
	t.Rotation = 90
	t.Text = tostring(lane)
	t.TextScaled = true
	t.FontFace = MONTSERRAT
	t.TextColor3 = W.LaneWhite
	t.Parent = ng
end

-- join ring by the start (gold, shows during the JOIN window)
local ringPos = Vector3.new(T.StartX - 14, 0.35, outerR + 12)
local jrOuter = cyl(tmp, "JO", 6, 0.3, ringPos, Palette.Gold)
local jrInner = cyl(tmp, "JI", 5.2, 1, ringPos, Palette.Gold)
local jr = subtract(jrOuter, { jrInner }, "JoinRing", track, Palette.Gold)
if jr then
	jr.Material = Enum.Material.Neon
	jr.CanCollide = false
	jr.Transparency = 1
end

----------------------------------------------------------------------------
-- start/finish arch with the LED screen (black steel, gold top beam)
----------------------------------------------------------------------------
local arch = folder("Arch", track)
local z1, z2 = T.InnerRadius - 3, outerR + 3
local span = z2 - z1 + 2.4
-- the Blender arch spans its X axis: turn it to span the lanes (world Z)
local archMesh = nil -- candy look (28 Oct): the part arch (the imported arch mesh is dark steel)
local function tower(z)
	if not archMesh then
		block(arch, "Leg", Vector3.new(2.4, 18, 2.4), Vector3.new(T.StartX, 9, z), Palette.White)
		block(arch, "Foot", Vector3.new(4, 1, 4), Vector3.new(T.StartX, 0.5, z), Palette.Sky)
	end
	-- glowing bands stay as Neon parts (just outside the mesh's blue bands)
	block(arch, "LegTrim", Vector3.new(2.7, 0.5, 2.7), Vector3.new(T.StartX, 6, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
	block(arch, "LegTrim", Vector3.new(2.7, 0.5, 2.7), Vector3.new(T.StartX, 12, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
end
tower(z1)
tower(z2)
if not archMesh then
	block(arch, "Beam", Vector3.new(3, 4, span), Vector3.new(T.StartX, 19.5, (z1 + z2) / 2), Palette.Sky)
	block(arch, "BeamGold", Vector3.new(3.2, 1, span + 0.2), Vector3.new(T.StartX, 21.7, (z1 + z2) / 2), Palette.Gold)
end
block(arch, "BeamGlow", Vector3.new(3.25, 0.35, span + 0.25), Vector3.new(T.StartX, 17.6, (z1 + z2) / 2), Palette.BrightBlue, { Material = Enum.Material.Neon })
for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
	local screen = block(arch, "Screen", Vector3.new(0.2, 3.2, span - 6), Vector3.new(T.StartX + (if face == Enum.NormalId.Left then -1.6 else 1.6), 19.5, (z1 + z2) / 2), Palette.SpeedBlack)
	surfaceText(screen, if face == Enum.NormalId.Left then Enum.NormalId.Left else Enum.NormalId.Right, {
		{ Text = "SPEED ARC", Height = 0.45, Color = Palette.Gold },
		{ Name = "RaceTimerText", Text = "NEXT RACE 3:00", Height = 0.45, Color = Palette.White },
	}, { PPS = 24, Brightness = 2, MaxDistance = 220, Padding = 0 })
end

----------------------------------------------------------------------------
-- flags (segment chains that wave on the client)
----------------------------------------------------------------------------
local function flag(base, color, accent, poleH, parent)
	local m = Instance.new("Model")
	m.Name = "Flag"
	m.Parent = parent or flagsF
	poleH = poleH or 6
	cyl(m, "Pole", 0.2, poleH, base + Vector3.new(0, poleH / 2, 0), W.Aluminium)
	ball(m, "Tip", 0.6, base + Vector3.new(0, poleH + 0.2, 0), Palette.Gold)
	local hingePos = base + Vector3.new(0, poleH - 1.4, 0)
	local hinge = block(m, "Hinge", Vector3.new(0.2, 0.2, 0.2), hingePos, color, { Transparency = 1, CanCollide = false, CanQuery = false })
	local n, segW, h = 5, 0.8, 2.4
	for i = 1, n do
		local c = if i % 2 == 0 then color else color:Lerp(accent, 0.12)
		local s = block(m, "Seg", Vector3.new(segW + 0.04, h, 0.08), hingePos + Vector3.new(segW * (i - 0.5), 0, 0), c, { CanCollide = false, CanQuery = false })
		s:SetAttribute("Seg", i)
		if i == n then
			s.Color = accent
		end
	end
	return m
end
flag(Vector3.new(T.StartX, 22.2, z1), Palette.ElectricBlue, Palette.Gold, 5)
flag(Vector3.new(T.StartX, 22.2, z2), Palette.Gold, Palette.ElectricBlue, 5)

----------------------------------------------------------------------------
-- bleachers along the back straight with the crowd and the big screen
----------------------------------------------------------------------------
local sz0 = -(outerR + 6) -- front of the stands
local rows = 6
local bleacherMesh = meshTemplate("Bleacher_Section")
local standLen = if bleacherMesh then 100 else 110
for k = 1, rows do
	local h = 1 + 1.3 * k
	local z = sz0 - 1.5 - 3 * (k - 1)
	if not bleacherMesh then
		block(stands, "Step" .. k, Vector3.new(standLen, h, 3), Vector3.new(0, h / 2, z), if k % 2 == 0 then Palette.Graphite else Color3.fromHex("#323846"))
		block(stands, "Seat" .. k, Vector3.new(standLen - 2, 0.5, 1.3), Vector3.new(0, h + 0.25, z + 0.6), W.Aluminium)
	end
	-- the blue seat edges glow (Neon), just in front of the mesh's painted edge
	block(stands, "SeatEdge" .. k, Vector3.new(standLen - 2, 0.15, 0.2), Vector3.new(0, h + 0.42, z + 1.3), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
end
if bleacherMesh then
	-- 5 sections of 20; the section's front rail is at Blender y = +0.75, its back at -18
	local sections = standLen / 20
	for i = 1, sections do
		local x = -standLen / 2 + 10 + (i - 1) * 20
		mesh("Bleacher_Section", stands, CFrame.new(x, 0, sz0), { Offset = Vector3.new(0, 0, 0.75 - bleacherMesh.Size.Z / 2) })
	end
end
local backZ = sz0 - 3 * rows - 1
block(stands, "BackWall", Vector3.new(standLen + 2, 16, 2), Vector3.new(0, 8, backZ), Palette.White)
block(stands, "BackTrim", Vector3.new(standLen + 2.4, 0.8, 2.4), Vector3.new(0, 16.2, backZ), Palette.Gold)
for side = -1, 1, 2 do
	local wedge = part({ Class = "WedgePart", Parent = stands, Name = "SideWall", Size = Vector3.new(1.5, 10, 3 * rows), CFrame = CFrame.new(side * (standLen / 2 + 0.75), 5, sz0 - 1.5 * rows) * CFrame.Angles(0, math.pi, 0), Color = Palette.White })
	wedge.Size = Vector3.new(1.5, 1 + 1.3 * rows + 1, 3 * rows)
	wedge.CFrame = CFrame.new(side * (standLen / 2 + 0.75), wedge.Size.Y / 2, sz0 - 1.5 * rows) * CFrame.Angles(0, math.pi, 0)
end
-- front rail (the mesh sections have their own)
if not bleacherMesh then
	block(stands, "Rail", Vector3.new(standLen, 0.3, 0.3), Vector3.new(0, 3.2, sz0 + 0.6), W.Aluminium)
	for i = 0, 10 do
		block(stands, "RailPost", Vector3.new(0.3, 3.2, 0.3), Vector3.new(-standLen / 2 + 1 + i * (standLen - 2) / 10, 1.6, sz0 + 0.6), W.Aluminium)
	end
end
-- big screen on the back wall (visible from the spawn across the track)
local screenFrame = block(stands, "ScreenFrame", Vector3.new(40, 13, 1), Vector3.new(0, 23, backZ + 0.2), Palette.SpeedBlack)
block(stands, "ScreenGlow", Vector3.new(40.6, 13.6, 0.6), Vector3.new(0, 23, backZ - 0.1), Palette.ElectricBlue, { Material = Enum.Material.Neon })
block(stands, "ScreenLeg", Vector3.new(1.5, 10, 1.5), Vector3.new(-14, 15, backZ - 0.8), Palette.White)
block(stands, "ScreenLeg", Vector3.new(1.5, 10, 1.5), Vector3.new(14, 15, backZ - 0.8), Palette.White)
surfaceText(screenFrame, Enum.NormalId.Back, {
	{ Text = "SPEED ARC", Height = 0.42, Color = Palette.Gold, Stroke = Palette.DeepGold, StrokeThickness = 2 },
	{ Name = "RaceTimerText", Text = "NEXT RACE 3:00", Height = 0.3, Color = Palette.White },
	{ Text = "EVERYONE STARTS SLOW", Height = 0.12, Color = Palette.BrightBlue, Font = BODY },
}, { PPS = 12, Brightness = 2.2, MaxDistance = 400 })
flag(Vector3.new(-standLen / 2, 16.6, backZ), Palette.ElectricBlue, Palette.Gold, 6)
flag(Vector3.new(standLen / 2 - 4, 16.6, backZ), Palette.Gold, Palette.ElectricBlue, 6)

-- crowd: low-poly people in team colours on the seats (they bob and cheer on the client)
local SKIN = { "#F2CDA8", "#E8B48A", "#C68B62", "#8D5A3B", "#5E3A26", "#F5D4B5" }
local SHIRTS = { Palette.ElectricBlue, Palette.Gold, Palette.White, Palette.BrightBlue, Palette.DeepBlue, Palette.ElectricBlue, Palette.Gold }
local count = 0
for k = 1, rows do
	local h = 1 + 1.3 * k + 0.5
	local z = sz0 - 1.5 - 3 * (k - 1) + 0.2
	local x = -standLen / 2 + 3 + rng:NextNumber(0, 2)
	while x < standLen / 2 - 3 do
		local fanMesh = meshTemplate("Crowd_Fan_A")
		if rng:NextNumber() < 0.82 and fanMesh then
			-- Blender fans: A blue, B gold with a flag (arm on +X), C white; body is 1.7 wide
			local pick = ({ "Crowd_Fan_A", "Crowd_Fan_B", "Crowd_Fan_C", "Crowd_Fan_A" })[rng:NextInteger(1, 4)]
			local t = meshTemplate(pick)
			local fan = mesh(pick, crowdF, CFrame.new(x, h, z) * CFrame.Angles(0, rng:NextNumber(-0.12, 0.12), 0), { Offset = Vector3.new(t.Size.X / 2 - 0.85, 0, 0), Scale = rng:NextNumber(0.95, 1.06), CanCollide = false, Name = "Fan" })
			fan:SetAttribute("Phase", rng:NextNumber(0, 6.28))
			count += 1
		elseif rng:NextNumber() < 0.82 then
			local m = Instance.new("Model")
			m.Name = "Fan"
			m:SetAttribute("Phase", rng:NextNumber(0, 6.28))
			local shirt = SHIRTS[rng:NextInteger(1, #SHIRTS)]
			local body = block(m, "Body", Vector3.new(1.7, 2.1, 1.1), Vector3.new(x, h + 1.05, z), shirt, { CanCollide = false, CanQuery = false })
			ball(m, "Head", 1.35, Vector3.new(x, h + 2.75, z), Color3.fromHex(SKIN[rng:NextInteger(1, #SKIN)]), { CanCollide = false, CanQuery = false })
			if rng:NextNumber() < 0.35 then
				-- arms up holding a little flag
				block(m, "Arm", Vector3.new(0.45, 1.6, 0.45), Vector3.new(x + 1, h + 2.6, z), shirt, { CanCollide = false, CanQuery = false })
				block(m, "HandFlag", Vector3.new(0.9, 0.6, 0.08), Vector3.new(x + 1.5, h + 3.4, z), if shirt == Palette.Gold then Palette.ElectricBlue else Palette.Gold, { CanCollide = false, CanQuery = false })
			end
			m.Parent = crowdF
			count += 1
		end
		x += rng:NextNumber(3.6, 5)
	end
end

-- spawn on the plaza, facing south down the wall course
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 0.4, 6)
spawn.CFrame = CFrame.lookAt(PLAZA + Vector3.new(0, 0.7, -14), PLAZA + Vector3.new(0, 0.7, 40))
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Duration = 0
spawn.Neutral = true
local decal = spawn:FindFirstChildOfClass("Decal")
if decal then
	decal:Destroy()
end
spawn.Parent = hub
floatLabel(props, Vector3.new(0, 28, 40), "RACE TRACK", "A RACE EVERY 3 MINUTES", Palette.Sky, 44, 12)

----------------------------------------------------------------------------
-- WALL COURSE (south): the shared builder (builder_lib L.course, same in every world). Hedges along
-- the course strip and a closed end show where it stops.
----------------------------------------------------------------------------
do
	L.course(hub, "Hub", { League = 1, Theme = "hub", Accent = Palette.Pink })
	local stripZ0, stripZ1 = 292, COURSE_END + 60
	for _, x in { -88, 88 } do
		block(props, "CourseHedge", Vector3.new(4, 5, stripZ1 - stripZ0), Vector3.new(x, 2.5, (stripZ0 + stripZ1) / 2), W.TreeLeafDark)
	end
	block(props, "CourseHedge", Vector3.new(180, 5, 4), Vector3.new(0, 2.5, stripZ1), W.TreeLeafDark)
end

----------------------------------------------------------------------------
-- SHOPS (west): four candy kiosks in a row facing the plaza. Each is built in its own frame
-- (local -Z = the front); the prompt part's RightVector points out of the front (TutorialService).
----------------------------------------------------------------------------
local Coaches = require(ReplicatedStorage.Shared.Config.Coaches:Clone())
local shops = folder("Shops")
block(shops, "ShopPadEdge", Vector3.new(68, 0.5, 136), Vector3.new(-118, 0.25, PLAZA.Z), Palette.Orange)
block(shops, "ShopPad", Vector3.new(66, 0.56, 134), Vector3.new(-118, 0.28, PLAZA.Z), Color3.fromHex("#FFE2B8"))
floatLabel(shops, Vector3.new(-122, 36, PLAZA.Z), "SHOPS", "SHOES - TRAILS - COACHES - KITS", Palette.Orange, 44, 12)

local function kiosk(name, front, a, b, sub, label, opens, action)
	local m = modelIn(name, shops)
	local cf = CFrame.lookAt(front, front + Vector3.xAxis) -- every kiosk faces east, towards the plaza
	local Wk, D = 22, 16
	local function kp(pname, size, x, y, z, color, extra)
		extra = extra or {}
		extra.Parent = extra.Parent or m
		extra.Name = pname
		extra.Size = size
		extra.CFrame = (extra.Turn and cf * CFrame.new(x, y, z) * extra.Turn) or cf * CFrame.new(x, y, z)
		extra.Turn = nil
		extra.Color = color
		return part(extra)
	end
	kp("Floor", Vector3.new(Wk, 0.62, D), 0, 0.31, D / 2, Palette.White)
	kp("BackWall", Vector3.new(Wk, 11, 1.2), 0, 6.1, D - 0.6, Palette.White)
	kp("BackPanel", Vector3.new(Wk - 4, 6.5, 0.3), 0, 6.6, D - 1.3, b)
	for _, s in { -1, 1 } do
		kp("SideWall", Vector3.new(1.2, 11, D), s * (Wk / 2 - 0.6), 6.1, D / 2, Palette.White)
		kp("SideStripe", Vector3.new(1.3, 1.2, D + 0.1), s * (Wk / 2 - 0.6), 9, D / 2, a)
		kp("Pillar", Vector3.new(12, 1.8, 1.8), s * (Wk / 2 - 0.6), 6.6, 0.4, a, { Shape = Enum.PartType.Cylinder, Turn = CFrame.Angles(0, 0, math.pi / 2) })
		kp("PillarCap", Vector3.new(2.4, 2.4, 2.4), s * (Wk / 2 - 0.6), 12.9, 0.4, b, { Shape = Enum.PartType.Ball })
	end
	kp("Roof", Vector3.new(Wk + 2, 1.4, D + 2), 0, 12.6, D / 2, a)
	kp("RoofTrim", Vector3.new(Wk + 2.4, 0.5, D + 2.4), 0, 11.9, D / 2, Palette.White)
	for i = 0, 6 do
		-- striped awning sloping down over the front (a WedgePart is tall at its +Z, the kiosk side)
		kp("Awning", Vector3.new(Wk / 7 + 0.02, 1.8, 4), -Wk / 2 + Wk / 14 + i * Wk / 7, 10.9, -1.6, if i % 2 == 0 then b else Palette.White, { Class = "WedgePart" })
	end
	kp("Counter", Vector3.new(Wk - 4, 3.6, 2.8), 0, 2.1, 2.6, Palette.White)
	kp("CounterFront", Vector3.new(Wk - 4.2, 2.2, 0.2), 0, 2.3, 1.15, a)
	kp("CounterTop", Vector3.new(Wk - 3.4, 0.5, 3.4), 0, 4.15, 2.6, b)
	local band = kp("Facade", Vector3.new(Wk + 2, 2.4, 0.6), 0, 14.5, 0.2, Palette.White)
	surfaceText(band, Enum.NormalId.Front, { { Text = sub, Height = 0.8, Color = a, Font = BODY } }, { PPS = 20, MaxDistance = 200, Padding = 0 })
	floatLabel(m, (cf * CFrame.new(0, 20, D / 2)).Position, label, nil, a, 22, 6)
	local spot = kp("PromptSpot", Vector3.new(1, 1, 1), 0, 3, -3, Palette.Gold, { Transparency = 1, CanCollide = false, Turn = CFrame.Angles(0, math.pi / 2, 0) })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = label
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Opens", opens)
	pp.Parent = spot
	return m, cf, kp
end

local KX = -116 -- the kiosks' front line
-- Shoe Shop: six pedestals on the counter (the client puts a turning shoe on each, dark if locked)
do
	local m, cf, kp = kiosk("ShoeShop", Vector3.new(KX, 0, 92), Palette.Orange, Palette.Gold, "RUN FASTER IN BETTER SHOES", "SHOES", "ShoeShop", "SHOP")
	local ped = Instance.new("Folder")
	ped.Name = "ShoePedestals"
	ped.Parent = m
	for i = 1, 6 do
		local x = -7.5 + (i - 1) * 3
		local top = kp("Pedestal" .. i, Vector3.new(1.8, 0.8, 1.8), x, 4.8, 2.6, Palette.White, { Parent = ped })
		top:SetAttribute("ShoeIndex", i)
		kp("PedestalRing", Vector3.new(2, 0.2, 2), x, 4.45, 2.6, Palette.Gold, { CanCollide = false })
		local tag = kp("Tag" .. i, Vector3.new(2.7, 0.8, 0.2), x, 2.6, 1.0, Palette.SpeedBlack, { CanCollide = false })
		local g = surfaceText(tag, Enum.NormalId.Front, { { Name = "Label", Text = "SHOES", Height = 0.8, Color = Palette.White, Font = BODY } }, { PPS = 40, MaxDistance = 60 })
		local ref = Instance.new("ObjectValue") -- the client writes the pair's name / unlock here
		ref.Name = "LabelRef"
		ref.Value = g:FindFirstChild("Label")
		ref.Parent = top
	end
	for i = 0, 1 do -- shoe boxes on two shelves
		kp("Shelf", Vector3.new(14, 0.3, 1.2), 0, 6.5 + i * 2.6, 14.8, Palette.White)
		for j = 0, 3 do
			kp("ShoeBox", Vector3.new(2.6, 1.4, 1), -4.5 + j * 3, 7.35 + i * 2.6, 14.8, if (i + j) % 2 == 0 then Palette.Orange else Palette.Sky)
		end
	end
end
-- Trail Booth: a demo streak loops behind the counter (MenuController moves "Demo")
do
	local m, cf = kiosk("TrailBooth", Vector3.new(KX, 0, 124), Palette.Pink, Palette.Purple, "LEAVE A STREAK BEHIND YOU", "TRAILS", "TrailBooth", "SHOP")
	local demo = part({ Parent = m, Name = "Demo", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = cf * CFrame.new(0, 7.6, 9) * CFrame.Angles(0, math.pi / 2, 0), Color = Palette.Gold, Transparency = 1, CanCollide = false })
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.7, 0)
	a0.Parent = demo
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.7, 0)
	a1.Parent = demo
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.6
	tr.LightEmission = 1
	tr.FaceCamera = true
	tr.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#FFE38C")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FF6FB5")), ColorSequenceKeypoint.new(1, Color3.fromHex("#6FDDFF")) })
	tr.Transparency = NumberSequence.new(0, 1)
	tr.Parent = demo
end
-- Coach Corner: the coach cards on a board on the back wall
do
	local _, _, kp = kiosk("CoachCorner", Vector3.new(KX, 0, 156), Palette.Mint, Palette.Gold, "ROLL COACHES HERE", "COACH AGENCY", "CoachCorner", "ROLL")
	local board = kp("Whiteboard", Vector3.new(16, 6, 0.3), 0, 7.4, 14.2, Palette.White)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 24
	g.MaxDistance = 90
	g.LightInfluence = 0.4
	g.Parent = board
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.25, -8, 0.5, -10)
	grid.CellPadding = UDim2.fromOffset(8, 10)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
	grid.Parent = g
	for _, c in Coaches.List do
		local cardF = Instance.new("Frame")
		cardF.BackgroundColor3 = Palette.Carbon
		cardF.BorderSizePixel = 0
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 8)
		cr.Parent = cardF
		local st = Instance.new("UIStroke")
		st.Color = Coaches.RarityColors[c.Rarity]
		st.Thickness = 3
		st.Parent = cardF
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 0.62)
		t.TextScaled = true
		t.FontFace = MONTSERRAT
		t.Text = string.upper(c.Name)
		t.TextColor3 = Palette.White
		t.Parent = cardF
		local r = t:Clone()
		r.Position = UDim2.fromScale(0, 0.62)
		r.Size = UDim2.fromScale(1, 0.34)
		r.FontFace = BODY
		r.Text = string.upper(c.Rarity)
		r.TextColor3 = Coaches.RarityColors[c.Rarity]
		r.Parent = cardF
		cardF.Parent = g
	end
end
-- Locker Room: six lockers along the back (opens the Locker on KITS)
do
	local _, _, kp = kiosk("LockerRoom", Vector3.new(KX, 0, 188), Palette.Sky, Palette.Gold, "KITS, HATS AND NAME STYLES", "LOCKER", "Locker", "OPEN")
	for k = 1, 6 do
		local x = -7.5 + (k - 1) * 3
		kp("Locker", Vector3.new(2.8, 7.6, 1.6), x, 4.4, 14.2, Palette.Sky)
		kp("LockerDoor", Vector3.new(2.4, 6.8, 0.12), x, 4.5, 13.36, Color3.fromHex("#8FD3FF"), { CanCollide = false })
		kp("Handle", Vector3.new(0.25, 1, 0.2), x + 0.8, 4.4, 13.25, Palette.Gold, { CanCollide = false })
		for v = 0, 2 do
			kp("Vent", Vector3.new(1.6, 0.16, 0.14), x, 7.3 - v * 0.4, 13.28, Palette.Sky, { CanCollide = false })
		end
	end
end

----------------------------------------------------------------------------
-- PORTALS (east): 5 big gates in a row facing the plaza, nothing in front of them, a light beam
-- over each. Unlocked gates teleport (AreaService), locked ones go dark on the client with their
-- requirement; 4-5 are COMING SOON (NOTIFY ME).
----------------------------------------------------------------------------
do
	local plaza = folder("PortalPlaza")
	block(plaza, "PortalPadEdge", Vector3.new(68, 0.5, 158), Vector3.new(118, 0.25, PLAZA.Z), Palette.Purple)
	block(plaza, "PortalPad", Vector3.new(66, 0.56, 156), Vector3.new(118, 0.28, PLAZA.Z), Color3.fromHex("#D9C8FF"))
	floatLabel(plaza, Vector3.new(104, 40, PLAZA.Z), "PORTALS", "GO PRO TO OPEN NEW WORLDS", Palette.Purple, 46, 12)
	local gates = {
		{ "HOMETOWN TRACK", "LEAGUE 1  -  YOU ARE HERE", Palette.Sky, nil, false },
		{ "CITY PARK RUN", "LEAGUE 2", Palette.Mint, "Park", false },
		{ "BIG STADIUM", "LEAGUE 3", Palette.Purple, "Stadium", false },
		{ "MOUNTAIN TRAIL", "COMING SOON", Palette.Orange, "Soon", true },
		{ "WORLD GAMES", "COMING SOON", Palette.Gold, "Soon", true },
	}
	for i, g in gates do
		local pos = Vector3.new(132, 0.56, PLAZA.Z + (i - 3) * 30)
		local cf = CFrame.lookAt(pos, pos - Vector3.xAxis) -- faces west, towards the plaza
		local m = Instance.new("Model")
		m.Name = "Gate" .. i
		m:SetAttribute("League", i)
		m.Parent = plaza
		part({ Parent = m, Name = "Base", Size = Vector3.new(19, 1, 8), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Palette.White })
		for _, s in { -1, 1 } do
			part({ Parent = m, Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18, 3.4, 3.4), CFrame = cf * CFrame.new(s * 7.8, 10, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Palette.White })
			part({ Parent = m, Name = "PillarCap", Shape = Enum.PartType.Ball, Size = Vector3.new(4.4, 4.4, 4.4), CFrame = cf * CFrame.new(s * 7.8, 19.6, 0), Color = g[3] })
			part({ Parent = m, Name = "PillarGlow", Size = Vector3.new(0.4, 16, 0.4), CFrame = cf * CFrame.new(s * 6.1, 9.6, -1.2), Color = g[3], Material = Enum.Material.Neon, CanCollide = false })
		end
		part({ Parent = m, Name = "Beam", Size = Vector3.new(15, 2.6, 3), CFrame = cf * CFrame.new(0, 18.6, 0), Color = g[3] })
		part({ Parent = m, Name = "BeamGold", Size = Vector3.new(15.4, 0.5, 3.4), CFrame = cf * CFrame.new(0, 17.2, 0), Color = Palette.Gold })
		local portal = part({ Parent = m, Name = "Portal", Size = Vector3.new(12, 16, 0.3), CFrame = cf * CFrame.new(0, 9, 0), Color = g[3], Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false })
		portal:SetAttribute("Accent", g[3]:ToHex())
		part({ Parent = m, Name = "Beacon", Size = Vector3.new(1.6, 80, 1.6), CFrame = cf * CFrame.new(0, 20 + 40, 0), Color = g[3], Material = Enum.Material.Neon, Transparency = 0.62, CanCollide = false, CanQuery = false })
		local board = part({ Parent = m, Name = "Board", Size = Vector3.new(16, 3.6, 0.6), CFrame = cf * CFrame.new(0, 23.6, -0.4), Color = Palette.SpeedBlack, CanCollide = false })
		surfaceText(board, Enum.NormalId.Front, {
			{ Name = "Title", Text = g[1], Height = 0.55, Color = Palette.White },
			{ Name = "Sub", Text = g[2], Height = 0.3, Color = Palette.Gold, Font = BODY },
		}, { PPS = 22, MaxDistance = 360, Padding = 0 })
		if g[4] then
			local trigger = part({ Parent = m, Name = "Trigger", Size = Vector3.new(11, 15, 2), CFrame = cf * CFrame.new(0, 8.5, 0), Transparency = 1, CanCollide = false })
			trigger.CanTouch = true
			trigger:SetAttribute("GateArea", g[4])
		end
		if g[5] then
			local spot = part({ Parent = m, Name = "NotifySpot", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 2.5, -2.5), Transparency = 1, CanCollide = false })
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "NOTIFY ME"
			pp.ObjectText = g[1]
			pp.HoldDuration = 0
			pp.MaxActivationDistance = 12
			pp.RequiresLineOfSight = false
			pp:SetAttribute("Opens", "NotifyMe")
			pp.Parent = spot
		end
	end
end

----------------------------------------------------------------------------
-- AFK TREADMILLS (south-west of the plaza): a row of six under a canopy, runners face the plaza.
-- They step for you (TrainingService); running the course is faster.
----------------------------------------------------------------------------
local tread = modelIn("Treadmill", training)
do
	local cx, tz = -55, 214
	block(tread, "MatEdge", Vector3.new(52, 0.5, 36), Vector3.new(cx, 0.25, tz), Palette.White)
	block(tread, "Mat", Vector3.new(50, 0.56, 34), Vector3.new(cx, 0.28, tz), Palette.Mint)
	for i = 1, 6 do
		local x = cx - 16.25 + (i - 1) * 6.5
		local m = modelIn("Treadmill" .. i, tread)
		local tm = meshTemplate("Treadmill")
		local y0 = 0.56
		if tm then
			-- Blender deck runs y -3.5..3.5 with the console past -3.5; lifted 0.08 so the belt meets the slot
			mesh("Treadmill", m, CFrame.new(x, y0 + 0.08, tz), { Offset = Vector3.new(0, 0, 3.5 - tm.Size.Z / 2) })
			block(m, "BeltStripe", Vector3.new(0.2, 0.03, 6.0), Vector3.new(x - 1.12, y0 + 0.93, tz + 0.15), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
			block(m, "BeltStripe", Vector3.new(0.2, 0.03, 6.0), Vector3.new(x + 1.12, y0 + 0.93, tz + 0.15), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
			block(m, "Screen", Vector3.new(2.1, 0.66, 0.04), Vector3.new(x, y0 + 4.85, tz - 3.04), Palette.BrightBlue, { Material = Enum.Material.Neon, CanCollide = false })
		else
			block(m, "Deck", Vector3.new(3.6, 0.8, 7), Vector3.new(x, y0 + 0.4, tz), Palette.White)
			block(m, "Belt", Vector3.new(2.8, 0.82, 6.2), Vector3.new(x, y0 + 0.42, tz), Palette.SpeedBlack)
			block(m, "Console", Vector3.new(3.4, 1.4, 0.6), Vector3.new(x, y0 + 4.4, tz - 3.3), Palette.Sky)
		end
		local slotY = y0 + (if tm then 0.91 else 0.82)
		local s = part({ Parent = m, Name = "Slot", Size = Vector3.new(2.5, 0.2, 2.5), CFrame = CFrame.lookAt(Vector3.new(x, slotY, tz + 0.6), Vector3.new(x, slotY, tz - 10)), Color = Palette.Gold, Transparency = 1, CanCollide = false })
		s:SetAttribute("StationId", "Treadmill")
		s:SetAttribute("Index", i)
		local exit = Instance.new("Attachment")
		exit.Name = "Exit"
		exit.Position = Vector3.new(0, 0, 6) -- off the back of the machine
		exit.Parent = s
	end
	for _, px in { cx - 22, cx + 22 } do
		for _, pz in { tz - 7, tz + 7 } do
			part({ Parent = tread, Name = "CanopyPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 1.2, 1.2), CFrame = CFrame.new(px, 6.5, pz) * CFrame.Angles(0, 0, math.pi / 2), Color = Palette.White })
		end
	end
	block(tread, "CanopyRoof", Vector3.new(48, 1, 18), Vector3.new(cx, 12.8, tz), Palette.Sky)
	block(tread, "CanopyTrim", Vector3.new(48.4, 0.5, 18.4), Vector3.new(cx, 12.1, tz), Palette.Gold)
	floatLabel(tread, Vector3.new(cx, 22, tz), "AFK TREADMILLS", "THEY STEP FOR YOU", Palette.Mint, 36, 10)
end

----------------------------------------------------------------------------
-- LEADERBOARDS (south-east of the plaza): four boards in a row facing the plaza. Filled by
-- LeaderboardService (parts with a "Board" attribute, rows Row1..Row5)
----------------------------------------------------------------------------
do
	local wall = folder("LeaderboardWall")
	local boardsList = {
		{ "Speed", "TOP SPEED", Palette.Gold },
		{ "Wins", "MOST WINS", Palette.Sky },
		{ "WeeklyWins", "WINS THIS WEEK", Palette.Pink },
		{ "WeeklyTime", "FASTEST SPRINT THIS WEEK", Palette.Mint },
	}
	block(wall, "PadEdge", Vector3.new(60, 0.5, 18), Vector3.new(56, 0.25, 214), Palette.Gold)
	block(wall, "Pad", Vector3.new(58, 0.56, 16), Vector3.new(56, 0.28, 214), Color3.fromHex("#FFE9A8"))
	floatLabel(wall, Vector3.new(56, 22, 216), "LEADERBOARDS", nil, Palette.Gold, 30, 6)
	for i, b in boardsList do
		local pos = Vector3.new(35 + (i - 1) * 14, 0.56, 216)
		local cf = CFrame.lookAt(pos, pos - Vector3.zAxis) -- faces north, towards the plaza
		for _, s in { -1, 1 } do
			part({ Parent = wall, Name = "Leg", Size = Vector3.new(1, 4, 1), CFrame = cf * CFrame.new(s * 4.5, 2, 0.4), Color = Palette.White })
		end
		part({ Parent = wall, Name = "Trim", Size = Vector3.new(12.6, 9.6, 0.6), CFrame = cf * CFrame.new(0, 8.6, 0.3), Color = b[3] })
		local board = part({ Parent = wall, Name = "Board", Size = Vector3.new(12, 9, 0.4), CFrame = cf * CFrame.new(0, 8.6, 0), Color = Palette.SpeedBlack })
		board:SetAttribute("Board", b[1])
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 24
		gui.MaxDistance = 220
		gui.LightInfluence = 0.2
		gui.Brightness = 1.4
		gui.Parent = board
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 0.18)
		t.Position = UDim2.fromScale(0, 0.02)
		t.TextScaled = true
		t.FontFace = MONTSERRAT
		t.Text = b[2]
		t.TextColor3 = b[3]
		t.Parent = gui
		local rows = Instance.new("Frame")
		rows.Name = "Rows"
		rows.BackgroundTransparency = 1
		rows.Position = UDim2.fromScale(0.05, 0.22)
		rows.Size = UDim2.fromScale(0.9, 0.74)
		rows.Parent = gui
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = rows
		for r = 1, 5 do
			local l = Instance.new("TextLabel")
			l.Name = "Row" .. r
			l.LayoutOrder = r
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 0.2)
			l.TextScaled = true
			l.FontFace = BODY
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Text = if r == 1 then "LOADING..." else "" -- LeaderboardService fills the rows
			l.TextColor3 = if r == 1 then Palette.Gold else Palette.White
			l.Parent = rows
		end
	end
end

----------------------------------------------------------------------------
-- trees only round the edges and along the course (never in the play areas), hedges at the edges
----------------------------------------------------------------------------
local function tree(pos, scale)
	if meshTemplate("Tree_Round_A") then
		local r = rng:NextNumber()
		local name = if r < 0.45 then "Tree_Round_A" elseif r < 0.9 then "Tree_Round_B" else "Tree_Pine"
		return mesh(name, props, CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), { Scale = (scale or 1) * (if name == "Tree_Pine" then 1.25 else 1), CastShadow = true, Name = "Tree" })
	end
	local m = Instance.new("Model")
	m.Name = "Tree"
	m.Parent = props
	scale = scale or 1
	cyl(m, "Trunk", 0.7 * scale, 6 * scale, pos + Vector3.new(0, 3 * scale, 0), W.Trunk, { CastShadow = false })
	local leaf = { W.TreeLeaf, W.TreeLeafLight, W.TreeLeafDark }
	ball(m, "Crown", 8 * scale, pos + Vector3.new(0, 8.5 * scale, 0), leaf[rng:NextInteger(1, 3)], { CastShadow = true })
	ball(m, "Crown2", 5.5 * scale, pos + Vector3.new(2.2 * scale, 10.5 * scale, 1 * scale), leaf[rng:NextInteger(1, 3)], { CastShadow = false })
	return m
end
local treeSpots = {}
for i = 0, 10 do
	table.insert(treeSpots, { -150 + i * 30, -100 }) -- behind the stands
end
for i = 0, 8 do
	table.insert(treeSpots, { -178, -80 + i * 42 }) -- the west edge
	table.insert(treeSpots, { 178, -80 + i * 42 }) -- the east edge
end
for z = 250, COURSE_END + 20, 55 do
	table.insert(treeSpots, { -52, z }) -- along both sides of the course
	table.insert(treeSpots, { 52, z + 27 })
end
for _, s in { { -130, 260 }, { -100, 270 }, { 110, 265 }, { 150, 255 }, { -150, 30 }, { 150, 30 }, { -140, -40 }, { 140, -40 } } do
	table.insert(treeSpots, s)
end
for _, s in treeSpots do
	tree(Vector3.new(s[1] + rng:NextNumber(-4, 4), 0, s[2] + rng:NextNumber(-4, 4)), rng:NextNumber(1.0, 1.4))
end
local hedgeC = W.TreeLeafDark
block(props, "Hedge", Vector3.new(4, 5, 404), Vector3.new(-196, 2.5, 90), hedgeC)
block(props, "Hedge", Vector3.new(4, 5, 404), Vector3.new(196, 2.5, 90), hedgeC)
block(props, "Hedge", Vector3.new(396, 5, 4), Vector3.new(0, 2.5, -112), hedgeC)
block(props, "Hedge", Vector3.new(170, 5, 4), Vector3.new(-111, 2.5, 292), hedgeC)
block(props, "Hedge", Vector3.new(170, 5, 4), Vector3.new(111, 2.5, 292), hedgeC)

----------------------------------------------------------------------------
-- finish
----------------------------------------------------------------------------
tmp:Destroy()
hub.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- the home area is always there
hub.Parent = workspace

-- lighting preset (the client applies the same values; this is for the edit view)
local LP = require(ReplicatedStorage.Shared.Config.Lighting:Clone()).Hub
Lighting.ClockTime = LP.ClockTime
Lighting.GeographicLatitude = LP.GeographicLatitude
Lighting.Brightness = LP.Brightness
Lighting.Ambient = LP.Ambient
Lighting.OutdoorAmbient = LP.OutdoorAmbient
Lighting.EnvironmentDiffuseScale = LP.EnvironmentDiffuseScale
Lighting.EnvironmentSpecularScale = LP.EnvironmentSpecularScale
Lighting.ExposureCompensation = LP.ExposureCompensation
Lighting.GlobalShadows = true
pcall(function()
	Lighting.Technology = Enum.Technology.ShadowMap
end)
local function ensure(class, name)
	local i = Lighting:FindFirstChild(name) or Instance.new(class)
	i.Name = name
	i.Parent = Lighting
	return i
end
local cc = ensure("ColorCorrectionEffect", "AreaGrade")
for k, v in LP.ColorCorrection do
	cc[k] = v
end
local bl = ensure("BloomEffect", "AreaBloom")
for k, v in LP.Bloom do
	bl[k] = v
end
local sr = ensure("SunRaysEffect", "AreaSunRays")
for k, v in LP.SunRays do
	sr[k] = v
end
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "Atmosphere")
for k, v in LP.Atmosphere do
	atmo[k] = v
end
for _, o in Lighting:GetChildren() do
	if (o:IsA("BloomEffect") and o ~= bl) or (o:IsA("ColorCorrectionEffect") and o ~= cc) or (o:IsA("SunRaysEffect") and o ~= sr) then
		o:Destroy()
	end
end
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = LP.Clouds.Cover
clouds.Density = LP.Clouds.Density
clouds.Color = LP.Clouds.Color
clouds.Parent = workspace.Terrain

-- streaming: small radius, separate areas (performance rules)
workspace.StreamingEnabled = true
pcall(function()
	workspace.StreamingTargetRadius = 400
	workspace.StreamingMinRadius = 128
end)

local n = 0
for _, d in hub:GetDescendants() do
	if d:IsA("BasePart") then
		n += 1
	end
end
return ("Hub built: %d parts, %d fans"):format(n, count)
