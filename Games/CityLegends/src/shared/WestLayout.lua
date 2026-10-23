--[[
	WestLayout
	Where everything in the west is (owner, 2026-10-22: a coastal highway over a river on a
	suspension bridge to a Miami / New York style Downtown, the beach, private islands offshore, a
	hotel, a casino and a gem showcase Downtown, and houses to buy). Pure maths from Config.West,
	shared by server and client.

	Going west (-X) from the city along z = 0:
	  the city's west edge -> the viaduct over the harbour, the suburbs and the Legends Loop -> the
	  countryside -> a canyon through the mountains -> the river (the suspension bridge) ->
	  Downtown (its own 6 x 6 street grid, road indices i = 100 .. 106) -> Ocean Drive and the beach
	  -> the causeway over the sea -> Legends Key, with Palm Isle and Coral Cay off it by bridges

	Frames: a site's or plot's frame stands at ground level in the middle of its lot, and its
	LookVector (-Z) points out of the entrance, towards the road it faces (like Towers and Bank).
]]

local Config = require(script.Parent.Config)
local CityLayout = require(script.Parent.CityLayout)

local C = Config.City
local W = Config.West

local WestLayout = {}

local N = C.Blocks
local BASE = W.IndexBase
local INNER = C.BlockSize - C.RoadWidth -- a block's sidewalk slab
local LOT = INNER - C.SidewalkWidth * 2 -- what's left inside the sidewalks

WestLayout.Lot = LOT
WestLayout.BlockInner = INNER

-- Downtown's outer road edges
WestLayout.DowntownEast = CityLayout.roadCoord(BASE + N) + C.RoadWidth / 2
WestLayout.DowntownWest = CityLayout.roadCoord(BASE) - C.RoadWidth / 2 -- Ocean Drive's beach side
WestLayout.DowntownHalfZ = C.HalfExtent + C.RoadWidth / 2

local SIDE_DIR = {
	N = Vector3.new(0, 0, -1),
	S = Vector3.new(0, 0, 1),
	E = Vector3.new(1, 0, 0),
	W = Vector3.new(-1, 0, 0),
}

function WestLayout.blockCenter(bi: number, bj: number): Vector3
	return Vector3.new((CityLayout.roadCoord(bi) + CityLayout.roadCoord(bi + 1)) / 2, C.CurbHeight, (CityLayout.roadCoord(bj) + CityLayout.roadCoord(bj + 1)) / 2)
end

-- a Downtown site ("hotel", "casino", "gems"): its frame (ground level, facing out of the
-- entrance) and its lot size (square, inside the sidewalks)
function WestLayout.site(name: string): (CFrame, number)
	local s = W.Sites[name]
	local c = WestLayout.blockCenter(s[1], s[2])
	return CFrame.lookAt(c, c + SIDE_DIR[s[3]]), LOT
end

-- the dealership's frame (ground level at its lot's middle, facing out of the showroom) and lot
function WestLayout.dealership(): (CFrame, number)
	local d = Config.Dealership
	local c = WestLayout.blockCenter(d.Block[1], d.Block[2])
	return CFrame.lookAt(c, c + SIDE_DIR[d.Face]), LOT
end

-- where a car pulls up outside a site: on the road's right-hand kerb lane, in front of the
-- entrance, heading so the entrance is on the right
function WestLayout.kerbFor(frame: CFrame, depth: number): CFrame
	local out = frame.LookVector
	local p = frame.Position + out * (depth / 2 + C.SidewalkWidth + C.LaneWidth * 1.5)
	p = Vector3.new(p.X, 0, p.Z)
	-- travelling with the entrance on the right: right = travel x up, so travel = up x right
	local travel = Vector3.yAxis:Cross(-out)
	return CFrame.lookAt(p, p + travel)
end

---------------------------------------------------------------------
-- Is a point in the way of the west road? (trees, houses, mountains and walls keep clear)
---------------------------------------------------------------------
function WestLayout.inCorridor(p: Vector3, margin: number?): boolean
	return p.X < -C.HalfExtent and math.abs(p.Z) < W.CorridorHalf + (margin or 0)
end

