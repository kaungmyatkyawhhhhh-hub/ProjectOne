--[[
	Marina (Studio, Edit mode; 2026-11-04, owner-away run step 6.3, the owner's photo
	imports/refs/map/marina_parking_supercars.png: a quayside car park right by the yachts, painted
	white bays and numbers on dark asphalt, supercars in a row, sterns and masts behind).

	Builds Workspace.Riviera.Marina on the harbour's east quay, between the Coast Road and the water
	(the quay where the road runs flat at the water's level). The quay is measured, not assumed: a
	frame runs along the road's edge (`a`, along; `n`, across towards the water) and every 4 studs
	the pavement's outer edge is found by raycast; the harbour edge is a straight quay wall on the
	line fitted to the water's edge.
	  * a flat asphalt deck (triangles, flush with the pavement), a granite kerb and black bollards
	    along the harbour edge, a stone quay wall down to the water, planters at both ends;
	  * two rows of painted bays (the harbour row backs onto the yachts like the photo), numbers on
	    the asphalt, a wide aisle; an invisible "ParkBay" marker in every bay (Parking puts parked
	    supercars there) under the folder MarinaBays;
	  * the entrance from the Coast Road: EntranceRamp (the venues' driveway, fitted to the kerb);
	  * yacht berths: an invisible "Berth" part every 30 studs on the water (its front points out to
	    sea, its back at the quay; PivotTo a yacht model onto it) with finger pontoons between them
	    and mooring cleats on the quay;
	  * harbour lamps (warm, night only) along the road side.
	Marina.build(opts?) -> Model. Marina.remove() takes it away (and puts back hidden map props).
]]

local Marina = {}

local ASPHALT = Color3.fromRGB(46, 47, 50)
local PAINT = Color3.fromRGB(236, 236, 230)
local GRANITE = Color3.fromRGB(150, 146, 138)
local STONE = Color3.fromRGB(176, 166, 148)
local IRON = Color3.fromRGB(24, 24, 26)
local WOOD = Color3.fromRGB(128, 96, 64)
local WARM = Color3.fromRGB(255, 214, 160)

local ROADISH = { Road = true, Pavement = true, Kerb = true, Rail = true, Wall = true, Line = true, Zebra = true, LaneDash = true }

export type Opts = {
	origin: Vector3?, -- a point on the pavement's outer edge where the quay starts
	along: Vector3?, -- the road's direction there
	t0: number?, -- the deck from t0 to t1 along (studs from the origin)
	t1: number?,
	deckY: number?, -- the deck's top (flush with the pavement)
	entranceT: number?, -- where the drive from the road comes in
}

local function newPart(parent: Instance, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid ~= false
	p.CanQuery = solid ~= false
	p.CanTouch = false
	p.CastShadow = solid ~= false
	p.Parent = parent
	return p
end

-- a flat triangle (two wedges), top face through a, b, c (the road tools' helper)
local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, parent: Instance, color: Color3, mat: Enum.Material)
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
		return
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	local drop = -nUp * (th / 2)
	for _, spec in {
		{ Vector3.new(th, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2 + drop, right, up, back) },
		{ Vector3.new(th, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back) },
	} do
		if spec[1].Y > 0.01 and spec[1].Z > 0.01 then
			local w = Instance.new("WedgePart")
			w.Name = "Deck"
			w.Anchored = true
			w.Size = spec[1]
			w.CFrame = spec[2]
			w.Color = color
			w.Material = mat
			w.CastShadow = false
			w.TopSurface = Enum.SurfaceType.Smooth
			w.BottomSurface = Enum.SurfaceType.Smooth
			w.Parent = parent
		end
	end
end

-- a number painted on the asphalt (a thin plate with the text on top)
local function paintNumber(parent: Instance, cf: CFrame, text: string)
	local plate = newPart(parent, Vector3.new(5, 0.05, 4), cf, ASPHALT, Enum.Material.Asphalt, false)
	plate.Transparency = 1
	plate.Name = "BayNumber"
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Top
	g.CanvasSize = Vector2.new(250, 200)
	g.LightInfluence = 1
	g.MaxDistance = 220
	g.Parent = plate
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextColor3 = PAINT
	t.TextTransparency = 0.08
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.Parent = g
end

function Marina.remove()
	local riv = workspace:FindFirstChild("Riviera")
	local old = riv and riv:FindFirstChild("Marina")
	if old then
		old:Destroy()
	end
	if riv then
		for _, d in riv:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("MarinaHidden") then
				d.Transparency = d:GetAttribute("MarinaHidden") :: number
				d.CanCollide = true
				d.CanQuery = true
				d:SetAttribute("MarinaHidden", nil)
			end
		end
	end
end

function Marina.build(opts: Opts?): Model
	local o = opts or {}
	Marina.remove()
	local riv = workspace:FindFirstChild("Riviera") :: Instance
	local origin = o.origin or Vector3.new(14004, 0, 700)
	local a = (o.along or Vector3.new(0.608, 0, 0.794)).Unit
	local n = Vector3.new(-a.Z, 0, a.X) -- across, towards the water
	local t0, t1 = o.t0 or -20, o.t1 or 96
	local deckY = o.deckY or 6.6
	local entT = o.entranceT or -4
	local model = Instance.new("Model")
	model.Name = "Marina"
	model.Parent = riv
	local function P(t: number, s: number, y: number?): Vector3
		local q = origin + a * t + n * s
		return Vector3.new(q.X, y or deckY, q.Z)
	end

	-------------------------------------------------------------------
	-- measure: the pavement's outer edge and the water's edge every 4 studs
	-------------------------------------------------------------------
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { model }
	rp.IgnoreWater = false
	local inner: { [number]: number } = {}
	local sumT, sumS, sumTT, sumTS, cnt = 0, 0, 0, 0, 0
	for t = t0, t1, 4 do
		local roadEdge, waterEdge = nil, nil
		for s = -20, 150, 0.5 do
			local q = P(t, s)
			local h = workspace:Raycast(Vector3.new(q.X, 150, q.Z), Vector3.new(0, -200, 0), rp)
			if h then
				if h.Instance == workspace.Terrain then
					if h.Material == Enum.Material.Water then
						waterEdge = s
						break
					end
				elseif ROADISH[h.Instance.Name] then
					roadEdge = s
				end
			end
		end
		inner[t] = (roadEdge or 0) + 0.7
		if waterEdge then
			sumT += t
			sumS += waterEdge
			sumTT += t * t
			sumTS += t * waterEdge
			cnt += 1
		end
	end
	-- buildings standing on the quay (one Belle Epoque block sits by the road): the deck goes round
	-- them on the water side, 2 studs clear
	local blocked: { { number } } = {}
	do
		local ov = OverlapParams.new()
		ov.FilterType = Enum.RaycastFilterType.Include
		ov.FilterDescendantsInstances = { riv:FindFirstChild("Buildings") :: Instance }
		local mid = P((t0 + t1) / 2, 50, deckY + 10)
		for _, part in workspace:GetPartBoundsInBox(CFrame.lookAt(mid, mid + a), Vector3.new(120, 16, t1 - t0 + 10), ov) do
			if part.Name == "Body" and part:IsA("BasePart") then
				local tmin, tmax, smax = math.huge, -math.huge, -math.huge
				for _, dx in { -1, 1 } do
					for _, dz in { -1, 1 } do
						local c = (part.CFrame * CFrame.new(dx * part.Size.X / 2, 0, dz * part.Size.Z / 2)).Position - origin
						tmin, tmax, smax = math.min(tmin, c:Dot(a)), math.max(tmax, c:Dot(a)), math.max(smax, c:Dot(n))
					end
				end
				if smax > 0 then
					table.insert(blocked, { tmin, tmax, smax })
				end
			end
		end
		for t, v in inner do
			for _, b in blocked do
				if t >= b[1] - 4 and t <= b[2] + 4 then
					inner[t] = math.max(v, b[3] + 2)
				end
			end
		end
	end
	local rowEnd = t1 - 6 -- the road row stops before the first building
	for _, b in blocked do
		rowEnd = math.min(rowEnd, b[1] - 6)
	end

	-- the harbour edge: a straight line s = c0 + c1 t fitted to the water's edge (outliers dropped)
	local c1 = (cnt * sumTS - sumT * sumS) / math.max(1e-6, cnt * sumTT - sumT * sumT)
	local c0 = (sumS - c1 * sumT) / math.max(1, cnt)
	local function outer(t: number): number
		return c0 + c1 * t - 1
	end
	model:SetAttribute("HarbourLine", Vector2.new(c0, c1))

	-------------------------------------------------------------------
	-- the deck
	-------------------------------------------------------------------
	local deck = Instance.new("Model")
	deck.Name = "Deck"
	deck.Parent = model
	local tPrev: number? = nil
	for t = t0, t1, 4 do
		if tPrev then
			local A, B = P(tPrev, inner[tPrev]), P(tPrev, outer(tPrev))
			local C, D = P(t, outer(t)), P(t, inner[t])
			triangle(A, B, C, 4, deck, ASPHALT, Enum.Material.Asphalt)
			triangle(A, C, D, 4, deck, ASPHALT, Enum.Material.Asphalt)
		end
		tPrev = t
	end
	-- an underlay 0.06 under the top, so a wheel's ray never drops through a hairline seam between
	-- two triangles (hidden under the deck; 0.06 apart, no flicker)
	tPrev = nil
	for t = t0, t1, 4 do
		if tPrev then
			local si = math.max(inner[tPrev], inner[t])
			local so = math.min(outer(tPrev), outer(t))
			if so - si > 1 then
				local c = P((tPrev + t) / 2, (si + so) / 2, deckY - 0.06 - 1.5)
				local u = newPart(deck, Vector3.new(so - si, 3, 4.4), CFrame.lookAt(c, c + a), ASPHALT, Enum.Material.Asphalt)
				u.Name = "DeckUnder"
				u.CastShadow = false
			end
		end
		tPrev = t
	end
	-- no terrain poking through the deck
	for t = t0, t1, 8 do
		local mid = (P(t, inner[t] or 0) + P(t, outer(t))) / 2
		local w = outer(t) - (inner[t] or 0)
		workspace.Terrain:FillBlock(CFrame.lookAt(mid + Vector3.new(0, 15.05, 0), mid + Vector3.new(0, 15.05, 0) + a), Vector3.new(w, 30, 9), Enum.Material.Air)
	end

	-------------------------------------------------------------------
	-- the harbour edge: quay wall, granite kerb, bollards, cleats; planters at the ends
	-------------------------------------------------------------------
	local edge = Instance.new("Model")
	edge.Name = "HarbourEdge"
	edge.Parent = model
	local e0, e1 = P(t0, outer(t0) + 1), P(t1, outer(t1) + 1)
	local dirW = (e1 - e0).Unit
	local lenW = (e1 - e0).Magnitude
	local midW = (e0 + e1) / 2
	local wallCF = CFrame.lookAt(midW, midW + dirW)
	-- (from the deck's edge, 1 inside the harbour line, to 0.6 outside it, down into the water)
	newPart(edge, Vector3.new(1.6, deckY + 3, lenW + 1.6), (wallCF - n * 0.2) + Vector3.new(0, -(deckY + 3) / 2 + 0.1, 0), STONE, Enum.Material.Limestone).Name = "QuayWall"
	-- (the wall's face runs on the harbour line; the kerb sits on the deck just inside it)
	local kerbCF = wallCF * CFrame.new(0, 0, 0) - n * 0.9
	newPart(edge, Vector3.new(1.6, 0.9, lenW), kerbCF + Vector3.new(0, 0.45, 0), GRANITE, Enum.Material.Granite).Name = "QuayKerb"
	local vk = game:GetService("ServerStorage"):FindFirstChild("RivieraAssets")
	local props = vk and vk:FindFirstChild("Props")
	local bollardSrc = props and props:FindFirstChild("BollardBlack")
	local nb = math.floor(lenW / 12)
	for k = 0, nb do
		local pos = e0 + dirW * (k * lenW / nb) - n * 3
		if bollardSrc and bollardSrc:IsA("Model") then
			local b = bollardSrc:Clone()
			b:PivotTo(CFrame.new(pos))
			b.Parent = edge
		else
			newPart(edge, Vector3.new(3, 0.9, 0.9), CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), IRON, Enum.Material.Metal).Shape = Enum.PartType.Cylinder
		end
	end
	-- the end planters (stone boxes with clipped shrubs) across both ends
	for _, ends in { { t0 + 1.5, t0 }, { t1 - 1.5, t1 } } do
		local t = ends[1]
		local i0, i1 = inner[ends[2]] or 0, outer(t)
		local s = i0 + 3
		while s < i1 - 3 do
			local c = P(t, s)
			newPart(edge, Vector3.new(5, 2.2, 3), CFrame.lookAt(c + Vector3.new(0, 1.1, 0), c + Vector3.new(0, 1.1, 0) + a), STONE, Enum.Material.Limestone)
			local shrub = newPart(edge, Vector3.new(4.6, 2.6, 2.6), CFrame.lookAt(c + Vector3.new(0, 3.2, 0), c + Vector3.new(0, 3.2, 0) + a), Color3.fromRGB(70, 96, 54), Enum.Material.Grass, false)
			shrub.Shape = Enum.PartType.Ball
			s += 7
		end
	end

	-------------------------------------------------------------------
	-- the bays: a harbour row (backs to the yachts) and a road row, a wide aisle between
	-------------------------------------------------------------------
	local paint = Instance.new("Model")
	paint.Name = "Paint"
	paint.Parent = model
	local markers = Instance.new("Folder")
	markers.Name = "MarinaBays"
	markers.Parent = model
	local BW, BD = 10, 20
	local num = 0
	local function line(p1: Vector3, p2: Vector3, w: number)
		local mid = (p1 + p2) / 2
		local len = (p2 - p1).Magnitude
		newPart(paint, Vector3.new(w, 0.05, len), CFrame.lookAt(mid + Vector3.new(0, 0.06, 0), mid + Vector3.new(0, 0.06, 0) + (p2 - p1).Unit), PAINT, Enum.Material.SmoothPlastic, false).Name = "BayLine"
	end
	-- a row along the line from `from` in direction `dir`, bays going `inward` (unit, across)
	local function row(from: Vector3, dir: Vector3, length: number, inward: Vector3, skip: ((number) -> boolean)?)
		local count = math.floor(length / BW)
		local start = from + dir * ((length - count * BW) / 2)
		for k = 0, count do
			local p = start + dir * (k * BW)
			local along = k * BW
			if not (skip and (skip(along) or (k > 0 and skip(along - BW)))) then
				line(p, p + inward * BD, 0.45)
			end
		end
		line(start, start + dir * (count * BW), 0.45) -- the line along the bays' backs
		for k = 0, count - 1 do
			local along = (k + 0.5) * BW
			if not (skip and skip(along)) then
				num += 1
				local c = start + dir * along + inward * (BD / 2)
				-- the marker faces out of the bay (towards the aisle): a parked car's nose
				local m = newPart(markers, Vector3.new(BW - 1, 1, BD - 1), CFrame.lookAt(c, c + inward), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, false)
				m.Name = "ParkBay"
				m.Transparency = 1
				local nc = start + dir * along + inward * (BD - 3)
				paintNumber(paint, CFrame.lookAt(nc + Vector3.new(0, 0.06, 0), nc + Vector3.new(0, 0.06, 0) - inward), tostring(num))
			end
		end
	end
	-- the harbour row: backs 4 studs inside the harbour line, bays reaching in
	local hb0, hb1 = P(t0 + 6, outer(t0 + 6) - 4), P(t1 - 6, outer(t1 - 6) - 4)
	row(hb0, (hb1 - hb0).Unit, (hb1 - hb0).Magnitude, -n)
	-- the road row: backs 2.5 inside the pavement, a gap for the entrance
	local innerMax = -math.huge
	for t, v in inner do
		if t >= t0 + 6 and t <= rowEnd then
			innerMax = math.max(innerMax, v)
		end
	end
	local rb0, rb1 = P(t0 + 6, innerMax + 2.5), P(rowEnd, innerMax + 2.5)
	row(rb0, a, (rb1 - rb0).Magnitude, n, function(along: number): boolean
		local t = t0 + 6 + along
		return math.abs(t - entT) < 16
	end)

	-------------------------------------------------------------------
	-- yacht berths, finger pontoons, cleats
	-------------------------------------------------------------------
	local berths = Instance.new("Folder")
	berths.Name = "YachtBerths"
	berths.Parent = model
	berths:SetAttribute("Note", "PivotTo a yacht model onto a Berth part: its front points out to sea, its back sits at the quay wall")
	local water = Instance.new("Model")
	water.Name = "Pontoons"
	water.Parent = model
	local nBerth = math.floor(lenW / 30)
	for k = 0, nBerth do
		local base = e0 + dirW * (k * lenW / nBerth)
		base = Vector3.new(base.X, 1.2, base.Z)
		-- a finger pontoon: planks on floats, 32 out
		local mid = base + n * 17
		newPart(water, Vector3.new(4, 0.6, 32), CFrame.lookAt(mid, mid + n), WOOD, Enum.Material.WoodPlanks).Name = "Pontoon"
		newPart(water, Vector3.new(3.6, 1.2, 31), CFrame.lookAt(mid - Vector3.new(0, 0.85, 0), mid - Vector3.new(0, 0.85, 0) + n), Color3.fromRGB(210, 210, 206), Enum.Material.SmoothPlastic, false)
		for _, d in { 6, 18, 30 } do
			local post = base + n * d + dirW * 2.4
			newPart(water, Vector3.new(0.8, 6, 0.8), CFrame.new(post + Vector3.new(0, 1.4, 0)), IRON, Enum.Material.Metal, false)
		end
		-- a cleat on the quay
		local cl = Vector3.new(base.X, deckY, base.Z) - n * 1.2 + dirW * 4
		newPart(edge, Vector3.new(1.6, 0.4, 0.5), CFrame.lookAt(cl + Vector3.new(0, 0.5, 0), cl + Vector3.new(0, 0.5, 0) + dirW), IRON, Enum.Material.Metal, false)
		if k < nBerth then
			local bc = base + dirW * (lenW / nBerth / 2) + n * 30
			local berth = newPart(berths, Vector3.new(14, 2, 56), CFrame.lookAt(Vector3.new(bc.X, 0.6, bc.Z), Vector3.new(bc.X, 0.6, bc.Z) + n), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, false)
			berth.Name = "Berth"
			berth.Transparency = 1
			berth:SetAttribute("Index", k + 1)
		end
	end

	-------------------------------------------------------------------
	-- harbour lamps along the road side (warm, night only, lit near the player)
	-------------------------------------------------------------------
	local CS = game:GetService("CollectionService")
	local lamps = Instance.new("Model")
	lamps.Name = "Lamps"
	lamps.Parent = model
	for t = t0 + 12, t1 - 8, 28 do
		local tk = t0 + math.floor((t - t0) / 4 + 0.5) * 4
		if math.abs(t - entT) > 18 then
			local foot = P(t, (inner[tk] or innerMax) + 1.2)
			newPart(lamps, Vector3.new(1.4, 0.6, 1.4), CFrame.new(foot + Vector3.new(0, 0.3, 0)), IRON, Enum.Material.Metal)
			newPart(lamps, Vector3.new(0.5, 16, 0.5), CFrame.new(foot + Vector3.new(0, 8.4, 0)), IRON, Enum.Material.Metal)
			for _, side in { -1, 1 } do
				local arm = foot + a * side * 1.6 + Vector3.new(0, 15.6, 0)
				newPart(lamps, Vector3.new(0.3, 0.3, 3.2), CFrame.lookAt(arm - a * side * 1.6 * 0.5, arm), IRON, Enum.Material.Metal, false)
				local head = newPart(lamps, Vector3.new(1.4, 1.8, 1.4), CFrame.new(arm - Vector3.new(0, 1, 0)), Color3.fromRGB(255, 226, 176), Enum.Material.Glass, false)
				head.Transparency = 0.15
				CS:AddTag(head, "LampGlow")
				local l = Instance.new("PointLight")
				l.Color = WARM
				l.Range = 34
				l.Brightness = 1.6
				l.Shadows = false
				l.Parent = head
				CS:AddTag(l, "DayOff")
				CS:AddTag(l, "LODLight")
			end
		end
	end

	-------------------------------------------------------------------
	-- the entrance from the Coast Road (the venues' driveway, fitted to the kerb)
	-------------------------------------------------------------------
	local ss = game:GetService("ServerScriptService")
	local erSrc = ss:FindFirstChild("EntranceRamp", true)
	if erSrc and erSrc:IsA("ModuleScript") then
		local copy = erSrc:Clone()
		copy.Parent = erSrc.Parent
		local ok, ER = pcall(require, copy)
		copy:Destroy()
		if ok then
			-- the railing along the pavement's edge opens for the drive (hidden, put back by remove)
			local ec = P(entT, (inner[entT] or innerMax) - 1, deckY + 3)
			local ov = OverlapParams.new()
			ov.FilterType = Enum.RaycastFilterType.Exclude
			ov.FilterDescendantsInstances = { model, workspace.Terrain }
			for _, part in workspace:GetPartBoundsInBox(CFrame.lookAt(ec, ec + a), Vector3.new(8, 8, 26), ov) do
				local nm = string.lower(part.Name)
				if string.find(nm, "rail") or string.find(nm, "post") or string.find(nm, "baluster") or string.find(nm, "bollard") or string.find(nm, "plinth") or string.find(nm, "balustrade") or string.find(nm, "coping") then
					part:SetAttribute("MarinaHidden", part.Transparency)
					part.Transparency = 1
					part.CanCollide = false
					part.CanQuery = false
				end
			end
			local inCF = CFrame.lookAt(P(entT, inner[entT] or innerMax, deckY), P(entT, (inner[entT] or innerMax) - 10, deckY))
			local okb, err = pcall(ER.build, model, inCF, { width = 24, color = ASPHALT, material = Enum.Material.Asphalt, keep = { model } })
			if not okb then
				warn("[Marina] entrance:", err)
			end
		end
	end

	model:SetAttribute("Bays", num)
	return model
end

return Marina
