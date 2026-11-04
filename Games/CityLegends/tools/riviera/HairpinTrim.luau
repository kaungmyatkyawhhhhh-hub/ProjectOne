--[[
	HairpinTrim (Studio, Edit mode; 2026-11-04, owner: "make the hairpin curve have the red curbs like other
	curves near the hairpin and also add road line"): the Grand Hairpin dressed like the roads next to it,
	with ordinary parts, so no Import 3D is needed:
	  * the brick-red pavement: the invisible solid pavement wedges (Grand Hairpin/Solid) shown in the
	    nearby roads' colour, the island's solid wedges shown as grass
	  * pale stone kerbs along both edges and round the island (Trim/Kerb), a gap at the hotel's drive
	  * road lines like the West Switchbacks': a solid edge line 1.2 in from each edge (Line, 0.6 wide), a
	    dashed middle line (0.5 wide, 7 long every 15), sitting 0.08 over the road by raycast

	HairpinTrim.build(data) -> counts   (data = build/riviera/hairpin.json)
]]

local HairpinTrim = {}

local PAVER = Color3.fromRGB(176, 104, 92)
local KERB = Color3.fromRGB(205, 202, 194)
local PAINT = Color3.fromRGB(232, 232, 226)
local GRASS = Color3.fromRGB(86, 118, 62)
local EDGE_IN = 1.2 -- the edge line, in from the road's edge
local KERB_UP = 0.58 -- the kerb's top over the road
local LIFT = 0.08 -- paint over the road
local DASH, PERIOD = 7, 15

function HairpinTrim.build(d)
	local folder = workspace.Riviera.Roads["Grand Hairpin"]
	local old = folder:FindFirstChild("Trim")
	if old then
		old:Destroy()
	end
	local trim = Instance.new("Folder")
	trim.Name = "Trim"

	local S = d.s
	local n = #S
	local cx, cz = d.centre[1], d.centre[2]
	local kerbW = d.kerb

	-- the road's surface, for the paint and kerbs
	local roadParts = {}
	for _, p in folder:GetChildren() do
		if p:IsA("BasePart") and p.Name == "Road" then
			table.insert(roadParts, p)
		end
	end
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Include
	down.FilterDescendantsInstances = roadParts
	local function surface(x: number, z: number, fallback: number): number
		local hit = workspace:Raycast(Vector3.new(x, fallback + 8, z), Vector3.new(0, -16, 0), down)
		return if hit then hit.Position.Y else fallback
	end

	-- +1 is the island's side of the road
	local function side(i: number, off: number): Vector3
		local s = S[i]
		return Vector3.new(s[1] - s[5] * off, s[2], s[3] + s[4] * off)
	end
	local function half(i: number): number
		return S[i][6]
	end
	local function nearIsland(i: number): boolean
		local s = S[i]
		return math.sqrt((s[1] - cx) ^ 2 + (s[3] - cz) ^ 2) < d.R + 6 and s[1] < cx + 80
	end
	local function atDrive(i: number): boolean
		return S[i][1] < cx and math.abs(S[i][3] - cz) < 26
	end

	local function make(name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = trim
		return p
	end

	-- the pavement and the island: their solid wedges, shown
	local shown = 0
	for _, p in folder.Solid:GetChildren() do
		if p.Name == "Pavement" then
			p.Transparency = 0
			p.Color = PAVER
			p.Material = Enum.Material.Pavement
			p.CastShadow = false
			shown += 1
		elseif p.Name == "Island" then
			p.Transparency = 0
			p.Color = GRASS
			p.Material = Enum.Material.Grass
			p.CastShadow = false
			shown += 1
		end
	end

	-- kerbs: short pieces, neighbours a hair apart in height and width so their overlaps never flicker
	local kerbs = 0
	local function kerbPiece(a: Vector3, b: Vector3, alt: number)
		local up = Vector3.new(0, KERB_UP - 1.5 + alt * 0.006, 0)
		local len = (b - a).Magnitude
		if len > 0.05 then
			make("Kerb", Vector3.new(kerbW - alt * 0.01, 3, len + 0.35), CFrame.lookAt((a + b) / 2 + up, b + up), KERB, Enum.Material.Concrete)
			kerbs += 1
		end
	end
	local function kerbAt(i: number, sign: number): Vector3
		local p = side(i, sign * (half(i) + kerbW / 2 - 0.05))
		return Vector3.new(p.X, surface(side(i, sign * (half(i) - 1)).X, side(i, sign * (half(i) - 1)).Z, p.Y), p.Z)
	end
	for i = 1, n - 2, 2 do
		if not atDrive(i) and not atDrive(i + 2) then
			kerbPiece(kerbAt(i, -1), kerbAt(i + 2, -1), (i // 2) % 2)
		end
		if not nearIsland(i) and not nearIsland(i + 2) then
			kerbPiece(kerbAt(i, 1), kerbAt(i + 2, 1), (i // 2) % 2)
		end
		if i % 60 == 1 then
			task.wait()
		end
	end
	-- round the island
	local isl = d.island
	local m = #isl
	local function islandY(x: number, z: number): number
		local best, bestD = S[1][2], math.huge
		for i = 1, n, 4 do
			local e = (S[i][1] - x) ^ 2 + (S[i][3] - z) ^ 2
			if e < bestD then
				best, bestD = S[i][2], e
			end
		end
		return best
	end
	for k = 1, m do
		local p, q = isl[k], isl[k % m + 1]
		local a = Vector3.new(p[1], islandY(p[1], p[2]), p[2])
		local b = Vector3.new(q[1], islandY(q[1], q[2]), q[2])
		kerbPiece(a, b, k % 2)
	end

	-- the lines
	local lines = 0
	local function paint(a: Vector3, b: Vector3, w: number)
		local pa = Vector3.new(a.X, surface(a.X, a.Z, a.Y) + LIFT, a.Z)
		local pb = Vector3.new(b.X, surface(b.X, b.Z, b.Y) + LIFT, b.Z)
		local len = (pb - pa).Magnitude
		if len > 0.2 then
			make("Line", Vector3.new(w, 0.04, len + 0.08), CFrame.lookAt((pa + pb) / 2, pb), PAINT, Enum.Material.SmoothPlastic)
			lines += 1
		end
	end
	-- the solid edge lines
	for i = 1, n - 3, 3 do
		if not atDrive(i) and not atDrive(i + 3) then
			paint(side(i, -(half(i) - EDGE_IN)), side(i + 3, -(half(i + 3) - EDGE_IN)), 0.6)
		end
		paint(side(i, half(i) - EDGE_IN), side(i + 3, half(i + 3) - EDGE_IN), 0.6)
		if i % 60 == 1 then
			task.wait()
		end
	end
	-- the dashed middle line
	local dist = { 0 }
	for i = 2, n do
		dist[i] = dist[i - 1] + (Vector3.new(S[i][1], 0, S[i][3]) - Vector3.new(S[i - 1][1], 0, S[i - 1][3])).Magnitude
	end
	local function atDist(want: number): Vector3
		for i = 2, n do
			if dist[i] >= want then
				local t = (want - dist[i - 1]) / math.max(dist[i] - dist[i - 1], 0.001)
				return side(i - 1, 0):Lerp(side(i, 0), t)
			end
		end
		return side(n, 0)
	end
	local s = 4
	while s + DASH < dist[n] do
		paint(atDist(s), atDist(s + DASH), 0.5)
		s += PERIOD
	end

	trim.Parent = folder
	return { shown = shown, kerbs = kerbs, lines = lines }
end

return HairpinTrim
