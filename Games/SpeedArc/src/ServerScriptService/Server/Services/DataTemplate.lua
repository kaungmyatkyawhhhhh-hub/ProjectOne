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
	FirstJoin = 0,
	LastJoin = 0,
}
