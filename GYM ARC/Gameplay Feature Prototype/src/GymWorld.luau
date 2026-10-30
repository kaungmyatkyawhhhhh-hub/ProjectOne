--[[
	GymWorld
	Builds the small gym (floor, spawn, lifting stations) from code so the
	whole prototype lives in scripts. Each station has a barbell that moves on
	the server, so every player sees reps happen.
]]

local GymWorld = {}

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	return p
end

local function buildBarbell(parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Barbell"
	local bar = part({
		Name = "Bar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7, 0.3, 0.3),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(190, 190, 200),
		CanCollide = false,
	})
	bar.Parent = model
	for _, side in ipairs({ -1, 1 }) do
		local plate = part({
			Name = side < 0 and "PlateL" or "PlateR",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.45, 1.4, 1.4),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(150, 150, 160),
			CanCollide = false,
		})
		plate:SetAttribute("Side", side)
		plate.Parent = model
	end
	model.PrimaryPart = bar
	model.Parent = parent
	return model
end

-- Places the barbell (and its plates) at a CFrame. Plates sit at the bar's ends.
function GymWorld.placeBarbell(barbell: Model, cf: CFrame)
	local bar = barbell:FindFirstChild("Bar") :: BasePart
	bar.CFrame = cf
	for _, plate in ipairs(barbell:GetChildren()) do
		local side = plate:GetAttribute("Side")
		if side then
			(plate :: BasePart).CFrame = cf * CFrame.new(side * 2.9, 0, 0)
		end
	end
end

function GymWorld.setPlates(barbell: Model, size: number, color: Color3)
	for _, plate in ipairs(barbell:GetChildren()) do
		if plate:GetAttribute("Side") then
			(plate :: BasePart).Size = Vector3.new(0.45, size, size)
			;(plate :: BasePart).Color = color
		end
	end
end

function GymWorld.build(stationCount: number)
	local folder = Instance.new("Folder")
	folder.Name = "Gym"
	folder.Parent = workspace

	part({ Name = "Floor", Size = Vector3.new(140, 1, 140), Position = Vector3.new(0, -0.5, 0),
		Material = Enum.Material.Concrete, Color = Color3.fromRGB(60, 62, 70) }).Parent = folder
	part({ Name = "Mat", Size = Vector3.new(70, 0.2, 34), Position = Vector3.new(0, 0.1, -8),
		Material = Enum.Material.Fabric, Color = Color3.fromRGB(35, 36, 42) }).Parent = folder

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 26)
	spawn.Color = Color3.fromRGB(255, 200, 40)
	spawn.Material = Enum.Material.Neon
	spawn.Duration = 0
	spawn.Parent = folder

	local stations = {}
	for i = 1, stationCount do
		local row = (i - 1) // 3
		local col = (i - 1) % 3
		local center = Vector3.new((col - 1) * 20, 0, -2 - row * 16)
		local look = CFrame.lookAt(center, center + Vector3.new(0, 0, -1)) -- players face -Z

		local model = Instance.new("Model")
		model.Name = "Station" .. i
		model.Parent = folder

		local platform = part({ Name = "Platform", Size = Vector3.new(9, 0.6, 7), CFrame = look * CFrame.new(0, 0.3, 0),
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 105, 60) })
		platform.Parent = model
		for _, side in ipairs({ -1, 1 }) do
			part({ Name = "Rack", Size = Vector3.new(0.5, 6, 0.5), CFrame = look * CFrame.new(side * 3.9, 3, -2.2),
				Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) }).Parent = model
		end

		-- the player stands here; HumanoidRootPart height is added when they step on
		local standCFrame = look * CFrame.new(0, 0.6, 0.6)

		local barbell = buildBarbell(model)
		local restCFrame = look * CFrame.new(0, 4.2, -1.1)
		GymWorld.placeBarbell(barbell, restCFrame)

		local promptPart = part({ Name = "PromptPart", Size = Vector3.new(1, 1, 1), CFrame = look * CFrame.new(0, 3, 0),
			Transparency = 1, CanCollide = false })
		promptPart.Parent = model
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Train"
		prompt.ObjectText = "Overhead Press"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart

		-- sound + sparkles on the station, so nearby players hear and see each rep
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/swoosh.wav"
		sound.Volume = 0.5
		sound.RollOffMaxDistance = 60
		sound.Parent = promptPart
		local perfectSound = Instance.new("Sound")
		perfectSound.Name = "Perfect"
		perfectSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		perfectSound.Volume = 0.6
		perfectSound.RollOffMaxDistance = 60
		perfectSound.Parent = promptPart

		local sparkleAttachment = Instance.new("Attachment")
		sparkleAttachment.Parent = barbell:FindFirstChild("Bar")
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Rate = 0
		sparkles.Lifetime = NumberRange.new(0.4, 0.8)
		sparkles.Speed = NumberRange.new(6, 12)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80))
		sparkles.Size = NumberSequence.new(0.5, 0)
		sparkles.LightEmission = 1
		sparkles.Parent = sparkleAttachment

		-- "FREE / In use" sign above the station, visible to everyone
		local sign = Instance.new("BillboardGui")
		sign.Size = UDim2.fromOffset(180, 40)
		sign.StudsOffset = Vector3.new(0, 4.5, 0)
		sign.MaxDistance = 70
		sign.Parent = promptPart
		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.fromScale(1, 1)
		signText.BackgroundTransparency = 1
		signText.Font = Enum.Font.GothamBlack
		signText.TextScaled = true
		signText.TextColor3 = Color3.fromRGB(120, 255, 140)
		signText.TextStrokeTransparency = 0.3
		signText.Text = "FREE"
		signText.Parent = sign

		table.insert(stations, {
			id = i,
			model = model,
			standCFrame = standCFrame,
			restCFrame = restCFrame,
			barbell = barbell,
			prompt = prompt,
			sound = sound,
			perfectSound = perfectSound,
			sparkles = sparkles,
			signText = signText,
			occupant = nil,
		})
	end
	return stations
end

return GymWorld
