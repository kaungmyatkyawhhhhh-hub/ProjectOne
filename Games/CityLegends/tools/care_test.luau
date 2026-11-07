-- Lune test for mileage, value, wear, repair prices, fuel and an old save (2026-11-07): src/shared/CarCare.lua.
--   lune run tools/care_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

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
local PartData = load("src/shared/PartData.lua", baseEnv)
local mods: { [string]: any } = { Config = Config, Cars = Cars, PartData = PartData }
local env = table.clone(baseEnv)
env.script = { Parent = { WaitForChild = waitFor } }
env.require = function(x)
	local m = mods[x.name]
	if m == nil then
		error("require " .. tostring(x.name))
	end
	return m
end
mods.CarStats = load("src/shared/CarStats.lua", env)
local CarCare = load("src/shared/CarCare.lua", env)

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end
local function near(a: number, b: number, by: number): boolean
	return math.abs(a - b) <= by
end

local W, V, S, F = Config.Wear, Config.Value, Config.Service, Config.Fuel
local newId, usedId, collectorId, evId
for _, spec in Cars.List do
	if spec.PriceSource == "new" and not spec.Electric and not newId and spec.Price > 300000 then
		newId = spec.Id
	elseif spec.PriceSource == "used" and not usedId then
		usedId = spec.Id
	elseif spec.PriceSource == "collector" and not collectorId then
		collectorId = spec.Id
	end
	if spec.Electric and not evId then
		evId = spec.Id
	end
end
check(newId and usedId and collectorId and evId, "found a new, used, collector and electric car")

-- new cars
local c = CarCare.fresh(newId)
check(c.m >= 0 and c.m <= 10, "a new car starts at 0-10 mi: " .. c.m)
check(c.e == 100 and c.t == 100 and c.b == 100 and c.h == 100 and c.f == 1, "a new car is healthy with a full tank")
check(CarCare.dealerMiles(usedId) >= 8000, "a used-price car comes with miles")
check(CarCare.checkEngine(c) == 0, "no light on a new car")

-- old save: miles from car XP, health fine, service due in a while
local old = CarCare.fresh(newId, 8, 500)
local total = 500
for l = 1, 7 do
	total += Config.carXpFor(l)
end
check(near(old.m - old.s, total * W.XpToMiles, 1), string.format("old save: %d mi from %d XP", old.m - old.s, total))
check(near(CarCare.dueIn(old), W.OldSaveDueIn, 1), "old save: service due in " .. CarCare.dueIn(old))
check(old.e == 100 and old.h == 100, "old save: health 100%")
check(CarCare.fresh(newId, 1, 0).m == CarCare.fresh(newId).m, "a car with no XP keeps its dealer miles")

