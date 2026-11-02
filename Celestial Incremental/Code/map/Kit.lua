-- Kit (Galaxy Incremental, 2 Nov): the map's reusable pieces. Kit.Make(name, opts) gives the piece:
--   * the owner's imported MeshPart of that name (ReplicatedStorage.GalaxyKit: galaxy_kit.fbx from Blender, low-poly faceted,
--     Celestial Incremental\Map\galaxy_kit.py), sized to opts.Size, or
--   * until it's imported, a stand-in of plain parts with the same size and place (so the map works and can be tested now).
-- opts: Size (the piece's bounding box, Roblox axes: Y up), CFrame, Color, Material, Parent, Name, Collide (default false),
-- Reflectance. Pieces are anchored, cast no shadow (Playbook), CanTouch off. Rings lie flat (axis Y) unless rotated.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = {}

Kit.Names = { "IslandTop", "IslandUnder", "RockBare", "RimRing", "GyroRing", "OrbitRing", "ShockRing", "Pillar", "LampOrb",
	"CrystalCluster", "Crystal", "Banner", "Telescope", "Dais", "BoardFrame", "BridgeSegment", "GrassPatch", "Altar", "CoreSpike",
	"CoreOrb", "Planet", "Anvil", "Padlock", "GateArch", "GateRing", "VoidDisc" }

-- the ring pieces' tube thickness as a share of their radius (matches galaxy_kit.py)
Kit.RingRatio = { RimRing = 0.03, GyroRing = 0.035, OrbitRing = 0.012, ShockRing = 0.02, GateRing = 0.15 }

function Kit.Imported(name: string): MeshPart?
	local folder = ReplicatedStorage:FindFirstChild("GalaxyKit")
	local mesh = folder and folder:FindFirstChild(name, true)
	return if mesh and mesh:IsA("MeshPart") then mesh else nil
end
function Kit.AllImported(): boolean
	for _, name in ipairs(Kit.Names) do
		if not Kit.Imported(name) then return false end
	end
	return true
end

local function style(part: BasePart, opts)
	part.Anchored = true
	part.CanCollide = opts.Collide == true
	part.CanQuery = opts.Collide == true or opts.Query == true
	part.CanTouch = false
	part.CastShadow = false
	part.Color = opts.Color or Color3.new(1, 1, 1)
	part.Material = opts.Material or Enum.Material.SmoothPlastic
	part.Reflectance = opts.Reflectance or 0
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
end

local function newPart(shape: Enum.PartType?, size: Vector3, cf: CFrame, opts, parent: Instance): Part
	local p = Instance.new("Part")
	if shape then p.Shape = shape end
	p.Size = size
	p.CFrame = cf
	style(p, opts)
	p.Parent = parent
	return p
end
-- a cylinder standing up (Roblox cylinders lie along X)
local function upCyl(d: number, h: number, cf: CFrame, opts, parent): Part
	return newPart(Enum.PartType.Cylinder, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), opts, parent)
end

local STAND_IN = {}
STAND_IN.IslandTop = function(s, cf, o, m) upCyl(s.X, s.Y, cf, o, m) end
STAND_IN.IslandUnder = function(s, cf, o, m)
	for i, k in ipairs({ 1, 0.8, 0.55, 0.3 }) do
		local h = s.Y / 4
		upCyl(s.X * k, h, cf * CFrame.new(0, s.Y / 2 - h * (i - 0.5), 0), o, m)
	end
end
STAND_IN.RockBare = function(s, cf, o, m)
	newPart(nil, s * 0.82, cf * CFrame.Angles(0.3, 0.6, 0.2), o, m)
	newPart(nil, s * 0.78, cf * CFrame.Angles(-0.4, 1.4, 0.5), o, m)
	newPart(nil, Vector3.new(s.X * 0.9, s.Y * 0.62, s.Z * 0.9), cf * CFrame.new(0, s.Y * 0.12, 0), o, m)
end
local function ring(s, cf, o, m, ratio)
	local R = s.X / 2
	local t = math.max(R * ratio * 2, 0.08)
	local n = math.clamp(math.floor(R * 2.2), 16, 48)
	for i = 1, n do
		local a = (i - 0.5) / n * math.pi * 2
		local len = 2 * math.pi * R / n * 1.08
		newPart(nil, Vector3.new(t, t, len), cf * CFrame.Angles(0, -a, 0) * CFrame.new(R - t / 2, 0, 0), o, m)
	end
end
for name, ratio in pairs(Kit.RingRatio) do
	STAND_IN[name] = function(s, cf, o, m) ring(s, cf, o, m, ratio) end
