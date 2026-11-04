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
-- Remotes (ReplicatedStorage.Galaxy): EconRequest (RemoteFunction: "BuyBody" / "BuyBody10" / "BuyBodyMax", k / "BuyNode", id /
-- "BuyRing2", id / "Supernova"; + the island slot from a board), EconEvent (server ->
-- client: "TutorialStep", step, essence / "Bought", kind, what / "CometPaid", id, value), MapEvent ("CometSpawn" to the
-- client; the client answers "Comet", id).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
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
	local owned = {}
	for i = 1, #Econ.Tiers do owned[i] = Econ.StartOwned[i] or 0 end
	return { v = Econ.DataVersion, stardust = 0, earnedRun = 0, earnedTotal = 0, bestRun = 0, owned = owned, nodes = {},
		essence = 0, tut = 0, supernovas = 0, comets = 0, shards = 0, shardsEarned = 0, ring2 = {}, settings = {}, guide = {},
		codes = {}, potions = {}, boostLeft = {}, alphaPlayer = false, alphaBadge = false }
end
-- forward-safe: fills what an older save doesn't have; a NEWER save (from a newer server) is never overwritten
local function migrate(d): (any, boolean)
	if type(d) ~= "table" then return newData(), false end
	if (tonumber(d.v) or 0) > Econ.DataVersion then return d, true end
	local base = newData()
	for k, v in pairs(base) do
		if d[k] == nil then d[k] = v end
	end
	if type(d.owned) ~= "table" then d.owned = base.owned end
	for i = 1, #Econ.Tiers do d.owned[i] = math.max(0, math.floor(tonumber(d.owned[i]) or 0)) end
	for _, k in ipairs({ "stardust", "earnedRun", "earnedTotal", "bestRun", "essence", "tut", "supernovas", "comets", "shards", "shardsEarned" }) do
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
local function stardustBoost(s): number
	return 1 + (surgeMult() - 1) + (if boosting(s, "Stardust") then 1 else 0) + (if s.passX2 then 1 else 0)
end
local function incomeOf(s): number
	return Econ.Income(s.d.owned, s.d.nodes, s.d.ring2) * stardustBoost(s)
end
local function cometEvery(s): number
	return math.max(Econ.Comet.MinEvery, Econ.CometEvery(s.d.nodes) / (if boosting(s, "Comets") then 2 else 1))
end

-- everything the HUD and the map read
local function publish(player: Player, s)
	local d = s.d
	player:SetAttribute("Stardust", d.stardust)
	player:SetAttribute("Income", incomeOf(s))
	player:SetAttribute("EarnedRun", d.earnedRun)
	player:SetAttribute("Essence", d.essence)
	player:SetAttribute("TutStep", d.tut)
	local bodies, tiers = 0, 0
	for k = 1, #Econ.Tiers do
		player:SetAttribute("Own" .. k, d.owned[k])
		bodies += d.owned[k]
		if d.owned[k] > 0 then tiers += 1 end
	end
	for _, n in ipairs(Econ.Ring1) do player:SetAttribute("Node_" .. n.id, d.nodes[n.id] == true) end
	for _, n in ipairs(Econ.Ring2) do player:SetAttribute("R2_" .. n.id, d.ring2[n.id] or 0) end
	player:SetAttribute("Shards", d.shards)
	player:SetAttribute("ShardsEarned", d.shardsEarned)
	player:SetAttribute("SupernovaShards", Econ.ShardsFor(d.earnedRun, d.nodes))
	-- the map
	player:SetAttribute("Bodies", bodies)
	player:SetAttribute("BodyTiers", tiers)
	player:SetAttribute("Supernovas", d.supernovas)
	player:SetAttribute("Rank", MapConfig.RankOf(MapConfig.TierOf(bodies, d.supernovas), d.supernovas))
	player:SetAttribute("SupernovaReady", d.earnedRun >= Econ.SupernovaNeed)
	player:SetAttribute("BestRunStardust", math.max(d.bestRun, d.earnedRun))
	player:SetAttribute("Tree_CometLure", if d.nodes.CometLure then 1 else 0)
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
end
local GUIDE_PAGES = { Stardust = true, Island = true, Tree = true, Comets = true, Supernova = true, Surge = true, Ranks = true }

