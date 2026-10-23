--[[
	OnFoot (client)
	Y (or the action button) gets you out of your car when it's nearly stopped, and back in when
	you walk up to it. On foot you are your own Roblox avatar with the normal walking camera; the
	car stays parked where you left it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local OnFoot = {}
OnFoot.active = false

local EXIT_SPEED = 12 -- studs/s (a little under the server's limit)
local ENTER_RANGE = 14

local remotes: Folder
local busy = false

-- another module can offer a different action for a slow car at a spot (the hotel's valet bay):
-- it returns the pill's label and what Y does, or nil to leave GET OUT
OnFoot.driveAction = nil :: (() -> (string?, (() -> ())?))?
local driveActionFn: (() -> ())? = nil

local function myCar(): Model?
	local cars = workspace:FindFirstChild("PlayerCars")
	local car = if cars then cars:FindFirstChild(player.Name) else nil
	return if car and car:IsA("Model") then car else nil
end

local function hrp(): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

function OnFoot.getOut()
	if busy or not Driving.isDriving() then
		return
	end
	if Driving.getSpeed() > EXIT_SPEED then
		UI.toast("Slow down to get out", Config.Theme.Warning)
		return
	end
	busy = true
	local ok, result = pcall(function()
		return (remotes:WaitForChild("ExitCar") :: RemoteFunction):InvokeServer()
	end)
	busy = false
	if not (ok and result) then
		UI.toast("Can't get out here", Config.Theme.Warning)
		return
	end
	Driving.park()
	OnFoot.footMode()
end

-- the server has stood the avatar up: walking camera and the on-foot HUD (after the car is parked)
function OnFoot.footMode()
	OnFoot.active = true
	UI.setOnFoot(true)
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		camera.CameraSubject = humanoid :: Humanoid
	end
	camera.FieldOfView = 70
end

function OnFoot.getIn()
	if busy or not OnFoot.active then
		return
	end
	local car, root = myCar(), hrp()
	if not (car and root) or (car:GetPivot().Position - root.Position).Magnitude > ENTER_RANGE then
		return
	end
	busy = true
	local ok, result = pcall(function()
		return (remotes:WaitForChild("EnterCar") :: RemoteFunction):InvokeServer()
	end)
	busy = false
	if not (ok and result) then
		return
	end
	OnFoot.active = false
	UI.setOnFoot(false)
	Driving.attach(car)
	UI.setCameraLabel(Driving.cameraMode)
end

-- a new car from the garage puts you straight in it (the server removes the avatar)
function OnFoot.reset()
	OnFoot.active = false
	UI.setOnFoot(false)
end

function OnFoot.toggle()
	if Driving.isDriving() and driveActionFn then
		driveActionFn()
	elseif Driving.isDriving() then
		OnFoot.getOut()
	elseif OnFoot.active then
		OnFoot.getIn()
	end
end

function OnFoot.init()
	remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Y or input.KeyCode == Enum.KeyCode.DPadUp then
			OnFoot.toggle()
		end
	end)
	UI.onAction = OnFoot.toggle
	-- the action pill: "GET OUT" when slow enough, "GET IN" beside your car
	RunService.Heartbeat:Connect(function()
		driveActionFn = nil
		if Driving.isDriving() then
			local label: string?, fn: (() -> ())? = nil, nil
			if OnFoot.driveAction and Driving.getSpeed() <= EXIT_SPEED and not UI.isGarageOpen() then
				label, fn = OnFoot.driveAction()
			end
			if label and fn then
				driveActionFn = fn
				UI.setAction(label, "Y")
			elseif Driving.getSpeed() <= EXIT_SPEED and not UI.isGarageOpen() then
				UI.setAction("GET OUT", "Y")
			else
				UI.setAction(nil)
			end
		elseif OnFoot.active then
			local car, root = myCar(), hrp()
			if car and root and (car:GetPivot().Position - root.Position).Magnitude <= ENTER_RANGE then
				UI.setAction("GET IN", "Y")
			else
				UI.setAction(nil)
			end
		else
			UI.setAction(nil)
		end
	end)
end

return OnFoot
