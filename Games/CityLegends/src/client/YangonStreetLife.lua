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
local PedMotion = require(script.Parent:WaitForChild("PedMotion"))
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local Traffic = require(script.Parent:WaitForChild("Traffic"))

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
local meetAt: { Vector3 } = {} -- (2026-11-28) "meet" spots: the People's Square car meet's onlookers

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
	for _, name in { "YangonStreetLifeMall", "YangonStreetLifeMeet" } do -- (2026-11-28) + the People's Square car meet's crowd and show cars
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
				if b[6] == "meet" then
					table.insert(meetAt, spotPos[#spotPos])
				end
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
	arm: number, leg: number, extra: { [number]: { { size: Vector3, rel: Vector3 } } }?,
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
-- (27 Nov, owner: "the characters blocky are too sharp and the corners need rounding ... use the real roblox character
-- from Avatar > Character > Blocky") ReplicatedStorage.PedKit.Body (Studio, saved in the place): Roblox's Blocky body =
-- the default R15 body parts (bevelled blocks), made in Studio with Players:CreateHumanoidModelFromDescription. One
-- folder per R6 limb (Torso, Left Arm ...) holding its R15 pieces "1", "2" (, "3") top down, attribute Off = the piece's
-- centre from the limb box's centre, folder attribute Box = the limb box; plus Head (MeshPart, attribute HairAt). The
-- limb's first piece is its part 1-7 (PedHits' joints), the others follow it (parts 8+). Without the kit: R6 blocks.
type LimbKit = { box: Vector3, pieces: { { tpl: BasePart, off: Vector3, size: Vector3, a: number, b: number } } }
local limbKit: { [number]: LimbKit } = {}
local LIMB_K = { 1, 4, 5, 6, 7 }
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
	-- the Blocky pieces: each limb's pieces stretched to fill its R6 box; cen / size become the first piece's
	local extra = {}
	for _, k in LIMB_K do
		local lk = limbKit[k]
		if lk then
			local F = size[k] / lk.box
			local p1 = lk.pieces[1]
			local c0 = cen[k]
			cen[k] = c0 + p1.off * F
			size[k] = p1.size * F
			local ex = {}
			for i = 2, #lk.pieces do
				local pc = lk.pieces[i]
				-- (27 Nov) 0.1 narrower across the hinge axis: in a bend the lower piece overlaps the one above, and
				-- their side faces in one plane z-fought (ragged "torn paper" patches on the arm); inset they hide inside
				ex[i] = { size = pc.size * F - Vector3.new(0.1, 0, 0), rel = (pc.off - p1.off) * F }
			end
			extra[k] = ex
		end
	end
	g = {
		cen = cen, size = size, shoulder = Vector3.new(bw + 0.5, 3.5, 0), hip = R6.hip, neck = R6.neck,
		waist = R6.waist, arm = R6.arm, leg = R6.leg, extra = extra,
	}
	geoCache[key] = g
	return g
end
-- Roblox hair: ReplicatedStorage.PedKit.Hair (Studio, saved in the place): the handles of Roblox's own free catalog
-- hairs (Pal Hair, Brown Hair, Updo ...; attribute Off = the handle's CFrame from the head's centre at scale 1, from its
-- HairAttachment; Long = women's), texture cleared so Part.Color is the hair colour; with no kit a plain block cap
local hairKit: { [string]: { BasePart } } = { short = {}, long = {} }
local headKit: BasePart? = nil
local hairShift = Vector3.zero -- the kit head's HairAttachment against the classic head's (0, 0.6, 0)

type Figure = {
	model: Model, parts: { BasePart }, cfs: { CFrame }, face: Decal?, scale: number, hairOff: CFrame, bald: boolean,
	geo: Geo, hairKind: string, tex: { any }, hairSize: Vector3, extraOf: { [number]: { k: number, i: number } },
	shadow: boolean?, rig: any?, rigGeo: any?,
}
type Walker = {
	fig: Figure, mode: string, path: { Vector3 }?, k: number, dir: number, pos: Vector3, yaw: number, speed: number,
	lat: number, phase: number, acc: number, timer: number, spot: number?, held: boolean?, gone: boolean?,
	latLo: number?, latHi: number?, look: number?, lookTo: number?, lookT: number?, t: number?, yawTo: number?,
	-- (27 Nov, PedMotion) gait "walk" / "run", steering, knock-overs, crossings, phones
	gait: string?, walkSpeed: number?, speedNow: number?, yawRate: number?, lean: number?, twist: number?,
	act: any?, knockAt: any?, knocker: boolean?, knockDone: boolean?, avoid: any?, cross: any?, glance: any?,
	runT: number?, hurry: boolean?, phone: string?, pauseYaw: number?, scanT: number?, forceKind: string?,
	forceRun: boolean?, flipAt: number?,
	-- (27 Nov) signal crossings and the idle phone look
	peekT: number?, peekOn: boolean?, obs: any?, forceSig: any?, sigStr: string?,
	-- (27 Nov) players' cars: running off, fear, the check timer
	flee: any?, fearT: number?, carT: number?, bump: any?,
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
	local body = kit and kit:FindFirstChild("Body")
	if body then
		for _, k in LIMB_K do
			local f = body:FindFirstChild(NAMES[k])
			local box = f and f:GetAttribute("Box") :: Vector3?
			if f and box then
				local lk: LimbKit = { box = box, pieces = {} }
				for i = 1, 3 do
					local pc = f:FindFirstChild(tostring(i)) :: BasePart?
					if pc then
						local off = (pc:GetAttribute("Off") :: Vector3?) or Vector3.zero
						-- the piece's share of the limb's height, top down (its slice of the clothes picture)
						local a = math.clamp((box.Y / 2 - off.Y - pc.Size.Y / 2) / box.Y, 0, 1)
						local b = math.clamp(a + pc.Size.Y / box.Y, 0, 1)
						table.insert(lk.pieces, { tpl = pc, off = off, size = pc.Size, a = a, b = b })
					end
				end
				if #lk.pieces > 0 then
					limbKit[k] = lk
				end
			end
		end
		local head = body:FindFirstChild("Head") :: BasePart?
		headKit = head
		if head then -- the head sits on the neck at its own size; PedHits reads R6 (geoFor copies it)
			R6.size[2] = head.Size
			R6.cen[2] = R6.neck + Vector3.new(0, head.Size.Y / 2, 0)
			hairShift = ((head:GetAttribute("HairAt") :: Vector3?) or Vector3.new(0, 0.6, 0)) - Vector3.new(0, 0.6, 0)
		end
	end
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

-- the clothed limbs: part number -> atlas ("shirt" / "pants"), slot group (T / R / L)
local FACE_IDS = {
	F = Enum.NormalId.Front, B = Enum.NormalId.Back, L = Enum.NormalId.Left, R = Enum.NormalId.Right,
	U = Enum.NormalId.Top, D = Enum.NormalId.Bottom,
}
local CLOTHED = { [1] = { "shirt", "T" }, [5] = { "shirt", "L" }, [6] = { "shirt", "R" }, [4] = { "pants", "L" }, [7] = { "pants", "R" } }

-- crop each Texture to its garment's slot for the part's present size (studs per tile = the whole atlas)
local function setClothes(f: Figure, top: string, low: string)
	if not CLOTH then
		return
	end
	local A, cw, ch, cols = CLOTH.size, CLOTH.cellW, CLOTH.cellH, CLOTH.cols
	for _, c in f.tex do
		local t = c.t
		local cell = CLOTH[c.atlas][if c.atlas == "shirt" then top else low] or 0
		-- a joint face (c.joint) shows the front's thin row at that edge of the piece
		local r = CLOTH.slots[c.group][if c.joint then "F" else c.face]
		-- a Blocky piece shows its own slice (a..b, top down) of the limb's picture
		local h = r[4] * (c.b - c.a)
		local x, y = (cell % cols) * cw + r[1], (cell // cols) * ch + r[2] + r[4] * c.a
		local part = f.parts[c.part]
		local sz = part.Size
		local face = c.face
		local W, H = if face == "L" or face == "R" then sz.Z else sz.X, if face == "U" or face == "D" then sz.Z else sz.Y
		local su, sv = W * A / r[3], H * A / h
		-- (27 Nov, tested in Studio) on a MeshPart a Texture's origin is the face's middle, on a Part its corner
		local mid = if part:IsA("MeshPart") then 0.5 else 0
		t.StudsPerTileU, t.StudsPerTileV = su, sv
		t.OffsetStudsU, t.OffsetStudsV = x / A * su + W * mid, y / A * sv + H * mid
	end
end

local function newFigure(): Figure
	local model = Instance.new("Model")
	model.Name = "Person"
	local parts = {}
	local face: Decal? = nil
	local extraOf = {}
	local tex = {}
	-- the clothes: one Texture per clothed face, cropped out of the shared atlases in dress() (U only on a limb's top)
	-- (27 Nov, owner: "i can see their skin between the joints") the faces a joint opens (a piece's bottom, the top
	-- of a lower piece) wear the clothes too: the front's 2-pixel row at that edge (a short sleeve's row stays skin)
	local function clothe(p: BasePart, idx: number, k: number, a: number, b: number, top: boolean, sole: boolean)
		local c = CLOTHED[k]
		if not (c and CLOTH) then
			return
		end
		local e = 2 / 64
		for _, fc in { "F", "B", "L", "R", "U", "D" } do
			if not (fc == "D" and sole) then
				local t = Instance.new("Texture")
				t.Texture = "rbxassetid://" .. CLOTH.atlas[c[1]]
				t.Face = FACE_IDS[fc]
				t.Parent = p
				local ent = { t = t, part = idx, atlas = c[1], group = c[2], face = fc, a = a, b = b }
				if fc == "U" and top then
					ent.a, ent.b = 0, 1
				elseif fc == "U" then
					ent.joint, ent.b = true, math.min(1, a + e)
				elseif fc == "D" then
					ent.joint, ent.a = true, math.max(0, b - e)
				end
				table.insert(tex, ent)
			end
		end
	end
	for k = 1, NPART do
		local lk = limbKit[k]
		local src = if lk then lk.pieces[1].tpl elseif k == 2 then headKit else nil
		local p: BasePart = if src then src:Clone() else Instance.new("Part")
		quiet(p)
		p.Material = Enum.Material.SmoothPlastic
		if p:IsA("Part") then
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
		end
		p.Name = NAMES[k]
		p.Size = R6.size[k]
		if k == 2 then
			if not src then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Head
				mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
				mesh.Parent = p
			end
			local d = Instance.new("Decal")
			d.Name = "face"
			d.Face = Enum.NormalId.Front
			d.Parent = p
			face = d
		end
		p.Parent = model
		parts[k] = p
		clothe(p, k, k, if lk then lk.pieces[1].a else 0, if lk then lk.pieces[1].b else 1, true, not lk and (k == 4 or k == 7))
	end
	-- the Blocky limbs' other pieces (parts 8+), posed with their limb
	for _, k in LIMB_K do
		local lk = limbKit[k]
		if lk then
			for i = 2, #lk.pieces do
				local pc = lk.pieces[i]
				local p = pc.tpl:Clone()
				quiet(p)
				p.Material = Enum.Material.SmoothPlastic
				p.Name = NAMES[k] .. i
				p.Parent = model
				table.insert(parts, p)
				extraOf[#parts] = { k = k, i = i }
				-- (hands stay bare skin: 8 Textures a person fewer)
				if not ((k == 5 or k == 6) and i == #lk.pieces) then
					clothe(p, #parts, k, pc.a, pc.b, false, (k == 4 or k == 7) and i == #lk.pieces)
				end
			end
		end
	end
	return {
		model = model, parts = parts, cfs = table.create(#parts, CFrame.new()), face = face, scale = 1,
		hairOff = CFrame.new(R6.cen[3] - R6.cen[2]), bald = false, geo = R6, hairKind = "", tex = tex,
		hairSize = R6.size[3], extraOf = extraOf,
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
	f.shadow = nil -- (the new hair piece: pedTick sets its shadow again)
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
	local extra = f.geo.extra
	for k, p in f.parts do
		p.Color = if k == 3 then pick(HAIR_COLS) else skin
		local ex = f.extraOf[k]
		p.Size = (if k == 3 then f.hairSize elseif ex and extra then extra[ex.k][ex.i].size else f.geo.size[k]) * s
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

-- (27 Nov) the pose comes from PedMotion: a procedural walk / run with knees, elbows, ankles, pelvis and chest, the
-- standing idle and the keyed knock-over actions (see its header and the vault research note)
local function pose(w: Walker, moving: boolean)
	local f = w.fig
	local s = f.scale
	local P = PedMotion.angles(w, moving)
	local ho = f.hairOff
	PedMotion.build(f, P, CFrame.new(w.pos) * CFrame.Angles(0, w.yaw, 0), s, ho - ho.Position + (ho.Position + hairShift) * s)
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
-- (27 Nov) kit pieces can be turned any way (the bin template lies on its side: its Y axis is horizontal), so a
-- part's footprint is its two most level axes: { vertical axis, the two level axes, half sizes } by object axis 1-3
local blockShape: { [BasePart]: { v: number, a: number, b: number, h: { number } } } = {}
local function shapeOf(q: BasePart)
	local sh = blockShape[q]
	if sh then
		return sh
	end
	local cf = q.CFrame
	local ups = { math.abs(cf.RightVector.Y), math.abs(cf.UpVector.Y), math.abs(cf.LookVector.Y) }
	local v = if ups[1] >= ups[2] and ups[1] >= ups[3] then 1 elseif ups[2] >= ups[3] then 2 else 3
	local a, b = if v == 1 then 2 else 1, if v == 3 then 2 else 3
	sh = { v = v, a = a, b = b, h = { q.Size.X / 2, q.Size.Y / 2, q.Size.Z / 2 } }
	blockShape[q] = sh
	return sh
end
local function axisOf(cf: CFrame, i: number): Vector3
	return if i == 1 then cf.RightVector elseif i == 2 then cf.UpVector else cf.LookVector
end
local function comp(v: Vector3, i: number): number
	return if i == 1 then v.X elseif i == 2 then v.Y else v.Z
end

local function blockAdd(q: Instance)
	if not q:IsA("BasePart") or blockKeys[q] or not q:IsDescendantOf(workspace) then
		return
	end
	local sh = shapeOf(q)
	local r = Vector2.new(sh.h[sh.a], sh.h[sh.b]).Magnitude + BLOCK_PAD + 2 -- (+2: a walker's own width, curving early)
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
	blockShape[q :: any] = nil
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
			local sh = shapeOf(q)
			local lp = q.CFrame:PointToObjectSpace(p)
			local la, lb = comp(lp, sh.a), comp(lp, sh.b)
			local ha, hb = sh.h[sh.a] + BLOCK_PAD, sh.h[sh.b] + BLOCK_PAD
			if math.abs(la) < ha and math.abs(lb) < hb and math.abs(comp(lp, sh.v)) < sh.h[sh.v] + 6 then
				local ld = q.CFrame:VectorToObjectSpace(toward)
				local da, db = comp(ld, sh.a), comp(ld, sh.b)
				local t = math.huge
				if math.abs(da) > 1e-3 then
					t = math.min(t, ((if da > 0 then ha else -ha) - la) / da)
				end
				if math.abs(db) > 1e-3 then
					t = math.min(t, ((if db > 0 then hb else -hb) - lb) / db)
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

-- (27 Nov, owner: "the characters are walking into trash bins, make it so that they can go around (ANIMATION MUST LOOK
-- LIKE AN ACTUAL HUMAN GOING AROUND, NOT JUST ROTATING CHARACTER ...)", "1 in 25 people knocks the trash bin down",
-- "1 in 10 people that cross the road will run") walkers steer: the heading turns at a limited, eased rate toward the
-- next point; things tagged PedBlock 2-3 s ahead are passed on a curve that starts early (the head turns first, the
-- chest leads the hips, the body leans into the curve); a knocker (1 in 25) walks up to the first bin (tag PedBin) and
-- kicks, pushes or shoulder-slams it (PedMotion's keyed actions; the bin tips over on the client's physics and is put
-- back unseen); at a pavement's end a walker looks both ways and crosses to the next pavement ahead (1 in 10 run)
local WALK_SPEED = { 2.6, 3.8 } -- studs a second: an easy stroll; the stride then stays human on Roblox's short legs
local RUN_SPEED = { 9, 11.5 }
local TURN_RATE = { walk = 2.3, run = 3.0 } -- rad/s at most
local LOOK_AHEAD = 2.6 -- seconds of walking checked for things in the way
local KNOCK_SHARE = 1 / 25
local CROSS_RUN = 1 / 10
local binTag: { [Instance]: boolean } = {}
type Fallen = { cf: CFrame, anch: boolean, coll: boolean, mless: boolean, t: number }
local fallen: { [BasePart]: Fallen } = {}

local function heading(yaw: number): Vector3
	return Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
end

local function wrapA(a: number): number
	return (a + math.pi) % (2 * math.pi) - math.pi
end

-- turn toward p: eased, rate-limited; the head turns first, the chest a little ahead of the hips, lean into the curve
local function steer(w: Walker, p: Vector3, dt: number): number
	local to = Vector3.new(p.X - w.pos.X, 0, p.Z - w.pos.Z)
	local dy = if to.Magnitude > 0.05 then wrapA(math.atan2(-to.X, -to.Z) - w.yaw) else 0
	local maxR = TURN_RATE[w.gait or "walk"] or 2.3
	local rateTo = math.clamp(dy * 2.4, -maxR, maxR)
	local rate = w.yawRate or 0
	rate += (rateTo - rate) * math.min(1, dt * 5)
	w.yawRate = rate
	w.yaw += rate * dt
	w.lookTo = math.clamp(dy * 0.9, -1.1, 1.1)
	w.twist = math.clamp(dy * 0.3, -0.25, 0.25)
	w.lean = math.clamp(rate * w.speed * 0.012, -0.08, 0.08)
	return dy
end

local function easeLook(w: Walker, dt: number)
	local to = w.lookTo or 0
	if w.glance then -- (after a knock-over) a look back at the bin
		w.glance.t -= dt
		to = w.glance.yaw
		if w.glance.t <= 0 then
			w.glance = nil
		end
	end
	local cur = w.look or 0
	w.look = cur + (to - cur) * math.min(1, dt * 4)
end

-- the nearest PedBlock part in the way within `dist` ahead: part, the clearance needed and which side it is on
local function obstacleAhead(w: Walker, dist: number): (BasePart?, number, number)
	local hd = heading(w.yaw)
	local side = Vector3.new(-hd.Z, 0, hd.X)
	local best, bestAlong, bestNeed, bestLat = nil, math.huge, 0, 0
	local seen = {}
	for _, a in { 0, 0.5, 1 } do
		local p = w.pos + hd * (dist * a)
		local list = blockCells[cellKey(math.floor(p.X / BLOCK_CELL), math.floor(p.Z / BLOCK_CELL))]
		if list and not seen[list] then
			seen[list] = true
			for _, q in list do
				if q.Parent and not fallen[q] then
					local rel = q.Position - w.pos
					local along = rel:Dot(hd)
					if along > 0.2 and along < dist and math.abs(rel.Y) < 8 then
						local sh = shapeOf(q)
						local ext = math.abs(side:Dot(axisOf(q.CFrame, sh.a))) * sh.h[sh.a]
							+ math.abs(side:Dot(axisOf(q.CFrame, sh.b))) * sh.h[sh.b]
						local need = ext + 0.95 * w.fig.scale + 0.35
						local lat = rel:Dot(side)
						if math.abs(lat) < need and along < bestAlong then
							best, bestAlong, bestNeed, bestLat = q, along, need, lat
						end
					end
				end
			end
		end
	end
	return best, bestNeed, bestLat
end

-- a bin tips over: free on the client's physics, pushed the way it was hit, put back later unseen
local function knockBin(q: BasePart, dir: Vector3, kind: string)
	if fallen[q] then
		return
	end
	-- (its first home is kept on the part: a second knock never takes a fallen spot as home)
	local home = q:GetAttribute("PedHome") :: CFrame?
	if not home then
		home = q.CFrame
		q:SetAttribute("PedHome", home)
	end
	fallen[q] = { cf = home :: CFrame, anch = q.Anchored, coll = q.CanCollide, mless = q.Massless, t = 0 }
	q.Anchored = false
	q.CanCollide = true
	q.Massless = false -- (the kit pieces are massless: one alone slid without tipping; tested in Play)
	local sp = if kind == "kick" then 17 elseif kind == "push" then 14 else 12
	local up = if kind == "kick" then 7 else 5
	q.AssemblyLinearVelocity = dir * sp + Vector3.new(0, up, 0)
	q.AssemblyAngularVelocity = Vector3.yAxis:Cross(dir) * (if kind == "kick" then 10 else 8)
		+ Vector3.new(0, rng:NextNumber(-2, 2), 0)
end

local function binsTick(dt: number, cam: Vector3, look: Vector3)
	for q, st in fallen do
		st.t += dt
		if not q.Parent then
			fallen[q] = nil
		else
			local away = (q.Position - cam).Magnitude > 90 or (q.Position - cam):Dot(look) < 0
			if (st.t > 12 and away) or st.t > 90 then
				q.Anchored = st.anch
				q.CanCollide = st.coll
				q.Massless = st.mless
				q.CFrame = st.cf
				q.AssemblyLinearVelocity = Vector3.zero
				q.AssemblyAngularVelocity = Vector3.zero
				fallen[q] = nil
			end
		end
	end
end

-- a crossing from the end of this pavement: the nearest point of another pavement path 16-75 studs ahead, with
-- nothing solid between (raycast at chest height) and no big climb
local crossRay = RaycastParams.new()
crossRay.FilterType = Enum.RaycastFilterType.Exclude
-- nothing big in the way at chest height (a building, a wall); poles, signs, props and cars don't count
local function lineClear(p: Vector3, q: Vector3): boolean
	local skip: { Instance } = { pedFolder :: Instance, carFolder :: Instance }
	for _, n in { "PlayerCars", "Traffic" } do
		local f = workspace:FindFirstChild(n)
		if f then
			table.insert(skip, f)
		end
	end
	local a, b = p + Vector3.new(0, 3.5, 0), q + Vector3.new(0, 3.5, 0)
	for _ = 1, 5 do
		crossRay.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(a, b - a, crossRay)
		if not hit then
			return true
		end
		local sz = hit.Instance.Size
		if math.max(sz.X, sz.Y, sz.Z) > 14 then
			return false
		end
		table.insert(skip, hit.Instance)
	end
	return true
end
local function findCross(w: Walker): (number?, number?, Vector3?)
	local p = w.pos
	local hd = heading(w.yaw)
	local cx, cz = math.floor(p.X / CELL), math.floor(p.Z / CELL)
	local best, bestPi, bestK, bestPt = math.huge, nil, nil, nil
	for gx = cx - 1, cx + 1 do
		for gz = cz - 1, cz + 1 do
			local list = pathCells[cellKey(gx, gz)]
			if list then
				for e = 1, #list // 2 do
					local pi, k = list[2 * e - 1], list[2 * e]
					local pts = paths[pi]
					local q = pts[k]
					if pts ~= w.path and q and math.abs(q.Y - p.Y) < 4 then
						local d = flat(q, p)
						if d > 16 and d < 75 then
							local dv = Vector3.new(q.X - p.X, 0, q.Z - p.Z) / d
							local dot = dv:Dot(hd)
							local score = d * (1.6 - dot)
							if dot > 0.3 and score < best then
								best, bestPi, bestK, bestPt = score, pi, k, q
							end
						end
					end
				end
			end
		end
	end
	if bestPt then
		if not lineClear(p, bestPt) then
			return nil
		end
	end
	return bestPi, bestK, bestPt
end

---------------------------------------------------------------------
-- (owner, 27 Nov: "make it so that npc characters can cross the road when the traffic light is green. ... if 1 side
-- traffic light is clear, let npc characters go and then wait at a place where it meets the other side lane that has
-- the red light. and when that red light becomes green, they continue") signal crossings. At a pavement end by a
-- signalled junction (RivieraTraffic.build().signals, the lights YangonSignals draws and Traffic obeys) a walker
-- crosses to a pavement across a road whose lane pieces the crossing line cuts square. The lanes it cuts are split by
-- the way their cars go: one carriageway per direction. Each is a stage, and a stage starts only while that traffic
-- has red with time left to get over; between the two the walker waits where the carriageways meet (the median, or
-- the centre line when there is none: never in a live lane). People on the road are obstacles for Traffic, so cars
-- turning in on their green wait for them too.
---------------------------------------------------------------------
local SIG_CELL = 64
local SIG_PACE = 1.3 -- crossing on the lights: a brisker walk
local sigState = 0 -- 0 not tried, 1 ready, -1 no signals
local sigCells: { [number]: { any } } = {} -- approaches by the cell of their junction's centre
local laneCells: { [number]: { any } } = {} -- lane pieces near a junction, by the cells their chord touches
local groundRay = RaycastParams.new()
groundRay.FilterType = Enum.RaycastFilterType.Include

local function sigInit(): boolean
	if sigState ~= 0 then
		return sigState > 0
	end
	local ok, g = pcall(RivieraTraffic.build)
	if not ok or not g or not g.signals or #g.signals == 0 then
		sigState = -1
		return false
	end
	sigState = 1
	for _, s in g.signals do
		local key = cellKey(math.floor(s.center.X / SIG_CELL), math.floor(s.center.Z / SIG_CELL))
		sigCells[key] = sigCells[key] or {}
		table.insert(sigCells[key], s)
	end
	for _, seg in g.lanes do
		if seg.kind == "lane" then
			local m = (seg.p0 + seg.p2) / 2
			local gx, gz = math.floor(m.X / SIG_CELL), math.floor(m.Z / SIG_CELL)
			local near = false
			for dx = -2, 2 do
				for dz = -2, 2 do
					near = near or sigCells[cellKey(gx + dx, gz + dz)] ~= nil
				end
			end
			if near then
				local seen = {}
				for _, q in { seg.p0, m, seg.p2 } do
					local key = cellKey(math.floor(q.X / SIG_CELL), math.floor(q.Z / SIG_CELL))
					if not seen[key] then
						seen[key] = true
						laneCells[key] = laneCells[key] or {}
						table.insert(laneCells[key], seg)
					end
				end
			end
		end
	end
	return true
end

-- the junction (its approaches) whose middle is within reach of p, or nil
local function junctionNear(p: Vector3): { any }?
	local gx, gz = math.floor(p.X / SIG_CELL), math.floor(p.Z / SIG_CELL)
	local best, bd = nil, math.huge
	for dx = -2, 2 do
		for dz = -2, 2 do
			for _, s in sigCells[cellKey(gx + dx, gz + dz)] or {} do
				local d = flat(s.center, p)
				if d < s.radius + 45 and d < bd and math.abs(s.center.Y - p.Y) < 8 then
					best, bd = s.i, d
				end
			end
		end
	end
	if not best then
		return nil
	end
	local list = {}
	for dx = -2, 2 do
		for dz = -2, 2 do
			for _, s in sigCells[cellKey(gx + dx, gz + dz)] or {} do
				if s.i == best then
					table.insert(list, s)
				end
			end
		end
	end
	return list
end

-- the stages of a crossing a -> b at a junction (its approaches), or nil when the line doesn't cut its lanes square
local function crossingPlan(a: Vector3, b: Vector3, approaches: { any }): any?
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local L = ab.Magnitude
	if L < 8 then
		return nil
	end
	local cdir = ab / L
	local right = cdir:Cross(Vector3.yAxis)
	local hits, seen = {}, {}
	for k = 0, math.ceil(L / 32) do
		local q = a + ab * math.min(1, k * 32 / L)
		local gx, gz = math.floor(q.X / SIG_CELL), math.floor(q.Z / SIG_CELL)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, seg in laneCells[cellKey(gx + dx, gz + dz)] or {} do
					if not seen[seg] then
						seen[seg] = true
						-- where the chords cross (flat)
						local r = ab
						local s = Vector3.new(seg.p2.X - seg.p0.X, 0, seg.p2.Z - seg.p0.Z)
						local den = r.X * s.Z - r.Z * s.X
						if math.abs(den) > 1e-6 then
							local qp = Vector3.new(seg.p0.X - a.X, 0, seg.p0.Z - a.Z)
							local t = (qp.X * s.Z - qp.Z * s.X) / den
							local u = (qp.X * r.Z - qp.Z * r.X) / den
							if t > 0 and t < 1 and u >= 0 and u <= 1 then
								local y = seg.p0.Y + (seg.p2.Y - seg.p0.Y) * u
								if math.abs(y - (a.Y + (b.Y - a.Y) * t)) < 5 then
									local d = s.Unit
									if math.abs(d:Dot(cdir)) > 0.5 then
										return nil -- (along the road or across the junction box: not a crossing)
									end
									table.insert(hits, { t = t * L, y = y, side = if d:Dot(right) > 0 then 1 else -1, dir = d })
								end
							end
						end
					end
				end
			end
		end
	end
	if #hits == 0 then
		return nil
	end
	table.sort(hits, function(x, y)
		return x.t < y.t
	end)
	-- the carriageways: runs of lanes going one way
	local groups = {}
	for _, h in hits do
		local g = groups[#groups]
		if g and g.side == h.side then
			g.t1 = h.t
			g.y = h.y
		else
			if #groups == 2 then
				return nil -- (more than two runs: not one road)
			end
			table.insert(groups, { side = h.side, t0 = h.t, t1 = h.t, y = h.y, dir = h.dir })
		end
	end
	for _, g in groups do
		for _, s in approaches do
			if math.abs(s.dir:Dot(g.dir)) > 0.7 then
				g.axis = s.axis
				break
			end
		end
	end
	if #groups == 2 then
		groups[1].axis = groups[1].axis or groups[2].axis
		groups[2].axis = groups[2].axis or groups[1].axis
	end
	if not groups[1].axis then
		return nil -- (a road this junction's lights don't hold)
	end
	local stages = {}
	if #groups == 1 then
		stages[1] = { to = b, axis = groups[1].axis, len = L }
	else
		-- wait where the two carriageways meet: half way between their nearest lanes' middles
		local tw = (groups[1].t1 + groups[2].t0) / 2
		local w = a + ab * (tw / L)
		local y = (groups[1].y + groups[2].y) / 2
		local root = Config.mapRoot and Config.mapRoot()
		if root then
			groundRay.FilterDescendantsInstances = { root }
			local hit = workspace:Raycast(Vector3.new(w.X, y + 6, w.Z), Vector3.new(0, -12, 0), groundRay)
			if hit then
				y = hit.Position.Y
			end
		end
		w = Vector3.new(w.X, y, w.Z)
		stages[1] = { to = w, axis = groups[1].axis, len = tw }
		stages[2] = { to = b, axis = groups[2].axis, len = L - tw }
	end
	return { i = approaches[1].i, stages = stages, k = 1 }
end

-- may this stage start now: its traffic has red, with time left to get over
local function gateOpen(w: Walker, sg: any, st: any): boolean
	local now = workspace:GetServerTimeNow()
	if CityLayout.lightState(sg.i, 0, st.axis, now) ~= "R" then
		return false
	end
	-- (people step out briskly on the lights: SIG_PACE; a wide carriageway that takes longer than a whole red starts
	-- as the red starts: cars are held then, and Traffic stops for people on the road anyway)
	local L = Config.Lights
	local need = math.min(st.len / math.max(w.speed * SIG_PACE, 4.2) + 1.0, L.Cycle - L.Green - L.Yellow - 1.5)
	return CityLayout.lightTimeLeft(sg.i, 0, st.axis, now) >= need
end

-- a signal crossing from this pavement end: (path, index, far point, plan) or nil. It goes over a zebra: each arm of
-- the junction has one just before its lanes end, square to the road. The walker walks along the kerb to the zebra's
-- near end (plan.pre, up to ZEBRA_WALK studs, crossing no lanes), waits there, crosses on the zebra's line in its
-- stages to the far end, then walks on to the far pavement's path (the returned point)
local ZEBRA_BACK = 5 -- studs back from the first approach lane's end (measured from above, 28 Nov) to the zebra's middle
local ZEBRA_WALK = 35
local function findSignalCross(w: Walker): (number?, number?, Vector3?, any?)
	if not sigInit() then
		return nil
	end
	local p = w.pos
	local approaches = junctionNear(p)
	if not approaches then
		return nil
	end
	-- the arms: approaches grouped by heading (30-degree buckets), the middle of their stop points
	local arms, byKey = {}, {}
	for _, ap in approaches do
		local key = math.floor((math.atan2(ap.dir.X, ap.dir.Z) + math.pi) / (math.pi / 6) + 0.5) % 12
		local arm = byKey[key]
		if not arm then
			arm = { dir = ap.dir, sum = Vector3.zero, n = 0, first = math.huge }
			byKey[key] = arm
			table.insert(arms, arm)
		end
		arm.sum += ap.pos
		arm.n += 1
		arm.first = math.min(arm.first, ap.pos:Dot(arm.dir))
	end
	local best, bestScore = nil, math.huge
	for _, arm in arms do
		local dir = Vector3.new(arm.dir.X, 0, arm.dir.Z).Unit
		local perp = dir:Cross(Vector3.yAxis)
		local mid = arm.sum / arm.n
		local z = mid + dir * (arm.first - mid:Dot(arm.dir) - ZEBRA_BACK)
		local sp = Vector3.new(p.X - z.X, 0, p.Z - z.Z):Dot(perp)
		local za = Vector3.new(z.X + perp.X * sp, p.Y, z.Z + perp.Z * sp)
		local walkA = flat(za, p)
		-- (the kerb walk must not cross a road of its own: a plan between p and za means lanes in the way)
		if walkA < ZEBRA_WALK and (walkA < 2 or not crossingPlan(p, za, approaches)) then
			local cx, cz = math.floor(z.X / CELL), math.floor(z.Z / CELL)
			for gx = cx - 1, cx + 1 do
				for gz = cz - 1, cz + 1 do
					local list = pathCells[cellKey(gx, gz)]
					for e = 1, (if list then #list // 2 else 0) do
						local pi, k = list[2 * e - 1], list[2 * e]
						local pts = paths[pi]
						local q = pts[k]
						if pts ~= w.path and q and math.abs(q.Y - p.Y) < 4 then
							local sq = Vector3.new(q.X - z.X, 0, q.Z - z.Z):Dot(perp)
							if sq * sp < 0 and math.abs(sq - sp) > 10 then
								local zb = Vector3.new(z.X + perp.X * sq, q.Y, z.Z + perp.Z * sq)
								local walkB = flat(zb, q)
								local score = walkA + walkB + rng:NextNumber(0, 15)
								if walkB < ZEBRA_WALK and score < bestScore then
									local plan = crossingPlan(za, zb, approaches)
									if plan and lineClear(za, zb) then
										plan.pre = za
										best, bestScore = { pi = pi, k = k, q = q, plan = plan }, score
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if best then
		return best.pi, best.k, best.q, best.plan
	end
	return nil
end

-- (owner, 27 Nov: "also add an idle animation") standing people now and then take the phone out for a look
local function idleTick(w: Walker, dt: number)
	w.peekT = (w.peekT or rng:NextNumber(2, 8)) - dt
	if (w.peekT :: number) > 0 then
		return
	end
	if w.peekOn then
		w.phone, w.peekOn = nil, nil
		w.peekT = rng:NextNumber(6, 16)
	elseif not w.phone and rng:NextNumber() < 0.4 then
		w.phone, w.peekOn = "hand", true
		w.peekT = rng:NextNumber(2, 4.5)
	else
		w.peekT = rng:NextNumber(5, 12)
	end
end

local function idleEnd(w: Walker)
	if w.peekOn then
		w.phone, w.peekOn = nil, nil
	end
end

---------------------------------------------------------------------
-- (owner, 27 Nov: "make it so that npc characters can start running if ur car is near them and faces them, and also
-- if ur car stands in their way, they can turn around because theyre scared or walk around ur car") players' cars.
-- A car coming at someone (moving toward them, them in its path, nearer the faster it goes): a startled look, then a
-- run sideways out of its path, then calm again with a look back. A car standing near: a wary look. A car standing
-- across the way: walk round it (like a bin, past its far end) or, scared or with no room, turn round.
---------------------------------------------------------------------
local pcars: { any } = {}
local pcarT = 0
local function refreshPCars(dt: number)
	pcarT -= dt
	if pcarT > 0 then
		return
	end
	pcarT = 0.15
	table.clear(pcars)
	local f = workspace:FindFirstChild("PlayerCars")
	if not f then
		return
	end
	for _, m in f:GetChildren() do
		local root = if m:IsA("Model") then m.PrimaryPart else nil
		if root then
			local v = root.AssemblyLinearVelocity
			local lv = root.CFrame.LookVector
			local fwd = Vector3.new(lv.X, 0, lv.Z)
			table.insert(pcars, {
				pos = root.Position, root = root, vel = Vector3.new(v.X, 0, v.Z),
				fwd = if fwd.Magnitude > 0.01 then fwd.Unit else Vector3.zAxis,
				halfLen = ((m:GetAttribute("Length") :: number?) or 14) / 2, width = (m:GetAttribute("Width") :: number?) or 6,
			})
		end
	end
end

-- a car's half extent along a flat direction
local function carExt(c: any, d: Vector3): number
	local r = c.fwd:Cross(Vector3.yAxis)
	return math.abs(d:Dot(c.fwd)) * c.halfLen + math.abs(d:Dot(r)) * c.width / 2
end

-- what a car near w is doing to it: "flee" (coming at it) with the car, its moving direction, lateral offset and
-- speed; "wary" (standing close by) with the car; or nil
local function carThreat(w: Walker): (string?, any?, Vector3?, number, number)
	for _, c in pcars do
		local rel = w.pos - c.pos
		local d = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
		if d < 45 and math.abs(rel.Y) < 8 then
			local sp = c.vel.Magnitude
			-- (over ~11 km/h: slower, they hold their ground and a nudge is a stumble back: PedHits / bump)
			if sp > 9 then
				local dir = c.vel / sp
				local along = rel:Dot(dir) - c.halfLen
				local lat = rel:Dot(dir:Cross(Vector3.yAxis))
				if along > -1 and along < 8 + sp * 2.2 and math.abs(lat) < c.width / 2 + 3 then
					return "flee", c, dir, lat, sp
				end
			elseif d < c.halfLen + 10 then
				return "wary", c, nil, 0, sp
			end
		end
	end
	return nil, nil, nil, 0, 0
end

-- start the flight: a point beside the car's path, away from the road when it can be (and nothing big in the way)
local function startFlee(w: Walker, c: any, dir: Vector3, lat: number, sp: number)
	local right = dir:Cross(Vector3.yAxis)
	local sgn = if lat > 0.6 then 1 elseif lat < -0.6 then -1 else 0
	if sgn == 0 then
		local kerb = kerbSide(w)
		sgn = if kerb and right:Dot(kerb) > 0 then -1 elseif kerb then 1 elseif rng:NextNumber() < 0.5 then 1 else -1
	end
	local function spot(s: number): Vector3
		local p = w.pos + right * (s * (c.width / 2 + 4.5) - lat) + dir * 1.5
		return Vector3.new(p.X, w.pos.Y, p.Z)
	end
	local p = spot(sgn)
	if not lineClear(w.pos, p) then
		p = spot(-sgn)
	end
	idleEnd(w)
	local toCar = c.pos - w.pos
	w.flee = {
		p = p, t = 0, startle = math.clamp(0.42 - sp * 0.01, 0.12, 0.4), prev = w.mode, car = c,
		lookYaw = math.clamp(wrapA(math.atan2(-toCar.X, -toCar.Z) - w.yaw), -1.4, 1.4),
	}
	w.mode = "flee" -- (its own mode: no kerb wait, pause or crossing step runs while it lasts)
	w.fearT = 10
end

-- (27 Nov, owner: "when i go slow near npc character and bump them with my car, they just teleport 2 studs away rn")
-- a slow bump (PedHits): pushed back over half a second along the car's push (eased), facing the car with the hands
-- out on the bonnet and stumbling steps back (PedMotion "bumped"). While the car keeps pushing they keep stepping
-- back in front of it (never inside its box); then a look, and a step aside out of its way or a shaken fist.
local function startBump(w: Walker, root: BasePart, v: Vector3)
	local model = root:FindFirstAncestorOfClass("Model")
	local vf = Vector3.new(v.X, 0, v.Z)
	local sp = vf.Magnitude
	local away = Vector3.new(w.pos.X - root.Position.X, 0, w.pos.Z - root.Position.Z)
	local dir = if sp > 0.1 then vf / sp elseif away.Magnitude > 0.01 then away.Unit else heading(w.yaw)
	local rv = root.CFrame.RightVector
	local right = Vector3.new(rv.X, 0, rv.Z)
	if right.Magnitude > 0.01 then
		right = right.Unit
		dir = (dir + right * (if away:Dot(right) >= 0 then 0.35 else -0.35)).Unit
	end
	local b = w.bump
	if b then -- (bumped again while stumbling: a fresh push from here)
		b.dir, b.x, b.t, b.D = dir, 0, 0, math.clamp(0.6 + sp * 0.1, 0.6, 2)
		return
	end
	idleEnd(w)
	w.flee, w.avoid, w.knockAt = nil, nil, nil
	w.bump = {
		dir = dir, root = root, t = 0, dur = 0.5, x = 0, D = math.clamp(1 + sp * 0.12, 1, 2.6),
		halfL = (((model and model:GetAttribute("Length")) :: number?) or 16) / 2,
		halfW = (((model and model:GetAttribute("Width")) :: number?) or 7) / 2,
	}
	w.act = { kind = "bumped", t = 0 }
	w.fearT = 10
end

local function bumpStep(w: Walker, dt: number)
	local b = w.bump :: any
	local root = b.root :: BasePart
	b.t += dt
	-- facing the car (eased: the body comes round to it)
	if root.Parent then
		local to = root.Position - w.pos
		w.yaw += wrapA(math.atan2(-to.X, -to.Z) - w.yaw) * math.min(1, dt * 6)
	end
	w.yawRate, w.twist, w.lean = 0, 0, 0
	-- the push: eased out over dur
	local a = math.clamp(b.t / b.dur, 0, 1)
	local x = b.D * a * a * (3 - 2 * a)
	w.pos += b.dir * (x - b.x)
	b.x = x
	-- never inside the car: in front of it, a hand's width off, while it keeps coming
	local pushed = false
	if root.Parent then
		local lv = root.CFrame.LookVector
		local f = Vector3.new(lv.X, 0, lv.Z)
		f = if f.Magnitude > 0.01 then f.Unit else Vector3.zAxis
		local r = f:Cross(Vector3.yAxis)
		local rel = Vector3.new(w.pos.X - root.Position.X, 0, w.pos.Z - root.Position.Z)
		local perp = b.dir:Cross(Vector3.yAxis)
		local supp = math.abs(b.dir:Dot(f)) * b.halfL + math.abs(b.dir:Dot(r)) * b.halfW + 1.1 * w.fig.scale
		local wide = math.abs(perp:Dot(f)) * b.halfL + math.abs(perp:Dot(r)) * b.halfW + 1.1 * w.fig.scale
		local d = rel:Dot(b.dir)
		if d < supp and d > -supp and math.abs(rel:Dot(perp)) < wide then
			w.pos += b.dir * (supp - d)
			pushed = true
		end
	end
	-- the stumble: played on, or back and forth over the steps while pushed
	local act = w.act
	if not act or act.kind ~= "bumped" then
		act = { kind = "bumped", t = 0.3 }
		w.act = act
	end
	if pushed and act.t >= 0.5 then
		b.rev = true
	end
	if b.rev then
		act.t -= dt
		if act.t <= 0.12 then
			act.t = 0.12
			b.rev = nil
		end
	else
		act.t += dt
	end
	if not pushed and not b.rev and act.t >= PedMotion.ACTIONS.bumped.dur then
		-- over it: a look at the car, then out of its way (a step aside) or a shaken fist at the driver
		w.bump = nil
		w.act = nil
		local to = root.Position - w.pos
		w.glance = { yaw = math.clamp(wrapA(math.atan2(-to.X, -to.Z) - w.yaw), -1.5, 1.5), t = 1.2 }
		if rng:NextNumber() < 0.35 then
			w.act = { kind = "fist", t = 0 }
		elseif w.mode ~= "stand" and root.Parent then
			local perp = b.dir:Cross(Vector3.yAxis)
			local s = if rng:NextNumber() < 0.5 then 1 else -1
			local p = w.pos + perp * s * (b.halfW + 3.5) + b.dir * 1.5
			p = Vector3.new(p.X, w.pos.Y, p.Z)
			if not lineClear(w.pos, p) then
				p = w.pos - perp * s * (b.halfW + 3.5) + b.dir * 1.5
				p = Vector3.new(p.X, w.pos.Y, p.Z)
			end
			w.avoid = { q = root, p = p, car = true }
			if w.mode == "pause" or w.mode == "look" then
				w.mode = "walk"
			end
		end
	end
end
YangonStreetLife.bump = startBump

-- a car standing across the way ahead within dist: walk round it, or turn back (scared, or no room). true = acted
local function carBlocked(w: Walker, dist: number): boolean
	local hd = heading(w.yaw)
	local side = Vector3.new(-hd.Z, 0, hd.X)
	for _, c in pcars do
		if c.vel.Magnitude < 3 then
			local rel = c.pos - w.pos
			local along = rel:Dot(hd)
			local alongExt = carExt(c, hd)
			if along > 0 and along - alongExt < dist and math.abs(rel.Y) < 8 then
				local need = carExt(c, side) + 0.95 * w.fig.scale + 0.6
				local lat = rel:Dot(side)
				if math.abs(lat) < need then
					local scared = (w.fearT or 0) > 0
					local function round(sgn: number): Vector3?
						local p = c.pos + side * sgn * (need + 1.4) + hd * (alongExt + 1)
						p = Vector3.new(p.X, w.pos.Y, p.Z)
						if lineClear(w.pos, p) then
							return p
						end
						return nil
					end
					local first = if math.abs(lat) > 0.25 then -math.sign(lat) else (if rng:NextNumber() < 0.5 then 1 else -1)
					local p = round(first) or round(-first)
					local back = w.mode ~= "cross" and w.path ~= nil and (not p or rng:NextNumber() < (if scared then 0.8 else 0.3))
					if back then
						-- turn round on the spot (eased), then walk back the way they came
						-- (heading for k + dir: the way back starts at that point, just behind once turned)
						if w.path and w.path[w.k + w.dir] then
							w.k += w.dir
						end
						w.dir = -w.dir
						w.mode = "pause"
						w.timer = rng:NextNumber(0.5, 1.1)
						w.pauseYaw = w.yaw + math.pi * (if rng:NextNumber() < 0.5 then 1 else -1)
						w.avoid = nil
						return true
					elseif p then
						w.avoid = { q = c.root, p = p, car = true }
						return true
					end
				end
			end
		end
	end
	return false
end

local function setGait(w: Walker, gait: string)
	w.gait = gait
	w.speed = if gait == "run" then rng:NextNumber(RUN_SPEED[1], RUN_SPEED[2]) else (w.walkSpeed or 3)
end

-- never inside another person: ease apart from anyone nearer than 2.4 studs (20 people: cheap); also while waiting
-- at a crossing, where a few stand on one spot
local function separate(w: Walker, dt: number)
	local s = w.fig.scale
	for _, o in active do
		if o ~= w and not o.held then
			local dx, dz = w.pos.X - o.pos.X, w.pos.Z - o.pos.Z
			local d = math.sqrt(dx * dx + dz * dz)
			local need = 2.4 * math.max(s, o.fig.scale)
			if d < need and math.abs(w.pos.Y - o.pos.Y) < 4 then
				if d < 0.01 then -- (exactly on one spot: a nudge sideways)
					dx, dz, d = 0.3, 0.1, 0.32
				end
				local k = math.min(1, dt * 6) * (need - d) / d
				w.pos += Vector3.new(dx * k, 0, dz * k)
			end
		end
	end
end

local function stepWalk(w: Walker, dt: number): boolean
	local s = w.fig.scale
	-- (27 Nov) bumped by a slow car: the stumble back, nothing else
	if w.bump then
		bumpStep(w, dt)
		return false
	end
	-- a knock-over under way (a keyed action, standing on the spot)
	if w.act then
		local act = w.act
		local A = PedMotion.ACTIONS[act.kind]
		local q = act.bin
		if act.kind ~= "slam" and q and q.Parent then
			steer(w, q.Position, dt)
		end
		w.yawRate = 0
		local before = act.t
		act.t += dt
		if before < A.contact and act.t >= A.contact and q and q.Parent then
			local d = Vector3.new(q.Position.X - w.pos.X, 0, q.Position.Z - w.pos.Z)
			knockBin(q, if d.Magnitude > 0.05 then d.Unit else heading(w.yaw), act.kind)
		end
		if act.t >= A.dur then
			w.act = nil
			w.knockDone = true
			if q then
				local d = q.Position - w.pos
				w.glance = { yaw = math.clamp(wrapA(math.atan2(-d.X, -d.Z) - w.yaw), -1.6, 1.6), t = 1.6 }
			end
		end
		return false
	end
	-- (27 Nov) a player's car: coming at them -> startled, then run out of its path; standing close -> a wary look
	w.fearT = math.max(0, (w.fearT or 0) - dt)
	w.carT = (w.carT or 0) - dt
	if not w.flee and #pcars > 0 and (w.carT :: number) <= 0 then
		w.carT = 0.15
		local kind, c, dir, lat, sp = carThreat(w)
		if kind == "flee" then
			startFlee(w, c, dir :: Vector3, lat, sp)
		elseif kind == "wary" and not w.glance and rng:NextNumber() < 0.25 then
			local toCar = c.pos - w.pos
			w.glance = { yaw = math.clamp(wrapA(math.atan2(-toCar.X, -toCar.Z) - w.yaw), -1.5, 1.5), t = rng:NextNumber(1, 2) }
		end
	end
	local fleeGoal: Vector3? = nil
	if w.flee then
		local fl = w.flee
		fl.t += dt
		if fl.t < fl.startle then
			-- the start: frozen for a beat, the head snapping round to the car
			w.yawRate, w.twist, w.lean = 0, 0, 0
			w.glance = { yaw = fl.lookYaw, t = 0.1 }
			return false
		end
		if w.gait ~= "run" then
			setGait(w, "run")
		end
		if flat(fl.p, w.pos) < 1.2 or fl.t > fl.startle + 3.5 then
			-- safe: calm down to a walk, a look back at the car, carry on (a crossing is finished, not dropped
			-- in the road)
			w.flee = nil
			if not w.hurry then
				setGait(w, "walk")
			end
			local toCar = fl.car.pos - w.pos
			w.glance = { yaw = math.clamp(wrapA(math.atan2(-toCar.X, -toCar.Z) - w.yaw), -1.6, 1.6), t = 1.4 }
			local onRoad = fl.prev == "cross" or (fl.prev == "wait" and w.cross and w.cross.sig and w.cross.sig.k > 1)
			if onRoad then
				w.mode = "cross"
				if w.cross and w.cross.sig then
					w.cross.sig.k = #w.cross.sig.stages
				end
			else
				w.mode = "walk"
				w.cross = nil
			end
			w.avoid = nil
		else
			fleeGoal = fl.p
		end
	end
	-- (27 Nov) at a signal crossing: waiting at the kerb or where the carriageways meet, facing across, until this
	-- stage's traffic has red with time to get over
	if not fleeGoal and w.mode == "wait" and w.cross and w.cross.sig then
		local sg = w.cross.sig
		local st = sg.stages[sg.k]
		local to = st.to - w.pos
		if Vector3.new(to.X, 0, to.Z).Magnitude > 0.3 then
			w.yaw += wrapA(math.atan2(-to.X, -to.Z) - w.yaw) * math.min(1, dt * 2.5)
		end
		w.yawRate, w.twist, w.lean = 0, 0, 0
		idleTick(w, dt)
		separate(w, dt)
		if gateOpen(w, sg, st) then
			idleEnd(w)
			w.mode = "cross"
		end
		return false
	end
	if not fleeGoal and (w.mode == "pause" or w.mode == "look") then
		if w.mode == "pause" then
			idleTick(w, dt)
		end
		w.timer -= dt
		if w.pauseYaw then
			w.yaw += wrapA(w.pauseYaw - w.yaw) * math.min(1, dt * 1.6)
		end
		if w.mode == "look" then -- before crossing: left, right, then go
			w.lookTo = if w.timer > 0.65 then -0.95 elseif w.timer > 0.2 then 0.95 else 0
		end
		if w.timer <= 0 then
			w.mode = if w.mode == "look" then "cross" else "walk"
			w.pauseYaw = nil
			idleEnd(w)
		end
		return false
	end
	-- (27 Nov) now and then a stop on the way: a look at a shop, the phone, the street (turned to, not snapped)
	if not fleeGoal and w.mode == "walk" and w.gait ~= "run" and rng:NextNumber() < dt / 45 then
		w.mode = "pause"
		w.timer = rng:NextNumber(2, 7)
		w.pauseYaw = w.yaw + rng:NextNumber(0.5, 1.6) * (if rng:NextNumber() < 0.5 then -1 else 1)
		return false
	end
	-- where to: the crossing's far side, a bin to knock, a way round something, or the next path point
	local goal: Vector3? = fleeGoal
	-- (27 Nov) to the zebra's near end along the kerb, then wait there for the lights
	if not goal and w.mode == "towait" and w.cross and w.cross.sig then
		goal = w.cross.sig.pre
		if flat(goal :: Vector3, w.pos) < 0.9 then
			w.mode = "wait"
			return false
		end
	end
	if not goal and w.mode == "cross" and w.cross then
		goal = w.cross.pt
		local sg = w.cross.sig
		if sg and sg.k <= #sg.stages then
			goal = sg.stages[sg.k].to
			if flat(goal :: Vector3, w.pos) < 1.0 then
				-- over this carriageway: on to the next only if its traffic is held too, else wait here; after the
				-- last, off the zebra to the far pavement's path
				sg.k += 1
				if sg.k <= #sg.stages then
					if not gateOpen(w, sg, sg.stages[sg.k]) then
						w.mode = "wait"
						return false
					end
					goal = sg.stages[sg.k].to
				else
					goal = w.cross.pt
				end
			end
		end
		if goal == w.cross.pt and flat(goal :: Vector3, w.pos) < 1.4 then
			local c = w.cross
			w.path = paths[c.pi]
			w.k = c.k
			local pts = w.path :: { Vector3 }
			local nxt = pts[c.k + 1] or pts[c.k - 1]
			local dv = if nxt then Vector3.new(nxt.X - pts[c.k].X, 0, nxt.Z - pts[c.k].Z) else heading(w.yaw)
			w.dir = if pts[c.k + 1] and dv:Dot(heading(w.yaw)) >= 0 then 1 elseif pts[c.k - 1] then -1 else 1
			w.latLo, w.latHi = if pathWide[c.pi] then -0.6 else -1.5, if pathWide[c.pi] then 3 else 1.5
			w.lat = math.clamp(w.lat, w.latLo :: number, w.latHi :: number)
			w.cross = nil
			w.mode = "walk"
			if w.gait == "run" and not w.hurry then
				w.runT = rng:NextNumber(0.8, 2.5) -- a few more strides, then back to a walk
			end
			goal = nil
		end
	end
	if w.runT then
		w.runT -= dt
		if w.runT <= 0 then
			w.runT = nil
			setGait(w, "walk")
		end
	end
	if not goal and w.knockAt then
		local q = w.knockAt.bin
		w.knockAt.t = (w.knockAt.t or 0) + dt
		if not q.Parent or fallen[q] or w.knockAt.t > 7 then -- (can't get there: give it up)
			w.knockAt = nil
		else
			goal = w.knockAt.spot
			if flat(goal, w.pos) < 0.45 then
				w.act = { kind = w.knockAt.kind, t = 0, bin = q }
				w.knockAt = nil
				return false
			end
		end
	end
	-- (a car standing on the crossing: round it)
	if not goal and w.mode == "cross" and not w.avoid and #pcars > 0 then
		w.scanT = (w.scanT or 0) - dt
		if (w.scanT :: number) <= 0 then
			w.scanT = 0.3
			carBlocked(w, 8)
		end
	end
	if not fleeGoal and w.avoid then
		local av = w.avoid
		local hd = heading(w.yaw)
		av.t = (av.t or 0) + dt
		if not av.q.Parent or (not av.car and (av.q.Position - w.pos):Dot(hd) < -0.6) or flat(av.p, w.pos) < 0.8 or av.t > 6 then
			w.avoid = nil
		else
			goal = av.p
		end
	end
	if not goal then
		-- the path: points reached (or passed close by) move on, drifting across the pavement
		for _ = 1, 4 do
			local t = target(w)
			if not t then
				-- the end of the pavement: cross to the next one ahead (looking both ways first), or turn back
				local pi, k, pt, sig = nil, nil, nil, nil
				-- (27 Nov) by a signalled junction: cross on the lights (most do)
				if type(w.forceSig) == "table" then -- (Studio staging: the crossing it was staged for)
					local c = w.forceSig
					pi, k, pt, sig = c.pi, c.k, c.pt, c.sig
					sig.k = 1
					w.forceSig = nil
				elseif rng:NextNumber() < 0.75 then
					pi, k, pt, sig = findSignalCross(w)
				end
				if not pi and (w.forceRun or rng:NextNumber() < 0.6) then
					pi, k, pt = findCross(w)
				end
				if pi and pt and sig then
					w.cross = { pi = pi, k = k :: number, pt = pt, sig = sig }
					if w.gait ~= "run" and (w.forceRun or rng:NextNumber() < CROSS_RUN) then
						w.forceRun = nil
						setGait(w, "run")
					end
					w.mode = if sig.pre and flat(sig.pre, w.pos) > 0.9 then "towait" else "wait"
					return false
				elseif pi and pt then
					w.cross = { pi = pi, k = k :: number, pt = pt }
					if w.gait ~= "run" and (w.forceRun or rng:NextNumber() < CROSS_RUN) then
						w.forceRun = nil
						setGait(w, "run")
						w.mode = "cross"
					elseif w.gait == "run" then
						w.mode = "cross"
					else
						w.mode = "look"
						w.timer = 1.1
					end
					return false
				end
				w.dir = -w.dir
				-- (a stub of a path: turned at both ends within a few seconds) someone new elsewhere instead
				local now = os.clock()
				if w.flipAt and now - w.flipAt < 4 then
					w.gone = true
					return false
				end
				w.flipAt = now
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
			local d = flat(t, w.pos)
			if d < 1.6 or (d < 3.5 and (t - w.pos):Dot(heading(w.yaw)) < 0) then
				w.k += w.dir
				if w.latLo then
					w.lat = math.clamp(w.lat + rng:NextNumber(-0.5, 0.5), w.latLo, w.latHi :: number)
				end
			else
				goal = t
				break
			end
		end
		if not goal then
			return false
		end
		-- something in the way 2-3 s ahead: curve round it early (or, for a knocker, walk up to the bin)
		w.scanT = (w.scanT or 0) - dt
		if (w.scanT :: number) <= 0 then
			w.scanT = 0.3
			-- (27 Nov) a player's car standing in the way first: round it or back the way they came
			if #pcars > 0 and not w.avoid and carBlocked(w, math.max(6, w.speed * LOOK_AHEAD)) then
				return false
			end
			local q, need, lat = obstacleAhead(w, math.max(6, w.speed * LOOK_AHEAD))
			if q then
				local hd = heading(w.yaw)
				local side = Vector3.new(-hd.Z, 0, hd.X)
				if w.knocker and not w.knockDone and binTag[q] and w.gait ~= "run" then
					local r = rng:NextNumber()
					local kind = w.forceKind or (if r < 0.4 then "kick" elseif r < 0.75 then "push" else "slam")
					local spot
					local ext = need - 0.95 * s - 0.35 -- the bin's half width this way
					if kind == "slam" then
						-- passing with the bin on the right: the right arm's outside 0.05 off it, the barge closes the gap
						spot = q.Position - side * (ext + 2.05 * s) - hd * 0.2
					else
						-- standing off so the kicking foot / the pushing hands just reach it at full stretch
						local back = q.Position - w.pos
						back = Vector3.new(back.X, 0, back.Z).Unit
						spot = q.Position - back * (ext + (if kind == "kick" then 1.9 else 2.35) * s)
					end
					w.knockAt = { bin = q, spot = Vector3.new(spot.X, w.pos.Y, spot.Z), kind = kind }
				else
					local sgn = if math.abs(lat) > 0.25 then -math.sign(lat) else 1
					if math.abs(lat) <= 0.25 then -- dead ahead: pass on the side away from the kerb
						local kerb = kerbSide(w)
						if kerb then
							sgn = if side:Dot(kerb) > 0 then -1 else 1
						end
					end
					local p = q.Position + side * sgn * (need + 0.5)
					w.avoid = { q = q, p = Vector3.new(p.X, w.pos.Y, p.Z) }
				end
			end
		end
	end
	local g = goal :: Vector3
	local dy = steer(w, g, dt)
	-- slower into a sharp turn; feet keep to the stride (cadence from the speed)
	local v = w.speed * (1 - 0.3 * math.min(1, math.abs(dy) / 1.4))
	if w.mode == "cross" and w.cross and w.cross.sig and w.gait ~= "run" then
		v *= SIG_PACE
	end
	local hd = heading(w.yaw)
	local step = v * dt
	local d = flat(g, w.pos)
	w.pos += hd * step
	if d > 0.01 then
		w.pos = Vector3.new(w.pos.X, w.pos.Y + (g.Y - w.pos.Y) * math.min(1, step / d), w.pos.Z)
	end
	-- (27 Nov) never inside another person: ease apart from anyone nearer than 2.4 studs (20 people: cheap)
	separate(w, dt)
	-- (a corner of a shelter on the line) never inside one
	if w.mode ~= "cross" then
		local kerb = kerbSide(w)
		if kerb then
			w.pos = clearOf(w.pos, kerb)
		end
	end
	if w.fig.model:GetAttribute("Staged") then -- (Studio staging: what the walker is doing)
		w.fig.model:SetAttribute("Dbg", string.format("%s goal %s avoid %s knock %s", w.mode, tostring(g),
			tostring(w.avoid and w.avoid.q:GetFullName()), tostring(w.knockAt and w.knockAt.kind)))
	end
	local cad = if w.gait == "run" then PedMotion.runCadence(v, s) else PedMotion.walkCadence(v, s)
	w.phase += cad / 2 * dt
	w.speedNow = v
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
	local who = whoAt(p.X, p.Z)
	local speed = rng:NextNumber(WALK_SPEED[1], WALK_SPEED[2])
	if who == "monk" then
		speed = math.min(speed, 3)
	end
	-- (27 Nov) a few in a hurry (a late commuter: running), some on the phone (at the ear / looking at it)
	local r = rng:NextNumber()
	local hurry = who ~= "monk" and r < 0.03
	local phone = if who == "monk" or hurry then nil elseif r < 0.09 then "ear" elseif r < 0.17 then "hand" else nil
	if phone == "hand" then
		speed *= 0.82
	end
	local dir = if rng:NextNumber() < 0.5 then 1 else -1
	-- across the pavement (lat > 0 away from the kerb): the whole width, not one line (narrow paths are the middle
	-- of a pavement, wide ones its kerb side)
	local lo, hi = if pathWide[pi] then -0.6 else -1.5, if pathWide[pi] then 3 else 1.5
	local function walker(f: Figure, lat: number, sp: number, phase: number): Walker
		local w: Walker = {
			fig = f, mode = "walk", path = pts, k = if dir > 0 then k else k + 1, dir = dir, pos = p, yaw = 0,
			speed = sp, lat = lat, phase = phase, acc = 0, timer = 0, spot = nil, latLo = lo, latHi = hi,
			gait = "walk", walkSpeed = sp, knocker = who ~= "monk" and rng:NextNumber() < KNOCK_SHARE,
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
	local w1 = walker(takeFigure(who), lat, speed, phase)
	w1.phone = phone
	if hurry then
		w1.hurry = true
		setGait(w1, "run")
		return true
	end
	-- a third walk in twos, side by side at one pace (friends, a couple, a parent and child)
	if who ~= "monk" and rng:NextNumber() < 0.3 and #active < pedWant then
		-- (27 Nov) shoulder to shoulder, 3 studs apart (1.3 put two Blocky bodies inside each other); the pair keep
		-- their lines (no drift each), so they never cross into each other
		local side = if lat + 3 <= hi + 1 then 3 else -3
		local who2 = if who == "kid" or rng:NextNumber() < 0.15 then "kid" elseif rng:NextNumber() < 0.5 then "man" else "woman"
		local w2 = walker(takeFigure(who2), lat + side, speed, phase + 0.45)
		w1.latLo, w1.latHi, w2.latLo, w2.latHi = nil, nil, nil, nil
		w1.phone, w1.knocker, w2.knocker = nil, false, false
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

-- (27 Nov, owner: "the npc,traffic needs shadows ... npc needs shadows") people cast shadows: the body pieces (torso,
-- head, arms, legs, hair; not the hands and feet: tiny), only within SHADOW_R of the camera and not on Low graphics /
-- low-end mode (pedShadowOk, from the start's quality check)
local SHADOW_R = 120
local blockScanT = 0
local pedShadowOk = true
local function shadowWant(f: Figure, on: boolean)
	if f.shadow == on then
		return
	end
	f.shadow = on
	for k, p in f.parts do
		local ex = f.extraOf[k]
		local tiny = ex and (ex.k == 4 or ex.k == 5 or ex.k == 6 or ex.k == 7) and ex.i == 3
		p.CastShadow = on and not tiny
	end
end

local function pedTick(cam: Vector3, cap: number)
	local cfg = Config.YangonStreetLife
	local want = cap
	if cam.Y > 1200 then
		want = 0
	elseif cam.Y > 300 then
		want = math.floor(cap / 3)
	end
	-- (2026-11-28) at the car meet a crowd stands round the drift pad: more people there, mostly standing
	local share = cfg.SpotShare
	for _, q in meetAt do
		if flat(q, cam) < 260 and cam.Y < 300 then
			want, share = cap + 14, 0.85
			break
		end
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
		if rng:NextNumber() < share then
			spawnStander(cam, cfg.PedMinGap, cfg.PedRadius)
		else
			spawnWalker(cam, cfg.PedMinGap, cfg.PedRadius)
		end
	end
	for _, w in active do
		shadowWant(w.fig, pedShadowOk and flat(w.pos, cam) < SHADOW_R)
	end
	-- (27 Nov) street kit tiles are built and tagged before they're parented into the Workspace, so the tag signal
	-- finds them outside it: pick up any PedBlock part now in the Workspace every few seconds
	blockScanT -= cfg.PedCheck
	if blockScanT <= 0 then
		blockScanT = 4
		for _, q in CollectionService:GetTagged("PedBlock") do
			if not blockKeys[q] then
				blockAdd(q)
			end
		end
		for q in blockKeys do -- (a tile taken down: its pieces leave the grid)
			if not q:IsDescendantOf(workspace) then
				blockRemove(q)
			end
		end
	end
	-- Studio test hook: player attribute TestPedStage = "bin" | "kick" | "push" | "slam" | "cross" puts the walker
	-- nearest the camera on the pavement path 14 studs before the nearest bin (a knocker for kick / push / slam), or
	-- 6 studs before its path's end as a runner who will cross; its model gets attribute Staged
	local lp = game:GetService("Players").LocalPlayer
	local stage = RunService:IsStudio() and lp and lp:GetAttribute("TestPedStage")
	if type(stage) == "string" then
		lp:SetAttribute("TestPedStage", nil)
		local best, bd = nil, math.huge
		for _, w in active do
			if w.path and not w.held and flat(w.pos, cam) < bd then
				best, bd = w, flat(w.pos, cam)
			end
		end
		if best then
			for _, w in active do
				w.fig.model:SetAttribute("Staged", nil)
			end
			local w = best
			w.act, w.knockAt, w.avoid, w.cross, w.mode = nil, nil, nil, nil, "walk"
			if stage == "run" then -- a hurrying runner on the pavement
				w.hurry = true
				setGait(w, "run")
			elseif stage == "sigcross" then
				-- (27 Nov) a pavement end near the camera with a signal crossing ahead (two stages first); the walker
				-- starts 3 points before it; attribute StageSig = how many stages
				local cx, cz = math.floor(cam.X / CELL), math.floor(cam.Z / CELL)
				local best2, best1 = nil, nil
				local seenP = {}
				for gx = cx - 3, cx + 3 do
					for gz = cz - 3, cz + 3 do
						local list = pathCells[cellKey(gx, gz)]
						for e = 1, (if list then #list // 2 else 0) do
							local pi = list[2 * e - 1]
							local pts = paths[pi]
							local n = #pts
							if not seenP[pi] and n > 5 and not best2 then
								seenP[pi] = true
								for _, en in { { n, n - 1, 1 }, { 1, 2, -1 } } do
									local pe, pn = pts[en[1]], pts[en[2]]
									local d = pe - pn
									local probe = { pos = pe, yaw = math.atan2(-d.X, -d.Z), path = pts } :: any
									local cpi, ck, cq, plan = findSignalCross(probe)
									if plan then
										local rec = { pts = pts, n = n, dir = en[3], stages = #plan.stages, cross = { pi = cpi, k = ck, pt = cq, sig = plan } }
										if #plan.stages == 2 then
											best2 = best2 or rec
										else
											best1 = best1 or rec
										end
									end
								end
							end
						end
					end
				end
				local rec = best2 or best1
				if rec then
					local pts, n = rec.pts, rec.n
					-- 10 studs before the end, on the last stretch, heading for the end
					local e, e2 = if rec.dir > 0 then n else 1, if rec.dir > 0 then n - 1 else 2
					local back = pts[e2] - pts[e]
					w.path, w.dir, w.k = pts, rec.dir, e2
					w.pos = pts[e] + back.Unit * math.min(10, back.Magnitude * 0.9)
					local nx = pts[e] - w.pos
					w.yaw = math.atan2(-nx.X, -nx.Z)
					w.latLo, w.latHi = nil, nil
					w.lat = 0
					w.forceSig = rec.cross
				end
				w.fig.model:SetAttribute("StageSig", if rec then rec.stages else 0)
			elseif stage == "cross" then
				-- a pavement end near the camera with a crossing ahead; the walker starts 8 points before it
				local cx, cz = math.floor(cam.X / CELL), math.floor(cam.Z / CELL)
				local found = false
				for gx = cx - 1, cx + 1 do
					for gz = cz - 1, cz + 1 do
						local list = pathCells[cellKey(gx, gz)]
						for e = 1, (if list then #list // 2 else 0) do
							local pts = paths[list[2 * e - 1]]
							local n = #pts
							if not found and n > 12 then
								local d = pts[n] - pts[n - 1]
								local probe = { pos = pts[n], yaw = math.atan2(-d.X, -d.Z), path = pts } :: any
								if findCross(probe) then
									w.path, w.dir, w.k = pts, 1, n - 2
									w.pos = pts[n - 3]
									local d2 = pts[n - 2] - pts[n - 3]
									w.yaw = math.atan2(-d2.X, -d2.Z)
									w.latLo, w.latHi = nil, nil
									found = true
								end
							end
						end
					end
				end
				w.forceRun = true
				w.fig.model:SetAttribute("StageCross", found)
			else
				-- the bin nearest the camera that a long pavement path runs past (its point nearest the bin 25+
				-- studs from both ends of the path: walkers turn at path ends)
				local bin, bpi, bk, best = nil, nil, nil, math.huge
				for q in binTag do
					if q:IsDescendantOf(workspace) and not fallen[q] and flat(q.Position, cam) < 300 then
						local pi0, k0, d0 = nil, nil, math.huge
						local cx, cz = math.floor(q.Position.X / CELL), math.floor(q.Position.Z / CELL)
						for gx = cx - 1, cx + 1 do
							for gz = cz - 1, cz + 1 do
								local list = pathCells[cellKey(gx, gz)]
								if list then
									for e = 1, #list // 2 do
										local pi, k = list[2 * e - 1], list[2 * e]
										local pts = paths[pi]
										local d = flat(pts[k], q.Position)
										if d < d0 and flat(pts[k], pts[1]) > 25 and flat(pts[k], pts[#pts]) > 25 then
											pi0, k0, d0 = pi, k, d
										end
									end
								end
							end
						end
						if pi0 and d0 < 6 and flat(q.Position, cam) < best then
							bin, bpi, bk, best = q, pi0, k0, flat(q.Position, cam)
						end
					end
				end
				if bin then
					w.fig.model:SetAttribute("StageBin", bin.Position)
					if bpi then
						local pts = paths[bpi]
						-- walk toward the bin from about 14 studs before it along the path
						local k0 = bk
						local dir = if pts[bk - 1] then 1 else -1
						while pts[k0 - dir] and flat(pts[k0 - dir], bin.Position) < 14 do
							k0 -= dir
						end
						k0 = if pts[k0 - dir] then k0 - dir else k0
						w.path, w.dir, w.k = pts, dir, k0 + dir
						w.pos = pts[k0]
						local nx = pts[k0 + dir] or bin.Position
						-- on the line that runs into the bin
						local dd = Vector3.new(nx.X - pts[k0].X, 0, nx.Z - pts[k0].Z)
						dd = if dd.Magnitude > 0.01 then dd.Unit else Vector3.xAxis
						local away = Vector3.new(-dd.Z, 0, dd.X) * dir
						local lat = (bin.Position - pts[k0]):Dot(away)
						w.lat = lat
						w.latLo = math.min(if pathWide[bpi] then -0.6 else -1.5, lat)
						w.latHi = math.max(if pathWide[bpi] then 3 else 1.5, lat)
						local dv = nx - w.pos
						w.yaw = math.atan2(-dv.X, -dv.Z)
						w.knocker = stage ~= "bin"
						w.knockDone = false
						w.forceKind = if stage ~= "bin" then stage else nil
						setGait(w, "walk")
					end
				end
			end
			w.fig.model:SetAttribute("Staged", true)
		end
	end
end

local function pedFrame(dt: number, cam: Vector3, look: Vector3)
	binsTick(dt, cam, look)
	refreshPCars(dt)
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
			if w.bump then -- (being pushed: every frame, so the car never goes into them)
				every = 0
			end
			if w.acc >= every then
				local a = w.acc
				w.acc = 0
				w.t = (w.t or 0) + a
				if w.bump then
					bumpStep(w, a)
				else
					if w.yawTo then
						w.yaw += (w.yawTo - w.yaw) * math.min(1, a * 2)
					end
					lookStep(w, a)
					idleTick(w, a)
					if w.act then -- (a shaken fist after a bump)
						w.act.t += a
						if w.act.t >= PedMotion.ACTIONS[w.act.kind].dur then
							w.act = nil
						end
					end
				end
				pose(w, false)
			elseif every == math.huge then
				w.acc = 0
			end
		else
			local d = flat(w.pos, cam)
			-- (27 Nov, owner: "the npcs from far away are laggy": 4 moves a second past 140 studs read as stutter; with
			-- PedMax 20 a pose every frame near and 30 a second far is cheap)
			local every = if d < 90 then 0 else 1 / 30
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
					if w.mode == "pause" or w.mode == "wait" then
						lookStep(w, a)
					else
						easeLook(w, a)
					end
				end
				pose(w, moving)
			end
		end
	end
	-- (27 Nov) people on the road (crossing, or waiting where the carriageways meet) are obstacles for Traffic
	local peds = Traffic.peds
	table.clear(peds)
	for _, w in active do
		local sg = w.cross and w.cross.sig
		-- (where in a signal crossing, on the model: for Studio checks; set only when it changes)
		local str = if sg then string.format("%s %d/%d", w.mode, sg.k, #sg.stages) else nil
		if (str or "") ~= w.sigStr then
			w.sigStr = str or ""
			w.fig.model:SetAttribute("Sig", str)
		end
		if not w.held and not w.gone and (w.mode == "cross" or w.mode == "flee" or (w.mode == "wait" and sg and sg.k > 1)) then
			local o = w.obs
			if not o then
				o = { pos = w.pos, fwd = heading(w.yaw), speed = 0, halfLen = 1, width = 2.4, ped = true }
				w.obs = o
			end
			o.pos, o.fwd = w.pos, heading(w.yaw)
			table.insert(peds, o)
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
		-- (27 Nov) bins (tag PedBin, also PedBlock: the kit template SPL_bin) can be knocked over
		CollectionService:GetInstanceAddedSignal("PedBin"):Connect(function(q)
			binTag[q] = true
		end)
		CollectionService:GetInstanceRemovedSignal("PedBin"):Connect(function(q)
			binTag[q] = nil
		end)
		for _, q in CollectionService:GetTagged("PedBin") do
			binTag[q] = true
		end
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
			pedShadowOk = q > cfg.LowScale and workspace:GetAttribute("TestPedShadows") ~= false
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
