-- Races (GDD sections 6.4 and 8).
return {
	IntervalSeconds = 180, -- a race every 3 minutes
	JoinSeconds = 10, -- gold JOIN button window (prompt 1 says 10 s; GDD 8.1 says 15 s)
	CountdownSeconds = 3,
	ResultsSeconds = 6,
	MaxRaceSeconds = 40, -- unfinished runners are placed by distance after this
	FirstRaceDelay = 45, -- first race after a server starts

	MaxRunners = 8,
	MinRunners = 4, -- NPC runners fill up to this
	NpcSpeedRange = { 0.7, 1.15 }, -- NPC speed = middle of joined players' speed x this
	NpcMinSpeed = 12,
	NpcNames = { "Dash", "Milo", "Zara", "Kofi", "Rina", "Theo", "Ivy", "Bo" },

	-- Pace (GDD 6.4): basePace x (1 + 0.6 x clamp(log2(speed / leagueMid), -1, 1.5))
	-- Tuned in prompt 1: at the League 1 middle (80 MPH) a Sprint takes ~17 s and a Lap Race ~33 s.
	-- Low clamp is -0.6 (GDD says -1) so brand-new runners aren't painfully slow in their first race.
	BasePace = 24, -- studs a second at the league middle
	LeagueMid = { 80, 3000, 150000, 8000000, 400000000 },
	PaceFactor = 0.6,
	PaceClampLow = -0.6,
	PaceClampHigh = 1.5,

	-- Boost: tap = +25% pace for 0.8 s, 3 charges, 1 charge back every 2.5 s
	Boost = {
		Mult = 0.25,
		Seconds = 0.8,
		Charges = 3,
		RefillSeconds = 2.5,
		MaxTapsPerSecond = 8,
	},
	Slipstream = { Distance = 6, Mult = 0.05 },
	FinalStretch = 0.8, -- last 20%

	-- Rewards in minutes of coins at your league (GDD 8.3)
	RewardMinutes = { 6, 4, 3 },
	FinishMinutes = 1.5,
	FirstRaceOfDayBonus = 0.5,

	Types = {
		Lap = { Name = "LAP RACE", Laps = 2 }, -- about 33 s at the league middle
		Sprint = { Name = "SPRINT", Laps = 1 }, -- about 17 s
	},
	Rotation = { "Lap", "Sprint" },

	-- School Track geometry (studs). Straights run along X; the home straight is on +Z.
	Track = {
		Center = Vector3.new(0, 0, 0),
		Straight = 100,
		InnerRadius = 30,
		LaneWidth = 4,
		Lanes = 6,
		StartX = 20, -- the gold start/finish line on the home straight
		SurfaceY = 0.4, -- top of the track surface
		HipY = 3.05, -- root part height above the surface
	},

	TickRate = 10, -- position updates a second
	RunAnimation = "rbxassetid://913376220",
}
