--[[
	Riviera road lines, redone (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP
	and run on build/riviera/roads.json after Roads.build.

	(owner, 2026-11-03: "most of the roads the has a intersection or a wide turn, the road becomes bad
	with road lines not there properly"): Roads.build lays each line along the chord between two
	centre-line samples, shifted sideways. On a bend the shifted chords turn with the chord, so on
	the inside of a tight bend they cross each other (white X marks), and away from the centre they
	point the wrong way (423 lines more than 15 degrees off the road). Here each line runs from
	sample a's own side point to sample b's (each sample's own right vector), so lines follow the
	curve; where the inside of a bend folds back (the side points run backwards) the line is left
	out. Both ends sit on this road's own surface, found by raycast (0.08 above it, the flicker
	rule); an end over another road's carriageway or off the road leaves the line out, so no line
	runs across a junction mouth.

	RoadLines.build(data, roadsFolder, only?) -> lines made (only: a set of road names to redo). Old "Line" parts are moved to
	ServerStorage.OldRoadLines first (delete that folder once the new lines are checked).
]]

local RoadLines = {}

local HALF = 32
local LINE_T = 0.04
local LIFT = 0.08 -- paint above the road (flicker rule: at least 0.05)
local PAINT = Color3.fromRGB(232, 232, 226)

local function prepare(data)
	local roads = {}
	for ri, r in data.roads do
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), wl = s[7] or HALF, wr = s[8] or HALF }
		end
		roads[ri] = { name = r.name, pts = pts }
	end
	local grid = {}
	for ri, r in roads do
		for i, p in r.pts do
			local key = math.floor(p.pos.X / 24) .. "," .. math.floor(p.pos.Z / 24)
			grid[key] = grid[key] or {}
			table.insert(grid[key], { ri, i })
		end
	end
	return roads, grid
end

local function otherNear(roads, grid, pos: Vector3, self: number, radius: number): boolean
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

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function RoadLines.build(data, roadsFolder: Instance, only: { [string]: boolean }?): number
	local roads, grid = prepare(data)
	local roadParts = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Road" or d.Name == "TurningCircle") then
			table.insert(roadParts, d)
		end
	end
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Include
	down.FilterDescendantsInstances = roadParts
	local function surface(p: Vector3, name: string): number?
		local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), down)
		if hit and hit.Instance.Parent and hit.Instance.Parent.Name == name then
			return hit.Position.Y
		end
		return nil
	end

	-- the old lines out of the way (kept for a quick undo)
	local ServerStorage = game:GetService("ServerStorage")
	local old = ServerStorage:FindFirstChild("OldRoadLines") or Instance.new("Folder")
	old.Name = "OldRoadLines"
	old.Parent = ServerStorage
	local moved = 0
	for _, folder in roadsFolder:GetChildren() do
		if only and not only[folder.Name] then
			continue
		end
		local keep = old:FindFirstChild(folder.Name) or Instance.new("Folder")
		keep.Name = folder.Name
		keep.Parent = old
		for _, d in folder:GetChildren() do
			if d.Name == "Line" then
				d.Parent = keep
				moved += 1
				if moved % 2000 == 0 then
					task.wait()
				end
			end
		end
	end

	local count = 0
	for ri, r in roads do
		local folder = roadsFolder:FindFirstChild(r.name)
		if not folder or (only and not only[r.name]) then
			continue
		end
		local pts = r.pts
		local n = #pts
		local inJunction = {}
		for i, p in pts do
			inJunction[i] = otherNear(roads, grid, p.pos, ri, HALF + 6)
		end
		local dash = 0
		for i = 1, n - 1 do
			if i % 40 == 0 then
				task.wait()
			end
			local a, b = pts[i], pts[i + 1]
			if inJunction[i] or inJunction[i + 1] then
				dash = 0
				continue
			end
			dash += 1
			local chord = flat(b.pos - a.pos)
			local len = chord.Magnitude
			if len < 0.5 then
				continue
			end
			-- each end at its own sample's width (the edge line follows a narrowed edge). (owner,
			-- 2026-11-03: "the road became 3.5 lane") the lane line on a side narrowed next to another
			-- road sits in the middle of what's left, so it reads as two narrower lanes, not a lane
			-- and a half (it was always 16 out, leaving a sliver past it)
			local lines = {
				{ x = a.wr - 1.2, xb = b.wr - 1.2, w = 0.6, solid = true },
				{ x = -(a.wl - 1.2), xb = -(b.wl - 1.2), w = 0.6, solid = true },
			}
			if dash % 2 == 0 then
				table.insert(lines, { x = 0, xb = 0, w = 0.5 })
				if math.min(a.wr, b.wr) > 14 then
					table.insert(lines, { x = math.min(HALF / 2, a.wr / 2), xb = math.min(HALF / 2, b.wr / 2), w = 0.4 })
				end
				if math.min(a.wl, b.wl) > 14 then
					table.insert(lines, { x = -math.min(HALF / 2, a.wl / 2), xb = -math.min(HALF / 2, b.wl / 2), w = 0.4 })
				end
			end
			local rightA = Vector3.new(-a.dir.Z, 0, a.dir.X).Unit
			local rightB = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit
			for _, l in lines do
				local pa = a.pos + rightA * l.x
				local pb = b.pos + rightB * l.xb
				local d = flat(pb - pa)
				-- (the inside of a tight bend: the side points stand still or run backwards)
				if d:Dot(chord) < 0.35 * len * len then
					continue
				end
				local ya, yb = surface(pa, r.name), surface(pb, r.name)
				if not ya or not yb then
					continue -- off the road, or over another road's carriageway (a junction)
				end
				pa = Vector3.new(pa.X, ya, pa.Z)
				pb = Vector3.new(pb.X, yb, pb.Z)
				local span = (pb - pa).Magnitude
				local p = Instance.new("Part")
				p.Name = "Line"
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.CastShadow = false
				p.Material = Enum.Material.SmoothPlastic
				p.Color = PAINT
				p.TopSurface = Enum.SurfaceType.Smooth
				p.BottomSurface = Enum.SurfaceType.Smooth
				p.Size = Vector3.new(l.w, LINE_T, if l.solid then span + 0.3 else span * 0.9)
				p.CFrame = CFrame.lookAt((pa + pb) / 2, pb) * CFrame.new(0, LINE_T / 2 + LIFT, 0)
				p.Parent = folder
				count += 1
			end
		end
	end
	return count
end

return RoadLines
