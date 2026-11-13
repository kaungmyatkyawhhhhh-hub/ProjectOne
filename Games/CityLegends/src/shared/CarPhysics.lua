--[[
	CarPhysics (2026-11-08, Prompts/A million times better wheels (new models).md, Part 2: "a million times better driving
	and feel"). The pure maths of how a car drives, shared by the driving code (client/Driving.lua) and the Lune tests
	(tools/physics_test.luau), so what is tested is what is driven.

	* Each car's own numbers (CarPhysicsData: weight on the front, drive and AWD split, gears and gearbox, tyre widths and
	  type, real stopping distance, centre of gravity, downforce), with the car's game spec (Cars: top speed, 0-60, handling).
	* A two-axle ("bicycle") tyre model: each axle has its own grip from its own load, so weight moving forward under
	  braking tucks the nose in, weight moving back under power settles the front, the outside... (the body's roll is
	  only visual). Grip builds with slip, peaks, then falls off smoothly (no sudden ice). Drive and brake force share each
	  tyre's grip with cornering (friction circle): too much power in a rear-drive car steps the rear out, a locked front
	  axle can't steer.
	* Driver aids: traction control and stability control (Off / Sport / On), ABS (On / Off), countersteer help (the front
	  wheels follow a slide on keyboards and phones; off for "Pro").

	Units: studs and seconds (1 stud/s = 0.783 mph, 1 g = Config.DrivingFeel.G studs/s^2). Car frame: x forward, y right,
	yaw rate r positive turning right.
]]

local Config = require(script.Parent:WaitForChild("Config"))
local Cars = require(script.Parent:WaitForChild("Cars"))
local Data = require(script.Parent:WaitForChild("CarPhysicsData"))

local CarPhysics = {}

export type Params = {
	id: string,
	L: number, -- wheelbase (studs)
	a: number, -- centre of gravity to the front axle
	b: number, -- ...and to the rear axle
	h: number, -- centre of gravity height (studs)
	iz: number, -- yaw inertia per unit mass (studs^2)
	muF: number, -- each axle's peak grip (g), before load and surface
	muR: number,
	peakF: number, -- slip angle (radians) where each axle grips hardest
	peakR: number,
	slide: number, -- share of grip left well past the peak
	drive: string, -- "RWD" | "AWD" | "FWD"
	rear: number, -- share of the drive to the rear axle
	brakeG: number, -- full braking (g), from the real stopping distance
	bias: number, -- front share of the braking
	df: number, -- extra load at 250 km/h (g) from downforce
	dfFront: number,
	gears: number,
	box: string,
	shift: number, -- upshift time (s)
	ratios: { number }, -- share of top speed at the top of each gear (at 88% of the revs)
	tyreF: number, -- tyre widths (mm), for the marks
	tyreR: number,
	kg: number,
	reserve: number, -- the engine's pull in the low gears over what the tyres can use (traction control keeps it in)
}

-- the car's own numbers: its own entry, its base car's (a SPORT / TOP trim), the model it uses, or the nearest kind
local CLASS_FALLBACK = { Sedan = "bnw_530i", Coupe = "nisun_350z", SUV = "bnw_x6", Supercar = "ferrara_458", Hypercar = "lambrini_lp700" }
function CarPhysics.dataOf(spec: Cars.CarSpec): any
	local d = (Data :: any)[spec.Id] or (spec.BaseId and (Data :: any)[spec.BaseId]) or (spec.Model and (Data :: any)[spec.Model])
	if not d then
		-- the Veyrun Sport / Top trims of the Origine
		local stem = string.match(spec.Id, "^(.-)_[%a]+$")
		d = stem and (Data :: any)[stem]
	end
	return d or (Data :: any)[CLASS_FALLBACK[spec.Class] or "bnw_530i"]
end

