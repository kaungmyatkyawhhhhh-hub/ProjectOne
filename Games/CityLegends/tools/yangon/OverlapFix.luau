--[[
	OverlapFix (Studio, Edit; 2026-11-26): fixes the overlaps tools/yangon/OverlapCheck.luau finds, by editing the kit
	data strings and the shells in place. Every changed tile string is first copied to
	ServerStorage.OverlapFixBackup.<Data folder>.<tile>, every removed shell / roof is moved to
	ServerStorage.OverlapFixBackup.Shells (undo = put them back), and every action is logged in F.LOG (and _G.OVLFIX_LOG).

	local F = require(ServerStorage.ClaudeTools.OverlapFix:Clone())
	F.dropDetail(rows)                    -- tree / street-prop records whose parts really go into a placed thing: removed
	F.shiftRecords(folder, key, first, last, dx, dz, expect) -- moves records first..last of a tile by (dx, dz)
	F.deleteBuilding(shellPart, reason)   -- the building that shell belongs to: its shells + roofs (to the backup) and
	                                      -- its kit records in Data_<district> (dropped); returns its XZ boxes (for the night
	                                      -- panes, see NightCut)
	Record format: shared/YangonKitData.lua (fixed width P / Q / B / L / K / T). Compact "!" tiles are left alone (logged).
]]

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local F = {}
F.DRY = false -- true: only log what would change
F.LOG = {}
_G.OVLFIX_LOG = F.LOG

local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end
local LEN = { [80] = 21, [81] = 27, [66] = 25, [76] = 31, [75] = 25, [84] = 22 } -- P Q B L K T
local XAT = { [80] = 3, [81] = 3, [66] = 1, [76] = 1, [75] = 1, [84] = 1 } -- offset of x(4) y(3) z(4)

local function num(s: string, a: number, n: number): number
	local v = 0
	for k = a, a + n - 1 do
		v = v * 64 + VAL[string.byte(s, k)]
	end
	return v
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

local lastYield = os.clock()
local function breathe() -- (long loops yield so Studio and the MCP stay alive)
	if os.clock() - lastYield > 0.05 then
		task.wait()
		lastYield = os.clock()
	end
end

local function log(s: string)
	table.insert(F.LOG, s)
	print("[OverlapFix] " .. s)
end

-- the records of a tile string: { t, a (start), L, s (text), x, y, z }; nil for a compact tile
function F.records(s: string, i: number, j: number, tile: number)
	if string.sub(s, 1, 1) == "!" then
		return nil
	end
	local x0, z0 = i * tile, j * tile
	local out = {}
	local p = 1
	while p <= #s do
		local t = string.byte(s, p)
		local L = LEN[t]
		if not L then
			return nil
		end
		local o = p + XAT[t]
		table.insert(out, {
			t = t,
			a = p,
			L = L,
			s = string.sub(s, p, p + L - 1),
			x = num(s, o, 4) / 500 - 16384 + x0,
			y = num(s, o + 4, 3) / 200 - 200,
			z = num(s, o + 7, 4) / 500 - 16384 + z0,
		})
		p += L
	end
	return out
end

local function backup(folder: Instance, v: StringValue)
	local root = SS:FindFirstChild("OverlapFixBackup")
	if not root then
		root = Instance.new("Folder")
		root.Name = "OverlapFixBackup"
		root.Parent = SS
	end
	local f = root:FindFirstChild(folder.Name)
	if not f then
		f = Instance.new("Folder")
		f.Name = folder.Name
		f.Parent = root
	end
	if not f:FindFirstChild(v.Name) then
		local c = v:Clone()
		c.Parent = f
	end
end

local function tileOf(v: StringValue): (number, number)
	local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
	return tonumber(i) :: number, tonumber(j) :: number
end

-- build one record alone (its parts), in a holder outside the DataModel
local KD, T
local function kd()
	if not KD then
		KD = require(RS.Shared.YangonKitData:Clone())
		T = KD.index(RS.YgnKit.Templates)
	end
	return KD, T
