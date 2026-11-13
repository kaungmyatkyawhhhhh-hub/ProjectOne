--[[
	YangonGreen (Studio, Edit mode; Yangon batch 0.5 accuracy pass, 14 Nov 2026, owner: "the inya lake have borders and stuff
	in real life and theres like a park", "do everything").

	Builds from ServerStorage.ClaudeTools.YangonGreenData (tools/yangon/d20_green.py, one string):
	  * the Inya Kan Baung embankments (S lines): along the shore where it runs beside a main road, a concrete edge from under
	    the water up to the bank with a low parapet on the water side, a light walkway 8 wide behind it;
	  * benches (B) on the walkway facing the water, small walkway lamps (L: white head tagged LampGlow, a PointLight tagged
	    LODLight / DayOff: WorldFx switches them at night and by distance);
	  * trees: the embankment rows and the parks (P) and the city (T: rain trees and mango trees = Monaco's broad "Tree", palms =
	    "Palm" / "PalmA"), kits copied once into ServerStorage.YangonData.GreenKit so they survive Monaco moving.
	Everything goes in Workspace.Yangon.Green (cleared first). Heights come from rays: the terrain, the water's surface.

	local G = require(ServerStorage.ClaudeTools.YangonGreen:Clone())
	G.spawn(function() return G.build() end)   then G.status()
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

function M.kit(): Folder
	local YD = SS.YangonData
	local kit = YD:FindFirstChild("GreenKit")
	if kit then
		return kit :: Folder
	end
	kit = Instance.new("Folder")
	kit.Name = "GreenKit"
	local D = SS:FindFirstChild("Riviera") and SS.Riviera:FindFirstChild("Dressing") or workspace:FindFirstChild("Riviera") and workspace.Riviera.Dressing
	for _, name in { "Tree", "Palm", "PalmA" } do
		local m = D and D:FindFirstChild(name, true)
		if m then
			local c = m:Clone()
			for _, d in c:GetDescendants() do
				if d:IsA("Script") or d:IsA("LocalScript") then
					d:Destroy()
				end
			end
			c.Parent = kit
		end
	end
	kit.Parent = YD
	return kit :: Folder
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

-- a tree from the kit, its foot on the ground, scaled to about `wide` studs across, turned by `yaw`
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
			-- (the canopy never stops a car; the trunk does)
			if d.Size.Y < sz.Y * 0.6 or d.Position.Y > g + sz.Y * 0.45 then
				d.CanCollide = false
			end
		end
	end
	t.Name = "YangonTree"
	t.Parent = parent
	return t
end

-- (14 Nov 2026, playtest: the grass fill behind the walkway rose up to 1.2 over it (terrain is 4-stud voxels) and buried every
-- walkway: each walkway is raised to just over the ground under it (its bottom stays), its parapet and edge with it, and the
-- benches stood back on it)
function M.lift(bank: Instance): number
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	rp.IgnoreWater = true
	local walks, pars, edges = {}, {}, {}
	for _, p in bank:GetChildren() do
		if p.Name == "Walkway" then
			table.insert(walks, p)
		elseif p.Name == "Parapet" then
			table.insert(pars, p)
		elseif p.Name == "BankEdge" then
			table.insert(edges, p)
		end
	end
	local function nearest(list, w)
		local best, bd = nil, 1e9
		for _, q in list do
			local d = ((q.Position - w.Position) * Vector3.new(1, 0, 1)).Magnitude
			if d < bd and q.CFrame.LookVector:Dot(w.CFrame.LookVector) > 0.99 then
				best, bd = q, d
			end
		end
		return if bd < 9 then best else nil
	end
	local raised = 0
	for _, w in walks do
		local top = w.Position.Y + w.Size.Y / 2
		local mt = -1e9
		for _, u in { -0.45, -0.2, 0, 0.2, 0.45 } do
			for _, v in { -3.5, 0, 3.5 } do
				local p = (w.CFrame * CFrame.new(u * w.Size.X, 0, v)).Position
				local h = workspace:Raycast(Vector3.new(p.X, top + 20, p.Z), Vector3.new(0, -40, 0), rp)
				if h and h.Position.Y > mt then
					mt = h.Position.Y
				end
			end
		end
		local d = mt + 0.12 - top
		if d > 0 then
			local par, edge = nearest(pars, w), nearest(edges, w)
			w.Size += Vector3.new(0, d, 0)
			w.CFrame += Vector3.new(0, d / 2, 0)
			if par then
				par.CFrame += Vector3.new(0, d, 0)
			end
			if edge then
				edge.Size += Vector3.new(0, d, 0)
				edge.CFrame += Vector3.new(0, d / 2, 0)
			end
			raised += 1
		end
	end
	for _, m in bank:GetChildren() do
		if m.Name == "Bench" then
			local ex = RaycastParams.new()
			ex.FilterType = Enum.RaycastFilterType.Exclude
			ex.FilterDescendantsInstances = { m }
			local cf, size = m:GetBoundingBox()
			local bottom = cf.Position.Y - size.Y / 2
			local h = workspace:Raycast(cf.Position + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), ex)
			if h and h.Instance.Name == "Walkway" then
				m:PivotTo(m:GetPivot() + Vector3.new(0, h.Position.Y - bottom, 0))
			end
		end
	end
	return raised
end

function M.build(): string
	local Y = workspace.Yangon
	local old = Y:FindFirstChild("Green")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Green"
	folder.Parent = Y
	local bank = Instance.new("Folder")
	bank.Name = "Embankment"
	bank.Parent = folder
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
	withWater.FilterDescendantsInstances = { workspace.Terrain }
	local kit = M.kit()
	local data = require(SS.ClaudeTools.YangonGreenData:Clone())
	local n = { S = 0, P = 0, T = 0, B = 0, L = 0, miss = 0 }
	local rng = Random.new(1411)
	local i = 0
	for line in string.gmatch(data, "[^\n]+") do
		i += 1
		local tag = string.sub(line, 1, 1)
		local v = {}
		for w in string.gmatch(string.sub(line, 3), "%S+") do
			table.insert(v, tonumber(w) or w)
		end
		if tag == "S" then
			local a, b = Vector3.new(v[1], 0, v[2]), Vector3.new(v[3], 0, v[4])
			local nrm = Vector3.new(v[5], 0, v[6]).Unit
			local mid = (a + b) / 2
			local len = (b - a).Magnitude
			local wy = waterTop((mid - nrm * 6).X, (mid - nrm * 6).Z) or waterTop((mid - nrm * 14).X, (mid - nrm * 14).Z)
			local gy = ground((mid + nrm * 8).X, (mid + nrm * 8).Z)
			if wy and gy then
				local top = math.max(gy, wy + 2.5) + 0.3
				-- (frame: looking out over the water, so its X runs along the shore; inland is behind it)
				local frame = CFrame.lookAt(Vector3.new(mid.X, 0, mid.Z), Vector3.new(mid.X, 0, mid.Z) - nrm)
				local inland = nrm
				local edgeBottom = wy - 4
				local edgeH = top - edgeBottom
				box("BankEdge", Vector3.new(len + 0.6, edgeH, 2), CFrame.new(Vector3.new(mid.X, edgeBottom + edgeH / 2, mid.Z) + inland * 0.6) * frame.Rotation, EDGE, Enum.Material.Concrete, bank)
				box("Parapet", Vector3.new(len + 0.6, 1.4, 0.8), CFrame.new(Vector3.new(mid.X, top + 0.7, mid.Z) + inland * 0.2) * frame.Rotation, EDGE:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Concrete, bank)
				local walk = box("Walkway", Vector3.new(len + 0.6, 1, 8), CFrame.new(Vector3.new(mid.X, top - 0.5, mid.Z) + inland * 5.6) * frame.Rotation, WALK, Enum.Material.Pavement, bank)
				walk.CastShadow = false
				-- (the ground behind the walkway up to its edge: no gap under it)
				workspace.Terrain:FillBlock(CFrame.new(Vector3.new(mid.X, top - 3, mid.Z) + inland * 5.6) * frame.Rotation, Vector3.new(len + 2, 4, 9), Enum.Material.Grass)
				n.S += 1
			else
				n.miss += 1
			end
		elseif tag == "B" then
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
		elseif tag == "L" then
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
		elseif tag == "P" then
			local kind = if rng:NextNumber() < 0.75 then "Tree" else (if rng:NextNumber() < 0.5 then "Palm" else "PalmA")
			if tree(kit, kind, v[1], v[2], if kind == "Tree" then rng:NextNumber(30, 46) else rng:NextNumber(18, 26), rng:NextNumber(0, math.pi * 2), trees) then
				n.P += 1
			else
				n.miss += 1
			end
		elseif tag == "T" then
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
	M.lift(bank)
	local parts = 0
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	return string.format("embankment %d pieces, %d benches, %d lamps; trees: %d by the lake and in parks, %d in the city; %d missed; %d parts", n.S, n.B, n.L, n.P, n.T, n.miss, parts)
end

function M.spawn(fn)
	local YD = SS.YangonData
	YD:SetAttribute("GreenStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		YD:SetAttribute("GreenStatus", string.format("%s after %.0f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("GreenStatus"))
end

return M
