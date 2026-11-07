-- ServerStorage.ClaudeTools.LampScan (run in Studio, Edit): reads a car model's real meshes with
-- EditableMesh and hands back the islands near its nose and tail as text (tools/lamps).
--   require(LampScan:Clone()).summary("lexis_lfa")          every island near the ends: place, size, colour
--   require(LampScan:Clone()).geometry("lexis_lfa", picks)  the triangles of the picked islands
local AS = game:GetService("AssetService")
local M = {}

local function skip(n: string): boolean
	return n:match("^[FR][LR]_") ~= nil or n:find("SteeringWheel", 1, true) ~= nil or n:find("LampFx", 1, true) ~= nil
end

local function bounds(model: Model): (number, number)
	local zmin, zmax = math.huge, -math.huge
	local pv = model:GetPivot()
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local c = pv:PointToObjectSpace(d.Position)
			zmin = math.min(zmin, c.Z - d.Size.Z / 2)
			zmax = math.max(zmax, c.Z + d.Size.Z / 2)
		end
	end
	return zmin, zmax
end

local function image(p: MeshPart): (buffer?, Vector2?)
	local sa = p:FindFirstChildWhichIsA("SurfaceAppearance")
	local id = if sa then sa.ColorMap else nil
	if not id or id == "" then
		id = p.TextureID
	end
	if not id or id == "" then
		return nil, nil
	end
	local ok, img = pcall(function()
		return AS:CreateEditableImageAsync(Content.fromUri(id))
	end)
	if not ok or not img then
		return nil, nil
	end
	local size = img.Size
	local buf = img:ReadPixelsBuffer(Vector2.zero, size)
	img:Destroy()
	return buf, size
end

-- the part's islands (connected triangles), in the model's own space (metres, pivot at 0, nose at -Z)
local function islands(p: MeshPart, pv: CFrame, em: any)
	local vids = em:GetVertices()
	local mn, mx = Vector3.one * math.huge, -Vector3.one * math.huge
	local raw = {}
	for _, v in vids do
		local q = em:GetPosition(v)
		raw[v] = q
		mn = mn:Min(q)
		mx = mx:Max(q)
	end
	local c = (mn + mx) / 2
	local ext = mx - mn
	local sc = Vector3.new(
		if ext.X > 1e-6 then p.Size.X / ext.X else 1,
		if ext.Y > 1e-6 then p.Size.Y / ext.Y else 1,
		if ext.Z > 1e-6 then p.Size.Z / ext.Z else 1
	)
	local toModel = pv:Inverse() * p.CFrame
	local pos = {}
	for v, q in raw do
		pos[v] = toModel * ((q - c) * sc)
	end
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
		local a = find(t[1])
		parent[a] = a
		for k = 2, #t do
			local b = find(t[k])
			parent[b] = a
		end
	end
	local out = {}
	for i, _ in faces do
		local t = fv[i]
		local r = find(t[1])
		local isl = out[r]
		if not isl then
			isl = { root = r, tris = {}, mn = Vector3.one * math.huge, mx = -Vector3.one * math.huge, nrm = Vector3.zero, area = 0 }
			out[r] = isl
		end
		table.insert(isl.tris, i)
		local a, b, d = pos[t[1]], pos[t[2]], pos[t[3]]
		isl.mn = isl.mn:Min(a):Min(b):Min(d)
		isl.mx = isl.mx:Max(a):Max(b):Max(d)
		local n = (b - a):Cross(d - a)
		isl.nrm += n
		isl.area += n.Magnitude / 2
	end
	return out, faces, fv, pos
end

