--[[
	YangonMedians (client): the planted middle strip of Yangon's main roads (owner, 2026-11-21, with a photo of Pyay
	Road: "on the pyay roads the middle of the roads need to be like this (not on bridges)"): a low red-and-white
	kerbed strip between the two directions with pot plants on it (old tyres painted as pots, white box planters,
	clipped shrubs), open at every junction and crossing.

	Where: between the inner lanes of the two directions of the roads in ROADS, wherever the lane data leaves room
	(the inner lanes' middles 13 to 40 studs apart: a lane is 12 wide), not within a signalled junction, not on a
	bridge deck (collision attribute RoadBox = "D"). Built from RivieraTraffic's lane data, only within LOAD studs of
	the camera, taken down past DROP. The kerb collides (0.45 high); the pots and shrubs do not.

	YangonMedians.start()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))

local YangonMedians = {}

-- the roads with a planted middle strip in real life (Pyay Road: the owner's photo; Kabar Aye Pagoda Road by
-- Myanmar Plaza: a Google photo sphere at 16.8262, 96.1542 shows the same kerbed, planted strip)
local ROADS = { ["Pyay Road"] = true, ["Kabar Aye Pagoda Road"] = true }
local LOAD, DROP = 520, 680
local CHUNK = 160
local STEP = 8 -- studs per kerb block
local RED, WHITE = Color3.fromRGB(176, 34, 30), Color3.fromRGB(226, 226, 220)
local TYRE, BOX = Color3.fromRGB(58, 58, 62), Color3.fromRGB(232, 232, 228)
local LEAF = { Color3.fromRGB(58, 104, 44), Color3.fromRGB(70, 118, 50), Color3.fromRGB(48, 92, 40) }

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?, collide: boolean?): BasePart
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = collide == true
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

local function baseRoad(name: string?): string
	return (string.gsub(name or "", "%s*#%d+$", ""))
end

