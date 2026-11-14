--[[
	CarDoors (client; owner, 2026-11-08, `Prompts/Scissor doors on the SVJ and SVJ 63 (cut properly).md`): turns the
	scissor doors of every car that has them. CarSkin puts each door on a Motor6D at its hinge (SkinDoorL / SkinDoorR on
	the car's root, attribute Open = degrees); the server says which door is open (car attributes DoorOpenL / DoorOpenR,
	server/Doors.lua), so every player sees the same. Here they swing up and down in Config.DoorFeel.Seconds with a soft
	ease and a door sound.
	Shift + F (Driving / OnFoot call onDoorKey) and the phone's DOORS button: both doors up or down while parked.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local CarDoors = {}

local player = Players.LocalPlayer
local FEEL = Config.DoorFeel
local SIDES = { "L", "R", "L2", "R2" } -- (2026-11-14: L2 / R2 = the rear doors of four-door cars)

type State = { t: number, want: number?, sound: Sound? }
local states: { [Motor6D]: State } = {}

local function myCar(): Model?
	local cars = workspace:FindFirstChild("PlayerCars")
	local car = if cars then cars:FindFirstChild(player.Name) else nil
	return if car and car:IsA("Model") then car else nil
end

-- does this car (as skinned in this game) have doors?
function CarDoors.has(car: Model?): boolean
	local root = if car then car.PrimaryPart else nil
	return root ~= nil and root:FindFirstChild("SkinDoorL") ~= nil
end

local function play(m: Motor6D, st: State, open: boolean)
	local holder = m.Part1
	if not holder then
		return
	end
	local s = st.sound
	if not s then
		local sound = Instance.new("Sound")
		sound.Name = "DoorSound"
		sound.Volume = FEEL.Volume
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = 70
		sound.Parent = holder
		st.sound = sound
		s = sound
	end
	local snd = s :: Sound
	snd.SoundId = if open then FEEL.OpenSound else FEEL.CloseSound
	snd.TimePosition = 0
	snd:Play()
end

local function step(dt: number)
	local cars = workspace:FindFirstChild("PlayerCars")
	if not cars then
		return
	end
	for _, car in cars:GetChildren() do
		local root = if car:IsA("Model") then car.PrimaryPart else nil
		if not root then
			continue
		end
		for _, side in SIDES do
			local m = root:FindFirstChild("SkinDoor" .. side)
			if not (m and m:IsA("Motor6D")) then
				continue
			end
			local st = states[m]
			if not st then
				st = { t = 0 }
				states[m] = st
			end
			local want = if car:GetAttribute("DoorOpen" .. side) == true then 1 else 0
			if want ~= st.want then
				if st.want ~= nil then
					play(m, st, want == 1)
				end
				st.want = want
			end
			if st.t ~= want then
				st.t = math.clamp(st.t + (if want == 1 then 1 else -1) * dt / FEEL.Seconds, 0, 1)
				local e = st.t * st.t * (3 - 2 * st.t) -- (a soft start and a soft stop)
				local open = (m:GetAttribute("Open") :: number?) or 70
				m.Transform = CFrame.Angles(math.rad(open * e), 0, 0)
			end
		end
	end
end

local remote: RemoteEvent? = nil

-- both doors up or down: from the seat while stopped, or standing next to your car
function CarDoors.toggle()
	local car = myCar()
	if not (car and CarDoors.has(car)) then
		return
	end
	if Driving.isDriving() then
		if Driving.getSpeed() > FEEL.MaxSpeed then
			UI.toast("Stop the car to open the doors", Config.Theme.Warning)
			return
		end
	else
		local character = player.Character
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp or (hrp.Position - car:GetPivot().Position).Magnitude > FEEL.Reach then
			return
		end
	end
	if remote then
		remote:FireServer("toggle")
	end
end

function CarDoors.init()
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local r = if remotes then remotes:WaitForChild("CarDoors", 30) else nil
		if r and r:IsA("RemoteEvent") then
			remote = r
		end
	end)
	Driving.onDoorKey = CarDoors.toggle
	UI.onDoors = CarDoors.toggle
	RunService.RenderStepped:Connect(step)
	-- the phone's DOORS button: in a car that has them, while stopped
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		for m in states do
			if not m.Parent then
				states[m] = nil
			end
		end
		if UI.showDoorsButton then
			local car = myCar()
			UI.showDoorsButton(Driving.isDriving() and car ~= nil and CarDoors.has(car) and Driving.getSpeed() <= FEEL.MaxSpeed)
		end
	end)
end

return CarDoors
