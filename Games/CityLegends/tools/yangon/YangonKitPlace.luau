--[[
	YangonKitPlace (Studio, Edit mode; ServerStorage.ClaudeTools pattern; 2026-11-16, rescale step 3.7): places the 1:1
	ordinary buildings made by tools/yangon/city/buildings_1to1.py from the reusable facade kit (kit_panels.py).

	Kit meshes (kit_<n>.glb, Open Cloud Models) are named CLASS_<pid>_cx_cy_cz_sx_sy_sz (hundredths of a stud, "n" =
	minus; the box in the panel's own frame: X along the wall, Y up, Z out of the wall). One panel is up to three
	MeshParts: KWX (the wall: takes the building's wall code as its Name, Plaster + its Ygn variant, the code's colour),
	KGR (glass, grilles, cages, AC: Metal + YgnSteelPainted, white, colours in the vertex colours), KAR (awnings, signs,
	laundry: Fabric + YgnCanvas, white). Cell meshes (cells_<n>.glb) are named GROUP_c<i>x<j>s<k>_<box> in world studs:
	KW6 plain walls, KCO flat roofs, KRG pitched roofs (zinc variant, sheet colours in the vertex colours), KWC compound
	walls, NWH night window panes (Neon, tag FacadeNight, hidden by day).
	Materials follow tools/yangon/YangonMaterials.luau's RULES.kit (that module is not in this place: the rules are copied
	here); colours are the midday calibrated kit colours (landmark_glb3d.GROUPS).

	local P = require(ServerStorage.ClaudeTools.YangonKitPlace:Clone())
	P.templates(holdingFolder)          -> n templates (copies in ServerStorage.YgnKitTemplates, CollisionFidelity Box)
	P.place(instText, folder)           -> parts: lines "pid sx x y z yaw wall", "#i j" starts cell (i, j)
	P.cells(holdingFolder, folder)      -> cell meshes placed
	P.spawn(fn) / P.status()            -> long work in a task; result in ServerStorage attribute KitPlaceStatus
	Light version (2026-11-16): the place keeps only the shells; the detail is data made on each client near the camera
	(src/client/YangonKitStream.client.lua, decoder Shared.YangonKitData).
	P.templates(holding, store)         -> templates into `store` (ReplicatedStorage.YgnKit.Templates for the light kit)
	P.shells(text, folder)              -> Shell_<n> lines: S shell box (wall colour, collision, attribute T = tile,
	                                       flat roofs get a concrete Texture on top), R pitched roof (kit roof, collides,
	                                       Box), W compound-wall collision (invisible) into folder.Shell / .WallCollide
	P.preview(centre, radius)           -> Edit only: builds the detail tiles within radius (what a client builds) into
	                                       Workspace._KitPreview and hides their shells; P.unpreview() undoes it
	Every visual MeshPart: Anchored, CanCollide / CanQuery / CanTouch false, CollisionFidelity Box. Collision is
	YangonBuildingMeshes.collide on the Collide_<n> strings.
]]

local SS = game:GetService("ServerStorage")
local MS = game:GetService("MaterialService")
local CollectionService = game:GetService("CollectionService")

local P = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- landmark_glb3d.GROUPS (midday calibrated) for the wall codes the generator uses
P.WALL = {
	KW0 = rgb(252, 255, 250), KW1 = rgb(255, 215, 153), KW2 = rgb(178, 242, 255), KW3 = rgb(199, 168, 130),
	KW4 = rgb(226, 248, 255), KW5 = rgb(255, 197, 187), KW6 = rgb(255, 252, 243), KW7 = rgb(208, 255, 165),
	KWG = rgb(162, 160, 150), KWB = rgb(173, 209, 250), KWC = rgb(144, 145, 136), KWD2 = rgb(181, 172, 162),
}
-- YangonMaterials RULES.kit, plus the cell groups
P.VARIANT = {
	KW0 = "YgnRenderPainted", KW1 = "YgnRenderPainted", KW2 = "YgnRenderPainted", KW3 = "YgnRenderPainted",
	KW4 = "YgnRenderPainted", KW5 = "YgnRenderPainted", KW6 = "YgnRenderPainted", KW7 = "YgnRenderPainted",
	KWB = "YgnRenderPainted", KWG = "YgnRenderStained", KWD2 = "YgnRenderStained", KWC = "YgnRenderStained",
	KGR = "YgnSteelPainted", KAR = "YgnCanvas", KCO = "YgnConcreteBare", KRG = "YgnCorrugatedZinc",
	KRF = "YgnCorrugatedRust", KRB = "YgnCorrugatedBlue", KRT = "YgnClayRoofTile",
}

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function P.parse(name: string)
	local kind, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+%d*)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not kind then
		return nil
	end
	return kind, id, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

