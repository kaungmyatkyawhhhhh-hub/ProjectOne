-- MapConfig (Galaxy Incremental): EVERY size and position of the map. The builder (ServerStorage.GalaxyMapBuilder), the
-- islands (GalaxyMapService) and the client (GalaxyMapClient) build only from this table.
-- REDONE TO SCALE (owner, 2 Nov night; vault "Galaxy Incremental - Map scale spec (redo)"): every piece is sized against the
-- R15 character (~5.2 studs tall, ~2 wide, walks 16 studs/s), not against the concept picture. Kit meshes are only ever
-- scaled UNIFORMLY (Kit.Fit): where the spec table and a mesh's own proportions disagree, the size the player meets is kept
-- (noted at the line).
-- Everything that grows reads the PLAYER's attributes (set by the economy): Bodies, BodyTiers, Supernovas, SupernovaReady,
-- and the Ignition checklist's attributes (below).
local MapConfig = {}

MapConfig.Origin = Vector3.new(0, 40, 0) -- the centre plaza's floor (the map floats in space)
MapConfig.Character = { Height = 5.2, Width = 2, WalkSpeed = 16 } -- (the yardstick)

function MapConfig.ZoneDir(angle: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a), 0, math.sin(a))
end

------------------------------------------------------------------------ the centre plaza (140 across)
-- Zone angles in degrees, the same as the islands' (0 = +X, 90 = +Z). The 8 bridges land at 22.5 + 45k; every zone sits in a
-- gap between two landings, so the walkway from each bridge to the Core stays open (8 wide + margin).
MapConfig.Centre = {
	Radius = 70,
	-- (IslandTop / IslandUnder scaled uniformly to 140 across: the slab is 12.6 thick, the rock cone 72 deep)
	Floor = { Fit = 140 }, Under = { Fit = 140 },
	Rim = { Fit = 141.5, Top = 1.5 },               -- the brass rim round the edge: sticks up 1.5 (a ledge, not a wall)
	Inlay = { Radius = 18, Top = 0.12 },            -- the brass ring round the Core's plaza
	TileCount = 40,                                 -- wedge tiles in the second stone tone, inlay -> rim
	Lamps = { Ring = 66, Spread = 5, Pillar = 7.4, Orb = 1.6 }, -- a pair at each bridge landing; 9 tall in all
	-- the Core: the star 10 across with its top ~20 up, 3 gyroscope rings 18-22 across, a stepped altar; footprint ~26
	Core = {
		Height = 15, Star = 10, Spikes = 12, Spike = 2.4,
		Altar = 14,                                 -- (Altar mesh at 14 across = 4.1 high: 3 steps)
		Collar = 9,
		Gyros = { { 9, 72, 0, 0.35 }, { 10, -58, 30, -0.25 }, { 11, 10, -70, 0.18 } }, -- radius, tilt X, tilt Y, spin
	},
	-- a stone threshold over the brass rim at every bridge landing (the bridges used to run under the rim)
	Threshold = { In = 4, Out = 3, Top = 1.6, Thick = 0.8, Ramp = 5 },
	Zones = {
		StarSurge = { angle = 45, dist = 52 },      -- FRONT: the server-wide STAR SURGE bar, facing the Core
		Forge = { angle = 315, dist = 50 },         -- RIGHT: the Star Forge on its platform, facing the Core
		BlackHole = { angle = 225, dist = 52 },     -- BACK: the Black Hole gate on its dais, facing the Core
		Sector2 = { angle = 180, dist = 65 },       -- BACK-LEFT: the Sector 2 gate arch + IGNITION sign + its bridge
		Leaderboard = { angle = 135, dist = 50 },   -- LEFT: top Supernovas + players near you, facing the Core
	},
	Gaps = { 0, 90, 270 },                          -- the open gaps: star-chart inlay, benches, crystals
	Details = { Chart = 40, ChartRadius = 7, Benches = 56, BenchSpread = 6, RimCrystals = 63 },
}

