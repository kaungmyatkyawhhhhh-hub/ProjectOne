--[[
	Knockables (client)
	Street lights, trees and traffic light poles you can knock down (owner, 2026-10-23: "when u crash
	into light poles, trees, lamp, traffic lights make it fall down like a real life physics but it
	will return on its own later").

	At start (before the LOD system hides far-off detail) the city is scanned once for those props
	and each one becomes a group: its key part (the pole or the trunk) and the pieces on it (arm,
	head, lamp; branches and leaves; the signal's arm, heads and sign). The concrete plinths and
	planters stay put.

	While you drive, a prop right in front of your car at speed is knocked: the real one is hidden
	and a copy made on this screen (so this game owns its physics) falls in its place, welded into
	one body and pushed the way you're going, so it tips over and rolls. The server passes the knock
	on and every other player's game drops the same prop. After RestoreSeconds, once no car is right
	beside it, the copy goes and the real one shows again. The map itself never changes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Driving = require(script.Parent:WaitForChild("Driving"))

local Knockables = {}

local K = Config.Knock
local CELL = 64

type Piece = { part: BasePart, transparency: number, collide: boolean, query: boolean }
type Group = { key: BasePart, base: Vector3, radius: number, pieces: { Piece }, down: boolean, downAt: number, debris: Model?, lights: { [Light]: boolean } }

local groups: { Group } = {}
local grid: { [string]: { Group } } = {}
local byKey: { [string]: Group } = {}

local function cellKey(x: number, z: number): string
	return math.floor(x / CELL) .. "," .. math.floor(z / CELL)
end

-- the id other games find the same prop by: its base, rounded
local function idOf(p: Vector3): string
	return string.format("%d,%d,%d", math.round(p.X), math.round(p.Y), math.round(p.Z))
end

local function add(key: BasePart, base: Vector3, radius: number, parts: { BasePart })
	local pieces: { Piece } = {}
	for _, p in parts do
		table.insert(pieces, { part = p, transparency = p.Transparency, collide = p.CanCollide, query = p.CanQuery })
	end
	local g: Group = { key = key, base = base, radius = radius, pieces = pieces, down = false, downAt = 0, debris = nil, lights = {} }
	table.insert(groups, g)
	local ck = cellKey(base.X, base.Z)
	grid[ck] = grid[ck] or {}
	table.insert(grid[ck], g)
	byKey[idOf(base)] = g
end

-- the bottom of an upright cylinder (Roblox cylinders lie along X; stood up, X points up)
local function footOf(p: BasePart): Vector3
	return p.Position - p.CFrame.RightVector * (p.Size.X / 2)
end

local function upright(p: BasePart): boolean
	return p:IsA("Part") and p.Shape == Enum.PartType.Cylinder and math.abs(p.CFrame.RightVector.Y) > 0.97
end

-- pieces in `parent` standing on the key (within `reach` of its foot across, from its foot up)
local function piecesAround(parent: Instance, foot: Vector3, reach: number, height: number, skip: (BasePart) -> boolean): { BasePart }
	local out = {}
	for _, c in parent:GetChildren() do
		if c:IsA("BasePart") and not skip(c) then
			local d = Vector2.new(c.Position.X - foot.X, c.Position.Z - foot.Z).Magnitude
			local dy = c.Position.Y - foot.Y
			if d <= reach and dy > 0.5 and dy < height and math.max(c.Size.X, c.Size.Y, c.Size.Z) < 16 then
				table.insert(out, c)
			end
		end
	end
	return out
end

local function scan(city: Instance)
	local signals: { Model } = {}
	for _, d in city:GetDescendants() do
		if d:IsA("Model") and string.sub(d.Name, 1, 7) == "Signal_" then
			table.insert(signals, d)
		elseif d:IsA("BasePart") then
			if d.Name == "LampPost" and upright(d) then
				-- a street light: the pole, its arm, head and lamp
				local foot = footOf(d)
				local parts = piecesAround(d.Parent :: Instance, foot, 8.5, d.Size.X + 3, function(p)
					return p == d or not (p.Material == Enum.Material.Metal or p.Material == Enum.Material.Neon)
				end)
				table.insert(parts, 1, d)
				add(d, foot, 1.2, parts)
			elseif d.Material == Enum.Material.Wood and upright(d) and d.Size.Y >= 0.99 and d.Size.Y <= 1.7 and d.Size.X > 4 and d.Size.X < 12 then
				-- a city tree: the lower trunk is the key; its upper trunk, branches and crown ride on it
				local foot = footOf(d)
				if foot.Y < 3 then
					local parts = piecesAround(d.Parent :: Instance, foot, 9, 24, function(p)
						return p == d or (p.Material ~= Enum.Material.Wood and p.Material ~= Enum.Material.LeafyGrass)
					end)
					table.insert(parts, 1, d)
					add(d, foot, 1.6, parts)
				end
			end
		end
	end
	-- traffic lights: one group per pole (its arm, head, sign and walk box), the plinth stays
	for _, m in signals do
		local poles: { BasePart } = {}
		for _, c in m:GetChildren() do
			if c:IsA("BasePart") and c.Name == "SignalPole" then
				table.insert(poles, c)
			end
		end
		local members: { [BasePart]: { BasePart } } = {}
		for _, pole in poles do
			members[pole] = { pole }
		end
		for _, c in m:GetChildren() do
			if c:IsA("BasePart") and c.Name ~= "SignalPole" and c.Name ~= "SignalBase" then
				local best, bestD = nil, math.huge
				for _, pole in poles do
					local d = Vector2.new(c.Position.X - pole.Position.X, c.Position.Z - pole.Position.Z).Magnitude
					if d < bestD then
						best, bestD = pole, d
					end
				end
				if best and bestD < 45 then
					table.insert(members[best], c)
				end
			end
		end
		for _, pole in poles do
			add(pole, footOf(pole), 1.4, members[pole])
		end
	end
end

local remote: RemoteEvent? = nil

local debrisFolder: Folder? = nil

-- the real prop's lights go off while it's down, and back as they were (day or night) after
local function lightsOff(g: Group, p: BasePart)
	for _, l in p:GetChildren() do
		if l:IsA("Light") then
			g.lights[l] = l.Enabled
			l.Enabled = false
		end
	end
end

local function knock(g: Group, dir: Vector3, speed: number)
	if g.down then
		return
	end
	g.down = true
	g.downAt = os.clock()
	if not debrisFolder or not debrisFolder.Parent then
		local f = Instance.new("Folder")
		f.Name = "KnockedProps"
		f.Parent = workspace
		debrisFolder = f
	end
	-- the copy: one body welded to its key part, the only piece that collides
	local model = Instance.new("Model")
	model.Name = "Knocked"
	local key: BasePart? = nil
	for _, pc in g.pieces do
		local orig = pc.part
		local c = orig:Clone()
		for _, tagless in c:GetDescendants() do
			-- (no tags on the copy: the LOD, lamp and traffic light scripts leave it alone)
			for _, t in tagless:GetTags() do
				tagless:RemoveTag(t)
			end
		end
		for _, t in c:GetTags() do
			c:RemoveTag(t)
		end
		c.Anchored = false
		c.CanQuery = false
		c.CanTouch = false
		if orig == g.key then
			key = c
			c.CanCollide = true
		else
			c.CanCollide = false
			c.Massless = true
		end
		c.Parent = model
		-- the real one hides (lights off) until it comes back
		orig.Transparency = 1
		orig.CanCollide = false
		orig.CanQuery = false
		lightsOff(g, orig)
	end
	if not key then
		return
	end
	for _, c in model:GetChildren() do
		if c ~= key and c:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = key
			w.Part1 = c
			w.Parent = c
		end
	end
	model.PrimaryPart = key
	model.Parent = debrisFolder
	g.debris = model
	-- pushed over the way the car was going, hard enough to topple it and slide it along
	local flat = Vector3.new(dir.X, 0, dir.Z)
	flat = if flat.Magnitude > 0.01 then flat.Unit else Vector3.xAxis
	local push = math.clamp(speed, 30, 160)
	local k = key :: BasePart
	k:ApplyImpulseAtPosition(flat * k.AssemblyMass * push * K.Push, k.Position + Vector3.new(0, k.Size.X * 0.3, 0))
	k.AssemblyAngularVelocity += flat:Cross(Vector3.yAxis) * -math.clamp(push / 25, 1.5, 5)
end

local function restore(g: Group)
	if g.debris then
		g.debris:Destroy()
		g.debris = nil
	end
	for _, pc in g.pieces do
		local p = pc.part
		p.Transparency = pc.transparency
		p.CanCollide = pc.collide
		p.CanQuery = pc.query
	end
	for l, on in g.lights do
		l.Enabled = on
	end
	table.clear(g.lights)
	g.down = false
end

-- the props near a point
local function near(p: Vector3): { Group }
	local out = {}
	local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	for x = cx - 1, cx + 1 do
		for z = cz - 1, cz + 1 do
			local list = grid[x .. "," .. z]
			if list then
				for _, g in list do
					table.insert(out, g)
				end
			end
		end
	end
	return out
end

local function carsNear(p: Vector3, r: number): boolean
	local folder = workspace:FindFirstChild("PlayerCars")
	for _, car in (if folder then folder:GetChildren() else {}) do
		if car:IsA("Model") and (car:GetPivot().Position - p).Magnitude < r then
			return true
		end
	end
	return false
end

-- knocks the prop nearest `p` (within 6 studs) over towards `dir`; true if there was one
function Knockables.knockNear(p: Vector3, dir: Vector3, speed: number): boolean
	local best, bestD = nil, 6
	for _, g in near(p) do
		local d = (g.base - p).Magnitude
		if not g.down and d < bestD then
			best, bestD = g, d
		end
	end
	if best then
		knock(best, dir, speed)
	end
	return best ~= nil
end

function Knockables.init()
	if not K.Enabled then
		return
	end
	local city = workspace:FindFirstChild("City")
	if not city then
		return
	end
	local t0 = os.clock()
	scan(city)
	print(("[CityLegends] %d knockable props (%.2fs)"):format(#groups, os.clock() - t0))

	local r = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Knock", 10)
	remote = if r and r:IsA("RemoteEvent") then r else nil
	if remote then
		-- another player knocked one: drop the same prop here
		remote.OnClientEvent:Connect(function(id: any, dir: any, speed: any)
			local g = if type(id) == "string" then byKey[id] else nil
			if g and typeof(dir) == "Vector3" and type(speed) == "number" then
				knock(g, dir, speed)
			end
		end)
	end

	local checkT, restoreT = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		checkT += dt
		restoreT += dt
		-- put props back once their time is up and no car is right there
		if restoreT > 1 then
			restoreT = 0
			local now = os.clock()
			for _, g in groups do
				if g.down and now - g.downAt > K.RestoreSeconds and not carsNear(g.base, 40) then
					restore(g)
				end
			end
		end
		if checkT < 1 / 30 then
			return
		end
		checkT = 0
		local model = Driving.getModel()
		local root = if model then model.PrimaryPart else nil
		if not root then
			return
		end
		local v = root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		if speed < Config.mphToSps(K.MinMph) then
			return
		end
		local cf = root.CFrame
		local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
		local right = fwd:Cross(Vector3.yAxis)
		local halfW = ((model :: Model):GetAttribute("Width") :: number? or 7) / 2
		local halfL = ((model :: Model):GetAttribute("Length") :: number? or 16) / 2
		-- a little ahead of the bumper, more the faster you go (one check every 1/30 s)
		local reach = halfL + 2 + speed / 30
		for _, g in near(root.Position) do
			if not g.down and math.abs(g.base.Y - root.Position.Y) < 12 then
				local rel = Vector3.new(g.base.X - cf.X, 0, g.base.Z - cf.Z)
				local along = rel:Dot(fwd)
				local side = math.abs(rel:Dot(right))
				if along > 0 and along < reach and side < halfW + g.radius then
					knock(g, v, speed)
					if remote then
						remote:FireServer(idOf(g.base), v, speed)
					end
				end
			end
		end
	end)
end

return Knockables