end
STAND_IN.Pillar = function(s, cf, o, m)
	upCyl(s.X * 0.55, s.Y * 0.9, cf, o, m)
	upCyl(s.X, s.Y * 0.07, cf * CFrame.new(0, -s.Y * 0.465, 0), o, m)
	upCyl(s.X * 0.9, s.Y * 0.06, cf * CFrame.new(0, s.Y * 0.47, 0), o, m)
end
local function ball(s, cf, o, m) newPart(Enum.PartType.Ball, Vector3.new(1, 1, 1) * math.min(s.X, s.Y, s.Z), cf, o, m) end
STAND_IN.LampOrb, STAND_IN.CoreOrb, STAND_IN.Planet = ball, ball, ball
STAND_IN.Crystal = function(s, cf, o, m) newPart(nil, Vector3.new(s.X * 0.7, s.Y, s.Z * 0.7), cf * CFrame.Angles(0, math.rad(45), 0), o, m) end
STAND_IN.CrystalCluster = function(s, cf, o, m)
	newPart(nil, Vector3.new(s.X * 0.3, s.Y, s.Z * 0.3), cf * CFrame.Angles(0.05, 0.8, 0.08), o, m)
	newPart(nil, Vector3.new(s.X * 0.24, s.Y * 0.68, s.Z * 0.24), cf * CFrame.new(s.X * 0.25, -s.Y * 0.14, s.Z * 0.1) * CFrame.Angles(0.3, 0.4, -0.35), o, m)
	newPart(nil, Vector3.new(s.X * 0.2, s.Y * 0.55, s.Z * 0.2), cf * CFrame.new(-s.X * 0.24, -s.Y * 0.2, s.Z * 0.12) * CFrame.Angles(-0.25, 1.1, 0.4), o, m)
end
STAND_IN.Banner = function(s, cf, o, m) newPart(nil, Vector3.new(s.X, s.Y, math.max(s.Z, 0.1)), cf, o, m) end
STAND_IN.BridgeSegment = function(s, cf, o, m) newPart(nil, s, cf, o, m) end
STAND_IN.GrassPatch = function(s, cf, o, m) upCyl(s.X, s.Y, cf, o, m) end
STAND_IN.Dais = function(s, cf, o, m)
	upCyl(s.X, s.Y * 0.36, cf * CFrame.new(0, -s.Y * 0.32, 0), o, m)
	upCyl(s.X * 0.82, s.Y * 0.36, cf * CFrame.new(0, 0.02, 0), o, m)
	upCyl(s.X * 0.6, s.Y * 0.3, cf * CFrame.new(0, s.Y * 0.35, 0), o, m)
end
STAND_IN.Altar = STAND_IN.Dais
STAND_IN.CoreSpike = function(s, cf, o, m) newPart(nil, Vector3.new(s.X * 0.5, s.Y, s.Z * 0.5), cf, o, m) end
STAND_IN.Telescope = function(s, cf, o, m)
	newPart(Enum.PartType.Cylinder, Vector3.new(s.Y * 0.7, s.X * 0.22, s.X * 0.22), cf * CFrame.new(0, s.Y * 0.2, 0) * CFrame.Angles(0, 0, math.rad(35)), o, m)
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3
		newPart(nil, Vector3.new(0.12, s.Y * 0.55, 0.12), cf * CFrame.new(math.cos(a) * s.X * 0.18, -s.Y * 0.22, math.sin(a) * s.X * 0.18) * CFrame.Angles(math.sin(a) * 0.3, 0, -math.cos(a) * 0.3), o, m)
	end
end
STAND_IN.BoardFrame = function(s, cf, o, m)
	local t = s.X * 0.05
	newPart(nil, Vector3.new(s.X, t, s.Z), cf * CFrame.new(0, s.Y * 0.36, 0), o, m)
	newPart(nil, Vector3.new(s.X, t, s.Z), cf * CFrame.new(0, -s.Y * 0.14, 0), o, m)
	newPart(nil, Vector3.new(t, s.Y * 0.55, s.Z), cf * CFrame.new(-s.X / 2 + t / 2, s.Y * 0.11, 0), o, m)
	newPart(nil, Vector3.new(t, s.Y * 0.55, s.Z), cf * CFrame.new(s.X / 2 - t / 2, s.Y * 0.11, 0), o, m)
	newPart(nil, Vector3.new(t * 0.8, s.Y * 0.35, t * 0.8), cf * CFrame.new(-s.X * 0.38, -s.Y * 0.32, 0), o, m)
	newPart(nil, Vector3.new(t * 0.8, s.Y * 0.35, t * 0.8), cf * CFrame.new(s.X * 0.38, -s.Y * 0.32, 0), o, m)
