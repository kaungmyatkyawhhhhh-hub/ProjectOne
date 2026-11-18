--[[
	Roads05StudioTest (Studio, Edit; J16, 18 Nov 2026): builds the roads05 Studio test spots one at a time, with the paint.
	Data: tools/yangon/city/roads05_studiotest.py -> imports/sync/roads05_studiotest.rbxmx -> PATCH of asset 133014134133489
	(open_cloud_invoke, content type model/x-rbxm). Then, in execute_luau calls (each under ~5 s; long work is spawned):

		-- 1. load (spawned; poll _G.RT.state until "loaded ..." or "ERR ...")
		local m = game:GetService("InsertService"):LoadAsset(133014134133489)
		local T = require(m:FindFirstChild("Roads05StudioTest", true):Clone())
		_G.RT = T  T.install(m)          -- moves the modules, makes the no-terrain copy, Y.load(), reads spots + paint
		-- 2. one spot (spawned; poll T.log[name] until not "running")
		_G.RT.run("ycentral")            -- workspace.Roads05Test.<name>: roads (lifted T.LIFT), then the paint
		-- 3. cameras for screen_capture (lift added): _G.RT.cam("ycentral", "overview" | "closeup" | "driver")
		-- 4. _G.RT.clean() (spawned): scratch folder, YangonScraps, data modules, the copy; poll _G.RT.state == "clean ..."

	Terrain: the copy of YangonRoads has every `workspace.Terrain:Fill*` call swapped for a no-op (counted in T.fills),
	so the place's terrain is never written. Paint: triangles rayed onto the built surface (40 studs above the data
	height ... 40 under it, the hit nearest the data height), laid T.PAINT_LIFT over it as two WedgeParts each; a vertex with no surface within 6 studs of its data height
	is counted and its triangle left out (T.log[name]).
]]

local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")

local T = {}
T.LIFT = 400
T.PAINT_LIFT = 0.08
T.PAINT_T = 0.04
T.log = {}
T.state = "new"
T.fills = 0
T.COLOR = {
	LW = Color3.fromRGB(232, 232, 226),
	LY = Color3.fromRGB(232, 184, 52),
	LZ = Color3.fromRGB(230, 190, 110),
}

local function sum(t)
	local h = 0
	for i = 1, #t do
		h = (h * 31 + string.byte(t, i)) % 2147483647
	end
	return h
end
T.sum = sum

