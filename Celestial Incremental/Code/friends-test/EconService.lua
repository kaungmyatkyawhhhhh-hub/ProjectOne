-- GalaxyEconService (Galaxy Incremental, friends test 8 Nov): the first 15 minutes, server side.
--  * the save (DataStore, data version Econ.DataVersion, a session lock, autosave every 60 s + on leave + on shutdown;
--    Studio uses separate "studio_" keys so tests never touch real saves)
--  * Stardust income every tick from the bodies you own (EconConfig formulas), buying bodies + ring-1 nodes
--  * comets: the SERVER decides when one appears (every 45 s, 30 s with Comet Lure) and pays 30-60 s of income when the
--    client catches that comet in time (a client can't make up comets)
--  * tutorial steps 1-7: each pays 1 Essence (step counter "n/7"), logged to the onboarding funnel
--  * THE SUPERNOVA (alpha part 1): "Supernova" when 1M stardust was earned this run -> shards (EconConfig.ShardsFor), the
--    Supernova count + 1; resets stardust, bodies (the asteroid stays) and ring 1; keeps shards, ring 2, Essence, the
--    tutorial. The client plays the wind-up first and asks at the impact; the map / Star Surge see the count go up.
--  * RING 2 (shards): "BuyRing2", id -> the node's next level (EconConfig.Ring2: costs, the Supernovas it needs, requires)
--  * analytics (overnight part 5): onboarding funnel 1-7, custom events "Supernova" (value = the count, shards in
--    field 1), "Ring2Buy" (value = the level, node in field 1), "PotionUsed", "SessionMinutes" (5 / 15 / 30);
--    GalaxyCodeService "CodeRedeemed", GalaxyStoreService "PassPromptShown" / "PassBought"
--  * alpha part 2: "Settings", { music, sfx } (the Settings sliders, 0..1 -> VolMusic / VolSfx) and "GuideSeen", id (the
--    GUIDE BOOK pages you've opened -> GuideSeen, comma-separated); both in the save
--  * the player attributes the map reads: Bodies, BodyTiers, Supernovas, Rank, SupernovaReady, BestRunStardust,
--    Tree_CometLure, CometsCaught; and the ones the HUD reads: Stardust, Income, EarnedRun, Essence, TutStep, Own1..,
--    Node_<id>, Loaded
-- Studio test switch: Workspace attribute TestFreshSave = true -> every player starts on a NEW save that is never written
-- (the tutorial / tier 0 test; the Studio save stays as it was). Workspace TestGiveStardust = n -> every player gets n
-- stardust EARNED (counts for the Supernova; for screenshots, never in the pace test).
-- Remotes (ReplicatedStorage.Galaxy): EconRequest (RemoteFunction: "BuyBody" / "BuyBody10" / "BuyBodyMax", k (+1 / 10 / max LEVELS) /
-- "BuyCopy", k (+BODY) / "BuyNode", id /
-- "BuyRing2", id / "Supernova"; + the island slot from a board), EconEvent (server ->
-- client: "TutorialStep", step, essence / "Bought", kind, what / "CometPaid", id, value), MapEvent ("CometSpawn" to the
-- client; the client answers "Comet", id).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))

local function remoteOf(class: string, name: string)
	local r = Galaxy:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = Galaxy
	end
	return r
end
local request = remoteOf("RemoteFunction", "EconRequest") :: RemoteFunction
local event = remoteOf("RemoteEvent", "EconEvent") :: RemoteEvent
local mapEvent = remoteOf("RemoteEvent", "MapEvent") :: RemoteEvent

local IS_STUDIO = RunService:IsStudio()
local okStore, store = pcall(function() return DataStoreService:GetDataStore("GalaxySave1") end)
if not okStore then store = nil end
local function keyOf(player: Player): string
	return (if IS_STUDIO then "studio_u_" else "u_") .. player.UserId
end

local sessions = {} -- [Player] = { d = data, pending = {[id] = clock}, cometId, nextComet, readOnly, noSave, dirty }
-- (other server scripts reach the sessions, publish and save through this module: GalaxyCodeService)
local Shared = require(game:GetService("ServerStorage"):WaitForChild("GalaxyEconShared"))
Shared.sessions = sessions

------------------------------------------------------------------------ data
local function newData()
	local owned, copies = {}, {}
	for i = 1, #Econ.Tiers do
		owned[i] = Econ.StartOwned[i] or 0
		copies[i] = if owned[i] > 0 then 1 else 0
	end
	return { v = Econ.DataVersion, stardust = 0, earnedRun = 0, earnedTotal = 0, bestRun = 0, owned = owned, copies = copies, nodes = {},
		essence = 0, tut = 0, supernovas = 0, comets = 0, shards = 0, shardsEarned = 0, ring2 = {}, settings = {}, guide = {},
		codes = {}, potions = {}, boostLeft = {}, alphaPlayer = false, alphaBadge = false, pads = 0,
		xp = Econ.XP.Start, xpTotal = Econ.XP.Start, perks = {}, ignition = 0, path = "",
		forge = { cores = {}, equipped = {}, rolls = 0, pityL = 0, pityM = 0 } }
