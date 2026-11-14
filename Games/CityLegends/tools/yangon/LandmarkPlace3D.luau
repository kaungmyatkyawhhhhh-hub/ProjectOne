--[[
	LandmarkPlace3D (Studio, Edit mode; 2026-11-14, real-geometry landmarks: Myanmar Centre, Sedona).

	Places the meshes made by tools/yangon/city/mc3d.py / sedona3d.py (landmark_glb3d.py): every MeshPart is named
	"<GROUP>_<tag>s<k>_cx_cy_cz_sx_sy_sz" (hundredths of a stud, "n" = minus; the true box, the .glb positions relative to
	the box centre with x and z negated, so CFrame.new(centre) with no turn). The GROUP gives the look (no textures:
	owner, 2026-11-14 "make myanmar plaza 3d, not with textures and decals"). Generate GROUPS with
	`python landmark_glb3d.py`.

	local P = require(ServerStorage.ClaudeTools.LandmarkPlace3D:Clone())
	P.place(holding, folder, modelName) -> MeshParts placed in folder/modelName (ModelStreamingMode Persistent)
	P.boards(list, images, folder)      -> picture boards: parts with a SurfaceGui ImageLabel (list from mc3d_boards.json:
	                                        {c = {x, y}, z0, w, h, n = {nx, ny}, img, frame}, model coords; images[img] = id;
	                                        base y from P.BASE / P.PLANE)
	P.signs(list, folder)               -> shop signs: thin parts with a SurfaceGui TextLabel
	P.lights(list, folder)              -> warm PointLights in invisible anchored parts
	Model coords -> world: X = 32600 + x, Z = -1350 - y, Y = base + z.
]]

local M = {}

