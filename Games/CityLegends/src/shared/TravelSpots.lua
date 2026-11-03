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
	race = "Race the clock or other players",
	delivery = "Pick up delivery jobs",
	palace = "The old town on the rock",
	stadium = "The bay's stadium",
	harbour = "The harbour front",
	lookout = "A view over the whole bay",
	home = "Your house",
}

local function iconFor(id: string): string
	if string.sub(id, 1, 6) == "tower_" then
		return "tower"
	end
	local map = { old_rock = "palace", mountain = "lookout", stadium = "stadium", harbour = "harbour", dealership = "dealership", customs = "customs", bank = "bank", hotel = "hotel", rewards = "rewards", gems = "gems", beach = "beach" }
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
		table.insert(list, { id = pl.id, name = pl.name, icon = icon, info = INFO[icon] or "", cf = pl.cf })
	end
	local realty = WestLayout.rivieraSite("realty")
	if realty then
		-- (the pavilion's own lot is smaller than a venue's: its size from the site)
		local site = (Config.RivieraVenues.Sites :: any).realty
		local depth = if site and type(site.size) == "number" then site.size else WestLayout.Lot
		table.insert(list, { id = "realty", name = "Legends Realty", icon = "realty", info = INFO.realty, cf = WestLayout.kerbFor(realty, depth) })
	end
	for _, r in ActivityData.races do
		local dir = Vector3.new(r.startDir.X, 0, r.startDir.Z)
		if dir.Magnitude > 0.1 then
			table.insert(list, { id = "race_" .. r.id, name = r.name, icon = "race", info = INFO.race, cf = CFrame.lookAt(r.start, r.start + dir.Unit) })
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
