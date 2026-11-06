-- GalaxyLiveService (Script, ServerScriptService; 7 Nov, "MONETIZATION + RETENTION BEFORE THE ALPHA"): the live-ops side.
--  * PREMIUM: Roblox Premium players get +10% stardust (s.premium; GalaxyEconService adds it to the boosts). Attribute Premium.
--  * EVENTS (the EventController): GameConfig.Events; every server reads the UTC clock itself, every second, and sets the
--    Galaxy attributes EventId / EventTitle / EventEnds (unix) / EventStardust (+x to the boosts). The HUD's banner shows the
--    real time left. Repeating events (everyDays) run at the same time every N days after their start.
--    Studio: Workspace TestEventIn = <minutes> adds a 3-minute test event that starts that many minutes from now.
--  * SESSIONS + WHAT'S NEW: each join counts a session (the notification prompt comes after the 3rd). Everyone who played
--    before the current GameConfig.WhatsNew.version gets its gift once (LiveEvent "UpdateGift"); a brand-new player skips
--    both (they get the tutorial, not a changelog).
--  * game.ServerRestartScheduled (an update restart): everyone sees "Update incoming!" (LiveEvent "UpdateIncoming"), and every
--    save is written right away.
--  * EXPERIENCE NOTIFICATIONS (Open Cloud, GameConfig.Notify): "your offline stardust is full" when a player's offline cap is
--    reached (scheduled in a MemoryStore sorted map when they leave, cancelled when they come back; any server sends it
--    when it's due; max 1 a day a player) and the weekly update message (once per GameConfig.Notify.weeklyVersion, to the
--    players seen in the last 28 days). Only opted-in 13+ players receive them (Roblox drops the rest).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local DataStoreService = game:GetService("DataStoreService")
local AnalyticsService = game:GetService("AnalyticsService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Config = require(Galaxy:WaitForChild("GameConfig"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Shared = require(ServerStorage:WaitForChild("GalaxyEconShared"))
local IS_STUDIO = RunService:IsStudio()

local liveEvent = Galaxy:FindFirstChild("LiveEvent") or Instance.new("RemoteEvent")
liveEvent.Name = "LiveEvent"
liveEvent.Parent = Galaxy

local function sessionOf(player: Player)
	local t = os.clock()
	while player.Parent and not Shared.sessions[player] and os.clock() - t < 60 do task.wait(0.5) end
	return Shared.sessions[player]
end

------------------------------------------------------------------------ PREMIUM
local function checkPremium(player: Player)
	local s = Shared.sessions[player]
	local on = player.MembershipType == Enum.MembershipType.Premium
		or (IS_STUDIO and workspace:GetAttribute("TestPremium") == true)
	player:SetAttribute("Premium", on)
	if s and (s.premium == true) ~= on then
		s.premium = on
		Shared.publish(player, s)
	end
end
Players.PlayerMembershipChanged:Connect(checkPremium)
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("TestPremium"):Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do checkPremium(p) end
	end)
end

------------------------------------------------------------------------ EVENTS
local function parseStart(iso: string): number?
	local ok, dt = pcall(DateTime.fromIsoDate, iso)
	return if ok and dt then dt.UnixTimestamp else nil
end
local events = {}
for _, e in ipairs(Config.Events or {}) do
	local start = parseStart(e.start)
	if start then table.insert(events, { def = e, start = start }) else warn("[GalaxyLive] bad event start", e.id, e.start) end
end
local testEvent -- (Studio)
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("TestEventIn"):Connect(function()
		local m = tonumber(workspace:GetAttribute("TestEventIn"))
		if not m then testEvent = nil return end
		testEvent = { def = { id = "Test2x", title = "2x STARDUST HOUR", minutes = 3, stardust = 1 }, start = os.time() + math.floor(m * 60) }
		print("[GalaxyLive] test event starts at", testEvent.start, "now", os.time())
	end)
end
-- the window an event is in at `now` (repeats: the latest start not after now)
local function windowOf(ev, now: number): (number, number)
	local start = ev.start
	local every = (ev.def.everyDays or 0) * 86400
	if every > 0 and now >= start then start += math.floor((now - start) / every) * every end
	return start, start + ev.def.minutes * 60
end
local function eventNow(now: number)
	local list = table.clone(events)
	if testEvent then table.insert(list, testEvent) end
	local active, nextStart, nextDef
	for _, ev in ipairs(list) do
		local a, b = windowOf(ev, now)
		if now >= a and now < b then
			active = { def = ev.def, ends = b }
		else
			local n = if now < a then a else a + (ev.def.everyDays or 0) * 86400
			if (ev.def.everyDays or 0) > 0 or now < a then
				if not nextStart or n < nextStart then nextStart, nextDef = n, ev.def end
			end
		end
	end
	return active, nextStart, nextDef
end
local lastId = nil
task.spawn(function()
	while true do
		local now = os.time()
		local active, nextStart, nextDef = eventNow(now)
		local id = active and active.def.id or ""
		Galaxy:SetAttribute("EventId", id)
		Galaxy:SetAttribute("EventTitle", active and active.def.title or "")
		Galaxy:SetAttribute("EventEnds", active and active.ends or 0)
		Galaxy:SetAttribute("EventStardust", active and (active.def.stardust or 0) or 0)
		Galaxy:SetAttribute("EventNext", nextStart or 0)
		Galaxy:SetAttribute("EventNextTitle", nextDef and nextDef.title or "")
		if id ~= lastId then
			-- an event started / ended: everyone's income changes now
			lastId = id
			for player, s in pairs(Shared.sessions) do Shared.publish(player, s) end
			if id ~= "" then print("[GalaxyLive] event on:", id, "until", active.ends) end
		end
		task.wait(1)
	end
end)

