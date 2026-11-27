--[[
	YangonKitData (2026-11-16, light pass of the 1:1 Yangon buildings): reads the packed kit detail made by
	tools/yangon/city/buildings_1to1.py + kit_pack.py and builds it from the shared kit templates.

	The place keeps only each building's shell (Workspace.Yangon1to1.Buildings.Shell: its collision boxes drawn in the
	wall colour, plus the pitched roofs). The facade panels, piers, party walls, flat roof slabs, roof props, drainpipes,
	AC units, compound walls and gates are data: ReplicatedStorage.YgnKit.Data_<district> holds a StringValue Meta and one
	StringValue a 256-stud tile ("i_j"). client/YangonKitStream builds the tiles near the camera with this module; the
	Edit tool (tools/yangon/YangonKitPlace.luau `preview`) uses it too.

	Record format (fixed width, 64-symbol digits; see kit_pack.py):
	  P pid(2) x(4) y(3) z(4) yaw(3) sx(3) code(1)            a kit piece
	  Q ... as P ... sy(3) sz(3)                              a kit piece scaled in Y / Z too
	  B x(4) y(3) z(4) yaw(3) sx(3) sy(3) sz(3) code(1)       a plain Part (code WCOL: compound-wall collision)
	Compact buildings (2026-11-16, Meta FORMAT=2, tools/yangon/city/kit_layout.py): a tile string starting with "!" holds
	  H (a building's outline, archetype, floors, wall colour, edge flags) and W (compound-wall runs) records, laid out
	  here by KD.expand into the records above (same code as kit_layout.expand), plus old records.
	Street detail (2026-11-16, tools/yangon/city/street_1to1.py; Data_<district>S, Meta LOAD / ATTACH / ATLAS / CELL):
	  L x1(4) y1(3) z1(4) yaw1(3) x2(4) y2(3) z2(4) yaw2(3) n(1) seed(1)   n black cables between two power poles (Beams
	                                                                        between the Meta ATTACH points of each pole)
	  K x1(4) y1(3) z1(4) x2(4) y2(3) z2(4) sag(2)                         one cable (a service drop to a house)
	  T x(4) y(3) z(4) yaw(3) w(2) h(2) atlas(1) cell(2)                   a name plate: an atlas cell on a SurfaceGui
	                                                                        (faces local -Z; an invisible carrier part)

	local KD = require(ReplicatedStorage.Shared.YangonKitData)
	local T = KD.index(templatesFolder)          -- pid -> pieces
	local meta = KD.meta(dataFolder)             -- { tile, pids, codes }
	local job = KD.job(str, i, j, meta, T, parentFolder)
	while not job:step(200) do task.wait() end   -- builds up to 200 parts a step
]]

local MaterialService = game:GetService("MaterialService")

local KD = {}

local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end
local TWO_PI = 2 * math.pi

local function num(s: string, a: number, n: number): number
	local v = 0
	for k = a, a + n - 1 do
		v = v * 64 + VAL[string.byte(s, k)]
	end
	return v
end
KD.num = num

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- landmark_glb3d.GROUPS (midday calibrated) for the wall codes the generator uses (same as YangonKitPlace)
-- (2026-11-27, TorqX look) KW0 / KW4 / KW6 toned from near pure white to stained off-whites (white walls blew out in sun);
-- the shells in Studio were recoloured to match (place_pack.WALL). Landmarks keep their own colours.
KD.WALL = {
	KW0 = rgb(226, 224, 216), KW1 = rgb(255, 215, 153), KW2 = rgb(178, 242, 255), KW3 = rgb(199, 168, 130),
	KW4 = rgb(200, 208, 204), KW5 = rgb(255, 197, 187), KW6 = rgb(222, 212, 194), KW7 = rgb(208, 255, 165),
	KWG = rgb(162, 160, 150), KWB = rgb(173, 209, 250), KWC = rgb(144, 145, 136), KWD2 = rgb(181, 172, 162),
	-- (2026-11-16, real places: places_1to1.py) fuel stations, car parks, courts, playgrounds
	PCN = rgb(196, 194, 188), PAS = rgb(84, 84, 86), PLN = rgb(236, 236, 230), PLY = rgb(232, 196, 64),
	PCW = rgb(240, 240, 236), PCS = rgb(214, 216, 212), PFG = rgb(46, 140, 82), PFR = rgb(196, 40, 40),
	PFB = rgb(30, 84, 160), PFY = rgb(240, 196, 40), PPD = rgb(40, 42, 46), PGL = rgb(60, 72, 80),
	PST = rgb(150, 154, 160), PRB = rgb(150, 70, 50), PCG = rgb(78, 128, 92), PLT = rgb(255, 250, 236),
	PSD = rgb(214, 196, 160), PCR = rgb(160, 175, 148),
}
-- plain-material codes (no MaterialVariant): Neon canopy lights, glass, plastic
KD.MAT = { PLT = Enum.Material.Neon, PGL = Enum.Material.Glass, PFG = Enum.Material.SmoothPlastic,
	PFR = Enum.Material.SmoothPlastic, PFB = Enum.Material.SmoothPlastic, PFY = Enum.Material.SmoothPlastic,
	PPD = Enum.Material.SmoothPlastic, PLY = Enum.Material.SmoothPlastic, PCW = Enum.Material.SmoothPlastic, PCR = Enum.Material.SmoothPlastic }
