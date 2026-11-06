-- GameConfig (Galaxy Incremental, overnight part 4, 3 Nov): EVERY Creator Hub id the game uses, in one place, plus the
-- launch switches. Ids from Creator Hub (P&L Studios XP, universe 10774273782): put each new id here and nothing else
-- changes. With an id of 0 the game simply skips that thing (no prompt, no award).
local Config = {}

-- the ALPHA (launch plan: Sat 14 Nov "[ALPHA] Galaxy Incremental"): while true, everyone who joins gets the Alpha Player
-- badge and the AlphaPlayer flag in their save (the title they get at full launch). Set false at full launch.
Config.AlphaActive = true

Config.Passes = {
	-- design note 9: "x2 Stardust | 249 | all stardust x2 forever" (the first pass is under 400 R$)
	X2Stardust = {
		id = 2070906361, -- the game pass id from Creator Hub (created 4 Nov, 249 R$)
		name = "x2 Stardust",
		title = "x2 STARDUST", -- (the store card's title)
		desc = "All your stardust x2, forever.",
		price = 249, -- (only shown until Roblox's live price loads: the store reads GetProductInfo)
		icon = "stardust",
	},
}

-- DEVELOPER PRODUCTS (Phase 2, 6 Nov): granted ONLY in GalaxyStoreService's ProcessReceipt, saved first, never twice (#454).
-- id 0 = not created in Creator Hub yet: the game hides that button. PRICES PROPOSED (owner creates them):
Config.Products = {
	-- the return screen's "x2" (#411): doubles what you earned while away. 25 R$: a small impulse buy (Depth's cheapest
	-- offer is 32 R$); it never sells a currency that buys luck
	OfflineX2 = { id = 3728719049, name = "x2 Offline Earnings", price = 25 }, -- (owner created it 6 Nov: 25 R$, no managed pricing)
}

Config.Badges = {
	AlphaPlayer = 4501804696776519, -- the badge id from Creator Hub (created 4 Nov)
	-- (Phase 2.5: a complete row of the Forge book; 0 = not created yet, nothing is awarded)
	-- (owner created 5 of them 6 Nov; Mythic + Celestial: PLACEHOLDERS, the owner sends the ids)
	CollectionCommon = 3711833782304936, CollectionUncommon = 20592640022331, CollectionRare = 2311076528381815,
	CollectionEpic = 3492227656070750, CollectionLegendary = 4059818233250995,
	CollectionMythic = 0, CollectionCelestial = 0,
}

return Config
