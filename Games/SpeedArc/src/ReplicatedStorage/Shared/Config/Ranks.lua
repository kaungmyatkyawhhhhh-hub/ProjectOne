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
	-- Leagues 1-3 tuned by the pacing sim (prompts 3 + 4): ~15 / 35 / 60 min each, Silver at ~5 min. 4-5 are placeholders
	-- (scaled like league 3) until their update prompts tune them.
	Thresholds = {
		{ 0, 3800, 20000, 36000, 70000 },
		{ 0, 4000000, 16000000, 40000000, 80000000 },
		{ 0, 1800000000, 7500000000, 18000000000, 36000000000 },
		{ 0, 1e12, 4e12, 1e13, 2e13 },
		{ 0, 5e14, 2e15, 5e15, 1e16 },
	},
}
