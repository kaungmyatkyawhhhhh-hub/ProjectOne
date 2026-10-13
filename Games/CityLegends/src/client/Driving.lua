--[[
	Driving (client)
	The local player owns the physics of their car. Every physics step we:
	  * read keyboard / gamepad / touch input
	  * integrate an arcade-realistic model: engine curve, brakes, drag, speed
	    sensitive steering with a lateral-g cap, tyre grip + handbrake drifts
	  * push the result into the LinearVelocity / AlignOrientation constraints
	  * detect crashes (physics stopped us) and "cut ups" (passing traffic close)
	  * pop small blue/orange exhaust flames on upshifts and lift-off crackles
	Every render frame we:
	  * spin + steer the wheels, turn the steering wheel, and solve 2-bone IK so
	    the driver's arms follow their hands on the wheel
	  * drive the camera (interior cockpit or chase) with speed-based FOV,
	    shake and blur
	  * update the HUD + the live gauge cluster on the dashboard
	Car controls (keyboard): J ignition, F start / stop the engine, Q / E shift down / up (the
	gearbox turns manual on the first shift, or from Settings), Left Shift clutch, P handbrake,
	T traction control, L lights, Z / X / C left blinker / hazards / right blinker, V camera.
	Touch and gamepad players start with the engine running and an automatic gearbox.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local avatarDesc: HumanoidDescription? = nil -- for the driver's arms

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))

local Traffic = require(script.Parent:WaitForChild("Traffic"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local DashGauges = require(script.Parent:WaitForChild("DashGauges"))

local camera = workspace.CurrentCamera

local Driving = {}
Driving.cameraMode = "Chase" -- "Chase" | "Interior"
Driving.inputEnabled = true
Driving.gearbox = "Auto" -- "Auto" | "Manual" (Settings; Q / E switch to manual too)
Driving.units = "mph" -- "mph" | "kmh" (Settings): the HUD and every cluster
Driving.onGearboxChanged = nil :: ((string) -> ())?
local GEARS = 7

type LocalArm = {
	upper: BasePart, -- the whole arm when fore is nil (R6)
	fore: BasePart?,
	glove: BasePart?,
	shoulder: Vector3,
	grip: Vector3,
	pole: Vector3,
	upperLen: number,
	foreLen: number,
	handLen: number,
	rot: CFrame, -- part space -> bone space (avatar limbs run along Y, our bones along Z)
}
type ArmRig = { upper: Motor6D, fore: Motor6D, shoulder: Vector3, grip: Vector3, pole: Vector3 }

type State = {
	model: Model,
	root: BasePart,
	spec: Cars.CarSpec,
	lv: LinearVelocity,
	ao: AlignOrientation,
	topSpeed: number,
	accel: number,
	wheelbase: number,
	halfHeight: number,
	width: number,
	yaw: number,
	vel: Vector3,
	steer: number,
	wheelSpin: number,
	wheels: { Motor6D },
	steerMotor: Motor6D?,
	steerMount: CFrame?,
	steerMaxRot: number,
	arms: { ArmRig },
	upperLen: number,
	foreLen: number,
	eye: Vector3,
	lastCommand: Vector3,
	crashCooldown: number,
	lastCrash: number,
	passTrack: { [any]: number },
	lastCutTime: number,
	lastCutSide: number,
	grounded: boolean,
	connections: { RBXScriptConnection },
	hidden: { BasePart },
	glass: { BasePart },
	gaugeSpeed: TextLabel?,
	gaugeGear: TextLabel?,
	gaugeBar: Frame?,
	dashUpdate: ((number, string, number) -> ())?,
	-- imported cars: their steering wheel and our arms, posed every frame on this client
	localSteer: { { part: BasePart, offset: CFrame } },
	localArms: { LocalArm },
	-- the model's own gauges: needle parts and on-screen needles (0..1 sweeps 240 degrees)
	partNeedles: { { part: BasePart, kind: string, pivot: CFrame, offset: CFrame } },
	guiNeedles: { { gui: GuiObject, kind: string, base: number } },
	guiTexts: { { label: TextLabel, kind: string } }, -- on-screen "Speed" / "RPM" / "Gear" read-outs
	speedShown: number,
	smoke: { { emitter: ParticleEmitter, rear: boolean } },
	-- body lean (radians): roll in turns, pitch on braking / accelerating
	roll: number,
	pitch: number,
	rpmShown: number,
	camPos: Vector3,
	camLook: Vector3,
	fov: number,
	shake: number,
	gear: string,
	rpm: number,
	cabinLight: PointLight?,
	engine: Audio.Engine,
	throttle: number,
	slip: number,
	flames: { ParticleEmitter },
	flameParts: { Instance },
	flameLight: PointLight?,
	flameGlow: number,
	throttleIn: number,
	pops: number,
	popTimer: number,
	-- car controls
	ignition: boolean,
	engineOn: boolean,
	cranking: number, -- seconds left of the starter turning the engine over
	manual: boolean,
	mgear: number, -- manual gear: -1 reverse, 0 neutral, 1..GEARS
	clutch: boolean,
	freeRpm: number, -- revs while the clutch is in or in neutral
	launch: number, -- seconds left of a clutch-drop launch
	parkBrake: boolean,
	tc: boolean,
	lightsOn: boolean,
	blinker: string, -- "" | "L" | "R" | "H"
	blinkT: number,
	blinkLights: { L: { PointLight }, R: { PointLight } },
	dashPanel: BasePart?,
}

local state: State? = nil
local remotes: Folder? = nil
local blur: BlurEffect? = nil

local function remote(name: string): any
	local r = remotes or ReplicatedStorage:WaitForChild("Remotes")
	remotes = r
	return (r :: Folder):WaitForChild(name)
end

---------------------------------------------------------------------
-- Input
---------------------------------------------------------------------
local function readInput(): (number, number, number, boolean, boolean)
	if not Driving.inputEnabled or UI.isGarageOpen() then
		return 0, 0, 0, false, false
	end
	local throttle, brake, steer = 0, 0, 0
	local handbrake, clutch = false, false
	if UserInputService:GetFocusedTextBox() == nil then
		clutch = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			throttle = 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
			brake = 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			steer -= 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			steer += 1
		end
		handbrake = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	end
	-- gamepad
	if UserInputService.GamepadEnabled then
		for _, input in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
			if input.KeyCode == Enum.KeyCode.ButtonR2 then
				throttle = math.max(throttle, input.Position.Z)
			elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
				brake = math.max(brake, input.Position.Z)
			elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
				if math.abs(input.Position.X) > 0.12 then
					steer += input.Position.X
				end
			elseif input.KeyCode == Enum.KeyCode.ButtonX then
				handbrake = handbrake or input.UserInputState == Enum.UserInputState.Begin
			end
		end
	end
	-- touch
	throttle = math.max(throttle, UI.touch.throttle)
	brake = math.max(brake, UI.touch.brake)
	steer += UI.touch.steer
	handbrake = handbrake or UI.touch.handbrake
	return throttle, brake, math.clamp(steer, -1, 1), handbrake, clutch
end

---------------------------------------------------------------------
-- Attach / detach
---------------------------------------------------------------------
local function yawFromLook(look: Vector3): number
	return math.atan2(-look.X, -look.Z)
end

local function forwardFromYaw(yaw: number): Vector3
	return Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
end

local function buildGauges(model: Model): (TextLabel?, TextLabel?, Frame?)
	local cluster = model:FindFirstChild("Cluster", true)
	local gui = cluster and cluster:FindFirstChild("Gauges")
	if not gui then
		return nil, nil, nil
	end
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(6, 8, 12)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local speed = Instance.new("TextLabel")
	speed.BackgroundTransparency = 1
	speed.Size = UDim2.new(0.5, 0, 0.75, 0)
	speed.Position = UDim2.fromScale(0.25, 0.02)
	speed.Font = Enum.Font.GothamBlack
	speed.TextScaled = true
	speed.TextColor3 = Color3.new(1, 1, 1)
	speed.Text = "0"
	speed.Parent = bg
	local gear = Instance.new("TextLabel")
	gear.BackgroundTransparency = 1
	gear.Size = UDim2.new(0.2, 0, 0.6, 0)
	gear.Position = UDim2.fromScale(0.78, 0.15)
	gear.Font = Enum.Font.GothamBlack
	gear.TextScaled = true
	gear.TextColor3 = Config.Theme.Accent
	gear.Text = "N"
	gear.Parent = bg
	local unit = Instance.new("TextLabel")
	unit.BackgroundTransparency = 1
	unit.Size = UDim2.new(0.2, 0, 0.3, 0)
	unit.Position = UDim2.fromScale(0.03, 0.35)
	unit.Font = Enum.Font.GothamBold
	unit.TextScaled = true
	unit.TextColor3 = Config.Theme.SubText
	unit.Text = if Driving.units == "kmh" then "KM/H" else "MPH"
	unit.Parent = bg
	local barBack = Instance.new("Frame")
	barBack.Position = UDim2.fromScale(0.05, 0.84)
	barBack.Size = UDim2.fromScale(0.9, 0.08)
	barBack.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
	barBack.BorderSizePixel = 0
	barBack.Parent = bg
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = Config.Theme.Accent
	bar.BorderSizePixel = 0
	bar.Parent = barBack
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Config.Theme.Accent, Config.Theme.Accent2)
	grad.Parent = bar
	return speed, gear, bar
end

---------------------------------------------------------------------
-- Exhaust flames (local player's car only)
---------------------------------------------------------------------
-- Exhaust tip positions in root space. A skinned car shows CarMesh's pipes,
-- so mirror its placement; otherwise use the (visible) part-built pipes.
local function exhaustTips(model: Model, root: BasePart): { Vector3 }
	local tips: { Vector3 } = {}
	if model:GetAttribute("Skinned") then
		-- CarSkin stores the mesh's pipe tips (root space) as Exhaust1..n
		local i = 1
		while true do
			local p = model:GetAttribute("Exhaust" .. i)
			if typeof(p) ~= "Vector3" then
				break
			end
			table.insert(tips, p)
			i += 1
		end
		if #tips > 0 then
			return tips
		end
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Exhaust" then
			-- cylinder axis points backwards; its length is Size.X
			table.insert(tips, root.CFrame:PointToObjectSpace(d.Position) + Vector3.new(0, 0, d.Size.X / 2))
		end
	end
	return tips
end

local function buildFlames(model: Model, root: BasePart, spec: Cars.CarSpec): ({ ParticleEmitter }, { Instance }, PointLight?)
	local emitters: { ParticleEmitter } = {}
	local parts: { Instance } = {}
	local tips = exhaustTips(model, root)
	if #tips == 0 then
		return emitters, parts, nil
	end
	local sum = Vector3.zero
	for _, tip in tips do
		sum += tip
		local att = Instance.new("Attachment")
		att.Name = "ExhaustFlame"
		att.Position = tip
		att.Parent = root
		table.insert(parts, att)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.LockedToPart = true -- stays on the pipe at any speed
		e.EmissionDirection = Enum.NormalId.Back
		e.Lifetime = NumberRange.new(0.05, 0.12)
		e.Speed = NumberRange.new(8, 15)
		e.SpreadAngle = Vector2.new(8, 8)
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.32),
			NumberSequenceKeypoint.new(0.5, 0.26),
			NumberSequenceKeypoint.new(1, 0.04),
		})
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 140, 255)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(120, 130, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 40)),
		})
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Brightness = 2
		e.ZOffset = 0.3
		e.Parent = att
		table.insert(emitters, e)
	end
	local glowAtt = Instance.new("Attachment")
	glowAtt.Name = "ExhaustGlow"
	glowAtt.Position = sum / #tips + Vector3.new(0, 0, 0.6)
	glowAtt.Parent = root
	table.insert(parts, glowAtt)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(130, 160, 255)
	light.Range = 9
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	light.Parent = glowAtt
	return emitters, parts, light
