-- SPEED ARC main numbers (GDD sections 6, 19). Every number lives in Config.
return {
	League = 1, -- the league new players start in
	LeagueTrainMult = 8, -- Go Pro: x8 SPEED per step for every league (GDD 9.2)

	Speed = {
		StartSpeed = 0, -- SPEED a new runner starts with
	},

	-- Walking speed (GDD 6.3): 16 + 6 x log10(1 + SPEED / 10), capped
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
		StepShare = 0.2, -- steps give about 20% of coins
		AssumedStepsPerSecond = 5, -- used to turn that share into coins per step
		CoinMultCap = 8, -- all coin multipliers together never pass x8 (lesson)
	},

	Data = {
		StoreName = "SpeedArcData_v1",
		StudioStoreName = "SpeedArcData_Studio", -- Studio tests never touch the live save
		AutosaveSeconds = 60,
		LockExpireSeconds = 180,
		LockWaitSeconds = 60,
		LockRetrySeconds = 6,
		Version = 5,
	},
}
