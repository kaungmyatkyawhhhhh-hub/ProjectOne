--[[
	Isle
	Builds Legends Isle (IsleLayout has the plan; owner, 2026-10-29: "one big island" with a
	mountain, a beach all round, real roads up the mountain and three neighbourhoods by height).

	  * the ground and the mountain are terrain: sand and grass discs, the lower slope, the mid
	    terrace, the upper face, the top plateau and a rocky summit, with rock bumps on the slopes;
	    every road gets rock filled in under it and air carved out above it
	  * the roads are parts like the city's: asphalt, a yellow centre line, white edge lines, kerbs
	    on the rings, guard rails and invisible walls along the climbs, lamps
	  * the beach: palms, a pier on the west side, lifeguard towers and beach huts
	  * the neighbourhoods: the low tier's sidewalk, mailboxes and street trees; pines and palms on
	    the mountain; the helipad and the lookout on top; the fountain at the causeway's landing; the
	    gate's guard house (Gate builds the barrier and the guards at start)
	Built by West.build (in the scenery: baked into the place).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))
local ChallengeData = require(Shared:WaitForChild("ChallengeData"))

local Isle = {}

local I = Config.West.Isle
local C = Config.City
local ROAD = IsleLayout.Road
local HALF = ROAD / 2
local CURB = C.CurbHeight
local GROUND = -0.8 -- the terrain's top on level ground (the roads' tops are at 0, 100, 240)

local rng = Random.new(20261029)

local STONE = Color3.fromRGB(196, 190, 178)
local KERB = Color3.fromRGB(200, 198, 190)
local RAIL = Color3.fromRGB(176, 180, 186)
local WOOD = Color3.fromRGB(126, 98, 70)
local WHITE = Color3.fromRGB(236, 234, 228)
local PINE = { Color3.fromRGB(34, 64, 40), Color3.fromRGB(42, 74, 46), Color3.fromRGB(30, 58, 38) }
local BARK = Color3.fromRGB(88, 66, 48)
local WARM = Color3.fromRGB(255, 196, 130)
local HUTS = { Color3.fromRGB(120, 196, 210), Color3.fromRGB(240, 150, 140), Color3.fromRGB(250, 214, 120), Color3.fromRGB(150, 210, 160) }

local CENTER = IsleLayout.Center
local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's axis is X: stand it up

---------------------------------------------------------------------
-- Where roads are (to keep trees and bumps off them)
---------------------------------------------------------------------
type Leg = { a: Vector3, b: Vector3 }
local legs: { Leg } = {}
for _, rd in IsleLayout.Roads do
	for k = 1, #rd.pts - 1 do
		table.insert(legs, { a = rd.pts[k], b = rd.pts[k + 1] })
	end
end

local function flatDist(p: Vector3, a: Vector3, b: Vector3): number
	local pa = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local t = math.clamp(pa:Dot(ab) / ab:Dot(ab), 0, 1)
	return (pa - ab * t).Magnitude
end

-- is p this far clear of every island road (rings and climbs)?
local function clearOfRoads(p: Vector3, margin: number): boolean
	for _, l in legs do
		if flatDist(p, l.a, l.b) < HALF + margin then
			return false
		end
	end
	local r = Vector3.new(p.X - CENTER.X, 0, p.Z - CENTER.Z).Magnitude
	for _, ring in IsleLayout.Rings do
		if math.abs(r - ring.radius) < HALF + margin and math.abs(p.Y - ring.y) < 40 then
			return false
		end
	end
	return true
end

local function clearOfLots(p: Vector3, lots: { IsleLayout.Lot }, margin: number): boolean
	for _, l in lots do
		local rel = l.frame:PointToObjectSpace(Vector3.new(p.X, l.frame.Position.Y, p.Z))
		if math.abs(rel.X) < l.width / 2 + margin and math.abs(rel.Z) < l.depth / 2 + margin and math.abs(p.Y - l.frame.Position.Y) < 30 then
			return false
		end
	end
	return true
end

