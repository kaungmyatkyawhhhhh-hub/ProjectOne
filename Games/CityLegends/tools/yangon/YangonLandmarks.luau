--[[
	YangonLandmarks (Studio, Edit mode; ServerStorage.ClaudeTools pattern; 2026-11-14, the great landmarks).

	Places the landmark models made by tools/yangon/city/landmarks.py (Shwedagon first). Each landmark is one .glb of
	meshes named KIND_id_cx_cy_cz_sx_sy_sz (hundredths of a stud, "n" = minus: the mesh's true box in world studs),
	uploaded with Open Cloud (POST /assets/v1/assets, Model, group 33151111, model/gltf-binary) and loaded with
	InsertService:LoadAsset. The .glb positions are relative to the box centre with x and z negated, so CFrame.new(centre)
	and Size from the name put it straight (no half turn). Its data module (build/landmarks/<id>_data.luau, pasted into
	ServerStorage.ClaudeTools.YangonLandmarkData_<id>) holds the collision boxes, the hill grid and the trees.

	local L = require(ServerStorage.ClaudeTools.YangonLandmarks:Clone())
	L.spawn(function() return L.build("shw", <asset id>, "Shwedagon Pagoda") end); L.status()
	    -> Workspace.Yangon.Landmarks.<name>: Meshes (MeshParts), Collide (invisible boxes), NamePlate (City Hall)
	    opts: { terrain = true } also writes the data's hill / pads / trees (off by default: the batch terrain steps
	    own the ground, lead 14 Nov); { retireStandIn = true } moves YangonFar's stand-in out (off: the batch 1
	    terrain step clears the far city).
	L.place(holding, model) -> meshes: material by kind
	    GOLD  Metal, warm gold (246, 176, 52), tag "LandmarkGlow" (attributes DayMaterial / DayColor keep the day look)
	    WHITE  SmoothPlastic (226, 223, 216); MIX  SmoothPlastic white (the vertex colours carry the colours)
	    STONE  Marble (214, 210, 202): the platform floor
	L.collide(text, folder) -> boxes: lines `box cx cy cz sx sy sz yaw tag` (yaw as landmarks.py: Roblox turns -yaw) and
	    `seg ax ay az bx by bz width thickness` (an oriented box whose top runs along A -> B: ramps, sloped walls);
	    Transparency 1, CanCollide, CanQuery, no touch, no shadow.
	L.terrain(data) -> the hill (Singuttara Hill under Shwedagon): clears the far stand-in's old mound (data.clear_*),
	    then raises the ground to the grid (grass), never lowering what is there (other terrain stays).
	L.trees(data, folder) -> trees from ServerStorage.YangonData.GreenKit (Tree / Palm / PalmA) on the slopes.
	L.pads(data) -> terrain pads under landmarks whose ground is not built yet (downtown, Maha Wizaya, Kaba Aye):
	    grass or pavement to just under the structure, never lowering anything.
	L.plate(data, model) -> a plain-text name plate (data.name at data.plate), e.g. "YANGON CITY HALL".
	L.retireStandIn() -> moves Workspace.Yangon.Far.Shwedagon (YangonFar's 1.4x stand-in) to
	    ServerStorage.YangonFar_old_shwedagon.
	L.glow(on) -> the night look for every LandmarkGlow part (Neon, brighter gold) or back to the day look.
	    WorldFx hook (client): see the note at the end of this file.
	L.undo(name) -> destroys Workspace.Yangon.Landmarks[name].
]]

local SS = game:GetService("ServerStorage")
local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")

local M = {}

M.GOLD = Color3.fromRGB(246, 176, 52)
M.GOLD_NIGHT = Color3.fromRGB(164, 102, 26) -- Neon: a dark warm gold glows gold; a bright one blooms into a yellow blob (checked)
M.GRASS = Enum.Material.Grass

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function M.parse(name: string)
	local kind, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not kind then
		return nil
	end
	return kind, id, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

function M.root(name: string): Model
	local Y = workspace:FindFirstChild("Yangon") :: Instance
	local f = Y:FindFirstChild("Landmarks")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Landmarks"
		f.Parent = Y
	end
	local m = f:FindFirstChild(name) :: Model?
	if not m then
		m = Instance.new("Model")
		m.Name = name
		-- the stupa must stand on the skyline from anywhere on the map
		m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		m.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
		m.Parent = f
	end
	return m :: Model
