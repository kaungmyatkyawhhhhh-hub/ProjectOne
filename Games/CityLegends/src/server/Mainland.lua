--[[
	Mainland
	The land round the harbour, where the Legends Loop runs (owner, 2026-10-17: "make the map 10x
	better"):
	  * a rocky shore with promenade lamps along the water
	  * suburbs between the shore and the loop: a lit street with houses either side
	  * a container port on the east shore: stacks of containers, gantry cranes, warehouses
	  * outside the loop: forest, rolling hills, wind turbines and radio masts with blinking
	    lights, and a mountain range on the horizon
	Small things sit in LOD groups (WorldFx hides them when the camera is far away).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))

local Mainland = {}

local C = Config.City
local E = C.HalfExtent + C.RoadWidth / 2
local RING = C.OuterRingDepth
local HW = C.HighwayWidth / 2
local O = E + RING -- the city island's edge
local W = O + 1500 -- the harbour's outer edge
local LOOP_S = C.LoopHalf
local LOOP_IN = LOOP_S - HW - 8 -- the loop's inner edge
local LOOP_OUT = LOOP_S + HW + 8
local OUT = LOOP_S + 1100 -- the land's outer edge
local WARM = Color3.fromRGB(255, 196, 130)
-- (2026-10-23: natural colours; the night lighting darkens them at night)
local GRASS = Color3.fromRGB(56, 78, 42)
local ROCK = Color3.fromRGB(82, 78, 72)

-- the four sides of a square ring: for each, the outward normal and the along direction
local SIDES = {
	{ n = Vector3.new(0, 0, -1), t = Vector3.new(1, 0, 0) },
	{ n = Vector3.new(0, 0, 1), t = Vector3.new(1, 0, 0) },
	{ n = Vector3.new(-1, 0, 0), t = Vector3.new(0, 0, 1) },
	{ n = Vector3.new(1, 0, 0), t = Vector3.new(0, 0, 1) },
}

-- the tunnel's mountain and the spur stay clear on the east side
local function eastClear(p: Vector3): boolean
	return p.X > O - 10 and math.abs(p.Z) < 820
end

-- how far a point is from the loop's centre line (the corners are round)
local LOOP_C = LOOP_S - C.LoopCorner
local function loopDist(p: Vector3): number
	local x, z = math.abs(p.X), math.abs(p.Z)
	if x <= LOOP_C or z <= LOOP_C then
		return math.abs(math.max(x, z) - LOOP_S)
	end
	return math.abs(Vector2.new(x - LOOP_C, z - LOOP_C).Magnitude - C.LoopCorner)
end
local function nearLoop(p: Vector3, margin: number): boolean
	return loopDist(p) < HW + 8 + margin
end

---------------------------------------------------------------------
-- Shore: a rock bank down to the water, with lamps along the top
---------------------------------------------------------------------
local function shore(kit: any, parent: Instance)
	local folder = kit.folder("Shore", parent)
	local rng = kit.rng
	for _, sd in SIDES do
		for t = -W + 60, W - 60, 120 do
			local p = sd.n * W + sd.t * t
			-- the east side's middle is land (the spur), not water
			if sd.n.X > 0.5 and math.abs(t) < O then
				continue
			end
			local cf = CFrame.lookAt(p, p - sd.n)
			-- a sloped rock bank (a wedge sloping down towards the water)
			kit.mk(folder, Vector3.new(124, 4.5, 14), cf * CFrame.new(0, -2.4, 6) * CFrame.Angles(0, math.pi, 0), ROCK, Enum.Material.Slate, { class = "Wedge", name = "Shore" })
			if rng:NextNumber() < 0.6 then
				kit.deco(folder, Vector3.new(rng:NextNumber(6, 12), rng:NextNumber(3, 6), rng:NextNumber(6, 10)), cf * CFrame.new(rng:NextNumber(-50, 50), -1.5, 10) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), 0), ROCK:Lerp(Color3.fromRGB(70, 66, 60), rng:NextNumber()), Enum.Material.Rock, { shadow = true })
			end
			-- promenade lamp
			local lp = p - sd.n * 6
			kit.deco(folder, Vector3.new(0.4, 8, 0.4), CFrame.new(lp + Vector3.new(0, 4, 0)), kit.METAL, Enum.Material.Metal)
			local bulb = kit.deco(folder, Vector3.one * 1.3, CFrame.new(lp + Vector3.new(0, 8.4, 0)), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
			kit.dayOff(bulb, if math.floor(t / 120) % 3 == 0 then kit.addLight("PointLight", bulb, WARM, 26, 0.9) else nil)
		end
	end
end

---------------------------------------------------------------------
-- Suburbs: between the shore and the loop
---------------------------------------------------------------------
local HOUSE_WALLS = {
	Color3.fromRGB(150, 140, 122), Color3.fromRGB(122, 110, 96), Color3.fromRGB(96, 104, 112),
	Color3.fromRGB(140, 120, 104), Color3.fromRGB(110, 118, 104), Color3.fromRGB(168, 160, 146),
}
local ROOFS = { Color3.fromRGB(56, 40, 36), Color3.fromRGB(40, 42, 48), Color3.fromRGB(70, 48, 40), Color3.fromRGB(46, 50, 46) }

local function house(kit: any, parent: Instance, base: Vector3, front: Vector3)
	local rng = kit.rng
	local w, d = rng:NextNumber(20, 28), rng:NextNumber(18, 24)
	local h = if rng:NextNumber() < 0.4 then 22 else 12
	local cf = CFrame.lookAt(base, base + front) -- -Z of the frame = front of the house
	local wall = kit.pick(HOUSE_WALLS)
	kit.mk(parent, Vector3.new(w, h, d), cf * CFrame.new(0, h / 2, 0), wall, Enum.Material.Plaster, { name = "House" })
	-- gable roof: two wedges back to back
	local roof = kit.pick(ROOFS)
	local rh = rng:NextNumber(6, 8)
	kit.mk(parent, Vector3.new(w + 1.5, rh, d / 2 + 1), cf * CFrame.new(0, h + rh / 2, -(d / 4 + 0.5)), roof, Enum.Material.Slate, { class = "Wedge" })
	kit.mk(parent, Vector3.new(w + 1.5, rh, d / 2 + 1), cf * CFrame.new(0, h + rh / 2, d / 4 + 0.5) * CFrame.Angles(0, math.pi, 0), roof, Enum.Material.Slate, { class = "Wedge" })
	-- windows: warm lit or dark, a door with a porch light
	local floors = if h > 15 then 2 else 1
	for f = 1, floors do
		for _, x in { -w * 0.3, w * 0.3 } do
			local lit = rng:NextNumber() < 0.55
			kit.deco(parent, Vector3.new(4, 4, 0.2), cf * CFrame.new(x, (f - 0.5) * 10 + 1, -d / 2 - 0.1), if lit then Color3.fromRGB(255, 200, 130) else Color3.fromRGB(20, 24, 30), if lit then Enum.Material.Neon else Enum.Material.Glass, { transparency = if lit then 0.25 else 0 })
		end
	end
	kit.deco(parent, Vector3.new(4, 7.5, 0.3), cf * CFrame.new(0, 3.75, -d / 2 - 0.15), Color3.fromRGB(60, 40, 30), Enum.Material.Wood)
	local porch = kit.deco(parent, Vector3.one * 0.7, cf * CFrame.new(0, 8.5, -d / 2 - 0.6), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
	if rng:NextNumber() < 0.25 then
		kit.addLight("PointLight", porch, WARM, 14, 0.7)
	end
	-- driveway and a little lawn fence
	kit.deco(parent, Vector3.new(7, 0.2, 12), cf * CFrame.new(w / 2 + 4, 0.1, -d / 2 - 6), Color3.fromRGB(60, 60, 62), Enum.Material.Concrete)
	if rng:NextNumber() < 0.5 then
		kit.tree(parent, (cf * CFrame.new(-w / 2 - 4, 0, -d / 2 - 6)).Position)
	end
end

local function suburbs(kit: any, parent: Instance)
	local root = kit.folder("Suburbs", parent)
	local streetAt = (W + LOOP_IN) / 2 -- the street runs midway between shore and loop
	for si, sd in SIDES do
		local half = streetAt - 40
		local t = -half
		while t < half do
			local t1 = math.min(t + 500, half)
			local mid = sd.n * streetAt + sd.t * ((t + t1) / 2)
			-- (the corners: the loop curves in across the street's line)
			if eastClear(mid) or nearLoop(sd.n * streetAt + sd.t * t, 80) or nearLoop(sd.n * streetAt + sd.t * t1, 80) then
				t = t1
				continue
			end
			local group = kit.lodGroup(root, `Suburb_{si}_{math.floor(t)}`, mid, 900)
			-- the street (asphalt, centre dashes, lamps)
			local a, b = sd.n * streetAt + sd.t * t, sd.n * streetAt + sd.t * t1
			local len = (b - a).Magnitude
			kit.mk(group, Vector3.new(26, 0.4, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, -0.1, 0), b + Vector3.new(0, -0.1, 0)), Color3.fromRGB(36, 36, 40), Enum.Material.Asphalt, { name = "Street" })
			local s = 6
			while s < len - 6 do
				local p = a:Lerp(b, s / len)
				kit.deco(group, Vector3.new(0.3, 0.05, 6), CFrame.lookAt(p + Vector3.new(0, 0.12, 0), p + Vector3.new(0, 0.12, 0) + sd.t), Color3.fromRGB(220, 170, 40), Enum.Material.SmoothPlastic)
				s += 16
			end
			-- houses on the loop's side, facing the street (the other side has the waterfront towers)
			local x = 20
			while x < len - 20 do
				local p = a:Lerp(b, x / len) + sd.n * 34
				-- (not under the coastal highway's viaduct)
				if not WestLayout.inCorridor(p, 30) then
					house(kit, group, Vector3.new(p.X, -0.3, p.Z), -sd.n)
				end
				x += kit.rng:NextNumber(38, 48)
			end
			-- lamps along the street
			local l = 30
			while l < len do
				local p = a:Lerp(b, l / len) + sd.n * 15
				local pole = kit.deco(group, Vector3.new(0.5, 14, 0.5), CFrame.new(p + Vector3.new(0, 7, 0)), kit.METAL, Enum.Material.Metal)
				local lamp = kit.deco(group, Vector3.new(2, 0.4, 1.2), pole.CFrame * CFrame.new(0, 7, 0), WARM, Enum.Material.Neon)
				kit.dayOff(lamp, kit.addLight("SpotLight", lamp, WARM, 40, 1.6, Enum.NormalId.Bottom, 120))
				l += 110
			end
			t = t1
		end
	end
end

---------------------------------------------------------------------
-- Container port on the east shore (north and south of the tunnel mountain)
---------------------------------------------------------------------
local CONTAINER = {
	Color3.fromRGB(150, 40, 30), Color3.fromRGB(30, 80, 140), Color3.fromRGB(190, 120, 30), Color3.fromRGB(40, 110, 70),
	Color3.fromRGB(120, 120, 126), Color3.fromRGB(160, 150, 140), Color3.fromRGB(90, 30, 90),
}

local function port(kit: any, parent: Instance)
	local root = kit.folder("Port", parent)
	local rng = kit.rng
	for _, sz in { -1, 1 } do
		local cx, cz = (O + W) / 2 + 150, sz * (O + 120)
		local group = kit.lodGroup(root, `Port_{sz}`, Vector3.new(cx, 0, cz), 1300)
		-- concrete apron
		kit.mk(group, Vector3.new(1000, 0.6, 360), CFrame.new(cx, 0, cz), Color3.fromRGB(62, 62, 64), Enum.Material.Concrete, { name = "Apron" })
		-- container stacks in rows
		for row = -3, 3 do
			for col = -8, 8 do
				if rng:NextNumber() < 0.8 then
					local stack = rng:NextInteger(1, 4)
					for k = 1, stack do
						local p = Vector3.new(cx + col * 50, 0.3 + (k - 0.5) * 8.6, cz + row * 22 - sz * 40)
						kit.mk(group, Vector3.new(40, 8.4, 8), CFrame.new(p), kit.pick(CONTAINER), Enum.Material.CorrodedMetal, { name = "Container" })
					end
				end
			end
		end
		-- gantry cranes along the water's edge, red warning lights on top
		for k = -2, 2 do
			local qx = cx + k * 180
			local qz = cz + sz * 150
			for _, dx in { -14, 14 } do
				for _, dz in { -10, 10 } do
					kit.mk(group, Vector3.new(2.5, 70, 2.5), CFrame.new(qx + dx, 35, qz + dz), Color3.fromRGB(200, 150, 40), Enum.Material.Metal)
				end
			end
			kit.mk(group, Vector3.new(34, 6, 120), CFrame.new(qx, 72, qz + sz * 30), Color3.fromRGB(200, 150, 40), Enum.Material.Metal)
			local beacon = kit.deco(group, Vector3.one * 2, CFrame.new(qx, 77, qz + sz * 30), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, { shape = Enum.PartType.Ball })
			CollectionService:AddTag(beacon, "Blink")
			local flood = kit.deco(group, Vector3.new(3, 1, 3), CFrame.new(qx, 68, qz), Color3.fromRGB(255, 240, 220), Enum.Material.Neon)
			kit.addLight("SpotLight", flood, Color3.fromRGB(255, 236, 210), 90, 2.2, Enum.NormalId.Bottom, 110)
		end
		-- warehouses behind
		for k = -2, 2 do
			local p = Vector3.new(cx + k * 190, 0, cz - sz * 150)
			kit.mk(group, Vector3.new(150, 30, 60), CFrame.new(p + Vector3.new(0, 15, 0)), Color3.fromRGB(70, 76, 82), Enum.Material.CorrodedMetal, { name = "Warehouse" })
			kit.deco(group, Vector3.new(130, 2, 0.4), CFrame.new(p + Vector3.new(0, 24, sz * 30.3)), Color3.fromRGB(255, 220, 160), Enum.Material.Neon, { transparency = 0.3 })
		end
	end
end

---------------------------------------------------------------------
-- Outside the loop: forest, hills, wind turbines, masts and a mountain range
---------------------------------------------------------------------
local function outer(kit: any, parent: Instance)
	local root = kit.folder("Countryside", parent)
	local rng = kit.rng
	-- rolling hills: big low grassy mounds
	for _ = 1, 60 do
		local sd = SIDES[rng:NextInteger(1, 4)]
		local r = rng:NextNumber(160, 300)
		local p = sd.n * rng:NextNumber(LOOP_OUT + r + 40, OUT + 200) + sd.t * rng:NextNumber(-OUT + 200, OUT - 200)
		if nearLoop(p, r + 30) or WestLayout.inCorridor(p, r + 40) then
			continue
		end
		kit.mk(root, Vector3.new(r * 2, rng:NextNumber(50, 120), r * 2), CFrame.new(p.X, -10, p.Z), GRASS:Lerp(Color3.fromRGB(74, 96, 50), rng:NextNumber()), Enum.Material.Grass, { shape = Enum.PartType.Ball, name = "Hill" })
	end
	-- forest in clumps (LOD), kept off the road's verge
	for c = 1, 140 do
		local sd = SIDES[rng:NextInteger(1, 4)]
		local center = sd.n * rng:NextNumber(LOOP_OUT + 60, OUT - 80) + sd.t * rng:NextNumber(-OUT + 100, OUT - 100)
		local group = kit.lodGroup(root, `Forest_{c}`, center, 1100)
		for _ = 1, rng:NextInteger(14, 26) do
			local p = center + Vector3.new(rng:NextNumber(-90, 90), 0, rng:NextNumber(-90, 90))
			if math.max(math.abs(p.X), math.abs(p.Z)) > LOOP_OUT + 30 and not nearLoop(p, 30) and not WestLayout.inCorridor(p, 40) then
				-- a conifer: trunk and two cones (wedge-less: stacked shrinking blocks read as a fir at night)
				local h = rng:NextNumber(26, 44)
				kit.deco(group, Vector3.new(1.4, h * 0.3, 1.4), CFrame.new(p + Vector3.new(0, h * 0.15, 0)), Color3.fromRGB(46, 34, 26), Enum.Material.Wood)
				for k = 0, 1 do
					local s = (1 - k * 0.4) * h * 0.4
					kit.deco(group, Vector3.new(s, h * 0.32, s), CFrame.new(p + Vector3.new(0, h * (0.32 + k * 0.22), 0)) * CFrame.Angles(0, rng:NextNumber(0, 1.5), 0), Color3.fromRGB(34, 60, 38):Lerp(Color3.fromRGB(50, 82, 46), rng:NextNumber()), Enum.Material.LeafyGrass, { shadow = true })
				end
			end
		end
	end
	-- wind turbines on the far hills, red lights blinking on the nacelles
	for k = 1, 16 do
		local sd = SIDES[(k % 4) + 1]
		local p = sd.n * (OUT - 300 + rng:NextNumber(-80, 80)) + sd.t * rng:NextNumber(-OUT + 400, OUT - 400)
		if WestLayout.inCorridor(p, 120) then
			continue
		end
		local h = 150
		kit.mk(root, Vector3.new(h, 6, 6), CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(196, 198, 202), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, name = "Turbine" })
		local hub = p + Vector3.new(0, h + 2, 0) - sd.n * 6
		kit.deco(root, Vector3.new(7, 7, 14), CFrame.lookAt(hub, hub - sd.n), Color3.fromRGB(196, 198, 202), Enum.Material.SmoothPlastic)
		local a0 = rng:NextNumber(0, math.pi * 2)
		for b = 0, 2 do
			local a = a0 + b * math.pi * 2 / 3
			local tip = Vector3.new(0, math.cos(a), 0) * 30 + sd.t * math.sin(a) * 30
			kit.deco(root, Vector3.new(2.4, 60, 0.8), CFrame.lookAt(hub - sd.n * 7.5 + tip / 2, hub - sd.n * 7.5 + tip / 2 - sd.n) * CFrame.Angles(0, 0, a), Color3.fromRGB(210, 212, 216), Enum.Material.SmoothPlastic)
		end
		local light = kit.deco(root, Vector3.one * 1.6, CFrame.new(hub + Vector3.new(0, 4, 0)), Color3.fromRGB(255, 20, 20), Enum.Material.Neon, { shape = Enum.PartType.Ball })
		CollectionService:AddTag(light, "Blink")
	end
	-- radio masts
	for k = 1, 4 do
		local sd = SIDES[k]
		local p = sd.n * (OUT - 160) + sd.t * rng:NextNumber(-1500, 1500)
		if WestLayout.inCorridor(p, 120) then
			p += sd.t * 600
		end
		kit.mk(root, Vector3.new(4, 260, 4), CFrame.new(p + Vector3.new(0, 130, 0)), Color3.fromRGB(150, 60, 50), Enum.Material.Metal, { name = "Mast" })
		for y = 60, 260, 100 do
			local l = kit.deco(root, Vector3.one * 2.4, CFrame.new(p + Vector3.new(0, y, 0)), Color3.fromRGB(255, 25, 25), Enum.Material.Neon, { shape = Enum.PartType.Ball })
			CollectionService:AddTag(l, "Blink")
		end
	end
	-- the mountain range on the horizon: ridges, each two big rock slopes back to back (like a
	-- roof), in two rows of different heights
	for _, sd in SIDES do
		for row = 0, 1 do
			for t = -OUT - 600 + row * 190, OUT + 600, 380 do
				local p = sd.n * (OUT + 260 + row * 330 + rng:NextNumber(-60, 60)) + sd.t * t
				local hgt = rng:NextNumber(220, 420) * (1 + row * 0.6)
				local w = rng:NextNumber(420, 700)
				-- the coastal highway's canyon cuts through the west range (West builds its walls)
				if sd.n.X < -0.5 and math.abs(t) < Config.West.CorridorHalf + w / 2 + 60 then
					continue
				end
				local d = hgt * rng:NextNumber(1.1, 1.6)
				local cf = CFrame.lookAt(Vector3.new(p.X, hgt / 2 - 30, p.Z), Vector3.new(p.X, hgt / 2 - 30, p.Z) - sd.n) * CFrame.Angles(0, rng:NextNumber(-0.25, 0.25), 0)
				local rock = Color3.fromRGB(70, 70, 72):Lerp(Color3.fromRGB(96, 92, 88), rng:NextNumber())
				kit.mk(root, Vector3.new(w, hgt, d), cf * CFrame.new(0, 0, -d / 2), rock, Enum.Material.Slate, { class = "Wedge", name = "Range" })
				kit.mk(root, Vector3.new(w, hgt, d), cf * CFrame.new(0, 0, d / 2) * CFrame.Angles(0, math.pi, 0), rock, Enum.Material.Slate, { class = "Wedge", name = "Range" })
			end
		end
		-- the land under the far range
		local a, b = sd.n * (OUT + 450) - sd.t * (OUT + 1000), sd.n * (OUT + 450) + sd.t * (OUT + 1000)
		local lo, hi = a:Min(b) - Vector3.new(450, 0, 450) * Vector3.new(math.abs(sd.n.X), 0, math.abs(sd.n.Z)), a:Max(b) + Vector3.new(450, 0, 450) * Vector3.new(math.abs(sd.n.X), 0, math.abs(sd.n.Z))
		kit.slab(root, lo.X, lo.Z, hi.X, hi.Z, -0.4, 4, Color3.fromRGB(52, 70, 40), Enum.Material.Grass, { name = "Land" })
	end
	-- invisible walls round the outside of the land (nobody drives off the world)
	local o = OUT + 20
	local gap = Config.West.CorridorHalf -- the coastal highway leaves to the west here
	for _, wpart in { { -o, -o - 2, o, -o + 2 }, { -o, o - 2, o, o + 2 }, { -o - 2, -o, -o + 2, -gap }, { -o - 2, gap, -o + 2, o }, { o - 2, -o, o + 2, o } } do
		kit.slab(root, wpart[1], wpart[2], wpart[3], wpart[4], 400, 400, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Boundary" })
	end
end

---------------------------------------------------------------------
-- Neon billboards along the loop's outer edge, facing the oncoming traffic both ways
---------------------------------------------------------------------
local ADS = { "CITY LEGENDS", "NIGHT RUN", "VORTEX V10", "MIDNIGHT FM 98.7", "CUT UP\nGET PAID", "KAIZEN RZ", "ECLIPSE JX", "NEON NIGHTS", "PHANTOM W16", "LEGENDS LOOP\n8 KM" }
local function billboards(kit: any, parent: Instance)
	local root = kit.folder("LoopBillboards", parent)
	local L = CityLayout.loopLength()
	local s = 350
	local k = 0
	while s < L do
		k += 1
		local sgn = if k % 2 == 0 then 1 else -1
		local p, dir = CityLayout.loopSample(s, sgn * (HW + 40))
		-- (not at the spur's junction)
		if not (p.X > LOOP_S - 200 and math.abs(p.Z) < 300) and not WestLayout.inCorridor(p, 160) then
			local group = kit.lodGroup(root, `Board_{k}`, p, 1400)
			local face = if sgn > 0 then -dir else dir -- towards the traffic coming at it on that side
			local cf = CFrame.lookAt(p + Vector3.new(0, 34, 0), p + Vector3.new(0, 34, 0) + face)
			local board = kit.deco(group, Vector3.new(60, 22, 1.2), cf, Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic, { name = "Billboard" })
			local c1, c2 = kit.pick(kit.NEON_COLORS), kit.pick(kit.NEON_COLORS)
			local _, frame = kit.surfaceText(board, Enum.NormalId.Front, kit.pick(ADS), Color3.new(1, 1, 1), c1, 0, Enum.Font.GothamBlack, Vector2.new(900, 330))
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new(c1, c2)
			grad.Rotation = kit.rng:NextInteger(0, 90)
			grad.Parent = frame
			CollectionService:AddTag(grad, "AnimatedBoard")
			kit.deco(group, Vector3.new(61, 0.6, 0.6), cf * CFrame.new(0, -11.3, 0), c1, Enum.Material.Neon)
			for _, sx in { -18, 18 } do
				kit.mk(group, Vector3.new(1.6, 24, 1.6), cf * CFrame.new(sx, -23, 1.5), kit.METAL, Enum.Material.Metal)
			end
		end
		s += 700
	end
end

function Mainland.build(kit: any, city: Instance)
	local root = kit.folder("Mainland", city)
	shore(kit, root)
	suburbs(kit, root)
	port(kit, root)
	outer(kit, root)
	billboards(kit, root)
end

return Mainland
