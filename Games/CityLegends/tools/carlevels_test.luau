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
local PartData = load("src/shared/PartData.lua", baseEnv)
local senv = table.clone(baseEnv)
senv.script = { Parent = { WaitForChild = waitFor } }
senv.require = function(x)
	if x.name == "Config" then
		return Config
	elseif x.name == "Cars" then
		return Cars
	elseif x.name == "PartData" then
		return PartData
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
-- the best part in every slot
local function bestSet(): { [string]: string }
	local full = {}
	for slot, list in PartData.BySlot do
		if slot ~= "swap" then
			local best, bestA = nil, -1
			for _, def in list do
				local v = (def.fx.accel or 0) + (def.fx.grip or 0) + (def.fx.weight or 0) + (def.fx.brake or 0)
				if v > bestA then
					best, bestA = def, v
				end
			end
			full[slot] = best.id
		end
	end
	return full
end
local full = bestSet()
check(CarStats.pi("toyoka_chaser", full) > CarStats.pi("toyoka_chaser"), "parts raise the PI")
check(CarStats.decodeParts(CarStats.encodeParts({ intake = "in_short", tyres = "ty_slick" })).intake == "in_short", "parts survive the attribute")
check(next(CarStats.decodeParts("engine=9,bogus=1,turbo=x,intake=ty_slick")) == nil, "bad parts text is dropped")
-- the data: every part in a real slot, brands of our own, a rarity, a price, an icon
local BRANDS = { ["Ferrolux"] = true, ["Kestrel Works"] = true, ["Tachyon"] = true, ["Steelvein"] = true, ["Pulsewerk"] = true, ["Nightcoil"] = true, ["Draxa"] = true, ["Corvin Motorsport"] = true }
local count, swaps = 0, 0
for id, def in PartData.Parts do
	count += 1
	if def.engine then
		swaps += 1
	end
	if not (PartData.Slots[def.slot] and BRANDS[def.brand] and PartData.Rarity[def.rarity] and def.list > 0 and def.id == id) then
		check(false, "part data: " .. id)
	end
end
check(swaps == 43, "43 engine swaps (" .. swaps .. ")")
check(count >= 68 + 43, "every part on the two icon sheets and more (" .. count .. ")")
for _, need in { "Pop Tune ECU", "Crackle Tune ECU", "Burble Tune ECU", "Muffler Delete", "Straight Pipe", "Catless Downpipe", "Decat Pipe", "Anti-Lag Map", "Rev Limiter Raise", "Nitrous Kit", "Drift Angle Kit", "Air Suspension", "Twin-Screw Supercharger", "Big Single Turbo", "Sequential Gearbox", "Roll Cage" } do
	local found = false
	for _, def in PartData.Parts do
		found = found or def.name == need
	end
	check(found, "the shop has the " .. need)
end
for _, def in PartData.SwapList do
	for _, word in { "VTEC", "EcoBoost", "Coyote", "Hemi", "Hellcat", "TFSI", "AMG" } do
		if string.find(string.lower(def.name), string.lower(word), 1, true) then
			check(false, "a maker's word in " .. def.name)
		end
	end
end
-- stock S2 / R / X cars: only tyres, gearbox, suspension and exhaust (owner, 2026-11-03)
for _, spec in Cars.All do
	local top = Config.CarParts.TopClasses[(CarStats.classOf(spec.Id))]
	for id, def in PartData.Parts do
		local allowed = CarStats.partAllowed(spec.Id, id)
		if allowed ~= ((not top) or PartData.Slots[def.slot].top == true or def.sound == true) then
			check(false, "part rule for " .. spec.Id .. " " .. id)
		end
	end
