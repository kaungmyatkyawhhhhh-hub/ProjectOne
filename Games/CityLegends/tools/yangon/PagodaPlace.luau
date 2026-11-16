--!nocheck
-- Pagoda generator, step 4 (2026-11-16): places copies of the stupa kit (tools/yangon/city/pagoda_kit.py, asset
-- 129014360989342, kept in ServerStorage.YgnPagodaKit) from rows made by pagodas_plan.py (build/pagodas/PagodaData.txt).
-- Run in Edit by execute_luau: local P = loadstring-free: paste this file's body with DATA set, then P.place(DATA).
-- Row: id|name|x|z|groundY(GLO-30)|W studs|H studs|shape sq/oct/rd|yaw deg|class|scheme|inP1
-- Each pagoda: Workspace.Yangon1to1.Pagodas.<id> (Model: 4 MeshParts BASE / BELL / TOP / HTI + 2 invisible collision parts),
-- ground from a raycast to Terrain (min of 5 hits under the base), else the GLO-30 height and a flat plate <id>_TEMP.
local P = {}
local KIT_ID = 129014360989342
local H_RATIO = 1.9
local REF = { XS = 9, S = 24, M = 54, L = 105, XL = 180 }
-- piece centre at the class reference size (studs, base centre on the ground = 0), from build/pagodas/pagoda_kit.json
P.CENTRE = {PG_XS_BASE_sq = {-0.000, 1.935, -0.000}, PG_XS_BASE_oct = {-0.000, 1.935, 0.000}, PG_XS_BASE_rd = {0.000, 1.935, 0.000}, PG_XS_BELL = {0.000, 7.650, 0.000}, PG_XS_TOP = {0.000, 12.465, 0.000}, PG_XS_HTI = {0.000, 15.525, 0.000}, PG_S_BASE_sq = {-0.000, 5.160, -0.000}, PG_S_BASE_oct = {-0.000, 5.160, 0.000}, PG_S_BASE_rd = {0.000, 5.160, 0.000}, PG_S_BELL = {0.000, 20.400, 0.000}, PG_S_TOP = {0.000, 33.240, 0.000}, PG_S_HTI = {0.000, 41.400, 0.000}, PG_M_BASE_sq = {-0.000, 11.610, -0.000}, PG_M_BASE_oct = {-0.000, 11.610, 0.000}, PG_M_BASE_rd = {0.000, 11.610, 0.000}, PG_M_BELL = {0.000, 45.900, 0.000}, PG_M_TOP = {0.000, 74.790, 0.000}, PG_M_HTI = {0.000, 93.150, 0.000}, PG_L_BASE_sq = {-0.000, 22.575, -0.000}, PG_L_BASE_oct = {-0.000, 22.575, 0.000}, PG_L_BASE_rd = {0.000, 22.575, 0.000}, PG_L_BELL = {0.000, 89.250, 0.000}, PG_L_TOP = {0.135, 145.425, 0.000}, PG_L_HTI = {0.000, 181.125, 0.000}, PG_XL_BASE_sq = {-0.000, 38.700, -0.000}, PG_XL_BASE_oct = {-0.000, 38.700, 0.000}, PG_XL_BASE_rd = {0.000, 38.700, 0.000}, PG_XL_BELL = {0.000, 153.000, 0.000}, PG_XL_TOP = {0.000, 249.300, 0.000}, PG_XL_HTI = {0.000, 310.500, 0.000}}
local GOLD = { mat = Enum.Material.Metal, var = "YgnGoldLeaf", col = Color3.fromRGB(226, 222, 245) }
local WHITE = { mat = Enum.Material.SmoothPlastic, col = Color3.fromRGB(255, 255, 250) }
-- mirror glass mosaic (Kaba Aye look pass v2: Foil, no variant, Reflectance 0.2)
local MOSAIC = { mat = Enum.Material.Foil, col = Color3.fromRGB(150, 160, 140), refl = 0.2 }
local SCHEME = {
	gold = { BASE = GOLD, BELL = GOLD, TOP = GOLD, HTI = GOLD },
	whitegold = { BASE = WHITE, BELL = GOLD, TOP = GOLD, HTI = GOLD },
	whitetop = { BASE = WHITE, BELL = WHITE, TOP = GOLD, HTI = GOLD },
	white = { BASE = WHITE, BELL = WHITE, TOP = WHITE, HTI = GOLD },
	mosaic = { BASE = MOSAIC, BELL = MOSAIC, TOP = MOSAIC, HTI = GOLD },
}

