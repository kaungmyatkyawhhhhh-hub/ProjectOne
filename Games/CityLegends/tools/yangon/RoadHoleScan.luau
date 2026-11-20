-- RoadHoleScan (21 Nov): find spots where the visual asphalt mesh (RMeshR) of the 1:1 roads
-- has no collision box (Roads.Collide RCol) under it, and fill them.
-- Edit mode, ServerStorage.ClaudeTools or execute_luau. Keep each MCP call short: run() spawns.
--   local T = require(this:Clone())
--   T.run({"Cell_23x28", ...})      -- poll T.state.done; T.state.holes = {x, meshY, z, kind, cell}
--   T.fill()                         -- after a run: boxes for every hole (attribute HoleFill = "21Nov")
--   T.undo()                         -- removes every HoleFill box
-- Method: each up-facing mesh triangle is sampled on a 4-stud XZ grid; a ray from meshY + 3 down 6
-- against Roads.Collide only. Fill = per grid row, runs of up to 8 points (split where the height
-- leaves the end-to-end line by > 0.12), box 4.4 wide, 2 high, top 0.1 under the mesh (as the
-- builder's boxes), pitched along the run; cloned from a builder R box (invisible, Plastic).
local AS = game:GetService("AssetService")
local T = { state = { done = true, cells = {}, holes = {}, log = {} } }
local function roads() return workspace.Yangon1to1.Roads end

local function scanPart(S, mp)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { roads().Collide }
	local ok, em = pcall(function() return AS:CreateEditableMeshAsync(Content.fromUri(mp.MeshId)) end)
	if not ok then table.insert(S.log, mp:GetFullName() .. " load fail " .. tostring(em)) return end
	local sc, cf, W = mp.Size / mp.MeshSize, mp.CFrame, {}
	for _, v in em:GetVertices() do W[v] = cf:PointToWorldSpace(em:GetPosition(v) * sc) end
	local seen, n, miss, t0 = {}, 0, 0, os.clock()
	for _, f in em:GetFaces() do
		local vs = em:GetFaceVertices(f)
		local a, b, c = W[vs[1]], W[vs[2]], W[vs[3]]
		local nrm = (b - a):Cross(c - a)
		local d = (b.Z - c.Z) * (a.X - c.X) + (c.X - b.X) * (a.Z - c.Z)
		if math.abs(nrm.Y) > 0.5 * nrm.Magnitude and math.abs(d) > 1e-6 then
			for gx = math.ceil(math.min(a.X, b.X, c.X) / 4) * 4, math.max(a.X, b.X, c.X), 4 do
				for gz = math.ceil(math.min(a.Z, b.Z, c.Z) / 4) * 4, math.max(a.Z, b.Z, c.Z), 4 do
					local key = gx .. "," .. gz
					if not seen[key] then
						local l1 = ((b.Z - c.Z) * (gx - c.X) + (c.X - b.X) * (gz - c.Z)) / d
						local l2 = ((c.Z - a.Z) * (gx - c.X) + (a.X - c.X) * (gz - c.Z)) / d
						local l3 = 1 - l1 - l2
						if l1 >= -0.001 and l2 >= -0.001 and l3 >= -0.001 then
							seen[key] = true
							n += 1
							local y = l1 * a.Y + l2 * b.Y + l3 * c.Y
							if not workspace:Raycast(Vector3.new(gx, y + 3, gz), Vector3.new(0, -6, 0), rp) then
								miss += 1
								table.insert(S.holes, { gx, y, gz, mp.Name, mp.Parent.Name })
							end
						end
					end
				end
			end
		end
		if os.clock() - t0 > 0.03 then task.wait() t0 = os.clock() end
	end
	em:Destroy()
	table.insert(S.cells, mp.Parent.Name .. "." .. mp.Name .. " pts " .. n .. " miss " .. miss)
end

function T.run(cells, kinds)
	kinds = kinds or { "RMeshR" }
	local S = { done = false, cells = {}, holes = {}, log = {} }
	T.state = S
	task.spawn(function()
		for _, cn in cells do
			local cell = roads().Meshes:FindFirstChild(cn)
			for _, mp in (cell and cell:GetChildren() or {}) do
				if mp:IsA("MeshPart") and table.find(kinds, mp.Name) then
					local ok, e = pcall(scanPart, S, mp)
					if not ok then table.insert(S.log, cn .. " err " .. tostring(e)) end
				end
			end
		end
		S.done = true
	end)
	return S
end

local function pieces(H)
	local rows, runs, out = {}, {}, {}
	for _, h in H do rows[h[3]] = rows[h[3]] or {} table.insert(rows[h[3]], h) end
	for _, r in rows do
		table.sort(r, function(a, b) return a[1] < b[1] end)
		local cur = { r[1] }
		for i = 2, #r do
			local p, q = r[i - 1], r[i]
			if q[1] - p[1] == 4 and math.abs(q[2] - p[2]) < 1 and #cur < 8 then table.insert(cur, q)
			else table.insert(runs, cur) cur = { q } end
		end
		table.insert(runs, cur)
	end
	local function split(run)
		if #run <= 2 then table.insert(out, run) return end
		local a, b, wi, wd = run[1], run[#run], 0, 0
		for i, p in run do
			local dv = math.abs(p[2] - (a[2] + (p[1] - a[1]) / (b[1] - a[1]) * (b[2] - a[2])))
			if dv > wd then wd, wi = dv, i end
		end
		if wd <= 0.12 then table.insert(out, run) return end
		split(table.move(run, 1, wi, 1, {}))
		split(table.move(run, wi + 1, #run, 1, {}))
	end
	for _, run in runs do split(run) end
	return out
end

function T.fill(H)
	H = H or T.state.holes
	local Col = roads().Collide
	local tpl
	for _, p in Col:GetChildren() do
		if p:GetAttribute("RoadBox") == "R" and not p:GetAttribute("HoleFill") then tpl = p:Clone() break end
	end
	for k in tpl:GetAttributes() do if k ~= "RoadBox" then tpl:SetAttribute(k, nil) end end
	tpl:SetAttribute("HoleFill", "21Nov")
	local n = 0
	for _, run in pieces(H) do
		local a, b = run[1], run[#run]
		local dx = b[1] - a[1]
		local s = dx > 0 and (b[2] - a[2]) / dx or 0
		local up = Vector3.new(-s, 1, 0).Unit
		local c = Vector3.new((a[1] + b[1]) / 2, (a[2] + b[2]) / 2 - 0.1, a[3]) - up
		local p = tpl:Clone()
		p.Size = Vector3.new(4.4, 2, dx + 4.4)
		p.CFrame = CFrame.lookAt(c, c + Vector3.new(1, s, 0).Unit, up)
		p.Parent = Col
		n += 1
		if n % 200 == 0 then task.wait() end
	end
	return n
end

function T.undo()
	local n = 0
	for _, p in roads().Collide:GetChildren() do
		if p:GetAttribute("HoleFill") then p:Destroy() n += 1 end
	end
	return n
end

return T