local function look(q: BasePart, code: string, color: Color3?)
	local v = P.VARIANT[code]
	local mv = v and MS:FindFirstChild(v)
	if mv and mv:IsA("MaterialVariant") then
		q.Material = mv.BaseMaterial
		q.MaterialVariant = v
	else
		q.Material = Enum.Material.SmoothPlastic
	end
	q.Color = color or Color3.new(1, 1, 1)
end

local function visual(q: BasePart)
	q.Anchored = true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.Massless = true
	pcall(function()
		(q :: any).RenderFidelity = Enum.RenderFidelity.Automatic
	end)
	pcall(function()
		(q :: any).DoubleSided = false
	end)
end

local function meshParts(holding: Instance)
	local out = {}
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, id, c, size = P.parse(d.Name)
			if not kind and d.Parent then
				kind, id, c, size = P.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			if kind then
				table.insert(out, { part = d, kind = kind, id = id, c = c, size = size })
			end
		end
	end
	return out
end

P.T = {} -- pid -> { {kind, template, c, size}, ... }

function P.templates(holding: Instance, into: Instance?): number
	local store = into or SS:FindFirstChild("YgnKitTemplates")
	if not store then
		store = Instance.new("Folder")
		store.Name = "YgnKitTemplates"
		store.Parent = SS
	end
	P.store = store
	local n = 0
	for _, m in meshParts(holding) do
		if m.kind == "KWX" or m.kind == "KGR" or m.kind == "KAR" or m.kind == "KRO" then
			local name = m.kind .. "_" .. m.id
			local q = store:FindFirstChild(name)
			if not q then
				q = m.part:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = name
				q.Size = m.size
				q.TextureID = ""
				visual(q)
				q.CastShadow = true
				if m.kind == "KGR" then
					look(q, "KGR")
				elseif m.kind == "KAR" then
					look(q, "KAR")
				end
				q:SetAttribute("C", m.c)
				q:SetAttribute("S", m.size)
				q.Parent = store
				-- set once parented (on an unparented copy it did not stick, 16 Nov); clones keep it
				pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
				end)
				n += 1
				if n % 20 == 0 then
					task.wait()
				end
			end
		end
	end
	P.index(store)
	return n
end

function P.index(into: Instance?): number
	P.T = {}
	local n = 0
	local store = into or P.store or SS:FindFirstChild("YgnKitTemplates")
	if not store then
		return 0
	end
	for _, q in store:GetChildren() do
		local kind, pid = string.match(q.Name, "^(%u+)_(%w+)$")
		if kind then
			P.T[pid] = P.T[pid] or {}
			table.insert(P.T[pid], { kind = kind, part = q, c = q:GetAttribute("C"), size = q:GetAttribute("S") })
			n += 1
		end
	end
	return n
end

function P.place(text: string, folder: Instance): number
	if next(P.T) == nil then
		P.index()
	end
	local n = 0
	local cellModel: Instance = folder
	local missing = 0
	local batch = {}
	local function flush()
		for _, q in batch do
			q.Parent = cellModel
		end
		table.clear(batch)
	end
	for line in string.gmatch(text, "[^\n]+") do
		if string.sub(line, 1, 1) == "#" then
			flush()
			local i, j = string.match(line, "#(%-?%d+) (%-?%d+)")
			local name = "Cell_" .. i .. "_" .. j
			local cm = folder:FindFirstChild(name)
			if not cm then
				cm = Instance.new("Model")
				cm.Name = name
				cm.Parent = folder
			end
			cellModel = cm
		elseif string.sub(line, 1, 2) == "B " then
			-- a plain Part: "B x y z sx sy sz yaw code" (plain walls in the wall colour, flat roof slabs KCO)
			local w = string.split(line, " ")
			local q = Instance.new("Part")
			q.Size = Vector3.new(tonumber(w[5]) :: number, tonumber(w[6]) :: number, tonumber(w[7]) :: number)
			q.CFrame = CFrame.new(tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number)
				* CFrame.Angles(0, tonumber(w[8]) :: number, 0)
			q.Name = w[9]
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			visual(q)
			q.CastShadow = true
			look(q, w[9], P.WALL[w[9]])
			table.insert(batch, q)
			n += 1
		else
			local w = string.split(line, " ")
			local parts = P.T[w[1]]
			if not parts then
				missing += 1
			else
				local sx = tonumber(w[2]) :: number
				local cf = CFrame.new(tonumber(w[3]) :: number, tonumber(w[4]) :: number, tonumber(w[5]) :: number)
					* CFrame.Angles(0, tonumber(w[6]) :: number, 0)
				local wall = w[7]
				local sy = tonumber(w[8]) or 1
				local sz = tonumber(w[9]) or 1
				local roof = w[10]
				for _, t in parts do
					local q = t.part:Clone()
					q.Size = Vector3.new(t.size.X * sx, t.size.Y * sy, t.size.Z * sz)
					q.CFrame = cf * CFrame.new(t.c.X * sx, t.c.Y * sy, t.c.Z * sz)
					if t.kind == "KWX" then
						q.Name = wall
						look(q, wall, P.WALL[wall])
					elseif t.kind == "KRO" then
						q.Name = roof or "KRG"
						look(q, roof or "KRG")
					else
						q.Name = t.kind
					end
					table.insert(batch, q)
					n += 1
				end
				if #batch >= 400 then
					flush()
					task.wait()
				end
			end
		end
	end
	flush()
	if missing > 0 then
		warn("YangonKitPlace: " .. missing .. " instances with no template")
	end
	return n
