-- SPEED ARC: builds the Hub (Hometown Track) in Studio. Run in edit mode (MCP or command bar via sync).
-- Stylized low-poly look from smooth parts + CSG for the curved track. Hero props get replaced by
-- the Blender meshes (Downloads\speed_arc_models\hub\) once they are imported.
-- Re-running replaces workspace.Hub (the old one is moved to ServerStorage as a dated backup).
local GeometryService = game:GetService("GeometryService")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Race = require(ReplicatedStorage.Shared.Config.Race)
local Stations = require(ReplicatedStorage.Shared.Config.Stations)
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
-- ground: grass with mowing stripes, plaza, paths
----------------------------------------------------------------------------
block(ground, "Grass", Vector3.new(300, 4, 320), Vector3.new(0, -2, 10), W.Grass)
block(ground, "Outskirts", Vector3.new(1600, 4, 1600), Vector3.new(0, -2.25, 10), Color3.fromHex("#4E9446"))
-- low hills on the horizon (half buried balls) so the world never ends in empty sky
local hillCols = { Color3.fromHex("#5BA04F"), Color3.fromHex("#4A8C43"), Color3.fromHex("#6AAE57") }
for i = 0, 15 do
	local a = i / 16 * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
	local d = rng:NextNumber(420, 560)
	local size = rng:NextNumber(150, 260)
	ball(ground, "Hill", size, Vector3.new(math.cos(a) * d, -size * 0.32, 10 + math.sin(a) * d), hillCols[i % 3 + 1], { CanCollide = false, CanQuery = false })
end
for i = 0, 14 do
	local x = -140 + i * 20
	if i % 2 == 0 then
		block(ground, "Stripe", Vector3.new(10, 0.06, 300), Vector3.new(x + 5, 0.03, 0), W.GrassDark, { CanCollide = false })
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
-- plaza between school and track + path
block(ground, "Plaza", Vector3.new(96, 0.3, 46), Vector3.new(0, 0.15, 86), Color3.fromHex("#A9B1BF"))
for i = 1, 11 do
	block(ground, "PlazaJoint", Vector3.new(0.25, 0.32, 46), Vector3.new(-48 + i * 8, 0.16, 86), Color3.fromHex("#959DAB"), { CanCollide = false })
end
for i = 1, 5 do
	block(ground, "PlazaJoint", Vector3.new(96, 0.32, 0.25), Vector3.new(0, 0.16, 63 + i * 7.66), Color3.fromHex("#959DAB"), { CanCollide = false })
