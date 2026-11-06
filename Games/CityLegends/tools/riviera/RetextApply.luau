--[[
	RetextApply (Studio, Edit mode; owner, 2026-11-06): puts the parts from tools/retext.py into ReplicatedStorage.CarModels.

	Upload imports/retext/<car id>.fbx through Open Cloud (group 33151111), insert_asset the Model into
	ServerStorage.RetextHolding, then RetextApply.run(carId, modelName, report), report = the <fbx>.json as a table.

	A part that was there gets the new mesh and keeps its look (texture, SurfaceAppearance, colour); a new part
	(report.__like[name] = the box of the part it copies, like[name] = that part's name) copies its look from there.
	The file's coordinates are the car's: Roblox model space is (-x, z, y) of them. A part moves by how far its box's
	middle moved, and its Size is the new box. The old parts go to ServerStorage.RetextOld.<car id>; undo puts them back.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RetextApply = {}

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function toModel(d: Vector3): Vector3
	return Vector3.new(-d.X, d.Z, d.Y)
end

local function middle(box): Vector3
	return (vec(box[1]) + vec(box[2])) / 2
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
	to.Color = from.Color
	to.Material = from.Material
	to.MaterialVariant = from.MaterialVariant
	to.Reflectance = from.Reflectance
	to.Transparency = from.Transparency
	to.CastShadow = from.CastShadow
	to.CanCollide = from.CanCollide
	to.CanQuery = from.CanQuery
	to.CanTouch = from.CanTouch
	to.Anchored = from.Anchored
	to.TextureID = from.TextureID
	for name, value in from:GetAttributes() do
		to:SetAttribute(name, value)
	end
	for _, c in to:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	for _, c in from:GetChildren() do
		if not c:IsA("JointInstance") and not c:IsA("WeldConstraint") then
			c:Clone().Parent = to
		end
	end
end

function RetextApply.run(carId: string, modelName: string, report: any, like: { [string]: string }?): { string }
	local car = ReplicatedStorage.CarModels[carId]
	local holding = ServerStorage.RetextHolding
	local model = holding[modelName]
	local old = ServerStorage:FindFirstChild("RetextOld") or Instance.new("Folder")
	old.Name = "RetextOld"
	old.Parent = ServerStorage
	local keep = old:FindFirstChild(carId) or Instance.new("Folder")
	keep.Name = carId
	keep.Parent = old
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
		local size = toModel(vec(r.after[2]) - vec(r.after[1]))
		size = Vector3.new(math.abs(size.X), math.abs(size.Y), math.abs(size.Z))
		local q = new:Clone()
		local pl = q:FindFirstChildOfClass("PackageLink")
		if pl then
			pl:Destroy()
		end
		local base: MeshPart?
		local partName = r.part or name
		if r.before then
			base = find(car, partName, r.before)
			if base then
				q.CFrame = CFrame.new(base.Position + toModel(middle(r.after) - middle(r.before)))
			end
		else
			local likeName = like and like[name]
			base = likeName and find(car, likeName, report.__like[name]) or nil
			if base then
				q.CFrame = CFrame.new(base.Position + toModel(middle(r.after) - middle(report.__like[name])))
			end
		end
		if not base then
			table.insert(out, "no base for " .. name)
			q:Destroy()
			continue
		end
		-- (a box can hold stray points the mesh doesn't: the mesh's own size is the true one, 100 to a stud in these files)
		local real = new.MeshSize / 100
		q.Size = if (real - size).Magnitude < 0.3 then real else size
		q.Name = partName
		copyLook(base, q)
		q:SetAttribute("Retext", true)
		q.Parent = car
		if r.before then
			base.Parent = keep
		end
		table.insert(out, name .. " ok")
	end
	return out
end

function RetextApply.undo(carId: string)
	local car = ReplicatedStorage.CarModels[carId]
	local keep = ServerStorage.RetextOld:FindFirstChild(carId)
	-- (the Veyrons have many parts of one name: only the parts this tool made go)
	for _, q in car:GetChildren() do
		if q:GetAttribute("Retext") then
			q:Destroy()
		end
	end
	for _, p in keep:GetChildren() do
		p.Parent = car
	end
end

return RetextApply
