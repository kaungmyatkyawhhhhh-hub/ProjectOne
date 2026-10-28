-- SPEED ARC: builds the Hub (Hometown Track) in Studio. Run in edit mode (MCP or command bar via sync).
-- Stylized low-poly look from smooth parts + CSG for the curved track. Hero props get replaced by
-- the Blender meshes (Downloads\speed_arc_models\hub\) once they are imported.
-- Re-running replaces workspace.Hub (the old one is moved to ServerStorage as a dated backup).
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
-- layout (28 Oct redesign): you spawn in the round CENTRAL PLAZA and every district is in view.
-- North: the race track. West: SHOP STREET (only shops). East: the PORTALS avenue to the portal
-- stage. South: the TRAINING YARD (only training), the school behind it. Each district has its own
-- paving, a neon line in its colour along the kerbs and an arch with its name at the plaza.
----------------------------------------------------------------------------
local PLAZA = Vector3.new(0, 0, 104)
local PLAZA_R = 26
local AVE_W = 22
local SHOP_END = -134 -- shop street runs from the plaza to the fountain
local STAGE = Vector3.new(140, 0, 104) -- portal stage centre
local STAGE_R = 36
local YARD_Z0, YARD_Z1, YARD_W = 150, 222, 144
local DISTRICT = {
	Shops = { Paving = Color3.fromHex("#D9CDB5"), Joint = Color3.fromHex("#C5B89E"), Accent = Palette.Gold },
	Portals = { Paving = Color3.fromHex("#BCC7D8"), Joint = Color3.fromHex("#A8B3C6"), Accent = Palette.BrightBlue },
	Training = { Paving = Color3.fromHex("#C9D0DB"), Joint = Color3.fromHex("#B4BCC8"), Accent = Palette.ElectricBlue },
	Track = { Paving = Color3.fromHex("#C9D0DB"), Joint = Color3.fromHex("#B4BCC8"), Accent = Palette.White },
}

