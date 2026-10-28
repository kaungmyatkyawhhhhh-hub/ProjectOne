-- Coaches (GDD 12). ORIGINAL characters built from running archetypes: no real names, faces,
-- signature poses or nicknames of real people. Boosts are at BASE; stages multiply them.
return {
	RollMinutes = 1.5, -- roll price = minutes of coins at your league
	RollMinPrice = 50,
	FreeSlots = 2, -- passes add more in M5 (SlotPasses below)
	SlotPasses = { "ExtraCoachSlot", "ExtraCoachSlot2" },
	Caps = { Train = 3.0, Pace = 0.15, Coins = 3.0 }, -- totals across equipped coaches (+300% / +15%)

	Stages = { "BASE", "PRO", "ELITE", "LEGEND" },
	StageColors = { "#1E90FF", "#6BE33B", "#FF7A1A", "#FFB300" }, -- tile colours in MY COACHES (BASE blue, PRO lime, ELITE orange, LEGEND gold)
	AgencyRange = 30, -- studs: rolls only near a Coach Agency stand (one in each world)
	StageMult = { 1, 1.5, 2.2, 3.0 },
	EvolveCost = 3, -- three of the same coach at the same stage -> one at the next stage

	Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Secret+" },
	RarityColors = {
		Common = Color3.fromHex("#C9D1DD"),
		Uncommon = Color3.fromHex("#6BE33B"), -- sporty rarity colours (prompt 12: no purple)
		Rare = Color3.fromHex("#1E90FF"),
		Epic = Color3.fromHex("#FF3B3B"),
		Legendary = Color3.fromHex("#FFD21F"),
		Mythic = Color3.fromHex("#FF7A1A"),
		Secret = Color3.fromHex("#F4F6FA"),
		["Secret+"] = Color3.fromHex("#FFE38C"),
	},
	-- pity: a guaranteed coach of at least this rarity after N rolls without one
	Pity = { { Rarity = "Rare", Rolls = 30 }, { Rarity = "Epic", Rolls = 80 }, { Rarity = "Legendary", Rolls = 150 }, { Rarity = "Mythic", Rolls = 500 } },

	List = {
		{ Id = "Benji", Name = "Coach Benji", Rarity = "Common", Chance = 40, Train = 0.05,
			Look = { Skin = "#E8B48A", Top = "#1E7BFF", Bottom = "#171A22", Hair = "#5A3A22" }, Prop = "Whistle",
			Line = "Everyone starts slow. Let's fix that!" },
		{ Id = "RaeMiles", Name = "Rae Miles", Rarity = "Uncommon", Chance = 28, Coins = 0.08,
			Look = { Skin = "#C68B62", Top = "#4FC3FF", Bottom = "#0E3A8A", Hair = "#2B1D14" }, Prop = "Headband",
			Line = "Long runs, steady pace. Coins add up." },
		{ Id = "IvoDash", Name = "Ivo Dash", Rarity = "Rare", Chance = 18, Train = 0.12,
			Look = { Skin = "#F2CDA8", Top = "#2A2F3A", Bottom = "#171A22", Hair = "#C9D1DD" }, Prop = "Stopwatch",
			Line = "Again! And faster this time." },
		{ Id = "MaraLeap", Name = "Mara Leap", Rarity = "Epic", Chance = 9.5, Train = 0.20, Coins = 0.10,
			Look = { Skin = "#8D5A3B", Top = "#FF7A1A", Bottom = "#171A22", Hair = "#2B1D14" }, Prop = "Braid",
			Line = "Big strides. Nothing in the way." },
		{ Id = "Zephyr", Name = "Zephyr Reign", Rarity = "Legendary", Chance = 3.5, Train = 0.35, Pace = 0.03,
			Look = { Skin = "#5E3A26", Top = "#FFC83D", Bottom = "#0E3A8A", Hair = "#0B0D12" }, Prop = "Wind",
			Cutscene = "Storm", Line = "Relax. Speed is a feeling." },
		{ Id = "Kai", Name = "Kai Highland", Rarity = "Mythic", Chance = 0.8, Train = 0.50, Pace = 0.05,
			Look = { Skin = "#8D5A3B", Top = "#FF7A1F", Bottom = "#3FA34D", Hair = "#2B1D14" }, Prop = "Barefoot",
			Cutscene = "Sunrise", Line = "The hills taught me patience." },
		{ Id = "FlyingGhost", Name = "The Flying Ghost", Rarity = "Secret", Chance = 0.17, Train = 0.65, Pace = 0.06,
			Look = { Skin = "#F2CDA8", Top = "#F4F6FA", Bottom = "#2A2F3A", Hair = "#5A3A22" }, Prop = "PocketWatch",
			Cutscene = "FilmGrain", Line = "Every second counts. I counted them all." },
		{ Id = "Mercury", Name = "Mercury", Rarity = "Secret+", Chance = 0.03, Train = 0.80, Pace = 0.08,
			Look = { Skin = "#E0A981", Top = "#FFC83D", Bottom = "#F4F6FA", Hair = "#FFE38C" }, Prop = "Wings",
			Cutscene = "Temple", Line = "Fast as a thought." },
	},
}
