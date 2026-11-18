--[[
	PlateShop (server, 19 Nov 2026): Myanmar number plates (shared/Plates.lua has the format and prices).
	  * every owned car carries a registered plate; a car with none gets a free random one ("3Q-3152")
	    the first time it spawns or the plate screen opens
	  * menu (anywhere: the car menu, Customs): ROLL a new random plate ($3,000), MOVE a plate you own
	    onto another of your cars, SELL a plate back for half of what you paid
	  * the Plate Office (a counter by the venue row, map icon "#"): CLAIM a chosen number, priced by
	    pattern (fancy numbers only here, for the prestige)
	  * plates are unique across every server: a DataStore key per plate holds the owner's UserId,
	    claimed with UpdateAsync (0 = free again); without DataStores (Studio offline) only per server
	  * taxis / YBS job vehicles get red hire plates (AA..HH), police black ones; event plates
	    (Customs looks: GGFEST26) still show over the registered plate
	Saved: profile.Plates = { Car = { [carId] = plate }, Bag = { [plate] = cash paid } }
	(the Bag holds every plate owned, on a car or spare).
	Real RTAD Yangon office: Ywarthagyi, Dagon Myothit (South), outside the built districts; the
	office stands in P1 by the venue row for now (vault research note).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared:WaitForChild("Cars"))
local Plates = require(Shared:WaitForChild("Plates"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local PlateShop = {}

-- the office counter (ground level, facing the street); measured in Studio 19 Nov
PlateShop.OFFICE = CFrame.lookAt(Vector3.new(35500, 41.08, 21960), Vector3.new(35400, 41.08, 21946))
local OFFICE_REACH = 30 -- studs from the counter for a claim

local ctx: any = nil
local rng = Random.new()
local claims: DataStore? = nil
local held: { [string]: number } = {} -- plate -> UserId, this server (also the fallback with no DataStore)

do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore((PlayerData :: any).storeName .. "_Plates")
	end)
	if ok then
		claims = result
	else
		warn("[CityLegends] Plates: no DataStore, plates are unique per server only:", result)
	end
end

-- takes `plate` for `uid` everywhere; false if someone else holds it (or the store didn't answer)
local function claim(plate: string, uid: number): boolean
	local h = held[plate]
	if h and h ~= uid then
		return false
	end
	if claims then
		local ok, result = pcall(function()
			return (claims :: DataStore):UpdateAsync(plate, function(old)
				if old == nil or old == 0 or old == uid then
					return uid
				end
				return nil -- (someone else's: no write)
			end)
		end)
		if not ok or result ~= uid then
			return false
		end
	end
	held[plate] = uid
	return true
end

local function release(plate: string, uid: number)
	if held[plate] == uid then
		held[plate] = nil
	end
	if claims then
		task.spawn(pcall, function()
			(claims :: DataStore):UpdateAsync(plate, function(old)
				return if old == uid then 0 else nil
			end)
		end)
	end
end

-- is `plate` free (or already ours)?
local function isFree(plate: string, uid: number): boolean
	local h = held[plate]
	if h then
		return h == uid
	end
	if claims then
		local ok, v = pcall(function()
			return (claims :: DataStore):GetAsync(plate)
		end)
		return ok and (v == nil or v == 0 or v == uid)
	end
	return true
end

---------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------
local function data(profile: any): { Car: { [string]: string }, Bag: { [string]: number } }
	local d = profile.Plates
	if type(d) ~= "table" then
		d = {}
		profile.Plates = d
	end
	d.Car = if type(d.Car) == "table" then d.Car else {}
	d.Bag = if type(d.Bag) == "table" then d.Bag else {}
	-- cleaned as it's read: only valid plates, only owned cars, every car plate in the bag
	for plate, paid in d.Bag do
		if not Plates.valid(plate) or type(paid) ~= "number" then
			d.Bag[plate] = nil
		end
	end
	for old, new in Cars.Swapped do
		if d.Car[old] and not d.Car[new] then
			d.Car[new] = d.Car[old]
		end
		d.Car[old] = nil
	end
	for carId, plate in d.Car do
		if not (profile.Owned[carId] and d.Bag[plate]) then
			d.Car[carId] = nil
		end
	end
	return d
end

local function carOf(d: any, plate: string): string?
	for carId, p in d.Car do
		if p == plate then
			return carId
		end
	end
	return nil
end

local function countBag(d: any): number
	local n = 0
	for _ in d.Bag do
		n += 1
	end
	return n
end

-- a fresh random plate claimed for the player (nil if the store keeps failing)
local function freshPlate(uid: number): string?
	for _ = 1, 6 do
		local t = Plates.roll(rng)
		if claim(t, uid) then
			return t
		end
	end
	return nil
end

-- the old plate leaving a car: a free one is let go, a paid one stays in the bag as a spare
local function dropOld(d: any, plate: string?, uid: number)
	if plate and d.Bag[plate] == 0 and not carOf(d, plate) then
		d.Bag[plate] = nil
		release(plate, uid)
	end
end

-- the player's live car shows `plate` (unless an event plate is on it)
local function showOn(player: Player, carId: string, plate: string)
	local car = ctx and ctx.getCar(player)
	if car and car:GetAttribute("CarId") == carId and not Plates.EVENT[car:GetAttribute("Plate") :: any] and not car:GetAttribute("JobCar") then
		car:SetAttribute("PlateKind", "private")
		car:SetAttribute("Plate", plate)
	end
end

-- the plate of one of the player's cars, given a free one if it has none (yields on a new plate)
function PlateShop.plateFor(player: Player, carId: string): string?
	local profile = PlayerData.get(player) :: any
	if not (profile and profile.Owned[carId]) then
		return nil
	end
	local d = data(profile)
	local plate = d.Car[carId]
	if plate then
		return plate
	end
	plate = freshPlate(player.UserId)
	if plate and not d.Car[carId] then
		d.Bag[plate] = 0
		d.Car[carId] = plate
	end
	return d.Car[carId]
end

-- a spawning car (Main.spawnFor): its plate, before Customs puts an event plate over it
function PlateShop.applyTo(player: Player, model: Model, carId: string, opts: any)
	model:SetAttribute("PlateKind", "private")
	local profile = PlayerData.get(player) :: any
	local d = profile and data(profile)
	local now = d and d.Car[carId]
	if now then
		model:SetAttribute("Plate", now)
	elseif profile and profile.Owned[carId] and not (opts and (opts.stolen or opts.test)) then
		model:SetAttribute("Plate", Plates.roll(rng)) -- (shown at once; the claimed one replaces it)
		task.spawn(function()
			local p = PlateShop.plateFor(player, carId)
			if p and model.Parent and model:GetAttribute("CarId") == carId then
				model:SetAttribute("Plate", p)
			end
		end)
	else
		model:SetAttribute("Plate", Plates.roll(rng)) -- (a test drive, a stolen car: some plate)
	end
end

-- a job vehicle: red hire plate for taxis and YBS vans, black for the patrol car
function PlateShop.applyJob(model: Model, job: string)
	local hire = job == "taxi" or job == "bus"
	model:SetAttribute("PlateKind", if hire then "taxi" else "private")
	model:SetAttribute("Plate", if hire then Plates.taxi(rng) else Plates.roll(rng))
end

---------------------------------------------------------------------
-- Remote calls (PlateCall)
---------------------------------------------------------------------
local function atOffice(player: Player): boolean
	local at: Vector3? = nil
	local car = ctx and ctx.getCar(player)
	if car and car.Parent then
		at = car:GetPivot().Position
	end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		at = root.Position
	end
	return at ~= nil and (at - PlateShop.OFFICE.Position).Magnitude <= OFFICE_REACH
end

local function stateOf(player: Player, profile: any): { [string]: any }
	local d = data(profile)
	local cars = {}
	for carId in profile.Owned do
		if Cars.ById[carId] then
			table.insert(cars, { id = carId, name = Cars.ById[carId].Name, plate = d.Car[carId] })
		end
	end
	table.sort(cars, function(a, b)
		return a.name < b.name
	end)
	local bag = {}
	for plate, paid in d.Bag do
		local price, why = Plates.price(plate)
		table.insert(bag, { plate = plate, paid = paid, car = carOf(d, plate), value = price, why = why[1] })
	end
	table.sort(bag, function(a, b)
		return (a.value or 0) > (b.value or 0)
	end)
	local car = ctx and ctx.getCar(player)
	local current = car and car:GetAttribute("CarId")
	return {
		ok = true,
		cars = cars,
		bag = bag,
		cash = profile.Cash,
		current = if type(current) == "string" and profile.Owned[current] then current else profile.Selected,
		office = atOffice(player),
		officeAt = PlateShop.OFFICE.Position,
	}
end

local handlers: { [string]: (Player, any, any) -> any } = {}

handlers.state = function(player)
	local profile = PlayerData.get(player) :: any
	if not profile then
		return { ok = false }
	end
	-- every owned car gets its plate here (a few store calls the first time)
	for carId in profile.Owned do
		if Cars.ById[carId] and not data(profile).Car[carId] then
			PlateShop.plateFor(player, carId)
		end
	end
	return stateOf(player, profile)
end

handlers.roll = function(player, carId)
	local profile = PlayerData.get(player) :: any
	if not (profile and type(carId) == "string" and profile.Owned[carId]) then
		return { ok = false }
	end
	if profile.Cash < Plates.ROLL_COST then
		return { ok = false, message = "Not enough cash" }
	end
	local d = data(profile)
	local plate = freshPlate(player.UserId)
	if not plate then
		return { ok = false, message = "The plate office is busy: try again" }
	end
	PlayerData.addCash(player, -Plates.ROLL_COST)
	local old = d.Car[carId]
	d.Bag[plate] = Plates.ROLL_COST
	d.Car[carId] = plate
	dropOld(d, old, player.UserId)
	showOn(player, carId, plate)
	task.spawn(PlayerData.save, player)
	local value, why = Plates.price(plate)
	return { ok = true, plate = plate, lucky = if (value or 0) > Plates.BASE then why[1] else nil, state = stateOf(player, profile) }
end

handlers.quote = function(player, raw)
	local plate = Plates.normalize(raw)
	if not plate then
		return { ok = false, message = "Plates look like 9E-9999 (no 0 in front)" }
	end
	local price, why = Plates.price(plate)
	return { ok = true, plate = plate, price = price, why = why, free = isFree(plate, player.UserId) }
end

handlers.claim = function(player, raw, carId)
	local profile = PlayerData.get(player) :: any
	local plate = Plates.normalize(raw)
	if not (profile and plate and type(carId) == "string" and profile.Owned[carId]) then
		return { ok = false, message = "Plates look like 9E-9999 (no 0 in front)" }
	end
	if not atOffice(player) then
		return { ok = false, message = "Chosen numbers are sold at the Plate Office (# on the map)" }
	end
	local d = data(profile)
	if d.Bag[plate] then
		return { ok = false, message = "You already own that plate" }
	end
	if countBag(d) >= Plates.BAG_MAX then
		return { ok = false, message = "You own too many plates: sell one first" }
	end
	local price = Plates.price(plate) :: number
	if profile.Cash < price then
		return { ok = false, message = "Not enough cash" }
	end
	if not claim(plate, player.UserId) then
		return { ok = false, message = plate .. " is taken" }
	end
	if profile.Cash < price then -- (cash can change while the store answered)
		release(plate, player.UserId)
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -price)
	local old = d.Car[carId]
	d.Bag[plate] = price
	d.Car[carId] = plate
	dropOld(d, old, player.UserId)
	showOn(player, carId, plate)
	task.spawn(PlayerData.save, player)
	return { ok = true, plate = plate, cost = price, state = stateOf(player, profile) }
end

-- a plate you own onto one of your cars (its car before gets a free plate when it next needs one)
handlers.move = function(player, plate, carId)
	local profile = PlayerData.get(player) :: any
	if not (profile and type(plate) == "string" and type(carId) == "string" and profile.Owned[carId]) then
		return { ok = false }
	end
	local d = data(profile)
	if not d.Bag[plate] then
		return { ok = false }
	end
	local from = carOf(d, plate)
	if from == carId then
		return { ok = false, message = "It's on that car already" }
	end
	local old = d.Car[carId]
	if from then
		d.Car[from] = nil
	end
	d.Car[carId] = plate
	dropOld(d, old, player.UserId)
	showOn(player, carId, plate)
	if from then
		local p = PlateShop.plateFor(player, from)
		if p then
			showOn(player, from, p)
		end
	end
	task.spawn(PlayerData.save, player)
	return { ok = true, state = stateOf(player, profile) }
end

-- sold back for half of what was paid; the plate is free for anyone again
handlers.sell = function(player, plate)
	local profile = PlayerData.get(player) :: any
	if not (profile and type(plate) == "string") then
		return { ok = false }
	end
	local d = data(profile)
	local paid = d.Bag[plate]
	if not paid then
		return { ok = false }
	end
	if paid <= 0 then
		return { ok = false, message = "Free plates can't be sold" }
	end
	local from = carOf(d, plate)
	local refund = math.floor(paid * Plates.SELL_SHARE)
	d.Bag[plate] = nil
	if from then
		d.Car[from] = nil
	end
	release(plate, player.UserId)
	PlayerData.addCash(player, refund)
	if from then
		local p = PlateShop.plateFor(player, from)
		if p then
			showOn(player, from, p)
		end
	end
	task.spawn(PlayerData.save, player)
	return { ok = true, refund = refund, state = stateOf(player, profile) }
end

---------------------------------------------------------------------
-- The Plate Office counter (the Job Center kiosk's style, in RTAD blue)
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

local function buildOffice()
	local base = PlateShop.OFFICE
	local model = Instance.new("Model")
	model.Name = "PlateOffice"
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local navy = Color3.fromRGB(18, 40, 84)
	local white = Color3.fromRGB(236, 236, 230)
	local black = Color3.fromRGB(14, 14, 18)
	part(model, Vector3.new(14, 0.5, 7), at(0, 0.25, 0.5), Color3.fromRGB(150, 146, 138), Enum.Material.Concrete)
	-- the board behind the counter: a big sample plate and the office's name
	local board = part(model, Vector3.new(9, 8, 0.8), at(0, 5.0, 2.6), navy, Enum.Material.SmoothPlastic)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.CanvasSize = Vector2.new(900, 800)
	gui.Parent = board
	local function text(t: string, y: number, h: number, size: number, color: Color3, font: Enum.Font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(30, y)
		l.Size = UDim2.new(1, -60, 0, h)
		l.Text = t
		l.TextColor3 = color
		l.TextSize = size
		l.Font = font
		l.TextWrapped = true
		l.Parent = gui
	end
	text("ROAD TRANSPORT", 40, 90, 80, white, Enum.Font.GothamBlack)
	text("PLATE OFFICE", 130, 90, 80, Color3.fromRGB(255, 196, 64), Enum.Font.GothamBlack)
	local sample = Instance.new("Frame")
	sample.BackgroundTransparency = 1
	sample.Position = UDim2.fromOffset(170, 270)
	sample.Size = UDim2.fromOffset(560, 254)
	sample.Parent = gui
	Plates.draw(sample, "9E-9999", "private")
	text("Choose your number · lucky 8s and 9s", 580, 120, 44, Color3.fromRGB(210, 214, 226), Enum.Font.GothamBold)
	-- the counter
	part(model, Vector3.new(8, 3.4, 1.6), at(0, 2.2, -0.6), white, Enum.Material.SmoothPlastic)
	part(model, Vector3.new(8.4, 0.3, 2), at(0, 4.05, -0.6), navy, Enum.Material.SmoothPlastic)
	-- canopy on two posts
	for _, x in { -6.2, 6.2 } do
		part(model, Vector3.new(0.45, 10.6, 0.45), at(x, 5.3, 3.2), black, Enum.Material.Metal)
	end
	part(model, Vector3.new(13.4, 0.3, 7.2), at(0, 10.75, 0.6), white, Enum.Material.SmoothPlastic)
	part(model, Vector3.new(13.8, 0.5, 0.3), at(0, 10.75, -3.05), navy, Enum.Material.SmoothPlastic)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(220, 230, 255)
	glow.Range = 14
	glow.Brightness = 1
	glow:AddTag("LODLight")
	glow.Parent = board
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PlateOffice"
	prompt.ActionText = "Number plates"
	prompt.ObjectText = "Plate Office"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part(model, Vector3.new(1, 1, 1), at(0, 3, -2.2), black, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
	local open: RemoteEvent = ctx.remote("RemoteEvent", "PlateOpen")
	prompt.Triggered:Connect(function(who: Player)
		open:FireClient(who)
	end)
	model.Parent = workspace
	workspace:SetAttribute("PlateOffice", base.Position) -- (the minimap's "#")
end

function PlateShop.init(c: any)
	ctx = c
	local call: RemoteFunction = ctx.remote("RemoteFunction", "PlateCall")
	call.OnServerInvoke = function(player: Player, what: any, a: any, b: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, a, b)
	end
	ctx.remote("RemoteEvent", "PlateOpen")
	buildOffice()
	Players.PlayerRemoving:Connect(function(player)
		for plate, uid in held do
			if uid == player.UserId then
				held[plate] = nil -- (the DataStore keeps the claim; this server's copy goes)
			end
		end
	end)
end

return PlateShop
