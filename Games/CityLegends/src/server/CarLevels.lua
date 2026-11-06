--[[
	CarLevels (owner, 2026-11-03: "car class grades and car levels")
	  * every car you own has its own level, 1 to Config.CarLevels.Max (50): it earns the player XP you
	    get while driving it (Main's grantXp passes it on: driving, cut-ups, races, drifts, jumps,
	    traps, duels, escapes, jobs, the bank; the same server checks), times FromPlayerXp
	  * each level gives the car Car Points (CpPerLevel); CP or cash buy performance parts and pay for
	    Legends Customs looks (Customs.lua asks spendCp)
	  * (2026-11-06, the workshop and the Part Shop) parts are PartData's: one per slot, bought for a
	    car, installed or kept in My Parts (profile.PartBag). Uninstalling puts a part back there so it
	    can go on another car. The price goes with the car, so a spare remembers the price factor it
	    was paid at and a dearer car pays the difference when it's fitted. Selling gives back
	    SellShare. Up to 3 builds per car, and the TUNE tab's settings (profile.CarSetup)
	  * a brand's cars at level 50 take BrandOff off that brand's dealer prices, up to BrandMax
	Saved on the profile: CarLevels / CarXP / CarCP ({ car id = number }), CarParts
	({ car id = { slot = part id } }), PartBag ({ part id = { price factor of each spare } }),
	CarSetup ({ car id = settings }) and CarBuilds ({ car id = { active, list } }). Every purchase is
	checked here and saved before it's confirmed. Old saves' Street / Sport / Race parts become their
	parts in PlayerData (PartData.migrate).
	The car's parts ride on its model as the "Parts" and "Setup" attributes (CarStats.encodeParts,
	encodeSetup): Driving drives the tuned numbers, every screen shows the tuned class.
	Remotes: CarCall (RemoteFunction: "state", "buy", "install", "uninstall", "sell", "setup",
	"saveBuild", "useBuild"), CarProgress (RemoteEvent, to the client: XP, level-ups, CP, parts, drops).
	The player's brand discounts are the "BrandOff" attribute (JSON).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local PartData = require(Shared:WaitForChild("PartData"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local CarLevels = {}

local L = Config.CarLevels

local ctx: any = nil
local progress: RemoteEvent? = nil
local busy: { [Player]: boolean } = {}

---------------------------------------------------------------------
-- the saved tables (made on first use; PlayerData cleans them when a save loads)
---------------------------------------------------------------------
local function tables(profile: any): ({ [string]: number }, { [string]: number }, { [string]: number }, { [string]: { [string]: string } })
	profile.CarLevels = if type(profile.CarLevels) == "table" then profile.CarLevels else {}
	profile.CarXP = if type(profile.CarXP) == "table" then profile.CarXP else {}
	profile.CarCP = if type(profile.CarCP) == "table" then profile.CarCP else {}
	profile.CarParts = if type(profile.CarParts) == "table" then profile.CarParts else {}
	return profile.CarLevels, profile.CarXP, profile.CarCP, profile.CarParts
end

local function partTables(profile: any): ({ [string]: { number } }, { [string]: { [string]: number } }, { [string]: any })
	profile.PartBag = if type(profile.PartBag) == "table" then profile.PartBag else {}
	profile.CarSetup = if type(profile.CarSetup) == "table" then profile.CarSetup else {}
	profile.CarBuilds = if type(profile.CarBuilds) == "table" then profile.CarBuilds else {}
	return profile.PartBag, profile.CarSetup, profile.CarBuilds
end

-- a car's level, XP inside it, XP the level needs, CP and parts
export type CarState = { level: number, xp: number, need: number, cp: number, parts: CarStats.Parts, setup: CarStats.Setup }
function CarLevels.stateOf(profile: any, carId: string): CarState
	local levels, xps, cps, parts = tables(profile)
	local _, setups = partTables(profile)
	local level = levels[carId] or 1
	return {
		level = level,
		xp = xps[carId] or 0,
		need = if level >= L.Max then 0 else Config.carXpFor(level),
		cp = cps[carId] or 0,
		parts = parts[carId] or {},
		setup = setups[carId] or {},
	}
end

function CarLevels.partsOf(player: Player, carId: string): CarStats.Parts
	local profile = PlayerData.get(player)
	if not profile then
		return {}
	end
	local _, _, _, parts = tables(profile)
	return parts[carId] or {}
end

---------------------------------------------------------------------
-- brand discounts: level-50 cars per brand
---------------------------------------------------------------------
local function brandOf(carId: string): string?
	local at = Cars.SeriesOf[carId]
	return if at then at.series.Brand else nil
end

-- this player's discount on `carId`'s brand (0 .. BrandMax)
function CarLevels.brandOff(player: Player, carId: string): number
	local profile = PlayerData.get(player)
	local brand = brandOf(carId)
	if not profile or not brand then
		return 0
	end
	local levels = tables(profile)
	local maxed = 0
	for id, level in levels do
		if level >= L.Max and profile.Owned[id] and brandOf(id) == brand then
			maxed += 1
		end
	end
	return math.min(L.BrandMax, maxed * L.BrandOff)
end

-- the dealer price of `carId` for this player (the brand discount off)
function CarLevels.priceFor(player: Player, carId: string): number
	local spec = Cars.ById[carId]
	if not spec then
		return math.huge
	end
	return math.floor(spec.Price * (1 - CarLevels.brandOff(player, carId)) / 100 + 0.5) * 100
end

-- the "BrandOff" attribute: { BRAND = share } for every brand with a discount (the dealer shows it)
function CarLevels.publish(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local levels = tables(profile)
	local count: { [string]: number } = {}
	for id, level in levels do
		local brand = brandOf(id)
		if level >= L.Max and profile.Owned[id] and brand then
			count[brand] = (count[brand] or 0) + 1
		end
	end
	local out = {}
	for brand, n in count do
		out[brand] = math.min(L.BrandMax, n * L.BrandOff)
	end
	player:SetAttribute("BrandOff", HttpService:JSONEncode(out))
end

---------------------------------------------------------------------
-- XP and levels
---------------------------------------------------------------------
local function push(player: Player, carId: string, extra: { [string]: any }?)
	local profile = PlayerData.get(player)
	if not (profile and progress) then
		return
	end
	local st = CarLevels.stateOf(profile, carId) :: any
	st.carId = carId
	st.partsText = CarStats.encodeParts(st.parts)
	st.setupText = CarStats.encodeSetup(st.setup)
	st.parts, st.setup = nil, nil
	if extra then
		for k, v in extra do
			st[k] = v
		end
	end
	(progress :: RemoteEvent):FireClient(player, st)
end

-- car XP for `carId` (it must be the player's own car); returns the levels it gained
function CarLevels.add(player: Player, carId: string, xp: number): number
	local profile = PlayerData.get(player)
	xp = math.floor(xp)
	if not profile or not profile.Loaded or xp <= 0 or not profile.Owned[carId] or not Cars.ById[carId] then
		return 0
	end
	local levels, xps, cps = tables(profile)
	local level = levels[carId] or 1
	if level >= L.Max then
		return 0
	end
	local have = (xps[carId] or 0) + xp
	local gained = 0
	while level < L.Max and have >= Config.carXpFor(level) do
		have -= Config.carXpFor(level)
		level += 1
		gained += 1
	end
	if level >= L.Max then
		have = 0
	end
	levels[carId] = level
	xps[carId] = have
	if gained > 0 then
		cps[carId] = (cps[carId] or 0) + gained * L.CpPerLevel
		push(player, carId, { levelUp = true, gainedCp = gained * L.CpPerLevel })
		if level >= L.Max then
			CarLevels.publish(player) -- a brand discount may have grown
		end
		task.spawn(PlayerData.save, player)
	else
		push(player, carId, { gained = xp })
	end
	return gained
end

-- (Main's grantXp) the player got XP from `source`: the car they're driving gets its share
function CarLevels.onPlayerXp(player: Player, amount: number, source: string)
	if not L.Sources[source] or not ctx then
		return
	end
	local car = ctx.getCar(player)
	if not car or car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return
	end
	local carId = car:GetAttribute("CarId")
	if type(carId) == "string" then
		CarLevels.add(player, carId, amount * L.FromPlayerXp)
	end
end

-- spends `n` of the car's CP (Customs looks); false when it hasn't enough
function CarLevels.spendCp(player: Player, carId: string, n: number): boolean
	local profile = PlayerData.get(player)
	if not profile or n < 0 then
		return false
	end
	local _, _, cps = tables(profile)
	if (cps[carId] or 0) < n then
		return false
	end
	cps[carId] = (cps[carId] or 0) - n
	push(player, carId)
	return true
end

---------------------------------------------------------------------
-- parts
---------------------------------------------------------------------
-- puts a player's parts and settings on their car model (spawn, and after a change)
function CarLevels.applyTo(player: Player, model: Model, carId: string)
	model:SetAttribute("Parts", CarStats.encodeParts(CarStats.cleanParts(carId, CarLevels.partsOf(player, carId))))
	local profile = PlayerData.get(player)
	if profile then
		local _, setups = partTables(profile)
		model:SetAttribute("Setup", CarStats.encodeSetup(setups[carId]))
	end
end

local handlers: { [string]: (Player, any) -> any } = {}

-- the spare parts as the client sees them: { part id = { price factor, ... } }
local function bagOf(profile: any): { [string]: { number } }
	return (partTables(profile))
end

-- every owned car's level, XP, CP, parts, settings and builds, its look (the workshop shows the real
-- car), and the spare parts
handlers.state = function(player)
	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false }
	end
	local _, _, builds = partTables(profile)
	local cars = {}
	for id in profile.Owned do
		local st = CarLevels.stateOf(profile, id) :: any
		st.partsText = CarStats.encodeParts(st.parts)
		st.setupText = CarStats.encodeSetup(st.setup)
		st.parts, st.setup = nil, nil
		st.builds = builds[id]
		st.look = profile.Customs and profile.Customs[id]
		cars[id] = st
	end
	return { ok = true, cars = cars, bag = bagOf(profile) }
end

local function ownedCar(profile: any, carId: any): boolean
	return type(carId) == "string" and profile.Owned[carId] == true and Cars.ById[carId] ~= nil
end

-- a spare of this part: the best paid one comes first
local function takeSpare(bag: { [string]: { number } }, partId: string): number?
	local list = bag[partId]
	if not list or #list == 0 then
		return nil
	end
	table.sort(list, function(a, b)
		return a > b
	end)
	local k = table.remove(list, 1)
	if #list == 0 then
		bag[partId] = nil
	end
	return k
end

local function putSpare(bag: { [string]: { number } }, partId: string, k: number)
	local list = bag[partId] or {}
	table.insert(list, k)
	bag[partId] = list
end

-- runs `change`, saves, and puts everything back if the save fails. `change` returns what to tell the
-- client. Everything a part screen does goes through here
local function transact(player: Player, profile: any, carId: string?, change: () -> { [string]: any }): { [string]: any }
	if busy[player] then
		return { ok = false, message = "One moment..." }
	end
	busy[player] = true
	local _, _, cps, allParts = tables(profile)
	local bag = bagOf(profile)
	local cashBefore = profile.Cash
	local cpBefore = if carId then cps[carId] or 0 else 0
	local partsBefore = if carId and allParts[carId] then table.clone(allParts[carId]) else nil
	local bagBefore = {}
	for id, list in bag do
		bagBefore[id] = table.clone(list)
	end
	local res = change()
	if not PlayerData.save(player) then
		if carId then
			allParts[carId] = partsBefore
			cps[carId] = cpBefore
		end
		profile.PartBag = bagBefore
		if profile.Cash ~= cashBefore then
			PlayerData.addCash(player, cashBefore - profile.Cash)
		end
		busy[player] = nil
		return { ok = false, message = "Couldn't save: try again" }
	end
	busy[player] = nil
	res.ok = true
	res.cash = profile.Cash
	res.bag = bagOf(profile)
	if carId then
		-- the car that's out gets its new parts at once
		local car = ctx.getCar(player)
		if car and car:GetAttribute("CarId") == carId then
			CarLevels.applyTo(player, car, carId)
		end
		push(player, carId)
		local parts = allParts[carId] or {}
		local letter, _, pi = CarStats.classOf(carId, parts)
		res.partsText = CarStats.encodeParts(parts)
		res.cp = cps[carId] or 0
		res.class = letter
		res.pi = pi
	end
	return res
end

-- fits `partId` on the car; what stood in the slot goes to My Parts, paid for this car
local function fit(profile: any, carId: string, partId: string)
	local _, _, _, allParts = tables(profile)
	local parts = allParts[carId] or {}
	local def = PartData.Parts[partId]
	local was = parts[def.slot]
	if was then
		putSpare(bagOf(profile), was, Config.partK(Cars.ById[carId].Price))
	end
	parts[def.slot] = partId
	allParts[carId] = parts
end

-- buy a part: arg = { car = id, part = part id, pay = "cp" | "cash", install = boolean }
handlers.buy = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" then
		return { ok = false, message = "Try again" }
	end
	local carId, partId, pay = arg.car, arg.part, arg.pay
	if not ownedCar(profile, carId) then
		return { ok = false, message = "You don't own that car" }
	end
	local def = if type(partId) == "string" then PartData.Parts[partId] else nil
	if not def then
		return { ok = false, message = "Unknown part" }
	end
	if pay ~= "cp" and pay ~= "cash" then
		return { ok = false, message = "Pay with CP or cash" }
	end
	local install = arg.install == true
	local _, _, cps, allParts = tables(profile)
	local parts = allParts[carId] or {}
	-- (a part for My Parts needn't fit this car, it can't be sold to you if it never would)
	local fits, why = CarStats.fits(carId, partId, if install then parts else nil)
	if not fits then
		return { ok = false, message = why }
	end
	local cash, cp = CarStats.partPrice(carId, partId)
	if pay == "cp" and not cp then
		return { ok = false, message = "This one is cash only" }
	end
	if pay == "cp" and (cps[carId] or 0) < (cp :: number) then
		return { ok = false, message = "Not enough CP: level this car up" }
	end
	if pay == "cash" and profile.Cash < cash then
		return { ok = false, message = "Not enough cash" }
	end
	local res = transact(player, profile, carId, function()
		if pay == "cp" then
			cps[carId] = (cps[carId] or 0) - (cp :: number)
		else
			PlayerData.addCash(player, -cash)
		end
		if install then
			fit(profile, carId, partId)
		else
			putSpare(bagOf(profile), partId, Config.partK(Cars.ById[carId].Price))
		end
		return { part = partId, installed = install }
	end)
	if res.ok then
		ctx.note(player, "customs", 1)
	end
	return res
end

-- what a spare costs to fit on this car: the difference when it was paid for a cheaper car
local function fitFee(carId: string, def: PartData.Part, k: number): number
	local swap = def.engine ~= nil
	local carK = Config.partK(Cars.ById[carId].Price)
	return math.max(0, Config.partCash(def.list, carK, swap) - Config.partCash(def.list, k, swap))
end

-- fit a spare: arg = { car = id, part = part id }
handlers.install = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" then
		return { ok = false, message = "Try again" }
	end
	local carId, partId = arg.car, arg.part
	if not ownedCar(profile, carId) then
		return { ok = false, message = "You don't own that car" }
	end
	local def = if type(partId) == "string" then PartData.Parts[partId] else nil
	local bag = bagOf(profile)
	if not def or not bag[partId] or #bag[partId] == 0 then
		return { ok = false, message = "You don't have that part" }
	end
	local _, _, _, allParts = tables(profile)
	local fits, why = CarStats.fits(carId, partId, allParts[carId] or {})
	if not fits then
		return { ok = false, message = why }
	end
	table.sort(bag[partId], function(a, b)
		return a > b
	end)
	local fee = fitFee(carId, def, bag[partId][1])
	if profile.Cash < fee then
		return { ok = false, message = "Not enough cash for the fitting fee" }
	end
	return transact(player, profile, carId, function()
		takeSpare(bagOf(profile), partId)
		if fee > 0 then
			PlayerData.addCash(player, -fee)
		end
		fit(profile, carId, partId)
		return { part = partId, installed = true, fee = fee }
	end)
end

-- take a part off: arg = { car = id, slot = slot key }. It goes to My Parts
handlers.uninstall = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" then
		return { ok = false, message = "Try again" }
	end
	local carId, slot = arg.car, arg.slot
	if not ownedCar(profile, carId) then
		return { ok = false, message = "You don't own that car" }
	end
	local _, _, _, allParts = tables(profile)
	local parts = allParts[carId]
	local partId = if parts and type(slot) == "string" then parts[slot] else nil
	if not partId then
		return { ok = false, message = "Nothing fitted there" }
	end
	return transact(player, profile, carId, function()
		parts[slot] = nil
		putSpare(bagOf(profile), partId, Config.partK(Cars.ById[carId].Price))
		return { part = partId, slot = slot }
	end)
end

-- sell a spare: arg = { part = part id }. Gives back SellShare of what it was paid for
handlers.sell = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" then
		return { ok = false, message = "Try again" }
	end
	local partId = arg.part
	local def = if type(partId) == "string" then PartData.Parts[partId] else nil
	local bag = bagOf(profile)
	if not def or not bag[partId] or #bag[partId] == 0 then
		return { ok = false, message = "You don't have that part" }
	end
	return transact(player, profile, nil, function()
		local k = takeSpare(bagOf(profile), partId) :: number
		local back = math.floor(Config.partCash(def.list, k, def.engine ~= nil) * Config.CarParts.SellShare / 100 + 0.5) * 100
		PlayerData.addCash(player, back)
		return { part = partId, back = back }
	end)
end

-- the TUNE tab: arg = { car = id, values = { key = number } }. Free; checked and clamped
handlers.setup = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" or not ownedCar(profile, arg.car) then
		return { ok = false, message = "Try again" }
	end
	local carId = arg.car
	local _, setups = partTables(profile)
	local clean = CarStats.cleanSetup(arg.values)
	setups[carId] = if next(clean) then clean else nil
	local car = ctx.getCar(player)
	if car and car:GetAttribute("CarId") == carId then
		CarLevels.applyTo(player, car, carId)
	end
	push(player, carId)
	task.spawn(PlayerData.save, player)
	return { ok = true, setupText = CarStats.encodeSetup(clean) }
end

local function buildOf(profile: any, carId: string): { active: number, list: { { [string]: string } } }
	local _, _, builds = partTables(profile)
	local b = builds[carId]
	if type(b) ~= "table" or type(b.list) ~= "table" then
		b = { active = 1, list = {} }
		builds[carId] = b
	end
	for n = 1, PartData.MaxBuilds do
		b.list[n] = b.list[n] or {}
	end
	return b
end

-- keep this car's parts as build n: arg = { car = id, n = 1..MaxBuilds }
handlers.saveBuild = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" or not ownedCar(profile, arg.car) then
		return { ok = false, message = "Try again" }
	end
	local carId, n = arg.car, arg.n
	if type(n) ~= "number" or n % 1 ~= 0 or n < 1 or n > PartData.MaxBuilds then
		return { ok = false, message = "Try again" }
	end
	local _, _, _, allParts = tables(profile)
	return transact(player, profile, carId, function()
		local b = buildOf(profile, carId)
		b.list[n] = table.clone(allParts[carId] or {})
		b.active = n
		return { builds = b }
	end)
end

-- switch to build n: the fitted parts go to My Parts, the build's come out of it. A part that was
-- sold or moved to another car leaves its slot stock (`missing`). arg = { car = id, n = 1..MaxBuilds }
handlers.useBuild = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" or not ownedCar(profile, arg.car) then
		return { ok = false, message = "Try again" }
	end
	local carId, n = arg.car, arg.n
	if type(n) ~= "number" or n % 1 ~= 0 or n < 1 or n > PartData.MaxBuilds then
		return { ok = false, message = "Try again" }
	end
	local _, _, _, allParts = tables(profile)
	return transact(player, profile, carId, function()
		local b = buildOf(profile, carId)
		local bag = bagOf(profile)
		local carK = Config.partK(Cars.ById[carId].Price)
		-- this build is remembered as it stands, then everything comes off
		local now = allParts[carId] or {}
		b.list[b.active] = table.clone(now)
		for _, partId in now do
			putSpare(bag, partId, carK)
		end
		local want = b.list[n]
		local parts: { [string]: string } = {}
		local missing = 0
		for slot, partId in want do
			local list = bag[partId]
			local best = 0
			for _, k in list or {} do
				best = math.max(best, k)
			end
			if best >= carK - 1e-6 then
				takeSpare(bag, partId)
				parts[slot] = partId
			else
				missing += 1
			end
		end
		allParts[carId] = parts
		b.active = n
		return { builds = b, missing = missing }
	end)
end

-- a free part (a rare reward). Comes fully paid, so it fits any car with no fee. `rarity`: that
-- rarity, or picked by Config.CarParts.Drops.Rarity. Returns its id
function CarLevels.givePart(player: Player, rarity: string?): string?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	local D = Config.CarParts.Drops
	local pick = rarity
	if not pick then
		local total = 0
		for _, w in D.Rarity do
			total += w
		end
		local roll = math.random() * total
		for _, name in PartData.Rarities do
			roll -= D.Rarity[name] or 0
			if roll <= 0 then
				pick = name
				break
			end
		end
	end
	local pool = {}
	for id, def in PartData.Parts do
		if def.rarity == pick and not def.engine then
			table.insert(pool, id)
		end
	end
	if #pool == 0 then
		return nil
	end
	table.sort(pool)
	local id = pool[math.random(#pool)]
	putSpare(bagOf(profile), id, Config.CarParts.CashMax)
	if progress then
		(progress :: RemoteEvent):FireClient(player, { drop = id, bag = bagOf(profile) })
	end
	task.spawn(PlayerData.save, player)
	return id
end

-- maybe a free part, after `source`: daily, gold, heist (Config.CarParts.Drops.Chance)
function CarLevels.rollDrop(player: Player, source: string): string?
	local chance = Config.CarParts.Drops.Chance[source]
	if chance and math.random() < chance then
		return CarLevels.givePart(player)
	end
	return nil
end

function CarLevels.init(c: any)
	ctx = c
	progress = ctx.remote("RemoteEvent", "CarProgress")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "CarCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return CarLevels
