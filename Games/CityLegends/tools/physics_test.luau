-- Lune test for the driving physics (2026-11-08, Prompts/A million times better wheels (new models).md, Part 2):
-- shared/CarPhysics.lua with every car's numbers, driven by the same per-frame sums as client/Driving.lua.
--   lune run tools/physics_test.luau .            (all cars, the checks)
--   lune run tools/physics_test.luau . table      (also the 0-60 / top speed / braking table for every car)
-- Checks: 0-60 and 100-0 km/h within 5% of the car (its game spec for 0-60, its real stopping distance), top speed
-- reached, no spin and no runaway with stability control on, a slide caught with the countersteer help, no NaN.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local showTable = process.args[2] == "table"
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local mods: { [string]: any } = {}
local function node(name: string): any
	return setmetatable({ name = name }, {
		__index = function(t, k)
			if k == "WaitForChild" or k == "FindFirstChild" then
				return function(_, n)
					return node(n)
				end
			end
			return node(k)
		end,
	})
end
local senv = table.clone(baseEnv)
senv.script = { Parent = node("Shared") }
senv.require = function(x)
	local m = mods[x.name]
	if not m then
		error("require " .. tostring(x.name))
	end
	return m
end
senv.game = {
	GetService = function()
		return { FindFirstChild = function()
			return nil
		end }
	end,
}
mods.Config = load("src/shared/Config.lua", baseEnv)
mods.Cars = load("src/shared/Cars.lua", baseEnv)
mods.PartData = load("src/shared/PartData.lua", senv)
mods.CarPhysicsData = load("src/shared/CarPhysicsData.lua", senv)
mods.CarStats = load("src/shared/CarStats.lua", senv)
mods.CarBuilder = load("src/shared/CarBuilder.lua", senv)
mods.CarPhysics = load("src/shared/CarPhysics.lua", senv)
local Config, Cars, CarStats, CarBuilder, CarPhysics = mods.Config, mods.Cars, mods.CarStats, mods.CarBuilder, mods.CarPhysics
local DF = Config.DrivingFeel
local G = DF.G

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	end
end

local CLASS_UP = { Sedan = 0.9, SUV = 0.86, Coupe = 0.93, Supercar = 0.95, Hypercar = 0.96 }

-- one car on a flat road: the same per-frame order as Driving.step
local function newCar(spec)
	local dims = CarBuilder.getDims(spec.Class, spec.Id)
	local _, kg = CarStats.powerOf(spec.Id, nil)
	local p = CarPhysics.params(spec, dims.wb, kg, spec.Handling)
	local up = CLASS_UP[spec.Class] or 0.9
	local k, drag = CarPhysics.powerFor(p, spec, up)
	local brake = CarPhysics.brakeFor(p, drag)
	return {
		spec = spec,
		p = p,
		k = k,
		drag = drag,
		brake = brake,
		up = up,
		top = Config.mphToSps(spec.TopSpeed),
		accel = Config.mphToSps(60) / spec.ZeroToSixty,
		vx = 0,
		vy = 0,
		r = 0,
		ax = 0,
		g = 1,
		cut = 0,
		t = 0,
		x = 0,
		yaw = 0,
		maxBeta = 0,
		maxLat = 0,
		absT = 0,
	}
end

