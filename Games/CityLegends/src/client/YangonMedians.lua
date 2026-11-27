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
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

-- (owner, 2026-11-22: "add road street lights like the actual yangon depending on the location") a divided main road
-- in Yangon is lit from its median: galvanised 10 m poles with two short arms and white LED heads, every 30-35 m
-- (vault: 2026-11-16 Research - Yangon street furniture, 2.3). Their lights follow the time of day.
local GALV = Color3.fromRGB(170, 174, 178)
local LED = Color3.fromRGB(236, 244, 255)
local LAMP_EVERY = 12 -- pieces of 8 studs: one post every 96 studs (32 m)
local function isNight(): boolean
	local t = Lighting.ClockTime
	return t < 6.2 or t > 17.8
end
local lampsOn = isNight()
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	local n = isNight()
	if n ~= lampsOn then
		lampsOn = n
		for _, l in CollectionService:GetTagged("MedianLamp") do
			if l:IsA("Light") then
				l.Enabled = n
			end
		end
	end
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))
local NL = Config.NightLamps

local YangonMedians = {}

-- the roads with a planted middle strip in real life (Pyay Road: the owner's photo; Kabar Aye Pagoda Road by
-- Myanmar Plaza: a Google photo sphere at 16.8262, 96.1542 shows the same kerbed, planted strip)
local ROADS = { ["Pyay Road"] = true, ["Kabar Aye Pagoda Road"] = true }
local LOAD, DROP = 520, 680
local CHUNK = 160
local STEP = 8 -- studs per kerb block
-- (27 Nov, owner: kerbs "not realistic") old dirty matte paint, as measured on the Myanmar Plaza photos (red 111, 46, 41
-- in shade / white 191, 187, 174), not fresh racetrack colours; every other kerb in the city is plain concrete
local RED, WHITE = Color3.fromRGB(146, 50, 44), Color3.fromRGB(196, 192, 182)
local SOIL = Color3.fromRGB(52, 84, 40)
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
					w = math.clamp(d - 12 - 0.6, 1.8, 9) -- the strip's width: the gap between the lanes, a little in from each
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
	local chunkM = m
	local runs: { any } = {} -- { piece model, start, end } of every piece built, in order
	for idx, pc in pieces do
		local a: Vector3, b: Vector3, w: number = pc[1], pc[2], pc[3]
		local mid = (a + b) / 2
		-- not on a bridge deck
		if collide then
			-- (also the Hledan flyover's added deck, 2026-11-22)
			rayParams.FilterDescendantsInstances = { collide }
			local hit = workspace:Raycast(mid + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
			if hit and hit.Instance:GetAttribute("RoadBox") == "D" then
				continue
			end
			if hit then
				mid = Vector3.new(mid.X, hit.Position.Y, mid.Z)
			end
			-- (owner, 2026-11-22: "Medians is on the road ... blocking half the road") the strip takes only the REAL gap
			-- between the two carriageways: rays across find where each one's road box (RoadBox R) starts. With no gap
			-- (one carriageway, a painted centre line) it is a thin strip on the centre line.
			local along = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			if along.Magnitude > 0.01 then
				local right = along.Unit:Cross(Vector3.yAxis)
				local function edge(side: number): number
					for t = 0, w / 2, 0.5 do
						local h2 = workspace:Raycast(mid + right * (side * t) + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
						if h2 and h2.Instance:GetAttribute("RoadBox") == "R" then
							return t
						end
					end
					return w / 2
				end
				local tl, tr = edge(-1), edge(1)
				if tl + tr < 1.2 then
					-- (no gap: the middle is driving surface, a lane or a painted line. Play, 22 Nov: even a thin strip
					-- there stood in a lane on the junction flares, so nothing is built)
					continue
				else
					mid += right * ((tr - tl) / 2)
					w = math.max(tl + tr - 0.5, 1.3)
				end
			end
		end
		local plantK = math.clamp(w / 4.5, 0.4, 1) -- plants shrink with a narrow strip, so nothing hangs over a lane
		local m = Instance.new("Model") -- (this piece's own parts: a short loose run is taken out again below)
		m.Name = "Piece"
		m.Parent = chunkM
		table.insert(runs, { m, a, b })
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt(mid, mid + Vector3.new(b.X - a.X, 0, b.Z - a.Z))
		if idx % LAMP_EVERY == 0 and w >= 2.2 then
			part(m, Vector3.new(0.9, 30, 0.9), cf * CFrame.new(0, 15, 0), GALV, Enum.Material.Metal, nil, true) -- the post
			part(m, Vector3.new(1.5, 1.2, 1.5), cf * CFrame.new(0, 0.6, 0), GALV, Enum.Material.Metal)
			part(m, Vector3.new(12.4, 0.45, 0.45), cf * CFrame.new(0, 29.7, 0), GALV, Enum.Material.Metal) -- both arms
			for side = -1, 1, 2 do
				local head = part(m, Vector3.new(2.3, 0.36, 0.95), cf * CFrame.new(side * 6.9, 29.55, 0), LED, Enum.Material.Neon)
				local l = Instance.new("SpotLight")
				l.Face = Enum.NormalId.Bottom
				-- (27 Nov) the same light as every street lamp (Config.NightLamps, matched to the night clips)
				l.Color, l.Brightness, l.Range, l.Angle, l.Shadows = NL.Color, NL.Brightness, NL.Range, NL.Angle, NL.Shadows
				l.Enabled = lampsOn
				CollectionService:AddTag(l, "MedianLamp")
				l.Parent = head
			end
		end
		-- the strip: a planted soil bed with a red-and-white banded kerb down each side (bands STEP / 2 long)
		local hash = math.floor(mid.X / STEP + 0.5) + math.floor(mid.Z / STEP + 0.5)
		local kw = 0.42
		local bedW = math.max(w - 2 * kw, 0.6)
		part(m, Vector3.new(bedW, 0.5, len + 0.05), cf * CFrame.new(0, 0.25, 0), SOIL, Enum.Material.Grass, nil, true)
		for side = -1, 1, 2 do
			for h = 0, 1 do
				local col = if (hash + h) % 2 == 0 then RED else WHITE
				part(m, Vector3.new(kw, 0.58, len / 2), cf * CFrame.new(side * (bedW + kw) / 2, 0.29, (h - 0.5) * len / 2), col, Enum.Material.Concrete, nil, true)
			end
		end
		local kit = ReplicatedStorage:FindFirstChild("MedianKit")
		local function put(name: string, k: number, at: CFrame)
			local src = kit and kit:FindFirstChild(name)
			if src and src:IsA("Model") then
				local c = src:Clone()
				c:ScaleTo(src:GetScale() * k * plantK) -- (ScaleTo is absolute: times the kit's own scale)
				c:PivotTo(at * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				c.Parent = m
			end
		end
		local sway = math.max(bedW / 2 - 0.9, 0)
		-- ground cover all along the bed
		for j = 0, 1 do
			put("Low", rng:NextNumber(0.55, 0.8), cf * CFrame.new(rng:NextNumber(-sway, sway), 0.46, (j - 0.5) * len / 2 + rng:NextNumber(-0.8, 0.8)))
		end
		-- the main plant of the block: mostly a clipped shrub in the soil, now and then a pot (painted tyre or white
		-- box, as on the real strips) or a spiky plant; a few blocks stay bare
		local roll = rng:NextNumber()
		if roll < 0.88 then
			local at = cf * CFrame.new(rng:NextNumber(-sway, sway) * 0.5, 0.5, rng:NextNumber(-1.2, 1.2))
			local pick = if (idx * 7 + hash) % 6 == 0 then "Spiky" else "Shrub"
			local up = 0
			if (idx + hash) % 4 == 0 then
				local d = math.min(bedW + 0.2, 2.1)
				up = 0.3
				if (idx + hash) % 8 == 0 then
					part(m, Vector3.new(d, 0.95, d), at * CFrame.new(0, 0.475, 0), BOX, Enum.Material.Concrete) -- a white box planter
					part(m, Vector3.new(d - 0.3, 0.06, d - 0.3), at * CFrame.new(0, 0.96, 0), Color3.fromRGB(70, 52, 38), Enum.Material.Ground)
				else
					part(m, Vector3.new(0.85, d, d), at * CFrame.new(0, 0.425, 0) * CFrame.Angles(0, 0, math.pi / 2), TYRE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder) -- a painted tyre
					part(m, Vector3.new(0.12, d + 0.04, d + 0.04), at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), WHITE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
				end
			end
			if kit and kit:FindFirstChild(pick) then
				put(pick, if pick == "Spiky" then rng:NextNumber(0.85, 1.15) else rng:NextNumber(0.7, 1.0), at * CFrame.new(0, up, 0))
			else
				local ball = rng:NextNumber(1.7, 2.6)
				part(m, Vector3.new(ball, ball * 0.9, ball), at * CFrame.new(0, up + ball * 0.4, 0), LEAF[rng:NextInteger(1, #LEAF)], Enum.Material.Grass, Enum.PartType.Ball)
			end
		end
	end
	-- (owner, 2026-11-22: "stuffs just laying on the middle of the road instead of connecting to the other main medians")
	-- a run of fewer than 5 pieces (40 studs) that joins nothing is removed, unless it reaches the chunk's edge (it may go
	-- on in the next chunk)
	local kx, kz = string.match(key, "^(-?%d+),(-?%d+)$")
	local x0, z0 = (tonumber(kx) or 0) * CHUNK, (tonumber(kz) or 0) * CHUNK
	local function atEdge(p: Vector3): boolean
		return p.X - x0 < 12 or x0 + CHUNK - p.X < 12 or p.Z - z0 < 12 or z0 + CHUNK - p.Z < 12
	end
	local i = 1
	while i <= #runs do
		local j = i
		while j < #runs and (runs[j + 1][2] - runs[j][3]).Magnitude < 1.5 do
			j += 1
		end
		if j - i + 1 < 5 and not atEdge(runs[i][2]) and not atEdge(runs[j][3]) then
			for k = i, j do
				runs[k][1]:Destroy()
			end
		end
		i = j + 1
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
