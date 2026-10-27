-- Shoes (GDD 11). Pairs 1-6 at launch; 7-9 arrive with leagues 4-5.
-- Unlock = { League = n, Rank = "Silver" } (rank inside that league; league reached counts forever).
-- Colors: sole, upper, accent (palette) for the mesh / part shoe on the feet.
return {
	Default = "WornSneakers",
	List = {
		{ Id = "WornSneakers", Name = "Worn Sneakers", Train = 1.0, Pace = 0.00, Price = 0, Unlock = { League = 1 },
			Colors = { "#D9DEE6", "#8A93A3", "#5E6878" } },
		{ Id = "CanvasRunners", Name = "Canvas Runners", Train = 1.3, Pace = 0.01, Price = 250, Unlock = { League = 1 },
			Colors = { "#F4F6FA", "#1E7BFF", "#F4F6FA" } },
		{ Id = "TrackTrainers", Name = "Track Trainers", Train = 1.7, Pace = 0.01, Price = 1500, Unlock = { League = 1, Rank = "Silver" },
			Colors = { "#F4F6FA", "#171A22", "#4FC3FF" } },
		{ Id = "LightRacers", Name = "Light Racers", Train = 2.3, Pace = 0.02, Price = 8000, Unlock = { League = 1, Rank = "Gold" },
			Colors = { "#FFC83D", "#F4F6FA", "#1E7BFF" } },
		{ Id = "ParkPacers", Name = "Park Pacers", Train = 3.2, Pace = 0.02, Price = 60000, Unlock = { League = 2 },
			Colors = { "#F4F6FA", "#3FA34D", "#FFC83D" } },
		{ Id = "SpikeShoes", Name = "Spike Shoes", Train = 4.5, Pace = 0.03, Price = 400000, Unlock = { League = 3 },
			Colors = { "#0B0D12", "#0E3A8A", "#FFC83D" } },
	},
}
