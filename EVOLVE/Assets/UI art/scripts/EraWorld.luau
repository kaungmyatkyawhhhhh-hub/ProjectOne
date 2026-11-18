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
local function apply(era)
	if era == current then return end
	current = era
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
