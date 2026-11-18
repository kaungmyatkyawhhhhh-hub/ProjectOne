--[[
	MallMovers (server, 2026-11-19, owner: "make the escalators & elevators work when there is a player on it. also the
	one from underground parking elevator too"). One script runs every tagged mover:

	  * Escalators: invisible ramp collision boxes tagged "MallEscalator" (attributes Up = true / false, Speed studs/s).
	    While a player is near, the anchored ramp gets AssemblyLinearVelocity along its slope (the conveyor trick), so
	    whoever stands on it rides up or down at a real escalator pace and can still walk. The visual steps stay put;
	    the landing boxes have no velocity, so nothing is flung at the ends.
	  * Lifts: Models tagged "MallLift" (built by tools/yangon/MCLift.luau):
	      Car (Model, PrimaryPart "Floor"; car doors "CarDoorL" / "CarDoorR"), Stops (Parts "Stop<i>" at each floor's
	      level with attribute Label), landing doors "DoorL<i>" / "DoorR<i>", call panels "Call<i>" (a "Call lift"
	      ProximityPrompt). The car is anchored and moved here; while it moves its floor carries the velocity, so riders
	      move with it (and are snapped back onto the floor if they drift). Doors close before every move; one car per
	      shaft with a simple queue. Riders pick a floor on the MallLift client panel (RemoteEvent MallLiftCall).
	Idle when nobody is near: the escalator loop only touches ramps with a player within 160 studs; lifts run on calls.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ESC_NEAR = 160
local LIFT_SPEED = 9 -- studs/s (about 3 m/s)
local DOOR_TIME = 0.9
local DWELL = 3.5

local function playersNear(pos: Vector3, r: number): boolean
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - pos).Magnitude < r then
			return true
		end
	end
	return false
end

-- escalators ---------------------------------------------------------------------------------------------------
task.spawn(function()
	while true do
		for _, ramp in CollectionService:GetTagged("MallEscalator") do
			if ramp:IsA("BasePart") and ramp:IsDescendantOf(workspace) then
				local v = Vector3.zero
				if playersNear(ramp.Position, ESC_NEAR) then
					local dir = ramp:GetAttribute("Up") == false and -1 or 1
					v = ramp.CFrame.RightVector * (ramp:GetAttribute("Speed") or 2) * dir
				end
				if (ramp.AssemblyLinearVelocity - v).Magnitude > 1e-3 then
					ramp.AssemblyLinearVelocity = v
				end
			end
		end
		task.wait(1)
	end
end)

-- lifts --------------------------------------------------------------------------------------------------------
local call = ReplicatedStorage:FindFirstChild("MallLiftCall") or Instance.new("RemoteEvent")
call.Name = "MallLiftCall"
call.Parent = ReplicatedStorage

local lifts: { [Model]: any } = {}

local function slide(parts: { BasePart }, offsets: { Vector3 }, open: boolean)
	local tw
	for i, p in parts do
		local closed = p:GetAttribute("ClosedCF") :: CFrame
		local goal = open and (closed + offsets[i]) or closed
		tw = TweenService:Create(p, TweenInfo.new(DOOR_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = goal })
		tw:Play()
	end
	if tw then
		tw.Completed:Wait()
	end
end

local function insideCar(L, root: BasePart): boolean
	local f = L.floor :: BasePart
	local rel = f.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) < f.Size.X / 2 and math.abs(rel.Z) < f.Size.Z / 2 and rel.Y > -1 and rel.Y < L.carH
end

local function doors(L, i: number, open: boolean)
	local ld = L.landing[i]
	local w = L.doorW
	local carDoors = { L.carL, L.carR }
	local carCF = L.car:GetPivot()
	for _, d in carDoors do
		d:SetAttribute("ClosedCF", carCF * (d:GetAttribute("LocalCF") :: CFrame))
	end
	local ax = L.floor.CFrame.RightVector
	task.spawn(slide, carDoors, { -ax * w, ax * w }, open)
	if ld then
		slide({ ld.l, ld.r }, { -ax * w, ax * w }, open)
	end
	L.open = open
end

local function moveCar(L, i: number)
	local target = L.stops[i].y
	local car = L.car :: Model
	local start = car:GetPivot()
	local y0 = start.Position.Y
	local dist = target - y0
	if math.abs(dist) < 0.01 then
		return
	end
	local dur = math.abs(dist) / LIFT_SPEED
	local t = 0
	local floorOff = L.floor.Position.Y - y0
	while t < dur do
		local dt = RunService.Heartbeat:Wait()
		t = math.min(dur, t + dt)
		-- ease in / out over the first / last half second
		local k = t / dur
		local e = k * k * (3 - 2 * k)
		local y = y0 + dist * e
		local vel = dist / dur * 6 * k * (1 - k) -- d(y)/dt of the smoothstep
		car:PivotTo(start + Vector3.new(0, y - y0, 0))
		L.floor.AssemblyLinearVelocity = Vector3.new(0, vel, 0)
		-- riders: keep each standing on the floor (no falling through, no jitter on a fast start)
		local fy = y + floorOff + L.floor.Size.Y / 2
		for _, p in Players:GetPlayers() do
			local c = p.Character
			local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if root and hum and insideCar(L, root) then
				local want = fy + hum.HipHeight + root.Size.Y / 2
				if root.Position.Y < want - 0.4 or root.Position.Y > want + 1.5 then
					root.CFrame = root.CFrame + Vector3.new(0, want - root.Position.Y, 0)
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, vel, root.AssemblyLinearVelocity.Z)
				end
			end
		end
	end
	L.floor.AssemblyLinearVelocity = Vector3.zero
	L.at = i
