-- (19 Nov 2026, DISTRICT REBUILD agent 3) helpers for rebuilding single road cells in the main place.
-- Paste into execute_luau (or require a ModuleScript copy) once per Studio session; they live in _G.
-- Needs _G.RY = a loaded YangonRoads (require(ClaudeTools.YangonRoads:Clone()).load() with Roads05_* in YangonData).
--   _G.RBXJob(label, {x0, z0, x1, z1})  build the box (spawned), collect pages, zstd+base64 slices; poll _G.RBX.st[label]
--   _G.RBXZ(label, k)                   slice k padded to 99,000 chars (one per call: the result lands in a tool-results file)
--   _G.PREP(tag, {glb ids}, collideId)  LoadAsset the baked glbs + collide pack into ServerStorage.<tag>_NewMeshes/_NewCollide
--   _G.SWAPGO(tag, {"21x27", ...}, "<tag>_NewMeshes", "<tag>_NewCollide")  old Cell_ + boxes (by box centre) -> ServerStorage.RB_Old<tag>
-- Poll _G.SWP / _G.SWP2. Free with _G.RBX.slices = {} and _G.RY = nil after.
_G.RBX = _G.RBX or { slices = {}, st = {}, log = {} }
_G.RBXJob = function(label, box)
	local J = _G.RBX
	J.st[label] = "building"
	task.spawn(function()
		local ok, err = pcall(function()
			local root = workspace.Yangon1to1.RoadsBuildRB
			local cellRoot = Instance.new("Folder")
			cellRoot.Name = "C" .. label
			cellRoot.Parent = root
			-- (24 Nov, May Ni Gone deck in 18x22: a cell box rebuilt alone has no deck whose middle lies outside it, so the
			-- swap lost that deck's surface in the cell) build every deck with a sample in the box; the bake keeps only its cells
			_G.RY.DECK_TOUCH = true
			local log = _G.RY.stepCell(box, cellRoot)
			J.st[label] = "collecting"
			-- (24 Nov: require caches a ModuleScript's first Source for the session; a Clone gets the current one, v3 pages)
			local B = require(game.ServerStorage.ClaudeTools.RoadBake05:Clone())
			local info = B.collect(cellRoot, label)
			local pages = _G.RoadBake05Pages
			local ES = game:GetService("EncodingService")
			local raw = buffer.fromstring(table.concat(pages, "\n"))
			local b64 = buffer.tostring(ES:Base64Encode(ES:CompressBuffer(raw, Enum.CompressionAlgorithm.Zstd, 9)))
			local sl = {}
			for a = 1, #b64, 98000 do
				table.insert(sl, b64:sub(a, a + 97999))
			end
			J.slices[label] = { sl = sl, np = #pages }
			_G.RoadBake05Pages = nil
			local n = B.clear(root)
			cellRoot:Destroy()
			J.log[label] = log .. "\n" .. info
			J.st[label] = string.format("done: %s | %d pages -> %d slices, cleared %d", info, #pages, #sl, n)
		end)
		if not ok then
			J.st[label] = "ERR " .. tostring(err)
		end
	end)
end
_G.RBXZ = function(label, k)
	local s = _G.RBX.slices[label]
	local t = string.format("@Z%s_01_%02d_%02d@", label, k, #s.sl) .. s.sl[k] .. "@END@"
	if #t < 99000 then
		t ..= string.rep("#", 99000 - #t)
	end
	return t
end
_G.PREP = function(tag, glbs, colId)
	_G.SWP = "prep " .. tag
	task.spawn(function()
		local ok, err = pcall(function()
			local SS, IS = game.ServerStorage, game:GetService("InsertService")
			local H = Instance.new("Folder")
			H.Name = tag .. "_Holding"
			H.Parent = SS
			-- (24 Nov: fresh uploads often answer HTTP 502 for a while) each LoadAsset retried 6 times, 5 s x try apart
			local function load(id)
				for t = 1, 6 do
					local ok, m = pcall(IS.LoadAsset, IS, id)
					if ok then
						return m
					end
					task.wait(5 * t)
				end
				error("LoadAsset failed: " .. tostring(id))
			end
			for _, id in glbs do
				load(id).Parent = H
			end
			local cm = load(colId)
			local text = {}
			for _, d in cm:GetDescendants() do
				if d:IsA("ModuleScript") then
					table.insert(text, require(d))
				end
			end
			cm:Destroy()
			local NM = Instance.new("Folder")
			NM.Name = tag .. "_NewMeshes"
			NM.Parent = SS
			local NC = Instance.new("Folder")
			NC.Name = tag .. "_NewCollide"
			NC.Parent = SS
			local nm = require(SS.ClaudeTools.YangonRoadMeshes).place(H, NM)
			local nc, B = 0, require(SS.ClaudeTools.RoadBake05:Clone())
			for _, t in text do
				nc += B.collide(t, NC)
			end
			H:Destroy()
			_G.SWP = string.format("%s ready: %d meshes, %d boxes", tag, nm, nc)
		end)
		if not ok then
			_G.SWP = "ERR " .. tostring(err)
		end
	end)
end
_G.SWAPGO = function(tag, cellList, NMname, NCname)
	_G.SWP2 = "swapping " .. tag
	task.spawn(function()
		local ok, err = pcall(function()
			local SS, R = game.ServerStorage, workspace.Yangon1to1.Roads
			local set = {}
			for _, c in cellList do
				set[c] = true
			end
			local BK = Instance.new("Folder")
			BK.Name = "RB_Old" .. tag
			local BM = Instance.new("Folder")
			BM.Name = "Meshes"
			BM.Parent = BK
			local BC = Instance.new("Folder")
			BC.Name = "Collide"
			BC.Parent = BK
			BK.Parent = SS
			local old = {}
			for _, p in R.Collide:GetChildren() do
				local pos = p.Position
				if set[(pos.X // 1536) .. "x" .. (pos.Z // 1536)] then
					table.insert(old, p)
				end
			end
			local om = 0
			for _, c in cellList do
				local m = R.Meshes:FindFirstChild("Cell_" .. c)
				if m then
					m.Parent = BM
					om += 1
				end
			end
			for i, p in old do
				p.Parent = BC
				if i % 2000 == 0 then
					task.wait()
				end
			end
			local NM, NC = SS[NMname], SS[NCname]
			local nm = 0
			for _, m in NM:GetChildren() do
				m.Parent = R.Meshes
				nm += 1
			end
			local nc = 0
			for i, p in NC:GetChildren() do
				p.Parent = R.Collide
				nc += 1
				if i % 2000 == 0 then
					task.wait()
				end
			end
			NM:Destroy()
			NC:Destroy()
			_G.SWP2 = string.format("%s swapped: old %d cells + %d boxes -> SS.%s; new %d cells + %d boxes in", tag, om, #old, BK.Name, nm, nc)
		end)
		if not ok then
			_G.SWP2 = "ERR " .. tostring(err)
		end
	end)
end
return true
