--[[
	Yangon buildings (Studio, Edit mode). Build step 8, 13 Nov 2026.

	Puts a building on every plot of imports/refs/map/ygn_plots.json (tools/yangon/d10_plots.py; in Studio
	the module ServerStorage.YangonData.Plots returns it as JSON) using the Riviera building kit
	(tools/riviera/Buildings.luau: real window recesses, one pane per lit window tagged "Window" so WorldFx
	lights them at night, a "Detail" model tagged LOD), with a Yangon style:

	  * walk-up block: 4-8 floors, pastel paint, balconies with low walls and steel rails, AC units on the
	    front, black or blue water tanks on the roof (most of Yangon's flats);
	  * shophouse: 3-5 floors, roller shutters and a wide signboard across the first floor;
	  * condo tower: 12-20 floors, white and grey, only near the big junctions (Hledan, Myanmar Plaza);
	  * gated villa: 2-3 floors, hipped roof, a wall round the plot with a steel gate, trees (the leafy
	    streets round Inya Lake);
	  * the landmarks: Optima Werkz (the car tuning workshop where players start), Novotel Yangon Max and
	    Myanmar Plaza. Names as plain text only (no logo artwork).

	Reference study: Roblox Playbook/2026-11-13 Research - Yangon buildings (step 8).md.
	Floors are the game's scale (12-stud ground floor, 9 studs a floor: a 3 m floor for a car 3 studs a
	metre), not the map's 1.6 studs a metre, or the buildings would be doll-sized next to the cars.

	Use (Edit mode):
	  local B = require(game.ServerStorage.ClaudeTools.YangonBuildings:Clone())
	  B.spawn(function() return B.build({ limit = 30 }) end)   -- a test batch
	  B.status()
	  B.build()            -- every plot (clears workspace.Yangon.Buildings first)
]]

local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local M = {}
local K = require(SS.ClaudeTools.Buildings:Clone()).kit
local part, small, quiet, face, faces, core, pane = K.part, K.small, K.quiet, K.face, K.faces, K.core, K.pane
local R = K.R
local IRON = K.IRON

M.GF, M.FH = 12, 9 -- ground floor, each floor above (studs)
M.SETBACK = 4.5 -- d10_plots.py: the building front stands this far behind the pavement's outer edge

-- the Yangon look (research: pastel walk-ups, stained, white condos, red and green villa roofs)
M.PASTEL = {
	Color3.fromRGB(232, 218, 170), -- cream
	Color3.fromRGB(200, 222, 202), -- mint
	Color3.fromRGB(236, 196, 186), -- salmon
	Color3.fromRGB(230, 228, 218), -- off white
	Color3.fromRGB(192, 212, 226), -- pale blue
	Color3.fromRGB(236, 222, 150), -- pale yellow
	Color3.fromRGB(238, 204, 168), -- peach
	Color3.fromRGB(198, 194, 182), -- stained grey
	Color3.fromRGB(214, 200, 226), -- lilac
}
M.CONDO = {
	Color3.fromRGB(226, 226, 222),
	Color3.fromRGB(214, 216, 216),
	Color3.fromRGB(232, 226, 210),
}
M.VILLA_WALL = { Color3.fromRGB(237, 230, 214), Color3.fromRGB(226, 222, 206), Color3.fromRGB(240, 236, 226) }
M.ROOF = { Color3.fromRGB(160, 50, 40), Color3.fromRGB(60, 110, 70), Color3.fromRGB(84, 88, 96), Color3.fromRGB(150, 70, 44) }
M.SIGN = {
	{ Color3.fromRGB(200, 40, 40), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(30, 80, 170), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(240, 200, 40), Color3.fromRGB(40, 30, 20) },
	{ Color3.fromRGB(30, 130, 70), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(250, 250, 246), Color3.fromRGB(190, 30, 30) },
	{ Color3.fromRGB(230, 110, 30), Color3.fromRGB(255, 255, 255) },
}
-- made-up Yangon shop names (no real brands)
M.SHOPS = {
	"Shwe Pyi Mobile", "Golden Lotus Tea Shop", "Mingalar Mart", "Yadanar Gold", "Aung Thit Pharmacy",
	"Nay Pyi Bakery", "Thiri Beauty Salon", "Kyaw Kyaw Electronics", "Royal Burma Cafe", "Sein Lan Noodle House",
	"Moe Kaung Motors", "Htet Htet Fashion", "Inya Car Wash", "Lucky Seven Tea House", "Myat Noe Clinic",
	"Kamayut Book Store", "Bahan Hardware", "Pearl Dental", "Zaw Zaw Tyres", "Hledan Phone Centre",
	"Su Myat Mohinga", "Lake View Restaurant", "Thu Kha Auto Parts", "Ever Green Furniture", "Silver Moon Karaoke",
	"Shwe Taung Optical", "Myanmar Shan Noodle", "Phoe Wa Printing", "Nilar Tailor", "Win Win Money Exchange",
	"Rainbow Ice Cream", "Mandalay Dumplings", "Ko Ko Gyi BBQ", "Thandar Flowers", "Pyay Road Gym",
}
local TANK = { Color3.fromRGB(30, 32, 34), Color3.fromRGB(34, 70, 140), Color3.fromRGB(30, 32, 34), Color3.fromRGB(196, 196, 190) }
local SHUTTER = Color3.fromRGB(154, 160, 166)
local AC = Color3.fromRGB(226, 226, 220)