-- junk in a save
local junk = CarCare.clean({ m = "x", e = 900, t = -5, f = 0 / 0, marks = { { k = "s", f = "L", u = 9, v = -1, n = 1 }, { k = "zz" }, 5 }, cracks = { glass = true, evil = true }, rash = 99, book = { 1, { t = 1, m = 2, k = "oil" } } }, newId)
check(junk.e == 100 and junk.t == 0 and junk.f == 1, "junk numbers are cleaned")
check(#junk.marks == 1 and junk.marks[1].u == 1 and junk.marks[1].v == 0, "junk marks are dropped, the rest clamped")
check(junk.cracks.glass == true and junk.cracks.evil == nil and junk.rash == 15, "junk cracks and rash are cleaned")
check(#junk.book == 1, "junk service book rows are dropped")

-- value
local function worth(id: string, miles: number): number
	local r = CarCare.fresh(id)
	r.m = r.s + miles
	r.last = r.m
	local _, _, mileage = CarCare.value(id, r)
	return mileage
end
check(near(worth(newId, 1000), 0.9, 0.005), "-10% by 1,000 mi")
check(near(worth(newId, 5000), 0.75, 0.005), "-25% by 5,000 mi")
check(near(worth(newId, 20000), 0.6, 0.005), "-40% by 20,000 mi")
check(near(worth(newId, 900000), V.Floor, 0.005), "the floor is 45%")
check(near(worth(collectorId, 900000), V.CollectorFloor, 0.005), "a collector's floor is 80%")
local last = 2
for miles = 0, 100000, 250 do
	local w = worth(newId, miles)
	check(w <= last + 1e-6, "value never goes up with miles: " .. miles) -- (prints a lot only when it fails)
	last = w
	if w > last then
		break
	end
end
local ok1 = CarCare.fresh(newId)
ok1.book = { { t = 1, m = 1, k = "oil" } }
local v1, price1, _, cond1 = CarCare.value(newId, ok1)
check(cond1 == 1 + V.HistoryBonus, "full history +3%")
check(v1 > price1, "a fresh serviced car can be worth a little over its price")
local bad = CarCare.fresh(newId)
bad.e, bad.t, bad.b, bad.h = 10, 10, 10, 10
bad.m = bad.last + W.ServiceEvery + 10
local _, _, _, cond2 = CarCare.value(newId, bad)
check(cond2 >= 1 - V.ConditionMax - 1e-9 and cond2 < 0.95, "condition takes at most 10%")
check(string.find(CarCare.breakdown(newId, bad), "→", 1, true) ~= nil, "breakdown: " .. CarCare.breakdown(newId, bad))

-- wear effects
local w = CarCare.fresh(newId)
w.e = 59
check(CarCare.checkEngine(w) == 1, "amber under 60")
local fx = CarCare.effects(w)
check(fx.power < 1 and fx.power > 0.9 and not fx.misfire, "a little less power under 60")
w.e = 29
fx = CarCare.effects(w)
check(CarCare.checkEngine(w) == 2 and fx.misfire and fx.power >= 0.85 - 1e-6, "flashing and misfires under 30, power " .. fx.power)
w.e = 9
fx = CarCare.effects(w)
check(fx.limp and fx.power >= 0.85 - 1e-6, "limp under 10, never dead")
w = CarCare.fresh(newId)
w.m = w.last + W.ServiceEvery + 1
check(CarCare.checkEngine(w) == 1, "amber when the service is overdue")
w = CarCare.fresh(newId)
w.t, w.b, w.h = 0, 0, 0
fx = CarCare.effects(w)
check(near(fx.grip, 1 - W.GripLoss, 1e-6) and near(fx.brake, 1 - W.BrakeLoss, 1e-6) and near(fx.handling, 1 - W.BodyLoss, 1e-6), "worn parts stay within -10% / -10% / -3%")

-- a full interval of normal driving must not reach the flashing light
local afterService = 100 - W.Engine.PerMile * W.ServiceEvery
check(afterService > W.EngineWarn, "a service interval of normal driving costs " .. (100 - afterService) .. "% engine")

-- prices against an hour's earnings
local hourly = Config.Testing and Config.Testing.HourlyEarn or 11400
local fresh = CarCare.fresh(newId)
fresh.m = fresh.last + W.ServiceEvery
fresh.e, fresh.t, fresh.b, fresh.h = 0, 0, 0, 0
local p = CarCare.prices(newId, fresh)
check(p.oil / hourly >= 0.02 and p.oil / hourly <= 0.12, string.format("oil $%d = %.0f%% of an hour", p.oil, p.oil / hourly * 100))
check(p.engine / hourly >= 0.1 and p.engine / hourly <= 0.6, string.format("engine $%d = %.0f%% of an hour", p.engine, p.engine / hourly * 100))
check(p.full < p.oil + p.engine + p.tyres + p.brakes + p.body, "a full service has a discount")
local clean = CarCare.prices(newId, CarCare.fresh(newId))
check(clean.full == 0 and clean.body == 0, "nothing to do costs nothing")
local cheap = CarCare.fresh(usedId)
cheap.m = cheap.last + 100
check(CarCare.prices(usedId, cheap).oil >= S.Oil[1] * Config.Economy.PartPriceMult - 10, "a cheap car still pays the base oil price")
check(CarCare.prices(newId, fresh).oil <= S.Oil[2] * Config.Economy.PartPriceMult * S.MaxCarK + 10, "at most x1.5 on a dear car")

-- fuel
check(CarCare.tankMinutes(150) == F.Minutes[1] and CarCare.tankMinutes(2000) == F.Minutes[2], "a tank lasts 45 to 30 minutes")
local tank = CarCare.tank(newId)
check(tank >= 45 and tank <= 110, "tank " .. tank .. " L")
local empty = CarCare.fresh(newId)
empty.f = 0
local fill = CarCare.fillPrice(newId, empty)
check(fill / hourly >= 0.005 and fill / hourly <= 0.03, string.format("a full tank $%d = %.1f%% of an hour", fill, fill / hourly * 100))
local ev = CarCare.fresh(evId)
ev.f = 0
check(CarCare.fillPrice(evId, ev) > 0, "a battery charge costs $" .. CarCare.fillPrice(evId, ev))
check(CarCare.burnLoad(0, 0) == F.Idle, "idling sips")
check(CarCare.burnLoad(120, 1) > CarCare.burnLoad(60, 0.4), "hard driving burns more")

print(if fails == 0 then "ALL OK" else fails .. " FAILED")
process.exit(if fails == 0 then 0 else 1)
