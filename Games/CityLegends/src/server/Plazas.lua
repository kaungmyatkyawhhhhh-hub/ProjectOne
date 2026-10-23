--[[
	Plazas (server)
	The landmark and venue blocks' empty grey ground (owner, 2026-10-23: "fill the gray block gaps
	out with something exciting"). Round each block's building there is a ring of open lot about
	36 studs wide; it gets warm stone paving and, in its corners and along its two street sides,
	things to see: food trucks with tables and string lights, an art ring, a basketball court,
	gardens with trees and benches, a big screen, kiosks. The middle of every side stays clear, so
	the entrances (bank steps, tower lobbies) are never in the way.

	Where each block's building stands (in 18-stud cells of its 216-stud lot, measured in a running
	game, venues included) is in FOOTPRINT. Customs and the dealership have drive-in bays all round
	and are left as they are.
]]

local Plazas = {}

local CELL = 18
local N = 12 -- cells along a lot side (216 / 18)

-- block "bi_bj" -> the building's cells { col0, row0, col1, row1 } (col along x, row along z)
Plazas.FOOTPRINT = {
	["2_2"] = { 2, 2, 9, 9 }, -- Legends Tower
	["3_2"] = { 4, 3, 8, 8 }, -- the Needle (the start block)
	["3_3"] = { 2, 2, 9, 9 }, -- Twist Tower
	["1_2"] = { 3, 2, 9, 9 }, -- the bank
	["2_3"] = { 3, 3, 11, 8 }, -- Aurum Residences
	["4_1"] = { 0, 3, 8, 8 }, -- Skyline One
	["1_4"] = { 3, 3, 11, 8 }, -- The Crown
}

local STONE = Color3.fromRGB(112, 104, 96)
local STONE_EDGE = Color3.fromRGB(150, 142, 130)
local METAL = Color3.fromRGB(46, 48, 54)
local WARM = Color3.fromRGB(255, 214, 160)
local TRUCK_COLORS = { Color3.fromRGB(236, 236, 230), Color3.fromRGB(150, 210, 190), Color3.fromRGB(244, 206, 96), Color3.fromRGB(196, 54, 48), Color3.fromRGB(70, 110, 170) }
local TRUCK_NAMES = { "TACO LEGENDS", "NIGHT BURGER", "BOBA BAR", "CITY COFFEE", "NOODLE BOX", "LATE WAFFLES" }
local KIOSKS = { "NEWS", "FLOWERS", "ICE CREAM", "SNEAKERS", "KEYS & PHONES", "HOT DOGS" }
local FLOWERS = { Color3.fromRGB(214, 60, 84), Color3.fromRGB(240, 196, 60), Color3.fromRGB(236, 120, 170), Color3.fromRGB(245, 245, 240) }

local up = CFrame.Angles(0, 0, math.pi / 2) -- a cylinder's axis is X: stand it up

