--[[
	JunctionCentral21Nov.luau (Studio, Edit; coordinator 21 Nov leftovers: "Junction City canopy lights and The
	Central's pavilion").
	* Junction City (refs_21nov/0820_19s.jpg): a deep canopy over the pavement along the mall's north face (Bogyoke Aung
	  San Rd), its underside full of short slanted white LED bars. The mall is the two tall shells
	  Buildings.Shell.Cell_19_24.KW6 (259 tall); for each, the face whose normal points most to -Z (north) gets one
	  slab 1.6 thick x 14 deep, bottom at y 54 (above the JunctionCity_NameWall, 44..52; pavement 35), CanCollide off.
	  The lights are one SurfaceGui on the slab's Bottom (LightInfluence 0, two rows of slanted bars): no Light objects.
	* The Central (refs_21nov/0799_36s.jpg): the round podium pavilion with a glowing white crown band and vertical gold
	  light strips. A free grass spot was probed (GetPartBoundsInBox 36 x 80 x 36, ground 44.5 by raycast) at
	  (35068, 25307) (GetPartBoundsInRadius 23 empty), between the walk-ups and The Central's tower (shell KWG 308
	  tall at 35121, 25218), east of the THE CENTRAL letters. Drum 44 across, 30 tall: lower shopfront ring and crown are Neon tagged LampGlow (WorldFx: Neon at
	  night, SmoothPlastic by day), 12 gold strips the same; 15 parts, CanCollide on for the body only.
	Both go in Workspace.Yangon1to1.Landmarks.IrlBuild21Nov (JunctionCityCanopy, TheCentralPavilion). M.build(), M.undo().
]]
local CS = game:GetService("CollectionService")
local M = {}
local CANOPY_Y, DEPTH, THICK = 54, 14, 1.6
local CENTRAL = Vector3.new(35068, 44.5, 25307)

local function root()
	local lm = workspace.Yangon1to1.Landmarks
	local f = lm:FindFirstChild("IrlBuild21Nov") or Instance.new("Folder")
	f.Name = "IrlBuild21Nov"
	f.Parent = lm
	return f
end

local function part(parent, name, cls, cf, size, color, glow)
	local p = Instance.new(cls)
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if glow then
		CS:AddTag(p, "LampGlow")
	end
	p.Parent = parent
	return p
end

local function canopyLights(slab)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Bottom
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 6
	g.LightInfluence = 0
	g.Brightness = 3
	g.MaxDistance = 700
	local n = math.floor(slab.Size.X / 9)
	for _, ys in { 0.3, 0.7 } do
		for i = 1, n do
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale((i - 0.5) / n, ys)
			f.Size = UDim2.fromOffset(26, 3)
			f.Rotation = -35
			f.BorderSizePixel = 0
			f.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
			f.Parent = g
		end
	end
	g.Parent = slab
end

function M.build()
	M.undo()
	local r = root()
	-- Junction City canopy
	local jc = Instance.new("Folder")
	jc.Name = "JunctionCityCanopy"
	for _, s in workspace.Yangon1to1.Buildings.Shell.Cell_19_24:GetChildren() do
		if s:IsA("BasePart") and s.Name == "KW6" and s.Size.Y > 250 then
			local best, half, len = nil, 0, 0
			for _, ax in { { s.CFrame.RightVector, s.Size.X, s.Size.Z }, { -s.CFrame.RightVector, s.Size.X, s.Size.Z },
				{ s.CFrame.LookVector, s.Size.Z, s.Size.X }, { -s.CFrame.LookVector, s.Size.Z, s.Size.X } } do
				if not best or ax[1].Z < best.Z then
					best, half, len = ax[1], ax[2] / 2, ax[3]
				end
			end
			local face = s.Position + best * half
			local at = Vector3.new(face.X, CANOPY_Y + THICK / 2, face.Z) + best * (DEPTH / 2)
			local along = Vector3.yAxis:Cross(best).Unit
			local slab = part(jc, "Canopy", "Part", CFrame.fromMatrix(at, along, Vector3.yAxis), Vector3.new(len, THICK, DEPTH),
				Color3.fromRGB(214, 214, 208), false)
			canopyLights(slab)
			-- thin glowing edge along the canopy front
			part(jc, "CanopyEdge", "Part", CFrame.fromMatrix(at + best * (DEPTH / 2 + 0.15), along, Vector3.yAxis),
				Vector3.new(len, 0.5, 0.3), Color3.fromRGB(240, 244, 250), true)
		end
	end
	jc.Parent = r
	-- The Central pavilion
	local tc = Instance.new("Model")
	tc.Name = "TheCentralPavilion"
	local up = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> vertical
	local function drum(name, y0, h, d, color, glow)
		return part(tc, name, "Part", CFrame.new(CENTRAL + Vector3.new(0, y0 + h / 2, 0)) * up, Vector3.new(h, d, d), color, glow)
	end
	for _, p in { drum("Shopfront", -1, 9, 43.6, Color3.fromRGB(255, 226, 160), true),
		drum("Body", 8, 14, 44, Color3.fromRGB(196, 190, 178), false),
		drum("Crown", 22, 7, 45, Color3.fromRGB(255, 248, 232), true) } do
		p.Shape = Enum.PartType.Cylinder
	end
	tc.Body.CanCollide = true
	tc.Body.CanQuery = true
	for i = 0, 11 do
		local a = i * math.pi / 6
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local at = CENTRAL + Vector3.new(0, 8 + 7, 0) + dir * 22.1
		part(tc, "GoldStrip", "Part", CFrame.lookAt(at, at + dir), Vector3.new(0.6, 13.5, 0.5), Color3.fromRGB(255, 204, 120), true)
	end
	tc.Parent = r
	local n = #tc:GetChildren() + #jc:GetChildren()
	return n
end

function M.undo()
	local r = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlBuild21Nov")
	if r then
		for _, name in { "JunctionCityCanopy", "TheCentralPavilion" } do
			local f = r:FindFirstChild(name)
			if f then
				f:Destroy()
			end
		end
	end
end

return M
