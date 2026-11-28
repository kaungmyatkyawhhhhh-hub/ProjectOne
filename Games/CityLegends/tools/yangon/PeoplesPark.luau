--!nocheck
--[[ People's Park + the Shwedagon view point and car park (Yangon 1:1; owner, 21 Nov: "view peoples park View point
	shwedagon pagoda and also the shwe dagon pagoda parking ... and build it").
	Shapes are the real ones from OpenStreetMap (build/osm_ygn/areas.json), as oriented boxes { x, z, length, width, angle }.
	Studio (Edit):  local P = require(ServerStorage.ClaudeTools.PeoplesPark:Clone())  P.all()   |  P.undo()
	Everything goes into Workspace.Yangon1to1.Parks.<name>. Slabs follow the ground along their length (level across),
	the ground is filled under them and cleared over them. Plants come from ReplicatedStorage.MedianKit. ]]
local P = {}
local T = workspace.Terrain
local RS = game:GetService("ReplicatedStorage")

P.RECTS = {
	garden = { 31419, 37668, 949, 85, 163 }, -- the long fountain garden that points at the pagoda's west stairs
	square = { 30679, 38070, 580, 170, 164 }, -- People's Square
	fountA = { 30846, 37837, 133, 80, -17 }, -- the big fountain at the garden's west head
	eleph = { 30616, 37906, 74, 72, 17 }, -- the Elephant Fountain
	parkPP = { 31721, 37138, 542, 104, 68 }, -- the car park by U Wisara Road (the pagoda's west side)
	parkSW = { 30766, 38602, 156, 184, 163 }, -- the car park by the square
	-- The Central (Kabar Aye Pagoda Road): the forecourt between the road and the round pavilion, the car park on the
	-- lawn behind the shop row, its drive from the road
	centralPlaza = { 34992, 25279, 108, 84, 0 },
	centralPark = { 35180, 25405, 280, 104, 0 },
	centralDrive = { 34985, 25495, 136, 24, 0 },
	centralLeg = { 35046, 25470.5, 25, 26, 90 },
}

local PAVE, PAVE2 = Color3.fromRGB(206, 198, 182), Color3.fromRGB(172, 150, 128)
local STONE, WHITE = Color3.fromRGB(226, 222, 212), Color3.fromRGB(240, 240, 236)
local SOIL, WATER, TILE = Color3.fromRGB(52, 84, 40), Color3.fromRGB(38, 96, 110), Color3.fromRGB(120, 186, 204)
local BASIN = Color3.fromRGB(46, 62, 66)
local ASPH, DARK = Color3.fromRGB(46, 47, 50), Color3.fromRGB(40, 42, 46)

local tp = RaycastParams.new()
tp.FilterType = Enum.RaycastFilterType.Include
tp.FilterDescendantsInstances = { T }
tp.IgnoreWater = true
local function gy(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -1000, 0), tp)
	return hit and hit.Position.Y
end

local function folder()
	local y = workspace.Yangon1to1
	local f = y:FindFirstChild("Parks")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Parks"
		f.Parent = y
	end
	return f
end
local function model(name)
	local f = folder()
	local old = f:FindFirstChild(name)
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = f
	return m
end
local function part(parent, name, size, cf, color, mat, collide)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.Size, p.CFrame, p.Color, p.Material = name, true, size, cf, color, mat or Enum.Material.SmoothPlastic
	p.CanCollide = collide ~= false
	p.CastShadow = size.Y >= 6
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- the ground along a box's long axis, every `step`, smoothed
local function profile(r, step)
	local a = math.rad(r[5])
	local u = Vector3.new(math.cos(a), 0, math.sin(a))
	local v = Vector3.new(-u.Z, 0, u.X)
	local c = Vector3.new(r[1], 0, r[2])
	local n = math.max(2, math.ceil(r[3] / step))
	step = r[3] / n
	local raw = {}
	for i = 0, n do
		local s = -r[3] / 2 + i * step
		local sum, k = 0, 0
		for _, j in { -0.45, -0.22, 0, 0.22, 0.45 } do
			local p = c + u * s + v * (j * r[4])
			local y = gy(p.X, p.Z)
			if y then sum += y k += 1 end
		end
		raw[i] = if k > 0 then sum / k else nil
	end
	local h = {}
	for i = 0, n do
		local sum, k = 0, 0
		for d = -2, 2 do
			local q = raw[i + d]
			if q then sum += q k += 1 end
		end
		h[i] = if k > 0 then sum / k else 0
	end
	return { c = c, u = u, v = v, n = n, step = step, h = h, len = r[3], wid = r[4] }
end
local function hAt(pf, s)
	local t = math.clamp((s + pf.len / 2) / pf.step, 0, pf.n)
	local i = math.min(math.floor(t), pf.n - 1)
	local f = t - i
	return pf.h[i] * (1 - f) + pf.h[i + 1] * f
end
-- a point on the box: s along, o across, y over the ground line
local function at(pf, s, o, lift)
	local p = pf.c + pf.u * s + pf.v * o
	return Vector3.new(p.X, hAt(pf, s) + (lift or 0), p.Z)
end
-- the frame of the ground line at s (looks along the axis, follows the slope)
local function frameAt(pf, s, o, lift)
	local a, b = at(pf, s - 2, o, lift), at(pf, s + 2, o, lift)
	return CFrame.lookAt((a + b) / 2, b)
end
local airJobs = {}
local function flush()
	for i, j in airJobs do
		T:FillBlock(j[1], j[2], Enum.Material.Air)
		if i % 20 == 0 then task.wait() end
	end
	table.clear(airJobs)
end
-- a strip of slabs along the box: its top is `lift` over the ground line
local function ribbon(parent, pf, name, o, wid, lift, th, color, mat, s0, s1, ground, collide)
	s0, s1 = s0 or -pf.len / 2, s1 or pf.len / 2
	local n = math.max(1, math.ceil((s1 - s0) / pf.step))
	local d = (s1 - s0) / n
	for i = 0, n - 1 do
		local a, b = at(pf, s0 + i * d, o, lift), at(pf, s0 + (i + 1) * d, o, lift)
		local top = CFrame.lookAt((a + b) / 2, b)
		local len = (b - a).Magnitude
		part(parent, name, Vector3.new(wid, th, len + 0.02), top * CFrame.new(0, -th / 2, 0), color, mat, collide)
		if ground then
			-- ground up to 4 under the top; the air over it is cut afterwards (P.flush), or a neighbour's fill comes back
			T:FillBlock(top * CFrame.new(0, -9, 0), Vector3.new(wid + 6, 10, len + 4), Enum.Material.Grass)
			table.insert(airJobs, { top * CFrame.new(0, 3.75, 0), Vector3.new(wid + 1, 12.5, len + 4) })
		end
		if i % 6 == 5 then task.wait() end
	end
end

local rng = Random.new(2611)
local function plant(parent, name, k, cf)
	local kit = RS:FindFirstChild("MedianKit")
	local src = kit and kit:FindFirstChild(name)
	if src then
		local c = src:Clone()
		c:ScaleTo(src:GetScale() * k)
		c:PivotTo(cf * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") then d.CanCollide = false d.CanQuery = false d.CastShadow = false end
		end
		c.Parent = parent
	end
end
local function jet(parent, pos, height, rate)
	local p = part(parent, "Jet", Vector3.new(0.8, 0.6, 0.8), CFrame.new(pos), Color3.fromRGB(150, 150, 150), Enum.Material.Metal, false)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fountain"
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(226, 242, 250))
	e.LightEmission = 0.35
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.8, 0.5), NumberSequenceKeypoint.new(1, 1) })
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1.9) })
	local sp = math.sqrt(2 * 60 * height)
	e.Speed = NumberRange.new(sp * 0.92, sp)
	e.Acceleration = Vector3.new(0, -60, 0)
	e.Lifetime = NumberRange.new(2 * sp / 60 * 0.95)
	e.Rate = rate or 26
	e.SpreadAngle = Vector2.new(5, 5)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = p
