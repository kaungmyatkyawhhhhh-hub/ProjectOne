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
		{ id = "toyoka_ae86", feel = "Light rear-drive drifter" }, -- (19 Nov) gifts are Local only
	},
	FastTravelCooldown = 30, -- seconds between trips
	-- the store (Playbook money rules): names and exact effects here, prices read from Roblox.
	-- (owner, 18 Nov: the ids made in Creator Hub; no cash for Robux, so the two cash packs are gone)
	Store = {
		{ key = "cash2x", name = "2x Cash", kind = "Pass", id = 2094087139, art = "store_cash2x", effect = "Double the cash from driving, cut-ups and jobs, for good" },
		{ key = "vip", name = "VIP", kind = "Pass", id = 2094033148, art = "store_vip", effect = "A VIP tag, free VIP bays in every tower garage and +10% cash from cut-ups" },
		{ key = "doublepay", name = "Double Pay", kind = "Pass", id = 2094591074, art = "store_cash2x", effect = "Double the pay from every job, for good" },
		{ key = "starter", name = "Starter Pack", kind = "Product", id = 3733093451, art = "store_starter", effect = "$50,000 and a starter car of your choice, once per player" },
		{ key = "garage", name = "Garage Space", kind = "Product", id = 3733093637, art = "store_garage", effect = "One more garage space at the house you live in" },
	},
}