-- one frame. inp: throttle 0..1, brake 0..1, steer -1..1 (the wheel angle comes from Driving's speed-sensitive lock),
-- tc / esc / abs / help, handbrake
local function frame(c, inp, dt)
	local p = c.p
	local spec = c.spec
	local vx = c.vx
	local frac = math.max(vx, 0) / c.top
	-- the automatic gearbox (Driving's rule, flat out)
	local drive = 0
	if spec.Electric then
		drive = if frac < 1 then c.accel * c.k * CarPhysics.evPull(frac) * inp.throttle else 0
	elseif c.cut > 0 then
		c.cut -= dt
	else
		local rev = frac / CarPhysics.gearHi(p, c.g)
		if rev >= c.up and c.g < p.gears and inp.throttle > 0.5 then
			c.g += 1
			c.cut = p.shift
		elseif c.g > 1 and rev < (if inp.throttle > 0.8 then 0.55 else 0.28) and frac / CarPhysics.gearHi(p, c.g - 1) < 0.82 then
			-- (Driving's kick-down)
			c.g -= 1
			c.cut = 0.12
			c.downs = (c.downs or 0) + 1
		end
		if inp.throttle > 0 and frac < 1 then
			drive = c.accel * c.k * CarPhysics.torqueCurve(math.max(rev, 0.3)) * CarPhysics.gearMul(p, c.g) * inp.throttle
		elseif inp.throttle == 0 and vx > 2 and inp.brake < 0.3 then
			drive = -(3 + 6 * math.min(rev, 1))
		end
	end
	c.brakeIn = (c.brakeIn or 0) + (inp.brake - (c.brakeIn or 0)) * math.min(1, dt * 7)
	local brake = c.brake * c.brakeIn * (c.brakeMul or 1)
	if c.brakeIn > 0.8 and inp.abs and Config.spsToMph(vx) > 12 then
		c.absT += dt
		brake *= 1 - DF.AbsPulse * (0.5 + 0.5 * math.sin(c.absT * math.pi * 2 * DF.AbsHz))
	end
	local speedAbs = math.abs(vx)
	local maxAngle = math.rad(36) / (1 + (speedAbs / 70) ^ 1.3)
	local out = CarPhysics.step(p, {
		vx = vx,
		vy = c.vy,
		r = c.r,
		delta = inp.steer * maxAngle,
		drive = if drive > 0 then drive * CarPhysics.reserve(p, vx, c.top, inp.tc or 2) else drive,
		brake = brake,
		handbrake = inp.handbrake == true,
		ax = c.ax,
		gripF = inp.grip or 1,
		gripR = inp.grip or 1,
		tc = inp.tc or 2,
		esc = inp.esc or 2,
		abs = inp.abs ~= false,
		help = inp.help or 1,
		pedal = c.brakeIn,
	}, dt)
	c.ax = out.ax
	local dragA = (2 + c.drag * vx * vx) * (if vx > 0.5 then 1 elseif vx < -0.5 then -1 else 0)
	vx += (out.ax - dragA) * dt
	if vx < 0 and inp.brake > 0 then
		vx = 0
	end
	c.vy, c.r = out.vy, out.r
	vx += c.vy * c.r * dt
	c.vx = vx
	c.yaw += c.r * dt
	c.t += dt
	c.x += vx * dt
	c.maxBeta = math.max(c.maxBeta, math.abs(out.beta))
	c.maxLat = math.max(c.maxLat, math.abs(vx * c.r) / G)
	if vx ~= vx or c.vy ~= c.vy or c.r ~= c.r then
		error("NaN " .. spec.Id)
	end
	return out
end

local DT = 1 / 60
local rows = {}
local list = {}
for _, spec in Cars.All do
	table.insert(list, spec)
end
table.sort(list, function(a, b)
	return a.Id < b.Id
end)

for _, spec in list do
	local id = spec.Id
	local d = CarPhysics.dataOf(spec)
	-- 0-60 and top speed
	local c = newCar(spec)
	local t60, t100 = nil, nil
	while c.t < 90 do
		frame(c, { throttle = 1, brake = 0, steer = 0 }, DT)
		if not t60 and c.vx >= Config.mphToSps(60) then
			t60 = c.t
		end
		if not t100 and c.vx >= 100 / 3.6 / 0.35 then
			t100 = c.t
		end
	end
	local topMph = Config.spsToMph(c.vx)
	check((c.downs or 0) == 0, string.format("%s: flat out the automatic never shifts back down (%d)", id, c.downs or 0))
	local want60 = spec.ZeroToSixty * (if spec.Electric then CarPhysics.EV_LAUNCH else 1)
	check(t60 and math.abs(t60 / want60 - 1) <= 0.05, string.format("%s 0-60 %.2f s (spec %.2f)", id, t60 or -1, want60))
	check(math.abs(topMph / spec.TopSpeed - 1) <= 0.05, string.format("%s top %.0f mph (spec %d)", id, topMph, spec.TopSpeed))
	-- 100-0 km/h, ABS on
	local b = newCar(spec)
	b.vx = 100 / 3.6 / 0.35
	b.x = 0
	while b.vx > 0.05 and b.t < 20 do
		frame(b, { throttle = 0, brake = 1, steer = 0, abs = true }, DT)
	end
	local stopM = b.x * 0.35
	check(math.abs(stopM / d.stop - 1) <= 0.05, string.format("%s 100-0 %.1f m (real %.1f)", id, stopM, d.stop))
	-- ABS off: the wheels lock and it stops later
	local bo = newCar(spec)
	bo.vx = 100 / 3.6 / 0.35
	bo.brakeMul = mods.Config.DrivingFeel.Axle.AbsOffSqueeze
	while bo.vx > 0.05 and bo.t < 20 do
		frame(bo, { throttle = 0, brake = 1, steer = 0, abs = false }, DT)
	end
	check(bo.x * 0.35 > stopM * 1.05, string.format("%s: ABS off stops later (%.1f m vs %.1f)", id, bo.x * 0.35, stopM))
	-- 60-0 mph
	local b6 = newCar(spec)
	b6.vx = Config.mphToSps(60)
	while b6.vx > 0.05 and b6.t < 20 do
		frame(b6, { throttle = 0, brake = 1, steer = 0, abs = true }, DT)
	end
	local stop60ft = b6.x * 0.35 * 3.281
	-- the most sideways grip (a slow steer ramp at 60 mph, held there with the throttle)
	local s = newCar(spec)
	s.vx = Config.mphToSps(60)
	local latMax = 0
	for i = 1, 360 do
		local steer = math.min(1, i / 300)
		local thr = math.clamp((Config.mphToSps(60) - s.vx) * 0.1 + 0.2, 0, 1)
		frame(s, { throttle = thr, brake = 0, steer = steer, esc = 0, help = 0 }, DT)
		latMax = math.max(latMax, math.abs(s.vx * s.r) / G)
	end
	-- stability control doesn't take away cornering grip: a steady corner at 50 mph, 60% lock, on vs off
	local function steady(esc)
		local q = newCar(spec)
		q.vx = Config.mphToSps(50)
		local gmax = 0
		for i = 1, 240 do
			local thr = math.clamp((Config.mphToSps(50) - q.vx) * 0.1 + 0.15, 0, 1)
			frame(q, { throttle = thr, brake = 0, steer = 0.6, esc = esc, help = 1 }, DT)
			if i > 120 then
				gmax = math.max(gmax, math.abs(q.vx * q.r) / G)
			end
		end
		return gmax
	end
	local gOn, gOff = steady(2), steady(0)
	check(gOn >= gOff * 0.85, string.format("%s: stability control keeps the corner grip (%.2f g on, %.2f off)", id, gOn, gOff))
	-- a step of steering at 100 mph with stability control on: no spin, settles
	local st = newCar(spec)
	st.vx = math.min(Config.mphToSps(100), st.top * 0.8)
	local spun = false
	for i = 1, 240 do
		local thr = math.clamp((math.min(Config.mphToSps(100), st.top * 0.8) - st.vx) * 0.2, 0, 1)
		frame(st, { throttle = thr, brake = 0, steer = if i < 150 then 1 else 0, esc = 2, help = 1 }, DT)
		if math.abs(math.atan2(st.vy, math.max(st.vx, 1))) > math.rad(25) then
			spun = true
		end
	end
	check(not spun, id .. " step steer at 100 mph with stability on stays under 25 degrees of slide")
	check(math.abs(st.r) < 0.2, string.format("%s settles after the step (yaw %.2f)", id, st.r))
	-- a quick lane change at 85% of top speed (high speed): stays stable, stability on
	local lc = newCar(spec)
	lc.vx = lc.top * 0.85
	local lcSpun = false
	for i = 1, 240 do
		local t = i * DT
		local steer = if t < 1.2 then 0.6 * math.sin(t / 1.2 * math.pi * 2) else 0
		frame(lc, { throttle = 0.9, brake = 0, steer = steer, esc = 2, help = 1 }, DT)
		if math.abs(math.atan2(lc.vy, math.max(lc.vx, 1))) > math.rad(15) then
			lcSpun = true
		end
	end
	check(not lcSpun, id .. " high-speed lane change stays straight (stability on)")
	check(math.abs(lc.r) < 0.15, string.format("%s settles after the lane change (yaw %.2f)", id, lc.r))
	-- a slide caught: a rear-drive car floored mid-corner with traction and stability off steps out; with the
	-- countersteer help and the throttle lifted it comes back
	local caught = true
	if d.drive ~= "FWD" then
		local o = newCar(spec)
		o.vx = Config.mphToSps(35)
		for i = 1, 90 do
			frame(o, { throttle = 0.3, brake = 0, steer = 0.7, esc = 0, tc = 0, help = 1 }, DT)
		end
		for i = 1, 60 do
			frame(o, { throttle = 1, brake = 0, steer = 0.7, esc = 0, tc = 0, help = 1 }, DT)
		end
		for i = 1, 180 do
			frame(o, { throttle = 0.2, brake = 0, steer = 0, esc = 0, tc = 0, help = 1 }, DT)
		end
		caught = math.abs(math.atan2(o.vy, math.max(o.vx, 1))) < math.rad(12) and math.abs(o.r) < 0.6
		-- and a powerful rear-drive car really does step out (traction and stability off)
		if d.drive == "RWD" and c.p.reserve > 1.6 then
			check(o.maxBeta > math.rad(6), string.format("%s: power oversteer with the aids off (%.1f deg)", id, math.deg(o.maxBeta)))
		end
	end
	check(caught, id .. " a power slide is caught with the countersteer help")
	table.insert(rows, string.format("| %s | %.2f / %.2f | %.0f / %d | %.1f / %.1f | %.0f | %.2f |", id, t60 or -1, want60, topMph, spec.TopSpeed, stopM, d.stop, stop60ft, latMax))
end

if showTable then
	print("| Car | 0-60 s (game / target) | Top mph (game / spec) | 100-0 m (game / real) | 60-0 ft | Max side g at 60 mph |")
	print("|---|---|---|---|---|---|")
	for _, r in rows do
		print(r)
	end
end
print(string.format("%d cars, %d fails", #list, fails))
if fails > 0 then
	process.exit(1)
end
