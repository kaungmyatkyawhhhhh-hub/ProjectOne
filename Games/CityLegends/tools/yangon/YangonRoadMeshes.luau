--[[
	YangonRoadMeshes (Studio, Edit mode; ServerStorage.ClaudeTools pattern; 2026-11-14): places the mesh roads of the Yangon
	batches 1-3 made by tools/yangon/city/roads.py, and their invisible collision boxes. Modelled on
	tools/riviera/RoadMeshes.luau (looks by kind) and YangonBuildingMeshes.luau (names, Open Cloud path, collision).

	Data path: build/city/roads_<tag>/roads_<tag>_<n>.glb (each <= 100 meshes) go up with Open Cloud as Models
	(POST /assets/v1/assets, assetType Model, group 33151111), then InsertService:LoadAsset(id) into
	ServerStorage.RoadMeshHolding_<tag>. Each MeshPart (or its "<name>_Node" Model) is named KIND_CELL_cx_cy_cz_sx_sy_sz in
	hundredths of a stud ("n" = minus): its true box. The .glb positions are relative to the box centre with x and z
	negated, so the importer's half turn puts them straight: CFrame.new(centre), no extra turn (glb.py, checked on the
	building pilot; opts.halfTurn = true to test the other way).

	local M = require(ServerStorage.ClaudeTools.YangonRoadMeshes:Clone())
	M.place(holding, folder, opts) -> meshes placed, into folder/Cell_<cell> Models (ModelStreamingMode Atomic). Anchored,
	    no collision / query / touch, no shadows (thin road pieces), RenderFidelity Automatic, DoubleSided off, Material
	    and Color by kind (LOOK below; KR / KW are the red and white kerb bands, KG plain grey kerbs, L paint, MG median
	    grass, B bridge concrete). opts: { halfTurn = bool, lift = number, name = cell Model prefix (default "Cell_") }
	M.collide(data, folder, opts) -> boxes: data is a RoadCollide_<tag>_<n> string, a line per box
	    "cx cy cz dx dy dz width walk kind" (cy = the box's TOP, (dx, dy, dz) its length and slope; kinds R carriageway,
	    P pavement, M median, J junction square, D deck, W parapet). Transparency 1, CanCollide true, CanQuery true (the
	    cars' ground rays and RoadLines-style raycasts need them), CanTouch false, CastShadow false, attribute RoadBox =
	    kind. Every box is a plain Part (no wedges): it lies along (dx, dy, dz), so its top follows the slope.
	M.undo(tag) destroys Workspace.Yangon.RoadMeshesB<tag> and Workspace.Yangon.RoadCollideB<tag>.
	M.spawn(fn) / M.status(): long work in a task with the result in ServerStorage attribute RoadMeshStatus.

	The calls (batch 1, after the .glb assets are inserted into ServerStorage.RoadMeshHolding_1 and the collision modules
	RoadCollide_1_1..n are in ServerStorage.YangonData):
		local M = require(game.ServerStorage.ClaudeTools.YangonRoadMeshes:Clone())
		M.spawn(function()
			local Y = workspace.Yangon
			local mf = Y:FindFirstChild("RoadMeshesB1") or Instance.new("Folder", Y); mf.Name = "RoadMeshesB1"
			local cf = Y:FindFirstChild("RoadCollideB1") or Instance.new("Folder", Y); cf.Name = "RoadCollideB1"
			local n = M.place(game.ServerStorage.RoadMeshHolding_1, mf)
			local b = 0
			for k = 1, 99 do
				local mod = game.ServerStorage.YangonData:FindFirstChild("RoadCollide_1_" .. k)
				if not mod then break end
				b += M.collide(require(mod), cf)
			end
			return n .. " meshes, " .. b .. " boxes"
		end)
		print(M.status())
]]

local SS = game:GetService("ServerStorage")

local M = {}

M.LOOK = {
	R = { Enum.Material.Asphalt, Color3.fromRGB(46, 47, 50) },
	P = { Enum.Material.Sandstone, Color3.fromRGB(128, 124, 116) },
	KR = { Enum.Material.Concrete, Color3.fromRGB(186, 34, 34) },
	KW = { Enum.Material.Concrete, Color3.fromRGB(232, 230, 224) },
	KG = { Enum.Material.Concrete, Color3.fromRGB(150, 146, 138) },
	L = { Enum.Material.SmoothPlastic, Color3.fromRGB(232, 232, 226) },
	MG = { Enum.Material.Grass, Color3.fromRGB(84, 116, 58) },
	B = { Enum.Material.Concrete, Color3.fromRGB(150, 146, 138) },
	F = { Enum.Material.Concrete, Color3.fromRGB(104, 102, 98) }, -- flush edge strips of residential streets
}

-- box thickness under the top, and the extra lift of the top over the line's cy, per collision kind
M.THICK = { R = 2, P = 2.5, M = 2.5, J = 2, D = 3, W = 5.5 }

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
	local cell = string.match(id, "^(.-)s%d+$") or id
	return kind, cell, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

function M.place(holding: Instance, folder: Instance, opts: any?): number
	local o = opts or {}
	local n = 0
	local cells = {}
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local kind, cell, c, size = M.parse(d.Name)
			if not kind and d.Parent then
				kind, cell, c, size = M.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			local look = kind and M.LOOK[kind]
			if look then
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
				q.Name = "RMesh" .. kind
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
				q.CastShadow = kind == "B"
				q.DoubleSided = false
				q.Material = look[1]
				q.Color = look[2]
				q.TextureID = ""
				pcall(function()
					q.RenderFidelity = Enum.RenderFidelity.Automatic
				end)
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
		local v = {}
		local kind = nil
		for w in string.gmatch(line, "%S+") do
			local x = tonumber(w)
			if x then
				table.insert(v, x)
			else
				kind = w
			end
		end
		if #v >= 7 then
			kind = kind or "R"
			local thick = M.THICK[kind] or 2
			local c = Vector3.new(v[1], v[2] + (o.lift or 0), v[3])
			local d = Vector3.new(v[4], v[5], v[6])
			local len = d.Magnitude
			if len > 0.05 then
				local fwd = d.Unit
				local flat = Vector3.new(fwd.X, 0, fwd.Z)
				local right = if flat.Magnitude > 1e-3 then Vector3.new(-flat.Unit.Z, 0, flat.Unit.X) else Vector3.xAxis
				local up = right:Cross(fwd).Unit
				if up.Y < 0 then
					up = -up
					right = -right
				end
				local p = Instance.new("Part")
				p.Name = "RCol"
				p.Anchored = true
				p.Size = Vector3.new(v[7], thick, len)
				-- (CFrame.fromMatrix: right = X, up = Y, back = Z; the box's top is cy)
				p.CFrame = CFrame.fromMatrix(c - up * (thick / 2), right, up, -fwd)
				p.Transparency = 1
				p.CanCollide = true
				p.CanQuery = true
				p.CanTouch = false
				p.CastShadow = false
				p.TopSurface = Enum.SurfaceType.Smooth
				p.BottomSurface = Enum.SurfaceType.Smooth
				p:SetAttribute("RoadBox", kind)
				p.Parent = folder
				n += 1
				if n % 300 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

function M.undo(tag: string): number
	local n = 0
	for _, name in { "RoadMeshesB" .. tag, "RoadCollideB" .. tag } do
		local f = workspace.Yangon:FindFirstChild(name)
		if f then
			f:Destroy()
			n += 1
		end
	end
	return n
end

function M.spawn(fn)
	SS:SetAttribute("RoadMeshStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		SS:SetAttribute("RoadMeshStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS:GetAttribute("RoadMeshStatus"))
end

return M
