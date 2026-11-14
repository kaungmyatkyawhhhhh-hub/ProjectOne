--[[
	YangonStreetLife (client, 2026-11-14)
	Owner: "the ingame yangon is too clean compared to real life yangon". Parked cars along the kerbs and people on the
	pavements, round the camera only, from src/shared/YangonStreetLife*.lua (tools/yangon/city/streetlife.py: car spots,
	standing spots, pavement paths; one string of lines per module). Does nothing outside Yangon.

	  * parked cars: TrafficBodies' low-poly bodies (anchored root = the one collidable box, no lights, no shadows),
	    pooled. Every Config.YangonStreetLife.CarCheck seconds the spots within CarRadius of the camera (a 128-stud
	    grid, never a full scan) fill up to CarMax, nearest first; a car goes back to the pool past CarKeep. 70% are
	    repainted white / silver / grey (Yangon's Probox / Mark II / Hiace look), half up on the pavement on main roads.
	  * people: 8 parts each (shirt, head with a face, hair, longyi, two arms, two feet), men in longyi and shirt,
	    women in htamein and blouse, monks in maroon robes now and then (more near monasteries and pagodas), kids in
	    the green and white school uniform near schools. They walk the pavement paths at 3-5 studs a second and turn
	    back where the pavement ends, or stand at bus stops, tea shops and shop fronts. Anchored, no collisions, moved
	    with BulkMoveTo: near ones a few dozen times a second, far ones a few times. At most PedMax within PedRadius.
	  * counts follow the graphics setting: qualityScale() at or under LowScale (Low) halves them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TrafficBodies = require(script.Parent:WaitForChild("TrafficBodies"))

local YangonStreetLife = {}

local CELL = 128
local function cellKey(gx: number, gz: number): number
	return gx * 1024 + gz
end

local started = false
local rng = Random.new()
local carFolder: Folder? = nil
local pedFolder: Folder? = nil

---------------------------------------------------------------------
-- Data
---------------------------------------------------------------------
-- cars (parallel arrays)
local carX, carY, carZ, carYaw, carKind, carCol, carUp = {}, {}, {}, {}, {}, {}, {}
local carCells: { [number]: { number } } = {}
-- standing spots
local spotPos: { Vector3 } = {}
local spotYaw: { number } = {}
local spotKind: { string } = {}
local spotCells: { [number]: { number } } = {}
-- pavement paths: points, and the cells' (path, point) pairs
local paths: { { Vector3 } } = {}
local pathWide: { boolean } = {}
local pathCells: { [number]: { number } } = {} -- flat: path, point, path, point ...
local schools: { Vector2 } = {}
local worship: { Vector2 } = {}

local function addCell(cells: { [number]: { number } }, x: number, z: number, ...: number)
	local key = cellKey(math.floor(x / CELL), math.floor(z / CELL))
	local list = cells[key]
	if not list then
		list = {}
		cells[key] = list
	end
	for _, v in { ... } do
		table.insert(list, v)
	end
end

local function loadChunks(): ({ string }, number, number)
	local chunks = {}
	local first = Shared:FindFirstChild("YangonStreetLife") or Shared:WaitForChild("YangonStreetLife", 10)
	if not first then
		warn("[CityLegends] YangonStreetLife: no data module")
		return chunks, 0, 0
	end
	local ok, mod = pcall(require, first)
	if not ok or type(mod) ~= "table" then
		warn("[CityLegends] YangonStreetLife: data failed:", mod)
		return chunks, 0, 0
	end
	table.insert(chunks, mod.data)
	for _, name in mod.more or {} do
		local m = Shared:FindFirstChild(name) or Shared:WaitForChild(name, 10)
		local ok2, s = false, nil
		if m then
			ok2, s = pcall(require, m)
		end
		if ok2 and type(s) == "string" then
			table.insert(chunks, s)
		else
			warn("[CityLegends] YangonStreetLife: part " .. name .. " missing or failed")
		end
	end
	return chunks, mod.origin[1], mod.origin[2]
end

local function parse()
	local chunks, OX, OZ = loadChunks()
	local n = 0
	for _, chunk in chunks do
		for line in string.gmatch(chunk, "[^\n]+") do
			n += 1
			if n % 400 == 0 then
				task.wait()
			end
			local b = string.split(line, " ")
			local tag = b[1]
			if tag == "C" then
				local x, z = tonumber(b[2]) / 10 + OX, tonumber(b[3]) / 10 + OZ
				table.insert(carX, x)
				table.insert(carZ, z)
				table.insert(carY, tonumber(b[4]) / 10)
				table.insert(carYaw, math.rad(tonumber(b[5]) / 10))
				table.insert(carKind, b[6])
				table.insert(carCol, tonumber(b[7]))
				table.insert(carUp, tonumber(b[8]))
				addCell(carCells, x, z, #carX)
			elseif tag == "S" then
				local x, z = tonumber(b[2]) / 10 + OX, tonumber(b[3]) / 10 + OZ
				table.insert(spotPos, Vector3.new(x, tonumber(b[4]) / 10, z))
				table.insert(spotYaw, math.rad(tonumber(b[5]) / 10))
				table.insert(spotKind, b[6])
				addCell(spotCells, x, z, #spotPos)
			elseif tag == "K" then
				table.insert(schools, Vector2.new(tonumber(b[2]) / 10 + OX, tonumber(b[3]) / 10 + OZ))
			elseif tag == "W" then
				table.insert(worship, Vector2.new(tonumber(b[2]) / 10 + OX, tonumber(b[3]) / 10 + OZ))
			elseif tag == "P" then
				local count = tonumber(b[3]) :: number
				local x, z, y = tonumber(b[4]) :: number, tonumber(b[5]) :: number, tonumber(b[6]) :: number
				local pts = table.create(count)
				pts[1] = Vector3.new(x / 10 + OX, y / 10, z / 10 + OZ)
				for k = 2, count do
					local j = 4 + 3 * (k - 1)
					x += tonumber(b[j]) :: number
					z += tonumber(b[j + 1]) :: number
					y += tonumber(b[j + 2]) :: number
					pts[k] = Vector3.new(x / 10 + OX, y / 10, z / 10 + OZ)
				end
				table.insert(paths, pts)
				table.insert(pathWide, b[2] == "m")
				local pi = #paths
				-- every point, plus points every ~24 studs along long straight pieces (so the cells near them know them)
				for k = 1, count - 1 do
					local a, c = pts[k], pts[k + 1]
					local L = (c - a).Magnitude
					addCell(pathCells, a.X, a.Z, pi, k)
					local steps = math.floor(L / 24)
					for s = 1, steps do
						local q = a:Lerp(c, s / (steps + 1))
						addCell(pathCells, q.X, q.Z, pi, k)
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Parked cars
---------------------------------------------------------------------
-- 1-6 white / silver / grey (70% of the spots), 7-10 black, dark blue, maroon, champagne; 11 = the model's own paint
local PAINT = {
	Color3.fromRGB(242, 242, 238), Color3.fromRGB(232, 232, 226), Color3.fromRGB(196, 198, 200),
	Color3.fromRGB(172, 176, 180), Color3.fromRGB(132, 136, 140), Color3.fromRGB(92, 96, 100),
	Color3.fromRGB(30, 30, 32), Color3.fromRGB(36, 52, 90), Color3.fromRGB(106, 32, 38), Color3.fromRGB(196, 182, 150),
}
local WHEEL_GROUP = { FL = true, FR = true, RL = true, RR = true }
local ROLL = math.atan(0.5 / 5.6) -- half up on a 0.5 kerb
local LENGTH = Config.Traffic.ModelLengths

type CarInfo = { paint: { MeshPart }, tex: { [MeshPart]: string }, sa: { [MeshPart]: SurfaceAppearance }, h: number, col: number, kind: string }
local info: { [Model]: CarInfo } = {}
local carPool: { [string]: { Model } } = {}
local live: { [number]: Model } = {}
local liveCount = 0
local built = 0
local warned = false

local function setupCar(m: Model, kind: string): CarInfo
	local root = m.PrimaryPart
	local ci: CarInfo = { paint = {}, tex = {}, sa = {}, h = (m:GetAttribute("Height") :: number?) or 5, col = 11, kind = kind }
	for _, d in m:GetDescendants() do
		if d:IsA("Light") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.CastShadow = false
			if d == root then
				d.Anchored = true
				d.CanCollide = true
				d.CanQuery = true
				d.CanTouch = false
			else
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				if d:GetAttribute("TailLight") then
					d.Material = Enum.Material.SmoothPlastic
					d.Color = Color3.fromRGB(150, 0, 6)
				end
				local group = d.Parent and string.match(d.Parent.Name, "^(%a+)")
				if d:IsA("MeshPart") and not (group and WHEEL_GROUP[group]) then
					local sa = d:FindFirstChildOfClass("SurfaceAppearance")
					if d.TextureID ~= "" or sa then
						table.insert(ci.paint, d)
						ci.tex[d] = d.TextureID
						if sa then
							ci.sa[d] = sa
						end
					end
				end
			end
		end
	end
	info[m] = ci
	return ci
end

local function paint(m: Model, col: number)
	local ci = info[m]
	if not Config.YangonStreetLife.Repaint or ci.col == col then
		return
	end
	ci.col = col
	local own = col > #PAINT
	for _, p in ci.paint do
		if own then
			p.TextureID = ci.tex[p]
			local sa = ci.sa[p]
			if sa then
				sa.Parent = p
			end
		else
			p.TextureID = ""
			local sa = ci.sa[p]
			if sa then
				sa.Parent = nil
			end
			p.Color = PAINT[col]
		end
	end
end

local function takeCar(kind: string, cap: number): Model?
	local list = carPool[kind]
	if list and #list > 0 then
		return table.remove(list)
	end
	if built < cap + 30 then
		local m = TrafficBodies.buildType(kind, rng)
		if m and m.PrimaryPart then
			built += 1
			setupCar(m, kind)
			return m
		end
		if not warned then
			warned = true
			warn("[CityLegends] YangonStreetLife: no TrafficModels for parked cars")
		end
		return nil
	end
	-- enough bodies made: an idle one no longer than the spot was made for (the spots are spaced for their kind)
	local best, bestL = nil, -1
	for k, l in carPool do
		local L = LENGTH[k] or 99
		if #l > 0 and L <= (LENGTH[kind] or 99) and L > bestL then
			best, bestL = l, L
		end
	end
	return if best then table.remove(best) else nil
end

local function releaseCar(i: number)
	local m = live[i]
	live[i] = nil
	liveCount -= 1
	m.Parent = nil
	local kind = info[m].kind
	carPool[kind] = carPool[kind] or {}
	table.insert(carPool[kind], m)
end

local function fillCar(i: number, cap: number): boolean
	local m = takeCar(carKind[i], cap)
	if not m then
		return false
	end
	paint(m, carCol[i])
	local ci = info[m]
	local up = carUp[i]
	local cf = CFrame.new(carX[i], carY[i] + ci.h / 2 + (if up ~= 0 then 0.25 else 0), carZ[i]) * CFrame.Angles(0, carYaw[i], 0)
	if up ~= 0 then
		cf *= CFrame.Angles(0, 0, up * ROLL)
	end
	m:PivotTo(cf)
	m.Parent = carFolder
	live[i] = m
	liveCount += 1
	return true
end

local candI: { number } = {}
local candD: { [number]: number } = {}
local wanted: { [number]: boolean } = {}

local function carTick(cam: Vector3, cap: number)
	local cfg = Config.YangonStreetLife
	local keep2, fill2 = cfg.CarKeep * cfg.CarKeep, cfg.CarRadius * cfg.CarRadius
	table.clear(candI)
	table.clear(candD)
	table.clear(wanted)
	if cam.Y < 1200 then -- (not from the dealer's stage and other rooms high over the map)
		local r = math.ceil(cfg.CarKeep / CELL)
		local gx0, gz0 = math.floor(cam.X / CELL), math.floor(cam.Z / CELL)
		for gx = gx0 - r, gx0 + r do
			for gz = gz0 - r, gz0 + r do
				local list = carCells[cellKey(gx, gz)]
				if list then
					for _, i in list do
						local dx, dz = carX[i] - cam.X, carZ[i] - cam.Z
						local d2 = dx * dx + dz * dz
						if d2 <= keep2 then
							table.insert(candI, i)
							candD[i] = d2
						end
					end
				end
			end
		end
	end
	if #candI > cap then
		table.sort(candI, function(a, b)
			return candD[a] < candD[b]
		end)
	end
	for k = 1, math.min(cap, #candI) do
		local i = candI[k]
		if live[i] or candD[i] <= fill2 then
			wanted[i] = true
		end
	end
	for i in live do
		if not wanted[i] then
			releaseCar(i)
		end
	end
	local builds = 0
	for k = 1, math.min(cap, #candI) do
		local i = candI[k]
		if wanted[i] and not live[i] then
			local fresh = built
			if fillCar(i, cap) and built > fresh then
				builds += 1
				if builds >= cfg.CarBuildsPerTick then
					break
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- People
---------------------------------------------------------------------
local SKIN = {
	Color3.fromRGB(226, 186, 148), Color3.fromRGB(210, 166, 126), Color3.fromRGB(192, 146, 106),
	Color3.fromRGB(170, 124, 86), Color3.fromRGB(146, 102, 68),
}
local MEN_SHIRT = {
	Color3.fromRGB(240, 240, 236), Color3.fromRGB(240, 240, 236), Color3.fromRGB(178, 200, 224), Color3.fromRGB(232, 222, 196),
	Color3.fromRGB(150, 152, 156), Color3.fromRGB(40, 50, 80), Color3.fromRGB(120, 40, 46), Color3.fromRGB(110, 116, 80),
}
local MEN_LONGYI = { -- paso: dark checks and plains
	Color3.fromRGB(44, 74, 56), Color3.fromRGB(36, 46, 76), Color3.fromRGB(96, 70, 52), Color3.fromRGB(104, 40, 46),
	Color3.fromRGB(70, 84, 104), Color3.fromRGB(34, 34, 38), Color3.fromRGB(60, 96, 70),
}
local WOMEN_TOP = { -- eingyi
	Color3.fromRGB(244, 244, 240), Color3.fromRGB(232, 168, 180), Color3.fromRGB(240, 222, 150), Color3.fromRGB(164, 196, 230),
	Color3.fromRGB(190, 170, 214), Color3.fromRGB(240, 190, 150), Color3.fromRGB(176, 220, 196),
}
local WOMEN_LONGYI = { -- htamein: bright
	Color3.fromRGB(170, 40, 100), Color3.fromRGB(100, 50, 120), Color3.fromRGB(30, 110, 120), Color3.fromRGB(196, 150, 60),
	Color3.fromRGB(170, 40, 40), Color3.fromRGB(40, 70, 150), Color3.fromRGB(30, 120, 80),
}
local ROBE = { Color3.fromRGB(122, 36, 34), Color3.fromRGB(138, 50, 38), Color3.fromRGB(110, 34, 40) }
local UNIFORM_TOP, UNIFORM_LONGYI = Color3.fromRGB(244, 244, 240), Color3.fromRGB(34, 110, 60)
local HAIR = Color3.fromRGB(20, 18, 16)
local SANDAL = Color3.fromRGB(60, 44, 34)
-- Roblox's own classic faces (as Pedestrians)
local FACES = {
	"rbxasset://textures/face.png",
	"rbxassetid://7074749", "rbxassetid://7074780", "rbxassetid://7074882", "rbxassetid://7075130",
	"rbxassetid://7075412", "rbxassetid://7076096", "rbxassetid://7317606", "rbxassetid://15885042",
	"rbxassetid://7699086", "rbxassetid://7131308", "rbxassetid://7317591", "rbxassetid://7074712",
	"rbxassetid://7074827", "rbxassetid://7074932", "rbxassetid://7075459", "rbxassetid://7076053",
}

-- the parts (feet on the ground, facing -Z): 1 shirt, 2 head, 3 hair, 4 longyi, 5 / 6 arms, 7 / 8 feet
local SIZES = {
	Vector3.new(2, 2, 1), Vector3.new(2, 1, 1), Vector3.new(1.32, 0.32, 1.32), Vector3.new(2, 1.75, 1.1),
	Vector3.new(1, 2, 1), Vector3.new(1, 2, 1), Vector3.new(0.8, 0.35, 1), Vector3.new(0.8, 0.35, 1),
}
local HAIR_SHORT, HAIR_SHORT_AT = Vector3.new(1.32, 0.32, 1.32), Vector3.new(0, 5.05, 0.02)
local HAIR_LONG, HAIR_LONG_AT = Vector3.new(1.34, 1.25, 0.9), Vector3.new(0, 4.75, 0.3)

type Figure = { model: Model, parts: { BasePart }, cfs: { CFrame }, face: Decal, scale: number, hairAt: Vector3, bald: boolean }
type Walker = {
	fig: Figure, mode: string, path: { Vector3 }?, k: number, dir: number, pos: Vector3, yaw: number, speed: number,
	lat: number, phase: number, acc: number, timer: number, spot: number?,
}

local figPool: { Figure } = {}
local active: { Walker } = {}
local spotBusy: { [number]: boolean } = {}

local function newFigure(): Figure
	local model = Instance.new("Model")
	model.Name = "Person"
	local parts = {}
	local face: Decal = nil :: any
	for k, size in SIZES do
		local p = Instance.new("Part")
		p.Name = "P" .. k
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		if k == 2 then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = p
			face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Parent = p
		elseif k == 4 then
			p.Material = Enum.Material.Fabric
		end
		p.Parent = model
		parts[k] = p
	end
	return { model = model, parts = parts, cfs = table.create(#SIZES, CFrame.new()), face = face, scale = 1, hairAt = HAIR_SHORT_AT, bald = false }
end

local function pick<T>(list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

local function nearAny(list: { Vector2 }, x: number, z: number, r: number): boolean
	local r2 = r * r
	for _, v in list do
		local dx, dz = v.X - x, v.Y - z
		if dx * dx + dz * dz < r2 then
			return true
		end
	end
	return false
end

-- who: "man", "woman", "monk", "kid"
local function whoAt(x: number, z: number): string
	local r = rng:NextNumber()
	if #schools > 0 and nearAny(schools, x, z, 160) and r < 0.45 then
		return "kid"
	end
	if #worship > 0 and nearAny(worship, x, z, 200) and r < 0.25 then
		return "monk"
	end
	if r < 0.04 then
		return "monk"
	elseif r < 0.09 then
		return "kid"
	end
	return if rng:NextNumber() < 0.5 then "man" else "woman"
end

local function dress(f: Figure, who: string)
	local skin = pick(SKIN)
	local top, low, armL, armR, hairLong, bald
	if who == "monk" then
		local robe = pick(ROBE)
		top, low, armL, armR, hairLong, bald = robe, robe, robe, skin, false, true -- the robe over the left shoulder
	elseif who == "kid" then
		local girl = rng:NextNumber() < 0.5
		top, low, hairLong, bald = UNIFORM_TOP, UNIFORM_LONGYI, girl, false
		armL = if rng:NextNumber() < 0.7 then skin else top
		armR = armL
	elseif who == "woman" then
		top, low, hairLong, bald = pick(WOMEN_TOP), pick(WOMEN_LONGYI), true, false
		armL = if rng:NextNumber() < 0.5 then skin else top
		armR = armL
	else
		top, low, hairLong, bald = pick(MEN_SHIRT), pick(MEN_LONGYI), false, false
		armL = if rng:NextNumber() < 0.65 then skin else top
		armR = armL
	end
	local s = if who == "kid" then rng:NextNumber(0.66, 0.78) else rng:NextNumber(0.93, 1.03)
	f.scale = s
	f.bald = bald
	local colours = { top, skin, HAIR, low, armL, armR, SANDAL, SANDAL }
	for k, p in f.parts do
		p.Color = colours[k]
		p.Size = SIZES[k] * s
	end
	local hair = f.parts[3]
	hair.Size = (if hairLong then HAIR_LONG else HAIR_SHORT) * s
	hair.Transparency = if bald then 1 else 0
	f.hairAt = if hairLong then HAIR_LONG_AT else HAIR_SHORT_AT
	f.face.Texture = pick(FACES)
end

local function pose(w: Walker, moving: boolean)
	local f = w.fig
	local s = f.scale
	local root = CFrame.new(w.pos) * CFrame.Angles(0, w.yaw, 0)
	local sw = if moving then math.sin(w.phase) else 0
	local bob = if moving then math.abs(math.cos(w.phase)) * 0.06 * s else 0
	local up = CFrame.new(0, bob, 0)
	local cfs = f.cfs
	cfs[1] = root * up * CFrame.new(0, 3 * s, 0)
	cfs[2] = root * up * CFrame.new(0, 4.5 * s, 0)
	cfs[3] = root * up * CFrame.new(f.hairAt * s)
	cfs[4] = root * CFrame.new(0, 1.225 * s + bob * 0.5, 0) * CFrame.Angles(sw * 0.03, 0, 0)
	cfs[5] = root * up * CFrame.new(-1.5 * s, 3.5 * s, 0) * CFrame.Angles(-sw * 0.4, 0, 0) * CFrame.new(0, -0.5 * s, 0)
	cfs[6] = root * up * CFrame.new(1.5 * s, 3.5 * s, 0) * CFrame.Angles(sw * 0.4, 0, 0) * CFrame.new(0, -0.5 * s, 0)
	cfs[7] = root * CFrame.new(-0.5 * s, (0.175 + math.max(0, sw) * 0.12) * s, (-0.1 - sw * 0.45) * s)
	cfs[8] = root * CFrame.new(0.5 * s, (0.175 + math.max(0, -sw) * 0.12) * s, (-0.1 + sw * 0.45) * s)
	workspace:BulkMoveTo(f.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

local function flat(a: Vector3, b: Vector3): number
	local dx, dz = a.X - b.X, a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function takeFigure(who: string): Figure
	local f = table.remove(figPool) or newFigure()
	dress(f, who)
	f.model.Parent = pedFolder
	return f
end

local function retire(k: number)
	local w = active[k]
	w.fig.model.Parent = nil
	table.insert(figPool, w.fig)
	if w.spot then
		spotBusy[w.spot] = nil
	end
	active[k] = active[#active]
	active[#active] = nil
end

-- the point on a path k (toward k + dir), shifted sideways by lat: the paths run with their road on the left, so
-- lat > 0 is away from the kerb whichever way the walker goes
local function target(w: Walker): Vector3?
	local pts = w.path :: { Vector3 }
	local a, b = pts[w.k], pts[w.k + w.dir]
	if not b then
		return nil
	end
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if d.Magnitude < 0.01 then
		return b
	end
	d = d.Unit
	return b + Vector3.new(-d.Z, 0, d.X) * (w.lat * w.dir)
end

local function stepWalk(w: Walker, dt: number): boolean
	if w.mode == "pause" then
		w.timer -= dt
		if w.timer <= 0 then
			w.mode = "walk"
		end
		return false
	end
	local remaining = w.speed * dt
	for _ = 1, 4 do
		local t = target(w)
		if not t then
			-- the end of the pavement: turn back, sometimes after a look round
			w.dir = -w.dir
			if rng:NextNumber() < 0.35 then
				w.mode = "pause"
				w.timer = rng:NextNumber(2, 6)
				return false
			end
			t = target(w)
			if not t then
				return false
			end
		end
		local to = t - w.pos
		local fl = Vector3.new(to.X, 0, to.Z)
		local L = fl.Magnitude
		if L > 0.05 then
			w.yaw = math.atan2(-fl.X, -fl.Z)
		end
		if L <= remaining then
			w.pos = t
			w.k += w.dir
			remaining -= L
		else
			w.pos += to * (remaining / L)
			remaining = 0
		end
		if remaining <= 0.001 then
			break
		end
	end
	w.phase += w.speed * dt * 1.45
	return true
end

local function spawnWalker(cam: Vector3, gap: number, radius: number): boolean
	local r = math.ceil(radius / CELL)
	local gx, gz = math.floor(cam.X / CELL) + rng:NextInteger(-r, r), math.floor(cam.Z / CELL) + rng:NextInteger(-r, r)
	local list = pathCells[cellKey(gx, gz)]
	if not list then
		return false
	end
	local e = rng:NextInteger(1, #list // 2)
	local pi, k = list[2 * e - 1], list[2 * e]
	local pts = paths[pi]
	local a, b = pts[k], pts[k + 1]
	if not (a and b) then
		return false
	end
	local p = a:Lerp(b, rng:NextNumber())
	local d = flat(p, cam)
	if d < gap or d > radius then
		return false
	end
	local cfg = Config.YangonStreetLife
	local who = whoAt(p.X, p.Z)
	local speed = rng:NextNumber(cfg.WalkSpeed[1], cfg.WalkSpeed[2])
	if who == "monk" then
		speed = math.min(speed, 3.4)
	end
	local dir = if rng:NextNumber() < 0.5 then 1 else -1
	local wide = pathWide[pi]
	local w: Walker = {
		fig = takeFigure(who), mode = "walk", path = pts, k = if dir > 0 then k else k + 1, dir = dir, pos = p, yaw = 0,
		speed = speed, lat = if wide then rng:NextNumber(0.3, 2.4) else rng:NextNumber(-0.4, 0.5), phase = rng:NextNumber(0, 6), acc = 0,
		timer = 0, spot = nil,
	}
	-- start on the line, shifted sideways like the rest of the walk
	local t = target(w)
	if t then
		local dd = Vector3.new(t.X - p.X, 0, t.Z - p.Z)
		if dd.Magnitude > 0.05 then
			dd = dd.Unit
			w.pos = p + Vector3.new(-dd.Z, 0, dd.X) * (w.lat * w.dir)
			w.yaw = math.atan2(-dd.X, -dd.Z)
		end
	end
	table.insert(active, w)
	pose(w, true)
	return true
end

local function spawnStander(cam: Vector3, gap: number, radius: number): boolean
	local r = math.ceil(radius / CELL)
	local gx, gz = math.floor(cam.X / CELL) + rng:NextInteger(-r, r), math.floor(cam.Z / CELL) + rng:NextInteger(-r, r)
	local list = spotCells[cellKey(gx, gz)]
	if not list then
		return false
	end
	local i = list[rng:NextInteger(1, #list)]
	if spotBusy[i] then
		return false
	end
	local p = spotPos[i]
	local d = flat(p, cam)
	if d < gap or d > radius then
		return false
	end
	spotBusy[i] = true
	local w: Walker = {
		fig = takeFigure(whoAt(p.X, p.Z)), mode = "stand", path = nil, k = 0, dir = 1, pos = p, yaw = spotYaw[i],
		speed = 0, lat = 0, phase = 0, acc = 0, timer = rng:NextNumber(4, 14), spot = i,
	}
	table.insert(active, w)
	pose(w, false)
	return true
end

local function pedTick(cam: Vector3, cap: number)
	local cfg = Config.YangonStreetLife
	local want = cap
	if cam.Y > 1200 then
		want = 0
	elseif cam.Y > 300 then
		want = math.floor(cap / 3)
	end
	local k = 1
	while k <= #active do
		local w = active[k]
		if #active > want or flat(w.pos, cam) > cfg.PedKeep then
			retire(k)
		else
			k += 1
		end
	end
	local tries = 0
	while #active < want and tries < 8 do
		tries += 1
		if rng:NextNumber() < cfg.SpotShare then
			spawnStander(cam, cfg.PedMinGap, cfg.PedRadius)
		else
			spawnWalker(cam, cfg.PedMinGap, cfg.PedRadius)
		end
	end
end

local function pedFrame(dt: number, cam: Vector3)
	for _, w in active do
		w.acc += dt
		if w.mode == "stand" then
			-- now and then a look round
			w.timer -= dt
			if w.timer <= 0 then
				w.timer = rng:NextNumber(4, 14)
				w.yaw = spotYaw[w.spot :: number] + rng:NextNumber(-0.7, 0.7)
				pose(w, false)
			end
			w.acc = 0
		else
			local d = flat(w.pos, cam)
			local every = if d < 70 then 0 elseif d < 140 then 0.1 else 0.25
			if w.acc >= every then
				local moving = stepWalk(w, w.acc)
				w.acc = 0
				pose(w, moving)
			end
		end
	end
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
function YangonStreetLife.start(qualityScale: (() -> number)?)
	local cfg = Config.YangonStreetLife
	if started or not cfg or cfg.Enabled == false or Config.activeMap() ~= "Yangon" then
		return
	end
	started = true
	task.spawn(function()
		local t0 = os.clock()
		parse()
		if #carX == 0 and #paths == 0 then
			return
		end
		local f = Instance.new("Folder")
		f.Name = "YangonStreetLife"
		local cf = Instance.new("Folder")
		cf.Name = "ParkedCars"
		cf.Parent = f
		local pf = Instance.new("Folder")
		pf.Name = "People"
		pf.Parent = f
		f.Parent = workspace
		carFolder, pedFolder = cf, pf
		print(string.format("[CityLegends] YangonStreetLife: %d car spots, %d standing spots, %d paths (%.2f s)",
			#carX, #spotPos, #paths, os.clock() - t0))
		local camera = workspace.CurrentCamera
		local function caps(): (number, number)
			local q = if qualityScale then qualityScale() else 1
			local k = if q <= cfg.LowScale then 0.5 else math.min(q, 1)
			return math.floor(cfg.CarMax * k), math.floor(cfg.PedMax * k)
		end
		local carCap, pedCap = caps()
		local carAcc, pedAcc, capAcc = cfg.CarCheck, cfg.PedCheck, 0
		RunService.Heartbeat:Connect(function(dt: number)
			local cam = (workspace.CurrentCamera or camera).CFrame.Position
			capAcc += dt
			if capAcc > 3 then
				capAcc = 0
				carCap, pedCap = caps()
			end
			carAcc += dt
			if carAcc >= cfg.CarCheck then
				carAcc = 0
				carTick(cam, carCap)
			end
			pedAcc += dt
			if pedAcc >= cfg.PedCheck then
				pedAcc = 0
				pedTick(cam, pedCap)
			end
			pedFrame(dt, cam)
		end)
	end)
end

-- (for a look in Studio: how many are out)
function YangonStreetLife.stats(): { cars: number, built: number, people: number }
	return { cars = liveCount, built = built, people = #active }
end

return YangonStreetLife
