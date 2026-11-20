--[[
	RoadBedDeepen (21 Nov 2026). Studio, Edit. Only writes Workspace.Terrain (Air). Re-runnable.

	WHY (the theory this was built on; see RESULT below, it did not hold): the road meshes (Yangon1to1.Roads.Meshes.Cell_<x>x<z>) sat only 1 to 4 studs over the terrain bed carved
	for them. Far from the camera Roblox draws terrain at a coarser LOD whose surface rises over the road, so far
	roads showed as grass with only the kerbs left (owner: "the map loading is bugged"). Not a mesh loading fault:
	the same mesh lifted 3 to 6 studs is visible. Fix: deepen the bed under the road surface.

	HOW: per 1536 cell, the ground-level collision boxes (RCol, RoadBox R / P; D decks have no ground) are drawn
	into a 4-stud column mask with the box top's height. A column is carved only when every column within MARGIN
	of it is covered too (so the trench stays under the road, never beside a kerb / verge), has no Water in the
	cut, and its terrain is within MAX_GAP under the road (ramps / bridges are left alone). Voxels from the road
	top down to D under it become Air.

	local R = require(ServerStorage.ClaudeTools.RoadBedDeepen:Clone())
	R.backup(23, 29)                      -- TerrainRegion into ServerStorage.TerrainBackup_21Nov (R.restore undoes)
	task.spawn(R.run, { { 23, 29 } })     -- or R.run() for every cell in Roads.Meshes; poll R.S (also _G.RoadBedDeepen)
	R.cell(23, 29, true)                  -- dry run: counts only

	RESULT (21 Nov, read before running again): NO PROVEN BENEFIT. In Edit the "grass over far roads" is the
	terrain LOD still refining after a camera jump: hold the camera 25 s and the ORIGINAL terrain shows the roads
	900 studs off. With the same jump + 4 s wait, original and D = 10 look the same (far roads hidden in both);
	D = 40 (no terrain under the road at all) showed a little more but opened a see-through patch. Early shots
	that seemed to show D = 10 beating D = 6 only differed in how long the camera had been there.
	State of the place: every Roads.Meshes cell EXCEPT 23x29 was carved at D = 10, MARGIN 1 (4.23 M voxels);
	23x29 was restored from its backup. Close-ups at a kerb and a grass edge were identical before / after.
	A second run with the same D changes nothing.
	shortcut: a re-run with a BIGGER D skips already-carved columns (they now fail MAX_GAP); raise MAX_GAP by the
	old D for that run.
]]
local T = workspace.Terrain
local M = {}
M.D = 10 -- studs of Air under the road top
M.MARGIN = 1 -- columns (4 studs each) kept uncarved inside the road's edge
M.MAX_GAP = 6 -- road top more than this over the terrain = ramp / bridge: skip
M.KINDS = { R = true, P = true }
M.CELL = 1536
M.S = { state = "idle", cells = 0, total = 0, boxes = 0, columns = 0, voxels = 0, water = 0, gap = 0 }
_G.RoadBedDeepen = M.S

local floor, abs, max, min = math.floor, math.abs, math.max, math.min
local AIR, WATER = Enum.Material.Air, Enum.Material.Water

