--[[
	Isle
	Builds Legends Isle (IsleLayout has the plan; owner, 2026-10-29: "one big island" with a big
	mountain, a sand beach all round, a real road winding up in switchbacks and three
	neighbourhoods by height).

	  * the island and the mountain are terrain only, written voxel by voxel from
	    IsleLayout.surface (so the ground sits exactly where it's asked: flat under every road,
	    terrace and lot), with grass, ground, rock and sand blended by slope and height, and the
	    sand running down under the sea
	  * the roads are parts like the city's: asphalt, a yellow centre line, white edge lines, kerbs
	    on the rings, guard rails and invisible walls along the climbs, lamps
	  * trees all over the slopes (pines up high, broadleaf trees and palms lower down), palms on
	    the beach, a pier on the west side, lifeguard towers and beach huts
	  * the low tier's sidewalk, mailboxes and street trees; the helipad and the lookout on top; the
	    fountain at the causeway's landing; the gate's guard house (Gate builds the barrier and
	    the guards at start)
	Built by West.build (in the scenery: baked into the place).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))
local ChallengeData = require(Shared:WaitForChild("ChallengeData"))

local Isle = {}
Isle.skipTerrain = false -- (the Lune map test can't make terrain)

local I = Config.West.Isle
local C = Config.City
local ROAD = IsleLayout.Road
local HALF = ROAD / 2
local CURB = C.CurbHeight

local rng = Random.new(20261029)

local STONE = Color3.fromRGB(196, 190, 178)
local KERB = Color3.fromRGB(200, 198, 190)
local RAIL = Color3.fromRGB(176, 180, 186)
local WOOD = Color3.fromRGB(126, 98, 70)
local WHITE = Color3.fromRGB(236, 234, 228)
local PINE = { Color3.fromRGB(34, 64, 40), Color3.fromRGB(42, 74, 46), Color3.fromRGB(30, 58, 38) }
local BARK = Color3.fromRGB(88, 66, 48)
local WARM = Color3.fromRGB(255, 196, 130)
local HUTS = { Color3.fromRGB(120, 196, 210), Color3.fromRGB(240, 150, 140), Color3.fromRGB(250, 214, 120), Color3.fromRGB(150, 210, 160) }

local CENTER = IsleLayout.Center
local UP = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's axis is X: stand it up

---------------------------------------------------------------------
-- Terrain: written from the height map in 128-stud columns
---------------------------------------------------------------------
local RES = 4
local HALF_SIZE = IsleLayout.MaxShore + 200

local function terrain(t: Terrain)
	local n = math.ceil(HALF_SIZE * 2 / RES)
	local x0 = math.floor((CENTER.X - HALF_SIZE) / RES) * RES
	local z0 = math.floor((CENTER.Z - HALF_SIZE) / RES) * RES
	-- the height of every column (cell centres)
	local H: { { number } } = table.create(n + 2)
	for i = 0, n + 1 do
		local row = table.create(n + 2, 0)
		local x = x0 + (i - 1) * RES + RES / 2 - CENTER.X
		for j = 0, n + 1 do
			row[j + 1] = IsleLayout.surface(x, z0 + (j - 1) * RES + RES / 2 - CENTER.Z)
		end
		H[i + 1] = row
		if i % 24 == 0 then
			task.wait()
		end
	end
	local function h(i: number, j: number): number
		return H[i + 1][j + 1]
	end
	local SEA = IsleLayout.SeaLevel
	local Mat = Enum.Material
	-- the surface material of a column: sand by the sea, rock where it's steep, grass on the gentle
	-- ground, with ground and leafy patches mixed in
	local function surfaceMat(i: number, j: number, y: number): Enum.Material
		local x = x0 + (i - 1) * RES + RES / 2
		local z = z0 + (j - 1) * RES + RES / 2
		local lx, lz = x - CENTER.X, z - CENTER.Z
		local r = math.sqrt(lx * lx + lz * lz)
		local s = math.max(math.abs(h(i + 1, j) - h(i - 1, j)), math.abs(h(i, j + 1) - h(i, j - 1))) / (RES * 2)
		local nz = math.noise(x / 60, z / 60, 3.3)
		if y < SEA or (y < 3 and r > IsleLayout.shore(math.atan2(lz, lx)) - 110) then
			return Mat.Sand
		elseif s < 0.22 then
			-- flat ground stays grass (with leafy patches)
			return if nz < -0.35 then Mat.LeafyGrass else Mat.Grass
		elseif s > 1.0 then
			return if nz > 0.25 then Mat.Slate else Mat.Rock -- bare cliffs
		elseif y > 380 then
			return if s > 0.4 or nz > 0 then Mat.Rock else Mat.Ground -- the bare top
		elseif y > 200 then
			if s > 0.5 then
				return if nz > 0.3 then Mat.Slate else Mat.Rock
			end
			return if nz > -0.1 then Mat.Ground else Mat.Rock
		elseif y > 60 then
			if s > 0.6 then
				return Mat.Rock
			elseif s > 0.4 then
				return if nz > 0 then Mat.Ground else Mat.Grass
			end
			return if nz < -0.3 then Mat.LeafyGrass else Mat.Grass
		end
		if s > 0.7 then
			return Mat.Rock
		end
		return if nz < -0.35 then Mat.LeafyGrass else Mat.Grass
	end
	local CH = 32 -- columns per chunk side
	local yLow = -24
	for ci = 1, n, CH do
		for cj = 1, n, CH do
			local ni, nj = math.min(CH, n - ci + 1), math.min(CH, n - cj + 1)
			-- (chunks out in the open sea are left as they are)
			local cxm = x0 + (ci - 1 + ni / 2) * RES - CENTER.X
			local czm = z0 + (cj - 1 + nj / 2) * RES - CENTER.Z
			if math.sqrt(cxm * cxm + czm * czm) - CH * RES * 0.71 < IsleLayout.MaxShore + 160 then
				local top = SEA
				for i = ci, ci + ni - 1 do
					for j = cj, cj + nj - 1 do
						top = math.max(top, h(i, j))
					end
				end
				local ny = math.ceil((top + 8 - yLow) / RES)
				local mats = table.create(ni)
				local occ = table.create(ni)
				for a = 1, ni do
					local i = ci + a - 1
					local mcol = table.create(ny)
					local ocol = table.create(ny)
					for b = 1, ny do
						mcol[b] = table.create(nj, Mat.Air)
						ocol[b] = table.create(nj, 0)
					end
					for c = 1, nj do
						local j = cj + c - 1
						local y = h(i, j)
						local surf = surfaceMat(i, j, y)
						-- (Roblox draws the surface about half a cell above where the occupancy
						-- says: measured 2 studs on flat ground, so it's asked for 2 lower)
						y -= 2
						local deep = if surf == Mat.Sand then Mat.Sand else Mat.Rock
						for b = 1, ny do
							local yb = yLow + (b - 1) * RES
							local o = math.clamp((y - yb) / RES, 0, 1)
							if o > 0 then
								mcol[b][c] = if yb + RES >= y - 6 then surf else deep
								ocol[b][c] = o
							elseif yb < SEA then
								mcol[b][c] = Mat.Water
								ocol[b][c] = math.clamp((SEA - yb) / RES, 0, 1)
							end
						end
					end
					mats[a] = mcol
					occ[a] = ocol
				end
				local lo = Vector3.new(x0 + (ci - 1) * RES, yLow, z0 + (cj - 1) * RES)
				local region = Region3.new(lo, lo + Vector3.new(ni * RES, ny * RES, nj * RES))
				t:WriteVoxels(region, RES, mats, occ)
				task.wait()
			end
		end
	end
end

---------------------------------------------------------------------
-- Road parts
---------------------------------------------------------------------
-- a straight road piece from a to b (surface points), with its markings
local function roadPiece(kit: any, parent: Instance, a: Vector3, b: Vector3, opts: { centre: boolean, edges: boolean, extra: number? })
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local extra = opts.extra or 2
	kit.mk(parent, Vector3.new(ROAD, 2, len + extra), cf * CFrame.new(0, -1, 0), kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
	if opts.centre then
		kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(-0.3, 0.02, 0), kit.LINE_YELLOW, Enum.Material.SmoothPlastic)
		kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(0.3, 0.02, 0), kit.LINE_YELLOW, Enum.Material.SmoothPlastic)
	end
	if opts.edges then
		for _, s in { -1, 1 } do
			kit.deco(parent, Vector3.new(0.35, 0.05, len), cf * CFrame.new(s * (HALF - 1.4), 0.02, 0), kit.LINE_WHITE, Enum.Material.SmoothPlastic)
		end
	end
end

-- a ring road: pieces round the circle, kerbs (open at the junctions), lamps outside
local function ringRoad(kit: any, parent: Instance, ring: IsleLayout.Ring)
	local folder = kit.folder("Ring_" .. ring.id, parent)
	local joins = IsleLayout.joins(ring.id)
	local n = math.clamp(math.floor(ring.radius * 2 * math.pi / 40), 64, 180)
	local function inGap(a: number, extra: number): boolean
		for _, j in joins do
			if IsleLayout.angDiff(a, j.angle) < j.gap + extra then
				return true
			end
		end
		return false
	end
	local lampEvery = math.max(2, math.floor(n / 28))
	for k = 0, n - 1 do
		local a0, a1 = k / n * math.pi * 2, (k + 1) / n * math.pi * 2
		local p0 = IsleLayout.polar(ring.radius, a0, ring.y)
		local p1 = IsleLayout.polar(ring.radius, a1, ring.y)
		local am = (a0 + a1) / 2
		roadPiece(kit, folder, p0, p1, { centre = k % 2 == 0, edges = not inGap(am, 0) })
		local cf = CFrame.lookAt((p0 + p1) / 2, p1)
		local len = (p1 - p0).Magnitude
		if not inGap(am, 0.01) then
			for _, s in { -1, 1 } do
				kit.mk(folder, Vector3.new(1, CURB, len + 1), cf * CFrame.new(s * (HALF + 0.5), CURB / 2, 0), KERB, Enum.Material.Concrete, { name = "Kerb" })
			end
		end
		if k % lampEvery == 0 and not inGap(am, 0.03) then
			local out = Vector3.new(math.cos(am), 0, math.sin(am))
			kit.streetLight(folder, IsleLayout.polar(ring.radius + HALF + 2, am, ring.y), -out)
		end
	end
end

-- a flat triangle of road (a, b, c at the same height: the surface), as two wedges
local function flatTriangle(kit: any, parent: Instance, a: Vector3, b: Vector3, c: Vector3)
	-- split at the foot of the height from a, so each half has its right angle there
	local bc = c - b
	local m = b + bc * math.clamp((a - b):Dot(bc) / bc:Dot(bc), 0, 1)
	for _, far in { b, c } do
		local ey, ez = a - m, far - m
		local h, l = ey.Magnitude, ez.Magnitude
		if h > 0.05 and l > 0.05 then
			-- WedgePart: right angle at local (y -h/2, z +l/2); its x is the thickness (vertical here)
			local y, z = ey.Unit, -ez.Unit
			local cf = CFrame.fromMatrix(m + ey / 2 + ez / 2 - Vector3.new(0, 1, 0), y:Cross(z), y, z)
			kit.mk(parent, Vector3.new(2, h, l), cf, kit.ASPHALT, kit.ROAD_MAT, { class = "Wedge", reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		end
	end
end

-- rebuild just the climbs (in Studio, on a built island): Isle.rebuildClimbs(CityBuilder.kit, isleFolder)
local climb: (any, Instance, IsleLayout.Road) -> ()

-- a climb: each leg in pieces following its slope, flat triangles closing the outside of each
-- bend, one level pad per hairpin, guard rails and invisible walls along the sides, lamps.
-- (owner, 2026-10-29: the car jerked going up and down. The hairpin pads reached 23 studs into
-- the legs, which only stay level for 14, so their edge stood a stud above the road; and pieces
-- stretched past the bends overlapped at different heights. Now every join is flush.)
function climb(kit: any, parent: Instance, rd: IsleLayout.Road)
	local folder = kit.folder("Road_" .. rd.id, parent)
	local pts = rd.pts
	local lampAt = 0
	local function isHairpin(q: number): boolean
		return q > 1 and q < #pts and IsleLayout.turnAt(pts, q) > 1
	end
	for k = 1, #pts - 1 do
		local a, b = pts[k], pts[k + 1]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local len = flat.Magnitude
		local dir = flat.Unit
		local side = dir:Cross(Vector3.yAxis)
		local f0, f1 = rd.level[k], rd.level[k + 1]
		local function at(d: number, off: number?): Vector3
			local p = a + dir * d + side * (off or 0)
			return Vector3.new(p.X, IsleLayout.legY(a.Y, b.Y, len, d, f0, f1), p.Z)
		end
		-- cut where the level ends begin and end, so each piece is wholly level or wholly on the
		-- slope (one piece across both sagged below the level end and left a ledge)
		local fl0, fl1 = IsleLayout.flats(a.Y, b.Y, f0, f1)
		if len <= fl0 + fl1 + 1 then
			fl0, fl1 = 0, 0
		end
		local cuts = { 0 }
		if fl0 > 0 then
			table.insert(cuts, fl0)
		end
		local s0, s1 = fl0, len - fl1
		local nPieces = math.max(1, math.ceil((s1 - s0) / 30))
		for q = 1, nPieces - 1 do
			table.insert(cuts, s0 + (s1 - s0) * q / nPieces)
		end
		if fl1 > 0 then
			table.insert(cuts, s1)
		end
		table.insert(cuts, len)
		local detail = kit.lodGroup(folder, "Detail", (a + b) / 2, 700 + len / 2)
		for q = 1, #cuts - 1 do
			local d0, d1 = cuts[q], cuts[q + 1]
			local p0, p1 = at(d0), at(d1)
			-- (a sliver of overlap: more would stand above the next piece, which climbs another way)
			roadPiece(kit, folder, p0, p1, { centre = true, edges = true, extra = 0.4 })
			-- rails and walls along the sides, not across the stubs at the rings or the hairpins
			local nearHairpin = (q == 1 and f0) or (q == #cuts - 1 and f1)
			local atRing = k == 1 or k == #pts - 1
			if rd.rails and not nearHairpin and not atRing then
				local cf = CFrame.lookAt((p0 + p1) / 2, p1)
				local plen = (p1 - p0).Magnitude
				for _, s in { -1, 1 } do
					kit.mk(folder, Vector3.new(0.5, 0.9, plen + 0.2), cf * CFrame.new(s * (HALF + 1), 2.2, 0), RAIL, Enum.Material.Metal, { name = "Rail" })
					kit.mk(folder, Vector3.new(1, 30, plen), cf * CFrame.new(s * (HALF + 1.6), 15, 0), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "Wall" })
					local posts = math.max(1, math.floor(plen / 16))
					for pp = 0, posts - 1 do
						kit.deco(detail, Vector3.new(0.5, 2.4, 0.5), cf * CFrame.new(s * (HALF + 1), 1.2, -plen / 2 + (pp + 0.5) * plen / posts), RAIL, Enum.Material.Metal)
					end
				end
			end
		end
		-- lamps every ~110 studs, on the outside of the mountain
		lampAt += len
		if lampAt > 110 and len > 20 then
			lampAt = 0
			local mid = at(len / 2)
			local outward = Vector3.new(mid.X - CENTER.X, 0, mid.Z - CENTER.Z).Unit
			local s = if side:Dot(outward) > 0 then 1 else -1
			kit.streetLight(detail, at(len / 2, s * (HALF + 2.5)), -side * s)
		end
	end
	for k = 2, #pts - 1 do
		local p = pts[k]
		local prev, nxt = pts[k - 1], pts[k + 1]
		local dirA = Vector3.new(p.X - prev.X, 0, p.Z - prev.Z).Unit
		local dirB = Vector3.new(nxt.X - p.X, 0, nxt.Z - p.Z).Unit
		if isHairpin(k) then
			-- one level pad, square to the level leg (the short run between the two hairpins). It
			-- reaches into the sloped leg only as far as that stays level (Flat, less a little for
			-- the leg's angle), so its edge never stands above the road
			local levelIsB = math.abs(nxt.Y - p.Y) < 0.01
			local v = if levelIsB then dirB else -dirA -- along the level leg, away from the corner
			local u = if levelIsB then -dirA else dirB -- into the sloped leg
			local across = v:Cross(Vector3.yAxis)
			if across:Dot(u) < 0 then
				across = -across
			end
			local back, fwd = HALF + 3, IsleLayout.Flat - 2
			local along = HALF + 3
			local centre = Vector3.new(p.X, p.Y - 1.02, p.Z) + across * ((fwd - back) / 2)
			kit.mk(folder, Vector3.new(back + fwd, 2, 2 * along), CFrame.fromMatrix(centre, across, Vector3.yAxis, across:Cross(Vector3.yAxis)), kit.ASPHALT, kit.ROAD_MAT, { reflectance = kit.ROAD_OPTS.reflectance, name = "Road" })
		else
			-- a bend: close the outside with a flat triangle at the corner's height (both legs'
			-- end edges are level there)
			local turn = dirA:Cross(dirB).Y
			if math.abs(turn) > 0.001 then
				local sideA, sideB = dirA:Cross(Vector3.yAxis), dirB:Cross(Vector3.yAxis)
				local s = if (sideB - sideA):Dot(dirA) > 0 then 1 else -1
				flatTriangle(kit, folder, p, p + sideA * s * HALF, p + sideB * s * HALF)
			end
		end
	end
end

---------------------------------------------------------------------
-- Scenery
---------------------------------------------------------------------
local function pine(kit: any, parent: Instance, pos: Vector3)
	local h = rng:NextNumber(20, 34)
	kit.deco(parent, Vector3.new(h * 0.5, 1.4, 1.4), CFrame.new(pos + Vector3.new(0, h * 0.25, 0)) * UP, BARK, Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
	local green = PINE[rng:NextInteger(1, #PINE)]
	for q = 0, 2 do
		local w = (h * 0.42) * (1 - q * 0.28)
		kit.deco(parent, Vector3.new(h * 0.26, w, w), CFrame.new(pos + Vector3.new(0, h * (0.35 + q * 0.22), 0)) * UP, green, Enum.Material.LeafyGrass, { shape = Enum.PartType.Cylinder, shadow = true })
	end
end

local function lifeguardTower(kit: any, parent: Instance, pos: Vector3, face: Vector3)
	local cf = CFrame.lookAt(pos, pos + face)
	for _, sx in { -3, 3 } do
		for _, sz in { -3, 3 } do
			kit.mk(parent, Vector3.new(0.6, 9, 0.6), cf * CFrame.new(sx, 4.5, sz), WHITE, Enum.Material.Wood)
		end
	end
	kit.mk(parent, Vector3.new(8, 0.6, 8), cf * CFrame.new(0, 9, 0), WOOD, Enum.Material.WoodPlanks)
	kit.mk(parent, Vector3.new(7, 5, 7), cf * CFrame.new(0, 11.8, 0), Color3.fromRGB(230, 90, 70), Enum.Material.SmoothPlastic, { name = "LifeguardHut" })
	kit.mk(parent, Vector3.new(9, 0.5, 9), cf * CFrame.new(0, 14.6, 0), WHITE, Enum.Material.SmoothPlastic)
	kit.mk(parent, Vector3.new(3, 0.4, 8), cf * CFrame.new(0, 4.5, -7) * CFrame.Angles(math.rad(-50), 0, 0), WOOD, Enum.Material.WoodPlanks)
end

local function beachHut(kit: any, parent: Instance, pos: Vector3, face: Vector3)
	local cf = CFrame.lookAt(pos, pos + face)
	local col = HUTS[rng:NextInteger(1, #HUTS)]
	kit.mk(parent, Vector3.new(8, 7, 7), cf * CFrame.new(0, 3.5, 0), col, Enum.Material.WoodPlanks, { name = "BeachHut" })
	kit.mk(parent, Vector3.new(9, 2, 8), cf * CFrame.new(0, 8, 0), WHITE, Enum.Material.WoodPlanks, { class = "Wedge" })
	kit.deco(parent, Vector3.new(3, 5, 0.2), cf * CFrame.new(0, 2.5, -3.6), Color3.fromRGB(70, 60, 50), Enum.Material.Wood)
end

local function pier(kit: any, parent: Instance, from: Vector3, dir: Vector3, len: number)
	local cf = CFrame.lookAt(from, from + dir)
	kit.mk(parent, Vector3.new(14, 1, len), cf * CFrame.new(0, 1.5, -len / 2), WOOD, Enum.Material.WoodPlanks, { name = "Pier" })
	local n = math.floor(len / 20)
	for k = 0, n do
		for _, sx in { -6, 6 } do
			kit.mk(parent, Vector3.new(1.2, 16, 1.2), cf * CFrame.new(sx, -6, -k * len / n), WOOD, Enum.Material.Wood)
		end
	end
	for _, sx in { -6.6, 6.6 } do
		kit.mk(parent, Vector3.new(0.3, 3, len), cf * CFrame.new(sx, 3.5, -len / 2), WOOD, Enum.Material.Wood, { name = "Rail" })
	end
	kit.mk(parent, Vector3.new(44, 1, 14), cf * CFrame.new(0, 1.5, -len - 6), WOOD, Enum.Material.WoodPlanks, { name = "Pier" })
	for _, sx in { -18, 18 } do
		local base = (cf * CFrame.new(sx, 2, -len - 6)).Position
		kit.mk(parent, Vector3.new(10, 0.5, 0.5), CFrame.new(base + Vector3.new(0, 5, 0)) * UP, Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		local lamp = kit.deco(parent, Vector3.one * 1.4, CFrame.new(base + Vector3.new(0, 10.6, 0)), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		kit.dayOff(lamp, kit.addLight("PointLight", lamp, WARM, 30, 1.4))
	end
end

local function fountain(kit: any, parent: Instance, p: Vector3)
	kit.mk(parent, Vector3.new(80, 0.4, 80), CFrame.new(p + Vector3.new(0, 0.2, 0)), Color3.fromRGB(184, 178, 166), Enum.Material.Limestone, { name = "Plaza" })
	kit.mk(parent, Vector3.new(1.4, 36, 36), CFrame.new(p + Vector3.new(0, 1.1, 0)) * UP, STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local water = kit.deco(parent, Vector3.new(0.4, 31, 31), CFrame.new(p + Vector3.new(0, 1.7, 0)) * UP, Color3.fromRGB(60, 170, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.45 })
	kit.addLight("PointLight", water, Color3.fromRGB(80, 170, 255), 26, 0.9)
	kit.mk(parent, Vector3.new(6, 4, 4), CFrame.new(p + Vector3.new(0, 4, 0)) * UP, STONE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	kit.deco(parent, Vector3.new(12, 2.4, 2.4), CFrame.new(p + Vector3.new(0, 9, 0)) * UP, Color3.fromRGB(170, 220, 255), Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
end

local function helipad(kit: any, parent: Instance, p: Vector3)
	kit.mk(parent, Vector3.new(1, 54, 54), CFrame.new(p + Vector3.new(0, 0.5, 0)) * UP, Color3.fromRGB(40, 42, 48), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder, name = "Helipad" })
	kit.deco(parent, Vector3.new(0.1, 44, 44), CFrame.new(p + Vector3.new(0, 1.02, 0)) * UP, Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, transparency = 0.6 })
	local h = kit.deco(parent, Vector3.new(16, 0.1, 22), CFrame.new(p + Vector3.new(0, 1.06, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(160, 220)
	gui.LightInfluence = 1
	gui.Parent = h
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
		kit.deco(parent, Vector3.one * 1.2, CFrame.new(p + Vector3.new(math.cos(a) * 25, 1.2, math.sin(a) * 25)), Color3.fromRGB(80, 255, 140), Enum.Material.Neon, { shape = Enum.PartType.Ball })
	end
end

local function lookout(kit: any, parent: Instance, p: Vector3)
	-- a stone deck at the top's edge looking back over the bay to Downtown (east)
	local face = Vector3.new(p.X - CENTER.X, 0, p.Z - CENTER.Z).Unit
	local cf = CFrame.lookAt(p, p + face)
	kit.mk(parent, Vector3.new(60, 1, 40), cf * CFrame.new(0, 0.5, -6), STONE, Enum.Material.Limestone, { name = "Lookout" })
	for _, sx in { -30, 30 } do
		kit.mk(parent, Vector3.new(1, 3.4, 40), cf * CFrame.new(sx, 2.7, -6), STONE, Enum.Material.Limestone)
	end
	kit.mk(parent, Vector3.new(60, 3.4, 1), cf * CFrame.new(0, 2.7, -26), STONE, Enum.Material.Limestone, { name = "LookoutWall" })
	for _, sx in { -12, 12 } do
		kit.mk(parent, Vector3.new(0.4, 3, 0.4), cf * CFrame.new(sx, 2.5, -22), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
		kit.mk(parent, Vector3.new(0.8, 0.8, 3), cf * CFrame.new(sx, 4.2, -22.4) * CFrame.Angles(math.rad(8), 0, 0), Color3.fromRGB(180, 150, 80), Enum.Material.Metal, { name = "Telescope" })
	end
end

-- the gate's guard house and pillars (Gate adds the barrier arm and the guards at start)
local function gateHouse(kit: any, parent: Instance)
	local g = IsleLayout.GateCFrame
	local folder = kit.folder("Gate", parent)
	for _, s in { -1, 1 } do
		kit.mk(folder, Vector3.new(4, 12, 4), g * CFrame.new(s * (HALF + 3), 6, 0), STONE, Enum.Material.Limestone, { name = "GatePillar" })
		kit.deco(folder, Vector3.new(4.6, 1, 4.6), g * CFrame.new(s * (HALF + 3), 12.5, 0), Color3.fromRGB(180, 150, 90), Enum.Material.Metal)
		local lamp = kit.deco(folder, Vector3.one * 1.6, g * CFrame.new(s * (HALF + 3), 13.8, 0), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		kit.dayOff(lamp, kit.addLight("PointLight", lamp, WARM, 28, 1.3))
	end
	-- the guard house, left of the road coming in
	local h = g * CFrame.new(-(HALF + 13), 0, 6)
	kit.mk(folder, Vector3.new(14, 0.6, 12), h * CFrame.new(0, 0.3, 0), STONE, Enum.Material.Limestone)
	kit.mk(folder, Vector3.new(12, 9, 0.6), h * CFrame.new(0, 5, 5.7), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.6, 9, 12), h * CFrame.new(-5.7, 5, 0), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.6, 3, 12), h * CFrame.new(5.7, 2, 0), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(0.3, 5, 11), h * CFrame.new(5.7, 6, 0), Color3.fromRGB(150, 190, 210), Enum.Material.Glass, { transparency = 0.5, name = "GuardWindow" })
	kit.mk(folder, Vector3.new(12, 0.6, 0.6), h * CFrame.new(0, 2, -5.7), WHITE, Enum.Material.SmoothPlastic, { name = "GuardHouse" })
	kit.mk(folder, Vector3.new(16, 1, 14), h * CFrame.new(0, 10, 0), Color3.fromRGB(40, 42, 48), Enum.Material.Metal, { name = "GuardRoof" })
	local light = kit.deco(folder, Vector3.new(6, 0.2, 2), h * CFrame.new(0, 9.4, 0), WARM, Enum.Material.Neon)
	kit.dayOff(light, kit.addLight("PointLight", light, WARM, 22, 1.2))
	local sign = kit.mk(folder, Vector3.new(30, 4, 1), g * CFrame.new(-(HALF + 26), 3, -4) * CFrame.Angles(0, math.pi / 2, 0), STONE, Enum.Material.Limestone, { name = "GateSign" })
	kit.surfaceText(sign, Enum.NormalId.Front, "THE SUMMIT · RESIDENTS ONLY", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 120))
	kit.surfaceText(sign, Enum.NormalId.Back, "THE SUMMIT · RESIDENTS ONLY", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 120))
end

-- the low tier's street: a sidewalk inside the ring, a mailbox and a street tree at every lot
local function lowStreet(kit: any, parent: Instance, lots: { IsleLayout.Lot })
	local folder = kit.folder("LowStreet", parent)
	for _, l in lots do
		if l.zone == "low" then
			local f = l.frame
			local front = f * CFrame.new(0, 0, -l.depth / 2 - 4)
			kit.mk(folder, Vector3.new(l.width + 14, 0.4, 8), front * CFrame.new(0, 0.2, 0), kit.SIDEWALK, Enum.Material.Concrete, { name = "Sidewalk" })
			kit.mk(folder, Vector3.new(0.3, 3.4, 0.3), front * CFrame.new(l.width / 2 - 6, 2.1, 2.5), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
			kit.mk(folder, Vector3.new(1.2, 1, 1.8), front * CFrame.new(l.width / 2 - 6, 4.2, 2.5), Color3.fromRGB(40, 70, 130), Enum.Material.Metal, { name = "Mailbox" })
			kit.tree(folder, (front * CFrame.new(-l.width / 2 + 4, 0.4, 1)).Position, 0.8)
		end
	end
end

-- trees: a forest on the lower slopes, fewer higher up, none on the cliffs
local function trees(kit: any, parent: Instance, palm: (any, Instance, Vector3, number?) -> Vector3)
	local folder = kit.folder("Trees", parent)
	local placed = 0
	for _ = 1, 6000 do
		if placed >= 640 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(60, I.Ring - HALF - 16)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if not IsleLayout.inZone(x, z, 12) then
			local y = IsleLayout.surface(x, z)
			local s = math.max(math.abs(IsleLayout.surface(x + 4, z) - IsleLayout.surface(x - 4, z)), math.abs(IsleLayout.surface(x, z + 4) - IsleLayout.surface(x, z - 4))) / 8
			local keep = if y < 160 then 1 elseif y < 280 then 0.35 else 0.1
			local clearRamps = true
			for _, rp in ChallengeData.ramps do
				if (Vector3.new(CENTER.X + x, 0, CENTER.Z + z) - Vector3.new(rp.cf.X, 0, rp.cf.Z)).Magnitude < 90 then
					clearRamps = false
				end
			end
			if s < 0.8 and y > 2 and clearRamps and rng:NextNumber() < keep then
				placed += 1
				local p = CENTER + Vector3.new(x, y - 0.6, z)
				local group = kit.lodGroup(folder, "Detail", p, 1000)
				local pick = rng:NextNumber()
				if y > 180 or (y > 50 and pick < 0.55) then
					pine(kit, group, p)
				elseif y > 15 or pick < 0.5 then
					kit.tree(group, p, rng:NextNumber(1.1, 1.6))
				else
					palm(kit, group, p)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- The build
---------------------------------------------------------------------
function Isle.rebuildClimbs(kit: any, isle: Instance)
	for _, rd in IsleLayout.Roads do
		local old = isle:FindFirstChild("Road_" .. rd.id)
		if old then
			old:Destroy()
		end
		climb(kit, isle, rd)
	end
end

function Isle.build(kit: any, parent: Instance, palm: (any, Instance, Vector3, number?) -> Vector3)
	local folder = kit.folder("LegendsIsle", parent)
	if not Isle.skipTerrain then
		terrain(workspace.Terrain)
	end
	for _, ring in IsleLayout.Rings do
		ringRoad(kit, folder, ring)
	end
	for _, rd in IsleLayout.Roads do
		climb(kit, folder, rd)
	end

	local lots = IsleLayout.lots()
	-- the beach: palms along the top of the sand, lifeguard towers and huts on the west and
	-- south, the pier
	local beach = kit.folder("Beach", folder)
	local nb = 72
	for k = 0, nb - 1 do
		local a = (k + rng:NextNumber(-0.3, 0.3)) / nb * math.pi * 2
		local r = IsleLayout.shore(a) - rng:NextNumber(96, 120)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if IsleLayout.angDiff(a, 0) > 0.1 and not IsleLayout.inZone(x, z, 8) then
			palm(kit, beach, CENTER + Vector3.new(x, IsleLayout.surface(x, z) - 0.5, z))
		end
	end
	local function onSand(r: number, a: number): Vector3
		r += IsleLayout.shore(a) - I.r
		local x, z = math.cos(a) * r, math.sin(a) * r
		return CENTER + Vector3.new(x, IsleLayout.surface(x, z), z)
	end
	for _, a in { math.pi * 0.85, math.pi, math.pi * 1.15, math.pi * 0.5, math.pi * 0.62 } do
		local p = onSand(I.r - 55, a)
		lifeguardTower(kit, beach, p, (p - CENTER) * Vector3.new(1, 0, 1))
	end
	for k = 0, 7 do
		local p = onSand(I.r - 80, math.pi * 0.7 + k * 0.07)
		beachHut(kit, beach, p, (p - CENTER) * Vector3.new(1, 0, 1))
	end
	pier(kit, beach, IsleLayout.polar(IsleLayout.shore(math.pi) - 40, math.pi, 0.4), Vector3.new(-1, 0, 0), 220)

	trees(kit, folder, palm)
	lowStreet(kit, folder, lots)
	fountain(kit, folder, IsleLayout.fountain())
	helipad(kit, folder, IsleLayout.helipad())
	lookout(kit, folder, IsleLayout.lookout())
	gateHouse(kit, folder)
	-- the island's name where the causeway lands
	local sp = IsleLayout.polar(I.Ring + HALF + 40, 0.075, 0)
	local wall = kit.mk(folder, Vector3.new(50, 9, 3), CFrame.lookAt(sp + Vector3.new(0, 4.5, 0), sp + Vector3.new(0, 4.5, 0) + Vector3.new(0, 0, 1)), STONE, Enum.Material.Limestone, { name = "IslandSign" })
	kit.surfaceText(wall, Enum.NormalId.Front, "LEGENDS ISLE", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
	kit.surfaceText(wall, Enum.NormalId.Back, "LEGENDS ISLE", Color3.fromRGB(255, 214, 140), nil, nil, Enum.Font.GothamBlack, Vector2.new(900, 170))
end

return Isle