end
-- forward-safe: fills what an older save doesn't have; a NEWER save (from a newer server) is never overwritten
local function migrate(d): (any, boolean)
	if type(d) ~= "table" then return newData(), false end
	if (tonumber(d.v) or 0) > Econ.DataVersion then return d, true end
	local oldV = tonumber(d.v) or 0
	local base = newData()
	for k, v in pairs(base) do
		if d[k] == nil then d[k] = v end
	end
	if type(d.owned) ~= "table" then d.owned = base.owned end
	for i = 1, #Econ.Tiers do d.owned[i] = math.max(0, math.floor(tonumber(d.owned[i]) or 0)) end
	-- v3 (feel pass, 5 Nov): owned = LEVELS + copies. An old owned count n -> level n (max 60), 1 + n/25 copies (max 5)
	if type(d.copies) ~= "table" then d.copies = {} end
	if oldV < 3 then
		-- (the island grew by itself before: give the pads that build the pieces it had, so it never shrinks)
		local oldBodies = 0
		for i = 1, #Econ.Tiers do oldBodies += d.owned[i] end
		d.pads = ({ 0, 2, 3, 4, 6, 8, 10 })[MapConfig.TierOf(oldBodies, tonumber(d.supernovas) or 0) + 1] or 10
		-- the ring-1 multipliers became PERKS: what you bought becomes perk levels worth the same; XP for the Supernovas done
		local nodes = if type(d.nodes) == "table" then d.nodes else {}
		local perks = {}
		if nodes.FirstLight then perks.FirstLight = 2 end
		if nodes.OrbitSpeed then perks.OrbitSpeed = 10 end
		if nodes.CometLure then perks.CometLure = 8 end
		if nodes.SupernovaReadiness then perks.Readiness = 10 end
		d.perks = perks
		for _, id in ipairs({ "FirstLight", "OrbitSpeed", "CometLure", "SupernovaReadiness" }) do nodes[id] = nil end
		d.xp = Econ.XP.Start + 50 * (tonumber(d.supernovas) or 0)
		d.xpTotal = d.xp
		-- (the old tutorial had 7 steps: finished = Tutorial 2 done too; else it starts again and skips past what you have)
		d.tut = if (tonumber(d.tut) or 0) >= 7 then #Econ.Tutorial else 0
	end
	if type(d.path) ~= "string" then d.path = "" end
	-- the Forge: only known cores, levels 1..max; equipped = known keys you own, at most Slots
	local f = if type(d.forge) == "table" then d.forge else {}
	local cores, eq = {}, {}
	if type(f.cores) == "table" then
		for key, lv in pairs(f.cores) do
			local k, r = string.match(tostring(key), "^(%a+):(%a+)$")
			if k and Econ.ForgeKindById[k] and Econ.ForgeRarityById[r] then cores[key] = math.clamp(math.floor(tonumber(lv) or 1), 1, Econ.Forge.MaxLevel) end
		end
	end
	if type(f.equipped) == "table" then
		for _, key in ipairs(f.equipped) do
			if cores[key] and #eq < Econ.Forge.Slots and not table.find(eq, key) then table.insert(eq, key) end
		end
	end
	d.forge = { cores = cores, equipped = eq, rolls = math.max(0, math.floor(tonumber(f.rolls) or 0)),
		pityL = math.max(0, math.floor(tonumber(f.pityL) or 0)), pityM = math.max(0, math.floor(tonumber(f.pityM) or 0)) }
	-- perks: only known ones, whole levels 0..max
	local pk = {}
	if type(d.perks) == "table" then
		for _, p in ipairs(Econ.Perks) do
			local lv = math.floor(tonumber(d.perks[p.id]) or 0)
			if lv > 0 then pk[p.id] = math.min(lv, Econ.PerkMax) end
		end
	end
	d.perks = pk
	for i = 1, #Econ.Tiers do
		if oldV < 3 then
			local n = d.owned[i]
			d.owned[i] = math.min(n, 60)
			d.copies[i] = if n > 0 then math.min(1 + n // 25, Econ.MaxCopies) else 0
		end
		d.copies[i] = math.clamp(math.floor(tonumber(d.copies[i]) or 0), 0, Econ.MaxCopies)
		if d.owned[i] > 0 and d.copies[i] == 0 then d.copies[i] = 1 end
		if d.owned[i] == 0 then d.copies[i] = 0 end
	end
	for _, k in ipairs({ "stardust", "earnedRun", "earnedTotal", "bestRun", "essence", "tut", "supernovas", "comets", "shards", "shardsEarned", "pads", "xp", "xpTotal", "ignition" }) do
		local n = tonumber(d[k]) or 0
		d[k] = if n == n and n ~= math.huge then n else 0
	end
	-- v2: ring 2 levels (only known nodes, whole numbers within their level count)
	local r2 = {}
	if type(d.ring2) == "table" then
		for _, n in ipairs(Econ.Ring2) do
			local lv = math.floor(tonumber(d.ring2[n.id]) or 0)
			if lv > 0 then r2[n.id] = math.min(lv, #n.costs) end
		end
	end
	d.ring2 = r2
	-- (alpha part 2: settings + guide pages; no version bump, an older save just gets them empty)
	if type(d.settings) ~= "table" then d.settings = {} end
	if type(d.guide) ~= "table" then d.guide = {} end
	-- (overnight part 2: codes used, potions owned, boost seconds left; only known potions, whole / finite numbers)
	if type(d.codes) ~= "table" then d.codes = {} end
	local pots, left = {}, {}
	for _, p in ipairs(Econ.Potions) do
		local n = math.floor(tonumber(type(d.potions) == "table" and d.potions[p.id]) or 0)
		if n > 0 and n < 1e6 then pots[p.id] = n end
		local l = tonumber(type(d.boostLeft) == "table" and d.boostLeft[p.id]) or 0
		if l > 0 and l < 1e7 then left[p.id] = l end
	end
	d.potions, d.boostLeft = pots, left
	d.v = Econ.DataVersion
	return d, false
end

local LOCK_STALE = 150 -- seconds: a lock older than this is from a server that died
local function load(player: Player): (any, boolean, boolean) -- data, readOnly, noSave
	if not store then return newData(), false, true end
	if IS_STUDIO and workspace:GetAttribute("TestFreshSave") == true then return newData(), false, true end
	local key = keyOf(player)
	for attempt = 1, 6 do
		local result, lockedElsewhere
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old)
				if type(old) == "table" and type(old.lock) == "table" and old.lock.job ~= game.JobId
					and os.time() - (tonumber(old.lock.t) or 0) < LOCK_STALE and attempt < 6 then
					lockedElsewhere = true
					return nil -- don't write: another server still has this save open
				end
				local d = if type(old) == "table" then old.data else nil
				result = d
				return { data = d or newData(), lock = { job = game.JobId, t = os.time() } }
			end)
		end)
		if ok and not lockedElsewhere then
			local d, readOnly = migrate(result)
			return d, readOnly, false
		end
		if not ok then
			warn("[GalaxyEcon] load failed for", player.Name, err)
			if IS_STUDIO and tostring(err):find("access", 1, true) then return newData(), false, true end
		end
		task.wait(if lockedElsewhere then 5 else 2)
		if not player.Parent then return nil, true, true end
	end
	return nil, true, true