---------------------------------------------------------------------
-- Terrain: the ground, the mountain, the sea floor
---------------------------------------------------------------------
local function radiusAt(y: number): number
	-- the mountain's radius at height y (inverse of IsleLayout.groundY, outer edge of each band)
	local M, T = I.Mid, I.Top
	if y <= 0 then
		return I.Foot
	elseif y <= M.y then
		return I.Foot - (I.Foot - M.outer) * y / M.y
	elseif y <= T.y then
		return M.inner - (M.inner - T.r) * (y - M.y) / (T.y - M.y)
	end
	return T.r
end

local function terrain(t: Terrain)
	local c = CENTER
	local function disc(r: number, top: number, h: number, mat: Enum.Material)
		t:FillCylinder(CFrame.new(c.X, top - h / 2, c.Z), h, r, mat)
	end
	-- the sea floor slopes up to the beach, the beach, the lawn
	disc(I.r + 260, -9, 6, Enum.Material.Sand)
	disc(I.r + 150, -5, 6, Enum.Material.Sand)
	disc(I.r + 60, -2.6, 6, Enum.Material.Sand)
	disc(I.r, GROUND, 10, Enum.Material.Sand)
	disc(I.lawn, GROUND, 6, Enum.Material.Grass)
	-- the mountain, in 4-stud layers: rock sides, a grassy terrace and top
	local layer = 4
	local y = GROUND
	while y < I.Top.y + GROUND - 0.01 do
		local top = y + layer
		local r = radiusAt(top - GROUND)
		disc(r, top, layer, Enum.Material.Rock)
		y = top
	end
	-- the mid terrace and the top plateau: grass on the flats
	disc(I.Mid.outer - 6, I.Mid.y + GROUND, 3, Enum.Material.Grass)
	disc(I.Top.r - 4, I.Top.y + GROUND, 3, Enum.Material.Grass)
	-- the mid terrace's flat (the layers above it are narrower: fill the shelf flat)
	disc(I.Mid.outer, I.Mid.y + GROUND - 3, 6, Enum.Material.Ground)
	disc(I.Mid.outer - 6, I.Mid.y + GROUND, 3, Enum.Material.Grass)
	-- the summit: a rocky knoll with a few crags
	local P = I.Peak
	t:FillBall(Vector3.new(c.X, I.Top.y, c.Z), P.r, Enum.Material.Rock)
	for k = 1, 5 do
		local a = k / 5 * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		t:FillBall(Vector3.new(c.X + math.cos(a) * P.r * 0.55, I.Top.y + P.r * 0.45, c.Z + math.sin(a) * P.r * 0.55), P.r * rng:NextNumber(0.3, 0.45), Enum.Material.Slate)
	end
	-- rock bumps on the slopes (not on the roads: they're carved out again below)
	local lots = IsleLayout.lots()
	for _ = 1, 140 do
		local a = rng:NextNumber(0, math.pi * 2)
		local upper = rng:NextNumber() < 0.45
		local r = if upper then rng:NextNumber(I.Top.r + 30, I.Mid.inner - 10) else rng:NextNumber(I.Mid.outer + 15, I.Foot - 25)
		local gy = IsleLayout.groundY(r)
		local p = Vector3.new(c.X + math.cos(a) * r, gy, c.Z + math.sin(a) * r)
		local size = rng:NextNumber(14, 34)
		if clearOfRoads(p, size + 10) and clearOfLots(p, lots, size) then
			t:FillBall(p, size, if rng:NextNumber() < 0.7 then Enum.Material.Rock else Enum.Material.Slate)
		end
	end
end

-- rock in under a road piece (from its surface down into the ground) and air above it
local function fillUnder(t: Terrain, a: Vector3, b: Vector3, width: number)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local h = math.max(a.Y, b.Y) + 12
	local cf = CFrame.lookAt(mid, b) * CFrame.new(0, -0.8 - h / 2, 0)
	t:FillBlock(cf, Vector3.new(width + 14, h, len + 2), Enum.Material.Rock)
	-- a wider skirt lower down, so a raised road reads as a built-up bank, not a wall
	t:FillBlock(cf * CFrame.new(0, -h * 0.25, 0), Vector3.new(width + 50, h * 0.5, len + 2), Enum.Material.Rock)
end
local function carveAbove(t: Terrain, a: Vector3, b: Vector3, width: number)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	t:FillBlock(CFrame.lookAt(mid, b) * CFrame.new(0, -0.6 + 26, 0), Vector3.new(width + 2, 52, len + 6), Enum.Material.Air)
end

---------------------------------------------------------------------
-- Road parts
---------------------------------------------------------------------
-- a straight road piece from a to b (surface points), with its markings
local function roadPiece(kit: any, parent: Instance, a: Vector3, b: Vector3, opts: { centre: boolean, edges: boolean })
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	kit.mk(parent, Vector3.new(ROAD, 1.2, len + 2), cf * CFrame.new(0, -0.6, 0), kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
	if opts.centre then
		kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(-0.3, 0.02, 0), kit.LINE_YELLOW, Enum.Material.SmoothPlastic)
		kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(0.3, 0.02, 0), kit.LINE_YELLOW, Enum.Material.SmoothPlastic)
	end
	if opts.edges then
		for _, s in { -1, 1 } do
			kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(s * (HALF - 1.4), 0.02, 0), kit.LINE_WHITE, Enum.Material.SmoothPlastic)
		end
	end
