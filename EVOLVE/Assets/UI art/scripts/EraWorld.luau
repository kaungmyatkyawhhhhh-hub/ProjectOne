-- EraWorld: every player sees the world of THEIR lineage's era (owner, 18 Nov 2026: "the world looks futuristic but not for
-- all"). Client-only looks: the ground and its collisions stay shared, the server still decides everything that matters.
-- Era = your depth on the tree (StageNum attribute). Changes here never replicate, so each player sees their own Earth.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local terrain = workspace.Terrain
local world = workspace:WaitForChild("World")

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local ERAS = { -- upto = last depth of the era; nil fields keep the map's own look
	{ upto = 11, name = "Ancient Sea", -- First Cell .. Eusthenopteron: life is still in the water
		atmo = { Density = 0.55, Color = rgb(40, 140, 160), Decay = rgb(20, 70, 110), Haze = 2.5, Glare = 0 },
		tint = rgb(170, 225, 235), sat = -0.1, ground = rgb(196, 184, 140), hide = { Tree = true },
		leaf = rgb(70, 110, 60), bush = { rgb(240, 120, 110), rgb(250, 170, 90), rgb(200, 110, 190) } }, -- palms = kelp, bushes = coral
	{ upto = 16, name = "First Forests", -- Tiktaalik .. Pederpes: fern forests and swamps
		atmo = { Density = 0.5, Color = rgb(140, 165, 130), Decay = rgb(70, 95, 65), Haze = 2.5, Glare = 0 },
		tint = rgb(205, 230, 200), sat = -0.25, ground = rgb(45, 75, 35), hide = { Tree = true },
		leaf = rgb(50, 110, 55), bush = { rgb(60, 100, 50) } },
	{ upto = 29, name = "Age of Reptiles", -- warm, hazy, no flowers yet
		atmo = { Density = 0.38, Color = rgb(220, 190, 150), Decay = rgb(170, 120, 90), Haze = 1.8, Glare = 0.3 },
		tint = rgb(255, 225, 190), sat = -0.1, ground = rgb(115, 115, 55), leaf = rgb(40, 90, 40), bush = { rgb(70, 100, 45) } },
	{ upto = 37, name = "Savanna", -- apes and the first humans: dry grassland
		atmo = { Density = 0.32, Color = rgb(235, 215, 170), Decay = rgb(200, 160, 110), Haze = 1.2, Glare = 0.2 },
		tint = rgb(255, 240, 215), sat = -0.15, ground = rgb(165, 140, 75), hide = { Palm = true },
		leaf = rgb(110, 125, 50), bush = { rgb(140, 125, 65) } },
	{ upto = 60, name = "Today" }, -- the map as built
	{ upto = math.huge, name = "Future", clock = 17.6, -- imagined: neon dusk
		atmo = { Density = 0.35, Color = rgb(120, 90, 200), Decay = rgb(60, 40, 120), Haze = 1.5, Glare = 0.5 },
		tint = rgb(225, 220, 255), sat = 0, ground = rgb(80, 90, 140),
		leaf = { rgb(60, 200, 220), rgb(220, 90, 200) }, bush = { rgb(140, 90, 230) } }, -- Neon blew out in testing: pastel instead
}

-- the map's own look, to return to
local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
local baseAtmo = atmo and { Density = atmo.Density, Color = atmo.Color, Decay = atmo.Decay, Haze = atmo.Haze, Glare = atmo.Glare }
local baseClock = Lighting.ClockTime
local baseGround = terrain:GetMaterialColor(Enum.Material.Grass)
local parts, n = {}, 0 -- [part] = { kind, role, color, material, transparency, collide, i }
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "EraTint"
tint.Parent = Lighting

