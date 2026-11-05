--[[
	Unoverlap (Studio, Edit mode; overnight step 5, 2026-11-06): checks that no two Riviera buildings
	poke into each other and that no building stands on a pavement or kerb, and nudges them apart.

	Each building has a flat box in its Body's frame: "core", the dark core plus the skin. Balconies
	and awnings may hang over a pavement; a wall may not, and nothing may stand inside a neighbour.

	Unoverlap.check() -> buildings, pairs of cores touching, cores on a pavement or kerb, worst depth,
	parts sunk into a neighbour's core
	Unoverlap.run() relaxes the boxes (pairs share the move, a pavement never moves, nothing moves more
	than MOST studs), then moves each model and its far stand-in (RivieraFar's Building group with
	Real = the model) sideways only. Each moved model keeps its first pivot in the attribute OldPivot:
	Unoverlap.undo() puts them back.
	Unoverlap.trim() takes the balconies, rails, slabs and trims that stand in a neighbour's wall off
	the building (a pushed-apart row can't make room for them) into
	ServerStorage.TrimmedParts_2026-11-06, each with an ObjectValue Home; Unoverlap.untrim() puts them
	back. A row with no room left: move the extra building to ServerStorage.RemovedBuildings_2026-11-06
	with its RivieraFar group, or its stand-in shows as a ghost.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Unoverlap = {}

local GAP = 0.1 -- what's left between two buildings: no shared planes (they flicker)
local NEAR = 14 -- neighbours are looked for this far apart
local MOST = 5 -- the furthest a building may move
local REMOVABLE = {
	Balcony = true,
	Rail = true,
	GlassRail = true,
	Awning = true,
	Sunblind = true,
	Planter = true,
	Shrub = true,
	Shutter = true,
	Sill = true,
	Blind = true,
	Band = true,
	Parapet = true,
	Cornice = true,
	Course = true,
	Pier = true,
}

type Box = { c: Vector2, ax: Vector2, az: Vector2, hx: number, hz: number }

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

-- how deep two flat boxes sink into each other, and the way to push b out (0 if they don't touch)
local function push(a: Box, b: Box, shift: Vector2): (number, Vector2)
	local d = b.c - a.c + shift
	local best, axis = math.huge, Vector2.zero
	for _, ax in { a.ax, a.az, b.ax, b.az } do
		local ra = a.hx * math.abs(ax:Dot(a.ax)) + a.hz * math.abs(ax:Dot(a.az))
		local rb = b.hx * math.abs(ax:Dot(b.ax)) + b.hz * math.abs(ax:Dot(b.az))
		local along = d:Dot(ax)
		local p = ra + rb - math.abs(along)
		if p <= 0 then
			return 0, Vector2.zero
		end
		if p < best then
			best = p
			axis = if along >= 0 then ax else -ax
		end
	end
	return best, axis
end

local function boxOf(cf: CFrame, x0: number, x1: number, z0: number, z1: number): Box
	local mid = cf * Vector3.new((x0 + x1) / 2, 0, (z0 + z1) / 2)
	return {
		c = flat(mid),
		ax = flat(cf.RightVector).Unit,
		az = flat(cf.LookVector).Unit,
		hx = (x1 - x0) / 2,
		hz = (z1 - z0) / 2,
	}
end

local function gather(riviera: Instance)
	local list = {}
	local n = 0
	for _, m in riviera:WaitForChild("Buildings"):GetChildren() do
		local body = m:FindFirstChild("Body")
		if m:IsA("Model") and body and body:IsA("BasePart") then
			local cf = body.CFrame
			local r = (m:GetAttribute("Recess") or 0.6) :: number
			local hx, hz = body.Size.X / 2 + r, body.Size.Z / 2 + r
			table.insert(list, {
				m = m,
				body = body,
				core = boxOf(cf, -hx, hx, -hz, hz),
				y0 = cf.Y - body.Size.Y / 2,
				y1 = cf.Y + body.Size.Y / 2,
				shift = Vector2.zero,
				near = {},
				walls = {},
			})
			n += 1
			if n % 40 == 0 then
				task.wait()
			end
		end
	end
	-- neighbours
	local G = 180
	local grid = {}
	for i, b in list do
		local key = math.floor(b.core.c.X / G) * 100000 + math.floor(b.core.c.Y / G)
		grid[key] = grid[key] or {}
		table.insert(grid[key], i)
	end
	for i, a in list do
		local cx, cz = math.floor(a.core.c.X / G), math.floor(a.core.c.Y / G)
		for gx = cx - 1, cx + 1 do
			for gz = cz - 1, cz + 1 do
				for _, j in grid[gx * 100000 + gz] or {} do
					local b = list[j]
					if j > i and (a.y1 > b.y0 and b.y1 > a.y0) then
						local reach = math.sqrt(a.core.hx ^ 2 + a.core.hz ^ 2) + math.sqrt(b.core.hx ^ 2 + b.core.hz ^ 2) + NEAR
						if (a.core.c - b.core.c).Magnitude < reach then
							table.insert(a.near, j)
						end
					end
				end
			end
		end
	end
	-- the pavements and kerbs round each one
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { riviera:WaitForChild("Roads") }
	op.MaxParts = 1500
	for i, a in list do
		local size = a.body.Size + Vector3.new(NEAR * 2, 0, NEAR * 2)
		for _, p in workspace:GetPartBoundsInBox(a.body.CFrame, size, op) do
			if p:IsA("Part") and (p.Name == "Pavement" or p.Name == "Kerb") then
				table.insert(a.walls, boxOf(p.CFrame, -p.Size.X / 2, p.Size.X / 2, -p.Size.Z / 2, p.Size.Z / 2))
			end
		end
		if i % 60 == 0 then
			task.wait()
		end
	end
	return list
end

local function measure(list)
	local pairsOut, roads = {}, {}
	for i, a in list do
		for _, j in a.near do
			local b = list[j]
			local p = push(a.core, b.core, b.shift - a.shift)
			if p > 0.02 then
				table.insert(pairsOut, { a = i, b = j, p = p })
			end
		end
		for _, w in a.walls do
			local p = push(w, a.core, a.shift)
			if p > 0.05 then
				table.insert(roads, { a = i, p = p })
				break
			end
		end
	end
	return pairsOut, roads
end

-- the parts of one building that stand inside a neighbour's core (found both ways round)
local function sunken(list): { { part: BasePart, into: any, depth: number } }
	local found = {}
	local function test(a, b)
		local r = (b.m:GetAttribute("Recess") or 0.6) :: number
		local inv = b.body.CFrame:Inverse()
		local bx, by, bz = b.body.Size.X / 2 + r, b.body.Size.Y / 2, b.body.Size.Z / 2 + r
		for _, d in a.parts do
			if d.Parent then
				local l = inv * d.CFrame
				local s = d.Size / 2
				local hx = math.abs(l.RightVector.X) * s.X + math.abs(l.UpVector.X) * s.Y + math.abs(l.LookVector.X) * s.Z
				local hy = math.abs(l.RightVector.Y) * s.X + math.abs(l.UpVector.Y) * s.Y + math.abs(l.LookVector.Y) * s.Z
				local hz = math.abs(l.RightVector.Z) * s.X + math.abs(l.UpVector.Z) * s.Y + math.abs(l.LookVector.Z) * s.Z
				local dx, dy, dz = bx + hx - math.abs(l.X), by + hy - math.abs(l.Y), bz + hz - math.abs(l.Z)
				local depth = math.min(dx, dz)
				-- (only a part whose middle is in there: the end of a long trim butting into a neighbour is fine)
				if depth > 0.05 and dy > 0.05 and math.abs(l.X) < bx and math.abs(l.Z) < bz then
					table.insert(found, { part = d, into = b, depth = depth })
				end
			end
		end
	end
	for i, a in list do
		if a.parts == nil then
			a.parts = {}
			for _, d in a.m:GetDescendants() do
				if d:IsA("BasePart") and d.Name ~= "Body" then
					table.insert(a.parts, d)
				end
			end
		end
		if i % 40 == 0 then
			task.wait()
		end
	end
	for i, a in list do
		for _, j in a.near do
			test(a, list[j])
			test(list[j], a)
		end
		if i % 20 == 0 then
			task.wait()
		end
	end
	return found
end

function Unoverlap.check(riviera: Instance?)
	local list = gather(riviera or workspace:WaitForChild("Riviera"))
	local pairsOut, roads = measure(list)
	local sunk = sunken(list)
	table.sort(pairsOut, function(x, y)
		return x.p > y.p
	end)
	local worst = if pairsOut[1] then pairsOut[1].p else 0
	print(string.format("Unoverlap: %d buildings, %d pairs touching (worst %.2f), %d on a pavement or kerb, %d parts in a neighbour", #list, #pairsOut, worst, #roads, #sunk))
	for k = 1, math.min(10, #pairsOut) do
		local q = pairsOut[k]
		print(string.format("  %.2f %s %.0f,%.0f / %s %.0f,%.0f", q.p, list[q.a].m.Name, list[q.a].core.c.X, list[q.a].core.c.Y, list[q.b].m.Name, list[q.b].core.c.X, list[q.b].core.c.Y))
	end
	local kinds = {}
	for _, q in sunk do
		kinds[q.part.Name] = (kinds[q.part.Name] or 0) + 1
	end
	for name, n in kinds do
		print("  in a neighbour:", name, n)
	end
	return #list, #pairsOut, #roads, worst, #sunk
end

function Unoverlap.run(riviera: Instance?)
	local root = riviera or workspace:WaitForChild("Riviera")
	local list = gather(root)
	local rounds = 0
	for round = 1, 400 do
		rounds = round
		local moves = table.create(#list, Vector2.zero)
		local worst = 0
		for i, a in list do
			for _, j in a.near do
				local b = list[j]
				local p, axis = push(a.core, b.core, b.shift - a.shift)
				if p > 0 then
					worst = math.max(worst, p)
					local step = axis * (p + GAP) / 2
					moves[i] -= step
					moves[j] += step
				end
			end
			for _, w in a.walls do
				local p, axis = push(w, a.core, a.shift)
				if p > 0 then
					worst = math.max(worst, p)
					moves[i] += axis * (p + 0.05)
				end
			end
		end
		if worst <= 0.01 then
			break
		end
		for i, a in list do
			local d = moves[i]
			if d.Magnitude > 1.5 then
				d = d.Unit * 1.5
			end
			a.shift += d * 0.8
			if a.shift.Magnitude > MOST then
				a.shift = a.shift.Unit * MOST
			end
		end
		if round % 40 == 0 then
			task.wait()
		end
	end
	-- the stand-ins go with their buildings
	local far = {}
	local rf = ReplicatedStorage:FindFirstChild("RivieraFar")
	if rf then
		for _, g in rf:GetChildren() do
			local real = g:FindFirstChild("Real")
			if real and real:IsA("ObjectValue") and real.Value then
				far[real.Value] = g
			end
		end
	end
	local moved, most = 0, 0
	for _, a in list do
		if a.shift.Magnitude > 0.005 then
			local m = a.m
			local delta = Vector3.new(a.shift.X, 0, a.shift.Y)
			if m:GetAttribute("OldPivot") == nil then
				m:SetAttribute("OldPivot", m:GetPivot())
			end
			m:PivotTo(m:GetPivot() + delta)
			local shell = m:GetAttribute("Shell")
			if typeof(shell) == "CFrame" then
				m:SetAttribute("Shell", shell + delta)
			end
			local g = far[m]
			if g then
				g:PivotTo(g:GetPivot() + delta)
			end
			moved += 1
			most = math.max(most, a.shift.Magnitude)
			if moved % 6 == 0 then
				task.wait()
			end
		end
	end
	print(string.format("Unoverlap: %d rounds, %d buildings moved, the most %.2f studs", rounds, moved, most))
	return moved, most, rounds
end

function Unoverlap.trim(riviera: Instance?)
	local SS = game:GetService("ServerStorage")
	local home = SS:FindFirstChild("TrimmedParts_2026-11-06")
	if not home then
		home = Instance.new("Folder")
		home.Name = "TrimmedParts_2026-11-06"
		home.Parent = SS
	end
	local list = gather(riviera or workspace:WaitForChild("Riviera"))
	local taken, left = 0, {}
	for _, q in sunken(list) do
		local d = q.part
		if d.Parent and d.Parent ~= home then
			if REMOVABLE[d.Name] then
				local v = Instance.new("ObjectValue")
				v.Name = "Home"
				v.Value = d.Parent
				v.Parent = d
				d.Parent = home
				taken += 1
			else
				left[d.Name] = (left[d.Name] or 0) + 1
			end
		end
	end
	return taken, left
end

function Unoverlap.untrim()
	local home = game:GetService("ServerStorage"):FindFirstChild("TrimmedParts_2026-11-06")
	if home then
		for _, d in home:GetChildren() do
			local v = d:FindFirstChild("Home")
			if v and v:IsA("ObjectValue") and v.Value then
				d.Parent = v.Value
				v:Destroy()
			end
		end
	end
end

function Unoverlap.undo(riviera: Instance?)
	local root = riviera or workspace:WaitForChild("Riviera")
	local far = {}
	local rf = ReplicatedStorage:FindFirstChild("RivieraFar")
	if rf then
		for _, g in rf:GetChildren() do
			local real = g:FindFirstChild("Real")
			if real and real:IsA("ObjectValue") and real.Value then
				far[real.Value] = g
			end
		end
	end
	for _, m in root:WaitForChild("Buildings"):GetChildren() do
		local old = m:GetAttribute("OldPivot")
		if typeof(old) == "CFrame" then
			local delta = old.Position - m:GetPivot().Position
			m:PivotTo(old)
			local shell = m:GetAttribute("Shell")
			if typeof(shell) == "CFrame" then
				m:SetAttribute("Shell", shell + delta)
			end
			local g = far[m]
			if g then
				g:PivotTo(g:GetPivot() + delta)
			end
			m:SetAttribute("OldPivot", nil)
		end
	end
end

return Unoverlap
