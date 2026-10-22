--[[
	PlayerData
	Cash, owned cars, level/XP and the daily gift timer, saved with DataStoreService
	when available. Old saves without the progression fields load as level 1.
	(publish the place and enable "Studio Access to API Services" to save in Studio).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))

export type Profile = {
	Cash: number,
	Owned: { [string]: boolean },
	Selected: string,
	Level: number,
	XP: number, -- progress inside the current level
	LastDaily: number, -- os.time() of the last daily gift claim (0 = never)
	Settings: Settings,
	Market: { [string]: any }, -- car stock market: stash, hype, requests (Market.lua checks it)
	Activities: { [string]: any }, -- race best times, collected chips (Activities.lua checks it)
	Penthouses: { [string]: boolean }, -- owned luxury tower penthouses (Config.Towers ids)
	Rent: { [string]: number }, -- os.time() each penthouse's safe was last emptied
	Home: string, -- penthouse id set as home ("" = none)
	Houses: { [string]: boolean }, -- owned island houses (Config.Houses.Types ids)
	HouseBays: { [string]: { string } }, -- per house type: the car id in each garage bay ("" = empty)
	HousePlots: { [string]: string }, -- per house type: the plot it stood on last time
	Chauffeur: { [string]: boolean }, -- chauffeur contracts (car ids from Config.Chauffeur.Fleet)
	Luxe: { [string]: any }, -- VIP card, owned and worn flex items (Luxe.lua checks it)
	Loaded: boolean,
}

export type Settings = {
	Units: string, -- "mph" | "kmh"
	Gearbox: string, -- "Auto" | "Manual"
}

export type Snapshot = {
	Cash: number,
	Owned: { string },
	Selected: string,
	Level: number,
	XP: number,
	XPNeed: number,
	DailyIn: number, -- seconds until the daily gift can be claimed
	Settings: Settings,
	Penthouses: { string },
	Home: string,
}

export type XpResult = {
	level: number,
	xp: number,
	need: number,
	levels: number, -- levels gained by this award
	reward: number, -- cash paid for those levels
}

local PlayerData = {}

local profiles: { [Player]: Profile } = {}
local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("CityLegends_v1")
	end)
	if ok then
		store = result
	else
		warn("[CityLegends] DataStore unavailable, progress will not be saved:", result)
	end
end

local function defaultProfile(): Profile
	return {
		Cash = Config.Economy.StartingCash,
		Owned = { [Cars.StarterId] = true },
		Selected = Cars.StarterId,
		Level = 1,
		XP = 0,
		LastDaily = 0,
		Settings = { Units = "mph", Gearbox = "Auto" },
		Market = {},
		Activities = {},
		Penthouses = {},
		Rent = {},
		Home = "",
		Houses = {},
		HouseBays = {},
		HousePlots = {},
		Chauffeur = {},
		Luxe = {},
		Loaded = false,
	}
end

local function makeLeaderstats(player: Player, profile: Profile)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = profile.Level
	level.Parent = stats
	local value = Instance.new("IntValue")
	value.Name = "Cash"
	value.Value = profile.Cash
	value.Parent = stats
	stats.Parent = player
end

local function setStat(player: Player, name: string, v: number)
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(name)
	if value and value:IsA("IntValue") then
		value.Value = v
	end
end