local current
local function style(p, o) -- one part in the current era
	local era = current
	local hidden = era.hide and era.hide[o.kind]
	p.Transparency = hidden and 1 or o.transparency
	p.CanCollide = not hidden and o.collide -- local only: you walk through what your era doesn't have
	p.CastShadow = not hidden
	local function pick(list) return typeof(list) == "Color3" and list or list[o.i % #list + 1] end
	if o.role == "leaf" and era.leaf then
		p.Color, p.Material = pick(era.leaf), era.neon and Enum.Material.Neon or o.material
	elseif o.role == "bush" and era.bush then
		p.Color, p.Material = pick(era.bush), era.neon and Enum.Material.Neon or o.material
	else
		p.Color, p.Material = o.color, o.material
	end
end
local function register(p) -- the map streams in and out, so parts arrive late
	if not p:IsA("BasePart") or parts[p] then return end
	local m = p.Parent == world and p or p:FindFirstAncestorWhichIsA("Model")
	if not m then return end
	n += 1
	local role = m.Name == "Bush" and "bush" or (p.Material == Enum.Material.Grass and "leaf") or "other"
	parts[p] = { kind = m.Name, role = role, color = p.Color, material = p.Material, transparency = p.Transparency, collide = p.CanCollide, i = n }
	if current then style(p, parts[p]) end
end
-- Era props: each era's own plants and landmarks, built from parts on this client only (human eras use the server's town).
local Y = CFrame.Angles
local function piece(m, size, color, cf, shape, mat, transp, oval)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, size.Magnitude > 6
	p.Size, p.Color, p.CFrame, p.TopSurface, p.BottomSurface = size, color, cf, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Material, p.Transparency = mat or Enum.Material.SmoothPlastic, transp or 0
	if oval then Instance.new("SpecialMesh", p).MeshType = Enum.MeshType.Sphere elseif shape then p.Shape = shape end
	p.Parent = m
