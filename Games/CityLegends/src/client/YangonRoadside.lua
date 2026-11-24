--[[
	YangonRoadside (client, 2026-11-25): the overhead wires of real daytime Yangon (vault "2026-11-23 Real Yangon by day -
	clip study", item 1: "every city frame has them"; clips 0929, 0930, 0933, 0934). Concrete poles with a black-white
	banded foot on the kerb side of every road, thick black cable bundles sagging from pole to pole, now and then a pair
	of wires across the road, a junction box or a coil of spare cable on a pole, a transformer every few poles.

	Placed by rule from RivieraTraffic's lane data (the same lanes the cars drive): every EVERY studs along the outermost
	lane of each road and way, on the pavement (collision box RoadBox "P") or the grass verge (terrain), never on a road,
	median, deck or building, never inside a signalled junction. Districts whose street layer already has poles and
	cables (ReplicatedStorage.YgnKit.Data_<d>S, P1) are skipped there. Built only within LOAD studs of the camera, taken
	down past DROP. Visual only: no collision, no rays, no touches, no shadows. Wires are Beams (no parts).

	YangonRoadside.start(qualityScale)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))

local YangonRoadside = {}

local LOAD, DROP = 480, 640
local CHUNK = 192
local EVERY = 105 -- studs between poles (35 m)
local POLE_H = 27 -- 9 m
local BAND_H = 1.1
local W = 0.95 -- pole width
local CONCRETE = Color3.fromRGB(150, 148, 142)
local BLACK, WHITE = Color3.fromRGB(24, 24, 26), Color3.fromRGB(228, 228, 224)
local CABLE = Color3.fromRGB(20, 20, 22)
local BOXGREY = Color3.fromRGB(120, 124, 126)

local function baseRoad(name: string?): string
	return (string.gsub(name or "", "%s*#%d+$", ""))
end

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

-- poles: id -> { pos (lane-derived), right (towards the kerb), dir, road, way, chunk, prev (id along the run), cross (id across) }
local function plan(g, skipTile: (number, number) -> boolean)
	local poles = {}
	local boards = {}
	local chunks: { [string]: { p: { number }, b: { any } } } = {}
	local outer: { [string]: number } = {}
	for _, l in g.lanesData do
		if l.yangon and not l.skip then
			local k = l.road .. "|" .. l.way
			if (outer[k] or 0) < l.lane then
				outer[k] = l.lane
			end
		end
	end
	local junctions = {}
	local seen = {}
	for _, s in g.signals or {} do
		if not seen[s.i] then
			seen[s.i] = true
			table.insert(junctions, { c = s.center, r = s.radius + 18 })
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
	local byRoad: { [string]: { number } } = {}
	for li, l in g.lanesData do
		if li % 150 == 0 then
			task.wait() -- (Play, 25 Nov: the whole plan in one go was a 0.4 s hitch at start)
		end
		if l.yangon and not l.skip and l.lane == outer[l.road .. "|" .. l.way] then
			local n = #l.pts // 3
			local prevP: Vector3? = nil
			local acc = (string.len(l.road) * 37) % EVERY -- both sides of a road don't line up
			local last: number? = nil
			for k = 1, n do
				local p = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				if prevP then
					local seg = Vector3.new(p.X - prevP.X, 0, p.Z - prevP.Z)
					local len = seg.Magnitude
					if len > 0.01 then
						local dir = seg.Unit
						local t = 0
						while acc + (len - t) >= EVERY do
							t += EVERY - acc
							acc = 0
							local at = prevP:Lerp(p, t / len)
							local right = dir:Cross(Vector3.yAxis)
							local pos = at + right * 10.5
							local tx, tz = math.floor(pos.X / 256), math.floor(pos.Z / 256)
							if inJunction(pos) or skipTile(tx, tz) then
								last = nil
							else
								local id = #poles + 1
								local key = math.floor(pos.X / CHUNK) .. "," .. math.floor(pos.Z / CHUNK)
								poles[id] = { pos = pos, right = right, dir = dir, road = baseRoad(l.road), way = l.way, chunk = key, prev = last }
								chunks[key] = chunks[key] or { p = {}, b = {} }
								table.insert(chunks[key].p, id)
								byRoad[baseRoad(l.road)] = byRoad[baseRoad(l.road)] or {}
								table.insert(byRoad[baseRoad(l.road)], id)
								last = id
								-- now and then a billboard on one green column, 35 studs on, back behind the pavement
								if id % 9 == 4 then
									local bpos = at + dir * 35 + right * 22
									local bkey = math.floor(bpos.X / CHUNK) .. "," .. math.floor(bpos.Z / CHUNK)
									boards[#boards + 1] = { pos = bpos, right = right, dir = dir, chunk = bkey, n = #boards + 1 }
								end
							end
						end
						acc += len - t
					end
				end
				prevP = p
			end
		end
	end
	-- every third pole on way 1 gets wires across the road to the nearest pole of the other way
	for _, ids in byRoad do
		local count = 0
		for _, id in ids do
			local a = poles[id]
			if a.way == 1 then
				count += 1
				if count % 3 == 0 then
					local best, bd = nil, 95
					for _, jd in ids do
						local b = poles[jd]
						if b.way ~= 1 then
							local d = Vector3.new(b.pos.X - a.pos.X, 0, b.pos.Z - a.pos.Z).Magnitude
							if d < bd and d > 20 and math.abs(b.pos.Y - a.pos.Y) < 8 then
								best, bd = jd, d
							end
						end
					end
					a.cross = best
				end
			end
		end
	end
	for _, b in boards do
		chunks[b.chunk] = chunks[b.chunk] or { p = {}, b = {} }
		table.insert(chunks[b.chunk].b, b)
	end
	return poles, chunks
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

-- where a pole really stands: on the pavement or the verge, near its lane-derived spot; nil if nowhere fits
local resolved: { [number]: Vector3 | false } = {}
local function resolve(poles, id: number): Vector3?
	local r = resolved[id]
	if r ~= nil then
		return r or nil
	end
	local p = poles[id]
	local root = Config.mapRoot and Config.mapRoot()
	local roads = root and root:FindFirstChild("Roads")
	local collide = roads and roads:FindFirstChild("Collide")
	if not collide then
		return nil -- not streamed / no map: try again later
	end
	local blockers = {}
	for _, n in { "Buildings", "Landmarks", "Parks", "Pagodas", "CarCare", "Sites", "Green" } do
		local f = root:FindFirstChild(n)
		if f then
			table.insert(blockers, f)
		end
	end
	local signals = workspace:FindFirstChild("YangonSignals")
	if signals then
		table.insert(blockers, signals)
	end
	local medians = workspace:FindFirstChild("YangonMedians")
	if medians then
		table.insert(blockers, medians)
	end
	rayParams.FilterDescendantsInstances = { collide, workspace.Terrain }
	overlap.FilterDescendantsInstances = blockers
	-- the lane under the spot must not be a deck (no poles on flyovers)
	local under = workspace:Raycast(p.pos - p.right * 10.5 + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), rayParams)
	if under and under.Instance:GetAttribute("RoadBox") == "D" then
		resolved[id] = false
		return nil
	end
	for _, off in { 0, -1.5, 1.5, 3, 4.5 } do
		local at = p.pos + p.right * off
		local hit = workspace:Raycast(at + Vector3.new(0, 14, 0), Vector3.new(0, -30, 0), rayParams)
		if hit then
			local kind = hit.Instance:GetAttribute("RoadBox")
			if kind == "P" or hit.Instance == workspace.Terrain then
				local base = Vector3.new(at.X, hit.Position.Y, at.Z)
				local box = CFrame.new(base + Vector3.new(0, POLE_H / 2 + 0.2, 0))
				if #workspace:GetPartBoundsInBox(box, Vector3.new(W + 0.6, POLE_H, W + 0.6), overlap) == 0 then
					resolved[id] = base
					return base
				end
			end
		end
	end
	resolved[id] = false
	return nil
end

-- the cable anchors of a pole (world positions), by slot: 1-2 the top arm's ends, 3-5 the bundles on the road side
local function anchors(p, base: Vector3): { Vector3 }
	local road = -p.right
	local top = base + Vector3.new(0, POLE_H + 0.35, 0)
	return {
		top + p.dir * 2.2,
		top - p.dir * 2.2,
		base + Vector3.new(0, POLE_H - 4.2, 0) + road * (W / 2 + 0.2),
		base + Vector3.new(0, POLE_H - 5.4, 0) + road * (W / 2 + 0.25),
		base + Vector3.new(0, POLE_H - 6.3, 0) + road * (W / 2 + 0.2),
	}
end

local DOWN = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0)) -- an attachment whose axis points down

