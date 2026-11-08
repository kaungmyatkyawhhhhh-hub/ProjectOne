--[[
	LoopLink (Studio, Edit mode; owner, 2026-11-08, a picture with two red lines: "MAKE the road like this"): the East
	Switchbacks leave the Mountain Road / Corniche Highway junction on a straight across the inside of their first loop
	and join the second leg just after the old U-turn. The old first leg and U-turn go (bed back to grass).
	Centreline: tools/riviera/looplink.json (PATH below: x, y, z, dir x, dir z, s): flat for 28 studs (the junction), then
	15.2% at most; the bend R 70 (owner, same day: "make the corner less sharp"; it was 45). looplink_design.py makes the
	file (R and the join sample as arguments), looplink_data.py writes it into the two data lines here.

	LoopLink.backup()   copies the ground into ServerStorage.LoopLinkGround
	LoopLink.clear()    moves the old first leg and U-turn (road, kerbs, pavements, lines, wall, lamps, benches) and the
	                    old mouth's pieces at the junction (attribute Mouth) to ServerStorage.LoopLinkOld
	LoopLink.ground()   cuts / fills the hillside for the new road, the old road's bed back to a grass bank (the junction's
	                    ground and the leg's past the join stay); run again on the backup: paste LoopLinkGround first
	LoopLink.surface()  the road surface only (build calls it; 4-stud strips on the inside of the bend)
	LoopLink.build()    road, kerbs, pavements, lines (attribute LoopLink)
	LoopLink.lamps()    street lamps along it (copies of an old one)
	LoopLink.undo()     puts it all back (not the meshes: the old ones are in ServerStorage.LoopLinkOldMeshes)
	Order: backup, clear, ground, build, lamps. Then: hide the new road / line / kerb / pavement parts (MeshHidden), the
	road meshes for the 4 cells (tools/road_mesh/patch_cells.py), the lanes (looplink_lanes.py on the committed lanes),
	the map tile (tools/minimap_art.py).
]]

local ServerStorage = game:GetService("ServerStorage")

local LoopLink = {}

