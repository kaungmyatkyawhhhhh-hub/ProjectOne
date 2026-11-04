--[[
	Realty
	Legends Realty, where you buy houses (owner, 2026-10-29: housing like Driving Empire's, our own
	look): a glass pavilion on the beach beside the causeway in Downtown, and a small booth where
	the causeway lands on Legends Isle. Each has an agent at a desk and a glowing blueprint table:
	E at either opens the catalogue (HousingClient). Buying and selling go through Houses.

	Built at start (not part of the baked map): the pavilion looks for a clear spot on the sand
	near the causeway, so it never lands on the beach's parasols or palms.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local EntranceRamp = require(script.Parent:WaitForChild("EntranceRamp"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))

local Realty = {}

local GLASS = Color3.fromRGB(150, 196, 220)
local WHITE = Color3.fromRGB(244, 242, 236)
local DARK = Color3.fromRGB(28, 30, 34)
local BLUEPRINT = Color3.fromRGB(70, 150, 255)
local WARM = Color3.fromRGB(255, 214, 160)

local fx: RemoteEvent? = nil

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, opts: { [string]: any }?): BasePart
	local o = opts or {}
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Transparency = o.transparency or 0
	p.CanCollide = o.collide ~= false
	if o.shape then
		p.Shape = o.shape
	end
	p.Name = o.name or "Part"
	p.Parent = parent
	return p
end

local function text(p: BasePart, face: Enum.NormalId, t: string, color: Color3, size: Vector2)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.CanvasSize = size
	sg.LightInfluence = 0
	sg.MaxDistance = 400
	sg.Parent = p
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Text = t
	l.TextColor3 = color
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Parent = sg
end

local function openFor(player: Player)
	if fx then
		fx:FireClient(player, { kind = "realty" })
	end
end

-- the agent at the desk: a smart suit, standing (Roblox's default avatar dressed up)
local function agent(parent: Instance, at: CFrame)
	task.spawn(function()
		local ok, rig = pcall(function()
			local d = Instance.new("HumanoidDescription")
			d.HeadColor = Color3.fromRGB(196, 150, 112)
			d.TorsoColor = Color3.fromRGB(34, 40, 58)
			d.LeftArmColor = Color3.fromRGB(34, 40, 58)
			d.RightArmColor = Color3.fromRGB(34, 40, 58)
			d.LeftLegColor = Color3.fromRGB(26, 28, 34)
			d.RightLegColor = Color3.fromRGB(26, 28, 34)
			return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6)
		end)
		if not ok or not rig then
			return
		end
		local model = rig :: Model
		model.Name = "RealtyAgent"
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = model:FindFirstChildOfClass("Humanoid")
		if root then
			root.Anchored = true
		end
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		model:PivotTo(at * CFrame.new(0, 3, 0))
		model.Parent = parent
		local head = model:FindFirstChild("Head") :: BasePart?
		if head then
			local p = Instance.new("ProximityPrompt")
			p.ActionText = "See the houses"
			p.ObjectText = "Legends Realty agent"
			p.KeyboardKeyCode = Enum.KeyCode.E
			p.MaxActivationDistance = 12
			p.RequiresLineOfSight = false
			p.Parent = head
			p.Triggered:Connect(openFor)
		end
	end)
end

-- the glowing blueprint table: step up to it and press E
local function blueprintTable(parent: Instance, at: CFrame, r: number)
	local base = part(parent, Vector3.new(2.4, r * 2, r * 2), at * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2), DARK, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local glow = part(parent, Vector3.new(0.2, r * 2 - 1, r * 2 - 1), at * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 196, 236), Enum.Material.Glass, { shape = Enum.PartType.Cylinder, collide = false, name = "BlueprintGlow" })
	-- (2026-11-04 remodel) a scale model of the island on the table: sea, a green hill, white villas
	part(parent, Vector3.new(0.12, r * 1.7, r * 1.7), at * CFrame.new(0, 2.66, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(60, 130, 170), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, collide = false })
	part(parent, Vector3.new(r * 1.2, r * 0.5, r * 1.0), at * CFrame.new(0, 2.7 + r * 0.12, 0), Color3.fromRGB(96, 128, 72), Enum.Material.Grass, { shape = Enum.PartType.Ball, collide = false })
	for k = 0, 5 do
		local a = k * math.pi / 3 + 0.3
		local rr = r * (if k % 2 == 0 then 0.42 else 0.3)
		part(parent, Vector3.new(r * 0.12, r * 0.09, r * 0.1), at * CFrame.new(math.cos(a) * rr, 2.78 + r * (if k % 2 == 0 then 0.06 else 0.18), math.sin(a) * rr) * CFrame.Angles(0, -a, 0), Color3.fromRGB(246, 242, 234), Enum.Material.SmoothPlastic, { collide = false })
	end
	local light = Instance.new("PointLight")
	light.Color = BLUEPRINT
	light.Range = r * 4
	light.Brightness = 1.4
	light.Parent = glow
	local p = Instance.new("ProximityPrompt")
	p.ActionText = "Browse houses"
	p.ObjectText = "Blueprint table"
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.MaxActivationDistance = r + 8
	p.RequiresLineOfSight = false
	p.Parent = base
	p.Triggered:Connect(openFor)