end

local function save(player: Player, release: boolean)
	local s = sessions[player]
	if not s or s.noSave or s.readOnly or not store then return end
	local data = s.d
	local ok, err = pcall(function()
		store:UpdateAsync(keyOf(player), function(old)
			if type(old) == "table" and type(old.lock) == "table" and old.lock.job ~= game.JobId
				and os.time() - (tonumber(old.lock.t) or 0) < LOCK_STALE then
				return nil -- another server took this save over: don't overwrite it
			end
			return { data = data, lock = if release then nil else { job = game.JobId, t = os.time() } }
		end)
	end)
	if not ok then warn("[GalaxyEcon] save failed for", player.Name, err) end
end

------------------------------------------------------------------------ the economy
local function unlocked(s, k: number): boolean
	return Econ.Unlocked(k, s.d.nodes, s.d.ring2)
end
-- STAR SURGE (GalaxyStarSurgeService): x2 stardust for everyone while it runs
local function surgeMult(): number
	return if workspace:GetServerTimeNow() < (Galaxy:GetAttribute("SurgeUntil") or 0) then MapConfig.Surge.Mult else 1
end
-- the boosts running for this player (potions)
local function boosting(s, id: string): boolean
	return (s.d.boostLeft[id] or 0) > 0
end
-- (the x2 STARDUST pass: s.passX2, set by GalaxyStoreService)
-- Boosts of the same kind ADD, they don't multiply (#69): Star Surge, the x2 STARDUST potion and the pass are each +1x,
-- so pass + potion = x3 and all three = x4 (never x8). Upgrades (ring 1, ring 2, milestones) still multiply inside Econ.Income.
-- (the SURGE POWER perk makes the Star Surge's part stronger for you)
local function stardustBoost(s): number
	local surge = (surgeMult() - 1) * (1 + Econ.PerksById.SurgePower.per * Econ.PerkLv(s.d.perks, "SurgePower"))
	return 1 + surge + (if boosting(s, "Stardust") then 1 else 0) + (if s.passX2 then 1 else 0)
end
local function forgeOf(s, kind: string): number
	return Econ.ForgeEffect(s.d.forge.equipped, s.d.forge.cores, kind)
end
local function incomeOf(s): number
	local d = s.d
	local path = if d.path == "Planet" then 1.5 else 1
	local base = Econ.Income(d.owned, d.copies, d.nodes, d.ring2, d.perks)
	-- (the GIANT core: the gas giants' share x its power)
	local giant = forgeOf(s, "Giant")
	if giant > 1 and d.owned[4] > 0 then
		base += Econ.TierIncomeWith(3, d.owned[4], math.max(d.copies[4], 1), d.nodes, d.ring2, d.perks) * Econ.AllMult(d.nodes, d.ring2, d.perks) * (giant - 1)
	end
	return base * Econ.PadMult(d.pads, d.perks) * path * forgeOf(s, "Stardust") * stardustBoost(s)
end
local function shardsOf(s): number
	return math.floor(Econ.ShardsFor(s.d.earnedRun, s.d.nodes, s.d.supernovas, s.d.perks) * forgeOf(s, "Shards"))
end
local function cometEvery(s): number
	local path = if s.d.path == "Comet" then 0.8 else 1
	-- (Tutorial 2: run 1 only, comets every ~20 s)
	local base = if s.d.supernovas == 0 then math.min(Econ.Comet.RunOneEvery, Econ.CometEvery(s.d.nodes, s.d.perks)) else Econ.CometEvery(s.d.nodes, s.d.perks)
	return math.max(Econ.Comet.MinEvery, base * path / (if boosting(s, "Comets") then 2 else 1))
end

-- everything the HUD and the map read
local function publish(player: Player, s)
	local d = s.d
	player:SetAttribute("Stardust", d.stardust)
	player:SetAttribute("Income", incomeOf(s))
	player:SetAttribute("EarnedRun", d.earnedRun)
	player:SetAttribute("Essence", d.essence)
	player:SetAttribute("TutStep", d.tut)
	-- Own<k> = the body type's LEVEL (0 = not unlocked), Copies<k> = its copies; Bodies = all copies; Sys = what the map draws
	-- ("namedTier:copies," per type, only changes on a new tier / copy / type, so the system isn't rebuilt every level)
	local bodies, tiers, sys = 0, 0, {}
	for k = 1, #Econ.Tiers do
		player:SetAttribute("Own" .. k, d.owned[k])
		player:SetAttribute("Copies" .. k, d.copies[k])
		bodies += d.copies[k]
		if d.owned[k] > 0 then tiers += 1 end
		table.insert(sys, (if d.owned[k] > 0 then Econ.NamedTier(d.owned[k]) else 0) .. ":" .. d.copies[k])
	end
	player:SetAttribute("Sys", table.concat(sys, ","))
	player:SetAttribute("Pads", math.clamp(math.floor(d.pads), 0, #Econ.Pads))
	for _, n in ipairs(Econ.Ring1) do player:SetAttribute("Node_" .. n.id, d.nodes[n.id] == true) end
	for _, n in ipairs(Econ.Ring2) do player:SetAttribute("R2_" .. n.id, d.ring2[n.id] or 0) end
	player:SetAttribute("Shards", d.shards)
	player:SetAttribute("ShardsEarned", d.shardsEarned)
	player:SetAttribute("SupernovaShards", shardsOf(s))
	player:SetAttribute("SupernovaNeed", Econ.NeedFor(d.supernovas))
	-- the map
	player:SetAttribute("Bodies", bodies)
	player:SetAttribute("BodyTiers", tiers)
	player:SetAttribute("Supernovas", d.supernovas)
	-- the COSMIC LEVEL (XP spent on perks never lowers it) and the rank = its name + the Supernovas ("FLARE III · ✦12")
	local level = Econ.LevelOf(d.xpTotal)
	player:SetAttribute("XP", d.xp)
	player:SetAttribute("XPTotal", d.xpTotal)
	player:SetAttribute("CosmicLevel", level)
	player:SetAttribute("Rank", Econ.RankText(level, d.supernovas))
	for _, p in ipairs(Econ.Perks) do player:SetAttribute("Perk_" .. p.id, d.perks[p.id] or 0) end
	-- PURPOSE: the best named tier of a body this run (the Ignition's "a body at IRON"), Ignition, the path, GALAXY LIT %
	local best = 0
	for k = 1, #Econ.Tiers do if d.owned[k] > 0 then best = math.max(best, Econ.NamedTier(d.owned[k])) end end
	player:SetAttribute("BestTier", best)
	player:SetAttribute("Ignition", d.ignition)
	player:SetAttribute("Path", d.path)
	player:SetAttribute("GalaxyLit", Econ.GalaxyLit(d.pads, d.supernovas, level, d.ignition))
	-- the Forge (one JSON attribute: your cores, the equipped ones, the pity counters)
	player:SetAttribute("Forge", HttpService:JSONEncode(d.forge))
	player:SetAttribute("SupernovaReady", d.earnedRun >= Econ.NeedFor(d.supernovas))
	player:SetAttribute("BestRunStardust", math.max(d.bestRun, d.earnedRun))
	player:SetAttribute("Tree_CometLure", if (d.perks.CometLure or 0) > 0 then 1 else 0)
	player:SetAttribute("CometsCaught", d.comets)
	if type(d.settings.music) == "number" then player:SetAttribute("VolMusic", d.settings.music) end
	if type(d.settings.sfx) == "number" then player:SetAttribute("VolSfx", d.settings.sfx) end
	-- potions: how many you have, and when each running boost ends (server time; the HUD counts down)
	for _, p in ipairs(Econ.Potions) do
		player:SetAttribute("Potion_" .. p.id, d.potions[p.id] or 0)
		local left = d.boostLeft[p.id] or 0
		player:SetAttribute("BoostEnd_" .. p.id, if left > 0 then workspace:GetServerTimeNow() + left else 0)
	end
	local seen = {}
	for id in pairs(d.guide) do table.insert(seen, id) end
	table.sort(seen)
	player:SetAttribute("GuideSeen", table.concat(seen, ","))
	if s.d.ignition < 1 and Shared.checkIgnition then task.defer(Shared.checkIgnition, player, s) end
	-- (Tutorial 2: the live values of the goal counters the card shows)
	player:SetAttribute("SupernovaPct", if d.supernovas >= 1 then 100 else math.floor(d.earnedRun / Econ.NeedFor(d.supernovas) * 100))
end
-- IGNITION 1: every item of MapConfig.Ignition met at once -> the sector lights up (once ever): Essence, Sector 2 opens
local function checkIgnition(player: Player, s)
	local d = s.d
	if d.ignition >= 1 then return end
	local done, total = MapConfig.IgnitionDone(player)
	if done < total then return end
	d.ignition = 1
	d.essence += Econ.IgnitionEssence
	player:SetAttribute("Ignition", 1)
	player:SetAttribute("Essence", d.essence)
	player:SetAttribute("GalaxyLit", Econ.GalaxyLit(d.pads, d.supernovas, Econ.LevelOf(d.xpTotal), 1))
	event:FireClient(player, "Ignition", 1, Econ.IgnitionEssence)
	pcall(function() AnalyticsService:LogCustomEvent(player, "Ignition", 1) end)
	task.spawn(save, player, false)
end
Shared.checkIgnition = checkIgnition
local GUIDE_PAGES = { Stardust = true, Island = true, Tree = true, Comets = true, Supernova = true, Surge = true, Ranks = true }

------------------------------------------------------------------------ tutorial
-- a step's live value, from the save (the same numbers the attributes show; `attr` names them)
local function tutValue(s, attr: string): number
	local d = s.d
	local k = tonumber(string.match(attr, "^Own(%d)$"))
	if k then return d.owned[k] or 0 end
	k = tonumber(string.match(attr, "^Copies(%d)$"))
	if k then return d.copies[k] or 0 end
	if attr == "Pads" then return d.pads end
	if attr == "CometsCaught" then return d.comets end
	if attr == "CosmicLevel" then return Econ.LevelOf(d.xpTotal) end
	if attr == "Supernovas" then return d.supernovas end
	if attr == "Ignition" then return d.ignition end
	if attr == "SupernovaPct" then return if d.supernovas >= 1 then 100 else math.floor(d.earnedRun / Econ.NeedFor(d.supernovas) * 100) end
	local p = string.match(attr, "^Perk_(%a+)$")
	if p then return d.perks[p] or 0 end
	local r = string.match(attr, "^R2_(%a+)$")
	if r then return d.ring2[r] or 0 end
	return 0
end
local function checkTutorial(player: Player, s)
	local d = s.d
	local paid = false
	while d.tut < #Econ.Tutorial and tutValue(s, Econ.Tutorial[d.tut + 1].attr) >= Econ.Tutorial[d.tut + 1].need do
		d.tut += 1
		local step = Econ.Tutorial[d.tut]
		d.essence += step.essence
		-- (the payout: ~20 s of your income in stardust, so every step feels like a reward. Spending money only: it does NOT
		-- count toward the Supernova, and steps done together pay once, so the curve stays as tuned)
		local pay = if paid then 0 else math.max(10, incomeOf(s) * Econ.TutorialStardustSec)
		paid = true
		d.stardust += pay
		player:SetAttribute("Stardust", d.stardust)
		pcall(function() AnalyticsService:LogOnboardingFunnelStepEvent(player, d.tut, step.id) end)
		event:FireClient(player, "TutorialStep", d.tut, step.essence, pay)
		-- (the step and the Essence show at once, whoever called this)
		player:SetAttribute("TutStep", d.tut)
		player:SetAttribute("Essence", d.essence)
	end
end

------------------------------------------------------------------------ comets
local function spawnComet(player: Player, s, tutorial: boolean)
	-- (the floor: never two comets within Econ.Comet.MinEvery s, whatever moved nextComet)
	if s.lastComet and os.clock() - s.lastComet < Econ.Comet.MinEvery then return end
	s.lastComet = os.clock()
	s.cometId += 1
	-- (run 1 only: 1 in 10 is GOLDEN, x5; never the tutorial's own comets)
	local golden = not tutorial and s.d.supernovas == 0 and math.random() < Econ.Comet.Golden
	s.pending[s.cometId] = os.clock()
	if golden then s.golden = s.golden or {} s.golden[s.cometId] = true end
	mapEvent:FireClient(player, "CometSpawn", s.cometId, math.random(1, 2 ^ 30), tutorial, golden)
end
local function cometLoop(player: Player, s)
	while sessions[player] == s do
		local tut = s.d.tut
		if tut < 5 then
			task.wait(1) -- (no comets during tutorial steps 1-5: nothing stacked on a hint)
		elseif tut == 5 then
			-- step 6: the tutorial comets, again every 15 s (the floor) until 2 are caught
			task.wait(2.5)
			if sessions[player] ~= s or s.d.tut ~= 5 then continue end
			spawnComet(player, s, true)
			for _ = 1, Econ.Comet.MinEvery - 2 do -- (2.5 + 13 s: just over the floor)
				task.wait(1)
				if sessions[player] ~= s or s.d.tut ~= 5 then break end
			end
		else
			s.nextComet = s.nextComet or (os.clock() + Econ.Comet.FirstDelay)
			if os.clock() >= s.nextComet and not (s.lastComet and os.clock() - s.lastComet < Econ.Comet.MinEvery) then
				spawnComet(player, s, false)
				s.nextComet = os.clock() + cometEvery(s)
			end
			task.wait(1)
		end
	end
end

------------------------------------------------------------------------ requests
local lastReq = {}
-- a buy from an island BOARD (arg 3 = the island slot): only the island's owner, standing within MapConfig.Boards.BuyRange
-- of the island's centre, i.e. on the island (the 2D window, hotbar U, sends no slot and works anywhere)
local function boardAllowed(player: Player, slot): boolean
	if type(slot) ~= "number" or slot ~= slot or player:GetAttribute("Island") ~= slot then return false end
	local islands = workspace:FindFirstChild("Galaxy") and workspace.Galaxy:FindFirstChild("Islands")
	local island = islands and islands:FindFirstChild("Island_" .. slot)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not island or not root or island:GetAttribute("Owner") ~= player.UserId then return false end
	local c = island:GetAttribute("Center")
	return typeof(c) == "Vector3" and (root.Position - c).Magnitude <= MapConfig.Boards.BuyRange
end

request.OnServerInvoke = function(player: Player, action, arg, slot)
	local s = sessions[player]
	if not s or s.readOnly then return false, "loading" end
	if slot ~= nil and not boardAllowed(player, slot) then return false, "board" end
	-- rate limit: 25 requests a second (hold-to-buy is ~10)
	local now = os.clock()
	local r = lastReq[player]
	if not r or now - r.t > 1 then r = { t = now, n = 0 } lastReq[player] = r end
	r.n += 1
	if r.n > 25 then return false, "slow" end
	local d = s.d
	if action == "BuyBody" or action == "BuyBody10" or action == "BuyBodyMax" then
		-- one body; BuyBody10 = up to 10 (the INFO board's 10x); BuyBodyMax = as many as you can pay for (the BODIES board's M)
		if type(arg) ~= "number" or arg ~= arg or arg % 1 ~= 0 or arg < 0 or arg >= #Econ.Tiers then return false, "bad" end
		if not unlocked(s, arg) then return false, "locked" end
		-- (feel pass: +1 LEVEL each; a Star type opened by ring 2 starts at level 0, so its first level gives it one copy)
		local most = if action == "BuyBody" then 1 elseif action == "BuyBody10" then 10 else 1000
		local got = 0
		while got < most do
			local cost = Econ.Cost(arg, d.owned[arg + 1], d.perks)
			if d.stardust < cost then break end
			d.stardust -= cost
			d.owned[arg + 1] += 1
			if d.copies[arg + 1] < 1 then d.copies[arg + 1] = 1 end
			got += 1
		end
		if got == 0 then return false, "poor" end
		checkTutorial(player, s)
		publish(player, s)
		return true, d.owned[arg + 1]
	elseif action == "BuyPad" then
		-- the next island pad (only on your island: the pad sends the slot, boardAllowed checked it above)
		if slot == nil then return false, "board" end
		local i = math.floor(d.pads) + 1
		local pad = Econ.Pads[i]
		if not pad then return false, "max" end
		if d.stardust < pad.price then return false, "poor" end
		d.stardust -= pad.price
		d.pads = i
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "PadBuy", i) end)
		return true, i
	elseif action == "ForgeRoll" then
		-- arg = 1 (ROLL) or Econ.Forge.Bulk (BULK): each roll costs RollCost Essence; the odds x your Luck cores (the
		-- rarer ones only); pity forces a Legendary / Mythic. Returns the results { "Kind:Rarity", ... }
		if d.ignition < 1 then return false, "locked" end
		local n = if arg == Econ.Forge.Bulk then Econ.Forge.Bulk else 1
		if d.essence < n * Econ.Forge.RollCost then return false, "poor" end
		d.essence -= n * Econ.Forge.RollCost
		local F = d.forge
		local luck = forgeOf(s, "Luck")
		local results = {}
		for _ = 1, n do
			F.rolls += 1
			F.pityL += 1
			F.pityM += 1
			local rarity
			if F.pityM >= Econ.Forge.PityMythic then
				rarity = "Mythic"
			elseif F.pityL >= Econ.Forge.PityLegendary then
				rarity = "Legendary"
			else
				local total = 0
				for i, r in ipairs(Econ.Forge.Rarities) do total += r.odds * (if i > 1 then luck else 1) end
				local x = math.random() * total
				for i, r in ipairs(Econ.Forge.Rarities) do
					x -= r.odds * (if i > 1 then luck else 1)
					if x <= 0 then rarity = r.id break end
				end
				rarity = rarity or "Common"
			end
			local ri = Econ.ForgeRarityById[rarity].index
			if ri >= 5 then F.pityL = 0 end
			if ri >= 6 then F.pityM = 0 end
			local kind = Econ.Forge.Kinds[math.random(1, #Econ.Forge.Kinds)].id
			local key = kind .. ":" .. rarity
			F.cores[key] = math.min((F.cores[key] or 0) + 1, Econ.Forge.MaxLevel)
			-- (a free slot takes a new core by itself)
			if #F.equipped < Econ.Forge.Slots and not table.find(F.equipped, key) then table.insert(F.equipped, key) end
			table.insert(results, key)
			-- (a CELESTIAL is told to the whole server: cutscene template, GLOBAL)
			if rarity == "Celestial" then event:FireAllClients("ForgeGlobal", player.DisplayName, key) end
			pcall(function() AnalyticsService:LogCustomEvent(player, "ForgeRoll", ri, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = key }) end)
		end
		publish(player, s)
		return true, results
	elseif action == "ForgeEquip" then
		-- equip / unequip one core you own (a full set: it replaces the first slot)
		if type(arg) ~= "string" or not d.forge.cores[arg] then return false, "bad" end
		local eq = d.forge.equipped
		local at = table.find(eq, arg)
		if at then
			table.remove(eq, at)
		else
			if #eq >= Econ.Forge.Slots then table.remove(eq, 1) end
			table.insert(eq, arg)
		end
		publish(player, s)
		return true
	elseif action == "SkipTutorial" then
		-- the card's SKIP (red, "not recommended"): the tutorial ends; no step rewards
		d.tut = #Econ.Tutorial
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "TutorialSkipped", 1) end)
		return true
	elseif action == "PickPath" then
		-- after Ignition 1: pick a path (free the first time; a switch costs Econ.PathSwitchShards shards)
		if d.ignition < 1 then return false, "locked" end
		local ok = false
		for _, p in ipairs(Econ.Paths) do if p.id == arg then ok = true end end
		if not ok then return false, "bad" end
		if d.path == arg then return false, "same" end
		if d.path ~= "" then
			if d.shards < Econ.PathSwitchShards then return false, "poor" end
			d.shards -= Econ.PathSwitchShards
		end
		d.path = arg
		publish(player, s)
		return true
	elseif action == "BuyPerk" then
		-- a perk level, paid in XP; its perk tier must be open (Cosmic Level)
		local perk = type(arg) == "string" and Econ.PerksById[arg]
		if not perk then return false, "bad" end
		local lv = d.perks[perk.id] or 0
		if lv >= Econ.PerkMax then return false, "max" end
		if Econ.LevelOf(d.xpTotal) < perk.opens then return false, "locked" end
		local cost = Econ.PerkCost(lv)
		if d.xp < cost then return false, "poor" end
		d.xp -= cost
		d.perks[perk.id] = lv + 1
		if perk.id == "CometLure" and s.nextComet then s.nextComet = math.min(s.nextComet, os.clock() + cometEvery(s)) end
		checkTutorial(player, s)
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "PerkBuy", lv + 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = perk.id }) end)
		return true, lv + 1
	elseif action == "BuyCopy" then
		-- +BODY: one more copy of an unlocked body type (max Econ.MaxCopies)
		if type(arg) ~= "number" or arg ~= arg or arg % 1 ~= 0 or arg < 0 or arg >= #Econ.Tiers then return false, "bad" end
		if d.owned[arg + 1] < 1 then return false, "locked" end
		local c = d.copies[arg + 1]
		if c >= Econ.MaxCopies then return false, "max" end
		local cost = Econ.CopyCost(arg, c, d.perks)
		if d.stardust < cost then return false, "poor" end
		d.stardust -= cost
		d.copies[arg + 1] = c + 1
		publish(player, s)
		return true, c + 1
	elseif action == "BuyNode" then
		local node = type(arg) == "string" and Econ.Ring1ById[arg]
		if not node then return false, "bad" end
		if d.nodes[node.id] then return false, "owned" end
		if node.requires and not d.nodes[node.requires] then return false, "locked" end
		if d.stardust < node.cost then return false, "poor" end
		d.stardust -= node.cost
		d.nodes[node.id] = true
		-- (an UNLOCK: the body type starts at level 1 with one copy)
		if node.effect.kind == "unlockTier" and d.owned[node.effect.tier + 1] < 1 then
			d.owned[node.effect.tier + 1] = 1
			d.copies[node.effect.tier + 1] = 1
		end
		if node.effect.kind == "cometEvery" and s.nextComet then
			s.nextComet = math.min(s.nextComet, os.clock() + node.effect.seconds)
		end
		checkTutorial(player, s)
		publish(player, s)
		return true
	elseif action == "BuyRing2" then
		local node = type(arg) == "string" and Econ.Ring2ById[arg]
		if not node then return false, "bad" end
		local level = d.ring2[node.id] or 0
		local cost = Econ.R2Cost(node.id, level)
		if not cost then return false, "max" end
		if d.supernovas < (node.novas or 0) then return false, "locked" end
		if node.requires and (d.ring2[node.requires] or 0) < 1 then return false, "locked" end
		if d.shards < cost then return false, "poor" end
		d.shards -= cost
		d.ring2[node.id] = level + 1
		checkTutorial(player, s)
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "Ring2Buy", level + 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = node.id }) end)
		return true, level + 1
	elseif action == "Settings" then
		if type(arg) ~= "table" then return false, "bad" end
		for _, k in ipairs({ "music", "sfx" }) do
			local v = arg[k]
			if type(v) == "number" and v == v and v >= 0 and v <= 1 then d.settings[k] = math.floor(v * 100 + 0.5) / 100 end
		end
		publish(player, s)
		return true
	elseif action == "UsePotion" then
		local p = type(arg) == "string" and Econ.PotionsById[arg]
		if not p then return false, "bad" end
		if (d.potions[p.id] or 0) < 1 then return false, "none" end
		d.potions[p.id] -= 1
		if d.potions[p.id] <= 0 then d.potions[p.id] = nil end
		d.boostLeft[p.id] = (d.boostLeft[p.id] or 0) + p.minutes * 60
		if p.id == "Comets" and s.nextComet then s.nextComet = math.min(s.nextComet, os.clock() + cometEvery(s)) end
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "PotionUsed", 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = p.id }) end)
		return true, d.boostLeft[p.id]
	elseif action == "GuideSeen" then
		if type(arg) ~= "string" or not GUIDE_PAGES[arg] then return false, "bad" end
		d.guide[arg] = true
		publish(player, s)
		return true
	elseif action == "Supernova" then
		-- (the client has played the wind-up; this is the impact)
		local got = shardsOf(s)
		if got <= 0 then return false, "notready" end
		local first = d.supernovas == 0
		d.bestRun = math.max(d.bestRun, d.earnedRun)
		d.shards += got
		d.shardsEarned += got
		d.supernovas += 1
		d.essence += Econ.SupernovaEssence
		d.stardust, d.earnedRun = 0, 0
		for i = 1, #Econ.Tiers do
			d.owned[i] = Econ.StartOwned[i] or 0
			d.copies[i] = if d.owned[i] > 0 then 1 else 0
		end
		d.nodes = {}
		checkTutorial(player, s)
		publish(player, s)
		pcall(function() AnalyticsService:LogCustomEvent(player, "Supernova", d.supernovas, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(got) }) end)
		task.spawn(save, player, false)
		return true, got, first
	end
	return false, "bad"
