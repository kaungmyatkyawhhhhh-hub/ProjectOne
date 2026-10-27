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
	-- Leagues 1-3 tuned by the pacing sim (prompt 3): ~15 / 35 / 60 min each. 4-5 are placeholders
	-- (scaled like league 3) until their update prompts tune them.
	Thresholds = {
		{ 0, 1500, 5000, 14000, 28000 },
		{ 0, 3000000, 12000000, 30000000, 60000000 },
		{ 0, 1750000000, 7000000000, 17500000000, 35000000000 },
		{ 0, 1e12, 4e12, 1e13, 2e13 },
		{ 0, 5e14, 2e15, 5e15, 1e16 },
	},
}