-- a food truck facing `face` (its serving side), tables and parasols in front, string lights
local function foodTruck(kit: any, parent: Instance, c: Vector3, face: Vector3, k: number)
	local mk, deco, rng = kit.mk, kit.deco, kit.rng
	local base = CFrame.lookAt(c, c + face) -- -Z is the serving side
	local body = TRUCK_COLORS[k % #TRUCK_COLORS + 1]
	local truck = base * CFrame.new(0, 0, 5)
	mk(parent, Vector3.new(16, 7.5, 7), truck * CFrame.new(-1.5, 5.3, 0), body, Enum.Material.SmoothPlastic, { name = "FoodTruck" })
	mk(parent, Vector3.new(5, 5.5, 6.8), truck * CFrame.new(8.5, 4.3, 0), body:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.SmoothPlastic)
	deco(parent, Vector3.new(0.2, 2.2, 5.6), truck * CFrame.new(11.05, 5.4, 0), Color3.fromRGB(30, 40, 50), Enum.Material.Glass, { transparency = 0.2 })
	for _, x in { -6, 6.5 } do
		for _, z in { -3.3, 3.3 } do
			deco(parent, Vector3.new(1.2, 3, 3), truck * CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
		end
	end
	-- the serving window, its shelf, the awning and the name board on the roof
	deco(parent, Vector3.new(9, 3.2, 0.2), truck * CFrame.new(-1.5, 6, -3.55), Color3.fromRGB(40, 30, 24), Enum.Material.SmoothPlastic)
	local glow = deco(parent, Vector3.new(8.4, 2.6, 0.1), truck * CFrame.new(-1.5, 6, -3.6), WARM, Enum.Material.Neon, { transparency = 0.35 })
	kit.addLight("PointLight", glow, WARM, 18, 0.9)
	deco(parent, Vector3.new(9.6, 0.3, 1.4), truck * CFrame.new(-1.5, 4.3, -4.1), Color3.fromRGB(180, 180, 186), Enum.Material.Metal)
	deco(parent, Vector3.new(10.5, 0.25, 3), truck * CFrame.new(-1.5, 8.2, -4.6) * CFrame.Angles(math.rad(18), 0, 0), Color3.fromRGB(196, 54, 48):Lerp(body, 0.3), Enum.Material.Fabric, { shadow = true })
	local board = deco(parent, Vector3.new(12, 2.2, 0.3), truck * CFrame.new(-1.5, 10.2, -1), Color3.fromRGB(24, 22, 20), Enum.Material.SmoothPlastic)
	kit.surfaceText(board, Enum.NormalId.Front, TRUCK_NAMES[k % #TRUCK_NAMES + 1], Color3.fromRGB(255, 226, 170), Color3.fromRGB(24, 22, 20), 0, Enum.Font.GothamBlack, Vector2.new(600, 110))
	-- tables with parasols in front of the window
	for t = -1, 1 do
		local p = (base * CFrame.new(t * 9, 0, -7 - math.abs(t) * 1.5)).Position
		mk(parent, Vector3.new(0.4, 3.4, 3.4), CFrame.new(p + Vector3.new(0, 2.6, 0)) * up, Color3.fromRGB(230, 230, 226), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
		deco(parent, Vector3.new(2.6, 0.5, 0.5), CFrame.new(p + Vector3.new(0, 1.3, 0)) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		deco(parent, Vector3.new(6, 0.35, 0.35), CFrame.new(p + Vector3.new(0, 5.6, 0)) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		deco(parent, Vector3.new(0.3, 8, 8), CFrame.new(p + Vector3.new(0, 8.6, 0)) * up, FLOWERS[(k + t + 2) % #FLOWERS + 1], Enum.Material.Fabric, { shape = Enum.PartType.Cylinder, shadow = true })
		for s = 0, 2 do
			local a = s * 2.1 + rng:NextNumber(0, 0.4)
			deco(parent, Vector3.new(1.8, 1.4, 1.4), CFrame.new(p + Vector3.new(math.cos(a) * 2.8, 0.9, math.sin(a) * 2.8)) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		end
	end
	-- string lights on two posts over the tables
	local a = (base * CFrame.new(-14, 0, -6)).Position
	local b = (base * CFrame.new(14, 0, -6)).Position
	for _, p in { a, b } do
		deco(parent, Vector3.new(11, 0.4, 0.4), CFrame.new(p + Vector3.new(0, 5.5, 0)) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	end
	for i = 0, 10 do
		local t = i / 10
		local p = a:Lerp(b, t) + Vector3.new(0, 10.6 - math.sin(t * math.pi) * 1.6, 0)
		local bulb = deco(parent, Vector3.one * 0.55, CFrame.new(p), WARM, Enum.Material.Neon, { shape = Enum.PartType.Ball })
		kit.dayOff(bulb)
	end
end

-- a big brushed-metal ring standing on a plinth, lit from below, with cube seats round it
local function artRing(kit: any, parent: Instance, c: Vector3, face: Vector3)
	local mk, deco = kit.mk, kit.deco
	local base = CFrame.lookAt(c, c + face)
	mk(parent, Vector3.new(14, 1.4, 6), base * CFrame.new(0, 0.7, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Slate)
	local R = 8.5
	local segs = 18
	for i = 0, segs - 1 do
		local a = (i + 0.5) / segs * 2 * math.pi
		local p = base * CFrame.new(math.cos(a) * R, 1.4 + R + math.sin(a) * R, 0)
		deco(parent, Vector3.new(2 * math.pi * R / segs + 0.25, 1.6, 1.6), p * CFrame.Angles(0, 0, a + math.pi / 2), Color3.fromRGB(196, 198, 204), Enum.Material.Metal, { reflectance = 0.15, shadow = true })
	end
	for _, x in { -4, 4 } do
		local lamp = deco(parent, Vector3.new(1.2, 0.4, 1.2), base * CFrame.new(x, 1.6, -2), WARM, Enum.Material.Neon)
		kit.dayOff(lamp, kit.addLight("SpotLight", lamp, WARM, 26, 1.6, Enum.NormalId.Top, 60))
	end
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		mk(parent, Vector3.new(2.6, 2.2, 2.6), base * CFrame.new(math.cos(a) * 11, 1.1, math.sin(a) * 6 - 2) * CFrame.Angles(0, a, 0), Color3.fromRGB(220, 214, 204), Enum.Material.Limestone)
	end
end

-- a half basketball court with its hoop
local function court(kit: any, parent: Instance, c: Vector3, face: Vector3)
	local mk, deco = kit.mk, kit.deco
	local base = CFrame.lookAt(c, c + face)
	local S = 32
	deco(parent, Vector3.new(S, 0.12, S), base * CFrame.new(0, 0.12, 0), Color3.fromRGB(150, 72, 44), Enum.Material.SmoothPlastic)
	local WHITE = Color3.fromRGB(235, 235, 230)
	for _, l in { { 0, -S / 2 + 0.4, S - 0.8, 0.4 }, { 0, S / 2 - 0.4, S - 0.8, 0.4 }, { -S / 2 + 0.4, 0, 0.4, S - 0.8 }, { S / 2 - 0.4, 0, 0.4, S - 0.8 } } do
		deco(parent, Vector3.new(l[3], 0.14, l[4]), base * CFrame.new(l[1], 0.14, l[2]), WHITE, Enum.Material.SmoothPlastic)
	end
	-- the key and the free-throw line (the hoop is on the far side, +Z)
	deco(parent, Vector3.new(10, 0.15, 12), base * CFrame.new(0, 0.13, S / 2 - 6.4), Color3.fromRGB(120, 54, 34), Enum.Material.SmoothPlastic)
	deco(parent, Vector3.new(10, 0.16, 0.4), base * CFrame.new(0, 0.15, S / 2 - 12.4), WHITE, Enum.Material.SmoothPlastic)
	for i = 0, 11 do
		local a = math.pi * (i + 0.5) / 12
		deco(parent, Vector3.new(2.4, 0.16, 0.4), base * CFrame.new(math.cos(a) * 13, 0.15, S / 2 - 1.5 - math.sin(a) * 13) * CFrame.Angles(0, -(a + math.pi / 2), 0), WHITE, Enum.Material.SmoothPlastic)
	end
	-- the hoop: a post, an arm, the backboard and an orange rim
	local post = base * CFrame.new(0, 0, S / 2 + 1)
	mk(parent, Vector3.new(13, 0.8, 0.8), post * CFrame.new(0, 6.5, 0) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	deco(parent, Vector3.new(0.5, 0.5, 2.6), post * CFrame.new(0, 12.4, -1.3), METAL, Enum.Material.Metal)
	mk(parent, Vector3.new(6, 3.6, 0.25), post * CFrame.new(0, 12.6, -2.6), WHITE, Enum.Material.SmoothPlastic)
	deco(parent, Vector3.new(2, 1.4, 0.27), post * CFrame.new(0, 12, -2.62), Color3.fromRGB(200, 40, 40), Enum.Material.SmoothPlastic)
	for i = 0, 9 do
		local a = i / 10 * 2 * math.pi
		deco(parent, Vector3.new(0.5, 0.15, 0.15), post * CFrame.new(math.cos(a) * 0.9, 11.2, -3.8 + math.sin(a) * 0.9) * CFrame.Angles(0, -a + math.pi / 2, 0), Color3.fromRGB(240, 110, 30), Enum.Material.Metal)
	end
	deco(parent, Vector3.one * 1.6, base * CFrame.new(3, 0.9, 2), Color3.fromRGB(220, 100, 40), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
	-- two lamps over the court
	for _, x in { -S / 2 - 0.5, S / 2 + 0.5 } do
		local p = base * CFrame.new(x, 0, 0)
		mk(parent, Vector3.new(16, 0.5, 0.5), p * CFrame.new(0, 8, 0) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		local head = deco(parent, Vector3.new(2, 0.5, 2), p * CFrame.new(0, 16.2, 0), Color3.fromRGB(255, 244, 220), Enum.Material.Neon)
		kit.dayOff(head, kit.addLight("SpotLight", head, Color3.fromRGB(255, 240, 210), 40, 1.6, Enum.NormalId.Bottom, 100))
	end
end

-- two raised planters with trees, a flower bed and benches between them
local function garden(kit: any, parent: Instance, c: Vector3, face: Vector3)
	local mk, deco = kit.mk, kit.deco
	local base = CFrame.lookAt(c, c + face)
	for _, x in { -9, 9 } do
		local p = (base * CFrame.new(x, 0, 2)).Position
		mk(parent, Vector3.new(2, 11, 11), CFrame.new(p + Vector3.new(0, 1, 0)) * up, Color3.fromRGB(200, 192, 180), Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		deco(parent, Vector3.new(0.3, 10, 10), CFrame.new(p + Vector3.new(0, 2.05, 0)) * up, Color3.fromRGB(36, 58, 30), Enum.Material.LeafyGrass, { shape = Enum.PartType.Cylinder })
		kit.tree(parent, p + Vector3.new(0, 2, 0), 1.05)
	end
	-- flower bed in the middle
	local bed = (base * CFrame.new(0, 0, 2)).Position
	mk(parent, Vector3.new(6, 1.2, 4), CFrame.new(bed + Vector3.new(0, 0.6, 0)) * base.Rotation, Color3.fromRGB(200, 192, 180), Enum.Material.Limestone)
	for f = 1, 10 do
		deco(parent, Vector3.one * 0.9, CFrame.new(bed + base.Rotation * Vector3.new(-2.4 + (f % 5) * 1.2, 1.6, -1 + (f // 5) * 1.6)), FLOWERS[f % #FLOWERS + 1], Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
	end
	-- benches facing the street
	for _, x in { -6, 6 } do
		local bcf = base * CFrame.new(x, 0, -6)
		deco(parent, Vector3.new(6, 0.4, 1.8), bcf * CFrame.new(0, 1.6, 0), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks, { shadow = true })
		deco(parent, Vector3.new(6, 1.5, 0.3), bcf * CFrame.new(0, 2.6, 0.95), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks)
		for _, bx in { -2.4, 2.4 } do
			deco(parent, Vector3.new(0.3, 1.5, 1.8), bcf * CFrame.new(bx, 0.75, 0), METAL, Enum.Material.Metal)
		end
	end
end

-- a big screen on two posts, facing the street
local SCREEN_TEXTS = { "CITY LEGENDS\nCUT UP · GET PAID", "LEGENDS LOOP\n8 KM OF HIGHWAY", "LEGENDS MOTORS\nNEW ARRIVALS", "NIGHT RUN\nTONIGHT 22:00" }
local function screen(kit: any, parent: Instance, c: Vector3, face: Vector3, k: number)
	local mk, deco = kit.mk, kit.deco
	local base = CFrame.lookAt(c, c + face)
	for _, x in { -9, 9 } do
		mk(parent, Vector3.new(18, 1, 1), base * CFrame.new(x, 9, 2) * up, METAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	end
	mk(parent, Vector3.new(24, 12.5, 1), base * CFrame.new(0, 12.5, 2), Color3.fromRGB(20, 20, 24), Enum.Material.Metal)
	local panel = deco(parent, Vector3.new(23, 11.5, 0.2), base * CFrame.new(0, 12.5, 1.45), Color3.fromRGB(8, 10, 14), Enum.Material.SmoothPlastic)
	local _, frame = kit.surfaceText(panel, Enum.NormalId.Front, SCREEN_TEXTS[k % #SCREEN_TEXTS + 1], Color3.fromRGB(255, 236, 205), Color3.fromRGB(14, 18, 30), 0, Enum.Font.GothamBlack, Vector2.new(600, 300))
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(60, 40, 90), Color3.fromRGB(20, 40, 70))
	grad.Rotation = 35
	grad.Parent = frame
	kit.addLight("SurfaceLight", panel, Color3.fromRGB(200, 190, 255), 22, 0.8, Enum.NormalId.Front, 120)
	-- a low hedge in front so nobody drives into the posts
	deco(parent, Vector3.new(24, 2.4, 2.2), base * CFrame.new(0, 1.2, -1.5), Color3.fromRGB(44, 74, 38), Enum.Material.LeafyGrass, { shadow = true })
end

-- a small kiosk with a sign, benches and a bike rack beside it (the 36 x 18 side spots)
local function kiosk(kit: any, parent: Instance, c: Vector3, face: Vector3, k: number)
	local mk, deco = kit.mk, kit.deco
	local base = CFrame.lookAt(c, c + face)
	local col = TRUCK_COLORS[(k + 2) % #TRUCK_COLORS + 1]
	mk(parent, Vector3.new(8, 6.5, 6), base * CFrame.new(-6, 3.25, 1), col, Enum.Material.SmoothPlastic, { name = "Kiosk" })
	deco(parent, Vector3.new(9.4, 0.5, 7.6), base * CFrame.new(-6, 6.75, 0.4), Color3.fromRGB(34, 34, 38), Enum.Material.Metal, { shadow = true })
	local glow = deco(parent, Vector3.new(6, 2.4, 0.1), base * CFrame.new(-6, 3.6, -2.05), WARM, Enum.Material.Neon, { transparency = 0.4 })
	kit.addLight("PointLight", glow, WARM, 14, 0.8)
	local sign = deco(parent, Vector3.new(8, 1.6, 0.25), base * CFrame.new(-6, 7.9, -2.4), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic)
	kit.surfaceText(sign, Enum.NormalId.Front, KIOSKS[k % #KIOSKS + 1], Color3.fromRGB(255, 230, 180), Color3.fromRGB(20, 20, 22), 0, Enum.Font.GothamBlack, Vector2.new(500, 100))
	-- a bench and a bike rack
	local bcf = base * CFrame.new(6, 0, -1)
	deco(parent, Vector3.new(6, 0.4, 1.8), bcf * CFrame.new(0, 1.6, 0), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks, { shadow = true })
	deco(parent, Vector3.new(6, 1.5, 0.3), bcf * CFrame.new(0, 2.6, 0.95), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks)
	for i = 0, 3 do
		deco(parent, Vector3.new(0.25, 2.4, 2.6), base * CFrame.new(11 + i * 1.6, 1.2, 2), METAL, Enum.Material.Metal)
	end
	kit.tree(parent, (base * CFrame.new(15.5, 0, 4)).Position, 0.8)
end

local CORNER_THEMES = { foodTruck, artRing, court, garden, screen }

function Plazas.fill(kit: any, parent: Instance, bi: number, bj: number, cx: number, cz: number, lot: number, top: number)
	local fp = Plazas.FOOTPRINT[bi .. "_" .. bj]
	if not fp then
		return
	end
	local folder = kit.lodGroup(parent, "Plaza", Vector3.new(cx, top, cz), 700)
	local x0, z0 = cx - lot / 2, cz - lot / 2
	local function cellX(i: number): number
		return x0 + i * CELL
	end
	local function cellZ(i: number): number
		return z0 + i * CELL
	end
	-- paving round the building: warm stone with a lighter rim against the building
	local function pave(c0: number, r0: number, c1: number, r1: number)
		if c1 < c0 or r1 < r0 then
			return
		end
		local ax, bx = cellX(c0), cellX(c1 + 1)
		local az, bz = cellZ(r0), cellZ(r1 + 1)
		kit.mk(folder, Vector3.new(bx - ax, 0.12, bz - az), CFrame.new((ax + bx) / 2, top + 0.06, (az + bz) / 2), STONE, Enum.Material.Pavement, { name = "PlazaFloor" })
	end
	pave(0, 0, N - 1, fp[2] - 1)
	pave(0, fp[4] + 1, N - 1, N - 1)
	pave(0, fp[2], fp[1] - 1, fp[4])
	pave(fp[3] + 1, fp[2], N - 1, fp[4])
	-- a rim of lighter stone round the building's cells
	local rx0, rx1, rz0, rz1 = cellX(fp[1]), cellX(fp[3] + 1), cellZ(fp[2]), cellZ(fp[4] + 1)
	for _, e in { { rx0, rz0 - 0.6, rx1, rz0 }, { rx0, rz1, rx1, rz1 + 0.6 }, { rx0 - 0.6, rz0, rx0, rz1 }, { rx1, rz0, rx1 + 0.6, rz1 } } do
		if e[3] - e[1] > 0.1 and e[4] - e[2] > 0.1 then
			kit.deco(folder, Vector3.new(e[3] - e[1], 0.16, e[4] - e[2]), CFrame.new((e[1] + e[3]) / 2, top + 0.08, (e[2] + e[4]) / 2), STONE_EDGE, Enum.Material.Limestone)
		end
	end

	-- the corners (2 x 2 cells): a theme each, facing the nearer street along z
	local seed = bi * 7 + bj * 3
	local k = 0
	for _, corner in { { 0, 0 }, { N - 2, 0 }, { 0, N - 2 }, { N - 2, N - 2 } } do
		k += 1
		local c = Vector3.new(cellX(corner[1] + 1), top, cellZ(corner[2] + 1))
		local face = Vector3.new(0, 0, if corner[2] == 0 then -1 else 1)
		local theme = CORNER_THEMES[(seed + k) % #CORNER_THEMES + 1]
		theme(kit, folder, c, face, seed + k)
	end
	-- along both street sides (z), between the corners and the clear middle: kiosks and gardens
	for _, row in { 0, N - 1 } do
		for _, col in { 2, N - 4 } do
			k += 1
			local c = Vector3.new(cellX(col + 1), top, cellZ(row) + CELL / 2)
			local face = Vector3.new(0, 0, if row == 0 then -1 else 1)
			kiosk(kit, folder, c, face, seed + k)
		end
	end
end

return Plazas
