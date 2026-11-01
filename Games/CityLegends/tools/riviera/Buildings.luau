--[[
	Riviera buildings (Studio, Edit mode), placed along the streets of build/riviera/roads.json.
	Two kinds from the owner's Monaco drive video:
	  * "Apartment": the 1970s-80s blocks (the most common, 0:20-2:10, 6:20-6:50): 9-17 storeys of
	    tan / ochre / beige concrete with long balconies stacked all the way up, glass bands behind
	  * "BelleEpoque": old Monaco (3:00-5:45): 5-7 storeys in cream, ochre, honey, peach, salmon or
	    pink, stone surrounds, shutters, black iron balconies, cornice and a slate mansard roof,
	    shops with awnings on the ground floor
	Each building stands with its front on the pavement's back edge, its base down to the lowest
	ground under it. Window and balcony detail sits in a "Detail" model tagged LOD (hidden far away);
	the body stays as the far silhouette. Window glass is tagged "Window" (lit at night later).

	Buildings.build(data, box, parent, rng, opts) -> count
	opts.style = function(position) -> chance of Belle Epoque (0..1)
]]

local CollectionService = game:GetService("CollectionService")

local Buildings = {}

local HALF, WALK = 32, 10
local FRONT = HALF + WALK + 1 -- road centre to building front

local BELLE = {
	Color3.fromRGB(236, 222, 190), -- cream
	Color3.fromRGB(222, 182, 112), -- ochre
	Color3.fromRGB(232, 200, 132), -- honey
	Color3.fromRGB(238, 196, 164), -- peach
	Color3.fromRGB(226, 158, 132), -- salmon
	Color3.fromRGB(234, 184, 176), -- pink
	Color3.fromRGB(240, 232, 214), -- off-white
}
local APART = {
	Color3.fromRGB(212, 188, 148), -- tan
	Color3.fromRGB(222, 198, 156),
	Color3.fromRGB(204, 170, 120), -- ochre concrete
	Color3.fromRGB(226, 214, 190), -- beige
	Color3.fromRGB(236, 230, 218), -- white-ish
}
local SHUTTER = { Color3.fromRGB(110, 128, 112), Color3.fromRGB(236, 234, 226), Color3.fromRGB(120, 92, 70), Color3.fromRGB(96, 116, 120) }
local AWNING = { Color3.fromRGB(160, 34, 36), Color3.fromRGB(40, 70, 52), Color3.fromRGB(30, 44, 74), Color3.fromRGB(196, 120, 40), Color3.fromRGB(150, 30, 30) }
local GLASS = Color3.fromRGB(44, 52, 58)
local STONE = Color3.fromRGB(232, 226, 210)
local IRON = Color3.fromRGB(26, 26, 28)
local SLATE = Color3.fromRGB(78, 84, 92)

local function part(props, parent): BasePart
	local p = Instance.new(props.Class or "Part")
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

local function detail(p: BasePart)
	p.CastShadow = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

local function window(cf: CFrame, w: number, h: number, parent: Instance)
	local g = part({ Name = "Glass", Size = Vector3.new(w, h, 0.3), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = GLASS, Reflectance = 0.05 }, parent)
	detail(g)
	CollectionService:AddTag(g, "Window")
	return g
end

