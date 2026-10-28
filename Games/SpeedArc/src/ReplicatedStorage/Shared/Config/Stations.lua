-- Training stations per league (GDD 7.2: base gain per tap / minimum MPH). The league multiplier
-- (x8 per Go Pro) is applied on top, so station 1 of a new league feels fast again.
-- Order matters inside a league: the next locked one is the goal shown on the HUD.
-- Gains are the GDD numbers; MinSpeed was scaled in prompt 3 by the pacing sim (tools/pacing_sim.py)
-- so a normal player takes ~15 / 35 / 60 minutes in leagues 1 / 2 / 3 (re-tuned in prompt 4 with the
-- New Runner boost, gifts, daily and quests).
return {
	-- League 1 School Track (hub)
	{ Id = "SprintLane", Name = "Sprint Lane", League = 1, Gain = 1, MinSpeed = 0, AnimSpeed = 1.0 },
	{ Id = "Treadmill", Name = "Treadmill", League = 1, Gain = 3, MinSpeed = 1400, AnimSpeed = 1.15 },
	{ Id = "StairRun", Name = "Stair Run", League = 1, Gain = 8, MinSpeed = 5000, AnimSpeed = 1.25 },
	-- League 2 City Park Run
	{ Id = "ParkLoop", Name = "Park Loop", League = 2, Gain = 40, MinSpeed = 0, AnimSpeed = 1.1 },
	{ Id = "HillSprint", Name = "Hill Sprint", League = 2, Gain = 90, MinSpeed = 1250000, AnimSpeed = 1.25 },
	{ Id = "BenchStepUps", Name = "Bench Step-Ups", League = 2, Gain = 200, MinSpeed = 4000000, AnimSpeed = 1.2 },
	{ Id = "BikeDrafting", Name = "Bike Drafting", League = 2, Gain = 450, MinSpeed = 12000000, AnimSpeed = 1.4 },
	-- League 3 Big Stadium
	{ Id = "BlockStarts", Name = "Block Starts", League = 3, Gain = 900, MinSpeed = 0, AnimSpeed = 1.2 },
	{ Id = "HurdlesRow", Name = "Hurdles", League = 3, Gain = 2000, MinSpeed = 550000000, AnimSpeed = 1.3 },
	{ Id = "ParachuteRun", Name = "Parachute Run", League = 3, Gain = 4500, MinSpeed = 1800000000, AnimSpeed = 1.35 },
	{ Id = "BungeeSprint", Name = "Bungee Sprint", League = 3, Gain = 10000, MinSpeed = 5500000000, AnimSpeed = 1.5 },
}
