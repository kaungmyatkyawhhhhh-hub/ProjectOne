-- Wall course (28 Oct pivot: "+1 SPEED every step"). Every step you run gives SPEED; one long
-- straight course per area ends each stage in a wall that needs some SPEED to smash through.
-- Smashing pays coins (minutes of coins at your league) and makes every later step in that league
-- worth more. Smashing the league's last wall = GO PRO ready. Races stay as an event.
return {
	StudsPerStep = 3.5, -- this much running on the ground = one step
	MaxStepsPerSecond = 12, -- anti-cheat: more than this a second is never counted
	StepGain = { 1, 40, 900, 20000, 500000 }, -- base SPEED per step by league (the x8 per league is on top, Boosts)
	WallBonus = 1.25, -- every wall you've smashed in your league: x1.25 SPEED per step (multiplies)
	-- the walls of a league as a share of that league's Champion SPEED (Config/Ranks); the last one = Go Pro
	WallShares = { 0.0015, 0.006, 0.017, 0.043, 0.086, 0.17, 0.31, 0.5, 0.71, 1.0 },
	RewardMinutes = { 0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.2, 1.5, 1.8, 2.5 }, -- coins for smashing wall k
	FirstSmashMult = 3, -- the first time ever you smash a wall it pays x3
	AfkStepsPerSecond = 2, -- steps a second on an AFK machine (Config/Stations)
	AutoRunMult = 3, -- the Auto Run pass (Store key AutoTrain): machines step x3 faster
	StageLength = 90, -- studs from one wall to the next (the first wall is one stage after the start)
	Width = 44,
	WallHeight = 18,
	BounceSpeed = 45, -- not enough SPEED: you bounce back this fast
	Colors = { "#FF6FB5", "#FF8A3D", "#FFD23F", "#7ED957", "#3DDC97", "#4DB8FF", "#6C8CFF", "#9B5DE5", "#FF5DA2", "#FFC83D" },
	-- each area's course: Start = the start line (centre, ground level), Dir = the way it runs
	Areas = {
		Hub = { Start = Vector3.new(0, 0, 196), Dir = Vector3.new(0, 0, 1) },
	},
}