end

local function exhaustPop(s: State, strength: number)
	for _, e in s.flames do
		e:Emit(math.max(1, math.floor((4 + math.random() * 4) * strength)))
	end
	s.flameGlow = math.max(s.flameGlow, 4 * strength)
end

function Driving.detach()
	local s = state
	if not s then
		return
	end
	for _, c in s.connections do
		c:Disconnect()
	end
	for _, f in s.flameParts do
		f:Destroy()
	end
	s.engine:destroy()
	if s.cabinLight then
		s.cabinLight:Destroy()
	end
	state = nil
	if blur then
		blur.Size = 0
	end
end

function Driving.isDriving(): boolean
	return state ~= nil
end

function Driving.getRoot(): BasePart?
	return if state then state.root else nil
end

function Driving.toggleCamera()
	Driving.cameraMode = if Driving.cameraMode == "Chase" then "Interior" else "Chase"
	UI.setCameraLabel(Driving.cameraMode)
	local s = state
	if s then
		local interior = Driving.cameraMode == "Interior"
		for _, p in s.hidden do
			p.LocalTransparencyModifier = if interior then 1 else 0
		end
		for _, g in s.glass do
			g.LocalTransparencyModifier = if interior then 0.65 else 0
		end
		if s.cabinLight then
			s.cabinLight.Enabled = interior
		end
	end
end

function Driving.reset()
	local s = state
	if not s then
		return
	end
	local cf = CityLayout.nearestLaneCFrame(s.root.Position)
	s.root.AssemblyLinearVelocity = Vector3.zero
	s.root.AssemblyAngularVelocity = Vector3.zero
	s.root.CFrame = cf + Vector3.new(0, s.halfHeight + 0.4, 0)
	s.yaw = yawFromLook(cf.LookVector)
	s.vel = Vector3.zero
	s.lastCommand = Vector3.zero
end

-- the live cluster on the dashboard: off with the ignition, and built again (needle sweep and all)
-- when it comes on or the speed units change
local function setClusterPower(s: State, on: boolean)
	local panel = s.dashPanel
	if not panel then
		return
	end
	local old = panel:FindFirstChild("Gauges")
	if old then
		old:Destroy()
	end
	s.dashUpdate = nil
	if on then
		DashGauges.setUnits(Driving.units)
		local ok, upd = pcall(DashGauges.build, panel)
		s.dashUpdate = if ok then upd else nil
	end
end

local function indicatorState(s: State): { [string]: any }
	return {
		ignition = s.ignition,
		engine = s.engineOn,
		manual = s.manual,
		park = s.parkBrake,
		tc = s.tc,
		lights = s.lightsOn,
		blinker = s.blinker,
	}
end

local function setLights(s: State, on: boolean)
	s.lightsOn = on
	for _, d in s.model:GetDescendants() do
		if d:IsA("SpotLight") or (d:IsA("SurfaceLight") and d.Parent and d.Parent.Name:lower():find("head")) then
			d.Enabled = on
		end
	end
end

