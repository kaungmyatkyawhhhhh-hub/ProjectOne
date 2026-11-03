--[[
	CarStats (owner, 2026-10-31: the Legends Motors buy menu, like Midnight Racing's)
	The numbers the dealer menu shows for each car, worked out from its spec (Cars): weight, power,
	torque, power-to-weight, braking, drive, seats, gearbox, fuel, MPG and a one-line description.
	They are for show only; the car drives on its spec (TopSpeed, ZeroToSixty, Handling).
]]

local Cars = require(script.Parent:WaitForChild("Cars"))
local Config = require(script.Parent:WaitForChild("Config"))

local CarStats = {}

export type Stats = {
	kmh: number,
	mph: number,
	weightKg: number,
	hp: number,
	torqueNm: number,
	ptw: number, -- hp per tonne
	braking: number, -- 0..1
	drive: string, -- RWD / AWD / FWD
	seats: number,
	gearbox: string, -- "A" automatic, "M/A" manual or automatic, "1" one speed (electric)
	fuel: string,
	mpg: string,
	abs: boolean,
	description: string,
}

-- base weight by class (kg), a little more for the dearer cars
local WEIGHT = { Sedan = 1550, Coupe = 1480, SUV = 2250, Supercar = 1520, Hypercar = 1750 }
local SEATS = { Sedan = 5, Coupe = 4, SUV = 5, Supercar = 2, Hypercar = 2 }

-- the drive of each car line (by the base car's id); the rest is RWD
local AWD = {
	nisun_gtr = true, audy_r8 = true, lambrini_lp640 = true, lambrini_lp700 = true, lambrini_lp750 = true, lambrini_svj = true, lambrini_svj63 = true,
	lambrini_urus = true, bugotti_veyron = true, bugotti_chiron = true, bugotti_chiron_pursport = true, bugotti_chiron_supersport = true,
	porsha_panamera = true, bentlee_contgt = true,
	bentlee_bentayga = true, bentz_gle53 = true, bentz_g63 = true, brabos_g63 = true, bentz_gls = true,
	bentz_e63s = true, bnw_m5_f90 = true, bnw_m8gc = true, bnw_x6 = true, bnw_x7 = true, toyoka_lc200 = true,
	toyoka_lc300 = true, lexis_lx700 = true, astin_dbx = true, maseroti_levante = true, xiaomo_su7 = true,
	byt_u8 = true, kio_ev6 = true, bentz_cla45 = true, bentz_s680 = true, rolls_cullinan = false,
	bentz_a45s = true,
}
local FWD = { suzaki_swift = true, toyoka_belta = true, toyoka_camri = true, toyoka_alfard = true }
local MANUAL = {
	nisun_350z = true, nisun_r34 = true, mazdo_rx7 = true, mazdo_rx8 = true, toyoka_supra_mk4 = true,
	toyoka_chaser = true, bnw_m3_e92 = true, bnw_m5_e60 = true, bnw_m6_v10 = true, chevo_c6 = true,
	chevo_camaro = true, dodger_challenger = true, porsha_boxster = true, porsha_gt3 = true,
	ferrara_f430 = true, lambrini_lp570 = true, lambrini_countach = true, lexis_lfa = false,
	bentz_190e = true, suzaki_swift = true,
}
local KERB: { [string]: number } = {
	suzaki_swift = 900, toyoka_belta = 1080, kio_ev6 = 2000, byt_seal = 2150, toyoka_camri = 1550, toyoka_crown = 1800,
	toyoka_alfard = 2200, toyoka_lc200 = 2600, toyoka_lc300 = 2500, lexis_lx700 = 2600, nisun_350z = 1450, mazdo_rx7 = 1280,
	mazdo_rx8 = 1310, bnw_530i = 1650, bnw_540i = 1750, bentz_e300 = 1700, bentz_e400 = 1800, bnw_330i_g20 = 1550,
	bnw_m3_e92 = 1600, bnw_m3_f80 = 1550, bnw_m4_f82 = 1550, bnw_m5_e60 = 1830, bnw_m6_v10 = 1785, bnw_m8gc = 1950,
	bentz_cla45 = 1650, bentz_cls63s = 1950, toyoka_supra_mk4 = 1570, nisun_r34 = 1560, dodger_challenger = 1950,
	xiaomo_su7 = 2200, bnw_x6 = 2250, bnw_x7 = 2450, bentz_gle53 = 2300, bentz_g63 = 2560, byt_u8 = 3460,
	porsha_panamera = 2050, chevo_camaro = 1700, chevo_c6 = 1480, porsha_boxster = 1400, chevo_c7 = 1500,
	bentz_s63 = 2070, bentz_gt63s = 2120, nisun_gtr = 1750, astin_db9 = 1800, astin_vantage = 1630, ferrara_f430 = 1450,
	bentz_sl65bs = 1870, lambrini_lp570 = 1340, audy_r8 = 1600, mclaran_12c = 1430, ferrara_599 = 1690, ferrara_458 = 1485,
	bentz_sls = 1620, porsha_gt3 = 1430, bentlee_contgt = 2250, bentlee_bentayga = 2420, lambrini_urus = 2200,
	brabos_g63 = 2560, rolls_wraith = 2360, rolls_cullinan = 2660, lambrini_lp700 = 1575, lexis_lfa = 1480,
	lambrini_lp750 = 1525, lambrini_svj = 1525, lambrini_svj63 = 1575, lambrini_lp640 = 1665, bnw_750li = 2050,
	bentz_gls = 2500, bentz_s680 = 2250, lambrini_countach = 1450, toyoka_chaser = 1450, bentz_190e = 1230,
	bentz_s65_w221 = 2250, maseroti_levante = 2100, lexis_lc500 = 1970, astin_dbx = 2250, ferrara_california = 1735,
	bugotti_veyron = 1890, bugotti_veyron_sport = 1838, bugotti_veyron_top = 1990, bugotti_chiron = 1995, bugotti_chiron_pursport = 1945,
	bugotti_chiron_supersport = 1990, bnw_m5_f10 = 1870, bnw_m5_f90 = 1855, bentz_e63s = 1880,
	bentz_a45s = 1635,
}
-- (2026-11-03, the classes: the PI reads power-to-weight, owner: "from real performance") the real
-- power (hp) of the car each one is modelled on; a SPORT / TOP trim gets its base car's, scaled by its
-- quicker 0-60. Cars not listed work it out from the 0-60 time as before.
local POWER: { [string]: number } = {
	toyoka_camri = 203, toyoka_alfard = 250, toyoka_lc200 = 381, toyoka_lc300 = 409, lexis_lx700 = 409,
	kio_ev6 = 225, nisun_350z = 306, mazdo_rx7 = 276, bnw_540i = 335, bentz_e400 = 329,
	bnw_m3_e92 = 414, bnw_m3_f80 = 425, bnw_m4_f82 = 425, bnw_m5_e60 = 500, bnw_m6_v10 = 500,
	bnw_m8gc = 617, bentz_cls63s = 603, toyoka_supra_mk4 = 320, nisun_r34 = 330, dodger_challenger = 485,
	xiaomo_su7 = 673, bnw_x6 = 335, bnw_x7 = 523, bentz_gle53 = 429, bentz_g63 = 577, byt_u8 = 1180,
	porsha_panamera = 621, chevo_camaro = 650, porsha_boxster = 394, chevo_c7 = 460, bentz_s63 = 621,
	bentz_gt63s = 630, bnw_750li = 445, toyoka_chaser = 280, bentz_190e = 235, bentz_s65_w221 = 518,
	maseroti_levante = 550, lexis_lc500 = 471, astin_dbx = 542, nisun_gtr = 565, astin_db9 = 568,
	astin_vantage = 503, ferrara_f430 = 483, bentz_sl65bs = 661, lambrini_lp570 = 562, audy_r8 = 420,
	mclaran_12c = 592, ferrara_599 = 611, ferrara_458 = 562, bentz_sls = 563, porsha_gt3 = 500,
	bentlee_contgt = 626, bentlee_bentayga = 600, lambrini_urus = 641, brabos_g63 = 789, rolls_wraith = 624,
	rolls_cullinan = 563, lambrini_lp700 = 700, lexis_lfa = 553, lambrini_lp750 = 750, lambrini_svj = 770,
	lambrini_svj63 = 770, lambrini_lp640 = 640, bentz_gls = 550, bentz_s680 = 621, lambrini_countach = 375,
	ferrara_california = 453, bugotti_veyron = 1001, bugotti_veyron_sport = 1200, bugotti_veyron_top = 1200,
	bugotti_chiron = 1500, bugotti_chiron_pursport = 1500, bugotti_chiron_supersport = 1600,
	bnw_m5_f10 = 560, bnw_m5_f90 = 600, bentz_e63s = 603, bentz_a45s = 416,
	-- the retired cars
	suzaki_swift = 90, toyoka_belta = 106, toyoka_crown = 226, byt_seal = 201, mazdo_rx8 = 231,
	bentz_e300 = 255, bnw_530i = 248, bnw_330i_g20 = 255, bentz_cla45 = 416, chevo_c6 = 430,
}

local SEAT_OVERRIDE = { toyoka_alfard = 7, toyoka_lc300 = 7, bnw_x7 = 7, bentz_gls = 4, rolls_cullinan = 4, lexis_lx700 = 7 }

local LINES = {
	Sedan = { "A comfortable four-door for every day.", "Quick and quiet, with room for the whole crew.", "A sharp sports saloon that loves the night." },
	Coupe = { "Two doors, low and loud.", "A grand tourer for long night runs.", "Light, eager and made for corners." },
	SUV = { "Big, tall and ready for anything.", "Room for everyone, and pace to match.", "A luxury tank for the city's widest streets." },
	Supercar = { "Mid-engined and made to be seen.", "A track car you can drive to dinner.", "Pure speed, wrapped in carbon." },
	Hypercar = { "One of the fastest things on the road.", "A legend you can drive in the city.", "Built to break records." },
}

local function baseOf(spec: Cars.CarSpec): string
	return spec.BaseId or spec.Id
end

function CarStats.of(id: string): Stats
	local spec = Cars.get(id)
	local base = baseOf(spec)
	local zts = math.max(spec.ZeroToSixty, 2)
	-- heavier as it gets dearer (luxury, more kit)
	local weight = (WEIGHT[spec.Class] or 1600) + math.clamp(math.log10(math.max(spec.Price, 10000)) - 4, 0, 2.7) * 90
	if spec.Electric then
		weight += 280
	end
	if base == "suzaki_swift" or base == "toyoka_belta" then
		weight = 1020
	end
	-- (owner, 2026-11-03, realistic physics) the real kerb weight (kg) of the cars modelled on known
	-- ones; the physics uses it (braking, grip, how the turn builds, bumps, crashes)
	weight = KERB[id] or KERB[base] or weight
	-- power-to-weight from the 0-60 time (about 110 hp/t at 9.5 s, about 520 at 2.5 s), or the
	-- real power where it's known (a trim: its base car's, scaled by its quicker 0-60)
	local ptw = 110 * (9.5 / zts) ^ 1.18
	local hp = ptw * weight / 1000
	local real = POWER[id]
	if not real and spec.BaseId and POWER[spec.BaseId] then
		real = POWER[spec.BaseId] * (Cars.get(spec.BaseId).ZeroToSixty / zts) ^ 1.18
	end
	if real then
		hp = real
		ptw = real * 1000 / weight
	end
	local torque = hp * (if spec.Electric then 1.9 elseif spec.Class == "SUV" then 1.55 else 1.25)
	local drive = if AWD[base] then "AWD" elseif FWD[base] then "FWD" else "RWD"
	local seats = SEAT_OVERRIDE[base] or SEATS[spec.Class] or 4
	local gearbox = if spec.Electric then "1" elseif MANUAL[base] then "M/A" else "A"
	local mpg = if spec.Electric then "EV" else tostring(math.clamp(math.floor(60 - hp / 18 + 0.5), 9, 48))
	local lines = LINES[spec.Class] or LINES.Sedan
	local tierIdx = if spec.Tier == "Starter" then 1 elseif spec.Tier == "Mid" then 2 else 3
	return {
		kmh = math.floor(spec.TopSpeed * 1.609 + 0.5),
		mph = spec.TopSpeed,
		weightKg = math.floor(weight / 5 + 0.5) * 5,
		hp = math.floor(hp + 0.5),
		torqueNm = math.floor(torque + 0.5),
		ptw = math.floor(ptw + 0.5),
		braking = math.clamp(0.35 + spec.Handling * 0.55 + (if spec.Class == "Supercar" or spec.Class == "Hypercar" then 0.1 else 0), 0, 1),
		drive = drive,
		seats = seats,
		gearbox = gearbox,
		fuel = if spec.Electric then "Electric" elseif hp > 450 then "98 octane" else "95 octane",
		mpg = mpg,
		abs = base ~= "lambrini_countach",
		description = lines[tierIdx] or lines[1],
	}
end

-- the best numbers in the game (the bars are filled against these)
local best: { kmh: number, ptw: number, weightKg: number }? = nil
function CarStats.best(): { kmh: number, ptw: number, weightKg: number }
	if not best then
		local b = { kmh = 1, ptw = 1, weightKg = 1 }
		for _, spec in Cars.List do
			local s = CarStats.of(spec.Id)
			b.kmh = math.max(b.kmh, s.kmh)
			b.ptw = math.max(b.ptw, s.ptw)
			b.weightKg = math.max(b.weightKg, s.weightKg)
		end
		best = b
	end
	return best :: { kmh: number, ptw: number, weightKg: number }
end

-- each car's redline (x1000 rpm) for the HUD rev counter (owner, 2026-11-03: the speedometer
-- style setting, "each car's own redline from its stats"): by class, and the cars known for their
-- own (the real engines they're modelled on); electric cars read their motor up to 16,000
local REDLINE_CLASS = { Sedan = 6.5, SUV = 6.0, Coupe = 7.0, Supercar = 8.0, Hypercar = 7.5 }
local REDLINE_CAR: { [string]: number } = {
	suzaki_swift = 6.5, toyoka_belta = 6.0, toyoka_camri = 6.2, toyoka_crown = 6.2, toyoka_alfard = 6.0,
	toyoka_lc200 = 5.5, toyoka_lc300 = 5.8, lexis_lx700 = 5.8, toyoka_chaser = 7.0, toyoka_supra_mk4 = 6.8,
	nisun_350z = 7.0, nisun_r34 = 8.0, nisun_gtr = 7.0, mazdo_rx7 = 8.0, mazdo_rx8 = 9.0,
	bnw_m3_e92 = 8.3, bnw_m3_f80 = 7.3, bnw_m4_f82 = 7.3, bnw_m5_e60 = 8.25, bnw_m6_v10 = 8.25,
	bnw_m5_f10 = 7.2, bnw_m5_f90 = 7.2, bnw_m8gc = 7.2, bnw_x6 = 6.5, bnw_x7 = 6.5, bnw_750li = 6.5,
	bentz_190e = 6.5, bentz_e63s = 7.0, bentz_cla45 = 7.2, bentz_cls63s = 7.0, bentz_sls = 7.2,
	bentz_sl65bs = 6.0, bentz_s65_w221 = 6.0, bentz_g63 = 6.5, brabos_g63 = 6.5, bentz_gt63s = 7.0,
	dodger_challenger = 6.4, chevo_camaro = 6.5, chevo_c6 = 7.0, chevo_c7 = 6.6,
	porsha_boxster = 7.8, porsha_gt3 = 9.0, porsha_panamera = 6.8,
	ferrara_f430 = 8.5, ferrara_458 = 9.0, ferrara_599 = 8.4, ferrara_california = 7.5,
	audy_r8 = 8.7, mclaran_12c = 8.5, lexis_lfa = 9.0, lexis_lc500 = 7.1,
	lambrini_lp570 = 8.5, lambrini_lp640 = 8.0, lambrini_lp700 = 8.5, lambrini_lp750 = 8.5, lambrini_svj = 8.7,
	lambrini_svj63 = 8.7, lambrini_countach = 7.0, lambrini_urus = 6.8,
	astin_db9 = 7.0, astin_vantage = 7.3, astin_dbx = 6.5, bentlee_contgt = 6.5, bentlee_bentayga = 6.0,
	rolls_wraith = 5.5, rolls_cullinan = 5.0, bugotti_veyron = 6.4, maseroti_levante = 6.5,
	bugotti_chiron = 6.7, bugotti_chiron_pursport = 6.9, bugotti_chiron_supersport = 6.9,
	bentz_a45s = 7.2,
}
function CarStats.redline(id: string): number
	local spec = Cars.get(id)
	if spec and spec.Electric then
		return 16
	end
	-- (a SPORT / TOP trim revs like its base car)
	return REDLINE_CAR[id] or (spec and REDLINE_CAR[baseOf(spec)]) or REDLINE_CLASS[spec and spec.Class or "Sedan"] or 6.5
end

---------------------------------------------------------------------
-- Classes, parts and the Performance Index (owner, 2026-11-03: "car class grades and car levels")
---------------------------------------------------------------------
export type Parts = { [string]: number } -- part key -> stage (1..3), Config.CarParts

-- what a car's parts do in all: shares off the 0-60 time, onto the top speed, onto Handling, onto
-- the braking force and off the weight (Config.CarParts)
export type Tune = { accel: number, speed: number, grip: number, brake: number, weight: number, pi: number }
function CarStats.tuneOf(parts: Parts?): Tune
	local t = { accel = 0, speed = 0, grip = 0, brake = 0, weight = 0, pi = 0 }
	if not parts then
		return t
	end
	local P = Config.CarParts
	local accelK = 1
	for key, stage in parts do
		local def = P.Parts[key]
		if not (def and def.stages[stage]) then
			continue
		end
		-- the engine's rules (Config.CarParts): Race Camshafts without Race Fuel count as Sport; an
		-- intake past the exhaust's stage gives only part of the extra
		if key == "cams" and stage >= 3 and (parts.fuel or 0) < 3 then
			stage = 2
		end
		local fx: { [string]: number } = table.clone(def.stages[stage] :: any)
		local ex = parts.exhaust or 0
		if key == "intake" and stage > ex then
			local low: { [string]: number } = if ex > 0 then def.stages[ex] :: any else {}
			for k, v in fx do
				local lv = low[k] or 0
				fx[k] = lv + (v - lv) * P.IntakeOverExhaust
			end
		end
		accelK *= 1 - (fx.accel or 0)
		t.speed += fx.speed or 0
		t.grip += fx.grip or 0
		t.brake += fx.brake or 0
		t.weight += fx.weight or 0
		t.pi += fx.pi or 0
	end
	-- a lighter car also pulls harder
	accelK *= (1 - t.weight) ^ 0.5
	t.accel = 1 - accelK
	return t
end

-- a car's stock class (cached: the screens ask often)
local stockClass: { [string]: string } = {}
local function stockLetter(id: string): string
	local l = stockClass[id]
	if not l then
		l = (Config.carClass(CarStats.pi(id)))
		stockClass[id] = l
	end
	return l
end

-- whether a part can go on this car: stock S2 / R / X cars take only tyres, gearbox, suspension and
-- exhaust (Config.CarParts.TopClasses / TopAllowed)
function CarStats.partAllowed(id: string, key: string): boolean
	local P = Config.CarParts
	if not P.Parts[key] then
		return false
	end
	return not P.TopClasses[stockLetter(id)] or P.TopAllowed[key] == true
end

-- only the parts this car can take (a part saved before a rule changed does nothing)
function CarStats.cleanParts(id: string, parts: Parts?): Parts?
	if not parts or next(parts) == nil then
		return parts
	end
	local out: Parts = {}
	for key, stage in parts do
		if CarStats.partAllowed(id, key) then
			out[key] = stage
		end
	end
	return out
end

-- the car's spec with its parts on (a copy; the same Id): what Driving drives and the PI reads
function CarStats.tunedSpec(id: string, parts: Parts?): Cars.CarSpec
	local spec = Cars.get(id)
	parts = CarStats.cleanParts(id, parts)
	if not parts or next(parts) == nil then
		return spec
	end
	local t = CarStats.tuneOf(parts)
	local out = table.clone(spec)
	out.ZeroToSixty = math.max(1.6, spec.ZeroToSixty * (1 - t.accel))
	out.TopSpeed = math.floor(spec.TopSpeed * (1 + t.speed) + 0.5)
	out.Handling = math.min(0.99, spec.Handling + t.grip)
	return out
end

-- the Performance Index, 100-999: 0-60, power-to-weight, top speed, grip, braking and weight, each read on its range
-- in Config.CarClasses and weighted, then curved so the top of the field spreads out
function CarStats.pi(id: string, parts: Parts?): number
	local C = Config.CarClasses
	parts = CarStats.cleanParts(id, parts)
	local spec = CarStats.tunedSpec(id, parts)
	local base = CarStats.of(id)
	local t = CarStats.tuneOf(parts)
	local weight = base.weightKg * (1 - t.weight)
	local braking = math.clamp(base.braking * (1 + t.brake * 0.6) + t.grip * 0.5, 0, 1.15)
	-- (the power parts give more power: as much as the quicker 0-60 needs)
	local ptw = base.hp * (1 / math.max(1 - t.accel, 0.3)) ^ 1.18 * 1000 / weight
	local function k(v: number, lo: number, hi: number): number
		return math.clamp((v - lo) / (hi - lo), 0, 1.1)
	end
	local a = math.clamp(math.log(C.Accel[1] / math.max(spec.ZeroToSixty, 1)) / math.log(C.Accel[1] / C.Accel[2]), 0, 1.1)
	local p = math.clamp(math.log(ptw / C.Power[1]) / math.log(C.Power[2] / C.Power[1]), 0, 1.1)
	local w = C.Weights
	local score = w.accel * a
		+ w.power * p
		+ w.speed * k(spec.TopSpeed, C.Speed[1], C.Speed[2]) ^ C.SpeedCurve
		+ w.grip * k(spec.Handling, C.Grip[1], C.Grip[2])
		+ w.brake * braking
		+ w.weight * k(weight, C.Weight[1], C.Weight[2])
	local x = math.max(0, (score - C.Map[1]) / (C.Map[2] - C.Map[1]))
	return math.clamp(math.floor(100 + 899 * x ^ C.Curve + t.pi + 0.5), 100, 999)
end

-- the class letter and colour of a car (with parts, or stock)
function CarStats.classOf(id: string, parts: Parts?): (string, Color3, number)
	local pi = CarStats.pi(id, parts)
	local letter, color = Config.carClass(pi)
	return letter, color, pi
end

-- the player level a car needs at the dealer: only stock class X needs one (owner: "price only,
-- X needs level 60")
function CarStats.requiredLevel(id: string): number
	local letter = CarStats.classOf(id)
	return if letter == "X" then Config.CarClasses.XLevel else 1
end

-- parts to and from the car model's "Parts" attribute ("engine=2,tyres=1")
function CarStats.encodeParts(parts: Parts?): string
	local out = {}
	for _, key in Config.CarParts.Keys do
		local stage = parts and parts[key]
		if stage and stage > 0 then
			table.insert(out, key .. "=" .. stage)
		end
	end
	return table.concat(out, ",")
end
function CarStats.decodeParts(raw: any): Parts
	local parts: Parts = {}
	if type(raw) ~= "string" then
		return parts
	end
	for key, stage in string.gmatch(raw, "(%a+)=(%d)") do
		local n = tonumber(stage) :: number
		if Config.CarParts.Parts[key] and n >= 1 and n <= #Config.CarParts.Stages then
			parts[key] = n
		end
	end
	return parts
end

return CarStats
