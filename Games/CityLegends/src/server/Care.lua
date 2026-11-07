--[[
	Care (server, owner 2026-11-07): mileage, wear, condition, fuel, the service book and visible damage of every car a
	player owns. The sums are shared/CarCare.lua, the numbers Config.Wear / Value / Service / Fuel.

	One record per car in profile.CarCare (saved). Miles and fuel are counted here, from what the car really does on
	the server; the driver's game only adds what the server can't see (held on the limiter, drifting, hard braking, a
	hit), and that can only add wear: it's clamped to the time that went by.

	The car carries what every screen needs as attributes: Odo, Fuel, CheckEngine, Eng, Tyre, Brk, Body, Dirt and Dmg
	(the visible damage, JSON). Stolen cars and test drives have no record: full tank, no wear.
	Remotes: CareCall (RemoteFunction), CareReport (RemoteEvent, driver to server), CarePush (RemoteEvent, to the driver).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Server = script.Parent
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cars = require(Shared:WaitForChild("Cars"))
local CarCare = require(Shared:WaitForChild("CarCare"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local Config = require(Shared:WaitForChild("Config"))
local PlayerData = require(Server:WaitForChild("PlayerData"))
local Dealership = require(Server:WaitForChild("Dealership"))

local W = Config.Wear
local F = Config.Fuel
local S = Config.Service

local Care = {}

type Session = {
	car: Model?,
	id: string?,
	carry: number, -- miles not yet shown
	-- from the driver's game
	reportAt: number,
	engineOn: boolean,
	throttle: number,
	warned: { [string]: boolean? },
	held: { e: number, t: number, b: number }, -- wear in a race: it lands after the finish
	lastHit: number,
	dirtyDmg: boolean,
	lifting: boolean,
}

local ctx: any = nil
local sessions: { [Player]: Session } = {}
local Push: RemoteEvent

local function sessionOf(player: Player): Session
	local s = sessions[player]
	if not s then
		s = { car = nil, id = nil, carry = 0, reportAt = 0, engineOn = false, throttle = 0.4, warned = {}, held = { e = 0, t = 0, b = 0 }, lastHit = 0, dirtyDmg = false, lifting = false }
		sessions[player] = s
	end
	return s
end

-- the record of a car, made when first asked for: from its car XP on an old save
function Care.record(player: Player, id: string): CarCare.Care?
	local profile = PlayerData.get(player) :: any
	if not profile or not Cars.ById[id] then
		return nil
	end
	local all = profile.CarCare
	if type(all) ~= "table" then
		all = {}
		profile.CarCare = all
	end
	local c = all[id]
	if not c then
		local level = if type(profile.CarLevels) == "table" then profile.CarLevels[id] else nil
		local xp = if type(profile.CarXP) == "table" then profile.CarXP[id] else nil
		c = CarCare.fresh(id, level or 1, xp or 0)
		all[id] = c
	end
	return c
end

-- a car bought today
function Care.onBought(player: Player, id: string)
	local profile = PlayerData.get(player) :: any
	if not profile then
		return
	end
	profile.CarCare = if type(profile.CarCare) == "table" then profile.CarCare else {}
	profile.CarCare[id] = CarCare.fresh(id)
end

local function damageJson(c: CarCare.Care): string
	local cracks = {}
	for k in c.cracks do
		table.insert(cracks, k)
	end
	return HttpService:JSONEncode({ m = c.marks, c = cracks, r = c.rash })
end

local function setIf(car: Model, name: string, value: any)
	if car:GetAttribute(name) ~= value then
		car:SetAttribute(name, value)
	end
end

local function publish(car: Model, c: CarCare.Care)
	setIf(car, "Odo", math.floor(c.m))
	setIf(car, "Fuel", math.floor(c.f * 1000) / 1000)
	setIf(car, "CheckEngine", CarCare.checkEngine(c))
	setIf(car, "ServiceIn", math.floor(CarCare.dueIn(c)))
	setIf(car, "Eng", math.floor(c.e * 10) / 10)
	setIf(car, "Tyre", math.floor(c.t * 10) / 10)
	setIf(car, "Brk", math.floor(c.b * 10) / 10)
	setIf(car, "Body", math.floor(c.h * 10) / 10)
	setIf(car, "Dirt", math.floor(c.d * 100) / 100)
end

-- a car comes out, or goes on a trailer: it carries its record
function Care.applyTo(player: Player, car: Model, id: string)
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		car:SetAttribute("Fuel", 1)
		return
	end
	local c = Care.record(player, id)
	if c then
		publish(car, c)
		car:SetAttribute("Dmg", damageJson(c))
	end
end

local function note(player: Player, text: string, kind: string?)
	Push:FireClient(player, { kind = kind or "toast", text = text })
end

-- wear goes on the record; in a race it waits for the finish, so it can't change the result
local function wear(player: Player, s: Session, c: CarCare.Care, e: number, t: number, b: number)
	local profile = PlayerData.get(player) :: any
	if not profile or (profile.DriveSeconds or 0) < W.ProtectSeconds then
		return
	end
	if ctx.isRacing(player) then
		s.held.e += e
		s.held.t += t
		s.held.b += b
		return
	end
	if s.held.e + s.held.t + s.held.b > 0 then
		e += s.held.e
		t += s.held.t
		b += s.held.b
		s.held = { e = 0, t = 0, b = 0 }
	end
	c.e = math.max(c.e - e, 0)
	c.t = math.max(c.t - t, 0)
	c.b = math.max(c.b - b, 0)
end

local function towing(player: Player): boolean
	return ctx.isTowing ~= nil and ctx.isTowing(player)
end

local function reminders(player: Player, s: Session, c: CarCare.Care)
	local due = CarCare.dueIn(c)
	if due < W.ServiceWarn and due > 0 and not s.warned.due then
		s.warned.due = true
		note(player, "Service due in " .. math.ceil(due) .. " mi")
	elseif due <= 0 and not s.warned.over then
		s.warned.over = true
		c.late = true
		note(player, "Service overdue: Legends Service", "service")
	end
	if c.e < W.EngineLimp and not s.warned.limp then
		s.warned.limp = true
		note(player, "Limp mode: get to Legends Service", "service")
	elseif c.e < W.EngineFlash and not s.warned.flash then
		s.warned.flash = true
		note(player, "Engine misfiring: get to Legends Service", "service")
	end
	if c.f <= F.Low and not s.warned.low then
		s.warned.low = true
		Push:FireClient(player, { kind = "lowfuel" })
	elseif c.f > F.Low + 0.05 then
		s.warned.low = nil
	end
end

local function step(player: Player, dt: number)
	local car = ctx.getCar(player)
	local s = sessionOf(player)
	if not car or car.Parent == nil or not car.PrimaryPart then
		s.car, s.id = nil, nil
		return
	end
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return
	end
	local id = car:GetAttribute("CarId") :: string
	if s.car ~= car then
		s.car, s.id = car, id
		s.warned = {}
	end
	if player.Character ~= nil or s.lifting then
		return -- (parked, or on the lift)
	end
	local c = Care.record(player, id)
	if not c then
		return
	end
	local profile = PlayerData.get(player) :: any
	-- Studio test hook: the player attribute TestCare, JSON of record fields ("drive" = profile.DriveSeconds)
	if RunService:IsStudio() and type(player:GetAttribute("TestCare")) == "string" then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(player:GetAttribute("TestCare") :: string)
		end)
		player:SetAttribute("TestCare", nil)
		if ok and type(data) == "table" then
			for k, value in data do
				if k == "drive" then
					profile.DriveSeconds = value
				else
					(c :: any)[k] = value
				end
			end
			publish(car, c)
		end
	end
	local v = car.PrimaryPart.AssemblyLinearVelocity
	local spec = Cars.get(id)
	local mph = math.min(Config.spsToMph(Vector3.new(v.X, 0, v.Z).Magnitude), spec.TopSpeed * 1.25)
	local on = s.engineOn or mph > 3
	if on then
		profile.DriveSeconds = (profile.DriveSeconds or 0) + dt
	end
	-- the odometer (from the speed, so fast travel, the valet and a trailer add nothing)
	if mph > 1 then
		local miles = mph * dt / 3600 * W.OdoScale
		c.m += miles
		s.carry += miles
		local k = if towing(player) then W.Tow else 1
		local overdue = CarCare.dueIn(c) < 0
		wear(player, s, c, miles * W.Engine.PerMile * k * (if overdue then W.Engine.Overdue else 1), miles * W.Tyres.PerMile * k, miles * W.Brakes.PerMile * k)
		c.d = math.min(c.d + miles / 1200, 1)
	end
	-- fuel
	if on then
		local hp = CarStats.powerOf(id, CarStats.decodeParts(car:GetAttribute("Parts")))
		local stock = CarStats.of(id).hp
		local tuned = math.clamp(hp / math.max(stock, 1), 1, 1.6) ^ 0.5
		local burn = dt / (CarCare.tankMinutes(stock) * 60) * CarCare.burnLoad(mph, s.throttle) * tuned * (if towing(player) then F.Tow else 1)
		local floor = if ctx.isBusy(player) or (player:GetAttribute("Wanted") or 0) > 0 or player:GetAttribute("Loot") then F.PauseAt else 0
		if c.f > floor then
			c.f = math.max(c.f - burn, floor)
		end
	end
	publish(car, c)
	reminders(player, s, c)
end

-- what the driver's game saw in the last few seconds: red (seconds held on the limiter past RedlineAfter), launch
-- (hard launches), drift, burn, hard (seconds), thr (0..1), on, wet, hits
local function onReport(player: Player, raw: any)
	if type(raw) ~= "table" then
		return
	end
	local s = sessionOf(player)
	local now = os.clock()
	local span = math.min(now - s.reportAt, 6)
	s.reportAt = now
	local function secs(key: string): number
		local n = tonumber(raw[key])
		return if n and n == n then math.clamp(n, 0, span + 0.5) else 0
	end
	local car = ctx.getCar(player)
	if not car or car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return
	end
	s.engineOn = raw.on == true
	local thr = tonumber(raw.thr)
	s.throttle = if thr and thr == thr then math.clamp(thr, 0, 1) else 0.4
	local id = car:GetAttribute("CarId") :: string
	local c = Care.record(player, id)
	if not c then
		return
	end
	local launches = math.clamp(tonumber(raw.launch) or 0, 0, 2)
	wear(player, s, c, secs("red") * W.Engine.RedlinePerSecond + launches * W.Engine.Launch, secs("drift") * W.Tyres.DriftPerSecond + secs("burn") * W.Tyres.BurnPerSecond, secs("hard") * W.Brakes.HardPerSecond)
	if raw.wet == true then
		c.d = math.max(c.d - span * 0.002, 0) -- rain washes a little off
	end
	-- hits: { k, f, u, v, n, sp (speed lost) }, a few a report at most
	if type(raw.hits) == "table" then
		local changed = false
		for i, hit in raw.hits do
			if i > 4 then
				break
			end
			local mark = CarCare.cleanMark(hit)
			local speed = if type(hit) == "table" then tonumber(hit.sp) else nil
			if mark and speed and speed == speed and now - s.lastHit > 0.15 then
				s.lastHit = now
				speed = math.clamp(speed, 0, 160)
				if #c.marks >= CarCare.MaxMarks then
					table.remove(c.marks, 1)
				end
				table.insert(c.marks, mark)
				local bodyLoss = if mark.k == "s" then 0.4 elseif mark.k == "t" then 0.3 else math.min(speed / 12, 6)
				c.h = math.max(c.h - bodyLoss, 0)
				if mark.k == "d" then
					wear(player, s, c, W.Engine.Crash * math.min(speed / 60, 2), 0, 0)
					-- a big hit: a lamp or the windscreen cracks
					if speed > 55 then
						if mark.f == "F" then
							c.cracks[if mark.u < 0.5 then "headL" else "headR"] = true
							c.cracks.bumperF = true
						elseif mark.f == "B" then
							c.cracks[if mark.u < 0.5 then "tailL" else "tailR"] = true
							c.cracks.bumperB = true
						end
					end
					-- a hard hit on a side knocks that mirror loose
					if speed > 40 and (mark.f == "L" or mark.f == "R") then
						c.cracks[if mark.f == "L" then "mirrorL" else "mirrorR"] = true
					end
					if speed > 80 and mark.f == "F" then
						c.cracks.glass = true
					end
				end
				changed = true
			end
		end
		if changed then
			car:SetAttribute("Dmg", damageJson(c))
		end
	end
	local rash = tonumber(raw.rash)
	if rash and rash >= 1 and rash <= 4 then
		local bit = 2 ^ (math.floor(rash) - 1)
		if math.floor(c.rash / bit) % 2 == 0 then
			c.rash += bit
			car:SetAttribute("Dmg", damageJson(c))
		end
	end
end

---------------------------------------------------------------------
-- The screens' calls
---------------------------------------------------------------------
local function atBay(car: Model?): boolean
	if not car then
		return false
	end
	local d = car:GetPivot().Position - S.Bay
	return Vector3.new(d.X, 0, d.Z).Magnitude <= S.BayRadius + 6
end

local function atPump(car: Model?): boolean
	if not car then
		return false
	end
	local p = car:GetPivot().Position
	for _, st in Config.Fuel.Stations do
		for _, pump in if car:GetAttribute("Electric") == true then st.chargers else st.pumps do
			if (p - pump).Magnitude <= F.PumpRange + 6 then
				return true
			end
		end
	end
	return false
end

local function stateFor(player: Player, id: string): { [string]: any }?
	local c = Care.record(player, id)
	if not c then
		return nil
	end
	local profile = PlayerData.get(player) :: any
	local value = CarCare.value(id, c)
	local spec = Cars.get(id)
	return {
		ok = true,
		id = id,
		name = spec.Name,
		miles = math.floor(c.m),
		due = math.floor(CarCare.dueIn(c)),
		oil = math.clamp(CarCare.dueIn(c) / W.ServiceEvery, 0, 1),
		e = c.e, t = c.t, b = c.b, h = c.h, f = c.f, d = c.d,
		check = CarCare.checkEngine(c),
		value = value,
		breakdown = CarCare.breakdown(id, c),
		sell = math.floor(value * Config.Value.SellShare / 10 + 0.5) * 10,
		prices = CarCare.prices(id, c),
		fill = CarCare.fillPrice(id, c),
		tank = CarCare.tank(id),
		electric = spec.Electric == true,
		book = c.book,
		cash = profile.Cash,
		freeFill = profile.FreeFill ~= false,
		freeService = profile.FreeService ~= false,
		marks = #c.marks,
	}
end

local function fix(c: CarCare.Care, job: string)
	if job == "oil" or job == "full" then
		if CarCare.dueIn(c) < 0 then
			c.late = true
		end
		c.last = c.m
		c.e = math.min(c.e + W.ServiceBack, 100)
	end
	if job == "engine" or job == "full" then
		c.e = 100
	end
	if job == "tyres" or job == "full" then
		c.t = 100
	end
	if job == "brakes" or job == "full" then
		c.b = 100
	end
	if job == "body" or job == "full" then
		c.h = 100
		c.marks = {}
		c.cracks = {}
		c.rash = 0
	end
end

-- the car goes up on the lift for a few seconds, then back down (every screen sees it)
local function lift(player: Player, s: Session, car: Model)
	local root = car.PrimaryPart
	if not root then
		return
	end
	s.lifting = true
	local from = car:GetPivot()
	root.Anchored = true
	local T = S.LiftSeconds
	local t0 = os.clock()
	while os.clock() - t0 < T and car.Parent do
		local k = (os.clock() - t0) / T
		local h = math.sin(math.clamp(k, 0, 1) * math.pi)
		h = math.clamp(h * 1.6, 0, 1)
		car:PivotTo(from + Vector3.new(0, h * 5.5, 0))
		RunService.Heartbeat:Wait()
	end
	if car.Parent then
		car:PivotTo(from)
		root.Anchored = false
		pcall(function()
			root:SetNetworkOwner(player)
		end)
	end
	s.lifting = false
end

local handlers: { [string]: (Player, any) -> { [string]: any } } = {}

handlers.state = function(player, id)
	local car = ctx.getCar(player)
	local carId = if type(id) == "string" then id elseif car then car:GetAttribute("CarId") else nil
	local profile = PlayerData.get(player)
	if type(carId) ~= "string" or not profile or not profile.Owned[carId] then
		return { ok = false, message = "Not your car" }
	end
	return stateFor(player, carId) or { ok = false }
end

handlers.service = function(player, job)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player) :: any
	local s = sessionOf(player)
	if type(job) ~= "string" or not profile or not car or s.lifting then
		return { ok = false, message = "Try again" }
	end
	if not atBay(car) then
		return { ok = false, message = "Drive into the bay first" }
	end
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return { ok = false, message = "Only your own cars" }
	end
	local id = car:GetAttribute("CarId") :: string
	local c = Care.record(player, id) :: CarCare.Care
	local prices = CarCare.prices(id, c)
	local price = prices[job]
	if not price or price <= 0 then
		return { ok = false, message = "Nothing to do there" }
	end
	-- the first oil service is free, on its own or as part of a full service
	if profile.FreeService ~= false then
		if job == "oil" then
			price = 0
		elseif job == "full" then
			price = math.max(price - prices.oil, 0)
		end
	end
	if profile.Cash < price then
		return { ok = false, message = "Not enough cash" }
	end
	if price > 0 then
		PlayerData.addCash(player, -price)
	end
	if job == "oil" or job == "full" then
		profile.FreeService = false
	end
	s.warned = {}
	lift(player, s, car)
	fix(c, job)
	table.insert(c.book, 1, { t = os.time(), m = math.floor(c.m), k = job })
	while #c.book > 12 do
		table.remove(c.book)
	end
	publish(car, c)
	car:SetAttribute("Dmg", damageJson(c))
	task.spawn(PlayerData.save, player)
	local st = stateFor(player, id) or {}
	st.ok = true
	st.paid = price
	return st
end

handlers.fill = function(player, dollars)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player) :: any
	if not profile or not car then
		return { ok = false, message = "Try again" }
	end
	if not atPump(car) then
		return { ok = false, message = "Stop at a pump first" }
	end
	if car:GetAttribute("Stolen") or car:GetAttribute("TestEnds") then
		return { ok = false, message = "Only your own cars" }
	end
	local id = car:GetAttribute("CarId") :: string
	local c = Care.record(player, id) :: CarCare.Care
	local full = CarCare.fillPrice(id, c)
	if full <= 0 then
		return { ok = false, message = "The tank is full" }
	end
	local pay = full
	if type(dollars) == "number" and dollars == dollars and dollars > 0 then
		pay = math.min(math.floor(dollars), full)
	end
	local free = profile.FreeFill ~= false
	if not free and profile.Cash < pay then
		if profile.Cash < 1 then
			return { ok = false, message = "Not enough cash" }
		end
		pay = math.floor(profile.Cash)
	end
	local share = pay / math.max(full, 1) * (1 - c.f)
	if free then
		share = 1 - c.f
		pay = 0
		profile.FreeFill = false
	else
		PlayerData.addCash(player, -pay)
	end
	c.f = math.min(c.f + share, 1)
	publish(car, c)
	sessionOf(player).warned.low = nil
	task.spawn(PlayerData.save, player)
	local st = stateFor(player, id) or {}
	st.ok = true
	st.paid = pay
	return st
end

handlers.wash = function(player)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player)
	if not profile or not car or not atPump(car) then
		return { ok = false, message = "Stop at a station first" }
	end
	if profile.Cash < S.Wash then
		return { ok = false, message = "Not enough cash" }
	end
	local id = car:GetAttribute("CarId") :: string
	local c = Care.record(player, id)
	if not c then
		return { ok = false }
	end
	PlayerData.addCash(player, -S.Wash)
	c.d = 0
	publish(car, c)
	return { ok = true, paid = S.Wash }
