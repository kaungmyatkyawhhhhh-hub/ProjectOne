-- EconConfig (Galaxy Incremental, friends test 8 Nov): every number of the first 15 minutes, from the design note
-- "2026-11-01 Supernova Incremental - Full game design" section 1 (bodies) and the owner's ring-1 rules (2 Nov,
-- Calc\ring1.py). Server and client both read it; nothing else holds an economy number.
local Econ = {}

Econ.DataVersion = 1 -- the save's version (bump + migrate in GalaxyEconService when the save's shape changes)

------------------------------------------------------------------------ bodies (design: section 1, formulas)
-- cost = 10 * 8^k * 1.15^owned; income = 5^k * owned * milestone per second (k = tier 0..7)
Econ.CostBase, Econ.CostTier, Econ.CostGrowth = 10, 8, 1.15
Econ.IncomeTier = 5
Econ.Milestones = { 25, 50, 100, 200, 300, 400 } -- x2 at each
Econ.StartOwned = { 1 } -- the asteroid already orbits at 0 s (design: tutorial "0 s")

-- the tiers in the friends test (Star .. Quasar come with Supernova / Black Hole; shown locked)
Econ.Tiers = {
	{ id = "Asteroid", name = "ASTEROID", icon = "asteroid", colour = Color3.fromRGB(196, 178, 204) },
	{ id = "Moon", name = "MOON", icon = "moon", colour = Color3.fromRGB(206, 222, 255), unlock = "LunarPull" },
	{ id = "Planet", name = "PLANET", icon = "planet", colour = Color3.fromRGB(180, 155, 255), unlock = "PlanetSeed" },
	{ id = "GasGiant", name = "GAS GIANT", icon = "gasgiant", colour = Color3.fromRGB(255, 176, 96), unlock = "GasGiant" },
	{ id = "Star", name = "STAR", icon = "sun", colour = Color3.fromRGB(255, 200, 90), lockedText = "SUPERNOVA 1" },
}
Econ.PlayableTiers = 4 -- Asteroid .. Gas Giant

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
	-- (Milestone Hunter, Supernova Readiness: not priced yet, not in the friends test)
}
Econ.Ring1ById = {}
for _, n in ipairs(Econ.Ring1) do Econ.Ring1ById[n.id] = n end

-- shared by the server (what you earn) and the window (what it shows): owned = { [1] = asteroids, ... }, nodes = { id = true }
function Econ.Unlocked(k: number, nodes): boolean
	if k == 0 then return true end
	if k >= Econ.PlayableTiers then return false end
	for _, n in ipairs(Econ.Ring1) do
		if n.effect.kind == "unlockTier" and n.effect.tier == k then return nodes[n.id] == true end
	end
	return false
end
-- tier k's income with its node multipliers (not the all-bodies ones)
function Econ.TierIncomeWith(k: number, owned: number, nodes): number
	local inc = Econ.TierIncome(k, owned)
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "tierMult" and n.effect.tier == k then inc *= n.effect.mult end
	end
	return inc
end
function Econ.AllMult(nodes): number
	local m = 1
	for _, n in ipairs(Econ.Ring1) do
		if nodes[n.id] and n.effect.kind == "allMult" then m *= n.effect.mult end
	end
	return m
end
function Econ.Income(owned, nodes): number
	local total = 0
	for k = 0, Econ.PlayableTiers - 1 do
		if (owned[k + 1] or 0) > 0 then total += Econ.TierIncomeWith(k, owned[k + 1], nodes) end
	end
	return total * Econ.AllMult(nodes)
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
}

------------------------------------------------------------------------ Supernova (design: needs 1M stardust earned this run)
Econ.SupernovaNeed = 1e6

------------------------------------------------------------------------ tutorial (design steps 1-4; Regrowth lesson: Essence
-- per step + a step counter). Friends test: "1/4".."4/4", 1 Essence each, then TUTORIAL COMPLETE (owner 2 Nov)
Econ.Tutorial = {
	{ id = "BuyAsteroid", hint = "Buy an asteroid", essence = 1 },
	{ id = "FirstLight", hint = "Get FIRST LIGHT (free)", essence = 1 },
	{ id = "FirstMoon", hint = "Get your first Moon", essence = 1 },
	{ id = "Comet", hint = "Tap the comet!", essence = 1 },
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
