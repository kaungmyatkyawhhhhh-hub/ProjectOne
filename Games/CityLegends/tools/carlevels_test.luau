-- Lune test for the car classes, car levels, CP, parts and brand discounts (2026-11-03):
-- src/server/CarLevels.lua with stubs for PlayerData and the Roblox services, plus the class
-- rules in CarStats and an old save that owns retired cars (src/server/PlayerData.lua).
--   lune run tools/carlevels_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local serde = require("@lune/serde")

local root = process.args[1] or "."
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local Config = load("src/shared/Config.lua", baseEnv)
local Cars = load("src/shared/Cars.lua", baseEnv)
local function waitFor(_, name)
	return { name = name, WaitForChild = waitFor }
end
local senv = table.clone(baseEnv)
senv.script = { Parent = { WaitForChild = waitFor } }
senv.require = function(x)
	if x.name == "Config" then
		return Config
	elseif x.name == "Cars" then
		return Cars
	end
	error("require " .. tostring(x.name))
end
local CarStats = load("src/shared/CarStats.lua", senv)

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

---------------------------------------------------------------------
-- classes
---------------------------------------------------------------------
local xCars, rCars = {}, {}
for _, spec in Cars.List do
	local letter = CarStats.classOf(spec.Id)
	if letter == "X" then
		table.insert(xCars, spec.Id)
	end
	if letter == "R" then
		rCars[spec.Id] = true
	end
	local pi = CarStats.pi(spec.Id)
	if pi < 100 or pi > 999 then
		check(false, "PI in range for " .. spec.Id)
	end
