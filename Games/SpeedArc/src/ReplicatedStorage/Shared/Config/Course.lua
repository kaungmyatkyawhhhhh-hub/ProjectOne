-- Wall course (28 Oct pivot: "+1 SPEED every step"). Every step you run gives SPEED; one long
-- straight course per area ends each stage in a wall that needs some SPEED to smash through.
-- Smashing pays coins (minutes of coins at your league) and makes every later step in that league
-- worth more. Smashing the league's last wall = GO PRO ready. Races stay as an event.
return {
	StudsPerStep = 3, -- this much running on the ground = one step
	MaxStepsPerSecond = 12, -- anti-cheat: more than this a second is never counted
	StepGain = { 1, 40, 900, 20000, 500000 }, -- base SPEED per step by league (the x8 per league is on top, Boosts)
	WallBonus = 1.25, -- every wall you've smashed in your league: x1.25 SPEED per step (multiplies)
	-- SPEED each wall needs, per league (tools/step_pacing_sim.py --solve, prompt 11): a normal player
	-- smashes wall 1 ~35 s after PLAY, wall 2 ~2 min, wall 5 ~7 min, the last wall (Go Pro) at ~15 /
	-- 35 / 60 min in leagues 1 / 2 / 3. Ranks (Config/Ranks) sit on walls 4 / 6 / 8 / 10.
	Walls = {
		{ 310, 1600, 3200, 4700, 8600, 15000, 18000, 28000, 34000, 53000 },
		{ 410000, 1600000, 2800000, 4200000, 7700000, 11000000, 17000000, 26000000, 37000000, 55000000 },
		{ 130000000, 630000000, 1200000000, 2100000000, 3400000000, 5700000000, 9100000000, 13000000000, 20000000000, 30000000000 },
	},
	-- leagues 4-5 (no course yet): a share of the league's Champion SPEED
	WallShares = { 0.006, 0.03, 0.06, 0.09, 0.16, 0.28, 0.34, 0.53, 0.64, 1.0 },
	RewardMinutes = { 0.3, 0.4, 0.5, 0.6, 0.8, 1.0, 1.2, 1.5, 1.8, 2.5 }, -- coins for smashing wall k
	FirstSmashMult = 3, -- the first time ever you smash a wall it pays x3
	RepeatSmashMult = 0.05, -- smashing a wall again (a new run) pays 5%: walls never out-earn the races
	AfkStepsPerSecond = 1.6, -- steps a second on an AFK machine (running is ~3x this)
	AutoRunMult = 2.4, -- the Auto Run pass (Store key AutoTrain): machines step x2.4 (still slower than running)
	StageLength = 90, -- studs from one wall to the next (the first wall is one stage after the start)
	Width = 44,
	WallHeight = 18,
	BounceSpeed = 20, -- not enough SPEED: a soft bounce back (never a fling)
	Colors = { "#FF6FB5", "#FF8A3D", "#FFD23F", "#7ED957", "#3DDC97", "#4DB8FF", "#6C8CFF", "#9B5DE5", "#FF5DA2", "#FFC83D" },
	-- each area's course: Start = the start line (centre, ground level), Dir = the way it runs
	Areas = {
		Hub = { Start = Vector3.new(0, 0, 196), Dir = Vector3.new(0, 0, 1) },
		Park = { Start = Vector3.new(2000, 0, 165), Dir = Vector3.new(0, 0, 1) }, -- south of the spawn plaza
		Stadium = { Start = Vector3.new(4000, 0, 192), Dir = Vector3.new(0, 0, 1) }, -- out of the players' tunnel
	},
}
