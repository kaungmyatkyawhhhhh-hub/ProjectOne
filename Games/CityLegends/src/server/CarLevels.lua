--[[
	CarLevels (owner, 2026-11-03: "car class grades and car levels")
	  * every car you own has its own level, 1 to Config.CarLevels.Max (50): it earns the player XP you
	    get while driving it (Main's grantXp passes it on: driving, cut-ups, races, drifts, jumps,
	    traps, duels, escapes, jobs, the bank; the same server checks), times FromPlayerXp
	  * each level gives the car Car Points (CpPerLevel); CP or cash buy that car's performance parts
	    (Config.CarParts: 8 parts, the engine as 5 of its own, 3 stages each, any order from level 1;
	    stock S2 / R / X cars only
	    tyres, gearbox, suspension and exhaust) and pay for its Legends Customs looks (Customs.lua
	    asks spendCp)
	  * a brand's cars at level 50 take BrandOff off that brand's dealer prices, up to BrandMax
	Saved on the profile: CarLevels / CarXP / CarCP ({ car id = number }) and CarParts
	({ car id = { part = stage } }). Every purchase is checked here and saved before it's confirmed.
	The car's parts ride on its model as the "Parts" attribute (CarStats.encodeParts): Driving drives
	the tuned numbers, every screen shows the tuned class.
	Remotes: CarCall (RemoteFunction: "state", "buyPart"), CarProgress (RemoteEvent, to the client:
	XP, level-ups, CP, parts). The player's brand discounts are the "BrandOff" attribute (JSON).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local CarLevels = {}

local L = Config.CarLevels
local P = Config.CarParts

local ctx: any = nil
local progress: RemoteEvent? = nil
local busy: { [Player]: boolean } = {}

---------------------------------------------------------------------
-- the saved tables (made on first use; PlayerData cleans them when a save loads)
---------------------------------------------------------------------
local function tables(profile: any): ({ [string]: number }, { [string]: number }, { [string]: number }, { [string]: { [string]: number } })
	profile.CarLevels = if type(profile.CarLevels) == "table" then profile.CarLevels else {}
	profile.CarXP = if type(profile.CarXP) == "table" then profile.CarXP else {}
	profile.CarCP = if type(profile.CarCP) == "table" then profile.CarCP else {}
	profile.CarParts = if type(profile.CarParts) == "table" then profile.CarParts else {}
	return profile.CarLevels, profile.CarXP, profile.CarCP, profile.CarParts
end

-- a car's level, XP inside it, XP the level needs, CP and parts
export type CarState = { level: number, xp: number, need: number, cp: number, parts: CarStats.Parts }
function CarLevels.stateOf(profile: any, carId: string): CarState
	local levels, xps, cps, parts = tables(profile)
	local level = levels[carId] or 1
	return {
		level = level,
		xp = xps[carId] or 0,
		need = if level >= L.Max then 0 else Config.carXpFor(level),
		cp = cps[carId] or 0,
		parts = parts[carId] or {},
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
	st.parts = nil
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
-- puts a player's parts on their car model (spawn, and after a purchase)
function CarLevels.applyTo(player: Player, model: Model, carId: string)
	model:SetAttribute("Parts", CarStats.encodeParts(CarStats.cleanParts(carId, CarLevels.partsOf(player, carId))))
end

local handlers: { [string]: (Player, any) -> any } = {}

-- every owned car's level, XP, CP and parts, the part prices for each, and the brand discounts
handlers.state = function(player)
	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false }
	end
	local cars = {}
	for id in profile.Owned do
		local st = CarLevels.stateOf(profile, id) :: any
		st.partsText = CarStats.encodeParts(st.parts)
		st.parts = nil
		cars[id] = st
	end
	return { ok = true, cars = cars }
end

-- buy the next stage of a part: arg = { car = id, part = key, pay = "cp" | "cash" }
handlers.buyPart = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" then
		return { ok = false, message = "Try again" }
	end
	local carId, key, pay = arg.car, arg.part, arg.pay
	if type(carId) ~= "string" or not profile.Owned[carId] or not Cars.ById[carId] then
		return { ok = false, message = "You don't own that car" }
	end
	if type(key) ~= "string" or not P.Parts[key] then
		return { ok = false, message = "Unknown part" }
	end
	if not CarStats.partAllowed(carId, key) then
		return { ok = false, message = "S2, R and X cars take only tyres, gearbox, suspension and exhaust" }
	end
	if pay ~= "cp" and pay ~= "cash" then
		return { ok = false, message = "Pay with CP or cash" }
	end
	if busy[player] then
		return { ok = false, message = "One moment..." }
	end
	-- parts go on at Legends Customs (in the tuning bay) or from the garage screen anywhere: the car
	-- needn't be out
	local _, _, cps, allParts = tables(profile)
	local parts = allParts[carId] or {}
	local stage = (parts[key] or 0) + 1
	if stage > #P.Stages then
		return { ok = false, message = "Already fully upgraded" }
	end
	local cpCost = Config.partCp(stage, key)
	local cashCost = Config.partCash(stage, Cars.ById[carId].Price, key)
	if pay == "cp" and (cps[carId] or 0) < cpCost then
		return { ok = false, message = "Not enough CP: level this car up" }
	end
	if pay == "cash" and profile.Cash < cashCost then
		return { ok = false, message = "Not enough cash" }
	end
	busy[player] = true
	local before = table.clone(parts)
	local cashBefore, cpBefore = profile.Cash, cps[carId] or 0
	if pay == "cp" then
		cps[carId] = cpBefore - cpCost
	else
		PlayerData.addCash(player, -cashCost)
	end
	parts[key] = stage
	allParts[carId] = parts
	-- saved before it's confirmed: if the save fails, the purchase is put back
	local saved = PlayerData.save(player)
	if not saved then
		allParts[carId] = before
		cps[carId] = cpBefore
		if pay == "cash" then
			PlayerData.addCash(player, cashBefore - profile.Cash)
		end
		busy[player] = nil
		return { ok = false, message = "Couldn't save: try again" }
	end
	busy[player] = nil
	ctx.note(player, "customs", 1)
	-- the car that's out gets its new parts at once
	local car = ctx.getCar(player)
	if car and car:GetAttribute("CarId") == carId then
		CarLevels.applyTo(player, car, carId)
	end
	push(player, carId)
	local letter, _, pi = CarStats.classOf(carId, parts)
	return { ok = true, stage = stage, part = key, cash = profile.Cash, cp = cps[carId] or 0, partsText = CarStats.encodeParts(parts), class = letter, pi = pi }
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
