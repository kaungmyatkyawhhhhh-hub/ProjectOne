--[[
	MCDrone (2026-11-17, owner: "see the mm plaza canopies and every thing in those picture and then match with our game")
	Myanmar Plaza area matched to the owner's drone photo (vault: City Legends/Owner ref - Myanmar Plaza drone view (real).png).
	Everything new goes in Workspace.Yangon1to1.Landmarks.MyanmarCentre.DroneMatch (M.undo() removes it).
	Done before this file (in Studio, 17 Nov): city/mc_corner_patch.py (Model 80568456105370) swapped into the CHR, FAS,
	SOF and big DRK meshes with ApplyMesh (old ids / sizes / positions in attributes *_drone), the STR mesh (the tilted
	roof canopy and its V struts) deleted, the two outer canopy columns' collision boxes deleted.
	  M.pergola()  the photo's white louvred pergola on the roof behind the corner front (inside the facade line)
	  M.gardens()  roof garden beds round the dome (city/mc_roof_gardens.py -> build/landmarks/p1_refit/mc_roof_beds.json)
	  M.fountain() the round plaza: a white-rimmed round fountain round the sculpture plinth and a clipped hedge ring
	Parts only (CSG for the rings), all butting, no coplanar visible faces. Run in Studio Edit (paste + call).
]]
local M = {}
local MC = workspace.Yangon1to1.Landmarks.MyanmarCentre
local WHITE = Color3.fromRGB(236, 236, 232)
local GRASS = Color3.fromRGB(92, 128, 62)
local HEDGE = Color3.fromRGB(52, 88, 44)

local function root(): Model
	local r = MC:FindFirstChild("DroneMatch")
	if not r then
		r = Instance.new("Model")
		r.Name = "DroneMatch"
		r.Parent = MC
	end
	return r
end

local function sub(name: string): Model
	local r = root()
	local f = r:FindFirstChild(name)
	if f then
		f:Destroy()
	end
	f = Instance.new("Model")
	f.Name = name
	f.Parent = r
	return f
end

local function part(parent, cf: CFrame, size: Vector3, color: Color3, mat: Enum.Material?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CFrame = cf
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = collide == true
	p.CastShadow = size.Y > 2
	p.Parent = parent
	return p
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
local function groundY(x: number, z: number): number?
	rp.FilterDescendantsInstances = { MC.Collide }
	local r = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -500, 0), rp)
	return r and r.Position.Y
end

-- the corner front: facade mid Mf, along T, N into the building (the facade is at depth 16.84 from the canopy edge)
-- the podium's roof cap (ROF mesh, flat at 119.86; the top floor's walkable slab is 15 lower: never raycast it)
local ROOF = 119.86
local Mf = Vector3.new(34811.05, 0, 27180.3)
local T = Vector3.new(0.7931, 0, -0.6092)
local N = Vector3.new(0.6092, 0, 0.7931)

function M.pergola()
	local f = sub("Pergola")
	local c = Mf + N * 26 -- depth 19..33: the roof edge balustrade stands at ~18
	local y0 = ROOF
	local H, W, D = 9, 44, 14
	local rot = CFrame.fromMatrix(Vector3.zero, T, Vector3.yAxis, T:Cross(Vector3.yAxis))
	local function at(s, h, d)
		return CFrame.new(c + T * s + N * (d - 26) + Vector3.new(0, y0 + h, 0)) * rot
	end
	-- four posts, two long beams on them, louvres across between the beams
	for _, s in { -W / 2 + 0.6, W / 2 - 0.6 } do
		for _, d in { 19.6, 32.4 } do
			part(f, at(s, (H - 1.2) / 2, d), Vector3.new(1.2, H - 1.2, 1.2), WHITE, nil, true)
		end
	end
	for _, d in { 19.6, 32.4 } do
		part(f, at(0, H - 0.6, d), Vector3.new(W, 1.2, 1.2), WHITE)
	end
	local n = 15
	for k = 0, n - 1 do
		local s = -W / 2 + 1.2 + (W - 2.4) * (k + 0.5) / n
		part(f, at(s, H - 0.6, 26), Vector3.new(0.5, 1.2, 11.6), WHITE) -- butts the beams' inner faces (12.8 - 1.2)
	end
	return #f:GetChildren()
end

