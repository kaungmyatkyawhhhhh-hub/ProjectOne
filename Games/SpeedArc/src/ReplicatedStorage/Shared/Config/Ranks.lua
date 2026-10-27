-- Ranks inside each league (GDD 9.1): SPEED thresholds. Prompt 3 adds rank-up rewards and Go Pro.
return {
	Names = { "Bronze", "Silver", "Gold", "Platinum", "Champion" },
	Colors = {
		Bronze = Color3.fromHex("#C98A5A"),
		Silver = Color3.fromHex("#C9D1DD"),
		Gold = Color3.fromHex("#FFC83D"),
		Platinum = Color3.fromHex("#4FC3FF"),
		Champion = Color3.fromHex("#F4F6FA"),
	},
	-- [league] = { Bronze, Silver, Gold, Platinum, Champion } minimum MPH
	Thresholds = {
		{ 0, 100, 400, 1000, 2000 },
		{ 0, 10000, 40000, 100000, 200000 },
		{ 0, 500000, 2000000, 5000000, 10000000 },
		{ 0, 25000000, 100000000, 250000000, 500000000 },
		{ 0, 1000000000, 4000000000, 10000000000, 20000000000 },
	},
}
