--[[
	GymConfig
	All tuning numbers for the lifting progression loop live here,
	so balance can be changed without touching any logic.
]]

local Config = {}

-- Weight upgrades (bought with Cash). "mult" = Strength gained per rep.
Config.Weights = {
	{ name = "5 kg", mult = 1, cost = 0, plate = 1.4, color = Color3.fromRGB(150, 150, 160) },
	{ name = "10 kg", mult = 2, cost = 60, plate = 1.8, color = Color3.fromRGB(70, 160, 255) },
	{ name = "20 kg", mult = 4, cost = 300, plate = 2.2, color = Color3.fromRGB(80, 210, 110) },
	{ name = "40 kg", mult = 8, cost = 1500, plate = 2.6, color = Color3.fromRGB(255, 200, 40) },
	{ name = "80 kg", mult = 16, cost = 7500, plate = 3.0, color = Color3.fromRGB(255, 110, 40) },
	{ name = "160 kg", mult = 32, cost = 37500, plate = 3.4, color = Color3.fromRGB(190, 80, 255) },
}

-- Ranks unlocked by total Strength (never spent, so progress is never lost).
Config.Ranks = {
	{ name = "Twig", min = 0, color = Color3.fromRGB(200, 200, 200) },
	{ name = "Rookie", min = 100, color = Color3.fromRGB(120, 200, 255) },
	{ name = "Gym Rat", min = 600, color = Color3.fromRGB(110, 230, 120) },
	{ name = "Beast", min = 3000, color = Color3.fromRGB(255, 200, 40) },
	{ name = "Titan", min = 15000, color = Color3.fromRGB(255, 110, 40) },
	{ name = "Olympian", min = 75000, color = Color3.fromRGB(200, 110, 255) },
}

Config.Rep = {
	cooldown = 0.3, -- seconds between reps (server enforced)
	perfectMult = 2, -- a rep inside the green zone counts double
	comboStep = 0.1, -- each perfect in a row adds +10%...
	comboMax = 1.0, -- ...up to +100%
	needleSpeed = 0.9, -- needle sweeps per second at 5 kg
	needleSpeedPerTier = 0.15, -- heavier weights = faster needle = harder timing
	zoneWidth = 0.18, -- green zone size (0..1 of the bar)
	tapTolerance = 0.6, -- max seconds between the client's tap time and the server receiving it
}

-- Body growth driven by total Strength (R15 body scale values).
Config.Body = {
	strengthForMax = 75000,
	maxExtraWidth = 0.9,
	maxExtraDepth = 0.7,
	maxExtraHeight = 0.25,
}

Config.StationCount = 6
Config.DataStoreName = "GymProgress_v1"

return Config
