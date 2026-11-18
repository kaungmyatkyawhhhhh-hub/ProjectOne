--[[
	MapBugScan (19 Nov 2026, map bug fixes after the J37 P1-P3 rebuild): Studio scans of the whole P1-P3 for
	  (a) terrain over a road / pavement box, and stray terrain near the flyovers (ridges over the local ground, floating blobs)
	  (b) kit props (Data_* tiles) on road asphalt: see KitOnRoad below
	  (c) invisible collidable parts
	ModuleScript in ServerStorage.ClaudeTools; require a :Clone(). Edit mode only. Each scan runs in task.spawn and writes
	its state into _G.MBS (poll _G.MBS.status).

	S.terrainScan(apply)  -- (a) counts; apply = true clears what it found (FillBlock Air / WriteVoxels)
	S.kitScan()           -- (b) records on R boxes per folder, kept in _G.MBS.kit
	S.kitApply()          -- (b) removes them from the tiles (compact "!" tiles are stored expanded), returns @KT dump lines
]]

local S = {}

local AREAS = { { 18, 25, 10, 22 }, { 19, 28, 26, 32 } } -- 1536 cells (x0, x1, z0, z1): P1 + P2, P3
local CELL = 1536
function S.inArea(x: number, z: number): boolean
	local cx, cz = x / CELL, z / CELL
	for _, a in AREAS do
		if cx >= a[1] and cx < a[2] and cz >= a[3] and cz < a[4] then
			return true
		end
	end
	return false
end

local function roads()
	return workspace.Yangon1to1.Roads.Collide
end

------------------------------------------------------------------------------------------------------------------------
-- (a) terrain
------------------------------------------------------------------------------------------------------------------------
local RES = 4
local T = workspace.Terrain

-- solid occupancy of a column of voxels from y0 up (RES cells), as an array
local function column(x: number, z: number, y0: number, y1: number)
	local reg = Region3.new(Vector3.new(x, y0, z), Vector3.new(x + RES, y1, z + RES)):ExpandToGrid(RES)
	local mats, occ = T:ReadVoxels(reg, RES)
	local col = {}
	for j = 1, occ.Size.Y do
		col[j] = if mats[1][j][1] == Enum.Material.Air or mats[1][j][1] == Enum.Material.Water then 0 else occ[1][j][1]
	end
	return col, reg.CFrame.Position.Y - reg.Size.Y / 2
end

-- terrain over the top of every R / P / M box (footprint, from top + 0.6 to top + 24): returns { box, solid voxels }
function S.overRoads(apply: boolean)
	local found, cleared = {}, 0
	local list = roads():GetChildren()
	for k, b in list do
		local t = b:GetAttribute("RoadBox")
		if (t == "R" or t == "P" or t == "M") and S.inArea(b.Position.X, b.Position.Z) then
			local top = b.CFrame * Vector3.new(0, b.Size.Y / 2, 0)
			-- the box's world bounds above its top (boxes are nearly flat: the slope's rise is added)
			local hx, hz = b.Size.X / 2, b.Size.Z / 2
			local rise = math.abs(b.CFrame.LookVector.Y) * b.Size.Z / 2 + math.abs(b.CFrame.RightVector.Y) * b.Size.X / 2
			local reg = Region3.new(Vector3.new(top.X - math.max(hx, hz), top.Y + 0.6, top.Z - math.max(hx, hz)),
				Vector3.new(top.X + math.max(hx, hz), top.Y + 24, top.Z + math.max(hx, hz))):ExpandToGrid(RES)
			local mats, occ = T:ReadVoxels(reg, RES)
			local base = reg.CFrame.Position - reg.Size / 2
			local n = 0
			for i = 1, occ.Size.X do
				for j = 1, occ.Size.Y do
					for l = 1, occ.Size.Z do
						if occ[i][j][l] > 0.05 and mats[i][j][l] ~= Enum.Material.Water then
							-- voxel middle inside the box's footprint and its middle over top + rise + 1
							local p = base + Vector3.new((i - 0.5) * RES, (j - 0.5) * RES, (l - 0.5) * RES)
							local lp = b.CFrame:PointToObjectSpace(p)
							if math.abs(lp.X) < hx and math.abs(lp.Z) < hz and lp.Y > b.Size.Y / 2 + rise + 1 then
								n += 1
							end
						end
					end
				end
			end
			if n > 0 then
				table.insert(found, { b, n })
				if apply then
					-- air from 0.05 over the box top up 30 studs, the box's own footprint
					T:FillBlock(b.CFrame * CFrame.new(0, b.Size.Y / 2 + 0.05 + 15, 0), Vector3.new(b.Size.X, 30, b.Size.Z), Enum.Material.Air)
					cleared += 1
				end
			end
		end
		if k % 400 == 0 then
			_G.MBS.status = "overRoads " .. k .. "/" .. #list .. " found " .. #found
			task.wait()
		end
	end
	return found, cleared
end

