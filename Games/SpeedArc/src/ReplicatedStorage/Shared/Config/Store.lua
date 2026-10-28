-- Store (M5, GDD 20). FAIR RULES: Robux never wins a race by itself, no paid luck on rolls, no fake
-- timers, offers only at calm moments (after a race, never in one, never in the tutorial), at most one
-- small offer card per 10 min, and the price shown = Roblox's real price (read from Roblox when the
-- Id is set; Price here must be the same number as in Creator Hub).
-- Id = 0 means "not created in Creator Hub yet": the card shows SOON and can't be bought.
return {
	Passes = {
		{ Key = "AutoTrain", Name = "AUTO TRAIN", Price = 249, Id = 0, Hero = true,
			Desc = "Trains for you on any station: 3 taps a second with a steady x1.2 combo.",
			Icon = { "AUTO", "#1E7BFF" } },
		{ Key = "Speed2x", Name = "2x SPEED", Price = 249, Id = 0,
			Desc = "Double SPEED from every training tap, forever.",
			Icon = { "2x", "#FFC83D" } },
		{ Key = "Coins2x", Name = "2x COINS", Price = 149, Id = 0,
			Desc = "Double coins from races, training and rewards (all coin boosts together stop at x8).",
			Icon = { "2x", "#3FA34D" } },
		{ Key = "VIP", Name = "VIP", Price = 299, Id = 0,
			Desc = "+10% coins, VIP tag, VIP kit, VIP trail, VIP name style and a gold chat name.",
			Icon = { "VIP", "#FFC83D" } },
		{ Key = "ExtraCoachSlot", Name = "EXTRA COACH SLOT", Price = 99, Id = 0,
			Desc = "Equip one more coach (3 slots).",
			Icon = { "+1", "#9B6BFF" } },
		{ Key = "ExtraCoachSlot2", Name = "EXTRA COACH SLOT 2", Price = 149, Id = 0, Needs = "ExtraCoachSlot",
			Desc = "Equip one more coach again (4 slots).",
			Icon = { "+1", "#FF7A1F" } },
		{ Key = "TrailPack", Name = "TRAIL PACK", Price = 199, Id = 0,
			Desc = "4 trails: Lightning, Rainbow, Comet and Neon Wave.",
			Icon = { "TRAILS", "#4FC3FF" } },
		{ Key = "FasterRolls", Name = "FASTER ROLLS", Price = 99, Id = 0,
			Desc = "Skip the roll animation and roll 3 coaches at once (same odds, same coin price).",
			Icon = { "x3", "#C9D1DD" } },
	},

	-- Developer products. Coin packs are minutes of coins at your league (late players still want them).
	Products = {
		{ Key = "CoinsSmall", Tab = "COINS", Name = "SMALL COINS", Price = 25, Id = 0, Minutes = 20, Desc = "20 minutes of coins" },
		{ Key = "CoinsMedium", Tab = "COINS", Name = "MEDIUM COINS", Price = 99, Id = 0, Minutes = 120, Desc = "2 hours of coins" },
		{ Key = "CoinsLarge", Tab = "COINS", Name = "LARGE COINS", Price = 249, Id = 0, Minutes = 360, Desc = "6 hours of coins" },
		{ Key = "Speed15", Tab = "BOOSTS", Name = "2x SPEED 15 MIN", Price = 25, Id = 0, SpeedBoost = 15 * 60, Desc = "Double training for 15 minutes of play" },
		{ Key = "StarterPack", Tab = "BOOSTS", Name = "STARTER PACK", Price = 49, Id = 0, Once = true,
			Minutes = 60, SpeedBoost = 30 * 60, ShoeSkin = "CanvasRunners_Starter", Title = "STARTER",
			Desc = "1 hour of coins + 2x SPEED for 30 min + gold Canvas Runners + the STARTER title. Once!" },
	},

	StarterWindowHours = 24, -- the Starter Pack is only offered in the first 24 h after you first joined
	OfferGapSeconds = 600, -- at most one small offer card per 10 min
	AutoTrainOfferAfter = 10 * 60, -- the Auto Train card after 10 min of tapping in a session (once)
	SpeedBoostMult = 2, -- the 2x SPEED product (stacks with the New Runner / gift boost)

	AutoTrain = { TapsPerSecond = 3, Combo = 1.2, AfkCheckSeconds = 15 * 60, AfkAnswerSeconds = 60 },
	VIP = { Coins = 0.10, ChatColor = "#FFC83D" },
	FasterRolls = { Count = 3 },
}
