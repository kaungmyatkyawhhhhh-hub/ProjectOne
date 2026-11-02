-- GalaxyLeaderboardService (Galaxy Incremental, 2 Nov): the LEFT zone's leaderboard wall (owner's centre redesign).
--  * TOP SUPERNOVAS: the 10 highest lifetime Supernova counts (OrderedDataStore), written on the wall for everyone
--  * PLAYERS NEAR YOU (Regrowth lesson, design additions note): the players just above and below YOUR lifetime Supernovas;
--    each player gets their own list (BoardEvent "Near") and their screen fills its side of the wall
-- Writes each player's lifetime Supernovas when it changes (and on join). Studio uses its own store.
-- Budget: GetSortedAsync allows 5 + 2 per player a minute; this uses 1 (top) + 1 per player (near) a minute.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local event = Galaxy:FindFirstChild("BoardEvent") or Instance.new("RemoteEvent")
event.Name = "BoardEvent"
event.Parent = Galaxy

local ok, store = pcall(function()
	return DataStoreService:GetOrderedDataStore(if RunService:IsStudio() then "GalaxySupernovasStudio1" else "GalaxySupernovas1")
end)
if not ok then store = nil end

local TOP_EVERY, NEAR_EVERY = 60, 60
local names = {} -- [userId] = name (cache)
local function nameOf(userId: number): string
	if names[userId] then return names[userId] end
	local p = Players:GetPlayerByUserId(userId)
	if p then names[userId] = p.DisplayName return p.DisplayName end
	local okName, n = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	names[userId] = if okName then n else "Player"
	return names[userId]
end

local written = {} -- [Player] = last value written
local function write(player: Player)
	if not store or not player:GetAttribute("Loaded") then return end
	local v = math.floor(tonumber(player:GetAttribute("Supernovas")) or 0)
	if written[player] == v then return end
	local okSet = pcall(function() store:SetAsync(tostring(player.UserId), v) end)
	if okSet then written[player] = v end
end

local function wallGuis(): { SurfaceGui }
	local wall = workspace:FindFirstChild("Galaxy") and workspace.Galaxy:FindFirstChild("Centre")
	wall = wall and wall:FindFirstChild("Leaderboard")
	wall = wall and wall:FindFirstChild("Wall")
	local list = {}
	if wall then
		for _, g in ipairs(wall:GetChildren()) do if g:IsA("SurfaceGui") then table.insert(list, g) end end
	end
	return list
end

local function refreshTop()
	if not store then return end
	local okGet, page = pcall(function() return store:GetSortedAsync(false, 10):GetCurrentPage() end)
	if not okGet then return end
	local lines = {}
	for i, entry in ipairs(page) do
		lines[i] = string.format("%d.  %s   %d", i, nameOf(tonumber(entry.key) or 0), entry.value)
	end
	for _, gui in ipairs(wallGuis()) do
		local top = gui:FindFirstChild("Top")
		for r = 1, 10 do
			local row = top and top:FindFirstChild("Row" .. r)
			if row then row.Text = lines[r] or "" end
		end
	end
end

-- the players just above and below you (5 each), you in the middle
local function refreshNear(player: Player)
	if not store or not player.Parent then return end
	local mine = math.floor(tonumber(player:GetAttribute("Supernovas")) or 0)
	local okA, above = pcall(function() return store:GetSortedAsync(true, 6, mine):GetCurrentPage() end)
	local okB, below = pcall(function() return store:GetSortedAsync(false, 6, nil, mine):GetCurrentPage() end)
	if not okA or not okB then return end
	local me = tostring(player.UserId)
	local seen, up, down = { [me] = true }, {}, {}
	for _, e in ipairs(above) do
		if not seen[e.key] and #up < 5 then seen[e.key] = true table.insert(up, 1, e) end
	end
	for _, e in ipairs(below) do
		if not seen[e.key] and #down < 5 then seen[e.key] = true table.insert(down, e) end
	end
	local list = {}
	for _, e in ipairs(up) do table.insert(list, { name = nameOf(tonumber(e.key) or 0), value = e.value }) end
	table.insert(list, { name = player.DisplayName, value = mine, you = true })
	for _, e in ipairs(down) do table.insert(list, { name = nameOf(tonumber(e.key) or 0), value = e.value }) end
	event:FireClient(player, "Near", list)
end

local function onPlayer(player: Player)
	while player.Parent and not player:GetAttribute("Loaded") do task.wait(0.5) end
	if not player.Parent then return end
	write(player)
	player:GetAttributeChangedSignal("Supernovas"):Connect(function() write(player) end)
	task.wait(2)
	refreshTop()
	refreshNear(player)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(player) written[player] = nil end)

task.spawn(function()
	while true do
		task.wait(TOP_EVERY)
		refreshTop()
	end
end)
task.spawn(function()
	while true do
		task.wait(NEAR_EVERY)
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(refreshNear, p)
			task.wait(1)
		end
	end
end)