-- near the flyovers: every 4-stud column within REACH of a deck (D box) in the area. Ground level G = the lowest
-- R / P / M box top within 24 studs of the column (columns with none are left). Terrain voxels whose
-- middle is over G + 4, or that sit on air (a gap of 4+ studs under them), are stray.
local REACH = 60
function S.nearDecks(apply: boolean)
	local decks, ground = {}, {}
	for _, b in roads():GetChildren() do
		local t = b:GetAttribute("RoadBox")
		if S.inArea(b.Position.X, b.Position.Z) then
			if t == "D" then
				table.insert(decks, b)
			end
		end
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { roads() }
	-- columns near decks (key x_z of the 4-grid)
	local cols, ncol = {}, 0
	for _, d in decks do
		local hx = d.Size.X / 2 + REACH
		local hz = d.Size.Z / 2 + REACH
		local r = math.max(hx, hz)
		local x0, x1 = math.floor((d.Position.X - r) / RES), math.floor((d.Position.X + r) / RES)
		local z0, z1 = math.floor((d.Position.Z - r) / RES), math.floor((d.Position.Z + r) / RES)
		for i = x0, x1 do
			for j = z0, z1 do
				local lp = d.CFrame:PointToObjectSpace(Vector3.new(i * RES + 2, d.Position.Y, j * RES + 2))
				if math.abs(lp.X) < hx and math.abs(lp.Z) < hz then
					local key = i .. "_" .. j
					if not cols[key] then
						cols[key] = { i, j, d }
						ncol += 1
					end
				end
			end
		end
	end
	_G.MBS.status = "nearDecks: " .. #decks .. " decks, " .. ncol .. " columns"
	local stray, nstray, done = {}, 0, 0
	local ridge, float = 0, 0
	for key, c in cols do
		local x, z = c[1] * RES, c[2] * RES
		if S.inArea(x, z) then
			-- ground: road / pavement boxes (not D) under / around the column
			local hits = workspace:GetPartBoundsInBox(CFrame.new(x + 2, 100, z + 2), Vector3.new(48, 400, 48), op)
			local G, lowest = nil, nil
			for _, b in hits do
				local t = b:GetAttribute("RoadBox")
				if t == "R" or t == "P" or t == "M" then
					local top = b.Position.Y + b.Size.Y / 2
					lowest = if lowest then math.min(lowest, top) else top
				end
			end
			-- only columns with a road / pavement within 24 studs: open ground further out keeps its own shape
			G = lowest
			if G then
				local col, yb = column(x, z, G - 16, G + 80)
				local seenAir = false
				local firstSolidAbove = nil
				for j = 1, #col do
					local ym = yb + (j - 0.5) * RES
					local solid = col[j] > 0.1
					if ym > G + 4 and solid then
						if ym > G + 6 or col[j] > 0.5 then
							table.insert(stray, { x, ym, z, seenAir })
							nstray += 1
							if seenAir then
								float += 1
							else
								ridge += 1
							end
						end
					end
					if not solid and ym > G - 2 then
						seenAir = true
					end
				end
			end
		end
		done += 1
		if done % 300 == 0 then
			_G.MBS.status = "nearDecks " .. done .. "/" .. ncol .. " stray " .. nstray
			task.wait()
		end
	end
	if apply then
		-- clear each stray voxel (whole 4-cell) by WriteVoxels of air, one column at a time
		for k, v in stray do
			local reg = Region3.new(Vector3.new(v[1], v[2] - 2, v[3]), Vector3.new(v[1] + RES, v[2] + 2, v[3] + RES)):ExpandToGrid(RES)
			T:FillRegion(reg, RES, Enum.Material.Air)
			if k % 500 == 0 then
				task.wait()
			end
		end
	end
	return { columns = ncol, stray = nstray, ridge = ridge, float = float, list = stray }
end

------------------------------------------------------------------------------------------------------------------------
-- (c) pavement boxes over bare asphalt / ground (roads05_pbox_clip.py output: "-" old row, then its "+" pieces)
------------------------------------------------------------------------------------------------------------------------
local function rowCF(line: string)
	local v = {}
	for w in string.gmatch(string.sub(line, 4), "%S+") do
		table.insert(v, tonumber(w))
	end
	local c, R, U = Vector3.new(v[1], v[2], v[3]), Vector3.new(v[4], v[5], v[6]), Vector3.new(v[7], v[8], v[9])
	return CFrame.fromMatrix(c, R, U, R:Cross(U)), Vector3.new(v[10], v[11], v[12])
end

function S.pboxSwap(text: string)
	-- old boxes go to ServerStorage.MB_OldPBoxes (undo: move them back, delete the new ones with attribute MBNew)
	local bk = game.ServerStorage:FindFirstChild("MB_OldPBoxes") or Instance.new("Folder")
	bk.Name = "MB_OldPBoxes"
	bk.Parent = game.ServerStorage
	local idx = {}
	for _, b in roads():GetChildren() do
		if b:GetAttribute("RoadBox") == "P" then
			local k = math.floor(b.Position.X) .. "_" .. math.floor(b.Position.Z)
			idx[k] = idx[k] or {}
			table.insert(idx[k], b)
		end
	end
	local function find(cf: CFrame)
		local p = cf.Position
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, b in idx[(math.floor(p.X) + dx) .. "_" .. (math.floor(p.Z) + dz)] or {} do
					if b.Parent and (b.Position - p).Magnitude < 0.05 then
						return b
					end
				end
			end
		end
		return nil
	end
	local old, removed, added, missing = nil, 0, 0, 0
	for line in string.gmatch(text, "[^\n]+") do
		local sg = string.sub(line, 1, 1)
		if sg == "-" then
			old = find((rowCF(line)))
			if old then
				old.Parent = bk
				removed += 1
			else
				missing += 1
			end
		elseif sg == "+" and old then
			local cf, size = rowCF(line)
			local q = old:Clone()
			q.CFrame = cf
			q.Size = size
			q:SetAttribute("MBNew", true)
			q.Parent = roads()
			added += 1
		end
	end
	return removed, added, missing
end

function S.terrainScan(apply: boolean)
	_G.MBS = { status = "start" }
	task.spawn(function()
		local ok, err = pcall(function()
			local found, cleared = S.overRoads(apply)
			_G.MBS.over = { boxes = #found, cleared = cleared, list = found }
			_G.MBS.near = S.nearDecks(apply)
		end)
		_G.MBS.status = if ok then "done" else "ERR " .. tostring(err)
	end)
	return "started"
end

return S