---------------------------------------------------------------------
-- gears
---------------------------------------------------------------------
-- first gear's share of top speed by the number of gears (more gears: a shorter first)
local FIRST = { [1] = 1, [2] = 0.5, [3] = 0.42, [4] = 0.38, [5] = 0.33, [6] = 0.3, [7] = 0.28, [8] = 0.25, [9] = 0.22, [10] = 0.2 }
function CarPhysics.ratios(n: number): { number }
	n = math.clamp(math.floor(n), 1, 10)
	local out = {}
	if n == 1 then
		return { 1 }
	end
	local r1 = FIRST[n]
	-- (evenly spread in speed: each upshift lands at about two thirds of the revs or more, so the automatic never
	-- falls back into the gear it just left)
	for i = 1, n do
		out[i] = r1 + (1 - r1) * (i - 1) / (n - 1)
	end
	return out
end

-- the top of gear g as a share of top speed (the car tops out at 88% of the revs in top gear)
function CarPhysics.gearHi(p: Params, g: number): number
	return p.ratios[math.clamp(g, 1, p.gears)] / 0.88
end

-- pull in a gear compared with first
function CarPhysics.gearMul(p: Params, g: number): number
	return CarPhysics.gearHi(p, 1) / CarPhysics.gearHi(p, g)
end

-- engine torque over the revs (0..1 of the limiter): soft at the bottom, strongest in the upper middle, easing off
-- before the limiter
function CarPhysics.torqueCurve(rev: number): number
	if rev >= 1 then
		return 0
	end
	return 0.72 + 0.33 * math.sin(math.clamp(rev / 0.72, 0, 1) * math.pi / 2) - math.max(0, rev - 0.82) * 0.9
end

-- an electric car's single gear: full pull to 30% of top speed, then its power holds (the pull fades as 1 / speed, as a
-- real motor's does). (2026-11-08: it faded as 1 / speed squared, so some never reached their top speed)
function CarPhysics.evPull(frac: number): number
	return math.min(1, 0.3 / math.max(frac, 1e-3))
end
-- (2026-11-08) electric cars now reach 60 mph in their real time (they were at 70% of it: the prompt's +-5%)
CarPhysics.EV_LAUNCH = 1

---------------------------------------------------------------------
-- the tyres
---------------------------------------------------------------------
-- grip by tyre kind (g, a real road tyre), before the game's own lift (GameGrip)
local TYRE_MU = { allseason = 0.85, touring = 0.9, sport = 1.0, cup = 1.08, offroad = 0.8 }

-- normalised side force for slip x (1 = the peak): rises, flattens at the peak, then falls off smoothly towards `slide`
function CarPhysics.curve(x: number, slide: number): number
	if x <= 1 then
		return x * (2 - x)
	end
	local k = x - 1
	return slide + (1 - slide) * math.exp(-k * k * 1.3)
end

---------------------------------------------------------------------
-- the car's numbers
---------------------------------------------------------------------
-- wb: the wheelbase in studs (CarBuilder.getDims); kg: the weight with its parts; handling: the tuned spec's
-- (performance tyres raise it)
function CarPhysics.params(spec: Cars.CarSpec, wb: number, kg: number, handling: number?): Params
	local DF = Config.DrivingFeel
	local P = DF.Axle
	local d = CarPhysics.dataOf(spec)
	local front = math.clamp(d.front or 0.5, 0.3, 0.7)
	-- a SPORT / TOP trim comes on the next grade of tyre (all-season -> touring -> sport -> cup)
	local tyreKind = d.tyre
	if spec.Trim == "SPORT" or spec.Trim == "TOP" then
		tyreKind = ({ allseason = "touring", offroad = "allseason", touring = "sport", sport = "cup" } :: any)[tyreKind] or tyreKind
	end
	local L = wb
	local a = L * (1 - front)
	local b = L * front
	local h = math.clamp(d.cg or 0.5, 0.3, 0.9) * 3 -- metres to studs (CarBuilder.STUDS_PER_METRE)
	-- yaw inertia: mid-engined cars turn in sharper (their weight is near the middle), big cars are lazier
	local di = if front <= 0.46 then 0.85 elseif spec.Class == "SUV" then 1.12 else 1.0
	local base = Cars.get(spec.Id) or spec
	local hBase = base.Handling or 0.7
	local hNow = handling or spec.Handling or hBase
	-- grip: the tyre kind and width, the car's own handling (the game's grading), parts on top
	local mu = (TYRE_MU[tyreKind] or 0.95) * P.GameGrip * (P.HandlingBase + P.HandlingK * hBase) * (1 + (hNow - hBase) * P.PartsGrip)
	local wF, wR = d.tyreF or 245, d.tyreR or 245
	local muF = mu * (wF / 245) ^ P.WidthPow
	local muR = mu * (wR / 245) ^ P.WidthPow
	-- the front tyres peak at a slightly bigger slip than the rears (a little understeer: stable at speed)
	local peak = P.SlipPeak
	-- brakes: the deceleration that stops it from 100 km/h in its real distance (the drag and rolling help a little)
	local stop = d.stop or 36
	local v = 27.78
	local brakeG = (v * v / (2 * stop)) / 9.81 * P.BrakeK
	local drive = d.drive or "RWD"
	local rear = if drive == "AWD" then math.clamp(d.rear or 0.6, 0.2, 0.9) elseif drive == "FWD" then 0 else 1
	if drive == "AWD" and spec.RearBias then
		rear = math.max(rear, 0.7)
	end
	local gears = if spec.Electric then 1 else math.clamp(d.gears or 7, 4, 10)
	return {
		id = spec.Id,
		L = L,
		a = a,
		b = b,
		h = h,
		iz = di * a * b,
		muF = muF,
		muR = muR,
		peakF = peak * P.FrontPeakK,
		peakR = peak,
		slide = P.SlideGrip,
		drive = drive,
		rear = rear,
		brakeG = brakeG,
		bias = if front >= 0.55 then 0.7 elseif front <= 0.45 then 0.6 else 0.65,
		df = (d.downforce or 0) / math.max(kg, 600) * P.DownforceK + (P.ClassDownforce[spec.Class] or 0),
		dfFront = 0.42,
		gears = gears,
		box = if spec.Electric then "ev" else (d.box or "auto"),
		shift = if spec.Electric then 0 else math.clamp(d.shift or 0.25, 0.05, 0.7),
		ratios = CarPhysics.ratios(gears),
		tyreF = wF,
		tyreR = wR,
		kg = kg,
		-- a powerful car's engine can overpower its tyres in the low gears (hp per tonne over 250: more): with
		-- traction control off or in Sport the rear can spin up and step out, as a real one does
		reserve = if drive == "RWD"
			then math.clamp((d.hp or 300) / math.max(kg, 600) * 1000 / P.RwdReservePer, 1, P.RwdReserveMax)
			else math.clamp((d.hp or 300) / math.max(kg, 600) * 1000 / 250, 1, P.ReserveMax),
	}
