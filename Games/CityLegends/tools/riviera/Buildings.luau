--[[
	Riviera buildings (Studio, Edit mode), placed along the streets of build/riviera/roads.json.

	v2 (2026-11-02, owner: "all building quality looks off and make them better", the Step 1 list in
	City Legends/City Legends.md, fixed worst first):
	  * real window depth: every face is a skin of piers and floor bands 0.6 studs proud of a dark glass
	    core, so each window is a recessed opening (problem 2: flat painted windows)
	  * windows on all four faces and on the floors below the street on the downhill side (problems 6
	    and 7: blank side and back walls, buildings standing on blank plinths)
	  * one pane per window or per balcony bay, never one long band of glass, so at night single rooms
	    light up, not whole orange slabs (problem 2); only the panes that can ever be lit are parts
	    (the same position pick as WorldFx.setWindow, at most 45% lit), the rest show the dark core
	  * Monaco colours (cream, ochre, honey, peach, salmon, pink; tan and ochre concrete), a darker
	    band at the foot, stone trims, Plaster / Concrete / Limestone, terracotta or slate roofs, a
	    little colour jitter per building (problem 3: plastic look, snow-white walls)
	  * taller, wider, tighter rows: Belle Epoque 6-8 storeys, 1970s blocks 8-16, newer white blocks
	    7-12, a narrower building tried before a gap is left (problem 4: short buildings, sand gaps)
	  * shopfronts: a pane per bay, a door, awnings in mixed colours, a shop sign (problem 5)
	  * roofs: terracotta or mansard with chimneys and dormers; flat roofs with parapets, plant
	    rooms, AC units, water tanks, aerials, terraces with umbrellas (problem 8)
	  * four kinds and many switches (shutters or not, balcony rows, railings, roof, colours, heights)
	    so neighbours differ (problem 9)
	  * the 1970s blocks: thin balcony slabs in the wall colour, solid or glass parapets, bays of
	    windows behind (problem 10: thick white slabs over dark blue bands)
	Kinds: "BelleEpoque", "Apartment" (1970s-80s), "Modern" (white 2000s blocks with glass railings).

	Each building: a "Body" (the dark core: WorldFx's LOD looks for it), the skin and big parts in the
	model, small detail (sills, shutters, rails, awnings, signs, roof clutter) in "Detail" (tag LOD,
	hidden far away). Attributes for tools/riviera/FarCity.luau: Shell (CFrame), ShellSize, Wall
	(colour), Recess. Window panes: tag Window.

	Buildings.build(data, box, parent, rng, opts) -> count
	opts.style = function(position) -> chance of Belle Epoque (0..1)
	opts.skip = function(roadName) -> true to leave a road without buildings
]]

local CollectionService = game:GetService("CollectionService")

local Buildings = {}

local HALF, WALK = 32, 10
local FRONT = HALF + WALK + 0.5 -- road centre to building front
local R = 0.6 -- window recess: the skin stands this far proud of the glass core
local MAX_SHARE = 0.45 -- DayCycle's most windows lit (dusk)

local BELLE = {
	Color3.fromRGB(232, 212, 168), -- cream
	Color3.fromRGB(214, 164, 92), -- ochre
	Color3.fromRGB(226, 186, 112), -- honey
	Color3.fromRGB(230, 178, 140), -- peach
	Color3.fromRGB(216, 142, 112), -- salmon
	Color3.fromRGB(224, 168, 158), -- pink
	Color3.fromRGB(236, 214, 142), -- pale yellow
	Color3.fromRGB(198, 116, 86), -- terracotta red
}
local APART = {
	Color3.fromRGB(204, 176, 132), -- tan
	Color3.fromRGB(214, 190, 150),
	Color3.fromRGB(194, 160, 112), -- ochre concrete
	Color3.fromRGB(218, 204, 178), -- beige
	Color3.fromRGB(186, 168, 140), -- grey-tan
}
local MODERN = {
	Color3.fromRGB(226, 220, 204), -- warm white
	Color3.fromRGB(232, 222, 196), -- cream
	Color3.fromRGB(214, 206, 190), -- stone
}
local SHUTTER = { Color3.fromRGB(96, 116, 92), Color3.fromRGB(70, 92, 78), Color3.fromRGB(226, 222, 210), Color3.fromRGB(116, 88, 66), Color3.fromRGB(88, 104, 112) }
local AWNING = {
	Color3.fromRGB(150, 34, 38),
	Color3.fromRGB(36, 66, 50),
	Color3.fromRGB(30, 44, 74),
	Color3.fromRGB(190, 116, 44),
	Color3.fromRGB(226, 220, 204),
	Color3.fromRGB(110, 30, 44),
	Color3.fromRGB(64, 64, 66),
}
local SHOPS = {
	"Café Lumière", "Boulangerie Rivo", "Maison Azur", "Pharmacie du Port", "Glacier Ondine",
	"Bijouterie Solène", "Galerie Marine", "Le Petit Bistro", "Optique Belair", "Fleurs de Lune",
	"Boutique Céleste", "Banque Corniche", "Agence Riviera", "Pâtisserie Élise", "Tabac Presse",
	"Librairie Vauban", "Épicerie Fine", "Salon Mirabelle", "Trattoria Sole", "Caviste du Rocher",
}
local CORE = Color3.fromRGB(46, 42, 38) -- dark glass (= WorldFx's unlit window)
local IRON = Color3.fromRGB(28, 28, 30)
local SLATE = Color3.fromRGB(84, 90, 98)
local TILE = Color3.fromRGB(178, 96, 64) -- terracotta
local WOOD = Color3.fromRGB(92, 62, 44)

local function part(props, parent): BasePart
	local p = Instance.new(props.Class or "Part")
	props.Class = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function small(p: BasePart): BasePart
	p.CastShadow = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- the skin (bands, piers, foot, parapets): the core just behind it casts the building's shadow
local function quiet(p: BasePart): BasePart
	p.CastShadow = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

-- same as WorldFx.setWindow's pick
local function hash(pos: Vector3): number
	return math.abs(math.sin(pos.X * 12.9898 + pos.Y * 78.233 + pos.Z * 37.719) * 43758.5453) % 1
end

local function jitter(c: Color3, rng: Random): Color3
	local k = rng:NextNumber(-0.06, 0.06)
	return if k > 0 then c:Lerp(Color3.new(1, 1, 1), k) else c:Lerp(Color3.new(0, 0, 0), -k)
end

local function pane(cf: CFrame, w: number, h: number, parent: Instance, always: boolean?, share: number?): BasePart?
	if not always and hash(cf.Position) >= (share or MAX_SHARE) then
		return nil -- never lit: the dark core shows through the opening
	end
	local g = small(part({ Name = "Glass", Size = Vector3.new(w, h, 0.1), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = CORE, Reflectance = 0 }, parent))
	CollectionService:AddTag(g, "Window")
	return g
end

---------------------------------------------------------------------
-- one face: a skin of piers and floor bands with recessed openings
---------------------------------------------------------------------
-- fcf: bottom-centre of the face on its outer plane (floor level), LookVector = outward
-- rows: { { wb, wt } } window bottoms / tops (relative to the floor), sorted
-- cols: windows across; ww: window width; gfShop: the ground floor as shop bays (front)
type Face = {
	fcf: CFrame,
	width: number,
	bottom: number, -- the face's lowest point (relative to the floor; negative below the street)
	top: number,
	ground: number, -- ground along this face: no openings below it
	cols: number,
	ww: number,
	rows: { { number } },
	shop: { number }?, -- { top of the shop openings } when the ground floor is shops
	gf: number, -- ground floor height
	share: number?, -- most windows ever lit on this face (fewer at the backs and ends: parts)
}

local function face(f: Face, wall: Color3, mat: Enum.Material, model: Instance, det: Instance, windows: { CFrame }?)
	local W, cols = f.width, f.cols
	local step = W / cols
	local rows = {}
	for _, r in f.rows do
		if r[1] >= f.ground + 0.5 then
			table.insert(rows, r)
		end
	end
	-- floor bands: solid between the window rows
	local edges = { f.bottom }
	for _, r in rows do
		table.insert(edges, r[1])
		table.insert(edges, r[2])
	end
	table.insert(edges, f.top)
	if f.shop then
		-- the shop row (0.6 .. shop top) replaces the ground floor's window row
		local shopTop = f.shop[1]
		local merged = { f.bottom, 0.6, shopTop }
		for _, r in rows do
			if r[1] > shopTop then
				table.insert(merged, r[1])
				table.insert(merged, r[2])
			end
		end
		table.insert(merged, f.top)
		edges = merged
	end
	for k = 1, #edges - 1, 2 do
		local y0, y1 = edges[k], edges[k + 1]
		if y1 - y0 > 0.05 then
			quiet(part({ Name = "Band", Size = Vector3.new(W, y1 - y0, R), CFrame = f.fcf * CFrame.new(0, (y0 + y1) / 2, R / 2), Material = mat, Color = wall }, model))
		end
	end
	-- piers between the columns; in the shop row narrower
	local pier = step - f.ww
	local lo = if f.shop then f.shop[1] else f.bottom
	local function pierRun(y0: number, y1: number, pw: number)
		if y1 - y0 < 0.05 then
			return
		end
		for k = 0, cols do
			local x = -W / 2 + k * step
			local w = if k == 0 or k == cols then pw / 2 else pw
			local cx = if k == 0 then x + w / 2 elseif k == cols then x - w / 2 else x
			quiet(part({ Name = "Pier", Size = Vector3.new(w, y1 - y0, R), CFrame = f.fcf * CFrame.new(cx, (y0 + y1) / 2, R / 2), Material = mat, Color = wall }, model))
		end
	end
	pierRun(lo, f.top, pier)
	if f.shop then
		pierRun(0.6, f.shop[1], 1.4)
	end
	-- the panes
	for _, r in rows do
		if f.shop and r[1] <= f.shop[1] then
			continue
		end
		for c = 1, cols do
			local x = -W / 2 + (c - 0.5) * step
			local cf = f.fcf * CFrame.new(x, (r[1] + r[2]) / 2, R - 0.06)
			pane(cf, f.ww, r[2] - r[1], model, false, f.share)
			if windows and hash(cf.Position + Vector3.new(0, 7.7, 0)) < 0.3 then
				-- a blind or a curtain half down (front windows only)
				local h = (r[2] - r[1]) * (0.3 + 0.5 * hash(cf.Position + Vector3.new(3.1, 0, 0)))
				local tone = if hash(cf.Position + Vector3.new(0, 0, 5.3)) < 0.5 then Color3.fromRGB(214, 204, 184) else Color3.fromRGB(176, 160, 134)
				small(part({ Name = "Blind", Size = Vector3.new(f.ww, h, 0.08), CFrame = f.fcf * CFrame.new(x, r[2] - h / 2, R - 0.14), Material = Enum.Material.Fabric, Color = tone }, det))
			end
			if windows then
				table.insert(windows, f.fcf * CFrame.new(x, r[1], 0))
			end
		end
	end
	if f.shop then
		for c = 1, cols do
			local x = -W / 2 + (c - 0.5) * step
			pane(f.fcf * CFrame.new(x, (0.6 + f.shop[1]) / 2, R - 0.06), step - 1.4, f.shop[1] - 0.6, model, true)
		end
	end
end

-- faces of a W x D block whose front is on cf (cf faces the street: LookVector out of the front)
local function faces(cf: CFrame, W: number, D: number): { { cf: CFrame, width: number } }
	return {
		{ cf = cf, width = W }, -- front
		{ cf = cf * CFrame.new(0, 0, D) * CFrame.Angles(0, math.pi, 0), width = W }, -- back
		{ cf = cf * CFrame.new(-W / 2, 0, D / 2) * CFrame.Angles(0, math.pi / 2, 0), width = D }, -- left
		{ cf = cf * CFrame.new(W / 2, 0, D / 2) * CFrame.Angles(0, -math.pi / 2, 0), width = D }, -- right
	}
end

local function core(m: Model, cf: CFrame, W: number, D: number, bottom: number, top: number, wall: Color3)
	part({ Name = "Body", Size = Vector3.new(W - 2 * R, top - bottom, D - 2 * R), CFrame = cf * CFrame.new(0, (top + bottom) / 2, D / 2), Material = Enum.Material.SmoothPlastic, Color = CORE, Reflectance = 0 }, m)
	m:SetAttribute("Shell", cf * CFrame.new(0, (top + bottom) / 2, D / 2))
	m:SetAttribute("ShellSize", Vector3.new(W, top - bottom, D))
	m:SetAttribute("Wall", wall)
	m:SetAttribute("Recess", R)
end

local function shopSign(cf: CFrame, w: number, rng: Random, det: Instance)
	local board = small(part({ Name = "Sign", Size = Vector3.new(w, 1.8, 0.3), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = AWNING[rng:NextInteger(1, #AWNING)]:Lerp(Color3.new(0, 0, 0), 0.25) }, det))
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(math.floor(w * 40), 72)
	gui.LightInfluence = 0.4
	gui.MaxDistance = 220
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = SHOPS[rng:NextInteger(1, #SHOPS)]
	t.TextColor3 = Color3.fromRGB(250, 226, 160)
	t.Font = Enum.Font.Garamond
	t.TextScaled = true
	t.Parent = gui
	gui.Parent = board
end

-- the shop row along the front: a door, awnings, a sign
local function shops(cf: CFrame, W: number, cols: number, shopTop: number, rng: Random, det: Instance)
	local step = W / cols
	local doorCol = rng:NextInteger(1, cols)
	local x = -W / 2 + (doorCol - 0.5) * step
	small(part({ Name = "Door", Size = Vector3.new(math.min(step - 2, 4.4), 7.2, 0.2), CFrame = cf * CFrame.new(x, 0.6 + 3.6, R - 0.15), Material = Enum.Material.Wood, Color = WOOD }, det))
	-- awnings: one colour per run of bays (a shop), some bays without
	local col = AWNING[rng:NextInteger(1, #AWNING)]
	for c = 1, cols do
		if rng:NextNumber() < 0.35 then
			col = AWNING[rng:NextInteger(1, #AWNING)]
		end
		if rng:NextNumber() < 0.75 then
			local ax = -W / 2 + (c - 0.5) * step
			small(part({ Class = "WedgePart", Name = "Awning", Size = Vector3.new(step - 1.6, 1.6, 4.2), CFrame = cf * CFrame.new(ax, shopTop + 0.4, -2.1) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = col }, det))
		end
	end
	shopSign(cf * CFrame.new(rng:NextNumber(-W / 4, W / 4), shopTop + 2.6, -0.2), math.min(W * 0.4, 16), rng, det)
end

---------------------------------------------------------------------
-- Belle Epoque
---------------------------------------------------------------------
local function belle(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance, low: boolean): Model
	local m = Instance.new("Model")
	m.Name = "BelleEpoque"
	local floors = if low then rng:NextInteger(4, 5) else rng:NextInteger(6, 8)
	local GF, FH = 14, 11
	local H = GF + floors * FH
	local wall = jitter(BELLE[rng:NextInteger(1, #BELLE)], rng)
	local trim = wall:Lerp(Color3.fromRGB(238, 230, 212), 0.6)
	local foot = wall:Lerp(Color3.fromRGB(70, 60, 50), 0.35)
	local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, cf, W, D, bottom, H, wall)
	-- rows: the floors below the street (downhill), the ground floor, the upper floors
	local rows = {}
	local nb = math.floor(-bottom / FH)
	for i = nb, 1, -1 do
		local y0 = -i * FH
		table.insert(rows, { y0 + 2.4, y0 + 8.8 })
	end
	table.insert(rows, { 2.6, 10.6 })
	for f = 1, floors do
		local y0 = GF + (f - 1) * FH
		table.insert(rows, { y0 + 2.2, y0 + 8.8 })
	end
	local ww = 3.8
	local fronts = {}
	for i, fc in faces(cf, W, D) do
		local cols = math.max(2, math.floor(fc.width / 8.5))
		local g = if i == 1 then math.min(gnd[1], gnd[2]) elseif i == 2 then math.min(gnd[3], gnd[4]) elseif i == 3 then math.min(gnd[1], gnd[3]) else math.min(gnd[2], gnd[4])
		face({
			fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = cols, ww = ww, rows = rows,
			shop = if i == 1 then { 11.2 } else nil, gf = GF, share = if i == 1 then MAX_SHARE else 0.3,
		}, wall, Enum.Material.Plaster, m, det, if i == 1 then fronts else nil)
		if i == 1 then
			shops(fc.cf, fc.width, cols, 11.2, rng, det)
		end
	end
	-- stone foot band and the ground-floor course along the front
	quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.3, 1.4 - bottom, R + 0.25), CFrame = cf * CFrame.new(0, (bottom + 1.4) / 2, R / 2 - 0.12), Material = Enum.Material.Limestone, Color = foot }, m))
	small(part({ Name = "Course", Size = Vector3.new(W + 0.6, 1.2, 1), CFrame = cf * CFrame.new(0, GF - 0.6, 0), Material = Enum.Material.Limestone, Color = trim }, det))
	if floors >= 5 then
		small(part({ Name = "Course", Size = Vector3.new(W + 0.4, 0.6, 0.8), CFrame = cf * CFrame.new(0, GF + 2 * FH - 0.3, 0.05), Material = Enum.Material.Limestone, Color = trim }, det))
	end
	-- front windows: stone sills and hoods, shutters, balconies
	local shutters = rng:NextNumber() < 0.6
	local shutCol = SHUTTER[rng:NextInteger(1, #SHUTTER)]
	local balconyRows = { [1] = true, [floors] = rng:NextNumber() < 0.7 }
	if rng:NextNumber() < 0.4 then
		balconyRows[3] = true
	end
	local continuous = rng:NextNumber() < 0.35
	local cols = math.max(2, math.floor(W / 8.5))
	local step = W / cols
	for _, wcf in fronts do
		local y = (cf:PointToObjectSpace(wcf.Position)).Y
		if y < GF then
			continue
		end
		local f = math.floor((y - GF) / FH) + 1
		small(part({ Name = "Sill", Size = Vector3.new(ww + 1, 0.4, 0.9), CFrame = wcf * CFrame.new(0, -0.2, -0.15), Material = Enum.Material.Limestone, Color = trim }, det))
		small(part({ Name = "Hood", Size = Vector3.new(ww + 1.2, 0.5, 0.6), CFrame = wcf * CFrame.new(0, 6.6 + 0.6, -0.05), Material = Enum.Material.Limestone, Color = trim }, det))
		if shutters and not (balconyRows[f] and continuous) then
			for _, sx in { -1, 1 } do
				small(part({ Name = "Shutter", Size = Vector3.new(1.9, 6.6, 0.2), CFrame = wcf * CFrame.new(sx * (ww / 2 + 1.05), 3.3, -0.1), Material = Enum.Material.Wood, Color = shutCol }, det))
			end
		end
		if balconyRows[f] and not continuous then
			small(part({ Name = "Balcony", Size = Vector3.new(ww + 2.2, 0.5, 2), CFrame = wcf * CFrame.new(0, -0.45, -1), Material = Enum.Material.Limestone, Color = trim }, det))
			small(part({ Name = "Rail", Size = Vector3.new(ww + 2.2, 0.2, 0.2), CFrame = wcf * CFrame.new(0, 2.9, -1.9), Material = Enum.Material.Metal, Color = IRON }, det))
			small(part({ Name = "Ironwork", Size = Vector3.new(ww + 2.1, 3, 0.08), CFrame = wcf * CFrame.new(0, 1.3, -1.9), Material = Enum.Material.Metal, Color = IRON, Transparency = 0.45 }, det))
		end
	end
	if continuous then
		for f in balconyRows do
			local y = GF + (f - 1) * FH + 2.2
			small(part({ Name = "Balcony", Size = Vector3.new(W - 1, 0.6, 2.4), CFrame = cf * CFrame.new(0, y - 0.5, -1.2), Material = Enum.Material.Limestone, Color = trim }, det))
			small(part({ Name = "Rail", Size = Vector3.new(W - 1, 0.2, 0.2), CFrame = cf * CFrame.new(0, y + 2.9, -2.3), Material = Enum.Material.Metal, Color = IRON }, det))
			small(part({ Name = "Ironwork", Size = Vector3.new(W - 1.1, 3, 0.08), CFrame = cf * CFrame.new(0, y + 1.3, -2.3), Material = Enum.Material.Metal, Color = IRON, Transparency = 0.45 }, det))
		end
	end
	-- cornice, roof: grey mansard with dormers, or low terracotta
	part({ Name = "Cornice", Size = Vector3.new(W + 2.4, 1.6, D + 2.4), CFrame = cf * CFrame.new(0, H + 0.8, D / 2), Material = Enum.Material.Limestone, Color = trim }, m)
	local roofY = H + 1.6
	if rng:NextNumber() < 0.5 then
		local rh = 9
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(W, rh, 4), CFrame = cf * CFrame.new(0, roofY + rh / 2, 2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Slate, Color = SLATE }, m)
		part({ Name = "Roof", Size = Vector3.new(W, rh, D - 8), CFrame = cf * CFrame.new(0, roofY + rh / 2, D / 2), Material = Enum.Material.Slate, Color = SLATE }, m)
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(W, rh, 4), CFrame = cf * CFrame.new(0, roofY + rh / 2, D - 2), Material = Enum.Material.Slate, Color = SLATE }, m)
		for c = 1, cols, 2 do
			local x = -W / 2 + (c - 0.5) * step
			small(part({ Name = "Dormer", Size = Vector3.new(4.4, 5, 3), CFrame = cf * CFrame.new(x, roofY + 4, 1.6), Material = Enum.Material.Plaster, Color = trim }, det))
			small(part({ Name = "DormerWindow", Size = Vector3.new(2.6, 3.4, 0.1), CFrame = cf * CFrame.new(x, roofY + 4, 0.05), Material = Enum.Material.SmoothPlastic, Color = CORE }, det))
		end
	else
		-- low terracotta: two slopes to a ridge along the front, gable ends in the wall colour
		local rh = math.min(10, D * 0.22)
		local half = D / 2 + 0.6
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(W + 1.2, rh, half), CFrame = cf * CFrame.new(0, roofY + rh / 2, half / 2 - 0.6) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.ClayRoofTiles, Color = TILE }, m)
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(W + 1.2, rh, half), CFrame = cf * CFrame.new(0, roofY + rh / 2, D - half / 2 + 0.6), Material = Enum.Material.ClayRoofTiles, Color = TILE }, m)
	end
	for _ = 1, rng:NextInteger(2, 3) do
		small(part({ Name = "Chimney", Size = Vector3.new(2.2, 6, 2.2), CFrame = cf * CFrame.new(rng:NextNumber(-W / 2 + 3, W / 2 - 3), roofY + 5, rng:NextNumber(D * 0.3, D * 0.7)), Material = Enum.Material.Plaster, Color = trim }, det))
	end
	det:SetAttribute("Center", (cf * CFrame.new(0, H / 2, D / 2)).Position)
	det:SetAttribute("Range", 650)
	CollectionService:AddTag(det, "LOD")
	det.Parent = m
	-- only the core collides and answers rays: everything else is just for show (less physics work)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Body" then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- flat-roofed blocks: the 1970s-80s balcony blocks and the newer white ones
---------------------------------------------------------------------
local function roofTop(cf: CFrame, W: number, D: number, H: number, wall: Color3, rng: Random, m: Model, det: Instance, modern: boolean)
	local edge = wall:Lerp(Color3.new(1, 1, 1), 0.1)
	part({ Name = "Roof", Size = Vector3.new(W, 0.6, D), CFrame = cf * CFrame.new(0, H + 0.3, D / 2), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(120, 116, 110), 0.5) }, m)
	-- parapet
	for _, s in { { 0, W, 0.8, 0.4 }, { 0, W, 0.8, D - 0.4 } } do
		quiet(part({ Name = "Parapet", Size = Vector3.new(s[2], 2.4, s[3]), CFrame = cf * CFrame.new(s[1], H + 1.2, s[4]), Material = Enum.Material.Concrete, Color = edge }, m))
	end
	for _, sx in { -1, 1 } do
		quiet(part({ Name = "Parapet", Size = Vector3.new(0.8, 2.4, D), CFrame = cf * CFrame.new(sx * (W / 2 - 0.4), H + 1.2, D / 2), Material = Enum.Material.Concrete, Color = edge }, m))
	end
	-- plant room, AC units, a water tank, an aerial; terraces with umbrellas on the newer ones
	part({ Name = "PlantRoom", Size = Vector3.new(W * rng:NextNumber(0.25, 0.4), 7, D * rng:NextNumber(0.3, 0.45)), CFrame = cf * CFrame.new(rng:NextNumber(-W / 5, W / 5), H + 3.5, D * rng:NextNumber(0.45, 0.6)), Material = Enum.Material.Concrete, Color = wall }, m)
	for _ = 1, rng:NextInteger(2, 4) do
		small(part({ Name = "AC", Size = Vector3.new(3, 2.2, 2.2), CFrame = cf * CFrame.new(rng:NextNumber(-W / 2 + 3, W / 2 - 3), H + 1.7, rng:NextNumber(4, D - 4)), Material = Enum.Material.Metal, Color = Color3.fromRGB(196, 196, 192) }, det))
	end
	if rng:NextNumber() < 0.5 then
		small(part({ Name = "Tank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 4, 4), CFrame = cf * CFrame.new(rng:NextNumber(-W / 3, W / 3), H + 3.1, rng:NextNumber(D * 0.2, D * 0.8)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(170, 172, 170) }, det))
	end
	if rng:NextNumber() < 0.4 then
		small(part({ Name = "Aerial", Size = Vector3.new(0.3, 9, 0.3), CFrame = cf * CFrame.new(rng:NextNumber(-W / 3, W / 3), H + 5, rng:NextNumber(D * 0.3, D * 0.7)), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 150) }, det))
	end
	if modern or rng:NextNumber() < 0.25 then
		for _ = 1, rng:NextInteger(1, 3) do
			local p = cf * CFrame.new(rng:NextNumber(-W / 2 + 5, W / 2 - 5), H + 0.6, rng:NextNumber(4, D * 0.35))
			small(part({ Name = "UmbrellaPole", Size = Vector3.new(0.25, 6, 0.25), CFrame = p * CFrame.new(0, 3, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(220, 220, 214) }, det))
			small(part({ Class = "WedgePart", Name = "Umbrella", Size = Vector3.new(7, 1.2, 3.5), CFrame = p * CFrame.new(0, 6.2, -1.75), Material = Enum.Material.Fabric, Color = Color3.fromRGB(236, 230, 214) }, det))
			small(part({ Class = "WedgePart", Name = "Umbrella", Size = Vector3.new(7, 1.2, 3.5), CFrame = p * CFrame.new(0, 6.2, 1.75) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(236, 230, 214) }, det))
			small(part({ Name = "Planter", Size = Vector3.new(3, 2, 3), CFrame = p * CFrame.new(4, 1, 2), Material = Enum.Material.Concrete, Color = Color3.fromRGB(170, 150, 120) }, det))
			small(part({ Name = "Shrub", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4), CFrame = p * CFrame.new(4, 3, 2), Material = Enum.Material.Grass, Color = Color3.fromRGB(70, 104, 56) }, det))
		end
	end
end

local function block(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance, modern: boolean): Model
	local m = Instance.new("Model")
	m.Name = if modern then "Modern" else "Apartment"
	local floors = if modern then rng:NextInteger(7, 12) else rng:NextInteger(8, 16)
	local GF, FH = 12, 9
	local H = GF + floors * FH
	local wall = jitter(if modern then MODERN[rng:NextInteger(1, #MODERN)] else APART[rng:NextInteger(1, #APART)], rng)
	local mat = if modern then Enum.Material.Plaster else Enum.Material.Concrete
	local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, cf, W, D, bottom, H, wall)
	local rows = {}
	local nb = math.floor(-bottom / FH)
	for i = nb, 1, -1 do
		local y0 = -i * FH
		table.insert(rows, { y0 + 2, y0 + 7.4 })
	end
	table.insert(rows, { 2.4, 9.6 })
	for f = 1, floors do
		local y0 = GF + (f - 1) * FH
		table.insert(rows, { y0 + 1.4, y0 + 7.8 })
	end
	-- balcony fronts (front and back) have wide bays; the ends of the 1970s blocks are mostly blank
	local bay = if modern then 9 else 8
	local blankEnds = not modern and rng:NextNumber() < 0.65
	for i, fc in faces(cf, W, D) do
		local g = if i == 1 then math.min(gnd[1], gnd[2]) elseif i == 2 then math.min(gnd[3], gnd[4]) elseif i == 3 then math.min(gnd[1], gnd[3]) else math.min(gnd[2], gnd[4])
		if i >= 3 and blankEnds then
			-- a blank end wall with a column of small windows (stair landings)
			face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = 1, ww = 2.6, rows = rows, gf = GF, share = 0.3 }, wall, mat, m, det)
		else
			local cols = math.max(2, math.floor(fc.width / bay))
			local ww = if i <= 2 then fc.width / cols - 1.4 else 4
			face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = cols, ww = ww, rows = rows, shop = if i == 1 then { 9.8 } else nil, gf = GF, share = if i <= 2 then MAX_SHARE else 0.3 }, wall, mat, m, det, if i == 1 then {} else nil)
			if i == 1 then
				shops(fc.cf, fc.width, cols, 9.8, rng, det)
			end
		end
	end
	quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.3, 1.2 - bottom, R + 0.25), CFrame = cf * CFrame.new(0, (bottom + 1.2) / 2, R / 2 - 0.12), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(70, 64, 58), 0.4) }, m))
	-- balconies on the front (and the back): thin slabs in the wall colour, solid or glass parapets,
	-- now and then a sunblind or a plant
	local glassRail = modern or rng:NextNumber() < 0.35
	local slabCol = wall:Lerp(Color3.new(1, 1, 1), 0.08)
	local depth = if modern then 4.4 else 3.8
	for side = 1, (if rng:NextNumber() < 0.6 then 2 else 1) do
		local fcf = faces(cf, W, D)[side].cf
		for f = 1, floors do
			local y = GF + (f - 1) * FH
			small(part({ Name = "Balcony", Size = Vector3.new(W + 0.6, 0.6, depth), CFrame = fcf * CFrame.new(0, y + 0.3, -depth / 2), Material = mat, Color = slabCol }, det)).CastShadow = true
			if glassRail then
				small(part({ Name = "GlassRail", Size = Vector3.new(W + 0.6, 3.2, 0.15), CFrame = fcf * CFrame.new(0, y + 2.2, -depth + 0.1), Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 200, 198), Transparency = 0.62 }, det))
				small(part({ Name = "Rail", Size = Vector3.new(W + 0.6, 0.2, 0.25), CFrame = fcf * CFrame.new(0, y + 3.85, -depth + 0.1), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 196) }, det))
			else
				small(part({ Name = "Parapet", Size = Vector3.new(W + 0.6, 3, 0.35), CFrame = fcf * CFrame.new(0, y + 2.1, -depth + 0.2), Material = mat, Color = wall }, det))
			end
			if rng:NextNumber() < 0.18 then
				small(part({ Class = "WedgePart", Name = "Sunblind", Size = Vector3.new(W * rng:NextNumber(0.25, 0.5), 1.2, depth - 0.4), CFrame = fcf * CFrame.new(rng:NextNumber(-W / 4, W / 4), y + FH - 1.2, -depth / 2) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.Fabric, Color = AWNING[rng:NextInteger(1, #AWNING)] }, det))
			end
		end
	end
	roofTop(cf, W, D, H, wall, rng, m, det, modern)
	det:SetAttribute("Center", (cf * CFrame.new(0, H / 2, D / 2)).Position)
	det:SetAttribute("Range", 700)
	CollectionService:AddTag(det, "LOD")
	det.Parent = m
	-- only the core collides and answers rays: everything else is just for show (less physics work)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Body" then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- placement
---------------------------------------------------------------------
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.IgnoreWater = false

local function ground(p: Vector3): (number?, boolean)
	local hit = workspace:Raycast(Vector3.new(p.X, 1600, p.Z), Vector3.new(0, -1700, 0), params)
	if not hit then
		return nil, false
	end
	return hit.Position.Y, hit.Material == Enum.Material.Water
end

function Buildings.build(data, box, parent: Instance, rng: Random, opts): number
	opts = opts or {}
	params.FilterDescendantsInstances = { workspace.Terrain }
	-- every road sample, for "is this spot clear of all roads?"
	local grid = {}
	local roads = {}
	for _, r in data.roads do
		local pts = {}
		for i, s in r.s do
			local p = Vector3.new(s[1], s[2], s[3])
			pts[i] = { pos = p, dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1 }
			local key = math.floor(p.X / 40) .. "," .. math.floor(p.Z / 40)
			grid[key] = grid[key] or {}
			table.insert(grid[key], p)
		end
		table.insert(roads, { name = r.name, kind = r.kind, pts = pts })
	end
	local function clearOfRoads(p: Vector3, margin: number): boolean
		local cx, cz = math.floor(p.X / 40), math.floor(p.Z / 40)
		for dx = -2, 2 do
			for dz = -2, 2 do
				for _, q in grid[(cx + dx) .. "," .. (cz + dz)] or {} do
					if (Vector2.new(q.X - p.X, q.Z - p.Z)).Magnitude < margin then
						return false
					end
				end
			end
		end
		return true
	end
	-- placed footprints (oriented boxes), for overlap tests
	local placed = {}
	local function overlaps(c: Vector3, along: Vector3, right: Vector3, W: number, D: number): boolean
		for _, b in placed do
			if (Vector2.new(b.c.X - c.X, b.c.Z - c.Z)).Magnitude < (b.r + math.max(W, D) / 2) then
				-- separating axis test on the 4 axes (shrunk a little: touching is fine)
				local axes = { along, right, b.along, b.right }
				local sep = false
				for _, ax in axes do
					local function extent(a: Vector3, r: Vector3, w: number, d: number)
						return math.abs(a:Dot(ax)) * w / 2 + math.abs(r:Dot(ax)) * d / 2
					end
					local dist = math.abs((b.c - c):Dot(ax))
					if dist >= extent(along, right, W, D) + extent(b.along, b.right, b.W, b.D) - 1.5 then
						sep = true
						break
					end
				end
				if not sep then
					return true
				end
			end
		end
		return false
	end
	local count = 0
	Buildings.why = {}
	local function why(k)
		Buildings.why[k] = (Buildings.why[k] or 0) + 1
	end
	for _, r in roads do
		if r.kind ~= "street" and r.name ~= "Coast Road" and r.name ~= "Town Road" then
			continue
		end
		if opts.skip and opts.skip(r.name) then
			continue -- (the hillside lanes are kept for the players' house lots)
		end
		for _, side in { -1, 1 } do
			local acc = 0
			local nextGap = rng:NextNumber(2, 8)
			for i = 2, #r.pts do
				local a, b = r.pts[i - 1], r.pts[i]
				acc += (b.pos - a.pos).Magnitude
				if acc < nextGap or b.tunnel then
					continue
				end
				if box and not (b.pos.X >= box[1] and b.pos.X <= box[3] and b.pos.Z >= box[2] and b.pos.Z <= box[4]) then
					continue
				end
				local right = Vector3.new(-b.dir.Z, 0, b.dir.X).Unit * side
				local along = b.dir.Unit
				local front = b.pos + right * FRONT
				local D = rng:NextNumber(38, 54)
				-- the widest that fits: a narrower one before leaving a gap
				local done = false
				for try, W in { rng:NextNumber(36, 56), rng:NextNumber(26, 34), 20 } do
					local f = front
					local centre = f + right * (D / 2)
					local corners = { f - along * (W / 2), f + along * (W / 2), f - along * (W / 2) + right * D, f + along * (W / 2) + right * D }
					if overlaps(centre, along, right, W, D) then
						why("building")
						if try == 1 then
							break -- still too close to the last one: wait for the next spot
						end
						continue
					end
					local ok = true
					-- keep the sea side open (the harbour road's view, beaches)
					for _, extra in { 20, 70, 130 } do
						local _, wet = ground(f + right * (D + extra))
						if wet then
							ok = false
							why("seaside")
							break
						end
					end
					for k = 1, 4 do
						if not ok then
							break
						end
						ok = clearOfRoads(corners[k], HALF + WALK - 2) and clearOfRoads((corners[k] + centre) / 2, HALF + WALK - 2)
						if not ok then
							why("road")
						end
					end
					local gnd = {}
					local floorY = b.pos.Y + 0.5
					for k = 1, 4 do
						if not ok then
							break
						end
						local y, wet = ground(corners[k])
						if y == nil or wet or y < 1 then
							ok = false
							why(if y == nil then "noground" elseif wet then "water" else "low")
						else
							gnd[k] = math.min(0, y - floorY) -- relative to the floor (never above it)
						end
					end
					if not ok then
						continue
					end
					-- corners: 1 front-left, 2 front-right, 3 back-left, 4 back-right
					local cf = CFrame.lookAt(Vector3.new(f.X, floorY, f.Z), Vector3.new(f.X, floorY, f.Z) - right)
					local lx = cf.RightVector:Dot(along)
					if lx < 0 then
						gnd = { gnd[2], gnd[1], gnd[4], gnd[3] }
					end
					local belleChance = if opts.style then opts.style(centre) else 0.4
					local roll = rng:NextNumber()
					local low = r.name == "Old Rock" or r.name == "Rock Climb"
					local made = if roll < belleChance then belle(cf, W, D, gnd, rng, parent, low) else block(cf, W, D, gnd, rng, parent, rng:NextNumber() < 0.3)
					-- the terrain inside the footprint goes (no hill poking through the shops)
					pcall(function()
						workspace.Terrain:FillBlock(cf * CFrame.new(0, 40, D / 2), Vector3.new(W - 1, 79, D - 1), Enum.Material.Air)
					end)
					table.insert(placed, { c = centre, along = along, right = right, W = W, D = D, r = math.max(W, D) / 2 * 1.42 })
					count += 1
					acc = 0
					-- the next one's centre: this half width, a small gap, about half the next width
					nextGap = W / 2 + rng:NextNumber(0.5, 3) + 14
					done = true
					local _ = made
					if count % 4 == 0 then
						task.wait()
					end
					break
				end
				if not done then
					acc = math.max(0, nextGap - 4) -- try again a little further on
				end
			end
		end
	end
	return count
end

-- the kit, for the landmarks (tools/riviera/OldRock.luau)
Buildings.kit = { part = part, small = small, quiet = quiet, pane = pane, face = face, faces = faces, core = core, belle = belle, block = block, hash = hash, R = R, CORE = CORE, TILE = TILE, SLATE = SLATE, IRON = IRON, SHUTTER = SHUTTER, BELLE = BELLE }

-- café tables on the pavement in front of some ground-floor shops (Creator Store sets in
-- ServerStorage.RivieraAssets.Props: CafeA, CafeB, cleaned); never on the street furniture, lamps,
-- trees or the doors. Into each building's Detail (hidden far away). chance(position) -> 0..1
function Buildings.cafes(buildings: Instance, dressing: Instance, roads: Instance, rng: Random, chance: (Vector3) -> number): number
	local lib = game:GetService("ServerStorage"):FindFirstChild("RivieraAssets")
	local props = lib and lib:FindFirstChild("Props")
	local sets = {}
	for _, name in { "CafeA", "CafeB" } do
		local m = props and props:FindFirstChild(name)
		if m then
			table.insert(sets, m)
		end
	end
	if #sets == 0 then
		return 0
	end
	local busy = OverlapParams.new()
	busy.FilterType = Enum.RaycastFilterType.Include
	busy.FilterDescendantsInstances = { dressing, buildings }
	local down = RaycastParams.new()
	down.FilterType = Enum.RaycastFilterType.Include
	down.FilterDescendantsInstances = { roads }
	local n = 0
	for k, b in buildings:GetChildren() do
		local shell = b:GetAttribute("Shell")
		local size = b:GetAttribute("ShellSize")
		local det = b:FindFirstChild("Detail")
		if b.Name ~= "BelleEpoque" or typeof(shell) ~= "CFrame" or not det or rng:NextNumber() >= chance(shell.Position) then
			continue
		end
		local front = shell * CFrame.new(0, 0, -size.Z / 2)
		local door = det:FindFirstChild("Door")
		local pick = sets[rng:NextInteger(1, #sets)]
		for _ = 1, rng:NextInteger(1, 2) do
			local off = rng:NextNumber(-size.X / 2 + 5, size.X / 2 - 5)
			local spot = (front * CFrame.new(off, 0, -4.6)).Position
			if door and (Vector2.new(door.Position.X - spot.X, door.Position.Z - spot.Z)).Magnitude < 7 then
				continue
			end
			local hit = workspace:Raycast(spot + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), down)
			if not hit or hit.Instance.Name ~= "Pavement" then
				continue
			end
			local ground = hit.Position
			local m = pick:Clone()
			m:ScaleTo(m:GetScale() * 0.8)
			local _, sz = m:GetBoundingBox()
			local cf = CFrame.lookAt(ground, ground + front.LookVector) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
			if #workspace:GetPartBoundsInBox(cf * CFrame.new(0, sz.Y / 2 + 0.6, 0), Vector3.new(sz.X, sz.Y - 1, sz.Z), busy) > 0 then
				m:Destroy()
				continue
			end
			m:PivotTo(cf)
			local box, bs = m:GetBoundingBox()
			m:PivotTo(m:GetPivot() + Vector3.new(ground.X - box.Position.X, ground.Y + 0.02 - (box.Position.Y - bs.Y / 2), ground.Z - box.Position.Z))
			m.Name = "Cafe"
			m.Parent = det
			n += 1
		end
		if k % 50 == 0 then
			task.wait()
		end
	end
	return n
end

return Buildings