end

-- a ring road: pieces round the circle, kerbs (open at the junctions), lamps outside
local function ringRoad(kit: any, parent: Instance, ring: IsleLayout.Ring, t: Terrain)
	local folder = kit.folder("Ring_" .. ring.id, parent)
	local joins = IsleLayout.joins(ring.id)
	local n = math.clamp(math.floor(ring.radius * 2 * math.pi / 40), 64, 160) -- (small rings: short pieces, no gaps at the corners)
	local function inGap(a: number, extra: number): boolean
		for _, j in joins do
			local d = (a - j.angle) % (2 * math.pi)
			if math.min(d, 2 * math.pi - d) < j.gap + extra then
				return true
			end
		end
		return false
	end
	local lampEvery = math.max(2, math.floor(n / 24))
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = IsleLayout.polar(ring.radius, a0, ring.y)
		local p1 = IsleLayout.polar(ring.radius, a1, ring.y)
		local am = (a0 + a1) / 2
		roadPiece(kit, folder, p0, p1, { centre = k % 2 == 0, edges = not inGap(am, 0) })
		carveAbove(t, p0, p1, ROAD + 6)
		local cf = CFrame.lookAt((p0 + p1) / 2, p1)
		local len = (p1 - p0).Magnitude
		if not inGap(am, 0.01) then
			for _, s in { -1, 1 } do
				kit.mk(folder, Vector3.new(1, CURB, len + 1), cf * CFrame.new(s * (HALF + 0.5), CURB / 2, 0), KERB, Enum.Material.Concrete, { name = "Kerb" })
			end
		end
		if k % lampEvery == 0 and not inGap(am, 0.03) then
			local out = Vector3.new(math.cos(am), 0, math.sin(am))
			kit.streetLight(folder, IsleLayout.polar(ring.radius + HALF + 2, am, ring.y), -out)
		end
	end
end