-- J / F / Q / E / P / T / L / Z / X / C
local function carKey(s: State, key: Enum.KeyCode)
	if key == Enum.KeyCode.J then
		s.ignition = not s.ignition
		if not s.ignition and s.engineOn then
			s.engineOn = false
			s.engine:setRunning(false)
		end
		s.cranking = 0
		setClusterPower(s, s.ignition)
		UI.toast(if s.ignition then "Ignition on" else "Ignition off")
	elseif key == Enum.KeyCode.F then
		if s.engineOn then
			s.engineOn = false
			s.engine:setRunning(false)
			UI.toast("Engine off")
		elseif not s.ignition then
			UI.toast("Turn the ignition on first (J)", Config.Theme.Warning)
		elseif s.cranking <= 0 then
			s.cranking = 0.8
			Audio.engineStart()
		end
	elseif key == Enum.KeyCode.E or key == Enum.KeyCode.Q then
		if not s.manual then
			s.manual = true
			s.mgear = tonumber(s.gear) or (if s.gear == "R" then -1 else 0)
			Driving.gearbox = "Manual"
			if Driving.onGearboxChanged then
				Driving.onGearboxChanged("Manual")
			end
		end
		local fwdSpeed = s.vel:Dot(forwardFromYaw(s.yaw))
		local before = s.mgear
		if key == Enum.KeyCode.E then
			s.mgear = math.min(s.mgear + 1, GEARS)
		else
			-- into reverse only when (nearly) stopped
			s.mgear = math.max(s.mgear - 1, if fwdSpeed > 4 then 0 else -1)
		end
		if s.mgear ~= before and s.mgear <= 0 then
			UI.toast(if s.mgear < 0 then "Reverse" else "Neutral")
		end
	elseif key == Enum.KeyCode.P then
		s.parkBrake = not s.parkBrake
		UI.toast(if s.parkBrake then "Handbrake on" else "Handbrake off")
	elseif key == Enum.KeyCode.T then
		s.tc = not s.tc
		UI.toast(if s.tc then "Traction control on" else "Traction control off", if s.tc then nil else Config.Theme.Warning)
	elseif key == Enum.KeyCode.L then
		setLights(s, not s.lightsOn)
		UI.toast(if s.lightsOn then "Lights on" else "Lights off")
	elseif key == Enum.KeyCode.Z or key == Enum.KeyCode.X or key == Enum.KeyCode.C then
		local want = if key == Enum.KeyCode.Z then "L" elseif key == Enum.KeyCode.C then "R" else "H"
		s.blinker = if s.blinker == want then "" else want
		s.blinkT = 0
	else
		return
	end
	UI.setIndicators(indicatorState(s))
end

