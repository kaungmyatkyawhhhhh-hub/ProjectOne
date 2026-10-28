-- What a new player's save looks like. New fields added here are filled into old saves automatically.
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

return {
	Version = GameConfig.Data.Version,
	Speed = GameConfig.Speed.StartSpeed,
	Coins = 0,
	League = 1,
	Medals = { Gold = 0, Silver = 0, Bronze = 0 },
	Stats = {
		Taps = 0,
		Steps = 0, -- 28 Oct pivot: steps run (and AFK machine steps)
		Races = 0,
		Wins = 0,
		PlaySeconds = 0,
		PBs = 0, -- M4 (quests / titles)
		Podiums = 0,
		Boosts = 0,
		Challenges = 0,
	},
	BestTimes = {}, -- [raceType] = seconds
	LastRaceDay = 0, -- day number of the last race (first race of the day bonus)
	BestLeague = 1, -- highest league ever reached (unlocks never go away after Go Pro)

	-- M2: collecting
	Shoe = "WornSneakers",
	OwnedShoes = { WornSneakers = true },
	Trail = "Dust",
	OwnedTrails = { Dust = true },
	Coaches = {}, -- list of { Uid = n, Id = "Benji", Stage = 1 }
	EquippedCoaches = {}, -- list of Uids (slot order)
	NextCoachUid = 1,
	CoachRolls = 0,
	Pity = {}, -- [rarity] = rolls since last coach of at least that rarity
	SeenCutscenes = {}, -- [coachId] = true (SKIP shows after the first time)
	Passes = {}, -- [passName] = true (M5)

	-- M3: leagues
	Rank = 1, -- rank index inside the current league (1 Bronze .. 5 Champion)
	BestRank = {}, -- [league] = best rank index reached there (unlocks keep after Go Pro)
	LeagueWins = 0, -- race wins in your own league since your last Go Pro
	Titles = {}, -- [title] = true
	FreeRolls = 0, -- free coach rolls (Go Pro gives one)
	SeenGoPro = {}, -- [league] = true (SKIP on the cutscene after the first time)
	FirstJoin = 0,
	LastJoin = 0,

	-- M4: first 15 minutes, daily, quests, social
	Tutorial = 0, -- step (Retention.Tutorial steps); 99 = done
	Funnel = {}, -- [step] = true (analytics steps fire once)
	Boost = { NewRunner = 0, Gift = 0, Invite = 0, Speed = 0 }, -- seconds of play left (Speed = 2x SPEED product)
	Daily = { LastClaimDay = 0, Streak = 0, GotTrail = false },
	Quests = { Day = 0, List = {}, BonusClaimed = false }, -- List = { { Id, Base, Claimed } }
	Gifts = { Day = 0, Seconds = 0, Next = 1 },
	Codes = {}, -- [CODE] = true
	Title = "", -- worn title ("" = newest earned)
	TopSpeed = {}, -- [league] = best SPEED reached there
	Challenge = { Day = 0, Paid = 0 },
	Weekly = { Week = 0, Wins = 0, Best = 0 }, -- Best = fastest Hometown Sprint this week (s)
	Prompted = {}, -- [Favourite / Notify] = true

	-- M5: store + locker cosmetics
	Receipts = {}, -- [purchaseId] = os.time() (never grant a product twice)
	Purchases = {}, -- [productKey] = count
	OwnedKits = {}, -- [kitId] = true
	Kit = { Top = "", Bottom = "" },
	OwnedHead = {},
	Head = "",
	Bib = { Number = 0, Color = "Blue", On = false },
	OwnedNameStyles = {},
	NameStyle = "",
	ShoeSkins = {}, -- [skinId] = true
	ShoeSkin = {}, -- [shoeId] = skinId worn
	AutoTrain = false,

	-- 28 Oct pivot: the wall course
	Walls = {}, -- [league] = best wall smashed there

	-- M6
	Settings = { Music = 0.8, Sounds = 0.8, Low = "Auto", Reduced = false },
}