local function colourOf(isl, faces, em, buf, size): { number }?
	if not buf then
		return nil
	end
	local r, g, b, n = 0, 0, 0, 0
	local step = math.max(1, math.floor(#isl.tris / 12))
	for k = 1, #isl.tris, step do
		local ok, uvs = pcall(function()
			return em:GetFaceUVs(faces[isl.tris[k]])
		end)
		if ok and uvs and uvs[1] then
			local uv = em:GetUV(uvs[1])
			local x = math.clamp(math.floor((uv.X % 1) * size.X), 0, size.X - 1)
			local y = math.clamp(math.floor((uv.Y % 1) * size.Y), 0, size.Y - 1)
			local o = (y * size.X + x) * 4
			r += buffer.readu8(buf, o)
			g += buffer.readu8(buf, o + 1)
			b += buffer.readu8(buf, o + 2)
			n += 1
		end
	end
	if n == 0 then
		return nil
	end
	return { math.floor(r / n), math.floor(g / n), math.floor(b / n) }
end

local function round(v: Vector3): { number }
	return { math.floor(v.X * 1000 + 0.5) / 1000, math.floor(v.Y * 1000 + 0.5) / 1000, math.floor(v.Z * 1000 + 0.5) / 1000 }
end

local function eachPart(model: Model, fn: (MeshPart, number) -> ())
	local k = 0
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") and not skip(d.Name) then
			k += 1
			fn(d, k)
			task.wait()
		end
	end
end

local function pad(text: string): string
	-- execute_luau hands back at most 100,000 characters, and a result near that lands in a file
	return text .. string.rep("#", math.max(0, 95000 - #text))
end

function M.summary(id: string, zone: number?): string
	local model = game.ReplicatedStorage.CarModels[id]
	local pv = model:GetPivot()
	local zmin, zmax = bounds(model)
	local L = zmax - zmin
	local z = zone or 0.24
	local rows, names = {}, {}
	eachPart(model, function(p, k)
		local ok, em = pcall(function()
			return AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
		end)
		if not ok or not em then
			names[k] = p.Name .. " FAILED"
			return
		end
		names[k] = p.Name
		local isl, faces = islands(p, pv, em)
		local buf, size = image(p)
		for _, i in isl do
			local s = i.mx - i.mn
			local cz = (i.mn.Z + i.mx.Z) / 2
			if (cz < zmin + L * z or cz > zmax - L * z) and s.X < 1.5 and s.Y < 0.9 and s.Z < 1.6 and i.area >= 0.0004 then
				local rgb = colourOf(i, faces, em, buf, size) or { -1, -1, -1 }
				local n = if i.nrm.Magnitude > 1e-6 then i.nrm.Unit else Vector3.zero
				table.insert(rows, { i.area, string.format("%d|%d|%d|%.4f|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.2f,%.2f,%.2f|%d,%d,%d", k, i.root, #i.tris, i.area, i.mn.X, i.mn.Y, i.mn.Z, i.mx.X, i.mx.Y, i.mx.Z, n.X, n.Y, n.Z, rgb[1], rgb[2], rgb[3]) })
			end
		end
		em:Destroy()
	end)
	table.sort(rows, function(a, b)
		return a[1] > b[1]
	end)
	local lines = { "@S@" .. id, string.format("zmin %.3f zmax %.3f", zmin, zmax) }
	for k, n in names do
		table.insert(lines, "P" .. k .. "=" .. n)
	end
	local total = #rows
	for i = 1, math.min(total, 1300) do
		table.insert(lines, rows[i][2])
	end
	table.insert(lines, "@END@ " .. total)
	return pad(table.concat(lines, string.char(10)))
end

-- picks: { [part index k, as a string] = { island roots } }; `from`: start at this piece (a call hands
-- back about 90,000 characters and says where the next one starts)
function M.geometry(id: string, picks: { [string]: { number } }, from: number?): string
	local model = game.ReplicatedStorage.CarModels[id]
	local pv = model:GetPivot()
	local out, size, n, nextAt = { "@G@" .. id }, 0, 0, nil
	local start = from or 1
	eachPart(model, function(p, k)
		local want = picks[tostring(k)]
		if not want or nextAt then
			return
		end
		local em = AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
		local isl, _, fv, pos = islands(p, pv, em)
		for _, root in want do
			local i = isl[root]
			if i then
				n += 1
				if n >= start and not nextAt then
					local map, verts, tris, c = {}, {}, {}, 0
					for _, t in i.tris do
						local tri = {}
						for _, v in fv[t] do
							if not map[v] then
								local q = pos[v]
								table.insert(verts, string.format("%.3f,%.3f,%.3f", q.X, q.Y, q.Z))
								c += 1
								map[v] = c - 1
							end
							table.insert(tri, map[v])
						end
						table.insert(tris, table.concat(tri, ","))
					end
					local row = table.concat({ string.format("I %d %d", k, root), "V " .. table.concat(verts, ";"), "T " .. table.concat(tris, ";") }, string.char(10))
					if size + #row > 90000 and size > 0 then
						nextAt = n
					else
						table.insert(out, row)
						size += #row
					end
				end
			end
		end
		em:Destroy()
	end)
	table.insert(out, "@END@ " .. (nextAt or 0))
	return pad(table.concat(out, string.char(10)))
end

-- every picked island of every car (ClaudeTools.LampPicks: JSON { car id: { part k: { roots } } }), as hex
-- (position: 3 x 16 bits in mm, offset 32768; corners: 3 x 16 bits): about 4,500 triangles a call
function M.dump(ids: { string }, carAt: number?, start: number?): string
	local P = game:GetService("HttpService"):JSONDecode(game.ServerStorage.ClaudeTools.LampPicks.Value)
	local out, size = { "@G@" }, 0
	local stop: string? = nil
	for c = carAt or 1, #ids do
		local id = ids[c]
		local model = game.ReplicatedStorage.CarModels[id]
		local pv = model:GetPivot()
		local n = 0
		local first = if c == (carAt or 1) then (start or 1) else 1
		table.insert(out, "C " .. id)
		eachPart(model, function(p, k)
			local want = P[id][tostring(k)]
			if not want or stop then
				return
			end
			local em = AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
			local isl, _, fv, pos = islands(p, pv, em)
			for _, root in want do
				local i = isl[root]
				if i then
					n += 1
					if n >= first and not stop then
						local map, verts, tris, nv = {}, {}, {}, 0
						for _, t in i.tris do
							for _, v in fv[t] do
								if not map[v] then
									local q = pos[v]
									table.insert(verts, string.format("%04x%04x%04x", math.floor(q.X * 1000 + 32768.5), math.floor(q.Y * 1000 + 32768.5), math.floor(q.Z * 1000 + 32768.5)))
									map[v] = nv
									nv += 1
								end
								table.insert(tris, string.format("%04x", map[v]))
							end
						end
						local row = string.format("I %d %.0f %s %s", k, root, table.concat(verts), table.concat(tris))
						if size + #row > 91000 and size > 0 then
							stop = c .. " " .. n
						else
							table.insert(out, row)
							size += #row
						end
					end
				end
			end
			em:Destroy()
		end)
		if stop then
			break
		end
	end
	table.insert(out, "@END@ " .. (stop or "done"))
	return pad(table.concat(out, string.char(10)))
end

return M
