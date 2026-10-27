-- PlayerData: one save per player (adapted from GYM ARC's approach).
-- Session lock so two servers never overwrite each other, autosave, save on leave and on server close,
-- migrations + template fill for old saves. Studio uses its own store; FreshPlayer plays on temporary data.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Config.GameConfig)
local Template = require(script.Parent.DataTemplate)

local Cfg = GameConfig.Data
local IS_STUDIO = RunService:IsStudio()
local JOB_ID = if IS_STUDIO then "studio" else game.JobId

local PlayerData = {}
PlayerData.Changed = Instance.new("BindableEvent") -- (player, key, value)
PlayerData.Loaded = Instance.new("BindableEvent") -- (player)

local profiles = {} -- [player] = { data = table, temp = bool, dirty = bool }
local store
local storeOk = true

-- Values mirrored to player attributes so the HUD can read them (replicates for free).
local ATTRIBUTES = { "Speed", "Coins", "League" }

-- Migrations: [fromVersion] = function(data) ... end. Each one moves data to the next version.
local MIGRATIONS = {}

local function deepCopy(t)
	local c = {}
	for k, v in t do
		c[k] = if type(v) == "table" then deepCopy(v) else v
	end
	return c
end

local function reconcile(data, template)
	for k, v in template do
		if data[k] == nil then
			data[k] = if type(v) == "table" then deepCopy(v) else v
		elseif type(v) == "table" and type(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

local function migrate(data)
	data.Version = data.Version or 1
	while MIGRATIONS[data.Version] do
		MIGRATIONS[data.Version](data)
		data.Version += 1
	end
	reconcile(data, Template)
	return data
end

local function getStore()
	if store == nil then
		local ok, s = pcall(function()
			return DataStoreService:GetDataStore(if IS_STUDIO then Cfg.StudioStoreName else Cfg.StoreName)
		end)
		if ok then
			store = s
		else
			storeOk = false
			warn("[PlayerData] DataStore not available:", s)
		end
	end
	return store
end

local function keyFor(player)
	return "p_" .. player.UserId
end

local function lockIsLive(lock)
	if type(lock) ~= "table" then
		return false
	end
	if lock.jobId == JOB_ID then
		return false
	end
	if lock.jobId == "studio" and not IS_STUDIO then
		return false -- Studio play tests never block a live server
	end
	return os.time() - (lock.time or 0) < Cfg.LockExpireSeconds
end

-- Load with the session lock. Returns data, or nil + reason.
local function loadSave(player)
	local s = getStore()
	if not s then
		return nil, "nostore"
	end
	local started = os.clock()
	while true do
		local result
		local blocked = false
		local ok, err = pcall(function()
			s:UpdateAsync(keyFor(player), function(old)
				if old and lockIsLive(old.Lock) then
					blocked = true
					return nil -- don't write
				end
				local data = old and old.Data or deepCopy(Template)
				result = data
				return { Data = data, Lock = { jobId = JOB_ID, time = os.time() } }
			end)
		end)
		if not ok then
			warn("[PlayerData] load failed:", err)
			if tostring(err):find("API") or tostring(err):find("access") or tostring(err):find("Publish") then
				storeOk = false
				return nil, "nostore"
			end
		elseif not blocked and result then
			return migrate(result)
		end
		if os.clock() - started > Cfg.LockWaitSeconds then
			return nil, if blocked then "locked" else "error"
		end
		task.wait(Cfg.LockRetrySeconds)
		if not player.Parent then
			return nil, "left"
		end
	end
end

local function writeSave(player, profile, release)
	if profile.temp then
		return true
	end
	local s = getStore()
	if not s then
		return false
	end
	local data = profile.data
	local ok, err = pcall(function()
		s:UpdateAsync(keyFor(player), function(old)
			if old and lockIsLive(old.Lock) then
				return nil -- another server owns it now: never overwrite
			end
			return { Data = data, Lock = if release then nil else { jobId = JOB_ID, time = os.time() } }
		end)
	end)
	if not ok then
		warn("[PlayerData] save failed for", player.Name, err)
	end
	return ok
end

local function setAttributes(player, data)
	for _, key in ATTRIBUTES do
		player:SetAttribute(key, data[key])
	end
	player:SetAttribute("MedalsGold", data.Medals.Gold)
	player:SetAttribute("MedalsSilver", data.Medals.Silver)
	player:SetAttribute("MedalsBronze", data.Medals.Bronze)
	player:SetAttribute("Races", data.Stats.Races)
	player:SetAttribute("Wins", data.Stats.Wins)
end

local function setupLeaderstats(player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local mph = Instance.new("IntValue")
	mph.Name = "MPH"
	mph.Value = math.floor(data.Speed)
	mph.Parent = ls
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = math.floor(data.Coins)
	coins.Parent = ls
	ls.Parent = player
end

local function onPlayerAdded(player)
	local fresh = IS_STUDIO and workspace:GetAttribute("FreshPlayer") == true
	local data, reason
	if fresh then
		data = deepCopy(Template)
	else
		data, reason = loadSave(player)
	end
	if not player.Parent then
		return
	end
	local temp = fresh
	if not data then
		if reason == "locked" then
			player:Kick("Your data is still saving from another server. Please rejoin in a minute.")
			return
		end
		if reason == "left" then
			return
		end
		-- No DataStore (Studio without API access): play on temporary data, never save
		warn("[PlayerData] playing on temporary data for", player.Name, "(" .. tostring(reason) .. ")")
		data = deepCopy(Template)
		temp = true
	end

	if data.FirstJoin == 0 then
		data.FirstJoin = os.time()
	end
	data.LastJoin = os.time()

	-- Studio test hooks
	if IS_STUDIO then
		local ts = workspace:GetAttribute("TestSpeed")
		if type(ts) == "number" then
			data.Speed = ts
		end
		local tc = workspace:GetAttribute("TestCoins")
		if type(tc) == "number" then
			data.Coins = tc
		end
	end

	profiles[player] = { data = data, temp = temp, joined = os.clock() }
	player:SetAttribute("DataTemp", temp)
	setAttributes(player, data)
	setupLeaderstats(player, data)
	player:SetAttribute("DataLoaded", true)
	PlayerData.Loaded:Fire(player)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.data.Stats.PlaySeconds += math.floor(os.clock() - profile.joined)
	profile.joined = os.clock()
	writeSave(player, profile, true)
	profiles[player] = nil
end

function PlayerData.isLoaded(player)
	return profiles[player] ~= nil
end

function PlayerData.get(player)
	local p = profiles[player]
	return p and p.data
end

function PlayerData.set(player, key, value)
	local p = profiles[player]
	if not p then
		return
	end
	p.data[key] = value
	if table.find(ATTRIBUTES, key) then
		player:SetAttribute(key, value)
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if key == "Speed" then
			ls.MPH.Value = math.floor(value)
		elseif key == "Coins" then
			ls.Coins.Value = math.floor(value)
		end
	end
	PlayerData.Changed:Fire(player, key, value)
end

function PlayerData.increment(player, key, amount)
	local data = PlayerData.get(player)
	if data then
		PlayerData.set(player, key, data[key] + amount)
	end
end

-- For nested values (medals, stats): change the table then call this to refresh attributes
function PlayerData.refresh(player)
	local data = PlayerData.get(player)
	if data then
		setAttributes(player, data)
	end
end

function PlayerData.start()
	getStore()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Cfg.AutosaveSeconds)
			for player, profile in profiles do
				if player.Parent then
					task.spawn(writeSave, player, profile, false)
				end
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, profile in profiles do
			pending += 1
			task.spawn(function()
				writeSave(player, profile, true)
				pending -= 1
			end)
		end
		local t = os.clock()
		while pending > 0 and os.clock() - t < 25 do
			task.wait(0.2)
		end
	end)
end

return PlayerData
