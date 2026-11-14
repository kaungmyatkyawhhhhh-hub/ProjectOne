--[[
	YangonGreenBatch (Studio, Edit mode; whole-Yangon map, 14 Nov 2026): the trees and lake embankments of a BATCH (1, 2, 3).

	YangonGreen.luau (the lead's) builds batch 0.5 from ClaudeTools.YangonGreenData into Workspace.Yangon.Green and clears that
	folder first. This file does the same for a batch WITHOUT touching it: the data is ClaudeTools.YangonGreenData_<t>_1 .. n
	(tools/yangon/city/green.py <t>, one string each, the same line format: S shore segment, P park tree, T city tree, B bench,
	L walkway lamp), the result goes into Workspace.Yangon.Green_<t> (Embankment + Trees), cleared first. It reuses
	YangonGreen's own pieces: its kit (YangonGreen.kit(): ServerStorage.YangonData.GreenKit, Monaco's Tree / Palm / PalmA) and its
	walkway lift (YangonGreen.lift(bank): raises each walkway over the 4-stud terrain cells after the grass fill). The
	embankment, bench, lamp and tree builders below are YangonGreen.build's code, unchanged (they are local there).
	Kandawgyi Lake gets an embankment + walkway all round its shore (its boardwalk); trees stand on the terrain (rays).

	local G = require(game.ServerStorage.ClaudeTools.YangonGreenBatch:Clone())
	G.spawn("1")   then   G.status("1")      -> Workspace.Yangon.Green_1
	G.undo("1")
]]

local SS = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local M = {}

local EDGE = Color3.fromRGB(176, 172, 164)
local WALK = Color3.fromRGB(196, 190, 178)
local BENCH = Color3.fromRGB(120, 84, 56)
local IRON = Color3.fromRGB(40, 42, 46)
local LAMP_HEAD = Color3.fromRGB(236, 244, 255)

local function box(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material, parent: Instance, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = col
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide ~= false
	p.CastShadow = size.Y > 2
	p.Parent = parent
	return p
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.IgnoreWater = true
local withWater = RaycastParams.new()
withWater.FilterType = Enum.RaycastFilterType.Include
withWater.IgnoreWater = false

local function ground(x: number, z: number): number?
	local h = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -600, 0), terrainOnly)
	return h and h.Position.Y
end

local function waterTop(x: number, z: number): number?
	local h = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -600, 0), withWater)
	if h and h.Material == Enum.Material.Water then
		return h.Position.Y
	end
	return nil
end

local function tree(kit: Folder, name: string, x: number, z: number, wide: number, yaw: number, parent: Instance): Model?
	local src = kit:FindFirstChild(name) :: Model?
	if not src then
		return nil
	end
	local g = ground(x, z)
	if not g then
		return nil
	end
	local t = src:Clone()
	local _, size = t:GetBoundingBox()
	t:ScaleTo(t:GetScale() * (wide / math.max(size.X, size.Z)))
	local cf, sz = t:GetBoundingBox()
	local foot = CFrame.new(x, g - 0.4, z) * CFrame.Angles(0, yaw, 0)
	t:PivotTo(foot * (CFrame.new(cf.Position - Vector3.new(0, sz.Y / 2, 0)):Inverse() * t:GetPivot()))
	for _, d in t:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d.Size.Y < sz.Y * 0.6 or d.Position.Y > g + sz.Y * 0.45 then
				d.CanCollide = false
			end
		end
	end
	t.Name = "YangonTree"
	t.Parent = parent
	return t
end