end

mapEvent.OnServerEvent:Connect(function(player: Player, kind, id)
	if kind ~= "Comet" then return end
	local s = sessions[player]
	if not s or type(id) ~= "number" then return end
	local born = s.pending[id]
	if not born then return end
	s.pending[id] = nil
	if os.clock() - born > Econ.Comet.Life + 1.5 then return end -- (gone)
	local value = incomeOf(s) * math.random(Econ.Comet.ValueMin, Econ.Comet.ValueMax)
		* (1 + Econ.PerksById.CometValue.per * Econ.PerkLv(s.d.perks, "CometValue")) * (if s.d.path == "Comet" then 2 else 1) * forgeOf(s, "Comets")
	if math.random() < Econ.PerksById.LuckyComet.per * Econ.PerkLv(s.d.perks, "LuckyComet") then value *= 10 end
	if s.golden and s.golden[id] then
		s.golden[id] = nil
		value *= Econ.Comet.GoldenX
	end
	s.d.stardust += value
	s.d.earnedRun += value
	s.d.earnedTotal += value
	s.d.comets += 1
	checkTutorial(player, s)
	publish(player, s)
	event:FireClient(player, "CometPaid", id, value)
end)

------------------------------------------------------------------------ players
local function onPlayer(player: Player)
	player:SetAttribute("Loaded", false)
	local d, readOnly, noSave = load(player)
	if not player.Parent then return end
	if not d then
		player:Kick("Your save couldn't be loaded right now. Please rejoin in a minute (your progress is safe).")
		return
	end
	local s = { d = d, pending = {}, cometId = 0, readOnly = readOnly, noSave = noSave }
	if readOnly then
		player:Kick("This server is older than your save. Please rejoin to get a newer server.")
		return
	end
	sessions[player] = s
	publish(player, s)
	checkTutorial(player, s)
	player:SetAttribute("Loaded", true)
	if noSave then warn("[GalaxyEcon] saving is OFF for", player.Name, "(Studio without API access, or no DataStore)") end
	task.spawn(cometLoop, player, s)
	-- session milestones (analytics custom event "SessionMinutes", value 5 / 15 / 30), once each per session
	task.spawn(function()
		local start = os.clock()
		for _, m in ipairs({ 5, 15, 30 }) do
			while sessions[player] == s and os.clock() - start < m * 60 do task.wait(5) end
			if sessions[player] ~= s then return end
			pcall(function() AnalyticsService:LogCustomEvent(player, "SessionMinutes", m) end)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(player)
	local s = sessions[player]
	if s then
		s.d.bestRun = math.max(s.d.bestRun, s.d.earnedRun)
		save(player, true)
	end
	sessions[player] = nil
	lastReq[player] = nil
end)
Shared.publish = publish
Shared.save = save

