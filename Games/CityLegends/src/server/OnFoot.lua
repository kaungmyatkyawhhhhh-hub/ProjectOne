--[[
	OnFoot (server)
	Getting out of your car and walking (owner, 2026-10-22: "make it so that u can exit the car and
	walk around"). Characters don't load on their own (Players.CharacterAutoLoads = false): getting
	out loads the player's avatar beside the driver's door and leaves the car parked; getting back
	in removes the avatar. A player who dies on foot gets up again beside their car.
	Riding along (owner, 2026-10-29): on foot, Y beside another player's car sits you in its free
	seat nearest you (front passenger, or the rear seats: Config.Passengers); Y or jump gets out.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Doors = require(script.Parent:WaitForChild("Doors")) -- (2026-11-08) scissor doors open for getting in and out

local OnFoot = {}

export type Ctx = {
	remote: (className: string, name: string) -> any,
	getCar: (player: Player) -> Model?,
	startFootCFrame: () -> CFrame,
	playerCars: Folder,
}

local ctx: Ctx
local EXIT_SPEED = 14 -- studs/s: you can get out while rolling slowly (about 30 km/h)
local ENTER_RANGE = 16
local GARDEN_RANGE = 90 -- how near the casino's garden a first car must be for a start on foot

local function carRoot(car: Model): BasePart?
	return car.PrimaryPart
end

-- beside the driver's door (left side), feet on whatever is below; `x` / `z` pick another door
-- (sx: -1 left, 1 right; z: studs back from the front doors)
local function doorSpot(car: Model, sx: number?, z: number?): CFrame
	local cf, size = car:GetBoundingBox()
	local side = cf * CFrame.new((sx or -1) * (size.X / 2 + 2.6), 0, -size.Z * 0.08 + (z or 0))
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { car }
	local hit = workspace:Raycast(side.Position + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), params)
	local y = if hit then hit.Position.Y else side.Position.Y - size.Y / 2
	local look = cf.LookVector
	local pos = Vector3.new(side.Position.X, y + 3.2, side.Position.Z)
	return CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z))
end

local function park(car: Model)
	local root = carRoot(car)
	if not root then
		return
	end
	local lv = root:FindFirstChild("Drive")
	if lv and lv:IsA("LinearVelocity") then
		lv.PlaneVelocity = Vector2.zero
	end
	car:SetAttribute("Parked", true)
end

-- the player's avatar beside their car (or at `at` when given)
local function standUp(player: Player, at: CFrame?)
	if at then
		-- (streaming: the floor there reaches the player's game first)
		pcall(function()
			player:RequestStreamAroundAsync(at.Position, 5)
		end)
	end
	player:LoadCharacterAsync()
	local character = player.Character
	if not character then
		return
	end
	local car = ctx.getCar(player)
	local spot = at or (if car and car.Parent then doorSpot(car) else ctx.startFootCFrame())
	character:PivotTo(spot)
	player.ReplicationFocus = nil
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(4)
			-- back on your feet beside your car, unless you got in or left meanwhile
			if player.Parent and player.Character == character then
				standUp(player)
			end
		end)
	end
end

function OnFoot.isOnFoot(player: Player): boolean
	return player.Character ~= nil
end

-- removes the avatar (getting into a car, or a new car from the garage)
function OnFoot.removeCharacter(player: Player)
	local character = player.Character
	if character then
		player.Character = nil
		character:Destroy()
	end
end

---------------------------------------------------------------------
-- Riding along
---------------------------------------------------------------------
-- the passenger seats, from the root: the driver's eye mirrored (front) and two behind (rear)
local function seatSpots(car: Model): { CFrame }
	local eye = car:GetAttribute("Eye")
	if typeof(eye) ~= "Vector3" then
		return {}
	end
	-- (low: a seated avatar's eyes are about 3 studs over the seat, so this puts them at the driver's
	-- eye height and the head stays under the roof)
	local hipY = eye.Y - 3.0
	local spots = { CFrame.new(-eye.X, hipY, eye.Z + 0.35) }
	local P = Config.Passengers
	if P.RearClasses[car:GetAttribute("Class")] and not P.TwoSeaters[car:GetAttribute("CarId")] then
		local rz = eye.Z + 3.0
		table.insert(spots, CFrame.new(eye.X, hipY, rz))
		table.insert(spots, CFrame.new(-eye.X, hipY, rz))
	end
	return spots
end

-- the car's seat i (made the first time someone rides: invisible, welded to the root)
local function rideSeat(car: Model, root: BasePart, i: number, at: CFrame): Seat
	local seat = car:FindFirstChild("RideSeat" .. i)
	if seat and seat:IsA("Seat") then
		return seat
	end
	local s = Instance.new("Seat")
	s.Name = "RideSeat" .. i
	s.Size = Vector3.new(1.6, 0.2, 1.6)
	s.Transparency = 1
	s.CanCollide = false
	s.CanTouch = false -- only Y seats you, never walking into it
	s.CanQuery = false
	s.Massless = true
	s.CFrame = root.CFrame * at
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = s
	w.Parent = s
	s.Parent = car
	return s
end

-- a rider adds no weight, so the driver's car handles the same
local function setMassless(character: Model, on: boolean)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d.Massless = on
		end
	end
end