local function wire(holder: BasePart, a: Vector3, b: Vector3, width: number, sagK: number)
	-- (parent first: a WorldCFrame set before parenting is taken as local)
	local a0 = Instance.new("Attachment")
	a0.Parent = holder
	a0.WorldCFrame = CFrame.new(a) * DOWN
	local a1 = Instance.new("Attachment")
	a1.Parent = holder
	a1.WorldCFrame = CFrame.new(b) * DOWN
	local sag = (b - a).Magnitude * sagK
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.CurveSize0, beam.CurveSize1 = sag, -sag
	beam.Width0, beam.Width1 = width, width
	beam.Color = ColorSequence.new(CABLE)
	beam.LightInfluence = 1
	beam.Segments = 8
	beam.FaceCamera = true
	beam.Parent = holder
end

local function buildPole(m: Instance, p, base: Vector3, id: number): BasePart
	local look = CFrame.lookAt(base, base + p.dir)
	-- the black-white banded foot, then the concrete shaft (stacked, not overlapping)
	for b = 0, 3 do
		part(m, Vector3.new(W, BAND_H, W), look * CFrame.new(0, BAND_H * (b + 0.5), 0), if b % 2 == 0 then BLACK else WHITE, Enum.Material.SmoothPlastic)
	end
	local shaftH = POLE_H - 4 * BAND_H
	local shaft = part(m, Vector3.new(W, shaftH, W), look * CFrame.new(0, 4 * BAND_H + shaftH / 2, 0), CONCRETE, Enum.Material.Concrete)
	-- the top arm along the road, sitting on the pole's top
	part(m, Vector3.new(0.35, 0.35, 5), look * CFrame.new(0, POLE_H + 0.175, 0), CONCRETE, Enum.Material.Concrete)
	-- road-side fittings against the pole's face (the road is -right = the look frame's -X... computed in world terms)
	local roadSide = CFrame.lookAt(base, base - p.right) -- facing the road
	if id % 3 == 0 then
		part(m, Vector3.new(1.3, 1.8, 0.7), roadSide * CFrame.new(0, 11, -(W / 2 + 0.35)), BOXGREY, Enum.Material.Metal) -- junction box
	elseif id % 3 == 1 then
		part(m, Vector3.new(0.55, 2.4, 2.4), roadSide * CFrame.new(0, 15.5, -(W / 2 + 0.275)) * CFrame.Angles(0, math.pi / 2, 0), CABLE, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder) -- coil of spare cable
	end
	if id % 7 == 0 then
		-- a transformer: two grey drums on the back of the pole
		for s = -1, 1, 2 do
			part(m, Vector3.new(2.6, 1.5, 1.5), roadSide * CFrame.new(s * 0.8, 19, W / 2 + 0.75) * CFrame.Angles(0, 0, math.pi / 2), BOXGREY, Enum.Material.Metal, Enum.PartType.Cylinder)
		end
	end
	return shaft
