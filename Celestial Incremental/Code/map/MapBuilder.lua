-- GalaxyMapBuilder (Galaxy Incremental): builds the STATIC map into Workspace.Galaxy, ONLY from MapConfig (every size and
-- position is there) + the kit (ReplicatedStorage.GalaxyKit meshes, always scaled uniformly with Kit.Fit).
-- REDONE TO SCALE (owner, 2 Nov night): everything sized against the R15 character (vault: "Map scale spec (redo)").
--  * the centre plaza (140 across) in ZONES round the Supernova Core: FRONT the STAR SURGE bar, RIGHT the Star Forge,
--    BACK the Black Hole gate, BACK-LEFT the Sector 2 arch + IGNITION sign + its 10-wide bridge, LEFT the leaderboard wall;
--    the plaza pieces you walk up to face the Core; open walkways from every bridge landing to the Core
--  * the 8 island slots (60 across), each with an 8-wide railed bridge and stone thresholds at both ends; a free slot is a dim
--    bare rock (GalaxyMapService grows the owned ones, including their Upgrades terminal, from tier 1)
--  * the locked Sector 2 island across the void, the sky and the lighting
-- Run in Studio (command bar): require(game.ServerStorage.GalaxyMapBuilder).Build(). GalaxyMapService rebuilds it at server
-- start when the map still has stand-ins and the owner's kit has been imported since.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy.MapConfig)
local Kit = require(Galaxy.Kit)

local C = MapConfig.Colors
local O = MapConfig.Origin
local UP = Vector3.new(0, 1, 0)
local Builder = {}

local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local FONT_B = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored, p.CastShadow, p.CanTouch = true, false, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	return p
end
Builder.part = part
local function brass(props)
	props.Color = C.Brass
	props.Material = props.Material or MapConfig.BrassMaterial
	props.Reflectance = props.Reflectance or MapConfig.BrassReflectance
	return props