end
table.sort(xCars)
check(#xCars == 5 and table.concat(xCars, ",") == "bugotti_chiron,bugotti_chiron_pursport,bugotti_chiron_supersport,lambrini_revuelto_sport,lambrini_revuelto_top", "only the Chirouns and the top two Revuelto trims are class X (" .. table.concat(xCars, ",") .. ")")
check(rCars.bugotti_veyron and rCars.bugotti_veyron_sport and rCars.bugotti_veyron_top, "the Veyruns are class R")
check(rCars.lambrini_svj, "the SVJ is class R")
check(CarStats.classOf("bnw_m5_f90") == "A", "the M5 F90 is class A")
check(CarStats.classOf(Cars.StarterId) == "D", "the free car is class D")
check(CarStats.requiredLevel("bugotti_chiron") == Config.CarClasses.XLevel and CarStats.requiredLevel("bugotti_veyron") == 1 and CarStats.requiredLevel("toyoka_chaser") == 1, "only class X needs a player level")
local full = {}
for _, key in Config.CarParts.Keys do
	full[key] = 3
end
check(CarStats.pi("toyoka_chaser", full) > CarStats.pi("toyoka_chaser"), "parts raise the PI")
check(CarStats.decodeParts(CarStats.encodeParts({ intake = 2, tyres = 3 })).intake == 2, "parts survive the attribute")
check(next(CarStats.decodeParts("engine=9,bogus=1,turbo=x")) == nil, "bad parts text is dropped")
-- stock S2 / R / X cars: only tyres, gearbox, suspension and exhaust (owner, 2026-11-03)
for _, spec in Cars.All do
	local top = Config.CarParts.TopClasses[(CarStats.classOf(spec.Id))]
	for _, key in Config.CarParts.Keys do
		local allowed = CarStats.partAllowed(spec.Id, key)
		if allowed ~= ((not top) or Config.CarParts.TopAllowed[key] == true) then
			check(false, "part rule for " .. spec.Id .. " " .. key)
		end
	end
end
check(not CarStats.partAllowed("bugotti_chiron", "displacement") and CarStats.partAllowed("bugotti_chiron", "tyres") and CarStats.partAllowed("bugotti_chiron", "exhaust"), "a Chiroun takes tyres and exhaust, no engine parts")
check(CarStats.partAllowed("bnw_m5_f90", "intake") and CarStats.partAllowed("toyoka_chaser", "weight"), "cars below S2 take every part")
check(CarStats.pi("bugotti_chiron", { displacement = 3, cams = 3 }) == CarStats.pi("bugotti_chiron"), "a not-allowed part does nothing on a top car")
check(CarStats.pi("bugotti_chiron", { tyres = 3 }) > CarStats.pi("bugotti_chiron"), "tyres still help a top car")
-- the engine's own parts and rules (owner, 2026-11-03: "press engine and then upgrade these")
check(Config.CarParts.Parts.engine == nil and #Config.CarParts.Groups.engine.parts == 5, "the engine is a menu of 5 parts")
local function t(parts)
	return CarStats.tuneOf(parts)
end
check(math.abs(t({ cams = 3 }).accel - t({ cams = 2 }).accel) < 1e-9 and t({ cams = 3, fuel = 3 }).accel > t({ cams = 2, fuel = 3 }).accel, "Race cams without Race fuel flatline (count as Sport)")
check(t({ intake = 3, exhaust = 3 }).accel - t({ exhaust = 3 }).accel > t({ intake = 3 }).accel, "the intake works best with an exhaust at its stage")
check(CarStats.pi("toyoka_chaser", { flywheel = 3 }) < CarStats.pi("toyoka_chaser") and t({ flywheel = 3 }).accel > 0, "a light flywheel is quicker but lowers the PI")
local gains = {}
for _, key in Config.CarParts.Groups.engine.parts do
	gains[key] = CarStats.pi("toyoka_chaser", { [key] = 3 }) - CarStats.pi("toyoka_chaser")
end
check(gains.displacement > gains.intake and gains.displacement > gains.cams and gains.displacement > gains.fuel, "displacement is the biggest engine PI gain")
check(Config.partCp(3, "displacement") > Config.partCp(3, "cams") and Config.partCp(3, "fuel") < Config.partCp(3, "cams"), "displacement costs the most, fuel the least")

---------------------------------------------------------------------
-- the car list
---------------------------------------------------------------------
check(Cars.StarterId == "kio_ev6" and Cars.ById.kio_ev6.Price == 0, "the Orient EV6 is the free car")
for id in Cars.RETIRED do
	check(Cars.ById[id] ~= nil and not Cars.forSale(id) and Cars.SeriesOf[id] ~= nil, "retired " .. id .. " kept (owners) but not sold")
end
check(not Cars.forSale("bentz_a45s") and Cars.ById.bentz_a45s ~= nil, "the A45 S waits for its model")
local five = Cars.SeriesOf.bnw_540i.series
check(table.concat(five.Ids, ",") == "bnw_540i,bnw_m5_e60,bnw_m5_f10,bnw_m5_f90", "5 Series ladder: 540i, M5 E60, M5 F10, M5 F90")
for _, series in Cars.Series do
	for _, id in series.Ids do
		if Cars.RETIRED[id] then
			check(false, "no retired car in a sold series: " .. id)
		end
	end
end

---------------------------------------------------------------------
-- CarLevels with stubs
---------------------------------------------------------------------
local profiles = {}
local saveOk = true
local PlayerData = {}
function PlayerData.get(p)
	return profiles[p]
end
function PlayerData.addCash(p, n)
	local pr = profiles[p]
	pr.Cash = math.max(0, math.floor(pr.Cash + n))
end
function PlayerData.save()
	return saveOk
end
local created = {}
local env = table.clone(baseEnv)
env.game = {
	GetService = function(_, name)
		if name == "HttpService" then
			return { JSONEncode = function(_, t)
				return serde.encode("json", t)
			end }
		elseif name == "Players" then
			return { PlayerRemoving = { Connect = function() end } }
		elseif name == "ReplicatedStorage" then
			return { WaitForChild = waitFor }
		end
		error(name)
	end,
}
env.script = { Parent = { WaitForChild = waitFor } }
env.require = function(x)
	if x.name == "Config" then
		return Config
	elseif x.name == "Cars" then
		return Cars
	elseif x.name == "CarStats" then
		return CarStats
	elseif x.name == "PlayerData" then
		return PlayerData
	end
	error("require " .. tostring(x.name))
end
env.task = { spawn = function(f, ...)
	f(...)
end }
local CarLevels = load("src/server/CarLevels.lua", env)

local function attrHolder()
	local attrs = {}
	return {
		attrs = attrs,
		SetAttribute = function(_, k, v)
			attrs[k] = v
		end,
		GetAttribute = function(_, k)
			return attrs[k]
		end,
	}
end
local player = attrHolder()
local carModel = attrHolder()
carModel.attrs.CarId = "toyoka_chaser"
local noted = 0
CarLevels.init({
	remote = function(class)
		local r = { ClassName = class, FireClient = function(self, _, st)
			self.last = st
		end }
		table.insert(created, r)
		return r
	end,
	getCar = function()
		return carModel
	end,
	note = function()
		noted += 1
	end,
})
local call, push
for _, r in created do
	if r.ClassName == "RemoteFunction" then
		call = r
	else
		push = r
	end
end
profiles[player] = { Loaded = true, Cash = 1000000, Owned = { toyoka_chaser = true, kio_ev6 = true } }

-- XP from driving the car: level-ups give CP
CarLevels.onPlayerXp(player, Config.carXpFor(1) - 1, "drive")
check(CarLevels.stateOf(profiles[player], "toyoka_chaser").level == 1, "just short of a level stays level 1")
CarLevels.onPlayerXp(player, 1, "cut")
local st = CarLevels.stateOf(profiles[player], "toyoka_chaser")
check(st.level == 2 and st.cp == Config.CarLevels.CpPerLevel and st.xp == 0, "a level-up gives CP")
check(push.last and push.last.levelUp == true and push.last.carId == "toyoka_chaser", "the client hears about the level-up")
CarLevels.onPlayerXp(player, 500, "goal")
check(CarLevels.stateOf(profiles[player], "toyoka_chaser").xp == 0, "goal XP doesn't count for the car")
carModel.attrs.TestEnds = 123
CarLevels.onPlayerXp(player, 500, "drive")
check(CarLevels.stateOf(profiles[player], "toyoka_chaser").xp == 0, "a test drive earns no car XP")
carModel.attrs.TestEnds = nil

-- the whole climb to 50: the XP it takes and the time at ~1.5 XP a second
local total = 0
for l = 1, Config.CarLevels.Max - 1 do
	total += Config.carXpFor(l)
end
print(string.format("     1 -> %d: %d car XP, %.1f h at 1.5 XP/s", Config.CarLevels.Max, total, total / 1.5 / 3600))
check(total / 1.5 / 3600 >= 2.4 and total / 1.5 / 3600 <= 3.1, "level 50 in about 2.5-3 hours")

-- parts: CP and cash, stages in order, the server's checks
local r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "cp" })
check(not r.ok, "not enough CP is refused (" .. tostring(r.message) .. ")")
CarLevels.add(player, "toyoka_chaser", 2000) -- a few more levels
local cp0 = CarLevels.stateOf(profiles[player], "toyoka_chaser").cp
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "cp" })
check(r.ok and r.stage == 1 and CarLevels.stateOf(profiles[player], "toyoka_chaser").cp == cp0 - Config.partCp(1, "intake"), "Street intake bought with CP")
check(carModel.attrs.Parts == "intake=1", "the car out gets its parts at once")
local cash0 = profiles[player].Cash
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "cash" })
check(r.ok and r.stage == 2 and profiles[player].Cash == cash0 - Config.partCash(2, Cars.ById.toyoka_chaser.Price, "intake"), "Sport intake bought with cash")
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "brakes", pay = "cash" })
check(r.ok and r.stage == 1, "any part in any order from the start")
r = call.OnServerInvoke(player, "buyPart", { car = "bnw_m5_f90", part = "intake", pay = "cash" })
check(not r.ok, "a car you don't own is refused")
profiles[player].Owned.bugotti_chiron = true
r = call.OnServerInvoke(player, "buyPart", { car = "bugotti_chiron", part = "displacement", pay = "cash" })
check(not r.ok, "no engine parts for a stock X car (" .. tostring(r.message) .. ")")
r = call.OnServerInvoke(player, "buyPart", { car = "bugotti_chiron", part = "gearbox", pay = "cash" })
check(r.ok, "a gearbox for a stock X car")
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "nitro", pay = "cash" })
check(not r.ok, "an unknown part is refused")
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "robux" })
check(not r.ok, "only CP or cash")
call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "cash" })
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "intake", pay = "cash" })
check(not r.ok, "no fourth stage")
saveOk = false
cash0 = profiles[player].Cash
r = call.OnServerInvoke(player, "buyPart", { car = "toyoka_chaser", part = "turbo", pay = "cash" })
check(not r.ok and profiles[player].Cash == cash0 and CarLevels.partsOf(player, "toyoka_chaser").turbo == nil, "a failed save puts the purchase back")
saveOk = true
check(noted >= 3, "parts count for the goals")