end

-- pole billboards (clips 0929 / 0930: big boards on one green steel column by the main roads). Fictional brands only.
local ADS = {
	{ top = "SHWE PYAY", mid = "ဘိလပ်မြေ", low = "CEMENT  ·  09-420 118 300", a = Color3.fromRGB(196, 28, 32), b = Color3.fromRGB(120, 10, 14), t = Color3.fromRGB(255, 214, 64) },
	{ top = "YADANAR 5G", mid = "အမြန်ဆုံး အင်တာနက်", low = "yadanar.net", a = Color3.fromRGB(20, 120, 210), b = Color3.fromRGB(8, 40, 110), t = Color3.new(1, 1, 1) },
	{ top = "GOLDEN TEAK RESIDENCE", mid = "အိမ်ခန်း ရောင်းမည်", low = "09-450 123 456", a = Color3.fromRGB(30, 92, 60), b = Color3.fromRGB(10, 40, 26), t = Color3.fromRGB(236, 200, 110) },
	{ top = "HILLTOP MILK TEA", mid = "လက်ဖက်ရည်", low = "3-in-1  ·  NEW TASTE", a = Color3.fromRGB(236, 150, 40), b = Color3.fromRGB(150, 70, 16), t = Color3.new(1, 1, 1) },
	{ top = "LUCKY STAR", mid = "ခေါက်ဆွဲ", low = "INSTANT NOODLE", a = Color3.fromRGB(250, 206, 30), b = Color3.fromRGB(214, 110, 10), t = Color3.fromRGB(140, 16, 16) },
	{ top = "ZAYAR PAINT", mid = "ဆေးသုတ်", low = "WEATHER SHIELD  ·  10 YEARS", a = Color3.fromRGB(110, 40, 150), b = Color3.fromRGB(40, 14, 70), t = Color3.new(1, 1, 1) },
}
local GREEN = Color3.fromRGB(46, 110, 64)
local BOARD_W, BOARD_H, BOARD_Y = 18, 9, 18

