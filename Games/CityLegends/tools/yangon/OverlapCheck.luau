--[[
	OverlapCheck (Studio; 2026-11-26, owner: "the gas station and a building is merged in together", Myanmar Plaza):
	map-wide 3D overlap check of every PLACED thing against the district buildings and against each other.

	Placed things (group = one venue / place / landmark):
	  - places data Data_<tag>P (fuel stations, car parks, pitches, playgrounds): built from the data, clustered per place
	  - Workspace.Yangon1to1 Sites (venue pads; in Play also what the venue code builds there), CarCare, Landmarks,
	    Pagodas, Parks, InyaBund, and in Play the venue models the server builds (Workspace.City, if present)
	Checked against:
	  - every building shell (Workspace.Yangon1to1.Buildings.Shell: the collision boxes and roofs)
	  - the client kit detail of the tiles round each thing (Data_<tag>, Data_<tag>G trees, Data_<tag>S street props),
	    with the KeepOut boxes taken out exactly as YangonKitStream does
	  - every other placed thing
	An overlap = two boxes that go more than TOL (0.5) studs into each other on every axis (separating-axis depth).
	Invisible parts that don't collide are skipped.

	local O = require(ServerStorage.ClaudeTools.OverlapCheck:Clone())
	O.spawn()            -- runs in the background; O.status() / _G.OVL_STATUS; box pairs in _G.OVL, then the exact pass
	                     -- (a MeshPart counts only if its triangles go TOL into the other box) in _G.OVL_EXACT; O.report()
	Run in Edit for the map; on the Server in Play to include the built venues.
]]

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local O = {}
O.TOL = 0.5
-- things built onto each other on purpose (not counted): a venue on its own pad, the Meliá joined to Myanmar Plaza (owner,
-- 16 Nov), signs / floodlights / shops mounted on a landmark, the plinth on The Central's plaza
O.JOINED = {
	["CarCare:legends_service|Sites:service"] = true,
	["Landmarks:MyanmarCentre|Landmarks:Sedona"] = true,
	["Landmarks:IrlSigns21Nov:MyanmarPlaza_LED|Landmarks:MyanmarCentre"] = true,
	["Landmarks:IrlSigns21Nov:MyanmarPlaza_LEDFrame|Landmarks:MyanmarCentre"] = true,
	["Landmarks:IrlSigns21Nov:Billboards|Landmarks:MyanmarCentre"] = true,
	["Landmarks:IrlNight21Nov:SuleShops|Landmarks:Sule"] = true,
	["Landmarks:IrlNight21Nov:SuleRoundabout|Landmarks:Sule"] = true,
	["Landmarks:IrlSigns21Nov:TheCentral_Plinth|Parks:TheCentral"] = true,
}
local function joined(a: string, b: string): boolean
	return O.JOINED[a .. "|" .. b] or O.JOINED[b .. "|" .. a] or false
end
O.KIT_PAD = 24 -- studs round a thing's box: kit tiles in reach are built

local function axes(cf: CFrame)
	return { cf.RightVector, cf.UpVector, cf.LookVector }
end

-- separating-axis depth of two boxes (> 0 = they overlap that much along the shallowest axis)
function O.depth(acf: CFrame, asz: Vector3, bcf: CFrame, bsz: Vector3): number
	local A, B = axes(acf), axes(bcf)
	local ea = { asz.X / 2, asz.Y / 2, asz.Z / 2 }
	local eb = { bsz.X / 2, bsz.Y / 2, bsz.Z / 2 }
	local t = bcf.Position - acf.Position
	local best = math.huge
	local function test(ax: Vector3)
		local ra = ea[1] * math.abs(A[1]:Dot(ax)) + ea[2] * math.abs(A[2]:Dot(ax)) + ea[3] * math.abs(A[3]:Dot(ax))
		local rb = eb[1] * math.abs(B[1]:Dot(ax)) + eb[2] * math.abs(B[2]:Dot(ax)) + eb[3] * math.abs(B[3]:Dot(ax))
		local o = ra + rb - math.abs(t:Dot(ax))
		if o < best then
			best = o
		end
		return best > 0
	end
	for i = 1, 3 do
		if not test(A[i]) or not test(B[i]) then
			return best
		end
	end
	for i = 1, 3 do
		for j = 1, 3 do
			local c = A[i]:Cross(B[j])
			if c.Magnitude > 1e-4 and not test(c.Unit) then
				return best
			end
		end
	end
	return best
