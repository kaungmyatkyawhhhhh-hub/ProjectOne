-- M4: the reasons to stay and come back (GDD 14, 15, 17, 18, 21, 26). Every number lives here.
-- Coin rewards are "minutes of coins at your league" (GDD 19) unless they say Coins.
return {
	-- Tutorial (GDD 21). Steps run in this order; a step's hint comes back every HintRepeat seconds
	-- until it's done, and its safety timeout only counts while the step is possible.
	Tutorial = {
		HintRepeat = 12,
		FirstTapCoins = 100,
		FirstTapSpeed = 10, -- "+10 MPH burst"
		ComboHintSeconds = 20, -- the combo hint shows until x1.2 or this many seconds of tapping
		RaceAfterSeconds = 30, -- tutorial race offered this long after the combo hint
		RaceNpcSpeed = { 0.55, 0.75 }, -- x the player's speed (slow NPCs, a close win)
		RacePace = 1.45, -- the tutorial race runs faster than normal so it's short and exciting
		ShoeId = "CanvasRunners", -- coins topped up to its price for the first shoes
		SilverRoll = 1, -- free coach rolls at Silver rank
		-- safety per step (seconds, counted only while the step is possible): first the game does the
		-- GO TO for the player, after twice this the step is skipped so nobody is ever stuck
		StepTimeouts = { [1] = 6, [2] = 30, [3] = 90, [4] = 55, [5] = 6, [6] = 75, [7] = 600, [8] = 75 }, -- 2 = first step, 3 = first wall
	},
	NewRunnerBoost = { Mult = 2, Seconds = 15 * 60 }, -- 2x training for 15 min of play

	-- Daily streak (GDD 15): one missed day allowed (lesson: UTC days change in the US afternoon)
	Daily = {
		GraceDays = 1,
		Days = {
			{ Minutes = 2 },
			{ Minutes = 3 },
			{ Minutes = 4 },
			{ Minutes = 4, Rolls = 1 },
			{ Minutes = 5 },
			{ Minutes = 6 },
			{ Minutes = 8, Trail = "Sunrise" }, -- the trail only the first time; later day 7s give Rolls
		},
		Day7RepeatRolls = 2,
	},

	-- Daily quests: 3 a day from this pool, 3 min each, all 3 = 10 min + a coach roll
	Quests = {
		PerDay = 3,
		RewardMinutes = 3,
		AllBonusMinutes = 10,
		AllBonusRolls = 1,
		Pool = {
			{ Id = "Win1", Text = "Win 1 race", Stat = "Wins", Goal = 1 },
			{ Id = "Race5", Text = "Race 5 times", Stat = "Races", Goal = 5 },
			{ Id = "Race3", Text = "Race 3 times", Stat = "Races", Goal = 3 },
			{ Id = "Taps300", Text = "Take 500 steps", Stat = "Steps", Goal = 500 }, -- ids kept from the tap days (old saves)
			{ Id = "Taps800", Text = "Take 1,500 steps", Stat = "Steps", Goal = 1500 },
			{ Id = "PB1", Text = "Get a new personal best", Stat = "PBs", Goal = 1 },
			{ Id = "Podium2", Text = "Finish top 3 twice", Stat = "Podiums", Goal = 2 },
			{ Id = "Boost15", Text = "Use BOOST 15 times", Stat = "Boosts", Goal = 15 },
			{ Id = "Roll1", Text = "Roll a coach", Stat = "Rolls", Goal = 1 },
		},
	},

	-- Playtime gifts: minutes of play today -> reward. Pays by itself, the popup names the next one.
	Gifts = {
		{ At = 3, Minutes = 1 },
		{ At = 8, Minutes = 2 },
		{ At = 15, TrainBoost = 5 * 60 }, -- 2x SPEED per step for 5 min of play
		{ At = 25, Minutes = 4 },
		{ At = 40, Minutes = 6 },
		{ At = 60, Rolls = 1 },
	},
	GiftBoostMult = 2, -- doesn't stack with the New Runner boost (the bigger one counts)

	-- Codes (case doesn't matter). More can be added live in the DataStore without publishing.
	Codes = {
		Store = "SpeedArcCodes_v1",
		RefreshSeconds = 60,
		Launch = {
			SPEEDARC = { Minutes = 5 },
			FIRSTRACE = { Rolls = 1 },
			RELEASE = { Minutes = 10, Rolls = 1 },
		},
	},

	-- Leaderboards (GDD 17). Versioned names: change Version to reset every board.
	Leaderboards = {
		Version = 1,
		Prefix = "SpeedArcLB",
		StudioPrefix = "SpeedArcLBStudio", -- Studio tests never touch the live boards
		WriteSeconds = 60,
		ReadSeconds = 60,
		Top = 25,
		WeeklyTopRewards = { { Title = "WEEKLY CHAMPION", Minutes = 30 }, { Title = "WEEKLY RUNNER-UP", Minutes = 20 }, { Title = "WEEKLY THIRD", Minutes = 10 } },
	},

	-- Titles (GDD 14): earned -> can be picked in the profile; the newest one is worn by default
	Titles = {
		Order = { "FIRST RACE", "FIRST WIN", "10 WINS", "100 WINS", "1000 WINS", "PARK RUNNER", "STADIUM STAR", "HOMETOWN CHAMPION", "PARK CHAMPION", "STADIUM CHAMPION", "PB HUNTER", "WEEKLY THIRD", "WEEKLY RUNNER-UP", "WEEKLY CHAMPION" },
		Wins = { [1] = "FIRST WIN", [10] = "10 WINS", [100] = "100 WINS", [1000] = "1000 WINS" },
		Champion = { [1] = "HOMETOWN CHAMPION", [2] = "PARK CHAMPION", [3] = "STADIUM CHAMPION" },
		PBs = 10, -- "PB HUNTER" after this many personal bests
	},

	-- Social (GDD 18)
	Social = {
		FriendBoostEach = 0.10,
		FriendBoostMax = 0.30,
		InviteBoost = 0.10,
		InviteBoostSeconds = 30 * 60,
		ChallengePaidPerDay = 3, -- RACE THEM pays coins only for the first 3 a day
		ChallengeMinutes = { 3, 1.5 }, -- 1st, 2nd
		ChallengeAskSeconds = 15,
	},

	-- Analytics funnel (GDD 26), in order; each fires once per player
	Funnel = { "loaded", "menu_play", "first_tap", "first_race_joined", "first_race_finished", "first_shoes", "first_coach_roll", "silver", "gold", "go_pro_1", "day2_return", "go_pro_2" },

	-- Studio: a fake clock for testing days (Workspace attribute TestDayOffset = days to add)
}
