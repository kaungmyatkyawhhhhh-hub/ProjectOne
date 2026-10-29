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
	Car controls (keyboard): F start / stop the engine, Q / E shift down / up (the
	gearbox turns manual on the first shift, or from Settings), M automatic / sequential,
	Left Shift clutch, P handbrake,
	T traction control, L lights, Z / X / C left blinker / hazards / right blinker, V camera,
	(nitro is in but switched off: Config.DrivingFeel.NitroEnabled).
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
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))

local camera = workspace.CurrentCamera

local Driving = {}
Driving.cameraMode = "Immersive" -- "Immersive" | "Low" | "Chase" | "Interior" (owner, 2026-10-22: an immersive view that feels fast)
-- Settings > Camera (owner, 2026-10-29): shake and head movement 0 (off) / 0.5 (low) / 1 (normal),
-- motion blur on or off, the outside cameras' FOV. Reduced Motion starts shake and head off.
Driving.camFx = { shake = 1, head = 1, blur = true, fov = Config.Camera.Immersive.Fov }
function Driving.setCamFx(fx: { shake: number?, head: number?, blur: boolean?, fov: number? })
	local c = Driving.camFx
	if type(fx.shake) == "number" then
		c.shake = math.clamp(fx.shake, 0, 1)
	end
	if type(fx.head) == "number" then
		c.head = math.clamp(fx.head, 0, 1)
	end
	if type(fx.blur) == "boolean" then
		c.blur = fx.blur
	end
	if type(fx.fov) == "number" then
		c.fov = math.clamp(math.floor(fx.fov + 0.5), Config.Camera.FovMin, Config.Camera.FovMax)
	end
end
Driving.inputEnabled = true
Driving.cameraHold = false -- another screen (Legends Customs) moves the camera for now
Driving.gearbox = "Auto" -- "Auto" | "Manual" (Settings; Q / E switch to manual too)
Driving.units = "mph" -- "mph" | "kmh" (Settings): the HUD and every cluster
Driving.onGearboxChanged = nil :: ((string) -> ())? -- Q / E or M changed the gearbox
local GEARS = 7

type Corner = { motor: Motor6D, knuckle: Motor6D?, at: Vector3, rest: number, front: boolean, left: boolean, gap: number, travel: number, hit: Vector3? }

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
	ride: VectorForce, -- (unused: kept at zero)
	vyTarget: number?, -- the suspension's vertical speed for the body this frame (nil: in the air)
	hull: Part, -- the body's collision box, raised clear of the road (the springs hold the car up)
	corners: { Corner }, -- one per wheel: its spring's state
	susp: { spring: number, damp: number, bump: number, droop: number },
	stopT: number, -- seconds stood still with the brake held (reverse waits a moment)
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
	guiTexts: { { label: TextLabel, kind: string, unit: string? } }, -- on-screen "Speed" / "RPM" / "Gear" read-outs
	-- live needles over a model's own painted dials (CarSkin.DIAL_NEEDLES): reading -> degrees
	dialNeedles: { { gui: GuiObject, kind: string, unit: string, scale: { { number } } } },
	dialSweep: number?, -- when the engine started: the needles sweep to the end and back
	speedShown: number,
	mphShown: number,
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
	tails: { BasePart }, -- tail lamps (TailLight parts): dim with the lights on, bright when braking
	rearGlow: { PointLight },
	tailBrake: boolean?,
	dashPanel: BasePart?,
	-- drivetrain feel
	agear: number, -- the automatic gearbox's gear (1..GEARS)
	shiftT: number, -- seconds left of a shift: no drive while the gear changes
	nextGear: number,
	electric: boolean, -- one gear, silent motor
	powerK: number, -- per car, so 0-60 mph matches its real time with gears and shifts
	dragC: number, -- per car aero drag
	brakeIn: number, -- the brakes bite in over a moment
	pitchVel: number,
	rollVel: number,
	lonG: number,
	latG: number,
	headPos: Vector3, -- the driver's head moving with the g-forces (cockpit camera)
	headVel: Vector3,
	headTilt: Vector2, -- ...its pitch (x) and roll (y), on the same kind of spring
	headTiltVel: Vector2,
	handRot: number, -- where the hands hold the wheel (they re-grip on big turns)
	camLag: number,
	camSwing: number,
	camSide: number, -- the outside cameras: slid out of the turn
	camRoll: number, -- ...banked into it
	camPitch: number, -- ...tipped by the g: up pulling away, down braking
	gFov: number, -- ...the view widened pulling away, tightened braking
	camBob: number,
	screech: number, -- tyre cry on hard launches (sound only)
	chirp: number, -- seconds left of a tyre chirp after a hard low-gear shift
	launchReady: boolean, -- launch control: brake + throttle held at a stop
	-- driving feel (Config.DrivingFeel)
	yawRate: number, -- the car's turn now (it follows the wheel with some weight)
	groundDist: number?, -- last ground ray distance (kerbs and bumps kick the body)
	groundUp: Vector3, -- the road's slope under the car, smoothed (the body sits along it)
	fovPunch: number, -- a moment's wider view (launch, flat-out shift, close pass)
	blurPulse: number,
	roar: Sound?, -- tyre and road roar that grows with speed
	-- physics v2 and extras (Config.DrivingFeel)
	cls: ClassFeel, -- weight and handling by class
	drive: string, -- "RWD" | "FWD" | "AWD"
	drifting: boolean,
	driftAngle: number, -- the body's slip angle (radians, + when sliding to the right)
	driftCalm: number, -- seconds the slip has been small (a drift ends after DriftHold)
	absT: number,
	airT: number, -- seconds in the air
	airVy: number, -- falling speed while in the air (for the landing)
	nitro: number, -- 0..1 in the bottle
	boosting: boolean,
	flameColors: { ColorSequence }, -- the flames' own colours (nitro turns them blue)
	skidL: Vector3?, -- where the last skid mark ended under each rear tyre
	skidR: Vector3?,
	skidT: number,
	boostWas: boolean,
}

type ClassFeel = { roll: number, pitch: number, understeer: number, shiftTime: number, upshift: number, revRate: number, brake: number, inertia: number }

-- a class's weight and gearbox (Config.DrivingFeel.ClassFeel, Sedan for anything unknown)
local function classFeel(class: string): ClassFeel
	local t = Config.DrivingFeel.ClassFeel
	return t[class] or t.Sedan
end

local state: State? = nil
local remotes: Folder? = nil
local blur: BlurEffect? = nil
local setVignette: (number) -> ()

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

-- nitro: Left Ctrl or B, R1 on a gamepad, the N2O button on a phone (held)
local nitroTouch = false
local function nitroHeld(): boolean
	if not Config.DrivingFeel.NitroEnabled or not Driving.inputEnabled or UI.isGarageOpen() then
		return false
	end
	if UserInputService:GetFocusedTextBox() == nil and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.B)) then
		return true
	end
	if UserInputService.GamepadEnabled and UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR1) then
		return true
	end
	return nitroTouch
end

-- effects quality: phones and low graphics get fewer particles and marks
local function fxQuality(): number
	return math.clamp(WorldFx.qualityScale(), 0.3, 1)
end

-- the nitro bottle on the HUD (above the rev counter), and the phone's N2O button
local nitroGui: ScreenGui? = nil
local nitroFill: Frame? = nil
local function nitroHud(): (ScreenGui, Frame)
	if nitroGui and nitroFill then
		return nitroGui, nitroFill
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "NitroHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 6
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local back = Instance.new("Frame")
	back.AnchorPoint = Vector2.new(1, 1)
	back.Position = if UI.isTouch then UDim2.new(1, -24, 1, -232) else UDim2.new(1, -36, 1, -262)
	back.Size = UDim2.fromOffset(if UI.isTouch then 150 else 200, 12)
	back.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	back.BackgroundTransparency = 0.2
	back.BorderSizePixel = 0
	back.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = back
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(90, 150, 255)
	st.Transparency = 0.4
	st.Parent = back
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
	fill.BorderSizePixel = 0
	fill.Parent = back
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(60, 120, 255), Color3.fromRGB(150, 220, 255))
	g.Parent = fill
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(1, 0.5)
	label.Position = UDim2.new(0, -8, 0.5, 0)
	label.Size = UDim2.fromOffset(40, 16)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = "N2O"
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.TextColor3 = Color3.fromRGB(150, 200, 255)
	label.Parent = back
	if UI.isTouch then
		local b = Instance.new("TextButton")
		b.Name = "NitroButton"
		b.AnchorPoint = Vector2.new(1, 1)
		b.Position = UDim2.new(1, -24, 1, -252)
		b.Size = UDim2.fromOffset(64, 64)
		b.BackgroundColor3 = Color3.fromRGB(30, 70, 160)
		b.BackgroundTransparency = 0.15
		b.Font = Enum.Font.GothamBlack
		b.Text = "N2O"
		b.TextSize = 16
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Parent = gui
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = b
		b.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				nitroTouch = true
			end
		end)
		b.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				nitroTouch = false
			end
		end)
	end
	nitroGui, nitroFill = gui, fill
	return gui, fill
end

-- sparks where the car scrapes a wall (one emitter, moved to the contact)
local sparkPart: BasePart? = nil
local sparkEmitter: ParticleEmitter? = nil
local function sparks(at: Vector3, normal: Vector3, count: number)
	if not sparkPart then
		local p = Instance.new("Part")
		p.Name = "ScrapeSparks"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.EmissionDirection = Enum.NormalId.Front
		e.Lifetime = NumberRange.new(0.15, 0.45)
		e.Speed = NumberRange.new(18, 40)
		e.SpreadAngle = Vector2.new(55, 55)
		e.Acceleration = Vector3.new(0, -70, 0)
		e.Drag = 2
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.14), NumberSequenceKeypoint.new(1, 0) })
		e.Color = ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 120, 30))
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Brightness = 3
		e.Parent = p
		p.Parent = workspace
		sparkPart, sparkEmitter = p, e
	end
	local p = sparkPart :: BasePart
	p.CFrame = CFrame.lookAt(at, at + normal + Vector3.new(0, 0.4, 0))
	;(sparkEmitter :: ParticleEmitter):Emit(math.max(1, math.floor(count * fxQuality())))
end