end

local function aabb(cf: CFrame, sz: Vector3): (Vector3, Vector3)
	local h = sz / 2
	local r = cf.RightVector * h.X
	local u = cf.UpVector * h.Y
	local l = cf.LookVector * h.Z
	local e = Vector3.new(
		math.abs(r.X) + math.abs(u.X) + math.abs(l.X),
		math.abs(r.Y) + math.abs(u.Y) + math.abs(l.Y),
		math.abs(r.Z) + math.abs(u.Z) + math.abs(l.Z)
	)
	return cf.Position - e, cf.Position + e
end

local function counts(p: BasePart): boolean
	return p.Transparency < 1 or p.CanCollide
end

-- a 2D grid of boxes (64-stud cells)
local CELL = 64
local function newGrid()
	return { cells = {} }
end
local function gridAdd(g, item)
	for i = math.floor(item.lo.X / CELL), math.floor(item.hi.X / CELL) do
		for j = math.floor(item.lo.Z / CELL), math.floor(item.hi.Z / CELL) do
			local k = i * 100000 + j
			local c = g.cells[k]
			if not c then
				c = {}
				g.cells[k] = c
			end
			table.insert(c, item)
		end
	end
end
local function gridQuery(g, lo: Vector3, hi: Vector3, fn)
	local seen = {}
	for i = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
		for j = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
			for _, it in g.cells[i * 100000 + j] or {} do
				if not seen[it] then
					seen[it] = true
					if it.hi.X >= lo.X and it.lo.X <= hi.X and it.hi.Z >= lo.Z and it.lo.Z <= hi.Z and it.hi.Y >= lo.Y and it.lo.Y <= hi.Y then
						fn(it)
					end
				end
			end
		end
	end
end

local function item(p: BasePart, group: string, kind: string)
	local lo, hi = aabb(p.CFrame, p.Size)
	return { cf = p.CFrame, size = p.Size, lo = lo, hi = hi, name = p.Name, group = group, kind = kind, part = p }
end

local status = "idle"
function O.status()
	return status
end
local function say(s)
	status = s
	_G.OVL_STATUS = s
end

-- district of each 256 tile, from the Data_<tag> folders
local function districtMap(root)
	local m = {}
	for _, f in root:GetChildren() do
		local tag = string.match(f.Name, "^Data_(P%d+)$")
		if tag then
			for _, v in f:GetChildren() do
				if v.Name ~= "Meta" then
					m[v.Name] = tag
				end
			end
		end
	end
	return m
end

