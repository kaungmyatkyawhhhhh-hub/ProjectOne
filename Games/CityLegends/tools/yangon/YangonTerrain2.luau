--[[
	YangonTerrain2 (Studio, Edit mode; whole-Yangon city generator, 14 Nov 2026): writes a batch's ground made by
	tools/yangon/city/terrain.py (heights, road beds, water) tile by tile with WriteVoxelChannels (solid and liquid both set).

	Data: ModuleScripts ServerStorage.ClaudeTools.Terrain<tag>_1..n (one string each), a line per 256-stud tile:
		"tx tz F|P <base>|<codes>|<explicit>"   (format in terrain.py's header)
	F tiles: every column is ours: written from YB up to just over the highest column, air from there to YTOP (FillBlock).
	P tiles: some columns are kept (batch 0.5's box and its road corridors, anything outside the batch): the tile is read
	(ReadVoxelChannels YB..YTOP), only our columns change, and it is written back.
	A column's top is the height the terrain SHOWS at: smooth solid terrain shows SOLID_LIFT (2) over bottom + occupancy x 4
	(measured 13 Nov 2026, YangonTerrain.luau), so the solid fill stops 2 under it; water fills to its level (no lift).

	local T = require(game.ServerStorage.ClaudeTools.YangonTerrain2:Clone())
	T.spawn("Terrain1_")          -- resumable: carries on after the last tile done (attribute Terrain2Done_<prefix> on
	                              -- ServerStorage.YangonData); T.spawn("Terrain1_", 1) starts again from tile 1
	T.status()                    -- "running k/n ..." / "done ..." / "ERROR ..."
	T.stop()                      -- stops after the tile being written
	T.probe({ {x, z}, ... })      -- terrain heights (water ignored) for checks
]]

local SS = game:GetService("ServerStorage")

local M = {}
M.YB = -24
M.YTOP = 200
M.TILE = 256
M.SOLID_LIFT = 2

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end
local byte, sub = string.byte, string.sub

local function h2(s: string, i: number): number
	return (VAL[byte(s, i)] * 64 + VAL[byte(s, i + 1)]) / 10 - 40
end

local MAT = {
	g = Enum.Material.Grass,
	h = Enum.Material.Grass,
	m = Enum.Material.Mud,
	n = Enum.Material.Mud,
	w = Enum.Material.Mud,
	v = Enum.Material.Sand,
}
local AIR, WATER = Enum.Material.Air, Enum.Material.Water

function M.load(prefix: string): { string }
	local lines = {}
	local CT = SS.ClaudeTools
	for k = 1, 999 do
		local m = CT:FindFirstChild(prefix .. k)
		if not m then
			break
		end
		local s = require(m:Clone())
		for line in string.gmatch(s, "[^\n]+") do
			table.insert(lines, line)
		end
	end
	return lines
end

-- decode a tile line -> X0, Z0, full, codes[4096], tops[4096], levels[4096] (column k = ix * 64 + iz, 1-based k + 1)
function M.decode(line: string)
	local tx, tz, kind, base, rle, ex = string.match(line, "^(%-?%d+) (%-?%d+) (%a) ([^|]*)|([^|]*)|(.*)$")
	assert(tx, "bad tile line")
	local X0, Z0 = tonumber(tx) * M.TILE, tonumber(tz) * M.TILE
	local B = table.create(289)
	for k = 0, 288 do
		B[k + 1] = h2(base, 2 * k + 1)
	end
	local codes = table.create(4096)
	local pos = 1
	for i = 1, #rle, 2 do
		local c = sub(rle, i, i)
		local n = VAL[byte(rle, i + 1)] + 1
		for _ = 1, n do
			codes[pos] = c
			pos += 1
		end
	end
	assert(pos == 4097, "codes " .. (pos - 1))
	local tops, levels = table.create(4096, 0), table.create(4096, 0)
	local ep = 1
	for k = 0, 4095 do
		local c = codes[k + 1]
		if c == "g" or c == "m" then
			local ix, iz = k // 64, k % 64
			local fx, fz = (ix * 4 + 2) / 16, (iz * 4 + 2) / 16
			local i, j = math.min(math.floor(fx), 15), math.min(math.floor(fz), 15)
			local a, b = fx - i, fz - j
			tops[k + 1] = B[i * 17 + j + 1] * (1 - a) * (1 - b) + B[(i + 1) * 17 + j + 1] * a * (1 - b)
				+ B[i * 17 + j + 2] * (1 - a) * b + B[(i + 1) * 17 + j + 2] * a * b
		elseif c == "h" or c == "n" then
			tops[k + 1] = h2(ex, ep)
			ep += 2
		elseif c == "w" or c == "v" then
			tops[k + 1] = h2(ex, ep)
			levels[k + 1] = h2(ex, ep + 2)
			ep += 4
		end
	end
	assert(ep == #ex + 1, "explicit " .. ep .. " / " .. #ex)
	return X0, Z0, kind == "F", codes, tops, levels
end

-- one column's layers into the x slice (sm / so / lo: [iy][iz]) of the SolidMaterial / SolidOccupancy / LiquidOccupancy
-- channels. Every channel is written: a plain WriteVoxels with Water only sets the liquid and keeps the solid that was there
-- (found 14 Nov 2026: the old skirt's grass stood up through the new river), so a water layer gets solid Air explicitly.
local function column(sm, so, lo, iz: number, ny: number, c: string, top: number, lv: number)
	local s = top - M.SOLID_LIFT
	local solid = MAT[c]
	local wet = c == "w" or c == "v"
	for iy = 1, ny do
		local yb = M.YB + (iy - 1) * 4
		local o = (s - yb) / 4
		if o >= 1 then
			sm[iy][iz], so[iy][iz], lo[iy][iz] = solid, 1, 0
		elseif o > 0.01 then
			sm[iy][iz], so[iy][iz], lo[iy][iz] = solid, o, 0
		elseif wet and lv > yb then
			sm[iy][iz], so[iy][iz], lo[iy][iz] = AIR, 0, math.min((lv - yb) / 4, 1)
		else
			sm[iy][iz], so[iy][iz], lo[iy][iz] = AIR, 0, 0
		end
	end
end

local CH = { "SolidMaterial", "SolidOccupancy", "LiquidOccupancy" }

function M.tile(line: string): (number, boolean)
	local X0, Z0, full, codes, tops, levels = M.decode(line)
	local T = workspace.Terrain
	if full then
		local hi = M.YB + 8
		for k = 1, 4096 do
			hi = math.max(hi, tops[k], levels[k])
		end
		local YT = math.min(M.YTOP, math.ceil((hi + 6) / 4) * 4)
		local ny = (YT - M.YB) / 4
		local SM, SO, LO = table.create(64), table.create(64), table.create(64)
		for ix = 1, 64 do
			local sm, so, lo = table.create(ny), table.create(ny), table.create(ny)
			for iy = 1, ny do
				sm[iy] = table.create(64, AIR)
				so[iy] = table.create(64, 0)
				lo[iy] = table.create(64, 0)
			end
			for iz = 1, 64 do
				local k = (ix - 1) * 64 + iz
				column(sm, so, lo, iz, ny, codes[k], tops[k], levels[k])
			end
			SM[ix], SO[ix], LO[ix] = sm, so, lo
		end
		T:WriteVoxelChannels(Region3.new(Vector3.new(X0, M.YB, Z0), Vector3.new(X0 + M.TILE, YT, Z0 + M.TILE)), 4,
			{ SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO })
		if YT < M.YTOP then
			T:FillBlock(CFrame.new(X0 + M.TILE / 2, (YT + M.YTOP) / 2, Z0 + M.TILE / 2), Vector3.new(M.TILE, M.YTOP - YT, M.TILE), AIR)
		end
		return 4096, true
	end
	local region = Region3.new(Vector3.new(X0, M.YB, Z0), Vector3.new(X0 + M.TILE, M.YTOP, Z0 + M.TILE))
	local ch = T:ReadVoxelChannels(region, 4, CH)
	local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
	local ny = (M.YTOP - M.YB) / 4
	local n = 0
	for ix = 1, 64 do
		local sm, so, lo = SM[ix], SO[ix], LO[ix]
		for iz = 1, 64 do
			local k = (ix - 1) * 64 + iz
			local c = codes[k]
			if c ~= "." then
				column(sm, so, lo, iz, ny, c, tops[k], levels[k])
				n += 1
			end
		end
	end
	T:WriteVoxelChannels(region, 4, { SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO })
	return n, false
end

local function YD()
	return SS:FindFirstChild("YangonData") or SS
end

function M.spawn(prefix: string, from: number?, to: number?)
	local yd = YD()
	yd:SetAttribute("Terrain2Status", "running (loading)")
	yd:SetAttribute("Terrain2Stop", false)
	task.spawn(function()
		local t0 = os.clock()
		local cols, nf, np = 0, 0, 0
		local ok, err = xpcall(function()
			local lines = M.load(prefix)
			local start = from or ((yd:GetAttribute("Terrain2Done_" .. prefix) or 0) + 1)
			local last = math.min(to or #lines, #lines)
			for k = start, last do
				if yd:GetAttribute("Terrain2Stop") then
					break
				end
				local c, full = M.tile(lines[k])
				cols += c
				if full then
					nf += 1
				else
					np += 1
				end
				yd:SetAttribute("Terrain2Done_" .. prefix, k)
				yd:SetAttribute("Terrain2Status", string.format("running %d/%d (%.0f s)", k, #lines, os.clock() - t0))
				task.wait()
			end
			return #lines
		end, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		yd:SetAttribute("Terrain2Status", string.format("%s after %.0f s: %d full + %d partial tiles, %d columns, last done %s %s",
			if ok then "done" else "ERROR", os.clock() - t0, nf, np, cols, tostring(yd:GetAttribute("Terrain2Done_" .. prefix)),
			if ok then "of " .. tostring(err) else tostring(err)))
	end)
end

function M.status(): string
	return tostring(YD():GetAttribute("Terrain2Status"))
end

function M.stop()
	YD():SetAttribute("Terrain2Stop", true)
end

function M.probe(points: { { number } }): { number? }
	local tp = RaycastParams.new()
	tp.FilterType = Enum.RaycastFilterType.Include
	tp.FilterDescendantsInstances = { workspace.Terrain }
	tp.IgnoreWater = true
	local out = {}
	for i, p in points do
		local h = workspace:Raycast(Vector3.new(p[1], 600, p[2]), Vector3.new(0, -900, 0), tp)
		out[i] = h and h.Position.Y or nil
	end
	return out
end

return M
