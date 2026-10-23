--[[
	West
	The west of the map (owner, 2026-10-22: "a Miami / New York style downtown packed with
	skyscrapers, neon lights, palm trees and heavy traffic", "a multi-lane coastal highway across a
	major river via an iconic elevated suspension bridge", "private offshore islands"). Where
	everything goes is in Config.West / WestLayout; this builds it:
	  * the coastal highway: up off the city's west edge onto a viaduct over the harbour, the
	    suburbs and the Legends Loop, down through the countryside and a canyon in the mountains
	  * the river and the Legends Bridge: two lit towers, necklace-lit main cables and suspenders
	  * Downtown: its own street grid (CityBuilder builds the roads, lights and blocks with the
	    hooks below), glass skyscrapers, palms on every sidewalk, a skyline ring north and south,
	    a riverside park facing the bridge
	  * Ocean Drive: pastel art deco hotels with neon along the beachfront, the promenade, the beach
	    and the sea
	  * the causeway to Legends Key, and the bridges on to Palm Isle and Coral Cay: island ring
	    roads, beaches, palms, parks (the houses on the plots are built by Houses)
	The hotel, casino and gem showcase sites are left as bare blocks here; their own modules build
	them.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))

local West = {}

local C = Config.City
local W = Config.West
local DT = W.IndexBase
local HW = C.HighwayWidth / 2
local DECK_W = C.HighwayWidth + 12
local HALF_ROAD = C.RoadWidth / 2
local CURB = C.CurbHeight
local CITY_EDGE = CityLayout.roadCoord(0) - HALF_ROAD
local DT_EAST = WestLayout.DowntownEast
local DT_WEST = WestLayout.DowntownWest
local DT_HALFZ = WestLayout.DowntownHalfZ
local HALFZ = W.HalfZ
local roadY = CityLayout.westRoadY

local rng = Random.new(20261022)

local WARM = Color3.fromRGB(255, 196, 130)
local CONCRETE = Color3.fromRGB(128, 128, 132)
local BARRIER = Color3.fromRGB(150, 150, 154)
local GIRDER = Color3.fromRGB(46, 48, 54)
local GRASS = Color3.fromRGB(60, 84, 44)
local ROCK = Color3.fromRGB(82, 78, 72)
local SAND = Color3.fromRGB(206, 188, 150)
local WET_SAND = Color3.fromRGB(150, 134, 106)
local TRUNK = Color3.fromRGB(112, 92, 70)
local FROND = { Color3.fromRGB(46, 104, 54), Color3.fromRGB(38, 92, 48), Color3.fromRGB(58, 116, 60) }
local STONE = Color3.fromRGB(196, 190, 178)
local PASTELS = {
	Color3.fromRGB(246, 196, 206), -- flamingo pink
	Color3.fromRGB(168, 226, 214), -- mint
	Color3.fromRGB(250, 232, 176), -- lemon
	Color3.fromRGB(204, 212, 250), -- lavender
	Color3.fromRGB(255, 214, 178), -- peach
	Color3.fromRGB(244, 244, 238), -- white
	Color3.fromRGB(176, 220, 246), -- sky
}
local DECO_NEON = {
	Color3.fromRGB(255, 70, 170),
	Color3.fromRGB(0, 229, 255),
	Color3.fromRGB(130, 90, 255),
	Color3.fromRGB(255, 150, 60),
	Color3.fromRGB(80, 255, 170),
}
local HOTEL_NAMES = { "THE CORALINE", "NEON TIDE", "PALM COURT", "BLUE FLAMINGO", "THE SEABREEZE", "STARLITE", "AQUAMARINE", "MOONGLOW", "SAND DOLLAR", "VELVET WAVE", "LUNA", "THE MERIDIAN" }

-- Downtown's street names (CityBuilder's arm signs): roads along z (by i - DT) and along x (by j)
West.NS_NAMES = { "OCEAN DR", "PALM AVE", "CORAL WAY", "BAYSHORE ST", "FLAMINGO AVE", "BISCAYNE ST", "RIVERSIDE DR" }
West.EW_NAMES = { "1ST ST", "5TH ST", "SUNSET AVE", "LEGENDS BLVD", "LINCOLN AVE", "MARINA ST", "22ND ST" }

local function pick<T>(list: { T }): T
	return list[rng:NextInteger(1, #list)]
end

---------------------------------------------------------------------
-- Palms
---------------------------------------------------------------------
-- a palm: a gently leaning, tapering trunk and a crown of drooping fronds
local function palm(kit: any, parent: Instance, pos: Vector3, h: number?)
	-- (2026-10-23: 11 parts instead of 15 -- three trunk pieces, seven fronds, one crown -- the map
	-- has about 800 palms)
	local deco = kit.deco
	local height = h or rng:NextNumber(24, 38)
	local a = rng:NextNumber(0, math.pi * 2)
	local lean = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(0.04, 0.2)
	local p = pos
	local segs = 3
	for k = 1, segs do
		local d = (Vector3.yAxis + lean * (k / segs) * 2).Unit
		local len = height / segs
		local q = p + d * len
		local r = 1.65 - k * 0.2
		-- (a cylinder runs along X: turned so X looks along the trunk)
		deco(parent, Vector3.new(len + 0.4, r, r), CFrame.lookAt((p + q) / 2, q) * CFrame.Angles(0, math.pi / 2, 0), TRUNK:Lerp(Color3.fromRGB(150, 132, 104), k / segs * 0.5), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
		p = q
	end
	local frond = pick(FROND)
	local n = 7
	local a0 = rng:NextNumber(0, math.pi * 2)
	for k = 1, n do
		local ang = a0 + k / n * math.pi * 2
		local len = rng:NextNumber(11, 15)
		local droop = rng:NextNumber(0.35, 0.75)
		local tint = frond:Lerp(Color3.fromRGB(96, 120, 56), rng:NextNumber(0, 0.35)) -- sun-bleached tips vary
		deco(parent, Vector3.new(rng:NextNumber(2.4, 3.2), 0.22, len), CFrame.new(p) * CFrame.Angles(0, ang, 0) * CFrame.Angles(-droop, 0, 0) * CFrame.new(0, 0, -len / 2), tint, Enum.Material.LeafyGrass, { shadow = true })
	end
	-- the crown where the fronds meet (it also hides their roots)
	deco(parent, Vector3.one * 2.4, CFrame.new(p + Vector3.new(0, -0.6, 0)), Color3.fromRGB(70, 74, 40), Enum.Material.LeafyGrass, { shape = Enum.PartType.Ball })
	return p
end

-- a palm in a round stone planter, lit from below on some
local function plantedPalm(kit: any, parent: Instance, pos: Vector3, lit: boolean)
	kit.mk(parent, Vector3.new(1.4, 5.5, 5.5), CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.pi / 2), STONE, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder, name = "Planter" })
	palm(kit, parent, pos + Vector3.new(0, 1.3, 0))
	if lit then
		local up = kit.deco(parent, Vector3.new(0.6, 0.3, 0.6), CFrame.new(pos + Vector3.new(1.6, 1.45, 0)), WARM, Enum.Material.Neon)
		kit.addLight("SpotLight", up, Color3.fromRGB(255, 220, 170), 30, 1.6, Enum.NormalId.Top, 50)
	end
end

---------------------------------------------------------------------
-- Downtown hooks for CityBuilder
---------------------------------------------------------------------
-- building heights: tallest in the middle of Downtown
function West.height(x: number, z: number): number
	local d = Vector2.new((x - W.DowntownX) / C.HalfExtent, z / C.HalfExtent).Magnitude
	local falloff = math.clamp(1 - d * 0.75, 0, 1)
	local h = 130 + 400 * falloff ^ 1.3 + rng:NextNumber(0, 120)
	if rng:NextNumber() < 0.15 then
		h += 170
	end
	return math.floor(h)
end

local EDGES = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }

