-- LeaderboardService (M4, GDD 17): global boards in OrderedDataStores with a versioned name (change
-- Config Version to reset them all). Boards: Top SPEED (all leagues), SPEED per league, Most Wins,
-- Fastest Sprint per league area, and the weekly boards (reset Monday 00:00 UTC; the top 3 get a
-- title + coins, delivered next time they play). Reads are spread out to stay inside Roblox budgets.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Areas = require(Shared.Config.Areas)
local Format = require(Shared.Util.Format)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local RaceService = require(script.Parent.RaceService)
local RetentionService = require(script.Parent.RetentionService)
local SocialService = require(script.Parent.SocialService)

local LeaderboardService = {}
local C = Retention.Leaderboards
local IS_STUDIO = RunService:IsStudio()
local PREFIX = (if IS_STUDIO then C.StudioPrefix else C.Prefix) .. "_v" .. C.Version .. "_"
local LEAGUE_STEP = 1e17 -- Top SPEED (all leagues) = league x 1e17 + speed

local stores = {}
local cache = {} -- [board] = { rows = { { rank, userId, name, value, text } }, at }
local written = {} -- [player] = { [board] = value }
local names = {} -- [userId] = display name

function LeaderboardService.week()
	local off = if IS_STUDIO then workspace:GetAttribute("TestWeekOffset") else nil
	-- the Unix epoch was a Thursday: +3 days makes weeks start on Monday
	return math.floor((RetentionService.now() + 3 * 86400) / 604800) + (if type(off) == "number" then off else 0)
end

-- the boards that exist right now: { key, title, ascending, format }
local function boards()
	local w = LeaderboardService.week()
	local list = {
		{ Key = "Speed", Title = "TOP SPEED", Kind = "speedAll" },
		{ Key = "Wins", Title = "MOST WINS", Kind = "count" },
		{ Key = "WeeklyWins_W" .. w, Short = "WeeklyWins", Title = "WINS THIS WEEK", Kind = "count" },
		{ Key = "WeeklyTime_W" .. w, Short = "WeeklyTime", Title = "FASTEST SPRINT THIS WEEK", Kind = "time", Asc = true },
	}
	for _, id in Areas.Order do
		local a = Areas[id]
		table.insert(list, { Key = "Speed_L" .. a.League, Title = a.Name .. " - TOP SPEED", Kind = "speed" })
		table.insert(list, { Key = "Sprint_" .. id, Title = a.Name .. " - FASTEST SPRINT", Kind = "time", Asc = true })
	end
	return list
end

local function store(key)
	if stores[key] == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore(PREFIX .. key)
		end)
		stores[key] = ok and s or false
	end
	return stores[key] or nil
end

local function valueText(kind, v)
	if kind == "speedAll" then
		local league = math.floor(v / LEAGUE_STEP)
		return ("L%d  %s SPEED"):format(league, Format.short(v - league * LEAGUE_STEP))
	elseif kind == "speed" then
		return Format.short(v) .. " SPEED"
	elseif kind == "time" then
		return ("%.2f s"):format(v / 1000)
	end
	return Format.short(v)
end

-- what each player puts on each board
local function values(data)
	local w = LeaderboardService.week()
	local out = {}
	local top = data.TopSpeed[tostring(data.League)] or data.Speed
	out.Speed = math.floor(data.League * LEAGUE_STEP + math.min(top, LEAGUE_STEP - 1))
	out.Wins = data.Stats.Wins
	for league, s in data.TopSpeed do
		out["Speed_L" .. league] = math.floor(s)
	end
	for _, id in Areas.Order do
		local t = data.BestTimes[id .. "_Sprint"]
		if t then
			out["Sprint_" .. id] = math.floor(t * 1000)
		end
	end
	if data.Weekly.Week == w then
		if data.Weekly.Wins > 0 then
			out["WeeklyWins_W" .. w] = data.Weekly.Wins
		end
		if data.Weekly.Best > 0 then
			out["WeeklyTime_W" .. w] = math.floor(data.Weekly.Best * 1000)
		end
	end
	return out
