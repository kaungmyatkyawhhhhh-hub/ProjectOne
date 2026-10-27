-- SPEED ARC main numbers (GDD sections 6, 19). Every number lives in Config.
return {
	League = 1, -- the league new players start in
	LeagueTrainMult = 8, -- Go Pro: x8 training gains per league (GDD 9.2)

	Speed = {
		StartSpeed = 0, -- MPH a new runner starts with
		MaxTapsPerSecond = 12, -- server counts at most this many taps a second (anti-cheat)
	},

	-- Combo (GDD 6.2): steady tapping (>= 3 taps a second, no gap > 0.6 s) builds x1.0 -> x1.5 over 10 s
	Combo = {
		MinTapsPerSecond = 3,
		MaxGap = 0.6,
		BuildSeconds = 10,
		Max = 1.5,
		Steps = { 1.1, 1.2, 1.3, 1.4, 1.5 }, -- a sound plays at each step
	},

	-- Walking speed in the hub (GDD 6.3): 16 + 6 x log10(1 + MPH / 10), capped
	Walk = {
		Base = 16,
		Factor = 6,
		Divider = 10,
		Cap = 30,
		FovMin = 70,
		FovMax = 80,
	},

	-- Economy (GDD 19). Rewards are "minutes of coins at your league".
	Economy = {
		CoinsPerMinute = { 60, 400, 3000, 25000, 200000 }, -- by league
		TrainingShare = 0.2, -- training taps give about 20% of coins
		AssumedTapsPerSecond = 5, -- used to turn the training share into coins per tap
		CoinMultCap = 8, -- all coin multipliers together never pass x8 (lesson)
	},

	Data = {
		StoreName = "SpeedArcData_v1",
		StudioStoreName = "SpeedArcData_Studio", -- Studio tests never touch the live save
		AutosaveSeconds = 60,
		LockExpireSeconds = 180,
		LockWaitSeconds = 60,
		LockRetrySeconds = 6,
		Version = 4,
	},
}
