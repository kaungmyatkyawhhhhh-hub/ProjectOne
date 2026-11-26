--[[
	CITY LEGENDS - Config.Camera and Config.DrivingFeel
	Moved out of Config.lua (2026-11-26: Studio caps a script at 200,000 characters).
	Config.lua calls this with its table at the same spot, so the load order is unchanged.
]]

return function(Config)
	---------------------------------------------------------------------
	-- Camera
	---------------------------------------------------------------------
	-- (owner, 2026-10-29: "camera and car movement like the video". The sense of speed comes from
	-- the camera's lag, distance, sway, shake and blur, not a big FOV stretch; the cockpit FOV never
	-- changes; the driver's head moves on a spring.)
	Config.Camera = {
		ChaseFov = 70, -- the far chase camera (the Settings FOV slider sets this and Immersive.Fov)
		FovMin = 60, -- the Settings slider's range (outside cameras only)
		FovMax = 90,
		InteriorFov = 64, -- from the driver's seat: 74 + the speed boost made the cabin look stretched (fish-eye)
		InteriorFovBoost = 0, -- owner: the same view in every car at every speed
		MaxFovBoost = 12, -- the far chase camera at top speed (was 32: too fish-eyed)
		ChaseDistance = 17,
		ChaseHeight = 5.2,
		-- the immersive camera (default): low and close behind the car (studs)
		Immersive = {
			Fov = 74,
			FovBoost = 11, -- added at top speed (was 38: up to 112 degrees, fish-eye)
			Distance = 11.5,
			Height = 3.4,
			SpeedPull = 4.5, -- falls back this much more at top speed
			Lag = 4.5, -- the car pulls away on a hard launch, comes closer braking (studs per g)...
			LagResponse = 2.2, -- ...and how fast the camera catches up (per second; lower = more lag)
			Swing = 0.3, -- looks into turns (radians at full lock)
			Buzz = 0.035, -- road shake at top speed (2026-11-03: was 0.09, too much)
			LookAhead = 22,
			LookHeight = 1.6,
			Blur = 4, -- motion blur at top speed (Settings: Motion blur Off turns it off). Lighter since
			-- 2026-11-03 (owner: the game looked grainy): Roblox's blur softens the whole screen
			BlurFrom = 0.5, -- share of the rush where it starts
		},
		-- the low camera (V cycle): about wheel-top height, close, a little to the side, lots of blur
		Low = {
			Fov = 78,
			FovBoost = 8,
			Distance = 10.5,
			Height = 2.1,
			Side = 3.4, -- studs off to the left of the car's centre line
			SpeedPull = 2,
			LookAhead = 26,
			LookHeight = 1.1,
			Blur = 6,
			BlurFrom = 0.4,
		},
		-- the g-forces on the outside cameras (owner, 2026-10-23: dramatic turns, launches and stops)
		Drama = {
			Response = 3, -- how fast it follows the g (per second): back to centre in about half a second
			Side = 2.6, -- studs the camera slides in a hard corner, so the car moves out in the frame...
			SideSpeed = 1.5, -- ...plus this much more at top speed
			Roll = 0.07, -- the camera rolls with the corner (radians per g)...
			MaxRoll = 0.08, -- ...up to about 4.5 degrees
			Pitch = 0.035, -- tips up pulling away, down braking (radians per g)
			AccelFov = 4.5, -- degrees wider at 1 g of pull...
			BrakeFov = 4, -- ...and tighter at 1 g of braking
		},
		-- the driver's head in the cockpit: on a spring, from the real g (Settings: Head movement)
		Head = {
			Response = 6.5, -- spring speed (radians per second, about 1 Hz)...
			Bounce = 0.55, -- ...and its damping (lower bounces more; 1 = none)
			Lean = 0.4, -- studs the head slides to the outside of a turn at 1 g
			Tilt = 0.105, -- the horizon tilts up to about 6 degrees in a hard corner (radians)
			TiltPerG = 0.09,
			Brake = 0.4, -- studs forward and down at full braking...
			BrakePitch = 0.09, -- ...and about 5 degrees nose down (radians)
			Launch = 0.3, -- studs pushed back pulling away
			LookInto = 9, -- degrees the view turns towards where the road goes, at full lock
			-- breathing when slow or parked: a tiny slow rise and fall, gone above FadeMph
			Breath = 0.04,
			BreathPeriod = 3.5,
			BreathFadeMph = 20,
		},
		-- high-speed shake, every camera (Settings: Camera shake): a slow sway built from smooth noise
		-- plus a fine vibration, growing from FromMph to ToMph
		Shake = {
			FromMph = 100,
			ToMph = 190,
			Roll = 0.02, -- up to about 1 degree of slow roll (2026-11-03: was 0.045)...
			Bob = 0.06, -- ...and this many studs up and down (was 0.12)...
			Rate = 0.4, -- ...about every 2.5 s
			Buzz = 0.012, -- the fine vibration (studs; was 0.03)
		},
	}

	---------------------------------------------------------------------
	-- Driving feel (owner, 2026-10-23: "fix the car physics it doesnt feel real, the players need to
	-- feel the rush when their going fast!"). Top speeds and 0-60 times still come from Cars.
	---------------------------------------------------------------------
	Config.DrivingFeel = {
		-- physics
		YawResponse = 6.5, -- how quickly the car's turn follows the wheel (per second): weight, not a rail
		YawResponseHandling = 5, -- extra response times the car's Handling
		SlipPeak = 0.14, -- slip angle (radians, about 8 degrees) where the tyres grip hardest
		SlideGrip = 0.62, -- grip left once a slide goes well past the peak (it keeps sliding)
		-- realistic physics (owner, 2026-11-03: "realistic car physics, like the car gets heavy when going
		-- fast"). Speeds here: 1 stud/s = 0.783 mph, so 1 g = G studs/s^2.
		G = 28,
		-- tyre grip in g: GripBase + GripHandling x the car's Handling, times GameGrip (a little more than
		-- a real car, so it stays fun). Lower GameGrip = slides sooner, heavier feel; higher = more arcade
		GripBase = 0.8,
		GripHandling = 0.4,
		GameGrip = 1.55, -- (2026-11-03: 1.35 felt too heavy, owner)
		Downforce = { Sedan = 0.05, Coupe = 0.1, Supercar = 0.45, Hypercar = 0.6 } :: { [string]: number }, -- extra grip at top speed (grows with speed squared)
		-- weight (CarStats' kerb weight, kg, over WeightRef): the powers say how much it matters
		WeightRef = 1600,
		WeightBrake = 0.2, -- a heavier car stops later
		WeightGrip = 0.1, -- ...grips a little less
		WeightInertia = 0.35, -- ...turns in slower (its turn builds and settles slower; was 0.5)
		WeightBump = 0.6, -- ...and kerbs, landings and crashes throw it about less (a light car bounces more)
		HighSpeedYaw = 400, -- the turn builds half as fast at this many studs/s: no snapping at speed (22 Nov: was 320)
		BrakeTurnIn = 0.25, -- braking loads the front: up to this much more turn-in
		TrailBrakeLoose = 0.35, -- ...and lightens the rear: braking hard mid-corner, the rear can step out
		SquatGrip = 0.3, -- pulling away loads the rear: a rear-drive car spins its tyres a little less
		WetGripLoss = 0.25, -- rain: this share of grip gone
		WetBrakeLoss = 0.15, -- ...and of braking
		-- driving assists (Settings: Off / Low / Normal): how hard a slide past the peak is caught,
		-- and on phones how much steering lock goes at top speed (the drift assist scales too)
		StabilityAssist = 3,
		TouchSteerAssist = 0.3,
		CameraG = 0.35, -- the camera's lean and lag take the g this much (it was tuned to the old scale)
		SteerSlowdown = 300, -- the wheel turns half as fast at this many studs/s (22 Nov, owner: lighter; was 230, 150)
		PowerOversteer = 0.6, -- traction control off: flooring it lets the rear step out this much more
		BumpKick = 0.18, -- body pitch kick (radians/s) per stud of sudden ground change over 0.45 (kerbs, ramps; was 0.5 from 0.18, owner 2026-11-02: the car jerked on every stud)
		LiftEase = 5, -- how fast the body rises to a bump under its wheels (per second; settling back is SettleEase)
		SettleEase = 12,
		-- realistic suspension (owner, 2026-10-24): a spring per wheel. spring: stiffness (its square
		-- root sets how fast the body returns to its ride height); damp: the fastest the body moves up or
		-- down on its springs (studs/s); bump / droop: how far a wheel can move up / down (studs). Soft
		-- and long-travel on SUVs and limousines, firm and short on supercars. HullLift: the body's
		-- collision box starts this far above the road.
		Suspension = {
			Sedan = { spring = 330, damp = 9, bump = 0.55, droop = 0.6 },
			SUV = { spring = 240, damp = 7, bump = 0.8, droop = 0.9 },
			Coupe = { spring = 420, damp = 11, bump = 0.45, droop = 0.5 },
			Supercar = { spring = 560, damp = 13, bump = 0.35, droop = 0.4 },
			Hypercar = { spring = 620, damp = 14, bump = 0.3, droop = 0.35 },
		} :: { [string]: { spring: number, damp: number, bump: number, droop: number } },
		HullLift = 1.3, -- the collision box's bottom over the car's (a small step slides under it; was 0.9)
		RoadTexture = 0.004, -- fine body shimmy at speed (radians)
		BodyRoll = 3.4, -- body lean in a corner (degrees per g, times the class's roll)
		BodyPitch = 3.0, -- nose dive braking / squat pulling away (degrees per g, times the class's pitch)
		-- the steering wheel turns further at parking speeds (degrees each way) and the car's own lock
		-- from LockFadeMph up; the hands re-grip (cross over) past HandReach degrees
		WheelLockSlow = 300,
		LockFadeMph = 40,
		HandReach = 100,
		WheelWobble = 1.2, -- small corrections on the straight at speed (degrees)
		-- the driver's arms: in the cockpit only this share of each arm shows, from the hand back
		-- towards the shoulder (the whole arm came past the camera as a slab, owner 2026-10-17; at
		-- 0.45 its cut end showed in turns, 2026-10-29)...
		CockpitArm = 0.8,
		-- ...and the hand runs this many studs past its grip, round the rim (owner, 2026-10-29: the
		-- end of the hand showed when turning)
		HandPastGrip = 0.3,
		-- sense of speed: these go by real speed, so every car feels fast when it is
		RushFrom = 45, -- mph where the speed effects start...
		RushTo = 190, -- ...and where they're full
		Vignette = 0.35, -- darkened screen edges at full wind (outside cameras; half in the cabin)
		-- the speed effect (owner, 2026-11-03: "realistic wind blur, not cartoon lines"): from this speed
		-- up to the car's top speed the near roadside blurs (depth of field) and the edges darken
		WindFromMph = 75, -- (120 km/h)
		WindFarBlur = 0, -- (21 Nov, owner: "too grainy": Roblox's depth of field is noisy; was 0.35) -- how much the street ahead and the roadside further off blur at top speed (0..1)
		WindStreaks = 0.8, -- the soft streaks at the screen's edge at top speed (0 = none)
		ShiftPunchFov = 3, -- a flat-out upshift at high revs: the view kicks wider for a moment
		ShiftBlur = 1,
		LaunchKickFov = 7, -- a hard launch
		LaunchBlur = 2,
		-- (owner, 2026-11-10) a launch-control start makes no tyre smoke for this long (seconds, or until you lift); press the
		-- brake again with the throttle still down (under BurnArmMph) and it's a burnout: the tyres spin and smoke on the spot
		LaunchClean = 3,
		BurnArmMph = 30,
		NearMissFov = 2.5, -- a close pass on traffic
		RoadRoar = 0.45, -- tyre and road roar at full rush (volume)
		CabinBuzz = 0.025, -- the driver's head buzzes with the road at speed (studs)

		-- physics v2 (owner, 2026-10-23: "the car driving physics improve it"): weight and handling by
		-- class. roll / pitch: body lean; understeer: the nose pushes wide at speed (front-heavy);
		-- shiftTime / upshift / revRate: the gearbox and how quickly the revs move; brake: stopping
		-- power (studs/s^2: about real g x 28 x 1.5, so 100-0 km/h takes ~22-33 m (2026-11-03: a bit lighter); it
		-- was 135-188, which stopped in ~10 m: 2026-11-03); inertia: how slowly the car's turn builds and settles
		ClassFeel = {
			Sedan = { roll = 1, pitch = 1, understeer = 0.12, shiftTime = 0.22, upshift = 0.9, revRate = 12, brake = 42, inertia = 1 },
			SUV = { roll = 1.45, pitch = 1.3, understeer = 0.22, shiftTime = 0.3, upshift = 0.86, revRate = 9, brake = 38, inertia = 1.35 },
			Coupe = { roll = 0.85, pitch = 0.9, understeer = 0.07, shiftTime = 0.16, upshift = 0.93, revRate = 15, brake = 44, inertia = 0.9 },
			Supercar = { roll = 0.6, pitch = 0.7, understeer = 0.04, shiftTime = 0.11, upshift = 0.95, revRate = 19, brake = 48, inertia = 0.8 },
			Hypercar = { roll = 0.6, pitch = 0.55, understeer = 0.03, shiftTime = 0.08, upshift = 0.96, revRate = 22, brake = 50, inertia = 0.75 },
		} :: { [string]: { roll: number, pitch: number, understeer: number, shiftTime: number, upshift: number, revRate: number, brake: number, inertia: number } },
		-- which wheels drive (any car not listed drives the rear wheels)
		FrontDrive = { suzaki_swift = true, toyoka_belta = true, toyoka_camri = true, toyoka_alfard = true } :: { [string]: boolean },
		AllDrive = {
			toyoka_crown = true, kio_ev6 = true, toyoka_lc200 = true, toyoka_lc300 = true, lexis_lx700 = true, bnw_x6 = true, bnw_x7 = true,
			bentz_gle53 = true, bentz_g63 = true, brabos_g63 = true, bentz_gls = true, bentz_cla45 = true, bentz_e63s = true, bnw_m5_f90 = true,
			bentz_s680 = true, byt_u8 = true, xiaomo_su7 = true, porsha_panamera = true, nisun_r34 = true, nisun_gtr = true, audy_r8 = true, audy_r8_lw = true, audy_r8_4s = true,
			lambrini_lp570 = true, lambrini_lp560 = true, lambrini_huracan = true, lambrini_performante = true, lambrini_sterrato = true, lambrini_revuelto = true, lambrini_lp640 = true, lambrini_lp670 = true, lambrini_urusp = true, lambrini_lp700 = true, lambrini_lp750 = true, lambrini_svj = true, lambrini_svj63 = true, lambrini_urus = true,
			bentlee_contgt = true, bentlee_bentayga = true, rolls_cullinan = true, astin_dbx = true, maseroti_levante = true, bugotti_veyron = true,
			bugotti_veyron_sport = true, bugotti_veyron_top = true, bugotti_chiron = true, bugotti_chiron_pursport = true, bugotti_chiron_supersport = true,
			ronin_cp9a = true, ronin_cp9a_champ = true, ronin_ct9a = true, ronin_cz4a = true, pleiad_gc8 = true, pleiad_gdb = true,
		} :: { [string]: boolean },
		FwdUndersteer = 0.3, -- front drive: flooring it in a corner pushes the nose wide
		AwdPowerOversteer = 0.35, -- an all-wheel-drive car gets this share of rear-drive power oversteer
		AwdRearBias = 0.8, -- the same for one that sends more to the rear (Cars `RearBias`: a drift mode feel)
		-- drifting: hold the handbrake into a corner, then balance it on the throttle and steering
		DriftMinMph = 22, -- slower than this it's just a slide
		DriftEnter = 0.2, -- slip angle (radians) that starts a drift
		DriftExit = 0.07, -- ...and below this for DriftHold seconds, it's over
		DriftHold = 0.35,
		DriftGrip = 1.5, -- side grip while drifting on the throttle (lift off and it bites back: x2.2)
		DriftAssist = 2.4, -- countersteer help: the nose is pulled towards where the car is going
		DriftMaxAngle = 0.95, -- past this (radians, about 55 degrees) the assist stops a spin
		-- brakes: anti-lock pulses on a hard stop, and some steering is kept
		AbsPulse = 0.1,
		AbsHz = 14,
		AbsSteer = 0.85,
		-- crashes, scrapes and landings
		CrashJolt = 0.6, -- body kick per 40 studs/s of speed lost in a crash
		ScrapeMinMph = 15, -- rubbing a wall faster than this throws sparks
		ScrapeDrag = 0.6, -- speed lost per second while scraping (share)
		LandKick = 0.03, -- body pitch per stud/s of falling speed on landing
		-- nitro (hold Left Ctrl or B, R1 on a gamepad, the N2O button on a phone); owner (2026-10-23):
		-- "remove nitro", so it's off: no bar, no boost
		NitroEnabled = false,
		NitroTop = 1.15, -- boost pushes the top speed this much past the car's own
		NitroAccel = 34, -- extra pull (studs/s^2)
		NitroDrain = 0.25, -- a full bottle lasts 4 seconds
		NitroFillSpeed = 0.03, -- per second at 140 mph and up (from 60 mph)
		NitroFillPass = 0.08, -- per close pass
		NitroFillIdle = 0.03, -- per second, always (2026-11-06: a fitted bottle refills slowly)
		NitroFillDrift = 0.07, -- per second of drifting
		NitroFov = 10,
		NitroBlur = 1.5,
		-- skid marks (scaled down on phones)
		SkidMax = 240, -- the newest this many strips (phones 120, low-end 60)
		SkidLife = 10, -- seconds before a mark has faded away (26 Nov)

		-- (2026-11-08, Prompts/A million times better wheels (new models).md, Part 2) the two-axle tyre model
		-- (shared/CarPhysics.lua) with each car's real numbers (shared/CarPhysicsData.lua). Enabled = false goes back to
		-- the old single-grip model above
		Axle = {
			Enabled = true,
			-- grip in g = the tyre kind (cup 1.08, sport 1.0, touring 0.9, all-season 0.85) x GameGrip x
			-- (HandlingBase + HandlingK x the car's Handling) x (tyre width / 245 mm) ^ WidthPow. Lower GameGrip = slides
			-- sooner and feels heavier; higher = more grip
			GameGrip = 1.5,
			HandlingBase = 0.75,
			HandlingK = 0.35,
			PartsGrip = 1.6, -- grip parts (tyres): each 0.01 of Handling they add gives this x 1% more grip
			WidthPow = 0.12,
			SlipPeak = 0.12, -- slip angle (radians, ~7 degrees) where the rear tyres grip hardest...
			FrontPeakK = 1.12, -- ...the fronts a little later (a touch of understeer: stable at speed)
			-- (owner, 2026-11-13: "fix cars understeering too much") with the steering help on, the front wheels turn no
			-- further past the car's path than this x the angle where they grip best (full lock used to scrub them at 2.4 x).
			-- 0 = off (the old way); more = the fronts scrub more at full lock (more understeer)
			SteerSlipMax = 1.1,
			SlideGrip = 0.72, -- grip left well past the peak (falls off smoothly, never ice)
			LoadSens = 0.12, -- a tyre with more load grips a little less per kg (weight transfer matters)
			LongGrip = 1.15, -- drive and braking grip over cornering grip (a tyre grips a little more straight ahead)
			SpinGrip = 0.8, -- spinning tyres (no traction control): the push left...
			LockGrip = 0.8, -- ...and locked ones (no ABS, handbrake)
			SlideSide = 0.65, -- a spinning or locked axle loses this share of its cornering grip
			BrakeK = 1, -- the brakes stop each car in its real distance (from 100 km/h, CarPhysicsData.stop) x this
			DownforceK = 2, -- each car's real downforce (kg at 250 km/h) counts this much (planted at speed)...
			ClassDownforce = { Supercar = 0.06, Hypercar = 0.1 } :: { [string]: number }, -- ...plus this (g at 250 km/h)
			-- (2026-11-08, Prompts/RWD cars slide more (and more with TCS off).md) rear-wheel drive only: how far past its
			-- grip the engine may push the rear before traction control cuts in (On / Sport), and how much it spins (0..1:
			-- more = less side grip left, more slide). Off: no limit. More = slides more
			RwdReservePer = 180, -- floored in a low gear (traction control Sport / off) a rear-drive car's engine asks its
			-- rear tyres for 1 + (hp per tonne / this - 1) x their grip...
			RwdReserveMax = 2.8, -- ...up to this much (more = spins up easier: donuts, power slides)
			RwdSlideOn = 1.12, -- On: a few degrees, then caught
			-- (owner, 2026-11-13: "fix some cars losing too much traction even when its not tuned") traction control On
			-- in a corner: a driven tyre keeps this share of the side grip it is using (the engine is held back for it);
			-- 0 = the old way (floored mid-corner, the driven tyres had almost no side grip left). Floor: the least share
			-- of its drive grip the engine always gets (so the car still pulls out of a corner)
			TcCornerKeep = 1,
			TcCornerFloor = 0.3,
			RwdSpinOn = 0.35,
			RwdSlideSport = 1.8, -- Sport: a clear slide, donuts
			RwdSpinSport = 1,
			RwdSpinOff = 1, -- Off: spins up freely (power oversteer, drifts, donuts)...
			-- ...but only on drift tyres (owner, 2026-11-10: "the cars are slipping too much when tcs is off and just make it
			-- slip like that when drift tires are installed"). Off on any other tyres: the rear may go this far past its grip
			-- (Sport's room, with no traction control cutting in), stability control stays in at Sport, and the countersteer
			-- help stays full. More = slides more
			RwdSlideOffGrip = 1.5,
			RwdSpinOffGrip = 0.75,
			RwdSpinSide = 0.6, -- the side grip a fully spinning rear loses on top (Sport / Off; more = slides further)
			DonutBelow = 45, -- studs/s (35 mph): under this a spinning rear may swing round (the countersteer help stays out)
			HelpTcOff = 0.7, -- the countersteer help with traction control off (rear-drive)
			EscSportFrom = 42, -- studs/s (33 mph): Sport stability control only above this (rear-drive: donuts)
			AbsOffSqueeze = 1.6, -- ABS off: a full pedal asks this much more than the brakes need (the wheels lock)...
			LockStop = 0.72, -- ...and locked front wheels stop the car this share as well as the anti-lock does (longer stops)
			ReserveMax = 2.2, -- the most a powerful car's engine can overpower its tyres in the low gears (traction off)
			KinFrom = 3, -- slower than this (studs/s) the car just goes where its wheels point...
			KinTo = 12, -- ...blended in up to here
			-- countersteer help (Settings, on for everyone but "Pro"): the front wheels follow the slide
			HelpK = 1,
			HelpMax = 0.45, -- radians at most (26 degrees)
			HelpYaw = 3, -- ...and a car turning further into its slide is slowed in its turn (per second)
			-- stability control: On / Sport
			EscUnder = 0.00006, -- how much the asked-for turn shrinks with speed (understeer gradient)
			EscTol = 0.06, -- yaw-rate error allowed (radians/s): On...
			EscTolSport = 0.25, -- ...Sport (small slides)
			EscGain = 9,
			EscBeta = 0.14, -- the body's slip angle it holds (radians): On (8 degrees)...
			EscBetaSport = 0.38, -- ...Sport (22 degrees)
			-- grip by the surface under each axle (Roblox material names; 1 = dry asphalt). Kerbs and painted lines
			-- by part name. Rally tyres (parts) lift the loose ones
			Surface = {
				Asphalt = 1,
				Concrete = 0.98,
				Pavement = 0.97,
				Slate = 0.95,
				Basalt = 0.95,
				Limestone = 0.94,
				Brick = 0.92,
				Cobblestone = 0.9,
				CrackedLava = 0.9,
				Wood = 0.85,
				WoodPlanks = 0.85,
				Grass = 0.55,
				LeafyGrass = 0.55,
				Ground = 0.6,
				Mud = 0.5,
				Sand = 0.5,
				Sandstone = 0.85,
				Rock = 0.8,
				Pebble = 0.62,
				Snow = 0.4,
				Glacier = 0.25,
				Ice = 0.2,
			} :: { [string]: number },
			KerbGrip = 0.88,
			PaintGrip = 0.94,
			-- feel
			KeyThrottleRamp = 6, -- keyboard throttle: 0 -> full in about a sixth of a second (per second)
			RevBounce = 0.06, -- the rev limiter: the cut's depth (share of the revs)
			SpinRedline = 0.45, -- driven tyres spinning this much (0..1) with the throttle down: the revs run to the limiter (donuts, burnouts)
			TorqueSteer = 0.012, -- front-drive: a gentle pull (radians) on a hard launch
		},
	}
end
