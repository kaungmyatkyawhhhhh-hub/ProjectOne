-- GalaxyEconService (Galaxy Incremental, friends test 8 Nov): the first 15 minutes, server side.
--  * the save (DataStore, data version Econ.DataVersion, a session lock, autosave every 60 s + on leave + on shutdown;
--    Studio uses separate "studio_" keys so tests never touch real saves)
--  * Stardust income every tick from the bodies you own (EconConfig formulas), buying bodies + ring-1 nodes
--  * comets: the SERVER decides when one appears (every 45 s, 30 s with Comet Lure) and pays 30-60 s of income when the
--    client catches that comet in time (a client can't make up comets)
--  * tutorial steps 1-4: each pays 1 Essence (step counter "n/4"), logged to the onboarding funnel
--  * the player attributes the map reads: Bodies, BodyTiers, Supernovas, Rank, SupernovaReady, BestRunStardust,
--    Tree_CometLure, CometsCaught; and the ones the HUD reads: Stardust, Income, EarnedRun, Essence, TutStep, Own1..,
--    Node_<id>, Loaded
-- Remotes (ReplicatedStorage.Galaxy): EconRequest (RemoteFunction: "BuyBody", k / "BuyNode", id), EconEvent (server ->
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

------------------------------------------------------------------------ data
local function newData()
	local owned = {}
	for i = 1, #Econ.Tiers do owned[i] = Econ.StartOwned[i] or 0 end
	return { v = Econ.DataVersion, stardust = 0, earnedRun = 0, earnedTotal = 0, bestRun = 0, owned = owned, nodes = {},
		essence = 0, tut = 0, supernovas = 0, comets = 0 }
end
-- forward-safe: fills what an older save doesn't have; a NEWER save (from a newer server) is never overwritten
local function migrate(d): (any, boolean)
	if type(d) ~= "table" then return newData(), false end
	if (tonumber(d.v) or 0) > Econ.DataVersion then return d, true end
	local base = newData()
	for k, v in pairs(base) do
		if d[k] == nil then d[k] = v end
	end
	for i = 1, #Econ.Tiers do d.owned[i] = math.max(0, math.floor(tonumber(d.owned[i]) or 0)) end
	for _, k in ipairs({ "stardust", "earnedRun", "earnedTotal", "bestRun", "essence", "tut", "supernovas", "comets" }) do
		local n = tonumber(d[k]) or 0
		d[k] = if n == n and n ~= math.huge then n else 0
	end
	d.v = Econ.DataVersion
	return d, false
end

local LOCK_STALE = 150 -- seconds: a lock older than this is from a server that died
local function load(player: Player): (any, boolean, boolean) -- data, readOnly, noSave
	if not store then return newData(), false, true end
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
	return Econ.Unlocked(k, s.d.nodes)
end
-- STAR SURGE (GalaxyStarSurgeService): x2 stardust for everyone while it runs
local function surgeMult(): number
	return if workspace:GetServerTimeNow() < (Galaxy:GetAttribute("SurgeUntil") or 0) then MapConfig.Surge.Mult else 1
end
local function incomeOf(s): number
	return Econ.Income(s.d.owned, s.d.nodes) * surgeMult()
end
local function cometEvery(s): number
	return Econ.CometEvery(s.d.nodes)
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
	-- the map
	player:SetAttribute("Bodies", bodies)
	player:SetAttribute("BodyTiers", tiers)
	player:SetAttribute("Supernovas", d.supernovas)
	player:SetAttribute("Rank", MapConfig.RankOf(MapConfig.TierOf(bodies, d.supernovas), d.supernovas))
	player:SetAttribute("SupernovaReady", d.earnedRun >= Econ.SupernovaNeed)
	player:SetAttribute("BestRunStardust", math.max(d.bestRun, d.earnedRun))
	player:SetAttribute("Tree_CometLure", if d.nodes.CometLure then 1 else 0)
	player:SetAttribute("CometsCaught", d.comets)
end

------------------------------------------------------------------------ tutorial
local TUT_DONE = {
	function(d) return d.owned[1] >= 2 end, -- bought an asteroid (you start with 1)
	function(d) return d.nodes.FirstLight == true end,
	function(d) return (d.owned[2] or 0) >= 1 end, -- the first Moon (Lunar Pull, then buy one)
	function(d) return d.comets >= 1 end,
}
local function checkTutorial(player: Player, s)
	local d = s.d
	while d.tut < #Econ.Tutorial and TUT_DONE[d.tut + 1](d) do
		d.tut += 1
		local step = Econ.Tutorial[d.tut]
		d.essence += step.essence
		pcall(function() AnalyticsService:LogOnboardingFunnelStepEvent(player, d.tut, step.id) end)
		event:FireClient(player, "TutorialStep", d.tut, step.essence)
	end
end

------------------------------------------------------------------------ comets
local function spawnComet(player: Player, s, tutorial: boolean)
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
			-- step 4: the tutorial comet, again every 12 s until it's caught
			task.wait(2.5)
			if sessions[player] ~= s or s.d.tut ~= 3 then continue end
			spawnComet(player, s, true)
			for _ = 1, 12 do
				task.wait(1)
				if sessions[player] ~= s or s.d.tut ~= 3 then break end
			end
		else
			s.nextComet = s.nextComet or (os.clock() + Econ.Comet.FirstDelay)
			if os.clock() >= s.nextComet then
				spawnComet(player, s, false)
				s.nextComet = os.clock() + cometEvery(s)
			end
			task.wait(1)
		end
	end
end

------------------------------------------------------------------------ requests
local lastReq = {}
request.OnServerInvoke = function(player: Player, action, arg)
	local s = sessions[player]
	if not s or s.readOnly then return false, "loading" end
	-- rate limit: 25 requests a second (hold-to-buy is ~10)
	local now = os.clock()
	local r = lastReq[player]
	if not r or now - r.t > 1 then r = { t = now, n = 0 } lastReq[player] = r end
	r.n += 1
	if r.n > 25 then return false, "slow" end
	local d = s.d
	if action == "BuyBody" then
		if type(arg) ~= "number" or arg ~= arg or arg % 1 ~= 0 or arg < 0 or arg >= Econ.PlayableTiers then return false, "bad" end
		if not unlocked(s, arg) then return false, "locked" end
		local cost = Econ.Cost(arg, d.owned[arg + 1])
		if d.stardust < cost then return false, "poor" end
		d.stardust -= cost
		d.owned[arg + 1] += 1
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
			local gain = incomeOf(s) * dt
			if gain > 0 then
				s.d.stardust += gain
				s.d.earnedRun += gain
				s.d.earnedTotal += gain
				player:SetAttribute("Stardust", s.d.stardust)
				player:SetAttribute("EarnedRun", s.d.earnedRun)
				if s.d.earnedRun >= Econ.SupernovaNeed and not player:GetAttribute("SupernovaReady") then publish(player, s) end
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

-- autosave
task.spawn(function()
	while true do
		task.wait(60)
		for player in pairs(sessions) do task.spawn(save, player, false) end
	end
end)
