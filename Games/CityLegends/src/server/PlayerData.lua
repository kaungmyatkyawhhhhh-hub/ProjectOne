--[[
	PlayerData
	Cash, owned cars, level/XP and the daily gift timer, saved with DataStoreService
	when available. Old saves without the progression fields load as level 1.
	(publish the place and enable "Studio Access to API Services" to save in Studio).
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local PartData = require(Shared:WaitForChild("PartData"))
local CarCare = require(Shared:WaitForChild("CarCare"))

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
	Trailers: { [string]: boolean }, -- (2026-11-07) trailers owned
	CarCare: { [string]: any }, -- (2026-11-07) per car id: mileage, health, fuel, service book, damage (shared/CarCare.lua)
	DriveSeconds: number, -- time at the wheel: new players have no wear for the first hour
	FreeFill: boolean?, -- false once the free first fill-up is used
	FreeService: boolean?, -- false once the free first service is used
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
	-- car levels (2026-11-03, CarLevels.lua): per car id its level (1-50), XP inside that level, unspent
	-- Car Points, and its performance parts ({ slot = part id }, PartData; saves from before 2026-11-06
	-- hold { part = stage }, moved when they load), the spare parts ({ part id = { price factor of each
	-- spare } }), the TUNE tab's settings and the builds per car (all CarLevels checks)
	CarLevels: { [string]: number },
	CarXP: { [string]: number },
	CarCP: { [string]: number },
	CarParts: { [string]: { [string]: string } },
	PartBag: { [string]: { number } },
	CarSetup: { [string]: { [string]: number } },
	CarBuilds: { [string]: any },
	Rewards: { [string]: any }, -- Legends Rewards: gifts claimed, wheel spins, codes (Rewards.lua checks it)
	LastSeen: number, -- os.time() of the last save (0 = never: a save from before 2026-11-03)
	Away: number, -- (not saved) seconds since the last session ended, from LastSeen (0 = unknown)
	IsNew: boolean, -- (not saved) no save existed when this session loaded
	-- the first car picked in the menu (2026-11-02): false only for a brand new player until they
	-- choose 1 of the 3 starters (Config.Menu.StarterChoices); old saves count as claimed
	Claimed: boolean,
	Loaded: boolean,
}

export type Settings = {
	Units: string, -- "mph" | "kmh"
	Gearbox: string, -- "Auto" | "Manual"
	CamFx: { shake: number, head: number, blur: boolean, fov: number }?, -- Settings > Camera
	-- the main menu's settings (2026-11-02)
	Minimap: { on: boolean, corner: string }?, -- shown, and which corner ("TopRight" ...)
	Graphics: string?, -- "Low" | "Medium" | "High" | "Ultra"
	Music: number?, -- 0..1
	Sfx: number?, -- 0..1
	Favs: { string }?, -- favourite cars (CARS tab)
	HideKeys: boolean?, -- the on-screen controls hidden
	Speedo: string?, -- the HUD speedometer: "Analogue" (default) | "Digital"
	Assist: string?, -- driving assists: "Off" | "Low" | "Normal" (default)
	Smoke: string?, -- tyre smoke: "Off" | "Low" | "High" (default)
	Marks: boolean?, -- tyre marks (default on)
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
	Claimed: boolean,
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

-- (2026-11-04) the session lock: a save's `Session` field ({ id, at }) says which game holds it, so
-- a quick rejoin can't load an old copy and two games can't overwrite each other. Autosaves renew it,
-- the last save clears it, a crashed server's lock runs out after LOCK_EXPIRES. Saves with no
-- Session (older ones) just load. A new player's first record is only { Fresh, Session }.
local LOCK_EXPIRES = 180 -- seconds: a bit over Main's 120 s autosave
local LOCK_WAIT = 8 -- seconds a join waits for the last game to finish saving
local LOAD_TRIES = 4
local FINAL_TRIES = 3
local LOAD_FAILED = "Your save couldn't load just now. It's safe: please rejoin in a minute."
-- each player's lock id (none: nothing to save to; false: another game took this save over)
local locks: { [Player]: string | boolean } = {}
-- players whose last save has started (weak: they go with the Player)
local releasing: { [Player]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local inFlight = 0 -- saves still running (BindToClose waits for them)

local function saveKey(player: Player): string
	return "p_" .. player.UserId
end

-- reads the save and takes its lock in one step, trying again after an error and waiting a moment
-- for a lock another game holds. Returns whether it worked, then the save (nil: a new player)
local function claim(player: Player): (boolean, any)
	local id = HttpService:GenerateGUID(false)
	local studio = RunService:IsStudio()
	local deadline = os.clock() + LOCK_WAIT
	local fails = 0
	while player.Parent do
		local saved, held = nil, false
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(saveKey(player), function(old: any): any
				local record = if type(old) == "table" then old else nil
				local session = if record then record.Session else nil
				-- (Studio never waits: stopping a test can leave its lock behind)
				held = not studio and type(session) == "table" and session.id ~= id and os.time() - (tonumber(session.at) or 0) < LOCK_EXPIRES
				if held then
					return nil
				end
				saved = if record and not record.Fresh then record else nil
				local out = record or { Fresh = true }
				out.Session = { id = id, at = os.time() }
				return out
			end)
		end)
		if ok and not held then
			locks[player] = id
			return true, saved
		end
		if not ok then
			fails += 1
			if fails >= (if studio then 1 else LOAD_TRIES) then
				return false, err
			end
			task.wait(fails)
		elseif os.clock() >= deadline then
			return false, "another game still holds this save"
		else
			task.wait(2)
		end
	end
	return false, "left while loading"
end

-- hands a lock back without saving (a player who left while their save loaded)
local function unlock(player: Player)
	local id = locks[player]
	locks[player] = nil
	if type(id) ~= "string" then
		return
	end
	inFlight += 1
	pcall(function()
		(store :: DataStore):UpdateAsync(saveKey(player), function(old: any): any
			if type(old) == "table" and type(old.Session) == "table" and old.Session.id == id then
				old.Session = nil
				return old
			end
			return nil
		end)
	end)
	inFlight -= 1
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
		Trailers = {},
		CarCare = {},
		DriveSeconds = 0,
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
		CarLevels = {},
		CarXP = {},
		CarCP = {},
		CarParts = {},
		PartBag = {},
		CarSetup = {},
		CarBuilds = {},
		Rewards = {},
		LastSeen = 0,
		Away = 0,
		IsNew = true,
		Claimed = false,
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

-- (2026-11-07, owner: "the one and only Urus") a car swapped for another (Cars.Swapped): everything
-- saved on the old id moves to the new one, so nobody ends up with both. A save with both keeps the
-- car with the higher level (its XP, CP, parts, tune, builds and look); the other one's parts go to My
-- Parts and the CP its levels earned are added. A part the new car can't take goes to My Parts too.
local function swapCars(profile: Profile)
	local p = profile :: any
	local function spare(partId: string, id: string)
		local list = profile.PartBag[partId] or {}
		table.insert(list, Config.partK(Cars.ById[id].Price))
		profile.PartBag[partId] = list
	end
	for old, new in Cars.Swapped do
		local hadOld, hadNew = profile.Owned[old] == true, profile.Owned[new] == true
		local function rank(id: string): number
			return (profile.CarLevels[id] or 1) * 1000000 + (profile.CarXP[id] or 0)
		end
		local oldWins = hadOld and (not hadNew or rank(old) > rank(new))
		local cpBack = 0
		if hadOld and hadNew then
			local loser = if oldWins then new else old
			cpBack = math.max(((profile.CarLevels[loser] or 1) - 1) * Config.CarLevels.CpPerLevel, profile.CarCP[loser] or 0)
			local parts: { [string]: string } = profile.CarParts[loser] or {}
			for _, partId in parts do
				spare(partId, loser)
			end
		end
		for _, key in { "CarLevels", "CarXP", "CarCP", "CarParts", "CarSetup", "CarBuilds", "Customs", "CarCare" } do
			if oldWins then
				p[key][new] = p[key][old]
			end
			p[key][old] = nil
		end
		if hadOld then
			profile.Owned[old] = nil
			profile.Owned[new] = true
			if cpBack > 0 then
				profile.CarCP[new] = (profile.CarCP[new] or 0) + cpBack
			end
			local parts: { [string]: string } = profile.CarParts[new] or {}
			for slot, partId in parts do
				if not CarStats.partAllowed(new, partId) then
					parts[slot] = nil
					spare(partId, old)
				end
			end
		end
		if profile.Selected == old then
			profile.Selected = new
		end
		local placed = false
		for _, bays in profile.HouseBays do
			for k, carId in bays do
				if carId == old or carId == new then
					bays[k] = if placed then "" else new
					placed = true
				end
			end
		end
		for id, carId in profile.Showcase do
			if carId == old then
				profile.Showcase[id] = new
			end
		end
		local favs = profile.Settings.Favs
		local at = favs and table.find(favs, old)
		if favs and at then
			if table.find(favs, new) then
				table.remove(favs, at)
			else
				favs[at] = new
			end
		end
		if type(profile.Market) == "table" then
			for _, key in { "Stash", "Req" } do
				for _, it in (profile.Market :: any)[key] or {} do
					if type(it) == "table" and it.c == old then
						it.c = new
					end
				end
			end
		end
	end
end

function PlayerData.load(player: Player): Profile?
	local profile = defaultProfile()
	if store then
		local ok, saved = claim(player)
		if ok and type(saved) == "table" then
			profile.IsNew = false
			profile.Claimed = saved.Claimed ~= false -- (saves from before the claim count as claimed)
			if type(saved.Rewards) == "table" then
				profile.Rewards = saved.Rewards -- (Rewards.lua cleans it when it's read)
			end
			-- how long they were away: from the last save, or (older saves) the last daily claim
			local seen = if type(saved.LastSeen) == "number" then saved.LastSeen elseif type(saved.LastDaily) == "number" then saved.LastDaily else 0
			if seen > 0 and seen <= os.time() then
				profile.LastSeen = seen
				profile.Away = os.time() - seen
			end
			if type(saved.Cash) == "number" then
				profile.Cash = math.max(0, math.floor(saved.Cash))
			end
			if type(saved.Owned) == "table" then
				-- (2026-11-04) a save that made the first-car pick owns just its list: the free car was
				-- added back here on every join. Older saves (no Claimed) still get it
				local owned: { [string]: boolean } = if saved.Claimed == true then {} else profile.Owned
				for _, id in saved.Owned do
					if type(id) == "string" and Cars.ById[id] then
						owned[id] = true
					end
				end
				if next(owned) then
					profile.Owned = owned
					if not owned[profile.Selected] then
						profile.Selected = (next(owned)) :: string
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
					local car = if type(id) == "string" then Cars.Swapped[id] or id else nil
					if on == true and car and Config.Chauffeur.Fleet[car] then
						profile.Chauffeur[car] = true
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
			-- car levels, XP, CP and parts (absent in saves from before 2026-11-03): only known cars,
			-- whole numbers in range, known parts and stages
			local maxLevel = Config.CarLevels.Max
			for _, key in { "CarLevels", "CarXP", "CarCP" } do
				local raw = saved[key]
				if type(raw) == "table" then
					local into = (profile :: any)[key]
					for id, n in raw do
						if type(id) == "string" and Cars.ById[id] and type(n) == "number" and n == n then
							local v = math.max(0, math.floor(n))
							if key == "CarLevels" then
								v = math.clamp(v, 1, maxLevel)
							end
							into[id] = v
						end
					end
				end
			end
			if type(saved.CarParts) == "table" then
				for id, parts in saved.CarParts do
					if type(id) == "string" and Cars.ById[id] and type(parts) == "table" then
						-- (2026-11-06) an old save's Street / Sport / Race parts become their new parts,
						-- installed; a save already moved reads as it is
						local clean = {}
						for slot, partId in PartData.migrate(parts) do
							if CarStats.partAllowed(id, partId) then
								clean[slot] = partId
							end
						end
						if next(clean) then
							profile.CarParts[id] = clean
						end
					end
				end
			end
			if type(saved.PartBag) == "table" then
				for partId, list in saved.PartBag do
					if type(partId) == "string" and PartData.Parts[partId] and type(list) == "table" then
						local clean = {}
						for _, k in list do
							-- (2026-11-07) a spare from when a factor went up to 10 stays, at today's top
							if type(k) == "number" and k == k and k >= 1 and k <= 10 and #clean < 99 then
								table.insert(clean, math.min(k, Config.CarParts.CashMax))
							end
						end
						if #clean > 0 then
							profile.PartBag[partId] = clean
						end
					end
				end
			end
			if type(saved.CarSetup) == "table" then
				for id, setup in saved.CarSetup do
					if type(id) == "string" and Cars.ById[id] then
						local clean = CarStats.cleanSetup(setup)
						if next(clean) then
							profile.CarSetup[id] = clean
						end
					end
				end
			end
			if type(saved.CarBuilds) == "table" then
				for id, b in saved.CarBuilds do
					if type(id) == "string" and Cars.ById[id] and type(b) == "table" and type(b.list) == "table" then
						local list = {}
						for n = 1, PartData.MaxBuilds do
							list[n] = if type(b.list[n]) == "table" then PartData.migrate(b.list[n]) else {}
						end
						local active = if type(b.active) == "number" and list[b.active] then b.active else 1
						profile.CarBuilds[id] = { active = active, list = list }
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
			if type(saved.Trailers) == "table" then
				for id, yes in saved.Trailers do
					if type(id) == "string" and yes == true then
						profile.Trailers[id] = true
					end
				end
			end
			-- (2026-11-07) a car's care record; old saves have none, Care makes them from the car's XP
			if type(saved.CarCare) == "table" then
				for id, rec in saved.CarCare do
					if type(id) == "string" and Cars.ById[id] then
						profile.CarCare[id] = CarCare.clean(rec, id)
					end
				end
			end
			if type(saved.DriveSeconds) == "number" and saved.DriveSeconds == saved.DriveSeconds then
				profile.DriveSeconds = math.max(saved.DriveSeconds, 0)
			elseif (profile.Level or 1) > 5 then
				profile.DriveSeconds = Config.Wear.ProtectSeconds -- (an old save isn't a new player)
			end
			if saved.FreeFill == false then
				profile.FreeFill = false
			end
			if saved.FreeService == false then
				profile.FreeService = false
			end
			if type(saved.Showcase) == "table" then
				for id, car in saved.Showcase do
					if type(id) == "string" and towerIds[id] and type(car) == "string" and Cars.ById[car] then
						profile.Showcase[id] = car
					end
				end
			end
			-- the hotel's suites are one suite you upgrade (2026-11-03): an older save that bought
			-- several keeps only the best one, with its home and showcase car moved onto it
			local best: string? = nil
			for _, t in Config.Hotel.Suites do
				if profile.Penthouses[t.id] then
					best = t.id
				end
			end
			if best then
				for _, t in Config.Hotel.Suites do
					if t.id ~= best then
						profile.Penthouses[t.id] = nil
						if type(saved.Home) == "string" and saved.Home == t.id then
							profile.Home = best
						end
						if profile.Showcase[t.id] then
							profile.Showcase[best] = profile.Showcase[best] or profile.Showcase[t.id]
							profile.Showcase[t.id] = nil
						end
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
			-- (2026-11-04) never play on with a blank profile: its saves would wipe the real one.
			-- (Studio without API access plays on with it: `locks` is empty, so it never saves)
			if not RunService:IsStudio() then
				if player.Parent then
					player:Kick(LOAD_FAILED)
				end
				return nil
			end
		end
	end
	swapCars(profile)
	-- (2026-11-04) they left while it loaded: nothing changed, so just hand the lock back
	if not player.Parent then
		unlock(player)
		return nil
	end
	profile.Loaded = true
	profiles[player] = profile
	makeLeaderstats(player, profile)
	return profile
end

-- what goes in the store (`session`: the lock, nil to clear it)
local function payloadOf(profile: Profile, session: { [string]: any }?): { [string]: any }
	profile.LastSeen = os.time()
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
	return {
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
		Trailers = profile.Trailers,
		CarCare = profile.CarCare,
		DriveSeconds = profile.DriveSeconds,
		FreeFill = profile.FreeFill,
		FreeService = profile.FreeService,
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
		CarLevels = profile.CarLevels,
		CarXP = profile.CarXP,
		CarCP = profile.CarCP,
		CarParts = profile.CarParts,
		PartBag = profile.PartBag,
		CarSetup = profile.CarSetup,
		CarBuilds = profile.CarBuilds,
		Rewards = profile.Rewards,
		LastSeen = profile.LastSeen,
		Claimed = profile.Claimed,
		Session = session,
	}
end

-- saves the profile; true when it was written (or there is no store to write to). `final`: the last
-- save of a visit, which clears the lock
function PlayerData.save(player: Player, final: boolean?): boolean
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return false
	end
	local id = locks[player]
	if not store or id == nil then
		return true
	end
	if id == false or (releasing[player] and not final) then
		return false
	end
	local taken = false
	inFlight += 1
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(saveKey(player), function(old: any): any
			-- (2026-11-04) a later session holds this save now: this copy is out of date
			local session = if type(old) == "table" then old.Session else nil
			taken = type(session) == "table" and session.id ~= id
			if taken or (releasing[player] and not final) then
				return nil
			end
			-- (made here, not before the call, so cash and what it paid for go in together)
			return payloadOf(profile, if final then nil else { id = id, at = os.time() })
		end)
	end)
	inFlight -= 1
	if taken then
		locks[player] = false
		warn("[CityLegends] save skipped for", player.Name, "another game holds it now")
		return false
	end
	if not ok then
		warn("[CityLegends] save failed for", player.Name, err)
	end
	return ok
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
		Settings = table.clone(profile.Settings),
		Penthouses = penthouses,
		Home = profile.Home,
		Claimed = profile.Claimed,
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
	-- the main menu's settings: only known values
	local mm = raw.Minimap
	if type(mm) == "table" then
		local corners = { TopRight = true, TopLeft = true, BottomRight = true, BottomLeft = true }
		profile.Settings.Minimap = { on = mm.on ~= false, corner = if type(mm.corner) == "string" and corners[mm.corner] then mm.corner else "TopRight" }
	end
	if type(raw.HideKeys) == "boolean" then
		profile.Settings.HideKeys = raw.HideKeys
	end
	if raw.Graphics == "Low" or raw.Graphics == "Medium" or raw.Graphics == "High" or raw.Graphics == "Ultra" then
		profile.Settings.Graphics = raw.Graphics
	end
	if raw.Assist == "Off" or raw.Assist == "Low" or raw.Assist == "Normal" then
		profile.Settings.Assist = raw.Assist -- driving assists (2026-11-03)
	end
	if raw.Smoke == "Off" or raw.Smoke == "Low" or raw.Smoke == "High" then
		profile.Settings.Smoke = raw.Smoke -- tyre smoke
	end
	if type(raw.Marks) == "boolean" then
		profile.Settings.Marks = raw.Marks -- tyre marks
	end
	if raw.Speedo == "Analogue" or raw.Speedo == "Digital" then
		profile.Settings.Speedo = raw.Speedo -- the HUD speedometer style (2026-11-03)
	end
	-- Settings > Graphics and Weather (2026-11-06): only known values, in range; none = the graphics level's
	local look = raw.Look
	if look == false then
		profile.Settings.Look = nil
	elseif type(look) == "table" then
		local L = Config.Look
		local out: { [string]: any } = {}
		for _, k in { "Shadows", "Glow", "Rays", "Dof", "SunClouds", "Haze" } do
			if type(look[k]) == "boolean" then
				out[k] = look[k]
			end
		end
		for k, allowed in L.Choices do
			if type(look[k]) == "string" and table.find(allowed, look[k]) then
				out[k] = look[k]
			end
		end
		for k, range in L.Sliders do
			local v = tonumber(look[k])
			if v and v == v then
				out[k] = math.clamp(v, -range, range)
			end
		end
		local t = tonumber(look.Time)
		if t and t == t and t >= 0 and t < 24 then
			out.Time = t
		end
		profile.Settings.Look = out
	end
	for _, key in { "Music", "Sfx" } do
		local v = tonumber(raw[key])
		if v and v == v then
			(profile.Settings :: any)[key] = math.clamp(math.floor(v * 20 + 0.5) / 20, 0, 1)
		end
	end
	if type(raw.Favs) == "table" then
		local favs = {}
		for _, id in raw.Favs do
			if type(id) == "string" and Cars.ById[id] and #favs < 100 and not table.find(favs, id) then
				table.insert(favs, id)
			end
		end
		profile.Settings.Favs = favs
	end
end

-- (2026-11-04) the last save, tried again if it fails; it clears the lock for the next game
function PlayerData.release(player: Player)
	if not profiles[player] or releasing[player] then
		return
	end
	releasing[player] = true
	inFlight += 1 -- (so BindToClose also waits through the pauses between tries)
	for try = 1, FINAL_TRIES do
		if PlayerData.save(player, true) or locks[player] == false then
			break
		end
		task.wait(try)
	end
	inFlight -= 1
	profiles[player] = nil
	locks[player] = nil
end

function PlayerData.saveAll()
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerData.save, player)
	end
end

-- (2026-11-04, BindToClose) waits for every save on its way, at most `limit` seconds
function PlayerData.waitForSaves(limit: number)
	local deadline = os.clock() + limit
	while inFlight > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

return PlayerData