end
local function lamp(parent, cf, light)
	part(parent, "LampPost", Vector3.new(0.7, 13, 0.7), cf * CFrame.new(0, 6.5, 0), DARK, Enum.Material.Metal, false)
	part(parent, "LampFoot", Vector3.new(1.6, 1, 1.6), cf * CFrame.new(0, 0.5, 0), DARK, Enum.Material.Metal, false)
	local g = Instance.new("Part")
	g.Shape = Enum.PartType.Ball
	g.Name, g.Anchored, g.CanCollide, g.CastShadow = "LampGlobe", true, false, false
	g.Size = Vector3.new(2.4, 2.4, 2.4)
	g.CFrame = cf * CFrame.new(0, 14, 0)
	g.Color, g.Material = Color3.fromRGB(255, 244, 214), Enum.Material.Neon
	g.Parent = parent
	if light then
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 232, 190), 34, 1.4, false
		l.Parent = g
	end
end
local function bench(parent, cf)
	part(parent, "Bench", Vector3.new(7, 0.5, 2), cf * CFrame.new(0, 1.6, 0), Color3.fromRGB(120, 84, 52), Enum.Material.Wood)
	part(parent, "BenchBack", Vector3.new(7, 1.6, 0.4), cf * CFrame.new(0, 2.7, 0.9), Color3.fromRGB(120, 84, 52), Enum.Material.Wood)
	for _, x in { -3, 3 } do
		part(parent, "BenchLeg", Vector3.new(0.5, 1.4, 1.8), cf * CFrame.new(x, 0.7, 0), DARK, Enum.Material.Metal)
	end
end
-- a level basin: rim, floor, water; jets at the given points (local x across, z along)
-- (28 Nov, owner: the basins read as flat pale-blue slabs) dark slate floor under see-through glassy water; pools pass TILE
local function basin(parent, cf, wid, len, rimH, jets, floor)
	part(parent, "BasinFloor", Vector3.new(wid, 0.4, len), cf * CFrame.new(0, 0.2, 0), floor or BASIN, Enum.Material.Slate)
	for _, sx in { -1, 1 } do
		part(parent, "Rim", Vector3.new(1.6, rimH, len + 3.2), cf * CFrame.new(sx * (wid / 2 + 0.8), rimH / 2, 0), STONE, Enum.Material.Concrete)
		part(parent, "Rim", Vector3.new(wid, rimH, 1.6), cf * CFrame.new(0, rimH / 2, sx * (len / 2 + 0.8)), STONE, Enum.Material.Concrete)
	end
	local w = part(parent, "Water", Vector3.new(wid, 0.3, len), cf * CFrame.new(0, rimH - 0.45, 0), WATER, Enum.Material.Glass, false)
	w.Transparency, w.Reflectance = 0.35, 0.2
	for _, j in jets or {} do
		jet(parent, (cf * CFrame.new(j[1], rimH - 0.2, j[2])).Position, j[3] or 9, j[4])
	end
end
local function sign(parent, cf, w, h, text, sub)
	local b = part(parent, "SignBoard", Vector3.new(w, h, 0.6), cf, Color3.fromRGB(30, 62, 44), Enum.Material.SmoothPlastic)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face, g.SizingMode, g.PixelsPerStud, g.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 30, 1
		g.Parent = b
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency, t.Size, t.Position = 1, UDim2.fromScale(0.94, sub and 0.58 or 0.9), UDim2.fromScale(0.03, 0.04)
		t.Text, t.TextScaled, t.Font, t.TextColor3 = text, true, Enum.Font.GothamBold, Color3.fromRGB(244, 222, 150)
		t.Parent = g
		if sub then
			local s = t:Clone()
			s.Size, s.Position, s.Text, s.Font, s.TextColor3 = UDim2.fromScale(0.94, 0.3), UDim2.fromScale(0.03, 0.64), sub, Enum.Font.Gotham, Color3.fromRGB(236, 236, 228)
			s.Parent = g
		end
	end
	return b
end

-- the long fountain garden
function P.garden()
	local r = P.RECTS.garden
	local pf = profile(r, 23.7)
	local m = model("FountainGarden")
	local H = pf.len / 2
	ribbon(m, pf, "Walk", 0, 85, 0.6, 5, PAVE, Enum.Material.Concrete, nil, nil, true)
	flush()
	local pitch, bl = 79, 62
	local nb = math.floor((pf.len - 40) / pitch)
	local first = -(nb * pitch) / 2 + pitch / 2
	for i = 0, nb - 1 do
		local s = first + i * pitch
		-- each basin is level, at its low end's height
		local low = math.min(hAt(pf, s - bl / 2), hAt(pf, s + bl / 2))
		local hi = math.max(hAt(pf, s - bl / 2), hAt(pf, s + bl / 2))
		local p0 = pf.c + pf.u * s
		local o = Vector3.new(p0.X, low + 0.6, p0.Z)
		basin(m, CFrame.lookAt(o, o + pf.u), 20, bl, (hi - low) + 1.5, { { 0, -bl / 4, 10 }, { 0, bl / 4, 10 }, { 0, 0, 5, 16 } })
		if i < nb - 1 then
			ribbon(m, pf, "CrossPath", 0, 85, 0.68, 0.3, PAVE2, Enum.Material.Concrete, s + pitch / 2 - 4, s + pitch / 2 + 4, false, false)
		end
		task.wait()
	end
	for _, side in { -1, 1 } do
		ribbon(m, pf, "Bed", side * 31, 7, 1.1, 1.2, SOIL, Enum.Material.Grass, -H + 6, H - 6, false)
		ribbon(m, pf, "BedEdge", side * 27.2, 0.6, 1.25, 1.4, STONE, Enum.Material.Concrete, -H + 6, H - 6, false)
		ribbon(m, pf, "BedEdge", side * 34.8, 0.6, 1.25, 1.4, STONE, Enum.Material.Concrete, -H + 6, H - 6, false)
		local k = 0
		for s = -H + 10, H - 10, 5.2 do
			k += 1
			local cf = frameAt(pf, s, side * 31 + rng:NextNumber(-1.6, 1.6), 1.1)
			if k % 5 == 0 then
				plant(m, "Shrub", rng:NextNumber(1.25, 1.6), cf)
			elseif k % 11 == 0 then
				plant(m, "Spiky", rng:NextNumber(1.3, 1.7), cf)
			else
				plant(m, "Low", rng:NextNumber(0.9, 1.25), cf)
			end
			if k % 40 == 0 then task.wait() end
		end
		for s = -H + 20, H - 20, 39.5 do
			lamp(m, frameAt(pf, s, side * 23.5, 0.6), false)
		end
		for s = first + pitch / 2, H - 30, pitch do
			bench(m, frameAt(pf, s - 9, side * 16, 0.6) * CFrame.Angles(0, side * math.pi / 2, 0))
		end
	end
	return #m:GetDescendants()
end

