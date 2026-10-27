-- SpeedFeelController (VFX note "Speed feel"): screen speed lines when you run fast or boost
-- (pooled frames, density follows pace), footstep dust on grass, sparks on the track at very high
-- speed. Low graphics: half the effects. FOV lives in CameraController / RaceController.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserSettings_ = UserSettings()

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)

local P = UIKit.Palette
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SpeedFeel = {}
local ctx
local lines = {}
local layer
local intensity = 0 -- 0..1, set from walk speed or race pace
local boostUntil = 0
local dust, sparks
local stepAcc = 0

local GRASS = { Grass = true, Stripe = true, Infield = true, InfieldStripe = true, Outskirts = true }
local TRACK = { Surface = true, Apron = true, Strip = true, StartFinish = true }

local function lowGraphics()
	local q = UserSettings_:GetService("UserGameSettings").SavedQualityLevel.Value
	return q ~= 0 and q <= 3
end

local function buildLines()
	layer = UIKit.make("Frame", { Name = "SpeedLines", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = ctx.Hud.canvas })
	for i = 1, 22 do
		local l = UIKit.make("Frame", {
			BackgroundColor3 = P.White,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(90, 3),
			Visible = false,
			Parent = layer,
		})
		UIKit.make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.35), NumberSequenceKeypoint.new(1, 1) }), Parent = l })
		lines[i] = { f = l, age = 1, life = 0.3, angle = 0, r0 = 0 }
	end
end

local function emitterOn(parent, texture, color, size, life)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = texture
	pe.Color = ColorSequence.new(color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 1.8) })
	pe.Transparency = NumberSequence.new(0.35, 1)
	pe.Lifetime = NumberRange.new(life * 0.7, life)
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(60, 60)
	pe.Acceleration = Vector3.new(0, 2, 0)
	pe.Rate = 0
	pe.Enabled = true
	pe.Parent = parent
	return pe
end

local function hookCharacter(char)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local a = Instance.new("Attachment")
	a.Name = "FeetFX"
	a.Position = Vector3.new(0, -2.9, 0.3)
	a.Parent = root
	dust = emitterOn(a, "rbxasset://textures/particles/smoke_main.dds", Color3.fromHex("#B7C29A"), 0.7, 0.6)
	sparks = emitterOn(a, "rbxasset://textures/particles/sparkles_main.dds", P.BrightBlue, 0.35, 0.3)
	sparks.LightEmission = 1
end

function SpeedFeel.boost()
	boostUntil = os.clock() + 0.6
end

-- what's under your feet, 4 times a second
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
local function floorKind(root)
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
	if not hit then
		return nil
	end
	local n = hit.Instance.Name
	if GRASS[n] then
		return "grass"
	elseif TRACK[n] or string.find(n, "^Line") then
		return "track"
	end
	return nil
end

local function update(dt)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local inRace = player:GetAttribute("InRace") == true
	local speed = 0
	if root then
		local v = root.AssemblyLinearVelocity
		speed = Vector3.new(v.X, 0, v.Z).Magnitude
	end
	local low = lowGraphics()
	local target
	if inRace then
		target = 0.55 + (if os.clock() < boostUntil then 0.45 else 0)
	else
		target = math.clamp((speed - 21) / 9, 0, 0.7) + (if os.clock() < boostUntil then 0.3 else 0)
	end
	if low then
		target *= 0.5
	end
	intensity += (target - intensity) * math.min(1, dt * 6)

	-- speed lines: spawn more the faster you go; each flies outward from the centre and fades
	local w = ctx.Hud.canvas.Size.X.Offset
	local h = ctx.Hud.canvas.Size.Y.Offset
	for _, L in lines do
		if L.age < L.life then
			L.age += dt
			local t = L.age / L.life
			local r = L.r0 + t * 0.55
			L.f.Position = UDim2.fromOffset(w / 2 + math.cos(L.angle) * r * w * 0.6, h / 2 + math.sin(L.angle) * r * h * 0.7)
			L.f.BackgroundTransparency = 0.2 + t * 0.8
			if L.age >= L.life then
				L.f.Visible = false
			end
		elseif intensity > 0.08 and math.random() < intensity * dt * 14 then
			L.age = 0
			L.life = 0.22 + math.random() * 0.15
			L.angle = math.random() * math.pi * 2
			L.r0 = 0.32 + math.random() * 0.12
			L.f.Rotation = math.deg(L.angle)
			L.f.Size = UDim2.fromOffset(60 + intensity * 90, 2 + math.floor(intensity * 2))
			L.f.Visible = true
		end
	end

	-- footstep dust on grass, sparks on the track at very high speed
	stepAcc += dt
	if root and hum and dust and stepAcc > 0.25 then
		stepAcc = 0
		if speed > 9 and hum.FloorMaterial ~= Enum.Material.Air then
			local kind = floorKind(root)
			local n = if low then 1 else 2
			if kind == "grass" then
				dust:Emit(n)
			elseif kind == "track" and speed > 26 then
				sparks:Emit(n + 1)
			end
		end
	end
end

function SpeedFeel.start(c)
	ctx = c
	ctx.SpeedFeel = SpeedFeel
	buildLines()
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		task.spawn(hookCharacter, player.Character)
	end
	RunService.RenderStepped:Connect(update)
end

return SpeedFeel
