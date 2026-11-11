-- MEGA BITE GameConfig: every tunable lives here (owner rule). Speeds in studs/s, turn in deg/s.
-- small = fast + twitchy (high turn, high agility); big = faster top speed, wide turns, more glide.
local C = {}

C.Evolutions = {
	{key = "Minnow",     name = "Minnow",      ability = "DART",        exp = 0,     size = 0.1,  cruise = 13, top = 24, turn = 240, agility = 11, grip = 7.0, accel = 7.0},
	{key = "Piranha",    name = "Piranha",     ability = "FRENZY",      exp = 25,    size = 0.3,  cruise = 14, top = 26, turn = 215, agility = 10, grip = 6.5, accel = 6.5},
	{key = "Barracuda",  name = "Barracuda",   ability = "TORPEDO",     exp = 200,   size = 1.2,  cruise = 17, top = 33, turn = 165, agility = 8,  grip = 5.5, accel = 6.0},
	{key = "ReefShark",  name = "Reef Shark",  ability = "SHARK SENSE", exp = 620,   size = 2.5,  cruise = 18, top = 34, turn = 135, agility = 6.5, grip = 4.5, accel = 5.0},
	{key = "Hammerhead", name = "Hammerhead",  ability = "HAMMER RAM",  exp = 2400,  size = 4.5,  cruise = 19, top = 36, turn = 115, agility = 5.5, grip = 4.0, accel = 4.5},
	{key = "GreatWhite", name = "Great White", ability = "BREACH",      exp = 10000, size = 6.0,  cruise = 20, top = 39, turn = 92,  agility = 4.5, grip = 3.4, accel = 4.0},
	{key = "Megalodon",  name = "Megalodon",   ability = "TIDAL ROAR",  exp = 40000, size = 18.0, cruise = 22, top = 42, turn = 70,  agility = 3.5, grip = 2.8, accel = 3.2},
}
C.AbilityColor = {DART = "Turquoise", FRENZY = "Coral", TORPEDO = "Blue", ["SHARK SENSE"] = "Kelp", ["HAMMER RAM"] = "Gold", BREACH = "Foam", ["TIDAL ROAR"] = "Cyan"}

C.Swim = {
	StopDecel = 0.85,         -- 1/s: let go = keep gliding a bit, then stop (owner 10 Nov: "u still move by abit"); ~3-4 s, ~25 studs at top speed
	BrakeDecel = 6,           -- 1/s: back (S / stick down) = brake hard, no turning (owner 10 Nov)
	BackDot = -0.35,          -- S counts as BRAKE only when 'toward the camera' points behind the shark (dot with heading below this)
	ReverseFrac = 0.4, ReverseAccel = 2.5,   -- after you've stopped, holding back = swim backwards at 0.4 x cruise (owner 10 Nov)
	DartMult = 2.3, DartTime = 0.4, DartCooldown = 2.2, DartInvuln = 0.45,
	PitchMax = 62,            -- deg
	PitchTurnFrac = 0.75,     -- pitch rate = turn * this
	BankMax = 38,             -- deg of roll at full turn
	BendMax = 0.55,           -- rad of spine bend at full turn
	BendSign = 1,
	Restitution = 0.35, BonkSpeed = 12,
	FloorClear = 0.6,         -- studs above the sea floor (plus half body height)
	Ceiling = 78,             -- y; the surface light cover
	MapCentre = Vector3.new(0, 0, 0),
	BorderSoft = 345, BorderHard = 400, BorderPush = 34,
	SwimAnimSpeed = 3,        -- above this speed the Swim clip plays
}

C.Camera = {
	DistBase = 8, DistPerStud = 1.0, Height = 0.15,   -- distance = (DistBase + DistPerStud * bodyLength) * zoom; aim at the body (owner 10 Nov)
	ZoomInTail = 0.12, ZoomInGap = 6, ZoomMax = 1.7,   -- closest zoom = right over the shark's back (0.12 x body length + 6 studs; Megalodon ~11), owner 10 Nov
	YawLag = 3.2,              -- 1/s: how fast the chase camera swings behind the heading
	RecenterDelay = 1.1,       -- s after the last manual drag
	PitchDefault = -12, PitchMin = -70, PitchMax = 55,  -- deg; default looks slightly down
	PitchReturn = 0.5,         -- 1/s return to default when idle
	PosLag = 14,               -- 1/s camera position smoothing
	Fov = 70, DartFov = 82,
	TouchSens = 0.32, MouseSens = 0.28, PadSens = 170,
}

C.Zones = {SafeReefRadius = 300}
C.Map = {
	Spawn = Vector3.new(0, 14, -24),
	Vents = {Vector3.new(46, 14, -57)},
}
C.Server = {SpeedSlack = 1.4, CheckEvery = 0.5, SpeedExtra = 8}
C.Quests = {
	{id = "vent", text = "Swim to the BANK VENT", target = "vent", radius = 26, reward = 3},
}
C.StudsPerMetre = 3.5
return C
