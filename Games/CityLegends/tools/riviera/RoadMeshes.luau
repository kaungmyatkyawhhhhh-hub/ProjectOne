--[[
	RoadMeshes (Studio, Edit mode; owner, 2026-11-06: "make all the roads smooth like in the blender"): puts the
	road meshes (tools/road_mesh/) on the map and hides the parts they replace.

	The meshes come in as Models in ServerStorage.RoadMeshHolding. Each MeshPart's name carries its true
	box: kind_id_cx_cy_cz_sx_sy_sz in hundredths of a stud ("n" = minus), because the importer scales and
	centres every mesh. They go to Workspace.Riviera.RoadMeshes with no collision: the road, kerb and pavement
	parts stay in the place for the cars, the traffic and every raycast, invisible (attribute MeshHidden).

	RoadMeshes.place(holding, folder) -> meshes placed
	RoadMeshes.hide(roads) -> parts hidden (the road surface, lines, and the kerbs, pavements and
	shoulders marked InMesh by the export)
	RoadMeshes.undo(roads) -> shows the parts again and removes the meshes
]]

local RoadMeshes = {}

local LOOK = {
	R = { Enum.Material.Asphalt, Color3.fromRGB(46, 47, 50) },
	L = { Enum.Material.SmoothPlastic, Color3.fromRGB(232, 232, 226) },
	KS = { Enum.Material.Concrete, Color3.fromRGB(205, 202, 194) },
	KR = { Enum.Material.Concrete, Color3.fromRGB(186, 34, 34) },
	KW = { Enum.Material.Concrete, Color3.fromRGB(232, 230, 224) },
	PP = { Enum.Material.Pavement, Color3.fromRGB(176, 104, 92) },
	PB = { Enum.Material.Pavement, Color3.fromRGB(235, 228, 218), "RivPaveBasket" },
	PH = { Enum.Material.Pavement, Color3.fromRGB(236, 226, 214), "RivPaveHerring" },
	PC = { Enum.Material.Pavement, Color3.fromRGB(230, 222, 210), "RivCobble" },
	S = { Enum.Material.Concrete, Color3.fromRGB(150, 146, 138) },
}

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -tonumber(string.sub(s, 2)) :: number / 100
	end
	return tonumber(s) :: number / 100
end

function RoadMeshes.place(holding: Instance, folder: Instance): number
	local n = 0
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, _, cx, cy, cz, sx, sy, sz = string.match(d.Name, "^(%a+)_([%dx]+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
			local look = kind and LOOK[kind]
			if look then
				local q = d:Clone()
				q.Name = "RoadMesh" .. kind
				q.Size = Vector3.new(number(sx), number(sy), number(sz))
				-- (the importer turns everything round: a half turn puts the mesh back)
				q.CFrame = CFrame.new(number(cx), number(cy), number(cz)) * CFrame.Angles(0, math.pi, 0)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.CastShadow = false
				q.Material = look[1]
				q.Color = look[2]
				if look[3] then
					q.MaterialVariant = look[3]
				end
				q.Parent = folder
				n += 1
				if n % 60 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

function RoadMeshes.hide(roads: Instance): number
	local n = 0
	for _, road in roads:GetChildren() do
		for _, p in road:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local take = (p.Name == "Road" and p:IsA("WedgePart")) or p.Name == "Line" or p.Name == "Zebra" or p:GetAttribute("InMesh") == true
				if take then
					p.Transparency = 1
					p:SetAttribute("MeshHidden", true)
					n += 1
				end
			end
		end
		task.wait()
	end
	return n
end

-- the islands between roads: their tops and kerbs are in the meshes now (the stone walls on them stay)
function RoadMeshes.hideIslands(dressing: Instance): number
	local n = 0
	for _, top in { "RoadIslands", "HairpinIslands" } do
		local folder = dressing:FindFirstChild(top)
		if folder then
			for _, p in folder:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 and (p.Name == "Island" or p.Name == "IslandKerb") then
					p.Transparency = 1
					p:SetAttribute("MeshHidden", true)
					n += 1
				end
			end
		end
	end
	return n
end

function RoadMeshes.undo(roads: Instance): number
	local n = 0
	local dressing = roads.Parent and roads.Parent:FindFirstChild("Dressing")
	for _, top in { "RoadIslands", "HairpinIslands" } do
		local folder = dressing and dressing:FindFirstChild(top)
		for _, p in if folder then folder:GetDescendants() else {} do
			if p:IsA("BasePart") and p:GetAttribute("MeshHidden") then
				p.Transparency = 0
				p:SetAttribute("MeshHidden", nil)
				n += 1
			end
		end
	end
	for _, road in roads:GetChildren() do
		for _, p in road:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("MeshHidden") then
				p.Transparency = 0
				p:SetAttribute("MeshHidden", nil)
				n += 1
			end
		end
		task.wait()
	end
	local riv = roads.Parent
	local f = riv and riv:FindFirstChild("RoadMeshes")
	if f then
		f:ClearAllChildren()
	end
	return n
end

return RoadMeshes
