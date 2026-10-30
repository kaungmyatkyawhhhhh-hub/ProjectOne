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
	Showcase: { [string]: string }, -- per penthouse / suite: the car its turntable shows
	Houses: { [string]: boolean }, -- owned house blueprints (Config.Houses.Designs ids)
	HouseBays: { [string]: { string } }, -- per design: the car in each garage bay, then each driveway spot ("" = empty)
	HousePlots: { [string]: string }, -- (old: per house type, the plot it stood on; read once to move old saves)
	HomeLot: string?, -- the lot your house stood on last (it goes back there when you join, if free)
	HomeDesign: string?, -- the house that stood there
	HouseExtraBays: { [string]: number }, -- per design: garage spaces bought on top of the free ones
	HouseAccess: string, -- who can come in: "nobody" | "friends" | "everyone"
	Roommates: { number }, -- user ids who can use your house
	Chauffeur: { [string]: boolean }, -- chauffeur contracts (car ids from Config.Chauffeur.Fleet)
	Luxe: { [string]: any }, -- VIP card, owned and worn flex items (Luxe.lua checks it)
	Challenges: { [string]: any }, -- speed trap bests, drift and jump bests (Challenges.lua checks it)
	Customs: { [string]: { [string]: any } }, -- per car id: its Legends Customs look (Customs.lua checks it)
	Goals: { [string]: any }, -- Legends Path, the daily streak and today's tasks (Goals.lua checks it)
	Brands: { [string]: number }, -- brand XP per brand (Brands.lua)
	Loaded: boolean,
}

export type Settings = {
	Units: string, -- "mph" | "kmh"
	Gearbox: string, -- "Auto" | "Manual"
	CamFx: { shake: number, head: number, blur: boolean, fov: number }?, -- Settings > Camera
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
		Showcase = {},
		Houses = {},
		HouseBays = {},
		HousePlots = {},
		HomeLot = nil,
		HomeDesign = nil,
		HouseExtraBays = {},
		HouseAccess = "friends",
		Roommates = {},
		Chauffeur = {},
		Luxe = {},
		Challenges = {},
		Customs = {},
		Goals = {},
		Brands = {},
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
			if type(saved.Challenges) == "table" then
				profile.Challenges = saved.Challenges
			end
			if type(saved.Luxe) == "table" then
				profile.Luxe = saved.Luxe
			end
			if type(saved.Customs) == "table" then
				profile.Customs = saved.Customs -- (Customs.lua cleans each look when it's read)
			end
			if type(saved.Goals) == "table" then
				profile.Goals = saved.Goals -- (Goals.lua cleans it when it's read)
			end
			if type(saved.Brands) == "table" then
				for brand, xp in saved.Brands do
					if type(brand) == "string" and type(xp) == "number" and xp == xp then
						profile.Brands[brand] = math.max(0, math.floor(xp))
					end
				end
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
			if type(saved.Showcase) == "table" then
				for id, car in saved.Showcase do
					if type(id) == "string" and towerIds[id] and type(car) == "string" and Cars.ById[car] then
						profile.Showcase[id] = car
					end
				end
			end
			-- houses (absent in older saves). Old house types (villa, mansion) become the designs
			-- that replaced them, worth as much or more: nobody loses anything (2026-10-29)
			local houseTypes = Config.Houses.Types
			local renamed = Config.Houses.Renamed
			local function design(id: any): string?
				if type(id) ~= "string" then
					return nil
				end
				local d = renamed[id] or id
				return if houseTypes[d] then d else nil
			end
			if type(saved.Houses) == "table" then
				for _, id in saved.Houses do
					local d = design(id)
					if d then
						profile.Houses[d] = true
					end
				end
			end
			if type(saved.HouseBays) == "table" then
				for id, bays in saved.HouseBays do
					local d = design(id)
					if d and type(bays) == "table" then
						local spec = Config.Houses.ById[d]
						local list = {}
						for k = 1, spec.maxBays + spec.drive do
							local carId = bays[k]
							list[k] = if type(carId) == "string" and Cars.ById[carId] then carId else ""
						end
						profile.HouseBays[d] = list
					end
				end
			end
			if type(saved.HomeLot) == "string" then
				profile.HomeLot = saved.HomeLot
			end
			local home = design(saved.HomeDesign)
			if home then
				profile.HomeDesign = home
			elseif type(saved.HousePlots) == "table" then
				-- an old save: its house type's plot (the High one first)
				for _, old in { "mansion", "villa" } do
					local plot = saved.HousePlots[old]
					if not profile.HomeDesign and type(plot) == "string" and design(old) then
						profile.HomeDesign = design(old)
						profile.HomeLot = plot
					end
				end
			end
			if type(saved.HouseExtraBays) == "table" then
				for id, n in saved.HouseExtraBays do
					local d = design(id)
					if d and type(n) == "number" then
						profile.HouseExtraBays[d] = math.clamp(math.floor(n), 0, 10)
					end
				end
			end
			if saved.HouseAccess == "nobody" or saved.HouseAccess == "friends" or saved.HouseAccess == "everyone" then
				profile.HouseAccess = saved.HouseAccess
			end
			if type(saved.Roommates) == "table" then
				for _, uid in saved.Roommates do
					if type(uid) == "number" and #profile.Roommates < 6 then
						table.insert(profile.Roommates, uid)
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
		Showcase = profile.Showcase,
		Houses = houses,
		HouseBays = profile.HouseBays,
		HomeLot = profile.HomeLot,
		HomeDesign = profile.HomeDesign,
		HouseExtraBays = profile.HouseExtraBays,
		HouseAccess = profile.HouseAccess,
		Roommates = profile.Roommates,
		Chauffeur = profile.Chauffeur,
		Luxe = profile.Luxe,
		Challenges = profile.Challenges,
		Customs = profile.Customs,
		Goals = profile.Goals,
		Brands = profile.Brands,
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
		Settings = { Units = profile.Settings.Units, Gearbox = profile.Settings.Gearbox, CamFx = profile.Settings.CamFx },
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
	-- Settings > Camera: only the known fields, in range
	local fx = raw.CamFx
	if type(fx) == "table" then
		local function level(v: any): number?
			return if v == 0 or v == 0.5 or v == 1 then v else nil
		end
		local fov = tonumber(fx.fov)
		profile.Settings.CamFx = {
			shake = level(fx.shake) or 1,
			head = level(fx.head) or 1,
			blur = fx.blur ~= false,
			fov = if fov and fov == fov then math.clamp(math.floor(fov + 0.5), Config.Camera.FovMin, Config.Camera.FovMax) else Config.Camera.Immersive.Fov,
		}
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
