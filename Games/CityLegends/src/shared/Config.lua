--[[
	CITY LEGENDS - shared configuration
	Every tunable number in the game lives here.
]]

local Config = {}

-- 1 stud ~= 0.35 m  ->  1 stud/s ~= 0.783 mph
Config.STUDS_TO_MPH = 0.783

function Config.mphToSps(mph: number): number
	return mph / Config.STUDS_TO_MPH
end

function Config.spsToMph(sps: number): number
	return sps * Config.STUDS_TO_MPH
end

---------------------------------------------------------------------
-- City layout
---------------------------------------------------------------------
Config.City = {
	Blocks = 6, -- blocks per side (roads = Blocks + 1 per axis)
	BlockSize = 300, -- distance between road centre lines
	LaneWidth = 16, -- owner (2026-10-22): "the road is too small" (was 12)
	LanesPerSide = 2,
	SidewalkWidth = 10,
	CurbHeight = 0.6,
	OuterRingDepth = 260, -- skyline ring of buildings around the grid

	-- Highway that leaves the city to the east, runs through the tunnel and joins the Legends Loop
	HighwayLanesPerSide = 3,
	TunnelStart = 1300, -- measured from the city edge
	TunnelLength = 600,
	-- the Legends Loop (owner, 2026-10-17: "make the highway very long and slowly loops around
	-- the map"): a 6-lane ring road round the city and the harbour, a rounded square with long,
	-- gentle corners (about 24,000 studs, 8 km, a lap)
	LoopHalf = 3300, -- from the city centre to the loop's centre line
	LoopCorner = 1300, -- corner radius
	HighwaySpeedK = 1.7, -- traffic drives this much faster on the highway
}

Config.City.RoadWidth = Config.City.LaneWidth * Config.City.LanesPerSide * 2
Config.City.HalfExtent = Config.City.Blocks * Config.City.BlockSize / 2
Config.City.HighwayWidth = Config.City.LaneWidth * Config.City.HighwayLanesPerSide * 2

-- knocking props over (owner, 2026-10-23: "when u crash into light poles, trees, lamp, traffic
-- lights make it fall down like a real life physics but it will return on its own later")
Config.Knock = {
	Enabled = true,
	MinMph = 12, -- slower than this you just bump it
	Push = 0.35, -- how hard the car shoves it (x its mass x your speed)
	RestoreSeconds = 40, -- it stands back up after this, once no car is right beside it
}

-- Studio play tests only (RunService:IsStudio()): every player starts with everything unlocked
-- and this much cash (owner, 2026-10-23)
Config.Testing = {
	StudioUnlockAll = true,
	StudioCash = 50000000,
}

-- the luxury towers' garages (Garages, Parking): paid VIP bays at the entrance and parked cars in
-- the basement you can steal (owner, 2026-10-23)
Config.Parking = {
	VipFee = 500, -- charged when you leave your car in a VIP bay (no cash: it's towed)
	ParkedPerGarage = 8, -- parked cars in each basement
	Tiers = { "Starter", "Mid" }, -- the kinds of car parked there
	StealHold = 2.5, -- seconds to hold E to break in
	StealStars = 1, -- police stars for a theft
	RefillSeconds = { 90, 180 }, -- a stolen car's bay gets a new random car after this long
}

-- where players start (owner, 2026-10-23: "make block_3_2 near streetscape the players spawn"): a
-- first car comes out on the street along this side of the block, and a player on foot with no car
-- stands up on its sidewalk, by the streetscape
Config.Spawn = {
	Block = { 3, 2 }, -- the Needle's block
	Side = Vector3.new(0, 0, 1), -- its edge on the city's middle road
	FrontRange = 22, -- a car called on foot comes out up to this far in front of you, if there is room
}
-- the east highway runs from the city's edge to the loop's inner edge
Config.City.HighwayLength = Config.City.LoopHalf - Config.City.HighwayWidth / 2 - (Config.City.HalfExtent + Config.City.RoadWidth / 2)

---------------------------------------------------------------------
-- Graphics / city detail. Turn things off here for low-end devices.
---------------------------------------------------------------------
Config.Graphics = {
	PremiumBuildings = true, -- setback towers, fins, lit crowns, lobbies
	Landmarks = true, -- Legends Tower, Twist Tower, Needle
	StreetDetail = true, -- trees, benches, bus stops, hydrants, steam vents
	WetRoads = true, -- glossy rain-soaked asphalt
	Water = true, -- harbour around the city (terrain water) + clouds
	Monorail = true, -- elevated train looping the skyline
	Searchlights = true, -- sweeping sky beams on the landmarks
}

Config.Monorail = {
	Offset = 9, -- distance outside the perimeter road edge
	Height = 48,
	CornerRadius = 40,
	Speed = 95,
	Cars = 4,
	CarLength = 26,
}

---------------------------------------------------------------------
-- Traffic lights (seconds)
---------------------------------------------------------------------
Config.Lights = {
	Green = 9,
	Yellow = 2.5,
	AllRed = 1.5,
}
Config.Lights.Cycle = (Config.Lights.Green + Config.Lights.Yellow + Config.Lights.AllRed) * 2

---------------------------------------------------------------------
-- NPC traffic
---------------------------------------------------------------------
Config.Traffic = {
	CarCount = 55,
	MinSpeedMph = 28,
	MaxSpeedMph = 48,
	TurnSpeedMph = 22,
	Accel = 28, -- studs/s^2
	Brake = 70,
	EmergencyBrake = 140,
	StopGap = 4, -- studs left between bumpers in a queue
	LookAhead = 70,
	RecycleDistance = 700,
	RespawnMin = 220,
	RespawnMax = 520,
	StuckTime = 6,
	-- Weighted pick of classes used for NPCs
	ClassWeights = { Sedan = 40, SUV = 25, Coupe = 18, Supercar = 6, Hypercar = 2 },
}

---------------------------------------------------------------------
-- Economy
---------------------------------------------------------------------
Config.Economy = {
	StartingCash = 5000,
	DriveMinMph = 40, -- passive income only above this speed
	DrivePerSecond = 1 / 18, -- $ per mph per second ( 90mph -> $5/s )
	CutBase = 120,
	CutMinMph = 55,
	ComboWindow = 4.5,
	ComboStep = 0.25, -- +25% per combo level
	ComboMax = 12,
	CutCooldown = 0.18,
	OncomingBonus = 1.6,
	ThreadBonus = 2.5,
	NearMissGap = 5, -- studs of free space that still counts as a cut
}

---------------------------------------------------------------------
-- Progression: XP + levels (earned alongside cash) and the daily gift
---------------------------------------------------------------------
Config.Progression = {
	XpBase = 40, -- XP needed for level 1 -> 2
	XpExponent = 1.35, -- XP needed = XpBase * level ^ XpExponent
	MaxLevel = 999,
	DriveXpPerSecond = 1 / 90, -- XP per mph per second ( 90mph -> 1 XP/s )
	CutXpPerCash = 1 / 30, -- a cut-up gives this much XP per $ it paid
	CutXpMax = 60, -- cap on XP from a single cut-up
	LevelUpCashBase = 500, -- cash reward on reaching a level:
	LevelUpCashPerLevel = 250, --   base + perLevel * newLevel
}

Config.Daily = {
	Cooldown = 24 * 60 * 60, -- seconds between daily gifts
	Cash = 2000, -- daily gift: Cash + CashPerLevel * (level - 1)
	CashPerLevel = 150,
}

-- XP needed to go from `level` to `level + 1`
function Config.xpForLevel(level: number): number
	local P = Config.Progression
	return math.max(1, math.floor(P.XpBase * math.max(1, level) ^ P.XpExponent + 0.5))
end

-- cash paid when the player reaches `level`
function Config.levelReward(level: number): number
	local P = Config.Progression
	return math.floor(P.LevelUpCashBase + P.LevelUpCashPerLevel * level)
end

-- cash in the daily gift for a player at `level`
function Config.dailyReward(level: number): number
	local D = Config.Daily
	return math.floor(D.Cash + D.CashPerLevel * (math.max(1, level) - 1))
end

---------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------
Config.Camera = {
	ChaseFov = 70,
	InteriorFov = 64, -- from the driver's seat: 74 + the speed boost made the cabin look stretched (fish-eye)
	InteriorFovBoost = 0, -- owner: the same view in every car at every speed (the outside camera still widens)
	MaxFovBoost = 32,
	ChaseDistance = 17,
	ChaseHeight = 5.2,
	-- the immersive camera (default): low and close behind the car (studs)
	Immersive = {
		Fov = 74,
		FovBoost = 38, -- added at top speed: the view stretches the faster you go
		Distance = 11.5,
		Height = 3.4,
		SpeedPull = 2.5, -- pulled back a little more at speed
		Lag = 3.2, -- thrown back on hard launches, forward under braking (studs per g)
		Swing = 0.3, -- looks into turns (radians at full lock)
		Buzz = 0.09, -- road shake at top speed
		LookAhead = 22,
		LookHeight = 1.6,
		Blur = 4,
	},
	-- the g-forces on the camera (owner, 2026-10-23: dramatic turns, launches and stops)
	Drama = {
		Response = 4, -- how fast it follows the g (per second)
		Side = 1.6, -- studs the outside camera slides out of a full-lock turn (more with speed)
		Roll = 0.1, -- bank into the turn (radians per g)...
		MaxRoll = 0.15, -- ...up to about 9 degrees
		Pitch = 0.04, -- tips up pulling away, down braking (radians per g)
		AccelFov = 8, -- degrees wider at 1 g of pull...
		BrakeFov = 6, -- ...and tighter at 1 g of braking
		Cabin = 0.3, -- how much of it the driver's-seat view gets (kept steady and readable)
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
	Downforce = { Supercar = 0.35, Hypercar = 0.5 } :: { [string]: number }, -- extra grip at top speed
	SteerSlowdown = 150, -- the wheel turns half as fast at this many studs/s (calm at speed)
	PowerOversteer = 0.6, -- traction control off: flooring it lets the rear step out this much more
	BumpKick = 0.5, -- body pitch kick (radians/s) per stud of sudden ground change (kerbs, ramps)
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
	HullLift = 0.9,
	RoadTexture = 0.004, -- fine body shimmy at speed (radians)
	-- sense of speed: these go by real speed, so every car feels fast when it is
	RushFrom = 45, -- mph where the speed effects start...
	RushTo = 190, -- ...and where they're full
	Vignette = 0.5, -- darkened screen edges at full rush (outside cameras; half in the cabin)
	ShiftPunchFov = 3, -- a flat-out upshift at high revs: the view kicks wider for a moment
	ShiftBlur = 3,
	LaunchKickFov = 7, -- a hard launch
	LaunchBlur = 6,
	NearMissFov = 2.5, -- a close pass on traffic
	RoadRoar = 0.45, -- tyre and road roar at full rush (volume)
	CabinBuzz = 0.025, -- the driver's head buzzes with the road at speed (studs)

	-- physics v2 (owner, 2026-10-23: "the car driving physics improve it"): weight and handling by
	-- class. roll / pitch: body lean; understeer: the nose pushes wide at speed (front-heavy);
	-- shiftTime / upshift / revRate: the gearbox and how quickly the revs move; brake: stopping
	-- power (studs/s^2); inertia: how slowly the car's turn builds and settles
	ClassFeel = {
		Sedan = { roll = 1, pitch = 1, understeer = 0.12, shiftTime = 0.22, upshift = 0.9, revRate = 12, brake = 150, inertia = 1 },
		SUV = { roll = 1.45, pitch = 1.3, understeer = 0.22, shiftTime = 0.3, upshift = 0.86, revRate = 9, brake = 135, inertia = 1.35 },
		Coupe = { roll = 0.85, pitch = 0.9, understeer = 0.07, shiftTime = 0.16, upshift = 0.93, revRate = 15, brake = 160, inertia = 0.9 },
		Supercar = { roll = 0.6, pitch = 0.7, understeer = 0.04, shiftTime = 0.11, upshift = 0.95, revRate = 19, brake = 178, inertia = 0.8 },
		Hypercar = { roll = 0.45, pitch = 0.55, understeer = 0.03, shiftTime = 0.08, upshift = 0.96, revRate = 22, brake = 188, inertia = 0.75 },
	} :: { [string]: { roll: number, pitch: number, understeer: number, shiftTime: number, upshift: number, revRate: number, brake: number, inertia: number } },
	-- which wheels drive (any car not listed drives the rear wheels)
	FrontDrive = { suzaki_swift = true, toyoka_belta = true, toyoka_camri = true, toyoka_alfard = true } :: { [string]: boolean },
	AllDrive = {
		toyoka_crown = true, kio_ev6 = true, toyoka_lc200 = true, toyoka_lc300 = true, lexis_lx700 = true, bnw_x6 = true, bnw_x7 = true,
		bentz_gle53 = true, bentz_g63 = true, brabos_g63 = true, bentz_gls = true, bentz_cla45 = true, bentz_e63s = true, bnw_m5_f90 = true,
		bentz_s680 = true, byt_u8 = true, xiaomo_su7 = true, porsha_panamera = true, nisun_r34 = true, nisun_gtr = true, audy_r8 = true,
		lambrini_lp570 = true, lambrini_lp640 = true, lambrini_lp700 = true, lambrini_lp750 = true, lambrini_urus = true,
		bentlee_contgt = true, bentlee_bentayga = true, rolls_cullinan = true, astin_dbx = true, maseroti_levante = true, bugotti_veyron = true,
	} :: { [string]: boolean },
	FwdUndersteer = 0.3, -- front drive: flooring it in a corner pushes the nose wide
	AwdPowerOversteer = 0.35, -- an all-wheel-drive car gets this share of rear-drive power oversteer
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
	NitroFillDrift = 0.07, -- per second of drifting
	NitroFov = 10,
	NitroBlur = 2.5,
	-- skid marks (scaled down on phones)
	SkidMax = 140,
	SkidLife = 7,
}

---------------------------------------------------------------------
-- Sounds
-- The game ships with a full built-in soundscape (engine, wind, tyres,
-- cut-ups, crashes, backfires, UI, ambience) made from audio inside the
-- Roblox client, so it always works. On top of that the ids below are real
-- recordings from the Creator Store (all checked: audio + public domain).
-- Every id is test-loaded at startup and only used if it loads; anything that
-- fails falls back to the built-in sound. Swap in your own ids any time.
---------------------------------------------------------------------
Config.Sounds = {
	-- engine set by the verified "Roblox Resources" group (public domain)
	Engine = "rbxassetid://80317022777602", -- Car-Engine-Loop (pitch follows RPM)
	EngineStart = "rbxassetid://78270463799678", -- Engine-Start
	-- per-car engines (verified creators); a car without one uses Engine above
	Engine_ferrara_458 = "rbxassetid://130398079560929", -- "Ferrari Engine", Roblox Sim Racing League
	-- ProSoundEffects (Roblox's official SFX partner, public domain)
	Crash = { "rbxassetid://9116546593", "rbxassetid://9116546326" }, -- Metal Crash 4 / 2
	TyreSqueal = "rbxassetid://9120399077", -- Vehicle Skids Long Heavy Tire Squeal 3
	CutUp = "rbxassetid://9126229255", -- Whoosh By Fast Airy Swooshing
	PassBy = "rbxassetid://9113003539", -- Race Car Pass By (cutscene)
	Impact = "rbxassetid://9120769331", -- Sonic Boom Low End Impact (title hit)
	-- night-drive playlist from Roblox's licensed music partners (public domain)
	Music = {
		"rbxassetid://140215257631273", -- Eclipse Drift (DistroKid)
		"rbxassetid://139904111224548", -- Urban Mirage - Night Drive Edit (DistroKid)
		"rbxassetid://140486290054589", -- Insert Coin (DistroKid)
		"rbxassetid://138826080188438", -- Escape the Night (DistroKid)
		"rbxassetid://1842960025", -- Infinite Void (APM)
	},
	MusicVolume = 0.22,
	-- per-car exhaust sets (owner's uploads): Exhaust_<car id>_<Start | Idle | Mid | High | Launch |
	-- Crackle | Redline>. Idle / Mid / High are loops blended by rpm; a car with them uses these
	-- instead of the shared engine sound (owner, 2026-10-22: the LP750 first, as a test)
	Exhaust_lambrini_lp750_Start = "rbxassetid://70853763868958",
	Exhaust_lambrini_lp750_Idle = "rbxassetid://91209556236511",
	Exhaust_lambrini_lp750_Mid = "rbxassetid://70783605428332",
	Exhaust_lambrini_lp750_High = "rbxassetid://132442120648563",
	Exhaust_lambrini_lp750_Launch = "rbxassetid://100034849111835",
	Exhaust_lambrini_lp750_Crackle = "rbxassetid://128716617727916",
	Exhaust_lambrini_lp750_Redline = "rbxassetid://15989284563", -- owner, 2026-10-22: new redline
	-- police and the bank (verified creators / ProSoundEffects)
	Siren = "rbxassetid://9056622054", -- Yelp-Police-Siren (loops)
	CameraFlash = "rbxassetid://9113678227", -- Camera Shutter 1 (SFX)
	Alarm = "rbxassetid://9113084849", -- Alarm Bell Constant Ring (SFX)
}

---------------------------------------------------------------------
-- Police and speed cameras (owner, 2026-10-22: limit 120 km/h, the police chase you)
---------------------------------------------------------------------
Config.Police = {
	SpeedLimitKmh = 120,
	CameraGraceKmh = 3, -- flashed above 123 km/h
	CameraRange = 42, -- studs from the camera
	CameraCooldown = 12, -- seconds before the same camera flashes you again
	CameraFine = 500,
	FinePerKmh = 25,
	CameraStars = 1,
	CityCameraEvery = 7, -- one camera per this many long city lanes
	LoopCameras = 6, -- pairs round the Legends Loop
	-- owner (2026-10-23): "there is too many police cars", "add a timer when the police will stop
	-- chasing and u get like a little bit of money"
	Patrols = 2, -- patrol cars around you when you're not wanted
	UnitsPerStar = 0.5, -- chasing units: 1 + half the stars, rounded down (max 3)
	MaxUnits = 3,
	ChaseSeconds = { 40, 50, 60, 70, 80 }, -- a chase gives up this long after it started (per star)
	PatrolMph = 38,
	ChaseMph = { 105, 125, 150, 175, 200 }, -- top chase speed per star
	SpotRange = 90, -- a patrol sees you speeding this close
	-- owner (2026-10-24): "make police cars like traffic and not crash into you. just show like a
	-- text and there will be a zone near the player. if they dont get out of the zone in 10 seconds
	-- then they get caught"
	ZoneTrigger = 90, -- a chasing police car this close (and in sight) throws a zone round you
	ZoneRadius = 70, -- the zone's size (studs from where you were)
	ZoneSeconds = 10, -- out of it in time or you're caught
	ZoneCooldown = 5, -- after you get out, this long before the next one
	LoseRange = 300, -- out of sight and this far from every unit...
	LoseSeconds = { 9, 11, 13, 15, 18 }, -- ...for this long per star: escaped
	MinChaseSeconds = 12,
	EscapeBounty = { 400, 800, 1500, 2500, 4000 }, -- a little money for getting away
	EscapeXp = 60,
	BustedFineFrac = 0.1, -- owner (2026-10-22): caught = 10% of the cash you have, no cap
	BustedFineMin = 0,
	BustedFineMax = math.huge,
	RamCooldown = 6,
	EscalateSeconds = 75, -- a chase this long adds a star...
	EscalateMax = 3, -- ...up to here
	CarId = "toyoka_crown", -- the police car's body
}

---------------------------------------------------------------------
-- The bank robbery (owner, 2026-10-22: "add a bank which u can rob")
---------------------------------------------------------------------
Config.Bank = {
	Block = { 1, 2 }, -- the city block the bank stands on
	Dropoff = { 6, 0 }, -- intersection whose corner has the drop-off
	CrackSeconds = 8, -- hold E at the vault door
	GrabSeconds = 2.5, -- hold E at a cash cart
	GrabsPerCart = 3,
	GrabMin = 6000,
	GrabMax = 11000, -- times 1 + 2% per level (up to level 50)
	MaxLoot = 60000, -- one bag
	Stars = 4,
	OpenSeconds = 90, -- the vault stays open
	CooldownSeconds = 300, -- then stays locked this long
	DropoffRadius = 22,
	DeliverXp = 400,
}

---------------------------------------------------------------------
-- Things to do: time-trial races, delivery jobs, Legends chips
---------------------------------------------------------------------
Config.Activities = {
	GoldMph = 80, -- average speed over the route for each medal
	SilverMph = 66,
	BronzeMph = 52,
	RaceRewards = { Gold = 9000, Silver = 5000, Bronze = 2500, Finish = 1000 },
	RaceXp = { Gold = 300, Silver = 180, Bronze = 100, Finish = 50 },
	CheckpointRadius = 26,
	JobMinDistance = 900, -- studs between dispatch and drop
	JobMph = 42, -- the time limit allows this average speed (+ JobGrace s)
	JobGrace = 25,
	JobPayPerStud = 7,
	JobTimeBonus = 40, -- per second left
	ChipCount = 25,
	ChipCash = 2500,
	ChipAllBonus = 100000,
}

---------------------------------------------------------------------
-- UI theme (dark)
---------------------------------------------------------------------
-- (owner, 2026-10-24: a studio-made look: graphite glass panels, one refined blue, gold for
-- levels and rewards, a softer money green; it was neon cyan and hot pink)
Config.Theme = {
	Background = Color3.fromRGB(8, 9, 12),
	Panel = Color3.fromRGB(15, 16, 21),
	PanelLight = Color3.fromRGB(28, 30, 38),
	Stroke = Color3.fromRGB(70, 75, 90),
	Text = Color3.fromRGB(242, 243, 247),
	SubText = Color3.fromRGB(150, 155, 170),
	Accent = Color3.fromRGB(80, 168, 255),
	Accent2 = Color3.fromRGB(255, 186, 64),
	Money = Color3.fromRGB(96, 228, 146),
	Warning = Color3.fromRGB(255, 184, 0),
	Danger = Color3.fromRGB(255, 72, 72),
}

---------------------------------------------------------------------
-- Car stock market (owner, 2026-10-22: a car stocks marketplace like the Flip Rush market).
-- Cars trade as collectible stock: buying a unit doesn't give you the car (a Showroom unit can
-- be taken delivery of). Prices are the server's: a random walk round each car's base value.
---------------------------------------------------------------------
Config.Market = {
	TickSeconds = 15, -- prices move this often
	History = 40, -- price points kept per car (sparklines)
	BaseK = 0.75, -- a Clean unit's base value, as a share of the car's dealer price
	MinBase = 4000, -- floor for cheap cars (the free starter)
	Volatility = 0.035, -- random move per tick (share of the price)
	Revert = 0.05, -- pull back towards the base value per tick
	Floor = 0.35, -- prices stay between these shares of the base value
	Ceiling = 3.5,
	-- condition: value multiplier and the tag colour on the cards
	Conditions = {
		{ Id = "Barn", Name = "Barn find", Mult = 0.45, Color = Color3.fromRGB(178, 120, 74) },
		{ Id = "Driven", Name = "Driven", Mult = 0.75, Color = Color3.fromRGB(150, 156, 172) },
		{ Id = "Clean", Name = "Clean", Mult = 1.0, Color = Color3.fromRGB(96, 196, 255) },
		{ Id = "Showroom", Name = "Showroom", Mult = 1.35, Color = Color3.fromRGB(122, 255, 170) },
	},
	Listings = 6, -- cars for sale in your market at a time
	ListingSpread = { 0.82, 1.22 }, -- asking price vs market value (some deals, some rip-offs)
	ListingRotate = 2, -- listings replaced on each price tick
	StashSlots = 32,
	Fee = 0.14, -- selling to the market (Stalls); drops with hype
	FeePerHype = 0.01,
	MinFee = 0.04,
	HypeMax = 10,
	HypeFlip = 0.25, -- a flip this profitable (share of what you paid) adds a hype point
	HypeDecayMinutes = 30, -- one hype point fades after this long without a good flip
	-- hold BUY to lowball: the chance it works and the discount, else the seller walks
	LowballChance = 0.35,
	LowballChancePerHype = 0.03,
	LowballMaxChance = 0.7,
	LowballDiscount = { 0.1, 0.3 },
	-- NPC buyers offering on your stash (no fee on an offer)
	OfferEvery = { 25, 60 }, -- seconds
	OfferSpread = { 0.85, 1.3 },
	OfferPerHype = 0.02,
	OfferLasts = 30, -- seconds
	-- daily requests: a buyer wants a car in a condition (or better) and pays a premium
	Requests = 3,
	RequestPremium = { 1.4, 1.8 },
	-- news moves a brand or class up or down for a few ticks
	NewsEvery = { 90, 150 }, -- seconds
	NewsImpact = { 0.06, 0.25 }, -- total move, spread over NewsTicks
	NewsTicks = 6,
	-- Flip-off vs Slick Vinny: out-earn him in 3 minutes
	FlipOffSeconds = 180,
	FlipOffPrize = 15000, -- plus a share of your stash value (capped)
	FlipOffPrizeShare = 0.02,
	FlipOffPrizeCap = 400000,
	FlipOffCooldown = 120,
	-- market-only cars (F430 and up): a share of listings are the ones you could unlock next
	-- market-only cars (owner, 2026-10-22: "make the high cars harder to get in the market"): rare
	-- listings, rarely in Showroom condition (the only one that can be delivered), mostly over value
	UnlockListingChance = 0.08,
	UnlockShowroomChance = 0.15,
	HighShowroomKeep = 0.2, -- of the Showroom rolls a market-only car gets, this share stays Showroom
	HighListingSpread = { 0.95, 1.6 },
}

---------------------------------------------------------------------
-- Luxury towers (owner, 2026-10-22: "towers that u can go inside and penthouse stuffs like
-- larping rich people", GTA 5 style, no alcohol). Each tower has a walk-in lobby, a penthouse at
-- the top (real floors, so the windows show the city) and a roof with a sky pool and a helipad.
-- Anyone can visit; buying one gives the daily rent from the wall safe, a home spawn and your name
-- on the residents' plaque. block = city block (i, j), height = studs to the roof.
---------------------------------------------------------------------
Config.Towers = {
	List = {
		{ id = "aurum", name = "AURUM RESIDENCES", block = { 2, 3 }, height = 300, price = 750000, rent = 12000, accent = Color3.fromRGB(255, 196, 92) },
		{ id = "skyline", name = "SKYLINE ONE", block = { 4, 1 }, height = 380, price = 3000000, rent = 45000, accent = Color3.fromRGB(0, 229, 255) },
		{ id = "crown", name = "THE CROWN", block = { 1, 4 }, height = 460, price = 12000000, rent = 160000, accent = Color3.fromRGB(190, 110, 255) },
	},
	RentCooldown = 24 * 3600, -- the wall safe refills once a day
}

---------------------------------------------------------------------
-- The west (owner, 2026-10-22): a coastal highway from the city over a river on a suspension
-- bridge to a Miami / New York style Downtown on the beach, and private islands offshore.
-- The world runs west (-X) along z = 0. Positions are x values unless said. WestLayout (shared)
-- turns these into sites, plots and places.
---------------------------------------------------------------------
Config.West = {
	-- the viaduct: up off the city's west edge, over the harbour, the suburbs and the loop, down in
	-- the countryside (deck top at ViaductY)
	ViaductY = 34,
	ViaductUp = { -990, -1290 }, -- rises between these
	ViaductDown = { -3440, -3740 }, -- falls between these
	CorridorHalf = 170, -- trees, houses and mountains stay this far either side of the road
	Canyon = { -4420, -5300 }, -- the cut through the mountain range
	River = { -5500, -6200 }, -- banks
	BridgeUp = { -5300, -5580 }, -- the deck rises between these
	BridgeTowers = { -5640, -6060 },
	BridgeDown = { -6120, -6420 },
	DeckY = 40,
	DowntownX = -7400, -- the centre of Downtown's street grid (6 x 6 blocks like the city)
	IndexBase = 100, -- Downtown's road indices along x: i = 100 .. 106 (j is the city's 0 .. 6)
	DowntownRing = 300, -- skyline blocks round Downtown (north, south, east)
	BeachWest = -8560, -- sand from Ocean Drive to here, then the sea
	SeaWest = -12600,
	HalfZ = 2700, -- the west's north / south edges
	CausewayY = 6, -- the causeway's deck over the sea
	-- block sites in Downtown {bi, bj, the side the entrance faces: "N" -Z, "S" +Z, "E" +X, "W" -X}
	Sites = {
		hotel = { 100, 2, "S" }, -- on Ocean Drive, facing Legends Boulevard (z = 0)
		casino = { 100, 3, "N" }, -- across the boulevard from the hotel
		gems = { 102, 3, "N" }, -- the gem showcase, up the boulevard
	},
	-- private islands offshore (centre x, z, radius); Legends Key is on the causeway, the other two
	-- hang off it by bridges north and south
	Islands = {
		{ id = "key", name = "LEGENDS KEY", x = -9760, z = 0, r = 440, ring = 300 },
		{ id = "palm", name = "PALM ISLE", x = -9760, z = -1500, r = 340, ring = 225 },
		{ id = "coral", name = "CORAL CAY", x = -9760, z = 1500, r = 340, ring = 225 },
	},
	IslandRoad = 30, -- island ring roads' width
}

---------------------------------------------------------------------
-- Island houses (owner, 2026-10-22: "add houses which u can buy and show case your car garage").
-- Miami-style villas and mansions on the private islands (WestLayout.housePlots). You buy a house
-- type; in each server you get a free plot of that type (the one you had last time if it's free).
-- The ground floor is a glass car gallery: you pick which of your cars stand in its bays.
---------------------------------------------------------------------
Config.Houses = {
	Types = {
		villa = { tier = 1, name = "Island Villa", price = 4000000, bays = 4 },
		mansion = { tier = 2, name = "Legends Key Mansion", price = 15000000, bays = 6 },
	},
	DriveTimeout = 12, -- seconds a "drive this car" spawn point waits for the car
}

---------------------------------------------------------------------
-- Pedestrians (client): people walking the sidewalks, crossing on red, strolling the beach
---------------------------------------------------------------------
Config.Pedestrians = {
	Max = 46, -- on high graphics; scaled down by WorldFx.qualityScale()
	SpawnRadius = 320, -- spawn within this of the camera
	CullRadius = 420, -- returned to the pool beyond this
	MinSpawnGap = 70, -- never pop in closer than this to the camera
	WalkSpeed = { 4.2, 6 }, -- studs a second
	CrossSpeed = 6.4,
	CrossChance = 0.35, -- at a corner: wait for the light and cross
}

---------------------------------------------------------------------
-- The Legends Grand Hotel Downtown (owner, 2026-10-22: "a large skyscraper hotel with valets",
-- penthouse suites on the hotel that "pay out money every minute to their owners"). The suites
-- are the top floors, lowest first. They pay while you're in the game (time offline doesn't
-- pay), one payment per full minute.
---------------------------------------------------------------------
Config.Hotel = {
	Name = "THE LEGENDS GRAND",
	Accent = Color3.fromRGB(255, 200, 120), -- champagne gold
	Neon = { Color3.fromRGB(255, 70, 170), Color3.fromRGB(40, 230, 220) }, -- Miami pink and teal
	IncomeEvery = 60, -- seconds in the game per payment
	Suites = {
		{ id = "grand_skyline", name = "SKYLINE SUITE", price = 2000000, perMinute = 2000 },
		{ id = "grand_ocean", name = "OCEAN SUITE", price = 6000000, perMinute = 6500 },
		{ id = "grand_royal", name = "ROYAL SUITE", price = 12000000, perMinute = 14000 },
		{ id = "grand_presidential", name = "PRESIDENTIAL SUITE", price = 25000000, perMinute = 30000 },
	},
	ValetRange = 20, -- how close to the middle of the valet bay your car must stop
	ValetSpeed = 14, -- studs/s: slow enough to hand over
}

---------------------------------------------------------------------
-- Luxury chauffeur service (owner, 2026-10-22: "hire an NPC driver to transport them across the
-- map in high-end luxury vehicles"). A contract for a car is bought once (in-game cash); then
-- that car and its driver come whenever you call, and rides are free.
---------------------------------------------------------------------
Config.Chauffeur = {
	-- car id -> contract price (the owner's fleet list; the prices match the cars' own)
	Fleet = {
		astin_dbx = 450000,
		bentlee_contgt = 1100000,
		bentlee_bentayga = 1200000,
		bentz_gls = 1200000,
		lambrini_urus = 1500000,
		brabos_g63 = 1600000,
		bentz_s680 = 1600000,
		rolls_wraith = 2000000,
		rolls_cullinan = 2500000,
	},
	-- the order the phone lists them in
	Order = { "astin_dbx", "bentlee_contgt", "bentlee_bentayga", "bentz_gls", "lambrini_urus", "brabos_g63", "bentz_s680", "rolls_wraith", "rolls_cullinan" },
	CityMph = 62, -- how fast the driver goes in town (owner, 2026-10-23: "drive faster"; was 44)
	HighwayMph = 125, -- on the highway and the loop (was 92)
	TurnMph = 22, -- round corners (highway ramps use their own speed; was 15)
	Accel = 26, -- studs/s per second (was 16)
	Brake = 34, -- (was 24)
	ArriveFrom = 260, -- a called car starts this far back up the road and drives to you
	PickupRange = 90, -- you must be this close to a road to call a car
	WaitSeconds = 120, -- a car you called but didn't get into leaves after this
	BringOwnCar = true, -- your own parked car is brought along and left behind you when you arrive
	SuitColor = Color3.fromRGB(22, 24, 30),
	-- chauffeur stands (phone booths for the service): city corners {i, j, si, sj}
	Stands = { { 3, 3, -1, -1 }, { 0, 3, 1, 1 }, { 6, 1, -1, 1 } },
}

---------------------------------------------------------------------
-- High-Rollers Casino and the Legends Gem Showcase, Downtown (owner, 2026-10-22: "places to spend
-- big money on rare, visible flex items like custom gems and accessories, and players can steal
-- and thrive from the casino and gem showcase"). Roblox doesn't allow gambling you can play, even
-- with fake money, so nothing in the casino takes a bet: you buy VIP membership, look the part and
-- rob the vault. In-game cash only, never Robux.
---------------------------------------------------------------------
Config.Luxe = {
	-- slot machines and card tables as scenery (none of them can be played). Roblox's maturity
	-- questionnaire asks about gambling scenery too, which can raise the age label; false puts
	-- lounge seating and car displays there instead
	GamingFloorDecor = true,
	-- VIP membership at the casino's VIP desk: a title over your head, the VIP lounge and money off
	-- at the Gem Showcase. A higher card replaces the lower one (you pay the difference)
	Vip = {
		{ id = 1, name = "GOLD CARD", title = "GOLD HIGH ROLLER", price = 250000, discount = 0.05, color = Color3.fromRGB(255, 200, 70) },
		{ id = 2, name = "PLATINUM CARD", title = "PLATINUM HIGH ROLLER", price = 2500000, discount = 0.1, color = Color3.fromRGB(215, 230, 245) },
		{ id = 3, name = "BLACK CARD", title = "BLACK CARD LEGEND", price = 25000000, discount = 0.15, color = Color3.fromRGB(190, 120, 255) },
	},
	-- wearables at the Gem Showcase: one per slot, everyone sees them on you (on foot)
	Slots = { "Neck", "Wrist", "Hand", "Ears", "Eyes", "Head" },
	Items = {
		{ id = "rope_silver", slot = "Neck", name = "Silver Rope Chain", price = 25000, metal = "silver", style = "chain" },
		{ id = "cuban_gold", slot = "Neck", name = "Gold Cuban Link", price = 120000, metal = "gold", style = "cuban" },
		{ id = "cuban_iced", slot = "Neck", name = "Iced-Out Cuban Link", price = 650000, metal = "white", gem = "diamond", style = "cuban" },
		{ id = "pendant_legend", slot = "Neck", name = "Legends Diamond Pendant", price = 2500000, metal = "gold", gem = "diamond", style = "pendant" },
		{ id = "pendant_emerald", slot = "Neck", name = "Emerald Crown Pendant", price = 8000000, metal = "gold", gem = "emerald", style = "pendant" },
		{ id = "pendant_midnight", slot = "Neck", name = "The Midnight Star", price = 40000000, metal = "white", gem = "sapphire", style = "star" },
		{ id = "watch_diver", slot = "Wrist", name = "Steel Diver Watch", price = 18000, metal = "silver", style = "watch" },
		{ id = "watch_presidente", slot = "Wrist", name = "Gold Presidente", price = 95000, metal = "gold", style = "watch" },
		{ id = "watch_iced", slot = "Wrist", name = "Iced Chronograph", price = 750000, metal = "white", gem = "diamond", style = "watch" },
		{ id = "watch_tourbillon", slot = "Wrist", name = "Royal Tourbillon", price = 3000000, metal = "rose", gem = "ruby", style = "watch" },
		{ id = "ring_signet", slot = "Hand", name = "Gold Signet Ring", price = 15000, metal = "gold", style = "ring" },
		{ id = "ring_ruby", slot = "Hand", name = "Ruby Pinky Ring", price = 450000, metal = "gold", gem = "ruby", style = "ring" },
		{ id = "ring_black", slot = "Hand", name = "Black Diamond Ring", price = 6000000, metal = "white", gem = "black", style = "ring" },
		{ id = "studs_diamond", slot = "Ears", name = "Diamond Studs", price = 40000, metal = "white", gem = "diamond", style = "studs" },
		{ id = "studs_pink", slot = "Ears", name = "Pink Diamond Studs", price = 1200000, metal = "rose", gem = "pink", style = "studs" },
		{ id = "shades_gold", slot = "Eyes", name = "Gold Aviators", price = 30000, metal = "gold", style = "shades" },
		{ id = "shades_iced", slot = "Eyes", name = "Iced Shades", price = 900000, metal = "white", gem = "diamond", style = "shades" },
		{ id = "crown_gold", slot = "Head", name = "Gold Crown", price = 5000000, metal = "gold", gem = "ruby", style = "crown" },
		{ id = "crown_imperial", slot = "Head", name = "Imperial Crown", price = 25000000, metal = "white", gem = "sapphire", style = "crown" },
	},
	Metals = {
		gold = Color3.fromRGB(255, 196, 70),
		silver = Color3.fromRGB(200, 204, 212),
		white = Color3.fromRGB(232, 238, 248),
		rose = Color3.fromRGB(236, 160, 136),
	},
	GemColors = {
		diamond =Color3.fromRGB(220, 245, 255),
		emerald = Color3.fromRGB(40, 220, 120),
		sapphire = Color3.fromRGB(40, 90, 255),
		ruby = Color3.fromRGB(255, 30, 70),
		pink = Color3.fromRGB(255, 120, 200),
		black = Color3.fromRGB(30, 30, 40),
	},
	-- the casino vault: hack the security room (the vault corridor's lasers go off), drill the vault
	-- door (the alarm), then load up from the trolleys. Cash in at the drop-off like the bank's
	Casino = {
		HackSeconds = 6, -- hold E at the security panel
		LasersOffSeconds = 150, -- how long the hack keeps the lasers off
		DrillSeconds = 12, -- hold E at the vault door, after the hack
		Stars = 5,
		OpenSeconds = 120,
		CooldownSeconds = 600,
		GrabSeconds = 3,
		GrabsPerTrolley = 3,
		GrabMin = 22000,
		GrabMax = 40000,
		MaxLoot = 400000, -- one bag
		HackXp = 80,
	},
	-- the Gem Showcase's smash-and-grab: smash a case (the alarm), grab its gems; the showpiece
	-- under the glass dome is worth the most and brings more stars
	Showcase = {
		SmashSeconds = 1.5,
		GrabSeconds = 1.2,
		Stars = 3,
		ShowpieceStars = 4,
		CaseMin = 9000,
		CaseMax = 18000,
		ShowpieceLoot = 75000,
		ShowpieceSeconds = 5,
		MaxLoot = 180000,
		RestockSeconds = 420, -- cases are mended and refilled after this
	},
}

---------------------------------------------------------------------
-- Time of day (owner, 2026-10-22: "morning, evening, sunset and night"): one full day takes
-- CycleMinutes of real time, the same hour for everyone (from the server's clock)
---------------------------------------------------------------------
Config.DayCycle = {
	Enabled = true,
	CycleMinutes = 24, -- one game hour a minute
	StartHour = 20, -- where the clock stands at server time 0 (shifts the whole cycle)
}

---------------------------------------------------------------------
-- Minimap (owner, 2026-10-23: "add a mini map to the game"): round, bottom left, turns with the
-- camera; zooms out with speed. N shows / hides it (M is the music).
---------------------------------------------------------------------
Config.Minimap = {
	Enabled = true,
	ZoomNear = 0.5, -- pixels per stud when slow (about 220 studs across the radius)
	ZoomFar = 0.14, -- ...and at FarMph and above
	FarMph = 150,
}

---------------------------------------------------------------------
-- Legends Motors, the car dealership (owner, 2026-10-23: "add a dealership, a real location";
-- the HUD's SHOP became CARS, your own cars only). New cars are bought here only.
---------------------------------------------------------------------
Config.Dealership = {
	Name = "LEGENDS MOTORS",
	Block = { 4, 2 }, -- the city block it stands on (east of the city centre)
	Face = "W", -- the side its showroom looks out of (towards the city centre)
	BuyRange = 260, -- a player must be this close to the showroom to buy
	-- cars on the showroom turntables (one per brand zone)
	Display = { "bnw_m5_e60", "bentz_e63s", "toyoka_supra_mk4", "nisun_r34", "porsha_panamera", "chevo_c7", "astin_vantage", "lexis_lc500" },
}

---------------------------------------------------------------------
-- Free-roam challenges (owner, 2026-10-23: "make the game 1000000000x better and cooler"): drift
-- scoring, speed traps, jump ramps and the leaderboard (Challenges.lua, ChallengeData)
---------------------------------------------------------------------
Config.Challenges = {
	-- drifting: the car's slide angle above DriftMinAngle at DriftMinMph or more builds points
	DriftMinAngle = 12, -- degrees between where the car points and where it goes
	DriftMinMph = 30,
	DriftLinkSeconds = 1.4, -- a pause this short keeps the run going; longer banks it
	DriftMultStep = 0.25, -- the multiplier grows this much...
	DriftMultEvery = 1.5, -- ...every this many seconds of drifting
	DriftMultMax = 5,
	DriftMaxPerSecond = 900, -- the server's cap on points per second of drifting
	DriftCashPerPoint = 0.2,
	DriftCashMax = 25000, -- per banked run
	DriftXpPerPoint = 1 / 150,
	DriftXpMax = 120,
	-- speed traps: medals by mph, cash for a better medal than you had on that trap
	TrapMedals = { { name = "BRONZE", mph = 100, cash = 750 }, { name = "SILVER", mph = 140, cash = 2000 }, { name = "GOLD", mph = 180, cash = 5000 } },
	TrapCooldown = 4, -- seconds before the same trap counts you again
	TrapXp = 25,
	-- jumps: air time (seconds) and distance (studs) pay out; small hops don't count
	StuntMinAir = 0.7,
	StuntCashPerSecond = 900,
	StuntCashPerStud = 4,
	StuntCashMax = 12000,
	StuntXp = 30,
	BoardKey = Enum.KeyCode.J, -- the leaderboard panel
	BoardRefresh = 60, -- seconds between leaderboard reads
}

---------------------------------------------------------------------
-- Legends Customs (owner, 2026-10-23: "make the game ... cooler"): a drive-in tuning garage.
-- Drive into its bay and press Y (or tap the pill) to restyle the car you're in: paint, finish,
-- second colour, window tint, underglow, rims, number plate, headlights. Saved per car.
---------------------------------------------------------------------
Config.Customs = {
	Name = "LEGENDS CUSTOMS",
	Block = { 3, 1 }, -- the city block it stands on (north of the centre)
	Face = "S", -- the side its bay doors look out of (towards the city centre)
	BayRadius = 20, -- how close to the middle of the bay the car must stop
	-- each change's price; times the car's tier
	Prices = { paint = 2500, finish = 1500, accent = 2000, tint = 1000, glow = 4000, rim = 2000, plate = 1500, head = 1200 },
	TierMult = { Starter = 1, Mid = 2.5, High = 6 },
	-- curated paint colours (name, r, g, b)
	Palette = {
		{ "Pearl White", 238, 238, 234 },
		{ "Arctic Silver", 182, 186, 192 },
		{ "Gunmetal", 72, 76, 82 },
		{ "Midnight Black", 16, 16, 18 },
		{ "Racing Red", 176, 16, 20 },
		{ "Rosso Deep", 110, 10, 16 },
		{ "Sunset Orange", 232, 96, 24 },
		{ "Giallo", 238, 190, 20 },
		{ "Lime Rush", 140, 200, 40 },
		{ "British Green", 18, 62, 40 },
		{ "Petrol Teal", 16, 92, 98 },
		{ "Estoril Blue", 24, 70, 160 },
		{ "Navy", 18, 28, 64 },
		{ "Royal Purple", 74, 30, 120 },
		{ "Champagne", 196, 172, 132 },
		{ "Chalk", 214, 210, 198 },
	},
	TintLevels = { 0, 0.45, 0.65, 0.85 }, -- window darkness: none, light, dark, limo
	Headlights = {
		white = { 255, 250, 240 },
		warm = { 255, 212, 150 },
		ice = { 196, 222, 255 },
	},
}

return Config
