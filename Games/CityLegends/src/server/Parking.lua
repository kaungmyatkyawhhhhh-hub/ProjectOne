--[[
	Parking (server)
	The luxury towers' garages at run time (owner, 2026-10-23: "make it say VIP parking on the
	entrance of the areas and u have to pay to park and in underground add some random low and mid
	tier cars that can't move on its own but add a feature that u can steal those random already
	there cars but after a while a new random car will replace that open space area car which got
	stolen").

	Parked cars: Config.Parking.ParkedPerGarage random Starter / Mid cars stand anchored in random
	basement bays (Garages' "ParkBay" markers). On foot, hold E on one ("Steal"): the client asks
	(StealCar), the parked car goes and you drive away in the same car from its bay, with a police
	star. It isn't yours to keep: it never goes in your garage. After RefillSeconds a new random car
	fills that bay.

	VIP bays ("VipBay" markers at each garage's entrance): leave your car in one (get out) and the
	fee comes off your cash once; with too little cash the car is towed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Parking = {}

local P = Config.Parking
local rng = Random.new()

type Bay = { cf: CFrame, car: Model? }

local bays: { Bay } = {}
local vipBays: { BasePart } = {}
local folder: Folder

-- the cars that can be parked: Starter / Mid tiers with an imported model in the game
local pool: { string } = {}

local function pickCar(): string?
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

local function park(bay: Bay)
	local id = pickCar()
	if not id then
		return
	end
	local model = CarBuilder.build(Cars.get(id), { interior = false, lights = false, anchored = true })
	model.Name = "Parked_" .. id
	model:SetAttribute("CarId", id)
	model:SetAttribute("Parked", true)
	local h = (model:GetAttribute("Height") :: number?) or 5
	model:PivotTo(bay.cf + Vector3.new(0, h / 2 + 0.3, 0))
	local root = model.PrimaryPart
	if root then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StealCar"
		prompt.ActionText = "Steal"
		prompt.ObjectText = Cars.get(id).Name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = P.StealHold
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = root
	end
	model.Parent = folder
	bay.car = model
end

function Parking.init(ctx: any, Police: any, Towers: any)
	local city = workspace:FindFirstChild("City")
	if not city then
		return
	end
	for _, spec in Cars.List do
		if table.find(P.Tiers, spec.Tier) and not spec.BaseId then
			table.insert(pool, spec.Id)
		end
	end
	folder = Instance.new("Folder")
	folder.Name = "ParkedCars"
	folder.Parent = workspace

	-- the markers, per garage
	local byGarage: { [Instance]: { CFrame } } = {}
	for _, d in city:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "ParkBay" then
			local g = d.Parent :: Instance
			byGarage[g] = byGarage[g] or {}
			table.insert(byGarage[g], d.CFrame)
		elseif d:IsA("BasePart") and d.Name == "VipBay" then
			table.insert(vipBays, d)
		end
	end
	for _, spots in byGarage do
		-- a random handful of each garage's bays
		for i = #spots, 2, -1 do
			local j = rng:NextInteger(1, i)
			spots[i], spots[j] = spots[j], spots[i]
		end
		for i = 1, math.min(P.ParkedPerGarage, #spots) do
			local bay: Bay = { cf = spots[i], car = nil }
			table.insert(bays, bay)
			park(bay)
		end
	end

	-- stealing one: the client asks once its hold on the prompt is done
	local steal: RemoteEvent = ctx.remote("RemoteEvent", "StealCar")
	steal.OnServerEvent:Connect(function(player: Player, model: any)
		if typeof(model) ~= "Instance" or model.Parent ~= folder then
			return
		end
		local character = player.Character
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp or (hrp.Position - (model :: Model):GetPivot().Position).Magnitude > 16 then
			return
		end
		local bay: Bay? = nil
		for _, b in bays do
			if b.car == model then
				bay = b
			end
		end
		local id = (model :: Model):GetAttribute("CarId")
		if not bay or type(id) ~= "string" then
			return
		end
		local spot = bay.cf
		bay.car = nil
		model:Destroy()
		ctx.spawnCar(player, id, { stolen = true, at = spot })
		Police.setWanted(player, math.max(Police.getWanted(player), P.StealStars), "car theft")
		Towers.send(player, { kind = "toast", text = "Stolen: " .. Cars.get(id).Name .. ". Lose the police!", color = "warning" })
		-- a new car in that bay later
		task.delay(rng:NextNumber(P.RefillSeconds[1], P.RefillSeconds[2]), function()
			local b = bay :: Bay
			if not b.car then
				park(b)
			end
		end)
	end)

	-- VIP bays: charged once when you leave your car in one; towed if you can't pay
	task.spawn(function()
		while true do
			task.wait(2)
			for _, player in Players:GetPlayers() do
				local car = ctx.getCar(player) :: Model?
				if not car then
					continue
				end
				if not car:GetAttribute("Parked") then
					car:SetAttribute("VipPaid", nil)
					continue
				end
				if car:GetAttribute("VipPaid") then
					continue
				end
				local pos = car:GetPivot().Position
				for _, bay in vipBays do
					local rel = bay.CFrame:PointToObjectSpace(pos)
					if math.abs(rel.X) < bay.Size.X / 2 + 1 and math.abs(rel.Z) < bay.Size.Z / 2 + 1 and math.abs(rel.Y) < 8 then
						local profile = PlayerData.get(player)
						if profile and profile.Cash >= P.VipFee then
							PlayerData.addCash(player, -P.VipFee)
							car:SetAttribute("VipPaid", true)
							Towers.send(player, { kind = "toast", text = "VIP parking: -$" .. P.VipFee, color = "accent" })
						else
							car:SetAttribute("VipPaid", true)
							Towers.send(player, { kind = "toast", text = "Not enough cash for VIP parking: your car is being towed", color = "danger" })
							task.delay(6, function()
								if car.Parent and car:GetAttribute("Parked") then
									ctx.despawn(player)
								end
							end)
						end
						break
					end
				end
			end
		end
	end)
end

return Parking
