--[[
	OnFoot (server)
	Getting out of your car and walking (owner, 2026-10-22: "make it so that u can exit the car and
	walk around"). Characters don't load on their own (Players.CharacterAutoLoads = false): getting
	out loads the player's avatar beside the driver's door and leaves the car parked; getting back
	in removes the avatar. A player who dies on foot gets up again beside their car.
]]

local Players = game:GetService("Players")

local OnFoot = {}

export type Ctx = {
	remote: (className: string, name: string) -> any,
	getCar: (player: Player) -> Model?,
}

local ctx: Ctx
local EXIT_SPEED = 14 -- studs/s: you can get out while rolling slowly (about 30 km/h)
local ENTER_RANGE = 16

local function carRoot(car: Model): BasePart?
	return car.PrimaryPart
end

-- beside the driver's door (left side), feet on whatever is below
local function doorSpot(car: Model): CFrame
	local cf, size = car:GetBoundingBox()
	local side = cf * CFrame.new(-(size.X / 2 + 2.6), 0, -size.Z * 0.08)
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
	player:LoadCharacterAsync()
	local character = player.Character
	if not character then
		return
	end
	local car = ctx.getCar(player)
	local spot = at or (if car and car.Parent then doorSpot(car) else nil)
	if spot then
		character:PivotTo(spot)
	end
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

function OnFoot.init(c: Ctx)
	ctx = c
	local ExitCar: RemoteFunction = ctx.remote("RemoteFunction", "ExitCar")
	local EnterCar: RemoteFunction = ctx.remote("RemoteFunction", "EnterCar")

	ExitCar.OnServerInvoke = function(player: Player)
		local car = ctx.getCar(player)
		local root = if car then carRoot(car) else nil
		if not (car and root) or player.Character then
			return false
		end
		local v = root.AssemblyLinearVelocity
		if Vector3.new(v.X, 0, v.Z).Magnitude > EXIT_SPEED then
			return false
		end
		park(car)
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
		OnFoot.removeCharacter(player)
		car:SetAttribute("Parked", nil)
		root:SetNetworkOwner(player)
		player.ReplicationFocus = root
		return true
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
