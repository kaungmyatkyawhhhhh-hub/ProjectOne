-- AFK step machines per league (28 Oct pivot: no more tapping). Stand on one and it steps for you:
-- Course.AfkStepsPerSecond steps a second, each worth one running step x Mult (Config/Course + Boosts).
-- Running the course is faster; machines are for AFK and phones. The Auto Run pass steps x3 faster.
-- Order matters inside a league: the next locked one is shown when you reach it.
-- (Sprint Lane and Stair Run were tap stations; they left the hub with the pivot.)
return {
	-- League 1 Hometown (hub)
	{ Id = "Treadmill", Name = "Treadmill", League = 1, Mult = 1, MinSpeed = 0, AnimSpeed = 1.15 },
	-- League 2 City Park Run
	{ Id = "ParkLoop", Name = "Park Loop", League = 2, Mult = 1, MinSpeed = 0, AnimSpeed = 1.1 },
	{ Id = "HillSprint", Name = "Hill Sprint", League = 2, Mult = 1.4, MinSpeed = 1250000, AnimSpeed = 1.25 },
	{ Id = "BenchStepUps", Name = "Bench Step-Ups", League = 2, Mult = 1.8, MinSpeed = 4000000, AnimSpeed = 1.2 },
	{ Id = "BikeDrafting", Name = "Bike Drafting", League = 2, Mult = 2.4, MinSpeed = 12000000, AnimSpeed = 1.4 },
	-- League 3 Big Stadium
	{ Id = "BlockStarts", Name = "Block Starts", League = 3, Mult = 1, MinSpeed = 0, AnimSpeed = 1.2 },
	{ Id = "HurdlesRow", Name = "Hurdles", League = 3, Mult = 1.4, MinSpeed = 550000000, AnimSpeed = 1.3 },
	{ Id = "ParachuteRun", Name = "Parachute Run", League = 3, Mult = 1.8, MinSpeed = 1800000000, AnimSpeed = 1.35 },
	{ Id = "BungeeSprint", Name = "Bungee Sprint", League = 3, Mult = 2.4, MinSpeed = 5500000000, AnimSpeed = 1.5 },
}
