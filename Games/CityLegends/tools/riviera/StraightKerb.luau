--[[
	Straight kerb across a curved road corner (Studio, Edit mode). Loaded into ServerStorage.RivieraTools
	by the MCP.

	(owner, 2026-11-03, picture of the Bay Link / Riviera Bay corner with a straight red line drawn from
	one kerb tip to the other: "can u make the road like that instead of curving it?"): the road edge
	becomes the straight line from a to b (both on the road edge, the road on the side `side` points
	to). Everything between that line and the old kerb is paved over: pieces ISLAND_UP over the road
	(0.06 under the old pavement's top, so where they overlap the old pavement shows, no flicker), a
	kerb along the new line, and the old kerb pieces inside the new pavement (they'd stick up through
	it) and the road lines under it are removed. The traffic lanes are moved in RivieraLanes.lua.

	StraightKerb.build(roadName, a, b, side, parent) -> pieces made, pieces removed
	(side: a unit vector across the line pointing to the road; parent: e.g. Workspace.Riviera.Dressing)
]]

local StraightKerb = {}

local STEP = 6
local FILL_UP = 0.44 -- the new pavement's top over the road (the old pavement is at 0.5)
local KERB_UP = 0.58 -- the kerb's top over the road (as Roads.luau's)
local SLAB = 6
local MAXDEPTH = 60

local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, props, parent: Instance): number
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 then
		return 0
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	if nUp.Y < 0.6 then
		return 0
	end
	local drop = -nUp * (th / 2)
	local w1 = Instance.new("WedgePart")
	w1.Size = Vector3.new(th, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 + drop, right, up, back)
	local w2 = Instance.new("WedgePart")
	w2.Size = Vector3.new(th, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back)
	for _, w in { w1, w2 } do
		w.Anchored = true
		w.CastShadow = false
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in props do
			(w :: any)[k] = v
		end
		w.Parent = parent
	end
	return 2
end

