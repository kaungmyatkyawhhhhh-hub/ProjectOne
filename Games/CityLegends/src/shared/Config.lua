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
-- the main menu (owner, 2026-11-02: big tiles, CAMPAIGN / CARS / STORE, opened from the HUD's MENU
-- button, in place of SETTINGS). A new player picks 1 of 3 starter cars; the world map fast travels
-- to the venues (server-checked, not while wanted or in a race / job / heist, a cooldown between)
Config.Menu = {
	-- (owner, 2026-11-03: the Chasor, the 350Z and the A45 S; until the A45 S has its model the
	-- Camaro stands in: `fallback`)
	StarterChoices = {
		{ id = "toyoka_chaser", feel = "Drifts easily" },
		{ id = "nisun_350z", feel = "Grippy sports car" },
		{ id = "bentz_a45s", feel = "Small, quick, all-wheel drive", fallback = "chevo_camaro", fallbackFeel = "Loud and fast" },
	},
	FastTravelCooldown = 30, -- seconds between trips
	-- the store (Playbook money rules): names and exact effects here, prices read from Roblox.
	-- Ids are the owner's to give: until then the tiles show greyed, "Coming soon"
	Store = {
		{ key = "vip", name = "VIP", kind = "Pass", id = nil, art = "store_vip", effect = "A VIP tag, the VIP bays in every tower garage and +10% cash from cut-ups" },
		{ key = "cash2x", name = "2x Cash", kind = "Pass", id = nil, art = "store_cash2x", effect = "Double the cash from driving, cut-ups and jobs, for good" },
		{ key = "starter", name = "Starter Pack", kind = "Product", id = nil, art = "store_starter", effect = "$50,000 and a car of your choice, once per player" },
		{ key = "cash_s", name = "Cash: $25,000", kind = "Product", id = nil, art = "store_bundle", effect = "$25,000 added to your cash" },
		{ key = "cash_m", name = "Cash: $100,000", kind = "Product", id = nil, art = "store_bundle", effect = "$100,000 added to your cash" },
		{ key = "garage", name = "Garage Space", kind = "Product", id = nil, art = "store_garage", effect = "One more garage space at your house" },
	},
}

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
-- Monaco only (owner, 2026-11-02: "bring the main stuffs from city legends to Monaco city and remove
-- the city legends map"): with the Riviera in the place and OldCity off, the old city, Downtown,
-- the west and Legends Isle aren't built; the venues, houses, races, deliveries and chips are in
-- Monaco (src/shared/RivieraWorld.lua, tools/map_plan/export_world.py). The old map is kept, unseen,
-- in ServerStorage.OldMap (and its terrain as ServerStorage.OldMap.Terrain): OldCity = true and
-- moving it back brings it back.
Config.World = {
	OldCity = false,
}
function Config.monacoOnly(): boolean
	return not Config.World.OldCity and workspace:FindFirstChild("Riviera") ~= nil
end

-- the venues in Monaco (owner, 2026-11-02: "Move the venues ... I may replace some of the venues
-- soon"): with the Riviera in the place, these sites replace the old city's blocks and Downtown's
-- (WestLayout). Each site: its middle (x, z), the way its entrance faces (fx, fz: towards the road
-- it opens onto) and its ground height (y: the lot's floor, level with the pavement). The lots are
-- WestLayout.Lot square (216); tools/riviera/Sites.luau clears and levels them in Studio.
-- Move a venue: change its site here and run Sites.luau for it again.
Config.RivieraVenues = {
	On = true,
	Sites = {
		-- (each 150 from its road's centre line, like the old city's blocks: the lot meets the pavement)
		dealership = { x = 16582.3, z = 847.1, fx = 0.174, fz = -0.985, y = 16.83 }, -- Larvotto, on the Coast Road
		customs = { x = 15061.4, z = 1089.1, fx = 0.129, fz = -0.992, y = 1.73 }, -- by the sea on the Coast Road
		hotel = { x = 11673.7, z = 1020.9, fx = 0.998, fz = 0.065, y = 12.37 }, -- Riviera Bay, by the sea
		rewards = { x = 14378.5, z = 31.2, fx = -0.134, fz = 0.991, y = 72.9 }, -- Legends Rewards (was the casino), Casino Heights, on the Town Road
		gems = { x = 14779.9, z = 64, fx = -0.022, fz = 1, y = 69.72 }, -- up the Town Road from Legends Rewards
		-- (owner, 2026-11-02: "move rest of the venue to monaco")
		bank = { x = 12491, z = 983.6, fx = -0.927, fz = 0.376, y = 10.97 }, -- Riviera Bay, east of the stadium
		-- the luxury towers: square to the world axes (their plaza and facade tiers are), entrance -Z
		tower_aurum = { x = 15457.2, z = 1111.1, fx = 0, fz = -1, y = 1.72 }, -- the waterfront, on the Coast Road
		tower_skyline = { x = 16261.7, z = 799.3, fx = 0, fz = -1, y = 13.23 }, -- Larvotto, on the Coast Road
		tower_crown = { x = 14260.5, z = -574.5, fx = 0, fz = -1, y = 161.15 }, -- high on the Mountain Road over the city
		-- Legends Realty's glass pavilion (the house catalogue), on the harbour side of the Coast Road
		realty = { x = 13390, z = 721.8, fx = -0.457, fz = -0.889, y = 6.6, size = 80 },
		-- the bank heist drop-off: a lot at the far east end
		dropoff = { x = 17176.4, z = 891, fx = -0.376, fz = -0.927, y = 20.73 },
	},
}

Config.Spawn = {
	Block = { 3, 2 }, -- the Needle's block
	Side = Vector3.new(0, 0, 1), -- its edge on the city's middle road
	FrontRange = 22, -- a car called on foot comes out up to this far in front of you, if there is room
	-- players start in Monaco (the Riviera) when it is in the place (owner, 2026-11-02: "I didnt spawn
	-- in the monaco map"): a first car on Harbour Street or the Coast Road by the harbour, on foot on
	-- the pavement beside it
	Riviera = true,
	RivieraRoads = { ["Harbour Street"] = true, ["Coast Road"] = true },
	RivieraNear = Vector3.new(13650, 0, 520), -- start within RivieraRadius of this
	RivieraRadius = 450,
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
	CarCount = 28, -- (2026-11-03: 38 -> 28, owner "reduce a little bit of traffic like 10 cars"; 90 -> 38 with the traffic now on the yellow routes only: about the same number of cars on them as before) -- in the city's streets, Monaco's too (owner, 2026-10-29: fewer; was 55 in all; 2026-11-02: 32 -> 40, "add more cars traffic"; 2026-11-03: 40 -> 64, "add more traffic cars throughout the map"; 64 -> 90 the same day, "add more traffic cars too"; phones get ~60%)
	HighwayCars = 18, -- on the highways and the loop, well spaced to split lanes and speed past
	HighwayGap = 60, -- studs kept free round a highway car when one is placed (city: 22)
	-- every car has its own pace, the inside lane runs faster than the outside ones, and each car's
	-- speed drifts up and down a little, so cars never sit side by side for long and there are gaps
	-- to split (owner, 2026-10-29; was 28-48 mph, all lanes alike)
	MinSpeedMph = 24,
	MaxSpeedMph = 54,
	LaneSpeedK = { 1.12, 0.95, 0.85 }, -- lane 1 (inside) .. 3 (outside)
	Wander = 0.14, -- each car's speed drifts this share up and down
	WanderPeriod = { 14, 34 }, -- seconds per drift, per car
	TurnSpeedMph = 22,
	Accel = 28, -- studs/s^2
	Brake = 70,
	EmergencyBrake = 140,
	StopGap = 4, -- studs left between bumpers in a stopped queue
	StopLineMargin = 1.2, -- studs between the front bumper and the stop line at a red light
	-- Legends Isle's mountain roads (owner, 2026-10-30: "reduce traffic on the mountain")
	MountainMax = 3, -- cars on the climbs and the mid ring at once
	MountainShare = 0.2, -- of the spots picked there, this share is used
	MountainTurnK = 0.25, -- how often a car turns up onto the mountain (vs other ways on)
	-- the Riviera (the new map): quiet streets, only this many NPC cars there at once (owner,
	-- 2026-11-02: "traffic on the new map (reduce traffic)")
	-- (owner, 2026-11-03: traffic only on the yellow roads, the three long routes)
	BumpMph = 14, -- traffic slows to this over a speed bump (2026-11-03)
	BumpLook = 40, -- ...from this many studs before it
	StreetShare = 0.05, -- of the spots picked on other streets, this share is used (a rare car)
	LeaveRouteK = 0.03, -- how seldom a car turns off a route onto a street
	StreetRecycle = 260, -- a car off the routes this far from you goes back onto one
	RivieraMax = 90, -- (64 before, then 32 before that, 2026-11-03: "add more traffic cars throughout the map"; 22 before that; owner 2026-11-02 again: "add more cars traffic")
	-- (12 before that: "add a little more traffic, the city monaco is kinda dead")
	FollowGap = 16, -- ...and at least a car length once moving (owner, 2026-10-29)...
	Headway = 0.5, -- ...plus this many seconds of travel
	LookAhead = 70,
	RecycleDistance = 700,
	RespawnMin = 220,
	RespawnMax = 520,
	StuckTime = 6,
	-- Weighted pick of classes used for NPCs
	ClassWeights = { Sedan = 40, SUV = 25, Coupe = 18, Supercar = 6, Hypercar = 2 },
	-- the imported low-poly traffic cars (ReplicatedStorage.TrafficModels, TrafficBodies): length in
	-- studs by type letter (real lengths at 3 studs a metre): A hatch, B people carrier, C small
	-- van, D minibus, E saloon, F pickup
	ModelLengths = { A = 12, B = 12.6, C = 13.2, D = 14.7, E = 13.8, F = 15.9 },
}

-- shown at the bottom of Settings (assets that ask for credit)
Config.Credits = {
	"Traffic cars: \"Low Poly cars pack\" by matisosanimation (CC BY 4.0)",
	"Map shape: © OpenStreetMap contributors (ODbL)",
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
	-- (owner, 2026-10-31: "make the game a little bit easier to get levels"; was 40 and 1.35,
	-- level 60 now takes about a third less XP)
	XpBase = 32, -- XP needed for level 1 -> 2
	XpExponent = 1.3, -- XP needed = XpBase * level ^ XpExponent
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
	HighSpeedYaw = 320, -- the turn builds half as fast at this many studs/s (~250 mph): no snapping at speed (was 220)
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
	SteerSlowdown = 150, -- the wheel turns half as fast at this many studs/s (calm at speed)
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
	WindFarBlur = 0.35, -- how much the street ahead and the roadside further off blur at top speed (0..1)
	WindStreaks = 0.8, -- the soft streaks at the screen's edge at top speed (0 = none)
	ShiftPunchFov = 3, -- a flat-out upshift at high revs: the view kicks wider for a moment
	ShiftBlur = 1,
	LaunchKickFov = 7, -- a hard launch
	LaunchBlur = 2,
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
		bentz_s680 = true, byt_u8 = true, xiaomo_su7 = true, porsha_panamera = true, nisun_r34 = true, nisun_gtr = true, audy_r8 = true,
		lambrini_lp570 = true, lambrini_lp640 = true, lambrini_lp700 = true, lambrini_lp750 = true, lambrini_svj = true, lambrini_svj63 = true, lambrini_urus = true,
		bentlee_contgt = true, bentlee_bentayga = true, rolls_cullinan = true, astin_dbx = true, maseroti_levante = true, bugotti_veyron = true,
		bugotti_veyron_sport = true, bugotti_veyron_top = true, bugotti_chiron = true, bugotti_chiron_pursport = true, bugotti_chiron_supersport = true,
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
	NitroBlur = 1.5,
	-- skid marks (scaled down on phones)
	SkidMax = 200, -- the newest this many strips (2026-11-03: was 140)
	SkidLife = 45, -- seconds before a mark has faded away (was 7)
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
	-- per-car exhaust sets (owner's uploads): Exhaust_<car id>_<Start | Idle | Low | Mid | High |
	-- Launch | Crackle | Redline | Shift | Downshift | ShiftPop | Pops> (Low and the one-shots since
	-- 2026-11-03). Idle / Mid / High are loops blended by rpm; a car with them uses these
	-- instead of the shared engine sound (owner, 2026-10-22: the LP750 first, as a test)
	-- (the Aventador SV: the SVJ's set, copied after this table at half volume, owner 2026-11-03)
	-- (owner, 2026-11-03: "exhaust sounds for SVJ and SVJ 63"; the limiter is the SV's)
	Exhaust_lambrini_svj_Start = "rbxassetid://70853763868958",
	Exhaust_lambrini_svj_Idle = "rbxassetid://86888239641129",
	Exhaust_lambrini_svj_Low = "rbxassetid://119404279673406",
	Exhaust_lambrini_svj_Mid = "rbxassetid://70783605428332",
	Exhaust_lambrini_svj_High = "rbxassetid://129073457954629",
	Exhaust_lambrini_svj_Redline = "rbxassetid://15989284563",
	Exhaust_lambrini_svj_Shift = "rbxassetid://116713101274714",
	Exhaust_lambrini_svj_Downshift = "rbxassetid://109515735710638",
	Exhaust_lambrini_svj_ShiftPop = "rbxassetid://128716617727916",
	Exhaust_lambrini_svj_Pops = "rbxassetid://125121319222420",
	Exhaust_lambrini_svj_Launch = "rbxassetid://100034849111835",
	-- (owner, 2026-11-03: "exhaust sounds for SVJ and SVJ 63"; the limiter is the SV's)
	Exhaust_lambrini_svj63_Start = "rbxassetid://70853763868958",
	Exhaust_lambrini_svj63_Idle = "rbxassetid://86888239641129",
	Exhaust_lambrini_svj63_Low = "rbxassetid://119404279673406",
	Exhaust_lambrini_svj63_Mid = "rbxassetid://70783605428332",
	Exhaust_lambrini_svj63_High = "rbxassetid://129073457954629",
	Exhaust_lambrini_svj63_Redline = "rbxassetid://15989284563",
	Exhaust_lambrini_svj63_Shift = "rbxassetid://116713101274714",
	Exhaust_lambrini_svj63_Downshift = "rbxassetid://109515735710638",
	Exhaust_lambrini_svj63_ShiftPop = "rbxassetid://128716617727916",
	Exhaust_lambrini_svj63_Pops = "rbxassetid://125121319222420",
	Exhaust_lambrini_svj63_Launch = "rbxassetid://100034849111835",
	-- police and the bank (verified creators / ProSoundEffects)
	Siren = "rbxassetid://9056622054", -- Yelp-Police-Siren (loops)
	CameraFlash = "rbxassetid://9113678227", -- Camera Shutter 1 (SFX)
	Alarm = "rbxassetid://9113084849", -- Alarm Bell Constant Ring (SFX)
}

-- the Bugattis' W16 (owner, 2026-11-03: "add the exhaust sounds, make it super realistic and search
-- from Toolbox ... a Veyron and Chiron exhaust sounds and don't forget the quad turbos blow-off and
-- whine, it's the most important of a Bugatti"). Public Creator Store audio (checked: all load and
-- play in Studio). Bands are crossfaded by rpm and each one pitched from the rpm it was recorded at
-- (Config.ExhaustBands); the *Off bands are the coast (off-throttle) recordings. Turbo = the turbo
-- whine loop (pitch and loudness follow the boost), Turbo2 = the second pair of the Chiron's
-- sequential turbos (comes in at 3,800 rpm), BlowOff = the blow-off on lifting off under boost.
do
	local CHIRON = {
		Start = "rbxassetid://119176690907106", -- "Bugatti Chiron W16 Startup" (EfiniRX)
		Idle = "rbxassetid://125444595831615", -- "Bugatti_Chiron_exh_on_Idle" (chazdoest0pic)
		Low = "rbxassetid://78106546390247", -- "Bugatti_Chiron_on3500_ext": on throttle at 3,500 rpm
		LowOff = "rbxassetid://102979441052957", -- "Bugatti_Chiron_off3500_ext": coasting at 3,500
		High = "rbxassetid://101082286464059", -- "Bugatti_Chiron_on6500_ext"
		HighOff = "rbxassetid://79069154574207", -- "Bugatti_Chiron_off6500_ext"
		Turbo = "rbxassetid://72711797703242", -- "bugatti_turbo" (schaefchen_17): the whine
		Turbo2 = "rbxassetid://72711797703242",
		BlowOff = "rbxassetid://101097691662187", -- a big twin-turbo blow-off (McLaren 650S, from a racing game)
	}
	local VEYRON = {
		Start = "rbxassetid://117970941785090", -- "Bugatti Veyron Startup Sound" (T0RQUES)
		Idle = "rbxassetid://82099770713185", -- "Bugatti Chiron Idle" (Tyudogg5): the same W16 at idle
		-- (owner, 2026-11-03: "the Veyron rev sound isn't good, switch it to this": the W16 bank's
		-- 3,500 rpm loop, pitched across the whole rev range; was the Asphalt and CSR2 loops)
		Low = "rbxassetid://102979441052957", -- "Bugatti_Chiron_off3500_ext" (chazdoest0pic)
		Turbo = "rbxassetid://72711797703242",
		BlowOff = "rbxassetid://95497630494219", -- a large blow-off ("toyotasupra_large", from a racing game)
	}
	local PUR_SPORT = table.clone(CHIRON)
	PUR_SPORT.Start = "rbxassetid://14130290830" -- "Bugatti Chiron Pur Sport Startup" (R5ist)
	local sets = {
		bugotti_veyron = VEYRON, bugotti_veyron_sport = VEYRON, bugotti_veyron_top = VEYRON,
		bugotti_chiron = CHIRON, bugotti_chiron_pursport = PUR_SPORT, bugotti_chiron_supersport = CHIRON,
	}
	for carId, set in sets do
		for part, id in set do
			Config.Sounds["Exhaust_" .. carId .. "_" .. part] = id
		end
	end
end

-- (owner, 2026-11-03: "use the SVJ exhaust sound and share it with the SV, but make the SV 2x
-- quieter") the Aventador SV plays the SVJ's whole exhaust set at half volume (Config.ExhaustVolume).
-- Tried the same day and dropped: the L539 V12 at 2,000 / 4,000 / 6,500 rpm ("l539-eng-acc-2000"
-- 119081006371451, "-4000" 82866280346883, "-6500" 138629257229746) with the SV's idle
-- 73235710388670, one ~4,700 rpm loop (72275841063718) and the "Aventador SVJ Revloop" bank
do
	for _, part in { "Start", "Idle", "Low", "Mid", "High", "Launch", "Crackle", "Redline", "Shift", "Downshift", "ShiftPop", "Pops" } do
		Config.Sounds["Exhaust_lambrini_lp750_" .. part] = Config.Sounds["Exhaust_lambrini_svj_" .. part]
	end
end

-- per-car exhaust loudness (every loop and one-shot of the car's set), 1 = as recorded
Config.ExhaustVolume = { lambrini_lp750 = 0.5 } :: { [string]: number }

-- the engine speed a one-shot was recorded at (by asset), so it's pitched to the revs it plays at: the
-- SVJ's downshift blip settles at ~4,200 rpm (its firing note)
Config.ExhaustShotRpm = { ["rbxassetid://109515735710638"] = 4200 } :: { [string]: number }

-- per-car exhaust bands: the rpm each loop was recorded at (the loop's pitch is the car's rpm over
-- this; bands crossfade between their rpms), and the turbos: `whine` the whine's pitch at full boost,
-- `seq` the rpm the second turbo pair comes in (sequential, the Chiron), `bov` the blow-off loudness;
-- `gain` all the loops' loudness, `gains` one band's on top (to level loops recorded louder or softer),
-- `width` how far each band reaches round its rpm (default 0.4; narrower = one recording heard at a time)
Config.ExhaustBands = {} :: { [string]: { bands: { [string]: number }, whine: number?, seq: number?, bov: number?, gain: number?, gains: { [string]: number }?, width: number? } }
do
	local chiron = { bands = { Idle = 950, Low = 3500, High = 6500 }, whine = 0.62, seq = 3800, bov = 1.0 }
	local veyron = { bands = { Idle = 950, Low = 3500 }, whine = 0.7, bov = 1.0 }
	for _, id in { "bugotti_veyron", "bugotti_veyron_sport", "bugotti_veyron_top" } do
		Config.ExhaustBands[id] = veyron
	end
	for _, id in { "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport" } do
		Config.ExhaustBands[id] = chiron
	end
end

-- Radio stations (owner, 2026-10-30, from the research: Midnight Racing's stations by genre). The
-- first plays Sounds.Music; the others are Roblox's licensed music library (DistroKid / APM).
-- Settings > Radio (or the HUD's toast) switches; M turns the radio off and on
Config.Radio = {
	Stations = {
		{ name = "MIDNIGHT FM", tracks = {} }, -- (Sounds.Music)
		{
			name = "LO-FI CITY",
			tracks = {
				"rbxassetid://100001805913571", -- Lofi Jazz Hip Hop Abstract Chill Beat
				"rbxassetid://119721983234750", -- Neon Sidewalks with Chillhop and Midnight Lofi
				"rbxassetid://136228570470406", -- Apartment Windows with Modern Chill Jazz
				"rbxassetid://89402602954424", -- Pastel Corner Life
			},
		},
		{
			name = "DRIFT PHONK",
			tracks = {
				"rbxassetid://85735197482652", -- Drift Night Phonk
				"rbxassetid://78571301330361", -- Nightmare (Drift Phonk)
				"rbxassetid://114152684566510", -- Dead Yesterdays (Drift Phonk)
				"rbxassetid://128825897988432", -- Pieces (Drift Phonk)
				"rbxassetid://83420704049320", -- Everything Nothing (Drift Phonk)
			},
		},
		{
			name = "CLUB RUSH",
			tracks = {
				"rbxassetid://9042578586", -- Night To Remember (APM)
				"rbxassetid://9042581323", -- Neon Nights (APM)
				"rbxassetid://9041811979", -- Born A Winner (APM)
				"rbxassetid://1841526682", -- Flashing Lights (APM)
			},
		},
	},
}

---------------------------------------------------------------------
-- Police and speed cameras (owner, 2026-10-22: limit 120 km/h, the police chase you)
---------------------------------------------------------------------
Config.Police = {
	SpeedCameras = false, -- (owner, 2026-11-03: "remove speed cameras for now"; true brings them back)
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
	Cars = false, -- police cars on the roads (owner, 2026-11-02: "remove the police cars for now"; true brings them back)
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
	-- racing other players (owner, 2026-10-30, from the research: Midnight Racing's race lobbies and
	-- PlayerVS duels, Vehicle Legends' more pay with others): stop in a race ring and you join its
	-- lobby; it starts LobbySeconds after the first racer (sooner when full). With 2+ racers the
	-- finishers share a pot (1st all of its share, then half each place down); a friend in the race
	-- multiplies your share. Alone, it's the time trial as before.
	LobbySeconds = 15,
	LobbyMax = 6,
	PotPerRacer = 4000,
	PotShares = { 1, 0.5, 0.25, 0.125 },
	FriendBonus = 1.5,
	-- duels: U (or the RACE pill) next to another driver challenges them to a sprint to a junction
	-- across town
	DuelRange = 120, -- studs between the cars
	DuelAskSeconds = 12,
	DuelMinDist = 1100,
	DuelMaxDist = 2200,
	DuelTimeout = 180,
	DuelPot = 10000,
	DuelSecondCash = 1500,
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
	HighFromPrice = 600000, -- high-end cars (the dealer sells them too since 2026-10-30; rare here)
	HighShowroomKeep = 0.2, -- of the Showroom rolls a high-end car gets, this share stays Showroom
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
		rewards = { 100, 3, "N" }, -- Legends Rewards (was the casino), across the boulevard from the hotel
		gems = { 102, 3, "N" }, -- the gem showcase, up the boulevard
	},
	-- Legends Isle (owner, 2026-10-29: one big island with a mountain, in place of the three small
	-- ones): the causeway lands on its east side. IsleLayout turns this into roads, lots and places.
	Isle = {
		x = -10700,
		z = 0,
		r = 1300, -- the shore: sand runs into the water here
		Ring = 1180, -- the island ring road's middle (on the low ground)
		Road = 34, -- every island road: one lane each way
		Foot = 1050, -- the mountain's lower slopes start here
		-- the mid terrace (a shelf cut round the mountain), its ring road and the lots outside it
		Mid = { y = 200, inner = 540, outer = 690, ring = 560, lots = 12, lotWidth = 104, lotDepth = 100 },
		-- the flat top (the gated Summit), its ring road and the lots round it
		-- (r: the flat top is just the ring road and the helipad now; each High lot is its own pad cut
		-- into the ridge round it, owner 2026-10-29: "each on its own spot")
		Top = { y = 400, r = 215, ring = 160, lotWidth = 120, lotDepth = 130 }, -- High lots (summit and waterfront)
		Low = { arc = 1.1, skip = 0.33, width = 60, depth = 72 }, -- street lots by the causeway (deep: the garage takes the front of the house)
		-- the switchbacks: curved legs round the mountain (radius of each, length of each)
		Lower = { radii = { 1010, 935, 860, 790, 720 }, length = 440, center = 0 }, -- east face
		Upper = { radii = { 505, 455, 405, 355, 305 }, length = 400, center = math.pi }, -- west face
	},
}

---------------------------------------------------------------------
-- Houses (owner, 2026-10-29: "a housing system like Driving Empire's", our own look). You buy a
-- house's blueprint at Legends Realty (it's yours for good), then claim a FOR SALE lot of its
-- tier on Legends Isle and the house builds there. One house stands at a time; swap any time.
-- Tier = lot = place on the mountain: 0 Low (by the bridge), 1 Mid (the terrace and the beach),
-- 2 High (the Summit behind the gate, and the beach). The list was OK'd by the owner (mood board
-- https://claude.ai/artifact/AYdvAfttk8rEcELnGbufgd). bays: garage spaces that come free; maxBays:
-- the most you can buy up to (BayPrices); drive: cars on show on the driveway; level: the player
-- level needed to buy. look: how HouseBuilder draws it (footprint, colours, roof, extras).
---------------------------------------------------------------------
local function design(id: string, name: string, tier: number, style: string, floors: number, beds: number, baths: number, sqft: number, bays: number, maxBays: number, price: number, level: number, desc: string, look: { [string]: any })
	return { id = id, name = name, tier = tier, style = style, floors = floors, beds = beds, baths = baths, sqft = sqft, bays = bays, maxBays = maxBays, drive = if bays >= 10 then 3 else 2, price = price, level = level, desc = desc, look = look }
end
local C3 = Color3.fromRGB
Config.Houses = {
	Designs = {
		-- LOW (small lots by the bridge)
		design("harlow", "The Harlow", 0, "Small modern, timber slats", 2, 3, 2, 1450, 3, 4, 150000, 1, "A warm white starter home with timber slats and big black windows.", { w = 34, d = 48, wall = C3(241, 236, 226), trim = C3(36, 36, 38), accent = C3(169, 119, 74), roof = "mono", roofColor = C3(52, 54, 58) }),
		design("bayview", "Bayview", 0, "Modern, sand render", 2, 3, 2, 1550, 3, 4, 240000, 1, "Sand-coloured modern house with a hip roof and a sunny balcony.", { w = 36, d = 48, wall = C3(222, 205, 176), trim = C3(250, 248, 242), roof = "hip", roofColor = C3(86, 88, 92), balcony = true }),
		design("linden", "Linden", 0, "Single-floor modern", 1, 2, 2, 1300, 3, 4, 330000, 2, "A low sage-green modern home with a flat roof and a covered patio.", { w = 40, d = 48, wall = C3(152, 170, 146), trim = C3(244, 242, 236), roof = "flat", roofColor = C3(60, 62, 66) }),
		design("corsa_lane", "Corsa Lane", 0, "White and grey modern", 2, 3, 3, 1800, 3, 4, 450000, 2, "Crisp white and grey two-storey with a balcony and a double garage.", { body = "WhiteCube", w = 38, d = 50, wall = C3(246, 246, 244), trim = C3(70, 72, 76), accent = C3(120, 124, 130), roof = "flat", roofColor = C3(58, 60, 64), balcony = true }),
		design("driftwood", "Driftwood Beach Shack", 0, "Timber shack on stilts", 1, 1, 1, 850, 3, 4, 520000, 3, "A weathered timber shack with a big deck, made for the beach life.", { w = 28, d = 42, wall = C3(166, 140, 112), trim = C3(240, 236, 226), roof = "gable", roofColor = C3(110, 96, 84), deck = true }),
		design("meadow_cottage", "Meadow Cottage", 0, "Beige cottage, hip roof", 1, 2, 1, 1100, 3, 4, 600000, 3, "A cosy single-storey cottage with a low hip roof and a garden path.", { w = 36, d = 46, wall = C3(226, 210, 182), trim = C3(250, 246, 236), roof = "hip", roofColor = C3(120, 92, 70) }),
		design("harbour_townhouse", "Harbour Townhouse", 0, "Narrow brick townhouse", 3, 3, 2, 1700, 3, 4, 750000, 4, "Three tall floors of red brick with white sash windows.", { w = 26, d = 50, wall = C3(150, 78, 60), trim = C3(246, 242, 234), roof = "gable", roofColor = C3(62, 62, 66) }),
		design("juniper", "Juniper Bungalow", 0, "Craftsman bungalow", 1, 3, 2, 1600, 3, 4, 900000, 4, "A craftsman bungalow with a deep front porch on stone posts.", { w = 40, d = 50, wall = C3(116, 128, 104), trim = C3(240, 234, 220), accent = C3(150, 140, 128), roof = "gable", roofColor = C3(70, 62, 56), porch = true }),
		design("sandpiper", "Sandpiper Ranch", 0, "Long ranch house", 1, 4, 2, 2000, 3, 4, 1100000, 5, "A long, low ranch house with a wide garage and a lawn all round.", { w = 48, d = 48, wall = C3(232, 222, 204), trim = C3(96, 80, 64), roof = "hip", roofColor = C3(98, 84, 72) }),
		design("fernbrook", "Fernbrook House", 0, "Family house, bay windows", 2, 4, 3, 2200, 3, 4, 1400000, 5, "A family house with bay windows and a gabled roof.", { w = 40, d = 52, wall = C3(198, 210, 220), trim = C3(250, 250, 248), roof = "gable", roofColor = C3(64, 70, 80) }),
		design("aspen", "Aspen A-Frame", 0, "Log A-frame cabin", 2, 3, 2, 1500, 3, 4, 1800000, 6, "A log A-frame with a glass gable end looking out over the water.", { w = 32, d = 52, wall = C3(132, 96, 64), trim = C3(36, 34, 32), roof = "aframe", roofColor = C3(52, 48, 44) }),
		design("brookside", "Brookside House", 0, "Craftsman, stone porch", 2, 4, 3, 2500, 3, 4, 2400000, 6, "Craftsman house with a stone-based porch and a big family kitchen.", { w = 42, d = 52, wall = C3(208, 196, 170), trim = C3(250, 248, 240), accent = C3(150, 140, 128), roof = "gable", roofColor = C3(84, 76, 70), porch = true }),
		-- MID (the terrace halfway up, and the beach)
		design("maple_hollow", "Maple Hollow", 1, "Bungalow, hip roof, front porch", 1, 4, 3, 2600, 3, 6, 3000000, 8, "A furnished bungalow with a hip roof, a railed front porch, flower beds and a gazebo.", { body = "RealisticBungalow", w = 52, d = 50, wall = C3(143, 165, 138), trim = C3(246, 243, 236), accent = C3(124, 116, 104), roof = "gable", roofColor = C3(70, 72, 76), porch = true, gazebo = true }),
		design("ridgeback_barn", "Ridgeback Barn", 1, "Barn house, wrap porch", 2, 3, 3, 2400, 4, 6, 3800000, 8, "A forest-green barn house with a metal roof, a cupola and a wrap-around porch.", { w = 48, d = 40, wall = C3(47, 61, 51), trim = C3(220, 214, 200), accent = C3(85, 73, 61), roof = "barn", roofColor = C3(170, 172, 168), porch = true, cupola = true }),
		design("the_laurel", "The Laurel", 1, "White modern, two floors", 2, 4, 3, 2900, 3, 6, 4600000, 9, "A furnished white two-floor house with a porch, a roof terrace and a pool out the back.", { body = "BigModernHouse", w = 52, d = 54, wall = C3(244, 240, 232), trim = C3(40, 40, 42), accent = C3(160, 112, 72), roof = "flat", roofColor = C3(52, 54, 58), pool = true, balcony = true }),
		design("kingsridge", "Kingsridge Villa", 1, "White and slate stone, waterfall pool", 2, 3, 3, 3100, 4, 6, 5500000, 10, "White render and dark slate stone, timber soffits and a waterfall pool.", { w = 54, d = 42, wall = C3(245, 245, 242), trim = C3(30, 30, 32), accent = C3(75, 79, 83), roof = "flat", roofColor = C3(48, 50, 54), pool = true }),
		design("casa_solana", "Casa Solana", 1, "Spanish villa, courtyard", 2, 4, 4, 3400, 4, 6, 6500000, 10, "A Spanish villa with clay tile roofs, arches and a shady courtyard.", { w = 54, d = 44, wall = C3(240, 226, 200), trim = C3(120, 72, 44), roof = "tile", roofColor = C3(178, 84, 50), arches = true, pool = true }),
		design("clearwater", "Clearwater Glass House", 1, "Glass pavilion", 1, 3, 3, 3000, 4, 6, 7800000, 11, "A single-floor glass pavilion: you see right through it to the view.", { w = 58, d = 40, wall = C3(236, 236, 234), trim = C3(26, 26, 28), roof = "flat", roofColor = C3(40, 40, 44), glassy = true, pool = true }),
		design("cedar_lodge", "Cedar Lake Lodge", 1, "Timber lodge, hot tub", 2, 5, 4, 3800, 4, 6, 9000000, 12, "A big timber lodge with stone chimneys, a hot tub and a deck.", { w = 56, d = 44, wall = C3(126, 88, 58), trim = C3(40, 36, 32), accent = C3(140, 134, 124), roof = "gable", roofColor = C3(58, 52, 46), deck = true, hottub = true }),
		design("cliffside", "Cliffside House", 1, "Cantilever over the cliff", 3, 4, 4, 4000, 4, 6, 10500000, 13, "Concrete and glass stepping out over the slope, a floor that hangs in the air.", { w = 50, d = 44, wall = C3(200, 200, 196), trim = C3(30, 30, 32), accent = C3(150, 110, 76), roof = "flat", roofColor = C3(56, 58, 62), cantilever = true, pool = true }),
		design("whitmore_hall", "Whitmore Hall", 1, "Double verandas, tennis court", 2, 6, 5, 5200, 4, 6, 12500000, 14, "A grand white house with two floors of verandas, a pool and a tennis court.", { w = 62, d = 46, wall = C3(250, 249, 245), trim = C3(250, 249, 245), accent = C3(47, 74, 59), roof = "hip", roofColor = C3(93, 107, 120), verandas = true, pool = true }),
		design("ocean_terrace", "Ocean Terrace", 1, "Glass waterfront, lit pool", 3, 5, 5, 5000, 4, 6, 15000000, 15, "Glass boxes over a lit pool, a solar roof and a private dock.", { body = "GlassTerraces", fitW = 96, fitD = 92, w = 58, d = 46, wall = C3(246, 246, 244), trim = C3(36, 36, 38), roof = "flat", roofColor = C3(40, 42, 46), glassy = true, pool = true, solar = true }),
		-- HIGH (the Summit, behind the gate, and the beach)
		design("skyline_loft", "Skyline Loft House", 2, "Wood and glass modern, underground garage", 2, 3, 4, 4000, 5, 8, 20000000, 20, "Cedar, white render and a slanted roof, a roof terrace, and the cars underground.", { body = "WoodModern", fitW = 100, fitD = 108, w = 64, d = 52, wall = C3(232, 226, 216), trim = C3(30, 28, 26), accent = C3(122, 90, 58), roof = "flat", roofColor = C3(44, 44, 46), cantilever = true, pool = true }),
		design("palm_crest", "Palm Crest Estate", 2, "Modern farmhouse, one long floor", 1, 6, 6, 7400, 5, 8, 26000000, 21, "A long white farmhouse with black windows, a vaulted living room and an underground garage.", { body = "WideFarmhouse", fitW = 100, fitD = 108, w = 72, d = 54, wall = C3(250, 250, 247), trim = C3(250, 250, 247), accent = C3(217, 205, 184), roof = "hip", roofColor = C3(110, 114, 120), pool = true, palms = true }),
		design("hillcrest_manor", "Hillcrest Manor", 2, "White family manor, hip roofs", 2, 7, 6, 8200, 5, 8, 32000000, 22, "A white two-floor manor with slate hip roofs, a grand stair and an underground garage.", { body = "WhiteHipHouse", fitW = 100, fitD = 108, w = 72, d = 56, wall = C3(248, 246, 240), trim = C3(70, 70, 74), roof = "hip", roofColor = C3(80, 84, 90), terraces = true, pool = true }),
		design("coral_bay", "Coral Bay Mansion", 2, "White modern, three floors of terraces", 3, 8, 7, 9000, 5, 8, 40000000, 24, "Three white floors stepping up with terraces and balconies, and an underground garage.", { body = "TerraceModern", fitW = 100, fitD = 108, w = 76, d = 56, wall = C3(250, 248, 240), trim = C3(64, 112, 168), roof = "hip", roofColor = C3(60, 64, 72), arches = true, balustrades = true, pool = true, palms = true }),
		design("villa_serena", "Villa Serena", 2, "Mediterranean villa, clay tile roofs", 2, 6, 6, 10500, 10, 10, 48000000, 25, "White walls under red clay tile roofs, a grand entry and an underground garage.", { body = "TerracottaVilla", fitW = 100, fitD = 108, w = 78, d = 58, wall = C3(234, 223, 202), trim = C3(180, 84, 47), roof = "tile", roofColor = C3(180, 84, 47), tower = true, fountain = true, arches = true, pool = true }),
		design("blackstone_lodge", "Blackstone Lodge", 2, "Stone and timber lodge", 2, 7, 7, 11000, 10, 10, 58000000, 26, "Stone, white boards and dark roofs on a big family lodge, with an underground garage.", { body = "StoneLodge", fitW = 100, fitD = 108, w = 78, d = 60, wall = C3(138, 133, 128), trim = C3(42, 36, 32), accent = C3(184, 115, 51), roof = "gable", roofColor = C3(52, 50, 48), stoneArch = true, pool = true }),
		design("summit_crown", "Summit Crown Estate", 2, "Ultra-modern glass villa", 2, 6, 8, 12500, 10, 10, 70000000, 27, "Floor-to-ceiling glass on white boxes, a floating stair and an underground garage.", { body = "GlassModern", fitW = 100, fitD = 108, w = 80, d = 60, wall = C3(247, 247, 245), trim = C3(90, 70, 50), roof = "flat", roofColor = C3(50, 50, 54), dome = true, carCourt = true, pool = true, solar = true }),
		design("legends_palace", "Legends Palace", 2, "White palace, grand terraces", 2, 10, 9, 14000, 10, 10, 84000000, 28, "The grand white palace: arched balconies, a grand hall and an underground garage.", { body = "WhitePalace", fitW = 100, fitD = 108, w = 84, d = 60, wall = C3(246, 242, 232), trim = C3(214, 190, 130), roof = "hip", roofColor = C3(70, 72, 78), columns = true, towers = true, balustrades = true, fountain = true, pool = true }),
		design("the_pinnacle", "The Pinnacle", 2, "Stone tower villa, rooftop helipad", 3, 8, 10, 16000, 10, 10, 100000000, 30, "The biggest house in the game: a stone tower, roof terraces, a helicopter on its own helipad and an underground garage.", { body = "HelipadVilla", fitW = 100, fitD = 108, w = 86, d = 62, wall = C3(236, 234, 228), trim = C3(26, 26, 28), accent = C3(150, 146, 136), roof = "flat", roofColor = C3(40, 40, 44), glassy = true, pool = true, helipad = true }),
	},
	-- extra garage spaces, bought one at a time up to the house's maxBays (in-game cash only)
	BayPrices = { 50000, 100000, 200000, 400000, 800000 },
	SellBack = 0.7, -- selling a blueprint at Legends Realty gives this share of its price back
	ClaimCooldown = 30, -- seconds before you can claim another lot (stops lot-hopping)
	-- old saves (2026-10-29): the old house types become these designs (worth as much or more)
	Renamed = { villa = "the_laurel", mansion = "skyline_loft" } :: { [string]: string },
	DriveTimeout = 12, -- seconds a "drive this car" spawn point waits for the car
}
-- the designs by id, and the old shape (Types) other code reads: tier, name, price, bays
Config.Houses.ById = {}
Config.Houses.Types = {}
for _, d in Config.Houses.Designs do
	Config.Houses.ById[d.id] = d
	Config.Houses.Types[d.id] = { tier = d.tier, name = d.name, price = d.price, bays = d.maxBays }
end

---------------------------------------------------------------------
-- Pedestrians (client): people walking the sidewalks, crossing on red, strolling the beach
---------------------------------------------------------------------
Config.Pedestrians = {
	-- (owner, 2026-11-02: "optimize the walking npc so that the game wont lag": was 46 / 320 / 420)
	Max = 18, -- on high graphics; scaled down by WorldFx.qualityScale() (was 30; owner 2026-11-02: "reduce NPC")
	SpawnRadius = 260, -- spawn within this of the camera
	CullRadius = 340, -- returned to the pool beyond this
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
-- One suite you upgrade (owner, 2026-11-03: "the 4 suites will be in the same location but when u
-- upgrade it in lobby the inside of the suites will change and the highest will be pent house"):
-- you own one tier at a time; the lobby's gallery upgrades it to the next (you pay the difference
-- in price), only that tier pays, and only its owner can ride up. Each tier's floor is furnished
-- better than the one below (adds).
---------------------------------------------------------------------
Config.Hotel = {
	Name = "THE LEGENDS GRAND",
	Accent = Color3.fromRGB(255, 200, 120), -- champagne gold
	Neon = { Color3.fromRGB(255, 70, 170), Color3.fromRGB(40, 230, 220) }, -- Miami pink and teal
	IncomeEvery = 60, -- seconds in the game per payment
	Suites = {
		-- (price: the tier's full value; an upgrade costs the difference from the tier below)
		{ id = "grand_skyline", name = "SKYLINE SUITE", price = 2000000, perMinute = 2000, adds = "Lounge, kitchen, bed" },
		{ id = "grand_ocean", name = "OCEAN SUITE", price = 6000000, perMinute = 6500, adds = "+ Car turntable" },
		{ id = "grand_royal", name = "ROYAL SUITE", price = 12000000, perMinute = 14000, adds = "+ DJ booth, chandelier" },
		{ id = "grand_presidential", name = "PENTHOUSE", price = 25000000, perMinute = 30000, adds = "+ Roof pool, helipad" },
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
-- The Legends Gem Showcase, Downtown (owner, 2026-10-22: "places to spend big money on rare,
-- visible flex items like custom gems and accessories"). In-game cash only, never Robux. (The
-- High-Rollers Casino was replaced by Legends Rewards on 2026-11-03; its VIP desk moved here and
-- its vault heist was removed.)
---------------------------------------------------------------------
Config.Luxe = {
	-- VIP membership at the Gem Showcase's VIP desk: a title over your head and money off the
	-- collection. A higher card replaces the lower one (you pay the difference)
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
-- Legends Rewards (owner, 2026-11-03: "Replace the casino with a rewards centre"): one building
-- on the casino square where players claim their daily reward and everything else they've earned.
-- The amounts are the owner's choice ("Double that"). Codes, the group and the Robux products are
-- the owner's to fill in.
---------------------------------------------------------------------
Config.Rewards = {
	Name = "LEGENDS REWARDS",
	DeskRange = 22, -- studs: how close to a claim desk you must stand (codes work anywhere)
	-- playtime gifts: minutes played today (UTC) -> cash; they start again each day
	Playtime = {
		{ minutes = 5, cash = 6000 },
		{ minutes = 15, cash = 12000 },
		{ minutes = 30, cash = 24000 },
		{ minutes = 60, cash = 60000 },
	},
	Weekly = 150000, -- once every 7 days
	WeeklyEvery = 7 * 24 * 60 * 60,
	-- level-up rewards: each level reached pays LevelCash x level, every 5th level a chest of
	-- ChestCash x level on top (older saves start from the level they had on 2026-11-03)
	LevelCash = 2000,
	ChestCash = 8000,
	ChestEvery = 5,
	Return = 100000, -- the welcome back gift, after this long away
	ReturnAway = 7 * 24 * 60 * 60,
	FriendDaily = 10000, -- playing in the same server as a friend, once a day
	Invite = 50000, -- a friend joins for the first time from your invite: both get this
	-- the Roblox group gift (one time): 0 hides it until the owner gives the group's id
	GroupId = 0,
	Group = 50000,
	-- codes: { code (capitals, 4-20 letters / digits), cash, ends ("YYYY-MM-DD", UTC, the last
	-- day it works), on }; each works once per player
	Codes = {
		{ code = "LEGENDS", cash = 25000, ends = "2026-12-31", on = false }, -- (a test code: off)
	},
	-- the wheels (owner, 2026-11-03: "add wheel spin and super wheel spins too and if they ran out
	-- u can buy back with money or robux"; "Bigger prizes"). Free spins come back on their timer;
	-- extra spins are bought with cash or Robux. The odds are shown before every spin (Roblox's
	-- rule for paid random items), and buying is hidden where Roblox restricts paid random items.
	-- weight = the chance in percent (they add up to 100); car = a free Mid car you don't own (or
	-- carCash when you own them all). reels: prizes a spin gives (owner, 2026-11-03: reels of
	-- prize cards like a wheelspin, the SUPER one more exciting: 3 reels, 3 prizes; its cash price
	-- went up to stay above what 3 prizes are worth on average)
	-- (owner, 2026-11-03: "make the prices rarer to get ... add more low percentage like up to 0.5%
	-- which will give a car and also add way more stuffs"): many small prizes, the big ones rare;
	-- kinds: cash, spin (one more spin of the same kind), flex (a Gem Showcase piece you don't own,
	-- at or under flexMax, or flexCash), car (a car you don't own, of carTiers at or under carMax,
	-- or carCash)
	Wheels = {
		wheel = {
			name = "SPIN",
			reels = 1,
			freeEvery = 24 * 60 * 60,
			cashPrice = 50000,
			productId = 0, -- the Robux developer product for 1 spin (0: hidden)
			prizes = {
				{ cash = 5000, weight = 22 },
				{ cash = 8000, weight = 18 },
				{ cash = 12000, weight = 15 },
				{ cash = 18000, weight = 12 },
				{ cash = 25000, weight = 9 },
				{ spin = true, weight = 8 },
				{ cash = 40000, weight = 6 },
				{ cash = 60000, weight = 4 },
				{ flex = true, flexMax = 120000, flexCash = 50000, weight = 2.5 },
				{ cash = 100000, weight = 2 },
				{ cash = 200000, weight = 1 },
				{ car = true, carTiers = { "Mid" }, carMax = 120000, carCash = 120000, weight = 0.5 },
			},
		},
		super = {
			name = "SUPER SPIN",
			reels = 3,
			freeEvery = 7 * 24 * 60 * 60,
			cashPrice = 1000000,
			productId = 0, -- (0: hidden)
			prizes = {
				{ cash = 25000, weight = 22 },
				{ cash = 40000, weight = 16 },
				{ cash = 60000, weight = 14 },
				{ cash = 90000, weight = 11 },
				{ cash = 125000, weight = 9 },
				{ cash = 175000, weight = 7 },
				{ cash = 250000, weight = 5 },
				{ spin = true, weight = 4 },
				{ flex = true, flexMax = 1000000, flexCash = 300000, weight = 4 },
				{ cash = 400000, weight = 3 },
				{ cash = 750000, weight = 2 },
				{ cash = 1500000, weight = 1.5 },
				{ car = true, carTiers = { "Mid", "High" }, carMax = 600000, carCash = 500000, weight = 1 },
				{ cash = 5000000, weight = 0.5 },
			},
		},
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
	-- (2026-11-03, the drawn map: a little wider, so the roads read as streets, not one big band)
	ZoomNear = 0.32, -- pixels per stud when slow (about 320 studs across the radius)
	ZoomFar = 0.12, -- ...and at FarMph and above
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
	-- the ready-made building (ServerStorage.DealerBody, 2026-10-31): the car on the turntable and
	-- the four indoor spots. The front car park stays empty for players to park in (owner,
	-- 2026-10-31: "dont put cars infront the dealership"); Lot = { ids } would fill its bays.
	Stage = "lambrini_lp750",
	Indoor = { "ferrara_458", "rolls_wraith", "porsha_gt3", "bentz_g63" },
	-- test drives (owner, 2026-10-30, from the research: Vehicle Legends): any dealer car you don't
	-- own, for a few minutes, once per car each visit; it pays less while you test it
	TestSeconds = 300,
	TestPay = 0.25, -- cut-ups and driving cash in a test car
	TestCooldown = 20, -- seconds between test drives
	-- the car park behind is the LEGENDS MEET (owner, 2026-10-30, from the research: Midnight
	-- Racing's parking-area meets): park there with other players for a small bonus each minute
	MeetBonusPerCar = 300, -- each minute, per other player's car parked there (up to MeetBonusMax cars)
	MeetBonusMax = 5,
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

-- riding along in another player's car (owner, 2026-10-29): Y beside it takes the free seat
-- nearest you. Every car has a front passenger seat; sedans, SUVs and coupes have two rear seats
-- too, except the two-seat coupes below (supercars and hypercars are all two-seaters)
Config.Passengers = {
	Range = 14, -- studs from your feet to the seat
	RearClasses = { Sedan = true, SUV = true, Coupe = true },
	TwoSeaters = {
		nisun_350z = true,
		mazdo_rx7 = true,
		porsha_boxster = true,
		chevo_c6 = true,
		chevo_c7 = true,
		astin_vantage = true,
		bentz_sl65bs = true,
	},
}

---------------------------------------------------------------------
-- Goals (owner, 2026-10-30, from the driving games research: Midnight Racing's milestones and
-- daily rewards, Car Dealership Tycoon's daily tasks):
--   * Legends Path: one-off goals in order, from the first minute; the next one is always on the
--     HUD and each pays when done
--   * the daily streak (replaces the flat daily gift): come back each day for more, day 7 a free
--     Mid car; miss more than StreakGrace and it starts again at day 1
--   * 3 daily tasks, new each day (UTC), each paying cash and XP
-- Stat names (Goals.note / Goals.value): miles, cuts, combo (best), races, gold (race golds),
-- traps (speed trap medals), trapgold, drifts, jumps, jobs, chips, customs, escapes, bank, house,
-- pvp (races finished against players), pvpwins, level, cars (owned), brands (owned brands)
---------------------------------------------------------------------
Config.Goals = {
	-- Legends Path, in order: { id, text, stat, need, cash, xp }
	Path = {
		{ id = "mile1", text = "Drive your first mile", stat = "miles", need = 1, cash = 1500, xp = 50 },
		{ id = "cut10", text = "Cut up 10 cars", stat = "cuts", need = 10, cash = 2000, xp = 60 },
		{ id = "combo5", text = "Hit a x5 combo", stat = "combo", need = 5, cash = 3000, xp = 80 },
		{ id = "lvl3", text = "Reach level 3", stat = "level", need = 3, cash = 3000, xp = 0 },
		{ id = "trap1", text = "Get a medal at a speed trap", stat = "traps", need = 1, cash = 3000, xp = 80 },
		{ id = "race1", text = "Finish a race", stat = "races", need = 1, cash = 4000, xp = 100 },
		{ id = "drift1", text = "Bank a drift", stat = "drifts", need = 1, cash = 3000, xp = 80 },
		{ id = "jump1", text = "Land a jump", stat = "jumps", need = 1, cash = 3000, xp = 80 },
		{ id = "car2", text = "Buy your second car", stat = "cars", need = 2, cash = 5000, xp = 120 },
		{ id = "custom1", text = "Restyle a car at Legends Customs", stat = "customs", need = 1, cash = 4000, xp = 100 },
		{ id = "job1", text = "Finish a delivery job", stat = "jobs", need = 1, cash = 4000, xp = 100 },
		{ id = "lvl5", text = "Reach level 5", stat = "level", need = 5, cash = 6000, xp = 0 },
		{ id = "pvp1", text = "Race against another player", stat = "pvp", need = 1, cash = 6000, xp = 150 },
		{ id = "cut200", text = "Cut up 200 cars", stat = "cuts", need = 200, cash = 8000, xp = 200 },
		{ id = "escape1", text = "Get away from the police", stat = "escapes", need = 1, cash = 8000, xp = 200 },
		{ id = "trapgold", text = "Get gold at a speed trap", stat = "trapgold", need = 1, cash = 8000, xp = 200 },
		{ id = "gold1", text = "Win gold in a race", stat = "gold", need = 1, cash = 8000, xp = 200 },
		{ id = "combo12", text = "Hit a x12 combo", stat = "combo", need = 12, cash = 12000, xp = 250 },
		{ id = "car5", text = "Own 5 cars", stat = "cars", need = 5, cash = 15000, xp = 300 },
		{ id = "lvl10", text = "Reach level 10", stat = "level", need = 10, cash = 15000, xp = 0 },
		{ id = "pvpwin1", text = "Win a race against a player", stat = "pvpwins", need = 1, cash = 15000, xp = 300 },
		{ id = "chips10", text = "Collect 10 chips", stat = "chips", need = 10, cash = 10000, xp = 200 },
		{ id = "mile100", text = "Drive 100 miles", stat = "miles", need = 100, cash = 20000, xp = 400 },
		{ id = "house1", text = "Buy a house", stat = "house", need = 1, cash = 25000, xp = 400 },
		{ id = "bank1", text = "Rob the bank and get away", stat = "bank", need = 1, cash = 25000, xp = 400 },
		{ id = "lvl20", text = "Reach level 20", stat = "level", need = 20, cash = 50000, xp = 0 },
		{ id = "car10", text = "Own 10 cars", stat = "cars", need = 10, cash = 50000, xp = 600 },
		{ id = "pvpwin10", text = "Win 10 races against players", stat = "pvpwins", need = 10, cash = 60000, xp = 800 },
		{ id = "brands10", text = "Own cars from 10 brands", stat = "brands", need = 10, cash = 100000, xp = 1000 },
		{ id = "lvl40", text = "Reach level 40", stat = "level", need = 40, cash = 150000, xp = 0 },
		{ id = "car25", text = "Own 25 cars", stat = "cars", need = 25, cash = 250000, xp = 2000 },
		{ id = "mile1000", text = "Drive 1,000 miles", stat = "miles", need = 1000, cash = 250000, xp = 2000 },
		{ id = "allcars", text = "King of the City: own every car", stat = "cars", need = -1, cash = 1000000, xp = 5000 }, -- (need -1: every car)
	},
	-- the daily streak: day 1..6 cash, day 7 a free Mid car you don't own (or StreakCarCash)
	Streak = { 5000, 8000, 12000, 18000, 25000, 35000 },
	StreakCarMaxPrice = 120000, -- the day-7 car: a Mid car at or under this price
	StreakCarCash = 60000, -- ...or this, when you own them all
	StreakCooldown = 20 * 60 * 60, -- a claim opens this long after the last one
	StreakGrace = 48 * 60 * 60, -- more than this since the last claim: back to day 1
	-- daily tasks: 3 a day from this pool; cash grows with level (x1 at level 1 .. x3 at level 41+)
	TasksPerDay = 3,
	Tasks = {
		{ id = "cuts", text = "Cut up %d cars", stat = "cuts", need = 40, cash = 6000, xp = 150 },
		{ id = "combo", text = "Hit a x%d combo", stat = "combo", need = 8, cash = 6000, xp = 150, best = true },
		{ id = "miles", text = "Drive %d miles", stat = "miles", need = 10, cash = 5000, xp = 150 },
		{ id = "drifts", text = "Bank %d drifts", stat = "drifts", need = 3, cash = 6000, xp = 150 },
		{ id = "traps", text = "Get %d speed trap medals", stat = "traps", need = 3, cash = 6000, xp = 150 },
		{ id = "jumps", text = "Land %d jumps", stat = "jumps", need = 3, cash = 5000, xp = 150 },
		{ id = "races", text = "Finish %d races", stat = "races", need = 2, cash = 6000, xp = 150 },
		{ id = "jobs", text = "Finish %d delivery jobs", stat = "jobs", need = 2, cash = 6000, xp = 150 },
		{ id = "pvp", text = "Race against players %d times", stat = "pvp", need = 2, cash = 8000, xp = 200 },
		{ id = "escapes", text = "Get away from the police %d time", stat = "escapes", need = 1, cash = 8000, xp = 200 },
	},
	TaskLevelBoost = 0.05, -- task cash x(1 + this per level above 1), at most x3
}

---------------------------------------------------------------------
-- Car classes, car levels and parts (owner, 2026-11-03: "car class grades and car levels")
--   * every car has a Performance Index (PI, 100-999) worked out from its numbers (CarStats.pi):
--     0-60, power-to-weight, top speed, handling, braking and weight; its class letter comes
--     from these ranges
--   * cars cost money only; class X also needs this player level (owner: "price only, X needs
--     level 60"). The player level stays for XP, rewards and goals.
---------------------------------------------------------------------
Config.CarClasses = {
	-- { letter, lowest PI, highest PI } (owner picked the suggested ranges)
	Ranges = {
		{ "D", 100, 400 },
		{ "C", 401, 500 },
		{ "B", 501, 600 },
		{ "A", 601, 700 },
		{ "S1", 701, 750 },
		{ "S2", 751, 800 },
		{ "R", 801, 900 },
		{ "X", 901, 999 },
	},
	-- our own badge colours (same idea as the racing games: one colour per class)
	Colors = {
		D = Color3.fromRGB(110, 196, 228),
		C = Color3.fromRGB(116, 214, 112),
		B = Color3.fromRGB(246, 196, 56),
		A = Color3.fromRGB(255, 136, 40),
		S1 = Color3.fromRGB(236, 64, 64),
		S2 = Color3.fromRGB(184, 76, 226),
		R = Color3.fromRGB(64, 112, 255),
		X = Color3.fromRGB(255, 52, 150),
	},
	XLevel = 60, -- the player level class X cars need at the dealer
	-- how much each number counts towards the PI (they add up to 1) and the range each is read in
	Weights = { accel = 0.2, power = 0.4, speed = 0.12, grip = 0.17, brake = 0.05, weight = 0.06 },
	SpeedCurve = 1.3, -- top speed counts more and more near the top
	Accel = { 11, 2.2 }, -- 0-60 mph seconds: the first scores 0, the second 1 (log scale)
	Power = { 90, 800 }, -- power-to-weight, hp per tonne (log scale)
	Speed = { 90, 275 }, -- top speed mph
	Grip = { 0.45, 0.97 }, -- Handling
	Weight = { 2800, 1200 }, -- kg (lighter scores higher)
	Map = { 0.03, 0.993 }, -- the weighted score that becomes PI 100 and PI 999
	Curve = 1, -- (that share raised to this first: above 1 spreads the top)
}

-- the class letter and colour of a PI
function Config.carClass(pi: number): (string, Color3)
	local C = Config.CarClasses
	local letter = C.Ranges[1][1]
	for _, r in C.Ranges do
		if pi >= r[2] then
			letter = r[1]
		end
	end
	return letter, C.Colors[letter] or Color3.new(1, 1, 1)
end

-- Car levels: each car you own levels up from 1 to Max by driving it. A car earns the player XP you
-- get in it (Sources: driving, cut-ups, races, drifts, speed traps, jumps, duels, police escapes,
-- jobs, the bank delivery) times FromPlayerXp; goals don't count. With about 1.5 XP a second of
-- mixed driving, 1 -> 50 takes about 2.5-3 hours (owner: "fast levelling")
Config.CarLevels = {
	Max = 50,
	XpBase = 150, -- car XP from level 1 to 2
	XpStep = 6, -- each level after needs this much more (1 -> 50: about 14,400 XP in all)
	FromPlayerXp = 1,
	Sources = { drive = true, cut = true, race = true, drift = true, ["speed trap"] = true, jump = true, duel = true, escape = true, job = true, bank = true },
	CpPerLevel = 1, -- Car Points for each level (owner: "1 CP per level"; 49 by level 50)
	-- brand discount (owner): each of a brand's cars at level 50 takes this off that brand's dealer
	-- prices, up to BrandMax (5 cars). The brand levels (Config.Brands) stay as well (owner: "keep both")
	BrandOff = 0.05,
	BrandMax = 0.25,
	-- Legends Customs looks can be paid with the car's CP too (owner: "both"): CP per change
	LookCp = { paint = 1, finish = 1, accent = 1, tint = 1, glow = 2, rim = 1, plate = 1, head = 1 },
}

-- car XP needed to go from `level` to `level + 1`
function Config.carXpFor(level: number): number
	local L = Config.CarLevels
	return math.floor(L.XpBase + L.XpStep * (math.max(1, level) - 1))
end

-- Performance parts (owner: "8 parts", 3 stages, from car level 1 in any order; paid with the car's
-- CP or cash, the server checks and saves). Each stage replaces the one before; the numbers are what
-- that stage does in all: accel = 0-60 time cut, speed = top speed added, grip = Handling added,
-- brake = braking force added, weight = weight taken off (shares), pi = PI added after the rest
-- (the flywheel's is below 0). They raise the car's PI and can move it up a class.
-- (owner, 2026-11-03: "you can't just upgrade engines like that, you have to press engine and then
-- upgrade these") Engine is a menu of its own 5 parts (Groups.engine), with the racing games' rules:
--   * Intake & Manifold works with the exhaust: past the exhaust's stage it gives half (IntakeOverExhaust)
--   * Ignition & Fuel is cheap; Race Camshafts without Race Fuel flatline (count as Sport)
--   * a lighter Flywheel revs quicker but lowers the PI
--   * Displacement gives the most power and PI and costs the most: fit it last
Config.CarParts = {
	-- the parts screen's rows ("engine" opens its group)
	Menu = { "engine", "turbo", "exhaust", "gearbox", "tyres", "brakes", "suspension", "weight" },
	-- every part key (saved, on the car's "Parts" attribute)
	Keys = { "intake", "fuel", "flywheel", "cams", "displacement", "turbo", "exhaust", "gearbox", "tyres", "brakes", "suspension", "weight" },
	Groups = {
		engine = { name = "Engine", icon = "⚙", parts = { "intake", "fuel", "flywheel", "cams", "displacement" } },
	},
	Stages = { "STREET", "SPORT", "RACE" },
	IntakeOverExhaust = 0.5, -- an intake above the exhaust's stage gives this share of the extra
	-- (owner, 2026-11-03: "S2 and R and X cars that are already in that range stock from the
	-- dealership, not tuneable except tyres, gearbox, suspension, exhaust, otherwise it would be too
	-- overpowered"; looks at Legends Customs aren't limited)
	TopClasses = { S2 = true, R = true, X = true }, -- by the car's stock class
	TopAllowed = { tyres = true, gearbox = true, suspension = true, exhaust = true },
	Cp = { 2, 5, 10 }, -- CP for each stage (owner: about 2 / 5 / 10)
	Cash = { 1500, 4000, 10000 }, -- cash for each stage, times the car's price factor:
	CashRef = 50000, --   (car price / CashRef) ^ 0.5, from 1 to CashMax
	CashMax = 10,
	-- (cp / cashK: a part's own CP per stage and cash multiplier, when not the usual)
	Parts = {
		intake = { name = "Intake & Manifold", icon = "⚙", hint = "Breathes with the exhaust: past the exhaust's stage it gives half", stages = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.015 } } },
		fuel = { name = "Ignition & Fuel System", icon = "⚙", hint = "Cheap power. Race Camshafts need Race Fuel", cp = { 1, 2, 4 }, cashK = 0.5, stages = { { accel = 0.005 }, { accel = 0.01 }, { accel = 0.02 } } },
		flywheel = { name = "Flywheel", icon = "⚙", hint = "Revs quicker, but lowers the PI a little", cp = { 1, 3, 6 }, cashK = 0.6, stages = { { accel = 0.005, weight = 0.003, pi = -3 }, { accel = 0.01, weight = 0.006, pi = -6 }, { accel = 0.015, weight = 0.01, pi = -10 } } },
		cams = { name = "Camshafts, Pistons & Valves", icon = "⚙", hint = "High-rev power. Race needs Race Fuel or it flatlines", stages = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.02 } } },
		displacement = { name = "Displacement", icon = "⚙", hint = "The most power and the most PI: fit it last", cp = { 4, 8, 15 }, cashK = 2, stages = { { accel = 0.02, speed = 0.01 }, { accel = 0.04, speed = 0.015 }, { accel = 0.06, speed = 0.025 } } },
		turbo = { name = "Turbo", icon = "🌀", stages = { { accel = 0.02, speed = 0.01 }, { accel = 0.04, speed = 0.02 }, { accel = 0.06, speed = 0.03 } } },
		exhaust = { name = "Exhaust", icon = "💨", stages = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.015 } } },
		gearbox = { name = "Gearbox", icon = "⚙", stages = { { accel = 0.015, speed = 0.01 }, { accel = 0.03, speed = 0.02 }, { accel = 0.05, speed = 0.03 } } },
		tyres = { name = "Tyres", icon = "◎", stages = { { grip = 0.02, brake = 0.03 }, { grip = 0.04, brake = 0.06 }, { grip = 0.07, brake = 0.1 } } },
		brakes = { name = "Brakes", icon = "◉", stages = { { brake = 0.08 }, { brake = 0.16 }, { brake = 0.25 } } },
		suspension = { name = "Suspension", icon = "⇕", stages = { { grip = 0.015 }, { grip = 0.03 }, { grip = 0.05 } } },
		weight = { name = "Weight Reduction", icon = "▽", stages = { { weight = 0.03 }, { weight = 0.06 }, { weight = 0.1 } } },
	},
}

-- the cash price of a part stage on a car of this price (`key`: the part, for its own multiplier)
function Config.partCash(stage: number, carPrice: number, key: string?): number
	local P = Config.CarParts
	local k = math.clamp((math.max(carPrice, 1) / P.CashRef) ^ 0.5, 1, P.CashMax)
	local def = if key then P.Parts[key] else nil
	return math.floor((P.Cash[stage] or 0) * k * ((def and def.cashK) or 1) / 100 + 0.5) * 100
end

-- the CP price of a part stage
function Config.partCp(stage: number, key: string?): number
	local P = Config.CarParts
	local def = if key then P.Parts[key] else nil
	return ((def and def.cp) or P.Cp)[stage] or 0
end

-- Brand levels (owner, 2026-10-30, from the research: Midnight Racing's manufacturer levels):
-- driving a brand's cars levels the brand up; each level takes CustomsOff off Legends Customs on
-- its cars (2026-11-03: cars have no level locks any more, so TrimEvery / TrimMax do nothing now)
Config.Brands = {
	XpPerMile = 12,
	XpPerCut = 3,
	Levels = { 0, 150, 400, 900, 1800, 3200, 5200, 8000, 12000, 18000 }, -- brand XP for level 1..10
	CustomsOff = 0.05, -- per brand level above 1 (at most 45% off)
	TrimEvery = 2, -- brand levels per player level off a trim's requirement
	TrimMax = 5,
}

function Config.brandLevel(xp: number): number
	local lvl = 1
	for k, need in Config.Brands.Levels do
		if xp >= need then
			lvl = k
		end
	end
	return lvl
end

function Config.brandCustomsMult(level: number): number
	return 1 - math.min(0.45, (math.max(1, level) - 1) * Config.Brands.CustomsOff)
end

function Config.brandTrimBonus(level: number): number
	return math.min(Config.Brands.TrimMax, math.floor((math.max(1, level) - 1) / Config.Brands.TrimEvery))
end

-- a daily task's cash at this level
function Config.taskCash(base: number, level: number): number
	local k = math.min(3, 1 + Config.Goals.TaskLevelBoost * (math.max(1, level) - 1))
	return math.floor(base * k / 100 + 0.5) * 100
end

return Config
