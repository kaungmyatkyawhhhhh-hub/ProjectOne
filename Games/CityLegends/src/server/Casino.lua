--[[
	Casino (server)
	The High-Rollers Casino on Ocean Drive, Downtown (owner, 2026-10-22). Roblox doesn't allow
	gambling you can play, even with fake money: nothing here takes a bet or pays out at random.
	  * Outside: a marble plaza with palms and fountains, a gold porte-cochere over a red carpet,
	    a glass facade with gold fins, the HIGH-ROLLERS marquee (chasing bulbs), a blade sign on
	    the corner and a lit glass tower above the hall.
	  * Inside: a lobby chandelier, the gaming floor (slot machines and card tables as scenery, or
	    lounge seating when Config.Luxe.GamingFloorDecor is off), the cashier's cage, the VIP desk
	    (VIP membership), a stage with a light show and LED wall, and the VIP lounge behind a glass
	    gate only members get through (the gate opens on the member's own client).
	  * The vault heist, behind the STAFF ONLY door: hack the security room's panel (the vault
	    corridor's lasers go off), drill the round vault door (alarm, 5 stars), load up from the
	    cash and gold trolleys, then lose the police and cash in at the bank's drop-off.

	CityBuilder calls Casino.buildWorld(kit, parent) once Downtown is built; Main.server calls
	Casino.init(ctx, Police, Luxe).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))

local L = Config.Luxe
local V = L.Casino

local Casino = {}

local MARBLE = Color3.fromRGB(236, 232, 224)
local MARBLE_DARK = Color3.fromRGB(40, 36, 42)
local GOLD = Color3.fromRGB(226, 180, 78)
local GLASS = Color3.fromRGB(22, 24, 36)
local WALL = Color3.fromRGB(34, 28, 36)
local CARPET = Color3.fromRGB(92, 14, 30)
local VELVET = Color3.fromRGB(120, 12, 40)
local LEATHER = Color3.fromRGB(20, 18, 22)
local STEEL = Color3.fromRGB(150, 156, 164)
local WARM = Color3.fromRGB(255, 214, 160)
local NEONS = {
	Color3.fromRGB(255, 40, 140), Color3.fromRGB(0, 230, 255), Color3.fromRGB(150, 70, 255),
	Color3.fromRGB(255, 196, 40), Color3.fromRGB(40, 255, 160),
}

local FLOOR = 1.6 -- the hall's floor above the plaza
local H = 40 -- hall height
local HX = 85 -- half the building's width
-- front wall, the hall's back wall, the back of house's back wall (the last two follow the lot's
-- size at build time: wider roads make smaller lots)
local Z_FRONT = -40
local Z_HALL, Z_BACK = 80, 112
local BOH_H = 18

type Vault = {
	base: CFrame?,
	door: Model?,
	hinge: CFrame?,
	hack: ProximityPrompt?,
	drill: ProximityPrompt?,
	drillRig: Model?,
	trolleys: { ProximityPrompt },
	lasers: { BasePart },
	laserWall: BasePart?,
	alarm: Sound?,
	alarmLights: { Light },
	screens: { TextLabel },
	lasersOffUntil: number,
	openUntil: number,
	lockedUntil: number,
	open: boolean,
}
local vault: Vault = {
	base = nil,
	door = nil,
	hinge = nil,
	hack = nil,
	drill = nil,
	drillRig = nil,
	trolleys = {},
	lasers = {},
	laserWall = nil,
	alarm = nil,
	alarmLights = {},
	screens = {},
	lasersOffUntil = 0,
	openUntil = 0,
	lockedUntil = 0,
	open = false,
}
local vipPrompt: ProximityPrompt? = nil

---------------------------------------------------------------------
-- Small builders
---------------------------------------------------------------------
local function prompt(parent: Instance, action: string, object: string, hold: number, range: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = range or 10
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.Parent = parent
	return p
end

-- a palm tree: a gently curved, ringed trunk and drooping fronds
function Casino.palm(kit: any, parent: Instance, pos: Vector3, h: number, seed: number)
	local rng = Random.new(seed)
	local lean = rng:NextNumber(0, math.pi * 2)
	local leanDir = Vector3.new(math.cos(lean), 0, math.sin(lean))
	local segs = 6
	local prev = pos
	local trunk = Color3.fromRGB(120, 98, 72)
	for k = 1, segs do
		local t = k / segs
		local p = pos + Vector3.new(0, h * t, 0) + leanDir * (t * t * h * 0.12)
		local mid = (prev + p) / 2
		local len = (p - prev).Magnitude
		local r = 1.5 - t * 0.5
		kit.deco(parent, Vector3.new(len + 0.2, r * 2, r * 2), CFrame.lookAt(mid, p) * CFrame.Angles(0, math.rad(90), 0), trunk:Lerp(Color3.fromRGB(90, 72, 54), t), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
		prev = p
	end
	local top = prev
	-- fronds: each two long thin leaves bending down
	for k = 0, 8 do
		local a = k / 9 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local green = Color3.fromRGB(34, 96, 44):Lerp(Color3.fromRGB(70, 130, 50), rng:NextNumber())
		local p1 = top + dir * 4 + Vector3.new(0, 1.2, 0)
		local p2 = top + dir * 9.5 - Vector3.new(0, 2.6, 0)
		kit.deco(parent, Vector3.new(2.6, 0.25, (p1 - top).Magnitude + 0.5), CFrame.lookAt((top + p1) / 2, p1), green, Enum.Material.Grass, { shadow = true })
		kit.deco(parent, Vector3.new(2.2, 0.25, (p2 - p1).Magnitude + 0.5), CFrame.lookAt((p1 + p2) / 2, p2), green, Enum.Material.Grass, { shadow = true })
	end
	for k = 0, 2 do
		local a = k * 2.1
		kit.deco(parent, Vector3.one * 0.9, CFrame.new(top + Vector3.new(math.cos(a) * 0.8, -0.8, math.sin(a) * 0.8)), Color3.fromRGB(70, 50, 30), Enum.Material.Wood, { shape = Enum.PartType.Ball })
	end
end

-- a fountain: a marble basin, glowing water, a spray
function Casino.fountain(kit: any, parent: Instance, cf: CFrame, r: number)
	local mk, deco = kit.mk, kit.deco
	mk(parent, Vector3.new(2.4, r * 2, r * 2), cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder, name = "Fountain" })
	local water = deco(parent, Vector3.new(0.3, r * 2 - 2, r * 2 - 2), cf * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 160, 255), Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.35 })
	water.Reflectance = 0.3
	kit.addLight("PointLight", water, Color3.fromRGB(60, 190, 255), r * 1.6, 1.4)
	mk(parent, Vector3.new(5, 2, 2), cf * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local bowl = deco(parent, Vector3.new(0.8, 6, 6), cf * CFrame.new(0, 6.2, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
	spray.LightEmission = 0.6
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.4) })
	spray.Lifetime = NumberRange.new(1.1, 1.5)
	spray.Rate = 70
	spray.Speed = NumberRange.new(16, 20)
	spray.SpreadAngle = Vector2.new(9, 9)
	spray.Acceleration = Vector3.new(0, -34, 0)
	spray.EmissionDirection = Enum.NormalId.Right -- (the bowl is a cylinder lying along X: +X is up)
	spray.Parent = bowl
end