-- the view point: a raised stone terrace at the garden's east end, looking along the axis at the Shwedagon
function P.viewpoint()
	local r = P.RECTS.garden
	local pf = profile(r, 23.7)
	local m = model("ShwedagonViewPoint")
	local e = -pf.u -- east (towards the pagoda)
	local base = at(pf, -pf.len / 2, 0, 0)
	local mid = base + e * 34
	local o = Vector3.new(mid.X, base.Y + 4.6, mid.Z)
	local cf = CFrame.lookAt(o, o + e) -- -Z looks at the pagoda
	local W, D = 84, 64
	T:FillBlock(cf * CFrame.new(0, -7, 0), Vector3.new(W + 10, 12, D + 10), Enum.Material.Grass)
	T:FillBlock(cf * CFrame.new(0, 6, 0), Vector3.new(W + 2, 12, D + 2), Enum.Material.Air)
	part(m, "Terrace", Vector3.new(W, 7, D), cf * CFrame.new(0, -3.5, 0), STONE, Enum.Material.Concrete)
	part(m, "TerraceInlay", Vector3.new(W - 14, 0.2, D - 14), cf * CFrame.new(0, 0.06, 0), PAVE2, Enum.Material.Concrete, false)
	for i = 1, 4 do
		part(m, "Step", Vector3.new(44, 7, 3), cf * CFrame.new(0, -3.5 - i * 1.0, D / 2 + i * 3 - 1.5), WHITE, Enum.Material.Concrete)
	end
	local function rail(a, b)
		local d = (b - a)
		local n = math.max(1, math.floor(d.Magnitude / 6))
		for i = 0, n do
			local p = a + d * (i / n)
			part(m, "Baluster", Vector3.new(0.9, 3.4, 0.9), cf * CFrame.new(p.X, 1.7, p.Z), WHITE, Enum.Material.Concrete)
		end
		local c = (a + b) / 2
		local size = if math.abs(d.X) > math.abs(d.Z) then Vector3.new(d.Magnitude + 0.9, 0.6, 1.2) else Vector3.new(1.2, 0.6, d.Magnitude + 0.9)
		part(m, "Handrail", size, cf * CFrame.new(c.X, 3.7, c.Z), WHITE, Enum.Material.Concrete)
	end
	local hw, hd = W / 2 - 1, D / 2 - 1
	rail(Vector3.new(-hw, 0, -hd), Vector3.new(hw, 0, -hd))
	rail(Vector3.new(-hw, 0, -hd + 1.5), Vector3.new(-hw, 0, hd))
	rail(Vector3.new(hw, 0, -hd + 1.5), Vector3.new(hw, 0, hd))
	rail(Vector3.new(-hw + 1.5, 0, hd), Vector3.new(-24, 0, hd))
	rail(Vector3.new(24, 0, hd), Vector3.new(hw - 1.5, 0, hd))
	local b = Instance.new("Part")
	b.Shape = Enum.PartType.Cylinder
	b.Name, b.Anchored, b.Size, b.Color, b.Material = "RoundBasin", true, Vector3.new(1.4, 20, 20), STONE, Enum.Material.Concrete
	b.CFrame = cf * CFrame.new(0, 0.7, 6) * CFrame.Angles(0, 0, math.pi / 2)
	b.Parent = m
	local w = b:Clone()
	w.Name, w.Size, w.Color, w.Material, w.Transparency, w.Reflectance, w.CanCollide = "Water", Vector3.new(0.3, 17.4, 17.4), WATER, Enum.Material.SmoothPlastic, 0.2, 0.25, false
	w.CFrame = cf * CFrame.new(0, 1.42, 6) * CFrame.Angles(0, 0, math.pi / 2)
	w.Parent = m
	jet(m, (cf * CFrame.new(0, 1.5, 6)).Position, 12, 34)
	for _, x in { -26, -13, 13, 26 } do
		bench(m, cf * CFrame.new(x, 0, -hd + 9))
	end
	for _, c in { { -hw + 2, -hd + 3 }, { hw - 2, -hd + 3 }, { -hw + 2, hd - 3 }, { hw - 2, hd - 3 } } do
		lamp(m, cf * CFrame.new(c[1], 0, c[2]), true)
	end
	for _, x in { -34, 34 } do
		plant(m, "Shrub", 1.8, cf * CFrame.new(x, 0, 14))
		plant(m, "Shrub", 1.8, cf * CFrame.new(x, 0, -6))
	end
	part(m, "SignPost", Vector3.new(0.6, 7, 0.6), cf * CFrame.new(-36.5, 3.5, hd - 4), DARK, Enum.Material.Metal)
	part(m, "SignPost", Vector3.new(0.6, 7, 0.6), cf * CFrame.new(-23.5, 3.5, hd - 4), DARK, Enum.Material.Metal)
	sign(m, cf * CFrame.new(-30, 6.5, hd - 4), 14, 5, "SHWEDAGON VIEW POINT", "People's Park")
	m:SetAttribute("ViewSpot", (cf * CFrame.new(0, 3, 0)).Position)
	return #m:GetDescendants()
end

-- People's Square, the big fountain and the Elephant Fountain at the west head
function P.square()
	local m = model("PeoplesSquare")
	local pf = profile(P.RECTS.square, 24.2)
	ribbon(m, pf, "Square", 0, 170, 0.6, 5, PAVE, Enum.Material.Concrete, nil, nil, true)
	flush()
	for s = -pf.len / 2 + 48, pf.len / 2 - 48, 96.8 do
		ribbon(m, pf, "Band", 0, 170, 0.68, 0.3, PAVE2, Enum.Material.Concrete, s - 3, s + 3, false, false)
	end
	for _, side in { -1, 1 } do
		for s = -pf.len / 2 + 24, pf.len / 2 - 24, 48.4 do
			lamp(m, frameAt(pf, s, side * 80, 0.6), false)
		end
	end
	task.wait()
	local r = P.RECTS.fountA
	local f = profile(r, 30)
	local c = at(f, 0, 0, 0)
	local cf = CFrame.lookAt(c, c + f.u)
	T:FillBlock(cf * CFrame.new(0, -4, 0), Vector3.new(r[4] + 16, 8, r[3] + 16), Enum.Material.Grass)
	T:FillBlock(cf * CFrame.new(0, 6, 0), Vector3.new(r[4] + 14, 12, r[3] + 14), Enum.Material.Air)
	part(m, "FountainApron", Vector3.new(r[4] + 14, 2, r[3] + 14), cf * CFrame.new(0, -0.6, 0), PAVE, Enum.Material.Concrete)
	local jets = {}
	for i = -2, 2 do
		table.insert(jets, { 0, i * 24, if i == 0 then 22 else 14, 34 })
		table.insert(jets, { -22, i * 24, 7 })
		table.insert(jets, { 22, i * 24, 7 })
	end
	basin(m, cf * CFrame.new(0, 0.4, 0), r[4] - 8, r[3] - 8, 2, jets)
	local re = P.RECTS.eleph
	local y = gy(re[1], re[2]) or 63
	local ec = CFrame.new(re[1], y + 0.4, re[2])
	T:FillBlock(ec * CFrame.new(0, 6, 0), Vector3.new(84, 12, 84), Enum.Material.Air)
	local function disc(name, d, h, up, color, tr)
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Name, p.Anchored, p.Size, p.Color, p.Material = name, true, Vector3.new(h, d, d), color, Enum.Material.Concrete
		p.CFrame = ec * CFrame.new(0, up, 0) * CFrame.Angles(0, 0, math.pi / 2)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if tr then p.Transparency, p.Reflectance, p.CanCollide, p.Material = tr, 0.25, false, Enum.Material.SmoothPlastic end
		p.Parent = m
	end
	disc("ElephantApron", 80, 1.2, 0, PAVE)
	disc("ElephantBasin", 62, 2.2, 1.1, STONE)
	disc("Water", 58, 0.3, 2.3, WATER, 0.2)
	disc("Plinth", 14, 4, 2.6, WHITE)
	jet(m, (ec * CFrame.new(0, 5, 0)).Position, 16, 34)
	for k = 0, 2 do
		local a = ec * CFrame.Angles(0, k * math.pi * 2 / 3, 0) * CFrame.new(0, 2.2, -19)
		part(m, "ElephantBody", Vector3.new(4.4, 4.2, 7.4), a * CFrame.new(0, 4.3, 0), WHITE, Enum.Material.SmoothPlastic)
		part(m, "ElephantHead", Vector3.new(3.4, 3.4, 3), a * CFrame.new(0, 5.4, -4.8), WHITE, Enum.Material.SmoothPlastic)
		part(m, "ElephantTrunk", Vector3.new(1, 4.4, 1), a * CFrame.new(0, 3.4, -6.6) * CFrame.Angles(math.rad(-18), 0, 0), WHITE, Enum.Material.SmoothPlastic)
		for _, x in { -1.5, 1.5 } do
			part(m, "ElephantEar", Vector3.new(0.4, 2.8, 2.2), a * CFrame.new(x * 1.35, 5.5, -3.9), WHITE, Enum.Material.SmoothPlastic)
			for _, z in { -2.4, 2.4 } do
				part(m, "ElephantLeg", Vector3.new(1.3, 2.4, 1.3), a * CFrame.new(x * 0.95, 1.1, z), WHITE, Enum.Material.SmoothPlastic)
			end
		end
		jet(m, (a * CFrame.new(0, 2.4, -8)).Position, 6, 18)
	end
	return #m:GetDescendants()
end

