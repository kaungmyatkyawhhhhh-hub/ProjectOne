-- WorldLifeController: cheap life in every area (GDD 3 "World life"). Waving flags (segment chains),
-- crowds that bob and cheer, the race countdown on screens, the JOIN ring. Areas stream in and out,
-- so everything registers itself as it arrives. Only near groups animate, at 30 Hz, with BulkMoveTo.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Util.Format)
local Palette = require(Shared.Config.Palette)
local Areas = require(Shared.Config.Areas)

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local WorldLife = {}

local NEAR = 260
local RATE = 1 / 30

local flags = {} -- [hinge] = entry
local crowds = {} -- [folder] = { parts = {}, base = {}, phase = {}, cfs = {}, center }
local timers = {} -- [label] = areaId
local rings = {} -- [part] = areaId
local cheer = {} -- [areaId] = os.clock() until
local areaOfModel = {}
for _, id in Areas.Order do
	areaOfModel[Areas[id].Model] = id
end

local function areaOf(inst)
	local node = inst
	while node and node.Parent ~= workspace do
		node = node.Parent
	end
	return node and areaOfModel[node.Name]
end

----------------------------------------------------------------------------
-- flags
----------------------------------------------------------------------------
local function addFlag(model)
	local hinge = model:FindFirstChild("Hinge")
	if not hinge or flags[hinge] then
		return
	end
	local segs = {}
	for _, p in model:GetChildren() do
		local i = p:GetAttribute("Seg")
		if p:IsA("BasePart") and i then
			segs[i] = p
		end
	end
	if #segs == 0 then
		return
	end
	local e = { hinge = hinge, pivot = hinge.CFrame, segs = {}, parts = {}, cfs = {}, phase = math.random() * 6 }
	for i, p in segs do
		e.segs[i] = { part = p, offset = hinge.CFrame:ToObjectSpace(p.CFrame), width = p.Size.X }
		e.parts[i] = p
	end
	flags[hinge] = e
end

local function stepFlags(t, camPos)
	for hinge, f in flags do
		if not hinge.Parent then
			flags[hinge] = nil
			continue
		end
		if (f.pivot.Position - camPos).Magnitude > NEAR then
			continue
		end
		local cf = f.pivot
		local ok = true
		for i, s in f.segs do
			if not s.part.Parent then
				ok = false
				break
			end
			local angle = math.sin(t * 3.2 - i * 0.75 + f.phase) * 0.22 * (0.5 + i * 0.18)
			local rotated = cf * CFrame.Angles(0, angle, 0)
			f.cfs[i] = rotated * CFrame.new(s.width / 2, s.offset.Position.Y, 0)
			cf = rotated * CFrame.new(s.width, 0, 0)
		end
		if ok then
			workspace:BulkMoveTo(f.parts, f.cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
end

----------------------------------------------------------------------------
-- crowds (each "Crowd" folder is a group)
----------------------------------------------------------------------------
local function addFan(folder, p)
	local g = crowds[folder]
	if not g then
		g = { parts = {}, base = {}, phase = {}, cfs = {}, sum = Vector3.zero, area = areaOf(folder) }
		crowds[folder] = g
	end
	table.insert(g.parts, p)
	table.insert(g.base, p.CFrame)
	local model = p.Parent
	table.insert(g.phase, p:GetAttribute("Phase") or (model and model:GetAttribute("Phase")) or math.random() * 6)
	g.sum += p.Position
	g.center = g.sum / #g.parts
end

local function removeFan(folder, p)
	local g = crowds[folder]
	if not g then
		return
	end
	local i = table.find(g.parts, p)
	if i then
		table.remove(g.parts, i)
		table.remove(g.base, i)
		table.remove(g.phase, i)
		g.cfs = {}
	end
end

local function stepCrowds(t, camPos)
	for _, g in crowds do
		if #g.parts == 0 or not g.center or (g.center - camPos).Magnitude > NEAR then
			continue
		end
		local cheering = os.clock() < (cheer[g.area or "Hub"] or 0)
		local amp = if cheering then 0.9 else 0.18
		local speed = if cheering then 9 else 2.4
		for i, base in g.base do
			g.cfs[i] = base + Vector3.new(0, math.abs(math.sin(t * speed + g.phase[i])) * amp, 0)
		end
		workspace:BulkMoveTo(g.parts, g.cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function WorldLife.cheer(seconds, areaId)
	areaId = areaId or player:GetAttribute("Area") or "Hub"
	cheer[areaId] = math.max(cheer[areaId] or 0, os.clock() + (seconds or 3))
end

----------------------------------------------------------------------------
-- registration as things stream in
----------------------------------------------------------------------------
local function consider(d)
	if d:IsA("TextLabel") and d.Name == "RaceTimerText" then
		timers[d] = areaOf(d) or "Hub"
	elseif d:IsA("BasePart") then
		if d.Name == "JoinRing" then
			rings[d] = areaOf(d) or "Hub"
		elseif d.Name == "Hinge" and d.Parent and d.Parent.Name == "Flag" then
			task.defer(addFlag, d.Parent)
		elseif d:GetAttribute("Seg") and d.Parent and d.Parent:FindFirstChild("Hinge") then
			task.defer(addFlag, d.Parent)
		else
			local folder = d:FindFirstAncestor("Crowd")
			if folder and folder:IsA("Folder") then
				addFan(folder, d)
			end
		end
	end
end

local function forget(d)
	timers[d] = nil
	rings[d] = nil
	if d:IsA("BasePart") then
		local folder = d:FindFirstAncestor("Crowd")
		if folder then
			removeFan(folder, d)
		end
	end
end

local function updateTimers()
	local root = ReplicatedStorage:FindFirstChild("RaceState")
	if not root then
		return
	end
	for label, areaId in timers do
		if not label.Parent then
			timers[label] = nil
			continue
		end
		local state = root:FindFirstChild(areaId)
		if state then
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
			label.Text = text
			label.TextColor3 = color
		end
	end
	for ring, areaId in rings do
		local state = root:FindFirstChild(areaId)
		if ring.Parent and state then
			ring.Transparency = if state:GetAttribute("Phase") == "Join" then 0.15 else 1
		end
	end
end

function WorldLife.start(ctx)
	ctx.WorldLife = WorldLife
	for _, d in workspace:GetDescendants() do
		consider(d)
	end
	workspace.DescendantAdded:Connect(consider)
	workspace.DescendantRemoving:Connect(forget)

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
		stepCrowds(t, camPos)
	end)

	local root = ReplicatedStorage:WaitForChild("RaceState")
	local function hook(state)
		state:GetAttributeChangedSignal("Phase"):Connect(function()
			local phase = state:GetAttribute("Phase")
			if phase == "Running" then
				WorldLife.cheer(4, state.Name)
			elseif phase == "Results" then
				WorldLife.cheer(5, state.Name)
			end
		end)
	end
	for _, s in root:GetChildren() do
		hook(s)
	end
	root.ChildAdded:Connect(hook)
	task.spawn(function()
		while true do
			updateTimers()
			task.wait(0.25)
		end
	end)
end

return WorldLife
