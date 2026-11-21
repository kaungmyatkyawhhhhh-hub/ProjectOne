--[[
	YangonSignals (client): traffic light poles at the 1:1 Yangon's signalled junctions (owner, 2026-11-21: "put
	traffic lights too"). The junctions and their phases come from RivieraTraffic.build().signals (the same lane
	pieces Traffic / Chauffeur / Police stop at), so the poles and the cars agree. Each approach (one junction, one
	heading) gets a mast pole on its right-hand pavement with an arm over its lanes and one head facing the cars, in
	the old city's look. The lenses carry the old city's tag and attributes (TrafficLamp, I / J / Axis / State), so
	WorldFx lights them on the shared clock. Built only within LOAD studs of the camera, taken down past DROP.

	YangonSignals.start()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))

local YangonSignals = {}

local LOAD, DROP = 650, 850
local METAL = Color3.fromRGB(46, 50, 56)
local BORDER = Color3.fromRGB(214, 168, 30)
local LENS_OFF = { R = Color3.fromRGB(52, 8, 8), Y = Color3.fromRGB(56, 38, 4), G = Color3.fromRGB(6, 40, 22) }
local POLE_H = 19
local SIDE = 9 -- studs from the outer lane's middle to the pole (the pavement)

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

-- one head: housing, yellow-bordered backplate, three lenses (R, Y, G) under visors, facing -look
local function head(parent: Instance, cf: CFrame, i: number, axis: string)
	part(parent, Vector3.new(2.9, 6.1, 0.06), cf * CFrame.new(0, 0, 0.68), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
	part(parent, Vector3.new(2.9, 6.1, 0.06), cf * CFrame.new(0, 0, 0.62), BORDER, Enum.Material.SmoothPlastic)
	part(parent, Vector3.new(2.55, 5.75, 0.06), cf * CFrame.new(0, 0, 0.57), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
	part(parent, Vector3.new(1.7, 5.1, 1.1), cf, Color3.fromRGB(22, 23, 26), Enum.Material.Metal)
	for idx, state in { "R", "Y", "G" } do
		local y = (2 - idx) * 1.6
		local lamp = part(parent, Vector3.new(0.25, 1.2, 1.2), cf * CFrame.new(0, y, -0.58) * CFrame.Angles(0, math.pi / 2, 0), LENS_OFF[state], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		lamp.Name = "Lamp"
		lamp:SetAttribute("I", i)
		lamp:SetAttribute("J", 0)
		lamp:SetAttribute("Axis", axis)
		lamp:SetAttribute("State", state)
		CollectionService:AddTag(lamp, "TrafficLamp")
		part(parent, Vector3.new(1.45, 0.08, 0.9), cf * CFrame.new(0, y + 0.7, -1.0), Color3.fromRGB(14, 14, 16), Enum.Material.SmoothPlastic)
	end
end

-- the approaches: one per junction and heading (30-degree buckets), with its lanes' stop points
local function approaches(signals): { any }
	local byKey, list = {}, {}
	for _, s in signals do
		local ang = math.atan2(s.dir.X, s.dir.Z)
		local key = s.i .. ":" .. (math.floor((ang + math.pi) / (math.pi / 6) + 0.5) % 12)
		local a = byKey[key]
		if not a then
			a = { i = s.i, axis = s.axis, dir = s.dir, pts = {}, center = s.center }
			byKey[key] = a
			table.insert(list, a)
		end
		table.insert(a.pts, s.pos)
	end
	for _, a in list do
		local right = a.dir:Cross(Vector3.yAxis)
		local outer, inner = a.pts[1], a.pts[1]
		for _, p in a.pts do
			if p:Dot(right) > outer:Dot(right) then
				outer = p
			end
			if p:Dot(right) < inner:Dot(right) then
				inner = p
			end
		end
		a.right = right
		a.outer = outer
		a.inner = inner
		a.mid = (outer + inner) / 2
	end
	return list
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function build(a, folder: Instance): Model
	local m = Instance.new("Model")
	m.Name = "YangonSignal"
	local base = a.outer + a.right * SIDE + a.dir * 4
	-- stand on the pavement (the map's collision), else just above the road
	local root = Config.mapRoot and Config.mapRoot()
	local y = a.outer.Y + 0.6
	if root then
		rayParams.FilterDescendantsInstances = { root }
		local hit = workspace:Raycast(base + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), rayParams)
		if hit then
			y = hit.Position.Y
		end
	end
	base = Vector3.new(base.X, y, base.Z)
	part(m, Vector3.new(2.4, 1.2, 2.4), CFrame.new(base + Vector3.new(0, 0.6, 0)), Color3.fromRGB(70, 72, 76), Enum.Material.Concrete)
	part(m, Vector3.new(POLE_H, 1.05, 1.05), CFrame.new(base + Vector3.new(0, POLE_H / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, Vector3.new(1.3, 0.5, 1.3), CFrame.new(base + Vector3.new(0, POLE_H + 0.25, 0)), METAL, Enum.Material.Metal)
	-- the arm out over the lanes, to the middle of the approach
	local armStart = base + Vector3.new(0, POLE_H - 2, 0)
	local reach = math.clamp((base - a.mid):Dot(a.right), 6, 40)
	local armEnd = armStart - a.right * reach
	part(m, Vector3.new(0.7, 0.7, reach), CFrame.lookAt((armStart + armEnd) / 2, armEnd), METAL, Enum.Material.Metal)
	local bA, bB = base + Vector3.new(0, POLE_H - 6, 0), armStart - a.right * math.min(8, reach)
	part(m, Vector3.new(0.35, 0.35, (bB - bA).Magnitude), CFrame.lookAt((bA + bB) / 2, bB), METAL, Enum.Material.Metal)
	local hp = armEnd - Vector3.new(0, 3.4, 0)
	part(m, Vector3.new(0.25, 0.9, 0.25), CFrame.new(hp + Vector3.new(0, 3, 0)), METAL, Enum.Material.Metal)
	head(m, CFrame.lookAt(hp, hp - a.dir), a.i, a.axis)
	-- a lower head on the pole for the cars at the front of the queue
	local lp = base + Vector3.new(0, 9, 0) - a.right * 1.2
	head(m, CFrame.lookAt(lp, lp - a.dir), a.i, a.axis)
	m.Parent = folder
	return m
end

local started = false
function YangonSignals.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local g
		for _ = 1, 60 do
			g = RivieraTraffic.build()
			if g then
				break
			end
			task.wait(2)
		end
		if not g or not g.signals or #g.signals == 0 then
			return
		end
		local list = approaches(g.signals)
		local folder = Instance.new("Folder")
		folder.Name = "YangonSignals"
		folder.Parent = workspace
		local built: { [any]: Model } = {}
		while true do
			local cam = workspace.CurrentCamera
			local at = if cam then cam.CFrame.Position else Vector3.zero
			local made = 0
			for _, a in list do
				local d = Vector3.new(a.mid.X - at.X, 0, a.mid.Z - at.Z).Magnitude
				if d < LOAD and not built[a] and made < 12 then
					built[a] = build(a, folder)
					made += 1
				elseif d > DROP and built[a] then
					built[a]:Destroy()
					built[a] = nil
				end
			end
			task.wait(if made >= 12 then 0.1 else 1)
		end
	end)
end

return YangonSignals
