--[[
	RoadVerge05 (Studio, Edit; ServerStorage.ClaudeTools.RoadVerge05; 2026-11-16): the grass beside the baked 1:1
	roads' pavements up to the pavement top (in P3 it stood 2-9 studs lower: the pavement's side showed as a wall,
	e.g. Sule Pagoda Road). From the baked collision boxes (RCol, attribute RoadBox "P" = pavement; "R" carriageway
	boxes too: side streets have pavements as mesh only, no box).

	Per 4-stud terrain cell (the voxel grid, centres at 4k + 2) within REACH of a pavement box's long side:
	target = pavement top - FLAT_DROP for the first FLAT studs, then SLOPE lower per stud; the highest target of all
	boxes wins. Cells over any road box are left (no grass on or over a road, an underpass included), and so are water
	cells, and cells under a pavement (a fill there could rise through the asphalt by the kerb). A cell whose ground is
	under its target gets a 4 x 4 grass column whose FillBlock top is 2 under the target (smooth terrain shows about
	2 studs over a FillBlock's top). Only raises ground.
	(The first version filled strips along each box: they left 1-cell trenches between strips and at road edges.)

	local V = require(game.ServerStorage.ClaudeTools.RoadVerge05:Clone())
	V.spawn(x0, z0, x1, z1)   -- runs in a task; V.status() -> "done ...: n boxes, c cells, f filled"
	V.spawn(x0, z0, x1, z1, "trim")   -- then: carve ground that reached within 0.6 of a pavement top
]]

local M = {}
M.REACH = 30       -- studs out from the pavement edge
M.FLAT = 6         -- level part beside the pavement
M.FLAT_DROP = 0.5  -- visible grass this much under the pavement top (never through it)
M.SLOPE = 0.4      -- then down this much per stud
M.KERB = 0.45      -- a carriageway box's top + this = the pavement top (side streets: pavement as mesh only)
M.DECK = 12        -- a carriageway this far over the ground is a deck: left alone
M.FLAT_R = 14      -- level part beside a carriageway box (its mesh pavement, ~2.5 m, comes first)