function Driving.attach(model: Model)
	Driving.detach()
	local root = model.PrimaryPart :: BasePart
	local spec = Cars.get(model:GetAttribute("CarId") :: string)
	local dims = CarBuilder.getDims(spec.Class, spec.Id)
	local lv = root:WaitForChild("Drive") :: LinearVelocity
	local ao = root:WaitForChild("Steer") :: AlignOrientation

	local wheels = {}
	local arms: { ArmRig } = {}
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
		end
	end
	local steerMotor = root:FindFirstChild("SteerMotor") :: Motor6D?
	for _, side in { "L", "R" } do
		local upper = root:FindFirstChild("UpperArm" .. side) :: Motor6D?
		local fore = root:FindFirstChild("ForeArm" .. side) :: Motor6D?
		local shoulder = model:GetAttribute("Shoulder" .. side) :: Vector3?
		local grip = model:GetAttribute("Grip" .. side) :: Vector3?
		if upper and fore and shoulder and grip then
			table.insert(arms, {
				upper = upper,
				fore = fore,
				shoulder = shoulder,
				grip = grip,
				pole = Vector3.new(if side == "L" then -0.8 else 0.8, -1, 0.2),
			})
		end
	end

	local hidden = {}
	local glass = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if model:GetAttribute("OwnInterior") then
				if d.Name == "Underglow" then
					table.insert(hidden, d) -- shows through the floor in first person
				end
				continue -- imported model: our cabin and driver are hidden for good
			elseif d.Name == "DriverHead" or d.Name == "DriverHair" or d.Name == "DriverNeck" then
				table.insert(hidden, d)
			elseif d.Name == "SkinGlass" or (not model:GetAttribute("Skinned") and (d.Name == "Windshield" or d.Name == "SideGlassL" or d.Name == "SideGlassR")) then
				table.insert(glass, d)
			end
		end
	end

	local cabinLight = Instance.new("PointLight")
	cabinLight.Color = Color3.fromRGB(255, 244, 228) -- warm dome light so the cabin is readable at night
	cabinLight.Brightness = 1.6
	cabinLight.Range = 9
	cabinLight.Shadows = false
	cabinLight.Enabled = false
	cabinLight.Parent = root

	local gSpeed, gGear, gBar = buildGauges(model)
	local localSteer = {}
	local localArms = {}
	local partNeedles = {}
	local guiNeedles = {}
	local guiTexts = {}
	-- extras for imported cars; a fault here must never stop the car from driving
	local okExtras, errExtras = pcall(function()
		-- imported cars: pose their steering wheel and our arms ourselves (anchored, local only)
		for _, d in model:GetDescendants() do
			local off = d:GetAttribute("SteerOffset")
			if d:IsA("BasePart") and typeof(off) == "CFrame" then
				for _, w in d:GetChildren() do
					if w:IsA("Weld") or w:IsA("WeldConstraint") then
						w:Destroy()
					end
				end
				d.Anchored = true
				table.insert(localSteer, { part = d, offset = off })
			end
		end
		-- the model's own gauges (own pcall: a fault here must not cost the driver's hands)
		local okG, errG = pcall(function()
			for _, d in model:GetDescendants() do
				local kind = d:GetAttribute("GaugeKind")
				if d:IsA("BasePart") and type(kind) == "string" then
					for _, w in d:GetChildren() do
						if w:IsA("Weld") or w:IsA("WeldConstraint") then
							w:Destroy()
						end
					end
					d.Anchored = true
					table.insert(partNeedles, { part = d, kind = kind, pivot = d:GetAttribute("GaugePivot") :: CFrame, offset = d:GetAttribute("GaugeOffset") :: CFrame })
				elseif d:IsA("TextLabel") and model:GetAttribute("OwnInterior") and (d.Name == "Speed" or d.Name == "RPM" or d.Name == "Gear") then
					table.insert(guiTexts, { label = d, kind = d.Name })
				elseif d:IsA("GuiObject") and d.Name == "Needle" and model:GetAttribute("OwnInterior") then
					-- which dial: the nearest named ancestor (the screen part keeps its model name as SrcName)
					local gk: string? = nil
					local a: Instance? = d.Parent
					while a and a ~= model do
						local n = ((a:GetAttribute("SrcName") :: string?) or a.Name):lower()
						if n == "spdn" or n == "tacn" then
							gk = nil
							break
						end
						if n:find("speed") or n:find("spd") then
							gk = "speed"
							break
						elseif n:find("tach") or n:find("tac") or n:find("rpm") then
							gk = "rpm"
							break
						end
						a = a.Parent
					end
					if gk then
						table.insert(guiNeedles, { gui = d, kind = gk, base = d.Rotation })
						-- the car's own start-up script used to switch these screens on
						local sg = d:FindFirstAncestorWhichIsA("SurfaceGui")
						if sg and not model:GetAttribute("OwnCluster") then
							sg.Enabled = true
						end
					end
				end
			end
		end)
		if not okG then
			warn("[CityLegends] gauge needles failed:", errG)
		end
		if model:GetAttribute("ArmsFitted") then
			local mount = model:GetAttribute("SteerMount") :: CFrame
			local sides = {}
			for _, side in { "L", "R" } do
				local shoulder = model:GetAttribute("Shoulder" .. side) :: Vector3
				local grip = model:GetAttribute("Grip" .. side) :: Vector3
				table.insert(sides, {
					side = side,
					shoulder = shoulder,
					grip = grip,
					reach = (shoulder - (mount * CFrame.new(grip)).Position).Magnitude,
					pole = Vector3.new(if side == "L" then -0.8 else 0.8, -1, 0.2),
				})
			end
			-- the player's own avatar as R6 (clothes and skin): only its two arms are used, each one
			-- straight from shoulder to hand, 30% of R6 thickness, posed every frame
			task.spawn(function()
				-- the avatar look is fetched once per session; a slow or failed fetch is retried
				local ok, rig = false, nil :: any
				for attempt = 1, 3 do
					ok, rig = pcall(function()
						if not avatarDesc then
							avatarDesc = Players:GetHumanoidDescriptionFromUserId(player.UserId)
						end
						return Players:CreateHumanoidModelFromDescription(avatarDesc :: HumanoidDescription, Enum.HumanoidRigType.R6)
					end)
					if ok then
						break
					end
					task.wait(attempt)
				end
				if not ok or not rig or not rig:FindFirstChild("Left Arm") or not (state and state.model == model) then
					if not ok then
						warn("[CityLegends] driver arms unavailable:", rig)
					end
					if ok and rig then
						rig:Destroy()
					end
					return
				end
				for _, d in rig:GetDescendants() do
					if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Accessory") then
						d:Destroy()
					end
				end
				local hum = rig:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					hum.PlatformStand = true
				end
				local keep = { ["Left Arm"] = true, ["Right Arm"] = true }
				for _, d in rig:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanQuery = false
						d.CanTouch = false
						d.CastShadow = false
						if not keep[d.Name] then
							-- the rest of the body: invisible and far away. The Humanoid forces torso and
							-- head to be solid, and an invisible wall near the car throws it about
							d.Transparency = 1
							d.CFrame = CFrame.new(0, 20000, 0)
						end
					elseif d:IsA("Decal") then
						d.Transparency = 1
					end
				end
				-- kept out of the car model (and out of physics and raycasts): only this client sees it
				rig.Parent = workspace.CurrentCamera
				local cur = state
				if not (cur and cur.model == model) then
					rig:Destroy()
					return
				end
				model.Destroying:Connect(function()
					rig:Destroy()
				end)
				table.insert(cur.connections, model.AncestryChanged:Connect(function()
					if not model:IsDescendantOf(workspace) then
						rig:Destroy()
					end
				end))
				for _, sd in sides do
					local arm = rig:FindFirstChild(if sd.side == "L" then "Left Arm" else "Right Arm") :: BasePart
					arm.Size = Vector3.new(0.3, sd.reach, 0.3) -- an R6 arm is 1 stud thick: 70% thinner
					table.insert(cur.localArms, {
						upper = arm,
						shoulder = sd.shoulder,
						grip = sd.grip,
						pole = sd.pole,
						upperLen = sd.reach,
						foreLen = 0,
						handLen = 0,
						rot = CFrame.Angles(math.pi / 2, 0, 0),
					})
				end
			end)
		end
	end)
	if not okExtras then
		warn("[CityLegends] cabin extras failed:", errExtras)
	end
	-- imported cars: the live cluster behind their own wheel
	local dashPanel = model:FindFirstChild("DashCluster", true)
	local dashUpdate: ((number, string, number) -> ())? = nil
	local style = if dashPanel then dashPanel:GetAttribute("Style") else nil
	local mountAttr = model:GetAttribute("SteerMount")
	local radiusAttr = model:GetAttribute("SteerRadius")
	local eyeAttr = model:GetAttribute("Eye")
	-- panel size per design, in wheel radii (wide clusters show partly through the rim, like real)
	local CLUSTER_SIZE = {
		Aventador = { 0.82, 0.82, 0.8, -0.06 }, -- just the round dial, over the model's own
		Ferrari = { 1.6, 0.6 },
		Ferrari599 = { 1.7, 0.6 },
		BMWLive = { 1.8, 0.62, 0.85 },
		BMWClassic = { 1.6, 0.6, 0.85 },
		BMWClassicGrey = { 1.6, 0.6, 0.85 },
		AMG = { 1.7, 0.62 },
		SupraTRD = { 1.9, 0.62 },
		Toyota = { 1.7, 0.62, 1.0 },
		AMGBiturbo = { 1.7, 0.62 },
		G63 = { 1.8, 0.62 },
		W212 = { 2.1, 0.62 },
		W213 = { 2.0, 0.72 },
		Gallardo = { 1.8, 0.66 },
		EV6 = { 1.7, 0.62, 0.95 },
		Aston = { 1.8, 0.62 },
		AMGSls = { 1.7, 0.62 },
		Urus = { 2.0, 0.72 },
		Murcielago = { 1.9, 0.66 },
		C6 = { 1.9, 0.66 },
		C7 = { 2.0, 0.66 },
	}
	local sizeFor = if type(style) == "string" then CLUSTER_SIZE[style] else nil
	if dashPanel and dashPanel:IsA("BasePart") and sizeFor
		and typeof(mountAttr) == "CFrame" and type(radiusAttr) == "number" and typeof(eyeAttr) == "Vector3" then
		-- sit where the car's own cluster is: seen through the top half of the wheel, just behind
		-- the rim, facing the driver's eye (the same eye the first-person camera uses)
		local r = radiusAttr
		-- third number: how high through the wheel it sits (in radii; default 0.6); fourth: a fine
		-- up/down nudge in studs
		local target = mountAttr.Position + mountAttr.UpVector * r * (sizeFor[3] or 0.6)
		local dir = (target - eyeAttr).Unit
		local pos = target + dir * 0.3
		local src = (ReplicatedStorage:FindFirstChild("CarModels", true) :: Instance):FindFirstChild(spec.Id, true)
		-- per-car line-up over the car's own cluster: { up (studs), forward (studs), size (x) };
		-- ClusterUp / ClusterForward / ClusterSize attributes on the model still win
		local CLUSTER_NUDGE = {
			ferrara_599 = { 0.07, 0, 1.04 }, -- on the line from the eye to the car's own cluster (from its 3D file)
			ferrara_f430 = { 0.09, 0, 1.8 }, -- owner's screenshot: big enough to cover its own cluster down to the hub
			lambrini_lp570 = { 0.15, 0, 1.25 }, -- owner's screenshot: up above the wheel hub, bigger
			bnw_m5_e60 = { 0, 0, 1.25 }, -- owner: bigger
		}
		local nudge = CLUSTER_NUDGE[spec.Id] or { 0, 0, 1 }
		local up = (if src then src:GetAttribute("ClusterUp") :: number? else nil) or nudge[1]
		local fwd = (if src then src:GetAttribute("ClusterForward") :: number? else nil) or nudge[2]
		local k = (if src then src:GetAttribute("ClusterSize") :: number? else nil) or nudge[3]
		local w = r * sizeFor[1]
		local h = r * sizeFor[2]
		local cf = root.CFrame * CFrame.lookAt(pos, pos + dir) * CFrame.new(0, up + (sizeFor[4] or 0), -fwd)
		local weld = dashPanel:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld.Enabled = false
		end
		dashPanel.Size = Vector3.new(w * k, h * k, 0.02)
		dashPanel.CFrame = cf
		if weld then
			weld.Enabled = true
		end
	end
	if dashPanel and dashPanel:IsA("BasePart") then
		local okDash, upd = pcall(DashGauges.build, dashPanel)
		dashUpdate = if okDash then upd else nil
	end
	local flames, flameParts, flameLight = buildFlames(model, root, spec)
	-- tyre smoke at each wheel's contact patch; strength follows the squeal
	local smoke: { { emitter: ParticleEmitter, rear: boolean } } = {}
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			local r = (j:GetAttribute("Radius") :: number?) or 1
			local att = Instance.new("Attachment")
			att.Name = "TyreSmoke"
			att.Position = j.C0.Position - Vector3.new(0, r * 0.85, 0)
			att.Parent = root
			table.insert(flameParts, att)
			local e = Instance.new("ParticleEmitter")
			e.Rate = 0
			e.Texture = "rbxasset://textures/particles/smoke_main.dds" -- built-in smoke puff
			e.Lifetime = NumberRange.new(1.2, 2.2)
			e.Speed = NumberRange.new(1, 3)
			e.SpreadAngle = Vector2.new(25, 25)
			e.Acceleration = Vector3.new(0, 2.5, 0)
			e.Drag = 1.5
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(0.4, 3.5), NumberSequenceKeypoint.new(1, 7) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 1) })
			e.Color = ColorSequence.new(Color3.fromRGB(196, 196, 198), Color3.fromRGB(150, 150, 154))
			e.LightInfluence = 0.25 -- neutral grey, not tinted purple by the neon
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-40, 40)
			e.Parent = att
			table.insert(smoke, { emitter = e, rear = j:GetAttribute("Front") ~= true })
		end
	end

	-- keyboard players start the car themselves (J, then F); touch and gamepad start running
	local autoStart = UI.isTouch or not UserInputService.KeyboardEnabled
	-- blinker lights at the four corners (seen by this player only)
	local blinkLights = { L = {} :: { PointLight }, R = {} :: { PointLight } }
	do
		local halfW = (model:GetAttribute("Width") :: number) / 2
		local reach = dims.wb * 0.78
		for _, side in { "L", "R" } do
			for _, z in { -reach, reach } do
				local att = Instance.new("Attachment")
				att.Name = "Blinker"
				att.Position = Vector3.new(if side == "L" then -halfW else halfW, 0, z)
				att.Parent = root
				table.insert(flameParts, att)
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 150, 20)
				light.Range = 7
				light.Brightness = 3
				light.Shadows = false
				light.Enabled = false
				light.Parent = att
				table.insert(blinkLights[side], light)
			end
		end
	end

	local s: State = {
		model = model,
		root = root,
		spec = spec,
		lv = lv,
		ao = ao,
		topSpeed = Config.mphToSps(spec.TopSpeed),
		accel = Config.mphToSps(60) / spec.ZeroToSixty,
		wheelbase = dims.wb,
		halfHeight = (model:GetAttribute("Height") :: number) / 2,
		width = model:GetAttribute("Width") :: number,
		yaw = yawFromLook(root.CFrame.LookVector),
		vel = Vector3.zero,
		steer = 0,
		wheelSpin = 0,
		wheels = wheels,
		steerMotor = steerMotor,
		steerMount = model:GetAttribute("SteerMount") :: CFrame?,
		steerMaxRot = (model:GetAttribute("SteerMaxRot") :: number?) or math.rad(110),
		arms = arms,
		upperLen = (model:GetAttribute("UpperLen") :: number?) or 1.1,
		foreLen = (model:GetAttribute("ForeLen") :: number?) or 1.05,
		eye = (model:GetAttribute("Eye") :: Vector3?) or Vector3.new(-1.3, 1, 0),
		lastCommand = Vector3.zero,
		crashCooldown = 0,
		lastCrash = 0,
		passTrack = {},
		lastCutTime = 0,
		lastCutSide = 0,
		grounded = true,
		connections = {},
		hidden = hidden,
		glass = glass,
		gaugeSpeed = gSpeed,
		gaugeGear = gGear,
		gaugeBar = gBar,
		dashUpdate = dashUpdate,
		localSteer = localSteer,
		localArms = localArms,
		partNeedles = partNeedles,
		guiNeedles = guiNeedles,
		guiTexts = guiTexts,
		speedShown = 0,
		smoke = smoke,
		roll = 0,
		pitch = 0,
		rpmShown = 0,
		camPos = root.Position + Vector3.new(0, 8, 20),
		camLook = root.Position,
		fov = Config.Camera.ChaseFov,
		shake = 0,
		gear = "N",
		rpm = 0,
		cabinLight = cabinLight,
		engine = Audio.engine(spec.Class, nil, spec.Id),
		throttle = 0,
		slip = 0,
		flames = flames,
		flameParts = flameParts,
		flameLight = flameLight,
		flameGlow = 0,
		throttleIn = 0,
		pops = 0,
		popTimer = 0,
		ignition = autoStart,
		engineOn = autoStart,
		cranking = 0,
		manual = Driving.gearbox == "Manual",
		mgear = 0,
		clutch = false,
		freeRpm = 0,
		launch = 0,
		parkBrake = false,
		tc = true,
		lightsOn = true,
		blinker = "",
		blinkT = 0,
		blinkLights = blinkLights,
		dashPanel = if dashPanel and dashPanel:IsA("BasePart") then dashPanel else nil,
	}
	state = s
	s.engine:setRunning(s.engineOn)
	if s.engineOn then
		Audio.engineStart()
	else
		setClusterPower(s, false)
		UI.toast("Press J for the ignition, then F to start the engine")
	end
	UI.setIndicators(indicatorState(s))
	camera.CameraType = Enum.CameraType.Scriptable

	-- apply current camera mode visibility
	Driving.cameraMode = if Driving.cameraMode == "Interior" then "Chase" else "Interior"
	Driving.toggleCamera()

	table.insert(s.connections, RunService.PreSimulation:Connect(function(dt)
		Driving.step(dt)
	end))
	table.insert(s.connections, RunService.RenderStepped:Connect(function(dt)
		Driving.render(dt)
	end))
	table.insert(s.connections, model.AncestryChanged:Connect(function(_, parent)
		if parent == nil and state and state.model == model then
			Driving.detach()
		end
	end))
