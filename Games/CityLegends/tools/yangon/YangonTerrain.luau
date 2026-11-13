-- Yangon map, build step 2: the ground (13 Nov 2026).
-- Smooth terrain from the smoothed ground grid, Inya Lake and the ponds as water.
-- Data: ServerStorage.YangonData.Terrain (a JSON string). Load as a ModuleScript and require a :Clone().
--   local T = require(game.ServerStorage.YangonData.Tools.YangonTerrain:Clone())
--   T.prepare()            -- once per require: reads the data, works out the water rows
--   T.run(first, count)    -- writes tiles first .. first+count-1 (782 in all), returns a status line
--   T.clear()              -- puts air back over the whole Yangon box
local M = {}
local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")

M.OX, M.OZ, M.SPM, M.VS = 30000, 0, 1.6, 1.6
M.X0, M.X1 = 27648, 33536 -- world studs, multiples of 256
M.Z0, M.Z1 = -6656, 2048
M.TOP = 64 -- highest terrain written (studs)
M.TILE = 256
M.LAKE_Y = 16 * 1.6 -- water surface
M.BED_DROP = 10 -- lake bed below the water surface
M.UNDER = 1.0 -- ground sits this far under the road height, so road slabs stand proud of it
M.SOLID_LIFT = 2 -- measured 13 Nov 2026: smooth solid terrain shows 2 studs (half a voxel) above bottom + occupancy x 4; water does not
M.NX = (M.X1 - M.X0) / M.TILE
M.NZ = (M.Z1 - M.Z0) / M.TILE

local D, rows

function M.prepare()
	D = Http:JSONDecode(require(SS.YangonData.Terrain:Clone()))
	-- water: D.water is a list of water bodies, each a list of outlines (the shore first, then its islands).
	-- For every 4-stud row (z) and every water body: the sorted x where its outlines are crossed.
	-- A column is water when it is inside any one body (odd number of crossings to its left).
	rows = {}
	local nrow = (M.Z1 - M.Z0) / 4
	for i = 1, nrow do rows[i] = {} end
	local crossings = 0
	for bi, body in ipairs(D.water) do
		for _, ring in ipairs(body) do
			local n = #ring / 2
			for k = 1, n do
				local k2 = k % n + 1
				local ax, az = M.OX + ring[2 * k - 1] * M.SPM, M.OZ - ring[2 * k] * M.SPM
				local bx, bz = M.OX + ring[2 * k2 - 1] * M.SPM, M.OZ - ring[2 * k2] * M.SPM
				if az ~= bz then
					if az > bz then ax, az, bx, bz = bx, bz, ax, az end
					local i0 = math.ceil((az - M.Z0 - 2) / 4) + 1
					local i1 = math.ceil((bz - M.Z0 - 2) / 4)
					for i = math.max(i0, 1), math.min(i1, nrow) do
						local zc = M.Z0 + (i - 1) * 4 + 2
						local list = rows[i][bi]
						if not list then list = {}; rows[i][bi] = list end
						table.insert(list, ax + (bx - ax) * (zc - az) / (bz - az))
						crossings += 1
					end
				end
			end
		end
	end
	for i = 1, nrow do
		local packed = {}
		for _, list in pairs(rows[i]) do table.sort(list); table.insert(packed, list) end
		rows[i] = packed
	end
	return string.format("grid %d x %d, %d water bodies, %d row crossings, %d tiles", D.nx, D.ny, #D.water, crossings, M.NX * M.NZ)
end

-- ground height in studs at a world position (the same bilinear grid the road heights come from)
function M.height(X, Z)
	local x, y = (X - M.OX) / M.SPM, (M.OZ - Z) / M.SPM
	local fi = math.clamp((x - D.x0) / D.dx, 0, D.nx - 1.001)
	local fj = math.clamp((y - D.y0) / D.dy, 0, D.ny - 1.001)
	local i, j = math.floor(fi), math.floor(fj)
	local a, b = fi - i, fj - j
	local h = D.h
	local r0, r1 = j * D.nx + i + 1, (j + 1) * D.nx + i + 1
	return (h[r0] * (1 - a) * (1 - b) + h[r0 + 1] * a * (1 - b) + h[r1] * (1 - a) * b + h[r1 + 1] * a * b) * M.VS
end

local function wet(row, X)
	for _, list in ipairs(row) do
		if list[1] <= X and list[#list] > X then
			local c = 0
			for _, x in ipairs(list) do
				if x <= X then c += 1 else break end
			end
			if c % 2 == 1 then return true end
		end
	end
	return false
end
M.isWater = function(X, Z)
	local i = math.floor((Z - M.Z0) / 4) + 1
	return rows[i] ~= nil and wet(rows[i], X)
end

function M.tile(tx, tz)
	local X0, Z0 = M.X0 + tx * M.TILE, M.Z0 + tz * M.TILE
	local n, ny = M.TILE / 4, M.TOP / 4
	local mats, occ = table.create(n), table.create(n)
	local AIR, GRASS, SAND, WATER = Enum.Material.Air, Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Water
	local bed = M.LAKE_Y - M.BED_DROP
	local waterCols = 0
	for ix = 1, n do
		local X = X0 + (ix - 1) * 4 + 2
		local mx, ox = table.create(ny), table.create(ny)
		for iy = 1, ny do mx[iy] = table.create(n, AIR); ox[iy] = table.create(n, 0) end
		for iz = 1, n do
			local Z = Z0 + (iz - 1) * 4 + 2
			local row = rows[(Z0 - M.Z0) / 4 + iz]
			if wet(row, X) then
				waterCols += 1
				for iy = 1, ny do
					local yb = (iy - 1) * 4
					local s = math.clamp((bed - M.SOLID_LIFT - yb) / 4, 0, 1)
					if s > 0 then
						mx[iy][iz] = SAND; ox[iy][iz] = s
					else
						local w = math.clamp((M.LAKE_Y - yb) / 4, 0, 1)
						if w > 0 then mx[iy][iz] = WATER; ox[iy][iz] = w end
					end
				end
			else
				local top = M.height(X, Z) - M.UNDER - M.SOLID_LIFT
				for iy = 1, ny do
					local g = math.clamp((top - (iy - 1) * 4) / 4, 0, 1)
					if g <= 0 then break end
					mx[iy][iz] = GRASS; ox[iy][iz] = g
				end
			end
		end
		mats[ix] = mx; occ[ix] = ox
	end
	local region = Region3.new(Vector3.new(X0, 0, Z0), Vector3.new(X0 + M.TILE, M.TOP, Z0 + M.TILE))
	workspace.Terrain:WriteVoxels(region, 4, mats, occ)
	return waterCols
end

function M.run(first, count)
	local t0 = os.clock()
	local total = M.NX * M.NZ
	local last = math.min(first + count - 1, total)
	local wetCols = 0
	for k = first, last do
		local tx, tz = (k - 1) % M.NX, math.floor((k - 1) / M.NX)
		wetCols += M.tile(tx, tz)
		task.wait()
	end
	return string.format("tiles %d..%d of %d written in %.1f s, %d water columns", first, last, total, os.clock() - t0, wetCols)
end

function M.clear()
	for tz = 0, M.NZ - 1 do
		for tx = 0, M.NX - 1 do
			local X0, Z0 = M.X0 + tx * M.TILE, M.Z0 + tz * M.TILE
			workspace.Terrain:FillBlock(CFrame.new(X0 + 128, M.TOP / 2, Z0 + 128), Vector3.new(256, M.TOP, 256), Enum.Material.Air)
		end
		task.wait()
	end
	return "cleared"
end

return M