-- brand discounts: 5% per level-50 car of the brand, at most 25%
local apex = {}
for _, spec in Cars.All do
	if Cars.SeriesOf[spec.Id].series.Brand == "APEX" then
		table.insert(apex, spec.Id)
	end
end
check(#apex >= 6, "Apex has six cars or more to test with (" .. #apex .. ")")
for i = 1, 6 do
	profiles[player].Owned[apex[i]] = true
	CarLevels.add(player, apex[i], 100000)
	local want = math.min(0.25, i * 0.05)
	check(math.abs(CarLevels.brandOff(player, apex[i]) - want) < 1e-9, string.format("%d Apex cars at level 50: %d%% off", i, math.floor(want * 100 + 0.5)))
end
check(CarLevels.brandOff(player, "bnw_m5_f90") == 0, "no discount on another brand")
check(CarLevels.priceFor(player, "toyoka_supra_mk4") == math.floor(Cars.ById.toyoka_supra_mk4.Price * 0.75 / 100 + 0.5) * 100, "the dealer price has the discount off")
check(type(player.attrs.BrandOff) == "string" and string.find(player.attrs.BrandOff, "APEX") ~= nil, "the BrandOff attribute is published")
check(CarLevels.stateOf(profiles[player], apex[1]).level == Config.CarLevels.Max, "levels stop at 50")

---------------------------------------------------------------------
-- an old save that owns retired cars still loads with them
---------------------------------------------------------------------
local saved = {
	Cash = 1234,
	Owned = { "suzaki_swift", "bnw_530i", "chevo_c6", "suzaki_swift_top", "bentz_cla45_sport", "no_such_car" },
	Selected = "bnw_530i",
	Level = 12,
	CarLevels = { suzaki_swift = 7, bogus = 3, bnw_530i = 99 },
	CarParts = { suzaki_swift = { intake = 2, bogus = 1, tyres = 7 }, bugotti_chiron = { displacement = 2, tyres = 1 } },
}
local penv = table.clone(baseEnv)
penv.game = {
	GetService = function(_, name)
		if name == "DataStoreService" then
			return { GetDataStore = function()
				return { GetAsync = function()
					return saved
				end, SetAsync = function() end, UpdateAsync = function(_, _, fn)
					return fn(saved)
				end }
			end }
		elseif name == "Players" then
			return { GetPlayers = function()
				return {}
			end }
		elseif name == "ReplicatedStorage" then
			return { WaitForChild = waitFor }
		elseif name == "HttpService" then
			return { GenerateGUID = function()
				return "test-session"
			end }
		elseif name == "RunService" then
			return { IsStudio = function()
				return true
			end }
		end
		error(name)
	end,
}
penv.require = env.require
penv.warn = function() end
penv.os = os
local folders = {}
penv.Instance = { new = function(class)
	local t = { ClassName = class, Value = 0 }
	table.insert(folders, t)
	return t
end }
local RealPlayerData = load("src/server/PlayerData.lua", penv)
local oldPlayer = { UserId = 42, Name = "Old", Parent = {} }
local pr = RealPlayerData.load(oldPlayer)
check(pr.Owned.suzaki_swift and pr.Owned.bnw_530i and pr.Owned.chevo_c6 and pr.Owned.suzaki_swift_top and pr.Owned.bentz_cla45_sport, "an old save keeps its retired cars")
check(pr.Owned.kio_ev6 == true, "and gets the free car")
check(pr.Selected == "bnw_530i", "its selected retired car stays selected")
check(pr.CarLevels.suzaki_swift == 7 and pr.CarLevels.bogus == nil and pr.CarLevels.bnw_530i == Config.CarLevels.Max, "car levels cleaned on load")
check(pr.CarParts.suzaki_swift.intake == 2 and pr.CarParts.suzaki_swift.bogus == nil and pr.CarParts.suzaki_swift.tyres == nil, "car parts cleaned on load")
check(pr.CarParts.bugotti_chiron.displacement == nil and pr.CarParts.bugotti_chiron.tyres == 1, "a top car's not-allowed part is dropped on load")

print(if fails == 0 then "ALL OK" else fails .. " FAILED")
if fails > 0 then
	process.exit(1)
end
