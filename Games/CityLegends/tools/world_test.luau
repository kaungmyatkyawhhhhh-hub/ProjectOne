-- Lune test: builds the whole map (CityBuilder.build, with the west, the venues and the houses)
-- with Lune's Roblox instances, so a script error in any builder shows up here instead of in
-- Studio; then checks every lane of the lane graph has road under it, and counts parts.
--   lune run tools/world_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
local Instance = roblox.Instance

-- Lune's CFrame.lookAt comes out wrong for a direction that isn't level (the matrix is
-- transposed); Roblox's is right. The builders get a correct one here.
local CFrameFixed = setmetatable({
	lookAt = function(at: Vector3, target: Vector3, up: Vector3?)
		local look = (target - at).Unit
		local upV = up or roblox.Vector3.new(0, 1, 0)
		if math.abs(look:Dot(upV)) > 0.9999 then
			upV = roblox.Vector3.new(0, 0, 1)
		end
		local right = look:Cross(upV).Unit
		local realUp = right:Cross(look)
		return roblox.CFrame.fromMatrix(at, right, realUp, -look)
	end,
}, { __index = roblox.CFrame })

local game = Instance.new("DataModel")
local workspace = game:GetService("Workspace")
local terrain = Instance.new("Terrain")
terrain.Parent = workspace
local water: { { CFrame | Vector3 } } = {}
local terrainOps = 0
roblox.implementMethod("Terrain", "FillBlock", function(_, cf, size, material)
	terrainOps += 1
	if material == roblox.Enum.Material.Water then
		table.insert(water, { cf, size })
	end
end)
-- (Legends Isle's mountain is terrain: Lune can't make it, the calls are just counted)
roblox.implementMethod("Terrain", "FillCylinder", function()
	terrainOps += 1
end)
roblox.implementMethod("Terrain", "FillBall", function()
	terrainOps += 1
end)
local tags: { [string]: number } = {}
roblox.implementMethod("CollectionService", "AddTag", function(_, _inst, tag)
	tags[tag] = (tags[tag] or 0) + 1
end)
roblox.implementMethod("CollectionService", "GetTagged", function()
	return {}
end)
roblox.implementMethod("Model", "PivotTo", function(m, cf)
	local ok, pivot = pcall(function()
		return m.WorldPivot
	end)
	local from = if ok and pivot then pivot else cf
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = cf * from:ToObjectSpace(d.CFrame)
		end
	end
end)
roblox.implementMethod("Model", "GetPivot", function(m)
	local ok, pivot = pcall(function()
		return m.WorldPivot
	end)
	return if ok and pivot then pivot else roblox.CFrame.new()
end)

-- events (Lune has none): a signal you can connect to that never fires
local deadSignal = { Connect = function()
	return { Disconnect = function() end }
end, Once = function()
	return { Disconnect = function() end }
end, Wait = function() end }
local function events(class: string, names: { string })
	for _, n in names do
		pcall(roblox.implementProperty, class, n, function()
			return deadSignal
		end)
	end
end
events("RemoteEvent", { "OnServerEvent", "OnClientEvent" })
events("ProximityPrompt", { "Triggered", "TriggerEnded", "PromptButtonHoldBegan", "PromptButtonHoldEnded", "PromptShown", "PromptHidden" })
for _, c in { "Part", "WedgePart", "MeshPart", "Seat", "VehicleSeat", "TrussPart", "CornerWedgePart", "UnionOperation", "Model", "Folder", "Attachment", "Sound", "ClickDetector", "Humanoid", "SurfaceGui", "BillboardGui", "TextButton", "Frame", "TextLabel", "ImageLabel", "ImageButton", "ScreenGui" } do
	events(c, { "Touched", "TouchEnded", "Destroying", "ChildAdded", "ChildRemoved", "DescendantAdded", "AncestryChanged", "Changed", "MouseClick", "Ended", "Played", "Activated", "MouseButton1Click", "Died", "Seated" })
	pcall(roblox.implementMethod, c, "GetPropertyChangedSignal", function()
		return deadSignal
	end)
	pcall(roblox.implementMethod, c, "GetAttributeChangedSignal", function()
		return deadSignal
	end)
end
for _, c in { "Sound" } do
	pcall(roblox.implementMethod, c, "Play", function() end)
	pcall(roblox.implementMethod, c, "Stop", function() end)
end

local rs = game:GetService("ReplicatedStorage")
local shared = Instance.new("Folder")
shared.Name = "Shared"
shared.Parent = rs

