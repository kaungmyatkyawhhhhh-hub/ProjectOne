--[[
	HighwayTerrain (Studio, Edit mode; 2026-11-04): writes the ground changed for the Riviera Highway
	(tools/map_plan/highway_terrain.py) into the open place. Per terrain tile it reads the place's own
	voxels, rewrites only the columns listed (new height and top material: the road bed, the rock
	cuttings, the embankments) and leaves every other column as it is.

	Serve Games/CityLegends/build on port 34999, then:
	  HighwayTerrain.run("http://127.0.0.1:34999/riviera_hw/", from, count) -> report
]]

local HighwayTerrain = {}

local Http = game:GetService("HttpService")

function HighwayTerrain.run(base: string, from: number?, count: number?): string
	local T = workspace.Terrain
	local index = Http:JSONDecode(Http:GetAsync(base .. "index.json", true))
	local MATS = {}
	for ch, name in index.mats do
		MATS[ch] = Enum.Material[name]
	end
	local C = index.cell
	local first = from or 1
	local last = math.min(first + (count or #index.tiles) - 1, #index.tiles)
	local cols = 0
	for n = first, last do
		local tile = Http:JSONDecode(Http:GetAsync(base .. index.tiles[n], true))
		-- the tile's box (cells) and the height range touched
		local i0, j0, i1, j1 = math.huge, math.huge, -math.huge, -math.huge
		local lo, hi = math.huge, -math.huge
		for _, c in tile.cols do
			i0, i1 = math.min(i0, c[1]), math.max(i1, c[1])
			j0, j1 = math.min(j0, c[2]), math.max(j1, c[2])
			local h = c[3] / 4
			lo, hi = math.min(lo, h), math.max(hi, h)
		end
		local x0 = index.x0 + i0 * C
		local z0 = index.z0 + j0 * C
		local w, d = i1 - i0 + 1, j1 - j0 + 1
		-- read high enough to clear what a cut takes away (the old ground can be ~150 higher)
		local y0 = math.floor(lo / C) * C - C * 3
		local y1 = math.ceil(math.max(hi, 0) / C) * C + (index.above or 220)
		y1 = y0 + math.ceil((y1 - y0) / C) * C
		local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x0 + w * C, y1, z0 + d * C))
		local mats, occs = T:ReadVoxels(region, C)
		local ny = #mats[1]
		for _, c in tile.cols do
			local ix, iz = c[1] - i0 + 1, c[2] - j0 + 1
			local h = c[3] / 4
			local top = MATS[c[4]] or Enum.Material.Ground
			local deep = if top == Enum.Material.Limestone or top == Enum.Material.Rock then top else Enum.Material.Rock
			local mx, ox = mats[ix], occs[ix]
			for iy = 1, ny do
				local yb = y0 + (iy - 1) * C
				local fill = (h - yb) / C
				if fill > 0 then
					mx[iy][iz] = if h - yb < C * 2.5 then top else deep
					ox[iy][iz] = math.min(fill, 1)
				elseif yb < 0 then
					mx[iy][iz] = Enum.Material.Water
					ox[iy][iz] = math.clamp(-yb / C, 0, 1)
				else
					mx[iy][iz] = Enum.Material.Air
					ox[iy][iz] = 0
				end
			end
			cols += 1
		end
		T:WriteVoxels(region, C, mats, occs)
		task.wait(0.15)
	end
	return string.format("tiles %d..%d of %d, %d columns written", first, last, #index.tiles, cols)
end

return HighwayTerrain