-- the plaza's pieces (all sizes in studs; "bottom" = its lowest edge above the floor)
MapConfig.StarSurge = { Width = 24, Height = 9, Bottom = 3, Frame = 0.8, Depth = 0.6 }
MapConfig.Forge = {
	Platform = 26,                                  -- (Dais mesh at 26 across = 4.4 high, 3 steps)
	Anvil = 8,                                      -- 8 long (the mesh makes it 4.7 high: chest height)
	Padlock = 2.5,                                  -- 2.5 high, hanging ON the anvil's front face
	Rim = 18,
	Sign = { Width = 15, Height = 6, Bottom = 1.2, Dist = 16 }, -- ("STAR FORGE" letters ~3 studs; clears the walkways)
}
MapConfig.BlackHole = {
	Dais = 30,                                      -- (Dais mesh at 30 across = 5.1 high, 3 steps)
	Ring = 22,                                      -- the gate ring, ~4x a player
	VoidShare = 0.76,                               -- the void's diameter / the ring's
	Arms = 3, ArmSteps = 18, ArmWidth = 1.8,
	Sign = { Width = 15, Height = 6, Bottom = 1.2, Dist = 18 },
}
MapConfig.Leaderboard = { Width = 24, Height = 12, Bottom = 3, Rows = 10 } -- (TOP SUPERNOVAS: 2 columns of 5, overnight part 3)
-- PLAYERS NEAR YOU (overnight part 3): its own board next to the leaderboard wall (it shared the wall before and was too
-- small to read on a phone): 5 above you, you (gold), 5 below; on the floor between the wall's end and the star-chart gap
-- the FREE REWARDS board (Phase 2.4, 6 Nov; Depth's lobby board): on the plaza between the Star Surge (45) and PLAYERS NEAR YOU
-- (110), facing the Core; its screen is drawn by GalaxyDaily
MapConfig.FreeBoard = { angle = 80, dist = 46, Width = 11, Height = 7.5, Bottom = 3 }
MapConfig.NearBoard = { angle = 110, dist = 46, Width = 13, Height = 15, Bottom = 3, Rows = 11 }
MapConfig.Sector2 = {
	-- the arch scaled uniformly so the 10-wide bridge fits through it (the kit arch's opening is 74% of its width): 14.2 wide,
	-- 18 high (the spec's 14 x 12 arch would leave a 9-wide opening for a 10-wide bridge)
	Arch = 14.2,
	NameSign = { Width = 24, Height = 4 },          -- "SECTOR 2: COMET REACH", letters ~2.7
	Ignition = { Width = 11, Height = 13, Bottom = 1, Angle = 166, Dist = 57 },
}

------------------------------------------------------------------------ the personal islands (60 across)
MapConfig.Islands = {
	Count = 8,
	Radius = 30,
	Ring = 128,                                     -- centre to island centre: plaza 70 + bridge ~22 + island 30 (+ thresholds)
	-- (IslandTop at 60 across = 5.4 thick, the rock cone 31 deep; the spec says 4 thick: the mesh decides)
	Floor = { Fit = 60 }, Under = { Fit = 60 },
	StartAngle = 22.5,                              -- island i at StartAngle + (i-1)*45 (the gap at 180 = the Sector 2 bridge)
	Heights = { 1.2, -1.5, 2, -0.5, 1.6, -1.8, 0.4, 2.2 },
	Bridge = { Width = 8, Thick = 0.8, Segments = 10, Arch = 2.5, Rail = 1.2 },
	-- the island end of every bridge: a threshold over the island's rim (in island units: x = out from the Core, from -Radius)
	Landing = { From = -33, To = -25, Top = 1.6, Ramp = 4 },
	-- island-local places (x = away from the Core, z = to the side; the bridge enters at x = -30, z = 0)
	-- the spawn FACES THE PAIR of boards, 21 studs in front of it: from the spawn camera (Roblox starts it 12.5 behind you,
	-- looking down at you) the pair fills most of the screen with its huge titles in view (owner, boards 1:1 passes 2-3;
	-- checked again in the lighting pass with Roblox's real starting camera: at 16.5 the titles were still cut off).
	-- (The island's star beam starts above the boards now, so the camera may stand behind it.)
	Spawn = Vector3.new(4, 0, -2.5),
	SpawnRock = Vector3.new(-2, 0, -2),             -- (tier 0: on the walkway over the rock)
	Rock = 30,                                      -- tier 0 / free slot: a bare asteroid 30 across (the mesh makes it 23 high)
	Tiles = { From = 0.6, To = 0.92, Count = 14 },
	RimFit = 61,                                    -- tier 2 brass rim (1.5 high)
	InlayFit = 34,
	Lamps = { Radius = 27.5, Angles = { 60, -60, 120, -120 }, Pillar = 6.5, Orb = 1.5 }, -- 8 tall; none at the bridge or the boards
	-- (the crystals, banner and telescope keep clear of the four boards: none in front of a board, none on the bridge path)
	Crystals = { Angles = { 130, 150, -125 }, From = 15, To = 21, Low = 3, High = 8 },
	Garden = { At = Vector3.new(-6, 0, 12), Fit = 14 },
	Banner = { At = Vector3.new(-21, 0, 17), Pole = 10, Cloth = 5 }, -- (the cloth mesh at 5 high is 5.1 wide)
	CrownRing = 55, CrownHeight = 15.5,             -- tier 5: a brass halo ring above the island (clear of the boards' tops)
	Dais = 12,
	Telescope = { At = Vector3.new(-19, 0, -13), Height = 7 },
	HangingCrystals = 3,
	-- tier 0 (a new player): the walkway from the bridge across the rock to a stone pad under the pair of boards, + a pad
	-- under each side board (Bodies, Star Upgrades) touching the rock
	RockPad = { At = Vector3.new(19, 0, 0), Fit = 34, WalkTo = 4 },
	SidePads = { Fit = 22, In = 2 }, -- (centred In studs nearer the middle than the side board)
	-- the ISLAND PADS (feel pass, 5 Nov): where the next pad sits (one at a time, in this order round the dais, all in
	-- front of the spawn camera or beside it; never on the bridge path or in front of a board), its size, click reach
	-- (6 Nov, owner: "buttons inside a platform": spots 3, 4, 6 and 10 sat in the MOON GARDEN / the crystals once those were
	-- built; moved clear of every piece. MapService.placePad also skips a spot a piece is in, PadClear studs round the rim)
	-- (picked from a Studio scan of all 8 islands with every piece built: the side of the island between the garden, the
	-- crystals and the banner has no room; spot 6 is beside the bridge path, clear of the light walk)
	PadSpots = { Vector3.new(10, 0, 8), Vector3.new(10, 0, -9), Vector3.new(7, 0, 12), Vector3.new(-1, 0, -12.5), Vector3.new(15, 0, 3),
		Vector3.new(-15, 0, -8), Vector3.new(14, 0, -4), Vector3.new(9, 0, 16), Vector3.new(6, 0, -15), Vector3.new(13, 0, 14) },
	PadSize = 4.5, PadReach = 60, PadClear = 0.5,
	-- what pads 11-20 build (island-local, x = out from the Core, z = to the side)
	PadBuilds = {
		Gyro = { Fit = 16, Height = 9, Tilt = 24 },
		Gate = { X = -22, Height = 11 },
		Lights = { Angles = { 45, 135, -45, -135 }, Radius = 9, Post = 3.2, Orb = 1 },
		Floaters = { Angles = { 35, 75, 105, 145, -35, -75, -105, -145 }, Radius = 34, Size = { 2.5, 4 }, Height = { 5, 9 } },
		Altar = { Height = 2.4, Orb = 1.4 },
		Halo = { Fit = 76, Height = 3, Tilt = 6 },
		Globe = { At = Vector3.new(-12, 0, -17), Stand = 3, Size = 3 },
		Spires = { Angles = { 160, -160 }, Radius = 26, Height = 8 },
		Walk = { From = -26, To = 0, Half = 4.6 },
		Beacon = { At = Vector3.new(-21, 0, -21), Height = 12, Orb = 2.4 },
	},
}

-- the island BOARDS (owner, 2 Nov: "1:1 direct copy boards from regrowth"; vault "Island boards like Regrowth 1to1"): four
-- live boards round every owned island, placed like Regrowth's plot (island-local: x = out from the Core, z = to the side).
--  * far edge, the PAIR (Regrowth's Perks Tree + Info): CONSTELLATION TREE left, INFO right; upright, each turned V degrees
--    in toward the player (a shallow V), Gap studs apart; the spawn faces Pair.At (the middle of the gap)
--  * left edge BODIES (Regrowth's Machines board), right edge STAR UPGRADES (Factory Upgrades): Tilt back on a stand
-- Pass 2 (owner, vault "Prompt - Boards 1to1 pass 2"):
--  * the pair: BIG (screens 11 x 13, ~2.5x the player), set INTO a low stone ledge (no legs; the screen's bottom at waist
--    height), a thick lavender stone frame with a lighter lip (the bevel) and side posts with round caps; huge white titles
--    over the top frame edge; an energy strip (crackling beams + a halo) round the frame, spilling out
--  * BODIES: Regrowth's Machines board: a thin angular frame (lavender tubes with violet neon, wider at the top), a neon glow
--    strip on top, on a ground stand
--  * STAR UPGRADES: the chunky stone frame with a thick animated flame border (gold / violet) spilling out
-- The titles, the halos, the beams and the flames are the client's (GalaxyBoards), only near you. Width / Height = the
-- screen; the frame goes round it. The screen's SurfaceGui (IslandBoardsUI) is drawn by the client, PxPerStud a stud. No
-- prompt, no ClickDetector: the buttons are on the screens. A board buy: the server checks the island's owner + within
-- BuyRange of the island's centre.
MapConfig.Boards = {
	PxPerStud = 50,
	-- (5 Nov, faded boards: LightInfluence 0 screens at Brightness 1 were washed out by the Atmosphere haze + the GalaxyGrade
	-- colour correction + bloom; tested 1.5 / 1.8 / 2.2 in Play: 1.8 = whites and the green / purple buttons like the 2D
	-- window, the dark rows stay dark (2.2 lifts them to purple). Island boards, their titles and the map signs use it)
	Brightness = 1.8,
	Stone = Color3.fromRGB(203, 192, 230), StoneLight = Color3.fromRGB(228, 221, 247), StoneDark = Color3.fromRGB(146, 134, 184),
	Screen = Color3.fromRGB(10, 8, 18),
	-- the pair: At = the middle of the gap; Bottom = the screen's bottom above the floor; the frame: Lip (the lighter bevel
	-- step), Bar (top), BarLow (bottom, on the ledge), Post (side posts, PostDepth deep), Depth; the ledge LedgeDepth deep
	Pair = { At = Vector3.new(25, 0, 0), Gap = 3, V = 16, Bottom = 2.8, Lip = 0.45, Bar = 1.5, BarLow = 0.5, Post = 2,
		PostDepth = 2.4, Depth = 1.8, LedgeDepth = 3.4 },
	Frame = 1.2, Depth = 1.2, -- (Star Upgrades' chunky frame)
	List = {
		-- (5 Nov: 11 x 13 -> 12.5 x 14.8 studs with the same 550 x 650 canvas, Px 44, so the TREE tiles read >= 44 px on the
		-- phone frame from the spawn; the tops stay under the star beam's start, System.BeamFrom)
		{ id = "Tree", title = "CONSTELLATION TREE", pair = -1, Width = 12.5, Height = 14.8, Px = 44, Neon = Color3.fromRGB(150, 100, 255) },
		{ id = "Info", title = "INFO", pair = 1, Width = 12.5, Height = 14.8, Px = 44, Neon = Color3.fromRGB(70, 165, 255) },
		{ id = "Bodies", title = "BODIES", At = Vector3.new(0, 0, -23), Width = 14, Height = 8, Tilt = 10, Bottom = 2.6,
			Style = "Neon", Neon = Color3.fromRGB(190, 110, 255) },
		{ id = "Stars", title = "PERKS", At = Vector3.new(0, 0, 23), Width = 14, Height = 8, Tilt = 10, Bottom = 2.6,
			Style = "Neon", Flames = true, Neon = Color3.fromRGB(255, 176, 42), Neon2 = Color3.fromRGB(170, 90, 255) },
		-- (Phase 2.7 #215: the STAR FORGE + BLACK HOLE boards, small, in the corners between the pair and the side boards;
		-- a padlock + what opens them; the FORGE one opens the Forge window from IGNITION 1. Checked clear of every piece +
		-- pad by the 6 Nov placement scan)
		{ id = "ForgeLock", title = "STAR FORGE", At = Vector3.new(17, 0, -19), Width = 6, Height = 4, Tilt = 0, Bottom = 1.6,
			Neon = Color3.fromRGB(255, 200, 70), locked = { text = "IGNITION 1", attr = "Ignition", need = 1, window = "Forge", icon = "forge" } },
		{ id = "BlackHoleLock", title = "BLACK HOLE", At = Vector3.new(17, 0, 19), Width = 6, Height = 4, Tilt = 0, Bottom = 1.6,
			-- (3.1: it opens with Ignition 1; the window shows the 100K shards progress and the COLLAPSE)
			Neon = Color3.fromRGB(170, 90, 255), locked = { text = "IGNITION 1", attr = "Ignition", need = 1, window = "BlackHole", icon = "blackHole" } },
	},
	-- the angular neon frame (Style "Neon": Bodies, Star Upgrades), round the screen: its bottom corners Low out and down, its
	-- top corners Wide out and High up (wider at the top, like Regrowth's Machines board)
	Angular = { Low = 0.4, Wide = 1.6, High = 0.7 },
	BuyRange = 40,  -- (from the island's centre: the island is 60 across, so anywhere on it)
	DrawRange = 160,
}
MapConfig.Boards.ById = {}
for _, b in ipairs(MapConfig.Boards.List) do MapConfig.Boards.ById[b.id] = b end

-- the island grows (tycoon feeling): each tier adds pieces (a pop + sparkle). Bodies reset every Supernova, so the first
-- tiers come from bodies owned in the first run and the later ones from Supernovas: an island never shrinks.
MapConfig.Tiers = {
	[0] = { name = "Bare rock", note = "a new player" },
	-- (feel pass, 5 Nov: the island now grows from the PADS you buy, EconConfig.Pads; these tiers only migrate old saves and
	-- name the island Tier the pads add up to)
	[1] = { name = "Stone disc + Upgrades terminal", bodies = 5 },
	[2] = { name = "Brass rim", bodies = 25 },
	[3] = { name = "Lamp pillars", bodies = 75 },
	[4] = { name = "Crystal garden", supernovas = 1 },
	[5] = { name = "Banner + crown ring", supernovas = 3 },
	[6] = { name = "Telescope + dais", supernovas = 8 },
	-- (later sectors add tiers here: Comet Reach, Nebula Gate, ...)
}
MapConfig.MaxTier = 6
-- the rank (on the name plate and over your head): NEW STAR (tiers 0-1), RISING STAR (2-3), then by Supernovas (alpha part 1,
-- PROPOSED names; design: "rank SPARK" at Supernova 1; colour per rank, gold first, VFX plan "Spark gold -> ...")
MapConfig.Ranks = {
	{ at = 1, name = "SPARK", colour = Color3.fromRGB(255, 205, 90) },
	{ at = 3, name = "FLARE", colour = Color3.fromRGB(255, 150, 70) },
	{ at = 5, name = "BLAZE", colour = Color3.fromRGB(255, 110, 120) },
	{ at = 8, name = "NOVA", colour = Color3.fromRGB(200, 140, 255) },
	{ at = 12, name = "SUPERGIANT", colour = Color3.fromRGB(120, 200, 255) },
}
function MapConfig.RankDef(supernovas: number)
	local def
	for _, r in ipairs(MapConfig.Ranks) do
		if supernovas >= r.at then def = r end
	end
	return def
end
function MapConfig.RankOf(tier: number, supernovas: number): string
	local def = MapConfig.RankDef(supernovas)
	if def then return def.name end
	return if tier >= 2 then "RISING STAR" else "NEW STAR"
end

-- the SUPERNOVA moment (alpha part 1; VFX plan: anticipation -> impact -> fade, ~5 s the first time, ~2 s after, skip after
-- the first): seconds of each beat; the nebula patches that stay in the sky over your island (one per Supernova, max Nebulae)
MapConfig.Supernova = {
	First = { Windup = 7.6, Hold = 0.4, Fade = 2.0 }, -- (~10 s: the cutscene template's first Supernova, 5 Nov; the climax at 8 s)
	Again = { Windup = 0.8, Hold = 0.1, Fade = 1.1 }, -- (~2 s)
	Swell = 1.8,          -- the star grows to this x its size in the wind-up
	FovPunch = 8,         -- degrees, at the impact (none with Reduced Motion)
	Shockwaves = 2,       -- rings across the plaza and the islands, for everyone
	Nebulae = 8, NebulaHeight = 70, NebulaSize = 70,
}
function MapConfig.TierOf(bodies: number, supernovas: number): number
	local tier = 0
	for t = 1, MapConfig.MaxTier do
		local need = MapConfig.Tiers[t]
		local ok = (need.bodies == nil or bodies >= need.bodies or supernovas >= 1) and (need.supernovas == nil or supernovas >= need.supernovas)
		if ok then tier = t end
	end
	return tier
end

-- the star system above an island: 30 above the floor (boards pass 3: clear above the 19-tall pair of boards); a rock until the
-- player owns a Star THIS run (alpha part 1: a Supernova shrinks it back to the rock, then it regrows), then a star 4 -> 8
-- across by tier; one planet per body tier owned (max 6) on
-- orbits of radius 6 -> 14, planets 1.5 -> 3. Its beam (and the stardust motes) start at BeamFrom, above every board's top,
-- so from the island they never run across a board.
MapConfig.System = {
	Height = 30, BeamFrom = 19.5, StarMin = 4, StarMax = 8, Rock = 4,
	OrbitMin = 6, OrbitMax = 14, PlanetMin = 1.5, PlanetMax = 3,
	Belt = 16.5, BeltRock = { 0.8, 1.5 }, MaxBelt = 20,
	MaxPlanets = 6, StarTierFrom = 5,
	Plate = { Above = 10, Width = 26, Height = 4.6 }, -- name letters ~2.5
}
function MapConfig.SystemOf(bodyTiers: number, _supernovas: number)
	local star = bodyTiers >= MapConfig.System.StarTierFrom
	return { star = star, planets = math.clamp(bodyTiers, 0, MapConfig.System.MaxPlanets) }
end

-- the locked next sector, across the void (BACK-LEFT), its 10-wide bridge lit one segment at a time as the Ignition
-- checklist fills
MapConfig.NextSector = {
	Name = "SECTOR 2: COMET REACH", -- (opens at IGNITION 1: the STAR FORGE)
	Angle = 180, Distance = 160, Height = 12, Radius = 30,
	BridgeWidth = 10, BridgeSegments = 18, LitAtStart = 3, Arch = 8,
	Crystals = { 5, 10 }, Padlock = 6,
}
do
	local NS = MapConfig.NextSector
	local a = math.rad(NS.Angle)
	NS.Position = Vector3.new(math.cos(a) * NS.Distance, NS.Height, math.sin(a) * NS.Distance)
end
-- the IGNITION gate of Sector 1 (feel pass + purpose, 5 Nov): all four at once (the server checks, GalaxyEconService
-- checkIgnition); tuned with the Studio bot to land ~minute 28 (vault "Feel pass" Progress note). Done once = Ignition 1
MapConfig.Ignition = {
	-- (Calc\feel2.py at ~28 real min: Supernova 11, LVL 19, all 20 pads; IRON = a body at Lv 20 in that run)
	{ attribute = "Supernovas", need = 11, text = "Go Supernova 11 times" }, -- (5 Nov re-tune: Supernova 11 ~27.4 min in Calceel2.py)
	{ attribute = "CosmicLevel", need = 19, text = "Reach Cosmic LVL 19" },
	{ attribute = "Pads", need = 20, text = "Build all 20 island pads" },
	{ attribute = "BestTier", need = 3, text = "A body at IRON (Lv 20)" },
}
function MapConfig.IgnitionDone(player: Player): (number, number)
	if (tonumber(player:GetAttribute("Ignition")) or 0) >= 1 then return #MapConfig.Ignition, #MapConfig.Ignition end
	local done = 0
	for _, item in ipairs(MapConfig.Ignition) do
		local value = player:GetAttribute(item.attribute)
		local n = if type(value) == "boolean" then (if value then 1 else 0) else (tonumber(value) or 0)
		if n >= item.need then done += 1 end
	end
	return done, #MapConfig.Ignition
end

-- STAR SURGE (design section 7): every Supernova in the server fills 5%; full = x2 stardust for everyone for 3 min, at most
-- once per 10 min; the bar shows who filled it last
MapConfig.Surge = { PerSupernova = 5, Mult = 2, Duration = 180, Cooldown = 600 }

-- the player's colour (banner, name plate, island trim): one per island slot
MapConfig.PlayerColors = {
	Color3.fromRGB(235, 80, 60), Color3.fromRGB(60, 145, 245), Color3.fromRGB(80, 210, 110), Color3.fromRGB(190, 80, 235),
	Color3.fromRGB(245, 185, 50), Color3.fromRGB(60, 210, 210), Color3.fromRGB(240, 105, 160), Color3.fromRGB(150, 150, 165),
}

MapConfig.Colors = {
	-- (owner, pass 3: stone #E8DCC8; lighting pass: brass #D9A441; Stone2 = the floor tiles' second tone; Rock = the cones
	-- under the islands)
	Stone = Color3.fromRGB(232, 220, 200), Stone2 = Color3.fromRGB(204, 188, 162), Rock = Color3.fromRGB(128, 104, 150),
	BareRock = Color3.fromRGB(150, 142, 150), Brass = Color3.fromRGB(217, 164, 65), Lamp = Color3.fromRGB(255, 196, 110),
	Crystal = Color3.fromRGB(150, 85, 255), Grass = Color3.fromRGB(90, 200, 140), Ice = Color3.fromRGB(130, 215, 255),
	Bridge = Color3.fromRGB(125, 100, 215), BridgeDim = Color3.fromRGB(70, 60, 105), Void = Color3.fromRGB(6, 2, 14),
	VoidGlow = Color3.fromRGB(150, 80, 255), Core = Color3.fromRGB(235, 158, 70), Spike = Color3.fromRGB(205, 96, 34),
	Steel = Color3.fromRGB(82, 88, 118), ForgeRim = Color3.fromRGB(80, 180, 255), Lock = Color3.fromRGB(215, 215, 228),
	Orbit = Color3.fromRGB(176, 150, 230), Star = Color3.fromRGB(255, 190, 80), Mote = Color3.fromRGB(255, 225, 160),
	SignBack = Color3.fromRGB(26, 20, 34), Screen = Color3.fromRGB(12, 10, 18),
}
-- brass everywhere = gold with a reflectance (lighting pass: #D9A441, 0.15, so it picks up the galaxy sky). (Material Metal
-- was tried in map pass 3: against the dark sky it mirrors the black and reads orange-brown, not gold.)
MapConfig.BrassMaterial = Enum.Material.SmoothPlastic
MapConfig.BrassReflectance = 0.15

-- the LIGHTING (owner, lighting pass 2 Nov; vault "Lighting pass"): every value here, applied by GalaxyLighting (the server
-- at start; the map builder; the client's low-end switch). Edit a number here + play to tune it.
--  * the sun = a low warm key light from the Core's side (one sun for the whole map, so it's aimed from the Core toward
--    island 1, the first player's island: ClockTime / GeographicLatitude give it 25 degrees up); the Core's own warm light
--    and each island's star light do the "light from the centre / my star lights my island" part
--  * violet ambient (shadows never black), violet atmosphere (far islands fade into violet, not white)
--  * bloom only on neon / the Core (threshold 1.8); a light warm grade; no sun rays, no depth of field
--  * lights: the Core (warm gold, 60) + one per island star (Star.Height above the island, range by tier), no shadows;
--    the boards light themselves with their neon. Full server: the Core, its rim light, the black hole, 8 stars = 11.
--  * LowEnd (phones, slow PCs, or Workspace TestLowEnd in Studio): bloom off, shadows off, island star lights off
MapConfig.Lighting = {
	ClockTime = 16.21, GeographicLatitude = 3.25, -- (sun 25 degrees up, from the Core over island 1)
	Brightness = 1.5, -- (2 + the Core's light + the star lights burnt the cream floor out; tuned in Play)
	ColorShift_Top = Color3.fromRGB(255, 236, 208), ColorShift_Bottom = Color3.fromRGB(150, 90, 235), -- (a softer gold: the
	-- grade's warm tint and the star lights add to it)
	GlobalShadows = true, ShadowSoftness = 0.3,
	Ambient = Color3.fromRGB(45, 35, 70), OutdoorAmbient = Color3.fromRGB(85, 70, 120),
	EnvironmentDiffuseScale = 0.6, EnvironmentSpecularScale = 0.8,
	ExposureCompensation = 0,
	-- (Haze 0.5 and the darker colours were tried: they drew a flat dark band over the galaxy sky behind the islands; with Haze 0
	-- the sky shows down to the horizon and the far islands still fade into violet)
	Atmosphere = { Density = 0.25, Offset = 0, Color = Color3.fromRGB(96, 56, 140), Decay = Color3.fromRGB(40, 20, 70), Glare = 0, Haze = 0 },
	Bloom = { Intensity = 0.4, Size = 24, Threshold = 1.8 },
	Grade = { Contrast = 0.15, Saturation = 0.15, Brightness = 0, TintColor = Color3.fromRGB(255, 244, 228) },
	-- (purpose: the galaxy before your Ignition 1: less colour, a touch darker and cooler; Ignition tweens to Grade)
	DimGrade = { Contrast = 0.1, Saturation = -0.2, Brightness = -0.04, TintColor = Color3.fromRGB(225, 225, 255) },
	Core = { Color = Color3.fromRGB(255, 186, 96), Range = 60, Brightness = 1 }, -- (2 blew the cream plaza out white; the
	-- client's pulse adds +-18% and a Supernova bursts it to 8)
	Star = { Height = 14, RangeMin = 20, RangeMax = 32, Brightness = 0.7 }, -- (range by island tier 0 -> MaxTier; the star's colour)
	-- (a slow PC: Roblox graphics level 1-3, or under 40 FPS over 8 s). Without shadows nothing is sun-lit or shaded, so the
	-- floor would go flat grey-pink: low-end uses a warmer, brighter OutdoorAmbient to keep the stone cream.
	LowEnd = { FpsBelow = 40, QualityAtMost = 3, OutdoorAmbient = Color3.fromRGB(150, 128, 120) },
}
MapConfig.PlanetColors = {
	Color3.fromRGB(150, 110, 240), Color3.fromRGB(80, 190, 255), Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 100, 120),
	Color3.fromRGB(255, 205, 80), Color3.fromRGB(200, 200, 215),
}

MapConfig.Sky = {
	-- (P&L Studios XP uploads, 2 Nov; Map\images\sky_*.png. Roblox's Lf is +X and Rt is -X. Up/Dn: the re-made v2 faces.)
	SkyboxFt = "rbxassetid://122365107824523", SkyboxBk = "rbxassetid://84969252246034", SkyboxLf = "rbxassetid://120684256007059",
	SkyboxRt = "rbxassetid://76670709549755", SkyboxUp = "rbxassetid://118744463737898", SkyboxDn = "rbxassetid://90521387144464",
}

-- a body's look by its NAMED TIER (feel pass, 5 Nov, #314): the type keeps its shape and its colour family; the tier sets the
-- surface. blend = how far the type's colour moves to the tier's colour. No glass / no part transparency (Playbook).
MapConfig.BodyLooks = {
	{ name = "DUST", material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(120, 108, 98), blend = 0.45 },
	{ name = "ROCK", material = Enum.Material.Slate, color = Color3.fromRGB(92, 80, 74), blend = 0.4 },
	{ name = "IRON", material = Enum.Material.CorrodedMetal, color = Color3.fromRGB(120, 132, 150), blend = 0.6 },
	{ name = "CRYSTAL", material = Enum.Material.Ice, color = Color3.fromRGB(170, 225, 255), blend = 0.65 },
	{ name = "PLASMA", material = Enum.Material.Neon, color = Color3.fromRGB(230, 70, 200), blend = 0.7 },
	{ name = "SOLAR", material = Enum.Material.Neon, color = Color3.fromRGB(255, 196, 70), blend = 0.8 },
	{ name = "NOVA", material = Enum.Material.Neon, color = Color3.fromRGB(255, 250, 235), blend = 0.85 },
}

MapConfig.LodDistance = 140      -- others' star systems simplified past this (star only)
MapConfig.VoidY = -110           -- below Origin.Y + this = fell off: back to your island
MapConfig.Comets = { From = 260, Through = 120, Low = 30, High = 80, Head = 4, Hit = 14, TutorialHit = 18 }

return MapConfig