KD.VARIANT = {
	-- (2026-11-27, owner: "less blocky, more like real life"; review the same day: the stained render read cold and
	-- grimy with a 9-stud repeat) ordinary walls wear the light, warm weathered render (36-stud tile, render_weathered.py);
	-- the dark grime is the panels' own vertex stains under slabs / roof edge / AC units. Plain side and party walls:
	-- KD.SIDE. Newer / villa-type panels: their template's MV attribute (the clean painted render). Flat roof slabs
	-- (KCO) are stained concrete, not near-white bare concrete.
	KW0 = "YgnRenderWeathered", KW1 = "YgnRenderWeathered", KW2 = "YgnRenderWeathered", KW3 = "YgnRenderWeathered",
	KW4 = "YgnRenderWeathered", KW5 = "YgnRenderWeathered", KW6 = "YgnRenderWeathered", KW7 = "YgnRenderWeathered",
	KWB = "YgnRenderWeathered", KWG = "YgnRenderStained", KWD2 = "YgnRenderStained", KWC = "YgnRenderStained",
	KGR = "YgnSteelPainted", KAR = "YgnCanvas", KCO = "YgnConcreteStained", KRG = "YgnCorrugatedZinc",
	KRF = "YgnCorrugatedRust", KRB = "YgnCorrugatedBlue", KRT = "YgnClayRoofTile",
	PCN = "YgnConcreteStained", PAS = "YgnAsphaltWorn", PLN = "YgnConcreteBare", PCS = "YgnSteelPainted",
	PST = "YgnSteelPainted", PRB = "YgnBrickRed", PCG = "YgnConcreteBare", PSD = "YgnDirtPacked",
}

-- plain side / party walls (B records in a wall colour): more rain streaks than a front (no slabs to hang them from)
KD.SIDE = {
	KW0 = "YgnRenderWeatheredSide", KW1 = "YgnRenderWeatheredSide", KW2 = "YgnRenderWeatheredSide",
	KW3 = "YgnRenderWeatheredSide", KW4 = "YgnRenderWeatheredSide", KW5 = "YgnRenderWeatheredSide",
	KW6 = "YgnRenderWeatheredSide", KW7 = "YgnRenderWeatheredSide", KWB = "YgnRenderWeatheredSide",
}

-- a variant name only if MaterialService has it (else the code's own look stays)
local function hasVariant(name: string?): boolean
	return name ~= nil and name ~= "" and MaterialService:FindFirstChild(name) ~= nil
end

local looks = {} -- code -> { material, variant name }
function KD.look(q: BasePart, code: string, color: Color3?)
	local l = looks[code]
	if not l then
		local v = KD.VARIANT[code]
		local mv = v and MaterialService:FindFirstChild(v)
		if KD.MAT[code] then
			l = { KD.MAT[code], "" }
		elseif mv and mv:IsA("MaterialVariant") then
			l = { mv.BaseMaterial, v }
		else
			l = { Enum.Material.SmoothPlastic, "" }
		end
		looks[code] = l
	end
	q.Material = l[1]
	q.MaterialVariant = l[2]
	q.Color = color or Color3.new(1, 1, 1)
end

-- templates are named KIND_<pid> with attributes C (middle) and S (size) in the piece's own frame
function KD.index(store: Instance)
	local T = {}
	for _, q in store:GetChildren() do
		local kind, pid = string.match(q.Name, "^(%u+)_(%w+)$")
		if kind and q:IsA("BasePart") then
			T[pid] = T[pid] or {}
			-- (2026-11-16, greenery) optional attribute R: the piece's own rotation in the record frame (CFrame; the
			-- reused old-map tree meshes sit turned in their models)
			table.insert(T[pid], { kind = kind, part = q, c = q:GetAttribute("C"), size = q:GetAttribute("S"), r = q:GetAttribute("R") })
		end
	end
	return T
end

function KD.meta(folder: Instance)
	local m = folder:FindFirstChild("Meta")
	if not m then
		return nil
	end
	local text = (m :: StringValue).Value
	local out = { tile = 256, pids = {}, codes = {}, attach = {}, atlas = {} }
	out.tile = tonumber(string.match(text, "TILE=([%d%.]+)")) or 256
	out.load = tonumber(string.match(text, "LOAD=([%d%.]+)") or "")
	for a, b, c in string.gmatch(string.match(text, "ATTACH=([^\n]*)") or "", "([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)") do
		table.insert(out.attach, Vector3.new(tonumber(a) :: number, tonumber(b) :: number, tonumber(c) :: number))
	end
	for w in string.gmatch(string.match(text, "ATLAS=([^\n]*)") or "", "%S+") do
		table.insert(out.atlas, if string.match(w, "^%d+$") then "rbxassetid://" .. w else w)
	end
	local cw, ch, cols = string.match(text, "CELL=(%d+) (%d+) (%d+)")
	out.cell = { tonumber(cw) or 256, tonumber(ch) or 88, tonumber(cols) or 4 }
	for w in string.gmatch(string.match(text, "PIDS=([^\n]*)") or "", "%S+") do
		table.insert(out.pids, w)
	end
	for w in string.gmatch(string.match(text, "CODES=([^\n]*)") or "", "%S+") do
		table.insert(out.codes, w)
	end
	-- (FORMAT=2, compact building data) the layout constants of kit_layout.py
	out.format = tonumber(string.match(text, "FORMAT=(%d+)") or "") or 1
	if out.format >= 2 then
		out.pidIndex, out.codeIndex, out.arch, out.walls, out.wcols = {}, {}, {}, {}, {}
		for k, p in out.pids do
			out.pidIndex[p] = k - 1
		end
		for k, c in out.codes do
			out.codeIndex[c] = k - 1
		end
		for name, a, b, c, d in string.gmatch(string.match(text, "ARCH=([^\n]*)") or "", "(%w+):([^,]+),([^,]+),([^,]+),(%S+)") do
			out.arch[name] = { bay = tonumber(a), gf = tonumber(b), par = tonumber(c), fh = tonumber(d) }
		end
		for w in string.gmatch(string.match(text, "WALLS=([^\n]*)") or "", "%S+") do
			table.insert(out.walls, w)
		end
		for w in string.gmatch(string.match(text, "WCOLS=([^\n]*)") or "", "%S+") do
			table.insert(out.wcols, w)
		end
		local s_, fh_, st_ = string.match(text, "LAYOUT=(%S+) (%S+) (%S+)")
		out.S, out.FH, out.STRETCH = tonumber(s_), tonumber(fh_), tonumber(st_)
	end
	return out
