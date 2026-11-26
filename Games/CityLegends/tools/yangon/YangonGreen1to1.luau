--[[
	YangonGreen1to1 (2026-11-16, P1 greenery and ground cover): puts tools/yangon/city/green_1to1.py's output into Studio.

	The holding Folder (GreenHolding_<tag>, from imports/sync/ygn1to1_green/green_<tag>.rbxmx) carries:
	  Data_<tag>G      kit_pack tile strings of the trees, palms, banana clumps, hedges, bougainvillea and shrubs: moved
	                   to ReplicatedStorage.YgnKit, built on each client near the camera by client/YangonKitStream
	                   (the same streamer as the building detail: templates KIND_<pid> in YgnKit.Templates)
	  Ground_<n>       "tx tz y0 y1 rle" per 256-stud terrain tile: the ground material of every 4-stud column
	  Far_<n>          "pid x y z sx sy sz yaw tile": cheap far looks of the big crowns (in the place, attribute T so the
	                   streamer hides them where it has built the real trees)

	local G = require(ServerStorage.ClaudeTools.YangonGreen1to1:Clone())
	G.variants()                         -- MaterialVariant YgnFoliage (a copy of YgnGrassLawn for leaves)
	G.templates(kitHolding)              -- tree kit MeshParts (tree_kit.py's .glb, inserted) -> YgnKit.Templates
	G.terrainLook()                      -- base-material overrides of the Ygn ground set + terrain colours
	G.spawn("paint", function() return G.paint(holding) end)   -- terrain materials (resumable, ~1 tile a frame)
	G.far(holding)                       -- Workspace.Yangon1to1.Green.Far
	G.data(holding)                      -- moves Data_<tag>G into ReplicatedStorage.YgnKit
	G.status()
	Paint is reversible only by running it again with other data (it keeps the occupancies, changes only materials
	in GROUND_SET).
]]

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local G = {}

local MAT = {
	L = Enum.Material.Grass,
	D = Enum.Material.LeafyGrass,
	P = Enum.Material.Ground,
	E = Enum.Material.Salt,
	G = Enum.Material.Pebble,
	M = Enum.Material.Mud,
	C = Enum.Material.Concrete,
	S = Enum.Material.Pavement,
}
-- terrain materials the painter may replace (land only: water, sand lake beds and rock stay)
local GROUND_SET = {
	[Enum.Material.Grass] = true,
	[Enum.Material.LeafyGrass] = true,
	[Enum.Material.Ground] = true,
	[Enum.Material.Salt] = true,
	[Enum.Material.Pebble] = true,
	[Enum.Material.Mud] = true,
	[Enum.Material.Concrete] = true,
	[Enum.Material.Pavement] = true,
}
G.TERRAIN = {
	Grass = "YgnGrassLawn",
	LeafyGrass = "YgnGrassDry",
	Ground = "YgnDirtPacked",
	Mud = "YgnMudEdge",
	Pebble = "YgnGravel",
	Salt = "YgnEarthRed",
}
-- terrain-only colours (Terrain:SetMaterialColor touches no part). They TINT the overriding MaterialVariant's map
-- (16 Nov: Roblox's default Ground colour 132,114,86 turned YgnDirtPacked orange-brown and Grass 106,127,63 made the
-- lawn near-black green), so the variant materials get near-white tints and the maps carry the colour. Salt can't be
-- coloured ("Invalid terrain material").
G.TERRAIN_COLOR = {
	Concrete = Color3.fromRGB(150, 146, 136),
	Pavement = Color3.fromRGB(164, 158, 146),
	Ground = Color3.fromRGB(228, 222, 214),
	Grass = Color3.fromRGB(205, 218, 195),
	LeafyGrass = Color3.fromRGB(226, 220, 204),
	Pebble = Color3.fromRGB(226, 226, 226),
	Mud = Color3.fromRGB(215, 210, 205),
}

local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end

local function setStatus(k, v)
	workspace:SetAttribute("Green_" .. k, v)
end

function G.spawn(name: string, fn)
	setStatus(name, "running")
	task.spawn(function()
		local ok, res = pcall(fn)
		setStatus(name, if ok then ("done " .. tostring(res)) else ("ERROR " .. tostring(res)))
	end)
	return "started " .. name
end

function G.status()
	local out = {}
	for k, v in workspace:GetAttributes() do
		if string.sub(k, 1, 6) == "Green_" then
			table.insert(out, k .. " = " .. tostring(v))
		end
	end
	table.sort(out)
	return table.concat(out, "\n")
end

-- leaves: a copy of the lawn texture tiled a little larger; vertex colours of the kit tint it per tree
function G.variants()
	local made = {}
	local src = MaterialService:FindFirstChild("YgnGrassLawn")
	if src and not MaterialService:FindFirstChild("YgnFoliage") then
		local v = src:Clone()
		v.Name = "YgnFoliage"
		v.StudsPerTile = 7
		v.Parent = MaterialService
		table.insert(made, "YgnFoliage")
	end
	return table.concat(made, ",")
end

-- names from glb.code: KIND_pid_cx_cy_cz_sx_sy_sz in hundredths, "n" = minus
local function num(s)
	if string.sub(s, 1, 1) == "n" then
		return -tonumber(string.sub(s, 2)) / 100
	end
	return tonumber(s) / 100
end
function G.parse(name: string)
	name = string.gsub(name, "_Node$", "")
	local kind, pid, a, b, c, d, e, f =
		string.match(name, "^(%u+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not kind then
		return nil
	end
	return kind, pid, Vector3.new(num(a), num(b), num(c)), Vector3.new(num(d), num(e), num(f))
end

local LOOK = {
	TRC = { Enum.Material.Grass, "YgnFoliage", Color3.new(1, 1, 1), true },
	TRB = { Enum.Material.Wood, "YgnBark", Color3.fromRGB(235, 225, 215), true },
	TRF = { Enum.Material.Fabric, "", Color3.new(1, 1, 1), true },
	TFR = { Enum.Material.Grass, "YgnFoliage", Color3.new(1, 1, 1), false },
	TFP = { Enum.Material.Grass, "YgnFoliage", Color3.new(1, 1, 1), false },
}
G.LOOK = LOOK

function G.templates(holding: Instance, store: Instance?)
	store = store or ReplicatedStorage.YgnKit.Templates
	local n = 0
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, pid, c, size = G.parse(d.Name)
			if not kind and d.Parent then
				kind, pid, c, size = G.parse(d.Parent.Name)
			end
			if kind and LOOK[kind] then
				local name = kind .. "_" .. pid
				local old = store:FindFirstChild(name)
				if old then
					old:Destroy()
				end
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = name
				q.Size = size
				q.TextureID = ""
				local lk = LOOK[kind]
				q.Material = lk[1]
				q.MaterialVariant = lk[2]
				q.Color = lk[3]
				q.CastShadow = lk[4]
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q:SetAttribute("C", c)
				q:SetAttribute("S", size)
				q.Parent = store
				pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				n += 1
				if n % 5 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

-- the old map's tree kit (ServerStorage.YangonData.GreenKit: Monaco Tree / Palm / PalmA copies) as streamer templates
-- (owner, 16 Nov: "the trees are so ugly ... the old map vibe was better"). Record origin = the foot of the trunk;
-- each piece keeps its own mesh, texture, material and colour; attribute R = its turn in the model (YangonKitData
-- applies it). Scale 1 = the model as it is (Tree 18.3 m across, Palm 12.2 m and PalmA 16.3 m tall at 3 studs a metre).
G.OLD = { Tree = "ot1", Palm = "op1", PalmA = "op2" }
function G.oldTemplates(kit: Instance?, store: Instance?)
	kit = kit or game:GetService("ServerStorage").YangonData.GreenKit
	store = store or ReplicatedStorage.YgnKit.Templates
	local n = 0
	for mname, pid in G.OLD do
		local m = kit:FindFirstChild(mname)
		if m then
			local cf, size = m:GetBoundingBox()
			-- the trunk: the tallest-thin piece (Trunk, or the palm's textured stem); its foot is the origin
			local trunk
			for _, d in m:GetDescendants() do
				if d:IsA("MeshPart") and (d.Name == "Trunk" or d.TextureID == "rbxassetid://10562881532") then
					trunk = d
				end
			end
			local base = trunk and trunk.Position or cf.Position
			local origin = Vector3.new(base.X, cf.Position.Y - size.Y / 2, base.Z)
			local k = 0
			for _, d in m:GetDescendants() do
				if d:IsA("MeshPart") then
					k += 1
					local name = "OK" .. string.char(64 + k) .. "_" .. pid
					local old = store:FindFirstChild(name)
					if old then
						old:Destroy()
					end
					local q = d:Clone()
					q.Name = name
					q.Anchored = true
					q.CanCollide = false
					q.CanQuery = false
					q.CanTouch = false
					q.CastShadow = true
					q:SetAttribute("C", d.Position - origin)
					q:SetAttribute("S", d.Size)
					q:SetAttribute("R", d.CFrame.Rotation)
					q.Parent = store
					pcall(function()
						q.CollisionFidelity = Enum.CollisionFidelity.Box
					end)
					n += 1
				end
			end
		end
	end
	return n
end

function G.terrainLook(undo: boolean?)
	local out = {}
	for matName, variant in G.TERRAIN do
		local mat = Enum.Material[matName]
		local key = "YgnOld_" .. matName
		if undo then
			local old = MaterialService:GetAttribute(key)
			if old ~= nil then
				MaterialService:SetBaseMaterialOverride(mat, old)
				MaterialService:SetAttribute(key, nil)
			end
		else
			if MaterialService:GetAttribute(key) == nil then
				MaterialService:SetAttribute(key, MaterialService:GetBaseMaterialOverride(mat))
			end
			if MaterialService:FindFirstChild(variant) then
				MaterialService:SetBaseMaterialOverride(mat, variant)
				table.insert(out, matName .. "->" .. variant)
			end
		end
	end
	local T = workspace.Terrain
	for matName, colr in G.TERRAIN_COLOR do
		local mat = Enum.Material[matName]
		local key = "YgnOldColor_" .. matName
		pcall(function()
			if undo then
				local old = T:GetAttribute(key)
				if old then
					T:SetMaterialColor(mat, old)
					T:SetAttribute(key, nil)
				end
			else
				if T:GetAttribute(key) == nil then
					T:SetAttribute(key, T:GetMaterialColor(mat))
				end
				T:SetMaterialColor(mat, colr)
			end
		end)
	end
	return table.concat(out, " ")
end

local function pages(holding: Instance, prefix: string)
	local list = {}
	for _, v in holding:GetChildren() do
		local n = v:IsA("StringValue") and tonumber(string.match(v.Name, "^" .. prefix .. "_(%d+)$"))
		if n then
			list[n] = v.Value
		end
	end
	return list
end

-- terrain ground materials, tile by tile (resumable: workspace attribute Green_paintDone counts lines done)
function G.paint(holding: Instance, from: number?)
	local T = workspace.Terrain
	local done = 0
	local changed = 0
	local start = from or 0
	local k = 0
	for _, text in pages(holding, "Ground") do
		for line in string.gmatch(text, "[^\n]+") do
			k += 1
			if k > start then
				local tx, tz, y0, y1, rle = string.match(line, "^(%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+) (%S+)$")
				tx, tz, y0, y1 = tonumber(tx), tonumber(tz), tonumber(y0), tonumber(y1)
				local x0, z0 = tx * 256, tz * 256
				local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x0 + 256, y1, z0 + 256))
				local mats, occ = T:ReadVoxels(region, 4)
				local ny = mats.Size.Y
				local idx = 0
				for p = 1, #rle, 2 do
					local ch = string.sub(rle, p, p)
					local run = VAL[string.byte(rle, p + 1)] + 1
					local m = MAT[ch]
					for q = idx, idx + run - 1 do
						if m then
							local ix = q // 64 + 1
							local iz = q % 64 + 1
							local mx = mats[ix]
							for iy = 1, ny do
								local cur = mx[iy][iz]
								if GROUND_SET[cur] and cur ~= m then
									mx[iy][iz] = m
									changed += 1
								end
							end
						end
					end
					idx += run
				end
				T:WriteVoxels(region, 4, mats, occ)
				done += 1
				workspace:SetAttribute("Green_paintDone", k)
				if done % 3 == 0 then
					task.wait()
				end
			end
		end
	end
	return string.format("%d tiles, %d voxels changed", done, changed)
end

-- far looks of the big crowns: per 1536-stud cell Models under Workspace.Yangon1to1.Green.Far
function G.far(holding: Instance, store: Instance?)
	store = store or ReplicatedStorage.YgnKit.Templates
	local root = workspace.Yangon1to1
	local green = root:FindFirstChild("Green") or Instance.new("Folder")
	green.Name = "Green"
	green.Parent = root
	local far = green:FindFirstChild("Far")
	if far then
		far:Destroy()
	end
	far = Instance.new("Folder")
	far.Name = "Far"
	far.Parent = green
	local tpl = { ff1 = store:FindFirstChild("TFR_ff1"), fp1 = store:FindFirstChild("TFP_fp1") }
	local cells = {}
	local n = 0
	local pending = {}
	for _, text in pages(holding, "Far") do
		for line in string.gmatch(text, "[^\n]+") do
			local pid, x, y, z, sx, sy, sz, yaw, tile =
				string.match(line, "^(%w+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
			local t = tpl[pid]
			if t then
				x, y, z, sx, sy, sz, yaw = tonumber(x), tonumber(y), tonumber(z), tonumber(sx), tonumber(sy), tonumber(sz), tonumber(yaw)
				local S, C = t:GetAttribute("S"), t:GetAttribute("C")
				local kx, ky, kz = sx / S.X, sy / S.Y, sz / S.Z
				local q = t:Clone()
				q.Size = Vector3.new(sx, sy, sz)
				q.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0) * CFrame.new(C.X * kx, C.Y * ky, C.Z * kz)
				q.CastShadow = false
				q:SetAttribute("T", tile)
				local key = math.floor(x / 1536) .. "_" .. math.floor(z / 1536)
				local cell = cells[key]
				if not cell then
					cell = Instance.new("Model")
					cell.Name = "Cell_" .. key
					cells[key] = cell
					pending[cell] = {}
				end
				table.insert(pending[cell], q)
				n += 1
			end
		end
	end
	-- parent each cell's parts in small batches
	for cell, list in pending do
		cell.Parent = far
		for i, q in list do
			q.Parent = cell
			if i % 400 == 0 then
				task.wait()
			end
		end
		task.wait()
	end
	return n
end

-- Edit look of what a client builds near `centre` (the green data only; YangonKitPlace.preview does the buildings):
-- workspace._GreenPreview, far looks of those tiles hidden. G.unpreview() takes it down.
function G.preview(centre: Vector3, radius: number)
	local KD = require((ReplicatedStorage.Shared.YangonKitData :: ModuleScript):Clone())
	local root = ReplicatedStorage.YgnKit
	local T = KD.index(root.Templates)
	local out = workspace:FindFirstChild("_GreenPreview") or Instance.new("Folder")
	out.Name = "_GreenPreview"
	out.Parent = workspace
	local keys, n = {}, 0
	for _, f in root:GetChildren() do
		if f:IsA("Folder") and string.match(f.Name, "^Data_.+G$") then
			local meta = KD.meta(f)
			for _, v in f:GetChildren() do
				local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
				if i then
					local cx, cz = (tonumber(i) + 0.5) * meta.tile, (tonumber(j) + 0.5) * meta.tile
					if math.sqrt((cx - centre.X) ^ 2 + (cz - centre.Z) ^ 2) <= radius and not out:FindFirstChild(v.Name) then
						local tf = Instance.new("Folder")
						tf.Name = v.Name
						tf.Parent = out
						local job = KD.job(v.Value, tonumber(i), tonumber(j), meta, T, tf)
						while not job:step(400) do
							task.wait()
						end
						n += job.parts
						keys[v.Name] = true
					end
				end
			end
		end
	end
	local far = workspace.Yangon1to1:FindFirstChild("Green") and workspace.Yangon1to1.Green:FindFirstChild("Far")
	if far then
		for _, d in far:GetDescendants() do
			if d:IsA("BasePart") and keys[d:GetAttribute("T")] then
				d.Transparency = 1
				d:SetAttribute("PreviewHidden", true)
			end
		end
	end
	return n
end

function G.unpreview()
	local out = workspace:FindFirstChild("_GreenPreview")
	if out then
		out:Destroy()
	end
	local far = workspace.Yangon1to1:FindFirstChild("Green") and workspace.Yangon1to1.Green:FindFirstChild("Far")
	if far then
		for _, d in far:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("PreviewHidden") then
				d.Transparency = 0
				d:SetAttribute("PreviewHidden", nil)
			end
		end
	end
end

-- Inya Lake bund (Edge_<n>: "CODE x y z sx sy sz yaw"): concrete wall into the water, steel railing, 3 m walkway;
-- the ground under each walkway piece is cleared above it and filled with grass under it (no terrain through it)
G.EDGE_LOOK = {
	WALL = { Enum.Material.Concrete, "YgnConcreteBare", Color3.fromRGB(196, 192, 182) },
	WALK = { Enum.Material.Pavement, "YgnPavementSlabs", Color3.fromRGB(208, 204, 196) },
	RAIL = { Enum.Material.Metal, "YgnSteelPainted", Color3.fromRGB(226, 228, 222) },
	POST = { Enum.Material.Metal, "YgnSteelPainted", Color3.fromRGB(226, 228, 222) },
}
function G.edge(holding: Instance)
	local root = workspace.Yangon1to1
	local green = root:FindFirstChild("Green") or Instance.new("Folder")
	green.Name = "Green"
	green.Parent = root
	local old = green:FindFirstChild("LakeEdge")
	if old then
		old:Destroy()
	end
	local f = Instance.new("Model")
	f.Name = "LakeEdge"
	f.Parent = green
	local T = workspace.Terrain
	local n = 0
	for _, text in pages(holding, "Edge") do
		for line in string.gmatch(text, "[^\n]+") do
			local code, x, y, z, sx, sy, sz, yaw = string.match(line, "^(%u+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
			x, y, z, sx, sy, sz, yaw = tonumber(x), tonumber(y), tonumber(z), tonumber(sx), tonumber(sy), tonumber(sz), tonumber(yaw)
			local cf = CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
			if code == "WALK" then
				local top = y + sy / 2
				-- (4-stud voxels: clear from 3.5 under the top so no voxel layer ends level with the walkway; the 4-stud
				-- deep walkway hides the step to the grass under it)
				T:FillBlock(CFrame.new(x, top - 3.5 + 10, z) * CFrame.Angles(0, yaw, 0), Vector3.new(sx + 2, 20, sz + 2), Enum.Material.Air)
				T:FillBlock(CFrame.new(x, top - 3.6 - 3, z) * CFrame.Angles(0, yaw, 0), Vector3.new(sx + 1, 6, sz), Enum.Material.Grass)
			end
			local lk = G.EDGE_LOOK[code]
			local q = Instance.new("Part")
			q.Name = code
			q.Anchored = true
			q.Size = Vector3.new(sx, sy, sz)
			q.CFrame = cf
			q.Material = lk[1]
			q.MaterialVariant = if game:GetService("MaterialService"):FindFirstChild(lk[2]) then lk[2] else ""
			q.Color = lk[3]
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			q.CanCollide = code ~= "POST" -- the rails and wall stop a car / player at the water; posts are inside the rail line
			q.CastShadow = code ~= "POST"
			q.Parent = f
			n += 1
			if n % 60 == 0 then
				task.wait()
			end
		end
	end
	return n
end

-- far looks from the old map's tree kit (owner, 16 Nov: the round ff1 blobs read as ugly): only the big crowns
-- (MIN_FAR_M across and up), the same Tree mesh as near, no shadows; attribute T hides them where the streamer has
-- built the real trees. Palms have no far look (thin, lost in the haze).
G.MIN_FAR_M = 16
function G.farOld(holding: Instance, store: Instance?)
	store = store or ReplicatedStorage.YgnKit.Templates
	local root = workspace.Yangon1to1
	local green = root:FindFirstChild("Green") or Instance.new("Folder")
	green.Name = "Green"
	green.Parent = root
	local far = green:FindFirstChild("Far")
	if far then
		far:Destroy()
	end
	far = Instance.new("Folder")
	far.Name = "Far"
	far.Parent = green
	local pieces = {}
	for _, q in store:GetChildren() do
		if string.match(q.Name, "^OK%u_ot1$") then
			table.insert(pieces, q)
		end
	end
	-- (27 Nov) the rain tree has its own one-part far look (tools/yangon/RainTree.luau)
	if store:FindFirstChild("OKF_ot1far") then
		pieces = { store.OKF_ot1far }
	end
	local cells, n, k = {}, 0, 0
	for _, text in pages(holding, "Far") do
		for line in string.gmatch(text, "[^\n]+") do
			local pid, x, y, z, sx, _sy, _sz, yaw, tile =
				string.match(line, "^(%w+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
			local Dm = (tonumber(sx) or 0) / 0.92 / 3
			if pid == "ff1" and Dm >= G.MIN_FAR_M then
				local s = Dm / 18.3
				local at = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
				local cf = CFrame.new(at) * CFrame.Angles(0, tonumber(yaw), 0)
				local key = math.floor(at.X / 1536) .. "_" .. math.floor(at.Z / 1536)
				local cell = cells[key]
				if not cell then
					cell = Instance.new("Model")
					cell.Name = "Cell_" .. key
					cell.Parent = far
					cells[key] = cell
				end
				for _, q in pieces do
					local p = q:Clone()
					local C, S, R = q:GetAttribute("C"), q:GetAttribute("S"), q:GetAttribute("R")
					p.Size = S * s
					p.CFrame = cf * CFrame.new(C * s) * (R or CFrame.identity)
					p.CastShadow = false
					p:SetAttribute("T", tile)
					p.Parent = cell
					k += 1
				end
				n += 1
				if n % 150 == 0 then
					task.wait()
				end
			end
		end
	end
	return n .. " trees, " .. k .. " parts"
end

-- ===================================================================================== edges v3 (owner's pictures)
-- Cols_<n>: "x z top wet" a 4 x 4 terrain column: grass up to `top`, air above; wet = water from `top` up to the lake
G.LAKE = 40.5
function G.cols(holding: Instance)
	local T = workspace.Terrain
	local n = 0
	for _, text in pages(holding, "Cols") do
		for line in string.gmatch(text, "[^\n]+") do
			local x, z, top, wet = string.match(line, "^(%S+) (%S+) (%S+) (%d)$")
			x, z, top = tonumber(x), tonumber(z), tonumber(top)
			T:FillBlock(CFrame.new(x, top + 12, z), Vector3.new(4, 24, 4), Enum.Material.Air)
			if wet == "1" and top < G.LAKE then
				T:FillBlock(CFrame.new(x, (top + G.LAKE) / 2, z), Vector3.new(4, G.LAKE - top, 4), Enum.Material.Water)
			end
			T:FillBlock(CFrame.new(x, top - 5, z), Vector3.new(4, 10, 4), Enum.Material.Grass)
			n += 1
			if n % 150 == 0 then
				task.wait()
			end
		end
	end
	return n
end

G.EDGE_LOOK.BRAIL = { Enum.Material.Metal, "", Color3.fromRGB(26, 27, 28) }
G.EDGE_LOOK.BPOST = { Enum.Material.Metal, "", Color3.fromRGB(26, 27, 28) }

-- the small street furniture of the lake walk, built from parts (owner's picture 2): white square planter with a
-- flowering bush, green bin, small green bench shelter. Pivot = bottom middle, front -Z.
local function box(parent, size, cf, color, mat, name)
	local p = Instance.new("Part")
	p.Name = name or "P"
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
function G.makeFurniture(kit: Instance)
	local WHITE, GREEN, DARKG = Color3.fromRGB(236, 236, 230), Color3.fromRGB(46, 120, 62), Color3.fromRGB(30, 84, 44)
	local made = {}
	-- planter: 1.2 x 0.6 x 1.2 m white box, soil 0.05 m under its rim
	local pl = Instance.new("Model")
	pl.Name = "PLANTER"
	box(pl, Vector3.new(3.6, 1.8, 3.6), CFrame.new(0, 0.9, 0), WHITE, Enum.Material.Concrete, "Box")
	box(pl, Vector3.new(3.0, 0.2, 3.0), CFrame.new(0, 1.72, 0), Color3.fromRGB(70, 52, 40), Enum.Material.Ground, "Soil")
	pl.PrimaryPart = pl.Box
	-- bin: green cylinder 0.5 m across, 0.9 m tall, lid
	local bin = Instance.new("Model")
	bin.Name = "BIN"
	local c = box(bin, Vector3.new(2.7, 1.5, 1.5), CFrame.new(0, 1.35, 0) * CFrame.Angles(0, 0, math.rad(90)), GREEN, Enum.Material.SmoothPlastic, "Body")
	c.Shape = Enum.PartType.Cylinder
	local lid = box(bin, Vector3.new(0.25, 1.62, 1.62), CFrame.new(0, 2.82, 0) * CFrame.Angles(0, 0, math.rad(90)), DARKG, Enum.Material.SmoothPlastic, "Lid")
	lid.Shape = Enum.PartType.Cylinder
	bin.PrimaryPart = c
	-- shelter: 2.4 x 1.6 m, 2.4 m tall, four green posts, a green roof, a bench
	local sh = Instance.new("Model")
	sh.Name = "SHELTER"
	for _, q in { { -3.3, -2.1 }, { 3.3, -2.1 }, { -3.3, 2.1 }, { 3.3, 2.1 } } do
		box(sh, Vector3.new(0.3, 7.2, 0.3), CFrame.new(q[1], 3.6, q[2]), GREEN, Enum.Material.Metal, "Post")
	end
	box(sh, Vector3.new(8.0, 0.25, 5.6), CFrame.new(0, 7.35, 0) * CFrame.Angles(math.rad(6), 0, 0), GREEN, Enum.Material.Metal, "Roof")
	box(sh, Vector3.new(6.0, 0.3, 1.4), CFrame.new(0, 1.35, 0.9), Color3.fromRGB(150, 150, 146), Enum.Material.Concrete, "Seat")
	for _, x in { -2.6, 2.6 } do
		box(sh, Vector3.new(0.3, 1.2, 1.2), CFrame.new(x, 0.6, 0.9), Color3.fromRGB(150, 150, 146), Enum.Material.Concrete, "Leg")
	end
	box(sh, Vector3.new(7.6, 0.35, 5.2), CFrame.new(0, 0.175, 0), Color3.fromRGB(176, 174, 166), Enum.Material.Concrete, "Pad")
	sh.PrimaryPart = sh.Pad
	for _, m in { pl, bin, sh } do
		local old = kit:FindFirstChild(m.Name)
		if old then
			old:Destroy()
		end
		m.Parent = kit
		table.insert(made, m.Name)
	end
	return table.concat(made, ",")
end

-- Models_<n>: "NAME x y z yaw scale" (NAME = a Model in `kit`, pivot at its bottom middle) into Green.Edges
function G.models(holding: Instance, kit: Instance)
	local root = workspace.Yangon1to1.Green
	local f = root:FindFirstChild("Edges") or Instance.new("Folder")
	f.Name = "Edges"
	f.Parent = root
	local old = f:FindFirstChild("Props")
	if old then
		old:Destroy()
	end
	local props = Instance.new("Model")
	props.Name = "Props"
	props.Parent = f
	local n, miss = 0, {}
	for _, text in pages(holding, "Models") do
		for line in string.gmatch(text, "[^\n]+") do
			local name, x, y, z, yaw, s = string.match(line, "^(%u+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
			local t = kit:FindFirstChild(name)
			if t then
				local m = t:Clone()
				local sc = tonumber(s) or 1
				if sc ~= 1 then
					m:ScaleTo(m:GetScale() * sc)
				end
				-- the template's pivot is its bottom middle (set in G.prepKit)
				m:PivotTo(CFrame.new(tonumber(x), tonumber(y), tonumber(z)) * CFrame.Angles(0, tonumber(yaw), 0))
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanTouch = false
						if name ~= "SHELTER" and name ~= "BIN" and name ~= "PLANTER" then
							d.CanCollide = false
							d.CanQuery = false
						end
					end
				end
				m.Parent = props
				n += 1
				if n % 50 == 0 then
					task.wait()
				end
			else
				miss[name] = true
			end
		end
	end
	local ms = {}
	for k in miss do
		table.insert(ms, k)
	end
	return n .. " models" .. (#ms > 0 and (" missing " .. table.concat(ms, ",")) or "")
end

-- a store model as a kit template: scripts and sounds out, pivot at the bottom middle of its trunk / box, `height`
-- studs tall (real size: rain-tree-like bank trees 12 m, fan palms 9 m, bushes 1.4 m)
function G.prepKit(model: Model, name: string, height: number, kit: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt")
			or d:IsA("BillboardGui") or d:IsA("ScreenGui") then
			d:Destroy()
		end
	end
	local cf, size = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * (height / size.Y))
	cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position.X, cf.Position.Y - size.Y / 2, cf.Position.Z)
	model.Name = name
	local old = kit:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	model.Parent = kit
	return size
end

-- a placed bund (WALL / RAIL / POST + WALK parts, edges v2) turned into the picture's natural bank: grass sloping from
-- the walkway's water edge down under the water, wall and railing taken away (P2's north shore)
function G.wallToBank(folder: Instance)
	local T = workspace.Terrain
	local walks = {}
	for _, q in folder:GetChildren() do
		if q.Name == "WALK" then
			table.insert(walks, q)
		end
	end
	local n = 0
	for _, w in folder:GetChildren() do
		if w.Name == "WALL" then
			-- landward = toward the nearest walkway piece
			local best, bd = nil, math.huge
			for _, k in walks do
				local d = (k.Position - w.Position).Magnitude
				if d < bd then
					best, bd = k, d
				end
			end
			if best then
				local cf = w.CFrame
				local nrm = cf.LookVector -- local -Z / +Z across the wall
				local toWalk = best.Position - w.Position
				if nrm:Dot(toWalk) < 0 then
					nrm = -nrm
				end
				nrm = Vector3.new(nrm.X, 0, nrm.Z).Unit
				local along = cf.RightVector
				local top = best.Position.Y + best.Size.Y / 2
				local L = w.Size.X
				for a = -L / 2, L / 2, 2 do
					for off = -16, 0, 2 do
						local t = (off + 16) / 16
						local h = (G.LAKE - 2.5) + t * (top - 0.4 - (G.LAKE - 2.5))
						local p = w.Position + along * a + nrm * off
						T:FillBlock(CFrame.new(p.X, h + 12, p.Z), Vector3.new(3, 24, 3), Enum.Material.Air)
						if h < G.LAKE then
							T:FillBlock(CFrame.new(p.X, (h + G.LAKE) / 2, p.Z), Vector3.new(3, G.LAKE - h, 3), Enum.Material.Water)
						end
						T:FillBlock(CFrame.new(p.X, h - 5, p.Z), Vector3.new(3, 10, 3), Enum.Material.Grass)
					end
				end
				n += 1
				if n % 4 == 0 then
					task.wait()
				end
			end
		end
	end
	local gone = 0
	for _, q in folder:GetChildren() do
		if q.Name == "WALL" or q.Name == "RAIL" or q.Name == "POST" then
			q:Destroy()
			gone += 1
		end
	end
	return n .. " wall pieces banked, " .. gone .. " parts removed"
end

-- owner's picture 1 (16 Nov: "the grass is so green"): terrain Grass colour, bright fresh green under the Riviera
-- light (applies to all terrain grass; the old colour is kept on Terrain attribute YgnOldColor_Grass)
G.GRASS = Color3.fromRGB(88, 158, 40)
function G.grassColour(c: Color3?, undo: boolean?)
	local T = workspace.Terrain
	if undo then
		local o = T:GetAttribute("YgnOldColor_Grass")
		if o then
			T:SetMaterialColor(Enum.Material.Grass, o)
			T:SetAttribute("YgnOldColor_Grass", nil)
		end
		return
	end
	if T:GetAttribute("YgnOldColor_Grass") == nil then
		T:SetAttribute("YgnOldColor_Grass", T:GetMaterialColor(Enum.Material.Grass))
	end
	T:SetMaterialColor(Enum.Material.Grass, c or G.GRASS)
end

-- Inya's shallow bed: Sand reads white through the water near the shores; paint it Mud in a box (x0, z0, x1, z1)
function G.lakeBed(x0: number, z0: number, x1: number, z1: number, y0: number?, y1: number?)
	local T = workspace.Terrain
	y0 = y0 or 24
	y1 = y1 or 44
	local n = 0
	for x = x0, x1, 256 do
		for z = z0, z1, 256 do
			local r = Region3.new(Vector3.new(x, y0, z), Vector3.new(math.min(x + 256, x1), y1, math.min(z + 256, z1))):ExpandToGrid(4)
			T:ReplaceMaterial(r, 4, Enum.Material.Sand, Enum.Material.Mud)
			n += 1
			if n % 10 == 0 then
				task.wait()
			end
		end
	end
	return n
end

-- (17 Nov, owner: grey "concrete blobs" on the grass) repaint every non-grass ground voxel to Grass in a box
-- (x0, z0, x1, z1), tile by tile. Kept: road beds (a part within 12 studs over the column's top), columns with water
-- or mud (lake / river edges), and the columns in keep: text lines "tx tz start+len,..." (runs of column index
-- ix * 64 + iz in that 256-stud tile; terrain.py's quay edge and piers, code 5, e.g. terrain_P3/keep_quay.txt). Real
-- paved areas are part slabs (places_1to1), never terrain. Resumable: from = tiles to skip; progress on workspace
-- attribute Green_unblob.
G.UNBLOB = {
	[Enum.Material.Concrete] = true, [Enum.Material.Pavement] = true, [Enum.Material.Asphalt] = true,
	[Enum.Material.Slate] = true, [Enum.Material.Ground] = true, [Enum.Material.Pebble] = true,
	[Enum.Material.Salt] = true, [Enum.Material.Cobblestone] = true, [Enum.Material.LeafyGrass] = true,
}
function G.unblob(x0: number, z0: number, x1: number, z1: number, keep: string?, y0: number?, y1: number?, from: number?)
	local T = workspace.Terrain
	y0, y1 = y0 or -40, y1 or 160
	local kept0 = {}
	for tx, tz, runs in string.gmatch(keep or "", "(%-?%d+) (%-?%d+) (%S+)") do
		local set = {}
		for a, n in string.gmatch(runs, "(%d+)%+(%d+)") do
			for q = tonumber(a), tonumber(a) + tonumber(n) - 1 do
				set[q] = true
			end
		end
		kept0[tx .. " " .. tz] = set
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { T }
	local k, cols, kept = 0, 0, 0
	for tx = math.floor(x0 / 256) * 256, x1 - 1, 256 do
		for tz = math.floor(z0 / 256) * 256, z1 - 1, 256 do
			k += 1
			if k > (from or 0) then
				local region = Region3.new(Vector3.new(tx, y0, tz), Vector3.new(tx + 256, y1, tz + 256))
				local mats, occ = T:ReadVoxels(region, 4)
				local ny, dirty = mats.Size.Y, false
				local ks = kept0[tx .. " " .. tz] or {}
				for ix = 1, 64 do
					local mx, ox = mats[ix], occ[ix]
					for iz = 1, 64 do
						local bad, top, skip = false, nil, false
						for iy = 1, ny do
							local m = mx[iy][iz]
							if m == Enum.Material.Water or m == Enum.Material.Mud then
								skip = true
								break
							end
							bad = bad or G.UNBLOB[m] == true
							if ox[iy][iz] > 0 then
								top = iy
							end
						end
						if bad and not skip and top and not ks[(ix - 1) * 64 + iz - 1] then
							local cx, cz = tx + ix * 4 - 2, tz + iz * 4 - 2
							local ty = y0 + top * 4
							if workspace:Raycast(Vector3.new(cx, ty + 12, cz), Vector3.new(0, -16, 0), rp) then
								kept += 1
							else
								for iy = 1, ny do
									if G.UNBLOB[mx[iy][iz]] then
										mx[iy][iz] = Enum.Material.Grass
									end
								end
								cols += 1
								dirty = true
							end
						end
					end
				end
				if dirty then
					T:WriteVoxels(region, 4, mats, occ)
				end
				workspace:SetAttribute("Green_unblob", k)
				task.wait()
			end
		end
	end
	return string.format("%d tiles, %d columns to grass, %d kept under roads", k, cols, kept)
end

function G.data(holding: Instance)
	local kit = ReplicatedStorage:FindFirstChild("YgnKit")
	local moved = {}
	for _, f in holding:GetChildren() do
		if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
			local old = kit:FindFirstChild(f.Name)
			if old then
				old:Destroy()
			end
			f.Parent = kit
			table.insert(moved, f.Name .. " " .. #f:GetChildren())
		end
	end
	return table.concat(moved, ", ")
end

return G