-- inside the west region (past the mainland's edge)
function WestLayout.inWest(p: Vector3): boolean
	return p.X < W.Canyon[1] and math.abs(p.Z) < W.HalfZ
end

-- the coastal highway's deck height at x (0 on the ground)
WestLayout.roadY = CityLayout.westRoadY

---------------------------------------------------------------------
-- Islands: ring roads, the causeway and the bridges between them, and house plots
---------------------------------------------------------------------
WestLayout.Islands = W.Islands
WestLayout.IslandById = {} :: { [string]: any }
for _, isl in W.Islands do
	WestLayout.IslandById[isl.id] = isl
end

function WestLayout.islandCenter(isl: any): Vector3
	return Vector3.new(isl.x, 0, isl.z)
end

-- the causeway: from Ocean Drive straight out along z = 0 to Legends Key's ring road
local KEY = W.Islands[1]
WestLayout.CausewayStart = WestLayout.DowntownWest
WestLayout.CausewayEnd = KEY.x + KEY.ring + W.IslandRoad / 2

-- the bridges from Legends Key's ring road to the other two (north and south)
WestLayout.IslandBridges = {} :: { { from: Vector3, to: Vector3, island: string } }
for k = 2, #W.Islands do
	local isl = W.Islands[k]
	local sgn = if isl.z < KEY.z then -1 else 1
	table.insert(WestLayout.IslandBridges, {
		from = Vector3.new(KEY.x, 0, KEY.z + sgn * (KEY.ring + W.IslandRoad / 2)),
		to = Vector3.new(isl.x, 0, isl.z - sgn * (isl.ring + W.IslandRoad / 2)),
		island = isl.id,
	})
end

-- angles (round the island, 0 = +X, towards +Z) where a road joins the ring: no plot there
local function joins(isl: any): { number }
	if isl.id == KEY.id then
		return { 0, math.pi / 2, -math.pi / 2 }
	end
	return { if isl.z < KEY.z then math.pi / 2 else -math.pi / 2 }
end

local function angleGap(a: number, b: number): number
	local d = (a - b) % (2 * math.pi)
	return math.min(d, 2 * math.pi - d)
end

export type Plot = {
	id: string,
	island: string,
	frame: CFrame, -- ground level, middle of the lot, LookVector towards the ring road
	width: number, -- along the road
	depth: number, -- away from the road
	tier: number, -- 1 = Palm Isle / Coral Cay villas, 2 = Legends Key mansions
}

-- house plots: between each island's ring road and its shore, facing the road
function WestLayout.housePlots(): { Plot }
	local plots: { Plot } = {}
	for _, isl in W.Islands do
		local c = WestLayout.islandCenter(isl)
		local inner = isl.ring + W.IslandRoad / 2 + 8 -- the lot's road side
		local outer = isl.r - 22 -- keep a beach strip
		local depth = outer - inner
		local rMid = (inner + outer) / 2
		local isKey = isl.id == KEY.id
		local count = if isKey then 10 else 7
		local width = if isKey then 110 else 96
		local n = 0
		for k = 0, count - 1 do
			local a = (k + 0.5) / count * 2 * math.pi
			local clear = true
			for _, j in joins(isl) do
				if angleGap(a, j) < 0.32 then
					clear = false
				end
			end
			if clear then
				n += 1
				local radial = Vector3.new(math.cos(a), 0, math.sin(a))
				local p = c + radial * rMid
				table.insert(plots, {
					id = `{isl.id}_{n}`,
					island = isl.id,
					frame = CFrame.lookAt(p, p - radial),
					width = width,
					depth = depth,
					tier = if isKey then 2 else 1,
				})
			end
		end
	end
	return plots
end

---------------------------------------------------------------------
-- Named places (chauffeur destinations, map labels): where a car stops, on the road
---------------------------------------------------------------------
export type Place = { id: string, name: string, cf: CFrame }

local function onLane(x: number, z: number, dir: Vector3): CFrame
	local right = dir:Cross(Vector3.yAxis)
	local p = Vector3.new(x, 0, z) + right * (C.LaneWidth * (C.LanesPerSide - 0.5))
	return CFrame.lookAt(p, p + dir)
end

function WestLayout.places(): { Place }
	local list: { Place } = {}
	local function add(id: string, name: string, cf: CFrame)
		table.insert(list, { id = id, name = name, cf = cf })
	end
	-- the city
	local mid = CityLayout.roadCoord(N / 2)
	add("city", "City Centre", onLane(mid + C.BlockSize / 2, mid, Vector3.new(1, 0, 0)))
	local bank = Config.Bank.Block
	local bx = (CityLayout.roadCoord(bank[1]) + CityLayout.roadCoord(bank[1] + 1)) / 2
	add("bank", "Legends Reserve Bank", onLane(bx, CityLayout.roadCoord(bank[2]), Vector3.new(1, 0, 0)))
	for _, t in Config.Towers.List do
		local tx = (CityLayout.roadCoord(t.block[1]) + CityLayout.roadCoord(t.block[1] + 1)) / 2
		add("tower_" .. t.id, t.name, onLane(tx, CityLayout.roadCoord(t.block[2]), Vector3.new(1, 0, 0)))
	end
	-- the dealership
	local dealerFrame, dealerLot = WestLayout.dealership()
	add("dealership", "Legends Motors", WestLayout.kerbFor(dealerFrame, dealerLot))
	-- Downtown
	for _, name in { "hotel", "casino", "gems" } do
		local frame, lot = WestLayout.site(name)
		local label = if name == "hotel" then "Legends Grand Hotel" elseif name == "casino" then "High-Rollers Casino" else "Gem Showcase"
		add(name, label, WestLayout.kerbFor(frame, lot))
	end
	add("downtown", "Downtown", onLane(W.DowntownX + C.BlockSize / 2, 0, Vector3.new(-1, 0, 0)))
	add("beach", "Ocean Drive Beach", onLane(CityLayout.roadCoord(BASE), C.BlockSize * 1.5, Vector3.new(0, 0, -1)))
	-- the islands (at the ring road where you arrive)
	add("island_key", "Legends Key", onLane(WestLayout.CausewayEnd + 40, 0, Vector3.new(-1, 0, 0)))
	for _, b in WestLayout.IslandBridges do
		local isl = WestLayout.IslandById[b.island]
		local dir = (b.to - b.from).Unit
		add("island_" .. isl.id, (string.gsub(isl.name, "(%a)(%w*)", function(a, r)
			return a .. string.lower(r)
		end)), onLane(b.to.X, b.to.Z - dir.Z * 40, dir))
	end
	return list
end

return WestLayout
