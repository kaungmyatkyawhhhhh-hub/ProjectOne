--[[
	HotelClient
	The Legends Grand Hotel's valet (see server/Hotel.lua):
	  * stopped in the valet bay under the canopy, the action pill says VALET: Y hands the car over
	    and you step out at the doors
	  * the valet stand's "Get my car" only shows while the valet has your car; it brings the car
	    back to the bay and puts you in it (the normal drive-out, so the HUD and camera come back)
	The suites' income popups come through the towers' TowerFX messages (Penthouse.client.lua).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))

local player = Players.LocalPlayer
local Theme = Config.Theme

local HotelClient = {}

local busy = false

local function bayNear(car: Model): boolean
	local p = car:GetPivot().Position
	for _, bay in CollectionService:GetTagged("HotelValetBay") do
		if bay:IsA("BasePart") then
			local b = bay.Position
			if Vector3.new(p.X - b.X, 0, p.Z - b.Z).Magnitude <= Config.Hotel.ValetRange and math.abs(p.Y - b.Y) < 12 then
				return true
			end
		end
	end
	return false
end

local function handOver()
	if busy then
		return
	end
	local call = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("HotelCall") :: RemoteFunction?
	if not call then
		return
	end
	busy = true
	local ok, result = pcall(function()
		return call:InvokeServer("valet")
	end)
	busy = false
	if not (ok and type(result) == "table") then
		return
	end
	if not result.ok then
		if type(result.message) == "string" then
			UI.toast(result.message, Theme.Warning)
		end
		return
	end
	Driving.park()
	OnFoot.footMode()
	UI.toast((if type(result.message) == "string" then result.message else "The valet is parking your car") .. ". Get it back at the valet stand", Theme.Accent)
end

-- the stand's prompt: only while the valet is holding your car
local function word(p: Instance)
	if not p:IsA("ProximityPrompt") then
		return
	end
	local id = player:GetAttribute("ValetCar")
	p.Enabled = type(id) == "string"
	local spec = if type(id) == "string" then Cars.ById[id] else nil
	p.ObjectText = if spec then "Valet  ·  " .. spec.Name else "Valet"
end

local function rewordAll()
	for _, p in CollectionService:GetTagged("HotelValetStand") do
		word(p)
	end
end

function HotelClient.init(requestDrive: (string) -> ())
	OnFoot.driveAction = function(): (string?, (() -> ())?)
		local car = Driving.getModel()
		if car and bayNear(car) then
			return "VALET", handOver
		end
		return nil, nil
	end
	CollectionService:GetInstanceAddedSignal("HotelValetStand"):Connect(word)
	player:GetAttributeChangedSignal("ValetCar"):Connect(rewordAll)
	task.defer(rewordAll)
	task.spawn(function()
		local fx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HotelFX", 120) :: RemoteEvent?
		if not fx then
			return
		end
		fx.OnClientEvent:Connect(function(info)
			if type(info) == "table" and info.kind == "retrieve" and type(info.carId) == "string" then
				UI.toast("Your car is coming round", Theme.Accent)
				requestDrive(info.carId)
			end
		end)
	end)
end

return HotelClient
