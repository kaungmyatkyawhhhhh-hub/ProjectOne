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
	LaneWidth = 12,
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
	BustedFineFrac = 0.06,
	BustedFineMin = 500,
	BustedFineMax = 150000,
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

return Config
