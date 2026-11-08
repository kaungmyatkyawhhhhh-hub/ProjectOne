--[[
	DetailsApply (Studio, Edit mode; owner, 2026-11-06, `Prompts/Small design changes on famous new cars.md`): puts the
	parts from tools/details.py into ReplicatedStorage.CarModels, and the new grille pictures from
	tools/details_tiles.py on their parts' SurfaceAppearances.

	Upload imports/details/<car id>.fbx through Open Cloud (group 33151111), insert_asset the Model into
	ServerStorage.DetailsHolding, then
	    DetailsApply.run(carId, modelName, report)          report = the <fbx>.json as a table
	    DetailsApply.tiles(carId, { Body_Grille = { colour = "rbxassetid://..", normal = "rbxassetid://.." } })
	    DetailsApply.undo(carId)                            everything back (parts and pictures)

	Same placing as RetextApply: Roblox model space is (-x, z, y) of the file's; a part moves by how far its box's middle
	moved. A replaced part keeps its look (colour, material, texture, SurfaceAppearance, attributes) and goes to
	ServerStorage.DetailsOld.<car id>. Old picture ids are kept on the SurfaceAppearance (attributes OldColorMap,
	OldNormalMap) for undo.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DetailsApply = {}

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function toModel(d: Vector3): Vector3
	return Vector3.new(-d.X, d.Z, d.Y)
end

local function middle(box): Vector3
	return (vec(box[1]) + vec(box[2])) / 2
end

local function carOf(carId: string): Model
	return ReplicatedStorage.CarModels:FindFirstChild(carId, true) :: Model
end

local function find(car: Instance, name: string, box): MeshPart?
	local size = toModel(vec(box[2]) - vec(box[1]))
	size = Vector3.new(math.abs(size.X), math.abs(size.Y), math.abs(size.Z))
	local best, bd = nil, math.huge
	for _, p in car:GetChildren() do
		if p:IsA("MeshPart") and p.Name == name then
			local d = (p.Size - size).Magnitude
			if d < bd then
				best, bd = p, d
			end
		end
	end
	return best
end

local function copyLook(from: MeshPart, to: MeshPart)
	for _, prop in { "Color", "Material", "MaterialVariant", "Reflectance", "Transparency", "CastShadow", "CanCollide",
		"CanQuery", "CanTouch", "Anchored", "TextureID", "DoubleSided" } do
		pcall(function()
			(to :: any)[prop] = (from :: any)[prop]
		end)
	end
	for name, value in from:GetAttributes() do
		to:SetAttribute(name, value)
	end
	for _, c in to:GetChildren() do
		c:Destroy()
	end
	for _, c in from:GetChildren() do
		if not c:IsA("JointInstance") and not c:IsA("WeldConstraint") then
			c:Clone().Parent = to
		end
	end
end

local function keepFolder(carId: string): Folder
	local old = ServerStorage:FindFirstChild("DetailsOld") or Instance.new("Folder")
	old.Name = "DetailsOld"
	old.Parent = ServerStorage
	local keep = old:FindFirstChild(carId) or Instance.new("Folder")
	keep.Name = carId
	keep.Parent = old
	return keep :: Folder
end

function DetailsApply.run(carId: string, modelName: string, report: any): { string }
	local car = carOf(carId)
	local model = ServerStorage.DetailsHolding[modelName]
	local keep = keepFolder(carId)
	local out = {}
	for name, r in report do
		if name == "__like" then
			continue
		end
		local new: MeshPart? = nil
		for _, d in model:GetDescendants() do
			if d:IsA("MeshPart") and d.Name == name then
				new = d
				break
			end
		end
		if not new then
			table.insert(out, "no mesh for " .. name)
			continue
		end
		local partName = r.part or name
		local base = r.before and find(car, partName, r.before)
		if not base then
			table.insert(out, "no base for " .. name)
			continue
		end
		local size = toModel(vec(r.after[2]) - vec(r.after[1]))
		size = Vector3.new(math.abs(size.X), math.abs(size.Y), math.abs(size.Z))
		local q = (new :: MeshPart):Clone()
		local pl = q:FindFirstChildOfClass("PackageLink")
		if pl then
			pl:Destroy()
		end
		q.CFrame = CFrame.new(base.Position + toModel(middle(r.after) - middle(r.before)))
		local real = (new :: MeshPart).MeshSize / 100
		q.Size = if (real - size).Magnitude < 0.3 then real else size
		q.Name = partName
		copyLook(base, q)
		q:SetAttribute("Details", true)
		q.Parent = base.Parent
		base.Parent = keep
		table.insert(out, string.format("%s ok (size %.3f, %.3f, %.3f; was %.3f, %.3f, %.3f)", name, q.Size.X, q.Size.Y, q.Size.Z,
			base.Size.X, base.Size.Y, base.Size.Z))
	end
	return out
end

function DetailsApply.tiles(carId: string, tiles: { [string]: { colour: string?, normal: string? } }): { string }
	local car = carOf(carId)
	local out = {}
	for name, t in tiles do
		local p = car:FindFirstChild(name)
		local sa = p and p:FindFirstChildOfClass("SurfaceAppearance")
		if not sa then
			-- (a part with only a TextureID: the colour picture goes there, a normal picture can't)
			if p and p:IsA("MeshPart") and t.colour then
				if p:GetAttribute("OldTextureID") == nil then
					p:SetAttribute("OldTextureID", p.TextureID)
				end
				p.TextureID = t.colour
				table.insert(out, name .. " texture ok")
			else
				table.insert(out, "nothing to change on " .. name)
			end
			continue
		end
		if sa:GetAttribute("OldColorMap") == nil then
			sa:SetAttribute("OldColorMap", sa.ColorMap)
			sa:SetAttribute("OldNormalMap", sa.NormalMap)
		end
		if t.colour then
			sa.ColorMap = t.colour
		end
		if t.normal then
			sa.NormalMap = t.normal
		end
		table.insert(out, name .. " tiles ok")
	end
	return out
end

function DetailsApply.undo(carId: string)
	local car = carOf(carId)
	local keep = ServerStorage.DetailsOld:FindFirstChild(carId)
	for _, q in car:GetChildren() do
		if q:GetAttribute("Details") then
			q:Destroy()
		end
	end
	if keep then
		for _, p in keep:GetChildren() do
			p.Parent = car
		end
	end
	for _, p in car:GetDescendants() do
		if p:IsA("MeshPart") and p:GetAttribute("OldTextureID") ~= nil then
			p.TextureID = p:GetAttribute("OldTextureID")
			p:SetAttribute("OldTextureID", nil)
		end
	end
	for _, sa in car:GetDescendants() do
		if sa:IsA("SurfaceAppearance") and sa:GetAttribute("OldColorMap") ~= nil then
			sa.ColorMap = sa:GetAttribute("OldColorMap")
			sa.NormalMap = sa:GetAttribute("OldNormalMap")
			sa:SetAttribute("OldColorMap", nil)
			sa:SetAttribute("OldNormalMap", nil)
		end
	end
end

return DetailsApply