function M.index()
	if M.idx then
		return M.idx
	end
	local idx = {}
	local pad = (M.MARGIN + 1) * 4
	for i, p in workspace.Yangon1to1.Roads.Collide:GetChildren() do
		if p.Name == "RCol" and M.KINDS[p:GetAttribute("RoadBox")] then
			local cf, s = p.CFrame, p.Size
			local r, l = cf.RightVector, cf.LookVector
			local ex = abs(r.X) * s.X / 2 + abs(l.X) * s.Z / 2 + pad
			local ez = abs(r.Z) * s.X / 2 + abs(l.Z) * s.Z / 2 + pad
			for cx = floor((cf.X - ex) / M.CELL), floor((cf.X + ex) / M.CELL) do
				for cz = floor((cf.Z - ez) / M.CELL), floor((cf.Z + ez) / M.CELL) do
					local key = cx .. "x" .. cz
					local t = idx[key]
					if not t then
						t = {}
						idx[key] = t
					end
					t[#t + 1] = p
				end
			end
		end
		if i % 20000 == 0 then
			task.wait()
		end
	end
	M.idx = idx
	return idx
end

-- the cell's column mask: top[ix * W + iz + 1] = lowest road top over that column (false = no road)
local function mask(cx: number, cz: number)
	local list = M.index()[cx .. "x" .. cz]
	if not list then
		return nil
	end
	local B = M.MARGIN + 1
	local N = M.CELL / 4
	local W = N + 2 * B
	local x0, z0 = cx * M.CELL - B * 4, cz * M.CELL - B * 4
	local top = table.create(W * W, false)
	for _, p in list do
		local cf, s = p.CFrame, p.Size
		local pos, r, l, u = cf.Position, cf.RightVector, cf.LookVector, cf.UpVector
		local hx, hz = s.X / 2, s.Z / 2
		local ex = abs(r.X) * hx + abs(l.X) * hz
		local ez = abs(r.Z) * hx + abs(l.Z) * hz
		local tc = pos + u * (s.Y / 2)
		for ix = max(0, floor((pos.X - ex - x0) / 4)), min(W - 1, floor((pos.X + ex - x0) / 4)) do
			local x = x0 + (ix + 0.5) * 4
			local dx = x - pos.X
			for iz = max(0, floor((pos.Z - ez - z0) / 4)), min(W - 1, floor((pos.Z + ez - z0) / 4)) do
				local z = z0 + (iz + 0.5) * 4
				local dz = z - pos.Z
				if abs(dx * r.X + dz * r.Z) <= hx and abs(dx * l.X + dz * l.Z) <= hz then
					local y = tc.Y - (u.X * (x - tc.X) + u.Z * (z - tc.Z)) / u.Y
					local k = ix * W + iz + 1
					local o = top[k]
					if not o or y < o then
						top[k] = y
					end
				end
			end
		end
	end
	return top, W, B, N, x0, z0, #list
end

function M.cell(cx: number, cz: number, dry: boolean?)
	local top, W, B, N, x0, z0, nBoxes = mask(cx, cz)
	if not top then
		return 0
	end
	local S, m, D = M.S, M.MARGIN, M.D
	S.boxes += nBoxes
	local TILE = 64
	for tx = 0, N / TILE - 1 do
		for tz = 0, N / TILE - 1 do
			local ia, ka = B + tx * TILE, B + tz * TILE
			local cols, ymin, ymax = {}, math.huge, -math.huge
			for ix = ia, ia + TILE - 1 do
				for iz = ka, ka + TILE - 1 do
					local y = top[ix * W + iz + 1]
					if y then
						local inside = true
						for ax = ix - m, ix + m do
							for az = iz - m, iz + m do
								if not top[ax * W + az + 1] then
									inside = false
								end
							end
						end
						if inside then
							cols[#cols + 1] = { ix - ia + 1, iz - ka + 1, y }
							ymin, ymax = min(ymin, y), max(ymax, y)
						end
					end
				end
			end
			if #cols > 0 then
				local ylo, yhi = floor((ymin - D - 4) / 4) * 4, math.ceil((ymax + 4) / 4) * 4
				local region = Region3.new(Vector3.new(x0 + ia * 4, ylo, z0 + ka * 4), Vector3.new(x0 + (ia + TILE) * 4, yhi, z0 + (ka + TILE) * 4))
				local mats, occ = T:ReadVoxels(region, 4)
				local ny = (yhi - ylo) / 4
				local changed = 0
				for _, c in cols do
					local mc, oc, k, y = mats[c[1]], occ[c[1]], c[2], c[3]
					local hi, lo = y + 2, y - D
					local j1 = min(ny, floor((hi - ylo) / 4 + 0.5)) -- highest voxel whose centre is <= hi
					local j0 = max(1, floor((lo - ylo) / 4 + 0.5) + 1) -- lowest voxel whose centre is > lo
					local surf, water = nil, false
					for j = j1, 1, -1 do
						local mat = mc[j][k]
						if mat == WATER then
							water = j >= j0
							break
						elseif mat ~= AIR and oc[j][k] > 0 then
							surf = ylo + (j - 0.5) * 4
							break
						end
					end
					for j = j0, j1 do
						if mc[j][k] == WATER then
							water = true
						end
					end
					if water then
						S.water += 1
					elseif surf and y - surf > M.MAX_GAP + 2 then
						S.gap += 1
					elseif surf then
						local n = 0
						for j = j0, j1 do
							if mc[j][k] ~= AIR then
								mc[j][k] = AIR
								oc[j][k] = 0
								n += 1
							end
						end
						if n > 0 then
							S.columns += 1
							changed += n
						end
					end
				end
				if changed > 0 then
					S.voxels += changed
					if not dry then
						T:WriteVoxels(region, 4, mats, occ)
					end
					task.wait()
				end
			end
		end
	end
	return nBoxes
end

-- cells = { { cx, cz }, ... }; nil = every Cell_<x>x<z> in Roads.Meshes
function M.run(cells: { { number } }?, dry: boolean?)
	local S = M.S
	if not cells then
		cells = {}
		for _, c in workspace.Yangon1to1.Roads.Meshes:GetChildren() do
			local x, z = c.Name:match("^Cell_(%-?%d+)x(%-?%d+)$")
			if x then
				cells[#cells + 1] = { tonumber(x), tonumber(z) }
			end
		end
	end
	S.state, S.cells, S.total, S.err = "index", 0, #cells, nil
	local ok, err = pcall(function()
		M.index()
		S.state = "carving"
		for _, c in cells do
			S.cur = c[1] .. "x" .. c[2]
			M.cell(c[1], c[2], dry)
			S.cells += 1
			task.wait()
		end
	end)
	S.state = if ok then "done" else "error"
	S.err = if ok then nil else tostring(err)
end

local function backupFolder()
	local f = game.ServerStorage:FindFirstChild("TerrainBackup_21Nov")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TerrainBackup_21Nov"
		f.Parent = game.ServerStorage
	end
	return f
end

-- the cell's terrain (voxel rows y0..y1, studs) as a TerrainRegion; M.restore pastes it back
function M.backup(cx: number, cz: number, y0: number?, y1: number?)
	local n = M.CELL / 4
	local a = Vector3int16.new(cx * n, floor((y0 or -40) / 4), cz * n)
	local reg = T:CopyRegion(Region3int16.new(a, Vector3int16.new(cx * n + n, floor((y1 or 120) / 4), cz * n + n)))
	reg.Name = "Cell_" .. cx .. "x" .. cz
	reg:SetAttribute("Corner", Vector3.new(a.X, a.Y, a.Z))
	local f = backupFolder()
	local old = f:FindFirstChild(reg.Name)
	if old then
		old:Destroy()
	end
	reg.Parent = f
	return reg
end

function M.restore(cx: number, cz: number)
	local reg = backupFolder():FindFirstChild("Cell_" .. cx .. "x" .. cz)
	assert(reg, "no backup for this cell")
	local c = reg:GetAttribute("Corner")
	T:PasteRegion(reg, Vector3int16.new(c.X, c.Y, c.Z), true)
end

return M
