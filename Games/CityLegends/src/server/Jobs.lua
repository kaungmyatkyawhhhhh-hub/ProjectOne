--[[
	Jobs (server; owner approved 18 Nov 2026: "job ranks + paychecks", Southwest Florida style)
	Numbers in Config.Jobs, sums in shared/JobRules.lua, screens in client/JobsClient.lua.
	  * (19 Nov, owner: "like roblox southwest florida") pick or quit a job anywhere, from the main menu's
	    JOBS tab (the Job Center kiosk on Myanmar Plaza's forecourt opens that tab too); the job shows over
	    your head and car ("YBS Bus Driver · R2"); field jobs get a job vehicle (shared/JobsData.lua)
	  * active jobs (delivery, taxi, YBS bus, traffic police): on duty while you do the job; pay per
	    stop / fare / patrol point / ticket, plus a small paycheck every PaycheckSeconds on duty.
	    Delivery is the old dispatch-ring job (Activities.lua calls Jobs.task when one is done)
	  * posts (tea shop, fuel station, dealership, mall shop): AFK jobs: stand at the post; a paycheck every
	    PaycheckSeconds, no daily cap; a "Still on shift?" check every JobsData.ShiftCheck; a serve prompt
	    at the post for tips; auto-rejoin before the 20-minute idle kick (see rejoin below)
	  * 5 ranks per job from job XP (duty minutes + tasks), saved per job in profile.Activities.jobs
	Everything is decided here: the client only asks ("take", "quit", "arrive") and shows.
	Remotes: JobCall (RemoteFunction), JobPush (RemoteEvent: state, paid, task, promoted, open, ticketed).
	Studio test hooks (server player attributes, Studio only): TestDoublePay = true, TestJobXp = n (adds n XP
	to the current job once), TestPaycheckSeconds = n (a shorter paycheck), TestShiftSeconds = n (a shorter shift check),
TestRejoin = true (the idle rejoin without the teleport: saves, builds the teleport data, restores it).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local JobRules = require(Shared:WaitForChild("JobRules"))
local JD = require(Shared:WaitForChild("JobsData"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local J = Config.Jobs
local GOLD = Config.Theme.Accent2

local Jobs = {}

type Task = { kind: string, pos: Vector3, name: string, from: Vector3, t0: number, stop: number? }
type Live = { duty: number, task: Task?, lastTask: number, lastCall: number, tickets: { [Player]: number }, pushAt: number, onDuty: boolean?,
	shift: number, askAt: number?, asleep: boolean?, serveAt: number, vehAt: number, rejoining: boolean? }
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
		s = { duty = 0, task = nil, lastTask = os.clock(), lastCall = 0, tickets = {}, pushAt = 0, shift = 0, serveAt = 0, vehAt = 0 }
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
		st.ask = lv.askAt ~= nil
		st.asleep = lv.asleep == true
		st.vehicle = JD.Vehicles[job.id] ~= nil
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

-- the job vehicle goes when you quit or change job: back into your own car if you were driving it
local function dropJobCar(player: Player, keep: string?)
	local car = ctx.getCar(player)
	local id = car and car:GetAttribute("JobCar")
	if not id or id == keep then
		return
	end
	local profile = PlayerData.get(player) :: any
	local back = profile and (if profile.Owned[profile.Selected] then profile.Selected else next(profile.Owned))
	if back and not player.Character then
		ctx.spawnCar(player, back)
	else
		ctx.despawn(player)
	end
end

handlers.take = function(player, id)
	local s = saved(player)
	local job = JobRules.byId(J, id)
	if not (s and job) then
		return { ok = false }
	end
	-- (19 Nov: from anywhere, like Southwest Florida's team change)
	dropJobCar(player, job.id)
	s.cur = job.id
	local lv = L(player)
	lv.duty, lv.lastTask, lv.shift, lv.askAt, lv.asleep = 0, os.clock(), 0, nil, false
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
	lv.task, lv.duty, lv.onDuty, lv.shift, lv.askAt, lv.asleep = nil, 0, false, 0, nil, false
	dropJobCar(player)
	pushState(player)
	return { ok = true, state = stateOf(player) }
end

handlers.arrive = arrive

-- the job vehicle (field jobs): spawned in front of you, or swapped in where your car is
handlers.vehicle = function(player)
	local s = saved(player)
	local v = s and JD.Vehicles[s.cur]
	local lv = L(player)
	if not v then
		return { ok = false, message = "This job has no vehicle" }
	end
	if os.clock() - lv.vehAt < JD.VehicleCooldown then
		return { ok = false, message = "One moment..." }
	end
	if ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
		return { ok = false, message = "Not while the police want you" }
	end
	lv.vehAt = os.clock()
	-- (stolen: the skips a car that isn't yours gets: no wear, fuel or parts on your save)
	ctx.spawnCar(player, v.car, { stolen = true, job = s.cur, look = v.look })
	return { ok = true }
end

-- a post's serve prompt (tea, a tank, a buyer, a shopper): a tip and XP for the job holder on duty there
local function serve(player: Player, jobId: string)
	local s = saved(player)
	local lv = L(player)
	local job = s and JobRules.byId(J, s.cur)
	if not (job and job.id == jobId and lv.onDuty) then
		push(player, { kind = "toast", text = if job and job.id == jobId then "Stand at your post first" else "Only on this job (JOBS in the menu)" })
		return
	end
	if os.clock() - lv.serveAt < JD.ServeCooldown then
		push(player, { kind = "toast", text = "Next customer in " .. math.ceil(JD.ServeCooldown - (os.clock() - lv.serveAt)) .. " s" })
		return
	end
	lv.serveAt = os.clock()
	local r = JobRules.rank(J, s.xp[job.id] or 0)
	local tip = JD.ServeTip
	local who = "a customer"
	-- the fuel post: a real player's car stopped at the pumps is a customer (double tip, full tank for them)
	if JD.Serve[jobId] and JD.Serve[jobId].car then
		for _, other in Players:GetPlayers() do
			local car = if other ~= player then ctx.getCar(other) else nil
			if car and car.PrimaryPart and flat(car.PrimaryPart.Position, job.post) < JD.ServeCarRange and car.PrimaryPart.AssemblyLinearVelocity.Magnitude < 3 then
				tip *= 2
				who = other.DisplayName
				local c = ctx.care and ctx.care.record(other, car:GetAttribute("CarId"))
				if c then
					c.f = 1
				end
				push(other, { kind = "toast", text = player.DisplayName .. " filled your tank: on the house" })
				break
			end
		end
	end
	local cash = pay(player, math.floor(tip * JobRules.mult(J, r, double(player)) + 0.5))
	addXp(player, s, job, JD.ServeXp)
	ctx.note(player, "jobtasks", 1)
	push(player, { kind = "task", what = string.upper(JD.Serve[jobId].action), name = "Tip from " .. who, cash = cash })
end

local function buildServePrompts()
	for _, job in J.List do
		local sv = JD.Serve[job.id]
		if job.kind == "post" and sv then
			local p = part(workspace, Vector3.new(1, 1, 1), CFrame.new(job.post + Vector3.new(0, 3, 0)), GOLD, Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Name = "JobServe_" .. job.id })
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = sv.action
			prompt.ObjectText = sv.object
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.HoldDuration = 0.6
			prompt.MaxActivationDistance = J.PostRadius
			prompt.RequiresLineOfSight = false
			prompt.Parent = p
			prompt.Triggered:Connect(function(who: Player)
				serve(who, job.id)
			end)
		end
	end
end

---------------------------------------------------------------------
-- Auto-rejoin before Roblox's 20-minute idle kick (owner approved 19 Nov; design of 17 Nov).
-- NOT officially approved by Roblox: watch moderation. Only a player on duty at a post: the client
-- reports Players.LocalPlayer.Idled; the server saves, then teleports to this same server (any
-- server if that fails) with the job in the teleport data; on arrival they stand at their post, on duty.
-- (the car is not brought back: getting into a car takes you off your feet; the garage has it)
---------------------------------------------------------------------
local OnFoot: any = nil

local function restore(player: Player, d: any): boolean
	if type(d) ~= "table" or d.v ~= 1 or type(d.at) ~= "number" or math.abs(os.time() - d.at) > JD.RejoinMaxAge then
		return false
	end
	local s = nil
	local deadline = os.clock() + 30
	repeat
		s = saved(player)
		if not s then
			task.wait(0.5)
		end
	until s or os.clock() > deadline or not player.Parent
	local job = s and JobRules.byId(J, s.cur)
	-- (teleport data passes through the client: only the job already on the save counts)
	if not (job and job.kind == "post" and job.id == d.job) then
		return false
	end
	local lv = L(player)
	lv.shift = math.clamp(tonumber(d.shift) or 0, 0, JD.ShiftCheck)
	lv.duty, lv.askAt, lv.asleep = 0, nil, false
	if OnFoot and OnFoot.standUp then
		OnFoot.standUp(player, CFrame.new(job.post + Vector3.new(0, 3, 0)))
	end
	player:SetAttribute("JobRejoined", true) -- (Main.client: menu shut, on-foot HUD)
	pushState(player)
	return true
end

local function rejoinData(player: Player): any
	local s = saved(player)
	local car = ctx.getCar(player)
	return { v = 1, job = s and s.cur, shift = L(player).shift, at = os.time(), car = car and car:GetAttribute("CarId") }
end

handlers.idle = function(player, seconds)
	local s = saved(player)
	local job = s and JobRules.byId(J, s.cur)
	local lv = L(player)
	local test = RunService:IsStudio() and player:GetAttribute("TestRejoin") == true
	if not test and (type(seconds) ~= "number" or seconds < JD.RejoinIdle) then
		return { ok = false }
	end
	if not (job and job.kind == "post" and lv.onDuty) or lv.rejoining then
		return { ok = false }
	end
	lv.rejoining = true
	PlayerData.save(player)
	local data = rejoinData(player)
	if test then
		player:SetAttribute("TestRejoin", nil)
		lv.rejoining = false
		local ok = restore(player, data) -- (Studio has no TeleportService: the restore path only)
		return { ok = ok, test = true }
	end
	task.spawn(function()
		for try = 1, JD.RejoinTries do
			local ok, err = pcall(function()
				local opts = Instance.new("TeleportOptions")
				if try < JD.RejoinTries then
					opts.ServerInstanceId = game.JobId -- (this same server; the last try: any server)
				end
				opts:SetTeleportData(data)
				TeleportService:TeleportAsync(game.PlaceId, { player }, opts)
			end)
			if ok then
				return
			end
			warn("[CityLegends] Jobs rejoin try " .. try .. " failed:", err)
			task.wait(3)
		end
		lv.rejoining = false
	end)
	return { ok = true }
end

-- "Still on shift?": KEEP WORKING
handlers.keep = function(player)
	local lv = L(player)
	lv.shift, lv.askAt, lv.asleep = 0, nil, false
	pushState(player)
	return { ok = true }
end

---------------------------------------------------------------------
-- The duty clock (once a second): paychecks, duty XP, post caps, police tickets
---------------------------------------------------------------------
local function shiftSeconds(player: Player): number
	local t = if RunService:IsStudio() then player:GetAttribute("TestShiftSeconds") else nil
	return if type(t) == "number" and t >= 5 then t else JD.ShiftCheck
end

-- the job over your head and over your car ("YBS Bus Driver · R2"); nil takes it off
local function tagOn(part: BasePart?, text: string?, hideFrom: Player?, up: number)
	if not part then
		return
	end
	local bb = part:FindFirstChild("JobTag") :: BillboardGui?
	if not text then
		if bb then
			bb:Destroy()
		end
		return
	end
	if not bb then
		local b = Instance.new("BillboardGui")
		b.Name = "JobTag"
		b.Size = UDim2.fromScale(4.2, 0.6)
		b.StudsOffset = Vector3.new(0, up, 0)
		b.MaxDistance = 140
		b.LightInfluence = 0
		b.PlayerToHideFrom = hideFrom
		local l = Instance.new("TextLabel")
		l.Name = "Text"
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.TextColor3 = GOLD
		l.TextStrokeColor3 = Color3.new(0, 0, 0)
		l.TextStrokeTransparency = 0.35
		l.Parent = b
		b.Parent = part
		bb = b
	end
	local l = (bb :: BillboardGui):FindFirstChild("Text") :: TextLabel
	if l.Text ~= text then
		l.Text = text
	end
end

local function tags(player: Player, text: string?)
	player:SetAttribute("JobTag", text)
	local head = player.Character and player.Character:FindFirstChild("Head") :: BasePart?
	tagOn(head, text, nil, 4.7) -- (over the VIP tag at 3.9)
	local car = ctx.getCar(player)
	if car and car.PrimaryPart then
		local h = (car:GetAttribute("Height") :: number?) or 5
		tagOn(car.PrimaryPart, text, player, h * 0.5 + 3) -- (not for the driver: it sits in their view)
	end
end

local function tick(player: Player)
	local s = saved(player)
	local job = s and JobRules.byId(J, s.cur)
	local lv = L(player)
	if not (s and job) then
		lv.onDuty = false
		tags(player, nil)
		return
	end
	tags(player, job.name .. " · R" .. tostring((JobRules.rank(J, s.xp[job.id] or 0))))
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
		-- (19 Nov, owner: AFK posts like Southwest Florida) no daily cap; a soft "Still on shift?" check
		local pos = where(player)
		local atPost = pos ~= nil and flat(pos, job.post) <= J.PostRadius and math.abs(pos.Y - job.post.Y) < 14
		if not atPost then
			lv.shift, lv.askAt, lv.asleep = 0, nil, false -- (walking off and back is not AFK)
		end
		onDuty = atPost and not lv.asleep
		if onDuty then
			lv.shift += 1
			if not lv.askAt and lv.shift >= shiftSeconds(player) then
				lv.askAt = os.clock()
				push(player, { kind = "stillthere", seconds = JD.ShiftAnswer })
				lv.pushAt = 0
			elseif lv.askAt and os.clock() - lv.askAt > JD.ShiftAnswer then
				lv.askAt, lv.asleep, onDuty = nil, true, false
				push(player, { kind = "offshift" })
			end
		end
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
	buildServePrompts()
	OnFoot = require(script.Parent:WaitForChild("OnFoot"))
	-- back from the idle rejoin: at your post, on duty
	local function joined(player: Player)
		local ok, d = pcall(function()
			return player:GetJoinData().TeleportData
		end)
		if ok and d then
			task.spawn(restore, player, d)
		end
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do
		joined(player)
	end
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
