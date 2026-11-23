--[[
	YccBanners21Nov.luau (Studio, Edit; coordinator 21 Nov leftovers: "YCC hall: add the yellow/black hazard stripe on
	the banner walls, and make the hall brighter at night").
	Real hall (City Legends/refs_21nov/0793_photo.jpg): a dark navy banner hoarding along the wall base, repeating
	"GG GAMING FEST 2026" (gold) and "yangonation. AUTOCULT" (white), with a yellow dash stripe on its top and bottom edge.
	Ours: thin transparent parts 0.5 stud inside the INW long walls (y 55.4-67.4), each carrying one SurfaceGui (bg, two
	dash rows from hard-step UIGradients, three labels). Wall lines measured from INW vertices in hall axes (u along the
	hall, v across): +v wall v = 91.97 + 0.0073u (doors at u -177..-150, -12..14, 152..179 kept clear), -v wall
	v = -92.15 + 0.0075u. Night: the 14 existing PointLights sat at y 82 inside the roof meshes (the hall floor got
	nothing; found in a Play night test): their parts move down to y 70 (15 above the floor), brightness 1.1 -> 2.6 and a
	cooler flood white; no new lights (phones). Old values in attributes *_before_21Nov. M.build(), M.undo().
]]
local M = {}
local A, B, C = Vector2.new(33412.5, 21916.6), Vector2.new(33537.9, 21779.2), Vector2.new(33922.3, 22124.8)
local AX, NE, O = (C - B).Unit, (B - A).Unit, (A + C) / 2
local NAVY = Color3.fromRGB(28, 30, 58)
local YEL = Color3.fromRGB(236, 178, 40)
local GOLD = Color3.fromRGB(214, 170, 96)
local TECH = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Regular)
local COND = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold)
local Y0, H = 55.4, 12
local WALLS = {
	{ v0 = 91.97, k = 0.0073, side = 1, segs = { { -252, -180 }, { -148, -15 }, { 17, 150 }, { 182, 252 } } },
	{ v0 = -92.15, k = 0.0075, side = -1, segs = { { -252, 252 } } },
}

local function world(u, v, y)
	-- u, v are projections (d:Dot(AX), d:Dot(NE)) and AX, NE are not quite perpendicular: invert the 2x2
	local det = AX.X * NE.Y - AX.Y * NE.X
	local x = (u * NE.Y - v * AX.Y) / det
	local z = (v * AX.X - u * NE.X) / det
	return Vector3.new(O.X + x, y, O.Y + z)
end

local function hall()
	return workspace.Yangon1to1.Landmarks.YangonConventionCentre
end

local function label(g, text, font, colour, pos, size)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position, t.Size = pos, size
	t.Text, t.FontFace, t.TextColor3, t.TextScaled = text, font, colour, true
	t.Parent = g
end

local function dashRow(g, y)
	-- 4 frames per row, 2 dashes each: yellow 2/3 of a period, navy gap 1/3
	local e = 0.001
	local cs = ColorSequence.new({
		ColorSequenceKeypoint.new(0, YEL), ColorSequenceKeypoint.new(1 / 3, YEL),
		ColorSequenceKeypoint.new(1 / 3 + e, NAVY), ColorSequenceKeypoint.new(0.5, NAVY),
		ColorSequenceKeypoint.new(0.5 + e, YEL), ColorSequenceKeypoint.new(5 / 6, YEL),
		ColorSequenceKeypoint.new(5 / 6 + e, NAVY), ColorSequenceKeypoint.new(1, NAVY),
	})
	for i = 0, 3 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.Position = UDim2.fromScale(i / 4, y)
		f.Size = UDim2.fromScale(0.25, 0.05)
		local gr = Instance.new("UIGradient")
		gr.Color = cs
		gr.Parent = f
		f.Parent = g
	end
end

local function panel(folder, name, u0, u1, w)
	local uc = (u0 + u1) / 2
	local vin = w.v0 + w.k * uc - w.side * 0.5
	local at = world(uc, vin, Y0 + H / 2)
	local d = world(uc + 1, vin + w.k, 0) - world(uc, vin, 0)
	local inward = Vector2.new(-d.Z, d.X).Unit -- perpendicular to the wall; flip to point into the hall
	if inward:Dot(NE) * w.side > 0 then
		inward = -inward
	end
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(u1 - u0, H, 0.2)
	p.CFrame = CFrame.lookAt(at, at + Vector3.new(inward.X, 0, inward.Y))
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 25
	g.LightInfluence = 0
	g.Brightness = 0.85
	g.MaxDistance = 400
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = NAVY
	bg.Parent = g
	dashRow(g, 0.02)
	dashRow(g, 0.93)
	label(g, "GG\nGAMING\nFEST 2026", TECH, GOLD, UDim2.fromScale(0.05, 0.14), UDim2.fromScale(0.34, 0.72))
	label(g, "yangonation.", COND, Color3.fromRGB(232, 232, 236), UDim2.fromScale(0.45, 0.2), UDim2.fromScale(0.5, 0.42))
	label(g, "A U T O C U L T", COND, Color3.fromRGB(200, 200, 210), UDim2.fromScale(0.62, 0.62), UDim2.fromScale(0.3, 0.1))
	g.Parent = p
	p.Parent = folder
end

function M.build()
	M.undo()
	local folder = Instance.new("Folder")
	folder.Name = "Banners21Nov"
	local n = 0
	for wi, w in WALLS do
		for _, s in w.segs do
			local cnt = math.max(1, math.floor((s[2] - s[1]) / 42 + 0.5))
			local step = (s[2] - s[1]) / cnt
			for i = 0, cnt - 1 do
				n += 1
				panel(folder, "Banner_" .. wi .. "_" .. n, s[1] + i * step, s[1] + (i + 1) * step, w)
			end
		end
	end
	folder.Parent = hall()
	for _, l in hall().Visual:GetDescendants() do
		if l:IsA("PointLight") then
			l:SetAttribute("Bright_before_21Nov", l.Brightness)
			l:SetAttribute("Color_before_21Nov", l.Color)
			l.Brightness = 2.6
			l.Color = Color3.fromRGB(238, 244, 255)
			local q = l.Parent -- the 0.4-stud "Light" part: at y 82 it sat inside the roof meshes and lit only them
			q:SetAttribute("Y_before_21Nov", q.Position.Y)
			q.Position = Vector3.new(q.Position.X, 70, q.Position.Z)
		end
	end
	return n
end

function M.undo()
	local f = hall():FindFirstChild("Banners21Nov")
	if f then
		f:Destroy()
	end
	for _, l in hall().Visual:GetDescendants() do
		if l:IsA("PointLight") and l:GetAttribute("Bright_before_21Nov") then
			l.Brightness = l:GetAttribute("Bright_before_21Nov")
			l.Color = l:GetAttribute("Color_before_21Nov")
			l:SetAttribute("Bright_before_21Nov", nil)
			l:SetAttribute("Color_before_21Nov", nil)
			local q = l.Parent
			if q:GetAttribute("Y_before_21Nov") then
				q.Position = Vector3.new(q.Position.X, q:GetAttribute("Y_before_21Nov"), q.Position.Z)
				q:SetAttribute("Y_before_21Nov", nil)
			end
		end
	end
end

return M