function PlayerData.load(player: Player): Profile
	local profile = defaultProfile()
	if store then
		local ok, saved = pcall(function()
			return (store :: DataStore):GetAsync("p_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			if type(saved.Cash) == "number" then
				profile.Cash = math.max(0, math.floor(saved.Cash))
			end
			if type(saved.Owned) == "table" then
				for _, id in saved.Owned do
					if type(id) == "string" and Cars.ById[id] then
						profile.Owned[id] = true
					end
				end
			end
			if type(saved.Selected) == "string" and profile.Owned[saved.Selected] then
				profile.Selected = saved.Selected
			end
			-- progression (absent in saves from before levels existed)
			if type(saved.Level) == "number" then
				profile.Level = math.clamp(math.floor(saved.Level), 1, Config.Progression.MaxLevel)
			end
			if type(saved.XP) == "number" then
				profile.XP = math.clamp(math.floor(saved.XP), 0, Config.xpForLevel(profile.Level))
			end
			if type(saved.LastDaily) == "number" then
				profile.LastDaily = math.clamp(math.floor(saved.LastDaily), 0, os.time())
			end
			if type(saved.Settings) == "table" then
				PlayerData.setSettings(player, saved.Settings, profile)
			end
			if type(saved.Market) == "table" then
				profile.Market = saved.Market
			end
			if type(saved.Activities) == "table" then
				profile.Activities = saved.Activities
			end
			-- chauffeur contracts (absent in older saves): only cars still in the fleet
			if type(saved.Chauffeur) == "table" then
				for id, on in saved.Chauffeur do
					if on == true and type(id) == "string" and Config.Chauffeur.Fleet[id] then
						profile.Chauffeur[id] = true
					end
				end
			end
			if type(saved.Luxe) == "table" then
				profile.Luxe = saved.Luxe
			end
			-- luxury towers (absent in older saves)
			local towerIds = {}
			for _, t in Config.Towers.List do
				towerIds[t.id] = true
			end
			for _, t in Config.Hotel.Suites do
				towerIds[t.id] = true -- the hotel's suites save like penthouses
			end
			if type(saved.Penthouses) == "table" then
				for _, id in saved.Penthouses do
					if type(id) == "string" and towerIds[id] then
						profile.Penthouses[id] = true
					end
				end
			end
			if type(saved.Rent) == "table" then
				for id, t in saved.Rent do
					if type(id) == "string" and towerIds[id] and type(t) == "number" then
						profile.Rent[id] = math.clamp(math.floor(t), 0, os.time())
					end
				end
			end
			if type(saved.Home) == "string" and profile.Penthouses[saved.Home] then
				profile.Home = saved.Home
			end
			-- island houses (absent in older saves)
			local houseTypes = Config.Houses.Types
			if type(saved.Houses) == "table" then
				for _, id in saved.Houses do
					if type(id) == "string" and houseTypes[id] then
						profile.Houses[id] = true
					end
				end
			end
			if type(saved.HouseBays) == "table" then
				for id, bays in saved.HouseBays do
					local spec = if type(id) == "string" then houseTypes[id] else nil
					if spec and type(bays) == "table" then
						local list = {}
						for k = 1, spec.bays do
							local carId = bays[k]
							list[k] = if type(carId) == "string" and Cars.ById[carId] then carId else ""
						end
						profile.HouseBays[id] = list
					end
				end
			end
			if type(saved.HousePlots) == "table" then
				for id, plot in saved.HousePlots do
					if type(id) == "string" and houseTypes[id] and type(plot) == "string" then
						profile.HousePlots[id] = plot
					end
				end
			end
		elseif not ok then
			warn("[CityLegends] load failed for", player.Name, saved)
		end
	end
	profile.Loaded = true
	profiles[player] = profile
	makeLeaderstats(player, profile)
	return profile
end

function PlayerData.save(player: Player)
	local profile = profiles[player]
	if not profile or not profile.Loaded or not store then
		return
	end
	local owned = {}
	for id in profile.Owned do
		table.insert(owned, id)
	end
	local penthouses = {}
	for id in profile.Penthouses do
		table.insert(penthouses, id)
	end
	local houses = {}
	for id in profile.Houses do
		table.insert(houses, id)
	end
	local payload = {
		Cash = profile.Cash,
		Owned = owned,
		Selected = profile.Selected,
		Level = profile.Level,
		XP = profile.XP,
		LastDaily = profile.LastDaily,
		Settings = profile.Settings,
		Market = profile.Market,
		Activities = profile.Activities,
		Penthouses = penthouses,
		Rent = profile.Rent,
		Home = profile.Home,
		Houses = houses,
		HouseBays = profile.HouseBays,
		HousePlots = profile.HousePlots,
		Chauffeur = profile.Chauffeur,
		Luxe = profile.Luxe,
	}
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[CityLegends] save failed for", player.Name, err)
	end
end

function PlayerData.get(player: Player): Profile?
	return profiles[player]
end

function PlayerData.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Cash = math.max(0, math.floor(profile.Cash + amount))
	setStat(player, "Cash", profile.Cash)
end

-- Adds XP, rolls over as many levels as it covers and pays the level-up cash.
function PlayerData.addXp(player: Player, amount: number): XpResult?
	local profile = profiles[player]
	amount = math.floor(amount)
	if not profile or amount <= 0 then
		return nil
	end
	local maxLevel = Config.Progression.MaxLevel
	profile.XP += amount
	local levels, reward = 0, 0
	while profile.Level < maxLevel and profile.XP >= Config.xpForLevel(profile.Level) do
		profile.XP -= Config.xpForLevel(profile.Level)
		profile.Level += 1
		levels += 1
		reward += Config.levelReward(profile.Level)
	end
	local need = Config.xpForLevel(profile.Level)
	if profile.Level >= maxLevel then
		profile.XP = math.min(profile.XP, need)
	end
	if levels > 0 then
		setStat(player, "Level", profile.Level)
		PlayerData.addCash(player, reward)
	end
	return { level = profile.Level, xp = profile.XP, need = need, levels = levels, reward = reward }
end

function PlayerData.dailyReadyIn(player: Player): number
	local profile = profiles[player]
	if not profile then
		return Config.Daily.Cooldown
	end
	return math.max(0, profile.LastDaily + Config.Daily.Cooldown - os.time())
end

-- Returns (claimed, cash paid). Only succeeds once per Config.Daily.Cooldown.
function PlayerData.claimDaily(player: Player): (boolean, number)
	local profile = profiles[player]
	if not profile or not profile.Loaded or PlayerData.dailyReadyIn(player) > 0 then
		return false, 0
	end
	local amount = Config.dailyReward(profile.Level)
	profile.LastDaily = os.time()
	PlayerData.addCash(player, amount)
	return true, amount
end

function PlayerData.snapshot(player: Player): Snapshot?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local owned = {}
	for id in profile.Owned do
		table.insert(owned, id)
	end
	local penthouses = {}
	for id in profile.Penthouses do
		table.insert(penthouses, id)
	end
	return {
		Cash = profile.Cash,
		Owned = owned,
		Selected = profile.Selected,
		Level = profile.Level,
		XP = profile.XP,
		XPNeed = Config.xpForLevel(profile.Level),
		DailyIn = PlayerData.dailyReadyIn(player),
		Settings = { Units = profile.Settings.Units, Gearbox = profile.Settings.Gearbox },
		Penthouses = penthouses,
		Home = profile.Home,
	}
end

-- the player's settings (from a save or the client): only known values are kept
function PlayerData.setSettings(player: Player, raw: any, into: Profile?)
	local profile = into or profiles[player]
	if not profile or type(raw) ~= "table" then
		return
	end
	if raw.Units == "mph" or raw.Units == "kmh" then
		profile.Settings.Units = raw.Units
	end
	if raw.Gearbox == "Auto" or raw.Gearbox == "Manual" then
		profile.Settings.Gearbox = raw.Gearbox
	end
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	profiles[player] = nil
end

function PlayerData.saveAll()
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerData.save, player)
	end
end

return PlayerData
