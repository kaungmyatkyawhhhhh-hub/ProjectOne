--[[
	Riviera street dressing (Studio, Edit mode), from build/riviera/roads.json, after Roads.build:
	  * street lamps: dark grey curved single-arm poles both sides (warm sodium heads at night:
	    tag LampGlow, SpotLight tagged LODLight + DayOff + ShadowLight, so WorldFx runs them)
	  * the harbour side of the Coast Road: a white stone balustrade and umbrella pines
	  * the coast tunnel: concrete ceiling, round white pillars open to the sea, rows of sodium lights
	Owner's reference: the morning drive video (harbour road with pines 7:02-7:25, tunnel 7:58-8:12).
	Details are grouped in models tagged LOD (Center / Range attributes) so far ones are hidden.
]]

local CollectionService = game:GetService("CollectionService")

local Dressing = {}

local HALF, WALK = 32, 10
local POLE = Color3.fromRGB(58, 60, 64)
local SODIUM = Color3.fromRGB(255, 176, 92)
local STONE = Color3.fromRGB(226, 222, 210)
local BARK = Color3.fromRGB(104, 82, 64)
local PINE = Color3.fromRGB(58, 80, 46)

local function part(props, parent): BasePart
	local p = Instance.new(props.Shape and "Part" or (props.Class or "Part"))
	props.Class = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function lodGroup(name: string, center: Vector3, range: number, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Center", center)
	m:SetAttribute("Range", range)
	CollectionService:AddTag(m, "LOD")
	m.Parent = parent
	return m
end

local function roadsIn(data, box)
	local out = {}
	for _, r in data.roads do
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1 }
		end
		table.insert(out, { name = r.name, kind = r.kind, rank = r.rank, pts = pts })
	end
	return out
end

local function inBox(box, p: Vector3)
	return box == nil or (p.X >= box[1] and p.X <= box[3] and p.Z >= box[2] and p.Z <= box[4])
end

-- distance from p to the nearest other road's centre (any road but `self`)
local function nearestOther(roads, self, p: Vector3): number
	local best = math.huge
	for _, r in roads do
		if r ~= self then
			for i = 1, #r.pts, 2 do
				local q = r.pts[i].pos
				local d = (Vector2.new(q.X, q.Z) - Vector2.new(p.X, p.Z)).Magnitude
				if d < best then
					best = d
				end
			end
		end
	end
	return best
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }
params.IgnoreWater = false

-- is there sea (water) beside the road at p?
local function seaAt(p: Vector3): boolean
	local hit = workspace:Raycast(Vector3.new(p.X, 200, p.Z), Vector3.new(0, -400, 0), params)
	return hit ~= nil and hit.Material == Enum.Material.Water
end

