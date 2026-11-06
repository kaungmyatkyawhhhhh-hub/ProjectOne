--[[
	PaveOverlap (Studio, Edit mode; owner, 2026-11-06, "Find all buildings and roads if they have this
	problem"): where two roads meet, each one's pavement used to run on over the other's: pink brick over
	basket weave, strips of one showing through the other, kerbs lying across the paving.

	Roads are ranked by how many pavement pieces they have: the longer road's pavement runs through.
	For each piece of the smaller road:
	  * COVER or more of it lies on the bigger road's pavement: it goes
	  * some of it does: it drops GAP under the other's top, so the other shows a clean edge (never
	    more than DROP: a piece standing far over the other road's pavement is left: that's a step
	    in the ground, not an overlap)
	A kerb lying on another road's pavement with no road beside it goes too.

	Removed pieces: ServerStorage.PaveOverlap_2026-11-06/<road>. Dropped pieces keep OldPaveCFrame.

	PaveOverlap.check(roads) -> pieces on another road's pavement, level with it (under GAP apart), kerbs lying
	on a pavement
	PaveOverlap.run(roads) -> pieces removed, pieces dropped, kerbs removed
	PaveOverlap.undo(roads)
]]

local ServerStorage = game:GetService("ServerStorage")

local PaveOverlap = {}

local COVER = 0.85
local GAP = 0.08
local DROP = 0.6
local BACKUP = "PaveOverlap_2026-11-06"
local G = 24
local KERB_REACH = 2.2 -- how far from a kerb's middle to look for the road

type Piece = { p: BasePart, road: string, rank: number, top: number }

local function topOf(p: BasePart): number
	return p.Position.Y + p.CFrame.UpVector.Y * p.Size.Y / 2
end

local function collect(roads: Instance): ({ Piece }, { [string]: { Piece } }, { [string]: number })
	local list: { Piece } = {}
	local rank: { [string]: number } = {}
	for _, road in roads:GetChildren() do
		local n = 0
		for _, p in road:GetChildren() do
			if p.Name == "Pavement" and p:IsA("Part") and p.Transparency < 1 then
				n += 1
			end
		end
		rank[road.Name] = n
	end
	local grid: { [string]: { Piece } } = {}
	for _, road in roads:GetChildren() do
		for _, p in road:GetChildren() do
			if p.Name == "Pavement" and p:IsA("Part") and p.Transparency < 1 then
				local e = { p = p, road = road.Name, rank = rank[road.Name], top = topOf(p) }
				table.insert(list, e)
				local k = math.floor(p.Position.X / G) .. "," .. math.floor(p.Position.Z / G)
				grid[k] = grid[k] or {}
				table.insert(grid[k], e)
			end
		end
	end
	return list, grid, rank
end

local function inside(e: Piece, at: Vector3): boolean
	local q = e.p.CFrame:PointToObjectSpace(Vector3.new(at.X, e.p.Position.Y, at.Z))
	return math.abs(q.X) <= e.p.Size.X / 2 and math.abs(q.Z) <= e.p.Size.Z / 2
end

local function around(grid, at: Vector3, fn: (Piece) -> ())
	local cx, cz = math.floor(at.X / G), math.floor(at.Z / G)
	for gx = cx - 1, cx + 1 do
		for gz = cz - 1, cz + 1 do
			for _, e in grid[gx .. "," .. gz] or {} do
				fn(e)
			end
		end
	end
end

-- how much of a piece lies on the pavements of bigger roads near its height, and those pieces
local function cover(e: Piece, grid): (number, { Piece })
	local hits = 0
	local over: { [Piece]: boolean } = {}
	local cf, s = e.p.CFrame, e.p.Size
	for i = -2, 2 do
		for j = -2, 2 do
			local at = cf * Vector3.new(s.X * i / 5, s.Y / 2, s.Z * j / 5)
			local hit = false
			around(grid, at, function(o)
				if o.road ~= e.road and (o.rank > e.rank or (o.rank == e.rank and o.road > e.road)) and math.abs(o.top - e.top) < DROP and inside(o, at) then
					hit = true
					over[o] = true
				end
			end)
			if hit then
				hits += 1
			end
		end
	end
	local list = {}
	for o in over do
		table.insert(list, o)
	end
	return hits / 25, list