end

-- the pavilion: a long glass box on a white plinth with a flat roof and the name on it
local function pavilion(parent: Instance, at: CFrame)
	local folder = Instance.new("Model")
	folder.Name = "LegendsRealty"
	local w, d, h = 44, 30, 15
	part(folder, Vector3.new(w + 8, 1, d + 8), at * CFrame.new(0, 0.5, 0), WHITE, Enum.Material.Limestone)
	part(folder, Vector3.new(w, 0.4, d), at * CFrame.new(0, 1.2, 0), Color3.fromRGB(226, 220, 210), Enum.Material.Marble)
	-- glass walls on three sides, the open front with two glass doors' frames
	part(folder, Vector3.new(w, h, 0.4), at * CFrame.new(0, 1 + h / 2, d / 2), GLASS, Enum.Material.Glass, { transparency = 0.55 })
	for _, s in { -1, 1 } do
		part(folder, Vector3.new(0.4, h, d), at * CFrame.new(s * w / 2, 1 + h / 2, 0), GLASS, Enum.Material.Glass, { transparency = 0.55 })
		part(folder, Vector3.new((w - 12) / 2, h, 0.4), at * CFrame.new(s * (w / 4 + 3), 1 + h / 2, -d / 2), GLASS, Enum.Material.Glass, { transparency = 0.55 })
		part(folder, Vector3.new(0.8, h, 0.8), at * CFrame.new(s * 6, 1 + h / 2, -d / 2), DARK, Enum.Material.Metal)
	end
	for _, x in { -w / 2, w / 2 } do
		for _, z in { -d / 2, d / 2 } do
			part(folder, Vector3.new(1, h, 1), at * CFrame.new(x, 1 + h / 2, z), DARK, Enum.Material.Metal)
		end
	end
	part(folder, Vector3.new(w + 6, 1.4, d + 6), at * CFrame.new(0, 1.7 + h, 0), WHITE, Enum.Material.Concrete)
	local sign = part(folder, Vector3.new(30, 3.4, 0.6), at * CFrame.new(0, 1.7 + h + 2.4, -d / 2 - 2.6), DARK, Enum.Material.Metal, { name = "RealtySign" })
	text(sign, Enum.NormalId.Front, "LEGENDS REALTY", WARM, Vector2.new(900, 100))
	local lamp = part(folder, Vector3.new(w - 4, 0.3, 1), at * CFrame.new(0, h + 0.6, 0), WARM, Enum.Material.Glass, { collide = false })
	local pl = Instance.new("PointLight")
	pl.Color = WARM
	pl.Range = 30
	pl.Brightness = 1.2
	pl.Parent = lamp
	-- inside: the desk and the agent, the blueprint table, a big screen and a scale model stand
	part(folder, Vector3.new(12, 3.6, 3), at * CFrame.new(0, 3.2, d / 2 - 6), DARK, Enum.Material.Wood, { name = "Desk" })
	agent(folder, at * CFrame.new(0, 1.4, d / 2 - 3.4) * CFrame.Angles(0, math.pi, 0))
	blueprintTable(folder, at * CFrame.new(-10, 1.4, -2), 4)
	local screen = part(folder, Vector3.new(16, 9, 0.4), at * CFrame.new(10, 8, d / 2 - 0.8), DARK, Enum.Material.SmoothPlastic, { name = "RealtyScreen" })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(640, 360)
	sg.LightInfluence = 0
	sg.Parent = screen
	local title = Instance.new("TextLabel")
	title.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	title.Size = UDim2.fromScale(1, 1)
	title.TextColor3 = Color3.fromRGB(240, 242, 248)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = sg
	-- the screen turns its back to the room otherwise: it faces in, towards the door
	screen.CFrame = screen.CFrame * CFrame.Angles(0, math.pi, 0)
	task.spawn(function()
		local designs = Config.Houses.Designs
		local k = 0
		while screen.Parent do
			k = k % #designs + 1
			local dd = designs[k]
			title.Text = string.upper(dd.name) .. "\n" .. dd.style .. "\n$" .. string.format("%.1fM", dd.price / 1e6):gsub("%.0M", "M")
			task.wait(4)
		end
	end)
	Realty.dress(folder, at, w, d, h)
	folder.Parent = parent
	return folder
