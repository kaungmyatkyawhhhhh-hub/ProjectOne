--!strict
-- AuraLayers: layered auras in the Sol's RNG style (clean layers, not particle spam).
-- Put this ModuleScript in ReplicatedStorage. Call it from a LocalScript on every client:
--   AuraLayers.Apply(character, "Pumpkin", character == LocalPlayer.Character)
--   AuraLayers.Remove(character)
-- Every aura is built from the same 6 layers; rarer auras switch more layers on.
-- Nothing is placed in front of the face, and the local player's own aura is drawn lighter.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AuraLayers = {}

-- Fill these with the image ids from Asset Manager (rbxassetid://...).
AuraLayers.Textures = {
	Glow = "rbxassetid://0", -- fx-glow.png
	Ring = "rbxassetid://0", -- fx-ring.png
	Swirl = "rbxassetid://0", -- fx-swirl.png
	Spark = "rbxassetid://0", -- fx-spark.png
	Star = "rbxassetid://0", -- fx-star4.png
	Smoke = "rbxassetid://0", -- fx-smoke.png
	Beam = "rbxassetid://0", -- fx-beam.png
	Flame = "rbxassetid://0", -- a flipbook flame sheet (Grid4x4), optional
}

type Def = {
	A: Color3, -- main color
	B: Color3, -- second color
	Ring: boolean, -- 1. ground ring
	Glow: boolean, -- 2. Highlight body glow
	Orbit: number, -- 3. number of orbiting pieces (0 = off)
	OrbitShape: string, -- "Ball" | "Crystal" | "Bat" | "Ghost" | "Skull" | "Flame"
	Beams: number, -- 4. spiral beams (0 = off)
	Trails: boolean, -- 5. feet trails
	Detail: string?, -- 6. "Halo" | "Scythe" | "Wings" | "Pumpkin" | nil
	Rising: boolean, -- soft particles rising from the ring (kept low)
}

local WHITE = Color3.new(1, 1, 1)

AuraLayers.Defs = {
	Ghost = { A = Color3.fromRGB(230, 240, 255), B = Color3.fromRGB(150, 200, 255), Ring = true, Glow = false, Orbit = 3, OrbitShape = "Ghost", Beams = 0, Trails = false, Rising = false },
	Bats = { A = Color3.fromRGB(255, 140, 40), B = Color3.fromRGB(60, 20, 70), Ring = true, Glow = false, Orbit = 5, OrbitShape = "Bat", Beams = 0, Trails = true, Rising = false },
	Web = { A = Color3.fromRGB(230, 235, 255), B = Color3.fromRGB(150, 90, 220), Ring = true, Glow = true, Orbit = 0, OrbitShape = "Ball", Beams = 2, Trails = false, Rising = false },
	Pumpkin = { A = Color3.fromRGB(255, 140, 20), B = Color3.fromRGB(255, 220, 90), Ring = true, Glow = true, Orbit = 3, OrbitShape = "Flame", Beams = 2, Trails = true, Detail = "Pumpkin", Rising = true },
	Cursed = { A = Color3.fromRGB(80, 255, 110), B = Color3.fromRGB(20, 120, 50), Ring = true, Glow = true, Orbit = 4, OrbitShape = "Skull", Beams = 3, Trails = true, Detail = "Halo", Rising = true },
	Reaper = { A = Color3.fromRGB(200, 30, 70), B = Color3.fromRGB(70, 20, 110), Ring = true, Glow = true, Orbit = 4, OrbitShape = "Crystal", Beams = 3, Trails = true, Detail = "Scythe", Rising = true },
} :: { [string]: Def }

local active: { [Model]: { cleanup: () -> () } } = {}

local function seq(a: Color3, b: Color3): ColorSequence
	return ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.6, b), ColorSequenceKeypoint.new(1, WHITE) })
end

local function fade(t0: number, mid: number, t1: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, t0), NumberSequenceKeypoint.new(0.3, mid), NumberSequenceKeypoint.new(1, t1) })
end

local function effectPart(name: string, size: Vector3, parent: Instance): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Transparency = 1
	p.Parent = parent
	return p
end

