--[[
	CarStats (owner, 2026-10-31: the Legends Motors buy menu, like Midnight Racing's)
	The numbers the dealer menu shows for each car, worked out from its spec (Cars): weight, power,
	torque, power-to-weight, braking, drive, seats, gearbox, fuel, MPG and a one-line description.
	They are for show only; the car drives on its spec (TopSpeed, ZeroToSixty, Handling).
]]

local Cars = require(script.Parent:WaitForChild("Cars"))

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
	lambrini_urus = true, bugotti_veyron = true, porsha_panamera = true, bentlee_contgt = true,
	bentlee_bentayga = true, bentz_gle53 = true, bentz_g63 = true, brabos_g63 = true, bentz_gls = true,
	bentz_e63s = true, bnw_m5_f90 = true, bnw_m8gc = true, bnw_x6 = true, bnw_x7 = true, toyoka_lc200 = true,
	toyoka_lc300 = true, lexis_lx700 = true, astin_dbx = true, maseroti_levante = true, xiaomo_su7 = true,
	byt_u8 = true, kio_ev6 = true, bentz_cla45 = true, bentz_s680 = true, rolls_cullinan = false,
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
	bugotti_veyron = 1890, bnw_m5_f10 = 1870, bnw_m5_f90 = 1855, bentz_e63s = 1880,
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
	-- power-to-weight from the 0-60 time (about 110 hp/t at 9.5 s, about 520 at 2.5 s)
	local ptw = 110 * (9.5 / zts) ^ 1.18
	local hp = ptw * weight / 1000
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
}
function CarStats.redline(id: string): number
	local spec = Cars.get(id)
	if spec and spec.Electric then
		return 16
	end
	return REDLINE_CAR[id] or REDLINE_CLASS[spec and spec.Class or "Sedan"] or 6.5
end

return CarStats
