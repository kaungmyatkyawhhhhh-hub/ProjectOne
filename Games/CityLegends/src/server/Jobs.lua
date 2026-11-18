--[[
	Jobs (server; owner approved 18 Nov 2026: "job ranks + paychecks", Southwest Florida style)
	Numbers in Config.Jobs, sums in shared/JobRules.lua, screens in client/JobsClient.lua.
	  * the Job Center kiosk on Myanmar Plaza's forecourt: pick or quit a job there (quit anywhere)
	  * active jobs (delivery, taxi, YBS bus, traffic police): on duty while you do the job; pay per
	    stop / fare / patrol point / ticket, plus a small paycheck every PaycheckSeconds on duty.
	    Delivery is the old dispatch-ring job (Activities.lua calls Jobs.task when one is done)
	  * posts (tea shop, fuel station, dealership, mall shop): stand at the post; a paycheck every
	    PaycheckSeconds, for at most PostCapSeconds a day
	  * 5 ranks per job from job XP (duty minutes + tasks), saved per job in profile.Activities.jobs
	Everything is decided here: the client only asks ("take", "quit", "arrive") and shows.
	Remotes: JobCall (RemoteFunction), JobPush (RemoteEvent: state, paid, task, promoted, open, ticketed).
	Studio test hooks (server player attributes, Studio only): TestDoublePay = true, TestJobXp = n (adds n XP
	to the current job once), TestPaycheckSeconds = n (a shorter paycheck).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local JobRules = require(Shared:WaitForChild("JobRules"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local J = Config.Jobs
local GOLD = Config.Theme.Accent2

local Jobs = {}

type Task = { kind: string, pos: Vector3, name: string, from: Vector3, t0: number, stop: number? }
type Live = { duty: number, task: Task?, lastTask: number, lastCall: number, tickets: { [Player]: number }, pushAt: number }
local live: { [Player]: Live } = {}
local ctx: any
local Push: RemoteEvent
local earnMult: ((Player, string) -> number)? = nil -- (server/Store.lua's, when it's in the place)

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function L(player: Player): Live
	local s = live[player]
	if not s then
		s = { duty = 0, task = nil, lastTask = os.clock(), lastCall = 0, tickets = {}, pushAt = 0 }
		live[player] = s
	end
	return s
end

-- the saved part: { cur = job id?, xp = { [id] = n }, day = UTC day, post = paid post seconds that day }
local function saved(player: Player): any
	local profile = PlayerData.get(player) :: any
	if not profile or not profile.Loaded or type(profile.Activities) ~= "table" then
		return nil
	end
	local s = profile.Activities.jobs
	if type(s) ~= "table" then
		s = {}
		profile.Activities.jobs = s
	end
	if type(s.xp) ~= "table" then
		s.xp = {}
	end
	for id, n in s.xp do
		if not JobRules.byId(J, id) or type(n) ~= "number" or n ~= n or n < 0 then
			s.xp[id] = nil
		end
	end
	if s.cur ~= nil and not JobRules.byId(J, s.cur) then
		s.cur = nil
	end
	if type(s.day) ~= "number" or type(s.post) ~= "number" then
		s.day, s.post = JobRules.day(os.time()), 0
	end
	if s.day ~= JobRules.day(os.time()) then
		s.day, s.post = JobRules.day(os.time()), 0
	end
	return s
end

local function where(player: Player): Vector3?
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		return hrp.Position
	end
	local car = ctx.getCar(player)
	return if car and car.PrimaryPart then car.PrimaryPart.Position else nil
end

-- in their own car, driving (on foot you have a character; a parked car doesn't count)
local function carRoot(player: Player): BasePart?
	local car = ctx.getCar(player)
	if not car or player.Character or car:GetAttribute("Parked") then
		return nil
	end
	return car.PrimaryPart
end

local function double(player: Player): boolean
	return player:GetAttribute("DoublePay") == true or (RunService:IsStudio() and player:GetAttribute("TestDoublePay") == true)
end

-- pays a job amount: 2x Cash / Premium on top (Store.earnMult "job"), like the delivery job
local function pay(player: Player, amount: number): number
	local cash = math.floor(amount * (if earnMult then earnMult(player, "job") else 1) + 0.5)
	if cash > 0 then
		PlayerData.addCash(player, cash)
	end
	return cash
end

local function stateOf(player: Player): { [string]: any }
	local s = saved(player)
	local lv = L(player)
	local st: { [string]: any } = { ok = s ~= nil, double = double(player), ranks = {} }
	if not s then
		return st
	end
	for _, job in J.List do
		st.ranks[job.id] = (JobRules.rank(J, s.xp[job.id] or 0))
	end
	st.postLeft = JobRules.postLeft(J, s, os.time())
	local job = JobRules.byId(J, s.cur)
	if job then
		local r, into, span = JobRules.rank(J, s.xp[job.id] or 0)
		st.job = job.id
		st.rank = r
		st.title = job.ranks[r]
		st.into = math.floor(into)
		st.span = span
		st.paycheck = JobRules.paycheck(J, job, r, st.double)
		st.payIn = math.max(0, Jobs.paySeconds(player) - lv.duty)
		st.onDuty = lv.onDuty == true
		local t = lv.task
		if t then
			st.task = { kind = t.kind, pos = t.pos, name = t.name }
		end
	end
	return st
end

local function push(player: Player, msg: { [string]: any })
	if Push and player.Parent then
		Push:FireClient(player, msg)
	end
end

local function pushState(player: Player)
	L(player).pushAt = os.clock()
	push(player, { kind = "state", state = stateOf(player) })
end

function Jobs.paySeconds(player: Player): number
	local t = if RunService:IsStudio() then player:GetAttribute("TestPaycheckSeconds") else nil
	return if type(t) == "number" and t >= 5 then t else J.PaycheckSeconds
end

-- adds job XP; a new rank is a promotion (saved straight away)
local function addXp(player: Player, s: any, job: any, n: number)
	local before = JobRules.rank(J, s.xp[job.id] or 0)
	s.xp[job.id] = (s.xp[job.id] or 0) + n
	local after = JobRules.rank(J, s.xp[job.id])
	if after > before then
		push(player, { kind = "promoted", job = job.name, title = job.ranks[after], rank = after, paycheck = JobRules.paycheck(J, job, after, double(player)) })
		ctx.note(player, "promotions", after - before)
		task.spawn(PlayerData.save, player)
		pushState(player)
	end
end

---------------------------------------------------------------------
-- Tasks: bus stops, taxi fares, patrol points
---------------------------------------------------------------------
local function places(): { { name: string, pos: Vector3 } }
	local list = {}
	for _, p in ActivityData.dropPoints do
		table.insert(list, p)
	end
	for _, p in ActivityData.dispatch do
		table.insert(list, p)
	end
	for _, p in J.BusStops do
		table.insert(list, p)
	end
	return list
end

-- a random place between lo and hi studs from `from` (else the nearest one beyond lo)
local function pickPlace(from: Vector3, lo: number, hi: number): { name: string, pos: Vector3 }?
	local fit, beyond, bestD = {}, nil, math.huge
	for _, p in places() do
		local d = flat(p.pos, from)
		if d >= lo and d <= hi then
			table.insert(fit, p)
		elseif d > lo and d < bestD then
			beyond, bestD = p, d
		end
	end
	return if #fit > 0 then fit[math.random(1, #fit)] else beyond
end

local function newTask(player: Player, jobId: string, after: Task?): Task?
	local root = carRoot(player)
	local from = if after then after.pos elseif root then root.Position else where(player)
	if not from then
		return nil
	end
	local now = os.clock()
	if jobId == "bus" then
		local k = 1
		if after and after.stop then
			k = after.stop % #J.BusStops + 1
		else
			local best = math.huge
			for i, b in J.BusStops do
				local d = flat(b.pos, from)
				if d < best then
					k, best = i, d
				end
			end
		end
		local b = J.BusStops[k]
		return { kind = "stop", pos = b.pos, name = b.name, from = from, t0 = now, stop = k }
	elseif jobId == "taxi" then
		if after and after.kind == "pickup" then
			local p = pickPlace(after.pos, J.Taxi.FareMin, math.huge)
			return if p then { kind = "fare", pos = p.pos, name = p.name, from = after.pos, t0 = now } else nil
		end
		local p = pickPlace(from, J.Taxi.PickupMin, J.Taxi.PickupMax)
		return if p then { kind = "pickup", pos = p.pos, name = p.name, from = from, t0 = now } else nil
	elseif jobId == "police" then
		local p = pickPlace(from, J.Patrol.Min, J.Patrol.Max)
		return if p then { kind = "patrol", pos = p.pos, name = p.name, from = from, t0 = now } else nil
	end
	return nil
end

-- the car reached its task (client asks; checked here): pay, XP, next task
local function arrive(player: Player): { [string]: any }
	local s = saved(player)
	local lv = L(player)
	local job = s and JobRules.byId(J, s.cur)
	local t = lv.task
	local root = carRoot(player)
	if not (s and job and t and root) then
		return { ok = false }
	end
	local speed = root.AssemblyLinearVelocity.Magnitude
	if flat(root.Position, t.pos) > J.ArriveRadius or speed > J.StopSps then
		return { ok = false, message = "Stop at the marker" }
	end
	local dist = flat(t.from, t.pos)
	if os.clock() - t.t0 < JobRules.minLegSeconds(J, dist) then
		return { ok = false } -- quicker than any car: not driven
	end
	local r = JobRules.rank(J, s.xp[job.id] or 0)
	local cash, what = 0, ""
	if t.kind == "pickup" then
		what = "PASSENGER IN"
	else
		cash = pay(player, JobRules.taskPay(J, job, r, dist, double(player)))
		what = if t.kind == "fare" then "FARE PAID" elseif t.kind == "stop" then "BUS STOP" else "PATROL CHECK"
		ctx.note(player, "jobtasks", 1)
	end
	lv.lastTask = os.clock()
	addXp(player, s, job, if t.kind == "pickup" then 0 else job.taskXp)
	lv.task = newTask(player, job.id, t)
	pushState(player)
	return { ok = true, cash = cash, what = what, name = t.name }
end

-- a delivery was finished (Activities.lua): job XP and the rank / Double Pay part of the pay
function Jobs.task(player: Player, kind: string, cash: number)
	local s = saved(player)
	local job = s and JobRules.byId(J, s.cur)
	if not (s and job and job.id == kind) then
		return 0
	end
	L(player).lastTask = os.clock()
	-- (the delivery's own cash already has Double Pay, 2x Cash and Premium in it: Activities.lua)
	local r = JobRules.rank(J, s.xp[job.id] or 0)
	local extra = math.max(0, math.floor(cash * (JobRules.mult(J, r) - 1) + 0.5))
	if extra > 0 then
		PlayerData.addCash(player, extra)
	end
	addXp(player, s, job, job.taskXp)
	ctx.note(player, "jobtasks", 1)
	pushState(player)
	return extra
end

---------------------------------------------------------------------
-- The Job Center kiosk (the Chauffeur stand's style: lit glass column, gold trim, glass canopy)
---------------------------------------------------------------------
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props then
		for k, val in props do
			(p :: any)[k] = val
		end
	end
	p.Parent = parent
	return p
end

local function buildCenter()
	local base = J.Center
	local model = Instance.new("Model")
	model.Name = "JobCenter"
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z)
	end
	local black = Color3.fromRGB(14, 14, 18)
	local wood = Color3.fromRGB(150, 106, 66)
	part(model, Vector3.new(14, 0.5, 7), at(0, 0.25, 0.5), Color3.fromRGB(40, 40, 44), Enum.Material.Marble)
	-- the lit board behind the counter
	local board = part(model, Vector3.new(9, 9, 0.8), at(0, 5.2, 2.6), black, Enum.Material.Glass, { Reflectance = 0.15 })
	for _, x in { -4.6, 4.6 } do
		part(model, Vector3.new(0.2, 9.4, 0.9), at(x, 5.2, 2.6), GOLD, Enum.Material.Metal, { Reflectance = 0.2 })
	end
	part(model, Vector3.new(9.4, 0.25, 1), at(0, 9.95, 2.6), GOLD, Enum.Material.Metal, { Reflectance = 0.2 })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.6
	gui.CanvasSize = Vector2.new(900, 900)
	gui.Parent = board
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(30, 26, 18), Color3.fromRGB(6, 6, 10))
	grad.Rotation = 90
	grad.Parent = bg
	local function text(t: string, y: number, h: number, size: number, color: Color3, font: Enum.Font)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(30, y)
		l.Size = UDim2.new(1, -60, 0, h)
		l.Text = t
		l.TextColor3 = color
		l.TextSize = size
		l.Font = font
		l.TextWrapped = true
		l.Parent = bg
	end
	text("LEGENDS", 120, 110, 100, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	text("JOB CENTER", 230, 100, 86, GOLD, Enum.Font.GothamBlack)
	text("Taxi · YBS Bus · Traffic Police · Delivery\nTea Shop · Fuel Station · Dealership · Mall", 400, 200, 40, Color3.fromRGB(200, 200, 210), Enum.Font.Gotham)
	text("5 RANKS · PAYCHECK EVERY MINUTE", 650, 60, 40, GOLD, Enum.Font.GothamBold)
	-- the counter in front
	part(model, Vector3.new(8, 3.4, 1.6), at(0, 2.2, -0.6), wood, Enum.Material.Wood)
	part(model, Vector3.new(8.4, 0.3, 2), at(0, 4.05, -0.6), GOLD, Enum.Material.Metal, { Reflectance = 0.2 })
	-- canopy on two posts
	for _, x in { -6.2, 6.2 } do
		part(model, Vector3.new(0.45, 11.6, 0.45), at(x, 5.8, 3.2), black, Enum.Material.Metal)
	end
	part(model, Vector3.new(13.4, 0.3, 7.2), at(0, 11.7, 0.6), Color3.fromRGB(200, 214, 222), Enum.Material.Glass, { Transparency = 0.45 })
	part(model, Vector3.new(13.8, 0.5, 0.3), at(0, 11.7, -3.05), GOLD, Enum.Material.Metal)
	part(model, Vector3.new(13.8, 0.5, 0.3), at(0, 11.7, 4.25), GOLD, Enum.Material.Metal)
	local down = part(model, Vector3.new(1, 0.1, 1), at(0, 11.45, -1.2), Color3.fromRGB(255, 236, 200), Enum.Material.Glass)
	local dl = Instance.new("SpotLight")
	dl.Face = Enum.NormalId.Bottom
	dl.Color = Color3.fromRGB(255, 220, 170)
	dl.Range = 16
	dl.Brightness = 1.4
	dl.Angle = 100
	dl:AddTag("LODLight")
	dl.Parent = down
	local glow = Instance.new("PointLight")
	glow.Color = GOLD
	glow.Range = 14
	glow.Brightness = 1
	glow:AddTag("LODLight")
	glow.Parent = board
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "JobCenter"
	prompt.ActionText = "Find a job"
	prompt.ObjectText = "Legends Job Center"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part(model, Vector3.new(1, 1, 1), at(0, 3, -2.2), black, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false })
	prompt.Triggered:Connect(function(who: Player)
		pushState(who)
		push(who, { kind = "open" })
	end)
	model.Parent = workspace
end

---------------------------------------------------------------------
-- Remote calls
---------------------------------------------------------------------
local handlers: { [string]: (Player, any) -> any } = {}

handlers.state = function(player)
	return stateOf(player)
end

handlers.take = function(player, id)
	local s = saved(player)
	local job = JobRules.byId(J, id)
	if not (s and job) then
		return { ok = false }
	end
	local pos = where(player)
	if not pos or flat(pos, J.Center.Position) > J.CenterRange then
		return { ok = false, message = "Take jobs at the Job Center (Myanmar Plaza)" }
	end
	s.cur = job.id
	local lv = L(player)
	lv.duty, lv.lastTask = 0, os.clock()
	lv.task = newTask(player, job.id, nil)
	task.spawn(PlayerData.save, player)
	pushState(player)
	return { ok = true, state = stateOf(player) }
end

handlers.quit = function(player)
	local s = saved(player)
	if not s then
		return { ok = false }
	end
	s.cur = nil
	local lv = L(player)
	lv.task, lv.duty, lv.onDuty = nil, 0, false
	pushState(player)
	return { ok = true, state = stateOf(player) }
end

handlers.arrive = arrive

---------------------------------------------------------------------
-- The duty clock (once a second): paychecks, duty XP, post caps, police tickets
---------------------------------------------------------------------
local function tick(player: Player)
	local s = saved(player)
	local job = s and JobRules.byId(J, s.cur)
	local lv = L(player)
	if not (s and job) then
		lv.onDuty = false
		return
	end
	-- Studio: the XP hook
	if RunService:IsStudio() then
		local add = player:GetAttribute("TestJobXp")
		if type(add) == "number" and add > 0 then
			player:SetAttribute("TestJobXp", nil)
			addXp(player, s, job, add)
		end
	end
	local wanted = ((player:GetAttribute("Wanted") :: number?) or 0) > 0
	local onDuty = false
	if job.kind == "post" then
		local pos = where(player)
		onDuty = pos ~= nil and flat(pos, job.post) <= J.PostRadius and math.abs(pos.Y - job.post.Y) < 14 and JobRules.postLeft(J, s, os.time()) > 0
	else
		local root = carRoot(player)
		if root and not lv.task and job.id ~= "delivery" then
			lv.task = newTask(player, job.id, nil) -- (took the job on foot: the first task once you drive)
		end
		local busy = if job.id == "delivery" then ctx.isBusy(player) else lv.task ~= nil
		onDuty = root ~= nil and not wanted and (busy or os.clock() - lv.lastTask < 60) and os.clock() - lv.lastTask < J.IdleSeconds
		if job.id == "delivery" and busy then
			lv.lastTask = math.max(lv.lastTask, os.clock() - 30) -- a delivery run in progress is work
		end
		-- traffic police: a real player speeding past is a ticket (no fine for them: just the officer's pay)
		if job.id == "police" and root then
			local P = Config.Police
			for _, other in Players:GetPlayers() do
				local oroot = if other ~= player then carRoot(other) else nil
				if oroot and flat(oroot.Position, root.Position) < J.Ticket.Range and os.clock() - (lv.tickets[other] or -1e9) > J.Ticket.Cooldown then
					local kmh = Config.spsToMph(oroot.AssemblyLinearVelocity.Magnitude) * 1.609
					if kmh > P.SpeedLimitKmh + P.CameraGraceKmh then
						lv.tickets[other] = os.clock()
						local r = JobRules.rank(J, s.xp.police or 0)
						local cash = pay(player, math.floor(J.Ticket.Pay * JobRules.mult(J, r, double(player)) + 0.5))
						lv.lastTask = os.clock()
						addXp(player, s, job, J.Ticket.Xp)
						ctx.note(player, "jobtasks", 1)
						push(player, { kind = "task", what = "SPEEDER TICKETED", name = other.DisplayName .. " · " .. math.floor(kmh) .. " km/h", cash = cash })
						push(other, { kind = "ticketed", by = player.DisplayName, kmh = math.floor(kmh), limit = P.SpeedLimitKmh })
					end
				end
			end
		end
	end
	local changed = onDuty ~= (lv.onDuty == true)
	lv.onDuty = onDuty
	if onDuty then
		lv.duty += 1
		if job.kind == "post" then
			s.post += 1
		end
		addXp(player, s, job, J.DutyXpPerMinute / 60)
		if lv.duty >= Jobs.paySeconds(player) then
			lv.duty = 0
			local r = JobRules.rank(J, s.xp[job.id] or 0)
			local cash = pay(player, JobRules.paycheck(J, job, r, double(player)))
			ctx.note(player, "paychecks", 1)
			push(player, { kind = "paid", cash = cash, title = job.ranks[r], double = double(player) })
			changed = true
		end
	end
	if changed or os.clock() - lv.pushAt > 10 then
		pushState(player)
	end
end

function Jobs.init(c: any)
	ctx = c
	if not (J.On and Config.activeMap() == "Yangon") then
		return -- (the posts, stops and kiosk are Yangon's)
	end
	local store = script.Parent:FindFirstChild("Store")
	if store then
		local ok, m = pcall(require, store)
		if ok and type(m) == "table" and type(m.earnMult) == "function" then
			earnMult = m.earnMult
		end
	end
	Push = ctx.remote("RemoteEvent", "JobPush")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "JobCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		local lv = L(player)
		if not h or os.clock() - lv.lastCall < 0.2 then
			return { ok = false }
		end
		lv.lastCall = os.clock()
		return h(player, arg)
	end
	buildCenter()
	Players.PlayerRemoving:Connect(function(player)
		live[player] = nil
		for _, lv in live do
			lv.tickets[player] = nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tick, player)
				if not ok then
					warn("[CityLegends] Jobs tick:", err)
				end
			end
		end
	end)
end

return Jobs
