--[[
	Riviera curve walls (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP and run
	on build/riviera/roads.json after Roads.build.

	(owner, 2026-11-03: "add a boulder at like turns on the mountain turns like this boulder but that
	isn't full around the curve so fix it and add boulders for wide curves like that", pictures of the
	cream stone walls at a hairpin with gaps between them): a low stone wall runs all the way round the
	outside of every curve on the hill roads (Mountain Road, the hairpins, terraces and switchbacks) and
	every wide curve elsewhere outside the town, just past the road's own pavement (or its edge where it
	has none), in the same stone as the hairpins' leg walls. The old leg-wall pieces (LegWall) are
	replaced by the new walls where they overlap.

	A curve: the road turns more than MIN_TURN degrees over about 100 studs. The wall stops short of
	junctions (another road within reach), tunnels, and where there's no ground or a building in the
	way. Each wall piece follows the road edge between two samples, its top WALL_UP above the pavement.

	CurveWalls.build(data, roadsFolder, parent) -> curve wall pieces, leg wall pieces (parent: e.g. Workspace.Riviera.Dressing)
]]

local CurveWalls = {}

local HALF = 32
local MIN_TURN = 25 -- degrees over the window
local WINDOW = 8 -- samples each side (~50 studs each way)
local WALL_UP = 2.6 -- the wall's top over the ground beside it
local WALL_DOWN = 8 -- ...and how far it goes into the ground
local THICK = 1.2
local STONE = Color3.fromRGB(222, 214, 196)