local GROUPS = {
	BLU = { "SmoothPlastic", 40, 62, 150, 0.00, 0.00, false, true },
	CAR = { "SmoothPlastic", 165, 120, 70, 0.00, 0.00, false, false },
	CEL = { "SmoothPlastic", 240, 240, 236, 0.00, 0.00, false, false },
	CHR = { "SmoothPlastic", 58, 60, 64, 0.00, 0.00, false, true },
	CRM = { "SmoothPlastic", 216, 206, 184, 0.00, 0.00, false, true },
	CRN = { "SmoothPlastic", 226, 214, 190, 0.00, 0.00, false, true },
	CRT = { "SmoothPlastic", 56, 120, 92, 0.00, 0.00, false, false },
	DRK = { "SmoothPlastic", 38, 40, 44, 0.00, 0.00, false, true },
	DRV = { "Asphalt", 64, 64, 66, 0.00, 0.00, false, false },
	EAV = { "SmoothPlastic", 88, 60, 46, 0.00, 0.00, false, true },
	FEN = { "DiamondPlate", 40, 58, 44, 0.55, 0.00, true, false },
	GLA = { "Glass", 46, 60, 76, 0.00, 0.12, false, true },
	GLB = { "Glass", 40, 62, 86, 0.00, 0.18, false, true },
	GLD = { "SmoothPlastic", 214, 186, 120, 0.00, 0.00, false, true },
	GLL = { "Glass", 150, 146, 132, 0.00, 0.12, false, true },
	GLP = { "Glass", 52, 62, 70, 0.00, 0.08, true, true },
	GLS = { "Glass", 176, 196, 204, 0.55, 0.05, true, false },
	GLU = { "Glass", 70, 100, 140, 0.00, 0.15, false, true },
	GRD = { "Metal", 170, 150, 115, 0.00, 0.00, false, false },
	GRN = { "Sandstone", 196, 178, 150, 0.00, 0.00, false, true },
	HDG = { "Grass", 64, 108, 44, 0.00, 0.00, false, true },
	LAW = { "Grass", 104, 150, 66, 0.00, 0.00, false, false },
	LIT = { "Neon", 196, 182, 156, 0.00, 0.00, false, false },
	MAR = { "Marble", 205, 198, 185, 0.00, 0.00, false, false },
	MEL = { "SmoothPlastic", 238, 238, 234, 0.00, 0.00, false, true },
	MUL = { "Metal", 84, 88, 94, 0.00, 0.00, false, true },
	MUW = { "SmoothPlastic", 236, 234, 228, 0.00, 0.00, false, true },
	ORG = { "SmoothPlastic", 246, 112, 30, 0.00, 0.00, false, true },
	PAV = { "Pavement", 124, 122, 116, 0.00, 0.00, false, false },
	PBD = { "SmoothPlastic", 216, 206, 186, 0.00, 0.00, false, true },
	PGR = { "SmoothPlastic", 112, 46, 40, 0.00, 0.00, false, true },
	POL = { "SmoothPlastic", 150, 200, 220, 0.00, 0.00, false, false },
	RAL = { "Glass", 200, 220, 228, 0.60, 0.05, true, false },
	RDL = { "SmoothPlastic", 170, 120, 60, 0.00, 0.00, false, true },
	RED = { "SmoothPlastic", 196, 30, 36, 0.00, 0.00, false, true },
	RES = { "SmoothPlastic", 228, 218, 198, 0.00, 0.00, false, true },
	ROF = { "Concrete", 150, 150, 146, 0.00, 0.00, false, false },
	SED = { "SmoothPlastic", 236, 236, 230, 0.00, 0.00, false, true },
	SEW = { "Glass", 88, 124, 110, 0.00, 0.10, false, true },
	SGN = { "SmoothPlastic", 30, 32, 36, 0.00, 0.00, false, true },
	SH1 = { "SmoothPlastic", 236, 206, 166, 0.00, 0.00, false, false },
	SH2 = { "SmoothPlastic", 206, 218, 228, 0.00, 0.00, false, false },
	SOL = { "Glass", 40, 54, 86, 0.00, 0.20, false, false },
	SPA = { "Metal", 198, 170, 124, 0.00, 0.00, false, true },
	SPB = { "Metal", 206, 208, 212, 0.00, 0.00, false, true },
	STL = { "Metal", 160, 162, 166, 0.00, 0.00, false, true },
	STP = { "DiamondPlate", 96, 98, 104, 0.00, 0.00, false, true },
	TEN = { "SmoothPlastic", 164, 82, 60, 0.00, 0.00, false, false },
	TER = { "SmoothPlastic", 134, 86, 66, 0.00, 0.00, false, true },
	WAT = { "Glass", 64, 170, 210, 0.25, 0.10, false, false },
	WLT = { "SmoothPlastic", 246, 246, 244, 0.00, 0.00, false, true },
	WOD = { "WoodPlanks", 150, 104, 70, 0.00, 0.00, true, true },
}
M.GROUPS = GROUPS
M.BASE = 28.8
M.PLANE = { 28.8747, -0.00652, -0.00118 }

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function M.parse(name: string)
	local grp, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%w+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not grp then
		return nil
	end
	return grp, id, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

function M.place(holding: Instance, folder: Instance, modelName: string): number
	local old = folder:FindFirstChild(modelName)
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = modelName
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
	local n = 0
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local grp, id, c, size = M.parse(d.Name)
			if not grp and d.Parent then
				grp, id, c, size = M.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			local spec = grp and GROUPS[grp]
			if spec then
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = grp
				q.Size = size
				q.CFrame = CFrame.new(c)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.TextureID = ""
				q.Material = Enum.Material[spec[1]]
				q.Color = Color3.fromRGB(spec[2], spec[3], spec[4])
				q.Transparency = spec[5]
				q.Reflectance = spec[6]
				q.DoubleSided = spec[7]
				q.CastShadow = spec[8]
				pcall(function()
					q.RenderFidelity = Enum.RenderFidelity.Automatic
				end)
				q.Parent = model
				n += 1
				if n % 20 == 0 then
					task.wait()
				end
			end
		end
	end
	model.Parent = folder
	return n
end

