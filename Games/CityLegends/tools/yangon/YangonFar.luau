--[[
	Yangon far city (Studio, Edit mode). Build step 8, 13 Nov 2026.

	The Yangon map is a block of ground with nothing past its edge (seen from the map, empty sky). This:
	  * M.skirt(): fills grass from each edge outward SKIRT studs, its top at that stretch of edge's own
	    ground (measured every SEG studs), so the ground goes on to the horizon with no step;
	  * M.city(): a ring of simple distant buildings on the skirt (2-3 parts each, non-colliding,
	    persistent so they always show), taller towards Hledan (west) and downtown (south);
	  * M.shwedagon(): the Shwedagon Pagoda's gold stupa on its hill terrace at its real bearing, about
	    2 km south of the map (Yangon's skyline signature), tagged LampGlow so WorldFx lights it at night.
	Everything goes in workspace.Yangon.Far (ModelStreamingMode Persistent).

	Use:  local F = require(game.ServerStorage.ClaudeTools.YangonFar:Clone()); F.all()
]]

local CollectionService = game:GetService("CollectionService")

local M = {}
-- the map's ground grid in world studs (ygn_road_design.json ground: X = 30000 + x*1.6, Z = -y*1.6)
M.X0, M.X1 = 30000 - 1289.35 * 1.6, 30000 + 2184.43 * 1.6
M.Z0, M.Z1 = -4067.87 * 1.6, 1083.29 * 1.6
M.SKIRT = 2600
M.SEG = 128
M.SHWEDAGON = Vector3.new(31619, 0, 3821) -- (96.1495 E, 16.7984 N on the map's frame)

local tp = RaycastParams.new()
tp.FilterType = Enum.RaycastFilterType.Include
tp.IgnoreWater = false

local function groundAt(x: number, z: number): number?
	tp.FilterDescendantsInstances = { workspace.Terrain }
	local h = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -900, 0), tp)
	return h and h.Position.Y or nil
end

function M.folder(): Model
	local y = workspace.Yangon
	local f = y:FindFirstChild("Far")
	if not f then
		f = Instance.new("Model")
		f.Name = "Far"
		f.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		f.Parent = y
	end
	return f :: Model
end

