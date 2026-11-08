--[[
	LoopLink (Studio, Edit mode; owner, 2026-11-08, a picture with two red lines: "MAKE the road like this"): the East
	Switchbacks leave the Mountain Road / Corniche Highway junction on a straight across the inside of their first loop
	and join the second leg just after the old U-turn. The old first leg and U-turn go (bed back to grass).
	Centreline: tools/riviera/looplink.json (PATH below: x, y, z, dir x, dir z, s), 13.7% at most.
	The data lines are written by tools/riviera/looplink_data.py from that file.

	LoopLink.backup()   copies the ground into ServerStorage.LoopLinkGround
	LoopLink.clear()    moves the old first leg and U-turn (road, kerbs, pavements, lines, wall, lamps, benches)
	                    to ServerStorage.LoopLinkOld
	LoopLink.ground()   cuts / fills the hillside for the new road, the old road's bed back to a grass bank
	LoopLink.build()    road, kerbs, pavements, lines (attribute LoopLink)
	LoopLink.lamps()    street lamps along it (copies of an old one)
	LoopLink.undo()     puts it all back
	Order: backup, clear, ground, build, lamps. Then the road meshes for the cells it touches, the lanes, the map tile.
]]

local ServerStorage = game:GetService("ServerStorage")

local LoopLink = {}