-- the game passes (Store.lua caches ownership as player attributes of the same name: Cash2x, Vip,
-- DoublePay). Paid power never reaches races or duels: their prizes are not multiplied
Config.Passes = {
	Cash2x = 2094087139,
	Vip = 2094033148,
	DoublePay = 2094591074,
}
-- developer products (Store.lua's ProcessReceipt is the only handler)
Config.Products = {
	StarterPack = 3733093451,
	GarageSpace = 3733093637,
	Spin = 3733093797,
}
Config.StarterPackCash = 50000
Config.VipCutBonus = 1.1 -- VIP: +10% cut-up cash
Config.PremiumBonus = 1.1 -- Roblox Premium: +10% cash (driving, cut-ups, jobs)

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
-- Yangon (owner, 2026-11-13: "Rush Yangon", the car meet): the map players play on when Workspace.Yangon
-- is in the place. Since build step 11 (2026-11-14) Monaco is out of the place: saved by the owner to
-- D:/RobloxStudioGameFiles/Riviera.rbxm and RivieraFar.rbxm (Insert from File brings it back).
-- With neither map the old city comes back.
function Config.activeMap(): string?
	if workspace == nil then
		return nil
	end
	-- (2026-11-17) the old 1.6 Yangon (Workspace.Yangon) was deleted; the 1:1 map (Workspace.Yangon1to1) is "Yangon" too
	if workspace:FindFirstChild("Yangon") or workspace:FindFirstChild("Yangon1to1") then
		return "Yangon"
	end
	if workspace:FindFirstChild("Riviera") then
		return "Riviera"
	end
	return nil
end
-- the Yangon map's root folder in the Workspace (the 1:1 Yangon1to1 since 2026-11-17, the old Yangon while it is there)
function Config.mapRoot(): Instance?
	if workspace == nil then
		return nil
	end
	return workspace:FindFirstChild("Yangon") or workspace:FindFirstChild("Yangon1to1")
end
function Config.monacoOnly(): boolean
	return not Config.World.OldCity and Config.activeMap() ~= nil
end
-- (2026-11-16, the 1:1 rescale, owner: "Everything at player scale") which map a point belongs to, by area instead
-- of the old "x > 25000" tests, so the new 3-studs-a-metre Yangon can be built beside the old one. YangonAreas: boxes
-- { minX, maxX, minZ, maxZ }; the lane width per map (Yangon 16 now, 12 at the new scale). (A function: Config's main
-- chunk is at its constant limit.)
Config.Areas = (function()
	return {
		-- (2026-11-16) the 1:1 Yangon frame (tools/yangon/city/geo.py at YANGON_SCALE=1to1: the whole OSM box lands at
		-- x 15,600-60,400, z 6,800-53,200); its lanes are 12 wide. The old map's batches 1-3 (1.6 studs a metre) reach
		-- z ~12,400, so the 1:1 area starts at z 14,000 (the pilots P1 / P2 lie at z 23,000-32,000; the 1:1 frame's
		-- northern edge, lat 16.865-16.89, overlaps the old batches and must wait until they are retired)
		YangonAreas = { { 25000, math.huge, -math.huge, math.huge }, { 15000, 61000, 14000, 54000 } },
		Yangon1to1Areas = { { 15000, 61000, 14000, 54000 } },
		LaneWidthYangon = 16,
		LaneWidthYangon1to1 = 12,
	}
end)()
local function inBoxes(boxes, pos: Vector3): boolean
	for _, b in boxes do
		if pos.X >= b[1] and pos.X <= b[2] and pos.Z >= b[3] and pos.Z <= b[4] then
			return true
		end
	end
	return false
end
function Config.isYangonAt(pos: Vector3): boolean
	return inBoxes(Config.Areas.YangonAreas, pos)
end
-- (2026-11-16) the 1:1 Yangon frame (Workspace.Yangon1to1, pilot districts P1...)
function Config.isYangon1to1At(pos: Vector3): boolean
	return inBoxes(Config.Areas.Yangon1to1Areas, pos)
end
function Config.mapAt(pos: Vector3): string
	-- (the name of the map's root folder in the Workspace: the 1:1 frame's is Yangon1to1)
	return if Config.isYangon1to1At(pos) then "Yangon1to1" elseif Config.isYangonAt(pos) then "Yangon" else "Riviera"
end
-- the lane width of the map in use, or (with a point) of the area that point is in: 12 in the 1:1 frame
function Config.laneWidth(pos: Vector3?): number
	if (pos and Config.isYangon1to1At(pos)) or (not pos and workspace and not workspace:FindFirstChild("Yangon") and workspace:FindFirstChild("Yangon1to1")) then
		return Config.Areas.LaneWidthYangon1to1
	end
	return if Config.activeMap() == "Yangon" then Config.Areas.LaneWidthYangon else Config.City.LaneWidth
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

-- the venues in Yangon (build step 9, 2026-11-13): same format as RivieraVenues; a venue named here
-- is in Yangon, the rest stay where RivieraVenues puts them. Lots from tools/yangon/d11_sites.py.
-- the venues in Yangon (build step 9, 2026-11-13): same format as RivieraVenues; a venue named here
-- is in Yangon, the rest stay where RivieraVenues puts them.
-- (2026-11-17, the switch to the 1:1 map) lots from tools/yangon/city/venues_1to1.py on the roads05 main roads of P1 / P2,
-- checked in Studio (no water, road or landmark; few or no shells), made ready by tools/yangon/YangonSites.luau
-- (S.root = workspace.Yangon1to1). The venue row is on Kabar Aye Pagoda Road's east side north of Myanmar Plaza;
-- the bank, its drop-off (by Myanmar Plaza) and the gem showcase stay on one map.
Config.YangonVenues = {
	On = true,
	Sites = {
		-- (owner, 2026-11-21: "move every venues to their actual place") the real places, from Google Maps: the lot (216
		-- square) is the nearest free one beside the real pin, its front on a road. Old spots in the vault note.
		dealership = { x = 31689.0, z = 31574.0, fx = -1, fz = 0, y = 73.5, size = 110, w = 80 }, -- RIDER AUTO Premium Exclusive (16.81529, 96.14526): compact, beside Optima, both face the road
		customs = { x = 31699.0, z = 31455.0, fx = -1, fz = 0, y = 75.5, size = 130, w = 88 }, -- Optima Werkz (16.81564, 96.14513): compact, 4 bays
		bank = { x = 38525.0, z = 45372.0, fx = 1, fz = 0, y = 21.29 }, -- CB Bank head office (16.77423, 96.16742)
		dropoff = { x = 35660.1, z = 27508.2, fx = -0.758, fz = -0.652, y = 36.84 }, -- by Myanmar Plaza (24 Nov: moved off a road that ran through it; was 35416.6, 27780.7)
		gems = { x = 35023.0, z = 18623.0, fx = 0.866, fz = -0.5, y = 63.70 }, -- Gems Museum (16.85471, 96.15632)
		rewards = { x = 35461.7, z = 22353.3, fx = -0.991, fz = -0.135, y = 39.02, w = 304 }, -- its car courts make it 304 wide (24 Nov: moved off a road; was 35389.0, 22838.7)
		-- square to the world axes (their towers and facade tiers are)
		hotel = { x = 27333.3, z = 30048.6, fx = -0.264, fz = -0.965, y = 54.53, size = 200 }, -- the real Novotel Yangon Max site (OSM o471327865), square to its south road; 200 lot (26 Nov)
		tower_aurum = { x = 29226.0, z = 21923.0, fx = -1, fz = 0, y = 67.78 }, -- Lotte Hotel (16.84432, 96.13728)
		tower_skyline = { x = 36686.0, z = 24776.8, fx = 0, fz = 1, y = 34.0 },
		tower_crown = { x = 39387.0, z = 39273.0, fx = 0, fz = -1, y = 35.86 }, -- Kan Thar Yar Centre (16.79233, 96.16963)
		realty = { x = 35426.2, z = 22115.1, fx = -0.991, fz = -0.136, y = 40.35, size = 80 },
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
	-- Yangon (build step 9): a first car on the Yangon Loop by Optima Werkz, on foot on its forecourt
	-- (1:1, 2026-11-17: on Kabar Aye Pagoda Road by Myanmar Plaza)
	YangonRoads = { ["Kabar Aye Pagoda Road"] = true },
	YangonNear = Vector3.new(34640, 0, 27300),
	YangonRadius = 500,
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
	CarCount = 46, -- (2026-11-03: 38 -> 28, owner "reduce a little bit of traffic like 10 cars"; 90 -> 38 with the traffic now on the yellow routes only: about the same number of cars on them as before) -- in the city's streets, Monaco's too (owner, 2026-10-29: fewer; was 55 in all; 2026-11-02: 32 -> 40, "add more cars traffic"; 2026-11-03: 40 -> 64, "add more traffic cars throughout the map"; 64 -> 90 the same day, "add more traffic cars too"; phones get ~60%)
	HighwayCars = 30, -- on the highways and the loop, well spaced to split lanes and speed past
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
	-- (owner, 27 Nov 2026: "the cars rn are unnatural") real pull-away and braking at 3 studs a metre, eased in and out
	-- (jerk), so no car changes speed in one frame; braking for lights, turns and cars ahead is planned at PlanBrake
	Accel = 8, -- studs/s^2 (about 2.7 m/s^2: 0-30 mph in ~5 s; was 28)
	Brake = 14, -- normal braking (about 0.5 g; was 70)
	EmergencyBrake = 27, -- hard stop (about 0.95 g; was 140)
	PlanBrake = 9, -- what stops and gaps are planned with (about 0.3 g)
	Jerk = 30, -- studs/s^3 the pull or braking builds up at (emergency: x4)
	StopGap = 15, -- studs between bumpers in a stopped queue (21 Nov, owner: a 1-car gap to cut through; was 4)
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
	FollowGap = 18, -- ...and at least a car length once moving (owner, 2026-10-29; 21 Nov: 16 -> 18)...
	Headway = 1.5, -- ...plus this many seconds of travel (27 Nov: 0.5 -> 1.5, a real following gap)
	LookAhead = 70,
	RecycleDistance = 700,
	RespawnMin = 220,
	RespawnMax = 520,
	StuckTime = 6,
	-- (27 Nov) the look of real car motion: body roll / pitch on the chassis (DrivingFeel's springs x these)
	BodyRollK = 1.4,
	BodyPitchK = 1.4,
	-- Weighted pick of classes used for NPCs
	ClassWeights = { Sedan = 40, SUV = 25, Coupe = 18, Supercar = 6, Hypercar = 2 },
	-- the imported low-poly traffic cars (ReplicatedStorage.TrafficModels, TrafficBodies): length in
	-- studs by type letter (real lengths at 3 studs a metre): A hatch, B people carrier, C small
	-- van, D minibus, E saloon, F pickup
	ModelLengths = { A = 12, B = 12.6, C = 13.2, D = 14.7, E = 13.8, F = 15.9 },
}

-- shown at the bottom of Settings (assets that ask for credit)
local okCredits, credits = pcall(function() return require(script.Parent:WaitForChild("Credits")) end)
Config.Credits = if okCredits and type(credits) == "table" then credits else {} -- (in Credits.lua: this file is at Studio's size limit; tests with no Credits get none)

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
	ShowcaseMult = 0.05, -- the Gems Museum
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

-- Config.ConfigFeel fills its part here (its own module: this file is at the size limit; offline tests without `script` call it themselves)
if script then
	require(script.Parent:WaitForChild("ConfigFeel"))(Config)
end

-- Config.ConfigSounds fills its part here (its own module: this file is at the size limit; offline tests without `script` call it themselves)
if script then
	require(script.Parent:WaitForChild("ConfigSounds"))(Config)
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
	MinChaseSeconds = 8, -- (2026-11-04: under LoseSeconds[1], or the server refused the escape and the chase froze)
	EscapeBounty = { 400, 800, 1500, 2500, 4000 }, -- a little money for getting away
	EscapeXp = 60,
	BustedFineFrac = 0.1, -- owner (2026-10-22): caught = 10% of the cash you have, no cap
	BustedFineMin = 0,
	BustedFineMax = math.huge,
	RamCooldown = 6,
	EscalateSeconds = 75, -- a chase this long adds a star...
	EscalateMax = 3, -- ...up to here
	CarId = "toyoka_chaser", -- the police car's body
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
	JobPayPerStud = 4, -- (19 Nov: 7 -> 4)
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
		{ id = "aurum", name = "LOTTE HOTEL YANGON", block = { 2, 3 }, height = 300, price = 750000, rent = 12000, accent = Color3.fromRGB(255, 196, 92) },
		{ id = "skyline", name = "SKYLINE ONE", block = { 4, 1 }, height = 380, price = 3000000, rent = 45000, accent = Color3.fromRGB(0, 229, 255) },
		{ id = "crown", name = "KAN THAR YAR CENTRE", block = { 1, 4 }, height = 460, price = 12000000, rent = 160000, accent = Color3.fromRGB(190, 110, 255) },
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

-- Yangon street life (client, 2026-11-14, owner: "the ingame yangon is too clean"): parked cars on the kerbs and
-- people on the pavements, from src/shared/YangonStreetLife*.lua (tools/yangon/city/streetlife.py), built by
-- client/YangonStreetLife round the camera. Counts are for High; Low graphics (qualityScale <= LowScale) halves them.
-- (a function: Config's main chunk is at its constant limit)
Config.YangonStreetLife = (function()
	return {
		Enabled = true,
		CarRadius = 260, -- parked cars are filled within this of the camera...
		CarKeep = 285, -- ...and kept until this far
		CarMax = 60,
		CarCheck = 0.5, -- seconds between fills
		CarBuildsPerTick = 6, -- new bodies made per fill at most
		Repaint = true, -- white / silver / grey / dark paints on the bodies (false: the models' own colours)
		PedRadius = 200,
		PedKeep = 230,
		PedMinGap = 55, -- never pop in nearer than this
		PedMax = 20, -- (27 Nov: 40 -> 20, owner "the npc characters are too much")
		PedCheck = 0.5,
		WalkSpeed = { 3, 5 }, -- studs a second
		SpotShare = 0.3, -- of the people, this share stand at bus stops, tea shops and shop fronts
		LowScale = 0.65,
	}
end)()

---------------------------------------------------------------------
-- The Novotel Yangon Max Downtown (owner, 2026-10-22: "a large skyscraper hotel with valets",
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
	Name = "NOVOTEL YANGON MAX",
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
	Order = { "astin_dbx", "bentlee_contgt", "bentlee_bentayga", "bentz_gls", "lambrini_urusp", "bentz_s680" },
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
-- The Myanmar Gems Museum, Downtown (owner, 2026-10-22: "places to spend big money on rare,
-- visible flex items like custom gems and accessories"). In-game cash only, never Robux. (The
-- High-Rollers Casino was replaced by Legends Rewards on 2026-11-03; its VIP desk moved here and
-- its vault heist was removed.)
---------------------------------------------------------------------
Config.Luxe = {
	-- VIP membership at the Gems Museum's VIP desk: a title over your head and money off the
	-- collection. A higher card replaces the lower one (you pay the difference)
	Vip = {
		{ id = 1, name = "GOLD CARD", title = "GOLD HIGH ROLLER", price = 250000, discount = 0.05, color = Color3.fromRGB(255, 200, 70) },
		{ id = 2, name = "PLATINUM CARD", title = "PLATINUM HIGH ROLLER", price = 2500000, discount = 0.1, color = Color3.fromRGB(215, 230, 245) },
		{ id = 3, name = "BLACK CARD", title = "BLACK CARD LEGEND", price = 25000000, discount = 0.15, color = Color3.fromRGB(190, 120, 255) },
	},
	-- wearables at the Gems Museum: one per slot, everyone sees them on you (on foot)
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
	-- the Gems Museum's smash-and-grab: smash a case (the alarm), grab its gems; the showpiece
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
	-- kinds: cash, spin (one more spin of the same kind), flex (a Gems Museum piece you don't own,
	-- at or under flexMax, or flexCash), car (a car you don't own, of carTiers at or under carMax,
	-- or carCash)
	Wheels = {
		wheel = {
			name = "SPIN",
			reels = 1,
			freeEvery = 24 * 60 * 60,
			cashPrice = 50000,
			productId = 3733093797, -- the Robux developer product for 1 spin (Config.Products.Spin; 0: hidden)
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
	ZoomNear = 0.24, -- px per stud when slow (20 Nov, owner: zoom out a bit; was 0.32)
	ZoomFar = 0.09, -- ...and at FarMph and above (2026-11-19: 0.12 -> 0.09, owner: zoom out further)
	FarMph = 150,
}

---------------------------------------------------------------------
-- Rider Auto, the car dealership (owner, 2026-10-23: "add a dealership, a real location";
-- the HUD's SHOP became CARS, your own cars only). New cars are bought here only.
---------------------------------------------------------------------
Config.Dealership = {
	Name = "RIDER AUTO",
	Block = { 4, 2 }, -- the city block it stands on (east of the city centre)
	Face = "W", -- the side its showroom looks out of (towards the city centre)
	BuyRange = 260, -- a player must be this close to the showroom to buy
	-- cars on the showroom turntables (one per brand zone)
	Display = { "bnw_m5_e60", "bentz_s680", "toyoka_supra_mk4", "nisun_gtr", "bentlee_bentayga", "nisun_350z", "toyoka_chaser", "lambrini_urusp" },
	-- the ready-made building (ServerStorage.DealerBody, 2026-10-31): the car on the turntable and
	-- the four indoor spots. The front car park stays empty for players to park in (owner,
	-- 2026-10-31: "dont put cars infront the dealership"); Lot = { ids } would fill its bays.
	Stage = "lambrini_lp750",
	Indoor = { "ferrara_599", "bentlee_contgt", "porsha_gt3", "bentz_gls" },
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
-- Optima Werkz (owner, 2026-10-23: "make the game ... cooler"): a drive-in tuning garage.
-- Drive into its bay and press Y (or tap the pill) to restyle the car you're in: paint, finish,
-- second colour, window tint, underglow, rims, number plate, headlights. Saved per car.
---------------------------------------------------------------------
Config.Customs = {
	Name = "OPTIMA WERKZ",
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
		{ id = "custom1", text = "Restyle a car at Optima Werkz", stat = "customs", need = 1, cash = 4000, xp = 100 },
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
	-- the daily streak: day 1..6 cash, day 7 a free Local car you don't own (or StreakCarCash)
	Streak = { 5000, 8000, 12000, 18000, 25000, 35000 },
	StreakCarMaxPrice = 150000, -- the day-7 car: a Local car at or under this price
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
		{ id = "paychecks", text = "Earn %d job paychecks", stat = "paychecks", need = 5, cash = 6000, xp = 150 }, -- (2026-11-18, the Job Center)
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
	-- Optima Werkz looks can be paid with the car's CP too (owner: "both"): CP per change
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
	-- overpowered"; PartData.Slots `top`; sound parts are fine on them, looks at Optima Werkz aren't
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
-- driving a brand's cars levels the brand up; each level takes CustomsOff off Optima Werkz on
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
	-- (owner, 2026-11-13: "the more u drive or do burnout or drift the tires wore out and lose alot of traction
	-- causing u to replace tires at the repair shop") about 4 times faster than before: a set lasts about 3.5 hours
	-- of normal driving, 2 minutes of drifting, or 50 seconds of burnouts and donuts (was 0.03, 0.2, 0.5)
	Tyres = { PerMile = 0.12, DriftPerSecond = 0.8, BurnPerSecond = 2 },
	Brakes = { PerMile = 0.015, HardPerSecond = 0.04 },
	Tow = 1.25, -- a trailer on: wear and fuel times this (fuel: Config.Fuel.Tow)
	-- what it does to the car
	EngineWarn = 60, -- check engine, steady
	EngineFlash = 30, -- check engine, flashing: misfires
	EngineLimp = 10, -- limp mode
	PowerAtWarn = 0.08, -- power lost by EngineFlash, from EngineWarn down
	PowerAtFlash = 0.15, -- power lost by 0, from EngineFlash down
	LimpMph = 45,
	GripLoss = 0.45, -- at 0% tyres (owner, 2026-11-13: worn tyres "lose alot of traction"; was 0.1)...
	GripCurve = 2, -- ...little of it while the tyres are fresh, most of it at the end: 50% tyres lose 11%, 25% lose 25%
	TyreWarn = 30, -- "Tyres worn" under this many percent...
	TyreBald = 10, -- ...and "Tyres bald" under this
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
	SellShare = 0.6, -- what Rider Auto pays of a car's value
}

Config.Service = {
	Name = "LEGENDS SERVICE",
	-- (Yangon step 11, 2026-11-14: the workshop on New Road by the Racing Hub, built by CareVenues.service on a
	-- YangonSites lot; Monaco's was Bay (15244.7, 3.7, 1082.7), Arrive from (15240, 4.7, 1036))
	-- (1:1, 2026-11-17: on Kabar Aye Pagoda Road's east side, the venue row; CareVenues.service on its YangonSites lot)
	-- (24 Nov: the workshop moved with its lot off a road that ran through it, to the lot at (35671.1, 25260.5) facing (0.259, 0.966); was Bay (35140.3, 42.7, 24410.4))
	Bay = Vector3.new(35688.5, 48.7, 25286.9), -- the middle of the workshop's middle bay (tools/riviera/CareVenues.luau)
	Arrive = CFrame.lookAt(Vector3.new(35703.4, 48.7, 25343.0), Vector3.new(35688.5, 48.7, 25286.9)), -- fast travel: on the forecourt, facing the bay
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
	toyoka_ae86 = true, -- the model's own two doors and door mirrors (normal front-hinged doors, 2026-11-14)
	toyoka_chaser = true, -- the model's own four doors (front L / R, rear L2 / R2) and door mirrors (front-hinged, 2026-11-14)
	ronin_cp9a = false, -- doors built (ronin_cp9a@doors: four doors, door shuts built) but OFF (2026-11-14): the front shuts' lower flange shows as two body-colour wedges in the front footwells from the seats, doors shut. true puts them on
	pleiad_gc8 = true, -- the model's own two doors and door mirrors; the body's own painted shuts, no jamb built (front-hinged, 2026-11-15)
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
		-- Yangon (build step 9, 2026-11-13): on New Road by Optima Werkz (tools/yangon/YangonSites.luau S.fuel)
		-- (1:1, 2026-11-17) the real Myawady station on Kabar Aye Pagoda Road by the flyover (places_1to1.py, Data_P1P): its 8 pumps
		{ id = "fuel_yangon", name = "Kabar Aye Fuel", pumps = { Vector3.new(34609.54, 62.91, 29154.71), Vector3.new(34606.4, 62.91, 29147.57), Vector3.new(34624.54, 62.91, 29148.12), Vector3.new(34621.4, 62.91, 29140.98), Vector3.new(34598.76, 62.91, 29130.15), Vector3.new(34595.62, 62.91, 29123.01), Vector3.new(34613.75, 62.91, 29123.57), Vector3.new(34610.62, 62.91, 29116.42) }, chargers = { Vector3.new(34598.76, 62.91, 29130.15), Vector3.new(34595.62, 62.91, 29123.01), Vector3.new(34613.75, 62.91, 29123.57), Vector3.new(34610.62, 62.91, 29116.42) }, arrive = CFrame.lookAt(Vector3.new(34599.22, 65.2, 29172.33), Vector3.new(34610.12, 65.2, 29135.53)) },
	} :: { { id: string, name: string, pumps: { Vector3 }, chargers: { Vector3 }, arrive: CFrame } },
}

---------------------------------------------------------------------
-- GG Gaming Fest (2026-11-17; vault "City Legends/2026-11-17 GGFest at YCC (in game).md"): the real festival at
-- the Yangon Convention Centre, 21-22 Nov 2026. The hall and its dressing are in Workspace.Yangon1to1.Landmarks
-- (tools/yangon/landmarks3d/ycc_ggfest.py). While it is live: the GG Quest (Goals.lua; saved in profile.Goals.GG) and,
-- for finishing it, the GGFest look on your car (free, Customs). Studio test: workspace attribute GGFestForce = true.
-- (a function: Config's main chunk is at its constant limit)
---------------------------------------------------------------------
Config.GGFest = (function()
	return {
		Start = 1795195800, -- 2026-11-21 00:00 Myanmar time (UTC+6:30)
		End = 1795368600, -- 2026-11-23 00:00 Myanmar time
		Name = "GG Gaming Fest",
		Line = "21-22 Nov · Yangon Convention Centre",
		Hall = Vector3.new(33667.65, 54.82, 22020.95), -- the hall's middle on its floor
		Arrive = CFrame.lookAt(Vector3.new(33746.53, 57.82, 21934.52), Vector3.new(33746.53 + 0.7436, 57.82, 21934.52 + 0.6686)),
		ArriveRadius = 330, -- studs from the hall's middle: "drive to YCC"
		Photo = Vector3.new(33797.04, 54.82, 22137.28), -- the photo spot ring in front of the stage
		PhotoRadius = 14,
		PhotoSpeed = 3, -- studs a second: stopped
		-- the quest, in order: { id, text, stat (Goals.note), need, pts, best = a best value, not a sum }
		Quest = {
			{ id = "arrive", text = "Drive to GG Gaming Fest at YCC", stat = "ggarrive", need = 1, pts = 100 },
			{ id = "cuts", text = "Cut up %d cars", stat = "cuts", need = 15, pts = 150 },
			{ id = "combo", text = "Hit a x%d combo", stat = "combo", need = 6, pts = 150, best = true },
			{ id = "drift", text = "Bank a drift", stat = "drifts", need = 1, pts = 150 },
			{ id = "photo", text = "Stop on the photo spot at the stage", stat = "ggphoto", need = 1, pts = 200 },
		},
		CashPerPoint = 25,
		-- the limited GGFest look, put on the car you finish the quest in (Customs.clean keeps only valid fields)
		Wrap = { paint = { 124, 66, 240 }, finish = "metallic", accent = { 0, 196, 228 }, glow = { 236, 38, 150 }, plate = "GGFEST26" },
	}
end)()

-- is the festival on? (`now` = os.time(); Studio only: workspace attribute GGFestForce)
function Config.ggLive(now: number?): boolean
	local t = now or os.time()
	local g = Config.GGFest
	if t >= g.Start and t < g.End then
		return true
	end
	return game:GetService("RunService"):IsStudio() and workspace:GetAttribute("GGFestForce") == true
end

---------------------------------------------------------------------
-- Jobs with ranks and paychecks (owner approved 18 Nov 2026, Southwest Florida style; vault
-- "City Legends/2026-11-18 Jobs - ranks and paychecks.md"). server/Jobs.lua pays, shared/JobRules.lua
-- does the sums, client/JobsClient.lua shows the Job Center and the HUD bar. Yangon only.
--   * active jobs: on duty = doing the job (in your car with a stop to reach); pay is mostly per
--     stop / fare / ticket plus a small paycheck every PaycheckSeconds
--   * posts: AFK jobs, stand at the post; a bigger paycheck (about 1/3 of active per minute), no cap
--     (19 Nov: the shift check and idle rejoin are in shared/JobsData.lua)
--   * 5 ranks per job: RankXp (XP from time on duty and tasks) and RankMult (all its pay)
--   * Double Pay pass (499 R$): x2 on all job pay. Read from the player's "DoublePay" attribute
--     (server/Store.lua); Studio test: server player attribute TestDoublePay = true
-- (a function: Config's main chunk is at its constant limit)
---------------------------------------------------------------------
Config.Jobs = (function()
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x, y, z)
	end
	local t = {
		On = true,
		-- the Job Center kiosk on Myanmar Plaza's forecourt, facing Kabar Aye Pagoda Road (spawn is just south)
		Center = CFrame.lookAt(v(34742, 40.6, 27586), v(34700, 40.6, 27586)),
		PaycheckSeconds = 60,
		DoublePayMult = 2,
		RankMult = { 1, 1.3, 1.65, 2.1, 2.7 }, -- every pay of the job at rank 1..5
		RankXp = { 0, 250, 800, 2000, 4500 }, -- XP to reach rank 1..5 (per job)
		DutyXpPerMinute = 6,
		PostRadius = 12, -- studs from the post (flat)
		IdleSeconds = 150, -- an active job with no task done this long: off duty (no AFK pay)
		ArriveRadius = 30, -- studs from a stop / fare / patrol point
		StopSps = 14, -- you must be (nearly) stopped there
		MaxSps = 300, -- no car is faster: a leg done quicker than distance / MaxSps is refused
		RadarSeconds = 3, -- police: hold still this long at a patrol point (the radar check; client side, feel only)
		Ticket = { Range = 90, Pay = 250, Xp = 10, Cooldown = 45 }, -- police: a real player speeding past (Police.SpeedLimitKmh)
		Taxi = { PickupMin = 250, PickupMax = 1400, FareMin = 900 }, -- studs
		Patrol = { Min = 600, Max = 1800 },
		List = {
			{ id = "delivery", name = "Delivery", kind = "active", where = "Dispatch rings (Myanmar Plaza, Kabar Aye)", paycheck = 100, taskXp = 25,
				ranks = { "Parcel Runner", "Van Driver", "Senior Courier", "Route Boss", "Express Chief" } },
			{ id = "taxi", name = "Taxi", kind = "active", where = "Fares all over town", paycheck = 100, base = 100, perStud = 0.22, taskXp = 20,
				ranks = { "Night Cabbie", "City Driver", "Airport Regular", "Top Fare", "Taxi Legend" } },
			{ id = "bus", name = "YBS Bus Driver", kind = "active", where = "7 stops: Kabar Aye, Kamayut, Mayangone", paycheck = 100, base = 50, perStud = 0.12, taskXp = 6,
				ranks = { "Spare Boy", "Bus Driver", "Line Driver", "Route Captain", "YBS Legend" } },
			{ id = "police", name = "Traffic Police", kind = "active", where = "Patrol points + speeders", paycheck = 100, base = 80, perStud = 0.15, taskXp = 8,
				ranks = { "Cadet", "Constable", "Sergeant", "Inspector", "Traffic Chief" } },
			{ id = "tea", name = "Tea Shop", kind = "post", where = "Shwe Lahpet Tea Shop, Inya Lake", post = v(35553.1, 36.92, 27386.1), paycheck = 200,
				ranks = { "Table Boy", "Tea Maker", "Head Brewer", "Shop Manager", "Tea House Owner" } },
			{ id = "fuel", name = "Fuel Station", kind = "post", where = "Kabar Aye Fuel (the flyover station)", post = v(34603.22, 62.31, 29138.33), paycheck = 200,
				ranks = { "Pump Attendant", "Cashier", "Shift Lead", "Station Manager", "Station Owner" } },
			{ id = "dealer", name = "Dealership Staff", kind = "post", where = "Rider Auto, Kabar Aye", post = v(35424.4, 38.56, 22405.2), paycheck = 200,
				ranks = { "Car Washer", "Sales Associate", "Senior Sales", "Sales Manager", "General Manager" } },
			{ id = "mall", name = "Mall Shop", kind = "post", where = "Golden Thread Boutique, Myanmar Plaza", post = v(34778, 40.5, 27640), paycheck = 200,
				ranks = { "Shop Helper", "Sales Clerk", "Senior Clerk", "Floor Manager", "Boutique Owner" } },
		},
		-- the YBS line: real bus stops on the map (street kit), driven in this order, then round again
		-- (27 Nov, owner: "rn lets have 3 jobs only to not complicate things in release") only these are offered; the others
		-- stay in List's data below (moved to Off) so they come back by adding their id here. A save on an Off job is cleared
		-- by JobRules (an unknown cur). Delivery = the new-player guide's job, Taxi = the Yangon car job, Tea Shop = the AFK post.
		Live = { delivery = true, taxi = true, tea = true },
		BusStops = {
			{ name = "Myanmar Plaza", pos = v(34538.1, 40.36, 27663.0) },
			{ name = "Inya Lake", pos = v(34598.9, 45.33, 27203.8) },
			{ name = "9 Mile", pos = v(34837.1, 45.21, 25409.4) },
			{ name = "Tea Shop Corner", pos = v(35524.6, 36.61, 27491.4) },
			{ name = "Kamayut Flats", pos = v(35805.6, 34.62, 27942.5) },
			{ name = "Mayangone", pos = v(34923.0, 74.74, 29784.6) },
			{ name = "Pyay Road", pos = v(34178.9, 60.18, 28812.6) },
		},
	}
	local live, off = {}, {}
	for _, job in t.List do
		table.insert(if t.Live[job.id] then live else off, job)
	end
	t.List, t.Off = live, off
	return t
end)()

-- (2026-11-27, owner: "the lighting angle is too low ... not spread out like the ones in real life", "irl, night lights
-- are white, not dim") Yangon street lamps: a white PointLight hung DROP studs under the head (on an Attachment), so its
-- 60-stud reach spreads a wide pool over road, pavement, walls and trees that meets the next lamp's; a soft glow sprite
-- (BillboardGui tag LampHalo, tools/yangon/city/lamp_glow.py) on the head at night. Used by tools/yangon/YangonStreetKit
-- (the P1 kit lamps) and client/YangonRoadside (the poles elsewhere, and the flyover deck lamps)
Config.NightLamps = {
	Color = Color3.fromRGB(240, 244, 255),
	Head = Color3.fromRGB(236, 244, 255),
	Brightness = 3,
	Range = 60,
	Glow = "rbxassetid://83825952241880",
	GlowSize = 11,
}

return Config
