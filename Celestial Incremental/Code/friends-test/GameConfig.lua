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
	-- (7 Nov, design §9 + the owner's monetization prompt: id 0 = not created yet = HIDDEN in the store, no effect. The owner
	-- creates them in Creator Hub and sends the ids. Prices: GetProductInfo once there is an id)
	VIP = {
		id = 2076176957, -- (owner created it 7 Nov)
		name = "VIP",
		title = "VIP",
		desc = "+25% stardust, +10% shards, a gold VIP name tag and chat tag.",
		price = 399,
		icon = "trophy",
		order = 2,
	},
	CoreSlot = {
		id = 2075582904, -- (owner created it 7 Nov)
		name = "+1 Core Slot",
		title = "+1 CORE SLOT",
		desc = "Equip 4 Star Cores at once instead of 3.",
		price = 349,
		icon = "starCore",
		order = 3,
	},
	AutoRoll = {
		id = 2075666914, -- (owner created it 7 Nov)
		name = "Auto Roll",
		title = "AUTO ROLL",
		desc = "The Star Forge rolls by itself while you have Essence. Switch it on or off in the Forge.",
		price = 199,
		icon = "forgeRolls",
		order = 4,
	},
}
Config.Passes.X2Stardust.order = 1

-- EVENTS (7 Nov, EventController = GalaxyLiveService): every server reads the clock itself (UTC) and runs the event that's on.
--   start = UTC time (ISO), minutes = how long, everyDays = repeats (7 = every week at the same time), stardust = +x (added
--   to the boosts like Star Surge: +1 = 2x STARDUST). The banner shows the real time left; no fake timers.
Config.Events = {
	-- (owner, 7 Nov: the alpha launches Sat 7 Nov 02:30 UTC = 9:00 Myanmar) the launch 2x hour, once
	{ id = "AlphaLaunch2x", title = "2x STARDUST HOUR", start = "2026-11-07T02:30:00Z", minutes = 60, stardust = 1 },
	-- then every Saturday 15:00 UTC (21:30 Myanmar, the Playbook's weekly slot)
	{ id = "Stardust2x", title = "2x STARDUST HOUR", start = "2026-11-14T15:00:00Z", minutes = 60, everyDays = 7, stardust = 1 },
}

-- WHAT'S NEW (7 Nov): the panel opens once per new version (after the tutorial), and everyone who played before it gets the
-- version's gift once on their next join. Bump `version` with each weekly update and change the lines + the gift.
Config.WhatsNew = {
	version = 1,
	title = "WHAT'S NEW",
	lines = {
		"BLACK HOLE: collapse 100K shards into Dark Matter (+25% shards each)",
		"AUTO-SUPERNOVA after your first Black Hole",
		"New Forge cards, leaderboards and STATS",
		"Playtime gifts now at 5, 10, 20, 40 and 60 minutes",
	},
	gift = { essence = 2 },
}

-- EXPERIENCE NOTIFICATIONS (7 Nov): only opted-in 13+ players get them (Playbook 11). The owner makes the messages in
-- Creator Hub (Engagement > Notifications) and an Open Cloud API key with "user-notification:write", saved in the game's
-- Secrets as `secret`. Empty message ids = nothing is sent.
Config.Notify = {
	secret = "NotifyApiKey",
	offlineFull = "", -- message id: "Your offline stardust is full!" (when the offline cap is reached; max 1 a day)
	weekly = "", -- message id: the weekly update
	weeklyVersion = 0, -- bump to send the weekly message once (to players seen in the last 28 days)
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