-- skid marks: a pool of thin dark strips under the rear tyres that fade out
type Skid = { part: BasePart, born: number }
local skids: { Skid } = {}
local skidNext = 1
local skidFolder: Folder? = nil
local function skidMark(a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	if len < 0.3 or len > 20 then
		return
	end
	local DF = Config.DrivingFeel
	local cap = math.floor(DF.SkidMax * fxQuality())
	if not skidFolder then
		local f = Instance.new("Folder")
		f.Name = "SkidMarks"
		f.Parent = workspace
		skidFolder = f
	end
	local entry = skids[skidNext]
	if not entry then
		local p = Instance.new("Part")
		p.Name = "Skid"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(18, 18, 20)
		p.Parent = skidFolder
		entry = { part = p, born = 0 }
		skids[skidNext] = entry
	end
	entry.part.Size = Vector3.new(0.85, 0.04, len + 0.1)
	entry.part.CFrame = CFrame.lookAt((a + b) / 2, b)
	entry.part.Transparency = 0.35
	entry.born = os.clock()
	skidNext = skidNext % math.max(cap, 1) + 1
end
local skidFadeT = 0
local function fadeSkids(dt: number)
	skidFadeT += dt
	if skidFadeT < 0.25 then
		return
	end
	skidFadeT = 0
	local life = Config.DrivingFeel.SkidLife
	local now = os.clock()
	for _, e in skids do
		if e.born > 0 then
			local age = (now - e.born) / life
			if age >= 1 then
				e.born = 0
				e.part.Transparency = 1
			else
				e.part.Transparency = 0.35 + 0.65 * age * age
			end
		end
	end
end

-- the flames' blue nitro colour
local NITRO_FLAME = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 230, 255)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 130, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 60, 255)),
})

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

-- darkened screen edges at speed (a tunnel-vision rush; Roblox has no real motion blur)
local vignetteFrames: { Frame } = {}
setVignette = function(k: number)
	if #vignetteFrames == 0 then
		if k <= 0.001 then
			return
		end
		local gui = Instance.new("ScreenGui")
		gui.Name = "SpeedVignette"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = -5
		gui.Parent = player:WaitForChild("PlayerGui")
		-- four edge bands, each fading in towards the edge
		local sides = {
			{ UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0.68), -90 },
			{ UDim2.fromScale(0.26, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.26, 1), UDim2.fromScale(0.74, 0), 180 },
		}
		for _, sd in sides do
			local f = Instance.new("Frame")
			f.Size = sd[1]
			f.Position = sd[2]
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BorderSizePixel = 0
			f.BackgroundTransparency = 1
			local g = Instance.new("UIGradient")
			g.Rotation = sd[3]
			g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
			g.Parent = f
			f.Parent = gui
			table.insert(vignetteFrames, f)
		end
	end
	for _, f in vignetteFrames do
		f.BackgroundTransparency = 1 - math.clamp(k, 0, 1)
	end
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
	if s.roar then
		s.roar:Destroy()
	end
	setVignette(0)
	if nitroGui then
		nitroGui.Enabled = false
	end
	nitroTouch = false
	UI.startPrompt(false)
	UI.setSpeedLines(0)
	if s.cabinLight then
		s.cabinLight:Destroy()
	end
	s.ride:Destroy()
	s.hull:Destroy()
	if s.root.Parent then
		s.root.CanCollide = true
	end
	state = nil
	if blur then
		blur.Size = 0
	end
end

function Driving.isDriving(): boolean
	return state ~= nil
end

-- the body's slip angle (radians, + sliding to the right), whether it's drifting, the nitro (0..1)
function Driving.getSlipAngle(): number
	return if state then state.driftAngle else 0
end
function Driving.isDrifting(): boolean
	return state ~= nil and state.drifting
end
function Driving.getNitro(): number
	return if state then state.nitro else 0
end

function Driving.getRoot(): BasePart?
	return if state then state.root else nil
end

function Driving.getModel(): Model?
	return if state then state.model else nil
end

-- ground speed in studs per second (0 when not driving)
function Driving.getSpeed(): number
	return if state then Vector3.new(state.vel.X, 0, state.vel.Z).Magnitude else 0
end

-- leaving the car (getting out to walk): it stops where it is, the cabin shows from outside again
function Driving.park()
	local s = state
	if not s then
		return
	end
	s.vel = Vector3.zero
	s.lv.PlaneVelocity = Vector2.zero
	for _, p in s.hidden do
		p.LocalTransparencyModifier = 0
	end
	for _, g in s.glass do
		g.LocalTransparencyModifier = 0
	end
	if s.cabinLight then
		s.cabinLight.Enabled = false
	end
	Driving.detach()
end

local CAMERA_ORDER = { Immersive = "Low", Low = "Chase", Chase = "Interior", Interior = "Immersive" }
function Driving.toggleCamera()
	Driving.cameraMode = CAMERA_ORDER[Driving.cameraMode] or "Immersive"
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
	s.yawRate = 0
	s.groundDist = nil
	s.groundUp = Vector3.yAxis
	s.drifting = false
	s.airT, s.airVy = 0, 0
	s.skidL, s.skidR = nil, nil
	s.lastCommand = Vector3.zero
end

---------------------------------------------------------------------
-- Drivetrain: gears, torque, shifts
---------------------------------------------------------------------
-- gear ratios as the share of top speed each gear reaches (at 88% of the revs); top gear reaches
-- top speed at 88% of the revs, so the car tops out without hitting the limiter. Each higher
-- gear pulls less (the ratio), so the revs climb slower in the upper gears, like a real gearbox
local RATIOS = { 0.30, 0.45, 0.58, 0.69, 0.79, 0.89, 1.0 }
local function gearHi(g: number): number
	return RATIOS[math.clamp(g, 1, GEARS)] / 0.88
end

-- pull at the wheels in a gear: engine torque times the gear ratio (1st gear = 1)
local function gearMul(g: number): number
	return gearHi(1) / gearHi(g)
end

-- an electric car's single gear (owner: "0-100 very fast but hard to get top speed"): instant full
-- pull up to a quarter of top speed, then it fades away fast, so the last stretch to top speed takes
-- a long time (no shifts, no limiter)
local function evPull(frac: number): number
	return math.min(1, (0.25 / math.max(frac, 1e-3)) ^ 2)
end
local EV_LAUNCH = 0.7 -- electric cars reach 60 mph in 70% of their listed time

-- engine torque over the rev range (rev 0..1 of the limiter): soft at the bottom, strongest in the
-- upper middle, easing off before the limiter, nothing at it
local function torqueCurve(rev: number): number
	if rev >= 1 then
		return 0
	end
	return 0.72 + 0.33 * math.sin(math.clamp(rev / 0.72, 0, 1) * math.pi / 2) - math.max(0, rev - 0.82) * 0.9
end

-- (where the automatic shifts flat out and how long a shift takes: by class, Config.DrivingFeel.ClassFeel)

-- air drag: at top speed it takes three quarters of the pull, the rest is held back by the
-- top speed limit, so cars reach their real top speed in a sensible time
local function dragFor(accel: number, k: number, top: number, electric: boolean): number
	local topPull = accel * k * (if electric then evPull(1) else torqueCurve(0.88) * gearMul(GEARS))
	return math.max(0.75 * topPull - 2, 0.5) / (top * top)
end

-- the power scale that gives a car its real 0-60 mph time once gears, shifts and drag are in
-- (worked out once per car); returns it with the car's drag
local powerCache: { [string]: { number } } = {}
local function powerFor(spec: Cars.CarSpec): (number, number)
	local top = Config.mphToSps(spec.TopSpeed)
	local accel = Config.mphToSps(60) / spec.ZeroToSixty
	local cached = powerCache[spec.Id]
	if cached then
		return cached[1], cached[2]
	end
	local target = Config.mphToSps(60)
	local electric = spec.Electric == true
	local cf = classFeel(spec.Class)
	local function zeroToSixty(k: number): number
		local c = dragFor(accel, k, top, electric)
		local v, g, cut, t, dt = 0, 1, 0, 0, 1 / 60
		while t < 40 do
			local frac = v / top
			local rev = frac / gearHi(g)
			local a = 0
			if electric then
				a = accel * k * evPull(frac)
			elseif cut > 0 then
				cut -= dt
			else
				a = accel * k * torqueCurve(math.max(rev, 0.3)) * gearMul(g)
				if rev >= cf.upshift and g < GEARS then
					g += 1
					cut = cf.shiftTime
				end
			end
			a -= 2 + c * v * v
			v = math.max(0, v + a * dt)
			t += dt
			if v >= target then
				return t
			end
		end
		return 40
	end
	local lo, hi = 0.3, 8
	for _ = 1, 18 do
		local mid = (lo + hi) / 2
		if zeroToSixty(mid) > spec.ZeroToSixty * (if electric then EV_LAUNCH else 1) then
			lo = mid
		else
			hi = mid
		end
	end
	powerCache[spec.Id] = { hi, dragFor(accel, hi, top, electric) }
	return hi, dragFor(accel, hi, top, electric)
end

-- the live cluster on the dashboard: built again (needle sweep and all) when switched on or when
-- the speed units change
local function setClusterPower(s: State, on: boolean)
	-- the car's own dials: the needles glow and sweep when it starts, and go unlit when it stops
	for _, n in s.dialNeedles do
		local sg = n.gui:FindFirstAncestorWhichIsA("SurfaceGui")
		if sg then
			sg.LightInfluence = if on then 0 else 1
			sg.Brightness = if on then 0.8 else 1 -- lit, but below the bloom: a crisp needle, no halo
			local light = sg.Parent and sg.Parent:FindFirstChild("DialLight")
			if light and light:IsA("Light") then
				light.Enabled = on
			end
		end
	end
	s.dialSweep = if on then os.clock() else nil
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

-- tail lamps: off with the lights, dim red with them on, bright red while braking
local TAIL_DIM, TAIL_BRAKE = Color3.fromRGB(150, 0, 6), Color3.fromRGB(255, 22, 22)
local function setTails(s: State)
	local braking = s.tailBrake == true
	for _, t in s.tails do
		local off = t:GetAttribute("TailOff") :: number?
		if off then
			-- a glowing copy over the model's own lamp: gone when the lights are off
			t.Color = if braking then TAIL_BRAKE else TAIL_DIM
			t.Transparency = if not s.lightsOn and not braking then 1 elseif braking then off * 0.3 else off
		else
			-- the lamp itself (our own bodies): darker when off
			t.Color = if braking then TAIL_BRAKE elseif s.lightsOn then TAIL_DIM else Color3.fromRGB(60, 0, 4)
		end
	end
	for _, g in s.rearGlow do
		g.Enabled = s.lightsOn or braking
		g.Brightness = if braking then 2.2 else 0.6
	end
