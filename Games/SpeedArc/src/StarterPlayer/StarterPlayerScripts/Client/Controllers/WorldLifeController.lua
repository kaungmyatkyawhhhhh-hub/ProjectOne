-- WorldLifeController: cheap life in the hub (GDD 3 "World life").
-- Waving flags (segment chains), the bleacher crowd bobbing and cheering, the race countdown on
-- the arch screen and clock tower. Updates only a short list of parts, only when you are near,
-- with BulkMoveTo, at a fixed low rate (never every part every frame).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Util.Format)
local Palette = require(Shared.Config.Palette)

local camera = workspace.CurrentCamera

local WorldLife = {}

local NEAR = 260 -- studs: farther than this, nothing animates
local RATE = 1 / 30

local flags = {} -- { pivot = CFrame, segs = { {part, offset} } }
local crowd = { parts = {}, base = {}, phase = {}, center = Vector3.zero }
local cheerUntil = 0
local timerLabels = {}
local ring

local function collectFlags(folder)
	for _, flag in folder:GetChildren() do
		local segs = {}
		for _, p in flag:GetChildren() do
			local i = p:GetAttribute("Seg")
			if p:IsA("BasePart") and i then
				segs[i] = p
			end
		end
		local hinge = flag:FindFirstChild("Hinge")
		if hinge and #segs > 0 then
			local entry = { pivot = hinge.CFrame, segs = {}, parts = {}, cfs = {}, phase = math.random() * 6 }
			for i, p in segs do
				entry.segs[i] = { part = p, offset = hinge.CFrame:ToObjectSpace(p.CFrame), width = p.Size.X }
				entry.parts[i] = p
			end
			table.insert(flags, entry)
		end
	end
end

local function collectCrowd(folder)
	local sum = Vector3.zero
	for _, p in folder:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(crowd.parts, p)
			table.insert(crowd.base, p.CFrame)
			-- a fan mesh has its own phase; parts of a part-built fan share their model's
			local model = p.Parent
			local seed = p:GetAttribute("Phase") or (model and model:GetAttribute("Phase")) or math.random() * 6
			table.insert(crowd.phase, seed)
			sum += p.Position
		end
	end
	if #crowd.parts > 0 then
		crowd.center = sum / #crowd.parts
	end
	crowd.cfs = table.create(#crowd.parts)
end

local function stepFlags(t, camPos)
	for _, f in flags do
		if (f.pivot.Position - camPos).Magnitude > NEAR then
			continue
		end
		-- each segment bends a bit more than the one before it: a travelling wave
		local cf = f.pivot
		for i, s in f.segs do
			local angle = math.sin(t * 3.2 - i * 0.75 + f.phase) * 0.22 * (0.5 + i * 0.18)
			-- rotate around the segment's leading edge
			local lead = cf * CFrame.new(0, 0, 0)
			local rotated = lead * CFrame.Angles(0, angle, 0)
			local segCf = rotated * CFrame.new(s.width / 2, s.offset.Position.Y, 0)
			f.cfs[i] = segCf
			cf = rotated * CFrame.new(s.width, 0, 0)
		end
		workspace:BulkMoveTo(f.parts, f.cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function stepCrowd(t, camPos)
	if #crowd.parts == 0 or (crowd.center - camPos).Magnitude > NEAR then
		return
	end
	local cheering = os.clock() < cheerUntil
	local amp = if cheering then 0.9 else 0.18
	local speed = if cheering then 9 else 2.4
	for i, base in crowd.base do
		local ph = crowd.phase[i]
		local y = math.abs(math.sin(t * speed + ph)) * amp
		crowd.cfs[i] = base + Vector3.new(0, y, 0)
	end
	workspace:BulkMoveTo(crowd.parts, crowd.cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

function WorldLife.cheer(seconds)
	cheerUntil = math.max(cheerUntil, os.clock() + (seconds or 3))
end

local function updateTimers(state)
	local phase = state:GetAttribute("Phase")
	local left = (state:GetAttribute("EndsAt") or 0) - workspace:GetServerTimeNow()
	local text, color
	if phase == "Join" then
		text, color = "JOIN NOW  " .. math.max(0, math.ceil(left)), Palette.Gold
	elseif phase == "Countdown" then
		text, color = tostring(math.max(1, math.ceil(left))), Palette.White
	elseif phase == "Running" then
		text, color = "RACE ON", Palette.BrightBlue
	elseif phase == "Results" then
		text, color = "WELL RUN!", Palette.Gold
	else
		text, color = "NEXT RACE  " .. Format.clock(left), Palette.White
	end
	for _, l in timerLabels do
		l.Text = text
		l.TextColor3 = color
	end
	if ring then
		ring.Transparency = if phase == "Join" then 0.15 else 1
	end
end

function WorldLife.start(ctx)
	ctx.WorldLife = WorldLife
	local hub = workspace:WaitForChild("Hub")
	local life = hub:WaitForChild("Life", 10)
	if life then
		local f = life:FindFirstChild("Flags")
		if f then
			collectFlags(f)
		end
		local c = life:FindFirstChild("Crowd")
		if c then
			collectCrowd(c)
		end
	end
	for _, d in hub:GetDescendants() do
		if d:IsA("TextLabel") and d.Name == "RaceTimerText" then
			table.insert(timerLabels, d)
		end
	end
	ring = hub:FindFirstChild("JoinRing", true)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < RATE then
			return
		end
		acc = 0
		local t = os.clock()
		local camPos = camera.CFrame.Position
		stepFlags(t, camPos)
		stepCrowd(t, camPos)
	end)

	local state = ReplicatedStorage:WaitForChild("RaceState")
	state:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = state:GetAttribute("Phase")
		if phase == "Running" then
			WorldLife.cheer(4)
		elseif phase == "Results" then
			WorldLife.cheer(5)
		end
	end)
	task.spawn(function()
		while true do
			updateTimers(state)
			task.wait(0.25)
		end
	end)
end

return WorldLife