end

local function sub(model: Instance, name: string): Instance
	local f = model:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = model
	end
	return f
end

function M.place(holding: Instance, model: Instance): number
	local folder = sub(model, "Meshes")
	folder:ClearAllChildren()
	local n = 0
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, id, c, size = M.parse(d.Name)
			if not kind and d.Parent then
				kind, id, c, size = M.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			if kind then
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = kind .. "_" .. id
				q.Size = size
				q.CFrame = CFrame.new(c)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.CastShadow = true
				q.DoubleSided = false
				q.TextureID = ""
				pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				pcall(function()
					-- the stupa's curves must stay smooth far away (it is the skyline)
					q.RenderFidelity = if kind == "GOLD" then Enum.RenderFidelity.Precise else Enum.RenderFidelity.Automatic
				end)
				if kind == "GOLD" then
					-- Metal, not Foil: Foil's crumpled texture read as tinfoil on the big plinth (checked in Studio)
					q.Material = Enum.Material.Metal
					q.Color = M.GOLD
					q.Reflectance = 0
					q:SetAttribute("DayMaterial", "Metal")
					q:SetAttribute("DayColor", M.GOLD)
					q:SetAttribute("NightColor", M.GOLD_NIGHT)
					CollectionService:AddTag(q, "LandmarkGlow")
				elseif kind == "STONE" then
					-- the platform floor: white SmoothPlastic blew out to pure white in the sun (checked); marble, grey
					q.Material = Enum.Material.Marble
					q.Color = Color3.fromRGB(214, 210, 202)
					q.CastShadow = false
				elseif kind == "WHITE" then
					q.Material = Enum.Material.SmoothPlastic
					q.Color = Color3.fromRGB(226, 223, 216)
				else
					q.Material = Enum.Material.SmoothPlastic
					q.Color = Color3.new(1, 1, 1)
				end
				q.Parent = folder
				n += 1
			end
		end
	end
	return n
end

function M.collide(text: string, model: Instance): number
	local folder = sub(model, "Collide")
	folder:ClearAllChildren()
	local n = 0
	for line in string.gmatch(text, "[^\n]+") do
		local w = string.split(line, " ")
		local p = Instance.new("Part")
		if w[1] == "box" then
			p.Size = Vector3.new(tonumber(w[5]) :: number, tonumber(w[6]) :: number, tonumber(w[7]) :: number)
			p.CFrame = CFrame.new(tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number)
				* CFrame.Angles(0, -(tonumber(w[8]) :: number), 0)
			p.Name = w[9] or "Box"
		elseif w[1] == "seg" then
			local a = Vector3.new(tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number)
			local b = Vector3.new(tonumber(w[5]) :: number, tonumber(w[6]) :: number, tonumber(w[7]) :: number)
			local width, thick = tonumber(w[8]) :: number, tonumber(w[9]) :: number
			local cf = CFrame.lookAt((a + b) / 2, b)
			p.Size = Vector3.new(width, thick, (b - a).Magnitude)
			p.CFrame = cf * CFrame.new(0, -thick / 2, 0)
			p.Name = "Ramp"
		else
			p:Destroy()
			continue
		end
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = folder
		n += 1
	end
	return n
end