end

local function setLights(s: State, on: boolean)
	s.lightsOn = on
	setTails(s)
	for _, d in s.model:GetDescendants() do
		if d:IsA("SpotLight") or (d:IsA("SurfaceLight") and d.Parent and d.Parent.Name:lower():find("head")) then
			d.Enabled = on
		end
	end
end

-- the engine starting brings the dash (needle sweep) and the lights on; stopping it turns them off
local function setCarPower(s: State, on: boolean)
	setClusterPower(s, on)
	setLights(s, on)
	remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn })
end

-- F / Q / E / M / P / T / L / Z / X / C
local function carKey(s: State, key: Enum.KeyCode)
	if key == Enum.KeyCode.F then
		if s.engineOn then
			s.engineOn = false
			s.engine:setRunning(false)
			setCarPower(s, false)
			UI.toast(if s.electric then "Power off" else "Engine off")
		elseif s.cranking <= 0 then
			if s.electric then
				s.cranking = 0.3 -- an electric car is just ready, silently
			else
				s.cranking = 0.8
				s.engine:crank()
			end
		end
	elseif (key == Enum.KeyCode.E or key == Enum.KeyCode.Q) and s.electric then
		UI.toast("Electric: one gear, just drive")
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
		if s.mgear ~= before and s.mgear > 0 and not s.clutch then
			s.shiftT = 0.1 -- a quick shift: the drive drops for a moment, then kicks back in
			s.nextGear = s.mgear
		end
	elseif key == Enum.KeyCode.M then
		-- automatic <-> sequential (owner, 2026-10-29)
		if s.electric then
			UI.toast("Electric: one gear, just drive")
		else
			local mode = if s.manual then "Auto" else "Manual"
			Driving.setGearbox(mode)
			if Driving.onGearboxChanged then
				Driving.onGearboxChanged(mode)
			end
			UI.toast(if mode == "Manual" then "Sequential: Q / E to shift" else "Automatic")
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
	if key == Enum.KeyCode.L or key == Enum.KeyCode.Z or key == Enum.KeyCode.X or key == Enum.KeyCode.C then
		remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn })
	end
end

-- other players' cars: their blinkers and lights, from the attributes the server sets on them
type OtherCar = { model: Model, L: { PointLight }, R: { PointLight }, lights: boolean? }
local others: { [Model]: OtherCar } = {}
local function otherCar(model: Model): OtherCar?
	local found = others[model]
	if found then
		return found
	end
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local _, size = model:GetBoundingBox()
	local o: OtherCar = { model = model, L = {}, R = {} }
	for _, side in { "L", "R" } do
		for _, z in { -size.Z * 0.46, size.Z * 0.46 } do
			local att = Instance.new("Attachment")
			att.Name = "Blinker"
			att.Position = Vector3.new(if side == "L" then -size.X * 0.46 else size.X * 0.46, 0, z)
			att.Parent = root
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 150, 20)
			light.Range = 7
			light.Brightness = 3
			light.Shadows = false
			light.Enabled = false
			light.Parent = att
			table.insert((o :: any)[side], light)
		end
	end
	others[model] = o
	return o
end

local function updateOthers()
	local folder = workspace:FindFirstChild("PlayerCars")
	if not folder then
		return
	end
	local lit = (os.clock() % 0.8) < 0.4
	for _, model in folder:GetChildren() do
		if not model:IsA("Model") or model:GetAttribute("Owner") == player.UserId then
			continue
		end
		local blinker = (model:GetAttribute("Blinker") :: string?) or ""
		local lights = model:GetAttribute("Lights")
		local o = others[model] or (if blinker ~= "" or lights ~= nil then otherCar(model) else nil)
		if not o then
			continue
		end
		for side, list in { L = o.L, R = o.R } do
			local on = lit and (blinker == "H" or blinker == side)
			for _, l in list do
				l.Enabled = on
			end
		end
		if lights ~= nil and lights ~= o.lights then
			o.lights = lights :: boolean
			for _, d in model:GetDescendants() do
				if d:IsA("SpotLight") then
					d.Enabled = lights :: boolean
				end
			end
		end
	end
	for model in others do
		if not model.Parent then
			others[model] = nil
		end
	end
end