end

--[[ (2026-11-16) compact building data (Meta FORMAT=2, tools/yangon/city/kit_layout.py): a tile string starting with "!"
	holds H (a building: outline + archetype + seed) and W (a chain of compound-wall runs) records plus old records.
	KD.expand lays them out into the old fixed-width string with the SAME code as kit_layout.expand (keep the two in
	step: only + - * / sqrt and floor decide anything, so Python and Luau give the same records). ]]
local CRC = {}
for i = 0, 255 do
	local c = i
	for _ = 1, 8 do
		c = if bit32.band(c, 1) == 1 then bit32.bxor(0xEDB88320, bit32.rshift(c, 1)) else bit32.rshift(c, 1)
	end
	CRC[i] = c
end
local function crc32(s: string): number
	local c = 0xFFFFFFFF
	for k = 1, #s do
		c = bit32.bxor(CRC[bit32.band(bit32.bxor(c, string.byte(s, k)), 255)], bit32.rshift(c, 8))
	end
	return bit32.bxor(c, 0xFFFFFFFF)
end
local function mul32(a: number, b: number): number
	local al = a % 65536
	return (al * b + (((a - al) / 65536 * b) % 65536) * 65536) % 4294967296
end
local function mix(x: number): number
	x = bit32.bxor(x, bit32.rshift(x, 16))
	x = mul32(x, 0x7feb352d)
	x = bit32.bxor(x, bit32.rshift(x, 15))
	x = mul32(x, 0x846ca68b)
	return bit32.bxor(x, bit32.rshift(x, 16))
end
local function rnd(seed: number, k: number): number
	return mix(bit32.bxor(seed, mix(k + 1))) / 4294967296
end
KD.mix, KD.crc32 = mix, crc32

-- kit_panels.stable_id: "p" / "q" + crc32 of the Python repr of the key
local pidCache = {}
local function panelPid(arch, role, floors, k, var, shop, stripe)
	local key = string.format("('%s', '%s', %d, %d, %d, %s, %s)", arch, role, floors, k, var, if shop then "True" else "False",
		if stripe then "True" else "False")
	local p = pidCache[key]
	if not p then
		p = string.format("p%08x", crc32(key))
		pidCache[key] = p
	end
	return p
end
local function propPid(name)
	local key = "('prop', '" .. name .. "')"
	local p = pidCache[key]
	if not p then
		p = string.format("q%08x", crc32(key))
		pidCache[key] = p
	end
	return p
end

local function enc(v: number, n: number): string
	v = math.floor(v + 0.5)
	local t = table.create(n)
	for k = n, 1, -1 do
		local d = v % 64
		t[k] = string.sub(B64, d + 1, d + 1)
		v = (v - d) / 64
	end
	return table.concat(t)
end
local function yawEnc(v: number): string
	return enc(math.floor((v % TWO_PI) / TWO_PI * 262144 + 0.5) % 262144, 3)
end

local LEN = {
	[string.byte("P")] = 21, [string.byte("Q")] = 27, [string.byte("B")] = 25,
	[string.byte("L")] = 31, [string.byte("K")] = 25, [string.byte("T")] = 22,
}
local QO = 10240
local K_SET = { 6, 4, 3, 2, 1 }
local ARCHS = { "walkup", "township", "house", "villa", "condo", "civic", "shed", "market", "colonial" }

local function fitWall(L, bay, STRETCH)
	local best
	local n0 = math.floor(L / bay)
	for n = math.max(1, n0 - 1), n0 + 2 do
		local s = L / (n * bay)
		if math.abs(s - 1) <= STRETCH then
			local c = math.abs(s - 1)
			if best == nil or c < best[1] then
				best = { c, n, s, 0.0 }
			end
		end
		s = math.min(math.max((L - 0.5 * bay) / (n * bay), 1 - STRETCH), 1 + STRETCH)
		local pw = L - n * bay * s
		local ps = pw / (0.5 * bay)
		if 0.3 <= ps and ps <= 1.6 then
			local c = math.abs(s - 1) + 0.3 * math.abs(ps - 1) + 0.05
			if best == nil or c < best[1] then
				best = { c, n, s, ps }
			end
		end
	end
	return best
end

local function inner(ring, px: number, pz: number, d: number): boolean
	local c = false
	local n = #ring
	local j = n
	local d2 = d * d
	for i = 1, n do
		local xi, zi = ring[i][1], ring[i][2]
		local xj, zj = ring[j][1], ring[j][2]
		if (zi > pz) ~= (zj > pz) and px < (xj - xi) * (pz - zi) / (zj - zi) + xi then
			c = not c
		end
		local ex, ez = xj - xi, zj - zi
		local ll = ex * ex + ez * ez
		local t = if ll > 0 then ((px - xi) * ex + (pz - zi) * ez) / ll else 0.0
		t = math.min(math.max(t, 0.0), 1.0)
		local qx, qz = px - (xi + t * ex), pz - (zi + t * ez)
		if qx * qx + qz * qz < d2 then
			return false
		end
		j = i
	end
	return c
end

local function area(ring): number
	local a = 0.0
	local n = #ring
	for i = 1, n do
		local p, q = ring[i], ring[i % n + 1]
		a += p[1] * q[2] - q[1] * p[2]
	end
	return math.abs(a) / 2
end

local function cross(o, a, b)
	return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
end