end
check(not CarStats.partAllowed("bugotti_chiron", "bl_bigbore") and CarStats.partAllowed("bugotti_chiron", "ty_sport") and CarStats.partAllowed("bugotti_chiron", "mf_straight") and CarStats.partAllowed("bugotti_chiron", "ecu_pop"), "the top cars' rule, sound parts are fine")
check(not CarStats.partAllowed("bugotti_chiron", "sw_2jz"), "no swap on a stock X car")
check(CarStats.partAllowed("bnw_m5_f90", "in_cold") and CarStats.partAllowed("toyoka_chaser", "wr_3"), "cars below S2 take every part")
check(CarStats.pi("bugotti_chiron", { block = "bl_bigbore", cams = "cam_3" }) == CarStats.pi("bugotti_chiron"), "a not-allowed part does nothing on a top car")
check(CarStats.pi("bugotti_chiron", { tyres = "ty_slick" }) > CarStats.pi("bugotti_chiron"), "tyres still help a top car")
check(not (CarStats.fits("kio_ev6", "mf_straight")) and not (CarStats.fits("kio_ev6", "sw_2jz")) and (CarStats.fits("kio_ev6", "ecu_1")) and (CarStats.fits("kio_ev6", "ty_sport")), "electric cars: no exhaust, no swap, software and tyres")
local fw = CarStats.tuneOf({ flywheel = "fw_alloy" })
check(CarStats.pi("toyoka_chaser", { flywheel = "fw_alloy" }) < CarStats.pi("toyoka_chaser") and fw.accel > 0, "a light flywheel is quicker but lowers the PI")
local function gain(slot: string, id: string): number
	return CarStats.pi("toyoka_chaser", { [slot] = id }) - CarStats.pi("toyoka_chaser")
