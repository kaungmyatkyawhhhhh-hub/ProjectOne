-- tools/exhaust/ExhaustCheck.luau (2026-11-21): check and measure the exhaust flame points (shared/ExhaustTips.lua)
-- in Studio, Edit. Paste into execute_luau; it sets _G.EX.
--   EX.stage()            every car in ExhaustTips.CARS in a line (car k at x = 5k, y 5200, its rear at z = 0, nose to -Z,
--                         by its wheels), a green rod out of every table tip. Look straight from behind, level with the
--                         pipes: screen_capture camera (5k, 5200.4, 2.2) -> (5k, 5200.4, 0). A rod must come out of a pipe.
--   EX.scan(id, opts)     the loose pieces low at the rear of CarModels[id]: part, ax (metres from the middle), up (over
--                         the lowest point), in (from the rear-most point), size. A pipe is a round piece about 0.06-0.14
--                         across and deeper than 0.05. Row = { ax / len, up / len, in / len } (len is printed).
--   EX.unstage()
-- 21 Nov: 19 of 24 rows were right; SLS and LP570 pointed at the centre fog lamp, 458 Speciale 7 cm low, GT3 8 cm high,
-- 599 3 cm low (the cloud's rows were picked by eye from renders).
local AS = game:GetService("AssetService")
local CM = game.ReplicatedStorage.CarModels
local X = {}
_G.EX = X

local function wheelPos(m, key)
	local w = m:FindFirstChild(key, true)
	if not w then
		return nil
	end
	if w:IsA("BasePart") then
		return w.Position
	end
	local sum, n = Vector3.zero, 0
	for _, d in w:GetDescendants() do
		if d:IsA("BasePart") then
			sum += d.Position
			n += 1
		end
	end
	return n > 0 and sum / n or nil
end

-- the car's frame (-Z forward, from its wheels), its visible box in that frame and its middle across
function X.frame(m)
	local fl, fr, rl, rr = wheelPos(m, "FL"), wheelPos(m, "FR"), wheelPos(m, "RL"), wheelPos(m, "RR")
	local front, rear = (fl + fr) / 2, (rl + rr) / 2
	local frame = CFrame.lookAt(rear, rear + ((front - rear) * Vector3.new(1, 0, 1)).Unit)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 and not d.Name:find("^LampFx") and not d.Name:find("^Mark") then
			local cf = frame:ToObjectSpace(d.CFrame)
			local h = d.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local p = cf * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)
						lo = lo:Min(p)
						hi = hi:Max(p)
					end
				end
			end
		end
	end
	local midX = (frame:PointToObjectSpace(rl).X + frame:PointToObjectSpace(rr).X) / 2
	return frame, lo, hi, midX
end

