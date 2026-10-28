-- Areas (GDD 4): small separate places linked by teleports. Each has its own track, race schedule
-- (offset from the others), lighting preset, music and leaderboard. Model = workspace child name.
return {
	Order = { "Hub", "Park", "Stadium" },
	MaxLeague = 3, -- leagues 4-5 are "COMING SOON" gates for launch
	LowerLeagueRewardMult = 0.25, -- races in a lower league's area pay a quarter

	Hub = {
		Id = "Hub", Name = "HOMETOWN TRACK", League = 1, Model = "Hub",
		Spawn = Vector3.new(0, 3, 126), SpawnLook = Vector3.new(0, 3, 200), -- the spawn plaza, facing the wall course
		Lighting = "Hub", Music = "Hub", RaceOffset = 0,
		Track = { Center = Vector3.new(0, 0, 0), Straight = 100, InnerRadius = 30, LaneWidth = 4, Lanes = 6, StartX = 20, SurfaceY = 0.4, HipY = 3.05 },
		Types = { "Lap", "Sprint" },
	},
	Park = {
		Id = "Park", Name = "CITY PARK RUN", League = 2, Model = "Park",
		Spawn = Vector3.new(2000, 3, 132), SpawnLook = Vector3.new(2000, 3, 200), -- facing the wall course
		Lighting = "Park", Music = "Park", RaceOffset = 60,
		Track = { Center = Vector3.new(2000, 0, 0), Straight = 130, InnerRadius = 44, LaneWidth = 4, Lanes = 4, StartX = 25, SurfaceY = 0.4, HipY = 3.05 },
		Types = { "Lap", "Sprint" },
	},
	Stadium = {
		Id = "Stadium", Name = "BIG STADIUM", League = 3, Model = "Stadium",
		Spawn = Vector3.new(4000, 3, 150), SpawnLook = Vector3.new(4000, 3, 90), -- inside the players' tunnel
		Lighting = "Stadium", Music = "Stadium", RaceOffset = 120,
		Track = { Center = Vector3.new(4000, 0, 0), Straight = 100, InnerRadius = 34, LaneWidth = 4, Lanes = 8, StartX = 20, SurfaceY = 0.4, HipY = 3.05 },
		Types = { "Lap", "Sprint", "Hurdles" },
	},

	-- Go Pro (GDD 9.2)
	GoPro = {
		Titles = { [2] = "PARK RUNNER", [3] = "STADIUM STAR", [4] = "TRAIL LEGEND", [5] = "WORLD CHAMPION" },
		FreeRolls = 1,
	},
	-- Rank up rewards in minutes of coins at your league (Silver, Gold, Platinum, Champion)
	RankRewardMinutes = { 0, 1, 2, 3, 5 },
}