end
check(gain("block", "bl_bigbore") > gain("intake", "in_ram") and gain("block", "bl_bigbore") > gain("cams", "cam_3"), "displacement is the biggest engine PI gain")
-- what needs what
check(not (CarStats.fits("toyoka_chaser", "bov_std", {})) and (CarStats.fits("toyoka_chaser", "bov_std", { induction = "tb_ball" })), "a blow-off valve needs a turbo")
check(not (CarStats.fits("toyoka_chaser", "bc_pulley", { induction = "tb_ball" })) and (CarStats.fits("toyoka_chaser", "bc_pulley", { induction = "sc_screw" })), "a pulley needs a supercharger")
check((CarStats.fits("toyoka_chaser", "bov_std", { swap = "sw_2jz" })), "a turbo engine counts as a turbo")
check(CarStats.tuneOf({ bov = "bov_std" }).accel == 0 and CarStats.tuneOf({ induction = "tb_ball", bov = "bov_std" }).bov, "a part that waits for a turbo does nothing")
check(CarStats.tuneOf({ downpipe = "dp_catless", induction = "tb_ball" }).accel > CarStats.tuneOf({ induction = "tb_ball" }).accel + 0.008, "a downpipe gives more with a turbo")
check(CarStats.tuneOf({ muffler = "mf_straight", ecu = "ecu_crackle" }).pop == "crackle" and CarStats.tuneOf({ muffler = "mf_straight" }).loud == 3, "sound parts")
-- engine swaps
do
	local hp0 = CarStats.powerOf("nisun_350z", { swap = "sw_2jz" })
	check(math.abs(hp0 - 320) < 1, "a swapped engine starts at its stock power")
	local set = table.clone(full)
	set.swap = "sw_2jz"
	local hpMax = CarStats.powerOf("nisun_350z", set)
	check(hpMax > 800 and hpMax <= 900.5, "tuned, it reaches its tuned max (" .. math.floor(hpMax) .. ")")
	local a, _, pa = CarStats.classOf("nisun_350z")
	local b, _, pb = CarStats.classOf("nisun_350z", { swap = "sw_2jz", induction = "tb_scroll" })
	check(pb > pa, "a swap moves the PI (" .. a .. " " .. pa .. " -> " .. b .. " " .. pb .. ")")
	check(CarStats.redlineOf("nisun_350z", { swap = "sw_f20" }) == 9, "a swap brings its own rev limit")
	check(CarStats.redlineOf("nisun_350z", { ecu = "ecu_limiter" }) > CarStats.redline("nisun_350z"), "the rev limiter raise")
	check(CarStats.of("nisun_350z").drive == "RWD" and CarStats.tunedSpec("nisun_350z", set).ZeroToSixty >= 2.6, "a swap can't beat the tyres: no 1.6 s RWD car")
	local dy = CarStats.dyno("nisun_350z", set)
	check(#dy.points == 28 and math.abs(dy.hp - hpMax) < 1 and dy.redline > 6000, "the dyno's curve peaks at the car's power")
end
-- settings
do
	local setup = CarStats.cleanSetup({ final = 5, ride = -0.5, nope = 1, press = 0 / 0 })
	check(setup.final == 1 and setup.ride == -0.5 and setup.nope == nil and setup.press == nil, "settings are clamped and checked")
	check(CarStats.decodeSetup(CarStats.encodeSetup(setup)).ride == -0.5, "settings survive the attribute")
	local base = Cars.get("nisun_350z")
	local tuned = CarStats.tunedSpec("nisun_350z", {}, { final = 1 })
	check(tuned.TopSpeed > base.TopSpeed and tuned.ZeroToSixty > base.ZeroToSixty, "final drive trades pull for top speed")
	check(CarStats.pi("nisun_350z") == CarStats.pi("nisun_350z", {}), "settings don't count for the PI")
end
-- prices
check(select(1, CarStats.partPrice("nisun_350z", "in_cold")) == 1300 and select(1, CarStats.partPrice("nisun_350z", "sw_2jz")) == 2500000, "prices: a tenth of the list on the cheapest cars, swaps at the list")
check(select(1, CarStats.partPrice("bugotti_veyron", "tb_ball")) > select(1, CarStats.partPrice("nisun_350z", "tb_ball")) * 3, "dearer cars pay more")
check(select(2, CarStats.partPrice("nisun_350z", "bl_stroker")) == nil and select(2, CarStats.partPrice("nisun_350z", "sw_2jz")) == nil and select(2, CarStats.partPrice("nisun_350z", "in_ram")) == 10, "Legendary and swaps are cash only")

-- an old save: every car, every old set of parts: the same or a little better, never worse
do
	local OLD = {
		intake = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.015 } },
		fuel = { { accel = 0.005 }, { accel = 0.01 }, { accel = 0.02 } },
		flywheel = { { accel = 0.005, weight = 0.003, pi = -3 }, { accel = 0.01, weight = 0.006, pi = -6 }, { accel = 0.015, weight = 0.01, pi = -10 } },
		cams = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.02 } },
		displacement = { { accel = 0.02, speed = 0.01 }, { accel = 0.04, speed = 0.015 }, { accel = 0.06, speed = 0.025 } },
		turbo = { { accel = 0.02, speed = 0.01 }, { accel = 0.04, speed = 0.02 }, { accel = 0.06, speed = 0.03 } },
		exhaust = { { accel = 0.01, speed = 0.005 }, { accel = 0.02, speed = 0.01 }, { accel = 0.035, speed = 0.015 } },
		gearbox = { { accel = 0.015, speed = 0.01 }, { accel = 0.03, speed = 0.02 }, { accel = 0.05, speed = 0.03 } },
		tyres = { { grip = 0.02, brake = 0.03 }, { grip = 0.04, brake = 0.06 }, { grip = 0.07, brake = 0.1 } },
		brakes = { { brake = 0.08 }, { brake = 0.16 }, { brake = 0.25 } },
		suspension = { { grip = 0.015 }, { grip = 0.03 }, { grip = 0.05 } },
		weight = { { weight = 0.03 }, { weight = 0.06 }, { weight = 0.1 } },
	}
	-- the old sums, with the old rules (Race cams need Race fuel, an intake past the exhaust gives half)
	local function oldTune(parts)
		local t = { accel = 0, speed = 0, grip = 0, brake = 0, weight = 0 }
		local k = 1
		for key, stage in parts do
			if key == "cams" and stage >= 3 and (parts.fuel or 0) < 3 then
				stage = 2
			end
			local fx = table.clone(OLD[key][stage])
			local ex = parts.exhaust or 0
			if key == "intake" and stage > ex then
				local low = if ex > 0 then OLD.intake[ex] else {}
				for f, v in fx do
					fx[f] = (low[f] or 0) + (v - (low[f] or 0)) * 0.5
				end
			end
			k *= 1 - (fx.accel or 0)
			t.speed += fx.speed or 0
			t.grip += fx.grip or 0
			t.brake += fx.brake or 0
			t.weight += fx.weight or 0
		end
		k *= (1 - t.weight) ^ 0.5
		t.accel = 1 - k
		return t
	end
	local keys = {}
	for key in OLD do
		table.insert(keys, key)
	end
	table.sort(keys)
	local seed = 11
	local function rnd(n)
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n
	end
	local tested, worse = 0, 0
	for _, spec in Cars.All do
		local top = Config.CarParts.TopClasses[(CarStats.classOf(spec.Id))]
		for try = 1, 12 do
			local old = {}
			for _, key in keys do
				local stage = if try == 1 then 3 else rnd(4)
				local allowed = not top or key == "tyres" or key == "gearbox" or key == "suspension" or key == "exhaust"
				if stage > 0 and allowed then
					old[key] = stage
				end
			end
			local t = oldTune(old)
			local now = PartData.migrate(old)
			local tuned = CarStats.tunedSpec(spec.Id, now)
			local zts = math.max(1.6, spec.ZeroToSixty * (1 - t.accel))
			local top_ = math.floor(spec.TopSpeed * (1 + t.speed) + 0.5)
			local hand = math.min(0.99, spec.Handling + t.grip)
			tested += 1
			if tuned.ZeroToSixty > zts + 1e-6 or tuned.TopSpeed < top_ or tuned.Handling < hand - 1e-6 then
				worse += 1
				print("WORSE", spec.Id, try, tuned.ZeroToSixty, zts, tuned.TopSpeed, top_, tuned.Handling, hand)
			end
			for key, stage in old do
				local map = PartData.OldParts[key]
				if now[map.slot] ~= map[stage] then
					worse += 1
					print("NOT MOVED", spec.Id, key)
				end
			end
		end
	end
	check(worse == 0, string.format("an old save's parts move and no car gets worse (%d sets of parts)", tested))
	local moved = PartData.migrate({ intake = 2, exhaust = 1, bogus = 1, tyres = 7 })
	check(moved.intake == "in_short" and moved.midpipe == "mp_sport" and moved.bogus == nil and moved.tyres == nil, "Street, Sport and Race become Uncommon, Rare and Epic; bad ones are dropped")
	check(PartData.migrate(moved).intake == "in_short", "a moved save stays as it is")
