--[[
	GemShowcase (server)
	The Legends Gem Showcase on Legends Boulevard, Downtown (owner, 2026-10-22: rare, visible flex
	items like custom gems and accessories, and you can steal from it).
	  * Outside: a white stone gallery with a gold-framed glass front, a gold awning, the name in
	    gold, a glowing diamond on the roof, palms and a giant turning gem over a reflecting pool.
	  * Inside: white marble and gold, chandeliers, twelve lit glass cases (necklaces on velvet
	    busts, crowns and shades on stands, watches on cushions, trays of loose stones) and, under
	    a glass dome at the back, the Legends Heart.
	  * Shopping: the concierge desk opens the shop (Luxe / LuxeClient): buy a piece and wear it.
	  * Smash-and-grab: smash a case (alarm, 3 stars), grab its stones into your bag; cutting the
	    dome for the Legends Heart is worth the most and brings 4 stars. Cash in at the bank's
	    drop-off. Smashed cases are mended and refilled after a while.

	CityBuilder calls GemShowcase.buildWorld(kit, parent) once Downtown is built; Main.server calls
	GemShowcase.init(ctx, Police, Luxe).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local Flex = require(Shared:WaitForChild("Flex"))
local Casino = require(script.Parent:WaitForChild("Casino"))

local L = Config.Luxe
local S = L.Showcase

local GemShowcase = {}

local STONE = Color3.fromRGB(238, 233, 224)
local STONE_DARK = Color3.fromRGB(200, 192, 180)
local MARBLE = Color3.fromRGB(244, 242, 238)
local BLACK = Color3.fromRGB(16, 14, 18)
local GOLD = Color3.fromRGB(226, 182, 84)
local VELVET = Color3.fromRGB(14, 12, 20)
local WARM = Color3.fromRGB(255, 226, 186)

local FLOOR = 1.2
local H = 30
local HX = 70
local Z_FRONT, Z_BACK = -40, 70

type Case = {
	model: Model,
	glass: BasePart,
	contents: Model,
	smash: ProximityPrompt,
	grab: ProximityPrompt,
	shards: ParticleEmitter,
	state: string, -- "whole" | "smashed" | "empty"
	smashedAt: number,
	showpiece: boolean,
}
local cases: { Case } = {}
local shopPrompt: ProximityPrompt? = nil
local alarm: Sound? = nil
local alarmLights: { Light } = {}
local alarmUntil = 0

local function prompt(parent: Instance, action: string, object: string, hold: number, range: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = range or 9
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.Parent = parent
	return p
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local f = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if f:sub(1, 1) == "," then
		f = f:sub(2)
	end
	return "$" .. f
end

-- a cut stone, standing on its point
local function stone(kit: any, parent: Instance, s: number, cf: CFrame, color: Color3): BasePart
	local g = kit.deco(parent, Vector3.new(s, s, s * 0.62), cf * CFrame.Angles(0, 0, math.rad(45)), color, Enum.Material.Neon, { transparency = 0.12 })
	return g
end

-- an item from the shop's catalogue, built round a display stand of the given size
local function display(kit: any, parent: Instance, itemId: string, at: CFrame)
	local item = Flex.ById[itemId]
	if not item then
		return
	end
	local deco = kit.deco
	local size: Vector3
	local origin: CFrame
	if item.slot == "Neck" then
		-- a black velvet bust
		size = Vector3.new(2.6, 2.2, 1.3)
		origin = at * CFrame.new(0, 1.6, 0)
		deco(parent, size, origin, VELVET, Enum.Material.Fabric)
		deco(parent, Vector3.new(0.9, 0.9, 0.9), origin * CFrame.new(0, size.Y / 2 + 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
	elseif item.slot == "Wrist" or item.slot == "Hand" then
		-- a velvet cushion with a roll the piece sits round (the roll lies along X; the piece's
		-- band runs round it, its face or stone on top)
		deco(parent, Vector3.new(3, 0.6, 2.2), at * CFrame.new(0, 0.3, 0), VELVET, Enum.Material.Fabric)
		local roll = if item.slot == "Wrist" then 0.8 else 0.3
		size = if item.slot == "Wrist" then Vector3.new(0.8, 1, 0.8) else Vector3.new(0.55, 0.6, 0.3)
		origin = at * CFrame.new(0, 0.6 + roll / 2, 0) * CFrame.Angles(0, 0, math.rad(-90))
		deco(parent, Vector3.new(2.4, roll, roll), at * CFrame.new(0, 0.6 + roll / 2, 0), VELVET, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
	else
		-- a head on a slim stand
		size = Vector3.new(1.3, 1.3, 1.3)
		origin = at * CFrame.new(0, 2.6, 0)
		deco(parent, Vector3.new(0.3, 2, 0.3), at * CFrame.new(0, 1, 0), GOLD, Enum.Material.Metal)
		deco(parent, size, origin, VELVET, Enum.Material.Fabric, { shape = Enum.PartType.Ball })
	end
	local m = Flex.build(item, size)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = origin * p.CFrame
		end
	end
	m.Parent = parent
	-- the price card
	local card = deco(parent, Vector3.new(2.6, 0.9, 0.08), at * CFrame.new(0, 0.5, -1.3) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(250, 248, 244), Enum.Material.SmoothPlastic)
	kit.surfaceText(card, Enum.NormalId.Front, item.name .. "\n" .. money(item.price), Color3.fromRGB(60, 46, 20), nil, nil, Enum.Font.Garamond, Vector2.new(260, 90))
end

-- a lit glass case: a black plinth, a glass box with what's for show inside
local function glassCase(kit: any, parent: Instance, cf: CFrame, w: number, d: number, fill: (contents: Model, top: CFrame) -> (), name: string): Case
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	local plinthH = 3.4
	mk(model, Vector3.new(w, plinthH, d), cf * CFrame.new(0, plinthH / 2, 0), BLACK, Enum.Material.Marble, { name = "Plinth" })
	deco(model, Vector3.new(w + 0.2, 0.25, d + 0.2), cf * CFrame.new(0, plinthH, 0), GOLD, Enum.Material.Metal)
	deco(model, Vector3.new(w - 0.6, 0.08, d - 0.6), cf * CFrame.new(0, plinthH + 0.16, 0), Color3.fromRGB(26, 20, 36), Enum.Material.Fabric)
	local glassH = 4.6
	local glass = mk(model, Vector3.new(w, glassH, d), cf * CFrame.new(0, plinthH + glassH / 2 + 0.1, 0), Color3.fromRGB(230, 244, 255), Enum.Material.Glass, { transparency = 0.82, reflectance = 0.15, name = "Glass" })
	-- gold corner posts and a lit top
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(model, Vector3.new(0.18, glassH, 0.18), cf * CFrame.new(sx * w / 2, plinthH + glassH / 2 + 0.1, sz * d / 2), GOLD, Enum.Material.Metal)
		end
	end
	local lid = deco(model, Vector3.new(w + 0.1, 0.3, d + 0.1), cf * CFrame.new(0, plinthH + glassH + 0.25, 0), GOLD, Enum.Material.Metal)
	kit.addLight("SpotLight", lid, Color3.fromRGB(255, 244, 228), 9, 3, Enum.NormalId.Bottom, 90)
	local contents = Instance.new("Model")
	contents.Name = "Contents"
	contents.Parent = model
	fill(contents, cf * CFrame.new(0, plinthH + 0.2, 0))
	-- shards for when it's smashed
	local shards = Instance.new("ParticleEmitter")
	shards.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	shards.LightEmission = 0.4
	shards.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.1) })
	shards.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	shards.Lifetime = NumberRange.new(0.6, 1.2)
	shards.Speed = NumberRange.new(10, 18)
	shards.SpreadAngle = Vector2.new(180, 180)
	shards.Acceleration = Vector3.new(0, -60, 0)
	shards.Rotation = NumberRange.new(0, 360)
	shards.RotSpeed = NumberRange.new(-300, 300)
	shards.Rate = 0
	shards.Parent = glass
	local smash = prompt(glass, "Smash the case", "Legends Gem Showcase", S.SmashSeconds, 8)
	local grab = prompt(glass, "Grab the stones", "Legends Gem Showcase", S.GrabSeconds, 8)
	grab.Enabled = false
	local c: Case = { model = model, glass = glass, contents = contents, smash = smash, grab = grab, shards = shards, state = "whole", smashedAt = 0, showpiece = false }
	table.insert(cases, c)
	return c
end

local GEM_COLORS = { "diamond", "emerald", "sapphire", "ruby", "pink" }

local function looseStones(kit: any, contents: Model, top: CFrame, w: number, d: number, seed: number)
	local rng = Random.new(seed)
	-- velvet trays of stones in rows
	for row = -1, 1, 2 do
		kit.deco(contents, Vector3.new(w * 0.8, 0.2, d * 0.3), top * CFrame.new(0, 0.1, row * d * 0.2), VELVET, Enum.Material.Fabric)
		for k = 0, 4 do
			local x = (k - 2) * w * 0.16
			local col = L.GemColors[GEM_COLORS[rng:NextInteger(1, #GEM_COLORS)]]
			stone(kit, contents, rng:NextNumber(0.35, 0.6), top * CFrame.new(x, 0.55, row * d * 0.2), col)
		end
	end
end

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
local function build(kit: any, parent: Instance, base: CFrame, lot: number)
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = "LegendsGemShowcase"
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the front (the street)
	end
	local half = lot / 2
	local inside = kit.lodGroup(model, "ShowcaseInterior", base.Position, 600)

	-- plaza, palms, the giant turning gem over a reflecting pool
	mk(model, Vector3.new(lot, 0.3, lot), at(0, 0.15, 0), Color3.fromRGB(214, 208, 198), Enum.Material.Marble, { name = "Plaza" })
	local poolCF = at(0, 0.3, -half + 34)
	mk(model, Vector3.new(1.4, 34, 34), poolCF * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder, name = "Pool" })
	local water = deco(model, Vector3.new(0.2, 32, 32), poolCF * CFrame.new(0, 1.45, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 120, 220), Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
	water.Reflectance = 0.4
	mk(model, Vector3.new(6, 6, 6), poolCF * CFrame.new(0, 4, 0), BLACK, Enum.Material.Marble, { name = "Plinth" })
	deco(model, Vector3.new(6.3, 0.4, 6.3), poolCF * CFrame.new(0, 7, 0), GOLD, Enum.Material.Metal)
	local big = deco(model, Vector3.new(8, 8, 5), poolCF * CFrame.new(0, 13, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(150, 220, 255), Enum.Material.Neon, { transparency = 0.1 })
	big.Name = "SpinGem"
	big:SetAttribute("Home", big.CFrame)
	CollectionService:AddTag(big, "SpinGem")
	kit.addLight("PointLight", big, Color3.fromRGB(150, 220, 255), 40, 2)
	for _, s in { -1, 1 } do
		for k, z in { -half + 8, -half + 44, Z_FRONT - 6, 0, 40, half - 10 } do
			Casino.palm(kit, model, at(s * (half - 10), 0.3, z).Position, 28 + (k % 3) * 4, 400 + k * 13 + (if s > 0 then 5 else 0))
		end
		local lamp = deco(model, Vector3.new(1.6, 1, 1.6), at(s * 50, 0.8, Z_FRONT - 6), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, WARM, 60, 2.6, Enum.NormalId.Top, 45)
	end
	-- steps and bollards at the doors
	mk(model, Vector3.new(40, 0.6, 4), at(0, 0.6, Z_FRONT - 3), STONE, Enum.Material.Marble)
	for x = -10, 10, 4 do
		mk(model, Vector3.new(2.4, 1.3, 1.3), at(x, 1.5, Z_FRONT - 7) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Bollard" })
	end

	-- floor, walls, roof
	mk(model, Vector3.new(HX * 2, FLOOR, Z_BACK - Z_FRONT), at(0, FLOOR / 2, (Z_FRONT + Z_BACK) / 2), STONE_DARK, Enum.Material.Limestone, { name = "Floor" })
	deco(inside, Vector3.new(HX * 2 - 4, 0.06, Z_BACK - Z_FRONT - 4), at(0, FLOOR + 0.03, (Z_FRONT + Z_BACK) / 2), MARBLE, Enum.Material.Marble)
	-- black marble border lines
	for _, s in { -1, 1 } do
		deco(inside, Vector3.new(1, 0.07, Z_BACK - Z_FRONT - 10), at(s * 26, FLOOR + 0.05, (Z_FRONT + Z_BACK) / 2), BLACK, Enum.Material.Marble)
	end
	deco(inside, Vector3.new(53, 0.07, 1), at(0, FLOOR + 0.05, Z_FRONT + 6), BLACK, Enum.Material.Marble)
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(3, H, Z_BACK - Z_FRONT), at(s * (HX - 1.5), FLOOR + H / 2, (Z_FRONT + Z_BACK) / 2), STONE, Enum.Material.Limestone, { name = "Wall" })
		-- slender lit windows down the sides
		for z = Z_FRONT + 12, Z_BACK - 10, 14 do
			deco(model, Vector3.new(0.3, 16, 3), at(s * (HX + 0.05), FLOOR + 12, z), Color3.fromRGB(255, 220, 170), Enum.Material.Glass, { transparency = 0.2 })
			deco(model, Vector3.new(0.5, 17, 0.6), at(s * (HX + 0.2), FLOOR + 12, z - 1.8), GOLD, Enum.Material.Metal)
			deco(model, Vector3.new(0.5, 17, 0.6), at(s * (HX + 0.2), FLOOR + 12, z + 1.8), GOLD, Enum.Material.Metal)
		end
	end
	mk(model, Vector3.new(HX * 2, H, 3), at(0, FLOOR + H / 2, Z_BACK - 1.5), STONE, Enum.Material.Limestone, { name = "Wall" })
	-- the glass front in a gold frame, the doors in the middle
	local doorHalf, doorH = 10, 16
	local glassTop = 22
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(HX - doorHalf, glassTop, 1.2), at(s * (HX + doorHalf) / 2, FLOOR + glassTop / 2, Z_FRONT), Color3.fromRGB(200, 214, 226), Enum.Material.Glass, { transparency = 0.45, reflectance = 0.2, name = "Facade" })
	end
	mk(model, Vector3.new(doorHalf * 2, glassTop - doorH, 1.2), at(0, FLOOR + doorH + (glassTop - doorH) / 2, Z_FRONT), Color3.fromRGB(200, 214, 226), Enum.Material.Glass, { transparency = 0.45, reflectance = 0.2, name = "Facade" })
	for x = -HX + 3, HX - 3, 7 do
		if math.abs(x) > doorHalf then
			deco(model, Vector3.new(0.6, glassTop, 1.4), at(x, FLOOR + glassTop / 2, Z_FRONT - 0.3), GOLD, Enum.Material.Metal)
		end
	end
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(1, doorH, 1.6), at(s * doorHalf, FLOOR + doorH / 2, Z_FRONT), GOLD, Enum.Material.Metal)
	end
	deco(model, Vector3.new(HX * 2, 0.8, 1.6), at(0, FLOOR + doorH, Z_FRONT - 0.2), GOLD, Enum.Material.Metal)
	-- the stone band with the name
	local band = mk(model, Vector3.new(HX * 2 + 2, H - glassTop, 2.4), at(0, FLOOR + glassTop + (H - glassTop) / 2, Z_FRONT - 0.4), STONE, Enum.Material.Limestone, { name = "NameBand" })
	kit.surfaceText(band, Enum.NormalId.Front, "LEGENDS  GEM  SHOWCASE", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(1800, 110))
	deco(model, Vector3.new(HX * 2 + 3, 0.6, 3), at(0, FLOOR + glassTop + 0.3, Z_FRONT - 0.4), GOLD, Enum.Material.Metal)
	deco(model, Vector3.new(HX * 2 + 4, 1.2, 3.4), at(0, FLOOR + H + 0.6, Z_FRONT - 0.4), STONE_DARK, Enum.Material.Limestone)
	-- the gold awning over the doors
	local awning = mk(model, Vector3.new(28, 0.8, 10), at(0, FLOOR + doorH + 1.4, Z_FRONT - 5), GOLD, Enum.Material.Metal, { name = "Awning" })
	kit.addLight("SpotLight", awning, WARM, 24, 2.4, Enum.NormalId.Bottom, 90)
	-- roof, parapet, the glowing diamond on top
	mk(model, Vector3.new(HX * 2, 2, Z_BACK - Z_FRONT), at(0, FLOOR + H + 1, (Z_FRONT + Z_BACK) / 2), STONE_DARK, Enum.Material.Limestone, { name = "Roof" })
	local dc = at(0, FLOOR + H + 16, Z_FRONT + 6)
	for k = 0, 3 do
		local a = math.rad(45 + k * 90)
		local mid = dc * CFrame.new(math.cos(a) * 6, math.sin(a) * 6, 0)
		deco(model, Vector3.new(12.6, 1.2, 1.2), mid * CFrame.Angles(0, 0, a + math.rad(90)), Color3.fromRGB(160, 230, 255), Enum.Material.Neon)
	end
	deco(model, Vector3.new(12, 0.8, 0.8), dc * CFrame.new(0, 2.5, 0), Color3.fromRGB(160, 230, 255), Enum.Material.Neon)

	-- inside: a white coffered ceiling with chandeliers
	deco(inside, Vector3.new(HX * 2 - 4, 0.5, Z_BACK - Z_FRONT - 4), at(0, FLOOR + H - 1, (Z_FRONT + Z_BACK) / 2), Color3.fromRGB(246, 242, 236), Enum.Material.SmoothPlastic)
	for x = -HX + 12, HX - 12, 16 do
		deco(inside, Vector3.new(0.6, 1, Z_BACK - Z_FRONT - 8), at(x, FLOOR + H - 1.6, (Z_FRONT + Z_BACK) / 2), GOLD, Enum.Material.Metal)
	end
	for _, z in { -14, 18, 46 } do
		local ch = at(0, FLOOR + H - 8, z)
		local hub = deco(inside, Vector3.new(2, 2, 2), ch, GOLD, Enum.Material.Metal)
		deco(inside, Vector3.new(0.2, 6, 0.2), ch * CFrame.new(0, 4, 0), GOLD, Enum.Material.Metal)
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2
			deco(inside, Vector3.new(0.4, 2.6, 0.4), ch * CFrame.new(math.cos(a) * 4.5, -1.4, math.sin(a) * 4.5), Color3.fromRGB(240, 248, 255), Enum.Material.Glass, { transparency = 0.15, reflectance = 0.5 })
			deco(inside, Vector3.one * 0.4, ch * CFrame.new(math.cos(a) * 4.5, 0, math.sin(a) * 4.5), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		end
		kit.addLight("PointLight", hub, WARM, 40, 1.4)
	end

	-- the cases: four along each side wall, four islands in the middle
	local wallShow = { "pendant_midnight", "crown_imperial", "cuban_iced", "watch_tourbillon", "pendant_emerald", "crown_gold", "shades_iced", "ring_black" }
	local k = 0
	for _, s in { -1, 1 } do
		for _, z in { -22, -4, 14, 32 } do
			k += 1
			local cf = at(s * (HX - 7), FLOOR, z) * CFrame.Angles(0, if s < 0 then math.rad(-90) else math.rad(90), 0)
			local show = wallShow[k]
			glassCase(kit, inside, cf, 12, 6, function(contents, top)
				display(kit, contents, show, top * CFrame.new(-2.6, 0, 0.6))
				looseStones(kit, contents, top * CFrame.new(3.2, 0, 0), 4.6, 5, k * 17)
			end, "WallCase" .. k)
		end
	end
	local islandShow = { "watch_iced", "studs_pink", "ring_ruby", "pendant_legend" }
	local n = 0
	for _, z in { 0, 24 } do
		for _, x in { -16, 16 } do
			n += 1
			local show = islandShow[n]
			glassCase(kit, inside, at(x, FLOOR, z), 9, 9, function(contents, top)
				display(kit, contents, show, top * CFrame.new(0, 0, -1.4))
				looseStones(kit, contents, top * CFrame.new(0, 0, 2.6), 7, 3, 300 + n)
			end, "IslandCase" .. n)
		end
	end

	-- the showpiece: the Legends Heart under a glass dome, red lasers round it
	local sp = at(0, FLOOR, 54)
	local spModel = Instance.new("Model")
	spModel.Name = "Showpiece"
	spModel.Parent = inside
	mk(spModel, Vector3.new(4, 9, 9), sp * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, Enum.Material.Marble, { shape = Enum.PartType.Cylinder, name = "Plinth" })
	deco(spModel, Vector3.new(0.4, 9.4, 9.4), sp * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local dome = mk(spModel, Vector3.new(8, 8, 8), sp * CFrame.new(0, 4.2, 0), Color3.fromRGB(230, 244, 255), Enum.Material.Glass, { shape = Enum.PartType.Ball, transparency = 0.8, reflectance = 0.2, name = "Glass" })
	local heartContents = Instance.new("Model")
	heartContents.Name = "Contents"
	heartContents.Parent = spModel
	local heart = deco(heartContents, Vector3.new(2.6, 2.6, 1.6), sp * CFrame.new(0, 6.4, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 90, 170), Enum.Material.Neon, { transparency = 0.05 })
	heart.Name = "SpinGem"
	heart:SetAttribute("Home", heart.CFrame)
	CollectionService:AddTag(heart, "SpinGem")
	kit.addLight("PointLight", heart, Color3.fromRGB(255, 90, 170), 18, 2.2)
	local hs = Instance.new("Sparkles")
	hs.SparkleColor = Color3.fromRGB(255, 160, 210)
	hs.Parent = heart
	for j = 0, 11 do
		local a = j / 12 * math.pi * 2
		deco(spModel, Vector3.new(0.12, 0.12, 4.4), sp * CFrame.new(math.cos(a) * 9, 1.4, math.sin(a) * 9) * CFrame.Angles(0, -a, 0), Color3.fromRGB(255, 20, 30), Enum.Material.Neon)
	end
	local plaque = deco(spModel, Vector3.new(6, 1.4, 0.1), sp * CFrame.new(0, 1.6, -4.6), Color3.fromRGB(250, 248, 244), Enum.Material.SmoothPlastic)
	kit.surfaceText(plaque, Enum.NormalId.Front, "THE LEGENDS HEART  ·  NOT FOR SALE", Color3.fromRGB(60, 46, 20), nil, nil, Enum.Font.Garamond, Vector2.new(500, 70))
	local spot = deco(spModel, Vector3.new(2, 0.3, 2), sp * CFrame.new(0, H - 2, 0), WARM, Enum.Material.Neon)
	kit.addLight("SpotLight", spot, Color3.fromRGB(255, 240, 230), 34, 3, Enum.NormalId.Bottom, 30)
	local shards = Instance.new("ParticleEmitter")
	shards.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
	shards.Size = NumberSequence.new(0.3)
	shards.Lifetime = NumberRange.new(0.6, 1.2)
	shards.Speed = NumberRange.new(10, 18)
	shards.SpreadAngle = Vector2.new(180, 180)
	shards.Acceleration = Vector3.new(0, -60, 0)
	shards.Rate = 0
	shards.Parent = dome
	local cut = prompt(dome, "Cut the glass dome", "The Legends Heart", S.ShowpieceSeconds, 9)
	local take = prompt(dome, "Take the Legends Heart", "The Legends Heart", S.GrabSeconds, 9)
	take.Enabled = false
	table.insert(cases, { model = spModel, glass = dome, contents = heartContents, smash = cut, grab = take, shards = shards, state = "whole", smashedAt = 0, showpiece = true })

	-- the concierge desk (the shop) with armchairs
	local desk = at(38, FLOOR, -24)
	mk(inside, Vector3.new(14, 3.8, 4), desk * CFrame.new(0, 1.9, 0), BLACK, Enum.Material.Marble, { name = "Concierge" })
	deco(inside, Vector3.new(14.4, 0.3, 4.4), desk * CFrame.new(0, 3.95, 0), GOLD, Enum.Material.Metal)
	local ds = deco(inside, Vector3.new(16, 3, 0.4), desk * CFrame.new(0, 10, 2.6), STONE, Enum.Material.Limestone)
	kit.surfaceText(ds, Enum.NormalId.Front, "CONCIERGE  ·  THE COLLECTION", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(700, 100))
	local shopPart = deco(inside, Vector3.new(2, 2, 2), desk * CFrame.new(0, 3, -3.4), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	shopPrompt = prompt(shopPart, "Browse the collection", "Legends Gem Showcase", 0, 10)
	for _, dx in { -5, 5 } do
		local chair = at(38 + dx, FLOOR, -12)
		deco(inside, Vector3.new(3.4, 1.6, 3.4), chair * CFrame.new(0, 1, 0), Color3.fromRGB(110, 14, 40), Enum.Material.Fabric)
		deco(inside, Vector3.new(3.4, 3, 0.8), chair * CFrame.new(0, 2.4, 1.4), Color3.fromRGB(110, 14, 40), Enum.Material.Fabric)
	end
	deco(inside, Vector3.new(2.4, 1.4, 2.4), at(38, FLOOR + 0.7, -12), GOLD, Enum.Material.Metal)

	-- the alarm
	local alarmPart = deco(model, Vector3.new(1, 1, 1), at(0, FLOOR + 16, 10), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	local snd = Instance.new("Sound")
	snd.Name = "Alarm"
	snd.SoundId = Config.Sounds.Alarm
	snd.Looped = true
	snd.Volume = 0.9
	snd.RollOffMaxDistance = 600
	snd.Parent = alarmPart
	alarm = snd
	for _, p in { { -HX + 5, -30 }, { HX - 5, -30 }, { -HX + 5, 60 }, { HX - 5, 60 } } do
		local bcn = deco(model, Vector3.new(1.2, 1.2, 1.2), at(p[1], FLOOR + H - 5, p[2]), Color3.fromRGB(120, 0, 0), Enum.Material.Glass)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 20, 20)
		l.Range = 40
		l.Brightness = 0
		l.Parent = bcn
		table.insert(alarmLights, l)
	end
end

-- builds the showcase on its Downtown site
function GemShowcase.buildWorld(kit: any, parent: Instance)
	local frame, lot = WestLayout.site("gems")
	build(kit, parent, frame, lot)
end

---------------------------------------------------------------------
-- The smash-and-grab
---------------------------------------------------------------------
local function setWhole(c: Case)
	c.state = "whole"
	c.glass.Transparency = if c.showpiece then 0.8 else 0.82
	c.glass.CanCollide = true
	c.contents.Parent = c.model
	c.smash.Enabled = true
	c.grab.Enabled = false
end

function GemShowcase.init(_ctx: any, Police: any, Luxe: any)
	if shopPrompt then
		shopPrompt.Triggered:Connect(function(who: Player)
			Luxe.fire(who, { kind = "openShop" })
		end)
	end
	for _, c in cases do
		c.smash.Triggered:Connect(function(who: Player)
			if c.state ~= "whole" then
				return
			end
			c.state = "smashed"
			c.smashedAt = os.clock()
			c.glass.Transparency = 1
			c.glass.CanCollide = false
			c.shards:Emit(if c.showpiece then 60 else 40)
			c.smash.Enabled = false
			c.grab.Enabled = true
			alarmUntil = os.clock() + 60
			if alarm and not alarm.IsPlaying then
				alarm:Play()
			end
			local stars = if c.showpiece then S.ShowpieceStars else S.Stars
			Police.setWanted(who, math.max(Police.getWanted(who), stars), "gems")
			if c.showpiece then
				Luxe.fireAll({ kind = "heartRobbery", by = who.DisplayName })
			else
				Luxe.fireAll({ kind = "gemsRobbery", by = who.DisplayName })
			end
		end)
		c.grab.Triggered:Connect(function(who: Player)
			if c.state ~= "smashed" then
				return
			end
			local carried = (who:GetAttribute("Loot") :: number?) or 0
			if carried >= S.MaxLoot then
				Luxe.fire(who, { kind = "full" })
				return
			end
			c.state = "empty"
			c.grab.Enabled = false
			c.contents.Parent = nil
			local amount = if c.showpiece then S.ShowpieceLoot else math.random(S.CaseMin, S.CaseMax)
			local total, added = Luxe.addLoot(who, Luxe.levelBoost(who, amount), S.MaxLoot)
			local stars = if c.showpiece then S.ShowpieceStars else S.Stars
			Police.setWanted(who, math.max(Police.getWanted(who), stars), "gems")
			Luxe.fire(who, { kind = "grab", amount = added, total = total, what = if c.showpiece then "THE LEGENDS HEART" else "STONES GRABBED" })
		end)
	end
	-- restocking, the alarm and its lights
	task.spawn(function()
		local blink = false
		while true do
			task.wait(0.25)
			local now = os.clock()
			for _, c in cases do
				if c.state ~= "whole" and now > c.smashedAt + S.RestockSeconds then
					setWhole(c)
				end
			end
			local ringing = now < alarmUntil
			if alarm and not ringing and alarm.IsPlaying then
				alarm:Stop()
			end
			blink = not blink
			for _, l in alarmLights do
				l.Brightness = if ringing and blink then 5 else 0
			end
		end
	end)
end

return GemShowcase