-- services the builders use, with stand-ins where Lune has no implementation
local collection = {
	AddTag = function(_, _inst, tag)
		tags[tag] = (tags[tag] or 0) + 1
	end,
	GetTagged = function()
		return {}
	end,
	HasTag = function()
		return false
	end,
	GetInstanceAddedSignal = function()
		return { Connect = function() end }
	end,
}
local signal = { Connect = function() end }
local players = { GetPlayers = function()
	return {}
end, PlayerAdded = signal, PlayerRemoving = signal }
local tween = { Create = function()
	return { Play = function() end, Completed = signal }
end }
local runService = { Heartbeat = signal, Stepped = signal, IsServer = function()
	return true
end, IsClient = function()
	return false
end, IsStudio = function()
	return false
end, IsRunning = function()
	return false
end }
local gameProxy = { GetService = function(_, n)
	if n == "CollectionService" then
		return collection
	elseif n == "Players" then
		return players
	elseif n == "TweenService" then
		return tween
	elseif n == "RunService" then
		return runService
	end
	return game:GetService(n)
end }

local modules: { [string]: any } = {}
local load: (string, string) -> any

local function makeEnv(dir: string): { [string]: any }
	local env: { [string]: any } = {
		Color3 = roblox.Color3,
		Vector3 = roblox.Vector3,
		Vector2 = roblox.Vector2,
		UDim2 = roblox.UDim2,
		UDim = roblox.UDim,
		Enum = roblox.Enum,
		CFrame = CFrameFixed,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		NumberRange = roblox.NumberRange,
		Rect = roblox.Rect,
		PhysicalProperties = roblox.PhysicalProperties,
		Font = roblox.Font,
		Instance = Instance,
		Random = { new = function(seed: number?)
			-- a small seeded generator with Roblox's Random methods
			local state = math.floor((seed or 1) % 2147483647)
			if state <= 0 then
				state += 2147483646
			end
			local function step(): number
				state = (state * 48271) % 2147483647
				return state / 2147483647
			end
			return {
				NextNumber = function(_, a: number?, b: number?)
					local lo, hi = a or 0, b or 1
					return lo + step() * (hi - lo)
				end,
				NextInteger = function(_, a: number, b: number)
					return a + math.floor(step() * (b - a + 1))
				end,
			}
		end },
		task = { spawn = function() end, wait = function() end, delay = function() end, defer = function() end },
		os = os,
		math = math,
		string = string,
		table = table,
		print = print,
		warn = function(...)
			print("WARN", ...)
		end,
		error = error,
		pcall = pcall,
		typeof = typeof,
		type = type,
		tostring = tostring,
		tonumber = tonumber,
		ipairs = ipairs,
		pairs = pairs,
		next = next,
		select = select,
		setmetatable = setmetatable,
		getmetatable = getmetatable,
		utf8 = utf8,
		bit32 = bit32,
		buffer = buffer,
		workspace = workspace,
		game = gameProxy,
		tick = os.clock,
		time = os.clock,
	}
	local sibling = setmetatable({}, { __index = function(_, k)
		if k == "WaitForChild" or k == "FindFirstChild" then
			return function(_, n)
				return { name = n, dir = dir }
			end
		end
		return { name = k, dir = dir }
	end })
	env.script = { Parent = sibling }
	env.require = function(x)
		if typeof(x) == "Instance" then
			x = { name = x.Name, dir = "shared" }
		end
		return load(x.name, x.dir)
	end
	return env
end

-- PlayerData and the like: server state the builders touch only at run time
local stubs: { [string]: any } = {
	PlayerData = setmetatable({}, { __index = function()
		return function() end
	end }),
}

load = function(name: string, dir: string): any
	if stubs[name] then
		return stubs[name]
	end
	if modules[name] ~= nil then
		return modules[name]
	end
	local path
	for _, d in { dir, "shared", "server" } do
		local p = `{root}/src/{d}/{name}.lua`
		if fs.isFile(p) then
			path = p
			dir = d
			break
		end
	end
	assert(path, "no module " .. name)
	local env = makeEnv(dir)
	modules[name] = luau.load(fs.readFile(path), { debugName = name, environment = env })()
	return modules[name]
end

