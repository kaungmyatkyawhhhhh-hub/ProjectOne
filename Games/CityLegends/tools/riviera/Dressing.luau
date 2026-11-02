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
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1, wl = s[7] or HALF, wr = s[8] or HALF }
		end
		table.insert(out, { name = r.name, kind = r.kind, rank = r.rank, pts = pts })
	end
	return out
end

local function inBox(box, p: Vector3)
	return box == nil or (p.X >= box[1] and p.X <= box[3] and p.Z >= box[2] and p.Z <= box[4])
end

-- distance from p to the nearest other road's centre (any road but `self`). The road's own centre
-- counts too where it comes back past p (a hairpin's other leg), and a side of the road with no
-- pavement (narrowed where two roads run side by side: a wall stands there) counts as 0
local function nearestOther(roads, self, p: Vector3): number
	local best = math.huge
	local pv = Vector2.new(p.X, p.Z)
	for _, r in roads do
		if r ~= self then
			for i = 1, #r.pts, 2 do
				local q = r.pts[i].pos
				local d = (Vector2.new(q.X, q.Z) - pv).Magnitude
				if d < best then
					best = d
				end
			end
		end
	end
	if self then
		local j0, d0 = 1, math.huge
		for k, s in self.pts do
			local d = (Vector2.new(s.pos.X, s.pos.Z) - pv).Magnitude
			if d < d0 then
				j0, d0 = k, d
			end
		end
		local s0 = self.pts[j0]
		local right = Vector3.new(-s0.dir.Z, 0, s0.dir.X)
		local w = if (p - s0.pos):Dot(right) < 0 then s0.wl else s0.wr
		if w < HALF - 0.5 then
			return 0
		end
		for k = 1, #self.pts, 2 do
			if math.abs(k - j0) >= 8 then
				local q = self.pts[k].pos
				local d = (Vector2.new(q.X, q.Z) - pv).Magnitude
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
	light.Angle = 135
	light.Range = 72
	light.Brightness = 6
	light.Color = Color3.fromRGB(255, 166, 86)
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
-- the owner's tree (ServerStorage.RivieraAssets.Tree, from tree_low_poly_lowpoly.glb: two tree
-- meshes) is used for the harbour trees; the part-built umbrella pine is only the fallback
local treeMeshes: { MeshPart }? = nil
local function treeTemplates(): { MeshPart }
	if treeMeshes == nil then
		local list = {}
		local src = game:GetService("ServerStorage"):FindFirstChild("RivieraAssets")
		local t = src and src:FindFirstChild("Tree")
		if t then
			for _, d in t:GetDescendants() do
				if d:IsA("MeshPart") then
					table.insert(list, d)
				end
			end
		end
		treeMeshes = list
	end
	return treeMeshes :: { MeshPart }
end

