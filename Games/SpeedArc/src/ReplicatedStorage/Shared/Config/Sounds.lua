-- Every sound in the game (Audio note rules). Roblox Creator Store / licensed library audio only.
-- Ids = one or more clips (never the same clip twice in a row). Pitch = random range. Layers = other keys played together.
-- Group: SFX, UI, Crowd, Music, Voice. Pool = how many copies can play at once.
local Sounds
Sounds = {
	-- Music (APM library via the Creator Store; owner picks the final ids). Crossfade 1.5 s between areas,
	-- race music from GO to the finish, everything ducks to 40% in the countdown.
	Music = {
		Hub = { Id = "rbxassetid://1846273376", Volume = 0.35 },
		Park = { Id = "rbxassetid://1846810919", Volume = 0.35 },
		Stadium = { Id = "rbxassetid://128683938011405", Volume = 0.35, Bed = "rbxassetid://9120974378" },
		Race = { Id = "rbxassetid://1842057947", Volume = 0.42 },
		Fade = 1.5,
		Duck = 0.4,
	},
	Groups = { SFX = 0.8, UI = 0.6, Crowd = 0.55, Music = 0.4, Voice = 0.8 },

	-- Loudness (M6): measured in Studio with the GYM ARC method (PlaybackLoudness while the clip plays;
	-- music at 15/35/55/75%). Every play is scaled by Target[group] / Loudness[id] (clamped), so a quiet
	-- clip and a loud clip at the same Volume sound equally loud. Volume then only says how important it is.
	Targets = { SFX = 90, UI = 35, Crowd = 110, Music = 110, Voice = 90 },
	NormClamp = { 0.5, 3.0 },
	Loudness = {
		["rbxassetid://9114215780"] = 8, -- click (Click, Tab, Denied, Join, RollTick ...)
		["rbxassetid://87061775498714"] = 14, -- step A
		["rbxassetid://140594308250996"] = 17, -- step B
		["rbxassetid://9120704978"] = 35, -- air whoosh (TapAir, windows, Jump)
		["rbxassetid://9117720867"] = 9, -- lace pull
		["rbxassetid://9126228631"] = 77, -- wind (Wind, TrailEquip, Arrive)
		["rbxassetid://75594243553477"] = 21, -- toast pop
		["rbxassetid://9125648149"] = 69, -- combo up / rank up
		["rbxassetid://9120975204"] = 148, -- crowd cheer (CrowdCheer, FinalStretch, FinishCheer)
		["rbxassetid://4944424481"] = 86, -- starting gun
		["rbxassetid://72827234719643"] = 62, -- shoe squeak
		["rbxassetid://9120914426"] = 40, -- thud (combo break, hurdle knock)
		["rbxassetid://9126229255"] = 94, -- boost whoosh
		["rbxassetid://132574644259001"] = 153, -- sparkle chord (unlock, reveals)
		["rbxassetid://139825402019264"] = 70, -- coins
		["rbxassetid://9113849583"] = 55, -- coin shower
		["rbxassetid://9120975307"] = 128, -- crowd burst
		["rbxassetid://91072655090313"] = 150, -- countdown beep
		["rbxassetid://91609406292294"] = 51, -- ka-ching
		["rbxassetid://1841800152"] = 91, -- fanfare
		["rbxassetid://9120974378"] = 96, -- crowd murmur / stadium bed
		-- music
		["rbxassetid://1846273376"] = 83, -- Hub
		["rbxassetid://1846810919"] = 157, -- Park
		["rbxassetid://128683938011405"] = 132, -- Stadium
		["rbxassetid://1842057947"] = 111, -- Race
	},

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
		Tab = { Ids = { "rbxassetid://9114215780" }, Volume = 0.3, Pitch = { 1.25, 1.3 }, Group = "UI", Pool = 2 },
		WindowOpen = { Ids = { "rbxassetid://9120704978" }, Volume = 0.25, Pitch = { 1.0, 1.06 }, Group = "UI", Pool = 1 },
		WindowClose = { Ids = { "rbxassetid://9120704978" }, Volume = 0.2, Pitch = { 0.8, 0.85 }, Group = "UI", Pool = 1 },

		-- Shops and collecting (Audio note)
		KaChing = { Ids = { "rbxassetid://91609406292294" }, Volume = 0.5, Pitch = { 0.98, 1.02 }, Group = "SFX", Pool = 1, Layers = { "CoinShower" } },
		ShoeSqueak = { Ids = { "rbxassetid://72827234719643" }, Volume = 0.45, Pitch = { 0.95, 1.08 }, Group = "SFX", Pool = 2 },
		LacePull = { Ids = { "rbxassetid://9117720867" }, Volume = 0.18, Pitch = { 1.6, 1.7 }, Group = "SFX", Pool = 1 },
		Equip = { Layers = { "ShoeSqueak", "LacePull" } },
		TrailEquip = { Ids = { "rbxassetid://9126228631" }, Volume = 0.35, Pitch = { 1.05, 1.12 }, Group = "SFX", Pool = 1 },
		RollTick = { Ids = { "rbxassetid://9114215780" }, Volume = 0.3, Pitch = { 1.4, 1.45 }, Group = "UI", Pool = 4 },
		RevealCommon = { Ids = { "rbxassetid://75594243553477" }, Volume = 0.5, Pitch = { 1.0, 1.0 }, Group = "SFX", Pool = 1 },
		RevealRare = { Ids = { "rbxassetid://132574644259001" }, Volume = 0.55, Pitch = { 1.0, 1.0 }, Group = "SFX", Pool = 1, Layers = { "RevealCommon" } },
		RevealEpic = { Ids = { "rbxassetid://132574644259001" }, Volume = 0.7, Pitch = { 0.9, 0.9 }, Group = "SFX", Pool = 1, Layers = { "CrowdOoh", "ComboUp" } },
		RevealLegend = { Ids = { "rbxassetid://1841800152" }, Volume = 0.6, Pitch = { 1.0, 1.0 }, Group = "Music", Pool = 1, Layers = { "FinishCheer", "RevealRare" } },
		RankUp = { Ids = { "rbxassetid://9125648149" }, Volume = 0.6, Pitch = { 0.8, 0.82 }, Group = "SFX", Pool = 1, Layers = { "CrowdOoh", "RevealRare" } },
		GoPro = { Ids = { "rbxassetid://1841800152" }, Volume = 0.7, Pitch = { 0.95, 0.95 }, Group = "Music", Pool = 1, Layers = { "FinishCheer", "Wind" } },
		Arrive = { Ids = { "rbxassetid://9126228631" }, Volume = 0.45, Pitch = { 0.9, 0.95 }, Group = "SFX", Pool = 1, Layers = { "CrowdMurmur" } },
		Jump = { Ids = { "rbxassetid://9120704978" }, Volume = 0.5, Pitch = { 0.9, 1.0 }, Group = "SFX", Pool = 2 },
		HurdleLand = { Ids = { "rbxassetid://87061775498714" }, Volume = 0.6, Pitch = { 0.85, 0.95 }, Group = "SFX", Pool = 2 },
		HurdleKnock = { Ids = { "rbxassetid://9120914426" }, Volume = 0.6, Pitch = { 0.95, 1.05 }, Group = "SFX", Pool = 2 },
		Wind = { Ids = { "rbxassetid://9126228631" }, Volume = 0.5, Pitch = { 0.55, 0.6 }, Group = "SFX", Pool = 2 },
	},
}

-- how much to scale this clip so it sounds as loud as the others in its group
function Sounds.norm(id, group)
	local l = Sounds.Loudness[id]
	if not l or l <= 0 then
		return 1
	end
	local t = Sounds.Targets[group or "SFX"] or 90
	return math.clamp(t / l, Sounds.NormClamp[1], Sounds.NormClamp[2])
end

return Sounds