end

-- the extra pull the engine has over the calibrated one (0-60 is with traction control on, which holds it to the
-- tyres): only without full traction control, and only at low speed (the low gears)
function CarPhysics.reserve(p: Params, speed: number, top: number, tc: number): number
	-- (a rear-drive car's overpowering is in CarPhysics.step: it is measured against its tyres)
	if p.reserve <= 1 or tc >= 2 or p.drive == "RWD" then
		return 1
	end
	return 1 + (p.reserve - 1) * math.clamp(1 - math.abs(speed) / (0.4 * top), 0, 1)
end

---------------------------------------------------------------------
-- loads and grip
---------------------------------------------------------------------
local V250 = 250 / 3.6 / 0.35 -- 250 km/h in studs/s

-- each axle's load (in g of the whole car) at a longitudinal acceleration ax (studs/s^2) and speed
function CarPhysics.loads(p: Params, ax: number, speed: number): (number, number)
	local G = Config.DrivingFeel.G
	local shift = ax * p.h / p.L / G -- load moving back under power, forward under braking
	local aero = p.df * (speed / V250) ^ 2
	local zf = p.b / p.L - shift + aero * p.dfFront
	local zr = p.a / p.L + shift + aero * (1 - p.dfFront)
	return math.max(zf, 0.05), math.max(zr, 0.05)
end

-- an axle's peak grip force (studs/s^2 of the whole car) at load z (g); grip per load falls a little as the load grows
local function cap(mu: number, z: number, z0: number, ls: number): number
	local k = math.clamp(1 - ls * (z / z0 - 1), 0.75, 1.15)
	return mu * k * z * Config.DrivingFeel.G
end

---------------------------------------------------------------------
-- one step of the car's motion in its own plane
---------------------------------------------------------------------
export type StepIn = {
	vx: number, -- forward speed (studs/s)
	vy: number, -- sideways speed (right +)
	r: number, -- yaw rate (right +)
	delta: number, -- front wheels' angle (radians, right +)
	drive: number, -- what the engine asks at the wheels (studs/s^2, + forward; engine braking negative)
	brake: number, -- what the brakes ask (studs/s^2, >= 0)
	handbrake: boolean,
	ax: number, -- last step's longitudinal acceleration (load transfer)
	gripF: number, -- surface and wet grip under each axle (1 = dry asphalt)
	gripR: number,
	tc: number, -- traction control: 0 off, 1 sport, 2 on
	esc: number, -- stability control: 0 off, 1 sport, 2 on
	abs: boolean,
	help: number, -- countersteer help 0..1
	pedal: number?, -- the brake pedal 0..1 (with ABS off a hard one locks the fronts)
	throttle: number?, -- the throttle 0..1, and the car's top speed (studs/s): a rear-drive car's power slides
	top: number?,
	drift: boolean?, -- drift tyres fitted: only on these does traction control off let the driven tyres spin freely
}
export type StepOut = {
	vy: number,
	r: number,
	ax: number, -- the drive and brakes' real acceleration (traction-limited; no drag)
	delta: number, -- the wheels' angle after the countersteer help
	slipF: number, -- each axle's slip over its peak (1 = at the limit)
	slipR: number,
	spin: number, -- 0..1 driven wheels spinning (no traction control)
	lock: number, -- 0..1 wheels locked (no ABS, or the handbrake)
	tcCut: number, -- 0..1 how hard traction / stability control is working (its lamp)
	beta: number, -- the body's slip angle (radians)
}

local function sign(x: number): number
	return if x < 0 then -1 else 1
end

function CarPhysics.step(p: Params, s: StepIn, dt: number): StepOut
	local DF = Config.DrivingFeel
	local P = DF.Axle
	local vx, vy, r = s.vx, s.vy, s.r
	local speed = math.abs(vx)
	local delta = s.delta
	local beta = math.atan2(vy, math.max(speed, 1))
	-- loads (last step's acceleration), each axle's grip
	local zf, zr = CarPhysics.loads(p, s.ax, speed)
	local z0f, z0r = p.b / p.L, p.a / p.L
	local capF = cap(p.muF * s.gripF, zf, z0f, P.LoadSens)
	local capR = cap(p.muR * s.gripR, zr, z0r, P.LoadSens)
	local longK = P.LongGrip
	-- the drive at each axle, traction-limited
	local fDrive = s.drive
	local spin, lock, tcCut = 0, 0, 0
	local dF, dR = fDrive * (1 - p.rear), fDrive * p.rear
	local rwd = p.drive == "RWD"
	-- (owner, 2026-11-13: "fix some cars losing too much traction even when its not tuned") traction control On
	-- holds the engine back in a corner: a driven tyre that is already cornering keeps the side grip it is using, so
	-- flooring it mid-corner no longer takes the grip away from under the car (straight ahead nothing changes: the
	-- 0-60 times stay). keepF / keepR: the share of its drive grip each axle may still use (1 = all, going straight)
	local keepF, keepR = 1, 1
	if s.tc == 2 and (P.TcCornerKeep or 0) > 0 and speed > P.KinFrom then
		local ux0 = math.max(speed, 0.5)
		local xF0 = math.abs(math.atan2(vy + p.a * r, ux0) - delta * sign(vx)) / p.peakF
		local xR0 = math.abs(math.atan2(vy - p.b * r, ux0)) / p.peakR
		local function keep(x: number): number
			local uy = math.min(x, 1) * P.TcCornerKeep
			return math.max(math.sqrt(math.max(1 - uy * uy, 0)), P.TcCornerFloor or 0.3)
		end
		keepF, keepR = keep(xF0), keep(xR0)
	end
	local function limitDrive(f: number, c: number, rear: boolean): (number, number)
		if f <= 0 then
			return f, 0
		end
		local lim = c * longK
		local keep = if rear then keepR else keepF
		-- a powerful rear-drive car floored in a low gear asks more of its rear tyres than they have (its engine's
		-- real pull, hp per tonne: Params.reserve); traction control On never lets it
		if rwd and rear and s.tc < 2 and (s.throttle or 0) > 0.4 and p.reserve > 1 then
			local low = math.clamp(1 - speed / (0.45 * math.max(s.top or 200, 1)), 0, 1)
			f = math.max(f, lim * (1 + (p.reserve - 1) * low) * (s.throttle or 0))
		end
		-- (2026-11-08, Prompts/RWD cars slide more (and more with TCS off).md) a rear-drive car's rear lets go more on
		-- power: with traction control on a few degrees, then it's caught; in Sport a clear slide; off, it spins up
		if rwd and rear then
			if s.tc == 2 then
				local top = math.min(lim * P.RwdSlideOn, lim * keep)
				if f > top then
					tcCut = math.max(tcCut, 1 - top / f)
				end
				local fx = math.min(f, top)
				-- (the few degrees of wheelspin stay for a straight-line launch only: none once the tyre is cornering)
				local straight = math.clamp((keep - 0.95) / 0.05, 0, 1)
				return math.min(fx, lim), math.clamp((fx / lim - 1) / math.max(P.RwdSlideOn - 1, 0.01), 0, 1) * P.RwdSpinOn * straight
			elseif s.tc == 1 then
				local top = lim * P.RwdSlideSport
				if f > top then
					tcCut = math.max(tcCut, 1 - top / f)
				end
				local fx = math.min(f, top)
				if fx > lim then
					return lim * P.SpinGrip, math.clamp((fx / lim - 1) / math.max(P.RwdSlideSport - 1, 0.01), 0.4, 1) * P.RwdSpinSport
				end
				return fx, 0
			end
			-- (owner, 2026-11-10) off on ordinary tyres: the rear steps out, but it isn't let go as freely as on drift tyres
			if not s.drift then
				local top = lim * P.RwdSlideOffGrip
				local fx = math.min(f, top)
				if fx > lim then
					return lim * P.SpinGrip, math.clamp((fx / lim - 1) / math.max(P.RwdSlideOffGrip - 1, 0.01), 0.3, 1) * P.RwdSpinOffGrip
				end
				return fx, 0
			end
			if f > lim then
				return lim * P.SpinGrip, math.clamp((f / lim - 1) * 2, 0.35, 1) * P.RwdSpinOff
			end
			return f, 0
		end
		if s.tc == 2 then
			local top = lim * math.min(0.97, keep)
			if f > top then
				tcCut = math.max(tcCut, 1 - top / f)
				return top, 0
			end
			return f, 0
		elseif s.tc == 1 then
			if f > lim * 1.06 then
				tcCut = math.max(tcCut, 1 - lim * 1.06 / f)
				return lim * 1.0, 0.25
			end
			return math.min(f, lim), if f > lim then 0.15 else 0
		end
		-- (2026-11-10) off on ordinary tyres (front and all-wheel drive): a chirp of wheelspin, as Sport
		if not s.drift then
			if f > lim * 1.06 then
				return lim, 0.25
			end
			return math.min(f, lim), if f > lim then 0.15 else 0
		end
		if f > lim then
			-- spinning: the tyre slides, it pushes less and has little left for cornering
			return lim * P.SpinGrip, math.clamp((f / lim - 1) * 2, 0.3, 1)
		end
		return f, 0
	end
	local spF, spR
	dF, spF = limitDrive(dF, capF, false)
	dR, spR = limitDrive(dR, capR, true)
	spin = math.max(spF, spR)
	-- the brakes at each axle; ABS keeps each axle just under locking
	local bF, bR = s.brake * p.bias, s.brake * (1 - p.bias)
	local lockF, lockR = 0, 0
	local function limitBrake(f: number, c: number, front: boolean): (number, number)
		local lim = c * longK
		if s.abs then
			return math.min(f, lim * 0.97), 0
		end
		-- ABS off: a hard pedal locks the front wheels (the brakes are biased to the front, as on a real car): the
		-- tyres slide, the car stops later and can't steer; a light pedal brakes as normal
		local normal = f / P.AbsOffSqueeze
		if front and (s.pedal or 0) > 0.85 and speed > 8 then
			return math.min(lim * P.LockGrip, normal * P.LockStop), 1
		end
		return math.min(normal, lim * 0.97), 0
	end
	bF, lockF = limitBrake(bF, capF, true)
	bR, lockR = limitBrake(bR, capR, false)
	if s.handbrake and speed > 1 then
		bR = math.max(bR, capR * longK * P.LockGrip)
		lockR = 1
	end
	lock = math.max(lockF, lockR)
	-- each axle's longitudinal force (+ forward): drive, then brakes against the motion
	local sv = sign(vx)
	local fxF = dF - bF * sv
	local fxR = dR - bR * sv
	-- what's left of each tyre's grip for cornering (a spinning or locked axle has little)
	local function sideCap(c: number, fx: number, slid: number): number
		-- (a friction ellipse: the tyre grips LongGrip more straight ahead than sideways)
		local u = fx / (c * longK)
		local left = c * math.sqrt(math.max(1 - u * u, 0.08 ^ 2))
		return left * (1 - slid * (1 - P.SlideSide))
	end
	local cF = sideCap(capF, fxF, math.max(lockF, spF))
	local cR = sideCap(capR, fxR, math.max(lockR, spR))
	-- a rear-drive car's rear tyres spinning up (traction control Sport / off) hold almost nothing sideways: it swings
	-- round (power slides, donuts)
	if rwd and s.tc < 2 and spR > 0 then
		cR *= 1 - spR * P.RwdSpinSide
	end
	-- the yaw and side speed, in small steps (stiff at low speed)
	local n = math.clamp(math.ceil(dt * 240), 1, 16)
	local h = dt / n
	local slipF, slipR = 0, 0
	local cosd = math.cos(delta)
	local blend = math.clamp((speed - P.KinFrom) / (P.KinTo - P.KinFrom), 0, 1)
	if rwd and spR > 0.25 then
		blend = math.max(blend, math.clamp(spR * 1.5, 0, 1)) -- (donuts: the spinning rear swings round)
	end
	-- the countersteer help stays out of a slow donut, and is a little weaker with traction control off
	local slowSpin = rwd and spR > 0.25 and speed < P.DonutBelow
	local help = if slowSpin then 0 elseif rwd and s.tc == 0 and s.drift then s.help * P.HelpTcOff else s.help
	-- countersteer help: the front wheels follow the car's slide (the way it's really going)
	if help > 0 and vx > 3 then
		local want = math.clamp(beta * P.HelpK, -P.HelpMax, P.HelpMax)
		-- only while the slide is past the tyres' peak at the rear, and it never fights the player's own countersteer
		local over = math.clamp((math.abs(beta) - p.peakR * 0.6) / (p.peakR * 1.4), 0, 1)
		delta += (want - math.clamp(delta, -math.abs(want), math.abs(want))) * over * help
		cosd = math.cos(delta)
	end
	-- stability control: a rear-drive car's goes with its traction control (Sport: Sport at most, off: off), and Sport
	-- only steps in at speed (so donuts work)
	-- (2026-11-10: off on ordinary tyres keeps Sport stability control; off on drift tyres frees the car)
	local esc = if rwd then math.min(s.esc, if s.tc == 0 and not s.drift then 1 else s.tc) else s.esc
	local escFrom = if esc == 1 and rwd then P.EscSportFrom else 8
	-- (owner, 2026-11-13: "fix cars understeering too much") at full lock the front wheels were turned far past the
	-- angle where their tyres grip best (2.4 times it at 60 mph), so the fronts scrubbed and the car ran wide on 78%
	-- of its grip. With the steering help on (everyone but "Pro") the front wheels turn no further past the car's path
	-- than SteerSlipMax x that angle: the fronts stay at their best grip and the car turns as tight as its tyres can.
	-- It only ever turns the wheels less than asked, never more
	local slipMax = if (s.help or 0) > 0 and (P.SteerSlipMax or 0) > 0 then p.peakF * P.SteerSlipMax else 0
	local dAsk = delta
	for _ = 1, n do
		local ux = math.max(speed, 0.5)
		if slipMax > 0 and blend > 0 then
			local base = math.atan2(vy + p.a * r, ux)
			local want = dAsk * sv
			local held = math.clamp(want, base - slipMax, base + slipMax)
			if math.abs(held) < math.abs(want) then
				delta = (want + (held - want) * blend) * sv
			else
				delta = dAsk
			end
			cosd = math.cos(delta)
		end
		local aF = math.atan2(vy + p.a * r, ux) - delta * sv
		local aR = math.atan2(vy - p.b * r, ux)
		local xF, xR = math.abs(aF) / p.peakF, math.abs(aR) / p.peakR
		slipF, slipR = xF, xR
		local fyF = -sign(aF) * cF * CarPhysics.curve(xF, p.slide)
		local fyR = -sign(aR) * cR * CarPhysics.curve(xR, p.slide)
		local ay = fyF * cosd + fyR
		local yawAcc = (p.a * fyF * cosd - p.b * fyR) / p.iz
		-- countersteer help, the second half: a car spinning into its slide (the rear past its peak) is slowed in its
		-- turn a little, so a keyboard or a thumb can catch it ("Pro" off)
		if help > 0 and vx > 3 then
			local b = math.atan2(vy, ux)
			if r * b < 0 and math.abs(b) > p.peakR * 0.8 then
				yawAcc -= r * P.HelpYaw * help * math.clamp((math.abs(b) - p.peakR * 0.8) / p.peakR, 0, 1)
			end
		end
		-- stability control: the yaw the driver asks for (within the tyres' grip); it brakes a wheel to hold it, and
		-- holds the body's slip angle
		if esc > 0 and speed > escFrom then
			local ref = vx * math.tan(dAsk) / (p.L * (1 + P.EscUnder * vx * vx))
			-- (what the tyres can turn the car with: both axles together)
			local lim = (capF + capR) * 1.05 / math.max(speed, 1)
			ref = math.clamp(ref, -lim, lim)
			local tol = if esc == 2 then P.EscTol else P.EscTolSport
			local err = r - ref
			if math.abs(err) > tol then
				local k = if esc == 2 then P.EscGain else P.EscGain * 0.5
				yawAcc -= (err - sign(err) * tol) * k
				tcCut = math.max(tcCut, math.clamp(math.abs(err) / 0.6, 0, 1))
			end
			local bmax = if esc == 2 then P.EscBeta else P.EscBetaSport
			local bnow = math.atan2(vy, ux)
			if math.abs(bnow) > bmax then
				vy -= sign(vy) * (math.abs(bnow) - bmax) * ux * math.min(1, h * 6)
				tcCut = 1
			end
		end
		vy += (ay - vx * r) * h
		r += yawAcc * h
		if blend < 1 then
			-- slow: the car simply goes where its wheels point (no slip), blended in
			local rk = vx * math.tan(delta) / p.L
			local vyk = rk * p.b
			local k = math.min(1, h * 20) * (1 - blend)
			r += (rk - r) * k
			vy += (vyk - vy) * k
		end
	end
	if vx ~= vx or vy ~= vy or r ~= r then -- (never: a NaN would freeze the car)
		vy, r = 0, 0
	end
	return {
		vy = vy,
		r = r,
		ax = fxF + fxR,
		delta = delta,
		slipF = slipF,
		slipR = slipR,
		spin = spin,
		lock = lock,
		tcCut = tcCut,
		beta = beta,
	}
end

---------------------------------------------------------------------
-- calibration: the engine's scale for the car's real 0-60, the drag for its top speed, the brakes for its stopping
-- distance. The same sums the game drives (gears, shift times, traction with traction control on).
---------------------------------------------------------------------
function CarPhysics.dragFor(p: Params, accel: number, k: number, top: number, electric: boolean): number
	local topPull = accel * k * (if electric then CarPhysics.evPull(1) else CarPhysics.torqueCurve(0.88) * CarPhysics.gearMul(p, p.gears))
	return math.max(0.75 * topPull - 2, 0.5) / (top * top)
end

-- simulate a standing start: seconds to `target` studs/s (40 if never)
function CarPhysics.timeTo(p: Params, spec: Cars.CarSpec, k: number, target: number, upshift: number): number
	local top = Config.mphToSps(spec.TopSpeed)
	local accel = Config.mphToSps(60) / spec.ZeroToSixty
	local electric = spec.Electric == true
	local c = CarPhysics.dragFor(p, accel, k, top, electric)
	local v, g, cut, t, dt, ax = 0, 1, 0, 0, 1 / 60, 0
	local longK = Config.DrivingFeel.Axle.LongGrip
	while t < 40 do
		local frac = v / top
		local rev = frac / CarPhysics.gearHi(p, g)
		local a = 0
		if electric then
			a = accel * k * CarPhysics.evPull(frac)
		elseif cut > 0 then
			cut -= dt
		else
			a = accel * k * CarPhysics.torqueCurve(math.max(rev, 0.3)) * CarPhysics.gearMul(p, g)
			if rev >= upshift and g < p.gears then
				g += 1
				cut = p.shift
			end
		end
		-- traction (traction control on): what the driven tyres can put down, axle by axle as CarPhysics.step does
		if a > 0 then
			local zf, zr = CarPhysics.loads(p, ax, v)
			local LS = Config.DrivingFeel.Axle.LoadSens
			local limF = cap(p.muF, zf, p.b / p.L, LS) * longK * 0.97
			local limR = cap(p.muR, zr, p.a / p.L, LS) * longK * 0.97
			a = math.min(a * (1 - p.rear), limF) + math.min(a * p.rear, limR)
		end
		ax = a
		a -= 2 + c * v * v
		v = math.max(0, v + a * dt)
		t += dt
		if v >= target then
			return t
		end
	end
	return 40
end

-- returns the engine scale and the drag (cached per car and numbers)
local powerCache: { [string]: { number } } = {}
function CarPhysics.powerFor(p: Params, spec: Cars.CarSpec, upshift: number): (number, number)
	local top = Config.mphToSps(spec.TopSpeed)
	local accel = Config.mphToSps(60) / spec.ZeroToSixty
	local key = string.format("%s|%s|%s|%.3f|%.3f|%.2f", spec.Id, tostring(spec.TopSpeed), tostring(spec.ZeroToSixty), p.muF, p.muR, p.kg)
	local hit = powerCache[key]
	if hit then
		return hit[1], hit[2]
	end
	local electric = spec.Electric == true
	local want = spec.ZeroToSixty * (if electric then CarPhysics.EV_LAUNCH else 1)
	-- (at most 4x: a car whose tyres can't give its 0-60 keeps a sane engine, so it still reaches its top speed)
	local lo, hi = 0.3, 4
	for _ = 1, 20 do
		local mid = (lo + hi) / 2
		if CarPhysics.timeTo(p, spec, mid, Config.mphToSps(60), upshift) > want then
			lo = mid
		else
			hi = mid
		end
	end
	local out = { hi, CarPhysics.dragFor(p, accel, hi, top, electric) }
	powerCache[key] = out
	return out[1], out[2]
end

-- the brakes' full deceleration (studs/s^2) that stops the car from 100 km/h in its real distance, with the drag,
-- rolling and the ABS pulses the game has
function CarPhysics.brakeFor(p: Params, drag: number): number
	local d = CarPhysics.dataOf(Cars.get(p.id) or ({ Id = p.id, Class = "Sedan" } :: any))
	local want = (d.stop or 36) / 0.35 -- studs at the game's speed scale
	local v0 = 100 / 3.6 / 0.35
	local pulse = Config.DrivingFeel.AbsPulse
	local function dist(B: number): number
		-- (the pedal comes in over about a tenth of a second, as Driving's brakeIn does)
		local v, x, dt, bin = v0, 0, 1 / 120, 0
		while v > 0 do
			bin += (1 - bin) * math.min(1, dt * 7)
			local a = B * bin * (if bin > 0.8 then 1 - pulse * 0.5 else 1) + 2 + drag * v * v
			v -= a * dt
			x += math.max(v, 0) * dt
		end
		return x
	end
	local lo, hi = 5, 80
	for _ = 1, 24 do
		local mid = (lo + hi) / 2
		if dist(mid) > want then
			lo = mid
		else
			hi = mid
		end
	end
	return hi
end

return CarPhysics
