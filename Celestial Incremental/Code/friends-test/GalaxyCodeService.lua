-- GalaxyCodeService (Galaxy Incremental, overnight part 2, 3 Nov): CODES, server side (design additions 3; the same
-- pattern as GYM ARC's codes, written fresh for this game).
--  * RemoteFunction Galaxy.Codes: Invoke(text) -> ok, message, rewardLine
--  * one use per player, saved: the code goes in the save (d.codes[CODE] = os.time()) in the SAME change as the reward,
--    then the save is written at once (never paid twice, never lost)
--  * the live list: CodesConfig.Start, then the DataStore "GalaxyCodes" (key "list"; in Studio "studio_list") on top;
--    re-read every 5 min
--  * 5 tries a minute per player
--  * analytics: custom event "CodeRedeemed" (the code in custom field 1)
-- OWNER CONSOLE (live game: F9 > Server = the REAL list; Studio: the command bar while playing, Server view = the
-- separate Studio test list only):
--   game.ServerStorage.GalaxyAdmin:Invoke("code", "list")
--   game.ServerStorage.GalaxyAdmin:Invoke("code", "add", "SPOOKY", { essence = 2, potions = { Stardust = 1 } }, "2026-11-10")
--   game.ServerStorage.GalaxyAdmin:Invoke("code", "disable", "SPOOKY")   -- "enable" turns it back on
--   game.ServerStorage.GalaxyAdmin:Invoke("code", "remove", "SPOOKY")    -- a starting code comes back as it was
--   (the 5th value: the last day UTC "YYYY-MM-DD", a number of days from now, or nil = never ends)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local AnalyticsService = game:GetService("AnalyticsService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Codes = require(Galaxy:WaitForChild("CodesConfig"))
local Shared = require(ServerStorage:WaitForChild("GalaxyEconShared"))

local remote = Galaxy:FindFirstChild("Codes") or Instance.new("RemoteFunction")
remote.Name = "Codes"
remote.Parent = Galaxy

local okStore, store = pcall(function() return DataStoreService:GetDataStore("GalaxyCodes") end)
if not okStore then store = nil end
-- (3 Nov: Studio reads and writes its own "studio_list", like the studio_u_ saves, so a test or a console command in
-- Studio can never touch the live code list. Only live servers use "list".)
local LIST_KEY = if game:GetService("RunService"):IsStudio() then "studio_list" else "list"

------------------------------------------------------------------------ the live list
local live = {} -- [CODE] = { reward, ends (os.time or nil), off }
local overrides = {} -- the DataStore's list: [CODE] = { reward?, ends?, off?, removed? }
-- a reward from the console: only known parts, whole numbers, capped
local function cleanReward(r)
	if type(r) ~= "table" then return nil end
	local out = { essence = 0, potions = {} }
	local e = math.floor(tonumber(r.essence) or 0)
	if e > 0 then out.essence = math.min(e, Codes.MaxEssence) end
	if type(r.potions) == "table" then
		for _, p in ipairs(Econ.Potions) do
			local n = math.floor(tonumber(r.potions[p.id]) or 0)
			if n > 0 then out.potions[p.id] = math.min(n, Codes.MaxPotions) end
		end
	end
	local b = math.floor(tonumber(r.boost) or 0)
	if b > 0 then out.boost = math.min(b, 240) end -- (minutes of x2 stardust, max 4 h)
	if out.essence == 0 and next(out.potions) == nil and not out.boost then return nil end
	return out
end
local function endsOf(v): number?
	if type(v) == "number" then return os.time() + math.floor(v * 86400) end
	if type(v) == "string" then
		local y, m, d = v:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
		if y then return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59 }) end
	end
	return nil
end
local function rebuild()
	table.clear(live)
	for code, c in pairs(Codes.Start) do live[code] = { reward = cleanReward(c.reward), ends = c.ends and endsOf(c.ends) } end
	for code, o in pairs(overrides) do
		if o.removed then
			-- (a removed console code goes; a removed starting code comes back as it was)
			if not Codes.Start[code] then live[code] = nil end
		else
			local base = live[code] or {}
			live[code] = { reward = cleanReward(o.reward) or base.reward, ends = if o.ends ~= nil then o.ends else base.ends, off = o.off == true }
		end
	end