end

local function writePlayer(player)
	local data = PlayerData.get(player)
	if not data or player:GetAttribute("DataTemp") and not IS_STUDIO then
		return
	end
	written[player] = written[player] or {}
	for key, v in values(data) do
		if written[player][key] ~= v and v > 0 then
			local s = store(key)
			if s then
				local ok = pcall(function()
					s:SetAsync(tostring(player.UserId), v)
				end)
				if ok then
					written[player][key] = v
				end
			end
		end
	end
end

local nameCount = 0
local function fillNames(ids)
	if nameCount > 600 then
		table.clear(names) -- a cap: names are cheap to ask for again
		nameCount = 0
	end
	local missing = {}
	for _, id in ids do
		if not names[id] then
			local p = Players:GetPlayerByUserId(id)
			if p then
				names[id] = p.DisplayName
			else
				table.insert(missing, id)
			end
		end
	end
	if #missing > 0 then
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(missing)
		end)
		if ok then
			for _, info in infos do
				names[info.Id] = info.DisplayName
				nameCount += 1
			end
		end
	end
end

local function readBoard(b)
	local s = store(b.Key)
	local rows = {}
	local ok = s and pcall(function()
		local pages = s:GetSortedAsync(b.Asc == true, C.Top)
		for i, e in pages:GetCurrentPage() do
			rows[i] = { Rank = i, UserId = tonumber(e.key), Value = e.value }
		end
	end)
	if not ok then
		-- no DataStore (Studio without API access): this server's players only
		rows = {}
		for _, p in Players:GetPlayers() do
			local d = PlayerData.get(p)
			local v = d and values(d)[b.Key]
			if v then
				table.insert(rows, { UserId = p.UserId, Value = v })
			end
		end
		table.sort(rows, function(x, y)
			return if b.Asc then x.Value < y.Value else x.Value > y.Value
		end)
		for i, r in rows do
			r.Rank = i
		end
	end
	local ids = {}
	for _, r in rows do
		table.insert(ids, r.UserId)
	end
	fillNames(ids)
	for _, r in rows do
		r.Name = names[r.UserId] or ("Runner " .. r.UserId)
		r.Text = valueText(b.Kind, r.Value)
	end
	cache[b.Short or b.Key] = { Title = b.Title, Rows = rows, At = os.time() }
end

-- the boards in the world: parts with a "Board" attribute (hub wall) + each area's "Leaderboard"
local paintTargets
local worldTargets, targetsAt = nil, 0
local function paintWorld()
	if worldTargets and os.clock() - targetsAt < 60 then
		return paintTargets(worldTargets)
	end
	local targets = {}
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Board") then
			table.insert(targets, { part = d, key = d:GetAttribute("Board") })
		end
	end
	for _, id in Areas.Order do
		local model = workspace:FindFirstChild(Areas[id].Model)
		local lb = model and model:FindFirstChild("Leaderboard", true)
		local board = lb and lb:FindFirstChild("Board")
		if board and not board:GetAttribute("Board") then
			table.insert(targets, { part = board, key = "Speed_L" .. Areas[id].League })
		end
	end
	worldTargets, targetsAt = targets, os.clock()
	paintTargets(targets)
end

function paintTargets(targets)
	for _, t in targets do
		local c = cache[t.key]
		local rowsFrame = t.part:FindFirstChild("Rows", true)
		if c and rowsFrame then
			for i = 1, 5 do
				local label = rowsFrame:FindFirstChild("Row" .. i)
				local r = c.Rows[i]
				if label then
					-- never a blank board: an empty one asks to be the first (prompt 11)
					label.Text = if r then ("%d.  %s   %s"):format(i, r.Name, r.Text) elseif i == 1 and #c.Rows == 0 then "BE THE FIRST!" else ""
				end
			end
		end
	end
end

