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
MapConfig.Leaderboard = { Width = 24, Height = 12, Bottom = 3, Rows = 10 }
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
	-- the spawn FACES THE BOARDS (owner, boards like Regrowth): tutorial step 1 is a button on the board. A little off the
	-- island's centre line, so the camera behind the player doesn't look through the star system's beam
	Spawn = Vector3.new(6, 0, -5),
	SpawnRock = Vector3.new(-2, 0, -2),             -- (tier 0: on the walkway over the rock)
	Rock = 30,                                      -- tier 0 / free slot: a bare asteroid 30 across (the mesh makes it 23 high)
	Tiles = { From = 0.6, To = 0.92, Count = 14 },
	RimFit = 61,                                    -- tier 2 brass rim (1.5 high)
	InlayFit = 34,
	Lamps = { Radius = 27.5, Angles = { 60, -60, 120, -120 }, Pillar = 6.5, Orb = 1.5 }, -- 8 tall; none at the bridge or the boards
	Crystals = { Angles = { 65, 105, -65, -105, 140 }, From = 15, To = 21, Low = 3, High = 8 }, -- (none in front of the boards)
	Garden = { At = Vector3.new(-6, 0, 12), Fit = 14 },
	Banner = { At = Vector3.new(0, 0, 26), Pole = 10, Cloth = 5 }, -- (the cloth mesh at 5 high is 5.1 wide)
	CrownRing = 55, CrownHeight = 15.5,             -- tier 5: a brass halo ring above the island (clear of the boards' tops)
	Dais = 12,
	Telescope = { At = Vector3.new(-15, 0, -11), Height = 7 },
	HangingCrystals = 3,
	-- tier 0 (a new player): the walkway from the bridge across the rock to a stone pad under the boards
	RockPad = { At = Vector3.new(19, 0, 0), Fit = 34, WalkTo = 4 },
}