-- the min-area rectangle: { cx, cz, e1x, e1z, hl, hw } (e1 along the long side), nil if degenerate
local function frame(ring)
	local srt = table.clone(ring)
	table.sort(srt, function(a, b)
		return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
	end)
	local pts = {}
	for _, p in srt do
		local l = pts[#pts]
		if not l or l[1] ~= p[1] or l[2] ~= p[2] then
			table.insert(pts, p)
		end
	end
	if #pts < 3 then
		return nil
	end
	local lo, up = {}, {}
	for _, p in pts do
		while #lo >= 2 and cross(lo[#lo - 1], lo[#lo], p) <= 0 do
			table.remove(lo)
		end
		table.insert(lo, p)
	end
	for k = #pts, 1, -1 do
		local p = pts[k]
		while #up >= 2 and cross(up[#up - 1], up[#up], p) <= 0 do
			table.remove(up)
		end
		table.insert(up, p)
	end
	local hull = {}
	for k = 1, #lo - 1 do
		table.insert(hull, lo[k])
	end
	for k = 1, #up - 1 do
		table.insert(hull, up[k])
	end
	if #hull < 3 then
		return nil
	end
	local best
	local nh = #hull
	for k = 1, nh do
		local a, b = hull[k], hull[k % nh + 1]
		local dx, dz = b[1] - a[1], b[2] - a[2]
		local ll = math.sqrt(dx * dx + dz * dz)
		if ll >= 1e-9 then
			local ux, uz = dx / ll, dz / ll
			local u0 = hull[1][1] * ux + hull[1][2] * uz
			local v0 = -hull[1][1] * uz + hull[1][2] * ux
			local u1, v1 = u0, v0
			for _, p in hull do
				local u = p[1] * ux + p[2] * uz
				local v = -p[1] * uz + p[2] * ux
				u0, u1, v0, v1 = math.min(u0, u), math.max(u1, u), math.min(v0, v), math.max(v1, v)
			end
			local ar = (u1 - u0) * (v1 - v0)
			if best == nil or ar < best[1] then
				best = { ar, ux, uz, u0, u1, v0, v1 }
			end
		end
	end
	local _, ux, uz, u0, u1, v0, v1 = table.unpack(best)
	local um, vm = (u0 + u1) / 2, (v0 + v1) / 2
	local cx, cz = ux * um - uz * vm, uz * um + ux * vm
	if u1 - u0 >= v1 - v0 then
		return { cx, cz, ux, uz, (u1 - u0) / 2, (v1 - v0) / 2 }
	end
	return { cx, cz, -uz, ux, (v1 - v0) / 2, (u1 - u0) / 2 }
end

local CORNERS = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
local function roofSlabs(ring, fr, CELLM: number, pause: (() -> ())?)
	local inset = 0.75
	local cx, cz, e1x, e1z = fr[1], fr[2], fr[3], fr[4]
	local hl, hw = fr[5] - inset, fr[6] - inset
	local e2x, e2z = -e1z, e1x
	local yw = math.atan2(-e1z, e1x)
	if hl < 0.25 or hw < 0.25 then
		return {}
	end
	-- (19 Nov) neighbouring cells share corners: each corner test is kept by its exact (u, v), so the result is the same
	-- as kit_layout.py's and a big compound roof costs ~4x less (P7 tile 135_159: one building took 190 ms)
	local memo = {}
	local function ok(uu, v, hu, hv)
		for _, c in CORNERS do
			local U, V = uu + c[1] * hu, v + c[2] * hv
			local row = memo[U]
			if not row then
				row = {}
				memo[U] = row
			end
			local r = row[V]
			if r == nil then
				r = inner(ring, cx + e1x * U + e2x * V, cz + e1z * U + e2z * V, 0.6)
				row[V] = r
			end
			if not r then
				return false
			end
		end
		return true
	end
	if ok(0.0, 0.0, hl, hw) then
		return { { cx, cz, 2 * hl, 2 * hw, yw } }
	end
	local nu, nv = math.max(1, math.ceil(2 * hl / CELLM)), math.max(1, math.ceil(2 * hw / CELLM))
	local du, dv = 2 * hl / nu, 2 * hw / nv
	local res, open = {}, {}
	for j = 0, nv do
		if pause then
			pause()
		end
		local runs = {}
		if j < nv then
			local v = -hw + (j + 0.5) * dv
			local start
			for i = 0, nu do
				local inside = i < nu and ok(-hl + (i + 0.5) * du, v, du / 2, dv / 2)
				if inside and start == nil then
					start = i
				elseif not inside and start ~= nil then
					table.insert(runs, { start, i })
					start = nil
				end
			end
		end
		local nxt = {}
		for _, rr in runs do
			local j0 = j
			for _, o in open do
				if o[1][1] == rr[1] and o[1][2] == rr[2] then
					j0 = o[2]
					o[2] = -1
					break
				end
			end
			table.insert(nxt, { rr, j0 })
		end
		for _, o in open do
			local j0 = o[2]
			if j0 >= 0 then
				local i0, i1 = o[1][1], o[1][2]
				local uu = -hl + (i0 + i1) / 2 * du
				local v = -hw + (j0 + j) / 2 * dv
				table.insert(res, { cx + e1x * uu + e2x * v, cz + e1z * uu + e2z * v, (i1 - i0) * du, (j - j0) * dv, yw })
			end
		end
		open = nxt
	end
	return res
end

local function wallLayout(a, b, BAYW: number)
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local L = math.sqrt(dx * dx + dz * dz)
	local n = math.max(1, math.floor(L / BAYW + 0.5))
	local ks = {}
	for _ = 1, n // 8 do
		table.insert(ks, 8)
	end
	for _ = 1, (n % 8) // 4 do
		table.insert(ks, 4)
	end
	for _ = 1, (n % 4) // 2 do
		table.insert(ks, 2)
	end
	for _ = 1, n % 2 do
		table.insert(ks, 1)
	end
	return L, dx / L, dz / L, L / (n * BAYW), ks
end

-- a compact tile string -> the old fixed-width string (and the number of records it could not write)
-- pause (optional): called before each record; Job:step passes one that yields its coroutine past the frame's deadline
function KD.expand(s: string, i: number, j: number, meta, pause: (() -> ())?): (string, number)
	local x0, z0 = i * meta.tile, j * meta.tile
	local S, FH, STRETCH = meta.S, meta.FH, meta.STRETCH
	local BAYW, WH, WT, CELLM = 3.5 * S, 2.1 * S, 0.22 * S, 1.0 * S
	local pidIndex, codeIndex = meta.pidIndex, meta.codeIndex
	local out = {}
	local bad = 0
	local function P(pid, x, y, z, yaw, sx, code, sy, sz)
		local pi, ci = pidIndex[pid], codeIndex[code]
		if not pi or not ci then
			bad += 1
			return
		end
		local r = (if sy then "Q" else "P") .. enc(pi, 2) .. enc((x - x0 + 16384) * 500, 4) .. enc((y + 200) * 200, 3)
			.. enc((z - z0 + 16384) * 500, 4) .. yawEnc(yaw) .. enc((sx - 0.1) * 50000, 3) .. string.sub(B64, ci + 1, ci + 1)
		if sy then
			r ..= enc((sy - 0.05) * 5000, 3) .. enc((sz - 0.05) * 5000, 3)
		end
		table.insert(out, r)
	end
	local function B(x, y, z, sx, sy, sz, yaw, code)
		local ci = codeIndex[code]
		if not ci then
			bad += 1
			return
		end
		table.insert(out, "B" .. enc((x - x0 + 16384) * 500, 4) .. enc((y + 200) * 200, 3) .. enc((z - z0 + 16384) * 500, 4)
			.. yawEnc(yaw) .. enc(sx * 200, 3) .. enc(sy * 200, 3) .. enc(sz * 200, 3) .. string.sub(B64, ci + 1, ci + 1))
	end
	local function wallBox(p, q, y0, y1, code, k)
		local dx, dz = q[1] - p[1], q[2] - p[2]
		local L = math.sqrt(dx * dx + dz * dz)
		local ux, uz = dx / L, dz / L
		local nx, nz = uz, -ux
		local cx, cz = (p[1] + q[1]) / 2 - nx * 0.01, (p[2] + q[2]) / 2 - nz * 0.01
		y1 -= 0.06 * k
		B(cx, (y0 + y1) / 2, cz, L, y1 - y0, 0.02, math.atan2(-uz, ux), code)
	end

	local function building(arch, floors, wall, flags, base, ring, edges, seed)
		local baseArch = if arch == "market" then "shed" else arch
		local A = meta.arch[baseArch]
		local bay = A.bay * S
		local Hs = (A.gf + A.fh * math.max(0, floors - 1)) * S
		local par = A.par * S
		local top = base + Hs + (if par > 0 then par else 0)
		local N = #ring
		local fronts = {}
		local isCondo = arch == "condo"
		local function stack(role, kk, var, shop, stripe, ox, oz, yaw, sx)
			if isCondo then
				local vv, st = var, stripe
				if kk == 0 then
					vv, st = 0, false
				end
				P(panelPid("condo", role, 2, kk, vv, false, st), ox, base, oz, yaw, sx, wall)
				local y = base + (meta.arch.condo.gf + FH) * S
				local left = floors - 2
				for _, nf in { 8, 4, 2, 1 } do
					while left >= nf do
						P(panelPid("condo_band", role, nf, kk, vv, false, st), ox, y, oz, yaw, sx, wall)
						y += nf * FH * S
						left -= nf
					end
				end
				P(panelPid("condo_top", role, 0, kk, vv, false, st), ox, y, oz, yaw, sx, wall)
			elseif kk == 0 then
				P(panelPid(arch, role, floors, 0, 0, false, false), ox, base, oz, yaw, sx, wall)
			else
				P(panelPid(arch, role, floors, kk, var, shop, stripe), ox, base, oz, yaw, sx, wall)
			end
		end
		local shopArch = arch == "walkup" or arch == "township" or arch == "colonial"
		for ei = 0, N - 1 do
			local a, b = ring[ei + 1], ring[(ei + 1) % N + 1]
			local dx, dz = b[1] - a[1], b[2] - a[2]
			local L = math.sqrt(dx * dx + dz * dz)
			if L >= 0.3 then
				local nx, nz = dz / L, -dx / L
				local e = edges[ei + 1]
				local party, front, shop = bit32.band(e, 1) ~= 0, bit32.band(e, 2) ~= 0, bit32.band(e, 4) ~= 0
				local fit = if party or L < 0.85 * bay then nil else fitWall(L, bay, STRETCH)
				if fit == nil then
					wallBox(a, b, base - 1.0, top, wall, if N % 2 == 1 and ei == N - 1 then 2 else ei % 2)
				else
					local n, s, ps = fit[2], fit[3], fit[4]
					local role = if front then "front" else "side"
					local ax, az = nz, -nx
					local yaw = math.atan2(nx, nz)
					if front then
						table.insert(fronts, { L, b, ax, az, yaw, s, n })
					end
					local u = 0.0
					local var = if front and shopArch then bit32.band(mix(bit32.bxor(seed, ei + 1000)), 1) else 0
					local stripeDone = false
					local pieces = {}
					local left = n
					for _, k in K_SET do
						while left >= k do
							table.insert(pieces, k)
							left -= k
						end
					end
					if ps > 0 then
						table.insert(pieces, 0)
					end
					for _, kk in pieces do
						local stripe = false
						if isCondo and front and not stripeDone and kk == 1 then
							stripe, stripeDone = true, true
						end
						local sx = if kk == 0 then ps else s
						stack(role, kk, var, shop, stripe, b[1] + ax * u, b[2] + az * u, yaw, sx)
						u += if kk == 0 then (0.5 * bay * ps) else kk * bay * s
					end
				end
			end
		end
		-- one drainpipe and one or two AC units a building, on its longest street face
		if #fronts > 0 and (arch == "walkup" or arch == "township" or arch == "house" or arch == "villa") and floors >= 2 then
			local e = fronts[1]
			for k = 2, #fronts do
				if fronts[k][1] > e[1] then
					e = fronts[k]
				end
			end
			local L, b, ax, az, yaw, s, n = e[1], e[2], e[3], e[4], e[5], e[6], e[7]
			local gf = A.gf
			if arch == "walkup" or arch == "township" then
				local u = L - 0.07 * S
				local y0, y1 = base + (gf - 0.3) * S, top - 0.1 * S
				P(propPid("pipe"), b[1] + ax * u, y0, b[2] + az * u, yaw, 1.0, wall, (y1 - y0) / (3.0 * S), 1.0)
			end
			local nAc = if arch == "walkup" and floors >= 4 then 2 else 1
			local spots = {}
			for bb = 0, n - 1 do
				for f = 1, floors - 1 do
					if (bb * bay + 0.16 * S) * s + 0.8 * S < L - 0.15 * S then
						table.insert(spots, { bb, f })
					end
				end
			end
			for k = #spots - 1, 1, -1 do
				local m = math.floor(rnd(seed, 50 + k) * (k + 1))
				spots[k + 1], spots[m + 1] = spots[m + 1], spots[k + 1]
			end
			for k = 1, math.min(nAc, #spots) do
				local bb, f = spots[k][1], spots[k][2]
				local u = (bb * bay + 0.16 * S) * s
				P(propPid("ac"), b[1] + ax * u, base + (gf + FH * (f - 1) + 0.17) * S, b[2] + az * u, yaw, 1.0, wall)
			end
		end
		if bit32.band(flags, 1) ~= 0 then
			return
		end
		local topY = base + Hs
		local fr = frame(ring)
		if not fr then
			return
		end
		local slabs = roofSlabs(ring, fr, CELLM, pause)
		for _, q in slabs do
			B(q[1], topY + 0.15 - 0.4, q[2], q[3], 0.8, q[4], q[5], "KCO")
		end
		-- roof props on flat roofs: tanks, a dish, a stair room (2.5 m inside the outline)
		local pa = arch == "walkup" or arch == "township" or arch == "civic" or arch == "condo" or arch == "colonial"
		if pa and area(ring) > (5 * S) * (5 * S) and bit32.band(flags, 2) == 0 then
			local cx, cz, e1x, e1z = fr[1], fr[2], fr[3], fr[4]
			local rp
			if inner(ring, cx, cz, 2.5 * S) then
				rp = { cx, cz }
			elseif #slabs > 0 then
				local big = slabs[1]
				for k = 2, #slabs do
					if slabs[k][3] * slabs[k][4] > big[3] * big[4] then
						big = slabs[k]
					end
				end
				if inner(ring, big[1], big[2], 2.5 * S) then
					rp = { big[1], big[2] }
				end
			end
			if rp then
				local wd = arch == "walkup" or arch == "condo"
				for _, it in { { "tanks", 0.0, 0.0 }, { "dish", 4 * S, 1 * S }, { "stair", -(4 * S), 2 * S } } do
					local name = it[1]
					local skip = (name == "dish" and (not wd or rnd(seed, 300) < 0.4))
						or (name == "stair" and not (wd or arch == "civic"))
					if not skip then
						local px = rp[1] + it[2] * e1x - it[3] * e1z
						local pz = rp[2] + it[2] * e1z + it[3] * e1x
						if inner(ring, px, pz, 2.5 * S) then
							P(propPid(name), px, topY + 0.15, pz, -math.atan2(e1z, e1x), 1.0, wall)
						end
					end
				end
			end
		end
	end

	local p = if string.byte(s, 1) == 33 then 2 else 1
	local n = #s
	while p <= n do
		if pause then
			pause()
		end
		local t = string.byte(s, p)
		if t == 72 then -- "H"
			local arch = ARCHS[VAL[string.byte(s, p + 1)] + 1]
			local floors = VAL[string.byte(s, p + 2)]
			local wall = meta.walls[VAL[string.byte(s, p + 3)] + 1]
			local flags = VAL[string.byte(s, p + 4)]
			local base = num(s, p + 5, 3) / 200 - 200
			local N = num(s, p + 8, 2)
			local X, Z = num(s, p + 10, 3), num(s, p + 13, 3)
			local seed = mix(bit32.bxor(X, mix(Z + 7919)))
			local ring = { { x0 + (X - QO) / 10, z0 + (Z - QO) / 10 } }
			p += 16
			for _ = 2, N do
				X += num(s, p, 2) - 2048
				Z += num(s, p + 2, 2) - 2048
				table.insert(ring, { x0 + (X - QO) / 10, z0 + (Z - QO) / 10 })
				p += 4
			end
			local edges = {}
			for _ = 1, (N + 1) // 2 do
				local v = VAL[string.byte(s, p)]
				table.insert(edges, v % 8)
				table.insert(edges, v // 8)
				p += 1
			end
			building(arch, floors, wall, flags, base, ring, edges, seed)
		elseif t == 87 then -- "W"
			local X, Z = num(s, p + 1, 3), num(s, p + 4, 3)
			local nseg = VAL[string.byte(s, p + 7)]
			p += 8
			for _ = 1, nseg do
				local X2, Z2 = X + num(s, p, 2) - 2048, Z + num(s, p + 2, 2) - 2048
				local inf = VAL[string.byte(s, p + 4)]
				local P0 = { x0 + (X - QO) / 10, z0 + (Z - QO) / 10 }
				local P1 = { x0 + (X2 - QO) / 10, z0 + (Z2 - QO) / 10 }
				local a, b = P0, P1
				if bit32.band(inf, 4) ~= 0 then
					a, b = P1, P0
				end
				local L, ux, uz, sw, ks = wallLayout(a, b, BAYW)
				local hq = { num(s, p + 5, 3) }
				p += 8
				for k = 2, #ks do
					if bit32.band(inf, 8) ~= 0 then
						hq[k] = num(s, p, 3)
						p += 3
					else
						hq[k] = hq[k - 1] + 20 * (VAL[string.byte(s, p)] - 32)
						p += 1
					end
				end
				local col = meta.wcols[inf % 4 + 1]
				local yaw = math.atan2(-uz, ux)
				local u = 0.0
				local lo, hi = math.huge, -math.huge
				for k, kk in ks do
					local gy = hq[k] / 200 - 200
					lo, hi = math.min(lo, gy), math.max(hi, gy)
					P(propPid("cwall" .. kk), a[1] + ux * u, gy, a[2] + uz * u, yaw, sw, col)
					u += kk * BAYW * sw
				end
				local y0, y1 = lo - 0.9, hi + WH
				B((a[1] + b[1]) / 2, (y0 + y1) / 2, (a[2] + b[2]) / 2, L, y1 - y0, WT, yaw, "WCOL")
				X, Z = X2, Z2
			end
		else
			local L = LEN[t]
			if not L then
				bad += 1
				break
			end
			table.insert(out, string.sub(s, p, p + L - 1))
			p += L
		end
	end
	return table.concat(out), bad
end

local WIRE_COLOR = ColorSequence.new(Color3.fromRGB(22, 22, 24))
local WIRE_T = NumberSequence.new(0)

-- a sagging black cable (old YangonDetails' Beam look): attachments on the tile's invisible anchor part
local function wire(anchor: BasePart, a: Vector3, b: Vector3, sag: number, width: number)
	local att0 = Instance.new("Attachment")
	att0.Parent = anchor -- (parent first: WorldCFrame on an unparented attachment is taken as local)
	att0.WorldCFrame = CFrame.fromMatrix(a, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
	local att1 = Instance.new("Attachment")
	att1.Parent = anchor -- (parent first: WorldCFrame on an unparented attachment is taken as local)
	att1.WorldCFrame = CFrame.fromMatrix(b, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = width
	beam.Width1 = width
	beam.Color = WIRE_COLOR
	beam.Transparency = WIRE_T
	beam.LightInfluence = 1
	beam.FaceCamera = true
	beam.Segments = 10
	beam.CurveSize0 = sag
	beam.CurveSize1 = -sag
	beam.Texture = ""
	beam.Parent = anchor
end
KD.wire = wire

local function visual(q: BasePart)
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.CastShadow = true
end

-- a resumable build of one tile's string into `parent`
local Job = {}
Job.__index = Job

function KD.job(s: string, i: number, j: number, meta, T, parent: Instance)
	return setmetatable({ s = s, pos = 1, x0 = i * meta.tile, z0 = j * meta.tile, meta = meta, T = T, parent = parent,
		parts = 0, missing = 0, batch = {} }, Job)
end

-- builds up to `budget` parts; true when the tile is done. `untilClock` (os.clock(), optional): a compact tile's layout
-- stops there and goes on at the next step (2026-11-19: one dense P7 / P4 tile's expand was up to 164 ms in one frame)
function Job:step(budget: number, untilClock: number?): boolean
	if string.byte(self.s, 1) == 33 then -- "!": compact (FORMAT=2): lay it out first
		if not untilClock then
			local bad
			self.s, bad = KD.expand(self.s, self.x0 / self.meta.tile, self.z0 / self.meta.tile, self.meta)
			self.missing += bad
		else
			self.until_ = untilClock
			if not self.co then
				local src = self.s
				self.co = coroutine.create(function()
					return KD.expand(src, self.x0 / self.meta.tile, self.z0 / self.meta.tile, self.meta, function()
						if os.clock() > self.until_ then
							coroutine.yield()
						end
					end)
				end)
			end
			local ok, s, bad = coroutine.resume(self.co)
			if not ok then
				self.co = nil
				error(s)
			end
			if coroutine.status(self.co) ~= "dead" then
				return false
			end
			self.co = nil
			self.s = s
			self.missing += bad
		end
	end
	local s, x0, z0, meta, T = self.s, self.x0, self.z0, self.meta, self.T
	local n = #s
	local made = 0
	local batch = self.batch
	while self.pos <= n and made < budget do
		local p = self.pos
		local t = string.byte(s, p)
		local L = LEN[t]
		if not L then
			self.pos = n + 1
			break
		end
		if t == 76 or t == 75 then -- "L" / "K": cables
			if not self.anchor then
				local a = Instance.new("Part")
				a.Name = "Wires"
				a.Anchored = true
				a.CanCollide = false
				a.CanQuery = false
				a.CanTouch = false
				a.Transparency = 1
				a.Size = Vector3.new(1, 1, 1)
				a.CFrame = CFrame.new(x0, 0, z0)
				a.Parent = self.parent
				self.anchor = a
			end
			local x1 = num(s, p + 1, 4) / 500 - 16384 + x0
			local y1 = num(s, p + 5, 3) / 200 - 200
			local z1 = num(s, p + 8, 4) / 500 - 16384 + z0
			if t == 76 then
				local a1 = num(s, p + 12, 3) / 262144 * TWO_PI
				local x2 = num(s, p + 15, 4) / 500 - 16384 + x0
				local y2 = num(s, p + 19, 3) / 200 - 200
				local z2 = num(s, p + 22, 4) / 500 - 16384 + z0
				local a2 = num(s, p + 26, 3) / 262144 * TWO_PI
				local n = VAL[string.byte(s, p + 29)]
				local seed = VAL[string.byte(s, p + 30)]
				local cf1 = CFrame.new(x1, y1, z1) * CFrame.Angles(0, a1, 0)
				local cf2 = CFrame.new(x2, y2, z2) * CFrame.Angles(0, a2, 0)
				local dist = (Vector3.new(x2, y2, z2) - Vector3.new(x1, y1, z1)).Magnitude
				local att = meta.attach
				local m = math.min(n, #att)
				for k = 1, m do
					local o = att[k]
					local sag = dist * (0.022 + 0.004 * ((seed + k * 7) % 5)) + 0.15 * ((seed + k) % 3)
					wire(self.anchor, (cf1 * CFrame.new(o)).Position, (cf2 * CFrame.new(o)).Position, sag, if k <= 4 then 0.09 else 0.12)
				end
				made += m
			else
				local x2 = num(s, p + 12, 4) / 500 - 16384 + x0
				local y2 = num(s, p + 16, 3) / 200 - 200
				local z2 = num(s, p + 19, 4) / 500 - 16384 + z0
				local sag = num(s, p + 23, 2) / 100
				wire(self.anchor, Vector3.new(x1, y1, z1), Vector3.new(x2, y2, z2), sag, 0.08)
				made += 1
			end
		elseif t == 84 then -- "T": a name plate
			local x = num(s, p + 1, 4) / 500 - 16384 + x0
			local y = num(s, p + 5, 3) / 200 - 200
			local z = num(s, p + 8, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 12, 3) / 262144 * TWO_PI
			local w, h = num(s, p + 15, 2) / 50, num(s, p + 17, 2) / 50
			local a = VAL[string.byte(s, p + 19)] + 1
			local cell = num(s, p + 20, 2)
			local img = meta.atlas[a]
			if img and img ~= "-" then
				local q = Instance.new("Part")
				q.Name = "Plate"
				q.Size = Vector3.new(w, h, 0.05)
				q.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
				q.Transparency = 1
				visual(q)
				q.CastShadow = false
				local cw, ch, cols = meta.cell[1], meta.cell[2], meta.cell[3]
				local g = Instance.new("SurfaceGui")
				g.Face = Enum.NormalId.Front
				g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
				g.CanvasSize = Vector2.new(cw, ch)
				g.LightInfluence = 1
				g.MaxDistance = 260
				local im = Instance.new("ImageLabel")
				im.BackgroundTransparency = 1
				im.Size = UDim2.fromScale(1, 1)
				im.Image = img
				im.ImageRectOffset = Vector2.new((cell % cols) * cw, math.floor(cell / cols) * ch)
				im.ImageRectSize = Vector2.new(cw, ch)
				im.Parent = g
				g.Parent = q
				table.insert(batch, q)
				made += 1
			end
		elseif t == 66 then -- "B"
			local x = num(s, p + 1, 4) / 500 - 16384 + x0
			local y = num(s, p + 5, 3) / 200 - 200
			local z = num(s, p + 8, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 12, 3) / 262144 * TWO_PI
			local sx, sy, sz = num(s, p + 15, 3) / 200, num(s, p + 18, 3) / 200, num(s, p + 21, 3) / 200
			local code = meta.codes[VAL[string.byte(s, p + 24)] + 1]
			local q = Instance.new("Part")
			q.Size = Vector3.new(sx, sy, sz)
			q.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
			q.Name = code
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			if code == "WCOL" then
				-- compound-wall collision (client-side: the local character and car are simulated here)
				q.Anchored = true
				q.Transparency = 1
				q.CanCollide = true
				q.CanQuery = true
				q.CanTouch = false
				q.CastShadow = false
			else
				visual(q)
				KD.look(q, code, KD.WALL[code])
				if hasVariant(KD.SIDE[code]) then
					q.MaterialVariant = KD.SIDE[code]
				end
			end
			table.insert(batch, q)
			made += 1
		else
			local pid = meta.pids[num(s, p + 1, 2) + 1]
			local x = num(s, p + 3, 4) / 500 - 16384 + x0
			local y = num(s, p + 7, 3) / 200 - 200
			local z = num(s, p + 10, 4) / 500 - 16384 + z0
			local yaw = num(s, p + 14, 3) / 262144 * TWO_PI
			local sx = num(s, p + 17, 3) / 50000 + 0.1
			local code = meta.codes[VAL[string.byte(s, p + 20)] + 1]
			local sy, sz = 1, 1
			if t == 81 then -- "Q"
				sy = num(s, p + 21, 3) / 5000 + 0.05
				sz = num(s, p + 24, 3) / 5000 + 0.05
			end
			local pieces = T[pid]
			if not pieces then
				self.missing += 1
			else
				local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
				for _, tp in pieces do
					local q = tp.part:Clone()
					q.Size = Vector3.new(tp.size.X * sx, tp.size.Y * sy, tp.size.Z * sz)
					q.CFrame = cf * CFrame.new(tp.c.X * sx, tp.c.Y * sy, tp.c.Z * sz) * (tp.r or CFrame.identity)
					if tp.kind == "KWX" then
						q.Name = code
						KD.look(q, code, KD.WALL[code])
						local mv = tp.part:GetAttribute("MV")
						if KD.VARIANT[code] ~= "YgnRenderStained" and hasVariant(mv) then
							q.MaterialVariant = mv -- (newer / villa-type panels: the clean painted render)
						end
					end
					table.insert(batch, q)
					made += 1
				end
			end
		end
		self.pos = p + L
	end
	for _, q in batch do
		q.Parent = self.parent
	end
	self.parts += #batch
	table.clear(batch)
	return self.pos > n
end

return KD
