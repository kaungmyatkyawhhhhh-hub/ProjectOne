-- GalaxyMapBuilder (Galaxy Incremental, 2 Nov): builds the STATIC map into Workspace.Galaxy from Config/MapConfig + Kit:
-- the centre island as a plaza in ZONES round the Supernova Core (MapConfig.Centre.Zones, owner's centre redesign 2 Nov):
--   FRONT the Upgrades + Tree boards (double-sided, clickable), RIGHT the Star Forge on its stepped platform, BACK the
--   Black Hole gate on its dais, BACK-LEFT the Sector 2 gate arch + IGNITION sign + its bridge, LEFT the leaderboard wall;
--   open walkways between them from every bridge to the Core, lamp posts on the rim only, small crystal accents;
-- the 8 island slots with their arched light bridges, the locked Sector 2 island across the void, the sky and the lighting.
-- Everything faces OUTWARD (to the islands); what several islands see is double-sided.
-- The islands' own pieces (tiers) are added by GalaxyMapService at runtime.
-- Run in Studio (command bar): require(game.ServerStorage.GalaxyMapBuilder).Build(). GalaxyMapService rebuilds it at server
-- start when the map still has stand-ins and the owner's kit (ReplicatedStorage.GalaxyKit) has been imported since.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy.MapConfig)
local Kit = require(Galaxy.Kit)

local C = MapConfig.Colors
local O = MapConfig.Origin
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
local function brass(props)
	props.Color = C.Brass
	props.Material = props.Material or MapConfig.BrassMaterial
	props.Reflectance = props.Reflectance or MapConfig.BrassReflectance
	return props
end
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
local function surface(p: BasePart, face: Enum.NormalId): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.MaxDistance = 220
	gui.Parent = p
	return gui
end
-- a sign on two brass posts standing on the floor (never floating): lines of text on its front (+Z), and on its back too
-- when `both` (seen from several islands)
local function sign(parent, name, base: CFrame, size: Vector3, lift: number, lines: { string }, color: Color3?, both: boolean?)
	local cf = base * CFrame.new(0, lift + size.Y / 2, 0)
	local p = part({ Name = name, Size = size, CFrame = cf, Color = Color3.fromRGB(26, 20, 34), CanCollide = false, CanQuery = false, Parent = parent })
	for _, face in ipairs(if both then { Enum.NormalId.Back, Enum.NormalId.Front } else { Enum.NormalId.Back }) do
		local gui = surface(p, face)
		for i, text in ipairs(lines) do
			label(gui, text, UDim2.fromScale(0.04, if #lines == 1 then 0.1 else (if i == 1 then 0.06 else 0.62)),
				UDim2.fromScale(0.92, if #lines == 1 then 0.8 else (if i == 1 then 0.55 else 0.32)),
				if i == 1 then (color or Color3.fromRGB(255, 214, 120)) else Color3.fromRGB(225, 215, 240))
		end
	end
	-- a brass edge round it + two posts down to the floor
	part(brass({ Name = name .. "Edge", Size = size + Vector3.new(0.3, 0.3, -0.1), CFrame = cf, CanCollide = false, CanQuery = false, Parent = parent }))
	for _, side in ipairs({ -1, 1 }) do
		local h = lift + size.Y * 0.5
		Kit.Make("Pillar", brass({ Name = name .. "Post", Size = Vector3.new(0.45, h, 0.45), CFrame = base * CFrame.new(side * (size.X / 2 - 0.4), h / 2, -0.32),
			Collide = true, Parent = parent }))
	end
	return p
end
-- a frame whose +Y points along dir (for spikes)
local function alongY(pos: Vector3, dir: Vector3): CFrame
	local right = dir:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 1e-3 then right = Vector3.new(1, 0, 0) end
	return CFrame.fromMatrix(pos, right.Unit, dir.Unit)
end
-- a frame at a zone: on the floor `dist` out from the Core at `angle`, its +Z facing OUT (to the islands)
local function zoneCf(angle: number, dist: number): CFrame
	local out = MapConfig.ZoneDir(angle)
	local pos = O + out * dist
	return CFrame.lookAt(pos, pos - out)
end

function Builder.IslandCenter(slot: number): (Vector3, Vector3, number)
	local I = MapConfig.Islands
	local a = math.rad(I.StartAngle + (slot - 1) * 360 / I.Count)
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	return O + dir * I.Ring + Vector3.new(0, I.Heights[slot] or 0, 0), dir, a
end

local function bridge(parent, A: Vector3, B: Vector3, n: number, width: number, arch: number, color: Color3, name: string)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	local pts = {}
	for k = 0, n do
		local t = k / n
		pts[k] = A:Lerp(B, t) + Vector3.new(0, math.sin(t * math.pi) * arch, 0)
	end
	for k = 1, n do
		local p0, p1 = pts[k - 1], pts[k]
		local len = (p1 - p0).Magnitude + 0.15
		local seg = Kit.Make("BridgeSegment", { Name = "Seg_" .. k, Size = Vector3.new(width, 0.4, len), CFrame = CFrame.lookAt((p0 + p1) / 2, p1),
			Color = color, Material = Enum.Material.Neon, Collide = true, Parent = folder })
		seg:SetAttribute("Index", k)
	end
	return folder, pts
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

	------------------------------------------------------------------ the centre island (the plaza)
	local centre = Instance.new("Model")
	centre.Name = "Centre"
	centre.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- (always in view: the client needs all of it)
	centre.Parent = root
	local CR = MapConfig.Centre
	local Z = CR.Zones
	Kit.Make("IslandTop", { Name = "Floor", Size = Vector3.new(CR.Radius * 2, CR.Thickness, CR.Radius * 2), CFrame = CFrame.new(O - Vector3.new(0, CR.Thickness / 2, 0)),
		Color = C.Stone, Collide = true, Parent = centre })
	-- the rock cone under it (turned and tipped a little, so it's uneven) with crystals hanging from it
	Kit.Make("IslandUnder", { Name = "Under", Size = Vector3.new(CR.Radius * 2, CR.UnderDepth, CR.Radius * 1.94),
		CFrame = CFrame.new(O - Vector3.new(0, CR.Thickness + CR.UnderDepth / 2 - 0.3, 0)) * CFrame.Angles(0.03, 0.9, -0.04), Color = C.Rock, Parent = centre })
	Kit.HangingCrystals(centre, O - Vector3.new(0, CR.Thickness, 0), CR.Radius, CR.UnderDepth, C.Crystal, 3)
	-- the floor: wedge tiles in the second stone tone between the brass inlay round the Core and the rim
	local tiles = Instance.new("Model")
	tiles.Name = "Tiles"
	tiles.Parent = centre
	Kit.TileRing(tiles, O, CR.TileRing + 0.6, CR.Radius - 2.2, 32, C.Stone2, math.rad(22.5))
	Kit.Make("RimRing", brass({ Name = "Inlay", Size = Vector3.new(CR.TileRing * 2, 0.25, CR.TileRing * 2), CFrame = CFrame.new(O + Vector3.new(0, 0.06, 0)), Parent = centre }))
	Kit.Make("RimRing", brass({ Name = "Rim", Size = Vector3.new(CR.Radius * 2 + 0.6, 1.65, CR.Radius * 2 + 0.6), CFrame = CFrame.new(O + Vector3.new(0, 0.2, 0)), Collide = true, Parent = centre }))
	-- lamp posts on the rim only: a pair at every bridge landing (the bridges are the way in)
	local I = MapConfig.Islands
	for slot = 1, I.Count do
		local landing = I.StartAngle + (slot - 1) * 360 / I.Count
		for _, side in ipairs({ -1, 1 }) do
			local d = MapConfig.ZoneDir(landing + side * CR.LampSpread)
			local p = O + d * CR.LampRing
			Kit.Make("Pillar", brass({ Name = "LampPost", Size = Vector3.new(0.9, 4, 0.9), CFrame = CFrame.new(p + Vector3.new(0, 2, 0)), Collide = true, Parent = centre }))
			Kit.Make("LampOrb", { Name = "Lamp", Size = Vector3.new(1.1, 1.1, 1.1), CFrame = CFrame.new(p + Vector3.new(0, 4.5, 0)), Color = C.Lamp, Material = Enum.Material.Neon, Parent = centre })
		end
	end
	-- the open gaps (CR.Accents): a star-chart inlay in the floor, two benches facing the Core, crystals by the rim; all
	-- off the walkways (the walkways run from each bridge landing to the Core)
	local D = CR.Details
	local details = Instance.new("Model")
	details.Name = "Details"
	details.Parent = centre
	local CHART = { { -4, -2 }, { -2, -0.8 }, { 0, -1.5 }, { 2, 0 }, { 3.6, 2.2 }, { 1.4, 3.2 }, { -0.6, 2.4 } } -- (along the rim, outward) studs
	for gi, angle in ipairs(CR.Accents) do
		local out = MapConfig.ZoneDir(angle)
		local frame = CFrame.lookAt(O + out * D.Chart, O + out * D.Chart - out) -- (+Z out, +X along the rim)
		Kit.Make("RimRing", brass({ Name = "ChartRing", Size = Vector3.new(D.ChartRadius * 2, 0.1, D.ChartRadius * 2), CFrame = frame * CFrame.new(0, 0.05, 0), Parent = details }))
		local pts = {}
		local flip = if gi % 2 == 0 then -1 else 1 -- (mirrored in every other gap, so they're not stamped)
		for i, pt in ipairs(CHART) do
			pts[i] = (frame * CFrame.new(pt[1] * flip, 0, pt[2])).Position
			part({ Name = "ChartStar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1, 1) * (if i == 4 then 1.4 else 1),
				CFrame = CFrame.new(pts[i] + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C.Lamp, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = details })
			if i > 1 then
				local a, b = pts[i - 1], pts[i]
				part(brass({ Name = "ChartLine", Size = Vector3.new(0.22, 0.06, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b) + Vector3.new(0, 0.03, 0),
					CanCollide = false, CanQuery = false, Parent = details }))
			end
		end
		for _, side in ipairs({ -1, 1 }) do
			local bf = CFrame.lookAt(O + out * D.Benches, O) * CFrame.new(side * D.BenchSpread, 0, 0)
			part({ Name = "BenchSeat", Size = Vector3.new(4.6, 0.5, 1.5), CFrame = bf * CFrame.new(0, 1.55, 0), Color = C.Stone2, Parent = details })
			for _, leg in ipairs({ -1.7, 1.7 }) do
				part(brass({ Name = "BenchLeg", Size = Vector3.new(0.45, 1.3, 1.1), CFrame = bf * CFrame.new(leg, 0.65, 0), Parent = details }))
			end
			local cr = O + out * D.RimCrystals + MapConfig.ZoneDir(angle + 90) * side * 7
			Kit.Make("CrystalCluster", { Size = Vector3.new(2.4, 3.2, 2.4), CFrame = CFrame.new(cr + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, math.rad(angle + side * 40), 0),
				Color = C.Crystal, Reflectance = 0.15, Parent = details })
		end
		local at = O + out * (CR.Radius - 6)
		Kit.Make("CrystalCluster", { Size = Vector3.new(3, 4, 3), CFrame = CFrame.new(at + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(angle), 0),
			Color = C.Crystal, Reflectance = 0.15, Parent = details })
	end
	-- the hidden spawn (everyone is moved to their own island right away)
	local spawnPad = Instance.new("SpawnLocation")
	spawnPad.Name = "SpawnLocation"
	spawnPad:SetAttribute("Galaxy", true)
	spawnPad.Size = Vector3.new(6, 0.2, 6)
	spawnPad.CFrame = CFrame.new(O + MapConfig.ZoneDir(90) * 24 + Vector3.new(0, 0.1, 0))
	spawnPad.Anchored, spawnPad.CanCollide, spawnPad.Transparency, spawnPad.Neutral = true, false, 1, true
	spawnPad.Duration = 0
	local decal = spawnPad:FindFirstChildOfClass("Decal")
	if decal then decal:Destroy() end
	spawnPad.Parent = centre

	-- the Supernova Core: altar, brass collar, the glowing core, 16 spikes, 3 gyroscope rings (the client turns them and
	-- pulses the core; it BURSTS when anyone goes Supernova). Toned down (owner): it lit the whole plaza white.
	local core = Instance.new("Model")
	core.Name = "Core"
	core.Parent = centre
	Kit.Make("Altar", { Name = "Altar", Size = Vector3.new(17, 4.4, 17), CFrame = CFrame.new(O + Vector3.new(0, 2.2, 0)), Color = C.Stone2, Collide = true, Parent = core })
	Kit.Make("RimRing", brass({ Name = "Collar", Size = Vector3.new(12.6, 0.5, 12.6), CFrame = CFrame.new(O + Vector3.new(0, 4.45, 0)), Parent = core }))
	local corePos = O + Vector3.new(0, CR.CoreHeight, 0)
	Kit.Make("CoreOrb", { Name = "CoreOrb", Size = Vector3.new(1, 1, 1) * CR.CoreRadius * 2, CFrame = CFrame.new(corePos), Color = C.Core, Material = Enum.Material.Neon, Parent = core })
	local lightHost = part({ Name = "CoreLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(corePos), Transparency = 1, CanCollide = false, CanQuery = false, Parent = core })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = Color3.fromRGB(255, 170, 90), 24, 1.4, false
	light.Parent = lightHost
	local rimHost = part({ Name = "RimLight", Size = Vector3.new(1, 1, 1), CFrame = CFrame.lookAt(O + Vector3.new(0, 13, -20), O + Vector3.new(0, 13, 10)),
		Transparency = 1, CanCollide = false, CanQuery = false, Parent = core })
	local rim = Instance.new("SpotLight")
	rim.Face, rim.Color, rim.Range, rim.Brightness, rim.Angle, rim.Shadows = Enum.NormalId.Front, Color3.fromRGB(170, 110, 255), 40, 2.5, 60, false
	rim.Parent = rimHost
	local golden = math.pi * (3 - math.sqrt(5))
	for i = 0, 15 do
		local y = 1 - (i + 0.5) / 16 * 2
		local r = math.sqrt(1 - y * y)
		local th = golden * i
		local dir = Vector3.new(math.cos(th) * r, y, math.sin(th) * r)
		local len = if i % 2 == 0 then 4.5 else 3.2
		Kit.Make("CoreSpike", { Name = "Spike", Size = Vector3.new(1.6, len, 1.6), CFrame = alongY(corePos + dir * (CR.CoreRadius + len / 2 - 0.6), dir),
			Color = C.Spike, Material = Enum.Material.Neon, Parent = core })
	end
	for i, spec in ipairs({ { 9.5, 72, 0 }, { 10.25, -58, 30 }, { 11, 10, -70 } }) do
		local ring = Kit.Make("GyroRing", brass({ Name = "Gyro" .. i, Size = Vector3.new(spec[1] * 2, 0.7 - i * 0.12, spec[1] * 2),
			CFrame = CFrame.new(corePos) * CFrame.Angles(math.rad(spec[2]), math.rad(spec[3]), 0), Parent = core }))
		ring:SetAttribute("Spin", ({ 0.35, -0.25, 0.18 })[i])
	end
	Kit.Make("RimRing", brass({ Name = "ShockMark", Size = Vector3.new(41, 0.15, 41), CFrame = CFrame.new(O + Vector3.new(0, 0.05, 0)), Parent = core }))

	------------------------------------------------------------------ FRONT: the boards (Upgrades + Tree side by side)
	-- E / tap / click opens the window (the hotbar opens it from anywhere too). Facing OUT, the screen on BOTH sides
	-- (islands surround the centre: never blank). A ClickDetector on each screen (clickable / tappable from a bridge or
	-- an island's edge) + the ProximityPrompt; GalaxyMapClient turns all of them into Galaxy.OpenWindow(id).
	local zb = zoneCf(Z.Boards.angle, Z.Boards.dist)
	local W, Hh = CR.BoardSize.X, CR.BoardSize.Y
	for i, b in ipairs(CR.Boards) do
		local board = Instance.new("Model")
		board.Name = "Board_" .. b.id
		board:SetAttribute("Window", b.id)
		board.Parent = centre
		-- An open V: each board turns BoardTurn degrees to face its nearer bridge, so their legs stay out of both walkways
		-- (>= 4 studs clear). Upgrades faces island 1 (the first island players get; the tutorial needs it), Tree island 2.
		-- (the zone frame's +X points toward island 1's side)
		local side = if i == 1 then 1 else -1
		local face = zb * CFrame.new(side * CR.BoardGap / 2, 0, 0) * CFrame.Angles(0, math.rad(side * CR.BoardTurn), 0) * CFrame.new(side * W / 2, 0, 0)
		local s = W / 1.12
		local screenCentre = face * CFrame.new(0, CR.BoardHeight + 1.2, 0)
		local frame = Kit.Make("BoardFrame", { Name = "Frame", Size = Vector3.new(W, 1.28 * s, 0.08 * s), CFrame = screenCentre * CFrame.new(0, -0.15 * s, 0),
			Color = C.Brass, Material = MapConfig.BoardFrameMaterial, Reflectance = MapConfig.BoardFrameReflectance, Collide = true, Parent = board })
		-- (the frame takes clicks too: it's what a click ray meets first round the screen)
		local frameClick = Instance.new("ClickDetector")
		frameClick.MaxActivationDistance = 60
		frameClick.Parent = frame
		local function screen(name: string, dz: number, faceId: Enum.NormalId)
			local p = part({ Name = name, Size = Vector3.new(W - 1.5, Hh - 0.9, 0.2), CFrame = screenCentre * CFrame.new(0, 0, dz), Color = Color3.fromRGB(12, 10, 18),
				CanCollide = false, Parent = board })
			p:SetAttribute("Window", b.id)
			local gui = surface(p, faceId)
			gui.MaxDistance = 260
			-- a big title under the window picture (never blank, even before the picture loads)
			local title = label(gui, if b.id == "Tree" then "CONSTELLATION TREE" else string.upper(b.id), UDim2.fromScale(0.07, 0.33), UDim2.fromScale(0.86, 0.34), b.beacon)
			title.Name = "Title"
			title.ZIndex = 0
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromScale(1, 1)
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = b.image
			img.ZIndex = 2
			img.Parent = gui
			-- (no SurfaceLight: its orange / green tinted the brass frame like coloured plastic; the screen glows by itself)
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 60
			click.Parent = p
			return p
		end
		-- (just in front of the frame's faces, which sit 0.04 * s out from its middle)
		local dz = 0.04 * s + 0.12
		local front = screen("Screen", dz, Enum.NormalId.Back)
		screen("ScreenBack", -dz, Enum.NormalId.Front)
		Kit.Make("LampOrb", { Name = "Beacon", Size = Vector3.new(2.2, 2.2, 2.2), CFrame = screenCentre * CFrame.new(0, Hh / 2 + 2.1, 0), Color = b.beacon, Material = Enum.Material.Neon, Parent = board })
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "Open"
		prompt.ActionText = "Open"
		prompt.ObjectText = if b.id == "Tree" then "CONSTELLATION TREE" else string.upper(b.id)
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 18
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Window", b.id)
		prompt.Parent = front
	end

	------------------------------------------------------------------ RIGHT: the Star Forge on its stepped platform
	-- (locked until Supernova 3: a padlock over the anvil, a blue rim that's not lit). It faces the CORE (owner, 2 Nov):
	-- players walk up to it from the plaza; its sign stands in front on the plaza side
	local forge = Instance.new("Model")
	forge.Name = "StarForge"
	forge:SetAttribute("Window", "Forge")
	forge.Parent = centre
	local zf = zoneCf(Z.Forge.angle, Z.Forge.dist) * CFrame.Angles(0, math.pi, 0)
	local stepH = 3.6
	Kit.Make("Dais", { Name = "Platform", Size = Vector3.new(16, stepH, 16), CFrame = zf * CFrame.new(0, stepH / 2, 0), Color = C.Stone2, Collide = true, Parent = forge })
	Kit.Make("RimRing", { Name = "Rim", Size = Vector3.new(10, 0.4, 10), CFrame = zf * CFrame.new(0, stepH + 0.1, 0), Color = C.ForgeRim, Parent = forge })
	Kit.Make("Anvil", { Name = "Anvil", Size = Vector3.new(6, 4, 2.4), CFrame = zf * CFrame.new(0, stepH + 2, -0.5), Color = C.Steel, Reflectance = 0.1, Collide = true, Parent = forge })
	-- the padlock hangs on the anvil's front face (the face toward the Core: the anvil's +Z face is at -0.5 + 1.2)
	Kit.Make("Padlock", { Name = "Padlock", Size = Vector3.new(1.6, 2.2, 0.5), CFrame = zf * CFrame.new(0, stepH + 2.9, 0.7 + 0.25), Color = C.Lock, Reflectance = 0.1, Parent = forge })
	-- the sign: 2x (reads from across the plaza), facing the Core, the same text on its back (the nearest bridges)
	sign(forge, "Sign", zf * CFrame.new(0, 0, 8.8), Vector3.new(14, 4.4, 0.3), 1.2, { "STAR FORGE", "SUPERNOVA 3" }, nil, true)

	------------------------------------------------------------------ BACK: the Black Hole gate (x1.5) on its dais
	-- (a brass ring round a violet void; locked; the client swirls the disk). It faces the CORE (owner, 2 Nov): a gate you
	-- walk up to from the plaza, its sign in front of it on the plaza side (facing out, its back was all you saw)
	local hole = Instance.new("Model")
	hole.Name = "BlackHoleGate"
	hole.Parent = centre
	local zh = zoneCf(Z.BlackHole.angle, Z.BlackHole.dist) * CFrame.Angles(0, math.pi, 0)
	local k = CR.BlackHoleScale
	local daisH = 2
	Kit.Make("Dais", { Name = "Base", Size = Vector3.new(19, daisH, 19), CFrame = zh * CFrame.new(0, daisH / 2, 0), Color = C.Stone2, Collide = true, Parent = hole })
	local outer = (17.6 + 2.55) * k
	local ringCf = zh * CFrame.new(0, daisH + outer / 2 - 0.4, 0) * CFrame.Angles(math.rad(90), 0, 0)
	Kit.Make("GateRing", brass({ Name = "Ring", Size = Vector3.new(outer, 2.55 * k, outer), CFrame = ringCf, Collide = true, Parent = hole }))
	Kit.Make("VoidDisc", { Name = "Void", Size = Vector3.new(15.4 * k, 0.2, 15.4 * k), CFrame = ringCf, Color = C.Void, Parent = hole })
	Kit.Make("VoidDisc", { Name = "VoidBack", Size = Vector3.new(15.4 * k, 0.2, 15.4 * k), CFrame = ringCf * CFrame.Angles(math.pi, 0, 0), Color = C.Void, Parent = hole })
	local disk = Kit.Make("OrbitRing", { Name = "Disk", Size = Vector3.new(12 * k, 0.3, 12 * k), CFrame = ringCf * CFrame.new(0, 0.25, 0), Color = C.VoidGlow, Material = Enum.Material.Neon, Parent = hole })
	disk:SetAttribute("Swirl", 0.9)
	-- the swirl: 3 spiral arms (pink near the middle to violet outside) round a soft glowing inner ring, all on both faces
	-- (each piece goes through the void plane); the client turns them slowly round the ring's axis
	local arms = Instance.new("Model")
	arms.Name = "Arms"
	arms:SetAttribute("Swirl", -0.35)
	arms.Parent = hole
	local inner, outerR, steps = 2.6, 15.4 * k / 2 - 1.4, 14
	for arm = 0, 2 do
		local prev
		for j = 0, steps do
			local t = j / steps
			local rr = inner + (outerR - inner) * t
			local th = arm * math.pi * 2 / 3 + t * math.pi * 1.5
			local pt = (ringCf * CFrame.new(math.cos(th) * rr, 0, math.sin(th) * rr)).Position
			if prev then
				local w = 1.1 - 0.75 * t
				part({ Name = "Arm", Size = Vector3.new(w, 0.5, (pt - prev).Magnitude + 0.25), CFrame = CFrame.lookAt((prev + pt) / 2, pt, ringCf.UpVector),
					Color = Color3.fromRGB(255, 130, 225):Lerp(Color3.fromRGB(140, 70, 255), t), Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, Parent = arms })
			end
			prev = pt
		end
	end
	local glow = Kit.Make("OrbitRing", { Name = "InnerGlow", Size = Vector3.new(inner * 2 + 0.6, 0.55, inner * 2 + 0.6), CFrame = ringCf, Color = Color3.fromRGB(255, 160, 235),
		Material = Enum.Material.Neon, Parent = hole })
	glow:SetAttribute("Swirl", 0.8)
	local glowHost = part({ Name = "GlowLight", Size = Vector3.new(1, 1, 1), CFrame = ringCf, Transparency = 1, CanCollide = false, CanQuery = false, Parent = hole })
	local gl = Instance.new("PointLight")
	gl.Color, gl.Range, gl.Brightness, gl.Shadows = Color3.fromRGB(190, 110, 255), 16, 1.3, false
	gl.Parent = glowHost
	hole:SetAttribute("RingCF", ringCf)
	-- the sign: 2x, facing the Core, the same text on its back
	sign(hole, "Sign", zh * CFrame.new(0, 0, 10.2), Vector3.new(14, 4.2, 0.3), 1, { "BLACK HOLE", "LOCKED" }, Color3.fromRGB(200, 150, 255), true)

	------------------------------------------------------------------ LEFT: the leaderboard wall (both sides)
	-- TOP SUPERNOVAS (filled by GalaxyLeaderboardService) + PLAYERS NEAR YOU (each screen fills its own, from the server)
	local lb = Instance.new("Model")
	lb.Name = "Leaderboard"
	lb.Parent = centre
	local zl = zoneCf(Z.Leaderboard.angle, Z.Leaderboard.dist)
	local LW, LH, lift = 24, 12, 2.2 -- (titles ~1.3 studs, rows ~0.85: readable from ~30 studs)
	local wallCf = zl * CFrame.new(0, lift + LH / 2, 0)
	local wall = part({ Name = "Wall", Size = Vector3.new(LW, LH, 0.6), CFrame = wallCf, Color = Color3.fromRGB(22, 17, 30), Parent = lb })
	part(brass({ Name = "WallEdge", Size = Vector3.new(LW + 0.6, LH + 0.6, 0.4), CFrame = wallCf, Parent = lb }))
	for _, sx in ipairs({ -1, 1 }) do
		Kit.Make("Pillar", brass({ Name = "Post", Size = Vector3.new(1, lift + LH + 1.2, 1), CFrame = zl * CFrame.new(sx * (LW / 2 + 0.7), (lift + LH + 1.2) / 2, 0), Collide = true, Parent = lb }))
		Kit.Make("LampOrb", { Name = "Lamp", Size = Vector3.new(1.1, 1.1, 1.1), CFrame = zl * CFrame.new(sx * (LW / 2 + 0.7), lift + LH + 1.9, 0), Color = C.Lamp, Material = Enum.Material.Neon, Parent = lb })
	end
	for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Front }) do
		local gui = surface(wall, face)
		gui.Name = "Board_" .. face.Name
		for col, spec in ipairs({ { "Top", "TOP SUPERNOVAS", Color3.fromRGB(255, 214, 120), 10 }, { "Near", "PLAYERS NEAR YOU", Color3.fromRGB(150, 220, 255), 11 } }) do
			local f = Instance.new("Frame")
			f.Name = spec[1]
			f.BackgroundTransparency = 1
			f.Position = UDim2.fromScale(if col == 1 then 0.02 else 0.51, 0.03)
			f.Size = UDim2.fromScale(0.47, 0.94)
			f.Parent = gui
			label(f, spec[2], UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.12), spec[3])
			for r = 1, spec[4] do
				local row = label(f, "", UDim2.fromScale(0.02, 0.14 + (r - 1) * 0.078), UDim2.fromScale(0.96, 0.07), Color3.fromRGB(225, 215, 240), FONT_B, Enum.TextXAlignment.Left)
				row.Name = "Row" .. r
			end
		end
		local divider = Instance.new("Frame")
		divider.BackgroundColor3 = Color3.fromRGB(201, 144, 46)
		divider.BorderSizePixel = 0
		divider.Position = UDim2.fromScale(0.497, 0.05)
		divider.Size = UDim2.new(0, 3, 0.9, 0)
		divider.Parent = gui
	end

	------------------------------------------------------------------ the 8 island slots + their bridges
	local islands = Instance.new("Folder")
	islands.Name = "Islands"
	islands.Parent = root
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
		local A = O + dir * (CR.Radius - 0.5) + Vector3.new(0, 0.05, 0)
		local B = center - dir * 9.5 + Vector3.new(0, 0.05, 0)
		bridge(island, A, B, I.Bridge.Segments, I.Bridge.Width, I.Bridge.Arch, C.BridgeDim, "Bridge")
		local pieces = Instance.new("Folder")
		pieces.Name = "Pieces"
		pieces.Parent = island
		-- the free slot's dim rock + landing (the same pieces as GalaxyMapService's tier 0, which reuses them): a bridge
		-- never leads into empty space, not even in Edit mode
		local R = I.Radius
		local t0 = Instance.new("Model")
		t0.Name = "T0"
		Kit.Make("RockBare", { Name = "Rock", Size = Vector3.new(R, R * 0.62, R), CFrame = CFrame.new(center - Vector3.new(0, R * 0.29, 0)) * CFrame.Angles(0, slot * 0.7, 0),
			Color = C.BareRock:Lerp(Color3.new(0, 0, 0), 0.45), Collide = true, Parent = t0 })
		local la, lb2 = center - dir * 9.6 + Vector3.new(0, 0.05, 0), center - dir * 3 + Vector3.new(0, 0.05, 0)
		Kit.Make("BridgeSegment", { Name = "Landing", Size = Vector3.new(I.Bridge.Width, 0.4, (lb2 - la).Magnitude), CFrame = CFrame.lookAt((la + lb2) / 2, lb2),
			Color = C.BridgeDim, Collide = true, Parent = t0 })
		t0.Parent = pieces
		island.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end

	------------------------------------------------------------------ BACK-LEFT: the locked next sector, its bridge + gate
	local NS = MapConfig.NextSector
	local nextS = Instance.new("Model")
	nextS.Name = "NextSector"
	nextS.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	nextS.Parent = root
	local N = O + NS.Position
	local nsDir = MapConfig.ZoneDir(NS.Angle)
	Kit.Make("IslandTop", { Name = "Floor", Size = Vector3.new(NS.Radius * 2, 2.5, NS.Radius * 2), CFrame = CFrame.new(N - Vector3.new(0, 1.25, 0)), Color = C.Stone, Collide = true, Parent = nextS })
	Kit.Make("IslandUnder", { Name = "Under", Size = Vector3.new(NS.Radius * 2, 17.5, NS.Radius * 2), CFrame = CFrame.new(N - Vector3.new(0, 2.5 + 8.75, 0)), Color = C.Rock, Parent = nextS })
	local rnd = Random.new(4)
	for _ = 1, 7 do
		local at = N + Vector3.new(rnd:NextNumber(-12, 12), 0, rnd:NextNumber(-12, 12))
		local h = rnd:NextNumber(4, 7.5)
		Kit.Make("Crystal", { Size = Vector3.new(h * 0.45, h, h * 0.45), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rnd:NextNumber(-0.3, 0.3), rnd:NextNumber(0, 6), rnd:NextNumber(-0.3, 0.3)),
			Color = C.Ice, Reflectance = 0.2, Parent = nextS })
	end
	Kit.Make("Padlock", { Name = "Padlock", Size = Vector3.new(3.5, 4.8, 1.4), CFrame = CFrame.new(N + Vector3.new(0, 10, 0)), Color = C.Lock, Reflectance = 0.1, Parent = nextS })
	local A = O + nsDir * (CR.Radius - 0.5) + Vector3.new(0, 0.05, 0)
	local B = N - nsDir * (NS.Radius - 1) + Vector3.new(0, 0.05, 0)
	local _, pts = bridge(nextS, A, B, NS.BridgeSegments, NS.BridgeWidth, NS.Arch, C.BridgeDim, "Bridge")
	-- brass edges along it (wider and clearer than the island bridges)
	local edges = Instance.new("Folder")
	edges.Name = "Edges"
	edges.Parent = nextS
	for s = 1, NS.BridgeSegments do
		local p0, p1 = pts[s - 1], pts[s]
		local cf = CFrame.lookAt((p0 + p1) / 2, p1)
		for _, side in ipairs({ -1, 1 }) do
			Kit.Make("BridgeSegment", brass({ Name = "Edge", Size = Vector3.new(0.35, 0.6, (p1 - p0).Magnitude + 0.15), CFrame = cf * CFrame.new(side * (NS.BridgeWidth / 2 + 0.1), 0.2, 0),
				Collide = true, Parent = edges }))
		end
	end
	-- the gate arch at the plaza's edge, its name (both sides), the IGNITION sign beside it on the plaza (on posts),
	-- the barrier while locked
	local gatePos = O + nsDir * (CR.Radius - 3)
	local gateCf = CFrame.lookAt(gatePos, gatePos + nsDir) -- (its -Z points out along the bridge; +Z faces the Core)
	Kit.Make("GateArch", brass({ Name = "Arch", Size = Vector3.new(NS.BridgeWidth + 4, 13, 1.6), CFrame = gateCf * CFrame.new(0, 6.5, 0), Collide = true, Parent = nextS }))
	-- (the name: 15 x 2.6 on top of the arch, letters ~1.6 studs, readable from ~30 studs)
	local archSign = part({ Name = "ArchSign", Size = Vector3.new(15, 2.6, 0.3), CFrame = gateCf * CFrame.new(0, 14.5, 0), Color = Color3.fromRGB(26, 20, 34),
		CanCollide = false, CanQuery = false, Parent = nextS })
	for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Front }) do
		label(surface(archSign, face), NS.Name, UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.8), Color3.fromRGB(150, 220, 255))
	end
	part(brass({ Name = "ArchSignEdge", Size = archSign.Size + Vector3.new(0.4, 0.4, -0.1), CFrame = archSign.CFrame, CanCollide = false, CanQuery = false, Parent = nextS }))
	-- IGNITION: on its posts on the plaza beside the gate, facing out, the checklist on both sides (islands and the plaza)
	-- (10 x 11.5, rows wrapped at ~0.75 studs: readable from ~30 studs; narrow enough to stay off the next walkway)
	local signPos = gatePos - nsDir * 4.5 + gateCf.RightVector * (NS.BridgeWidth / 2 + 7.2)
	local signBase = CFrame.lookAt(signPos, signPos - nsDir) * CFrame.Angles(0, math.rad(12), 0)
	local ign = sign(nextS, "IgnitionSign", signBase, Vector3.new(10, 11.5, 0.3), 0.6, { "IGNITION" }, Color3.fromRGB(255, 200, 110), true)
	-- (the client fills the checklist rows for the local player, on every face)
	for _, gui in ipairs(ign:GetChildren()) do
		if not gui:IsA("SurfaceGui") then continue end
		local title = gui:FindFirstChildOfClass("TextLabel")
		if title then title.Size = UDim2.fromScale(0.92, 0.13) title.Position = UDim2.fromScale(0.04, 0.03) end
		for i, item in ipairs(MapConfig.Ignition) do
			local row = label(gui, "[  ]  " .. item.text, UDim2.fromScale(0.05, 0.19 + (i - 1) * 0.2), UDim2.fromScale(0.9, 0.18), Color3.fromRGB(200, 190, 220), FONT_B, Enum.TextXAlignment.Left)
			row.Name = "Row" .. i
			row.TextWrapped = true
			-- (one text size for every row, ~0.75 studs: TextScaled alone made the short rows bigger)
			local cap = Instance.new("UITextSizeConstraint")
			cap.MaxTextSize = 30
			cap.Parent = row
		end
	end
	part({ Name = "Barrier", Size = Vector3.new(NS.BridgeWidth + 1, 12, 1), CFrame = gateCf * CFrame.new(0, 6, 0), Transparency = 1, CanCollide = true, CanQuery = false, Parent = nextS })

	------------------------------------------------------------------ sky + lighting (warm ground vs violet sky)
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
	-- (concept v3 look, owner pass 2) warm daylight from the front (high) on the cream stone + brass; the faces turned away
	-- from the sun take a violet rim (ColorShift_Bottom + a violet back light behind the Core); a thin violet atmosphere
	-- far out (denser or with Haze it covers the skybox); less blue in the ambient
	Lighting.ClockTime = 10.5
	Lighting.GeographicLatitude = 58
	Lighting.Brightness = 1.7
	Lighting.Ambient = Color3.fromRGB(70, 58, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(112, 100, 112)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 230, 196)
	Lighting.ColorShift_Bottom = Color3.fromRGB(150, 90, 235)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density, atm.Offset, atm.Color, atm.Decay, atm.Glare, atm.Haze = 0.18, 0, Color3.fromRGB(96, 48, 140), Color3.fromRGB(40, 16, 70), 0, 0
	atm.Parent = Lighting
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	-- bloom softer (owner, centre redesign: the Core's glow blew out the plaza)
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity, bloom.Size, bloom.Threshold = 0.32, 18, 2.1
	bloom.Parent = Lighting
	local cc = Lighting:FindFirstChild("GalaxyGrade") or Instance.new("ColorCorrectionEffect")
	cc.Name = "GalaxyGrade"
	cc.Saturation, cc.Contrast, cc.Brightness, cc.TintColor = 0.1, 0.1, 0, Color3.fromRGB(255, 246, 232)
	cc.Parent = Lighting

	local count = 0
	for _, d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then count += 1 end end
	root:SetAttribute("Parts", count)
	return root
end

return Builder