end

function P.cells(holding: Instance, folder: Instance): number
	local n = 0
	for _, m in meshParts(holding) do
		if m.kind ~= "KWX" and m.kind ~= "KGR" and m.kind ~= "KAR" and m.kind ~= "KRO" then
			local cell = string.match(m.id, "^c(.-)s%d+$") or m.id
			local cm = folder:FindFirstChild("Cell_" .. cell)
			if not cm then
				cm = Instance.new("Model")
				cm.Name = "Cell_" .. cell
				cm.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
				cm.Parent = folder
			end
			local q = m.part:Clone()
			for _, ch in q:GetChildren() do
				ch:Destroy()
			end
			q.Name = m.kind
			q.Size = m.size
			q.CFrame = CFrame.new(m.c)
			q.TextureID = ""
			visual(q)
			q.CastShadow = m.kind ~= "NWH"
			if m.kind == "NWH" then
				q.Material = Enum.Material.Neon
				q.Color = rgb(204, 160, 104)
				q.Transparency = 1
				CollectionService:AddTag(q, "FacadeNight")
			elseif m.kind == "KWC" or m.kind == "KW6" then
				look(q, m.kind) -- white: the wall colours are in the vertex colours
			else
				look(q, m.kind)
			end
			q.Parent = cm
			pcall(function()
				q.CollisionFidelity = Enum.CollisionFidelity.Box
			end)
			n += 1
			if n % 10 == 0 then
				task.wait()
			end
		end
	end
	return n
end

-- ------------------------------------------------------------------------------------------------ light version
local function cellModel(folder: Instance, x: number, z: number): Instance
	local name = "Cell_" .. math.floor(x / 1792) .. "_" .. math.floor(z / 1792)
	local cm = folder:FindFirstChild(name)
	if not cm then
		cm = Instance.new("Model")
		cm.Name = name
		cm.Parent = folder
	end
	return cm
end

