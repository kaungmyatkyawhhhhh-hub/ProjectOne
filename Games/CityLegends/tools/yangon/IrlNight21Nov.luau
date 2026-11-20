--[[
	IrlNight21Nov (Studio, Edit mode; owner's real night footage of 21 Nov 2026, vault note
	"City Legends/2026-11-21 Real Yangon references - what the game must match.md").

	Builds Workspace.Yangon1to1.Landmarks.IrlNight21Nov (delete that one folder to undo):
	  CityHall    warm-white light lines on the floor bands, parapet and every tower eave + facade wash (0806_19s)
	  Roundabout  the gold monument and its lit base ring on the bare Hanthawaddy island (0803_2s)
	  ParkFence   red / green neon meander and gold-wrapped poles round Maha Bandula Park (0801_5s)
	  SuleShops   gold crest on the shop ring, crest floodlights, yellow sign boards (0806_1s)

	Night switching is WorldFx's own (no new code): Neon lines carry tag FacadeNight (hidden by day), gold
	carries LandmarkGlow (DayColor / DayMaterial / NightColor), pole wraps LampGlow, lights LODLight + DayOff
	(built Enabled = false). M.preview(true / false) shows the night state in Edit on this folder only.

	Run: paste into the command bar / execute_luau with the last line changed to `return M.build()`.
	shortcut: outlines are OSM polygons pasted below (geo.py, YANGON_SCALE=1to1), re-paste if the map moves.
]]
local CollectionService = game:GetService("CollectionService")

local M = {}
local FROM = "IrlRefs 21Nov"
local rgb = Color3.fromRGB

local function landmarks(): Instance
	return workspace.Yangon1to1.Landmarks
end

local function item(name: string): Folder
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if not root then
		root = Instance.new("Folder")
		root.Name = "IrlNight21Nov"
		root:SetAttribute("From", FROM)
		root.Parent = landmarks()
	end
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f:SetAttribute("From", FROM)
	return f -- parented by the caller once it is full (one insert)
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p:SetAttribute("From", FROM)
	p.Parent = parent
	return p
end