end

---------------------------------------------------------------------
-- Physics step
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function reportCrash(s: State, severity: number)
	local now = os.clock()
	if now - s.lastCrash < 0.8 then
		return
	end
	s.lastCrash = now
	s.shake = math.max(s.shake, math.clamp(severity / 80, 0.3, 1.5))
	UI.flash(Config.Theme.Danger)
	UI.setCombo(0)
	remote("Crash"):FireServer()
	Audio.crash(severity)
end

local function detectCuts(s: State, fwd: Vector3, speedMph: number)
	local right = fwd:Cross(Vector3.yAxis)
	local myPos = Vector3.new(s.root.Position.X, 0, s.root.Position.Z)
	local E = Config.Economy
	local seen = {}
	for _, npc in Traffic.near(myPos, 45) do
		seen[npc] = true
		local rel = npc.pos - myPos
		local f = rel:Dot(fwd)
		local prev = s.passTrack[npc]
		s.passTrack[npc] = f
		if prev and prev > 0 and f <= 0 then
			local lat = rel:Dot(right)
			local gap = math.abs(lat) - (s.width + npc.width) / 2
			local recentlyCrashed = os.clock() - s.lastCrash < 1.2
			if gap < E.NearMissGap and gap > -1.5 and speedMph >= E.CutMinMph and not recentlyCrashed then
				local closeness = math.clamp(1 - gap / E.NearMissGap, 0, 1)
				local oncoming = npc.fwd:Dot(fwd) < -0.5
				local side = if lat >= 0 then 1 else -1
				local now = os.clock()
				local thread = now - s.lastCutTime < 0.4 and side ~= s.lastCutSide
				s.lastCutTime = now
				s.lastCutSide = side
				remote("CutUp"):FireServer({ closeness = closeness, oncoming = oncoming, thread = thread })
			end
		end
	end
	for npc in s.passTrack do
		if not seen[npc] then
			s.passTrack[npc] = nil
		end
	end
end

