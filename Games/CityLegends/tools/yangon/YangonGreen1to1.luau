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
-- terrain-only colours of the two paved materials (Terrain:SetMaterialColor touches no part)
G.TERRAIN_COLOR = {
	Concrete = Color3.fromRGB(150, 146, 136),
	Pavement = Color3.fromRGB(164, 158, 146),
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