-- a light line: Neon, hidden by day (WorldFx.setFacadeNight)
local function neon(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = part(parent, name, size, cf, color, Enum.Material.Neon, shape)
	p.Transparency = 1
	p:AddTag("FacadeNight")
	return p
end

-- gold that glows at night (WorldFx.setLandmarkGlow)
local function glow(p: Part, night: Color3): Part
	p:SetAttribute("DayColor", p.Color)
	p:SetAttribute("DayMaterial", p.Material.Name)
	p:SetAttribute("NightColor", night)
	p:AddTag("LandmarkGlow")
	return p
end

local function light(l: Light, parent: Instance, color: Color3, brightness: number, range: number): Light
	l.Color = color
	l.Brightness = brightness;
	(l :: any).Range = range
	l.Shadows = false
	l.Enabled = false
	l:SetAttribute("From", FROM)
	l:AddTag("LODLight")
	l:AddTag("DayOff")
	l.Parent = parent
	return l
end

-- upright cylinder (Roblox cylinders lie along X)
local function cyl(parent: Instance, name: string, r: number, h: number, pos: Vector3, color: Color3, material: Enum.Material?): Part
	return part(parent, name, Vector3.new(h, 2 * r, 2 * r), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
end

-- a bar from a to b (world), square section t
local function bar(a: Vector3, b: Vector3, t: number, extra: number?): (Vector3, CFrame)
	local L = (b - a).Magnitude
	return Vector3.new(t, t, L + (extra or 0)), CFrame.lookAt((a + b) / 2, b)
end

-- outward unit normal of edge a -> b of a polygon round centre c (x, z pairs)
local function outward(a, b, c): (number, number, number)
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local L = math.sqrt(dx * dx + dz * dz)
	local nx, nz = dz / L, -dx / L
	if nx * ((a[1] + b[1]) / 2 - c[1]) + nz * ((a[2] + b[2]) / 2 - c[2]) < 0 then
		nx, nz = -nx, -nz
	end
	return nx, nz, L
end

local function centroid(poly): { number }
	local x, z = 0, 0
	for _, p in poly do
		x += p[1]
		z += p[2]
	end
	return { x / #poly, z / #poly }
end

------------------------------------------------------------------------------------------------ A. City Hall
-- outline = OSM o5677100 (dt_landmarks.city_hall: same polygon, same tower maths; S = 3 studs a metre)
local CH_POLY = { { 36109.3, 44964.3 }, { 36162.8, 45014.5 }, { 36256.7, 45017.2 }, { 36256.5, 45023.9 }, { 36262.3, 45024.1 }, { 36261.9, 45036.5 }, { 36350.3, 45039.1 }, { 36350.7, 45025.7 }, { 36355.9, 45025.9 }, { 36356.0, 45021.2 }, { 36444.2, 45023.7 }, { 36465.9, 45003.8 }, { 36471.3, 44787.5 }, { 36115.1, 44777.2 } }
local CH_RECT = { { 36472.2, 44787.5 }, { 36114.8, 44777.1 }, { 36107.4, 45032.1 }, { 36464.8, 45042.4 } } -- its minimum rotated rectangle
local CH_C = { 36289.77, 44909.79 }
local CH_BASE = 13.9 -- the trim mesh's foot (Visual.TRM)
local WARM = rgb(238, 230, 213)

function M.cityHall(): string
	local f = item("CityHall")
	local yH = CH_BASE + 15.6 * 3
	local nLine, nLight = 0, 0
	-- floor bands and parapet, right round
	for i, a in CH_POLY do
		local b = CH_POLY[i % #CH_POLY + 1]
		local nx, nz, L = outward(a, b, CH_C)
		for _, y in { CH_BASE + 14.6, CH_BASE + 35.6, yH - 0.6, yH + 3.8 } do
			local o = Vector3.new(nx * 1.9, 0, nz * 1.9)
			local size, cf = bar(Vector3.new(a[1], y, a[2]) + o, Vector3.new(b[1], y, b[2]) + o, 0.55, 2)
			neon(f, "Line", size, cf, WARM)
			nLine += 1
		end
		-- the wash: one SurfaceLight strip per long wall, on the ground, tilted up at the wall
		if L > 60 then
			local mid = Vector3.new((a[1] + b[1]) / 2 + nx * 16, CH_BASE + 1, (a[2] + b[2]) / 2 + nz * 16)
			local aim = Vector3.new((a[1] + b[1]) / 2, CH_BASE + 30, (a[2] + b[2]) / 2)
			local strip = part(f, "Wash", Vector3.new(L - 8, 0.4, 0.4), CFrame.lookAt(mid, aim), WARM)
			strip.Transparency = 1
			local sl = Instance.new("SurfaceLight")
			sl.Face = Enum.NormalId.Front
			sl.Angle = 110
			light(sl, strip, WARM, 2.2, 60)
			nLight += 1
		end
	end
	-- towers: eave squares in the rectangle's frame
	local e = Vector3.new(CH_RECT[2][1] - CH_RECT[1][1], 0, CH_RECT[2][2] - CH_RECT[1][2]).Unit
	local function square(cx: number, cz: number, y: number, hu: number, hv: number)
		local cf = CFrame.fromMatrix(Vector3.new(cx, y, cz), e, Vector3.yAxis)
		for _, s in { -1, 1 } do
			neon(f, "Eave", Vector3.new(2 * hu + 0.5, 0.5, 0.5), cf * CFrame.new(0, 0, s * hv), WARM)
			neon(f, "Eave", Vector3.new(0.5, 0.5, 2 * hv + 0.5), cf * CFrame.new(s * hu, 0, 0), WARM)
			nLine += 2
		end
	end
	local function pyatthat(cx: number, cz: number, w: number, y: number, tiers: number)
		for k = 1, tiers do
			local hb = w / 2 + w * 0.12 + 0.3
			square(cx, cz, y - 0.25, hb, hb)
			y += w * 0.22
			w *= 0.62
			if k < tiers then
				y += w * 0.35
			end
		end
	end
	for _, c in CH_RECT do
		local d = Vector3.new(CH_C[1] - c[1], 0, CH_C[2] - c[2]).Unit * 27
		local tx, tz = c[1] + d.X, c[2] + d.Z
		square(tx, tz, yH + 15.35, 17.4, 17.4)
		pyatthat(tx, tz, 27 * 0.62, yH + 21.4, 2)
	end
	local sx, sz = (CH_RECT[3][1] + CH_RECT[4][1]) / 2, (CH_RECT[3][2] + CH_RECT[4][2]) / 2 -- the south side's middle
	local d = Vector3.new(CH_C[1] - sx, 0, CH_C[2] - sz).Unit * 36
	local tx, tz = sx + d.X, sz + d.Z
	square(tx, tz, yH + 24.0, 27.3, 21.9)
	pyatthat(tx, tz, 54 * 0.75, yH + 24.6, 5)
	f.Parent = landmarks().IrlNight21Nov
	return string.format("CityHall: %d neon lines, %d lights", nLine, nLight)
end

------------------------------------------------------------------------------------------------ B. Roundabout monument
-- the bare island of the Hanthawaddy roundabout (measured in Studio: x 28195..28306, z 32138..32249, top 75.63)
local RB = Vector3.new(28250.5, 75.63, 32193.5)
local GOLD = rgb(232, 227, 96)
local GOLD_DAY = rgb(246, 196, 62)
local RING_GREEN = rgb(156, 201, 116)

function M.roundabout(): string
	local f = item("Roundabout")
	local n = 0
	local K = 1.25 -- the drawing below is in units of 0.8 m; the real one stands about 12 m
	local NIGHT = rgb(150, 132, 38) -- (a bright gold Neon blooms into a yellow blob)
	local LINE = rgb(255, 246, 190)
	local function at(y: number): Vector3
		return RB + Vector3.new(0, y * K, 0)
	end
	local function gold(name: string, r: number, h: number, y: number): Part
		n += 1
		return glow(cyl(f, name, r * K, h * K, at(y + h / 2), GOLD_DAY, Enum.Material.Metal), NIGHT)
	end
	local function rim(name: string, r: number, y: number, color: Color3, t: number?)
		n += 1
		neon(f, name, Vector3.new(t or 0.45, 2 * r * K, 2 * r * K), CFrame.new(at(y)) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.PartType.Cylinder)
	end
	-- the planted base ring (the only solid piece)
	local bed = cyl(f, "BaseRing", 28 * K, 1.6 * K, at(0.8), rgb(74, 122, 60), Enum.Material.Grass)
	bed.CanCollide = true
	bed.CanQuery = true
	n += 1
	rim("RingGreen", 28.5, 0.5, RING_GREEN, 0.8)
	rim("RingWhite", 28.3, 1.45, rgb(255, 250, 225), 0.6)
	-- three gold steps, a light line on each
	local y = 1.6
	for i, r in { 9.5, 7.8, 6.2 } do
		gold("Step" .. i, r, 1.3, y)
		y += 1.3
		rim("StepLight", r + 0.15, y - 0.2, LINE)
	end
	-- the open-work stem: an hourglass of drums with light bands
	for i, r in { 4.4, 3.5, 2.7, 2.7, 3.5, 4.4 } do
		gold("Stem" .. i, r, 2.6, y)
		y += 2.6
		rim("StemLight", r + 0.15, y, LINE)
	end
	-- the bowl under the canopy, the wide scalloped canopy, two shrinking tiers, the dark crown
	gold("Bowl", 6.5, 1.6, y)
	y += 1.6
	gold("Canopy", 11.5, 1.5, y)
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		n += 1
		glow(part(f, "Scallop", Vector3.one * 4.6 * K, CFrame.new(at(y - 0.4) + Vector3.new(math.cos(a), 0, math.sin(a)) * 10.4 * K), GOLD_DAY, Enum.Material.Metal, Enum.PartType.Ball), NIGHT)
	end
	y += 1.5
	rim("CanopyLight", 11.65, y, LINE)
	gold("Tier1", 8.4, 1.5, y)
	y += 1.5
	rim("TierLight", 8.55, y, LINE)
	gold("Tier2", 5.6, 1.4, y)
	y += 1.4
	cyl(f, "Crown", 3.6 * K, 2.2 * K, at(y + 1.1), rgb(120, 44, 40))
	n += 1
	y += 2.2
	rim("CrownLight", 3.8, y - 0.3, LINE)
	gold("Cap", 2.2, 0.8, y)
	-- two lights: the stem's glow and the canopy's underside
	for _, h in { 9, 20 } do
		local holder = part(f, "Glow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(at(h) + Vector3.new(0, 0, 12)), GOLD)
		holder.Transparency = 1
		n += 1
		light(Instance.new("PointLight"), holder, GOLD, 1.6, 40)
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("Roundabout: %d parts, 2 lights, top %.1f studs over the island", n, (y + 0.8) * K)
end

------------------------------------------------------------------------------------------------ C. Maha Bandula Park fence
local PARK = { { 36014.4, 45932.5 }, { 36409.9, 45944.4 }, { 36424.7, 45553.1 }, { 36431.7, 45297.7 }, { 36241.4, 45292.5 }, { 36125.9, 45290.8 }, { 36071.2, 45310.2 }, { 36025.2, 45350.8 }, { 36024.4, 45548.6 } } -- OSM way 129485365
local RED = rgb(206, 52, 26) -- photo (216, 93, 49); Neon renders lighter, so the part is deeper
local GREEN = rgb(70, 200, 62) -- photo (128, 211, 100)
local LED_GOLD = rgb(255, 214, 96)

function M.parkFence(): string
	local f = item("ParkFence")
	local c = centroid(PARK)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { landmarks() } -- the ground only (terrain, road and pavement boxes)
	local nNeon, nPole, k = 0, 0, 0
	local lastY = 18
	local INSET, PERIOD, LO, HI, T = 6, 16, 0.9, 6.4, 0.45
	for i, a in PARK do
		local b = PARK[i % #PARK + 1]
		local nx, nz, L = outward(a, b, c)
		local ex, ez = (b[1] - a[1]) / L, (b[2] - a[2]) / L
		local n = math.max(1, math.floor((L - 2 * INSET) / PERIOD))
		local p = (L - 2 * INSET) / n
		for j = 0, n - 1 do
			local function at(s: number): (number, number)
				return a[1] + ex * (INSET + j * p + s) - nx * INSET, a[2] + ez * (INSET + j * p + s) - nz * INSET
			end
			local mx, mz = at(p / 2)
			local hit = workspace:Raycast(Vector3.new(mx, 200, mz), Vector3.new(0, -400, 0), rp)
			local gy = if hit then hit.Position.Y else lastY
			lastY = gy
			local color = if (k // 6) % 2 == 0 then RED else GREEN
			local function P(s: number, h: number): Vector3
				local x, z = at(s)
				return Vector3.new(x, gy + h, z)
			end
			-- one turn of the meander: up, along the top, down, along the bottom
			for _, seg in { { P(0, LO), P(0, HI) }, { P(0, HI), P(p / 2, HI) }, { P(p / 2, HI), P(p / 2, LO) }, { P(p / 2, LO), P(p, LO) } } do
				local size, cf = bar(seg[1], seg[2], T, T)
				neon(f, "Neon", size, cf, color)
				nNeon += 1
			end
			-- a pole with a gold LED wrap where the colour changes
			if k % 6 == 0 then
				local x, z = at(0)
				cyl(f, "Pole", 0.45, 17, Vector3.new(x - nx * 1.2, gy + 8.5, z - nz * 1.2), rgb(150, 152, 154), Enum.Material.Metal)
				local wrap = cyl(f, "PoleWrap", 0.62, 10, Vector3.new(x - nx * 1.2, gy + 6.5, z - nz * 1.2), LED_GOLD)
				wrap:AddTag("LampGlow")
				nPole += 1
			end
			k += 1
		end
		task.wait()
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("ParkFence: %d neon bars, %d poles with gold wraps, 0 lights", nNeon, nPole)
end

------------------------------------------------------------------------------------------------ D. Sule shops
-- the shop ring's outer face = OSM way 131745510 simplified 0.4 m (sule3d.grounds); gates at N / E / S / W of the stupa
local SULE = { { 35858.0, 45143.0 }, { 35872.0, 45171.3 }, { 35908.2, 45209.0 }, { 35929.8, 45225.7 }, { 35952.7, 45239.4 }, { 35977.9, 45245.8 }, { 36015.2, 45246.9 }, { 36041.3, 45242.0 }, { 36068.0, 45230.7 }, { 36089.1, 45215.8 }, { 36107.5, 45198.2 }, { 36124.9, 45177.0 }, { 36139.4, 45147.3 }, { 36140.0, 45122.3 }, { 36136.3, 45103.0 }, { 36125.3, 45083.6 }, { 36097.5, 45049.1 }, { 36072.5, 45022.9 }, { 36046.0, 45001.8 }, { 36022.8, 44992.4 }, { 35985.5, 44991.4 }, { 35970.1, 44993.3 }, { 35957.0, 44997.9 }, { 35933.5, 45010.1 }, { 35912.5, 45027.2 }, { 35894.7, 45046.5 }, { 35878.0, 45068.5 }, { 35867.6, 45089.1 }, { 35858.5, 45115.1 } }
local SULE_C = { 35993.22, 45130.83 }
local SULE_Y0 = 18.47
local BOARD = rgb(236, 200, 44)
local CREST_DAY = rgb(255, 187, 84) -- Sule's own gold (Visual.GLD)
local CREST_NIGHT = rgb(150, 112, 30) -- (brighter blooms yellow)

function M.suleShops(): string
	local f = item("SuleShops")
	local nBoard, nCrest, nLight = 0, 0, 0
	local function inGate(x: number, z: number, half: number): boolean
		return math.abs(x - SULE_C[1]) < half or math.abs(z - SULE_C[2]) < half
	end
	local yTop = SULE_Y0 + 5.8 * 3 -- the facade's top
	for i, a in SULE do
		local b = SULE[i % #SULE + 1]
		local nx, nz, L = outward(a, b, SULE_C)
		local ex, ez = (b[1] - a[1]) / L, (b[2] - a[2]) / L
		local function P(s: number, y: number, out: number): Vector3
			return Vector3.new(a[1] + ex * s + nx * out, y, a[2] + ez * s + nz * out)
		end
		-- yellow boards over the shop bays (about 4 m each, as sule3d cut them)
		local nb = math.max(1, math.round(L / 12))
		local w = L / nb
		for j = 0, nb - 1 do
			local m = P((j + 0.5) * w, SULE_Y0 + 9.45, 0.3)
			if w >= 7.2 and not inGate(m.X, m.Z, 16) then
				local size, cf = bar(P(j * w + 1.5, m.Y, 0.3), P((j + 1) * w - 1.5, m.Y, 0.3), 0.3)
				part(f, "Board", Vector3.new(0.3, 2.5, size.Z), cf, BOARD)
				nBoard += 1
			end
		end
		-- the gold crest on the wall's top: a band and its teeth
		local size, cf = bar(P(0, yTop + 1.1, 0.1), P(L, yTop + 1.1, 0.1), 0.6, 0.6)
		glow(part(f, "Crest", Vector3.new(0.6, 2.6, size.Z), cf, CREST_DAY, Enum.Material.Metal), CREST_NIGHT)
		nCrest += 1
		local nt = math.max(1, math.floor(L / 9))
		for j = 0, nt - 1 do
			local s = (j + 0.5) * L / nt
			local tall = if j % 2 == 0 then 3.4 else 2.2
			local _, tcf = bar(P(s - 2, yTop + 2.4 + tall / 2, 0.1), P(s + 2, yTop + 2.4 + tall / 2, 0.1), 0.6)
			glow(part(f, "CrestTooth", Vector3.new(0.6, tall, 4), tcf, CREST_DAY, Enum.Material.Metal), CREST_NIGHT)
			nCrest += 1
		end
		-- crest floodlights: one in five edges, on the pavement, aimed at the crest
		if i % 5 == 1 then
			local from = P(L / 2, SULE_Y0 + 1, 15)
			local lamp = part(f, "Flood", Vector3.new(1.2, 1.2, 1.2), CFrame.lookAt(from, P(L / 2, yTop + 2, 0)), rgb(40, 40, 42))
			local sl = Instance.new("SpotLight")
			sl.Face = Enum.NormalId.Front
			sl.Angle = 100
			light(sl, lamp, rgb(255, 242, 208), 4, 46)
			nLight += 1
		end
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("SuleShops: %d yellow boards, %d crest parts, %d floodlights", nBoard, nCrest, nLight)
end

------------------------------------------------------------------------------------------------ E. Sule roundabout
-- (owner, 21 Nov: "there is sule roundabout too"; IMG_0806 0-30 s, IMG_0804 80 s) the stupa stands floodlit gold
-- over the ring: four floods on the platform aimed up the bell and one glow at the spire. The ring's crest, boards
-- and crest floods are item D.
function M.suleRoundabout(): string
	local f = item("SuleRoundabout")
	local c = Vector3.new(SULE_C[1], SULE_Y0 + 3.6 * 3 + 1, SULE_C[2])
	local gold = rgb(255, 206, 110)
	for k = 0, 3 do
		local a = math.rad(45 + 90 * k)
		local from = c + Vector3.new(math.cos(a) * 48, 0, math.sin(a) * 48)
		local lamp = part(f, "StupaFlood", Vector3.new(1.2, 1.2, 1.2), CFrame.lookAt(from, c + Vector3.new(0, 44, 0)), rgb(40, 40, 42))
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Front
		sl.Angle = 70
		light(sl, lamp, gold, 6, 60)
	end
	local top = part(f, "SpireGlow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(c + Vector3.new(9, 78, 9)), gold)
	top.Transparency = 1
	light(Instance.new("PointLight"), top, gold, 3, 60)
	f.Parent = landmarks().IrlNight21Nov
	return "SuleRoundabout: 5 parts, 5 lights (4 stupa floods, 1 spire glow)"
end

------------------------------------------------------------------------------------------------ all
-- the night state in Edit, on this folder only (in Play, WorldFx does the same by its tags)
function M.preview(night: boolean): string
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if not root then
		return "nothing built"
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			if d:HasTag("FacadeNight") then
				d.Transparency = if night then 0 else 1
			elseif d:HasTag("LandmarkGlow") then
				d.Material = if night then Enum.Material.Neon else (Enum.Material :: any)[d:GetAttribute("DayMaterial")]
				d.Color = if night then d:GetAttribute("NightColor") else d:GetAttribute("DayColor")
			elseif d:HasTag("LampGlow") then
				d.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
		elseif d:IsA("Light") then
			d.Enabled = night
		end
	end
	return "preview " .. (if night then "night" else "day")
end

-- self-check: everything anchored and marked, lights off, a handful of lights per item
function M.check(): string
	local root = landmarks().IrlNight21Nov
	local out = {}
	for _, f in root:GetChildren() do
		local parts, lights = 0, 0
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				assert(d.Anchored and d:GetAttribute("From") == FROM, "unanchored or unmarked: " .. d:GetFullName())
				assert(not d:HasTag("FacadeNight") or d.Transparency == 1, "a night line is showing by day")
			elseif d:IsA("Light") then
				lights += 1
				assert(not d.Enabled and d:HasTag("LODLight") and d:HasTag("DayOff"), "light not switched by WorldFx")
			end
		end
		assert(lights <= 8, f.Name .. ": too many lights")
		table.insert(out, string.format("%s %d parts %d lights", f.Name, parts, lights))
	end
	return table.concat(out, "; ")
end

function M.build(): string
	local out = { M.cityHall(), M.roundabout(), M.parkFence(), M.suleShops(), M.suleRoundabout() }
	table.insert(out, M.check())
	return table.concat(out, "\n")
end

function M.undo()
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if root then
		root:Destroy()
	end
end

return M
