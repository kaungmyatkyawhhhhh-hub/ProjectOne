--[[
	Legends Service and the Riviera Fuel stations (Studio, Edit mode; owner 2026-11-07: "add a repair shop", gas stations at
	their real places, "super realistic"). Built from parts in the look of the map's Monaco buildings: stucco, travertine,
	dark aluminium, glass, warm white light. Cleaned Toolbox pieces wait in ServerStorage.CareKit (Lift, TireRack, ToolChest;
	no scripts, credits in City Legends.md). Everything lands in workspace.Riviera.CarCare/<id>; what stood in a drive's way
	moves to ServerStorage.CareHidden/<id>.

	local V = require(ServerStorage.ClaudeTools.CareVenues:Clone())
	V.service(frame)                  frame: the plot's street edge, middle, slab top; +Z away from the road
	V.station(site)                   site: { id, name, frame, depth (skirt), litre, kwh, drives = { {x, w, len} }, ... }
	V.frameAt(road, way, x, z, side, setback, y)  a plot's frame beside a lane
	V.undo(id)
]]

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local M = {}
-- the map it builds on (2026-11-13, Yangon step 9): M.root = workspace.Yangon, M.clearIn = what may move aside
-- (default: the Riviera and its Dressing), M.brand = { "LEGENDS", "FUEL" } for the signs
M.root = nil :: Instance?
M.clearIn = nil :: Instance?
M.brand = nil :: { string }?
local function root(): Instance
	return M.root or workspace.Riviera
end
local function zone(): Instance
	return M.clearIn or workspace.Riviera.Dressing
end
local function brand(): string
	return if M.brand then M.brand[1] .. " " .. M.brand[2] else "RIVIERA FUEL"
end

local rgb = Color3.fromRGB
local Mat = Enum.Material
local C = {
	stucco = rgb(233, 225, 209),
	stone = rgb(208, 197, 176),
	alu = rgb(52, 54, 58),
	steel = rgb(150, 154, 160),
	white = rgb(238, 238, 234),
	glass = rgb(168, 194, 204),
	slab = rgb(158, 156, 150),
	joint = rgb(96, 94, 90),
	asphalt = rgb(50, 50, 54),
	epoxy = rgb(128, 132, 134),
	yellow = rgb(232, 186, 40),
	red = rgb(160, 34, 34),
	navy = rgb(16, 42, 78),
	gold = rgb(214, 172, 92),
	led = rgb(255, 236, 206),
	rubber = rgb(22, 22, 24),
	hedge = rgb(58, 88, 48),
	tile = rgb(196, 192, 184),
}

type Kit = { [string]: any }