local function isHill(name: string): boolean
	return name == "Mountain Road" or string.find(name, "Hairpin") ~= nil or string.find(name, "Terrace") ~= nil or string.find(name, "Switchbacks") ~= nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function CurveWalls.build(data, roadsFolder: Instance, parent: Instance): number
	-- every road's samples in a grid (for "is another road near?")
	local roads = {}
	local grid = {}
	for ri, r in data.roads do
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1 }
			local key = math.floor(s[1] / 24) .. "," .. math.floor(s[3] / 24)
			grid[key] = grid[key] or {}
			table.insert(grid[key], { ri, i })
		end
		roads[ri] = { name = r.name, kind = r.kind, closed = r.closed, pts = pts }
	end
	local function otherNear(pos: Vector3, self: number, radius: number): boolean
		local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
		local reach = math.ceil(radius / 24)
		for dx = -reach, reach do
			for dz = -reach, reach do
				local cell = grid[(cx + dx) .. "," .. (cz + dz)]
				if cell then
					for _, e in cell do
						if e[1] ~= self then
							local q = roads[e[1]].pts[e[2]].pos
							if Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude < radius then
								return true
							end
						end
					end
				end
			end
		end
		return false
	end

	-- what the ground is like across the road: raycasts against the road pieces (road, pavement, kerb)
	local roadParts, others = {}, {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Road" or d.Name == "TurningCircle" or d.Name == "Pavement" or d.Name == "Kerb" or d.Name == "Shoulder" then
				table.insert(roadParts, d)
			end
		end
	end
	local onRoad = RaycastParams.new()
	onRoad.FilterType = Enum.RaycastFilterType.Include
	onRoad.FilterDescendantsInstances = roadParts
	local anything = RaycastParams.new()
	anything.FilterType = Enum.RaycastFilterType.Exclude
	anything.FilterDescendantsInstances = others

	-- the hairpins' leg walls (on the line between two legs running side by side, where the road is
	-- narrowed): made again, and all the way along now. They used to stop wherever another road came
	-- within reach (gaps at the hairpins); now only where the wall would stand on another road's lanes
	local old = 0
	for _, d in roadsFolder:GetDescendants() do
		if d.Name == "LegWall" then
			d:Destroy()
		end
	end
	for ri, r in roads do
		local folder = roadsFolder:FindFirstChild(r.name)
		local src = data.roads[ri].s
		if folder then
			for i = 1, #src - 1 do
				local a, b = src[i], src[i + 1]
				for side = -1, 1, 2 do
					local wa = if side < 0 then (a[7] or HALF) else (a[8] or HALF)
					local wb = if side < 0 then (b[7] or HALF) else (b[8] or HALF)
					if wa < HALF - 0.5 and wb < HALF - 0.5 and a[6] ~= 1 then
						local pa, pb = Vector3.new(a[1], a[2], a[3]), Vector3.new(b[1], b[2], b[3])
						local da, db = Vector3.new(a[4], 0, a[5]).Unit, Vector3.new(b[4], 0, b[5]).Unit
						local ea = pa + Vector3.new(-da.Z, 0, da.X) * side * wa
						local eb = pb + Vector3.new(-db.Z, 0, db.X) * side * wb
						local flatLen = Vector2.new(eb.X - ea.X, eb.Z - ea.Z).Magnitude
						if flatLen > 0.05 and not otherNear((ea + eb) / 2, ri, HALF - 4) then
							local top = math.max(ea.Y, eb.Y) + 2.5
							local bottom = math.min(ea.Y, eb.Y) - 9
							local mid = Vector3.new((ea.X + eb.X) / 2, (top + bottom) / 2, (ea.Z + eb.Z) / 2)
							local w = Instance.new("Part")
							w.Name = "LegWall"
							w.Anchored = true
							w.CastShadow = false
							w.TopSurface = Enum.SurfaceType.Smooth
							w.BottomSurface = Enum.SurfaceType.Smooth
							w.Material = Enum.Material.Limestone
							w.Color = STONE
							w.Size = Vector3.new(1, top - bottom, flatLen + 0.6)
							w.CFrame = CFrame.lookAt(mid, Vector3.new(eb.X, mid.Y, eb.Z))
							w.Parent = folder
							old += 1
						end
					end
				end
			end
		end
	end
	local folder = parent:FindFirstChild("CurveWalls")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "CurveWalls"
	folder.Parent = parent

	-- the road's outer edge beside a sample: walk out from the centre until the road surface ends
	local function edgeAt(p: Vector3, out: Vector3): (Vector3?, number?)
		local last: Vector3? = nil
		local lastY: number? = nil
		for d = HALF - 4, HALF + 18, 1 do
			local q = p + out * d
			local hit = workspace:Raycast(q + Vector3.new(0, 12, 0), Vector3.new(0, -30, 0), onRoad)
			if hit then
				last = Vector3.new(q.X, 0, q.Z)
				lastY = hit.Position.Y
			elseif last then
				break
			end
		end
		if not last then
			return nil, nil
		end
		return last + out * (THICK / 2 + 0.6), lastY
	end

	local count = 0
	for ri, r in roads do
		local hill = isHill(r.name)
		local n = #r.pts
		if n < 2 * WINDOW + 2 or (not hill and r.kind ~= "route") then
			continue -- (town streets keep their pavements open: walls only on the hills and the long routes)
		end
		-- the turn at each sample, signed (+ = turning right, the wall on the left)
		local turn = {}
		for i = 1, n do
			local a = r.pts[math.max(1, i - WINDOW)].dir
			local b = r.pts[math.min(n, i + WINDOW)].dir
			if a.Magnitude > 0 and b.Magnitude > 0 then
				a, b = a.Unit, b.Unit
				local ang = math.deg(math.acos(math.clamp(a:Dot(b), -1, 1)))
				local cross = a.X * b.Z - a.Z * b.X
				turn[i] = ang * (if cross > 0 then 1 else -1)
			else
				turn[i] = 0
			end
		end
		local minTurn = if hill then MIN_TURN else MIN_TURN * 1.6 -- (only the wide, sweeping ones on the routes)
		local prev: { pos: Vector3, y: number, side: number }? = nil
		for i = 1, n do
			local p = r.pts[i]
			local t = turn[i]
			local ok = math.abs(t) >= minTurn and not p.tunnel and not otherNear(p.pos, ri, HALF + 26)
			local here: { pos: Vector3, y: number, side: number }? = nil
			if ok then
				local d = p.dir.Unit
				local right = Vector3.new(-d.Z, 0, d.X)
				-- (t > 0: turning towards right, so the outside of the curve is on the left)
				local side = if t > 0 then -1 else 1
				local out = right * side
				local e, y = edgeAt(p.pos, out)
				if e and y then
					here = { pos = e, y = y, side = side }
				end
			end
			if here and prev and prev.side == here.side then
				local a, b = prev.pos, here.pos
				local len = (flat(b) - flat(a)).Magnitude
				if len > 0.5 and len < 20 then
					local top = math.max(prev.y, here.y) + WALL_UP
					local bottom = math.min(prev.y, here.y) - WALL_DOWN
					local mid = Vector3.new((a.X + b.X) / 2, (top + bottom) / 2, (a.Z + b.Z) / 2)
					-- (nothing solid already there: a building, a lamp's base, a tree)
					local clear = workspace:GetPartBoundsInBox(CFrame.lookAt(mid, Vector3.new(b.X, mid.Y, b.Z)) * CFrame.new(0, (top - bottom) / 2 - 1.2, 0), Vector3.new(THICK, 1.6, len))
					local blocked = false
					for _, c in clear do
						if c.CanCollide and c.Name ~= "CurveWall" and c.Name ~= "Road" and c.Name ~= "Pavement" and c.Name ~= "Kerb" and c.Name ~= "Line" and c.Name ~= "Zebra" then
							blocked = true
							break
						end
					end
					if not blocked then
						local w = Instance.new("Part")
						w.Name = "CurveWall"
						w.Anchored = true
						w.CastShadow = false
						w.Material = Enum.Material.Limestone
						w.Color = STONE
						w.TopSurface = Enum.SurfaceType.Smooth
						w.BottomSurface = Enum.SurfaceType.Smooth
						w.Size = Vector3.new(THICK, top - bottom, len + 0.4)
						w.CFrame = CFrame.lookAt(mid, Vector3.new(b.X, mid.Y, b.Z))
						w.Parent = folder
						count += 1
					end
				end
			end
			prev = here
			if i % 60 == 0 then
				task.wait()
			end
		end
	end
	return count, old
end

return CurveWalls