-- Small mesh-like orbit pieces built from simple parts (swap for real MeshParts later).
local function orbitPiece(shape: string, def: Def, parent: Instance, lighter: number): BasePart
	local p = effectPart("Orbit", Vector3.new(0.6, 0.6, 0.6), parent)
	p.Transparency = 0.15 + lighter
	p.Material = Enum.Material.Neon
	p.Color = def.A
	if shape == "Ball" or shape == "Ghost" then
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.7, 0.7, 0.7)
		if shape == "Ghost" then
			p.Material = Enum.Material.Glass
			p.Transparency = 0.35 + lighter
		end
	elseif shape == "Crystal" then
		p.Size = Vector3.new(0.35, 0.9, 0.35)
	elseif shape == "Bat" then
		p.Size = Vector3.new(0.9, 0.12, 0.35)
		p.Material = Enum.Material.SmoothPlastic
		p.Color = def.B
	elseif shape == "Skull" then
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.6, 0.6, 0.6)
		p.Color = Color3.fromRGB(235, 240, 225)
		p.Material = Enum.Material.SmoothPlastic
	end
	local light = Instance.new("PointLight")
	light.Color = def.A
	light.Range = 4
	light.Brightness = 0.8
	light.Parent = p
	if shape == "Flame" then
		local att = Instance.new("Attachment")
		att.Parent = p
		local f = Instance.new("ParticleEmitter")
		f.Texture = AuraLayers.Textures.Flame ~= "rbxassetid://0" and AuraLayers.Textures.Flame or AuraLayers.Textures.Glow
		if AuraLayers.Textures.Flame ~= "rbxassetid://0" then
			f.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
			f.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		end
		f.Color = seq(def.A, def.B)
		f.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		f.Transparency = fade(0.2 + lighter, 0.3 + lighter, 1)
		f.LightEmission = 0.8
		f.Lifetime = NumberRange.new(0.4, 0.6)
		f.Rate = 10
		f.Speed = NumberRange.new(1, 2)
		f.EmissionDirection = Enum.NormalId.Top
		f.Parent = att
	end
	return p
end

