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
		Races = 0,
		Wins = 0,
		PlaySeconds = 0,
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
}