end

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
	elseif x.name == "PartData" then
		return PartData
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

-- parts: buy, install, take off, move, sell, builds: the server's checks
local function ask(what, arg)
	return call.OnServerInvoke(player, what, arg)
end
local pr0 = profiles[player]
local r = ask("buy", { car = "toyoka_chaser", part = "in_cold", pay = "cp", install = true })
check(not r.ok, "not enough CP is refused (" .. tostring(r.message) .. ")")
CarLevels.add(player, "toyoka_chaser", 2000) -- a few more levels
local cp0 = CarLevels.stateOf(pr0, "toyoka_chaser").cp
r = ask("buy", { car = "toyoka_chaser", part = "in_cold", pay = "cp", install = true })
check(r.ok and CarLevels.stateOf(pr0, "toyoka_chaser").cp == cp0 - 2, "an Uncommon intake bought with CP and installed")
check(carModel.attrs.Parts == "intake=in_cold", "the car out gets its parts at once")
local cash0 = pr0.Cash
local price = CarStats.partPrice("toyoka_chaser", "in_short")
r = ask("buy", { car = "toyoka_chaser", part = "in_short", pay = "cash", install = true })
check(r.ok and pr0.Cash == cash0 - price and #(pr0.PartBag.in_cold or {}) == 1, "a better part goes in, the old one to My Parts")
r = ask("buy", { car = "bnw_m5_f90", part = "in_cold", pay = "cash" })
check(not r.ok, "a car you don't own is refused")
pr0.Owned.bugotti_chiron = true
r = ask("buy", { car = "bugotti_chiron", part = "bl_bigbore", pay = "cash", install = true })
check(not r.ok, "no engine parts for a stock X car (" .. tostring(r.message) .. ")")
r = ask("buy", { car = "bugotti_chiron", part = "gb_close", pay = "cash", install = true })
check(r.ok, "a gearbox for a stock X car")
r = ask("buy", { car = "toyoka_chaser", part = "nitro", pay = "cash" })
check(not r.ok, "an unknown part is refused")
r = ask("buy", { car = "toyoka_chaser", part = "in_cold", pay = "robux" })
check(not r.ok, "only CP or cash")
r = ask("buy", { car = "toyoka_chaser", part = "bl_stroker", pay = "cp" })
check(not r.ok, "Legendary parts are cash only")
r = ask("buy", { car = "toyoka_chaser", part = "bov_std", pay = "cash", install = true })
check(not r.ok, "a blow-off valve needs a turbo first")
saveOk = false
cash0 = pr0.Cash
local bag0 = #(pr0.PartBag.in_cold or {})
r = ask("buy", { car = "toyoka_chaser", part = "tb_ball", pay = "cash", install = true })
check(not r.ok and pr0.Cash == cash0 and CarLevels.partsOf(player, "toyoka_chaser").induction == nil, "a failed save puts the purchase back")
r = ask("install", { car = "toyoka_chaser", part = "in_cold" })
check(not r.ok and CarLevels.partsOf(player, "toyoka_chaser").intake == "in_short" and #(pr0.PartBag.in_cold or {}) == bag0, "a failed save puts an install back")
saveOk = true
check(noted >= 3, "parts count for the goals")
-- moving a part: off one car, onto another; a dearer car pays the difference, once
pr0.Owned.bnw_m5_f90 = true
r = ask("uninstall", { car = "toyoka_chaser", slot = "intake" })
check(r.ok and CarLevels.partsOf(player, "toyoka_chaser").intake == nil and #pr0.PartBag.in_short == 1, "uninstalling puts the part in My Parts")
local kA, kB = Config.partK(Cars.ById.toyoka_chaser.Price), Config.partK(Cars.ById.bnw_m5_f90.Price)
check(kB > kA, "the second car is dearer")
local fee = Config.partCash(PartData.Parts.in_short.list, kB) - Config.partCash(PartData.Parts.in_short.list, kA)
cash0 = pr0.Cash
r = ask("install", { car = "bnw_m5_f90", part = "in_short" })
check(r.ok and r.fee == fee and pr0.Cash == cash0 - fee and CarLevels.partsOf(player, "bnw_m5_f90").intake == "in_short" and pr0.PartBag.in_short == nil, "a part moves to a dearer car for the difference")
r = ask("uninstall", { car = "bnw_m5_f90", slot = "intake" })
cash0 = pr0.Cash
r = ask("install", { car = "toyoka_chaser", part = "in_short" })
check(r.ok and r.fee == 0 and pr0.Cash == cash0, "and back to a cheaper car for nothing")
r = ask("install", { car = "toyoka_chaser", part = "cam_3" })
check(not r.ok, "you can't fit a part you don't have")
-- selling: 50% of what it was paid
r = ask("buy", { car = "toyoka_chaser", part = "cam_2", pay = "cash" })
price = CarStats.partPrice("toyoka_chaser", "cam_2")
cash0 = pr0.Cash
r = ask("sell", { part = "cam_2" })
check(r.ok and pr0.Cash == cash0 + math.floor(price * 0.5 / 100 + 0.5) * 100 and pr0.PartBag.cam_2 == nil, "selling gives back 50%")
r = ask("sell", { part = "cam_2" })
check(not r.ok, "you can't sell what you haven't got")
-- builds: parts move between them
r = ask("saveBuild", { car = "toyoka_chaser", n = 1 })
check(r.ok, "a build saved")
ask("buy", { car = "toyoka_chaser", part = "wr_1", pay = "cash", install = true })
r = ask("saveBuild", { car = "toyoka_chaser", n = 2 })
check(r.ok, "a second build saved")
r = ask("useBuild", { car = "toyoka_chaser", n = 1 })
check(r.ok and CarLevels.partsOf(player, "toyoka_chaser").weight == nil and CarLevels.partsOf(player, "toyoka_chaser").intake == "in_short" and #pr0.PartBag.wr_1 == 1, "switching takes the other build's parts off")
r = ask("useBuild", { car = "toyoka_chaser", n = 2 })
check(r.ok and r.missing == 0 and CarLevels.partsOf(player, "toyoka_chaser").weight == "wr_1" and pr0.PartBag.wr_1 == nil, "and back on in one tap")
r = ask("useBuild", { car = "toyoka_chaser", n = 9 })
check(not r.ok, "no build 9")
-- settings
r = ask("setup", { car = "toyoka_chaser", values = { final = 9, launch = 0.7, bad = 1 } })
check(r.ok and pr0.CarSetup.toyoka_chaser.final == 1 and pr0.CarSetup.toyoka_chaser.bad == nil and string.find(carModel.attrs.Setup, "launch=0.70", 1, true) ~= nil, "settings saved, clamped, on the car")
r = ask("setup", { car = "bnw_m5_e60", values = {} })
check(not r.ok, "no settings on a car you don't own")
-- rare drops: fully paid, so they fit anything with no fee
local id = CarLevels.givePart(player, "Legendary")
check(id ~= nil and PartData.Parts[id].rarity == "Legendary" and not PartData.Parts[id].engine and pr0.PartBag[id][1] == Config.CarParts.CashMax, "a drop goes to My Parts, fully paid")

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
	PartBag = { in_cold = { 1.5, "x", 99 }, nothing = { 1 } },
	CarSetup = { suzaki_swift = { final = 3, bad = 1 } },
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
check(pr.CarParts.suzaki_swift.intake == "in_short" and pr.CarParts.suzaki_swift.bogus == nil and pr.CarParts.suzaki_swift.tyres == nil, "an old save's parts become the new parts on load, bad ones cleaned")
check(pr.CarParts.bugotti_chiron.block == nil and pr.CarParts.bugotti_chiron.tyres == "ty_road", "a top car's not-allowed part is dropped on load")

check(#pr.PartBag.in_cold == 1 and pr.PartBag.nothing == nil and pr.CarSetup.suzaki_swift.final == 1 and pr.CarSetup.suzaki_swift.bad == nil, "spare parts and settings cleaned on load")


---------------------------------------------------------------------
-- one Urus only, two 458s (2026-11-07): the old Urus's owners get the new one on load
---------------------------------------------------------------------
check(not Cars.forSale("lambrini_urus") and Cars.forSale("lambrini_urusp") and Cars.get("lambrini_urusp").Name == "Enfurecido Brava", "one Urus on sale, named Enfurecido Brava")
check(Cars.ById.lambrini_urusp_sport == nil and Cars.ById.lambrini_urusp_top == nil and Cars.get("lambrini_urusp").Price == 1900000, "no Urus trims, price kept")
for _, series in Cars.Series do
	if series.Name == "ENFURECIDO BRAVA" then
		check(#series.Ids == 1 and series.Ids[1] == "lambrini_urusp", "the Brava line has one car")
	elseif series.Name == "ROSSO RAMPANTE F142" then
		check(#series.Ids == 2 and series.Ids[1] == "ferrara_458spider" and series.Ids[2] == "ferrara_458speciale", "the F142 line is the Spider and the Speciale")
	end
	check(series.Name ~= "ROSSO RAMPANTE F142 COUPE" and series.Name ~= "ENFURECIDO BRAVA OLD", "no retired line on sale: " .. series.Name)
end
check(not Cars.forSale("ferrara_458") and Cars.ById.ferrara_458 ~= nil, "the 458 Italia is off sale, owners keep it")
for _, spec in Cars.List do
	check(spec.Id ~= "lambrini_urus" and spec.Id ~= "ferrara_458", "not in the list: " .. spec.Id)
end
check(Config.Chauffeur.Fleet.lambrini_urus == nil and Config.Chauffeur.Fleet.lambrini_urusp == 1900000 and table.find(Config.Chauffeur.Order, "lambrini_urusp") ~= nil and table.find(Config.Chauffeur.Order, "lambrini_urus") == nil, "the chauffeur fleet uses the new Urus")

saved = {
	Claimed = true,
	Owned = { "kio_ev6", "lambrini_urus", "ferrara_458" },
	Selected = "lambrini_urus",
	CarLevels = { lambrini_urus = 20 },
	CarXP = { lambrini_urus = 33 },
	CarCP = { lambrini_urus = 5 },
	CarParts = { lambrini_urus = { tyres = "ty_road" } },
	CarSetup = { lambrini_urus = { final = 1 } },
	Customs = { lambrini_urus = { paint = "red" } },
	Chauffeur = { lambrini_urus = true },
	Market = { Stash = { { u = "a", c = "lambrini_urus", k = "Clean", p = 10 } } },
	Settings = { Favs = { "lambrini_urus", "kio_ev6" } },
}
local one = RealPlayerData.load({ UserId = 43, Name = "OneUrus", Parent = {} })
check(one.Owned.lambrini_urusp and not one.Owned.lambrini_urus and one.Owned.ferrara_458, "the old Urus becomes the new one, the 458 Italia stays")
check(one.Selected == "lambrini_urusp", "selected moves too")
check(one.CarLevels.lambrini_urusp == 20 and one.CarXP.lambrini_urusp == 33 and one.CarCP.lambrini_urusp == 5, "level, XP and CP move")
check(one.CarParts.lambrini_urusp and one.CarParts.lambrini_urusp.tyres == "ty_road" and one.CarSetup.lambrini_urusp.final == 1 and one.Customs.lambrini_urusp.paint == "red", "parts, tune and look move")
check(one.CarLevels.lambrini_urus == nil and one.CarParts.lambrini_urus == nil and one.Customs.lambrini_urus == nil, "nothing left on the old id")
check(one.Chauffeur.lambrini_urusp == true and one.Chauffeur.lambrini_urus == nil, "a chauffeur contract moves")
check(table.find(one.Settings.Favs, "lambrini_urusp") ~= nil and table.find(one.Settings.Favs, "lambrini_urus") == nil, "favourites move")
check(one.Market.Stash[1].c == "lambrini_urusp", "a market stash unit moves")

saved = {
	Claimed = true,
	Owned = { "lambrini_urus", "lambrini_urusp" },
	Selected = "lambrini_urusp",
	CarLevels = { lambrini_urus = 30, lambrini_urusp = 11 },
	CarXP = { lambrini_urus = 7, lambrini_urusp = 90 },
	CarCP = { lambrini_urus = 4, lambrini_urusp = 2 },
	CarParts = { lambrini_urus = { tyres = "ty_road" }, lambrini_urusp = { tyres = "ty_road" } },
	Customs = { lambrini_urus = { paint = "red" }, lambrini_urusp = { paint = "blue" } },
}
local both = RealPlayerData.load({ UserId = 44, Name = "BothUrus", Parent = {} })
check(both.Owned.lambrini_urusp and not both.Owned.lambrini_urus, "owning both ends up with one")
check(both.CarLevels.lambrini_urusp == 30 and both.CarXP.lambrini_urusp == 7 and both.Customs.lambrini_urusp.paint == "red", "the better car's progress stays")
check(both.CarCP.lambrini_urusp == 4 + 10, "the other car's level CP is added")
check(both.PartBag.ty_road ~= nil and #both.PartBag.ty_road == 1, "the other car's parts go to My Parts")

saved = {
	Claimed = true,
	Owned = { "lambrini_urus", "lambrini_urusp" },
	Selected = "lambrini_urus",
	CarLevels = { lambrini_urus = 3, lambrini_urusp = 9 },
	CarCP = { lambrini_urusp = 1 },
}
local both2 = RealPlayerData.load({ UserId = 45, Name = "BothUrus2", Parent = {} })
check(both2.CarLevels.lambrini_urusp == 9 and both2.CarCP.lambrini_urusp == 3 and both2.Selected == "lambrini_urusp", "the new one kept when it's the better one")

print(if fails == 0 then "ALL OK" else fails .. " FAILED")
if fails > 0 then
	process.exit(1)
end
