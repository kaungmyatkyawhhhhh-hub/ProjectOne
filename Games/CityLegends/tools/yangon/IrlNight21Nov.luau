--[[
	IrlNight21Nov (Studio, Edit mode; owner's real night footage of 21 Nov 2026, vault note
	"City Legends/2026-11-21 Real Yangon references - what the game must match.md").

	Builds Workspace.Yangon1to1.Landmarks.IrlNight21Nov (delete that one folder to undo):
	  CityHall    warm-white light lines on the floor bands, parapet and every tower eave + facade wash (0806_19s)
	              + M.cityHallModel(): the model fix inside Landmarks.city_hall (Rebuild21Nov; M.undoCityHall())
	  Roundabout  the gold monument and its lit base ring on the bare Hanthawaddy island (0803_2s)
	  ParkFence   red / green neon meander and gold-wrapped poles round Maha Bandula Park (0801_5s)
	  SuleShops   gold crest on the shop ring, crest floodlights, yellow sign boards (0806_1s)
	  SuleRoundabout  floods on the stupa (IMG_0806, IMG_0804 80 s)

	Night switching is WorldFx's own (no new code): Neon lines carry tag FacadeNight (hidden by day), gold
	carries LandmarkGlow (DayColor / DayMaterial / NightColor), pole wraps LampGlow, lights LODLight + DayOff
	(built Enabled = false). M.preview(true / false) shows the night state in Edit on this folder only.

	Run: paste into the command bar / execute_luau with the last line changed to `return M.build()`.
	shortcut: outlines are OSM polygons pasted below (geo.py, YANGON_SCALE=1to1), re-paste if the map moves.
]]
local CollectionService = game:GetService("CollectionService")

local M = {}
local FROM = "IrlRefs 21Nov"
local rgb = Color3.fromRGB

local function landmarks(): Instance
	return workspace.Yangon1to1.Landmarks
end

local function item(name: string): Folder
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if not root then
		root = Instance.new("Folder")
		root.Name = "IrlNight21Nov"
		root:SetAttribute("From", FROM)
		root.Parent = landmarks()
	end
	local old = root:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f:SetAttribute("From", FROM)
	return f -- parented by the caller once it is full (one insert)
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p:SetAttribute("From", FROM)
	p.Parent = parent
	return p
end