function AuraLayers.Apply(character: Model, auraName: string, isLocalPlayer: boolean)
	AuraLayers.Remove(character)
	local def = AuraLayers.Defs[auraName]
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not def or not root or not humanoid then
		return
	end
	-- Your own aura is lighter so it never blocks your view.
	local lighter = isLocalPlayer and 0.3 or 0
	local rateMul = isLocalPlayer and 0.4 or 1

	local folder = Instance.new("Folder")
	folder.Name = "AuraLayers"
	folder.Parent = character
	local conns: { RBXScriptConnection } = {}

	-- 1. Ground ring: a flat disc kept on the floor by a downward raycast every frame.
	local ringPart: BasePart? = nil
	local ringDecal: Decal? = nil
	if def.Ring then
		ringPart = effectPart("GroundRing", Vector3.new(7, 0.05, 7), folder)
		ringDecal = Instance.new("Decal")
		ringDecal.Face = Enum.NormalId.Top
		ringDecal.Texture = AuraLayers.Textures.Ring
		ringDecal.Color3 = def.A
		ringDecal.Transparency = 0.25 + lighter
		ringDecal.ZIndex = 1
		ringDecal.Parent = ringPart
		local inner = Instance.new("Decal")
		inner.Face = Enum.NormalId.Top
		inner.Texture = AuraLayers.Textures.Glow
		inner.Color3 = def.B
		inner.Transparency = 0.55 + lighter
		inner.Parent = ringPart
		if def.Rising then
			local att = Instance.new("Attachment")
			att.Parent = ringPart
			local p = Instance.new("ParticleEmitter")
			p.Texture = AuraLayers.Textures.Spark
			p.Orientation = Enum.ParticleOrientation.VelocityParallel
			p.Color = seq(def.A, def.B)
			p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
			p.Transparency = fade(0.3 + lighter, 0.2 + lighter, 1)
			p.LightEmission = 1
			p.Lifetime = NumberRange.new(0.7, 1)
			p.Rate = 6 * rateMul
			p.Speed = NumberRange.new(3, 5)
			p.SpreadAngle = Vector2.new(8, 8)
			p.EmissionDirection = Enum.NormalId.Top
			p.Shape = Enum.ParticleEmitterShape.Disc
			p.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			p.Parent = att
		end
	end

	-- 2. Body glow: a soft outline, never covering the player.
	if def.Glow then
		local h = Instance.new("Highlight")
		h.FillColor = def.A
		h.OutlineColor = def.A
		h.FillTransparency = 0.92
		h.OutlineTransparency = 0.25 + lighter
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = character
		h.Parent = folder
	end

	-- 3. Orbiting pieces at waist/shoulder height (never at face height).
	local orbiters: { BasePart } = {}
	for i = 1, def.Orbit do
		table.insert(orbiters, orbitPiece(def.OrbitShape, def, folder, lighter))
	end

	-- 4. Spiral beams from the feet up the body.
	if def.Beams > 0 then
		for i = 1, def.Beams do
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(math.cos(i * 2.1) * 1.4, -2.6, math.sin(i * 2.1) * 1.4)
			a0.Parent = root
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(math.cos(i * 2.1 + 2) * 1.2, 0.6, math.sin(i * 2.1 + 2) * 1.2)
			a1.Parent = root
			local b = Instance.new("Beam")
			b.Attachment0 = a0
			b.Attachment1 = a1
			b.Texture = AuraLayers.Textures.Beam
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = 2
			b.TextureSpeed = 1.5
			b.Color = seq(def.A, def.B)
			b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35 + lighter), NumberSequenceKeypoint.new(0.8, 0.35 + lighter), NumberSequenceKeypoint.new(1, 1) })
			b.Width0 = 0.35
			b.Width1 = 0.1
			b.CurveSize0 = 2
			b.CurveSize1 = -2
			b.LightEmission = 1
			b.FaceCamera = true
			b.Parent = folder
			folder.Destroying:Connect(function()
				a0:Destroy()
				a1:Destroy()
			end)
		end
	end

	-- 5. Thin fading trails from the feet (only visible while moving).
	if def.Trails then
		for _, footName in { "LeftFoot", "RightFoot", "Left Leg", "Right Leg" } do
			local foot = character:FindFirstChild(footName) :: BasePart?
			if foot then
				local t0 = Instance.new("Attachment")
				t0.Position = Vector3.new(0, -0.3, 0.2)
				t0.Parent = foot
				local t1 = Instance.new("Attachment")
				t1.Position = Vector3.new(0, -0.3, -0.2)
				t1.Parent = foot
				local tr = Instance.new("Trail")
				tr.Attachment0 = t0
				tr.Attachment1 = t1
				tr.Lifetime = 0.35
				tr.Color = seq(def.A, def.B)
				tr.Transparency = NumberSequence.new(0.3 + lighter, 1)
				tr.LightEmission = 0.8
				tr.FaceCamera = true
				tr.Parent = folder
				folder.Destroying:Connect(function()
					t0:Destroy()
					t1:Destroy()
				end)
			end
		end
	end

	-- 6. One detail, behind or above the body (never in front of the face).
	local detail: BasePart? = nil
	if def.Detail == "Halo" then
		detail = effectPart("Halo", Vector3.new(1.6, 0.12, 1.6), folder)
		detail.Shape = Enum.PartType.Cylinder
		detail.Material = Enum.Material.Neon
		detail.Color = def.A
		detail.Transparency = 0.2 + lighter
	elseif def.Detail == "Scythe" then
		detail = effectPart("Scythe", Vector3.new(0.15, 3.2, 0.15), folder)
		detail.Material = Enum.Material.Metal
		detail.Color = Color3.fromRGB(40, 30, 45)
		detail.Transparency = lighter
		local blade = effectPart("Blade", Vector3.new(0.08, 0.5, 1.8), detail)
		blade.Material = Enum.Material.Neon
		blade.Color = def.A
		blade.Transparency = 0.1 + lighter
	elseif def.Detail == "Pumpkin" then
		detail = effectPart("Pumpkin", Vector3.new(0.9, 0.8, 0.9), folder)
		detail.Shape = Enum.PartType.Ball
		detail.Material = Enum.Material.Neon
		detail.Color = def.A
		detail.Transparency = 0.1 + lighter
	end

	-- Equip reveal: a quick flash ring on the ground.
	if ringDecal then
		ringDecal.Transparency = 0
		task.delay(0.15, function()
			if ringDecal and ringDecal.Parent then
				ringDecal.Transparency = 0.25 + lighter
			end
		end)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local t = 0
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		if not root.Parent then
			return
		end
		t += dt
		local pos = root.Position
		local hip = humanoid.HipHeight + root.Size.Y / 2

		-- Ring sits on the floor even while walking; it hides while far above the ground.
		if ringPart then
			local hit = Workspace:Raycast(pos, Vector3.new(0, -(hip + 6), 0), rayParams)
			local y = hit and hit.Position.Y or (pos.Y - hip)
			ringPart.CFrame = CFrame.new(pos.X, y + 0.06, pos.Z) * CFrame.Angles(0, t * 0.6, 0)
			if ringDecal then
				ringDecal.Transparency = (pos.Y - y > hip + 4) and 1 or (0.25 + lighter)
			end
		end

		-- Orbiters circle at waist height with a gentle bob.
		local n = #orbiters
		for i, p in orbiters do
			local a = t * 1.4 + (i / n) * math.pi * 2
			local radius = 2.2
			local height = -0.6 + math.sin(t * 2 + i) * 0.25
			p.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * radius, height, math.sin(a) * radius))
				* CFrame.Angles(0, -a, math.sin(t * 3 + i) * 0.3)
		end

		-- Detail follows the body.
		if detail then
			if detail.Name == "Halo" then
				detail.CFrame = root.CFrame * CFrame.new(0, 2.6, 0.3) * CFrame.Angles(0, 0, math.rad(90))
			elseif detail.Name == "Scythe" then
				detail.CFrame = root.CFrame * CFrame.new(0.6, 0.6, 1.3) * CFrame.Angles(0, 0, math.rad(-25))
				local blade = detail:FindFirstChild("Blade") :: BasePart?
				if blade then
					blade.CFrame = detail.CFrame * CFrame.new(0, 1.5, -0.8)
				end
			elseif detail.Name == "Pumpkin" then
				detail.CFrame = root.CFrame * CFrame.new(-1.6, -0.4 + math.sin(t * 2) * 0.2, 0.4)
			end
		end
	end))

	active[character] = {
		cleanup = function()
			for _, c in conns do
				c:Disconnect()
			end
			folder:Destroy()
		end,
	}
	character.Destroying:Connect(function()
		AuraLayers.Remove(character)
	end)
end

function AuraLayers.Remove(character: Model)
	local a = active[character]
	if a then
		a.cleanup()
		active[character] = nil
	end
end

return AuraLayers
