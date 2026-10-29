--[[
	Chauffeur (server)
	The luxury chauffeur service (owner, 2026-10-22: "hire an NPC driver to transport them across
	the map in high-end luxury vehicles"). A contract for a fleet car (Config.Chauffeur.Fleet) is
	bought once; then you call that car from the phone (H) or a chauffeur stand, it pulls up on the
	road beside you, you get in and it drives you to a place from WestLayout.places().

	How the car moves: the server builds it (CarBuilder, no collisions, held by rigid align
	constraints) and gives its physics to the rider, whose client moves the constraint targets
	along the lane graph every frame (ChauffeurClient). The rider's machine owns the physics, so
	everyone else sees it glide smoothly, like a player's own car.

	While riding you're in the back with the tinted windows up: your avatar is put away, and you
	stand up again on the kerb when you arrive (or stop the ride). Your own parked car is brought
	along and left behind the chauffeur's spot (Config.Chauffeur.BringOwnCar).

	Phases per rider: "coming" (driving to you) -> "riding" -> "leaving" (pulls away, then gone).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local ChauffeurRoute = require(Shared:WaitForChild("ChauffeurRoute"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local Gate = require(script.Parent:WaitForChild("Gate"))

local CH = Config.Chauffeur

local Chauffeur = {}

type Ride = {
	car: Model,
	carId: string,
	place: string,
	phase: string,
	created: number,
	prompt: ProximityPrompt,
}

local rides: { [Player]: Ride } = {}
local ctx: any
local push: RemoteEvent
local folder: Folder
local placeById: { [string]: WestLayout.Place } = {}

local GOLD = Color3.fromRGB(214, 178, 98)

local function contracts(player: Player): { [string]: boolean }?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	local c = (profile :: any).Chauffeur
	if type(c) ~= "table" then
		c = {}
		;(profile :: any).Chauffeur = c
	end
	return c
end

local function hrpOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function spotIds(spot: ChauffeurRoute.Spot): { number }
	return { spot.seg.id, spot.s }
end

---------------------------------------------------------------------
-- Ending rides
---------------------------------------------------------------------
local function endRide(player: Player, reason: string?)
	local ride = rides[player]
	if not ride then
		return
	end
	rides[player] = nil
	player:SetAttribute("Riding", nil)
	if ride.car.Parent then
		ride.car:Destroy()
	end
	if reason and player.Parent then
		push:FireClient(player, { event = "ended", reason = reason })
	end
end

---------------------------------------------------------------------
-- The car
---------------------------------------------------------------------
local function buildCar(player: Player, carId: string, at: CFrame): Model
	local spec = Cars.get(carId)
	local model = CarBuilder.build(spec, { interior = true, lights = true, anchored = false, color = Color3.fromRGB(14, 14, 16) })
	model.Name = "Chauffeur_" .. player.Name
	model:SetAttribute("Rider", player.UserId)
	model:SetAttribute("Chauffeur", true)
	model:SetAttribute("Plate", "VIP")
	local root = model.PrimaryPart :: BasePart
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	-- rigid constraints hold the car on the rider's targets (and still in mid-air until then)
	local att = Instance.new("Attachment")
	att.Name = "ChauffeurAttachment"
	att.Parent = root
	local ap = Instance.new("AlignPosition")
	ap.Name = "ChauffeurPosition"
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.RigidityEnabled = true
	ap.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Name = "ChauffeurOrientation"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = true
	ao.Parent = root
	local h = model:GetAttribute("Height") :: number
	local cf = at + Vector3.new(0, h / 2 + 0.05, 0)
	model:PivotTo(cf)
	ap.Position = cf.Position
	ao.CFrame = cf.Rotation
	return model
end

-- the kerb beside the car's right-hand (passenger) doors, feet on the ground
local function kerbSpot(car: Model): CFrame
	local cf, size = car:GetBoundingBox()
	-- (out past the kerb lane's edge onto the sidewalk, whatever the lane width)
	local out = math.max(4, Config.City.LaneWidth / 2 - size.X / 2 + 2.5)
	local side = cf * CFrame.new(size.X / 2 + out, 0, size.Z * 0.12)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder, ctx.playerCars }
	local hit = workspace:Raycast(side.Position + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), params)
	local y = if hit then hit.Position.Y else side.Position.Y - size.Y / 2
	local pos = Vector3.new(side.Position.X, y + 3.2, side.Position.Z)
	-- facing away from the road (towards the kerb), the way you'd step out
	return CFrame.lookAt(pos, pos + Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z))
end

-- your own parked car, brought along: on the road behind the chauffeur's spot
local function bringOwnCar(player: Player, chauffeurCar: Model)
	if not CH.BringOwnCar then
		return
	end
	local own = ctx.getCar(player) :: Model?
	if not (own and own.Parent and own.PrimaryPart) then
		return
	end
	local cf = chauffeurCar:GetPivot()
	local back = ((chauffeurCar:GetAttribute("Length") :: number) / 2 + (own:GetAttribute("Length") :: number) / 2 + 6)
	local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if flat.Magnitude < 0.01 then
		return
	end
	flat = flat.Unit
	local pos = cf.Position - flat * back
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder, ctx.playerCars }
	local hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -40, 0), params)
	local y = if hit then hit.Position.Y else pos.Y - (chauffeurCar:GetAttribute("Height") :: number) / 2
	local root = own.PrimaryPart :: BasePart
	local h = own:GetAttribute("Height") :: number
	local target = CFrame.lookAt(Vector3.new(pos.X, y + h / 2 + 0.3, pos.Z), Vector3.new(pos.X, y + h / 2 + 0.3, pos.Z) + flat)
	own:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local steer = root:FindFirstChild("Steer")
	if steer and steer:IsA("AlignOrientation") then
		steer.CFrame = target.Rotation
	end
	local drive = root:FindFirstChild("Drive")
	if drive and drive:IsA("LinearVelocity") then
		drive.PlaneVelocity = Vector2.zero
	end
	own:SetAttribute("Parked", true)
