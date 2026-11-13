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

	RoadLines.build(data, roadsFolder, only?, opts?) -> lines made (only: a set of road names to redo). Old "Line" parts are moved to
	ServerStorage.OldRoadLines first (delete that folder once the new lines are checked).

	Yangon (2026-11-13): a road with its own `half` in the data gets its lane lines at half of that, and
	"in a junction" is measured with the other road's half (a street mouth is as wide as the street).
	Without `half` nothing changes. opts (all optional): cut = the same table as Roads.build's opts.cut
	(cut samples get no lines and are no junction for anyone); paint = Color3 for every line;
	centre = { color = Color3?, solid = boolean?, double = boolean? } for the middle line;
	clearMouths = true: a line piece is also left out when either end lies on another road's
	carriageway (a street joining at a slant: its mouth reaches further along the edge line than the
	"in a junction" test of the centre line sees), and the road under each end is looked for 0.05
	inside the piece (a ray exactly on the seam between two road pieces can miss: a missing dash).
]]

local RoadLines = {}

local HALF = 32
local LINE_T = 0.04
local LIFT = 0.08 -- paint above the road (flicker rule: at least 0.05)
local PAINT = Color3.fromRGB(232, 232, 226)

local maxDh = 0 -- (the widest road's half width over HALF)

local function prepare(data, cut)
	local roads = {}
	maxDh = 0
	for ri, r in data.roads do
		local half = r.half -- (Yangon: this road's own half width; nil = HALF, as before)
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), wl = s[7] or half or HALF, wr = s[8] or half or HALF }
		end
		roads[ri] = { name = r.name, pts = pts, route = r.kind == "route", half = half, dh = (half or HALF) - HALF, cut = if cut then cut[r.name] else nil }
		maxDh = math.max(maxDh, roads[ri].dh)
	end
	local grid = {}
	for ri, r in roads do
		for i, p in r.pts do
			if r.cut and r.cut[i] then
				continue
			end
			local key = math.floor(p.pos.X / 24) .. "," .. math.floor(p.pos.Z / 24)
			grid[key] = grid[key] or {}
			table.insert(grid[key], { ri, i })
		end
	end
	return roads, grid
end

local function otherNear(roads, grid, pos: Vector3, self: number, radius: number): boolean
	local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
	local reach = math.ceil((radius + maxDh) / 24)
	for dx = -reach, reach do
		for dz = -reach, reach do
			local cell = grid[(cx + dx) .. "," .. (cz + dz)]
			if cell then
				for _, e in cell do
					if e[1] ~= self then
						local q = roads[e[1]].pts[e[2]].pos
						if Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude < radius + roads[e[1]].dh then -- (dh: "that far past this road's own edge")
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

function RoadLines.build(data, roadsFolder: Instance, only: { [string]: boolean }?, opts): number
	opts = opts or {}
	local paint = opts.paint or PAINT
	local centre = opts.centre or {}
	local roads, grid = prepare(data, opts.cut)
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
		local H = r.half or HALF
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
			if inJunction[i] or inJunction[i + 1] or (r.cut and (r.cut[i] or r.cut[i + 1])) then
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
			-- (opts.centre, Yangon: the middle line may be solid, double and its own colour)
			if centre.solid then
				if centre.double then
					table.insert(lines, { x = -0.55, xb = -0.55, w = 0.5, solid = true, color = centre.color })
					table.insert(lines, { x = 0.55, xb = 0.55, w = 0.5, solid = true, color = centre.color })
				else
					table.insert(lines, { x = 0, xb = 0, w = 0.5, solid = true, color = centre.color })
				end
			end
			if dash % 2 == 0 then
				if not centre.solid then
					table.insert(lines, { x = 0, xb = 0, w = 0.5, color = centre.color })
				end
				-- (owner, 2026-11-04: "Make the road 1+1 for the roads which isnt yellow"): only the three
				-- yellow routes keep their lane lines; the streets are one lane each way
				if not r.route then
					-- (no lane lines)
				elseif math.min(a.wr, b.wr) > 14 then
					table.insert(lines, { x = math.min(H / 2, a.wr / 2), xb = math.min(H / 2, b.wr / 2), w = 0.4 })
				end
				if r.route and math.min(a.wl, b.wl) > 14 then
					table.insert(lines, { x = -math.min(H / 2, a.wl / 2), xb = -math.min(H / 2, b.wl / 2), w = 0.4 })
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
				if opts.clearMouths and (otherNear(roads, grid, pa, ri, HALF + 0.5) or otherNear(roads, grid, pb, ri, HALF + 0.5)) then
					continue -- (in another road's mouth)
				end
				local ya, yb
				if opts.clearMouths then
					-- (the two ends stand exactly on the cross-sections where the road's pieces meet, and a
					-- ray on a seam can slip between two pieces: look a hair inside this piece instead)
					local inset = d.Unit * 0.05
					ya, yb = surface(pa + inset, r.name), surface(pb - inset, r.name)
				else
					ya, yb = surface(pa, r.name), surface(pb, r.name)
				end
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
				p.Color = l.color or paint
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