local function ride(player: Player, car: any): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not (character and humanoid and hrp) or humanoid.Health <= 0 or humanoid.SeatPart then
		return false
	end
	-- only another player's car (a client can name any instance)
	if typeof(car) ~= "Instance" or not car:IsA("Model") or car.Parent ~= ctx.playerCars or car:GetAttribute("Owner") == player.UserId then
		return false
	end
	local root = carRoot(car)
	if not root then
		return false
	end
	local v = root.AssemblyLinearVelocity
	if Vector3.new(v.X, 0, v.Z).Magnitude > EXIT_SPEED then
		return false
	end
	-- the free seat nearest you
	local best, bestI, bestD = nil, 0, Config.Passengers.Range
	for i, at in seatSpots(car) do
		local seat = car:FindFirstChild("RideSeat" .. i)
		local taken = seat and seat:IsA("Seat") and seat.Occupant ~= nil
		local d = ((root.CFrame * at).Position - hrp.Position).Magnitude
		if not taken and d < bestD then
			best, bestI, bestD = at, i, d
		end
	end
	if not best then
		return false
	end
	local seat = rideSeat(car, root, bestI, best)
	-- (2026-11-08) a car with scissor doors: the passenger's door goes up first (2026-11-14: a rear seat opens its rear
	-- door on a four-door car)
	local eye = car:GetAttribute("Eye")
	local behind = best.Position.Z - (if typeof(eye) == "Vector3" then eye.Z else best.Position.Z)
	local doorSide = Doors.sideFor(car, best.Position.X, behind)
	if Doors.has(car) then
		Doors.open(car, doorSide, 1.3)
		task.wait(0.45)
		if not (car.Parent and player.Character == character and humanoid.Health > 0) or seat.Occupant then
			return false
		end
	end
	setMassless(character, true)
	seat:Sit(humanoid)
	-- getting out (Y, jump, or the car going away): weight back, stood beside that door
	local sx, z = if best.Position.X >= 0 then 1 else -1, best.Position.Z - (car:GetAttribute("Eye") :: Vector3).Z
	local conn: RBXScriptConnection
	conn = humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		if humanoid.SeatPart == seat then
			return
		end
		conn:Disconnect()
		if player.Character ~= character or humanoid.Health <= 0 then
			return
		end
		setMassless(character, false)
		if car.Parent then
			Doors.open(car, doorSide, 1.3)
			character:PivotTo(doorSpot(car, sx, z))
		end
	end)
	return true
end

-- out of the passenger seat (Y): breaking the seat weld stands you up beside the door
local function leaveRide(player: Player): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local seat = if humanoid then humanoid.SeatPart else nil
	if not (seat and seat.Name:match("^RideSeat")) then
		return false
	end
	local weld = seat:FindFirstChild("SeatWeld")
	if weld then
		weld:Destroy()
	end
	return true
end

function OnFoot.init(c: Ctx)
	ctx = c
	local ExitCar: RemoteFunction = ctx.remote("RemoteFunction", "ExitCar")
	local EnterCar: RemoteFunction = ctx.remote("RemoteFunction", "EnterCar")

	-- `where` = "garden": the start of a visit (owner, 2026-11-04: "player actually spawn at the garden
	-- of the casino"): once a visit, only when the car came out on the casino's drive (not a fast travel)
	local arrived: { [Player]: boolean } = {}
	Players.PlayerRemoving:Connect(function(player)
		arrived[player] = nil
	end)
	ExitCar.OnServerInvoke = function(player: Player, where: any)
		local car = ctx.getCar(player)
		local root = if car then carRoot(car) else nil
		if not (car and root) or player.Character then
			return false
		end
		local v = root.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > EXIT_SPEED then
			return false
		end
		if where == "garden" then
			-- (Yangon, build step 9: players start in their car on the loop by Optima Werkz)
			if Config.activeMap() == "Yangon" then
				return false
			end
			local spot = ctx.startFootCFrame()
			if arrived[player] or (spot.Position - root.Position).Magnitude > GARDEN_RANGE then
				return false
			end
			arrived[player] = true
			park(car)
			standUp(player, spot)
			return true
		end
		park(car)
		-- (2026-11-08) a car with scissor doors: the driver's door goes up, then you step out
		if Doors.has(car) then
			Doors.open(car, "L", 1.6)
			task.wait(0.45)
			if not car.Parent or player.Character then
				return false
			end
		end
		standUp(player)
		return true
	end

	EnterCar.OnServerInvoke = function(player: Player)
		local car = ctx.getCar(player)
		local character = player.Character
		local root = if car then carRoot(car) else nil
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not (car and root and hrp) then
			return false
		end
		if (hrp.Position - root.Position).Magnitude > ENTER_RANGE then
			return false
		end
		-- (2026-11-08) a car with scissor doors: the driver's door goes up, you get in, it comes down
		if Doors.has(car) then
			Doors.open(car, "L", 1.1)
			task.wait(0.5)
			if not car.Parent or player.Character ~= character then
				return false
			end
		end
		OnFoot.removeCharacter(player)
		car:SetAttribute("Parked", nil)
		root:SetNetworkOwner(player)
		player.ReplicationFocus = root
		return true
	end

	local RideCar: RemoteFunction = ctx.remote("RemoteFunction", "RideCar")
	RideCar.OnServerInvoke = function(player: Player, car: any)
		if car == nil then
			return leaveRide(player)
		end
		return ride(player, car)
	end

	Players.PlayerRemoving:Connect(function(player)
		OnFoot.removeCharacter(player)
	end)
end

-- puts a player on foot somewhere (used by the towers' elevators and the bank)
OnFoot.standUp = function(player: Player, at: CFrame?)
	standUp(player, at)
end

return OnFoot
