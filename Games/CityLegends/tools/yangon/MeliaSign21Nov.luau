--[[
	MeliaSign21Nov.luau (Studio, Edit; coordinator 21 Nov: "Meliá sign: make it read MELIÁ like the real one").
	Real sign (City Legends/refs_21nov/0799_99s.jpg): gold serif capitals MELIÁ high on the tower's broad face.
	The old letters are one mesh, Landmarks.MyanmarCentre.Meshes.RDL, holding four texts (measured from its vertices with
	EditableMesh): MELIA YANGON on the tower's west face (x 34784-34786, y 311-317, z 27727-27791) and east face
	(x 34851-34853, z 27731-27795), MELIA YANGON on the west entrance canopy (x 34614-34618, y 58-61, z 27770-27793)
	and a small MYANMAR PLAZA (x 34690-34699, y 55-56, plane z 27761). The mesh is hidden (Transparency 1, old value in
	attribute Transp_before_21Nov) and all four come back as SurfaceGui text on thin transparent parts (no lights):
	tower faces MELIÁ (72 x 20, larger than the old 6-stud letters, as in the photo), canopy MELIÁ YANGON, MYANMAR PLAZA
	as it was. Parts go in Landmarks.IrlSigns21Nov (names Melia_*). M.build(), M.undo().
]]
local M = {}
local GOLD = Color3.fromRGB(222, 178, 86)
local SERIF = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)

local function rdl()
	return workspace.Yangon1to1.Landmarks.MyanmarCentre.Meshes.RDL
end

local function sign(name, at: Vector3, face: Vector3, w, h, text, faces)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(w, h, 0.2)
	p.CFrame = CFrame.lookAt(at, at + face) -- Front face looks along `face`
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	for _, f in faces do
		local g = Instance.new("SurfaceGui")
		g.Face = f
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 90 / h -- TextScaled stops at 100 px: keep the canvas ~90 px tall
		g.LightInfluence = 0
		g.Brightness = 1.3
		g.MaxDistance = 5000
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = text
		t.TextScaled = true
		t.FontFace = SERIF
		t.TextColor3 = GOLD
		t.Parent = g
		g.Parent = p
	end
	p.Parent = workspace.Yangon1to1.Landmarks.IrlSigns21Nov
	return p
end

function M.build()
	M.undo()
	local r = rdl()
	r:SetAttribute("Transp_before_21Nov", r.Transparency)
	r.Transparency = 1
	local F = { Enum.NormalId.Front }
	sign("Melia_TowerWest", Vector3.new(34784.9, 315.5, 27759), Vector3.new(-1, 0, 0), 72, 20, "MELIÁ", F)
	sign("Melia_TowerEast", Vector3.new(34852.1, 315.5, 27763), Vector3.new(1, 0, 0), 72, 20, "MELIÁ", F)
	sign("Melia_Canopy", Vector3.new(34614.9, 59.5, 27781.5), Vector3.new(-1, 0, 0), 24, 3.2, "MELIÁ YANGON", F)
	sign("Melia_MyanmarPlazaSmall", Vector3.new(34694.5, 55.5, 27761), Vector3.new(0, 0, 1), 9.5, 1.2, "MYANMAR PLAZA",
		{ Enum.NormalId.Front, Enum.NormalId.Back })
	return 4
end

function M.undo()
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlSigns21Nov")
	if f then
		for _, c in f:GetChildren() do
			if c.Name:sub(1, 6) == "Melia_" then
				c:Destroy()
			end
		end
	end
	local r = rdl()
	local t = r:GetAttribute("Transp_before_21Nov")
	if t then
		r.Transparency = t
		r:SetAttribute("Transp_before_21Nov", nil)
	end
end

return M