function Driving.step(dt: number)
	local s = state
	if not s or not s.root.Parent then
		return
	end
	dt = math.min(dt, 1 / 20)
	local root = s.root
	local throttleKey, brake, steerIn, handbrake, clutch = readInput()
	-- the engine: the starter turns it over for a moment, then it runs; off, the pedal does nothing
	if s.cranking > 0 then
		s.cranking -= dt
		if s.cranking <= 0 and s.ignition then
			s.engineOn = true
			s.engine:setRunning(true)
			UI.setIndicators(indicatorState(s))
		end
	end
	local throttle = if s.engineOn then throttleKey else 0
	handbrake = handbrake or s.parkBrake
	-- clutch (manual gearbox): dropping it at high revs from a standstill launches the car
	local clutchWas = s.clutch
	s.clutch = clutch and s.manual
	if clutchWas and not s.clutch and s.freeRpm > 0.6 and s.mgear >= 1 and s.engineOn and Config.spsToMph(s.vel.Magnitude) < 20 then
		s.launch = 0.8
	end
	s.launch = math.max(0, s.launch - dt)
	s.throttle += (throttle - s.throttle) * math.min(1, dt * 10)
	-- lifting off at high revs: a short crackle of pops + flames
	if s.throttleIn > 0.7 and throttle < 0.2 and s.rpm > 0.6 and Config.spsToMph(s.vel.Magnitude) > 30 then
		s.pops = math.random(2, 4)
		s.popTimer = 0.04
	end
	s.throttleIn = throttle

	-- ground check
	rayParams.FilterDescendantsInstances = { s.model, workspace:FindFirstChild("Traffic") :: Instance }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -(s.halfHeight + 1.2), 0), rayParams)
	s.grounded = hit ~= nil

	local actual = root.AssemblyLinearVelocity
	local actualFlat = Vector3.new(actual.X, 0, actual.Z)

	-- Crash detection: physics couldn't give us the velocity we asked for
	if s.grounded and s.lastCommand.Magnitude > 25 then
		local loss = (s.lastCommand - actualFlat).Magnitude
		if loss > math.max(22, s.lastCommand.Magnitude * 0.35) then
			s.vel = actualFlat
			reportCrash(s, loss)
		end
	end

	local fwd = forwardFromYaw(s.yaw)
	local right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
	local fwdSpeed = s.vel:Dot(fwd)
	local latSpeed = s.vel:Dot(right)
	local handling = s.spec.Handling

	if s.grounded then
		-- longitudinal
		local a = 0
		local speedFrac = fwdSpeed / s.topSpeed
		if s.manual then
			-- manual: the gear sets how hard the engine pulls; at the top of a gear it hits the limiter
			local engaged = s.engineOn and not s.clutch
			if engaged and s.mgear > 0 then
				local hi = (s.mgear / GEARS) ^ (1 / 0.8)
				local rev = math.max(speedFrac, 0) / hi
				if throttle > 0 then
					if fwdSpeed < -2 then
						a += 140 * throttle
					else
						local torque = if rev >= 1 then 0 else math.clamp(0.4 + 0.9 * rev, 0.4, 1)
						a += s.accel * 1.25 * throttle * torque * math.max(0, 1 - math.max(speedFrac, 0) ^ 2.6) * (if s.launch > 0 then 1.35 else 1)
					end
				elseif fwdSpeed > 2 then
					a -= 6 -- engine braking
				end
				if rev > 1.02 then
					a -= 30 * (rev - 1) -- shifted down too early: the engine holds the car back
				end
			elseif engaged and s.mgear < 0 and throttle > 0 then
				if fwdSpeed > 2 then
					a -= 140 * throttle
				elseif fwdSpeed > -s.topSpeed * 0.22 then
					a -= s.accel * 0.6 * throttle
				end
			end
			if brake > 0 then
				if fwdSpeed > 2 then
					a -= 150 * brake
				elseif fwdSpeed < -2 then
					a += 150 * brake
				end
			end
		else
			if throttle > 0 then
				if fwdSpeed < -2 then
					a += 140 * throttle -- braking out of reverse
				else
					a += s.accel * 1.25 * throttle * math.max(0, 1 - math.max(speedFrac, 0) ^ 2.6)
				end
			end
			if brake > 0 then
				if fwdSpeed > 2 then
					a -= 150 * brake
				elseif fwdSpeed > -s.topSpeed * 0.22 and s.engineOn then
					a -= s.accel * 0.6 * brake
				end
			end
		end
		-- rolling resistance + aero drag
		local drag = 4 + 0.00045 * fwdSpeed * fwdSpeed
		if handbrake then
			drag += 40
		end
		if math.abs(fwdSpeed) > 0.5 then
			a -= math.sign(fwdSpeed) * drag
		elseif throttle == 0 and brake == 0 then
			fwdSpeed = 0
		end
		fwdSpeed += a * dt

		-- steering: speed-sensitive wheel angle, capped by lateral grip
		local steerRate = if math.abs(steerIn) > math.abs(s.steer) then 4.2 else 7
		s.steer += (steerIn - s.steer) * math.min(1, dt * steerRate)
		local speedAbs = math.abs(fwdSpeed)
		local maxAngle = math.rad(36) / (1 + (speedAbs / 70) ^ 1.3)
		local angle = s.steer * maxAngle
		local yawRate = fwdSpeed * math.tan(angle) / s.wheelbase
		local gripG = 2.2 + 2.0 * handling -- real-life grip, not glued to the road
		local cap = gripG * 28 / math.max(speedAbs, 1)
		if handbrake then
			cap *= 1.7
		end
		yawRate = math.clamp(yawRate, -cap, cap)
		s.yaw -= yawRate * dt

		-- lateral grip (low with handbrake -> drift)
		local grip = if handbrake then 1.4 else 4.5 + 5 * handling
		-- hard launch: the rear steps out a little while the tyres find grip; traction control
		-- keeps it tidy, and with it off the rear lets go under power much longer
		if (throttle > 0.6 or s.launch > 0) and not handbrake then
			local loss = (if s.tc then 0.2 else 0.55) * throttle * math.clamp(1 - math.abs(speedFrac) * (if s.tc then 2.5 else 1.3), 0, 1)
			if s.launch > 0 then
				loss += 0.3
			end
			grip *= 1 - math.min(loss, 0.8)
		end
		latSpeed *= math.exp(-grip * dt)
		s.slip = math.abs(latSpeed) + (if handbrake and math.abs(fwdSpeed) > 20 then 25 else 0)
		-- tyres squeal: flooring it from low speed, braking hard at speed, turning hard when fast
		local sf = math.abs(fwdSpeed) / s.topSpeed
		if throttle > 0.7 and fwdSpeed >= -1 and sf < 0.35 then
			s.slip += (if s.tc then 22 else 52) * throttle * (1 - sf / 0.35)
		end
		if s.launch > 0 then
			s.slip += 40
		end
		if brake > 0.6 and fwdSpeed > 40 then
			s.slip += 36 * brake
		end
		if math.abs(s.steer) > 0.35 and sf > 0.4 then
			s.slip += 60 * math.abs(s.steer) * (sf - 0.4)
		end

		-- body lean: outward in turns, nose down when braking, squat when accelerating
		local latG = math.clamp(fwdSpeed * yawRate / 196.2, -1.5, 1.5)
		local lonG = math.clamp(a / 196.2, -1.5, 1.5)
		local rollTarget = math.rad(3.2) * latG
		local pitchTarget = math.rad(2.2) * lonG
		s.roll += (rollTarget - s.roll) * math.min(1, dt * 6)
		s.pitch += (pitchTarget - s.pitch) * math.min(1, dt * 6)

		local newFwd = forwardFromYaw(s.yaw)
		local newRight = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
		s.vel = newFwd * fwdSpeed + newRight * latSpeed
		s.lv.MaxForce = root.AssemblyMass * 400
	else
		s.lv.MaxForce = root.AssemblyMass * 8
		s.steer += (steerIn - s.steer) * math.min(1, dt * 6)
	end

	-- out of the world
	if root.Position.Y < -40 then
		Driving.reset()
		return
	end

	s.lv.PlaneVelocity = Vector2.new(s.vel.X, s.vel.Z)
	s.ao.CFrame = CFrame.Angles(0, s.yaw, 0) * CFrame.Angles(s.pitch, 0, s.roll)
	s.lastCommand = s.vel

	-- gears / rpm (cosmetic)
	local fs = s.vel:Dot(forwardFromYaw(s.yaw))
	local frac = math.clamp(math.abs(fs) / s.topSpeed, 0, 1)
	local prevGear = s.gear
	local function manualName(): string
		return if s.mgear < 0 then "R" elseif s.mgear == 0 then "N" else tostring(s.mgear)
	end
	if not s.engineOn then
		s.gear = if s.manual then manualName() else "N"
		s.rpm = if s.cranking > 0 then 0.12 else 0
		s.freeRpm = s.rpm
	elseif s.manual then
		s.gear = manualName()
		s.freeRpm += (0.12 + 0.86 * throttle - s.freeRpm) * math.min(1, dt * 6)
		if s.mgear == 0 or s.clutch then
			s.rpm = s.freeRpm
		elseif s.mgear < 0 then
			s.rpm = math.clamp(0.12 + 0.8 * -fs / (s.topSpeed * 0.22), 0.12, 1)
			s.freeRpm = s.rpm
		else
			local hi = (s.mgear / GEARS) ^ (1 / 0.8)
			s.rpm = math.clamp(0.12 + 0.88 * frac / hi, 0.12, 1.05)
			s.freeRpm = s.rpm
		end
	elseif fs < -1 then
		s.gear = "R"
		s.rpm = math.clamp(-fs / (s.topSpeed * 0.22), 0, 1)
	elseif math.abs(fs) < 1 and throttle == 0 then
		s.gear = "N"
		s.rpm = 0.1
	else
		local gears = GEARS
		local g = math.clamp(math.floor(frac ^ 0.8 * gears) + 1, 1, gears)
		s.gear = tostring(g)
		local lo = ((g - 1) / gears) ^ (1 / 0.8)
		local hi = (g / gears) ^ (1 / 0.8)
		s.rpm = math.clamp((frac - lo) / (hi - lo), 0, 1) * 0.75 + 0.2
	end

	-- shift sounds (dip in revs, pops on hard upshifts)
	local pg, ng = tonumber(prevGear), tonumber(s.gear)
	if pg and ng and ng ~= pg then
		s.engine:shift(ng > pg)
		if ng > pg and throttle > 0.5 then
			exhaustPop(s, 1)
		end
	end

	local mph = Config.spsToMph(math.abs(fs))
	detectCuts(s, forwardFromYaw(s.yaw), mph)