end
local BALL, CYL = Enum.PartType.Ball, Enum.PartType.Cylinder
local UP = Y(0, 0, math.pi / 2) -- a Cylinder's length is X: this stands it up
local PROPS = {
	kelp = function(m, cf, r)
		local h = r:NextNumber(10, 22)
		for k = 0, 5 do
			piece(m, Vector3.new(0.6, h / 6 + 0.5, 1.3), k % 2 == 0 and rgb(70, 110, 50) or rgb(95, 120, 45), cf * CFrame.new(math.sin(k * 0.9) * 0.7, h / 6 * (k + 0.5), 0) * Y(0, 0, math.sin(k) * 0.15))
		end
		piece(m, Vector3.new(0.4, 2.5, 1.6), rgb(110, 140, 55), cf * CFrame.new(0.6, h, 0) * Y(0, 0, -0.5), nil, nil, nil, true)
	end,
	coral = function(m, cf, r)
		local c = ({ rgb(240, 120, 110), rgb(250, 170, 90), rgb(200, 110, 190) })[r:NextInteger(1, 3)]
		for k = -1, 1 do piece(m, Vector3.new(0.4, r:NextNumber(4, 7), r:NextNumber(4, 6)), c, cf * Y(0, k * 0.6 + r:NextNumber(), 0) * CFrame.new(0, 2.5, 0), nil, nil, nil, true) end
	end,
	anemone = function(m, cf, r)
		local c = ({ rgb(250, 150, 60), rgb(170, 110, 220), rgb(240, 110, 150) })[r:NextInteger(1, 3)]
		piece(m, Vector3.new(1.6, 2.4, 2.4), c:Lerp(Color3.new(0, 0, 0), 0.3), cf * CFrame.new(0, 0.8, 0) * UP, CYL)
		for k = 1, 7 do
			local a = k / 7 * math.pi * 2
			piece(m, Vector3.new(0.35, 1.6, 0.35), c, cf * CFrame.new(math.cos(a) * 0.8, 2.2, math.sin(a) * 0.8) * Y(math.sin(a) * 0.4, 0, -math.cos(a) * 0.4))
		end
	end,
	clubmoss = function(m, cf, r) -- Lepidodendron: a tall scaly pole that forks at the top
		local h = r:NextNumber(18, 28)
		piece(m, Vector3.new(h, 1.6, 1.6), rgb(85, 95, 60), cf * CFrame.new(0, h / 2, 0) * UP, CYL, Enum.Material.Wood)
		for _, s in { -1, 1 } do
			local top = cf * CFrame.new(s * 1.6, h + 1.6, 0) * Y(0, 0, -s * 0.6)
			piece(m, Vector3.new(4, 0.9, 0.9), rgb(85, 95, 60), top * UP, CYL, Enum.Material.Wood)
			piece(m, Vector3.new(3, 4, 3), rgb(60, 110, 50), top * CFrame.new(0, 2.5, 0), nil, Enum.Material.Grass, nil, true)
		end
	end,
	treefern = function(m, cf, r)
		local h = r:NextNumber(6, 10)
		piece(m, Vector3.new(h, 1.2, 1.2), rgb(80, 60, 40), cf * CFrame.new(0, h / 2, 0) * UP, CYL, Enum.Material.Wood)
		for k = 1, 8 do
			piece(m, Vector3.new(1.4, 0.3, 7), rgb(55, 120, 50), cf * CFrame.new(0, h, 0) * Y(0, k / 8 * math.pi * 2, 0) * Y(-0.45, 0, 0) * CFrame.new(0, 0, -3.2), nil, Enum.Material.Grass, nil, true)
		end
	end,
	horsetail = function(m, cf, r)
		for _ = 1, 5 do
			local h = r:NextNumber(5, 10)
			local o = CFrame.new(r:NextNumber(-1.5, 1.5), 0, r:NextNumber(-1.5, 1.5))
			piece(m, Vector3.new(h, 0.5, 0.5), rgb(110, 140, 60), cf * o * CFrame.new(0, h / 2, 0) * UP, CYL)
			piece(m, Vector3.new(0.7, 1.4, 0.7), rgb(140, 110, 70), cf * o * CFrame.new(0, h + 0.5, 0), nil, nil, nil, true)
		end
	end,
	cycad = function(m, cf, r)
		piece(m, Vector3.new(2.6, 4, 2.6), rgb(120, 95, 60), cf * CFrame.new(0, 1.8, 0), nil, Enum.Material.Wood, nil, true)
		for k = 1, 10 do
			piece(m, Vector3.new(1, 0.3, 6), k % 2 == 0 and rgb(55, 100, 45) or rgb(70, 115, 50), cf * CFrame.new(0, 3.6, 0) * Y(0, k / 10 * math.pi * 2, 0) * Y(0.5, 0, 0) * CFrame.new(0, 0, -2.8), nil, Enum.Material.Grass, nil, true)
		end
	end,
	araucaria = function(m, cf, r) -- monkey-puzzle conifer: flat tiers on a tall pole
		local h = r:NextNumber(20, 30)
		piece(m, Vector3.new(h, 1.3, 1.3), rgb(95, 70, 50), cf * CFrame.new(0, h / 2, 0) * UP, CYL, Enum.Material.Wood)
		for k = 0, 3 do
			local w = 12 - k * 2.6
			piece(m, Vector3.new(1.2, w, w), rgb(40, 80, 45), cf * CFrame.new(0, h * 0.55 + k * h * 0.14, 0) * UP, CYL, Enum.Material.Grass)
		end
	end,
	acacia = function(m, cf, r)
		local h = r:NextNumber(9, 13)
		for _, s in { -1, 1 } do piece(m, Vector3.new(h, 0.9, 0.9), rgb(90, 70, 50), cf * CFrame.new(s * 1.2, h / 2, 0) * Y(0, 0, s * 0.18) * UP, CYL, Enum.Material.Wood) end
		piece(m, Vector3.new(r:NextNumber(13, 17), 2.4, r:NextNumber(11, 14)), rgb(95, 115, 45), cf * CFrame.new(0, h + 0.6, 0), nil, Enum.Material.Grass, nil, true)
	end,
	mound = function(m, cf, r) -- termite mound
		local h = r:NextNumber(5, 9)
		piece(m, Vector3.new(3.2, h, 3.2), rgb(175, 125, 75), cf * CFrame.new(0, h * 0.4, 0), nil, Enum.Material.Sand, nil, true)
		piece(m, Vector3.new(1.8, h * 0.6, 1.8), rgb(160, 115, 70), cf * CFrame.new(1.3, h * 0.3, 0.5), nil, Enum.Material.Sand, nil, true)
	end,
	tuft = function(m, cf, r)
		for k = 1, 5 do piece(m, Vector3.new(0.3, r:NextNumber(1.5, 2.5), 0.3), rgb(205, 185, 105), cf * Y(0, k * 1.3, 0) * CFrame.new(0.3, 0.9, 0) * Y(0, 0, 0.3)) end
	end,
	dome = function(m, cf, r)
		local d = r:NextNumber(10, 18)
		piece(m, Vector3.new(1, d + 2, d + 2), rgb(235, 235, 245), cf * CFrame.new(0, 0.5, 0) * UP, CYL)
		piece(m, Vector3.one * d, rgb(200, 220, 255), cf, BALL, Enum.Material.Glass, 0.35)
	end,
	pylon = function(m, cf, r)
		local h = r:NextNumber(12, 20)
		piece(m, Vector3.new(h, 0.8, 0.8), rgb(235, 235, 245), cf * CFrame.new(0, h / 2, 0) * UP, CYL)
		piece(m, Vector3.one * 2, ({ rgb(150, 220, 230), rgb(225, 160, 220) })[r:NextInteger(1, 2)], cf * CFrame.new(0, h + 1, 0), BALL)
	end,
}
local LANDMARKS = { -- one big thing far out, so the era reads from anywhere
	volcano = function(m)
		local base = CFrame.new(40, 0, -360)
		for k = 0, 11 do piece(m, Vector3.new(8, 150 - k * 11, 150 - k * 11), rgb(80 - k * 2, 70 - k * 2, 65 - k * 2), base * CFrame.new(0, 4 + k * 6.5, 0) * UP, CYL, Enum.Material.Slate) end
		piece(m, Vector3.new(2, 28, 28), rgb(230, 90, 40), base * CFrame.new(0, 76.5, 0) * UP, CYL) -- no Neon: it blew out in testing
		for k = 1, 4 do piece(m, Vector3.one * (16 + k * 6), rgb(120, 115, 110), base * CFrame.new(k * 6, 80 + k * 16, 0), BALL, nil, 0.35) end
	end,
}
local ERA_PROPS = { -- what each era scatters, and how many
	["Ancient Sea"] = { kelp = 45, coral = 25, anemone = 25 },
	["First Forests"] = { clubmoss = 35, treefern = 35, horsetail = 30 },
	["Age of Reptiles"] = { cycad = 40, araucaria = 25, landmark = "volcano" },
	["Savanna"] = { acacia = 30, mound = 20, tuft = 50 },
	["Future"] = { dome = 14, pylon = 20 },
}
local propFolders = {}
local ground = RaycastParams.new()
ground.FilterType = Enum.RaycastFilterType.Include
ground.FilterDescendantsInstances = { terrain, workspace:FindFirstChild("Baseplate") }
local function buildProps(era)
	local list = ERA_PROPS[era.name]
	local folder = Instance.new("Folder")
	folder.Name = "EraProps_" .. era.name
	if not list then return folder end
	local r = Random.new(#era.name * 7919) -- same layout every time
	for kind, count in list do
		if kind == "landmark" then LANDMARKS[count](folder) continue end
		for _ = 1, count do
			local a, d = r:NextNumber(0, math.pi * 2), r:NextNumber(35, 245)
			local x, z = math.cos(a) * d, math.sin(a) * d
			-- shortcut: terrain far away may not be streamed in yet; then the prop sits at the flat ground height (y = 1)
			local hit = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), ground)
			if hit and hit.Material == Enum.Material.Water then continue end
			local m = Instance.new("Model")
			PROPS[kind](m, CFrame.new(x, hit and hit.Position.Y - 0.3 or 1, z) * Y(0, r:NextNumber(0, math.pi * 2), 0), r)
			m.Parent = folder
		end
	end
	return folder