-- a light line: Neon, hidden by day (WorldFx.setFacadeNight)
local function neon(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = part(parent, name, size, cf, color, Enum.Material.Neon, shape)
	p.Transparency = 1
	p:AddTag("FacadeNight")
	return p
end

-- gold that glows at night (WorldFx.setLandmarkGlow)
local function glow(p: Part, night: Color3): Part
	p:SetAttribute("DayColor", p.Color)
	p:SetAttribute("DayMaterial", p.Material.Name)
	p:SetAttribute("NightColor", night)
	p:AddTag("LandmarkGlow")
	return p
end

local function light(l: Light, parent: Instance, color: Color3, brightness: number, range: number): Light
	l.Color = color
	l.Brightness = brightness;
	(l :: any).Range = range
	l.Shadows = false
	l.Enabled = false
	l:SetAttribute("From", FROM)
	l:AddTag("LODLight")
	l:AddTag("DayOff")
	l.Parent = parent
	return l
end

-- upright cylinder (Roblox cylinders lie along X)
local function cyl(parent: Instance, name: string, r: number, h: number, pos: Vector3, color: Color3, material: Enum.Material?): Part
	return part(parent, name, Vector3.new(h, 2 * r, 2 * r), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
end

-- a bar from a to b (world), square section t
local function bar(a: Vector3, b: Vector3, t: number, extra: number?): (Vector3, CFrame)
	local L = (b - a).Magnitude
	return Vector3.new(t, t, L + (extra or 0)), CFrame.lookAt((a + b) / 2, b)
end

-- outward unit normal of edge a -> b of a polygon round centre c (x, z pairs)
local function outward(a, b, c): (number, number, number)
	local dx, dz = b[1] - a[1], b[2] - a[2]
	local L = math.sqrt(dx * dx + dz * dz)
	local nx, nz = dz / L, -dx / L
	if nx * ((a[1] + b[1]) / 2 - c[1]) + nz * ((a[2] + b[2]) / 2 - c[2]) < 0 then
		nx, nz = -nx, -nz
	end
	return nx, nz, L
end

local function centroid(poly): { number }
	local x, z = 0, 0
	for _, p in poly do
		x += p[1]
		z += p[2]
	end
	return { x / #poly, z / #poly }
end

------------------------------------------------------------------------------------------------ A. City Hall
-- outline = OSM o5677100 (the polygon dt_landmarks.city_hall uses; S = 3 studs a metre)
local CH_POLY = { { 36109.3, 44964.3 }, { 36162.8, 45014.5 }, { 36256.7, 45017.2 }, { 36256.5, 45023.9 }, { 36262.3, 45024.1 }, { 36261.9, 45036.5 }, { 36350.3, 45039.1 }, { 36350.7, 45025.7 }, { 36355.9, 45025.9 }, { 36356.0, 45021.2 }, { 36444.2, 45023.7 }, { 36465.9, 45003.8 }, { 36471.3, 44787.5 }, { 36115.1, 44777.2 } }
local CH_RECT = { { 36472.2, 44787.5 }, { 36114.8, 44777.1 }, { 36107.4, 45032.1 }, { 36464.8, 45042.4 } } -- its minimum rotated rectangle
local CH_C = { 36289.77, 44909.79 }
local CH_BASE = 13.9 -- the trim mesh foot (Visual.TRM)
local CH_YH = CH_BASE + 15.6 * 3 -- the roof
local CH_FRONT = 6 -- CH_POLY edge 6 -> 7 is the entrance bay front (south, facing the park)
local WARM = rgb(238, 230, 213) -- photo; the lights use it
local WARM_NEON = rgb(196, 182, 156) -- the Neon that reads as it (full white blooms)
local CH_WALL = rgb(238, 230, 212) -- cream stone
local CH_TRIM = rgb(218, 206, 182)
local CH_ROOF = rgb(132, 104, 156) -- lilac tier roofs
local CH_EAVE = rgb(70, 120, 84) -- green eave boards
local CH_GOLD = rgb(232, 180, 70)
local CH_HIP = math.pi -- the CornerWedgePart turn that puts its peak on the tier (checked by eye in Studio)

local function inPoly(x: number, z: number, poly): boolean
	local inside = false
	local j = #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if (a[2] > z) ~= (b[2] > z) and x < (b[1] - a[1]) * (z - a[2]) / (b[2] - a[2]) + a[1] then
			inside = not inside
		end
		j = i
	end
	return inside
end

-- the towers, each ON the roof: a corner pavilion slides in from its corner of the rectangle until its whole
-- block stands inside the outline (the old mesh put the south-west one 27 studs in from the rectangle corner,
-- which is outside the cut corner by Sule: it hung in the air); the tall one stands on the entrance bay
type Tower = { cx: number, cz: number, hu: number, hv: number, blockH: number, hb: number, tiers: number }
local function chFrame(): Vector3
	return Vector3.new(CH_RECT[2][1] - CH_RECT[1][1], 0, CH_RECT[2][2] - CH_RECT[1][2]).Unit
end
local function chTowers(): { Tower }
	local e = chFrame()
	local v = Vector3.new(-e.Z, 0, e.X)
	local out = {}
	for _, c in CH_RECT do
		local d = Vector3.new(CH_C[1] - c[1], 0, CH_C[2] - c[2]).Unit
		local half = 13.5
		for step = 27, 140 do
			local p = Vector3.new(c[1], 0, c[2]) + d * step
			local ok = true
			for _, s in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
				local q = p + e * (s[1] * (half + 3)) + v * (s[2] * (half + 3))
				ok = ok and inPoly(q.X, q.Z, CH_POLY)
			end
			if ok then
				table.insert(out, { cx = p.X, cz = p.Z, hu = half, hv = half, blockH = 16, hb = 16, tiers = 3 })
				break
			end
		end
	end
	local a, b = CH_POLY[CH_FRONT], CH_POLY[CH_FRONT + 1]
	local nx, nz = outward(a, b, CH_C)
	table.insert(out, { cx = (a[1] + b[1]) / 2 - nx * 25, cz = (a[2] + b[2]) / 2 - nz * 25, hu = 24, hv = 21, blockH = 25, hb = 25.5, tiers = 5 })
	return out
end
-- the tiers of a tower: { y of the eave over the roof, eave half, top half, rise }, then the spire foot
local function chTiers(t: Tower): ({ { number } }, number)
	local list = {}
	local y, hb = t.blockH, t.hb
	for k = 1, t.tiers do
		table.insert(list, { y, hb, hb * 0.5, hb * 0.42 })
		y += 0.5 + hb * 0.42
		if k < t.tiers then
			y += hb * 0.24
			hb *= 0.72
		end
	end
	return list, y
end

-- the model fix (owner, 21 Nov: "the city hall needs fix too"). The wall, tier-roof, eave and spire meshes
-- (WAL / ROW / WTR / GLD) hold the hanging tower and the flat slab tiers and cannot be cut in Studio (CSG: not
-- manifold), so they are hidden and built again here from Parts in city_hall.Rebuild21Nov: walls on the same
-- plane with the window openings read from the glass mesh, towers at chTowers(), sloped tiers, spires.
-- Undo: M.undoCityHall() (or the whole original: ServerStorage.CityHall_before_21Nov).
local CH_HIDE = { "WAL", "ROW", "WTR", "GLD", "TRM" } -- (TRM: its teal is baked into the mesh, Color cannot change it)
local function merge(iv: { { number } }): { { number } }
	table.sort(iv, function(p, q)
		return p[1] < q[1]
	end)
	local out = {}
	for _, r in iv do
		local last = out[#out]
		if last and r[1] <= last[2] + 0.05 then
			last[2] = math.max(last[2], r[2])
		else
			table.insert(out, { r[1], r[2] })
		end
	end
	return out
end

function M.cityHallModel(): string
	local model = landmarks().city_hall
	local V = model.Visual
	local SS = game:GetService("ServerStorage")
	if not SS:FindFirstChild("CityHall_before_21Nov") then
		local b = model:Clone()
		b.Name = "CityHall_before_21Nov"
		b.Parent = SS
	end
	local old = model:FindFirstChild("Rebuild21Nov")
	if old then
		old:Destroy()
	end
	local R = Instance.new("Model")
	R.Name = "Rebuild21Nov"
	R:SetAttribute("From", FROM)
	local nWall, nTower = 0, 0

	-- window openings: the glass panes stand 1 stud behind the wall plane
	local glass = V.GLW
	local em = game:GetService("AssetService"):CreateEditableMeshAsync(Content.fromUri(glass.MeshId), { FixedSize = true })
	local sc = glass.Size / glass.MeshSize
	local pos = {}
	for _, vid in em:GetVertices() do
		pos[vid] = glass.CFrame:PointToWorldSpace(em:GetPosition(vid) * sc)
	end
	local faces = {}
	for _, fid in em:GetFaces() do
		local f = em:GetFaceVertices(fid)
		table.insert(faces, { pos[f[1]], pos[f[2]], pos[f[3]] })
	end
	em:Destroy()

	local TOP = CH_YH + 1.6
	local FOOT = CH_BASE - 0.5
	for i, a in CH_POLY do
		local b = CH_POLY[i % #CH_POLY + 1]
		local nx, nz, L = outward(a, b, CH_C)
		local A = Vector3.new(a[1], 0, a[2])
		local e = Vector3.new(b[1] - a[1], 0, b[2] - a[2]).Unit
		local n = Vector3.new(nx, 0, nz)
		local cf = CFrame.fromMatrix(A, e, Vector3.yAxis) -- local x along the wall
		local zOut = cf:VectorToObjectSpace(n).Z -- +1 or -1: which local z is outside
		local function wall(s0: number, s1: number, y0: number, y1: number, d0: number, d1: number)
			if s1 - s0 < 0.05 or y1 - y0 < 0.05 then
				return
			end
			part(R, "Wall", Vector3.new(s1 - s0, y1 - y0, d0 - d1), cf * CFrame.new((s0 + s1) / 2, (y0 + y1) / 2, zOut * (d0 + d1) / 2), CH_WALL)
			nWall += 1
		end
		-- the panes of this wall as (s, y) boxes
		local boxes = {}
		for _, f in faces do
			local on = true
			local s0, s1, y0, y1 = math.huge, -math.huge, math.huge, -math.huge
			for _, p in f do
				local rel = p - A
				local s, d = rel:Dot(e), rel:Dot(n)
				on = on and math.abs(d + 1) < 0.25 and s > -0.1 and s < L + 0.1
				s0, s1, y0, y1 = math.min(s0, s), math.max(s1, s), math.min(y0, p.Y), math.max(y1, p.Y)
			end
			if on then
				table.insert(boxes, { s0, s1, y0, y1 })
			end
		end
		local rowIv = {}
		for _, bx in boxes do
			table.insert(rowIv, { bx[3], bx[4] })
		end
		local rows = merge(rowIv)
		wall(0, L, FOOT, TOP, -1.06, -1.7) -- the back of every opening
		local y = FOOT
		for _, row in rows do
			wall(0, L, y, row[1], -0.06, -0.98) -- the band under this row
			local paneIv = {}
			for _, bx in boxes do
				if bx[3] >= row[1] - 0.1 and bx[4] <= row[2] + 0.1 then
					table.insert(paneIv, { bx[1], bx[2] })
				end
			end
			local s = 0
			for _, pane in merge(paneIv) do
				wall(s, pane[1], row[1], row[2], -0.06, -0.98) -- a pier
				s = pane[2]
			end
			wall(s, L, row[1], row[2], -0.06, -0.98)
			y = row[2]
		end
		wall(0, L, y, TOP, -0.06, -0.98)
		-- the trim, in stone instead of teal: three bands and a pilaster between bays
		local function trim(s0: number, s1: number, y0: number, y1: number, depth: number)
			part(R, "Trim", Vector3.new(s1 - s0, y1 - y0, depth), cf * CFrame.new((s0 + s1) / 2, (y0 + y1) / 2, zOut * (depth / 2 - 0.06)), CH_TRIM)
			nWall += 1
		end
		local bands = { { CH_BASE + 14.1, CH_BASE + 15, 0.96 }, { CH_BASE + 35.1, CH_BASE + 36, 1.1 }, { CH_YH - 1.35, CH_YH + 0.2, 1.5 } }
		local foot = FOOT
		for _, bd in bands do
			trim(0, L, bd[1], bd[2], bd[3])
			if rows[1] then
				local paneIv = {}
				for _, bx in boxes do
					if bx[4] <= rows[1][2] + 0.1 then
						table.insert(paneIv, { bx[1], bx[2] })
					end
				end
				local panes = merge(paneIv)
				for j = 1, #panes - 1 do
					local mid = (panes[j][2] + panes[j + 1][1]) / 2
					trim(mid - 0.6, mid + 0.6, foot, bd[1], 0.6)
				end
			end
			foot = bd[2]
		end
	end

	-- towers
	local e = chFrame()
	for _, t in chTowers() do
		local cf = CFrame.fromMatrix(Vector3.new(t.cx, CH_YH, t.cz), e, Vector3.yAxis)
		local function P(name: string, size: Vector3, at: CFrame, color: Color3, class: string?): BasePart
			nTower += 1
			if class then
				local p = Instance.new(class) :: BasePart
				p.Name, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = name, true, false, false, false, false
				p.Size, p.CFrame, p.Color, p.Material = size, cf * at, color, Enum.Material.SmoothPlastic
				p:SetAttribute("From", FROM)
				p.Parent = R
				return p
			end
			return part(R, name, size, cf * at, color)
		end
		P("Block", Vector3.new(2 * t.hu, t.blockH + 1, 2 * t.hv), CFrame.new(0, (t.blockH - 1) / 2, 0), CH_WALL)
		P("BlockBand", Vector3.new(2 * t.hu + 1.2, 0.9, 2 * t.hv + 1.2), CFrame.new(0, t.blockH - 2.2, 0), CH_TRIM)
		local tiers, top = chTiers(t)
		for k, tr in tiers do
			local y, hb, ht, rise = tr[1], tr[2], tr[3], tr[4]
			local d = hb - ht
			P("Eave", Vector3.new(2 * hb + 0.7, 0.5, 2 * hb + 0.7), CFrame.new(0, y + 0.25, 0), CH_EAVE)
			P("RoofCore", Vector3.new(2 * ht, rise, 2 * ht), CFrame.new(0, y + 0.5 + rise / 2, 0), CH_ROOF)
			for q = 0, 3 do
				local rot = CFrame.Angles(0, q * math.pi / 2, 0)
				P("Roof", Vector3.new(2 * ht, rise, d), rot * CFrame.new(0, y + 0.5 + rise / 2, -(ht + d / 2)), CH_ROOF, "WedgePart")
				P("RoofHip", Vector3.new(d, rise, d), rot * CFrame.new(ht + d / 2, y + 0.5 + rise / 2, -(ht + d / 2)) * CFrame.Angles(0, CH_HIP, 0), CH_ROOF, "CornerWedgePart")
				-- the upturned corner
				local s = hb * 0.16
				P("Horn", Vector3.new(0.5, 0.5, s * 2), rot * CFrame.new(hb + 0.1, y + 0.5, -(hb + 0.1)) * CFrame.Angles(0, -math.pi / 4, 0) * CFrame.Angles(math.rad(38), 0, 0) * CFrame.new(0, 0, -s * 0.8), CH_GOLD)
			end
			if k < #tiers then
				local nh = tiers[k + 1][2] * 0.55
				local dh = tiers[k + 1][1] - (y + 0.5 + rise)
				P("Drum", Vector3.new(2 * nh, dh, 2 * nh), CFrame.new(0, y + 0.5 + rise + dh / 2, 0), CH_WALL)
			end
		end
		-- spire: shrinking gold drums, a rod, a bud
		local r = tiers[#tiers][3] * 0.8
		local y = top
		for _ = 1, 5 do
			local h = r * 1.5
			nTower += 1
			local c = cyl(R, "Spire", r, h, (cf * CFrame.new(0, y + h / 2, 0)).Position, CH_GOLD)
			c.Reflectance = 0.12
			y += h
			r *= 0.66
		end
		nTower += 2
		cyl(R, "SpireRod", 0.3, t.hb * 0.35, (cf * CFrame.new(0, y + t.hb * 0.175, 0)).Position, CH_GOLD)
		part(R, "SpireBud", Vector3.one * 1.4, cf * CFrame.new(0, y + t.hb * 0.35, 0), CH_GOLD, nil, Enum.PartType.Ball)
	end

	-- real colours on the meshes that stay; the old ones kept as attributes
	for name, look in { SLB = { rgb(168, 164, 156), Enum.Material.SmoothPlastic } } do
		local p = V[name]
		if p:GetAttribute("Old21Color") == nil then
			p:SetAttribute("Old21Color", p.Color)
			p:SetAttribute("Old21Material", p.Material.Name)
		end
		p.Color, p.Material = look[1], look[2]
	end
	for _, name in CH_HIDE do
		local p = V[name]
		if p:GetAttribute("Old21Transparency") == nil then
			p:SetAttribute("Old21Transparency", p.Transparency)
		end
		p.Transparency = 1
	end
	R.ModelStreamingMode = model.ModelStreamingMode
	R.Parent = model
	return string.format("CityHall model: %d wall and trim parts, %d tower parts; hidden %s", nWall, nTower, table.concat(CH_HIDE, " "))
end

function M.undoCityHall()
	local model = landmarks().city_hall
	local r = model:FindFirstChild("Rebuild21Nov")
	if r then
		r:Destroy()
	end
	for _, p in model.Visual:GetChildren() do
		if p:GetAttribute("Old21Transparency") ~= nil then
			p.Transparency = p:GetAttribute("Old21Transparency")
		end
		if p:GetAttribute("Old21Color") ~= nil then
			p.Color = p:GetAttribute("Old21Color")
			p.Material = (Enum.Material :: any)[p:GetAttribute("Old21Material")]
		end
	end
end

-- the night lights: lines on the floor bands and parapet, on every tier eave, and the facade wash
function M.cityHall(): string
	local f = item("CityHall")
	local nLine, nLight = 0, 0
	for i, a in CH_POLY do
		local b = CH_POLY[i % #CH_POLY + 1]
		local nx, nz, L = outward(a, b, CH_C)
		for _, y in { CH_BASE + 14.6, CH_BASE + 35.6, CH_YH + 1.9 } do
			local o = Vector3.new(nx * 1.9, 0, nz * 1.9)
			local size, cf = bar(Vector3.new(a[1], y, a[2]) + o, Vector3.new(b[1], y, b[2]) + o, 0.55, 2)
			neon(f, "Line", size, cf, WARM_NEON)
			nLine += 1
		end
		-- the wash: one SurfaceLight strip per long wall, on the ground, tilted up at the wall
		if L > 60 then
			local mid = Vector3.new((a[1] + b[1]) / 2 + nx * 16, CH_BASE + 1, (a[2] + b[2]) / 2 + nz * 16)
			local aim = Vector3.new((a[1] + b[1]) / 2, CH_BASE + 30, (a[2] + b[2]) / 2)
			local strip = part(f, "Wash", Vector3.new(L - 8, 0.4, 0.4), CFrame.lookAt(mid, aim), WARM)
			strip.Transparency = 1
			local sl = Instance.new("SurfaceLight")
			sl.Face = Enum.NormalId.Front
			sl.Angle = 110
			light(sl, strip, WARM, 2.2, 60)
			nLight += 1
		end
	end
	local e = chFrame()
	for _, t in chTowers() do
		local function square(y: number, hu: number, hv: number)
			local cf = CFrame.fromMatrix(Vector3.new(t.cx, CH_YH + y, t.cz), e, Vector3.yAxis)
			for _, s in { -1, 1 } do
				neon(f, "Eave", Vector3.new(2 * hu + 0.5, 0.5, 0.5), cf * CFrame.new(0, 0, s * hv), WARM_NEON)
				neon(f, "Eave", Vector3.new(0.5, 0.5, 2 * hv + 0.5), cf * CFrame.new(s * hu, 0, 0), WARM_NEON)
				nLine += 2
			end
		end
		square(t.blockH - 2.2, t.hu + 0.95, t.hv + 0.95)
		for _, tr in (chTiers(t)) do
			square(tr[1] + 0.25, tr[2] + 0.7, tr[2] + 0.7)
		end
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("CityHall: %d neon lines, %d lights", nLine, nLight)
end

------------------------------------------------------------------------------------------------ B. Roundabout monument
-- the bare island of the Hanthawaddy roundabout (measured in Studio: x 28195..28306, z 32138..32249, top 75.63)
local RB = Vector3.new(28250.5, 75.63, 32193.5)
local GOLD = rgb(232, 227, 96)
local GOLD_DAY = rgb(246, 196, 62)
local RING_GREEN = rgb(78, 100, 58) -- photo (156, 201, 116) halved for Neon

function M.roundabout(): string
	local f = item("Roundabout")
	local n = 0
	local K = 1.25 -- the drawing below is in units of 0.8 m; the real one stands about 12 m
	local NIGHT = rgb(116, 113, 48) -- photo (232, 227, 96) halved: Neon renders about twice its colour
	local LINE = rgb(196, 186, 150)
	local function at(y: number): Vector3
		return RB + Vector3.new(0, y * K, 0)
	end
	local function gold(name: string, r: number, h: number, y: number): Part
		n += 1
		return glow(cyl(f, name, r * K, h * K, at(y + h / 2), GOLD_DAY, Enum.Material.Metal), NIGHT)
	end
	local function rim(name: string, r: number, y: number, color: Color3, t: number?)
		n += 1
		neon(f, name, Vector3.new(t or 0.45, 2 * r * K, 2 * r * K), CFrame.new(at(y)) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.PartType.Cylinder)
	end
	-- the planted base ring (the only solid piece)
	local bed = cyl(f, "BaseRing", 28 * K, 1.6 * K, at(0.8), rgb(74, 122, 60), Enum.Material.Grass)
	bed.CanCollide = true
	bed.CanQuery = true
	n += 1
	rim("RingGreen", 28.5, 0.5, RING_GREEN, 0.8)
	rim("RingWhite", 28.3, 1.45, LINE, 0.6)
	-- three gold steps, a light line on each
	local y = 1.6
	for i, r in { 9.5, 7.8, 6.2 } do
		gold("Step" .. i, r, 1.3, y)
		y += 1.3
		rim("StepLight", r + 0.15, y - 0.2, LINE)
	end
	-- the open-work stem: an hourglass of drums with light bands
	for i, r in { 4.4, 3.5, 2.7, 2.7, 3.5, 4.4 } do
		gold("Stem" .. i, r, 2.6, y)
		y += 2.6
		rim("StemLight", r + 0.15, y, LINE)
	end
	-- the bowl under the canopy, the wide scalloped canopy, two shrinking tiers, the dark crown
	gold("Bowl", 6.5, 1.6, y)
	y += 1.6
	gold("Canopy", 11.5, 1.5, y)
	for k = 1, 14 do
		local a = k / 14 * math.pi * 2
		n += 1
		glow(part(f, "Scallop", Vector3.one * 4.6 * K, CFrame.new(at(y - 0.4) + Vector3.new(math.cos(a), 0, math.sin(a)) * 10.4 * K), GOLD_DAY, Enum.Material.Metal, Enum.PartType.Ball), NIGHT)
	end
	y += 1.5
	rim("CanopyLight", 11.65, y, LINE)
	gold("Tier1", 8.4, 1.5, y)
	y += 1.5
	rim("TierLight", 8.55, y, LINE)
	gold("Tier2", 5.6, 1.4, y)
	y += 1.4
	cyl(f, "Crown", 3.6 * K, 2.2 * K, at(y + 1.1), rgb(120, 44, 40))
	n += 1
	y += 2.2
	rim("CrownLight", 3.8, y - 0.3, LINE)
	gold("Cap", 2.2, 0.8, y)
	-- two lights: the stem's glow and the canopy's underside
	for _, h in { 9, 20 } do
		local holder = part(f, "Glow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(at(h) + Vector3.new(0, 0, 12)), GOLD)
		holder.Transparency = 1
		n += 1
		light(Instance.new("PointLight"), holder, GOLD, 1.6, 40)
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("Roundabout: %d parts, 2 lights, top %.1f studs over the island", n, (y + 0.8) * K)
end

------------------------------------------------------------------------------------------------ C. Maha Bandula Park fence
local PARK = { { 36014.4, 45932.5 }, { 36409.9, 45944.4 }, { 36424.7, 45553.1 }, { 36431.7, 45297.7 }, { 36241.4, 45292.5 }, { 36125.9, 45290.8 }, { 36071.2, 45310.2 }, { 36025.2, 45350.8 }, { 36024.4, 45548.6 } } -- OSM way 129485365
local RED = rgb(108, 46, 24) -- photo (216, 93, 49): Neon renders about twice its colour, so parts carry half
local GREEN = rgb(64, 106, 50) -- photo (128, 211, 100)
local LED_GOLD = rgb(128, 106, 46)

function M.parkFence(): string
	local f = item("ParkFence")
	local c = centroid(PARK)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { landmarks() } -- the ground only (terrain, road and pavement boxes)
	local nNeon, nPole, k = 0, 0, 0
	local lastY = 18
	local INSET, PERIOD, LO, HI, T = 6, 16, 0.9, 6.4, 0.45
	for i, a in PARK do
		local b = PARK[i % #PARK + 1]
		local nx, nz, L = outward(a, b, c)
		local ex, ez = (b[1] - a[1]) / L, (b[2] - a[2]) / L
		local n = math.max(1, math.floor((L - 2 * INSET) / PERIOD))
		local p = (L - 2 * INSET) / n
		for j = 0, n - 1 do
			local function at(s: number): (number, number)
				return a[1] + ex * (INSET + j * p + s) - nx * INSET, a[2] + ez * (INSET + j * p + s) - nz * INSET
			end
			local mx, mz = at(p / 2)
			local hit = workspace:Raycast(Vector3.new(mx, 200, mz), Vector3.new(0, -400, 0), rp)
			local gy = if hit then hit.Position.Y else lastY
			lastY = gy
			local color = if (k // 6) % 2 == 0 then RED else GREEN
			local function P(s: number, h: number): Vector3
				local x, z = at(s)
				return Vector3.new(x, gy + h, z)
			end
			-- one turn of the meander: up, along the top, down, along the bottom
			for _, seg in { { P(0, LO), P(0, HI) }, { P(0, HI), P(p / 2, HI) }, { P(p / 2, HI), P(p / 2, LO) }, { P(p / 2, LO), P(p, LO) } } do
				local size, cf = bar(seg[1], seg[2], T, T)
				neon(f, "Neon", size, cf, color)
				nNeon += 1
			end
			-- a pole with a gold LED wrap where the colour changes
			if k % 6 == 0 then
				local x, z = at(0)
				cyl(f, "Pole", 0.45, 17, Vector3.new(x - nx * 1.2, gy + 8.5, z - nz * 1.2), rgb(150, 152, 154), Enum.Material.Metal)
				local wrap = cyl(f, "PoleWrap", 0.62, 10, Vector3.new(x - nx * 1.2, gy + 6.5, z - nz * 1.2), LED_GOLD)
				wrap:AddTag("LampGlow")
				nPole += 1
			end
			k += 1
		end
		task.wait()
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("ParkFence: %d neon bars, %d poles with gold wraps, 0 lights", nNeon, nPole)
end

------------------------------------------------------------------------------------------------ D. Sule shops
-- the shop ring's outer face = OSM way 131745510 simplified 0.4 m (sule3d.grounds); gates at N / E / S / W of the stupa
local SULE = { { 35858.0, 45143.0 }, { 35872.0, 45171.3 }, { 35908.2, 45209.0 }, { 35929.8, 45225.7 }, { 35952.7, 45239.4 }, { 35977.9, 45245.8 }, { 36015.2, 45246.9 }, { 36041.3, 45242.0 }, { 36068.0, 45230.7 }, { 36089.1, 45215.8 }, { 36107.5, 45198.2 }, { 36124.9, 45177.0 }, { 36139.4, 45147.3 }, { 36140.0, 45122.3 }, { 36136.3, 45103.0 }, { 36125.3, 45083.6 }, { 36097.5, 45049.1 }, { 36072.5, 45022.9 }, { 36046.0, 45001.8 }, { 36022.8, 44992.4 }, { 35985.5, 44991.4 }, { 35970.1, 44993.3 }, { 35957.0, 44997.9 }, { 35933.5, 45010.1 }, { 35912.5, 45027.2 }, { 35894.7, 45046.5 }, { 35878.0, 45068.5 }, { 35867.6, 45089.1 }, { 35858.5, 45115.1 } }
local SULE_C = { 35993.22, 45130.83 }
local SULE_Y0 = 18.47
local BOARD = rgb(236, 200, 44)
local CREST_DAY = rgb(255, 187, 84) -- Sule's own gold (Visual.GLD)
local CREST_NIGHT = rgb(104, 86, 28) -- renders about (208, 172, 56)

function M.suleShops(): string
	local f = item("SuleShops")
	local nBoard, nCrest, nLight = 0, 0, 0
	local function inGate(x: number, z: number, half: number): boolean
		return math.abs(x - SULE_C[1]) < half or math.abs(z - SULE_C[2]) < half
	end
	local yTop = SULE_Y0 + 5.8 * 3 -- the facade's top
	for i, a in SULE do
		local b = SULE[i % #SULE + 1]
		local nx, nz, L = outward(a, b, SULE_C)
		local ex, ez = (b[1] - a[1]) / L, (b[2] - a[2]) / L
		local function P(s: number, y: number, out: number): Vector3
			return Vector3.new(a[1] + ex * s + nx * out, y, a[2] + ez * s + nz * out)
		end
		-- yellow boards over the shop bays (about 4 m each, as sule3d cut them)
		local nb = math.max(1, math.round(L / 12))
		local w = L / nb
		for j = 0, nb - 1 do
			local m = P((j + 0.5) * w, SULE_Y0 + 9.45, 0.3)
			if w >= 7.2 and not inGate(m.X, m.Z, 16) then
				local size, cf = bar(P(j * w + 1.5, m.Y, 0.3), P((j + 1) * w - 1.5, m.Y, 0.3), 0.3)
				part(f, "Board", Vector3.new(0.3, 2.5, size.Z), cf, BOARD)
				nBoard += 1
			end
		end
		-- the gold crest on the wall's top: a band and its teeth
		local size, cf = bar(P(0, yTop + 1.1, 0.1), P(L, yTop + 1.1, 0.1), 0.6, 0.6)
		glow(part(f, "Crest", Vector3.new(0.6, 2.6, size.Z), cf, CREST_DAY, Enum.Material.Metal), CREST_NIGHT)
		nCrest += 1
		local nt = math.max(1, math.floor(L / 9))
		for j = 0, nt - 1 do
			local s = (j + 0.5) * L / nt
			local tall = if j % 2 == 0 then 3.4 else 2.2
			local _, tcf = bar(P(s - 2, yTop + 2.4 + tall / 2, 0.1), P(s + 2, yTop + 2.4 + tall / 2, 0.1), 0.6)
			glow(part(f, "CrestTooth", Vector3.new(0.6, tall, 4), tcf, CREST_DAY, Enum.Material.Metal), CREST_NIGHT)
			nCrest += 1
		end
		-- crest floodlights: one in five edges, on the pavement, aimed at the crest
		if i % 5 == 1 then
			local from = P(L / 2, SULE_Y0 + 1, 15)
			local lamp = part(f, "Flood", Vector3.new(1.2, 1.2, 1.2), CFrame.lookAt(from, P(L / 2, yTop + 2, 0)), rgb(40, 40, 42))
			local sl = Instance.new("SpotLight")
			sl.Face = Enum.NormalId.Front
			sl.Angle = 100
			light(sl, lamp, rgb(255, 242, 208), 4, 46)
			nLight += 1
		end
	end
	f.Parent = landmarks().IrlNight21Nov
	return string.format("SuleShops: %d yellow boards, %d crest parts, %d floodlights", nBoard, nCrest, nLight)
end

------------------------------------------------------------------------------------------------ E. Sule roundabout
-- (owner, 21 Nov: "there is sule roundabout too"; IMG_0806 0-30 s, IMG_0804 80 s) the stupa stands floodlit gold
-- over the ring: four floods on the platform aimed up the bell and one glow at the spire. The ring's crest, boards
-- and crest floods are item D.
function M.suleRoundabout(): string
	local f = item("SuleRoundabout")
	local c = Vector3.new(SULE_C[1], SULE_Y0 + 3.6 * 3 + 1, SULE_C[2])
	local gold = rgb(255, 206, 110)
	for k = 0, 3 do
		local a = math.rad(45 + 90 * k)
		local from = c + Vector3.new(math.cos(a) * 48, 0, math.sin(a) * 48)
		local lamp = part(f, "StupaFlood", Vector3.new(1.2, 1.2, 1.2), CFrame.lookAt(from, c + Vector3.new(0, 44, 0)), rgb(40, 40, 42))
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Front
		sl.Angle = 70
		light(sl, lamp, gold, 6, 60)
	end
	local top = part(f, "SpireGlow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(c + Vector3.new(9, 78, 9)), gold)
	top.Transparency = 1
	light(Instance.new("PointLight"), top, gold, 3, 60)
	f.Parent = landmarks().IrlNight21Nov
	return "SuleRoundabout: 5 parts, 5 lights (4 stupa floods, 1 spire glow)"
end

------------------------------------------------------------------------------------------------ all
-- the night state in Edit, on this folder only (in Play, WorldFx does the same by its tags)
function M.preview(night: boolean): string
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if not root then
		return "nothing built"
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			if d:HasTag("FacadeNight") then
				d.Transparency = if night then 0 else 1
			elseif d:HasTag("LandmarkGlow") then
				d.Material = if night then Enum.Material.Neon else (Enum.Material :: any)[d:GetAttribute("DayMaterial")]
				d.Color = if night then d:GetAttribute("NightColor") else d:GetAttribute("DayColor")
			elseif d:HasTag("LampGlow") then
				d.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
		elseif d:IsA("Light") then
			d.Enabled = night
		end
	end
	return "preview " .. (if night then "night" else "day")
end

-- self-check: everything anchored and marked, lights off, a handful of lights per item
function M.check(): string
	local root = landmarks().IrlNight21Nov
	local out = {}
	for _, f in root:GetChildren() do
		local parts, lights = 0, 0
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				assert(d.Anchored and d:GetAttribute("From") == FROM, "unanchored or unmarked: " .. d:GetFullName())
				assert(not d:HasTag("FacadeNight") or d.Transparency == 1, "a night line is showing by day")
			elseif d:IsA("Light") then
				lights += 1
				assert(not d.Enabled and d:HasTag("LODLight") and d:HasTag("DayOff"), "light not switched by WorldFx")
			end
		end
		assert(lights <= 8, f.Name .. ": too many lights")
		table.insert(out, string.format("%s %d parts %d lights", f.Name, parts, lights))
	end
	return table.concat(out, "; ")
end

function M.build(): string
	local out = { M.cityHallModel(), M.cityHall(), M.roundabout(), M.parkFence(), M.suleShops(), M.suleRoundabout() }
	table.insert(out, M.check())
	return table.concat(out, "\n")
end

function M.undo()
	M.undoCityHall()
	local root = landmarks():FindFirstChild("IrlNight21Nov")
	if root then
		root:Destroy()
	end
end

return M
