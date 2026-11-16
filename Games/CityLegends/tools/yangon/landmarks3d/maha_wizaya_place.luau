--!nocheck
-- Maha Wizaya Pagoda: places the imported model (ServerStorage.MahaWizayaHolding, from asset 133204634351791 via
-- InsertService:LoadAsset) at its real spot, sets the looks, builds the invisible collision and the inside lights.
-- Paste into execute_luau (Edit). It runs in task.spawn and reports in _G.mwPlace (the MCP cuts calls over ~5 s).
-- Model frame (Blender, metres): +X east, +Y north, +Z up, pivot = stupa axis on the ground under the plaza.
-- The importer turns a .glb half a turn: the parts come in with Blender (x, y, z) at holding (-3x, 3z, 3y); one more
-- half turn puts Blender (x, y, z) at world (X + 3x, Y0 + 3z, Z - 3y) (north = -Z).
local IDS = { dome = 123923787186968, mural = 119786845550491, leaves = 77892181944887 } -- textures darkened x0.55-0.86 (tex/*_v2.png): a MeshPart Color does not tint a TextureID
local X, Y0, Z = 33902.884, 108.92, 38317.361 -- OSM way/180612556 centroid (96.152209, 16.794919) via geo.world, 1to1; ground GLO-30 (ground.py)
local S = 3

local LOOK = { -- key = last "_" piece of the mesh name
	Gold = { Enum.Material.Metal, Color3.fromRGB(226, 222, 245), "YgnGoldLeaf" },
	Cream = { Enum.Material.SmoothPlastic, Color3.fromRGB(246, 236, 192) },
	White = { Enum.Material.SmoothPlastic, Color3.fromRGB(255, 255, 250) },
	Red = { Enum.Material.SmoothPlastic, Color3.fromRGB(150, 52, 46) },
	Marble = { Enum.Material.Marble, Color3.fromRGB(232, 230, 222), "YgnMarbleWhite" },
	FloorDark = { Enum.Material.SmoothPlastic, Color3.fromRGB(44, 46, 46), nil, 0.12 },
	FloorLight = { Enum.Material.SmoothPlastic, Color3.fromRGB(214, 208, 196), nil, 0.05 },
	Lattice = { Enum.Material.SmoothPlastic, Color3.fromRGB(44, 92, 66) },
	Wood = { Enum.Material.Wood, Color3.fromRGB(118, 74, 44) },
	Trunk = { Enum.Material.SmoothPlastic, Color3.fromRGB(96, 108, 106) },
	Lotus = { Enum.Material.SmoothPlastic, Color3.fromRGB(196, 98, 92) },
	TileBlue = { Enum.Material.SmoothPlastic, Color3.fromRGB(90, 168, 196) },
	Grate = { Enum.Material.Metal, Color3.fromRGB(60, 60, 62) },
	Glass = { Enum.Material.Glass, Color3.fromRGB(200, 226, 232), nil, 0.1, 0.55 },
	Carpet = { Enum.Material.Fabric, Color3.fromRGB(150, 44, 40) },
	Roof = { Enum.Material.Metal, Color3.fromRGB(50, 100, 75), "YgnCorrugatedZinc" },
	TexDome = { Enum.Material.Fabric, Color3.new(1, 1, 1), nil, 0, 0, "dome" },
	TexMural = { Enum.Material.Fabric, Color3.new(1, 1, 1), nil, 0, 0, "mural" },
	TexLeaves = { Enum.Material.Fabric, Color3.new(1, 1, 1), nil, 0, 0, "leaves" },
}

local BASE = CFrame.new(X, Y0, Z) * CFrame.Angles(0, math.pi, 0)
local function W(x, y, z) -- Blender metres -> world position
	return Vector3.new(X + S * x, Y0 + S * z, Z - S * y)
end

local function run()
	local hold = game.ServerStorage.MahaWizayaHolding
	local lm = workspace.Yangon1to1.Landmarks
	local old = lm:FindFirstChild("MahaWizaya")
	if old then old:Destroy() end
	local root = Instance.new("Model")
	root.Name = "MahaWizaya"
	root:SetAttribute("Source", "tools/yangon/landmarks3d/maha_wizaya_blender.py + maha_wizaya_place.luau")
	root:SetAttribute("AssetId", 133204634351791)
	local vis = Instance.new("Model")
	vis.Name = "Visual"
	vis.Parent = root
	local col = Instance.new("Folder")
	col.Name = "Collision"
	col.Parent = root
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = root
	root.Parent = lm
	local mvs = game:GetService("MaterialService")
	local n = 0
	for _, d in hold:GetDescendants() do
		if d:IsA("MeshPart") then
			local node = d.Parent and d.Parent.Name:gsub("_Node$", "") or d.Name
			local key = d.Name:match("_([%a]+)$")
			local lk = LOOK[key]
			d.CFrame = BASE * d.CFrame
			d.Name = node
			d.Anchored = true
			if lk then
				d.Material = lk[1]
				d.Color = lk[2]
				if lk[3] and mvs:FindFirstChild(lk[3], true) then d.MaterialVariant = lk[3] end
				d.Reflectance = lk[4] or 0
				d.Transparency = lk[5] or 0
				if lk[6] then d.TextureID = "rbxassetid://" .. IDS[lk[6]] end
			end
			d:SetAttribute("Look", key)
			d.Parent = vis
			d.CollisionFidelity = Enum.CollisionFidelity.Box
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			n += 1
			if n % 40 == 0 then task.wait() end
		end
	end
	-- invisible collision (Blender metres): box(centre x, centre y, z0, z1, width across, depth along, bearing deg)
	local nc = 0
	local function box(name, cx, cy, z0, z1, sx, sy, b, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		if shape then
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(S * (z1 - z0), S * sx, S * sx)
			p.CFrame = CFrame.new(W(cx, cy, (z0 + z1) / 2)) * CFrame.Angles(0, 0, math.pi / 2)
		else
			p.Size = Vector3.new(S * sx, S * (z1 - z0), S * sy)
			p.CFrame = CFrame.new(W(cx, cy, (z0 + z1) / 2)) * CFrame.Angles(0, -math.rad(b or 0), 0)
		end
		p.Parent = col
		nc += 1
	end
	local function pol(r, bdeg) -- bearing -> Blender xy
		local t = math.rad(bdeg)
		return r * math.sin(t), r * math.cos(t)
	end
	box("Plaza", 0, 0, -0.6, 0.3, 90, 90, 0)
	box("FloorInside", 0, 0, 0.3, 0.65, 34, 34, 0)
	for _, b in { 0, 90, 180, 270 } do
		local x, y = pol(24.35, b)
		box("FloorTunnel", x, y, 0.3, 0.65, 4.1, 15.1, b)
	end
	-- wall stretches between the 4 doorways: chamber wall (r 11-13) and ambulatory outer wall (r 17-19)
	local function ring(name, r0, r1, gapHalf, z1, nseg)
		for q = 0, 3 do
			local g = math.deg(math.asin(gapHalf / r0))
			local a0, a1 = 90 * q + g, 90 * (q + 1) - g
			local span = (a1 - a0) / nseg
			for i = 0, nseg - 1 do
				local a = a0 + span * (i + 0.5)
				local x, y = pol((r0 + r1) / 2, a)
				box(name, x, y, 0.65, z1, 2 * r1 * math.tan(math.rad(span / 2)) + 0.05, r1 - r0, a)
			end
		end
	end
	ring("ChamberWall", 11.0, 13.0, 1.7, 5.5, 8)
	ring("AmbulatoryWall", 17.0, 19.0, 2.05, 6.2, 10)
	-- the base mass: one box per octagon side (cardinal sides split round the tunnel), apothem 18.5 -> 27.4
	local h = 27.4 * math.tan(math.pi / 8)
	for k = 0, 7 do
		local b = 45 * k
		local spans = (k % 2 == 0) and { { -h, -2.05 }, { 2.05, h } } or { { -h, h } }
		for _, sp in spans do
			local tm = (sp[1] + sp[2]) / 2
			local nx, ny = pol(1, b)
			local tx, ty = ny, -nx
			local cr = (18.5 + 27.4) / 2
			box("Base", nx * cr + tx * tm, ny * cr + ty * tm, 0.3, 6.2, sp[2] - sp[1], 27.4 - 18.5, b)
		end
		if k % 2 == 0 then -- porch piers
			for _, s in { -1, 1 } do
				local nx, ny = pol(1, b)
				local tx, ty = ny, -nx
				local tm, cr = s * 3.7, (27.4 + 31.9) / 2
				box("Porch", nx * cr + tx * tm, ny * cr + ty * tm, 0.3, 6.8, 3.3, 4.5, b)
				-- chinthe on its plinth
				local cx, cy = nx * (27.4 + 1.6) + tx * s * 7.75, ny * (27.4 + 1.6) + ty * s * 7.75
				box("Chinthe", cx, cy, 0.3, 3.8, 1.5, 2.6, b)
			end
		end
	end
	box("ShrineBasin", 0, 0, 0.65, 1.6, 8.9, 0, 0, true)
	box("Shrine", 0, 0, 1.6, 9.6, 5.2, 5.2, 22.5)
	for k = 0, 11 do
		local b = 15 + 30 * k
		local x, y = pol(6.3, b)
		box("Case", x, y, 0.65, 1.75, 1.0, 0.7, b)
	end
	-- the ground plate under the compound (no 1:1 terrain here yet): concrete, top at the ground
	local plate = lm:FindFirstChild("MahaWizayaPlate_TEMP") or Instance.new("Part")
	plate.Name = "MahaWizayaPlate_TEMP"
	plate.Anchored = true
	plate.Material = Enum.Material.Concrete
	plate.Color = Color3.fromRGB(150, 146, 136)
	plate.Size = Vector3.new(336, 6, 336)
	plate.CFrame = CFrame.new(X, Y0 - 3, Z)
	plate.Parent = lm
	-- inside lights (the photos: white floodlights and wall lamps)
	local function lamp(name, x, y, z, bright, range, colr)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(0.5, 0.5, 0.5)
		p.Position = W(x, y, z)
		local l = Instance.new("PointLight")
		l.Brightness = bright * 0.6 -- (0.6: dimmer, like the photos)
		l.Range = range
		l.Color = colr
		l.Shadows = false
		l.Parent = p
		p:SetAttribute("NoLod", true)
		p.Parent = lights
	end
	for k = 0, 3 do
		local x, y = pol(7.5, 45 + 90 * k)
		lamp("ChamberLamp", x, y, 4.2, 1.6, 40, Color3.fromRGB(225, 238, 255))
		local x2, y2 = pol(15, 45 + 90 * k)
		lamp("AmbulatoryLamp", x2, y2, 4.0, 1.2, 30, Color3.fromRGB(255, 244, 222))
		local x3, y3 = pol(22, 90 * k)
		lamp("TunnelLamp", x3, y3, 3.8, 1.0, 22, Color3.fromRGB(255, 244, 222))
	end
	lamp("DomeLamp", 0, 0, 10.5, 1.4, 45, Color3.fromRGB(210, 232, 255))
	hold:Destroy()
	return string.format("meshparts %d, collision %d", n, nc)
end

_G.mwPlace = "busy"
task.spawn(function()
	local ok, res = pcall(run)
	_G.mwPlace = (ok and "ok: " or "ERR: ") .. tostring(res)
end)
return "started"