end

-- out of fuel: a can brought to you, or a tow to the nearest station
handlers.roadside = function(player, kind)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player)
	if not profile or not car then
		return { ok = false, message = "Try again" }
	end
	local id = car:GetAttribute("CarId") :: string
	local c = Care.record(player, id)
	if not c or c.f > F.Low then
		return { ok = false, message = "You don't need help" }
	end
	local price = if kind == "tow" then F.TowPrice else F.CanPrice
	price = math.min(price, profile.Cash)
	PlayerData.addCash(player, -price)
	if kind == "tow" then
		local p = car:GetPivot().Position
		local best: any, bestD = nil, math.huge
		for _, st in Config.Fuel.Stations do
			local d = (st.pumps[1] - p).Magnitude
			if d < bestD then
				best, bestD = st, d
			end
		end
		c.f = math.max(c.f, F.PauseAt * 2)
		if best then
			pcall(function()
				player:RequestStreamAroundAsync(best.arrive.Position, 6)
			end)
			Push:FireClient(player, { kind = "tow", cf = best.arrive })
		end
	else
		c.f = math.min(c.f + F.CanShare, 1)
	end
	publish(car, c)
	return { ok = true, paid = price }
end

-- selling at Legends Motors: the car goes, its record too
handlers.sell = function(player, id)
	local profile = PlayerData.get(player) :: any
	if type(id) ~= "string" or not profile or not profile.Owned[id] then
		return { ok = false, message = "Not your car" }
	end
	if not Dealership.near(player, ctx.getCar) then
		return { ok = false, message = "Sell it at " .. Config.Dealership.Name }
	end
	local n = 0
	for _ in profile.Owned do
		n += 1
	end
	if n <= 1 then
		return { ok = false, message = "You can't sell your last car" }
	end
	local out = ctx.getCar(player)
	if out and out:GetAttribute("CarId") == id then
		return { ok = false, message = "You're driving that one" }
	end
	local c = Care.record(player, id) :: CarCare.Care
	local pay = math.floor(CarCare.value(id, c) * Config.Value.SellShare / 10 + 0.5) * 10
	profile.Owned[id] = nil
	profile.CarCare[id] = nil
	if profile.Selected == id then
		profile.Selected = next(profile.Owned)
	end
	PlayerData.addCash(player, pay)
	task.spawn(PlayerData.save, player)
	return { ok = true, paid = pay, data = PlayerData.snapshot(player) }
end

function Care.init(c: any)
	ctx = c
	Push = ctx.remote("RemoteEvent", "CarePush")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "CareCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	local report: RemoteEvent = ctx.remote("RemoteEvent", "CareReport")
	report.OnServerEvent:Connect(onReport)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t < 0.5 then
			return
		end
		local span = t
		t = 0
		for _, player in Players:GetPlayers() do
			local ok, err = pcall(step, player, span)
			if not ok then
				warn("[CityLegends] Care:", err)
			end
		end
	end)
end

return Care
