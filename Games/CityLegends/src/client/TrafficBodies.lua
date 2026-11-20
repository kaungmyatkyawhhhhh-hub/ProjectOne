--[[
	TrafficBodies (client)
	Traffic cars from ReplicatedStorage.TrafficModels (owner, 2026-11-01: the "Low Poly cars pack"
	by matisosanimation, CC BY 4.0, split by tools/split_cars.py and brought in with Import 3D).
	Each model is Traffic_<type><n>: a Body plus FL / FR / RL / RR wheels. Import 3D renames them
	"Body2_Node", "FL2_Node" ... (a model of mesh parts each) and turns the car round: its front is
	+Z, its left +X. The first time a model is used it is scaled to its real length
	(Config.Traffic.ModelLengths, by type letter) and given what Traffic expects: an anchored
	"Chassis" root (the hitbox), Wheel_* Motor6Ds on the root (no lights: owner 2026-11-02), and
	Length / Width / Height attributes. Every car after that is a clone of the ready one.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TrafficMix = require(Shared:WaitForChild("TrafficMix"))
local Plates = require(Shared:WaitForChild("Plates"))

local TrafficBodies = {}

local WHEELS = { "FL", "FR", "RL", "RR" }
local UNTEXTURED = Color3.fromRGB(26, 26, 28)

local ready: { [Model]: Model } = {}

-- "FL2_Node" -> "FL", "Body29" -> "Body"
local function key(name: string): string
	return string.match(name, "^(%a+)%d*_Node$") or string.match(name, "^(%a+)%d*$") or name
end

local function partOf(m: Instance, k: string): Instance?
	for _, c in m:GetChildren() do
		if key(c.Name) == k then
			return c
		end
	end
	return nil
end

local function folder(): Instance?
	return ReplicatedStorage:FindFirstChild("TrafficModels")
end

local function templates(): { Model }
	local out = {}
	local f = folder()
	if f then
		for _, m in f:GetChildren() do
			-- (20 Nov 2026) no copies of put-away old-model cars: TrafficMix.spawns (moving and parked cars)
			if m:IsA("Model") and partOf(m, "Body") and TrafficMix.spawns(m.Name) then
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

-- (2026-11-19) a rear Myanmar plate (real 358 x 162 mm at 3 studs a metre) where a ray from behind first
-- meets the body at bumper height; the model is parented for a moment so the ray can see it (nil: no hit)
local function rearPlate(m: Model, cf: CFrame, box: Vector3): Part?
	local away = Vector3.new(0, 20000, 0)
	m:PivotTo(CFrame.new(away))
	m.Parent = workspace
	-- (the templates' parts have CanQuery off, and helper boxes are plain Parts: rays see only the meshes)
	local meshes = {}
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") then
			d.CanQuery = true
			table.insert(meshes, d)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = meshes
	local hit: RaycastResult? = nil
	for _, k in { 0.3, 0.36, 0.24, 0.42 } do
		local from = cf.Position + away + Vector3.new(0, -box.Y / 2 + box.Y * k, -box.Z / 2 - 4)
		local r = workspace:Raycast(from, Vector3.new(0, 0, box.Z), params)
		if r and r.Normal.Z < -0.6 then
			hit = r
			break
		end
	end
	m.Parent = nil
	m:PivotTo(CFrame.new())
	if not hit then
		return nil
	end
	local pos = hit.Position - away + Vector3.new(0, 0, -0.06)
	local plate = Instance.new("Part")
	plate.Name = "PlateText"
	plate.Size = Vector3.new(1.07, 0.49, 0.02)
	plate.Transparency = 1
	plate.CFrame = CFrame.lookAt(pos, pos - Vector3.zAxis) -- (its front face looks back out of the car)
	plate.Parent = m
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(220, 100)
	sg.LightInfluence = 1
	sg.MaxDistance = 70
	sg.Parent = plate
	return plate
end

local function prepare(template: Model): Model
	local m = template:Clone()
	m:PivotTo(CFrame.new())
	local kind = string.match(m.Name, "_(%a)") or "A"
	-- (2026-11-19) the Yangon set: each car at its own real length (TrafficMix), the old pack by type letter
	local entry = TrafficMix.byName[template.Name]
	local target = if entry then entry.len else Config.Traffic.ModelLengths[kind] or 13
	local keepColors = template:GetAttribute("KeepColors") == true
	local _, size = m:GetBoundingBox()
	m:ScaleTo(m:GetScale() * target / math.max(size.Z, 0.1))
	local cf, box = m:GetBoundingBox()
	pcall(rearPlate, m, cf, box)
	m.Parent = nil
	cf = CFrame.new(cf.Position) * CFrame.Angles(0, math.pi, 0) -- the root's front (-Z) is the car's +Z

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
		local w = partOf(m, name)
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
			-- Import 3D drops the plain colours: the untextured pieces (tyres, trim, glass) are near-black
			if p:IsA("MeshPart") and p.TextureID == "" and not keepColors then
				p.Color = UNTEXTURED
			end
			if not wheelParts[p] then
				weld(root, p)
			end
		end
	end
	-- (no brake-light strips: traffic cars have no lights, owner 2026-11-02)
	m:SetAttribute("Length", box.Z)
	m:SetAttribute("Width", box.X)
	m:SetAttribute("Height", box.Y)
	m:SetAttribute("TrafficBody", m.Name)
	if entry then
		m:SetAttribute("TrafficId", entry.id)
		if entry.rare then
			-- the hook for a later chase bonus (17 Nov design): rare NPC supercars carry RareTraffic = their cap group
			m:SetAttribute("RareTraffic", entry.rare)
			m:SetAttribute("RacerMph", entry.mph and entry.mph * (TrafficMix.TrimSpeed[entry.trim or "BASE"] or 1))
			m:SetAttribute("RareTrim", entry.trim)
		end
	end
	return m
end

local function buildFrom(list: { Model }, rng: Random, pick: Model?): Model?
	if #list == 0 and not pick then
		return nil
	end
	local template = pick or list[rng:NextInteger(1, #list)]
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
	local car = done:Clone()
	-- (2026-11-19) its number plate: private black, a share of Probox / small cars as red taxis
	local plate = car:FindFirstChild("PlateText")
	local sg = plate and plate:FindFirstChildOfClass("SurfaceGui")
	if sg then
		local e = TrafficMix.byName[template.Name]
		local taxi = e ~= nil and not e.rare and rng:NextNumber() < (if e.id == "probox" then 0.5 else 0.12)
		Plates.draw(sg, if taxi then Plates.taxi(rng) else Plates.roll(rng), if taxi then "taxi" else "private")
	end
	-- livery: the parts marked TrafficPaint take one of the car's colours (TrafficMix)
	local entry = TrafficMix.byName[template.Name]
	if entry and #entry.paint > 0 then
		local color = entry.paint[rng:NextInteger(1, #entry.paint)]
		for _, d in car:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("TrafficPaint") then
				d.Color = color
			end
		end
	end
	return car
end

-- a new traffic car (nil when there are no TrafficModels). With the Yangon set in the place the car comes from
-- TrafficMix.pick: `counts` = live cars per rare group, `main` = the spot is on a main road
-- (2026-11-21, races) `rivalOf` = a rare cap group: only a rival for that group's car (TrafficMix.rival), or nil
function TrafficBodies.build(rng: Random, counts: { [string]: number }?, main: boolean?, rivalOf: string?): Model?
	local all = templates()
	local have, byName = {}, {}
	for _, m in all do
		if TrafficMix.byName[m.Name] then
			have[m.Name] = true
			byName[m.Name] = m
		end
	end
	if next(have) then
		local name = if rivalOf then TrafficMix.rival(rng, have, counts or {}, rivalOf) else TrafficMix.pick(rng, have, counts or {}, main == true)
		return if name then buildFrom({}, rng, byName[name]) else nil
	end
	return if rivalOf then nil else buildFrom(all, rng)
end

-- (2026-11-14, YangonStreetLife's parked cars) a car of one type letter (Config.Traffic.ModelLengths: A hatch,
-- B people carrier, C small van, D minibus, E saloon, F pickup); any type when the place has none of that one
function TrafficBodies.buildType(kind: string, rng: Random): Model?
	local all = {}
	for _, m in templates() do
		local e = TrafficMix.byName[m.Name]
		if not (e and (e.rare or e.main)) then -- (no parked supercars or buses)
			table.insert(all, m)
		end
	end
	local list = {}
	for _, m in all do
		if (string.match(m.Name, "_(%a)") or "A") == kind then
			table.insert(list, m)
		end
	end
	return buildFrom(if #list > 0 then list else all, rng)
end

return TrafficBodies
