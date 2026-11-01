--[[
	Writes the Riviera terrain into the open Studio place (Edit mode, MCP execute_luau or the
	command bar). Reads build/riviera/meta.json and tile_*.json from a local server:
	    cd Games/CityLegends/build && python -m http.server 34999 --bind 127.0.0.1
	Run it with FROM / COUNT for a batch of tiles (HttpService allows ~500 requests a minute, so
	it waits 0.13 s per tile; ~300 tiles a run), then TUNNELS = true once to carve the tunnels.
	The data is made by tools/map_plan/terrain_build.py.
]]
local FROM, COUNT, TUNNELS = 1, 300, false
local BASE = "http://127.0.0.1:34999/riviera/"

local Http = game:GetService("HttpService")
local T = workspace.Terrain
Http.HttpEnabled = true
local t0 = os.clock()
local ok, result = pcall(function()
	local meta = Http:JSONDecode(Http:GetAsync(BASE .. "meta.json", true))
	local MATS = {}
	for ch, name in meta.mats do
		MATS[ch] = Enum.Material[name]
	end
	local CELL = meta.cell
	local last = FROM - 1
	for n = FROM, math.min(FROM + COUNT - 1, #meta.tiles) do
		local tile = Http:JSONDecode(Http:GetAsync(BASE .. meta.tiles[n], true))
		local w, d = tile.w, tile.d
		local lo, hi = 0, 0
		for _, q in tile.h do
			local v = q / 4
			lo = math.min(lo, v)
			hi = math.max(hi, v)
		end
		local y0 = math.floor(lo / CELL) * CELL - CELL * 2
		local y1 = math.ceil(math.max(hi, 0) / CELL) * CELL + CELL * 12 -- clears what stood above too
		local ny = (y1 - y0) // CELL
		local mats, occs = table.create(w), table.create(w)
		for ix = 1, w do
			local mx, ox = table.create(ny), table.create(ny)
			for iy = 1, ny do
				mx[iy] = table.create(d, Enum.Material.Air)
				ox[iy] = table.create(d, 0)
			end
			mats[ix], occs[ix] = mx, ox
		end
		for iz = 1, d do
			for ix = 1, w do
				local k = (iz - 1) * w + ix
				local h = tile.h[k] / 4
				local top = MATS[string.sub(tile.m, k, k)] or Enum.Material.Grass
				local deep = if top == Enum.Material.Limestone or top == Enum.Material.Rock then top else Enum.Material.Rock
				local mx, ox = mats[ix], occs[ix]
				for iy = 1, ny do
					local yb = y0 + (iy - 1) * CELL
					local fill = (h - yb) / CELL
					if fill > 0 then
						mx[iy][iz] = if h - yb < CELL * 2.5 then top else deep
						ox[iy][iz] = math.min(fill, 1)
					elseif yb < 0 then
						mx[iy][iz] = Enum.Material.Water
						ox[iy][iz] = math.clamp(-yb / CELL, 0, 1)
					end
				end
			end
		end
		local x0 = meta.x0 + tile.i * CELL
		local z0 = meta.z0 + tile.j * CELL
		T:WriteVoxels(Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x0 + w * CELL, y1, z0 + d * CELL)), CELL, mats, occs)
		last = n
		task.wait(0.13)
	end
	if TUNNELS then
		for _, t in meta.tunnels do
			local pos = Vector3.new(t[1], t[2], t[3])
			local dir = Vector3.new(t[4], 0, t[5])
			if dir.Magnitude > 0 then
				local cf = CFrame.lookAt(pos, pos + dir)
				T:FillBlock(cf * CFrame.new(0, 16, 0), Vector3.new(80, 32, 10), Enum.Material.Air)
				T:FillBlock(cf * CFrame.new(0, -3, 0), Vector3.new(72, 6, 10), Enum.Material.Asphalt)
			end
		end
	end
	return string.format("wrote %d..%d of %d in %.1fs%s", FROM, last, #meta.tiles, os.clock() - t0, if TUNNELS then " + tunnels" else "")
end)
Http.HttpEnabled = false
return if ok then result else "ERR " .. tostring(result)