function StraightKerb.build(roadName: string, a: Vector3, b: Vector3, side: Vector3, parent: Instance): (number, number)
	local roadsFolder = workspace.Riviera.Roads
	local folderR = roadsFolder:FindFirstChild(roadName) :: Instance
	local roadParts = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Road" or d.Name == "TurningCircle") then
			table.insert(roadParts, d)
		end
	end
	local onRoad = RaycastParams.new()
	onRoad.FilterType = Enum.RaycastFilterType.Include
	onRoad.FilterDescendantsInstances = roadParts
	local solid = RaycastParams.new()
	solid.FilterType = Enum.RaycastFilterType.Include
	local edgeParts = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Road" or d.Name == "TurningCircle" or d.Name == "Kerb" or d.Name == "Pavement") then
			table.insert(edgeParts, d)
		end
	end
	solid.FilterDescendantsInstances = edgeParts
	local function roadY(p: Vector3): number?
		local hit = workspace:Raycast(Vector3.new(p.X, p.Y + 15, p.Z), Vector3.new(0, -30, 0), onRoad)
		return hit and hit.Position.Y
	end
	local function topHit(p: Vector3): string?
		local hit = workspace:Raycast(Vector3.new(p.X, p.Y + 15, p.Z), Vector3.new(0, -30, 0), solid)
		return hit and hit.Instance.Name
	end

	local flatA, flatB = Vector3.new(a.X, 0, a.Z), Vector3.new(b.X, 0, b.Z)
	local len = (flatB - flatA).Magnitude
	local u = (flatB - flatA).Unit
	local n = Vector3.new(side.X, 0, side.Z).Unit
	local into = -n -- into the old corner

	-- along the new line: K (on it) and F (the old kerb behind it)
	local steps = math.max(2, math.ceil(len / STEP))
	local K, F = {}, {}
	for i = 0, steps do
		local p = flatA + u * (len * i / steps) + Vector3.new(0, (a.Y + b.Y) / 2, 0)
		local y = roadY(p + n * 0.6) or roadY(p) or p.Y
		local k = Vector3.new(p.X, y, p.Z)
		-- walk into the corner over the road to the old kerb / pavement
		local t, yLast = 0.3, y
		while t < MAXDEPTH do
			local q = k + into * t
			local name = topHit(q)
			if name ~= "Road" and name ~= "TurningCircle" then
				break
			end
			yLast = roadY(q) or yLast
			t += 0.5
		end
		local depth = math.max(0, t - 0.3) + 1 -- a stud under the old kerb
		table.insert(K, k)
		-- (owner: the old pavement stood up past the new one, a step) the far side meets the old
		-- pavement's own top (a hair under it), so the new pavement rises to it with no step
		local fy = yLast
		local behind = k + into * (depth + 2)
		local hit = workspace:Raycast(Vector3.new(behind.X, behind.Y + 15, behind.Z), Vector3.new(0, -30, 0), solid)
		if hit and hit.Instance.Name == "Pavement" and math.abs(hit.Position.Y - (yLast + 0.5)) < 2 then
			fy = hit.Position.Y - 0.06 - FILL_UP
		end
		table.insert(F, Vector3.new(k.X, fy, k.Z) + into * depth)
	end

	local folder = parent:FindFirstChild("StraightKerbs") or Instance.new("Folder")
	folder.Name = "StraightKerbs"
	folder.Parent = parent
	local model = folder:FindFirstChild(roadName)
	if model then
		model:Destroy()
	end
	model = Instance.new("Model")
	model.Name = roadName
	model.Parent = folder

	-- the new pavement looks like this road's own
	local look = { Name = "Pavement", Material = Enum.Material.Pavement, Color = Color3.fromRGB(176, 104, 92) }
	for _, d in folderR:GetChildren() do
		if d:IsA("BasePart") and d.Name == "Pavement" then
			look = { Name = "CornerPavement", Material = d.Material, Color = d.Color, MaterialVariant = d.MaterialVariant }
			break
		end
	end
	look.Name = "CornerPavement"

	local made = 0
	local upF = Vector3.new(0, FILL_UP, 0)
	for i = 1, #K - 1 do
		local k0, k1, f0, f1 = K[i] + upF, K[i + 1] + upF, F[i] + upF, F[i + 1] + upF
		made += triangle(k0, k1, f1, SLAB, look, model)
		made += triangle(k0, f1, f0, SLAB, look, model)
		-- the kerb on the new line, 0.45 in from the road
		local m0 = K[i] + into * 0.45 + Vector3.new(0, KERB_UP, 0)
		local m1 = K[i + 1] + into * 0.45 + Vector3.new(0, KERB_UP, 0)
		local kerb = Instance.new("Part")
		kerb.Name = "Kerb"
		kerb.Anchored = true
		kerb.CastShadow = false
		kerb.Material = Enum.Material.Concrete
		kerb.Color = Color3.fromRGB(205, 202, 194)
		kerb.TopSurface = Enum.SurfaceType.Smooth
		kerb.BottomSurface = Enum.SurfaceType.Smooth
		kerb.Size = Vector3.new(0.9, 4, (m1 - m0).Magnitude + 0.3)
		kerb.CFrame = CFrame.lookAt((m0 + m1) / 2, m1) * CFrame.new(0, -2, 0)
		kerb.Parent = model
		made += 1
	end

	-- what's now inside the new pavement: old kerbs (they'd stick up) and road lines go
	local function inside(p: Vector3): boolean
		local rel = Vector3.new(p.X, 0, p.Z) - flatA
		local along = rel:Dot(u)
		local across = rel:Dot(into)
		if along < 0 or along > len or across < 1.2 then
			return false
		end
		-- within the fill's depth at this point
		local i = math.clamp(math.floor(along / len * steps) + 1, 1, #K)
		local depth = (Vector3.new(F[i].X, 0, F[i].Z) - Vector3.new(K[i].X, 0, K[i].Z)).Magnitude
		return across < depth + 0.5 and math.abs(p.Y - K[i].Y) < 6
	end
	local removed = 0
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Kerb" or d.Name == "Line") and d.Parent ~= model and inside(d.Position) then
			d:Destroy()
			removed += 1
		end
	end
	return made, removed
end

return StraightKerb
