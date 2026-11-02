-- GameConfig (Galaxy Incremental, overnight part 4, 3 Nov): EVERY Creator Hub id the game uses, in one place, plus the
-- launch switches. The ids are PLACEHOLDERS (0) until the owner creates them in Creator Hub (P&L Studios XP): put each
-- new id here and nothing else changes. With an id of 0 the game simply skips that thing (no prompt, no award).
local Config = {}

-- the ALPHA (launch plan: Sat 14 Nov "[ALPHA] Galaxy Incremental"): while true, everyone who joins gets the Alpha Player
-- badge and the AlphaPlayer flag in their save (the title they get at full launch). Set false at full launch.
Config.AlphaActive = true

Config.Passes = {
	-- design note 9: "x2 Stardust | 249 | all stardust x2 forever" (the first pass is under 400 R$)
	X2Stardust = {
		id = 0, -- PLACEHOLDER: the game pass id from Creator Hub
		name = "x2 Stardust",
		title = "x2 STARDUST", -- (the store card's title)
		desc = "All your stardust x2, forever.",
		price = 249, -- (only shown until Roblox's live price loads: the store reads GetProductInfo)
		icon = "stardust",
	},
}

Config.Badges = {
	AlphaPlayer = 0, -- PLACEHOLDER: the badge id from Creator Hub
}

return Config