------------------------------------------------------------------------ NOTIFICATIONS (Open Cloud)
local N = Config.Notify or {}
local queue = MemoryStoreService:GetSortedMap("GalaxyNotifyQueue")
local sentToday = MemoryStoreService:GetSortedMap("GalaxyNotifySent")
local recent = DataStoreService:GetOrderedDataStore("GalaxyRecentPlayers")
local function send(userId: number, messageId: string, category: string): boolean
	if messageId == "" or IS_STUDIO then return false end
	local okKey, key = pcall(function() return HttpService:GetSecret(N.secret) end)
	if not okKey then warn("[GalaxyLive] no notification key secret", N.secret) return false end
	local body = HttpService:JSONEncode({
		source = { universe = "universes/" .. game.GameId },
		payload = { message_id = messageId, type = "MOMENT", join_experience = { launch_data = category } },
		analytics_data = { category = category },
	})
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = "https://apis.roblox.com/cloud/v2/users/" .. userId .. "/notifications",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = key },
			Body = body,
		})
	end)
	if not ok or not res.Success then warn("[GalaxyLive] notification failed", userId, category, ok and res.StatusCode or res) end
	return ok and res.Success
end
-- offline full: scheduled on leave (when the cap fills), cancelled on join
local function offlineCapSeconds(s): number
	local _, cap = Econ.OfflineOf(s.d.ring2)
	return cap
end
Players.PlayerRemoving:Connect(function(player: Player)
	local s = Shared.sessions[player]
	if not s or N.offlineFull == "" then return end
	local due = os.time() + offlineCapSeconds(s)
	pcall(function() queue:SetAsync(tostring(player.UserId), { kind = "offline" }, 7 * 86400, due) end)
end)
task.spawn(function()
	while true do
		task.wait(if IS_STUDIO then 10 else 60)
		if N.offlineFull ~= "" then
			local ok, due = pcall(function()
				return queue:GetRangeAsync(Enum.SortDirection.Ascending, 20, nil, { sortKey = os.time() })
			end)
			for _, item in ipairs(ok and due or {}) do
				-- (claim it: only the server whose remove works sends it)
				local claimed = pcall(function() queue:RemoveAsync(item.key) end)
				local userId = tonumber(item.key)
				if claimed and userId and not Players:GetPlayerByUserId(userId) then
					local day = tostring(Econ.Today())
					local okSent, already = pcall(function() return sentToday:GetAsync(item.key .. ":" .. day) end)
					if okSent and not already then
						pcall(function() sentToday:SetAsync(item.key .. ":" .. day, true, 86400) end)
						send(userId, N.offlineFull, "offline_full")
					end
				end
			end
		end
	end
end)
-- the weekly message: once per weeklyVersion, by the first server that claims it
task.spawn(function()
	if N.weekly == "" or (N.weeklyVersion or 0) <= 0 or IS_STUDIO then return end
	local store = DataStoreService:GetDataStore("GalaxyNotifyWeekly")
	local claimed = false
	pcall(function()
		store:UpdateAsync("sentVersion", function(v)
			if (tonumber(v) or 0) >= N.weeklyVersion then return nil end
			claimed = true
			return N.weeklyVersion
		end)
	end)
	if not claimed then return end
	local ok, pages = pcall(function() return recent:GetSortedAsync(false, 100, Econ.Today() - 28) end)
	while ok and pages do
		for _, e in ipairs(pages:GetCurrentPage()) do
			send(tonumber(e.key) or 0, N.weekly, "weekly_update")
			task.wait(0.2)
		end
		if pages.IsFinished then break end
		ok = pcall(function() pages:AdvanceToNextPageAsync() end)
	end
end)

------------------------------------------------------------------------ players: sessions, What's New gift, notifications
local W = Config.WhatsNew
local function onPlayer(player: Player)
	local s = sessionOf(player)
	if not s or not player.Parent then return end
	checkPremium(player)
	local d = s.d
	d.sessions += 1
	-- (Studio: TestUpdateGift = true -> this join gets the update gift again, to test it)
	if IS_STUDIO and workspace:GetAttribute("TestUpdateGift") == true then d.giftVersion = 0 end
	if d.played < 60 and d.supernovas == 0 then
		-- (brand new: no changelog, no update gift; they start on this version)
		d.seenVersion, d.giftVersion = W.version, W.version
	elseif d.giftVersion < W.version then
		d.giftVersion = W.version
		local g = W.gift or {}
		if g.essence then d.essence += g.essence end
		task.delay(6, function() if player.Parent then liveEvent:FireClient(player, "UpdateGift", W.version, g.essence or 0) end end)
		pcall(function() AnalyticsService:LogCustomEvent(player, "UpdateGift", W.version) end)
	end
	Shared.publish(player, s)
	-- (back: their offline notification is off; remembered as a recent player for the weekly message)
	if not IS_STUDIO then
		pcall(function() queue:RemoveAsync(tostring(player.UserId)) end)
		pcall(function() recent:SetAsync(tostring(player.UserId), Econ.Today()) end)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end

------------------------------------------------------------------------ an UPDATE restart is coming
local restarting = false
local function updateIncoming(seconds)
	if restarting then return end
	restarting = true
	local t = tonumber(seconds)
	liveEvent:FireAllClients("UpdateIncoming", t)
	for player in pairs(Shared.sessions) do task.spawn(Shared.save, player, false) end
	print("[GalaxyLive] update restart scheduled", t)
end
game.ServerRestartScheduled:Connect(updateIncoming)
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("TestRestart"):Connect(function()
		if workspace:GetAttribute("TestRestart") then updateIncoming(60) end
	end)
end