local function kit(parent: Instance, frame: CFrame): Kit
	local K: Kit = {}
	function K.at(x: number, y: number, z: number): Vector3
		return frame:PointToWorldSpace(Vector3.new(x, y, z))
	end
	-- a box from its two corners, in the plot's own space
	function K.box(name: string, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3, mat: Enum.Material?, opts: { [string]: any }?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1))
		p.CFrame = frame * CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
		p.Color = color
		p.Material = mat or Mat.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanTouch = false
		if opts then
			for k, v in opts do
				(p :: any)[k] = v
			end
		end
		p.Parent = parent
		return p
	end
	-- something small: no collisions, no shadow
	function K.bit(name: string, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, color: Color3, mat: Enum.Material?, opts: { [string]: any }?): Part
		local p = K.box(name, x1, y1, z1, x2, y2, z2, color, mat, opts)
		p.CanCollide = false
		p.CastShadow = false
		p.CanQuery = false
		return p
	end
	function K.cyl(name: string, x: number, y1: number, z: number, y2: number, d: number, color: Color3, mat: Enum.Material?, solid: boolean?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.Size = Vector3.new(y2 - y1, d, d)
		p.CFrame = frame * CFrame.new(x, (y1 + y2) / 2, z) * CFrame.Angles(0, 0, math.pi / 2)
		p.Color = color
		p.Material = mat or Mat.Metal
		p.CanCollide = solid == true
		p.CanTouch = false
		p.CanQuery = solid == true
		p.CastShadow = solid == true
		p.Parent = parent
		return p
	end
	function K.glass(name: string, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number, solid: boolean?): Part
		local p = K.box(name, x1, y1, z1, x2, y2, z2, C.glass, Mat.Glass, { Transparency = 0.5, Reflectance = 0.12, CastShadow = false })
		p.CanCollide = solid ~= false
		return p
	end
	-- warm white LED light: a strip that glows at night
	function K.led(name: string, x1: number, y1: number, z1: number, x2: number, y2: number, z2: number): Part
		local p = K.bit(name, x1, y1, z1, x2, y2, z2, C.led, Mat.Neon)
		CollectionService:AddTag(p, "LampGlow")
		return p
	end
	function K.light(p: BasePart, kind: string, range: number, brightness: number, dayOff: boolean?)
		local l: any = Instance.new(kind)
		l.Color = C.led
		l.Range = range
		l.Brightness = brightness
		l.Shadows = false
		if kind ~= "PointLight" then
			l.Angle = 120
			l.Face = Enum.NormalId.Bottom
		end
		l.Parent = p
		if dayOff then
			CollectionService:AddTag(l, "DayOff")
		end
		return l
	end
	-- a sign: text on one face of a part
	function K.sign(p: BasePart, face: Enum.NormalId, canvas: Vector2, rows: { any }, glow: boolean?)
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		g.CanvasSize = canvas
		g.LightInfluence = if glow then 0.1 else 0.8
		g.Brightness = if glow then 1.5 else 1
		g.MaxDistance = 500
		g.ResetOnSpawn = false
		g.Parent = p
		for _, r in rows do
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Position = UDim2.fromScale(r.x or 0.04, r.y or 0)
			t.Size = UDim2.fromScale(r.w or 0.92, r.h or 1)
			t.Font = r.font or Enum.Font.GothamBold
			t.Text = r.text
			t.TextColor3 = r.color or C.white
			t.TextScaled = true
			t.TextXAlignment = r.align or Enum.TextXAlignment.Center
			t.Parent = g
		end
		return g
	end
	function K.rope(name: string, a: BasePart, aAt: Vector3, b: BasePart, bAt: Vector3, len: number, width: number?)
		local a0 = Instance.new("Attachment")
		a0.Position = aAt
		a0.Parent = a
		local a1 = Instance.new("Attachment")
		a1.Position = bAt
		a1.Parent = b
		local r = Instance.new("RopeConstraint")
		r.Name = name
		r.Attachment0 = a0
		r.Attachment1 = a1
		r.Length = len
		r.Visible = true
		r.Thickness = width or 0.12
		r.Color = BrickColor.new("Really black")
		r.Parent = a
	end
	return K
end

-- ---------------------------------------------------------------------------------------------------- moving things aside

local KEEP_WHOLE = { Tree = true, Palm = true, StreetLamp = true, ["road sign "] = true, Bench = true, BusShelter = true, Bin = true, Bollard = true }

local function hiddenFolder(id: string): Folder
	local root = ServerStorage:FindFirstChild("CareHidden") or Instance.new("Folder")
	root.Name = "CareHidden"
	root.Parent = ServerStorage
	local f = root:FindFirstChild(id) or Instance.new("Folder")
	f.Name = id
	f.Parent = root
	return f :: Folder
end

-- what stands in a drive's way moves aside (not roads, pavements, kerbs or plates)
local function clearBox(id: string, cf: CFrame, size: Vector3, only: { [string]: boolean }?)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { zone() }
	local folder = hiddenFolder(id)
	local moved = 0
	for _, p in workspace:GetPartBoundsInBox(cf, size, params) do
		local top: Instance = p
		local a: Instance? = p.Parent
		local named = only == nil
		while a and a ~= zone() do
			if a:IsA("Model") and KEEP_WHOLE[a.Name] then
				top = a
			end
			if only and only[a.Name] then
				named = true
			end
			a = a.Parent
		end
		if named and top.Parent and top.Parent ~= folder and top:IsDescendantOf(workspace) then
			top:SetAttribute("OldParent", top.Parent:GetFullName())
			top.Parent = folder
			moved += 1
		end
	end
	return moved
end

function M.undo(id: string)
	local holder = root():FindFirstChild("CarCare")
	local model = holder and holder:FindFirstChild(id)
	if model then
		model:Destroy()
	end
	local root = ServerStorage:FindFirstChild("CareHidden")
	local f = root and root:FindFirstChild(id)
	if f then
		for _, c in f:GetChildren() do
			local path = c:GetAttribute("OldParent")
			local at: Instance? = game
			for name in string.gmatch(path or "", "[^%.]+") do
				at = at and at:FindFirstChild(name)
			end
			if at then
				c:SetAttribute("OldParent", nil)
				c.Parent = at
			end
		end
		f:Destroy()
	end
end

local function holder(id: string): Model
	local h = root():FindFirstChild("CarCare") or Instance.new("Folder")
	h.Name = "CarCare"
	h.Parent = root()
	local m = Instance.new("Model")
	m.Name = id
	m.Parent = h
	return m
end

function M.frameAt(road: string, way: number, x: number, z: number, side: number, setback: number, y: number?): (CFrame, number)
	local Sh = game.ReplicatedStorage.Shared
	local lane
	for _, L in { require(Sh.RivieraLanes:Clone()), require(Sh.RivieraLanesHighway:Clone()) } do
		for _, l in (L :: any).lanes do
			if l.road == road and l.way == way and l.lane == 1 then
				lane = l
			end
		end
	end
	local best, at, dir = 1e12, Vector3.zero, Vector3.xAxis
	local n = #lane.pts // 3
	for i = 1, n - 1 do
		local k = (i - 1) * 3
		local p = Vector3.new(lane.pts[k + 1], lane.pts[k + 2], lane.pts[k + 3])
		local d = (Vector3.new(p.X - x, 0, p.Z - z)).Magnitude
		if d < best then
			best, at = d, p
			local q = Vector3.new(lane.pts[k + 4], lane.pts[k + 5], lane.pts[k + 6])
			dir = Vector3.new(q.X - p.X, 0, q.Z - p.Z).Unit
		end
	end
	local right = dir:Cross(Vector3.yAxis)
	local Z = right * side
	local X = Vector3.yAxis:Cross(Z)
	local o = at + Z * setback
	return CFrame.fromMatrix(Vector3.new(o.X, y or at.Y, o.Z), X, Vector3.yAxis, Z), at.Y
end

-- a drive from the road up to the plot: x and width. It walks out from the plot to the road's first lane, so it knows how
-- far the road is and how high the kerb and pavement stand; a short lip on the road climbs the kerb
local function drive(K: Kit, id: string, frame: CFrame, x: number, w: number, _len: number, parent: Instance)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Include
	ray.FilterDescendantsInstances = { root():FindFirstChild("Roads") or root() }
	local roadY, kerbTop, reach = frame.Y - 0.4, frame.Y - 0.3, 24
	for d = 1, 60 do
		local hit = workspace:Raycast(frame:PointToWorldSpace(Vector3.new(x, 40, -d)), Vector3.new(0, -120, 0), ray)
		if hit and hit.Instance.Name == "Road" then
			roadY, reach = hit.Position.Y, d
			break
		elseif hit then
			kerbTop = math.max(kerbTop, hit.Position.Y)
		end
	end
	local function piece(a: Vector3, b: Vector3)
		local mid = (a + b) / 2
		local p = Instance.new("Part")
		p.Name = "Drive"
		p.Anchored = true
		p.CanTouch = false
		p.Size = Vector3.new(w, 0.8, (b - a).Magnitude + 0.1)
		p.CFrame = CFrame.lookAt(mid, b) * CFrame.new(0, -0.4, 0)
		p.Color = C.asphalt
		p.Material = Mat.Asphalt
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Parent = parent
	end
	local function at(z: number, y: number): Vector3
		local q = frame:PointToWorldSpace(Vector3.new(x, 0, z))
		return Vector3.new(q.X, y, q.Z)
	end
	local top = kerbTop + 0.14
	piece(at(-reach - 7, roadY - 0.04), at(-reach + 1, top))
	piece(at(-reach + 1, top), at(2, frame.Y - 0.02))
	clearBox(id, frame * CFrame.new(x, 6, (3 - reach) / 2), Vector3.new(w + 4, 16, reach + 6))
end

-- ---------------------------------------------------------------------------------------------------- the fuel station

local function product(K: Kit, x1: number, y: number, z1: number, x2: number, z2: number, seed: number)
	local cols = { rgb(190, 60, 50), rgb(230, 200, 90), rgb(60, 110, 170), rgb(240, 240, 235), rgb(60, 140, 90), rgb(220, 130, 50) }
	local n = 6
	for i = 1, n do
		local a = x1 + (x2 - x1) * (i - 1) / n
		local b = a + (x2 - x1) / n - 0.15
		K.bit("Goods", a, y, z1, b, y + 0.75, z2, cols[(seed + i) % #cols + 1])
	end
end

local function dispenser(K: Kit, m: Model, x: number, z: number, litre: number)
	K.box("PumpBase", x - 1.7, 0.5, z - 0.85, x + 1.7, 0.9, z + 0.85, C.alu, Mat.Metal)
	local body = K.box("PumpBody", x - 1.45, 0.9, z - 0.65, x + 1.45, 5.3, z + 0.65, C.white, Mat.SmoothPlastic)
	K.bit("PumpEdge", x - 1.5, 0.9, z - 0.5, x - 1.42, 5.3, z + 0.5, C.steel, Mat.Metal)
	K.bit("PumpEdge", x + 1.42, 0.9, z - 0.5, x + 1.5, 5.3, z + 0.5, C.steel, Mat.Metal)
	local head = K.box("PumpHead", x - 1.55, 5.3, z - 0.72, x + 1.55, 6.9, z + 0.72, C.navy, Mat.SmoothPlastic)
	K.bit("PumpLine", x - 1.56, 5.3, z - 0.73, x + 1.56, 5.4, z + 0.73, C.gold, Mat.Metal)
	K.sign(head, Enum.NormalId.Front, Vector2.new(220, 90), { { text = brand(), color = C.white, font = Enum.Font.GothamBlack, y = 0.2, h = 0.6 } }, true)
	K.sign(head, Enum.NormalId.Back, Vector2.new(220, 90), { { text = brand(), color = C.white, font = Enum.Font.GothamBlack, y = 0.2, h = 0.6 } }, true)
	for _, face in { -1, 1 } do
		local zz = z + face * 0.66
		local screen = K.bit("PumpScreen", x - 1.05, 3.2, zz, x + 1.05, 4.9, zz + face * 0.04, rgb(10, 12, 14), Mat.Glass)
		K.sign(screen, if face < 0 then Enum.NormalId.Front else Enum.NormalId.Back, Vector2.new(210, 170), {
			{ text = "98", color = C.gold, font = Enum.Font.GothamBold, y = 0.06, h = 0.2 },
			{ text = string.format("$%.2f /L", litre), color = rgb(255, 214, 120), font = Enum.Font.Code, y = 0.32, h = 0.34 },
			{ text = "CARD ONLY", color = C.steel, font = Enum.Font.Gotham, y = 0.72, h = 0.16 },
		}, true)
		for i, col in { rgb(30, 120, 70), C.rubber, rgb(190, 150, 40) } do
			local bx = x - 1.0 + (i - 1) * 1.0
			local nozzle = K.bit("Nozzle", bx - 0.13, 1.9, zz, bx + 0.13, 2.7, zz + face * 0.22, col)
			K.rope("Hose", head, Vector3.new(bx - x, -0.4, face * 0.72), nozzle, Vector3.new(0, 0.3, 0), 6.2, 0.13)
		end
	end
	return K.at(x, 0, z), body
end

local function charger(K: Kit, x: number, z: number, faceX: number)
	K.box("ChargerBase", x - 1.0, 0.5, z - 1.0, x + 1.0, 0.8, z + 1.0, C.alu, Mat.Metal)
	local post = K.box("Charger", x - 0.8, 0.8, z - 0.9, x + 0.8, 7.6, z + 0.9, C.white, Mat.SmoothPlastic)
	K.bit("ChargerStripe", x - 0.82, 7.1, z - 0.92, x + 0.82, 7.3, z + 0.92, C.gold, Mat.Metal)
	local fx = x + faceX * 0.82
	local screen = K.bit("ChargerScreen", fx - 0.02, 4.4, z - 0.6, fx + 0.02, 6.2, z + 0.6, rgb(10, 12, 14), Mat.Glass)
	K.sign(screen, if faceX > 0 then Enum.NormalId.Right else Enum.NormalId.Left, Vector2.new(120, 180), {
		{ text = "FAST", color = C.white, font = Enum.Font.GothamBlack, y = 0.1, h = 0.2 },
		{ text = "CHARGE", color = rgb(120, 230, 170), font = Enum.Font.GothamBold, y = 0.34, h = 0.16 },
		{ text = "150 kW", color = C.gold, font = Enum.Font.Code, y = 0.6, h = 0.2 },
	}, true)
	local plug = K.bit("ChargerPlug", fx, 2.6, z + 0.2, fx + faceX * 0.25, 3.4, z + 0.5, C.rubber)
	K.rope("Cable", post, Vector3.new(faceX * 0.82, 3.4, 0), plug, Vector3.new(0, 0.3, 0), 6.5, 0.16)
	return K.at(x, 0, z)
end

function M.station(site: { [string]: any }): { [string]: any }
	local id = site.id
	M.undo(id)
	local m = holder(id)
	local frame: CFrame = site.frame
	local K = kit(m, frame)
	local W, D = site.w or 84, 62
	local hw = W / 2

	workspace.Terrain:FillBlock(frame * CFrame.new(0, 17, D / 2), Vector3.new(W + 8, 46, D + 8), Mat.Air)
	clearBox(id, frame * CFrame.new(0, 12, D / 2), Vector3.new(W, 28, D))
	clearBox(id, frame * CFrame.new(0, 6, -8), Vector3.new(W + 2, 16, 24), { Balustrade = true, GuardRails = true })
	clearBox(id, frame * CFrame.new(0, 20, D / 2), Vector3.new(W + 36, 44, D + 36), { Tree = true })

	-- the forecourt, and the wall that holds it up
	K.box("Forecourt", -hw, -1.2, 0, hw, 0, D, C.slab, Mat.Concrete)
	local depth = site.depth or 6
	K.box("Skirt", -hw, -1.2 - depth, 0.3, hw, -1.2, D, C.stone, Mat.Limestone)
	for x = -hw + 14, hw - 1, 14 do
		K.bit("Joint", x - 0.06, 0, 0, x + 0.06, 0.04, D, C.joint)
	end
	for z = 14, D - 1, 14 do
		K.bit("Joint", -hw, 0, z - 0.06, hw, 0.04, z + 0.06, C.joint)
	end
	K.box("Kerb", -hw - 0.8, 0, D - 0.2, hw + 0.8, 0.7, D + 1, C.stone, Mat.Limestone)
	K.box("Kerb", -hw - 0.8, 0, 12, -hw, 0.7, D, C.stone, Mat.Limestone)
	K.box("Kerb", hw, 0, 12, hw + 0.8, 0.7, D, C.stone, Mat.Limestone)
	if site.backWall then
		K.box("BackWall", -hw - 2, -2, D + 1, hw + 2, site.backWall, D + 3, C.stone, Mat.Limestone)
	end

	-- pump islands and the canopy
	local pumps: { Vector3 } = {}
	for _, z in { 13, 30 } do
		K.box("Island", -13, 0, z - 1.5, 13, 0.5, z + 1.5, C.tile, Mat.Concrete)
		K.bit("IslandLip", -13.1, 0, z - 1.6, 13.1, 0.12, z + 1.6, C.yellow, Mat.SmoothPlastic)
		for _, x in { -7, 7 } do
			table.insert(pumps, (dispenser(K, m, x, z, site.litre)))
		end
		for _, x in { -12, 12 } do
			K.cyl("Bollard", x, 0.5, z, 3, 0.6, C.yellow, Mat.Metal, true)
			K.cyl("BollardBand", x, 2.2, z, 2.6, 0.62, C.rubber, Mat.Metal)
		end
		K.cyl("Bin", 0, 0.5, z, 2.6, 1.1, C.alu, Mat.Metal)
		K.bit("Towels", -0.5, 2.7, z - 0.3, 0.5, 3.4, z + 0.3, C.white)
		K.cyl("TowelPole", 0, 2.6, z, 2.75, 0.2, C.steel, Mat.Metal)
	end
	local cy, cz = 15.5, 21.5
	K.box("CanopyRoof", -27, cy + 1.2, cz - 17, 27, cy + 1.7, cz + 17, C.white, Mat.Metal)
	local fascia = K.box("CanopyFascia", -28, cy, cz - 18, 28, cy + 2, cz - 17, C.navy, Mat.SmoothPlastic)
	local fasciaB = K.box("CanopyFascia", -28, cy, cz + 17, 28, cy + 2, cz + 18, C.navy, Mat.SmoothPlastic)
	K.box("CanopyFascia", -28, cy, cz - 17, -27, cy + 2, cz + 17, C.navy, Mat.SmoothPlastic)
	K.box("CanopyFascia", 27, cy, cz - 17, 28, cy + 2, cz + 17, C.navy, Mat.SmoothPlastic)
	K.bit("CanopyLine", -28.02, cy, cz - 18.04, 28.02, cy + 0.16, cz - 18, C.gold, Mat.Metal)
	K.bit("CanopyLine", -28.02, cy, cz + 18, 28.02, cy + 0.16, cz + 18.04, C.gold, Mat.Metal)
	K.bit("CanopyLine", -28.04, cy, cz - 18.02, -28, cy + 0.16, cz + 18.02, C.gold, Mat.Metal)
	K.bit("CanopyLine", 28, cy, cz - 18.02, 28.04, cy + 0.16, cz + 18.02, C.gold, Mat.Metal)
	K.sign(fascia, Enum.NormalId.Front, Vector2.new(1120, 40), { { text = brand(), color = C.white, font = Enum.Font.GothamBlack, y = 0.08, h = 0.84 } }, true)
	K.sign(fasciaB, Enum.NormalId.Back, Vector2.new(1120, 40), { { text = brand(), color = C.white, font = Enum.Font.GothamBlack, y = 0.08, h = 0.84 } }, true)
	K.box("CanopyCeiling", -27, cy + 0.8, cz - 17, 27, cy + 1.2, cz + 17, rgb(226, 226, 222), Mat.SmoothPlastic)
	for _, x in { -18, -6, 6, 18 } do
		for _, z in { 12, 21.5, 31 } do
			local led = K.led("CanopyLed", x - 3.6, cy + 0.74, z - 1.2, x + 3.6, cy + 0.8, z + 1.2)
			if z == 21.5 then
				K.light(led, "SpotLight", 42, 2.2, true)
			end
		end
	end
	for _, z in { 13, 30 } do
		K.cyl("CanopyColumn", 0, 0.5, z, cy + 0.8, 1.3, C.white, Mat.Metal, true)
	end

	-- the charging bay at the side
	K.box("EvIsland", 31, 0, 8, 34, 0.5, 34, C.tile, Mat.Concrete)
	K.bit("EvBay", 34.2, 0, 8, 46, 0.03, 34, rgb(44, 96, 76))
	for _, z in { 12, 21, 30 } do
		K.bit("EvLine", 34.2, 0.03, z - 4.6, 46, 0.05, z - 4.4, C.white)
	end
	K.bit("EvLine", 34.2, 0.03, 34.4 - 0.1, 46, 0.05, 34.4 + 0.1, C.white)
	local chargers = { charger(K, 32.5, 12, 1), charger(K, 32.5, 21, 1), charger(K, 32.5, 30, 1) }

	-- the shop
	local bx1, bx2, bz1, bz2 = -22, 16, 47, D - 1
	local H = 9.5
	K.box("ShopFloor", bx1, 0, bz1, bx2, 0.3, bz2, C.tile, Mat.Marble)
	K.box("ShopBack", bx1, 0.3, bz2 - 0.8, bx2, H, bz2, C.stucco, Mat.Plaster)
	K.box("ShopSide", bx1, 0.3, bz1, bx1 + 0.8, H, bz2, C.stone, Mat.Limestone)
	K.box("ShopSide", bx2 - 0.8, 0.3, bz1, bx2, H, bz2, C.stone, Mat.Limestone)
	K.box("ShopRoof", bx1 - 2, H, bz1 - 3, bx2 + 2, H + 0.7, bz2 + 0.6, C.white, Mat.Metal)
	local shopSign = K.box("ShopFascia", bx1 - 2.1, H - 0.3, bz1 - 3.1, bx2 + 2.1, H + 1.5, bz1 - 2.9, C.navy, Mat.SmoothPlastic)
	K.sign(shopSign, Enum.NormalId.Front, Vector2.new(840, 40), { { text = brand() .. "   ·   SHOP", color = C.white, font = Enum.Font.GothamBlack, y = 0.1, h = 0.8 } }, true)
	for x = bx1 + 0.8, bx2 - 1, (bx2 - bx1 - 1.6) / 6 do
		K.box("Mullion", x - 0.12, 0.3, bz1, x + 0.12, H, bz1 + 0.3, C.alu, Mat.Metal)
	end
	K.box("Mullion", bx2 - 1.04, 0.3, bz1, bx2 - 0.8, H, bz1 + 0.3, C.alu, Mat.Metal)
	K.box("Transom", bx1 + 0.8, 7.6, bz1, bx2 - 0.8, 7.8, bz1 + 0.3, C.alu, Mat.Metal)
	K.glass("ShopGlass", bx1 + 0.8, 0.3, bz1 + 0.1, bx2 - 0.8, H, bz1 + 0.2)
	-- inside: the ceiling lights, shelves, a lit fridge wall, the till
	K.box("ShopCeiling", bx1 + 0.8, H - 0.5, bz1 + 0.3, bx2 - 0.8, H, bz2 - 0.8, C.white, Mat.SmoothPlastic, { CanCollide = false })
	for _, x in { -14, -3, 8 } do
		local led = K.led("ShopLed", x - 3.5, H - 0.56, bz1 + 5, x + 3.5, H - 0.5, bz1 + 6.4)
		K.light(led, "PointLight", 22, 1.1)
	end
	for i, x in { -15, -8, -1 } do
		K.box("Shelf", x - 2.2, 0.3, bz1 + 3.5, x + 2.2, 5, bz1 + 5, rgb(236, 236, 232), Mat.SmoothPlastic)
		for lvl = 0, 2 do
			product(K, x - 2.1, 1 + lvl * 1.35, bz1 + 3.4, x + 2.1, bz1 + 3.5, i + lvl)
			product(K, x - 2.1, 1 + lvl * 1.35, bz1 + 5, x + 2.1, bz1 + 5.1, i + lvl + 2)
		end
	end
	K.box("Fridges", bx1 + 1, 0.3, bz2 - 2.6, 0, 7.4, bz2 - 0.8, rgb(40, 42, 46), Mat.Metal)
	for x = bx1 + 1.2, -2, 3.1 do
		K.bit("FridgeDoor", x, 0.8, bz2 - 2.66, x + 2.9, 7.1, bz2 - 2.6, rgb(190, 225, 240), Mat.Neon, { Transparency = 0.25 })
		for lvl = 0, 3 do
			product(K, x + 0.1, 1.2 + lvl * 1.4, bz2 - 2.72, x + 2.8, bz2 - 2.66, lvl + 3)
		end
	end
	K.box("Till", 4, 0.3, bz1 + 5, 14, 3.6, bz1 + 7, rgb(46, 50, 58), Mat.Wood)
	K.bit("TillTop", 3.9, 3.6, bz1 + 4.9, 14.1, 3.75, bz1 + 7.1, C.stone, Mat.Marble)
	K.bit("TillScreen", 8, 3.75, bz1 + 5.4, 9.6, 4.9, bz1 + 5.5, rgb(16, 18, 22), Mat.Glass)
	K.box("BackShelf", 3, 0.3, bz2 - 2.2, 15, 7, bz2 - 0.8, rgb(60, 62, 66), Mat.Wood)
	for lvl = 0, 3 do
		product(K, 3.2, 1.1 + lvl * 1.45, bz2 - 2.3, 14.8, bz2 - 2.2, lvl)
	end

	-- air and water
	K.box("AirBase", -40, 0, 42, -36, 0.5, 46, C.tile, Mat.Concrete)
	local air = K.box("AirPost", -38.6, 0.5, 43.4, -37.2, 6, 44.6, C.navy, Mat.SmoothPlastic)
	K.sign(air, Enum.NormalId.Front, Vector2.new(70, 120), {
		{ text = "AIR", color = C.white, font = Enum.Font.GothamBlack, y = 0.1, h = 0.3 },
		{ text = "WATER", color = C.gold, font = Enum.Font.GothamBold, y = 0.5, h = 0.2 },
	}, true)
	local gun = K.bit("AirGun", -38.3, 2.8, 43.25, -37.9, 3.6, 43.4, C.rubber)
	K.rope("AirHose", air, Vector3.new(0, 1, -0.6), gun, Vector3.new(0, 0.3, 0), 6, 0.12)
	K.cyl("WaterCan", -39.2, 0.5, 44.8, 1.9, 0.9, rgb(60, 120, 180), Mat.SmoothPlastic)

	-- the price sign by the road
	local tx = -hw + 6
	K.box("TotemBase", tx - 3.6, 0, 2.4, tx + 3.6, 0.8, 5.6, C.stone, Mat.Limestone)
	local totem = K.box("Totem", tx - 2.9, 0.8, 3.3, tx + 2.9, 24, 4.7, C.navy, Mat.SmoothPlastic)
	local rows = {
		{ text = if M.brand then M.brand[1] else "RIVIERA", color = C.white, font = Enum.Font.GothamBlack, y = 0.04, h = 0.09 },
		{ text = if M.brand then M.brand[2] else "FUEL", color = C.gold, font = Enum.Font.GothamBlack, y = 0.14, h = 0.1 },
		{ text = "98", color = C.gold, font = Enum.Font.GothamBold, x = 0.08, w = 0.3, y = 0.34, h = 0.08, align = Enum.TextXAlignment.Left },
		{ text = string.format("%.2f", site.litre), color = rgb(255, 214, 120), font = Enum.Font.Code, x = 0.4, w = 0.54, y = 0.33, h = 0.1, align = Enum.TextXAlignment.Right },
		{ text = "95", color = C.gold, font = Enum.Font.GothamBold, x = 0.08, w = 0.3, y = 0.47, h = 0.08, align = Enum.TextXAlignment.Left },
		{ text = string.format("%.2f", site.litre - 0.08), color = rgb(255, 214, 120), font = Enum.Font.Code, x = 0.4, w = 0.54, y = 0.46, h = 0.1, align = Enum.TextXAlignment.Right },
		{ text = "DIESEL", color = C.gold, font = Enum.Font.GothamBold, x = 0.08, w = 0.3, y = 0.6, h = 0.06, align = Enum.TextXAlignment.Left },
		{ text = string.format("%.2f", site.litre - 0.16), color = rgb(255, 214, 120), font = Enum.Font.Code, x = 0.4, w = 0.54, y = 0.59, h = 0.1, align = Enum.TextXAlignment.Right },
		{ text = "CHARGE /kWh", color = rgb(120, 230, 170), font = Enum.Font.GothamBold, x = 0.08, w = 0.42, y = 0.74, h = 0.05, align = Enum.TextXAlignment.Left },
		{ text = string.format("%.2f", site.kwh), color = rgb(120, 230, 170), font = Enum.Font.Code, x = 0.5, w = 0.44, y = 0.72, h = 0.1, align = Enum.TextXAlignment.Right },
	}
	K.sign(totem, Enum.NormalId.Front, Vector2.new(230, 930), rows, true)
	K.sign(totem, Enum.NormalId.Back, Vector2.new(230, 930), rows, true)

	-- planting along the road between the drives
	local dressing = root():FindFirstChild("Dressing")
	local palm = dressing and dressing:FindFirstChild("Palm", true)
	local dx1, dx2 = -hw + 12, hw - 6
	local drives = site.drives or { { -18, 22, 22 }, { 22, 22, 22 } }
	local edges: { number } = { dx1 }
	for _, d in drives do
		table.insert(edges, d[1] - d[2] / 2)
		table.insert(edges, d[1] + d[2] / 2)
		drive(K, id, frame, d[1], d[2], d[3], m)
	end
	table.insert(edges, dx2)
	for i = 1, #edges - 1, 2 do
		local a, b = edges[i], edges[i + 1]
		if b - a > 5 then
			K.box("Planter", a + 0.5, 0, 0.4, b - 0.5, 1, 3.2, C.stone, Mat.Limestone)
			K.bit("Hedge", a + 1, 1, 0.9, b - 1, 2.3, 2.7, C.hedge, Mat.Grass)
			if palm and b - a > 16 then
				local c = palm:Clone()
				c:PivotTo(frame * CFrame.new((a + b) / 2, 0, 1.8))
				c.Parent = m
			end
		end
	end

	return { id = id, name = site.name, pumps = pumps, chargers = chargers, arrive = frame * CFrame.new(-7, 2.6, 21.5) * CFrame.Angles(0, -math.pi / 2, 0) }
end

-- ---------------------------------------------------------------------------------------------------- Legends Service

local function bayLines(K: Kit, x: number)
	K.bit("BayLine", x - 10.6, 0.1, 44, x - 10.2, 0.14, 108, C.yellow)
	K.bit("BayLine", x + 10.2, 0.1, 44, x + 10.6, 0.14, 108, C.yellow)
end

local function clonePiece(name: string, parent: Instance, cf: CFrame): Model?
	local kitFolder = ServerStorage:FindFirstChild("CareKit")
	local src = kitFolder and kitFolder:FindFirstChild(name)
	if not src then
		return nil
	end
	local c = src:Clone()
	c:PivotTo(cf)
	c.Parent = parent
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	return c
end

function M.service(frame: CFrame): { [string]: any }
	local id = "legends_service"
	M.undo(id)
	local m = holder(id)
	local K = kit(m, frame)
	local hw, D = 76, 150

	workspace.Terrain:FillBlock(frame * CFrame.new(0, 21, D / 2 + 2), Vector3.new(hw * 2 + 8, 54, D + 8), Mat.Air)
	clearBox(id, frame * CFrame.new(0, 12, D / 2), Vector3.new(hw * 2, 30, D))
	clearBox(id, frame * CFrame.new(0, 6, -6), Vector3.new(hw * 2 + 2, 16, 20), { Balustrade = true })

	-- the plate, on a quay wall at the harbour's edge
	K.box("Plate", -hw, -4, 0, hw, 0, D, C.slab, Mat.Concrete)
	K.box("Quay", -hw - 1, -8, 2, hw + 1, -0.6, D + 1, C.stone, Mat.Limestone)
	K.box("Forecourt", -hw, 0, 0, hw, 0.05, 46, C.asphalt, Mat.Asphalt)
	for _, x in { -56, -44, -32, -20, -8, 4, 16, 28, 40, 52 } do
		if x < -26 or x > 26 then
			K.bit("ParkLine", x - 0.15, 0.05, 3, x + 0.15, 0.09, 17, C.white)
		end
	end

	-- the walls: stucco over a travertine base, piers between the workshop doors
	local x1, x2, z1, z2 = -56, 56, 46, 116
	local H, Top = 18, 27
	K.box("Floor", x1, 0, z1, x2, 0.08, z2, C.epoxy, Mat.Concrete, { Reflectance = 0.04 })
	K.box("WallLeft", x1 - 2, 0, z1, x1, Top, z2 + 2, C.stucco, Mat.Plaster)
	K.box("WallRight", x2, 0, z1, x2 + 2, Top, z2 + 2, C.stucco, Mat.Plaster)
	K.box("WallBack", x1, 0, z2, x2, Top, z2 + 2, C.stucco, Mat.Plaster)
	K.box("BaseStone", x1 - 2.2, 0, z1, x1 - 2, 4, z2 + 2.2, C.stone, Mat.Limestone)
	K.box("BaseStone", x2 + 2, 0, z1, x2 + 2.2, 4, z2 + 2.2, C.stone, Mat.Limestone)
	K.box("Lintel", x1 - 2.2, H, z1 - 2, x2 + 2.2, Top, z1, C.stucco, Mat.Plaster)
	K.box("Roof", x1 - 3, Top, z1 - 3, x2 + 3, Top + 1, z2 + 3, C.stone, Mat.Limestone)
	K.box("RoofTop", x1 - 2, Top + 1, z1 - 2, x2 + 2, Top + 1.1, z2 + 2, C.slab, Mat.Concrete)
	K.box("Ceiling", x1, H + 1, z1, x2, Top, z2, C.white, Mat.SmoothPlastic)
	K.box("CeilingFace", x1, H, z1, x2, H + 1, z2, rgb(214, 214, 210), Mat.SmoothPlastic, { CanCollide = false })
	for _, x in { -46, -22, 2, 26 } do
		K.box("Pier", x - 2, 0, z1 - 2.4, x + 2, H, z1 + 1, C.stone, Mat.Limestone)
	end
	K.box("Pier", 54, 0, z1 - 2.4, 58.2, H, z1 + 1, C.stone, Mat.Limestone)
	K.box("Pier", -58.2, 0, z1 - 2.4, -54, H, z1 + 1, C.stone, Mat.Limestone)

	-- the workshop doors, rolled up under the lintel, dark frames
	local bays = { -34, -10, 14 }
	for _, x in bays do
		K.box("DoorBox", x - 10, H - 2.4, z1 - 1, x + 10, H, z1 + 1.4, C.alu, Mat.Metal)
		bayLines(K, x)
		K.bit("BayNumber", x - 7, 0.09, z1 - 13, x + 7, 0.12, z1 - 12.7, C.white)
	end

	-- reception: floor-to-ceiling glass, marble floor
	K.box("ReceptionFloor", 28, 0.08, z1, x2, 0.4, 80, rgb(226, 220, 208), Mat.Marble)
	K.box("ReceptionWall", 27.2, 0.08, 62, 28, H, z2, C.stucco, Mat.Plaster)
	K.box("ReceptionWall", 28, 0.08, 80, x2, H, 81, C.stucco, Mat.Plaster)
	K.glass("WorkshopWindow", 27.3, 4, z1 + 1, 27.9, H - 2, 62)
	K.box("Sill", 27.2, 0.08, z1 + 1, 28, 4, 62, C.stone, Mat.Limestone)
	K.glass("ReceptionGlass", 28, 0.4, z1 - 0.8, 54, H, z1 - 0.5)
	for x = 28, 54.1, 6.5 do
		K.box("Mullion", x - 0.15, 0.4, z1 - 1, x + 0.15, H, z1 - 0.4, C.alu, Mat.Metal)
	end
	K.box("Transom", 28, 11.8, z1 - 1, 54, 12, z1 - 0.4, C.alu, Mat.Metal)
	K.box("Desk", 34, 0.4, 66, 50, 4.2, 69, rgb(60, 48, 40), Mat.Wood)
	K.bit("DeskTop", 33.8, 4.2, 65.8, 50.2, 4.4, 69.2, C.stone, Mat.Marble)
	local backSign = K.bit("ReceptionSign", 33, 7, 80, 51, 12, 79.9, C.navy)
	K.sign(backSign, Enum.NormalId.Front, Vector2.new(720, 200), {
		{ text = "LEGENDS SERVICE", color = C.white, font = Enum.Font.GothamBlack, y = 0.2, h = 0.4 },
		{ text = "Oil  ·  Tyres  ·  Brakes  ·  Engine  ·  Body", color = C.gold, font = Enum.Font.Gotham, y = 0.66, h = 0.18 },
	}, true)
	for _, x in { 36, 44 } do
		K.box("Waiting", x, 0.4, 53, x + 6, 2.2, 56, rgb(44, 46, 52), Mat.Fabric)
		K.box("WaitingBack", x, 2.2, 55.2, x + 6, 4.4, 56, rgb(44, 46, 52), Mat.Fabric)
	end
	for _, at in { { 40, 62 }, { 46, 74 } } do
		local led = K.led("ReceptionLed", at[1] - 6, H - 0.06, at[2] - 1, at[1] + 6, H, at[2] + 1)
		K.light(led, "PointLight", 34, 1)
	end

	-- the office floor over reception: the street's own look, shutters and a balcony
	local oy = Top + 1
	K.box("OfficeFront", 26, oy, z1 - 2, 58.2, oy + 13, z1, C.stucco, Mat.Plaster)
	K.box("OfficeSide", 26, oy, z1 - 2, 28, oy + 13, 92, C.stucco, Mat.Plaster)
	K.box("OfficeSide", 56.2, oy, z1 - 2, 58.2, oy + 13, 92, C.stucco, Mat.Plaster)
	K.box("OfficeBack", 26, oy, 90, 58.2, oy + 13, 92, C.stucco, Mat.Plaster)
	K.box("OfficeRoof", 25, oy + 13, z1 - 3, 59.2, oy + 14, 93, rgb(176, 96, 70), Mat.Slate)
	K.box("Balcony", 30, oy - 0.2, z1 - 6, 54, oy + 0.4, z1 - 2, C.stone, Mat.Limestone)
	for x = 30, 54.1, 1.2 do
		K.bit("Baluster", x - 0.12, oy + 0.4, z1 - 5.9, x + 0.12, oy + 3.2, z1 - 5.7, C.alu, Mat.Metal)
	end
	K.box("BalconyRail", 30, oy + 3.2, z1 - 6, 54, oy + 3.5, z1 - 5.6, C.alu, Mat.Metal)
	for _, x in { 34, 42, 50 } do
		K.bit("OfficeWindow", x - 2.2, oy + 1, z1 - 2.06, x + 2.2, oy + 10, z1 - 2, rgb(30, 36, 44), Mat.Glass, { Reflectance = 0.2 })
		K.bit("Shutter", x - 4.3, oy + 1, z1 - 2.1, x - 2.3, oy + 10, z1 - 2, rgb(96, 124, 118), Mat.Wood)
		K.bit("Shutter", x + 2.3, oy + 1, z1 - 2.1, x + 4.3, oy + 10, z1 - 2, rgb(96, 124, 118), Mat.Wood)
	end

	-- the big sign, on the lintel, and the one by the road
	local sign = K.box("SignPanel", -46, 19.6, z1 - 2.5, 24, 25.4, z1 - 2, C.alu, Mat.Metal)
	K.sign(sign, Enum.NormalId.Front, Vector2.new(1400, 116), {
		{ text = "LEGENDS SERVICE", color = rgb(255, 244, 222), font = Enum.Font.GothamBlack, y = 0.1, h = 0.8 },
	}, true)
	K.bit("SignLine", -46, 19.1, z1 - 2.56, 24, 19.3, z1 - 2, C.gold, Mat.Metal)
	K.bit("SignLine", -46, 25.7, z1 - 2.56, 24, 25.9, z1 - 2, C.gold, Mat.Metal)
	for _, x in { -30, 0, 30 } do
		local wash = K.led("SignWash", x - 8, 18.7, z1 - 2.9, x + 8, 19, z1 - 2.5)
		K.light(wash, "PointLight", 26, 0.9, true)
	end
	K.box("TotemBase", -70, 0, 4, -62, 0.8, 8, C.stone, Mat.Limestone)
	local totem = K.box("Totem", -69, 0.8, 5, -63, 26, 7, C.alu, Mat.Metal)
	local rows = {
		{ text = "LEGENDS", color = C.white, font = Enum.Font.GothamBlack, y = 0.05, h = 0.1 },
		{ text = "SERVICE", color = C.gold, font = Enum.Font.GothamBlack, y = 0.16, h = 0.1 },
		{ text = "OIL", color = C.white, font = Enum.Font.GothamBold, y = 0.42, h = 0.06 },
		{ text = "TYRES", color = C.white, font = Enum.Font.GothamBold, y = 0.51, h = 0.06 },
		{ text = "BRAKES", color = C.white, font = Enum.Font.GothamBold, y = 0.6, h = 0.06 },
		{ text = "ENGINE", color = C.white, font = Enum.Font.GothamBold, y = 0.69, h = 0.06 },
		{ text = "BODY", color = C.white, font = Enum.Font.GothamBold, y = 0.78, h = 0.06 },
	}
	K.sign(totem, Enum.NormalId.Front, Vector2.new(240, 1000), rows, true)
	K.sign(totem, Enum.NormalId.Back, Vector2.new(240, 1000), rows, true)

	-- the workshop: lifts, light, tool walls, tyre racks
	for _, x in bays do
		local lift = clonePiece("Lift", m, frame * CFrame.new(x, 6.1, 80) * CFrame.Angles(0, math.pi / 2, 0))
		local _ = lift
		for _, z in { 58, 74, 90, 106 } do
			local led = K.led("WorkshopLed", x - 1, H - 0.08, z - 6, x + 1, H, z + 6)
			if z == 74 or z == 90 then
				K.light(led, "PointLight", 44, 1.8)
			end
		end
	end
	-- the tool wall along the back
	K.box("ToolBoard", -52, 5, z2 - 0.3, 22, 13, z2, rgb(40, 44, 50), Mat.DiamondPlate, { CanCollide = false })
	local toolCol = { C.steel, rgb(180, 184, 190), C.red, rgb(30, 90, 150) }
	for i = 0, 34 do
		local x = -50 + i * 2.05
		local h = 1.2 + (i * 7 % 5) * 0.32
		local y = 11.8 - h
		K.bit("Tool", x, y, z2 - 0.42, x + 0.3, y + h, z2 - 0.3, toolCol[i % #toolCol + 1], Mat.Metal)
		K.bit("ToolHead", x - 0.16, y + h - 0.36, z2 - 0.44, x + 0.46, y + h, z2 - 0.3, C.steel, Mat.Metal)
		if i % 3 == 0 then
			K.bit("Spanner", x + 0.5, 6.2, z2 - 0.4, x + 0.72, 8.4 - (i % 4) * 0.3, z2 - 0.3, C.steel, Mat.Metal)
		end
	end
	K.box("Bench", -52, 0.08, z2 - 3.6, -24, 3.6, z2 - 0.4, rgb(70, 74, 80), Mat.Metal, { CanCollide = false })
	K.bit("BenchTop", -52.2, 3.6, z2 - 3.8, -23.8, 3.9, z2 - 0.3, rgb(120, 92, 66), Mat.Wood)
	K.cyl("Vice", -46, 3.9, z2 - 2, 4.8, 0.9, C.alu, Mat.Metal)
	K.bit("Jack", -32, 3.9, z2 - 3.2, -29, 4.5, z2 - 1.2, C.red)
	for i, x in { -18, -11, -4 } do
		local chest = clonePiece("ToolChest", m, frame * CFrame.new(x, 2.6, z2 - 2) * CFrame.Angles(0, if i == 2 then math.pi else 0, 0))
		local _ = chest
	end
	K.cyl("OilDrum", 9, 0.08, z2 - 3, 4.2, 2.6, rgb(30, 60, 110), Mat.Metal)
	K.cyl("OilDrum", 12, 0.08, z2 - 3.4, 4.2, 2.6, rgb(120, 30, 30), Mat.Metal)
	K.cyl("OilDrum", 15, 0.08, z2 - 2.8, 4.2, 2.6, rgb(36, 38, 42), Mat.Metal)
	-- racks on the left wall
	for _, z in { 62, 80, 98 } do
		clonePiece("TireRack", m, frame * CFrame.new(x1 + 3.4, 4.5, z) * CFrame.Angles(0, math.pi / 2, 0))
	end
	-- an air reel over each bay and a wall of oil on the right
	for _, x in bays do
		K.cyl("Reel", x + 9, H - 3, 112, H, 1.6, C.red, Mat.Metal)
	end
	K.box("Shelving", 22, 0.08, 84, 26.6, 13, 114, rgb(66, 70, 78), Mat.Metal, { CanCollide = false })
	for lvl = 0, 3 do
		for z = 86, 112, 4.3 do
			product(K, 21.7, 1.2 + lvl * 3, z, 22, z + 3.6, lvl + 5)
		end
	end

	-- the side yard, palms and the lamps
	local dressing = root():FindFirstChild("Dressing")
	local palm = dressing and dressing:FindFirstChild("Palm", true)
	for _, at in { { -70, 32 }, { 70, 32 }, { -68, 96 }, { 68, 96 } } do
		K.box("Planter", at[1] - 3, 0, at[2] - 3, at[1] + 3, 1.4, at[2] + 3, C.stone, Mat.Limestone)
		if palm then
			local c = palm:Clone()
			c:PivotTo(frame * CFrame.new(at[1], 1.4, at[2]))
			c.Parent = m
		end
	end
	K.box("Rail", -hw, 0, D - 1, hw, 3.4, D, C.stone, Mat.Limestone)

	drive(K, id, frame, -37, 24, 22, m)
	drive(K, id, frame, 23, 20, 22, m)

	return { bay = K.at(-10, 0, 78) }
end

return M
