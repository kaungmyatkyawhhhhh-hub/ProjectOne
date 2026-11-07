--[[
	CarCare (shared): the sums behind mileage, value, wear, service prices and fuel (owner, 2026-11-07).
	The server keeps one record per car (profile.CarCare[id], server/Care.lua); this file only reads and works out.
	Numbers: Config.Wear, Config.Value, Config.Service, Config.Fuel.

	A record: m miles on the clock, s the miles it came with, last the miles at its last service, e t b h the engine,
	tyres, brakes and body in percent, f the fuel (0..1), d the dirt (0..1), late true if a service was ever overdue,
	book { { t = os.time, m = miles, k = what } }, marks and cracks the visible damage.
]]

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))

local CarCare = {}

export type Care = {
	m: number,
	s: number,
	last: number,
	e: number,
	t: number,
	b: number,
	h: number,
	f: number,
	d: number,
	late: boolean?,
	book: { { t: number, m: number, k: string } },
	marks: { any },
	cracks: { [string]: boolean },
	rash: number,
}

local W = Config.Wear
local V = Config.Value
local S = Config.Service
local F = Config.Fuel

local function hash(id: string): number
	local h = 7
	for i = 1, #id do
		h = (h * 31 + string.byte(id, i)) % 65521
	end
	return h
end

-- the miles a car comes with from the dealer: new 0-10, a used price a used car's, a collector a few
function CarCare.dealerMiles(id: string): number
	local spec = Cars.ById[id]
	local kind = spec and spec.PriceSource
	local h = hash(id)
	if kind == "used" then
		return 8000 + h % 32000
	elseif kind == "collector" then
		return 3000 + h % 25000
	end
	return h % 11
end

-- a car's total XP, for old saves
local function xpTotal(level: number, xp: number): number
	local total = xp
	for l = 1, level - 1 do
		total += Config.carXpFor(l)
	end
	return total
end

-- a new record: bought today (level nil), or a car from an old save (its miles from its car XP)
function CarCare.fresh(id: string, level: number?, xp: number?): Care
	local start = CarCare.dealerMiles(id)
	local driven = 0
	local last = start
	if level then
		driven = math.floor(xpTotal(level, xp or 0) * W.XpToMiles)
		last = start + driven - (W.ServiceEvery - W.OldSaveDueIn)
	end
	return { m = start + driven, s = start, last = last, e = 100, t = 100, b = 100, h = 100, f = if level then 0.8 else 1, d = 0, late = nil, book = {}, marks = {}, cracks = {}, rash = 0 }
end

