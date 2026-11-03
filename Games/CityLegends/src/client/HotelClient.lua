--[[
	HotelClient
	The Legends Grand Hotel's valet (see server/Hotel.lua):
	  * stopped in the valet bay under the canopy, the action pill says VALET: Y hands the car over
	    and you step out at the doors
	  * the valet stand's "Get my car" only shows while the valet has your car; it brings the car
	    back to the bay and puts you in it (the normal drive-out, so the HUD and camera come back)
	  * the suite (one suite you upgrade, 2026-11-03): the gallery's plinths and the lifts are
	    worded for this player's tier (buy, upgrade, "your suite", locked; the lifts say they're
	    for suite owners until you own one)
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

-- the tier this player owns (0: none), from the penthouses the server publishes
local function myTier(): number
	local raw = player:GetAttribute("Penthouses")
	local owned = {}
	if type(raw) == "string" then
		for id in raw:gmatch("[^,]+") do
			owned[id] = true
		end
	end
	local best = 0
	for k, s in Config.Hotel.Suites do
		if owned[s.id] then
			best = k
		end
	end
	return best
end

local function titleCase(s: string): string
	return (string.gsub(string.lower(s), "(%a)([%w']*)", function(a, b)
		return string.upper(a) .. b
	end))
end

local function wordSuite(p: Instance)
	if not p:IsA("ProximityPrompt") then
		return
	end
	local mine = myTier()
	if p:HasTag("HotelSuiteLift") then
		p.ObjectText = if mine > 0 then "Elevator  ·  " .. titleCase(Config.Hotel.Suites[mine].name) else "Elevator (suite owners only)"
		return
	end
	local k = p:GetAttribute("Tier")
	if type(k) ~= "number" then
		return
	end
	if p:GetAttribute("BaseObject") == nil then
		p:SetAttribute("BaseAction", p.ActionText)
		p:SetAttribute("BaseObject", p.ObjectText)
	end
	p.Enabled = k >= mine -- (tiers below yours are gone)
	if k < mine then
		return
	elseif k == mine then
		p.ActionText = "Your suite"
		p.ObjectText = titleCase(Config.Hotel.Suites[k].name)
		p.HoldDuration = 0
	elseif k == mine + 1 then
		p.ActionText = p:GetAttribute("BaseAction") :: string
		p.ObjectText = p:GetAttribute("BaseObject") :: string
		p.HoldDuration = 1.5
	else
		p.ActionText = "Locked"
		p.ObjectText = "Upgrade to the " .. titleCase(Config.Hotel.Suites[mine + 1].name) .. " first"
		p.HoldDuration = 0
	end
end

local function wordSuites()
	for _, tag in { "HotelTier", "HotelSuiteLift" } do
		for _, p in CollectionService:GetTagged(tag) do
			wordSuite(p)
		end
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
	for _, tag in { "HotelTier", "HotelSuiteLift" } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(wordSuite)
	end
	player:GetAttributeChangedSignal("Penthouses"):Connect(wordSuites)
	task.defer(wordSuites)
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