---------------------------------------------------------------------
-- street lamps
---------------------------------------------------------------------
local function lamp(base: Vector3, toRoad: Vector3, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "StreetLamp"
	local h = 26
	part({ Name = "Pole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.9, 0.9), CFrame = CFrame.new(base + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = POLE, CastShadow = false }, m)
	part({ Name = "Foot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.5, 1.5), CFrame = CFrame.new(base + Vector3.new(0, 0.8, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = POLE, CastShadow = false }, m)
	-- the curved arm: two pieces bending out over the road
	local top = base + Vector3.new(0, h, 0)
	local mid = top + toRoad * 3 + Vector3.new(0, 1.6, 0)
	local tip = top + toRoad * 7.5 + Vector3.new(0, 1.2, 0)
	for _, seg in { { top, mid }, { mid, tip } } do
		local a, b = seg[1], seg[2]
		part({ Name = "Arm", Size = Vector3.new(0.5, 0.5, (b - a).Magnitude + 0.3), CFrame = CFrame.lookAt((a + b) / 2, b), Material = Enum.Material.Metal, Color = POLE, CastShadow = false }, m)
	end
	local head = part({ Name = "Head", Size = Vector3.new(1.4, 0.5, 3.2), CFrame = CFrame.lookAt(tip + toRoad * 1.2 - Vector3.new(0, 0.35, 0), tip + toRoad * 3 - Vector3.new(0, 0.35, 0)), Material = Enum.Material.Neon, Color = SODIUM, CastShadow = false }, m)
	CollectionService:AddTag(head, "LampGlow")
	local cap = part({ Name = "Cap", Size = Vector3.new(1.7, 0.4, 3.6), CFrame = head.CFrame * CFrame.new(0, 0.42, 0), Material = Enum.Material.Metal, Color = POLE, CastShadow = false }, m)
	cap.CanCollide = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 120
	light.Range = 48
	light.Brightness = 2.4
	light.Color = Color3.fromRGB(255, 178, 104)
	light.Shadows = false
	light.Parent = head
	CollectionService:AddTag(light, "LODLight")
	CollectionService:AddTag(light, "DayOff")
	CollectionService:AddTag(light, "ShadowLight")
	m.Parent = parent
end

function Dressing.lamps(data, box, parent: Instance): number
	local roads = roadsIn(data, box)
	local n = 0
	for _, r in roads do
		local town = r.kind == "street" or r.name == "Town Road" or r.name == "Coast Road"
		local acc, side = 0, 1
		for i = 2, #r.pts do
			local a, b = r.pts[i - 1], r.pts[i]
			acc += (b.pos - a.pos).Magnitude
			if acc >= 64 and inBox(box, b.pos) and not b.tunnel then
				acc = 0
				side = -side -- staggered: one side then the other
				local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
				local base = b.pos + right * side * (HALF + (if town then WALK - 1.6 else 4)) + Vector3.new(0, if town then 0.5 else 0, 0)
				if nearestOther(roads, r, base) > HALF + 4 then
					lamp(base, -right * side, parent)
					n += 1
				end
			end
			if i % 60 == 0 then
				task.wait()
			end
		end
	end
	return n
end

---------------------------------------------------------------------
-- harbour balustrade and umbrella pines
---------------------------------------------------------------------
local function pine(base: Vector3, rng: Random, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "UmbrellaPine"
	local lean = CFrame.Angles(rng:NextNumber(-0.18, 0.18), rng:NextNumber(0, math.pi * 2), rng:NextNumber(-0.18, 0.18))
	local h = rng:NextNumber(30, 40)
	local trunkCF = CFrame.new(base) * lean
	part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.2, 2.2), CFrame = trunkCF * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Wood, Color = BARK }, m)
	local top = (trunkCF * CFrame.new(0, h, 0)).Position
	-- a few forking branches and a wide flat crown of overlapping clumps
	for k = 1, 3 do
		local ang = k * 2.1 + rng:NextNumber(-0.3, 0.3)
		local tip = top + Vector3.new(math.cos(ang) * 7, rng:NextNumber(1, 3), math.sin(ang) * 7)
		local from = top - Vector3.new(0, 4, 0)
		part({ Name = "Branch", Size = Vector3.new(1, 1, (tip - from).Magnitude), CFrame = CFrame.lookAt((from + tip) / 2, tip), Material = Enum.Material.Wood, Color = BARK, CastShadow = false }, m)
	end
	for k = 1, 7 do
		-- flat discs of foliage: the umbrella top
		local ang = rng:NextNumber(0, math.pi * 2)
		local rad = if k == 1 then 0 else rng:NextNumber(5, 11)
		local c = top + Vector3.new(math.cos(ang) * rad, rng:NextNumber(1.5, 4), math.sin(ang) * rad)
		local d = rng:NextNumber(16, 24)
		part({ Name = "Crown", Shape = Enum.PartType.Cylinder, Size = Vector3.new(rng:NextNumber(4.5, 6.5), d, d), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Grass, Color = PINE:Lerp(Color3.fromRGB(74, 98, 56), rng:NextNumber()), CanCollide = false }, m)
	end
	m.Parent = parent
end

function Dressing.harbour(data, box, parent: Instance, rng: Random): (number, number)
	local roads = roadsIn(data, box)
	local balusters, pines = 0, 0
	for _, r in roads do
		if r.name ~= "Coast Road" then
			continue
		end
		local group: Model? = nil
		local acc, pineAcc = 0, 0
		for i = 2, #r.pts do
			local a, b = r.pts[i - 1], r.pts[i]
			if not inBox(box, b.pos) or b.tunnel then
				continue
			end
			local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
			for _, side in { -1, 1 } do
				local edge = HALF + WALK - 0.6
				local wet = false
				for dist = 30, 180, 30 do
					if seaAt(b.pos + right * side * (HALF + WALK + dist)) then
						wet = true
						break
					end
				end
				if not wet then
					continue
				end
				if nearestOther(roads, r, b.pos + right * side * edge) < HALF + WALK + 6 then
					continue
				end
				if group == nil or (group:GetAttribute("Center") - b.pos).Magnitude > 200 then
					group = lodGroup("Balustrade", b.pos, 700, parent)
				end
				-- rails along this stretch
				local pa = a.pos + Vector3.new(-a.dir.Z, 0, a.dir.X).Unit * side * edge
				local pb = b.pos + right * side * edge
				local len = (pb - pa).Magnitude
				local base = (pa + pb) / 2 + Vector3.new(0, 0.5, 0)
				local cf = CFrame.lookAt(base, base + (pb - pa))
				part({ Name = "Plinth", Size = Vector3.new(1.4, 1, len + 0.2), CFrame = cf * CFrame.new(0, 0.5, 0), Material = Enum.Material.Limestone, Color = STONE }, group :: Model)
				part({ Name = "Rail", Size = Vector3.new(1.3, 0.7, len + 0.2), CFrame = cf * CFrame.new(0, 3.75, 0), Material = Enum.Material.Limestone, Color = STONE }, group :: Model)
				local count = math.max(1, math.floor(len / 1.6))
				for k = 0, count - 1 do
					local p = cf * CFrame.new(0, 2.2, -len / 2 + (k + 0.5) * len / count)
					part({ Name = "Baluster", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 0.75, 0.75), CFrame = p * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Limestone, Color = STONE, CastShadow = false }, group :: Model)
					balusters += 1
				end
				-- umbrella pines on the harbour side every ~46 studs, in the pavement's outer edge
				pineAcc += (b.pos - a.pos).Magnitude
				if pineAcc > 46 then
					pineAcc = 0
					pine(b.pos + right * side * (HALF + WALK - 4) + Vector3.new(0, 0.5, 0), rng, parent)
					pines += 1
				end
			end
			acc += 1
			if acc % 30 == 0 then
				task.wait()
			end
		end
	end
	return balusters, pines
end

---------------------------------------------------------------------
-- retaining walls: where the hill behind a town pavement stands higher than the road (cream stone
-- blocks, as all over the video), unless a building already stands there
---------------------------------------------------------------------
function Dressing.walls(data, box, parent: Instance, keepOut: Instance?): number
	local roads = roadsIn(data, box)
	local n = 0
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = if keepOut then { keepOut } else {}
	local group: Model? = nil
	for _, r in roads do
		local town = r.kind == "street" or r.name == "Town Road" or r.name == "Coast Road"
		if not town then
			continue
		end
		for i = 2, #r.pts do
			local a, b = r.pts[i - 1], r.pts[i]
			if not inBox(box, b.pos) or b.tunnel then
				continue
			end
			local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
			for _, side in { -1, 1 } do
				local back = b.pos + right * side * (HALF + WALK + 4)
				local hit = workspace:Raycast(Vector3.new(back.X, b.pos.Y + 80, back.Z), Vector3.new(0, -100, 0), params)
				if not hit or hit.Position.Y < b.pos.Y + 2.5 or hit.Material == Enum.Material.Water then
					continue
				end
				if nearestOther(roads, r, b.pos + right * side * (HALF + WALK)) < HALF + WALK + 8 then
					continue
				end
				local top = math.min(hit.Position.Y + 1.5, b.pos.Y + 40)
				local pa = a.pos + Vector3.new(-a.dir.Z, 0, a.dir.X).Unit * side * (HALF + WALK + 1.2)
				local pb = b.pos + right * side * (HALF + WALK + 1.2)
				local len = (Vector2.new(pb.X - pa.X, pb.Z - pa.Z)).Magnitude + 0.8
				local bottom = math.min(pa.Y, pb.Y) - 2
				local h = top - bottom
				local mid = Vector3.new((pa.X + pb.X) / 2, bottom + h / 2, (pa.Z + pb.Z) / 2)
				local cf = CFrame.lookAt(mid, mid + Vector3.new(pb.X - pa.X, 0, pb.Z - pa.Z))
				if keepOut and #workspace:GetPartBoundsInBox(cf, Vector3.new(2.4, h, len), overlap) > 0 then
					continue
				end
				if group == nil or (group:GetAttribute("Center") - mid).Magnitude > 250 then
					group = lodGroup("Walls", mid, 1400, parent)
				end
				part({ Name = "RetainingWall", Size = Vector3.new(2.4, h, len), CFrame = cf, Material = Enum.Material.Sandstone, Color = Color3.fromRGB(222, 206, 172) }, group :: Model)
				part({ Name = "WallCap", Size = Vector3.new(3, 0.8, len), CFrame = cf * CFrame.new(0, h / 2 + 0.4, 0), Material = Enum.Material.Limestone, Color = Color3.fromRGB(232, 224, 204), CastShadow = false }, group :: Model)
				n += 1
			end
			if i % 50 == 0 then
				task.wait()
			end
		end
	end
	return n
end

---------------------------------------------------------------------
-- the coast tunnel: the land side a wall, the sea side round white pillars
---------------------------------------------------------------------
function Dressing.tunnel(data, parent: Instance): number
	local roads = roadsIn(data, nil)
	local n = 0
	for _, r in roads do
		local group: Model? = nil
		local acc = 0
		for i = 2, #r.pts do
			local a, b = r.pts[i - 1], r.pts[i]
			if not (a.tunnel and b.tunnel) then
				continue
			end
			if group == nil or (group:GetAttribute("Center") - b.pos).Magnitude > 220 then
				group = lodGroup("Tunnel", b.pos, 900, parent)
			end
			local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
			-- the sea is on the side facing +Z (south) along the coast
			local sea = if right.Z > 0 then 1 else -1
			local mid = (a.pos + b.pos) / 2
			local len = (b.pos - a.pos).Magnitude + 1.2
			local cf = CFrame.lookAt(mid, mid + (b.pos - a.pos))
			local W = HALF + WALK
			-- ceiling and the land-side wall (cream-yellow lower half)
			part({ Name = "Ceiling", Size = Vector3.new(W * 2 + 6, 3, len), CFrame = cf * CFrame.new(0, 27.5, 0), Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 146, 136) }, group :: Model)
			part({ Name = "Wall", Size = Vector3.new(2, 14, len), CFrame = cf * CFrame.new(-sea * (W + 1), 7, 0), Material = Enum.Material.Plaster, Color = Color3.fromRGB(236, 198, 112) }, group :: Model)
			part({ Name = "WallUpper", Size = Vector3.new(2, 13, len), CFrame = cf * CFrame.new(-sea * (W + 1), 20.5, 0), Material = Enum.Material.Concrete, Color = Color3.fromRGB(160, 156, 146) }, group :: Model)
			-- raised walkways both sides (the tunnel has no pavements of its own)
			for _, sd in { -1, 1 } do
				part({ Name = "Walkway", Size = Vector3.new(W - HALF, 6, len), CFrame = cf * CFrame.new(sd * (HALF + (W - HALF) / 2), 0.5 - 3, 0), Material = Enum.Material.Concrete, Color = Color3.fromRGB(176, 172, 162) }, group :: Model)
			end
			workspace.Terrain:FillBlock(cf * CFrame.new(0, 14, 0), Vector3.new(W * 2, 26, len + 2), Enum.Material.Air)
			-- low wall + pillars on the sea side
			part({ Name = "SeaKerbWall", Size = Vector3.new(2, 3.4, len), CFrame = cf * CFrame.new(sea * (W + 1), 1.7, 0), Material = Enum.Material.Concrete, Color = Color3.fromRGB(214, 210, 200) }, group :: Model)
			acc += (b.pos - a.pos).Magnitude
			if acc > 26 then
				acc = 0
				local p = cf * CFrame.new(sea * (W + 2.5), 13.5, 0)
				part({ Name = "Pillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 6, 6), CFrame = p * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Concrete, Color = Color3.fromRGB(232, 230, 222) }, group :: Model)
				-- two rows of sodium lights in the ceiling (lit day and night)
				for _, x in { -18, 18 } do
					local l = part({ Name = "TunnelLight", Size = Vector3.new(1.4, 0.4, 2.6), CFrame = cf * CFrame.new(x, 25.8, 0), Material = Enum.Material.Neon, Color = SODIUM, CastShadow = false, CanCollide = false }, group :: Model)
					if x > 0 then
						local pl = Instance.new("PointLight")
						pl.Range = 40
						pl.Brightness = 1.6
						pl.Color = Color3.fromRGB(255, 170, 90)
						pl.Parent = l
						CollectionService:AddTag(pl, "LODLight")
					end
				end
				n += 1
			end
			-- open the terrain on the sea side so the pillars look out over the water
			workspace.Terrain:FillBlock(cf * CFrame.new(sea * (W + 34), 16, 0), Vector3.new(60, 30, len + 2), Enum.Material.Air)
		end
	end
	return n
end

---------------------------------------------------------------------
-- street furniture (video: bollards, blue crossing signs, scooters parked in rows, planters,
-- palms, bus shelters)
---------------------------------------------------------------------
local function bollard(pos: Vector3, striped: boolean, parent: Instance)
	local col = if striped then Color3.fromRGB(196, 32, 36) else Color3.fromRGB(34, 36, 38)
	part({ Name = "Bollard", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 0.8, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = col, CastShadow = false }, parent)
	if striped then
		part({ Name = "Stripe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.84, 0.84), CFrame = CFrame.new(pos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 236), CastShadow = false }, parent)
	end
end

local function crossingSign(pos: Vector3, face: Vector3, parent: Instance)
	part({ Name = "SignPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 0.4, 0.4), CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 152, 156), CastShadow = false }, parent)
	local cf = CFrame.lookAt(pos + Vector3.new(0, 9.2, 0), pos + Vector3.new(0, 9.2, 0) + face)
	part({ Name = "CrossingSign", Size = Vector3.new(2.6, 2.6, 0.15), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(28, 82, 168), CastShadow = false }, parent)
	part({ Name = "SignTriangle", Size = Vector3.new(1.7, 1.5, 0.05), CFrame = cf * CFrame.new(0, 0, -0.1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240), CastShadow = false }, parent)
end

local SCOOTER = { Color3.fromRGB(230, 230, 226), Color3.fromRGB(30, 30, 32), Color3.fromRGB(150, 30, 34), Color3.fromRGB(40, 70, 120), Color3.fromRGB(170, 172, 176) }
local function scooter(cf: CFrame, rng: Random, parent: Instance)
	local col = SCOOTER[rng:NextInteger(1, #SCOOTER)]
	local m = Instance.new("Model")
	m.Name = "Scooter"
	for _, z in { -2.1, 2.1 } do
		part({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 1.9, 1.9), CFrame = cf * CFrame.new(0, 0.95, z), Material = Enum.Material.Rubber, Color = Color3.fromRGB(24, 24, 24), CastShadow = false }, m)
	end
	part({ Name = "Floor", Size = Vector3.new(1.2, 0.5, 2.6), CFrame = cf * CFrame.new(0, 1.3, 0), Material = Enum.Material.SmoothPlastic, Color = col, CastShadow = false }, m)
	part({ Name = "Rear", Size = Vector3.new(1.4, 1.5, 2.2), CFrame = cf * CFrame.new(0, 2, 1.4), Material = Enum.Material.SmoothPlastic, Color = col, CastShadow = false }, m)
	part({ Name = "Seat", Size = Vector3.new(1.2, 0.35, 2.2), CFrame = cf * CFrame.new(0, 2.9, 1.3), Material = Enum.Material.Leather, Color = Color3.fromRGB(26, 26, 26), CastShadow = false }, m)
	part({ Name = "Front", Size = Vector3.new(1.2, 3, 0.6), CFrame = cf * CFrame.new(0, 2.6, -2) * CFrame.Angles(-0.25, 0, 0), Material = Enum.Material.SmoothPlastic, Color = col, CastShadow = false }, m)
	part({ Name = "Bars", Size = Vector3.new(2.2, 0.25, 0.25), CFrame = cf * CFrame.new(0, 4.1, -2.35), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 42), CastShadow = false }, m)
	m.Parent = parent
end

local function planter(pos: Vector3, rng: Random, parent: Instance)
	part({ Name = "Planter", Size = Vector3.new(5, 2.6, 5), CFrame = CFrame.new(pos + Vector3.new(0, 1.3, 0)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(122, 92, 64) }, parent)
	local green = Color3.fromRGB(64, 104, 52):Lerp(Color3.fromRGB(96, 130, 64), rng:NextNumber())
	part({ Name = "Shrub", Shape = Enum.PartType.Ball, Size = Vector3.new(5.6, 5.6, 5.6), CFrame = CFrame.new(pos + Vector3.new(0, 4.4, 0)), Material = Enum.Material.Grass, Color = green, CanCollide = false }, parent)
	if rng:NextNumber() < 0.4 then -- bougainvillea
		part({ Name = "Flowers", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), 6, rng:NextNumber(-1, 1))), Material = Enum.Material.Grass, Color = Color3.fromRGB(206, 64, 140), CanCollide = false, CastShadow = false }, parent)
	end
end

local function busShelter(cf: CFrame, parent: Instance)
	local m = Instance.new("Model")
	m.Name = "BusShelter"
	part({ Name = "Roof", Size = Vector3.new(4.5, 0.4, 14), CFrame = cf * CFrame.new(0, 9, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 72, 76) }, m)
	part({ Name = "Back", Size = Vector3.new(0.3, 8, 13), CFrame = cf * CFrame.new(2, 4.6, 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 210, 220), Transparency = 0.55 }, m)
	local ad = part({ Name = "AdPanel", Size = Vector3.new(0.6, 7, 4), CFrame = cf * CFrame.new(0, 4.4, 6.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(250, 236, 210) }, m)
	ad.CastShadow = false
	part({ Name = "Bench", Size = Vector3.new(1.4, 0.4, 9), CFrame = cf * CFrame.new(1, 2, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 90, 60) }, m)
	for _, z in { -6.5, 6.5 } do
		part({ Name = "Post", Size = Vector3.new(0.4, 9, 0.4), CFrame = cf * CFrame.new(2, 4.5, z), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 72, 76) }, m)
	end
	m.Parent = parent
end

function Dressing.furniture(data, box, parent: Instance, rng: Random, palms: Model?): { [string]: number }
	local roads = roadsIn(data, box)
	local n = { bollards = 0, signs = 0, scooters = 0, planters = 0, palms = 0, shelters = 0 }
	local group: Model? = nil
	local function grp(at: Vector3): Model
		if group == nil or (group:GetAttribute("Center") - at).Magnitude > 220 then
			group = lodGroup("Furniture", at, 600, parent)
		end
		return group :: Model
	end
	for _, r in roads do
		local town = r.kind == "street" or r.name == "Town Road" or r.name == "Coast Road"
		if not town then
			continue
		end
		local inJ = {}
		for i, p in r.pts do
			inJ[i] = nearestOther(roads, r, p.pos) < HALF + 6
		end
		local acc, palmAcc, shelterAcc = 0, 0, 0
		local scooterRun = 0
		local casino = string.find(r.name, "Casino") ~= nil
		for i = 2, #r.pts do
			local a, b = r.pts[i - 1], r.pts[i]
			if not inBox(box, b.pos) or b.tunnel then
				continue
			end
			local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
			local step = (b.pos - a.pos).Magnitude
			acc += step
			palmAcc += step
			shelterAcc += step
			-- at a junction approach: red-white bollards on the corners and a blue crossing sign
			local leaving = inJ[i - 1] and not inJ[i]
			local arriving = i < #r.pts and inJ[i + 1] and not inJ[i]
			if leaving or arriving then
				for _, side in { -1, 1 } do
					local kerb = b.pos + right * side * (HALF + 1.5) + Vector3.new(0, 0.5, 0)
					if nearestOther(roads, r, kerb) > HALF + 3 then
						for k = 0, 2 do
							bollard(kerb + b.dir * (k * 3 - 3), true, grp(kerb))
							n.bollards += 1
						end
						crossingSign(b.pos + right * side * (HALF + 3.5) + Vector3.new(0, 0.5, 0), -b.dir, grp(kerb))
						n.signs += 1
					end
				end
			end
			if inJ[i] then
				continue
			end
			local seaRight = seaAt(b.pos + right * (HALF + WALK + 60))
			-- black bollards along the kerb in the casino quarter
			if casino and acc > 9 then
				acc = 0
				for _, side in { -1, 1 } do
					bollard(b.pos + right * side * (HALF + 1.4) + Vector3.new(0, 0.5, 0), false, grp(b.pos))
					n.bollards += 1
				end
			end
			-- scooters parked in a row against the kerb (a few runs per street)
			if scooterRun > 0 then
				scooterRun -= 1
				local side = if seaRight then -1 else 1
				local base = b.pos + right * side * (HALF + 3) + Vector3.new(0, 0.5, 0)
				for k = 0, 1 do
					local p = base + b.dir * (k * 3.2)
					scooter(CFrame.lookAt(p, p - right * side), rng, grp(p))
					n.scooters += 1
				end
			elseif r.kind == "street" and rng:NextNumber() < 0.025 then
				scooterRun = rng:NextInteger(3, 6)
			end
			-- planters and palms on the pavements' outer edge, alternating sides
			if palmAcc > 52 then
				palmAcc = 0
				local side = if rng:NextNumber() < 0.5 then 1 else -1
				if seaAt(b.pos + right * side * (HALF + WALK + 60)) then
					side = -side
				end
				local spot = b.pos + right * side * (HALF + WALK - 3) + Vector3.new(0, 0.5, 0)
				if nearestOther(roads, r, spot) > HALF + WALK then
					if palms and (casino or r.name == "Beach Avenue" or r.name == "Coast Road") then
						local pm = palms:Clone()
						pm:ScaleTo(pm:GetScale() * rng:NextNumber(1.1, 1.5))
						local cf, size = pm:GetBoundingBox()
						pm:PivotTo(pm:GetPivot() + (spot - Vector3.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)))
						pm:PivotTo(pm:GetPivot() * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
						for _, d in pm:GetDescendants() do
							if d:IsA("BasePart") then
								d.CanCollide = false
							end
						end
						pm.Parent = grp(spot)
						n.palms += 1
					else
						planter(spot, rng, grp(spot))
						n.planters += 1
					end
				end
			end
			-- a bus shelter now and then on the Coast and Town roads
			if (r.name == "Coast Road" or r.name == "Town Road") and shelterAcc > 420 then
				shelterAcc = 0
				local side = if seaRight then -1 else 1
				local spot = b.pos + right * side * (HALF + WALK - 3) + Vector3.new(0, 0.5, 0)
				if nearestOther(roads, r, spot) > HALF + WALK + 10 then
					busShelter(CFrame.lookAt(spot, spot + b.dir) * CFrame.Angles(0, if side > 0 then 0 else math.pi, 0), grp(spot))
					n.shelters += 1
				end
			end
			if i % 40 == 0 then
				task.wait()
			end
		end
	end
	return n
end

return Dressing