-- the island BOARDS (owner, "boards like Regrowth", 2 Nov): two live panels on the OUTER edge of every owned island, on the
-- far side from the bridge, backs to the void, each face tangent to the rim, left UPGRADES / right CONSTELLATION TREE (seen
-- from the island). Their screens are live SurfaceGuis (GalaxyBoards, canvas 745 x 512 = the v12 board PNGs / 2) with real
-- buttons: no prompt, no ClickDetector. Buying from a board: the server checks the island's owner + within BuyRange.
-- (The spec's +-14 deg puts two 16-wide panels at radius 26 into each other: 18.5 deg is the closest they stand apart.)
MapConfig.Boards = {
	Radius = 26, Angle = 18.5, Tilt = 8, Bottom = 2.5,
	Width = 16, Height = 11,                        -- (16 / 11 = 1.4545 = the canvas 745 / 512)
	Frame = 0.8, Depth = 0.8,
	Canvas = Vector2.new(745, 512), Window = Vector2.new(30, 32), -- (the v12 window's place on the canvas)
	BuyRange = 45, DrawRange = 160,
	Panels = { { id = "Upgrades", side = -1 }, { id = "Tree", side = 1 } },
}

-- the island grows (tycoon feeling): each tier adds pieces (a pop + sparkle). Bodies reset every Supernova, so the first
-- tiers come from bodies owned in the first run and the later ones from Supernovas: an island never shrinks.
MapConfig.Tiers = {
	[0] = { name = "Bare rock", note = "a new player" },
	[1] = { name = "Stone disc + Upgrades terminal", bodies = 5 },
	[2] = { name = "Brass rim", bodies = 25 },
	[3] = { name = "Lamp pillars", bodies = 75 },
	[4] = { name = "Crystal garden", supernovas = 1 },
	[5] = { name = "Banner + crown ring", supernovas = 3 },
	[6] = { name = "Telescope + dais", supernovas = 8 },
	-- (later sectors add tiers here: Comet Reach, Nebula Gate, ...)
}
MapConfig.MaxTier = 6
-- the rank on the name plate (owner, pass 2): NEW STAR (tiers 0-1), RISING STAR (2-3), then SUPERNOVA n
function MapConfig.RankOf(tier: number, supernovas: number): string
	if supernovas >= 1 then return "SUPERNOVA " .. supernovas end
	return if tier >= 2 then "RISING STAR" else "NEW STAR"
end
function MapConfig.TierOf(bodies: number, supernovas: number): number
	local tier = 0
	for t = 1, MapConfig.MaxTier do
		local need = MapConfig.Tiers[t]
		local ok = (need.bodies == nil or bodies >= need.bodies or supernovas >= 1) and (need.supernovas == nil or supernovas >= need.supernovas)
		if ok then tier = t end
	end
	return tier
end

-- the star system above an island: ~22 above the floor; a rock until the player owns a star (or has gone Supernova), then a
-- star 4 -> 8 across by tier; one planet per body tier owned (max 6) on orbits of radius 6 -> 14, planets 1.5 -> 3
MapConfig.System = {
	Height = 22, StarMin = 4, StarMax = 8, Rock = 4,
	OrbitMin = 6, OrbitMax = 14, PlanetMin = 1.5, PlanetMax = 3,
	Belt = 16.5, BeltRock = { 0.8, 1.5 }, MaxBelt = 20,
	MaxPlanets = 6, StarTierFrom = 5,
	Plate = { Above = 10, Width = 26, Height = 4.6 }, -- name letters ~2.5
}
function MapConfig.SystemOf(bodyTiers: number, supernovas: number)
	local star = bodyTiers >= MapConfig.System.StarTierFrom or supernovas >= 1
	return { star = star, planets = math.clamp(bodyTiers, 0, MapConfig.System.MaxPlanets) }
end

-- the locked next sector, across the void (BACK-LEFT), its 10-wide bridge lit one segment at a time as the Ignition
-- checklist fills
MapConfig.NextSector = {
	Name = "SECTOR 2: COMET REACH",
	Angle = 180, Distance = 160, Height = 12, Radius = 30,
	BridgeWidth = 10, BridgeSegments = 18, LitAtStart = 3, Arch = 8,
	Crystals = { 5, 10 }, Padlock = 6,
}
do
	local NS = MapConfig.NextSector
	local a = math.rad(NS.Angle)
	NS.Position = Vector3.new(math.cos(a) * NS.Distance, NS.Height, math.sin(a) * NS.Distance)
end
-- (numbers to confirm with the design: the Ignition gate of Sector 1)
MapConfig.Ignition = {
	{ attribute = "Supernovas", need = 5, text = "Go Supernova 5 times" },
	{ attribute = "BestRunStardust", need = 1e12, text = "Earn 1T stardust in one run" },
	{ attribute = "Tree_CometLure", need = 1, text = "Unlock Comet Lure in the tree" },
	{ attribute = "Shards", need = 250, text = "Hold 250 shards" },
}
function MapConfig.IgnitionDone(player: Player): (number, number)
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
	-- (owner, pass 3: stone #E8DCC8, brass #C9902E; Stone2 = the floor tiles' second tone; Rock = the cones under the islands)
	Stone = Color3.fromRGB(232, 220, 200), Stone2 = Color3.fromRGB(204, 188, 162), Rock = Color3.fromRGB(128, 104, 150),
	BareRock = Color3.fromRGB(150, 142, 150), Brass = Color3.fromRGB(201, 144, 46), Lamp = Color3.fromRGB(255, 196, 110),
	Crystal = Color3.fromRGB(150, 85, 255), Grass = Color3.fromRGB(90, 200, 140), Ice = Color3.fromRGB(130, 215, 255),
	Bridge = Color3.fromRGB(125, 100, 215), BridgeDim = Color3.fromRGB(70, 60, 105), Void = Color3.fromRGB(6, 2, 14),
	VoidGlow = Color3.fromRGB(150, 80, 255), Core = Color3.fromRGB(235, 158, 70), Spike = Color3.fromRGB(205, 96, 34),
	Steel = Color3.fromRGB(82, 88, 118), ForgeRim = Color3.fromRGB(80, 180, 255), Lock = Color3.fromRGB(215, 215, 228),
	Orbit = Color3.fromRGB(176, 150, 230), Star = Color3.fromRGB(255, 190, 80), Mote = Color3.fromRGB(255, 225, 160),
	SignBack = Color3.fromRGB(26, 20, 34), Screen = Color3.fromRGB(12, 10, 18),
}
-- brass everywhere = gold with a small reflectance (owner: #C9902E, pass 3). (Material Metal was tried: against the dark sky
-- it mirrors the black and reads orange-brown, not gold.)
MapConfig.BrassMaterial = Enum.Material.SmoothPlastic
MapConfig.BrassReflectance = 0.06
MapConfig.PlanetColors = {
	Color3.fromRGB(150, 110, 240), Color3.fromRGB(80, 190, 255), Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 100, 120),
	Color3.fromRGB(255, 205, 80), Color3.fromRGB(200, 200, 215),
}

MapConfig.Sky = {
	-- (P&L Studios XP uploads, 2 Nov; Map\images\sky_*.png. Roblox's Lf is +X and Rt is -X. Up/Dn: the re-made v2 faces.)
	SkyboxFt = "rbxassetid://122365107824523", SkyboxBk = "rbxassetid://84969252246034", SkyboxLf = "rbxassetid://120684256007059",
	SkyboxRt = "rbxassetid://76670709549755", SkyboxUp = "rbxassetid://118744463737898", SkyboxDn = "rbxassetid://90521387144464",
}

MapConfig.LodDistance = 140      -- others' star systems simplified past this (star only)
MapConfig.VoidY = -110           -- below Origin.Y + this = fell off: back to your island
MapConfig.Comets = { From = 260, Through = 120, Low = 30, High = 80, Head = 4, Hit = 14, TutorialHit = 18 }

return MapConfig