-- a car park: one asphalt tile per bay (level, on its own ground), rows of bays and aisles across the lot. Tiles that
-- would lie on a road or pavement of the map are left out: the park's own service roads stay as they are.
function P.carpark(key, name, title)
	local r = P.RECTS[key]
	local pf = profile(r, 27)
	local m = model(name)
	local W, H = r[4], r[3] / 2
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { workspace.Yangon1to1.Roads }
	local bay, aisle, bw = 19, 24, 9
	local rows = {}
	local o, turn = -W / 2 + 1, 0
	while o + bay <= W / 2 - 1 do
		table.insert(rows, { o, bay, true })
		o += bay
		turn += 1
		if turn % 2 == 1 and o + aisle + bay <= W / 2 - 1 then
			table.insert(rows, { o, aisle, false })
			o += aisle
		end
	end
	local n, made = 0, 0
	for _, row in rows do
		local mid = row[1] + row[2] / 2
		for s = -H + bw / 2, H - bw / 2, bw do
			n += 1
			if n % 40 == 0 then task.wait() end
			local p = pf.c + pf.u * s + pf.v * mid
			local top = -1e9
			for _, d in { { 0, 0 }, { 3, 6 }, { -3, 6 }, { 3, -6 }, { -3, -6 } } do
				local q = p + pf.u * d[1] + pf.v * d[2]
				local y = gy(q.X, q.Z)
				if y and y > top then top = y end
			end
			if top < -1e8 then continue end
			local o3 = Vector3.new(p.X, top + 0.35, p.Z)
			local cf = CFrame.lookAt(o3, o3 + pf.u)
			if #workspace:GetPartBoundsInBox(cf, Vector3.new(row[2] + 2, 14, bw + 2), op) > 0 then continue end
			made += 1
			part(m, "Asphalt", Vector3.new(row[2] + 0.02, 5, bw + 0.02), cf * CFrame.new(0, -2.5, 0), ASPH, Enum.Material.Asphalt)
			table.insert(airJobs, { cf * CFrame.new(0, 4.5, 0), Vector3.new(row[2], 11, bw) })
			if row[3] then
				part(m, "BayLine", Vector3.new(row[2] - 1, 0.1, 0.4), cf * CFrame.new(0, 0.06, bw / 2 - 0.2), WHITE, Enum.Material.SmoothPlastic, false)
			end
		end
	end
	flush()
	for _, side in { -1, 1 } do
		for s = -H + 30, H - 30, 60 do
			local p = pf.c + pf.u * s + pf.v * (side * (W / 2 + 2))
			local y = gy(p.X, p.Z)
			if y and #workspace:GetPartBoundsInBox(CFrame.new(p.X, y, p.Z), Vector3.new(4, 14, 4), op) == 0 then
				lamp(m, CFrame.new(p.X, y, p.Z), false)
				plant(m, "Shrub", rng:NextNumber(1.1, 1.5), CFrame.new(p.X, y, p.Z) * CFrame.new(5, 0, 0))
			end
		end
	end
	for _, s in { -H + 3, H - 3 } do
		local p = pf.c + pf.u * s + pf.v * (W / 2 + 3)
		local y = gy(p.X, p.Z) or hAt(pf, s)
		local cf = CFrame.lookAt(Vector3.new(p.X, y, p.Z), Vector3.new(p.X, y, p.Z) + pf.u)
		part(m, "SignPost", Vector3.new(0.6, 12, 0.6), cf * CFrame.new(0, 6, 0), DARK, Enum.Material.Metal)
		local b = sign(m, cf * CFrame.new(0, 12.5, 0), 12, 5, "P", title)
		b.Color = Color3.fromRGB(28, 70, 150)
	end
	m:SetAttribute("Bays", made)
	return #m:GetDescendants()
end

-- The Central: paved forecourt with a fountain in front of the pavilion, a car park and its drive
function P.central()
	local m = model("TheCentral")
	local pf = profile(P.RECTS.centralPlaza, 27)
	ribbon(m, pf, "Plaza", 0, 84, 0.3, 5, PAVE, Enum.Material.Concrete, nil, nil, true)
	flush()
	for s = -27, 27, 27 do
		ribbon(m, pf, "Band", 0, 84, 0.38, 0.3, PAVE2, Enum.Material.Concrete, s - 2, s + 2, false, false)
	end
	local c = at(pf, 26, 16, 0.3)
	local ec = CFrame.new(c)
	local function disc(name, d, h, up, color, tr)
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Name, p.Anchored, p.Size, p.Color, p.Material = name, true, Vector3.new(h, d, d), color, Enum.Material.Concrete
		p.CFrame = ec * CFrame.new(0, up, 0) * CFrame.Angles(0, 0, math.pi / 2)
		if tr then p.Transparency, p.Reflectance, p.CanCollide, p.Material = tr, 0.25, false, Enum.Material.SmoothPlastic end
		p.Parent = m
	end
	disc("FountainBasin", 26, 1.8, 0.9, STONE)
	disc("Water", 23, 0.3, 1.9, WATER, 0.2)
	jet(m, (ec * CFrame.new(0, 2, 0)).Position, 11, 34)
	for k = 0, 5 do
		jet(m, (ec * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 2, -8)).Position, 5, 16)
	end
	for _, o in { -40, 40 } do
		for s = -45, 45, 30 do
			lamp(m, frameAt(pf, s, o, 0.3), s == -15 or s == 15)
		end
		for s = -30, 30, 30 do
			local cf = frameAt(pf, s, o * 0.94, 0.3)
			part(m, "Planter", Vector3.new(5, 1.6, 5), cf * CFrame.new(0, 0.8, 0), WHITE, Enum.Material.Concrete)
			plant(m, "Shrub", 1.5, cf * CFrame.new(0, 1.6, 0))
		end
	end
	bench(m, frameAt(pf, 26, -8, 0.3) * CFrame.Angles(0, math.pi / 2, 0))
	bench(m, frameAt(pf, 8, 16, 0.3) * CFrame.Angles(0, -math.pi / 2, 0))
	task.wait()
	for _, key in { "centralDrive", "centralLeg" } do
		local d = profile(P.RECTS[key], 27)
		ribbon(m, d, "Drive", 0, P.RECTS[key][4], 0.35, 5, ASPH, Enum.Material.Asphalt, nil, nil, true)
	end
	flush()
	local d = profile(P.RECTS.centralDrive, 27)
	for s = -60, 60, 12 do
		part(m, "DriveDash", Vector3.new(0.4, 0.1, 6), frameAt(d, s, 0, 0.42), WHITE, Enum.Material.SmoothPlastic, false)
	end
	local n = #m:GetDescendants()
	return n .. ", car park " .. P.carpark("centralPark", "TheCentralCarPark", "The Central")
end

