-- SPEED ARC builder library for the league areas (City Park, Big Stadium ...). Returned as a table;
-- an area builder is run as loadstring(area)(lib). Same look rules as build_hub.luau.
local GeometryService = game:GetService("GeometryService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local L = {}
L.Palette = require(ReplicatedStorage.Shared.Config.Palette:Clone())
L.Stations = require(ReplicatedStorage.Shared.Config.Stations:Clone())
L.Areas = require(ReplicatedStorage.Shared.Config.Areas:Clone())
local Palette = L.Palette
local W = Palette.World
L.W = W
L.MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
L.BODY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
L.rng = Random.new(31)

function L.part(props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = props.CastShadow or false
	p.CanCollide = props.CanCollide ~= false
	p.CanQuery = props.CanQuery ~= false
	p.CanTouch = props.CanTouch or false
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

function L.block(parent, name, size, pos, color, extra)
	extra = extra or {}
	extra.Parent, extra.Name, extra.Size, extra.Pos, extra.Color = parent, name, size, pos, color
	return L.part(extra)
end

function L.cyl(parent, name, radius, height, pos, color, extra)
	extra = extra or {}
	extra.Parent, extra.Name, extra.Shape, extra.Color = parent, name, Enum.PartType.Cylinder, color
	extra.Size = Vector3.new(height, radius * 2, radius * 2)
	extra.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
	return L.part(extra)
end

function L.ball(parent, name, d, pos, color, extra)
	extra = extra or {}
	extra.Parent, extra.Name, extra.Shape, extra.Color = parent, name, Enum.PartType.Ball, color
	extra.Size = Vector3.new(d, d, d)
	extra.Pos = pos
	return L.part(extra)
end

local function csg(kind, main, others, name, parent, color)
	local ok, res = pcall(function()
		local fn = if kind == "union" then GeometryService.UnionAsync else GeometryService.SubtractAsync
		return fn(GeometryService, main, others, { CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition, RenderFidelity = Enum.RenderFidelity.Precise, SplitApart = false })
	end)
	if not ok then
		warn(kind .. " failed", name, res)
		return nil
	end
	main:Destroy()
	for _, o in others do
		o:Destroy()
	end
	local u = res[1]
	u.Name = name
	u.Anchored = true
	u.UsePartColor = true
	u.Color = color
	u.CastShadow = false
	u.Parent = parent
	return u
end

-- solid oval of a track's shape (track T), radius r
function L.stadium(T, r, h, y0, color, tmp)
	local c = T.Center
	local y = y0 + h / 2
	local rect = L.block(tmp, "R", Vector3.new(T.Straight, h, r * 2), c + Vector3.new(0, y, 0), color)
	local a = L.cyl(tmp, "A", r, h, c + Vector3.new(T.Straight / 2, y, 0), color)
	local b = L.cyl(tmp, "B", r, h, c + Vector3.new(-T.Straight / 2, y, 0), color)
	return csg("union", rect, { a, b }, "Stadium", tmp, color)
end

function L.ring(T, name, parent, r1, r2, h, y0, color, tmp)
	local outer = L.stadium(T, r2, h, y0, color, tmp)
	local inner = L.stadium(T, r1, h + 1, y0 - 0.5, color, tmp)
	return csg("subtract", outer, { inner }, name, parent, color)
end

-- the whole running oval: surface, apron, lane lines, curbs, gold line, lane numbers
function L.paintTrack(T, parent, tmp, opts)
	opts = opts or {}
	local outerR = T.InnerRadius + T.LaneWidth * T.Lanes
	L.ring(T, "Surface", parent, T.InnerRadius, outerR, T.SurfaceY, 0, opts.Color or W.TrackBlue, tmp)
	L.ring(T, "Apron", parent, outerR, outerR + 3, T.SurfaceY - 0.08, 0, opts.Apron or W.TrackBlueDark, tmp)
	for i = 1, T.Lanes - 1 do
		local r = T.InnerRadius + i * T.LaneWidth
		L.ring(T, "Line" .. i, parent, r - 0.15, r + 0.15, T.SurfaceY + 0.03, 0, W.LaneWhite, tmp)
		task.wait()
	end
	L.ring(T, "InnerCurb", parent, T.InnerRadius - 0.7, T.InnerRadius, T.SurfaceY + 0.35, 0, W.Aluminium, tmp)
	L.ring(T, "OuterCurb", parent, outerR + 3, outerR + 3.6, T.SurfaceY + 0.3, 0, W.LaneWhite, tmp)
	local lineZ = T.InnerRadius + T.LaneWidth * T.Lanes / 2
	local c = T.Center
	L.block(parent, "StartFinish", Vector3.new(1.2, T.SurfaceY + 0.06, T.LaneWidth * T.Lanes), c + Vector3.new(T.StartX, (T.SurfaceY + 0.06) / 2, lineZ), Palette.Gold)
	L.block(parent, "StartGlow", Vector3.new(0.3, T.SurfaceY + 0.08, T.LaneWidth * T.Lanes), c + Vector3.new(T.StartX - 0.8, (T.SurfaceY + 0.08) / 2, lineZ), Palette.Gold, { Material = Enum.Material.Neon })
	return outerR
end

function L.surfaceText(parent, face, lines, opts)
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
		t.FontFace = l.Font or L.MONTSERRAT
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

function L.meshTemplate(name, libName)
	local lib = ServerStorage:FindFirstChild(libName or "Meshes")
	local m = lib and lib:FindFirstChild(name)
	return m and (if m:IsA("MeshPart") then m else m:FindFirstChildWhichIsA("MeshPart"))
end

function L.mesh(name, parent, cf, opts)
	opts = opts or {}
	local t = L.meshTemplate(name, opts.Lib)
	if not t then
		return nil
	end
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

function L.folder(name, parent, model)
	local f = Instance.new(if model then "Model" else "Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function L.tree(parent, pos, scale)
	local r = L.rng:NextNumber()
	local name = if r < 0.4 then "Tree_Round_A" elseif r < 0.8 then "Tree_Round_B" else "Tree_Pine"
	local t = L.mesh(name, parent, CFrame.new(pos) * CFrame.Angles(0, L.rng:NextNumber(0, math.pi * 2), 0), { Scale = (scale or 1) * (if name == "Tree_Pine" then 1.25 else 1), CastShadow = true, Name = "Tree" })
	if not t then
		L.cyl(parent, "Trunk", 0.7, 6, pos + Vector3.new(0, 3, 0), W.Trunk)
		L.ball(parent, "Crown", 8, pos + Vector3.new(0, 8.5, 0), W.TreeLeaf, { CastShadow = true })
	end
end

function L.slot(parent, stationId, cf, i)
	local s = L.part({ Parent = parent, Name = "Slot", Size = Vector3.new(2.5, 0.2, 2.5), CFrame = cf, Color = Palette.Gold, Transparency = 1, CanCollide = false })
	s:SetAttribute("StationId", stationId)
	s:SetAttribute("Index", i)
	local exit = Instance.new("Attachment")
	exit.Name = "Exit"
	exit.Position = Vector3.new(-4.5, 0, 2)
	exit.Parent = s
	return s
end

function L.station(id)
	for _, s in L.Stations do
		if s.Id == id then
			return s
		end
	end
end

function L.sign(parent, station, cf)
	local m = Instance.new("Model")
	m.Name = "Sign"
	m.Parent = parent
	local board = L.part({ Parent = m, Name = "Board", Size = Vector3.new(9, 4.6, 0.5), CFrame = cf * CFrame.new(0, 5.6, 0), Color = Palette.Carbon })
	L.part({ Parent = m, Name = "Trim", Size = Vector3.new(9.4, 5, 0.3), CFrame = cf * CFrame.new(0, 5.6, 0.15), Color = if station.MinSpeed > 0 then Palette.Gold else Palette.ElectricBlue })
	L.part({ Parent = m, Name = "Post", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = cf * CFrame.new(-3.4, 1.7, 0.2), Color = Palette.SpeedBlack })
	L.part({ Parent = m, Name = "Post", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = cf * CFrame.new(3.4, 1.7, 0.2), Color = Palette.SpeedBlack })
	local fmt = require(ReplicatedStorage.Shared.Util.Format:Clone())
	L.surfaceText(board, Enum.NormalId.Front, {
		{ Text = string.upper(station.Name), Height = 0.36, Color = Palette.White },
		{ Text = ("AFK STEPS  x%g"):format(station.Mult or 1), Height = 0.24, Color = Palette.BrightBlue, Font = L.BODY },
		{ Text = if station.MinSpeed > 0 then ("NEEDS %s SPEED"):format(fmt.short(station.MinSpeed)) else "OPEN IN THIS LEAGUE", Height = 0.2, Color = Palette.Gold, Font = L.BODY },
	}, { PPS = 26, MaxDistance = 120, Padding = 2 })
	return m
end

function L.flag(parent, base, color, accent, poleH)
	local m = Instance.new("Model")
	m.Name = "Flag"
	m.Parent = parent
	poleH = poleH or 6
	L.cyl(m, "Pole", 0.2, poleH, base + Vector3.new(0, poleH / 2, 0), W.Aluminium)
	L.ball(m, "Tip", 0.6, base + Vector3.new(0, poleH + 0.2, 0), Palette.Gold)
	local hingePos = base + Vector3.new(0, poleH - 1.4, 0)
	L.block(m, "Hinge", Vector3.new(0.2, 0.2, 0.2), hingePos, color, { Transparency = 1, CanCollide = false, CanQuery = false })
	for i = 1, 5 do
		local s = L.block(m, "Seg", Vector3.new(0.84, 2.4, 0.08), hingePos + Vector3.new(0.8 * (i - 0.5), 0, 0), if i == 5 then accent else color, { CanCollide = false, CanQuery = false })
		s:SetAttribute("Seg", i)
	end
	return m
end

-- start/finish arch over the lanes (Blender mesh if imported) with countdown screens both sides
function L.arch(parent, T)
	local outerR = T.InnerRadius + T.LaneWidth * T.Lanes
	local c = T.Center
	local z1, z2 = T.InnerRadius - 3, outerR + 3
	local midZ = (z1 + z2) / 2
	local span = z2 - z1
	local x = c.X + T.StartX
	local scale = math.max(1, (span + 4) / 30)
	-- candy look (prompt 11): the part arch, white legs and a sky-blue beam (the imported arch mesh is dark steel)
	for _, z in { z1, z2 } do
		L.block(parent, "Leg", Vector3.new(2.4 * scale, 18 * scale, 2.4 * scale), Vector3.new(x, 9 * scale, z), Palette.White)
		L.block(parent, "Foot", Vector3.new(4 * scale, 1, 4 * scale), Vector3.new(x, 0.5, z), Palette.Sky)
	end
	L.block(parent, "Beam", Vector3.new(3 * scale, 4 * scale, span + 2.4), Vector3.new(x, 19.5 * scale, midZ), Palette.Sky)
	L.block(parent, "BeamGold", Vector3.new(3.2 * scale, 1, span + 2.6), Vector3.new(x, 21.7 * scale, midZ), Palette.Gold)
	local beamY = 19.5 * scale
	for _, side in { -1, 1 } do
		local screen = L.block(parent, "Screen", Vector3.new(0.2, 3.2 * scale, span - 4), Vector3.new(x + side * 1.6 * scale, beamY, midZ), Palette.SpeedBlack)
		L.surfaceText(screen, if side < 0 then Enum.NormalId.Left else Enum.NormalId.Right, {
			{ Text = "SPEED ARC", Height = 0.45, Color = Palette.Gold },
			{ Name = "RaceTimerText", Text = "NEXT RACE 3:00", Height = 0.45, Color = Palette.White },
		}, { PPS = 24, Brightness = 2, MaxDistance = 260, Padding = 0 })
	end
	return midZ
end

-- a gate: two pillars, a top beam, a glowing portal, a sign, and an invisible trigger (GateArea)
function L.gate(parent, name, cf, accent, title, subtitle, gateArea, notify)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	for _, s in { -1, 1 } do
		L.part({ Parent = m, Name = "Pillar", Size = Vector3.new(1.8, 12, 1.8), CFrame = cf * CFrame.new(s * 5.2, 6, 0), Color = Palette.SpeedBlack })
		L.part({ Parent = m, Name = "PillarGlow", Size = Vector3.new(0.3, 11, 0.3), CFrame = cf * CFrame.new(s * 4.25, 6, -0.75), Color = accent, Material = Enum.Material.Neon, CanCollide = false })
	end
	L.part({ Parent = m, Name = "Beam", Size = Vector3.new(12.6, 2, 2.2), CFrame = cf * CFrame.new(0, 12.6, 0), Color = Palette.Carbon })
	L.part({ Parent = m, Name = "BeamGold", Size = Vector3.new(12.8, 0.4, 2.4), CFrame = cf * CFrame.new(0, 13.7, 0), Color = Palette.Gold })
	local portal = L.part({ Parent = m, Name = "Portal", Size = Vector3.new(8.4, 11, 0.2), CFrame = cf * CFrame.new(0, 6, 0), Color = accent, Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false })
	portal:SetAttribute("Accent", accent:ToHex())
	local board = L.part({ Parent = m, Name = "Board", Size = Vector3.new(11, 2.8, 0.4), CFrame = cf * CFrame.new(0, 12.6, -1.25), Color = Palette.SpeedBlack, CanCollide = false })
	L.surfaceText(board, Enum.NormalId.Front, {
		{ Name = "Title", Text = title, Height = 0.55, Color = Palette.White },
		{ Name = "Sub", Text = subtitle, Height = 0.3, Color = Palette.Gold, Font = L.BODY },
	}, { PPS = 22, MaxDistance = 160, Padding = 0 })
	if gateArea then
		local trigger = L.part({ Parent = m, Name = "Trigger", Size = Vector3.new(8, 10, 2), CFrame = cf * CFrame.new(0, 5.5, 0), Transparency = 1, CanCollide = false, CanTouch = true })
		trigger:SetAttribute("GateArea", gateArea)
	end
	if notify then
		local spot = L.part({ Parent = m, Name = "NotifySpot", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 2.5, -2), Transparency = 1, CanCollide = false })
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "NOTIFY ME"
		pp.ObjectText = title
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp:SetAttribute("Opens", "NotifyMe")
		pp.Parent = spot
	end
	return m
end

-- the COACH AGENCY stand (28 Oct, owner: one in each world; rolls only happen here). cf = the
-- front-centre on the ground, facing the players. A candy desk under a canopy, a board of eight
-- coach cards in the rarity colours, a giant floating name, the ROLL prompt (Opens = "CoachCorner").
function L.agency(parent, cf)
	local Coaches = require(ReplicatedStorage.Shared.Config.Coaches:Clone())
	local m = Instance.new("Model")
	m.Name = "CoachAgency"
	m.Parent = parent
	local pink, white = Palette.Pink, Palette.White
	local function p(name, size, x, y, z, color, extra)
		extra = extra or {}
		extra.Parent = m
		extra.Name = name
		extra.Size = size
		extra.CFrame = cf * CFrame.new(x, y, z) * (extra.Turn or CFrame.new())
		extra.Turn = nil
		extra.Color = color
		return L.part(extra)
	end
	p("Pad", Vector3.new(18, 0.5, 10), 0, 0.25, 3.5, Palette.Cream)
	p("PadEdge", Vector3.new(18.6, 0.45, 10.6), 0, 0.22, 3.5, pink)
	p("Board", Vector3.new(16, 9, 0.8), 0, 5.6, 6.6, white)
	p("BoardTrim", Vector3.new(16.6, 9.6, 0.6), 0, 5.6, 6.9, pink)
	for i, c in Coaches.List do
		local x = -5.25 + ((i - 1) % 4) * 3.5
		local y = 7.4 - math.floor((i - 1) / 4) * 3.4
		p("Card", Vector3.new(2.8, 2.8, 0.2), x, y, 6.15, Coaches.RarityColors[c.Rarity], { CanCollide = false })
		p("CardFace", Vector3.new(1.4, 1.4, 1.4), x, y + 0.2, 6.0, Color3.fromHex(c.Look.Skin), { CanCollide = false, Shape = Enum.PartType.Ball })
	end
	p("Counter", Vector3.new(14, 3.4, 2.6), 0, 1.95, 2.2, pink)
	p("CounterTop", Vector3.new(14.6, 0.5, 3.2), 0, 3.9, 2.2, white)
	for _, s in { -1, 1 } do
		p("Pole", Vector3.new(11, 1.2, 1.2), s * 8.2, 5.9, 0.6, white, { Shape = Enum.PartType.Cylinder, Turn = CFrame.Angles(0, 0, math.pi / 2) })
		p("PoleCap", Vector3.new(1.8, 1.8, 1.8), s * 8.2, 11.6, 0.6, Palette.Gold, { Shape = Enum.PartType.Ball })
	end
	p("Canopy", Vector3.new(18, 1, 9), 0, 11.6, 3.4, pink)
	for i = 0, 5 do
		p("Awning", Vector3.new(3.02, 1.4, 3), -7.5 + i * 3, 10.5, -0.6, if i % 2 == 0 then white else pink, { Class = "WedgePart" })
	end
	local band = p("Facade", Vector3.new(18, 2, 0.5), 0, 13.1, -0.6, white)
	L.surfaceText(band, Enum.NormalId.Front, { { Text = "ROLL COACHES HERE", Height = 0.8, Color = pink, Font = L.BODY } }, { PPS = 20, MaxDistance = 200, Padding = 0 })
	-- a giant floating name
	local anchor = p("LabelAnchor", Vector3.new(1, 1, 1), 0, 19, 3, white, { Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(30, 7)
	bb.LightInfluence = 0
	bb.MaxDistance = 600
	bb.Parent = anchor
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "COACH AGENCY"
	t.TextScaled = true
	t.FontFace = L.MONTSERRAT
	t.TextColor3 = white
	t.Parent = bb
	local st = Instance.new("UIStroke")
	st.Color = pink:Lerp(Color3.new(0, 0, 0), 0.45)
	st.Thickness = 3
	st.Parent = t
	-- the prompt: its RightVector points out of the front (TutorialService stands you there)
	local spot = p("PromptSpot", Vector3.new(1, 1, 1), 0, 3, -2.5, Palette.Gold, { Transparency = 1, CanCollide = false, Turn = CFrame.Angles(0, math.pi / 2, 0) })
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "ROLL"
	pp.ObjectText = "Coach Agency"
	pp.HoldDuration = 0
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp:SetAttribute("Opens", "CoachCorner")
	pp.Parent = spot
	return m
end

-- a giant floating name (BillboardGui sized in studs, so it reads like a sign in the world)
function L.floatLabel(parent, pos, text, sub, color, w, h)
	local anchor = L.part({ Parent = parent, Name = "LabelAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false })
	local bb = Instance.new("BillboardGui")
	bb.Name = "FloatLabel"
	bb.Size = UDim2.fromScale(w, h)
	bb.LightInfluence = 0
	bb.MaxDistance = 700
	bb.Parent = anchor
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.45)
	local function line(t, y, hgt, col, stroke)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, hgt)
		l.Text = t
		l.TextScaled = true
		l.FontFace = L.MONTSERRAT
		l.TextColor3 = col
		l.Parent = bb
		local s = Instance.new("UIStroke")
		s.Color = stroke
		s.Thickness = 3
		s.Parent = l
	end
	line(text, 0, if sub then 0.68 else 1, Palette.White, dark)
	if sub then
		line(sub, 0.7, 0.3, color, Palette.White)
	end
	return anchor
end

-- the wall's face (both sides): WALL k, the big number, and (filled live by WallController for the
-- next wall of your run) a bar with "214 / 420", "about 40 more steps", cracks when you're close
local function wallGui(blockPart, face, k, need, col)
	local fmt = require(ReplicatedStorage.Shared.Util.Format:Clone())
	local g = Instance.new("SurfaceGui")
	g.Name = "WallGui"
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 12
	g.MaxDistance = 320
	g.LightInfluence = 0.2
	g.Brightness = 1.4
	g.ZOffset = 0.1
	g.Parent = blockPart
	local dark = col:Lerp(Color3.new(0, 0, 0), 0.5)
	local function label(name, text, y, h, stroke)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.05, y)
		l.Size = UDim2.fromScale(0.9, h)
		l.Text = text
		l.TextScaled = true
		l.FontFace = L.MONTSERRAT
		l.TextColor3 = Palette.White
		l.ZIndex = 3
		l.Parent = g
		local s = Instance.new("UIStroke")
		s.Color = dark
		s.Thickness = stroke
		s.Parent = l
		return l
	end
	-- cracks (behind the text): thin dark lines from the middle, shown when you're close
	local cracks = Instance.new("Frame")
	cracks.Name = "Cracks"
	cracks.BackgroundTransparency = 1
	cracks.Size = UDim2.fromScale(1, 1)
	cracks.Visible = false
	cracks.Parent = g
	local crng = Random.new(k * 7)
	for i = 1, 9 do
		local c = Instance.new("Frame")
		c.BackgroundColor3 = dark
		c.BorderSizePixel = 0
		c.AnchorPoint = Vector2.new(0, 0.5)
		c.Position = UDim2.fromScale(crng:NextNumber(0.3, 0.7), crng:NextNumber(0.3, 0.7))
		c.Size = UDim2.new(0, crng:NextInteger(60, 160), 0, crng:NextInteger(3, 5))
		c.Rotation = crng:NextNumber(0, 360)
		c.ZIndex = 2
		c.Parent = cracks
	end
	label("Title", "WALL " .. k, 0.04, 0.14, 3)
	label("Need", fmt.short(need), 0.17, 0.38, 6)
	label("Sub", "SPEED NEEDED", 0.55, 0.12, 3)
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundColor3 = dark
	bar.Position = UDim2.fromScale(0.18, 0.71)
	bar.Size = UDim2.fromScale(0.64, 0.08)
	bar.Visible = false
	bar.ZIndex = 3
	bar.Parent = g
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0.5, 0)
	bc.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Palette.White
	fill.Size = UDim2.fromScale(0, 1)
	fill.ZIndex = 4
	fill.Parent = bar
	bc:Clone().Parent = fill
	local have = label("Have", "", 0.81, 0.14, 3)
	have.Visible = false
end

-- the wall course of an area (28 Oct pivot, prompt 11: one builder for every world). Config/Course
-- Areas[areaId] gives the start line and the direction. Walls are Models "Wall<k>" (Index / League
-- attributes; "Block" is the wall, "Glow" parts light up on your screen when you have the SPEED).
-- opts: League, Theme ("hub" | "hedge" | "stands"), Colors (10 hex), Crowd (folder for fans),
--       Bridge (stage number that crosses water), Title / Sub (the start arch), Accent
function L.course(parent, areaId, opts)
	local Course = require(ReplicatedStorage.Shared.Config.Course:Clone())
	local Formulas = require(ReplicatedStorage.Shared.Util.Formulas) -- not a clone: it requires its Config siblings
	local C = Course.Areas[areaId]
	local walls = #Course.WallShares
	local L_, Wd, H = Course.StageLength, Course.Width, Course.WallHeight
	local colors = opts.Colors or Course.Colors
	local accent = opts.Accent or Palette.Pink
	local m = Instance.new("Model")
	m.Name = "Course"
	m.Parent = parent
	-- local frame: x across, z = distance down the course (the frame looks down -Z, so z is negative)
	local F = CFrame.lookAt(C.Start, C.Start + C.Dir)
	local function at(x, y, along)
		return F * CFrame.new(x, y, -along)
	end
	local function p(name, size, x, y, along, color, extra, into)
		extra = extra or {}
		extra.Parent = into or m
		extra.Name = name
		extra.Size = size
		extra.CFrame = at(x, y, along) * (extra.Turn or CFrame.new())
		extra.Turn = nil
		extra.Color = color
		return L.part(extra)
	end
	local seatLines = {}
	for k = 1, walls do
		local col = Color3.fromHex(colors[(k - 1) % #colors + 1])
		local a0 = (k - 1) * L_
		local mid = a0 + L_ / 2
		local water = opts.Bridge == k
		p("Stage" .. k, Vector3.new(Wd, 0.6, L_), 0, 0.3, mid, col:Lerp(Palette.White, 0.45))
		for side = -1, 1, 2 do
			p("Kerb", Vector3.new(2, 1.6, L_), side * (Wd / 2 + 1), 0.8, mid, col)
			p("KerbTop", Vector3.new(2.2, 0.3, L_), side * (Wd / 2 + 1), 1.65, mid, Palette.White)
			p("Side", Vector3.new(1, 40, L_), side * (Wd / 2 + 2.5), 20, mid, col, { Transparency = 1 })
			if water then
				-- a bridge over the lake: water both sides, white posts and a rail
				p("Water", Vector3.new(60, 0.3, L_ + 20), side * (Wd / 2 + 32), -0.2, mid, Color3.fromHex("#4FB6F0"), { Transparency = 0.1, CanCollide = false })
				for j = 0, 6 do
					p("BridgePost", Vector3.new(0.8, 3.6, 0.8), side * (Wd / 2 + 1), 3.4, a0 + 6 + j * 13, Palette.White)
				end
				p("BridgeRail", Vector3.new(0.6, 0.6, L_), side * (Wd / 2 + 1), 5.1, mid, Palette.White)
			elseif opts.Theme == "hedge" then
				p("Hedge", Vector3.new(3, 3.6, L_), side * (Wd / 2 + 4), 1.8, mid, W.TreeLeafDark)
				for j = 0, 4 do
					p("Bush", Vector3.new(4.6, 4.6, 4.6), side * (Wd / 2 + 4.4), 3.2, a0 + 9 + j * 18, if j % 2 == 0 then W.TreeLeaf else W.TreeLeafLight, { Shape = Enum.PartType.Ball, CanCollide = false })
				end
			elseif opts.Theme == "stands" then
				-- low stands with a crowd along the course (they cheer on every smash)
				for row = 1, 3 do
					local h = row * 1.4
					p("StandStep", Vector3.new(4, h, L_ - 2), side * (Wd / 2 + 2 + row * 4), h / 2, mid, if row % 2 == 0 then Palette.White else Palette.Sky)
				end
				if k % 2 == 1 then
					local x = side * (Wd / 2 + 2 + 2 * 4)
					table.insert(seatLines, { (at(x, 2 * 1.4, a0 + 4)).Position, (at(x, 2 * 1.4, a0 + L_ - 4)).Position, (F.RightVector * -side) })
				end
			end
		end
		-- chevrons point the way
		for j = 0, 3 do
			for s = -1, 1, 2 do
				p("Chevron", Vector3.new(6, 0.62, 1.4), s * 2.2, 0.31, a0 + 14 + j * 18, Palette.White, { CanCollide = false, Turn = CFrame.Angles(0, -s * math.rad(35), 0) })
			end
		end
		-- the wall
		local wm = Instance.new("Model")
		wm.Name = "Wall" .. k
		wm:SetAttribute("Index", k)
		wm:SetAttribute("League", opts.League)
		wm.Parent = m
		local wallAt = k * L_
		local blockPart = p("Block", Vector3.new(Wd, H, 3), 0, 0.6 + H / 2, wallAt, col, nil, wm)
		p("Top", Vector3.new(Wd, 26, 3), 0, 0.6 + H + 13, wallAt, col, { Transparency = 1 }, wm)
		p("Cap", Vector3.new(Wd + 1, 1.2, 3.6), 0, 0.6 + H + 0.6, wallAt, Palette.White, nil, wm)
		for r = 1, 4 do
			p("Band", Vector3.new(Wd + 0.04, 0.35, 3.08), 0, 0.6 + r * H / 5, wallAt, col:Lerp(Palette.White, 0.35), { CanCollide = false }, wm)
		end
		-- glowing edges (your screen lights them when you have enough SPEED)
		local glow = col:Lerp(Palette.White, 0.5)
		for _, s in { -1, 1 } do
			p("Glow", Vector3.new(0.6, H + 0.4, 3.3), s * (Wd / 2 - 0.2), 0.6 + H / 2, wallAt, glow, { Material = Enum.Material.Neon, Transparency = 1, CanCollide = false }, wm)
		end
		p("Glow", Vector3.new(Wd, 0.6, 3.3), 0, 0.6 + H - 0.2, wallAt, glow, { Material = Enum.Material.Neon, Transparency = 1, CanCollide = false }, wm)
		local need = Formulas.wallNeed(opts.League, k)
		wallGui(blockPart, Enum.NormalId.Front, k, need, col)
		wallGui(blockPart, Enum.NormalId.Back, k, need, col)
	end
	-- the finish: a gold stage, a FINISH arch and a closed end (WallService sends you back to the start)
	local endAt = walls * L_
	p("Finish", Vector3.new(Wd, 0.6, 40), 0, 0.3, endAt + 20, Palette.Gold)
	for side = -1, 1, 2 do
		p("Side", Vector3.new(1, 40, 40), side * (Wd / 2 + 2.5), 20, endAt + 20, Palette.Gold, { Transparency = 1 })
		p("FinishKerb", Vector3.new(2, 1.6, 40), side * (Wd / 2 + 1), 0.8, endAt + 20, Palette.Gold)
		p("FinishPillar", Vector3.new(16, 3, 3), side * (Wd / 2 + 1.6), 8, endAt + 30, Palette.White, { Shape = Enum.PartType.Cylinder, Turn = CFrame.Angles(0, 0, math.pi / 2) })
		p("FinishCap", Vector3.new(4, 4, 4), side * (Wd / 2 + 1.6), 16.4, endAt + 30, Palette.Gold, { Shape = Enum.PartType.Ball })
	end
	local fb = p("FinishBeam", Vector3.new(Wd + 6, 4, 2.4), 0, 14, endAt + 30, Palette.Gold)
	L.surfaceText(fb, Enum.NormalId.Back, { { Text = "FINISH", Height = 0.8, Color = Palette.White, Stroke = Palette.DeepGold, StrokeThickness = 3 } }, { PPS = 14, MaxDistance = 400, Padding = 0 })
	p("EndWall", Vector3.new(Wd + 8, 10, 2), 0, 5, endAt + 41, Palette.White)
	p("EndStripe", Vector3.new(Wd + 8.2, 1.2, 2.2), 0, 7, endAt + 41, accent)
	p("EndBlock", Vector3.new(Wd + 6, 40, 2), 0, 20, endAt + 41, Palette.White, { Transparency = 1 })
	L.floatLabel(m, (at(0, 20, endAt + 24)).Position, "YOU DID IT!", "GO PRO TO OPEN A NEW WORLD", Palette.Gold, 40, 11)
	-- the start arch
	for _, s in { -1, 1 } do
		p("ArchPillar", Vector3.new(20, 3.2, 3.2), s * (Wd / 2 + 1.6), 10, 0, accent, { Shape = Enum.PartType.Cylinder, Turn = CFrame.Angles(0, 0, math.pi / 2) })
		p("ArchCap", Vector3.new(4.4, 4.4, 4.4), s * (Wd / 2 + 1.6), 20.6, 0, Palette.Gold, { Shape = Enum.PartType.Ball })
	end
	local beam = p("ArchBeam", Vector3.new(Wd + 6, 5, 2.4), 0, 17.5, 0, Palette.White)
	p("ArchTrim", Vector3.new(Wd + 6.4, 0.8, 2.8), 0, 15, 0, accent)
	-- the back face looks at you as you come up to the start
	L.surfaceText(beam, Enum.NormalId.Back, {
		{ Text = opts.Title or "WALL RUN", Height = 0.6, Color = accent, Stroke = Palette.White, StrokeThickness = 3 },
		{ Text = opts.Sub or "EVERY STEP = +1 SPEED", Height = 0.3, Color = Palette.SpeedBlack, Font = L.BODY },
	}, { PPS = 14, MaxDistance = 400, Padding = 0, Brightness = 1.2 })
	L.floatLabel(m, C.Start + Vector3.new(0, 30, 0), "SMASH WALLS", "RUN, GET FASTER, BREAK THROUGH", accent, 48, 13)
	local fans = 0
	if #seatLines > 0 and opts.Crowd then
		fans = L.fans(opts.Crowd, seatLines, 0.45, "MeshesV1_Backup")
	end
	return m, fans
end

-- a leaderboard board with 5 rows the server fills (AreaService)
function L.leaderboard(parent, cf, title)
	local m = Instance.new("Model")
	m.Name = "Leaderboard"
	m.Parent = parent
	local board = L.part({ Parent = m, Name = "Board", Size = Vector3.new(10, 7, 0.5), CFrame = cf * CFrame.new(0, 6.5, 0), Color = Palette.Carbon })
	L.part({ Parent = m, Name = "Trim", Size = Vector3.new(10.4, 7.4, 0.3), CFrame = cf * CFrame.new(0, 6.5, 0.2), Color = Palette.Gold })
	for _, s in { -1, 1 } do
		L.part({ Parent = m, Name = "Leg", Size = Vector3.new(0.5, 3, 0.5), CFrame = cf * CFrame.new(s * 4, 1.5, 0.2), Color = Palette.SpeedBlack })
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.MaxDistance = 200
	gui.LightInfluence = 0.2
	gui.Brightness = 1.4
	gui.Parent = board
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.2)
	t.TextScaled = true
	t.FontFace = L.MONTSERRAT
	t.Text = title
	t.TextColor3 = Palette.Gold
	t.Parent = gui
	local rows = Instance.new("Frame")
	rows.Name = "Rows"
	rows.BackgroundTransparency = 1
	rows.Position = UDim2.fromScale(0.06, 0.22)
	rows.Size = UDim2.fromScale(0.88, 0.75)
	rows.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rows
	for i = 1, 5 do
		local r = Instance.new("TextLabel")
		r.Name = "Row" .. i
		r.LayoutOrder = i
		r.BackgroundTransparency = 1
		r.Size = UDim2.fromScale(1, 0.2)
		r.TextScaled = true
		r.FontFace = L.BODY
		r.TextXAlignment = Enum.TextXAlignment.Left
		r.Text = if i == 1 then "LOADING..." else "" -- LeaderboardService fills the rows
		r.TextColor3 = if i == 1 then Palette.Gold else Palette.White
		r.Parent = rows
	end
	return m
end

-- fill a set of bleacher rows with fans (rows given by world positions of each seat line)
function L.fans(parent, seatLines, density, lib)
	local count = 0
	for _, line in seatLines do
		local a, b = line[1], line[2]
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local d = L.rng:NextNumber(0, 2)
		while d < len - 1 do
			if L.rng:NextNumber() < density then
				local pick = ({ "Crowd_Fan_A", "Crowd_Fan_B", "Crowd_Fan_C", "Crowd_Fan_A" })[L.rng:NextInteger(1, 4)]
				local pos = a + dir * d
				-- fans face +Z (their face side): point +Z at the track
				local cf = CFrame.lookAt(pos, pos - line[3]) * CFrame.Angles(0, L.rng:NextNumber(-0.12, 0.12), 0)
				local t = L.meshTemplate(pick, lib)
				if t then
					local f = L.mesh(pick, parent, cf, { Lib = lib, Scale = L.rng:NextNumber(0.95, 1.06), CanCollide = false, Name = "Fan", Offset = Vector3.new(t.Size.X / 2 - 0.85, 0, 0) })
					f:SetAttribute("Phase", L.rng:NextNumber(0, 6.28))
					count += 1
				end
			end
			d += L.rng:NextNumber(3.6, 5)
		end
	end
	return count
end

function L.countParts(model)
	local n, lights = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		elseif d:IsA("Light") then
			lights += 1
		end
	end
	return n, lights
end

-- start an area model: replaces an older one built today, backs up one from another day
function L.begin(modelName)
	local stamp = os.date("!%Y%m%d_%H%M")
	local today = os.date("!%Y%m%d")
	local old = workspace:FindFirstChild(modelName)
	if old then
		if old:GetAttribute("BuildDay") == today then
			old:Destroy()
		else
			old.Name = modelName .. "Backup_" .. stamp
			old.Parent = ServerStorage
		end
	end
	local m = Instance.new("Model")
	m.Name = modelName
	m:SetAttribute("BuildDay", today)
	local tmp = Instance.new("Folder")
	tmp.Name = "_tmp_" .. modelName
	tmp.Parent = workspace
	return m, tmp
end

function L.finish(m, tmp)
	tmp:Destroy()
	m.ModelStreamingMode = Enum.ModelStreamingMode.Default -- streams on its own; never all areas at once
	m.Parent = workspace
	return L.countParts(m)
end

return L