end
STAND_IN.Anvil = function(s, cf, o, m)
	newPart(nil, Vector3.new(s.X * 0.75, s.Y * 0.28, s.Z), cf * CFrame.new(s.X * 0.12, s.Y * 0.36, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.28, s.Y * 0.45, s.Z * 0.7), cf * CFrame.new(s.X * 0.12, 0, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.5, s.Y * 0.18, s.Z), cf * CFrame.new(s.X * 0.12, -s.Y * 0.41, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.3, s.Y * 0.18, s.Z * 0.5), cf * CFrame.new(-s.X * 0.38, s.Y * 0.36, 0), o, m)
end
STAND_IN.Padlock = function(s, cf, o, m)
	newPart(nil, Vector3.new(s.X, s.Y * 0.6, s.Z), cf * CFrame.new(0, -s.Y * 0.2, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.14, s.Y * 0.4, s.Z * 0.5), cf * CFrame.new(-s.X * 0.32, s.Y * 0.3, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.14, s.Y * 0.4, s.Z * 0.5), cf * CFrame.new(s.X * 0.32, s.Y * 0.3, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.78, s.Y * 0.12, s.Z * 0.5), cf * CFrame.new(0, s.Y * 0.46, 0), o, m)
end
STAND_IN.GateArch = function(s, cf, o, m)
	local t = s.X * 0.13
	newPart(nil, Vector3.new(t, s.Y * 0.74, t), cf * CFrame.new(-s.X / 2 + t / 2, -s.Y * 0.13, 0), o, m)
	newPart(nil, Vector3.new(t, s.Y * 0.74, t), cf * CFrame.new(s.X / 2 - t / 2, -s.Y * 0.13, 0), o, m)
	newPart(nil, Vector3.new(s.X, t, t), cf * CFrame.new(0, s.Y * 0.3, 0), o, m)
	newPart(nil, Vector3.new(s.X * 0.6, t, t), cf * CFrame.new(0, s.Y / 2 - t / 2, 0), o, m)
end
STAND_IN.VoidDisc = function(s, cf, o, m) upCyl(s.X, math.max(s.Y, 0.1), cf, o, m) end

-- the kit meshes' own proportions (MeshSize of galaxy_kit.fbx): the stand-ins use them too, so a piece is the same size
-- either way
local NATIVE = {
	Altar = Vector3.new(184.776, 54, 184.776), Anvil = Vector3.new(142, 83, 42), Banner = Vector3.new(108, 106, 13.2),
	BoardFrame = Vector3.new(112, 124, 8), BridgeSegment = Vector3.new(100, 12, 100), CoreOrb = Vector3.new(190.21, 200, 200),
	CoreSpike = Vector3.new(100, 100, 100), Crystal = Vector3.new(44, 100, 38.1), CrystalCluster = Vector3.new(158.3, 159.35, 123.14),
	Dais = Vector3.new(200, 34, 200), GateArch = Vector3.new(144, 183.79, 24), GateRing = Vector3.new(240, 34, 240),
	GrassPatch = Vector3.new(167.78, 6, 171.16), GyroRing = Vector3.new(207, 6.06, 207), IslandTop = Vector3.new(200, 18, 194.99),
	IslandUnder = Vector3.new(200, 103.07, 200), LampOrb = Vector3.new(178.89, 200, 170.13), OrbitRing = Vector3.new(202.4, 2.4, 202.4),
	Padlock = Vector3.new(70, 90, 26), Pillar = Vector3.new(44, 182, 44), Planet = Vector3.new(178.89, 200, 170.13),
	RimRing = Vector3.new(206, 5.196, 206), RockBare = Vector3.new(194.91, 150.53, 175.12), ShockRing = Vector3.new(204, 4, 204),
	Telescope = Vector3.new(73.17, 161.67, 122.31), VoidDisc = Vector3.new(200, 0.01, 200),
}
-- a piece's size scaled UNIFORMLY so its `axis` ("X", "Y" or "Z") is `value` studs (never stretched: owner, map redo)
function Kit.Fit(name: string, axis: string, value: number): Vector3
	local mesh = Kit.Imported(name)
	local native = (mesh and mesh.MeshSize) or NATIVE[name] or Vector3.new(1, 1, 1)
	return native * (value / native[axis])
end