end

local function run(L)
	if L.busy then
		return
	end
	L.busy = true
	while #L.queue > 0 do
		local i = L.queue[1]
		if L.at ~= i then
			if L.open then
				doors(L, L.at, false)
			end
			moveCar(L, i)
		end
		table.remove(L.queue, 1)
		doors(L, i, true)
		L.model:SetAttribute("At", i)
		local t0 = os.clock()
		while os.clock() - t0 < DWELL and #L.queue == 0 do
			task.wait(0.25)
		end
	end
	-- park with the doors open at the last floor, closed after a while with nobody about
	task.delay(8, function()
		if not L.busy and L.open and #L.queue == 0 and not playersNear(L.floor.Position, 20) then
			doors(L, L.at, false)
		end
	end)
	L.busy = false
end

local function request(L, i: number)
	if not L.stops[i] then
		return
	end
	if L.at == i and L.open and not L.busy then
		return
	end
	if not table.find(L.queue, i) then
		table.insert(L.queue, i)
	end
	task.spawn(run, L)
end

local function setup(model: Model)
	if lifts[model] then
		return
	end
	local car = model:WaitForChild("Car", 10) :: Model
	local stopsF = model:WaitForChild("Stops", 10)
	if not car or not stopsF then
		warn("MallMovers: lift without Car / Stops", model:GetFullName())
		return
	end
	local L = {
		model = model,
		car = car,
		floor = car.PrimaryPart or car:FindFirstChild("Floor"),
		carL = car:FindFirstChild("CarDoorL"),
		carR = car:FindFirstChild("CarDoorR"),
		carH = model:GetAttribute("CarHeight") or 8,
		doorW = model:GetAttribute("DoorSlide") or 2.2,
		stops = {},
		landing = {},
		queue = {},
		at = model:GetAttribute("At") or 1,
		open = false,
		busy = false,
	}
	local carCF = car:GetPivot()
	for _, d in { L.carL, L.carR } do
		d:SetAttribute("LocalCF", carCF:ToObjectSpace(d.CFrame))
	end
	local n = 0
	for _, s in stopsF:GetChildren() do
		local i = tonumber(s.Name:match("^Stop(%d+)$"))
		if i then
			L.stops[i] = { y = s.Position.Y, label = s:GetAttribute("Label") or tostring(i) }
			n = math.max(n, i)
			local l, r = model:FindFirstChild("DoorL" .. i), model:FindFirstChild("DoorR" .. i)
			if l and r then
				l:SetAttribute("ClosedCF", l.CFrame)
				r:SetAttribute("ClosedCF", r.CFrame)
				L.landing[i] = { l = l, r = r }
			end
			local panel = model:FindFirstChild("Call" .. i)
			local prompt = panel and panel:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Triggered:Connect(function()
					request(L, i)
				end)
			end
		end
	end
	-- park the car exactly at its stop (the builder leaves it there)
	local i0 = L.at
	if L.stops[i0] then
		car:PivotTo(carCF + Vector3.new(0, L.stops[i0].y - carCF.Position.Y, 0))
	end
	lifts[model] = L
end

call.OnServerEvent:Connect(function(player: Player, model: any, i: any)
	local L = typeof(model) == "Instance" and lifts[model]
	if not L or typeof(i) ~= "number" or i ~= math.floor(i) then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not insideCar(L, root) then
		return
	end
	request(L, i)
end)

for _, m in CollectionService:GetTagged("MallLift") do
	task.spawn(setup, m)
end
CollectionService:GetInstanceAddedSignal("MallLift"):Connect(function(m)
	task.spawn(setup, m)
end)