local function adFace(board: BasePart, face: Enum.NormalId, ad)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 1
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(400, 200)
	sg.MaxDistance = 600
	sg.Parent = board
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = Color3.new(1, 1, 1)
	bg.Parent = sg
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(ad.a, ad.b)
	grad.Rotation = 90
	grad.Parent = bg
	local function label(text: string, y: number, h: number, font: Enum.Font)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.05, y)
		t.Size = UDim2.fromScale(0.9, h)
		t.Font = font
		t.TextScaled = true
		t.TextColor3 = ad.t
		t.Text = text
		t.Parent = bg
	end
	label(ad.top, 0.06, 0.3, Enum.Font.GothamBlack)
	label(ad.mid, 0.38, 0.34, Enum.Font.GothamBold)
	label(ad.low, 0.76, 0.16, Enum.Font.GothamBold)
end

local function buildBoard(m: Instance, b): boolean
	local root = Config.mapRoot and Config.mapRoot()
	local roads = root and root:FindFirstChild("Roads")
	local collide = roads and roads:FindFirstChild("Collide")
	if not collide then
		return false
	end
	rayParams.FilterDescendantsInstances = { collide, workspace.Terrain }
	local hit = workspace:Raycast(b.pos + Vector3.new(0, 14, 0), Vector3.new(0, -30, 0), rayParams)
	if not hit or not (hit.Instance == workspace.Terrain or hit.Instance:GetAttribute("RoadBox") == "P") then
		return false
	end
	local base = Vector3.new(b.pos.X, hit.Position.Y, b.pos.Z)
	-- the board stands square to the road, facing the traffic that comes along it
	local cf = CFrame.lookAt(base, base - b.dir)
	local blockers = {}
	for _, n in { "Buildings", "Landmarks", "Parks", "Pagodas", "CarCare", "Sites", "Green" } do
		local f = root:FindFirstChild(n)
		if f then
			table.insert(blockers, f)
		end
	end
	overlap.FilterDescendantsInstances = blockers
	if #workspace:GetPartBoundsInBox(cf * CFrame.new(0, (BOARD_Y + BOARD_H) / 2 + 0.5, 0), Vector3.new(BOARD_W + 1, BOARD_Y + BOARD_H, 3), overlap) > 0 then
		return false
	end
	-- one column (a foot, the shaft) up to the board's frame
	part(m, Vector3.new(2.4, 1, 2.4), cf * CFrame.new(0, 0.5, 0), GREEN, Enum.Material.Metal)
	part(m, Vector3.new(1.5, BOARD_Y - 1, 1.5), cf * CFrame.new(0, 1 + (BOARD_Y - 1) / 2, 0), GREEN, Enum.Material.Metal)
	local board = part(m, Vector3.new(BOARD_W, BOARD_H, 0.7), cf * CFrame.new(0, BOARD_Y + BOARD_H / 2, 0), GREEN, Enum.Material.Metal)
	local pick = (b.n - 1) % #ADS + 1
	adFace(board, Enum.NormalId.Front, ADS[pick])
	adFace(board, Enum.NormalId.Back, ADS[pick % #ADS + 1])
	return true
end

local function buildChunk(poles, chunk, folder: Instance, full: boolean): Model?
	local m = Instance.new("Model")
	m.Name = "Roadside"
	local any = false
	for _, b in chunk.b do
		if buildBoard(m, b) then
			any = true
		end
	end
	for _, id in chunk.p do
		local p = poles[id]
		local base = resolve(poles, id)
		if base then
			any = true
			local shaft = buildPole(m, p, base, id)
			local mine = anchors(p, base)
			-- the run back to the previous pole
			local prevBase = p.prev and resolve(poles, p.prev)
			if prevBase then
				local q = poles[p.prev]
				local theirs = anchors(q, prevBase)
				local span = (mine[1] - theirs[1]).Magnitude
				if span < EVERY * 1.6 then
					wire(shaft, theirs[1], mine[1], 0.12, 0.05)
					wire(shaft, theirs[2], mine[2], 0.12, 0.055)
					wire(shaft, theirs[3], mine[3], 0.42, 0.065) -- the thick bundles
					if full then
						wire(shaft, theirs[4], mine[4], 0.3, 0.08)
						wire(shaft, theirs[5], mine[5], 0.22, 0.095)
					end
				end
			end
			local crossBase = p.cross and resolve(poles, p.cross)
			if crossBase then
				local theirs = anchors(poles[p.cross], crossBase)
				wire(shaft, mine[1], theirs[1], 0.12, 0.045)
				wire(shaft, mine[3], theirs[3], 0.28, 0.06)
			end
		end
	end
	if not any then
		m:Destroy()
		return nil
	end
	m.Parent = folder
	return m
end

local started = false
function YangonRoadside.start(qualityScale: (() -> number)?)
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
		-- tiles whose street layer already has poles and cables
		local kit = ReplicatedStorage:FindFirstChild("YgnKit")
		local function skipTile(i: number, j: number): boolean
			if not kit then
				return false
			end
			for _, f in kit:GetChildren() do
				if string.match(f.Name, "^Data_P%d+S$") and f:FindFirstChild(i .. "_" .. j) then
					return true
				end
			end
			return false
		end
		local poles, chunks = plan(g, skipTile)
		local folder = Instance.new("Folder")
		folder.Name = "YangonRoadside"
		folder.Parent = workspace
		local built: { [string]: Model | false } = {}
		while true do
			local q = if qualityScale then qualityScale() else 1
			local full = q > 0.5
			local load = if full then LOAD else LOAD * 0.7
			local cam = workspace.CurrentCamera
			local at = if cam then cam.CFrame.Position else Vector3.zero
			local cx, cz = math.floor(at.X / CHUNK), math.floor(at.Z / CHUNK)
			local reach = math.ceil(load / CHUNK)
			local made = 0
			for dx = -reach, reach do
				for dz = -reach, reach do
					local key = (cx + dx) .. "," .. (cz + dz)
					if chunks[key] and built[key] == nil and made < 3 then
						local mx, mz = (cx + dx + 0.5) * CHUNK, (cz + dz + 0.5) * CHUNK
						if Vector3.new(mx - at.X, 0, mz - at.Z).Magnitude < load then
							built[key] = buildChunk(poles, chunks[key], folder, full) or false
							made += 1
						end
					end
				end
			end
			for key, m in built do
				local x, z = string.match(key, "^(%-?%d+),(%-?%d+)$")
				local mx, mz = (tonumber(x) :: number + 0.5) * CHUNK, (tonumber(z) :: number + 0.5) * CHUNK
				if Vector3.new(mx - at.X, 0, mz - at.Z).Magnitude > DROP then
					if m then
						m:Destroy()
					end
					built[key] = nil
				end
			end
			task.wait(if made >= 3 then 0.05 else 1)
		end
	end)
end

return YangonRoadside
