-- Every sound in the game (Audio note rules). Roblox Creator Store / licensed library audio only.
-- Ids = one or more clips (never the same clip twice in a row). Pitch = random range. Layers = other keys played together.
-- Group: SFX, UI, Crowd, Music, Voice. Pool = how many copies can play at once.
return {
	Groups = { SFX = 0.8, UI = 0.6, Crowd = 0.55, Music = 0.4, Voice = 0.8 },

	Sounds = {
		-- Training
		Step = { Ids = { "rbxassetid://87061775498714", "rbxassetid://140594308250996" }, Volume = 0.55, Pitch = { 0.95, 1.05 }, Group = "SFX", Pool = 6 },
		TapAir = { Ids = { "rbxassetid://9120704978" }, Volume = 0.12, Pitch = { 1.15, 1.3 }, Group = "SFX", Pool = 4 },
		Tap = { Layers = { "Step", "TapAir" } },
		ComboUp = { Ids = { "rbxassetid://9125648149" }, Volume = 0.3, Pitch = { 1.0, 1.04 }, Group = "SFX", Pool = 2 },
		ComboMax = { Ids = { "rbxassetid://132574644259001" }, Volume = 0.35, Pitch = { 1.1, 1.14 }, Group = "SFX", Pool = 1 },
		ComboBreak = { Ids = { "rbxassetid://9120914426" }, Volume = 0.25, Pitch = { 0.7, 0.75 }, Group = "SFX", Pool = 1 },
		StationEnter = { Ids = { "rbxassetid://9114215780" }, Volume = 0.5, Pitch = { 1.0, 1.05 }, Group = "UI", Pool = 1, Layers = { "TapAir" } },
		StationLeave = { Ids = { "rbxassetid://9114215780" }, Volume = 0.4, Pitch = { 0.85, 0.9 }, Group = "UI", Pool = 1 },
		Unlock = { Ids = { "rbxassetid://132574644259001" }, Volume = 0.6, Pitch = { 1.0, 1.0 }, Group = "SFX", Pool = 1, Layers = { "CrowdOoh" } },
		Denied = { Ids = { "rbxassetid://9114215780" }, Volume = 0.45, Pitch = { 0.6, 0.62 }, Group = "UI", Pool = 1 },

		-- Races
		Join = { Ids = { "rbxassetid://9114215780" }, Volume = 0.6, Pitch = { 1.15, 1.2 }, Group = "UI", Pool = 1, Layers = { "CrowdMurmur" } },
		CrowdMurmur = { Ids = { "rbxassetid://9120974378" }, Volume = 0.2, Pitch = { 0.95, 1.0 }, Group = "Crowd", Pool = 1 },
		CrowdOoh = { Ids = { "rbxassetid://9120974378" }, Volume = 0.15, Pitch = { 1.05, 1.1 }, Group = "Crowd", Pool = 1 },
		Beep = { Ids = { "rbxassetid://91072655090313" }, Volume = 0.45, Pitch = { 1.0, 1.0 }, Group = "SFX", Pool = 2 },
		StartGun = { Ids = { "rbxassetid://4944424481" }, Volume = 0.7, Pitch = { 0.98, 1.02 }, Group = "SFX", Pool = 1, Layers = { "CrowdCheer" } },
		CrowdCheer = { Ids = { "rbxassetid://9120975204" }, Volume = 0.35, Pitch = { 0.97, 1.03 }, Group = "Crowd", Pool = 2 },
		CrowdBurst = { Ids = { "rbxassetid://9120975307" }, Volume = 0.25, Pitch = { 1.0, 1.06 }, Group = "Crowd", Pool = 2 },
		Boost = { Ids = { "rbxassetid://9126229255" }, Volume = 0.55, Pitch = { 0.95, 1.05 }, Group = "SFX", Pool = 3 },
		BoostEmpty = { Ids = { "rbxassetid://9114215780" }, Volume = 0.35, Pitch = { 0.7, 0.72 }, Group = "UI", Pool = 1 },
		FinalStretch = { Ids = { "rbxassetid://9120975204" }, Volume = 0.5, Pitch = { 1.05, 1.08 }, Group = "Crowd", Pool = 1 },
		Fanfare = { Ids = { "rbxassetid://1841800152" }, Volume = 0.5, Pitch = { 1.0, 1.0 }, Group = "Music", Pool = 1 },
		FinishCheer = { Ids = { "rbxassetid://9120975204" }, Volume = 0.55, Pitch = { 1.0, 1.04 }, Group = "Crowd", Pool = 1 },

		-- Coins and UI
		Coins = { Ids = { "rbxassetid://139825402019264" }, Volume = 0.5, Pitch = { 0.97, 1.03 }, Group = "SFX", Pool = 2, Layers = { "CoinShower" } },
		CoinShower = { Ids = { "rbxassetid://9113849583" }, Volume = 0.25, Pitch = { 1.1, 1.2 }, Group = "SFX", Pool = 1 },
		Click = { Ids = { "rbxassetid://9114215780" }, Volume = 0.45, Pitch = { 1.0, 1.08 }, Group = "UI", Pool = 3 },
		Toast = { Ids = { "rbxassetid://75594243553477" }, Volume = 0.35, Pitch = { 1.0, 1.0 }, Group = "UI", Pool = 1 },
	},
}
