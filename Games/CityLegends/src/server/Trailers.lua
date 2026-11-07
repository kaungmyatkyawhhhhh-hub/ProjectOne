--[[
	Trailers (server, owner 2026-11-07). A player owns a trailer like a car (profile.Trailers). Out in the world it
	is an anchored model in workspace.Trailers. Parked, its deck and ramps are solid and it stands where the server
	put it. Hitched, every player's screen moves it behind the towing car (client/TrailerClient.lua): nothing here
	simulates it, so it can't fling or fall through anything. The driver's game reports where it is once a second,
	so it parks in the right place.

	A car on the trailer is a dressed copy welded to the deck; the real car is put away. Only one car of yours is
	ever out, so unloading brings the loaded car out and puts the car you came in away.
	Remotes: TrailerCall (RemoteFunction), TrailerPose (RemoteEvent, the driver's reported spot), TrailerNote.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Server = script.Parent
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local Config = require(Shared:WaitForChild("Config"))
local TrailerBuilder = require(Shared:WaitForChild("TrailerBuilder"))
local PlayerData = require(Server:WaitForChild("PlayerData"))
local Dealership = require(Server:WaitForChild("Dealership"))
local Customs = require(Server:WaitForChild("Customs"))

local T = Config.Towing
local TR = T.Trailer
local Trailers = {}

type State = { model: Model, root: BasePart, hitched: boolean, car: Model?, load: string?, loadModel: Model?, pose: CFrame? }

local ctx: any = nil
local states: { [Player]: State } = {}
local folder: Folder
local Note: RemoteEvent

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function groundAt(p: Vector3): number?
	local list: { Instance } = {}
	for _, name in { "PlayerCars", "Trailers", "Traffic", "Pedestrians" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(list, f)
		end
	end
	rayParams.FilterDescendantsInstances = list
	local hit = workspace:Raycast(p + Vector3.new(0, 12, 0), Vector3.new(0, -40, 0), rayParams)
	return if hit then hit.Position.Y else nil
end

local function ownsTrailer(player: Player): boolean
	local profile = PlayerData.get(player)
	return profile ~= nil and profile.Trailers[TR.Id] == true
end

local function loadKg(st: State?): number
	if not st or not st.load then
		return 0
	end
	return CarStats.of(st.load).weightKg
end

local function tooHeavy(car: Model, st: State?, extraKg: number?): boolean
	return TR.Kg + loadKg(st) + (extraKg or 0) > CarStats.towKg(car:GetAttribute("CarId") :: string)
end

local function setSolid(st: State, solid: boolean)
	for _, d in st.model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Solid") then
			d.CanCollide = solid
			d.CanQuery = solid
		end
	end
end

local function publish(st: State)
	local m = st.model
	m:SetAttribute("Hitched", st.hitched)
	m:SetAttribute("Load", st.load or "")
	m:SetAttribute("TotalKg", TR.Kg + loadKg(st))
	-- (parked and empty, the ramps stay down, ready to drive on)
	m:SetAttribute("RampsDown", not st.hitched and st.load == nil)
end

local function setLoad(player: Player, st: State, carId: string?)
	if st.loadModel then
		st.loadModel:Destroy()
		st.loadModel = nil
	end
	st.load = carId
	if carId then
		local ok, car = pcall(CarBuilder.build, Cars.get(carId), { interior = false, lights = false, anchored = false })
		if ok and car then
			pcall(Customs.applyTo, player, car, carId)
			car.Name = "LoadedCar"
			car:SetAttribute("CarId", carId)
			local r = car.PrimaryPart :: BasePart
			local h = (car:GetAttribute("Height") :: number?) or 4
			for _, d in car:GetDescendants() do
				if d:IsA("BasePart") then
					d.CanCollide = false
					d.CanQuery = false
					d.CanTouch = false
					d.Massless = true
				end
			end
			car:PivotTo(st.root.CFrame * CFrame.new(0, TR.DeckHeight + h / 2 + 0.06, TR.LoadZ))
			r.Anchored = false
			local w = Instance.new("WeldConstraint")
			w.Part0 = st.root
			w.Part1 = r
			w.Parent = r
			car.Parent = st.model
			CollectionService:AddTag(car, "TrailerLoad")
			st.loadModel = car
		end
	end
	publish(st)
end

-- where the hitch of this car is, near enough (the screens work it out exactly)
local function hitchPoint(car: Model): Vector3
	local len = (car:GetAttribute("Length") :: number?) or 15
	return (car:GetPivot() * CFrame.new(0, -1, len / 2)).Position
end

local function couplerPoint(st: State): Vector3
	return (st.root.CFrame * CFrame.new(0, TR.CouplerHeight, -TR.AxleToHitch)).Position
end

local function canTow(player: Player, car: Model?): (boolean, string?)
	if not car then
		return false, "Get in a car first"
	end
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return false, "Only your own car can tow"
	end
	if CarStats.towKg(car:GetAttribute("CarId") :: string) <= 0 then
		return false, "This car can't tow"
	end
	if ctx.isRacing(player) then
		return false, "Not in a race"
	end
	if ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
		return false, "Lose the police first"
	end
	return true, nil
end

local function make(player: Player, cf: CFrame): State
	local model = TrailerBuilder.build()
	model.Name = player.Name
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("OwnerName", player.Name)
	-- (hitched, the server's copy stays put while every screen moves it: it mustn't stream out)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model:PivotTo(cf)
	model.Parent = folder
	local st: State = { model = model, root = model.PrimaryPart :: BasePart, hitched = false, car = nil, load = nil, loadModel = nil, pose = nil }
	states[player] = st
	setSolid(st, true)
	publish(st)
	return st
end

-- the trailer's spot straight behind this car, on the ground
local function behind(car: Model): CFrame
	local cf = car:GetPivot()
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local len = (car:GetAttribute("Length") :: number?) or 15
	local at = cf.Position - look * (len / 2 + 0.5 + TR.AxleToHitch)
	local y = groundAt(at) or (cf.Position.Y - 2)
	return CFrame.lookAt(Vector3.new(at.X, y, at.Z), Vector3.new(at.X, y, at.Z) + look)
end

local function hitch(st: State, car: Model)
	st.hitched = true
	st.car = car
	st.pose = behind(car)
	setSolid(st, false)
	publish(st)
end

local function unhitch(st: State, cf: CFrame?)
	st.hitched = false
	st.car = nil
	local at = cf or st.pose or st.root.CFrame
	local y = groundAt(at.Position) or at.Position.Y
	-- (always a new value: each screen moved it itself, and only a change comes through to them)
	st.model:PivotTo(at + Vector3.new(0, y - at.Position.Y + math.random() * 0.002, 0))
	st.pose = nil
	setSolid(st, true)
	publish(st)
end

local function remove(player: Player)
	local st = states[player]
	if st then
		st.model:Destroy()
		states[player] = nil
	end
end

function Trailers.isTowing(player: Player): boolean
	local st = states[player]
	return st ~= nil and st.hitched
end

local handlers: { [string]: (Player, any, State?) -> { [string]: any } } = {}

local function reply(player: Player, ok: boolean, message: string?): { [string]: any }
	local st = states[player]
	return {
		ok = ok,
		message = message,
		owned = ownsTrailer(player),
		out = st ~= nil,
		hitched = st ~= nil and st.hitched,
		load = if st then st.load else nil,
	}
end

handlers.state = function(player)
	return reply(player, true)
end

handlers.buy = function(player)
	local profile = PlayerData.get(player)
	if not profile then
		return reply(player, false, "Profile not loaded")
	end
	if ownsTrailer(player) then
		return reply(player, false, "You already own it: CARS > TRAILER")
	end
	if not Dealership.near(player, ctx.getCar) then
		return reply(player, false, "Buy it at " .. Config.Dealership.Name)
	end
	if profile.Cash < TR.Price then
		return reply(player, false, "Not enough cash")
	end
	PlayerData.addCash(player, -TR.Price)
	profile.Trailers[TR.Id] = true
	task.spawn(PlayerData.save, player)
	return reply(player, true, TR.Name .. " bought")
end

-- comes out already hitched to the car you are in
handlers.take = function(player, _, st)
	if not ownsTrailer(player) then
		return reply(player, false, "Buy a trailer at " .. Config.Dealership.Name)
	end
	local car = ctx.getCar(player)
	local ok, why = canTow(player, car)
	if not ok then
		return reply(player, false, why)
	end
	if tooHeavy(car, st) then
		return reply(player, false, "Too heavy for this car")
	end
	local cf = behind(car)
	if st then
		st.model:PivotTo(cf)
	else
		st = make(player, cf)
	end
	hitch(st :: State, car)
	return reply(player, true, "Trailer hitched")
end

-- out on its own, in front of you (reverse up to it to hitch)
handlers.park = function(player, _, st)
	if not ownsTrailer(player) then
		return reply(player, false, "Buy a trailer at " .. Config.Dealership.Name)
	end
	local character = player.Character
	local car = ctx.getCar(player)
	local base = if character then character:GetPivot() elseif car then car:GetPivot() else nil
	if not base then
		return reply(player, false, "Not here")
	end
	local look = Vector3.new(base.LookVector.X, 0, base.LookVector.Z)
	look = if look.Magnitude > 0.1 then look.Unit else Vector3.new(0, 0, -1)
	local at = base.Position + look * 30
	local y = groundAt(at)
	if not y then
		return reply(player, false, "No room here")
	end
	local cf = CFrame.lookAt(Vector3.new(at.X, y, at.Z), Vector3.new(at.X, y, at.Z) + look)
	if st then
		if st.hitched then
			unhitch(st, cf)
		else
			st.model:PivotTo(cf)
		end
	else
		make(player, cf)
	end
	return reply(player, true, "Trailer out")
end

handlers.hitch = function(player, _, st)
	if not st then
		return reply(player, false, "No trailer out")
	end
	local car = ctx.getCar(player)
	local ok, why = canTow(player, car)
	if not ok then
		return reply(player, false, why)
	end
	if (hitchPoint(car) - couplerPoint(st)).Magnitude > T.HitchRange + 6 then
		return reply(player, false, "Back up to the trailer")
	end
	if tooHeavy(car, st) then
		return reply(player, false, "Too heavy for this car")
	end
	hitch(st, car)
	return reply(player, true, "Trailer hitched")
end

handlers.unhitch = function(player, cf, st)
	if not st or not st.hitched then
		return reply(player, false, "No trailer on")
	end
	local car = ctx.getCar(player)
	local spot = if typeof(cf) == "CFrame" then cf else nil
	if spot and car and (spot.Position - car:GetPivot().Position).Magnitude > 60 then
		spot = nil
	end
	unhitch(st, spot)
	return reply(player, true, "Trailer unhitched")
end

-- your car on the deck (or at the ramps): strapped down, and you're out
handlers.strap = function(player, _, st)
	if not st then
		return reply(player, false, "No trailer out")
	end
	if st.hitched then
		return reply(player, false, "Unhitch it first")
	end
	if st.load then
		return reply(player, false, "There's a car on it already")
	end
	local car = ctx.getCar(player)
	if not car then
		return reply(player, false, "Drive a car onto it")
	end
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return reply(player, false, "Only your own cars go on your trailer")
	end
	local q = st.root.CFrame:PointToObjectSpace(car:GetPivot().Position)
	if math.abs(q.X) > TR.Width / 2 + 3 or q.Z < TR.DeckFront - 2 or q.Z > TR.DeckBack + TR.RampLength + 8 or q.Y > 12 then
		return reply(player, false, "Drive up the ramps first")
	end
	local id = car:GetAttribute("CarId") :: string
	ctx.despawn(player)
	setLoad(player, st, id)
	return reply(player, true, "Strapped down")
end

-- from the garage straight onto it
handlers.load = function(player, carId, st)
	if not st then
		return reply(player, false, "No trailer out")
	end
	if st.load then
		return reply(player, false, "There's a car on it already")
	end
	local profile = PlayerData.get(player)
	if type(carId) ~= "string" or not profile or not profile.Owned[carId] then
		return reply(player, false, "Only your own cars go on your trailer")
	end
	local car = ctx.getCar(player)
	if car and car:GetAttribute("CarId") == carId then
		return reply(player, false, "You're driving that one")
	end
	if st.hitched and car and tooHeavy(car, nil, CarStats.of(carId).weightKg) then
		return reply(player, false, "Too heavy for this car")
	end
	setLoad(player, st, carId)
	return reply(player, true, "Car loaded")
end

handlers.unload = function(player, _, st)
	if not st or not st.load then
		return reply(player, false, "Nothing on it")
	end
	local character = player.Character
	if not character then
		return reply(player, false, "Get out and stand by the trailer")
	end
	local axle = if st.hitched and st.pose then st.pose.Position else st.root.Position
	if (character:GetPivot().Position - axle).Magnitude > T.UnloadRange + 10 then
		return reply(player, false, "Stand by the trailer")
	end
	if st.hitched then
		unhitch(st)
	end
	-- the ramps first, then the car off them, nose away from the trailer
	st.model:SetAttribute("RampsDown", true)
	task.wait(1)
	local carId = st.load
	if not carId or states[player] ~= st then
		return reply(player, false)
	end
	local cf = st.root.CFrame * CFrame.new(0, 0, TR.DeckBack + TR.RampLength + 10) * CFrame.Angles(0, math.pi, 0)
	setLoad(player, st, nil)
	ctx.spawnCar(player, carId, { at = cf })
	return reply(player, true, "Unloaded")
end

-- back to the garage, with any car on it
handlers.stow = function(player)
	remove(player)
	return reply(player, true, "Trailer put away")
end

function Trailers.init(c: any)
	ctx = c
	folder = Instance.new("Folder")
	folder.Name = "Trailers"
	folder.Parent = workspace
	Note = ctx.remote("RemoteEvent", "TrailerNote")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "TrailerCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg, states[player])
	end
	local pose: RemoteEvent = ctx.remote("RemoteEvent", "TrailerPose")
	pose.OnServerEvent:Connect(function(player: Player, cf: any)
		local st = states[player]
		local car = ctx.getCar(player)
		if st and st.hitched and car and typeof(cf) == "CFrame" and (cf.Position - car:GetPivot().Position).Magnitude < 60 then
			st.pose = cf
		end
	end)
	Players.PlayerRemoving:Connect(remove)
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, st in states do
				local car = ctx.getCar(player)
				if st.hitched then
					-- the towing car went (put away, swapped) or the police came: the trailer stays where it is
					if car ~= st.car then
						unhitch(st)
					elseif ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
						unhitch(st)
						Note:FireClient(player, "Police! The trailer is left behind")
					elseif ctx.isRacing(player) then
						unhitch(st)
					end
				end
				-- the car on the deck was taken out of the garage: it left the trailer
				if st.load and car and car:GetAttribute("CarId") == st.load then
					setLoad(player, st, nil)
				end
			end
		end
	end)
end

return Trailers
