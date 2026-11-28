--[[
	SedonaSign (2026-11-28, owner: "the Sedona exterior and its SEDONA sign" are inaccurate). The roadside sign on Kabar
	Aye Pagoda Road wore the old blue board with white letters (part of the Sedona meshes: group BLU + letters). The
	hotel's current logo (sedonamyanmar.com, files of 2023-12 and 2026-06: slate and taupe serif SEDONA with an orchid in
	the O, YANGON under it) goes on a white board that encloses the old one. Real brand signs are allowed for Sedona
	(owner, see Games/CityLegends/CLAUDE.md). Face picture: imports/signs/sedona_sign_face.png = Image 131324883898621.
	The real board's shape is not known from a dated photo: only the face is certain.
	Run in Studio Edit: require(ClaudeTools.SedonaSign:Clone()).build() / .undo()
]]
local M = {}
local FACE = "rbxassetid://131324883898621"
local NAME = "Sedona_RoadSign"

local function folder(): Instance
	local lm = workspace.Yangon1to1.Landmarks
	local f = lm:FindFirstChild("IrlSigns28Nov")
	if not f then
		f = Instance.new("Folder")
		f.Name = "IrlSigns28Nov"
		f.Parent = lm
	end
	return f
end

function M.undo(): string
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlSigns28Nov")
	local old = f and f:FindFirstChild(NAME)
	if old then
		old:Destroy()
		return "removed"
	end
	return "nothing to remove"
end

function M.build(): string
	M.undo()
	-- the old board: the BLU mesh of Landmarks.Sedona.Meshes (2 x 9 x 27, faces along X)
	local blu: BasePart? = nil
	for _, d in workspace.Yangon1to1.Landmarks.Sedona.Meshes:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == "BLU" then
			blu = d
		end
	end
	if not blu then
		return "no BLU sign board found"
	end
	local m = Instance.new("Model")
	m.Name = NAME
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Anchored = true
	board.Size = Vector3.new(blu.Size.X + 0.8, blu.Size.Y + 1.2, blu.Size.Z + 1.2)
	board.CFrame = blu.CFrame * CFrame.new(0, 3.2, 0) -- (raised: the road fence hid the YANGON line)
	board.Color = Color3.fromRGB(250, 250, 248)
	board.Material = Enum.Material.SmoothPlastic
	board.CastShadow = false
	board.Parent = m
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = 36
		g.LightInfluence = 0.6
		g.MaxDistance = 700
		g.Parent = board
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundColor3 = board.Color
		img.BorderSizePixel = 0
		img.Image = FACE
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = g
	end
	-- a slim taupe cap and a plinth down to the lawn, in the logo's colours
	local taupe = Color3.fromRGB(160, 142, 126)
	local function slab(name: string, y0: number, y1: number)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.Size = Vector3.new(board.Size.X + 0.5, y1 - y0, board.Size.Z + 0.5)
		p.CFrame = CFrame.new(board.Position.X, (y0 + y1) / 2, board.Position.Z) * board.CFrame.Rotation
		p.Color = taupe
		p.Material = Enum.Material.SmoothPlastic
		p.CastShadow = false
		p.Parent = m
	end
	local top, bottom = board.Position.Y + board.Size.Y / 2, board.Position.Y - board.Size.Y / 2
	slab("Cap", top, top + 0.3)
	slab("Plinth", blu.Position.Y - blu.Size.Y / 2 - 0.3, bottom)
	m.Parent = folder()
	return string.format("sign built at (%.0f, %.0f, %.0f), board %s", board.Position.X, board.Position.Y, board.Position.Z, tostring(board.Size))
end

return M
