--[[
	ChineseTemple21Nov.luau (Studio, Edit; owner 21 Nov: "do these: ... the Chinese temple"; reference frame
	City Legends/refs_21nov/0800_1s.jpg, seen from the flyover just before the Hanthawaddy Roundabout frames 0802 / 0803).
	Where: OSM way 520945700 "Chinese Temple" (6 levels, 96.1316 E 16.8189 N): the game already has it as the kit walkup
	shell Buildings.Shell.Cell_15_16.KW4 (main block 103 x 66 x 75, roof at y 122.45). This adds the temple's roof-top
	pavilion on that roof (the shell is not touched): a green glazed tile skirt with a red fascia round the roof edge,
	the yellow lattice balustrade, the white pavilion with octagonal green windows and a gold name plaque, two tiers of
	green tile roof with red eaves and upturned red corners.
	~40 parts, all CanCollide / CanQuery off (roof dressing nobody drives on). Faces butt or cross at angles: no coplanar
	visible faces. M.build() -> Workspace.Yangon1to1.Landmarks.IrlBuild21Nov.ChineseTempleHanthawaddy; M.undo().
]]
local M = {}
M.SHELL = { pos = Vector3.new(27294.6, 122.45, 30353.3), look = Vector3.new(-0.991, 0, 0.134), w = 103.3, d = 74.8 }

local GREEN = Color3.fromRGB(38, 76, 54)
local RED = Color3.fromRGB(168, 52, 40)
local YELLOW = Color3.fromRGB(226, 190, 80)
local WHITE = Color3.fromRGB(236, 234, 226)
local GOLD = Color3.fromRGB(214, 172, 64)

local model, F
local function part(name, cls, lcf, size, color)
	local p = Instance.new(cls)
	p.Name = name
	p.Size = size
	p.CFrame = F * lcf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- a sloped tile skirt round a rectangle (half sizes hx, hz) at height y: each side leans out and down by `ang`
local function skirt(hx, hz, y, out, ang, thick, color, trim)
	for _, s in { { hz, hx, 0 }, { hx, hz, 90 } } do -- {offset of the side, half length along it, yaw}
		local half, other, yaw = s[1], s[2], s[3]
		for _, sign in { 1, -1 } do
			local len = 2 * (other + out) -- runs along the side, past the corners (sides cross at an angle there)
			local slope = out / math.cos(math.rad(ang))
			local base = CFrame.Angles(0, math.rad(yaw), 0) * CFrame.new(0, y, sign * (half + out / 2))
			local tilt = CFrame.Angles(math.rad(sign * ang), 0, 0)
			part("Tile", "Part", base * tilt, Vector3.new(len, thick, slope), color)
			if trim then
				part("Fascia", "Part", base * CFrame.new(0, -math.tan(math.rad(ang)) * out / 2 - thick, sign * out / 2),
					Vector3.new(len, 1.2, 0.8), RED)
			end
		end
	end
end

-- a gable roof tier: two wedges back to back along X, an eave plate with red underside, four upturned corners
local function tier(y, hx, hz, rise, eave)
	part("Eave", "Part", CFrame.new(0, y + 0.6, 0), Vector3.new(2 * (hx + eave), 1.2, 2 * (hz + eave)), GREEN)
	part("EaveRed", "Part", CFrame.new(0, y - 0.3, 0), Vector3.new(2 * (hx + eave) - 1.6, 0.6, 2 * (hz + eave) - 1.6), RED)
	for _, sign in { 1, -1 } do
		local cf = CFrame.new(0, y + 1.2 + rise / 2, sign * (hz + eave - 1) / 2)
			* CFrame.Angles(0, if sign > 0 then math.pi else 0, 0)
		part("Roof", "WedgePart", cf, Vector3.new(2 * (hx + eave) - 2, rise, hz + eave - 1), GREEN)
	end
	part("Ridge", "Part", CFrame.new(0, y + 1.2 + rise + 0.6, 0), Vector3.new(2 * (hx + eave) - 2, 1.2, 1.6), RED)
	for _, sx in { 1, -1 } do
		for _, sz in { 1, -1 } do
			local at = Vector3.new(sx * (hx + eave), y + 1.6, sz * (hz + eave))
			local out = Vector3.new(sx, 0, sz).Unit
			-- small red wedge pointing out of the corner, its slope rising outward (the upturned eave)
			part("Curl", "WedgePart", CFrame.lookAt(at - out * 1.5, at - out * 3) * CFrame.Angles(0, 0, 0), Vector3.new(1.6, 2.4, 4), RED)
		end
	end
