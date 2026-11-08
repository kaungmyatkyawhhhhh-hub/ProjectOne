--[[
	DoorsApply (Studio, Edit mode; owner, 2026-11-08, `Prompts/Scissor doors on the SVJ and SVJ 63 (cut properly).md`):
	makes ReplicatedStorage.CarModels.<car id>@doors from the car's model and the parts of tools/doors.py. The car's own
	model stays as it is: with Config.Doors[<car id>] off the game uses it, so going back is one switch.

	Upload imports/doors/<car id>.fbx through Open Cloud (group 33151111), InsertService:LoadAsset it into
	ServerStorage.DoorsHolding.<car id> (a folder per car: the cars share part names), then
	    DoorsApply.run(carId, report)      report = the <fbx>.json as a table; returns lines to read
	    DoorsApply.undo(carId)             takes <car id>@doors away (the car's own model was never touched)

	The new model: the body parts the doors came out of are swapped for the cut ones (each keeps its look: colour,
	material, texture, SurfaceAppearance, attributes); Doors/Door_L and Doors/Door_R hold each door's parts (named like the
	part they came from, with that part's look) and a Hinge part: its position is the hinge, its X axis the turning axis
	(the door's back goes up for a positive turn), attribute Open = how far it opens (degrees). A part the doors took
	whole (report "after" = null) is dropped; report "covers" (Body_JambCover) are new plain black parts.
	Placing (as DetailsApply): Roblox model space is (-x, z, y) of the file's; a part moves by how far its box's middle
	moved, and a new part sits where the car's paint part says the file's origin is.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DoorsApply = {}

local function vec(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end

local function toModel(d: Vector3): Vector3
	return Vector3.new(-d.X, d.Z, d.Y)
end

local function middle(box): Vector3
	return (vec(box[1]) + vec(box[2])) / 2
end

local function sizeOf(box): Vector3
	local s = toModel(vec(box[2]) - vec(box[1]))
	return Vector3.new(math.abs(s.X), math.abs(s.Y), math.abs(s.Z))
end

local function folder(): Instance
	return ReplicatedStorage:FindFirstChild("CarModels", true) :: Instance
end

-- the car's own part of that name whose size matches the file's box
local function find(car: Instance, name: string, box): MeshPart?
	local size = sizeOf(box)
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

local function meshNamed(model: Instance, name: string): MeshPart?
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == name then
			return d
		end
	end
	return nil
end

local function placed(new: MeshPart, pos: Vector3, box): MeshPart
	local q = new:Clone()
	local pl = q:FindFirstChildOfClass("PackageLink")
	if pl then
		pl:Destroy()
	end
	q.CFrame = CFrame.new(pos)
	local size = sizeOf(box)
	local real = new.MeshSize / 100
	q.Size = if (real - size).Magnitude < 0.3 then real else size
	return q
end

-- a plain black cover part (Body_JambCover: the backs of one-sided faces round the opening, and in each door)
local function blackCover(q: MeshPart, car: Instance, rgb: { number }?)
	for _, c in q:GetChildren() do
		c:Destroy()
	end
	local like = car:FindFirstChildWhichIsA("MeshPart")
	q.Anchored = if like then like.Anchored else true
	q.CanCollide = false
	q.CanQuery = false
	q.CanTouch = false
	q.CastShadow = false
	q.Material = Enum.Material.SmoothPlastic
	q.TextureID = ""
	q.Transparency = 0
	local c = rgb or { 0.02, 0.02, 0.02 }
	q.Color = Color3.new(c[1], c[2], c[3])
end

function DoorsApply.run(carId: string, report: any): { string }
	local out = {}
	local cars = folder()
	local own = cars:FindFirstChild(carId) :: Model
	-- (each car's upload in its own folder DoorsHolding/<car id>: the cars share part names)
	local holding = ServerStorage:FindFirstChild("DoorsHolding")
	local mine = if holding then holding:FindFirstChild(carId) else nil
	if mine then
		holding = mine
	end
	if not (own and holding) then
		return { "no car model or no DoorsHolding" }
	end
	local old = cars:FindFirstChild(carId .. "@doors")
	if old then
		old:Destroy()
	end
	local car = own:Clone()
	car.Name = carId .. "@doors"
	car:SetAttribute("CarId", carId)
	car:SetAttribute("Doors", true)
	-- where the file's origin is in this model (from the paint part, which every report has)
	local origin: Vector3? = nil
	for name, r in report.parts do
		local base = find(own, name, r.before)
		if base then
			origin = base.Position - toModel(middle(r.before))
			break
		end
	end
	if not origin then
		return { "no part of the report found in " .. carId }
	end
	-- the body parts the doors came out of
	for name, r in report.parts do
		local base = find(car, name, r.before)
		if base and r.after == nil then
			-- (the doors took all of it: e.g. a part that was only the two mirrors)
			local was = (base :: MeshPart).Size
			;(base :: MeshPart):Destroy()
			table.insert(out, string.format("%s all in the doors (removed; was %.2f %.2f %.2f)", name, was.X, was.Y, was.Z))
			continue
		end
		local new = meshNamed(holding, name)
		if not (base and new) then
			table.insert(out, "missing " .. name .. (if base then " (mesh)" else " (part)"))
			continue
		end
		local q = placed(new :: MeshPart, (base :: MeshPart).Position + toModel(middle(r.after) - middle(r.before)), r.after)
		q.Name = name
		copyLook(base :: MeshPart, q)
		q.Parent = (base :: MeshPart).Parent
		local was = (base :: MeshPart).Size
		;(base :: MeshPart):Destroy()
		table.insert(out, string.format("%s cut (%d faces; size %.2f %.2f %.2f, was %.2f %.2f %.2f)", name, r.faces, q.Size.X, q.Size.Y, q.Size.Z, was.X, was.Y, was.Z))
	end
	-- the doors
	local doors = Instance.new("Folder")
	doors.Name = "Doors"
	doors.Parent = car
	for side, d in report.doors do
		local m = Instance.new("Model")
		m.Name = "Door_" .. side
		m.Parent = doors
		for key, r in d.parts do
			local new = meshNamed(holding, key)
			local look = own:FindFirstChild(r.part)
			-- (the door's own black backs have no part of that name in the car)
			local isCover = string.sub(r.part, 1, 14) == "Body_JambCover"
			if not (new and (isCover or (look and look:IsA("MeshPart")))) then
				table.insert(out, "missing door part " .. key)
				continue
			end
			local q = placed(new :: MeshPart, origin + toModel(middle(r.after)), r.after)
			q.Name = r.part
			if isCover then
				blackCover(q, car, r.color)
			else
				copyLook(look :: MeshPart, q)
			end
			q:SetAttribute("Door", side)
			q.Parent = m
		end
		local hinge = Instance.new("Part")
		hinge.Name = "Hinge"
		hinge.Size = Vector3.new(0.05, 0.05, 0.05)
		hinge.Transparency = 1
		hinge.Anchored = true
		hinge.CanCollide = false
		hinge.CanQuery = false
		hinge.CanTouch = false
		local axis = toModel(vec(d.axis)).Unit
		local up = if math.abs(axis.Y) < 0.9 then Vector3.yAxis else Vector3.zAxis
		local back = axis:Cross(up).Unit
		up = back:Cross(axis).Unit
		hinge.CFrame = CFrame.fromMatrix(origin + toModel(vec(d.hinge)), axis, up, back)
		hinge:SetAttribute("Open", d.open)
		hinge.Parent = m
		table.insert(out, string.format("Door_%s: %d parts, hinge (%.3f, %.3f, %.3f), axis (%.3f, %.3f, %.3f), opens %d", side, #m:GetChildren() - 1,
			hinge.Position.X - car:GetPivot().X, hinge.Position.Y - car:GetPivot().Y, hinge.Position.Z - car:GetPivot().Z, axis.X, axis.Y, axis.Z, d.open))
	end
	-- the black jamb cover (owner, same day: the jamb was see-through with the door up): a plain black part behind the
	-- body's one-sided faces round the door opening
	for name, r in (report.covers or {}) :: { [string]: any } do
		local new = meshNamed(holding, name)
		if not new then
			table.insert(out, "missing cover " .. name)
			continue
		end
		local q = placed(new :: MeshPart, origin + toModel(middle(r.after)), r.after)
		q.Name = name
		blackCover(q, car, r.color)
		q.Parent = car
		table.insert(out, string.format("%s added (%d faces)", name, r.faces))
	end
	car.Parent = cars
	return out
end

function DoorsApply.undo(carId: string)
	local m = folder():FindFirstChild(carId .. "@doors")
	if m then
		m:Destroy()
	end
end

return DoorsApply
