--[[
	Dealership
	Legends Motors, the city's car dealership (owner, 2026-10-23: "add a dealership, a real
	location"; the HUD's SHOP became CARS and shows only the cars you have). New cars are bought
	here, nowhere else:
	  * a glass showroom on its own city block (Config.Dealership), facing the city centre: a
	    white polished floor with lit strips, brand zones (a turntable with a car under a hanging
	    brand sign), a sales desk, a lit drive-out bay with a door onto the street
	  * a service building and a car park behind, a pylon sign on the forecourt corner
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

local GLASS = Color3.fromRGB(150, 180, 205)
local FRAME = Color3.fromRGB(32, 34, 40)
local WHITE = Color3.fromRGB(236, 236, 232)
local FLOOR = Color3.fromRGB(226, 226, 230)
local ACCENT = Config.Theme.Accent
local WARM = Color3.fromRGB(255, 226, 180)

-- what the dealership built (server state the remotes use)
local frame: CFrame? = nil -- ground level at the lot's middle, -Z out of the showroom
local doorCF: CFrame? = nil -- where a car driven out starts (ground level, facing the street)
-- the LEGENDS MEET car park behind the showroom (set when the block is built)
local meet: { cf: CFrame, size: Vector3 }? = nil
local prompts: { ProximityPrompt } = {}

-- a display car's model id for each turntable (built on the server, skinned on the client)
local function displayCar(parent: Instance, carId: string, top: Vector3, facing: CFrame)
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
	car:PivotTo(CFrame.new(top + Vector3.new(0, h / 2 + 0.05, 0)) * facing.Rotation * CFrame.Angles(0, math.rad(35), 0))
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
	-- the showroom: x from -SW to +SW, z from Z0 (front glass) to Z1 (back wall), H tall; the
	-- drive-out bay is its right end (x > BX)
	local SW = half - 8
	local Z0, Z1 = -half + 40, half - 72
	local H = 30
	local BX = SW - 40
	local FLOOR_T = 0.25

	-- forecourt: pale paving with a dark border, from the showroom to the sidewalk
	mk(model, Vector3.new(lot, 0.12, Z0 + half), at(0, 0.06, (-half + Z0) / 2), Color3.fromRGB(150, 146, 140), Enum.Material.Pavement, { name = "Forecourt" })
	-- the showroom floor: white polished stone
	mk(model, Vector3.new(SW * 2, FLOOR_T, Z1 - Z0), at(0, FLOOR_T / 2, (Z0 + Z1) / 2), FLOOR, Enum.Material.Marble, { reflectance = 0.18, name = "ShowroomFloor" })
	local detail = kit.lodGroup(model, "Detail", (base * CFrame.new(0, 10, 0)).Position, 520)
	-- lit strips in the floor running to the windows
	for x = -SW + 18, BX - 10, 36 do
		deco(detail, Vector3.new(0.6, 0.05, Z1 - Z0 - 8), at(x, FLOOR_T + 0.03, (Z0 + Z1) / 2), ACCENT, Enum.Material.Neon, { transparency = 0.35 })
	end
	-- roof slab with a lit fascia band all round
	mk(model, Vector3.new(SW * 2 + 6, 2.4, Z1 - Z0 + 6), at(0, H + 1.2, (Z0 + Z1) / 2), WHITE, Enum.Material.SmoothPlastic, { name = "Roof" })
	deco(model, Vector3.new(SW * 2 + 6.2, 0.6, 0.3), at(0, H + 0.4, Z0 - 3.1), ACCENT, Enum.Material.Neon)
	deco(model, Vector3.new(SW * 2 + 6.2, 0.6, 0.3), at(0, H + 0.4, Z1 + 3.1), ACCENT, Enum.Material.Neon)
	-- glass walls between dark steel mullions (front, sides; the back wall is solid)
	local function glassRun(x0: number, z0: number, x1: number, z1: number)
		local a, b = Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
		local len = (b - a).Magnitude
		local n = math.max(1, math.floor(len / 20))
		for k = 0, n - 1 do
			local p0, p1 = a:Lerp(b, k / n), a:Lerp(b, (k + 1) / n)
			local mid = (p0 + p1) / 2
			local dir = (p1 - p0).Unit
			local cf = base * CFrame.lookAt(Vector3.new(mid.X, H / 2 + FLOOR_T, mid.Z), Vector3.new(mid.X, H / 2 + FLOOR_T, mid.Z) + dir)
			mk(model, Vector3.new(0.4, H, (p1 - p0).Magnitude), cf, GLASS, Enum.Material.Glass, { transparency = 0.72, reflectance = 0.25, name = "ShowroomGlass" })
			mk(model, Vector3.new(0.9, H, 0.9), base * CFrame.new(p0.X, H / 2 + FLOOR_T, p0.Z), FRAME, Enum.Material.Metal, { name = "Mullion" })
		end
		mk(model, Vector3.new(0.9, H, 0.9), base * CFrame.new(b.X, H / 2 + FLOOR_T, b.Z), FRAME, Enum.Material.Metal, { name = "Mullion" })
	end
	glassRun(-SW, Z0, BX - 6, Z0) -- front (the bay's door is open glass)
	glassRun(-SW, Z0, -SW, Z1)
	glassRun(SW, Z0, SW, Z1)
	mk(model, Vector3.new(SW * 2, H, 1.2), at(0, H / 2 + FLOOR_T, Z1), Color3.fromRGB(44, 46, 52), Enum.Material.SmoothPlastic, { name = "BackWall" })
	-- the bay's door: a frame with a lit DRIVE OUT header, a wall between bay and showroom
	mk(model, Vector3.new(0.9, H, Z1 - Z0 - 2), at(BX - 6, H / 2 + FLOOR_T, (Z0 + Z1) / 2 + 1), FRAME, Enum.Material.Metal, { name = "BayWall" })
	local header = mk(model, Vector3.new(SW - BX + 6, 5, 1.4), at((BX - 6 + SW) / 2, H - 2.5 + FLOOR_T, Z0), FRAME, Enum.Material.Metal, { name = "BayHeader" })
	kit.surfaceText(header, Enum.NormalId.Front, "DRIVE OUT", Color3.new(1, 1, 1), nil, nil, Enum.Font.GothamBlack, Vector2.new(600, 110))
	for _, x in { BX - 4, SW - 2 } do
		deco(model, Vector3.new(0.5, H - 6, 0.5), at(x, (H - 6) / 2 + FLOOR_T, Z0 - 0.8), ACCENT, Enum.Material.Neon)
	end
	-- the bay: dark floor with yellow guide lines; the car starts here facing the street
	deco(model, Vector3.new(SW - BX - 4, 0.05, Z1 - Z0 - 10), at((BX + SW) / 2 - 1, FLOOR_T + 0.03, (Z0 + Z1) / 2), Color3.fromRGB(36, 38, 44), Enum.Material.SmoothPlastic)
	for _, dx in { -8, 8 } do
		deco(model, Vector3.new(0.4, 0.06, Z1 - Z0 - 14), at((BX + SW) / 2 - 1 + dx, FLOOR_T + 0.05, (Z0 + Z1) / 2), Color3.fromRGB(240, 196, 40), Enum.Material.Neon, { transparency = 0.2 })
	end
	local bayX = (BX + SW) / 2 - 1
	local bayP = (base * CFrame.new(bayX, FLOOR_T, (Z0 + Z1) / 2 + 6)).Position
	doorCF = CFrame.lookAt(bayP, bayP + base.LookVector)
	-- kerb ramps where the bay's lane crosses the sidewalk and meets the road
	-- (a wedge's slope faces its -Z: down towards the street; the road is CURB below the frame)
	local kerbZ = -half - C.SidewalkWidth
	mk(model, Vector3.new(SW - BX + 2, CURB, 5), at(bayX, -CURB / 2, kerbZ - 2.5), Color3.fromRGB(110, 110, 114), Enum.Material.Concrete, { class = "Wedge", name = "KerbRamp" })

	-- big LEGENDS MOTORS sign on the roof edge over the front glass
	local sign = mk(model, Vector3.new(SW * 1.3, 8, 1.2), at(-12, H + 6.5, Z0 - 1), Color3.fromRGB(14, 14, 18), Enum.Material.SmoothPlastic, { name = "DealerSign" })
	kit.surfaceText(sign, Enum.NormalId.Front, D.Name, Color3.new(1, 1, 1), nil, nil, Enum.Font.GothamBlack, Vector2.new(1400, 170))
	deco(model, Vector3.new(SW * 1.3 + 0.4, 0.4, 1.4), at(-12, H + 2.4, Z0 - 1), ACCENT, Enum.Material.Neon)
	local glow = deco(model, Vector3.new(0.5, 0.5, 0.5), at(-12, H + 6.5, Z0 - 6), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", glow, Color3.fromRGB(200, 240, 255), 30, 2, Enum.NormalId.Back, 90)

	-- the pylon sign on the forecourt's left corner, listing the brands
	local brands: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, series in Cars.Series do
		local b = series.Brand or series.Name
		if not seen[b] then
			seen[b] = true
			table.insert(brands, b)
		end
	end
	local pylonP = at(-half + 10, 0, -half + 12)
	mk(model, Vector3.new(7, 44, 3), pylonP * CFrame.new(0, 22, 0), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic, { name = "Pylon" })
	local pylonFace = deco(model, Vector3.new(6, 30, 0.2), pylonP * CFrame.new(0, 26, -1.6), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
	kit.surfaceText(pylonFace, Enum.NormalId.Front, table.concat(brands, "\n"), WHITE, nil, nil, Enum.Font.GothamBold, Vector2.new(260, 1300))
	local pylonTop = deco(model, Vector3.new(7.4, 4, 3.4), pylonP * CFrame.new(0, 42, 0), ACCENT, Enum.Material.Neon, { transparency = 0.1 })
	kit.addLight("PointLight", pylonTop, ACCENT, 30, 1.2)

	-- ceiling lights: long warm panels (a few real lights; the panels glow)
	for x = -SW + 20, BX - 10, 40 do
		for z = Z0 + 18, Z1 - 12, 34 do
			local panel = deco(detail, Vector3.new(14, 0.3, 4), at(x, H - 0.3 + FLOOR_T, z), WARM, Enum.Material.Neon, { transparency = 0.2 })
			kit.addLight("SurfaceLight", panel, WARM, 34, 1.4, Enum.NormalId.Bottom, 120)
		end
	end

	-- brand zones: a turntable with a car under a hanging brand sign and a spotlight
	local zoneCols = 4
	local spanX = (BX - 10) - (-SW + 10)
	local idx = 0
	for _, carId in D.Display do
		local spec = Cars.ById[carId]
		if not spec then
			continue
		end
		idx += 1
		local col = (idx - 1) % zoneCols
		local row = math.floor((idx - 1) / zoneCols)
		local x = -SW + 10 + spanX * (col + 0.5) / zoneCols
		local z = Z0 + 26 + row * 40
		local tableTop = FLOOR_T + 1
		mk(model, Vector3.new(1, 26, 26), at(x, FLOOR_T + 0.5, z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, reflectance = 0.15, name = "Turntable" })
		deco(model, Vector3.new(0.3, 26.6, 26.6), at(x, FLOOR_T + 0.2, z) * CFrame.Angles(0, 0, math.pi / 2), ACCENT, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
		local series = Cars.SeriesOf[carId]
		local brand = if series then series.series.Brand or series.series.Name else spec.Name
		local plate = deco(detail, Vector3.new(16, 3.2, 0.4), at(x, H - 7, z - 2), Color3.fromRGB(16, 16, 20), Enum.Material.SmoothPlastic, { name = "BrandSign" })
		kit.surfaceText(plate, Enum.NormalId.Front, brand, WHITE, nil, nil, Enum.Font.GothamBlack, Vector2.new(640, 128))
		kit.surfaceText(plate, Enum.NormalId.Back, brand, WHITE, nil, nil, Enum.Font.GothamBlack, Vector2.new(640, 128))
		deco(detail, Vector3.new(16.2, 0.25, 0.5), at(x, H - 8.75, z - 2), ACCENT, Enum.Material.Neon)
		for _, dx in { -6, 6 } do
			deco(detail, Vector3.new(0.12, 5.4, 0.12), at(x + dx, H - 2.7 - 0.3, z - 2), FRAME, Enum.Material.Metal)
		end
		local spot = deco(detail, Vector3.new(1.4, 0.6, 1.4), at(x, H - 1, z), Color3.fromRGB(255, 250, 240), Enum.Material.Neon)
		kit.addLight("SpotLight", spot, Color3.fromRGB(255, 246, 232), 40, 2.4, Enum.NormalId.Bottom, 50)
		-- the car, and a prompt by its front to open the buy screen on it
		local topPos = (at(x, tableTop, z)).Position
		displayCar(model, carId, topPos, base)
		local stand = deco(detail, Vector3.new(1.2, 3.4, 0.3), at(x + 9, FLOOR_T + 1.7, z - 12), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic, { name = "InfoStand" })
		kit.surfaceText(stand, Enum.NormalId.Front, spec.Name .. "\n$" .. tostring(spec.Price) .. "  ·  LV " .. Cars.requiredLevel(carId), WHITE, nil, nil, Enum.Font.GothamBold, Vector2.new(160, 160))
		prompt(stand, "View cars", spec.Name, carId)
	end

	-- the sales desk at the back: a long white counter with a dark top, screens and a lit sign
	local deskZ = Z1 - 14
	local deskX = (-SW + BX) / 2
	local desk = mk(model, Vector3.new(26, 4, 4), at(deskX, FLOOR_T + 2, deskZ), WHITE, Enum.Material.Marble, { name = "SalesDesk" })
	mk(model, Vector3.new(27, 0.4, 5), at(deskX, FLOOR_T + 4.2, deskZ), Color3.fromRGB(20, 20, 24), Enum.Material.Granite)
	deco(model, Vector3.new(26.2, 0.3, 0.2), at(deskX, FLOOR_T + 0.4, deskZ - 2.05), ACCENT, Enum.Material.Neon)
	for _, dx in { -7, 0, 7 } do
		deco(model, Vector3.new(3.2, 2, 0.15), at(deskX + dx, FLOOR_T + 5.6, deskZ + 0.8) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(30, 120, 200), Enum.Material.Neon, { transparency = 0.25 })
	end
	local salesSign = deco(model, Vector3.new(30, 4, 0.4), at(deskX, FLOOR_T + 13, Z1 - 0.9), Color3.fromRGB(16, 16, 20), Enum.Material.SmoothPlastic, { name = "SalesSign" })
	kit.surfaceText(salesSign, Enum.NormalId.Front, "SALES  ·  NEW CARS", WHITE, nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 120))
	prompt(desk, "Browse cars", D.Name)
	-- lounge: two sofas and a low table by the desk
	for _, dx in { -20, 20 } do
		mk(model, Vector3.new(10, 2.2, 4), at(deskX + dx, FLOOR_T + 1.1, deskZ - 14), Color3.fromRGB(46, 46, 52), Enum.Material.Fabric, { name = "Sofa" })
		mk(model, Vector3.new(10, 3, 1), at(deskX + dx, FLOOR_T + 2.5, deskZ - 12), Color3.fromRGB(46, 46, 52), Enum.Material.Fabric)
	end

	-- behind: the service building and a car park
	local backZ0 = Z1 + 6
	local backZ1 = half - 4
	mk(model, Vector3.new(SW, 22, backZ1 - backZ0), at(-SW / 2, 11, (backZ0 + backZ1) / 2), Color3.fromRGB(70, 74, 80), Enum.Material.SmoothPlastic, { name = "ServiceBuilding" })
	local servSign = deco(model, Vector3.new(SW * 0.6, 3.4, 0.3), at(-SW / 2, 17, backZ0 - 0.2), Color3.fromRGB(16, 16, 20), Enum.Material.SmoothPlastic)
	kit.surfaceText(servSign, Enum.NormalId.Front, "SERVICE", WHITE, nil, nil, Enum.Font.GothamBlack, Vector2.new(600, 70))
	for k = 0, 2 do
		deco(detail, Vector3.new(14, 12, 0.2), at(-SW + 16 + k * (SW - 20) / 2.6, 6, backZ0 - 0.15), Color3.fromRGB(150, 154, 160), Enum.Material.DiamondPlate)
	end
	-- the car park: dark asphalt, painted bays, two lamps
	local parkX0, parkX1 = 4, SW
	mk(model, Vector3.new(parkX1 - parkX0, 0.15, backZ1 - backZ0), at((parkX0 + parkX1) / 2, 0.08, (backZ0 + backZ1) / 2), Color3.fromRGB(40, 40, 44), Enum.Material.Asphalt, { name = "CarPark" })
	local bayW = 12
	local x = parkX0 + 4
	while x + bayW <= parkX1 do
		deco(detail, Vector3.new(0.35, 0.05, 18), at(x, 0.17, backZ1 - 11), Color3.fromRGB(230, 230, 226), Enum.Material.SmoothPlastic)
		x += bayW
	end
	for _, px in { parkX0 + 10, parkX1 - 10 } do
		kit.streetLight(model, (at(px, 0.15, backZ0 + 6)).Position, base.LookVector)
	end
	-- the car park is the LEGENDS MEET: a lit sign on the showroom's back wall, coloured light
	-- strips between the bays
	local meetSign = mk(model, Vector3.new(parkX1 - parkX0 - 10, 6, 0.8), at((parkX0 + parkX1) / 2, 20, Z1 + 1.1), Color3.fromRGB(14, 14, 18), Enum.Material.SmoothPlastic, { name = "MeetSign" })
	kit.surfaceText(meetSign, Enum.NormalId.Back, "LEGENDS MEET", Color3.fromRGB(255, 120, 220), nil, nil, Enum.Font.GothamBlack, Vector2.new(1000, 140))
	deco(model, Vector3.new(parkX1 - parkX0 - 9.6, 0.4, 0.9), at((parkX0 + parkX1) / 2, 16.8, Z1 + 1.1), Color3.fromRGB(80, 220, 255), Enum.Material.Neon)
	local meetGlow = deco(model, Vector3.new(0.5, 0.5, 0.5), at((parkX0 + parkX1) / 2, 14, Z1 + 6), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", meetGlow, Color3.fromRGB(255, 140, 230), 40, 1.6, Enum.NormalId.Bottom, 100)
	local sx = parkX0 + 4 + bayW / 2
	local stripCol = { Color3.fromRGB(255, 80, 200), Color3.fromRGB(70, 210, 255) }
	local k = 0
	while sx + bayW / 2 <= parkX1 do
		k += 1
		deco(detail, Vector3.new(0.3, 0.06, 16), at(sx - bayW / 2 + 0.6, 0.18, backZ1 - 11), stripCol[k % 2 + 1], Enum.Material.Neon, { transparency = 0.3 })
		sx += bayW
	end
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
