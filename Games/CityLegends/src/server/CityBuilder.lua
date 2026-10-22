--[[
	CityBuilder
	Procedurally builds the whole night city on the server:
	  * grid of 4-lane roads with markings, stop lines and crosswalks
	  * sidewalks + towers with lit window bands, neon shop signs, billboards,
	    rooftop aviation lights and parks
	  * street lights and working traffic-light heads at every intersection
	  * a skyline ring around the city
	  * a 6-lane highway that leaves the city, runs through a mountain tunnel
	    (with the CITY LEGENDS sign inside) and ends in a turnaround plaza
	  * night lighting / atmosphere / post-processing
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local CityPremium = require(script.Parent:WaitForChild("CityPremium"))
local Mainland = require(script.Parent:WaitForChild("Mainland"))
local Bank = require(script.Parent:WaitForChild("Bank"))
local Towers = require(script.Parent:WaitForChild("Towers"))

local CityBuilder = {}

local C = Config.City
local N = C.Blocks
local B = C.BlockSize
local HALF_ROAD = C.RoadWidth / 2
local CURB = C.CurbHeight
local E = C.HalfExtent + HALF_ROAD -- outer edge of the perimeter roads
local RING = C.OuterRingDepth
local HW = C.HighwayWidth / 2
local HWY_X0 = CityLayout.HighwayStartX
local TUNNEL_X0 = HWY_X0 + C.TunnelStart
local TUNNEL_X1 = TUNNEL_X0 + C.TunnelLength
local LOOP_S = C.LoopHalf -- the Legends Loop's centre line
local LOOP_R = C.LoopCorner
local LOOP_C = LOOP_S - LOOP_R
local LOOP_HW = HW + 8 -- half the loop's paved width (lanes and shoulders)
local SPUR_END = LOOP_S - HW - 110 -- the spur's rails and markings stop at the junction

local rng = Random.new(20261007)

---------------------------------------------------------------------
-- Part helpers
---------------------------------------------------------------------
type PartOpts = {
	collide: boolean?,
	transparency: number?,
	reflectance: number?,
	shadow: boolean?,
	shape: Enum.PartType?,
	class: string?,
	name: string?,
}

local function mk(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, o: PartOpts?): BasePart
	local opts: PartOpts = o or {}
	local p: BasePart
	if opts.class == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local part = Instance.new("Part")
		if opts.shape then
			part.Shape = opts.shape
		end
		p = part
	end
	p.Name = opts.name or "Part"
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Transparency = opts.transparency or 0
	p.Reflectance = opts.reflectance or 0
	local collide = opts.collide ~= false
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.CastShadow = opts.shadow ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- decorative, non-colliding
local function deco(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, o: PartOpts?): BasePart
	local opts: PartOpts = o or {}
	opts.collide = false
	if opts.shadow == nil then
		opts.shadow = false
	end
	return mk(parent, size, cf, color, material, opts)
end

-- Axis aligned slab between two corners, split into tiles (Roblox parts max out at 2048 studs)
local function slab(parent: Instance, x0: number, z0: number, x1: number, z1: number, top: number, thickness: number, color: Color3, material: Enum.Material, o: PartOpts?)
	local maxTile = 1000
	local xa, xb = math.min(x0, x1), math.max(x0, x1)
	local za, zb = math.min(z0, z1), math.max(z0, z1)
	local nx = math.max(1, math.ceil((xb - xa) / maxTile))
	local nz = math.max(1, math.ceil((zb - za) / maxTile))
	local sx, sz = (xb - xa) / nx, (zb - za) / nz
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			local cx = xa + sx * (ix + 0.5)
			local cz = za + sz * (iz + 0.5)
			mk(parent, Vector3.new(sx, thickness, sz), CFrame.new(cx, top - thickness / 2, cz), color, material, o)
		end
	end
end

local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function addLight(className: string, parent: Instance, color: Color3, range: number, brightness: number, face: Enum.NormalId?, angle: number?): Light
	local l = Instance.new(className) :: Light
	l.Color = color
	l.Brightness = brightness
	l.Shadows = false
	if l:IsA("PointLight") then
		l.Range = range
	elseif l:IsA("SpotLight") then
		l.Range = range
		l.Face = face or Enum.NormalId.Bottom
		l.Angle = angle or 90
	elseif l:IsA("SurfaceLight") then
		l.Range = range
		l.Face = face or Enum.NormalId.Front
		l.Angle = angle or 90
	end
	l.Parent = parent
	CollectionService:AddTag(l, "LODLight")
	return l
end

-- A group of small details the client hides when the camera is far away
-- (see WorldFx LOD). Engine-wise this removes thousands of parts from the
-- scene at any one time.
local function lodGroup(parent: Instance, name: string, center: Vector3, range: number): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Center", center)
	m:SetAttribute("Range", range)
	CollectionService:AddTag(m, "LOD")
	m.Parent = parent
	return m
end

local function surfaceText(part: BasePart, face: Enum.NormalId, text: string, textColor: Color3, bg: Color3?, bgTransparency: number?, font: Enum.Font?, canvas: Vector2?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.Brightness = 1.25
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = canvas or Vector2.new(600, 200)
	gui.MaxDistance = 650
	gui.Parent = part
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = bg or Color3.new(0, 0, 0)
	frame.BackgroundTransparency = bgTransparency or 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.8)
	label.Position = UDim2.fromScale(0.04, 0.1)
	label.Font = font or Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = textColor:Lerp(Color3.new(1, 1, 1), 0.6)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = label
	return gui, frame, label
end

---------------------------------------------------------------------
-- Palette
---------------------------------------------------------------------
local WET = Config.Graphics.WetRoads
-- wet roads: dark, smooth and slightly reflective so street lights leave glossy highlights
-- real asphalt texture either way; wet roads are a touch darker and glossier
local ASPHALT = if WET then Color3.fromRGB(38, 38, 42) else Color3.fromRGB(48, 48, 52)
local ROAD_MAT = Enum.Material.Asphalt
local ROAD_OPTS = { reflectance = if WET then 0.05 else 0 }
local SIDEWALK = Color3.fromRGB(78, 78, 84)
local CURB_COLOR = Color3.fromRGB(110, 110, 116)
local LINE_WHITE = Color3.fromRGB(205, 205, 200)
local LINE_YELLOW = Color3.fromRGB(230, 170, 30)
local STREETLIGHT = Color3.fromRGB(255, 202, 146) -- warm sodium-white
local METAL = Color3.fromRGB(38, 40, 44)

local WINDOW_COLORS = {
	Color3.fromRGB(158, 126, 88),
	Color3.fromRGB(150, 110, 70),
	Color3.fromRGB(165, 142, 110),
	Color3.fromRGB(112, 128, 150),
	Color3.fromRGB(96, 116, 146),
	Color3.fromRGB(134, 140, 152),
}
local NEON_COLORS = {
	Color3.fromRGB(255, 40, 140),
	Color3.fromRGB(0, 230, 255),
	Color3.fromRGB(150, 70, 255),
	Color3.fromRGB(255, 120, 0),
	Color3.fromRGB(40, 255, 140),
	Color3.fromRGB(255, 230, 40),
	Color3.fromRGB(255, 60, 60),
}
local SHOP_NAMES = {
	"NOODLE BAR", "24/7", "HOTEL NOVA", "ARCADE", "SUSHI", "PHARMACY", "NEON CLUB", "PIZZA",
	"MOTEL", "JAZZ", "RAMEN", "CINEMA", "GYM", "CAFE", "TATTOO", "DINER", "KARAOKE", "BARBER",
	"TACOS", "VINYL", "LOUNGE", "BOBA", "GARAGE", "TUNING", "DONUTS",
}
local BILLBOARDS = {
	"CITY LEGENDS", "DRIVE FAST\nLIVE LEGEND", "VORTEX V10", "NIGHT RUN", "ECLIPSE JX", "KAIZEN RZ",
	"MIDNIGHT FM 98.7", "NEON NIGHTS", "PHANTOM W16", "CUT UP\nGET PAID",
}

local function pick<T>(list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

---------------------------------------------------------------------
-- Lighting / atmosphere
---------------------------------------------------------------------
function CityBuilder.setupLighting()
	-- Rainy neon night (Highway Legends look): a dim blue moonlit base so the street lamps, neon
	-- and headlights carry the scene, wet glossy reflections, glow round every bright light and a
	-- cool, contrasty grade. Weather.lua blends its rain mood from these values.
	-- newer lighting properties may not exist on every engine version
	pcall(function()
		(Lighting :: any).Technology = Enum.Technology.Future
	end)
	pcall(function()
		(Lighting :: any).LightingStyle = (Enum :: any).LightingStyle.Realistic
	end)
	pcall(function()
		(Lighting :: any).PrioritizeLightingQuality = true
	end)
	Lighting.ClockTime = 0
	Lighting.GeographicLatitude = 30 -- the moon a little off overhead: long soft building shadows
	Lighting.Brightness = 2.3 -- owner (2026-10-17): a little brighter
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.12
	Lighting.Ambient = Color3.fromRGB(98, 102, 122) -- lifts shadowed and covered spots, like car cabins
	Lighting.OutdoorAmbient = Color3.fromRGB(116, 124, 164)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1 -- glossy paint and wet roads mirror the city
	Lighting.ExposureCompensation = 0.75
	Lighting.ColorShift_Top = Color3.fromRGB(120, 140, 200)
	Lighting.ColorShift_Bottom = Color3.fromRGB(8, 8, 18)

	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
			child:Destroy()
		end
	end

	local sky = Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.MoonAngularSize = 11
	sky.Parent = Lighting

	-- city haze: far blocks fade into a deep blue, near ones stay clear
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.3
	atmo.Offset = 0.12
	atmo.Color = Color3.fromRGB(86, 100, 148)
	atmo.Decay = Color3.fromRGB(40, 46, 84)
	atmo.Glare = 0.25
	atmo.Haze = 1.2
	atmo.Parent = Lighting

	-- a soft glow round genuinely bright things (lamps, neon, lights), not round paint or the
	-- dashboard screens (owner, 2026-10-17: the glow made first person hard to see)
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.7
	bloom.Size = 32
	bloom.Threshold = 1.45
	bloom.Parent = Lighting

	-- faint shafts from the moon through the towers
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.03
	rays.Spread = 0.5
	rays.Parent = Lighting

	-- cool shadows, deep blacks, rich colour
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.02
	cc.Contrast = 0.18
	cc.Saturation = 0.14
	cc.TintColor = Color3.fromRGB(236, 242, 255)
	cc.Parent = Lighting
end

---------------------------------------------------------------------
-- Roads
---------------------------------------------------------------------
local function dashedLine(parent: Instance, a: Vector3, b: Vector3, width: number, dash: number, gap: number, color: Color3)
	local dir = b - a
	local len = dir.Magnitude
	local unit = dir.Unit
	local look = CFrame.lookAt(Vector3.zero, unit)
	local s = gap / 2
	while s + dash <= len do
		local center = a + unit * (s + dash / 2)
		deco(parent, Vector3.new(width, 0.05, dash), CFrame.new(center.X, 0.03, center.Z) * look.Rotation, color, Enum.Material.SmoothPlastic, { reflectance = 0.05 })
		s += dash + gap
	end
end

local function solidLine(parent: Instance, a: Vector3, b: Vector3, width: number, color: Color3)
	-- (in pieces: a part can be at most 2048 studs long)
	local n = math.max(1, math.ceil((b - a).Magnitude / 1000))
	for k = 0, n - 1 do
		local pa, pb = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
		local center = (pa + pb) / 2
		deco(parent, Vector3.new(width, 0.05, (pb - pa).Magnitude), CFrame.lookAt(Vector3.new(center.X, 0.03, center.Z), Vector3.new(pb.X, 0.03, pb.Z)), color, Enum.Material.SmoothPlastic, { reflectance = 0.05 })
	end
end

local function buildRoadMarkings(parent: Instance)
	local root = folder("Markings", parent)
	-- segments between adjacent intersections
	for i = 0, N do
		for j = 0, N do
			local a = CityLayout.intersectionPos(i, j)
			local marks = lodGroup(root, `Cell_{i}_{j}`, a + Vector3.new(B / 4, 0, B / 4), 420)
			for k = 1, 2 do -- east and south neighbours only (each road once)
				local ni, nj = i + (if k == 1 then 1 else 0), j + (if k == 2 then 1 else 0)
				if CityLayout.inGrid(ni, nj) then
					local b = CityLayout.intersectionPos(ni, nj)
					local dir = CityLayout.Dirs[k]
					local right = dir:Cross(Vector3.yAxis)
					local s0 = a + dir * (HALF_ROAD + 4)
					local s1 = b - dir * (HALF_ROAD + 4)
					-- double yellow centre line
					solidLine(marks, s0 + right * 0.35, s1 + right * 0.35, 0.3, LINE_YELLOW)
					solidLine(marks, s0 - right * 0.35, s1 - right * 0.35, 0.3, LINE_YELLOW)
					-- lane dividers
					for side = -1, 1, 2 do
						dashedLine(marks, s0 + right * side * C.LaneWidth, s1 + right * side * C.LaneWidth, 0.35, 10, 14, LINE_WHITE)
					end
				end
			end
			-- stop lines + crosswalks on each approach
			for k = 1, 4 do
				local dir = CityLayout.Dirs[k]
				local pi, pj = i - (if k == 1 then 1 elseif k == 3 then -1 else 0), j - (if k == 2 then 1 elseif k == 4 then -1 else 0)
				if CityLayout.inGrid(pi, pj) then
					local right = dir:Cross(Vector3.yAxis)
					local stop = a - dir * (HALF_ROAD + CityLayout.StopLineGap - 0.6)
					local center = stop + right * (HALF_ROAD / 2)
					deco(marks, Vector3.new(HALF_ROAD - 1, 0.05, 1.2), CFrame.lookAt(Vector3.new(center.X, 0.035, center.Z), Vector3.new(center.X, 0.035, center.Z) + dir), LINE_WHITE, Enum.Material.SmoothPlastic)
					-- zebra crossing just inside the intersection box
					local cw = a - dir * (HALF_ROAD - 3)
					for s = -3, 3 do
						local p = cw + right * (s * HALF_ROAD / 3.6)
						deco(marks, Vector3.new(4, 0.05, 5), CFrame.lookAt(Vector3.new(p.X, 0.035, p.Z), Vector3.new(p.X, 0.035, p.Z) + dir), LINE_WHITE, Enum.Material.SmoothPlastic, { transparency = 0.1 })
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Street furniture
---------------------------------------------------------------------
local function streetLight(parent: Instance, base: Vector3, armDir: Vector3)
	local height = 22
	mk(parent, Vector3.new(height, 0.7, 0.7), CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "LampPost" })
	local armEnd = base + Vector3.new(0, height, 0) + armDir * 7
	deco(parent, Vector3.new(0.4, 0.4, 7), CFrame.lookAt((base + Vector3.new(0, height, 0) + armEnd) / 2, armEnd), METAL, Enum.Material.Metal)
	local head = deco(parent, Vector3.new(2.6, 0.5, 1.2), CFrame.lookAt(armEnd - Vector3.new(0, 0.3, 0), armEnd - Vector3.new(0, 0.3, 0) + armDir), METAL, Enum.Material.Metal)
	local lamp = deco(parent, Vector3.new(2.2, 0.15, 1), head.CFrame * CFrame.new(0, -0.3, 0), STREETLIGHT, Enum.Material.Neon)
	-- a bright warm pool on the road; near the camera it also casts shadows (WorldFx)
	local pool = addLight("SpotLight", lamp, STREETLIGHT, 62, 2.4, Enum.NormalId.Bottom, 130)
	CollectionService:AddTag(pool, "ShadowLight")
end

-- fictional street names for the arm signs: roads along Z (index i) and along X (index j)
local NS_NAMES = { "HARBOR ST", "NEON BLVD", "KAIZEN ST", "MAIN ST", "LEGEND AVE", "VORTEX ST", "MIDNIGHT ST", "ECLIPSE ST", "ORION ST" }
local EW_NAMES = { "1ST AVE", "2ND AVE", "3RD AVE", "CENTRAL AVE", "5TH AVE", "6TH AVE", "7TH AVE", "8TH AVE", "9TH AVE" }
local SIGNAL_METAL = Color3.fromRGB(46, 50, 56)
local SIGNAL_YELLOW = Color3.fromRGB(214, 168, 30)
local LENS_OFF = { R = Color3.fromRGB(52, 8, 8), Y = Color3.fromRGB(56, 38, 4), G = Color3.fromRGB(6, 40, 22) }

-- one signal head: black housing on a backplate with a reflective yellow border, three lenses
-- under tunnel visors, and a small glow light the client colours with the lit lens
local function signalHead(parent: Instance, cf: CFrame, i: number, j: number, axis: string, small: boolean?)
	local sc = if small then 0.8 else 1
	-- backplate: black from behind, a yellow border round a black middle from the front
	deco(parent, Vector3.new(2.9, 6.1, 0.06) * sc, cf * CFrame.new(0, 0, 0.68 * sc), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
	deco(parent, Vector3.new(2.9, 6.1, 0.06) * sc, cf * CFrame.new(0, 0, 0.62 * sc), SIGNAL_YELLOW, Enum.Material.SmoothPlastic, { reflectance = 0.1 })
	deco(parent, Vector3.new(2.55, 5.75, 0.06) * sc, cf * CFrame.new(0, 0, 0.57 * sc), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
	deco(parent, Vector3.new(1.7, 5.1, 1.1) * sc, cf, Color3.fromRGB(22, 23, 26), Enum.Material.Metal)
	for idx, state in { "R", "Y", "G" } do
		local y = (2 - idx) * 1.6 * sc
		-- cylinder axis is X: turn it so the round face looks down the road
		local lamp = deco(parent, Vector3.new(0.25, 1.2, 1.2) * sc, cf * CFrame.new(0, y, -0.58 * sc) * CFrame.Angles(0, math.pi / 2, 0), LENS_OFF[state], Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, name = "Lamp" })
		lamp:SetAttribute("I", i)
		lamp:SetAttribute("J", j)
		lamp:SetAttribute("Axis", axis)
		lamp:SetAttribute("State", state)
		CollectionService:AddTag(lamp, "TrafficLamp")
		-- tunnel visor: a hood over the top and down both sides
		deco(parent, Vector3.new(1.45, 0.08, 0.9) * sc, cf * CFrame.new(0, y + 0.7 * sc, -1.0 * sc), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
		for _, sx in { -1, 1 } do
			deco(parent, Vector3.new(0.08, 0.75, 0.75) * sc, cf * CFrame.new(sx * 0.7 * sc, y + 0.3 * sc, -0.95 * sc), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
		end
	end
	local glowPart = deco(parent, Vector3.new(0.2, 0.2, 0.2), cf * CFrame.new(0, 0, -1.6 * sc), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "SignalGlow" })
	-- (a LOD light: switched off when the camera is far away)
	local glow = addLight("PointLight", glowPart, Color3.fromRGB(255, 35, 35), if small then 9 else 14, 1.4)
	glow:SetAttribute("I", i)
	glow:SetAttribute("J", j)
	glow:SetAttribute("Axis", axis)
	CollectionService:AddTag(glow, "SignalGlow")
end

local function trafficSignal(parent: Instance, i: number, j: number, k: number)
	-- signals for traffic travelling in direction k into intersection (i, j), on the far side of
	-- the junction like real ones (owner, 2026-10-17: "make the traffic lights look good"): a mast
	-- pole on the far right corner, an arm over the approach lanes with a head over each lane and
	-- the cross street's name sign, and a lower head on the pole itself
	local center = CityLayout.intersectionPos(i, j)
	local dir = CityLayout.Dirs[k]
	local right = dir:Cross(Vector3.yAxis)
	local axis = if k % 2 == 1 then "X" else "Z"
	-- (where the far side is the highway's mouth, the pole stands beyond the highway's edge)
	local poleSide = if i == N and j == CityLayout.HighwayJ and k == 1 then HW + 8 else HALF_ROAD + 4
	local poleBase = center + dir * (HALF_ROAD + 6) + right * poleSide + Vector3.new(0, CURB, 0)
	local poleH = 21
	-- base plinth, the pole and a cap
	mk(parent, Vector3.new(2.6, 1.4, 2.6), CFrame.new(poleBase + Vector3.new(0, 0.7, 0)), Color3.fromRGB(70, 72, 76), Enum.Material.Concrete, { name = "SignalBase" })
	mk(parent, Vector3.new(poleH, 1.1, 1.1), CFrame.new(poleBase + Vector3.new(0, poleH / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), SIGNAL_METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "SignalPole", reflectance = 0.08 })
	deco(parent, Vector3.new(1.4, 0.5, 1.4), CFrame.new(poleBase + Vector3.new(0, poleH + 0.25, 0)), SIGNAL_METAL, Enum.Material.Metal)
	-- the mast arm, reaching over the approach lanes, with a brace under it
	local armLen = poleSide
	local armStart = poleBase + Vector3.new(0, poleH - 2, 0)
	local armEnd = armStart - right * armLen
	deco(parent, Vector3.new(0.7, 0.7, armLen), CFrame.lookAt((armStart + armEnd) / 2, armEnd), SIGNAL_METAL, Enum.Material.Metal, { reflectance = 0.08 })
	local braceA = poleBase + Vector3.new(0, poleH - 6, 0)
	local braceB = armStart - right * 9
	deco(parent, Vector3.new(0.35, 0.35, (braceB - braceA).Magnitude), CFrame.lookAt((braceA + braceB) / 2, braceB), SIGNAL_METAL, Enum.Material.Metal)
	-- a head hanging over the middle of each approach lane, facing the oncoming cars
	for l = 1, C.LanesPerSide do
		local headPos = center + dir * (HALF_ROAD + 6) + right * CityLayout.laneOffset(l)
		headPos = Vector3.new(headPos.X, armStart.Y - 3.4, headPos.Z)
		deco(parent, Vector3.new(0.25, 0.9, 0.25), CFrame.new(headPos + Vector3.new(0, 3, 0)), SIGNAL_METAL, Enum.Material.Metal)
		signalHead(parent, CFrame.lookAt(headPos, headPos - dir), i, j, axis)
	end
	-- the cross street's name on the arm, near the pole
	local crossName = if axis == "X" then NS_NAMES[i + 1] else EW_NAMES[j + 1]
	local signPos = armStart - right * (armLen - 4) + Vector3.new(0, 1.6, 0)
	local sign = deco(parent, Vector3.new(11, 2.2, 0.2), CFrame.lookAt(signPos, signPos - dir), Color3.fromRGB(14, 96, 52), Enum.Material.SmoothPlastic, { name = "StreetSign" })
	surfaceText(sign, Enum.NormalId.Front, crossName or "", Color3.fromRGB(245, 245, 245), Color3.fromRGB(14, 96, 52), 0, Enum.Font.GothamBold, Vector2.new(550, 110))
	-- a lower head on the pole for cars at the front of the queue
	local lowPos = poleBase + Vector3.new(0, 10, 0) - right * 1.4
	signalHead(parent, CFrame.lookAt(lowPos, lowPos - dir), i, j, axis, true)
	-- a pedestrian signal box facing across the side street
	local pedPos = poleBase + Vector3.new(0, 8, 0) + dir * 0.9
	local ped = deco(parent, Vector3.new(1.3, 1.3, 0.6), CFrame.lookAt(pedPos, pedPos + dir), Color3.fromRGB(22, 23, 26), Enum.Material.Metal)
	deco(parent, Vector3.new(1, 1, 0.1), ped.CFrame * CFrame.new(0, 0, -0.32), Color3.fromRGB(255, 150, 60), Enum.Material.Neon, { transparency = 0.25 })
end

---------------------------------------------------------------------
-- Buildings
---------------------------------------------------------------------
local CROWN_COLORS = {
	Color3.fromRGB(235, 245, 255),
	Color3.fromRGB(235, 245, 255),
	Config.Theme.Accent,
	Config.Theme.Accent2,
	Color3.fromRGB(255, 190, 90),
	Color3.fromRGB(150, 70, 255),
}
local CORP_NAMES = {
	"NOVA BANK", "ORION", "HALCYON", "VANTA", "APEX", "AURORA", "MERIDIAN", "KESTREL",
	"OBSIDIAN", "LUMEN", "SOLACE HOTEL", "ZENITH", "PARAGON", "ARCLIGHT", "HELIX",
}

type Palette = {
	kind: string, -- facade texture style (FacadeTex): glass / panel / stone / brick
	body: Color3,
	mat: Enum.Material,
	refl: number,
	fin: Color3,
	finMat: Enum.Material,
	finW: number, -- mullion / pier width
	module: number, -- window module (centre-to-centre spacing)
	winH: number, -- window height within an 11 stud floor
	warm: boolean,
	lit: number,
	ledges: boolean,
	punched: boolean, -- solid wall with punched windows (needs dark panes)
}

local function randomPalette(kind: string): Palette
	local warm = rng:NextNumber() < 0.55
	local lit = rng:NextNumber(0.3, 0.6)
	if kind == "glass" then
		local tints = { Color3.fromRGB(20, 30, 46), Color3.fromRGB(16, 24, 32), Color3.fromRGB(30, 36, 50), Color3.fromRGB(18, 34, 38), Color3.fromRGB(42, 36, 30) }
		return { kind = "glass", body = pick(tints), mat = Enum.Material.Glass, refl = 0.35, fin = Color3.fromRGB(96, 100, 108), finMat = Enum.Material.Metal, finW = 0.5, module = 6.5, winH = 7.5, warm = warm, lit = lit, ledges = false, punched = false }
	elseif kind == "stone" then
		local stones = { Color3.fromRGB(118, 110, 98), Color3.fromRGB(92, 90, 88), Color3.fromRGB(130, 120, 104) }
		local c = pick(stones)
		return { kind = "stone", body = c, mat = Enum.Material.Limestone, refl = 0, fin = c:Lerp(Color3.new(0, 0, 0), 0.15), finMat = Enum.Material.Limestone, finW = 1.8, module = 7.5, winH = 6, warm = true, lit = lit, ledges = true, punched = true }
	elseif kind == "brick" then
		local c = pick({ Color3.fromRGB(104, 58, 44), Color3.fromRGB(86, 52, 42), Color3.fromRGB(120, 76, 58) })
		return { kind = "brick", body = c, mat = Enum.Material.Brick, refl = 0, fin = c:Lerp(Color3.new(0, 0, 0), 0.1), finMat = Enum.Material.Brick, finW = 2, module = 7, winH = 5.5, warm = true, lit = lit, ledges = true, punched = true }
	end
	-- dark metal panel office block
	return { kind = "panel", body = Color3.fromRGB(44, 46, 54), mat = Enum.Material.SmoothPlastic, refl = 0.12, fin = Color3.fromRGB(28, 28, 32), finMat = Enum.Material.Metal, finW = 0.9, module = 7, winH = 6.5, warm = warm, lit = lit, ledges = false, punched = true }
end

local FACE_DEFS = {
	{ n = Vector3.new(0, 0, -1), axis = "X" },
	{ n = Vector3.new(0, 0, 1), axis = "X" },
	{ n = Vector3.new(-1, 0, 0), axis = "Z" },
	{ n = Vector3.new(1, 0, 0), axis = "Z" },
}

local PANE = Color3.fromRGB(16, 20, 28)

--[[
	One block-shaped section of a building. Every face is laid out on a window
	grid: lit windows come in runs of whole modules (rooms with the lights on),
	mullions / stone piers sit on the module lines, punched-window walls get
	dark glass panes on every floor, and stone/brick gets floor ledges.
	Fine facade parts go into `fine` (a LOD group) when given.
]]
local function facadeTier(model: Instance, cx: number, cz: number, w: number, dpt: number, y0: number, y1: number, pal: Palette, premium: boolean, skipFace: Vector3?, fine: Instance?)
	local h = y1 - y0
	local fineParent = fine or model
	local tower = mk(model, Vector3.new(w, h, dpt), CFrame.new(cx, y0 + h / 2, cz), pal.body, pal.mat, { reflectance = pal.refl, name = "Tower" })
	-- the client paints real facade textures from these (see BuildingSkin)
	tower:SetAttribute("Style", pal.kind)
	tower:SetAttribute("Module", pal.module)
	tower:SetAttribute("Warm", pal.warm)
	tower:SetAttribute("Busy", pal.lit > 0.45)
	tower:SetAttribute("BaseY", y0)
	if skipFace then
		tower:SetAttribute("SkipFace", skipFace)
	end
	local floorH = 11
	local floors = math.floor((h - 3) / floorH)
	for _, face in FACE_DEFS do
		if skipFace and face.n:Dot(skipFace) > 0.9 then
			continue -- nobody ever sees this side
		end
		local len = if face.axis == "X" then w else dpt
		local off = if face.axis == "X" then dpt / 2 else w / 2
		local tangent = face.n:Cross(Vector3.yAxis)
		-- window grid for this face (cap the column count to keep part counts sane)
		local cols = math.max(2, math.floor((len - 2) / pal.module))
		local maxCols = if skipFace then 8 else 12 -- skyline ring buildings get a coarser grid
		if cols > maxCols then
			cols = maxCols
		end
		local module = (len - 2) / cols
		local function colX(c: number): number
			return -((len - 2) / 2) + (c - 0.5) * module
		end
		for f = 1, floors do
			local y = y0 + 1.5 + (f - 0.5) * floorH
			-- dark panes across the floor for punched-window walls
			if premium and pal.punched then
				local pc = Vector3.new(cx, y, cz) + face.n * (off + 0.04)
				deco(fineParent, Vector3.new(len - 2, pal.winH, 0.12), CFrame.lookAt(pc, pc + face.n), PANE, Enum.Material.Glass, { reflectance = 0.3, name = "Pane" })
			end
			-- runs of lit rooms; neighbouring lit runs merge into one part (the
			-- mullions drawn on top still show the individual windows)
			local litStart: number? = nil
			local function flush(lastCol: number)
				if litStart then
					local first = litStart :: number
					local mid = (colX(first) + colX(lastCol)) / 2
					local width = (lastCol - first + 1) * module - pal.finW
					local color = if pal.warm then WINDOW_COLORS[rng:NextInteger(1, 3)] else WINDOW_COLORS[rng:NextInteger(3, 6)]
					local center = Vector3.new(cx, y, cz) + face.n * (off + 0.08) + tangent * mid
					deco(model, Vector3.new(width, pal.winH - 0.4, 0.14), CFrame.lookAt(center, center + face.n), color, Enum.Material.Neon, { transparency = rng:NextNumber(0.2, 0.42), name = "WinLit" })
					litStart = nil
				end
			end
			local c = 1
			while c <= cols do
				local run = math.min(cols - c + 1, rng:NextInteger(1, 4))
				if rng:NextNumber() < pal.lit then
					litStart = litStart or c
				else
					flush(c - 1)
				end
				c += run
			end
			flush(cols)
		end
		-- mullions / piers on every module line
		if premium then
			for k = 1, cols - 1 do
				local t = colX(k) + module / 2
				local pos = Vector3.new(cx, y0 + h / 2, cz) + face.n * (off + 0.3) + tangent * t
				deco(fineParent, Vector3.new(pal.finW, h, 0.6), CFrame.lookAt(pos, pos + face.n), pal.fin, pal.finMat, { reflectance = if pal.finMat == Enum.Material.Metal then 0.2 else 0, name = "Fin" })
			end
			-- corner piers frame the facade
			for _, sgn in { -1, 1 } do
				local pos = Vector3.new(cx, y0 + h / 2, cz) + face.n * (off + 0.3) + tangent * (sgn * (len / 2 - 0.6))
				deco(fineParent, Vector3.new(1.4, h, 0.7), CFrame.lookAt(pos, pos + face.n), pal.fin, pal.finMat)
			end
		end
	end
	-- floor ledges (stone / brick)
	if premium and pal.ledges then
		for f = 1, floors do
			local y = y0 + 1.5 + f * floorH - floorH / 2 - pal.winH / 2 - 0.4
			deco(fineParent, Vector3.new(w + 1, 0.6, dpt + 1), CFrame.new(cx, y, cz), pal.fin, pal.finMat, { name = "Ledge" })
		end
	end
	-- dark granite plinth where the building meets the street
	if y0 <= CURB + 0.01 then
		mk(model, Vector3.new(w + 0.8, 3, dpt + 0.8), CFrame.new(cx, y0 + 1.5, cz), Color3.fromRGB(32, 32, 36), Enum.Material.Granite, { name = "Plinth" })
	end
end

local function neonOutline(model: Instance, cx: number, cz: number, w: number, dpt: number, y: number, color: Color3, thick: number?)
	local t = thick or 0.5
	deco(model, Vector3.new(w + t, t, t), CFrame.new(cx, y, cz - dpt / 2), color, Enum.Material.Neon)
	deco(model, Vector3.new(w + t, t, t), CFrame.new(cx, y, cz + dpt / 2), color, Enum.Material.Neon)
	deco(model, Vector3.new(t, t, dpt + t), CFrame.new(cx - w / 2, y, cz), color, Enum.Material.Neon)
	deco(model, Vector3.new(t, t, dpt + t), CFrame.new(cx + w / 2, y, cz), color, Enum.Material.Neon)
end

local function rooftopKit(model: Instance, cx: number, cz: number, w: number, dpt: number, top: number, midrise: boolean)
	for _ = 1, rng:NextInteger(1, 3) do
		local ax = cx + rng:NextNumber(-w * 0.3, w * 0.3)
		local az = cz + rng:NextNumber(-dpt * 0.3, dpt * 0.3)
		deco(model, Vector3.new(rng:NextNumber(5, 9), rng:NextNumber(3, 5), rng:NextNumber(5, 9)), CFrame.new(ax, top + 2.5, az), Color3.fromRGB(70, 72, 76), Enum.Material.DiamondPlate, { shadow = true })
	end
	if midrise and rng:NextNumber() < 0.6 then
		-- classic wooden water tank on legs
		local tx, tz = cx + w * 0.22, cz - dpt * 0.22
		for _, o in { { -2.5, -2.5 }, { 2.5, 2.5 }, { -2.5, 2.5 }, { 2.5, -2.5 } } do
			deco(model, Vector3.new(0.6, 8, 0.6), CFrame.new(tx + o[1], top + 4, tz + o[2]), METAL, Enum.Material.Metal)
		end
		deco(model, Vector3.new(10, 9, 9), CFrame.new(tx, top + 12.5, tz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 50, 36), Enum.Material.WoodPlanks, { shape = Enum.PartType.Cylinder, shadow = true })
		deco(model, Vector3.new(10, 3, 10), CFrame.new(tx, top + 18.5, tz), Color3.fromRGB(50, 36, 28), Enum.Material.WoodPlanks, { class = "Wedge" })
	end
end

local function lobby(model: Instance, cx: number, cz: number, w: number, dpt: number, base: number, front: Vector3, tower: boolean)
	local tangent = front:Cross(Vector3.yAxis)
	local frontLen = if math.abs(front.X) > 0.5 then dpt else w
	local frontOff = if math.abs(front.X) > 0.5 then w / 2 else dpt / 2
	-- double height glowing lobby glass
	local glassPos = Vector3.new(cx, base + 7, cz) + front * (frontOff + 0.1)
	deco(model, Vector3.new(frontLen * 0.9, 12, 0.2), CFrame.lookAt(glassPos, glassPos + front), Color3.fromRGB(140, 116, 86), Enum.Material.Neon, { transparency = 0.3 })
	-- mullions
	for k = -3, 3 do
		local p = glassPos + front * 0.2 + tangent * (k * frontLen * 0.13)
		deco(model, Vector3.new(0.5, 12, 0.4), CFrame.lookAt(p, p + front), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	end
	-- cantilevered canopy with a downlight strip
	local canopyW = math.min(frontLen * 0.55, 34)
	local cpos = Vector3.new(cx, base + 13.5, cz) + front * (frontOff + 3)
	local canopy = deco(model, Vector3.new(canopyW, 0.9, 6), CFrame.lookAt(cpos, cpos + front), Color3.fromRGB(16, 16, 18), Enum.Material.Metal, { shadow = true })
	deco(model, Vector3.new(canopyW - 1, 0.15, 0.6), canopy.CFrame * CFrame.new(0, -0.5, -2.2), Color3.fromRGB(255, 230, 200), Enum.Material.Neon)
	if tower then
		local nameplate = deco(model, Vector3.new(canopyW - 2, 2.2, 0.3), canopy.CFrame * CFrame.new(0, 1.6, -2.8), Color3.fromRGB(10, 10, 12), Enum.Material.SmoothPlastic)
		surfaceText(nameplate, Enum.NormalId.Front, pick(CORP_NAMES), Color3.fromRGB(240, 240, 250), nil, nil, Enum.Font.GothamMedium, Vector2.new(700, 70))
	end
end

local function shopSign(model: Instance, cx: number, cz: number, w: number, dpt: number, base: number, front: Vector3)
	local tangent = front:Cross(Vector3.yAxis)
	local frontLen = if math.abs(front.X) > 0.5 then dpt else w
	local frontOff = if math.abs(front.X) > 0.5 then w / 2 else dpt / 2
	local neon = pick(NEON_COLORS)
	local signPos = Vector3.new(cx, base + 17.5, cz) + front * (frontOff + 0.6) + tangent * rng:NextNumber(-frontLen * 0.2, frontLen * 0.2)
	local sign = deco(model, Vector3.new(math.min(30, frontLen * 0.6), 5, 0.6), CFrame.lookAt(signPos, signPos + front), Color3.fromRGB(10, 10, 12), Enum.Material.SmoothPlastic)
	surfaceText(sign, Enum.NormalId.Front, pick(SHOP_NAMES), neon, nil, nil, Enum.Font.GothamBlack, Vector2.new(600, 100))
	local signGlow = deco(model, Vector3.new(sign.Size.X + 0.6, 0.25, 0.25), sign.CFrame * CFrame.new(0, -2.8, -0.2), neon, Enum.Material.Neon)

	if rng:NextNumber() < 0.15 then
		CollectionService:AddTag(signGlow, "Flicker")
	end
	-- vertical blade sign sticking out from the corner (very "night city")
	if rng:NextNumber() < 0.35 then
		local bladePos = Vector3.new(cx, base + 30, cz) + front * (frontOff + 3) + tangent * (frontLen / 2 - 2)
		local blade = deco(model, Vector3.new(0.8, 22, 5), CFrame.lookAt(bladePos, bladePos + front), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
		local c = pick(NEON_COLORS)
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			local _, _, lbl = surfaceText(blade, face, pick(SHOP_NAMES), c, nil, nil, Enum.Font.GothamBlack, Vector2.new(120, 520))
			lbl.Rotation = 90
			lbl.Size = UDim2.fromScale(4.2, 0.22)
			lbl.Position = UDim2.fromScale(-1.6, 0.39)
		end
		deco(model, Vector3.new(1, 22.6, 0.3), blade.CFrame * CFrame.new(0, 0, -2.6), c, Enum.Material.Neon)
	end
end

local function rooftopBillboard(model: Instance, cx: number, cz: number, top: number, front: Vector3, frontOff: number, w: number)
	local bw = math.min(w * 0.9, 60)
	local bpos = Vector3.new(cx, top + 2 + 12, cz) + front * (frontOff * 0.6)
	local board = deco(model, Vector3.new(bw, 20, 1), CFrame.lookAt(bpos, bpos + front), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
	local c1 = pick(NEON_COLORS)
	local _, frame, _ = surfaceText(board, Enum.NormalId.Front, pick(BILLBOARDS), Color3.new(1, 1, 1), c1, 0, Enum.Font.GothamBlack, Vector2.new(900, 300))
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(c1, pick(NEON_COLORS))
	grad.Rotation = rng:NextInteger(0, 90)
	grad.Parent = frame
	CollectionService:AddTag(grad, "AnimatedBoard")
	deco(model, Vector3.new(bw + 1, 0.5, 0.5), board.CFrame * CFrame.new(0, -10.3, 0), c1, Enum.Material.Neon)
	for _, sx in { -0.35, 0.35 } do
		deco(model, Vector3.new(0.6, 12, 0.6), board.CFrame * CFrame.new(bw * sx, -14, 1), METAL, Enum.Material.Metal)
	end
end

local function spire(model: Instance, cx: number, cz: number, top: number, scale: number)
	local y = top
	for _, seg in { { 26, 3.2 }, { 20, 2.0 }, { 16, 1.0 } } do
		local len, r = seg[1] * scale, seg[2] * scale
		deco(model, Vector3.new(len, r * 2, r * 2), CFrame.new(cx, y + len / 2, cz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(180, 184, 192), Enum.Material.Metal, { shape = Enum.PartType.Cylinder, reflectance = 0.3 })
		y += len
	end
	local beacon = deco(model, Vector3.one * 2, CFrame.new(cx, y + 1, cz), Color3.fromRGB(255, 20, 20), Enum.Material.Neon, { shape = Enum.PartType.Ball })
	CollectionService:AddTag(beacon, "Blink")
end

local function building(parent: Instance, cx: number, cz: number, w: number, dpt: number, h: number, base: number, frontNormal: Vector3, hideBack: boolean?)
	local skip = if hideBack then -frontNormal else nil
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = parent
	local premium = Config.Graphics.PremiumBuildings
	local frontOff = if math.abs(frontNormal.X) > 0.5 then w / 2 else dpt / 2
	-- street-level + rooftop clutter lives in a LOD group; the silhouette, windows
	-- and crown stay visible from anywhere
	local detail = lodGroup(model, "Detail", Vector3.new(cx, base + math.min(h, 60) / 2, cz), 460)
	-- window panes, mullions and ledges: invisible detail from far away
	local fine = lodGroup(model, "Facade", Vector3.new(cx, base + h / 2, cz), 620 + h * 0.6)
	local crown = pick(CROWN_COLORS)

	if h >= 250 then
		-------------------------------------------------- skyscraper
		local pal = randomPalette(if rng:NextNumber() < 0.7 then "glass" else "plastic")
		local tiers = if premium then (if h > 400 then 3 else 2) else 1
		local fractions = if tiers == 3 then { 0.55, 0.28, 0.17 } elseif tiers == 2 then { 0.7, 0.3 } else { 1 }
		local scales = { 1, 0.78, 0.58 }
		local y = base
		local tw, td = w, dpt
		for t = 1, tiers do
			tw, td = w * scales[t], dpt * scales[t]
			local y1 = y + h * fractions[t]
			facadeTier(model, cx, cz, tw, td, y, y1, pal, premium, skip, fine)
			-- setback terrace: slab + glowing edge
			mk(model, Vector3.new(tw + 1, 1.4, td + 1), CFrame.new(cx, y1 + 0.7, cz), Color3.fromRGB(22, 22, 26), Enum.Material.Concrete, { name = "Terrace" })
			if premium then
				neonOutline(model, cx, cz, tw + 1, td + 1, y1 + 1.5, crown, 0.45)
			end
			y = y1 + 1.4
		end
		local top = y
		if premium then
			-- glowing glass crown lantern
			local lw, ld = tw * 0.72, td * 0.72
			deco(model, Vector3.new(lw, 16, ld), CFrame.new(cx, top + 8, cz), Color3.fromRGB(20, 26, 36), Enum.Material.Glass, { transparency = 0.25, reflectance = 0.25 })
			deco(model, Vector3.new(lw - 1.5, 14.5, ld - 1.5), CFrame.new(cx, top + 8, cz), crown:Lerp(Color3.new(0, 0, 0), 0.45), Enum.Material.Neon, { transparency = 0.6 })
			neonOutline(model, cx, cz, lw, ld, top + 16.2, crown, 0.5)
			mk(model, Vector3.new(lw * 0.6, 3, ld * 0.6), CFrame.new(cx, top + 17.5, cz), Color3.fromRGB(26, 26, 30), Enum.Material.Metal)
			spire(model, cx, cz, top + 19, if h > 400 then 1.5 else 1)
		else
			spire(model, cx, cz, top, 1)
		end
		lobby(detail, cx, cz, w, dpt, base, frontNormal, true)
	elseif h >= 120 then
		-------------------------------------------------- tower
		local pal = randomPalette(pick({ "glass", "glass", "stone", "plastic" }))
		local twoTier = premium and rng:NextNumber() < 0.45
		local y1 = if twoTier then base + h * 0.75 else base + h
		facadeTier(model, cx, cz, w, dpt, base, y1, pal, premium, skip, fine)
		local top = y1
		local tw, td = w, dpt
		if twoTier then
			mk(model, Vector3.new(w + 1, 1.2, dpt + 1), CFrame.new(cx, y1 + 0.6, cz), Color3.fromRGB(22, 22, 26), Enum.Material.Concrete)
			tw, td = w * 0.7, dpt * 0.7
			facadeTier(model, cx, cz, tw, td, y1 + 1.2, base + h, pal, premium, skip, fine)
			top = base + h
		end
		mk(model, Vector3.new(tw + 1, 2, td + 1), CFrame.new(cx, top + 1, cz), Color3.fromRGB(25, 25, 28), Enum.Material.Concrete, { name = "Parapet" })
		if premium and rng:NextNumber() < 0.65 then
			neonOutline(model, cx, cz, tw + 1, td + 1, top + 2.2, crown, 0.4)
		end
		if h > 180 then
			spire(model, cx, cz, top + 2, 0.7)
		end
		if premium then
			rooftopKit(detail, cx, cz, tw, td, top + 2, false)
		end
		lobby(detail, cx, cz, w, dpt, base, frontNormal, rng:NextNumber() < 0.5)
		if h > 90 and rng:NextNumber() < 0.25 then
			rooftopBillboard(model, cx, cz, top, frontNormal, frontOff * (tw / w), tw)
		end
	else
		-------------------------------------------------- mid-rise
		local pal = randomPalette(pick({ "brick", "stone", "plastic" }))
		facadeTier(model, cx, cz, w, dpt, base, base + h, pal, premium, skip, fine)
		local top = base + h
		mk(model, Vector3.new(w + 1.4, 2.2, dpt + 1.4), CFrame.new(cx, top + 1.1, cz), Color3.fromRGB(30, 28, 26), Enum.Material.Concrete, { name = "Cornice" })
		if premium then
			rooftopKit(detail, cx, cz, w, dpt, top + 2.2, true)
		end
		if h > 70 and rng:NextNumber() < 0.3 then
			rooftopBillboard(model, cx, cz, top, frontNormal, frontOff, w)
		end
	end

	-- every building gets street-level life
	shopSign(detail, cx, cz, w, dpt, base, frontNormal)
	if h < 120 then
		local tangent = frontNormal:Cross(Vector3.yAxis)
		local frontLen = if math.abs(frontNormal.X) > 0.5 then dpt else w
		local shopPos = Vector3.new(cx, base + 5, cz) + frontNormal * (frontOff + 0.1)
		deco(detail, Vector3.new(frontLen * 0.85, 8, 0.2), CFrame.lookAt(shopPos, shopPos + frontNormal), Color3.fromRGB(150, 122, 90), Enum.Material.Neon, { transparency = 0.35 })
		-- striped awning
		local awnPos = Vector3.new(cx, base + 10, cz) + frontNormal * (frontOff + 2.2) + tangent * 0
		deco(detail, Vector3.new(frontLen * 0.6, 0.5, 4.5), CFrame.lookAt(awnPos, awnPos + frontNormal) * CFrame.Angles(math.rad(-14), 0, 0), pick(NEON_COLORS):Lerp(Color3.new(0, 0, 0), 0.55), Enum.Material.Fabric, { shadow = true })
	end
	return model
end

local function tree(parent: Instance, pos: Vector3)
	local h = rng:NextNumber(10, 16)
	deco(parent, Vector3.new(h, 1.1, 1.1), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(45, 32, 24), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
	for _ = 1, 3 do
		local r = rng:NextNumber(6, 9)
		deco(parent, Vector3.one * r, CFrame.new(pos + Vector3.new(rng:NextNumber(-2, 2), h + rng:NextNumber(-1, 2), rng:NextNumber(-2, 2))), Color3.fromRGB(24, 52, 30), Enum.Material.Grass, { shape = Enum.PartType.Ball, shadow = true })
	end
end

local function park(parent: Instance, cx: number, cz: number, size: number)
	local top = CURB
	mk(parent, Vector3.new(size - 20, 0.3, size - 20), CFrame.new(cx, top + 0.15, cz), Color3.fromRGB(26, 46, 28), Enum.Material.Grass, { collide = true })
	-- cross paths
	deco(parent, Vector3.new(size - 20, 0.35, 8), CFrame.new(cx, top + 0.18, cz), Color3.fromRGB(70, 66, 60), Enum.Material.Pavement)
	deco(parent, Vector3.new(8, 0.35, size - 20), CFrame.new(cx, top + 0.18, cz), Color3.fromRGB(70, 66, 60), Enum.Material.Pavement)
	-- fountain
	mk(parent, Vector3.new(1.5, 30, 30), CFrame.new(cx, top + 0.9, cz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(90, 90, 95), Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local water = deco(parent, Vector3.new(0.4, 26, 26), CFrame.new(cx, top + 1.5, cz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(40, 140, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.45 })
	addLight("PointLight", water, Color3.fromRGB(60, 150, 255), 22, 0.8)
	deco(parent, Vector3.new(10, 2, 2), CFrame.new(cx, top + 6, cz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 210, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
	for _ = 1, 14 do
		local px = cx + rng:NextNumber(-size / 2 + 20, size / 2 - 20)
		local pz = cz + rng:NextNumber(-size / 2 + 20, size / 2 - 20)
		if math.abs(px - cx) > 14 and math.abs(pz - cz) > 14 then
			tree(parent, Vector3.new(px, top + 0.3, pz))
		end
	end
	-- warm path lamps
	for _, off in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		local p = Vector3.new(cx + off[1] * size * 0.22, top, cz + off[2] * 7)
		deco(parent, Vector3.new(0.4, 8, 0.4), CFrame.new(p + Vector3.new(0, 4, 0)), METAL, Enum.Material.Metal)
		local bulb = deco(parent, Vector3.new(1.2, 1.2, 1.2), CFrame.new(p + Vector3.new(0, 8.4, 0)), STREETLIGHT, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		addLight("PointLight", bulb, STREETLIGHT, 18, 0.6)
	end
end

-- Fill a rectangular lot area with buildings on a sub-grid
local function fillBuildings(parent: Instance, x0: number, z0: number, x1: number, z1: number, heightFn: (number, number) -> number, cell: number, forcedFront: Vector3?)
	local nx = math.max(1, math.floor((x1 - x0) / cell))
	local nz = math.max(1, math.floor((z1 - z0) / cell))
	local cw = (x1 - x0) / nx
	local cd = (z1 - z0) / nz
	for ix = 0, nx - 1 do
		for iz = 0, nz - 1 do
			local cx = x0 + cw * (ix + 0.5)
			local cz = z0 + cd * (iz + 0.5)
			local w = cw * rng:NextNumber(0.68, 0.88)
			local dpt = cd * rng:NextNumber(0.68, 0.88)
			local h = heightFn(cx, cz)
			-- storefront faces whichever road is nearest
			local bx = (x0 + x1) / 2
			local bz = (z0 + z1) / 2
			local front
			local dx, dz = cx - bx, cz - bz
			if forcedFront then
				front = forcedFront
			elseif math.abs(dx) / (x1 - x0) > math.abs(dz) / (z1 - z0) then
				front = Vector3.new(if dx >= 0 then 1 else -1, 0, 0)
			else
				front = Vector3.new(0, 0, if dz >= 0 then 1 else -1)
			end
			building(parent, cx, cz, w, dpt, h, CURB, front, forcedFront ~= nil)
		end
	end
end

local function downtownHeight(x: number, z: number): number
	local dist = Vector2.new(x, z).Magnitude / C.HalfExtent
	local falloff = math.clamp(1 - dist, 0, 1)
	local h = 50 + 330 * falloff ^ 1.5 + rng:NextNumber(0, 90)
	if rng:NextNumber() < 0.12 then
		h += 120 * falloff + 60
	end
	return math.floor(h)
end

---------------------------------------------------------------------
-- City grid
---------------------------------------------------------------------
local function buildBlocks(parent: Instance)
	local blocks = folder("Blocks", parent)
	local inner = B - C.RoadWidth
	for bi = 0, N - 1 do
		for bj = 0, N - 1 do
			local cx = (CityLayout.roadCoord(bi) + CityLayout.roadCoord(bi + 1)) / 2
			local cz = (CityLayout.roadCoord(bj) + CityLayout.roadCoord(bj + 1)) / 2
			local blockFolder = folder(`Block_{bi}_{bj}`, blocks)
			-- raised sidewalk slab (acts as a curb the car slides along)
			mk(blockFolder, Vector3.new(inner, CURB, inner), CFrame.new(cx, CURB / 2, cz), SIDEWALK, Enum.Material.Pavement, { name = "Sidewalk" })
			-- curb edge highlight
			for _, s in { -1, 1 } do
				deco(blockFolder, Vector3.new(inner, CURB + 0.02, 0.8), CFrame.new(cx, CURB / 2, cz + s * (inner / 2 - 0.4)), CURB_COLOR, Enum.Material.Concrete)
				deco(blockFolder, Vector3.new(0.8, CURB + 0.02, inner), CFrame.new(cx + s * (inner / 2 - 0.4), CURB / 2, cz), CURB_COLOR, Enum.Material.Concrete)
			end

			local lot = inner - C.SidewalkWidth * 2
			-- gameplay venues first (the bank), then the landmark towers
			local landmark = Bank.block(CityBuilder.kit, blockFolder, bi, bj, cx, cz, lot) or Towers.block(CityBuilder.kit, blockFolder, bi, bj, cx, cz, lot) or CityPremium.landmark(CityBuilder.kit, blockFolder, bi, bj, cx, cz, lot)
			local isPark = not landmark and rng:NextNumber() < 0.12
			if landmark then
				-- block is taken by a landmark tower
			elseif isPark then
				park(blockFolder, cx, cz, inner)
			else
				local cell = if rng:NextNumber() < 0.25 then lot else lot / 2
				fillBuildings(blockFolder, cx - lot / 2, cz - lot / 2, cx + lot / 2, cz + lot / 2, downtownHeight, cell - 1)
			end

			-- street lights along each edge (arms reach over the road)
			for _, edge in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
				local tangent = edge:Cross(Vector3.yAxis)
				for _, t in { -0.25, 0.25 } do
					local pos = Vector3.new(cx, CURB, cz) + edge * (inner / 2 - 2) + tangent * (inner * t)
					streetLight(blockFolder, pos, edge)
				end
			end
			CityPremium.streetscape(CityBuilder.kit, blockFolder, cx, cz, inner)
		end
	end
end

local function buildSignals(parent: Instance)
	local root = folder("TrafficLights", parent)
	for i = 0, N do
		for j = 0, N do
			local signals = lodGroup(root, `Signal_{i}_{j}`, CityLayout.intersectionPos(i, j), 520)
			for k = 1, 4 do
				local dir = CityLayout.Dirs[k]
				-- approach exists if the previous intersection is in the grid
				local pi = i - math.round(dir.X)
				local pj = j - math.round(dir.Z)
				-- (and the highway's approach into the city's east edge)
				if CityLayout.inGrid(pi, pj) or (i == N and j == CityLayout.HighwayJ and k == 3) then
					trafficSignal(signals, i, j, k)
				end
			end
		end
	end
end

local function buildRing(parent: Instance)
	local ring = folder("Skyline", parent)
	local function ringHeight(_x: number, _z: number): number
		return math.floor(rng:NextNumber(110, 360))
	end
	-- {x0, z0, x1, z1, storefront direction (towards the city)}
	local regions: { { any } } = {
		{ -E - RING, -E - RING, E + RING, -E, Vector3.new(0, 0, 1) }, -- north
		{ -E - RING, E, E + RING, E + RING, Vector3.new(0, 0, -1) }, -- south
		{ -E - RING, -E, -E, E, Vector3.new(1, 0, 0) }, -- west
		{ E, -E, E + RING, -HW - 16, Vector3.new(-1, 0, 0) }, -- east (north of the highway)
		{ E, HW + 16, E + RING, E, Vector3.new(-1, 0, 0) }, -- east (south of the highway)
	}
	for _, r in regions do
		slab(ring, r[1], r[2], r[3], r[4], CURB, CURB, SIDEWALK, Enum.Material.Pavement)
		fillBuildings(ring, r[1] + 14, r[2] + 14, r[3] - 14, r[4] - 14, ringHeight, 118, r[5])
	end
	-- street lights facing the perimeter roads
	for s = -1, 1, 2 do
		for t = -E + 60, E - 60, 150 do
			streetLight(ring, Vector3.new(t, CURB, s * (E + 3)), Vector3.new(0, 0, -s))
			if math.abs(t) > HW + 30 or s == -1 then
				streetLight(ring, Vector3.new(s * (E + 3), CURB, t), Vector3.new(-s, 0, 0))
			end
		end
	end
	-- invisible boundary walls around the skyline ring (gap on the east for the highway)
	local o = E + RING
	local wallParts = {
		{ -o, -o - 2, o, -o + 2 },
		{ -o, o - 2, o, o + 2 },
		{ -o - 2, -o, -o + 2, o },
		{ o - 2, -o, o + 2, -HW - 6 },
		{ o - 2, HW + 6, o + 2, o },
	}
	for _, w in wallParts do
		slab(ring, w[1], w[2], w[3], w[4], 400, 400, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Boundary" })
	end
end

---------------------------------------------------------------------
-- Highway, mountain, tunnel and plaza
---------------------------------------------------------------------
local function cityLegendsSign(parent: Instance, pos: Vector3, width: number, height: number)
	local sign = deco(parent, Vector3.new(1, height, width), CFrame.new(pos), Color3.fromRGB(6, 6, 10), Enum.Material.SmoothPlastic, { name = "CityLegendsSign" })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.Brightness = 3
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = Vector2.new(1400, math.floor(1400 * height / width))
		gui.Parent = sign
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
		frame.BorderSizePixel = 0
		frame.Parent = gui
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(0.9, 0.62)
		label.Position = UDim2.fromScale(0.05, 0.12)
		label.Font = Enum.Font.GothamBlack
		label.Text = "CITY LEGENDS"
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = frame
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Config.Theme.Accent),
			ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Config.Theme.Accent2),
		})
		grad.Parent = label
		local sub = Instance.new("TextLabel")
		sub.BackgroundTransparency = 1
		sub.Size = UDim2.fromScale(0.9, 0.16)
		sub.Position = UDim2.fromScale(0.05, 0.76)
		sub.Font = Enum.Font.GothamBold
		sub.Text = "WELCOME TO THE NIGHT"
		sub.TextScaled = true
		sub.TextColor3 = Color3.fromRGB(180, 185, 200)
		sub.Parent = frame
	end
	-- neon frame
	local c1, c2 = Config.Theme.Accent, Config.Theme.Accent2
	deco(parent, Vector3.new(1.4, 0.5, width + 1), CFrame.new(pos + Vector3.new(0, height / 2 + 0.25, 0)), c1, Enum.Material.Neon)
	deco(parent, Vector3.new(1.4, 0.5, width + 1), CFrame.new(pos - Vector3.new(0, height / 2 + 0.25, 0)), c2, Enum.Material.Neon)
	deco(parent, Vector3.new(1.4, height + 1, 0.5), CFrame.new(pos + Vector3.new(0, 0, width / 2 + 0.25)), c2, Enum.Material.Neon)
	deco(parent, Vector3.new(1.4, height + 1, 0.5), CFrame.new(pos - Vector3.new(0, 0, width / 2 + 0.25)), c1, Enum.Material.Neon)
	for _, dx in { -6, 6 } do
		local glow = deco(parent, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos + Vector3.new(dx, -height / 2 - 1, 0)), c1, Enum.Material.SmoothPlastic, { transparency = 1 })
		addLight("PointLight", glow, if dx < 0 then c1 else c2, 40, 2.5)
	end
	return sign
end

---------------------------------------------------------------------
-- The Legends Loop: a 6-lane ring road round the city and the harbour (CityLayout.loopSample)
---------------------------------------------------------------------
local buildLoop: (Instance) -> ()

local function gantry(parent: Instance, s: number, text: string, sub: string?)
	-- an overhead sign across the clockwise half, facing the clockwise traffic
	local p, dir = CityLayout.loopSample(s)
	local right = dir:Cross(Vector3.yAxis)
	for _, off in { -LOOP_HW - 1, LOOP_HW + 1 } do
		local q = p + right * off
		mk(parent, Vector3.new(1.4, 28, 1.4), CFrame.new(q + Vector3.new(0, 14, 0)), METAL, Enum.Material.Metal, { name = "GantryPost" })
	end
	deco(parent, Vector3.new(LOOP_HW * 2 + 4, 1.6, 1.6), CFrame.lookAt(p + Vector3.new(0, 26.5, 0), p + Vector3.new(0, 26.5, 0) + dir) * CFrame.new(0, 0, 0), METAL, Enum.Material.Metal)
	local signPos = p + right * (HW / 2) + Vector3.new(0, 22, 0)
	local sign = deco(parent, Vector3.new(30, 7, 0.6), CFrame.lookAt(signPos, signPos - dir), Color3.fromRGB(10, 70, 40), Enum.Material.SmoothPlastic, { name = "LoopSign" })
	surfaceText(sign, Enum.NormalId.Front, if sub then text .. "\n" .. sub else text, Color3.new(1, 1, 1), Color3.fromRGB(10, 90, 50), 0, Enum.Font.GothamBold, Vector2.new(800, 190))
end

buildLoop = function(hwy: Instance)
	local loop = folder("Loop", hwy)
	local L = CityLayout.loopLength()
	local side = 2 * LOOP_C
	local arc = math.pi / 2 * LOOP_R
	local junction = function(p: Vector3): boolean
		-- the spur's mouth on the east side
		return p.X > LOOP_S - LOOP_HW - 30 and p.X < LOOP_S and math.abs(p.Z) < 112
	end
	-- paving: the straights as slabs, the corners as overlapping pieces
	for k = 0, 3 do
		local s0 = k * (side + arc)
		local a = CityLayout.loopSample(s0)
		local b = CityLayout.loopSample(s0 + side)
		local half = Vector3.new(LOOP_HW, 0, LOOP_HW)
		local lo, hi = a:Min(b) - half, a:Max(b) + half
		slab(loop, lo.X, lo.Z, hi.X, hi.Z, 0, 2, ASPHALT, ROAD_MAT, table.clone(ROAD_OPTS))
		local n = math.ceil(arc * (LOOP_R + LOOP_HW) / LOOP_R / 24)
		for q = 0, n - 1 do
			local s = s0 + side + arc * (q + 0.5) / n
			local p, dir = CityLayout.loopSample(s)
			local len = arc * (LOOP_R + LOOP_HW) / LOOP_R / n + 1.5
			mk(loop, Vector3.new(LOOP_HW * 2, 2, len), CFrame.lookAt(p - Vector3.new(0, 1, 0), p - Vector3.new(0, 1, 0) + dir), ASPHALT, ROAD_MAT, table.clone(ROAD_OPTS))
		end
	end
	-- the junction's corners, paved
	-- (a hair lower than the roads it meets, so nothing shimmers where they overlap)
	slab(loop, LOOP_S - LOOP_HW - 110, -116, LOOP_S - LOOP_HW + 1, 116, -0.02, 2, ASPHALT, ROAD_MAT, table.clone(ROAD_OPTS))
	-- its edges are walled in (rail + invisible wall), joining the spur's walls to the loop's
	local jx0, jx1 = LOOP_S - LOOP_HW - 110, LOOP_S - LOOP_HW + 1
	for _, sz in { -1, 1 } do
		for _, seg in { { Vector3.new(jx0, 0, sz * (HW + 3)), Vector3.new(jx0, 0, sz * 116) }, { Vector3.new(jx0, 0, sz * 116), Vector3.new(jx1, 0, sz * 116) } } do
			local a0, a1 = seg[1], seg[2]
			local cen, len = (a0 + a1) / 2, (a1 - a0).Magnitude + 0.6
			mk(loop, Vector3.new(0.6, 1.2, len), CFrame.lookAt(cen + Vector3.new(0, 2.2, 0), a1 + Vector3.new(0, 2.2, 0)), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { reflectance = 0.2, name = "GuardRail" })
			mk(loop, Vector3.new(2, 60, len), CFrame.lookAt(cen + Vector3.new(0, 30, 0), a1 + Vector3.new(0, 30, 0)), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
		end
	end

	-- markings, rails, barrier and lights, walked along the loop in chunks (LOD groups)
	local CHUNK = 600
	local chunks = math.ceil(L / CHUNK)
	local walls = folder("LoopWalls", loop)
	for c = 0, chunks - 1 do
		local cs0, cs1 = c * CHUNK, math.min(L, (c + 1) * CHUNK)
		local mid = CityLayout.loopSample((cs0 + cs1) / 2)
		local marks = lodGroup(loop, `Loop_{c}`, mid, 900)
		-- (straight stretches get long pieces, corners short ones)
		local function piece(s: number): number
			local local_ = s % (side + arc)
			return if local_ < side then 120 else 20
		end
		local s = cs0
		while s < cs1 - 0.1 do
			local step = math.min(piece(s), cs1 - s)
			local pa = CityLayout.loopSample(s)
			local pb = CityLayout.loopSample(s + step)
			local function line(off: number, w: number, color: Color3)
				-- (sampled with the offset, so on the corners it follows the curve)
				local q0 = CityLayout.loopSample(s, off)
				local q1 = CityLayout.loopSample(s + step, off)
				local cen = (q0 + q1) / 2
				deco(marks, Vector3.new(w, 0.05, (q1 - q0).Magnitude + 0.3), CFrame.lookAt(Vector3.new(cen.X, 0.03, cen.Z), Vector3.new(q1.X, 0.03, q1.Z)), color, Enum.Material.SmoothPlastic, { reflectance = 0.05 })
			end
			-- edge lines and the double yellow either side of the barrier
			for _, off in { -HW + 1, HW - 1 } do
				line(off, 0.4, LINE_WHITE)
			end
			for _, off in { -1.2, 1.2 } do
				line(off, 0.3, LINE_YELLOW)
			end
			-- concrete median barrier
			do
				local cen = (pa + pb) / 2
				mk(marks, Vector3.new(1.4, 2.6, (pb - pa).Magnitude + 0.4), CFrame.lookAt(cen + Vector3.new(0, 1.3, 0), pb + Vector3.new(0, 1.3, 0)), Color3.fromRGB(84, 84, 82), Enum.Material.Concrete, { name = "Barrier" })
			end
			-- guard rails and invisible walls on both outer edges (open at the junction)
			for _, sgn in { -1, 1 } do
				local q0 = CityLayout.loopSample(s, sgn * (LOOP_HW - 2))
				local q1 = CityLayout.loopSample(s + step, sgn * (LOOP_HW - 2))
				if not (junction(q0) or junction(q1)) then
					local cen = (q0 + q1) / 2
					local len = (q1 - q0).Magnitude + 0.4
					mk(marks, Vector3.new(0.6, 1.2, len), CFrame.lookAt(cen + Vector3.new(0, 2.2, 0), q1 + Vector3.new(0, 2.2, 0)), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { reflectance = 0.2, name = "GuardRail" })
					mk(walls, Vector3.new(2, 60, len), CFrame.lookAt(cen + Vector3.new(0, 30, 0), q1 + Vector3.new(0, 30, 0)), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
				end
			end
			s += step
		end
		-- dashed lane lines: 12 long, 18 apart
		local d = cs0
		while d < cs1 - 12 do
			for _, off in { -2 * C.LaneWidth, -C.LaneWidth, C.LaneWidth, 2 * C.LaneWidth } do
				local q0 = CityLayout.loopSample(d, off)
				local q1 = CityLayout.loopSample(d + 12, off)
				if not junction(q0) then
					local cen = (q0 + q1) / 2
					deco(marks, Vector3.new(0.35, 0.05, 12), CFrame.lookAt(Vector3.new(cen.X, 0.03, cen.Z), Vector3.new(q1.X, 0.03, q1.Z)), LINE_WHITE, Enum.Material.SmoothPlastic, { reflectance = 0.05 })
				end
			end
			d += 30
		end
		-- lights on the outer edges, arms over the lanes, alternating sides
		local l = cs0 + 90
		local flip = c % 2 == 0
		while l < cs1 do
			local sgn = if flip then 1 else -1
			local p, dir = CityLayout.loopSample(l, sgn * (LOOP_HW + 3))
			if not junction(p) then
				local inward = -dir:Cross(Vector3.yAxis) * sgn
				streetLight(marks, p, inward)
			end
			flip = not flip
			l += 180
		end
	end
	-- signs for the clockwise traffic: the exit to downtown ahead of the junction, and the
	-- loop's name past each corner
	gantry(loop, LOOP_C - 700, "DOWNTOWN  ➜  NEXT EXIT", "KEEP RIGHT")
	gantry(loop, LOOP_C - 140, "EXIT  ➜  DOWNTOWN")
	for k = 0, 3 do
		gantry(loop, k * (side + arc) + side + arc + 300, "LEGENDS LOOP", if k % 2 == 0 then "CITY LEGENDS 8 KM" else "NIGHT RUN  ➜")
	end
end

local function buildHighway(parent: Instance)
	local hwy = folder("Highway", parent)
	-- the land east of the city, and the mainland all round the harbour (the loop runs on it)
	local W = E + RING + 1500 -- the harbour's outer edge (CityPremium's water)
	local OUT = LOOP_S + 1100
	local grass = Color3.fromRGB(18, 26, 18)
	slab(hwy, E + RING, -E - RING, W, E + RING, -0.3, 4, grass, Enum.Material.Grass, { name = "Land" })
	slab(hwy, -OUT, -OUT, OUT, -W, -0.3, 4, grass, Enum.Material.Grass, { name = "Land" })
	slab(hwy, -OUT, W, OUT, OUT, -0.3, 4, grass, Enum.Material.Grass, { name = "Land" })
	slab(hwy, -OUT, -W, -W, W, -0.3, 4, grass, Enum.Material.Grass, { name = "Land" })
	slab(hwy, W, -W, OUT, W, -0.3, 4, grass, Enum.Material.Grass, { name = "Land" })
	-- road surface (inside the skyline ring the city asphalt is already there), out to the loop
	slab(hwy, E + RING, -HW - 6, LOOP_S - LOOP_HW, HW + 6, 0, 2, ASPHALT, ROAD_MAT, table.clone(ROAD_OPTS))

	-- markings
	local marks = folder("HighwayMarkings", hwy)
	local a = Vector3.new(HWY_X0 + 4, 0, 0)
	local b = Vector3.new(SPUR_END, 0, 0)
	solidLine(marks, a + Vector3.new(0, 0, 0.4), b + Vector3.new(0, 0, 0.4), 0.3, LINE_YELLOW)
	solidLine(marks, a - Vector3.new(0, 0, 0.4), b - Vector3.new(0, 0, 0.4), 0.3, LINE_YELLOW)
	for _, z in { -2 * C.LaneWidth, -C.LaneWidth, C.LaneWidth, 2 * C.LaneWidth } do
		dashedLine(marks, a + Vector3.new(0, 0, z), b + Vector3.new(0, 0, z), 0.35, 12, 18, LINE_WHITE)
	end
	for _, z in { -HW + 1, HW - 1 } do
		solidLine(marks, a + Vector3.new(0, 0, z), b + Vector3.new(0, 0, z), 0.4, LINE_WHITE)
	end

	-- guard rails + invisible walls
	for _, s in { -1, 1 } do
		local x0 = E + RING
		local len = SPUR_END - x0
		for part = 0, 1 do
			local cx = x0 + len * (part * 0.5 + 0.25)
			mk(hwy, Vector3.new(len / 2, 1.2, 0.6), CFrame.new(cx, 2.2, s * (HW + 2)), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { reflectance = 0.2, name = "GuardRail" })
			mk(hwy, Vector3.new(len / 2, 60, 2), CFrame.new(cx, 30, s * (HW + 3)), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
		end
		for x = x0 + 10, SPUR_END, 24 do
			if x < TUNNEL_X0 - 4 or x > TUNNEL_X1 + 4 then
				deco(hwy, Vector3.new(0.5, 2.6, 0.5), CFrame.new(x, 1.3, s * (HW + 2.2)), METAL, Enum.Material.Metal)
			end
		end
		-- reflectors (little amber dots)
		for x = x0 + 22, SPUR_END, 48 do
			deco(hwy, Vector3.new(0.4, 0.3, 0.2), CFrame.new(x, 2.2, s * (HW + 1.65)), Color3.fromRGB(255, 160, 40), Enum.Material.Neon)
		end
	end

	-- highway lights (outside the tunnel)
	for x = HWY_X0 + 40, SPUR_END, 160 do
		if x < TUNNEL_X0 - 20 or x > TUNNEL_X1 + 20 then
			streetLight(hwy, Vector3.new(x, 0, -(HW + 5)), Vector3.new(0, 0, 1))
			streetLight(hwy, Vector3.new(x + 80, 0, HW + 5), Vector3.new(0, 0, -1))
		end
	end

	-- overhead gantry sign leaving the city
	local gx = E + RING + 120
	for _, s in { -1, 1 } do
		mk(hwy, Vector3.new(1.2, 26, 1.2), CFrame.new(gx, 13, s * (HW + 4)), METAL, Enum.Material.Metal)
	end
	deco(hwy, Vector3.new(1.4, 1.4, HW * 2 + 10), CFrame.new(gx, 25, 0), METAL, Enum.Material.Metal)
	local gsign = deco(hwy, Vector3.new(0.6, 7, 34), CFrame.new(gx - 0.5, 20, HW / 2), Color3.fromRGB(10, 70, 40), Enum.Material.SmoothPlastic)
	surfaceText(gsign, Enum.NormalId.Left, "LEGENDS LOOP  ➜  2 MI", Color3.new(1, 1, 1), Color3.fromRGB(10, 90, 50), 0, Enum.Font.GothamBold, Vector2.new(800, 160))
	local gsign2 = deco(hwy, Vector3.new(0.6, 7, 34), CFrame.new(gx + 0.5, 20, -HW / 2), Color3.fromRGB(10, 70, 40), Enum.Material.SmoothPlastic)
	surfaceText(gsign2, Enum.NormalId.Right, "DOWNTOWN", Color3.new(1, 1, 1), Color3.fromRGB(10, 90, 50), 0, Enum.Font.GothamBold, Vector2.new(800, 160))

	-------------------------------------------------------------
	-- Mountain
	-------------------------------------------------------------
	local rock = Color3.fromRGB(34, 32, 32)
	local mtn = folder("Mountain", hwy)
	local mx = (TUNNEL_X0 + TUNNEL_X1) / 2
	local tunnelH = 22
	for _, s in { -1, 1 } do
		-- main massif on each side of the tunnel
		mk(mtn, Vector3.new(C.TunnelLength, 240, 700), CFrame.new(mx, 100, s * (HW + 4 + 350)), rock, Enum.Material.Slate)
		-- sloped approaches
		-- (a wedge's slope faces local -Z; rotating +90deg about Y points it at -X)
		mk(mtn, Vector3.new(700, 240, 260), CFrame.new(TUNNEL_X0 - 130, 100, s * (HW + 4 + 350)) * CFrame.Angles(0, math.pi / 2, 0), rock, Enum.Material.Slate, { class = "Wedge" })
		mk(mtn, Vector3.new(700, 240, 260), CFrame.new(TUNNEL_X1 + 130, 100, s * (HW + 4 + 350)) * CFrame.Angles(0, -math.pi / 2, 0), rock, Enum.Material.Slate, { class = "Wedge" })
		for _ = 1, 6 do
			local p = Vector3.new(mx + rng:NextNumber(-350, 350), rng:NextNumber(150, 230), s * rng:NextNumber(HW + 120, 600))
			mk(mtn, Vector3.new(rng:NextNumber(120, 240), rng:NextNumber(80, 160), rng:NextNumber(120, 240)), CFrame.new(p) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), rock, Enum.Material.Slate)
		end
	end
	-- ridge over the tunnel
	mk(mtn, Vector3.new(C.TunnelLength, 200, HW * 2 + 12), CFrame.new(mx, tunnelH + 3 + 100, 0), rock, Enum.Material.Slate)
	mk(mtn, Vector3.new(HW * 2 + 12, 120, 90), CFrame.new(TUNNEL_X0 - 45, tunnelH + 3 + 60, 0) * CFrame.Angles(0, math.pi / 2, 0), rock, Enum.Material.Slate, { class = "Wedge" })
	mk(mtn, Vector3.new(HW * 2 + 12, 120, 90), CFrame.new(TUNNEL_X1 + 45, tunnelH + 3 + 60, 0) * CFrame.Angles(0, -math.pi / 2, 0), rock, Enum.Material.Slate, { class = "Wedge" })

	-------------------------------------------------------------
	-- Tunnel
	-------------------------------------------------------------
	local tunnel = folder("Tunnel", hwy)
	local concrete = Color3.fromRGB(96, 96, 100)
	for _, s in { -1, 1 } do
		mk(tunnel, Vector3.new(C.TunnelLength, tunnelH, 3), CFrame.new(mx, tunnelH / 2, s * (HW + 2.5)), concrete, Enum.Material.Concrete, { name = "TunnelWall" })
		-- lower tiled band
		deco(tunnel, Vector3.new(C.TunnelLength, 6, 0.2), CFrame.new(mx, 4, s * (HW + 0.95)), Color3.fromRGB(190, 192, 196), Enum.Material.SmoothPlastic, { reflectance = 0.15 })
		deco(tunnel, Vector3.new(C.TunnelLength, 0.6, 0.2), CFrame.new(mx, 7.3, s * (HW + 0.9)), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		-- sodium lamps
		local idx = 0
		for x = TUNNEL_X0 + 10, TUNNEL_X1 - 10, 20 do
			idx += 1
			local lamp = deco(tunnel, Vector3.new(7, 0.7, 1), CFrame.new(x, tunnelH - 3, s * (HW + 0.6)), Color3.fromRGB(255, 160, 60), Enum.Material.Neon)
			if idx % 2 == 0 then
				addLight("PointLight", lamp, Color3.fromRGB(255, 150, 60), 30, 1.6)
			end
		end
	end
	mk(tunnel, Vector3.new(C.TunnelLength, 3, HW * 2 + 8), CFrame.new(mx, tunnelH + 1.5, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Concrete, { name = "TunnelCeiling" })
	-- centre ceiling light strip
	for x = TUNNEL_X0 + 15, TUNNEL_X1 - 15, 30 do
		deco(tunnel, Vector3.new(10, 0.3, 1.2), CFrame.new(x, tunnelH - 0.2, 0), Color3.fromRGB(255, 220, 170), Enum.Material.Neon)
	end
	-- portals
	for _, px in { TUNNEL_X0, TUNNEL_X1 } do
		local facing = if px == TUNNEL_X0 then -1 else 1
		mk(tunnel, Vector3.new(6, 12, HW * 2 + 30), CFrame.new(px + facing * 3, tunnelH + 6, 0), Color3.fromRGB(70, 70, 74), Enum.Material.Concrete, { name = "Portal" })
		for _, s in { -1, 1 } do
			mk(tunnel, Vector3.new(6, tunnelH + 12, 12), CFrame.new(px + facing * 3, (tunnelH + 12) / 2, s * (HW + 9)), Color3.fromRGB(70, 70, 74), Enum.Material.Concrete)
		end
		local plaque = deco(tunnel, Vector3.new(0.5, 6, 56), CFrame.new(px + facing * 6.3, tunnelH + 6, 0), Color3.fromRGB(10, 10, 14), Enum.Material.SmoothPlastic)
		surfaceText(plaque, if facing == -1 then Enum.NormalId.Left else Enum.NormalId.Right, "LEGENDS TUNNEL", Color3.fromRGB(255, 190, 90), nil, nil, Enum.Font.GothamBlack, Vector2.new(1100, 120))
	end

	-- THE sign
	cityLegendsSign(tunnel, Vector3.new(mx, tunnelH - 7.5, 0), 58, 10)

	buildLoop(hwy)
end

---------------------------------------------------------------------
-- Helpers shared with CityPremium
---------------------------------------------------------------------
CityBuilder.kit = {
	mk = mk,
	deco = deco,
	slab = slab,
	folder = folder,
	addLight = addLight,
	surfaceText = surfaceText,
	lodGroup = lodGroup,
	pick = pick,
	rng = rng,
	building = building,
	tree = tree,
	facadeTier = facadeTier,
	neonOutline = neonOutline,
	spire = spire,
	randomPalette = randomPalette,
	lobby = lobby,
	METAL = METAL,
	STREETLIGHT = STREETLIGHT,
	NEON_COLORS = NEON_COLORS,
	BILLBOARDS = BILLBOARDS,
}

---------------------------------------------------------------------
-- Entry point
---------------------------------------------------------------------
function CityBuilder.build(): Folder
	CityBuilder.setupLighting()

	local existing = workspace:FindFirstChild("City")
	if existing then
		existing:Destroy()
	end
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local city = Instance.new("Folder")
	city.Name = "City"

	-- one big asphalt ground: every gap between blocks is road
	local ground = folder("Ground", city)
	slab(ground, -E - RING, -E - RING, E + RING, E + RING, 0, 4, ASPHALT, ROAD_MAT, table.clone(ROAD_OPTS))

	buildRoadMarkings(city)
	buildBlocks(city)
	buildSignals(city)
	buildRing(city)
	buildHighway(city)
	CityPremium.environment(CityBuilder.kit, city)
	Mainland.build(CityBuilder.kit, city)

	city.Parent = workspace
	city:SetAttribute("Ready", true)
	return city
end

return CityBuilder