-- a line of chasing marquee bulbs (LuxeClient runs the chase)
local function bulbs(kit: any, parent: Instance, a: CFrame, b: CFrame, step: number, start: number): number
	local len = (b.Position - a.Position).Magnitude
	local n = math.max(1, math.floor(len / step))
	for k = 0, n do
		local p = a.Position:Lerp(b.Position, k / n)
		local bulb = kit.deco(parent, Vector3.one * 1.1, CFrame.new(p), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		bulb:SetAttribute("Index", start + k)
		CollectionService:AddTag(bulb, "Marquee")
	end
	return start + n + 1
end

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
local function build(kit: any, parent: Instance, base: CFrame, lot: number)
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = "HighRollersCasino"
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the front (the street)
	end
	local half = lot / 2
	Z_BACK = math.min(112, half - 4)
	Z_HALL = Z_BACK - 32
	local inside = kit.lodGroup(model, "CasinoInterior", base.Position, 700)

	-------------------------------------------------------------
	-- Plaza: marble, the red carpet, palms, fountains, bollards
	-------------------------------------------------------------
	mk(model, Vector3.new(lot, 0.3, lot), at(0, 0.15, 0), Color3.fromRGB(200, 194, 184), Enum.Material.Marble, { name = "Plaza" })
	deco(model, Vector3.new(16, 0.06, half + Z_FRONT + 2), at(0, 0.33, (-half + Z_FRONT) / 2 - 1), VELVET, Enum.Material.Fabric)
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(0.5, 0.07, half + Z_FRONT + 2), at(s * 8.2, 0.34, (-half + Z_FRONT) / 2 - 1), GOLD, Enum.Material.Metal)
	end
	-- steps up to the hall
	mk(model, Vector3.new(70, 0.65, 4), at(0, 0.62, Z_FRONT - 4), MARBLE, Enum.Material.Marble)
	mk(model, Vector3.new(70, 1.3, 2.2), at(0, 0.95, Z_FRONT - 1.1), MARBLE, Enum.Material.Marble)
	-- gold bollards across the doors: people walk through, cars don't
	for x = -12, 12, 4 do
		mk(model, Vector3.new(2.4, 1.4, 1.4), at(x, 1.5, Z_FRONT - 7) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Bollard" })
	end
	for _, s in { -1, 1 } do
		Casino.fountain(kit, model, at(s * 66, 0.3, -half + 26), 11)
		for k, z in { -half + 8, -half + 46, Z_FRONT - 4, -2, 36, 74 } do
			Casino.palm(kit, model, at(s * (half - 9), 0.3, z).Position, 30 + (k % 3) * 4, k * 31 + (if s > 0 then 7 else 0))
		end
		-- palms flanking the carpet
		Casino.palm(kit, model, at(s * 48, 0.3, -half + 6).Position, 26, 90 + s)
		-- uplights washing the facade
		local lamp = deco(model, Vector3.new(1.6, 1, 1.6), at(s * 62, 0.8, Z_FRONT - 6), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 196, 120), 70, 3, Enum.NormalId.Top, 50)
	end

	-------------------------------------------------------------
	-- Floors, walls, roof
	-------------------------------------------------------------
	mk(model, Vector3.new(HX * 2, FLOOR, Z_BACK - Z_FRONT), at(0, FLOOR / 2, (Z_FRONT + Z_BACK) / 2), MARBLE_DARK, Enum.Material.Marble, { name = "Floor" })
	-- the lobby's marble with a gold star inlay
	deco(model, Vector3.new(HX * 2 - 6, 0.06, 22), at(0, FLOOR + 0.03, Z_FRONT + 12), MARBLE, Enum.Material.Marble)
	for k = 0, 3 do
		deco(model, Vector3.new(14, 0.07, 1.2), at(0, FLOOR + 0.05, Z_FRONT + 12) * CFrame.Angles(0, math.rad(k * 45), 0), GOLD, Enum.Material.Metal)
	end
	-- side walls (the hall, then back of house), with neon edge lines outside
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(3, H, Z_HALL - Z_FRONT), at(s * (HX - 1.5), FLOOR + H / 2, (Z_FRONT + Z_HALL) / 2), WALL, Enum.Material.Concrete, { name = "Wall" })
		mk(model, Vector3.new(3, BOH_H, Z_BACK - Z_HALL), at(s * (HX - 1.5), FLOOR + BOH_H / 2, (Z_HALL + Z_BACK) / 2), WALL, Enum.Material.Concrete, { name = "Wall" })
		for k = 0, 5 do
			local z = Z_FRONT + 10 + k * 22
			deco(model, Vector3.new(0.4, H - 6, 0.6), at(s * (HX + 0.1), FLOOR + H / 2, z), NEONS[(k % #NEONS) + 1], Enum.Material.Neon)
		end
		deco(model, Vector3.new(0.5, 1.2, Z_BACK - Z_FRONT), at(s * (HX + 0.1), FLOOR + BOH_H + 0.6, (Z_FRONT + Z_BACK) / 2), GOLD, Enum.Material.Metal)
	end
	mk(model, Vector3.new(HX * 2, BOH_H, 3), at(0, FLOOR + BOH_H / 2, Z_BACK - 1.5), WALL, Enum.Material.Concrete, { name = "Wall" })
	-- the hall's back wall, with the STAFF ONLY door at x -54 .. -48
	mk(model, Vector3.new(HX - 54, H, 2), at((-HX - 54) / 2, FLOOR + H / 2, Z_HALL), WALL, Enum.Material.Concrete, { name = "Wall" })
	mk(model, Vector3.new(HX + 48, H, 2), at((HX - 48) / 2, FLOOR + H / 2, Z_HALL), WALL, Enum.Material.Concrete, { name = "Wall" })
	mk(model, Vector3.new(6, H - 10, 2), at(-51, FLOOR + 10 + (H - 10) / 2, Z_HALL), WALL, Enum.Material.Concrete, { name = "Wall" })
	local staff = deco(model, Vector3.new(7, 1.6, 0.3), at(-51, FLOOR + 11, Z_HALL - 1.2), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
	kit.surfaceText(staff, Enum.NormalId.Back, "STAFF ONLY", Color3.fromRGB(255, 70, 70), nil, nil, Enum.Font.GothamBold, Vector2.new(300, 70))
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(0.5, 10, 2.4), at(-51 + s * 3.2, FLOOR + 5, Z_HALL), STEEL, Enum.Material.Metal)
	end
	-- the front: a glass curtain wall with gold fins, the doors in the middle
	local doorHalf, doorH = 14, 24
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(HX - doorHalf, H, 1.5), at(s * (HX + doorHalf) / 2, FLOOR + H / 2, Z_FRONT), GLASS, Enum.Material.Glass, { transparency = 0.3, reflectance = 0.25, name = "Facade" })
	end
	mk(model, Vector3.new(doorHalf * 2, H - doorH, 1.5), at(0, FLOOR + doorH + (H - doorH) / 2, Z_FRONT), GLASS, Enum.Material.Glass, { transparency = 0.3, reflectance = 0.25, name = "Facade" })
	for x = -HX + 4, HX - 4, 8 do
		if math.abs(x) > doorHalf + 1 then
			deco(model, Vector3.new(0.8, H, 1.6), at(x, FLOOR + H / 2, Z_FRONT - 1.2), GOLD, Enum.Material.Metal)
		end
	end
	for _, y in { FLOOR + doorH, FLOOR + H - 0.8 } do
		deco(model, Vector3.new(HX * 2 + 1, 1.6, 2), at(0, y, Z_FRONT - 1), GOLD, Enum.Material.Metal)
	end
	-- the door frame and open glass doors pushed to the sides
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(1.2, doorH, 2.2), at(s * doorHalf, FLOOR + doorH / 2, Z_FRONT), GOLD, Enum.Material.Metal)
		deco(model, Vector3.new(6, doorH - 2, 0.4), at(s * (doorHalf - 3.4), FLOOR + (doorH - 2) / 2, Z_FRONT + 1.6), Color3.fromRGB(220, 200, 150), Enum.Material.Glass, { transparency = 0.6 })
	end
	-- roofs and a ceiling with cove neon
	mk(model, Vector3.new(HX * 2, 2, Z_HALL - Z_FRONT), at(0, FLOOR + H + 1, (Z_FRONT + Z_HALL) / 2), WALL, Enum.Material.Concrete, { name = "Roof" })
	mk(model, Vector3.new(HX * 2, 1.5, Z_BACK - Z_HALL), at(0, FLOOR + BOH_H + 0.75, (Z_HALL + Z_BACK) / 2), WALL, Enum.Material.Concrete, { name = "Roof" })
	deco(inside, Vector3.new(HX * 2 - 6, 0.6, Z_HALL - Z_FRONT - 4), at(0, FLOOR + H - 1.6, (Z_FRONT + Z_HALL) / 2), Color3.fromRGB(26, 20, 28), Enum.Material.SmoothPlastic)
	for _, s in { -1, 1 } do
		deco(inside, Vector3.new(0.6, 0.6, Z_HALL - Z_FRONT - 8), at(s * (HX - 6), FLOOR + H - 2.4, (Z_FRONT + Z_HALL) / 2), Color3.fromRGB(255, 60, 160), Enum.Material.Neon)
	end
	for _, z in { Z_FRONT + 2, Z_HALL - 6 } do
		deco(inside, Vector3.new(HX * 2 - 12, 0.6, 0.6), at(0, FLOOR + H - 2.4, z), Color3.fromRGB(255, 60, 160), Enum.Material.Neon)
	end

	-------------------------------------------------------------
	-- The marquee, the blade sign, the porte-cochere
	-------------------------------------------------------------
	local signY = FLOOR + H + 10
	local board = mk(model, Vector3.new(130, 16, 3), at(0, signY, Z_FRONT - 2), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic, { name = "Marquee" })
	local _, _, label = kit.surfaceText(board, Enum.NormalId.Front, "HIGH-ROLLERS", Color3.new(1, 1, 1), nil, nil, Enum.Font.GothamBlack, Vector2.new(1600, 200))
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 90)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 170)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 90)) })
	grad.Parent = label
	CollectionService:AddTag(grad, "AnimatedBoard")
	local frontZ = Z_FRONT - 3.8
	local idx = 0
	idx = bulbs(kit, model, at(-66, signY + 9, frontZ), at(66, signY + 9, frontZ), 3, idx)
	idx = bulbs(kit, model, at(66, signY - 9, frontZ), at(-66, signY - 9, frontZ), 3, idx)
	for _, s in { -1, 1 } do
		bulbs(kit, model, at(s * 66, signY - 6, frontZ), at(s * 66, signY + 6, frontZ), 3, idx)
	end
	kit.addLight("SpotLight", board, Color3.fromRGB(255, 200, 140), 40, 2, Enum.NormalId.Front, 70)
	local sub = deco(model, Vector3.new(46, 8, 1), at(0, FLOOR + 32, Z_FRONT - 1.4), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic)
	kit.surfaceText(sub, Enum.NormalId.Front, "★  CASINO  ★", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(800, 140))
	-- the blade sign on the corner, seen from up and down the street
	local blade = mk(model, Vector3.new(3, 64, 14), at(-HX - 4, FLOOR + 30, Z_FRONT + 6), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic, { name = "Blade" })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local _, _, bl = kit.surfaceText(blade, face, "C\nA\nS\nI\nN\nO", Color3.fromRGB(255, 70, 170), nil, nil, Enum.Font.GothamBlack, Vector2.new(200, 900))
		bl.TextScaled = true
	end
	for _, dz in { -7.4, 7.4 } do
		deco(model, Vector3.new(3.4, 64, 0.6), at(-HX - 4, FLOOR + 30, Z_FRONT + 6 + dz), Color3.fromRGB(255, 196, 60), Enum.Material.Neon)
	end
	-- the porte-cochere: a gold canopy over the carpet, neon edged, lit from below
	local cz = Z_FRONT - 24
	mk(model, Vector3.new(84, 2, 44), at(0, 21, cz), Color3.fromRGB(40, 30, 20), Enum.Material.Metal, { name = "Canopy" })
	deco(model, Vector3.new(85, 2.6, 0.8), at(0, 21, cz - 22.2), GOLD, Enum.Material.Metal)
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(0.8, 2.6, 44), at(s * 42.2, 21, cz), GOLD, Enum.Material.Metal)
		deco(model, Vector3.new(0.5, 0.5, 42), at(s * 41.6, 19.8, cz), Color3.fromRGB(255, 196, 60), Enum.Material.Neon)
		mk(model, Vector3.new(20, 3, 3), at(s * 36, 10.5, cz - 18) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Column" })
		mk(model, Vector3.new(20, 3, 3), at(s * 36, 10.5, cz + 14) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Column" })
	end
	deco(model, Vector3.new(84, 0.5, 0.5), at(0, 19.8, cz - 21.6), Color3.fromRGB(255, 196, 60), Enum.Material.Neon)
	local fascia = deco(model, Vector3.new(50, 2.4, 0.3), at(0, 21, cz - 22.7), GOLD, Enum.Material.Metal)
	kit.surfaceText(fascia, Enum.NormalId.Front, "HIGH-ROLLERS CASINO", Color3.fromRGB(30, 20, 10), nil, nil, Enum.Font.Garamond, Vector2.new(1000, 60))
	for _, x in { -24, 0, 24 } do
		local down = deco(model, Vector3.new(4, 0.3, 4), at(x, 19.9, cz), Color3.fromRGB(255, 236, 200), Enum.Material.Neon)
		kit.addLight("SpotLight", down, WARM, 30, 2.4, Enum.NormalId.Bottom, 90)
	end

	-------------------------------------------------------------
	-- The tower above the hall: dark glass, gold edges, lit bands, a crown
	-------------------------------------------------------------
	local tw, td = 112, 56
	local tz = (Z_HALL + 24) / 2 + 2
	local t0 = FLOOR + H + 2
	local th = 196
	mk(model, Vector3.new(tw, th, td), at(0, t0 + th / 2, tz), GLASS, Enum.Material.Glass, { reflectance = 0.2, name = "Tower" })
	for y = t0 + 10, t0 + th - 14, 12 do
		local lit = (y // 12) % 3 ~= 0
		local col = if lit then Color3.fromRGB(255, 206, 140) else Color3.fromRGB(60, 50, 70)
		deco(model, Vector3.new(tw + 0.4, 1.2, 0.3), at(0, y, tz - td / 2 - 0.15), col, Enum.Material.Neon, { transparency = if lit then 0.15 else 0.5 })
		deco(model, Vector3.new(tw + 0.4, 1.2, 0.3), at(0, y, tz + td / 2 + 0.15), col, Enum.Material.Neon, { transparency = if lit then 0.15 else 0.5 })
		for _, s in { -1, 1 } do
			deco(model, Vector3.new(0.3, 1.2, td + 0.4), at(s * (tw / 2 + 0.15), y, tz), col, Enum.Material.Neon, { transparency = if lit then 0.15 else 0.5 })
		end
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			deco(model, Vector3.new(1.4, th, 1.4), at(sx * tw / 2, t0 + th / 2, tz + sz * td / 2), GOLD, Enum.Material.Metal)
		end
	end
	-- the crown: stepped gold tiers and the HR monogram
	local cy = t0 + th
	mk(model, Vector3.new(tw - 16, 10, td - 10), at(0, cy + 5, tz), Color3.fromRGB(30, 24, 18), Enum.Material.Metal, { name = "Crown" })
	mk(model, Vector3.new(tw - 40, 14, td - 24), at(0, cy + 17, tz), Color3.fromRGB(30, 24, 18), Enum.Material.Metal, { name = "Crown" })
	for _, y in { cy + 0.6, cy + 10.4, cy + 24.4 } do
		deco(model, Vector3.new(tw - 8, 0.8, td - 4), at(0, y, tz), Color3.fromRGB(255, 196, 60), Enum.Material.Neon, { transparency = 0.1 })
	end
	local mono = deco(model, Vector3.new(30, 12, 0.6), at(0, cy + 17, tz - (td - 24) / 2 - 0.4), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(mono, Enum.NormalId.Front, "HR", Color3.fromRGB(255, 210, 90), nil, nil, Enum.Font.Garamond, Vector2.new(400, 160))
	local beacon = deco(model, Vector3.one * 2.4, at(0, cy + 26, tz), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, { shape = Enum.PartType.Ball })
	CollectionService:AddTag(beacon, "Blink")
	for _, s in { -1, 1 } do
		local wash = deco(model, Vector3.new(1.6, 1, 1.6), at(s * 40, FLOOR + H + 3, tz - td / 2 - 4), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", wash, Color3.fromRGB(255, 120, 200), 90, 2.5, Enum.NormalId.Top, 35)
	end

	-------------------------------------------------------------
	-- Inside: the lobby chandelier and rope lines
	-------------------------------------------------------------
	local ch = at(0, FLOOR + H - 10, Z_FRONT + 16)
	local hub = deco(inside, Vector3.new(3, 4, 4), ch * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	deco(inside, Vector3.new(0.3, 7, 0.3), ch * CFrame.new(0, 5, 0), GOLD, Enum.Material.Metal)
	for ring = 1, 2 do
		local r = 4 + ring * 3
		local n = 10 + ring * 6
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			deco(inside, Vector3.new(0.6, 1.8 + ring * 0.6, 0.6), ch * CFrame.new(math.cos(a) * r, -ring * 1.6, math.sin(a) * r), Color3.fromRGB(240, 248, 255), Enum.Material.Glass, { transparency = 0.2, reflectance = 0.4 })
			deco(inside, Vector3.one * 0.5, ch * CFrame.new(math.cos(a) * r, -ring * 1.6 - 1.4, math.sin(a) * r), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		end
	end
	kit.addLight("PointLight", hub, WARM, 50, 1.8)
	for _, s in { -1, 1 } do
		for k = 0, 3 do
			local z = Z_FRONT + 6 + k * 6
			deco(inside, Vector3.new(0.5, 3.2, 0.5), at(s * 9, FLOOR + 1.6, z), GOLD, Enum.Material.Metal)
			deco(inside, Vector3.one * 0.8, at(s * 9, FLOOR + 3.4, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
			if k < 3 then
				deco(inside, Vector3.new(0.3, 0.3, 6), at(s * 9, FLOOR + 2.8, z + 3), VELVET, Enum.Material.Fabric)
			end
		end
	end

	-------------------------------------------------------------
	-- The gaming floor (scenery only) or lounge seating
	-------------------------------------------------------------
	local floorZ0, floorZ1 = Z_FRONT + 24, Z_HALL
	deco(inside, Vector3.new(HX * 2 - 6, 0.06, floorZ1 - floorZ0), at(0, FLOOR + 0.03, (floorZ0 + floorZ1) / 2), CARPET, Enum.Material.Fabric)
	for x = -HX + 12, HX - 12, 12 do
		deco(inside, Vector3.new(0.4, 0.07, floorZ1 - floorZ0), at(x, FLOOR + 0.05, (floorZ0 + floorZ1) / 2), Color3.fromRGB(150, 110, 40), Enum.Material.Fabric)
	end
	local rng = Random.new(7744)
	if L.GamingFloorDecor then
		-- banks of slot machines (no lever, no spin: they just glow)
		local symbols = { "7  7  7", "◆  ★  ◆", "★  7  ★", "★  ★  ★", "◆  ◆  ◆" }
		for row, z in { -10, 8, 26 } do
			for _, side in { -1, 1 } do
				for k = 0, 7 do
					local x = -80 + k * 5
					local cf = at(x, FLOOR, z + side * 1.4) * CFrame.Angles(0, if side < 0 then 0 else math.pi, 0)
					local neon = NEONS[rng:NextInteger(1, #NEONS)]
					mk(inside, Vector3.new(4, 5.6, 2.6), cf * CFrame.new(0, 2.8, 0), Color3.fromRGB(26, 22, 32), Enum.Material.Metal, { name = "SlotMachine" })
					local screen = deco(inside, Vector3.new(3.2, 2.4, 0.1), cf * CFrame.new(0, 3.6, -1.35), Color3.fromRGB(8, 8, 14), Enum.Material.SmoothPlastic)
					kit.surfaceText(screen, Enum.NormalId.Front, symbols[rng:NextInteger(1, #symbols)], neon, Color3.fromRGB(12, 10, 24), 0, Enum.Font.GothamBlack, Vector2.new(220, 160))
					deco(inside, Vector3.new(4.1, 0.9, 2.7), cf * CFrame.new(0, 6.05, 0), neon, Enum.Material.Neon)
					deco(inside, Vector3.new(3.4, 0.8, 1.2), cf * CFrame.new(0, 2, -1.6) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(40, 36, 48), Enum.Material.Metal)
					deco(inside, Vector3.new(0.6, 1.6, 1.6), cf * CFrame.new(0, 1.8, -3.4) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
					deco(inside, Vector3.new(0.3, 1.6, 0.3), cf * CFrame.new(0, 0.8, -3.4), GOLD, Enum.Material.Metal)
				end
			end
			-- a lit sign at each row's end
			local cap = deco(inside, Vector3.new(1, 3, 8), at(-86 + 3.2, FLOOR + 8, z), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic)
			kit.surfaceText(cap, Enum.NormalId.Right, "HIGH\nROLLERS", NEONS[(row % #NEONS) + 1], nil, nil, Enum.Font.GothamBlack, Vector2.new(300, 120))
		end
		-- card tables (felt, a gold rim, stacks of chips and seats)
		for _, tx in { 40, 66 } do
			for _, tz2 in { -8, 14 } do
				local tc = at(tx, FLOOR, tz2)
				mk(inside, Vector3.new(2.6, 4, 4), tc * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(30, 22, 18), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, name = "Table" })
				deco(inside, Vector3.new(0.5, 13, 13), tc * CFrame.new(0, 2.8, 0) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
				deco(inside, Vector3.new(0.4, 12, 12), tc * CFrame.new(0, 3.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(16, 92, 56), Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
				for k = 0, 5 do
					local a = k / 6 * math.pi * 2
					local stack = tc * CFrame.new(math.cos(a) * 3.6, 3.3, math.sin(a) * 3.6)
					for j = 0, rng:NextInteger(1, 4) do
						deco(inside, Vector3.new(0.18, 0.8, 0.8), stack * CFrame.new(0, j * 0.19, 0) * CFrame.Angles(0, 0, math.rad(90)), NEONS[rng:NextInteger(1, #NEONS)]:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
					end
					local seat = tc * CFrame.new(math.cos(a) * 8.6, 0, math.sin(a) * 8.6)
					deco(inside, Vector3.new(0.6, 2.2, 2.2), seat * CFrame.new(0, 2.4, 0) * CFrame.Angles(0, 0, math.rad(90)), VELVET, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
					deco(inside, Vector3.new(0.3, 2.2, 0.3), seat * CFrame.new(0, 1.1, 0), GOLD, Enum.Material.Metal)
				end
				-- a pendant lamp over the table
				local lamp = deco(inside, Vector3.new(3, 1.2, 3), tc * CFrame.new(0, 14, 0), GOLD, Enum.Material.Metal)
				deco(inside, Vector3.new(0.2, H - 15, 0.2), tc * CFrame.new(0, 14 + (H - 15) / 2, 0), GOLD, Enum.Material.Metal)
				deco(inside, Vector3.new(2.6, 0.2, 2.6), tc * CFrame.new(0, 13.3, 0), WARM, Enum.Material.Neon)
				kit.addLight("SpotLight", lamp, WARM, 22, 2.2, Enum.NormalId.Bottom, 80)
			end
		end
	else
		-- lounge seating and two car display turntables instead
		for _, p in { { -60, 0 }, { -60, 22 }, { 52, 0 }, { 52, 22 } } do
			local c = at(p[1], FLOOR, p[2])
			deco(inside, Vector3.new(14, 2, 4), c * CFrame.new(0, 1, -5), LEATHER, Enum.Material.Leather)
			deco(inside, Vector3.new(14, 2, 4), c * CFrame.new(0, 1, 5), LEATHER, Enum.Material.Leather)
			deco(inside, Vector3.new(6, 1.4, 4), c * CFrame.new(0, 0.7, 0), MARBLE, Enum.Material.Marble)
		end
		for _, x in { -30, 22 } do
			local c = at(x, FLOOR, 10)
			mk(inside, Vector3.new(1, 22, 22), c * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE_DARK, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
			deco(inside, Vector3.new(0.3, 22.4, 22.4), c * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 60, 160), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.4 })
		end
	end

	-------------------------------------------------------------
	-- The cashier's cage (back left)
	-------------------------------------------------------------
	local cageX = -60
	local cageZ = Z_HALL - 22
	mk(inside, Vector3.new(3, 4.4, 24), at(cageX, FLOOR + 2.2, cageZ), Color3.fromRGB(40, 26, 18), Enum.Material.Wood, { name = "Counter" })
	deco(inside, Vector3.new(3.6, 0.4, 24.4), at(cageX, FLOOR + 4.6, cageZ), MARBLE, Enum.Material.Marble)
	for z = cageZ - 11.4, cageZ + 11.4, 1.4 do
		deco(inside, Vector3.new(0.18, 8, 0.18), at(cageX, FLOOR + 8.8, z), GOLD, Enum.Material.Metal)
	end
	deco(inside, Vector3.new(0.6, 0.6, 24), at(cageX, FLOOR + 12.8, cageZ), GOLD, Enum.Material.Metal)
	local cash = deco(inside, Vector3.new(0.5, 3, 18), at(cageX + 0.3, FLOOR + 15, cageZ), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic)
	kit.surfaceText(cash, Enum.NormalId.Right, "CASHIER", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(600, 100))
	mk(inside, Vector3.new(HX + cageX - 3, 14, 1), at((-HX + 3 + cageX) / 2, FLOOR + 7, cageZ - 12.5), WALL, Enum.Material.Concrete)
	for _, z in { cageZ - 8, cageZ, cageZ + 8 } do
		deco(inside, Vector3.new(4, 0.5, 6), at(-80, FLOOR + 4, z), STEEL, Enum.Material.Metal)
		for k = -1, 1 do
			deco(inside, Vector3.new(1.2, 0.6, 1.8), at(-80 + k * 1.3, FLOOR + 4.55, z), Color3.fromRGB(255, 200, 60), Enum.Material.Foil)
		end
	end
	local cl = deco(inside, Vector3.new(2, 0.3, 2), at(-72, FLOOR + 13, cageZ), WARM, Enum.Material.Neon)
	kit.addLight("PointLight", cl, WARM, 24, 1.2)

	-------------------------------------------------------------
	-- The VIP desk (VIP membership)
	-------------------------------------------------------------
	local desk = at(0, FLOOR, Z_HALL - 36)
	mk(inside, Vector3.new(16, 4.2, 4), desk * CFrame.new(0, 2.1, 0), Color3.fromRGB(14, 12, 16), Enum.Material.Marble, { name = "VipDesk" })
	deco(inside, Vector3.new(16.4, 0.4, 4.4), desk * CFrame.new(0, 4.3, 0), GOLD, Enum.Material.Metal)
	deco(inside, Vector3.new(16.2, 0.4, 0.2), desk * CFrame.new(0, 1.2, -2.05), Color3.fromRGB(190, 120, 255), Enum.Material.Neon)
	local vs = deco(inside, Vector3.new(22, 5, 0.6), desk * CFrame.new(0, 13, 1), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic)
	local _, _, vl = kit.surfaceText(vs, Enum.NormalId.Front, "VIP MEMBERSHIP", Color3.new(1, 1, 1), nil, nil, Enum.Font.GothamBlack, Vector2.new(800, 140))
	local vg = Instance.new("UIGradient")
	vg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 70)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(215, 230, 245)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 120, 255)) })
	vg.Parent = vl
	CollectionService:AddTag(vg, "AnimatedBoard")
	-- three cards on stands
	for k, tier in L.Vip do
		local card = deco(inside, Vector3.new(2.4, 1.5, 0.1), desk * CFrame.new(-4 + (k - 1) * 4, 5.4, 0.6) * CFrame.Angles(math.rad(-20), 0, 0), tier.color, if k == 3 then Enum.Material.Glass else Enum.Material.Metal)
		card.Reflectance = 0.3
	end
	local vipPart = deco(inside, Vector3.new(2, 2, 2), desk * CFrame.new(0, 3, -3.5), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	vipPrompt = prompt(vipPart, "VIP membership", "High-Rollers Casino", 0, 10)
	local dl = deco(inside, Vector3.new(4, 0.3, 4), desk * CFrame.new(0, H - 3, 0), WARM, Enum.Material.Neon)
	kit.addLight("SpotLight", dl, WARM, 30, 2, Enum.NormalId.Bottom, 60)

	-------------------------------------------------------------
	-- The stage: a platform, an LED wall, a truss of moving lights
	-------------------------------------------------------------
	local stageZ = Z_HALL - 10
	mk(inside, Vector3.new(56, 3, 18), at(-6, FLOOR + 1.5, stageZ + 1), Color3.fromRGB(16, 14, 18), Enum.Material.SmoothPlastic, { name = "Stage" })
	deco(inside, Vector3.new(56.4, 0.4, 0.4), at(-6, FLOOR + 2.8, stageZ - 8), Color3.fromRGB(0, 230, 255), Enum.Material.Neon)
	local wall = deco(inside, Vector3.new(52, 22, 0.8), at(-6, FLOOR + 3 + 11, Z_HALL - 1.6), Color3.fromRGB(6, 6, 10), Enum.Material.SmoothPlastic)
	local _, wf, wlabel = kit.surfaceText(wall, Enum.NormalId.Front, "HIGH-ROLLERS LIVE", Color3.new(1, 1, 1), Color3.fromRGB(20, 0, 40), 0, Enum.Font.GothamBlack, Vector2.new(1200, 500))
	local wg = Instance.new("UIGradient")
	wg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 40, 140)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 230, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 70, 255)) })
	wg.Parent = wf
	CollectionService:AddTag(wg, "AnimatedBoard")
	wlabel.TextColor3 = Color3.new(1, 1, 1)
	deco(inside, Vector3.new(58, 1, 1), at(-6, FLOOR + 28, stageZ - 4), STEEL, Enum.Material.Metal)
	for _, s in { -1, 1 } do
		deco(inside, Vector3.new(1, 28, 1), at(-6 + s * 29, FLOOR + 14, stageZ - 4), STEEL, Enum.Material.Metal)
		-- speaker stacks
		for k = 0, 2 do
			deco(inside, Vector3.new(5, 4, 4), at(-6 + s * 25, FLOOR + 5 + k * 4, stageZ + 6), Color3.fromRGB(14, 14, 16), Enum.Material.Fabric)
		end
	end
	for k = 0, 5 do
		local head = deco(inside, Vector3.new(1.6, 1.6, 1.6), at(-26 + k * 8, FLOOR + 26.6, stageZ - 4), Color3.fromRGB(20, 20, 24), Enum.Material.Metal)
		head.Name = "MovingHead"
		head:SetAttribute("Home", head.CFrame)
		head:SetAttribute("Phase", k * 0.9)
		local beam = kit.addLight("SpotLight", head, NEONS[(k % #NEONS) + 1], 60, 4, Enum.NormalId.Bottom, 25)
		beam.Name = "Beam"
		CollectionService:AddTag(head, "CasinoSpot")
	end

	-------------------------------------------------------------
	-- The VIP lounge (back right), behind a glass gate
	-------------------------------------------------------------
	local lx0, lx1, lz0, lz1 = 46, HX - 2, Z_HALL - 36, Z_HALL - 1
	local lcx, lcz = (lx0 + lx1) / 2, (lz0 + lz1) / 2
	mk(inside, Vector3.new(lx1 - lx0, 2.4, lz1 - lz0), at(lcx, FLOOR + 1.2, lcz), Color3.fromRGB(18, 14, 20), Enum.Material.Marble, { name = "LoungeFloor" })
	deco(inside, Vector3.new(lx1 - lx0 - 2, 0.06, lz1 - lz0 - 2), at(lcx, FLOOR + 2.43, lcz), Color3.fromRGB(60, 10, 70), Enum.Material.Fabric)
	-- glass walls: along x = 46 (the gate in it) and along z = 44
	local gateZ0, gateZ1 = lz0 + 14, lz0 + 20
	local wallH = 10
	local function glassWall(size: Vector3, cf: CFrame)
		mk(inside, size, cf, Color3.fromRGB(200, 180, 140), Enum.Material.Glass, { transparency = 0.65, name = "LoungeGlass" })
		deco(inside, Vector3.new(size.X + 0.2, 0.5, size.Z + 0.2), cf * CFrame.new(0, size.Y / 2, 0), GOLD, Enum.Material.Metal)
	end
	glassWall(Vector3.new(0.6, wallH, gateZ0 - lz0), at(lx0, FLOOR + 2.4 + wallH / 2, (lz0 + gateZ0) / 2))
	glassWall(Vector3.new(0.6, wallH, lz1 - gateZ1), at(lx0, FLOOR + 2.4 + wallH / 2, (gateZ1 + lz1) / 2))
	glassWall(Vector3.new(lx1 - lx0, wallH, 0.6), at(lcx, FLOOR + 2.4 + wallH / 2, lz0))
	local gate = mk(inside, Vector3.new(0.8, wallH, gateZ1 - gateZ0), at(lx0, FLOOR + 2.4 + wallH / 2, (gateZ0 + gateZ1) / 2), Color3.fromRGB(190, 120, 255), Enum.Material.Glass, { transparency = 0.45, name = "VipGate" })
	CollectionService:AddTag(gate, "VipGate")
	local gs = deco(inside, Vector3.new(0.4, 2, 8), at(lx0 - 0.6, FLOOR + 2.4 + wallH + 1.6, (gateZ0 + gateZ1) / 2), Color3.fromRGB(10, 8, 14), Enum.Material.SmoothPlastic)
	kit.surfaceText(gs, Enum.NormalId.Left, "VIP LOUNGE", Color3.fromRGB(190, 120, 255), nil, nil, Enum.Font.GothamBlack, Vector2.new(400, 100))
	-- a step up to the gate, velvet ropes outside it
	mk(inside, Vector3.new(4, 1.2, gateZ1 - gateZ0 + 4), at(lx0 - 2, FLOOR + 0.6, (gateZ0 + gateZ1) / 2), Color3.fromRGB(18, 14, 20), Enum.Material.Marble)
	for _, z in { gateZ0 - 2, gateZ1 + 2 } do
		deco(inside, Vector3.new(0.5, 3.2, 0.5), at(lx0 - 5, FLOOR + 1.6, z), GOLD, Enum.Material.Metal)
		deco(inside, Vector3.one * 0.8, at(lx0 - 5, FLOOR + 3.4, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	end
	-- inside: sofas, low tables, a piano, an aquarium wall
	local ly = FLOOR + 2.4
	for _, z in { lz0 + 6, lz0 + 26 } do
		deco(inside, Vector3.new(16, 1.6, 4), at(66, ly + 0.8, z - 4), LEATHER, Enum.Material.Leather)
		deco(inside, Vector3.new(16, 3.2, 1.2), at(66, ly + 1.6, z - 6.2), LEATHER, Enum.Material.Leather)
		deco(inside, Vector3.new(8, 1.2, 3), at(66, ly + 0.6, z + 1), MARBLE, Enum.Material.Marble)
		deco(inside, Vector3.new(8.2, 0.2, 3.2), at(66, ly + 1.25, z + 1), GOLD, Enum.Material.Metal)
	end
	deco(inside, Vector3.new(6, 2.4, 8), at(54, ly + 3, lz0 + 30), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic, { reflectance = 0.3 })
	deco(inside, Vector3.new(0.4, 3, 0.4), at(54, ly + 1.5, lz0 + 27), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
	deco(inside, Vector3.new(6, 0.3, 7), at(54.5, ly + 5.4, lz0 + 30.5) * CFrame.Angles(math.rad(25), 0, 0), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic, { reflectance = 0.3 })
	local tank = deco(inside, Vector3.new(1, 12, lz1 - lz0 - 6), at(lx1 - 1.2, ly + 7, lcz), Color3.fromRGB(20, 120, 255), Enum.Material.Glass, { transparency = 0.35 })
	kit.addLight("SurfaceLight", tank, Color3.fromRGB(40, 150, 255), 22, 1.4, Enum.NormalId.Left, 120)
	local fish = { Color3.fromRGB(255, 140, 30), Color3.fromRGB(255, 230, 60), Color3.fromRGB(255, 80, 160), Color3.fromRGB(80, 230, 255) }
	for k = 1, 14 do
		deco(inside, Vector3.new(0.4, 0.6, 1.2), at(lx1 - 1.2, ly + 2 + rng:NextNumber(0, 10), lz0 + 4 + rng:NextNumber(0, lz1 - lz0 - 8)), fish[(k % #fish) + 1], Enum.Material.Neon)
	end
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
	bubbles.Size = NumberSequence.new(0.2)
	bubbles.Transparency = NumberSequence.new(0.4)
	bubbles.Lifetime = NumberRange.new(2, 3)
	bubbles.Rate = 12
	bubbles.Speed = NumberRange.new(3, 4)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Parent = tank
	local vipSign = deco(inside, Vector3.new(0.4, 4, 12), at(lx1 - 2, ly + 16, lcz), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(vipSign, Enum.NormalId.Left, "VIP", Color3.fromRGB(190, 120, 255), nil, nil, Enum.Font.GothamBlack, Vector2.new(400, 140))
	for _, z in { lz0 + 8, lz0 + 26 } do
		local ll = deco(inside, Vector3.new(3, 0.3, 3), at(66, FLOOR + H - 3, z), Color3.fromRGB(220, 170, 255), Enum.Material.Neon)
		kit.addLight("SpotLight", ll, Color3.fromRGB(210, 160, 255), 26, 1.6, Enum.NormalId.Bottom, 80)
	end

	-------------------------------------------------------------
	-- Back of house: the security room, the laser corridor, the vault
	-------------------------------------------------------------
	local boh = kit.lodGroup(model, "CasinoBackOfHouse", base.Position, 500)
	-- (all measured from the hall's back wall: the corridor runs zc +- 6, its wall at zw)
	local zc, zw, zr = Z_HALL + 6, Z_HALL + 12, Z_HALL + 16
	-- the security room x -85 .. -48 (through the STAFF ONLY door)
	mk(boh, Vector3.new(1.5, BOH_H, Z_BACK - zw), at(-48, FLOOR + BOH_H / 2, (zw + Z_BACK) / 2), WALL, Enum.Material.Concrete, { name = "Wall" })
	-- the corridor from the security room to the vault wall at x = -25
	mk(boh, Vector3.new(23, BOH_H, 1.5), at(-36.5, FLOOR + BOH_H / 2, zw), WALL, Enum.Material.Concrete, { name = "Wall" })
	deco(boh, Vector3.new(36, 0.06, Z_BACK - Z_HALL - 2), at(-66.5, FLOOR + 0.03, (Z_HALL + Z_BACK) / 2), Color3.fromRGB(70, 72, 78), Enum.Material.Concrete)
	local sl = deco(boh, Vector3.new(6, 0.3, 2), at(-66, FLOOR + BOH_H - 0.5, zr), Color3.fromRGB(220, 240, 255), Enum.Material.Neon)
	kit.addLight("PointLight", sl, Color3.fromRGB(200, 230, 255), 26, 1)
	-- the CCTV wall and the panel to hack
	local panel = mk(boh, Vector3.new(1.2, 9, 18), at(-83.4, FLOOR + 6, zr + 2), Color3.fromRGB(20, 22, 26), Enum.Material.Metal, { name = "SecurityPanel" })
	for k = 0, 5 do
		local col, row = k % 3, k // 3
		local screen = deco(boh, Vector3.new(0.2, 3.4, 5.2), at(-82.7, FLOOR + 4 + row * 4, zr - 3.6 + col * 5.6), Color3.fromRGB(6, 10, 8), Enum.Material.SmoothPlastic)
		local _, _, sLabel = kit.surfaceText(screen, Enum.NormalId.Right, string.format("CAM %02d\n● REC", k + 1), Color3.fromRGB(80, 255, 140), Color3.fromRGB(4, 16, 8), 0, Enum.Font.Code, Vector2.new(200, 130))
		table.insert(vault.screens, sLabel)
	end
	deco(boh, Vector3.new(4, 3, 14), at(-79, FLOOR + 1.5, zr + 2), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
	vault.hack = prompt(panel, "Hack security", "CCTV and lasers", V.HackSeconds, 9)
	-- the lasers across the corridor, and the wall of light they make
	for _, x in { -43, -39, -35, -31 } do
		for k, y in { 1.2, 3.4, 5.6, 7.8 } do
			local beam = deco(boh, Vector3.new(0.12, 0.12, 12), at(x, FLOOR + y, zc) * CFrame.Angles(math.rad((k % 2) * 6 - 3), 0, 0), Color3.fromRGB(255, 20, 30), Enum.Material.Neon)
			beam.Name = "Laser"
			table.insert(vault.lasers, beam)
		end
		for _, z in { zc - 5.4, zc + 5.4 } do
			deco(boh, Vector3.new(0.8, 9, 0.6), at(x, FLOOR + 4.5, z), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		end
	end
	vault.laserWall = mk(boh, Vector3.new(14, 12, 12), at(-37, FLOOR + 6, zc), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "LaserWall" })
	-- the vault wall (x = -25) round a round door at the corridor's end
	local vx = -25
	mk(boh, Vector3.new(3, BOH_H, Z_BACK - zw), at(vx, FLOOR + BOH_H / 2, (zw + Z_BACK) / 2), STEEL:Lerp(WALL, 0.5), Enum.Material.Concrete, { name = "VaultWall" })
	mk(boh, Vector3.new(3, BOH_H - 11.5, 12), at(vx, FLOOR + 11.5 + (BOH_H - 11.5) / 2, zc), STEEL:Lerp(WALL, 0.5), Enum.Material.Concrete, { name = "VaultWall" })
	local R = 5.6
	local doorCF = at(vx, FLOOR + 6, zc)
	deco(boh, Vector3.new(3.4, R * 2 + 1.6, R * 2 + 1.6), doorCF * CFrame.new(-0.3, 0, 0), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local door = Instance.new("Model")
	door.Name = "CasinoVaultDoor"
	local disc = mk(door, Vector3.new(2.6, R * 2, R * 2), doorCF * CFrame.new(-1.6, 0, 0), STEEL, Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder, name = "Disc" })
	deco(door, Vector3.new(2.8, R * 2 - 2, R * 2 - 2), doorCF * CFrame.new(-1.6, 0, 0), Color3.fromRGB(120, 126, 134), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local face = doorCF * CFrame.new(-3.1, 0, 0)
	deco(door, Vector3.new(0.5, 3.6, 3.6), face, GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	for k = 0, 2 do
		deco(door, Vector3.new(0.4, 6, 0.5), face * CFrame.Angles(math.rad(k * 60), 0, 0), GOLD, Enum.Material.Metal)
	end
	for k = 0, 9 do
		local a = k * math.pi / 5
		deco(door, Vector3.new(0.5, 0.7, 0.7), face * CFrame.new(0, math.cos(a) * (R - 1), math.sin(a) * (R - 1)), GOLD, Enum.Material.Metal)
	end
	door.PrimaryPart = disc
	door.Parent = boh
	vault.door = door
	vault.hinge = at(vx - 1.6, FLOOR + 6, zc + R)
	local drillPart = deco(boh, Vector3.new(2, 2, 2), at(vx - 5, FLOOR + 4, zc), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	local drill = prompt(drillPart, "Drill the vault", "High-Rollers vault", V.DrillSeconds, 9)
	drill.Enabled = false
	vault.drill = drill
	-- the drill rig (shows while the vault is being drilled and open)
	local rig = Instance.new("Model")
	rig.Name = "DrillRig"
	deco(rig, Vector3.new(1.2, 6, 1.2), at(vx - 6, FLOOR + 3, zc - 3), Color3.fromRGB(230, 170, 30), Enum.Material.Metal)
	deco(rig, Vector3.new(4.6, 1.2, 1.2), at(vx - 4.2, FLOOR + 6, zc - 3), Color3.fromRGB(230, 170, 30), Enum.Material.Metal)
	deco(rig, Vector3.new(2.6, 0.5, 0.5), at(vx - 2.4, FLOOR + 6, zc - 1.4), STEEL, Enum.Material.Metal)
	for _, p in rig:GetChildren() do
		if p:IsA("BasePart") then
			p.Transparency = 1
		end
	end
	rig.Parent = boh
	vault.drillRig = rig
	-- the vault room x -25 .. 85: gold on shelves, cash pallets, the trolleys
	deco(boh, Vector3.new(HX - vx - 4, 0.1, Z_BACK - Z_HALL - 4), at((vx + HX) / 2, FLOOR + 0.05, (Z_HALL + Z_BACK) / 2), Color3.fromRGB(60, 62, 66), Enum.Material.DiamondPlate)
	for x = vx + 10, HX - 10, 12 do
		for _, y in { 3, 7, 11 } do
			deco(boh, Vector3.new(10, 0.5, 4), at(x, FLOOR + y, Z_BACK - 5), STEEL, Enum.Material.Metal)
			for k = -2, 2 do
				if y == 7 then
					deco(boh, Vector3.new(1.6, 1.2, 1.2), at(x + k * 2, FLOOR + y + 0.85, Z_BACK - 5), Color3.fromRGB(70, 140, 80), Enum.Material.SmoothPlastic)
				else
					deco(boh, Vector3.new(1.6, 0.8, 0.9), at(x + k * 2, FLOOR + y + 0.65, Z_BACK - 5), Color3.fromRGB(255, 200, 60), Enum.Material.Foil)
				end
			end
		end
	end
	local names = { "Cash trolley", "Gold trolley" }
	for k = 1, 6 do
		local x = vx + 12 + (k - 1) * 16
		local gold = k % 2 == 0
		local cart = mk(boh, Vector3.new(6, 3.4, 3.4), at(x, FLOOR + 2, zr), Color3.fromRGB(60, 64, 70), Enum.Material.Metal, { name = "Trolley" .. k })
		for j = -1, 1 do
			deco(boh, Vector3.new(1.6, 1.1, 2.6), at(x + j * 1.8, FLOOR + 4.25, zr), if gold then Color3.fromRGB(255, 200, 60) else Color3.fromRGB(80, 160, 90), if gold then Enum.Material.Foil else Enum.Material.SmoothPlastic)
		end
		for _, dx in { -2.4, 2.4 } do
			deco(boh, Vector3.new(0.8, 1, 1), at(x + dx, FLOOR + 0.3, zr) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(20, 20, 22), Enum.Material.Rubber, { shape = Enum.PartType.Cylinder })
		end
		local tp = prompt(cart, "Grab " .. (if gold then "gold" else "cash"), names[if gold then 2 else 1], V.GrabSeconds, 8)
		tp.Enabled = false
		table.insert(vault.trolleys, tp)
	end
	for _, x in { 0, 40, 70 } do
		local vl2 = deco(boh, Vector3.new(4, 0.3, 4), at(x, FLOOR + BOH_H - 0.5, zr + 2), Color3.fromRGB(255, 240, 210), Enum.Material.Neon)
		kit.addLight("PointLight", vl2, Color3.fromRGB(255, 230, 190), 30, 1.2)
	end
	-- the alarm: a bell and red beacons in the hall and the vault
	local alarmPart = deco(model, Vector3.new(1, 1, 1), at(0, FLOOR + 20, Z_HALL - 20), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	local alarm = Instance.new("Sound")
	alarm.Name = "Alarm"
	alarm.SoundId = Config.Sounds.Alarm
	alarm.Looped = true
	alarm.Volume = 1
	alarm.RollOffMaxDistance = 700
	alarm.Parent = alarmPart
	vault.alarm = alarm
	for _, p in { { -HX + 6, Z_FRONT + 20 }, { HX - 6, Z_FRONT + 20 }, { 20, zr }, { -66, zr } } do
		local bcn = deco(model, Vector3.new(1.2, 1.2, 1.2), at(p[1], FLOOR + (if p[2] > Z_HALL then BOH_H - 2 else H - 8), p[2]), Color3.fromRGB(120, 0, 0), Enum.Material.Glass)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 20, 20)
		l.Range = 46
		l.Brightness = 0
		l.Parent = bcn
		table.insert(vault.alarmLights, l)
	end
	vault.base = base
end

-- builds the casino on its Downtown site
function Casino.buildWorld(kit: any, parent: Instance)
	local frame, lot = WestLayout.site("casino")
	build(kit, parent, frame, lot)
end

---------------------------------------------------------------------
-- The vault heist
---------------------------------------------------------------------
-- is anyone's character inside this box (in the casino's own space)?
local function anyoneIn(x0: number, x1: number, z0: number, z1: number): boolean
	local base = vault.base
	if not base then
		return false
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp then
			local p = base:PointToObjectSpace(hrp.Position)
			if p.X > x0 and p.X < x1 and p.Z > z0 and p.Z < z1 and p.Y > -2 and p.Y < BOH_H + 4 then
				return true
			end
		end
	end
	return false
end

local function setLasers(on: boolean)
	for _, b in vault.lasers do
		b.Transparency = if on then 0 else 1
	end
	if vault.laserWall then
		vault.laserWall.CanCollide = on
	end
	for _, s in vault.screens do
		s.TextColor3 = if on then Color3.fromRGB(80, 255, 140) else Color3.fromRGB(255, 60, 60)
		local text = if on then (string.gsub(s.Text, "OFFLINE", "● REC")) else (string.gsub(s.Text, "● REC", "OFFLINE"))
		s.Text = text
	end
end

local function setRig(visible: boolean)
	local rig = vault.drillRig
	if rig then
		for _, p in rig:GetChildren() do
			if p:IsA("BasePart") then
				p.Transparency = if visible then 0 else 1
			end
		end
	end
end

local function setVaultOpen(open: boolean)
	vault.open = open
	local door = vault.door
	local hinge = vault.hinge
	if door and hinge then
		-- swing the door into the corridor round its hinge
		local swing = if open then CFrame.Angles(0, math.rad(100), 0) else CFrame.new()
		for _, p in door:GetDescendants() do
			if p:IsA("BasePart") then
				local home = p:GetAttribute("Home") :: CFrame?
				if not home then
					home = p.CFrame
					p:SetAttribute("Home", home)
				end
				local goal = hinge * swing * hinge:ToObjectSpace(home :: CFrame)
				TweenService:Create(p, TweenInfo.new(if open then 5 else 3, Enum.EasingStyle.Sine), { CFrame = goal }):Play()
			end
		end
	end
	for _, tp in vault.trolleys do
		tp.Enabled = open
		tp:SetAttribute("Left", if open then V.GrabsPerTrolley else 0)
	end
	if vault.alarm then
		if open then
			vault.alarm:Play()
		else
			vault.alarm:Stop()
		end
	end
	setRig(open)
end

function Casino.init(ctx: any, Police: any, Luxe: any)
	if vipPrompt then
		vipPrompt.Triggered:Connect(function(who: Player)
			Luxe.fire(who, { kind = "openVip" })
		end)
	end
	local hack, drill = vault.hack, vault.drill
	if hack then
		hack.Triggered:Connect(function(who: Player)
			local now = os.clock()
			if now < vault.lasersOffUntil or now < vault.lockedUntil then
				return
			end
			vault.lasersOffUntil = now + V.LasersOffSeconds
			setLasers(false)
			ctx.grantXp(who, V.HackXp, "casino")
			Luxe.fire(who, { kind = "hacked", seconds = V.LasersOffSeconds })
		end)
	end
	if drill then
		drill.Triggered:Connect(function(who: Player)
			local now = os.clock()
			if now >= vault.lasersOffUntil or now < vault.lockedUntil or vault.open then
				return
			end
			vault.openUntil = now + V.OpenSeconds
			vault.lockedUntil = now + V.OpenSeconds + V.CooldownSeconds
			-- the lasers stay off while the vault is open, so nobody gets shut in
			vault.lasersOffUntil = math.max(vault.lasersOffUntil, vault.openUntil + 20)
			setVaultOpen(true)
			Police.setWanted(who, math.max(Police.getWanted(who), V.Stars), "casino")
			Luxe.fireAll({ kind = "casinoRobbery", by = who.DisplayName })
		end)
	end
	for _, tp in vault.trolleys do
		tp.Triggered:Connect(function(who: Player)
			local left = (tp:GetAttribute("Left") :: number?) or 0
			if left <= 0 or not vault.open then
				return
			end
			local carried = (who:GetAttribute("Loot") :: number?) or 0
			if carried >= V.MaxLoot then
				Luxe.fire(who, { kind = "full" })
				return
			end
			local total, added = Luxe.addLoot(who, Luxe.levelBoost(who, math.random(V.GrabMin, V.GrabMax)), V.MaxLoot)
			tp:SetAttribute("Left", left - 1)
			if left - 1 <= 0 then
				tp.Enabled = false
			end
			Police.setWanted(who, math.max(Police.getWanted(who), V.Stars), "casino")
			Luxe.fire(who, { kind = "grab", amount = added, total = total })
		end)
	end
	-- timers: the vault closes (never on someone inside), the lasers come back, the alarm lights
	task.spawn(function()
		local blink = false
		while true do
			task.wait(0.25)
			local now = os.clock()
			if vault.open and now > vault.openUntil and not anyoneIn(-25, HX, Z_HALL, Z_BACK) then
				setVaultOpen(false)
			end
			if vault.laserWall and not vault.laserWall.CanCollide and now > vault.lasersOffUntil and not vault.open and not anyoneIn(-48, -25, Z_HALL, Z_HALL + 12) then
				setLasers(true)
			end
			local onCooldown = now < vault.lockedUntil
			if hack then
				hack.Enabled = now >= vault.lasersOffUntil and not onCooldown
			end
			if drill then
				drill.Enabled = now < vault.lasersOffUntil and not onCooldown and not vault.open
			end
			blink = not blink
			for _, l in vault.alarmLights do
				l.Brightness = if vault.open and blink then 6 else 0
			end
		end
	end)
end

return Casino
