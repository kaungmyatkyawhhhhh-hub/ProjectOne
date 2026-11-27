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
local SOIL, WATER, TILE = Color3.fromRGB(52, 84, 40), Color3.fromRGB(64, 150, 176), Color3.fromRGB(120, 186, 204)
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
local function basin(parent, cf, wid, len, rimH, jets)
	part(parent, "BasinFloor", Vector3.new(wid, 0.4, len), cf * CFrame.new(0, 0.2, 0), TILE, Enum.Material.SmoothPlastic)
	for _, sx in { -1, 1 } do
		part(parent, "Rim", Vector3.new(1.6, rimH, len + 3.2), cf * CFrame.new(sx * (wid / 2 + 0.8), rimH / 2, 0), STONE, Enum.Material.Concrete)
		part(parent, "Rim", Vector3.new(wid, rimH, 1.6), cf * CFrame.new(0, rimH / 2, sx * (len / 2 + 0.8)), STONE, Enum.Material.Concrete)
	end
	local w = part(parent, "Water", Vector3.new(wid, 0.3, len), cf * CFrame.new(0, rimH - 0.45, 0), WATER, Enum.Material.SmoothPlastic, false)
	w.Transparency, w.Reflectance = 0.28, 0.25
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
