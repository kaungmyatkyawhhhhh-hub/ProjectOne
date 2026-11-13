--[[
	YangonBuildingMeshes (Studio, Edit mode; ServerStorage.ClaudeTools pattern; 2026-11-14, the mesh building kit).

	Places the Yangon mesh buildings made by tools/yangon/city/d24_bmesh.py: per 256-stud cell an F mesh (walls, shadows on)
	and an R mesh (roofs and props), all on ONE atlas (tools/yangon/city/atlas.py) through a SurfaceAppearance, with the
	building colours in the meshes' vertex colours; plus invisible plain collision boxes.

	Data path: the .glb packs go up with Open Cloud (POST /assets/v1/assets, assetType Model, group 33151111), then
	InsertService:LoadAsset(id) into ServerStorage.BuildingMeshHolding. Each MeshPart (inside a "<name>_Node" Model) is
	named KIND_CELL_cx_cy_cz_sx_sy_sz in hundredths of a stud ("n" = minus): its true box. Positions in the .glb are
	relative to the box centre with x and z negated, so the importer's half turn puts them straight: CFrame.new(centre),
	no extra turn (checked in the pilot, opts.halfTurn = true to test the other way).

	local M = require(ServerStorage.ClaudeTools.YangonBuildingMeshes:Clone())
	M.place(holding, folder, { color = <atlas id>, glow = <mask id>, night = <atlas_night id, optional> }, opts) -> meshes placed
	    into folder/Cell_<cell> Models (ModelStreamingMode Atomic). Anchored, no collision / query / touch, CastShadow on F
	    only, RenderFidelity Automatic. F (walls) and R (roofs, props): TextureID = the atlas; the building colours are the
	    meshes' vertex colours, which Roblox multiplies with a TextureID but HIDES under a SurfaceAppearance (pilot).
	    G (night windows, 0.08 in front of the window walls): a SurfaceAppearance (ColorMap = the atlas, opaque, or with
	    textureIds.night = atlas_night.png see-through; EmissiveMask = the mask, EmissiveStrength 0), Transparency 1 by
	    day; tags "FacadeGlow" (the SurfaceAppearance) and "FacadeNight" (the MeshPart) for a night script: M.glow(3)
	    looked right with a dark night (pilot). A freshly uploaded picture as a SurfaceAppearance ColorMap draws plain
	    white for 30+ minutes (a TextureID shows in about a minute): check the night look later.
	    opts: { halfTurn = bool, lift = number (y offset, for comparisons),
	    name = string (cell Model name prefix, default "Cell_") }
	M.collide(data, folder, opts) -> boxes: data is the Collide_<n> string (`id|x y z sx sy sz yaw|...` a line);
	    Transparency 1, CanCollide true, CanQuery true, CanTouch false, CastShadow false, attribute Plot = id.
	M.probe(text) -> "id y" lines: the lowest terrain under each outline's sample points (text: "id x z;x z;..." lines).
	M.hideParts(x0, x1, z0, z1) / M.restoreParts(): moves the part buildings whose pivot lies in the box to
	    ServerStorage.PilotHidden and back (attribute HiddenFrom keeps the old parent's full name).
	M.glow(strength) sets EmissiveStrength on every FacadeGlow SurfaceAppearance and shows the G layer (strength > 0)
	    or hides it (0).
	M.undo(folderName) destroys Workspace.Yangon[folderName] (default the meshes and the collision folders).
	M.spawn(fn) / M.status(): long work in a task with the result in ServerStorage attribute BuildingMeshStatus.
]]

local SS = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local M = {}

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

-- KIND_CELL_cx_cy_cz_sx_sy_sz -> kind, cell id, centre, size
function M.parse(name: string)
	local kind, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not kind then
		return nil
	end
	local cell = string.match(id, "^(.-)s%d+$") or id
	return kind, cell, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

local function asset(id: any): string
	local s = tostring(id)
	if string.match(s, "^%d+$") then
		return "rbxassetid://" .. s
	end
	return s
end

function M.place(holding: Instance, folder: Instance, textureIds: { color: any, glow: any, night: any? }, opts: any?): number
	local o = opts or {}
	local n = 0
	local cells = {}
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, cell, c, size = M.parse(d.Name)
			if not kind and d.Parent then
				kind, cell, c, size = M.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			if kind then
				local model = cells[cell]
				if not model then
					model = folder:FindFirstChild((o.name or "Cell_") .. cell)
					if not model then
						model = Instance.new("Model")
						model.Name = (o.name or "Cell_") .. cell
						model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
						model.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
						model.Parent = folder
					end
					cells[cell] = model
				end
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = "BMesh" .. kind
				q.Size = size
				local cf = CFrame.new(c + Vector3.new(0, o.lift or 0, 0))
				if o.halfTurn then
					cf *= CFrame.Angles(0, math.pi, 0)
				end
				q.CFrame = cf
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.CastShadow = kind == "F"
				q.DoubleSided = false
				q.Material = Enum.Material.SmoothPlastic
				q.Color = Color3.new(1, 1, 1)
				pcall(function()
					q.RenderFidelity = Enum.RenderFidelity.Automatic
				end)
				if kind == "G" then
					-- the night windows: an emissive copy of the window walls 0.08 in front, hidden by day
					q.TextureID = ""
					local sa = Instance.new("SurfaceAppearance")
					if textureIds.night then
						-- (atlas_night.png, alpha = mask: see-through between the windows; in the pilot that RGBA picture
						-- never drew, as a ColorMap or a TextureID, so the default is the opaque atlas below)
						sa.AlphaMode = Enum.AlphaMode.Transparency
						sa.ColorMap = asset(textureIds.night)
					else
						-- opaque: at night G covers the window walls with the same atlas (no building tint, hardly
						-- seen in the dark) and the mask lights the windows
						sa.AlphaMode = Enum.AlphaMode.Overlay
						sa.ColorMap = asset(textureIds.color)
					end
					sa.EmissiveMaskContent = Content.fromUri(asset(textureIds.glow))
					sa.EmissiveStrength = 0
					sa.Parent = q
					q.Transparency = 1
					q.CastShadow = false
					CollectionService:AddTag(sa, "FacadeGlow")
					CollectionService:AddTag(q, "FacadeNight")
				else
					-- a plain TextureID: a SurfaceAppearance would hide the vertex colours (the building colours)
					q.TextureID = asset(textureIds.color)
				end
				q:SetAttribute("Cell", cell)
				q.Parent = model
				n += 1
				if n % 40 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

function M.collide(data: string, folder: Instance, opts: any?): number
	local o = opts or {}
	local n = 0
	for line in string.gmatch(data, "[^\n]+") do
		local parts = string.split(line, "|")
		local id = parts[1]
		for k = 2, #parts do
			local v = {}
			for w in string.gmatch(parts[k], "%S+") do
				table.insert(v, tonumber(w))
			end
			if #v == 7 then
				local p = Instance.new("Part")
				p.Name = "BCol"
				p.Anchored = true
				p.Size = Vector3.new(v[4], v[5], v[6])
				p.CFrame = CFrame.new(v[1], v[2] + (o.lift or 0), v[3]) * CFrame.Angles(0, v[7], 0)
				p.Transparency = 1
				p.CanCollide = true
				p.CanQuery = true
				p.CanTouch = false
				p.CastShadow = false
				p.TopSurface = Enum.SurfaceType.Smooth
				p.BottomSurface = Enum.SurfaceType.Smooth
				p:SetAttribute("Plot", id)
				p.Parent = folder
				n += 1
			end
		end
		if n % 200 == 0 then
			task.wait()
		end
	end
	return n
end

function M.probe(text: string): string
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = true
	local out = {}
	for line in string.gmatch(text, "[^\n]+") do
		local id, rest = string.match(line, "^(%S+) (.*)$")
		local low = math.huge
		for x, z in string.gmatch(rest, "(%-?[%d%.]+) (%-?[%d%.]+)") do
			local h = workspace:Raycast(Vector3.new(tonumber(x), 600, tonumber(z)), Vector3.new(0, -1000, 0), params)
			if h then
				low = math.min(low, h.Position.Y)
			end
		end
		table.insert(out, id .. " " .. (if low < math.huge then string.format("%.2f", low) else "nil"))
	end
	return table.concat(out, "\n")
end

function M.hideParts(x0: number, x1: number, z0: number, z1: number): number
	local store = SS:FindFirstChild("PilotHidden")
	if not store then
		store = Instance.new("Folder")
		store.Name = "PilotHidden"
		store.Parent = SS
	end
	local n = 0
	for _, m in workspace.Yangon.Buildings:GetChildren() do
		if m:IsA("Model") then
			local p = m:GetPivot().Position
			if p.X >= x0 and p.X <= x1 and p.Z >= z0 and p.Z <= z1 then
				m:SetAttribute("HiddenFrom", m.Parent:GetFullName())
				m.Parent = store
				n += 1
			end
		end
	end
	return n
end

function M.restoreParts(): number
	local store = SS:FindFirstChild("PilotHidden")
	if not store then
		return 0
	end
	local n = 0
	for _, m in store:GetChildren() do
		m.Parent = workspace.Yangon.Buildings
		m:SetAttribute("HiddenFrom", nil)
		n += 1
	end
	store:Destroy()
	return n
end

function M.glow(strength: number): number
	local n = 0
	for _, sa in CollectionService:GetTagged("FacadeGlow") do
		sa.EmissiveStrength = strength
		n += 1
	end
	for _, q in CollectionService:GetTagged("FacadeNight") do
		q.Transparency = if strength > 0 then 0 else 1
	end
	return n
end

function M.undo(folderName: string?): number
	local n = 0
	for _, name in (if folderName then { folderName } else { "BuildingMeshes", "BuildingCollide" }) do
		local f = workspace.Yangon:FindFirstChild(name)
		if f then
			f:Destroy()
			n += 1
		end
	end
	return n
end

function M.spawn(fn)
	SS:SetAttribute("BuildingMeshStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		SS:SetAttribute("BuildingMeshStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS:GetAttribute("BuildingMeshStatus"))
end

return M
