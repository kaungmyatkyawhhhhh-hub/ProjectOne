--[[
	MCEscalators (2026-11-19, owner: "in myanmar plaza, some part of the elevator is not collidable and i fall off")
	Puts city/mc_escalator_patch.py's result into the placed Myanmar Centre
	(Workspace.Yangon1to1.Landmarks.MyanmarCentre):
	  M.swap(holding)   the six patched interior meshes (MAR, CEL, GFA, LIT, RAL, STL: landing tongues from the galleries
	                    to the escalators' ends, the atrium's glass ring opened there) via MeshPart:ApplyMesh; the old
	                    MeshId is kept in attribute OldMeshId_esc. `holding` = the LoadAsset'ed Model of
	                    imports/sync/landmarks/mc1/mc1_escalators.glb.
	  M.collide(json)   mc1_escalators.glb.json's "drop" boxes (the old per-step boxes and the ring walls across the
	                    tongues) are matched by position / size in MyanmarCentre.Collide and moved to
	                    ServerStorage.MCEscalatorsOld; its "add" boxes (one pitched ramp per escalator, landing boxes,
	                    tongue slabs and side walls) are made like P1Refit.collide's (name "Col"). Returns counts.
	  M.undo()          puts the old boxes and meshes back.
	Run in Studio Edit (paste + call; every call is short).
]]
local M = {}
local MC = workspace.Yangon1to1.Landmarks.MyanmarCentre

local function prefixOf(name: string): string
	local p = string.split(name, "_")
	return p[1] .. "_" .. p[2] .. "_"
end

function M.swap(holding: Instance): string
	local placed = {}
	for _, d in MC.Meshes:GetDescendants() do
		if d:IsA("MeshPart") then
			placed[prefixOf(d.Name)] = d
		end
	end
	local done = {}
	for _, src in holding:GetDescendants() do
		if src:IsA("MeshPart") then
			local nm = src.Name:gsub("_Node$", "")
			local dst = placed[prefixOf(nm)]
			if dst then
				local p = string.split(nm, "_")
				local c = Vector3.new(tonumber(p[3]) / 100, tonumber(p[4]) / 100, tonumber(p[5]) / 100)
				local s = Vector3.new(tonumber(p[6]) / 100, tonumber(p[7]) / 100, tonumber(p[8]) / 100)
				if dst:GetAttribute("OldMeshId_esc") == nil then
					dst:SetAttribute("OldMeshId_esc", dst.MeshId)
				end
				dst:ApplyMesh(src)
				dst.Size = s
				dst.CFrame = CFrame.new(c)
				dst.Name = nm
				table.insert(done, nm)
			end
		end
	end
	return #done .. " swapped: " .. table.concat(done, ", ")
end

local function key(cf: CFrame, size: Vector3): string
	return string.format("%.1f %.1f %.1f %.1f %.1f %.1f", cf.X, cf.Y, cf.Z, size.X, size.Y, size.Z)
end

function M.collide(json: string): string
	local data = game:GetService("HttpService"):JSONDecode(json)
	local old = game:GetService("ServerStorage"):FindFirstChild("MCEscalatorsOld") or Instance.new("Folder")
	old.Name = "MCEscalatorsOld"
	old.Parent = game:GetService("ServerStorage")
	local want = {}
	for _, v in data.drop do
		want[key(CFrame.new(v[1], v[2], v[3]), Vector3.new(v[4], v[5], v[6]))] = true
	end
	local dropped = 0
	for _, p in MC.Collide:GetChildren() do
		if p:IsA("BasePart") and want[key(p.CFrame, p.Size)] then
			want[key(p.CFrame, p.Size)] = nil
			p.Parent = old
			dropped += 1
		end
	end
	local missing = 0
	for _ in want do
		missing += 1
	end
	local added = 0
	for _, v in data.add do
		local p = Instance.new("Part")
		p.Name = "Col"
		p.Anchored = true
		p.Size = Vector3.new(math.max(v[4], 0.05), math.max(v[5], 0.05), math.max(v[6], 0.05))
		p.CFrame = CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[7], 0) * CFrame.Angles(0, 0, v[8] or 0)
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p:SetAttribute("Esc19Nov", true)
		p.Parent = MC.Collide
		added += 1
	end
	return string.format("dropped %d (not found %d), added %d", dropped, missing, added)
end

function M.undo(): string
	local n = 0
	for _, p in MC.Collide:GetChildren() do
		if p:GetAttribute("Esc19Nov") then
			p:Destroy()
			n += 1
		end
	end
	local old = game:GetService("ServerStorage"):FindFirstChild("MCEscalatorsOld")
	if old then
		for _, p in old:GetChildren() do
			p.Parent = MC.Collide
		end
		old:Destroy()
	end
	for _, d in MC.Meshes:GetDescendants() do
		if d:IsA("MeshPart") and d:GetAttribute("OldMeshId_esc") then
			d.MeshId = d:GetAttribute("OldMeshId_esc") -- shortcut: MeshId can't be set by scripts outside Studio Edit, fine here
			d:SetAttribute("OldMeshId_esc", nil)
		end
	end
	return "undone, boxes removed " .. n
end

return M