function P.kit()
	local ss = game:GetService("ServerStorage")
	local kit = ss:FindFirstChild("YgnPagodaKit")
	if kit and #kit:GetChildren() >= 30 then
		return kit
	end
	if kit then kit:Destroy() end
	local m = game:GetService("InsertService"):LoadAsset(KIT_ID)
	kit = Instance.new("Folder")
	kit.Name = "YgnPagodaKit"
	for _, d in m:GetDescendants() do
		if d:IsA("MeshPart") then
			local nm = d.Name:gsub("_Node$", "")
			d.Name = nm
			d.Anchored = true
			d.Parent = kit
		end
	end
	m:Destroy()
	kit:SetAttribute("AssetId", KIT_ID)
	kit.Parent = ss
	return kit
end

local function groundAt(x, z, r, glo)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local lo, n = math.huge, 0
	for _, o in { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local hit = workspace:Raycast(Vector3.new(x + o[1] * r, glo + 400, z + o[2] * r), Vector3.new(0, -900, 0), rp)
		if hit and math.abs(hit.Position.Y - glo) < 60 then
			lo = math.min(lo, hit.Position.Y)
			n += 1
		end
	end
	if n >= 4 then return lo, true end
	return glo, false
end

function P.placeOne(kit, folder, row)
	local f = string.split(row, "|")
	local id, name = f[1], f[2]
	local x, z, glo = tonumber(f[3]), tonumber(f[4]), tonumber(f[5])
	local W, H = tonumber(f[6]), tonumber(f[7])
	local shape, yaw, cls, scheme = f[8], math.rad(tonumber(f[9])), f[10], f[11]
	local old = folder:FindFirstChild(id)
	if old then old:Destroy() end
	local kw = W / REF[cls]
	local ky = H / (H_RATIO * REF[cls])
	local gy, onTerrain = groundAt(x, z, W * 0.5, glo)
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("Name", name)
	model:SetAttribute("Class", cls)
	model:SetAttribute("Scheme", scheme)
	model:SetAttribute("Shape", shape)
	model:SetAttribute("Ground", onTerrain and "terrain" or "GLO-30 + temp plate")
	local base = CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0)
	local sch = SCHEME[scheme] or SCHEME.gold
	for _, piece in { "BASE_" .. shape, "BELL", "TOP", "HTI" } do
		local nm = "PG_" .. cls .. "_" .. piece
		local src = kit:FindFirstChild(nm)
		local c = P.CENTRE[nm]
		local p = src:Clone()
		p.Size = Vector3.new(src.Size.X * kw, src.Size.Y * ky, src.Size.Z * kw)
		p.CFrame = base * CFrame.new(c[1] * kw, c[2] * ky, c[3] * kw)
		local look = sch[piece:match("^(%a+)")]
		p.Material = look.mat
		p.MaterialVariant = look.var or ""
		p.Color = look.col
		p.Reflectance = look.refl or 0
		p.Anchored = true
		p.CastShadow = true
		p.Name = piece:match("^(%a+)")
		p.Parent = model
	end
	-- collision: the terraces as a box (or a cylinder when round), the bell as a cylinder
	local tH = 0.30 * REF[cls] * ky
	local col = Instance.new("Part")
	col.Name = "Collide_Base"
	col.Anchored = true
	col.Transparency = 1
	col.CanTouch = false
	col.CastShadow = false
	col.Size = Vector3.new(W, tH, W)
	col.CFrame = base * CFrame.new(0, tH / 2, 0)
	col.Parent = model
	local bH = (0.90 - 0.30) * REF[cls] * ky
	local bell = Instance.new("Part")
	bell.Name = "Collide_Bell"
	bell.Shape = Enum.PartType.Cylinder
	bell.Anchored = true
	bell.Transparency = 1
	bell.CanTouch = false
	bell.CastShadow = false
	bell.Size = Vector3.new(bH, 0.6 * W, 0.6 * W)
	bell.CFrame = base * CFrame.new(0, tH + bH / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
	bell.Parent = model
	if not onTerrain then
		local pl = Instance.new("Part")
		pl.Name = id .. "_TEMP"
		pl.Anchored = true
		pl.Material = Enum.Material.Concrete
		pl.Color = Color3.fromRGB(150, 146, 138)
		pl.Size = Vector3.new(W * 1.2 + 4, 2, W * 1.2 + 4)
		pl.CFrame = base * CFrame.new(0, -1, 0)
		pl.Parent = model
	end
	model.WorldPivot = base
	model.Parent = folder
	-- after parenting (an unparented clone's CollisionFidelity doesn't stick)
	for _, p in model:GetChildren() do
		if p:IsA("MeshPart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.Box end)
		end
	end
	return model
end

function P.folder()
	local root = workspace:FindFirstChild("Yangon1to1")
	local f = root:FindFirstChild("Pagodas")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Pagodas"
		f.Parent = root
	end
	return f
end

function P.place(rows)
	local kit = P.kit()
	local folder = P.folder()
	local n = 0
	for i, row in rows do
		if row ~= "" then
			P.placeOne(kit, folder, row)
			n += 1
		end
		if i % 8 == 0 then task.wait() end
	end
	return n
end

return P
