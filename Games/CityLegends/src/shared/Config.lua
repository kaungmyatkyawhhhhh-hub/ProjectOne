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
	-- (owner, 2026-11-06: the 350Z, the 330i and the Focus RS; until the Focus has its model the 540i
	-- stands in: `fallback`. The Camaro stood in for the A45 S and was far too fast for a free car)
	StarterChoices = {
		{ id = "nisun_350z", feel = "Grippy sports car" },
		{ id = "bnw_330i_g20", feel = "Quick, comfy sedan" },
		{ id = "dearb_focus_rs", feel = "All-wheel drive, drift mode", fallback = "bnw_540i", fallbackFeel = "Fast and comfy" },
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
	-- (2026-11-04) the marina car park by the yachts: supercars parked in some of its bays
	MarinaParked = 0, -- (owner, 2026-11-04: no parked cars here, players park their own)
	MarinaTiers = { "High" },
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
	return not Config.World.OldCity and workspace ~= nil and workspace:FindFirstChild("Riviera") ~= nil
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
	-- lanes each way on the streets, the roads that aren't yellow (owner, 2026-11-04: "Make the road 1+1
	-- for the roads which isnt yellow. The yellow road will stay the same"): 1 = one lane in the middle
	-- of each half (RivieraTraffic), 2 = the old two
	StreetLanes = 1,
	-- the Riviera Highway (the mountain highway, 2026-11-04, owner-away prompt: "at most 10 cars in
	-- total ... so players can drive fast"): traffic cars on it at once
	-- (10 before; owner, 2026-11-04: "add a little more cars on the highway (not alot) and make them go 120 kmh")
	RivieraHighwayMax = 12,
	RivieraHighwayMph = 74.6, -- 120 km/h, on the highways proper (the 1 + 1 passes keep their own pace)
	-- busy stretches (owner, 2026-11-04: "reduce a little bit of traffic on the road near the harbour", then
	-- "split some cars from the casnio road onto the harbour road, so its not too busy"): at most this many
	-- cars are placed in each circle, the rest go elsewhere round you. Casino: the Town Road past it;
	-- harbour: the Coast Road on the front and Harbour Street above it.
	BusyZones = {
		{ at = Vector3.new(13760, 0, 640), radius = 420, max = 13 }, -- harbour
		{ at = Vector3.new(14150, 0, 140), radius = 420, max = 8 }, -- casino
	} :: { { at: Vector3, radius: number, max: number } },
	-- streets that share the routes' cars: how many of the spots picked on them are used (others: StreetShare)
	StreetShareBy = { ["Harbour Street"] = 0.4, ["Casino Climb"] = 0.15 } :: { [string]: number },
	-- how readily a car leaves a route onto this street (others: LeaveRouteK): the climb from the casino road
	-- down to the harbour
	SplitTurnK = { ["Casino Climb"] = 0.6, ["Harbour Street"] = 0.3 } :: { [string]: number },
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
	"Enfurecido L140, LB724, LB834 and LB834 ZV, LB744 models by Ddiaz Design",
	"Enfurecido L147, Brava, Rosso Rampante F149 Riviera and F142 models by Ddiaz Design",
	"Dearborn C346 model by Ddiaz Design",
	"Stealth-Apex V10 Halo and Halo Circuit models by Ddiaz Design",
	"Enfurecido Classico 5000 model by Ddiaz Design (CC BY)",
	"Tri-Star Silber Z223 Royale V12 model by Ddiaz Design",
	"Tri-Star Silber X167 Royale model by Black Snow (CC BY)",
	"Speedmark P11 Spider model by Ddiaz Design (CC BY)",
	"Tri-Star Silber C197 Wingdoor model by Ddiaz Design",
	"British Vanguard Highland model by Ddiaz Design",
	"Sovereign Grand Tourer model by Ddiaz Design",
	"Horizon Z33 model by Ddiaz Design",
	"Bavarica Werkz G20 Sport model by Ddiaz Design",
	"Rosso Rampante F141 model by Ddiaz Design (CC BY)",
	"Tri-Star Silber R230 V12 Track model by Ddiaz Design",
	"Precision Type 42 V10 model by Ddiaz Design",
	"Precision Type 42 V10 Lightweight model by Ddiaz Design",
	"Precision 4S V10 model by Ddiaz Design",
	"Bavarica Werkz E60 V10 model by Galaxy Car Showroom (CC BY 4.0)",
	"Sovereign Highlands model by Ddiaz Design (CC BY-NC-SA 4.0)",
	"Horizon R35 model by Ddiaz Design (CC BY-NC-SA 4.0)",
	"Car trailer: \"Flatbed Baked\" by 3DE_Study (CC BY 4.0)",
	"Map shape: © OpenStreetMap contributors (ODbL)",
}

---------------------------------------------------------------------
-- Economy
---------------------------------------------------------------------
-- Harder cash (owner, 2026-11-07: "make the cash harder to get since the car prices change, but not
-- too hard to the point players quit"). The earn numbers all over this file are the old ones; the
-- block at the very end of this file scales them by these, so one number tunes each kind of money:
Config.Economy = {
	ActiveMult = 0.15, -- driving, cut-ups, races, drift, jumps, speed traps, chips, duels, property income
	JobMult = 0.085, -- delivery jobs (back to back they paid far more than anything else)
	HeistMult = 0.1, -- the bank
	ShowcaseMult = 0.05, -- the Gem Showcase
	GiftMult = 0.15, -- daily streak, weekly and welcome gifts
	TaskMult = 0.1, -- daily tasks
	PlaytimeCash = { 500, 1000, 1500, 3000 }, -- the 5 / 15 / 30 / 60 minute gifts (were 6K, 12K, 24K, 60K)
	LevelUpMult = 0.1, -- the cash on every level-up
	LevelGiftMult = 0.02, -- Legends Rewards' level gifts and chests
	WheelMult = 0.1, -- SPIN's cash prizes and price
	SuperWheelMult = 0.03, -- SUPER SPIN's
	GoalSmallMult = 0.4, -- Legends Path goals up to GoalSmallUpTo: the first hours stay rewarding
	GoalBigMult = 0.15,
	GoalSmallUpTo = 8000,
	PartPriceMult = 2.5, -- parts cost their real aftermarket price (PartData.Real) times this
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
	SkidMax = 200, -- the newest this many strips (2026-11-03: was 140)
	SkidLife = 45, -- seconds before a mark has faded away (was 7)

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
		TorqueSteer = 0.012, -- front-drive: a gentle pull (radians) on a hard launch
	},
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
	-- (2026-11-06) parts' sounds, all already in the game: pops and crackles for a car with none of its
	-- own (the SVJ's), a turbo's whine and a blow-off (the Bugattis')
	SharedPops = "rbxassetid://125121319222420",
	SharedCrackle = "rbxassetid://128716617727916",
	SharedTurbo = "rbxassetid://72711797703242",
	SharedBlowOff = "rbxassetid://95497630494219",
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

-- (owner, 2026-11-05: "replace the lp 700 exhaust sound with the SV's exhaust but make it 1.6 times
-- quieter and replace the start up with sound 6718630582, also make the exhaust sound realistic") the
-- LP700-4 plays the SV's loops and one-shots with its own start-up; quieter in Config.ExhaustVolume,
-- pitched from each loop's real engine speed in Config.ExhaustBands, timed in Config.ExhaustStart
-- (owner, 2026-11-05: "remove the pop and bangs on the lp700") so not the SV's Crackle, ShiftPop or
-- Pops, or its Shift clip (a bang at 0.4 s, 5 times the clip's level and louder than Pops: the upshift
-- is the note dropping, `shiftCut`); `noPops` in Config.ExhaustBands stops the shared backfire too
do
	for _, part in { "Idle", "Low", "Mid", "High", "Launch", "Redline", "Downshift" } do
		Config.Sounds["Exhaust_lambrini_lp700_" .. part] = Config.Sounds["Exhaust_lambrini_lp750_" .. part]
	end
	Config.Sounds.Exhaust_lambrini_lp700_Start = "rbxassetid://6718630582" -- "Lamborghini Aventador SVJ Startup" (1Rhymastic)
end

-- per-car exhaust loudness (every loop and one-shot of the car's set), 1 = as recorded
Config.ExhaustVolume = { lambrini_lp750 = 0.5, lambrini_lp700 = 0.5 / 1.6 } :: { [string]: number }

-- a car's own start-up clip, in seconds from pressing start: `idleAt` + `fade` the idle comes in,
-- `out` to `ends` the clip fades away (touching the throttle jumps to `out`), `settleFrom` the rpm the
-- clip ends on: the idle starts there and falls to its own rpm over `settle`. The LP700's clip: starter
-- to 0.8 s (when the engine catches in Driving), flare 4,700 rpm, 2,800 by 1.3 s, 1,340 at its end
-- (`gain`: the clip's loudness, 2026-11-09)
Config.ExhaustStart = {
	lambrini_lp700 = { idleAt = 1.9, fade = 0.5, out = 2.2, ends = 2.6, settleFrom = 1340, settle = 2.5 },
} :: { [string]: { idleAt: number, fade: number, out: number, ends: number, settleFrom: number?, settle: number?, gain: number? } }

-- the engine speed a one-shot was recorded at (by asset), so it's pitched to the revs it plays at: the
-- SVJ's downshift blip settles at ~4,200 rpm (its firing note)
Config.ExhaustShotRpm = { ["rbxassetid://109515735710638"] = 4200 } :: { [string]: number }

-- per-car exhaust bands: the rpm each loop was recorded at (the loop's pitch is the car's rpm over
-- this; bands crossfade between their rpms), and the turbos: `whine` the whine's pitch at full boost,
-- `seq` the rpm the second turbo pair comes in (sequential, the Chiron), `bov` the blow-off loudness;
-- `gain` all the loops' loudness, `gains` one band's on top (to level loops recorded louder or softer),
-- `width` how far each band reaches round its rpm (default 0.4; narrower = one recording heard at a time),
-- `reachDown` a band's own reach below its rpm, `coast` the EQ (dB) with the throttle shut: the note goes
-- dark and quiet on a lift, `shiftCut` seconds the note drops on an upshift (the ignition cut),
-- `loopRpm` the rpm the Launch and Redline loops were recorded at, `idleReach` / `idleTop` how far above
-- its rpm the idle loop lasts (default 0.28) and the highest it's pitched (default 1.45), `noPops` no
-- pops or bangs: none of the sounds and none of the exhaust flames that go with them (nitro keeps its own)
-- (2026-11-09) `gains.Redline` the limiter loop's loudness, `shots` each one-shot's loudness (Shift,
-- Downshift, Pops, BlowOff, EWhine), `turbo` the turbo whine's loudness, `liftPops = false` no pops when
-- you lift off (the car's own engine; a pop / crackle tune from the Part Shop still pops), `shiftPops =
-- false` no bang or flame on a hard upshift (a smooth dual-clutch car)
Config.ExhaustBands = {} :: { [string]: { bands: { [string]: number }, whine: number?, seq: number?, bov: number?, gain: number?, gains: { [string]: number }?, width: number?, reachDown: { [string]: number }?, coast: { mid: number, high: number }?, shiftCut: number?, loopRpm: { [string]: number }?, idleReach: number?, idleTop: number?, noPops: boolean?, shots: { [string]: number }?, turbo: number?, liftPops: boolean?, shiftPops: boolean? } }
do
	local chiron = { bands = { Idle = 950, Low = 3500, High = 6500 }, whine = 0.62, seq = 3800, bov = 1.0 }
	local veyron = { bands = { Idle = 950, Low = 3500 }, whine = 0.7, bov = 1.0 }
	for _, id in { "bugotti_veyron", "bugotti_veyron_sport", "bugotti_veyron_top" } do
		Config.ExhaustBands[id] = veyron
	end
	for _, id in { "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport" } do
		Config.ExhaustBands[id] = chiron
	end
	-- the LP700-4: the SV's loops, each pitched from its real engine speed, measured from its firing
	-- note in Studio (a V12 fires at rpm / 10 Hz: Idle 100 Hz, Low 502, Mid 600, High ~790, Launch 504,
	-- limiter 820), so every loop plays the same note at any revs. `gains` keep the SV's loudness of
	-- each loop (with ExhaustVolume: the SV's, 1.6 times quieter)
	Config.ExhaustBands.lambrini_lp700 = {
		bands = { Idle = 1000, Low = 5020, Mid = 6000, High = 7900 },
		-- (nothing is recorded between 1,000 and 5,000 rpm: Low reaches down and the idle reaches up,
		-- they meet near 2,200, where each is at the end of its pitch)
		width = 0.2, reachDown = { Low = 0.55 }, idleReach = 0.45, idleTop = 2.2,
		gains = { Idle = 0.53, Low = 1.4, Mid = 1.4, High = 0.83 },
		coast = { mid = -3, high = -12 },
		shiftCut = 0.09,
		loopRpm = { Launch = 5040, Redline = 8200 },
		noPops = true,
	}
end

---------------------------------------------------------------------
-- Supercar exhaust sounds by real engine (owner, 2026-11-09, Prompts/Realistic exhaust sounds for the
-- supercars (real engines).md: "find their actual engine; for example the Ferrari 458 will be a
-- flat-plane crank V8, naturally aspirated"). One sound set per engine family; each car on it gets small
-- changes (`volume`, `tone`: `pitch`, EQ `low` / `mid` / `high` in dB, `drive` = rawness). The Bugattis and
-- the ZV / ZVX / ZVX 63 keep their sounds (owner). A trim (SPORT / TOP) plays its base car's set.
--
-- Every id is public Creator Store audio (uploader in the comment; credits in City Legends.md). Each loop
-- was measured in Studio (AudioPlayer:GetWaveformAsync): its engine speed from the spacing of its
-- half-order lines (rpm / 120 Hz; checked on loops whose rpm is in their name: right to within 1%), its
-- loudness (the `gains` level each loop to the same step from idle to redline) and its loop point (no
-- click or jump in level). Clips that name a game, or look cut from one (on / off + rpm banks, "ext_on",
-- "[31]"), were left out.
--
-- To put a car back on its old sound: Config.SupercarExhaust.Off.<car id> = true (the LP700-4 then plays
-- the SV's loops again, the others the shared engine sound).
-- (`Cars` is filled below: the cars now on these sets)
Config.SupercarExhaust = { Enabled = true, Off = {} :: { [string]: boolean }, Cars = {} :: { [string]: boolean } }
-- per-car tone on top of its set: `pitch`, EQ `low` / `mid` / `high` (dB), `drive` (0..0.3 distortion)
Config.ExhaustTone = {} :: { [string]: { pitch: number?, low: number?, mid: number?, high: number?, drive: number? } }
-- (in a function of its own: its many constants in the main chunk crashed Lune's Luau)
local function supercarExhaust()
	local function id(n: number): string
		return "rbxassetid://" .. tostring(n)
	end
	local SVJ_POPS, SVJ_CRACKLE = Config.Sounds.SharedPops, Config.Sounds.SharedCrackle
	local V12_BLIP = "rbxassetid://109515735710638" -- the SVJ's downshift blip (in the game since 2026-11-03)
	local COAST = { mid = -3, high = -10 }
	local FAMILY: { [string]: any } = {
		-- Ferrari F136 V8, NA, flat-plane crank (458 4.5, F430 / California 4.3): high, sharp, to 9,000
		V8_FLATPLANE = {
			sounds = {
				Start = id(117250121821594), -- "458 startup" (SuperJMTABO): catches at once, flare ~2,500, settles ~720
				Idle = id(84053009150735), -- "458 idle" (xVlbez), 735 rpm
				Low = id(133285489196557), -- "458 Rev A_01" (xVlbez), 3,025 rpm
				Mid = id(100105615776941), -- "458 Rev B" (xVlbez), 5,090 rpm
				High = id(131194279941747), -- "458 Rev C" (xVlbez), 9,060 rpm
			},
			bands = {
				bands = { Idle = 735, Low = 3025, Mid = 5090, High = 9060 },
				gains = { Idle = 2.65, Low = 1.0, Mid = 1.31, High = 1.36 },
				width = 0.38, reachDown = { Low = 0.5 }, idleReach = 0.35, idleTop = 1.7,
				coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
			},
			start = { idleAt = 2.6, fade = 0.8, out = 3.0, ends = 4.2, settleFrom = 720, settle = 1.0, gain = 1.5 },
		},
		-- Ferrari F140 V12, 6.0 NA (599 GTO; the Enzo has the same engine family): a smooth, rising wail
		V12_F140 = {
			sounds = {
				Start = id(126951297346788), -- "Ferrari 599 GTO startup" (Noobsttkill): catches at 1.35 s, ~1,400 at its end
				Idle = id(132538972175033), -- "Ferrari Enzo Idle" (Tyudogg5), 1,240 rpm
				Low = id(106444431622928), -- "Ferrari 599 GTB Revloop" (e92nic), 4,690 rpm
				Mid = id(110907563356979), -- "599ex" (zonda_collector), 5,600 rpm
				High = id(77826592795280), -- "Ferrari Enzo Revloop" (Tyudogg5), 6,850 rpm
				Downshift = V12_BLIP,
			},
			bands = {
				bands = { Idle = 1240, Low = 4690, Mid = 5600, High = 6850 },
				gains = { Idle = 0.34, Low = 2.12, Mid = 0.47, High = 0.92 },
				width = 0.32, -- (close bands: one recording at a time)
				coast = COAST, shiftCut = 0.08, liftPops = false, shiftPops = false,
				shots = { Downshift = 2.0 },
			},
			start = { idleAt = 4.4, fade = 0.8, out = 4.8, ends = 6.0, settleFrom = 1400, settle = 1.5, gain = 1.64 },
		},
		-- Lamborghini 6.5 V12, NA (Murcielago LP650-4 / LP670-4 SV): deep, raw, old-school
		V12_MURCIELAGO = {
			sounds = {
				Start = id(120002975599821), -- "Lamborghini Murcielago Startup" (Tyudogg5)
				Idle = id(132862605780028), -- "Lamborghini Murcielago Idle" (Tyudogg5), 1,185 rpm
				Low = id(135017534787316), -- "Lamborghini Murcielago Revloop" (Tyudogg5), 3,740 rpm
				Mid = id(95944505132247), -- "LAMBORGHINI MURCIELAGO REV 55" (alakatz), 5,500 rpm
				High = id(71771238598620), -- "Lamborghini Murcielago Revloop" (Tyudogg5), 7,450 rpm
				Downshift = V12_BLIP,
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1185, Low = 3740, Mid = 5500, High = 7450 },
				gains = { Idle = 0.29, Low = 0.79, Mid = 0.38, High = 0.45 },
				coast = COAST, shiftCut = 0.12,
				shots = { Downshift = 2.0, Pops = 1.3 },
			},
			start = { idleAt = 2.2, fade = 0.4, out = 2.4, ends = 2.74, settleFrom = 1530, settle = 2.0, gain = 0.66 },
		},
		-- Lamborghini L539 6.5 V12, NA (Aventador LP700-4): a screaming V12; the single-clutch ISR gearbox
		-- cracks on every upshift
		V12_AVENTADOR = {
			sounds = {
				Start = id(103478790721598), -- "Lamborghini Aventador Startup" (Tyudogg5): flare ~4,900, ~1,740 at its end
				Idle = id(91209556236511), -- "Lamborghini Aventador Idle" (Tyudogg5), 850 rpm
				Low = id(10006383812), -- "Aventador S Revloop fixed" (AmikkuHedgehog), 3,905 rpm
				High = id(80757676040270), -- "Lamborghini Aventador Rev" (Tyudogg5), 7,880 rpm
				Redline = id(137849905001581), -- "Limiter (Red) Aventador (1)" (KVERTH): the limiter, ~8,300
				Shift = id(97354969724257), -- "Aventador SVJ Crackle1" (Adhamkhedrhuman): the ISR crack
				Downshift = V12_BLIP,
			},
			bands = {
				bands = { Idle = 850, Low = 3905, High = 7880 },
				gains = { Idle = 0.62, Low = 0.43, High = 0.81, Redline = 0.69 },
				width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
				loopRpm = { Redline = 8300 },
				coast = COAST, shiftCut = 0.12,
				-- (owner, 2026-11-05: no pops and bangs on the LP700 when you lift; the shift crack is the gearbox)
				noPops = true,
				shots = { Shift = 3.6, Downshift = 2.0 },
			},
			start = { idleAt = 4.4, fade = 0.6, out = 4.8, ends = 5.3, settleFrom = 1740, settle = 2.5, gain = 1.56 },
		},
		-- Lamborghini L545 6.5 V12 + 3 electric motors (Revuelto): V12 to 9,500, a soft electric whine pulling away
		V12_REVUELTO = {
			sounds = {
				Start = id(80946715098566), -- "Revuelto Startup" (noobsttkillsounds), ~1,550 at its end
				Idle = id(91209556236511), -- the Aventador's idle (same V12 family; no clean Revuelto idle loop)
				Low = id(10006383812), -- "Aventador S Revloop fixed" (AmikkuHedgehog), 3,905 rpm
				High = id(138122265243234), -- "Revuelto Rev" (Cotten_Hill), 7,970 rpm
				Downshift = V12_BLIP,
				EWhine = id(9116980190), -- "Motor Whine Electric Whirring Buzzing 8 (SFX)" (ProSoundEffects)
			},
			bands = {
				bands = { Idle = 850, Low = 3905, High = 7970 },
				gains = { Idle = 0.62, Low = 0.43, High = 0.40 },
				width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
				coast = COAST, shiftCut = 0.05, shiftPops = false,
				shots = { Downshift = 2.0, EWhine = 1.0 },
			},
			start = { idleAt = 3.0, fade = 0.5, out = 3.2, ends = 3.76, settleFrom = 1550, settle = 2.0, gain = 0.94 },
		},
		-- Lamborghini 5.2 V12 with carburettors (Countach 5000 QV): intake roar, lots of character
		V12_COUNTACH = {
			sounds = {
				Start = id(88964621513263), -- "countach startup" (RSSUPER56), ~1,040 at its end
				Idle = id(18326228444), -- "Countach_idle" (ProGamersCh2), 1,030 rpm
				Low = id(135017534787316), -- the Murcielago's 3,740 rpm loop (the same Lamborghini V12 line)
				High = id(82845556133822), -- "LAMBORGHINI_COUNTACH_REVLOOP_22" (Chxvrxlet), 7,720 rpm
				Downshift = V12_BLIP,
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1030, Low = 3740, High = 7720 },
				gains = { Idle = 0.77, Low = 0.79, High = 3.22 },
				width = 0.42, coast = COAST, shiftCut = 0.15,
				shots = { Downshift = 1.6, Pops = 1.2 },
			},
			start = { idleAt = 3.3, fade = 0.6, out = 3.6, ends = 4.6, settleFrom = 1040, settle = 0.5, gain = 0.88 },
		},
		-- Lamborghini / Audi 5.2 V10, NA (Gallardo, Huracan, R8): a hard-edged howl
		V10 = {
			sounds = {
				Start = id(120452275990108), -- "Lamborghini Huracan Startup" (Tyudogg5), ~1,470 at its end
				Idle = id(87192192605296), -- "r8 idle" (TBWK128), 1,166 rpm
				Low = id(967630175), -- "Huracan Rev" (imawsome220), 4,080 rpm
				High = id(107508835832190), -- "2023 Lamborghini Huracan Tecnica_REDLINE" (w3xoq), 7,780 rpm
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1166, Low = 4080, High = 7780 },
				gains = { Idle = 0.53, Low = 0.39, High = 1.39 },
				width = 0.36, reachDown = { Low = 0.5 },
				coast = COAST, shiftCut = 0.06, shiftPops = false,
			},
			start = { idleAt = 2.2, fade = 0.5, out = 2.4, ends = 2.85, settleFrom = 1470, settle = 1.5, gain = 0.61 },
		},
		-- (owner, 2026-11-10: "Change all the R8 and hurcan rev loop to this: 77659121594090") the Huracans and the
		-- R8s: the V10 set with that one rev loop in place of the two Huracan loops (the Gallardos keep V10)
		V10_REV = {
			sounds = {
				Start = id(120452275990108), -- "Lamborghini Huracan Startup" (Tyudogg5), ~1,470 at its end
				Idle = id(87192192605296), -- "r8 idle" (TBWK128), 1,166 rpm
				High = id(77659121594090), -- "V10_rev" (Simonko9955), 6,920 rpm (steady over its 7.2 s, no jump at the seam)
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1166, High = 6920 },
				gains = { Idle = 0.53, High = 0.27 }, -- (a loud clip: rms 0.61, the old 7,780 loop's 0.12 at 1.39)
				width = 0.42, reachDown = { High = 0.6 }, idleReach = 0.4, idleTop = 1.8,
				coast = COAST, shiftCut = 0.06, shiftPops = false,
			},
			start = { idleAt = 2.2, fade = 0.5, out = 2.4, ends = 2.85, settleFrom = 1470, settle = 1.5, gain = 0.61 },
		},
		-- Toyota 1LR-GUE 4.8 V10, NA (LFA): the high, very fast F1-like scream
		LFA = {
			sounds = {
				Start = id(113328555788876), -- "lfa startup" (HaruHado), ~1,150 at its end
				Idle = id(105486944192315), -- "LFA Idle" (zonda_collector), 1,156 rpm
				Low = id(6927392752), -- "LFA Exhaust" (Basic42), 3,760 rpm
				Mid = id(6486544609), -- "Lexus LFA Revloop1" (Basic42), 7,990 rpm
				High = id(6486438800), -- "Lexus V10" (Basic42), 9,470 rpm
			},
			bands = {
				bands = { Idle = 1156, Low = 3760, Mid = 7990, High = 9470 },
				gains = { Idle = 0.50, Low = 1.97, Mid = 0.45, High = 0.66 },
				reachDown = { Low = 0.5 },
				coast = COAST, shiftCut = 0.1, liftPops = false, shiftPops = false,
			},
			start = { idleAt = 3.6, fade = 0.6, out = 4.0, ends = 5.0, settleFrom = 1150, settle = 0.6, gain = 0.55 },
		},
		-- McLaren 3.8 twin-turbo V8, flat-plane (12C): a rasp with the turbos' whoosh and flutter. No clean
		-- 12C loops: these are the 720S's (its 4.0 is the same engine grown)
		V8_TWINTURBO = {
			sounds = {
				Start = id(136200211585476), -- "Startup 720S" (KVERTH), ~1,450 at its end
				Idle = id(78621869530140), -- "Idle 720s" (KVERTH), 1,430 rpm
				Low = id(102329538428291), -- "mclaren_720s_spider_middle" (ieu1713), 4,960 rpm
				High = id(74484380782795), -- "RevA 720s" (KVERTH), 8,070 rpm
				Turbo = Config.Sounds.SharedTurbo,
				BlowOff = id(117842945197592), -- "sfx_super-car-turbo-flutter-01" (AmikkuHedgehog)
				Downshift = id(114401892748128), -- "MCLARENV8DOWNSHIFT1" (YaBoyZenvo)
			},
			bands = {
				bands = { Idle = 1430, Low = 4960, High = 8070 },
				gains = { Idle = 0.47, Low = 0.39, High = 0.39 },
				width = 0.42, whine = 0.55, bov = 0.8, turbo = 0.6,
				coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
				shots = { Downshift = 0.85 },
			},
			start = { idleAt = 1.45, fade = 0.4, out = 1.6, ends = 2.03, settleFrom = 1450, settle = 0.3, gain = 1.04 },
		},
		-- Mercedes-AMG M159 6.2 V8, NA, cross-plane crank (SLS): deep muscle-car thunder, loud crackles
		V8_CROSSPLANE = {
			sounds = {
				Start = id(122484115722819), -- "SLS start" (B0tzep), ~1,150 at its end
				Idle = id(86966846628695), -- "Idle SLS" (B0tzep), 1,121 rpm
				Low = id(82458196515450), -- "SLS Engine RPM3" (lontanyl), 3,260 rpm
				High = id(124254451477176), -- "SLS Engine RPM10" (lontanyl), 5,415 rpm
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1121, Low = 3260, High = 5415 },
				gains = { Idle = 0.24, Low = 1.96, High = 2.90 },
				coast = COAST, shiftCut = 0.08,
				shots = { Pops = 1.6 },
			},
			start = { idleAt = 3.0, fade = 0.5, out = 3.3, ends = 4.0, settleFrom = 1150, settle = 0.5, gain = 0.81 },
		},
		-- Porsche 4.0 flat-6, NA (911 GT3): metallic, rising howl to 9,000, PDK blips on the way down
		FLAT6 = {
			sounds = {
				Start = id(131868759155566), -- "Porsche 911 GT3 Startup" (Tyudogg5), ~1,300 at its end
				Idle = id(90645713888895), -- "Idle GT3RS" (KVERTH), 1,302 rpm
				Low = id(123035578761975), -- "Porsche 911 GT3 Rev" (Tyudogg5), 4,610 rpm
				Mid = id(83330624942853), -- "Porsche 911 GT3 Rev" (Tyudogg5), 6,610 rpm
				High = id(107579237097468), -- "Porsche 911 GT3 Revloop" (Tyudogg5), 7,780 rpm
				Redline = id(91195272918788), -- "Porsche 911 GT3 Redline Rev-Limiter" (Tyudogg5), ~8,650
				Downshift = id(17552549922), -- "downshift flat six redo" (Thirty3Works): the blip, settles ~5,150
			},
			bands = {
				bands = { Idle = 1302, Low = 4610, Mid = 6610, High = 7780 },
				gains = { Idle = 0.40, Low = 0.48, Mid = 0.67, High = 1.22, Redline = 0.82 },
				loopRpm = { Redline = 8645 },
				coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
				shots = { Downshift = 0.48 },
			},
			start = { idleAt = 2.6, fade = 0.6, out = 3.0, ends = 4.0, settleFrom = 1330, settle = 0.5, gain = 0.89 },
		},
		-- (owner, 2026-11-10: "don't forget to add exhaust sounds for them if they don't have": the six
		-- imports of Prompts/Finish the 7 waiting imports that had no set; found, measured and levelled the
		-- same way as the sets above. Not heard by ear.)
		-- BMW S85 5.0 V10, NA (E60 M5): odd-firing, so a strong 2.5 order under the 5th; to 8,250
		V10_S85 = {
			sounds = {
				Start = id(92477496018635), -- "e60 m5 start" (313Dday): catches at 1.05 s, ~930 at its end
				Idle = id(91710929912172), -- "e60_m5_exh_idle" (imziIo), 905 rpm
				Low = id(81767984377994), -- "RevB & RelB M5 E60 New" (KVERTH), 5,617 rpm
				High = id(72998982295293), -- "RevA & RelA M5 E60 New" (KVERTH), 8,287 rpm
			},
			bands = {
				bands = { Idle = 905, Low = 5617, High = 8287 },
				gains = { Idle = 0.34, Low = 0.43, High = 0.57 },
				-- (nothing is recorded between 905 and 5,617 rpm: Low reaches down and the idle reaches up)
				width = 0.42, reachDown = { Low = 0.6 }, idleReach = 0.45, idleTop = 2.2,
				coast = COAST, shiftCut = 0.12, liftPops = false, shiftPops = false, -- (the SMG's cut)
			},
			start = { idleAt = 1.7, fade = 0.5, out = 2.0, ends = 2.5, settleFrom = 930, settle = 0.5, gain = 0.77 },
		},
		-- BMW S65 4.0 / 4.4 V8, NA, cross-plane (E92 M3 / GTS): to 8,300
		V8_S65 = {
			sounds = {
				Start = id(18527193586), -- "M3 E92 STRAIGHTPIPE IGNITION" (r3_vl): catches at 0.75 s, ~1,180 at its end
				Idle = id(73671901945692), -- "M3 E92 idle crossplaned" (metius311), 1,430 rpm
				Low = id(100211620676087), -- "RevB E92 Gintani" (omega123058), 5,239 rpm
				High = id(123715831140370), -- "RevA and RelA E92 Gintani" (omega123058), 8,109 rpm
			},
			bands = {
				-- (tried and dropped: metius311's 2,019 rpm loop 111331460009411 as a band right above the idle:
				-- coasting down through 1,700 rpm the note went 2 times quieter between the two)
				bands = { Idle = 1430, Low = 5239, High = 8109 },
				gains = { Idle = 0.78, Low = 0.74, High = 0.61 },
				reachDown = { Low = 0.5 },
				coast = COAST, shiftCut = 0.05, liftPops = false, shiftPops = false,
			},
			start = { idleAt = 3.3, fade = 0.5, out = 3.6, ends = 4.3, settleFrom = 1180, settle = 1.0, gain = 0.81 },
		},
		-- BMW S55 3.0 twin-turbo straight-6 (F82 M4): firing at the 3rd order with the 1.5 / 4.5 of its two
		-- turbos; whine, a blow-off on the lift, a few burbles
		I6_TWINTURBO = {
			sounds = {
				Start = id(94137111764818), -- "S55Startup" (YaBoyZenvo), ~1,210 at its end
				Idle = id(81564166436366), -- "S55 idle crossfade" (metius311), 1,190 rpm
				Low = id(111740167050459), -- "s55.low" (ObIiveracy), 4,101 rpm
				Mid = id(85381791243117), -- "RevB S55" (KVERTH), 5,773 rpm
				High = id(127910564907665), -- "RevA S55" (KVERTH), 7,129 rpm
				Redline = id(92088361930636), -- "Red S55" (KVERTH): the limiter, ~7,430
				Turbo = Config.Sounds.SharedTurbo,
				BlowOff = id(108432076069136), -- "turbo bov s58" (RedfieldBSAA): the S55's successor
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 1190, Low = 4101, Mid = 5773, High = 7129 },
				gains = { Idle = 1.10, Low = 0.39, Mid = 0.42, High = 0.48, Redline = 0.61 },
				loopRpm = { Redline = 7432 },
				reachDown = { Low = 0.5 }, whine = 0.55, bov = 1.1, turbo = 0.6,
				coast = COAST, shiftCut = 0.05, shiftPops = false,
				shots = { Pops = 0.7 },
			},
			start = { idleAt = 1.5, fade = 0.4, out = 1.8, ends = 2.38, settleFrom = 1210, settle = 0.5, gain = 0.86 },
		},
		-- BMW S63 4.4 twin-turbo V8, cross-plane, turbos in the V (F90 M5 / M5 CS): a strong 2nd order
		V8_S63 = {
			sounds = {
				Start = id(103612899870303), -- "Startup M5" (KVERTH): catches at 0.6 s, ~1,460 at its end
				Idle = id(92369296738404), -- "F90CSIDLE2" (Rezixtxc), 900 rpm
				Low = id(86560702684802), -- "F90CSMID_012" (Rezixtxc), 4,602 rpm
				High = id(123277157456191), -- "F90CSHIGH_012" (Rezixtxc), 6,402 rpm
				Redline = id(112552469972463), -- "F90CSLIMITER_012" (Rezixtxc): the limiter, ~6,610
				Turbo = Config.Sounds.SharedTurbo,
				BlowOff = id(108749717618927), -- "TURBO FLUTTER M5 F90" (ThisIsGrandee)
				Pops = SVJ_POPS,
				Crackle = SVJ_CRACKLE,
			},
			bands = {
				bands = { Idle = 900, Low = 4602, High = 6402 },
				gains = { Idle = 0.83, Low = 0.57, High = 0.58, Redline = 1.43 },
				loopRpm = { Redline = 6608 },
				width = 0.42, reachDown = { Low = 0.55 }, idleReach = 0.4, idleTop = 1.8,
				whine = 0.55, bov = 1.1, turbo = 0.6,
				coast = COAST, shiftCut = 0.08, shiftPops = false,
				shots = { Pops = 0.7 },
			},
			start = { idleAt = 1.2, fade = 0.5, out = 1.5, ends = 2.4, settleFrom = 1460, settle = 1.5, gain = 0.67 },
		},
		-- VW group 4.0 twin-turbo V8 (Bentayga V8). No clean Bentayga V8 loops (the "bentayga" idle and
		-- start-up in the store are the W12): these are an Audi RS7's, the same engine, their rpm given by
		-- the uploader and measured the same
		V8_VW40 = {
			sounds = {
				Start = id(114174944994309), -- "Audi RS7 MNSRY Startup" (FinanceTrend): catches at 1.05 s, ~1,470 at its end
				Idle = id(100620796837132), -- "Audi RS7 MNSRY Idle" (FinanceTrend), ~1,050 rpm
				Low = id(107993163342852), -- "Audi RS7 MNSRY RevA" (FinanceTrend), 2,999 rpm
				High = id(135208328060016), -- "Audi RS7 MNSRY RevB" (FinanceTrend), 5,494 rpm
				Redline = id(105083828781421), -- "Audi RS7 MNSRY Redline" (FinanceTrend): the limiter, 6,994
				Turbo = Config.Sounds.SharedTurbo,
			},
			bands = {
				bands = { Idle = 1050, Low = 2999, High = 5494 },
				gains = { Idle = 0.25, Low = 0.41, High = 0.56, Redline = 0.64 },
				loopRpm = { Redline = 6994 },
				width = 0.42, reachDown = { Low = 0.5 }, whine = 0.5, turbo = 0.3,
				coast = COAST, shiftCut = 0.1, liftPops = false, shiftPops = false,
			},
			start = { idleAt = 2.4, fade = 0.6, out = 2.8, ends = 3.9, settleFrom = 1470, settle = 1.5, gain = 0.96 },
		},
		-- Nissan VR38DETT 3.8 twin-turbo V6 (R35 GT-R): firing at the 3rd order, the turbos' whoosh and flutter
		V6_TWINTURBO = {
			sounds = {
				Start = id(8393134777), -- "Nissan GTR R35 (VR38DETT) Startup" (EfiniRX): catches at 0.75 s, ~1,290 at its end
				Idle = id(119747324235535), -- "nissan gtr idle" (jeemuzujamin), 1,255 rpm
				Low = id(86018842069517), -- "r35 low rev" (imkn32), 3,320 rpm
				Mid = id(130132947354022), -- "nissan gtr high" (jeemuzujamin), 5,862 rpm
				High = id(106611475215254), -- "GTR R35" (vamytran78965), 6,907 rpm
				Turbo = Config.Sounds.SharedTurbo,
				BlowOff = id(130283408353912), -- "VR38 Pop Off Flutter" (cezuuya)
			},
			bands = {
				bands = { Idle = 1255, Low = 3320, Mid = 5862, High = 6907 },
				gains = { Idle = 0.48, Low = 0.69, Mid = 0.74, High = 0.57 },
				reachDown = { Low = 0.5 }, whine = 0.6, bov = 0.5, turbo = 0.7,
				coast = COAST, shiftCut = 0.06, liftPops = false, shiftPops = false,
			},
			start = { idleAt = 1.9, fade = 0.5, out = 2.2, ends = 2.9, settleFrom = 1290, settle = 0.5, gain = 1.2 },
		},
	}
	local GALLARDO = {
		sounds = {
			Start = id(104916533556412), -- "GallardoStartup" (YaBoyZenvo), ~1,490 at its end
			Idle = id(118435710042398), -- "GallardoEngineIdle" (YaBoyZenvo), 1,030 rpm
		},
		bands = { bands = { Idle = 1030 }, gains = { Idle = 0.27 }, shiftCut = 0.12 },
		start = { idleAt = 3.9, fade = 0.6, out = 4.2, ends = 4.98, settleFrom = 1490, settle = 2.0, gain = 0.55 },
	}
	local R8_START = {
		sounds = { Start = id(94856442609554) }, -- "V10R8Startup" (Teslaprodriv), ~1,400 at its end
		start = { idleAt = 3.6, fade = 0.5, out = 3.9, ends = 4.7, settleFrom = 1400, settle = 1.5, gain = 1.08 },
	}
	local F430_START = {
		sounds = { Start = id(133124486022122) }, -- "F430ScudStart" (FreeIsaacbolarini), ~1,750 at its end
		start = { idleAt = 2.9, fade = 0.6, out = 3.2, ends = 3.8, settleFrom = 1750, settle = 2.0, gain = 0.62 },
	}
	-- each car: its family, then its own changes (`with`: shared extra parts, `volume`, `tone`, `bands`)
	local CARS: { [string]: any } = {
		ferrara_458 = { family = "V8_FLATPLANE" },
		ferrara_458spider = { family = "V8_FLATPLANE", volume = 1.05, tone = { high = 1 } },
		ferrara_458speciale = { family = "V8_FLATPLANE", volume = 1.15, tone = { drive = 0.1, high = 2 } }, -- rawer
		ferrara_f430 = { family = "V8_FLATPLANE", with = F430_START, tone = { high = 2 }, bands = { shiftCut = 0.1 } }, -- F1 gearbox
		ferrara_california = { family = "V8_FLATPLANE", volume = 0.72, tone = { high = -3 }, bands = { coast = { mid = -5, high = -14 } } }, -- smoother, quieter
		ferrara_599 = { family = "V12_F140" },
		lambrini_lp640 = { family = "V12_MURCIELAGO" },
		lambrini_lp670 = { family = "V12_MURCIELAGO", volume = 1.15, tone = { drive = 0.1, high = 1.5 } }, -- the SV: rawer
		-- (owner, 2026-11-05: the LP700 quieter than the SV: about as loud as it was)
		lambrini_lp700 = { family = "V12_AVENTADOR", volume = 0.47 },
		lambrini_revuelto = { family = "V12_REVUELTO" },
		lambrini_countach = { family = "V12_COUNTACH", tone = { low = 3, drive = 0.06 } }, -- the carburettors' roar
		lambrini_lp570 = { family = "V10", with = GALLARDO, volume = 1.05, tone = { drive = 0.08, high = 1 } },
		lambrini_lp560 = { family = "V10", with = GALLARDO, tone = { drive = 0.05 } },
		lambrini_huracan = { family = "V10_REV" },
		lambrini_performante = { family = "V10_REV", volume = 1.2, tone = { drive = 0.08, high = 1 }, bands = { shots = { Pops = 1.5 } } },
		lambrini_sto = { family = "V10_REV", volume = 1.25, tone = { drive = 0.1, high = 1.5 }, bands = { shots = { Pops = 1.6 } } },
		lambrini_sterrato = { family = "V10_REV", volume = 0.95, tone = { low = 1 } },
		-- the Audis: a bit more muffled than the Lamborghinis (1st generation), the 2nd generation sharper
		audy_r8 = { family = "V10_REV", with = R8_START, volume = 0.9, tone = { high = -4 }, bands = { shiftCut = 0.15, shots = { Pops = 0.7 } } },
		audy_r8_lw = { family = "V10_REV", with = R8_START, volume = 0.95, tone = { high = -3 }, bands = { shiftCut = 0.12, shots = { Pops = 0.7 } } },
		audy_r8_4s = { family = "V10_REV", with = R8_START, tone = { high = 1.5 }, bands = { shots = { Pops = 0.8 } } },
		audy_r8_4s_rwd = { family = "V10_REV", with = R8_START, tone = { high = 1.5 }, bands = { shots = { Pops = 0.8 } } }, -- (not in the game yet)
		lexis_lfa = { family = "LFA" },
		lexis_lfa_circuit = { family = "LFA", volume = 1.1, tone = { high = 1 } },
		mclaran_12c = { family = "V8_TWINTURBO" },
		bentz_sls = { family = "V8_CROSSPLANE" },
		porsha_gt3 = { family = "FLAT6" },
		-- (2026-11-10) the imports that had no set
		bnw_m5_e60 = { family = "V10_S85" },
		bnw_m3_e92 = { family = "V8_S65" },
		bnw_m4_f82 = { family = "I6_TWINTURBO" },
		bnw_m5_f90 = { family = "V8_S63" },
		bentlee_bentayga = { family = "V8_VW40", volume = 0.8, tone = { high = -4 } }, -- quieter and softer than the tuned RS7
		nisun_gtr = { family = "V6_TWINTURBO" },
	}
	local PARTS = { "Start", "Idle", "Low", "Mid", "High", "Launch", "Crackle", "Redline", "Shift", "Downshift", "ShiftPop", "Pops", "LowOff", "MidOff", "HighOff", "Turbo", "Turbo2", "BlowOff", "EWhine" }
	local function merged(a: any, b: any): any
		local out = table.clone(a or {})
		for k, v in b or {} do
			out[k] = if type(v) == "table" and type(out[k]) == "table" then merged(out[k], v) else v
		end
		return out
	end
	for carId, car in CARS do
		if not Config.SupercarExhaust.Enabled or Config.SupercarExhaust.Off[carId] then
			continue
		end
		local fam = FAMILY[car.family]
		local with = car.with or {}
		local sounds = merged(fam.sounds, with.sounds)
		local bands = merged(merged(fam.bands, with.bands), car.bands)
		for _, part in PARTS do
			Config.Sounds["Exhaust_" .. carId .. "_" .. part] = sounds[part] -- (clears the old set's parts)
		end
		Config.ExhaustBands[carId] = bands
		Config.ExhaustStart[carId] = merged(fam.start, with.start)
		Config.ExhaustVolume[carId] = car.volume or 1
		Config.ExhaustTone[carId] = car.tone
		Config.SupercarExhaust.Cars[carId] = true
	end
	-- the downshift blips' engine speed (their pitch follows the gear they land in)
	Config.ExhaustShotRpm["rbxassetid://17552549922"] = 5150
end
supercarExhaust()

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
	MinChaseSeconds = 8, -- (2026-11-04: under LoseSeconds[1], or the server refused the escape and the chase froze)
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
	FinishLag = 0.6, -- seconds of driving allowed at a race or duel finish (the server sees a moving car a moment late)
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
	NoNitrous = { riv_mountain = true }, -- (2026-11-06) races run without nitrous: their card says so
	-- the Racing Hub (owner, 2026-11-06: "collect all of those racing areas and make a racing hub at the
	-- Old Rock place"): every race's ring is on the palace square; when its lobby starts you're taken to
	-- the race's start line
	Hub = {
		Name = "Racing Hub",
		Bays = {
			riv_coast = Vector3.new(12988, 52, 1252),
			riv_mountain = Vector3.new(13028, 52, 1252),
			riv_town = Vector3.new(13068, 52, 1252),
			riv_casino = Vector3.new(13008, 52, 1306),
			riv_highway = Vector3.new(13052, 52, 1306),
		},
		Spot = CFrame.lookAt(Vector3.new(13032, 52, 1326), Vector3.new(13032, 52, 1250)), -- fast travel
		GridSeconds = 8, -- from the lobby's end to GO: the trip to the start line and 3-2-1
		GridGap = 16, -- studs between rows on the start line
		GridSide = 6, -- studs either side of the line's middle
	},
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
	-- owner (2026-11-07): "remove the car market for now". false: no MARKET button, no K key, nothing
	-- runs on the server, and saved stashes are left alone. true brings it all back
	Enabled = false,
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
	HighFromPrice = 300000, -- high-end cars (the dealer sells them too since 2026-10-30; rare here)
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
		astin_dbx = 257000,
		bentlee_contgt = 345000,
		bentlee_bentayga = 227000,
		bentz_gls = 180000,
		lambrini_urusp = 285000,
		brabos_g63 = 390000,
		bentz_s680 = 245000,
		rolls_wraith = 175000,
		rolls_cullinan = 432000,
	},
	-- the order the phone lists them in
	Order = { "astin_dbx", "bentlee_contgt", "bentlee_bentayga", "bentz_gls", "lambrini_urusp", "brabos_g63", "bentz_s680", "rolls_wraith", "rolls_cullinan" },
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
				{ part = "Rare", weight = 1.5 }, -- (2026-11-06) a free part of this rarity, into My Parts
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
				{ part = "Epic", weight = 2 },
				{ cash = 1500000, weight = 1.5 },
				{ car = true, carTiers = { "Mid", "High" }, carMax = 600000, carCash = 500000, weight = 1 },
				{ cash = 5000000, weight = 0.5 },
				{ part = "Legendary", weight = 0.4 },
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
	CycleMinutes = 14, -- about 35 s a game hour (owner, 2026-11-05: quicker days; was 24)
	StartHour = 20, -- where the clock stands at server time 0 (only until the server's DayZero arrives)
	ServerStartHour = 17, -- a new server starts here (2026-11-06: the sunset look comes first)
	MenuHour = 17.3, -- the start menu's backdrop, on every join
	MenuBlend = 5, -- seconds from it to the server's clock when you start playing
}

-- the picture settings (owner, 2026-11-06, the Ghost Driver look: client/LookFx.lua; Settings > Graphics and
-- Weather). A graphics level sets Presets; a player's own changes are saved as Settings.Look
Config.Look = {
	Defaults = {
		Shadows = true, Reflections = "High", Ambient = "High", Glow = true, Rays = true, Dof = false,
		Brightness = 0, Contrast = 0, Saturation = 0,
		Weather = "Auto", Sky = "Auto", SunClouds = true, Haze = true, Fog = "Thick",
	},
	Presets = {
		Low = { Shadows = false, Reflections = "Low", Ambient = "Low", Glow = false, Rays = false, Fog = "Off" },
		-- (2026-11-06, FPS: shadows cost a fifth of the frame in Studio, so phones, on Medium, go without)
		Medium = { Shadows = false, Reflections = "High", Ambient = "High", Glow = true, Rays = false, Fog = "Light" },
		High = { Shadows = true, Reflections = "High", Ambient = "High", Glow = true, Rays = true, Fog = "Thick" },
		Ultra = { Shadows = true, Reflections = "High", Ambient = "High", Glow = true, Rays = true, Fog = "Thick" },
	},
	Choices = {
		Reflections = { "Low", "High" },
		Ambient = { "Low", "High" },
		Weather = { "Auto", "Clear", "Rain" },
		Sky = { "Auto", "Day", "Sunset", "Night" },
		Fog = { "Off", "Light", "Thick" },
	},
	Sliders = { Brightness = 0.5, Contrast = 0.2, Saturation = 0.3 }, -- how far each goes each way from the look
	AmbientLow = 0.45, -- EnvironmentDiffuseScale at Ambient Low
	ReflectionsLow = 0.35, -- EnvironmentSpecularScale at Reflections Low
	Dof = { Far = 0.12, Focus = 70, Radius = 220 }, -- a soft distance blur when a player turns it on
	Fog = {
		Image = "rbxassetid://123351176849967", -- tools/look_art.py
		Sheets = 16,
		Overlap = 1.5, -- each sheet is this many times its share of the ring
		Radius = 520, -- inside the streaming radius, so the far city fades into it
		Height = 90,
		Lift = 26, -- the band's middle over the ground
		Level = { Off = 0, Light = 0.4, Thick = 0.75 },
	},
	ShadowImage = "rbxassetid://96671888596471", -- tools/look_art.py
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
	Indoor = { "ferrara_599", "rolls_wraith", "porsha_gt3", "bentz_g63" },
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

-- the working lamps of the newest models (client/CarLamps.lua; owner, 2026-11-06). A SpotLight's range
-- stops at 60 studs, so high beam adds a light further up the road (ReachAhead)
Config.Lamps = {
	HoldFlash = 0.35, -- hold L this long: high beam while held
	DoubleTap = 0.3, -- two taps inside this: a short flash
	FlashTime = 0.4,
	AutoOn = 0.3, -- Auto: low beam from this much night (DayCycle.night), off again under AutoOff
	AutoOff = 0.15,
	DrlCore = 0.35, -- how see-through the strips are in each state
	DrlGlass = 0.72,
	LowGlass = 0.62,
	HighGlass = 0.5, -- (x the low beam number)
	Glass = { bugotti_chiron = 0.86, bugotti_chiron_pursport = 0.86, bugotti_chiron_supersport = 0.86 }, -- covers over four lamps
	NoseGap = 0.4, -- the beams start this far ahead of the nose
	LowRange = 60, LowAngle = 96, LowBrightness = 9, LowTilt = -9, LowOut = 2,
	HighRange = 60, HighAngle = 76, HighBrightness = 15, HighTilt = -3.5, HighOut = 1,
	ReachAhead = 48, ReachUp = 5, ReachRange = 60, ReachAngle = 74, ReachBrightness = 8, ReachTilt = -6,
	ShadowQuality = 1, -- WorldFx.qualityScale() from which your own low beam casts shadows
	NearCars = 6, -- other cars with real lights (half on Medium, none on Low, double on Ultra)
	NearDistance = 260,
	HazeTexture = "rbxassetid://123351176849967", -- the fog band's soft sheet
	HazeLength = 44,
	HazeWidth = 16,
	GlareImage = "rbxassetid://106509623755056", -- tools/lamps/glare.png
	GlareSize = 120,
	GlareDistance = 320,
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
	StreakCarMaxPrice = 50000, -- the day-7 car: a Mid car at or under this price
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

-- Performance parts (owner, 2026-11-06: "make the upgrading area way better"): the parts, slots and
-- engine swaps are in shared/PartData.lua, the numbers are worked out in CarStats. Here: the class rule
-- and the money.
Config.CarParts = {
	-- (owner, 2026-11-03: "S2 and R and X cars that are already in that range stock from the
	-- dealership, not tuneable except tyres, gearbox, suspension, exhaust, otherwise it would be too
	-- overpowered"; PartData.Slots `top`; sound parts are fine on them, looks at Legends Customs aren't
	-- limited)
	TopClasses = { S2 = true, R = true, X = true }, -- by the car's stock class
	-- a part's price: its real price * Economy.PartPriceMult. Big parts (BigFrom and up) cost a little more
	-- on dear cars: the factor (car price / CashRef) ^ 0.5, from 1 to CashMax
	BigFrom = 2000,
	CashRef = 500000,
	CashMax = 1.5,
	SellShare = 0.5, -- selling a spare part back: this share of what it was paid for
	-- rare drops: the chance of a free part (it comes fully paid: it fits any car with no fee) and
	-- how the rarity is picked (no engine swaps). Shown in the wheels' ODDS
	Drops = {
		Chance = { daily = 0.2, gold = 0.1, heist = 0.25 },
		Rarity = { Common = 46, Uncommon = 32, Rare = 16, Epic = 5, Legendary = 1 },
	},
}

-- a car's price factor for parts
function Config.partK(carPrice: number): number
	local P = Config.CarParts
	return math.clamp((math.max(carPrice, 1) / P.CashRef) ^ 0.5, 1, P.CashMax)
end

-- a part's price at a price factor (rounded to $10)
function Config.partCash(list: number, k: number, _swap: boolean?): number
	local factor = if list >= Config.CarParts.BigFrom then math.min(k, Config.CarParts.CashMax) else 1
	return math.floor(list * Config.Economy.PartPriceMult * factor / 10 + 0.5) * 10
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

---------------------------------------------------------------------
-- Harder cash: scales the old earn numbers above by the multipliers in Config.Economy (2026-11-07).
-- The old values are in the tables above, the new ones are in City Legends/City Legends.md
---------------------------------------------------------------------
do
	local E = Config.Economy
	local function cash(v: number, k: number): number
		return math.max(5, math.floor(v * k / 5 + 0.5) * 5)
	end
	local A = E.ActiveMult
	-- XP stays what it was: a cut-up's XP is worked out from its cash
	Config.Progression.CutXpPerCash /= A
	E.DrivePerSecond *= A
	E.CutBase = E.CutBase * A
	Config.Progression.LevelUpCashBase = cash(Config.Progression.LevelUpCashBase, E.LevelUpMult)
	Config.Progression.LevelUpCashPerLevel = cash(Config.Progression.LevelUpCashPerLevel, E.LevelUpMult)
	local Act = Config.Activities
	for k, v in Act.RaceRewards do
		Act.RaceRewards[k] = cash(v, A)
	end
	Act.ChipCash = cash(Act.ChipCash, A)
	Act.ChipAllBonus = cash(Act.ChipAllBonus, A)
	Act.PotPerRacer = cash(Act.PotPerRacer, A)
	Act.DuelPot = cash(Act.DuelPot, A)
	Act.DuelSecondCash = cash(Act.DuelSecondCash, A)
	Act.JobPayPerStud *= E.JobMult
	Act.JobTimeBonus = cash(Act.JobTimeBonus, E.JobMult)
	local Ch = Config.Challenges
	Ch.DriftCashPerPoint *= A
	Ch.DriftCashMax = cash(Ch.DriftCashMax, A)
	Ch.StuntCashPerSecond = cash(Ch.StuntCashPerSecond, A)
	Ch.StuntCashPerStud *= A
	Ch.StuntCashMax = cash(Ch.StuntCashMax, A)
	for _, m in Ch.TrapMedals do
		m.cash = cash(m.cash, A)
	end
	Config.Dealership.MeetBonusPerCar = cash(Config.Dealership.MeetBonusPerCar, A)
	for k, v in Config.Police.EscapeBounty do
		Config.Police.EscapeBounty[k] = cash(v, A)
	end
	Config.Police.CameraFine = cash(Config.Police.CameraFine, A)
	Config.Police.FinePerKmh = math.max(1, math.floor(Config.Police.FinePerKmh * A + 0.5))
	Config.Parking.VipFee = cash(Config.Parking.VipFee, A)
	for _, t in Config.Towers.List do
		t.rent = cash(t.rent, A)
	end
	for _, t in Config.Hotel.Suites do
		t.perMinute = cash(t.perMinute, A)
	end
	local B = Config.Bank
	B.GrabMin, B.GrabMax, B.MaxLoot = cash(B.GrabMin, E.HeistMult), cash(B.GrabMax, E.HeistMult), cash(B.MaxLoot, E.HeistMult)
	local S = Config.Luxe.Showcase
	S.CaseMin, S.CaseMax = cash(S.CaseMin, E.ShowcaseMult), cash(S.CaseMax, E.ShowcaseMult)
	S.ShowpieceLoot, S.MaxLoot = cash(S.ShowpieceLoot, E.ShowcaseMult), cash(S.MaxLoot, E.ShowcaseMult)
	local M = Config.Market
	M.FlipOffPrize = cash(M.FlipOffPrize, A)
	M.FlipOffPrizeCap = cash(M.FlipOffPrizeCap, A)
	local G = E.GiftMult
	local R = Config.Rewards
	for i, p in R.Playtime do
		p.cash = E.PlaytimeCash[i] or cash(p.cash, G)
	end
	for _, key in { "Weekly", "Return", "FriendDaily", "Invite", "Group" } do
		(R :: any)[key] = cash((R :: any)[key], G)
	end
	R.LevelCash = cash(R.LevelCash, E.LevelGiftMult)
	R.ChestCash = cash(R.ChestCash, E.LevelGiftMult)
	for name, wheel in R.Wheels do
		local k = if name == "super" then E.SuperWheelMult else E.WheelMult
		wheel.cashPrice = cash(wheel.cashPrice, k)
		for _, prize in wheel.prizes do
			if prize.cash then
				prize.cash = cash(prize.cash, k)
			end
			if prize.flexCash then
				prize.flexCash = cash(prize.flexCash, k)
			end
			if prize.carCash then
				prize.carCash = cash(prize.carCash, k)
			end
		end
	end
	local Go = Config.Goals
	for _, g in Go.Path do
		g.cash = cash(g.cash, if g.cash <= E.GoalSmallUpTo then E.GoalSmallMult else E.GoalBigMult)
	end
	for i, v in Go.Streak do
		Go.Streak[i] = cash(v, G)
	end
	Go.StreakCarCash = cash(Go.StreakCarCash, G)
	for _, t in Go.Tasks do
		t.cash = cash(t.cash, E.TaskMult)
	end
end

---------------------------------------------------------------------
-- Towing (owner, 2026-11-07: "Only SUVs or cars that have a trailer hitch can carry trailers")
---------------------------------------------------------------------
Config.Towing = {
	-- the real braked tow rating of each car with a hitch, in kg. A trim tows what its base car tows.
	-- Trailer + the car on it must be within this.
	Cars = {
		toyoka_lc200 = 3500, toyoka_lc300 = 3500, lexis_lx700 = 3600,
		bentz_g63 = 3500, brabos_g63 = 3500, bentz_gle53 = 3500, bentz_gls = 3500,
		bnw_x6 = 3200, bnw_x7 = 3400,
		bentlee_bentayga = 3500, lambrini_urusp = 3500,
		byt_u8 = 3500, astin_dbx = 2700, maseroti_levante = 2700,
	} :: { [string]: number },
	-- a 7 x 20 ft 7,000 lb steel car hauler: new ones are about $3,900 to $5,600 (aluminium about $9,500)
	Trailer = {
		Id = "hauler",
		Name = "Legends Car Hauler",
		Price = 5500,
		Kg = 950, -- empty
		-- its shape, in studs: the owner's model (ReplicatedStorage.TrailerModels.hauler, "Flatbed Baked") with
		-- a drawbar and ramps added. The origin is on the ground between the axles, -Z to the coupler
		DeckHeight = 3.48,
		Width = 7.2,
		DeckFront = -14.8,
		DeckBack = 3.5,
		LoadZ = -5.6, -- the middle of the car on it
		AxleToHitch = 19.4,
		CouplerHeight = 1.35,
		WheelRadius = 1.25,
		WheelWidth = 1,
		RampLength = 12,
	},
	TopMph = 80, -- about 130 km/h
	AccelPow = 0.8, -- acceleration x (car / (car + trailer + load)) ^ this
	BrakePow = 0.5, -- the same for the brakes: the trailer's own brakes help, so less
	SteerK = 0.82, -- turns wider
	Jackknife = 72, -- degrees: it never folds further than this
	ClimbRate = 34, -- studs a second, the fastest the trailer rises or drops with the road
	MaxRoll = 0.14, -- radians of lean over a bump
	SwayFromMph = 50,
	SwayStuds = 0.28, -- at the axle, at most
	SwayRate = 2.6, -- radians a second
	HitchRange = 5, -- studs from the hitch to the coupler
	UnloadRange = 38, -- studs from the trailer's axle
	ActionMph = 6, -- HITCH, UNHITCH and STRAP only below this
	Key = Enum.KeyCode.I, -- (the last free letter: J is the leaderboard, K the market)
	HitchReach = { -- a car's hitch further out (+) or in (-), in studs
		bentlee_bentayga = -0.57, -- (2026-11-10) the 2018 model's own tow bar: its ball 3.63 studs behind the rear axle, 1.35 up
	} :: { [string]: number },
	Camera = { Back = 19, Up = 5, Turn = 3 }, -- pulled back to see the trailer; reversing it turns round
}

---------------------------------------------------------------------
-- Cruise control, mileage, wear, value, service, fuel
-- (owner, 2026-11-07: "the more mileage you have for the car, the cheaper the car value drops ...
-- a repair shop ... when the car's redlining for a long time or driving too long without maintenance")
-- Keep it fun: wear is slow, warnings are clear, repairs are cheap against an hour's pay (about $11,000), a
-- car never strands anyone. shared/CarCare.lua does the sums, server/Care.lua keeps the books.
---------------------------------------------------------------------
Config.Cruise = {
	Key = Enum.KeyCode.K, -- (free while the market is off: J is the leaderboard)
	MinMph = 15,
	Step = 5, -- a tap on the throttle or brake changes the set speed by this (mph or km/h)
	HoldBrake = 0.28, -- seconds: the brake held longer than a tap switches it off
	GapSeconds = 0.9, -- traffic right ahead closer than this many seconds: it switches off
	GapMin = 20, -- studs
}

Config.Wear = {
	-- the map is small: each mile on the road shows as this many on the odometer, about 240 in an hour's drive
	OdoScale = 4,
	ServiceEvery = 600, -- miles between oil services (about 2.5 hours' driving)
	ServiceWarn = 50, -- "Service due in 50 mi"
	ServiceBack = 4, -- an oil service gives the engine this much back, so on-time cars stay healthy
	ProtectSeconds = 3600, -- new players: no wear for the first hour of driving
	XpToMiles = 0.045, -- old saves: a car's miles from its car XP (1.5 XP a second at about 60 mph, x OdoScale)
	OldSaveDueIn = 400, -- old saves: the first service is due this many miles on
	-- percent lost
	Engine = { PerMile = 0.002, Overdue = 4, RedlineAfter = 3, RedlinePerSecond = 0.1, Launch = 0.03, Crash = 0.5 },
	Tyres = { PerMile = 0.03, DriftPerSecond = 0.2, BurnPerSecond = 0.5 },
	Brakes = { PerMile = 0.015, HardPerSecond = 0.04 },
	Tow = 1.25, -- a trailer on: wear and fuel times this (fuel: Config.Fuel.Tow)
	-- what it does to the car
	EngineWarn = 60, -- check engine, steady
	EngineFlash = 30, -- check engine, flashing: misfires
	EngineLimp = 10, -- limp mode
	PowerAtWarn = 0.08, -- power lost by EngineFlash, from EngineWarn down
	PowerAtFlash = 0.15, -- power lost by 0, from EngineFlash down
	LimpMph = 45,
	GripLoss = 0.1, -- at 0% tyres
	BrakeLoss = 0.1, -- at 0% brakes
	BodyLoss = 0.03, -- at 0% body (only under 40%)
}

Config.Value = {
	-- a car's value by miles it has done with you: { miles, share of its price }
	Mileage = { { 0, 1 }, { 1000, 0.9 }, { 5000, 0.75 }, { 20000, 0.6 }, { 80000, 0.45 } },
	Floor = 0.45,
	CollectorFloor = 0.8,
	ConditionMax = 0.1, -- up to this much off for low health or an overdue service
	HistoryBonus = 0.03, -- every service on time
	SellShare = 0.6, -- what Legends Motors pays of a car's value
}

Config.Service = {
	Name = "LEGENDS SERVICE",
	Bay = Vector3.new(15244.7, 3.7, 1082.7), -- the middle of the workshop's middle bay (tools/riviera/CareVenues.luau)
	Arrive = CFrame.lookAt(Vector3.new(15240, 4.7, 1036), Vector3.new(15244.7, 4.7, 1082.7)), -- fast travel: on the forecourt, facing the bay
	BayRadius = 22,
	LiftSeconds = 4,
	-- real-world prices; times Economy.PartPriceMult, times PriceK of the car (1 to MaxCarK)
	Oil = { 100, 220 },
	Tyres = { 400, 2500 },
	Brakes = { 400, 1500 },
	Engine = 1000, -- a full rebuild from 0%
	Body = 1500, -- a full body repair from 0%
	CarKFrom = 50000, -- a car under this price pays the low end
	CarKTo = 1500000, -- at this price and up, the high end
	MaxCarK = 1.5,
	FullDiscount = 0.1,
	Wash = 40,
}

-- Scissor doors cut from the cars' own models (owner, 2026-11-08, `Prompts/Scissor doors on the SVJ and SVJ 63 (cut
-- properly).md`). To go back: set a car's switch to false and the game uses its old model with no doors, exactly as
-- before (the one with doors is ReplicatedStorage.CarModels.<car id>@doors; the old one was never changed).
-- The Aventador LP700 and the SV (lambrini_lp750) open the same way (owner, same day: "because I like it").
Config.Doors = {
	lambrini_svj = true,
	lambrini_svj63 = true,
	lambrini_lp700 = true,
	lambrini_lp750 = true,
} :: { [string]: boolean }
Config.DoorFeel = {
	Seconds = 0.7, -- to open or close
	MaxSpeed = 2, -- studs/s: they open only when (nearly) stopped
	CloseSpeed = 4, -- studs/s: they close as soon as the car drives off
	Reach = 16, -- studs: on foot, how near your car you can open them
	-- ProSoundEffects (Roblox's official SFX partner, public domain): "Audi Car Door Movement Opening Closing 1 / 5"
	OpenSound = "rbxassetid://9113204879",
	CloseSound = "rbxassetid://9113205539",
	Volume = 0.45,
}

Config.Fuel = {
	Minutes = { 45, 30 }, -- a full tank: small engines, big engines (normal driving)
	PowerFrom = 200, -- horsepower at Minutes[1]
	PowerTo = 1100,
	Idle = 0.15, -- burn at a standstill, of normal
	Tow = 1.35,
	Low = 0.15,
	PauseAt = 0.01, -- races, jobs and heists never run dry
	PricePerLitre = 2.6, -- a real Monaco price (about $2.2) times a small multiplier: a tank is 1-3% of an hour's pay
	PricePerKwh = 0.7,
	FillSeconds = 3,
	ChargeSeconds = 6,
	CanShare = 0.12, -- roadside help: the can gives this much of a tank
	CanPrice = 90,
	TowPrice = 250,
	PumpRange = 16,
	-- built by tools/riviera/CareVenues.luau on the plot nearest each real station (see City Legends.md for kept and skipped;
	-- 2026-11-08: Town and West moved, their plates stood on Ravine Street and Coast Road)
	Stations = {
		{ id = "fuel_highway", name = "Riviera Fuel Highway", pumps = { Vector3.new(10296.6, 100.0, 12.0), Vector3.new(10284.6, 100.0, 4.8), Vector3.new(10305.3, 100.0, -2.5), Vector3.new(10293.3, 100.0, -9.7) }, chargers = { Vector3.new(10262.2, 100.0, -7.4), Vector3.new(10266.8, 100.0, -15.2), Vector3.new(10271.5, 100.0, -22.9) }, arrive = CFrame.new(10300.9, 102.6, 4.8, 0.5150, 0.0000, 0.8572, 0.0000, 1.0000, 0.0000, -0.8572, 0.0000, 0.5150) },
		{ id = "fuel_west", name = "Riviera Fuel West", pumps = { Vector3.new(12111.8, 6.4, 1502.7), Vector3.new(12125.8, 6.4, 1502.7), Vector3.new(12111.8, 6.4, 1519.7), Vector3.new(12125.8, 6.4, 1519.7) }, chargers = { Vector3.new(12151.3, 6.4, 1501.8), Vector3.new(12151.3, 6.4, 1510.8), Vector3.new(12151.3, 6.4, 1519.8) }, arrive = CFrame.new(12111.8, 9.0, 1511.2, -0.0036, 0.0000, -1.0000, 0.0000, 1.0000, 0.0000, 1.0000, 0.0000, -0.0036) },
		{ id = "fuel_town", name = "Riviera Fuel Town", pumps = { Vector3.new(12980.7, 117.9, -206.0), Vector3.new(12990.4, 117.9, -196.0), Vector3.new(12968.4, 117.9, -194.2), Vector3.new(12978.2, 117.9, -184.1) }, chargers = { Vector3.new(13008.8, 117.9, -178.3), Vector3.new(13002.4, 117.9, -172.1), Vector3.new(12995.9, 117.9, -165.8) }, arrive = CFrame.new(12974.6, 120.5, -200.1, -0.7193, 0.0000, -0.6947, 0.0000, 1.0000, 0.0000, 0.6947, 0.0000, -0.7193) },
		{ id = "fuel_east", name = "Riviera Fuel East", pumps = { Vector3.new(16760.2, 19.9, 774.1), Vector3.new(16774.1, 19.9, 774.6), Vector3.new(16759.4, 19.9, 791.0), Vector3.new(16773.4, 19.9, 791.6) }, chargers = { Vector3.new(16799.7, 19.9, 774.7), Vector3.new(16799.3, 19.9, 783.7), Vector3.new(16798.9, 19.9, 792.7) }, arrive = CFrame.new(16759.8, 22.5, 782.5, -0.0424, 0.0000, -0.9991, 0.0000, 1.0000, 0.0000, 0.9991, 0.0000, -0.0424) },
		{ id = "fuel_mountain", name = "Riviera Fuel Mountain", pumps = { Vector3.new(16195.3, 167.2, -671.1), Vector3.new(16209.2, 167.2, -669.3), Vector3.new(16193.2, 167.2, -654.2), Vector3.new(16207.1, 167.2, -652.5) }, chargers = { Vector3.new(16234.6, 167.2, -667.2), Vector3.new(16233.5, 167.2, -658.3), Vector3.new(16232.4, 167.2, -649.4) }, arrive = CFrame.new(16194.2, 169.8, -662.6, -0.1222, 0.0000, -0.9925, 0.0000, 1.0000, 0.0000, 0.9925, 0.0000, -0.1222) },
		{ id = "fuel_corniche", name = "Riviera Fuel Corniche", pumps = { Vector3.new(14337.4, 448.6, -1681.8), Vector3.new(14351.3, 448.6, -1680.2), Vector3.new(14335.5, 448.6, -1664.9), Vector3.new(14349.4, 448.6, -1663.3) }, chargers = { Vector3.new(14376.8, 448.6, -1678.3), Vector3.new(14375.7, 448.6, -1669.3), Vector3.new(14374.7, 448.6, -1660.4) }, arrive = CFrame.new(14336.4, 451.2, -1673.3, -0.1130, 0.0000, -0.9936, 0.0000, 1.0000, 0.0000, 0.9936, 0.0000, -0.1130) },
	} :: { { id: string, name: string, pumps: { Vector3 }, chargers: { Vector3 }, arrive: CFrame } },
}

return Config