local function jitter(c: Color3, rng: Random): Color3
	local k = rng:NextNumber(-0.05, 0.05)
	return if k > 0 then c:Lerp(Color3.new(1, 1, 1), k) else c:Lerp(Color3.new(0, 0, 0), -k)
end

local function text(board: BasePart, s: string, col: Color3, face: Enum.NormalId?, font: Enum.Font?, maxDist: number?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(math.max(64, math.floor(board.Size.X * 30)), math.max(32, math.floor(board.Size.Y * 30)))
	gui.LightInfluence = 0.3
	gui.MaxDistance = maxDist or 260
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.94, 0.86)
	t.Position = UDim2.fromScale(0.03, 0.07)
	t.Text = s
	t.TextColor3 = col
	t.Font = font or Enum.Font.GothamBlack
	t.TextScaled = true
	t.Parent = gui
	gui.Parent = board
end

local function sign(cf: CFrame, w: number, h: number, rng: Random, det: Instance, name: string?)
	local pal = M.SIGN[rng:NextInteger(1, #M.SIGN)]
	local b = small(part({ Name = "Sign", Size = Vector3.new(w, h, 0.4), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = pal[1] }, det))
	text(b, name or M.SHOPS[rng:NextInteger(1, #M.SHOPS)], pal[2])
	return b
end

-- the rows of window openings: below-ground floors (on a slope), the ground floor, the floors above
local function windowRows(bottom: number, floors: number): { { number } }
	local rows = {}
	for i = math.floor(-bottom / M.FH), 1, -1 do
		local y0 = -i * M.FH
		table.insert(rows, { y0 + 2, y0 + 7.4 })
	end
	table.insert(rows, { 2.4, 9.6 })
	for f = 1, floors do
		local y0 = M.GF + (f - 1) * M.FH
		table.insert(rows, { y0 + 1.4, y0 + 7.8 })
	end
	return rows
end

local function finish(m: Model, det: Model, cf: CFrame, H: number, D: number, range: number)
	det:SetAttribute("Center", (cf * CFrame.new(0, H / 2, D / 2)).Position)
	det:SetAttribute("Range", range)
	CollectionService:AddTag(det, "LOD")
	det.Parent = m
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Body" then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
end

-- a flat roof: slab, parapet, stair room, water tanks (Yangon's black plastic ones), a dish
local function flatRoof(cf: CFrame, W: number, D: number, H: number, wall: Color3, rng: Random, m: Model, det: Instance, tanks: number)
	local edge = wall:Lerp(Color3.new(1, 1, 1), 0.08)
	part({ Name = "Roof", Size = Vector3.new(W, 0.6, D), CFrame = cf * CFrame.new(0, H + 0.3, D / 2), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(110, 106, 100), 0.55) }, m)
	for _, s in { { W, 0.4 }, { W, D - 0.4 } } do
		quiet(part({ Name = "Parapet", Size = Vector3.new(s[1], 2.4, 0.8), CFrame = cf * CFrame.new(0, H + 1.2, s[2]), Material = Enum.Material.Concrete, Color = edge }, m))
	end
	for _, sx in { -1, 1 } do
		quiet(part({ Name = "Parapet", Size = Vector3.new(0.8, 2.4, D - 1.6), CFrame = cf * CFrame.new(sx * (W / 2 - 0.4), H + 1.2, D / 2), Material = Enum.Material.Concrete, Color = edge }, m))
	end
	local sw, sd = math.min(12, W * 0.3), math.min(12, D * 0.35)
	part({ Name = "StairRoom", Size = Vector3.new(sw, 7, sd), CFrame = cf * CFrame.new(rng:NextNumber(-W / 4, W / 4), H + 3.5, D * rng:NextNumber(0.4, 0.6)), Material = Enum.Material.Concrete, Color = wall }, m)
	for _ = 1, tanks do
		local col = TANK[rng:NextInteger(1, #TANK)]
		small(part({ Name = "Tank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4.4, 4.2, 4.2), CFrame = cf * CFrame.new(rng:NextNumber(-W / 2 + 4, W / 2 - 4), H + 2.8, rng:NextNumber(4, D - 4)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.SmoothPlastic, Color = col }, det)).CastShadow = true
	end
	if rng:NextNumber() < 0.45 then
		small(part({ Name = "Dish", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3.2, 3.2), CFrame = cf * CFrame.new(rng:NextNumber(-W / 3, W / 3), H + 3, rng:NextNumber(3, 6)) * CFrame.Angles(0, math.pi / 2, math.rad(30)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(220, 220, 216) }, det))
	end
end

-- the ground floor shops along the front: roller shutters (some half down), signboards
local function shopRow(cf: CFrame, W: number, cols: number, rng: Random, det: Instance, bigSign: boolean)
	local step = W / cols
	for c = 1, cols do
		local x = -W / 2 + (c - 0.5) * step
		local down = rng:NextNumber()
		if down < 0.55 then
			local h = if down < 0.2 then 8.6 else rng:NextNumber(1.6, 4)
			small(part({ Name = "Shutter", Size = Vector3.new(step - 1.6, h, 0.2), CFrame = cf * CFrame.new(x, 9.8 - h / 2, R - 0.25), Material = Enum.Material.DiamondPlate, Color = SHUTTER }, det))
		end
	end
	if bigSign then
		sign(cf * CFrame.new(0, 11.4, -0.35), W - 1, 3, rng, det)
	else
		sign(cf * CFrame.new(rng:NextNumber(-W / 5, W / 5), 11.2, -0.35), math.min(W * 0.55, 20), 2.4, rng, det)
	end
end

-- balconies across a face, floor by floor: a slab, a low wall, a steel rail on top; now and then washing
local function balconies(fcf: CFrame, W: number, floors: number, wall: Color3, mat: Enum.Material, rng: Random, det: Instance, depth: number)
	local slab = wall:Lerp(Color3.new(1, 1, 1), 0.06)
	for f = 1, floors do
		local y = M.GF + (f - 1) * M.FH
		small(part({ Name = "Balcony", Size = Vector3.new(W + 0.6, 0.6, depth), CFrame = fcf * CFrame.new(0, y + 0.3, -depth / 2), Material = mat, Color = slab }, det)).CastShadow = true
		small(part({ Name = "BalconyWall", Size = Vector3.new(W + 0.6, 2.2, 0.35), CFrame = fcf * CFrame.new(0, y + 1.7, -depth + 0.2), Material = mat, Color = wall }, det))
		small(part({ Name = "Rail", Size = Vector3.new(W + 0.6, 0.25, 0.25), CFrame = fcf * CFrame.new(0, y + 3.9, -depth + 0.2), Material = Enum.Material.Metal, Color = IRON }, det))
		if rng:NextNumber() < 0.22 then
			local cols = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 90, 170), Color3.fromRGB(230, 200, 60), Color3.fromRGB(240, 240, 236), Color3.fromRGB(90, 150, 90) }
			small(part({ Name = "Washing", Size = Vector3.new(rng:NextNumber(3, 6), 1.8, 0.12), CFrame = fcf * CFrame.new(rng:NextNumber(-W / 3, W / 3), y + 3.1, -depth + 0.45), Material = Enum.Material.Fabric, Color = cols[rng:NextInteger(1, #cols)] }, det))
		end
	end
end

-- AC units hung on a face beside some windows
local function acUnits(fcf: CFrame, W: number, cols: number, floors: number, det: Instance, share: number)
	local step = W / cols
	for f = 1, floors do
		for c = 1, cols do
			local p = fcf * CFrame.new(-W / 2 + (c - 0.5) * step + step * 0.32, M.GF + (f - 1) * M.FH + 1.6, -0.9)
			if K.hash(p.Position) < share then
				small(part({ Name = "AC", Size = Vector3.new(2.4, 1.7, 1.2), CFrame = p, Material = Enum.Material.SmoothPlastic, Color = AC }, det))
			end
		end
	end
end

---------------------------------------------------------------------
-- archetypes
---------------------------------------------------------------------
function M.walkup(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance, floors: number, shops: boolean, detail: boolean): Model
	local m = Instance.new("Model")
	m.Name = "WalkUp"
	local H = M.GF + floors * M.FH
	local wall = jitter(M.PASTEL[rng:NextInteger(1, #M.PASTEL)], rng)
	local mat = Enum.Material.Concrete
	local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, cf, W, D, bottom, H, wall)
	local rows = windowRows(bottom, floors)
	local blankEnds = rng:NextNumber() < 0.7
	for i, fc in faces(cf, W, D) do
		local g = if i == 1 then math.min(gnd[1], gnd[2]) elseif i == 2 then math.min(gnd[3], gnd[4]) elseif i == 3 then math.min(gnd[1], gnd[3]) else math.min(gnd[2], gnd[4])
		if i >= 3 and blankEnds then
			face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = 1, ww = 2.6, rows = rows, gf = M.GF, share = 0.3 }, wall, mat, m, det)
		else
			local cols = math.max(2, math.floor(fc.width / 8))
			face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = cols, ww = if i <= 2 then fc.width / cols - 1.6 else 4, rows = rows, shop = if i == 1 and shops then { 9.8 } else nil, gf = M.GF, share = if i <= 2 then 0.45 else 0.3 }, wall, mat, m, det, if i == 1 and detail then {} else nil)
			if i == 1 then
				if shops then
					shopRow(fc.cf, fc.width, cols, rng, det, false)
				end
				if detail then
					acUnits(fc.cf, fc.width, cols, floors, det, 0.38)
				end
			end
		end
	end
	quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.3, 1.2 - bottom, R + 0.25), CFrame = cf * CFrame.new(0, (bottom + 1.2) / 2, R / 2 - 0.12), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(70, 64, 58), 0.4) }, m))
	if detail then
		balconies(faces(cf, W, D)[1].cf, W, floors, wall, mat, rng, det, 3.4)
	end
	flatRoof(cf, W, D, H, wall, rng, m, det, rng:NextInteger(1, 3))
	finish(m, det, cf, H, D, 650)
	m.Parent = parent
	return m
end

function M.shophouse(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance, floors: number, detail: boolean): Model
	local m = Instance.new("Model")
	m.Name = "Shophouse"
	local H = M.GF + floors * M.FH
	local wall = jitter(M.PASTEL[rng:NextInteger(1, #M.PASTEL)], rng)
	local mat = Enum.Material.Plaster
	local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, cf, W, D, bottom, H, wall)
	local rows = windowRows(bottom, floors)
	for i, fc in faces(cf, W, D) do
		local g = if i == 1 then math.min(gnd[1], gnd[2]) elseif i == 2 then math.min(gnd[3], gnd[4]) elseif i == 3 then math.min(gnd[1], gnd[3]) else math.min(gnd[2], gnd[4])
		local cols = if i <= 2 then math.max(2, math.floor(fc.width / 6)) else 1
		face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = cols, ww = if i <= 2 then fc.width / cols - 1.4 else 2.6, rows = rows, shop = if i == 1 then { 9.8 } else nil, gf = M.GF, share = if i == 1 then 0.45 else 0.25 }, wall, mat, m, det, if i == 1 and detail then {} else nil)
		if i == 1 then
			shopRow(fc.cf, fc.width, cols, rng, det, true)
			if detail then
				acUnits(fc.cf, fc.width, cols, floors, det, 0.3)
			end
		end
	end
	quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.3, 1.2 - bottom, R + 0.25), CFrame = cf * CFrame.new(0, (bottom + 1.2) / 2, R / 2 - 0.12), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(70, 64, 58), 0.4) }, m))
	-- a rooftop sign on some
	if rng:NextNumber() < 0.3 then
		local pal = M.SIGN[rng:NextInteger(1, #M.SIGN)]
		local b = small(part({ Name = "RoofSign", Size = Vector3.new(math.min(W - 4, 26), 5, 0.5), CFrame = cf * CFrame.new(0, H + 5.5, 2), Material = Enum.Material.SmoothPlastic, Color = pal[1] }, det))
		text(b, M.SHOPS[rng:NextInteger(1, #M.SHOPS)], pal[2], nil, nil, 600)
		CollectionService:AddTag(b, "LampGlow")
	end
	flatRoof(cf, W, D, H, wall, rng, m, det, rng:NextInteger(1, 2))
	finish(m, det, cf, H, D, 600)
	m.Parent = parent
	return m
end

function M.tower(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance, floors: number, name: string?): Model
	local m = Instance.new("Model")
	m.Name = "Tower"
	local H = M.GF + floors * M.FH
	local wall = jitter(M.CONDO[rng:NextInteger(1, #M.CONDO)], rng)
	local mat = Enum.Material.Plaster
	local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, cf, W, D, bottom, H, wall)
	local rows = windowRows(bottom, floors)
	for i, fc in faces(cf, W, D) do
		local g = if i == 1 then math.min(gnd[1], gnd[2]) elseif i == 2 then math.min(gnd[3], gnd[4]) elseif i == 3 then math.min(gnd[1], gnd[3]) else math.min(gnd[2], gnd[4])
		local cols = math.max(2, math.floor(fc.width / 9))
		face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = g, cols = cols, ww = fc.width / cols - 1.2, rows = rows, shop = if i == 1 then { 9.8 } else nil, gf = M.GF, share = if i <= 2 then 0.45 else 0.35 }, wall, mat, m, det)
	end
	quiet(part({ Name = "Foot", Size = Vector3.new(W + 0.3, 1.2 - bottom, R + 0.25), CFrame = cf * CFrame.new(0, (bottom + 1.2) / 2, R / 2 - 0.12), Material = Enum.Material.Concrete, Color = wall:Lerp(Color3.fromRGB(70, 64, 58), 0.4) }, m))
	balconies(faces(cf, W, D)[1].cf, W, floors, wall, mat, rng, det, 4.2)
	-- the crown: a band with the building's name (condos are named in Yangon)
	local crown = part({ Name = "Crown", Size = Vector3.new(W + 0.6, 6, D + 0.6), CFrame = cf * CFrame.new(0, H + 3, D / 2), Material = Enum.Material.Plaster, Color = wall:Lerp(Color3.fromRGB(60, 70, 90), 0.5) }, m)
	if name then
		text(crown, name, Color3.fromRGB(255, 255, 255), Enum.NormalId.Front, Enum.Font.GothamBold, 900)
	end
	flatRoof(cf, W, D, H + 6, wall, rng, m, det, 2)
	finish(m, det, cf, H, D, 900)
	m.Parent = parent
	return m
end

-- a gated villa: house set back in its yard, hipped roof, a wall all round with a steel gate, trees
function M.villa(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "Villa"
	local floors = rng:NextInteger(1, 2) -- (plus the ground floor)
	local GF, FH = 11, 9
	local hw, hd = W - rng:NextInteger(10, 16), D - rng:NextInteger(14, 20)
	local hcf = cf * CFrame.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(8, D - hd - 4))
	local H = GF + floors * FH
	local wall = jitter(M.VILLA_WALL[rng:NextInteger(1, #M.VILLA_WALL)], rng)
	local mat = Enum.Material.Plaster
	local low = math.min(gnd[1], gnd[2], gnd[3], gnd[4])
	local bottom = low - 2
	local det = Instance.new("Model")
	det.Name = "Detail"
	core(m, hcf, hw, hd, bottom, H, wall)
	local rows = { { 2.4, 8.6 } }
	for f = 1, floors do
		table.insert(rows, { GF + (f - 1) * FH + 1.4, GF + (f - 1) * FH + 7.6 })
	end
	for i, fc in faces(hcf, hw, hd) do
		local cols = math.max(1, math.floor(fc.width / 10))
		face({ fcf = fc.cf, width = fc.width, bottom = bottom, top = H, ground = low, cols = cols, ww = 4.6, rows = rows, gf = GF, share = 0.4 }, wall, mat, m, det)
	end
	-- hipped roof: four wedges meeting in a ridge
	local roofCol = M.ROOF[rng:NextInteger(1, #M.ROOF)]
	local rh = 7
	local oh = 1.6
	local rw, rd = hw + 2 * oh, hd + 2 * oh
	local top = hcf * CFrame.new(0, H, hd / 2)
	part({ Name = "Eaves", Size = Vector3.new(rw, 0.6, rd), CFrame = top * CFrame.new(0, 0.3, 0), Material = Enum.Material.Concrete, Color = wall }, m)
	local ridge = math.max(0.5, rw - rd)
	part({ Name = "RoofRidge", Size = Vector3.new(ridge, rh, 0.4), CFrame = top * CFrame.new(0, 0.6 + rh / 2, 0), Material = Enum.Material.SmoothPlastic, Color = roofCol }, m)
	for _, s in { 1, -1 } do
		-- (a WedgePart is tall at its +Z side: each half turns its tall side to the ridge)
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(ridge + 0.02, rh, rd / 2), CFrame = top * CFrame.new(0, 0.6 + rh / 2, s * rd / 4) * CFrame.Angles(0, if s > 0 then math.pi else 0, 0), Material = Enum.Material.SmoothPlastic, Color = roofCol }, m)
		local half = math.min(rw, rd) / 2
		part({ Class = "WedgePart", Name = "Roof", Size = Vector3.new(rd, rh, half), CFrame = top * CFrame.new(s * (ridge / 2 + half / 2), 0.6 + rh / 2, 0) * CFrame.Angles(0, -s * math.pi / 2, 0), Material = Enum.Material.SmoothPlastic, Color = roofCol:Lerp(Color3.new(0, 0, 0), 0.08) }, m)
	end
	-- the wall round the plot and the gate (front)
	local wc = wall:Lerp(Color3.fromRGB(120, 116, 106), 0.18)
	local wh = 4
	local gate = math.min(14, W * 0.35)
	local gx = rng:NextNumber(-W / 2 + gate / 2 + 2, W / 2 - gate / 2 - 2)
	local function wallRun(c0: CFrame, len: number, y0: number)
		if len > 0.3 then
			quiet(part({ Name = "YardWall", Size = Vector3.new(len, wh - y0, 0.8), CFrame = c0 * CFrame.new(0, (wh + y0) / 2, 0), Material = Enum.Material.Plaster, Color = wc }, m))
		end
	end
	local l1 = (gx - gate / 2) - (-W / 2)
	local l2 = W / 2 - (gx + gate / 2)
	local f0 = math.min(gnd[1], gnd[2]) - 1
	wallRun(cf * CFrame.new(-W / 2 + l1 / 2, 0, 0.4), l1, f0)
	wallRun(cf * CFrame.new(W / 2 - l2 / 2, 0, 0.4), l2, f0)
	small(part({ Name = "Gate", Size = Vector3.new(gate, wh - 0.4, 0.3), CFrame = cf * CFrame.new(gx, wh / 2 - 0.2, 0.4), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(60, 64, 70) }, m))
	wallRun(cf * CFrame.new(0, 0, D - 0.4), W, math.min(gnd[3], gnd[4]) - 1)
	wallRun(cf * CFrame.new(-W / 2 + 0.4, 0, D / 2) * CFrame.Angles(0, math.pi / 2, 0), D - 1.6, math.min(gnd[1], gnd[3]) - 1)
	wallRun(cf * CFrame.new(W / 2 - 0.4, 0, D / 2) * CFrame.Angles(0, math.pi / 2, 0), D - 1.6, math.min(gnd[2], gnd[4]) - 1)
	-- trees in the yard (a rain tree's wide crown, or a palm)
	for _ = 1, rng:NextInteger(1, 2) do
		local tx = if rng:NextNumber() < 0.5 then -W / 2 + 6 else W / 2 - 6
		local tz = rng:NextNumber(5, D - 5)
		local tcf = cf * CFrame.new(tx, 0, tz)
		local hgt = rng:NextNumber(14, 22)
		small(part({ Name = "Trunk", Size = Vector3.new(1.4, hgt, 1.4), CFrame = tcf * CFrame.new(0, hgt / 2 + low, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(92, 72, 56) }, det))
		small(part({ Name = "Crown", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 9, 14) * rng:NextNumber(0.8, 1.2), CFrame = tcf * CFrame.new(0, hgt + low + 1, 0), Material = Enum.Material.Grass, Color = Color3.fromRGB(64, 112, 56):Lerp(Color3.fromRGB(96, 130, 60), rng:NextNumber()) }, det)).CastShadow = true
	end
	finish(m, det, hcf, H, hd, 500)
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- landmarks
---------------------------------------------------------------------
local function bigSign(cf: CFrame, w: number, h: number, txt: string, bg: Color3, fg: Color3, parent: Instance, glow: boolean?)
	local b = part({ Name = "LandmarkSign", Size = Vector3.new(w, h, 0.6), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = bg, CastShadow = false }, parent)
	text(b, txt, fg, Enum.NormalId.Front, Enum.Font.GothamBlack, 2000)
	if glow then
		CollectionService:AddTag(b, "LampGlow")
	end
	return b
end

-- Optima Werkz: a car tuning workshop with roller doors, a side office and a forecourt (the start)
function M.optima(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "OptimaWerkz"
	local low = math.min(gnd[1], gnd[2], gnd[3], gnd[4])
	local fore = 20 -- the forecourt (the meet spot) in front
	local ww, wd, wh = 60, 40, 17
	local wcf = cf * CFrame.new(-W / 2 + ww / 2 + 4, 0, fore)
	local det = Instance.new("Model")
	det.Name = "Detail"
	local wall = Color3.fromRGB(70, 72, 76)
	part({ Name = "Body", Size = Vector3.new(ww, wh - low + 1, wd), CFrame = wcf * CFrame.new(0, (wh + low - 1) / 2, wd / 2), Material = Enum.Material.Metal, Color = wall }, m)
	-- three roller doors, one open (a car inside)
	for k = -1, 1 do
		local open = k == 0
		local dcf = wcf * CFrame.new(k * 19, 0, -0.05)
		part({ Name = if open then "DoorOpen" else "RollerDoor", Size = Vector3.new(14, 10.5, 0.3), CFrame = dcf * CFrame.new(0, if open then 9.6 else 5.25, 0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(138, 143, 148) }, m)
		if open then
			small(part({ Name = "Opening", Size = Vector3.new(14, 8.5, 0.2), CFrame = dcf * CFrame.new(0, 4.25, 0.05), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(28, 28, 30) }, m))
		end
	end
	-- the side office: white, glass front
	local ocf = cf * CFrame.new(-W / 2 + ww + 4 + 12, 0, fore)
	part({ Name = "Office", Size = Vector3.new(22, 14 - low + 1, wd), CFrame = ocf * CFrame.new(0, (14 + low - 1) / 2, wd / 2), Material = Enum.Material.Plaster, Color = Color3.fromRGB(237, 237, 232) }, m)
	local g = small(part({ Name = "Glass", Size = Vector3.new(18, 8, 0.2), CFrame = ocf * CFrame.new(0, 5, -0.1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 60, 72) }, m))
	CollectionService:AddTag(g, "Window")
	-- the signboard over the doors and a pylon at the road
	bigSign(wcf * CFrame.new(0, wh - 2.4, -0.5), ww - 4, 4.4, "OPTIMA WERKZ", Color3.fromRGB(17, 17, 17), Color3.fromRGB(255, 255, 255), m, true)
	local pcf = cf * CFrame.new(W / 2 - 6, 0, 3)
	part({ Name = "Pylon", Size = Vector3.new(1.6, 16 - low, 1.6), CFrame = pcf * CFrame.new(0, (16 + low) / 2, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 44) }, m)
	local p2 = bigSign(pcf * CFrame.new(0, 17.5, -0.2), 12, 5, "OPTIMA WERKZ", Color3.fromRGB(17, 17, 17), Color3.fromRGB(230, 40, 40), m, true)
	text(p2, "OPTIMA WERKZ", Color3.fromRGB(230, 40, 40), Enum.NormalId.Back, Enum.Font.GothamBlack, 2000)
	-- forecourt slab (the meet spot): concrete, flush with the floor
	part({ Name = "Forecourt", Size = Vector3.new(W - 4, 1, fore + 2), CFrame = cf * CFrame.new(0, -0.5, fore / 2), Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 148, 142) }, m)
	m:SetAttribute("MeetSpot", (cf * CFrame.new(0, 1, fore / 2)).Position)
	finish(m, det, cf, wh, D, 800)
	-- (the bodies collide: the workshop is solid; finish() made only "Body" collide, so put walls back)
	for _, n in { "Office", "Forecourt", "RollerDoor", "Pylon" } do
		for _, p in m:GetChildren() do
			if p.Name == n and p:IsA("BasePart") then
				p.CanCollide = true
				p.CanQuery = true
			end
		end
	end
	m.Parent = parent
	return m
end

-- Novotel Yangon Max: a glass podium with a drop-off canopy, a tower on it and a lower wing behind
function M.novotel(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "Novotel"
	local low = math.min(gnd[1], gnd[2], gnd[3], gnd[4])
	local holder = Instance.new("Folder")
	holder.Name = "Parts"
	holder.Parent = m
	-- the podium (2 tall floors)
	local pd = math.min(D, 70)
	local podium = M.tower(cf, W, pd, gnd, rng, holder, 1, nil)
	podium.Name = "Podium"
	-- tower A on the podium, set back; tower B behind it
	local aW, aD = math.min(W - 10, 80), 28
	local acf = cf * CFrame.new(0, M.GF + M.FH, 12)
	local a = M.tower(acf, aW, aD, { 0, 0, 0, 0 }, rng, holder, 14, nil)
	a.Name = "TowerA"
	local bcf = cf * CFrame.new(W / 4, M.GF + M.FH, 12 + aD + 2)
	local b = M.tower(bcf, math.min(W / 2, 46), math.max(10, pd - aD - 16), { 0, 0, 0, 0 }, rng, holder, 11, nil)
	b.Name = "TowerB"
	-- glass-blue panes: tint the walls a cool grey and the sign band navy
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Band" or d.Name == "Pier") then
			d.Color = Color3.fromRGB(201, 205, 209)
		end
	end
	local topA = M.GF + M.FH + M.GF + 14 * M.FH
	bigSign(acf * CFrame.new(0, topA - 4, -1), math.min(aW - 8, 46), 7, "NOVOTEL", Color3.fromRGB(31, 42, 92), Color3.fromRGB(255, 255, 255), m, true)
	-- drop-off canopy
	part({ Name = "Canopy", Size = Vector3.new(36, 1.4, 14), CFrame = cf * CFrame.new(0, 9, -6), Material = Enum.Material.Metal, Color = Color3.fromRGB(201, 205, 209) }, m)
	for _, sx in { -1, 1 } do
		part({ Name = "CanopyPost", Size = Vector3.new(1, 9, 1), CFrame = cf * CFrame.new(sx * 16, 4.5, -12), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 154, 158) }, m)
	end
	bigSign(cf * CFrame.new(0, 10.4, -13.1), 16, 2, "NOVOTEL", Color3.fromRGB(31, 42, 92), Color3.fromRGB(255, 255, 255), m)
	m.Parent = parent
	return m
end

-- Myanmar Plaza: a long white mall with dark glass, a glass corner atrium, two towers behind
function M.mmplaza(cf: CFrame, W: number, D: number, gnd: { number }, rng: Random, parent: Instance): Model
	local m = Instance.new("Model")
	m.Name = "MyanmarPlaza"
	local low = math.min(gnd[1], gnd[2], gnd[3], gnd[4])
	local holder = Instance.new("Folder")
	holder.Name = "Parts"
	holder.Parent = m
	local pd = math.min(D - 10, 100)
	local podium = M.tower(cf, W, pd, gnd, rng, holder, 3, nil)
	podium.Name = "Mall"
	for _, d in podium:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Band" or d.Name == "Pier") then
			d.Color = Color3.fromRGB(230, 232, 234)
		end
	end
	local H = M.GF + 3 * M.FH
	-- the corner atrium: a tall dark-glass box at the front left
	part({ Name = "Atrium", Size = Vector3.new(40, H + 12 - low, 30), CFrame = cf * CFrame.new(-W / 2 + 21, (H + 12 + low) / 2, 14), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 60, 72) }, m)
	-- towers behind
	local t1 = M.tower(cf * CFrame.new(W / 4, H, pd * 0.45), 60, 40, { 0, 0, 0, 0 }, rng, holder, 15, nil)
	t1.Name = "Tower1"
	local t2 = M.tower(cf * CFrame.new(-W / 6, H, pd * 0.5), 50, 36, { 0, 0, 0, 0 }, rng, holder, 11, nil)
	t2.Name = "Tower2"
	bigSign(cf * CFrame.new(W / 8, H - 4, -1), math.min(W * 0.5, 90), 7, "MYANMAR PLAZA", Color3.fromRGB(240, 240, 240), Color3.fromRGB(180, 30, 40), m, true)
	-- the corner pylon and the fountain plaza
	local pcf = cf * CFrame.new(-W / 2 + 6, 0, -2)
	local py = part({ Name = "Pylon", Size = Vector3.new(6, 26 - low, 1.6), CFrame = pcf * CFrame.new(0, (26 + low) / 2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(180, 30, 40) }, m)
	text(py, "MYANMAR PLAZA", Color3.fromRGB(255, 255, 255), Enum.NormalId.Front, Enum.Font.GothamBlack, 2000)
	part({ Name = "FountainBasin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 16, 16), CFrame = cf * CFrame.new(-W / 2 + 22, 0.7, -0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Concrete, Color = Color3.fromRGB(220, 220, 214) }, m)
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- placement
---------------------------------------------------------------------
local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.IgnoreWater = false
local roadsOnly = RaycastParams.new()
roadsOnly.FilterType = Enum.RaycastFilterType.Include

-- which kind of building on which plot (deterministic by plot index)
local TOWER_SPOTS = {
	Vector3.new(28480, 0, -1140), -- Hledan / University Avenue under the Pyay flyover
	Vector3.new(32560, 0, -1300), -- round Myanmar Plaza (Kabar Aye Pagoda Road)
	Vector3.new(30880, 0, -700), -- University Avenue meets the loop
}
local LEAFY = { ["University Avenue"] = true, ["Inya Road"] = true, ["Inya Road West"] = true, ["Inya Road East"] = true, ["Inya Myaing Street"] = true, ["Kan Road"] = true }
M.TOWER_NAMES = { "Inya Lake Residence", "Pearl Condo", "Golden City Tower", "Kamayut Heights", "Shwe Garden Condo", "Lotus Residences", "Bahan Tower", "Royal Lake View" }

local function pick(p, rng: Random): string
	if p.landmark then
		return p.landmark
	end
	local pos = Vector3.new(p.x, 0, p.z)
	local nearTowers = false
	for _, t in TOWER_SPOTS do
		if (pos - t).Magnitude < 420 then
			nearTowers = true
		end
	end
	local r = rng:NextNumber()
	if p.kind == "route" or p.kind == "side" then
		if nearTowers and p.w >= 52 and p.d >= 60 and r < 0.35 then
			return "tower"
		end
		if LEAFY[p.road] and r < 0.3 then
			return "villa"
		end
		if r < 0.55 then
			return "walkup"
		elseif r < 0.9 then
			return "shophouse"
		end
		return "villa"
	end
	if LEAFY[p.road] and r < 0.6 then
		return "villa"
	end
	if r < 0.42 then
		return "villa"
	elseif r < 0.85 then
		return "walkup"
	end
	return "shophouse"
end

function M.folder(): Instance
	local y = workspace:FindFirstChild("Yangon")
	local f = y:FindFirstChild("Buildings")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Buildings"
		f.Parent = y
	end
	return f
end

function M.spawn(fn)
	local YD = SS.YangonData
	YD:SetAttribute("BuildingsStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		YD:SetAttribute("BuildingsStatus", string.format("%s after %.0f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("BuildingsStatus"))
end

-- opts.limit: only the first n plots (a test), opts.only = { [kind] = true }, opts.keep (don't clear)
function M.build(opts)
	opts = opts or {}
	local plots = Http:JSONDecode(require(SS.YangonData.Plots:Clone())).plots
	local parent = M.folder()
	if not opts.keep then
		for i, c in parent:GetChildren() do
			c:Destroy()
			if i % 200 == 0 then
				task.wait()
			end
		end
	end
	terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
	roadsOnly.FilterDescendantsInstances = { workspace.Yangon.Roads }
	local made, skipped, kinds, parts = 0, 0, {}, 0
	local rng = Random.new(20261113)
	for i, p in plots do
		if opts.limit and made >= opts.limit then
			break
		end
		local prng = Random.new(1000 + i)
		local kind = pick(p, prng)
		if opts.only and not opts.only[kind] then
			continue
		end
		local f = Vector3.new(p.fx, 0, p.fz)
		local centre = Vector3.new(p.x, 0, p.z)
		local front = centre - f * (p.d / 2)
		-- floor: the pavement's top in front of the plot
		local probe = front - f * (M.SETBACK + 2.5)
		local hit = workspace:Raycast(Vector3.new(probe.X, 300, probe.Z), Vector3.new(0, -400, 0), roadsOnly)
		local tg = workspace:Raycast(Vector3.new(front.X, 300, front.Z), Vector3.new(0, -400, 0), terrainOnly)
		if not hit and not tg then
			skipped += 1
			continue
		end
		local floorY = if hit then hit.Position.Y else tg.Position.Y + 0.5
		local cf = CFrame.lookAt(Vector3.new(front.X, floorY, front.Z), Vector3.new(front.X, floorY, front.Z) - f)
		-- the ground at the four corners, under the floor (FL, FR, BL, BR in the building's frame)
		local gnd, water, above = {}, false, -math.huge
		for _, c in { { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } } do
			local wp = cf * Vector3.new(c[1] * p.w / 2, 0, c[2] * p.d)
			local g = workspace:Raycast(Vector3.new(wp.X, 300, wp.Z), Vector3.new(0, -400, 0), terrainOnly)
			local gy = if g then g.Position.Y else floorY - 6
			if g and g.Material == Enum.Material.Water then
				water = true
			end
			above = math.max(above, gy - floorY)
			table.insert(gnd, math.min(0, gy - floorY))
		end
		if water then
			skipped += 1
			continue
		end
		if above > 0 then
			-- ground higher than the floor: dig the footprint out (as Buildings.build)
			workspace.Terrain:FillBlock(cf * CFrame.new(0, above / 2 + 40, p.d / 2), Vector3.new(p.w, 80 + above, p.d), Enum.Material.Air)
		end
		local m
		if kind == "walkup" then
			local floors = if p.kind == "street" then prng:NextInteger(3, 6) else prng:NextInteger(5, 8)
			m = M.walkup(cf, p.w, p.d, gnd, prng, parent, floors, p.kind ~= "street" or prng:NextNumber() < 0.3, p.kind ~= "street" or prng:NextNumber() < 0.5)
		elseif kind == "shophouse" then
			m = M.shophouse(cf, p.w, p.d, gnd, prng, parent, prng:NextInteger(2, if p.kind == "street" then 3 else 4), p.kind ~= "street")
		elseif kind == "tower" then
			m = M.tower(cf, math.min(p.w, 56), math.min(p.d, 48), gnd, prng, parent, prng:NextInteger(12, 20), M.TOWER_NAMES[prng:NextInteger(1, #M.TOWER_NAMES)])
		elseif kind == "villa" then
			m = M.villa(cf, p.w, p.d, gnd, prng, parent)
		elseif kind == "optima" then
			m = M.optima(cf, p.w, p.d, gnd, prng, parent)
		elseif kind == "novotel" then
			m = M.novotel(cf, p.w, p.d, gnd, prng, parent)
		elseif kind == "mmplaza" then
			m = M.mmplaza(cf, p.w, p.d, gnd, prng, parent)
		end
		if m then
			m:SetAttribute("Plot", i)
			m:SetAttribute("Road", p.road)
			made += 1
			kinds[kind] = (kinds[kind] or 0) + 1
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					parts += 1
				end
			end
		end
		if made % 4 == 0 then
			task.wait()
		end
	end
	-- no two faces on one plane (the Riviera's flashing): the kit's own fixer
	local moved, left = 0, 0
	local un = SS.ClaudeTools:FindFirstChild("Unstack")
	if un then
		moved, left = (require(un:Clone()) :: any).all(parent)
	end
	local t = {}
	for k, v in kinds do
		table.insert(t, k .. " " .. v)
	end
	return string.format("%d buildings (%s), %d skipped, %d parts (%.0f each); unstack moved %s, left %s", made, table.concat(t, ", "), skipped, parts, parts / math.max(made, 1), tostring(moved), tostring(left))
end

return M
