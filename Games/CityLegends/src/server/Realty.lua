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
	local glow = part(parent, Vector3.new(0.2, r * 2 - 1, r * 2 - 1), at * CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.pi / 2), BLUEPRINT, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, collide = false, name = "BlueprintGlow" })
	-- a little house drawn in light on the table
	part(parent, Vector3.new(r * 0.7, r * 0.45, r * 0.6), at * CFrame.new(0, 2.6 + r * 0.22, 0), Color3.fromRGB(200, 230, 255), Enum.Material.ForceField, { collide = false })
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
	local lamp = part(folder, Vector3.new(w - 4, 0.3, 1), at * CFrame.new(0, h + 0.6, 0), WARM, Enum.Material.Neon, { collide = false })
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
	folder.Parent = parent
	return folder
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
