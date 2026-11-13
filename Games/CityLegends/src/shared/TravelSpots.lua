--[[
	TravelSpots (shared)
	The places the main menu's world map shows and fast travels to (owner, 2026-11-02): each venue
	(WestLayout.places: Legends Motors, Legends Customs, the bank, the towers, the hotel, Legends Rewards,
	the gem showcase, and Monaco's own spots), Legends Realty, the races' starts and the delivery
	dispatches. Each spot: an id, a name, its symbol (MenuArt.venues), a line on what you do there,
	and where you arrive: on the road outside, facing the way on (cf). Your own house is added by the
	server (Houses.homeSpot); its id is "home".
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))

local TravelSpots = {}

export type Spot = { id: string, name: string, icon: string, info: string, cf: CFrame }

local INFO = {
	dealership = "Buy new cars, test drive them",
	customs = "Paint, wheels and tuning",
	bank = "The vault: rob it, if you dare",
	tower = "Penthouses with garages",
	hotel = "Suites and the valet",
	rewards = "Daily rewards, gifts and wheel spins",
	gems = "Rare gems and flex items",
	realty = "Buy a house, pick a lot",
	hairpin = "The roof terrace over the Grand Hairpin",
	race = "Race the clock or other players",
	delivery = "Pick up delivery jobs",
	palace = "The old town on the rock",
	stadium = "The bay's stadium",
	harbour = "The harbour front",
	marina = "Park by the yachts",
	ygn_optima = "The car meet: tuners and supercars",
	ygn_novotel = "The hotel by the Pyay Road flyover",
	ygn_mmplaza = "The big mall and its towers",
	ygn_roundabout = "Round the Hanthawaddy Roundabout",
	ygn_newroad = "The flyover on New Road",
	ygn_university = "Down University Avenue",
	highway = "Mountain bends and long straights",
	lookout = "A view over the whole bay",
	home = "Your house",
	service = "Oil, tyres, brakes, engine and body repair",
	fuel = "Fuel, fast chargers and a car wash",
}

local function iconFor(id: string): string
	if string.sub(id, 1, 6) == "tower_" then
		return "tower"
	end
	local map = { ygn_optima = "race", ygn_novotel = "hotel", ygn_mmplaza = "harbour", ygn_roundabout = "lookout", ygn_newroad = "lookout", ygn_university = "lookout", old_rock = "palace", mountain = "lookout", stadium = "stadium", harbour = "harbour", dealership = "dealership", customs = "customs", bank = "bank", hotel = "hotel", rewards = "rewards", gems = "gems", beach = "beach" }
	return map[id] or "harbour"
end

local cache: { Spot }? = nil

function TravelSpots.list(): { Spot }
	if cache then
		return cache
	end
	local list: { Spot } = {}
	for _, pl in WestLayout.places() do
		local icon = iconFor(pl.id)
		table.insert(list, { id = pl.id, name = pl.name, icon = icon, info = INFO[pl.id] or INFO[icon] or "", cf = pl.cf })
	end
	local realty = WestLayout.rivieraSite("realty")
	if realty then
		-- (the pavilion's own lot is smaller than a venue's: its size from the site)
		local site = WestLayout.siteData("realty")
		local depth = if site and type(site.size) == "number" then site.size else WestLayout.Lot
		table.insert(list, { id = "realty", name = "Legends Realty", icon = "realty", info = INFO.realty, cf = WestLayout.kerbFor(realty, depth) })
	end
	-- (2026-11-04) the marina car park on the harbour's east quay (Workspace.Riviera.Marina)
	local riv = workspace:FindFirstChild("Riviera")
	if riv and riv:FindFirstChild("Marina") then
		local at = Vector3.new(13990, 8, 742)
		table.insert(list, { id = "marina", name = "Marina Parking", icon = "harbour", info = INFO.marina, cf = CFrame.lookAt(at, at + Vector3.new(0.608, 0, 0.794)) })
	end
	-- (2026-11-04) the Grand Hairpin Hotel: on its drive, facing the door
	if riv then
		local at = Vector3.new(10670, 40.5, 750)
		table.insert(list, { id = "hairpin_hotel", name = "Grand Hairpin Hotel", icon = "hotel", info = INFO.hairpin, cf = CFrame.lookAt(at, at + Vector3.new(-1, 0, 0)) })
	end
	-- (2026-11-04) the Riviera Highway (the mountain highway west of the town): its valley straight
	local okH, hw = pcall(function()
		return require(script.Parent:WaitForChild("RivieraHighway", 2)) :: any
	end)
	if riv and okH and type(hw) == "table" and hw.spot then
		table.insert(list, { id = "highway", name = "Riviera Highway", icon = "lookout", info = INFO.highway, cf = CFrame.lookAt(hw.spot.at + Vector3.new(0, 3, 0), hw.spot.at + Vector3.new(0, 3, 0) + hw.spot.dir) })
	end
	-- (2026-11-06) all the races start from the Racing Hub
	table.insert(list, { id = "racing_hub", name = Config.Activities.Hub.Name, icon = "race", info = INFO.race, cf = ActivityData.hubSpot or Config.Activities.Hub.Spot })
	-- (2026-11-07) Legends Service and the Riviera Fuel stations
	table.insert(list, { id = "service", name = "Legends Service", icon = "service", info = INFO.service, cf = (Config :: any).Service.Arrive })
	for _, st in (Config :: any).Fuel.Stations do
		-- (only the stations of a map in the place: Monaco's are kept in ServerStorage since Yangon step 11)
		local here = if st.arrive.Position.X > 25000 then workspace:FindFirstChild("Yangon") else riv
		if here then
			table.insert(list, { id = st.id, name = st.name, icon = "fuel", info = INFO.fuel, cf = st.arrive })
		end
	end
	-- (the dispatch's own spot on the pavement: CityLayout's lane search only knows the old city)
	for k, dsp in ActivityData.dispatch do
		table.insert(list, { id = "job_" .. k, name = dsp.name, icon = "delivery", info = INFO.delivery, cf = CFrame.new(dsp.pos) })
	end
	cache = list
	return list
end

function TravelSpots.get(id: string): Spot?
	for _, s in TravelSpots.list() do
		if s.id == id then
			return s
		end
	end
	return nil
end

TravelSpots.INFO = INFO

return TravelSpots