function Driving.attach(model: Model)
	Driving.detach()
	local root = model.PrimaryPart :: BasePart
	local spec = Cars.get(model:GetAttribute("CarId") :: string)
	local dims = CarBuilder.getDims(spec.Class, spec.Id)
	local lv = root:WaitForChild("Drive", 10) :: LinearVelocity?
	local ao = root:WaitForChild("Steer", 10) :: AlignOrientation?
	if not (lv and ao) then
		warn("[CityLegends] car never got its drive parts, not attaching")
		return
	end
	-- the suspension (owner, 2026-10-24: the car "jerks around like it's driving on rocks" on the
	-- bridge ramps and bounces under hard braking). The body is a box that used to slide on the road
	-- on its bottom face: tipped by braking or a change of slope its edge dug into the road and was
	-- shoved back out. Now a spring holds it a little above the road, so it can lean freely.
	local ride = Instance.new("VectorForce")
	ride.Name = "Ride"
	ride.Attachment0 = lv.Attachment0
	ride.RelativeTo = Enum.ActuatorRelativeTo.World
	ride.ApplyAtCenterOfMass = true
	ride.Force = Vector3.zero
	ride.Parent = root
	-- realistic suspension (owner, 2026-10-24: "add realistic suspension"): each wheel reads the
	-- road under it and has its own spring. The body sits on them at its real ride height, tilts
	-- with the road the four wheels are on (one wheel up a kerb tips it), and the wheels move up and
	-- down under it over bumps. The body box no longer touches the road: a collision hull, raised
	-- clear of it, keeps walls and other cars out.
	local DFs = Config.DrivingFeel
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(root.Size.X, math.max(root.Size.Y - DFs.HullLift, 0.6), root.Size.Z)
	hull.CFrame = root.CFrame * CFrame.new(0, (root.Size.Y - hull.Size.Y) / 2, 0)
	hull.Transparency = 1
	hull.CanCollide = true
	hull.CanQuery = false
	hull.CanTouch = true
	hull.Massless = true
	hull.CustomPhysicalProperties = root.CustomPhysicalProperties
	local hw = Instance.new("WeldConstraint")
	hw.Part0 = root
	hw.Part1 = hull
	hw.Parent = hull
	hull.Parent = model
	root.CanCollide = false

	local wheels = {}
	local arms: { ArmRig } = {}
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
		end
	end
	local corners: { Corner } = {}
	for _, j in wheels do
		-- the wheel centre's height over the road when the car stands at its design ride height
		local rest = j.C0.Position.Y + root.Size.Y / 2 + 0.025
		local knuckle = root:FindFirstChild("Knuckle" .. j.Name:sub(6))
		table.insert(corners, {
			motor = j,
			knuckle = if knuckle and knuckle:IsA("Motor6D") then knuckle else nil,
			at = j.C0.Position,
			rest = rest,
			front = j.C0.Position.Z < 0,
			left = j.C0.Position.X < 0,
			gap = 0,
			travel = 0,
			hit = nil,
		})
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
	cabinLight.Brightness = 0.45 -- just enough to read the cabin; brighter washed it out (owner, 2026-10-17)
	cabinLight.Range = 7
	cabinLight.Shadows = false
	cabinLight.Enabled = false
	cabinLight.Parent = root

	local gSpeed, gGear, gBar = buildGauges(model)
	local localSteer = {}
	local localArms = {}
	local partNeedles = {}
	local guiNeedles = {}
	local guiTexts = {}
	local dialNeedles = {}
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
				elseif d:IsA("GuiObject") and d.Name == "DialNeedle" then
					local pts = {}
					for v, a in string.gmatch(tostring(d:GetAttribute("GaugeScale")), "(%-?[%d%.]+):(%-?[%d%.]+)") do
						table.insert(pts, { tonumber(v) :: number, tonumber(a) :: number })
					end
					if #pts >= 2 then
						table.insert(dialNeedles, { gui = d, kind = tostring(d:GetAttribute("GaugeKind")), unit = tostring(d:GetAttribute("GaugeUnit")), scale = pts })
					end
				elseif d:IsA("TextLabel") and model:GetAttribute("OwnInterior") and (d.Name == "Speed" or d.Name == "RPM" or d.Name == "Gear") then
					-- a read-out printed for one unit (a car's own km/h display) keeps to it
					local unit = d:GetAttribute("GaugeUnit")
					table.insert(guiTexts, { label = d, kind = d.Name, unit = if type(unit) == "string" then unit else nil })
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
				-- no avatar (a Studio test player, or the avatar service down): plain default arms
				if not ok then
					ok, rig = pcall(function()
						return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R6)
					end)
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
		F430 = { 1.7, 0.6 },
		Ferrari458 = { 1.6, 0.6 },
		FerrariCalifornia = { 1.6, 0.6 },
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
		GallardoSL = { 1.8, 0.66 },
		EV6 = { 1.7, 0.62, 0.95 },
		Aston = { 1.8, 0.62 },
		AMGSls = { 1.7, 0.62 },
		Urus = { 2.0, 0.72 },
		Murcielago = { 1.9, 0.66 },
		MurcielagoLP640 = { 1.9, 0.66 },
		C6 = { 1.9, 0.66 },
		C7 = { 2.0, 0.66 },
	}
	local sizeFor = if type(style) == "string" then CLUSTER_SIZE[style] else nil
	if dashPanel and dashPanel:IsA("BasePart") and sizeFor and not dashPanel:GetAttribute("Placed")
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
			lambrini_lp640 = { 0, 0, 0.9 }, -- the LP640 design inside its own hood
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

	-- keyboard players start the engine themselves (F); touch and gamepad start running
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
		ride = ride,
		hull = hull,
		corners = corners,
		susp = Config.DrivingFeel.Suspension[spec.Class] or Config.DrivingFeel.Suspension.Sedan,
		stopT = 0,
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
		dialNeedles = dialNeedles,
		speedShown = 0,
		mphShown = 0,
		smoke = smoke,
		roll = 0,
		pitch = 0,
		rpmShown = 0,
		camPos = root.Position + Vector3.new(0, 8, 20),
		camLook = root.Position,
		camLag = 0, -- immersive camera: pulled back on hard acceleration, pushed in braking
		camSwing = 0, -- immersive camera: looks into the turn
		camSide = 0,
		camRoll = 0,
		camPitch = 0,
		gFov = 0,
		camBob = 0,
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
		ignition = true, -- no ignition key (owner): the dash is always on in the car
		engineOn = autoStart,
		cranking = 0,
		manual = Driving.gearbox == "Manual" and spec.Electric ~= true,
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
		tails = {},
		rearGlow = {},
		dashPanel = if dashPanel and dashPanel:IsA("BasePart") then dashPanel else nil,
		agear = 1,
		shiftT = 0,
		nextGear = 1,
		electric = spec.Electric == true,
		powerK = 1,
		dragC = 0,
		brakeIn = 0,
		pitchVel = 0,
		rollVel = 0,
		lonG = 0,
		latG = 0,
		headPos = Vector3.zero,
		headVel = Vector3.zero,
		headTilt = Vector2.zero,
		headTiltVel = Vector2.zero,
		handRot = 0,
		screech = 0,
		chirp = 0,
		launchReady = false,
		yawRate = 0,
		groundDist = nil,
		groundUp = Vector3.yAxis,
		fovPunch = 0,
		blurPulse = 0,
		roar = nil,
		cls = classFeel(spec.Class),
		drive = if Config.DrivingFeel.AllDrive[spec.Id] then "AWD" elseif Config.DrivingFeel.FrontDrive[spec.Id] then "FWD" else "RWD",
		drifting = false,
		driftAngle = 0,
		driftCalm = 0,
		absT = 0,
		airT = 0,
		airVy = 0,
		nitro = 0.5, -- half a bottle to start
		boosting = false,
		boostWas = false,
		flameColors = {},
		skidL = nil,
		skidR = nil,
		skidT = 0,
	}
	for _, e in flames do
		table.insert(s.flameColors, e.Color)
	end
	state = s
	if Config.DrivingFeel.NitroEnabled then
		nitroHud()
		if nitroGui then
			nitroGui.Enabled = true
		end
	end
	-- road roar: the tyres on the tarmac and the air round the car, rising with speed
	do
		local roar = Instance.new("Sound")
		roar.Name = "RoadRoar"
		roar.SoundId = "rbxasset://sounds/action_falling.ogg"
		roar.Looped = true
		roar.Volume = 0
		roar.PlaybackSpeed = 0.4
		local eq = Instance.new("EqualizerSoundEffect")
		eq.LowGain = 6
		eq.MidGain = -6
		eq.HighGain = -18
		eq.Parent = roar
		roar.Parent = game:GetService("SoundService")
		roar:Play()
		s.roar = roar
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("TailLight") then
			table.insert(s.tails, d)
		elseif d:IsA("PointLight") and (d.Name == "RearGlow" or d.Name == "TailGlow") and d.Enabled then
			table.insert(s.rearGlow, d)
		end
	end
	s.powerK, s.dragC = powerFor(spec)
	s.engine:setRunning(s.engineOn and not s.electric)
	if s.engineOn and not s.electric then
		s.engine:crank()
	else
		setClusterPower(s, false) -- dark dash and lights until the engine starts
		setLights(s, false)
		remote("CarSignals"):FireServer({ blinker = "", lights = false })
		UI.startPrompt(true)
	end
	UI.setIndicators(indicatorState(s))
	camera.CameraType = Enum.CameraType.Scriptable

	-- apply current camera mode visibility
	-- toggleCamera below moves one step on: start one step back so it lands on the current mode
	local back = Driving.cameraMode
	for prev, nxt in CAMERA_ORDER do
		if nxt == back then
			Driving.cameraMode = prev
		end
	end
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
				-- the whoosh of a car going past, and a flick of the view
				Audio.passBy(0.35 + 0.45 * closeness)
				s.nitro = math.min(1, s.nitro + Config.DrivingFeel.NitroFillPass * (0.5 + closeness))
				s.fovPunch += Config.DrivingFeel.NearMissFov * (0.5 + closeness)
				s.shake = math.max(s.shake, 0.12 + 0.2 * closeness)
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
			UI.startPrompt(false)
			s.engineOn = true
			s.engine:setRunning(not s.electric)
			setCarPower(s, true)
			UI.setIndicators(indicatorState(s))
		end
	end
	local throttle = if s.engineOn then throttleKey else 0
	local braking = s.engineOn and brake > 0.05
	if braking ~= (s.tailBrake == true) then
		s.tailBrake = braking
		setTails(s)
	end
	handbrake = handbrake or s.parkBrake
	-- clutch (manual gearbox): dropping it at high revs from a standstill launches the car
	local clutchWas = s.clutch
	s.clutch = clutch and s.manual
	local DF = Config.DrivingFeel
	local launchWas = s.launch
	if clutchWas and not s.clutch and s.freeRpm > 0.6 and s.mgear >= 1 and s.engineOn and Config.spsToMph(s.vel.Magnitude) < 20 then
		s.launch = 0.8
	end
	s.launch = math.max(0, s.launch - dt)
	-- launch control (automatic): hold the brake and floor it at a stop, the revs build; let go of
	-- the brake and the car launches
	-- It latches: once set at a stop it holds until the brake is let go (it used to drop out whenever
	-- the car crept, so the revs bounced 1,000-3,000 and the car rolled: owner, 2026-10-24)
	local standing = math.abs(s.vel:Dot(forwardFromYaw(s.yaw))) < 3
	local holding
	if s.launchReady then
		holding = s.engineOn and brake > 0.3 and throttle > 0.3
	else
		holding = not s.manual and s.engineOn and standing and brake > 0.5 and throttle > 0.5
	end
	if s.launchReady and not holding and throttle > 0.5 and brake <= 0.3 then
		s.launch = 0.8
	end
	if holding and not s.launchReady then
		UI.toast("Launch control: let go of the brake")
	end
	s.launchReady = holding
	s.engine:setLaunch(holding)
	-- a launch: the view kicks wide and blurs for a moment, the camera is thrown back
	if s.launch > launchWas + 0.5 then
		s.fovPunch += DF.LaunchKickFov
		s.blurPulse = math.max(s.blurPulse, DF.LaunchBlur)
		s.camLag += 2.5
		s.shake = math.max(s.shake, 0.35)
	end
	s.throttle += (throttle - s.throttle) * math.min(1, dt * 10)
	-- lifting off at high revs: a short crackle of pops + flames
	if s.throttleIn > 0.7 and throttle < 0.2 and s.rpm > 0.6 and Config.spsToMph(s.vel.Magnitude) > 30 and not s.electric then
		s.pops = math.random(2, 4)
		s.popTimer = 0.04
	end
	s.throttleIn = throttle

	-- ground check
	rayParams.FilterDescendantsInstances = { s.model, workspace:FindFirstChild("Traffic") :: Instance }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -(s.halfHeight + 1.2), 0), rayParams)
	s.grounded = hit ~= nil
	-- kerbs, ramps and bumps: a sudden change in the ground under the car kicks the body
	if hit then
		local last = s.groundDist
		if last then
			local jump = last - hit.Distance -- up when the ground rises
			if math.abs(jump) > 0.18 and math.abs(jump) < 4 then -- (the spring smooths small ones)
				s.pitchVel += jump * DF.BumpKick * 20
				s.rollVel += jump * DF.BumpKick * 8 * (if math.random() < 0.5 then -1 else 1)
				s.shake = math.max(s.shake, math.min(math.abs(jump) * 0.5, 0.6))
			end
		end
		s.groundDist = hit.Distance
	else
		s.groundDist = nil
	end
	-- the suspension: a ray down from each wheel finds the road under it; how far the wheel sits
	-- from where it should be is its spring's travel. The springs together carry the body (one
	-- force through its middle; the tilt comes from the road plane below)
	local sp = s.susp
	local up = root.CFrame.UpVector
	local sum, nOn = 0, 0
	for _, c in s.corners do
		local origin = root.CFrame:PointToWorldSpace(c.at) + up * 1
		local r = workspace:Raycast(origin, -up * (1 + c.rest + sp.droop + 0.6), rayParams)
		if r and r.Normal.Y > 0.6 then
			c.gap = (r.Distance - 1) - c.rest -- above zero: the road is lower than the wheel's rest
			c.hit = r.Position
			sum += c.gap
			nOn += 1
		else
			c.gap = sp.droop
			c.hit = nil
		end
	end
	-- The springs act as a vertical speed for the body, which the physics holds every physics step
	-- (a force set once a frame overshot at low frame rates: a dropped car bounced 7 studs high).
	-- The body rises or sinks back to its ride height at the spring's own rate, plus the road's own
	-- climb or fall under it, and the damping is the speed limit on the way.
	if nOn > 0 then
		local avg = sum / nOn
		local rate = math.sqrt(sp.spring) * 0.55
		local vy = -avg * rate
		-- (fewer wheels on the road: over an edge the car drops away freely)
		if nOn < #s.corners then
			vy = math.min(vy, root.AssemblyLinearVelocity.Y)
		end
		s.vyTarget = math.clamp(vy, -sp.damp, sp.damp)
	else
		s.vyTarget = nil
	end
	-- the road plane under the four wheels: the body lies along it (one wheel up a kerb tips it; a
	-- crest or a dip pitches it). In the air it eases back level.
	local upNow = Vector3.yAxis
	do
		local fl, fr, rl, rr
		for _, c in s.corners do
			if c.hit then
				if c.front then
					if c.left then
						fl = c.hit
					else
						fr = c.hit
					end
				else
					if c.left then
						rl = c.hit
					else
						rr = c.hit
					end
				end
			end
		end
		if fl and fr and rl and rr then
			local along = (fl + fr) / 2 - (rl + rr) / 2
			local across = (fr + rr) / 2 - (fl + rl) / 2
			if along.Magnitude > 0.5 and across.Magnitude > 0.5 then
				local nrm = across.Unit:Cross(along.Unit)
				if nrm.Y > 0.6 then
					upNow = nrm.Unit
				end
			end
		elseif hit and hit.Normal.Y > 0.75 then
			upNow = hit.Normal
		end
	end
	s.groundUp = s.groundUp:Lerp(upNow, math.min(1, dt * (if nOn > 0 then 12 else 2))).Unit
	s.grounded = nOn > 0

	local actual = root.AssemblyLinearVelocity
	local actualFlat = Vector3.new(actual.X, 0, actual.Z)

	-- in the air (a ramp, the viaduct's kinks, a kerb at speed) and the landing: the body
	-- compresses, the nose dips, the camera thumps, a hard one bangs
	if not s.grounded then
		s.airT += dt
		s.airVy = math.min(s.airVy, actual.Y)
	else
		if s.airT > 0.25 then
			local fall = -s.airVy
			if fall > 8 then
				s.pitchVel -= DF.LandKick * fall
				s.headVel += Vector3.new(0, -fall * 0.04, 0)
				s.shake = math.max(s.shake, math.clamp(fall / 60, 0.2, 1))
				if fall > 45 then
					Audio.crash(fall * 0.5)
				end
			end
		end
		s.airT, s.airVy = 0, 0
	end

	-- Crash detection: physics couldn't give us the velocity we asked for
	if s.grounded and s.lastCommand.Magnitude > 25 then
		local loss = (s.lastCommand - actualFlat).Magnitude
		if loss > math.max(22, s.lastCommand.Magnitude * 0.35) then
			s.vel = actualFlat
			reportCrash(s, loss)
			-- the jolt: the body and the driver's head are thrown
			local k = math.clamp(loss / 40, 0, 2) * DF.CrashJolt
			s.pitchVel -= k * 2
			s.rollVel += k * 3 * (if math.random() < 0.5 then -1 else 1)
			s.headVel += Vector3.new(0, 0, -k * 3)
			s.drifting = false
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
		s.brakeIn += (brake - s.brakeIn) * math.min(1, dt * 7)
		-- the automatic picks its gear by revs and how hard you press: flat out it holds each gear
		-- near the limiter, cruising it shifts early; pressing hard at low revs kicks down
		if not s.manual and s.shiftT <= 0 and not s.electric then
			if fwdSpeed > 1 and s.engineOn then
				local rev = speedFrac / gearHi(s.agear)
				if s.agear < GEARS and rev >= 0.5 + (s.cls.upshift - 0.5) * throttle then
					s.nextGear = s.agear + 1
					s.shiftT = if throttle > 0.5 then s.cls.shiftTime else s.cls.shiftTime * 1.6
				elseif s.agear > 1 and rev < (if throttle > 0.8 then 0.55 else 0.28) and speedFrac / gearHi(s.agear - 1) < 0.9 then
					s.nextGear = s.agear - 1
					s.shiftT = 0.12
				end
			elseif fwdSpeed <= 1 then
				s.agear = 1
			end
		end
		local gearNow = if s.manual then s.mgear else s.agear
		local engaged = s.engineOn and not s.clutch and s.shiftT <= 0 and gearNow ~= 0
		if engaged and gearNow > 0 and fwdSpeed > -2 then
			local rev = if s.electric then math.max(speedFrac, 0) else math.max(speedFrac, 0) / gearHi(gearNow)
			if throttle > 0 and speedFrac < 1 then -- at top speed the limiter holds it there
				local pull = if s.electric then evPull(math.max(speedFrac, 0)) else torqueCurve(math.max(rev, 0.3)) * gearMul(gearNow)
				a += s.accel * s.powerK * throttle * pull * (if s.launch > 0 then 1.15 else 1)
			elseif throttle == 0 and fwdSpeed > 2 then
				a -= 3 + 6 * math.min(rev, 1) -- engine braking (regen on an electric car)
			end
			if rev > 1.02 then
				a -= 30 * (rev - 1) -- shifted down too early: the engine holds the car back
			end
		elseif throttle > 0 and fwdSpeed < -2 then
			a += 140 * throttle -- braking out of reverse
		end
		-- brakes by class; a hard stop at speed pulses the anti-lock (keeps some steering)
		local brakeForce = s.cls.brake * s.brakeIn
		local abs = s.brakeIn > 0.8 and Config.spsToMph(math.abs(fwdSpeed)) > 12
		if abs then
			s.absT += dt
			brakeForce *= 1 - DF.AbsPulse * (0.5 + 0.5 * math.sin(s.absT * math.pi * 2 * DF.AbsHz))
			s.shake = math.max(s.shake, 0.05)
		end
		-- reverse: up to 40% of top speed (45 mph at most), pulling away hard (owner, 2026-10-29:
		-- "every car's reverse is too slow"; was a third, 35 mph at most, and a gentler pull)
		local reverseTop = Config.mphToSps(math.min(45, s.spec.TopSpeed * 0.4))
		local reversePull = math.max(s.accel * s.powerK * 1.5, 34)
		if s.manual then
			if engaged and gearNow < 0 and throttle > 0 and fwdSpeed > -reverseTop then
				a -= if fwdSpeed > 2 then 140 * throttle else reversePull * throttle
			end
			if fwdSpeed > 2 then
				a -= brakeForce
			elseif fwdSpeed < -2 then
				a += brakeForce
			end
		elseif fwdSpeed > 2 then
			a -= brakeForce
		elseif brake > 0 and throttle == 0 and fwdSpeed > -reverseTop and s.engineOn and not s.launchReady and s.stopT > 0.25 then
			-- automatic: hold the brake at a stop to reverse (not with the throttle down too). It waits
			-- a moment after stopping, so a hard stop doesn't bounce straight into reverse
			a -= reversePull * brake
		end
		if brake > 0 and math.abs(fwdSpeed) <= 2 then
			s.stopT += dt
		elseif brake == 0 or fwdSpeed > 2 then
			s.stopT = 0
		end
		if s.launchReady then
			-- launch control: the brakes hold the car dead still while the revs build
			a, fwdSpeed, latSpeed = 0, 0, 0
		end
		-- rolling resistance + aero drag (each car's own, so it tops out at its real top speed)
		local drag = 2 + s.dragC * fwdSpeed * fwdSpeed
		if handbrake then
			drag += 40
		end
		if math.abs(fwdSpeed) > 0.5 then
			a -= math.sign(fwdSpeed) * drag
		elseif throttle == 0 and brake == 0 then
			fwdSpeed = 0
		end
		-- nitro: extra pull, and past the car's own top speed up to NitroTop of it
		s.boosting = nitroHeld() and s.nitro > 0 and engaged and gearNow > 0 and throttle > 0.3 and fwdSpeed > 5
		if s.boosting then
			if speedFrac < 1 then
				a += DF.NitroAccel
			else
				a += drag + DF.NitroAccel * math.clamp((DF.NitroTop - speedFrac) / (DF.NitroTop - 1), 0, 1)
			end
			s.nitro = math.max(0, s.nitro - DF.NitroDrain * dt)
		end
		fwdSpeed += a * dt

		-- steering: speed-sensitive wheel angle, capped by lateral grip; the wheel turns slower and
		-- finer at speed
		local speedAbs = math.abs(fwdSpeed)
		local steerRate = (if math.abs(steerIn) > math.abs(s.steer) then 4.2 else 7) / (1 + speedAbs / DF.SteerSlowdown)
		s.steer += (steerIn - s.steer) * math.min(1, dt * steerRate)
		local maxAngle = math.rad(36) / (1 + (speedAbs / 70) ^ 1.3)
		local angle = s.steer * maxAngle
		local yawRate = fwdSpeed * math.tan(angle) / s.wheelbase
		-- real-life grip, not glued to the road; supercars gain downforce with speed
		local gripG = 2.2 + 2.0 * handling
		gripG *= 1 + (DF.Downforce[s.spec.Class] or 0) * math.clamp(speedAbs / s.topSpeed, 0, 1) ^ 2
		-- power on the rear (traction control off, or a clutch-drop launch) loosens it
		local loss = 0
		if not handbrake and (throttle > 0.5 or s.launch > 0) and s.drive ~= "FWD" then
			loss = (if s.tc then 0.05 else 0.4) * throttle * math.clamp(1 - math.abs(speedFrac) * 1.5, 0, 1)
			if s.launch > 0 then
				loss += 0.2
			end
			if s.drive == "AWD" then
				loss *= DF.AwdPowerOversteer -- all four wheels share the power
			end
			loss = math.min(loss, 0.7)
		end
		local cap = gripG * 28 / math.max(speedAbs, 1)
		-- the front tyres give up first on a heavy-nosed car at speed (understeer), more so when a
		-- front-drive car is flooring it through the corner; braking hard keeps most of the steering
		cap *= 1 - s.cls.understeer * math.clamp(speedAbs / s.topSpeed, 0, 1)
		if s.drive == "FWD" then
			cap *= 1 - DF.FwdUndersteer * throttle * math.clamp(speedAbs / (s.topSpeed * 0.5), 0, 1)
		end
		if abs then
			cap *= DF.AbsSteer
		end
		if handbrake then
			cap *= 1.7
		elseif not s.tc then
			cap *= 1 + DF.PowerOversteer * loss / 0.4 -- the rear steps out under power
		end
		yawRate = math.clamp(yawRate, -cap, cap)
		-- the car's turn follows the wheel with its weight: quick when parking, heavier at speed
		local response = (DF.YawResponse + DF.YawResponseHandling * handling) * (1 + 3 * math.max(0, 1 - speedAbs / 40)) / s.cls.inertia
		s.yawRate += (yawRate - s.yawRate) * math.min(1, dt * response)
		yawRate = s.yawRate
		s.yaw -= yawRate * dt

		-- drifting: a slide past DriftEnter at speed (or the handbrake thrown into a corner) is a
		-- drift; the nose is eased towards where the car is going (countersteer help), gently while
		-- you steer and firmly past the spin limit, so a drift can be held and linked
		local driftAngle = math.atan2(latSpeed, math.max(math.abs(fwdSpeed), 1))
		s.driftAngle = driftAngle
		local driftMph = Config.spsToMph(speedAbs)
		if not s.drifting then
			if driftMph > DF.DriftMinMph and fwdSpeed > 0 and (math.abs(driftAngle) > DF.DriftEnter or (handbrake and math.abs(s.steer) > 0.25)) then
				s.drifting = true
				s.driftCalm = 0
			end
		else
			s.driftCalm = if math.abs(driftAngle) < DF.DriftExit then s.driftCalm + dt else 0
			if s.driftCalm > DF.DriftHold or driftMph < DF.DriftMinMph * 0.7 or fwdSpeed <= 0 then
				s.drifting = false
			end
		end
		if s.drifting and speedAbs > 1 then
			local velYaw = yawFromLook((fwd * fwdSpeed + right * latSpeed).Unit)
			local d = (velYaw - s.yaw + math.pi) % (2 * math.pi) - math.pi
			s.yaw += d * DF.DriftAssist * (1 - 0.6 * math.abs(steerIn)) * dt
			if math.abs(d) > DF.DriftMaxAngle then
				s.yaw += (math.abs(d) - DF.DriftMaxAngle) * math.sign(d) * math.min(1, dt * 12)
			end
			s.nitro = math.min(1, s.nitro + DF.NitroFillDrift * dt)
		end

		-- the car turns, its momentum doesn't: the velocity stays where it was and the tyres pull
		-- it round as far as their grip allows (below), which is what lets a car slide and drift
		do
			local nf = forwardFromYaw(s.yaw)
			local nr = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
			local wv = fwd * fwdSpeed + right * latSpeed
			fwdSpeed, latSpeed = wv:Dot(nf), wv:Dot(nr)
			fwd, right = nf, nr
		end

		-- lateral grip (low with handbrake -> drift). Past the tyres' peak slip angle the grip falls
		-- away, so a slide keeps going until you catch it
		local grip = if handbrake then 1.4 else 4.5 + 5 * handling
		grip *= 1 - loss
		local slipAngle = math.atan2(math.abs(latSpeed), math.max(math.abs(fwdSpeed), 6))
		if slipAngle > DF.SlipPeak then
			grip *= 1 - (1 - DF.SlideGrip) * math.clamp((slipAngle - DF.SlipPeak) / DF.SlipPeak, 0, 1)
		end
		if s.drifting and not handbrake then
			-- in a held drift the side grip stays low while you stay on the throttle
			grip = math.min(grip, if throttle > 0.4 then DF.DriftGrip else DF.DriftGrip * 2.2)
		end
		-- the tyres pull the side speed out up to the sideways force they have (the same grip that
		-- caps the turn, a little more so a normal corner holds its line); a drift, the handbrake,
		-- wheelspin or a slide past the peak leaves them less, and the car slides
		do
			local gripK = grip / (4.5 + 5 * handling)
			local remove = gripG * 28 * 1.15 * gripK * dt
			latSpeed *= math.exp(-grip * 0.5 * dt)
			latSpeed = math.sign(latSpeed) * math.max(0, math.abs(latSpeed) - remove)
		end
		s.slip = math.abs(latSpeed) + (if handbrake and math.abs(fwdSpeed) > 20 then 25 else 0)
		if s.drifting then
			s.slip += 30 * math.clamp(math.abs(driftAngle) / 0.5, 0, 1)
		end
		-- tyre noise and smoke: a real launch (traction control off, flooring it from a stop, or a
		-- clutch drop) for a moment only, a hard stop at speed, and turning hard when fast
		local sf = math.abs(fwdSpeed) / s.topSpeed
		if not s.tc and throttle > 0.8 and fwdSpeed >= -1 and sf < 0.06 then
			s.slip += 30 * throttle * (1 - sf / 0.06)
		end
		if s.launch > 0 then
			s.slip += 25 * s.launch / 0.8
		end
		if s.brakeIn > 0.85 and fwdSpeed > 70 then
			s.slip += 14 * s.brakeIn
		end
		if math.abs(s.steer) > 0.35 and sf > 0.4 then
			s.slip += 60 * math.abs(s.steer) * (sf - 0.4)
		end
		-- a loud tyre cry pulling away hard and on a launch (sound only: no smoke unless they slip)
		local cry = 0
		if engaged and gearNow > 0 and throttle > 0.8 and fwdSpeed >= -1 and sf < 0.12 then
			cry = (1 - sf / 0.12) * (if s.tc then 0.75 else 1)
		end
		if s.launch > 0 then
			cry = 1
		end
		s.chirp = math.max(0, s.chirp - dt)
		if s.chirp > 0 then
			cry = math.max(cry, 0.8)
		end
		s.screech = cry

		-- body on its springs: leans out in turns, dives under braking, squats pulling away, and
		-- rocks a little when a shift cuts and returns the drive
		local latG = math.clamp(fwdSpeed * yawRate / 196.2, -1.5, 1.5)
		local lonG = math.clamp(a / 196.2, -1.5, 1.5)
		s.latG, s.lonG = latG, lonG
		-- (and a fine shimmy from the road surface at speed)
		local tex = DF.RoadTexture * math.clamp(speedAbs / s.topSpeed, 0, 1)
		local tnow = os.clock()
		local texP = tex * math.noise(tnow * 9, 0, 7)
		local texR = tex * math.noise(0, tnow * 11, 8)
		s.pitchVel += ((math.rad(DF.BodyPitch) * s.cls.pitch * lonG + texP - s.pitch) * 70 - s.pitchVel * 10) * dt
		s.pitch += s.pitchVel * dt
		s.rollVel += ((math.rad(DF.BodyRoll) * s.cls.roll * latG + texR - s.roll) * 90 - s.rollVel * 12) * dt
		s.roll += s.rollVel * dt

		local newFwd = forwardFromYaw(s.yaw)
		local newRight = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
		s.vel = newFwd * fwdSpeed + newRight * latSpeed
		s.lv.MaxForce = root.AssemblyMass * 400
		s.lv.MaxAxesForce = Vector3.new(root.AssemblyMass * 400, root.AssemblyMass * 320, root.AssemblyMass * 400)
	else
		s.lv.MaxForce = root.AssemblyMass * 8
		s.steer += (steerIn - s.steer) * math.min(1, dt * 6)
		s.yawRate *= math.exp(-dt * 2)
		s.boosting = false
		-- in the air the nose follows the arc (up off a ramp, down to land)
		local arc = math.clamp(math.atan2(actual.Y, math.max(actualFlat.Magnitude, 1)) * 0.6, -0.35, 0.35)
		s.pitch += (arc - s.pitch) * math.min(1, dt * 2)
		s.pitchVel *= math.exp(-dt * 4)
	end

	-- scraping a wall: sparks, speed bleeding off, a buzz in the camera
	if s.grounded and Config.spsToMph(s.vel.Magnitude) > DF.ScrapeMinMph then
		local side = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
		for _, sd in { 1, -1 } do
			local w = workspace:Raycast(root.Position, side * sd * (s.width / 2 + 0.4), rayParams)
			if w and w.Instance.CanCollide and math.abs(w.Normal.Y) < 0.5 then
				s.vel *= 1 - DF.ScrapeDrag * dt
				s.shake = math.max(s.shake, 0.15)
				sparks(w.Position, w.Normal, 3 + math.floor(Config.spsToMph(s.vel.Magnitude) / 25))
			end
		end
	end

	-- nitro fills from driving fast (not while it's being used)
	local mphNow = Config.spsToMph(s.vel.Magnitude)
	if not s.boosting and mphNow > 60 then
		s.nitro = math.min(1, s.nitro + DF.NitroFillSpeed * math.clamp((mphNow - 60) / 80, 0, 1) * dt)
	end

	-- skid marks under the rear tyres while they slide
	if s.grounded and hit and (s.slip > 28 or s.drifting) and mphNow > 8 then
		s.skidT += dt
		if s.skidT > 0.05 then
			s.skidT = 0
			local y = hit.Position.Y + 0.03
			local cf = CFrame.new(root.Position) * CFrame.Angles(0, s.yaw, 0)
			local back = s.wheelbase * 0.5
			local l = cf:PointToWorldSpace(Vector3.new(-(s.width / 2 - 1.1), 0, back))
			local r = cf:PointToWorldSpace(Vector3.new(s.width / 2 - 1.1, 0, back))
			l = Vector3.new(l.X, y, l.Z)
			r = Vector3.new(r.X, y, r.Z)
			if s.skidL then
				skidMark(s.skidL, l)
			end
			if s.skidR then
				skidMark(s.skidR, r)
			end
			s.skidL, s.skidR = l, r
		end
	else
		s.skidL, s.skidR = nil, nil
	end

	-- out of the world
	if root.Position.Y < -40 then
		Driving.reset()
		return
	end

	if s.vyTarget and s.grounded then
		-- on its wheels: the suspension holds the vertical speed too, following the road's climb
		local nrm = s.groundUp
		local climb = if nrm.Y > 0.5 then -(nrm.X * s.vel.X + nrm.Z * s.vel.Z) / nrm.Y else 0
		s.lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		s.lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		s.lv.VectorVelocity = Vector3.new(s.vel.X, climb + s.vyTarget, s.vel.Z)
	else
		s.lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		s.lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
		s.lv.PlaneVelocity = Vector2.new(s.vel.X, s.vel.Z)
	end
	do
		local look = CFrame.Angles(0, s.yaw, 0).LookVector
		local n = s.groundUp
		local along = (look - n * look:Dot(n)).Unit
		s.ao.CFrame = CFrame.fromMatrix(Vector3.zero, along:Cross(n).Unit, n, -along) * CFrame.Angles(s.pitch, 0, s.roll)
	end
	s.lastCommand = s.vel

	-- gears / rpm (cosmetic)
	local fs = s.vel:Dot(forwardFromYaw(s.yaw))
	local frac = math.clamp(math.abs(fs) / s.topSpeed, 0, 1)
	local prevGear = s.gear
	local function manualName(): string
		return if s.mgear < 0 then "R" elseif s.mgear == 0 then "N" else tostring(s.mgear)
	end
	-- a shift: the drive comes back with a kick
	if s.shiftT > 0 then
		s.shiftT -= dt
		if s.shiftT <= 0 then
			if not s.manual then
				s.agear = s.nextGear
			end
			s.pitchVel += math.rad(16) * throttle
			s.headVel += Vector3.new(0, 0, 1.6 * throttle)
			-- flat out near the limiter: the view punches wider for a moment
			if throttle > 0.8 and s.rpm > 0.8 then
				s.fovPunch += Config.DrivingFeel.ShiftPunchFov
				s.blurPulse = math.max(s.blurPulse, Config.DrivingFeel.ShiftBlur)
			end
			local g = if s.manual then s.mgear else s.agear
			if throttle > 0.8 and g >= 1 and g <= 3 then
				s.chirp = 0.25 -- the tyres chirp as the drive slams back in
			end
		end
	end
	if not s.engineOn then
		s.gear = if s.manual then manualName() else "N"
		s.rpm = if s.cranking > 0 then 0.12 else 0
		s.freeRpm = s.rpm
	else
		local free = s.manual and (s.mgear == 0 or s.clutch)
		s.freeRpm += (0.12 + 0.86 * throttle - s.freeRpm) * math.min(1, dt * 6)
		local target
		if s.manual then
			s.gear = manualName()
		elseif fs < -1 then
			s.gear = "R"
		elseif math.abs(fs) < 1 and throttle == 0 then
			s.gear = if s.electric then "D" else "N"
		else
			s.gear = if s.electric then "D" else tostring(s.agear)
		end
		if free then
			target = s.freeRpm
		elseif fs < -1 or (s.manual and s.mgear < 0) then
			target = math.clamp(0.12 + 0.8 * -fs / Config.mphToSps(math.min(35, s.spec.TopSpeed * 0.33)), 0.12, 1)
		elseif s.electric then
			target = 0.1 + 0.85 * frac -- the motor's speed: no gears, no limiter
		elseif s.launchReady then
			target = 0.62 -- launch control holds the revs, steady
			s.rpm = target
		elseif s.gear == "N" then
			target = 0.12
		else
			-- during an automatic shift the revs already fall to the next gear
			local g = if s.manual then s.mgear elseif s.shiftT > 0 then s.nextGear else s.agear
			local rev = frac / gearHi(g)
			target = 0.12 + 0.88 * rev
			if rev < 0.35 and throttle > 0 then
				target = math.max(target, 0.2 + 0.25 * throttle) -- pulling away: the clutch slips
			end
			target = math.clamp(target, 0.12, 1.02)
		end
		s.rpm += (target - s.rpm) * math.min(1, dt * s.cls.revRate)
		if not free then
			s.freeRpm = s.rpm
		end
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
	-- each wheel moves up and down on its spring to stay on the road (its travel smoothed a touch)
	local sp = s.susp
	for _, c in s.corners do
		local want = math.clamp(-c.gap, -sp.droop, sp.bump)
		c.travel += (want - c.travel) * math.min(1, dt * 30)
		local m = c.motor
		local lift = CFrame.new(m.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0))
		local klift = if c.knuckle then CFrame.new(c.knuckle.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0)) else CFrame.new()
		if m:GetAttribute("Front") then
			m.Transform = lift * CFrame.Angles(0, wheelAngle, 0) * CFrame.Angles(s.wheelSpin, 0, 0)
			-- brake caliper rides on a knuckle that steers but doesn't spin
			if c.knuckle then
				c.knuckle.Transform = klift * CFrame.Angles(0, wheelAngle, 0)
			end
		else
			m.Transform = lift * CFrame.Angles(s.wheelSpin, 0, 0)
			if c.knuckle then
				c.knuckle.Transform = klift
			end
		end
	end

	-- steering wheel + hands + IK arms. The wheel turns much further at parking speeds than at
	-- speed (as the road wheels do), with small corrections on the straight; the hands follow and
	-- re-grip (cross over) on big turns
	local DF = Config.DrivingFeel
	local mphAbs = Config.spsToMph(math.abs(fwdSpeed))
	local slowK = math.clamp(1 - mphAbs / DF.LockFadeMph, 0, 1)
	local lock = s.steerMaxRot + math.max(0, math.rad(DF.WheelLockSlow) - s.steerMaxRot) * slowK
	local wobble = math.rad(DF.WheelWobble) * math.noise(os.clock() * 0.9, 3.3, 0) * math.clamp((mphAbs - 30) / 60, 0, 1)
	local rot = -s.steer * lock + wobble
	if s.steerMotor then
		s.steerMotor.Transform = CFrame.Angles(0, 0, rot)
	end
	local reach = math.rad(DF.HandReach)
	local grip = rot - math.pi * math.floor(rot / math.pi + 0.5) -- the nearest half turn: hands swap over
	if math.abs(rot) <= reach then
		grip = rot
	end
	if math.abs(grip - s.handRot) > math.pi * 0.6 then
		s.handRot = grip -- a re-grip: let go and take hold again
	else
		s.handRot += (grip - s.handRot) * math.min(1, dt * 18)
	end
	pcall(function()
		if s.steerMount and #s.localSteer > 0 then
			local wheelWorld = root.CFrame * s.steerMount * CFrame.Angles(0, 0, rot)
			for _, ls in s.localSteer do
				ls.part.CFrame = wheelWorld * ls.offset
			end
		end
		if s.steerMount and #s.localArms > 0 then
			local wheelCF = s.steerMount * CFrame.Angles(0, 0, s.handRot)
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
					-- one straight arm, shoulder to hand. In first person only the forearm and hand
					-- show (owner, 2026-10-17: the whole arm came past the camera as a big slab;
					-- 2026-10-22: the hands on the wheel disappeared when it was hidden)
					local from = arm.shoulder
					if Driving.cameraMode == "Interior" then
						from = handPos + (arm.shoulder - handPos) * 0.45
					end
					local len = (handPos - from).Magnitude
					if math.abs(arm.upper.Size.Y - len) > 0.02 then
						arm.upper.Size = Vector3.new(arm.upper.Size.X, len, arm.upper.Size.Z)
					end
					arm.upper.CFrame = root.CFrame * CFrame.lookAt((from + handPos) / 2, handPos) * arm.rot
				end
				-- jointed arms: in first person the upper arm (next to the camera) hides, the
				-- forearm and glove stay on the wheel
				arm.upper.LocalTransparencyModifier = if fore and Driving.cameraMode == "Interior" then 1 else 0
				if fore then
					fore.LocalTransparencyModifier = 0
				end
				if arm.glove then
					(arm.glove :: BasePart).LocalTransparencyModifier = 0
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
		if #s.partNeedles > 0 or #s.guiNeedles > 0 or #s.guiTexts > 0 or #s.dialNeedles > 0 then
			local k = 1 - math.exp(-dt * 10) -- needles swing, they don't snap
			s.speedShown += (math.clamp(mph / 160, 0, 1) - s.speedShown) * k
			s.mphShown += (mph - s.mphShown) * k
			s.rpmShown += (math.clamp(s.rpm, 0, 1) - s.rpmShown) * k
			local sweep = 0
			if s.dialSweep then
				local t = (os.clock() - s.dialSweep) / 1.6
				if t < 1 then
					sweep = math.sin(t * math.pi)
				else
					s.dialSweep = nil
				end
			end
			for _, n in s.dialNeedles do
				local pts = n.scale
				local top = pts[#pts][1]
				-- the rev counter reads 8000 at our limiter (as the cars' own read-outs do)
				local v = if n.kind == "speed" then (if n.unit == "kmh" then s.mphShown * 1.609 else s.mphShown) else s.rpmShown * 8000
				v = math.max(v, sweep * top)
				local ang = pts[#pts][2]
				for i = 1, #pts - 1 do
					local a, b = pts[i], pts[i + 1]
					if v <= b[1] then
						ang = a[2] + (b[2] - a[2]) * math.clamp((v - a[1]) / (b[1] - a[1]), 0, 1)
						break
					end
				end
				n.gui.Rotation = ang
			end
			for _, n in s.partNeedles do
				local v = if n.kind == "speed" then s.speedShown else s.rpmShown
				-- the pivot's +Z looks at the driver: a negative turn is clockwise as the driver sees it
				n.part.CFrame = root.CFrame * n.pivot * CFrame.Angles(0, 0, -math.rad(v * 240)) * n.offset
			end
			for _, tl in s.guiTexts do
				tl.label.Text = if tl.kind == "Speed" then tostring(math.floor((if (tl.unit or Driving.units) == "kmh" then mph * 1.609 else mph) + 0.5)) elseif tl.kind == "RPM" then tostring(math.floor(s.rpm * 80) * 100) else s.gear
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

	-- the rush: how fast it feels, by real speed (so a quick car at 150 feels it whatever its top)
	local mphNow = Config.spsToMph(math.abs(fwdSpeed))
	local rush = math.clamp((mphNow - DF.RushFrom) / (DF.RushTo - DF.RushFrom), 0, 1) ^ 1.2
	local fx = math.max(speedFrac, rush)

	-- engine / wind / tyre audio (the wind by the rush too)
	s.engine:update(s.rpm, s.throttle, fx, s.slip, nil, s.screech)
	if s.roar then
		local k = if s.grounded then math.clamp(mphNow / 180, 0, 1) ^ 1.3 else 0
		s.roar.Volume += (DF.RoadRoar * k - s.roar.Volume) * math.min(1, dt * 4)
		s.roar.PlaybackSpeed = 0.35 + 0.45 * k
	end
	-- smoke with the squeal (same curve as the sound); launches smoke the rear tyres most
	local squeal = math.clamp((s.slip - 8) / 40, 0, 1)
	local q = fxQuality()
	for _, sm in s.smoke do
		local rate = if squeal > 0.05 then squeal * (if sm.rear then 70 else 35) else 0
		-- a drift smokes the rear tyres hard
		if s.drifting and sm.rear then
			rate = math.max(rate, 55 * math.clamp(math.abs(s.driftAngle) / 0.4, 0.4, 1))
		end
		sm.emitter.Rate = rate * q
	end
	fadeSkids(dt)

	-- nitro: blue flames out of the pipes, the view kicks wide and blurs, a whoosh as it lights
	if s.boosting then
		if not s.boostWas then
			for _, e in s.flames do
				e.Color = NITRO_FLAME
			end
			if s.flameLight then
				s.flameLight.Color = Color3.fromRGB(90, 140, 255)
			end
			Audio.passBy(1)
			s.camLag += 2
			s.shake = math.max(s.shake, 0.3)
		end
		for _, e in s.flames do
			e:Emit(if q > 0.7 then 2 else 1)
		end
		s.flameGlow = math.max(s.flameGlow, 3)
		s.fovPunch = math.max(s.fovPunch, Config.DrivingFeel.NitroFov)
		s.blurPulse = math.max(s.blurPulse, Config.DrivingFeel.NitroBlur)
	elseif s.boostWas then
		for i, e in s.flames do
			e.Color = s.flameColors[i] or e.Color
		end
		if s.flameLight then
			s.flameLight.Color = Color3.fromRGB(130, 160, 255)
		end
	end
	s.boostWas = s.boosting
	if nitroFill then
		nitroFill.Size = UDim2.fromScale(math.clamp(s.nitro, 0, 1), 1)
		nitroFill.BackgroundTransparency = if s.boosting then 0 else 0.15
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

	if Driving.cameraHold then
		return
	end
	-- camera (owner, 2026-10-29: "like the video"). The speed comes from the camera's lag, distance,
	-- sway, shake and blur; the FOV only moves a little outside and never in the cockpit. Settings:
	-- Driving.camFx (shake, head movement, motion blur, outside FOV).
	local C = Config.Camera
	local cfx = Driving.camFx
	local mode = Driving.cameraMode
	local interior = mode == "Interior"
	s.shake = math.max(0, s.shake - dt * 2.5)
	local t = os.clock()
	-- moments of extra speed: launches, flat-out shifts and close passes punch the view
	s.fovPunch *= math.exp(-dt * 3.5)
	s.blurPulse = math.max(0, s.blurPulse - dt * 14)
	local speedShake = 0.012 * math.min(fx * 6, 1) + math.max(0, fx - 0.3) * 0.16
	local shakeAmt = (speedShake + s.shake * 0.5) * cfx.shake
	local shakeOffset = Vector3.new(math.noise(t * 23, 0, 1), math.noise(0, t * 21, 2), 0) * shakeAmt
	local function setBlur(size: number)
		if blur then
			blur.Size = if cfx.blur then size else 0
		end
	end

	-- the g-forces on the outside cameras: the camera slides in a corner (the car moves out in the
	-- frame) and rolls with it, tips with the pull and the braking, lags behind a launch and comes
	-- closer braking. All smoothed, back to centre in about half a second.
	local G = C.Drama
	local IC = C.Immersive
	local gk = math.min(1, dt * G.Response)
	local latG = math.clamp(s.latG, -1.2, 1.2)
	local lonG = math.clamp(s.lonG, -1.2, 1.2)
	local yawRate = s.steer * math.min(math.abs(fwdSpeed), 60) / 60
	s.camLag += ((lonG * IC.Lag) - s.camLag) * math.min(1, dt * IC.LagResponse)
	s.camSwing += ((yawRate * IC.Swing) - s.camSwing) * math.min(1, dt * 3.5)
	local swingFrac = if IC.Swing > 0 then math.clamp(s.camSwing / IC.Swing, -1, 1) else 0
	s.camSide += (swingFrac * (G.Side + G.SideSpeed * fx) * math.min(1, fx * 3) - s.camSide) * gk
	s.camRoll += (math.clamp(-latG * G.Roll, -G.MaxRoll, G.MaxRoll) - s.camRoll) * gk
	s.camPitch += (lonG * G.Pitch - s.camPitch) * gk
	s.gFov += ((if lonG > 0 then lonG * G.AccelFov else lonG * G.BrakeFov) - s.gFov) * gk

	-- high-speed sway (every camera): a slow roll and float from smooth noise, a fine vibration
	-- on top, both growing with speed
	local HS = C.Shake
	local hs = math.clamp((mphNow - HS.FromMph) / (HS.ToMph - HS.FromMph), 0, 1) * cfx.shake
	local sway = CFrame.identity
	if hs > 0 then
		local function n(a: number, b: number): number
			return math.clamp(math.noise(a, b, 0.5) * 2, -1, 1)
		end
		local float = Vector3.new(0, HS.Bob * hs * n(t * HS.Rate, 21.7), 0)
		local buzz = Vector3.new(n(t * 37, 5.1), n(5.3, t * 41), 0) * HS.Buzz * hs
		sway = CFrame.new(float + buzz) * CFrame.Angles(0, 0, HS.Roll * hs * n(t * HS.Rate, 13.3))
	end

	local targetFov
	local rootCF = root.CFrame
	if interior then
		targetFov = C.InteriorFov + C.MaxFovBoost * C.InteriorFovBoost * speedFrac ^ 1.5
		local H = C.Head
		local hk = cfx.head
		local mouseLook = 0
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			local vp = camera.ViewportSize
			local mp = UserInputService:GetMouseLocation()
			mouseLook = -((mp.X / vp.X) - 0.5) * math.rad(160)
		end
		local lookInto = -s.steer * math.rad(H.LookInto) * hk
		local eyeCF = rootCF * CFrame.new(s.eye) * CFrame.Angles(0, lookInto + mouseLook, 0) * CFrame.Angles(math.rad(-4), 0, 0)
		-- the driver's head on a spring, from the real g: slides to the outside of a turn and tilts
		-- the horizon, dips forward and down braking, is pushed back pulling away; a crash jolts it
		local brakeK = math.clamp(-lonG / 0.8, 0, 1)
		local pullK = math.clamp(lonG / 0.8, 0, 1)
		local headTarget = Vector3.new(-latG * H.Lean, -brakeK * H.Brake * 0.5, pullK * H.Launch - brakeK * H.Brake) * hk
		local tiltTarget = Vector2.new(-brakeK * H.BrakePitch + pullK * 0.02, math.clamp(-latG * H.TiltPerG, -H.Tilt, H.Tilt)) * hk
		local w = H.Response
		local step = math.min(dt, 1 / 30)
		s.headVel += ((headTarget - s.headPos) * (w * w) - s.headVel * (2 * H.Bounce * w)) * step
		s.headPos += s.headVel * step
		s.headTiltVel += ((tiltTarget - s.headTilt) * (w * w) - s.headTiltVel * (2 * H.Bounce * w)) * step
		s.headTilt += s.headTiltVel * step
		-- breathing when slow or parked: a tiny slow rise and fall, a little uneven
		local slow = math.clamp(1 - mphNow / H.BreathFadeMph, 0, 1)
		local breath = H.Breath * slow * hk * math.sin(t * 2 * math.pi / H.BreathPeriod + math.noise(t * 0.15, 7.7, 0) * 1.5) * (0.85 + 0.3 * math.noise(t * 0.1, 9.9, 0))
		local jolt = Vector3.new(math.noise(t * 23, 0, 1), math.noise(0, t * 21, 2), 0) * (s.shake * 0.15 + DF.CabinBuzz * rush) * cfx.shake
		camera.CFrame = eyeCF * CFrame.new(s.headPos + jolt + Vector3.new(0, breath, 0)) * CFrame.Angles(s.headTilt.X, 0, s.headTilt.Y)
		setBlur(0)
	elseif mode == "Immersive" or mode == "Low" then
		-- low and close behind the car, like a racing game's near camera; "Low" sits at wheel-top
		-- height off to one side, closer, with more blur
		local low = mode == "Low"
		local LC = C.Low
		targetFov = cfx.fov + (if low then (LC.Fov - IC.Fov) + LC.FovBoost * fx ^ 1.25 else IC.FovBoost * fx ^ 1.25)
		local back = if low then LC.Distance + s.camLag * 0.6 + fx * LC.SpeedPull else IC.Distance + s.camLag + fx * IC.SpeedPull
		local up = if low then LC.Height else IC.Height - fx * 0.5
		local side = if low then -LC.Side + s.camSide * 0.5 else s.camSide
		local base = CFrame.new(root.Position) * CFrame.Angles(0, s.yaw, 0) -- level with the road, not the body roll
		local camPos = (base * CFrame.Angles(0, s.camSwing, 0) * CFrame.new(side, up, back)).Position
		-- road buzz: fine fast shake that grows with speed, plus a slow float
		s.camBob += dt * (6 + fx * 30)
		local buzz = (0.015 + fx ^ 2 * IC.Buzz + s.shake * 0.4) * cfx.shake
		local shake = Vector3.new(math.noise(t * 31, 0, 3), math.noise(0, t * 29, 4), 0) * buzz
			+ Vector3.new(0, math.sin(s.camBob) * 0.03 * fx * cfx.shake, 0)
		local ahead = if low then CFrame.new(-LC.Side * 0.3, LC.LookHeight, -LC.LookAhead) else CFrame.new(0, IC.LookHeight, -IC.LookAhead)
		local lookAt = (base * CFrame.Angles(0, -s.camSwing * 0.6, 0) * ahead).Position
		s.camPos = camPos
		s.camLook = lookAt
		camera.CFrame = CFrame.lookAt(camPos + shake, lookAt + shake * 0.5) * CFrame.Angles(s.camPitch, 0, s.camRoll)
		local blurMax = if low then LC.Blur else IC.Blur
		local blurFrom = if low then LC.BlurFrom else IC.BlurFrom
		setBlur(math.max(blurMax * math.max(0, fx - blurFrom) ^ 1.3, s.blurPulse))
	else
		targetFov = cfx.fov + (C.ChaseFov - IC.Fov) + C.MaxFovBoost * fx ^ 1.4
		-- follow the direction of travel a little when drifting
		local velDir = if s.vel.Magnitude > 5 then s.vel.Unit else fwd
		if s.vel:Dot(fwd) < -5 then
			velDir = fwd
		end
		local camDir = (fwd * 0.75 + velDir * 0.25).Unit
		local dist = C.ChaseDistance + speedFrac * 4 + s.camLag * 0.6
		local right = camDir:Cross(Vector3.yAxis)
		local desired = root.Position - camDir * dist + right * s.camSide + Vector3.new(0, C.ChaseHeight - speedFrac * 0.8, 0)
		local alpha = 1 - math.exp(-dt * 10)
		s.camPos = s.camPos:Lerp(desired, alpha)
		-- never let the camera lag too far behind at hyper speeds
		local offset = s.camPos - root.Position
		if offset.Magnitude > dist * 1.6 then
			s.camPos = root.Position + offset.Unit * dist * 1.6
		end
		local look = root.Position + fwd * 10 + Vector3.new(0, 1.8, 0)
		s.camLook = s.camLook:Lerp(look, 1 - math.exp(-dt * 14))
		camera.CFrame = CFrame.lookAt(s.camPos + shakeOffset, s.camLook) * CFrame.Angles(s.camPitch * 0.7, 0, s.camRoll * 0.8)
		setBlur(math.max(3.5 * math.max(0, fx - 0.45) ^ 1.5, s.blurPulse))
	end
	camera.CFrame *= sway
	camera.Focus = CFrame.new(root.Position) -- (Playbook: every frame, or shadows and detail break)
	s.fov += (targetFov - s.fov) * math.min(1, dt * 4)
	-- (the cockpit keeps one FOV: the owner wants that view steady and readable)
	camera.FieldOfView = s.fov + (if interior then 0 else s.fovPunch + s.gFov)
	UI.setSpeedLines(if interior then 0 else math.max(0, fx - 0.3) / 0.7)
	setVignette(DF.Vignette * math.max(0, fx - 0.25) / 0.75 * (if interior then 0.5 else 1))
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
		s.manual = Driving.gearbox == "Manual" and not s.electric
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

	RunService.Heartbeat:Connect(updateOthers)

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
