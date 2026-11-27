--[[
	Yangon-Dala Bridge (Myanmar-Korea Friendship Bridge) at 1:1 (owner, 21 Nov 2026: "the dala bridge needs to be 1:1
	exactly the same as the real life"). Re-runnable: paste into the MCP's execute_luau (Edit) as
		local M = (function() <this file> end)()  return M.build()
	Everything goes into Workspace.Yangon1to1.Landmarks.DalaBridge (attribute From); M.undo() removes it. It touches
	nothing else (reads Roads.Collide and Terrain with rays only).

	Scale: tools/yangon/city/geo.py at YANGON_SCALE=1to1: 3 studs a metre across AND up,
	X = 30000 + (lon - 96.14) * KX * 3, Z = 30000 - (lat - 16.82) * KY * 3.

	Collision follows Roads.Collide: Parts named RCol, Transparency 1, CanCollide + CanQuery, CanTouch false, size
	(width, 2, length) lying along the road with the TOP on the surface, attribute RoadBox = D deck / W parapet or
	barrier / P walkway / R road at grade. Visual parts: CanCollide / CanQuery / CanTouch false.
	Night: WorldFx's own tags (LandmarkGlow + DayColor / DayMaterial / NightColor, LampGlow, FacadeNight, lights
	LODLight + DayOff and Enabled false), so everything is off by day.

	27 Nov 2026 (owner: "ok do the changes"; vault `City Legends/2026-11-27 Clip catalogue - Yangon-Dala cable-stayed bridge at
	night (0808).md` section 3, night clip IMG_0808 parts 1 + 2): pale deck, the real edge on the cable-stayed part (low kerb,
	2-rail steel guard rail, anchor strip, vertical-bar railing), bell anchor caps with a yellow reflector and an uplight,
	lamps on the anchor strip with an arm, lower legs closing to ONE footing (V), lilac wash on the inner leg faces only, a lit
	window under the cap, 50 km/h signs + plaques at the legs, frosted screens on the approaches, a white edge line on the
	ramps, and the Dala end (gantry with Dala / Sat Ein Tann Beach / Twante + 5.5 m, hump sign, rumble band, toll lane lights,
	down-light grid, booth frames, water barriers). The result is kept in ServerStorage (not live).
]]
local M = {}
local FROM = "DalaBridge 21Nov"
local S = 3 -- studs per metre (geo.py SPM = VS = 3)
local KX, KY = 111320 * math.cos(math.rad(16.82)), 110540