local PATH = {{17040.00,183.100,-480.00,0.8650,0.5010,0.00},{17043.44,183.100,-478.01,0.8650,0.5010,3.98},{17046.88,183.100,-476.01,0.8650,0.5010,7.95},{17050.32,183.100,-474.02,0.8650,0.5010,11.93},{17053.76,183.100,-472.03,0.8650,0.5010,15.90},{17057.20,183.100,-470.04,0.8650,0.5010,19.88},{17060.64,183.100,-468.04,0.8650,0.5010,23.85},{17064.08,183.100,-466.05,0.8650,0.5010,27.83},{17067.52,183.054,-464.06,0.8650,0.5010,31.80},{17070.96,182.908,-462.07,0.8650,0.5010,35.78},{17074.40,182.662,-460.07,0.8650,0.5010,39.75},{17077.84,182.316,-458.08,0.8650,0.5010,43.73},{17081.28,181.869,-456.09,0.8650,0.5010,47.70},{17084.72,181.322,-454.10,0.8650,0.5010,51.68},{17088.16,180.717,-452.10,0.8650,0.5010,55.66},{17091.60,180.112,-450.11,0.8650,0.5010,59.63},{17095.04,179.507,-448.12,0.8650,0.5010,63.61},{17098.48,178.902,-446.13,0.8650,0.5010,67.58},{17101.92,178.297,-444.13,0.8650,0.5010,71.56},{17105.36,177.692,-442.14,0.8650,0.5010,75.53},{17108.80,177.087,-440.15,0.8650,0.5010,79.51},{17112.24,176.482,-438.15,0.8650,0.5010,83.48},{17115.68,175.877,-436.16,0.8650,0.5010,87.46},{17119.12,175.272,-434.17,0.8650,0.5010,91.43},{17122.56,174.667,-432.18,0.8650,0.5010,95.41},{17126.00,174.062,-430.19,0.8650,0.5010,99.38},{17129.44,173.457,-428.19,0.8650,0.5010,103.36},{17132.88,172.852,-426.20,0.8650,0.5010,107.33},{17136.32,172.247,-424.21,0.8650,0.5010,111.31},{17139.76,171.641,-422.21,0.8650,0.5010,115.29},{17143.20,171.036,-420.22,0.8650,0.5010,119.26},{17146.64,170.431,-418.23,0.8650,0.5010,123.24},{17150.08,169.826,-416.24,0.8650,0.5010,127.21},{17153.52,169.221,-414.24,0.8650,0.5010,131.19},{17156.96,168.616,-412.25,0.8650,0.5010,135.16},{17160.40,168.011,-410.26,0.8650,0.5010,139.14},{17163.84,167.406,-408.27,0.8650,0.5010,143.11},{17167.28,166.801,-406.27,0.8650,0.5010,147.09},{17170.72,166.196,-404.28,0.8650,0.5010,151.06},{17174.16,165.591,-402.29,0.8650,0.5010,155.04},{17177.60,164.986,-400.30,0.8650,0.5010,159.01},{17181.04,164.381,-398.30,0.8650,0.5010,162.99},{17184.48,163.776,-396.31,0.8650,0.5010,166.97},{17187.92,163.171,-394.32,0.8650,0.5010,170.94},{17191.36,162.566,-392.32,0.8650,0.5010,174.92},{17194.80,161.961,-390.33,0.8650,0.5010,178.89},{17198.24,161.356,-388.34,0.8650,0.5010,182.87},{17201.68,160.750,-386.35,0.8650,0.5010,186.84},{17205.12,160.145,-384.36,0.8650,0.5010,190.82},{17208.56,159.540,-382.36,0.8650,0.5010,194.79},{17212.00,158.935,-380.37,0.8650,0.5010,198.77},{17215.44,158.330,-378.38,0.8650,0.5010,202.74},{17218.88,157.725,-376.38,0.8650,0.5010,206.72},{17222.32,157.120,-374.39,0.8650,0.5010,210.69},{17225.76,156.515,-372.40,0.8650,0.5010,214.67},{17229.20,155.910,-370.41,0.8650,0.5010,218.65},{17232.64,155.305,-368.41,0.8650,0.5010,222.62},{17236.08,154.700,-366.42,0.8650,0.5010,226.60},{17239.52,154.095,-364.43,0.8650,0.5010,230.57},{17242.96,153.490,-362.44,0.8650,0.5010,234.55},{17246.40,152.885,-360.44,0.8650,0.5010,238.52},{17249.84,152.280,-358.45,0.8650,0.5010,242.50},{17253.28,151.675,-356.46,0.8650,0.5010,246.47},{17256.72,151.070,-354.47,0.8650,0.5010,250.45},{17260.06,150.472,-352.40,0.8360,0.5490,254.37},{17263.28,149.875,-350.16,0.8040,0.5950,258.30},{17266.36,149.277,-347.74,0.7690,0.6390,262.23},{17269.31,148.680,-345.14,0.7320,0.6810,266.15},{17272.11,148.082,-342.39,0.6930,0.7210,270.08},{17274.75,147.485,-339.48,0.6510,0.7590,274.00},{17277.22,146.887,-336.44,0.6080,0.7940,277.93},{17279.52,146.290,-333.25,0.5620,0.8270,281.86},{17281.63,145.692,-329.94,0.5150,0.8570,285.78},{17283.56,145.095,-326.52,0.4660,0.8850,289.71},{17285.29,144.497,-323.00,0.4160,0.9090,293.63},{17286.82,143.900,-319.39,0.3640,0.9310,297.56},{17288.15,143.302,-315.69,0.3110,0.9500,301.48},{17289.26,142.705,-311.93,0.2580,0.9660,305.41},{17290.17,142.107,-308.11,0.2030,0.9790,309.33},{17290.86,141.510,-304.25,0.1480,0.9890,313.26},{17291.33,140.912,-300.35,0.0920,0.9960,317.19},{17291.58,140.315,-296.43,0.0360,0.9990,321.11},{17291.62,139.717,-292.51,-0.0200,1.0000,325.04},{17291.43,139.120,-288.59,-0.0760,0.9970,328.96},{17291.02,138.522,-284.68,-0.1320,0.9910,332.89},{17290.40,137.925,-280.81,-0.1870,0.9820,336.82},{17289.55,137.327,-276.97,-0.2420,0.9700,340.74},{17288.50,136.730,-273.19,-0.2960,0.9550,344.67},{17287.23,136.132,-269.48,-0.3490,0.9370,348.59},{17285.76,135.535,-265.84,-0.4010,0.9160,352.52},{17284.09,134.937,-262.29,-0.4520,0.8920,356.44},{17282.22,134.340,-258.84,-0.5010,0.8660,360.37},{17280.16,133.742,-255.50,-0.5490,0.8360,364.30},{17277.91,133.145,-252.28,-0.5950,0.8040,368.22},{17275.49,132.547,-249.19,-0.6390,0.7690,372.15},{17272.90,131.950,-246.24,-0.6810,0.7320,376.07},{17270.15,131.352,-243.44,-0.7210,0.6930,380.00},{17267.24,130.755,-240.80,-0.7590,0.6520,383.93},{17264.20,130.157,-238.32,-0.7940,0.6080,387.85},{17261.01,129.565,-236.03,-0.8270,0.5630,391.78},{17257.71,128.998,-233.91,-0.8570,0.5150,395.70},{17254.29,128.458,-231.98,-0.8840,0.4670,399.63},{17250.77,127.945,-230.25,-0.9090,0.4160,403.55},{17247.15,127.458,-228.71,-0.9310,0.3650,407.48},{17243.46,126.999,-227.39,-0.9500,0.3120,411.40},{17239.70,126.566,-226.27,-0.9660,0.2580,415.33},{17235.88,126.160,-225.36,-0.9790,0.2040,419.26}} --DATA PATH
local OLD = {{17040.00,183.10,-480.00},{17041.51,183.10,-486.91},{17041.43,183.10,-495.19},{17040.35,183.10,-504.33},{17038.88,183.10,-513.82},{17037.61,183.10,-523.14},{17037.13,183.10,-531.77},{17038.04,183.10,-539.19},{17040.94,183.10,-544.89},{17046.44,183.10,-548.36},{17055.11,183.10,-549.07},{17067.57,183.10,-546.51},{17070.80,182.76,-545.50},{17074.34,182.58,-544.31},{17078.16,182.37,-542.95},{17082.27,182.10,-541.42},{17086.64,181.76,-539.74},{17091.26,181.39,-537.90},{17096.13,180.96,-535.91},{17101.22,180.41,-533.78},{17106.52,179.84,-531.51},{17112.03,179.24,-529.11},{17117.73,178.61,-526.59},{17123.61,177.97,-523.94},{17129.66,177.30,-521.18},{17135.85,176.62,-518.31},{17142.19,175.92,-515.34},{17148.65,175.21,-512.27},{17155.22,174.48,-509.10},{17161.90,173.73,-505.85},{17168.67,172.98,-502.52},{17175.52,172.21,-499.12},{17182.43,171.44,-495.64},{17189.39,170.66,-492.10},{17196.39,169.87,-488.50},{17203.42,169.08,-484.85},{17210.46,168.28,-481.15},{17217.51,167.49,-477.41},{17224.54,166.69,-473.64},{17231.55,165.89,-469.83},{17238.52,165.10,-466.00},{17245.45,164.30,-462.15},{17252.31,163.52,-458.29},{17259.10,162.73,-454.42},{17265.80,161.96,-450.54},{17272.40,161.19,-446.67},{17278.90,160.44,-442.81},{17285.26,159.70,-438.97},{17291.49,158.96,-435.14},{17297.58,158.25,-431.34},{17303.50,157.55,-427.57},{17309.24,156.86,-423.84},{17314.80,156.19,-420.15},{17320.16,155.55,-416.51},{17325.30,154.92,-412.92},{17330.23,154.31,-409.39},{17334.91,153.73,-405.93},{17339.35,153.17,-402.54},{17343.52,152.64,-399.23},{17347.41,152.13,-396.00},{17351.02,151.65,-392.85},{17354.33,151.20,-389.80},{17357.33,150.78,-386.85},{17360.00,150.39,-384.00},{17365.97,149.83,-376.75},{17370.88,149.23,-369.51},{17374.77,148.61,-362.32},{17377.69,147.85,-355.17},{17379.69,147.12,-348.07},{17380.80,146.41,-341.05},{17381.07,145.71,-334.10},{17380.54,145.02,-327.24},{17379.26,144.34,-320.49},{17377.28,143.64,-313.84},{17374.62,142.94,-307.32},{17371.35,142.22,-300.94},{17367.50,141.49,-294.69},{17363.11,140.74,-288.61},{17358.23,139.97,-282.69},{17352.90,139.19,-276.95},{17347.17,138.39,-271.40},{17341.08,137.58,-266.05},{17334.68,136.76,-260.92},{17328.00,135.93,-256.00},{17324.24,135.48,-253.52},{17320.13,135.00,-251.14},{17315.70,134.50,-248.85},{17310.95,133.98,-246.65},{17305.90,133.43,-244.52},{17300.57,132.86,-242.48},{17294.99,132.27,-240.51},{17289.16,131.66,-238.61},{17283.11,131.02,-236.77},{17276.84,130.37,-234.99},{17270.39,129.71,-233.27},{17263.76,129.02,-231.60},{17256.98,128.32,-229.98},{17250.06,127.61,-228.40},{17243.02,126.89,-226.86},{17235.88,126.16,-225.36}} --DATA OLD
local M = #OLD -- the old road from the junction (1) to where the new one joins (M)
local HALF = 32
local KERB_W, WALK = 0.9, 10
local KERB_UP, PAVE_UP = 0.58, 0.5
local THICK = 4
local START = 30 -- the kerbs, pavements and lines start here (the junction's own asphalt before it)
local START_LEFT = -12 -- on the left the old road's mouth is gone: the kerb runs on back to the Mountain Road's
local BACK = -16 -- the surface starts this far back in the junction (over the old mouth's corner)
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
	if s < 0 then
		-- (back into the junction, flat, the way the road starts)
		local a = PATH[1]
		return Vector3.new(a[1] + a[4] * s - a[5] * off, a[2] + up, a[3] + a[5] * s + a[4] * off)
	end
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
	-- past the join's cross line: the leg that stays (the same test as tools/road_mesh/patch_cells.py)
	local q, e = OLD[M], PATH[#PATH]
	local rx, rz = p.X - q[1], p.Z - q[3]
	if rx * e[4] + rz * e[5] > 0.5 and math.sqrt(rx * rx + rz * rz) < 75 then
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
	local p0 = Vector2.new(OLD[1][1], OLD[1][3])
	for _, p in road:GetChildren() do
		if p:IsA("BasePart") and p:GetAttribute("LoopLink") == nil then
			if onOld(p.Position, HALF + KERB_W + WALK + 3) then
				p.Parent = f
				n += 1
			elseif p.Position.Y > 170 and p.Position.Y < 200 then
				-- the old mouth (its first samples, heading north out of the junction): the new surface lies there
				local d = nearest(OLD, p.Position.X, p.Position.Z, 1, 12)
				if d < 46 and (Vector2.new(p.Position.X, p.Position.Z) - p0).Magnitude < 75 then
					p:SetAttribute("Mouth", true)
					p.Parent = f
					n += 1
				end
			end
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
			local q = PATH[#PATH]
			local pastEnd = k == #PATH - 1 and (x - q[1]) * q[4] + (z - q[3]) * q[5] > 0
			-- (the junction's own ground stays, and so does the leg's past the join: it runs on lower)
			local beyond = (k == 1 and not farFromJunction(x, z)) or pastEnd
			if not beyond then
				if d <= HALF then
					want, mat = h - 4, Enum.Material.Asphalt
				elseif d <= edge + 1 then
					want, mat = h - 2.6, Enum.Material.Ground
				elseif d < edge + 90 then
					local e = d - edge - 1
					-- low under the pavement and a low verge after it: smooth terrain's 4-stud voxels came up to
					-- 2 studs over the height asked for next to the steep cut (grass and rock teeth on the pavers),
					-- so the cut starts 4 studs out
					local top = h - 1.8 + math.max(0, e - 4) * SLOPE_CUT
					local bottom = h - 2.6 - e * SLOPE_FILL
					if want > top then
						want, mat = top, if e < 4 then Enum.Material.Grass else Enum.Material.Rock
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

-- the surface: a triangle pair per strip every PATH step. On the straight two strips (flat across, so each quad is
-- flat). In the bend a quad between two radial edges at different heights is twisted, and its two triangles slope
-- differently (on the inside of the R 45 bend the lanes went 15% / 51% / 15%: a small step every 3 studs), so there
-- the strips are 4 studs wide on the inside and 8 on the outside.
local COARSE = { -HALF, 0, HALF }
local function strips(k: number): { number }
	local a, b = PATH[k], PATH[k + 1]
	local turn = a[4] * b[5] - a[5] * b[4] -- > 0: turning right (the inside is +off)
	if math.abs(turn) < 0.002 then
		return COARSE
	end
	local list = {}
	for off = -HALF, HALF, 4 do
		local inside = if turn > 0 then off >= 0 else off <= 0
		if inside or off % 8 == 0 then
			table.insert(list, off)
		end
	end
	return list
end

function LoopLink.surface(): number
	local road = workspace.Riviera.Roads["East Switchbacks"]
	local n = 0
	do
		local a, b = at(BACK, -HALF, 0), at(BACK, 0, 0)
		local c, d = at(0, -HALF, 0), at(0, 0, 0)
		triangle(a, b, d, road)
		triangle(a, d, c, road)
	end
	for k = 1, #PATH - 1 do
		local s0, s1 = PATH[k][6], PATH[k + 1][6]
		local list = strips(k)
		for i = 1, #list - 1 do
			local a, b = at(s0, list[i], 0), at(s0, list[i + 1], 0)
			local c, d = at(s1, list[i], 0), at(s1, list[i + 1], 0)
			triangle(a, b, d, road)
			triangle(a, d, c, road)
			n += 4
		end
		if k % 10 == 0 then
			task.wait()
		end
	end
	return n
end

function LoopLink.build(): number
	local road = workspace.Riviera.Roads["East Switchbacks"]
	LoopLink.surface()
	-- kerbs, pavements, lines from START (the junction's own asphalt before it) to the end (the leg's own after it)
	for _, side in { -1, 1 } do
		local first = if side < 0 then START_LEFT else START
		local s = first
		while s < TOTAL do
			local ns = math.min(s + 5, TOTAL)
			local a, b = at(s, side * (HALF + 0.4), KERB_UP - 3.02), at(ns, side * (HALF + 0.4), KERB_UP - 3.02)
			box("Kerb", Vector3.new(KERB_W, 6.04, (b - a).Magnitude + 0.25), CFrame.lookAt((a + b) / 2, b), KERB, Enum.Material.Concrete, true, road)
			s = ns
		end
		s = first
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