end

---------------------------------------------------------------------
-- Render: rig animation + camera
---------------------------------------------------------------------
function Driving.render(dt: number)
	local s = state
	if not s or not s.root.Parent then
		return
	end
	local root = s.root
	local fwd = forwardFromYaw(s.yaw)
	local fwdSpeed = s.vel:Dot(fwd)
	local speedFrac = math.clamp(math.abs(fwdSpeed) / s.topSpeed, 0, 1)

	-- wheels
	s.wheelSpin = (s.wheelSpin - fwdSpeed * dt / 1.1) % (math.pi * 2)
	local wheelAngle = -s.steer * math.rad(28) / (1 + (math.abs(fwdSpeed) / 90))
	for _, m in s.wheels do
		if m:GetAttribute("Front") then
			m.Transform = CFrame.Angles(0, wheelAngle, 0) * CFrame.Angles(s.wheelSpin, 0, 0)
			-- brake caliper rides on a knuckle that steers but doesn't spin
			local knuckle = s.root:FindFirstChild("Knuckle" .. m.Name:sub(6))
			if knuckle and knuckle:IsA("Motor6D") then
				knuckle.Transform = CFrame.Angles(0, wheelAngle, 0)
			end
		else
			m.Transform = CFrame.Angles(s.wheelSpin, 0, 0)
		end
	end

	-- steering wheel + hands + IK arms
	local rot = -s.steer * s.steerMaxRot
	if s.steerMotor then
		s.steerMotor.Transform = CFrame.Angles(0, 0, rot)
	end
	pcall(function()
		if s.steerMount and #s.localSteer > 0 then
			local wheelWorld = root.CFrame * s.steerMount * CFrame.Angles(0, 0, rot)
			for _, ls in s.localSteer do
				ls.part.CFrame = wheelWorld * ls.offset
			end
		end
		if s.steerMount and #s.localArms > 0 then
			local wheelCF = s.steerMount * CFrame.Angles(0, 0, rot)
			for _, arm in s.localArms do
				local handPos = (wheelCF * CFrame.new(arm.grip)).Position
				local fore, glove = arm.fore, arm.glove
				if fore then
					local upperCF, foreCF = CarBuilder.solveArm(arm.shoulder, handPos, arm.upperLen, arm.foreLen, arm.pole)
					arm.upper.CFrame = root.CFrame * upperCF * arm.rot
					fore.CFrame = root.CFrame * foreCF * arm.rot
					if glove then
						glove.CFrame = root.CFrame * foreCF * CFrame.new(0, 0, -(arm.foreLen + arm.handLen) / 2) * arm.rot
					end
				else
					-- one straight arm, shoulder to hand
					local len = (handPos - arm.shoulder).Magnitude
					if math.abs(arm.upper.Size.Y - len) > 0.02 then
						arm.upper.Size = Vector3.new(arm.upper.Size.X, len, arm.upper.Size.Z)
					end
					arm.upper.CFrame = root.CFrame * CFrame.lookAt((arm.shoulder + handPos) / 2, handPos) * arm.rot
				end
			end
		end
	end)
	if s.steerMount then
		local wheelCF = s.steerMount * CFrame.Angles(0, 0, rot)
		for _, arm in s.arms do
			local hand = (wheelCF * CFrame.new(arm.grip)).Position
			local upperCF, foreCF = CarBuilder.solveArm(arm.shoulder, hand, s.upperLen, s.foreLen, arm.pole)
			arm.upper.Transform = arm.upper.C0:Inverse() * upperCF
			arm.fore.Transform = arm.fore.C0:Inverse() * foreCF
		end
	end

	-- dashboard cluster + HUD
	local mph = Config.spsToMph(math.abs(fwdSpeed))
	if s.gaugeSpeed then
		s.gaugeSpeed.Text = tostring(math.floor((if Driving.units == "kmh" then mph * 1.609 else mph) + 0.5))
	end
	if s.gaugeGear then
		s.gaugeGear.Text = s.gear
	end
	if s.gaugeBar then
		s.gaugeBar.Size = UDim2.fromScale(s.rpm, 1)
	end
	if s.dashUpdate then
		pcall(s.dashUpdate, mph, s.gear, s.rpm)
	end
	pcall(function()
		if #s.partNeedles > 0 or #s.guiNeedles > 0 or #s.guiTexts > 0 then
			local k = 1 - math.exp(-dt * 10) -- needles swing, they don't snap
			s.speedShown += (math.clamp(mph / 160, 0, 1) - s.speedShown) * k
			s.rpmShown += (math.clamp(s.rpm, 0, 1) - s.rpmShown) * k
			for _, n in s.partNeedles do
				local v = if n.kind == "speed" then s.speedShown else s.rpmShown
				n.part.CFrame = root.CFrame * n.pivot * CFrame.Angles(0, 0, math.rad(v * 240)) * n.offset
			end
			for _, tl in s.guiTexts do
				tl.label.Text = if tl.kind == "Speed" then tostring(math.floor((if Driving.units == "kmh" then mph * 1.609 else mph) + 0.5)) elseif tl.kind == "RPM" then tostring(math.floor(s.rpm * 80) * 100) else s.gear
			end
			for _, n in s.guiNeedles do
				n.gui.Rotation = n.base + (if n.kind == "speed" then s.speedShown else s.rpmShown) * 240
			end
		end
	end)
	UI.setSpeed(mph, speedFrac, s.gear, s.rpm)

	-- blinkers: the corner lights and the HUD arrows flash together, with a soft tick
	if s.blinker ~= "" then
		local before = (s.blinkT % 0.8) < 0.4
		s.blinkT += dt
		local lit = (s.blinkT % 0.8) < 0.4
		for side, lights in s.blinkLights do
			local on = lit and (s.blinker == "H" or s.blinker == side)
			for _, l in lights do
				l.Enabled = on
			end
		end
		UI.setBlink(lit and s.blinker ~= "R", lit and s.blinker ~= "L")
		if lit ~= before then
			Audio.tick(lit)
		end
	elseif s.blinkT ~= 0 then
		s.blinkT = 0
		for _, lights in s.blinkLights do
			for _, l in lights do
				l.Enabled = false
			end
		end
		UI.setBlink(false, false)
	end

	-- engine / wind / tyre audio
	s.engine:update(s.rpm, s.throttle, speedFrac, s.slip)
	-- smoke with the squeal (same curve as the sound); launches smoke the rear tyres most
	local squeal = math.clamp((s.slip - 8) / 40, 0, 1)
	for _, sm in s.smoke do
		sm.emitter.Rate = if squeal > 0.05 then squeal * (if sm.rear then 70 else 35) else 0
	end

	-- exhaust crackle + flame glow
	if s.pops > 0 then
		s.popTimer -= dt
		if s.popTimer <= 0 then
			s.pops -= 1
			s.popTimer = 0.07 + math.random() * 0.12
			exhaustPop(s, 0.6 + math.random() * 0.4)
			if math.random() < 0.6 then
				Audio.backfire()
			end
		end
	end
	if s.flameLight then
		s.flameGlow = math.max(0, s.flameGlow - dt * 40)
		s.flameLight.Brightness = s.flameGlow
		s.flameLight.Enabled = s.flameGlow > 0
	end

	-- camera
	local C = Config.Camera
	s.shake = math.max(0, s.shake - dt * 2.5)
	local t = os.clock()
	local speedShake = 0.012 * math.min(speedFrac * 6, 1) + math.max(0, speedFrac - 0.3) * 0.16
	local shakeAmt = speedShake + s.shake * 0.5
	local shakeOffset = Vector3.new(math.noise(t * 23, 0, 1), math.noise(0, t * 21, 2), 0) * shakeAmt

	local targetFov
	local rootCF = root.CFrame
	if Driving.cameraMode == "Interior" then
		targetFov = C.InteriorFov + C.MaxFovBoost * C.InteriorFovBoost * speedFrac ^ 1.5
		local mouseLook = 0
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local vp = camera.ViewportSize
			local mp = UserInputService:GetMouseLocation()
			mouseLook = -((mp.X / vp.X) - 0.5) * math.rad(160)
		end
		local lookInto = -s.steer * math.rad(9)
		local eyeCF = rootCF * CFrame.new(s.eye) * CFrame.Angles(0, lookInto + mouseLook, 0) * CFrame.Angles(math.rad(-4), 0, 0)
		-- inside the cabin the view stays steady; only a crash jolts it
		local jolt = Vector3.new(math.noise(t * 23, 0, 1), math.noise(0, t * 21, 2), 0) * s.shake * 0.15
		camera.CFrame = eyeCF * CFrame.new(jolt)
		s.camPos = camera.CFrame.Position
		if blur then
			blur.Size = 0
		end
	else
		targetFov = C.ChaseFov + C.MaxFovBoost * speedFrac ^ 1.4
		-- follow the direction of travel a little when drifting
		local velDir = if s.vel.Magnitude > 5 then s.vel.Unit else fwd
		if s.vel:Dot(fwd) < -5 then
			velDir = fwd
		end
		local camDir = (fwd * 0.75 + velDir * 0.25).Unit
		local dist = C.ChaseDistance + speedFrac * 4
		local desired = root.Position - camDir * dist + Vector3.new(0, C.ChaseHeight - speedFrac * 0.8, 0)
		local alpha = 1 - math.exp(-dt * 10)
		s.camPos = s.camPos:Lerp(desired, alpha)
		-- never let the camera lag too far behind at hyper speeds
		local offset = s.camPos - root.Position
		if offset.Magnitude > dist * 1.6 then
			s.camPos = root.Position + offset.Unit * dist * 1.6
		end
		local look = root.Position + fwd * 10 + Vector3.new(0, 1.8, 0)
		s.camLook = s.camLook:Lerp(look, 1 - math.exp(-dt * 14))
		local roll = math.clamp(-s.steer * speedFrac * 0.05, -0.05, 0.05)
		camera.CFrame = CFrame.lookAt(s.camPos + shakeOffset, s.camLook) * CFrame.Angles(0, 0, roll)
		if blur then
			blur.Size = 3.5 * math.max(0, speedFrac - 0.45) ^ 1.5
		end
	end
	s.fov += (targetFov - s.fov) * math.min(1, dt * 4)
	camera.FieldOfView = s.fov
