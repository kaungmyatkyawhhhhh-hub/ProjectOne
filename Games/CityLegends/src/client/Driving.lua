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
	Car controls (keyboard): F start / stop the engine, Q / E shift down / up (manual /
	sequential only: M or Settings switches; in automatic Q / E just say so), M automatic / sequential,
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
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local avatarDesc: HumanoidDescription? = nil -- for the driver's arms

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CarPhysics = require(Shared:WaitForChild("CarPhysics"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))

local Traffic = require(script.Parent:WaitForChild("Traffic"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local DashGauges = require(script.Parent:WaitForChild("DashGauges"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local CarLamps = require(script.Parent:WaitForChild("CarLamps"))
local CameraLook = require(script.Parent:WaitForChild("CameraLook"))
local lookRay = RaycastParams.new() -- (the outside camera swung round must not go through a wall)
lookRay.FilterType = Enum.RaycastFilterType.Exclude
lookRay.RespectCanCollide = true

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
Driving.menuHold = false -- the main menu is open: the car is braked and held (MainMenu)
Driving.nitroBlocked = false -- a race marked "no nitrous" (Activities)
Driving.wet = 0 -- how wet the road is, 0..1 (Weather sets it): less grip, longer stops
Driving.assist = 1 -- driving assists (Settings): 0 off, 0.5 low, 1 normal
Driving.smoke = 1 -- tyre smoke (Settings): 0 off, 0.5 low, 1 high
Driving.marks = true -- tyre marks (Settings)
-- (2026-11-08) driver aids (Settings > DRIVING): traction control and stability control 0 off / 1 sport / 2 on, ABS on or
-- off, the countersteer help (0 = "Pro"). New players: all on
Driving.tcMode = 2
Driving.escMode = 2
Driving.abs = true
Driving.help = 1
Driving.loadHold = false -- the map round the car is still loading (Main.client's waitForMap): held too
Driving.cameraHold = false -- another screen (Legends Customs) moves the camera for now
Driving.workshopOpen = false -- the workshop has the camera (over Legends Customs too)
Driving.gearbox = "Auto" -- "Auto" | "Manual" (Settings or M; Q / E shift only in manual)
Driving.units = "mph" -- "mph" | "kmh" (Settings): the HUD and every cluster
Driving.onGearboxChanged = nil :: ((string) -> ())? -- Q / E or M changed the gearbox
local GEARS = 7 -- (the old model's gearbox: with the two-axle model each car has its own, CarPhysics)
local curP: any = nil -- the driven car's CarPhysics numbers (nil: the old model)
local function gearsNow(): number
	return if curP then curP.gears else GEARS
end
-- a short buzz on phones (hard hits, kerbs, gear shifts), where the device can
local HapticService = game:GetService("HapticService")
local buzzUntil = 0
local function buzz(k: number, t: number)
	if not UI.isTouch then
		return
	end
	pcall(function()
		if HapticService:IsVibrationSupported(Enum.UserInputType.Touch) and HapticService:IsMotorSupported(Enum.UserInputType.Touch, Enum.VibrationMotor.Large) then
			HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, math.clamp(k, 0, 1))
			buzzUntil = os.clock() + t
			task.delay(t, function()
				if os.clock() >= buzzUntil - 0.01 then
					pcall(function()
						HapticService:SetMotor(Enum.UserInputType.Touch, Enum.VibrationMotor.Large, 0)
					end)
				end
			end)
		end
	end)
end
-- keyboard throttle (on / off keys): eased in, so the car isn't kicked from nothing to full
local keyThrottle = false

type Corner = { motor: Motor6D, knuckle: Motor6D?, at: Vector3, rest: number, front: boolean, left: boolean, gap: number, travel: number, hit: Vector3?, radius: number, spin: number, mat: Enum.Material?, partName: string?, nrm: Vector3?, skid: Vector3? }

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
	-- (2026-11-07) towing: the weight on the hitch, the top speed with it, what the trailer's lamps were last told, the camera's pull and turn
	towKg: number?,
	towTop: number?,
	towBrake: boolean?,
	towRev: boolean?,
	towPull: number,
	towTurn: number,
	applyTune: () -> (),
	-- (2026-11-08) the two-axle model (CarPhysics): the car's numbers, its brakes, last step's acceleration and result,
	-- each axle's grip under it; the keyboard throttle's ease; the kit-v2 wheels (blur, spokes, brake discs) and the
	-- brakes' heat; the steering sent to the other players; the rev limiter
	axle: any?,
	brakeAxle: number,
	axAxle: number,
	axleOut: any?,
	gripF: number,
	gripR: number,
	thrRamp: number,
	kit: { [Corner]: { blur: { BasePart }, spokes: { BasePart }, discs: { SurfaceAppearance }, shown: number } },
	brakeHeat: number,
	glowShown: number,
	steerSent: number,
	steerSendT: number,
	engSent: number, -- (2026-11-09) the engine state last sent to the other players
	thrSent: number,
	gearSent: number,
	onSent: boolean,
	limitT: number,
	smokeF: number,
	smokeR: number,
	tcFlashT: number, -- the TC light flashes while traction / stability control is working
	-- (2026-11-07) cruise control: the set speed, the pedal taps, the regulator; what the car's health does to it;
	-- out of fuel; what the driver's game tells the server next (Driving.takeReport)
	cruise: number?,
	cruiseUp: number,
	cruiseDown: number,
	cruiseI: number,
	cruiseGapT: number,
	care: { power: number, grip: number, brake: number, handling: number, limp: boolean, misfire: boolean, empty: boolean }?,
	capTop: number?,
	gripK: number,
	sputter: number,
	misT: number,
	report: { red: number, launch: number, drift: number, burn: number, hard: number, thr: number, n: number, hits: { any }, rash: number? },
	redHold: number,
	scrapeT: { [number]: number },
	scrapeU: { [number]: number },
	rashT: number,
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
	-- (scale: our converted cars' own needles, CarSkin.OWN_NEEDLES: reading -> degrees, from the
	-- needle's modelled angle `rest`)
	partNeedles: { { part: BasePart, kind: string, pivot: CFrame, offset: CFrame, scale: { { number } }?, rest: number, unit: string } },
	powerShown: number, -- throttle x revs, eased (a power gauge)
	warmT: number?, -- when the engine started (an oil gauge warms up)
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
	lamps: boolean, -- a model with its own working lamps (CarLamps): no box-car lights on it
	beam: string, -- "off" | "drl" | "low" | "high" (lamps only)
	tails: { BasePart }, -- tail lamps (TailLight parts): dim with the lights on, bright when braking
	rearGlow: { PointLight },
	tailBrake: boolean?,
	dashPanel: BasePart?,
	-- drivetrain feel
	agear: number, -- the automatic gearbox's gear (1..GEARS)
	shiftT: number, -- seconds left of a shift: no drive while the gear changes
	soundGear: number?, -- the gear the shift sounds last heard (the one the revs follow)
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
	launchClean: number, -- (2026-11-10) seconds left of a launch-control start with no tyre smoke
	burnArmed: boolean, -- a launch-control start with the throttle still held: the brake now makes a burnout
	burnout: boolean, -- brake + throttle after a launch-control start: the driven tyres spin and smoke on the spot
	driftTyres: boolean, -- drift tyres fitted (with traction control off the rear lets go freely only on these)
	weightK: number, -- the car's kerb weight over Config.DrivingFeel.WeightRef (CarStats)
	brakeK: number, -- the brake parts' extra braking force (1 = stock; CarStats.tuneOf)
	-- (2026-11-06, the workshop) what the parts and the TUNE tab's settings do to the feel
	shiftK: number, -- shift time
	steerK: number, -- wheel lock
	driftK: number, -- how easily the tyres let go
	launchK: number, -- the launch's pull
	launchRev: number, -- launch control's revs, 0..1 of the redline
	bumpK: number, -- how hard a bump kicks
	downK: number, -- wing downforce added
	rallyK: number, -- grip on dirt and grass
	rideDrop: number, -- how far the body sits under its stock height (studs)
	rideWant: number,
	airRide: boolean,
	popTune: string?, -- the ECU's map: pop, crackle, burble, antilag
	popLoud: boolean, -- a straight pipe, muffler delete or decat
	popGap: number, -- seconds between pops
	nitroOn: boolean, -- a bottle is fitted
	nitroDrain: number,
	engineLayout: string?, -- a swapped engine's layout
	lonGReal: number, -- pull-away (+) / braking (-) in real g, last frame
	surface: string?, -- "hard" | "loose" under the car
	smokeDust: boolean?,
	smokeSent: number?,
	smokeSendT: number?,
	tunnelCheck: number?, -- seconds to the next tunnel check
	wind: number?, -- the wind blur's strength now, 0..1
	inTunnel: boolean?,
	autoHintT: number?, -- when Q / E in automatic last showed its hint
	seaT: number?, -- seconds on the water (back to the road after 2)
	-- driving feel (Config.DrivingFeel)
	yawRate: number, -- the car's turn now (it follows the wheel with some weight)
	groundDist: number?, -- last ground ray distance (kerbs and bumps kick the body)
	gapSm: number?, -- the springs' mean travel, smoothed (a stud under one wheel barely lifts the body)
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
local windDof: DepthOfFieldEffect? = nil
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
	-- the main menu is open: braked and held where it is (owner, 2026-11-02)
	if Driving.menuHold or Driving.loadHold then
		-- (brakes while moving, the handbrake once stopped: a held brake at a stop would reverse)
		local s = state
		local moving = s ~= nil and Vector3.new(s.vel.X, 0, s.vel.Z).Magnitude > 3
		return 0, if moving then 1 else 0, 0, true, false
	end
	if not Driving.inputEnabled or UI.isGarageOpen() then
		return 0, 0, 0, false, false
	end
	local throttle, brake, steer = 0, 0, 0
	local handbrake, clutch = false, false
	-- Studio test drives (Claude's road checks): a test script drives through player attributes
	local tester = Players.LocalPlayer
	if RunService:IsStudio() and tester:GetAttribute("TestDrive") then
		return tester:GetAttribute("TestThrottle") or 0, tester:GetAttribute("TestBrake") or 0, tester:GetAttribute("TestSteer") or 0, tester:GetAttribute("TestHandbrake") == true, false
	end
	if UserInputService:GetFocusedTextBox() == nil then
		clutch = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			throttle = 1
		end
		keyThrottle = throttle > 0
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
	if not (Config.DrivingFeel.NitroEnabled or (state and state.nitroOn)) or Driving.nitroBlocked or not Driving.inputEnabled or UI.isGarageOpen() then
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
type Skid = { part: BasePart, born: number, base: number }
local skids: { Skid } = {}
local skidNext = 1
local skidFolder: Folder? = nil
-- (2026-11-03) as wide as the tyre, darker the harder it slips, laid on the road's own slope
local function skidMark(a: Vector3, b: Vector3, width: number?, dark: number?, normal: Vector3?)
	local len = (b - a).Magnitude
	if len < 0.3 or len > 20 or not Driving.marks then
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
		entry = { part = p, born = 0, base = 0.35 }
		skids[skidNext] = entry
	end
	local base = 0.62 - 0.4 * math.clamp(dark or 0.5, 0, 1) -- see-through, darker with a harder slide
	entry.part.Size = Vector3.new(width or 0.85, 0.04, len + 0.1)
	entry.part.CFrame = CFrame.lookAt((a + b) / 2, b, normal or Vector3.yAxis)
	entry.part.Transparency = base
	entry.base = base
	entry.born = os.clock()
	skidNext = skidNext % math.max(cap, 1) + 1
end
local HARD_SURFACE = {
	[Enum.Material.Asphalt] = true, [Enum.Material.Concrete] = true, [Enum.Material.Pavement] = true,
	[Enum.Material.SmoothPlastic] = true, [Enum.Material.Plastic] = true, [Enum.Material.Slate] = true,
	[Enum.Material.Cobblestone] = true, [Enum.Material.Basalt] = true, [Enum.Material.Limestone] = true,
}
local LOOSE_SURFACE = {
	[Enum.Material.Grass] = true, [Enum.Material.LeafyGrass] = true, [Enum.Material.Sand] = true,
	[Enum.Material.Ground] = true, [Enum.Material.Mud] = true, [Enum.Material.Snow] = true,
}
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
				e.part.Transparency = e.base + (1 - e.base) * age * age
			end
		end
	end
end

local SMOKE = ColorSequence.new(Color3.fromRGB(206, 206, 208), Color3.fromRGB(160, 160, 164))
local DUST = ColorSequence.new(Color3.fromRGB(170, 150, 118), Color3.fromRGB(140, 124, 98))

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

-- a car's exhaust settings (Config.ExhaustBands; a SPORT / TOP trim has its base car's)
local function exhaustCfg(s: State): any
	local cfg = Config.ExhaustBands[s.spec.Id]
	if cfg == nil then
		local spec = Cars.get(s.spec.Id) :: any
		cfg = if spec and spec.BaseId then Config.ExhaustBands[spec.BaseId] else nil
	end
	return cfg
end

-- a car with no pops or bangs (Config.ExhaustBands: `noPops`)
local function noPops(s: State): boolean
	local cfg = exhaustCfg(s)
	return cfg ~= nil and cfg.noPops == true
end
-- (2026-11-09, the supercars' real engines) no pops lifting off (`liftPops = false`), no bang or flame on
-- a hard upshift (`shiftPops = false`: a smooth dual-clutch car)
local function noLiftPops(s: State): boolean
	local cfg = exhaustCfg(s)
	return cfg ~= nil and cfg.liftPops == false
end
local function noShiftPops(s: State): boolean
	local cfg = exhaustCfg(s)
	return cfg ~= nil and cfg.shiftPops == false
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
	curP = nil
	UI.showShiftPaddles(false)
	for _, c in s.connections do
		c:Disconnect()
	end
	for _, f in s.flameParts do
		f:Destroy()
	end
	if s.lamps then
		CarLamps.drive(nil, "off", "", false, false)
		CarLamps.reset()
		UI.setLampMode(nil)
	end
	s.engine:destroy()
	if s.roar then
		s.roar:Destroy()
	end
	setVignette(0)
	if windDof then
		windDof.NearIntensity, windDof.FarIntensity = 0, 0
	end
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
	-- (owner, 2026-11-02: "when a player exit a car the hands get left behind"): the driver's arms
	-- (a local rig under the camera) go, and the steering wheel and needle parts that were posed by
	-- hand (unwelded and anchored on this client) are put back at rest and welded to the car again,
	-- so they move with it once the driver is out
	for _, arm in s.localArms do
		local rig = arm.upper and arm.upper.Parent
		if rig and rig:IsA("Model") and rig:IsDescendantOf(workspace.CurrentCamera) then
			rig:Destroy()
		end
	end
	table.clear(s.localArms)
	pcall(function()
		local root = s.root
		local function reweld(part: BasePart, cf: CFrame)
			part.CFrame = cf
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = part
			w.Parent = part
			part.Anchored = false
		end
		if s.steerMount then
			for _, ls in s.localSteer do
				if ls.part.Parent then
					reweld(ls.part, root.CFrame * s.steerMount * ls.offset)
				end
			end
		end
		for _, n in s.partNeedles do
			if n.part.Parent then
				reweld(n.part, root.CFrame * n.pivot * n.offset)
			end
		end
	end)
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

-- the car's own engine stays quiet while something else plays it (the workshop's dyno)
function Driving.muteEngine(on: boolean)
	local s = state
	if s then
		s.engine:setRunning(not on and s.engineOn and not s.electric)
	end
end

function Driving.getModel(): Model?
	return if state then state.model else nil
end

-- (2026-11-07) cruise control -----------------------------------------------------------------------
Driving.noCruise = nil :: (() -> boolean)? -- set by CareClient: true in a race, a time trial or on a job
Driving.onMisfire = nil :: (() -> ())? -- set by CareClient: the puff of smoke

local function showCruise(s: State)
	local mph = if s.cruise then Config.spsToMph(s.cruise) else nil
	UI.setCruise(mph, Driving.units == "kmh")
	DashGauges.cruiseMph = mph
end

local function cruiseOff(s: State, beep: boolean?)
	if s.cruise then
		s.cruise = nil
		showCruise(s)
		if beep then
			Audio.tick(false)
		end
	end
end

function Driving.toggleCruise()
	local s = state
	if not s then
		return
	end
	if s.cruise then
		cruiseOff(s, true)
		return
	end
	local C = Config.Cruise
	local v = s.vel:Dot(forwardFromYaw(s.yaw))
	if not s.engineOn then
		return
	end
	if Driving.noCruise and Driving.noCruise() then
		UI.toast("No cruise control in a race or on a job", Config.Theme.Warning)
		return
	end
	if Config.spsToMph(v) < C.MinMph then
		UI.toast("Cruise control works from " .. C.MinMph .. " mph")
		return
	end
	s.cruise = v
	s.cruiseI = 0
	s.cruiseUp = 0
	s.cruiseDown = 0
	s.cruiseGapT = 0.5
	showCruise(s)
	Audio.tick(true)
end

-- the phone's + and - (steps of 5, in mph or km/h)
function Driving.cruiseStep(dir: number)
	local s = state
	if not s or not s.cruise then
		return
	end
	local C = Config.Cruise
	local step = Config.mphToSps(if Driving.units == "kmh" then C.Step / 1.609 else C.Step)
	s.cruise = math.clamp(s.cruise + dir * step, Config.mphToSps(C.MinMph), math.min(s.topSpeed, s.capTop or s.topSpeed))
	showCruise(s)
end

-- the pedals while it's on: a tap changes the set speed, the brake held switches it off, then the regulator
local function cruisePedals(s: State, throttle: number, brake: number, dt: number): (number, number)
	local set = s.cruise
	if not set then
		return throttle, brake
	end
	local C = Config.Cruise
	if not s.engineOn or (Driving.noCruise and Driving.noCruise()) then
		cruiseOff(s, true)
		return throttle, brake
	end
	if throttle > 0.3 then
		if s.cruiseUp <= 0 then
			Driving.cruiseStep(1)
			s.cruiseUp = 0.45
		end
		s.cruiseUp -= dt
	else
		s.cruiseUp = 0
	end
	if brake > 0.3 then
		s.cruiseDown += dt
		if s.cruiseDown > C.HoldBrake then
			cruiseOff(s, true)
			return 0, brake
		end
	else
		if s.cruiseDown > 0 then
			Driving.cruiseStep(-1)
		end
		s.cruiseDown = 0
	end
	local fwd = forwardFromYaw(s.yaw)
	local v = s.vel:Dot(fwd)
	-- traffic right ahead: it lets go with a short beep
	s.cruiseGapT -= dt
	if s.cruiseGapT <= 0 then
		s.cruiseGapT = 0.2
		local gap = math.max(C.GapMin, v * C.GapSeconds)
		local right = fwd:Cross(Vector3.yAxis)
		local at = Vector3.new(s.root.Position.X, 0, s.root.Position.Z)
		for _, npc in Traffic.near(s.root.Position, gap + 24) do
			local rel = Vector3.new(npc.pos.X, 0, npc.pos.Z) - at
			local f = rel:Dot(fwd)
			if f > 0 and f < gap + s.wheelbase * 0.7 and math.abs(rel:Dot(right)) < (s.width + npc.width) / 2 + 1 and npc.fwd:Dot(fwd) * npc.speed < v - 3 then
				cruiseOff(s, true)
				UI.toast("Cruise off: traffic ahead", Config.Theme.Warning)
				return 0, brake
			end
		end
	end
	local err = (s.cruise :: number) - v
	s.cruiseI = math.clamp(s.cruiseI + err * dt, -40, 40)
	local want = 0.1 * err + 0.03 * s.cruiseI + 0.22
	if err < -9 then
		return 0, math.max(brake, 0.2)
	end
	return math.clamp(want, 0, 1), brake
end

-- what the car's health does (CareClient, when it changes)
function Driving.setCare(care: { [string]: any }?)
	local s = state
	if not s then
		return
	end
	s.care = care :: any
	s.applyTune()
end

-- what happened since the last call, for the server (CareClient, every couple of seconds)
function Driving.takeReport(): { [string]: any }?
	local s = state
	if not s then
		return nil
	end
	local r = s.report
	s.report = { red = 0, launch = 0, drift = 0, burn = 0, hard = 0, thr = 0, n = 0, hits = {} }
	return { red = r.red, launch = r.launch, drift = r.drift, burn = r.burn, hard = r.hard, thr = if r.n > 0 then r.thr / r.n else 0, on = s.engineOn, wet = Driving.wet > 0.5, hits = r.hits, rash = r.rash }
end

-- a mark for the server: k "s" scrape, "t" scratch, "d" dent; f the side; u along it, v up it; n its size
local function hitMark(s: State, k: string, f: string, u: number, v: number, n: number, speed: number)
	if #s.report.hits < 4 then
		table.insert(s.report.hits, { k = k, f = f, u = u, v = v, n = n, sp = speed })
	end
end

-- (2026-11-07) the weight on the hitch, nil with no trailer on (TrailerClient, every frame)
function Driving.setTow(kg: number?)
	local s = state
	if not s or s.towKg == kg then
		return
	end
	s.towKg = kg
	s.applyTune()
	if not kg then
		s.towBrake, s.towRev = false, false
	end
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
	-- (2026-11-04) on its wheels the car runs in Vector mode, where PlaneVelocity does nothing: it
	-- kept rolling at its last speed with nobody in it. Plane mode, as it spawned: stopped, on gravity
	s.lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	s.lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
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
-- is the engine running? (F starts it; once it runs F gets you out)
function Driving.isEngineOn(): boolean
	return state ~= nil and state.engineOn == true
end

-- set by OnFoot: what F does in a running car (get out when slow enough)
Driving.onExitKey = nil :: (() -> ())?
Driving.onDoorKey = nil :: (() -> ())? -- (2026-11-08) Shift + F: the scissor doors (client/CarDoors)

local applyCamera: () -> ()
function Driving.toggleCamera()
	Driving.cameraMode = CAMERA_ORDER[Driving.cameraMode] or "Immersive"
	applyCamera()
end

-- V: first person and back to the outside view you had (Driving Empire's V); Shift + V cycles the
-- outside views
local lastOutside = "Immersive"
function Driving.toggleFirstPerson()
	if Driving.cameraMode == "Interior" then
		Driving.cameraMode = lastOutside
	else
		lastOutside = Driving.cameraMode
		Driving.cameraMode = "Interior"
	end
	applyCamera()
end

applyCamera = function()
	CameraLook.reset()
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
	-- (on the Monaco map its own lanes; CityLayout only knows the old city's)
	local here = s.root.Position - Vector3.new(0, 2, 0)
	local cf = (if workspace:FindFirstChild("Riviera") then RivieraTraffic.nearestCFrame(here) else nil) or CityLayout.nearestLaneCFrame(s.root.Position)
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

-- the main menu's fast travel: the car onto a spot (ground level, facing the way on), stopped
function Driving.teleport(cf: CFrame)
	local s = state
	if not s then
		return
	end
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	local flat = if look.Magnitude > 0.1 then CFrame.lookAt(cf.Position, cf.Position + look.Unit) else CFrame.new(cf.Position)
	s.root.AssemblyLinearVelocity = Vector3.zero
	s.root.AssemblyAngularVelocity = Vector3.zero
	s.root.CFrame = flat + Vector3.new(0, s.halfHeight + 0.6, 0)
	s.yaw = yawFromLook(flat.LookVector)
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
	if curP then
		return CarPhysics.gearHi(curP, g)
	end
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
	if curP then
		return CarPhysics.evPull(frac)
	end
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
	-- (keyed by the numbers too: a car with performance parts drives its tuned ones)
	local key = spec.Id .. "|" .. spec.TopSpeed .. "|" .. spec.ZeroToSixty
	local cached = powerCache[key]
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
	powerCache[key] = { hi, dragFor(accel, hi, top, electric) }
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
		beam = s.beam,
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
	DashGauges.lightsOn = on
	setTails(s)
	if s.lamps then
		return
	end
	for _, d in s.model:GetDescendants() do
		if d:IsA("SpotLight") or (d:IsA("SurfaceLight") and d.Parent and d.Parent.Name:lower():find("head")) then
			d.Enabled = on
		end
	end
end

-- the engine starting brings the dash (needle sweep) and the lights on; stopping it turns them off
-- a tunnel: a roof overhead here and also 25 studs ahead and behind (so a bridge or a sign
-- overhead doesn't count; the coast tunnel is open to the sea on one side, so no wall check)
local tunnelRay = RaycastParams.new()
tunnelRay.FilterType = Enum.RaycastFilterType.Exclude
tunnelRay.IgnoreWater = true
local function roofAt(p: Vector3): boolean
	local up = workspace:Raycast(p, Vector3.new(0, 45, 0), tunnelRay)
	if not up then
		return false
	end
	if up.Instance ~= workspace.Terrain then
		local sz = (up.Instance :: BasePart).Size
		if math.max(sz.X * sz.Z, sz.X * sz.Y, sz.Y * sz.Z) < 300 then
			return false -- a sign or a lamp overhead, not a roof
		end
	end
	return true
end
local function isInTunnel(s: State): boolean
	local ignore: { Instance } = { s.model }
	for _, name in { "Traffic", "PlayerCars", "Pedestrians" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(ignore, f)
		end
	end
	if workspace.CurrentCamera then
		table.insert(ignore, workspace.CurrentCamera)
	end
	tunnelRay.FilterDescendantsInstances = ignore
	local p = s.root.Position
	local f = s.root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if f.Magnitude < 0.1 then
		return false
	end
	f = f.Unit
	return roofAt(p) and roofAt(p + f * 25) and roofAt(p - f * 25)
end

local function setCarPower(s: State, on: boolean)
	setClusterPower(s, on)
	if s.lamps then
		return -- (CarLamps decides: the update loop sends the change)
	end
	setLights(s, on)
	remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn })
end

-- F / Q / E / M / P / T / L / Z / X / C (owner, 2026-10-31: the keys of Driving Empire; F starts
-- the car, and once it's running F gets you out, like Y)
local function carKey(s: State, key: Enum.KeyCode)
	if key == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		-- (2026-11-08) Shift + F: the scissor doors up / down, on the cars that have them (no free letter was left)
		if Driving.onDoorKey then
			Driving.onDoorKey()
		end
		return
	end
	if key == Enum.KeyCode.F then
		if s.engineOn then
			if Driving.onExitKey then
				Driving.onExitKey()
			end
		elseif s.care and s.care.empty then
			UI.toast(if s.electric then "Battery empty" else "Out of fuel", Config.Theme.Warning)
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
	elseif (key == Enum.KeyCode.E or key == Enum.KeyCode.Q) and not s.manual then
		-- (owner, 2026-11-03: "when using automatic mode when u press E or Q it switches to manual
		-- mode"): in automatic Q / E do nothing but say how to change (M, or Settings)
		if os.clock() - (s.autoHintT or 0) > 3 then
			s.autoHintT = os.clock()
			UI.toast("Automatic: press M for sequential (Q / E)")
		end
	elseif key == Enum.KeyCode.E or key == Enum.KeyCode.Q then
		local fwdSpeed = s.vel:Dot(forwardFromYaw(s.yaw))
		local before = s.mgear
		if key == Enum.KeyCode.E then
			s.mgear = math.min(s.mgear + 1, gearsNow())
		else
			-- into reverse only when (nearly) stopped
			s.mgear = math.max(s.mgear - 1, if fwdSpeed > 4 then 0 else -1)
		end
		if s.mgear ~= before and s.mgear <= 0 then
			UI.toast(if s.mgear < 0 then "Reverse" else "Neutral")
		end
		if s.mgear ~= before and s.mgear > 0 and not s.clutch then
			s.shiftT = 0.1 * s.shiftK -- a quick shift: the drive drops for a moment, then kicks back in
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
	elseif key == Enum.KeyCode.P and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		-- (Shift + P is the free camera, PhotoMode)
		s.parkBrake = not s.parkBrake
		UI.toast(if s.parkBrake then "Handbrake on" else "Handbrake off")
	elseif key == Config.Cruise.Key then
		Driving.toggleCruise()
		return
	elseif key == Enum.KeyCode.T then
		s.tc = not s.tc
		DashGauges.tcOff = not s.tc
		UI.toast(if s.tc then "Traction control on" else "Traction control off", if s.tc then nil else Config.Theme.Warning)
	elseif key == Enum.KeyCode.L then
		if s.lamps then
			CarLamps.press() -- (the mode changes on release, Driving.lampRelease)
			return
		end
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
		remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn, beam = if s.lamps then s.beam else nil })
	end
end

local LAMP_MODES = { auto = "AUTO", low = "LOW BEAM", high = "HIGH BEAM", off = "LIGHTS OFF" }
function Driving.lampPress()
	if state and state.lamps then
		CarLamps.press()
	end
end
function Driving.lampRelease()
	local mode = CarLamps.release()
	if mode and state and state.lamps then
		UI.setLampMode(mode)
		UI.toast("Lights: " .. LAMP_MODES[mode])
	end
end

-- other players' cars: their blinkers and lights, from the attributes the server sets on them
type OtherWheel = { motor: Motor6D, knuckle: Motor6D?, front: boolean, radius: number, spin: number, blur: { BasePart }, spokes: { BasePart }, shown: number }
type OtherCar = { model: Model, L: { PointLight }, R: { PointLight }, lights: boolean?, smoke: { ParticleEmitter }, wheels: { OtherWheel }, kitBy: { [BasePart]: OtherWheel }, skinN: number, engine: Audio.Engine?, eRpm: number, eThr: number, eGear: number, eOn: boolean?, eDistT: number }
local others: { [Model]: OtherCar } = {}
-- (2026-11-09) the other players' engines heard at once, and how far (studs)
local OTHER_ENGINE_MAX, OTHER_ENGINE_RANGE = 3, 220
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
	local o: OtherCar = { model = model, L = {}, R = {}, smoke = {}, wheels = {}, kitBy = {}, skinN = -1, eRpm = 0.12, eThr = 0, eGear = 0, eDistT = 0 }
	-- (2026-11-08) its wheels: they spin with its speed and the fronts turn with its steering (the Steer attribute);
	-- the kit-v2 wheels blur at speed as ours do
	local kitBy = o.kitBy
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			local kn = root:FindFirstChild("Knuckle" .. j.Name:sub(6))
			local w: OtherWheel = {
				motor = j,
				knuckle = if kn and kn:IsA("Motor6D") then kn else nil,
				front = j:GetAttribute("Front") == true,
				radius = (j:GetAttribute("Radius") :: number?) or 1.1,
				spin = 0,
				blur = {},
				spokes = {},
				shown = 0,
			}
			table.insert(o.wheels, w)
			if j.Part1 then
				kitBy[j.Part1 :: BasePart] = w
			end
		end
	end
	-- tyre smoke at the rear wheels' contact patches (the driver's game sends how much: the Smoke attribute)
	local spots: { Vector3 } = {}
	for _, w in o.wheels do
		if not w.front then
			table.insert(spots, w.motor.C0.Position - Vector3.new(0, w.radius * 0.85, 0))
		end
	end
	if #spots ~= 2 then
		spots = { Vector3.new(-size.X * 0.38, -size.Y * 0.45, size.Z * 0.32), Vector3.new(size.X * 0.38, -size.Y * 0.45, size.Z * 0.32) }
	end
	for _, at in spots do
		local att = Instance.new("Attachment")
		att.Name = "OtherSmoke"
		att.Position = at
		att.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Lifetime = NumberRange.new(1.2, 2.2)
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(25, 25)
		e.Acceleration = Vector3.new(0, 2.5, 0)
		e.Drag = 1.5
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(0.4, 3.5), NumberSequenceKeypoint.new(1, 7) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 1) })
		e.Color = SMOKE
		e.LightInfluence = 0.25
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-40, 40)
		e.Parent = att
		table.insert(o.smoke, e)
	end
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

local function updateOthers(dt: number?)
	local folder = workspace:FindFirstChild("PlayerCars")
	if not folder then
		return
	end
	local step = math.min(dt or 1 / 60, 0.1)
	local camPos = workspace.CurrentCamera.CFrame.Position
	local lit = (os.clock() % 0.8) < 0.4
	for _, model in folder:GetChildren() do
		if not model:IsA("Model") or model:GetAttribute("Owner") == player.UserId then
			continue
		end
		local blinker = (model:GetAttribute("Blinker") :: string?) or ""
		local lights = model:GetAttribute("Lights")
		local o = others[model] or otherCar(model)
		if not o then
			continue
		end
		-- its kit-v2 wheel pieces (the skin can come after the car)
		local skin = model:FindFirstChild("Skin")
		if skin and #skin:GetChildren() ~= o.skinN then
			o.skinN = #skin:GetChildren()
			for _, w in o.wheels do
				w.blur, w.spokes = {}, {}
			end
			for _, d in skin:GetChildren() do
				local role = d:GetAttribute("WheelRole")
				if role and d:IsA("BasePart") then
					local wc = d:FindFirstChildOfClass("WeldConstraint")
					local w = if wc and wc.Part0 then o.kitBy[wc.Part0 :: BasePart] else nil
					if w then
						if role == "Blur" then
							table.insert(w.blur, d)
						elseif role == "Face" or role == "Nuts" or role == "Cap" then
							table.insert(w.spokes, d)
						end
					end
				end
			end
		end
		-- (2026-11-08) its wheels turn and spin as the driver's do (close by only)
		local root = model.PrimaryPart
		if root and (root.Position - camPos).Magnitude < 260 then
			local v = root.AssemblyLinearVelocity:Dot(root.CFrame.LookVector)
			local steer = (model:GetAttribute("Steer") :: number?) or 0
			local angle = -steer * math.rad(28) / (1 + math.abs(v) / 90)
			for _, w in o.wheels do
				w.spin = (w.spin - v * step / math.max(w.radius, 0.3)) % (math.pi * 2)
				if w.front then
					w.motor.Transform = CFrame.Angles(0, angle, 0) * CFrame.Angles(w.spin, 0, 0)
					if w.knuckle then
						w.knuckle.Transform = CFrame.Angles(0, angle, 0)
					end
				else
					w.motor.Transform = CFrame.Angles(w.spin, 0, 0)
				end
				if #w.blur > 0 then
					local f = math.clamp((math.abs(v) / math.max(w.radius, 0.3) - 12) / 18, 0, 1)
					if math.abs(f - w.shown) > 0.03 or (f == 0 and w.shown ~= 0) or (f == 1 and w.shown ~= 1) then
						w.shown = f
						for _, b in w.blur do
							b.Transparency = 1 - f
						end
						for _, p in w.spokes do
							p.Transparency = f * f
						end
					end
				end
			end
		end
		local lamps = CarLamps.hasModel(model) -- (their lamps blink themselves)
		for side, list in { L = o.L, R = o.R } do
			local on = lit and (blinker == "H" or blinker == side) and not lamps
			for _, l in list do
				l.Enabled = on
			end
		end
		local smokeLevel = (model:GetAttribute("Smoke") :: number?) or 0
		for _, e in o.smoke do
			e.Rate = (if smokeLevel >= 2 then 70 elseif smokeLevel >= 1 then 25 else 0) * fxQuality() * Driving.smoke
		end
		if lights ~= nil and lights ~= o.lights and not lamps then
			o.lights = lights :: boolean
			for _, d in model:GetDescendants() do
				if d:IsA("SpotLight") then
					d.Enabled = lights :: boolean
				end
			end
		end
	end
	-- (2026-11-09) the other players' engines: the nearest few within earshot play their car's own sound
	-- from the car, driven by the revs, throttle and gear their driver sends (EngRpm / EngThr / EngGear /
	-- EngOn); further away, none
	local near: { { o: OtherCar, d: number } } = {}
	for model, o in others do
		local root = model.PrimaryPart
		if root and model.Parent then
			local d = (root.Position - camPos).Magnitude
			if d < OTHER_ENGINE_RANGE then
				table.insert(near, { o = o, d = d })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	local keep: { [OtherCar]: number } = {}
	for i = 1, math.min(#near, OTHER_ENGINE_MAX) do
		keep[near[i].o] = near[i].d
	end
	for model, o in others do
		local d = keep[o]
		local root = model.PrimaryPart
		if d and root and not o.engine then
			local carId = model:GetAttribute("CarId")
			local spec = if type(carId) == "string" then Cars.get(carId) else nil
			if spec then
				local ok, eng = pcall(function()
					local parts = CarStats.decodeParts(model:GetAttribute("Parts"))
					local tune = CarStats.tuneOf(CarStats.cleanParts(spec.Id, parts))
					local e = Audio.engine(spec.Class, root, spec.Id, if tune.engine then tune.engine.layout else nil)
					e:setRedline(CarStats.redlineOf(spec.Id, parts) * 1000)
					e:setMods(tune)
					return e
				end)
				if ok and eng then
					o.engine = eng
					o.eOn = nil
					o.eGear = 0
					o.eRpm = (model:GetAttribute("EngRpm") :: number?) or 0.12
				end
			end
		elseif not d and o.engine then
			o.engine:destroy()
			o.engine = nil
		end
		local eng = o.engine
		if eng and d and root then
			local carId = model:GetAttribute("CarId")
			local spec = if type(carId) == "string" then Cars.get(carId) else nil
			local rpmT = (model:GetAttribute("EngRpm") :: number?) or 0.12
			local thrT = (model:GetAttribute("EngThr") :: number?) or 0
			local gear = (model:GetAttribute("EngGear") :: number?) or 0
			local on = model:GetAttribute("EngOn") ~= false and not (spec and spec.Electric)
			o.eRpm += (rpmT - o.eRpm) * math.min(1, step * 8)
			o.eThr += (thrT - o.eThr) * math.min(1, step * 10)
			if on ~= o.eOn then
				o.eOn = on
				eng:setRunning(on)
			end
			if gear ~= o.eGear then
				if o.eGear > 0 and gear > 0 and on then
					eng:shift(gear > o.eGear, rpmT)
				end
				o.eGear = gear
			end
			local top = Config.mphToSps(if spec then spec.TopSpeed else 150)
			local speedFrac = math.clamp(root.AssemblyLinearVelocity.Magnitude / math.max(top, 1), 0, 1)
			local smokeLevel = (model:GetAttribute("Smoke") :: number?) or 0
			eng:update(o.eRpm, o.eThr, speedFrac, if smokeLevel >= 2 then 40 elseif smokeLevel >= 1 then 22 else 0, nil, nil)
			o.eDistT -= step
			if o.eDistT <= 0 then
				o.eDistT = 0.25
				eng:setDistance(d)
			end
		end
	end
	for model, o in others do
		if not model.Parent then
			if o.engine then
				o.engine:destroy()
				o.engine = nil
			end
			others[model] = nil
		end
	end
end

function Driving.attach(model: Model)
	Driving.detach()
	local root = model.PrimaryPart :: BasePart
	-- (2026-11-03) the car's performance parts (the "Parts" attribute, CarLevels): it drives its tuned
	-- numbers (the same Id, so everything else still knows the car)
	local spec = CarStats.tunedSpec(model:GetAttribute("CarId") :: string, CarStats.decodeParts(model:GetAttribute("Parts")))
	local dims = CarBuilder.getDims(spec.Class, spec.Id)
	UI.setSpeedoCar(CarStats.redline(spec.Id), spec.Electric == true) -- the HUD rev counter's scale
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
			radius = (j:GetAttribute("Radius") :: number?) or 1.1,
			spin = 0,
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
					local scale: { { number } }? = nil
					local sc = d:GetAttribute("GaugeScale")
					if type(sc) == "string" then
						local pts = {}
						for v, a in string.gmatch(sc, "(%-?[%d%.]+):(%-?[%d%.]+)") do
							table.insert(pts, { tonumber(v) :: number, tonumber(a) :: number })
						end
						scale = if #pts >= 2 then pts else nil
					end
					table.insert(partNeedles, {
						part = d,
						kind = kind,
						pivot = d:GetAttribute("GaugePivot") :: CFrame,
						offset = d:GetAttribute("GaugeOffset") :: CFrame,
						scale = scale,
						rest = tonumber(d:GetAttribute("GaugeRest")) or 0,
						unit = tostring(d:GetAttribute("GaugeUnit") or ""),
					})
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
		axle = nil,
		brakeAxle = 0,
		axAxle = 0,
		axleOut = nil,
		gripF = 1,
		gripR = 1,
		thrRamp = 0,
		kit = {},
		brakeHeat = 0,
		glowShown = 0,
		steerSent = 0,
		steerSendT = 0,
		engSent = -1,
		thrSent = -1,
		gearSent = -1,
		onSent = false,
		limitT = 0,
		smokeF = 0,
		smokeR = 0,
		tcFlashT = 0,
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
		powerShown = 0,
		smoke = smoke,
		roll = 0,
		pitch = 0,
		rpmShown = 0,
		camPos = root.Position + Vector3.new(0, 8, 20),
		camLook = root.Position,
		camLag = 0, -- immersive camera: pulled back on hard acceleration, pushed in braking
		towPull = 0,
		towTurn = 0,
		applyTune = function() end, -- (set by attach)
		cruiseUp = 0,
		cruiseDown = 0,
		cruiseI = 0,
		cruiseGapT = 0,
		gripK = 1,
		sputter = 0,
		misT = 2,
		report = { red = 0, launch = 0, drift = 0, burn = 0, hard = 0, thr = 0, n = 0, hits = {} },
		redHold = 0,
		scrapeT = { [1] = 0, [-1] = 0 },
		scrapeU = { [1] = 0.5, [-1] = 0.5 },
		rashT = 0,
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
		lamps = CarLamps.has(spec.Id),
		beam = "off",
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
		launchClean = 0,
		burnArmed = false,
		burnout = false,
		driftTyres = false,
		weightK = 1,
		brakeK = 1,
		shiftK = 1,
		steerK = 1,
		driftK = 0,
		launchK = 1.15,
		launchRev = 0.62,
		bumpK = 1,
		downK = 0,
		rallyK = 0,
		rideDrop = 0,
		rideWant = 0,
		airRide = false,
		popLoud = false,
		popGap = 0.1,
		nitroOn = false,
		nitroDrain = Config.DrivingFeel.NitroDrain,
		lonGReal = 0,
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
	UI.showShiftPaddles(UI.isTouch and s.manual)
	-- (2026-11-08) the kit-v2 wheels' pieces by corner (CarSkin welds each wheel piece to its tyre part): the blurred
	-- face, the spokes it stands in for, the brake discs (they glow after a hard stop)
	do
		local byTire: { [BasePart]: Corner } = {}
		for _, c in s.corners do
			local t = c.motor.Part1
			if t then
				byTire[t] = c
			end
		end
		local skin = model:FindFirstChild("Skin")
		if skin then
			for _, d in skin:GetChildren() do
				local role = d:GetAttribute("WheelRole")
				if role and d:IsA("BasePart") then
					local w = d:FindFirstChildOfClass("WeldConstraint")
					local c = if w and w.Part0 then byTire[w.Part0 :: BasePart] else nil
					if c then
						local k = s.kit[c] or { blur = {}, spokes = {}, discs = {}, shown = 0 }
						s.kit[c] = k
						if role == "Blur" then
							table.insert(k.blur, d)
						elseif role == "Face" or role == "Nuts" or role == "Cap" then
							table.insert(k.spokes, d)
						elseif role == "Disc" then
							local sa = d:FindFirstChildOfClass("SurfaceAppearance")
							if sa then
								table.insert(k.discs, sa)
							end
						end
					end
				end
			end
		end
	end
	if s.lamps then
		CarLamps.reset()
		UI.setLampMode(CarLamps.mode)
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
	-- the tuned numbers (performance parts), again whenever a part is bought while the car is out
	local function applyTune()
		local id = model:GetAttribute("CarId") :: string
		local parts = CarStats.decodeParts(model:GetAttribute("Parts"))
		local setup = CarStats.decodeSetup(model:GetAttribute("Setup"))
		local tuned = CarStats.tunedSpec(id, parts, setup)
		local clean = CarStats.cleanParts(id, parts)
		local tune = CarStats.tuneOf(clean)
		local DFeel = Config.DrivingFeel
		-- (owner, 2026-11-10: with traction control off a car slides like that only on drift tyres)
		s.driftTyres = clean ~= nil and clean.tyres == "ty_drift"
		s.spec = tuned
		s.topSpeed = Config.mphToSps(tuned.TopSpeed)
		s.accel = Config.mphToSps(60) / tuned.ZeroToSixty
		local _, kg = CarStats.powerOf(id, parts)
		-- (2026-11-08) the two-axle model: this car's own numbers (CarPhysicsData), the engine and brakes worked out for
		-- its 0-60 and its real stopping distance with its own gears and gearbox
		if DFeel.Axle.Enabled then
			local P = CarPhysics.params(tuned, s.wheelbase, kg, tuned.Handling)
			s.axle = P
			curP = P
			s.powerK, s.dragC = CarPhysics.powerFor(P, tuned, s.cls.upshift)
			s.brakeAxle = CarPhysics.brakeFor(P, s.dragC)
			s.agear = math.min(s.agear, gearsNow())
			s.mgear = math.min(s.mgear, gearsNow())
		else
			s.axle = nil
			curP = nil
			s.powerK, s.dragC = powerFor(tuned)
		end
		s.weightK = kg / DFeel.WeightRef
		-- (brake bias: a little off at either end)
		s.brakeK = (1 + tune.brake) * (1 - 0.5 * math.abs((setup.bias or 0.6) - 0.6))
		s.shiftK = 1 - math.min(tune.shift, 0.7)
		s.steerK = 1 + tune.steer
		s.driftK = tune.drift + math.max(0, setup.press or 0) * 0.15 + math.max(0, 0.6 - (setup.bias or 0.6)) * 0.5
		s.rallyK = tune.rally
		s.downK = (setup.down or 0) * 0.12 + (if parts.wing then 0.03 else 0)
		-- launch control: its revs, and how well that suits the drive (a good value gives the best start)
		local best = (if s.drive == "AWD" then 0.72 elseif s.drive == "FWD" then 0.48 else 0.58) + (if tune.forced == "turbo" then 0.06 else 0)
		s.launchRev = setup.launch or 0.62
		s.launchK = 1.05 + 0.15 * math.clamp(1 - math.abs(s.launchRev - best) / 0.25, 0, 1) + tune.launch
		s.rideWant = -(setup.ride or 0) * 0.2
		s.bumpK = 1 + math.max(0, -(setup.ride or 0)) * 0.7
		s.airRide = tune.air
		s.popTune = tune.pop
		s.popLoud = tune.loud >= 2 or tune.decat
		s.popGap = if tune.pop == "crackle" then 0.05 elseif tune.pop == "burble" then 0.14 else 0.08
		-- a nitrous bottle: its HUD, and how long it lasts
		s.nitroOn = tune.nitro > 0
		s.nitroDrain = DFeel.NitroDrain / math.max(tune.nitro, 0.1)
		if s.nitroOn or DFeel.NitroEnabled then
			nitroHud()
		end
		if nitroGui then
			nitroGui.Enabled = s.nitroOn or DFeel.NitroEnabled
		end
		-- a swapped engine sounds like its layout, and revs to its own limit
		UI.setSpeedoCar(CarStats.redlineOf(id, parts), spec.Electric == true)
		local layout = if tune.engine then tune.engine.layout else nil
		if layout ~= s.engineLayout then
			s.engineLayout = layout
			s.engine:destroy()
			s.engine = Audio.engine(spec.Class, nil, spec.Id, layout)
			s.engine:setRunning(s.engineOn and not s.electric)
		end
		s.engine:setRedline(CarStats.redlineOf(id, parts) * 1000)
		s.engine:setMods(tune)
		-- (2026-11-07) a trailer on: slower off the line, longer stops, wider turns, a top speed
		s.towTop = nil
		s.capTop = nil
		if s.towKg then
			local W = Config.Towing
			local carShare = kg / (kg + s.towKg)
			s.accel *= carShare ^ W.AccelPow
			s.brakeK *= carShare ^ W.BrakePow
			s.steerK *= W.SteerK
			s.towTop = Config.mphToSps(W.TopMph)
			s.capTop = s.towTop
		end
		-- (2026-11-07) the car's health: a tired engine, worn tyres and brakes (small, never game-breaking)
		s.gripK = 1
		local care = s.care
		if care then
			s.accel *= care.power
			s.powerK *= care.power
			s.brakeK *= care.brake
			s.gripK = care.grip * care.handling
			if care.limp then
				local limp = Config.mphToSps(Config.Wear.LimpMph)
				s.capTop = math.min(s.capTop or limp, limp)
			end
		end
	end
	s.applyTune = applyTune
	applyTune()
	table.insert(s.connections, model:GetAttributeChangedSignal("Parts"):Connect(applyTune))
	table.insert(s.connections, model:GetAttributeChangedSignal("Setup"):Connect(applyTune))
	DashGauges.tcOff = not s.tc
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
	buzz(math.clamp(severity / 60, 0.4, 1), 0.18)
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
	-- (asked at the car's real height: from y 0 nothing up a hill was ever near, 2026-11-04)
	for _, npc in Traffic.near(s.root.Position, 45) do
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
	-- Studio test hooks (Claude's driving tests): TestEngine starts the engine, TestGearbox sets it
	if RunService:IsStudio() then
		local tester = Players.LocalPlayer
		if tester:GetAttribute("TestEngine") and not s.engineOn and s.cranking <= 0 then
			s.cranking = 0.3
			s.ignition = true
		end
		local tp = tester:GetAttribute("TestTeleport")
		if typeof(tp) == "CFrame" then
			tester:SetAttribute("TestTeleport", nil)
			Driving.teleport(tp)
		end
		local gb = tester:GetAttribute("TestGearbox")
		if (gb == "Auto" or gb == "Manual") and (gb == "Manual") ~= s.manual and not s.electric then
			Driving.setGearbox(gb)
		end
		-- (2026-11-08) the driver aids for a test: TestTC / TestESC 0..2, TestABS, TestHelp 0..1
		local tc, esc, ab, hp = tester:GetAttribute("TestTC"), tester:GetAttribute("TestESC"), tester:GetAttribute("TestABS"), tester:GetAttribute("TestHelp")
		if type(tc) == "number" then
			Driving.tcMode = tc
		end
		if type(esc) == "number" then
			Driving.escMode = esc
		end
		if type(ab) == "boolean" then
			Driving.abs = ab
		end
		if type(hp) == "number" then
			Driving.help = hp
		end
	end
	-- steering help on phones (driving assists): a little less lock at speed, so a thumb can't flick
	-- the car round at 200 km/h
	if UI.isTouch and Driving.assist > 0 then
		steerIn *= 1 - Config.DrivingFeel.TouchSteerAssist * Driving.assist * math.clamp(s.vel.Magnitude / s.topSpeed, 0, 1)
	end
	-- the engine: the starter turns it over for a moment, then it runs; off, the pedal does nothing
	if s.cranking > 0 then
		s.cranking -= dt
		if s.cranking <= 0 and s.ignition then
			UI.startPrompt(false)
			s.engineOn = true
			s.warmT = os.clock()
			s.engine:setRunning(not s.electric)
			setCarPower(s, true)
			UI.setIndicators(indicatorState(s))
		end
	end
	-- (2026-11-07) out of fuel: it sputters, then the engine stops and the car coasts
	local careNow = s.care
	if careNow and careNow.empty and s.engineOn then
		if s.sputter <= 0 then
			s.sputter = 1.4
			UI.toast(if s.electric then "Battery empty" else "Out of fuel", Config.Theme.Warning)
		end
		s.sputter -= dt
		throttleKey = if math.sin(os.clock() * 19) > 0 then throttleKey else 0
		if s.sputter <= 0.02 then
			s.sputter = 0
			s.engineOn = false
			s.engine:setRunning(false)
			setCarPower(s, false)
			cruiseOff(s, true)
			UI.setIndicators(indicatorState(s))
		end
	elseif careNow and careNow.misfire and s.engineOn and not s.electric then
		-- under 30%: it stumbles now and then, a pop and a puff of smoke
		s.misT -= dt
		if s.misT <= 0.14 then
			throttleKey = 0
		end
		if s.misT <= 0 then
			s.misT = 1.2 + math.random() * 2.5
			Audio.backfire(s.root)
			if Driving.onMisfire then
				Driving.onMisfire()
			end
		end
	end
	throttleKey, brake = cruisePedals(s, throttleKey, brake, dt)
	-- (2026-11-08) a keyboard's on / off throttle eases in (full in about a sixth of a second) and drops quickly
	if keyThrottle and s.axle then
		s.thrRamp += math.clamp(throttleKey - s.thrRamp, -dt * 12, dt * Config.DrivingFeel.Axle.KeyThrottleRamp)
		throttleKey = s.thrRamp
	else
		s.thrRamp = throttleKey
	end
	local throttle = if s.engineOn then throttleKey else 0
	-- (the wear the server can't see)
	local rep = s.report
	rep.thr += throttle
	rep.n += 1
	if s.rpm >= 0.97 and throttle > 0.5 and not s.electric then
		s.redHold += dt
		if s.redHold > Config.Wear.Engine.RedlineAfter then
			rep.red += dt
		end
	else
		s.redHold = 0
	end
	if s.drifting then
		rep.drift += dt
	end
	if brake > 0.8 and s.vel.Magnitude > 30 then
		rep.hard += dt
	end
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
	-- (owner, 2026-11-03: "when cars use manual mode launch control doesnt work"): the manual and
	-- sequential gearbox get it too, in a forward gear with the clutch up (Shift dropped at high revs
	-- still launches as well)
	if s.launchReady then
		holding = s.engineOn and brake > 0.3 and throttle > 0.3
	else
		holding = s.engineOn and standing and brake > 0.5 and throttle > 0.5 and (not s.manual or (s.mgear >= 1 and not s.clutch))
	end
	-- (owner, 2026-11-10: "to actually bring smoke on tire is when using launch control then release and then press S")
	-- a burnout: after a launch-control start, with the throttle still down, press the brake again: the brakes hold
	-- the car and the driven tyres spin and smoke on the spot. Lift the throttle (or get past BurnArmMph) and it's over
	if s.burnArmed and not s.burnout and (throttle < 0.3 or not s.engineOn or Config.spsToMph(s.vel.Magnitude) > DF.BurnArmMph) then
		s.burnArmed = false
	end
	s.burnout = s.burnArmed and s.engineOn and throttle > 0.5 and brake > 0.3 and not s.electric and (not s.manual or (s.mgear >= 1 and not s.clutch))
	if s.burnout then
		holding = false -- (the pedals are the burnout's, not launch control's)
	end
	if s.launchReady and not holding and not s.burnout and throttle > 0.5 and brake <= 0.3 then
		s.launch = 0.8
		s.report.launch += 1
		-- (owner, 2026-11-10: "when doing launch control there is tire smoke ... remove that") the start itself is clean
		s.launchClean = DF.LaunchClean
		s.burnArmed = true
	end
	if s.launchClean > 0 then
		s.launchClean = if throttle < 0.3 or s.burnout then 0 else math.max(0, s.launchClean - dt)
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
	if s.throttleIn > 0.7 and throttle < 0.2 and not s.electric then
		local liftMph = Config.spsToMph(s.vel.Magnitude)
		local map = s.popTune
		if map == "crackle" or map == "antilag" then
			if s.rpm > 0.4 then
				s.pops = math.random(8, 12)
				s.popTimer = 0.04
			end
		elseif map == "pop" then
			if s.rpm > 0.45 then
				s.pops = math.random(4, 6)
				s.popTimer = 0.04
			end
		elseif map == "burble" then
			if s.rpm > 0.18 and s.rpm < 0.7 then
				s.pops = math.random(3, 5)
				s.popTimer = 0.08
			end
		elseif s.rpm > 0.6 and liftMph > 30 and not noPops(s) and not noLiftPops(s) then
			s.pops = math.random(2, 4)
			s.popTimer = 0.04
		end
	end
	s.throttleIn = throttle

	-- the ride height (TUNE), and air suspension sinking when parked
	do
		local parked = s.airRide and s.vel.Magnitude < 2 and throttle == 0
		s.rideDrop += (s.rideWant + (if parked then 0.35 else 0) - s.rideDrop) * math.min(1, dt * 1.5)
	end

	-- ground check
	rayParams.FilterDescendantsInstances = { s.model, workspace:FindFirstChild("Traffic") :: Instance }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -(s.halfHeight + 1.2), 0), rayParams)
	s.grounded = hit ~= nil
	-- kerbs, ramps and bumps: a sudden change in the ground under the car kicks the body
	if hit then
		local last = s.groundDist
		if last then
			local jump = last - hit.Distance -- up when the ground rises
			-- (owner, 2026-11-02: "the car is jerking and jump and lifting up too much when there is
			-- a stud or a bump"): only a real kerb or ramp kicks the body, and gently; a stud or a
			-- seam in the road is soaked up by the springs. No random sideways roll any more.
			if math.abs(jump) > 0.45 and math.abs(jump) < 4 then
				local k = math.clamp(math.abs(jump) - 0.45, 0, 1.5) * math.sign(jump)
				s.pitchVel += k * DF.BumpKick * 20 * s.weightK ^ -DF.WeightBump * s.bumpK
				s.shake = math.max(s.shake, math.min(math.abs(k) * 0.3 * s.bumpK, 0.35))
				buzz(0.25 + 0.3 * math.abs(k), 0.06)
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
			c.gap = (r.Distance - 1) - (c.rest - s.rideDrop) -- above zero: the road is lower than the wheel's rest
			c.hit = r.Position
			c.mat = r.Material
			c.partName = r.Instance.Name
			c.nrm = r.Normal
			sum += c.gap
			nOn += 1
		else
			c.gap = sp.droop
			c.hit = nil
			c.mat = nil
		end
	end
	-- The springs act as a vertical speed for the body, which the physics holds every physics step
	-- (a force set once a frame overshot at low frame rates: a dropped car bounced 7 studs high).
	-- The body rises or sinks back to its ride height at the spring's own rate, plus the road's own
	-- climb or fall under it, and the damping is the speed limit on the way.
	if nOn > 0 then
		-- the springs' mean travel, smoothed: the body follows the road, not each stud under a
		-- wheel (it rises more slowly than it settles, so a bump doesn't throw it up)
		local raw = sum / nOn
		local prev = s.gapSm or raw
		local k = if raw < prev then DF.LiftEase else DF.SettleEase
		s.gapSm = prev + (raw - prev) * math.min(1, dt * k)
		local avg = s.gapSm
		local rate = math.sqrt(sp.spring) * 0.45
		local vy = -avg * rate
		-- (fewer wheels on the road: over an edge the car drops away freely)
		if nOn < #s.corners then
			vy = math.min(vy, root.AssemblyLinearVelocity.Y)
		end
		s.vyTarget = math.clamp(vy, -sp.damp, sp.damp)
	else
		s.vyTarget = nil
		s.gapSm = nil
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
	-- (the road plane eases in: a sudden tilt of more than ~6 degrees is one wheel on a stud, which
	-- tilts the body only slowly; a real change of slope comes through within a few tenths)
	local tiltRate = if nOn == 0 then 2 elseif upNow:Dot(s.groundUp) < 0.9945 then 3 else 8
	s.groundUp = s.groundUp:Lerp(upNow, math.min(1, dt * tiltRate)).Unit
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
				s.pitchVel -= DF.LandKick * fall * s.weightK ^ -DF.WeightBump
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
			-- (2026-11-07) where it hit: from the way the speed went, on the side that took it
			local push = s.lastCommand - actualFlat
			local fwdNow = forwardFromYaw(s.yaw)
			local sideNow = fwdNow:Cross(Vector3.yAxis)
			local along, across = push:Dot(fwdNow), push:Dot(sideNow)
			local kind = if loss > 34 then "d" else "t"
			local sizeK = math.clamp(loss / 45, 0.5, 1.6)
			if math.abs(along) >= math.abs(across) then
				hitMark(s, kind, if along > 0 then "F" else "B", 0.5 + math.clamp(across / math.max(math.abs(along), 1), -1, 1) * 0.38, 0.35 + math.random() * 0.15, sizeK, loss)
			else
				hitMark(s, kind, if across > 0 then "R" else "L", 0.5 + (math.random() - 0.5) * 0.7, 0.3 + math.random() * 0.25, sizeK, loss)
			end
			cruiseOff(s, true)
			s.vel = actualFlat
			reportCrash(s, loss)
			-- the jolt: the body and the driver's head are thrown
			local k = math.clamp(loss / 40, 0, 2) * DF.CrashJolt * s.weightK ^ -DF.WeightBump
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
				if s.agear < gearsNow() and rev >= 0.5 + (s.cls.upshift - 0.5) * throttle then
					s.nextGear = s.agear + 1
					-- (each car's own gearbox with the two-axle model: dual-clutch quick, old automatics slow)
					local shiftTime = if curP then curP.shift else s.cls.shiftTime
					s.shiftT = (if throttle > 0.5 then shiftTime else shiftTime * 1.6) * s.shiftK
				elseif s.agear > 1 and rev < (if throttle > 0.8 then 0.55 else 0.28) and speedFrac / gearHi(s.agear - 1) < (if curP then 0.82 else 0.9) then
					s.nextGear = s.agear - 1
					s.shiftT = 0.12
				end
			elseif fwdSpeed <= 1 then
				s.agear = 1
			end
		end
		local gearNow = if s.manual then s.mgear else s.agear
		local engaged = s.engineOn and not s.clutch and s.shiftT <= 0 and gearNow ~= 0
		-- (2026-11-08) the two-axle model takes the engine's push and the brakes apart (each through its tyres' grip)
		local axleOn = s.axle ~= nil
		local aEng, aBrk = 0, 0
		if engaged and gearNow > 0 and fwdSpeed > -2 then
			local rev = if s.electric then math.max(speedFrac, 0) else math.max(speedFrac, 0) / gearHi(gearNow)
			if throttle > 0 and speedFrac < 1 and not (s.capTop and fwdSpeed >= s.capTop) then -- at top speed the limiter holds it there
				local pull = if s.electric then evPull(math.max(speedFrac, 0)) else torqueCurve(math.max(rev, 0.3)) * gearMul(gearNow)
				local push = s.accel * s.powerK * throttle * pull * (if s.launch > 0 then s.launchK else 1)
				a += push
				aEng += push
			elseif throttle == 0 and fwdSpeed > 2 and not (axleOn and brake > 0.3) then
				-- engine braking (regen on an electric car); not under hard braking (the clutch is out)
				local eb = 3 + 6 * math.min(rev, 1)
				a -= eb
				aEng -= eb
			end
			if rev > 1.02 then
				a -= 30 * (rev - 1) -- shifted down too early: the engine holds the car back
				aEng -= 30 * (rev - 1)
			end
		elseif throttle > 0 and fwdSpeed < -2 and not (s.manual and gearNow < 0) then
			-- braking out of reverse (not in a manual's R gear: there the throttle drives it backwards;
			-- owner, 2026-10-30: manual reverse crawled at ~5 km/h because this braked it)
			a += 140 * throttle
		end
		-- brakes by class; a hard stop at speed pulses the anti-lock (keeps some steering)
		-- (2026-11-03, realistic physics) real stopping power: the class's brake (about g x 28 x
		-- BrakeBoost), a heavier car stops later, a wet road too
		local brakeForce = s.cls.brake * s.brakeK * s.brakeIn * s.weightK ^ -DF.WeightBrake * (1 - DF.WetBrakeLoss * Driving.wet)
		if axleOn then
			-- each car's own brakes, for its real stopping distance (CarPhysics.brakeFor); with ABS off a full pedal
			-- squeezes harder than the tyres can take, and they lock
			brakeForce = s.brakeAxle * s.brakeK * s.brakeIn * (1 - DF.WetBrakeLoss * Driving.wet) * (if Driving.abs then 1 else DF.Axle.AbsOffSqueeze)
		end
		local abs = s.brakeIn > 0.8 and Config.spsToMph(math.abs(fwdSpeed)) > 12 and (Driving.abs or not axleOn)
		if abs then
			s.absT += dt
			brakeForce *= 1 - DF.AbsPulse * (0.5 + 0.5 * math.sin(s.absT * math.pi * 2 * DF.AbsHz))
			s.shake = math.max(s.shake, 0.05)
		end
		-- reverse: 10 km/h at most for every car (owner, 2026-10-31: "make the top speed like 10 kmh";
		-- it was 25 mph), with a gentle pull so it creeps back rather than jumping
		local reverseTop = Config.mphToSps(10 / 1.609)
		local reversePull = 24
		if s.manual then
			if engaged and gearNow < 0 and throttle > 0 and fwdSpeed > -reverseTop then
				a -= if fwdSpeed > 2 then 140 * throttle else reversePull * throttle
			end
			if fwdSpeed > 2 then
				a -= brakeForce
				aBrk += brakeForce
			elseif fwdSpeed < -2 then
				a += brakeForce
				aBrk += brakeForce
			end
		elseif fwdSpeed > 2 then
			a -= brakeForce
			aBrk += brakeForce
		elseif brake > 0 and throttle == 0 and fwdSpeed > -reverseTop and s.engineOn and not s.launchReady and s.stopT > 0.12 then
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
		if handbrake and not axleOn then
			drag += 40 -- (the two-axle model locks the rear wheels instead)
		end
		if math.abs(fwdSpeed) > 0.5 then
			a -= math.sign(fwdSpeed) * drag
		elseif throttle == 0 and brake == 0 then
			fwdSpeed = 0
		end
		-- nitro: extra pull, and past the car's own top speed up to NitroTop of it
		s.boosting = nitroHeld() and s.nitro > 0 and engaged and gearNow > 0 and throttle > 0.3 and fwdSpeed > 5 and not s.towTop
		if s.capTop and fwdSpeed > s.capTop then
			a -= math.min(50, 6 + (fwdSpeed - s.capTop) * 2) -- (downhill, or just hitched at speed)
		end
		if s.boosting then
			if speedFrac < 1 then
				a += DF.NitroAccel
			else
				a += drag + DF.NitroAccel * math.clamp((DF.NitroTop - speedFrac) / (DF.NitroTop - 1), 0, 1)
			end
			s.nitro = math.max(0, s.nitro - s.nitroDrain * dt)
		elseif s.nitroOn then
			s.nitro = math.min(1, s.nitro + DF.NitroFillIdle * dt) -- (a fitted bottle refills slowly)
		end
		-- (the two-axle model moves the speed with its tyres below; the rest of the pull (drag, reverse, a limiter) is
		-- the same)
		local aOther = a - aEng + aBrk * (if fwdSpeed >= 0 then 1 else -1)
		if not axleOn then
			fwdSpeed += a * dt
		end

		-- steering: speed-sensitive wheel angle, capped by lateral grip; the wheel turns slower and
		-- finer at speed
		local speedAbs = math.abs(fwdSpeed)
		local steerRate = (if math.abs(steerIn) > math.abs(s.steer) then 4.2 else 7) / (1 + speedAbs / DF.SteerSlowdown)
		s.steer += (steerIn - s.steer) * math.min(1, dt * steerRate)
		local maxAngle = math.rad(36) * s.steerK / (1 + (speedAbs / 70) ^ 1.3)
		local angle = s.steer * maxAngle
		local yawRate = fwdSpeed * math.tan(angle) / s.wheelbase
		local out: any = nil
		if axleOn then
			-- (2026-11-08) the two-axle tyre model (CarPhysics.step): each axle's grip from its own load, surface and the
			-- rain; drive and brakes share it with cornering; the driver aids from Settings
			local AX = DF.Axle
			local P = s.axle :: any
			-- front drive: a gentle pull on a hard launch
			if s.drive == "FWD" and throttle > 0.8 and speedAbs < 40 then
				angle += AX.TorqueSteer * throttle * (1 - speedAbs / 40)
			end
			-- the surface under each axle (kerbs, paint, cobbles a little less; grass, sand, gravel much less)
			local gF, gR, nF, nR = 0, 0, 0, 0
			for _, c in s.corners do
				local g = 1
				if c.mat then
					g = AX.Surface[c.mat.Name] or 1
					local nm = c.partName or ""
					if string.find(nm, "Kerb", 1, true) then
						g = math.min(g, AX.KerbGrip)
					elseif string.find(nm, "Line", 1, true) or string.find(nm, "Dash", 1, true) or string.find(nm, "Paint", 1, true) then
						g = math.min(g, AX.PaintGrip)
					end
					if g < 0.8 then
						g = math.min(1, g * (1 + s.rallyK)) -- rally tyres
					end
				end
				if c.front then
					gF += g
					nF += 1
				else
					gR += g
					nR += 1
				end
			end
			local wetK = (1 - DF.WetGripLoss * Driving.wet) * s.gripK * (1 - math.min(s.driftK, 0.6) * 0.3)
			s.gripF = (if nF > 0 then gF / nF else 1) * wetK
			s.gripR = (if nR > 0 then gR / nR else 1) * wetK
			out = CarPhysics.step(P, {
				vx = fwdSpeed,
				vy = latSpeed,
				r = s.yawRate,
				delta = angle,
				drive = if s.launchReady or s.burnout then 0 elseif aEng > 0 then aEng * CarPhysics.reserve(P, fwdSpeed, s.topSpeed, if s.tc then Driving.tcMode else 0) else aEng,
				brake = aBrk,
				handbrake = handbrake,
				ax = s.axAxle,
				gripF = s.gripF,
				gripR = s.gripR,
				tc = if s.tc then Driving.tcMode else 0,
				esc = Driving.escMode,
				abs = Driving.abs,
				help = Driving.help,
				pedal = s.brakeIn,
				throttle = if engaged and gearNow > 0 then throttle else 0,
				top = s.topSpeed,
				drift = s.driftTyres,
			}, dt)
			-- a burnout: the driven tyres spin flat out on the spot (the wheels, the smoke and the squeal follow `spin`)
			if s.burnout then
				out.spin = 1
			end
			s.axleOut = out
			s.axAxle = out.ax
			-- the TC light: flashes while the aids are working (steady when TC is off), HUD and the live cluster
			if s.tc and out.tcCut > 0.12 then
				s.tcFlashT = 0.35
			end
			s.tcFlashT = math.max(0, s.tcFlashT - dt)
			local flick = s.tcFlashT > 0 and (os.clock() % 0.24) < 0.12
			DashGauges.tcOff = (not s.tc) or flick
			UI.setTcWorking(s.tcFlashT > 0)
			-- the speed: what the tyres put down plus the rest, then the car's frame turns with it
			fwdSpeed += (out.ax + aOther) * dt
			if s.launchReady or (s.burnout and math.abs(fwdSpeed) < 2) then
				fwdSpeed = 0
			end
			latSpeed = out.vy
			s.yawRate = out.r
			yawRate = out.r
			fwdSpeed += latSpeed * out.r * dt
			s.yaw -= out.r * dt
			fwd = forwardFromYaw(s.yaw)
			right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
			-- (Studio driving tests: what the tyres and the engine are doing, on the car's root)
			if RunService:IsStudio() and Players.LocalPlayer:GetAttribute("TestDrive") then
				root:SetAttribute("Dbg", string.format("eng %.1f brk %.1f ax %.1f oth %.1f gF %.2f gR %.2f spin %.2f lock %.2f tc %.2f hb %s g %s wet %.2f k %.2f acc %.1f", aEng, aBrk, out.ax, aOther, s.gripF, s.gripR, out.spin, out.lock, out.tcCut, tostring(handbrake), tostring(s.gear), Driving.wet, s.powerK, s.accel))
			end
		end
		-- (2026-11-03, realistic physics) real tyre grip in g (the car's handling, a little help from
		-- GameGrip), lower for a heavy car, lower in the wet; aero downforce grows with speed squared
		-- (a lot on supercars, a little on the others), so a fast car is planted at speed
		local gripG = (DF.GripBase + DF.GripHandling * handling) * DF.GameGrip * s.weightK ^ -DF.WeightGrip * s.gripK
		gripG *= 1 + ((DF.Downforce[s.spec.Class] or 0) + s.downK) * math.clamp(speedAbs / s.topSpeed, 0, 1.1) ^ 2
		gripG *= 1 - DF.WetGripLoss * Driving.wet
		local latA = gripG * DF.G -- the sideways pull the tyres have (studs/s^2)
		-- weight transfer: braking loads the front (it turns in harder), pulling away loads the rear
		local brakeLoad = math.clamp(s.brakeIn, 0, 1) * math.clamp(speedAbs / 60, 0, 1)
		-- power on the rear (traction control off, or a clutch-drop launch) loosens it
		local loss = 0
		if not handbrake and (throttle > 0.5 or s.launch > 0) and s.drive ~= "FWD" then
			loss = (if s.tc then 0.05 else 0.4) * throttle * math.clamp(1 - math.abs(speedFrac) * 1.5, 0, 1)
			-- (the rear squats under power: a rear-drive car puts it down a little better as it digs in)
			loss *= 1 - DF.SquatGrip * math.clamp(s.lonGReal, 0, 1)
			if s.launch > 0 then
				loss += 0.2
			end
			if s.drive == "AWD" then
				loss *= if s.spec.RearBias then DF.AwdRearBias else DF.AwdPowerOversteer -- all four wheels share the power
			end
			loss = math.min(loss, 0.7)
		end
		local cap = latA / math.max(speedAbs, 1)
		cap *= 1 + DF.BrakeTurnIn * brakeLoad
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
		if not axleOn then
			yawRate = math.clamp(yawRate, -cap, cap)
			-- the car's turn follows the wheel with its weight: quick when parking, heavier at speed
			local response = (DF.YawResponse + DF.YawResponseHandling * handling) * (1 + 3 * math.max(0, 1 - speedAbs / 40)) / s.cls.inertia
			-- (2026-11-03) momentum: a heavy car's turn builds slower, and every car resists sudden
			-- direction changes at speed (no snapping at 250 km/h)
			response /= s.weightK ^ DF.WeightInertia * (1 + speedAbs / DF.HighSpeedYaw)
			s.yawRate += (yawRate - s.yawRate) * math.min(1, dt * response)
			yawRate = s.yawRate
			s.yaw -= yawRate * dt
		end

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
			if not axleOn then
				s.yaw += d * DF.DriftAssist * (0.4 + 0.6 * Driving.assist) * (1 - 0.6 * math.abs(steerIn)) * dt
				if math.abs(d) > DF.DriftMaxAngle then
					s.yaw += (math.abs(d) - DF.DriftMaxAngle) * math.sign(d) * math.min(1, dt * 12)
				end
			elseif Driving.help > 0 and math.abs(d) > DF.DriftMaxAngle then
				-- (the two-axle model) past the spin limit the countersteer help turns the car back towards where it's
				-- going (off for "Pro"); its speed stays, seen from the new heading
				local wv = fwd * fwdSpeed + right * latSpeed
				s.yaw += (math.abs(d) - DF.DriftMaxAngle) * math.sign(d) * math.min(1, dt * 8)
				s.yawRate *= math.exp(-dt * 4)
				fwd = forwardFromYaw(s.yaw)
				right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
				fwdSpeed, latSpeed = wv:Dot(fwd), wv:Dot(right)
			end
			s.nitro = math.min(1, s.nitro + DF.NitroFillDrift * dt)
		end

		-- the car turns, its momentum doesn't: the velocity stays where it was and the tyres pull
		-- it round as far as their grip allows (below), which is what lets a car slide and drift
		-- (the two-axle model did all of this in CarPhysics.step)
		if not axleOn then
			local nf = forwardFromYaw(s.yaw)
			local nr = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
			local wv = fwd * fwdSpeed + right * latSpeed
			fwdSpeed, latSpeed = wv:Dot(nf), wv:Dot(nr)
			fwd, right = nf, nr
		end

		-- lateral grip (low with handbrake -> drift). Past the tyres' peak slip angle the grip falls
		-- away, so a slide keeps going until you catch it
		local grip = if handbrake then 1.4 else 4.5 + 5 * handling
		local slipAngle = math.atan2(math.abs(latSpeed), math.max(math.abs(fwdSpeed), 6))
		if not axleOn then
		grip *= 1 - loss
		grip *= 1 - math.min(s.driftK, 0.6) * 0.4 -- (drift tyres, a drift kit, high pressures)
		if s.surface == "loose" then
			grip *= 1 + s.rallyK
		end
		-- braking hard mid-corner: the rear goes light and can step out
		grip *= 1 - DF.TrailBrakeLoose * brakeLoad * math.abs(s.steer)
		grip *= 1 - DF.WetGripLoss * Driving.wet
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
			local remove = latA * 1.15 * gripK * dt
			latSpeed *= math.exp(-grip * 0.5 * dt)
			latSpeed = math.sign(latSpeed) * math.max(0, math.abs(latSpeed) - remove)
		end
		-- driving assist (Settings: Off / Low / Normal): past the tyres' peak, outside a drift or the
		-- handbrake, the slide and the spin are gently caught, so keyboard and touch players don't spin
		if Driving.assist > 0 and not handbrake and not s.drifting and slipAngle > DF.SlipPeak then
			latSpeed *= math.exp(-DF.StabilityAssist * Driving.assist * dt)
			s.yawRate *= math.exp(-DF.StabilityAssist * 0.5 * Driving.assist * dt)
		end
		end -- (the old model)
		s.slip = math.abs(latSpeed) + (if handbrake and math.abs(fwdSpeed) > 20 then 25 else 0)
		if out then
			-- (the two-axle model) tyre noise from the real slip: a soft squeal near the limit, louder in a slide, a
			-- screech when locking or spinning; smoke per axle
			local x = math.max(out.slipF / 1.1, out.slipR)
			s.slip = 40 * math.clamp((x - 0.82) / 1.2, 0, 1) + 38 * out.spin + 38 * out.lock + (if handbrake and math.abs(fwdSpeed) > 20 then 20 else 0)
			if math.abs(fwdSpeed) < 4 and out.spin < 0.1 then
				s.slip = 0
			end
			local frontSpin = if s.drive ~= "RWD" then out.spin else 0
			local rearSpin = if s.drive ~= "FWD" then out.spin else 0
			-- (owner, 2026-11-10: "fix tire smoke coming out for no reason when idle") at a crawl the slip angle is no
			-- measure of a slide (a few cm/s of side creep read as a big angle): it smokes only once the car really moves
			local moving = math.clamp((math.abs(fwdSpeed) - 4) / 8, 0, 1)
			s.smokeF = math.clamp(math.max(frontSpin, (out.slipF - 1.4) / 1.5 * moving, if s.brakeIn > 0.8 and not Driving.abs then out.lock else 0), 0, 1)
			s.smokeR = math.clamp(math.max(rearSpin, (out.slipR - 1.3) / 1.4 * moving, if handbrake then out.lock * 0.6 else 0), 0, 1)
			if s.launchClean > 0 then
				s.smokeF, s.smokeR = 0, 0
			end
		end
		if throttle > 0.8 and math.abs(fwdSpeed) < 14 and brake > 0.3 then
			s.report.burn += dt
		end
		if s.drifting then
			s.slip += 30 * math.clamp(math.abs(driftAngle) / 0.5, 0, 1)
		end
		-- tyre noise and smoke: a real launch (traction control off, flooring it from a stop, or a
		-- clutch drop) for a moment only, a hard stop at speed, and turning hard when fast
		local sf = math.abs(fwdSpeed) / s.topSpeed
		-- (the two-axle model hears the real slip, above; these are the old model's guesses)
		if not axleOn and not s.tc and throttle > 0.8 and fwdSpeed >= -1 and sf < 0.06 then
			s.slip += 30 * throttle * (1 - sf / 0.06)
		end
		if s.launch > 0 and not axleOn then
			s.slip += 25 * s.launch / 0.8
		end
		if s.brakeIn > 0.85 and fwdSpeed > 70 then
			s.slip += (if axleOn then 8 else 14) * s.brakeIn
		end
		if not axleOn and math.abs(s.steer) > 0.35 and sf > 0.4 then
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
		-- (g in real units: the body leans and dives by what the car really does; the camera keeps its
		-- old, gentler scale)
		local latG = math.clamp(fwdSpeed * yawRate / DF.G, -2.5, 2.5)
		local lonG = math.clamp(a / DF.G, -2.5, 2.5)
		s.lonGReal = lonG
		s.latG, s.lonG = latG * DF.CameraG, lonG * DF.CameraG
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
		-- (2026-11-04) off the ground for a while, the speed is what the car really does: wedged with
		-- no wheel on anything it kept its old speed, and "Slow down to get out" never went away
		if s.airT > 0.5 then
			s.vel = actualFlat
		end
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
				-- (2026-11-07) a mark every half second of grinding, moving along the side; a metal grind
				s.scrapeT[sd] += dt
				if s.scrapeT[sd] > 0.5 then
					s.scrapeT[sd] = 0
					s.scrapeU[sd] = (s.scrapeU[sd] + 0.17) % 1
					hitMark(s, "s", if sd > 0 then "R" else "L", 0.12 + s.scrapeU[sd] * 0.76, 0.32 + math.random() * 0.16, 1, 0)
					Audio.scrape(math.clamp(s.vel.Magnitude / 80, 0.3, 1))
				end
			end
		end
	end
	-- a kerb under a wheel at speed: curb rash on that rim (a low ray at each front corner, a few times a second)
	s.rashT -= dt
	if s.rashT <= 0 and s.grounded and Config.spsToMph(s.vel.Magnitude) > 8 then
		s.rashT = 0.2
		for i, sd in { -1, 1 } do
			local at = root.Position + Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw)) * sd * (s.width / 2 + 0.2) + forwardFromYaw(s.yaw) * s.wheelbase * 0.5
			local d = workspace:Raycast(at, Vector3.new(0, -8, 0), rayParams)
			if d and string.find(d.Instance.Name, "Kerb", 1, true) then
				s.report.rash = i
			end
		end
	end

	-- nitro fills from driving fast (not while it's being used)
	local mphNow = Config.spsToMph(s.vel.Magnitude)
	if not s.boosting and mphNow > 60 then
		s.nitro = math.min(1, s.nitro + DF.NitroFillSpeed * math.clamp((mphNow - 60) / 80, 0, 1) * dt)
	end

	-- the surface under the car: hard (asphalt, concrete) or loose (grass, sand: dust, no marks)
	if hit then
		s.surface = if HARD_SURFACE[hit.Material] then "hard" elseif LOOSE_SURFACE[hit.Material] then "loose" else "hard"
	end
	-- (2026-11-08, the two-axle model) marks from each tyre's own contact patch, as wide as that tyre, darker the
	-- harder it slides, spins or locks; only on hard ground
	if s.axleOut and s.axle then
		s.skidT += dt
		if s.skidT > 0.05 then
			s.skidT = 0
			local AX = DF.Axle
			local P = s.axle :: any
			for _, c in s.corners do
				local amount = if c.front then s.smokeF else math.max(s.smokeR, if s.drifting then 0.6 else 0)
				local hard = c.mat ~= nil and (AX.Surface[(c.mat :: Enum.Material).Name] or 1) >= 0.85
				if s.grounded and c.hit and hard and amount > 0.15 and mphNow > 6 then
					local p = root.CFrame:PointToWorldSpace(c.at)
					p = Vector3.new(p.X, (c.hit :: Vector3).Y + 0.03, p.Z)
					local w = math.clamp((if c.front then P.tyreF else P.tyreR) / 1000 * 3 * 0.9, 0.5, 1.3)
					if c.skid then
						skidMark(c.skid :: Vector3, p, w, math.clamp(amount, 0.25, 1), c.nrm)
					end
					c.skid = p
				else
					c.skid = nil
				end
			end
		end
	-- skid marks under the rear tyres while they slide (only on a hard road surface)
	elseif s.grounded and hit and s.surface == "hard" and (s.slip > 28 or s.drifting) and mphNow > 8 then
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
			local tyre = math.clamp(s.width * 0.13, 0.6, 1.2)
			local dark = math.clamp((s.slip - 20) / 50, 0, 1)
			if s.skidL then
				skidMark(s.skidL, l, tyre, dark, hit.Normal)
			end
			if s.skidR then
				skidMark(s.skidR, r, tyre, dark, hit.Normal)
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
	-- (2026-11-04) in the sea: off a quay the car skates on the water or sits on the shallow seabed, and
	-- never gets down to the check above. Two seconds of that and it's back on the road (the ray starts
	-- above the car: from under the surface it would miss the water)
	local sea = if root.Position.Y < 20 then workspace:Raycast(root.Position + Vector3.new(0, 8, 0), Vector3.new(0, -(s.halfHeight + 9.2), 0), rayParams) else nil
	if sea and sea.Material == Enum.Material.Water then
		s.seaT = (s.seaT or 0) + dt
		if (s.seaT :: number) >= 2 then
			s.seaT = 0
			Driving.reset()
			return
		end
	else
		s.seaT = 0
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
			if throttle > 0.5 then
				buzz(0.15 + 0.15 * throttle, 0.04) -- a little kick on phones
			end
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
			target = s.launchRev -- launch control holds the revs, steady
			s.rpm = target
		elseif s.burnout then
			target = math.min(0.6 + 0.37 * throttle, 0.97) -- the tyres spinning free: the revs high
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
			-- (2026-11-08) on the limiter the revs bounce off it (the cut and the catch), heard and on the dials
			if s.axle and throttle > 0.6 and rev >= 0.985 then
				s.limitT += dt
				target = 1 - Config.DrivingFeel.Axle.RevBounce * (0.5 + 0.5 * math.sin(s.limitT * math.pi * 2 * 9))
				s.rpm = target
			else
				s.limitT = 0
			end
		end
		s.rpm += (target - s.rpm) * math.min(1, dt * s.cls.revRate)
		if not free then
			s.freeRpm = s.rpm
		end
	end

	-- shift sounds (dip in revs, pops on hard upshifts, the downshift blip): the moment the gearbox
	-- takes the new gear, which is when the revs start to move (owner, 2026-11-03: "the downshift sound
	-- doesn't match the actual downshift"; it used to wait for the gear on the dash, after the shift)
	local effGear: number? = if s.electric then nil elseif s.manual then (if s.mgear > 0 then s.mgear else nil) elseif s.shiftT > 0 then s.nextGear else s.agear
	if effGear and s.soundGear and effGear ~= s.soundGear and math.abs(fs) > 2 and s.engineOn then
		local isUp = effGear > s.soundGear
		s.engine:shift(isUp, math.clamp(0.12 + 0.88 * frac / gearHi(effGear), 0.12, 1.02))
		if isUp and throttle > 0.5 and (s.popTune or (not noPops(s) and not noShiftPops(s))) then
			exhaustPop(s, if s.popLoud then 1.4 else 1)
		end
		-- the crackle map also crackles on the way down the gears
		if not isUp and (s.popTune == "crackle" or s.popTune == "antilag") then
			s.pops = math.max(s.pops, 3)
			s.popTimer = 0.04
		end
	end
	s.soundGear = effGear

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
	-- (2026-11-08) each wheel spins at its own radius: driven wheels faster when they spin up, locked ones stop;
	-- the front wheels at the angle the tyres really have (two-axle model)
	local ao = s.axleOut
	if ao then
		wheelAngle = -math.clamp(ao.delta, -math.rad(30), math.rad(30)) -- (30 degrees at most: the tyre stays in its arch)
	end
	for _, c in s.corners do
		local v = fwdSpeed
		if ao then
			local driven = if s.drive == "AWD" then true elseif s.drive == "FWD" then c.front else not c.front
			if driven and ao.spin > 0 then
				v += (if fwdSpeed >= 0 then 1 else -1) * ao.spin * 45
			end
			if ao.lock > 0.5 and (not c.front or not Driving.abs) and (not c.front or s.brakeIn > 0.8) then
				v = 0
			end
		end
		c.spin = (c.spin - v * dt / math.max(c.radius, 0.3)) % (math.pi * 2)
		-- the kit-v2 wheels: at speed the spokes give way to a blurred spinning face (no strobe), as a camera sees it
		local k = s.kit[c]
		if k then
			local w = math.abs(v) / math.max(c.radius, 0.3)
			local f = math.clamp((w - 12) / 18, 0, 1)
			if math.abs(f - k.shown) > 0.03 or (f == 0 and k.shown ~= 0) or (f == 1 and k.shown ~= 1) then
				k.shown = f
				for _, b in k.blur do
					b.Transparency = 1 - f
				end
				for _, p in k.spokes do
					p.Transparency = f * f
				end
			end
		end
	end
	-- hot brakes after a hard stop from high speed: the discs glow a faint orange, then cool
	do
		local sf = math.abs(fwdSpeed) / s.topSpeed
		if s.brakeIn > 0.7 and sf > 0.35 then
			s.brakeHeat = math.min(1, s.brakeHeat + s.brakeIn * sf * sf * dt * 0.9)
		else
			s.brakeHeat = math.max(0, s.brakeHeat - dt * 0.09)
		end
		local glow = math.clamp((s.brakeHeat - 0.35) / 0.65, 0, 1)
		if math.abs(glow - s.glowShown) > 0.02 or (glow == 0 and s.glowShown ~= 0) then
			s.glowShown = glow
			for _, k in s.kit do
				for _, sa in k.discs do
					pcall(function()
						sa.EmissiveStrength = glow * 1.6
					end)
				end
			end
		end
	end
	-- the other players see the front wheels turn (a steering value on the car, a few times a second)
	s.steerSendT -= dt
	local steerQ = math.floor(s.steer * 10 + 0.5) / 10
	-- (2026-11-09) the engine's revs, throttle, gear and on / off go with it, so the other players hear the
	-- car (rounded, a few times a second at most)
	local engQ = math.floor(math.clamp(s.rpm, 0, 1.1) * 40 + 0.5) / 40
	local thrQ = math.floor(math.clamp(s.throttle, 0, 1) * 4 + 0.5) / 4
	local gearQ = s.soundGear or 0
	local onQ = s.engineOn == true
	if s.steerSendT <= 0 and (math.abs(steerQ - s.steerSent) >= 0.1 or engQ ~= s.engSent or thrQ ~= s.thrSent or gearQ ~= s.gearSent or onQ ~= s.onSent) then
		s.steerSent, s.engSent, s.thrSent, s.gearSent, s.onSent = steerQ, engQ, thrQ, gearQ, onQ
		s.steerSendT = 0.15
		remote("CarSignals"):FireServer({ steer = steerQ, eng = { engQ, thrQ, gearQ, onQ } })
	end
	-- each wheel moves up and down on its spring to stay on the road (its travel smoothed a touch)
	local sp = s.susp
	for _, c in s.corners do
		local want = math.clamp(-c.gap + s.rideDrop, -sp.droop, sp.bump)
		c.travel += (want - c.travel) * math.min(1, dt * 30)
		local m = c.motor
		local lift = CFrame.new(m.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0))
		local klift = if c.knuckle then CFrame.new(c.knuckle.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0)) else CFrame.new()
		if m:GetAttribute("Front") then
			m.Transform = lift * CFrame.Angles(0, wheelAngle, 0) * CFrame.Angles(c.spin, 0, 0)
			-- brake caliper rides on a knuckle that steers but doesn't spin
			if c.knuckle then
				c.knuckle.Transform = klift * CFrame.Angles(0, wheelAngle, 0)
			end
		else
			m.Transform = lift * CFrame.Angles(c.spin, 0, 0)
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
						from = handPos + (arm.shoulder - handPos) * DF.CockpitArm
					end
					-- the hand runs on past the grip, over and round the rim, so its flat end doesn't
					-- show beside the wheel when the hands come up in a turn (owner, 2026-10-29)
					local tip = handPos + (handPos - from).Unit * DF.HandPastGrip
					local len = (tip - from).Magnitude
					if math.abs(arm.upper.Size.Y - len) > 0.02 then
						arm.upper.Size = Vector3.new(arm.upper.Size.X, len, arm.upper.Size.Z)
					end
					arm.upper.CFrame = root.CFrame * CFrame.lookAt((from + tip) / 2, tip) * arm.rot
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
			s.powerShown += ((if s.engineOn then s.throttle * s.rpm else 0) - s.powerShown) * k
			for _, n in s.partNeedles do
				local turn: number
				local pts = n.scale
				if pts then
					-- the dial's own scale (OWN_NEEDLES), from where the model's needle points
					local first, top = pts[1][1], pts[#pts][1]
					local v: number
					if n.kind == "speed" then
						v = if n.unit == "kmh" then s.mphShown * 1.609 else s.mphShown
					elseif n.kind == "rpm" then
						v = s.rpmShown * (if n.unit == "redline" then CarStats.redline(s.spec.Id) * 1000 else 8000) -- (redline is in thousands)
					elseif n.kind == "power" then
						v = s.powerShown * top
					elseif n.kind == "fuel" then
						v = first + (top - first) * 0.85 -- nearly full
					elseif n.kind == "oil" then
						-- warms up over the first minute to its normal reading
						local warm = if s.warmT then math.clamp((os.clock() - s.warmT) / 60, 0, 1) else 0
						v = first + (top - first) * 0.6 * warm
					else
						v = first
					end
					if n.kind == "speed" or n.kind == "rpm" or n.kind == "power" then
						v = math.max(v, sweep * top)
					end
					local ang = pts[#pts][2]
					for i = 1, #pts - 1 do
						local a, b = pts[i], pts[i + 1]
						if v <= b[1] then
							ang = a[2] + (b[2] - a[2]) * math.clamp((v - a[1]) / (b[1] - a[1]), 0, 1)
							break
						end
					end
					turn = ang - n.rest
				else
					turn = (if n.kind == "speed" then s.speedShown else s.rpmShown) * 240
				end
				-- the pivot's +Z looks at the driver: a negative turn is clockwise as the driver sees it
				n.part.CFrame = root.CFrame * n.pivot * CFrame.Angles(0, 0, -math.rad(turn)) * n.offset
			end
			for _, tl in s.guiTexts do
				tl.label.Text = if tl.kind == "Speed" then tostring(math.floor((if (tl.unit or Driving.units) == "kmh" then mph * 1.609 else mph) + 0.5)) elseif tl.kind == "RPM" then tostring(math.floor(s.rpm * 80) * 100) else s.gear
			end
			for _, n in s.guiNeedles do
				n.gui.Rotation = n.base + (if n.kind == "speed" then s.speedShown else s.rpmShown) * 240
			end
		end
	end)
	UI.setSpeed(mph, speedFrac, s.gear, s.rpm, s.launchReady, s.manual)

	-- blinkers: the corner lights and the HUD arrows flash together, with a soft tick
	if s.blinker ~= "" then
		local before = (s.blinkT % 0.8) < 0.4
		s.blinkT += dt
		local lit = (s.blinkT % 0.8) < 0.4
		for side, lights in s.blinkLights do
			local on = lit and (s.blinker == "H" or s.blinker == side) and not s.lamps
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

	-- the new models' lamps (CarLamps): the beam it should be now, told to everyone when it changes
	if s.lamps then
		local beam = CarLamps.beamFor(s.engineOn, s.inTunnel == true)
		if beam ~= s.beam then
			s.beam = beam
			setLights(s, beam == "low" or beam == "high")
			UI.setIndicators(indicatorState(s))
			remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn, beam = beam })
		end
		local reversing = s.engineOn and (fwdSpeed < -1 or (s.manual and s.mgear < 0))
		CarLamps.drive(s.model, beam, s.blinker, s.blinker ~= "" and (s.blinkT % 0.8) < 0.4, reversing)
		CarLamps.wet = Driving.wet
	end

	-- (2026-11-07) towing: the trailer's brake and reverse lamps, told to everyone when they change;
	-- the camera turns round while reversing
	local towReverse = false
	if s.towTop then
		towReverse = s.engineOn and (fwdSpeed < -1.5 or (s.manual and s.mgear < 0))
		local braking = s.brakeIn > 0.2
		if braking ~= s.towBrake or towReverse ~= s.towRev then
			s.towBrake, s.towRev = braking, towReverse
			remote("CarSignals"):FireServer({ brake = braking, rev = towReverse })
		end
	end
	s.towTurn += ((if towReverse then math.pi else 0) - s.towTurn) * math.min(1, dt * Config.Towing.Camera.Turn)
	s.towPull += ((if s.towTop then 1 else 0) - s.towPull) * math.min(1, dt * 2)

	-- the rush: how fast it feels, by real speed (so a quick car at 150 feels it whatever its top)
	local mphNow = Config.spsToMph(math.abs(fwdSpeed))
	local rush = math.clamp((mphNow - DF.RushFrom) / (DF.RushTo - DF.RushFrom), 0, 1) ^ 1.2
	local fx = math.max(speedFrac, rush)

	-- engine / wind / tyre audio (the wind by the rush too)
	-- in a tunnel (a roof overhead along the way; owner, 2026-11-03): the engine doubles and
	-- the sound gets a stone-corridor echo; checked a few times a second
	s.tunnelCheck = (s.tunnelCheck or 0) - dt
	if s.tunnelCheck <= 0 then
		s.tunnelCheck = 0.2
		local inside = isInTunnel(s)
		if inside ~= s.inTunnel then
			s.inTunnel = inside
			s.engine:setTunnel(inside)
			SoundService.AmbientReverb = if inside then Enum.ReverbType.StoneCorridor else Enum.ReverbType.City
		end
	end
	s.engine:setCabin(Driving.cameraMode == "Interior")
	s.engine:update(s.rpm, s.throttle, fx, s.slip, nil, s.screech)
	if s.roar then
		local k = if s.grounded then math.clamp(mphNow / 180, 0, 1) ^ 1.3 else 0
		s.roar.Volume += (DF.RoadRoar * k - s.roar.Volume) * math.min(1, dt * 4)
		s.roar.PlaybackSpeed = 0.35 + 0.45 * k
	end
	-- smoke with the squeal (same curve as the sound); launches smoke the rear tyres most
	local squeal = math.clamp((s.slip - 8) / 40, 0, 1)
	-- (2026-11-03) the Tyre smoke setting, none in the rain (wet tyres don't smoke), dust and less
	-- of it on grass or sand; the driven wheels smoke most
	local q = fxQuality() * Driving.smoke * (if Driving.wet > 0.3 then 0 else 1) * (if s.surface == "loose" then 0.4 else 1)
	local loose = s.surface == "loose"
	if loose ~= s.smokeDust then
		s.smokeDust = loose
		for _, sm in s.smoke do
			sm.emitter.Color = if loose then DUST else SMOKE
		end
	end
	local total = 0
	for _, sm in s.smoke do
		local driven = if s.drive == "FWD" then not sm.rear elseif s.drive == "AWD" then true else sm.rear
		local rate = if squeal > 0.05 then squeal * (if driven then 70 else 35) else 0
		if s.axleOut then
			-- (the two-axle model) each axle smokes from its own tyres' slide, spin or lock
			rate = 75 * (if sm.rear then s.smokeR else s.smokeF)
		end
		if s.launchClean > 0 then
			rate = 0 -- (a launch-control start: no smoke)
		end
		-- a drift smokes the rear tyres hard
		if s.drifting and sm.rear then
			rate = math.max(rate, 55 * math.clamp(math.abs(s.driftAngle) / 0.4, 0.4, 1))
		end
		sm.emitter.Rate = math.min(rate * q, 100) -- (Playbook: about 100 a second per emitter at most)
		total += sm.emitter.Rate
	end
	-- other players see it too: a smoke level on the car (0 / 1 / 2), sent only when it changes
	local level = if total > 120 then 2 elseif total > 25 then 1 else 0
	s.smokeSendT = (s.smokeSendT or 0) - dt
	if level ~= s.smokeSent and s.smokeSendT <= 0 then
		s.smokeSent = level
		s.smokeSendT = 0.3
		remote("CarSignals"):FireServer({ smoke = level })
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
			if s.popTune then
				s.popTimer = s.popGap + math.random() * s.popGap * 1.2
				local k = 0.6 + math.random() * 0.4
				s.engine:pop(k)
				-- (burbles are soft: no flame)
				if s.popTune ~= "burble" then
					exhaustPop(s, k * (if s.popLoud then 1.5 else 1))
				end
			else
				s.popTimer = 0.07 + math.random() * 0.12
				exhaustPop(s, 0.6 + math.random() * 0.4)
				if math.random() < 0.6 then
					Audio.backfire()
				end
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
	-- (2026-11-04) a screen that shut while you sat in the car hands the walking camera back
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
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
	-- (owner, 2026-11-03: "the shaking at top speed is too much ... unrealistic") a real camera at
	-- speed rumbles slowly and a little; it was a fast jitter. Smaller and about 9 times a second now
	local speedShake = 0.008 * math.min(fx * 6, 1) + math.max(0, fx - 0.3) * 0.05
	local shakeAmt = (speedShake + s.shake * 0.5) * cfx.shake
	local shakeOffset = Vector3.new(math.noise(t * 9, 0, 1), math.noise(0, t * 8, 2), 0) * shakeAmt
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
		local buzz = Vector3.new(n(t * 11, 5.1), n(5.3, t * 13), 0) * HS.Buzz * hs
		sway = CFrame.new(float + buzz) * CFrame.Angles(0, 0, HS.Roll * hs * n(t * HS.Rate, 13.3))
	end

	-- (owner, 2026-11-13: "make it so that u can look around in third person camera view") the outside
	-- cameras swing round the car: right mouse button held, a finger dragged on free screen, or the right
	-- stick (client/CameraLook). Swung round, the camera looks at the car instead of the road ahead and
	-- comes in before a wall or the ground; let go and drive, and it eases back behind the car.
	CameraLook.update(dt, mphNow)
	local lookK = if interior then 0 else CameraLook.amount()
	local function orbit(camPos: Vector3, lookAt: Vector3): (Vector3, Vector3)
		if interior or not CameraLook.active() then
			return camPos, lookAt
		end
		local pivot = root.Position + Vector3.new(0, 1.8, 0)
		local turnY = CFrame.Angles(0, CameraLook.yaw, 0)
		local off = turnY:VectorToWorldSpace(camPos - pivot)
		local flatOff = Vector3.new(off.X, 0, off.Z)
		local dist = off.Magnitude
		if flatOff.Magnitude > 1e-3 and dist > 1e-3 then
			local e = math.clamp(math.atan2(off.Y, flatOff.Magnitude) + CameraLook.pitch, -0.2, 1.35)
			off = flatOff.Unit * math.cos(e) * dist + Vector3.new(0, math.sin(e) * dist, 0)
		end
		local look = (pivot + turnY:VectorToWorldSpace(lookAt - pivot)):Lerp(pivot, lookK)
		lookRay.FilterDescendantsInstances = { s.model, player.Character :: Instance }
		local hit = workspace:Raycast(pivot, off, lookRay)
		if hit then
			off = (hit.Position - pivot) * 0.9
		end
		return pivot + off, look
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
		local jolt = Vector3.new(math.noise(t * 10, 0, 1), math.noise(0, t * 9, 2), 0) * (s.shake * 0.15 + DF.CabinBuzz * rush) * cfx.shake
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
		back += s.towPull * Config.Towing.Camera.Back
		up += s.towPull * Config.Towing.Camera.Up
		local side = if low then -LC.Side + s.camSide * 0.5 else s.camSide
		local base = CFrame.new(root.Position) * CFrame.Angles(0, s.yaw, 0) -- level with the road, not the body roll
		local camPos = (base * CFrame.Angles(0, s.camSwing + s.towTurn, 0) * CFrame.new(side, up, back)).Position
		-- road buzz: fine fast shake that grows with speed, plus a slow float
		s.camBob += dt * (4 + fx * 8)
		local buzz = (0.01 + fx ^ 2 * IC.Buzz + s.shake * 0.4) * cfx.shake
		local shake = Vector3.new(math.noise(t * 9, 0, 3), math.noise(0, t * 8, 4), 0) * buzz
			+ Vector3.new(0, math.sin(s.camBob) * 0.012 * fx * cfx.shake, 0)
		local ahead = if low then CFrame.new(-LC.Side * 0.3, LC.LookHeight, -LC.LookAhead) else CFrame.new(0, IC.LookHeight, -IC.LookAhead)
		local lookAt = (base * CFrame.Angles(0, -s.camSwing * 0.6 + s.towTurn, 0) * ahead).Position
		s.camPos = camPos
		s.camLook = lookAt
		local oPos, oLook = orbit(camPos, lookAt)
		camera.CFrame = CFrame.lookAt(oPos + shake, oLook + shake * 0.5) * CFrame.Angles(s.camPitch, 0, s.camRoll)
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
		local dist = C.ChaseDistance + speedFrac * 4 + s.camLag * 0.6 + s.towPull * Config.Towing.Camera.Back
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
		local oPos, oLook = orbit(s.camPos, s.camLook)
		camera.CFrame = CFrame.lookAt(oPos + shakeOffset, oLook) * CFrame.Angles(s.camPitch * 0.7, 0, s.camRoll * 0.8)
		setBlur(math.max(2 * math.max(0, fx - 0.55) ^ 1.5, s.blurPulse))
	end
	camera.CFrame *= sway
	camera.Focus = CFrame.new(root.Position) -- (Playbook: every frame, or shadows and detail break)
	s.fov += (targetFov - s.fov) * math.min(1, dt * 4)
	-- (the cockpit keeps one FOV: the owner wants that view steady and readable)
	camera.FieldOfView = s.fov + (if interior then 0 else s.fovPunch + s.gFov)
	-- speed: a realistic wind blur, not cartoon lines (owner, 2026-11-03): the hard white streaks are
	-- gone; from WindFromMph to the car's top speed the near roadside blurs as it rushes past (depth
	-- of field: what's close, at the screen's edges, smears; the road ahead, where you look, stays
	-- sharp), a touch of far haze, the edges darken a little. Off in the cockpit (the cluster stays
	-- readable), with Motion blur off or Reduced Motion; lighter on phones
	local wind = 0
	if not interior and cfx.blur and not GuiService.ReducedMotionEnabled then
		local mphWind = Config.spsToMph(s.vel.Magnitude)
		local full = math.max(DF.WindFromMph + 30, Config.spsToMph(s.topSpeed) * 0.95)
		wind = math.clamp((mphWind - DF.WindFromMph) / (full - DF.WindFromMph), 0, 1) ^ 1.2 * (if UI.isTouch then 0.6 else 1)
	end
	if windDof then
		s.wind = (s.wind or 0) + (wind - (s.wind or 0)) * math.min(1, dt * 3)
		local w = s.wind :: number
		-- (Roblox has no screen-edge blur: the car and the road close by stay sharp, the street further
		-- ahead and the roadside rushing past blur softly, plus a few feathered streaks at the very edge)
		windDof.NearIntensity = 0
		windDof.FarIntensity = DF.WindFarBlur * w
		windDof.FocusDistance = 30
		windDof.InFocusRadius = 90 - 40 * w
	end
	UI.setSpeedLines((s.wind or 0) * DF.WindStreaks)
	setVignette(DF.Vignette * (s.wind or 0) * (if interior then 0.5 else 1))
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
	-- (2026-11-04) no Q / E on a gamepad: a Manual saved on a PC left the car stuck in neutral. (2026-11-08) phones
	-- shift with the paddles on the screen
	local canShift = UI.isTouch or UserInputService.KeyboardEnabled
	Driving.gearbox = if mode == "Manual" and canShift then "Manual" else "Auto"
	DashGauges.gearbox = Driving.gearbox
	local s = state
	if s then
		s.manual = Driving.gearbox == "Manual" and not s.electric
		s.mgear = if s.manual then (tonumber(s.gear) or 0) else 0
		UI.setIndicators(indicatorState(s))
	end
	UI.showShiftPaddles(UI.isTouch and Driving.gearbox == "Manual" and s ~= nil and not s.electric)
end

---------------------------------------------------------------------
-- One-time setup
---------------------------------------------------------------------
function Driving.init()
	-- (2026-11-13) look around the car in the outside cameras (not in the cockpit or a menu)
	CameraLook.init(function(): boolean
		return state ~= nil and Driving.cameraMode ~= "Interior" and not Driving.cameraHold and not Driving.workshopOpen and not Driving.menuHold and not UI.isGarageOpen()
	end)
	-- (2026-11-08) the phone's shift paddles
	UI.onShift = function(dir: number)
		local s = state
		if s and s.manual then
			carKey(s, if dir > 0 then Enum.KeyCode.E else Enum.KeyCode.Q)
		end
	end
	local b = Instance.new("BlurEffect")
	b.Size = 0
	b.Parent = Lighting
	blur = b
	-- the wind blur at speed (see the camera): a depth of field with nothing in it until you're fast
	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "WindBlur"
	dof.NearIntensity = 0
	dof.FarIntensity = 0
	dof.FocusDistance = 40
	dof.InFocusRadius = 80
	dof.Parent = Lighting
	windDof = dof

	RunService.Heartbeat:Connect(updateOthers)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not state or UI.modalOpen then
			return
		end
		if input.KeyCode == Enum.KeyCode.V then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				Driving.toggleCamera()
			else
				Driving.toggleFirstPerson()
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonY then
			Driving.toggleCamera()
		elseif input.KeyCode == Enum.KeyCode.R then
			-- the radio's next station (Driving Empire's R)
			UI.toast("Radio: " .. Audio.nextStation())
		elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonSelect then
			Driving.reset()
		elseif Driving.inputEnabled and not UI.isGarageOpen() then
			carKey(state, input.KeyCode)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.L then
			Driving.lampRelease()
		end
	end)
	UI.onLampPress = Driving.lampPress
	UI.onLampRelease = Driving.lampRelease

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