game:BindToClose(function()
	local left = 0
	for player in pairs(sessions) do
		left += 1
		task.spawn(function()
			save(player, true)
			left -= 1
		end)
	end
	local t = os.clock()
	while left > 0 and os.clock() - t < 25 do task.wait(0.2) end
end)

-- income: every 0.5 s; the HUD counts up smoothly between
task.spawn(function()
	local last = os.clock()
	while true do
		task.wait(0.5)
		local now = os.clock()
		local dt = math.min(now - last, 5)
		last = now
		for player, s in pairs(sessions) do
			-- the boosts run down while you play; one ending changes your income: re-publish
			for id, left in pairs(s.d.boostLeft) do
				left -= dt
				if left <= 0 then
					s.d.boostLeft[id] = nil
					publish(player, s)
				else
					s.d.boostLeft[id] = left
				end
			end
			local gain = incomeOf(s) * dt
			-- XP from your system (the Cosmic Level); a new level re-publishes (the rank, the perk tiers)
			local xp = Econ.XPRate(gain / math.max(dt, 1e-6), s.d.perks, forgeOf(s, "XP")) * dt
			if xp > 0 then
				local before = Econ.LevelOf(s.d.xpTotal)
				s.d.xp += xp
				s.d.xpTotal += xp
				player:SetAttribute("XP", s.d.xp)
				player:SetAttribute("XPTotal", s.d.xpTotal)
				if Econ.LevelOf(s.d.xpTotal) > before then publish(player, s) end
			end
			if gain > 0 then
				s.d.stardust += gain
				s.d.earnedRun += gain
				s.d.earnedTotal += gain
				player:SetAttribute("Stardust", s.d.stardust)
				player:SetAttribute("EarnedRun", s.d.earnedRun)
				local need = Econ.NeedFor(s.d.supernovas)
				player:SetAttribute("SupernovaShards", shardsOf(s))
				if s.d.earnedRun >= need and not player:GetAttribute("SupernovaReady") then publish(player, s) end
				-- (Tutorial 2: the "100% SUPERNOVA" and "Cosmic LVL" steps complete on the income tick)
				if s.d.tut < #Econ.Tutorial then
					if s.d.supernovas == 0 then player:SetAttribute("SupernovaPct", math.floor(s.d.earnedRun / need * 100)) end
					local before = s.d.tut
					checkTutorial(player, s)
					if s.d.tut ~= before then publish(player, s) end
				end
			end
		end
	end
end)

