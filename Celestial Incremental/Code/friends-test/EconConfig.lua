-- EconConfig (Galaxy Incremental, friends test 8 Nov): every number of the first 15 minutes, from the design note
-- "2026-11-01 Supernova Incremental - Full game design" section 1 (bodies) and the owner's ring-1 rules (2 Nov,
-- Calc\ring1.py). Server and client both read it; nothing else holds an economy number.
local Econ = {}

Econ.DataVersion = 3 -- the save's version (bump + migrate in GalaxyEconService when the save's shape changes)
-- (3 = feel pass, 5 Nov: owned = body LEVELS + copies; an old owned count n -> level n, 1 + n/25 copies)
-- (2 = alpha part 1, 3 Nov: shards, shardsEarned, ring2, the Binary Star tier; a v1 save gets them empty)

------------------------------------------------------------------------ bodies (FEEL PASS, 5 Nov: Calc\feel.py, vault "Feel pass PLAN + numbers")
-- a body type k (0 = Asteroid): UPGRADE = +1 level, +BODY = one more copy in orbit (max MaxCopies). Unlocking a type = level 1,
-- one copy. income = 5^k * level * copies * 2^(named tiers passed); a NAMED TIER every 10 levels (DUST, ROCK, IRON...), x2 each.
-- UPGRADE cost = 10 * 8^k * 1.8^level; +BODY cost = 50 * 8^k * 4^(copies - 1). A Supernova resets levels and copies.
Econ.CostBase, Econ.CostTier, Econ.LevelGrowth = 10, 8, 1.8
Econ.CopyBase, Econ.CopyGrowth, Econ.MaxCopies = 50, 4, 5
Econ.IncomeTier = 5
Econ.TierEvery = 10
Econ.TierNames = { "DUST", "ROCK", "IRON", "CRYSTAL", "PLASMA", "SOLAR", "NOVA", "PULSAR", "QUASAR", "COSMIC" }
Econ.StartOwned = { 1 } -- the asteroid already orbits at 0 s (level 1, one copy)

-- the tiers (design: Star at Supernova 1, Binary Star at Supernova 3, Pulsar / Quasar with the Black Hole later).
-- unlock = the ring-1 node that opens it; unlockR2 = the ring-2 node (shards) that opens it; lockedText = shown until then
Econ.Tiers = {
	{ id = "Asteroid", name = "ASTEROID", icon = "asteroid", colour = Color3.fromRGB(196, 178, 204) },
	{ id = "Moon", name = "MOON", icon = "moon", colour = Color3.fromRGB(206, 222, 255), unlock = "LunarPull" },
	{ id = "Planet", name = "PLANET", icon = "planet", colour = Color3.fromRGB(180, 155, 255), unlock = "PlanetSeed" },
	{ id = "GasGiant", name = "GAS GIANT", icon = "gasgiant", colour = Color3.fromRGB(255, 176, 96), unlock = "GasGiant" },
	{ id = "Star", name = "STAR", icon = "sun", colour = Color3.fromRGB(255, 200, 90), unlockR2 = "StarTier", lockedText = "SUPERNOVA 1" },
	-- (no binary-star icon in the kit yet: the sun, tinted)
	{ id = "BinaryStar", name = "BINARY STAR", icon = "sun", colour = Color3.fromRGB(255, 150, 120), unlockR2 = "BinaryStar", lockedText = "SUPERNOVA 3" },
}
Econ.PlayableTiers = 4 -- Asteroid .. Gas Giant: the tiers ring 1 opens (the Star and up come from ring 2)

