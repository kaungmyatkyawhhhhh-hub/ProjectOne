--[[
	Palms (2026-11-27): the old map's palm (Monaco kit: a curved trunk mesh + two flat star-shaped crown cards, mesh
	10562881447 + 10562874217) and the roadside toddy palm swapped for our own (tools/trees/palm_atlas.py +
	palm_tree.py, Model asset below): CocoPalm (~12 m coconut), CocoPalmT (~16 m), ToddyPalm (fan palm).

	Run in Studio Edit (execute_luau: paste this file, then call). Everything old goes into
	ServerStorage.PalmBackup_20261127 first; P.undo() puts it back.
	  P.templates()  ReplicatedStorage.YgnKit.Templates: OKA_op1 = CocoPalm, OKA_op2 = CocoPalmT (one MeshPart each,
	                 SurfaceAppearance AlphaMode Transparency); old OKA/OKB/OKC_op1/op2 out. Scale 1 = the old palm's
	                 height (op1 12.2 m, op2 16.3 m: green_1to1.py OLD_KIT), so the records line up.
	  P.placed()     every placed old palm model (FANPALM, Palm, PalmA: workspace, GreenEdgeKit, MonacoKit.Dressing,
	                 DealerBody(Compact).Remodel) -> one MeshPart "Palm", same foot, yaw and height
	  P.toddy()      ReplicatedStorage.RoadsideKit.ToddyPalm (client-built median palms): Trunk + Crown -> ToddyPalm mesh
	  P.landmarks()  the palms (and broad trees) baked into the 3D landmarks' KTW / KTL meshes (see below)
	  P.undo()
	Not swapped: ServerStorage.YangonData.GreenKit (YangonGreen1to1.oldTemplates' source; re-running that brings the old
	templates back: run P.templates() after it) and ServerStorage.RivieraAssets (Monaco's originals).
]]
local P = {}
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