function T.install(model: Instance)
	T.state = "installing"
	task.spawn(function()
		local ok, err = pcall(function()
			local f = model:FindFirstChild("YangonToolsIn", true)
			local YD = SS.YangonData
			for _, c in YD:GetChildren() do
				if c.Name:match("^Roads05_") then
					c:Destroy()
				end
			end
			local paint, spots, n = {}, nil, 0
			for _, c in f:GetChildren() do
				if c.Name:match("^Roads05_%d") then
					c.Parent = YD
					n += 1
				elseif c.Name:match("^Roads05Paint_") then
					paint[tonumber(c.Name:match("%d+$"))] = require(c)
				elseif c.Name == "Roads05Spots" then
					spots = Http:JSONDecode(require(c))
				elseif c.Name == "YangonRoads" or c.Name == "YangonRoadsChecks" or c.Name == "Roads" then
					-- (J21: Roads.luau is packed too: the builder's edge pin lives there)
					local o = SS.ClaudeTools:FindFirstChild(c.Name)
					if o then
						o:Destroy()
					end
					c.Parent = SS.ClaudeTools
				end
			end
			model:Destroy()
			T.spots = spots
			T.paint = {}
			for _, chunk in paint do
				for line in chunk:gmatch("[^\n]+") do
					table.insert(T.paint, line)
				end
			end
			-- the no-terrain copy (never parented to the place: required from nil)
			_G.RTNoTerrain = {
				FillBlock = function() T.fills += 1 end,
				FillCylinder = function() T.fills += 1 end,
				FillBall = function() T.fills += 1 end,
				FillWedge = function() T.fills += 1 end,
			}
			local src, k = SS.ClaudeTools.YangonRoads.Source:gsub("workspace%.Terrain:Fill", "_G.RTNoTerrain:Fill")
			local j = SS.ClaudeTools.YangonRoads:Clone()
			j.Name = "YangonRoadsRT"
			j.Source = src
			T.yrSum = sum(SS.ClaudeTools.YangonRoads.Source)
			local Y = require(j)
			Y.load()
			-- (J29) a deck is built when any of its samples is in the box (the bake keeps one owner cell per deck): a
			-- deck whose middle lay outside a test box was never built and its ground road met nothing (double_junction)
			Y.DECK_TOUCH = true
			T.Y = Y
			T.state = string.format("loaded %d roads, %d data modules, %d paint tris, %d fill calls swapped, YR %d", #Y.list, n, #T.paint, k, T.yrSum)
		end)
		if not ok then
			T.state = "ERR " .. tostring(err)
		end
	end)
	return "spawned"
end

-- two WedgeParts make a triangle (a, b, c world points)
local function tri(a, b, c, parent, color)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude < 1e-3 or ac.Magnitude < 1e-3 or bc.Magnitude < 1e-3 then
		return 0
	end
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-6 then
		return 0
	end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local h = math.abs(ab:Dot(up))
	local n = 0
	for _, w in { { (a + b) / 2, right, math.abs(ab:Dot(back)) }, { (a + c) / 2, -right, math.abs(ac:Dot(back)) } } do
		if w[3] > 1e-3 and h > 1e-3 then
			local p = Instance.new("WedgePart")
			p.Name = "Paint"
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.SmoothPlastic
			p.Color = color
			p.Size = Vector3.new(T.PAINT_T, h, w[3])
			local s = if w[2] == right then 1 else -1
			p.CFrame = CFrame.fromMatrix(w[1], w[2], up, back * s)
			p.Parent = parent
			n += 1
		end
	end
	return n
end

function T.layPaint(sp, folder)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { folder }
	local pf = Instance.new("Folder")
	pf.Name = "Paint"
	pf.Parent = folder
	T.far = 0
	local miss, skipped, parts, chunk = 0, 0, 0, Instance.new("Folder")
	chunk.Name = "c"
	for li = sp.paint[1], sp.paint[2] do
		local line = T.paint[li]
		local k, rest = line:match("^(%S+) (.*)$")
		local v = {}
		for u in rest:gmatch("%S+") do
			table.insert(v, tonumber(u))
		end
		local pts = {}
		for q = 0, 2 do
			local x, z, y = v[q * 3 + 1], v[q * 3 + 2], v[q * 3 + 3] + T.LIFT
			-- the surface nearest the data height (a ground line under a deck, a deck line over a road; up to 4 layers)
			local hit, o = nil, Vector3.new(x, y + 40, z)
			for _ = 1, 4 do
				local h = workspace:Raycast(o, Vector3.new(0, y - 40 - o.Y, 0), rp)
				if not h then
					break
				end
				if not hit or math.abs(h.Position.Y - y) < math.abs(hit.Position.Y - y) then
					hit = h
				end
				o = h.Position - Vector3.new(0, 0.05, 0)
			end
			if hit and math.abs(hit.Position.Y - y) > 6 then
				T.far = (T.far or 0) + 1 -- no surface within 6 studs of the data height (e.g. a deck not built in this box)
				hit = nil
			end
			if hit then
				pts[q + 1] = hit.Position + hit.Normal * (T.PAINT_LIFT + T.PAINT_T / 2)
			else
				miss += 1
			end
		end
		if pts[1] and pts[2] and pts[3] then -- paint never hangs in the air: a triangle with a vertex off every surface is left out
			parts += tri(pts[1], pts[2], pts[3], chunk, T.COLOR[k] or T.COLOR.LW)
		else
			skipped += 1
		end
		if (li - sp.paint[1]) % 400 == 399 then
			chunk.Parent = pf
			chunk = Instance.new("Folder")
			chunk.Name = "c"
			task.wait()
		end
	end
	chunk.Parent = pf
	return string.format("paint tris %d wedges %d, vertices off the surface %d (of them over 6 studs from the data height %d), tris left out %d", sp.paint[2] - sp.paint[1] + 1, parts, miss, T.far, skipped)
end

function T.run(name: string)
	local sp = T.spots[name]
	local root = workspace:FindFirstChild("Roads05Test") or Instance.new("Folder")
	root.Name = "Roads05Test"
	root.Parent = workspace
	for _, o in root:GetChildren() do
		o:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	T.log[name] = "running"
	task.spawn(function()
		local fills0 = T.fills
		local ok, res = pcall(function()
			return T.Y.stepCell(sp.box, f)
		end)
		local n = 0
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame += Vector3.new(0, T.LIFT, 0)
				n += 1
				if n % 3000 == 0 then
					task.wait()
				end
			end
		end
		local pr = if ok then T.layPaint(sp, f) else "no paint"
		T.log[name] = string.format("%s %s | parts lifted %d | terrain writes skipped %d | %s", ok and "OK" or "ERR", tostring(res), n, T.fills - fills0, pr)
	end)
	return "spawned " .. name
end

-- (J28 QA) the built-surface check, deterministic: T.qa(name) = YangonRoads.qaBuilt's rules on the spot just built
-- (T.run), but the same build always gives the same counts:
--   * fixed grid: cell (i, j) casts at x0 + i G + OX, z0 + j G + OZ; the small fixed offsets keep rays off the whole /
--     half-stud lines where piece edges lie (a ray down a shared edge hit or missed by float luck);
--   * fixed re-cast rules: a side-face hit is cast again at 3 fixed offsets, a miss at 2 (as qaBuilt);
--   * the top is chosen, not taken: every up-facing part within TIE of the first hit is gathered (short rays, the found
--     parts excluded) and the one first by (Kerb, Pavement, Road, other; highest; road name; part position) is the cell's
--     top, so an overlap never depends on which part the engine's tree returns first;
--   * one fixed scan order (i, then j), 4-stud dedup as qaBuilt.
-- Each fault keeps both cells (kind, road = part's folder, part name, height) in T.faults[name] for the census.
-- T.fingerprint(name) hashes the built parts (sorted), to tell a changed build from a changed check.
T.QA_G, T.QA_OX, T.QA_OZ, T.QA_TIE, T.QA_MARGIN = 0.5, 0.0173, 0.0311, 0.011, 20
T.faults, T.qaLog = {}, {}
local ORDER = { Kerb = 1, Pavement = 2, Road = 3 }
local MISS_RING = { { 0.003, 0.002 }, { 0.006, 0.004 }, { 0.03, 0 }, { 0, 0.03 }, { -0.03, 0 }, { 0, -0.03 }, { 0.05, 0.05 }, { -0.05, -0.05 } }
local function topKey(r)
	local p = r.Instance
	return string.format("%d|%09.3f|%s|%s|%.3f,%.3f,%.3f", ORDER[p.Name] or 9, 9999 - r.Position.Y, p.Parent and p.Parent.Name or "", p.Name, p.Position.X, p.Position.Y, p.Position.Z)
end

function T.qaCore(root: Instance, x0: number, z0: number, x1: number, z1: number)
	local Y = T.Y
	local G, OX, OZ, TIE = T.QA_G, T.QA_OX, T.QA_OZ, T.QA_TIE
	local MG = math.floor(T.QA_MARGIN / G)
	local STEP = 0.1 + 0.19 * G
	local P = RaycastParams.new()
	P.FilterType = Enum.RaycastFilterType.Include
	P.FilterDescendantsInstances = { root }
	local nx, nz = math.floor((x1 - x0) / G), math.floor((z1 - z0) / G)
	local Y0, DOWN = 3000, Vector3.new(0, -3500, 0)
	local kind, hy, inst, deckCell = {}, {}, {}, {}
	local function cast(x, z)
		return workspace:Raycast(Vector3.new(x, Y0, z), DOWN, P)
	end
	for i = 0, nx do
		for j = 0, nz do
			local x, z = x0 + i * G + OX, z0 + j * G + OZ
			local r = cast(x, z)
			local t = 0
			while r and r.Normal.Y < 0.5 and t < 3 do
				t += 1
				r = cast(x + 0.04 * t, z + 0.03 * t)
			end
			-- a miss is cast again at fixed offsets up to 0.05 (J28 QA false positive: long_median (42920, 28124) and 38 more
			-- 'pave_gap' pinholes were rays through a < 0.005 crack where pavement wedges meet: invisible, and narrower than
			-- the 0.05 flicker gap)
			for _, o in MISS_RING do
				if r and r.Normal.Y >= 0.5 then
					break
				end
				r = cast(x + o[1], z + o[2]) or r
			end
			if r and r.Normal.Y >= 0.5 then
				local best, bk = r, topKey(r)
				local ex = { r.Instance }
				for _ = 1, 6 do
					local P2 = RaycastParams.new()
					P2.FilterType = Enum.RaycastFilterType.Exclude
					P2.FilterDescendantsInstances = ex
					local r2 = workspace:Raycast(r.Position + Vector3.new(0, TIE, 0), Vector3.new(0, -2 * TIE, 0), P2)
					if not (r2 and r2.Instance:IsDescendantOf(root)) then
						break
					end
					table.insert(ex, r2.Instance)
					if r2.Normal.Y >= 0.5 then
						local k2 = topKey(r2)
						if k2 < bk then
							best, bk = r2, k2
						end
					end
				end
				r = best
			end
			local k = i * (nz + 1) + j
			if r and r.Normal.Y < 0.5 then
				kind[k] = "Edge"
			elseif r then
				local n = r.Instance.Name
				kind[k] = if n == "Road" or n == "Kerb" or n == "Pavement" then n else "Other"
				hy[k] = r.Position.Y
				inst[k] = r.Instance
				deckCell[k] = Y.deckHalf ~= nil and Y.deckHalf[r.Instance.Parent.Name] ~= nil
			else
				kind[k] = "None"
			end
		end
		if i % 20 == 0 then
			task.wait()
		end
	end
	local out, seen, list = {}, {}, {}
	local function cell(k)
		local p = inst[k]
		-- kind, road (part's folder), the folder above it (Roads / a mouth's / Decks ...), part class, height (data)
		return { kind[k], p and p.Parent.Name or "", p and p.Parent.Parent and p.Parent.Parent.Name or "", p and p.ClassName or "", hy[k] and math.floor((hy[k] - T.LIFT) * 1000 + 0.5) / 1000 or false }
	end
	local function add(what, i, j, k, q)
		local x, z = x0 + i * G + OX, z0 + j * G + OZ
		local key = what .. math.floor(x / 4) .. "," .. math.floor(z / 4)
		if seen[key] then
			return
		end
		seen[key] = true
		out[what] = (out[what] or 0) + 1
		local nb = {}
		if q == nil then -- a hole: its 4 neighbours
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				table.insert(nb, cell((i + d[1]) * (nz + 1) + j + d[2]))
			end
		else
			nb = { cell(k), cell(q) }
		end
		table.insert(list, { t = what, x = math.floor(x * 100 + 0.5) / 100, z = math.floor(z * 100 + 0.5) / 100, c = nb, edge = math.floor(math.min(x - x0, x1 - x, z - z0, z1 - z)) })
	end
	local function K(i, j)
		return i * (nz + 1) + j
	end
	local freeC = {}
	local function freeEnd(p: Instance?, x: number, z: number): boolean
		local o = p and p.Parent and Y.R[p.Parent.Name]
		if not o then
			return false
		end
		for _, e in { o.s[1], o.s[o.n] } do
			if math.sqrt((e[1] - x) ^ 2 + (e[3] - z) ^ 2) < o.half + 4 then
				local key = o.name .. e[1]
				if freeC[key] == nil then
					freeC[key] = true
					for oi, b in Y.near(e[1], e[3], 2) do
						local q = Y.list[oi]
						if q ~= o and Y.polyDist(q, b[2], e[1], e[3]) < Y.sideHalf(q, b[2], e[1], e[3]) + 2 then
							freeC[key] = false
							break
						end
					end
				end
				if freeC[key] then
					return true
				end
			end
		end
		return false
	end
	-- (J28 QA false positive) the test box clips a road square across its own direction, so where a road crosses the
	-- box edge at an angle its clipped end reaches up to half + walk further in than the box margin: open asphalt there
	-- is the clip, not a builder fault (hledan_flyover, slip_triangle, bahan_ring, hanthawaddy shots)
	local function clipped(p: Instance?, x: number, z: number): boolean
		local o = p and p.Parent and Y.R[p.Parent.Name]
		if not o then
			return false
		end
		local d = math.min(x - x0, x1 - x, z - z0, z1 - z)
		local reach = T.QA_MARGIN + o.half + math.max(o.walkL or 0, o.walkR or 0) + 2
		if d >= reach then
			return false
		end
		for _, e in { o.s[1], o.s[o.n] } do
			if e[1] < x0 or e[1] > x1 or e[3] < z0 or e[3] > z1 then
				return true -- the road runs out of the box: its end here is the box's cut
			end
		end
		return false
	end
	-- (J30 QA false positive) the narrow apex of open ground behind a pavement that wraps a corner nose (block interior,
	-- bahan_ring Lane #6610 (35539, 38067)) has pavement on both sides too, but it widens into open ground: a slot stays
	-- narrow. The nothing connected to the cell within 6 studs: over 150 cells (a 2-stud slot holds about 100) = open ground
	local function openGround(i, j): boolean
		local seenN, stack, n = { [K(i, j)] = true }, { { i, j } }, 0
		while #stack > 0 do
			local c = table.remove(stack)
			n += 1
			if n > 150 then
				return true
			end
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local a2, b2 = c[1] + d[1], c[2] + d[2]
				local q = K(a2, b2)
				if math.abs(a2 - i) <= 12 and math.abs(b2 - j) <= 12 and not seenN[q] and kind[q] == "None" then
					seenN[q] = true
					table.insert(stack, { a2, b2 })
				end
			end
		end
		return false
	end
	-- (J36 QA audit false positive) a kerb crossing the grid at a slant can be thinner than the 0.5 cell diagonal, so a
	-- road cell and a pavement cell touch past it although the kerb is whole (bahan_ring island (35423, 37888): shots
	-- 'fault audit - keg6'). Fixed probes at 0.1 / 0.2 / 0.3 / 0.4 along the pair: any kerb top there = no gap
	local function kerbBetween(x: number, z: number, alongX: boolean): boolean
		for _, f in { 0.1, 0.2, 0.3, 0.4 } do
			local r = cast(x + (if alongX then f else 0), z + (if alongX then 0 else f))
			if r and r.Normal.Y >= 0.5 and r.Instance.Name == "Kerb" then
				return true
			end
		end
		return false
	end
	-- pave_gap (J29 builder ask): an open slot (1-4 cells of nothing) with pavement on both sides, along x or z
	local function paveGap(i, j): boolean
		for _, d in { { 1, 0 }, { 0, 1 } } do
			local a, b = nil, nil
			for s = 1, 4 do
				local q = kind[K(i - d[1] * s, j - d[2] * s)]
				if q ~= "None" then
					a = q
					break
				end
			end
			for s = 1, 4 do
				local q = kind[K(i + d[1] * s, j + d[2] * s)]
				if q ~= "None" then
					b = q
					break
				end
			end
			if a == "Pavement" and b == "Pavement" and not openGround(i, j) then
				return true
			end
		end
		return false
	end
	for i = math.max(1, MG), math.min(nx - 1, nx - MG) do
		for j = math.max(1, MG), math.min(nz - 1, nz - MG) do
			local k = K(i, j)
			local a = kind[k]
			if a == "None" and paveGap(i, j) then
				add("pave_gap", i, j, k, nil)
			end
			if a == "None" then
				local c = 0
				for _, q in { K(i + 1, j), K(i - 1, j), K(i, j + 1), K(i, j - 1) } do
					if kind[q] == "Road" then
						c += 1
					end
				end
				if c >= 3 then
					add("box_hole", i, j, k, nil)
				end
			end
			for _, q in { K(i + 1, j), K(i, j + 1) } do
				local b = kind[q]
				local x, z = x0 + i * G + OX, z0 + j * G + OZ
				if (a == "Road" and b == "None" and deckCell[k]) or (b == "Road" and a == "None" and deckCell[q]) then
					-- a deck's open end in the test subset
				elseif (a == "Road" and b == "None" and freeEnd(inst[k], x, z)) or (b == "Road" and a == "None" and freeEnd(inst[q], x, z)) then
					-- a dead end
				elseif (a == "Road" and b == "None" and clipped(inst[k], x, z)) or (b == "Road" and a == "None" and clipped(inst[q], x, z)) then
					-- the test box's cut of a road crossing its edge at an angle
				elseif a == "Road" and b == "Road" and math.abs(hy[k] - hy[q]) > 3 and (deckCell[k] or deckCell[q]) then
					-- (J28 QA false positive) two levels: a deck's top beside the road under / beside it (a deck clipped
					-- in mid-air by the test box, hledan_flyover). A deck's real foot lands on its road (< 3 apart)
				elseif ((a == "Road" and (b == "Pavement" or b == "None")) or (b == "Road" and (a == "Pavement" or a == "None"))) and not kerbBetween(x, z, q == K(i + 1, j)) then
					add("kerb_gap", i, j, k, q)
				elseif a == "Road" and b == "Road" and math.abs(hy[k] - hy[q]) > STEP then
					add("road_step", i, j, k, q)
				elseif a == "Pavement" and b == "Pavement" and math.abs(hy[k] - hy[q]) > STEP then
					add("pave_step", i, j, k, q)
				elseif (a == "Kerb" and b == "Road" and hy[k] - hy[q] < 0.3) or (b == "Kerb" and a == "Road" and hy[q] - hy[k] < 0.3) then
					add("buried", i, j, k, q)
				end
			end
		end
	end
	return out, list
end

function T.qa(name: string)
	local f = workspace.Roads05Test:FindFirstChild(name)
	local b = T.spots[name].box
	T.qaLog[name] = "running"
	task.spawn(function()
		local ok, out, list = pcall(T.qaCore, f, b[1], b[2], b[3], b[4])
		if not ok then
			T.qaLog[name] = "ERR " .. tostring(out)
			return
		end
		T.faults[name] = list
		local s = {}
		for _, w in { "box_hole", "kerb_gap", "road_step", "pave_step", "buried", "pave_gap" } do
			table.insert(s, tostring(out[w] or 0))
		end
		T.qaLog[name] = table.concat(s, " / ")
	end)
	return "spawned qa " .. name
end

function T.fingerprint(name: string)
	local rows = {}
	for _, d in workspace.Roads05Test[name]:GetDescendants() do
		if d:IsA("BasePart") and d.CanQuery then
			local p, s = d.Position, d.Size
			table.insert(rows, string.format("%s%s%.3f%.3f%.3f%.3f%.3f%.3f%.3f", d.Parent.Name, d.Name, p.X, p.Y, p.Z, s.X, s.Y, s.Z, d.CFrame.LookVector.X + d.CFrame.UpVector.Z))
		end
	end
	table.sort(rows)
	return #rows, sum(table.concat(rows))
end

-- every spot in turn (spawned): build, check, fingerprint; T.allLog = { name = "bh / kg / rs / ps / bu | parts hash" }
function T.runAll(names)
	T.allLog, T.allState = {}, "running"
	task.spawn(function()
		for _, name in names do
			T.allState = "running " .. name
			T.run(name)
			while T.log[name] == "running" do
				task.wait(0.5)
			end
			T.qa(name)
			while T.qaLog[name] == "running" do
				task.wait(0.5)
			end
			local n, h = T.fingerprint(name)
			T.allLog[name] = string.format("%s | %d parts %d", T.qaLog[name], n, h)
		end
		T.allState = "done"
	end)
	return "spawned"
end

function T.cam(name: string, view: string)
	local c = T.spots[name].cams[view]
	return { c.pos[1], c.pos[2] + T.LIFT, c.pos[3] }, { c.at[1], c.at[2] + T.LIFT, c.at[3] }
end

-- what is under screen pixels (judging a shot): {{px, py}, ...}
function T.pick(campos: Vector3, target: Vector3, pts)
	local cam = workspace.CurrentCamera
	local old = cam.CFrame
	cam.CFrame = CFrame.lookAt(campos, target)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Roads05Test }
	local out = {}
	for _, p in pts do
		local ray = cam:ViewportPointToRay(p[1], p[2])
		local h = workspace:Raycast(ray.Origin, ray.Direction * 3000, rp)
		table.insert(out, string.format("(%d,%d) -> %s", p[1], p[2], h and string.format("%.1f %.2f %.1f %s/%s", h.Position.X, h.Position.Y - T.LIFT, h.Position.Z, h.Instance.Parent.Name, h.Instance.Name) or "nothing"))
	end
	cam.CFrame = old
	return table.concat(out, "\n")
end

function T.clean()
	T.state = "cleaning"
	task.spawn(function()
		local root = workspace:FindFirstChild("Roads05Test")
		if root then
			for _, f in root:GetChildren() do
				local n = 0
				for _, c in f:GetDescendants() do
					if c:IsA("BasePart") then
						c:Destroy()
						n += 1
						if n % 2000 == 0 then
							task.wait()
						end
					end
				end
				f:Destroy()
			end
			root:Destroy()
		end
		local sc = SS:FindFirstChild("YangonScraps")
		if sc then
			sc:Destroy()
		end
		local d = 0
		for _, c in SS.YangonData:GetChildren() do
			if c.Name:match("^Roads05") then
				c:Destroy()
				d += 1
			end
		end
		T.Y, T.paint, _G.RTNoTerrain = nil, nil, nil
		T.state = "clean, data modules removed " .. d
	end)
	return "spawned"
end

return T
