--[[
	IrlSigns21Nov.luau (Studio, Edit; 21 Nov 2026, owner: "its the real life yangon city", the night videos in
	City Legends/2026-11-21 Real Yangon references): lit roadside billboards (made-up ads), the Myanmar Plaza LED
	screen + name, the Junction City name wall + roof sign, THE CENTRAL letters. Real mall names as plain text only
	(no logo artwork); billboards carry made-up brands. No Light objects: glow = SurfaceGui (LightInfluence low)
	+ Neon flood bars tagged LampGlow (WorldFx: Neon at night, plain by day), so phones pay no light cost.
	Everything goes in Workspace.Yangon1to1.Landmarks.IrlSigns21Nov; M.undo() deletes that folder.
	Spots are checked by raycast: a board stands only on grass, never on a road / pavement box or in a building.
	Placed 21 Nov (run inline from execute_luau with these functions; 25 parts in all):
	  * billboards: Kabar Aye Pagoda Rd lake verge (road west edge - 14, z 26700..28500 step 260, facing +X) and
	    Sule Pagoda Rd north of Sule (z 43700..44900 step 200, alternate verges): 6 of 14 spots were all-grass
	  * MyanmarPlaza_LED 46 x 26 (+ LEDFrame 48 x 28) and MyanmarPlaza_Name 70 x 9 on Myanmar Centre's west wall
	    (wallAt from x 34600 at z 27310 / 27410, 4 / 3 studs out), Brightness 2.2, LightInfluence 0
	  * JunctionCity_NameWall 64 x 8 (cream, ground + 13) and JunctionCity_RoofSign 180 x 22 (y 268) on the north
	    face (z ~43482, facing Bogyoke Aung San Rd)
	  * TheCentral_Letters 58 x 10 + plinth at (34978, 25265) on the grass east of Kabar Aye, facing the road
	Real brand signs (owner, 21 Nov: the managers of CB Bank, Melia, Sedona agreed):
	  * CBBank_RoofSign: transparent Part 60 x 26 x 0.4 on Myanmar Centre tower B's roof (34716, 392, 27488), facing -X;
	    SurfaceGuis Front + Back (PPS 10, LightInfluence 0, Brightness 1.8): rainbow arc (clipped ring Frame, UIStroke 22
	    with a rainbow UIGradient) over yellow "CB BANK" (GothamSSm Heavy, 255, 214, 20), as the real one (0799_85s)
	  * CBBank_RoofSign_Sule: a clone on the tower by Sule Pagoda Rd (shell Cell_20_24.KW6, roof 269.9), centre
	    (36196, 283.5, 43544), facing north to the truss bridge (0804_56s)
	  * Melia: no new part; Landmarks.MyanmarCentre.Meshes.RDL (the existing MELIA YANGON letters) re-coloured gold
	    (226, 182, 96), NightColor (255, 214, 130); old colour in attribute Color_before_21Nov
	  * Sedona: the existing white glowing SEDONA (Landmarks.Sedona WLT) already matches 0799_43s: unchanged
]]
local CS = game:GetService("CollectionService")
local M = {}

local function root()
	local lm = workspace.Yangon1to1.Landmarks
	local f = lm:FindFirstChild("IrlSigns21Nov")
	if not f then
		f = Instance.new("Folder")
		f.Name = "IrlSigns21Nov"
		f.Parent = lm
	end
	return f
end