end
local function readList()
	if not store then return end
	local ok, list = pcall(function() return store:GetAsync(LIST_KEY) end)
	if ok and type(list) == "table" then overrides = list end
	rebuild()
end
rebuild()
task.spawn(function()
	while true do
		readList()
		task.wait(Codes.Refresh)
	end
end)

------------------------------------------------------------------------ redeem
local tries = {} -- [Player] = { t, n }
remote.OnServerInvoke = function(player: Player, text)
	if type(text) ~= "string" then return false, "Type a code first." end
	local now = os.clock()
	local t = tries[player]
	if not t or now - t.t > 60 then t = { t = now, n = 0 } tries[player] = t end
	t.n += 1
	if t.n > Codes.TriesPerMinute then return false, "Too many tries. Wait a minute, then try again." end
	local code = Codes.Normalize(text)
	if code == "" then return false, "Type a code first." end
	local s = Shared.sessions[player]
	if not s or s.readOnly then return false, "Still loading. Try again in a moment." end
	local c = live[code]
	if not c or not c.reward then return false, "That code doesn't exist." end
	if c.off or (c.ends and os.time() > c.ends) then return false, "This code expired." end
	local d = s.d
	if d.codes[code] then return false, "Already used." end
	-- the code and its reward in one change, then saved at once
	d.codes[code] = os.time()
	d.essence += c.reward.essence or 0
	for id, n in pairs(c.reward.potions or {}) do d.potions[id] = (d.potions[id] or 0) + n end
	-- (a boost reward runs at once: the x2 STARDUST potion's boost, added on top of any time left)
	if (c.reward.boost or 0) > 0 then d.boostLeft.Stardust = (d.boostLeft.Stardust or 0) + c.reward.boost * 60 end
	Shared.publish(player, s)
	task.spawn(Shared.save, player, false)
	pcall(function() AnalyticsService:LogCustomEvent(player, "CodeRedeemed", 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = code }) end)
	return true, "Redeemed!", Codes.Describe(c.reward, Econ.PotionsById)
end
Players.PlayerRemoving:Connect(function(p) tries[p] = nil end)

------------------------------------------------------------------------ the owner's console
local admin = ServerStorage:FindFirstChild("GalaxyAdmin") or Instance.new("BindableFunction")
admin.Name = "GalaxyAdmin"
admin.Parent = ServerStorage
local function writeList(change)
	if not store then return false, "no DataStore here (Studio without API access?)" end
	local ok, err = pcall(function()
		store:UpdateAsync(LIST_KEY, function(old)
			old = if type(old) == "table" then old else {}
			change(old)
			return old
		end)
	end)
	if not ok then return false, tostring(err) end
	readList()
	return true, "ok"
end
admin.OnInvoke = function(what, action, code, a, b)
	if what ~= "code" then return "commands: code list | add CODE reward [ends] | disable CODE | enable CODE | remove CODE" end
	if action == "list" then
		local lines = {}
		for k, c in pairs(live) do
			table.insert(lines, string.format("%s  %s%s%s", k, Codes.Describe(c.reward or {}, Econ.PotionsById),
				if c.ends then "  ends " .. os.date("!%Y-%m-%d", c.ends) else "", if c.off then "  OFF" else ""))
		end
		table.sort(lines)
		return table.concat(lines, "\n")
	end
	code = Codes.Normalize(code or "")
	if code == "" then return "which code?" end
	if action == "add" then
		local r = cleanReward(a)
		if not r then return "bad reward: use { essence = n, potions = { Stardust = n, Comets = n } }" end
		return select(2, writeList(function(list) list[code] = { reward = r, ends = endsOf(b) } end))
	elseif action == "disable" or action == "enable" then
		if not live[code] then return "no such code" end
		return select(2, writeList(function(list)
			local o = list[code] or {}
			o.off = action == "disable"
			o.removed = nil
			list[code] = o
		end))
	elseif action == "remove" then
		return select(2, writeList(function(list) list[code] = { removed = true } end))
	end
	return "unknown action: list / add / disable / enable / remove"
end
