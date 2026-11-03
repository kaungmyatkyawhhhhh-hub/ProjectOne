-- EconConfig (Galaxy Incremental, friends test 8 Nov): every number of the first 15 minutes, from the design note
-- "2026-11-01 Supernova Incremental - Full game design" section 1 (bodies) and the owner's ring-1 rules (2 Nov,
-- Calc\ring1.py). Server and client both read it; nothing else holds an economy number.
local Econ = {}

Econ.DataVersion = 2 -- the save's version (bump + migrate in GalaxyEconService when the save's shape changes)
-- (2 = alpha part 1, 3 Nov: shards, shardsEarned, ring2, the Binary Star tier; a v1 save gets them empty)

------------------------------------------------------------------------ bodies (design: section 1, formulas)
-- cost = 10 * 8^k * 1.15^owned; income = 5^k * owned * milestone per second (k = tier 0..7)
Econ.CostBase, Econ.CostTier, Econ.CostGrowth = 10, 8, 1.15
Econ.IncomeTier = 5
Econ.Milestones = { 25, 50, 100, 200, 300, 400 } -- x2 at each
Econ.StartOwned = { 1 } -- the asteroid already orbits at 0 s (design: tutorial "0 s")

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

local function milestone(owned: number): number
	local m = 1
	for _, at in ipairs(Econ.Milestones) do
		if owned >= at then m *= 2 end
	end
	return m
end
Econ.Milestone = milestone
-- k is 0-based (Asteroid = 0)
function Econ.Cost(k: number, owned: number): number
	return Econ.CostBase * Econ.CostTier ^ k * Econ.CostGrowth ^ owned
end
function Econ.TierIncome(k: number, owned: number): number
	return Econ.IncomeTier ^ k * owned * milestone(owned)
end
-- the next milestone at or above `owned` (for "x2 at 25")
function Econ.NextMilestone(owned: number): number?
	for _, at in ipairs(Econ.Milestones) do
		if owned < at then return at end
	end
	return nil
end
-- a body's TIER = the milestones it has passed (the island boards show "TIER 2 [SILVER]", like Regrowth's machine tiers)
Econ.MilestoneNames = { [0] = "NO TIER", "BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND", "COSMIC" }
function Econ.MilestoneTier(owned: number): number
	local t = 0
	for _, at in ipairs(Econ.Milestones) do
		if owned >= at then t += 1 end
	end
	return t
end

------------------------------------------------------------------------ ring 1 (ONE table: the Upgrades window reads it for
-- the friends test, the Constellation Tree (T) reads the same table from the alpha; owner 2 Nov)
-- effect kinds: tierMult (tier k earns x mult), unlockTier (opens tier k), allMult (every body x mult),
-- cometEvery (a comet every n s)
-- tab = where the Upgrades window shows it (friends test); requires = the node before it
Econ.Ring1 = {
	{ id = "FirstLight", name = "FIRST LIGHT", cost = 0, tab = "STARDUST", icon = "sun",
		desc = "asteroids earn x2", effect = { kind = "tierMult", tier = 0, mult = 2 } },
	{ id = "LunarPull", name = "LUNAR PULL", cost = 80, tab = "PLANETS", icon = "moon",
		desc = "unlocks the Moon", effect = { kind = "unlockTier", tier = 1 } },
	{ id = "PlanetSeed", name = "PLANET SEED", cost = 640, tab = "PLANETS", icon = "planet", requires = "LunarPull",
		desc = "unlocks the Planet", effect = { kind = "unlockTier", tier = 2 } },
	{ id = "GasGiant", name = "GAS GIANT", cost = 5120, tab = "PLANETS", icon = "gasgiant", requires = "PlanetSeed",
		desc = "unlocks the Gas Giant", effect = { kind = "unlockTier", tier = 3 } },
	-- PROPOSED (calc, Calc\ring1.py, 2 Nov): priced by the payback rule, then x0.5 so ring 1 rebuys in ~2 min after Supernova 1
	{ id = "OrbitSpeed", name = "ORBIT SPEED", cost = 55000, tab = "STARDUST", icon = "planet",
		desc = "every body earns x1.5", effect = { kind = "allMult", mult = 1.5 } },
	{ id = "CometLure", name = "COMET LURE", cost = 80000, tab = "COMETS", icon = "comet",
		desc = "comets every 30 s (was 45 s)", effect = { kind = "cometEvery", seconds = 30 } },
	-- PROPOSED (calc, Calc\ring2.py, 3 Nov): ~60 s of late run-1 income; spending never lowers "earned this run"
	{ id = "SupernovaReadiness", name = "READINESS", cost = 400000, tab = "STARDUST", icon = "shard",
		desc = "+20% shards at this Supernova", effect = { kind = "shardBonus", pct = 20 } },
	-- (Milestone Hunter: not priced yet, not in the alpha)
}
Econ.Ring1ById = {}
for _, n in ipairs(Econ.Ring1) do Econ.Ring1ById[n.id] = n end