local function quiet(p: BasePart): BasePart
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function box(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material?, parent: Instance, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	quiet(p)
	p.Parent = parent
	return p
end

-- the edge's ground every SEG studs along each side (a stud or two inside the grid)
local function edgeHeights()
	local e = { n = {}, s = {}, w = {}, e = {} }
	for x = M.X0, M.X1, M.SEG do
		table.insert(e.n, { x, groundAt(x, M.Z0 + 6) })
		table.insert(e.s, { x, groundAt(x, M.Z1 - 6) })
	end
	for z = M.Z0, M.Z1, M.SEG do
		table.insert(e.w, { z, groundAt(M.X0 + 6, z) })
		table.insert(e.e, { z, groundAt(M.X1 - 6, z) })
	end
	return e
end

-- (FillBlock's top shows about 2 studs higher on smooth terrain: the fills stop 2 under the edge's
-- ground so the joint is level)
function M.skirt(): string
	local e = edgeHeights()
	local n = 0
	local function fill(cx: number, cz: number, sx: number, sz: number, top: number)
		local bottom = top - 24 -- (thin: these fills are huge)
		workspace.Terrain:FillBlock(CFrame.new(cx, (top + bottom) / 2 - 2, cz), Vector3.new(sx, top - bottom, sz), Enum.Material.Grass)
		n += 1
	end
	local S = M.SKIRT
	for _, q in e.n do
		if q[2] then
			fill(q[1], M.Z0 - S / 2 + 2, M.SEG + 8, S, q[2])
		end
	end
	for _, q in e.s do
		if q[2] then
			fill(q[1], M.Z1 + S / 2 - 2, M.SEG + 8, S, q[2])
		end
	end
	for _, q in e.w do
		if q[2] then
			fill(M.X0 - S / 2 + 2, q[1], S, M.SEG + 8, q[2])
		end
	end
	for _, q in e.e do
		if q[2] then
			fill(M.X1 + S / 2 - 2, q[1], S, M.SEG + 8, q[2])
		end
	end
	-- the four corners at their corner's height
	local function h(list, k)
		return (list[k] and list[k][2]) or 40
	end
	fill(M.X0 - S / 2, M.Z0 - S / 2, S, S, h(e.n, 1))
	fill(M.X1 + S / 2, M.Z0 - S / 2, S, S, h(e.n, #e.n))
	fill(M.X0 - S / 2, M.Z1 + S / 2, S, S, h(e.s, 1))
	fill(M.X1 + S / 2, M.Z1 + S / 2, S, S, h(e.s, #e.s))
	return "skirt: " .. n .. " fills"
end

local FAR_COLS = {
	Color3.fromRGB(214, 208, 196), Color3.fromRGB(196, 192, 184), Color3.fromRGB(226, 220, 204),
	Color3.fromRGB(184, 190, 196), Color3.fromRGB(206, 196, 176), Color3.fromRGB(170, 178, 186),
	Color3.fromRGB(222, 214, 190), Color3.fromRGB(150, 160, 170),
}

-- distant buildings: 2-3 parts each (body, a darker band of windows on the top floors, a roof cap)
function M.city(seed: number?): string
	local f = M.folder()
	local old = f:FindFirstChild("City")
	if old then
		old:Destroy()
	end
	local city = Instance.new("Folder")
	city.Name = "City"
	local rng = Random.new(seed or 1311)
	local made = 0
	local cx, cz = (M.X0 + M.X1) / 2, (M.Z0 + M.Z1) / 2
	local hw, hd = (M.X1 - M.X0) / 2, (M.Z1 - M.Z0) / 2
	for _ = 1, 260 do
		-- a point in the ring 180..1500 outside the edge
		local side = rng:NextInteger(1, 4)
		local out = 180 + rng:NextNumber() ^ 1.6 * 1300
		local x, z
		if side == 1 then
			x, z = rng:NextNumber(M.X0 - out, M.X1 + out), M.Z0 - out
		elseif side == 2 then
			x, z = rng:NextNumber(M.X0 - out, M.X1 + out), M.Z1 + out
		elseif side == 3 then
			x, z = M.X0 - out, rng:NextNumber(M.Z0 - out, M.Z1 + out)
		else
			x, z = M.X1 + out, rng:NextNumber(M.Z0 - out, M.Z1 + out)
		end
		-- (keep clear of Shwedagon's hill)
		if (Vector3.new(x, 0, z) - M.SHWEDAGON).Magnitude < 420 then
			continue
		end
		local g = groundAt(x, z) or 40
		-- taller west (Hledan, Kamayut) and south (downtown)
		local tall = 0.35
		if x < cx - hw * 0.4 or z > cz + hd * 0.5 then
			tall = 0.65
		end
		local h = if rng:NextNumber() < tall then rng:NextNumber(90, 230) else rng:NextNumber(36, 90)
		local w, d = rng:NextNumber(40, 90), rng:NextNumber(40, 80)
		local yaw = rng:NextNumber(-0.25, 0.25) + (if side <= 2 then 0 else math.pi / 2)
		local cf = CFrame.new(x, g - 4, z) * CFrame.Angles(0, yaw, 0)
		local col = FAR_COLS[rng:NextInteger(1, #FAR_COLS)]
		local m = Instance.new("Model")
		m.Name = "FarBuilding"
		box("Body", Vector3.new(w, h + 4, d), cf * CFrame.new(0, (h + 4) / 2, 0), col, Enum.Material.Concrete, m)
		-- a band of dark windows wrapping the upper part (reads as glazing at a distance)
		local bh = math.min(h * 0.55, 60)
		local band = box("Windows", Vector3.new(w + 0.4, bh, d + 0.4), cf * CFrame.new(0, h + 4 - bh / 2 - 6, 0), col:Lerp(Color3.fromRGB(40, 48, 60), 0.6), Enum.Material.SmoothPlastic, m)
		if h > 120 then
			box("Crown", Vector3.new(w * 0.7, 10, d * 0.7), cf * CFrame.new(0, h + 9, 0), col:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Concrete, m)
		end
		CollectionService:AddTag(band, "FarBand")
		m.Parent = city
		made += 1
	end
	city.Parent = f
	return "far city: " .. made .. " buildings"
end

-- Shwedagon: the hill and its terrace, the gold stupa (terraces, bell, rings, lotus, banana bud, umbrella
-- spire) and a ring of small stupas round it
function M.shwedagon(): string
	local f = M.folder()
	local old = f:FindFirstChild("Shwedagon")
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = "Shwedagon"
	local p = M.SHWEDAGON
	local g = groundAt(p.X, p.Z) or 45
	-- Singuttara hill: a terrain mound, then the white terrace on top
	workspace.Terrain:FillCylinder(CFrame.new(p.X, g + 30 - 2, p.Z), 60, 320, Enum.Material.Grass)
	workspace.Terrain:FillCylinder(CFrame.new(p.X, g + 50 - 2, p.Z), 20, 230, Enum.Material.Grass)
	local base = g + 60
	local GOLD = Color3.fromRGB(212, 160, 23)
	local WHITE = Color3.fromRGB(245, 245, 240)
	box("Terrace", Vector3.new(300, 8, 300), CFrame.new(p.X, base - 4, p.Z), WHITE, Enum.Material.Marble, m)
	local function gold(name, size, cf, shape)
		local q = box(name, size, cf, GOLD, Enum.Material.Foil, m, shape)
		CollectionService:AddTag(q, "LampGlow")
		return q
	end
	local y = base
	-- three octagon-ish terraces (two squares at 45 degrees each)
	for i, s in { 150, 126, 104 } do
		for _, r in { 0, math.pi / 4 } do
			gold("Plinth" .. i, Vector3.new(s, 10, s), CFrame.new(p.X, y + 5, p.Z) * CFrame.Angles(0, r, 0))
		end
		y += 10
	end
	-- the bell
	gold("Bell", Vector3.new(96, 110, 96), CFrame.new(p.X, y + 40, p.Z), Enum.PartType.Ball)
	y += 90
	-- the rings (turban bands) and the lotus
	for i, r in { 60, 52, 44, 38, 32 } do
		gold("Ring" .. i, Vector3.new(8, r, r), CFrame.new(p.X, y + 4, p.Z) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
		y += 8
	end
	-- the banana bud: a long tapering stack
	local r = 28
	for i = 1, 10 do
		gold("Bud" .. i, Vector3.new(10, r, r), CFrame.new(p.X, y + 5, p.Z) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
		y += 10
		r *= 0.8
	end
	-- the umbrella (hti) and the spire
	gold("Hti", Vector3.new(4, 14, 14), CFrame.new(p.X, y + 2, p.Z) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	gold("Spire", Vector3.new(30, 2.4, 2.4), CFrame.new(p.X, y + 18, p.Z) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	gold("Orb", Vector3.new(4, 4, 4), CFrame.new(p.X, y + 34, p.Z), Enum.PartType.Ball)
	local top = y + 36
	-- small stupas round the terrace
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		local q = Vector3.new(p.X + math.cos(a) * 120, base, p.Z + math.sin(a) * 120)
		gold("SmallBell", Vector3.new(16, 20, 16), CFrame.new(q + Vector3.new(0, 10, 0)), Enum.PartType.Ball)
		gold("SmallSpire", Vector3.new(26, 4, 4), CFrame.new(q + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	end
	m.Parent = f
	return string.format("Shwedagon at %.0f, %.0f: ground %.0f, top %.0f (%d parts)", p.X, p.Z, g, top, #m:GetChildren())
end

function M.all(): string
	local log = { M.skirt() }
	task.wait()
	table.insert(log, M.city())
	task.wait()
	table.insert(log, M.shwedagon())
	return table.concat(log, "\n")
end

return M
