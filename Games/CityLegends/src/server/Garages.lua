--[[
	Garages (server)
	Underground parking for the luxury towers (owner, 2026-10-23: "for hotels and luxury areas that
	usually have parkings add basement parking under ground garage that you can go down actually and
	also parking on the entrance").

	Behind each tower (the side away from its entrance) a driveway leaves the street over a lowered
	kerb onto an apron. Beside the apron is a small marked surface lot (the entrance parking); ahead
	a ramp runs down a walled, railed well through the ground slab into a basement deck under the
	whole lot: concrete floor and walls, pillars, painted bays and aisles, strip lights, signs. You
	can drive (or walk) down, park and come back up the same ramp.

	Every basement bay gets an invisible "ParkBay" marker (facing out of the bay) and every entrance
	bay a "VipBay" marker the size of the bay: Parking (the server) puts parked cars you can steal in
	the first and charges for the second.

	The city's ground is one 4-stud asphalt slab with nothing under it, and each block has one
	sidewalk slab; both are cut round the ramp well and the lowered kerb (cut() splits a slab into
	the pieces round a hole). Plazas leaves the garage's corner and side alone (Garages.SIDE).
]]

local Garages = {}

-- the towers' blocks -> which side of the lot the garage opens on (-1: -x, 1: +x), behind the tower
Garages.SIDE = {
	["2_3"] = -1, -- Aurum Residences (entrance faces +x)
	["1_4"] = -1, -- The Crown (entrance faces +x)
	["4_1"] = 1, -- Skyline One (entrance faces -x)
}

local FLOOR = -16 -- the basement floor's top
local CEIL = -4 -- the ground slab's underside
local HALF = 104 -- the basement reaches this far from the block's middle (inside the 108 lot)
local RAMP_IN, RAMP_OUT = 78, 102 -- the ramp well across the lot (from the block's middle, on its side)
local RAMP_Z0, RAMP_Z1 = -50, 50 -- the well along z (the top end is the apron's)
local APRON_Z0, APRON_Z1 = -72, -50 -- the driveway and apron along z
local CONCRETE = Color3.fromRGB(118, 116, 112)
local CONCRETE_DARK = Color3.fromRGB(84, 82, 80)
local YELLOW = Color3.fromRGB(240, 196, 40)
local WHITE = Color3.fromRGB(232, 232, 228)
local BLUE = Color3.fromRGB(30, 90, 190)
local TUBE = Color3.fromRGB(236, 244, 255)

-- an invisible marker the parking script finds (its size is the bay's)
local function marker(parent: Instance, name: string, cf: CFrame, size: Vector3)
	local m = Instance.new("Part")
	m.Name = name
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.Transparency = 1
	m.Size = size
	m.CFrame = cf
	m.Parent = parent
end

-- splits a flat axis-aligned slab into the pieces round a hole (x0..x1, z0..z1); returns them
function Garages.cut(part: BasePart, x0: number, x1: number, z0: number, z1: number): { BasePart }
	local p, s = part.CFrame.Position, part.Size
	local ax, bx = p.X - s.X / 2, p.X + s.X / 2
	local az, bz = p.Z - s.Z / 2, p.Z + s.Z / 2
	x0, x1 = math.max(x0, ax), math.min(x1, bx)
	z0, z1 = math.max(z0, az), math.min(z1, bz)
	if x1 <= x0 or z1 <= z0 then
		return { part }
	end
	local out = {}
	local function piece(px0: number, px1: number, pz0: number, pz1: number)
		if px1 - px0 < 0.05 or pz1 - pz0 < 0.05 then
			return
		end
		local c = part:Clone()
		c.Size = Vector3.new(px1 - px0, s.Y, pz1 - pz0)
		c.CFrame = CFrame.new((px0 + px1) / 2, p.Y, (pz0 + pz1) / 2)
		c.Parent = part.Parent
		table.insert(out, c)
	end
	piece(ax, x0, az, bz)
	piece(x1, bx, az, bz)
	piece(x0, x1, az, z0)
	piece(x0, x1, z1, bz)
	part:Destroy()
	return out
end

-- cuts a hole in whichever of these slabs it falls in
local function cutAll(slabs: { BasePart }, x0: number, x1: number, z0: number, z1: number): { BasePart }
	local out = {}
	for _, sl in slabs do
		if sl.Parent then
			for _, piece in Garages.cut(sl, x0, x1, z0, z1) do
				table.insert(out, piece)
			end
		end
	end
	return out
end

local function sign(kit: any, parent: Instance, at: Vector3, facing: Vector3, title: string, sub: string)
	local mk, deco = kit.mk, kit.deco
	mk(parent, Vector3.new(9, 0.5, 0.5), CFrame.new(at + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 48, 54), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local board = deco(parent, Vector3.new(5.5, 5.5, 0.3), CFrame.lookAt(at + Vector3.new(0, 10.5, 0), at + Vector3.new(0, 10.5, 0) + facing), BLUE, Enum.Material.SmoothPlastic)
	kit.surfaceText(board, Enum.NormalId.Front, "P", Color3.new(1, 1, 1), BLUE, 0, Enum.Font.GothamBlack, Vector2.new(200, 200))
	local plate = deco(parent, Vector3.new(7, 1.6, 0.25), CFrame.lookAt(at + Vector3.new(0, 6.8, 0), at + Vector3.new(0, 6.8, 0) + facing), Color3.fromRGB(20, 22, 26), Enum.Material.SmoothPlastic)
	kit.surfaceText(plate, Enum.NormalId.Front, title .. "\n" .. sub, Color3.new(1, 1, 1), Color3.fromRGB(20, 22, 26), 0, Enum.Font.GothamBold, Vector2.new(420, 100))
end

function Garages.build(kit: any, city: Instance)
	local mk, deco = kit.mk, kit.deco
	local blocks = city:FindFirstChild("Blocks")
	local groundFolder = city:FindFirstChild("Ground")
	if not (blocks and groundFolder) then
		return
	end
	local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).City
	local CityLayout = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CityLayout"))
	local CURB = C.CurbHeight
	local inner = C.BlockSize - C.RoadWidth
	-- (a block's sidewalk edge is inner / 2 from its middle; the lot is inner - 2 x sidewalk)
	for key, s in Garages.SIDE do
		local bi, bj = string.match(key, "^(%d+)_(%d+)$")
		local block = blocks:FindFirstChild("Block_" .. key)
		if not (bi and block) then
			continue
		end
		local cx = (CityLayout.roadCoord(tonumber(bi) :: number) + CityLayout.roadCoord(tonumber(bi) :: number + 1)) / 2
		local cz = (CityLayout.roadCoord(tonumber(bj) :: number) + CityLayout.roadCoord(tonumber(bj) :: number + 1)) / 2
		local function X(o: number): number -- an offset across the lot, towards the garage's side
			return cx + s * o
		end
		local function span(a: number, b: number): (number, number)
			return math.min(X(a), X(b)), math.max(X(a), X(b))
		end
		local garage = Instance.new("Model")
		garage.Name = "Garage"
		garage.Parent = block

		-- the holes: the ramp well through the ground and the sidewalk, and the lowered kerb
		local wx0, wx1 = span(RAMP_IN, RAMP_OUT)
		local sidewalks = {}
		for _, c in block:GetChildren() do
			if c:IsA("BasePart") and c.Name == "Sidewalk" then
				table.insert(sidewalks, c)
			end
		end
		sidewalks = cutAll(sidewalks, wx0, wx1, cz + RAMP_Z0, cz + RAMP_Z1)
		local kx0, kx1 = span(inner / 2 - 10, inner / 2 + 0.5)
		cutAll(sidewalks, kx0, kx1, cz + APRON_Z0, cz + APRON_Z1)
		local grounds = {}
		for _, g in groundFolder:GetChildren() do
			if g:IsA("BasePart") then
				table.insert(grounds, g)
			end
		end
		cutAll(grounds, wx0, wx1, cz + RAMP_Z0, cz + RAMP_Z1)
		-- clear the driveway of street furniture (lamp posts with their arms, a bus stop, a hydrant)
		local dx0, dx1 = span(inner / 2 - 12, inner / 2 + 10)
		for _, d in block:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Sidewalk" and d.Parent ~= garage then
				local p = d.CFrame.Position
				if p.X > dx0 and p.X < dx1 and p.Z > cz + APRON_Z0 - 1 and p.Z < cz + APRON_Z1 + 1 and p.Y < 30 and math.max(d.Size.X, d.Size.Z) < 40 then
					d:Destroy()
				end
			end
		end
		-- the lowered kerb: a gentle slope from the road up to the lot
		mk(garage, Vector3.new(math.abs(kx1 - kx0), CURB, APRON_Z1 - APRON_Z0), CFrame.new((kx0 + kx1) / 2, CURB / 2, cz + (APRON_Z0 + APRON_Z1) / 2), Color3.fromRGB(128, 124, 118), Enum.Material.Concrete, { name = "Driveway" })
		local wedgeLen = 4
		local wedgeX = X(inner / 2 + 0.5 + wedgeLen / 2)
		mk(garage, Vector3.new(APRON_Z1 - APRON_Z0, CURB, wedgeLen), CFrame.new(wedgeX, CURB / 2, cz + (APRON_Z0 + APRON_Z1) / 2) * CFrame.Angles(0, if s > 0 then -math.pi / 2 else math.pi / 2, 0), Color3.fromRGB(128, 124, 118), Enum.Material.Concrete, { class = "Wedge", name = "DrivewayWedge" })

		-- the ramp: down the well from the apron to the basement floor, yellow edges, arrows
		local top = Vector3.new(X((RAMP_IN + RAMP_OUT) / 2), CURB, cz + RAMP_Z0)
		local bottom = Vector3.new(X((RAMP_IN + RAMP_OUT) / 2), FLOOR, cz + RAMP_Z1)
		local len = (bottom - top).Magnitude
		local rampCf = CFrame.lookAt((top + bottom) / 2, bottom) -- -Z points down the ramp
		mk(garage, Vector3.new(RAMP_OUT - RAMP_IN, 1, len + 0.6), rampCf * CFrame.new(0, -0.5, 0), CONCRETE, Enum.Material.Concrete, { name = "Ramp" })
		for _, e in { -1, 1 } do
			deco(garage, Vector3.new(0.6, 0.06, len), rampCf * CFrame.new(e * ((RAMP_OUT - RAMP_IN) / 2 - 0.6), 0.03, 0), YELLOW, Enum.Material.SmoothPlastic)
		end
		for k = -2, 2 do
			local a = rampCf * CFrame.new(0, 0.04, k * 18)
			deco(garage, Vector3.new(0.7, 0.06, 6), a, WHITE, Enum.Material.SmoothPlastic)
			deco(garage, Vector3.new(0.7, 0.06, 3), a * CFrame.new(-1, 0, -2.2) * CFrame.Angles(0, math.rad(-35), 0), WHITE, Enum.Material.SmoothPlastic)
			deco(garage, Vector3.new(0.7, 0.06, 3), a * CFrame.new(1, 0, -2.2) * CFrame.Angles(0, math.rad(35), 0), WHITE, Enum.Material.SmoothPlastic)
		end
		-- the well's walls (from the basement floor up to a railing over the plaza) and its far end
		for _, o in { RAMP_IN - 0.6, RAMP_OUT + 0.6 } do
			mk(garage, Vector3.new(1.2, CURB + 3 - FLOOR, RAMP_Z1 - RAMP_Z0), CFrame.new(X(o), (FLOOR + CURB + 3) / 2, cz + (RAMP_Z0 + RAMP_Z1) / 2), CONCRETE, Enum.Material.Concrete, { name = "RampWall" })
			deco(garage, Vector3.new(1.4, 0.3, RAMP_Z1 - RAMP_Z0), CFrame.new(X(o), CURB + 3.15, cz + (RAMP_Z0 + RAMP_Z1) / 2), YELLOW, Enum.Material.SmoothPlastic)
		end
		mk(garage, Vector3.new(RAMP_OUT - RAMP_IN + 2.4, CURB + 3 - CEIL, 1.2), CFrame.new(X((RAMP_IN + RAMP_OUT) / 2), (CEIL + CURB + 3) / 2, cz + RAMP_Z1 + 0.6), CONCRETE, Enum.Material.Concrete, { name = "RampWall" })
		-- a height bar over the top of the ramp
		for _, o in { RAMP_IN - 0.6, RAMP_OUT + 0.6 } do
			mk(garage, Vector3.new(0.6, 11, 0.6), CFrame.new(X(o), CURB + 5.5, cz + RAMP_Z0 - 2), Color3.fromRGB(46, 48, 54), Enum.Material.Metal)
		end
		local bar = deco(garage, Vector3.new(RAMP_OUT - RAMP_IN + 1.8, 1.2, 0.5), CFrame.new(X((RAMP_IN + RAMP_OUT) / 2), CURB + 10.4, cz + RAMP_Z0 - 2), YELLOW, Enum.Material.SmoothPlastic)
		kit.surfaceText(bar, Enum.NormalId.Front, "RESIDENTS PARKING  ·  CLEARANCE 3.0 m", Color3.fromRGB(20, 20, 20), YELLOW, 0, Enum.Font.GothamBlack, Vector2.new(800, 50))
		kit.surfaceText(bar, Enum.NormalId.Back, "EXIT", Color3.fromRGB(20, 20, 20), YELLOW, 0, Enum.Font.GothamBlack, Vector2.new(800, 50))

		-- the basement: floor, walls, a concrete ceiling under the slab (open over the ramp well)
		mk(garage, Vector3.new(HALF * 2, 1, HALF * 2), CFrame.new(cx, FLOOR - 0.5, cz), CONCRETE_DARK, Enum.Material.Concrete, { name = "GarageFloor" })
		for _, w in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
			local size = if w[1] == 0 then Vector3.new(HALF * 2 + 2, CEIL - FLOOR, 1) else Vector3.new(1, CEIL - FLOOR, HALF * 2 + 2)
			mk(garage, size, CFrame.new(cx + w[1] * (HALF + 0.5), (FLOOR + CEIL) / 2, cz + w[2] * (HALF + 0.5)), CONCRETE, Enum.Material.Concrete, { name = "GarageWall" })
		end
		cutAll({ deco(garage, Vector3.new(HALF * 2, 0.3, HALF * 2), CFrame.new(cx, CEIL - 0.15, cz), Color3.fromRGB(150, 148, 142), Enum.Material.Concrete) }, wx0 - 1.2, wx1 + 1.2, cz + RAMP_Z0, cz + RAMP_Z1 + 1.2)
		-- bays: columns of nose-to-nose bays between aisles, across from the ramp side
		local BAY_W, BAY_D, AISLE = 10, 18, 24
		local o = RAMP_IN - 1.2 - AISLE -- the first bay column starts past an aisle beside the ramp wall
		local columns = {}
		while o - BAY_D * 2 > -HALF + 2 do
			table.insert(columns, o - BAY_D) -- the line between two nose-to-nose bays
			o -= BAY_D * 2 + AISLE
		end
		if o - BAY_D > -HALF + 1 then
			table.insert(columns, -HALF + BAY_D / 2 + 1 + BAY_D / 2) -- a single row against the far wall
		end
		local pillars = {}
		for _, mid in columns do
			local lx0, lx1 = span(mid - BAY_D, mid + BAY_D)
			deco(garage, Vector3.new(0.4, 0.06, HALF * 2 - 24), CFrame.new(X(mid), FLOOR + 0.03, cz), WHITE, Enum.Material.SmoothPlastic)
			for z = -HALF + 12, HALF - 12, BAY_W do
				deco(garage, Vector3.new(lx1 - lx0, 0.06, 0.4), CFrame.new((lx0 + lx1) / 2, FLOOR + 0.03, cz + z), WHITE, Enum.Material.SmoothPlastic)
				-- the bays either side of the middle line, cars backed in (facing the aisle)
				if z + BAY_W <= HALF - 12 then
					for _, side in { -1, 1 } do
						local c = Vector3.new(X(mid + side * BAY_D / 2), FLOOR, cz + z + BAY_W / 2)
						local out = Vector3.new(X(mid + side * BAY_D) - X(mid), 0, 0).Unit
						marker(garage, "ParkBay", CFrame.lookAt(c, c + out), Vector3.new(BAY_W - 1, 1, BAY_D - 1))
					end
				end
			end
			-- pillars on the middle line every few bays, lit strip lights over the aisles
			for z = -HALF + 12 + BAY_W * 3, HALF - 12, BAY_W * 4 do
				table.insert(pillars, Vector3.new(X(mid), 0, cz + z))
			end
		end
		for _, p in pillars do
			mk(garage, Vector3.new(2.6, CEIL - FLOOR, 2.6), CFrame.new(p.X, (FLOOR + CEIL) / 2, p.Z), Color3.fromRGB(170, 166, 158), Enum.Material.Concrete, { name = "Pillar" })
			deco(garage, Vector3.new(2.7, 1.2, 2.7), CFrame.new(p.X, FLOOR + 1.6, p.Z), YELLOW, Enum.Material.SmoothPlastic)
		end
		for xo = -HALF + 16, RAMP_IN - 8, 26 do
			for z = -HALF + 16, HALF - 16, 32 do
				local tube = deco(garage, Vector3.new(1, 0.25, 14), CFrame.new(X(xo), CEIL - 0.45, cz + z), TUBE, Enum.Material.Neon)
				if (z // 32) % 2 == 0 then
					kit.addLight("PointLight", tube, Color3.fromRGB(230, 240, 255), 34, 1.1)
				end
			end
		end
		-- level and exit signs
		local level = deco(garage, Vector3.new(10, 4, 0.3), CFrame.lookAt(Vector3.new(X(RAMP_IN - 14), CEIL - 3, cz + RAMP_Z1 + 6), Vector3.new(X(RAMP_IN - 14), CEIL - 3, cz + RAMP_Z1 + 7)), BLUE, Enum.Material.SmoothPlastic)
		kit.surfaceText(level, Enum.NormalId.Back, "P -1", Color3.new(1, 1, 1), BLUE, 0, Enum.Font.GothamBlack, Vector2.new(300, 120))
		local exit = deco(garage, Vector3.new(8, 2, 0.3), CFrame.new(X((RAMP_IN + RAMP_OUT) / 2), CEIL - 2.2, cz + RAMP_Z1 + 2), Color3.fromRGB(20, 140, 60), Enum.Material.Neon)
		kit.surfaceText(exit, Enum.NormalId.Back, "EXIT", Color3.new(1, 1, 1), Color3.fromRGB(20, 140, 60), 0, Enum.Font.GothamBlack, Vector2.new(300, 75))

		-- the entrance parking: three paid VIP bays off the apron, in the lot's corner (owner,
		-- 2026-10-23: "make it say VIP parking on the entrance ... and u have to pay to park")
		local fee = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")).Parking.VipFee
		local GOLD = Color3.fromRGB(232, 190, 90)
		for b = 0, 2 do
			local mid = 74 + 5 + b * 10
			local bx = X(mid)
			deco(garage, Vector3.new(0.4, 0.08, 18), CFrame.new(X(mid - 5), CURB + 0.22, cz + APRON_Z0 - 9), GOLD, Enum.Material.SmoothPlastic)
			mk(garage, Vector3.new(5, 0.5, 0.8), CFrame.new(bx, CURB + 0.45, cz + APRON_Z0 - 16.5), YELLOW, Enum.Material.Concrete)
			local pl = deco(garage, Vector3.new(6, 0.08, 3), CFrame.new(bx, CURB + 0.22, cz + APRON_Z0 - 6), WHITE, Enum.Material.SmoothPlastic, { transparency = 1 })
			kit.surfaceText(pl, Enum.NormalId.Top, "VIP", GOLD, nil, 1, Enum.Font.GothamBlack, Vector2.new(200, 100))
			local c = Vector3.new(bx, CURB, cz + APRON_Z0 - 9)
			marker(garage, "VipBay", CFrame.lookAt(c, c + Vector3.new(0, 0, 1)), Vector3.new(9, 8, 17))
		end
		deco(garage, Vector3.new(0.4, 0.08, 18), CFrame.new(X(74 + 30 + 0), CURB + 0.22, cz + APRON_Z0 - 9), GOLD, Enum.Material.SmoothPlastic)
		sign(kit, garage, Vector3.new(X(RAMP_IN - 4), CURB, cz + APRON_Z1 + 2), Vector3.new(0, 0, -1), "PARKING", "RESIDENTS · VISITORS")
		sign(kit, garage, Vector3.new(X(108 - 2), CURB, cz + APRON_Z0 - 19), Vector3.new(0, 0, 1), "VIP PARKING", "$" .. fee .. " · PAY ON ARRIVAL")
	end
end

return Garages