end

local function backup(name: string): Folder
	local top = ServerStorage:FindFirstChild(BACKUP)
	if not top then
		top = Instance.new("Folder")
		top.Name = BACKUP
		top.Parent = ServerStorage
	end
	local f = top:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = top
	end
	return f :: Folder
end

-- a kerb with no road beside it, on a bigger road's pavement
local function strayKerb(k: BasePart, road: Instance, grid, rank): boolean
	local at = k.Position + k.CFrame.UpVector * (k.Size.Y / 2)
	local mine = rank[road.Name] or 0
	local onPave = false
	around(grid, at, function(o)
		if o.road ~= road.Name and o.rank >= mine and math.abs(o.top - at.Y) < 0.7 and inside(o, at) then
			onPave = true
		end
	end)
	if not onPave then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Riviera.Roads }
	for _, side in { -1, 1 } do
		local q = at + k.CFrame.RightVector * (side * KERB_REACH)
		local r = workspace:Raycast(q + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), params)
		if r and r.Instance.Name == "Road" then
			return false
		end
	end
	return true
end

function PaveOverlap.check(roads: Instance): (number, number, number)
	local list, grid, rank = collect(roads)
	local level, covered = 0, 0
	for i, e in list do
		local share, over = cover(e, grid)
		if share > 0 then
			for _, o in over do
				if math.abs(o.top - e.top) < GAP - 0.002 then
					level += 1
					break
				end
			end
		end
		if share >= COVER then
			covered += 1
		end
		if i % 400 == 0 then
			task.wait()
		end
	end
	local kerbs = 0
	for _, road in roads:GetChildren() do
		for _, k in road:GetChildren() do
			if k.Name == "Kerb" and k:IsA("Part") and k.Transparency < 1 and strayKerb(k, road, grid, rank) then
				kerbs += 1
			end
		end
		task.wait()
	end
	return covered, level, kerbs
end

function PaveOverlap.run(roads: Instance): (number, number, number)
	local list, grid, rank = collect(roads)
	local removed, dropped = 0, 0
	-- smallest roads first: a piece lowered or gone no longer counts for the ones after it
	table.sort(list, function(a, b)
		return a.rank < b.rank
	end)
	for i, e in list do
		local share, over = cover(e, grid)
		if share >= COVER then
			e.p.Parent = backup(e.road)
			e.top = -1e6
			removed += 1
		elseif share > 0 then
			local want = math.huge
			for _, o in over do
				want = math.min(want, o.top - GAP)
			end
			if want < e.top then
				if e.p:GetAttribute("OldPaveCFrame") == nil then
					e.p:SetAttribute("OldPaveCFrame", e.p.CFrame)
				end
				e.p.CFrame -= Vector3.new(0, e.top - want, 0)
				e.top = want
				dropped += 1
			end
		end
		if i % 400 == 0 then
			task.wait()
		end
	end
	local kerbs = 0
	for _, road in roads:GetChildren() do
		local gone = {}
		for _, k in road:GetChildren() do
			if k.Name == "Kerb" and k:IsA("Part") and k.Transparency < 1 and strayKerb(k, road, grid, rank) then
				table.insert(gone, k)
			end
		end
		for _, k in gone do
			k.Parent = backup(road.Name)
			kerbs += 1
		end
		task.wait()
	end
	return removed, dropped, kerbs
end

function PaveOverlap.undo(roads: Instance)
	local top = ServerStorage:FindFirstChild(BACKUP)
	for _, road in roads:GetChildren() do
		for _, p in road:GetChildren() do
			local cf = p:GetAttribute("OldPaveCFrame")
			if typeof(cf) == "CFrame" and p:IsA("BasePart") then
				p.CFrame = cf
				p:SetAttribute("OldPaveCFrame", nil)
			end
		end
		local f = top and top:FindFirstChild(road.Name)
		if f then
			for _, p in f:GetChildren() do
				p.Parent = road
			end
		end
	end
end

return PaveOverlap
