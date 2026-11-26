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
local ExhaustTips = require(Shared:WaitForChild("ExhaustTips"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CarPhysics = require(Shared:WaitForChild("CarPhysics"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local WaterRescue = require(Shared:WaitForChild("WaterRescue"))

local Traffic = require(script.Parent:WaitForChild("Traffic"))
local UI = require(script.Parent:WaitForChild("UI"))
local Frame = require(script.Parent:WaitForChild("Frame")) -- (2026-11-20) per-frame logic also runs with no render frames
local Audio = require(script.Parent:WaitForChild("Audio"))
local LowEnd = require(script.Parent:WaitForChild("LowEnd"))
local DashGauges = require(script.Parent:WaitForChild("DashGauges"))
local R34Mfd = require(script.Parent:WaitForChild("R34Mfd"))
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
-- speed (26 Nov): Settings > Speed effects, scales the speed FOV widening and the speed lines (0 / 0.5 / 1)
Driving.camFx = { shake = 1, head = 1, blur = true, fov = Config.Camera.Immersive.Fov, speed = 1 }
function Driving.setCamFx(fx: { shake: number?, head: number?, blur: boolean?, fov: number?, speed: number? })
	local c = Driving.camFx
	if type(fx.speed) == "number" then
		c.speed = math.clamp(fx.speed, 0, 1)
	end
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
Driving.cameraHold = false -- another screen (Optima Werkz) moves the camera for now
Driving.workshopOpen = false -- the workshop has the camera (over Optima Werkz too)
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
	lampsOut: () -> (), -- (detach: lights and brake lamps off, told to everyone)
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
	mfdUpdate: ((number, number, number, number, boolean) -> ())?, -- a second dash screen (client/R34Mfd)
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
	roadGlow: SpotLight?, -- (2026-11-26) the tail lamps' red light on the road behind
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
	flameLevel: number, -- (2026-11-21) CarStats.flameLevel: 0 no exhaust flames (stock), 1 flames, 2 the Flame Tune
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
	seaT: number?, -- seconds since the last water check (WaterRescue.Every)
	holeT: number?, -- (2026-11-22) seconds stuck under a road (fell through a hole in its collision)
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
	-- (19 Nov) the phone's N2O button is in the touch layout now (UI.buildTouchControls), over GAS
	UI.onNitroTouch = function(on: boolean)
		nitroTouch = on
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
type Skid = { part: BasePart, born: number, base: number, life: number }
local skids: { Skid } = {}
local skidNext = 1
local skidFolder: Folder? = nil
-- (2026-11-26) how many strips and how long they stay: PC Config (240, 10 s), phones 120 / 8 s, low-end 60 / 6 s
local function skidBudget(): (number, number)
	if LowEnd.on then
		return 60, 6
	elseif UI.isTouch then
		return 120, 8
	end
	return Config.DrivingFeel.SkidMax, Config.DrivingFeel.SkidLife
end
-- (2026-11-26) the strip's middle this far up the road's normal: 0.02 thick, its underside 0.06 over the road (no flicker)
local SKID_LIFT = 0.07
-- (2026-11-03) as wide as the tyre, darker the harder it slips, laid on the road's own slope
local function skidMark(a: Vector3, b: Vector3, width: number?, dark: number?, normal: Vector3?)
	local len = (b - a).Magnitude
	if len < 0.3 or len > 20 or not Driving.marks then
		return
	end
	local cap, life = skidBudget()
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
		entry = { part = p, born = 0, base = 0.35, life = 10 }
		skids[skidNext] = entry
	end
	local base = 0.72 - 0.37 * math.clamp(dark or 0.5, 0, 1) -- soft and see-through (0.35-0.72), darker with a harder slide
	local up = normal or Vector3.yAxis
	local mid = (a + b) / 2 + up * SKID_LIFT
	entry.part.Size = Vector3.new(width or 0.85, 0.02, len + 0.02)
	entry.part.CFrame = CFrame.lookAt(mid, mid + (b - a), up)
	entry.part.Transparency = base
	entry.base = base
	entry.life = life
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
	if skidFadeT < 0.1 then
		return
	end
	skidFadeT = 0
	local now = os.clock()
	for _, e in skids do
		if e.born > 0 then
			local age = (now - e.born) / e.life
			if age >= 1 then
				e.born = 0
				e.part.Transparency = 1
			else
				-- (2026-11-26) full strength for the first half of its life, then a smooth fade out
				local t = math.clamp(age * 2 - 1, 0, 1)
				e.part.Transparency = e.base + (1 - e.base) * t * t * (3 - 2 * t)
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
local function exhaustTips(model: Model, root: BasePart, id: string?): { Vector3 }
	local tips: { Vector3 } = {}
	-- (2026-11-21) an imported model's tips measured from its own model file (ExhaustTips), placed from the skin's box
	-- in root space: { across, up, in } x the skin's length from its middle, lowest and rear-most points (-Z = front)
	local rows = if id then ExhaustTips.tipsOf(id) else nil
	local skin = model:FindFirstChild("Skin")
	if rows and skin then
		local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
		for _, d in skin:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				local cf = root.CFrame:ToObjectSpace(d.CFrame)
				local h = d.Size / 2
				for _, c in { Vector3.new(h.X, h.Y, h.Z), Vector3.new(-h.X, h.Y, h.Z), Vector3.new(h.X, -h.Y, h.Z), Vector3.new(h.X, h.Y, -h.Z), Vector3.new(-h.X, -h.Y, h.Z), Vector3.new(-h.X, h.Y, -h.Z), Vector3.new(h.X, -h.Y, -h.Z), Vector3.new(-h.X, -h.Y, -h.Z) } do
					local p = cf * c
					lo = lo:Min(p)
					hi = hi:Max(p)
				end
			end
		end
		local len = hi.Z - lo.Z
		if len > 4 and len < 80 then
			local midX = (lo.X + hi.X) / 2
			for _, r in rows do
				table.insert(tips, Vector3.new(midX + r[1] * len, lo.Y + r[2] * len, hi.Z - r[3] * len))
			end
			return tips
		end
	end
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

local exhaustSmoke: { [Instance]: { ParticleEmitter } } = {} -- [root] = its tips' smoke (2026-11-21)
local function buildFlames(model: Model, root: BasePart, spec: Cars.CarSpec): ({ ParticleEmitter }, { Instance }, PointLight?)
	local emitters: { ParticleEmitter } = {}
	local parts: { Instance } = {}
	local smokes: { ParticleEmitter } = {}
	exhaustSmoke[root] = smokes
	local tips = exhaustTips(model, root, spec.Id)
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
		-- exhaust smoke: a grey puff that drifts and grows (pops, hard shifts, launches)
		local sm = Instance.new("ParticleEmitter")
		sm.Rate = 0
		sm.Texture = "rbxasset://textures/particles/smoke_main.dds"
		sm.EmissionDirection = Enum.NormalId.Back
		sm.Lifetime = NumberRange.new(0.6, 1.2)
		sm.Speed = NumberRange.new(2, 5)
		sm.SpreadAngle = Vector2.new(25, 25)
		sm.Acceleration = Vector3.new(0, 1.5, 0)
		sm.Drag = 2
		sm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 2.6) })
		sm.Color = ColorSequence.new(Color3.fromRGB(120, 120, 124), Color3.fromRGB(170, 170, 174))
		sm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		sm.LightInfluence = 1
		sm.Parent = att
		table.insert(smokes, sm)
	end
	local glowAtt = Instance.new("Attachment")
	glowAtt.Name = "ExhaustGlow"
	glowAtt.Position = sum / #tips + Vector3.new(0, 0, 0.6)
	glowAtt.Parent = root
	table.insert(parts, glowAtt)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 50)
	light.Range = 12
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	light.Parent = glowAtt
	return emitters, parts, light