end
local function showProps(era)
	for e, f in propFolders do f.Parent = e == era and workspace or nil end
	if not propFolders[era] then
		propFolders[era] = buildProps(era)
		propFolders[era].Parent = workspace
	end
end

-- Swimming: in the sea world you sink slowly, and every jump press (Space or the phone jump button) is a stroke upward.
local baseGravity = workspace.Gravity
local SEA_GRAVITY, STROKE, SINK, SURFACE = 35, 22, 7, 90 -- a stroke lifts about 7 studs, you sink at 7 studs/s, nobody swims above y = 90
local lastStroke = 0
game:GetService("UserInputService").JumpRequest:Connect(function()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if current ~= ERAS[1] or not root or root.Position.Y > SURFACE or os.clock() - lastStroke < 0.25 then return end
	lastStroke = os.clock()
	local v = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(v.X, STROKE, v.Z)
end)
-- Swim pose: the server welds each body part ("Form") to the root. On this client those become Welds we can turn,
-- so the body tips nose-up when rising, nose-down when sinking, and wiggles while moving. Only you see it.
-- shortcut: offsets are taken once per part; if body parts are ever resized after spawn (R6 ScaleTo), re-take them.
local swimWelds = {} -- [Weld] = C0 at rest
local function hookCharacter(char)
	table.clear(swimWelds)
	local root = char:WaitForChild("HumanoidRootPart")
	local function take(wc)
		if not (wc:IsA("WeldConstraint") and wc.Part0 == root and wc.Part1 and wc.Part1.Name == "Form") then return end
		local w = Instance.new("Weld")
		w.Part0, w.Part1, w.C0 = root, wc.Part1, root.CFrame:ToObjectSpace(wc.Part1.CFrame)
		w.Parent = wc.Part1
		wc.Enabled = false
		swimWelds[w] = w.C0
	end
	for _, d in char:GetDescendants() do take(d) end
	char.DescendantAdded:Connect(take)