-- cleans a saved record (junk in old or edited saves can't break anything)
function CarCare.clean(raw: any, id: string): Care
	local c = CarCare.fresh(id)
	if type(raw) ~= "table" then
		return c
	end
	local function num(key: string, lo: number, hi: number, def: number): number
		local v = raw[key]
		return if type(v) == "number" and v == v then math.clamp(v, lo, hi) else def
	end
	c.m = num("m", 0, 9999999, c.m)
	c.s = num("s", 0, c.m, math.min(c.s, c.m))
	c.last = num("last", 0, c.m, math.min(c.last, c.m))
	c.e, c.t, c.b, c.h = num("e", 0, 100, 100), num("t", 0, 100, 100), num("b", 0, 100, 100), num("h", 0, 100, 100)
	c.f, c.d = num("f", 0, 1, 1), num("d", 0, 1, 0)
	c.late = if raw.late == true then true else nil
	if type(raw.book) == "table" then
		for _, b in raw.book do
			if type(b) == "table" and type(b.t) == "number" and type(b.m) == "number" and type(b.k) == "string" and #c.book < 12 then
				table.insert(c.book, { t = b.t, m = b.m, k = string.sub(b.k, 1, 12) })
			end
		end
	end
	if type(raw.marks) == "table" then
		for _, k in raw.marks do
			if type(k) == "table" and #c.marks < CarCare.MaxMarks then
				local mark = CarCare.cleanMark(k)
				if mark then
					table.insert(c.marks, mark)
				end
			end
		end
	end
	if type(raw.cracks) == "table" then
		for _, key in CarCare.CrackKeys do
			if raw.cracks[key] == true then
				c.cracks[key] = true
			end
		end
	end
	c.rash = num("rash", 0, 15, 0)
	return c
end

-- visible damage: a mark is { k = "s" scrape | "t" scratch | "d" dent, f = "L" | "R" | "F" | "B", u = along the side, v = up, n = size }
CarCare.MaxMarks = 14
CarCare.CrackKeys = { "glass", "headL", "headR", "tailL", "tailR" }
local FACES = { L = true, R = true, F = true, B = true }
local KINDS = { s = true, t = true, d = true }
function CarCare.cleanMark(raw: any): { [string]: any }?
	if type(raw) ~= "table" or not FACES[raw.f] or not KINDS[raw.k] then
		return nil
	end
	local u, v, n = tonumber(raw.u), tonumber(raw.v), tonumber(raw.n)
	if not (u and v and n) or u ~= u or v ~= v or n ~= n then
		return nil
	end
	return { k = raw.k, f = raw.f, u = math.floor(math.clamp(u, 0, 1) * 100 + 0.5) / 100, v = math.floor(math.clamp(v, 0, 1) * 100 + 0.5) / 100, n = math.floor(math.clamp(n, 0.3, 1.6) * 10 + 0.5) / 10 }
end

-- miles to the next service (under 0: overdue)
function CarCare.dueIn(c: Care): number
	return c.last + W.ServiceEvery - c.m
end

-- 0 off, 1 steady, 2 flashing
function CarCare.checkEngine(c: Care): number
	if c.e < W.EngineFlash then
		return 2
	end
	if c.e < W.EngineWarn or CarCare.dueIn(c) < 0 then
		return 1
	end
	return 0
end

-- what the car's health does to it
function CarCare.effects(c: Care): { power: number, grip: number, brake: number, handling: number, limp: boolean, misfire: boolean }
	local power = 1
	if c.e < W.EngineFlash then
		power = 1 - W.PowerAtWarn - W.PowerAtFlash * (W.EngineFlash - c.e) / W.EngineFlash * (1 - W.PowerAtWarn / W.PowerAtFlash)
	elseif c.e < W.EngineWarn then
		power = 1 - W.PowerAtWarn * (W.EngineWarn - c.e) / (W.EngineWarn - W.EngineFlash)
	end
	local handling = 1
	if c.h < 40 then
		handling = 1 - W.BodyLoss * (40 - c.h) / 40
	end
	return {
		power = power,
		grip = 1 - W.GripLoss * (100 - c.t) / 100,
		brake = 1 - W.BrakeLoss * (100 - c.b) / 100,
		handling = handling,
		limp = c.e < W.EngineLimp,
		misfire = c.e < W.EngineFlash,
	}
end

-- value --------------------------------------------------------------------------------------
local function mileageShare(miles: number, floor: number): number
	local pts = V.Mileage
	local share = pts[#pts][2]
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		if miles <= b[1] then
			local k = (miles - a[1]) / (b[1] - a[1])
			k = k * k * (3 - 2 * k) * 0.35 + k * 0.65 -- smooth, no steps
			share = a[2] + (b[2] - a[2]) * k
			break
		end
	end
	-- a collector's car keeps more: its whole drop is squeezed above its own floor
	return floor + (share - V.Floor) / (1 - V.Floor) * (1 - floor)
end

-- worth, and the shares it's made of: price, mileage (0..1), condition (0.9..1.03)
function CarCare.value(id: string, c: Care): (number, number, number, number)
	local spec = Cars.ById[id]
	local price = if spec then spec.Price else 0
	local floor = if spec and spec.PriceSource == "collector" then V.CollectorFloor else V.Floor
	local mileage = mileageShare(math.max(c.m - c.s, 0), floor)
	local health = (c.e + c.t + c.b + c.h) / 4
	local condition = 1 - V.ConditionMax * math.clamp((100 - health) / 50, 0, 1)
	if CarCare.dueIn(c) < 0 then
		condition -= V.ConditionMax * 0.2
	end
	condition = math.max(condition, 1 - V.ConditionMax)
	if not c.late and #c.book > 0 and condition >= 0.99 then
		condition += V.HistoryBonus
	end
	return math.floor(price * mileage * condition / 10 + 0.5) * 10, price, mileage, condition
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. out:gsub("^,", "")
end
CarCare.money = money

-- "Price $120,000 · Mileage −18% · Condition −2% → $96,000"
function CarCare.breakdown(id: string, c: Care): string
	local value, price, mileage, condition = CarCare.value(id, c)
	local m = math.floor((1 - mileage) * 100 + 0.5)
	local k = math.floor((condition - 1) * 100 + 0.5)
	local cond = if k > 0 then "+" .. k .. "%" elseif k < 0 then "−" .. -k .. "%" else "0%"
	return string.format("Price %s · Mileage −%d%% · Condition %s → %s", money(price), m, cond, money(value))
end

function CarCare.milesText(miles: number): string
	return string.sub(money(math.floor(miles)), 2) .. " mi"
end

-- service prices -------------------------------------------------------------------------------
local function carShare(id: string): number
	local spec = Cars.ById[id]
	local price = if spec then spec.Price else 0
	return math.clamp((math.log(math.max(price, S.CarKFrom)) - math.log(S.CarKFrom)) / (math.log(S.CarKTo) - math.log(S.CarKFrom)), 0, 1)
end

local function priced(real: number, id: string): number
	local k = 1 + (S.MaxCarK - 1) * carShare(id)
	return math.floor(real * Config.Economy.PartPriceMult * k / 10 + 0.5) * 10
end

-- what each job costs now, 0 if there's nothing to do
function CarCare.prices(id: string, c: Care): { [string]: number }
	local share = carShare(id)
	local p: { [string]: number } = {}
	p.oil = if c.m > c.last + 1 then priced(S.Oil[1] + (S.Oil[2] - S.Oil[1]) * share, id) else 0
	p.engine = if c.e < 99.5 then math.max(priced(S.Engine * (100 - c.e) / 100, id), 50) else 0
	p.tyres = if c.t < 99.5 then math.max(priced((S.Tyres[1] + (S.Tyres[2] - S.Tyres[1]) * share) * (100 - c.t) / 100, id), 50) else 0
	p.brakes = if c.b < 99.5 then math.max(priced((S.Brakes[1] + (S.Brakes[2] - S.Brakes[1]) * share) * (100 - c.b) / 100, id), 50) else 0
	local hurt = (100 - c.h) / 100 + #c.marks * 0.01
	p.body = if c.h < 99.5 or #c.marks > 0 or next(c.cracks) or c.rash > 0 then math.max(priced(S.Body * math.min(hurt, 1), id), 50) else 0
	p.full = math.floor((p.oil + p.engine + p.tyres + p.brakes + p.body) * (1 - S.FullDiscount) / 10 + 0.5) * 10
	return p
end

-- fuel -------------------------------------------------------------------------------------------
-- the tank: litres (kWh on an electric car), about its real size
function CarCare.tank(id: string): number
	local base = CarStats.of(id)
	local spec = Cars.ById[id]
	if spec and spec.Electric then
		return math.floor(math.clamp(base.weightKg / 26, 58, 120) / 2 + 0.5) * 2
	end
	return math.floor(math.clamp(base.weightKg / 24, 45, 110) / 5 + 0.5) * 5
end

-- minutes a full tank lasts at normal driving (hp: the car's power now)
function CarCare.tankMinutes(hp: number): number
	local k = math.clamp((hp - F.PowerFrom) / (F.PowerTo - F.PowerFrom), 0, 1)
	return F.Minutes[1] + (F.Minutes[2] - F.Minutes[1]) * k
end

-- how hard the engine works: 1 is normal driving
function CarCare.burnLoad(mph: number, throttle: number): number
	if mph < 3 then
		return F.Idle
	end
	return 0.55 + 0.6 * math.clamp(throttle, 0, 1) + 0.2 * math.clamp(mph / 120, 0, 1.5)
end

-- what filling up costs, and how long it takes
function CarCare.fillPrice(id: string, c: Care): number
	local spec = Cars.ById[id]
	local need = (1 - c.f) * CarCare.tank(id)
	return math.ceil(need * (if spec and spec.Electric then F.PricePerKwh else F.PricePerLitre))
end

return CarCare
