--[[
	TrafficBodies (client)
	Traffic cars from ReplicatedStorage.TrafficModels (owner, 2026-11-01: the "Low Poly cars pack"
	by matisosanimation, CC BY 4.0, split by tools/split_cars.py and brought in with Import 3D).
	Each model is Traffic_<type><n>: a Body plus FL / FR / RL / RR wheels (a part or a model each),
	facing -Z. The first time a model is used it is scaled to its real length
	(Config.Traffic.ModelLengths, by type letter) and given what Traffic expects: an anchored
	"Chassis" root (the hitbox), Wheel_* Motor6Ds on the root, brake lights tagged TailLight, and
	Length / Width / Height attributes. Every car after that is a clone of the ready one.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local TrafficBodies = {}

local BRAKE_OFF = Color3.fromRGB(150, 0, 6)
local WHEELS = { "FL", "FR", "RL", "RR" }

local ready: { [Model]: Model } = {}

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild("TrafficModels")
end

local function templates(): { Model }
	local out = {}
	local f = folder()
	if f then
		for _, m in f:GetChildren() do
			if m:IsA("Model") and m:FindFirstChild("Body", true) then
				table.insert(out, m)
			end
		end
	end
	return out
end

function TrafficBodies.available(): boolean
	return #templates() > 0
end

local function partsOf(inst: Instance): { BasePart }
	local out = {}
	if inst:IsA("BasePart") then
		table.insert(out, inst)
	end
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(out, d)
		end
	end
	return out
end

local function centreOf(parts: { BasePart }): Vector3
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in parts do
		local h = p.Size / 2
		for _, c in { Vector3.new(-1, -1, -1), Vector3.new(1, 1, 1) } do
			local w = p.CFrame:PointToWorldSpace(h * c)
			lo, hi = lo:Min(w), hi:Max(w)
		end
	end
	return (lo + hi) / 2
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function prepare(template: Model): Model
	local m = template:Clone()
	m:PivotTo(CFrame.new())
	local kind = string.match(m.Name, "_(%a)") or "A"
	local target = Config.Traffic.ModelLengths[kind] or 13
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * target / math.max(size.Z, 0.1))
	local cf, box = m:GetBoundingBox()
	cf = CFrame.new(cf.Position) -- square to the car: front -Z, right +X

	local root = Instance.new("Part")
	root.Name = "Chassis"
	root.Size = Vector3.new(box.X - 0.1, box.Y - 0.05, box.Z - 0.1)
	root.CFrame = cf
	root.Transparency = 1
	root.CanCollide = true
	root.CanQuery = true
	root.CanTouch = true
	root.Anchored = true
	root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0, 100, 1)
	root.Parent = m
	m.PrimaryPart = root

	local wheelParts: { [BasePart]: boolean } = {}
	for _, name in WHEELS do
		local w = m:FindFirstChild(name, true)
		local parts = if w then partsOf(w) else {}
		if #parts > 0 then
			local main = parts[1]
			for i = 2, #parts do
				weld(main, parts[i])
			end
			local hub = CFrame.new(centreOf(parts)) * cf.Rotation
			local motor = Instance.new("Motor6D")
			motor.Name = "Wheel_" .. name
			motor.Part0 = root
			motor.Part1 = main
			motor.C0 = cf:ToObjectSpace(hub)
			motor.C1 = main.CFrame:ToObjectSpace(hub)
			motor.Parent = root
			for _, p in parts do
				wheelParts[p] = true
			end
		end
	end
	for _, p in partsOf(m) do
		if p ~= root then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			if not wheelParts[p] then
				weld(root, p)
			end
		end
	end
	-- brake lights: two thin strips on the tail (the painted lamps stay as they are)
	for _, side in { -1, 1 } do
		local t = Instance.new("Part")
		t.Name = "TailLight"
		t.Size = Vector3.new(box.X * 0.2, box.Y * 0.07, 0.08)
		t.CFrame = cf * CFrame.new(side * box.X * 0.33, -box.Y * 0.05, box.Z / 2 - 0.25)
		t.Material = Enum.Material.Neon
		t.Color = BRAKE_OFF
		t.CanCollide = false
		t.CanQuery = false
		t.CanTouch = false
		t.CastShadow = false
		t.Massless = true
		t:SetAttribute("TailLight", true)
		t.Parent = m
		weld(root, t)
	end
	m:SetAttribute("Length", box.Z)
	m:SetAttribute("Width", box.X)
	m:SetAttribute("Height", box.Y)
	m:SetAttribute("TrafficBody", m.Name)
	return m
end

-- a new traffic car (nil when there are no TrafficModels)
function TrafficBodies.build(rng: Random): Model?
	local list = templates()
	if #list == 0 then
		return nil
	end
	local template = list[rng:NextInteger(1, #list)]
	local done = ready[template]
	if not done then
		local ok, result = pcall(prepare, template)
		if not ok then
			warn("[CityLegends] Traffic model " .. template.Name .. " failed:", result)
			return nil
		end
		done = result
		ready[template] = done
	end
	return done:Clone()
end

return TrafficBodies