-- Downtown's sidewalks: palms in planters, benches, neon kiosks
function West.streetscape(kit: any, parent: Instance, cx: number, cz: number, inner: number)
	if not Config.Graphics.StreetDetail then
		return
	end
	local folder = kit.lodGroup(parent, "Streetscape", Vector3.new(cx, CURB, cz), 420 + inner / 2)
	for _, edge in EDGES do
		local tangent = edge:Cross(Vector3.yAxis)
		local base = Vector3.new(cx, CURB, cz) + edge * (inner / 2 - 4.5)
		for k, t in { -0.36, 0, 0.36 } do
			plantedPalm(kit, folder, base + tangent * (inner * t), k == 2)
		end
		-- bench
		local bp = base + tangent * (inner * 0.18)
		local bcf = CFrame.lookAt(bp, bp + edge)
		kit.deco(folder, Vector3.new(6, 0.4, 1.8), bcf * CFrame.new(0, 1.6, 0), Color3.fromRGB(230, 226, 214), Enum.Material.SmoothPlastic, { shadow = true })
		kit.deco(folder, Vector3.new(5.4, 1.4, 1.2), bcf * CFrame.new(0, 0.7, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		-- a lit kiosk on some corners
		if rng:NextNumber() < 0.3 then
			local kp = base + tangent * (inner * -0.18)
			local c = pick(DECO_NEON)
			kit.mk(folder, Vector3.new(5, 8, 5), CFrame.new(kp + Vector3.new(0, 4, 0)), Color3.fromRGB(26, 26, 30), Enum.Material.SmoothPlastic, { name = "Kiosk" })
			kit.deco(folder, Vector3.new(5.2, 0.5, 5.2), CFrame.new(kp + Vector3.new(0, 8.25, 0)), c, Enum.Material.Neon)
			kit.deco(folder, Vector3.new(4, 3, 0.2), CFrame.lookAt(kp + Vector3.new(0, 5, 0) + edge * 2.55, kp + Vector3.new(0, 5, 0) + edge * 4), c:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon, { transparency = 0.3 })
		end
	end
end

-- one Ocean Drive art deco hotel: pastel stucco, eyebrow ledges over each floor's windows, rounded
-- corners, a stepped central fin with the hotel's name in neon, a neon-trimmed roof and a cafe
-- terrace (no bar) on the street. `cf` stands at the front middle on the ground, facing the street
local function artDeco(kit: any, parent: Instance, cf: CFrame, w: number, d: number, floors: number, name: string)
	local mk, deco = kit.mk, kit.deco
	local body = pick(PASTELS)
	local trim = Color3.fromRGB(250, 250, 246)
	local neon = pick(DECO_NEON)
	local fh = 11
	local h = floors * fh + 4
	local at = function(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z) -- -z is the street
	end
	local model = Instance.new("Model")
	model.Name = "DecoHotel"
	model.Parent = parent
	local detail = kit.lodGroup(model, "Detail", (cf * CFrame.new(0, h / 2, d / 2)).Position, 520)
	mk(model, Vector3.new(w, h, d), at(0, h / 2, d / 2), body, Enum.Material.Plaster, { name = "DecoBody" })
	-- rounded front corners
	for _, sx in { -1, 1 } do
		mk(model, Vector3.new(h, 9, 9), at(sx * (w / 2 - 1.5), h / 2, 3) * CFrame.Angles(0, 0, math.pi / 2), body, Enum.Material.Plaster, { shape = Enum.PartType.Cylinder })
	end
	-- floors: window bands (some warmly lit), white eyebrow ledges, a neon pinstripe
	for f = 1, floors do
		local y = (f - 0.5) * fh + 1.5
		for _, side in { -1, 1 } do
			local bx = side * (w * 0.26)
			local lit = rng:NextNumber() < 0.5
			deco(detail, Vector3.new(w * 0.36, 5.5, 0.2), at(bx, y, -0.12), if lit then Color3.fromRGB(255, 206, 150) else Color3.fromRGB(26, 34, 44), if lit then Enum.Material.Neon else Enum.Material.Glass, { transparency = if lit then 0.2 else 0, reflectance = if lit then 0 else 0.3 })
			deco(detail, Vector3.new(w * 0.38, 0.5, 2.2), at(bx, y + 3.4, -1.1), trim, Enum.Material.SmoothPlastic, { shadow = true })
		end
		if f % 2 == 0 then
			deco(detail, Vector3.new(w + 0.4, 0.35, 0.3), at(0, f * fh + 1.6, -0.2), neon, Enum.Material.Neon)
		end
	end
	-- the stepped central fin and its vertical neon name
	local finH = h + 18
	mk(model, Vector3.new(9, finH, 6), at(0, finH / 2, -1), trim, Enum.Material.Plaster)
	mk(model, Vector3.new(6, 10, 5), at(0, finH + 5, 0), trim, Enum.Material.Plaster)
	deco(model, Vector3.new(1.6, 6, 1.6), at(0, finH + 13, 0), neon, Enum.Material.Neon, { shape = Enum.PartType.Ball })
	local sign = deco(model, Vector3.new(7, finH - 12, 0.4), at(0, (finH - 12) / 2 + 9, -4.2), Color3.fromRGB(16, 16, 20), Enum.Material.SmoothPlastic, { name = "DecoSign" })
	local vertical = table.concat(string.split(string.gsub(name, "^THE ", ""), ""), "\n")
	kit.surfaceText(sign, Enum.NormalId.Front, vertical, Color3.new(1, 1, 1), neon, 0.15, Enum.Font.GothamBlack, Vector2.new(120, 120 * #string.gsub(name, "^THE ", "")))
	local glow = deco(model, Vector3.new(0.3, 0.3, 0.3), at(0, finH / 2, -6), neon, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("PointLight", glow, neon, 26, 1.4)
	-- the roof's neon outline
	kit.neonOutline(model, (cf * CFrame.new(0, 0, d / 2)).Position.X, (cf * CFrame.new(0, 0, d / 2)).Position.Z, w + 0.4, d + 0.4, h + 0.2, neon, 0.45)
	-- the cafe terrace on the street: awning, tables under parasols, warm glass front
	deco(detail, Vector3.new(w * 0.9, 8, 0.2), at(0, 4.5, -0.15), Color3.fromRGB(255, 214, 160), Enum.Material.Neon, { transparency = 0.45 })
	deco(detail, Vector3.new(w * 0.92, 0.5, 6), at(0, 10.5, -3.2) * CFrame.Angles(math.rad(-12), 0, 0), neon:Lerp(Color3.new(0, 0, 0), 0.4), Enum.Material.Fabric, { shadow = true })
	for k = -2, 2 do
		local tp = at(k * (w * 0.18), 0, -10)
		deco(detail, Vector3.new(0.3, 3, 0.3), tp * CFrame.new(0, 1.5, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		deco(detail, Vector3.new(3.4, 0.25, 3.4), tp * CFrame.new(0, 3.1, 0), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic)
		deco(detail, Vector3.new(0.2, 8, 0.2), tp * CFrame.new(0, 4, 0), Color3.fromRGB(200, 200, 204), Enum.Material.Metal)
		deco(detail, Vector3.new(7, 0.4, 7), tp * CFrame.new(0, 8, 0), pick(PASTELS), Enum.Material.Fabric, { shadow = true })
	end
	return model
end

-- one of Downtown's venue sites (hotel, casino, gem showcase)?
function West.isSite(bi: number, bj: number): boolean
	for _, s in W.Sites do
		if s[1] == bi and s[2] == bj then
			return true
		end
	end
	return false
end

-- the hotel / casino / gem showcase sites stay bare (their own modules build there); the Ocean
-- Drive row gets art deco hotels in front and glass condo towers behind
function West.block(kit: any, parent: Instance, bi: number, bj: number, cx: number, cz: number, lot: number): boolean
	if West.isSite(bi, bj) then
		return true
	end
	if bi == DT then
		-- three hotels along the lot's west edge, facing Ocean Drive (-X)
		local front = Vector3.new(-1, 0, 0)
		local x0 = cx - lot / 2 + 2
		local slot = lot / 3
		for k = 0, 2 do
			local z = cz - lot / 2 + slot * (k + 0.5)
			local p = Vector3.new(x0, CURB, z)
			artDeco(kit, parent, CFrame.lookAt(p, p + front), slot - 8, 62, rng:NextInteger(3, 5), pick(HOTEL_NAMES))
		end
		-- condo towers behind
		local bx = cx + lot / 4 + 6
		for _, sz in { -1, 1 } do
			kit.building(parent, bx, cz + sz * lot / 4, lot / 2 - 26, lot / 2 - 18, rng:NextNumber(150, 300), CURB, front, false)
		end
		return true
	end
	return false
end

---------------------------------------------------------------------
-- The coastal highway: deck, rails, markings, lights, pillars
---------------------------------------------------------------------
-- pieces of the road between two x (going west): short where it climbs, long where it's level
local function roadPieces(x0: number, x1: number): { { number } }
	local out = {}
	local x = x0
	while x > x1 + 0.01 do
		local nx = math.max(x - 40, x1)
		local level = math.abs(roadY(x) - roadY(nx)) < 1e-3 and math.abs(roadY((x + nx) / 2) - roadY(x)) < 1e-3
		local last = out[#out]
		if level and last and last[1] - nx <= 800 and math.abs(roadY(last[1]) - roadY(last[2])) < 1e-3 and math.abs(roadY((last[1] + last[2]) / 2) - roadY(last[2])) < 1e-3 then
			last[2] = nx
		else
			table.insert(out, { x, nx })
		end
		x = nx
	end
	return out
end

local function at(x: number, z: number, lift: number?): Vector3
	return Vector3.new(x, roadY(x) + (lift or 0), z)
end

-- a strip along the road (deck, rail, line) from xa to xb at side offset z, following the deck
local function strip(kit: any, parent: Instance, xa: number, xb: number, z: number, width: number, thick: number, lift: number, color: Color3, material: Enum.Material, opts: any?)
	local pa, pb = at(xa, z, lift), at(xb, z, lift)
	local len = (pb - pa).Magnitude
	local cf = CFrame.lookAt((pa + pb) / 2, pb)
	return kit.mk(parent, Vector3.new(width, thick, len + 0.3), cf * CFrame.new(0, -thick / 2, 0), color, material, opts)
end

local function highway(kit: any, root: Instance)
	local hwy = kit.folder("CoastalHighway", root)
	local pieces = roadPieces(CITY_EDGE, DT_EAST)
	local loopX = -C.LoopHalf
	local suburbX = -((C.HalfExtent + HALF_ROAD + C.OuterRingDepth + 1500) + (C.LoopHalf - HW - 8)) / 2
	for k, pc in pieces do
		local xa, xb = pc[1], pc[2]
		local high = math.max(roadY(xa), roadY(xb)) > 0.5
		local mid = (xa + xb) / 2
		local group = kit.lodGroup(hwy, `Stretch_{k}`, at(mid, 0), 900 + (xa - xb) / 2)
		-- the deck (asphalt on top; a steel girder under it where it's up in the air)
		strip(kit, hwy, xa, xb, 0, DECK_W, if high then 3 else 2, 0, kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		if high then
			strip(kit, group, xa, xb, 0, DECK_W - 10, 4, -3, GIRDER, Enum.Material.Metal, { collide = false, shadow = true })
			-- concrete parapets and invisible walls (nobody drives off the viaduct or the bridge)
			for _, s in { -1, 1 } do
				strip(kit, hwy, xa, xb, s * (DECK_W / 2 - 0.7), 1.4, 3.2, 3.2, BARRIER, Enum.Material.Concrete, { name = "Parapet" })
				strip(kit, hwy, xa, xb, s * (DECK_W / 2 - 0.7), 1.4, 40, 43, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
				strip(kit, group, xa, xb, s * (DECK_W / 2 - 0.3), 0.3, 0.3, 2.4, Color3.fromRGB(255, 160, 40), Enum.Material.Neon, { collide = false })
			end
		else
			for _, s in { -1, 1 } do
				strip(kit, group, xa, xb, s * (HW + 2), 0.6, 1.2, 2.8, Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { reflectance = 0.2, name = "GuardRail" })
			end
		end
	end
	-- markings, chunked for distance culling
	local marks = kit.folder("HighwayMarkings", hwy)
	local chunk: Model? = nil
	local chunkX = math.huge
	local function chunkAt(x: number): Model
		if not chunk or chunkX - x > 600 then
			chunkX = x
			chunk = kit.lodGroup(marks, `Marks_{math.floor(-x)}`, at(x - 300, 0), 700)
		end
		return chunk :: Model
	end
	for _, pc in pieces do
		local g = chunkAt(pc[1])
		for _, z in { -0.4, 0.4 } do
			strip(kit, g, pc[1], pc[2], z, 0.3, 0.05, 0.06, kit.LINE_YELLOW, Enum.Material.SmoothPlastic, { collide = false })
		end
		for _, z in { -(HW - 1), HW - 1 } do
			strip(kit, g, pc[1], pc[2], z, 0.4, 0.05, 0.06, kit.LINE_WHITE, Enum.Material.SmoothPlastic, { collide = false })
		end
	end
	local x = CITY_EDGE - 12
	while x > DT_EAST + 20 do
		local g = chunkAt(x)
		for _, z in { -2 * C.LaneWidth, -C.LaneWidth, C.LaneWidth, 2 * C.LaneWidth } do
			strip(kit, g, x, x - 12, z, 0.35, 0.05, 0.06, kit.LINE_WHITE, Enum.Material.SmoothPlastic, { collide = false })
		end
		x -= 30
	end
	-- lights along both edges
	local idx = 0
	x = CITY_EDGE - 60
	while x > DT_EAST + 30 do
		idx += 1
		local high = roadY(x) > 0.5
		local s = if idx % 2 == 0 then 1 else -1
		local edge = if high then DECK_W / 2 - 1.6 else HW + 5
		-- (not on the bridge's main span: the cables light it)
		if not (x < W.BridgeTowers[1] + 10 and x > W.BridgeTowers[2] - 10) then
			kit.streetLight(chunkAt(x), at(x, s * edge, if high then 0 else 0), Vector3.new(0, 0, -s))
		end
		x -= 85
	end
	-- pillars under the viaduct and the bridge approaches (not on the roads underneath)
	local function pillarsBetween(x0: number, x1: number, step: number)
		local px = x0
		while px > x1 do
			local y = roadY(px)
			local clear = math.abs(px - loopX) > 70 and math.abs(px - suburbX) > 24
			if y > 7 and clear then
				local bottom = -24
				local hgt = y - 3 - bottom
				for _, s in { -1, 1 } do
					kit.mk(hwy, Vector3.new(6, hgt, 6), CFrame.new(px, bottom + hgt / 2, s * (HW - 8)), CONCRETE, Enum.Material.Concrete, { name = "Pillar" })
				end
				kit.mk(hwy, Vector3.new(7, 4, DECK_W - 6), CFrame.new(px, y - 5, 0), CONCRETE, Enum.Material.Concrete, { name = "PierCap" })
			end
			px -= step
		end
	end
	pillarsBetween(W.ViaductUp[1] - 120, W.ViaductDown[2], 110)
	pillarsBetween(W.BridgeUp[1] - 60, W.BridgeTowers[1] + 30, 70)
	pillarsBetween(W.BridgeTowers[2] - 30, W.BridgeDown[2], 70)
	-- overhead signs
	local function gantry(gx: number, text: string, sub: string)
		local y = roadY(gx)
		local high = y > 0.5
		local edge = if high then DECK_W / 2 - 1.5 else HW + 4
		for _, s in { -1, 1 } do
			kit.mk(hwy, Vector3.new(1.2, 26, 1.2), CFrame.new(gx, y + 13, s * edge), kit.METAL, Enum.Material.Metal)
		end
		kit.deco(hwy, Vector3.new(1.4, 1.4, edge * 2 + 2), CFrame.new(gx, y + 25, 0), kit.METAL, Enum.Material.Metal)
		local sign = kit.deco(hwy, Vector3.new(0.6, 7, 34), CFrame.new(gx + 0.5, y + 20, -HW / 2), Color3.fromRGB(10, 70, 40), Enum.Material.SmoothPlastic)
		kit.surfaceText(sign, Enum.NormalId.Right, text, Color3.new(1, 1, 1), Color3.fromRGB(10, 90, 50), 0, Enum.Font.GothamBold, Vector2.new(800, 160))
		local back = kit.deco(hwy, Vector3.new(0.6, 7, 34), CFrame.new(gx - 0.5, y + 20, HW / 2), Color3.fromRGB(10, 70, 40), Enum.Material.SmoothPlastic)
		kit.surfaceText(back, Enum.NormalId.Left, sub, Color3.new(1, 1, 1), Color3.fromRGB(10, 90, 50), 0, Enum.Font.GothamBold, Vector2.new(800, 160))
	end
	gantry(CITY_EDGE - 160, "DOWNTOWN  ·  ISLANDS  →", "CITY CENTRE")
	gantry(W.Canyon[1] + 200, "LEGENDS BRIDGE  ·  DOWNTOWN", "LEGENDS LOOP  ·  CITY")
	gantry(W.BridgeDown[2] - 30, "OCEAN DRIVE  ·  ISLANDS", "CITY  ·  LEGENDS LOOP")
end

---------------------------------------------------------------------
-- The canyon through the mountains
---------------------------------------------------------------------
local function canyon(kit: any, root: Instance)
	local folder = kit.folder("Canyon", root)
	local x0, x1 = W.Canyon[1], W.Canyon[2]
	local x = x0 - 60
	while x > x1 do
		for _, s in { -1, 1 } do
			local len = rng:NextNumber(160, 240)
			local hgt = rng:NextNumber(110, 240)
			local depth = hgt * rng:NextNumber(1.1, 1.6)
			local cz = s * (HW + 16 + depth / 2)
			local rock = Color3.fromRGB(110, 92, 74):Lerp(Color3.fromRGB(140, 118, 92), rng:NextNumber()) -- (sandstone canyon)
			-- the slope faces the road: the wedge's -Z looks at it
			kit.mk(folder, Vector3.new(len, hgt, depth), CFrame.lookAt(Vector3.new(x, hgt / 2 - 6, cz), Vector3.new(x, hgt / 2 - 6, cz - s)), rock, Enum.Material.Slate, { class = "Wedge", name = "CanyonWall" })
			kit.mk(folder, Vector3.new(len, hgt * 0.8, 300), CFrame.new(x, hgt * 0.4 - 6, s * (HW + 16 + depth + 150)), rock, Enum.Material.Slate, { name = "CanyonWall" })
			if rng:NextNumber() < 0.6 then
				kit.deco(folder, Vector3.new(rng:NextNumber(8, 18), rng:NextNumber(6, 12), rng:NextNumber(8, 16)), CFrame.new(x + rng:NextNumber(-60, 60), 3, s * (HW + 12 + rng:NextNumber(0, 8))) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 3), 0), ROCK, Enum.Material.Rock, { shadow = true })
			end
		end
		x -= 150
	end
end

---------------------------------------------------------------------
-- The river and the Legends Bridge
---------------------------------------------------------------------
local function river(kit: any, root: Instance)
	local folder = kit.folder("River", root)
	local e, w = W.River[1], W.River[2]
	workspace.Terrain:FillBlock(CFrame.new((e + w) / 2, -9, 0), Vector3.new(e - w + 40, 14, (HALFZ + 1600) * 2), Enum.Material.Water)
	-- rocky banks
	for _, side in { { x = e, s = 1 }, { x = w, s = -1 } } do
		local z = -HALFZ - 300
		while z < HALFZ + 300 do
			local p = Vector3.new(side.x, 0, z + 60)
			-- slope down into the water (towards the river: -s along x)
			kit.mk(folder, Vector3.new(124, 5, 18), CFrame.lookAt(p + Vector3.new(-side.s * 7, -2.6, 0), p + Vector3.new(-side.s * 7, -2.6, 0) + Vector3.new(side.s, 0, 0)) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), ROCK, Enum.Material.Slate, { class = "Wedge", name = "Bank" })
			z += 120
		end
	end
end

local function bridge(kit: any, root: Instance)
	local folder = kit.folder("LegendsBridge", root)
	local deck = W.DeckY
	local tx1, tx2 = W.BridgeTowers[1], W.BridgeTowers[2]
	local topY = deck + 175
	local legZ = DECK_W / 2 + 5
	local cableZ = DECK_W / 2 + 1
	local GOLD = Color3.fromRGB(255, 206, 120)
	local tower = Color3.fromRGB(150, 146, 140)
	for _, tx in { tx1, tx2 } do
		for _, s in { -1, 1 } do
			-- two stacked, slightly tapering legs
			kit.mk(folder, Vector3.new(10, deck + 30, 10), CFrame.new(tx, (deck + 30) / 2 - 24, s * legZ), tower, Enum.Material.Concrete, { name = "TowerLeg" })
			kit.mk(folder, Vector3.new(8, topY - deck, 8), CFrame.new(tx, deck + (topY - deck) / 2, s * legZ), tower, Enum.Material.Concrete, { name = "TowerLeg" })
			-- lit strips up the leg facing the road traffic both ways
			for _, fx in { -1, 1 } do
				kit.deco(folder, Vector3.new(0.4, topY - deck - 10, 1.2), CFrame.new(tx + fx * 4.2, deck + (topY - deck) / 2, s * legZ), GOLD, Enum.Material.Neon, { transparency = 0.15 })
			end
			local beacon = kit.deco(folder, Vector3.one * 3, CFrame.new(tx, topY + 6, s * legZ), Color3.fromRGB(255, 25, 25), Enum.Material.Neon, { shape = Enum.PartType.Ball })
			CollectionService:AddTag(beacon, "Blink")
			kit.deco(folder, Vector3.new(6, 6, 6), CFrame.new(tx, topY + 2, s * legZ), tower, Enum.Material.Concrete)
			local flood = kit.deco(folder, Vector3.new(2, 1, 2), CFrame.new(tx + 8, deck + 2, s * legZ), WARM, Enum.Material.Neon)
			kit.addLight("SpotLight", flood, Color3.fromRGB(255, 222, 170), 120, 3, Enum.NormalId.Top, 30)
		end
		-- cross beams: under the deck, in the middle and at the top (with the bridge's name)
		kit.mk(folder, Vector3.new(8, 8, legZ * 2 + 8), CFrame.new(tx, deck - 8, 0), tower, Enum.Material.Concrete)
		kit.mk(folder, Vector3.new(7, 9, legZ * 2), CFrame.new(tx, deck + 95, 0), tower, Enum.Material.Concrete)
		local top = kit.mk(folder, Vector3.new(7, 12, legZ * 2), CFrame.new(tx, topY - 12, 0), tower, Enum.Material.Concrete, { name = "TowerTop" })
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			kit.surfaceText(top, face, "LEGENDS BRIDGE", GOLD, nil, nil, Enum.Font.GothamBlack, Vector2.new(1100, 140))
		end
	end
	-- the main cables: necklace-lit catenaries over the main span, falling to anchorages on the banks
	local anchorE, anchorW = W.BridgeUp[1] + 20, W.BridgeDown[2] - 20
	local function cableY(x: number): number
		if x <= tx1 and x >= tx2 then
			local m = (tx1 + tx2) / 2
			local u = (x - m) / ((tx1 - tx2) / 2)
			return deck + 8 + (topY - 6 - deck - 8) * u * u
		end
		-- side spans: a gentle sag from the tower top down to the anchorage
		local a, b = if x > tx1 then anchorE else anchorW, if x > tx1 then tx1 else tx2
		local t = (x - a) / (b - a)
		local ya, yb = roadY(a) + 6, topY - 6
		return ya + (yb - ya) * t - 18 * t * (1 - t)
	end
	local xs = {}
	local x = anchorE
	while x > anchorW do
		table.insert(xs, x)
		x -= 20
	end
	table.insert(xs, anchorW)
	for _, s in { -1, 1 } do
		local z = s * cableZ
		for k = 1, #xs - 1 do
			local a = Vector3.new(xs[k], cableY(xs[k]), z)
			local b = Vector3.new(xs[k + 1], cableY(xs[k + 1]), z)
			kit.deco(folder, Vector3.new((b - a).Magnitude + 0.6, 2.2, 2.2), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(170, 166, 160), Enum.Material.Metal, { shape = Enum.PartType.Cylinder, shadow = true })
			-- necklace lights
			kit.deco(folder, Vector3.one * 1.6, CFrame.new(a + Vector3.new(0, 1.4, 0)), Color3.fromRGB(255, 236, 200), Enum.Material.Neon, { shape = Enum.PartType.Ball })
			-- suspender down to the deck edge
			local y = roadY(xs[k]) + 3.2
			if a.Y - y > 3 and math.abs(xs[k] - tx1) > 6 and math.abs(xs[k] - tx2) > 6 then
				kit.deco(folder, Vector3.new(a.Y - y, 0.5, 0.5), CFrame.new(xs[k], (a.Y + y) / 2, s * (DECK_W / 2 - 0.7)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 146, 140), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
			end
		end
		-- anchorages
		for _, ax in { anchorE, anchorW } do
			kit.mk(folder, Vector3.new(30, 18, 14), CFrame.new(ax, roadY(ax) + 5, s * (cableZ + 6)), CONCRETE, Enum.Material.Concrete, { name = "Anchorage" })
		end
	end
end

---------------------------------------------------------------------
-- Downtown's surroundings: ground, skyline ring, riverside park
---------------------------------------------------------------------
local function downtownGround(kit: any, root: Instance)
	local folder = kit.folder("DowntownGround", root)
	-- grass under the whole west bank, the grid's asphalt on top
	kit.slab(folder, W.River[2], -HALFZ - 200, DT_WEST - 20, HALFZ + 200, -0.3, 4, GRASS, Enum.Material.Grass, { name = "Land" })
	kit.slab(folder, W.River[1] + 20, -HALFZ - 200, W.Canyon[2] - 4, HALFZ + 200, -0.3, 4, GRASS, Enum.Material.Grass, { name = "Land" })
	kit.slab(folder, DT_EAST, -DT_HALFZ, DT_WEST, DT_HALFZ, 0, 4, kit.ASPHALT, kit.ROAD_MAT, table.clone(kit.ROAD_OPTS))
	-- the coastal highway's road on the ground between the bridge and Downtown is the deck (highway)

	-- the skyline ring north and south of Downtown: dense glass towers facing it
	local ring = W.DowntownRing
	local function ringHeight(_x: number, _z: number): number
		return math.floor(rng:NextNumber(160, 420))
	end
	for _, s in { -1, 1 } do
		local z0, z1 = s * DT_HALFZ, s * (DT_HALFZ + ring)
		kit.slab(folder, DT_WEST, math.min(z0, z1), DT_EAST, math.max(z0, z1), CURB, CURB, kit.SIDEWALK, Enum.Material.Pavement)
		kit.fillBuildings(folder, DT_WEST + 14, math.min(z0, z1) + 14, DT_EAST - 14, math.max(z0, z1) - 14, ringHeight, 118, Vector3.new(0, 0, -s))
		for x = DT_WEST + 60, DT_EAST - 60, 150 do
			kit.streetLight(folder, Vector3.new(x, CURB, s * (DT_HALFZ + 3)), Vector3.new(0, 0, -s))
		end
		-- beyond: the far skyline (silhouettes with lit floors) out to the edge of the west
		for x = DT_WEST + 60, DT_EAST - 40, 130 do
			for _, row in { 1, 2, 3 } do
				local h = rng:NextNumber(120, 460) * (1.15 - row * 0.15)
				local w = rng:NextNumber(60, 110)
				local z = s * (DT_HALFZ + ring + row * 380 + rng:NextNumber(-60, 60))
				if math.abs(z) < HALFZ + 600 then
					local p = Vector3.new(x + rng:NextNumber(-30, 30), 0, z)
					kit.deco(folder, Vector3.new(w, h, w), CFrame.new(p.X, h / 2 - 2, p.Z), Color3.fromRGB(64, 72, 84), Enum.Material.Glass, { reflectance = 0.2 })
					for _ = 1, rng:NextInteger(3, 6) do
						local y = rng:NextNumber(12, h - 8)
						local fp = p - Vector3.new(0, 0, s * (w / 2 + 0.1))
						kit.deco(folder, Vector3.new(w * rng:NextNumber(0.4, 0.95), 3, 0.3), CFrame.lookAt(Vector3.new(fp.X, y, fp.Z), Vector3.new(fp.X, y, fp.Z) - Vector3.new(0, 0, s)), if rng:NextNumber() < 0.6 then WARM else pick(DECO_NEON), Enum.Material.Neon, { transparency = 0.35 })
					end
					if h > 300 then
						local beacon = kit.deco(folder, Vector3.one * 3, CFrame.new(p.X, h, p.Z), Color3.fromRGB(255, 20, 20), Enum.Material.Neon, { shape = Enum.PartType.Ball })
						CollectionService:AddTag(beacon, "Blink")
					end
				end
			end
		end
	end

	-- the riverside park between Downtown and the river (the highway runs through it)
	local park = kit.folder("RiversidePark", folder)
	local px0, px1 = DT_EAST, W.River[2] + 16
	for _, s in { -1, 1 } do
		local z0, z1 = s * (HW + 14), s * (DT_HALFZ + ring)
		kit.mk(park, Vector3.new(px1 - px0, 0.4, math.abs(z1 - z0)), CFrame.new((px0 + px1) / 2, 0.2, (z0 + z1) / 2), Color3.fromRGB(66, 98, 50), Enum.Material.Grass, { name = "Lawn" })
		local g = kit.lodGroup(park, `Park_{s}`, Vector3.new((px0 + px1) / 2, 0, (z0 + z1) / 2), 1100)
		-- the promenade along the river with lamps and palms
		kit.deco(g, Vector3.new(16, 0.5, math.abs(z1 - z0)), CFrame.new(px1 - 10, 0.25, (z0 + z1) / 2), Color3.fromRGB(150, 140, 126), Enum.Material.Pavement)
		local z = z0 + s * 30
		while math.abs(z) < math.abs(z1) - 20 do
			palm(kit, g, Vector3.new(px1 - 22, 0.4, z))
			kit.deco(g, Vector3.new(0.4, 9, 0.4), CFrame.new(px1 - 3, 4.9, z + s * 20), kit.METAL, Enum.Material.Metal)
			local bulb = kit.deco(g, Vector3.one * 1.3, CFrame.new(px1 - 3, 9.6, z + s * 20), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
			kit.dayOff(bulb, if math.floor(math.abs(z) / 45) % 2 == 0 then kit.addLight("PointLight", bulb, WARM, 24, 0.9) else nil)
			z += s * 45
		end
		-- palms dotted over the lawn
		for _ = 1, 14 do
			palm(kit, g, Vector3.new(rng:NextNumber(px0 + 20, px1 - 40), 0.4, rng:NextNumber(math.min(z0, z1) + 20, math.max(z0, z1) - 20)))
		end
	end
	-- DOWNTOWN in big lit letters on the lawn, facing the bridge
	local sign = kit.deco(park, Vector3.new(1.5, 18, 120), CFrame.new(DT_EAST + 90, 9, -(HW + 90)), Color3.fromRGB(12, 12, 16), Enum.Material.SmoothPlastic, { name = "DowntownSign" })
	kit.surfaceText(sign, Enum.NormalId.Right, "DOWNTOWN", Color3.new(1, 1, 1), nil, nil, Enum.Font.GothamBlack, Vector2.new(1400, 210))
	local signGlow = kit.deco(park, Vector3.new(0.5, 0.5, 0.5), CFrame.new(DT_EAST + 100, 4, -(HW + 90)), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", signGlow, Color3.fromRGB(255, 120, 200), 50, 3, Enum.NormalId.Left, 70)
end

---------------------------------------------------------------------
-- Ocean Drive: the promenade, the beach and the sea
---------------------------------------------------------------------
local function beach(kit: any, root: Instance)
	local folder = kit.folder("Beach", root)
	local x0 = DT_WEST -- Ocean Drive's beach-side edge
	local prom = x0 - 16
	local sea = W.BeachWest
	workspace.Terrain:FillBlock(CFrame.new((sea + W.SeaWest) / 2 - 10, -9, 0), Vector3.new(sea - W.SeaWest + 60, 14, (HALFZ + 1600) * 2), Enum.Material.Water)
	-- promenade (a raised sidewalk with a low white wall), sand, wet sand sloping into the sea
	kit.slab(folder, x0, -HALFZ - 200, prom, HALFZ + 200, CURB, CURB + 2, Color3.fromRGB(176, 166, 150), Enum.Material.Pavement, { name = "Promenade" })
	kit.slab(folder, prom, -HALFZ - 200, sea + 30, HALFZ + 200, 0.2, 4, SAND, Enum.Material.Sand, { name = "Sand" })
	local z = -HALFZ - 200
	while z < HALFZ + 200 do
		local len = math.min(600, HALFZ + 200 - z)
		local p = Vector3.new(sea + 6, -1.8, z + len / 2)
		-- (the slope faces the sea: -X)
		kit.mk(folder, Vector3.new(len, 4, 48), CFrame.lookAt(p, p - Vector3.new(1, 0, 0)), WET_SAND, Enum.Material.Sand, { class = "Wedge", name = "Shoreline" })
		z += len
	end
	for _, s in { -1, 1 } do
		-- the low wall along the promenade's beach side (gaps for the causeway and some steps)
		local zz = s * 80
		while math.abs(zz) < HALFZ + 150 do
			kit.mk(folder, Vector3.new(1.2, 2.4, 70), CFrame.new(prom + 0.6, CURB + 1.2, zz + s * 35), Color3.fromRGB(240, 238, 230), Enum.Material.Plaster, { name = "SeaWall" })
			zz += s * 90
		end
	end
	-- along the beach, in LOD chunks: palms on the promenade, lamps, lifeguard towers, parasols
	for c = -6, 5 do
		local za, zb = c * 460, (c + 1) * 460
		if za > HALFZ + 100 or zb < -HALFZ - 100 then
			continue
		end
		local g = kit.lodGroup(folder, `BeachChunk_{c}`, Vector3.new((x0 + sea) / 2, 0, (za + zb) / 2), 1000)
		local zz = za + 20
		while zz < zb do
			if math.abs(zz) > 40 then
				plantedPalm(kit, g, Vector3.new(prom + 6, CURB, zz), math.floor(zz / 36) % 3 == 0)
			end
			zz += 36
		end
		local lz = za + 30
		while lz < zb do
			if math.abs(lz) > 50 then
				kit.deco(g, Vector3.new(0.5, 13, 0.5), CFrame.new(x0 - 2, CURB + 6.5, lz), kit.METAL, Enum.Material.Metal)
				local lamp = kit.deco(g, Vector3.new(2.4, 0.5, 1.4), CFrame.new(x0 - 2, CURB + 13, lz), WARM, Enum.Material.Neon)
				kit.dayOff(lamp, kit.addLight("SpotLight", lamp, WARM, 40, 1.4, Enum.NormalId.Bottom, 120))
			end
			lz += 110
		end
		-- a pastel lifeguard tower
		local tz = (za + zb) / 2 + rng:NextNumber(-80, 80)
		if math.abs(tz) > 80 then
			local tp = Vector3.new(sea + 70, 0.2, tz)
			for _, dx in { -3, 3 } do
				for _, dz in { -3, 3 } do
					kit.deco(g, Vector3.new(0.6, 9, 0.6), CFrame.new(tp + Vector3.new(dx, 4.5, dz)), Color3.fromRGB(220, 220, 214), Enum.Material.Wood)
				end
			end
			kit.mk(g, Vector3.new(9, 6, 9), CFrame.new(tp + Vector3.new(0, 12, 0)), pick(PASTELS), Enum.Material.Plaster, { name = "LifeguardTower" })
			kit.deco(g, Vector3.new(10.5, 0.6, 10.5), CFrame.new(tp + Vector3.new(0, 15.3, 0)), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic)
			kit.deco(g, Vector3.new(0.3, 4, 3), CFrame.new(tp + Vector3.new(-4.7, 12, 0)), pick(DECO_NEON), Enum.Material.Neon, { transparency = 0.2 })
		end
		-- parasols with pairs of loungers
		for _ = 1, 5 do
			local pz = rng:NextNumber(za + 20, zb - 20)
			if math.abs(pz) < 60 then
				continue
			end
			local pp = Vector3.new(rng:NextNumber(sea + 30, prom - 40), 0.2, pz)
			kit.deco(g, Vector3.new(0.3, 8, 0.3), CFrame.new(pp + Vector3.new(0, 4, 0)), Color3.fromRGB(230, 230, 226), Enum.Material.Metal)
			kit.deco(g, Vector3.new(0.8, 9, 9), CFrame.new(pp + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.pi / 2), pick(PASTELS), Enum.Material.Fabric, { shape = Enum.PartType.Cylinder, shadow = true })
			for _, dz in { -2.4, 2.4 } do
				kit.deco(g, Vector3.new(6, 0.5, 2.2), CFrame.new(pp + Vector3.new(-1, 1, dz)) * CFrame.Angles(0, 0, math.rad(-8)), Color3.fromRGB(245, 245, 240), Enum.Material.SmoothPlastic)
			end
		end
	end
end

---------------------------------------------------------------------
-- The causeway, the islands and the bridges between them
---------------------------------------------------------------------
-- a straight deck over the sea from a to b (y from CityLayout.seaRoadY), with rails, walls,
-- lamps, piers and markings; nLanes each way
local function seaRoad(kit: any, parent: Instance, a: Vector3, b: Vector3, width: number, landA: number, landB: number, laneOffsets: { number })
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local dir = flat.Unit
	local side = dir:Cross(Vector3.yAxis)
	local function pt(d: number, off: number, lift: number): Vector3
		local p = a + dir * d + side * off
		return Vector3.new(p.X, CityLayout.seaRoadY(d, len, landA, landB) + lift, p.Z)
	end
	local function piece(d0: number, d1: number, off: number, w: number, thick: number, lift: number, color: Color3, mat: Enum.Material, opts: any?)
		local pa, pb = pt(d0, off, lift), pt(d1, off, lift)
		return kit.mk(parent, Vector3.new(w, thick, (pb - pa).Magnitude + 0.3), CFrame.lookAt((pa + pb) / 2, pb) * CFrame.new(0, -thick / 2, 0), color, mat, opts)
	end
	-- pieces: short on the ramps, long over the level stretch
	local cuts = { 0 }
	local d = 0
	while d < len do
		local nd = math.min(d + 30, len)
		local y0, y1 = CityLayout.seaRoadY(d, len, landA, landB), CityLayout.seaRoadY(nd, len, landA, landB)
		local last = cuts[#cuts]
		if #cuts >= 2 and math.abs(y0 - y1) < 1e-3 and math.abs(CityLayout.seaRoadY(cuts[#cuts - 1], len, landA, landB) - y0) < 1e-3 and nd - cuts[#cuts - 1] < 700 then
			cuts[#cuts] = nd
		else
			table.insert(cuts, nd)
		end
		d = nd
		local _ = last
	end
	local group = kit.lodGroup(parent, "Detail", (a + b) / 2, 700 + len / 2)
	for k = 1, #cuts - 1 do
		local d0, d1 = cuts[k], cuts[k + 1]
		piece(d0, d1, 0, width, 2.4, 0, kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		piece(d0, d1, 0, width - 8, 3, -2.4, GIRDER, Enum.Material.Concrete, { collide = false, shadow = true })
		for _, s in { -1, 1 } do
			piece(d0, d1, s * (width / 2 - 0.6), 1.2, 3, 3, Color3.fromRGB(240, 238, 230), Enum.Material.Plaster, { name = "Rail" })
			piece(d0, d1, s * (width / 2 - 0.6), 1.2, 30, 33, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
			piece(d0, d1, s * (width / 2 - 2), 0.4, 0.05, 0.05, kit.LINE_WHITE, Enum.Material.SmoothPlastic, { collide = false })
		end
		for _, off in laneOffsets do
			piece(d0, d1, off, 0.3, 0.05, 0.05, kit.LINE_YELLOW, Enum.Material.SmoothPlastic, { collide = false })
		end
	end
	-- lamps and piers
	local l = 20
	local k = 0
	while l < len - 10 do
		k += 1
		local s = if k % 2 == 0 then 1 else -1
		local base = pt(l, s * (width / 2 - 1.6), 0)
		kit.streetLight(group, base, -side * s)
		local y = CityLayout.seaRoadY(l, len, landA, landB)
		if y > 3 then
			local p = pt(l, 0, 0)
			kit.mk(parent, Vector3.new(width - 10, y + 18, 5), CFrame.lookAt(Vector3.new(p.X, (y - 2.4 - 20) / 2 + 0, p.Z), Vector3.new(p.X, (y - 2.4 - 20) / 2, p.Z) + side), CONCRETE, Enum.Material.Concrete, { name = "Pier" })
		end
		l += 60
	end
end

local function island(kit: any, root: Instance, isl: any, joins: { number })
	local folder = kit.folder("Island_" .. isl.id, root)
	local c = Vector3.new(isl.x, 0, isl.z)
	local r = isl.r
	-- the island: a sand disc, a lawn inside the beach strip
	kit.mk(folder, Vector3.new(6, r * 2, r * 2), CFrame.new(c.X, -3, c.Z) * CFrame.Angles(0, 0, math.pi / 2), SAND, Enum.Material.Sand, { shape = Enum.PartType.Cylinder, name = "IslandSand" })
	kit.mk(folder, Vector3.new(0.4, (r - 24) * 2, (r - 24) * 2), CFrame.new(c.X, 0.05, c.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 104, 54), Enum.Material.Grass, { shape = Enum.PartType.Cylinder, name = "IslandLawn", collide = false })
	-- the ring road (straight pieces round the circle), a centre line and kerbs
	local ring = isl.ring
	local road = W.IslandRoad
	local n = 64
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = c + Vector3.new(math.cos(a0), 0, math.sin(a0)) * ring
		local p1 = c + Vector3.new(math.cos(a1), 0, math.sin(a1)) * ring
		local mid = (p0 + p1) / 2
		local len = (p1 - p0).Magnitude + 1.2
		local cf = CFrame.lookAt(mid, p1)
		kit.mk(folder, Vector3.new(road, 0.5, len), cf * CFrame.new(0, 0.1 - 0.25, 0), kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		if k % 2 == 0 then
			kit.deco(folder, Vector3.new(0.35, 0.05, len * 0.6), cf * CFrame.new(0, 0.13, 0), kit.LINE_YELLOW, Enum.Material.SmoothPlastic)
		end
		for _, s in { -1, 1 } do
			kit.mk(folder, Vector3.new(1, CURB, len), cf * CFrame.new(s * (road / 2 + 0.5), CURB / 2 + 0.1, 0), Color3.fromRGB(200, 198, 190), Enum.Material.Concrete, { name = "Kerb" })
		end
		-- lamps on the outer kerb
		if k % 4 == 0 then
			local out = Vector3.new(math.cos(a0), 0, math.sin(a0))
			kit.streetLight(folder, p0 + out * (road / 2 + 2) + Vector3.new(0, 0.1, 0), -out)
		end
	end
	-- palms round the beach strip, not where roads come in
	local np = math.floor(2 * math.pi * (r - 12) / 34)
	for k = 0, np - 1 do
		local a = k / np * math.pi * 2
		local clear = true
		for _, j in joins do
			local d = (a - j) % (2 * math.pi)
			if math.min(d, 2 * math.pi - d) < 0.16 then
				clear = false
			end
		end
		if clear then
			palm(kit, folder, c + Vector3.new(math.cos(a), 0, math.sin(a)) * (r - 12) + Vector3.new(0, 0, 0))
		end
	end
	-- the middle: a lawn with a fountain plaza and palms (Legends Key: a helipad and the island sign)
	local inner = ring - road / 2 - 12
	kit.mk(folder, Vector3.new(1.4, 36, 36), CFrame.new(c.X, 0.7, c.Z) * CFrame.Angles(0, 0, math.pi / 2), STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local water = kit.deco(folder, Vector3.new(0.4, 31, 31), CFrame.new(c.X, 1.3, c.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(60, 170, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.45 })
	kit.addLight("PointLight", water, Color3.fromRGB(80, 170, 255), 26, 0.9)
	kit.deco(folder, Vector3.new(12, 2.4, 2.4), CFrame.new(c.X, 7, c.Z) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(170, 220, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
	for k = 1, 10 do
		local a = k / 10 * math.pi * 2 + 0.3
		palm(kit, folder, c + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(40, inner - 20) + Vector3.new(0, 0.2, 0))
	end
	if isl.id == "key" then
		local hp = c + Vector3.new(-inner * 0.55, 0, 0)
		kit.mk(folder, Vector3.new(1, 50, 50), CFrame.new(hp + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(40, 42, 48), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder, name = "Helipad" })
		kit.deco(folder, Vector3.new(0.1, 40, 40), CFrame.new(hp + Vector3.new(0, 1.02, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, transparency = 0.6 })
		local hLetter = kit.deco(folder, Vector3.new(16, 0.1, 22), CFrame.new(hp + Vector3.new(0, 1.06, 0)), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, { transparency = 1 })
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Top
		gui.CanvasSize = Vector2.new(160, 220)
		gui.LightInfluence = 1
		gui.Parent = hLetter
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "H"
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.fromRGB(240, 240, 240)
		t.Parent = gui
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			local l = kit.deco(folder, Vector3.one * 1.2, CFrame.new(hp + Vector3.new(math.cos(a) * 25, 1.2, math.sin(a) * 25)), Color3.fromRGB(80, 255, 140), Enum.Material.Neon, { shape = Enum.PartType.Ball })
			local _ = l
		end
	end
	-- the island's name on a lit stone wall where its road comes in
	local ja = joins[1]
	local out = Vector3.new(math.cos(ja), 0, math.sin(ja))
	local tangent = out:Cross(Vector3.yAxis)
	local sp = c + out * (ring + road / 2 + 30) + tangent * 34
	local wall = kit.mk(folder, Vector3.new(44, 9, 3), CFrame.lookAt(sp + Vector3.new(0, 4.5, 0), sp + Vector3.new(0, 4.5, 0) + tangent), STONE, Enum.Material.Limestone, { name = "IslandSign" })
	kit.surfaceText(wall, Enum.NormalId.Front, isl.name, Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
	kit.surfaceText(wall, Enum.NormalId.Back, isl.name, Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
	local lightPart = kit.deco(folder, Vector3.new(0.5, 0.5, 0.5), wall.CFrame * CFrame.new(0, -5, -3), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("SpotLight", lightPart, WARM, 24, 2, Enum.NormalId.Top, 80)
end

local function islands(kit: any, root: Instance)
	local folder = kit.folder("Islands", root)
	local key = W.Islands[1]
	local road = W.IslandRoad
	local j = CityLayout.HighwayJ
	local z0 = CityLayout.roadCoord(j)
	-- the causeway from Ocean Drive to Legends Key's ring road
	local a = Vector3.new(DT_WEST, 0, z0)
	local b = Vector3.new(WestLayout.CausewayEnd, 0, z0)
	local seaA = DT_WEST - W.BeachWest
	local seaB = (key.x + key.r) - WestLayout.CausewayEnd
	local cw = kit.folder("Causeway", folder)
	local lanes = C.LaneWidth * C.LanesPerSide
	seaRoad(kit, cw, a, b, lanes * 2 + 12, seaA, seaB, { -0.4, 0.4 })
	local joinsKey = { 0 }
	for k = 2, #W.Islands do
		local isl = W.Islands[k]
		local sgn = if isl.z < key.z then -1 else 1
		table.insert(joinsKey, sgn * math.pi / 2)
		local from = Vector3.new(key.x, 0, key.z + sgn * (key.ring + road / 2))
		local to = Vector3.new(isl.x, 0, isl.z - sgn * (isl.ring + road / 2))
		local bf = kit.folder("IslandBridge_" .. isl.id, folder)
		seaRoad(kit, bf, from, to, C.LaneWidth * 2 + 12, key.r - key.ring - road / 2, isl.r - isl.ring - road / 2, { 0 })
		island(kit, folder, isl, { -sgn * math.pi / 2 })
	end
	island(kit, folder, key, joinsKey)
end

---------------------------------------------------------------------
-- Boundaries
---------------------------------------------------------------------
local function walls(kit: any, root: Instance)
	local folder = kit.folder("WestBoundary", root)
	local x0, x1 = W.Canyon[1] + 20, W.SeaWest
	for _, s in { -1, 1 } do
		kit.slab(folder, x1, s * HALFZ - 2, x0, s * HALFZ + 2, 400, 400, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Boundary" })
	end
	kit.slab(folder, x1 - 2, -HALFZ, x1 + 2, HALFZ, 400, 400, Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Boundary" })
end

function West.build(kit: any, city: Instance)
	local root = kit.folder("West", city)
	highway(kit, root)
	canyon(kit, root)
	river(kit, root)
	bridge(kit, root)
	downtownGround(kit, root)
	beach(kit, root)
	islands(kit, root)
	walls(kit, root)
end

return West