end

-- rewrite a tile without the records whose index is in drop
function F.drop(folder: Instance, v: StringValue, drop: { [number]: boolean }, why: string)
	local recs = F.recordsOf(folder, v)
	if not recs then
		log("SKIP unreadable tile " .. folder.Name .. "." .. v.Name)
		return 0
	end
	local keep, n = {}, 0
	for k, r in recs do
		if drop[k] then
			n += 1
			log(string.format("drop %s.%s #%d %s at (%.1f, %.1f, %.1f): %s", folder.Name, v.Name, k, string.char(r.t), r.x, r.y, r.z, why))
		else
			table.insert(keep, r.s)
		end
	end
	if n > 0 and not F.DRY then
		backup(folder, v)
		v.Value = table.concat(keep)
	end
	return n
end

-- move records first..last of a tile by (dx, dz); expect = { [index] = code letter } sanity checks
function F.shiftRecords(folder: Instance, key: string, first: number, last: number, dx: number, dz: number, expectCount: number?)
	local v = folder:FindFirstChild(key) :: StringValue
	local meta = require(RS.Shared.YangonKitData:Clone()).meta(folder)
	local i, j = tileOf(v)
	local recs = F.records(v.Value, i, j, meta.tile)
	assert(recs, "compact tile")
	if expectCount then
		assert(#recs == expectCount, "record count " .. #recs .. " ~= " .. expectCount)
	end
	backup(folder, v)
	local x0, z0 = i * meta.tile, j * meta.tile
	local out = {}
	for k, r in recs do
		if k >= first and k <= last then
			local o = XAT[r.t] + 1 -- (x starts at this index inside the record; 26 Nov: an off-by-one here cut the type letter
			-- and the streamer stopped reading the tile at that record)
			local s = r.s
			local xs = enc((r.x + dx - x0 + 16384) * 500, 4)
			local zs = enc((r.z + dz - z0 + 16384) * 500, 4)
			s = string.sub(s, 1, o - 1) .. xs .. string.sub(s, o + 4, o + 6) .. zs .. string.sub(s, o + 11)
			assert(string.sub(s, 1, 1) == string.sub(r.s, 1, 1))
			assert(#s == r.L)
			table.insert(out, s)
		else
			table.insert(out, r.s)
		end
	end
	v.Value = table.concat(out)
	log(string.format("shift %s.%s records %d..%d by (%.2f, %.2f)", folder.Name, key, first, last, dx, dz))
end

-- the records of a tile; a compact ("!") tile is laid out first by YangonKitData.expand (the old record format, which
-- the streamer reads too), so its buildings and walls can be edited record by record
function F.recordsOf(folder: Instance, v: StringValue)
	local K = kd()
	local meta = K.meta(folder)
	local i, j = tileOf(v)
	local s = v.Value
	if string.sub(s, 1, 1) == "!" then
		s = K.expand(s, i, j, meta)
	end
	return F.records(s, i, j, meta.tile)
end

function F.buildRecord(folder: Instance, v: StringValue, r, holder: Instance)
	local K, TT = kd()
	local meta = K.meta(folder)
	local i, j = tileOf(v)
	local job = K.job(r.s, i, j, meta, TT, holder)
	while not job:step(500) do
	end
	return holder:GetChildren()
end

-- tree / street-prop records (Data_<tag>G / Data_<tag>S) whose own parts really go into a placed thing of the rows
function F.dropDetail(rows, exact)
	exact = exact or _G.OVLmod.exact
	local byTile = {}
	for _, r in rows do
		if r.bkind == "tree" or r.bkind == "street" then
			local fname, key = string.match(r.b, "^%a+:([^:]+):(.+)$")
			local k = fname .. "|" .. key
			byTile[k] = byTile[k] or { fname = fname, key = key, a = {} }
			byTile[k].a[r.apart] = true
		end
	end
	local total = 0
	for _, e in byTile do
		local folder = RS.YgnKit:FindFirstChild(e.fname)
		local v = folder and folder:FindFirstChild(e.key)
		if v then
			local recs = F.recordsOf(folder, v)
			if recs then
				local drop = {}
				local reasons = {}
				for k, r in recs do
					local holder = Instance.new("Folder")
					local parts = F.buildRecord(folder, v, r, holder)
					for _, q in parts do
						if q:IsA("BasePart") then
							for ap in e.a do
								if (ap.Position - q.Position).Magnitude < (ap.Size.Magnitude + q.Size.Magnitude) / 2
									and _G.OVLmod.depth(ap.CFrame, ap.Size, q.CFrame, q.Size) > _G.OVLmod.TOL
									and exact({ apart = ap, bpart = q }) then
									drop[k] = true
									reasons[k] = ap.Name
									break
								end
							end
						end
						if drop[k] then
							break
						end
					end
					holder:Destroy()
					breathe()
				end
				local why = {}
				for _, w in reasons do
					why[w] = true
				end
				local ws = {}
				for w in why do
					table.insert(ws, w)
				end
				total += F.drop(folder, v, drop, "into " .. table.concat(ws, "/"))
			else
				log("SKIP compact " .. e.fname .. "." .. e.key)
			end
			task.wait()
		end
	end
	log("dropDetail: " .. total .. " records")
	return total
end

-- XZ test: point inside an oriented box grown by g
local function inBoxXZ(cf: CFrame, size: Vector3, p: Vector3, g: number): boolean
	local l = cf:PointToObjectSpace(Vector3.new(p.X, cf.Position.Y, p.Z))
	return math.abs(l.X) <= size.X / 2 + g and math.abs(l.Z) <= size.Z / 2 + g
end

-- the building a shell part belongs to: every shell / roof part in the same Shell cell whose middle is inside this
-- shell's footprint (grown 1 stud), then their kit records in Data_<district> (records whose built parts all stand
-- inside the footprints grown 1.5 studs)
function F.deleteBuilding(shell: BasePart, reason: string)
	local cell = shell.Parent
	if not cell or not cell.Parent or cell.Parent.Name ~= "Shell" then
		return nil, nil, 0 -- (already taken with another shell of the same building)
	end
	local boxes = { { cf = shell.CFrame, size = shell.Size } }
	local parts = {}
	for _, q in cell:GetDescendants() do
		if q:IsA("BasePart") and inBoxXZ(shell.CFrame, shell.Size, q.Position, 1) then
			table.insert(parts, q)
			if q ~= shell and q:IsA("Part") then
				table.insert(boxes, { cf = q.CFrame, size = q.Size })
			end
		end
	end
	local c = Vector3.zero
	for _, q in parts do
		c += q.Position
	end
	c /= #parts
	local tag = string.format("%s_%d_%d", cell.Name, math.round(c.X), math.round(c.Z))
	if not F.DRY then
		local root = SS:FindFirstChild("OverlapFixBackup") or Instance.new("Folder")
		root.Name = "OverlapFixBackup"
		root.Parent = SS
		local sh = root:FindFirstChild("Shells") or Instance.new("Folder")
		sh.Name = "Shells"
		sh.Parent = root
		local bf = Instance.new("Folder")
		bf.Name = tag
		bf:SetAttribute("Reason", reason)
		bf:SetAttribute("From", cell:GetFullName())
		bf.Parent = sh
		for _, q in parts do
			q.Parent = bf
		end
	end
	log(string.format("delete building %s (%d shell/roof parts): %s", tag, #parts, reason))
	-- kit records
	local tkey = shell:GetAttribute("T")
	local ti, tj = string.match(tostring(tkey), "^(%-?%d+)_(%-?%d+)$")
	ti, tj = tonumber(ti), tonumber(tj)
	local nrec = 0
	for _, folder in RS.YgnKit:GetChildren() do
		if string.match(folder.Name, "^Data_P%d+$") and ti then
			for di = -1, 1 do
				for dj = -1, 1 do
					local v = folder:FindFirstChild((ti + di) .. "_" .. (tj + dj))
					if v then
						local recs = F.recordsOf(folder, v)
						if recs then
							local drop = {}
							for k, r in recs do
								local holder = Instance.new("Folder")
								local ps = F.buildRecord(folder, v, r, holder)
								local all, any = true, false
								for _, q in ps do
									if q:IsA("BasePart") then
										any = true
										local inside = false
										for _, b in boxes do
											if inBoxXZ(b.cf, b.size, q.Position, 1.5) then
												inside = true
												break
											end
										end
										if not inside then
											all = false
											break
										end
									end
								end
								holder:Destroy()
								breathe()
								if any and all then
									drop[k] = true
								end
							end
							nrec += F.drop(folder, v, drop, "building " .. tag)
						else
							log("SKIP compact " .. folder.Name .. "." .. v.Name .. " (building " .. tag .. ")")
						end
					end
				end
			end
		end
	end
	return boxes, tag, nrec
end

-- the night-window mesh of a cell without the panes inside the given XZ boxes (grown 2 studs): kept triangles as text
-- lines for tools/yangon/city/night_cut.py ("ax ay az bx by bz cx cy cz r g b", world studs); returns lines, removed
function F.nightExport(part: MeshPart, boxes)
	local AS = game:GetService("AssetService")
	local em = AS:CreateEditableMeshAsync(Content.fromUri(part.MeshId))
	local s = part.Size / part.MeshSize
	local cf = part.CFrame
	local lines, removed = {}, 0
	for _, f in em:GetFaces() do
		local vs = em:GetFaceVertices(f)
		local w = {}
		for k = 1, 3 do
			w[k] = cf * (em:GetPosition(vs[k]) * s)
		end
		local c = (w[1] + w[2] + w[3]) / 3
		breathe()
		local inside = false
		for _, b in boxes do
			if inBoxXZ(b.cf, b.size, c, 2) then
				inside = true
				break
			end
		end
		if inside then
			removed += 1
		else
			local col = Color3.new(1, 1, 1)
			pcall(function()
				local cs = em:GetFaceColors(f)
				col = em:GetColor(cs[1])
			end)
			table.insert(lines, string.format("%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %d %d", w[1].X, w[1].Y, w[1].Z,
				w[2].X, w[2].Y, w[2].Z, w[3].X, w[3].Y, w[3].Z, math.round(col.R * 255), math.round(col.G * 255), math.round(col.B * 255)))
		end
	end
	em:Destroy()
	log(string.format("night %s: %d panes kept, %d removed", part:GetFullName(), #lines, removed))
	return lines, removed
end

-- compound walls: a WCOL collision box that goes into a placed thing, with every record whose parts stand inside it
-- (the wall's visible pieces): all dropped (the wall stops at the placed thing)
function F.dropWalls(rows)
	local byTile = {}
	for _, r in rows do
		if r.bkind == "kit" and r.bname == "WCOL" then
			local fname, key = string.match(r.b, "^%a+:([^:]+):(.+)$")
			local k = fname .. "|" .. key
			byTile[k] = byTile[k] or { fname = fname, key = key, w = {} }
			table.insert(byTile[k].w, { cf = r.bcf, size = r.bsize, pos = r.bpos, a = r.a })
		end
	end
	local total = 0
	for _, e in byTile do
		local folder = RS.YgnKit:FindFirstChild(e.fname)
		local v = folder and folder:FindFirstChild(e.key)
		if v then
			local recs = F.recordsOf(folder, v)
			local drop, why = {}, {}
			for k, r in recs or {} do
				local holder = Instance.new("Folder")
				local ps = F.buildRecord(folder, v, r, holder)
				local all, any, hitW = true, false, nil
				for _, q in ps do
					if q:IsA("BasePart") then
						any = true
						local inside = false
						for _, w in e.w do
							if inBoxXZ(w.cf, w.size, q.Position, 0.6) and math.abs(q.Position.Y - w.pos.Y) <= w.size.Y / 2 + 1 then
								inside, hitW = true, w
								break
							end
						end
						if not inside then
							all = false
							break
						end
					end
				end
				holder:Destroy()
				breathe()
				if any and all then
					drop[k] = true
					why[hitW.a] = true
				end
			end
			local ws = {}
			for a in why do
				table.insert(ws, a)
			end
			total += F.drop(folder, v, drop, "compound wall into " .. table.concat(ws, "/"))
		end
	end
	log("dropWalls: " .. total)
	return total
end

-- (round 2) cut a box back from one side until it is clear of `others` (each { cf, size }) by 0.1; nil if no single side does
function F.shrinkPlan(cf: CFrame, size: Vector3, others)
	local depth = _G.OVLmod.depth
	local best
	for _, ax in { { "X", 1 }, { "X", -1 }, { "Z", 1 }, { "Z", -1 } } do
		local full = if ax[1] == "X" then size.X else size.Z
		local function at(c)
			local ns = if ax[1] == "X" then Vector3.new(size.X - c, size.Y, size.Z) else Vector3.new(size.X, size.Y, size.Z - c)
			local off = if ax[1] == "X" then Vector3.new(-ax[2] * c / 2, 0, 0) else Vector3.new(0, 0, -ax[2] * c / 2)
			return cf * CFrame.new(off), ns
		end
		local function clear(c)
			local ncf, ns = at(c)
			for _, b in others do
				if depth(ncf, ns, b.cf, b.size) > -0.1 then
					return false
				end
			end
			return true
		end
		local lo, hi = 0, full * 0.6
		if clear(hi) then
			for _ = 1, 30 do
				local m = (lo + hi) / 2
				if clear(m) then hi = m else lo = m end
			end
			if not best or hi < best.cut then
				local ncf, ns = at(hi)
				best = { cf = ncf, size = ns, cut = hi, axis = ax[1] .. (if ax[2] > 0 then "+" else "-") }
			end
		end
	end
	return best
end

-- (round 2) cut several sides of a flat pad: each item goes to the side that frees it with the smallest cut
function F.multiCut(cf: CFrame, size: Vector3, others)
	local cuts = { ["X+"] = 0, ["X-"] = 0, ["Z+"] = 0, ["Z-"] = 0 }
	for _, o in others do
		local l = cf:PointToObjectSpace(o.cf.Position)
		local rx, ry, rz = o.cf.RightVector * o.size.X / 2, o.cf.UpVector * o.size.Y / 2, o.cf.LookVector * o.size.Z / 2
		local function ext(a: Vector3)
			return math.abs(rx:Dot(a)) + math.abs(ry:Dot(a)) + math.abs(rz:Dot(a))
		end
		local ex, ey, ez = ext(cf.RightVector), ext(cf.UpVector), ext(cf.LookVector)
		local need = {
			["X+"] = size.X / 2 - (l.X - ex) + 0.1, ["X-"] = size.X / 2 - (-l.X - ex) + 0.1,
			["Z+"] = size.Z / 2 - (l.Z - ez) + 0.1, ["Z-"] = size.Z / 2 - (-l.Z - ez) + 0.1,
		}
		local clear = math.abs(l.Y) >= size.Y / 2 + ey
		for _, v in need do
			if v <= 0.1 then
				clear = true
			end
		end
		if not clear then
			local bs, bv = nil, math.huge
			for k, v in need do
				if v < bv then bs, bv = k, v end
			end
			cuts[bs] = math.max(cuts[bs], bv)
		end
	end
	local ns = Vector3.new(size.X - cuts["X+"] - cuts["X-"], size.Y, size.Z - cuts["Z+"] - cuts["Z-"])
	local off = Vector3.new((cuts["X-"] - cuts["X+"]) / 2, 0, (cuts["Z-"] - cuts["Z+"]) / 2)
	return cf * CFrame.new(off), ns, cuts
end

return F