end

---------------------------------------------------------------------
-- The remodel (2026-11-04, owner-away run, `Prompts/Remodel the venues.md`: "an elegant estate
-- agency: big windows with house photos, a desk, the island / map model on a table, screens"):
-- listing cards in the windows (a picture of each design's house, its name and price), a wood
-- slat soffit, a lounge corner, two desk screens, planters by the door. Looks only.
---------------------------------------------------------------------
local function listingCard(parent: Instance, cf: CFrame, design: { [string]: any }, k: number)
	local frame = part(parent, Vector3.new(6.4, 8.4, 0.25), cf, Color3.fromRGB(196, 158, 92), Enum.Material.Metal, { collide = false })
	local card = part(parent, Vector3.new(6, 8, 0.1), cf * CFrame.new(0, 0, -0.16), WHITE, Enum.Material.SmoothPlastic, { collide = false })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(300, 400)
	sg.LightInfluence = 0.3
	sg.Brightness = 1.2
	sg.MaxDistance = 260
	sg.Parent = card
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(250, 248, 244)
	bg.BorderSizePixel = 0
	bg.Parent = sg
	-- the "photo": sky, sea, a lawn and the house (a body, a roof, windows), in the design's colours
	local photo = Instance.new("Frame")
	photo.Position = UDim2.fromOffset(14, 14)
	photo.Size = UDim2.new(1, -28, 0, 220)
	photo.BorderSizePixel = 0
	photo.BackgroundColor3 = Color3.new(1, 1, 1)
	photo.ClipsDescendants = true
	photo.Parent = bg
	local sky = Instance.new("UIGradient")
	sky.Rotation = 90
	local dusk = k % 3 == 0
	sky.Color = if dusk then ColorSequence.new(Color3.fromRGB(250, 170, 120), Color3.fromRGB(120, 110, 170)) else ColorSequence.new(Color3.fromRGB(120, 180, 236), Color3.fromRGB(214, 236, 250))
	sky.Parent = photo
	local function rect(x: number, y: number, w2: number, h2: number, c: Color3, rot: number?)
		local f = Instance.new("Frame")
		f.Position = UDim2.fromOffset(x, y)
		f.Size = UDim2.fromOffset(w2, h2)
		f.BackgroundColor3 = c
		f.BorderSizePixel = 0
		f.Rotation = rot or 0
		f.Parent = photo
		return f
	end
	rect(0, 150, 272, 30, Color3.fromRGB(40, 110, 160))
	rect(0, 170, 272, 60, Color3.fromRGB(96, 140, 78))
	local look = design.look or {}
	local wall = if typeof(look.wall) == "Color3" then look.wall else Color3.fromRGB(240, 236, 226)
	local roof = if typeof(look.roof) == "Color3" then look.roof else Color3.fromRGB(70, 66, 64)
	rect(56, 104, 160, 76, wall)
	if k % 2 == 0 then
		rect(46, 92, 180, 14, roof) -- a flat modern roof
	else
		rect(70, 78, 70, 70, roof, 45)
		rect(132, 78, 70, 70, roof, 45)
		rect(56, 104, 160, 76, wall)
	end
	for j = 0, 3 do
		rect(70 + j * 36, 120, 22, 26, if dusk then Color3.fromRGB(255, 214, 150) else Color3.fromRGB(60, 80, 100))
	end
	rect(126, 150, 20, 30, Color3.fromRGB(70, 50, 36))
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(14, 246)
	name.Size = UDim2.new(1, -28, 0, 60)
	name.Text = string.upper(design.name or "")
	name.TextColor3 = Color3.fromRGB(28, 30, 34)
	name.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
	name.TextScaled = true
	name.TextWrapped = true
	name.Parent = bg
	local price = Instance.new("TextLabel")
	price.BackgroundTransparency = 1
	price.Position = UDim2.fromOffset(14, 314)
	price.Size = UDim2.new(1, -28, 0, 40)
	price.Text = "$" .. string.format("%.1fM", (design.price or 0) / 1e6):gsub("%.0M", "M")
	price.TextColor3 = Color3.fromRGB(150, 112, 50)
	price.Font = Enum.Font.GothamBold
	price.TextScaled = true
	price.Parent = bg
	local tag = Instance.new("TextLabel")
	tag.BackgroundTransparency = 1
	tag.Position = UDim2.fromOffset(14, 356)
	tag.Size = UDim2.new(1, -28, 0, 28)
	tag.Text = tostring(design.style or "")
	tag.TextColor3 = Color3.fromRGB(110, 112, 118)
	tag.Font = Enum.Font.Gotham
	tag.TextScaled = true
	tag.Parent = bg
	return frame
end

function Realty.dress(folder: Model, at: CFrame, w: number, d: number, h: number)
	local designs = Config.Houses.Designs
	-- listing cards hung inside the side and back glass, facing out (passers-by see them)
	local k = 0
	local spots = {}
	for _, sx in { -1, 1 } do
		for _, z in { -8, 0, 8 } do
			table.insert(spots, at * CFrame.new(sx * (w / 2 - 0.6), 7.5, z) * CFrame.Angles(0, sx * math.pi / 2, 0))
		end
	end
	for _, x in { -16, -8 } do
		table.insert(spots, at * CFrame.new(x, 7.5, d / 2 - 0.6) * CFrame.Angles(0, math.pi, 0))
	end
	for _, cf in spots do
		k += 1
		local design = designs[((k * 5) % #designs) + 1]
		if design then
			listingCard(folder, cf, design, k)
			-- (the same card seen from inside)
			listingCard(folder, cf * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -0.5), design, k)
		end
	end
	-- a warm oak slat soffit under the roof's overhang, front and sides
	for x = -w / 2 - 2, w / 2 + 2, 1.6 do
		part(folder, Vector3.new(0.7, 0.3, 4), at * CFrame.new(x, 1 + h - 0.1, -d / 2 - 1.8), Color3.fromRGB(176, 128, 82), Enum.Material.Wood, { collide = false })
	end
	-- downlights in the soffit (night)
	for _, x in { -14, 0, 14 } do
		local dl = part(folder, Vector3.new(0.8, 0.1, 0.8), at * CFrame.new(x, 1 + h - 0.3, -d / 2 - 1.8), WARM, Enum.Material.Glass, { collide = false })
		local sl = Instance.new("SpotLight")
		sl.Face = Enum.NormalId.Bottom
		sl.Color = WARM
		sl.Range = 16
		sl.Brightness = 1.2
		sl.Angle = 80
		sl.Parent = dl
		game:GetService("CollectionService"):AddTag(sl, "DayOff")
	end
	-- planters with clipped olive trees either side of the door
	for _, sx in { -1, 1 } do
		part(folder, Vector3.new(4, 2.6, 4), at * CFrame.new(sx * 10, 2.3, -d / 2 - 5), Color3.fromRGB(46, 48, 52), Enum.Material.Concrete)
		part(folder, Vector3.new(0.5, 3, 0.5), at * CFrame.new(sx * 10, 5, -d / 2 - 5), Color3.fromRGB(90, 70, 50), Enum.Material.Wood, { collide = false })
		part(folder, Vector3.new(4.2, 3.6, 4.2), at * CFrame.new(sx * 10, 7.6, -d / 2 - 5), Color3.fromRGB(110, 128, 90), Enum.Material.Grass, { shape = Enum.PartType.Ball, collide = false })
	end
	-- a lounge corner (front right): rug, sofa and palm from the venue kit, a low table
	local vk = game:GetService("ServerStorage"):FindFirstChild("VenueKit")
	local function kit(name: string, cf: CFrame)
		local src = vk and vk:FindFirstChild(name)
		if src and src:IsA("Model") then
			local m = src:Clone()
			m:PivotTo(cf)
			m.Parent = folder
		end
	end
	part(folder, Vector3.new(14, 0.06, 10), at * CFrame.new(12, 1.43, -6), Color3.fromRGB(200, 190, 172), Enum.Material.Fabric, { collide = false })
	kit("Chesterfield", at * CFrame.new(12, 1.4, -10.5))
	kit("Armchair", at * CFrame.new(18, 1.4, -4) * CFrame.Angles(0, math.rad(-110), 0))
	kit("PottedPalm", at * CFrame.new(w / 2 - 3, 1.4, -d / 2 + 3))
	kit("PottedPalm", at * CFrame.new(-w / 2 + 3, 1.4, d / 2 - 3))
	part(folder, Vector3.new(5, 1.4, 3), at * CFrame.new(12, 2.1, -6), Color3.fromRGB(30, 30, 34), Enum.Material.Marble)
	-- two slim screens on the desk
	for _, sx in { -1, 1 } do
		local scr = part(folder, Vector3.new(2.6, 1.7, 0.15), at * CFrame.new(sx * 3, 6, d / 2 - 6.4) * CFrame.Angles(math.rad(-8), math.pi, 0), Color3.fromRGB(20, 22, 26), Enum.Material.SmoothPlastic, { collide = false })
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(160, 100)
		sg.LightInfluence = 0
		sg.Parent = scr
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.fromRGB(30, 60, 90)
		f.Parent = sg
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(120, 180, 230), Color3.fromRGB(40, 90, 70))
		g.Parent = f
		part(folder, Vector3.new(0.3, 1, 0.3), at * CFrame.new(sx * 3, 5.1, d / 2 - 6.2), DARK, Enum.Material.Metal, { collide = false })
	end
end

-- the booth by the causeway's landing on the island: a kiosk with a canopy
local function booth(parent: Instance, at: CFrame)
	local m = Instance.new("Model")
	m.Name = "RealtyBooth"
	part(m, Vector3.new(18, 0.6, 14), at * CFrame.new(0, 0.3, 0), WHITE, Enum.Material.Limestone)
	part(m, Vector3.new(10, 3.6, 3), at * CFrame.new(0, 2.4, 3), DARK, Enum.Material.Wood, { name = "Desk" })
	for _, x in { -8, 8 } do
		part(m, Vector3.new(0.6, 10, 0.6), at * CFrame.new(x, 5.6, 5.5), DARK, Enum.Material.Metal)
		part(m, Vector3.new(0.6, 10, 0.6), at * CFrame.new(x, 5.6, -5.5), DARK, Enum.Material.Metal)
	end
	part(m, Vector3.new(19, 0.8, 15), at * CFrame.new(0, 11, 0), WHITE, Enum.Material.Concrete)
	local sign = part(m, Vector3.new(16, 2.4, 0.4), at * CFrame.new(0, 12.6, -7.2), DARK, Enum.Material.Metal)
	text(sign, Enum.NormalId.Front, "LEGENDS REALTY", WARM, Vector2.new(800, 120))
	agent(m, at * CFrame.new(0, 0.6, 5.4) * CFrame.Angles(0, math.pi, 0))
	blueprintTable(m, at * CFrame.new(-5, 0.6, -2.5), 2.6)
	m.Parent = parent
	return m
end

-- a clear, level spot on the sand by the causeway: nothing standing in a box this size there
local function clearSpot(): CFrame
	local z0 = CityLayout.roadCoord(CityLayout.HighwayJ)
	local W = Config.West
	local x0 = (WestLayout.DowntownWest + W.BeachWest) / 2
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _, dz in { 70, -70, 110, -110, 150, -150 } do
		for _, dx in { 0, 60, -60, 120, -120 } do
			local p = Vector3.new(x0 + dx, 200, z0 + dz)
			local hit = workspace:Raycast(p, Vector3.new(0, -400, 0), params)
			if hit then
				local ground = hit.Position.Y
				local box = workspace:GetPartBoundsInBox(CFrame.new(Vector3.new(p.X, ground + 10, p.Z)), Vector3.new(60, 18, 46))
				local blocked = false
				for _, b in box do
					-- (the sand and other flat ground slabs don't count)
					if b.Position.Y + b.Size.Y / 2 > ground + 1.5 then
						blocked = true
						break
					end
				end
				if not blocked then
					-- facing the causeway road, so you see the front from it
					local at = Vector3.new(p.X, ground, p.Z)
					return CFrame.lookAt(at, Vector3.new(at.X, at.Y, z0))
				end
			end
		end
	end
	local at = Vector3.new(x0, 2, z0 + 70)
	return CFrame.lookAt(at, Vector3.new(at.X, at.Y, z0))
end

function Realty.init(ctx: any)
	fx = ctx.remote("RemoteEvent", "HouseFx")
	local folder = Instance.new("Folder")
	folder.Name = "Realty"
	folder.Parent = workspace
	local ok, err = pcall(function()
		-- Monaco only: the pavilion on its own lot by the harbour, no island booth
		local riv = if Config.monacoOnly() then WestLayout.rivieraSite("realty") else nil
		if riv then
			pavilion(folder, riv)
			-- (owner, 2026-11-04: every venue you can drive onto) a drive from the road over the trench
			-- between the pavement and the lot
			local size = (Config.RivieraVenues.Sites :: any).realty.size or 80
			local inner = riv * CFrame.new(0, 0.2, -size / 2 - 1.5)
			task.defer(function()
				EntranceRamp.build(folder, inner, { width = 26, reach = 50, keep = { folder } })
			end)
			return
		end
		pavilion(folder, clearSpot())
		-- the island booth: inside the island ring beside where the causeway lands
		local I = Config.West.Isle
		local p = IsleLayout.polar(I.Ring - IsleLayout.Road / 2 - 26, 0.2, 0)
		booth(folder, CFrame.lookAt(p, Vector3.new(IsleLayout.polar(I.Ring, 0.2, 0).X, p.Y, IsleLayout.polar(I.Ring, 0.2, 0).Z)))
	end)
	if not ok then
		warn("[CityLegends] Legends Realty:", err)
	end
end

return Realty