-- the hill grid: rows (z) of base-64 pairs, height x 4
local ALPH = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decode(data: any)
	local val = {}
	for i = 1, 64 do
		val[string.byte(ALPH, i)] = i - 1
	end
	local rows = {}
	for line in string.gmatch(data.grid, "[^\n]+") do
		local r = table.create(#line // 2)
		for i = 1, #line, 2 do
			r[#r + 1] = (val[string.byte(line, i)] * 64 + val[string.byte(line, i + 1)]) / 4
		end
		rows[#rows + 1] = r
	end
	return rows
end

local function sampler(data: any)
	local rows = decode(data)
	local n, x0, z0, st = data.gn, data.gx0, data.gz0, data.gstep
	return function(x: number, z: number): number?
		local fi = (x - x0) / st
		local fj = (z - z0) / st
		if fi < 0 or fj < 0 or fi > n - 1.001 or fj > n - 1.001 then
			return nil
		end
		local i, j = math.floor(fi), math.floor(fj)
		local a, b = fi - i, fj - j
		local r0, r1 = rows[j + 1], rows[j + 2]
		return r0[i + 1] * (1 - a) * (1 - b) + r0[i + 2] * a * (1 - b) + r1[i + 1] * (1 - a) * b + r1[i + 2] * a * b
	end
end

-- terrain: chunk by chunk (CH x CH voxel columns), from Y_LO up to Y_HI
function M.terrain(data: any): string
	local T = workspace.Terrain
	local h = sampler(data)
	local x0, z0 = data.gx0, data.gz0
	local span = (data.gn - 1) * data.gstep
	local VX = 4
	local Y_LO, Y_HI = 28, 180
	local CH = 48
	local nx = math.floor(span / VX)
	local cleared, raised = 0, 0
	local cx, cz, cr, cy = data.clear_x, data.clear_z, data.clear_r, data.clear_y
	for ci = 0, nx - 1, CH do
		for cj = 0, nx - 1, CH do
			local ax = x0 + ci * VX
			local az = z0 + cj * VX
			local bx = math.min(x0 + (ci + CH) * VX, x0 + nx * VX)
			local bz = math.min(z0 + (cj + CH) * VX, z0 + nx * VX)
			local region = Region3.new(Vector3.new(ax, Y_LO, az), Vector3.new(bx, Y_HI, bz)):ExpandToGrid(4)
			local mats, occs = T:ReadVoxels(region, 4)
			local size = mats.Size
			local rmin = region.CFrame.Position - region.Size / 2
			for i = 1, size.X do
				local x = rmin.X + (i - 0.5) * 4
				for k = 1, size.Z do
					local z = rmin.Z + (k - 0.5) * 4
					local top = h(x, z)
					local inClear = cr and (x - cx) ^ 2 + (z - cz) ^ 2 <= cr * cr
					for j = 1, size.Y do
						local yb = rmin.Y + (j - 1) * 4
						if inClear and yb >= cy and occs[i][j][k] > 0 then
							occs[i][j][k] = 0
							mats[i][j][k] = Enum.Material.Air
							cleared += 1
						end
						if top then
							local o = math.clamp((top - yb) / 4, 0, 1)
							if o > occs[i][j][k] + 0.01 then
								occs[i][j][k] = o
								mats[i][j][k] = M.GRASS
								raised += 1
							end
						end
					end
				end
			end
			T:WriteVoxels(region, 4, mats, occs)
			task.wait()
		end
	end
	return string.format("terrain: %d voxels cleared (old mound), %d raised", cleared, raised)
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.IgnoreWater = true

function M.trees(data: any, model: Instance): number
	terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
	local folder = sub(model, "Trees")
	folder:ClearAllChildren()
	local YD = SS:FindFirstChild("YangonData")
	local kit = YD and YD:FindFirstChild("GreenKit")
	if not kit then
		return 0
	end
	local names = { "Tree", "Palm", "PalmA" }
	local rng = Random.new(1453)
	local n = 0
	for line in string.gmatch(data.trees, "[^\n]+") do
		local w = string.split(line, " ")
		local x, z, s, k = tonumber(w[1]) :: number, tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number
		local src = kit:FindFirstChild(names[k] or "Tree") :: Model?
		local hit = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -700, 0), terrainOnly)
		if src and hit then
			local g = hit.Position.Y
			local t = src:Clone()
			local _, size = t:GetBoundingBox()
			local wide = (if k == 1 then rng:NextNumber(30, 44) else rng:NextNumber(18, 26)) * s
			t:ScaleTo(t:GetScale() * (wide / math.max(size.X, size.Z)))
			local cf, sz = t:GetBoundingBox()
			local foot = CFrame.new(x, g - 0.6, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			t:PivotTo(foot * (CFrame.new(cf.Position - Vector3.new(0, sz.Y / 2, 0)):Inverse() * t:GetPivot()))
			for _, d in t:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					if d.Size.Y < sz.Y * 0.6 or d.Position.Y > g + sz.Y * 0.45 then
						d.CanCollide = false
					end
					d.CanTouch = false
				end
			end
			t.Parent = folder
			n += 1
			if n % 60 == 0 then
				task.wait()
			end
		end
	end
	return n
end

function M.retireStandIn(): string
	local Y = workspace:FindFirstChild("Yangon")
	local far = Y and Y:FindFirstChild("Far")
	local old = far and far:FindFirstChild("Shwedagon")
	if not old then
		return "stand-in: none in Workspace.Yangon.Far"
	end
	local prev = SS:FindFirstChild("YangonFar_old_shwedagon")
	if prev then
		prev:Destroy()
	end
	old.Name = "YangonFar_old_shwedagon"
	old:SetAttribute("WasIn", "Workspace.Yangon.Far (named Shwedagon)")
	old.Parent = SS
	return "stand-in moved to ServerStorage.YangonFar_old_shwedagon"
end

function M.glow(on: boolean): number
	local n = 0
	for _, p in CollectionService:GetTagged("LandmarkGlow") do
		if p:IsA("BasePart") then
			if on then
				p.Material = Enum.Material.Neon
				p.Color = p:GetAttribute("NightColor") or M.GOLD_NIGHT
			else
				p.Material = Enum.Material[p:GetAttribute("DayMaterial") or "Metal"]
				p.Color = p:GetAttribute("DayColor") or M.GOLD
			end
			n += 1
		end
	end
	return n
end

-- ground pads under landmarks whose ground is not built yet (data.pads: `mat y depth 0 x,z;x,z;...` a line): fills the
-- polygon from y - depth up to y - 0.6 (grass, or pavement), never lowering what is there
local PAD_MAT = { grass = Enum.Material.Grass, pave = Enum.Material.Pavement }
function M.pads(data: any): string
	if not data.pads then
		return "pads: none"
	end
	local T = workspace.Terrain
	local n = 0
	for line in string.gmatch(data.pads, "[^\n]+") do
		local w = string.split(line, " ")
		local mat = PAD_MAT[w[1]] or Enum.Material.Grass
		local top, depth = tonumber(w[2]) :: number - 0.6, tonumber(w[3]) :: number
		local poly = {}
		local x0, z0, x1, z1 = math.huge, math.huge, -math.huge, -math.huge
		for pair in string.gmatch(w[5], "[^;]+") do
			local xy = string.split(pair, ",")
			local x, z = tonumber(xy[1]) :: number, tonumber(xy[2]) :: number
			table.insert(poly, Vector2.new(x, z))
			x0, z0, x1, z1 = math.min(x0, x), math.min(z0, z), math.max(x1, x), math.max(z1, z)
		end
		local function inside(x: number, z: number): boolean
			local c = false
			local j = #poly
			for i = 1, #poly do
				local a, b = poly[i], poly[j]
				if (a.Y > z) ~= (b.Y > z) and x < (b.X - a.X) * (z - a.Y) / (b.Y - a.Y) + a.X then
					c = not c
				end
				j = i
			end
			return c
		end
		local region = Region3.new(Vector3.new(x0 - 4, top - depth, z0 - 4), Vector3.new(x1 + 4, top + 4, z1 + 4)):ExpandToGrid(4)
		local mats, occs = T:ReadVoxels(region, 4)
		local size = mats.Size
		local rmin = region.CFrame.Position - region.Size / 2
		for i = 1, size.X do
			local x = rmin.X + (i - 0.5) * 4
			for k = 1, size.Z do
				local z = rmin.Z + (k - 0.5) * 4
				if inside(x, z) then
					for j = 1, size.Y do
						local yb = rmin.Y + (j - 1) * 4
						local o = math.clamp((top - yb) / 4, 0, 1)
						if o > occs[i][j][k] + 0.01 then
							occs[i][j][k] = o
							mats[i][j][k] = mat
							n += 1
						end
					end
				end
			end
		end
		T:WriteVoxels(region, 4, mats, occs)
		task.wait()
	end
	return string.format("pads: %d voxels", n)
end

-- a plain-text name plate (owner: real names as plain text, never logo artwork): data.name at data.plate "x y z",
-- facing +z (south)
function M.plate(data: any, model: Instance): string
	if not (data.name and data.plate) then
		return "plate: none"
	end
	local xyz = string.split((string.gsub(data.plate, "%s+$", "")), " ")
	local p = Instance.new("Part")
	p.Name = "NamePlate"
	p.Size = Vector3.new(34, 3.2, 0.2)
	p.CFrame = CFrame.new(tonumber(xyz[1]) :: number, tonumber(xyz[2]) :: number, tonumber(xyz[3]) :: number)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromRGB(238, 236, 228)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 24
	g.LightInfluence = 1
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = string.gsub(data.name, "%s+$", "")
	t.TextScaled = true
	t.Font = Enum.Font.SourceSansSemibold
	t.TextColor3 = Color3.fromRGB(40, 70, 72)
	t.Parent = g
	g.Parent = p
	local old = model:FindFirstChild("NamePlate")
	if old then
		old:Destroy()
	end
	p.Parent = model
	return "plate: " .. t.Text
end

function M.load(lid: string, assetId: number): Instance
	local hold = SS:FindFirstChild("LandmarkHolding")
	if not hold then
		hold = Instance.new("Folder")
		hold.Name = "LandmarkHolding"
		hold.Parent = SS
	end
	local old = hold:FindFirstChild(lid)
	if old then
		old:Destroy()
	end
	local m = InsertService:LoadAsset(assetId)
	m.Name = lid
	m.Parent = hold
	return m
end

function M.data(lid: string): any
	local mod = SS.ClaudeTools:FindFirstChild("YangonLandmarkData_" .. lid) :: ModuleScript
	return require(mod:Clone())
end

-- the whole landmark: meshes, collision, the hill and trees (when the data has them), the stand-in out
function M.build(lid: string, assetId: number, name: string, opts: any?): string
	local o = opts or {}
	local log = {}
	local data = M.data(lid)
	local hold = M.load(lid, assetId)
	local model = M.root(name)
	table.insert(log, string.format("%d meshes", M.place(hold, model)))
	table.insert(log, string.format("%d collision boxes", M.collide(data.collide, model)))
	task.wait()
	-- terrain only when asked (lead, 14 Nov: the batch terrain steps build the ground; landmarks write none by default)
	if data.grid and o.terrain then
		table.insert(log, M.terrain(data))
	end
	if data.trees and o.terrain then
		table.insert(log, string.format("%d trees", M.trees(data, model)))
	end
	if data.pads and o.terrain then
		table.insert(log, M.pads(data))
	end
	if data.name then
		table.insert(log, M.plate(data, model))
	end
	if lid == "shw" and o.retireStandIn then
		table.insert(log, M.retireStandIn())
	end
	model:SetAttribute("AssetId", assetId)
	model:SetAttribute("Landmark", lid)
	return table.concat(log, "; ")
end

function M.undo(name: string): number
	local Y = workspace:FindFirstChild("Yangon")
	local f = Y and Y:FindFirstChild("Landmarks")
	local m = f and f:FindFirstChild(name)
	if m then
		m:Destroy()
		return 1
	end
	return 0
end

function M.spawn(fn)
	SS:SetAttribute("LandmarkStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		SS:SetAttribute("LandmarkStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS:GetAttribute("LandmarkStatus"))
end

--[[ WorldFx night hook (client, src/client/WorldFx.lua, inside WorldFx.setDaylight after `lampsLit = lit`):

		for i, p in CollectionService:GetTagged("LandmarkGlow") do
			if p:IsA("BasePart") then
				if lit then
					p.Material = Enum.Material.Neon
					p.Color = p:GetAttribute("NightColor") or Color3.fromRGB(164, 102, 26)
				else
					p.Material = Enum.Material[p:GetAttribute("DayMaterial") or "Metal"]
					p.Color = p:GetAttribute("DayColor") or Color3.fromRGB(246, 176, 52)
				end
			end
		end

	plus the same body in a CollectionService:GetInstanceAddedSignal("LandmarkGlow") handler (streamed-in parts).
	Do NOT tag landmarks "LampGlow": that path sets SmoothPlastic by day and the gold would lose its Metal.
]]

return M
