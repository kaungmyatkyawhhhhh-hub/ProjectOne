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

local CollectionService = game:GetService("CollectionService")

local M = {}

local GROUPS = {
	AMB = { "Neon", 220, 170, 90, 0.00, 0.00, false, false },
	BKG = { "SmoothPlastic", 15, 15, 18, 0.00, 0.15, false, true },
	BLU = { "SmoothPlastic", 40, 62, 150, 0.00, 0.00, false, true },
	BOR = { "SmoothPlastic", 205, 90, 50, 0.00, 0.00, false, true },
	BRD = { "SmoothPlastic", 190, 140, 80, 0.00, 0.00, false, false },
	BTP = { "SmoothPlastic", 35, 35, 35, 0.00, 0.10, false, true },
	CAR = { "SmoothPlastic", 200, 160, 102, 0.00, 0.08, false, false },
	CEL = { "SmoothPlastic", 238, 238, 236, 0.00, 0.00, false, false },
	CHR = { "SmoothPlastic", 92, 86, 76, 0.00, 0.00, false, true },
	CRM = { "SmoothPlastic", 255, 238, 200, 0.00, 0.00, false, true },
	CRN = { "SmoothPlastic", 248, 255, 254, 0.00, 0.04, false, true },
	CRT = { "SmoothPlastic", 56, 120, 92, 0.00, 0.00, false, false },
	CRY = { "Glass", 236, 240, 244, 0.20, 0.25, false, false },
	CUS = { "SmoothPlastic", 140, 140, 138, 0.00, 0.00, false, true },
	DRK = { "SmoothPlastic", 40, 36, 32, 0.00, 0.06, false, true },
	DRV = { "Asphalt", 64, 64, 66, 0.00, 0.00, false, false },
	EAV = { "SmoothPlastic", 70, 64, 48, 0.00, 0.00, false, true },
	ESC = { "SmoothPlastic", 96, 58, 42, 0.00, 0.05, false, true },
	FAS = { "SmoothPlastic", 252, 255, 254, 0.00, 0.03, false, true },
	FEN = { "DiamondPlate", 40, 58, 44, 0.55, 0.00, true, false },
	GFA = { "SmoothPlastic", 236, 236, 234, 0.00, 0.00, false, false },
	GLA = { "Glass", 85, 90, 83, 0.00, 0.22, false, true },
	GLB = { "Glass", 74, 75, 65, 0.00, 0.25, false, true },
	GLD = { "SmoothPlastic", 162, 144, 125, 0.00, 0.10, false, true },
	GLL = { "Glass", 150, 146, 132, 0.00, 0.12, false, true },
	GLM = { "Glass", 97, 111, 113, 0.00, 0.20, false, true },
	GLP = { "Glass", 62, 73, 71, 0.00, 0.20, true, true },
	GLS = { "Glass", 176, 196, 204, 0.55, 0.05, true, false },
	GLU = { "Glass", 102, 107, 109, 0.00, 0.22, false, true },
	GRD = { "SmoothPlastic", 150, 134, 98, 0.00, 0.12, false, false },
	GRN = { "SmoothPlastic", 252, 255, 250, 0.00, 0.00, false, true },
	GST = { "SmoothPlastic", 80, 80, 80, 0.00, 0.00, false, true },
	HDG = { "Grass", 64, 108, 44, 0.00, 0.00, false, true },
	KAC = { "SmoothPlastic", 252, 255, 248, 0.00, 0.00, false, true },
	KAR = { "SmoothPlastic", 151, 92, 69, 0.00, 0.00, true, true },
	KAW = { "SmoothPlastic", 72, 137, 239, 0.00, 0.00, true, true },
	KBC = { "Glass", 65, 92, 136, 0.00, 0.12, false, true },
	KCB = { "Metal", 59, 62, 65, 0.00, 0.00, false, true },
	KCG = { "SmoothPlastic", 73, 77, 75, 0.00, 0.00, false, true },
	KCO = { "SmoothPlastic", 186, 180, 165, 0.00, 0.00, false, true },
	KCR = { "SmoothPlastic", 249, 252, 255, 0.00, 0.00, false, true },
	KCU = { "CorrodedMetal", 177, 111, 74, 0.00, 0.00, false, true },
	KCW = { "SmoothPlastic", 255, 252, 239, 0.00, 0.00, false, true },
	KDS = { "SmoothPlastic", 215, 217, 210, 0.00, 0.00, false, true },
	KFR = { "SmoothPlastic", 234, 233, 218, 0.00, 0.00, false, true },
	KGB = { "SmoothPlastic", 79, 73, 64, 0.40, 0.00, false, false },
	KGL = { "Glass", 45, 47, 47, 0.00, 0.15, false, true },
	KGM1 = { "SmoothPlastic", 72, 68, 62, 0.80, 0.00, false, false },
	KGM2 = { "SmoothPlastic", 72, 68, 62, 0.65, 0.00, false, false },
	KGM3 = { "SmoothPlastic", 65, 61, 56, 0.50, 0.00, false, false },
	KGR = { "Metal", 59, 62, 65, 0.00, 0.00, false, true },
	KGS = { "SmoothPlastic", 100, 125, 67, 0.00, 0.00, false, true },
	KGT = { "Metal", 34, 55, 48, 0.00, 0.00, false, true },
	KGU = { "CorrodedMetal", 255, 169, 101, 0.00, 0.00, false, true },
	KL1 = { "SmoothPlastic", 197, 73, 68, 0.00, 0.00, true, false },
	KL2 = { "SmoothPlastic", 72, 96, 155, 0.00, 0.00, true, false },
	KL3 = { "SmoothPlastic", 223, 194, 68, 0.00, 0.00, true, false },
	KL4 = { "SmoothPlastic", 252, 255, 248, 0.00, 0.00, true, false },
	KL5 = { "SmoothPlastic", 234, 172, 182, 0.00, 0.00, true, false },
	KL6 = { "SmoothPlastic", 130, 148, 168, 0.00, 0.00, true, false },
	KNT = { "SmoothPlastic", 72, 148, 69, 0.30, 0.00, true, false },
	KPL = { "SmoothPlastic", 73, 114, 52, 0.00, 0.00, false, true },
	KPP = { "SmoothPlastic", 82, 137, 218, 0.00, 0.00, false, true },
	KPV = { "SmoothPlastic", 162, 154, 136, 0.00, 0.00, false, true },
	KRB = { "SmoothPlastic", 107, 154, 231, 0.00, 0.00, true, true },
	KRD = { "SmoothPlastic", 61, 61, 63, 0.00, 0.00, false, true },
	KRF = { "CorrodedMetal", 156, 104, 83, 0.00, 0.00, true, true },
	KRG = { "CorrodedMetal", 166, 166, 158, 0.00, 0.00, true, true },
	KRL = { "Glass", 188, 240, 243, 0.60, 0.05, true, false },
	KRS = { "SmoothPlastic", 162, 160, 153, 0.00, 0.00, false, true },
	KRT = { "SmoothPlastic", 179, 101, 69, 0.00, 0.00, false, true },
	KS1 = { "SmoothPlastic", 200, 54, 47, 0.00, 0.00, false, true },
	KS2 = { "SmoothPlastic", 220, 172, 18, 0.00, 0.00, false, true },
	KS3 = { "SmoothPlastic", 35, 86, 182, 0.00, 0.00, false, true },
	KS4 = { "SmoothPlastic", 219, 97, 65, 0.00, 0.00, false, true },
	KSH = { "WoodPlanks", 209, 133, 76, 0.00, 0.00, false, true },
	KSH2 = { "WoodPlanks", 182, 230, 176, 0.00, 0.00, false, true },
	KSH3 = { "SmoothPlastic", 98, 160, 218, 0.00, 0.00, false, true },
	KSH4 = { "SmoothPlastic", 196, 123, 56, 0.00, 0.00, false, true },
	KSI = { "SmoothPlastic", 58, 51, 43, 0.00, 0.00, false, true },
	KSK = { "SmoothPlastic", 215, 148, 94, 0.00, 0.00, false, true },
	KST = { "SmoothPlastic", 62, 60, 56, 0.45, 0.00, false, false },
	KSU = { "SmoothPlastic", 100, 96, 88, 0.55, 0.00, false, false },
	KSV = { "SmoothPlastic", 230, 204, 113, 0.00, 0.00, false, true },
	KSW = { "SmoothPlastic", 252, 255, 245, 0.00, 0.00, false, true },
	KTK = { "SmoothPlastic", 24, 24, 26, 0.00, 0.00, false, true },
	KTL = { "SmoothPlastic", 64, 95, 48, 0.00, 0.00, true, true },
	KTP = { "SmoothPlastic", 61, 116, 199, 0.00, 0.00, true, true },
	KTW = { "SmoothPlastic", 99, 85, 73, 0.00, 0.00, false, true },
	KTY = { "SmoothPlastic", 20, 20, 20, 0.00, 0.00, false, true },
	KW0 = { "SmoothPlastic", 252, 255, 250, 0.00, 0.00, false, true },
	KW1 = { "SmoothPlastic", 255, 215, 153, 0.00, 0.00, false, true },
	KW2 = { "SmoothPlastic", 178, 242, 255, 0.00, 0.00, false, true },
	KW3 = { "SmoothPlastic", 199, 168, 130, 0.00, 0.00, false, true },
	KW4 = { "SmoothPlastic", 226, 248, 255, 0.00, 0.00, false, true },
	KW5 = { "SmoothPlastic", 255, 197, 187, 0.00, 0.00, false, true },
	KW6 = { "SmoothPlastic", 255, 252, 243, 0.00, 0.00, false, true },
	KW7 = { "SmoothPlastic", 208, 255, 165, 0.00, 0.00, false, true },
	KWB = { "SmoothPlastic", 173, 209, 250, 0.00, 0.00, false, true },
	KWC = { "SmoothPlastic", 144, 145, 136, 0.00, 0.00, false, true },
	KWD = { "SmoothPlastic", 146, 104, 68, 0.00, 0.00, false, true },
	KWD2 = { "Concrete", 181, 172, 162, 0.00, 0.00, false, true },
	KWG = { "SmoothPlastic", 162, 160, 150, 0.00, 0.00, false, true },
	KWI = { "SmoothPlastic", 22, 22, 22, 0.00, 0.00, true, false },
	LAW = { "Grass", 104, 150, 66, 0.00, 0.00, false, false },
	LEF = { "SmoothPlastic", 60, 110, 60, 0.00, 0.00, false, false },
	LIT = { "Neon", 198, 196, 188, 0.00, 0.00, false, false },
	LQG = { "SmoothPlastic", 40, 140, 80, 0.00, 0.05, false, false },
	LQR = { "SmoothPlastic", 170, 40, 35, 0.00, 0.05, false, false },
	MAR = { "SmoothPlastic", 218, 212, 200, 0.00, 0.08, false, false },
	MBM = { "SmoothPlastic", 60, 45, 35, 0.00, 0.00, false, true },
	MCO = { "SmoothPlastic", 70, 52, 40, 0.00, 0.00, false, false },
	MDK = { "SmoothPlastic", 235, 233, 228, 0.00, 0.05, false, true },
	MEL = { "SmoothPlastic", 250, 252, 250, 0.00, 0.00, false, true },
	MFL = { "SmoothPlastic", 215, 205, 190, 0.00, 0.04, false, false },
	MUL = { "SmoothPlastic", 52, 52, 44, 0.00, 0.00, false, true },
	MUW = { "SmoothPlastic", 236, 234, 228, 0.00, 0.00, false, true },
	MWH = { "SmoothPlastic", 232, 230, 225, 0.00, 0.06, false, false },
	NAV = { "SmoothPlastic", 40, 50, 80, 0.00, 0.00, false, true },
	NWA = { "Neon", 196, 148, 84, 1.00, 0.00, false, false, "night" },
	NWC = { "Neon", 146, 178, 180, 1.00, 0.00, false, false, "night" },
	NWH = { "Neon", 204, 160, 104, 1.00, 0.00, false, false, "night" },
	NWY = { "Neon", 206, 192, 144, 1.00, 0.00, false, false, "night" },
	OAK = { "SmoothPlastic", 200, 165, 115, 0.00, 0.00, false, true },
	OCH = { "SmoothPlastic", 190, 150, 80, 0.00, 0.00, false, true },
	ORC = { "SmoothPlastic", 245, 245, 240, 0.00, 0.00, false, false },
	ORG = { "SmoothPlastic", 255, 91, 24, 0.00, 0.00, false, true, "glow", 236, 84, 30 },
	PAV = { "Pavement", 124, 122, 116, 0.00, 0.00, false, false },
	PBD = { "SmoothPlastic", 255, 254, 245, 0.00, 0.00, false, true },
	PGR = { "SmoothPlastic", 100, 62, 40, 0.00, 0.08, false, true },
	PLM = { "SmoothPlastic", 60, 110, 70, 0.00, 0.00, false, false },
	POL = { "SmoothPlastic", 150, 200, 220, 0.00, 0.00, false, false },
	PRA = { "SmoothPlastic", 186, 62, 64, 0.00, 0.00, false, false },
	PRB = { "SmoothPlastic", 58, 96, 160, 0.00, 0.00, false, false },
	PRC = { "SmoothPlastic", 226, 210, 180, 0.00, 0.00, false, false },
	PRD = { "SmoothPlastic", 40, 42, 48, 0.00, 0.00, false, false },
	PRE = { "SmoothPlastic", 78, 140, 96, 0.00, 0.00, false, false },
	PRF = { "SmoothPlastic", 236, 178, 58, 0.00, 0.00, false, false },
	RAL = { "Glass", 176, 204, 196, 0.60, 0.05, true, false },
	RDL = { "SmoothPlastic", 170, 120, 60, 0.00, 0.00, false, true, "glow", 220, 204, 176 },
	RED = { "SmoothPlastic", 196, 30, 36, 0.00, 0.00, false, true },
	RES = { "SmoothPlastic", 255, 240, 204, 0.00, 0.00, false, true },
	ROF = { "Concrete", 150, 150, 146, 0.00, 0.00, false, false },
	RTL = { "SmoothPlastic", 190, 82, 50, 0.00, 0.03, false, true },
	RUG = { "SmoothPlastic", 150, 140, 128, 0.00, 0.00, false, false },
	SAG = { "SmoothPlastic", 140, 150, 100, 0.00, 0.00, false, true },
	SBK = { "SmoothPlastic", 30, 30, 30, 0.00, 0.05, false, true },
	SED = { "SmoothPlastic", 249, 250, 250, 0.00, 0.00, false, true },
	SEW = { "Glass", 95, 111, 97, 0.00, 0.12, false, true },
	SFR = { "SmoothPlastic", 180, 90, 60, 0.00, 0.00, false, true },
	SGD = { "SmoothPlastic", 170, 130, 70, 0.00, 0.10, false, false },
	SGN = { "SmoothPlastic", 30, 32, 36, 0.00, 0.00, false, true },
	SH1 = { "SmoothPlastic", 236, 206, 166, 0.00, 0.00, false, false },
	SH2 = { "SmoothPlastic", 206, 218, 228, 0.00, 0.00, false, false },
	SIL = { "SmoothPlastic", 252, 255, 255, 0.00, 0.03, false, true },
	SOF = { "SmoothPlastic", 162, 135, 89, 0.00, 0.00, false, false },
	SOL = { "Glass", 40, 54, 86, 0.00, 0.20, false, false },
	SPA = { "SmoothPlastic", 248, 255, 254, 0.00, 0.04, false, true },
	SPB = { "SmoothPlastic", 245, 252, 255, 0.00, 0.04, false, true },
	STL = { "Metal", 160, 162, 166, 0.00, 0.00, false, true },
	STP = { "DiamondPlate", 96, 98, 104, 0.00, 0.00, false, true },
	STR = { "SmoothPlastic", 252, 255, 254, 0.00, 0.03, false, true },
	TEK = { "SmoothPlastic", 176, 120, 62, 0.00, 0.00, false, true },
	TEN = { "SmoothPlastic", 164, 82, 60, 0.00, 0.00, false, false },
	TER = { "SmoothPlastic", 138, 96, 67, 0.00, 0.00, false, true },
	TKC = { "SmoothPlastic", 170, 115, 60, 0.00, 0.00, false, false },
	TLB = { "SmoothPlastic", 60, 90, 150, 0.00, 0.03, false, false },
	TLW = { "SmoothPlastic", 240, 240, 240, 0.00, 0.03, false, false },
	TRZ = { "SmoothPlastic", 205, 205, 200, 0.00, 0.05, false, false },
	TUB = { "SmoothPlastic", 120, 125, 130, 0.00, 0.00, false, true },
	WAL = { "SmoothPlastic", 120, 80, 50, 0.00, 0.00, false, true },
	WAT = { "Glass", 64, 170, 210, 0.25, 0.10, false, false },
	WLT = { "SmoothPlastic", 255, 246, 232, 0.00, 0.00, false, true, "glow", 214, 206, 190 },
	WOD = { "WoodPlanks", 166, 124, 78, 0.00, 0.00, true, true },
	WTL = { "SmoothPlastic", 238, 238, 234, 0.00, 0.04, false, false },
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
				pcall(function() q.CollisionFidelity = Enum.CollisionFidelity.Box end) -- visual only: no hull data (2026-11-16)
				q.CanTouch = false
				q.TextureID = ""
				q.Material = Enum.Material[spec[1]]
				q.Color = Color3.fromRGB(spec[2], spec[3], spec[4])
				q.Transparency = spec[5]
				q.Reflectance = spec[6]
				q.DoubleSided = spec[7]
				q.CastShadow = spec[8]
				-- night (2026-11-16): "night" groups are lit windows (tag FacadeNight: WorldFx shows them at night only);
				-- "glow" groups are letters that light up at night (tag LandmarkGlow, NightColor = spec 10-12)
				if spec[9] == "night" then
					q.Transparency = 1
					CollectionService:AddTag(q, "FacadeNight")
				elseif spec[9] == "glow" then
					q:SetAttribute("NightColor", Color3.fromRGB(spec[10], spec[11], spec[12]))
					q:SetAttribute("DayColor", q.Color)
					q:SetAttribute("DayMaterial", spec[1])
					CollectionService:AddTag(q, "LandmarkGlow")
				end
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
		mall = { 22, 0.9, Color3.fromRGB(255, 250, 242) },
		atrium = { 30, 1.0, Color3.fromRGB(255, 252, 246) },
		shop = { 14, 0.7, Color3.fromRGB(250, 252, 255) },
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
