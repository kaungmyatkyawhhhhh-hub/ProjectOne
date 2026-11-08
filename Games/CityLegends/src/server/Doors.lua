--[[
	Doors (server; owner, 2026-11-08, `Prompts/Scissor doors on the SVJ and SVJ 63 (cut properly).md`): the scissor doors
	of the cars that have them (Config.Doors[<car id>] on and ReplicatedStorage.CarModels.<car id>@doors there).
	Each door is a car attribute, DoorOpenL / DoorOpenR (true = open): every player's game turns the doors from it
	(client/CarDoors). They open only when the car is (nearly) stopped, and close as it drives off.

	Doors.has(car)                    does this car have doors
	Doors.open(car, side, seconds?)   opens that door ("L" driver, "R" passenger); closes it again after `seconds`
	Doors.close(car)                  closes both
	The CarDoors remote: the owner toggles both doors while parked (Shift + F, the phone's DOORS button).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))

local Doors = {}

local ctx: any = nil
local SIDES = { "L", "R" }

local function speedOf(car: Model): number
	local root = car.PrimaryPart
	if not root then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

function Doors.has(car: Model?): boolean
	if not car or not car.Parent then
		return false
	end
	local id = car:GetAttribute("CarId")
	if type(id) ~= "string" then
		return false
	end
	local modelId = Cars.modelOf(id)
	if not (Config.Doors and Config.Doors[modelId] == true) then
		return false
	end
	local folder = ReplicatedStorage:FindFirstChild("CarModels", true)
	return folder ~= nil and folder:FindFirstChild(modelId .. "@doors", true) ~= nil
end

-- a door's next close is cancelled when it is opened again meanwhile
local token: { [Model]: { [string]: number } } = {}
-- getting in or out: the door stays up for that moment even while the parked car still rolls to a stop
local holdUntil: { [Model]: number } = {}

local function set(car: Model, side: string, open: boolean)
	token[car] = token[car] or {}
	token[car][side] = (token[car][side] or 0) + 1
	car:SetAttribute("DoorOpen" .. side, open)
end

function Doors.open(car: Model, side: string, seconds: number?)
	if not Doors.has(car) or speedOf(car) > Config.DoorFeel.MaxSpeed + 9 then
		return
	end
	set(car, side, true)
	if seconds then
		holdUntil[car] = os.clock() + seconds
		local my = token[car][side]
		task.delay(seconds, function()
			if car.Parent and token[car] and token[car][side] == my then
				set(car, side, false)
			end
		end)
	end
end

function Doors.close(car: Model)
	for _, side in SIDES do
		if car:GetAttribute("DoorOpen" .. side) then
			set(car, side, false)
		end
	end
end

local function anyOpen(car: Model): boolean
	return car:GetAttribute("DoorOpenL") == true or car:GetAttribute("DoorOpenR") == true
end

function Doors.init(c: any)
	ctx = c
	local remote: RemoteEvent = ctx.remote("RemoteEvent", "CarDoors")
	local last: { [Player]: number } = {}
	remote.OnServerEvent:Connect(function(player: Player, what: any)
		if what ~= "toggle" then
			return
		end
		local now = os.clock()
		if now - (last[player] or 0) < 0.4 then
			return
		end
		last[player] = now
		local car = ctx.getCar(player)
		if not (car and Doors.has(car)) then
			return
		end
		-- from the seat, or standing next to it
		local character = player.Character
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp and (hrp.Position - car:GetPivot().Position).Magnitude > Config.DoorFeel.Reach then
			return
		end
		if speedOf(car) > Config.DoorFeel.MaxSpeed then
			return
		end
		if anyOpen(car) then
			Doors.close(car)
		else
			for _, side in SIDES do
				set(car, side, true)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
	end)
	-- they close as the car drives off (and never stay open while driving)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		for car in token do
			if not car.Parent then
				token[car] = nil
				holdUntil[car] = nil
			elseif anyOpen(car) and speedOf(car) > Config.DoorFeel.CloseSpeed then
				local held = os.clock() < (holdUntil[car] or 0) and speedOf(car) <= Config.DoorFeel.MaxSpeed + 9
				if not held then
					Doors.close(car)
				end
			end
		end
	end)
end

return Doors