local function data(tag: string): string
	local parts = {}
	for i = 1, 99 do
		local m = SS.ClaudeTools:FindFirstChild("YangonGreenData_" .. tag .. "_" .. i)
		if not m then
			break
		end
		table.insert(parts, require((m :: ModuleScript):Clone()))
	end
	assert(#parts > 0, "no YangonGreenData_" .. tag .. "_1 in ServerStorage.ClaudeTools")
	return table.concat(parts, "\n")
end

function M.build(tag: string): string
	tag = tostring(tag)
	local G = require(SS.ClaudeTools.YangonGreen:Clone())
	local Y = workspace.Yangon
	local old = Y:FindFirstChild("Green_" .. tag)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Green_" .. tag
	folder.Parent = Y
	local bank = Instance.new("Folder")
	bank.Name = "Embankment"
	bank.Parent = folder
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
	withWater.FilterDescendantsInstances = { workspace.Terrain }
	local kit = G.kit()
	local n = { S = 0, P = 0, T = 0, B = 0, L = 0, miss = 0 }
	local rng = Random.new(1411 + (tonumber(tag) or 0))
	local i = 0
	for line in string.gmatch(data(tag), "[^\n]+") do
		i += 1
		local key = string.sub(line, 1, 1)
		local v = {}
		for w in string.gmatch(string.sub(line, 3), "%S+") do
			table.insert(v, tonumber(w) or w)
		end
		if key == "S" then
			local a, b = Vector3.new(v[1], 0, v[2]), Vector3.new(v[3], 0, v[4])
			local nrm = Vector3.new(v[5], 0, v[6]).Unit
			local mid = (a + b) / 2
			local len = (b - a).Magnitude
			local wy = waterTop((mid - nrm * 6).X, (mid - nrm * 6).Z) or waterTop((mid - nrm * 14).X, (mid - nrm * 14).Z)
			local gy = ground((mid + nrm * 8).X, (mid + nrm * 8).Z)
			if wy and gy then
				local top = math.max(gy, wy + 2.5) + 0.3
				local frame = CFrame.lookAt(Vector3.new(mid.X, 0, mid.Z), Vector3.new(mid.X, 0, mid.Z) - nrm)
				local inland = nrm
				local edgeBottom = wy - 4
				local edgeH = top - edgeBottom
				box("BankEdge", Vector3.new(len + 0.6, edgeH, 2), CFrame.new(Vector3.new(mid.X, edgeBottom + edgeH / 2, mid.Z) + inland * 0.6) * frame.Rotation, EDGE, Enum.Material.Concrete, bank)
				box("Parapet", Vector3.new(len + 0.6, 1.4, 0.8), CFrame.new(Vector3.new(mid.X, top + 0.7, mid.Z) + inland * 0.2) * frame.Rotation, EDGE:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Concrete, bank)
				local walk = box("Walkway", Vector3.new(len + 0.6, 1, 8), CFrame.new(Vector3.new(mid.X, top - 0.5, mid.Z) + inland * 5.6) * frame.Rotation, WALK, Enum.Material.Pavement, bank)
				walk.CastShadow = false
				workspace.Terrain:FillBlock(CFrame.new(Vector3.new(mid.X, top - 3, mid.Z) + inland * 5.6) * frame.Rotation, Vector3.new(len + 2, 4, 9), Enum.Material.Grass)
				n.S += 1
			else
				n.miss += 1
			end
		elseif key == "B" then
			local g = ground(v[1], v[2])
			if g then
				local p = Vector3.new(v[1], g, v[2])
				local cf = CFrame.lookAt(p, p + Vector3.new(v[3], 0, v[4]))
				local m = Instance.new("Model")
				m.Name = "Bench"
				box("Seat", Vector3.new(5, 0.4, 1.6), cf * CFrame.new(0, 1.7, 0), BENCH, Enum.Material.Wood, m)
				box("Back", Vector3.new(5, 1.4, 0.3), cf * CFrame.new(0, 2.6, 0.75), BENCH, Enum.Material.Wood, m)
				box("Leg", Vector3.new(0.3, 1.7, 1.4), cf * CFrame.new(-2.1, 0.85, 0), IRON, Enum.Material.Metal, m)
				box("Leg", Vector3.new(0.3, 1.7, 1.4), cf * CFrame.new(2.1, 0.85, 0), IRON, Enum.Material.Metal, m)
				m.Parent = bank
				n.B += 1
			end
		elseif key == "L" then
			local g = ground(v[1], v[2])
			if g then
				local m = Instance.new("Model")
				m.Name = "WalkLamp"
				box("Post", Vector3.new(0.5, 11, 0.5), CFrame.new(v[1], g + 5.5, v[2]), IRON, Enum.Material.Metal, m)
				local head = box("Head", Vector3.new(1.4, 1.2, 1.4), CFrame.new(v[1], g + 11.4, v[2]), LAMP_HEAD, Enum.Material.Neon, m, false)
				CollectionService:AddTag(head, "LampGlow")
				local l = Instance.new("PointLight")
				l.Color = Color3.fromRGB(232, 240, 255)
				l.Range = 26
				l.Brightness = 2
				l.Shadows = false
				l.Parent = head
				CollectionService:AddTag(l, "LODLight")
				CollectionService:AddTag(l, "DayOff")
				m.Parent = bank
				n.L += 1
			end
		elseif key == "P" then
			local kind = if rng:NextNumber() < 0.75 then "Tree" else (if rng:NextNumber() < 0.5 then "Palm" else "PalmA")
			if tree(kit, kind, v[1], v[2], if kind == "Tree" then rng:NextNumber(30, 46) else rng:NextNumber(18, 26), rng:NextNumber(0, math.pi * 2), trees) then
				n.P += 1
			else
				n.miss += 1
			end
		elseif key == "T" then
			local s = v[3]
			local kind = if v[4] == "P" then (if rng:NextNumber() < 0.5 then "Palm" else "PalmA") else "Tree"
			local wide = if kind == "Tree" then (if v[4] == "R" then 34 else 24) * s else 18 * s
			if tree(kit, kind, v[1], v[2], wide, rng:NextNumber(0, math.pi * 2), trees) then
				n.T += 1
			else
				n.miss += 1
			end
		end
		if i % 150 == 0 then
			task.wait()
		end
	end
	G.lift(bank)
	local parts = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return string.format("batch %s: embankment %d pieces, %d benches, %d lamps; trees: %d in rows and parks, %d in the city; %d missed; %d parts",
		tag, n.S, n.B, n.L, n.P, n.T, n.miss, parts)
end

function M.undo(tag: string)
	local old = workspace.Yangon:FindFirstChild("Green_" .. tostring(tag))
	if old then
		old:Destroy()
	end
end

function M.status(tag: string): string
	return tostring(SS.YangonData:GetAttribute("GreenStatus_" .. tostring(tag)))
end

function M.spawn(tag: string)
	tag = tostring(tag)
	local YD = SS.YangonData
	YD:SetAttribute("GreenStatus_" .. tag, "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(M.build, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end, tag)
		YD:SetAttribute("GreenStatus_" .. tag, string.format("%s after %.0f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

return M