local function base(x: number, z: number, plane: { number }?): number
	local p = plane or M.PLANE
	if p then
		return math.max(M.BASE, p[1] + p[2] * (x - 32600) + p[3] * (z + 1350))
	end
	return M.BASE
end

local function boardPart(name, cx, cz, y, w, h, nx, ny, parent)
	-- a thin part facing the model-coords normal (nx, ny): world normal (nx, 0, -ny)
	local X, Z = 32600 + cx, -1350 - cy
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = Vector3.new(w, h, 0.2)
	local look = Vector3.new(nx, 0, -ny)
	local pos = Vector3.new(X, y + h / 2, Z)
	p.CFrame = CFrame.lookAt(pos, pos + look)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function M.boards(list: { any }, images: { [string]: number }, folder: Instance, plane: { number }?): number
	local n = 0
	for _, b in list do
		local cx, cy = b.c[1], b.c[2]
		local y = base(32600 + cx, -1350 - cy, plane) + b.z0
		local frame = b.frame or 0
		if frame > 0 then
			local f = boardPart("BoardFrame", cx - b.n[1] * 0.05, cy - b.n[2] * 0.05, y - frame, b.w + 2 * frame, b.h + 2 * frame, b.n[1], b.n[2], folder)
			f.Material = Enum.Material.SmoothPlastic
			f.Color = Color3.fromRGB(226, 226, 222)
		end
		local p = boardPart("Board", cx + b.n[1] * 0.1, cy + b.n[2] * 0.1, y, b.w, b.h, b.n[1], b.n[2], folder)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.new(0, 0, 0)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 20
		sg.LightInfluence = 0.15
		sg.Brightness = 1.2
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = "rbxassetid://" .. tostring(images[b.img])
		img.Parent = sg
		sg.Parent = p
		n += 1
	end
	return n
end

function M.signs(list: { any }, folder: Instance, plane: { number }?): number
	local colours = {
		Color3.fromRGB(255, 255, 255), Color3.fromRGB(246, 206, 120), Color3.fromRGB(255, 120, 90), Color3.fromRGB(150, 220, 255),
	}
	local n = 0
	for i, s in list do
		local cx, cy = s.c[1], s.c[2]
		local y = base(32600 + cx, -1350 - cy, plane) + s.z0
		local p = boardPart("ShopSign", cx, cy, y, s.w, s.h, s.n[1], s.n[2], folder)
		p.Transparency = 1
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 24
		sg.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBold
		t.TextScaled = true
		t.Text = s.text
		t.TextColor3 = colours[(i % #colours) + 1]
		t.Parent = sg
		sg.Parent = p
		n += 1
	end
	return n
end

function M.lights(list: { any }, folder: Instance, plane: { number }?, kinds: { [string]: boolean }?): number
	local spec = {
		mall = { 22, 0.9, Color3.fromRGB(255, 236, 206) },
		atrium = { 30, 1.0, Color3.fromRGB(255, 244, 226) },
		shop = { 14, 0.7, Color3.fromRGB(255, 240, 214) },
		lobby = { 26, 1.2, Color3.fromRGB(255, 240, 214) },
		soffit = { 16, 0.8, Color3.fromRGB(255, 226, 180) },
		street = { 34, 1.0, Color3.fromRGB(236, 244, 255) },
	}
	local n = 0
	for _, l in list do
		if not kinds or kinds[l.kind] then
			local s = spec[l.kind] or spec.mall
			local X, Z = 32600 + l.p[1], -1350 - l.p[2]
			local p = Instance.new("Part")
			p.Name = "Light_" .. l.kind
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Transparency = 1
			p.Size = Vector3.new(0.2, 0.2, 0.2)
			p.Position = Vector3.new(X, base(X, Z, plane) + l.p[3], Z)
			local pl = Instance.new("PointLight")
			pl.Range = s[1]
			pl.Brightness = s[2]
			pl.Color = s[3]
			pl.Shadows = false
			pl.Parent = p
			p.Parent = folder
			n += 1
		end
	end
	return n
end

return M