---------------------------------------------------------------------
-- 1970s-80s apartment block: front faces -Z of `cf` (cf at the middle of the front, ground level)
---------------------------------------------------------------------
local function apartment(cf: CFrame, W: number, D: number, base: number, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "Apartment"
	local floors = rng:NextInteger(9, 17)
	local FH = 9
	local H = 12 + floors * FH
	local col = APART[rng:NextInteger(1, #APART)]
	local bodyCF = cf * CFrame.new(0, (H - base) / 2, D / 2)
	part({ Name = "Body", Size = Vector3.new(W, H + base, D), CFrame = cf * CFrame.new(0, H / 2 - base / 2, D / 2), Material = Enum.Material.Plaster, Color = col }, m)
	local det = Instance.new("Model")
	det.Name = "Detail"
	-- ground floor: shopfront glass band and an awning
	window(cf * CFrame.new(0, 5.5, -0.1), W - 4, 8, det)
	local aw = AWNING[rng:NextInteger(1, #AWNING)]
	local a = part({ Class = "WedgePart", Name = "Awning", Size = Vector3.new(W - 6, 1.6, 4), CFrame = cf * CFrame.new(0, 10.6, -2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = aw }, det)
	detail(a)
	-- each storey: a balcony slab across the front, its railing, the glass band behind
	local railCol = if rng:NextNumber() < 0.5 then Color3.fromRGB(240, 240, 236) else Color3.fromRGB(70, 74, 78)
	for f = 1, floors do
		local y = 12 + (f - 1) * FH
		local slab = part({ Name = "Balcony", Size = Vector3.new(W + 1, 0.9, 4.5), CFrame = cf * CFrame.new(0, y, -2.2), Material = Enum.Material.Concrete, Color = col:Lerp(Color3.new(1, 1, 1), 0.25) }, det)
		slab.CastShadow = true
		slab.CanCollide = false
		local rail = part({ Name = "Rail", Size = Vector3.new(W + 1, 3, 0.35), CFrame = cf * CFrame.new(0, y + 1.95, -4.3), Material = Enum.Material.SmoothPlastic, Color = railCol }, det)
		detail(rail)
		window(cf * CFrame.new(0, y + 4.4, -0.1), W - 3, 6.2, det)
		-- a few awnings / plants on the balconies
		if rng:NextNumber() < 0.25 then
			local s = part({ Class = "WedgePart", Name = "Sunblind", Size = Vector3.new(W * rng:NextNumber(0.3, 0.6), 1.2, 3.6), CFrame = cf * CFrame.new(rng:NextNumber(-W / 4, W / 4), y + FH - 1.4, -2.2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = AWNING[rng:NextInteger(1, #AWNING)] }, det)
			detail(s)
		end
	end
	-- roof: parapet and a small plant room
	part({ Name = "Parapet", Size = Vector3.new(W, 2, D), CFrame = cf * CFrame.new(0, H + 1, D / 2), Material = Enum.Material.Concrete, Color = col:Lerp(Color3.new(1, 1, 1), 0.2) }, m)
	part({ Name = "PlantRoom", Size = Vector3.new(W * 0.35, 7, D * 0.4), CFrame = cf * CFrame.new(rng:NextNumber(-W / 5, W / 5), H + 3.5, D * 0.55), Material = Enum.Material.Concrete, Color = col }, m)
	det:SetAttribute("Center", (cf * CFrame.new(0, H / 2, 0)).Position)
	det:SetAttribute("Range", 900)
	CollectionService:AddTag(det, "LOD")
	det.Parent = m
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- Belle Epoque: front faces -Z of `cf`
---------------------------------------------------------------------
local function belle(cf: CFrame, W: number, D: number, base: number, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "BelleEpoque"
	local floors = rng:NextInteger(4, 6)
	local GF, FH = 14, 11
	local H = GF + floors * FH
	local col = BELLE[rng:NextInteger(1, #BELLE)]
	local trim = col:Lerp(STONE, 0.65)
	part({ Name = "Body", Size = Vector3.new(W, H + base, D), CFrame = cf * CFrame.new(0, H / 2 - base / 2, D / 2), Material = Enum.Material.Plaster, Color = col }, m)
	-- cornice and the mansard roof with dormers
	part({ Name = "Cornice", Size = Vector3.new(W + 2, 1.8, D + 2), CFrame = cf * CFrame.new(0, H + 0.4, D / 2), Material = Enum.Material.Limestone, Color = trim }, m)
	local roofH = 9
	part({ Class = "WedgePart", Name = "RoofFront", Size = Vector3.new(W, roofH, 4), CFrame = cf * CFrame.new(0, H + 1.3 + roofH / 2, 2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Slate, Color = SLATE }, m)
	part({ Name = "RoofTop", Size = Vector3.new(W, roofH, D - 8), CFrame = cf * CFrame.new(0, H + 1.3 + roofH / 2, D / 2), Material = Enum.Material.Slate, Color = SLATE }, m)
	part({ Class = "WedgePart", Name = "RoofBack", Size = Vector3.new(W, roofH, 4), CFrame = cf * CFrame.new(0, H + 1.3 + roofH / 2, D - 2), Material = Enum.Material.Slate, Color = SLATE }, m)
	local det = Instance.new("Model")
	det.Name = "Detail"
	local cols = math.max(2, math.floor(W / 8.5))
	local step = W / cols
	local shutters = rng:NextNumber() < 0.6
	local shutCol = SHUTTER[rng:NextInteger(1, #SHUTTER)]
	-- shops on the ground floor
	for c = 1, cols do
		local x = -W / 2 + (c - 0.5) * step
		window(cf * CFrame.new(x, 5.5, -0.1), step - 2.4, 8.5, det)
	end
	local aw = AWNING[rng:NextInteger(1, #AWNING)]
	local a = part({ Class = "WedgePart", Name = "Awning", Size = Vector3.new(W - 4, 1.8, 5), CFrame = cf * CFrame.new(0, 11.2, -2.5) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = aw }, det)
	detail(a)
	local sc = part({ Name = "GroundCourse", Size = Vector3.new(W + 0.6, 1.2, 0.8), CFrame = cf * CFrame.new(0, GF - 0.6, -0.3), Material = Enum.Material.Limestone, Color = trim }, det)
	detail(sc)
	for f = 1, floors do
		local y = GF + (f - 1) * FH
		local band = part({ Name = "Course", Size = Vector3.new(W + 0.4, 0.6, 0.5), CFrame = cf * CFrame.new(0, y + FH - 0.3, -0.2), Material = Enum.Material.Limestone, Color = trim }, det)
		detail(band)
		local balconyRow = (f == 1 or f == floors) or (f == 3 and rng:NextNumber() < 0.5)
		for c = 1, cols do
			local x = -W / 2 + (c - 0.5) * step
			local wy = y + 5.2
			local frame = part({ Name = "Surround", Size = Vector3.new(4.6, 7.8, 0.25), CFrame = cf * CFrame.new(x, wy, -0.12), Material = Enum.Material.Limestone, Color = trim }, det)
			detail(frame)
			window(cf * CFrame.new(x, wy - 0.2, -0.28), 3.4, 6.6, det)
			if shutters then
				for _, sx in { -2.75, 2.75 } do
					local sh = part({ Name = "Shutter", Size = Vector3.new(1.7, 6.8, 0.25), CFrame = cf * CFrame.new(x + sx, wy - 0.2, -0.3), Material = Enum.Material.Wood, Color = shutCol }, det)
					detail(sh)
				end
			end
			if balconyRow then
				local bslab = part({ Name = "Balcony", Size = Vector3.new(5.6, 0.6, 2.2), CFrame = cf * CFrame.new(x, y + 1.4, -1.1), Material = Enum.Material.Limestone, Color = trim }, det)
				bslab.CanCollide = false
				local rail = part({ Name = "IronRail", Size = Vector3.new(5.6, 0.25, 0.25), CFrame = cf * CFrame.new(x, y + 4.3, -2.1), Material = Enum.Material.Metal, Color = IRON }, det)
				detail(rail)
				for k = -2, 2 do
					local bar = part({ Name = "IronBar", Size = Vector3.new(0.16, 2.9, 0.16), CFrame = cf * CFrame.new(x + k * 1.3, y + 2.85, -2.1), Material = Enum.Material.Metal, Color = IRON }, det)
					detail(bar)
				end
			end
		end
	end
	-- dormers in the mansard
	for c = 1, cols, 2 do
		local x = -W / 2 + (c - 0.5) * step
		local d = part({ Name = "Dormer", Size = Vector3.new(4, 5, 3), CFrame = cf * CFrame.new(x, H + 1.3 + 4, 1.4), Material = Enum.Material.Plaster, Color = trim }, det)
		d.CanCollide = false
		window(cf * CFrame.new(x, H + 1.3 + 4, -0.15), 2.4, 3.4, det)
	end
	det:SetAttribute("Center", (cf * CFrame.new(0, H / 2, 0)).Position)
	det:SetAttribute("Range", 800)
	CollectionService:AddTag(det, "LOD")
	det.Parent = m
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- placement
---------------------------------------------------------------------
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.IgnoreWater = false

local function ground(p: Vector3): (number?, boolean)
	local hit = workspace:Raycast(Vector3.new(p.X, 1600, p.Z), Vector3.new(0, -1700, 0), params)
	if not hit then
		return nil, false
	end
	return hit.Position.Y, hit.Material == Enum.Material.Water
end

function Buildings.build(data, box, parent: Instance, rng: Random, opts): number
	opts = opts or {}
	params.FilterDescendantsInstances = { workspace.Terrain }
	-- every road sample, for "is this spot clear of all roads?"
	local grid = {}
	local roads = {}
	for _, r in data.roads do
		local pts = {}
		for i, s in r.s do
			local p = Vector3.new(s[1], s[2], s[3])
			pts[i] = { pos = p, dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1 }
			local key = math.floor(p.X / 40) .. "," .. math.floor(p.Z / 40)
			grid[key] = grid[key] or {}
			table.insert(grid[key], p)
		end
		table.insert(roads, { name = r.name, kind = r.kind, pts = pts })
	end
	local function clearOfRoads(p: Vector3, margin: number): boolean
		local cx, cz = math.floor(p.X / 40), math.floor(p.Z / 40)
		for dx = -2, 2 do
			for dz = -2, 2 do
				for _, q in grid[(cx + dx) .. "," .. (cz + dz)] or {} do
					if (Vector2.new(q.X - p.X, q.Z - p.Z)).Magnitude < margin then
						return false
					end
				end
			end
		end
		return true
	end
	local placed = {} -- { centre, radius }
	local function clearOfBuildings(c: Vector3, rad: number): boolean
		for _, b in placed do
			if (Vector2.new(b[1].X - c.X, b[1].Z - c.Z)).Magnitude < (b[2] + rad) * 0.82 then
				return false
			end
		end
		return true
	end
	local count = 0
	Buildings.why = {}
	local function why(k)
		Buildings.why[k] = (Buildings.why[k] or 0) + 1
	end
	for _, r in roads do
		if r.kind ~= "street" and r.name ~= "Coast Road" and r.name ~= "Town Road" then
			continue
		end
		if opts.skip and opts.skip(r.name) then
			continue -- (the hillside lanes are kept for the players' house lots)
		end
		for _, side in { -1, 1 } do
			local acc = 0
			local nextGap = rng:NextNumber(4, 12)
			for i = 2, #r.pts do
				local a, b = r.pts[i - 1], r.pts[i]
				acc += (b.pos - a.pos).Magnitude
				if acc < nextGap or b.tunnel then
					continue
				end
				if box and not (b.pos.X >= box[1] and b.pos.X <= box[3] and b.pos.Z >= box[2] and b.pos.Z <= box[4]) then
					continue
				end
				local W = rng:NextNumber(34, 58)
				local D = rng:NextNumber(38, 56)
				local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit * side
				local front = b.pos + right * FRONT
				local centre = front + right * (D / 2)
				local along = b.dir.Unit
				local corners = {
					front - along * (W / 2), front + along * (W / 2),
					front - along * (W / 2) + right * D, front + along * (W / 2) + right * D, centre,
				}
				local ok = clearOfBuildings(centre, math.max(W, D) / 2)
				-- keep the sea side open (the harbour road's view, beaches)
				for _, extra in { 20, 70, 130 } do
					local _, wet = ground(front + right * (D + extra))
					if wet then
						ok = false
						why("seaside")
						break
					end
				end
				if not ok then
					why("building")
				end
				for k = 1, #corners do
					if not ok then
						break
					end
					ok = clearOfRoads(corners[k], HALF + WALK - 2)
					if not ok then
						why("road")
					end
				end
				local lowest, highest = math.huge, -math.huge
				for k = 1, #corners do
					if not ok then
						break
					end
					local y, wet = ground(corners[k])
					if y == nil or wet or y < 1 then
						ok = false
						why(if y == nil then "noground" elseif wet then "water" else "low")
					else
						lowest = math.min(lowest, y)
						highest = math.max(highest, y)
					end
				end
				if not ok then
					acc = math.max(0, nextGap - 6) -- try again a little further on
					continue
				end
				acc = 0
				nextGap = W + rng:NextNumber(1, 6)
				-- ground floor at the pavement; the body runs down to the lowest ground under it
				local floorY = b.pos.Y + 0.5
				local base = math.max(0, floorY - lowest) + 2
				local cf = CFrame.lookAt(Vector3.new(front.X, floorY, front.Z), Vector3.new(front.X, floorY, front.Z) - right)
				local belleChance = if opts.style then opts.style(centre) else 0.4
				local made = if rng:NextNumber() < belleChance then belle(cf, W, D, base, rng, parent) else apartment(cf, W, D, base, rng, parent)
				table.insert(placed, { centre, math.max(W, D) / 2 })
				count += 1
				if count % 6 == 0 then
					task.wait()
				end
				local _ = made
			end
		end
	end
	return count
end

return Buildings