local function pine(base: Vector3, rng: Random, parent: Instance)
	local m = Instance.new("Model")
	local templates = treeTemplates()
	if #templates > 0 then
		m.Name = "Tree"
		local mesh = templates[rng:NextInteger(1, #templates)]:Clone()
		local k = rng:NextNumber(30, 40) / mesh.Size.Y
		mesh.Size *= k
		mesh.CFrame = CFrame.new(base + Vector3.new(0, mesh.Size.Y / 2 - 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
		mesh.Anchored = true
		mesh.CanCollide = false
		mesh.CanQuery = false
		mesh.Name = "Crown"
		mesh.Parent = m
		-- an invisible trunk so cars still hit the tree
		part({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 2, 2), CFrame = CFrame.new(base + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.pi / 2), Transparency = 1, CastShadow = false }, m)
		m.Parent = parent
		return
	end
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

local lampCache: { [Instance]: { Vector3 } } = {}
local function lampSpots(parent: Instance): { Vector3 }
	if not lampCache[parent] then
		local list = {}
		for _, m in parent:GetChildren() do
			if m.Name == "StreetLamp" and m:FindFirstChild("Pole") then
				table.insert(list, (m :: any).Pole.Position)
			end
		end
		lampCache[parent] = list
	end
	return lampCache[parent]
end

function Dressing.harbour(data, box, parent: Instance, rng: Random): (number, number)
	lampCache[parent] = nil
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
				local spot = b.pos + right * side * (HALF + 2.6) + Vector3.new(0, 0.5, 0) -- at the kerb
				-- not on top of a street lamp (lamps are placed first): wait for the next sample
				local clash = false
				for _, lampPos in lampSpots(parent) do
					if Vector2.new(lampPos.X - spot.X, lampPos.Z - spot.Z).Magnitude < 10 then
						clash = true
						break
					end
				end
				if pineAcc > 46 and not clash then
					pineAcc = 0
					pine(spot, rng, parent)
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
-- Creator Store props (owner 2026-11-02: "take and insert from Toolbox, for more realism"):
-- ServerStorage.RivieraAssets.Props, cleaned of scripts; the part-built ones are the fallback
local function prop(name: string): Instance?
	local lib = game:GetService("ServerStorage"):FindFirstChild("RivieraAssets")
	local props = lib and lib:FindFirstChild("Props")
	return props and props:FindFirstChild(name)
end
-- a copy of a prop standing on cf (its bottom on cf's height, centred on cf), turned like cf
local function placeProp(name: string, cf: CFrame, scale: number?, parent: Instance): Instance?
	local src = prop(name)
	if not src then
		return nil
	end
	local m = src:Clone()
	if m:IsA("BasePart") then
		if scale then
			m.Size *= scale
		end
		m.CFrame = cf * CFrame.new(0, m.Size.Y / 2, 0)
	elseif m:IsA("Model") then
		if scale then
			m:ScaleTo(m:GetScale() * scale)
		end
		m:PivotTo(cf)
		local box, size = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(cf.Position.X - box.Position.X, cf.Position.Y - (box.Position.Y - size.Y / 2), cf.Position.Z - box.Position.Z))
	end
	m.Parent = parent
	return m
end

local function bollard(pos: Vector3, striped: boolean, parent: Instance)
	if not striped and placeProp("BollardBlack", CFrame.new(pos), nil, parent) then
		return
	end
	local col = if striped then Color3.fromRGB(196, 32, 36) else Color3.fromRGB(34, 36, 38)
	part({ Name = "Bollard", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 0.8, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = col, CastShadow = false }, parent)
	if striped then
		part({ Name = "Stripe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.84, 0.84), CFrame = CFrame.new(pos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 236), CastShadow = false }, parent)
	end
end

local function crossingSign(pos: Vector3, face: Vector3, parent: Instance)
	if placeProp("CrossingSign", CFrame.lookAt(pos, pos + face) * CFrame.Angles(0, math.pi / 2, 0), 0.6, parent) then
		return
	end
	part({ Name = "SignPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 0.4, 0.4), CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 152, 156), CastShadow = false }, parent)
	local cf = CFrame.lookAt(pos + Vector3.new(0, 9.2, 0), pos + Vector3.new(0, 9.2, 0) + face)
	part({ Name = "CrossingSign", Size = Vector3.new(2.6, 2.6, 0.15), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(28, 82, 168), CastShadow = false }, parent)
	part({ Name = "SignTriangle", Size = Vector3.new(1.7, 1.5, 0.05), CFrame = cf * CFrame.new(0, 0, -0.1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240), CastShadow = false }, parent)
end

local SCOOTER = { Color3.fromRGB(230, 230, 226), Color3.fromRGB(30, 30, 32), Color3.fromRGB(150, 30, 34), Color3.fromRGB(40, 70, 120), Color3.fromRGB(170, 172, 176) }
local function scooter(cf: CFrame, rng: Random, parent: Instance)
	local pick = if rng:NextNumber() < 0.55 then "ScooterClassic" else "ScooterModern"
	if placeProp(pick, cf * CFrame.Angles(0, if rng:NextNumber() < 0.5 then 0 else math.pi, 0) * CFrame.Angles(0, rng:NextNumber(-0.12, 0.12), 0), nil, parent) then
		return
	end
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

local function planter(pos: Vector3, rng: Random, parent: Instance, along: Vector3?)
	local dir = along or Vector3.new(1, 0, 0)
	local cf = CFrame.lookAt(pos, pos + dir)
	if rng:NextNumber() < 0.3 then
		if placeProp("PlanterStone", cf * CFrame.Angles(0, math.pi / 2, 0), 0.8, parent) then
			return
		end
	elseif placeProp("PlanterPot", cf * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), rng:NextNumber(1.1, 1.4), parent) then
		return
	end
	part({ Name = "Planter", Size = Vector3.new(5, 2.6, 5), CFrame = CFrame.new(pos + Vector3.new(0, 1.3, 0)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(122, 92, 64) }, parent)
	local green = Color3.fromRGB(64, 104, 52):Lerp(Color3.fromRGB(96, 130, 64), rng:NextNumber())
	part({ Name = "Shrub", Shape = Enum.PartType.Ball, Size = Vector3.new(5.6, 5.6, 5.6), CFrame = CFrame.new(pos + Vector3.new(0, 4.4, 0)), Material = Enum.Material.Grass, Color = green, CanCollide = false }, parent)
	if rng:NextNumber() < 0.4 then -- bougainvillea
		part({ Name = "Flowers", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-1, 1), 6, rng:NextNumber(-1, 1))), Material = Enum.Material.Grass, Color = Color3.fromRGB(206, 64, 140), CanCollide = false, CastShadow = false }, parent)
	end
end

local function busShelter(cf: CFrame, parent: Instance)
	if placeProp("BusShelter", cf, nil, parent) then
		return
	end
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
				-- street trees stand at the kerb, so their crowns stay clear of the buildings (owner
				-- 2026-11-02: "some of the trees are not in the correct place")
				local kerbSpot = b.pos + right * side * (HALF + 2.6) + Vector3.new(0, 0.5, 0)
				local palmA = prop("PalmA")
				if nearestOther(roads, r, spot) > HALF + WALK and palmA and (casino or r.name == "Beach Avenue" or r.name == "Coast Road") then
					-- a Creator Store palm (textured; the owner's import shows white): its trunk's foot
					-- (attribute TrunkFoot on the trunk mesh, in its own space) on the kerb spot
					local pm = palmA:Clone()
					pm:ScaleTo(pm:GetScale() * rng:NextNumber(0.62, 0.8))
					pm:PivotTo(CFrame.new(kerbSpot) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
					for _, d in pm:GetDescendants() do
						if d:IsA("BasePart") and d:GetAttribute("TrunkFoot") then
							local foot = (d.CFrame * CFrame.new((d:GetAttribute("TrunkFoot") :: Vector3) * d.Size)).Position
							pm:PivotTo(pm:GetPivot() + (kerbSpot - Vector3.new(0, 0.3, 0) - foot))
							break
						end
					end
					pm.Name = "Palm"
					pm.Parent = grp(kerbSpot)
					n.palms += 1
				elseif nearestOther(roads, r, spot) > HALF + WALK then
					if palms and (casino or r.name == "Beach Avenue" or r.name == "Coast Road") then
						-- one palm of the imported group (the group is 60 studs wide: whole, it stood
						-- on the road, owner 2026-11-02 "why is there trees on the road")
						local meshes = {}
						for _, d in palms:GetDescendants() do
							if d:IsA("MeshPart") then
								table.insert(meshes, d)
							end
						end
						local mesh = meshes[rng:NextInteger(1, #meshes)]:Clone()
						mesh.Size *= rng:NextNumber(30, 40) / mesh.Size.Y
						-- the trunk's foot on the spot (palms lean: attribute TrunkBase, the foot's place in
						-- the mesh box as fractions, measured from the mesh's vertices)
						local foot = mesh:GetAttribute("TrunkBase") or Vector3.new(0, -0.5, 0)
						mesh.CFrame = CFrame.new(spot - Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0) * CFrame.new(-foot * mesh.Size)
						mesh.Anchored = true
						mesh.CanCollide = false
						mesh.CanQuery = false
						mesh.Name = "Palm"
						local pm = Instance.new("Model")
						pm.Name = "Palm"
						mesh.Parent = pm
						pm.Parent = grp(spot)
						n.palms += 1
					else
						planter(spot, rng, grp(spot), b.dir)
						n.planters += 1
						-- now and then a bench beside it, facing the street
						if rng:NextNumber() < 0.35 then
							local at = spot + b.dir.Unit * 7
							if placeProp("Bench", CFrame.lookAt(at, at + b.dir), nil, grp(at)) then
								n.benches = (n.benches or 0) + 1
							end
						end
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

-- trees whose crown runs into a building, or whose trunk stands on a lamp, sign or bus shelter, go
-- (run last, when the buildings and the furniture are in)
function Dressing.fitTrees(parent: Instance, buildings: Instance): number
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { buildings }
	local clutter = {}
	for _, m in parent:GetDescendants() do
		if m:IsA("Model") and (m.Name == "StreetLamp" or m.Name == "BusShelter" or m.Name == "CrossingSign") then
			table.insert(clutter, m)
		end
	end
	local op2 = OverlapParams.new()
	op2.FilterType = Enum.RaycastFilterType.Include
	op2.FilterDescendantsInstances = clutter
	local removed = 0
	local trees = {}
	for _, m in parent:GetDescendants() do
		if m:IsA("Model") and (m.Name == "Tree" or m.Name == "Palm") then
			table.insert(trees, m)
		end
	end
	for _, m in trees do
		local box, size = m:GetBoundingBox()
		local crown = workspace:GetPartBoundsInBox(box * CFrame.new(0, size.Y * 0.2, 0), Vector3.new(size.X * 0.6, size.Y * 0.5, size.Z * 0.6), op)
		local base = Vector3.new(box.Position.X, box.Position.Y - size.Y / 2, box.Position.Z)
		local trunk = workspace:GetPartBoundsInBox(CFrame.new(base + Vector3.new(0, 4, 0)), Vector3.new(5, 8, 5), op2)
		if #crown > 0 or #trunk > 0 then
			m:Destroy()
			removed += 1
		end
	end
	return removed
end

return Dressing