local BEDS = {{34794.38,27240.94,24,16},{34830.38,27240.94,30,16},{34728.38,27268.94,30,20},{34764.38,27268.94,24,20},{34872.38,27268.94,30,20},{34722.38,27292.94,24,16},{34905.38,27292.94,24,16},{34728.38,27318.94,30,16},{34911.38,27318.94,30,16},{34722.38,27346.94,24,20},{34728.38,27370.94,30,16},{34722.38,27398.94,24,20},{34758.38,27398.94,30,20},{34869.38,27398.94,30,20},{34905.38,27398.94,24,20},{34911.38,27422.94,30,16},{34947.38,27422.94,24,16},{34980.38,27448.94,30,16},{34983.38,27476.94,30,20},{35022.38,27476.94,30,20},{34980.38,27500.94,30,16},{35016.38,27500.94,24,16},{35052.38,27500.94,30,16},{34983.38,27528.94,30,20},{35022.38,27528.94,30,20},{35058.38,27528.94,24,20},{34980.38,27552.94,30,16},{35016.38,27552.94,24,16},{34947.38,27578.94,24,16}}

function M.gardens()
	local f = sub("RoofGardens")
	for i, b in BEDS do
		local y = ROOF
		-- a lawn bed 1 stud high (0.2 sunk in the roof), every other bed with a clipped hedge down its middle
		part(f, CFrame.new(b[1], y + 0.3, b[2]), Vector3.new(b[3], 1, b[4]), GRASS, Enum.Material.Grass)
		if i % 2 == 0 then
			part(f, CFrame.new(b[1], y + 0.8 + 0.9, b[2]), Vector3.new(b[3] - 6, 1.8, 2.2), HEDGE, Enum.Material.LeafyGrass)
		end
	end
	return #f:GetChildren()
end

local PC = Vector3.new(34717.5, 0, 27127.5) -- the round plaza (layout plinth_c), r 37.5, sculpture plinth 6 x 6
local GS = game:GetService("GeometryService")

local function ring(parent, c: Vector3, rOut: number, rIn: number, h: number, color, mat, cuts: { Part }?)
	local outer = Instance.new("Part")
	outer.Shape = Enum.PartType.Cylinder
	outer.Size = Vector3.new(h, rOut * 2, rOut * 2)
	outer.CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.pi / 2)
	local inner = outer:Clone()
	inner.Size = Vector3.new(h + 1, rIn * 2, rIn * 2)
	local list = { inner }
	for _, p in cuts or {} do
		table.insert(list, p)
	end
	local res = GS:SubtractAsync(outer, list, { CollisionFidelity = Enum.CollisionFidelity.Box, SplitApart = false })
	local u = res[1]
	u.Anchored = true
	u.Color = color
	u.Material = mat
	u.UsePartColor = true
	u.CanCollide = false
	u.Parent = parent
	return u
end

function M.fountain()
	local f = sub("RoundPlaza")
	local y = groundY(PC.X, PC.Z + 12) or 44
	-- fountain: white rim 10 / 8.6, water 0.5 under the rim top, round the 6 x 6 plinth
	ring(f, Vector3.new(PC.X, y + 0.8, PC.Z), 10, 8.6, 1.8, WHITE, Enum.Material.SmoothPlastic)
	local plinthHole = Instance.new("Part")
	plinthHole.Size = Vector3.new(6.2, 4, 6.2)
	plinthHole.CFrame = CFrame.new(PC.X, y, PC.Z)
	local w = ring(f, Vector3.new(PC.X, y + 0.55, PC.Z), 8.6, 0.01, 1.1, Color3.fromRGB(70, 150, 170), Enum.Material.Glass, { plinthHole })
	w.Transparency = 0.15
	-- clipped hedge ring 26..28.5, four 8-stud paths on the diagonals
	local cuts = {}
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		local cp = Instance.new("Part")
		cp.Size = Vector3.new(8, 6, 8)
		cp.CFrame = CFrame.new(PC.X + math.cos(a) * 27.25, y, PC.Z + math.sin(a) * 27.25) * CFrame.Angles(0, -a, 0)
		table.insert(cuts, cp)
	end
	ring(f, Vector3.new(PC.X, y + 1.0, PC.Z), 28.5, 26, 2.4, HEDGE, Enum.Material.LeafyGrass, cuts)
	return y
end

function M.undo()
	local r = MC:FindFirstChild("DroneMatch")
	if r then
		r:Destroy()
	end
end

return M