end
-- the SPEED ARC emblem painted in the plaza
cyl(ground, "EmblemGold", 10, 0.36, Vector3.new(0, 0.18, 84), Palette.Gold, { CanCollide = false })
cyl(ground, "Emblem", 9.2, 0.38, Vector3.new(0, 0.19, 84), Palette.DeepBlue, { CanCollide = false })
local emblemTop = block(ground, "EmblemText", Vector3.new(16, 0.05, 16), Vector3.new(0, 0.4, 84), Palette.DeepBlue, { Transparency = 1, CanCollide = false })
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
-- planters with flowers on both sides of the plaza
local FLOWERS = { Palette.Gold, Palette.White, Palette.BrightBlue, Color3.fromHex("#FF8FB1") }
for side = -1, 1, 2 do
	for j = 0, 1 do
		local px, pz = side * 34, 78 + j * 16
		block(ground, "Planter", Vector3.new(14, 1.6, 6), Vector3.new(px, 0.8, pz), Palette.Graphite)
		block(ground, "PlanterTrim", Vector3.new(14.4, 0.3, 6.4), Vector3.new(px, 1.65, pz), W.Concrete)
		block(ground, "Soil", Vector3.new(13, 0.2, 5), Vector3.new(px, 1.62, pz), W.GrassDark)
		for f = 1, 7 do
			ball(ground, "Flower", rng:NextNumber(0.8, 1.3), Vector3.new(px - 5.5 + f * 1.4 + rng:NextNumber(-0.3, 0.3), 2.1, pz + rng:NextNumber(-1.6, 1.6)), FLOWERS[rng:NextInteger(1, #FLOWERS)], { CanCollide = false })
		end
	end
end
block(ground, "PlazaEdge", Vector3.new(98, 0.22, 48), Vector3.new(0, 0.11, 86), Palette.Graphite)
block(ground, "Path", Vector3.new(14, 0.24, 10), Vector3.new(0, 0.12, 60), W.Path)

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
local function tower(z)
	block(arch, "Leg", Vector3.new(2.4, 18, 2.4), Vector3.new(T.StartX, 9, z), Palette.SpeedBlack)
	block(arch, "LegTrim", Vector3.new(2.6, 0.5, 2.6), Vector3.new(T.StartX, 6, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
	block(arch, "LegTrim", Vector3.new(2.6, 0.5, 2.6), Vector3.new(T.StartX, 12, z), Palette.ElectricBlue, { Material = Enum.Material.Neon })
	block(arch, "Foot", Vector3.new(4, 1, 4), Vector3.new(T.StartX, 0.5, z), Palette.Graphite)
end
tower(z1)
tower(z2)
local span = z2 - z1 + 2.4
block(arch, "Beam", Vector3.new(3, 4, span), Vector3.new(T.StartX, 19.5, (z1 + z2) / 2), Palette.SpeedBlack)
block(arch, "BeamGold", Vector3.new(3.2, 1, span + 0.2), Vector3.new(T.StartX, 21.7, (z1 + z2) / 2), Palette.Gold)
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
local function flag(base, color, accent, poleH)
	local m = Instance.new("Model")
	m.Name = "Flag"
	m.Parent = flagsF
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
local standLen = 110
for k = 1, rows do
	local h = 1 + 1.3 * k
	local z = sz0 - 1.5 - 3 * (k - 1)
	block(stands, "Step" .. k, Vector3.new(standLen, h, 3), Vector3.new(0, h / 2, z), if k % 2 == 0 then Palette.Graphite else Color3.fromHex("#323846"))
	block(stands, "Seat" .. k, Vector3.new(standLen - 2, 0.5, 1.3), Vector3.new(0, h + 0.25, z + 0.6), W.Aluminium)
	block(stands, "SeatEdge" .. k, Vector3.new(standLen - 2, 0.15, 0.2), Vector3.new(0, h + 0.4, z + 1.25), Palette.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
end
local backZ = sz0 - 3 * rows - 1
block(stands, "BackWall", Vector3.new(standLen + 2, 16, 2), Vector3.new(0, 8, backZ), Palette.Carbon)
block(stands, "BackTrim", Vector3.new(standLen + 2.4, 0.8, 2.4), Vector3.new(0, 16.2, backZ), Palette.Gold)
for side = -1, 1, 2 do
	local wedge = part({ Class = "WedgePart", Parent = stands, Name = "SideWall", Size = Vector3.new(1.5, 10, 3 * rows), CFrame = CFrame.new(side * (standLen / 2 + 0.75), 5, sz0 - 1.5 * rows) * CFrame.Angles(0, math.pi, 0), Color = Palette.Carbon })
	wedge.Size = Vector3.new(1.5, 1 + 1.3 * rows + 1, 3 * rows)
	wedge.CFrame = CFrame.new(side * (standLen / 2 + 0.75), wedge.Size.Y / 2, sz0 - 1.5 * rows) * CFrame.Angles(0, math.pi, 0)
end
-- front rail
block(stands, "Rail", Vector3.new(standLen, 0.3, 0.3), Vector3.new(0, 3.2, sz0 + 0.6), W.Aluminium)
for i = 0, 10 do
	block(stands, "RailPost", Vector3.new(0.3, 3.2, 0.3), Vector3.new(-standLen / 2 + 1 + i * (standLen - 2) / 10, 1.6, sz0 + 0.6), W.Aluminium)
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
		if rng:NextNumber() < 0.82 then
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
local sx0, sFront, sDepth, sW = 0, 112, 22, 124
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

-- spawn on the school steps
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 0.4, 6)
spawn.CFrame = CFrame.new(0, 0.5, sFront - 13) * CFrame.Angles(0, 0, 0)
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
-- training spots (infield): Sprint Lane, Treadmills, Stair Run
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
local sprint = folder("SprintLane", training)
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
	-- starting block
	part({ Class = "WedgePart", Parent = sprint, Name = "Block", Size = Vector3.new(1.6, 0.7, 1.2), CFrame = CFrame.new(spX0 + 4.2, 0.65, z) * CFrame.Angles(0, -math.pi / 2, 0), Color = Palette.SpeedBlack })
	-- cones at the far end
	cyl(sprint, "ConeBase", 0.9, 0.2, Vector3.new(spX1 - 1, 0.4, z), Palette.SpeedBlack)
	cyl(sprint, "Cone", 0.55, 1.4, Vector3.new(spX1 - 1, 1.1, z), W.Cone)
	cyl(sprint, "ConeBand", 0.6, 0.3, Vector3.new(spX1 - 1, 1.2, z), Palette.White)
end
sign(sprint, Stations[1], CFrame.lookAt(Vector3.new(spX0 + 12, 0, spZ + 12.5), Vector3.new(spX0 + 12, 0, spZ + 30)))

-- Treadmills: 4 under a canopy, runners face -Z (towards the stands)
local tread = folder("Treadmill", training)
local trX0, trZ = -10, -6
for i = 1, 4 do
	local x = trX0 + (i - 1) * 6.5
	local m = Instance.new("Model")
	m.Name = "Treadmill" .. i
	m.Parent = tread
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
	local cf = CFrame.lookAt(Vector3.new(x, 0.95, trZ + 0.6), Vector3.new(x, 0.95, trZ - 10))
	slot(m, "Treadmill", cf, i)
end
-- canopy
local cx = trX0 + 1.5 * 6.5
for _, px in { trX0 - 3.5, trX0 + 3 * 6.5 + 3.5 } do
	for _, pz in { trZ - 5, trZ + 5 } do
		block(tread, "CanopyPost", Vector3.new(0.6, 9, 0.6), Vector3.new(px, 4.5, pz), Palette.SpeedBlack)
	end
end
block(tread, "CanopyRoof", Vector3.new(3 * 6.5 + 9, 0.8, 12), Vector3.new(cx, 9.4, trZ), Palette.ElectricBlue)
block(tread, "CanopyTrim", Vector3.new(3 * 6.5 + 9.4, 0.4, 12.4), Vector3.new(cx, 8.9, trZ), Palette.Gold)
block(tread, "CanopyGlow", Vector3.new(3 * 6.5 + 8, 0.2, 10.8), Vector3.new(cx, 8.95, trZ), Palette.BrightBlue, { Material = Enum.Material.Neon })
sign(tread, Stations[2], CFrame.lookAt(Vector3.new(trX0 + 3 * 6.5 + 10, 0, trZ + 6), Vector3.new(trX0 + 3 * 6.5 + 14, 0, trZ + 30)))

-- Stair Run: a wide flight of stairs to a platform, runners face up the stairs (-Z)
local stair = folder("StairRun", training)
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
flag(Vector3.new(stX + 5, topH, stZ0 - steps * 2 - 5), Palette.ElectricBlue, Palette.Gold, 6)
sign(stair, Stations[3], CFrame.lookAt(Vector3.new(stX - 9, 0, stZ0 + 1), Vector3.new(stX - 9, 0, stZ0 + 30)))

----------------------------------------------------------------------------
-- trees (round low-poly), hedges at the edges, lamps, benches
----------------------------------------------------------------------------
local function tree(pos, scale)
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
	{ -130, -120 }, { -110, -132 }, { -80, -128 }, { 80, -126 }, { 108, -134 }, { 132, -118 },
	{ -134, -80 }, { -136, -40 }, { -132, 0 }, { -136, 40 }, { -130, 82 }, { -128, 120 },
	{ 134, -80 }, { 136, -38 }, { 132, 2 }, { 136, 42 }, { 130, 84 }, { 128, 122 },
	{ -78, 130 }, { 78, 130 }, { -96, 100 }, { 96, 100 }, { -60, -100 }, { 60, -100 },
}
for _, s in treeSpots do
	tree(Vector3.new(s[1] + rng:NextNumber(-3, 3), 0, s[2] + rng:NextNumber(-3, 3)), rng:NextNumber(0.85, 1.2))
end
-- hedges: the edges of the hub show why they end
local hedgeC = W.TreeLeafDark
block(props, "Hedge", Vector3.new(4, 4, 290), Vector3.new(-146, 2, 10), hedgeC)
block(props, "Hedge", Vector3.new(4, 4, 290), Vector3.new(146, 2, 10), hedgeC)
block(props, "Hedge", Vector3.new(296, 4, 4), Vector3.new(0, 2, -146), hedgeC)
block(props, "Hedge", Vector3.new(84, 4, 4), Vector3.new(-104, 2, 152), hedgeC)
block(props, "Hedge", Vector3.new(84, 4, 4), Vector3.new(104, 2, 152), hedgeC)
-- lamps along the plaza (Neon heads, no real lights)
for _, lx in { -44, -22, 22, 44 } do
	cyl(props, "LampPole", 0.3, 9, Vector3.new(lx, 4.5, 64), Palette.SpeedBlack)
	block(props, "LampArm", Vector3.new(0.3, 0.3, 2), Vector3.new(lx, 9, 63.2), Palette.SpeedBlack)
	block(props, "LampHead", Vector3.new(1.2, 0.5, 1.6), Vector3.new(lx, 8.8, 62.4), Palette.SpeedBlack)
	block(props, "LampGlow", Vector3.new(1, 0.15, 1.4), Vector3.new(lx, 8.5, 62.4), W.WindowLit, { Material = Enum.Material.Neon })
end
-- benches
local function bench(cf)
	local m = Instance.new("Model")
	m.Name = "Bench"
	m.Parent = props
	part({ Parent = m, Name = "Seat", Size = Vector3.new(6, 0.4, 1.6), CFrame = cf * CFrame.new(0, 1.6, 0), Color = W.Wood })
	part({ Parent = m, Name = "Back", Size = Vector3.new(6, 1.2, 0.3), CFrame = cf * CFrame.new(0, 2.6, 0.75) * CFrame.Angles(math.rad(-10), 0, 0), Color = W.Wood })
	for s = -1, 1, 2 do
		part({ Parent = m, Name = "Leg", Size = Vector3.new(0.3, 1.6, 1.6), CFrame = cf * CFrame.new(s * 2.6, 0.8, 0), Color = Palette.SpeedBlack })
	end
end
for _, bx in { -33, 33 } do
	bench(CFrame.new(bx, 0.3, 70) * CFrame.Angles(0, math.pi, 0))
end
bench(CFrame.new(-60, 0, -66) * CFrame.Angles(0, 0, 0))
bench(CFrame.new(60, 0, -66) * CFrame.Angles(0, 0, 0))

----------------------------------------------------------------------------
-- finish
----------------------------------------------------------------------------
tmp:Destroy()
hub.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- the home area is always there
hub.Parent = workspace

-- lighting preset (the client applies the same values; this is for the edit view)
local L = require(ReplicatedStorage.Shared.Config.Lighting).Hub
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
