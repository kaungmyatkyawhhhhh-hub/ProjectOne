--[[
	YangonStreetLife (client, 2026-11-14)
	Owner: "the ingame yangon is too clean compared to real life yangon". Parked cars along the kerbs and people on the
	pavements, round the camera only, from src/shared/YangonStreetLife*.lua (tools/yangon/city/streetlife.py: car spots,
	standing spots, pavement paths; one string of lines per module). Does nothing outside Yangon.

	  * parked cars: TrafficBodies' low-poly bodies (anchored root = the one collidable box, no lights, no shadows),
	    pooled. Every Config.YangonStreetLife.CarCheck seconds the spots within CarRadius of the camera (a 128-stud
	    grid, never a full scan) fill up to CarMax, nearest first; a car goes back to the pool past CarKeep. 70% are
	    repainted white / silver / grey (Yangon's Probox / Mark II / Hiace look), half up on the pavement on main roads.
	  * people: classic R6 Roblox avatars (owner, 27 Nov: Roblox characters, never realistic people): 7 parts each
	    (torso, Roblox head with a Roblox face, Roblox hair, legs, arms), clothes as Textures cropped out of two
	    shared atlases (tools/people/roblox_clothes.py, shared/PedClothes): men in longyi and shirt, women in htamein and blouse, monks in maroon robes now and then (more near monasteries and pagodas), kids in
	    the green and white school uniform near schools. They walk the pavement paths at 3-5 studs a second and turn
	    back where the pavement ends (spread across the pavement, drifting, a third in twos, stopping now and then),
	    or stand at bus stops, tea shops and shop fronts (off the exact mark and facing). Anchored, no collisions, moved
	    with BulkMoveTo: near ones a few dozen times a second, far ones a few times. At most PedMax within PedRadius.
	  * counts follow the graphics setting: qualityScale() at or under LowScale (Low) halves them.
]]

local CollectionService = game:GetService("CollectionService")
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
	-- extra chunks made by other tools, in the same format and origin (optional): the Myanmar Plaza mall's shoppers
	-- (tools/yangon/city/mall_life.py, 2026-11-16)
	for _, name in { "YangonStreetLifeMall" } do
		local m = Shared:FindFirstChild(name)
		if m then
			local ok3, s = pcall(require, m)
			if ok3 and type(s) == "string" then
				table.insert(chunks, s)
			end
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
-- (27 Nov, owner: "make it just roblox character, like the tiktok video car game, not some realistic looking people
-- because thats terrifying and kids gonna get scared because the game is in roblox and they expect roblox character")
-- classic R6 Roblox avatars: block body, the Roblox head with Roblox faces, Roblox hair, Roblox-style clothes.
-- Yangon shows only in the clothes (tools/people/roblox_clothes.py, shared/PedClothes): longyi checks, htamein, eingyi
-- blouses, the monk's robe, the green and white school uniform, a T-shirt and jeans. Skin = Roblox's body colours.
-- The clothes are Textures cropped out of two shared atlases (no Humanoid: its Shirt / Pants composite cost ~1.4 MB of
-- character texture a person in Studio, 58 MB for 40; the atlases are 2 pictures for everyone).
local SKIN = {
	Color3.fromRGB(234, 184, 146), Color3.fromRGB(204, 142, 105), Color3.fromRGB(255, 204, 153),
	Color3.fromRGB(175, 122, 89), Color3.fromRGB(124, 92, 70), Color3.fromRGB(245, 205, 48),
}
local HAIR_COLS = {
	Color3.fromRGB(28, 24, 22), Color3.fromRGB(28, 24, 22), Color3.fromRGB(46, 34, 26), Color3.fromRGB(70, 48, 32),
}
local CLOTH: any = nil -- shared/PedClothes (atlases, garment cells, face slots)
local MEN_TOP = { "shirt_white", "shirt_white", "shirt_blue", "shirt_cream", "shirt_navy", "tee_red", "tee_black" }
local MEN_LOW = { "longyi_green", "longyi_blue", "longyi_brown", "longyi_grey", "longyi_maroon" }
local WOMEN_TOP = { "blouse_white", "blouse_pink", "blouse_yellow", "blouse_lilac" }
local WOMEN_LOW = { "htamein_pink", "htamein_teal", "htamein_purple", "htamein_gold" }
-- Roblox's own classic faces (the smile first, twice as likely)
local FACES = {
	"rbxasset://textures/face.png", "rbxasset://textures/face.png",
	"rbxassetid://7074749", "rbxassetid://7074780", "rbxassetid://7074882", "rbxassetid://7075130",
	"rbxassetid://7075412", "rbxassetid://7076096", "rbxassetid://7317606", "rbxassetid://7131308",
	"rbxassetid://7074712", "rbxassetid://7074827",
}

-- the parts (feet on the ground, facing -Z): 1 torso, 2 head, 3 hair, 4 left leg, 5 / 6 left / right arm, 7 right leg.
-- cen = each part's centre, shoulder / hip = the right pivots (the left are mirrored), neck / waist: PedHits' joints.
-- Each figure gets its own copy scaled for its build (geoFor), so PedHits' sockets match what is drawn.
type Geo = {
	cen: { Vector3 }, size: { Vector3 }, shoulder: Vector3, hip: Vector3, neck: Vector3, waist: Vector3,
	arm: number, leg: number,
}
local R6: Geo = {
	cen = {
		Vector3.new(0, 3, 0), Vector3.new(0, 4.5, 0), Vector3.new(0, 5.1, 0.05), Vector3.new(-0.5, 1, 0),
		Vector3.new(-1.5, 3, 0), Vector3.new(1.5, 3, 0), Vector3.new(0.5, 1, 0),
	},
	size = {
		Vector3.new(2, 2, 1), Vector3.new(2, 1, 1), Vector3.new(1.3, 0.4, 1.3), Vector3.new(1, 2, 1),
		Vector3.new(1, 2, 1), Vector3.new(1, 2, 1), Vector3.new(1, 2, 1),
	},
	shoulder = Vector3.new(1.5, 3.5, 0), hip = Vector3.new(0.5, 2, 0), neck = Vector3.new(0, 4, 0),
	waist = Vector3.new(0, 2, 0), arm = 0.6, leg = 0.55,
}
local NAMES = { "Torso", "Head", "Hair", "Left Leg", "Left Arm", "Right Arm", "Right Leg" }
local NPART = #NAMES
local geoCache: { [number]: Geo } = {}
-- bw = build (shoulder width): 0.9 thin .. 1.15 broad; the torso widens and the arms move out with it
local function geoFor(bw: number): Geo
	local key = math.floor(bw * 20 + 0.5)
	local g = geoCache[key]
	if g then
		return g
	end
	bw = key / 20
	local cen, size = table.clone(R6.cen), table.clone(R6.size)
	size[1] = Vector3.new(2 * bw, 2, 1)
	cen[5] = Vector3.new(-(bw + 0.5), 3, 0)
	cen[6] = Vector3.new(bw + 0.5, 3, 0)
	g = {
		cen = cen, size = size, shoulder = Vector3.new(bw + 0.5, 3.5, 0), hip = R6.hip, neck = R6.neck,
		waist = R6.waist, arm = R6.arm, leg = R6.leg,
	}
	geoCache[key] = g
	return g
end
-- Roblox hair: ReplicatedStorage.PedKit.Hair (Studio, saved in the place): the handles of Roblox's own free catalog
-- hairs (Pal Hair, Brown Hair, Updo ...; attribute Off = the handle's CFrame from the head's centre at scale 1, from its
-- HairAttachment; Long = women's), texture cleared so Part.Color is the hair colour; with no kit a plain block cap
local hairKit: { [string]: { BasePart } } = { short = {}, long = {} }

type Figure = {
	model: Model, parts: { BasePart }, cfs: { CFrame }, face: Decal?, scale: number, hairOff: CFrame, bald: boolean,
	geo: Geo, hairKind: string, tex: { Texture }, hairSize: Vector3,
}
type Walker = {
	fig: Figure, mode: string, path: { Vector3 }?, k: number, dir: number, pos: Vector3, yaw: number, speed: number,
	lat: number, phase: number, acc: number, timer: number, spot: number?, held: boolean?, gone: boolean?,
	latLo: number?, latHi: number?, look: number?, lookTo: number?, lookT: number?, t: number?, yawTo: number?,
}

local pedWant = 0 -- people wanted out now (pedTick)
local figPool: { Figure } = {}
local active: { Walker } = {}
local spotBusy: { [number]: boolean } = {}

local function quiet(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

-- the clothes' image ids and the hair kit, once
local function loadTemplates()
	local ok, ids = pcall(require, Shared:WaitForChild("PedClothes", 5) :: ModuleScript)
	if ok and type(ids) == "table" then
		CLOTH = ids
	else
		warn("[CityLegends] YangonStreetLife: no PedClothes, plain clothes")
	end
	local kit = ReplicatedStorage:FindFirstChild("PedKit")
	local hairs = kit and kit:FindFirstChild("Hair")
	if hairs then
		for _, h in hairs:GetChildren() do
			if h:IsA("BasePart") then
				local kind = if h:GetAttribute("Long") then "long" else "short"
				table.insert(hairKit[kind], h)
			end
		end
	end
end

-- the clothed faces: { part number, atlas ("shirt" / "pants"), slot group (T / R / L), face }
local FACE_IDS = { F = Enum.NormalId.Front, B = Enum.NormalId.Back, L = Enum.NormalId.Left, R = Enum.NormalId.Right, U = Enum.NormalId.Top }
local CLOTHED: { { any } } = {}
for _, e in { { 1, "shirt", "T" }, { 5, "shirt", "L" }, { 6, "shirt", "R" }, { 4, "pants", "L" }, { 7, "pants", "R" } } do
	for _, face in { "F", "B", "L", "R", "U" } do
		table.insert(CLOTHED, { e[1], e[2], e[3], face })
	end
end

-- crop each Texture to its garment's slot for the part's present size (studs per tile = the whole atlas)
local function setClothes(f: Figure, top: string, low: string)
	if not CLOTH then
		return
	end
	local A, cw, ch, cols = CLOTH.size, CLOTH.cellW, CLOTH.cellH, CLOTH.cols
	for i, c in CLOTHED do
		local t = f.tex[i]
		local part = f.parts[c[1]]
		local cell = CLOTH[c[2]][if c[2] == "shirt" then top else low] or 0
		local r = CLOTH.slots[c[3]][c[4]]
		local x, y = (cell % cols) * cw + r[1], (cell // cols) * ch + r[2]
		local sz = part.Size
		local face = c[4]
		local W, H = if face == "L" or face == "R" then sz.Z else sz.X, if face == "U" then sz.Z else sz.Y
		local su, sv = W * A / r[3], H * A / r[4]
		t.StudsPerTileU, t.StudsPerTileV = su, sv
		t.OffsetStudsU, t.OffsetStudsV = x / A * su, y / A * sv
	end
end

local function newFigure(): Figure
	local model = Instance.new("Model")
	model.Name = "Person"
	local parts = {}
	local face: Decal? = nil
	for k = 1, NPART do
		local p = Instance.new("Part")
		quiet(p)
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Name = NAMES[k]
		p.Size = R6.size[k]
		if k == 2 then
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
		p.Parent = model
		parts[k] = p
	end
	-- the clothes: one Texture per clothed face, cropped out of the shared atlases in dress()
	local tex = {}
	if CLOTH then
		for i, c in CLOTHED do
			local t = Instance.new("Texture")
			t.Texture = "rbxassetid://" .. CLOTH.atlas[c[2]]
			t.Face = FACE_IDS[c[4]]
			t.Parent = parts[c[1]]
			tex[i] = t
		end
	end
	return {
		model = model, parts = parts, cfs = table.create(NPART, CFrame.new()), face = face, scale = 1,
		hairOff = CFrame.new(R6.cen[3] - R6.cen[2]), bald = false, geo = R6, hairKind = "", tex = tex,
		hairSize = R6.size[3],
	}
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

-- the hair piece: a copy of one of the kit's Roblox hairs (a MeshPart's MeshId can't change at run time), or the cap
local function setHair(f: Figure, kind: string)
	local list = hairKit[kind]
	if #list == 0 then
		list = hairKit.short
	end
	if #list == 0 then
		return
	end
	local src = pick(list)
	local p = src:Clone()
	quiet(p)
	p.Name = "Hair"
	p.Parent = f.model
	f.parts[3]:Destroy()
	f.parts[3] = p
	f.hairOff = (src:GetAttribute("Off") :: CFrame?) or CFrame.new(0, 0.6, 0)
	f.hairSize = src.Size
end

local function dress(f: Figure, who: string)
	local skin = pick(SKIN)
	local top, low, hairKind, bald
	if who == "monk" then
		top, low, hairKind, bald = "robe_shirt", "robe_pants", "short", true
	elseif who == "kid" then
		top, low, hairKind, bald = "uniform_shirt", "uniform_longyi", if rng:NextNumber() < 0.5 then "long" else "short", false
	elseif who == "woman" then
		top, low, hairKind, bald = pick(WOMEN_TOP), pick(WOMEN_LOW), "long", false
	else
		-- now and then a young man in a T-shirt and jeans
		if rng:NextNumber() < 0.15 then
			top, low = if rng:NextNumber() < 0.5 then "tee_red" else "tee_black", "jeans_blue"
		else
			top, low = pick(MEN_TOP), pick(MEN_LOW)
		end
		hairKind, bald = "short", false
	end
	local girl = who == "woman" or (who == "kid" and hairKind == "long")
	local s = if who == "kid" then rng:NextNumber(0.68, 0.8) elseif girl then rng:NextNumber(0.9, 0.98)
		else rng:NextNumber(0.95, 1.05)
	local bw = if who == "kid" then 1 elseif girl then rng:NextNumber(0.9, 1.02) else rng:NextNumber(0.95, 1.15)
	f.scale = s
	f.bald = bald
	f.geo = geoFor(bw)
	if f.hairKind ~= hairKind or rng:NextNumber() < 0.5 then
		setHair(f, hairKind)
	end
	f.hairKind = hairKind
	for k, p in f.parts do
		p.Color = if k == 3 then pick(HAIR_COLS) else skin
		p.Size = (if k == 3 then f.hairSize else f.geo.size[k]) * s
	end
	setClothes(f, top, low)
	f.parts[3].Transparency = if bald then 1 else 0
	if f.face then
		f.face.Texture = pick(FACES)
	end
end

-- head turns: a slow look round (shops, the street, now and then the camera), eased
local function lookStep(w: Walker, dt: number)
	w.lookT = (w.lookT or 0) - dt
	if (w.lookT :: number) <= 0 then
		w.lookT = rng:NextNumber(1.5, 5)
		w.lookTo = if rng:NextNumber() < 0.45 then 0 else rng:NextNumber(-0.9, 0.9)
	end
	local cur = w.look or 0
	w.look = cur + ((w.lookTo or 0) - cur) * math.min(1, dt * 3)
end

-- the classic Roblox walk: arms and legs swing from shoulders and hips (opposite), the body dips as the legs open;
-- standing: a little arm sway and the head looking round
local function pose(w: Walker, moving: boolean)
	local f = w.fig
	local g = f.geo
	local cen = g.cen
	local s = f.scale
	local root = CFrame.new(w.pos) * CFrame.Angles(0, w.yaw, 0)
	local t = w.t or 0
	local sw = if moving then math.sin(w.phase) else 0
	local legA = sw * g.leg
	local armA = if moving then sw * g.arm else math.sin(t * 1.6 + w.lat * 3) * 0.04
	local dip = if moving then 2 * (1 - math.cos(legA)) * s else math.sin(t * 2.1) * 0.015 * s
	local up = root * CFrame.new(0, -dip, 0)
	local shR, hipR = g.shoulder, g.hip
	local shL, hipL = Vector3.new(-shR.X, shR.Y, shR.Z), Vector3.new(-hipR.X, hipR.Y, hipR.Z)
	local cfs = f.cfs
	local head = up * CFrame.new(g.neck * s) * CFrame.Angles(0, w.look or 0, 0) * CFrame.new((cen[2] - g.neck) * s)
	cfs[1] = up * CFrame.new(cen[1] * s)
	cfs[2] = head
	cfs[3] = head * (f.hairOff - f.hairOff.Position + f.hairOff.Position * s)
	cfs[4] = up * CFrame.new(hipL * s) * CFrame.Angles(legA, 0, 0) * CFrame.new((cen[4] - hipL) * s)
	cfs[5] = up * CFrame.new(shL * s) * CFrame.Angles(-armA, 0, 0) * CFrame.new((cen[5] - shL) * s)
	cfs[6] = up * CFrame.new(shR * s) * CFrame.Angles(armA, 0, 0) * CFrame.new((cen[6] - shR) * s)
	cfs[7] = up * CFrame.new(hipR * s) * CFrame.Angles(-legA, 0, 0) * CFrame.new((cen[7] - hipR) * s)
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

-- (27 Nov, owner: "fix the people walking through the shelters") things walkers go round: parts tagged PedBlock (the
-- street kit's shelter body SMT_busd carries the tag on its template, so P1's street-layer shelters and
-- YangonRoadside's own get it; YangonRoadside tags its free-standing ad panels). Kept in a 32-stud grid.
local BLOCK_CELL, BLOCK_PAD = 32, 0.9
local blockCells: { [number]: { BasePart } } = {}
local blockKeys: { [BasePart]: { number } } = {}
local function blockAdd(q: Instance)
	if not q:IsA("BasePart") or blockKeys[q] or not q:IsDescendantOf(workspace) then
		return
	end
	local r = q.Size.Magnitude / 2 + BLOCK_PAD
	local p = q.Position
	local keys = {}
	for gx = math.floor((p.X - r) / BLOCK_CELL), math.floor((p.X + r) / BLOCK_CELL) do
		for gz = math.floor((p.Z - r) / BLOCK_CELL), math.floor((p.Z + r) / BLOCK_CELL) do
			local k = cellKey(gx, gz)
			local list = blockCells[k]
			if not list then
				list = {}
				blockCells[k] = list
			end
			table.insert(list, q)
			table.insert(keys, k)
		end
	end
	blockKeys[q] = keys
end
local function blockRemove(q: Instance)
	local keys = blockKeys[q :: any]
	if not keys then
		return
	end
	blockKeys[q :: any] = nil
	for _, k in keys do
		local list = blockCells[k]
		local i = list and table.find(list, q :: any)
		if i then
			list[i] = list[#list]
			list[#list] = nil
			if #list == 0 then
				blockCells[k] = nil
			end
		end
	end
end

-- p moved out of any PedBlock box (grown by BLOCK_PAD) along `toward` (flat unit vector: the kerb side), so a walker
-- passes between a shelter and the kerb instead of through it
local function clearOf(p: Vector3, toward: Vector3): Vector3
	local list = blockCells[cellKey(math.floor(p.X / BLOCK_CELL), math.floor(p.Z / BLOCK_CELL))]
	if not list then
		return p
	end
	for _ = 1, 2 do
		local moved = false
		for _, q in list do
			local lp = q.CFrame:PointToObjectSpace(p)
			local h = q.Size / 2
			local hx, hz = h.X + BLOCK_PAD, h.Z + BLOCK_PAD
			if math.abs(lp.X) < hx and math.abs(lp.Z) < hz and lp.Y > -h.Y - 6 and lp.Y < h.Y + 1 then
				local ld = q.CFrame:VectorToObjectSpace(toward)
				local t = math.huge
				if math.abs(ld.X) > 1e-3 then
					t = math.min(t, ((if ld.X > 0 then hx else -hx) - lp.X) / ld.X)
				end
				if math.abs(ld.Z) > 1e-3 then
					t = math.min(t, ((if ld.Z > 0 then hz else -hz) - lp.Z) / ld.Z)
				end
				if t < math.huge then
					p += toward * (t + 0.05)
					moved = true
				end
			end
		end
		if not moved then
			break
		end
	end
	return p
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
	local away = Vector3.new(-d.Z, 0, d.X) * w.dir
	return clearOf(b + away * w.lat, -away)
end

-- the kerb side of a walker's current stretch (flat unit), for pushing it out of a PedBlock box
local function kerbSide(w: Walker): Vector3?
	local pts = w.path
	if not pts then
		return nil
	end
	local a, b = pts[w.k - w.dir], pts[w.k]
	if not (a and b) then
		a, b = pts[w.k], pts[w.k + w.dir]
	end
	if not (a and b) then
		return nil
	end
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if d.Magnitude < 0.01 then
		return nil
	end
	d = d.Unit
	return -Vector3.new(-d.Z, 0, d.X) * w.dir
end

local function stepWalk(w: Walker, dt: number): boolean
	if w.mode == "pause" then
		w.timer -= dt
		if w.timer <= 0 then
			w.mode = "walk"
		end
		return false
	end
	-- (27 Nov) now and then a stop on the way: a look at a shop, the phone, the street
	if rng:NextNumber() < dt / 45 then
		w.mode = "pause"
		w.timer = rng:NextNumber(2, 7)
		w.yaw += rng:NextNumber(0.5, 1.6) * (if rng:NextNumber() < 0.5 then -1 else 1)
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
			-- drift across the pavement a little at each point (no one walks a ruled line)
			if w.latLo then
				w.lat = math.clamp(w.lat + rng:NextNumber(-0.5, 0.5), w.latLo, w.latHi :: number)
			end
		else
			w.pos += to * (remaining / L)
			remaining = 0
		end
		if remaining <= 0.001 then
			break
		end
	end
	-- (a corner of a shelter on the straight line to the next point) never inside one
	local kerb = kerbSide(w)
	if kerb then
		w.pos = clearOf(w.pos, kerb)
	end
	-- (R6 legs at 0.55 rad: ~4.2 studs a stride; shorter people step faster)
	w.phase += w.speed * dt * 1.5 / w.fig.scale
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
	-- (27 Nov, owner: people in rows) never on top of someone: no one within 8 studs
	for _, o in active do
		if flat(o.pos, p) < 8 then
			return false
		end
	end
	local cfg = Config.YangonStreetLife
	local who = whoAt(p.X, p.Z)
	local speed = rng:NextNumber(cfg.WalkSpeed[1], cfg.WalkSpeed[2])
	if who == "monk" then
		speed = math.min(speed, 3.4)
	end
	local dir = if rng:NextNumber() < 0.5 then 1 else -1
	-- across the pavement (lat > 0 away from the kerb): the whole width, not one line (narrow paths are the middle
	-- of a pavement, wide ones its kerb side)
	local lo, hi = if pathWide[pi] then -0.6 else -1.5, if pathWide[pi] then 3 else 1.5
	local function walker(f: Figure, lat: number, sp: number, phase: number): Walker
		local w: Walker = {
			fig = f, mode = "walk", path = pts, k = if dir > 0 then k else k + 1, dir = dir, pos = p, yaw = 0,
			speed = sp, lat = lat, phase = phase, acc = 0, timer = 0, spot = nil, latLo = lo, latHi = hi,
		}
		-- start on the line, shifted sideways like the rest of the walk
		local t = target(w)
		if t then
			local dd = Vector3.new(t.X - p.X, 0, t.Z - p.Z)
			if dd.Magnitude > 0.05 then
				dd = dd.Unit
				local away = Vector3.new(-dd.Z, 0, dd.X) * w.dir
				w.pos = clearOf(p + away * w.lat, -away)
				w.yaw = math.atan2(-dd.X, -dd.Z)
			end
		end
		table.insert(active, w)
		pose(w, true)
		return w
	end
	local lat = rng:NextNumber(lo, hi)
	local phase = rng:NextNumber(0, 6)
	walker(takeFigure(who), lat, speed, phase)
	-- a third walk in twos, side by side at one pace (friends, a couple, a parent and child)
	if who ~= "monk" and rng:NextNumber() < 0.3 and #active < pedWant then
		local side = if lat + 1.3 <= hi then 1.3 else -1.3
		local who2 = if who == "kid" or rng:NextNumber() < 0.15 then "kid" elseif rng:NextNumber() < 0.5 then "man" else "woman"
		walker(takeFigure(who2), lat + side, speed, phase + 1.3)
	end
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
	-- (27 Nov) not on the spot's exact mark nor its exact facing, so a row of spots never reads as a line-up
	p += Vector3.new(rng:NextNumber(-0.8, 0.8), 0, rng:NextNumber(-0.8, 0.8))
	local w: Walker = {
		fig = takeFigure(whoAt(p.X, p.Z)), mode = "stand", path = nil, k = 0, dir = 1, pos = p,
		yaw = spotYaw[i] + rng:NextNumber(-0.6, 0.6), speed = 0, lat = 0, phase = 0, acc = 0, timer = rng:NextNumber(4, 14), spot = i,
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
	pedWant = want
	local k = 1
	while k <= #active do
		local w = active[k]
		-- (PedHits: a walker knocked over is held until it is up; `gone` = it faded out, put someone new elsewhere)
		if w.gone or (not w.held and (#active > want or flat(w.pos, cam) > cfg.PedKeep)) then
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

local function pedFrame(dt: number, cam: Vector3, look: Vector3)
	for _, w in active do
		w.acc += dt
		if w.held or w.gone then
			w.acc = 0
		elseif w.mode == "stand" then
			-- now and then a turn (eased), the head looking round and a little sway: posed only near and in view
			w.timer -= dt
			if w.timer <= 0 then
				w.timer = rng:NextNumber(4, 14)
				w.yawTo = spotYaw[w.spot :: number] + rng:NextNumber(-0.7, 0.7)
			end
			local d = flat(w.pos, cam)
			local every = if d < 40 then 0.05 elseif d < 90 then 0.25 else math.huge
			if d > 20 and (w.pos - cam):Dot(look) < 0 then
				every = math.huge
			end
			if w.acc >= every then
				local a = w.acc
				w.acc = 0
				w.t = (w.t or 0) + a
				if w.yawTo then
					w.yaw += (w.yawTo - w.yaw) * math.min(1, a * 2)
				end
				lookStep(w, a)
				pose(w, false)
			elseif every == math.huge then
				w.acc = 0
			end
		else
			local d = flat(w.pos, cam)
			local every = if d < 70 then 0 elseif d < 140 then 0.1 else 0.25
			-- (2026-11-26, FPS) behind the camera and not right beside it: out of view, posed at the far rate
			if d > 20 and (w.pos - cam):Dot(look) < 0 then
				every = 0.25
			end
			if w.acc >= every then
				local a = w.acc
				local moving = stepWalk(w, a)
				w.acc = 0
				w.t = (w.t or 0) + a
				if d < 60 then
					lookStep(w, a)
				end
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
		loadTemplates()
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
		CollectionService:GetInstanceAddedSignal("PedBlock"):Connect(blockAdd)
		CollectionService:GetInstanceRemovedSignal("PedBlock"):Connect(blockRemove)
		for _, q in CollectionService:GetTagged("PedBlock") do
			blockAdd(q)
		end
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
			local camCF = (workspace.CurrentCamera or camera).CFrame
			local cam = camCF.Position
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
			pedFrame(dt, cam, camCF.LookVector)
		end)
	end)
end

-- (PedHits, 2026-11-26) the walkers out now, and the posing function for standing one up
function YangonStreetLife.walkers(): { any }
	return active
end
YangonStreetLife.pose = pose

-- (for a look in Studio: how many are out)
function YangonStreetLife.stats(): { cars: number, built: number, people: number }
	return { cars = liveCount, built = built, people = #active }
end

return YangonStreetLife