function M.run(x0: number, z0: number, x1: number, z1: number): string
	local col = workspace.Yangon1to1.Roads.Collide
	local target: { [number]: number } = {}
	local underTop: { [number]: boolean } = {}
	local n = 0
	local rpG = RaycastParams.new()
	rpG.FilterType = Enum.RaycastFilterType.Include
	rpG.FilterDescendantsInstances = { workspace.Terrain }
	for i, p in col:GetChildren() do
		local kind = p:GetAttribute("RoadBox")
		local c = p.Position
		if (kind == "P" or kind == "R") and c.X >= x0 and c.X <= x1 and c.Z >= z0 and c.Z <= z1 then
			local cf, sz = p.CFrame, p.Size
			local top = c.Y + sz.Y / 2
			local across, w, len = cf.RightVector, sz.X, sz.Z
			if sz.X > sz.Z then
				across, w, len = cf.LookVector, sz.Z, sz.X
			end
			across = Vector3.new(across.X, 0, across.Z).Unit
			local along = Vector3.new(-across.Z, 0, across.X)
			local flat = M.FLAT
			if kind == "R" then
				flat = M.FLAT_R
				-- (side streets have no pavement boxes: their pavements are mesh only. Take the carriageway box with a
				-- 0.45 kerb. A deck over 12 studs above the ground beside it is a flyover: no embankment)
				top += M.KERB
				local e = c + across * (w / 2 + 3)
				local g = workspace:Raycast(Vector3.new(e.X, top + 20, e.Z), Vector3.new(0, -100, 0), rpG)
				if g and top - g.Position.Y > M.DECK then
					continue
				end
			end
			do
				n += 1
				local r = w / 2 + M.REACH + len / 2
				for ci = math.floor((c.X - r) / 4), math.floor((c.X + r) / 4) do
					for cj = math.floor((c.Z - r) / 4), math.floor((c.Z + r) / 4) do
						local dx, dz = ci * 4 + 2 - c.X, cj * 4 + 2 - c.Z
						local u = dx * across.X + dz * across.Z
						local v = dx * along.X + dz * along.Z
						if math.abs(v) <= len / 2 + 2 then
							local d = math.abs(u) - w / 2
							local k = ci * 100000 + cj
							if d <= 0 then
								underTop[k] = true
							elseif d <= M.REACH then
								local t = top - M.FLAT_DROP - math.max(0, d - flat) * M.SLOPE
								if not target[k] or t > target[k] then
									target[k] = t
								end
							end
						end
					end
				end
			end
		end
		if i % 500 == 0 then
			task.wait()
		end
	end
	local rpRoad = RaycastParams.new()
	rpRoad.FilterType = Enum.RaycastFilterType.Include
	rpRoad.FilterDescendantsInstances = { col }
	local rpT = RaycastParams.new()
	rpT.FilterType = Enum.RaycastFilterType.Include
	rpT.FilterDescendantsInstances = { workspace.Terrain }
	rpT.IgnoreWater = false
	-- (no fill under a landmark, a pagoda or a building shell: Sule's ring road stands ~6 over its pagoda pad)
	local rpKeep = RaycastParams.new()
	rpKeep.FilterType = Enum.RaycastFilterType.Include
	local keep = {}
	for _, nm in { "Landmarks", "Pagodas", "Buildings" } do
		local f = workspace.Yangon1to1:FindFirstChild(nm)
		if f then
			table.insert(keep, f)
		end
	end
	rpKeep.FilterDescendantsInstances = keep
	local cells, filled = 0, 0
	local function fill(x: number, z: number, topF: number)
		local g = workspace:Raycast(Vector3.new(x, topF + 40, z), Vector3.new(0, -120, 0), rpT)
		if g and g.Material == Enum.Material.Water then
			return
		end
		if g == nil or g.Position.Y < topF + 2 - 0.4 then
			local bottom = math.min(topF - 4, (if g then g.Position.Y else topF - 16) - 4)
			workspace.Terrain:FillBlock(CFrame.new(x, (topF + bottom) / 2, z), Vector3.new(4, topF - bottom, 4),
				Enum.Material.Grass)
			filled += 1
		end
	end
	-- beside the pavements: only where no road box is anywhere under the cell
	for k, t in target do
		cells += 1
		local x, z = (k // 100000) * 4 + 2, (k % 100000) * 4 + 2
		if not underTop[k] and workspace:Raycast(Vector3.new(x, t + 40, z), Vector3.new(0, -200, 0), rpRoad) == nil
			and workspace:Raycast(Vector3.new(x, t + 400, z), Vector3.new(0, -600, 0), rpKeep) == nil then
			fill(x, z, t - 2)
		end
		if cells % 400 == 0 then
			task.wait()
		end
	end
	return string.format("%d pavement boxes, %d cells, %d filled", n, cells, filled)
end

-- The fill's first cell beside a pavement swelled up to 0.1 under the pavement top (the grass showed through at the
-- edge, 16 Nov): carve every cell under a pavement or within TRIM_D of its edge whose ground is within TRIM_MIN of
-- the pavement top down to TRIM_TO under it (an Air box; smooth terrain lands near the box's bottom).
M.TRIM_D = 6
M.TRIM_MIN = 0.6
M.TRIM_TO = 1.2
M.TRIM_D_R = 9     -- beside a carriageway box (its mesh pavement + 1.5)
-- (25 Nov) `only`: a list of road boxes (RoadTerrainPoke's hits) to trim round instead of every box in the window
function M.trim(x0: number, z0: number, x1: number, z1: number, only: { BasePart }?): string
	local col = workspace.Yangon1to1.Roads.Collide
	local rpT = RaycastParams.new()
	rpT.FilterType = Enum.RaycastFilterType.Include
	rpT.FilterDescendantsInstances = { workspace.Terrain }
	local cut: { [number]: number } = {}
	local cutR: { [number]: number } = {}   -- (from carriageway boxes)
	local n = 0
	for i, p in only or col:GetChildren() do
		local c = p.Position
		local kind = p:GetAttribute("RoadBox")
		if (kind == "P" or kind == "R") and c.X >= x0 and c.X <= x1 and c.Z >= z0 and c.Z <= z1 then
			n += 1
			local cf, sz = p.CFrame, p.Size
			local top = c.Y + sz.Y / 2
			local across, w, len = cf.RightVector, sz.X, sz.Z
			if sz.X > sz.Z then
				across, w, len = cf.LookVector, sz.Z, sz.X
			end
			across = Vector3.new(across.X, 0, across.Z).Unit
			local along = Vector3.new(-across.Z, 0, across.X)
			local reach = M.TRIM_D
			if kind == "R" then
				-- (a side street's mesh pavement: kerb on the carriageway box, pavement about 7.5 wide)
				top += M.KERB
				reach = M.TRIM_D_R
				local e = c + across * (w / 2 + 3)
				local g = workspace:Raycast(Vector3.new(e.X, top + 20, e.Z), Vector3.new(0, -100, 0), rpT)
				if g and top - g.Position.Y > M.DECK then
					reach = -1   -- a deck: nothing to trim
				end
			end
			local r = w / 2 + reach + len / 2
			for ci = math.floor((c.X - r) / 4), math.floor((c.X + r) / 4) do
				for cj = math.floor((c.Z - r) / 4), math.floor((c.Z + r) / 4) do
					local dx, dz = ci * 4 + 2 - c.X, cj * 4 + 2 - c.Z
					local u = dx * across.X + dz * across.Z
					local v = dx * along.X + dz * along.Z
					if reach >= 0 and math.abs(v) <= len / 2 + 2 and math.abs(u) - w / 2 <= reach then
						local k = ci * 100000 + cj
						local y = top - M.TRIM_TO
						local into = if kind == "P" then cut else cutR
						if not into[k] or y < into[k] then
							into[k] = y
						end
					end
				end
			end
		end
		if i % 500 == 0 then
			task.wait()
		end
	end
	-- (the lower of the two: a side street running downhill from a main road lies under the main road's band; near a
	-- main road the two levels differ by about 0.05)
	for k, y in cutR do
		if not cut[k] or y < cut[k] then
			cut[k] = y
		end
	end
	local cells, carved = 0, 0
	for k, y in cut do
		cells += 1
		local x, z = (k // 100000) * 4 + 2, (k % 100000) * 4 + 2
		-- (25 Nov, road bug sweep) the centre ray alone missed the swell between cell centres: 4,893 road boxes still had
		-- grass 0.12-4.9 over their top (grass lying on the asphalt). Test the centre and 4 points near the corners.
		local g, gy = nil, -math.huge
		for _, o in { { 0, 0 }, { 1.8, 1.8 }, { -1.8, 1.8 }, { 1.8, -1.8 }, { -1.8, -1.8 } } do
			local h = workspace:Raycast(Vector3.new(x + o[1], y + 40, z + o[2]), Vector3.new(0, -80, 0), rpT)
			if h and h.Position.Y > gy then
				g, gy = h, h.Position.Y
			end
		end
		if g and g.Material ~= Enum.Material.Water and g.Position.Y > y + M.TRIM_TO - M.TRIM_MIN then
			workspace.Terrain:FillBlock(CFrame.new(x, y + 10, z), Vector3.new(4, 20, 4), Enum.Material.Air)
			carved += 1
		end
		if cells % 400 == 0 then
			task.wait()
		end
	end
	return string.format("trim: %d pavement boxes, %d cells, %d carved", n, cells, carved)
end

function M.spawn(x0: number, z0: number, x1: number, z1: number, fn: string?)
	workspace:SetAttribute("RoadVerge05", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(if fn == "trim" then M.trim else M.run, x0, z0, x1, z1)
		workspace:SetAttribute("RoadVerge05", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(workspace:GetAttribute("RoadVerge05"))
end

return M
