-- Training stations, League 1 School Track (GDD 7.2: base gain per tap / minimum MPH).
-- Order matters: the next locked one is the goal shown on the HUD.
return {
	{
		Id = "SprintLane",
		Name = "Sprint Lane",
		Gain = 1,
		MinSpeed = 0,
		AnimSpeed = 1.0, -- run animation speed while tapping
	},
	{
		Id = "Treadmill",
		Name = "Treadmill",
		Gain = 3,
		MinSpeed = 40,
		AnimSpeed = 1.15,
	},
	{
		Id = "StairRun",
		Name = "Stair Run",
		Gain = 8,
		MinSpeed = 150,
		AnimSpeed = 1.25,
	},
}