------------------------------------------------------------------------ ring 2: SHARDS (design section 2, the STELLAR branch in the
-- alpha; permanent until the Black Hole). costs[level] = the shards for that level. PROPOSED (calc, Calc\ring2.py, 3 Nov): each
-- buy priced so the build is worth ~x(1 + 0.1 * shards spent) (the design's rule); the two tier unlocks have a floor (3 / 5).
-- novas = the Supernovas you need first; requires = the node before it
Econ.Ring2 = {
	-- (alpha 2, 3 Nov: x1.5 -> x1.75 a level, so the second run is ~2x faster)
	{ id = "Starfire", name = "STARFIRE", icon = "sun", costs = { 5, 8, 15, 25, 40 },
		desc = "every body earns x1.75 a level", effect = { kind = "allMult", mult = 1.75 } },
	{ id = "StarTier", name = "STAR", icon = "sun", costs = { 3 }, novas = 1,
		desc = "unlocks the Star", effect = { kind = "unlockTier", tier = 4 } },
	{ id = "HeavyElements", name = "HEAVY ELEMENTS", icon = "gasgiant", costs = { 20 }, requires = "StarTier",
		desc = "each tier earns x(1 + 0.25 x its number)", effect = { kind = "heavy", per = 0.25 } },
	{ id = "BinaryStar", name = "BINARY STAR", icon = "sun", costs = { 5 }, novas = 3, requires = "StarTier",
		desc = "unlocks the Binary Star", effect = { kind = "unlockTier", tier = 5 } },
}
Econ.Ring2ById = {}
for _, n in ipairs(Econ.Ring2) do Econ.Ring2ById[n.id] = n end
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
function Econ.TierIncomeWith(k: number, owned: number, nodes, r2): number
	local inc = Econ.TierIncome(k, owned)
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "tierMult" and n.effect.tier == k then inc *= n.effect.mult end
	end
	if ((r2 or {}).HeavyElements or 0) >= 1 then inc *= 1 + Econ.Ring2ById.HeavyElements.effect.per * (k + 1) end
	return inc
end
-- every body x: ring 1's allMult nodes x Starfire (x1.75 a level)
function Econ.AllMult(nodes, r2): number
	local m = 1
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "allMult" then m *= n.effect.mult end
	end
	local sf = (r2 or {}).Starfire or 0
	if sf > 0 then m *= Econ.Ring2ById.Starfire.effect.mult ^ sf end
	return m
end
function Econ.Income(owned, nodes, r2): number
	local total = 0
	for k = 0, #Econ.Tiers - 1 do
		if (owned[k + 1] or 0) > 0 then total += Econ.TierIncomeWith(k, owned[k + 1], nodes, r2) end
	end
	return total * Econ.AllMult(nodes, r2)
end
function Econ.CometEvery(nodes): number
	local every = Econ.Comet.Every
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
	FirstDelay = 20,     -- the first regular comet after the tutorial
	MinEvery = 15,       -- the floor (3 Nov): never more than one comet per 15 s, whatever stacks (Lure + x2 COMETS = 15)
}

------------------------------------------------------------------------ Supernova (design section 1: needs 1M stardust EARNED this run;
-- shards = floor(10 * sqrt(earned / 1M)), +20% with Supernova Readiness). Resets stardust, bodies (the asteroid stays), ring 1.
-- Keeps shards, ring 2, the Supernova count + rank, Essence, the tutorial, the island's pieces.
-- (alpha 2, 3 Nov: the need 1M -> 2M for a ~10 min first run; the shards formula stays on 1M, so the first gives 14)
Econ.SupernovaNeed = 2e6
Econ.ShardBase = 1e6
function Econ.ShardsFor(earned: number, nodes): number
	if earned < Econ.SupernovaNeed then return 0 end
	local base = 10 * math.sqrt(earned / Econ.ShardBase)
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "shardBonus" then base *= 1 + n.effect.pct / 100 end
	end
	return math.floor(base + 1e-9)
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
Econ.Tutorial = {
	{ id = "BuyAsteroid", hint = "Buy an asteroid", essence = 1 },
	{ id = "FirstLight", hint = "Get FIRST LIGHT (free)", essence = 1 },
	{ id = "FirstMoon", hint = "Get your first Moon", essence = 1 },
	{ id = "Comet", hint = "Tap the comet!", essence = 1 },
	-- (design steps 5-7, alpha part 1): the SUPERNOVA goal bar to 50%, the Supernova itself, the first ring-2 node
	{ id = "HalfSupernova", hint = "Grow to 50% SUPERNOVA", essence = 1 },
	{ id = "Supernova", hint = "Go SUPERNOVA!", essence = 1 },
	{ id = "Starfire", hint = "Spend shards: STARFIRE", essence = 1 },
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
