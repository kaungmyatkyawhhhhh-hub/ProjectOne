--[[
	RainTree (2026-11-27, owner: "Trees next"): the broadleaf tree ot1 swapped from the Toolbox acacia (flat
	low-poly crown) to our rain tree (tools/trees/leaf_atlas.py + rain_tree.py, Model asset below).

	Run in Studio Edit (execute_luau: paste this file, then call). Everything old goes into
	ServerStorage.TreeBackup_20261127 first; R.undo() puts it back.
	  R.templates()  ReplicatedStorage.YgnKit.Templates: OKA_ot1 = the near tree (one MeshPart, leaves + bark in one
	                 atlas, SurfaceAppearance AlphaMode Transparency), OKB_ot1 (old trunk) out, OKF_ot1far = the far
	                 look (pid "ot1far" is in no Meta PIDS, so the streamer never builds it)
	  R.placed()     the 187 placed "Acacia" models (+ ServerStorage.GreenEdgeKit.BANKTREE's) -> "RainTree" (red LeafyGrass crowns -> "FlameTree", the flame atlas)
	  R.far()        Workspace.Yangon1to1.Green.Far: each old crown + trunk pair -> one OKF_ot1far part (same T)
	  R.undo()
	Scale: record scale 1 = 18.3 m crown (green_1to1.py OLD_KIT), so the mesh (17.3 m) is grown by F.
]]
local R = {}
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

R.MODEL = 125285857865594 -- CL RainTree v3 (RainTree near 1,670 tris, RainTreeFar 220 tris)
R.ATLAS = "rbxassetid://127614795774772" -- rain_atlas.png
R.FLAME = "rbxassetid://86540793969262" -- flame_atlas.png (v2, denser blossoms; v1 was 127408360340598)
R.FARTEX = "rbxassetid://102023366540990" -- rain_far.png
R.ROUGH = "rbxassetid://129339459957618" -- plain white roughness (no sky sheen on the leaves)
-- imports/trees/rain_tree.json (studs, Roblox axes; origin = trunk foot)
R.NEAR = { size = Vector3.new(51.97, 37.55, 51.66), centre = Vector3.new(-0.27, 18.78, -1.01) }
R.FARB = { size = Vector3.new(48.64, 34.99, 46.83), centre = Vector3.new(0.16, 17.49, -1.02) }
R.F = 18.3 * 3 / ((51.97 + 51.66) / 2)
R.BACKUP = "TreeBackup_20261127"

local function backup()
	local b = SS:FindFirstChild(R.BACKUP)
	if not b then
		b = Instance.new("Folder")
		b.Name = R.BACKUP
		b.Parent = SS
	end
	return b
end

local function sub(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local src
local function source()
	if not src then
		src = game:GetService("InsertService"):LoadAsset(R.MODEL)
	end
	return src:FindFirstChild("RainTree", true), src:FindFirstChild("RainTreeFar", true)
end

local function quiet(q)
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	pcall(function()
		q.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
end

function R.nearPart(tex)
	local near = source()
	local q = near:Clone()
	quiet(q)
	q.Material = Enum.Material.Plastic
	q.Color = Color3.new(1, 1, 1)
	q.CastShadow = true
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = tex or R.ATLAS
	sa.RoughnessMap = R.ROUGH
	sa.AlphaMode = Enum.AlphaMode.Transparency
	sa.Parent = q
	return q
end

function R.farPart()
	local _, far = source()
	local q = far:Clone()
	quiet(q)
	q.TextureID = R.FARTEX
	q.Material = Enum.Material.Fabric
	q.Color = Color3.new(1, 1, 1)
	q.CastShadow = false
	return q
end

function R.templates()
	local T = RS.YgnKit.Templates
	local b = sub(backup(), "Templates")
	for _, n in { "OKA_ot1", "OKB_ot1" } do
		local q = T:FindFirstChild(n)
		if q and not b:FindFirstChild(n) then
			q.Parent = b
		elseif q then
			q:Destroy()
		end
	end
	local q = R.nearPart()
	q.Name = "OKA_ot1"
	q.Size = R.NEAR.size * R.F
	q:SetAttribute("C", R.NEAR.centre * R.F)
	q:SetAttribute("S", R.NEAR.size * R.F)
	q.Parent = T
	local f = R.farPart()
	f.Name = "OKF_ot1far"
	f.Size = R.FARB.size * R.F
	f:SetAttribute("C", R.FARB.centre * R.F)
	f:SetAttribute("S", R.FARB.size * R.F)
	local old = T:FindFirstChild("OKF_ot1far")
	if old then
		old:Destroy()
	end
	f.Parent = T
	return "templates in"
end

-- the record frame (trunk foot, yaw) and scale of an old tree from its trunk (old template OKB_ot1's C / S / R)
local function frameOf(trunk)
	local t = backup().Templates.OKB_ot1
	local C, S, Rr = t:GetAttribute("C"), t:GetAttribute("S"), t:GetAttribute("R")
	local s = trunk.Size.Y / S.Y
	return trunk.CFrame * Rr:Inverse() * CFrame.new(-C * s), s
end
local function frameOfCrown(crown)
	local t = backup().Templates.OKA_ot1
	local C, S, Rr = t:GetAttribute("C"), t:GetAttribute("S"), t:GetAttribute("R")
	local s = crown.Size.Y / S.Y
	return crown.CFrame * Rr:Inverse() * CFrame.new(-C * s), s
end

function R.placed()
	local b = sub(backup(), "Placed")
	local list = {}
	-- the placed ones and the green-edge kit's BANKTREE template (G.models clones it)
	for _, root in { workspace, SS:FindFirstChild("GreenEdgeKit") } do
		for _, d in root:GetDescendants() do
			if d:IsA("Model") and d.Name == "Acacia" then
				table.insert(list, d)
			end
		end
	end
	local n, red = 0, 0
	for _, m in list do
		local trunk, crown = m:FindFirstChild("Trunk"), m:FindFirstChild("Crown")
		local cf, s = frameOf(trunk)
		local flame = crown.Material == Enum.Material.LeafyGrass
		local nm = Instance.new("Model")
		nm.Name = if flame then "FlameTree" else "RainTree"
		local q = R.nearPart(if flame then R.FLAME else R.ATLAS)
		q.Name = "Tree"
		q.Size = R.NEAR.size * R.F * s
		q.CFrame = cf * CFrame.new(R.NEAR.centre * R.F * s)
		q.Parent = nm
		nm.WorldPivot = cf
		local ov = Instance.new("ObjectValue") -- the old model in the backup (R.undo)
		ov.Name = "Old"
		ov.Value = m
		ov.Parent = nm
		local parent = m.Parent
		m.Parent = b
		nm.Parent = parent
		n += 1
		red += if flame then 1 else 0
		if n % 40 == 0 then
			task.wait()
		end
	end
	return n .. " placed trees swapped (" .. red .. " flame)"
end

function R.far()
	local green = workspace.Yangon1to1.Green
	local old = green:FindFirstChild("Far")
	local b = backup()
	if b:FindFirstChild("Far") then
		return "a Far backup exists already: undo first"
	end
	local far = Instance.new("Folder")
	far.Name = "Far"
	local n, cells = 0, 0
	for _, cell in old:GetChildren() do
		local nc = Instance.new("Model")
		nc.Name = cell.Name
		for _, q in cell:GetChildren() do
			if q.Name == "OKA_ot1" then
				local cf, s = frameOfCrown(q)
				local p = R.farPart()
				p.Name = "OKF_ot1far"
				p.Size = R.FARB.size * R.F * s
				p.CFrame = cf * CFrame.new(R.FARB.centre * R.F * s)
				p:SetAttribute("T", q:GetAttribute("T"))
				p.Parent = nc
				n += 1
			end
		end
		nc.Parent = far
		cells += 1
		if cells % 4 == 0 then
			task.wait()
		end
	end
	old.Parent = b
	far.Parent = green
	return string.format("far: %d trees in %d cells (old folder in ServerStorage.%s.Far)", n, cells, R.BACKUP)
end

function R.undo()
	local b = SS:FindFirstChild(R.BACKUP)
	if not b then
		return "no backup"
	end
	local T = RS.YgnKit.Templates
	for _, n in { "OKA_ot1", "OKF_ot1far" } do
		local q = T:FindFirstChild(n)
		if q then
			q:Destroy()
		end
	end
	if b:FindFirstChild("Templates") then
		for _, q in b.Templates:GetChildren() do
			q.Parent = T
		end
	end
	if b:FindFirstChild("Far") then
		local cur = workspace.Yangon1to1.Green:FindFirstChild("Far")
		if cur then
			cur:Destroy()
		end
		b.Far.Parent = workspace.Yangon1to1.Green
	end
	local n = 0
	local all = workspace:GetDescendants()
	for _, d in SS.GreenEdgeKit:GetDescendants() do
		table.insert(all, d)
	end
	for _, d in all do
		if d:IsA("Model") and (d.Name == "RainTree" or d.Name == "FlameTree") then
			local ov = d:FindFirstChild("Old")
			if ov and ov.Value then
				ov.Value.Parent = d.Parent
				d:Destroy()
				n += 1
			end
		end
	end
	return "undone, placed back " .. n
end

return R