local function modelIn(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
-- a build made facing +X around 'from' is moved so that point sits at 'to', facing 'facing'
local function place(model, from, to, facing)
	model.WorldPivot = CFrame.lookAt(from, from + Vector3.xAxis)
	model:PivotTo(CFrame.lookAt(to, to + facing))
end

block(ground, "Grass", Vector3.new(400, 4, 410), Vector3.new(0, -2, 84), W.Grass)
block(ground, "Outskirts", Vector3.new(1600, 4, 1600), Vector3.new(0, -2.25, 84), Color3.fromHex("#4E9446"))
-- low hills on the horizon (half buried balls) so the world never ends in empty sky
local hillCols = { Color3.fromHex("#5BA04F"), Color3.fromHex("#4A8C43"), Color3.fromHex("#6AAE57") }
for i = 0, 15 do
	local a = i / 16 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
	local d = rng:NextNumber(450, 590)
	local size = rng:NextNumber(150, 260)
	ball(ground, "Hill", size, Vector3.new(math.cos(a) * d, -size * 0.32, 84 + math.sin(a) * d), hillCols[i % 3 + 1], { CanCollide = false, CanQuery = false })
end
for i = 0, 19 do
	local x = -200 + i * 20
	if i % 2 == 0 then
		block(ground, "Stripe", Vector3.new(10, 0.06, 404), Vector3.new(x + 5, 0.03, 84), W.GrassDark, { CanCollide = false })
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

-- a paved avenue from a to b with kerbs and a neon line in its district's colour
local function avenue(name, a, b, width, d)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	part({ Parent = ground, Name = name, Size = Vector3.new(width, 0.25, len), CFrame = cf * CFrame.new(0, 0.125, 0), Color = d.Paving })
	for s = 6, len - 3, 6 do
		part({ Parent = ground, Name = "Joint", Size = Vector3.new(width - 0.2, 0.26, 0.2), CFrame = cf * CFrame.new(0, 0.13, len / 2 - s), Color = d.Joint, CanCollide = false })
	end
	for side = -1, 1, 2 do
		part({ Parent = ground, Name = "Kerb", Size = Vector3.new(0.9, 0.45, len), CFrame = cf * CFrame.new(side * (width / 2 + 0.45), 0.225, 0), Color = W.Concrete })
		part({ Parent = ground, Name = "KerbLine", Size = Vector3.new(0.3, 0.27, len), CFrame = cf * CFrame.new(side * (width / 2 - 1), 0.135, 0), Color = d.Accent, Material = Enum.Material.Neon, CanCollide = false })
	end
end
avenue("ShopStreet", PLAZA + Vector3.new(-23, 0, 0), Vector3.new(SHOP_END, 0, PLAZA.Z), AVE_W, DISTRICT.Shops)
avenue("PortalAvenue", PLAZA + Vector3.new(23, 0, 0), STAGE - Vector3.new(STAGE_R - 2, 0, 0), AVE_W, DISTRICT.Portals)
avenue("YardPath", PLAZA + Vector3.new(0, 0, 23), Vector3.new(0, 0, YARD_Z0 + 1), 20, DISTRICT.Training)
avenue("TrackPath", PLAZA + Vector3.new(0, 0, -23), Vector3.new(0, 0, 57.8), 18, DISTRICT.Track)

-- the plaza: light paving with a darker band and radial joints
cyl(ground, "PlazaEdge", PLAZA_R + 1, 0.34, PLAZA + Vector3.new(0, 0.17, 0), Palette.Graphite)
cyl(ground, "Plaza", PLAZA_R, 0.36, PLAZA + Vector3.new(0, 0.18, 0), Color3.fromHex("#C9D0DB"))
cyl(ground, "PlazaBand", 20, 0.37, PLAZA + Vector3.new(0, 0.185, 0), Color3.fromHex("#AEB7C5"))
cyl(ground, "PlazaInner", 18.8, 0.38, PLAZA + Vector3.new(0, 0.19, 0), Color3.fromHex("#D3D9E2"))
for i = 0, 7 do
	part({ Parent = ground, Name = "PlazaJoint", Size = Vector3.new(0.22, 0.385, PLAZA_R * 2 - 0.6), CFrame = CFrame.new(PLAZA + Vector3.new(0, 0.1925, 0)) * CFrame.Angles(0, i * math.pi / 8, 0), Color = Color3.fromHex("#B4BCC8"), CanCollide = false })
end
-- the SPEED ARC emblem painted in the middle
cyl(ground, "EmblemGold", 10, 0.4, PLAZA + Vector3.new(0, 0.2, 0), Palette.Gold, { CanCollide = false })
cyl(ground, "Emblem", 9.2, 0.42, PLAZA + Vector3.new(0, 0.21, 0), Palette.DeepBlue, { CanCollide = false })
local emblemTop = block(ground, "EmblemText", Vector3.new(16, 0.05, 16), PLAZA + Vector3.new(0, 0.44, 0), Palette.DeepBlue, { Transparency = 1, CanCollide = false })
local eg = Instance.new("SurfaceGui")
eg.Face = Enum.NormalId.Top
eg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
eg.PixelsPerStud = 16
eg.MaxDistance = 160
eg.LightInfluence = 1
eg.Parent = emblemTop
for i, l in { { "SPEED", Palette.White, 0.64 }, { "ARC", Palette.Gold, 0.36 } } do
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(l[3], 0.5)
	t.Size = UDim2.fromScale(0.8, 0.28)
	t.Rotation = 90
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
local archMesh = mesh("Start_Arch", arch, CFrame.new(T.StartX, 0, (z1 + z2) / 2) * CFrame.Angles(0, math.pi / 2, 0))
local function tower(z)
	if not archMesh then
		block(arch, "Leg", Vector3.new(2.4, 18, 2.4), Vector3.new(T.StartX, 9, z), Palette.SpeedBlack)
		block(arch, "Foot", Vector3.new(4, 1, 4), Vector3.new(T.StartX, 0.5, z), Palette.Graphite)
	end
	-- glowing bands stay as Neon parts (just outside the mesh's blue bands)
	block(arch, "LegTrim", Vector3.new(2.7, 0.5, 2.7), Vector3.new(T.StartX, 6, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
	block(arch, "LegTrim", Vector3.new(2.7, 0.5, 2.7), Vector3.new(T.StartX, 12, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
end
tower(z1)
tower(z2)
if not archMesh then
	block(arch, "Beam", Vector3.new(3, 4, span), Vector3.new(T.StartX, 19.5, (z1 + z2) / 2), Palette.SpeedBlack)
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
block(stands, "BackWall", Vector3.new(standLen + 2, 16, 2), Vector3.new(0, 8, backZ), Palette.Carbon)
block(stands, "BackTrim", Vector3.new(standLen + 2.4, 0.8, 2.4), Vector3.new(0, 16.2, backZ), Palette.Gold)
for side = -1, 1, 2 do
	local wedge = part({ Class = "WedgePart", Parent = stands, Name = "SideWall", Size = Vector3.new(1.5, 10, 3 * rows), CFrame = CFrame.new(side * (standLen / 2 + 0.75), 5, sz0 - 1.5 * rows) * CFrame.Angles(0, math.pi, 0), Color = Palette.Carbon })
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
block(stands, "ScreenLeg", Vector3.new(1.5, 10, 1.5), Vector3.new(-14, 15, backZ - 0.8), Palette.SpeedBlack)
block(stands, "ScreenLeg", Vector3.new(1.5, 10, 1.5), Vector3.new(14, 15, backZ - 0.8), Palette.SpeedBlack)
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

----------------------------------------------------------------------------
-- school building (front + sides only, it's the backdrop) with the clock tower and banner
----------------------------------------------------------------------------
local sx0, sFront, sDepth, sW = 0, YARD_Z1 + 14, 22, 124 -- behind the Training Yard
local fz = sFront + sDepth / 2
block(school, "Body", Vector3.new(sW, 24, sDepth), Vector3.new(sx0, 12, fz), W.Brick)
block(school, "Base", Vector3.new(sW + 1, 2, sDepth + 1), Vector3.new(sx0, 1, fz), W.Concrete)
block(school, "FloorBand", Vector3.new(sW + 0.6, 1, sDepth + 0.6), Vector3.new(sx0, 12, fz), W.Concrete)
block(school, "Parapet", Vector3.new(sW + 1.2, 1.6, sDepth + 1.2), Vector3.new(sx0, 24.8, fz), Palette.Graphite)
block(school, "ParapetGold", Vector3.new(sW + 1.3, 0.4, sDepth + 1.3), Vector3.new(sx0, 24.2, fz), Palette.Gold)
-- windows (two floors), lit warm inside, with frames + sills
for floor = 0, 1 do
	local y = 6.5 + floor * 11
	for i = 0, 9 do
		local x = -55 + i * 12.2
		if math.abs(x) > 12 then
			block(school, "WinFrame", Vector3.new(7.2, 6.4, 0.5), Vector3.new(x, y, sFront - 0.1), Palette.White)
			block(school, "Win", Vector3.new(6.2, 5.4, 0.5), Vector3.new(x, y, sFront - 0.2), if (i + floor) % 3 == 0 then W.WindowLit else W.Window)
			block(school, "WinBar", Vector3.new(0.4, 5.4, 0.6), Vector3.new(x, y, sFront - 0.25), Palette.White)
			block(school, "Sill", Vector3.new(7.8, 0.5, 1.2), Vector3.new(x, y - 3.4, sFront - 0.4), W.Concrete)
		end
	end
end
-- entrance: blue doors, gold frame, canopy, steps
block(school, "DoorFrame", Vector3.new(14, 10, 0.8), Vector3.new(0, 5, sFront - 0.2), Palette.Gold)
block(school, "Doors", Vector3.new(12, 9, 0.8), Vector3.new(0, 4.5, sFront - 0.4), Palette.ElectricBlue)
block(school, "DoorGap", Vector3.new(0.3, 9, 0.9), Vector3.new(0, 4.5, sFront - 0.45), Palette.DeepBlue)
block(school, "DoorGlass", Vector3.new(4.2, 3, 0.9), Vector3.new(-3, 6.2, sFront - 0.45), W.Window, { Transparency = 0.15 })
block(school, "DoorGlass", Vector3.new(4.2, 3, 0.9), Vector3.new(3, 6.2, sFront - 0.45), W.Window, { Transparency = 0.15 })
block(school, "Canopy", Vector3.new(20, 0.8, 7), Vector3.new(0, 10.6, sFront - 3.5), Palette.SpeedBlack)
block(school, "CanopyGlow", Vector3.new(20.2, 0.25, 7.2), Vector3.new(0, 10.1, sFront - 3.5), Palette.ElectricBlue, { Material = Enum.Material.Neon })
for i = 1, 3 do
	block(school, "Step", Vector3.new(26 - i * 2, 0.6, 2.4), Vector3.new(0, 0.3 + (i - 1) * 0.6, sFront - 8.5 + i * 2.2), W.Concrete)
end
-- banner between the floors
local banner = block(school, "Banner", Vector3.new(30, 6.5, 0.4), Vector3.new(-34, 12.2, sFront - 0.6), Palette.DeepBlue)
block(school, "BannerTrim", Vector3.new(30.6, 7.1, 0.3), Vector3.new(-34, 12.2, sFront - 0.45), Palette.Gold)
surfaceText(banner, Enum.NormalId.Front, {
	{ Text = "SPEED ARC", Height = 0.62, Color = Palette.Gold, Stroke = Palette.SpeedBlack, StrokeThickness = 2 },
	{ Text = "HOMETOWN TRACK", Height = 0.25, Color = Palette.White, Font = BODY },
}, { PPS = 14, MaxDistance = 260 })
local banner2 = block(school, "Banner2", Vector3.new(30, 6.5, 0.4), Vector3.new(34, 12.2, sFront - 0.6), Palette.SpeedBlack)
block(school, "BannerTrim2", Vector3.new(30.6, 7.1, 0.3), Vector3.new(34, 12.2, sFront - 0.45), Palette.ElectricBlue)
surfaceText(banner2, Enum.NormalId.Front, {
	{ Text = "EVERYONE", Height = 0.42, Color = Palette.White },
	{ Text = "STARTS SLOW", Height = 0.42, Color = Palette.Gold },
}, { PPS = 14, MaxDistance = 260 })
-- clock tower with the race countdown
local tz = sFront + 6
block(school, "Tower", Vector3.new(16, 40, 12), Vector3.new(0, 20, tz), W.BrickDark)
block(school, "TowerBand", Vector3.new(16.6, 1, 12.6), Vector3.new(0, 25, tz), W.Concrete)
block(school, "TowerTop", Vector3.new(17.2, 1.6, 13.2), Vector3.new(0, 40.6, tz), Palette.Graphite)
part({ Class = "WedgePart", Parent = school, Name = "Roof", Size = Vector3.new(17, 7, 6.8), CFrame = CFrame.new(0, 44.9, tz - 3.4), Color = Palette.ElectricBlue })
part({ Class = "WedgePart", Parent = school, Name = "Roof", Size = Vector3.new(17, 7, 6.8), CFrame = CFrame.new(0, 44.9, tz + 3.4) * CFrame.Angles(0, math.pi, 0), Color = Palette.DeepBlue })
ball(school, "Spire", 1.4, Vector3.new(0, 48.8, tz), Palette.Gold)
local clockFace = cyl(school, "ClockRim", 5.6, 0.8, Vector3.new(0, 32.5, tz - 6.2), Palette.Gold)
clockFace.CFrame = CFrame.new(0, 32.5, tz - 6.2) * CFrame.Angles(0, math.pi / 2, 0)
local clock = block(school, "Clock", Vector3.new(9.2, 9.2, 0.6), Vector3.new(0, 32.5, tz - 6.6), Palette.SpeedBlack)
surfaceText(clock, Enum.NormalId.Front, {
	{ Text = "NEXT RACE", Height = 0.22, Color = Palette.BrightBlue, Font = BODY },
	{ Name = "RaceTimerText", Text = "3:00", Height = 0.42, Color = Palette.White },
}, { PPS = 20, Brightness = 2, MaxDistance = 300 })

-- flags on the roof
flag(Vector3.new(-sW / 2 + 4, 25.6, sFront + 2), Palette.ElectricBlue, Palette.Gold, 7)
flag(Vector3.new(sW / 2 - 8, 25.6, sFront + 2), Palette.Gold, Palette.ElectricBlue, 7)

-- spawn in the plaza, facing the track: every district is in view from here
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 0.4, 6)
spawn.CFrame = CFrame.new(PLAZA + Vector3.new(0, 0.5, 14))
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Duration = 0
spawn.Neutral = true
local decal = spawn:FindFirstChildOfClass("Decal")
if decal then
	decal:Destroy()
end
spawn.Parent = hub

----------------------------------------------------------------------------
-- TRAINING YARD (south of the plaza): Sprint Lane, Treadmills, Stair Run, one bay each. Each
-- station is built where it used to stand and then placed in its bay.
----------------------------------------------------------------------------
local function slot(parent, stationId, cf, i)
	local s = part({ Parent = parent, Name = "Slot", Size = Vector3.new(2.5, 0.2, 2.5), CFrame = cf, Color = Palette.Gold, Transparency = 1, CanCollide = false })
	s:SetAttribute("StationId", stationId)
	s:SetAttribute("Index", i)
	local exit = Instance.new("Attachment")
	exit.Name = "Exit"
	exit.Position = Vector3.new(-4.5, 0, 2)
	exit.Parent = s
	return s
end

local function sign(parent, station, cf)
	local m = Instance.new("Model")
	m.Name = "Sign"
	m.Parent = parent
	local board = part({ Parent = m, Name = "Board", Size = Vector3.new(9, 4.6, 0.5), CFrame = cf * CFrame.new(0, 5.6, 0), Color = Palette.Carbon })
	part({ Parent = m, Name = "Trim", Size = Vector3.new(9.4, 5, 0.3), CFrame = cf * CFrame.new(0, 5.6, 0.15), Color = if station.MinSpeed > 0 then Palette.Gold else Palette.ElectricBlue })
	part({ Parent = m, Name = "Post", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = cf * CFrame.new(-3.4, 1.7, 0.2), Color = Palette.SpeedBlack })
	part({ Parent = m, Name = "Post", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = cf * CFrame.new(3.4, 1.7, 0.2), Color = Palette.SpeedBlack })
	surfaceText(board, Enum.NormalId.Front, {
		{ Text = string.upper(station.Name), Height = 0.36, Color = Palette.White },
		{ Text = ("+%d MPH / TAP"):format(station.Gain), Height = 0.24, Color = Palette.BrightBlue, Font = BODY },
		{ Text = if station.MinSpeed > 0 then ("NEEDS %d MPH"):format(station.MinSpeed) else "OPEN TO EVERYONE", Height = 0.2, Color = Palette.Gold, Font = BODY },
	}, { PPS = 26, MaxDistance = 120, Padding = 2 })
	return m
end

-- Sprint Lane: 3 painted lanes with starting blocks and cones (runners face +X)
local sprint = modelIn("SprintLane", training)
local spX0, spX1, spZ = -42, -12, 14
block(sprint, "Strip", Vector3.new(spX1 - spX0, 0.2, 12.4), Vector3.new((spX0 + spX1) / 2, 0.2, spZ + 4), W.TrackBlue)
for i = 0, 3 do
	block(sprint, "Line", Vector3.new(spX1 - spX0, 0.22, 0.25), Vector3.new((spX0 + spX1) / 2, 0.21, spZ - 2 + i * 4), W.LaneWhite)
end
block(sprint, "StartLine", Vector3.new(0.6, 0.23, 12), Vector3.new(spX0 + 3, 0.215, spZ + 4), Palette.Gold)
for i = 1, 3 do
	local z = spZ + (i - 1) * 4
	local cf = CFrame.lookAt(Vector3.new(spX0 + 6, 0.3, z), Vector3.new(spX0 + 20, 0.3, z))
	slot(sprint, "SprintLane", cf, i)
	-- starting block (the Blender block's rail runs along its Z: turn it to run along the lane)
	if not mesh("Starting_Block", sprint, CFrame.new(spX0 + 4.2, 0.3, z) * CFrame.Angles(0, math.pi / 2, 0), { Name = "Block" }) then
		part({ Class = "WedgePart", Parent = sprint, Name = "Block", Size = Vector3.new(1.6, 0.7, 1.2), CFrame = CFrame.new(spX0 + 4.2, 0.65, z) * CFrame.Angles(0, -math.pi / 2, 0), Color = Palette.SpeedBlack })
	end
	-- cones at the far end
	-- repeated props get a small random turn so no two look placed by a machine
	if not mesh("Cone", sprint, CFrame.new(spX1 - 1, 0.3, z) * CFrame.Angles(0, rng:NextNumber(-0.5, 0.5), 0)) then
		cyl(sprint, "ConeBase", 0.9, 0.2, Vector3.new(spX1 - 1, 0.4, z), Palette.SpeedBlack)
		cyl(sprint, "Cone", 0.55, 1.4, Vector3.new(spX1 - 1, 1.1, z), W.Cone)
		cyl(sprint, "ConeBand", 0.6, 0.3, Vector3.new(spX1 - 1, 1.2, z), Palette.White)
	end
end
-- runners face south, the start line is at the front of the bay
place(sprint, Vector3.new((spX0 + spX1) / 2, 0, spZ + 4), Vector3.new(-48, 0.32, 188), Vector3.zAxis) -- 0.32 = on top of the bay mat

-- Treadmills: 4 under a canopy, runners face -Z (towards the stands)
local tread = modelIn("Treadmill", training)
local trX0, trZ = -10, -6
for i = 1, 4 do
	local x = trX0 + (i - 1) * 6.5
	local m = Instance.new("Model")
	m.Name = "Treadmill" .. i
	m.Parent = tread
	local tm = meshTemplate("Treadmill")
	if tm then
		-- Blender deck runs y -3.5..3.5 with the console past -3.5; lifted 0.08 so the belt meets the slot
		mesh("Treadmill", m, CFrame.new(x, 0.08, trZ), { Offset = Vector3.new(0, 0, 3.5 - tm.Size.Z / 2) })
		-- glowing belt stripes and screen (Neon) laid just over the mesh's painted ones
		-- v2 mesh: belt recessed in the deck (top 0.83), screen recessed in the console (face at -3.0)
		block(m, "BeltStripe", Vector3.new(0.2, 0.03, 6.0), Vector3.new(x - 1.12, 0.08 + 0.85, trZ + 0.15), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
		block(m, "BeltStripe", Vector3.new(0.2, 0.03, 6.0), Vector3.new(x + 1.12, 0.08 + 0.85, trZ + 0.15), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
		block(m, "Screen", Vector3.new(2.1, 0.66, 0.04), Vector3.new(x, 0.08 + 4.77, trZ - 3.04), Palette.BrightBlue, { Material = Enum.Material.Neon, CanCollide = false })
	else
		block(m, "Deck", Vector3.new(3.6, 0.8, 7), Vector3.new(x, 0.55, trZ), Palette.Graphite)
		block(m, "Belt", Vector3.new(2.8, 0.82, 6.2), Vector3.new(x, 0.58, trZ), Palette.SpeedBlack)
		block(m, "BeltStripe", Vector3.new(0.25, 0.84, 6.2), Vector3.new(x - 1.1, 0.59, trZ), Palette.ElectricBlue, { Material = Enum.Material.Neon })
		block(m, "BeltStripe", Vector3.new(0.25, 0.84, 6.2), Vector3.new(x + 1.1, 0.59, trZ), Palette.ElectricBlue, { Material = Enum.Material.Neon })
		for side = -1, 1, 2 do
			block(m, "Upright", Vector3.new(0.35, 4, 0.35), Vector3.new(x + side * 1.6, 2.6, trZ - 3.2), W.Aluminium)
			block(m, "Rail", Vector3.new(0.3, 0.3, 3.2), Vector3.new(x + side * 1.6, 4.2, trZ - 1.8), W.Aluminium)
		end
		block(m, "Console", Vector3.new(3.4, 1.4, 0.6), Vector3.new(x, 4.6, trZ - 3.3), Palette.Carbon)
		block(m, "Screen", Vector3.new(2.2, 0.7, 0.62), Vector3.new(x, 4.7, trZ - 3.32), Palette.BrightBlue, { Material = Enum.Material.Neon })
	end
	local slotY = if meshTemplate("Treadmill") then 0.91 else 0.95 -- stand on the belt
	local cf = CFrame.lookAt(Vector3.new(x, slotY, trZ + 0.6), Vector3.new(x, slotY, trZ - 10))
	slot(m, "Treadmill", cf, i)
end
-- canopy
local cx = trX0 + 1.5 * 6.5
for _, px in { trX0 - 3.5, trX0 + 3 * 6.5 + 3.5 } do
	for _, pz in { trZ - 5, trZ + 5 } do
		block(tread, "CanopyPost", Vector3.new(0.6, 12, 0.6), Vector3.new(px, 6, pz), Palette.SpeedBlack)
	end
end
block(tread, "CanopyRoof", Vector3.new(3 * 6.5 + 9, 0.8, 12), Vector3.new(cx, 12.4, trZ), Palette.ElectricBlue)
block(tread, "CanopyTrim", Vector3.new(3 * 6.5 + 9.4, 0.4, 12.4), Vector3.new(cx, 11.9, trZ), Palette.Gold)
block(tread, "CanopyGlow", Vector3.new(3 * 6.5 + 8, 0.2, 10.8), Vector3.new(cx, 11.95, trZ), Palette.BrightBlue, { Material = Enum.Material.Neon })
-- runners face north, towards the plaza and the track
place(tread, Vector3.new(cx, 0, trZ), Vector3.new(0, 0.32, 184), Vector3.xAxis)

-- Stair Run: a wide flight of stairs to a platform, runners face up the stairs (-Z)
local stair = modelIn("StairRun", training)
local stX, stZ0, steps = 36, 12, 10
for i = 1, steps do
	local h = i * 0.8
	block(stair, "Step", Vector3.new(10, h, 2), Vector3.new(stX, h / 2, stZ0 - (i - 0.5) * 2), if i % 2 == 0 then W.Concrete else Color3.fromHex("#C3CAD5"))
	block(stair, "Nose", Vector3.new(10.02, 0.12, 0.3), Vector3.new(stX, h + 0.01, stZ0 - (i - 1) * 2 - 0.15), Palette.Gold, { CanCollide = false })
end
local topH = steps * 0.8
for side = -1, 1, 2 do
	local wall = part({ Class = "WedgePart", Parent = stair, Name = "SideWall", Size = Vector3.new(0.8, topH + 0.6, steps * 2), CFrame = CFrame.new(stX + side * 5.4, (topH + 0.6) / 2, stZ0 - steps) * CFrame.Angles(0, math.pi, 0), Color = Palette.ElectricBlue })
	block(stair, "SideCap", Vector3.new(0.9, topH + 0.6, 6), Vector3.new(stX + side * 5.4, (topH + 0.6) / 2, stZ0 - steps * 2 - 3), Palette.DeepBlue)
end
block(stair, "Platform", Vector3.new(12, topH, 6), Vector3.new(stX, topH / 2, stZ0 - steps * 2 - 3), W.Concrete)
for side = -1, 1, 2 do
	local rx = stX + side * 5.4
	local a = Vector3.new(rx, 3, stZ0)
	local b = Vector3.new(rx, topH + 3, stZ0 - steps * 2)
	part({ Parent = stair, Name = "Handrail", Size = Vector3.new(0.3, 0.3, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Color = Palette.ElectricBlue })
	for i = 0, 2 do
		local t = i / 2
		local p = a:Lerp(b, t)
		block(stair, "RailPost", Vector3.new(0.3, 3, 0.3), p - Vector3.new(0, 1.5, 0), W.Aluminium)
	end
end
for i = 1, 2 do
	local x = stX + (if i == 1 then -2.2 else 2.2)
	local stepI = 5
	local y = stepI * 0.8 + 0.1
	local cf = CFrame.lookAt(Vector3.new(x, y, stZ0 - (stepI - 0.5) * 2), Vector3.new(x, y, stZ0 - 30))
	slot(stair, "StairRun", cf, i)
end
flag(Vector3.new(stX + 5, topH, stZ0 - steps * 2 - 5), Palette.ElectricBlue, Palette.Gold, 6, stair)
-- the stairs climb south, away from the plaza
place(stair, Vector3.new(stX, 0, stZ0), Vector3.new(48, 0.32, 166), -Vector3.xAxis)
-- each bay's sign stands at its front-left corner, facing the plaza
for _, s in { { sprint, Stations[1], -48 }, { tread, Stations[2], 0 }, { stair, Stations[3], 48 } } do
	sign(s[1], s[2], CFrame.lookAt(Vector3.new(s[3] - 13, 0.3, YARD_Z0 + 8), Vector3.new(s[3] - 13, 0.3, YARD_Z0 - 40)))
end
-- the yard: light floor, a blue mat with white lines per bay, a fence round three sides
do
	local yard = modelIn("TrainingYard", ground)
	local yc = Vector3.new(0, 0, (YARD_Z0 + YARD_Z1) / 2)
	local yd = YARD_Z1 - YARD_Z0
	block(yard, "Floor", Vector3.new(YARD_W, 0.3, yd), yc + Vector3.new(0, 0.15, 0), DISTRICT.Training.Paving)
	block(yard, "FloorEdge", Vector3.new(YARD_W + 1.2, 0.26, yd + 1.2), yc + Vector3.new(0, 0.13, 0), Palette.Graphite)
	for _, bx in { -48, 0, 48 } do
		local mz, md = yc.Z + 1, yd - 8
		block(yard, "Mat", Vector3.new(42, 0.32, md), Vector3.new(bx, 0.16, mz), Palette.DeepBlue)
		for s = -1, 1, 2 do
			block(yard, "MatLine", Vector3.new(0.3, 0.34, md), Vector3.new(bx + s * 20.4, 0.17, mz), W.LaneWhite, { CanCollide = false })
			block(yard, "MatLine", Vector3.new(41, 0.34, 0.3), Vector3.new(bx, 0.17, mz + s * (md / 2 - 0.4)), W.LaneWhite, { CanCollide = false })
		end
	end
	local function fence(a, b)
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		local n = math.max(1, math.floor(len / 6 + 0.5))
		for i = 0, n do
			part({ Parent = yard, Name = "FencePost", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = cf * CFrame.new(0, 1.7, len / 2 - i * len / n), Color = Palette.Graphite })
		end
		for _, y in { 1.4, 2.9 } do
			part({ Parent = yard, Name = "FenceRail", Size = Vector3.new(0.3, 0.3, len), CFrame = cf * CFrame.new(0, y, 0), Color = Palette.ElectricBlue })
		end
	end
	local hx = YARD_W / 2
	fence(Vector3.new(-hx, 0, YARD_Z0), Vector3.new(-hx, 0, YARD_Z1))
	fence(Vector3.new(hx, 0, YARD_Z0), Vector3.new(hx, 0, YARD_Z1))
	fence(Vector3.new(-hx, 0, YARD_Z1), Vector3.new(hx, 0, YARD_Z1))
end


----------------------------------------------------------------------------
-- trees (round low-poly), hedges at the edges, street lamps with banners, benches
----------------------------------------------------------------------------
local function tree(pos, scale)
	if meshTemplate("Tree_Round_A") then
		local r = rng:NextNumber()
		local name = if r < 0.4 then "Tree_Round_A" elseif r < 0.8 then "Tree_Round_B" else "Tree_Pine"
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
	ball(m, "Crown3", 5 * scale, pos + Vector3.new(-2 * scale, 7.4 * scale, -1.6 * scale), leaf[rng:NextInteger(1, 3)], { CastShadow = false })
	return m
end
local treeSpots = {
	-- behind the stands
	{ -150, -96 }, { -122, -104 }, { -94, -98 }, { -66, -104 }, { -36, -99 }, { 36, -100 }, { 66, -104 }, { 94, -97 }, { 122, -104 }, { 150, -96 },
	-- either side of the track
	{ -164, -62 }, { -174, -24 }, { -160, 16 }, { -172, 52 }, { 164, -62 }, { 176, -22 }, { 160, 18 }, { 174, 50 },
	-- behind both rows of shops and round the fountain
	{ -84, 68 }, { -122, 66 }, { -84, 142 }, { -124, 144 }, { -48, 156 }, { -170, 82 }, { -172, 126 }, { -160, 152 },
	-- round the portal stage (beside and behind it, never in front)
	{ 184, 74 }, { 188, 104 }, { 184, 134 }, { 116, 64 }, { 116, 144 }, { 70, 68 }, { 70, 140 },
	-- the south fields beside the yard and the school
	{ -92, 162 }, { -96, 198 }, { -90, 234 }, { -128, 180 }, { -150, 214 }, { -140, 254 }, { -172, 186 },
	{ 92, 162 }, { 96, 198 }, { 90, 234 }, { 128, 176 }, { 152, 210 }, { 140, 254 }, { 172, 180 },
	{ -80, 266 }, { 80, 266 },
}
for _, s in treeSpots do
	tree(Vector3.new(s[1] + rng:NextNumber(-3, 3), 0, s[2] + rng:NextNumber(-3, 3)), rng:NextNumber(0.9, 1.3))
end
-- hedges: the edges of the hub show why they end
local hedgeC = W.TreeLeafDark
block(props, "Hedge", Vector3.new(4, 4, 404), Vector3.new(-196, 2, 84), hedgeC)
block(props, "Hedge", Vector3.new(4, 4, 404), Vector3.new(196, 2, 84), hedgeC)
block(props, "Hedge", Vector3.new(396, 4, 4), Vector3.new(0, 2, -116), hedgeC)
block(props, "Hedge", Vector3.new(396, 4, 4), Vector3.new(0, 2, 284), hedgeC)
-- street lamps along the avenues (Neon heads, no real lights) with a banner in the district colour
local function lamp(pos, look, bannerColor)
	local cf = CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)) -- the head reaches over the street
	local lt = meshTemplate("Lamp_Post")
	if lt then
		mesh("Lamp_Post", props, cf, { Offset = Vector3.new(0, 0, 0.6 - lt.Size.Z / 2) })
		-- glow panel inside the recess under the v2 head
		part({ Parent = props, Name = "LampGlow", Size = Vector3.new(0.84, 0.04, 1.26), CFrame = cf * CFrame.new(0, 8.53, -1.65), Color = W.WindowLit, Material = Enum.Material.Neon, CanCollide = false })
	else
		part({ Parent = props, Name = "LampPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(9, 0.6, 0.6), CFrame = cf * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Palette.SpeedBlack })
		part({ Parent = props, Name = "LampHead", Size = Vector3.new(1.2, 0.5, 2.2), CFrame = cf * CFrame.new(0, 8.8, -1), Color = Palette.SpeedBlack })
		part({ Parent = props, Name = "LampGlow", Size = Vector3.new(1, 0.15, 1.4), CFrame = cf * CFrame.new(0, 8.5, -1.4), Color = W.WindowLit, Material = Enum.Material.Neon, CanCollide = false })
	end
	if bannerColor then
		part({ Parent = props, Name = "BannerArm", Size = Vector3.new(0.15, 0.15, 1.8), CFrame = cf * CFrame.new(0, 7.0, -0.9), Color = Palette.Graphite, CanCollide = false })
		part({ Parent = props, Name = "Banner", Size = Vector3.new(0.1, 2.8, 1.3), CFrame = cf * CFrame.new(0, 5.5, -1.1), Color = bannerColor, CanCollide = false })
		part({ Parent = props, Name = "BannerTip", Size = Vector3.new(0.11, 0.5, 1.3), CFrame = cf * CFrame.new(0, 3.85, -1.1), Color = Palette.SpeedBlack, CanCollide = false })
	end
end
for _, x in { -46, -88, -124 } do
	for side = -1, 1, 2 do
		lamp(Vector3.new(x, 0.25, PLAZA.Z + side * 12.6), Vector3.new(x, 0, PLAZA.Z), Palette.Gold)
	end
end
for _, x in { 44, 62, 80, 98 } do
	for side = -1, 1, 2 do
		lamp(Vector3.new(x, 0.25, PLAZA.Z + side * 12.6), Vector3.new(x, 0, PLAZA.Z), Palette.BrightBlue)
	end
end
-- benches (local -Z = the way you face when you sit)
local function bench(cf, parent)
	if mesh("Bench", parent or props, cf, { Offset = Vector3.new(0, 0, 0.05) }) then
		return
	end
	local m = Instance.new("Model")
	m.Name = "Bench"
	m.Parent = parent or props
	part({ Parent = m, Name = "Seat", Size = Vector3.new(6, 0.4, 1.6), CFrame = cf * CFrame.new(0, 1.6, 0), Color = W.Wood })
	part({ Parent = m, Name = "Back", Size = Vector3.new(6, 1.2, 0.3), CFrame = cf * CFrame.new(0, 2.6, 0.75) * CFrame.Angles(math.rad(-10), 0, 0), Color = W.Wood })
	for s = -1, 1, 2 do
		part({ Parent = m, Name = "Leg", Size = Vector3.new(0.3, 1.6, 1.6), CFrame = cf * CFrame.new(s * 2.6, 0.8, 0), Color = Palette.SpeedBlack })
	end
end
-- benches by the track to watch the races from
for _, x in { -40, -26, 26, 40 } do
	bench(CFrame.lookAt(Vector3.new(x, 0, 66), Vector3.new(x, 0, 0)))
end

----------------------------------------------------------------------------
-- SHOP STREET (west of the plaza): Shoe Shop + Trail Booth on the north side, Coach Corner + Locker
-- Room on the south side. Each is built facing +X where it used to stand, then placed on the street.
----------------------------------------------------------------------------
local Coaches = require(ReplicatedStorage.Shared.Config.Coaches:Clone())
local shops = folder("Shops")

local function prompt(parent, opens, action, object, pos)
	local anchor = block(parent, "PromptSpot", Vector3.new(1, 1, 1), pos, Palette.Gold, { Transparency = 1, CanCollide = false })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Opens", opens)
	pp.Parent = anchor
	return pp
end

local function signBoard(parent, name, size, cf, lines, trim)
	local board = part({ Parent = parent, Name = name, Size = size, CFrame = cf, Color = Palette.SpeedBlack })
	-- the board faces +X (towards the track); trim sits behind it, glow strip along the bottom front
	part({ Parent = parent, Name = name .. "Trim", Size = size + Vector3.new(0.1, 0.4, 0.4), CFrame = cf * CFrame.new(-0.2, 0, 0), Color = trim or Palette.Gold })
	part({ Parent = parent, Name = name .. "Glow", Size = Vector3.new(0.1, 0.18, size.Z + 0.2), CFrame = cf * CFrame.new(size.X / 2 + 0.05, -size.Y / 2 + 0.2, 0), Color = Palette.BrightBlue, Material = Enum.Material.Neon, CanCollide = false })
	surfaceText(board, Enum.NormalId.Right, lines, { PPS = 20, Brightness = 2, MaxDistance = 220, Padding = 0 })
	return board
end

-- Shoe Shop: open-front sports store, six turning pedestals inside
do
	local m = modelIn("ShoeShop", shops)
	local x0, zc = -126, -38
	block(m, "Floor", Vector3.new(16.4, 0.4, 24.4), Vector3.new(x0, 0.2, zc), Palette.Graphite)
	block(m, "FloorTrim", Vector3.new(0.3, 0.45, 24.4), Vector3.new(x0 + 8.1, 0.22, zc), Palette.Gold)
	local shell = meshTemplate("ShoeShop_Shell")
	if shell then
		-- the imported shell came in turned round (open side at its -X): turn it back so it opens to the front
		mesh("ShoeShop_Shell", m, CFrame.new(x0, 0, zc) * CFrame.Angles(0, math.pi, 0), { Offset = Vector3.new(8 - shell.Size.X / 2, 0, 0) })
	end
	if not shell then
	block(m, "BackWall", Vector3.new(1, 12, 24), Vector3.new(x0 - 7.5, 6, zc), Palette.Carbon)
	block(m, "BackPanel", Vector3.new(0.3, 7, 21), Vector3.new(x0 - 6.9, 5.2, zc), Palette.DeepBlue)
	for i = 0, 2 do
		block(m, "Shelf", Vector3.new(1.2, 0.25, 20), Vector3.new(x0 - 6.4, 3 + i * 2.2, zc), W.Aluminium)
	end
	for _, side in { -1, 1 } do
		block(m, "SideWall", Vector3.new(16, 12, 1), Vector3.new(x0, 6, zc + side * 11.5), Palette.Carbon)
		block(m, "SideStripe", Vector3.new(16.1, 0.5, 1.05), Vector3.new(x0, 9.5, zc + side * 11.5), Palette.ElectricBlue)
		block(m, "Pillar", Vector3.new(1.4, 12.4, 1.4), Vector3.new(x0 + 7.6, 6.2, zc + side * 11.5), Palette.SpeedBlack)
	end
	block(m, "Roof", Vector3.new(17, 1, 25), Vector3.new(x0, 12.5, zc), Palette.SpeedBlack)
	block(m, "RoofGold", Vector3.new(17.2, 0.35, 25.2), Vector3.new(x0, 12.05, zc), Palette.Gold)
	-- striped awning over the open front
	for i = 0, 7 do
		local z = zc - 10.5 + i * 3
		part({ Class = "WedgePart", Parent = m, Name = "Awning", Size = Vector3.new(3, 1.4, 4), CFrame = CFrame.new(x0 + 10, 10.6, z) * CFrame.Angles(0, math.pi / 2, 0), Color = if i % 2 == 0 then Palette.ElectricBlue else Palette.White })
	end
	end -- part build
	signBoard(m, "Sign", Vector3.new(0.6, 3, 16), CFrame.new(x0 + 8.6, 14.6, zc), {
		{ Text = "SHOE SHOP", Height = 0.62, Color = Palette.Gold },
		{ Text = "RUN FASTER IN BETTER SHOES", Height = 0.25, Color = Palette.White, Font = BODY },
	})
	-- pedestals (the client puts a turning shoe on each, dark if it's still locked)
	local ped = folder("ShoePedestals", m)
	for i = 1, 6 do
		local z = zc - 8 + (i - 1) * 3.2
		cyl(m, "PedestalBase", 1.15, 0.3, Vector3.new(x0 - 2, 0.55, z), Palette.SpeedBlack)
		local top = cyl(ped, "Pedestal" .. i, 0.9, 2.2, Vector3.new(x0 - 2, 1.8, z), W.Aluminium)
		top:SetAttribute("ShoeIndex", i)
		cyl(m, "PedestalRing", 0.95, 0.15, Vector3.new(x0 - 2, 2.88, z), Palette.Gold)
		local tag = block(m, "Tag" .. i, Vector3.new(0.2, 0.7, 2.6), Vector3.new(x0 - 0.9, 1.2, z), Palette.SpeedBlack)
		tag.CFrame = tag.CFrame * CFrame.Angles(0, 0, math.rad(-20))
		local g = surfaceText(tag, Enum.NormalId.Right, { { Name = "Label", Text = "SHOES", Height = 0.8, Color = Palette.White, Font = BODY } }, { PPS = 40, MaxDistance = 60 })
		local ref = Instance.new("ObjectValue") -- the client writes the pair's name / unlock here
		ref.Name = "LabelRef"
		ref.Value = g:FindFirstChild("Label")
		ref.Parent = top
	end
	prompt(m, "ShoeShop", "SHOP", "Shoe Shop", Vector3.new(x0 + 6, 3, zc))
	place(m, Vector3.new(x0 + 8, 0, zc), Vector3.new(-62, 0, PLAZA.Z - 12.5), Vector3.zAxis)
end

-- Trail Booth: a neon carnival stand with a demo trail looping behind a glass-look panel
do
	local m = modelIn("TrailBooth", shops)
	local x0, zc = -128, 4
	block(m, "Base", Vector3.new(10, 0.5, 14), Vector3.new(x0, 0.25, zc), Palette.Graphite)
	local shell = meshTemplate("TrailBooth_Shell")
	if shell then
		mesh("TrailBooth_Shell", m, CFrame.new(x0, 0, zc) * CFrame.Angles(0, math.pi, 0), { Offset = Vector3.new(5.0 - shell.Size.X / 2, 0, 0) }) -- turned round too
	end
	if not shell then
	block(m, "Counter", Vector3.new(2.2, 3.4, 12), Vector3.new(x0 + 3.6, 2.2, zc), Palette.Carbon)
	block(m, "CounterTop", Vector3.new(2.6, 0.3, 12.4), Vector3.new(x0 + 3.6, 4.05, zc), Palette.Gold)
	block(m, "Back", Vector3.new(0.8, 9, 14), Vector3.new(x0 - 4.6, 4.5, zc), Palette.SpeedBlack)
	end -- part build (counter + back)
	block(m, "CounterGlow", Vector3.new(0.12, 0.25, 12), Vector3.new(x0 + 4.75, 3.7, zc), Palette.BrightBlue, { Material = Enum.Material.Neon, CanCollide = false })
	block(m, "DemoPanel", Vector3.new(0.2, 5.5, 10), Vector3.new(x0 - 4, 5, zc), W.Window, { Transparency = 0.55, CanCollide = false })
	for _, side in { -1, 1 } do
		if not shell then
			block(m, "Post", Vector3.new(0.8, 10, 0.8), Vector3.new(x0 + 4.4, 5, zc + side * 6.6), Palette.SpeedBlack)
		end
		block(m, "PostNeon", Vector3.new(0.15, 9.6, 0.15), Vector3.new(x0 + 4.85, 5, zc + side * 6.6), Palette.Gold, { Material = Enum.Material.Neon, CanCollide = false })
	end
	block(m, "TopNeon", Vector3.new(0.15, 0.15, 13.4), Vector3.new(x0 + 4.85, 9.9, zc), Palette.Gold, { Material = Enum.Material.Neon, CanCollide = false })
	for i = 0, if shell then -1 else 6 do
		part({ Class = "WedgePart", Parent = m, Name = "Canopy", Size = Vector3.new(2, 1.6, 10), CFrame = CFrame.new(x0, 10.8, zc - 6 + i * 2) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 0, 0), Color = if i % 2 == 0 then Palette.Gold else Palette.SpeedBlack })
	end
	signBoard(m, "Sign", Vector3.new(0.6, 2.6, 12), CFrame.new(x0 + 5.2, 12.8, zc), {
		{ Text = "TRAIL BOOTH", Height = 0.6, Color = Palette.BrightBlue },
		{ Text = "LEAVE A STREAK BEHIND YOU", Height = 0.25, Color = Palette.White, Font = BODY },
	}, Palette.ElectricBlue)
	-- the demo runner the client moves in a loop (a Trail between two attachments)
	local demo = block(m, "Demo", Vector3.new(0.4, 0.4, 0.4), Vector3.new(x0 - 3.2, 5, zc), Palette.Gold, { Transparency = 1, CanCollide = false })
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
	tr.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromHex("#FFE38C")), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FF7A1F")), ColorSequenceKeypoint.new(1, Color3.fromHex("#4FC3FF")) })
	tr.Transparency = NumberSequence.new(0, 1)
	tr.Parent = demo
	prompt(m, "TrailBooth", "SHOP", "Trail Booth", Vector3.new(x0 + 6, 3, zc))
	place(m, Vector3.new(x0 + 5, 0, zc), Vector3.new(-100, 0, PLAZA.Z - 12.5), Vector3.zAxis)
end

-- Coach Corner: bench, whiteboard with the coach cards, stopwatch, whistle on a hook, COACHES sign
do
	local m = modelIn("CoachCorner", shops)
	local x0, zc = -126, 44
	block(m, "Pad", Vector3.new(16, 0.3, 18), Vector3.new(x0, 0.15, zc), Color3.fromHex("#9DA6B5"))
	bench(CFrame.new(x0 + 2, 0.3, zc + 4) * CFrame.Angles(0, math.pi / 2, 0), m)
	-- whiteboard on legs, facing the track
	local board = block(m, "Whiteboard", Vector3.new(0.3, 5, 9), Vector3.new(x0 - 4, 5.2, zc - 2), Palette.White)
	if not mesh("CoachBoard", m, CFrame.new(x0 - 4.06, 0, zc - 2)) then
		block(m, "BoardFrame", Vector3.new(0.35, 5.4, 9.4), Vector3.new(x0 - 4.05, 5.2, zc - 2), W.Aluminium)
		for _, s in { -1, 1 } do
			block(m, "BoardLeg", Vector3.new(0.3, 7.6, 0.3), Vector3.new(x0 - 4.1, 3.8, zc - 2 + s * 4.3), W.Aluminium)
		end
	end
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Right
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
	-- table with a stopwatch, a post with the whistle on a hook
	block(m, "Table", Vector3.new(2.4, 0.25, 3), Vector3.new(x0 + 1, 2.6, zc - 6), W.Wood)
	block(m, "TableLeg", Vector3.new(0.3, 2.5, 0.3), Vector3.new(x0 + 1, 1.3, zc - 6), Palette.SpeedBlack)
	local sw = cyl(m, "Stopwatch", 0.55, 0.22, Vector3.new(x0 + 1, 2.85, zc - 6), Palette.Gold)
	sw.CFrame = CFrame.new(x0 + 1, 3.1, zc - 6) * CFrame.Angles(0, 0, math.rad(70))
	cyl(m, "StopwatchFace", 0.42, 0.24, Vector3.new(x0 + 1.05, 3.12, zc - 6), Palette.White).CFrame = CFrame.new(x0 + 1.06, 3.12, zc - 6) * CFrame.Angles(0, 0, math.rad(70))
	block(m, "HookPost", Vector3.new(0.35, 6, 0.35), Vector3.new(x0 - 1.5, 3, zc + 9), Palette.SpeedBlack)
	block(m, "Hook", Vector3.new(0.8, 0.12, 0.12), Vector3.new(x0 - 1.1, 5.6, zc + 9), W.Aluminium)
	block(m, "Lanyard", Vector3.new(0.06, 1.2, 0.5), Vector3.new(x0 - 0.75, 5, zc + 9), Palette.ElectricBlue, { CanCollide = false })
	block(m, "Whistle", Vector3.new(0.3, 0.25, 0.45), Vector3.new(x0 - 0.75, 4.35, zc + 9), Palette.Gold, { CanCollide = false })
	-- big sign on two posts
	for _, s in { -1, 1 } do
		block(m, "SignPost", Vector3.new(0.5, 11, 0.5), Vector3.new(x0 - 6, 5.5, zc - 2 + s * 5), Palette.SpeedBlack)
	end
	signBoard(m, "Sign", Vector3.new(0.6, 3, 11), CFrame.new(x0 - 6, 11.4, zc - 2), {
		{ Text = "COACHES", Height = 0.62, Color = Palette.Gold },
		{ Text = "ROLL A COACH  -  THEY FOLLOW YOU", Height = 0.25, Color = Palette.White, Font = BODY },
	})
	prompt(m, "CoachCorner", "ROLL", "Coach Corner", Vector3.new(x0 + 2, 3, zc - 2))
	place(m, Vector3.new(x0 + 8, 0, zc), Vector3.new(-62, 0, PLAZA.Z + 12.5), -Vector3.zAxis)
end

-- Locker Room: open-front changing room, a row of lockers, a bench and two kit stands (opens KITS)
do
	local m = modelIn("LockerRoom", shops)
	local x0, zc = 0, 0
	block(m, "Floor", Vector3.new(16.4, 0.4, 20.4), Vector3.new(x0, 0.2, zc), Palette.Graphite)
	block(m, "FloorTrim", Vector3.new(0.3, 0.45, 20.4), Vector3.new(x0 + 8.1, 0.22, zc), Palette.Gold)
	block(m, "BackWall", Vector3.new(1, 12, 20), Vector3.new(x0 - 7.5, 6, zc), Palette.Carbon)
	for _, side in { -1, 1 } do
		block(m, "SideWall", Vector3.new(16, 12, 1), Vector3.new(x0, 6, zc + side * 9.5), Palette.Carbon)
		block(m, "SideStripe", Vector3.new(16.1, 0.5, 1.05), Vector3.new(x0, 9.5, zc + side * 9.5), Palette.ElectricBlue)
		block(m, "Pillar", Vector3.new(1.4, 12.4, 1.4), Vector3.new(x0 + 7.6, 6.2, zc + side * 9.5), Palette.SpeedBlack)
	end
	block(m, "Roof", Vector3.new(17, 1, 21), Vector3.new(x0, 12.5, zc), Palette.SpeedBlack)
	block(m, "RoofGold", Vector3.new(17.2, 0.35, 21.2), Vector3.new(x0, 12.05, zc), Palette.Gold)
	block(m, "CeilingGlow", Vector3.new(10, 0.15, 14), Vector3.new(x0, 11.95, zc), Palette.BrightBlue, { Material = Enum.Material.Neon, CanCollide = false })
	-- six lockers: inset doors, vent slots, a gold handle and number each
	for k = 1, 6 do
		local z = zc - 7.5 + (k - 1) * 3
		block(m, "Locker", Vector3.new(1.8, 8.4, 2.9), Vector3.new(x0 - 6.1, 4.6, z), Palette.DeepBlue)
		block(m, "LockerDoor", Vector3.new(0.12, 7.6, 2.5), Vector3.new(x0 - 5.16, 4.7, z), Palette.ElectricBlue)
		for v = 0, 2 do
			block(m, "Vent", Vector3.new(0.14, 0.14, 1.6), Vector3.new(x0 - 5.08, 7.6 - v * 0.4, z), Palette.DeepBlue, { CanCollide = false })
		end
		block(m, "Handle", Vector3.new(0.2, 0.9, 0.2), Vector3.new(x0 - 5.02, 4.6, z + 0.9), Palette.Gold, { CanCollide = false })
		local plate = block(m, "Number", Vector3.new(0.1, 0.7, 0.9), Vector3.new(x0 - 5.05, 6.4, z), Palette.White, { CanCollide = false })
		surfaceText(plate, Enum.NormalId.Right, { { Text = tostring(k), Height = 0.9, Color = Palette.DeepBlue } }, { PPS = 40, MaxDistance = 60, Padding = 0 })
	end
	block(m, "LockerTop", Vector3.new(2.1, 0.3, 18.2), Vector3.new(x0 - 6.1, 8.95, zc), Palette.Gold)
	bench(CFrame.new(x0 - 1.5, 0.4, zc) * CFrame.Angles(0, -math.pi / 2, 0), m)
	-- two kit stands at the front: a Blue Singlet and a VIP kit
	for i, kit in { { Palette.ElectricBlue, Palette.DeepBlue, -6 }, { Palette.Gold, Palette.SpeedBlack, 6 } } do
		local z = zc + kit[3]
		cyl(m, "StandBase", 1.1, 0.3, Vector3.new(x0 + 5, 0.55, z), Palette.SpeedBlack)
		cyl(m, "StandPole", 0.12, 3.2, Vector3.new(x0 + 5, 2.2, z), W.Aluminium)
		block(m, "StandTop", Vector3.new(1.1, 2.2, 2.2), Vector3.new(x0 + 5, 4.9, z), kit[1])
		block(m, "StandStripe", Vector3.new(1.12, 0.35, 2.22), Vector3.new(x0 + 5, 4.9, z), Palette.White)
		block(m, "StandShorts", Vector3.new(1.0, 1.0, 2.1), Vector3.new(x0 + 5, 3.3, z), kit[2])
		ball(m, "StandHead", 1.1, Vector3.new(x0 + 5, 6.6, z), W.Aluminium)
	end
	signBoard(m, "Sign", Vector3.new(0.6, 3, 15), CFrame.new(x0 + 8.6, 14.6, zc), {
		{ Text = "LOCKER ROOM", Height = 0.62, Color = Palette.Gold },
		{ Text = "KITS, HATS AND NAME STYLES", Height = 0.25, Color = Palette.White, Font = BODY },
	})
	prompt(m, "Locker", "OPEN", "Locker Room", Vector3.new(x0 + 6, 3, zc))
	place(m, Vector3.new(x0 + 8, 0, zc), Vector3.new(-100, 0, PLAZA.Z + 12.5), -Vector3.zAxis)
end


----------------------------------------------------------------------------
-- Portal stage at the end of the PORTALS avenue (east): 5 league gates in a shallow arc that faces
-- the plaza, nothing in front of them, a light beam over each so you can find them from anywhere.
-- Unlocked gates teleport (AreaService), locked ones go dark on the client with their requirement;
-- 4-5 are COMING SOON (NOTIFY ME).
----------------------------------------------------------------------------
do
	local plaza = folder("PortalPlaza")
	local pc = STAGE
	local top = 1.1
	cyl(plaza, "Step", STAGE_R + 2, 0.5, pc + Vector3.new(0, 0.25, 0), Palette.Graphite)
	cyl(plaza, "Platform", STAGE_R, top, pc + Vector3.new(0, top / 2, 0), DISTRICT.Portals.Paving)
	cyl(plaza, "PlatformGlow", STAGE_R + 0.15, 0.2, pc + Vector3.new(0, top - 0.2, 0), Palette.BrightBlue, { Material = Enum.Material.Neon, CanCollide = false })
	cyl(plaza, "Ring", 12, top + 0.06, pc + Vector3.new(0, (top + 0.06) / 2, 0), Palette.Gold)
	cyl(plaza, "RingInner", 11, top + 0.08, pc + Vector3.new(0, (top + 0.08) / 2, 0), Palette.DeepBlue)
	local gates = {
		{ "HOMETOWN TRACK", "LEAGUE 1  -  THIS TRACK", Palette.ElectricBlue, nil, false },
		{ "CITY PARK RUN", "LEAGUE 2", Palette.BrightBlue, "Park", false },
		{ "BIG STADIUM", "LEAGUE 3", Color3.fromHex("#C9D8FF"), "Stadium", false },
		{ "MOUNTAIN TRAIL", "COMING SOON", Color3.fromHex("#3F8F55"), "Soon", true },
		{ "WORLD GAMES", "COMING SOON", Palette.Gold, "Soon", true },
	}
	local arcC = pc - Vector3.new(16, 0, 0) -- the gates face this point (towards the avenue)
	for i, g in gates do
		local a = math.rad(-50 + (i - 1) * 25)
		local pos = arcC + Vector3.new(math.cos(a) * 40, top, math.sin(a) * 40)
		local cf = CFrame.lookAt(pos, Vector3.new(arcC.X, pos.Y, arcC.Z))
		local m = Instance.new("Model")
		m.Name = "Gate" .. i
		m:SetAttribute("League", i)
		m.Parent = plaza
		for _, s in { -1, 1 } do
			part({ Parent = m, Name = "Pillar", Size = Vector3.new(2.2, 17, 2.2), CFrame = cf * CFrame.new(s * 6.4, 8.5, 0), Color = Palette.SpeedBlack })
			part({ Parent = m, Name = "PillarFoot", Size = Vector3.new(3, 1, 3), CFrame = cf * CFrame.new(s * 6.4, 0.5, 0), Color = Palette.Graphite })
			part({ Parent = m, Name = "PillarGlow", Size = Vector3.new(0.3, 15.6, 0.3), CFrame = cf * CFrame.new(s * 5.25, 8.5, -0.9), Color = g[3], Material = Enum.Material.Neon, CanCollide = false })
		end
		part({ Parent = m, Name = "Beam", Size = Vector3.new(15.4, 2.6, 2.6), CFrame = cf * CFrame.new(0, 17.6, 0), Color = Palette.Carbon })
		part({ Parent = m, Name = "BeamGold", Size = Vector3.new(15.6, 0.4, 2.8), CFrame = cf * CFrame.new(0, 19.0, 0), Color = Palette.Gold })
		local portal = part({ Parent = m, Name = "Portal", Size = Vector3.new(10.4, 15.6, 0.2), CFrame = cf * CFrame.new(0, 8.2, 0), Color = g[3], Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false })
		portal:SetAttribute("Accent", g[3]:ToHex())
		-- the light beam into the sky (Neon, no real light): you can see where the portals are from the whole hub
		part({ Parent = m, Name = "Beacon", Size = Vector3.new(1.4, 80, 1.4), CFrame = cf * CFrame.new(0, 19.2 + 40, 0), Color = g[3], Material = Enum.Material.Neon, Transparency = 0.62, CanCollide = false, CanQuery = false })
		local board = part({ Parent = m, Name = "Board", Size = Vector3.new(13, 3.2, 0.4), CFrame = cf * CFrame.new(0, 17.6, -1.5), Color = Palette.SpeedBlack, CanCollide = false })
		surfaceText(board, Enum.NormalId.Front, {
			{ Name = "Title", Text = g[1], Height = 0.55, Color = Palette.White },
			{ Name = "Sub", Text = g[2], Height = 0.3, Color = Palette.Gold, Font = BODY },
		}, { PPS = 22, MaxDistance = 320, Padding = 0 })
		if g[4] then
			local trigger = part({ Parent = m, Name = "Trigger", Size = Vector3.new(10, 14, 2), CFrame = cf * CFrame.new(0, 7.5, 0), Transparency = 1, CanCollide = false })
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
	flag(Vector3.new(pc.X - STAGE_R + 3, top, pc.Z - 14), Palette.BrightBlue, Palette.Gold, 9)
	flag(Vector3.new(pc.X - STAGE_R + 3, top, pc.Z + 14), Palette.Gold, Palette.BrightBlue, 9)
end


----------------------------------------------------------------------------
-- M4 leaderboards: two walls on the south side of the plaza (either side of the Training Yard path),
-- facing the plaza. Filled by LeaderboardService (parts with a "Board" attribute, rows Row1..Row5)
----------------------------------------------------------------------------
do
	local wall = folder("LeaderboardWall")
	local boardsList = {
		{ "Speed", "TOP SPEED", Palette.Gold },
		{ "Wins", "MOST WINS", Palette.ElectricBlue },
		{ "WeeklyWins", "WINS THIS WEEK", Palette.Gold },
		{ "WeeklyTime", "FASTEST SPRINT THIS WEEK", Palette.BrightBlue },
	}
	local function boardWall(centre, list)
		local cf = CFrame.lookAt(centre, centre - Vector3.zAxis) -- faces north, towards the plaza
		part({ Parent = wall, Name = "Back", Size = Vector3.new(27, 12.4, 1.2), CFrame = cf * CFrame.new(0, 6.2, 0.9), Color = Palette.Carbon })
		part({ Parent = wall, Name = "Cap", Size = Vector3.new(28, 0.8, 2.4), CFrame = cf * CFrame.new(0, 12.8, 0.6), Color = Palette.Gold })
		part({ Parent = wall, Name = "Base", Size = Vector3.new(28, 1, 3), CFrame = cf * CFrame.new(0, 0.5, 0.4), Color = Palette.Graphite })
		local sign = part({ Parent = wall, Name = "Sign", Size = Vector3.new(17, 2.4, 0.5), CFrame = cf * CFrame.new(0, 14.4, 0.6), Color = Palette.SpeedBlack })
		surfaceText(sign, Enum.NormalId.Front, { { Text = "LEADERBOARDS", Height = 0.85, Color = Palette.Gold } }, { PPS = 20, MaxDistance = 220 })
		for i, b in list do
			local x = (i - 1.5) * 12.6
			local board = part({ Parent = wall, Name = "Board", Size = Vector3.new(11.6, 9, 0.4), CFrame = cf * CFrame.new(x, 6.6, 0), Color = Palette.SpeedBlack })
			board:SetAttribute("Board", b[1])
			part({ Parent = wall, Name = "Trim", Size = Vector3.new(12, 9.4, 0.3), CFrame = cf * CFrame.new(x, 6.6, 0.15), Color = b[3] })
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Front
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 24
			gui.MaxDistance = 110
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
				l.Text = r .. ".  -"
				l.TextColor3 = if r == 1 then Palette.Gold else Palette.White
				l.Parent = rows
			end
		end
	end
	boardWall(Vector3.new(-30, 0, 139), { boardsList[1], boardsList[2] })
	boardWall(Vector3.new(30, 0, 139), { boardsList[3], boardsList[4] })
end


----------------------------------------------------------------------------
-- look pass (28 Oct): real flowers in raised planters, wayfinding (district arches, a signpost and
-- floor labels on the plaza), the fountain at the end of Shop Street, grass patches, bushes along
-- the hedges. Seeded, so every rebuild looks the same.
----------------------------------------------------------------------------
do
	local dress = folder("Dressing")
	local rnd = Random.new(606)
	local greens = { Color3.fromHex("#66B356"), Color3.fromHex("#549C47"), Color3.fromHex("#6FBB5C"), Color3.fromHex("#4F9443") }
	local LIP = Color3.fromHex("#DDE2EA")
	local SOIL = Color3.fromHex("#5C4030")

	-- flowers: stem, two leaves and a bloom built from small parts, unioned once per kind and
	-- cloned, so each flower is one part (clones share the mesh)
	local PINK, ORANGE = Color3.fromHex("#FF8FB1"), Color3.fromHex("#FF9A3D")
	local stemC, leafC = Color3.fromHex("#3E8A3A"), Color3.fromHex("#58A84A")
	local function p(props)
		props.Parent = tmp
		return part(props)
	end
	local function stemAndLeaves(ps, h)
		table.insert(ps, p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.14, 0.14), CFrame = CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = stemC }))
		for s = -1, 1, 2 do
			table.insert(ps, p({ Size = Vector3.new(0.55, 0.07, 0.24), CFrame = CFrame.new(s * 0.24, h * 0.3 + (s + 1) * 0.1, 0) * CFrame.Angles(0, 0, s * math.rad(28)), Color = leafC }))
		end
	end
	local function daisy(petal, heart)
		local ps, h = {}, 1.5
		stemAndLeaves(ps, h)
		for i = 0, 6 do
			local a = i / 7 * math.pi * 2
			-- round petal discs around the heart, the outer edge tipped up
			table.insert(ps, p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.07, 0.42, 0.42), CFrame = CFrame.new(0, h, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0.27, 0, 0) * CFrame.Angles(0, 0, math.pi / 2 + math.rad(18)), Color = petal }))
		end
		table.insert(ps, p({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), CFrame = CFrame.new(0, h + 0.05, 0), Color = heart }))
		return ps
	end
	local function tulip(col)
		local ps, h = {}, 1.35
		stemAndLeaves(ps, h)
		table.insert(ps, p({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.46, 0.46, 0.46), CFrame = CFrame.new(0, h + 0.12, 0), Color = col }))
		for i = 0, 2 do
			local a = i / 3 * math.pi * 2
			-- three upright petals round the cup, leaning out a little at the top
			table.insert(ps, p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.06, 0.5, 0.5), CFrame = CFrame.new(0, h + 0.3, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0.17, 0, 0) * CFrame.Angles(0, 0, math.rad(-12)), Color = col:Lerp(Palette.White, 0.12) }))
		end
		return ps
	end
	local function spike(col)
		local ps, h = {}, 1.3
		stemAndLeaves(ps, h)
		for k = 0, 4 do
			local d = 0.42 - k * 0.05
			table.insert(ps, p({ Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = CFrame.new(0, h - 0.2 + k * 0.24, 0), Color = col:Lerp(Palette.White, k * 0.07) }))
		end
		return ps
	end
	local kinds = {
		DaisyWhite = daisy(Palette.White, Palette.Gold),
		DaisyGold = daisy(Palette.Gold, Palette.DeepGold),
		DaisyPink = daisy(PINK, Palette.Gold),
		TulipPink = tulip(PINK),
		TulipGold = tulip(Palette.Gold),
		TulipOrange = tulip(ORANGE),
		SpikeBlue = spike(Palette.BrightBlue),
		SpikeWhite = spike(Palette.White),
	}
	local flowerT = {}
	for kind, ps in kinds do
		local ok, res = pcall(function()
			return GeometryService:UnionAsync(ps[1], table.move(ps, 2, #ps, 1, {}), { CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false })
		end)
		for _, q in ps do
			q:Destroy()
		end
		if ok then
			local u = res[1]
			u.Name = "Flower"
			u.UsePartColor = false -- keep each piece's colour
			u.Anchored = true
			u.CanCollide = false
			u.CanQuery = false
			u.CanTouch = false
			u.CastShadow = false
			u.Parent = tmp
			flowerT[kind] = { u = u, cf = u.CFrame } -- the union keeps the stem's turn: place it with it
		else
			warn("flower union failed", kind, res)
		end
	end
	local function flower(parent, pos, kind, scale)
		local t = flowerT[kind]
		if not t then
			return
		end
		local f = t.u:Clone()
		f.Size = t.u.Size * scale
		f.CFrame = CFrame.new(pos) * CFrame.Angles(rnd:NextNumber(-0.12, 0.12), rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(-0.12, 0.12)) * CFrame.new(t.cf.Position * scale) * t.cf.Rotation
		f.Parent = parent
	end
	-- fill a bed: leafy mounds first, then flowers in drifts of one kind (not random confetti)
	local function fillBed(sample, area, topY, mix)
		for _ = 1, math.floor(area / 3) do
			local x, z = sample()
			local d = rnd:NextNumber(0.8, 1.3)
			ball(dress, "Leaves", d, Vector3.new(x, topY + d * 0.12, z), greens[rnd:NextInteger(1, #greens)], { CanCollide = false, CanQuery = false })
		end
		for _ = 1, math.floor(area * 0.55) do
			local x, z, u = sample()
			flower(dress, Vector3.new(x, topY, z), mix[math.clamp(math.floor(u * #mix) + 1, 1, #mix)], rnd:NextNumber(0.85, 1.2))
		end
	end
	local function planter(cf, sx, sz, mix)
		part({ Parent = dress, Name = "Planter", Size = Vector3.new(sx, 1.1, sz), CFrame = cf * CFrame.new(0, 0.55, 0), Color = W.Concrete })
		part({ Parent = dress, Name = "PlanterLip", Size = Vector3.new(sx + 0.3, 0.22, sz + 0.3), CFrame = cf * CFrame.new(0, 1.12, 0), Color = LIP })
		part({ Parent = dress, Name = "Soil", Size = Vector3.new(sx - 0.5, 0.1, sz - 0.5), CFrame = cf * CFrame.new(0, 1.22, 0), Color = SOIL, CanCollide = false })
		local ix, iz = sx / 2 - 0.6, sz / 2 - 0.6
		fillBed(function()
			local lx = rnd:NextNumber(-ix, ix)
			local w = cf * Vector3.new(lx, 0, rnd:NextNumber(-iz, iz))
			return w.X, w.Z, (lx + ix) / (2 * ix)
		end, sx * sz, cf.Position.Y + 1.27, mix)
	end
	local function roundPlanter(pos, r, mix, treeScale)
		cyl(dress, "Planter", r, 1.1, pos + Vector3.new(0, 0.55, 0), W.Concrete)
		cyl(dress, "PlanterLip", r + 0.18, 0.22, pos + Vector3.new(0, 1.12, 0), LIP)
		cyl(dress, "Soil", r - 0.25, 0.1, pos + Vector3.new(0, 1.22, 0), SOIL, { CanCollide = false })
		local inner = if treeScale then 1.2 else 0
		fillBed(function()
			local a = rnd:NextNumber(0, math.pi * 2)
			local d = math.sqrt(rnd:NextNumber((inner / (r - 0.5)) ^ 2, 1)) * (r - 0.5)
			return pos.X + math.cos(a) * d, pos.Z + math.sin(a) * d, a / (math.pi * 2)
		end, math.pi * r * r, pos.Y + 1.27, mix)
		if treeScale then
			tree(pos + Vector3.new(0, 1.2, 0), treeScale)
		end
	end

	-- the plaza: four round planters with a small tree on the diagonals, benches facing the middle
	local plazaY = PLAZA + Vector3.new(0, 0.38, 0)
	local plazaMixes = { { "DaisyWhite", "TulipPink" }, { "TulipGold", "SpikeBlue" }, { "DaisyPink", "SpikeWhite" }, { "TulipOrange", "DaisyWhite" } }
	for i, deg in { 45, 135, 225, 315 } do
		local a = math.rad(deg)
		roundPlanter(plazaY + Vector3.new(math.cos(a) * 21, 0, math.sin(a) * 21), 3.4, plazaMixes[i], 0.5)
		for _, da in { -16, 16 } do
			local b = math.rad(deg + da)
			local pos = plazaY + Vector3.new(math.cos(b) * 21.5, 0, math.sin(b) * 21.5)
			bench(CFrame.lookAt(pos, plazaY), dress)
		end
	end
	-- Shop Street planters between the shops, Portal avenue planters between the lamps
	for _, x in { -40, -81, -117 } do
		for side = -1, 1, 2 do
			planter(CFrame.new(x, 0, PLAZA.Z + side * 13.6), 8, 2.4, { "TulipGold", "DaisyWhite", "TulipPink" })
		end
	end
	for _, x in { 53, 89 } do
		for side = -1, 1, 2 do
			planter(CFrame.new(x, 0, PLAZA.Z + side * 13.6), 8, 2.4, { "SpikeBlue", "DaisyWhite", "SpikeWhite" })
		end
	end
	-- Training Yard: planters between the bays
	for _, x in { -24, 24 } do
		planter(CFrame.new(x, 0.3, YARD_Z0 + 16), 2.4, 20, { "SpikeBlue", "SpikeWhite" })
	end
	-- flower beds in the fields by the track (where the race benches are) and behind the shops
	for i, c in { Vector3.new(-33, 0, 74), Vector3.new(33, 0, 74), Vector3.new(-66, 0, 146), Vector3.new(62, 0, 150), Vector3.new(-150, 0, 70), Vector3.new(130, 0, 150) } do
		roundPlanter(c, rnd:NextNumber(2.6, 3.2), plazaMixes[(i - 1) % #plazaMixes + 1])
	end

	-- the fountain at the end of Shop Street
	do
		local F = Vector3.new(SHOP_END - 8, 0, PLAZA.Z)
		cyl(dress, "FountainPlazaEdge", 14.8, 0.32, F + Vector3.new(0, 0.16, 0), Palette.Graphite)
		cyl(dress, "FountainPlaza", 14, 0.34, F + Vector3.new(0, 0.17, 0), DISTRICT.Shops.Paving)
		cyl(dress, "BasinGold", 6.8, 0.36, F + Vector3.new(0, 0.18, 0), Palette.Gold)
		cyl(dress, "Basin", 6.4, 1.5, F + Vector3.new(0, 0.75, 0), W.Concrete)
		cyl(dress, "Water", 5.9, 0.12, F + Vector3.new(0, 1.5, 0), Palette.BrightBlue, { Transparency = 0.15, CanCollide = false })
		cyl(dress, "Column", 0.9, 3.4, F + Vector3.new(0, 3.2, 0), W.Concrete)
		cyl(dress, "Bowl", 2.6, 0.5, F + Vector3.new(0, 5.0, 0), LIP)
		cyl(dress, "BowlWater", 2.3, 0.1, F + Vector3.new(0, 5.26, 0), Palette.BrightBlue, { Transparency = 0.15, CanCollide = false })
		local jet = cyl(dress, "Jet", 0.22, 1.6, F + Vector3.new(0, 6.1, 0), Palette.White, { Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false })
		local at = Instance.new("Attachment")
		at.Position = Vector3.new(0.8, 0, 0) -- the jet's axis is its X (cylinder)
		at.Parent = jet
		local spray = Instance.new("ParticleEmitter")
		spray.Rate = 30
		spray.Lifetime = NumberRange.new(0.7, 1)
		spray.Speed = NumberRange.new(5, 7)
		spray.SpreadAngle = Vector2.new(28, 28)
		spray.EmissionDirection = Enum.NormalId.Right
		spray.Acceleration = Vector3.new(0, -26, 0)
		spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.05) })
		spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		spray.Color = ColorSequence.new(Color3.fromHex("#DFF4FF"))
		spray.LightEmission = 0.3
		spray.Parent = at
		for _, deg in { 45, 135, 225, 315 } do
			local a = math.rad(deg)
			local pos = F + Vector3.new(math.cos(a) * 10, 0.34, math.sin(a) * 10)
			bench(CFrame.lookAt(pos, F + Vector3.new(0, 0.34, 0)), dress)
		end
	end

	-- district arches at the plaza exits: the name faces you as you leave the plaza
	local function districtArch(pos, out, span, title, sub, accent)
		local cf = CFrame.lookAt(pos, pos + out)
		for _, s in { -1, 1 } do
			local x = s * (span / 2 + 1.2)
			part({ Parent = dress, Name = "ArchPillar", Size = Vector3.new(2.4, 14, 2.4), CFrame = cf * CFrame.new(x, 7, 0), Color = Palette.Carbon })
			part({ Parent = dress, Name = "ArchFoot", Size = Vector3.new(3.4, 1, 3.4), CFrame = cf * CFrame.new(x, 0.5, 0), Color = Palette.Graphite })
			part({ Parent = dress, Name = "ArchGlow", Size = Vector3.new(0.2, 12, 0.5), CFrame = cf * CFrame.new(x - s * 1.2, 7.4, 0), Color = accent, Material = Enum.Material.Neon, CanCollide = false })
		end
		local beam = part({ Parent = dress, Name = "ArchBeam", Size = Vector3.new(span + 6, 3.6, 1.8), CFrame = cf * CFrame.new(0, 15.2, 0), Color = Palette.SpeedBlack })
		part({ Parent = dress, Name = "ArchTrim", Size = Vector3.new(span + 6.4, 0.45, 2.2), CFrame = cf * CFrame.new(0, 17.2, 0), Color = Palette.Gold })
		part({ Parent = dress, Name = "ArchGlowBeam", Size = Vector3.new(span + 5.6, 0.25, 1.9), CFrame = cf * CFrame.new(0, 13.3, 0), Color = accent, Material = Enum.Material.Neon, CanCollide = false })
		surfaceText(beam, Enum.NormalId.Back, {
			{ Text = title, Height = 0.56, Color = accent },
			{ Text = sub, Height = 0.26, Color = Palette.White, Font = BODY },
		}, { PPS = 18, MaxDistance = 320, Padding = 0, Brightness = 1.6 })
		surfaceText(beam, Enum.NormalId.Front, {
			{ Text = "CENTRAL PLAZA", Height = 0.5, Color = Palette.White },
		}, { PPS = 18, MaxDistance = 200, Padding = 0 })
	end
	districtArch(PLAZA + Vector3.new(-31, 0, 0), -Vector3.xAxis, AVE_W + 2, "SHOP STREET", "SHOES  -  TRAILS  -  COACHES  -  KITS", Palette.Gold)
	districtArch(PLAZA + Vector3.new(31, 0, 0), Vector3.xAxis, AVE_W + 2, "PORTALS", "GO PRO TO OPEN NEW LEAGUES", Palette.BrightBlue)
	districtArch(PLAZA + Vector3.new(0, 0, 31), Vector3.zAxis, 22, "TRAINING YARD", "TAP TO GET FASTER", Palette.BrightBlue)

	-- the signpost by the spawn: one arrow board per district
	do
		local fp = PLAZA + Vector3.new(9, 0.38, 9)
		cyl(dress, "SignPole", 0.32, 13.4, fp + Vector3.new(0, 6.7, 0), Palette.Graphite)
		cyl(dress, "SignPoleFoot", 0.8, 0.6, fp + Vector3.new(0, 0.3, 0), Palette.SpeedBlack)
		ball(dress, "SignPoleTop", 0.9, fp + Vector3.new(0, 13.6, 0), Palette.Gold)
		for i, d in {
			{ -Vector3.zAxis, "RACE TRACK", Palette.White },
			{ Vector3.xAxis, "PORTALS", Palette.BrightBlue },
			{ -Vector3.xAxis, "SHOP STREET", Palette.Gold },
			{ Vector3.zAxis, "TRAINING", Palette.BrightBlue },
		} do
			local yaw = math.atan2(-d[1].Z, d[1].X)
			local cf = CFrame.new(fp + Vector3.new(0, 13 - i * 1.65, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.new(3.7, 0, 0)
			local board = part({ Parent = dress, Name = "SignArrow", Size = Vector3.new(6.6, 1.4, 0.3), CFrame = cf, Color = Palette.SpeedBlack })
			part({ Parent = dress, Name = "SignTip", Size = Vector3.new(0.99, 0.99, 0.3), CFrame = cf * CFrame.new(3.3, 0, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = d[3] })
			part({ Parent = dress, Name = "SignEdge", Size = Vector3.new(6.6, 0.14, 0.32), CFrame = cf * CFrame.new(0, -0.64, 0), Color = d[3] })
			-- the back face reads towards the tip, the front face away from it
			surfaceText(board, Enum.NormalId.Back, { { Text = d[2] .. "  >", Height = 0.8, Color = d[3] } }, { PPS = 30, MaxDistance = 140, Padding = 0 })
			surfaceText(board, Enum.NormalId.Front, { { Text = "<  " .. d[2], Height = 0.8, Color = d[3] } }, { PPS = 30, MaxDistance = 140, Padding = 0 })
		end
	end

	-- floor labels painted at the plaza exits (the text's top points the way you go)
	local function floorLabel(pos, out, text, color)
		local lbl = part({ Parent = dress, Name = "FloorLabel", Size = Vector3.new(3.2, 0.05, 12), CFrame = CFrame.fromMatrix(pos, -out, Vector3.yAxis), Color = Palette.White, Transparency = 1, CanCollide = false, CanQuery = false })
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Top
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 20
		g.MaxDistance = 120
		g.LightInfluence = 1
		g.Parent = lbl
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Text = text
		t.TextScaled = true
		t.FontFace = MONTSERRAT
		t.TextColor3 = color
		t.Parent = g
		return t
	end
	floorLabel(PLAZA + Vector3.new(-23, 0.4, 0), -Vector3.xAxis, "SHOPS", Palette.DeepGold)
	floorLabel(PLAZA + Vector3.new(23, 0.4, 0), Vector3.xAxis, "PORTALS", Palette.ElectricBlue)
	floorLabel(PLAZA + Vector3.new(0, 0.4, 23), Vector3.zAxis, "TRAINING", Palette.ElectricBlue)
	floorLabel(PLAZA + Vector3.new(0, 0.4, -23), -Vector3.zAxis, "RACES", Palette.DeepBlue)
	floorLabel(STAGE + Vector3.new(0, 1.2, 0), Vector3.xAxis, "PORTALS", Palette.White)

	-- grass colour patches on the open fields (clear of every district)
	local function onField(x, z)
		local trackArea = math.abs(x) < 112 and z > -86 and z < 62
		local plazaArea = (Vector3.new(x, 0, z) - PLAZA).Magnitude < 32
		local shopArea = x < -20 and x > -160 and math.abs(z - PLAZA.Z) < 32
		local portalArea = x > 20 and math.abs(z - PLAZA.Z) < 42
		local yardArea = math.abs(x) < 80 and z > 126 and z < 228
		local schoolArea = math.abs(x) < 70 and z > 226 and z < 264
		return not (trackArea or plazaArea or shopArea or portalArea or yardArea or schoolArea) and math.abs(x) < 188 and z > -108 and z < 276
	end
	local n = 0
	while n < 46 do
		local x, z = rnd:NextNumber(-188, 188), rnd:NextNumber(-108, 276)
		if onField(x, z) then
			n += 1
			local gp = block(dress, "GrassPatch", Vector3.new(rnd:NextNumber(5, 13), 0.04, rnd:NextNumber(4, 10)), Vector3.new(x, 0.1, z), greens[rnd:NextInteger(1, #greens)], { CanCollide = false })
			gp.CFrame = CFrame.new(x, 0.1, z) * CFrame.Angles(0, rnd:NextNumber(0, math.pi), 0)
		end
	end
	-- bushes along the hedges (small tree crowns)
	for i = 0, 12 do
		local z = -100 + i * 30
		for _, x in { -190, 190 } do
			tree(Vector3.new(x + rnd:NextNumber(-2, 2), 0, z + rnd:NextNumber(-4, 4)), rnd:NextNumber(0.42, 0.55))
		end
	end
	for i = 0, 12 do
		local x = -180 + i * 30
		for _, z in { -110, 278 } do
			tree(Vector3.new(x + rnd:NextNumber(-4, 4), 0, z + rnd:NextNumber(-2, 2)), rnd:NextNumber(0.42, 0.55))
		end
	end
end

----------------------------------------------------------------------------
-- finish
----------------------------------------------------------------------------
tmp:Destroy()
hub.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- the home area is always there
hub.Parent = workspace

-- lighting preset (the client applies the same values; this is for the edit view)
local L = require(ReplicatedStorage.Shared.Config.Lighting:Clone()).Hub
Lighting.ClockTime = L.ClockTime
Lighting.GeographicLatitude = L.GeographicLatitude
Lighting.Brightness = L.Brightness
Lighting.Ambient = L.Ambient
Lighting.OutdoorAmbient = L.OutdoorAmbient
Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale
Lighting.ExposureCompensation = L.ExposureCompensation
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
for k, v in L.ColorCorrection do
	cc[k] = v
end
local bl = ensure("BloomEffect", "AreaBloom")
for k, v in L.Bloom do
	bl[k] = v
end
local sr = ensure("SunRaysEffect", "AreaSunRays")
for k, v in L.SunRays do
	sr[k] = v
end
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "Atmosphere")
for k, v in L.Atmosphere do
	atmo[k] = v
end
for _, o in Lighting:GetChildren() do
	if (o:IsA("BloomEffect") and o ~= bl) or (o:IsA("ColorCorrectionEffect") and o ~= cc) or (o:IsA("SunRaysEffect") and o ~= sr) then
		o:Destroy()
	end
end
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = L.Clouds.Cover
clouds.Density = L.Clouds.Density
clouds.Color = L.Clouds.Color
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
