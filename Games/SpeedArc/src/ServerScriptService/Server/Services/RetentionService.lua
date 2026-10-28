-- RetentionService (M4, GDD 15): daily streak, 3 daily quests, playtime gifts, codes, and the
-- timed boosts' clocks. Days are UTC days (+ Studio's TestDayOffset). The client shows the popups
-- one at a time when the player is free; the server pays right away so nothing is ever lost.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Trails = require(Shared.Config.Trails)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local LockerService = require(script.Parent.LockerService)

local RetentionService = {}
RetentionService.Claimed = Instance.new("BindableEvent") -- (player, kind) "daily" (first claim -> notify prompt)
local IS_STUDIO = RunService:IsStudio()
local Event = Net.get("Retention")
local Toast = Net.get("Toast")

local Q = Retention.Quests
local codes = {} -- live list: Config launch codes + the DataStore list
local codeStore = nil

function RetentionService.now()
	local off = if IS_STUDIO then workspace:GetAttribute("TestDayOffset") else nil
	return os.time() + (if type(off) == "number" then off * 86400 else 0)
end

function RetentionService.today()
	return math.floor(RetentionService.now() / 86400)
end

----------------------------------------------------------------------------
-- rewards
----------------------------------------------------------------------------
-- reward = { Minutes, Coins, Rolls, Trail, TrainBoost }; returns a short text of what was given
function RetentionService.give(player, reward)
	local data = PlayerData.get(player)
	if not data then
		return ""
	end
	local parts = {}
	local coins = (reward.Coins or 0) + Formulas.minutesOfCoins(reward.Minutes or 0, data.League)
	if coins > 0 then
		PlayerData.set(player, "Coins", data.Coins + coins)
		table.insert(parts, ("+%d coins"):format(coins))
	end
	if reward.Rolls then
		data.FreeRolls = (data.FreeRolls or 0) + reward.Rolls
		table.insert(parts, if reward.Rolls == 1 then "a free coach roll" else ("%d free coach rolls"):format(reward.Rolls))
	end
	if reward.Trail then
		data.OwnedTrails[reward.Trail] = true
		for _, t in Trails.List do
			if t.Id == reward.Trail then
				table.insert(parts, "the " .. t.Name .. " trail")
			end
		end
	end
	if reward.TrainBoost then
		data.Boost.Gift = (data.Boost.Gift or 0) + reward.TrainBoost
		table.insert(parts, ("2x training for %d min"):format(reward.TrainBoost // 60))
	end
	if reward.Title then
		data.Titles[reward.Title] = true
		table.insert(parts, "the title " .. reward.Title)
	end
	LockerService.push(player)
	return table.concat(parts, " + ")
end

----------------------------------------------------------------------------
-- daily streak (7 days, one missed day allowed)
----------------------------------------------------------------------------
local function dailyState(data)
	local d = data.Daily
	local today = RetentionService.today()
	local gap = today - (d.LastClaimDay or 0)
	local claimable = gap >= 1
	local nextDay
	if d.LastClaimDay == 0 or gap > 1 + Retention.Daily.GraceDays then
		nextDay = 1 -- new streak
	elseif gap == 0 then
		nextDay = (d.Streak % #Retention.Daily.Days) + 1 -- tomorrow's
	else
		nextDay = (d.Streak % #Retention.Daily.Days) + 1
	end
	return { Claimable = claimable, Day = nextDay, Streak = d.Streak, Broken = d.LastClaimDay ~= 0 and gap > 1 + Retention.Daily.GraceDays }
end

local function dayReward(data, day)
	local r = table.clone(Retention.Daily.Days[day])
	if r.Trail and data.Daily.GotTrail then
		r.Trail = nil
		r.Rolls = (r.Rolls or 0) + Retention.Daily.Day7RepeatRolls
	end
	return r
end

local function claimDaily(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local st = dailyState(data)
	if not st.Claimable then
		return false, "claimed"
	end
	local reward = dayReward(data, st.Day)
	data.Daily.Streak = st.Day
	data.Daily.LastClaimDay = RetentionService.today()
	if reward.Trail then
		data.Daily.GotTrail = true
	end
	local text = RetentionService.give(player, reward)
	RetentionService.Claimed:Fire(player, "daily")
	return true, { Day = st.Day, Text = text }
end

----------------------------------------------------------------------------
-- quests
----------------------------------------------------------------------------
local function statValue(data, stat)
	if stat == "Rolls" then
		return data.CoachRolls or 0
	end
	return data.Stats[stat] or 0
end

local function questDef(id)
	for _, q in Q.Pool do
		if q.Id == id then
			return q
		end
	end
end

local function questProgress(data, entry)
	local def = questDef(entry.Id)
	if not def then
		return 0, 1
	end
	return math.clamp(statValue(data, def.Stat) - (entry.Base or 0), 0, def.Goal), def.Goal
end

-- pays what was finished but not claimed (lesson: never lose them at the reset)
local function payUnclaimed(player, data)
	local total = 0
	for _, e in data.Quests.List do
		local p, goal = questProgress(data, e)
		if not e.Claimed and p >= goal then
			e.Claimed = true
			total += Q.RewardMinutes
		end
	end
	if total > 0 then
		local text = RetentionService.give(player, { Minutes = total })
		Event:FireClient(player, "notice", { Title = "QUESTS PAID", Text = "Your finished quests from yesterday: " .. text })
	end
end

local function rollQuests(player, data)
	local today = RetentionService.today()
	if data.Quests.Day == today then
		return
	end
	if data.Quests.Day ~= 0 then
		payUnclaimed(player, data)
	end
	local rng = Random.new(today * 7919 + player.UserId % 100000)
	local pool = table.clone(Q.Pool)
	local list = {}
	local usedStat = {}
	while #list < Q.PerDay and #pool > 0 do
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		if not usedStat[q.Stat] then
			usedStat[q.Stat] = true
			table.insert(list, { Id = q.Id, Base = statValue(data, q.Stat), Claimed = false })
		end
	end
	data.Quests = { Day = today, List = list, BonusClaimed = false }
end

local function questsState(data)
	local list = {}
	for i, e in data.Quests.List do
		local def = questDef(e.Id)
		local p, goal = questProgress(data, e)
		list[i] = { Id = e.Id, Text = def and def.Text or e.Id, Progress = p, Goal = goal, Claimed = e.Claimed }
	end
	local allClaimed = #list > 0
	for _, e in list do
		allClaimed = allClaimed and e.Claimed
	end
	return { List = list, BonusReady = allClaimed and not data.Quests.BonusClaimed, BonusClaimed = data.Quests.BonusClaimed }
end

local function claimQuest(player, index)
	local data = PlayerData.get(player)
	local e = data and type(index) == "number" and data.Quests.List[index]
	if not e or e.Claimed then
		return false
	end
	local p, goal = questProgress(data, e)
	if p < goal then
		return false, "notdone"
	end
	e.Claimed = true
	local text = RetentionService.give(player, { Minutes = Q.RewardMinutes })
	return true, { Text = text }
end

local function claimBonus(player)
	local data = PlayerData.get(player)
	if not data or not questsState(data).BonusReady then
		return false
	end
	data.Quests.BonusClaimed = true
	local text = RetentionService.give(player, { Minutes = Q.AllBonusMinutes, Rolls = Q.AllBonusRolls })
	return true, { Text = text }
end

----------------------------------------------------------------------------
-- playtime gifts (minutes of play today)
----------------------------------------------------------------------------
local function giftsState(data)
	local g = data.Gifts
	local nextGift = Retention.Gifts[g.Next]
	return { Seconds = g.Seconds, Next = g.Next, NextAt = nextGift and nextGift.At * 60 or nil, Total = #Retention.Gifts }
end

local function tickGifts(player, data)
	local g = data.Gifts
	local today = RetentionService.today()
	if g.Day ~= today then
		g.Day, g.Seconds, g.Next = today, 0, 1
	end
	g.Seconds += 1
	local gift = Retention.Gifts[g.Next]
	if gift and g.Seconds >= gift.At * 60 then
		g.Next += 1
		local text = RetentionService.give(player, gift)
		local nxt = Retention.Gifts[g.Next]
		Event:FireClient(player, "gift", { Index = g.Next - 1, Text = text, NextAt = nxt and nxt.At, Total = #Retention.Gifts })
	end
end

----------------------------------------------------------------------------
-- codes
----------------------------------------------------------------------------
local function loadCodes()
	local list = {}
	for code, r in Retention.Codes.Launch do
		list[string.upper(code)] = r
	end
	if codeStore then
		local ok, stored = pcall(function()
			return codeStore:GetAsync("list")
		end)
		if ok and type(stored) == "table" then
			for code, r in stored do
				if r == false then
					list[string.upper(code)] = nil -- removed
				elseif type(r) == "table" then
					list[string.upper(code)] = r
				end
			end
		end
	end
	codes = list
end

local function redeem(player, text)
	local data = PlayerData.get(player)
	if not data or type(text) ~= "string" or #text > 30 then
		return false, "bad"
	end
	local code = string.upper((text:gsub("%s", "")))
	local r = codes[code]
	if not r or (r.Expires and os.time() > r.Expires) then
		return false, "unknown"
	end
	if data.Codes[code] then
		return false, "used"
	end
	data.Codes[code] = true
	return true, { Text = RetentionService.give(player, r) }
end

-- console: _G.SpeedArcCodes.add("SUMMER", { Minutes = 5, Rolls = 1 }) / .remove("SUMMER") / .list()
local function editCodes(code, value)
	if not codeStore then
		return "no DataStore"
	end
	local ok, err = pcall(function()
		codeStore:UpdateAsync("list", function(old)
			old = old or {}
			old[string.upper(code)] = value
			return old
		end)
	end)
	loadCodes()
	return if ok then "ok" else tostring(err)
end
_G.SpeedArcCodes = {
	add = function(code, reward)
		return editCodes(code, reward or { Minutes = 5 })
	end,
	remove = function(code)
		return editCodes(code, false)
	end,
	list = function()
		local out = {}
		for c in codes do
			table.insert(out, c)
		end
		return table.concat(out, ", ")
	end,
}

----------------------------------------------------------------------------
function RetentionService.state(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	rollQuests(player, data)
	local st = dailyState(data)
	local days = {}
	for i = 1, #Retention.Daily.Days do
		days[i] = dayReward(data, i)
	end
	return {
		Daily = st,
		DailyRewards = days,
		Quests = questsState(data),
		Gifts = giftsState(data),
		Tutorial = data.Tutorial,
	}
end

local function push(player)
	local st = RetentionService.state(player)
	if st then
		Event:FireClient(player, "state", st)
	end
end
RetentionService.push = push

function RetentionService.start()
	pcall(function()
		codeStore = DataStoreService:GetDataStore(Retention.Codes.Store)
	end)
	task.spawn(function()
		while true do
			pcall(loadCodes)
			task.wait(Retention.Codes.RefreshSeconds)
		end
	end)

	Net.on("RetentionState", function(player)
		return true, RetentionService.state(player)
	end)
	Net.on("ClaimDaily", function(player)
		local ok, res = claimDaily(player)
		push(player)
		return ok, res
	end)
	Net.on("ClaimQuest", function(player, i)
		local ok, res = claimQuest(player, i)
		push(player)
		return ok, res
	end)
	Net.on("ClaimQuestBonus", function(player)
		local ok, res = claimBonus(player)
		push(player)
		return ok, res
	end)
	Net.on("RedeemCode", function(player, text)
		return redeem(player, text)
	end)

	PlayerData.Loaded.Event:Connect(function(player)
		local data = PlayerData.get(player)
		rollQuests(player, data)
		push(player)
	end)

	-- one clock for everyone: gifts, boosts, day changes, quest progress pushes
	task.spawn(function()
		local lastDay = RetentionService.today()
		local n = 0
		while true do
			task.wait(1)
			n += 1
			local today = RetentionService.today()
			for _, player in Players:GetPlayers() do
				local data = PlayerData.get(player)
				if data then
					tickGifts(player, data)
					local b = data.Boost
					for k, v in b do
						if v > 0 then
							b[k] = v - 1
						end
					end
					player:SetAttribute("BoostNewRunner", b.NewRunner)
					player:SetAttribute("BoostGift", b.Gift)
					player:SetAttribute("BoostInvite", b.Invite)
					player:SetAttribute("BoostSpeed", b.Speed or 0)
					if today ~= lastDay or n % 5 == 0 then
						push(player) -- quest progress, the gift timer, a new day
					end
				end
			end
			lastDay = today
		end
	end)
end

return RetentionService