-- the piece, at cf (its centre), size s (bounding box, Roblox axes). opts.Fit = { axis, value } sizes it uniformly instead
-- of opts.Size.
function Kit.Make(name: string, opts): Instance
	if opts.Fit then opts.Size = Kit.Fit(name, opts.Fit[1], opts.Fit[2]) end
	local size, cf = opts.Size, opts.CFrame
	local mesh = Kit.Imported(name)
	if mesh then
		local part = mesh:Clone()
		part.Name = opts.Name or name
		part.Size = size
		part.CFrame = cf
		style(part, opts)
		part.Parent = opts.Parent
		return part
	end
	local model = Instance.new("Model")
	model.Name = opts.Name or name
	model:SetAttribute("StandIn", name)
	local build = STAND_IN[name]
	if build then build(size, cf, opts, model) else newPart(nil, size, cf, opts, model) end
	model.Parent = opts.Parent
	return model
end

-- a ring of wedge tiles on a floor (concept v3): every other one of `count` sectors between radius r1 and r2, in `color`,
-- lying on the surface at `top` (the floor's top centre). Each tile = a block + two thin wedges (a flat trapezoid).
function Kit.TileRing(parent: Instance, top: Vector3, r1: number, r2: number, count: number, color: Color3, start: number?)
	local half = math.pi / count
	local t = 0.06
	local L = r2 - r1
	local w1 = 2 * r1 * math.sin(half) * 0.92
	local d = (2 * r2 * math.sin(half) * 0.92 - w1) / 2
	local up = Vector3.new(0, 1, 0)
	for k = 0, count - 1, 2 do
		local phi = (start or 0) + (k + 0.5) * 2 * half
		local r = Vector3.new(math.cos(phi), 0, math.sin(phi))
		local s = r:Cross(up)
		local mid = top + r * (r1 + L / 2) + Vector3.new(0, t / 2 + 0.01, 0)
		newPart(nil, Vector3.new(w1, t, L), CFrame.fromMatrix(mid, s, up, -r), { Color = color }, parent)
		for _, side in ipairs({ 1, -1 }) do
			local w = Instance.new("WedgePart")
			w.Size = Vector3.new(t, d, L)
			-- (the wedge's triangle lies flat: its thin X is vertical, its thick end points out)
			w.CFrame = CFrame.fromMatrix(mid + s * side * (w1 / 2 + d / 2), up * side, s * side, r)
			style(w, { Color = color })
			w.Parent = parent
		end
	end
end

-- the IslandUnder mesh's profile (galaxy_kit.py): its radius share at each depth share
local UNDER_PROFILE = { { 0, 1 }, { 0.25, 0.86 }, { 0.55, 0.62 }, { 0.82, 0.32 }, { 1, 0.08 } }
local function underRadius(u: number): number
	for i = 2, #UNDER_PROFILE do
		local a, b = UNDER_PROFILE[i - 1], UNDER_PROFILE[i]
		if u <= b[1] then return a[2] + (b[2] - a[2]) * (u - a[1]) / (b[1] - a[1]) end
	end
	return 0.08
end

-- 2-3 crystals hanging point-down under an island's rock cone (centre = the cone's top centre, depth = its height)
function Kit.HangingCrystals(parent: Instance, centre: Vector3, radius: number, depth: number, color: Color3, seed: number)
	local rnd = Random.new(seed)
	for k = 1, 3 do
		local a = seed + k * 2.1 + rnd:NextNumber(-0.3, 0.3)
		-- (its top inside the cone, so it grows out of the rock a little lower down, out where the cone is still wide enough
		-- to show past its edge from above; they glow softly, since the cone's underside is in shadow)
		local u = rnd:NextNumber(0.3, 0.5)
		local y = depth * u
		local rr = radius * underRadius(u + 0.14) * 0.98
		local h = depth * rnd:NextNumber(0.28, 0.38)
		Kit.Make("Crystal", { Name = "HangingCrystal", Fit = { "Y", h },
			CFrame = CFrame.new(centre + Vector3.new(math.cos(a) * rr, -y - h / 2, math.sin(a) * rr)) * CFrame.Angles(math.pi + rnd:NextNumber(-0.15, 0.15), rnd:NextNumber(0, 6), 0),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.3), Material = Enum.Material.Neon, Parent = parent })
	end
end

-- every part of a piece (one MeshPart, or a stand-in's parts)
function Kit.Parts(piece: Instance): { BasePart }
	if piece:IsA("BasePart") then return { piece } end
	local list = {}
	for _, d in ipairs(piece:GetDescendants()) do if d:IsA("BasePart") then table.insert(list, d) end end
	return list
end
function Kit.SetColor(piece: Instance, color: Color3, material: Enum.Material?)
	for _, p in ipairs(Kit.Parts(piece)) do
		p.Color = color
		if material then p.Material = material end
	end
end

return Kit
