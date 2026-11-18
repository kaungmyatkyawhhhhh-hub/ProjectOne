--[[
	CrateRules: the rules the crates must follow when they are built (owner approved 19 Nov 2026, vault
	"2026-11-19 Economy - fair car prices proposal" + "2026-11-17 Car economy and Skyfreight crate design").
	Nothing opens crates yet; this is the agreed data, read by the crate code once it exists.
	  * Import-only cars (Cars.isImport) come only from crates: never the dealer (BuyCar refuses), never a
	    market delivery, no airport cash buy.
	  * A duplicate from a CASH crate refunds DupRefund of the car's value (Cars Price = its value). At 50%
	    the cash crates would pay out more than they cost.
	  * Hypercars (Rarity "Hypercar", the Velocité Noir cars) only from crates, with a pity guarantee.
	Odds are percentages by Cars Rarity; a crate's pity: at most that many crates without the tier.
]]

return {
	DupRefund = 0.3, -- cash crates only
	AirportCashBuy = false, -- (owner: no airport cash buy, hypercars included)
	Cash = {
		Basic = { price = 90000, odds = { Common = 70, Uncommon = 25, Rare = 5 } },
		-- Premium: a Legendary at least every 8 crates; a Hypercar at least every 20 (about 200 h of a free mid
		-- player, the 140-210 h hypercar target)
		Premium = {
			price = 750000,
			odds = { Rare = 60, Epic = 32.5, Legendary = 6, Mythic = 1, Hypercar = 0.5 },
			pity = { Legendary = 8, Hypercar = 20 },
		},
	},
}