end

local function exhaustPop(s: State, strength: number)
	-- (owner, 2026-11-21) flames only on a car tuned for them (CarStats.flameLevel); the Flame Tune's are bigger
	if s.flameLevel <= 0 then
		return
	end
	if s.flameLevel >= 2 then
		strength *= 1.6
	end
	for _, e in s.flames do
		e:Emit(math.max(1, math.floor((4 + math.random() * 4) * strength)))
	end
	for _, e in exhaustSmoke[s.root] or {} do
		e:Emit(math.max(1, math.floor(2 * strength)))
	end
	s.flameGlow = math.max(s.flameGlow, math.min(6, 4.5 * strength)) -- (2026-11-26) capped: every flash ~0.12 s
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
	-- (owner, 2026-11-21: headlights and taillights without bugs, like the real cars): getting out puts every lamp out, for everyone
	s.lampsOut()
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
	UI.showNitroButton(false)
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

-- (2026-11-26, PedHits) a small speed loss: the car keeps share k of its ground speed
function Driving.slowBy(k: number)
	local s = state
	if s then
		s.vel = Vector3.new(s.vel.X * k, s.vel.Y, s.vel.Z * k)
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

-- (2026-11-21, owner: "make it so that when a car goes in water, they get teleported back to the nearest road
-- near the water, facing the roads direction") is this point in Terrain water: its one 4-stud cell
local function wetAt(p: Vector3): boolean
	local c = Vector3.new(math.floor(p.X / 4), math.floor(p.Y / 4), math.floor(p.Z / 4)) * 4
	local mats = workspace.Terrain:ReadVoxels(Region3.new(c, c + Vector3.new(4, 4, 4)), 4)
	return mats[1][1][1] == Enum.Material.Water
end
local roadRay = RaycastParams.new()
roadRay.FilterType = Enum.RaycastFilterType.Include
local roadOverlap = OverlapParams.new()
roadOverlap.FilterType = Enum.RaycastFilterType.Include
-- (same day) the middle of the nearest lane on a DRY road, looking the way that lane drives: of the lane points
-- nearest to `pos`, the first with a built carriageway or deck under it (the 1:1 map's collision boxes, RoadBox
-- "R" / "D") and no water on it. Without lane data: the nearest road box's top, along its long axis. nil = no map
local function roadNear(pos: Vector3): CFrame?
	local map = workspace:FindFirstChild("Yangon1to1")
	local roads = map and map:FindFirstChild("Roads")
	local collide = roads and roads:FindFirstChild("Collide")
	local g = if Config.activeMap() then RivieraTraffic.build() else nil
	if g then
		local list = WaterRescue.candidates(g.lanes, CityLayout.sample, pos, 8, 24)
		for _, c in list do
			local onRoad = true
			if collide then
				roadRay.FilterDescendantsInstances = { collide }
				local h = workspace:Raycast(c.p + Vector3.new(0, 6, 0), Vector3.new(0, -16, 0), roadRay)
				local kind = h and h.Instance:GetAttribute("RoadBox")
				onRoad = kind == "R" or kind == "D"
				if h and onRoad then
					c.p = Vector3.new(c.p.X, h.Position.Y, c.p.Z)
				end
			end
			c.dry = onRoad and not wetAt(c.p + Vector3.new(0, 2, 0))
		end
		local c = WaterRescue.pick(list)
		if c then
			local flat = Vector3.new(c.dir.X, 0, c.dir.Z)
			return if flat.Magnitude > 0.01 then CFrame.lookAt(c.p, c.p + flat.Unit) else CFrame.new(c.p)
		end
	end
	if collide then
		roadOverlap.FilterDescendantsInstances = { collide }
		for _, r in { 300, 1200, 4000 } do
			local best: BasePart?, bd = nil, math.huge
			for _, p in workspace:GetPartBoundsInRadius(pos, r, roadOverlap) do
				local d = (p.Position - pos).Magnitude
				if d < bd and p:GetAttribute("RoadBox") == "R" then
					best, bd = p, d
				end
			end
			if best then
				-- (a road box lies along its road: length on Z, the top on the surface)
				local top = best.Position + best.CFrame.UpVector * (best.Size.Y / 2)
				local look = best.CFrame.LookVector
				return CFrame.lookAt(top, top + Vector3.new(look.X, 0, look.Z).Unit)
			end
		end
	end
	return nil
end

-- (`from`: the road nearest to that point instead of to the car, 2026-11-21: where it went into the water)
function Driving.reset(from: Vector3?)
	local s = state
	if not s then
		return
	end
	-- (on the Monaco map its own lanes; CityLayout only knows the old city's)
	local here = (from or s.root.Position) - Vector3.new(0, 2, 0)
	local cf = roadNear(here) or CityLayout.nearestLaneCFrame(s.root.Position)
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
local function tailsLook(tails: { BasePart }, rearGlow: { any }, lightsOn: boolean, braking: boolean)
	for _, t in tails do
		local off = t:GetAttribute("TailOff") :: number?
		if off then
			-- a glowing copy over the model's own lamp: gone when the lights are off
			t.Color = if braking then TAIL_BRAKE else TAIL_DIM
			t.Transparency = if not lightsOn and not braking then 1 elseif braking then off * 0.3 else off
		else
			-- the lamp itself (our own bodies): darker when off
			t.Color = if braking then TAIL_BRAKE elseif lightsOn then TAIL_DIM else Color3.fromRGB(60, 0, 4)
		end
	end
	for _, g in rearGlow do
		g.Enabled = lightsOn or braking
		g.Brightness = if braking then 2.2 else 0.6
	end
end
local function setTails(s: State)
	tailsLook(s.tails, s.rearGlow, s.lightsOn, s.tailBrake == true)
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
type OtherCar = { model: Model, L: { PointLight }, R: { PointLight }, lights: boolean?, smoke: { ParticleEmitter }, wheels: { OtherWheel }, kitBy: { [BasePart]: OtherWheel }, skinN: number, tails: { BasePart }?, tailN: number?, tailOn: boolean?, tailBrake: boolean?, engine: Audio.Engine?, eRpm: number, eThr: number, eGear: number, eOn: boolean?, eDistT: number }
local others: { [Model]: OtherCar } = {}
-- (2026-11-09) the other players' engines heard at once, and how far (studs)
-- (owner, 2026-11-21: "u can hear ur car sounds only") 4, 2 on a low-end phone (LowEnd.on)
local OTHER_ENGINE_MAX, OTHER_ENGINE_RANGE = 4, 220
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
		-- (owner, 2026-11-21: headlights and taillights without bugs, like the real cars): its tail and brake lamps, as its
		-- driver's game sends them (the same look as your own; no RearGlow lights: too many for a phone)
		local tailN = if skin then #skin:GetChildren() else 0
		local tails = o.tails
		if not tails or o.tailN ~= tailN then
			tails = {}
			o.tails, o.tailN, o.tailOn = tails, tailN, nil
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and d:GetAttribute("TailLight") then
					table.insert(tails, d)
				end
			end
		end
		local tailOn, tailBrake = lights == true, model:GetAttribute("Brake") == true
		if tailOn ~= o.tailOn or tailBrake ~= o.tailBrake then
			o.tailOn, o.tailBrake = tailOn, tailBrake
			tailsLook(tails, {}, tailOn, tailBrake)
		end
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
	for i = 1, math.min(#near, if LowEnd.on then 2 else OTHER_ENGINE_MAX) do
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
	local okMfd, mfdUpdate = pcall(R34Mfd.build, model)
	local flames, flameParts, flameLight = buildFlames(model, root, spec)
	-- (owner, 2026-11-21) exhaust flames + smoke only on supercars and 5 hypercars (the 4 Aventadors, the Revuelto):
	-- ExhaustTips.allowed; every other car keeps them off (they were off for all cars earlier that night)
	if not ExhaustTips.allowed(spec.Id) then
		for _, e in flames do
			e:Destroy()
		end
		for _, e in exhaustSmoke[root] or {} do
			e:Destroy()
		end
		exhaustSmoke[root] = nil
		if flameLight then
			flameLight:Destroy()
		end
		flames, flameLight = {}, nil
	end
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
		mfdUpdate = if okMfd then mfdUpdate else nil,
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
		lampsOut = function() end, -- (set by attach)
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
		flameLevel = 0,
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
	-- (2026-11-21) the skin can arrive after the car: try the exhaust tips again for a few seconds
	if ExhaustTips.allowed(spec.Id) and #flames == 0 then
		task.spawn(function()
			for _ = 1, 6 do
				task.wait(1.5)
				if state ~= s or not root.Parent then
					return
				end
				local f, fp, fl = buildFlames(model, root, spec)
				if #f > 0 then
					s.flames = f
					for _, x in fp do
						table.insert(s.flameParts, x)
					end
					s.flameLight = fl
					s.flameColors = {}
					for _, e in f do
						table.insert(s.flameColors, e.Color)
					end
					return
				end
				for _, x in fp do
					x:Destroy()
				end
			end
		end)
	end
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
	-- (2026-11-26) the tail lamps' red glow on the road behind: one SpotLight aimed down and back from the lamps'
	-- middle (in flameParts so detach takes it away); this car only, off in low-end
	if #s.tails > 0 then
		local sum = Vector3.zero
		for _, t in s.tails do
			sum += root.CFrame:PointToObjectSpace(t.Position)
		end
		local at = sum / #s.tails + Vector3.new(0, -0.2, 0.7) -- behind the bumper: lights the road, not the car
		local att = Instance.new("Attachment")
		att.Name = "TailRoadGlow"
		att.CFrame = CFrame.lookAt(at, at + Vector3.new(0, -1, 0.9))
		att.Parent = root
		local l = Instance.new("SpotLight")
		l.Color = Color3.fromRGB(255, 28, 18)
		l.Range = 14
		l.Angle = 90
		l.Brightness = 0
		l.Shadows = false
		l.Enabled = false
		l.Parent = att
		table.insert(s.flameParts, att)
		s.roadGlow = l
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
		s.flameLevel = CarStats.flameLevel(tune)
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
		UI.showNitroButton(s.nitroOn or DFeel.NitroEnabled)
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
	s.lampsOut = function()
		s.tailBrake = false
		setLights(s, false)
		remote("CarSignals"):FireServer({ blinker = "", lights = false, beam = "off", brake = false, rev = false })
	end
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
	table.insert(s.connections, Frame.Connect(function(dt)
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
local waterState = WaterRescue.new() -- (2026-11-21) the water timer and its cooldown: client/Driving's "in the sea" check
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

-- (2026-11-26) this function lives in the child module Step (the 200,000-character limit)
require(script:WaitForChild("Step"))({ Audio = Audio, CarPhysics = CarPhysics, Config = Config, DashGauges = DashGauges, Driving = Driving, HARD_SURFACE = HARD_SURFACE, LOOSE_SURFACE = LOOSE_SURFACE, Players = Players, RunService = RunService, UI = UI, WaterRescue = WaterRescue, buzz = buzz, cruiseOff = cruiseOff, cruisePedals = cruisePedals, detectCuts = detectCuts, evPull = evPull, exhaustPop = exhaustPop, forwardFromYaw = forwardFromYaw, gearHi = gearHi, gearMul = gearMul, gearsNow = gearsNow, hitMark = hitMark, indicatorState = indicatorState, nitroHeld = nitroHeld, noLiftPops = noLiftPops, noPops = noPops, noShiftPops = noShiftPops, rayParams = rayParams, readInput = readInput, reportCrash = reportCrash, roadOverlap = roadOverlap, roadRay = roadRay, setCarPower = setCarPower, setTails = setTails, skidMark = skidMark, sparks = sparks, torqueCurve = torqueCurve, waterState = waterState, wetAt = wetAt, yawFromLook = yawFromLook, get_state = function() return state end, get_curP = function() return curP end, get_keyThrottle = function() return keyThrottle end })

---------------------------------------------------------------------
-- Render: rig animation + camera
---------------------------------------------------------------------
-- (2026-11-26) this function lives in the child module Render (the 200,000-character limit)
require(script:WaitForChild("Render"))({ Audio = Audio, CameraLook = CameraLook, CarBuilder = CarBuilder, CarLamps = CarLamps, CarStats = CarStats, Config = Config, DUST = DUST, Driving = Driving, GuiService = GuiService, LowEnd = LowEnd, NITRO_FLAME = NITRO_FLAME, SMOKE = SMOKE, SoundService = SoundService, UI = UI, UserInputService = UserInputService, buzz = buzz, camera = camera, exhaustPop = exhaustPop, fadeSkids = fadeSkids, forwardFromYaw = forwardFromYaw, fxQuality = fxQuality, indicatorState = indicatorState, isInTunnel = isInTunnel, lookRay = lookRay, player = player, remote = remote, setLights = setLights, setVignette = setVignette, get_state = function() return state end, get_blur = function() return blur end, get_windDof = function() return windDof end, get_nitroFill = function() return nitroFill end })

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

	-- a driving key, from the keyboard or the phone's buttons (UI.onCarKey: the touch layout's car menu)
	local function driveKey(key: Enum.KeyCode)
		if not state or UI.modalOpen then
			return
		end
		if key == Enum.KeyCode.V then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				Driving.toggleCamera()
			else
				Driving.toggleFirstPerson()
			end
		elseif key == Enum.KeyCode.ButtonY then
			Driving.toggleCamera()
		elseif key == Enum.KeyCode.R then
			-- the radio's next station (Driving Empire's R)
			UI.toast("Radio: " .. Audio.nextStation())
		elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.ButtonSelect then
			Driving.reset()
		elseif Driving.inputEnabled and not UI.isGarageOpen() then
			carKey(state, key)
		end
	end
	UI.onCarKey = driveKey
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed then
			driveKey(input.KeyCode)
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