-- a surge starting / ending changes everyone's income: re-publish (and once more when it runs out)
Galaxy:GetAttributeChangedSignal("SurgeUntil"):Connect(function()
	for player, s in pairs(sessions) do publish(player, s) end
	local untilT = Galaxy:GetAttribute("SurgeUntil") or 0
	task.delay(math.max(0, untilT - workspace:GetServerTimeNow()) + 0.1, function()
		for player, s in pairs(sessions) do publish(player, s) end
	end)
end)

if IS_STUDIO then
	-- (Studio: TestIgnitionReady = true -> every player meets the Ignition 1 checklist (Supernovas, LVL, pads, a body at IRON);
	-- the server's own check then lights the sector. For the cinematic / the Forge tests; never in the pace test.)
	workspace:GetAttributeChangedSignal("TestIgnitionReady"):Connect(function()
		if workspace:GetAttribute("TestIgnitionReady") ~= true then return end
		for player, s in pairs(sessions) do
			local d = s.d
			d.supernovas = math.max(d.supernovas, 12)
			d.pads = #Econ.Pads
			d.xpTotal = math.max(d.xpTotal, Econ.XPForLevel(19) + 1)
			d.owned[1] = math.max(d.owned[1], 20)
			d.copies[1] = math.max(d.copies[1], 1)
			d.tut = #Econ.Tutorial
			publish(player, s)
		end
	end)
	workspace:GetAttributeChangedSignal("TestGiveStardust"):Connect(function()
		local n = tonumber(workspace:GetAttribute("TestGiveStardust"))
		if not n then return end
		for player, s in pairs(sessions) do
			s.d.stardust += n
			s.d.earnedRun += n
			s.d.earnedTotal += n
			checkTutorial(player, s)
			publish(player, s)
		end
	end)
end

-- autosave
task.spawn(function()
	while true do
		task.wait(60)
		for player in pairs(sessions) do task.spawn(save, player, false) end
	end
end)