function P.shells(text: string, folder: Instance): number
	if next(P.T) == nil then
		P.index()
	end
	local shellF = folder:FindFirstChild("Shell") or Instance.new("Folder")
	shellF.Name = "Shell"
	shellF.Parent = folder
	local wallF = folder:FindFirstChild("WallCollide") or Instance.new("Folder")
	wallF.Name = "WallCollide"
	wallF.Parent = folder
	local conc = MS:FindFirstChild("YgnConcreteBare")
	local n = 0
	for line in string.gmatch(text, "[^\n]+") do
		local w = string.split(line, " ")
		if w[1] == "S" then
			local q = Instance.new("Part")
			q.Name = w[10]
			q.Size = Vector3.new(tonumber(w[6]) :: number, tonumber(w[7]) :: number, tonumber(w[8]) :: number)
			q.CFrame = CFrame.new(tonumber(w[3]) :: number, tonumber(w[4]) :: number, tonumber(w[5]) :: number)
				* CFrame.Angles(0, tonumber(w[9]) :: number, 0)
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			q.Anchored = true
			q.CanCollide = true
			q.CanQuery = true
			q.CanTouch = false
			q.CastShadow = true
			look(q, w[10], P.WALL[w[10]])
			q:SetAttribute("T", w[2])
			if w[11] == "1" and conc then
				-- a flat roof seen from far: the concrete slab texture on the shell top
				local t = Instance.new("Texture")
				t.Face = Enum.NormalId.Top
				t.Texture = (conc :: any).ColorMap
				t.StudsPerTileU = (conc :: any).StudsPerTile
				t.StudsPerTileV = (conc :: any).StudsPerTile
				t.Color3 = rgb(196, 192, 184)
				t.Parent = q
			end
			q.Parent = cellModel(shellF, q.Position.X, q.Position.Z)
			n += 1
		elseif w[1] == "R" then
			local parts = P.T[w[2]]
			if parts then
				local sx, sy, sz = tonumber(w[3]) :: number, tonumber(w[9]) :: number, tonumber(w[10]) :: number
				local cf = CFrame.new(tonumber(w[4]) :: number, tonumber(w[5]) :: number, tonumber(w[6]) :: number)
					* CFrame.Angles(0, tonumber(w[7]) :: number, 0)
				for _, t in parts do
					local q = t.part:Clone()
					q.Size = Vector3.new(t.size.X * sx, t.size.Y * sy, t.size.Z * sz)
					q.CFrame = cf * CFrame.new(t.c.X * sx, t.c.Y * sy, t.c.Z * sz)
					if t.kind == "KRO" then
						q.Name = w[11]
						look(q, w[11])
						q.CanCollide = true -- the roof is its own collision (CollisionFidelity Box on the template)
						q.CanQuery = true
					else
						q.Name = w[8]
						look(q, w[8], P.WALL[w[8]])
					end
					q.Parent = cellModel(shellF, cf.Position.X, cf.Position.Z)
					n += 1
				end
			end
		elseif w[1] == "W" then
			local q = Instance.new("Part")
			q.Name = "WCol"
			q.Anchored = true
			q.Size = Vector3.new(tonumber(w[5]) :: number, tonumber(w[6]) :: number, tonumber(w[7]) :: number)
			q.CFrame = CFrame.new(tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number)
				* CFrame.Angles(0, tonumber(w[8]) :: number, 0)
			q.Transparency = 1
			q.CanCollide = true
			q.CanQuery = true
			q.CanTouch = false
			q.CastShadow = false
			q.TopSurface = Enum.SurfaceType.Smooth
			q.BottomSurface = Enum.SurfaceType.Smooth
			q.Parent = wallF
			n += 1
		end
		if n % 300 == 0 then
			task.wait()
		end
	end
	return n
end

-- Edit preview of what a client builds near the camera
function P.preview(centre: Vector3, radius: number, shellFolder: Instance?): number
	local RS = game:GetService("ReplicatedStorage")
	local KD = require((RS:WaitForChild("Shared"):WaitForChild("YangonKitData") :: ModuleScript):Clone())
	local root = RS:FindFirstChild("YgnKit")
	assert(root, "no ReplicatedStorage.YgnKit")
	local T = KD.index(root:FindFirstChild("Templates"))
	local out = workspace:FindFirstChild("_KitPreview") or Instance.new("Folder")
	out.Name = "_KitPreview"
	out.Parent = workspace
	local keys = {}
	local n = 0
	for _, f in root:GetChildren() do
		if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
			local meta = KD.meta(f)
			for _, v in f:GetChildren() do
				local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
				if i then
					local cx, cz = (tonumber(i) + 0.5) * meta.tile, (tonumber(j) + 0.5) * meta.tile
					if math.sqrt((cx - centre.X) ^ 2 + (cz - centre.Z) ^ 2) <= radius and not out:FindFirstChild(v.Name) then
						local tf = Instance.new("Folder")
						tf.Name = v.Name
						tf.Parent = out
						local job = KD.job((v :: StringValue).Value, tonumber(i) :: number, tonumber(j) :: number, meta, T, tf)
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
	local y = workspace:FindFirstChild("Yangon1to1")
	local sf = shellFolder or (y and y:FindFirstChild("Buildings") and y.Buildings:FindFirstChild("Shell"))
	if sf then
		for _, d in sf:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("T") and keys[d:GetAttribute("T")] then
				d.Transparency = 1
				d:SetAttribute("PreviewHidden", true)
				for _, t in d:GetChildren() do
					if t:IsA("Texture") then
						t.Transparency = 1
					end
				end
			end
		end
	end
	return n
end

function P.unpreview(shellFolder: Instance?)
	local out = workspace:FindFirstChild("_KitPreview")
	if out then
		out:Destroy()
	end
	local y = workspace:FindFirstChild("Yangon1to1")
	local sf = shellFolder or (y and y:FindFirstChild("Buildings") and y.Buildings:FindFirstChild("Shell"))
	if sf then
		for _, d in sf:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("PreviewHidden") then
				d.Transparency = 0
				d:SetAttribute("PreviewHidden", nil)
				for _, t in d:GetChildren() do
					if t:IsA("Texture") then
						t.Transparency = 0
					end
				end
			end
		end
	end
end

function P.spawn(fn)
	SS:SetAttribute("KitPlaceStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		SS:SetAttribute("KitPlaceStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function P.status(): string
	return tostring(SS:GetAttribute("KitPlaceStatus"))
end

return P