end

-- Settings: speed units for the HUD and the cluster ("mph" | "kmh")
function Driving.setUnits(units: string)
	Driving.units = if units == "kmh" then "kmh" else "mph"
	DashGauges.setUnits(Driving.units)
	UI.setUnits(Driving.units)
	local s = state
	if s and s.ignition then
		setClusterPower(s, true)
	end
end

-- Settings: "Auto" | "Manual" gearbox
function Driving.setGearbox(mode: string)
	Driving.gearbox = if mode == "Manual" then "Manual" else "Auto"
	local s = state
	if s then
		s.manual = Driving.gearbox == "Manual"
		s.mgear = if s.manual then (tonumber(s.gear) or 0) else 0
		UI.setIndicators(indicatorState(s))
	end
end

---------------------------------------------------------------------
-- One-time setup
---------------------------------------------------------------------
function Driving.init()
	local b = Instance.new("BlurEffect")
	b.Size = 0
	b.Parent = Lighting
	blur = b

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not state then
			return
		end
		if input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonY then
			Driving.toggleCamera()
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonSelect then
			Driving.reset()
		elseif Driving.inputEnabled and not UI.isGarageOpen() then
			carKey(state, input.KeyCode)
		end
	end)

	remote("Earned").OnClientEvent:Connect(function(info)
		if type(info) ~= "table" then
			return
		end
		if info.kind == "crash" then
			UI.setCombo(0)
			return
		end
		local amount = tonumber(info.amount) or 0
		local combo = tonumber(info.combo) or 1
		local text = tostring(info.label or "CUT UP")
		if combo > 1 then
			text ..= "  x" .. combo
		end
		local color = Config.Theme.Accent
		if text:find("THREAD") then
			color = Config.Theme.Accent2
		elseif text:find("ONCOMING") then
			color = Config.Theme.Warning
		end
		UI.popup(text, amount, color)
		UI.setCombo(combo)
		local s = state
		if s then
			s.shake = math.max(s.shake, 0.15)
		end
		Audio.cutUp(combo, text)
	end)
end

return Driving
