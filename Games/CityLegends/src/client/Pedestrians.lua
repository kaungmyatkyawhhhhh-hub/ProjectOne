--[[
	Pedestrians (client)
	People walking the city's and Downtown's sidewalks, and strolling Ocean Drive's beach promenade
	(owner, 2026-10-22: "a living city ... walking NPC pedestrians", smooth on mobile).

	  * a pool of simple figures (shirt, trousers, shoes, skin, hair), built once and reused: a
	    figure leaving the area goes back to the pool and comes out again somewhere new
	  * they appear only round the camera (never right in front of it), go back to the pool when far
	    away, and their number follows WorldFx.qualityScale()
	  * they walk round their block on the sidewalk, between the shop fronts and the kerb trees. At
	    a corner some wait at the kerb for the red light (CityLayout's phases) and cross to the next
	    block on the crossing; they never walk into the road anywhere else
	  * the walk is animated by hand (legs and arms swing with the stride), moved in one BulkMoveTo
	    a frame; far figures animate less often
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))

local Pedestrians = {}

local C = Config.City
local P = Config.Pedestrians
local N = C.Blocks
local B = C.BlockSize
local HALF_ROAD = C.RoadWidth / 2
local CURB = C.CurbHeight
local INNER = B - C.RoadWidth
-- the walking lines: just outside the lot, inside the kerb trees and lamps
local LANES = { INNER / 2 - 8.6, INNER / 2 - 7.3 }
local KERB_LINE = HALF_ROAD + 1.5 -- the crossing runs this far from the junction's centre
local KERB_WAIT = HALF_ROAD + 2.5 -- where they wait, along the crossing

local SKIN = {
	Color3.fromRGB(255, 220, 190), Color3.fromRGB(234, 192, 158), Color3.fromRGB(204, 156, 118),
	Color3.fromRGB(160, 112, 78), Color3.fromRGB(118, 80, 56), Color3.fromRGB(86, 58, 42),
}
local HAIR = {
	Color3.fromRGB(20, 18, 16), Color3.fromRGB(46, 32, 24), Color3.fromRGB(84, 58, 38),
	Color3.fromRGB(176, 140, 90), Color3.fromRGB(120, 60, 36), Color3.fromRGB(150, 150, 150),
}
local SHIRTS = {
	Color3.fromRGB(236, 236, 232), Color3.fromRGB(30, 34, 52), Color3.fromRGB(22, 22, 24),
	Color3.fromRGB(196, 178, 150), Color3.fromRGB(84, 94, 66), Color3.fromRGB(120, 36, 46),
	Color3.fromRGB(120, 150, 190), Color3.fromRGB(110, 112, 118), Color3.fromRGB(200, 120, 90),
	Color3.fromRGB(60, 90, 110),
}
local TROUSERS = {
	Color3.fromRGB(44, 62, 96), Color3.fromRGB(26, 26, 30), Color3.fromRGB(150, 132, 100),
	Color3.fromRGB(80, 82, 88), Color3.fromRGB(220, 216, 206), Color3.fromRGB(56, 50, 44),
}

---------------------------------------------------------------------
-- Figures
---------------------------------------------------------------------
-- part offsets from the figure's root (feet on the ground, facing -Z); limbs swing from their
-- joints. {name, size, joint (from root), offset from the joint, swing: 0 none, 1 / -1 legs,
-- 2 / -2 arms}
type PartDef = { size: Vector3, joint: Vector3, offset: Vector3, swing: number, colour: string, head: boolean? }
-- (owner, 2026-11-02: "make all of the walking npc R6 with a random face") Roblox's R6 body: a 2 x 2
-- torso, the classic head with a face, 1 x 2 arms and legs; 6 parts (was 13)
local DEFS: { PartDef } = {
	{ size = Vector3.new(2, 2, 1), joint = Vector3.new(0, 3, 0), offset = Vector3.zero, swing = 0, colour = "shirt" },
	{ size = Vector3.new(2, 1, 1), joint = Vector3.new(0, 4.5, 0), offset = Vector3.zero, swing = 0, colour = "skin", head = true },
	-- legs (hip joints)
	{ size = Vector3.new(1, 2, 1), joint = Vector3.new(-0.5, 2, 0), offset = Vector3.new(0, -1, 0), swing = 1, colour = "trousers" },
	{ size = Vector3.new(1, 2, 1), joint = Vector3.new(0.5, 2, 0), offset = Vector3.new(0, -1, 0), swing = -1, colour = "trousers" },
	-- arms (shoulder joints)
	{ size = Vector3.new(1, 2, 1), joint = Vector3.new(-1.5, 3.5, 0), offset = Vector3.new(0, -0.5, 0), swing = -2, colour = "arms" },
	{ size = Vector3.new(1, 2, 1), joint = Vector3.new(1.5, 3.5, 0), offset = Vector3.new(0, -0.5, 0), swing = 2, colour = "arms" },
}
-- Roblox's own classic faces (their images), and the default smile
local FACES = {
	"rbxasset://textures/face.png",
	"rbxassetid://7074749", "rbxassetid://7074780", "rbxassetid://7074882", "rbxassetid://7075130",
	"rbxassetid://7075412", "rbxassetid://7076096", "rbxassetid://7317606", "rbxassetid://15885042",
	"rbxassetid://7699086", "rbxassetid://7131308", "rbxassetid://7317591", "rbxassetid://7074712",
	"rbxassetid://7074827", "rbxassetid://7074932", "rbxassetid://7075459", "rbxassetid://7076053",
	"rbxassetid://7076211", "rbxassetid://8329438", "rbxassetid://10747392", "rbxassetid://12145059",
}

type Figure = { parts: { BasePart }, cfs: { CFrame }, shown: boolean, face: Decal? }

local folder: Folder? = nil
local rng = Random.new()

local function newFigure(): Figure
	local parts = {}
	local face: Decal? = nil
	for k, def in DEFS do
		local p = Instance.new("Part")
		p.Name = "Ped" .. k
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = def.size
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if def.head then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = p
			local d = Instance.new("Decal")
			d.Name = "face"
			d.Face = Enum.NormalId.Front
			d.Parent = p
			face = d
		end
		parts[k] = p
	end
	local cfs = table.create(#DEFS, CFrame.new())
	return { parts = parts, cfs = cfs, shown = false, face = face }
end

local function dress(f: Figure)
	local shirt = SHIRTS[rng:NextInteger(1, #SHIRTS)]
	local skin = SKIN[rng:NextInteger(1, #SKIN)]
	local look = {
		skin = skin,
		hair = HAIR[rng:NextInteger(1, #HAIR)],
		shirt = shirt,
		trousers = TROUSERS[rng:NextInteger(1, #TROUSERS)],
		arms = if rng:NextNumber() < 0.6 then shirt else skin, -- long sleeves or short
	}
	local scale = rng:NextNumber(0.94, 1.04)
	for k, def in DEFS do
		local p = f.parts[k]
		p.Color = look[def.colour]
		p.Size = def.size * scale
	end
	if f.face then
		f.face.Texture = FACES[rng:NextInteger(1, #FACES)]
	end
end

local function show(f: Figure, on: boolean)
	if f.shown == on then
		return
	end
	f.shown = on
	for _, p in f.parts do
		p.Parent = if on then folder else nil
	end
end

---------------------------------------------------------------------
-- Where they walk
---------------------------------------------------------------------
type Block = { base: number, bi: number, bj: number, center: Vector3 }
local blocks: { Block } = {}
local blockAt: { [string]: Block } = {}

local function blockKey(bi: number, bj: number): string
	return bi .. "," .. bj
end

for _, base in CityLayout.GridBases do
	for gi = 0, N - 1 do
		for bj = 0, N - 1 do
			local bi = base + gi
			local cx = (CityLayout.roadCoord(bi) + CityLayout.roadCoord(bi + 1)) / 2
			local cz = (CityLayout.roadCoord(bj) + CityLayout.roadCoord(bj + 1)) / 2
			local blk = { base = base, bi = bi, bj = bj, center = Vector3.new(cx, CURB, cz) }
			table.insert(blocks, blk)
			blockAt[blockKey(bi, bj)] = blk
		end
	end
end

-- the block perimeter (a square of half-size r round the centre), walked clockwise as s grows:
-- edge 0 along +X (north side), 1 along +Z (east), 2 along -X (south), 3 along -Z (west)
local CORNERS = { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1) }
local EDGE_DIR = { Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), Vector3.new(0, 0, -1) }
local EDGE_OUT = { Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0) }

local function perimeter(blk: Block, r: number, s: number): (Vector3, number)
	s = s % (8 * r)
	local edge = math.floor(s / (2 * r))
	local t = s - edge * 2 * r
	return blk.center + CORNERS[edge + 1] * r + EDGE_DIR[edge + 1] * t, edge
end

-- the junction road index for a world coordinate (x uses the block's grid)
local function roadIndexX(base: number, x: number): number
	if base == 0 then
		return math.round(x / B + N / 2)
	end
	return base + math.round((x - Config.West.DowntownX) / B + N / 2)
end
local function roadIndexZ(z: number): number
	return math.round(z / B + N / 2)
end

-- the beach promenade (Ocean Drive's sand side), two stretches either side of the causeway
local PROM_X = WestLayout.DowntownWest - 9
local PROM_Z = WestLayout.DowntownHalfZ - 20
local promY: number? = nil -- found by a ray the first time someone walks there

---------------------------------------------------------------------
-- Walkers
---------------------------------------------------------------------
type Walker = {
	fig: Figure,
	mode: string, -- "block" | "cross" | "wait" | "prom" | "pause"
	blk: Block?,
	r: number,
	s: number,
	way: number, -- +1 clockwise, -1 the other way
	speed: number,
	phase: number,
	pos: Vector3,
	yaw: number,
	-- crossing: the waypoints and the block it ends on
	path: { Vector3 }?,
	pathK: number,
	nextBlk: Block?,
	nextS: number,
	light: { number }?, -- i, j of the junction
	axis: string,
	timer: number,
	promDir: number,
	promZ0: number,
	promZ1: number,
	lastEdge: number,
	animAcc: number,
	rivPath: { Vector3 }?, -- Monaco: the pavement line it walks (its points), and where on it
	rivK: number?,
}

local pool: { Figure } = {}
local active: { Walker } = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function getFigure(): Figure
	local f = table.remove(pool) or newFigure()
	dress(f)
	return f
end

local function retire(k: number)
	local w = active[k]
	show(w.fig, false)
	table.insert(pool, w.fig)
	active[k] = active[#active]
	active[#active] = nil
end

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

-- at a corner: maybe wait and cross straight on to the next block
local function tryCross(w: Walker, edge: number, cornerPos: Vector3): boolean
	local blk = w.blk :: Block
	if rng:NextNumber() > P.CrossChance then
		return false
	end
	local dir = EDGE_DIR[edge + 1] * w.way
	local nrm = EDGE_OUT[edge + 1]
	local nb = blockAt[blockKey(blk.bi + math.round(dir.X), blk.bj + math.round(dir.Z))]
	if not nb or nb.base ~= blk.base then
		return false
	end
	-- the junction in that corner
	local off = B / 2 - w.r
	local junction = cornerPos + dir * off + nrm * off
	local kerb = Vector3.new(junction.X, CURB, junction.Z) - nrm * KERB_LINE
	local nearSide = kerb - dir * KERB_WAIT
	local farSide = kerb + dir * KERB_WAIT
	local arrive = cornerPos + dir * (2 * off)
	w.path = { nearSide, farSide, Vector3.new(arrive.X, CURB, arrive.Z) }
	w.pathK = 1
	w.nextBlk = nb
	-- the same edge on the next block, from its start (clockwise) or its end
	-- (a hair inside the edge, so arriving isn't taken for another corner)
	w.nextS = if w.way > 0 then edge * 2 * w.r + 0.05 else (edge + 1) * 2 * w.r - 0.05
	w.light = { roadIndexX(blk.base, junction.X), roadIndexZ(junction.Z) }
	-- the road being crossed runs along nrm: its traffic moves along that axis
	w.axis = if math.abs(nrm.X) > 0.5 then "X" else "Z"
	w.mode = "cross"
	return true
end

local function stepBlock(w: Walker, dt: number)
	local blk = w.blk :: Block
	local before = w.s
	w.s += w.speed * dt * w.way
	local L = 8 * w.r
	-- passed a corner?
	local side = 2 * w.r
	local e0 = math.floor((before % L) / side)
	local e1 = math.floor((w.s % L) / side)
	if e0 ~= e1 then
		local cornerS = if w.way > 0 then e1 * side else e0 * side
		local cornerPos = perimeter(blk, w.r, cornerS)
		local edge = if w.way > 0 then e0 else e0 -- the edge we were walking
		if tryCross(w, edge, Vector3.new(cornerPos.X, CURB, cornerPos.Z)) then
			w.s = cornerS
			w.pos = Vector3.new(cornerPos.X, CURB, cornerPos.Z)
			return
		elseif rng:NextNumber() < 0.06 then
			w.mode = "pause"
			w.timer = rng:NextNumber(2, 6)
		end
	end
	local p, edge = perimeter(blk, w.r, w.s)
	w.pos = Vector3.new(p.X, CURB, p.Z)
	local dir = EDGE_DIR[edge + 1] * w.way
	w.yaw = math.atan2(-dir.X, -dir.Z)
	w.lastEdge = edge
end

local function stepCross(w: Walker, dt: number)
	local path = w.path :: { Vector3 }
	local target = path[w.pathK]
	-- at the near kerb: wait for the cars to have red, with time to get over
	if w.pathK == 2 and w.mode == "wait" then
		local light = w.light :: { number }
		local t = serverNow()
		local need = (KERB_WAIT * 2) / P.CrossSpeed + 0.5
		if CityLayout.lightState(light[1], light[2], w.axis, t) == "R" and CityLayout.lightTimeLeft(light[1], light[2], w.axis, t) > need then
			w.mode = "cross"
		else
			w.phase = 0
			return
		end
	end
	local to = target - w.pos
	local flat = Vector3.new(to.X, 0, to.Z)
	local speed = if w.pathK == 2 then P.CrossSpeed else w.speed
	local step = speed * dt
	if flat.Magnitude <= step then
		w.pos = target
		w.pathK += 1
		if w.pathK == 2 then
			w.mode = "wait"
		elseif w.pathK > #path then
			w.blk = w.nextBlk
			w.s = w.nextS
			w.path = nil
			w.mode = "block"
		end
		return
	end
	local dir = flat.Unit
	-- down off the kerb onto the road and back up
	local rel = math.abs((w.pos - path[1]):Dot(dir) - KERB_WAIT)
	local y = if w.pathK == 2 and rel < HALF_ROAD then 0.05 else CURB
	w.pos = Vector3.new(w.pos.X + dir.X * step, y, w.pos.Z + dir.Z * step)
	w.yaw = math.atan2(-dir.X, -dir.Z)
end

local function stepProm(w: Walker, dt: number)
	local z = w.pos.Z + w.promDir * w.speed * dt
	if z > w.promZ1 or z < w.promZ0 then
		w.promDir = -w.promDir
		z = math.clamp(z, w.promZ0, w.promZ1)
		if rng:NextNumber() < 0.4 then
			w.mode = "pause"
			w.timer = rng:NextNumber(3, 8)
		end
	end
	w.pos = Vector3.new(w.pos.X, w.pos.Y, z)
	w.yaw = if w.promDir > 0 then math.pi else 0
end

---------------------------------------------------------------------
-- Monaco (the Riviera, owner 2026-11-02: "the city monaco is kinda dead right now"): people on its
-- pavements, walking along a road's pavement line (from the traffic lanes, out past the kerb) and
-- turning back where the pavement stops (a junction mouth, a wall)
---------------------------------------------------------------------
local rivPaths: { { Vector3 } }? = nil
local TOWN_TOP = 92 -- studs up: the busy town ends here (Town Road and the top streets reach ~85)
local function rivieraPaths(): { { Vector3 } }
	if rivPaths then
		return rivPaths
	end
	local list = {}
	if workspace:FindFirstChild("Riviera") then
		local ok, data = pcall(function()
			return require(Shared:WaitForChild("RivieraLanes", 3))
		end)
		if ok and type(data) == "table" then
			for _, l in data.lanes do
				-- (owner, 2026-11-03: "dont add walking npc near the summits but npc in the busy city
				-- area is fine"): no one on the hill roads up to the summits, nor above the town
				local hill = l.road == "Mountain Road" or string.find(l.road or "", "Hairpin") ~= nil
					or string.find(l.road or "", "Terrace") ~= nil or string.find(l.road or "", "Switchbacks") ~= nil
				if l.lane == 2 and not hill then -- the outer lane, 24 right of the centre: the pavement is 13 further
					local pts = l.pts
					local n = #pts // 3
					local path = {}
					for k = 1, n do
						local a = Vector3.new(pts[3 * k - 2], pts[3 * k - 1], pts[3 * k])
						local b = if k < n then Vector3.new(pts[3 * k + 1], pts[3 * k + 2], pts[3 * k + 3]) else a
						local pa = if k > 1 then Vector3.new(pts[3 * k - 5], pts[3 * k - 4], pts[3 * k - 3]) else a
						local d = (b - pa) * Vector3.new(1, 0, 1)
						if a.Y > TOWN_TOP then
							-- (a climb past the town's top: the path stops there, a new one starts below)
							if #path > 3 then
								table.insert(list, path)
							end
							path = {}
						elseif d.Magnitude > 0.1 then
							local right = Vector3.new(-d.Z, 0, d.X).Unit
							table.insert(path, a + right * 13 + Vector3.new(0, 0.35, 0))
						end
					end
					if #path > 3 then
						table.insert(list, path)
					end
				end
			end
		end
	end
	rivPaths = list
	return list
end

local rivRay = RaycastParams.new()
rivRay.FilterType = Enum.RaycastFilterType.Include
local rivRoads: Instance? = nil
-- the pavement's height at a point: a number on pavement, false on anything else (road, kerb,
-- nothing), nil when that part of the map isn't streamed in yet (not known)
local function pavementAt(p: Vector3): number | boolean | nil
	if not rivRoads then
		local r = workspace:FindFirstChild("Riviera")
		rivRoads = r and r:FindFirstChild("Roads")
		if not rivRoads then
			return nil
		end
		rivRay.FilterDescendantsInstances = { rivRoads }
	end
	local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -12, 0), rivRay)
	if not hit then
		return nil
	end
	return if hit.Instance.Name == "Pavement" then hit.Position.Y else false
end

-- (owner, 2026-11-02: "let them walk on each lane. I see an npc walking on a different lane") a
-- walker only ever steps along a piece of pavement line that is pavement all the way (both ends and
-- the middle, checked once and remembered), so nobody wanders onto the road at a bend, a narrowed
-- stretch or a junction mouth; at the end of the pavement they turn back
local segOk: { [{ Vector3 }]: { [number]: boolean } } = {}
local pointY: { [{ Vector3 }]: { [number]: number } } = {}
local function segmentOk(path: { Vector3 }, i: number, j: number): boolean
	local lo = math.min(i, j)
	local cache = segOk[path]
	if not cache then
		cache = {}
		segOk[path] = cache
	end
	local known = cache[lo]
	if known ~= nil then
		return known
	end
	local a, b = path[lo], path[lo + 1]
	if not (a and b) then
		return false
	end
	local ya, ym, yb = pavementAt(a), pavementAt((a + b) / 2), pavementAt(b)
	if ya == nil or ym == nil or yb == nil then
		return false -- not streamed in: not walkable for now (not remembered)
	end
	local ok = type(ya) == "number" and type(ym) == "number" and type(yb) == "number"
	cache[lo] = ok
	return ok
end

-- spawn spots: the pavement lines' points in 200-stud cells, so a spawn only looks at its own area
local rivCells: { [string]: { { any } } }? = nil
local function rivCellKey(x: number, z: number): string
	return math.floor(x / 200) .. "," .. math.floor(z / 200)
end

local function stepRiv(w: Walker, dt: number)
	local path = w.rivPath :: { Vector3 }
	local k = w.rivK :: number
	local nextI = k + w.way
	local b = path[nextI]
	if not b or not segmentOk(path, k, nextI) then
		w.way = -w.way
		if rng:NextNumber() < 0.3 then
			w.mode = "pause"
			w.timer = rng:NextNumber(2, 6)
		end
		return
	end
	-- (the pavement's height at each point, found once)
	local ys = pointY[path]
	if not ys then
		ys = {}
		pointY[path] = ys
	end
	local y = ys[nextI]
	if y == nil then
		local found = pavementAt(b)
		y = if type(found) == "number" then found else w.pos.Y
		ys[nextI] = y
	end
	local to = Vector3.new(b.X, y, b.Z)
	local flat = (to - w.pos) * Vector3.new(1, 0, 1)
	local stepD = w.speed * dt
	if flat.Magnitude <= stepD then
		w.pos = to
		w.rivK = nextI
	else
		w.pos = w.pos:Lerp(to, stepD / flat.Magnitude)
	end
	if flat.Magnitude > 0.05 then
		local dir = flat.Unit
		w.yaw = math.atan2(-dir.X, -dir.Z)
	end
end

-- pose the figure: legs and arms swing with the stride
local function pose(w: Walker, moving: boolean)
	local fig = w.fig
	local root = CFrame.new(w.pos) * CFrame.Angles(0, w.yaw, 0)
	local swing = if moving then math.sin(w.phase) else 0
	local bob = if moving then math.abs(math.cos(w.phase)) * 0.08 else 0
	root += Vector3.new(0, bob, 0)
	for k, def in DEFS do
		local a = 0
		if def.swing == 1 or def.swing == -1 then
			a = swing * 0.55 * def.swing
		elseif def.swing ~= 0 then
			a = swing * 0.45 * (def.swing / 2)
		end
		fig.cfs[k] = root * CFrame.new(def.joint) * CFrame.Angles(a, 0, 0) * CFrame.new(def.offset)
	end
	workspace:BulkMoveTo(fig.parts, fig.cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

---------------------------------------------------------------------
-- Spawning round the camera
---------------------------------------------------------------------
local function flatDist(a: Vector3, b: Vector3): number
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function spawnRiv(camPos: Vector3): boolean
	local paths = rivieraPaths()
	if #paths == 0 then
		return false
	end
	if not rivCells then
		local cells = {}
		for _, pth in paths do
			for i = 1, #pth - 1 do
				local key = rivCellKey(pth[i].X, pth[i].Z)
				cells[key] = cells[key] or {}
				table.insert(cells[key], { pth, i })
			end
		end
		rivCells = cells
	end
	-- a point within reach of the camera: from the cells round it
	local reach = math.ceil(P.SpawnRadius / 200)
	local cx, cz = math.floor(camPos.X / 200), math.floor(camPos.Z / 200)
	local pick = nil
	for _ = 1, 4 do
		local cell = (rivCells :: any)[(cx + rng:NextInteger(-reach, reach)) .. "," .. (cz + rng:NextInteger(-reach, reach))]
		if cell then
			local c = cell[rng:NextInteger(1, #cell)]
			local d = flatDist(c[1][c[2]], camPos)
			if d >= P.MinSpawnGap and d <= P.SpawnRadius and segmentOk(c[1], c[2], c[2] + 1) then
				pick = c
				break
			end
		end
	end
	if not pick then
		return false
	end
	local path, k = pick[1], pick[2]
	local p = path[k]
	local y = pavementAt(p)
	if type(y) ~= "number" then
		return false
	end
	local fig = getFigure()
	local w: Walker = {
		fig = fig, mode = "riv", blk = nil, r = 0, s = 0, way = 1,
		speed = rng:NextNumber(P.WalkSpeed[1], P.WalkSpeed[2]), phase = rng:NextNumber(0, 6),
		pos = Vector3.new(p.X, y, p.Z), yaw = 0, path = nil, pathK = 0, nextBlk = nil, nextS = 0,
		light = nil, axis = "X", timer = 0, promDir = 1, promZ0 = 0, promZ1 = 0, lastEdge = 0, animAcc = 0,
		rivPath = path, rivK = k,
	}
	show(fig, true)
	table.insert(active, w)
	return true
end

local function spawnOne(camPos: Vector3): boolean
	-- in Monaco: its pavements
	if camPos.X > 10500 and workspace:FindFirstChild("Riviera") then
		return spawnRiv(camPos)
	end
	-- the beach promenade now and then, when the camera is near it
	local nearProm = math.abs(camPos.X - PROM_X) < P.SpawnRadius and math.abs(camPos.Z) < PROM_Z + P.SpawnRadius
	if nearProm and rng:NextNumber() < 0.3 then
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local z0, z1 = if side < 0 then -PROM_Z else 40, if side < 0 then -40 else PROM_Z
		local z = math.clamp(camPos.Z + rng:NextNumber(-P.SpawnRadius, P.SpawnRadius), z0, z1)
		local x = PROM_X + rng:NextNumber(-3, 3)
		local p = Vector3.new(x, 0, z)
		if flatDist(p, camPos) < P.MinSpawnGap then
			return false
		end
		if not promY then
			local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), rayParams)
			if not hit then
				return false -- nothing there to walk on
			end
			promY = hit.Position.Y
		end
		local fig = getFigure()
		local w: Walker = {
			fig = fig, mode = "prom", blk = nil, r = 0, s = 0, way = 1,
			speed = rng:NextNumber(P.WalkSpeed[1], P.WalkSpeed[2]) * 0.8, phase = rng:NextNumber(0, 6),
			pos = Vector3.new(x, promY :: number, z), yaw = 0, path = nil, pathK = 0, nextBlk = nil, nextS = 0,
			light = nil, axis = "X", timer = 0, promDir = if rng:NextNumber() < 0.5 then 1 else -1,
			promZ0 = z0, promZ1 = z1, lastEdge = 0, animAcc = 0,
		}
		show(fig, true)
		table.insert(active, w)
		return true
	end
	-- a block near the camera
	local candidates = {}
	for _, blk in blocks do
		if flatDist(blk.center, camPos) < P.SpawnRadius + B / 2 then
			table.insert(candidates, blk)
		end
	end
	if #candidates == 0 then
		return false
	end
	local blk = candidates[rng:NextInteger(1, #candidates)]
	local r = LANES[rng:NextInteger(1, #LANES)]
	local s = rng:NextNumber(0, 8 * r)
	local p = perimeter(blk, r, s)
	local d = flatDist(p, camPos)
	if d < P.MinSpawnGap or d > P.SpawnRadius then
		return false
	end
	local fig = getFigure()
	local w: Walker = {
		fig = fig, mode = "block", blk = blk, r = r, s = s, way = if rng:NextNumber() < 0.5 then 1 else -1,
		speed = rng:NextNumber(P.WalkSpeed[1], P.WalkSpeed[2]), phase = rng:NextNumber(0, 6),
		pos = Vector3.new(p.X, CURB, p.Z), yaw = 0, path = nil, pathK = 0, nextBlk = nil, nextS = 0,
		light = nil, axis = "X", timer = 0, promDir = 1, promZ0 = 0, promZ1 = 0, lastEdge = 0, animAcc = 0,
	}
	show(fig, true)
	table.insert(active, w)
	return true
end

function Pedestrians.start(qualityScale: number)
	if folder then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "Pedestrians"
	f.Parent = workspace
	folder = f
	rayParams.FilterDescendantsInstances = { f }
	local target = math.floor(P.Max * math.clamp(qualityScale, 0.4, 1.05))
	local camera = workspace.CurrentCamera
	local spawnAcc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		local camPos = camera.CFrame.Position
		-- high up (helicopter tour, telescope, menus over the city): fewer people
		local want = if camPos.Y > 260 then math.floor(target / 3) else target
		spawnAcc += dt
		if spawnAcc > 0.2 then
			spawnAcc = 0
			local tries = 0
			while #active < want and tries < 4 do
				tries += 1
				spawnOne(camPos)
			end
		end
		local k = 1
		while k <= #active do
			local w = active[k]
			local dist = flatDist(w.pos, camPos)
			if dist > P.CullRadius or #active > want + 4 then
				retire(k)
				continue
			end
			local moving = true
			if w.mode == "block" then
				stepBlock(w, dt)
			elseif w.mode == "cross" or w.mode == "wait" then
				stepCross(w, dt)
				moving = w.mode ~= "wait"
			elseif w.mode == "prom" then
				stepProm(w, dt)
			elseif w.mode == "riv" then
				stepRiv(w, dt)
			elseif w.mode == "pause" then
				moving = false
				w.timer -= dt
				if w.timer <= 0 then
					w.mode = if w.blk then "block" elseif w.rivPath then "riv" else "prom"
				end
			end
			if moving then
				w.phase += dt * w.speed * 1.45
			end
			-- near figures animate every frame, far ones a few times a second
			w.animAcc += dt
			-- (lighter: owner, 2026-11-02 "optimize the walking npc so that the game wont lag")
			local every = if dist < 70 then 0 elseif dist < 160 then 0.1 else 0.25
			if w.animAcc >= every then
				w.animAcc = 0
				pose(w, moving)
			end
			k += 1
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function(char)
		rayParams.FilterDescendantsInstances = { f, char }
	end)
end

return Pedestrians
