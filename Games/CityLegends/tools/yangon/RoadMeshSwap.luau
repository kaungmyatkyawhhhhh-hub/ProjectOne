--[[
	RoadMeshSwap (Studio, Edit; 25 Nov 2026, road bug sweep): mesh-only swap of whole road cells (no collision box touched).
	Paste into execute_luau once per Studio session (the helpers live in _G), then:

	_G.MSWALL({ {tag, {glb asset ids}, {"12x11", ...}}, ... })   -- runs in turn; each prints "MSW <result>" to the log
	_G.MSWAP(tag, ids, cells)                                     -- one batch; result in _G.MSW

	Each batch: LoadAsset every glb (6 tries), YangonRoadMeshes.place into a holding folder, check the new Cell_ folders
	are exactly the cells asked for, move the old Cell_ folders to ServerStorage.RB_Old<tag>, put the new ones in and set
	the meshes CanCollide / CanQuery / CanTouch / CastShadow off, CollisionFidelity Box (as the place's other road meshes).
	Delete the RB_Old folders after a look (place size), then save.
]]
_G.MSWAP = function(tag, ids, cells)
	_G.MSW = "running " .. tag
	task.spawn(function()
		local ok, err = pcall(function()
			local SS, IS = game.ServerStorage, game:GetService("InsertService")
			local H = Instance.new("Folder")
			H.Name = tag .. "_Holding"
			H.Parent = SS
			for _, id in ids do
				local m
				for t = 1, 6 do
					local ok2, r = pcall(IS.LoadAsset, IS, id)
					if ok2 then
						m = r
						break
					end
					task.wait(5 * t)
				end
				if not m then
					error("LoadAsset failed " .. id)
				end
				m.Parent = H
			end
			local NM = Instance.new("Folder")
			NM.Name = tag .. "_NewMeshes"
			NM.Parent = SS
			local nm = require(SS.ClaudeTools.YangonRoadMeshes:Clone()).place(H, NM)
			H:Destroy()
			local got = {}
			for _, c in NM:GetChildren() do
				got[c.Name:sub(6)] = true
			end
			for _, c in cells do
				if not got[c] then
					error("new meshes lack cell " .. c)
				end
			end
			for _, c in NM:GetChildren() do
				if not table.find(cells, c.Name:sub(6)) then
					error("extra cell " .. c.Name)
				end
			end
			local R = workspace.Yangon1to1.Roads
			local BK = Instance.new("Folder")
			BK.Name = "RB_Old" .. tag
			BK.Parent = SS
			local n = 0
			for _, c in cells do
				local old = R.Meshes:FindFirstChild("Cell_" .. c)
				if old then
					old.Parent = BK
				end
			end
			for _, c in NM:GetChildren() do
				for _, m in c:GetDescendants() do
					if m:IsA("MeshPart") then
						m.CanCollide, m.CanQuery, m.CanTouch, m.CastShadow = false, false, false, false
						m.CollisionFidelity = Enum.CollisionFidelity.Box
						n += 1
					end
				end
				c.Parent = R.Meshes
			end
			NM:Destroy()
			_G.MSW = string.format("%s swapped: %d cells, %d meshes (placed %s); old in SS.%s", tag, #cells, n, tostring(nm), BK.Name)
		end)
		if not ok then
			_G.MSW = "ERR " .. tag .. " " .. tostring(err)
		end
	end)
end

_G.MSWALL = function(jobs)
	_G.MSWLOG = {}
	task.spawn(function()
		for _, j in jobs do
			_G.MSWAP(j[1], j[2], j[3])
			repeat
				task.wait(1)
			until not tostring(_G.MSW):match("^running")
			table.insert(_G.MSWLOG, _G.MSW)
			print("MSW " .. tostring(_G.MSW))
		end
		table.insert(_G.MSWLOG, "ALLDONE")
	end)
end

return true