end
if player.Character then task.spawn(hookCharacter, player.Character) end
player.CharacterAdded:Connect(hookCharacter)
local pitch, posed = 0, false
game:GetService("RunService").Heartbeat:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local sea, v = current == ERAS[1], root.AssemblyLinearVelocity
	if sea and v.Y < -SINK then root.AssemblyLinearVelocity = Vector3.new(v.X, -SINK, v.Z) end -- water drag: sink, don't drop
	if not sea and not posed then return end
	pitch += ((sea and math.clamp(v.Y / STROKE, -1, 1) * 0.4 or 0) - pitch) * math.min(dt * 6, 1)
	local wiggle = (sea and Vector3.new(v.X, 0, v.Z).Magnitude > 2) and math.sin(os.clock() * 8) * 0.12 or 0
	posed = sea or math.abs(pitch) > 0.01
	local turn = posed and CFrame.Angles(pitch, wiggle, 0) or CFrame.identity
	for w, c0 in swimWelds do
		if w.Parent then w.C0 = turn * c0 else swimWelds[w] = nil end
	end
end)

local function apply(era)
	if era == current then return end
	current = era
	showProps(era)
	workspace.Gravity = era == ERAS[1] and SEA_GRAVITY or baseGravity -- local: only your own character feels it
	local fade = TweenInfo.new(2)
	if atmo then TweenService:Create(atmo, fade, era.atmo or baseAtmo):Play() end
	TweenService:Create(tint, fade, { TintColor = era.tint or Color3.new(1, 1, 1), Saturation = era.sat or 0 }):Play()
	TweenService:Create(Lighting, fade, { ClockTime = era.clock or baseClock }):Play()
	terrain:SetMaterialColor(Enum.Material.Grass, era.ground or baseGround)
	for p, o in parts do
		if p.Parent then style(p, o) else parts[p] = nil end
	end
end
for _, p in world:GetDescendants() do register(p) end
world.DescendantAdded:Connect(register)
local function eraOf(depth)
	for _, e in ERAS do if depth <= e.upto then return e end end
	return ERAS[#ERAS]
end
-- Sea branches stay in the sea at any depth (a whale in the Ice Age still sees the ocean). Path = "F1=Fish,...,F5=Whales": newest last.
local SEA = { Sharks = true, TrueSharks = true, Rays = true, RayFins = true, Coelacanths = true, Whales = true, SeaReptiles = true,
	Jellies = true, Sponges = true, Echinoderms = true, Cephalopods = true, Clams = true, Crustaceans = true }
local function refresh()
	local lane = (player:GetAttribute("Path") or ""):match("=(%w+)$")
	apply(SEA[lane] and ERAS[1] or eraOf(player:GetAttribute("StageNum") or 1))
end
player:GetAttributeChangedSignal("StageNum"):Connect(refresh)
player:GetAttributeChangedSignal("Path"):Connect(refresh)
refresh()