local function part(parent, name, size, cf, color, mat, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanQuery = collide == true
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- a SurfaceGui on the part's Front face: lines = { {text, height share, color, font} }, bg = {c1, c2} or nil
local function face(p, bg, lines, pps)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pps or 20
	g.LightInfluence = 0.15
	g.Brightness = 1.4
	g.MaxDistance = 1400
	g.ZOffset = 0
	local fr = Instance.new("Frame")
	fr.Size = UDim2.fromScale(1, 1)
	fr.BorderSizePixel = 0
	if bg then
		fr.BackgroundColor3 = Color3.new(1, 1, 1)
		local gr = Instance.new("UIGradient")
		gr.Color = ColorSequence.new(bg[1], bg[2])
		gr.Rotation = bg[3] or 20
		gr.Parent = fr
	else
		fr.BackgroundTransparency = 1
	end
	fr.Parent = g
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Parent = fr
	for i, l in lines do
		local t = Instance.new("TextLabel")
		t.LayoutOrder = i
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(0.94, l[2])
		t.Text = l[1]
		t.TextScaled = true
		t.TextColor3 = l[3]
		t.FontFace = Font.fromEnum(l[4] or Enum.Font.GothamBlack)
		t.Parent = fr
	end
	g.Parent = p
	return g
end

local function ground(x, z)
	local hit = workspace:Raycast(Vector3.new(x, 900, z), Vector3.new(0, -1100, 0))
	return hit
end

-- clear spot for a footprint (w across, d deep) at (x, z) facing dir: every probe lands on terrain grass
local function grassSpot(x, z, right, w, d)
	local fwd = Vector3.new(-right.Z, 0, right.X)
	local y = -math.huge
	for _, a in { -0.5, 0, 0.5 } do
		for _, b in { -0.5, 0.5 } do
			local q = Vector3.new(x, 0, z) + right * (a * w) + fwd * (b * d)
			local hit = ground(q.X, q.Z)
			if not hit or not hit.Instance:IsA("Terrain") or hit.Material ~= Enum.Material.Grass then
				return nil
			end
			y = math.max(y, hit.Position.Y)
		end
	end
	return y
end

local ADS = {
	{ "LEGENDS MOTORS", "NEW CARS EVERY WEEK", Color3.fromRGB(16, 18, 30), Color3.fromRGB(40, 46, 90), Color3.fromRGB(240, 196, 70) },
	{ "GOLDEN RIVER BANK", "SAVE MORE, SMILE MORE", Color3.fromRGB(240, 196, 40), Color3.fromRGB(250, 226, 120), Color3.fromRGB(30, 24, 20) },
	{ "SWAN MOBILE 5G", "FASTEST IN YANGON", Color3.fromRGB(120, 40, 170), Color3.fromRGB(210, 80, 190), Color3.fromRGB(255, 255, 255) },
	{ "PEACOCK COFFEE MIX", "3 IN 1  -  ALWAYS FRESH", Color3.fromRGB(150, 26, 30), Color3.fromRGB(220, 70, 40), Color3.fromRGB(255, 236, 200) },
	{ "MINGALAR NOODLES", "HOT  -  SPICY  -  READY", Color3.fromRGB(230, 120, 20), Color3.fromRGB(250, 190, 60), Color3.fromRGB(120, 20, 10) },
	{ "CITY LEGENDS FM", "99.1  -  DRIVE ALL NIGHT", Color3.fromRGB(10, 70, 140), Color3.fromRGB(30, 160, 210), Color3.fromRGB(255, 255, 255) },
	{ "LOTUS PAINT", "COLOUR YOUR HOME", Color3.fromRGB(20, 120, 80), Color3.fromRGB(110, 200, 120), Color3.fromRGB(255, 255, 255) },
	{ "ROYAL TEA HOUSE", "SINCE 1998", Color3.fromRGB(60, 30, 20), Color3.fromRGB(140, 80, 40), Color3.fromRGB(250, 220, 160) },
}

-- one billboard: pole + board + flood bar (3 parts). right = the board's +X in the world, the face looks at the road
local function billboard(parent, x, y, z, right, ad, n)
	local W, H, POLE = 36, 12, 20
	local look = Vector3.new(right.Z, 0, -right.X) -- Front face direction (-Z of the CFrame)
	local base = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(x, y, z) + look)
	local m = Instance.new("Model")
	m.Name = "Billboard_" .. n
	part(m, "Pole", Vector3.new(1.6, POLE + 1, 1.6), base * CFrame.new(0, (POLE + 1) / 2 - 1, 0.8), Color3.fromRGB(70, 72, 76), Enum.Material.Metal, true)
	local board = part(m, "Board", Vector3.new(W, H, 0.8), base * CFrame.new(0, POLE + H / 2, 0), Color3.fromRGB(28, 28, 30))
	face(board, { ad[3], ad[4] }, { { ad[1], 0.5, ad[5] }, { ad[2], 0.24, ad[5], Enum.Font.GothamBold } }, 16)
	local bar = part(m, "Flood", Vector3.new(W - 2, 0.5, 0.5), base * CFrame.new(0, POLE + H + 0.6, -1.2), Color3.fromRGB(255, 244, 222), Enum.Material.Neon)
	CS:AddTag(bar, "LampGlow")
	m.Parent = parent
	return m
end

-- billboards along a road edge: walk a polyline of candidate spots, keep those whose footprint is all grass
-- spots = { {x, z, yawDeg facing the road} }
function M.billboards(spots)
	local f = root()
	local holder = f:FindFirstChild("Billboards") or Instance.new("Folder")
	holder.Name = "Billboards"
	holder.Parent = f
	local made, skipped = 0, 0
	for i, s in spots do
		local yaw = math.rad(s[3])
		local look = Vector3.new(math.sin(yaw), 0, math.cos(yaw)) -- facing the road
		local right = Vector3.new(-look.Z, 0, look.X)
		local y = grassSpot(s[1], s[2], right, 40, 6)
		if y then
			made += 1
			billboard(holder, s[1], y, s[2], right, ADS[(i - 1) % #ADS + 1], i)
		else
			skipped += 1
		end
	end
	return made, skipped
end

-- a flat sign hung off a wall: centre point on the wall face, outward normal (flat), size
function M.wallSign(name, at, normal, w, h, bg, lines, pps, transparent)
	local f = root()
	local cf = CFrame.lookAt(at, at + normal)
	local p = part(f, name, Vector3.new(w, h, 0.4), cf, bg and Color3.fromRGB(20, 20, 22) or Color3.new(0, 0, 0))
	if transparent then
		p.Transparency = 1
	end
	face(p, bg, lines, pps)
	return p
end

-- horizontal ray to a building wall from a road-side point: returns the hit point and the flat outward normal
function M.wallAt(from, dir)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace.Terrain, root() }
	local hit = workspace:Raycast(from, dir, params)
	if not hit then
		return nil
	end
	local n = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
	return hit.Position, n.Magnitude > 0.01 and n.Unit or -dir.Unit, hit.Instance
end

function M.undo()
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlSigns21Nov")
	if f then
		f:Destroy()
	end
end

return M