end
Builder.brass = brass
local function label(gui, text, pos: UDim2, size: UDim2, colour: Color3, font, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position, l.Size = pos, size
	l.FontFace = font or FONT
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = colour
	l.TextXAlignment = align or Enum.TextXAlignment.Center
	l.Parent = gui
	return l
end
Builder.label = label
local function surface(p: BasePart, face: Enum.NormalId): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Brightness = MapConfig.Boards.Brightness -- (not washed out by the haze + grade + bloom, 5 Nov)
	gui.MaxDistance = 300
	gui.Parent = p
	return gui
end
Builder.surface = surface
-- a frame at `pos` whose +Z points at `target` (text on a part's Back face = +Z reads from the target's side)
local function faceTo(pos: Vector3, target: Vector3): CFrame
	local d = Vector3.new(target.X - pos.X, 0, target.Z - pos.Z)
	if d.Magnitude < 1e-3 then d = Vector3.new(0, 0, 1) end
	return CFrame.lookAt(pos, pos - d.Unit)
end
Builder.faceTo = faceTo
-- a zone on the plaza floor: `dist` out from the Core at `angle`; its +Z faces the Core (inward) or out
local function zoneCf(angle: number, dist: number, inward: boolean): CFrame
	local pos = O + MapConfig.ZoneDir(angle) * dist
	return faceTo(pos, if inward then O else pos + MapConfig.ZoneDir(angle))
end
-- a sign on two brass posts standing on the floor: text lines on its front (+Z), and on its back too when `both`
local function sign(parent, name, base: CFrame, w: number, h: number, bottom: number, lines: { string }, color: Color3?, both: boolean?)
	local cf = base * CFrame.new(0, bottom + h / 2, 0)
	local p = part({ Name = name, Size = Vector3.new(w, h, 0.3), CFrame = cf, Color = C.SignBack, CanCollide = false, CanQuery = false, Parent = parent })
	for _, face in ipairs(if both then { Enum.NormalId.Back, Enum.NormalId.Front } else { Enum.NormalId.Back }) do
		local gui = surface(p, face)
		for i, text in ipairs(lines) do
			label(gui, text, UDim2.fromScale(0.04, if #lines == 1 then 0.1 else (if i == 1 then 0.06 else 0.62)),
				UDim2.fromScale(0.92, if #lines == 1 then 0.8 else (if i == 1 then 0.52 else 0.32)),
				if i == 1 then (color or Color3.fromRGB(255, 214, 120)) else Color3.fromRGB(225, 215, 240))
		end
	end
	part(brass({ Name = name .. "Edge", Size = Vector3.new(w + 0.5, h + 0.5, 0.2), CFrame = cf, CanCollide = false, CanQuery = false, Parent = parent }))
	for _, side in ipairs({ -1, 1 }) do
		local ph = bottom + h * 0.5
		part(brass({ Name = name .. "Post", Size = Vector3.new(0.5, ph, 0.5), CFrame = base * CFrame.new(side * (w / 2 - 0.6), ph / 2, -0.3), Parent = parent }))
	end
	return p
end
Builder.sign = sign
-- a frame whose +Y points along dir (for spikes)
local function alongY(pos: Vector3, dir: Vector3): CFrame
	local right = dir:Cross(UP)
	if right.Magnitude < 1e-3 then right = Vector3.new(1, 0, 0) end
	return CFrame.fromMatrix(pos, right.Unit, dir.Unit)
end

function Builder.IslandCenter(slot: number): (Vector3, Vector3, number)
	local I = MapConfig.Islands
	local a = math.rad(I.StartAngle + (slot - 1) * 360 / I.Count)
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	return O + dir * I.Ring + Vector3.new(0, I.Heights[slot] or 0, 0), dir, a
end
-- island-local place: x = out from the Core, z = to the side (MapConfig.Islands.Spawn, Terminal, ...)
function Builder.IslandPoint(c: Vector3, dir: Vector3, at: Vector3): Vector3
	local side = Vector3.new(-dir.Z, 0, dir.X)
	return c + dir * at.X + side * at.Z + UP * at.Y
end

-- a bridge: n deck segments (lit / dim later by Index) with brass rails both sides
local function bridge(parent, A: Vector3, B: Vector3, n: number, width: number, arch: number, color: Color3, name: string)
	local I = MapConfig.Islands.Bridge
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	local rails = Instance.new("Folder")
	rails.Name = name .. "Rails"
	rails.Parent = parent
	local pts = {}
	for k = 0, n do
		local t = k / n
		pts[k] = A:Lerp(B, t) + UP * (math.sin(t * math.pi) * arch)
	end
	for k = 1, n do
		local p0, p1 = pts[k - 1], pts[k]
		local len = (p1 - p0).Magnitude + 0.2
		local cf = CFrame.lookAt((p0 + p1) / 2, p1) * CFrame.new(0, -I.Thick / 2, 0)
		local seg = part({ Name = "Seg_" .. k, Size = Vector3.new(width, I.Thick, len), CFrame = cf, Color = color, Material = Enum.Material.Neon, CanCollide = true, Parent = folder })
		seg:SetAttribute("Index", k)
		for _, side in ipairs({ -1, 1 }) do
			local railCf = cf * CFrame.new(side * (width / 2 - 0.2), I.Thick / 2 + I.Rail, 0)
			part(brass({ Name = "Rail", Size = Vector3.new(0.35, 0.35, len), CFrame = railCf, CanCollide = true, Parent = rails }))
			if k % 2 == 1 or k == n then
				part(brass({ Name = "RailPost", Size = Vector3.new(0.3, I.Rail, 0.3), CFrame = cf * CFrame.new(side * (width / 2 - 0.2), I.Thick / 2 + I.Rail / 2, (if k == n then 1 else -1) * (len / 2 - 0.2)),
					CanCollide = false, CanQuery = false, Parent = rails }))
			end
		end
	end
	return folder, pts
end
-- a stone threshold over a rim (top `top` above `floor` level), a slab from `from` to `to` along `dir` from `origin` +
-- a ramp `ramp` long back down to the floor on the `from` side. Returns the slab's far end (where the bridge starts).
local function threshold(parent, origin: Vector3, dir: Vector3, from: number, to: number, top: number, thick: number, ramp: number, width: number): Vector3
	local w = width + 1.2
	local frame = CFrame.lookAt(origin, origin + dir) -- (-Z = along dir)
	local slab = part({ Name = "Threshold", Size = Vector3.new(w, thick, to - from), Color = C.Stone2, CanCollide = true,
		CFrame = frame * CFrame.new(0, top - thick / 2, -(from + to) / 2), Parent = parent })
	local wedge = Instance.new("WedgePart")
	wedge.Name = "ThresholdRamp"
	wedge.Size = Vector3.new(w, top, ramp)
	wedge.CFrame = frame * CFrame.new(0, top / 2, -(from - ramp / 2)) * CFrame.Angles(0, math.pi, 0)
	wedge.Anchored, wedge.CastShadow, wedge.CanTouch = true, false, false
	wedge.Color, wedge.Material = C.Stone2, Enum.Material.SmoothPlastic
	wedge.Parent = parent
	for _, side in ipairs({ -1, 1 }) do
		part(brass({ Name = "ThresholdEdge", Size = Vector3.new(0.3, 0.2, to - from), CFrame = slab.CFrame * CFrame.new(side * (w / 2 - 0.15), thick / 2 + 0.1, 0),
			CanCollide = false, CanQuery = false, Parent = parent }))
	end
	return origin + dir * (to - 0.3) + UP * (top - 0.1)
end

-- the LEFT zone's leaderboard wall + the PLAYERS NEAR YOU board next to it (overnight part 3: its own function, so Studio
-- can rebuild just these two without rebuilding the map: Builder.Leaderboards(workspace.Galaxy.Centre))
function Builder.Leaderboards(centre: Instance)
	for _, n in ipairs({ "Leaderboard", "NearBoard" }) do
		local old = centre:FindFirstChild(n)
		if old then old:Destroy() end
	end
	local Z = MapConfig.Centre.Zones
	------------------------------------------------------------------ LEFT: the leaderboard wall (facing the Core, both sides)
	-- TOP SUPERNOVAS (GalaxyLeaderboardService) in 2 columns of 5; PLAYERS NEAR YOU has its own board next to it (below)
	local LB = MapConfig.Leaderboard
	local lb = Instance.new("Model")
	lb.Name = "Leaderboard"
	lb.Parent = centre
	local zl = zoneCf(Z.Leaderboard.angle, Z.Leaderboard.dist, true)
	local wallCf = zl * CFrame.new(0, LB.Bottom + LB.Height / 2, 0)
	-- (7 Nov, rule 8 ONE FRAME: the plaque art is the board's frame: no brass edge, the wall itself is see-through)
	local wall = part({ Name = "Wall", Size = Vector3.new(LB.Width, LB.Height, 0.6), CFrame = wallCf, Color = Color3.fromRGB(22, 17, 30), Transparency = 1, Parent = lb })
	for _, sx in ipairs({ -1, 1 }) do
		local h = LB.Bottom + LB.Height + 1
		part(brass({ Name = "Post", Size = Vector3.new(1, h, 1), CFrame = zl * CFrame.new(sx * (LB.Width / 2 + 0.9), h / 2, 0), Parent = lb }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", 1.6 }, CFrame = zl * CFrame.new(sx * (LB.Width / 2 + 0.9), h + 0.8, 0), Color = C.LampHead, Material = Enum.Material.SmoothPlastic, Parent = lb })
	end
	for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Front }) do
		local gui = surface(wall, face)
		gui.Name = "Board_" .. face.Name
		local f = Instance.new("Frame")
		f.Name = "Top"
		f.BackgroundTransparency = 1
		f.Position = UDim2.fromScale(0.02, 0.03)
		f.Size = UDim2.fromScale(0.96, 0.94)
		f.Parent = gui
		label(f, "TOP SUPERNOVAS", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.17), Color3.fromRGB(255, 214, 120))
		local perCol = math.ceil(LB.Rows / 2)
		for r = 1, LB.Rows do
			local col, i = (r - 1) // perCol, (r - 1) % perCol
			local row = label(f, "", UDim2.fromScale(0.02 + col * 0.5, 0.21 + i * (0.78 / perCol)), UDim2.fromScale(0.46, 0.78 / perCol * 0.82), Color3.fromRGB(225, 215, 240), FONT_B, Enum.TextXAlignment.Left)
			row.Name = "Row" .. r
		end
		local divider = Instance.new("Frame")
		divider.BackgroundColor3 = C.Brass
		divider.BorderSizePixel = 0
		divider.Position = UDim2.fromScale(0.497, 0.22)
		divider.Size = UDim2.new(0, 4, 0.74, 0)
		divider.Parent = gui
	end

	------------------------------------------------------------------ PLAYERS NEAR YOU (overnight part 3): its own board next
	-- to the wall, facing the Core; each player's screen fills it with THEIR neighbours (GalaxyMapClient, BoardEvent "Near")
	local NB = MapConfig.NearBoard
	local nb = Instance.new("Model")
	nb.Name = "NearBoard"
	nb.Parent = centre
	local zn = zoneCf(NB.angle, NB.dist, true)
	local nbCf = zn * CFrame.new(0, NB.Bottom + NB.Height / 2, 0)
	local board = part({ Name = "Board", Size = Vector3.new(NB.Width, NB.Height, 0.6), CFrame = nbCf, Color = Color3.fromRGB(22, 17, 30), Transparency = 1, Parent = nb })
	for _, sx in ipairs({ -1, 1 }) do
		local h = NB.Bottom + NB.Height + 1
		part(brass({ Name = "Post", Size = Vector3.new(1, h, 1), CFrame = zn * CFrame.new(sx * (NB.Width / 2 + 0.9), h / 2, 0), Parent = nb }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", 1.6 }, CFrame = zn * CFrame.new(sx * (NB.Width / 2 + 0.9), h + 0.8, 0), Color = C.LampHead, Material = Enum.Material.SmoothPlastic, Parent = nb })
	end
	local ngui = surface(board, Enum.NormalId.Back)
	ngui.Name = "Board_Back"
	local nf = Instance.new("Frame")
	nf.Name = "Near"
	nf.BackgroundTransparency = 1
	nf.Position = UDim2.fromScale(0.04, 0.025)
	nf.Size = UDim2.fromScale(0.92, 0.95)
	nf.Parent = ngui
	label(nf, "PLAYERS NEAR YOU", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.1), Color3.fromRGB(150, 220, 255))
	for r = 1, NB.Rows do
		-- (each row: a soft band behind it; the server's list fills the text, you in gold on your own screen)
		local band = Instance.new("Frame")
		band.Name = "Band" .. r
		band.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		band.BackgroundTransparency = if r % 2 == 0 then 0.94 else 1
		band.BorderSizePixel = 0
		band.Position = UDim2.fromScale(0, 0.12 + (r - 1) * (0.88 / NB.Rows))
		band.Size = UDim2.fromScale(1, 0.88 / NB.Rows)
		band.Parent = nf
		local row = label(nf, "", UDim2.fromScale(0.03, 0.12 + (r - 1) * (0.88 / NB.Rows) + 0.88 / NB.Rows * 0.1), UDim2.fromScale(0.94, 0.88 / NB.Rows * 0.8), Color3.fromRGB(225, 215, 240), FONT_B, Enum.TextXAlignment.Left)
		row.Name = "Row" .. r
	end
end

-- DECOR NEVER IN FRONT OF A SIGN (6 Nov, owner: "buttons inside a platform"): a crystal standing in a sign's view (its
-- face +- 0.5 studs, up to 6 studs out in front) is slid sideways out of it, 0.5 studs clear. The plaza and Sector 2 only
-- (the islands keep their pieces clear by MapConfig). Runs at the end of Build, and again from GalaxyMapService (a place
-- built before this rule; the Sector 2 Forge it places later).
local DECOR = { Crystal = true, CrystalCluster = true }
function Builder.ClearDecor(root: Instance)
	local islands = root:FindFirstChild("Islands")
	local faces = {}
	-- (a part named Screen = a board whose screen the client draws, e.g. FREE REWARDS: its Back face counts too)
	local list = {}
	for _, g in ipairs(root:GetDescendants()) do
		if g:IsA("SurfaceGui") then table.insert(list, g)
		elseif g:IsA("BasePart") and g.Name == "Screen" and not (islands and g:IsDescendantOf(islands)) then table.insert(list, { Parent = g, Face = Enum.NormalId.Back }) end
	end
	for _, g in ipairs(list) do
		if g.Parent:IsA("BasePart") and not (islands and g.Parent:IsDescendantOf(islands)) then
			local p = g.Parent :: BasePart
			local n = Vector3.FromNormalId(g.Face)
			local normal = p.CFrame:VectorToWorldSpace(n)
			local right = normal:Cross(Vector3.new(0, 1, 0))
			if right.Magnitude < 0.1 then continue end -- (a face looking up or down)
			right = right.Unit
			local depth = math.abs(p.Size:Dot(n)) / 2
			local hw = math.abs(p.CFrame:VectorToObjectSpace(right):Dot(p.Size)) / 2
			table.insert(faces, { c = p.Position + normal * depth, normal = normal, right = right, hw = hw, hh = p.Size.Y / 2, sign = p })
		end
	end
	for _, d in ipairs(root:GetDescendants()) do
		if not d:IsA("BasePart") or not DECOR[d.Name] or (islands and d:IsDescendantOf(islands)) then continue end
		local r = math.max(d.Size.X, d.Size.Z) / 2
		for _, f in ipairs(faces) do
			if d:IsDescendantOf(f.sign.Parent) then continue end
			local v = d.Position - f.c
			local x, y, z = v:Dot(f.right), v.Y, v:Dot(f.normal)
			if z > -r and z < 6 + r and math.abs(x) < f.hw + 0.5 + r and math.abs(y) < f.hh + 0.5 + d.Size.Y / 2 then
				local side = if x >= 0 then 1 else -1
				d.CFrame += f.right * side * (f.hw + 0.5 + r + 0.1 - math.abs(x))
			end
		end
	end
end

-- the plaza's FREE REWARDS board (MapConfig.FreeBoard): a dark screen in a brass edge on two posts with lamps, like PLAYERS
-- NEAR YOU. Built by Build, and by GalaxyMapService into a place built before it (it checks first)
function Builder.FreeBoard(centre: Instance)
	if centre:FindFirstChild("FreeBoard") then return end
	local FB = MapConfig.FreeBoard
	local m = Instance.new("Model")
	m.Name = "FreeBoard"
	local zn = zoneCf(FB.angle, FB.dist, true)
	local cf = zn * CFrame.new(0, FB.Bottom + FB.Height / 2, 0)
	part({ Name = "Screen", Size = Vector3.new(FB.Width, FB.Height, 0.6), CFrame = cf, Color = Color3.fromRGB(22, 17, 30), Parent = m })
	part(brass({ Name = "Edge", Size = Vector3.new(FB.Width + 1, FB.Height + 1, 0.4), CFrame = cf, Parent = m }))
	for _, sx in ipairs({ -1, 1 }) do
		local h = FB.Bottom + FB.Height + 1
		part(brass({ Name = "Post", Size = Vector3.new(1, h, 1), CFrame = zn * CFrame.new(sx * (FB.Width / 2 + 0.9), h / 2, 0), Parent = m }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", 1.6 }, CFrame = zn * CFrame.new(sx * (FB.Width / 2 + 0.9), h + 0.8, 0), Color = C.LampHead, Material = Enum.Material.SmoothPlastic, Parent = m })
	end
	-- (7 Nov, rule: boards are placed with BoardPlacer) pivot = bottom-centre, LookVector = its front (to the Core); placed from
	-- the layout table (MapConfig.FreeBoard angle + dist) on the plaza's rim disc (r 70.75, centre = the Core), flat on the floor
	m.WorldPivot = zn * CFrame.Angles(0, math.pi, 0)
	m.Parent = centre
	local tools = game:GetService("ServerStorage"):FindFirstChild("Tools")
	local placer = tools and tools:FindFirstChild("BoardPlacer")
	local rim = centre:FindFirstChild("Rim")
	if placer and rim and rim:IsA("BasePart") then
		require(placer).place(m, rim, FB.angle, { margin = rim.Size.X / 2 - FB.dist, tiltBack = 0, groundY = O.Y })
	end
end

-- the plaza's lamp posts (9 tall): a pair at every bridge landing, and at the Sector 2 path, on the rim's flat top. Matte heads.
function Builder.PlazaLamps(centre: Instance)
	local CR, I, Z = MapConfig.Centre, MapConfig.Islands, MapConfig.Centre.Zones
	local landings = {}
	for slot = 1, I.Count do table.insert(landings, I.StartAngle + (slot - 1) * 360 / I.Count) end
	table.insert(landings, Z.Sector2.angle)
	local L = CR.Lamps
	for _, landing in ipairs(landings) do
		local spread = if landing == Z.Sector2.angle then L.Spread * 1.4 else L.Spread
		for _, side in ipairs({ -1, 1 }) do
			local p = O + MapConfig.ZoneDir(landing + side * spread) * L.Ring + UP * CR.Rim.Top
			Kit.Make("Pillar", brass({ Name = "LampPost", Fit = { "Y", L.Pillar }, CFrame = CFrame.new(p + UP * (L.Pillar / 2)), Collide = true, Parent = centre }))
			Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", L.Orb }, CFrame = CFrame.new(p + UP * (L.Pillar + L.Orb / 2)), Color = C.LampHead, Material = Enum.Material.SmoothPlastic, Parent = centre })
		end
	end
end

-- (7 Nov, owner "Plaza boards") a place built before: the star-chart inlay goes, the plaza's lamps are rebuilt on the rim with
-- matte heads, every other lamp head on the plaza goes matte, and FREE REWARDS is built if it's missing
function Builder.PlazaCleanup(root: Instance)
	local centre = root:FindFirstChild("Centre")
	if not centre then return end
	local det = centre:FindFirstChild("Details")
	for _, d in ipairs(det and det:GetChildren() or {}) do
		if d.Name == "ChartRing" or d.Name == "ChartStar" or d.Name == "ChartLine" then d:Destroy() end
	end
	local L = MapConfig.Centre.Lamps
	local post = centre:FindFirstChild("LampPost")
	if post and post:IsA("BasePart") and math.abs(Vector3.new(post.Position.X - O.X, 0, post.Position.Z - O.Z).Magnitude - L.Ring) > 0.2 then
		for _, c in ipairs(centre:GetChildren()) do
			if c.Name == "LampPost" or c.Name == "Lamp" then c:Destroy() end
		end
		Builder.PlazaLamps(centre)
	end
	for _, d in ipairs(centre:GetDescendants()) do
		if d.Name == "Lamp" and d:IsA("BasePart") and d.Material == Enum.Material.Neon then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = C.LampHead
		end
	end
	-- (7 Nov, owner: "the free reward board keeps moving to the front": a FREE REWARDS that's already in the place is never
	-- moved or rebuilt (the owner places it in Studio); it's only built when it's missing)
	Builder.FreeBoard(centre)
end

function Builder.Build()
	local old = workspace:FindFirstChild("Galaxy")
	if old then old:Destroy() end
	local root = Instance.new("Model")
	root.Name = "Galaxy"
	root:SetAttribute("StandIns", not Kit.AllImported())
	root.Parent = workspace

	-- the place's defaults out of the way (kept, not deleted)
	local keep = ServerStorage:FindFirstChild("PlaceDefaults") or Instance.new("Folder")
	keep.Name = "PlaceDefaults"
	keep.Parent = ServerStorage
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local x = workspace:FindFirstChild(name)
		if x and x.Parent == workspace and not x:GetAttribute("Galaxy") then x.Parent = keep end
	end

	------------------------------------------------------------------ the centre plaza
	local centre = Instance.new("Model")
	centre.Name = "Centre"
	centre.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	centre.Parent = root
	local CR = MapConfig.Centre
	local Z = CR.Zones
	local I = MapConfig.Islands
	local floor = Kit.Make("IslandTop", { Name = "Floor", Fit = { "X", CR.Floor.Fit }, CFrame = CFrame.new(O), Color = C.Stone, Collide = true, Parent = centre })
	local floorH = Kit.Fit("IslandTop", "X", CR.Floor.Fit).Y
	for _, p in ipairs(Kit.Parts(floor)) do p.CFrame = p.CFrame - UP * (floorH / 2) end
	local underSize = Kit.Fit("IslandUnder", "X", CR.Under.Fit)
	Kit.Make("IslandUnder", { Name = "Under", Fit = { "X", CR.Under.Fit }, CFrame = CFrame.new(O - UP * (floorH + underSize.Y / 2 - 0.3)) * CFrame.Angles(0.03, 0.9, -0.04),
		Color = C.Rock, Parent = centre })
	Kit.HangingCrystals(centre, O - UP * floorH, CR.Radius, underSize.Y, C.Crystal, 3)
	-- the brass rim (sticks up Rim.Top), the inlay round the Core's plaza, the tiles between
	local rimTube = Kit.Fit("RimRing", "X", CR.Rim.Fit).Y
	Kit.Make("RimRing", brass({ Name = "Rim", Fit = { "X", CR.Rim.Fit }, CFrame = CFrame.new(O + UP * (CR.Rim.Top - rimTube / 2)), Collide = true, Parent = centre }))
	local inlayTube = Kit.Fit("RimRing", "X", CR.Inlay.Radius * 2).Y
	Kit.Make("RimRing", brass({ Name = "Inlay", Fit = { "X", CR.Inlay.Radius * 2 }, CFrame = CFrame.new(O + UP * (CR.Inlay.Top - inlayTube / 2)), Parent = centre }))
	local tiles = Instance.new("Model")
	tiles.Name = "Tiles"
	tiles.Parent = centre
	Kit.TileRing(tiles, O, CR.Inlay.Radius + 0.8, CR.Radius - 3, CR.TileCount, C.Stone2, math.rad(I.StartAngle))
	Builder.PlazaLamps(centre)
	-- the stone thresholds over the rim where the bridges land
	local T = CR.Threshold
	local bridgeStart = {}
	for slot = 1, I.Count do
		local _, dir = Builder.IslandCenter(slot)
		bridgeStart[slot] = threshold(centre, O, dir, CR.Radius - T.In, CR.Radius + T.Out, T.Top, T.Thick, T.Ramp, I.Bridge.Width)
	end
	-- the hidden spawn (everyone is moved to their own island right away)
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SpawnLocation"
	spawnPad:SetAttribute("Galaxy", true)
	spawnPad.Size = Vector3.new(6, 0.2, 6)
	spawnPad.CFrame = CFrame.new(O + MapConfig.ZoneDir(90) * 30 + UP * 0.1)
	spawnPad.Anchored, spawnPad.CanCollide, spawnPad.Transparency, spawnPad.Neutral = true, false, 1, true
	spawnPad.Duration = 0
	local decal = spawnPad:FindFirstChildOfClass("Decal")
	if decal then decal:Destroy() end
	spawnPad.Parent = centre

	------------------------------------------------------------------ the Supernova Core
	-- a stepped altar, a brass collar, the star (10 across, its top ~20 up) with spikes, 3 gyroscope rings 18-22 across (the
	-- client turns them and pulses the star; it BURSTS when anyone goes Supernova)
	local K = CR.Core
	local core = Instance.new("Model")
	core.Name = "Core"
	core.Parent = centre
	local altarH = Kit.Fit("Altar", "X", K.Altar).Y
	Kit.Make("Altar", { Name = "Altar", Fit = { "X", K.Altar }, CFrame = CFrame.new(O + UP * (altarH / 2)), Color = C.Stone2, Collide = true, Parent = core })
	Kit.Make("RimRing", brass({ Name = "Collar", Fit = { "X", K.Collar }, CFrame = CFrame.new(O + UP * (altarH + 0.05)), Parent = core }))
	local corePos = O + UP * K.Height
	Kit.Make("CoreOrb", { Name = "CoreOrb", Fit = { "Y", K.Star }, CFrame = CFrame.new(corePos), Color = C.Core, Material = Enum.Material.Neon, Parent = core })
	local lightHost = part({ Name = "CoreLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(corePos), Transparency = 1, CanCollide = false, CanQuery = false, Parent = core })
	local light = Instance.new("PointLight")
	local LC = MapConfig.Lighting.Core
	light.Color, light.Range, light.Brightness, light.Shadows = LC.Color, LC.Range, LC.Brightness, false
	light.Parent = lightHost
	local rimHost = part({ Name = "RimLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.lookAt(corePos + Vector3.new(0, 2, -28), corePos + Vector3.new(0, 0, 14)),
		Transparency = 1, CanCollide = false, CanQuery = false, Parent = core })
	local rim = Instance.new("SpotLight")
	rim.Face, rim.Color, rim.Range, rim.Brightness, rim.Angle, rim.Shadows = Enum.NormalId.Front, Color3.fromRGB(170, 110, 255), 50, 2.5, 60, false
	rim.Parent = rimHost
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, K.Spikes - 1 do
		local y = 1 - (i + 0.5) / K.Spikes * 2
		local r = math.sqrt(1 - y * y)
		local th = golden * i
		local dir = Vector3.new(math.cos(th) * r, y, math.sin(th) * r)
		local len = K.Spike * (if i % 2 == 0 then 1 else 0.75)
		Kit.Make("CoreSpike", { Name = "Spike", Fit = { "Y", len }, CFrame = alongY(corePos + dir * (K.Star / 2 + len / 2 - 0.6), dir),
			Color = C.Spike, Material = Enum.Material.Neon, Parent = core })
	end
	for i, spec in ipairs(K.Gyros) do
		local ring = Kit.Make("GyroRing", brass({ Name = "Gyro" .. i, Fit = { "X", spec[1] * 2 },
			CFrame = CFrame.new(corePos) * CFrame.Angles(math.rad(spec[2]), math.rad(spec[3]), 0), Parent = core }))
		ring:SetAttribute("Spin", spec[4])
	end

	------------------------------------------------------------------ FRONT: the STAR SURGE bar (facing the Core)
	-- every Supernova in the server fills 5%; full = x2 stardust for everyone for 3 min (GalaxyStarSurgeService fills the labels)
	local S = MapConfig.StarSurge
	local surge = Instance.new("Model")
	surge.Name = "StarSurge"
	surge.Parent = centre
	local zs = zoneCf(Z.StarSurge.angle, Z.StarSurge.dist, true)
	local screenCf = zs * CFrame.new(0, S.Bottom + S.Height / 2, 0)
	local screen = part({ Name = "Screen", Size = Vector3.new(S.Width, S.Height, 0.3), CFrame = screenCf, Color = C.SignBack, CanCollide = false, Parent = surge })
	local backPlate = part(brass({ Name = "Back", Size = Vector3.new(S.Width + S.Frame * 2, S.Height + S.Frame * 2, S.Depth), CFrame = screenCf * CFrame.new(0, 0, -S.Depth / 2 - 0.1), Parent = surge }))
	-- (its back, seen from the islands: the name, so it's not a blank plate)
	label(surface(backPlate, Enum.NormalId.Front), "STAR SURGE", UDim2.fromScale(0.08, 0.3), UDim2.fromScale(0.84, 0.4), Color3.fromRGB(60, 30, 10))
	for _, sx in ipairs({ -1, 1 }) do
		local h = S.Bottom + S.Height + S.Frame
		part(brass({ Name = "Post", Size = Vector3.new(0.9, h, 0.9), CFrame = zs * CFrame.new(sx * (S.Width / 2 + S.Frame / 2), h / 2, -S.Depth / 2), Parent = surge }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", 1.6 }, CFrame = zs * CFrame.new(sx * (S.Width / 2 + S.Frame / 2), h + 0.8, -S.Depth / 2), Color = C.LampHead, Material = Enum.Material.SmoothPlastic, Parent = surge })
	end
	local sg = surface(screen, Enum.NormalId.Back)
	sg.Name = "Surge"
	label(sg, "STAR SURGE", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.3), Color3.fromRGB(255, 214, 120)).Name = "Title"
	local barBack = Instance.new("Frame")
	barBack.Name = "Bar"
	barBack.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
	barBack.BorderSizePixel = 0
	barBack.Position = UDim2.fromScale(0.05, 0.38)
	barBack.Size = UDim2.fromScale(0.9, 0.24)
	barBack.Parent = sg
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0.3, 0)
	bc.Parent = barBack
	local bs = Instance.new("UIStroke")
	bs.Color, bs.Thickness = C.Brass, 6
	bs.Parent = barBack
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	fill.Parent = barBack
	bc:Clone().Parent = fill
	local fg = Instance.new("UIGradient")
	fg.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 120, 40))
	fg.Parent = fill
	label(barBack, "0%", UDim2.fromScale(0, 0.1), UDim2.fromScale(1, 0.8), Color3.new(1, 1, 1)).Name = "Pct"
	label(sg, "Every Supernova in the server fills 5%", UDim2.fromScale(0.05, 0.66), UDim2.fromScale(0.9, 0.15), Color3.fromRGB(225, 215, 240), FONT_B).Name = "Status"
	label(sg, "", UDim2.fromScale(0.05, 0.82), UDim2.fromScale(0.9, 0.13), Color3.fromRGB(150, 220, 255), FONT_B).Name = "Last"

	------------------------------------------------------------------ RIGHT: the Star Forge (facing the Core)
	-- locked until Supernova 3: the padlock hangs on the anvil's front face; the sign stands in front on the plaza side
	local F = MapConfig.Forge
	local forge = Instance.new("Model")
	forge.Name = "StarForge"
	forge:SetAttribute("Window", "Forge")
	forge.Parent = centre
	local zf = zoneCf(Z.Forge.angle, Z.Forge.dist, true)
	local platH = Kit.Fit("Dais", "X", F.Platform).Y
	Kit.Make("Dais", { Name = "Platform", Fit = { "X", F.Platform }, CFrame = zf * CFrame.new(0, platH / 2, 0), Color = C.Stone2, Collide = true, Parent = forge })
	Kit.Make("RimRing", { Name = "Rim", Fit = { "X", F.Rim }, CFrame = zf * CFrame.new(0, platH + 0.05, 0), Color = C.ForgeRim, Parent = forge })
	local anvil = Kit.Fit("Anvil", "X", F.Anvil)
	Kit.Make("Anvil", { Name = "Anvil", Fit = { "X", F.Anvil }, CFrame = zf * CFrame.new(0, platH + anvil.Y / 2, 0), Color = C.Steel, Reflectance = 0.1, Collide = true, Parent = forge })
	local lock = Kit.Fit("Padlock", "Y", F.Padlock)
	-- (on the front face: the face toward the Core is at +Z = anvil.Z / 2; hung on the upper part, the anvil's face block)
	Kit.Make("Padlock", { Name = "Padlock", Fit = { "Y", F.Padlock }, CFrame = zf * CFrame.new(anvil.X * 0.08, platH + anvil.Y - lock.Y / 2 - 0.25, anvil.Z / 2 + lock.Z / 2),
		Color = C.Lock, Reflectance = 0.1, Parent = forge })
	-- (6 Nov: the Forge opens at IGNITION 1 since 5 Nov; was "SUPERNOVA 3")
	sign(forge, "Sign", zf * CFrame.new(0, 0, F.Sign.Dist), F.Sign.Width, F.Sign.Height, F.Sign.Bottom, { "STAR FORGE", "IGNITION 1" }, nil, true)

	------------------------------------------------------------------ BACK: the Black Hole gate (facing the Core)
	-- a 22-wide brass ring on its dais round an OPAQUE void, a glowing inner ring, 3 spiral arms and particles drawn inward
	-- (the client turns the arms, the glow and the disk); the sign stands in front on the plaza side
	local B = MapConfig.BlackHole
	local hole = Instance.new("Model")
	hole.Name = "BlackHoleGate"
	hole:SetAttribute("Window", "BlackHole") -- (3.1: its prompt opens the BLACK HOLE window, GalaxyMapService)
	hole.Parent = centre
	local zh = zoneCf(Z.BlackHole.angle, Z.BlackHole.dist, true)
	local daisH = Kit.Fit("Dais", "X", B.Dais).Y
	Kit.Make("Dais", { Name = "Base", Fit = { "X", B.Dais }, CFrame = zh * CFrame.new(0, daisH / 2, 0), Color = C.Stone2, Collide = true, Parent = hole })
	local ringCf = zh * CFrame.new(0, daisH + B.Ring / 2 - 0.6, 0) * CFrame.Angles(math.rad(90), 0, 0) -- (the ring's axis = its local Y = toward the Core)
	Kit.Make("GateRing", brass({ Name = "Ring", Fit = { "X", B.Ring }, CFrame = ringCf, Collide = true, Parent = hole }))
	local voidD = B.Ring * B.VoidShare
	part({ Name = "Void", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, voidD, voidD), CFrame = ringCf * CFrame.Angles(0, 0, math.rad(90)), Color = C.Void,
		CanCollide = true, Parent = hole })
	local disk = Kit.Make("OrbitRing", { Name = "Disk", Fit = { "X", voidD * 0.92 }, CFrame = ringCf, Color = C.VoidGlow, Material = Enum.Material.Neon, Parent = hole })
	disk:SetAttribute("Swirl", 0.6)
	local arms = Instance.new("Model")
	arms.Name = "Arms"
	arms:SetAttribute("Swirl", -0.55)
	arms.Parent = hole
	local inner, outerR = 1.6, voidD / 2 - 1
	for arm = 0, B.Arms - 1 do
		local prev
		for j = 0, B.ArmSteps do
			local t = j / B.ArmSteps
			local rr = inner + (outerR - inner) * t
			local th = arm * math.pi * 2 / B.Arms + t * math.pi * 1.6
			local pt = (ringCf * CFrame.new(math.cos(th) * rr, 0, math.sin(th) * rr)).Position
			if prev then
				part({ Name = "Arm", Size = Vector3.new(B.ArmWidth * (1 - 0.65 * t), 1.1, (pt - prev).Magnitude + 0.3), CFrame = CFrame.lookAt((prev + pt) / 2, pt, ringCf.UpVector),
					Color = Color3.fromRGB(255, 140, 230):Lerp(Color3.fromRGB(150, 70, 255), t), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = arms })
			end
			prev = pt
		end
	end
	local glow = Kit.Make("GateRing", { Name = "InnerGlow", Fit = { "X", inner * 2 + 2.4 }, CFrame = ringCf, Color = Color3.fromRGB(255, 170, 240), Material = Enum.Material.Neon, Parent = hole })
	glow:SetAttribute("Swirl", 1.2)
	local pull = part({ Name = "Pull", Size = Vector3.new(voidD - 1, 0.2, voidD - 1), CFrame = ringCf, Transparency = 1, CanCollide = false, CanQuery = false, Parent = hole })
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = require(Galaxy:WaitForChild("VfxTextures")).alpha.stardust_mote -- (the VFX pass: our stardust mote, #281; 7 Nov: _alpha)
	pe.Shape, pe.ShapeInOut, pe.ShapeStyle = Enum.ParticleEmitterShape.Disc, Enum.ParticleEmitterShapeInOut.Inward, Enum.ParticleEmitterShapeStyle.Surface
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 170, 240), Color3.fromRGB(150, 90, 255))
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(1, 1.2)
	pe.Speed = NumberRange.new(outerR / 1.1)
	pe.RotSpeed = NumberRange.new(-90, 90)
	pe.Rate = 30
	pe.Parent = pull
	local gl = Instance.new("PointLight")
	gl.Color, gl.Range, gl.Brightness, gl.Shadows = Color3.fromRGB(190, 110, 255), 20, 1.4, false
	gl.Parent = pull
	hole:SetAttribute("RingCF", ringCf)
	sign(hole, "Sign", zh * CFrame.new(0, 0, B.Sign.Dist), B.Sign.Width, B.Sign.Height, B.Sign.Bottom, { "BLACK HOLE", "100K SHARDS" }, Color3.fromRGB(200, 150, 255), true)

	Builder.Leaderboards(centre)

	------------------------------------------------------------------ the gaps: benches, crystals (7 Nov: no star-chart inlay)
	local D = CR.Details
	local details = Instance.new("Model")
	details.Name = "Details"
	details.Parent = centre
	for _, angle in ipairs(CR.Gaps) do
		local out = MapConfig.ZoneDir(angle)
		for _, side in ipairs({ -1, 1 }) do
			local bf = faceTo(O + out * D.Benches + MapConfig.ZoneDir(angle + 90) * side * D.BenchSpread, O)
			part({ Name = "BenchSeat", Size = Vector3.new(5, 0.5, 1.6), CFrame = bf * CFrame.new(0, 1.6, 0), Color = C.Stone2, Parent = details })
			part({ Name = "BenchBack", Size = Vector3.new(5, 1.4, 0.35), CFrame = bf * CFrame.new(0, 2.5, -0.65), Color = C.Stone2, Parent = details })
			for _, leg in ipairs({ -1.9, 1.9 }) do
				part(brass({ Name = "BenchLeg", Size = Vector3.new(0.45, 1.35, 1.2), CFrame = bf * CFrame.new(leg, 0.68, 0), Parent = details }))
			end
			local cr = O + out * D.RimCrystals + MapConfig.ZoneDir(angle + 90) * side * 9
			Kit.Make("CrystalCluster", { Fit = { "Y", if side < 0 then 4 else 5.5 }, CFrame = CFrame.new(cr + UP * (if side < 0 then 2 else 2.75)) * CFrame.Angles(0, math.rad(angle + side * 40), 0),
				Color = C.Crystal, Reflectance = 0.15, Parent = details })
		end
		Kit.Make("CrystalCluster", { Fit = { "Y", 8 }, CFrame = CFrame.new(O + out * (D.RimCrystals + 1) + UP * 4) * CFrame.Angles(0, math.rad(angle), 0), Color = C.Crystal, Reflectance = 0.15, Parent = details })
	end

	------------------------------------------------------------------ the 8 island slots + their bridges
	local islands = Instance.new("Folder")
	islands.Name = "Islands"
	islands.Parent = root
	local LD = I.Landing
	for slot = 1, I.Count do
		local center, dir, a = Builder.IslandCenter(slot)
		local island = Instance.new("Model")
		island.Name = "Island_" .. slot
		island:SetAttribute("Slot", slot)
		island:SetAttribute("Center", center)
		island:SetAttribute("Angle", a)
		island:SetAttribute("Owner", 0)
		island:SetAttribute("Tier", 0)
		island.Parent = islands
		local anchor = part({ Name = "Anchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(center), Transparency = 1, CanCollide = false, CanQuery = false, Parent = island })
		island.PrimaryPart = anchor
		-- the island's own threshold over its rim, from the bridge in toward the island (ramp down onto the floor)
		local landing = Instance.new("Model")
		landing.Name = "Landing"
		landing.Parent = island
		local islandEnd = threshold(landing, center, -dir, -LD.To, -LD.From, LD.Top, I.Bridge.Thick, LD.Ramp, I.Bridge.Width)
		bridge(island, bridgeStart[slot], islandEnd, I.Bridge.Segments, I.Bridge.Width, I.Bridge.Arch, C.BridgeDim, "Bridge")
		local pieces = Instance.new("Folder")
		pieces.Name = "Pieces"
		pieces.Parent = island
		-- the free slot's dim bare rock + its landing (GalaxyMapService's tier 0 = the same pieces): a bridge never leads into
		-- empty space, not even in Edit mode
		Builder.RockPieces(island, center, dir, slot, false).Parent = pieces
		island.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end

	------------------------------------------------------------------ BACK-LEFT: the Sector 2 arch, IGNITION, bridge, island
	local NS = MapConfig.NextSector
	local S2 = MapConfig.Sector2
	local nextS = Instance.new("Model")
	nextS.Name = "NextSector"
	nextS.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	nextS.Parent = root
	local N = O + NS.Position
	local nsDir = MapConfig.ZoneDir(NS.Angle)
	local nsFloorH = Kit.Fit("IslandTop", "X", NS.Radius * 2).Y
	local nsFloor = Kit.Make("IslandTop", { Name = "Floor", Fit = { "X", NS.Radius * 2 }, CFrame = CFrame.new(N - UP * (nsFloorH / 2)), Color = C.Stone, Collide = true, Parent = nextS })
	local _ = nsFloor
	local nsUnder = Kit.Fit("IslandUnder", "X", NS.Radius * 2)
	Kit.Make("IslandUnder", { Name = "Under", Fit = { "X", NS.Radius * 2 }, CFrame = CFrame.new(N - UP * (nsFloorH + nsUnder.Y / 2 - 0.3)), Color = C.Rock, Parent = nextS })
	local rnd = Random.new(4)
	for _ = 1, 7 do
		local at = N + Vector3.new(rnd:NextNumber(-20, 20), 0, rnd:NextNumber(-20, 20))
		local h = rnd:NextNumber(NS.Crystals[1], NS.Crystals[2])
		Kit.Make("Crystal", { Name = "Crystal", Fit = { "Y", h }, CFrame = CFrame.new(at + UP * (h / 2 - 0.3)) * CFrame.Angles(rnd:NextNumber(-0.25, 0.25), rnd:NextNumber(0, 6), rnd:NextNumber(-0.25, 0.25)),
			Color = C.Ice, Reflectance = 0.2, Parent = nextS })
	end
	Kit.Make("Padlock", { Name = "Padlock", Fit = { "Y", NS.Padlock }, CFrame = CFrame.new(N + UP * 14), Color = C.Lock, Reflectance = 0.1, Parent = nextS })
	-- the bridge: from its threshold over the plaza's rim to the island's edge, brass rails both sides
	local A = threshold(centre, O, nsDir, CR.Radius - T.In, CR.Radius + T.Out, T.Top, T.Thick, T.Ramp, NS.BridgeWidth)
	local Bp = N - nsDir * (NS.Radius - 1.5)
	bridge(nextS, A, Bp, NS.BridgeSegments, NS.BridgeWidth, NS.Arch, C.BridgeDim, "Bridge")
	-- the gate arch on the plaza at the path's end (its +Z faces the Core), the name on top (both sides), the barrier
	local gatePos = O + nsDir * Z.Sector2.dist
	local gateCf = faceTo(gatePos, O)
	local arch = Kit.Fit("GateArch", "X", S2.Arch)
	Kit.Make("GateArch", brass({ Name = "Arch", Fit = { "X", S2.Arch }, CFrame = gateCf * CFrame.new(0, arch.Y / 2, 0), Collide = true, Parent = nextS }))
	local nameCf = gateCf * CFrame.new(0, arch.Y + S2.NameSign.Height / 2 + 0.4, 0)
	local archSign = part({ Name = "ArchSign", Size = Vector3.new(S2.NameSign.Width, S2.NameSign.Height, 0.3), CFrame = nameCf, Color = C.SignBack, CanCollide = false, CanQuery = false, Parent = nextS })
	for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Front }) do
		label(surface(archSign, face), NS.Name, UDim2.fromScale(0.03, 0.1), UDim2.fromScale(0.94, 0.8), Color3.fromRGB(150, 220, 255))
	end
	part(brass({ Name = "ArchSignEdge", Size = archSign.Size + Vector3.new(0.5, 0.5, -0.1), CFrame = nameCf, CanCollide = false, CanQuery = false, Parent = nextS }))
	part(brass({ Name = "ArchSignPost", Size = Vector3.new(0.6, 0.8, 0.6), CFrame = gateCf * CFrame.new(0, arch.Y + 0.2, 0), Parent = nextS }))
	part({ Name = "Barrier", Size = Vector3.new(S2.Arch, arch.Y, 1), CFrame = gateCf * CFrame.new(0, arch.Y / 2, 0), Transparency = 1, CanCollide = true, CanQuery = false, Parent = nextS })
	-- IGNITION: on its posts on the plaza beside the arch, facing the Core, the checklist on both sides
	local IG = S2.Ignition
	local signPos = O + MapConfig.ZoneDir(IG.Angle) * IG.Dist
	local ign = sign(nextS, "IgnitionSign", faceTo(signPos, O), IG.Width, IG.Height, IG.Bottom, { "IGNITION" }, Color3.fromRGB(255, 200, 110), true)
	for _, gui in ipairs(ign:GetChildren()) do
		if not gui:IsA("SurfaceGui") then continue end
		local title = gui:FindFirstChildOfClass("TextLabel")
		if title then title.Size = UDim2.fromScale(0.92, 0.18) title.Position = UDim2.fromScale(0.04, 0.03) end
		for i, item in ipairs(MapConfig.Ignition) do
			local row = label(gui, "[  ]  " .. item.text, UDim2.fromScale(0.05, 0.24 + (i - 1) * 0.185), UDim2.fromScale(0.9, 0.17), Color3.fromRGB(200, 190, 220), FONT_B, Enum.TextXAlignment.Left)
			row.Name = "Row" .. i
			row.TextWrapped = true
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize = 36
			cap.Parent = row
		end
	end

	------------------------------------------------------------------ sky + lighting (MapConfig.Sky, MapConfig.Lighting)
	local keepL = ServerStorage:FindFirstChild("LightingDefaults") or Instance.new("Folder")
	keepL.Name = "LightingDefaults"
	keepL.Parent = ServerStorage
	for _, name in ipairs({ "SunRays", "DepthOfField" }) do
		local x = Lighting:FindFirstChild(name)
		if x then x.Parent = keepL end
	end
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	for key, v in pairs(MapConfig.Sky) do sky[key] = v end
	sky.CelestialBodiesShown = false
	sky.StarCount = 0
	sky.Parent = Lighting
	require(Galaxy:WaitForChild("GalaxyLighting")).Apply()

	local count = 0
	for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then count += 1 end end
	root:SetAttribute("Parts", count)
	Builder.FreeBoard(centre)
	Builder.ClearDecor(root)
	return root
end

-- tier 0 / a free slot: a bare asteroid at the island's centre + a landing from the island threshold to it. `owned` = lit,
-- and (a new player) the walkway runs on across the lowered rock to a stone pad under the boards.
function Builder.RockPieces(island: Instance, center: Vector3, dir: Vector3, slot: number, owned: boolean): Model
	local I = MapConfig.Islands
	local t0 = Instance.new("Model")
	t0.Name = "T0"
	t0:SetAttribute("Owned", owned)
	local rock = Kit.Fit("RockBare", "X", I.Rock)
	local top = if owned then -0.3 else 1.5 -- (owned: under the walkway)
	Kit.Make("RockBare", { Name = "Rock", Fit = { "X", I.Rock }, CFrame = CFrame.new(center + UP * (top - rock.Y / 2)) * CFrame.Angles(0, slot * 0.7, 0),
		Color = if owned then C.BareRock else C.BareRock:Lerp(Color3.new(0, 0, 0), 0.45), Collide = true, Parent = t0 })
	local from = Builder.IslandPoint(center, dir, Vector3.new(I.Landing.To + I.Landing.Ramp, 0, 0))
	local to = Builder.IslandPoint(center, dir, Vector3.new(if owned then I.RockPad.WalkTo else -I.Rock * 0.38, 0, 0))
	part({ Name = "Landing", Size = Vector3.new(I.Bridge.Width, I.Bridge.Thick, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to) * CFrame.new(0, -I.Bridge.Thick / 2 + 0.05, 0),
		Color = if owned then C.Bridge else C.BridgeDim, Material = if owned then Enum.Material.Neon else Enum.Material.SmoothPlastic, CanCollide = true, Parent = t0 })
	if owned then
		local pad = I.RockPad
		local padH = Kit.Fit("IslandTop", "X", pad.Fit).Y
		local at = Builder.IslandPoint(center, dir, pad.At)
		Kit.Make("IslandTop", { Name = "BoardPad", Fit = { "X", pad.Fit }, CFrame = CFrame.lookAt(at - UP * (padH / 2), at - UP * (padH / 2) + dir), Color = C.Stone, Collide = true, Parent = t0 })
		local under = Kit.Fit("IslandUnder", "X", pad.Fit)
		Kit.Make("IslandUnder", { Name = "PadUnder", Fit = { "X", pad.Fit }, CFrame = CFrame.new(at - UP * (padH + under.Y / 2 - 0.3)) * CFrame.Angles(0, slot, 0), Color = C.Rock, Parent = t0 })
		-- a pad under each side board (Bodies, Star Upgrades), touching the rock: the tutorial's first buy is on the Bodies board
		local SP = I.SidePads
		local sideH = Kit.Fit("IslandTop", "X", SP.Fit).Y
		local sideUnder = Kit.Fit("IslandUnder", "X", SP.Fit)
		for _, b in ipairs(MapConfig.Boards.List) do
			if b.At then
				local p = Builder.IslandPoint(center, dir, b.At - b.At.Unit * SP.In)
				Kit.Make("IslandTop", { Name = "BoardPad", Fit = { "X", SP.Fit }, CFrame = CFrame.lookAt(p - UP * (sideH / 2), p - UP * (sideH / 2) + dir), Color = C.Stone, Collide = true, Parent = t0 })
				Kit.Make("IslandUnder", { Name = "PadUnder", Fit = { "X", SP.Fit }, CFrame = CFrame.new(p - UP * (sideH + sideUnder.Y / 2 - 0.3)) * CFrame.Angles(0, slot + b.At.Z, 0), Color = C.Rock, Parent = t0 })
			end
		end
	end
	local _ = island
	return t0
end

-- the island boards' places (MapConfig.Boards): [id] = the centre of the board's SCREEN, +Z toward the player (the screen's
-- Back face carries the live SurfaceGui). The pair stands upright in a shallow V (each turned Pair.V in toward the player,
-- their inner frame edges Pair.Gap apart); the side boards face the island's centre, tilted back Tilt on their stand.
function Builder.BoardCFrames(center: Vector3, dir: Vector3): { [string]: CFrame }
	local B = MapConfig.Boards
	local P = B.Pair
	local function world(v: Vector3): Vector3 return Builder.IslandPoint(center, dir, v) end
	local function along(v: Vector3): Vector3 return world(v) - world(Vector3.zero) end
	local out = {}
	for _, b in ipairs(B.List) do
		if b.pair then
			local v, side = math.rad(P.V), b.pair
			local lateral = Vector3.new(-math.sin(v), 0, side * math.cos(v)) -- (along the board, from the gap outward)
			local normal = Vector3.new(-math.cos(v), 0, -side * math.sin(v)) -- (its face, toward the player)
			local base = world(P.At + Vector3.new(0, 0, side * P.Gap / 2) + lateral * Builder.BoardHalfWidth(b))
			local n = along(normal)
			out[b.id] = CFrame.lookAt(base, base - n) * CFrame.new(0, P.Bottom + b.Height / 2, 0)
		else
			local base = faceTo(world(b.At), center)
			out[b.id] = base * CFrame.new(0, b.Bottom, 0) * CFrame.Angles(math.rad(-b.Tilt), 0, 0) * CFrame.new(0, b.Height / 2, 0)
		end
	end
	return out
end

-- one board's frame (MapConfig.Boards; boards 1:1 pass 2). Every board: the dark screen (its SurfaceGui is the client's).
--  * the pair (Regrowth's Perks Tree / Info): a thick lavender stone frame round a lighter lip (the bevel), side posts with
--    round caps and brass bands from the ledge to above the top, set INTO a low stone ledge (no legs). Its BACK (pass 3):
--    a lavender panel with a brass trim and a gold emblem: the big star on the Tree, the owner's name plate on Info
--  * Style "Neon" (Bodies = Regrowth's Machines, Star Upgrades = Factory Upgrades): a thin angular frame, wider at the top
--    (MapConfig.Boards.Angular): lavender tubes with a neon tube on their front, ball joints, a neon glow strip on top;
--    two struts + a slab on the ground
--  * else (not used now): the chunky 1.2 frame with rounded outer corners and a brass trim; two legs
-- (The screens' own rounded corners, in the frame's colour, are drawn by their UI.)
local function flatOf(cf: CFrame): CFrame
	return CFrame.lookAt(cf.Position, cf.Position + Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z))
end
-- two legs up the back of a tilted board, leaning with it, from the floor to 2 studs under its top; a brass foot each
local function legs(parent: Instance, cf: CFrame, w: number, h: number, back: number, floorY: number, thick: number)
	local B = MapConfig.Boards
	local up = cf.UpVector
	for _, sx in ipairs({ -1, 1 }) do
		local top = (cf * CFrame.new(sx * (w / 2 - 2), h / 2 - 2, -back)).Position
		local reach = (top.Y - floorY) / up.Y
		local bottom = top - up * reach
		part({ Name = "Leg", Size = Vector3.new(thick, reach + 0.6, thick), CFrame = CFrame.fromMatrix((top + bottom) / 2, cf.RightVector, up), Color = B.StoneDark, CanCollide = true, Parent = parent })
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		part(brass({ Name = "Foot", Size = Vector3.new(1.8, 0.5, 2.6), CFrame = CFrame.lookAt(bottom + UP * 0.2, bottom + UP * 0.2 + look), CanCollide = true, Parent = parent }))
	end
end
function Builder.BoardFrame(parent: Instance, cf: CFrame, spec, floorY: number, ownerName: string?)
	local B = MapConfig.Boards
	local w, h = spec.Width, spec.Height
	local function stone(props)
		props.Color = props.Color or B.Stone
		props.CanCollide = if props.CanCollide == nil then true else props.CanCollide
		props.Parent = parent
		return part(props)
	end
	-- a straight piece from a to b in the board's plane (board-local x, y), z out of it
	local function piece(a: Vector2, b: Vector2, thick: number, depth: number, z: number, props)
		local d = b - a
		local mid = (a + b) / 2
		props.Size = Vector3.new(d.Magnitude, thick, depth)
		props.CFrame = cf * CFrame.new(mid.X, mid.Y, z) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X))
		return stone(props)
	end
	part({ Name = "Screen", Size = Vector3.new(w, h, 0.2), CFrame = cf * CFrame.new(0, 0, 0.1), Color = B.Screen, CanCollide = false, Parent = parent })
	if spec.pair then
		local P = B.Pair
		local L, T, Lo, Po, D = P.Lip, P.Bar, P.BarLow, P.Post, P.Depth
		stone({ Name = "BackPlate", Size = Vector3.new(w + 2 * L, h + 2 * L, 0.4), CFrame = cf * CFrame.new(0, 0, -D / 2 + 0.2), Color = B.StoneDark })
		-- the lip: a lighter step 0.4 back from the frame's front, round the screen (the bevel)
		for _, s in ipairs({ -1, 1 }) do
			stone({ Name = "Lip", Size = Vector3.new(w + 2 * L, L, D - 0.4), CFrame = cf * CFrame.new(0, s * (h / 2 + L / 2), -0.2), Color = B.StoneLight })
			stone({ Name = "Lip", Size = Vector3.new(L, h, D - 0.4), CFrame = cf * CFrame.new(s * (w / 2 + L / 2), 0, -0.2), Color = B.StoneLight })
		end
		-- the thick top bar, the low bottom bar (on the ledge), the side posts from the ledge to above the top
		local top = h / 2 + L
		local foot = -h / 2 - L - Lo -- (the ledge's top, board-local)
		local head = top + T + 0.3
		stone({ Name = "TopBar", Size = Vector3.new(w + 2 * L, T, D), CFrame = cf * CFrame.new(0, top + T / 2, 0) })
		stone({ Name = "BottomBar", Size = Vector3.new(w + 2 * L, Lo, D), CFrame = cf * CFrame.new(0, foot + Lo / 2, 0) })
		part(brass({ Name = "Trim", Size = Vector3.new(w + 2 * L, 0.2, 0.1), CFrame = cf * CFrame.new(0, top + 0.12, D / 2 + 0.04), Parent = parent }))
		for _, s in ipairs({ -1, 1 }) do
			local x = s * (w / 2 + L + Po / 2)
			stone({ Name = "Post", Size = Vector3.new(Po, head - foot, P.PostDepth), CFrame = cf * CFrame.new(x, (head + foot) / 2, 0) })
			stone({ Name = "PostCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(P.PostDepth, Po, Po), CFrame = cf * CFrame.new(x, head, 0) * CFrame.Angles(0, math.pi / 2, 0) })
			for _, y in ipairs({ top - 0.8, -h / 2 + 0.8 }) do
				part(brass({ Name = "Band", Size = Vector3.new(Po + 0.08, 0.3, P.PostDepth + 0.08), CFrame = cf * CFrame.new(x, y, 0), Parent = parent }))
			end
		end
		-- the low stone ledge the panel is set into (to the floor), with a lighter cap
		local flat = flatOf(cf)
		local ledgeTop = (cf * CFrame.new(0, foot, 0)).Position.Y
		local width = w + 2 * L + 2 * Po + 0.6
		local mid = (flat * CFrame.new(0, 0, 0.5)).Position
		stone({ Name = "Ledge", Size = Vector3.new(width, ledgeTop - floorY, P.LedgeDepth), CFrame = flat - flat.Position + Vector3.new(mid.X, (ledgeTop + floorY) / 2, mid.Z) })
		stone({ Name = "LedgeCap", Size = Vector3.new(width + 0.3, 0.3, P.LedgeDepth + 0.3), CFrame = flat - flat.Position + Vector3.new(mid.X, ledgeTop - 0.1, mid.Z), Color = B.StoneLight })
		Builder.BoardBack(parent, cf * CFrame.new(0, 0, -D / 2 - 0.15), w + 2 * L, h + 2 * L, spec.id, ownerName)
	elseif spec.Style == "Neon" then
		local G = B.Angular
		local bl, br = Vector2.new(-w / 2 - G.Low, -h / 2 - G.Low), Vector2.new(w / 2 + G.Low, -h / 2 - G.Low)
		local tl, tr = Vector2.new(-w / 2 - G.Wide, h / 2 + G.High), Vector2.new(w / 2 + G.Wide, h / 2 + G.High)
		stone({ Name = "BackPlate", Size = Vector3.new(w + 0.8, h + 0.8, 0.3), CFrame = cf * CFrame.new(0, 0, -0.25), Color = B.Screen })
		for _, seg in ipairs({ { bl, br }, { br, tr }, { tr, tl }, { tl, bl } }) do
			piece(seg[1], seg[2], 0.55, 0.6, 0, { Name = "Tube" })
			-- (the neon edge is in front of the screen's plane: never in the way of a click / tap ray)
			piece(seg[1], seg[2], 0.2, 0.2, 0.36, { Name = "NeonTube", Color = spec.Neon, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false })
		end
		for _, p in ipairs({ bl, br, tl, tr }) do
			stone({ Name = "Joint", Shape = Enum.PartType.Ball, Size = Vector3.new(0.85, 0.85, 0.85), CFrame = cf * CFrame.new(p.X, p.Y, 0) })
		end
		piece(Vector2.new(-w * 0.34, h / 2 + 1.2), Vector2.new(w * 0.34, h / 2 + 1.2), 0.3, 0.35, 0, { Name = "GlowStrip", Color = spec.Neon, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false })
		Builder.BoardBack(parent, cf * CFrame.new(0, 0, -0.55), w + 0.8, h + 0.8, spec.id, nil)
		legs(parent, cf, w, h, 0.75, floorY, 0.8)
		local flat = flatOf(cf)
		local under = (flat * CFrame.new(0, 0, -1)).Position
		stone({ Name = "Slab", Size = Vector3.new(w * 0.7, 0.4, 3.6), CFrame = flat - flat.Position + Vector3.new(under.X, floorY + 0.2, under.Z), Color = B.StoneDark })
	else
		local F, D = B.Frame, B.Depth
		stone({ Name = "BackPlate", Size = Vector3.new(w, h, 0.4), CFrame = cf * CFrame.new(0, 0, -D / 2 + 0.2), Color = B.StoneDark })
		-- (7 Nov, rule 8 ONE FRAME: the STAR FORGE / BLACK HOLE boards show framed art (the chained sign): no stone frame round it)
		for _, s in ipairs(if spec.locked then {} else { -1, 1 }) do
			-- the bars run half a frame past the screen; a round (frame-thick) fills each outer corner
			stone({ Name = "FrameBar", Size = Vector3.new(w + F, F, D), CFrame = cf * CFrame.new(0, s * (h / 2 + F / 2), 0) })
			stone({ Name = "FrameBar", Size = Vector3.new(F, h + F, D), CFrame = cf * CFrame.new(s * (w / 2 + F / 2), 0, 0) })
			for _, t in ipairs({ -1, 1 }) do
				stone({ Name = "FrameCorner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(D, F, F),
					CFrame = cf * CFrame.new(s * (w / 2 + F / 2), t * (h / 2 + F / 2), 0) * CFrame.Angles(0, math.pi / 2, 0) })
			end
			part(brass({ Name = "Trim", Size = Vector3.new(w + 0.44, 0.22, 0.12), CFrame = cf * CFrame.new(0, s * (h / 2 + 0.11), D / 2 + 0.05), Parent = parent }))
			part(brass({ Name = "Trim", Size = Vector3.new(0.22, h + 0.44, 0.12), CFrame = cf * CFrame.new(s * (w / 2 + 0.11), 0, D / 2 + 0.05), Parent = parent }))
		end
		legs(parent, cf, w, h, D / 2 + 0.55, floorY, 1.1)
	end
end

-- the island's BOARDS (moved from GalaxyMapService, 7 Nov, so Tools/BoardPreview builds the same ones in Edit): + its AREA
-- (BoardPlacer's disc) with the ISLANDSPAWN. `into` = where they go (default: the island; the preview: its own folder)
local function centerOf(island: Model): (Vector3, Vector3, number)
	local c = island:GetAttribute("Center") :: Vector3
	local a = island:GetAttribute("Angle") :: number
	return c, Vector3.new(math.cos(a), 0, math.sin(a)), a
end
local function at(island: Model, x: number, z: number, y: number?): Vector3
	local c, dir = centerOf(island)
	return Builder.IslandPoint(c, dir, Vector3.new(x, y or 0, z))
end
local function islandArea(island: Model, holder: Instance): BasePart
	local name = island.Name .. "_Area"
	local area = island:FindFirstChild(name) or holder:FindFirstChild(name)
	if area then return area end
	local c = centerOf(island)
	area = Builder.part({ Name = name, Size = Vector3.new(2 * MapConfig.Islands.Radius, 1, 2 * MapConfig.Islands.Radius), CFrame = CFrame.new(c - Vector3.new(0, 0.5, 0)), Transparency = 1,
		CanCollide = false, CanQuery = false, Parent = holder })
	Builder.part({ Name = "IslandSpawn", Size = Vector3.new(4, 1, 4), CFrame = CFrame.new(at(island, -(MapConfig.Islands.Radius - 6), 0, 0.5)), Transparency = 1,
		CanCollide = false, CanQuery = false, Parent = area })
	return area
end
-- the boards: built where the old geometry put them (so each frame is whole), given a bottom-centre pivot that looks at the
-- player (front = LookVector), then PLACED BY BoardPlacer from MapConfig.Boards.Layout. (The pair's old gap ledge is gone:
-- the pair now stands 30 deg apart round the rim.)
function Builder.IslandBoards(island: Model, into: Instance?)
	local holder = into or island
	local old = holder:FindFirstChild("Boards")
	if old then return old end
	local c, dir = centerOf(island)
	local area = islandArea(island, holder)
	local cfs = Builder.BoardCFrames(c, dir)
	local L = MapConfig.Boards.Layout
	local BoardPlacer = require(ServerStorage:WaitForChild("Tools"):WaitForChild("BoardPlacer"))
	local model = Instance.new("Model")
	model.Name = "Boards"
	model.Parent = holder
	local placed = {}
	for _, spec in ipairs(MapConfig.Boards.List) do
		local panel = Instance.new("Model")
		panel.Name = "Board_" .. spec.id
		panel:SetAttribute("Board", spec.id)
		Builder.BoardFrame(panel, cfs[spec.id], spec, c.Y, island:GetAttribute("OwnerName"))
		local screen = panel.Screen
		screen:SetAttribute("Board", spec.id)
		-- (the screen's visible side is its Back face: -LookVector)
		local front = -screen.CFrame.LookVector
		front = Vector3.new(front.X, 0, front.Z).Unit
		local bottom = Vector3.new(screen.Position.X, c.Y, screen.Position.Z)
		panel.WorldPivot = CFrame.lookAt(bottom, bottom + front)
		panel.Parent = model
		local row = L[spec.id]
		if row then
			-- the rim angle in WORLD degrees (BoardPlacer: 0 = +X): the island's far side turned by the row's angle
			local a = math.rad(row.angle)
			local w = at(island, math.cos(a), math.sin(a)) - at(island, 0, 0)
			local worldDeg = math.deg(math.atan2(w.Z, w.X))
			BoardPlacer.place(panel, area, worldDeg, { margin = L.Margin, tiltBack = 0, groundY = c.Y })
			placed[spec.id] = { panel = panel, row = row, deg = worldDeg }
		end
		panel:SetAttribute("Placeable", true)
	end
	-- the pair turns `spread` deg toward each other (the side is worked out from where the other board stands)
	for _, pair in ipairs({ { "Tree", "Info" }, { "Info", "Tree" } }) do
		local me, other = placed[pair[1]], placed[pair[2]]
		if me and other and (me.row.spread or 0) ~= 0 then
			local look = me.panel:GetPivot().LookVector
			local to = other.panel:GetPivot().Position - me.panel:GetPivot().Position
			local side = if look:Cross(to).Y >= 0 then 1 else -1
			BoardPlacer.place(me.panel, area, me.deg, { margin = L.Margin, tiltBack = 0, groundY = c.Y, pairSpread = side * me.row.spread })
		end
	end
	return model
end
-- the back of a board (pass 3: "no blank slab"): a lavender stone panel (cf = its middle, facing the board's front) with a
-- brass trim inset round it and a gold emblem on its back face: the big four-point star on the Tree, the island owner's
-- name plate (under a smaller star) on Info, a star on the others
function Builder.BoardBack(parent: Instance, cf: CFrame, w: number, h: number, id: string, ownerName: string?)
	local B = MapConfig.Boards
	local A = require(Galaxy:WaitForChild("UIAssets"))
	local panel = part({ Name = "BackPanel", Size = Vector3.new(w, h, 0.3), CFrame = cf, Color = B.Stone, CanCollide = true, Parent = parent })
	local z = -0.15 - 0.05 -- (on the panel's back face)
	for _, s in ipairs({ -1, 1 }) do
		part(brass({ Name = "BackTrim", Size = Vector3.new(w - 1.2, 0.25, 0.1), CFrame = cf * CFrame.new(0, s * (h / 2 - 0.6), z), Parent = parent }))
		part(brass({ Name = "BackTrim", Size = Vector3.new(0.25, h - 1.2, 0.1), CFrame = cf * CFrame.new(s * (w / 2 - 0.6), 0, z), Parent = parent }))
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front -- (-Z: the back of the board)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.3
	gui.MaxDistance = 300
	local function image(img: string, colour: Color3, size: number, y: number, transparency: number?)
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.Image = img
		i.ImageColor3 = colour
		i.ImageTransparency = transparency or 0
		i.AnchorPoint = Vector2.new(0.5, 0.5)
		i.Position = UDim2.fromScale(0.5, y)
		i.Size = UDim2.fromScale(size, size)
		i.SizeConstraint = Enum.SizeConstraint.RelativeXX
		i.Parent = gui
		return i
	end
	if id == "Tree" then
		image(A.softglow, Color3.fromRGB(255, 190, 80), 1.1, 0.5, 0.35)
		image(A.sparkle, Color3.fromRGB(255, 196, 70), 0.78, 0.5)
	elseif id ~= "Info" then
		image(A.softglow, Color3.fromRGB(255, 190, 80), 0.5, 0.5, 0.4)
		image(A.sparkle, Color3.fromRGB(255, 196, 70), 0.36, 0.5)
	else
		image(A.softglow, Color3.fromRGB(255, 190, 80), 0.6, 0.3, 0.45)
		image(A.sparkle, Color3.fromRGB(255, 196, 70), 0.42, 0.3)
		-- the name plate: a brass plate with the owner's name
		local plate = Instance.new("Frame")
		plate.AnchorPoint = Vector2.new(0.5, 0.5)
		plate.Position = UDim2.fromScale(0.5, 0.68)
		plate.Size = UDim2.fromScale(0.82, 0.17)
		plate.BackgroundColor3 = Color3.new(1, 1, 1)
		plate.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = plate
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255, 220, 140), Color3.fromRGB(196, 128, 40))
		g.Rotation = 90
		g.Parent = plate
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(80, 44, 16)
		st.Thickness = 5
		st.Parent = plate
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromScale(0.06, 0.1)
		name.Size = UDim2.fromScale(0.88, 0.8)
		name.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		name.TextScaled = true
		name.Text = string.upper(ownerName or "")
		name.TextColor3 = Color3.fromRGB(60, 30, 10)
		name.Parent = plate
	end
	gui.Parent = panel
end

-- the half width of a board with its frame (the pair's lip + posts; the others' frame)
function Builder.BoardHalfWidth(spec): number
	local B = MapConfig.Boards
	return if spec.pair then spec.Width / 2 + B.Pair.Lip + B.Pair.Post else spec.Width / 2 + B.Frame
end

return Builder