end

local function windows(face: Enum.NormalId, wide: number)
	local p = model:FindFirstChild("Pavilion")
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 10
	g.LightInfluence = 1
	g.Parent = p
	local function oct(xs)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(xs, 0.5)
		f.Size = UDim2.fromOffset(84, 84)
		f.BackgroundColor3 = Color3.fromRGB(36, 74, 52)
		f.Rotation = 22.5
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.29, 0) -- near-octagon
		c.Parent = f
		local s = Instance.new("UIStroke")
		s.Color = GOLD
		s.Thickness = 5
		s.Parent = f
		f.Parent = g
	end
	if wide > 40 then
		oct(0.2)
		oct(0.8)
		local door = Instance.new("Frame")
		door.AnchorPoint = Vector2.new(0.5, 1)
		door.Position = UDim2.fromScale(0.5, 1)
		door.Size = UDim2.new(0.3, 0, 0.62, 0)
		door.BackgroundColor3 = Color3.fromRGB(110, 34, 28)
		door.BorderSizePixel = 0
		door.Parent = g
		local plaque = Instance.new("Frame")
		plaque.AnchorPoint = Vector2.new(0.5, 0)
		plaque.Position = UDim2.fromScale(0.5, 0.08)
		plaque.Size = UDim2.new(0.22, 0, 0.2, 0)
		plaque.BackgroundColor3 = Color3.fromRGB(70, 40, 24)
		plaque.Parent = g
		local s = Instance.new("UIStroke")
		s.Color = GOLD
		s.Thickness = 4
		s.Parent = plaque
	else
		oct(0.5)
	end
end

function M.build()
	local lm = workspace.Yangon1to1.Landmarks
	local root = lm:FindFirstChild("IrlBuild21Nov") or Instance.new("Folder")
	root.Name = "IrlBuild21Nov"
	root.Parent = lm
	local old = root:FindFirstChild("ChineseTempleHanthawaddy")
	if old then
		old:Destroy()
	end
	model = Instance.new("Model")
	model.Name = "ChineseTempleHanthawaddy"
	local s = M.SHELL
	F = CFrame.lookAt(s.pos, s.pos + s.look) -- local -Z = shell look; local X across the 74.8 side
	-- shell size 103.3 along its local X: here local X = shell right, so hx = w/2 runs along RightVector
	local hx, hz = s.w / 2, s.d / 2
	-- roof-edge skirt (green glazed tiles, red fascia) and the balustrade set back 3 studs
	skirt(hx, hz, -1.4, 6, 24, 0.8, GREEN, true)
	local bx, bz, th = hx - 3, hz - 3, 0.6
	part("Rail", "Part", CFrame.new(0, 1.8, bz), Vector3.new(2 * bx, 3.6, th), YELLOW)
	part("Rail", "Part", CFrame.new(0, 1.8, -bz), Vector3.new(2 * bx, 3.6, th), YELLOW)
	part("Rail", "Part", CFrame.new(bx - th / 2, 1.8, 0), Vector3.new(th, 3.6, 2 * bz - 2 * th), YELLOW)
	part("Rail", "Part", CFrame.new(-bx + th / 2, 1.8, 0), Vector3.new(th, 3.6, 2 * bz - 2 * th), YELLOW)
	-- the white pavilion
	local pw, pd, ph = 56, 38, 18
	part("Pavilion", "Part", CFrame.new(0, ph / 2, 0), Vector3.new(pw, ph, pd), WHITE)
	windows(Enum.NormalId.Front, pw)
	windows(Enum.NormalId.Back, pw)
	windows(Enum.NormalId.Left, pd)
	windows(Enum.NormalId.Right, pd)
	tier(ph, pw / 2, pd / 2, 6, 7)
	-- upper drum and the top tier
	part("Drum", "Part", CFrame.new(0, ph + 7.2 + 4, 0), Vector3.new(30, 8, 20), WHITE)
	tier(ph + 15.2, 15, 10, 6, 6)
	model.Parent = root
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

function M.undo()
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlBuild21Nov")
	local m = f and f:FindFirstChild("ChineseTempleHanthawaddy")
	if m then
		m:Destroy()
	end
end

return M