function X.scan(id, opts)
	opts = opts or {}
	local m = CM[id]
	local frame, lo, hi, midX = X.frame(m)
	local rows = {}
	for _, p in m:GetDescendants() do
		if p:IsA("MeshPart") and p.Transparency < 1 and not p.Name:find("^LampFx") and not p:FindFirstAncestor("Wheels") and not p.Name:find("^SeeThrough") then
			local c = frame:PointToObjectSpace(p.Position)
			if c.Z + p.Size.Magnitude / 2 < hi.Z - (opts.depth or 0.6) then
				continue
			end
			local ok, em = pcall(function()
				return AS:CreateEditableMeshAsync(Content.fromUri(p.MeshId))
			end)
			if not ok then
				continue
			end
			local mn, mx = Vector3.one * math.huge, -Vector3.one * math.huge
			local raw = {}
			for _, v in em:GetVertices() do
				local q = em:GetPosition(v)
				raw[v] = q
				mn = mn:Min(q)
				mx = mx:Max(q)
			end
			local cc, e = (mn + mx) / 2, mx - mn
			local sc = Vector3.new(e.X > 1e-6 and p.Size.X / e.X or 1, e.Y > 1e-6 and p.Size.Y / e.Y or 1, e.Z > 1e-6 and p.Size.Z / e.Z or 1)
			local toF = frame:Inverse() * p.CFrame
			local pos, key, keyOf, nk = {}, {}, {}, 0
			for v, q in raw do
				local w = toF * ((q - cc) * sc)
				pos[v] = w
				local s = string.format("%d,%d,%d", math.floor(w.X * 500 + 0.5), math.floor(w.Y * 500 + 0.5), math.floor(w.Z * 500 + 0.5))
				local k = keyOf[s]
				if not k then
					nk += 1
					k = nk
					keyOf[s] = k
				end
				key[v] = k
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
				local a = find(key[t[1]])
				parent[a] = a
				for k2 = 2, #t do
					parent[find(key[t[k2]])] = a
				end
			end
			local isl = {}
			for i in faces do
				local r = find(key[fv[i][1]])
				local I = isl[r]
				if not I then
					I = { n = 0, mn = Vector3.one * math.huge, mx = -Vector3.one * math.huge }
					isl[r] = I
				end
				for _, v in fv[i] do
					I.mn = I.mn:Min(pos[v])
					I.mx = I.mx:Max(pos[v])
				end
				I.n += 1
			end
			for _, I in isl do
				local s = I.mx - I.mn
				local c2 = (I.mn + I.mx) / 2
				local up = c2.Y - lo.Y
				if I.mx.Z > hi.Z - (opts.depth or 0.45) and up < (opts.up or 0.75) and up > 0.08 and math.max(s.X, s.Y) < (opts.max or 0.3) and math.max(s.X, s.Y) > 0.035 and I.n >= 12 and s.Z > 0.02 then
					table.insert(rows, { p = p.Name, ax = c2.X - midX, up = up, inn = hi.Z - I.mx.Z, sx = s.X, sy = s.Y, sz = s.Z, n = I.n })
				end
			end
			em:Destroy()
			task.wait()
		end
	end
	table.sort(rows, function(a, b)
		if a.p ~= b.p then
			return a.p < b.p
		end
		return a.ax < b.ax
	end)
	local out = { string.format("%s len %.3f", id, hi.Z - lo.Z) }
	for i = 1, math.min(#rows, opts.rows or 60) do
		local r = rows[i]
		table.insert(out, string.format(" %-22s ax %+.3f up %.3f in %.3f  size %.2fx%.2fx%.2f t%d", r.p, r.ax, r.up, r.inn, r.sx, r.sy, r.sz, r.n))
	end
	return table.concat(out, "\n")
end

function X.unstage()
	local st = workspace:FindFirstChild("_ExStage")
	if st then
		st:Destroy()
	end
end

function X.stage()
	X.unstage()
	local tmp = game.ReplicatedStorage.Shared:Clone() -- (Edit's require caches: a fresh copy reads the current table)
	tmp.Parent = game.ServerStorage
	local ET = require(tmp.ExhaustTips)
	tmp:Destroy()
	local st = Instance.new("Folder")
	st.Name = "_ExStage"
	st.Parent = workspace
	local ids = {}
	for id in ET.CARS do
		table.insert(ids, id)
	end
	table.sort(ids)
	local out = {}
	for k, id in ids do
		local m = CM[id]:Clone()
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		m.Parent = st
		local frame, lo, hi, midX = X.frame(m)
		local len = hi.Z - lo.Z
		m:PivotTo(CFrame.new(5 * k, 5200, 0) * (frame * CFrame.new(midX, lo.Y, hi.Z)):Inverse() * m:GetPivot())
		for _, r in ET.CARS[id] do
			local tip = Vector3.new(5 * k + r[1] * len, 5200 + r[2] * len, -r[3] * len)
			local rod = Instance.new("Part")
			rod.Anchored = true
			rod.CanCollide = false
			rod.Shape = Enum.PartType.Cylinder
			rod.Material = Enum.Material.Neon
			rod.Color = Color3.fromRGB(0, 255, 60)
			rod.Size = Vector3.new(0.5, 0.025, 0.025)
			rod.CFrame = CFrame.new(tip + Vector3.new(0, 0, 0.25)) * CFrame.Angles(0, math.pi / 2, 0)
			rod.Parent = st
		end
		table.insert(out, string.format("%d %s len %.2f", k, id, len))
	end
	return table.concat(out, "\n")
end

return "EX ready"
