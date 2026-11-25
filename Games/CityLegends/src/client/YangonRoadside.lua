--[[
	YangonRoadside (client, 2026-11-25): the street dressing of real daytime Yangon (vault "2026-11-23 Real Yangon by day -
	clip study": item 1 "every city frame has them", item 2 toddy palm avenues, item 8 pole billboards; clips 0929-0934).

	  * main roads (RivieraTraffic's lanes, the outermost lane of each road and way): a concrete pole every EVERY studs on
	    the kerb side, black-white banded foot, thick black cable bundles sagging from pole to pole, now and then wires
	    across the road, a junction box / coil of spare cable / transformer; a white LED lamp arm on every second pole
	    (roads without a planted median: Pyay Road's median has its own lamps); a pole billboard now and then.
	  * side streets (road collision boxes RoadBox "R" with no traffic lane in them): a pole on one side every SIDE_CELL
	    studs, one wire and two bundles to the next pole along the street, an amber lamp on every second pole (owner,
	    21 Nov: side-street power-pole lamps are amber).
	  * at big signalled junctions (3+ approaches): a camera gantry over the widest approach, a white arm with 3-4 cameras
	    (clips 0929: 4 cameras, 0930: 3).
	  * at real compound gates (OSM barrier=gate, Shared.YangonRoadsideData): a guard booth with a red-white striped roof.
	  * round real construction sites (OSM landuse / building = construction): blue sheet hoarding.
	  * billboards light up at night near the camera, like the lamps.
	  * medians at least PALM_MEDIAN wide (the gap between the two ways' inner lanes): a row of toddy (palmyra) palms
	    down the middle, clip 0930.

	Nothing is placed on a road, median kerb, deck or building, inside a signalled junction, or where it would touch any
	other visible part: the client-built kit (buildings' balconies, walls and trees in workspace.YgnKitNear: CanQuery is
	off there, so they are tested point by point against each part's box), parks, landmarks, edge greenery, medians and
	signals. A wire that would touch one is left out. A chunk waits until the kit tiles round it are built (attribute
	Built). Districts whose street layer already has poles and cables (ReplicatedStorage.YgnKit.Data_<d>S, P1) are
	skipped. Built only within LOAD studs of the camera, taken down past DROP. Visual only: no collision, no rays, no
	touches, no shadows. Wires are Beams (no parts).

	YangonRoadside.start(qualityScale)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))

local YangonRoadside = {}

local LOAD, DROP = 480, 640
local CHUNK = 192
local EVERY = 105 -- studs between main-road poles (35 m)
local SIDE_CELL = 96 -- one side-street pole per cell of this size (CHUNK is a multiple of it)
local PALM_MEDIAN = 15 -- medians at least this wide (5 m) get toddy palms
local PALM_EVERY = 30 -- studs between palms (10 m)
local PALM_H = 45 -- trunk height (15 m)
local POLE_H = 27 -- 9 m
local BAND_H = 1.1
local W = 0.95 -- pole width
local TILE = 256 -- the kit's tile size
local CELL = 16 -- the blocker grid
local CONCRETE = Color3.fromRGB(150, 148, 142)
local BLACK, WHITE = Color3.fromRGB(24, 24, 26), Color3.fromRGB(228, 228, 224)
local CABLE = Color3.fromRGB(20, 20, 22)
local BOXGREY = Color3.fromRGB(120, 124, 126)
local GALV = Color3.fromRGB(170, 174, 178)
local LED, LED_LIGHT = Color3.fromRGB(236, 244, 255), Color3.fromRGB(232, 240, 255)
local AMBER, AMBER_LIGHT = Color3.fromRGB(255, 176, 92), Color3.fromRGB(255, 170, 96)
local NO_LAMPS = { ["Pyay Road"] = true, ["Kabar Aye Pagoda Road"] = true } -- their planted medians have lamps

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

local function isNight(): boolean
	local t = Lighting.ClockTime
	return t < 6.2 or t > 17.8
end

-- the camera gantries' space, known from the plan (before anything is built): wires and poles keep out of it
local gantryReg: { [string]: { Vector3 } } = {}
local function gantryAdd(p: Vector3)
	local k = math.floor(p.X / 32) .. "," .. math.floor(p.Z / 32)
	gantryReg[k] = gantryReg[k] or {}
	table.insert(gantryReg[k], p)
end
local function nearGantry(p: Vector3, r: number): boolean
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, q in gantryReg[(math.floor(p.X / 32) + dx) .. "," .. (math.floor(p.Z / 32) + dz)] or {} do
				if (q - p).Magnitude < r then
					return true
				end
			end
		end
	end
	return false
end

local GANTRY_BACK, GANTRY_SIDE, GANTRY_H = 30, 13, 20 -- studs before the stop line, out from the outer lane, arm height

---------------------------------------------------------------------
-- the plan: main-road poles from the lanes
---------------------------------------------------------------------
-- poles: id -> { pos (lane-derived), right (towards the kerb), dir, road, way, chunk, prev (id along the run), cross (id across) }
local function plan(g, skipTile: (number, number) -> boolean)
	local poles = {}
	local boards = {}
	local chunks: { [string]: any } = {} -- key -> { p = pole ids, b = boards, palms, gantries, gates, hoard }
	local laneGrid: { [string]: { Vector3 } } = {} -- every lane point, 48-stud cells (side streets are where none is)
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
		if l.yangon and not l.skip then
			for k = 1, #l.pts // 3 do
				local p = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				local key = math.floor(p.X / 48) .. "," .. math.floor(p.Z / 48)
				laneGrid[key] = laneGrid[key] or {}
				table.insert(laneGrid[key], p)
			end
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
							local tx, tz = math.floor(pos.X / TILE), math.floor(pos.Z / TILE)
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
	-- toddy palm spots: the middle of a median at least PALM_MEDIAN wide (between the two ways' inner lanes, a lane
	-- being 12 wide), every PALM_EVERY studs, not in a junction
	local back: { [string]: { Vector3 } } = {}
	for _, l in g.lanesData do
		if l.yangon and not l.skip and l.way == -1 and l.lane == 1 then
			for k = 1, #l.pts // 3 do
				local q = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				local key = baseRoad(l.road) .. "|" .. math.floor(q.X / 64) .. "," .. math.floor(q.Z / 64)
				back[key] = back[key] or {}
				table.insert(back[key], q)
			end
		end
	end
	for li, l in g.lanesData do
		if li % 300 == 0 then
			task.wait()
		end
		if l.yangon and not l.skip and l.way == 1 and l.lane == 1 then
			local road = baseRoad(l.road)
			local acc = 0
			local prevP: Vector3? = nil
			for k = 1, #l.pts // 3 do
				local p = Vector3.new(l.pts[3 * k - 2], l.pts[3 * k - 1], l.pts[3 * k])
				if prevP then
					acc += Vector3.new(p.X - prevP.X, 0, p.Z - prevP.Z).Magnitude
				end
				prevP = p
				if acc >= PALM_EVERY then
					acc = 0
					local best, bd = nil, math.huge
					local cx, cz = math.floor(p.X / 64), math.floor(p.Z / 64)
					for dx = -1, 1 do
						for dz = -1, 1 do
							for _, q in back[road .. "|" .. (cx + dx) .. "," .. (cz + dz)] or {} do
								local d = Vector3.new(q.X - p.X, 0, q.Z - p.Z).Magnitude
								if d < bd and math.abs(q.Y - p.Y) < 4 then
									best, bd = q, d
								end
							end
						end
					end
					if best and bd >= 12 + PALM_MEDIAN and bd <= 60 then
						local mid = (p + best) / 2
						if not inJunction(mid) then
							local key = math.floor(mid.X / CHUNK) .. "," .. math.floor(mid.Z / CHUNK)
							chunks[key] = chunks[key] or { p = {}, b = {} }
							chunks[key].palms = chunks[key].palms or {}
							table.insert(chunks[key].palms, mid)
						end
					end
				end
			end
		end
	end
	-- camera gantries: at junctions with 3+ approaches, over the approach with the most lanes (3+)
	local appr: { [string]: any } = {}
	local byJ: { [number]: { any } } = {}
	for _, sg in g.signals or {} do
		local ang = math.atan2(sg.dir.X, sg.dir.Z)
		local key = sg.i .. ":" .. (math.floor((ang + math.pi) / (math.pi / 6) + 0.5) % 12)
		local a = appr[key]
		if not a then
			a = { i = sg.i, dir = Vector3.new(sg.dir.X, 0, sg.dir.Z).Unit, pts = {} }
			appr[key] = a
			byJ[sg.i] = byJ[sg.i] or {}
			table.insert(byJ[sg.i], a)
		end
		table.insert(a.pts, sg.pos)
	end
	for _, list in byJ do
		if #list >= 3 then
			local best
			for _, a in list do
				if #a.pts >= 3 and (not best or #a.pts > #best.pts) then
					best = a
				end
			end
			if best then
				local right = best.dir:Cross(Vector3.yAxis)
				local outer, inner = best.pts[1], best.pts[1]
				for _, q in best.pts do
					if q:Dot(right) > outer:Dot(right) then
						outer = q
					end
					if q:Dot(right) < inner:Dot(right) then
						inner = q
					end
				end
				local base = outer + right * GANTRY_SIDE - best.dir * GANTRY_BACK
				local reach = math.clamp((base - (outer + inner) / 2):Dot(right) + 6, 14, 52)
				local gt = { base = base, dir = best.dir, right = right, reach = reach, cams = math.min(#best.pts, 4) }
				local key = math.floor(base.X / CHUNK) .. "," .. math.floor(base.Z / CHUNK)
				chunks[key] = chunks[key] or { p = {}, b = {} }
				chunks[key].gantries = chunks[key].gantries or {}
				table.insert(chunks[key].gantries, gt)
				for y = 0, GANTRY_H + 1, 2 do
					gantryAdd(base + Vector3.new(0, y + 0.5, 0))
				end
				for d = 0, reach, 2 do
					gantryAdd(base + Vector3.new(0, GANTRY_H, 0) - right * d)
					gantryAdd(base + Vector3.new(0, GANTRY_H - 1.5, 0) - right * d)
				end
			end
		end
	end
	return poles, chunks, laneGrid, inJunction
end

---------------------------------------------------------------------
-- what else is there: the parts nothing may touch
---------------------------------------------------------------------
local kitFolder: Instance? = nil
local kitTiles: { [string]: boolean } = {} -- tile names ("i_j" and "Si_j") that have kit data
local tileIndex = setmetatable({}, { __mode = "k" }) -- kit tile folder -> { [cellKey]: { BasePart } }
local staticIndex: { [string]: { BasePart } } = {}
local staticSeen = setmetatable({}, { __mode = "k" })

local function cellKey(x: number, z: number): string
	return math.floor(x / CELL) .. "," .. math.floor(z / CELL)
end

local function addPart(cells, q: BasePart, maxExt: number?)
	if q.Transparency >= 1 or math.max(q.Size.X, q.Size.Y, q.Size.Z) < 0.5 then
		return
	end
	local cf, h = q.CFrame, q.Size * 0.5
	local ex = math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z + 2
	local ez = math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z + 2
	local p = cf.Position
	if ex > (maxExt or 120) or ez > (maxExt or 120) then
		return -- (a huge box: ground plates and landmark walls; their collision boxes are found by solidAt)
	end
	for gx = math.floor((p.X - ex) / CELL), math.floor((p.X + ex) / CELL) do
		for gz = math.floor((p.Z - ez) / CELL), math.floor((p.Z + ez) / CELL) do
			local k = gx .. "," .. gz
			local list = cells[k]
			if not list then
				list = {}
				cells[k] = list
			end
			table.insert(list, q)
		end
	end
end

local function indexOf(f: Instance)
	local cells = tileIndex[f]
	if cells then
		return cells
	end
	cells = {}
	local n = 0
	for _, q in f:GetDescendants() do
		if q:IsA("BasePart") then
			addPart(cells, q)
			n += 1
			if n % 2000 == 0 then
				task.wait()
			end
		end
	end
	tileIndex[f] = cells
	return cells
end

local function watchStatic(f: Instance)
	local function add(q)
		if q:IsA("BasePart") and not staticSeen[q] then
			staticSeen[q] = true
			addPart(staticIndex, q, 60)
		end
	end
	local n = 0
	for _, q in f:GetDescendants() do
		add(q)
		n += 1
		if n % 3000 == 0 then
			task.wait()
		end
	end
	f.DescendantAdded:Connect(add)
end

-- every kit tile under the box has been built (or has no data)
local function kitReady(x0: number, z0: number, x1: number, z1: number): boolean
	local near = kitFolder or workspace:FindFirstChild("YgnKitNear")
	kitFolder = near
	for i = math.floor(x0 / TILE), math.floor(x1 / TILE) do
		for j = math.floor(z0 / TILE), math.floor(z1 / TILE) do
			for _, pre in { "", "S" } do
				local name = pre .. i .. "_" .. j
				if kitTiles[name] then
					local f = near and near:FindFirstChild(name)
					if not f or not f:GetAttribute("Built") then
						return false
					end
				end
			end
		end
	end
	return true
end

-- the blockers round a box: kit tiles (indexed once each), the static map folders, the built medians and signals
local function blockersFor(x0: number, z0: number, x1: number, z1: number)
	local sets = { staticIndex }
	local near = kitFolder
	if near then
		for i = math.floor(x0 / TILE), math.floor(x1 / TILE) do
			for j = math.floor(z0 / TILE), math.floor(z1 / TILE) do
				for _, pre in { "", "S" } do
					local f = near:FindFirstChild(pre .. i .. "_" .. j)
					if f then
						table.insert(sets, indexOf(f))
					end
				end
			end
		end
	end
	local dyn = {}
	for _, n in { "YangonMedians", "YangonSignals" } do
		local f = workspace:FindFirstChild(n)
		if f then
			for _, m in f:GetChildren() do
				local ok, cf, size = pcall(function()
					return (m :: Model):GetBoundingBox()
				end)
				if ok and cf.X + size.X > x0 - 60 and cf.X - size.X < x1 + 60 and cf.Z + size.Z > z0 - 60 and cf.Z - size.Z < z1 + 60 then
					for _, q in m:GetDescendants() do
						if q:IsA("BasePart") then
							addPart(dyn, q)
						end
					end
				end
			end
		end
	end
	table.insert(sets, dyn)
	return sets
end

local function blocked(sets, p: Vector3, margin: number): boolean
	local k = cellKey(p.X, p.Z)
	for _, cells in sets do
		local list = cells[k]
		if list then
			for _, q in list do
				if q.Parent then
					local lp = q.CFrame:PointToObjectSpace(p)
					local h = q.Size
					if math.abs(lp.X) < h.X * 0.5 + margin and math.abs(lp.Y) < h.Y * 0.5 + margin and math.abs(lp.Z) < h.Z * 0.5 + margin then
						return true
					end
				end
			end
		end
	end
	return false
end

-- my own things other chunks must keep clear of: palm trunks and the wires across roads (flat 32-stud grid)
local palmReg: { [string]: { any } } = {} -- { pos, chunk key }
local crossReg: { [string]: { any } } = {}
local function regKey(x: number, z: number): string
	return math.floor(x / 32) .. "," .. math.floor(z / 32)
end
local function regAdd(reg, p: Vector3, owner: string)
	local k = regKey(p.X, p.Z)
	reg[k] = reg[k] or {}
	table.insert(reg[k], { p, owner })
end
local function regPurge(owner: string)
	for _, reg in { palmReg, crossReg } do
		for _, list in reg do
			for i = #list, 1, -1 do
				if list[i][2] == owner then
					table.remove(list, i)
				end
			end
		end
	end
end
local function nearPalm(p: Vector3, r: number): boolean
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, e in palmReg[(math.floor(p.X / 32) + dx) .. "," .. (math.floor(p.Z / 32) + dz)] or {} do
				local q = e[1]
				if Vector3.new(p.X - q.X, 0, p.Z - q.Z).Magnitude < r and p.Y > q.Y - 1 and p.Y < q.Y + PALM_H + 12 then
					return true
				end
			end
		end
	end
	return false
end
local function nearCross(p: Vector3, r: number): boolean
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, e in crossReg[(math.floor(p.X / 32) + dx) .. "," .. (math.floor(p.Z / 32) + dz)] or {} do
				if (e[1] - p).Magnitude < r then
					return true
				end
			end
		end
	end
	return false
end

---------------------------------------------------------------------
-- building
---------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

local function mapParts()
	local root = Config.mapRoot and Config.mapRoot()
	local roads = root and root:FindFirstChild("Roads")
	local collide = roads and roads:FindFirstChild("Collide")
	return root, collide
end

-- the ground under a spot: its height and kind ("P" pavement, "T" terrain, else the RoadBox letter or nil)
local function ground(at: Vector3): (number?, string?)
	local _, collide = mapParts()
	if not collide then
		return nil, nil
	end
	rayParams.FilterDescendantsInstances = { collide, workspace.Terrain }
	local hit = workspace:Raycast(at + Vector3.new(0, 14, 0), Vector3.new(0, -30, 0), rayParams)
	if not hit then
		return nil, nil
	end
	if hit.Instance == workspace.Terrain then
		return hit.Position.Y, "T"
	end
	return hit.Position.Y, hit.Instance:GetAttribute("RoadBox")
end

-- the shells and other query-able map parts (buildings' collision and roofs, landmarks' collision ...)
local function solidList(): { Instance }?
	local root = mapParts()
	if not root then
		return nil
	end
	local list = {}
	for _, n in { "Buildings", "Landmarks", "Parks", "Pagodas", "CarCare", "Sites", "Green" } do
		local f = root:FindFirstChild(n)
		if f then
			table.insert(list, f)
		end
	end
	return list
end
local function solidAt(box: CFrame, size: Vector3): boolean
	local list = solidList()
	if not list then
		return true
	end
	overlap.FilterDescendantsInstances = list
	return #workspace:GetPartBoundsInBox(box, size, overlap) > 0
end

-- a pole standing at base is clear of everything (own lamp arm included when lampDir is given)
local function poleClear(sets, base: Vector3, lampDir: Vector3?): boolean
	if solidAt(CFrame.new(base + Vector3.new(0, POLE_H / 2 + 0.2, 0)), Vector3.new(W + 0.6, POLE_H, W + 0.6)) then
		return false
	end
	for y = 1.5, POLE_H + 1, 2 do
		local p = base + Vector3.new(0, y, 0)
		if blocked(sets, p, W / 2 + 0.25) or nearPalm(p, 2.5) or nearGantry(p, 2) then
			return false
		end
	end
	-- the top arm (5 long along the road, either way round): its ends
	for _, d in { Vector3.xAxis, Vector3.zAxis } do
		for sgn = -1, 1, 2 do
			if blocked(sets, base + Vector3.new(0, POLE_H + 0.2, 0) + d * (2.6 * sgn), 0.4) then
				return false
			end
		end
	end
	if lampDir then
		for d = 1, 8, 1.5 do
			if blocked(sets, base + Vector3.new(0, POLE_H - 1.5, 0) + lampDir * d, 0.5) then
				return false
			end
		end
	end
	return true
end

-- (owner via coordinator, 25 Nov: "keep poles off corner islands and small traffic islands") a pole spot must have
-- land behind it, away from the street: an island has road there
local function backed(at: Vector3, out: Vector3): boolean
	for _, d in { 6, 12, 18 } do
		local _, kind = ground(at + out * d)
		if kind == "R" or kind == "D" or kind == "M" then
			return false
		end
	end
	return true
end

-- resolved pole spots (main-road poles): id -> base | false; nil = not known yet (kit round it not built)
local resolved: { [number]: Vector3 | false } = {}
local function resolve(poles, id: number, sets): Vector3?
	local r = resolved[id]
	if r ~= nil then
		return r or nil
	end
	local p = poles[id]
	-- the lane under the spot must not be a deck (no poles on flyovers)
	local _, under = ground(p.pos - p.right * 10.5)
	if under == "D" then
		resolved[id] = false
		return nil
	end
	local lamp = if id % 2 == 0 and not NO_LAMPS[p.road] then -p.right else nil
	for _, off in { 0, -1.5, 1.5, 3, 4.5 } do
		for _, along in { 0, 6, -6, 12, -12 } do
			local at = p.pos + p.right * off + p.dir * along
			local y, kind = ground(at)
			if y and (kind == "P" or kind == "T") and backed(at, p.right) then
				local base = Vector3.new(at.X, y, at.Z)
				if poleClear(sets, base, lamp) then
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
local function anchors(dir: Vector3, right: Vector3, base: Vector3): { Vector3 }
	local road = -right
	local top = base + Vector3.new(0, POLE_H + 0.35, 0)
	return {
		top + dir * 2.2,
		top - dir * 2.2,
		base + Vector3.new(0, POLE_H - 4.2, 0) + road * (W / 2 + 0.2),
		base + Vector3.new(0, POLE_H - 5.4, 0) + road * (W / 2 + 0.25),
		base + Vector3.new(0, POLE_H - 6.3, 0) + road * (W / 2 + 0.2),
	}
end

local DOWN = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0)) -- an attachment whose axis points down

-- the points of a sagging wire (the beam's own curve), ends left out
local function wirePoints(a: Vector3, b: Vector3, sag: number): { Vector3 }
	local out = {}
	local p1, p2 = a + Vector3.new(0, -sag, 0), b + Vector3.new(0, -sag, 0)
	local n = math.max(2, math.ceil((b - a).Magnitude / 4))
	for i = 1, n - 1 do
		local t = i / n
		local u = 1 - t
		local q = a * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + b * (t * t * t)
		if (q - a).Magnitude > 2 and (q - b).Magnitude > 2 then
			table.insert(out, q)
		end
	end
	return out
end

-- a wire from a to b, unless it would touch something; returns its points when built
local function wire(holder: BasePart, sets, a: Vector3, b: Vector3, width: number, sagK: number, color: Color3?): { Vector3 }?
	local sag = (b - a).Magnitude * sagK
	local pts = wirePoints(a, b, sag)
	for _, q in pts do
		if blocked(sets, q, width / 2 + 0.15) or nearPalm(q, 2.2) or nearGantry(q, width / 2 + 1.5) then
			return nil
		end
	end
	-- (Play, 25 Nov: wires ran through shell roofs) the buildings' own boxes along the wire's box
	local list = solidList()
	if list then
		overlap.FilterDescendantsInstances = list
		local lo, hi = a:Min(b) - Vector3.new(1, sag + 1, 1), a:Max(b) + Vector3.new(1, 1, 1)
		local near = workspace:GetPartBoundsInBox(CFrame.new((lo + hi) / 2), hi - lo, overlap)
		if #near > 0 then
			local cells = {}
			for _, q in near do
				addPart(cells, q, 400)
			end
			for _, q in pts do
				if blocked({ cells }, q, width / 2 + 0.15) then
					return nil
				end
			end
		end
	end
	-- (parent first: a WorldCFrame set before parenting is taken as local)
	local a0 = Instance.new("Attachment")
	a0.Parent = holder
	a0.WorldCFrame = CFrame.new(a) * DOWN
	local a1 = Instance.new("Attachment")
	a1.Parent = holder
	a1.WorldCFrame = CFrame.new(b) * DOWN
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.CurveSize0, beam.CurveSize1 = sag, -sag
	beam.Width0, beam.Width1 = width, width
	beam.Color = ColorSequence.new(color or CABLE)
	beam.LightInfluence = 1
	beam.Segments = 8
	beam.FaceCamera = true
	beam.Parent = holder
	return pts
end

local LIGHT_R = 220
local AD_R = 320
local function lampLight(head: BasePart, color: Color3)
	local l = Instance.new("SpotLight")
	l.Face = Enum.NormalId.Bottom
	l.Color, l.Brightness, l.Range, l.Angle, l.Shadows = color, 4, 60, 135, false
	l.Enabled = false -- (the main loop turns on the near ones at night)
	CollectionService:AddTag(l, "RoadsideLamp")
	l.Parent = head
end

local function buildPole(m: Instance, dir: Vector3, right: Vector3, base: Vector3, id: number, lamp: string?): BasePart
	local look = CFrame.lookAt(base, base + dir)
	-- the black-white banded foot, then the concrete shaft (stacked, not overlapping)
	for b = 0, 3 do
		part(m, Vector3.new(W, BAND_H, W), look * CFrame.new(0, BAND_H * (b + 0.5), 0), if b % 2 == 0 then BLACK else WHITE, Enum.Material.SmoothPlastic)
	end
	local shaftH = POLE_H - 4 * BAND_H
	local shaft = part(m, Vector3.new(W, shaftH, W), look * CFrame.new(0, 4 * BAND_H + shaftH / 2, 0), CONCRETE, Enum.Material.Concrete)
	-- the top arm along the road, sitting on the pole's top
	part(m, Vector3.new(0.35, 0.35, 5), look * CFrame.new(0, POLE_H + 0.175, 0), CONCRETE, Enum.Material.Concrete)
	local roadSide = CFrame.lookAt(base, base - right) -- facing the road (-Z of this frame points at it)
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
	if lamp then
		-- a galvanised arm out over the road from the pole's face, the lamp head under its end
		part(m, Vector3.new(0.3, 0.3, 7), roadSide * CFrame.new(0, POLE_H - 1.5, -(W / 2 + 3.5)), GALV, Enum.Material.Metal)
		local head = part(m, Vector3.new(0.9, 0.3, 2.2), roadSide * CFrame.new(0, POLE_H - 1.8, -(W / 2 + 6.2)), if lamp == "amber" then AMBER else LED, Enum.Material.Neon)
		lampLight(head, if lamp == "amber" then AMBER_LIGHT else LED_LIGHT)
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
	CollectionService:AddTag(sg, "RoadsideAd") -- (lit at night near the camera by the main loop)
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

local function buildBoard(m: Instance, sets, b): boolean
	local y, kind = ground(b.pos)
	if not y or not (kind == "P" or kind == "T") then
		return false
	end
	local base = Vector3.new(b.pos.X, y, b.pos.Z)
	-- the board stands square to the road, facing the traffic that comes along it
	local cf = CFrame.lookAt(base, base - b.dir)
	if solidAt(cf * CFrame.new(0, (BOARD_Y + BOARD_H) / 2 + 0.5, 0), Vector3.new(BOARD_W + 1, BOARD_Y + BOARD_H, 3)) then
		return false
	end
	-- the column, then a grid over the board's face, against everything else round it
	for yy = 1.5, BOARD_Y, 2 do
		local p = (cf * CFrame.new(0, yy, 0)).Position
		if blocked(sets, p, 1) or nearPalm(p, 3) or nearCross(p, 3) then
			return false
		end
	end
	for x = -BOARD_W / 2, BOARD_W / 2, 3 do
		for yy = BOARD_Y, BOARD_Y + BOARD_H, 3 do
			local p = (cf * CFrame.new(x, yy, 0)).Position
			if blocked(sets, p, 0.6) or nearPalm(p, 3) or nearCross(p, 2) then
				return false
			end
		end
	end
	part(m, Vector3.new(2.4, 1, 2.4), cf * CFrame.new(0, 0.5, 0), GREEN, Enum.Material.Metal)
	part(m, Vector3.new(1.5, BOARD_Y - 1, 1.5), cf * CFrame.new(0, 1 + (BOARD_Y - 1) / 2, 0), GREEN, Enum.Material.Metal)
	local board = part(m, Vector3.new(BOARD_W, BOARD_H, 0.7), cf * CFrame.new(0, BOARD_Y + BOARD_H / 2, 0), GREEN, Enum.Material.Metal)
	local pick = (b.n - 1) % #ADS + 1
	adFace(board, Enum.NormalId.Front, ADS[pick])
	adFace(board, Enum.NormalId.Back, ADS[pick % #ADS + 1])
	return true
end

---------------------------------------------------------------------
-- toddy palms on wide medians (clip 0930: a row of tall palmyra palms on the median)
---------------------------------------------------------------------
local palmProto: Model? = nil
local function palmModel(): Model?
	if palmProto then
		return palmProto
	end
	local kit = ReplicatedStorage:FindFirstChild("RoadsideKit")
	local src = kit and kit:FindFirstChild("ToddyPalm")
	if src and src:IsA("Model") then
		palmProto = src
	end
	return palmProto
end

local function buildPalms(m: Instance, sets, key: string, spots: { Vector3 }?): number
	local proto = palmModel()
	local _, collide = mapParts()
	if not proto or not collide or not spots then
		return 0
	end
	local made = 0
	for _, at in spots do
		local y, kind = ground(at)
		-- on the median: its kerbed strip is a mesh over the road's own collision box (R), so R counts (the spot is
		-- 14+ studs from either inner lane's middle); never on a deck or a wall
		local ok = y ~= nil and (kind == "R" or kind == "M" or kind == "T" or kind == "P")
		local base = Vector3.new(at.X, y or at.Y, at.Z)
		if ok then
			ok = not nearPalm(base, PALM_EVERY * 0.6)
		end
		if ok then
			-- (a flyover's median has the ground road under it: no palms up there)
			rayParams.FilterDescendantsInstances = { collide, workspace.Terrain }
			local below = workspace:Raycast(base - Vector3.new(0, 2, 0), Vector3.new(0, -60, 0), rayParams)
			if below and base.Y - below.Position.Y > 8 then
				ok = false
			end
		end
		if ok then
			for yy = 1.5, PALM_H, 3 do
				local p = base + Vector3.new(0, yy, 0)
				if blocked(sets, p, 1.2) or nearCross(p, 2.5) then
					ok = false
					break
				end
			end
		end
		if ok then
			-- the crown: nothing within its radius
			for _, o in { Vector3.zero, Vector3.new(10, 0, 0), Vector3.new(-10, 0, 0), Vector3.new(0, 0, 10), Vector3.new(0, 0, -10), Vector3.new(0, -5, 0), Vector3.new(0, 5, 0) } do
				if blocked(sets, base + Vector3.new(0, PALM_H + 6, 0) + o, 1.5) then
					ok = false
					break
				end
			end
		end
		if ok and solidAt(CFrame.new(base + Vector3.new(0, (PALM_H + 15) / 2 + 0.5, 0)), Vector3.new(3, PALM_H + 15, 3)) then
			ok = false
		end
		if ok then
			local c2 = proto:Clone()
			c2:PivotTo(CFrame.new(base) * CFrame.Angles(0, (math.floor(at.X) * 7 + math.floor(at.Z)) % 360 * math.pi / 180, 0))
			c2.Parent = m
			regAdd(palmReg, base, key)
			made += 1
		end
	end
	return made
end

---------------------------------------------------------------------
-- side streets: road boxes with no traffic lane in them
---------------------------------------------------------------------
local sideCache: { [string]: { any } } = {}
local function sideCandidates(key: string, laneGrid, inJunction, skipTile): { any }
	local hit = sideCache[key]
	if hit then
		return hit
	end
	local _, collide = mapParts()
	if not collide then
		return {}
	end
	local kx, kz = string.match(key, "^(%-?%d+),(%-?%d+)$")
	local x0, z0 = (tonumber(kx) :: number) * CHUNK, (tonumber(kz) :: number) * CHUNK
	overlap.FilterDescendantsInstances = { collide }
	local boxes = workspace:GetPartBoundsInBox(CFrame.new(x0 + CHUNK / 2, 0, z0 + CHUNK / 2), Vector3.new(CHUNK + 160, 2000, CHUNK + 160), overlap)
	local function nearLane(p: Vector3, r: number): boolean
		local cx, cz = math.floor(p.X / 48), math.floor(p.Z / 48)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, q in laneGrid[(cx + dx) .. "," .. (cz + dz)] or {} do
					if Vector3.new(p.X - q.X, 0, p.Z - q.Z).Magnitude < r then
						return true
					end
				end
			end
		end
		return false
	end
	local best: { [string]: any } = {}
	for _, bx in boxes do
		if bx:GetAttribute("RoadBox") == "R" then
			local sx, sz = bx.Size.X, bx.Size.Z
			local short, long = math.min(sx, sz), math.max(sx, sz)
			local axis = if sx >= sz then bx.CFrame.RightVector else bx.CFrame.LookVector
			axis = Vector3.new(axis.X, 0, axis.Z)
			if axis.Magnitude > 0.5 and short >= 10 and short <= 36 and long >= 10 and (long >= 1.3 * short or long >= 40) and not nearLane(bx.Position, short / 2 + 10) then
				axis = axis.Unit
				if axis.X < -0.01 or (math.abs(axis.X) <= 0.01 and axis.Z < 0) then
					axis = -axis -- one way round for the whole street
				end
				local n = axis:Cross(Vector3.yAxis) -- the pole side: the same side all along a straight street
				for t = -long / 2, long / 2, 12 do
					local p = bx.Position + axis * t + n * (short / 2 + 3.5)
					if p.X >= x0 and p.X < x0 + CHUNK and p.Z >= z0 and p.Z < z0 + CHUNK then
						local gx, gz = math.floor(p.X / SIDE_CELL), math.floor(p.Z / SIDE_CELL)
						local ck = gx .. "," .. gz
						local mid = Vector3.new((gx + 0.5) * SIDE_CELL, p.Y, (gz + 0.5) * SIDE_CELL)
						local d = Vector3.new(p.X - mid.X, 0, p.Z - mid.Z).Magnitude
						if not best[ck] or d < best[ck].d then
							best[ck] = { pos = p, axis = axis, n = n, d = d }
						end
					end
				end
			end
		end
	end
	local list = {}
	for ck, c in best do
		if not inJunction(c.pos) and not nearLane(c.pos, 24) and not skipTile(math.floor(c.pos.X / TILE), math.floor(c.pos.Z / TILE)) then
			c.id = ck
			table.insert(list, c)
		end
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	sideCache[key] = list
	return list
end

local sideResolved: { [string]: Vector3 | false } = {}
local function sideHash(c): number
	local gx, gz = string.match(c.id, "^(%-?%d+),(%-?%d+)$")
	return math.abs((tonumber(gx) :: number) * 3 + (tonumber(gz) :: number) * 5)
end
local function resolveSide(c, sets): Vector3?
	local r = sideResolved[c.id]
	if r ~= nil then
		return r or nil
	end
	local lamp = if sideHash(c) % 2 == 0 then -c.n else nil
	for _, off in { 0, 1.5, -1, 3 } do
		for _, along in { 0, 6, -6, 12, -12 } do
			local at = c.pos + c.n * off + c.axis * along
			local y, kind = ground(at)
			if y and (kind == "P" or kind == "T") and backed(at, c.n) then
				local base = Vector3.new(at.X, y, at.Z)
				if poleClear(sets, base, lamp) then
					sideResolved[c.id] = base
					return base
				end
			end
		end
	end
	sideResolved[c.id] = false
	return nil
end

---------------------------------------------------------------------
-- camera gantries, guard booths, site hoarding
---------------------------------------------------------------------
local GANTRY_WHITE = Color3.fromRGB(232, 234, 236)
local LENS = Color3.fromRGB(18, 20, 24)

local function buildGantry(m: Instance, sets, gt): boolean
	for _, back in { 0, 10, 20 } do
		local at = gt.base - gt.dir * back
		local y, kind = ground(at)
		if y and (kind == "P" or kind == "T") then
			local base = Vector3.new(at.X, y, at.Z)
			local ok = not solidAt(CFrame.new(base + Vector3.new(0, GANTRY_H / 2 + 0.3, 0)), Vector3.new(1.4, GANTRY_H, 1.4))
			if ok then
				for yy = 1.5, GANTRY_H + 1, 2 do
					if blocked(sets, base + Vector3.new(0, yy, 0), 0.8) or nearPalm(base + Vector3.new(0, yy, 0), 2.5) then
						ok = false
						break
					end
				end
			end
			if ok then
				for d = 1, gt.reach, 2 do
					local q = base + Vector3.new(0, GANTRY_H - 0.8, 0) - gt.right * d
					if blocked(sets, q, 1.4) or nearPalm(q, 2.5) or nearCross(q, 2) then
						ok = false
						break
					end
				end
			end
			if ok then
				local face = CFrame.lookAt(base, base - gt.dir) -- the cameras look back at the cars coming
				part(m, Vector3.new(GANTRY_H, 0.8, 0.8), CFrame.new(base + Vector3.new(0, GANTRY_H / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), GANTRY_WHITE, Enum.Material.Metal, Enum.PartType.Cylinder)
				-- the arm sits on the pole's top and runs out over the lanes
				local armMid = base + Vector3.new(0, GANTRY_H + 0.25, 0) - gt.right * (gt.reach / 2)
				part(m, Vector3.new(0.5, 0.5, gt.reach + 0.4), CFrame.lookAt(armMid, armMid - gt.right), GANTRY_WHITE, Enum.Material.Metal)
				-- the cameras hang under the arm, evenly along its outer two thirds
				for k = 1, gt.cams do
					local d = gt.reach * (0.3 + 0.65 * (k - 0.5) / gt.cams)
					local c = base + Vector3.new(0, GANTRY_H - 0.35, 0) - gt.right * d
					local body = face.Rotation + c
					part(m, Vector3.new(0.7, 0.7, 1.6), body, GANTRY_WHITE, Enum.Material.SmoothPlastic)
					part(m, Vector3.new(0.5, 0.5, 0.12), body * CFrame.new(0, 0, -0.86), LENS, Enum.Material.Glass)
				end
				return true
			end
		end
	end
	return false
end

local BOOTH_WALL = Color3.fromRGB(226, 220, 204)
local ROOF_RED = Color3.fromRGB(190, 36, 32)

local function buildBooth(m: Instance, sets, gate: Vector3): boolean
	-- a spot beside the gate: off the road, on the pavement / ground, clear of walls and trees
	for k = 0, 7 do
		local a = k * math.pi / 4
		local off = Vector3.new(math.cos(a), 0, math.sin(a))
		local at = gate + off * 9
		local y, kind = ground(at)
		if y and (kind == "P" or kind == "T") then
			local base = Vector3.new(at.X, y, at.Z)
			local cf = CFrame.lookAt(base, base - off) -- the window faces the gate
			local ok = not solidAt(cf * CFrame.new(0, 4.6, 0), Vector3.new(6.4, 8.6, 6.4))
			if ok then
				for _, o in { Vector3.new(0, 1, 0), Vector3.new(2.5, 1, 2.5), Vector3.new(-2.5, 1, 2.5), Vector3.new(2.5, 1, -2.5), Vector3.new(-2.5, 1, -2.5), Vector3.new(0, 4, 0), Vector3.new(0, 7.5, 0), Vector3.new(3, 7.6, 3), Vector3.new(-3, 7.6, -3) } do
					local q = (cf * CFrame.new(o)).Position
					if blocked(sets, q, 0.4) or nearPalm(q, 2) then
						ok = false
						break
					end
				end
			end
			if ok then
				-- off the road on all four corners
				for _, o in { Vector3.new(3, 0, 3), Vector3.new(-3, 0, 3), Vector3.new(3, 0, -3), Vector3.new(-3, 0, -3) } do
					local _, k2 = ground((cf * CFrame.new(o)).Position)
					if k2 == "R" or k2 == "D" or k2 == "M" then
						ok = false
						break
					end
				end
			end
			if ok then
				part(m, Vector3.new(5, 7, 5), cf * CFrame.new(0, 3.5, 0), BOOTH_WALL, Enum.Material.SmoothPlastic)
				-- window (front) and door (side): thin sheets standing on the walls
				part(m, Vector3.new(3.6, 2.2, 0.1), cf * CFrame.new(0, 4.6, -2.55), LENS, Enum.Material.Glass)
				part(m, Vector3.new(0.1, 5.6, 2.2), cf * CFrame.new(2.55, 2.8, 0.6), Color3.fromRGB(96, 70, 52), Enum.Material.Wood)
				-- the roof: red and white stripes side by side, overhanging the walls
				for i = 0, 3 do
					part(m, Vector3.new(1.6, 0.4, 6.4), cf * CFrame.new(-2.4 + i * 1.6, 7.2, 0), if i % 2 == 0 then ROOF_RED else WHITE, Enum.Material.SmoothPlastic)
				end
				return true
			end
		end
	end
	return false
end

local HOARD_BLUE = Color3.fromRGB(28, 86, 168)
local HOARD_H = 7.5 -- 2.5 m

local function buildHoarding(m: Instance, sets, panels: { any }): number
	local made = 0
	for _, pn in panels do
		local y, kind = ground(pn.c)
		if y and kind ~= "R" and kind ~= "D" and kind ~= "M" then
			local base = Vector3.new(pn.c.X, y, pn.c.Z)
			local cf = CFrame.lookAt(base, base + pn.n)
			local ok = not solidAt(cf * CFrame.new(0, HOARD_H / 2 + 0.3, 0), Vector3.new(pn.w, HOARD_H - 0.4, 0.3))
			if ok then
				for x = -pn.w / 2 + 0.5, pn.w / 2 - 0.5, 1.5 do
					for yy = 0.8, HOARD_H - 0.4, 2.2 do
						if blocked(sets, (cf * CFrame.new(x, yy, 0)).Position, 0.2) then
							ok = false
							break
						end
					end
					if not ok then
						break
					end
				end
			end
			if ok then
				part(m, Vector3.new(pn.w, HOARD_H, 0.25), cf * CFrame.new(0, HOARD_H / 2, 0), HOARD_BLUE, Enum.Material.DiamondPlate)
				made += 1
			end
		end
	end
	return made
end

---------------------------------------------------------------------
-- a chunk
---------------------------------------------------------------------
local function chunkXZ(key: string): (number, number)
	local kx, kz = string.match(key, "^(%-?%d+),(%-?%d+)$")
	return (tonumber(kx) :: number) * CHUNK, (tonumber(kz) :: number) * CHUNK
end

-- nil = not ready yet (try again later); false = nothing here
local function buildChunk(ctx, key: string, chunk, folder: Instance, full: boolean): Model | false | nil
	local x0, z0 = chunkXZ(key)
	local _, collide = mapParts()
	if not collide then
		return nil
	end
	-- the kit round the chunk (and its neighbours, for the wires out of it) must be built first
	if not kitReady(x0 - 110, z0 - 110, x0 + CHUNK + 110, z0 + CHUNK + 110) then
		return nil
	end
	regPurge(key)
	local sets = blockersFor(x0 - CHUNK, z0 - CHUNK, x0 + 2 * CHUNK, z0 + 2 * CHUNK)
	local poles = ctx.poles
	local m = Instance.new("Model")
	m.Name = "Roadside"
	local any = false
	-- palms first (their trunks are what the cross wires keep off)
	if buildPalms(m, sets, key, chunk and chunk.palms) > 0 then
		any = true
	end
	task.wait()
	for _, id in chunk and chunk.p or {} do
		local p = poles[id]
		local base = resolve(poles, id, sets)
		if base then
			any = true
			local lamp = if id % 2 == 0 and not NO_LAMPS[p.road] then "white" else nil
			local shaft = buildPole(m, p.dir, p.right, base, id, lamp)
			local mine = anchors(p.dir, p.right, base)
			-- the run back to the previous pole
			local prevBase = p.prev and resolve(poles, p.prev, sets)
			if prevBase then
				local q = poles[p.prev]
				local theirs = anchors(q.dir, q.right, prevBase)
				if (mine[1] - theirs[1]).Magnitude < EVERY * 1.6 then
					wire(shaft, sets, theirs[1], mine[1], 0.12, 0.05)
					wire(shaft, sets, theirs[2], mine[2], 0.12, 0.055)
					wire(shaft, sets, theirs[3], mine[3], 0.42, 0.065) -- the thick bundles
					if full then
						wire(shaft, sets, theirs[4], mine[4], 0.3, 0.08)
						wire(shaft, sets, theirs[5], mine[5], 0.22, 0.095)
					end
				end
			end
			local crossBase = p.cross and resolve(poles, p.cross, sets)
			if crossBase then
				local q = poles[p.cross]
				local theirs = anchors(q.dir, q.right, crossBase)
				for _, pr in { { 1, 0.12, 0.045 }, { 3, 0.28, 0.06 } } do
					local pts = wire(shaft, sets, mine[pr[1]], theirs[pr[1]], pr[2], pr[3])
					for _, s in pts or {} do
						regAdd(crossReg, s, key)
					end
				end
			end
		end
	end
	task.wait()
	for _, b in chunk and chunk.b or {} do
		if buildBoard(m, sets, b) then
			any = true
		end
	end
	for _, gt in chunk and chunk.gantries or {} do
		if buildGantry(m, sets, gt) then
			any = true
		end
	end
	for _, gate in chunk and chunk.gates or {} do
		if buildBooth(m, sets, gate) then
			any = true
		end
	end
	if chunk and chunk.hoard and buildHoarding(m, sets, chunk.hoard) > 0 then
		any = true
	end
	-- side streets: a pole per cell, wired to the next pole along the street
	local mineSide = sideCandidates(key, ctx.laneGrid, ctx.inJunction, ctx.skipTile)
	if #mineSide > 0 then
		local around = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				local k2 = math.floor(x0 / CHUNK + dx) .. "," .. math.floor(z0 / CHUNK + dz)
				for _, c in sideCandidates(k2, ctx.laneGrid, ctx.inJunction, ctx.skipTile) do
					table.insert(around, c)
				end
			end
		end
		for _, c in mineSide do
			local base = resolveSide(c, sets)
			if base then
				any = true
				local h = sideHash(c)
				local shaft = buildPole(m, c.axis, c.n, base, h, if h % 2 == 0 then "amber" else nil)
				-- the next pole forward along the street
				local best, bd = nil, 150
				for _, o in around do
					if o ~= c then
						local d = Vector3.new(o.pos.X - c.pos.X, 0, o.pos.Z - c.pos.Z)
						local len = d.Magnitude
						if len > 45 and len < bd and d.Unit:Dot(c.axis) > 0.92 then
							best, bd = o, len
						end
					end
				end
				local ob = best and resolveSide(best, sets)
				if ob then
					local mine = anchors(c.axis, c.n, base)
					local theirs = anchors(best.axis, best.n, ob)
					wire(shaft, sets, mine[1], theirs[1], 0.12, 0.05)
					wire(shaft, sets, mine[3], theirs[3], 0.36, 0.065)
					if full then
						wire(shaft, sets, mine[4], theirs[4], 0.26, 0.085)
					end
				end
			end
		end
	end
	if not any then
		m:Destroy()
		return false
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
		-- the kit's tiles (which tile names will be built), and the tiles whose street layer has poles and cables
		local kit = ReplicatedStorage:FindFirstChild("YgnKit")
		local streetTiles: { [string]: boolean } = {}
		for _, f in (kit and kit:GetChildren()) or {} do
			if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
				local meta = f:FindFirstChild("Meta")
				local pre = if meta and string.find(meta.Value, "LOAD=", 1, true) then "S" else ""
				for _, v in f:GetChildren() do
					if v:IsA("StringValue") and v.Name ~= "Meta" then
						kitTiles[pre .. v.Name] = true
						if string.match(f.Name, "^Data_P%d+S$") then
							streetTiles[v.Name] = true
						end
					end
				end
			end
		end
		local function skipTile(i: number, j: number): boolean
			return streetTiles[i .. "_" .. j] == true
		end
		local poles, chunks, laneGrid, inJunction = plan(g, skipTile)
		local ctx = { poles = poles, laneGrid = laneGrid, inJunction = inJunction, skipTile = skipTile }
		-- real OSM gates (guard booths) and construction sites (hoarding), into the chunks
		local dataMod = Shared:FindFirstChild("YangonRoadsideData")
		local okData, data = pcall(function()
			return dataMod and require(dataMod)
		end)
		if okData and data then
			local function chunkOf(x: number, z: number)
				local key = math.floor(x / CHUNK) .. "," .. math.floor(z / CHUNK)
				chunks[key] = chunks[key] or { p = {}, b = {} }
				return chunks[key]
			end
			for xs, zs in string.gmatch(data.Gates or "", "(%-?[%d%.]+),(%-?[%d%.]+)") do
				local x, z = tonumber(xs) :: number, tonumber(zs) :: number
				local c = chunkOf(x, z)
				c.gates = c.gates or {}
				table.insert(c.gates, Vector3.new(x, 0, z))
			end
			for _, ring in data.Sites or {} do
				local pts = {}
				for xs, zs in string.gmatch(ring, "(%-?[%d%.]+),(%-?[%d%.]+)") do
					table.insert(pts, Vector3.new(tonumber(xs) :: number, 0, tonumber(zs) :: number))
				end
				-- each panel faces out of the ring's middle
				local mid = Vector3.zero
				for _, q in pts do
					mid += q
				end
				mid /= math.max(#pts, 1)
				for k = 1, #pts - 1 do
					local a, b = pts[k], pts[k + 1]
					local len = (b - a).Magnitude
					if len > 1 then
						local d = (b - a).Unit
						local nOut = d:Cross(Vector3.yAxis)
						if nOut:Dot((a + b) / 2 - mid) < 0 then
							nOut = -nOut
						end
						-- panels butt end to end; 0.2 kept clear at each corner so two edges' panels never meet
						local usable = len - 0.4
						local n = math.max(1, math.floor(usable / 8 + 0.5))
						local w = usable / n
						for i = 1, n do
							local cpos = a + d * (0.2 + (i - 0.5) * w)
							local c = chunkOf(cpos.X, cpos.Z)
							c.hoard = c.hoard or {}
							table.insert(c.hoard, { c = cpos, n = nOut, w = w - 0.02 })
						end
					end
				end
			end
		end
		-- the map folders the overlap query can't see into (visual meshes): indexed once, then as they stream in
		task.spawn(function()
			local root = Config.mapRoot and Config.mapRoot()
			if root then
				for _, n in { "Parks", "Landmarks", "Pagodas" } do
					local f = root:FindFirstChild(n)
					if f then
						watchStatic(f)
					end
				end
				local green = root:FindFirstChild("Green")
				local edges = green and green:FindFirstChild("Edges")
				if edges then
					watchStatic(edges)
				end
			end
		end)
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
			-- the lamps' lights: at night, normal quality, within LIGHT_R of the camera (phones: few lights)
			local lampsOn = isNight()
			for _, l in CollectionService:GetTagged("RoadsideLamp") do
				local h = l.Parent
				if l:IsA("Light") and h and h:IsA("BasePart") then
					l.Enabled = lampsOn and full and (h.Position - at).Magnitude < LIGHT_R
				end
			end
			-- billboards: backlit (no light influence) at night within AD_R of the camera
			for _, sg in CollectionService:GetTagged("RoadsideAd") do
				local h = sg.Parent
				if sg:IsA("SurfaceGui") and h and h:IsA("BasePart") then
					local lit = lampsOn and (h.Position - at).Magnitude < AD_R
					sg.LightInfluence = if lit then 0 else 1
					sg.Brightness = if lit then 1.3 else 1
				end
			end
			local cx, cz = math.floor(at.X / CHUNK), math.floor(at.Z / CHUNK)
			local reach = math.ceil(load / CHUNK)
			local made = 0
			for dx = -reach, reach do
				for dz = -reach, reach do
					local key = (cx + dx) .. "," .. (cz + dz)
					if built[key] == nil and made < 2 then
						local mx, mz = (cx + dx + 0.5) * CHUNK, (cz + dz + 0.5) * CHUNK
						if Vector3.new(mx - at.X, 0, mz - at.Z).Magnitude < load then
							local r = buildChunk(ctx, key, chunks[key], folder, full)
							if r ~= nil then
								built[key] = r
								made += 1
							end
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
					regPurge(key)
					built[key] = nil
				end
			end
			task.wait(if made >= 2 then 0.05 else 1)
		end
	end)
end

return YangonRoadside