-- shared modules are found under ReplicatedStorage.Shared:WaitForChild(name)
local sharedProxy = { WaitForChild = function(_, n)
	return { name = n, dir = "shared" }
end }
roblox.implementMethod("ReplicatedStorage", "WaitForChild", function(_, n)
	if n == "Shared" then
		return sharedProxy
	end
	return Instance.new("Folder")
end)

local fails = 0
local function check(cond: boolean, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

local t0 = os.clock()
-- (Legends Isle's terrain is written voxel by voxel: Lune can't, so it's left out here)
load("Isle", "server").skipTerrain = true
local CityBuilder = load("CityBuilder", "server")
local ok, err = pcall(CityBuilder.build)
check(ok, "CityBuilder.build runs" .. (if ok then "" else ": " .. tostring(err)))
if not ok then
	process.exit(1)
end
print(string.format("built in %.1fs", os.clock() - t0))

local city = workspace:FindFirstChild("City")
check(city ~= nil, "City folder in the workspace")
-- parts per top-level folder (and the west's parts)
local total = 0
local parts: { BasePart } = {}
for _, folder in city:GetChildren() do
	local n = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
			table.insert(parts, d)
		end
	end
	total += n
	print(string.format("  %-22s %7d parts", folder.Name, n))
end
print(string.format("  %-22s %7d parts", "TOTAL", total))

-- every lane has a colliding road surface right under it (sampled along the lane)
local CityLayout = load("CityLayout", "shared")
local graph = CityLayout.buildGraph()
-- a coarse grid of the colliding parts' footprints
local CELL = 64
local grid: { [string]: { BasePart } } = {}
for _, p in parts do
	if p.CanCollide and p.Transparency < 1 then
		local cf, s = p.CFrame, p.Size
		local ex = math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z
		local ez = math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z
		local x0, x1 = math.floor((cf.X - ex / 2) / CELL), math.floor((cf.X + ex / 2) / CELL)
		local z0, z1 = math.floor((cf.Z - ez / 2) / CELL), math.floor((cf.Z + ez / 2) / CELL)
		if (x1 - x0 + 1) * (z1 - z0 + 1) < 4000 then
			for gx = x0, x1 do
				for gz = z0, z1 do
					local k = gx .. "," .. gz
					grid[k] = grid[k] or {}
					table.insert(grid[k], p)
				end
			end
		end
	end
end
-- a wedge lying flat (its thickness up, as the island's bend fillers): its top over pos, if
-- pos is over its triangle
local function flatWedgeTop(p: BasePart, pos: Vector3): number?
	if not p:IsA("WedgePart") or math.abs(p.CFrame.RightVector.Y) < 0.99 then
		return nil
	end
	local l = p.CFrame:PointToObjectSpace(pos)
	local s = p.Size
	if math.abs(l.Y) > s.Y / 2 + 0.05 or math.abs(l.Z) > s.Z / 2 + 0.05 then
		return nil
	end
	-- solid where (y + h/2) / h <= (z + l/2) / l
	if (l.Y + s.Y / 2) / s.Y > (l.Z + s.Z / 2) / s.Z + 0.02 then
		return nil
	end
	return p.CFrame.Position.Y + s.X / 2
end

-- the top surface of the parts under a point, nearest to y (nil when nothing's there)
local function groundAt(pos: Vector3): number?
	local list = grid[math.floor(pos.X / CELL) .. "," .. math.floor(pos.Z / CELL)]
	local best: number? = nil
	for _, p in list or {} do
		local l = p.CFrame:PointToObjectSpace(pos)
		local s = p.Size
		if math.abs(l.X) <= s.X / 2 + 0.05 and math.abs(l.Z) <= s.Z / 2 + 0.05 then
			-- the top face's height at this point (a block part; tilted decks too)
			local top = p.CFrame:PointToWorldSpace(roblox.Vector3.new(l.X, s.Y / 2, l.Z)).Y
			if p:IsA("WedgePart") then
				top = flatWedgeTop(p, pos) or math.huge
			elseif p:IsA("Part") and (p :: Part).Shape ~= roblox.Enum.PartType.Block then
				continue
			end
			if math.abs(top - pos.Y) < 3 and (not best or math.abs(top - pos.Y) < math.abs((best :: number) - pos.Y)) then
				best = top
			end
		end
	end
	return best
end
local bad, checked = 0, 0
local badWest = 0
for _, seg in graph.all do
	for k = 0, 4 do
		local p = CityLayout.sample(seg, seg.length * k / 4)
		checked += 1
		if not groundAt(p) then
			bad += 1
			if p.X < -1200 then
				badWest += 1
			end
			if bad <= 12 then
				print("  no road under", p, "dir", seg.dir, seg.kind)
			end
		end
	end
end
check(bad == 0, `road under every lane ({bad} of {checked} points missing, {badWest} in the west)`)

-- the island's climbs are smooth: no ledge a car would hit (owner, 2026-10-29: the car jerked
-- going up and down). Walks every island lane a stud at a time and takes the highest road top
-- under it (what the wheels touch); a jump of more than 0.35 studs is a ledge.
local IsleLayout = load("IsleLayout", "shared")
local function highestAt(pos: Vector3): number?
	local best: number? = nil
	for _, p in grid[math.floor(pos.X / CELL) .. "," .. math.floor(pos.Z / CELL)] or {} do
		local wtop = flatWedgeTop(p, pos)
		if wtop and math.abs(wtop - pos.Y) < 2.5 and (not best or wtop > (best :: number)) then
			best = wtop
		end
		if p:IsA("WedgePart") or (p:IsA("Part") and (p :: Part).Shape ~= roblox.Enum.PartType.Block) then
			continue
		end
		local l = p.CFrame:PointToObjectSpace(pos)
		local s = p.Size
		if math.abs(l.X) <= s.X / 2 and math.abs(l.Z) <= s.Z / 2 then
			local top = p.CFrame:PointToWorldSpace(roblox.Vector3.new(l.X, s.Y / 2, l.Z)).Y
			if math.abs(top - pos.Y) < 2.5 and (not best or top > (best :: number)) then
				best = top
			end
		end
	end
	return best
end
local ledges, walked = 0, 0
for _, seg in graph.all do
	local m = (seg.p0 + seg.p2) / 2
	if (roblox.Vector3.new(m.X, 0, m.Z) - IsleLayout.Center).Magnitude < IsleLayout.MaxShore and math.abs(seg.p2.Y - seg.p0.Y) + math.abs(seg.p0.Y) > 1 then
		local prev: number? = nil
		for d = 0, math.floor(seg.length) do
			local pos = CityLayout.sample(seg, d)
			local top = highestAt(pos)
			walked += 1
			if top and prev and math.abs(top - prev) > 0.35 then
				ledges += 1
				if ledges <= 8 then
					print(string.format("  ledge %.2f at %.0f, %.0f, %.0f", top - prev, pos.X, pos.Y, pos.Z))
				end
			end
			prev = top
		end
	end
end
check(ledges == 0, `island climbs smooth ({ledges} ledges in {walked} points)`)
-- nothing solid stands in a lane: colliding parts (not road surfaces) whose box takes in a point
-- 2 to 7 studs above the lane
local function blockedAt(pos: Vector3): BasePart?
	local list = grid[math.floor(pos.X / CELL) .. "," .. math.floor(pos.Z / CELL)]
	for _, p in list or {} do
		for _, h in { 2.5, 5, 7 } do
			local l = p.CFrame:PointToObjectSpace(pos + roblox.Vector3.new(0, h, 0))
			local sz = p.Size
			if math.abs(l.X) < sz.X / 2 and math.abs(l.Y) < sz.Y / 2 and math.abs(l.Z) < sz.Z / 2 then
				return p
			end
		end
	end
	return nil
end
local blocked, byName = 0, {}
for _, seg in graph.all do
	for k = 0, 8 do
		local p = CityLayout.sample(seg, seg.length * k / 8)
		local hit = blockedAt(p)
		if hit then
			blocked += 1
			local path = hit.Name
			local a = hit.Parent
			while a and a.Parent and a.Parent.Name ~= "City" do
				path = a.Name .. "/" .. path
				a = a.Parent
			end
			path = (if a then a.Name .. "/" else "") .. path
			if not byName[path] then
				byName[path] = { n = 0, at = p }
			end
			byName[path].n += 1
		end
	end
end
local shown = 0
for path, info in byName do
	shown += 1
	if shown <= 25 then
		print(string.format("  in a lane: %-60s x%d  e.g. %s", path, info.n, tostring(info.at)))
	end
end
check(blocked == 0, `lanes clear of solid parts ({blocked} points blocked)`)
check(#water >= 4, `water filled ({#water} blocks)`)
print(`tags: LOD {tags.LOD or 0}, LODLight {tags.LODLight or 0}`)
if fails > 0 then
	print(`{fails} FAILED`)
	process.exit(1)
end
print("ALL OK")