-- ---- real dimensions (metres) and where each comes from ----
local MAIN_LEN = 690 -- cable-stayed main bridge: 2,264 ft (MOC / Global New Light of Myanmar) = 690 m (Utracon project page)
local MAIN_SPAN = 370 -- Wikipedia "List of bridges in Myanmar"; side spans (690 - 370) / 2 = 160 (derived, one source)
local APPROACH_DALA = 601 -- 1,972 ft (state media); Utracon gives 577 / 601 the other way round: total 1,868 m either way
local APPROACH_SPAN = 45 -- precast I-girders 44.9 m long (Utracon) = pier spacing of the approaches
local GRADE = 0.06 -- approach longitudinal slope 6% (Utracon)
local CLEARANCE = 48.8 -- navigation clearance 160 ft (state media)
local BOX_DEPTH = 2.8 -- steel box girder depth: typical for this span, NOT sourced
local CREST = 52 -- deck surface over the water at mid span = clearance + box + surfacing (derived)
local DECK_W = 26.5 -- four-lane bridge width 87 ft (state media)
local LEG_W = 14.3 -- two-lane Yangon (Phone Gyi Street) approach 47 ft (state media)
local RAMP_W = 8.5 -- Strand Road ramps: measured from IMG_0808 (one wide lane + shoulders between parapets)
local LANE = 3.5 -- the ruler for everything measured from the videos
local PYLON_ABOVE_DECK = 84 -- no source found: measured from IMG_0808 46 s / 52 s (1.7-1.9 x the deck's height over the pile cap)
local CABLES = 14 -- per fan per plane (2 planes x 4 fans = 112): counted from IMG_0808 52 s, approximate
local LAMP_GAP = 35 -- every third stay anchor in IMG_0808 138 s, approximate
local WATER_Y = 3.0 -- the river's surface in the place (ray on Terrain water)
-- centreline: OSM way 1219935185 (Yangon-Dala Bridge) + ramps 1416082924 (west, on) / 1416082923 (east, off), from
-- overpass-api.de 21 Nov 2026 (build/osm_ygn has no roads.json; the copy is build/dala_bridge/overpass.json)
local MAIN = { { 96.145006, 16.779221 }, { 96.144762, 16.772652 }, { 96.142709, 16.76481 }, { 96.142566, 16.764124 }, { 96.142753, 16.760129 }, { 96.142702, 16.759621 }, { 96.142577, 16.75897 }, { 96.142465, 16.758355 }, { 96.142353, 16.757753 }, { 96.142315, 16.757534 }, { 96.142295, 16.757431 } }
local WEST = { { 96.139355, 16.774936 }, { 96.139606, 16.7749 }, { 96.139917, 16.774897 }, { 96.141211, 16.77483 }, { 96.141526, 16.774794 }, { 96.141774, 16.774721 }, { 96.141971, 16.774642 }, { 96.142127, 16.774579 }, { 96.144254, 16.773455 }, { 96.144465, 16.773329 } }
local EAST = { { 96.150268, 16.772016 }, { 96.149052, 16.772045 }, { 96.14799, 16.772091 }, { 96.147438, 16.77213 }, { 96.147105, 16.772176 }, { 96.14653, 16.772321 }, { 96.145805, 16.772662 }, { 96.14531, 16.772932 }, { 96.14515, 16.772943 } }
local JUNCTION = { 96.144762, 16.772652 } -- where the ramps join (OSM node)
local MID = { 96.143901, 16.769362 } -- middle of the river on the centreline (OSM river polygon 35911642: banks 684.5 m apart)
local WEST_SKIP = 100 -- the west ramp's first 100 m lie outside the built map: it starts on the existing road there
local PLAZA = 1190 -- toll plaza: metres south of mid span, on the Dala side at grade (IMG_0808 200-231 s); position approximate

-- cross-sections in metres: cw = half the carriageway (between barriers), tot = half the whole deck
local SEC = {
	main = { cw = 8.8, tot = DECK_W / 2 }, -- 2 x (0.3 median half + 0.5 + 2 lanes + 1.0 shoulder), barriers 0.45, 4.0 walk + cable zone
	leg = { cw = LEG_W / 2 - 0.45, tot = LEG_W / 2 },
	ramp = { cw = RAMP_W / 2 - 0.45, tot = RAMP_W / 2 },
}
local C = {
	asphalt = Color3.fromRGB(58, 58, 62), concrete = Color3.fromRGB(168, 166, 160), steel = Color3.fromRGB(205, 205, 200),
	pylon = Color3.fromRGB(214, 210, 198), cable = Color3.fromRGB(226, 222, 204), yellow = Color3.fromRGB(230, 222, 114),
	white = Color3.fromRGB(235, 235, 230), lamp = Color3.fromRGB(236, 244, 255), rail = Color3.fromRGB(190, 192, 196),
	pylonNight = Color3.fromRGB(124, 122, 116), -- 27 Nov: 164,157,142 bloomed the whole pylon into a white blob at night (Edit shot)
	cableNight = Color3.fromRGB(120, 116, 104), violet = Color3.fromRGB(150, 120, 205), -- the LED wash on the legs, IMG_0808 46 s
	deck = Color3.fromRGB(178, 174, 166), -- pale grey deck under white lamps (night clip p2 1:19, p1 0:21, p1 1:31 concrete)
	silver = Color3.fromRGB(196, 198, 200), railWhite = Color3.fromRGB(222, 224, 222), capCream = Color3.fromRGB(214, 204, 172),
	reflector = Color3.fromRGB(240, 196, 40), red = Color3.fromRGB(200, 40, 36), signGreen = Color3.fromRGB(46, 132, 124),
	bronze = Color3.fromRGB(118, 90, 58), screen = Color3.fromRGB(214, 220, 222),
}

local BARS_TEX = "rbxassetid://128299204776548" -- imports/sync/dala_rail_bars.png (Decal 131639002789551, group 33151111)

local function W(ll) return Vector3.new(30000 + (ll[1] - 96.14) * KX * S, 0, 30000 - (ll[2] - 16.82) * KY * S) end

-- ---- lines ----
local function chaikin(p)
	for _ = 1, 3 do
		local q = { p[1] }
		for i = 1, #p - 1 do
			table.insert(q, p[i]:Lerp(p[i + 1], 0.25))
			table.insert(q, p[i]:Lerp(p[i + 1], 0.75))
		end
		table.insert(q, p[#p])
		p = q
	end
	return p
end
local function newLine(pts)
	local L = { p = chaikin(pts), cum = { 0 } }
	for i = 2, #L.p do L.cum[i] = L.cum[i - 1] + (L.p[i] - L.p[i - 1]).Magnitude end
	L.len = L.cum[#L.cum]
	return L
end
local function sample(L, s)
	s = math.clamp(s, 0, L.len)
	local i = 1
	while i < #L.p - 1 and L.cum[i + 1] < s do i += 1 end
	local d = L.p[i + 1] - L.p[i]
	return L.p[i] + d * ((s - L.cum[i]) / d.Magnitude), d.Unit
end
local function project(L, pt)
	local best, bs = math.huge, 0
	for s = 0, L.len, 1 do
		local d = (sample(L, s) - pt).Magnitude
		if d < best then best, bs = d, s end
	end
	return bs
end
local function frame(L, s) -- on the deck surface, looking along rising stations, RightVector = local +X
	local p, d = sample(L, s)
	local y = L.y(s)
	local slope = (L.y(math.min(s + 3, L.len)) - L.y(math.max(s - 3, 0))) / (math.min(s + 3, L.len) - math.max(s - 3, 0))
	local P = Vector3.new(p.X, y, p.Z)
	return CFrame.lookAt(P, P + Vector3.new(d.X, slope, d.Z)), slope, math.atan2(d.X, d.Z)
end

-- ---- parts ----
local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.Size, p.CFrame, p.Color = name, true, size, cf, color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = size.Y >= 6
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function rcol(parent, kind, size, cf)
	local p = part(parent, "RCol", size, cf, C.concrete, Enum.Material.Plastic)
	p.Transparency, p.CanCollide, p.CanQuery, p.CastShadow = 1, true, true, false
	p:SetAttribute("RoadBox", kind)
	return p
end
local function glow(p, night)
	p:SetAttribute("DayColor", p.Color)
	p:SetAttribute("DayMaterial", p.Material.Name)
	p:SetAttribute("NightColor", night)
	p:AddTag("LandmarkGlow")
	return p
end
local function neon(parent, name, size, cf, color)
	local p = part(parent, name, size, cf, color, Enum.Material.Neon)
	p.Transparency = 1
	p:AddTag("FacadeNight")
	return p
end
local function beam(parent, name, a, b, tx, ty, color) -- a box from a to b
	return part(parent, name, Vector3.new(tx, ty, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
end
local function rod(parent, name, a, b, dia, color) -- a cylinder from a to b
	return part(parent, name, Vector3.new((b - a).Magnitude, dia, dia), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), color, nil, Enum.PartType.Cylinder)
end

local function gui(p, face, ppS, light)
	local sg = Instance.new("SurfaceGui")
	sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, ppS or 40, light or 0.6
	sg.Parent = p
	return sg
end
local function frameUI(parent, pos, size, color, round)
	local f = Instance.new("Frame")
	f.AnchorPoint, f.Position, f.Size, f.BackgroundColor3, f.BorderSizePixel = Vector2.new(0.5, 0.5), pos, size, color, 0
	if round then Instance.new("UICorner", f).CornerRadius = UDim.new(round, 0) end
	f.Parent = parent
	return f
end
local function textUI(parent, pos, size, text, color, font)
	local t = Instance.new("TextLabel")
	t.AnchorPoint, t.Position, t.Size, t.BackgroundTransparency, t.TextScaled = Vector2.new(0.5, 0.5), pos, size, 1, true
	t.Text, t.TextColor3, t.Font = text, color, font or Enum.Font.GothamBold
	t.Parent = parent
	return t
end
-- a drawn arrow (shaft + ▲ head) in a square box: kind "up", "left" (turn left hook) or "right" (turn right hook)
local function arrowUI(parent, pos, size, kind, color)
	local box = frameUI(parent, pos, size, color)
	box.BackgroundTransparency = 1
	local function head(p, rot) -- a drawn diamond: its back half sits on the shaft, the front half is the tip
		local d = frameUI(box, p, UDim2.fromScale(0.36, 0.36), color)
		Instance.new("UIAspectRatioConstraint", d)
		d.Rotation = 45 -- the same diamond for every direction
	end
	if kind == "up" then
		frameUI(box, UDim2.fromScale(0.5, 0.64), UDim2.fromScale(0.16, 0.62), color)
		head(UDim2.fromScale(0.5, 0.3), 0)
	else
		local sx = if kind == "right" then 1 else -1
		frameUI(box, UDim2.fromScale(0.5 - sx * 0.22, 0.68), UDim2.fromScale(0.16, 0.5), color) -- stem
		frameUI(box, UDim2.fromScale(0.5 - sx * 0.02, 0.43), UDim2.fromScale(0.56, 0.16), color) -- bar
		head(UDim2.fromScale(0.5 + sx * 0.24, 0.43), sx * 90)
	end
	return box
end

function M.undo()
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("DalaBridge")
	if f then f:Destroy() end
end

function M.build()
	M.undo()
	local Y1 = workspace.Yangon1to1
	local roadRay, terrRay = RaycastParams.new(), RaycastParams.new()
	roadRay.FilterType, roadRay.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { Y1.Roads.Collide }
	terrRay.FilterType, terrRay.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { workspace.Terrain }
	local function roadY(p, fallback)
		local h = workspace:Raycast(Vector3.new(p.X, 600, p.Z), Vector3.new(0, -700, 0), roadRay)
		return h and h.Position.Y or fallback
	end
	local function groundY(p)
		local h = workspace:Raycast(Vector3.new(p.X, 1000, p.Z), Vector3.new(0, -1100, 0), terrRay)
		return h and h.Position.Y or WATER_Y
	end

	-- the main line and its profile (metres over the water as a function of the distance a from mid span)
	local main = newLine((function() local t = {} for i, ll in MAIN do t[i] = W(ll) end return t end)())
	local sMid, sJ = project(main, W(MID)), project(main, W(JUNCTION))
	local HALF, SAG = MAIN_LEN / 2, 60
	local H_MAIN_END = CREST - GRADE * HALF / 2 -- the crest curve spans the main bridge: level at mid span, 6% at its ends
	local function profile(a, hEnd, aEnd)
		if a >= aEnd then return hEnd end
		if a > aEnd - SAG then return hEnd + GRADE * (aEnd - a) ^ 2 / (2 * SAG) end
		if a > HALF then return H_MAIN_END - GRADE * (a - HALF) end
		return CREST - GRADE * a * a / (2 * HALF)
	end
	local function endOf(hEnd) return HALF + (H_MAIN_END - hEnd) / GRADE + SAG / 2 end
	-- Yangon end: where the 6% grade comes down onto the existing road (its built height read by ray)
	local hN = (40.2 - WATER_Y) / S
	for _ = 1, 3 do
		hN = (roadY(sample(main, sMid - endOf(hN) * S), 40.2) - WATER_Y) / S
	end
	local aN = endOf(hN)
	local hS = 4.5 -- Dala end at grade: no ground in the place there, so a level road 4.5 m over the river (the bank is 3.3)
	local aS = endOf(hS)
	main.y = function(s)
		local a = (s - sMid) / S
		return WATER_Y + S * (if a < 0 then profile(-a, hN, aN) else profile(a, hS, aS))
	end
	local sStart, sEnd = sMid - aN * S, main.len
	local sMainN, sMainS = sMid - HALF * S, sMid + HALF * S
	local PYLON_S = { sMid - (MAIN_SPAN / 2) * S, sMid + (MAIN_SPAN / 2) * S }
	local sApprS = sMainS + APPROACH_DALA * S
	local sPlaza = sMid + PLAZA * S
	local PLAZA_HALF = 45 * S
	main.sec = function(s) return if s < sJ then SEC.leg else SEC.main end
	main.name = "main"

	-- ramps: far end -> junction; they end beside the centreline so their lane runs into the outer lane
	local function ramp(name, lls, skip, side, farFallback)
		local pts = {}
		for _, ll in lls do table.insert(pts, W(ll)) end
		local jf = select(1, frame(main, sJ))
		local flat = CFrame.lookAt(Vector3.new(jf.X, 0, jf.Z), Vector3.new(jf.X, 0, jf.Z) + Vector3.new(jf.LookVector.X, 0, jf.LookVector.Z))
		table.insert(pts, (flat * CFrame.new(side * 7 * S, 0, 25 * S)).Position)
		table.insert(pts, (flat * CFrame.new(side * 5 * S, 0, 0)).Position)
		local raw = newLine(pts)
		if skip > 0 then
			local t = {}
			for s = skip * S, raw.len, 30 do table.insert(t, (sample(raw, s))) end
			table.insert(t, raw.p[#raw.p])
			raw = newLine(t)
		end
		local L = raw
		local y0 = roadY(L.p[1], farFallback)
		local yJ = main.y(sJ)
		local sag = 30 * S
		local g = (yJ - y0) / (L.len - sag / 2)
		L.y = function(s) return if s < sag then y0 + g * s * s / (2 * sag) else y0 + g * (s - sag / 2) end
		L.sec = function() return SEC.ramp end
		L.name, L.grade = name, g
		return L
	end
	local west = ramp("west", WEST, WEST_SKIP, 1, 25.8)
	local east = ramp("east", EAST, 0, -1, 24.3)

	-- segments: longer on straights, shorter where the line turns or the slope changes
	local function segments(L, s0, s1, base, breaks)
		local segs, s = {}, s0
		table.sort(breaks)
		while s < s1 - 0.5 do
			local len = base
			if L == main and math.abs(s - sJ) < 90 * S and s < sJ then len = 10 * S end
			if L ~= main and s > L.len - 90 * S then len = 10 * S end
			local _, sl0, h0 = frame(L, s)
			while len > 12 * S do
				local _, sl1, h1 = frame(L, math.min(s + len, s1))
				local dh = math.abs((h1 - h0 + math.pi) % (2 * math.pi) - math.pi)
				if dh < 0.06 and math.abs(sl1 - sl0) < 0.012 then break end
				len /= 2
			end
			local e = math.min(s + len, s1)
			for _, b in breaks do if b > s + 1 and b < e - 1 then e = b break end end
			if s1 - e < 6 then e = s1 end
			local fa, _, ha = frame(L, s)
			local fb, _, hb = frame(L, e)
			local sec = L.sec((s + e) / 2)
			local turn = math.abs((hb - ha + math.pi) % (2 * math.pi) - math.pi)
			table.insert(segs, { L = L, a = s, b = e, sec = sec, cf = CFrame.lookAt((fa.Position + fb.Position) / 2, fb.Position),
				len = (fb.Position - fa.Position).Magnitude + math.min(sec.tot * S * turn, 6) })
			s = e
		end
		return segs
	end
	local all = {
		main = segments(main, sStart, sEnd, 60 * S, { sJ, sMainN, sMainS, sApprS, sPlaza - PLAZA_HALF, sPlaza + PLAZA_HALF }),
		west = segments(west, 0, west.len, 30 * S, {}),
		east = segments(east, 0, east.len, 30 * S, {}),
	}
	-- a piece standing in another line's carriageway (where the ramps merge) is left out
	local function blocked(L, cf, x, len)
		for name, segs in all do
			if name ~= L.name then
				for _, g in segs do
					if (g.cf.Position - cf.Position).Magnitude < 400 then
						for _, z in { -len / 2, 0, len / 2 } do
							local q = g.cf:PointToObjectSpace((cf * CFrame.new(x, 0, z)).Position)
							if math.abs(q.X) < g.sec.cw * S - 1.5 and math.abs(q.Z) < g.len / 2 and math.abs(q.Y) < 8 then return true end
						end
					end
				end
			end
		end
		return false
	end

	local root = Instance.new("Folder")
	root.Name = "DalaBridge"
	root:SetAttribute("From", FROM)
	root.Parent = Y1.Landmarks
	local function group(name) local f = Instance.new("Folder") f.Name = name return f end
	local function flush(f) f.Parent = root task.wait() end

	-- ---- decks ----
	local BAR_W, BAR_H = 0.45 * S, 3.3 -- concrete barrier 0.9 m + its steel rail
	-- cable-stayed part's edge (27 Nov, night clip): kerb 0.5 m, rails at 0.65 / 0.95 m, posts every 4 m, railing posts every 3 m
	local KERB_H, RAIL_H = 0.5 * S, { 0.65 * S, 0.95 * S }
	local RAIL_TOP, GPOST, RPOST = 0.95 * S + 0.225, 4 * S, 3 * S
	for name, segs in all do
		local deck, col = group("Deck_" .. name), group("Collide_" .. name)
		for gi, g in segs do
			local L, sec, cf, len = g.L, g.sec, g.cf, g.len
			local alt = (gi % 2) * 0.07 -- every second piece 0.07 up / in, so overlapping ends at a bend never share a plane
			local cw, tot = sec.cw * S, sec.tot * S
			local mid = (g.a + g.b) / 2
			local isMain = sec == SEC.main
			local inPlaza = L == main and math.abs(mid - sPlaza) < PLAZA_HALF
			rcol(col, if L == main and mid > sApprS then "R" else "D", Vector3.new(2 * cw, 2, len), cf * CFrame.new(0, -1, 0))
			part(deck, "Asphalt", Vector3.new(2 * cw, 0.3, len), cf * CFrame.new(0, -0.15, 0), C.deck, Enum.Material.Asphalt)
			-- structure: steel box under the cable-stayed part, concrete girders on the approaches, fill at grade
			local onMain = L == main and mid > sMainN and mid < sMainS
			local depth = if onMain then BOX_DEPTH * S elseif L == main and mid > sApprS then cf.Y - WATER_Y + 2 elseif L == main then 7 else 5.4
			g.depth = depth
			part(deck, "Girder", Vector3.new(2 * tot - (if onMain then 0 else 1.5), depth, len), cf * CFrame.new(0, -0.3 - depth / 2, 0), if onMain then C.steel else C.concrete)
			if not inPlaza then
				for _, sx in { -1, 1 } do
					local x = sx * (cw + BAR_W / 2)
					if not blocked(L, cf, sx * (cw + 1.6), len) then
						if onMain then
							-- the cable-stayed part (night clip p2 1:19 / 1:31, p1 0:21): a low kerb with a 2-rail steel guard rail
							part(deck, "Kerb", Vector3.new(BAR_W, KERB_H + 0.3, len), cf * CFrame.new(x - sx * alt, KERB_H / 2 - 0.15 + alt, 0), C.concrete)
							local px = x - sx * alt -- posts stand on the kerb's middle, rails on their road side
							for _, h in RAIL_H do
								part(deck, "GuardRail", Vector3.new(0.3, 0.45, len), cf * CFrame.new(px - sx * (0.15 + 0.15 - 0.02), h + alt, 0), C.silver, Enum.Material.Metal)
							end
							for z = -len / 2 + GPOST / 2, len / 2 - 0.5, GPOST do
								part(deck, "GuardPost", Vector3.new(0.3, RAIL_TOP - KERB_H + 0.04, 0.3), cf * CFrame.new(px, (KERB_H + RAIL_TOP) / 2 - 0.08 + alt, z), C.silver, Enum.Material.Metal)
							end
						else
							part(deck, "Barrier", Vector3.new(BAR_W, BAR_H + 0.3, len), cf * CFrame.new(x, BAR_H / 2 - 0.15, 0), C.concrete)
						end
						rcol(col, "W", Vector3.new(BAR_W, 6.1, len), cf * CFrame.new(x, 2.75, 0))
					end
					if isMain then
						local wx, ww = sx * (cw + BAR_W + (tot - cw - BAR_W) / 2), tot - cw - BAR_W
						-- 0.16 narrower on the outside: its outer face no longer lies in the box's side face or the railing posts' face
						part(deck, if onMain then "AnchorStrip" else "Walk", Vector3.new(ww - 0.16, 0.9, len), cf * CFrame.new(wx - sx * (0.08 + (if onMain then alt else 0)), 0.15 + alt, 0), C.concrete)
						rcol(col, "P", Vector3.new(ww, 2, len), cf * CFrame.new(wx, -0.4, 0))
						local rx = sx * (tot - 0.3 - alt)
						if onMain then
							-- outer railing, white vertical bars (p2 1:23 / 1:31): rails + posts + a see-through bar infill
							part(deck, "RailTop", Vector3.new(0.28, 0.3, len), cf * CFrame.new(rx, 0.6 + 3.6 + alt, 0), C.railWhite, Enum.Material.Metal)
							part(deck, "RailFoot", Vector3.new(0.28, 0.3, len), cf * CFrame.new(rx, 0.6 + 0.45 + alt, 0), C.railWhite, Enum.Material.Metal)
							local infill = part(deck, "RailBars", Vector3.new(0.12, 2.85, len), cf * CFrame.new(rx, 0.6 + 0.6 + 1.425 + 0.02 + alt, 0), C.railWhite, Enum.Material.Metal)
							infill.Transparency = 1 -- the bars are a tiled texture on both faces (2 bars per 0.25 m)
							for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
								local t = Instance.new("Texture")
								t.Texture, t.Face, t.StudsPerTileU, t.StudsPerTileV = BARS_TEX, face, 0.75, 2.85
								t.Parent = infill
							end
							for z = -len / 2 + RPOST / 2, len / 2 - 0.5, RPOST do
								part(deck, "RailPost", Vector3.new(0.4, 4.0, 0.4), cf * CFrame.new(rx, 0.6 + 2.0 - 0.05, z), C.railWhite, Enum.Material.Metal)
							end
						else
							-- approaches: a tall frosted screen on the parapet (p2 0:31, p1 0:59-1:11)
							local r = part(deck, "Screen", Vector3.new(0.3, 7.2, len), cf * CFrame.new(rx, 0.6 + 3.6 + 0.08 + alt, 0), C.screen, Enum.Material.Glass)
							r.Transparency = 0.45
						end
					end
				end
				if isMain then -- the median barrier (IMG_0808 172 s: a bus on the other carriageway behind it)
					part(deck, "Median", Vector3.new(0.6 * S, BAR_H - 0.3, len), cf * CFrame.new(0, BAR_H / 2 - 0.15, 0), C.concrete)
					rcol(col, "W", Vector3.new(0.6 * S, 6.1, len), cf * CFrame.new(0, 2.75, 0))
				end
			end
		end
		flush(deck)
		flush(col)
	end

	-- ---- paint: 0.04 thick, 0.08 over the asphalt (flicker rule). Yangon line rule 21 Nov: double yellow between
	-- opposing traffic (the two-lane leg), yellow edge lines where the videos show them, white lane dashes ----
	local paint = group("Lines")
	local LW = 0.15 * S
	local function line(L, cf, x, len, color)
		if blocked(L, cf, x, len) then return end
		part(paint, "Line", Vector3.new(LW, 0.04, len), cf * CFrame.new(x, 0.1, 0), color).CastShadow = false
	end
	for name, segs in all do
		for _, g in segs do
			local mid = (g.a + g.b) / 2
			if g.L == main and math.abs(mid - sPlaza) < PLAZA_HALF then continue end
			if g.sec == SEC.leg then
				line(g.L, g.cf, -LW, g.len, C.yellow)
				line(g.L, g.cf, LW, g.len, C.yellow)
			elseif g.sec == SEC.main then
				line(g.L, g.cf, -(g.sec.cw - 1.0) * S, g.len, C.yellow)
				line(g.L, g.cf, (g.sec.cw - 1.0) * S, g.len, C.yellow)
			else
				local ys = if name == "west" then -1 else 1
				line(g.L, g.cf, ys * (g.sec.cw - 0.5) * S, g.len, C.yellow)
				line(g.L, g.cf, -ys * (g.sec.cw - 0.5) * S, g.len, C.white) -- the ramp's white right edge (night clip p2 0:05)
			end
		end
	end
	for s = sJ + 6 * S, sEnd - 3 * S, 12 * S do -- 3 m dash, 9 m gap
		if math.abs(s - sPlaza) > PLAZA_HALF then
			local cf = frame(main, s)
			for _, x in { -4.3 * S, 4.3 * S } do
				part(paint, "Dash", Vector3.new(LW, 0.04, 3 * S), cf * CFrame.new(x, 0.1, 0), C.white).CastShadow = false
			end
		end
	end
	flush(paint)

	-- ---- pylons: A-frame over the deck with a slotted head, legs closing in to one pile cap under it (diamond),
	-- shape from IMG_0808 46 / 52 / 138 s; sizes measured against the 26.5 m deck ----
	local pylons, cables = group("Pylons"), group("Cables")
	local LEG_X = 11.3 -- leg centre at deck level: the legs stand in the walkway zone, railing outside them
	for pi, dir in { -1, 1 } do
		local sp = sMid + dir * (MAIN_SPAN / 2) * S
		local f = frame(main, sp)
		local deckH = (f.Y - WATER_Y) / S
		local base = CFrame.lookAt(Vector3.new(f.X, WATER_Y, f.Z), Vector3.new(f.X, WATER_Y, f.Z) + Vector3.new(f.LookVector.X, 0, f.LookVector.Z))
		local function P(x, h, z) return (base * CFrame.new(x * S, h * S, (z or 0) * S)).Position end
		local top, headBase = deckH + PYLON_ABOVE_DECK, deckH + 55
		local pf = group("Pylon" .. pi)
		pf.Parent = pylons
		local up = base.LookVector
		for _, sx in { -1, 1 } do
			local a, b = P(sx * LEG_X, deckH - 5), P(sx * 2.6, headBase + 1)
			glow(part(pf, "Leg", Vector3.new(2.6 * S, 5 * S, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b, up), C.pylon), C.pylonNight)
			a, b = P(sx * 1.4, 3), P(sx * LEG_X, deckH - 4) -- closing in to ONE footing at the water (night clip p2 0:47 / 0:51)
			glow(part(pf, "LowerLeg", Vector3.new(2.6 * S - 0.3, 5 * S - 0.3, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b, up), C.pylon), C.pylonNight)
			glow(part(pf, "Head", Vector3.new(2.2 * S, (top - headBase) * S, 5 * S), CFrame.new(P(sx * 2.6, (top + headBase) / 2)) * base.Rotation, C.pylon), C.pylonNight)
			-- the violet wash on the inner face of each leg only (night clip p2 0:43 / 0:47: warm white pylon, lilac inside the legs)
			a, b = P(sx * (LEG_X - 1.45), deckH + 2), P(sx * 1.15, headBase - 3)
			neon(pf, "Wash", Vector3.new(0.3, 2 * S, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b, up), C.violet)
		end
		glow(part(pf, "HeadBeam", Vector3.new(7.4 * S, 3 * S, 5.2 * S), CFrame.new(P(0, headBase)) * base.Rotation, C.pylon), C.pylonNight)
		glow(part(pf, "Cap", Vector3.new(7.4 * S, 2 * S, 5.2 * S), CFrame.new(P(0, top - 1)) * base.Rotation, C.pylon), C.pylonNight)
		glow(part(pf, "CrossBeam", Vector3.new((2 * LEG_X + 2.6) * S, 3 * S, 5.2 * S), CFrame.new(P(0, deckH - BOX_DEPTH - 2.2)) * base.Rotation, C.pylon), C.pylonNight)
		part(pf, "PileCap", Vector3.new(9 * S, 7 * S, 12 * S), CFrame.new(P(0, 1.5)) * base.Rotation, C.concrete) -- one narrow footing
		-- the lit window at the top of the slot, under the cap (night clip p1 0:21, p2 0:43); 0.1 m clear of the shafts and cap
		neon(pf, "TopLight", Vector3.new(2.8 * S, 2 * S, 1 * S), CFrame.new(P(0, top - 3.1)) * base.Rotation, C.lamp)
		-- a bronze plaque on the inner face of each leg at deck level and a 50 km/h sign before each leg (night clip p2 1:29-1:31)
		for _, leg in pf:GetChildren() do
			if leg.Name == "Leg" then
				local zA = leg.Size.Z / 2 -- the leg's deck end (LookVector = local -Z runs up the leg)
				local fz = zA - (5 + 1.6) * S / math.abs(leg.CFrame.LookVector.Y)
				local best
				for _, nx in { -1, 1 } do
					local q = leg.CFrame * CFrame.new(nx * (leg.Size.X / 2 + 0.15), 0, fz)
					local lat = math.abs(base:PointToObjectSpace(q.Position).X)
					if not best or lat < best.lat then best = { lat = lat, cf = q, nx = nx } end
				end
				local pl = part(pf, "Plaque", Vector3.new(0.2, 0.5 * S, 0.7 * S), best.cf, C.bronze, Enum.Material.Metal)
				local g = gui(pl, if best.nx > 0 then Enum.NormalId.Right else Enum.NormalId.Left, 30)
				local rim = frameUI(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.86, 0.82), Color3.fromRGB(150, 118, 76))
				frameUI(rim, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.88), C.bronze)
			end
		end
		for _, sx in { -1, 1 } do -- traffic keeps right: +s traffic on +x sees the sign before the pylon, -s traffic on -x
			local ss = sp - sx * 7 * S
			local sf = frame(main, ss)
			local flat = CFrame.lookAt(sf.Position, sf.Position + Vector3.new(sf.LookVector.X, 0, sf.LookVector.Z))
			local x = sx * (SEC.main.cw + 0.45 + 0.35) * S
			local foot = (flat * CFrame.new(x, 0.6, 0)).Position
			local facing = -sx * Vector3.new(sf.LookVector.X, 0, sf.LookVector.Z).Unit
			local segH = 0.44 * S
			for k = 0, 4 do -- red / white striped post, 2.2 m
				local c = (k % 2 == 0) and C.red or C.white
				part(pf, "SignPost", Vector3.new(segH, 0.24, 0.24), CFrame.new(foot + Vector3.new(0, (k + 0.5) * segH, 0)) * CFrame.Angles(0, 0, math.pi / 2), c, nil, Enum.PartType.Cylinder)
			end
			local disc = part(pf, "SpeedSign", Vector3.new(0.12, 0.7 * S, 0.7 * S), CFrame.fromMatrix(foot + Vector3.new(0, 2.2 * S + 0.35 * S, 0) + facing * 0.2, facing, Vector3.yAxis), C.white, nil, Enum.PartType.Cylinder)
			local g = gui(disc, Enum.NormalId.Right, 60)
			local ring = frameUI(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), C.red, 1)
			local inner = frameUI(ring, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.76, 0.76), Color3.fromRGB(248, 248, 244), 1)
			textUI(inner, UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.78, 0.5), "50", Color3.fromRGB(20, 20, 20))
			textUI(inner, UDim2.fromScale(0.5, 0.76), UDim2.fromScale(0.5, 0.18), "km/h", Color3.fromRGB(20, 20, 20), Enum.Font.Gotham)
		end
		neon(pf, "UnderLight", Vector3.new(18 * S, 0.3, 3 * S), CFrame.new(P(0, deckH - BOX_DEPTH - 3.9)) * base.Rotation, C.lamp)
		-- stays: two planes, semi-fan, anchored in the head and outside the barrier on the deck
		for _, side in { -1, 1 } do
			local toMid = side == -dir
			for i = 0, CABLES - 1 do
				local d = if toMid then 17 + 12.5 * i else 14 + 10.8 * i
				local df = frame(main, sp + side * d * S)
				local hTop = headBase + 3 + i * (PYLON_ABOVE_DECK - 55 - 5) / (CABLES - 1)
				for _, sx in { -1, 1 } do
					local a = (df * CFrame.new(sx * 10.6 * S, 0.6, 0)).Position -- on the anchor strip
					local b = P(sx * 2.6, hTop, side * 1.5)
					local u = (b - a).Unit
					glow(rod(cables, "Stay", a + u * 1.4 * S, b, 0.9, C.cable), C.cableNight)
					-- the cream bell anchor cap (night clip p2 1:19 / 1:23, p1 0:21): wide bell on the strip, body up the cable
					glow(rod(cables, "CapBell", a - u * 0.25 * S, a + u * 0.45 * S, 0.85 * S, C.capCream), C.cableNight)
					glow(rod(cables, "CapBody", a + u * 0.4 * S, a + u * 1.6 * S, 0.55 * S, C.capCream), C.cableNight)
					local road = -sx * df.RightVector
					road = (road - u * road:Dot(u)).Unit -- across the body, toward the road
					local rp = a + u * 1.15 * S + road * (0.275 * S + 0.04)
					part(cables, "Reflector", Vector3.new(0.08, 0.36, 0.36), CFrame.fromMatrix(rp, road, u), C.reflector, nil, Enum.PartType.Cylinder)
					local flat = Vector3.new(df.LookVector.X, 0, df.LookVector.Z).Unit
					neon(cables, "Uplight", Vector3.new(0.35 * S, 0.12 * S, 0.25 * S), CFrame.lookAt(a, a + flat) * CFrame.new(-sx * 0.7 * S, 0.06 * S + 0.02, 0), C.lamp)
				end
			end
		end
	end
	flush(pylons)
	flush(cables)

	-- ---- piers ----
	local piers = group("Piers")
	local function pier(L, s, colX, colZ, capH)
		local f = frame(L, s)
		local g
		for _, q in all[L.name] do if s >= q.a - 1 and s <= q.b + 1 then g = q break end end
		local topY = f.Y - 0.3 - (g and g.depth or 7)
		local gy = groundY(f.Position)
		if topY - capH - gy < 12 then return end
		local flat = CFrame.lookAt(Vector3.new(f.X, 0, f.Z), Vector3.new(f.X, 0, f.Z) + Vector3.new(f.LookVector.X, 0, f.LookVector.Z))
		part(piers, "PierCap", Vector3.new(2 * L.sec(s).tot * S - 4, capH, colZ + 3), flat * CFrame.new(0, topY - capH / 2, 0), C.concrete)
		local h = topY - capH - gy + 6
		part(piers, "Pier", Vector3.new(colX, h, colZ), flat * CFrame.new(0, topY - capH - h / 2, 0), C.concrete)
	end
	for s = sMainN, sStart, -APPROACH_SPAN * S do pier(main, s, if s < sJ then 9 else 18, 7.5, 6) end
	for s = sMainS, sApprS, APPROACH_SPAN * S do pier(main, s, 18, 7.5, 6) end
	for _, L in { west, east } do
		for s = L.len - 40 * S, 20 * S, -30 * S do pier(L, s, 6, 6, 5) end -- single flared columns (IMG_0807): spacing not sourced
	end
	flush(piers)

	-- ---- lamps: white (the game's Yangon lamp colours), on the outer barriers; a SpotLight on every fourth ----
	local lamps = group("Lamps")
	local nLamp = 0
	local function lamp(L, s, sx)
		local f = frame(L, s)
		local x = sx * (L.sec(s).cw * S + BAR_W / 2)
		if blocked(L, f, x + sx * 1.6, 90) then return end -- the barrier's own test: no lamp where the barrier is left out
		-- on the cable-stayed part the poles stand on the anchor strip with an arm over the road (night clip p2 1:31, p1 0:37)
		local strip = L == main and s > sMainN and s < sMainS
		if strip then
			for _, sp in PYLON_S do if math.abs(s - sp) < 6 * S then return end end
			x = sx * 12.2 * S
		end
		local y0 = if strip then 0.6 else BAR_H
		local flat = CFrame.lookAt(f.Position, f.Position + Vector3.new(f.LookVector.X, 0, f.LookVector.Z)) * CFrame.new(x, 0, 0)
		rod(lamps, "Pole", (flat * CFrame.new(0, y0 - 0.1, 0)).Position, (flat * CFrame.new(0, y0 + 30, 0)).Position, 0.75, C.rail)
		local hx = -sx * 2.2
		if strip then
			hx = -sx * 5.0 -- head ends 9.8 m out: clear of the stays (about 9.3 m out at that height)
			rod(lamps, "Arm", (flat * CFrame.new(0, y0 + 29.6, 0)).Position, (flat * CFrame.new(hx * 0.8, y0 + 30.4, 0)).Position, 0.35, C.rail)
		end
		local head = part(lamps, "Head", Vector3.new(4.5, 0.5, 1.5), flat * CFrame.new(hx, y0 + 30.2, 0), C.lamp)
		head:AddTag("LampGlow")
		nLamp += 1
		if nLamp % 4 == 0 then
			local l = Instance.new("SpotLight")
			l.Face, l.Angle, l.Range, l.Brightness, l.Color = Enum.NormalId.Bottom, 120, 60, 7, Color3.fromRGB(232, 240, 255)
			l.Shadows, l.Enabled = false, false
			l:AddTag("LODLight")
			l:AddTag("DayOff")
			l.Parent = head
		end
	end
	for s = sStart + 10 * S, sEnd - 5 * S, LAMP_GAP * S do
		if math.abs(s - sPlaza) > PLAZA_HALF then
			lamp(main, s, -1)
			if s > sJ then lamp(main, s, 1) end
		end
	end
	for s = 15 * S, west.len - 20 * S, LAMP_GAP * S do lamp(west, s, 1) end
	for s = 15 * S, east.len - 20 * S, LAMP_GAP * S do lamp(east, s, -1) end
	flush(lamps)

	-- ---- toll plaza (Dala side, at grade): canopy with the lit name sign, booth islands (IMG_0808 215-231 s) ----
	local toll = group("Toll")
	local tf = frame(main, sPlaza)
	local T = CFrame.lookAt(tf.Position, tf.Position + Vector3.new(tf.LookVector.X, 0, tf.LookVector.Z))
	part(toll, "Apron", Vector3.new(144, tf.Y - WATER_Y + 2, 2 * PLAZA_HALF), T * CFrame.new(0, -0.1 - (tf.Y - WATER_Y + 2) / 2, 0), C.deck, Enum.Material.Asphalt)
	rcol(toll, "R", Vector3.new(144, 2, 2 * PLAZA_HALF), T * CFrame.new(0, -1.1, 0))
	part(toll, "Canopy", Vector3.new(132, 3, 42), T * CFrame.new(0, 19.5, 0), Color3.fromRGB(232, 232, 228))
	local brown = Color3.fromRGB(88, 70, 60)
	for i = -3, 3 do
		local x = i * 16
		part(toll, "Island", Vector3.new(6, 1, 36), T * CFrame.new(x, 0.5, 0), Color3.fromRGB(214, 180, 40))
		rcol(toll, "W", Vector3.new(6, 6, 36), T * CFrame.new(x, 3, 0))
		part(toll, "Booth", Vector3.new(5, 8, 9), T * CFrame.new(x, 5, 4), Color3.fromRGB(236, 236, 232))
		part(toll, "Column", Vector3.new(3, 17, 3), T * CFrame.new(x, 9.5, -8), brown)
	end
	-- (27 Nov, night clip p1 1:33-1:55) local z < 0 = the Dala (+s) side; +s traffic arrives from local +z on the x > 0 lanes
	for i = -4, 3 do -- a white ceiling full of round down-lights
		for _, z in { -15, -5, 5, 15 } do
			neon(toll, "Downlight", Vector3.new(0.15, 1.6, 1.6), T * CFrame.new(i * 16 + 8, 18 - 0.085, z) * CFrame.Angles(0, 0, math.pi / 2), C.lamp).Shape = Enum.PartType.Cylinder
		end
	end
	local yellow = Color3.fromRGB(226, 186, 34)
	for i = -3, 3 do
		local x = i * 16
		-- yellow frame round each glass booth (sill rail + corner posts) and red water-filled barriers at the island noses
		part(toll, "BoothRail", Vector3.new(5.3, 0.35, 9.3), T * CFrame.new(x, 4.6, 4), yellow, Enum.Material.Metal)
		for _, cx in { -1, 1 } do
			for _, cz in { -1, 1 } do
				part(toll, "BoothPost", Vector3.new(0.42, 8.1, 0.42), T * CFrame.new(x + cx * 2.55, 5.03, 4 + cz * 4.55), yellow, Enum.Material.Metal)
			end
		end
		for _, z in { -19.6, 19.6 } do
			part(toll, "WaterBarrier", Vector3.new(4, 2.4, 1.5), T * CFrame.new(x, 1.1, z), C.red, Enum.Material.Plastic)
		end
	end
	for i = -3, 2 do -- lane lights on both canopy edges: green arrow for the lanes of that direction, red X for the others
		local x = i * 16 + 8
		for _, z in { -20.5, 20.5 } do
			local open = (z > 0) == (x > 0)
			local box = part(toll, "LaneLight", Vector3.new(1.6, 1.6, 0.6), T * CFrame.new(x, 16.6, z), Color3.fromRGB(24, 24, 26))
			local g = gui(box, if z < 0 then Enum.NormalId.Front else Enum.NormalId.Back, 60, 0)
			if open then
				arrowUI(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8), "up", Color3.fromRGB(70, 230, 120)).Rotation = 180
			else
				textUI(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8), "X", Color3.fromRGB(240, 50, 40))
			end
		end
	end
	for _, side in { 1, -1 } do -- yellow / black rumble band across one direction's lanes, 20 m before the canopy
		for k = 0, 23 do
			local x = side * (0.5 + 1.5 + k * 3)
			part(toll, "Rumble", Vector3.new(3 - 0.02, 0.04, 4.5), T * CFrame.new(x, 0.1, side * 60), if k % 2 == 0 then yellow else Color3.fromRGB(26, 26, 26)).CastShadow = false
		end
	end
	for _, z in { -21.5, 21.5 } do -- the name board on the canopy edge, read from both approaches
		local sign = glow(part(toll, "Sign", Vector3.new(66, 6, 0.6), T * CFrame.new(0, 24, z), Color3.fromRGB(240, 236, 220)), Color3.fromRGB(196, 182, 156))
		local sg = Instance.new("SurfaceGui")
		sg.Face = if z < 0 then Enum.NormalId.Front else Enum.NormalId.Back
		sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = Enum.SurfaceGuiSizingMode.PixelsPerStud, 20, 0
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency, t.TextScaled = UDim2.fromScale(1, 1), 1, true
		t.Text, t.TextColor3, t.Font = "မြန်မာ-ကိုရီးယား ချစ်ကြည်ရေး(ဒလ)တံတား", Color3.fromRGB(96, 70, 20), Enum.Font.SourceSansBold
		t.Parent = sg
		sg.Parent = sign
	end
	flush(toll)

	-- ---- Dala end: overhead sign gantry, height limit and hump sign for Dala-bound traffic (night clip p1 1:31) ----
	local dala = group("DalaEnd")
	local sG = sPlaza - PLAZA_HALF - 50 * S
	local gfr = frame(main, sG)
	local G = CFrame.lookAt(gfr.Position, gfr.Position + Vector3.new(gfr.LookVector.X, 0, gfr.LookVector.Z))
	local grey = Color3.fromRGB(150, 152, 154)
	local PX = (SEC.main.cw + 0.45 + 2.0) * S
	for _, sx in { -1, 1 } do
		part(dala, "GantryPost", Vector3.new(0.45 * S, 8.2 * S, 0.45 * S), G * CFrame.new(sx * PX, 0.6 - 0.1 + 4.1 * S, 0), grey, Enum.Material.Metal)
	end
	for _, h in { 7.25, 8.05 } do
		part(dala, "GantryChord", Vector3.new(2 * PX - 0.45 * S - 0.04, 0.25 * S, 0.25 * S), G * CFrame.new(0, 0.6 + h * S, 0), grey, Enum.Material.Metal)
	end
	for k = 0, 7 do -- zigzag web between the chords
		local x0 = -PX + 0.6 * S + k * (2 * PX - 1.2 * S) / 8
		local x1 = x0 + (2 * PX - 1.2 * S) / 8
		local a = (G * CFrame.new(x0, 0.6 + (if k % 2 == 0 then 7.25 + 0.12 else 8.05 - 0.12) * S, 0)).Position
		local b = (G * CFrame.new(x1, 0.6 + (if k % 2 == 0 then 8.05 - 0.12 else 7.25 + 0.12) * S, 0)).Position
		local tw = (if k % 2 == 0 then 0.13 else 0.09) * S
		beam(dala, "GantryWeb", a, b, tw, tw, grey).Material = Enum.Material.Metal
	end
	local signs = {
		{ x = 1.6, my = "ဒလမြို့နယ်", en = "Dala Township", arrow = "left" },
		{ x = 4.5, my = nil, en = "Sat Ein Tann Beach", arrow = "up" }, -- Burmese line unreadable in the clip: check with sharper frames
		{ x = 7.4, my = "တွံတေးမြို့နယ်", en = "Twante Township", arrow = "right" },
	}
	for _, sd in signs do
		local p = part(dala, "DirectionSign", Vector3.new(2.6 * S, 2.2 * S, 0.12), G * CFrame.new(sd.x * S, 0.6 + 6.75 * S, 0.125 * S + 0.12), C.signGreen)
		local g = gui(p, Enum.NormalId.Back, 24, 0.5)
		local border = frameUI(g, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.95, 0.93), Color3.fromRGB(236, 240, 236))
		local fill = frameUI(border, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.96, 0.95), C.signGreen)
		if sd.my then
			textUI(fill, UDim2.fromScale(0.5, 0.17), UDim2.fromScale(0.8, 0.2), sd.my, Color3.new(1, 1, 1), Enum.Font.SourceSansBold)
			textUI(fill, UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.86, 0.17), sd.en, Color3.new(1, 1, 1), Enum.Font.GothamBold)
		else
			textUI(fill, UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.9, 0.2), sd.en, Color3.new(1, 1, 1), Enum.Font.GothamBold)
		end
		arrowUI(fill, UDim2.fromScale(0.5, 0.73), UDim2.fromScale(0.42, 0.44), sd.arrow, Color3.new(1, 1, 1))
	end
	-- 5.5 m height limit on the gantry's right end
	local hl = part(dala, "HeightSign", Vector3.new(0.12, 0.8 * S, 0.8 * S), CFrame.fromMatrix((G * CFrame.new(9.9 * S, 0.6 + 6.75 * S, 0.125 * S + 0.12)).Position, -G.LookVector, Vector3.yAxis), C.white, nil, Enum.PartType.Cylinder)
	local hg = gui(hl, Enum.NormalId.Right, 60)
	local ring = frameUI(hg, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), C.red, 1)
	local inner = frameUI(ring, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.78, 0.78), Color3.fromRGB(248, 248, 244), 1)
	textUI(inner, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.74, 0.34), "5.5 m", Color3.fromRGB(20, 20, 20))
	textUI(inner, UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.3, 0.2), "▼", Color3.fromRGB(20, 20, 20), Enum.Font.Arimo) -- Gotham has no ▲▼
	textUI(inner, UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.3, 0.2), "▲", Color3.fromRGB(20, 20, 20), Enum.Font.Arimo)
	-- hump warning: yellow diamond on a grey post, right side, 15 m past the gantry
	local hf = frame(main, sG + 15 * S)
	local H = CFrame.lookAt(hf.Position, hf.Position + Vector3.new(hf.LookVector.X, 0, hf.LookVector.Z))
	local foot = (H * CFrame.new((SEC.main.cw + 0.45 + 1.0) * S, 0.6, 0)).Position
	part(dala, "HumpPost", Vector3.new(2.6 * S, 0.24, 0.24), CFrame.new(foot + Vector3.new(0, 1.3 * S - 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2), grey, Enum.Material.Metal, Enum.PartType.Cylinder)
	local dpos = foot + Vector3.new(0, 2.6 * S + 0.35 * S, 0) - H.LookVector * 0.25
	local dia = part(dala, "HumpSign", Vector3.new(0.65 * S, 0.65 * S, 0.1), CFrame.lookAt(dpos, dpos - H.LookVector) * CFrame.Angles(0, 0, math.pi / 4), Color3.fromRGB(240, 200, 30))
	local dg = gui(dia, Enum.NormalId.Front, 60)
	local blk = frameUI(dg, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1), Color3.fromRGB(20, 20, 20))
	local yel = frameUI(blk, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.86, 0.86), Color3.fromRGB(240, 200, 30))
	local sym = frameUI(yel, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.9), Color3.new())
	sym.BackgroundTransparency, sym.Rotation = 1, -45
	frameUI(sym, UDim2.fromScale(0.5, 0.62), UDim2.fromScale(0.7, 0.07), Color3.fromRGB(20, 20, 20))
	frameUI(sym, UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.34, 0.16), Color3.fromRGB(20, 20, 20), 0.5)
	flush(dala)

	for _, d in root:GetDescendants() do
		if d:IsA("Instance") and not d:IsA("Folder") then d:SetAttribute("From", FROM) end
	end

	-- ---- self-check ----
	local n = #root:GetDescendants()
	assert(n < 5200, "too many instances: " .. n) -- 27 Nov: railing posts, caps, signs
	assert(math.abs((main.y(sMid) - WATER_Y) / S - CREST) < 0.01, "crest height")
	assert(math.abs(sMainS - sMainN - MAIN_LEN * S) < 0.01, "main bridge length")
	for name, segs in all do
		for i = 2, #segs do assert(math.abs(segs[i].a - segs[i - 1].b) < 0.01, name .. ": deck gap") end
	end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			assert(d.Anchored, "unanchored part")
			assert((d.Name == "RCol") == d.CanCollide, "collision convention: " .. d.Name)
		end
	end
	local a0, a1 = frame(main, sStart).Position, frame(main, sEnd).Position
	local w0, e0 = frame(west, 0).Position, frame(east, 0).Position
	local function v(p) return ("(%.0f, %.1f, %.0f)"):format(p.X, p.Y, p.Z) end
	return ("instances %d | Yangon end %s (existing road y %.1f) | Dala end %s | west ramp start %s (road %s) | east ramp end %s (road %s) | junction y %.1f | pylons y top %.1f, deck there %.1f | crest y %.1f | deck start station %.0f m of OSM way, main bridge %.0f-%.0f m, Dala approach to %.0f m, plaza %.0f m, end %.0f m | ramp grades west %.3f east %.3f | lamps %d")
		:format(n, v(a0), roadY(a0, -1), v(a1), v(w0), tostring(roadY(w0, nil)), v(e0), tostring(roadY(e0, nil)), main.y(sJ),
			WATER_Y + S * ((frame(main, sMid + MAIN_SPAN / 2 * S).Y - WATER_Y) / S + PYLON_ABOVE_DECK), frame(main, sMid + MAIN_SPAN / 2 * S).Y, main.y(sMid),
			sStart / S, sMainN / S, sMainS / S, sApprS / S, sPlaza / S, sEnd / S, west.grade / 1, east.grade / 1, nLamp)
end

return M