----------------------------------------------------------------------------
-- weekly: count wins + the best Hometown Sprint; pay last week's top 3 once
----------------------------------------------------------------------------
local pendingStore = nil
local paidStore = nil

local function payWeek(week)
	if not paidStore then
		return
	end
	local claimed = false
	pcall(function()
		paidStore:UpdateAsync("W" .. week, function(old)
			if old then
				return nil -- another server paid it
			end
			claimed = true
			return os.time()
		end)
	end)
	if not claimed then
		return
	end
	local s = store("WeeklyWins_W" .. week)
	if not s then
		return
	end
	pcall(function()
		local page = s:GetSortedAsync(false, 3):GetCurrentPage()
		for i, e in page do
			local reward = C.WeeklyTopRewards[i]
			if reward then
				pendingStore:SetAsync(e.key, { Title = reward.Title, Minutes = reward.Minutes, Week = week })
			end
		end
	end)
	for _, p in Players:GetPlayers() do
		LeaderboardService.deliver(p)
	end
end

function LeaderboardService.deliver(player)
	if not pendingStore then
		return
	end
	local ok, reward = pcall(function()
		return pendingStore:GetAsync(tostring(player.UserId))
	end)
	if ok and type(reward) == "table" then
		pcall(function()
			pendingStore:RemoveAsync(tostring(player.UserId))
		end)
		local text = RetentionService.give(player, { Minutes = reward.Minutes })
		SocialService.award(player, reward.Title)
		Net.get("Retention"):FireClient(player, "notice", { Title = reward.Title, Text = "Top 3 last week! " .. text })
	end
end

local function weeklyFor(data)
	local w = LeaderboardService.week()
	if data.Weekly.Week ~= w then
		data.Weekly = { Week = w, Wins = 0, Best = 0 }
	end
	return data.Weekly
end

function LeaderboardService.start()
	pcall(function()
		pendingStore = DataStoreService:GetDataStore(PREFIX .. "WeeklyPending")
		paidStore = DataStoreService:GetDataStore(PREFIX .. "WeeklyPaid")
	end)
	Net.on("Leaderboard", function(_, key)
		local c = cache[key]
		return c ~= nil, c
	end)
	RaceService.Won.Event:Connect(function(player, area, place, info)
		local data = PlayerData.get(player)
		if not data or not info or info.kind ~= "race" then
			return
		end
		local wk = weeklyFor(data)
		if place == 1 then
			wk.Wins += 1
		end
		if area.Id == "Hub" and info.raceType == "Sprint" and info.time then
			if wk.Best == 0 or info.time < wk.Best then
				wk.Best = info.time
			end
		end
	end)
	PlayerData.Loaded.Event:Connect(function(player)
		weeklyFor(PlayerData.get(player))
		task.spawn(LeaderboardService.deliver, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pcall(writePlayer, player)
		written[player] = nil
	end)

	-- writes: everyone once a minute (only changed values)
	task.spawn(function()
		task.wait(10)
		while true do
			for _, p in Players:GetPlayers() do
				pcall(writePlayer, p)
			end
			task.wait(C.WriteSeconds)
		end
	end)
	-- reads: one board at a time, spread over the minute (GetSorted budget is small)
	task.spawn(function()
		task.wait(5)
		local i = 0
		local lastWeek = LeaderboardService.week()
		while true do
			local list = boards()
			i = i % #list + 1
			pcall(readBoard, list[i])
			pcall(paintWorld)
			local w = LeaderboardService.week()
			if w ~= lastWeek then
				task.spawn(payWeek, lastWeek)
				lastWeek = w
			end
			-- GetSortedAsync budget is 5 + 2 per player a minute: stay 2 under it (the soak test
			-- showed queued requests at one read every 6 s with one player)
			local perMinute = math.max(1, 5 + 2 * #Players:GetPlayers() - 2)
			task.wait(math.max(6, C.ReadSeconds / #list, 60 / perMinute))
		end
	end)
end

return LeaderboardService