------------------------------------------------------------------------ tutorial
local TUT_DONE = {
	function(d) return d.owned[1] >= 2 end, -- bought an asteroid (you start with 1)
	function(d) return d.nodes.FirstLight == true end,
	function(d) return (d.owned[2] or 0) >= 1 end, -- the first Moon (Lunar Pull, then buy one)
	function(d) return d.comets >= 1 end,
	function(d) return d.earnedRun >= Econ.SupernovaNeed / 2 or d.supernovas >= 1 end, -- the goal bar at 50%
	function(d) return d.supernovas >= 1 end,
	function(d) return (d.ring2.Starfire or 0) >= 1 end,
}
local function checkTutorial(player: Player, s)
	local d = s.d
	while d.tut < #Econ.Tutorial and TUT_DONE[d.tut + 1](d) do
		d.tut += 1
		local step = Econ.Tutorial[d.tut]
		d.essence += step.essence
		pcall(function() AnalyticsService:LogOnboardingFunnelStepEvent(player, d.tut, step.id) end)
		event:FireClient(player, "TutorialStep", d.tut, step.essence)
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
	s.pending[s.cometId] = os.clock()
	mapEvent:FireClient(player, "CometSpawn", s.cometId, math.random(1, 2 ^ 30), tutorial)
end
local function cometLoop(player: Player, s)
	while sessions[player] == s do
		local tut = s.d.tut
		if tut < 3 then
			task.wait(1) -- (no comets during tutorial steps 1-3: nothing stacked on a hint)
		elseif tut == 3 then
			-- step 4: the tutorial comet, again every 15 s (the floor) until it's caught
			task.wait(2.5)
			if sessions[player] ~= s or s.d.tut ~= 3 then continue end
			spawnComet(player, s, true)
			for _ = 1, Econ.Comet.MinEvery - 2 do -- (2.5 + 13 s: just over the floor)
				task.wait(1)
				if sessions[player] ~= s or s.d.tut ~= 3 then break end
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
		local most = if action == "BuyBody" then 1 elseif action == "BuyBody10" then 10 else 1000
		local got = 0
		while got < most do
			local cost = Econ.Cost(arg, d.owned[arg + 1])
			if d.stardust < cost then break end
			d.stardust -= cost
			d.owned[arg + 1] += 1
			got += 1
		end
		if got == 0 then return false, "poor" end
		checkTutorial(player, s)
		publish(player, s)
		return true, d.owned[arg + 1]
	elseif action == "BuyNode" then
		local node = type(arg) == "string" and Econ.Ring1ById[arg]
		if not node then return false, "bad" end
		if d.nodes[node.id] then return false, "owned" end
		if node.requires and not d.nodes[node.requires] then return false, "locked" end
		if d.stardust < node.cost then return false, "poor" end
		d.stardust -= node.cost
		d.nodes[node.id] = true
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
		local got = Econ.ShardsFor(d.earnedRun, d.nodes)
		if got <= 0 then return false, "notready" end
		local first = d.supernovas == 0
		d.bestRun = math.max(d.bestRun, d.earnedRun)
		d.shards += got
		d.shardsEarned += got
		d.supernovas += 1
		d.stardust, d.earnedRun = 0, 0
		for i = 1, #Econ.Tiers do d.owned[i] = Econ.StartOwned[i] or 0 end
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
			if gain > 0 then
				s.d.stardust += gain
				s.d.earnedRun += gain
				s.d.earnedTotal += gain
				player:SetAttribute("Stardust", s.d.stardust)
				player:SetAttribute("EarnedRun", s.d.earnedRun)
				player:SetAttribute("SupernovaShards", Econ.ShardsFor(s.d.earnedRun, s.d.nodes))
				if s.d.earnedRun >= Econ.SupernovaNeed and not player:GetAttribute("SupernovaReady") then publish(player, s) end
				if s.d.tut == 4 and s.d.earnedRun >= Econ.SupernovaNeed / 2 then
					checkTutorial(player, s)
					publish(player, s)
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