function O.run(opts)
	opts = opts or {}
	local KD = require(RS.Shared.YangonKitData:Clone())
	local root = RS.YgnKit
	local T = KD.index(root.Templates)
	local map = workspace:FindFirstChild("Yangon1to1")
	local tmp = Instance.new("Folder")
	tmp.Name = "_OverlapCheckTmp"
	tmp.Archivable = false
	tmp.Parent = SS
	local dmap = districtMap(root)
	local function districtAt(x: number, z: number): string
		local i, j = math.floor(x / 256), math.floor(z / 256)
		for r = 0, 4 do -- (a landmark site has no kit tile of its own: the nearest tile's district)
			for di = -r, r do
				for dj = -r, r do
					local d = dmap[(i + di) .. "_" .. (j + dj)]
					if d then
						return d
					end
				end
			end
		end
		return "?"
	end

	local function buildTile(folder: Instance, v: StringValue, meta, parent: Instance)
		local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
		local job = KD.job(v.Value, tonumber(i) :: number, tonumber(j) :: number, meta, T, parent)
		local n = 0
		while not job:step(1500) do
			n += 1
			if n % 2 == 0 then
				task.wait()
			end
		end
	end

	-- 1. placed things
	say("placed things")
	local placed = {} -- items
	local function addModelGroups(folder: Instance?, prefix: string)
		if not folder then
			return
		end
		for _, ch in folder:GetChildren() do
			if ch:IsA("BasePart") then
				if counts(ch) then
					table.insert(placed, item(ch, prefix .. ":" .. ch.Name, "placed"))
				end
			elseif string.match(ch.Name, "^Irl") then
				addModelGroups(ch, prefix .. ":" .. ch.Name)
			else
				for _, p in ch:GetDescendants() do
					if p:IsA("BasePart") and counts(p) then
						table.insert(placed, item(p, prefix .. ":" .. ch.Name, "placed"))
					end
				end
			end
		end
	end
	if map then
		for _, n in { "Sites", "CarCare", "Landmarks", "Pagodas", "Parks", "InyaBund" } do
			addModelGroups(map:FindFirstChild(n), n)
		end
	end
	for _, extra in opts.extra or {} do
		addModelGroups(extra[1], extra[2])
	end
	-- places data, one group per place (parts touching each other, per district)
	for _, f in root:GetChildren() do
		local tag = string.match(f.Name, "^Data_(P%d+)P$")
		if tag then
			local meta = KD.meta(f)
			local holder = Instance.new("Folder")
			holder.Name = f.Name
			holder.Parent = tmp
			for _, v in f:GetChildren() do
				if v:IsA("StringValue") and v.Name ~= "Meta" then
					buildTile(f, v, meta, holder)
				end
			end
			local its = {}
			for _, p in holder:GetDescendants() do
				if p:IsA("BasePart") and counts(p) then
					table.insert(its, item(p, "", "placed"))
				end
			end
			-- union-find on boxes within 3 studs
			local parent = {}
			local function find(a)
				while parent[a] ~= a do
					parent[a] = parent[parent[a]]
					a = parent[a]
				end
				return a
			end
			local g = newGrid()
			for k, it in its do
				parent[k] = k
				it.k = k
				gridAdd(g, it)
			end
			local pad = Vector3.new(3, 3, 3)
			for _, it in its do
				gridQuery(g, it.lo - pad, it.hi + pad, function(o)
					local a, b = find(it.k), find(o.k)
					if a ~= b then
						parent[a] = b
					end
				end)
			end
			local name = {}
			for _, it in its do
				local r = find(it.k)
				if not name[r] then
					local c = its[r].cf.Position
					name[r] = string.format("%sP:place@%d,%d", tag, math.round(c.X), math.round(c.Z))
				end
				it.group = name[r]
				table.insert(placed, it)
			end
			task.wait()
		end
	end

	-- group boxes
	local groups = {}
	for _, it in placed do
		local g = groups[it.group]
		if not g then
			g = { lo = it.lo, hi = it.hi, n = 0 }
			groups[it.group] = g
		end
		g.lo = g.lo:Min(it.lo)
		g.hi = g.hi:Max(it.hi)
		g.n += 1
	end
	local placedGrid = newGrid()
	for _, it in placed do
		gridAdd(placedGrid, it)
	end

	-- 2. shells
	say("shells")
	local shellGrid = newGrid()
	local nShell = 0
	if map then
		for _, cellF in map.Buildings.Shell:GetChildren() do
			for _, p in cellF:GetDescendants() do
				if p:IsA("BasePart") and counts(p) then
					gridAdd(shellGrid, item(p, "shell:" .. cellF.Name, "shell"))
					nShell += 1
				end
			end
			if nShell % 20000 < 600 then
				task.wait()
			end
		end
	end

	-- 3. kit detail tiles near the placed things (built once, KeepOut taken out)
	say("kit tiles")
	local keepOut = {}
	for _, b in (root:FindFirstChild("KeepOut") and root.KeepOut:GetChildren() or {}) do
		if b:IsA("BasePart") then
			table.insert(keepOut, { inv = b.CFrame:Inverse(), hx = b.Size.X / 2, hz = b.Size.Z / 2 })
		end
	end
	local function inKeepOut(pos: Vector3): boolean
		for _, k in keepOut do
			local l = k.inv * pos
			if math.abs(l.X) < k.hx and math.abs(l.Z) < k.hz then
				return true
			end
		end
		return false
	end
	local kitFolders = {}
	for _, f in root:GetChildren() do
		if string.match(f.Name, "^Data_P%d+[GS]?$") then
			table.insert(kitFolders, f)
		end
	end
	local need = {}
	for _, g in groups do
		for i = math.floor((g.lo.X - O.KIT_PAD) / 256), math.floor((g.hi.X + O.KIT_PAD) / 256) do
			for j = math.floor((g.lo.Z - O.KIT_PAD) / 256), math.floor((g.hi.Z + O.KIT_PAD) / 256) do
				need[i .. "_" .. j] = true
			end
		end
	end
	local kitGrid = newGrid()
	local nTiles, nKit = 0, 0
	for _, f in kitFolders do
		local meta = KD.meta(f)
		local kind = if string.sub(f.Name, -1) == "G" then "tree" elseif string.sub(f.Name, -1) == "S" then "street" else "kit"
		for key in need do
			local v = f:FindFirstChild(key)
			if v then
				local holder = Instance.new("Folder")
				holder.Name = f.Name .. ":" .. key
				holder.Parent = tmp
				buildTile(f, v :: StringValue, meta, holder)
				for _, p in holder:GetDescendants() do
					if p:IsA("BasePart") and counts(p) and not inKeepOut(p.Position) then
						gridAdd(kitGrid, item(p, kind .. ":" .. f.Name .. ":" .. key, kind))
						nKit += 1
					end
				end
				holder:Destroy()
				nTiles += 1
				if nTiles % 10 == 0 then
					say(string.format("kit tiles %d", nTiles))
					task.wait()
				end
			end
		end
	end

	-- 4. pairs
	say("pairs")
	local rows = {}
	local pairSeen = {}
	local tolV = Vector3.new(O.TOL, O.TOL, O.TOL)
	local function check(a, b)
		local d = O.depth(a.cf, a.size, b.cf, b.size)
		if d > O.TOL then
			local c = a.cf.Position
			table.insert(rows, {
				district = districtAt(c.X, c.Z),
				a = a.group,
				aname = a.name,
				apos = c,
				b = b.group,
				bkind = b.kind,
				bname = b.name,
				bpos = b.cf.Position,
				bsize = b.size,
				depth = d,
				apart = a.part,
				bpart = b.part,
			})
		end
	end
	for n, a in placed do
		local lo, hi = a.lo + tolV, a.hi - tolV
		gridQuery(shellGrid, lo, hi, function(b)
			check(a, b)
		end)
		gridQuery(kitGrid, lo, hi, function(b)
			check(a, b)
		end)
		gridQuery(placedGrid, lo, hi, function(b)
			if b.group ~= a.group and a.group < b.group and not joined(a.group, b.group) then
				local k = a.part:GetDebugId() .. b.part:GetDebugId()
				if not pairSeen[k] then
					pairSeen[k] = true
					check(a, b)
				end
			end
		end)
		if n % 2000 == 0 then
			say(string.format("pairs %d / %d", n, #placed))
			task.wait()
		end
	end
	tmp:Destroy()
	_G.OVL = rows
	say(string.format("done: %d placed parts in %d groups, %d shells, %d kit parts (%d tiles), %d overlapping part pairs", #placed, (function()
		local c = 0
		for _ in groups do
			c += 1
		end
		return c
	end)(), nShell, nKit, nTiles, #rows))
	return rows
end

-- second pass on the box hits: a MeshPart's box is often far bigger than its mesh (landmark hills, gable roofs, tree
-- crowns), so a pair with a mesh only counts when the mesh's own triangles go more than TOL into the other box
local AS = game:GetService("AssetService")
local meshCache = {}
local function meshTris(mp: MeshPart)
	local id = mp.MeshId
	local m = meshCache[id]
	if m == nil then
		local ok, em = pcall(function()
			return AS:CreateEditableMeshAsync(Content.fromUri(id))
		end)
		if not ok or not em then
			meshCache[id] = false
			return nil
		end
		local pos, tris = {}, {}
		for _, v in em:GetVertices() do
			pos[v] = em:GetPosition(v)
		end
		for _, f in em:GetFaces() do
			local a = em:GetFaceVertices(f)
			table.insert(tris, { pos[a[1]], pos[a[2]], pos[a[3]] })
		end
		em:Destroy()
		m = { tris = tris }
		meshCache[id] = m
	end
	if not m then
		return nil
	end
	local s = mp.Size / mp.MeshSize
	local cf = mp.CFrame
	local out = table.create(#m.tris)
	for k, t in m.tris do
		out[k] = { cf * (t[1] * s), cf * (t[2] * s), cf * (t[3] * s) }
	end
	return out
end

-- does a triangle cut a box (centre c, axes A, half sizes e)? separating axes
local function triBox(t, c: Vector3, A, e)
	local v0, v1, v2 = t[1] - c, t[2] - c, t[3] - c
	local function sep(ax: Vector3): boolean
		if ax.Magnitude < 1e-6 then
			return false
		end
		local p0, p1, p2 = v0:Dot(ax), v1:Dot(ax), v2:Dot(ax)
		local r = e[1] * math.abs(A[1]:Dot(ax)) + e[2] * math.abs(A[2]:Dot(ax)) + e[3] * math.abs(A[3]:Dot(ax))
		return math.min(p0, p1, p2) > r or math.max(p0, p1, p2) < -r
	end
	for i = 1, 3 do
		if sep(A[i]) then
			return false
		end
	end
	local f0, f1, f2 = v1 - v0, v2 - v1, v0 - v2
	if sep(f0:Cross(f2)) then
		return false
	end
	for i = 1, 3 do
		if sep(A[i]:Cross(f0)) or sep(A[i]:Cross(f1)) or sep(A[i]:Cross(f2)) then
			return false
		end
	end
	return true
end

local function meshIntoBox(mp: MeshPart, bcf: CFrame, bsz: Vector3, tol: number): boolean
	local e = { bsz.X / 2 - tol, bsz.Y / 2 - tol, bsz.Z / 2 - tol }
	if e[1] <= 0 or e[2] <= 0 or e[3] <= 0 then
		return false
	end
	local tris = meshTris(mp)
	if not tris then
		return true -- unreadable mesh: keep the box answer
	end
	local A = axes(bcf)
	local lo, hi = aabb(bcf, Vector3.new(e[1] * 2, e[2] * 2, e[3] * 2))
	local c = bcf.Position
	for _, t in tris do
		local a, b, d = t[1], t[2], t[3]
		if math.max(a.X, b.X, d.X) >= lo.X and math.min(a.X, b.X, d.X) <= hi.X and math.max(a.Y, b.Y, d.Y) >= lo.Y
			and math.min(a.Y, b.Y, d.Y) <= hi.Y and math.max(a.Z, b.Z, d.Z) >= lo.Z and math.min(a.Z, b.Z, d.Z) <= hi.Z
			and triBox(t, c, A, e) then
			return true
		end
	end
	return false
end

function O.exact(r): boolean
	local a, b = r.apart, r.bpart
	local am, bm = a:IsA("MeshPart"), b:IsA("MeshPart")
	if not am and not bm then
		return true
	end
	if am and not meshIntoBox(a, b.CFrame, b.Size, O.TOL) then
		return false
	end
	if bm and not meshIntoBox(b, a.CFrame, a.Size, O.TOL) then
		return false
	end
	return true
end

function O.refine(rows)
	rows = rows or _G.OVL
	local keep = {}
	for n, r in rows do
		if O.exact(r) then
			table.insert(keep, r)
		end
		if n % 50 == 0 then
			say(string.format("exact %d / %d (kept %d)", n, #rows, #keep))
			task.wait()
		end
	end
	_G.OVL_EXACT = keep
	say(string.format("exact done: %d of %d box pairs are real", #keep, #rows))
	return keep
end

-- per district, per placed thing: what it overlaps (one line per other thing; shells / kit by tile)
function O.report(rows)
	rows = rows or _G.OVL_EXACT or _G.OVL or {}
	local by = {}
	for _, r in rows do
		local k = r.district .. "|" .. r.a .. "|" .. r.b
		local e = by[k]
		if not e then
			e = { district = r.district, a = r.a, b = r.b, kind = r.bkind, n = 0, depth = 0, names = {} }
			by[k] = e
		end
		e.n += 1
		e.depth = math.max(e.depth, r.depth)
		e.names[r.aname .. ">" .. r.bname] = true
	end
	local list = {}
	for _, e in by do
		table.insert(list, e)
	end
	table.sort(list, function(x, y)
		if x.district ~= y.district then
			return x.district < y.district
		end
		if x.a ~= y.a then
			return x.a < y.a
		end
		return x.b < y.b
	end)
	local out = {}
	for _, e in list do
		local nm = {}
		for k in e.names do
			table.insert(nm, k)
		end
		table.sort(nm)
		table.insert(out, string.format("%s | %s | %s (%s) | %d pairs | max %.1f | %s", e.district, e.a, e.b, e.kind, e.n, e.depth, table.concat(nm, " ", 1, math.min(#nm, 4))))
	end
	return out
end

function O.spawn(opts)
	say("starting")
	task.spawn(function()
		local ok, err = pcall(function()
			local rows = O.run(opts)
			O.refine(rows)
		end)
		if not ok then
			say("ERROR " .. tostring(err))
		end
	end)
end

return O
