--[[
	SmoothKerbs (Studio, Edit mode; owner, 2026-11-06: "make all the roads smooth like in the blender but
	mainly the turns"; overnight step 7): the kerbs, pavements and shoulders on every bend, redrawn with
	short pieces along a smooth curve. The road builder lays one piece per road sample, 7 to 10 studs
	long, so a bend shows as a chain of straight bits with a kink at each joint: the zig-zag.

	Works from the pieces in the place (they carry the hand fixes, the road data doesn't). Each line of
	pieces along a road is walked; where the direction jumps at a joint by KINK degrees or more, that
	stretch is redrawn: a Catmull-Rom curve through the middles of the old pieces (it passes inside the
	road's own corners, so it never leaves a gap beside the asphalt), heights smoothed, new pieces
	every STEP studs copied from the old ones (colour, material, size across). Straight road is left
	alone. Red-and-white kerbs keep their stripes, STRIPE studs long.

	Old pieces go to ServerStorage.OldKerbs_2026-11-06/<road>; SmoothKerbs.undo(roads) brings them back.
	This needs no Import 3D. Real meshes would be smoother still (see the road notes), but take the
	owner's OK for uploads.

	SmoothKerbs.plan(roads) -> text: what would change
	SmoothKerbs.run(roads, only?) -> runs, old pieces, new pieces   (only: a set of road names)
	SmoothKerbs.undo(roads) -> pieces back
]]

local ServerStorage = game:GetService("ServerStorage")

local SmoothKerbs = {}

local KINK = 1.5 -- degrees at a joint that show
local STEPS = { Kerb = 2.5, Pavement = 4, Shoulder = 4 }
local OVER = 0.25 -- neighbours overlap this much
local REACH = 32 -- the next piece's middle is at most this far on (tight bends have 30-stud pieces)
local STRIPE = 5
local RED = Color3.fromRGB(186, 34, 34)
local WHITE = Color3.fromRGB(232, 230, 224)
local KERB = Color3.fromRGB(205, 202, 194)
local BACKUP = "OldKerbs_2026-11-06"

type Piece = { p: BasePart, a: Vector3, b: Vector3, c: Vector3, dir: Vector3 }

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function pieces(road: Instance, name: string): { Piece }
	local out = {}
	for _, p in road:GetChildren() do
		if p.Name == name and p:IsA("Part") and p.Size.Z > 1 and p.Transparency < 1 then
			local dir = p.CFrame.LookVector
			local half = dir * (p.Size.Z / 2)
			table.insert(out, { p = p, a = p.Position - half, b = p.Position + half, c = p.Position, dir = flat(dir).Unit })
		end
	end
	return out
end

-- the lines of pieces, each in order. (On a bend the builder makes each piece several studs longer than
-- its stretch of road, so ends say little: the middles are followed)
local function chains(list: { Piece }): { { Piece } }
	local G = 12
	local grid: { [string]: { number } } = {}
	for i, k in list do
		local g = math.floor(k.c.X / G) .. "," .. math.floor(k.c.Z / G)
		grid[g] = grid[g] or {}
		table.insert(grid[g], i)
	end
	local nextOf: { [number]: number } = {}
	local hasPrev: { [number]: boolean } = {}
	for i, k in list do
		local bestJ, bestD = nil, math.huge
		local side = Vector3.new(-k.dir.Z, 0, k.dir.X)
		local cx, cz = math.floor(k.c.X / G), math.floor(k.c.Z / G)
		for gx = cx - 3, cx + 3 do
			for gz = cz - 3, cz + 3 do
				for _, j in (grid[gx .. "," .. gz] or {}) :: { number } do
					local o = list[j]
					local dv = flat(o.c - k.c)
					local fwd, lat = dv:Dot(k.dir), math.abs(dv:Dot(side))
					if j ~= i and not hasPrev[j] and fwd > 0.5 and fwd < REACH and lat < 0.6 * fwd + 0.8 and k.dir:Dot(o.dir) > 0.35 and math.abs(o.c.Y - k.c.Y) < 4 then
						local d = fwd + 2 * lat
						if d < bestD then
							bestJ, bestD = j, d
						end
					end
				end
			end
		end
		if bestJ then
			nextOf[i] = bestJ
			hasPrev[bestJ] = true
		end
	end
	local out = {}
	local used: { [number]: boolean } = {}
	local function walk(start: number)
		local chain, at = {}, start
		while at and not used[at] do
			used[at] = true
			table.insert(chain, list[at])
			at = nextOf[at]
		end
		if #chain >= 3 then
			table.insert(out, chain)
		end
	end
	for i in list do
		if not hasPrev[i] then
			walk(i)
		end
	end
	for i in list do
		if not used[i] then
			walk(i) -- (a closed loop)
		end
	end
	return out
end

-- stretches of a chain whose joints show: { first, last } piece numbers
local function stretches(chain: { Piece }): { { number } }
	local n = #chain
	local bent: { [number]: boolean } = {}
	for i = 1, n - 1 do
		local cross = chain[i].dir:Cross(chain[i + 1].dir).Y
		local dot = chain[i].dir:Dot(chain[i + 1].dir)
		if math.abs(math.deg(math.atan2(cross, dot))) >= KINK then
			bent[i] = true
			bent[i + 1] = true
		end
	end
	local out, i = {}, 1
	while i <= n do
		if bent[i] then
			local j = i
			-- (a single straight piece between two bent ones goes with them)
			while j < n and (bent[j + 1] or (j + 2 <= n and bent[j + 2])) do
				j += 1
			end
			if j > i then
				table.insert(out, { math.max(i, 2), math.min(j, n - 1) })
			end
			i = j + 1
		else
			i += 1
		end
	end
	return out
end

local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- points every `step` along the curve through the middles from piece i to piece j
local function curve(chain: { Piece }, i: number, j: number, step: number): { Vector3 }
	local n = #chain
	local mids: { Vector3 } = {}
	for k = 1, n do
		mids[k] = chain[k].c
	end
	-- the height: joints differ a little by design (flicker), the curve shouldn't
	local ys: { number } = {}
	for k = 1, n do
		ys[k] = (mids[math.max(k - 1, 1)].Y + 2 * mids[k].Y + mids[math.min(k + 1, n)].Y) / 4
	end
	local function at(k: number): Vector3
		local q = mids[math.clamp(k, 1, n)]
		return Vector3.new(q.X, ys[math.clamp(k, 1, n)], q.Z)
	end
	local fine: { Vector3 } = {}
	for k = i, j - 1 do
		for s = 0, 11 do
			table.insert(fine, catmull(at(k - 1), at(k), at(k + 1), at(k + 2), s / 12))
		end
	end
	table.insert(fine, at(j))
	local total = 0
	for k = 2, #fine do
		total += (fine[k] - fine[k - 1]).Magnitude
	end
	local count = math.max(math.round(total / step), 1)
	local want = total / count
	local out = { fine[1] }
	local run, nextAt = 0, want
	for k = 2, #fine do
		local a, b = fine[k - 1], fine[k]
		local d = (b - a).Magnitude
		while run + d >= nextAt and #out < count do
			table.insert(out, a:Lerp(b, (nextAt - run) / d))
			nextAt += want
		end
		run += d
	end
	table.insert(out, fine[#fine])
	return out
end

local function isStriped(p: BasePart): boolean
	return p:GetAttribute("OldKerbColor") ~= nil
end

local function backup(road: Instance): Folder
	local top = ServerStorage:FindFirstChild(BACKUP)
	if not top then
		top = Instance.new("Folder")
		top.Name = BACKUP
		top.Parent = ServerStorage
	end
	local f = top:FindFirstChild(road.Name)
	if not f then
		f = Instance.new("Folder")
		f.Name = road.Name
		f.Parent = top
	end
	return f :: Folder
end

-- one line of pieces: each stretch's curve runs from the middle of the piece before it to the middle of the
-- piece after it; those two keep their outer half, the pieces between go to the backup
local function redraw(road: Instance, chain: { Piece }, list: { { number } }, name: string): (number, number)
	local keep = backup(road)
	local cutFront: { [number]: boolean } = {}
	local cutBack: { [number]: boolean } = {}
	local old, made = 0, 0
	for _, s in list do
		local i, j = s[1], s[2]
		local first, last = i - 1, j + 1
		local pts = curve(chain, first, last, STEPS[name])
		local model = chain[i].p
		local striped = isStriped(model)
		local arc = 0
		for k = 1, #pts - 1 do
			local a, b = pts[k], pts[k + 1]
			local len = (b - a).Magnitude
			local lift = Vector3.new(0, (k % 2) * 0.02, 0)
			local q = model:Clone()
			q:SetAttribute("SmoothKerb", true)
			q:SetAttribute("OldKerbColor", nil)
			q.Size = Vector3.new(model.Size.X - (k % 2) * 0.01, model.Size.Y, len + OVER)
			q.CFrame = CFrame.lookAt((a + b) / 2 + lift, b + lift)
			if striped then
				q.Color = if math.floor(arc / STRIPE) % 2 == 0 then RED else WHITE
				q:SetAttribute("OldKerbColor", KERB)
			end
			arc += len
			q.Parent = road
			made += 1
		end
		cutFront[first] = true
		cutBack[last] = true
		for k = i, j do
			chain[k].p.Parent = keep
			old += 1
		end
	end
	for k, _ in cutFront do
		local c = chain[k]
		if cutBack[k] then
			c.p.Parent = keep -- (both halves are curve now)
			old += 1
		elseif c.p.Parent == road then
			c.p:SetAttribute("SmoothOldCFrame", c.p.CFrame)
			c.p:SetAttribute("SmoothOldSize", c.p.Size)
			local len = c.p.Size.Z / 2 + OVER
			local from = c.a
			local to = c.c + (c.b - c.a).Unit * OVER
			c.p.Size = Vector3.new(c.p.Size.X, c.p.Size.Y, len)
			c.p.CFrame = c.p.CFrame.Rotation + (from + to) / 2
		end
	end
	for k, _ in cutBack do
		local c = chain[k]
		if not cutFront[k] and c.p.Parent == road then
			c.p:SetAttribute("SmoothOldCFrame", c.p.CFrame)
			c.p:SetAttribute("SmoothOldSize", c.p.Size)
			local len = c.p.Size.Z / 2 + OVER
			local from = c.c - (c.b - c.a).Unit * OVER
			local to = c.b
			c.p.Size = Vector3.new(c.p.Size.X, c.p.Size.Y, len)
			c.p.CFrame = c.p.CFrame.Rotation + (from + to) / 2
		end
	end
	return old, made
end

function SmoothKerbs.plan(roads: Instance): string
	local lines = {}
	local totalOld, totalNew = 0, 0
	for _, road in roads:GetChildren() do
		local line = { road.Name }
		for _, name in { "Kerb", "Pavement", "Shoulder" } do
			local list = pieces(road, name)
			if #list > 0 then
				local runs, old, new = 0, 0, 0
				for _, chain in chains(list) do
					for _, s in stretches(chain) do
						runs += 1
						old += s[2] - s[1] + 1
						local len = 0
						for k = s[1], s[2] - 1 do
							len += (chain[k + 1].c - chain[k].c).Magnitude
						end
						new += math.ceil(len / STEPS[name])
					end
				end
				table.insert(line, string.format("%s %d pieces, %d stretches, %d -> %d", name, #list, runs, old, new))
				totalOld += old
				totalNew += new
			end
		end
		table.insert(lines, table.concat(line, "; "))
		task.wait()
	end
	table.sort(lines)
	table.insert(lines, string.format("TOTAL %d -> %d", totalOld, totalNew))
	return table.concat(lines, "\n")
end

function SmoothKerbs.run(roads: Instance, only: { [string]: boolean }?): (number, number, number)
	local runs, old, new = 0, 0, 0
	for _, road in roads:GetChildren() do
		if not only or only[road.Name] then
			for _, name in { "Kerb", "Pavement", "Shoulder" } do
				local list = pieces(road, name)
				if #list > 0 then
					for _, chain in chains(list) do
						local parts = stretches(chain)
						if #parts > 0 then
							local o, n = redraw(road, chain, parts, name)
							runs += #parts
							old += o
							new += n
						end
					end
				end
			end
			task.wait()
		end
	end
	return runs, old, new
end

function SmoothKerbs.undo(roads: Instance): number
	local top = ServerStorage:FindFirstChild(BACKUP)
	local n = 0
	for _, road in roads:GetChildren() do
		for _, p in road:GetChildren() do
			if p:GetAttribute("SmoothKerb") then
				p:Destroy()
			elseif p:GetAttribute("SmoothOldCFrame") then
				p.CFrame = p:GetAttribute("SmoothOldCFrame")
				p.Size = p:GetAttribute("SmoothOldSize")
				p:SetAttribute("SmoothOldCFrame", nil)
				p:SetAttribute("SmoothOldSize", nil)
			end
		end
		local f = top and top:FindFirstChild(road.Name)
		if f then
			for _, p in f:GetChildren() do
				p.Parent = road
				n += 1
			end
		end
		task.wait()
	end
	return n
end

return SmoothKerbs
