--[[
	Traffic overlap test (27 Nov 2026; vault "City Legends/2026-11-27 Traffic - real car motion, no overlaps.md").
	Paste into execute_luau on the CLIENT in Play. It counts, every frame for `SECONDS`, the traffic cars whose boxes
	(workspace.Traffic.*.Chassis, shrunk 0.2 studs a side so touching is not overlapping) overlap another traffic car or
	a player's car, flat (2D boxes) and within 6 studs of height. Results go on workspace attributes (the test runs in
	the background): OverlapDone, OverlapNpc (pair-starts NPC x NPC), OverlapPlayer (NPC x player car), OverlapFrames
	(frames with any NPC x NPC overlap), OverlapNear (pair-starts within 300 studs of the camera), OverlapLog (the first
	12 spots), OverlapCars (cars per frame on average).
	The goal is OverlapNpc = 0.
]]
local SECONDS = 60
local SHRINK = 0.2
local RunService = game:GetService("RunService")

local function box(m: Model): (CFrame?, Vector3?)
	local c = m.PrimaryPart
	if not c then
		return nil, nil
	end
	return c.CFrame, c.Size
end

local function hit(a: CFrame, sa: Vector3, b: CFrame, sb: Vector3): boolean
	if math.abs(a.Position.Y - b.Position.Y) > 6 then
		return false
	end
	local fa, ra = a.LookVector * Vector3.new(1, 0, 1), a.RightVector * Vector3.new(1, 0, 1)
	local fb, rb = b.LookVector * Vector3.new(1, 0, 1), b.RightVector * Vector3.new(1, 0, 1)
	fa, ra, fb, rb = fa.Unit, ra.Unit, fb.Unit, rb.Unit
	local ha, wa = sa.Z / 2 - SHRINK, sa.X / 2 - SHRINK
	local hb, wb = sb.Z / 2 - SHRINK, sb.X / 2 - SHRINK
	local d = (b.Position - a.Position) * Vector3.new(1, 0, 1)
	for _, ax in { fa, ra, fb, rb } do
		local pa = ha * math.abs(fa:Dot(ax)) + wa * math.abs(ra:Dot(ax))
		local pb = hb * math.abs(fb:Dot(ax)) + wb * math.abs(rb:Dot(ax))
		if math.abs(d:Dot(ax)) > pa + pb then
			return false
		end
	end
	return true
end

workspace:SetAttribute("OverlapDone", false)
task.spawn(function()
	local t0 = os.clock()
	local live: { [string]: boolean } = {}
	local npcN, plN, frames, near, cars, n = 0, 0, 0, 0, 0, 0
	local log = {}
	local ids: { [Model]: number } = {}
	local nextId = 0
	local function idOf(m: Model): number
		if not ids[m] then
			nextId += 1
			ids[m] = nextId
		end
		return ids[m]
	end
	while os.clock() - t0 < SECONDS do
		RunService.Heartbeat:Wait()
		local f = workspace:FindFirstChild("Traffic")
		local list = {}
		if f then
			for _, m in f:GetChildren() do
				if m:IsA("Model") then
					local cf, sz = box(m)
					if cf then
						table.insert(list, { m = m, cf = cf, sz = sz })
					end
				end
			end
		end
		local players = {}
		local pf = workspace:FindFirstChild("PlayerCars")
		if pf then
			for _, m in pf:GetChildren() do
				if m:IsA("Model") and m.PrimaryPart then
					local cf, sz = m:GetBoundingBox()
					table.insert(players, { m = m, cf = cf, sz = sz })
				end
			end
		end
		cars += #list
		n += 1
		local cam = workspace.CurrentCamera.CFrame.Position
		local now: { [string]: boolean } = {}
		local any = false
		for i = 1, #list do
			local a = list[i]
			for j = i + 1, #list do
				local b = list[j]
				if (a.cf.Position - b.cf.Position).Magnitude < 50 and hit(a.cf, a.sz, b.cf, b.sz) then
					any = true
					local k = idOf(a.m) .. "-" .. idOf(b.m)
					now[k] = true
					if not live[k] then
						npcN += 1
						if (a.cf.Position - cam).Magnitude < 300 then
							near += 1
						end
						if #log < 12 then
							local p = a.cf.Position
							table.insert(log, string.format("%s|%s@%d,%d,%d", a.m.Name, b.m.Name, p.X, p.Y, p.Z))
						end
					end
				end
			end
			for _, pc in players do
				if (a.cf.Position - pc.cf.Position).Magnitude < 50 and hit(a.cf, a.sz, pc.cf, pc.sz) then
					local k = "p" .. idOf(a.m) .. "-" .. idOf(pc.m)
					now[k] = true
					if not live[k] then
						plN += 1
					end
				end
			end
		end
		if any then
			frames += 1
		end
		live = now
	end
	workspace:SetAttribute("OverlapNpc", npcN)
	workspace:SetAttribute("OverlapPlayer", plN)
	workspace:SetAttribute("OverlapFrames", frames)
	workspace:SetAttribute("OverlapNear", near)
	workspace:SetAttribute("OverlapCars", math.floor(cars / math.max(n, 1)))
	workspace:SetAttribute("OverlapFramesTotal", n)
	workspace:SetAttribute("OverlapLog", table.concat(log, ";"))
	workspace:SetAttribute("OverlapDone", true)
end)
return "started"