P.MODEL = 111240851902621 -- CL Palms v1 (CocoPalm 1,190 / CocoPalmT 1,190 / ToddyPalm 300 tris)
P.ATLAS = "rbxassetid://86989180507805" -- palm_atlas.png
P.ROUGH = "rbxassetid://129339459957618" -- plain white roughness (the rain tree's: no sky sheen)
-- imports/trees/palms.json (studs, Roblox axes; origin = trunk foot)
P.MESH = {
	CocoPalm = { size = Vector3.new(25.40, 43.65, 23.64), centre = Vector3.new(3.13, 21.38, -0.66) },
	CocoPalmT = { size = Vector3.new(26.38, 56.65, 23.82), centre = Vector3.new(2.03, 27.87, 0.18) },
	ToddyPalm = { size = Vector3.new(25.29, 68.16, 24.47), centre = Vector3.new(0.21, 33.66, -0.62) },
}
P.OLD_H = { op1 = 36.73, op2 = 48.85 } -- old template model heights (studs) at record scale 1
P.TRUNK, P.CROWN = "rbxassetid://10562881447", "rbxassetid://10562874217"
P.BACKUP = "PalmBackup_20261127"

local function sub(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end
local function backup()
	return sub(SS, P.BACKUP)
end

local src
function P.part(kind: string, h: number)
	if not src then
		src = game:GetService("InsertService"):LoadAsset(P.MODEL)
	end
	local q = src:FindFirstChild(kind, true):Clone()
	local f = h / P.MESH[kind].size.Y
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.CastShadow = true
	q.DoubleSided = true -- the frond cards have no back faces
	q.Material = Enum.Material.Plastic
	q.Color = Color3.new(1, 1, 1)
	pcall(function()
		q.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	q.Size = P.MESH[kind].size * f
	local sa = Instance.new("SurfaceAppearance")
	sa.ColorMap = P.ATLAS
	sa.RoughnessMap = P.ROUGH
	sa.AlphaMode = Enum.AlphaMode.Transparency
	sa.Parent = q
	return q, f
end

function P.templates()
	local T = RS.YgnKit.Templates
	local b = sub(backup(), "Templates")
	for _, pid in { "op1", "op2" } do
		for _, k in { "A", "B", "C" } do
			local q = T:FindFirstChild("OK" .. k .. "_" .. pid)
			if q and not b:FindFirstChild(q.Name) then
				q.Parent = b
			elseif q then
				q:Destroy()
			end
		end
		local kind = if pid == "op1" then "CocoPalm" else "CocoPalmT"
		local q, f = P.part(kind, P.OLD_H[pid])
		q.Name = "OKA_" .. pid
		q:SetAttribute("C", P.MESH[kind].centre * f)
		q:SetAttribute("S", q.Size)
		q.Parent = T
	end
	return "templates in"
end

-- an old palm model: only the trunk and crown meshes in it
local function isOldPalm(m: Instance): BasePart?
	if not m:IsA("Model") then
		return nil
	end
	local trunk, other = nil, false
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			if d:IsA("MeshPart") and d.MeshId == P.TRUNK then
				trunk = d
			elseif not (d:IsA("MeshPart") and d.MeshId == P.CROWN) then
				other = true
			end
		end
	end
	return if trunk and not other then trunk else nil
end

function P.placed()
	local b = sub(backup(), "Placed")
	local roots = { workspace }
	for _, n in { "GreenEdgeKit", "MonacoKit", "DealerBody", "DealerBodyCompact" } do
		table.insert(roots, SS:FindFirstChild(n))
	end
	local list = {}
	for _, root in roots do
		for _, d in root:GetDescendants() do
			if d.Name == "FANPALM" or d.Name == "Palm" or d.Name == "PalmA" then
				local trunk = isOldPalm(d)
				if trunk then
					table.insert(list, { d, trunk })
				end
			end
		end
	end
	local n = 0
	for _, it in list do
		local m, trunk = it[1], it[2]
		local cf, size = m:GetBoundingBox()
		local foot = trunk.Position - Vector3.new(0, trunk.Size.Y / 2, 0)
		local h = cf.Position.Y + size.Y / 2 - foot.Y
		local lv = trunk.CFrame.LookVector
		local frame = CFrame.new(foot) * CFrame.Angles(0, math.atan2(-lv.X, -lv.Z), 0)
		local kind = if h > 45 then "CocoPalmT" else "CocoPalm"
		local nm = Instance.new("Model")
		nm.Name = m.Name
		local q, f = P.part(kind, h)
		q.Name = "Palm"
		q.CFrame = frame * CFrame.new(P.MESH[kind].centre * f)
		q.Parent = nm
		nm.WorldPivot = frame
		for k, v in m:GetAttributes() do
			nm:SetAttribute(k, v)
		end
		local ov = Instance.new("ObjectValue") -- the old model in the backup (P.undo)
		ov.Name = "Old"
		ov.Value = m
		ov.Parent = nm
		local parent = m.Parent
		m.Parent = b
		nm.Parent = parent
		n += 1
		if n % 40 == 0 then
			task.wait()
		end
	end
	return n .. " placed palms swapped"
end

function P.toddy()
	local kit = RS.RoadsideKit
	local old = kit:FindFirstChild("ToddyPalm")
	local b = sub(backup(), "Templates")
	if b:FindFirstChild("ToddyPalm") then
		return "toddy backup exists already: undo first"
	end
	local h = old:GetExtentsSize().Y
	local nm = Instance.new("Model")
	nm.Name = "ToddyPalm"
	local q, f = P.part("ToddyPalm", h)
	q.Name = "Palm"
	q.CFrame = old:GetPivot() * CFrame.new(P.MESH.ToddyPalm.centre * f)
	q.Parent = nm
	nm.WorldPivot = old:GetPivot()
	old.Parent = b
	nm.Parent = kit
	return "toddy palm in, h " .. h
end

--[[ The 3D landmarks (Myanmar Plaza = Landmarks.MyanmarCentre, Sedona) carry their palms and broad trees baked into one
	KTW (trunks) + one KTL (leaves) MeshPart each (city/mc3d.py _palm / _rain_tree, props1to1.py). Their trunks are
	found in the KTW mesh (EditableMesh, vertices clustered in XZ): a palm trunk leans (cluster width ~1.3-2.3), a broad
	tree's trunk is upright, exactly 2.2 wide and 0.45 h tall; the limb ends are tiny separate clusters (skipped).
	KTL + KTW go to the backup; each palm becomes CocoPalm(T) with its trunk top at the old one's, each broad tree the
	rain tree (RainTree.luau's model) h tall, in a Folder "Trees" next to "Meshes". ]]
P.RAIN = { model = 125285857865594, atlas = "rbxassetid://127614795774772",
	size = Vector3.new(51.97, 37.55, 51.66), centre = Vector3.new(-0.27, 18.78, -1.01) }
P.TOP = { CocoPalm = 1.30, CocoPalmT = 1.23 } -- palm height / trunk-top height of the meshes

function P.scanTrunks(ktw: MeshPart)
	local em = game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri(ktw.MeshId))
	local pts = {}
	for _, v in em:GetVertices() do
		table.insert(pts, ktw.CFrame * em:GetPosition(v))
	end
	local parent = {}
	for i = 1, #pts do
		parent[i] = i
	end
	local function root(i)
		while parent[i] ~= i do
			parent[i] = parent[parent[i]]
			i = parent[i]
		end
		return i
	end
	local C = 3.2
	local grid = {}
	for i, q in pts do
		local k = math.floor(q.X / C) .. "," .. math.floor(q.Z / C)
		grid[k] = grid[k] or {}
		table.insert(grid[k], i)
	end
	for i, q in pts do
		local gx, gz = math.floor(q.X / C), math.floor(q.Z / C)
		for dx = -1, 1 do
			for dz = -1, 1 do
				for _, j in grid[(gx + dx) .. "," .. (gz + dz)] or {} do
					local r = pts[j] - q
					if j > i and r.X * r.X + r.Z * r.Z < C * C then
						local a, b = root(i), root(j)
						if a ~= b then
							parent[a] = b
						end
					end
				end
			end
		end
	end
	local cl = {}
	for i, q in pts do
		local r = root(i)
		cl[r] = cl[r] or {}
		table.insert(cl[r], q)
	end
	local out = {}
	for _, l in cl do
		local mn, mx = Vector3.one * 1e9, -Vector3.one * 1e9
		for _, q in l do
			mn, mx = mn:Min(q), mx:Max(q)
		end
		local s, n = Vector3.zero, 0
		for _, q in l do
			if q.Y < mn.Y + 0.5 then
				s += q
				n += 1
			end
		end
		local ground = mn.Y + 2 -- the trunk tubes start 2 studs under the ground
		local h, w = mx.Y - ground, math.max(mx.X - mn.X, mx.Z - mn.Z)
		local foot = Vector3.new(s.X / n, ground, s.Z / n)
		if h > 5 then
			local tree = math.abs(w - 2.2) < 0.03 and h < 25
			table.insert(out, { kind = if tree then "tree" else "palm", foot = foot, h = if tree then h / 0.45 else h })
		end
	end
	return out
end

function P.landmarks()
	local b = sub(backup(), "Landmarks")
	local rain
	local msg = {}
	for _, lm in workspace.Yangon1to1.Landmarks:GetChildren() do
		local meshes = lm:FindFirstChild("Meshes")
		local ktw, ktl = meshes and meshes:FindFirstChild("KTW"), meshes and meshes:FindFirstChild("KTL")
		if ktw and ktl and not lm:FindFirstChild("Trees") then
			local folder = Instance.new("Folder")
			folder.Name = "Trees"
			local np, nt = 0, 0
			for _, t in P.scanTrunks(ktw) do
				local yaw = CFrame.Angles(0, (t.foot.X * 0.37 + t.foot.Z * 0.11) % (2 * math.pi), 0)
				local frame = CFrame.new(t.foot) * yaw
				local m = Instance.new("Model")
				local q
				if t.kind == "palm" then
					local kind = if t.h > 26 then "CocoPalmT" else "CocoPalm"
					local f
					q, f = P.part(kind, t.h * P.TOP[kind])
					q.CFrame = frame * CFrame.new(P.MESH[kind].centre * f)
					m.Name = "Palm"
					np += 1
				else
					rain = rain or game:GetService("InsertService"):LoadAsset(P.RAIN.model):FindFirstChild("RainTree", true)
					local f = t.h / P.RAIN.size.Y
					q = rain:Clone()
					q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, true
					q.Material, q.Color = Enum.Material.Plastic, Color3.new(1, 1, 1)
					q.Size = P.RAIN.size * f
					q.CFrame = frame * CFrame.new(P.RAIN.centre * f)
					local sa = Instance.new("SurfaceAppearance")
					sa.ColorMap, sa.RoughnessMap, sa.AlphaMode = P.RAIN.atlas, P.ROUGH, Enum.AlphaMode.Transparency
					sa.Parent = q
					m.Name = "RainTree"
					nt += 1
				end
				q.Name = "Tree"
				q.Parent = m
				m.WorldPivot = frame
				m.Parent = folder
			end
			local home = Instance.new("Folder")
			home.Name = lm.Name
			local ov = Instance.new("ObjectValue") -- where KTW / KTL go back to (P.undo)
			ov.Name = "Home"
			ov.Value = meshes
			ov.Parent = home
			home.Parent = b
			ktw.Parent, ktl.Parent = home, home
			folder.Parent = lm
			table.insert(msg, string.format("%s %d palms %d trees", lm.Name, np, nt))
		end
	end
	return table.concat(msg, ", ")
end

function P.undo()
	local b = SS:FindFirstChild(P.BACKUP)
	if not b then
		return "no backup"
	end
	if b:FindFirstChild("Landmarks") then
		for _, home in b.Landmarks:GetChildren() do
			local meshes = home.Home.Value
			if meshes then
				for _, q in home:GetChildren() do
					if q:IsA("BasePart") then
						q.Parent = meshes
					end
				end
				local trees = meshes.Parent:FindFirstChild("Trees")
				if trees then
					trees:Destroy()
				end
			end
			home:Destroy()
		end
	end
	local T = RS.YgnKit.Templates
	for _, n in { "OKA_op1", "OKA_op2" } do
		local q = T:FindFirstChild(n)
		if q then
			q:Destroy()
		end
	end
	if b:FindFirstChild("Templates") then
		for _, q in b.Templates:GetChildren() do
			if q.Name == "ToddyPalm" then
				local cur = RS.RoadsideKit:FindFirstChild("ToddyPalm")
				if cur then
					cur:Destroy()
				end
				q.Parent = RS.RoadsideKit
			else
				q.Parent = T
			end
		end
	end
	local n = 0
	local all = workspace:GetDescendants()
	for _, r in { "GreenEdgeKit", "MonacoKit", "DealerBody", "DealerBodyCompact" } do
		local root = SS:FindFirstChild(r)
		if root then
			for _, d in root:GetDescendants() do
				table.insert(all, d)
			end
		end
	end
	for _, d in all do
		if d:IsA("Model") then
			local ov = d:FindFirstChild("Old")
			if ov and ov:IsA("ObjectValue") and ov.Value and ov.Value.Parent and ov.Value:IsDescendantOf(b) then
				ov.Value.Parent = d.Parent
				d:Destroy()
				n += 1
			end
		end
	end
	return "undone, placed back " .. n
end

return P