-- the strip's runs: { a, b, w } pieces STEP long between the two directions' inner lanes
local function plan(g): { [string]: { any } }
	local lanes = g.lanesData
	local back: { [string]: { Vector3 } } = {} -- [road] = the way -1 inner lane's points
	local cell = 48
	local grid: { [string]: { [string]: { Vector3 } } } = {}
	for _, l in lanes do
		local road = baseRoad(l.road)
		if l.yangon and ROADS[road] and l.way == -1 and l.lane == 1 and not l.skip then
			grid[road] = grid[road] or {}
			for k = 1, #l.pts // 3 do
				local p = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				local key = math.floor(p.X / cell) .. "," .. math.floor(p.Z / cell)
				grid[road][key] = grid[road][key] or {}
				table.insert(grid[road][key], p)
			end
		end
	end
	local _ = back
	local function nearest(road: string, p: Vector3): (Vector3?, number)
		local best, bd = nil, math.huge
		local cx, cz = math.floor(p.X / cell), math.floor(p.Z / cell)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, q in (grid[road] and grid[road][(cx + dx) .. "," .. (cz + dz)]) or {} do
					local d = Vector3.new(q.X - p.X, 0, q.Z - p.Z).Magnitude
					if d < bd and math.abs(q.Y - p.Y) < 4 then
						best, bd = q, d
					end
				end
			end
		end
		return best, bd
	end
	-- the junctions (signalled): the strip stops for them
	local junctions = {}
	local seen = {}
	for _, s in g.signals or {} do
		if not seen[s.i] then
			seen[s.i] = true
			table.insert(junctions, { c = s.center, r = s.radius + 14 })
		end
	end
	local function inJunction(p: Vector3): boolean
		for _, j in junctions do
			if Vector3.new(p.X - j.c.X, 0, p.Z - j.c.Z).Magnitude < j.r then
				return true
			end
		end
		return false
	end
	local chunks: { [string]: { any } } = {}
	for _, l in lanes do
		local road = baseRoad(l.road)
		if l.yangon and ROADS[road] and l.way == 1 and l.lane == 1 and not l.skip and grid[road] then
			local prev: Vector3? = nil
			local prevW = 0
			for k = 1, #l.pts // 3 do
				local p = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				local q, d = nearest(road, p)
				local mid: Vector3? = nil
				local w = 0
				if q and d >= 13 and d <= 40 then
					mid = (p + q) / 2
					w = math.clamp(d - 12 - 1.2, 1.4, 3.2) -- the strip's width: the gap between the lanes, a little in from each
					if inJunction(mid :: Vector3) then
						mid = nil
					end
				end
				if mid and prev and (mid - prev).Magnitude < 60 then
					local a, b = prev, mid
					local len = (b - a).Magnitude
					local n = math.max(1, math.floor(len / STEP + 0.5))
					for i = 1, n do
						local s0, s1 = a:Lerp(b, (i - 1) / n), a:Lerp(b, i / n)
						local m = (s0 + s1) / 2
						local key = math.floor(m.X / CHUNK) .. "," .. math.floor(m.Z / CHUNK)
						chunks[key] = chunks[key] or {}
						table.insert(chunks[key], { s0, s1, (prevW + w) / 2 })
					end
				end
				prev, prevW = mid, w
			end
		end
	end
	return chunks
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function buildChunk(key: string, pieces: { any }, folder: Instance): Model
	local m = Instance.new("Model")
	m.Name = "Median_" .. key
	local root = Config.mapRoot and Config.mapRoot()
	local roads = root and root:FindFirstChild("Roads")
	local collide = roads and roads:FindFirstChild("Collide")
	local rng = Random.new(string.len(key) * 7919 + (tonumber((string.gsub(key, "[^%d]", ""))) or 0) % 100000)
	for idx, pc in pieces do
		local a: Vector3, b: Vector3, w: number = pc[1], pc[2], pc[3]
		local mid = (a + b) / 2
		-- not on a bridge deck
		if collide then
			rayParams.FilterDescendantsInstances = { collide }
			local hit = workspace:Raycast(mid + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
			if hit and hit.Instance:GetAttribute("RoadBox") == "D" then
				continue
			end
			if hit then
				mid = Vector3.new(mid.X, hit.Position.Y, mid.Z)
			end
		end
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt(mid, mid + Vector3.new(b.X - a.X, 0, b.Z - a.Z))
		-- the kerb block: red and white in turn along the road
		local hash = math.floor(mid.X / STEP + 0.5) + math.floor(mid.Z / STEP + 0.5)
		part(m, Vector3.new(w, 0.45, len + 0.05), cf * CFrame.new(0, 0.225, 0), if hash % 2 == 0 then RED else WHITE, Enum.Material.Concrete, nil, true)
		-- a pot plant on every block but a few (real strips have gaps)
		if rng:NextNumber() < 0.82 then
			local at = cf * CFrame.new(0, 0.45, rng:NextNumber(-1.5, 1.5))
			local d = math.min(w + 0.5, 2.1)
			if (idx + hash) % 3 == 0 then
				part(m, Vector3.new(d, 0.95, d), at * CFrame.new(0, 0.475, 0), BOX, Enum.Material.SmoothPlastic) -- a white box planter
			else
				part(m, Vector3.new(0.85, d, d), at * CFrame.new(0, 0.425, 0) * CFrame.Angles(0, 0, math.pi / 2), TYRE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder) -- a painted tyre
				part(m, Vector3.new(0.12, d + 0.04, d + 0.04), at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			end
			-- the shrub: a short stem and a clipped ball
			local hgt = rng:NextNumber(1.3, 2.4)
			local ball = rng:NextNumber(1.7, 2.6)
			part(m, Vector3.new(hgt, 0.22, 0.22), at * CFrame.new(0, 0.9 + hgt / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(84, 66, 48), Enum.Material.Wood, Enum.PartType.Cylinder)
			part(m, Vector3.new(ball, ball * 0.9, ball), at * CFrame.new(0, 0.9 + hgt + ball * 0.3, 0), LEAF[rng:NextInteger(1, #LEAF)], Enum.Material.Grass, Enum.PartType.Ball)
		end
	end
	m.Parent = folder
	return m
end

local started = false
function YangonMedians.start()
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
		if not g or not g.lanesData then
			return
		end
		local chunks = plan(g)
		local folder = Instance.new("Folder")
		folder.Name = "YangonMedians"
		folder.Parent = workspace
		local built: { [string]: Model } = {}
		while true do
			local cam = workspace.CurrentCamera
			local at = if cam then cam.CFrame.Position else Vector3.zero
			local cx, cz = math.floor(at.X / CHUNK), math.floor(at.Z / CHUNK)
			local reach = math.ceil(LOAD / CHUNK)
			local made = 0
			for dx = -reach, reach do
				for dz = -reach, reach do
					local key = (cx + dx) .. "," .. (cz + dz)
					if chunks[key] and not built[key] and made < 3 then
						local mx, mz = (cx + dx + 0.5) * CHUNK, (cz + dz + 0.5) * CHUNK
						if Vector3.new(mx - at.X, 0, mz - at.Z).Magnitude < LOAD then
							built[key] = buildChunk(key, chunks[key], folder)
							made += 1
						end
					end
				end
			end
			for key, m in built do
				local x, z = string.match(key, "^(%-?%d+),(%-?%d+)$")
				local mx, mz = (tonumber(x) :: number + 0.5) * CHUNK, (tonumber(z) :: number + 0.5) * CHUNK
				if Vector3.new(mx - at.X, 0, mz - at.Z).Magnitude > DROP then
					m:Destroy()
					built[key] = nil
				end
			end
			task.wait(if made >= 3 then 0.05 else 1)
		end
	end)
end

return YangonMedians