-- the named tier of a level: 1 = DUST (Lv 1-9), 2 = ROCK (10-19), 3 = IRON (20-29) ...
function Econ.NamedTier(level: number): number
	return math.clamp(level // Econ.TierEvery + 1, 1, #Econ.TierNames)
end
function Econ.TierName(level: number): string
	return Econ.TierNames[Econ.NamedTier(level)]
end
-- the level the next named tier starts at (nil = the last one)
function Econ.NextTierAt(level: number): number?
	local t = Econ.NamedTier(level)
	return if t < #Econ.TierNames then t * Econ.TierEvery else nil
end
-- k is 0-based (Asteroid = 0). UPGRADE from `level` to level + 1
function Econ.Cost(k: number, level: number, perks): number
	return Econ.CostBase * Econ.CostTier ^ k * Econ.LevelGrowth ^ level * (1 - Econ.PerksById.CheapLevels.per * Econ.PerkLv(perks, "CheapLevels"))
end
-- +BODY: the next copy when you have `copies`
function Econ.CopyCost(k: number, copies: number, perks): number
	return Econ.CopyBase * Econ.CostTier ^ k * Econ.CopyGrowth ^ (math.max(copies, 1) - 1) * (1 - Econ.PerksById.CheapBodies.per * Econ.PerkLv(perks, "CheapBodies"))
end
function Econ.TierIncome(k: number, level: number, copies: number): number
	if level <= 0 or copies <= 0 then return 0 end
	return Econ.IncomeTier ^ k * level * copies * 2 ^ (Econ.NamedTier(level) - 1)
end

------------------------------------------------------------------------ ring 1 (ONE table: the Upgrades window reads it for
-- the friends test, the Constellation Tree (T) reads the same table from the alpha; owner 2 Nov)
-- effect kinds: tierMult (tier k earns x mult), unlockTier (opens tier k), allMult (every body x mult),
-- cometEvery (a comet every n s)
-- tab = where the Upgrades window shows it (friends test); requires = the node before it
Econ.Ring1 = {
	-- (feel pass, 5 Nov: ring 1 = the three tier UNLOCKS only, on the BODIES rows; First Light, Orbit Speed, Comet Lure and
	-- Readiness are PERKS now, bought with XP: Econ.Perks)
	{ id = "LunarPull", name = "LUNAR PULL", cost = 80, tab = "PLANETS", icon = "moon",
		desc = "unlocks the Moon", effect = { kind = "unlockTier", tier = 1 } },
	{ id = "PlanetSeed", name = "PLANET SEED", cost = 640, tab = "PLANETS", icon = "planet", requires = "LunarPull",
		desc = "unlocks the Planet", effect = { kind = "unlockTier", tier = 2 } },
	{ id = "GasGiant", name = "GAS GIANT", cost = 5120, tab = "PLANETS", icon = "gasgiant", requires = "PlanetSeed",
		desc = "unlocks the Gas Giant", effect = { kind = "unlockTier", tier = 3 } },
}
Econ.Ring1ById = {}
for _, n in ipairs(Econ.Ring1) do Econ.Ring1ById[n.id] = n end

------------------------------------------------------------------------ ring 2: SHARDS (design section 2, the STELLAR branch in the
-- alpha; permanent until the Black Hole). costs[level] = the shards for that level. PROPOSED (calc, Calc\ring2.py, 3 Nov): each
-- buy priced so the build is worth ~x(1 + 0.1 * shards spent) (the design's rule); the two tier unlocks have a floor (3 / 5).
-- novas = the Supernovas you need first; requires = the node before it
Econ.Ring2 = {
	-- (alpha 2, 3 Nov: x1.5 -> x1.75 a level, so the second run is ~2x faster)
	-- (re-priced 5 Nov, owner: ~40% of ring 2 + its capstone still unbought at Ignition 1 (~27 min, ~600 shards earned):
	-- the bot buys Star, Starfire 1-3, Heavy Elements by then; Starfire 4-5 and the Binary Star are still ahead)
	{ id = "Starfire", name = "STARFIRE", icon = "sun", costs = { 5, 15, 45, 600, 1200 },
		desc = "every body earns x1.75 a level", effect = { kind = "allMult", mult = 1.75 } },
	{ id = "StarTier", name = "STAR", icon = "sun", costs = { 3 }, novas = 1,
		desc = "unlocks the Star", effect = { kind = "unlockTier", tier = 4 } },
	{ id = "HeavyElements", name = "HEAVY ELEMENTS", icon = "gasgiant", costs = { 120 }, requires = "StarTier",
		desc = "each tier earns x(1 + 0.25 x its number)", effect = { kind = "heavy", per = 0.25 } },
	{ id = "BinaryStar", name = "BINARY STAR", icon = "sun", costs = { 600 }, novas = 3, requires = "StarTier",
		desc = "unlocks the Binary Star", effect = { kind = "unlockTier", tier = 5 } },
}
Econ.Ring2ById = {}
for _, n in ipairs(Econ.Ring2) do Econ.Ring2ById[n.id] = n end
-- ring 2's CAPSTONE (pick 1: design 2; Phase 2 builds it): its planned price, above what a player holds at Ignition 1
Econ.Ring2CapstoneShards = 1000
-- the other ring-2 branches: shown as "?" with what opens them (not in the alpha)
Econ.Ring2Later = {
	{ name = "COMETS", icon = "comet", lockedText = "NEXT UPDATE" },
	{ name = "FORGE", icon = "forge", lockedText = "SUPERNOVA 3" },
	{ name = "AUTOMATION", icon = "gear", lockedText = "NEXT UPDATE" },
}
-- r2 = { [id] = level }. The next level's cost (nil = maxed)
function Econ.R2Cost(id: string, level: number): number?
	local n = Econ.Ring2ById[id]
	return n and n.costs[level + 1]
end

-- shared by the server (what you earn) and the windows (what they show): owned = { [1] = asteroids, ... },
-- nodes = { id = true } (ring 1), r2 = { id = level } (ring 2; optional)
function Econ.Unlocked(k: number, nodes, r2): boolean
	if k == 0 then return true end
	local tier = Econ.Tiers[k + 1]
	if not tier then return false end
	if tier.unlock then return nodes[tier.unlock] == true end
	if tier.unlockR2 then return ((r2 or {})[tier.unlockR2] or 0) >= 1 end
	return false
end
-- tier k's income with its node multipliers (not the all-bodies ones): ring 1's tierMult, ring 2's Heavy Elements
function Econ.TierIncomeWith(k: number, level: number, copies: number, nodes, r2, perks): number
	local inc = Econ.TierIncome(k, level, copies)
	-- (the body type's perk: FIRST LIGHT, MOON GLOW, PLANET CORE, GIANT STORM, STAR HEART: +0.5x a level)
	local tp = Econ.TierPerk[k]
	if tp then inc *= 1 + Econ.PerksById[tp].per * Econ.PerkLv(perks, tp) end
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "tierMult" and n.effect.tier == k then inc *= n.effect.mult end
	end
	if ((r2 or {}).HeavyElements or 0) >= 1 then inc *= 1 + Econ.Ring2ById.HeavyElements.effect.per * (k + 1) end
	return inc
end
-- every body x: ring 1's allMult nodes x Starfire (x1.75 a level) x the STARDUST and ORBIT SPEED perks
function Econ.AllMult(nodes, r2, perks): number
	local m = (1 + Econ.PerksById.Stardust.per * Econ.PerkLv(perks, "Stardust")) * (1 + Econ.PerksById.OrbitSpeed.per * Econ.PerkLv(perks, "OrbitSpeed"))
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "allMult" then m *= n.effect.mult end
	end
	local sf = (r2 or {}).Starfire or 0
	if sf > 0 then m *= Econ.Ring2ById.Starfire.effect.mult ^ sf end
	return m
end
-- owned = { [1] = the Asteroid's level, ... }, copies = { [1] = its copies, ... }
function Econ.Income(owned, copies, nodes, r2, perks): number
	local total = 0
	for k = 0, #Econ.Tiers - 1 do
		if (owned[k + 1] or 0) > 0 then total += Econ.TierIncomeWith(k, owned[k + 1], math.max(copies[k + 1] or 0, 1), nodes, r2, perks) end
	end
	return total * Econ.AllMult(nodes, r2, perks)
end
function Econ.CometEvery(nodes, perks): number
	local every = Econ.Comet.Every - Econ.PerksById.CometLure.per * Econ.PerkLv(perks, "CometLure")
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "cometEvery" then every = math.min(every, n.effect.seconds) end
	end
	return every
end

------------------------------------------------------------------------ comets (design: every 45 s, worth 30-60 s of income)
Econ.Comet = {
	Every = 45,          -- seconds between comets (Comet Lure: 30)
	ValueMin = 30, ValueMax = 60, -- a caught comet = this many seconds of your income
	Life = 9,            -- a comet can be caught for this long after it appears (server side)
	FirstDelay = 20,     -- the first regular comet after the tutorial's comets
	RunOneEvery = 20,    -- (Tutorial 2: run 1 only, a comet every ~20 s)
	Golden = 0.1, GoldenX = 5, -- (run 1 only: 1 in 10 comets is GOLDEN and pays x5)
	MinEvery = 15,       -- the floor (3 Nov): never more than one comet per 15 s, whatever stacks (Lure + x2 COMETS = 15)
}

------------------------------------------------------------------------ Supernova (feel pass, 5 Nov): the stardust EARNED this run that
-- Supernova n needs (Calc\feel2.py, calibrated to the Studio bot on 5 Nov: x6 / x5 / x4 let runs 4-6 collapse to 18-35 s
-- once ring 2's Binary Star + Heavy Elements arrive at Supernova 3): real runs 6.0, 2.6, 2.4, 2.2, 2.05, 1.8, 1.7, 1.7 min
-- (runs 2-6 each shorter: owner 5 Nov); after ~Supernova 9 they lengthen (pads, perks, Starfire maxed) = Ignition 1 + the Forge. shards = floor(14 x sqrt(earned / need) x 1.25^Supernovas done): 14 at
-- Supernova 1, a little more each time, x1.41 if you earn 2x the need first (the Studio bot, 5 Nov: shards from the raw
-- earned amount gave 269 -> 1,146 a Supernova and bought all of ring 2 by Supernova 3).
-- Resets stardust, body levels + copies (the asteroid stays at level 1), the tier unlocks. Keeps shards, ring 2, the count + rank,
-- Essence, the tutorial, pads, the Cosmic Level and perks.
-- (owner 5 Nov: Supernova 1 ~5 min, runs never under ~1.5 min; with ring 2 re-priced. Sim: 5.0, 2.6, 2.5, 2.4, 2.3, 2.2, 2.2,
-- 2.0, 2.0, 2.0, 2.1, 2.2, then 1.6-3.0 with x1.6. 220K gave 5.7 min, so Supernova 1 = 110K)
-- (bot 5 Nov, 2nd check: from Supernova 9 the runs fell to 0.9-1.5 min with 720M..960M: the late needs grow faster now)
Econ.SupernovaNeeds = { 2.5e5, 1.8e6, 1.2e7, 4.8e7, 2.4e8, 4e8, 4.6e8, 1.4e9, 1.7e9, 1.9e9, 2.6e9, 1.6e10 }
Econ.NeedGrowthAfter = 2.4
function Econ.NeedFor(novas: number): number
	local n = (novas or 0) + 1
	local list = Econ.SupernovaNeeds
	if n <= #list then return list[n] end
	return list[#list] * Econ.NeedGrowthAfter ^ (n - #list)
end
Econ.ShardFirst, Econ.ShardGrowth = 14, 1.25
function Econ.ShardsFor(earned: number, nodes, novas: number?, perks): number
	local need = Econ.NeedFor(novas or 0)
	if earned < need then return 0 end
	local base = Econ.ShardFirst * math.sqrt(earned / need) * Econ.ShardGrowth ^ (novas or 0) * (1 + Econ.PerksById.Readiness.per * Econ.PerkLv(perks, "Readiness"))
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "shardBonus" then base *= 1 + n.effect.pct / 100 end
	end
	return math.floor(base + 1e-9)
end

------------------------------------------------------------------------ ISLAND PADS (feel pass, 5 Nov: #388 #86 #125). A chain of 20 pads on
-- your island, only the next one lit (the arrow points at it). Each builds a piece of your island in front of you
-- (MapService PAD_BUILD); bonus = x1.15 stardust. Pads are KEPT through a Supernova. Prices: Calc\feel.py (a pad is
-- bought once it costs <= ~45 s of income: 1-8 in run 1, the rest by ~30 min). Pads 1-10 are the island's old pieces.
-- (bot 5 Nov: pads 17-20 at 100M-1.5B cost more than a late run earns, so 'all 20 pads' never finished: now 30M-500M)
Econ.PadBonus = 1.15
Econ.Pads = {
	{ id = "Disc", name = "STONE ISLAND", price = 15 },
	{ id = "Tiles", name = "STAR TILES", price = 60 },
	{ id = "Rim", name = "BRASS RIM", price = 150, bonus = true },
	{ id = "Lamps", name = "LAMP PILLARS", price = 400 },
	{ id = "Crystals", name = "CRYSTALS", price = 1.2e3 },
	{ id = "Garden", name = "MOON GARDEN", price = 3e3, bonus = true },
	{ id = "Banner", name = "YOUR BANNER", price = 8e3 },
	{ id = "Crown", name = "CROWN RING", price = 2e4 },
	{ id = "Dais", name = "STAR DAIS", price = 6e4, bonus = true },
	{ id = "Telescope", name = "TELESCOPE", price = 1.5e5 },
	{ id = "Gyro", name = "GYRO RING", price = 4e5 },
	{ id = "Gate", name = "STAR GATE", price = 1e6, bonus = true },
	{ id = "Lights", name = "INNER LIGHTS", price = 2.5e6 },
	{ id = "Floaters", name = "FLOATING CRYSTALS", price = 6e6 },
	{ id = "Altar", name = "STAR ALTAR", price = 1.5e7, bonus = true },
	{ id = "Halo", name = "ORBIT HALO", price = 3e7 },
	{ id = "Globe", name = "PLANET GLOBE", price = 6e7 },
	{ id = "Spires", name = "CRYSTAL SPIRES", price = 1.2e8, bonus = true },
	{ id = "Walk", name = "LIGHT WALK", price = 2.5e8 },
	{ id = "Beacon", name = "BEACON", price = 5e8, bonus = true },
}
-- the x stardust from the bonus pads you have
function Econ.PadMult(pads: number, perks): number
	local m = 1
	local each = Econ.PadBonus + Econ.PerksById.PadPower.per * Econ.PerkLv(perks, "PadPower")
	for i = 1, math.min(pads or 0, #Econ.Pads) do
		if Econ.Pads[i].bonus then m *= each end
	end
	return m
end

------------------------------------------------------------------------ COSMIC LEVEL + PERKS (feel pass, 5 Nov: #84 #85; Calc\feel.py)
-- XP/s = 0.12 * log10(1 + stardust/s)^1.5 (x XP FLOW). Level n needs 8 * 1.3^(n-1) more XP in TOTAL. XP is also SPENT on
-- perks, but the level never goes down (Regrowth's LVL + XP crystals). Kept through a Supernova. A new save starts with 2 XP:
-- FIRST LIGHT's first level is the tutorial's step 2.
Econ.XP = { Base = 0.12, Power = 1.5, Need = 8, Grow = 1.3, Start = 2 }
function Econ.PerkLv(perks, id: string): number
	return if perks then tonumber(perks[id]) or 0 else 0
end
function Econ.XPRate(income: number, perks, extra: number?): number
	return Econ.XP.Base * math.log10(1 + math.max(income, 0)) ^ Econ.XP.Power * (1 + Econ.PerksById.XPFlow.per * Econ.PerkLv(perks, "XPFlow")) * (extra or 1)
end
-- the TOTAL XP that reaches `level` (level 1 = 0)
function Econ.XPForLevel(level: number): number
	return Econ.XP.Need * (Econ.XP.Grow ^ (level - 1) - 1) / (Econ.XP.Grow - 1)
end
function Econ.LevelOf(totalXP: number): number
	local lv = 1
	while lv < 500 and totalXP >= Econ.XPForLevel(lv + 1) do lv += 1 end
	return lv
end
-- the level's NAME (it is the rank over your head: owner 5 Nov, "FLARE III · ✦12"): 9 steps a band, I-IX
Econ.LevelBands = {
	{ name = "SPARK", colour = Color3.fromRGB(255, 205, 90) },
	{ name = "FLARE", colour = Color3.fromRGB(255, 150, 70) },
	{ name = "BLAZE", colour = Color3.fromRGB(255, 110, 120) },
	{ name = "NOVA", colour = Color3.fromRGB(200, 140, 255) },
	{ name = "SUPERGIANT", colour = Color3.fromRGB(120, 200, 255) },
	{ name = "HYPERGIANT", colour = Color3.fromRGB(150, 255, 230) },
	{ name = "QUASAR", colour = Color3.fromRGB(255, 120, 230) },
}
local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX" }
function Econ.LevelBand(level: number)
	return Econ.LevelBands[math.clamp((level - 1) // 9 + 1, 1, #Econ.LevelBands)]
end
function Econ.LevelName(level: number): string
	local band = (level - 1) // 9 + 1
	if band > #Econ.LevelBands then return Econ.LevelBands[#Econ.LevelBands].name .. " " .. (level - 9 * (#Econ.LevelBands - 1)) end
	return Econ.LevelBands[band].name .. " " .. ROMAN[(level - 1) % 9 + 1]
end
-- the RANK over your head: the level name + your Supernovas ("FLARE III · ✦12")
function Econ.RankText(level: number, novas: number): string
	return Econ.LevelName(level) .. (if novas > 0 then " · ✦" .. novas else "")
end
-- 16 PERKS in 4 perk tiers; a tier opens every 10 Cosmic Levels (LVL 1, 10, 20, 30). Max 10 levels each; a level costs
-- 2 x 1.6^level XP. per = what one level adds (x, s, %, chance)
Econ.PerkMax = 10
Econ.Perks = {
	{ id = "Stardust", name = "STARDUST", icon = "stardust", opens = 1, per = 0.1, desc = "all stardust +0.1x a level" },
	{ id = "FirstLight", name = "FIRST LIGHT", icon = "sun", opens = 1, per = 0.5, desc = "asteroids +0.5x a level" },
	{ id = "CometLure", name = "COMET LURE", icon = "comet", opens = 1, per = 2, desc = "comets come 2 s sooner a level" },
	{ id = "CometValue", name = "COMET VALUE", icon = "comet", opens = 1, per = 0.1, desc = "comets pay +10% a level" },
	{ id = "OrbitSpeed", name = "ORBIT SPEED", icon = "planet", opens = 10, per = 0.05, desc = "every body +0.05x a level" },
	{ id = "MoonGlow", name = "MOON GLOW", icon = "moon", opens = 10, per = 0.5, desc = "moons +0.5x a level" },
	{ id = "PlanetCore", name = "PLANET CORE", icon = "planet", opens = 10, per = 0.5, desc = "planets +0.5x a level" },
	{ id = "XPFlow", name = "XP FLOW", icon = "essence", opens = 10, per = 0.1, desc = "+10% XP a level" },
	{ id = "Readiness", name = "READINESS", icon = "shard", opens = 20, per = 0.02, desc = "+2% shards a level" },
	{ id = "GiantStorm", name = "GIANT STORM", icon = "gasgiant", opens = 20, per = 0.5, desc = "gas giants +0.5x a level" },
	{ id = "CheapLevels", name = "CHEAP LEVELS", icon = "stardust", opens = 20, per = 0.03, desc = "UPGRADE costs -3% a level" },
	{ id = "SurgePower", name = "SURGE POWER", icon = "stardust", opens = 20, per = 0.1, desc = "Star Surge +10% stronger a level" },
	{ id = "StarHeart", name = "STAR HEART", icon = "sun", opens = 30, per = 0.5, desc = "stars +0.5x a level" },
	{ id = "CheapBodies", name = "CHEAP BODIES", icon = "planet", opens = 30, per = 0.04, desc = "+BODY costs -4% a level" },
	{ id = "LuckyComet", name = "LUCKY COMET", icon = "comet", opens = 30, per = 0.01, desc = "+1% chance a comet pays x10" },
	{ id = "PadPower", name = "PAD POWER", icon = "stardust", opens = 30, per = 0.01, desc = "bonus pads +0.01x each a level" },
}
Econ.PerksById = {}
for _, p in ipairs(Econ.Perks) do Econ.PerksById[p.id] = p end
-- the body type each tier perk boosts (k 0-based)
Econ.TierPerk = { [0] = "FirstLight", [1] = "MoonGlow", [2] = "PlanetCore", [3] = "GiantStorm", [4] = "StarHeart" }
function Econ.PerkCost(level: number): number
	return math.ceil(2 * 1.6 ^ level)
end
-- what a perk gives at a level, as shown on its card ("x1.30", "35s", "+20%")
function Econ.PerkValue(p, level: number): string
	if p.id == "CometLure" then return (Econ.Comet.Every - p.per * level) .. "s" end
	if p.id == "CometValue" or p.id == "XPFlow" or p.id == "Readiness" or p.id == "SurgePower" or p.id == "LuckyComet" then
		return "+" .. math.floor(p.per * level * 100 + 0.5) .. "%"
	end
	if p.id == "CheapLevels" or p.id == "CheapBodies" then return "-" .. math.floor(p.per * level * 100 + 0.5) .. "%" end
	local v = if p.id == "PadPower" then Econ.PadBonus + p.per * level else 1 + p.per * level
	local s = string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
	return "x" .. s
end
-- the perks from a subject's attributes (Perk_<id>)
function Econ.PerksOf(subject): { [string]: number }
	local t = {}
	if not subject then return t end
	for _, p in ipairs(Econ.Perks) do t[p.id] = tonumber(subject:GetAttribute("Perk_" .. p.id)) or 0 end
	return t
end

------------------------------------------------------------------------ PURPOSE (owner 4-5 Nov: "no purpose"; vault "Prompt - Purpose", #9-#27)
-- "The galaxy went dark. Light it up again, one star at a time." Chapters = SECTORS, each adds a new system. The IGNITION
-- gate ends a sector: its checklist (MapConfig.Ignition) must be met all at once; the server lights the sector (Ignition 1
-- ~minute 28: Calc\feel.py + the Studio bot), gives Essence, opens Sector 2 (the STAR FORGE), and you pick 1 of 2 PATHS.
Econ.Premise = "The galaxy went dark. Light it up again, one star at a time."
Econ.Sectors = {
	{ id = "EmberBelt", name = "EMBER BELT", system = "Stardust, bodies, the Supernova", icon = "stardust" },
	{ id = "CometReach", name = "COMET REACH", system = "The STAR FORGE", icon = "forge" },
	{ id = "NebulaGate", name = "NEBULA GATE", system = "The BLACK HOLE", icon = "gear", later = true },
	{ id = "RingNebula", name = "RING NEBULA", system = "?", icon = "planet", later = true },
	{ id = "Unknown", name = "?", system = "?", icon = "lock", later = true },
}
Econ.IgnitionEssence = 10 -- (Ignition 1's reward: Essence = the Forge's currency, so the Forge starts with rolls)
Econ.SupernovaEssence = 1 -- (every Supernova gives 1 Essence: the Forge's slow fixed rate, design "one job per currency")
-- the 2 PATHS picked at Ignition 1 (switch later for PathSwitchShards shards)
Econ.Paths = {
	{ id = "Comet", name = "COMET PATH", icon = "comet", desc = "Comets pay x2 and come 20% sooner" },
	{ id = "Planet", name = "PLANET PATH", icon = "planet", desc = "Every body earns x1.5" },
}
Econ.PathSwitchShards = 10
-- GALAXY LIT %: the finish line (#27). Sector 1 can give up to 23%: pads 0.4 each, Supernovas 0.5 each (to 10), Cosmic Level
-- 0.1 each (to 30), Ignition 1 = 7
function Econ.GalaxyLit(pads: number, novas: number, level: number, ignition: number): number
	return math.floor(pads * 0.4 + math.min(novas, 10) * 0.5 + math.min(level, 30) * 0.1 + math.min(ignition, 1) * 7)
end

------------------------------------------------------------------------ THE STAR FORGE (design "Full game design" 3b; Sector 2, opens at
-- IGNITION 1: checklist #59-#62). Roll a Star Core for 1 Essence (BULK = 3 rolls); the odds are shown (sum 100%); pity:
-- Legendary by roll 200, Mythic by 1,500 (none for Celestial). Equip 3 cores. 6 kinds x 7 rarities = 42 cores (the book);
-- a duplicate levels its core (1-10, +10% of its power each). Essence = the Forge only (tutorial, Supernovas, Ignition):
-- it can't be bought, and stardust never turns into Essence.
Econ.Forge = {
	RollCost = 1, Bulk = 3, Slots = 3, MaxLevel = 10,
	PityLegendary = 200, PityMythic = 1500,
	Rarities = {
		{ id = "Common", name = "COMMON", odds = 60, mult = 1.2, colour = Color3.fromRGB(200, 196, 210) },
		{ id = "Uncommon", name = "UNCOMMON", odds = 25, mult = 1.4, colour = Color3.fromRGB(110, 230, 120) },
		{ id = "Rare", name = "RARE", odds = 10, mult = 1.8, colour = Color3.fromRGB(90, 170, 255) },
		{ id = "Epic", name = "EPIC", odds = 4, mult = 2.5, colour = Color3.fromRGB(190, 110, 255) },
		{ id = "Legendary", name = "LEGENDARY", odds = 0.9, mult = 4, colour = Color3.fromRGB(255, 190, 60) },
		{ id = "Mythic", name = "MYTHIC", odds = 0.09, mult = 8, colour = Color3.fromRGB(255, 90, 120) },
		{ id = "Celestial", name = "CELESTIAL", odds = 0.01, mult = 20, colour = Color3.fromRGB(150, 255, 240) },
	},
	-- one stat each (choosing 3 is a real choice). power p = 1 + (rarity mult - 1) x (1 + 0.1 x (level - 1))
	Kinds = {
		{ id = "Stardust", name = "STARDUST CORE", icon = "stardust", desc = "all stardust x" },
		{ id = "Shards", name = "SHARD CORE", icon = "shard", desc = "+% shards" },
		{ id = "Comets", name = "COMET CORE", icon = "comet", desc = "comets pay x" },
		{ id = "XP", name = "XP CORE", icon = "sun", desc = "+% XP" },
		{ id = "Luck", name = "LUCK CORE", icon = "essence", desc = "+% Forge luck" },
		{ id = "Giant", name = "GIANT CORE", icon = "gasgiant", desc = "gas giants x" },
		-- (owner 5 Nov: when offline earnings is built, ADD an OFFLINE core here (offline rate +%); keep the XP core)
	},
}
Econ.ForgeRarityById, Econ.ForgeKindById = {}, {}
for i, r in ipairs(Econ.Forge.Rarities) do r.index = i Econ.ForgeRarityById[r.id] = r end
for _, k in ipairs(Econ.Forge.Kinds) do Econ.ForgeKindById[k.id] = k end
function Econ.CorePower(rarity: string, level: number): number
	local r = Econ.ForgeRarityById[rarity]
	if not r then return 1 end
	return 1 + (r.mult - 1) * (1 + 0.1 * (math.clamp(level, 1, Econ.Forge.MaxLevel) - 1))
end
-- what a core does, as a short text ("x1.80", "+40%")
function Econ.CoreText(kind: string, rarity: string, level: number): string
	local p = Econ.CorePower(rarity, level)
	if kind == "Shards" then return "+" .. math.floor((p - 1) * 50 + 0.5) .. "%" end
	if kind == "XP" then return "+" .. math.floor((p - 1) * 100 + 0.5) .. "%" end
	if kind == "Luck" then return "+" .. math.floor((p - 1) * 25 + 0.5) .. "%" end
	if kind == "Giant" then p = p ^ 1.5 end
	return "x" .. (string.format("%.2f", p):gsub("0+$", ""):gsub("%.$", ""))
end
-- the effect of the EQUIPPED cores, by kind (same kind ADDS, like every boost: #69). equipped = { "Kind:Rarity", ... },
-- cores = { ["Kind:Rarity"] = level }
function Econ.ForgeEffect(equipped, cores, kind: string): number
	local add = 0
	for _, key in ipairs(equipped or {}) do
		local k, r = string.match(key, "^(%a+):(%a+)$")
		if k == kind and cores and cores[key] then add += Econ.CorePower(r, cores[key]) - 1 end
	end
	if kind == "Shards" then return 1 + add * 0.5 end
	if kind == "XP" then return 1 + add end
	if kind == "Luck" then return 1 + add * 0.25 end
	if kind == "Giant" then return (1 + add) ^ 1.5 end
	return 1 + add
end

------------------------------------------------------------------------ BOOST POTIONS (design additions 3, overnight part 2): from codes,
-- kept in an inventory, used when the player wants. Using one adds its minutes to that boost's timer (they stack by TIME,
-- never x4). The timer only runs while you play. x2 STARDUST doubles all stardust income; x2 COMETS = comets come twice
-- as often (and a caught one pays the same).
Econ.Potions = {
	{ id = "Stardust", name = "x2 STARDUST", icon = "potionStardust", minutes = 15, colour = Color3.fromRGB(255, 150, 40),
		desc = "x2 stardust for 15 min" },
	{ id = "Comets", name = "x2 COMETS", icon = "potionComets", minutes = 15, colour = Color3.fromRGB(70, 170, 255),
		desc = "twice as many comets for 15 min" },
}
Econ.PotionsById = {}
for _, p in ipairs(Econ.Potions) do Econ.PotionsById[p.id] = p end

------------------------------------------------------------------------ tutorial (design steps 1-4; Regrowth lesson: Essence
-- per step + a step counter). Friends test: "1/4".."4/4", 1 Essence each, then TUTORIAL COMPLETE (owner 2 Nov)
-- TUTORIAL 2 (5 Nov, Regrowth style; vault "Prompt - Tutorial 2"; checklist #110-#123): 20 GOAL steps with a live counter
-- (attr = the player attribute counted, need = the goal), guiding the first ~27 min to IGNITION 1 (the Star Forge). Each
-- step pays its Essence + ~TutorialStardustSec seconds of income; +3 Essence at the first Supernova and at Ignition. The
-- guide (LUMI, the star spirit) says `hint`. Every step shows or unlocks something new; never a "now grind" step.
Econ.TutorialStardustSec = 20
Econ.TutorialSpirit = { name = "LUMI", portrait = "rbxassetid://128773218162368" } -- (UI\star_spirit_blender.py, Studio test upload)
Econ.Tutorial = {
	{ id = "Asteroid3", hint = "UPGRADE your Asteroid", attr = "Own1", need = 3, essence = 1 },
	{ id = "FirstLight", hint = "PERK: FIRST LIGHT (free)", attr = "Perk_FirstLight", need = 1, essence = 1 },
	{ id = "Pad1", hint = "Build your island: STONE ISLAND", attr = "Pads", need = 1, essence = 1 },
	{ id = "Moon", hint = "UNLOCK the Moon", attr = "Own2", need = 1, essence = 1 },
	{ id = "Copy", hint = "+BODY: a 2nd Asteroid", attr = "Copies1", need = 2, essence = 1 },
	{ id = "Comets", hint = "Tap 2 comets!", attr = "CometsCaught", need = 2, essence = 1 },
	{ id = "Rock", hint = "Asteroid to ROCK (Lv 10)", attr = "Own1", need = 10, essence = 1 },
	{ id = "Planet", hint = "UNLOCK the Planet", attr = "Own3", need = 1, essence = 1 },
	{ id = "Pads4", hint = "Build 4 island pads", attr = "Pads", need = 4, essence = 1 },
	{ id = "Level3", hint = "Reach Cosmic LVL 3", attr = "CosmicLevel", need = 3, essence = 1 },
	{ id = "Giant", hint = "UNLOCK the Gas Giant", attr = "Own4", need = 1, essence = 1 },
	{ id = "Ready", hint = "Grow to 100% SUPERNOVA", attr = "SupernovaPct", need = 100, essence = 1 },
	{ id = "Supernova", hint = "Go SUPERNOVA!", attr = "Supernovas", need = 1, essence = 3 },
	{ id = "Starfire", hint = "TREE: buy STARFIRE", attr = "R2_Starfire", need = 1, essence = 1 },
	{ id = "StarTier", hint = "TREE: open the STAR", attr = "R2_StarTier", need = 1, essence = 1 },
	{ id = "Nova2", hint = "Go SUPERNOVA again", attr = "Supernovas", need = 2, essence = 1 },
	{ id = "Pads12", hint = "Build 12 island pads", attr = "Pads", need = 12, essence = 1 },
	{ id = "Level10", hint = "Cosmic LVL 10: new PERKS", attr = "CosmicLevel", need = 10, essence = 1 },
	{ id = "Nova6", hint = "Go SUPERNOVA 6 times", attr = "Supernovas", need = 6, essence = 1 },
	{ id = "Ignition", hint = "Light SECTOR 1: IGNITION", attr = "Ignition", need = 1, essence = 3 },
}
Econ.HintAfter = 5 -- seconds idle before the hint line shows (design: "only after 5 s idle")

------------------------------------------------------------------------ number format (design: K, M, B, T, Qa, Qi...)
local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
function Econ.Format(n: number): string
	if n ~= n or n == math.huge then return "0" end
	if n < 0 then return "-" .. Econ.Format(-n) end
	if n < 100 then
		local f = math.floor(n * 10) / 10
		return if f == math.floor(f) then tostring(math.floor(f)) else string.format("%.1f", f)
	end
	if n < 1000 then return tostring(math.floor(n)) end
	local i = 1
	while n >= 1000 and i < #SUFFIX do
		n /= 1000
		i += 1
	end
	local s = if n >= 100 then string.format("%.0f", math.floor(n)) elseif n >= 10 then string.format("%.1f", math.floor(n * 10) / 10)
		else string.format("%.2f", math.floor(n * 100) / 100)
	return s .. SUFFIX[i]
end

return Econ
