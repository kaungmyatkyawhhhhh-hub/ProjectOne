--[[
	WestLayout
	Where everything in the west is (owner, 2026-10-22: a coastal highway over a river on a
	suspension bridge to a Miami / New York style Downtown, the beach, private islands offshore, a
	hotel, Legends Rewards (was a casino) and a gem showcase Downtown, and houses to buy). Pure maths from Config.West,
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
local IsleLayout = require(script.Parent.IsleLayout)

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

-- a venue's site in Monaco (Config.RivieraVenues), when the Riviera is in the place
-- the site table rivieraSite uses for a venue (Yangon's while Yangon is in the place and lists it)
function WestLayout.siteData(name: string): { [string]: any }?
	local yv = Config.YangonVenues
	local s = yv and yv.On and yv.Sites[name]
	if s and workspace and workspace:FindFirstChild("Yangon") then
		return s
	end
	local rv = Config.RivieraVenues
	return rv and rv.On and rv.Sites[name] or nil
end

-- (Yangon first: a venue with a Yangon site stands there while Yangon is in the place)
function WestLayout.rivieraSite(name: string): CFrame?
	local yv = Config.YangonVenues
	local s = yv and yv.On and yv.Sites[name]
	if not s or not (workspace and workspace:FindFirstChild("Yangon")) then
		local rv = Config.RivieraVenues
		s = rv and rv.On and rv.Sites[name]
		if not s or not (workspace and workspace:FindFirstChild("Riviera")) then -- (Lune has no workspace)
			return nil
		end
	end
	local c = Vector3.new(s.x, s.y, s.z)
	return CFrame.lookAt(c, c + Vector3.new(s.fx, 0, s.fz).Unit)
end

-- a Downtown site ("hotel", "rewards", "gems"): its frame (ground level, facing out of the
-- entrance) and its lot size (square, inside the sidewalks)
function WestLayout.site(name: string): (CFrame, number)
	local riv = WestLayout.rivieraSite(name)
	if riv then
		return riv, LOT
	end
	local s = W.Sites[name]
	local c = WestLayout.blockCenter(s[1], s[2])
	return CFrame.lookAt(c, c + SIDE_DIR[s[3]]), LOT
end

-- the dealership's frame (ground level at its lot's middle, facing out of the showroom) and lot
-- Legends Customs: its frame (ground level, facing out of the bay doors) and lot
function WestLayout.customs(): (CFrame, number)
	local riv = WestLayout.rivieraSite("customs")
	if riv then
		return riv, LOT
	end
	local d = Config.Customs
	local c = WestLayout.blockCenter(d.Block[1], d.Block[2])
	return CFrame.lookAt(c, c + SIDE_DIR[d.Face]), LOT
end

function WestLayout.dealership(): (CFrame, number)
	local riv = WestLayout.rivieraSite("dealership")
	if riv then
		return riv, LOT
	end
	local d = Config.Dealership
	local c = WestLayout.blockCenter(d.Block[1], d.Block[2])
	return CFrame.lookAt(c, c + SIDE_DIR[d.Face]), LOT
end

-- where a car pulls up outside a site: on the road's right-hand kerb lane, in front of the
-- entrance, heading so the entrance is on the right
function WestLayout.kerbFor(frame: CFrame, depth: number): CFrame
	local out = frame.LookVector
	local p = frame.Position + out * (depth / 2 + C.SidewalkWidth + C.LaneWidth * 1.5)
	-- (on the road: the site's floor is the pavement, a kerb above it; 0 in the old city)
	p = Vector3.new(p.X, frame.Position.Y - C.CurbHeight, p.Z)
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
-- Legends Isle (IsleLayout): the causeway's end and the house plots
---------------------------------------------------------------------
WestLayout.CausewayStart = WestLayout.DowntownWest
WestLayout.CausewayEnd = IsleLayout.CausewayEnd

export type Plot = {
	id: string,
	island: string,
	zone: string, -- "low" | "mid" | "high" (IsleLayout's neighbourhoods)
	frame: CFrame, -- ground level, middle of the lot, LookVector towards the road
	width: number, -- along the road
	depth: number, -- away from the road
	tier: number, -- the house type's tier (Config.Houses.Types): 1 mid (villas), 2 high (mansions), 0 low (no type yet)
}

local TIER = { low = 0, mid = 1, high = 2 }

-- house plots: the island's lots in each neighbourhood, facing their road
function WestLayout.housePlots(): { Plot }
	local plots: { Plot } = {}
	for _, l in IsleLayout.lots() do
		table.insert(plots, { id = l.id, island = "isle", zone = l.zone, frame = l.frame, width = l.width, depth = l.depth, tier = TIER[l.zone] })
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
	local bankRiv = WestLayout.rivieraSite("bank")
	add("bank", "Legends Reserve Bank", if bankRiv then WestLayout.kerbFor(bankRiv, LOT) else onLane(bx, CityLayout.roadCoord(bank[2]), Vector3.new(1, 0, 0)))
	for _, t in Config.Towers.List do
		local tx = (CityLayout.roadCoord(t.block[1]) + CityLayout.roadCoord(t.block[1] + 1)) / 2
		local riv = WestLayout.rivieraSite("tower_" .. t.id)
		add("tower_" .. t.id, t.name, if riv then WestLayout.kerbFor(riv, LOT) else onLane(tx, CityLayout.roadCoord(t.block[2]), Vector3.new(1, 0, 0)))
	end
	-- the dealership
	local dealerFrame, dealerLot = WestLayout.dealership()
	add("dealership", "Legends Motors", WestLayout.kerbFor(dealerFrame, dealerLot))
	local customsFrame, customsLot = WestLayout.customs()
	add("customs", "Legends Customs", WestLayout.kerbFor(customsFrame, customsLot))
	-- Downtown
	for _, name in { "hotel", "rewards", "gems" } do
		local frame, lot = WestLayout.site(name)
		local label = if name == "hotel" then "Legends Grand Hotel" elseif name == "rewards" then "Legends Rewards" else "Gem Showcase"
		add(name, label, WestLayout.kerbFor(frame, lot))
	end
	add("downtown", "Downtown", onLane(W.DowntownX + C.BlockSize / 2, 0, Vector3.new(-1, 0, 0)))
	add("beach", "Ocean Drive Beach", onLane(CityLayout.roadCoord(BASE), C.BlockSize * 1.5, Vector3.new(0, 0, -1)))
	-- Legends Isle: the ring road by the causeway, the mid terrace and the summit
	for _, pl in IsleLayout.places() do
		add(pl.id, pl.name, pl.cf)
	end
	-- Monaco only: the venues there, and a few of its own places (on the road, heading on)
	if Config.monacoOnly() then
		local keep = {}
		for _, pl in list do
			if WestLayout.rivieraSite(pl.id) then
				table.insert(keep, pl)
			end
		end
		local function onRoad(id: string, name: string, p: Vector3, dir: Vector3)
			table.insert(keep, { id = id, name = name, cf = CFrame.lookAt(p, p + dir) })
		end
		onRoad("old_rock", "Old Rock Palace", Vector3.new(13028.75, 44.48, 1471.33), Vector3.new(-0.99, 0, -0.11))
		onRoad("stadium", "Riviera Bay Stadium", Vector3.new(11822.03, 11.11, 1060.31), Vector3.new(0.02, 0, -1))
		onRoad("harbour", "The Harbour", Vector3.new(13696.26, 6, 536.58), Vector3.new(1, 0, -0.03))
		onRoad("mountain", "Mountain Road Lookout", Vector3.new(13598.51, 121.33, -754.69), Vector3.new(1, 0, 0))
		-- Yangon (build step 9): its landmarks, on the outer lane beside them (YangonLanes)
		if workspace:FindFirstChild("Yangon") then
			onRoad("ygn_optima", "Optima Werkz", Vector3.new(30866.98, 46.15, 764.83), Vector3.new(0.519, 0, -0.855))
			onRoad("ygn_novotel", "Novotel", Vector3.new(28637.73, 40.34, -137.68), Vector3.new(0.253, 0, 0.967))
			onRoad("ygn_mmplaza", "Myanmar Plaza", Vector3.new(32471.71, 28.96, -1305.15), Vector3.new(0.134, 0, -0.991))
			onRoad("ygn_roundabout", "Hanthawaddy Roundabout", Vector3.new(28976.76, 47.42, 1184.83), Vector3.new(0.125, 0, 0.992))
			onRoad("ygn_newroad", "New Road", Vector3.new(32450.83, 59.4, 894.39), Vector3.new(0.996, 0, 0.088))
			onRoad("ygn_university", "University Avenue", Vector3.new(29652.39, 52.59, -1013.03), Vector3.new(0.996, 0, 0.091))
		end
		return keep
	end
	return list
end

return WestLayout