-- (2026-11-28, owner: "most importantly, do the People's park near shwedagon pagoda, people do car meets & drift a lot
-- there") the car meet on People's Square: one smooth asphalt drift pad on the square's own ground line (the paving's
-- 24-stud profile, so no step), tyre-mark decals that never overlap, twin white lamps (Config.NightLamps look) along
-- both long sides, the invisible MeetZone (server Dealership's meet bonus + the minimap's M), and the crowd / show-car
-- spots for client YangonStreetLife (returned as chunk lines; save them as src/shared/YangonStreetLifeMeet.lua)
P.MEET = { s0 = -170, s1 = 170, half = 62 } -- along the square / half across (the square's globe lamps stand at 80)
P.MARKS = { donut = "rbxassetid://116259565084700", arc = "rbxassetid://128409324099510" } -- tools/yangon/city/tyre_marks.py uploads
local ORIGIN = { 27900, -6500 } -- YangonStreetLife's origin
function P.meet()
	local m = model("CarMeet")
	local pf = profile(P.RECTS.square, 24.2)
	local M = P.MEET
	local LIFT = 0.86 -- pad top over the ground line (the paving is 0.6, its bands 0.68)
	ribbon(m, pf, "DriftPad", 0, M.half * 2, LIFT, 0.7, ASPH, Enum.Material.Asphalt, M.s0, M.s1, false, true)
	for _, p in m:GetChildren() do
		p.CastShadow = false
		pcall(function() p.MaterialVariant = "YgnRoadAsphalt" end)
	end
	-- the meet zone (Dealership reads it): pad middle, X across, Z along
	local mid = frameAt(pf, (M.s0 + M.s1) / 2, 0, LIFT)
	local z = part(m, "MeetZone", Vector3.new(M.half * 2, 30, M.s1 - M.s0), mid, DARK, nil, false)
	z.Transparency, z.CanQuery, z.CanTouch = 1, false, false
	-- tyre marks: decals on invisible carriers 0.16 over the pad (a 26-stud mark spans a profile joint: up to ~0.13 of bend),
	-- never overlapping (centres 38+ apart); the car's own skids (0.07 up) pass under them
	local rngM = Random.new(2811)
	local placed = {}
	for i = 1, 400 do
		if #placed >= 11 then break end
		local s, o = rngM:NextNumber(M.s0 + 20, M.s1 - 20), rngM:NextNumber(-M.half + 18, M.half - 18)
		local ok = true
		for _, q in placed do
			if (q - Vector2.new(s, o)).Magnitude < 38 then ok = false break end
		end
		if ok then
			table.insert(placed, Vector2.new(s, o))
			local f = frameAt(pf, s, o, LIFT) * CFrame.Angles(0, rngM:NextNumber(0, math.pi * 2), 0)
			local c = part(m, "TyreMarks", Vector3.new(26, 0.05, 26), f * CFrame.new(0, 0.16 - 0.025, 0), DARK, nil, false)
			c.Transparency, c.CanQuery, c.CanTouch, c.CastShadow = 1, false, false, false
			local d = Instance.new("Decal")
			d.Face = Enum.NormalId.Top
			d.Texture = if #placed % 3 == 0 then P.MARKS.arc else P.MARKS.donut
			d.Transparency = 0.15
			d.Parent = c
		end
	end
	-- lamps: the street kit's twin lamp2 (as client YangonMedians places it: its own light + glow, tags LODLight / DayOff
	-- / LampHalo, so WorldFx lights it at night), one post every 54 studs along both long sides, arms across the pad
	local KD = require(RS.Shared.YangonKitData)
	local kit = KD.index(RS.YgnKit.Templates).lamp2 or {}
	local NL = require(RS.Shared.Config).NightLamps
	local CS = game:GetService("CollectionService")
	local nLamp, nLight = 0, 0
	for _, side in { -1, 1 } do
		for s = M.s0 + 10, M.s1 - 9, 54 do
			local f = frameAt(pf, s, side * (M.half + 6), 0.6)
			f = CFrame.lookAt(f.Position, f.Position + pf.u) * CFrame.Angles(0, math.pi / 2, 0)
			local lm = Instance.new("Model")
			lm.Name = "MeetLamp"
			for _, tp in kit do
				local q = tp.part:Clone()
				q.CFrame = f * CFrame.new(tp.c)
				q.Parent = lm
			end
			local post = part(lm, "PostCollide", Vector3.new(0.6, 30, 0.6), f * CFrame.new(0, 15, 0), DARK, nil, true)
			post.Transparency = 1
			local lit = false
			for _, d in lm:GetDescendants() do
				if d:IsA("Light") then lit = true nLight += 1 end
			end
			if not lit then -- (no kit light: one white NightLamps light under the heads)
				local a = Instance.new("Attachment")
				a.Name, a.Position = "LampLight", Vector3.new(0, 14, 0)
				a.Parent = post
				local l = Instance.new("PointLight")
				l.Color, l.Brightness, l.Range, l.Shadows = NL.Color, NL.Brightness, NL.Range, false
				l.Parent = a
				CS:AddTag(l, "DayOff")
				nLight += 1
			end
			lm.Parent = m
			nLamp += 1
		end
	end
	-- street-life lines: show cars nose-in at both ends of the pad, onlookers along the long sides and the ends
	local lines = {}
	local function enc(p, yaw)
		return string.format("%d %d %d %d", math.round((p.X - ORIGIN[1]) * 10), math.round((p.Z - ORIGIN[2]) * 10), math.round(p.Y * 10), math.round(math.deg(yaw) * 10))
	end
	local function yawTo(p, q)
		local d = q - p
		return math.atan2(-d.X, -d.Z) -- (YangonStreetLife: CFrame.Angles(0, yaw, 0), front -Z)
	end
	local centre = at(pf, 0, 0, LIFT)
	local kinds = { "A", "B", "C", "D", "E" }
	for _, e in { -1, 1 } do
		local k = 0
		for o = -48, 48, 12 do
			k += 1
			local p = at(pf, e * ((M.s1 - M.s0) / 2 + 14), o, 0.6)
			local faceTo = at(pf, 0, o * 0.6, 0.6)
			table.insert(lines, "C " .. enc(p, yawTo(p, faceTo)) .. " " .. kinds[(k % #kinds) + 1] .. " 11 0")
		end
	end
	local nS = 0
	for _, side in { -1, 1 } do
		for s = M.s0 + 4, M.s1 - 4, 9 do
			if (s - M.s0) % 54 > 6 then -- (not on a lamp)
				local p = at(pf, s, side * (M.half + rngM:NextNumber(5, 12)), 0.6)
				table.insert(lines, "S " .. enc(p, yawTo(p, at(pf, s, 0, 0.6))) .. " meet")
				nS += 1
			end
		end
	end
	for _, e in { -1, 1 } do
		for o = -54, 54, 9 do
			local p = at(pf, e * ((M.s1 - M.s0) / 2 + 30), o + rngM:NextNumber(-2, 2), 0.6)
			table.insert(lines, "S " .. enc(p, yawTo(p, centre)) .. " meet")
			nS += 1
		end
	end
	m:SetAttribute("Lamps", nLamp)
	m:SetAttribute("Marks", #placed)
	return table.concat(lines, "\n"), string.format("pad %d parts, %d marks, %d lamps (%d kit pieces, %d lights), %d spots", #m:GetChildren(), #placed, nLamp, #kit, nLight, nS)
end
-- (2026-11-28, owner: "do u not see how the people park is rn?" + "these too") the rest of People's Park from OSM
-- (tools/yangon/PeoplesParkOSM.luau, made by tools/yangon/city/peoples_park_osm.py): terrain Water in the lakes / ponds
-- that have none, the footways and park drives as paving that follows the ground (joint discs at the bends, each way a
-- little higher than the last so crossings never z-fight; a stretch the map already paves is left alone), bridge decks,
-- pools, the pitches' lines and goals, small fountains, gate pillars, globe lamps (LODLight / DayOff) and benches beside
-- the paths, and the shade trees: OSM's mapped trees plus a fill where the lawns are bare, as streamed tree-kit records
-- (ReplicatedStorage.YgnKit.Data_PPG, YangonKitStream) with far looks (Green.Far.Cell_PP, attribute T).
-- No tree, lamp or path on the car meet, the square, the fountain garden or the Shwedagon view line along its axis.
function P.grounds()
	local D = require(game:GetService("ServerStorage").ClaudeTools.PeoplesParkOSM:Clone())
	local CS = game:GetService("CollectionService")
	local m = model("ParkGrounds")
	local R = Random.new(2811)
	local wp = RaycastParams.new()
	wp.FilterType = Enum.RaycastFilterType.Include
	wp.FilterDescendantsInstances = { T }
	wp.IgnoreWater = false
	local function wy(x, z) -- terrain top with water, and whether it is water
		local h = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -1000, 0), wp)
		return h and h.Position.Y, h ~= nil and h.Material == Enum.Material.Water
	end
	local xp = RaycastParams.new()
	xp.FilterType = Enum.RaycastFilterType.Exclude
	local function covered(x, z, g) -- a visible map part (road, paving, building) within 3 of the ground here
		local ex = { T, m }
		for _ = 1, 6 do
			xp.FilterDescendantsInstances = ex
			local h = workspace:Raycast(Vector3.new(x, g + 80, z), Vector3.new(0, -86, 0), xp)
			if not h then return false end
			if h.Instance.Transparency < 0.9 then return h.Position.Y > g - 3 end
			table.insert(ex, h.Instance)
		end
		return false
	end
	local function poly(px, x, z)
		local c, n = false, #px / 2
		local j = n
		for i = 1, n do
			local x1, z1, x2, z2 = px[2 * i - 1], px[2 * i], px[2 * j - 1], px[2 * j]
			if (z1 > z) ~= (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1) + x1 then c = not c end
			j = i
		end
		return c
	end
	local function inBox(b, x, z, pad) -- b = { x, z, length, width, angle }
		local a = math.rad(b[5])
		local dx, dz = x - b[1], z - b[2]
		local u = dx * math.cos(a) + dz * math.sin(a)
		local v = -dx * math.sin(a) + dz * math.cos(a)
		return math.abs(u) <= b[3] / 2 + pad and math.abs(v) <= b[4] / 2 + pad
	end
	local function boxCF(b, y)
		local a = math.rad(b[5])
		local u = Vector3.new(math.cos(a), 0, math.sin(a))
		local c = Vector3.new(b[1], y, b[2])
		return CFrame.lookAt(c, c + u) -- length along Z
	end
	-- the places already built (car meet, square, garden, fountains, car parks)
	local built = {}
	for k, pad in { garden = 14, square = 14, fountA = 14, eleph = 14, parkPP = 8, parkSW = 8 } do
		table.insert(built, { P.RECTS[k], pad })
	end
	local G = P.RECTS.garden
	local ga = math.rad(G[5])
	local gu = Vector2.new(math.cos(ga), math.sin(ga))
	local function inView(x, z) -- the Shwedagon sight line: the garden's axis, from past the square's west end eastwards
		local d = Vector2.new(x - G[1], z - G[2])
		local s, o = d:Dot(gu), math.abs(d.X * -gu.Y + d.Y * gu.X)
		return o < 72 and s > -G[3] / 2 - 160 and s < G[3] / 2 + 700 -- (+u points west: the square is at s ~ +820)
	end
	local function onBuilt(x, z, pad)
		for _, b in built do
			if inBox(b[1], x, z, b[2] + (pad or 0)) then return true end
		end
		return inView(x, z)
	end
	local stats = {}

	-- 1. water: lakes / ponds with no terrain water yet (level a little under the lowest bank, on the 4-stud grid)
	local nW = 0
	for _, w in D.water do
		local px = w.p
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		local bank = math.huge
		for i = 1, #px, 2 do
			minX, maxX = math.min(minX, px[i]), math.max(maxX, px[i])
			minZ, maxZ = math.min(minZ, px[i + 1]), math.max(maxZ, px[i + 1])
			local g = gy(px[i], px[i + 1])
			if g then bank = math.min(bank, g) end
		end
		local level = math.floor((bank - 1.5) / 4) * 4
		for z = math.floor(minZ / 4) * 4 + 2, maxZ, 4 do
			local x0 = nil
			local function run(x1)
				if x0 then
					local len = x1 - x0
					local cx = (x0 + x1) / 2 - 2
					T:FillBlock(CFrame.new(cx, level + 24, z), Vector3.new(len, 48, 4), Enum.Material.Air)
					T:FillBlock(CFrame.new(cx, level - 5, z), Vector3.new(len, 10, 4), Enum.Material.Water)
					T:FillBlock(CFrame.new(cx, level - 12, z), Vector3.new(len, 4, 4), Enum.Material.Mud)
					nW += 1
					x0 = nil
				end
			end
			for x = math.floor(minX / 4) * 4 + 2, maxX + 4, 4 do
				local _, wet = wy(x, z)
				if poly(px, x, z) and not wet then
					x0 = x0 or x
				else
					run(x)
				end
			end
			run(maxX + 4)
			task.wait()
		end
	end
	stats.water = nW

	-- 2. paths
	local PATHW = { footway = 7, path = 5, steps = 7, pedestrian = 14, service = 11 }
	local PCOL = { service = Color3.fromRGB(150, 146, 138) }
	local bridges = {}
	for _, b in D.box do
		if b[1] == "bridge" then table.insert(bridges, { b[2], b[3], b[4], b[5], b[6] }) end
	end
	local function onBridge(x, z)
		for _, b in bridges do
			if inBox(b, x, z, 2) then return true end
		end
		return false
	end
	local ways = {} -- { kind, w, p = points with heights } for lamps / trees
	local nSeg, nSkip, wi = 0, 0, 0
	for _, way in D.ways do
		local kind, pts = way[1], way[3]
		local w = PATHW[kind] or 7
		local v = {} -- densified to <= 20 studs
		for i = 1, #pts - 2, 2 do
			local a, b = Vector2.new(pts[i], pts[i + 1]), Vector2.new(pts[i + 2], pts[i + 3])
			local n = math.max(1, math.ceil((b - a).Magnitude / 20))
			for k = 0, n - 1 do table.insert(v, a:Lerp(b, k / n)) end
		end
		table.insert(v, Vector2.new(pts[#pts - 1], pts[#pts]))
		wi += 1
		local lift = 0.3 + (wi % 5) * 0.05
		local H = {}
		for i, q in v do
			local hi = -math.huge
			for _, o in { Vector2.zero, Vector2.new(w / 2, 0), Vector2.new(-w / 2, 0), Vector2.new(0, w / 2), Vector2.new(0, -w / 2) } do
				local g = gy(q.X + o.X, q.Y + o.Y)
				if g then hi = math.max(hi, g) end
			end
			H[i] = if hi > -1e6 then hi + lift else 66
		end
		local joint = {}
		local col = PCOL[kind] or PAVE
		for i = 1, #v - 1 do
			local a, b = v[i], v[i + 1]
			local mid = (a + b) / 2
			local g = gy(mid.X, mid.Y) or H[i]
			local _, wet = wy(mid.X, mid.Y)
			if wet or onBridge(mid.X, mid.Y) or onBuilt(mid.X, mid.Y, -2) or covered(mid.X, mid.Y, g) or (a - b).Magnitude < 0.5 then
				nSkip += 1
			else
				local A3, B3 = Vector3.new(a.X, H[i], a.Y), Vector3.new(b.X, H[i + 1], b.Y)
				local cf = CFrame.lookAt((A3 + B3) / 2, B3)
				part(m, "Path", Vector3.new(w, 1, (B3 - A3).Magnitude), cf * CFrame.new(0, -0.5, 0), col, Enum.Material.Concrete)
				for _, e in { { A3, i }, { B3, i + 1 } } do
					if e[2] > 1 and e[2] < #v and not joint[e[2]] then
						joint[e[2]] = true
						local d = part(m, "PathJoint", Vector3.new(1, w, w), CFrame.new(e[1] + Vector3.new(0, -0.47, 0)) * CFrame.Angles(0, 0, math.pi / 2), col, Enum.Material.Concrete)
						d.Shape = Enum.PartType.Cylinder
					end
				end
				nSeg += 1
				if nSeg % 150 == 0 then task.wait() end
			end
		end
		local p3 = {}
		for i, q in v do p3[i] = Vector3.new(q.X, H[i], q.Y) end
		table.insert(ways, { kind = kind, w = w, p = p3 })
	end
	stats.paths, stats.pathSkip = nSeg, nSkip
	local function nearWay(x, z, extra)
		local q = Vector2.new(x, z)
		for _, w in ways do
			local r = w.w / 2 + extra
			for i = 1, #w.p - 1 do
				local a, b = Vector2.new(w.p[i].X, w.p[i].Z), Vector2.new(w.p[i + 1].X, w.p[i + 1].Z)
				local ab = b - a
				local t = if ab.Magnitude > 0 then math.clamp((q - a):Dot(ab) / ab:Dot(ab), 0, 1) else 0
				if (a + ab * t - q).Magnitude < r then return true end
			end
		end
		return false
	end

	-- 3. bridge decks with rails (level, on the higher bank)
	for _, b in bridges do
		local a = math.rad(b[5])
		local u = Vector3.new(math.cos(a), 0, math.sin(a))
		local e1, e2 = Vector3.new(b[1], 0, b[2]) + u * (b[3] / 2), Vector3.new(b[1], 0, b[2]) - u * (b[3] / 2)
		local y = math.max(gy(e1.X, e1.Z) or 66, gy(e2.X, e2.Z) or 66) + 0.6
		local cf = boxCF(b, y)
		local wd = math.max(b[4], 8)
		part(m, "BridgeDeck", Vector3.new(wd, 1.2, b[3] + 6), cf * CFrame.new(0, -0.6, 0), Color3.fromRGB(150, 112, 78), Enum.Material.WoodPlanks)
		for _, sx in { -1, 1 } do
			part(m, "BridgeRail", Vector3.new(0.4, 0.4, b[3] + 6), cf * CFrame.new(sx * (wd / 2 - 0.3), 3.2, 0), Color3.fromRGB(196, 60, 46), Enum.Material.Wood)
			for z = -b[3] / 2 - 2, b[3] / 2 + 2, 6 do
				part(m, "BridgePost", Vector3.new(0.5, 3, 0.5), cf * CFrame.new(sx * (wd / 2 - 0.3), 1.5, z), Color3.fromRGB(196, 60, 46), Enum.Material.Wood)
			end
		end
	end

	-- 4. pools, pitches, other car parks, small fountains, gardens' shrubs
	local trunks = {} -- { Vector2, r } kept clear by trees / lamps / benches
	local nPool, nPitch, nPark, nFount, nShrub = 0, 0, 0, 0, 0
	for _, bx in D.box do
		local kind, b = bx[1], { bx[2], bx[3], bx[4], bx[5], bx[6] }
		local g = gy(b[1], b[2])
		if not g or onBuilt(b[1], b[2]) then continue end
		if kind == "pool" then
			if not covered(b[1], b[2], g) then
				local lo = math.huge
				for _, c in { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } } do
					local cf = boxCF(b, 0) * CFrame.new(c[1] * b[4] / 2, 0, c[2] * b[3] / 2)
					lo = math.min(lo, gy(cf.X, cf.Z) or g)
				end
				T:FillBlock(boxCF(b, lo + 6), Vector3.new(b[4] + 8, 12, b[3] + 8), Enum.Material.Air)
				part(m, "PoolDeck", Vector3.new(b[4] + 8, 1.2, b[3] + 8), boxCF(b, lo - 0.5), PAVE, Enum.Material.Concrete)
				basin(m, boxCF(b, lo + 0.1), math.max(b[4] - 2, 4), math.max(b[3] - 2, 4), 1.2, nil, TILE)
				nPool += 1
			end
		elseif kind == "pitch" then
			local pf = profile(b, 20)
			for _, o in { -b[4] / 2, b[4] / 2 } do
				ribbon(m, pf, "PitchLine", o, 0.6, 0.12, 0.3, WHITE, Enum.Material.SmoothPlastic, nil, nil, false, false)
			end
			for _, s0 in { -b[3] / 2 + 0.4, 0, b[3] / 2 - 0.4 } do
				part(m, "PitchLine", Vector3.new(b[4] - 0.6, 0.3, 0.6), frameAt(pf, s0, 0, 0.12) * CFrame.new(0, -0.15, 0), WHITE, Enum.Material.SmoothPlastic, false)
			end
			for _, e in { -1, 1 } do
				local f = frameAt(pf, e * (b[3] / 2 - 1), 0, 0)
				for _, x in { -11, 11 } do
					part(m, "GoalPost", Vector3.new(0.5, 7.5, 0.5), f * CFrame.new(x, 3.75, 0), WHITE, Enum.Material.Metal)
				end
				part(m, "GoalBar", Vector3.new(22.5, 0.5, 0.5), f * CFrame.new(0, 7.5, 0), WHITE, Enum.Material.Metal)
			end
			nPitch += 1
		elseif kind == "parking" then
			if not covered(b[1], b[2], g) then
				local key = "pp" .. bx.id
				P.RECTS[key] = b
				P.carpark(key, "ParkCarPark" .. bx.id, "People's Park")
				nPark += 1
			end
		elseif kind == "garden" and b[3] * b[4] < 30000 then
			for _ = 1, math.floor(b[3] * b[4] / 260) do
				local u, v = R:NextNumber(-0.45, 0.45) * b[3], R:NextNumber(-0.45, 0.45) * b[4]
				local cf = boxCF(b, 0) * CFrame.new(v, 0, -u)
				local y = gy(cf.X, cf.Z)
				if y and not nearWay(cf.X, cf.Z, 2) and not covered(cf.X, cf.Z, y) then
					local k = R:NextInteger(1, 6)
					plant(m, if k == 1 then "Shrub" elseif k == 2 then "Spiky" else "Low", R:NextNumber(1, 1.5), CFrame.new(cf.X, y, cf.Z))
					nShrub += 1
				end
			end
			task.wait()
		end
	end
	for _, f in D.fount do
		local b = { f[1], f[2], math.max(f[3], 10), math.max(f[4], 10), f[5] }
		local g = gy(b[1], b[2])
		if g and not onBuilt(b[1], b[2], 30) and not covered(b[1], b[2], g) then
			T:FillBlock(boxCF(b, g + 6), Vector3.new(b[4] + 8, 12, b[3] + 8), Enum.Material.Air)
			part(m, "FountainApron", Vector3.new(b[4] + 8, 1.2, b[3] + 8), boxCF(b, g - 0.4), PAVE, Enum.Material.Concrete)
			basin(m, boxCF(b, g + 0.2), b[4] - 3, b[3] - 3, 1.6, { { 0, 0, 10, 24 } })
			table.insert(trunks, { Vector2.new(b[1], b[2]), math.max(b[3], b[4]) / 2 + 6 })
			nFount += 1
		end
	end
	stats.pools, stats.pitches, stats.carparks, stats.founts, stats.shrubs = nPool, nPitch, nPark, nFount, nShrub
	task.wait()

	-- 5. trees: the mapped ones first (their real spots), then a fill on the bare lawns
	local placed = {}
	local GH = 64
	local grid = {}
	local function clear(x, z, r, k)
		local gi, gj = math.floor(x / GH), math.floor(z / GH)
		for a = gi - 2, gi + 2 do
			for c = gj - 2, gj + 2 do
				for _, t in grid[a * 100000 + c] or {} do
					if math.sqrt((t.x - x) ^ 2 + (t.z - z) ^ 2) < k * (t.r + r) then return false end
				end
			end
		end
		return true
	end
	local function inPark(x, z) return poly(D.park, x, z) end
	local boxes = {}
	for _, bx in D.box do
		if bx[1] == "parking" or bx[1] == "pool" or bx[1] == "pitch" or bx[1] == "bridge" then
			table.insert(boxes, { bx[2], bx[3], bx[4], bx[5], bx[6] })
		end
	end
	local bp = OverlapParams.new()
	bp.FilterType = Enum.RaycastFilterType.Exclude
	bp.FilterDescendantsInstances = { T }
	local function treeOk(x, z, r, k)
		if not inPark(x, z) or onBuilt(x, z, 4) then return nil end
		for _, b in boxes do
			if inBox(b, x, z, 5) then return nil end
		end
		for _, t in trunks do
			if (t[1] - Vector2.new(x, z)).Magnitude < t[2] then return nil end
		end
		local g, wet = wy(x, z)
		if not g or wet then return nil end
		for _, o in { { 9, 0 }, { -9, 0 }, { 0, 9 }, { 0, -9 } } do
			local _, w2 = wy(x + o[1], z + o[2])
			if w2 then return nil end
		end
		if nearWay(x, z, 3) or not clear(x, z, r, k) then return nil end
		if #workspace:GetPartBoundsInRadius(Vector3.new(x, g + 3, z), 6, bp) > 0 then return nil end
		return g
	end
	local function add(x, z, Dm, palm, g)
		local t = { x = x, z = z, r = Dm * 1.5, palm = palm, g = g, Dm = Dm, yaw = R:NextNumber(0, math.pi * 2) }
		table.insert(placed, t)
		local key = math.floor(x / GH) * 100000 + math.floor(z / GH)
		grid[key] = grid[key] or {}
		table.insert(grid[key], t)
	end
	local function nearWater(x, z)
		for _, o in { { 40, 0 }, { -40, 0 }, { 0, 40 }, { 0, -40 } } do
			local _, w2 = wy(x + o[1], z + o[2])
			if w2 then return true end
		end
		return false
	end
	local tr = D.trees
	local nMapped = 0
	for i = 1, #tr, 2 do
		local x, z = tr[i], tr[i + 1]
		local Dm = R:NextNumber(12, 20)
		local g = treeOk(x, z, Dm * 1.5, 0.3)
		if g then
			add(x, z, Dm, false, g)
			nMapped += 1
		end
		if i % 200 == 1 then task.wait() end
	end
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for i = 1, #D.park, 2 do
		minX, maxX = math.min(minX, D.park[i]), math.max(maxX, D.park[i])
		minZ, maxZ = math.min(minZ, D.park[i + 1]), math.max(maxZ, D.park[i + 1])
	end
	local nFill = 0
	for x = minX + 20, maxX, 44 do
		for z = minZ + 20, maxZ, 44 do
			local px, pz = x + R:NextNumber(-15, 15), z + R:NextNumber(-15, 15)
			local palm = nearWater(px, pz) and R:NextNumber() < 0.35
			local Dm = if palm then 8 else R:NextNumber(13, 22)
			local g = treeOk(px, pz, Dm * 1.5, 0.55)
			if g then
				add(px, pz, Dm, palm, g)
				nFill += 1
			end
		end
		task.wait()
	end
	stats.treesMapped, stats.treesFill = nMapped, nFill

	-- the streamed records (kit_pack.py's Q record: pid, x, y, z, yaw, sx, code, sy, sz) and the far looks
	local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
	local function enc(v, n)
		v = math.round(v)
		assert(v >= 0 and v < 64 ^ n, "enc range")
		local s = ""
		for i = n - 1, 0, -1 do
			local d = math.floor(v / 64 ^ i) % 64
			s ..= string.sub(B64, d + 1, d + 1)
		end
		return s
	end
	local PIDS = { ot1 = 0, op1 = 1, op2 = 2 }
	local tiles = {}
	local farT = nil
	for _, d in workspace.Yangon1to1.Green.Far:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == "OKF_ot1far" then farT = d break end
	end
	local farM = Instance.new("Model")
	farM.Name = "Cell_PP"
	local nFar = 0
	for _, t in placed do
		local pid, s, sy
		if t.palm then
			local hm = R:NextNumber(10, 15)
			if R:NextNumber() < 0.55 then pid, s = "op1", hm / 12.2 else pid, s = "op2", hm / 16.3 end
			sy = s
		else
			pid, s = "ot1", t.Dm / 18.3
			sy = s * R:NextNumber(0.92, 1.12)
		end
		local i, j = math.floor(t.x / 256), math.floor(t.z / 256)
		local key = i .. "_" .. j
		local y = t.g - 0.4
		local rec = "Q" .. enc(PIDS[pid], 2) .. enc((t.x - i * 256 + 16384) * 500, 4) .. enc((y + 200) * 200, 3)
			.. enc((t.z - j * 256 + 16384) * 500, 4) .. enc(math.round((t.yaw % (2 * math.pi)) / (2 * math.pi) * 262144) % 262144, 3)
			.. enc((s - 0.1) * 50000, 3) .. "0" .. enc((sy - 0.05) * 5000, 3) .. enc((s - 0.05) * 5000, 3)
		tiles[key] = (tiles[key] or "") .. rec
		if farT and not t.palm and t.Dm >= 14 then
			local f = farT:Clone()
			f.Size = Vector3.new(t.Dm * 3 * 0.92, t.Dm * 3 * 0.62 * sy / s, t.Dm * 3 * 0.85)
			f.CFrame = CFrame.new(t.x, t.g + f.Size.Y * 0.49, t.z) * CFrame.Angles(0, t.yaw, 0)
			f:SetAttribute("T", key)
			f.Parent = farM
			nFar += 1
		end
	end
	local K = RS.YgnKit
	local old = K:FindFirstChild("Data_PPG")
	if old then old:Destroy() end
	local dataF = Instance.new("Folder")
	dataF.Name = "Data_PPG"
	local meta = Instance.new("StringValue")
	meta.Name, meta.Value = "Meta", "TILE=256\nPIDS=ot1 op1 op2\nCODES=TRE\n"
	meta.Parent = dataF
	local nT = 0
	for key, str in tiles do
		local v = Instance.new("StringValue")
		v.Name, v.Value = key, str
		v.Parent = dataF
		nT += 1
	end
	dataF.Parent = K
	local oldFar = workspace.Yangon1to1.Green.Far:FindFirstChild("Cell_PP")
	if oldFar then oldFar:Destroy() end
	farM.Parent = workspace.Yangon1to1.Green.Far
	stats.treeTiles, stats.far = nT, nFar
	for _, t in placed do
		table.insert(trunks, { Vector2.new(t.x, t.z), if t.palm then 4 else 7 })
	end
	task.wait()

	-- 6. lamps and benches beside the footways; gate pillars
	local lamps = {}
	local function freeSpot(x, z, r)
		local q = Vector2.new(x, z)
		for _, t in trunks do
			if (t[1] - q).Magnitude < t[2] + r then return nil end
		end
		local g, wet = wy(x, z)
		if not g or wet or onBuilt(x, z, 2) or not inPark(x, z) then return nil end
		if #workspace:GetPartBoundsInRadius(Vector3.new(x, g + 2.5, z), r, bp) > 0 then return nil end
		return g
	end
	local nLamp, nBench = 0, 0
	for _, w in ways do
		if w.kind == "service" then continue end
		local acc, side = 30, 1
		for i = 1, #w.p - 1 do
			local a, b = w.p[i], w.p[i + 1]
			local d = (b - a) * Vector3.new(1, 0, 1)
			local L = d.Magnitude
			if L < 0.5 then continue end
			local u = d.Unit
			local n = Vector3.new(-u.Z, 0, u.X)
			local s = 0
			while acc + (L - s) >= 75 do
				s += 75 - acc
				acc = 0
				local p = a:Lerp(b, s / L)
				local lp = p + n * side * (w.w / 2 + 2.5)
				local farOk = true
				for _, q in lamps do
					if (q - lp).Magnitude < 45 then farOk = false break end
				end
				local g = farOk and freeSpot(lp.X, lp.Z, 2)
				if g then
					local lm = Instance.new("Model")
					lm.Name = "ParkLamp"
					lamp(lm, CFrame.new(lp.X, g, lp.Z), true)
					for _, l in lm:GetDescendants() do
						if l:IsA("PointLight") then
							l.Range, l.Brightness = 30, 1.2
							CS:AddTag(l, "LODLight")
							CS:AddTag(l, "DayOff")
						end
					end
					lm.Parent = m
					table.insert(lamps, lp)
					table.insert(trunks, { Vector2.new(lp.X, lp.Z), 2 })
					nLamp += 1
				end
				local bq = a:Lerp(b, math.min(1, (s + 6) / L)) - n * side * (w.w / 2 + 2.2)
				local gb = (nLamp + nBench) % 2 == 0 and freeSpot(bq.X, bq.Z, 1.8) -- (a radius of 4 touched the path itself)
				if gb then
					local pos = Vector3.new(bq.X, gb, bq.Z)
					-- the bench's back (+Z) away from the path
					bench(m, CFrame.lookAt(pos, pos + n * side))
					table.insert(trunks, { Vector2.new(bq.X, bq.Z), 4 })
					nBench += 1
				end
				side = -side
			end
			acc += L - s
		end
		task.wait()
	end
	local nGate = 0
	for i = 1, #D.gates, 2 do
		local x, z = D.gates[i], D.gates[i + 1]
		local best, dir = math.huge, Vector3.xAxis
		local pk = D.park
		for k = 1, #pk - 3, 2 do
			local a, b = Vector2.new(pk[k], pk[k + 1]), Vector2.new(pk[k + 2], pk[k + 3])
			local ab = b - a
			if ab.Magnitude > 1 then
				local t = math.clamp((Vector2.new(x, z) - a):Dot(ab) / ab:Dot(ab), 0, 1)
				local dd = (a + ab * t - Vector2.new(x, z)).Magnitude
				if dd < best then best, dir = dd, Vector3.new(ab.Unit.X, 0, ab.Unit.Y) end
			end
		end
		for _, sx in { -1, 1 } do
			local p = Vector3.new(x, 0, z) + dir * sx * 9
			local g = gy(p.X, p.Z)
			if g and #workspace:GetPartBoundsInRadius(Vector3.new(p.X, g + 3, p.Z), 1.6, bp) == 0 then
				local c = Vector3.new(p.X, g, p.Z)
				part(m, "GatePillar", Vector3.new(2.6, 9, 2.6), CFrame.lookAt(c, c + dir) * CFrame.new(0, 4.5, 0), Color3.fromRGB(232, 220, 192), Enum.Material.Concrete)
				part(m, "GateCap", Vector3.new(3.4, 0.8, 3.4), CFrame.lookAt(c, c + dir) * CFrame.new(0, 9.4, 0), Color3.fromRGB(176, 140, 64), Enum.Material.Concrete)
				nGate += 1
			end
		end
	end
	stats.lamps, stats.benches, stats.gatePillars = nLamp, nBench, nGate
	local out = {}
	for k, v in stats do table.insert(out, k .. "=" .. v) end
	table.sort(out)
	return table.concat(out, " ") .. " parts=" .. #m:GetDescendants()
end

function P.all()
	local out = {}
	table.insert(out, "garden " .. P.garden())
	task.wait()
	table.insert(out, "viewpoint " .. P.viewpoint())
	task.wait()
	table.insert(out, "square " .. P.square())
	task.wait()
	table.insert(out, "parkPP " .. P.carpark("parkPP", "ShwedagonCarPark", "Shwedagon West Gate"))
	task.wait()
	table.insert(out, "parkSW " .. P.carpark("parkSW", "SquareCarPark", "People's Square"))
	return table.concat(out, ", ")
end
function P.undo()
	local f = workspace.Yangon1to1:FindFirstChild("Parks")
	if f then f:Destroy() end
end
return P
