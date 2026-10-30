--[[
	PlayerData
	Loads / saves each player's progress. Falls back to session-only data when
	DataStores are unavailable (e.g. Studio without API access), and never saves
	over a profile that failed to load.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))

local PlayerData = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local profiles = {} -- [Player] = { data = {...}, canSave = bool }

local function defaults()
	return { strength = 0, cash = 0, tier = 1 }
end

function PlayerData.load(player: Player)
	local data = defaults()
	local canSave = false
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then
			canSave = true
			if type(saved) == "table" then
				data.strength = tonumber(saved.strength) or 0
				data.cash = tonumber(saved.cash) or 0
				data.tier = math.clamp(tonumber(saved.tier) or 1, 1, #Config.Weights)
			end
		end
	end
	profiles[player] = { data = data, canSave = canSave }
	return data
end

function PlayerData.get(player: Player)
	local profile = profiles[player]
	return profile and profile.data
end

function PlayerData.save(player: Player)
	local profile = profiles[player]
	if not (profile and profile.canSave and store) then
		return
	end
	pcall(function()
		store:SetAsync("p_" .. player.UserId, profile.data)
	end)
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	profiles[player] = nil
end

return PlayerData
