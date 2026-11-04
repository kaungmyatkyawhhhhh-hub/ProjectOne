--[[
	SitePads (Studio, Edit mode; 2026-11-04, owner: "At the crown building, its floating and the floor is
	bugging"): the ground under and round a venue or house lot's stone plate (Workspace.Riviera.Sites).
	Later ground writes (the highway, the north roads) put the old hillside back round some plates: a side
	of the plate stood in the air, or the hill came up through it. This rewrites the terrain columns only:

	  * under the plate: exactly SINK studs below its top, so nothing pokes through and nothing hangs
	  * round it, out to `margin`: an earth bank down (slope `fill`) or a cutting up (slope `cut`), so the
	    plate's edge meets the ground; the hill further out stays
	  * columns with a road, kerb or pavement (and 4 studs round them), other buildings and the sea are
	    left alone
	  * a stone retaining wall round the plate's edge (children of the plate, named SiteWall), going deep
	    into the ground: where a road leaves no room for a bank the plate still stands on something

	SitePads.group(names, margin) -> the plates to solve together; SitePads.tiles(plates, margin) -> tiles
	SitePads.fixTile(plates, tile, opts?) -> cuts, fills.  opts: margin (60), fill (0.9), cut (1.2)
	SitePads.wall(plate) -> the four retaining walls
	SitePads.survey() -> list of plates with ground over them or hanging in the air
]]

local SitePads = {}

local C = 4 -- terrain voxel
local SINK = 4.4 -- the plates are 4 thick
local ROADISH = {
	Road = true,
	Kerb = true,
	Pavement = true,
	Shoulder = true,
	LegWall = true,
	TurningCircle = true,
	Wall = true,
	WallCap = true,
	DriveSlab = true,
}

local function floorTo(v: number): number
	return math.floor(v / C) * C
end

local function ceilTo(v: number): number
	return math.ceil(v / C) * C
end

-- how far (x, z) lies outside the plate (0 inside it)
local function outside(plate: BasePart, x: number, z: number): number
	local q = plate.CFrame:PointToObjectSpace(Vector3.new(x, plate.Position.Y, z))
	local dx = math.max(math.abs(q.X) - plate.Size.X / 2, 0)
	local dz = math.max(math.abs(q.Z) - plate.Size.Z / 2, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- the plates in `names`, and every plate within reach of them (neighbouring lots step up the hill, so
-- their banks have to be solved together: one plate's bank must never bury the next)
function SitePads.group(names: { string }, margin: number): { BasePart }
	local sites = workspace.Riviera.Sites
	local chosen: { [BasePart]: boolean } = {}
	local list: { BasePart } = {}
	for _, n in names do
		local p = sites[n]
		chosen[p] = true
		table.insert(list, p)
	end
	local grew = true
	while grew do
		grew = false
		for _, p in sites:GetChildren() do
			if p:IsA("BasePart") and not chosen[p] then
				for _, q in list do
					local gap = (p.Position - q.Position) * Vector3.new(1, 0, 1)
					if gap.Magnitude < (p.Size.Magnitude + q.Size.Magnitude) / 2 + margin then
						chosen[p] = true
						table.insert(list, p)
						grew = true
						break
					end
				end
			end
		end
	end
	return list
end

-- SitePads.tiles(plates, margin) -> the 256-stud tiles to do, one fix call each (a run stays short)
function SitePads.tiles(plates: { BasePart }, margin: number): { Vector2 }
	local seen, out = {}, {}
	for _, p in plates do
		local r = p.Size.Magnitude / 2 + margin
		for x = math.floor((p.Position.X - r) / 256), math.floor((p.Position.X + r) / 256) do
			for z = math.floor((p.Position.Z - r) / 256), math.floor((p.Position.Z + r) / 256) do
				local k = x .. "," .. z
				if not seen[k] then
					seen[k] = true
					table.insert(out, Vector2.new(x, z))
				end
			end
		end
	end
	return out
end

function SitePads.fixTile(plates: { BasePart }, tile: Vector2, opts: { [string]: number }?): (number, number)
	local o = opts or {}
	local M = o.margin or 60
	local FILL, CUT = o.fill or 0.9, o.cut or 1.2
	local T = workspace.Terrain
	local x0, z0 = tile.X * 256, tile.Y * 256
	local x1, z1 = x0 + 256, z0 + 256
	local nx, nz = 64, 64
	-- the plates that reach this tile
	local near = {}
	local yMin, yMax = math.huge, -math.huge
	for _, p in plates do
		local r = p.Size.Magnitude / 2 + M
		if p.Position.X + r >= x0 and p.Position.X - r <= x1 and p.Position.Z + r >= z0 and p.Position.Z - r <= z1 then
			table.insert(near, p)
			local top = p.Position.Y + p.Size.Y / 2
			yMin, yMax = math.min(yMin, top), math.max(yMax, top)
		end
	end
	if #near == 0 then
		return 0, 0
	end
	local y0 = math.max(floorTo(yMin - 120), -16)
	local y1 = ceilTo(yMax + 136)

	-- each column's limits from every plate
	local lo, hi = {}, {}
	local inPlate = {}
	for i = 1, nx do
		lo[i], hi[i], inPlate[i] = {}, {}, {}
		local px = x0 + (i - 0.5) * C
		for k = 1, nz do
			local pz = z0 + (k - 0.5) * C
			local l, h = -math.huge, math.huge
			local inside = false
			local reach = false
			for _, p in near do
				local d = outside(p, px, pz)
				if d <= M then
					reach = true
					local top = p.Position.Y + p.Size.Y / 2
					if d <= 0 then
						inside = true
						l = math.max(l, top - SINK)
						h = math.min(h, top - SINK)
					else
						l = math.max(l, top - 0.4 - d * FILL)
						h = math.min(h, top - 0.4 + d * CUT)
					end
				end
			end
			if reach then
				lo[i][k], hi[i][k] = math.min(l, h), h
				inPlate[i][k] = inside
			end
		end
	end

	-- what must stay as it is (the plates themselves don't count)
	local keep, road = {}, {}
	for i = 1, nx do
		keep[i], road[i] = {}, {}
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { T, workspace.Riviera.Sites }
	params.RespectCanCollide = false
	for i = 1, nx do
		local px = x0 + (i - 0.5) * C
		for k = 1, nz do
			if lo[i][k] then
				local pz = z0 + (k - 0.5) * C
				local hit = workspace:Raycast(Vector3.new(px, y1 + 40, pz), Vector3.new(0, y0 - y1 - 60, 0), params)
				if hit then
					if ROADISH[hit.Instance.Name] then
						road[i][k] = true
					elseif hit.Instance.Size.Magnitude > 30 then
						keep[i][k] = true -- a building or a big wall
					end
				end
			end
		end
		if i % 20 == 0 then
			task.wait()
		end
	end
	for i = 1, nx do
		for k = 1, nz do
			if road[i][k] then
				for a = math.max(i - 1, 1), math.min(i + 1, nx) do
					for b = math.max(k - 1, 1), math.min(k + 1, nz) do
						keep[a][b] = true
					end
				end
			end
		end
	end

	local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
	local mats, occs = T:ReadVoxels(region, C)
	local ny = #mats[1]
	local cuts, fills = 0, 0
	for i = 1, nx do
		local mx, ox = mats[i], occs[i]
		for k = 1, nz do
			if lo[i][k] and not keep[i][k] then
				local cur: number? = nil
				local topIy = 0
				for iy = ny, 1, -1 do
					local m = mx[iy][k]
					if ox[iy][k] > 0.01 and m ~= Enum.Material.Air and m ~= Enum.Material.Water then
						cur = y0 + (iy - 1) * C + ox[iy][k] * C
						topIy = iy
						break
					end
				end
				if cur and cur > 1 then
					local want = math.clamp(cur, lo[i][k], hi[i][k])
					local bank = not inPlate[i][k]
					if want < cur - 0.25 then
						for iy = topIy, 1, -1 do
							local yb = y0 + (iy - 1) * C
							if yb >= want then
								mx[iy][k] = Enum.Material.Air
								ox[iy][k] = 0
							else
								ox[iy][k] = math.min(ox[iy][k], (want - yb) / C)
								if bank then
									mx[iy][k] = if cur - want > 10 then Enum.Material.Rock else Enum.Material.Grass
								end
								break
							end
						end
						cuts += 1
					elseif want > cur + 0.25 then
						for iy = topIy, ny do
							local yb = y0 + (iy - 1) * C
							if yb >= want then
								break
							end
							local f = math.min((want - yb) / C, 1)
							if f > ox[iy][k] then
								ox[iy][k] = f
							end
							mx[iy][k] = if want - yb < C * 2 then Enum.Material.Grass else Enum.Material.Ground
						end
						fills += 1
					end
				end
			end
		end
	end
	T:WriteVoxels(region, C, mats, occs)
	return cuts, fills
end

function SitePads.wall(plate: BasePart): number
	for _, c in plate:GetChildren() do
		if c.Name == "SiteWall" then
			c:Destroy()
		end
	end
	local DEEP = 44
	local count = 0
	for _, e in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local alongZ = e[1] ~= 0
		local size = if alongZ then Vector3.new(0.8, DEEP, plate.Size.Z + 1.6) else Vector3.new(plate.Size.X + 1.6, DEEP, 0.8)
		local off = Vector3.new(e[1] * (plate.Size.X / 2 + 0.4), plate.Size.Y / 2 - 0.06 - DEEP / 2, e[2] * (plate.Size.Z / 2 + 0.4))
		local p = Instance.new("Part")
		p.Name = "SiteWall"
		p.Anchored = true
		p.Size = size
		p.CFrame = plate.CFrame * CFrame.new(off)
		p.Color = Color3.fromRGB(196, 186, 170)
		p.Material = Enum.Material.Concrete
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = plate
		count += 1
	end
	return count
end

function SitePads.survey(): { string }
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local rows = {}
	for _, p in workspace.Riviera.Sites:GetChildren() do
		if p:IsA("BasePart") then
			local top = p.Position.Y + p.Size.Y / 2
			local poke, air, n = 0, 0, 0
			local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
			for u = -1, 1, 0.1 do
				for v = -1, 1, 0.1 do
					local q = (p.CFrame * CFrame.new(u * hx, 0, v * hz)).Position
					local r = workspace:Raycast(Vector3.new(q.X, top + 120, q.Z), Vector3.new(0, -260, 0), params)
					local y = if r then r.Position.Y else -999
					n += 1
					if y > top + 0.05 then
						poke += 1
					elseif y < top - 8.5 then
						air += 1
					end
				end
			end
			if poke / n > 0.01 or air / n > 0.01 then
				table.insert(rows, { p.Name, poke / n + air / n, poke / n, air / n })
			end
		end
	end
	table.sort(rows, function(a, b)
		return a[2] > b[2]
	end)
	local out = {}
	for _, r in rows do
		table.insert(out, string.format("%s through %.0f%% hanging %.0f%%", r[1], r[3] * 100, r[4] * 100))
	end
	return out
end

return SitePads
