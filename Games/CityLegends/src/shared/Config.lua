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
		Lag = 2.2, -- thrown back on hard launches, forward under braking (studs per g)
		Swing = 0.22, -- looks into turns (radians at full lock)
		Buzz = 0.09, -- road shake at top speed
		LookAhead = 22,
		LookHeight = 1.6,
		Blur = 4,
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
	Patrols = 4, -- patrol cars around you when you're not wanted
	UnitsPerStar = 1, -- chasing units: 1 + stars (max 6)
	MaxUnits = 6,
	PatrolMph = 38,
	ChaseMph = { 105, 125, 150, 175, 200 }, -- top chase speed per star
	SpotRange = 90, -- a patrol sees you speeding this close
	BustRange = 20,
	BustSeconds = 3, -- stopped next to a police car this long
	LoseRange = 300, -- out of sight and this far from every unit...
	LoseSeconds = { 9, 11, 13, 15, 18 }, -- ...for this long per star: escaped
	MinChaseSeconds = 12,
	EscapeBounty = { 1500, 3500, 7000, 12000, 20000 },
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
Config.Theme = {
	Background = Color3.fromRGB(10, 11, 15),
	Panel = Color3.fromRGB(18, 20, 27),
	PanelLight = Color3.fromRGB(27, 30, 40),
	Stroke = Color3.fromRGB(45, 50, 66),
	Text = Color3.fromRGB(236, 238, 245),
	SubText = Color3.fromRGB(140, 146, 165),
	Accent = Color3.fromRGB(0, 229, 255),
	Accent2 = Color3.fromRGB(255, 46, 136),
	Money = Color3.fromRGB(61, 255, 143),
	Warning = Color3.fromRGB(255, 184, 0),
	Danger = Color3.fromRGB(255, 64, 64),
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
	CityMph = 44, -- how fast the driver goes in town
	HighwayMph = 92, -- on the highway and the loop
	TurnMph = 15, -- round corners (highway ramps use their own speed)
	Accel = 16, -- studs/s per second
	Brake = 24,
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

return Config
