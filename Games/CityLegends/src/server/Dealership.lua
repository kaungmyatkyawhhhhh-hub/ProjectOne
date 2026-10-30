--[[
	Dealership
	Legends Motors, the city's car dealership (owner, 2026-10-23: "add a dealership, a real
	location"; the HUD's SHOP became CARS and shows only the cars you have). New cars are bought
	here, nowhere else:
	  * (redesigned 2026-10-30) a dark-glass showroom on its own city block (Config.Dealership),
	    facing the city centre: a tall front hall and a lower back hall under a stepped roof, the
	    name on a brushed-metal fascia, a canopy over the customer doors, a light stone floor,
	    a turntable stage under spotlights (D.DisplayHero), display plinths (D.Display), the sales
	    counter, a drive-out bay with its own door and lane to the street
	  * an outdoor lot with painted bays and the budget cars (D.DisplayLot), a stone pylon sign
	  * a service building and the LEGENDS MEET car park behind
	Every display car has a stand sign (name, price, level) that opens the buy screen on it.
	Walking up to the sales desk or a turntable opens the buy screen (DealerOpen); a car bought or
	picked there is driven out of the drive-out bay (DealerCall "door" sets the spawn spot).
	The turntable cars are tagged like the towers' showcase cars, so the client skins and turns them.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))

local Dealership = {}

local D = Config.Dealership
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local C = Config.City
local CURB = C.CurbHeight

-- (2026-10-30 redesign: dark glass, brushed metal, light stone, warm light; no neon)
local GLASS = Color3.fromRGB(46, 56, 66)
local BRUSHED = Color3.fromRGB(150, 152, 156)
local DARK = Color3.fromRGB(28, 28, 32)
local STONE = Color3.fromRGB(222, 216, 204)
local STONE_DARK = Color3.fromRGB(168, 160, 148)
local CANOPY = Color3.fromRGB(238, 234, 226)
local LETTER = Color3.fromRGB(255, 238, 210)
local WARM = Color3.fromRGB(255, 214, 160)
local PAINT_YELLOW = Color3.fromRGB(226, 182, 48)
local PAINT_WHITE = Color3.fromRGB(230, 230, 226)

-- what the dealership built (server state the remotes use)
local frame: CFrame? = nil -- ground level at the lot's middle, -Z out of the showroom
local doorCF: CFrame? = nil -- where a car driven out starts (ground level, facing the street)
-- the LEGENDS MEET car park behind the showroom (set when the block is built)
local meet: { cf: CFrame, size: Vector3 }? = nil
local prompts: { ProximityPrompt } = {}

-- a display car's model id for each turntable (built on the server, skinned on the client)
local function displayCar(parent: Instance, carId: string, top: Vector3, facing: CFrame, turn: number?)
	local spec = Cars.ById[carId]
	if not spec then
		return
	end
	local ok, car = pcall(CarBuilder.build, spec, { interior = false, lights = true, anchored = true })
	if not ok or not car then
		warn("[CityLegends] dealership car could not be built:", car)
		return
	end
	local h = (car:GetAttribute("Height") :: number?) or 4
	car:PivotTo(CFrame.new(top + Vector3.new(0, h / 2 + 0.05, 0)) * facing.Rotation * CFrame.Angles(0, math.rad(turn or 35), 0))
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	car.Name = "DisplayCar"
	car.Parent = parent
	-- (the client skins tower showcase cars and turns them slowly when you're near)
	CollectionService:AddTag(car, "TowerShowcase")
end

local function prompt(part: BasePart, action: string, object: string, carId: string?)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p:SetAttribute("CarId", carId or "")
	p.Parent = part
	table.insert(prompts, p)
end

-- builds Legends Motors when (bi, bj) is its block
-- (CityBuilder asks this when baking the map: this block stays empty and is built at start)
function Dealership.isBlock(bi: number, bj: number): boolean
	return bi == D.Block[1] and bj == D.Block[2]
end

function Dealership.block(kit: any, parent: Instance, bi: number, bj: number, _cx: number, _cz: number, lot: number): boolean
	if not (bi == D.Block[1] and bj == D.Block[2]) then
		return false
	end
	local mk, deco = kit.mk, kit.deco
	local base = WestLayout.dealership()
	frame = base
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the street the showroom faces
	end
	local model = Instance.new("Model")
	model.Name = "LegendsMotors"
	model.Parent = parent
	local half = lot / 2
	local detail = kit.lodGroup(model, "Detail", (base * CFrame.new(0, 10, 0)).Position, 520)

	-- the showroom (2026-10-30 redesign): x from SX0 to SX1, front glass at SZ0, back wall at SZ1;
	-- a tall front hall (HF) and a lower back hall (HB) under a stepped roof; the drive-out bay is
	-- its right end (x > BAYX); the outdoor lot is right of it, the LEGENDS MEET car park behind
	local SX0, SX1 = -half + 8, 28
	local SZ0, SZ1 = -62, 40
	local STEP = -6 -- where the tall front hall meets the lower back hall
	local HF, HB = 40, 28
	local FLOOR_T = 0.3
	local BAYX = 4
	local DOOR0, DOOR1 = -48, -34 -- the customer doors in the front glass

	-- forecourt: light stone paving from the street to the showroom; the lot: dark asphalt
	mk(model, Vector3.new(SX1 + 6 + half, 0.12, SZ0 + half), at((SX1 + 6 - half) / 2, 0.06, (-half + SZ0) / 2), Color3.fromRGB(196, 190, 178), Enum.Material.Pavement, { name = "Forecourt" })
	-- the showroom floor: light polished stone
	mk(model, Vector3.new(SX1 - SX0, FLOOR_T, SZ1 - SZ0), at((SX0 + SX1) / 2, FLOOR_T / 2, (SZ0 + SZ1) / 2), STONE, Enum.Material.Marble, { reflectance = 0.12, name = "ShowroomFloor" })

	-- the stepped roof: dark metal slabs, a thick front fascia with the name, a glass clerestory where
	-- the tall hall steps down
	mk(model, Vector3.new(SX1 - SX0 + 4, 2.4, STEP - SZ0 + 4), at((SX0 + SX1) / 2, HF + 1.2, (SZ0 + STEP) / 2 - 1), DARK, Enum.Material.Metal, { name = "Roof" })
	mk(model, Vector3.new(SX1 - SX0 + 4, 2.4, SZ1 - STEP + 2), at((SX0 + SX1) / 2, HB + 1.2, (STEP + SZ1) / 2 + 1), DARK, Enum.Material.Metal, { name = "Roof" })
	mk(model, Vector3.new(SX1 - SX0, HF - HB, 0.4), at((SX0 + SX1) / 2, (HF + HB) / 2 + 1, STEP), GLASS, Enum.Material.Glass, { transparency = 0.45, reflectance = 0.3, name = "Clerestory" })
	local fascia = mk(model, Vector3.new(SX1 - SX0 + 4.4, 8, 2), at((SX0 + SX1) / 2, HF + 4, SZ0 - 3), BRUSHED, Enum.Material.Metal, { name = "Fascia" })
	kit.surfaceText(fascia, Enum.NormalId.Front, D.Name, LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(1700, 110))
	local fasciaLamp = deco(model, Vector3.new(0.5, 0.5, 0.5), at((SX0 + SX1) / 2, HF - 1, SZ0 - 8), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", fasciaLamp, WARM, 24, 1.6, Enum.NormalId.Top, 100)

	-- tall dark-glass walls between brushed-metal mullions
	local function glassRun(x0: number, z0: number, x1: number, z1: number, h: number, y0: number?)
		local bottom = y0 or 0
		local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
		local len = (b - a).Magnitude
		local n = math.max(1, math.floor(len / 14))
		local mid0 = bottom + (h - bottom) / 2 + FLOOR_T
		for k = 0, n - 1 do
			local p0, p1 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
			local mid = (p0 + p1) / 2
			local dir = (p1 - p0).Unit
			local cf = base * CFrame.lookAt(Vector3.new(mid.X, mid0, mid.Z), Vector3.new(mid.X, mid0, mid.Z) + dir)
			mk(model, Vector3.new(0.4, h - bottom, (p1 - p0).Magnitude), cf, GLASS, Enum.Material.Glass, { transparency = 0.55, reflectance = 0.3, name = "ShowroomGlass" })
			mk(model, Vector3.new(0.7, h - bottom, 1.4), base * CFrame.new(p0.X, mid0, p0.Z), BRUSHED, Enum.Material.Metal, { name = "Mullion" })
		end
		mk(model, Vector3.new(0.7, h - bottom, 1.4), base * CFrame.new(b.X, mid0, b.Z), BRUSHED, Enum.Material.Metal, { name = "Mullion" })
	end
	glassRun(SX0, SZ0, DOOR0, SZ0, HF)
	glassRun(DOOR0, SZ0, DOOR1, SZ0, HF, 11) -- (over the doors)
	glassRun(DOOR1, SZ0, BAYX, SZ0, HF)
	glassRun(SX0, SZ0, SX0, STEP, HF)
	glassRun(SX0, STEP, SX0, SZ1, HB)
	-- over the drive-out door, and its right side: a solid stone wall
	mk(model, Vector3.new(SX1 - BAYX, HF - 16, 1.2), at((BAYX + SX1) / 2, 16 + (HF - 16) / 2 + FLOOR_T, SZ0), STONE_DARK, Enum.Material.Limestone, { name = "BayHeader" })
	mk(model, Vector3.new(1.2, HF, STEP - SZ0), at(SX1, HF / 2 + FLOOR_T, (SZ0 + STEP) / 2), STONE_DARK, Enum.Material.Limestone, { name = "SideWall" })
	mk(model, Vector3.new(1.2, HB, SZ1 - STEP), at(SX1, HB / 2 + FLOOR_T, (STEP + SZ1) / 2), STONE_DARK, Enum.Material.Limestone, { name = "SideWall" })
	-- the back wall: warm stone inside
	mk(model, Vector3.new(SX1 - SX0, HB, 1.2), at((SX0 + SX1) / 2, HB / 2 + FLOOR_T, SZ1), STONE_DARK, Enum.Material.Limestone, { name = "BackWall" })
	-- between the bay and the hall: a brushed-metal wall, open at the back so a car rolls round
	mk(model, Vector3.new(0.8, HF, 30), at(BAYX, HF / 2 + FLOOR_T, SZ0 + 15), BRUSHED, Enum.Material.Metal, { name = "BayWall" })

	-- the customer doors: a metal frame and two glass leaves you walk through
	mk(model, Vector3.new(DOOR1 - DOOR0 + 1.4, 1.2, 1.6), at((DOOR0 + DOOR1) / 2, 11 + FLOOR_T, SZ0), BRUSHED, Enum.Material.Metal, { name = "DoorHead" })
	for _, s in { 0.25, 0.75 } do
		deco(model, Vector3.new((DOOR1 - DOOR0) / 2 - 0.4, 10.6, 0.3), at(DOOR0 + (DOOR1 - DOOR0) * s, 5.5 + FLOOR_T, SZ0 - 0.4), GLASS, Enum.Material.Glass, { transparency = 0.6, reflectance = 0.25, name = "EntranceDoor" })
	end
	-- the canopy over the entrance: a thin stone-white slab on two slim columns, warm downlights
	local CAN0, CAN1 = DOOR0 - 26, DOOR1 + 26
	local canDepth = 26
	local canopy = mk(model, Vector3.new(CAN1 - CAN0, 1.6, canDepth), at((CAN0 + CAN1) / 2, 24, SZ0 - canDepth / 2), CANOPY, Enum.Material.SmoothPlastic, { name = "Canopy" })
	deco(model, Vector3.new(CAN1 - CAN0 + 0.2, 1.8, 0.4), at((CAN0 + CAN1) / 2, 24, SZ0 - canDepth), BRUSHED, Enum.Material.Metal)
	for _, x in { CAN0 + 6, CAN1 - 6 } do
		mk(model, Vector3.new(1.2, 23.2, 1.2), at(x, 11.6, SZ0 - canDepth + 4), BRUSHED, Enum.Material.Metal, { shape = Enum.PartType.Block, name = "CanopyColumn" })
	end
	kit.addLight("SurfaceLight", canopy, WARM, 26, 1.2, Enum.NormalId.Bottom, 110)

	-- the drive-out bay: dark floor, painted guide lines; the car starts here facing the street
	local bayX = (BAYX + SX1) / 2
	deco(model, Vector3.new(SX1 - BAYX - 2, 0.05, 44), at(bayX, FLOOR_T + 0.03, SZ0 + 24), Color3.fromRGB(46, 46, 50), Enum.Material.Concrete)
	for _, dx in { -7, 7 } do
		deco(detail, Vector3.new(0.4, 0.06, 40), at(bayX + dx, FLOOR_T + 0.06, SZ0 + 24), PAINT_YELLOW, Enum.Material.SmoothPlastic)
	end
	local bayP = (base * CFrame.new(bayX, FLOOR_T, SZ0 + 22)).Position
	doorCF = CFrame.lookAt(bayP, bayP + base.LookVector)
	local exitSign = deco(model, Vector3.new(14, 2.6, 0.3), at(bayX, 17.6 + FLOOR_T, SZ0 - 0.75), DARK, Enum.Material.Metal, { name = "ExitSign" })
	kit.surfaceText(exitSign, Enum.NormalId.Front, "DRIVE OUT", LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(500, 90))
	-- the lane from the bay door to the street, and a kerb ramp down to the road
	for _, dx in { -7, 7 } do
		deco(detail, Vector3.new(0.4, 0.05, SZ0 + half - 2), at(bayX + dx, 0.15, (SZ0 - half) / 2), PAINT_YELLOW, Enum.Material.SmoothPlastic)
	end
	local kerbZ = -half - C.SidewalkWidth
	mk(model, Vector3.new(SX1 - BAYX + 2, CURB, 5), at(bayX, -CURB / 2, kerbZ - 2.5), Color3.fromRGB(110, 110, 114), Enum.Material.Concrete, { class = "Wedge", name = "KerbRamp" })

	-- inside: warm ceiling panels (a few real lights), the turntable stage, display plinths, the desk
	for _, p in { { -78, -40 }, { -24, -40 }, { -78, 14 }, { -24, 14 } } do
		local y = if p[2] < STEP then HF else HB
		local panel = deco(detail, Vector3.new(18, 0.3, 6), at(p[1], y - 0.3 + FLOOR_T, p[2]), CANOPY, Enum.Material.SmoothPlastic)
		kit.addLight("SurfaceLight", panel, WARM, 40, 1.3, Enum.NormalId.Bottom, 120)
	end

	-- a stand sign by a car: its name and price
	local function stand(parent2: Instance, carId: string, p: CFrame)
		local spec = Cars.ById[carId]
		if not spec then
			return
		end
		mk(parent2, Vector3.new(0.4, 3.2, 0.4), p * CFrame.new(0, 1.6, 0), BRUSHED, Enum.Material.Metal, { name = "StandPost" })
		local plate = mk(parent2, Vector3.new(3.4, 2.2, 0.25), p * CFrame.new(0, 3.6, 0) * CFrame.Angles(math.rad(-20), 0, 0), DARK, Enum.Material.Metal, { name = "InfoStand" })
		kit.surfaceText(plate, Enum.NormalId.Front, spec.Name .. "\n$" .. tostring(spec.Price) .. "  ·  LV " .. Cars.requiredLevel(carId), LETTER, nil, nil, Enum.Font.GothamBold, Vector2.new(240, 150))
		prompt(plate, "View car", spec.Name, carId)
	end

	-- the turntable stage in the middle of the tall hall, under four spotlights
	local stageX, stageZ = (SX0 + BAYX) / 2, (SZ0 + STEP) / 2 - 2
	mk(model, Vector3.new(1.2, 38, 38), at(stageX, FLOOR_T + 0.6, stageZ) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(34, 34, 38), Enum.Material.Granite, { shape = Enum.PartType.Cylinder, reflectance = 0.1, name = "Turntable" })
	deco(model, Vector3.new(0.9, 39.2, 39.2), at(stageX, FLOOR_T + 0.45, stageZ) * CFrame.Angles(0, 0, math.pi / 2), BRUSHED, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local lp = at(stageX + math.cos(a) * 16, HF - 1.2, stageZ + math.sin(a) * 16)
		local lamp = deco(detail, Vector3.new(1.6, 2, 1.6), lp, DARK, Enum.Material.Metal, { name = "StageLamp" })
		kit.addLight("SpotLight", lamp, WARM, 48, 2.2, Enum.NormalId.Bottom, 40)
	end
	if D.DisplayHero then
		displayCar(model, D.DisplayHero, (at(stageX, FLOOR_T + 1.2, stageZ)).Position, base)
		stand(model, D.DisplayHero, at(stageX + 14, FLOOR_T, stageZ - 19))
	end

	-- display plinths round the hall
	local spots = { { SX0 + 18, SZ0 + 16 }, { SX0 + 18, SZ1 - 30 }, { BAYX - 16, SZ1 - 30 }, { stageX, SZ1 - 30 } }
	for i, carId in D.Display do
		local s = spots[i]
		if not s then
			break
		end
		mk(model, Vector3.new(16, 0.5, 24), at(s[1], FLOOR_T + 0.25, s[2]), STONE_DARK, Enum.Material.Limestone, { name = "Plinth" })
		displayCar(model, carId, (at(s[1], FLOOR_T + 0.5, s[2])).Position, base)
		stand(model, carId, at(s[1] + 10, FLOOR_T, s[2] - 12))
	end

	-- the sales counter at the back (the buy screen opens here), with a lounge in front
	local deskX, deskZ = stageX, SZ1 - 8
	local desk = mk(model, Vector3.new(30, 4, 4), at(deskX, FLOOR_T + 2, deskZ), STONE, Enum.Material.Marble, { name = "SalesDesk" })
	mk(model, Vector3.new(31, 0.4, 5), at(deskX, FLOOR_T + 4.2, deskZ), DARK, Enum.Material.Granite)
	local deskSign = deco(model, Vector3.new(32, 4, 0.4), at(deskX, FLOOR_T + 14, SZ1 - 0.9), DARK, Enum.Material.Metal, { name = "SalesSign" })
	kit.surfaceText(deskSign, Enum.NormalId.Front, "SALES  ·  NEW CARS", LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 110))
	prompt(desk, "Browse cars", D.Name)
	for _, dx in { -24, 24 } do
		mk(model, Vector3.new(10, 2.2, 4), at(deskX + dx, FLOOR_T + 1.1, deskZ - 2), Color3.fromRGB(70, 60, 52), Enum.Material.Leather, { name = "Sofa" })
		mk(model, Vector3.new(10, 3, 1), at(deskX + dx, FLOOR_T + 2.5, deskZ), Color3.fromRGB(70, 60, 52), Enum.Material.Leather)
	end

	-- the outdoor lot right of the showroom: dark asphalt, painted bays in two rows facing the
	-- aisle, the budget cars in them
	local LX0, LX1 = SX1 + 6, half - 4
	mk(model, Vector3.new(LX1 - LX0, 0.15, SZ1 + half - 4), at((LX0 + LX1) / 2, 0.08, (SZ1 - half + 4) / 2), Color3.fromRGB(44, 44, 48), Enum.Material.Asphalt, { name = "Lot" })
	local rows = { -half + 14, SZ0 + 30 } -- each row's middle (z)
	local bayW = 14
	local nBays = math.floor((LX1 - LX0 - 4) / bayW)
	local lotIdx = 0
	for r, rz in rows do
		for b = 0, nBays do
			local x = LX0 + 2 + b * bayW
			deco(detail, Vector3.new(0.35, 0.05, 20), at(x, 0.17, rz), PAINT_WHITE, Enum.Material.SmoothPlastic)
			if b < nBays then
				lotIdx += 1
				local carId = D.DisplayLot and D.DisplayLot[lotIdx]
				if carId then
					-- (front row noses to the street, back row to the aisle)
					local facing = if r == 1 then base else base * CFrame.Angles(0, math.pi, 0)
					local cx = x + bayW / 2
					displayCar(model, carId, (at(cx, 0.16, rz)).Position, facing, 0)
					stand(model, carId, at(cx + 5.5, 0.16, rz + (if r == 1 then 11 else -11)))
				end
			end
		end
	end
	for _, lp in { { LX0 + 8, -half + 30 }, { LX1 - 8, -half + 30 }, { LX1 - 8, SZ0 + 50 } } do
		kit.streetLight(model, (at(lp[1], 0.15, lp[2])).Position, -base.RightVector)
	end

	-- the pylon sign on the forecourt's left corner: a tall stone blade with the name
	local pylonP = at(-half + 9, 0, -half + 10)
	mk(model, Vector3.new(6, 48, 3), pylonP * CFrame.new(0, 24, 0), STONE, Enum.Material.Limestone, { name = "Pylon" })
	local pylonFace = deco(model, Vector3.new(4.6, 38, 0.3), pylonP * CFrame.new(0, 26, -1.6), DARK, Enum.Material.Metal)
	kit.surfaceText(pylonFace, Enum.NormalId.Front, "L\nE\nG\nE\nN\nD\nS\n\nM\nO\nT\nO\nR\nS", LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(120, 1000))
	local pylonLamp = deco(model, Vector3.new(0.5, 0.5, 0.5), pylonP * CFrame.new(0, 2, -6), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", pylonLamp, WARM, 50, 1.4, Enum.NormalId.Top, 30)

	-- behind: the service building and the LEGENDS MEET car park
	local backZ0 = SZ1 + 8
	local backZ1 = half - 4
	local servX1 = -40
	mk(model, Vector3.new(servX1 - SX0, 20, backZ1 - backZ0), at((SX0 + servX1) / 2, 10, (backZ0 + backZ1) / 2), STONE_DARK, Enum.Material.Limestone, { name = "ServiceBuilding" })
	local servSign = deco(model, Vector3.new(26, 3.4, 0.3), at((SX0 + servX1) / 2, 15, backZ0 - 0.2), DARK, Enum.Material.Metal)
	kit.surfaceText(servSign, Enum.NormalId.Front, "SERVICE", LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(600, 70))
	for k = 0, 2 do
		deco(detail, Vector3.new(12, 12, 0.2), at(SX0 + 10 + k * 16, 6, backZ0 - 0.15), Color3.fromRGB(150, 154, 160), Enum.Material.DiamondPlate)
	end
	local parkX0, parkX1 = servX1 + 6, half - 4
	mk(model, Vector3.new(parkX1 - parkX0, 0.15, backZ1 - backZ0), at((parkX0 + parkX1) / 2, 0.08, (backZ0 + backZ1) / 2), Color3.fromRGB(40, 40, 44), Enum.Material.Asphalt, { name = "CarPark" })
	local x = parkX0 + 4
	while x + bayW <= parkX1 do
		deco(detail, Vector3.new(0.35, 0.05, 18), at(x, 0.17, backZ1 - 11), PAINT_WHITE, Enum.Material.SmoothPlastic)
		x += bayW
	end
	for _, px in { parkX0 + 10, parkX1 - 10 } do
		kit.streetLight(model, (at(px, 0.15, backZ0 + 6)).Position, base.LookVector)
	end
	-- the car park is the LEGENDS MEET: its name on the showroom's back wall, warm floodlight
	local meetSign = mk(model, Vector3.new(44, 6, 0.8), at((parkX0 + SX1) / 2, 20, SZ1 + 1.1), DARK, Enum.Material.Metal, { name = "MeetSign" })
	kit.surfaceText(meetSign, Enum.NormalId.Back, "LEGENDS MEET", LETTER, nil, nil, Enum.Font.GothamBlack, Vector2.new(1000, 140))
	local meetGlow = deco(model, Vector3.new(0.5, 0.5, 0.5), at((parkX0 + parkX1) / 2, 16, SZ1 + 6), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", meetGlow, WARM, 44, 1.4, Enum.NormalId.Bottom, 100)
	local meetCF = at((parkX0 + parkX1) / 2, 0, (backZ0 + backZ1) / 2)
	meet = { cf = meetCF, size = Vector3.new(parkX1 - parkX0, 30, backZ1 - backZ0) }
	workspace:SetAttribute("MeetSpot", meetCF.Position)
	return true
end

-- is this player close enough to the showroom to buy?
function Dealership.near(player: Player, getCar: ((Player) -> Model?)?): boolean
	local f = frame
	if not f then
		return true -- (no dealership built: don't lock buying)
	end
	local pos: Vector3? = nil
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		pos = hrp.Position
	elseif getCar then
		local car = getCar(player)
		if car then
			pos = car:GetPivot().Position
		end
	end
	return pos ~= nil and ((pos :: Vector3) - f.Position).Magnitude < D.BuyRange
end

function Dealership.init(ctx: any)
	local openEvent: RemoteEvent = ctx.remote("RemoteEvent", "DealerOpen")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "DealerCall")
	for _, p in prompts do
		p.Triggered:Connect(function(player: Player)
			local id = p:GetAttribute("CarId")
			openEvent:FireClient(player, if type(id) == "string" and id ~= "" then id else nil)
		end)
	end
	call.OnServerInvoke = function(player: Player, what: any)
		if what == "door" then
			-- the next car this player drives out starts in the drive-out bay
			if doorCF and Dealership.near(player, ctx.getCar) and ctx.spawnAt then
				ctx.spawnAt[player] = doorCF
				return true
			end
			return false
		end
		return nil
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		if ctx.spawnAt then
			ctx.spawnAt[player] = nil
		end
	end)
	-- the meet: how many players' cars are parked there (the map shows it), and a small bonus each
	-- minute for each other car there while yours is parked too
	local minuteAt: { [Player]: number } = {}
	task.spawn(function()
		while true do
			task.wait(5)
			local m = meet
			if not m then
				continue
			end
			local inside: { Player } = {}
			for _, p in Players:GetPlayers() do
				local car = ctx.getCar(p)
				local root = car and car.PrimaryPart
				if root and not p.Character then
					local rel = m.cf:PointToObjectSpace(root.Position)
					if math.abs(rel.X) < m.size.X / 2 and math.abs(rel.Z) < m.size.Z / 2 and math.abs(rel.Y) < 15 and root.AssemblyLinearVelocity.Magnitude < 4 then
						table.insert(inside, p)
					end
				end
			end
			workspace:SetAttribute("MeetCount", #inside)
			local now = os.clock()
			for _, p in inside do
				if #inside >= 2 then
					minuteAt[p] = minuteAt[p] or now
					if now - minuteAt[p] >= 60 then
						minuteAt[p] = now
						local others = math.min(#inside - 1, D.MeetBonusMax)
						PlayerData.addCash(p, others * D.MeetBonusPerCar)
					end
				end
			end
			for p in minuteAt do
				if not table.find(inside, p) or #inside < 2 then
					minuteAt[p] = nil
				end
			end
		end
	end)
end

return Dealership
