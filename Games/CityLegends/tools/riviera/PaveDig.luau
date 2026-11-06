--[[
	PaveDig (Studio, Edit mode; owner, 2026-11-06, "FIND IT ALL"): the hillside coming up through a pavement in
	patches of grass and stone. Road writes smooth the terrain over the pavement's edge, and terrain
	voxels are 4 studs, so a slope can stand a little over a flat piece of paving.

	Each pavement piece is sampled GRID x GRID across. Where the ground stands over the paving, the terrain
	columns under the piece (and MARGIN round it) are rewritten so the ground stops SINK under the paving's
	top. Only ground over that height goes; nothing is filled in. The pieces stay where they are.

	PaveDig.check(roads) -> pieces with ground over them, share of their sample points on average
	PaveDig.run(roads) -> pieces dug
]]

local PaveDig = {}

local C = 4 -- terrain voxel
local MARGIN = 3
local SINK = 1.6
local OVER = 0.02
local HIGH = 14
local GRID = 5

local function floorTo(v: number): number
	return math.floor(v / C) * C
end

local function terrainOnly(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	return params
end

-- how many sample points have ground over them
local function over(p: BasePart, params: RaycastParams): number
	local cf, s = p.CFrame, p.Size
	local hits = 0
	for i = 1, GRID do
		for j = 1, GRID do
			local at = cf * Vector3.new(((i - 0.5) / GRID - 0.5) * s.X, s.Y / 2, ((j - 0.5) / GRID - 0.5) * s.Z)
			local r = workspace:Raycast(at + Vector3.new(0, HIGH, 0), Vector3.new(0, -HIGH, 0), params)
			if r and r.Position.Y > at.Y + OVER then
				hits += 1
			end
		end
	end
	return hits
end

local function each(roads: Instance, fn: (BasePart) -> ())
	local n = 0
	for _, road in roads:GetChildren() do
		for _, p in road:GetChildren() do
			if p.Name == "Pavement" and p:IsA("Part") then
				n += 1
				fn(p)
				if n % 300 == 0 then
					task.wait()
				end
			end
		end
	end
end

-- the columns under a piece, written down to `top - SINK`
local function dig(p: BasePart)
	local t = workspace.Terrain
	local cf, s = p.CFrame, p.Size
	local top = p.Position.Y + cf.UpVector.Y * s.Y / 2
	local rx, rz = s.X / 2 + MARGIN, s.Z / 2 + MARGIN
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, q in { { 1, 1 }, { 1, -1 }, { -1, -1 }, { -1, 1 } } do
		local w = cf * Vector3.new(q[1] * rx, 0, q[2] * rz)
		minX, maxX = math.min(minX, w.X), math.max(maxX, w.X)
		minZ, maxZ = math.min(minZ, w.Z), math.max(maxZ, w.Z)
	end
	local limit = top - SINK
	local y0 = floorTo(limit - C)
	local y1 = floorTo(limit + 64) + C -- (a hill over the paving comes away whole, no overhang)
	local region = Region3.new(Vector3.new(floorTo(minX), y0, floorTo(minZ)), Vector3.new(floorTo(maxX) + C, y1, floorTo(maxZ) + C))
	local mats, occ = t:ReadVoxels(region, C)
	local sz = mats.Size
	local changed = false
	for ix = 1, sz.X do
		local wx = floorTo(minX) + (ix - 0.5) * C
		for iz = 1, sz.Z do
			local wz = floorTo(minZ) + (iz - 0.5) * C
			local q = cf:PointToObjectSpace(Vector3.new(wx, p.Position.Y, wz))
			if math.abs(q.X) <= rx and math.abs(q.Z) <= rz then
				for iy = 1, sz.Y do
					local yc = y0 + (iy - 0.5) * C
					local cap = math.clamp((limit - (yc - C / 2)) / C, 0, 1)
					if occ[ix][iy][iz] > cap then
						occ[ix][iy][iz] = cap
						if cap <= 0 then
							mats[ix][iy][iz] = Enum.Material.Air
						end
						changed = true
					end
				end
			end
		end
	end
	if changed then
		t:WriteVoxels(region, C, mats, occ)
	end
end

function PaveDig.check(roads: Instance): (number, number)
	local params = terrainOnly()
	local count, hits = 0, 0
	each(roads, function(p)
		local h = over(p, params)
		if h > 0 then
			count += 1
			hits += h
		end
	end)
	return count, if count > 0 then hits / count / (GRID * GRID) else 0
end

function PaveDig.run(roads: Instance): number
	local params = terrainOnly()
	local dug = 0
	each(roads, function(p)
		if over(p, params) > 0 then
			dig(p)
			dug += 1
		end
	end)
	return dug
end

return PaveDig