end

---------------------------------------------------------------------
-- Remote handlers
---------------------------------------------------------------------
local handlers: { [string]: (Player, any, any) -> any } = {}

handlers.state = function(player)
	local c = contracts(player) or {}
	local owned = {}
	for id in c do
		table.insert(owned, id)
	end
	local ride = rides[player]
	return {
		contracts = owned,
		ride = if ride then { carId = ride.carId, place = ride.place, phase = ride.phase, car = ride.car.Name } else nil,
	}
end

handlers.buy = function(player, carId)
	local price = if type(carId) == "string" then CH.Fleet[carId] else nil
	local c = contracts(player)
	local profile = PlayerData.get(player)
	if not (price and c and profile) then
		return { ok = false, message = "Not in the fleet" }
	end
	if c[carId] then
		return { ok = true, message = "Already on contract" }
	end
	if profile.Cash < price then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -price)
	c[carId] = true
	task.spawn(PlayerData.save, player)
	return { ok = true, message = Cars.get(carId).Name .. " chauffeur on contract", cash = profile.Cash }
end

handlers.call = function(player, carId, placeId)
	local c = contracts(player)
	if not (type(carId) == "string" and c and c[carId]) then
		return { ok = false, message = "Sign a contract for that car first" }
	end
	local place = if type(placeId) == "string" then placeById[placeId] else nil
	if not place then
		return { ok = false, message = "Unknown place" }
	end
	-- (the Summit is gated: residents only)
	if place.id == "isle_top" and not Gate.mayEnter(player) then
		return { ok = false, message = "The Summit is residents only" }
	end
	if player:GetAttribute("Riding") then
		return { ok = false, message = "You're already riding" }
	end
	local hrp = hrpOf(player)
	if not hrp then
		return { ok = false, message = if ctx.getCar(player) then "Get out of your car first (Y)" else "Step out onto the street first" }
	end
	local feet = hrp.Position - Vector3.new(0, 3, 0)
	local pickups = ChauffeurRoute.nearestList(feet, CH.PickupRange, nil, true, 6)
	if #pickups == 0 then
		return { ok = false, message = "Walk to a road first" }
	end
	local dests = ChauffeurRoute.nearestList(place.cf.Position, 45, place.cf.LookVector, true, 4)
	if #dests == 0 then
		return { ok = false, message = "No road there yet" }
	end
	local pickPos = CityLayout.sample(pickups[1].seg, pickups[1].s)
	local destPos = CityLayout.sample(dests[1].seg, dests[1].s)
	if (pickPos - destPos).Magnitude < 60 then
		return { ok = false, message = "You're already there" }
	end
	local pickup, dest = ChauffeurRoute.connect(pickups, dests)
	if not (pickup and dest) then
		return { ok = false, message = "No road there yet" }
	end
	-- the car starts out of sight up the road (or right there when nothing leads in)
	local start = ChauffeurRoute.backFrom(pickup, CH.ArriveFrom)
	if not ChauffeurRoute.find(start, pickup) then
		start = pickup
	end
	endRide(player)
	local p, dir = CityLayout.sample(start.seg, start.s)
	local car = buildCar(player, carId, CFrame.lookAt(p, p + dir))
	car:SetAttribute("Place", place.id)
	local root = car.PrimaryPart :: BasePart

	-- getting in: the rear door (only the rider may)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChauffeurBoard"
	prompt.ActionText = "Get in"
	prompt.ObjectText = Cars.get(carId).Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	-- (each client hides it; the rider's shows it once the car has stopped)
	prompt.Parent = root
	car.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	car.Parent = folder
	root:SetNetworkOwner(player)

	local r: Ride = { car = car, carId = carId, place = place.id, phase = "coming", created = os.clock(), prompt = prompt }
	rides[player] = r
	prompt.Triggered:Connect(function(who: Player)
		if who ~= player or rides[player] ~= r or r.phase ~= "coming" then
			return
		end
		local here = hrpOf(player)
		if not here or (here.Position - root.Position).Magnitude > 22 then
			return
		end
		if root.AssemblyLinearVelocity.Magnitude > 8 then
			return
		end
		r.phase = "riding"
		prompt:Destroy()
		OnFoot.removeCharacter(player)
		player:SetAttribute("Riding", true)
		player.ReplicationFocus = root
		push:FireClient(player, { event = "boarded", car = car.Name })
	end)
	-- a car you never got into leaves
	task.delay(CH.WaitSeconds, function()
		if rides[player] == r and r.phase == "coming" then
			endRide(player, "Your driver couldn't wait any longer")
		end
	end)
	return {
		ok = true,
		car = car.Name,
		carId = carId,
		place = place.id,
		start = spotIds(start),
		pickup = spotIds(pickup),
		dest = spotIds(dest),
	}
end

-- at the destination (or "stop here"): out on the kerb, the car pulls away
handlers.arrive = function(player)
	local r = rides[player]
	if not r or r.phase ~= "riding" then
		return { ok = false }
	end
	local root = r.car.PrimaryPart
	if not root then
		endRide(player)
		OnFoot.standUp(player)
		return { ok = false }
	end
	r.phase = "leaving"
	player:SetAttribute("Riding", nil)
	bringOwnCar(player, r.car)
	OnFoot.standUp(player, kerbSpot(r.car))
	local car = r.car
	task.delay(8, function()
		if rides[player] == r then
			rides[player] = nil
		end
		if car.Parent then
			car:Destroy()
		end
	end)
	return { ok = true }
end

handlers.cancel = function(player)
	local r = rides[player]
	if r and r.phase == "riding" then
		-- cancelling mid-ride is "stop here"
		return handlers.arrive(player)
	end
	endRide(player)
	return { ok = true }
end

---------------------------------------------------------------------
-- Chauffeur stands (city corners): a kiosk that opens the phone
---------------------------------------------------------------------
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function stand(parent: Instance, base: CFrame)
	local model = Instance.new("Model")
	model.Name = "ChauffeurStand"
	local at = function(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local black = Color3.fromRGB(14, 14, 18)
	-- plinth, the kiosk column, gold trim
	part(model, Vector3.new(6, 0.5, 3.2), at(0, 0.25, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Marble)
	local column = part(model, Vector3.new(3.6, 9, 1.4), at(0, 5, 0), black, Enum.Material.Glass, { Reflectance = 0.15 })
	for _, x in { -1.85, 1.85 } do
		part(model, Vector3.new(0.18, 9.2, 1.5), at(x, 5, 0), GOLD, Enum.Material.Metal, { Reflectance = 0.2 })
	end
	part(model, Vector3.new(3.9, 0.25, 1.6), at(0, 9.6, 0), GOLD, Enum.Material.Metal, { Reflectance = 0.2 })
	-- the lit panel: both faces
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.Brightness = 1.6
		gui.CanvasSize = Vector2.new(360, 900)
		gui.Parent = column
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
		bg.BorderSizePixel = 0
		bg.Parent = gui
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(Color3.fromRGB(30, 26, 18), Color3.fromRGB(6, 6, 10))
		grad.Rotation = 90
		grad.Parent = bg
		local function text(t: string, y: number, h: number, size: number, color: Color3, font: Enum.Font)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromOffset(20, y)
			l.Size = UDim2.new(1, -40, 0, h)
			l.Text = t
			l.TextColor3 = color
			l.TextSize = size
			l.Font = font
			l.TextWrapped = true
			l.Parent = bg
		end
		text("★", 90, 120, 110, GOLD, Enum.Font.GothamBlack)
		text("LEGENDS", 240, 70, 58, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
		text("CHAUFFEUR", 310, 60, 44, GOLD, Enum.Font.GothamBold)
		text("Private drivers\nany time, anywhere", 420, 110, 30, Color3.fromRGB(200, 200, 210), Enum.Font.Gotham)
		text("PRESS  H", 720, 60, 34, GOLD, Enum.Font.GothamBlack)
	end
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 14
	glow.Brightness = 1.2
	glow:AddTag("LODLight") -- off when far away, like the street lamps
	glow.Parent = column
	-- velvet rope posts either side (a VIP pick-up point)
	for _, x in { -5.5, 5.5 } do
		part(model, Vector3.new(0.5, 3.2, 0.5), at(x, 1.6, -1.2), GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, CFrame = at(x, 1.6, -1.2) * CFrame.Angles(0, 0, math.pi / 2) })
		part(model, Vector3.new(0.7, 0.7, 0.7), at(x, 3.4, -1.2), GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Ball })
	end
	for _, x in { -3.6, 3.6 } do
		part(model, Vector3.new(3.4, 0.3, 0.3), at(x, 2.6, -1.2), Color3.fromRGB(120, 10, 26), Enum.Material.Fabric)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ChauffeurStand"
	prompt.ActionText = "Call a chauffeur"
	prompt.ObjectText = "Legends Chauffeur"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = column
	prompt.Triggered:Connect(function(who: Player)
		push:FireClient(who, { event = "openPhone" })
	end)
	model.Parent = parent
end

local function buildStands()
	local parent = Instance.new("Folder")
	parent.Name = "ChauffeurStands"
	for _, st in CH.Stands do
		local i, j, si, sj = st[1], st[2], st[3], st[4]
		if not (CityLayout.inGrid(i, j)) then
			continue
		end
		local corner = ActivityData.corner(i, j, si, sj)
		-- along the block edge from the corner (clear of the signal poles), facing the road
		local along = Vector3.new(si * 34, 0, 0)
		local p = corner + along + Vector3.new(0, 0, sj * 2.2)
		local towardsRoad = Vector3.new(0, 0, -sj)
		stand(parent, CFrame.lookAt(p, p + towardsRoad))
	end
	parent.Parent = workspace
end

---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
function Chauffeur.init(c: any)
	ctx = c
	for _, place in WestLayout.places() do
		placeById[place.id] = place
	end
	folder = Instance.new("Folder")
	folder.Name = "Chauffeurs"
	folder.Parent = workspace
	push = ctx.remote("RemoteEvent", "ChauffeurPush")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "ChauffeurCall")
	call.OnServerInvoke = function(player: Player, what: any, a: any, b: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, a, b)
	end
	-- warm the route tables (the lane graph's parallel lanes) before anyone calls
	task.spawn(ChauffeurRoute.graph)
	buildStands()

	-- your own car from the garage (or leaving) ends a ride
	ctx.playerCars.ChildAdded:Connect(function(model: Instance)
		for player, r in rides do
			if model:GetAttribute("Owner") == player.UserId and r.phase ~= "leaving" then
				endRide(player, "Ride cancelled")
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		endRide(player)
	end)
	-- a rider whose car vanished gets put back on their feet
	task.spawn(function()
		while true do
			task.wait(2)
			for player, r in rides do
				if not r.car.Parent then
					local riding = r.phase == "riding"
					endRide(player, "Ride ended")
					if riding and player.Parent and not player.Character then
						OnFoot.standUp(player)
					end
				end
			end
		end
	end)
end

-- for other modules: is this player in a chauffeur car right now
function Chauffeur.isRiding(player: Player): boolean
	local r = rides[player]
	return r ~= nil and r.phase == "riding"
end

return Chauffeur