-- a climb (IsleLayout.Roads): each leg in pieces following its slope, a pad at each corner,
-- guard rails and invisible walls along the sides, lamps
local function climb(kit: any, parent: Instance, rd: IsleLayout.Road, t: Terrain)
	local folder = kit.folder("Road_" .. rd.id, parent)
	local T = IsleLayout.Trim
	local pts = rd.pts
	for k = 1, #pts - 1 do
		local a, b = pts[k], pts[k + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		local dir = flat.Unit
		local side = dir:Cross(Vector3.yAxis)
		local function at(d: number, off: number?): Vector3
			local p = a + dir * d + side * (off or 0)
			return Vector3.new(p.X, IsleLayout.legY(a.Y, b.Y, len, d), p.Z)
		end
		-- pieces: the level ends, the slope in 30-stud pieces
		local cuts = { 0 }
		if len > T * 2 + 1 then
			table.insert(cuts, T)
			local n = math.max(1, math.ceil((len - T * 2) / 30))
			for q = 1, n - 1 do
				table.insert(cuts, T + (len - T * 2) * q / n)
			end
			table.insert(cuts, len - T)
		end
		table.insert(cuts, len)
		local detail = kit.lodGroup(folder, "Detail", (a + b) / 2, 700 + len / 2)
		for q = 1, #cuts - 1 do
			local d0, d1 = cuts[q], cuts[q + 1]
			local p0, p1 = at(d0), at(d1)
			roadPiece(kit, folder, p0, p1, { centre = true, edges = true })
			fillUnder(t, p0, p1, ROAD)
			-- rails and walls, not into the corners (the turn sweeps across there)
			local first, last = k == 1 and q == 1, k == #pts - 1 and q == #cuts - 1
			local nearCorner = (q == 1 and k > 1) or (q == #cuts - 1 and k < #pts - 1)
			if rd.rails and not nearCorner and not first and not last then
				local cf = CFrame.lookAt((p0 + p1) / 2, p1)
				local plen = (p1 - p0).Magnitude
				for _, s in { -1, 1 } do
					kit.mk(folder, Vector3.new(0.5, 0.9, plen + 0.2), cf * CFrame.new(s * (HALF + 1), 2.2, 0), RAIL, Enum.Material.Metal, { name = "Rail" })
					kit.mk(folder, Vector3.new(1, 30, plen), cf * CFrame.new(s * (HALF + 1.6), 15, 0), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
					local posts = math.max(1, math.floor(plen / 16))
					for pp = 0, posts - 1 do
						kit.deco(detail, Vector3.new(0.5, 2.4, 0.5), cf * CFrame.new(s * (HALF + 1), 1.2, -plen / 2 + (pp + 0.5) * plen / posts), RAIL, Enum.Material.Metal)
					end
				end
			end
		end
		-- lamps every 90 studs on the outer side
		local l = 45
		local s = if k % 2 == 0 then 1 else -1
		while l < len - 30 do
			kit.streetLight(detail, at(l, s * (HALF + 2.5)), -side * s)
			l += 90
		end
	end
	-- the corners: level pads the turns sweep across (a square along each leg, just under them)
	for k = 2, #pts - 1 do
		local p = pts[k]
		for _, q in { pts[k - 1], pts[k + 1] } do
			local look = Vector3.new(q.X - p.X, 0, q.Z - p.Z).Unit
			local cf = CFrame.lookAt(Vector3.new(p.X, p.Y - 0.62, p.Z), Vector3.new(p.X, p.Y - 0.62, p.Z) + look)
			kit.mk(folder, Vector3.new(ROAD + 6, 1.2, ROAD + 6), cf, kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		end
		fillUnder(t, p - Vector3.new(HALF, 0, 0), p + Vector3.new(HALF, 0, 0), ROAD + 10)
	end
end

local function carveRoad(rd: IsleLayout.Road, t: Terrain)
	local pts = rd.pts
	for k = 1, #pts - 1 do
		local a, b = pts[k], pts[k + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		local dir = flat.Unit
		local n = math.max(1, math.ceil(len / 30))
		for q = 0, n - 1 do
			local d0, d1 = len * q / n, len * (q + 1) / n
			local p0 = a + dir * d0
			local p1 = a + dir * d1
			carveAbove(t, Vector3.new(p0.X, IsleLayout.legY(a.Y, b.Y, len, d0), p0.Z), Vector3.new(p1.X, IsleLayout.legY(a.Y, b.Y, len, d1), p1.Z), ROAD + 6)
		end
	end
	for k = 2, #pts - 1 do
		local p = pts[k]
		t:FillBlock(CFrame.new(p.X, p.Y - 0.6 + 26, p.Z), Vector3.new(ROAD + 18, 52, ROAD + 18), Enum.Material.Air)
	end
end

---------------------------------------------------------------------
-- Scenery
---------------------------------------------------------------------
local function pine(kit: any, parent: Instance, pos: Vector3)
	local h = rng:NextNumber(18, 30)
	kit.deco(parent, Vector3.new(h * 0.5, 1.4, 1.4), CFrame.new(pos + Vector3.new(0, h * 0.25, 0)) * UP, BARK, Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
	local green = PINE[rng:NextInteger(1, #PINE)]
	for q = 0, 2 do
		local w = (h * 0.42) * (1 - q * 0.28)
		kit.deco(parent, Vector3.new(h * 0.26, w, w), CFrame.new(pos + Vector3.new(0, h * (0.35 + q * 0.22), 0)) * UP, green, Enum.Material.LeafyGrass, { shape = Enum.PartType.Cylinder, shadow = true })
	end
end

local function lifeguardTower(kit: any, parent: Instance, pos: Vector3, face: Vector3)
	local cf = CFrame.lookAt(pos, pos + face)
	for _, sx in { -3, 3 } do
		for _, sz in { -3, 3 } do
			kit.mk(parent, Vector3.new(0.6, 9, 0.6), cf * CFrame.new(sx, 4.5, sz), WHITE, Enum.Material.Wood)
		end
	end
	kit.mk(parent, Vector3.new(8, 0.6, 8), cf * CFrame.new(0, 9, 0), WOOD, Enum.Material.WoodPlanks)
	kit.mk(parent, Vector3.new(7, 5, 7), cf * CFrame.new(0, 11.8, 0), Color3.fromRGB(230, 90, 70), Enum.Material.SmoothPlastic, { name = "LifeguardHut" })
	kit.mk(parent, Vector3.new(9, 0.5, 9), cf * CFrame.new(0, 14.6, 0), WHITE, Enum.Material.SmoothPlastic)
	kit.mk(parent, Vector3.new(3, 0.4, 8), cf * CFrame.new(0, 4.5, -7) * CFrame.Angles(math.rad(-50), 0, 0), WOOD, Enum.Material.WoodPlanks)
end

local function beachHut(kit: any, parent: Instance, pos: Vector3, face: Vector3)
	local cf = CFrame.lookAt(pos, pos + face)
	local col = HUTS[rng:NextInteger(1, #HUTS)]
	kit.mk(parent, Vector3.new(8, 7, 7), cf * CFrame.new(0, 3.5, 0), col, Enum.Material.WoodPlanks, { name = "BeachHut" })
	kit.mk(parent, Vector3.new(9, 2, 8), cf * CFrame.new(0, 8, 0), WHITE, Enum.Material.WoodPlanks, { class = "Wedge" })
	kit.deco(parent, Vector3.new(3, 5, 0.2), cf * CFrame.new(0, 2.5, -3.6), Color3.fromRGB(70, 60, 50), Enum.Material.Wood)
end

local function pier(kit: any, parent: Instance, from: Vector3, dir: Vector3, len: number)
	local cf = CFrame.lookAt(from, from + dir)
	kit.mk(parent, Vector3.new(14, 1, len), cf * CFrame.new(0, 1.5, -len / 2), WOOD, Enum.Material.WoodPlanks, { name = "Pier" })
	local n = math.floor(len / 20)
	for k = 0, n do
		for _, sx in { -6, 6 } do
			kit.mk(parent, Vector3.new(1.2, 14, 1.2), cf * CFrame.new(sx, -5, -k * len / n), WOOD, Enum.Material.Wood)
		end
	end
	for _, sx in { -6.6, 6.6 } do
		kit.mk(parent, Vector3.new(0.3, 3, len), cf * CFrame.new(sx, 3.5, -len / 2), WOOD, Enum.Material.Wood, { name = "Rail" })
	end
	-- a T at the end and two lamps
	kit.mk(parent, Vector3.new(44, 1, 14), cf * CFrame.new(0, 1.5, -len - 6), WOOD, Enum.Material.WoodPlanks, { name = "Pier" })
	for _, sx in { -18, 18 } do
		local base = (cf * CFrame.new(sx, 2, -len - 6)).Position
		local post = kit.mk(parent, Vector3.new(10, 0.5, 0.5), CFrame.new(base + Vector3.new(0, 5, 0)) * UP, Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		local lamp = kit.deco(parent, Vector3.one * 1.4, CFrame.new(base + Vector3.new(0, 10.6, 0)), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		kit.dayOff(lamp, kit.addLight("PointLight", lamp, WARM, 30, 1.4))
		local _ = post
	end
end

local function fountain(kit: any, parent: Instance, p: Vector3)
	kit.mk(parent, Vector3.new(80, 0.4, 80), CFrame.new(p + Vector3.new(0, 0.2, 0)), Color3.fromRGB(184, 178, 166), Enum.Material.Limestone, { name = "Plaza" })
	kit.mk(parent, Vector3.new(1.4, 36, 36), CFrame.new(p + Vector3.new(0, 1.1, 0)) * UP, STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local water = kit.deco(parent, Vector3.new(0.4, 31, 31), CFrame.new(p + Vector3.new(0, 1.7, 0)) * UP, Color3.fromRGB(60, 170, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.45 })
	kit.addLight("PointLight", water, Color3.fromRGB(80, 170, 255), 26, 0.9)
	kit.mk(parent, Vector3.new(6, 4, 4), CFrame.new(p + Vector3.new(0, 4, 0)) * UP, STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	kit.deco(parent, Vector3.new(12, 2.4, 2.4), CFrame.new(p + Vector3.new(0, 9, 0)) * UP, Color3.fromRGB(170, 220, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
end

local function helipad(kit: any, parent: Instance, p: Vector3)
	kit.mk(parent, Vector3.new(1, 54, 54), CFrame.new(p + Vector3.new(0, 0.5, 0)) * UP, Color3.fromRGB(40, 42, 48), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder, name = "Helipad" })
	kit.deco(parent, Vector3.new(0.1, 44, 44), CFrame.new(p + Vector3.new(0, 1.02, 0)) * UP, Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, transparency = 0.6 })
	local h = kit.deco(parent, Vector3.new(16, 0.1, 22), CFrame.new(p + Vector3.new(0, 1.06, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(160, 220)
	gui.LightInfluence = 1
	gui.Parent = h
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "H"
	t.TextScaled = true
	t.Font = Enum.Font.GothamBlack
	t.TextColor3 = Color3.fromRGB(240, 240, 240)
	t.Parent = gui
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		kit.deco(parent, Vector3.one * 1.2, CFrame.new(p + Vector3.new(math.cos(a) * 25, 1.2, math.sin(a) * 25)), Color3.fromRGB(80, 255, 140), Enum.Material.Neon, { shape = Enum.PartType.Ball })
	end
end

local function lookout(kit: any, parent: Instance, p: Vector3)
	-- a stone deck at the plateau's edge looking back over the bay to Downtown (east)
	local face = Vector3.new(p.X - CENTER.X, 0, p.Z - CENTER.Z).Unit
	local cf = CFrame.lookAt(p, p + face)
	kit.mk(parent, Vector3.new(60, 1, 40), cf * CFrame.new(0, 0.5, -6), STONE, Enum.Material.Limestone, { name = "Lookout" })
	for _, sx in { -30, 30 } do
		kit.mk(parent, Vector3.new(1, 3.4, 40), cf * CFrame.new(sx, 2.7, -6), STONE, Enum.Material.Limestone)
	end
	kit.mk(parent, Vector3.new(60, 3.4, 1), cf * CFrame.new(0, 2.7, -26), STONE, Enum.Material.Limestone, { name = "LookoutWall" })
	for _, sx in { -12, 12 } do
		kit.mk(parent, Vector3.new(0.4, 3, 0.4), cf * CFrame.new(sx, 2.5, -22), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		kit.mk(parent, Vector3.new(0.8, 0.8, 3), cf * CFrame.new(sx, 4.2, -22.4) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(180, 150, 80), Enum.Material.Metal, { name = "Telescope" })
	end
end

-- the gate's guard house and pillars (Gate adds the barrier arm and the guards at start)
local function gateHouse(kit: any, parent: Instance)
	local g = IsleLayout.GateCFrame
	local folder = kit.folder("Gate", parent)
	for _, s in { -1, 1 } do
		kit.mk(folder, Vector3.new(4, 12, 4), g * CFrame.new(s * (HALF + 3), 6, 0), STONE, Enum.Material.Limestone, { name = "GatePillar" })
		kit.deco(folder, Vector3.new(4.6, 1, 4.6), g * CFrame.new(s * (HALF + 3), 12.5, 0), Color3.fromRGB(180, 150, 90), Enum.Material.Metal)
		local lamp = kit.deco(folder, Vector3.one * 1.6, g * CFrame.new(s * (HALF + 3), 13.8, 0), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		kit.dayOff(lamp, kit.addLight("PointLight", lamp, WARM, 28, 1.3))
	end
	-- the guard house, left of the road coming in
	local h = g * CFrame.new(-(HALF + 13), 0, 6)
	kit.mk(folder, Vector3.new(14, 0.6, 12), h * CFrame.new(0, 0.3, 0), STONE, Enum.Material.Limestone)
	kit.mk(folder, Vector3.new(12, 9, 0.6), h * CFrame.new(0, 5, 5.7), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.6, 9, 12), h * CFrame.new(-5.7, 5, 0), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.6, 3, 12), h * CFrame.new(5.7, 2, 0), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.3, 5, 11), h * CFrame.new(5.7, 6, 0), Color3.fromRGB(150, 190, 210), Enum.Material.Glass, { transparency = 0.5, name = "GuardWindow" })
	kit.mk(folder, Vector3.new(12, 0.6, 0.6), h * CFrame.new(0, 2, -5.7), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(16, 1, 14), h * CFrame.new(0, 10, 0), Color3.fromRGB(40, 42, 48), Enum.Material.Metal, { name = "GuardRoof" })
	local light = kit.deco(folder, Vector3.new(6, 0.2, 2), h * CFrame.new(0, 9.4, 0), WARM, Enum.Material.Neon)
	kit.dayOff(light, kit.addLight("PointLight", light, WARM, 22, 1.2))
	-- the community's name over the way in
	local sign = kit.mk(folder, Vector3.new(30, 4, 1), g * CFrame.new(-(HALF + 26), 3, -4) * CFrame.Angles(0, math.pi / 2, 0), STONE, Enum.Material.Limestone, { name = "GateSign" })
	kit.surfaceText(sign, Enum.NormalId.Front, "THE SUMMIT · RESIDENTS ONLY", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 120))
	kit.surfaceText(sign, Enum.NormalId.Back, "THE SUMMIT · RESIDENTS ONLY", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 120))
end

-- the low tier's street: a sidewalk inside the ring, a mailbox and a street tree at every lot
local function lowStreet(kit: any, parent: Instance, lots: { IsleLayout.Lot })
	local folder = kit.folder("LowStreet", parent)
	for _, l in lots do
		if l.zone == "low" then
			local f = l.frame
			local front = f * CFrame.new(0, 0, -l.depth / 2 - 4) -- the sidewalk in front of the lot
			kit.mk(folder, Vector3.new(l.width + 14, 0.4, 8), front * CFrame.new(0, 0.2, 0), kit.SIDEWALK, Enum.Material.Concrete, { name = "Sidewalk" })
			kit.mk(folder, Vector3.new(0.3, 3.4, 0.3), front * CFrame.new(l.width / 2 - 6, 2.1, 2.5), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
			kit.mk(folder, Vector3.new(1.2, 1, 1.8), front * CFrame.new(l.width / 2 - 6, 4.2, 2.5), Color3.fromRGB(40, 70, 130), Enum.Material.Metal, { name = "Mailbox" })
			kit.tree(folder, (front * CFrame.new(-l.width / 2 + 4, 0.4, 1)).Position, 0.8)
		end
	end
end

---------------------------------------------------------------------
-- The build
---------------------------------------------------------------------
function Isle.build(kit: any, parent: Instance, palm: (any, Instance, Vector3, number?) -> Vector3)
	local folder = kit.folder("LegendsIsle", parent)
	local t = workspace.Terrain
	terrain(t)
	-- the roads (rock in under the climbs as they're built), then air carved out above them all
	for _, ring in IsleLayout.Rings do
		ringRoad(kit, folder, ring, t)
	end
	for _, rd in IsleLayout.Roads do
		climb(kit, folder, rd, t)
	end
	for _, rd in IsleLayout.Roads do
		carveRoad(rd, t)
	end
	-- room round the gate for the guard house and the guards (the climb's first stub is cut into
	-- the foot of the upper face)
	t:FillBlock(IsleLayout.GateCFrame * CFrame.new(0, 16 - 0.6, 6), Vector3.new(96, 32, 60), Enum.Material.Air)

	local lots = IsleLayout.lots()
	-- the beach: palms all round, lifeguard towers and huts on the west and south, the pier
	local beach = kit.folder("Beach", folder)
	local nb = 64
	for k = 0, nb - 1 do
		local a = (k + rng:NextNumber(-0.3, 0.3)) / nb * math.pi * 2
		local p = IsleLayout.polar(rng:NextNumber(I.lawn - 30, I.lawn + 20), a, GROUND + 0.2)
		if math.abs(a) > 0.12 and clearOfRoads(p, 10) and clearOfLots(p, lots, 4) then
			palm(kit, beach, p)
		end
	end
	local sandR = (I.lawn + I.r) / 2 + 10
	for _, a in { math.pi * 0.85, math.pi, math.pi * 1.15, math.pi * 0.5, math.pi * 0.62 } do
		local p = IsleLayout.polar(sandR, a, GROUND + 0.6)
		lifeguardTower(kit, beach, p, (p - CENTER) * Vector3.new(1, 0, 1))
	end
	for k = 0, 7 do
		local a = math.pi * 0.7 + k * 0.09
		local p = IsleLayout.polar(I.lawn + 6, a, GROUND + 0.4)
		beachHut(kit, beach, p, (p - CENTER) * Vector3.new(1, 0, 1))
	end
	pier(kit, beach, IsleLayout.polar(I.r - 30, math.pi, 0), Vector3.new(-1, 0, 0), 220)

	-- trees: pines up the mountain, palms on the low ground and the terrace's edge
	local trees = kit.folder("Trees", folder)
	local placed = 0
	for _ = 1, 600 do
		if placed >= 230 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local band = rng:NextNumber()
		local r
		if band < 0.4 then
			r = rng:NextNumber(I.Mid.outer + 10, I.Foot + 30)
		elseif band < 0.75 then
			r = rng:NextNumber(I.Top.r + 15, I.Mid.inner - 5)
		else
			r = rng:NextNumber(I.Foot + 30, I.Ring - HALF - 12)
		end
		local p = IsleLayout.polar(r, a, IsleLayout.groundY(r) + GROUND)
		local clearRamps = true
		for _, rp in ChallengeData.ramps do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(rp.cf.X, 0, rp.cf.Z)).Magnitude < 90 then
				clearRamps = false
			end
		end
		if clearRamps and clearOfRoads(p, 14) and clearOfLots(p, lots, 6) and (p - IsleLayout.fountain()).Magnitude > 60 then
			placed += 1
			local group = kit.lodGroup(trees, "Detail", p, 900)
			if r > I.Foot + 20 then
				palm(kit, group, p)
			else
				pine(kit, group, p)
			end
		end
	end

	-- the neighbourhoods
	lowStreet(kit, folder, lots)
	fountain(kit, folder, IsleLayout.fountain())
	helipad(kit, folder, IsleLayout.helipad())
	lookout(kit, folder, IsleLayout.lookout())
	gateHouse(kit, folder)
	-- the island's name where the causeway lands
	local sp = IsleLayout.polar(I.Ring + HALF + 40, 0.08, 0)
	local wall = kit.mk(folder, Vector3.new(50, 9, 3), CFrame.lookAt(sp + Vector3.new(0, 4.5, 0), sp + Vector3.new(0, 4.5, 0) + Vector3.new(0, 0, 1)), STONE, Enum.Material.Limestone, { name = "IslandSign" })
	kit.surfaceText(wall, Enum.NormalId.Front, "LEGENDS ISLE", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
	kit.surfaceText(wall, Enum.NormalId.Back, "LEGENDS ISLE", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
end

return Isle
