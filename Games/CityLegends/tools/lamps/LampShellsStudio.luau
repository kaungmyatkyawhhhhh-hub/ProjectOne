-- tools/lamps/LampShellsStudio.luau (2026-11-21): the Studio half of lampfx_studio.py. Paste the whole file into
-- execute_luau (Edit); it sets _G.LS. Steps for a car:
--   LS.scan(id, zone, partNames, minArea)       loose pieces on the left half near the ends (ax = distance from the middle)
--   LS.get(id, want) / LS.many({{id, want}...})  only the pieces a job asks for (want rows from `lampfx_studio.py want job.json`)
--   LS.pg(id, i)                                 a page of that text (99,000 chars, padded so it lands in a tool-results file)
--   python lampfx_studio.py job.json <pages>     -> imports/sync/lamp_shells/<id>.glb -> Open Cloud Model (group 33151111)
--   LS.apply(id, assetId, "all")                 backup to ServerStorage.LampBackup_21Nov once, replace the roles in the pack,
--                                                lit stage clone at (0, 5000, 0) in Workspace._LampStage; LS.unstage() after looking
local AS = game:GetService("AssetService")
local LS = {}
_G.LS = LS
local CM = game.ReplicatedStorage.CarModels

function LS.read(model, p)
	local em = AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
	local pv = model:GetPivot()
	local mn, mx = Vector3.one * math.huge, -Vector3.one * math.huge
	local raw = {}
	for _, v in em:GetVertices() do
		local q = em:GetPosition(v)
		raw[v] = q
		mn = mn:Min(q)
		mx = mx:Max(q)
	end
	local c = (mn + mx) / 2
	local ext = mx - mn
	local sc = Vector3.new(ext.X > 1e-6 and p.Size.X / ext.X or 1, ext.Y > 1e-6 and p.Size.Y / ext.Y or 1, ext.Z > 1e-6 and p.Size.Z / ext.Z or 1)
	local toModel = pv:Inverse() * p.CFrame
	local pos, key, keyOf, nk = {}, {}, {}, 0
	for v, q in raw do
		local w = toModel * ((q - c) * sc)
		pos[v] = w
		local s = string.format("%d,%d,%d", math.floor(w.X * 1000 + 0.5), math.floor(w.Y * 1000 + 0.5), math.floor(w.Z * 1000 + 0.5))
		local k = keyOf[s]
		if not k then
			nk += 1
			k = nk
			keyOf[s] = k
		end
		key[v] = k
	end
	-- loose pieces by merged positions (a piece's seams share points, not vertex ids)
	local parent = {}
	local function find(a)
		local r = a
		while parent[r] and parent[r] ~= r do
			r = parent[r]
		end
		while parent[a] and parent[a] ~= r do
			parent[a], a = r, parent[a]
		end
		return r
	end
	local faces = em:GetFaces()
	local fv = {}
	for i, f in faces do
		local t = em:GetFaceVertices(f)
		fv[i] = t
		local a = find(key[t[1]])
		parent[a] = a
		for k = 2, #t do
			local b = find(key[t[k]])
			parent[b] = a
		end
	end
	local rootOf = {}
	for i in faces do
		rootOf[i] = find(key[fv[i][1]])
	end
	return { em = em, pos = pos, faces = faces, fv = fv, rootOf = rootOf, key = key }
end

local function readTry(model, p)
	for _ = 1, 3 do
		local ok, r = pcall(LS.read, model, p)
		if ok then
			return r
		end
		task.wait(1) -- "Failed to load mesh" now and then: it loads on the next try
	end
	return nil
end

local function bounds(model)
	local cf, sz = model:GetBoundingBox()
	local zc = model:GetPivot():PointToObjectSpace(cf.Position).Z
	return zc - sz.Z / 2, zc + sz.Z / 2, sz
end

function LS.scan(id, zone, names, minArea)
	local model = CM[id]
	local zmin, zmax, sz = bounds(model)
	zone = zone or 0.25
	local lines = { id .. string.format(" z %.2f..%.2f size %.2f,%.2f,%.2f", zmin, zmax, sz.X, sz.Y, sz.Z) }
	for _, name in names do
		local p = model:FindFirstChild(name, true)
		local R = p and readTry(model, p)
		if R then
			local isl = {}
			for i in R.faces do
				local r = R.rootOf[i]
				local I = isl[r]
				if not I then
					I = { n = 0, mn = Vector3.one * math.huge, mx = -Vector3.one * math.huge, nrm = Vector3.zero, area = 0 }
					isl[r] = I
				end
				local t = R.fv[i]
				local a, b, d = R.pos[t[1]], R.pos[t[2]], R.pos[t[3]]
				I.mn = I.mn:Min(a):Min(b):Min(d)
				I.mx = I.mx:Max(a):Max(b):Max(d)
				local n = (b - a):Cross(d - a)
				I.nrm += n
				I.area += n.Magnitude / 2
				I.n += 1
			end
			local rows = {}
			for _, I in isl do
				local cz = (I.mn.Z + I.mx.Z) / 2
				if (cz < zmin + sz.Z * zone or cz > zmax - sz.Z * zone) and I.area >= (minArea or 0.0015) and I.mn.X < 0.02 then
					local n = I.nrm.Magnitude > 1e-6 and I.nrm.Unit or Vector3.zero
					table.insert(rows, { I.area, string.format(" %5d t %.4f ax %.2f..%.2f y %.2f..%.2f z %.2f..%.2f n %.1f,%.1f,%.1f", I.n, I.area, math.max(-I.mx.X, 0), -I.mn.X, I.mn.Y, I.mx.Y, I.mn.Z, I.mx.Z, n.X, n.Y, n.Z) })
				end
			end
			table.sort(rows, function(a, b)
				return a[1] > b[1]
			end)
			table.insert(lines, name .. " faces " .. #R.faces .. " pieces " .. #rows)
			for i = 1, math.min(#rows, 45) do
				table.insert(lines, rows[i][2])
			end
			R.em:Destroy()
		else
			table.insert(lines, name .. " FAILED")
		end
		task.wait()
	end
	return table.concat(lines, "\n")
end

-- the LEFT loose pieces a job asks for. want = { { part, ax0, ax1, y0, y1, z0, z1 }, ... } (no box = every left piece near the ends)
function LS.prep(id, want, zone)
	local model = CM[id]
	local zmin, zmax, sz = bounds(model)
	zone = zone or 0.3
	local byPart = {}
	for _, w in want do
		byPart[w[1]] = byPart[w[1]] or {}
		table.insert(byPart[w[1]], w)
	end
	local out = { "@G@" .. id }
	for name, boxes in byPart do
		local p = model:FindFirstChild(name, true)
		local R = p and readTry(model, p)
		if R then
			local mn, mx = {}, {}
			for i in R.faces do
				local r = R.rootOf[i]
				local t = R.fv[i]
				local a, b, d = R.pos[t[1]], R.pos[t[2]], R.pos[t[3]]
				mn[r] = (mn[r] or a):Min(a):Min(b):Min(d)
				mx[r] = (mx[r] or a):Max(a):Max(b):Max(d)
			end
			local keep = {}
			for r, lo in mn do
				local c = (lo + mx[r]) / 2
				if c.X < 0.02 then
					for _, b in boxes do
						if not b[2] then
							if c.Z < zmin + sz.Z * zone or c.Z > zmax - sz.Z * zone then
								keep[r] = true
							end
						elseif -c.X >= b[2] - 0.02 and -c.X <= b[3] and c.Y >= b[4] and c.Y <= b[5] and c.Z >= b[6] and c.Z <= b[7] then
							keep[r] = true
						end
					end
				end
			end
			local map, nv, verts, tris, n = {}, 0, {}, {}, 0
			for i in R.faces do
				if keep[R.rootOf[i]] then
					local t = R.fv[i]
					n += 1
					local idx = {}
					for k = 1, 3 do
						local key = R.key[t[k]]
						local m = map[key]
						if not m then
							local q = R.pos[t[k]]
							m = nv
							nv += 1
							map[key] = m
							table.insert(verts, string.format("%04x%04x%04x", math.floor(q.X * 1000 + 32768.5), math.floor(q.Y * 1000 + 32768.5), math.floor(q.Z * 1000 + 32768.5)))
						end
						idx[k] = m
					end
					table.insert(tris, string.format("%05x%05x%05x%05x", idx[1], idx[2], idx[3], R.rootOf[i]))
				end
			end
			table.insert(out, "P " .. name .. " " .. nv .. " " .. n)
			table.insert(out, "V " .. table.concat(verts))
			table.insert(out, "T " .. table.concat(tris))
			R.em:Destroy()
		else
			table.insert(out, "FAILED " .. name)
		end
		task.wait()
	end
	table.insert(out, "@END@")
	LS.text = table.concat(out, "\n")
	return LS.text
end

LS.saved = {}
function LS.many(list)
	local o = {}
	for _, row in list do
		local t = LS.prep(row[1], row[2])
		LS.saved[row[1]] = t
		table.insert(o, row[1] .. " " .. math.ceil(#t / 99000) .. "p " .. #t .. (t:find("FAILED") and " FAILED" or ""))
	end
	return table.concat(o, "\n")
end
function LS.get(id, want)
	return LS.many({ { id, want } })
end
function LS.pg(id, i)
	local s = LS.saved[id]:sub((i - 1) * 99000 + 1, i * 99000)
	return "@PAGE " .. i .. "@\n" .. s .. string.rep("#", 95000 - #s)
end

function LS.stage(id)
	LS.unstage()
	local st = Instance.new("Folder")
	st.Name = "_LampStage"
	st.Parent = workspace
	local m = CM[id]:Clone()
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	m:PivotTo(CFrame.new(0, 5000, 0))
	m.Parent = st
	return m
end
function LS.unstage()
	local st = workspace:FindFirstChild("_LampStage")
	if st then
		st:Destroy()
	end
end

local function num(s)
	if s:sub(1, 1) == "n" then
		return -tonumber(s:sub(2)) / 1000
	end
	return tonumber(s) / 1000
end
function LS.backup(id)
	local f = game.ServerStorage:FindFirstChild("LampBackup_21Nov")
	if not f then
		f = Instance.new("Folder")
		f.Name = "LampBackup_21Nov"
		f.Parent = game.ServerStorage
	end
	if not f:FindFirstChild(id) then
		CM[id]:Clone().Parent = f
		return true
	end
	return false
end

function LS.lit(m, mode)
	for _, d in m:GetChildren() do
		if d.Name:sub(1, 7) == "LampFx_" then
			local r = d.Name:sub(8, -2)
			d.Transparency = 1
			if r == "HeadCore" then
				d.Transparency = 0
				d.Color = Color3.fromRGB(240, 246, 255)
			elseif r == "HeadGlass" then
				d.Transparency = 0.62
				d.Color = Color3.fromRGB(240, 246, 255)
			elseif r == "Tail" then
				d.Transparency = 0.3
				d.Color = Color3.fromRGB(150, 0, 6)
			end
			if mode == "all" then
				if r == "TurnF" or r == "TurnR" then
					d.Transparency = 0
					d.Color = Color3.fromRGB(255, 140, 16)
				elseif r == "Rev" then
					d.Transparency = 0
					d.Color = Color3.fromRGB(255, 252, 244)
				end
			end
		end
	end
end

-- a pack's LF_<role><L|R>_<centre mm>_<size mm> meshes replace those roles on the model (other roles stay)
function LS.apply(id, assetId, mode)
	local pack = game:GetService("InsertService"):LoadAsset(assetId)
	local model = CM[id]
	local made = LS.backup(id)
	local out = {}
	for _, d in pack:GetDescendants() do
		if d:IsA("MeshPart") then
			local role, cx, cy, cz, sx, sy, sz = string.match(d.Name, "^LF_(%a+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
			if role then
				local name = "LampFx_" .. role
				local old = model:FindFirstChild(name)
				if old then
					old:Destroy()
				end
				local q = d:Clone()
				q.Name = name
				q.Size = Vector3.new(math.max(num(sx), 0.002), math.max(num(sy), 0.002), math.max(num(sz), 0.002))
				q.CFrame = model:GetPivot() * CFrame.new(num(cx), num(cy), num(cz))
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.CastShadow = false
				q.Massless = true
				q.Material = Enum.Material.Neon
				q.Color = Color3.new(1, 1, 1)
				q.Transparency = 0.9
				q.Parent = model
				local ok = pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				table.insert(out, role .. (ok and "" or "(fidelity!)"))
			end
		end
	end
	pack:Destroy()
	LS.lit(LS.stage(id), mode or "all")
	table.sort(out)
	return #out .. " placed, backup made now=" .. tostring(made) .. ": " .. table.concat(out, ",")
end

return "LS ready"