local PATH = {{17040.00,183.100,-480.00,0.8360,0.5490,0.00},{17043.33,183.055,-477.81,0.8360,0.5490,3.98},{17046.66,182.919,-475.63,0.8360,0.5490,7.96},{17049.98,182.694,-473.44,0.8360,0.5490,11.95},{17053.31,182.377,-471.25,0.8360,0.5490,15.93},{17056.64,181.971,-469.06,0.8360,0.5490,19.91},{17059.97,181.474,-466.88,0.8360,0.5490,23.89},{17063.29,180.930,-464.69,0.8360,0.5490,27.88},{17066.62,180.385,-462.50,0.8360,0.5490,31.86},{17069.95,179.841,-460.32,0.8360,0.5490,35.84},{17073.28,179.297,-458.13,0.8360,0.5490,39.82},{17076.60,178.752,-455.94,0.8360,0.5490,43.80},{17079.93,178.208,-453.76,0.8360,0.5490,47.78},{17083.26,177.664,-451.57,0.8360,0.5490,51.77},{17086.59,177.119,-449.38,0.8360,0.5490,55.75},{17089.92,176.575,-447.19,0.8360,0.5490,59.73},{17093.24,176.030,-445.01,0.8360,0.5490,63.71},{17096.57,175.486,-442.82,0.8360,0.5490,67.70},{17099.90,174.942,-440.63,0.8360,0.5490,71.68},{17103.23,174.397,-438.45,0.8360,0.5490,75.66},{17106.56,173.853,-436.26,0.8360,0.5490,79.64},{17109.88,173.309,-434.07,0.8360,0.5490,83.62},{17113.21,172.764,-431.89,0.8360,0.5490,87.61},{17116.54,172.220,-429.70,0.8360,0.5490,91.59},{17119.87,171.676,-427.51,0.8360,0.5490,95.57},{17123.19,171.131,-425.32,0.8360,0.5490,99.55},{17126.52,170.587,-423.14,0.8360,0.5490,103.53},{17129.85,170.042,-420.95,0.8360,0.5490,107.52},{17133.18,169.498,-418.76,0.8360,0.5490,111.50},{17136.51,168.954,-416.58,0.8360,0.5490,115.48},{17139.83,168.409,-414.39,0.8360,0.5490,119.46},{17143.16,167.865,-412.20,0.8360,0.5490,123.44},{17146.49,167.320,-410.02,0.8360,0.5490,127.43},{17149.82,166.776,-407.83,0.8360,0.5490,131.41},{17153.14,166.232,-405.64,0.8360,0.5490,135.39},{17156.47,165.687,-403.45,0.8360,0.5490,139.37},{17159.80,165.143,-401.27,0.8360,0.5490,143.35},{17163.13,164.599,-399.08,0.8360,0.5490,147.34},{17166.46,164.054,-396.89,0.8360,0.5490,151.32},{17169.78,163.510,-394.71,0.8360,0.5490,155.30},{17173.11,162.965,-392.52,0.8360,0.5490,159.28},{17176.44,162.421,-390.33,0.8360,0.5490,163.27},{17179.77,161.877,-388.14,0.8360,0.5490,167.25},{17183.09,161.332,-385.96,0.8360,0.5490,171.23},{17186.42,160.788,-383.77,0.8360,0.5490,175.21},{17189.75,160.244,-381.58,0.8360,0.5490,179.19},{17193.08,159.699,-379.40,0.8360,0.5490,183.18},{17196.40,159.155,-377.21,0.8360,0.5490,187.16},{17199.73,158.610,-375.02,0.8360,0.5490,191.14},{17203.06,158.066,-372.84,0.8360,0.5490,195.12},{17206.39,157.522,-370.65,0.8360,0.5490,199.10},{17209.72,156.977,-368.46,0.8360,0.5490,203.09},{17213.04,156.433,-366.27,0.8360,0.5490,207.07},{17216.37,155.889,-364.09,0.8360,0.5490,211.05},{17219.70,155.344,-361.90,0.8360,0.5490,215.03},{17223.03,154.800,-359.71,0.8360,0.5490,219.01},{17226.35,154.256,-357.53,0.8360,0.5490,223.00},{17229.68,153.711,-355.34,0.8360,0.5490,226.98},{17233.01,153.167,-353.15,0.8360,0.5490,230.96},{17236.34,152.622,-350.97,0.8360,0.5490,234.94},{17239.67,152.078,-348.78,0.8360,0.5490,238.93},{17242.99,151.534,-346.59,0.8360,0.5490,242.91},{17246.32,150.989,-344.40,0.8360,0.5490,246.89},{17249.65,150.445,-342.22,0.8360,0.5490,250.87},{17252.98,149.901,-340.03,0.8360,0.5490,254.85},{17256.31,149.356,-337.84,0.8360,0.5490,258.84},{17259.63,148.812,-335.66,0.8360,0.5490,262.82},{17262.96,148.267,-333.47,0.8360,0.5490,266.80},{17266.29,147.723,-331.28,0.8360,0.5490,270.78},{17269.62,147.179,-329.10,0.8360,0.5490,274.76},{17272.94,146.634,-326.91,0.8360,0.5490,278.75},{17276.27,146.090,-324.72,0.8360,0.5490,282.73},{17279.60,145.545,-322.54,0.8360,0.5490,286.71},{17282.93,145.001,-320.35,0.8360,0.5490,290.69},{17286.26,144.457,-318.16,0.8360,0.5490,294.68},{17289.58,143.912,-315.97,0.8360,0.5490,298.66},{17292.80,143.370,-313.65,0.7840,0.6210,302.62},{17295.79,142.828,-311.06,0.7260,0.6870,306.59},{17298.55,142.286,-308.21,0.6630,0.7480,310.55},{17301.04,141.744,-305.13,0.5950,0.8040,314.52},{17303.26,141.202,-301.84,0.5220,0.8530,318.48},{17305.18,140.660,-298.38,0.4450,0.8960,322.45},{17306.78,140.118,-294.75,0.3640,0.9310,326.41},{17308.06,139.576,-291.00,0.2810,0.9600,330.38},{17309.00,139.034,-287.15,0.1950,0.9810,334.34},{17309.60,138.492,-283.23,0.1080,0.9940,338.31},{17309.86,137.950,-279.27,0.0200,1.0000,342.27},{17309.76,137.408,-275.31,-0.0680,0.9980,346.24},{17309.32,136.866,-271.37,-0.1550,0.9880,350.20},{17308.53,136.324,-267.49,-0.2420,0.9700,354.17},{17307.41,135.782,-263.69,-0.3260,0.9450,358.13},{17305.95,135.240,-260.00,-0.4080,0.9130,362.10},{17304.17,134.698,-256.46,-0.4870,0.8730,366.06},{17302.09,134.156,-253.09,-0.5620,0.8270,370.03},{17299.72,133.617,-249.91,-0.6320,0.7750,373.99},{17297.08,133.095,-246.95,-0.6980,0.7160,377.96},{17294.19,132.593,-244.24,-0.7580,0.6520,381.92},{17291.08,132.110,-241.79,-0.8130,0.5820,385.89},{17287.76,131.646,-239.62,-0.8610,0.5090,389.85},{17284.26,131.201,-237.76,-0.9020,0.4310,393.82},{17280.61,130.776,-236.21,-0.9370,0.3500,397.78},{17276.84,130.370,-234.99,-0.9640,0.2660,401.75}} --DATA PATH
local OLD = {{17040.00,183.10,-480.00},{17041.51,183.10,-486.91},{17041.43,183.10,-495.19},{17040.35,183.10,-504.33},{17038.88,183.10,-513.82},{17037.61,183.10,-523.14},{17037.13,183.10,-531.77},{17038.04,183.10,-539.19},{17040.94,183.10,-544.89},{17046.44,183.10,-548.36},{17055.11,183.10,-549.07},{17067.57,183.10,-546.51},{17070.80,182.76,-545.50},{17074.34,182.58,-544.31},{17078.16,182.37,-542.95},{17082.27,182.10,-541.42},{17086.64,181.76,-539.74},{17091.26,181.39,-537.90},{17096.13,180.96,-535.91},{17101.22,180.41,-533.78},{17106.52,179.84,-531.51},{17112.03,179.24,-529.11},{17117.73,178.61,-526.59},{17123.61,177.97,-523.94},{17129.66,177.30,-521.18},{17135.85,176.62,-518.31},{17142.19,175.92,-515.34},{17148.65,175.21,-512.27},{17155.22,174.48,-509.10},{17161.90,173.73,-505.85},{17168.67,172.98,-502.52},{17175.52,172.21,-499.12},{17182.43,171.44,-495.64},{17189.39,170.66,-492.10},{17196.39,169.87,-488.50},{17203.42,169.08,-484.85},{17210.46,168.28,-481.15},{17217.51,167.49,-477.41},{17224.54,166.69,-473.64},{17231.55,165.89,-469.83},{17238.52,165.10,-466.00},{17245.45,164.30,-462.15},{17252.31,163.52,-458.29},{17259.10,162.73,-454.42},{17265.80,161.96,-450.54},{17272.40,161.19,-446.67},{17278.90,160.44,-442.81},{17285.26,159.70,-438.97},{17291.49,158.96,-435.14},{17297.58,158.25,-431.34},{17303.50,157.55,-427.57},{17309.24,156.86,-423.84},{17314.80,156.19,-420.15},{17320.16,155.55,-416.51},{17325.30,154.92,-412.92},{17330.23,154.31,-409.39},{17334.91,153.73,-405.93},{17339.35,153.17,-402.54},{17343.52,152.64,-399.23},{17347.41,152.13,-396.00},{17351.02,151.65,-392.85},{17354.33,151.20,-389.80},{17357.33,150.78,-386.85},{17360.00,150.39,-384.00},{17365.97,149.83,-376.75},{17370.88,149.23,-369.51},{17374.77,148.61,-362.32},{17377.69,147.85,-355.17},{17379.69,147.12,-348.07},{17380.80,146.41,-341.05},{17381.07,145.71,-334.10},{17380.54,145.02,-327.24},{17379.26,144.34,-320.49},{17377.28,143.64,-313.84},{17374.62,142.94,-307.32},{17371.35,142.22,-300.94},{17367.50,141.49,-294.69},{17363.11,140.74,-288.61},{17358.23,139.97,-282.69},{17352.90,139.19,-276.95},{17347.17,138.39,-271.40},{17341.08,137.58,-266.05},{17334.68,136.76,-260.92},{17328.00,135.93,-256.00},{17324.24,135.48,-253.52},{17320.13,135.00,-251.14},{17315.70,134.50,-248.85},{17310.95,133.98,-246.65},{17305.90,133.43,-244.52},{17300.57,132.86,-242.48},{17294.99,132.27,-240.51},{17289.16,131.66,-238.61},{17283.11,131.02,-236.77},{17276.84,130.37,-234.99}} --DATA OLD
local M = #OLD -- the old road from the junction (1) to where the new one joins (M)
local HALF = 32
local KERB_W, WALK = 0.9, 10
local KERB_UP, PAVE_UP = 0.58, 0.5
local THICK = 4
local START = 36 -- the kerbs, pavements and lines start here (the junction's own asphalt before it)
local PAINT = Color3.fromRGB(232, 232, 226)
local ASPHALT = Color3.fromRGB(46, 47, 50)
local PAVER = Color3.fromRGB(176, 104, 92)
local KERB = Color3.fromRGB(205, 202, 194)
local C = 4
local BOX_MIN = Vector3.new(16960, 96, -640)
local BOX_MAX = Vector3.new(17470, 236, -150)
local SLOPE_CUT, SLOPE_FILL = 1.35, 0.7

local function holding(name: string): Folder
	local f = ServerStorage:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = ServerStorage
	end
	return f :: Folder
end

-- nearest point of a polyline (list of {x, y, z, ...}) in plan: distance, height there, segment index
local function nearest(list, x: number, z: number, i0: number?, i1: number?): (number, number, number)
	local best, by, bi = math.huge, 0, 1
	for k = (i0 or 1), (i1 or #list) - 1 do
		local a, b = list[k], list[k + 1]
		local dx, dz = b[1] - a[1], b[3] - a[3]
		local L2 = dx * dx + dz * dz
		local u = if L2 > 0 then math.clamp(((x - a[1]) * dx + (z - a[3]) * dz) / L2, 0, 1) else 0
		local d = math.sqrt((x - a[1] - dx * u) ^ 2 + (z - a[3] - dz * u) ^ 2)
		if d < best then
			best, by, bi = d, a[2] + (b[2] - a[2]) * u, k
		end
	end
	return best, by, bi
end
LoopLink.nearest = nearest
LoopLink.PATH = PATH
LoopLink.OLD = OLD

local TOTAL = 0
-- the new road at distance s along it, `off` to the right of the way it runs, `up` above the surface
local function at(s: number, off: number, up: number): Vector3
	local n = #PATH
	local k = 1
	while k < n - 1 and PATH[k + 1][6] < s do
		k += 1
	end
	local a, b = PATH[k], PATH[k + 1]
	local t = math.clamp((s - a[6]) / math.max(b[6] - a[6], 1e-6), 0, 1)
	local x = a[1] + (b[1] - a[1]) * t
	local y = a[2] + (b[2] - a[2]) * t
	local z = a[3] + (b[3] - a[3]) * t
	local dx, dz = a[4] + (b[4] - a[4]) * t, a[5] + (b[5] - a[5]) * t
	local L = math.sqrt(dx * dx + dz * dz)
	dx, dz = dx / L, dz / L
	-- right of the way it runs, seen from above with x east and z south: (-dz, dx)
	return Vector3.new(x - dz * off, y + up, z + dx * off)
end
LoopLink.at = at
TOTAL = PATH[#PATH][6]

function LoopLink.backup()
	local t = workspace.Terrain
	local region = Region3int16.new(
		Vector3int16.new(BOX_MIN.X // C, BOX_MIN.Y // C, BOX_MIN.Z // C),
		Vector3int16.new(BOX_MAX.X // C, BOX_MAX.Y // C, BOX_MAX.Z // C)
	)
	local copy = t:CopyRegion(region)
	copy.Name = "LoopLinkGround"
	copy:SetAttribute("Corner", BOX_MIN)
	copy.Parent = ServerStorage
end

local function farFromJunction(x: number, z: number): boolean
	return (Vector2.new(x, z) - Vector2.new(OLD[1][1], OLD[1][3])).Magnitude > 40
end

-- is a spot on the old stretch (and not on the junction, nor on the leg that stays)?
local function onOld(p: Vector3, reach: number): boolean
	if p.Y < 110 or p.Y > 205 then
		return false
	end
	local d = nearest(OLD, p.X, p.Z, 2, M - 1)
	if d > reach or not farFromJunction(p.X, p.Z) then
		return false
	end
	-- the leg that stays starts at M
	local dq = (Vector2.new(p.X, p.Z) - Vector2.new(OLD[M][1], OLD[M][3])).Magnitude
	local dLast = nearest(OLD, p.X, p.Z, M - 3, M)
	return not (dq < 30 and dLast <= d + 0.01)
end
LoopLink.onOld = onOld

function LoopLink.clear(): number
	local keep = holding("LoopLinkOld")
	local n = 0
	local road = workspace.Riviera.Roads["East Switchbacks"]
	local f = keep:FindFirstChild(road.Name) or Instance.new("Folder")
	f.Name = road.Name
	f.Parent = keep
	for _, p in road:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("LoopLink") == nil and onOld(p.Position, HALF + KERB_W + WALK + 3) then
			p.Parent = f
			n += 1
		end
	end
	-- what stood by the old road or stands on the new one
	local dressing = workspace.Riviera.Dressing
	for _, d in dressing:GetChildren() do
		if (d:IsA("Model") or d:IsA("BasePart")) and d:GetAttribute("LoopLink") == nil then
			local pos = if d:IsA("Model") then d:GetPivot().Position else (d :: BasePart).Position
			local dNew = nearest(PATH, pos.X, pos.Z)
			local onNew = dNew < HALF + WALK + 6 and pos.Y > 110 and pos.Y < 205 and farFromJunction(pos.X, pos.Z)
			if onOld(pos, HALF + WALK + 8) or onNew then
				d:SetAttribute("WasIn", (d.Parent :: Instance):GetFullName())
				d.Parent = keep
				n += 1
			end
		end
	end
	return n
end

function LoopLink.ground(): number
	local t = workspace.Terrain
	local region = Region3.new(BOX_MIN, BOX_MAX):ExpandToGrid(C)
	local mats, occ = t:ReadVoxels(region, C)
	local sz = mats.Size
	local low = region.CFrame.Position - region.Size / 2
	local edge = HALF + KERB_W + WALK
	local changed = 0
	for ix = 1, sz.X do
		local x = low.X + (ix - 0.5) * C
		for iz = 1, sz.Z do
			local z = low.Z + (iz - 0.5) * C
			local g = low.Y
			local topMat = Enum.Material.Ground
			for iy = sz.Y, 1, -1 do
				if occ[ix][iy][iz] > 0.02 and mats[ix][iy][iz] ~= Enum.Material.Water then
					g = low.Y + (iy - 1 + occ[ix][iy][iz]) * C
					topMat = mats[ix][iy][iz]
					break
				end
			end
			local want, mat = g, nil
			-- the old road's bed: back up to its old height, in grass
			local dOld, oldY = nearest(OLD, x, z, 2, M - 1)
			if dOld < edge + 4 and onOld(Vector3.new(x, oldY, z), edge + 4) then
				if want < oldY - 0.4 then
					want = oldY - 0.4
				end
				mat = Enum.Material.Grass
			end
			-- the new road
			local d, h, k = nearest(PATH, x, z)
			local beyond = k == 1 and not farFromJunction(x, z) -- (the junction's own ground stays)
			if not beyond then
				if d <= HALF then
					want, mat = h - 4, Enum.Material.Asphalt
				elseif d <= edge + 1 then
					want, mat = h - 1.4, Enum.Material.Ground
				elseif d < edge + 90 then
					local e = d - edge - 1
					local top = h - 1.4 + e * SLOPE_CUT
					local bottom = h - 1.4 - e * SLOPE_FILL
					if want > top then
						want, mat = top, Enum.Material.Rock
					elseif want < bottom then
						want, mat = bottom, Enum.Material.Ground
					end
				end
			end
			if math.abs(want - g) > 0.05 or mat then
				changed += 1
				for iy = 1, sz.Y do
					local yb = low.Y + (iy - 1) * C
					local o = math.clamp((want - yb) / C, 0, 1)
					occ[ix][iy][iz] = o
					if o <= 0 then
						mats[ix][iy][iz] = Enum.Material.Air
					elseif mat and yb + C >= want - C then
						mats[ix][iy][iz] = mat
					elseif mats[ix][iy][iz] == Enum.Material.Air then
						mats[ix][iy][iz] = mat or topMat
					end
				end
			end
		end
		if ix % 16 == 0 then
			task.wait()
		end
	end
	t:WriteVoxels(region, C, mats, occ)
	return changed
end

local function triangle(a: Vector3, b: Vector3, c: Vector3, parent: Instance)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 then
		return
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	local drop = -nUp * (THICK / 2)
	local w1 = Instance.new("WedgePart")
	w1.Size = Vector3.new(THICK, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + drop, right, up, back)
	local w2 = Instance.new("WedgePart")
	w2.Size = Vector3.new(THICK, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back)
	for _, w in { w1, w2 } do
		w.Name = "Road"
		w.Anchored = true
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w.Material = Enum.Material.Asphalt
		w.Color = ASPHALT
		w.CastShadow = false
		w:SetAttribute("LoopLink", true)
		w.Parent = parent
	end
end

local function box(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean, parent: Instance)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid
	p.CanTouch = false
	p.CanQuery = solid
	p.CastShadow = false
	p:SetAttribute("LoopLink", true)
	p.Parent = parent
end

function LoopLink.build(): number
	local road = workspace.Riviera.Roads["East Switchbacks"]
	-- the surface: two strips, a triangle pair every PATH step
	for k = 1, #PATH - 1 do
		local s0, s1 = PATH[k][6], PATH[k + 1][6]
		for _, side in { { -HALF, 0 }, { 0, HALF } } do
			local a, b = at(s0, side[1], 0), at(s0, side[2], 0)
			local c, d = at(s1, side[1], 0), at(s1, side[2], 0)
			triangle(a, b, d, road)
			triangle(a, d, c, road)
		end
		if k % 20 == 0 then
			task.wait()
		end
	end
	-- kerbs, pavements, lines from START (the junction's own asphalt before it) to the end (the leg's own after it)
	for _, side in { -1, 1 } do
		local s = START
		while s < TOTAL do
			local ns = math.min(s + 5, TOTAL)
			local a, b = at(s, side * (HALF + 0.4), KERB_UP - 3.02), at(ns, side * (HALF + 0.4), KERB_UP - 3.02)
			box("Kerb", Vector3.new(KERB_W, 6.04, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), KERB, Enum.Material.Concrete, true, road)
			s = ns
		end
		s = START
		while s < TOTAL do
			local ns = math.min(s + 6, TOTAL)
			local off = side * (HALF + KERB_W - 0.4 + WALK / 2 - 0.05)
			local a, b = at(s, off, PAVE_UP - 3), at(ns, off, PAVE_UP - 3)
			box("Pavement", Vector3.new(WALK, 6, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), PAVER, Enum.Material.Pavement, true, road)
			s = ns
		end
		s = START
		while s < TOTAL do
			local ns = math.min(s + 6, TOTAL)
			local a, b = at(s, side * (HALF - 1.5), 0.1), at(ns, side * (HALF - 1.5), 0.1)
			box("Line", Vector3.new(0.6, 0.04, (b - a).Magnitude + 0.3), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
			s = ns
		end
		task.wait()
	end
	local s = START
	while s < TOTAL - 8 do
		local a, b = at(s, 0, 0.1), at(s + 7, 0, 0.1)
		box("Line", Vector3.new(0.5, 0.04, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), PAINT, Enum.Material.SmoothPlastic, false, road)
		s += 15
	end
	local n = 0
	for _, p in road:GetChildren() do
		if p:GetAttribute("LoopLink") then
			n += 1
		end
	end
	return n
end

-- street lamps along both pavements, one each side every 140 studs, copies of an old one turned to face the road
function LoopLink.lamps(): number
	local keep = ServerStorage:FindFirstChild("LoopLinkOld")
	local proto: Model? = nil
	local protoSide = nil
	if keep then
		for _, d in keep:GetChildren() do
			if d.Name == "StreetLamp" and d:IsA("Model") then
				proto = d
				break
			end
		end
	end
	if not proto then
		return 0
	end
	-- which way the old lamp's arm reaches (its own frame): from its pivot to its highest part
	local pv = proto:GetPivot()
	local top, topY = nil, -math.huge
	for _, p in proto:GetDescendants() do
		if p:IsA("BasePart") and p.Position.Y > topY then
			top, topY = p, p.Position.Y
		end
	end
	local reachLocal = pv:PointToObjectSpace(if top then top.Position else pv.Position) * Vector3.new(1, 0, 1)
	protoSide = if reachLocal.Magnitude > 0.5 then reachLocal.Unit else Vector3.new(0, 0, -1)
	local n = 0
	local s = START + 20
	while s < TOTAL - 20 do
		for _, side in { -1, 1 } do
			local base = at(s, side * (HALF + KERB_W + 1.6), PAVE_UP)
			local inward = ((at(s, 0, PAVE_UP) - base) * Vector3.new(1, 0, 1)).Unit
			-- turn so the arm (protoSide in the lamp's frame) points inward
			local yawArm = math.atan2(-protoSide.X, -protoSide.Z)
			local yawIn = math.atan2(-inward.X, -inward.Z)
			local lamp = (proto :: Model):Clone()
			lamp:PivotTo(CFrame.new(base) * CFrame.Angles(0, yawIn - yawArm, 0) * pv.Rotation)
			lamp:SetAttribute("LoopLink", true)
			lamp.Parent = workspace.Riviera.Dressing
			n += 1
		end
		s += 140
	end
	return n
end

function LoopLink.undo()
	local road = workspace.Riviera.Roads["East Switchbacks"]
	for _, p in road:GetChildren() do
		if p:GetAttribute("LoopLink") then
			p:Destroy()
		end
	end
	for _, d in workspace.Riviera.Dressing:GetChildren() do
		if d:GetAttribute("LoopLink") then
			d:Destroy()
		end
	end
	local keep = ServerStorage:FindFirstChild("LoopLinkOld")
	if keep then
		local f = keep:FindFirstChild(road.Name)
		if f then
			for _, p in f:GetChildren() do
				p.Parent = road
			end
		end
		for _, d in keep:GetChildren() do
			if d ~= f then
				d.Parent = workspace.Riviera.Dressing
			end
		end
	end
	local g = ServerStorage:FindFirstChild("LoopLinkGround")
	if g then
		workspace.Terrain:PasteRegion(g :: TerrainRegion, Vector3int16.new(BOX_MIN.X // C, BOX_MIN.Y // C, BOX_MIN.Z // C), true)
	end
end

return LoopLink
