-- FrostFX (27 Nov, Christmas Strongman; owner: "layered realistic vfxs ... add vfx in cutscenes too, thats the reason why
-- TDS Cutscenes are way better"): the Christmas event's frost look, layered from HofVFX's own flipbooks. Client only.
--   FrostFX.Gather(pos, size, time)         anticipation: frost motes and a shrinking orb pulled into a point
--   FrostFX.Burst(pos, size, opts)          the impact: white-hot core, light pulse, flipbook ring, a flat snow shockwave,
--                                           frost sparks, rolling snow mist, falling glints (+ opts.shake / opts.flash)
--   FrostFX.GroundWave(pos, radius)         a ring of snow mist rolling out along the ground
--   FrostFX.Snowfall(camera, time)          snow drifting past the lens (depth in a shot)
--   FrostFX.Aura(model)             a lasting cold aura: mist pooling at the feet, rising frost motes, a breathing
--                                           cyan light, the armour's glow pieces pulsing -> returns a stop function
--   FrostFX.Shake(amp, time) / FrostFX.Flash(color, peak, time)
-- Reduced Motion: no shake, no flash; particles stay.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HofVFX = require(script.Parent.HofVFX)
local Theme = require(ReplicatedStorage.Shared.UI.Theme)
local TEX = HofVFX.TEX
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local ICE = Color3.fromHex("#BFEFFF")
local CYAN = Color3.fromHex("#5FE2FF")
local WHITE = Color3.new(1, 1, 1)
local DEEP = Color3.fromHex("#3A9BD8")

local FrostFX = {}

local function seq(a, b) return ColorSequence.new(a, b or a) end
local function nseq(points)
	local keys = {}
	for _, p in ipairs(points) do table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2])) end
	return NumberSequence.new(keys)
end
local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function low(): boolean return HofVFX.LowGraphics ~= nil and HofVFX.LowGraphics() == true end
local function holder(pos: Vector3, life: number, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Name = "FrostFX"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = size or Vector3.one * 0.2
	p.CFrame = CFrame.new(pos)
	p.Parent = Workspace
	Debris:AddItem(p, life)
	return p
end
local function smoke(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = SMOKE
	e.LightEmission = 0.25
	e.LightInfluence = 0.4
	e.Rate = 0
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end

-- shake: an offset added after the camera scripts (Camera + 1); LaunchCinematic reads FrostFX.ShakeOffset() instead
local shakeAmp, shakeEnd, shakeLen = 0, 0, 1
function FrostFX.ShakeOffset(): CFrame
	local left = shakeEnd - os.clock()
	if left <= 0 then return CFrame.identity end
	local a = shakeAmp * (left / shakeLen) ^ 2
	local t = os.clock() * 38
	return CFrame.Angles(math.noise(t, 1) * a * 0.02, math.noise(t, 2) * a * 0.02, math.noise(t, 3) * a * 0.012)
end
local bound = false
function FrostFX.Shake(amp: number, time: number, external: boolean?)
	if Theme.ReducedMotion() then return end
	shakeAmp, shakeLen, shakeEnd = amp, time, os.clock() + time
	if external or bound then return end
	bound = true
	RunService:BindToRenderStep("FrostShake", Enum.RenderPriority.Camera.Value + 1, function()
		if os.clock() > shakeEnd then
			RunService:UnbindFromRenderStep("FrostShake")
			bound = false
			return
		end
		local cam = Workspace.CurrentCamera
		cam.CFrame = cam.CFrame * FrostFX.ShakeOffset()
	end)
end

function FrostFX.Flash(color: Color3?, peak: number?, time: number?)
	if Theme.ReducedMotion() then return end
	local gui = Players.LocalPlayer.PlayerGui:FindFirstChild("FrostFlash")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "FrostFlash"
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 86
		gui.ResetOnSpawn = false
		gui.Parent = Players.LocalPlayer.PlayerGui
	end
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = color or WHITE
	f.BackgroundTransparency = 1 - (peak or 0.5)
	f.Parent = gui
	tween(f, time or 0.45, { BackgroundTransparency = 1 })
	Debris:AddItem(f, (time or 0.45) + 0.1)
end

function FrostFX.Gather(pos: Vector3, size: number?, time: number?)
	local s, t = size or 10, time or 0.5
	local h = holder(pos, t + 1, Vector3.one * s)
	local e = HofVFX.Emitter(h, TEX.Sparkle, { Color = seq(WHITE, CYAN), Lifetime = NumberRange.new(t * 0.8, t), Size = nseq({ { 0, s * 0.06 }, { 1, s * 0.02 } }),
		Transparency = nseq({ { 0, 1 }, { 0.3, 0 }, { 1, 0.2 } }), Speed = NumberRange.new(-s * 1.6, -s * 1.1), SpreadAngle = Vector2.new(180, 180),
		Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward })
	e:Emit(if low() then 14 else 30)
	local orb = HofVFX.Emitter(h, TEX.Orb, { Color = seq(WHITE, ICE), Lifetime = NumberRange.new(t), Size = nseq({ { 0, s * 0.9 }, { 1, s * 0.15 } }),
		Transparency = nseq({ { 0, 1 }, { 0.4, 0.35 }, { 1, 0 } }), LockedToPart = true })
	orb:Emit(1)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = ICE, 0, s * 3, false
	light.Parent = h
	tween(light, t, { Brightness = 2.5 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

function FrostFX.Burst(pos: Vector3, size: number?, opts: { [string]: any }?)
	opts = opts or {}
	local s = size or 12
	local lo = low()
	local color = opts.color or CYAN
	local h = holder(pos, 4)
	-- 1 the white-hot core and the light pulse
	HofVFX.Emitter(h, TEX.Orb, { Color = seq(WHITE, color), Lifetime = NumberRange.new(0.45), Size = nseq({ { 0, s * 0.6 }, { 0.25, s * 0.85 }, { 1, s * 0.2 } }),
		Transparency = nseq({ { 0, 0 }, { 1, 1 } }), LockedToPart = true }):Emit(1)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = ICE:Lerp(WHITE, 0.4), 9, s * 5, false
	light.Parent = h
	tween(light, 1.1, { Brightness = 0 })
	-- 2 the flipbook burst and ring (they face the camera), then the flat snow shockwave along the floor of the burst
	HofVFX.Emitter(h, TEX.Burst, { Color = seq(WHITE, color), Lifetime = NumberRange.new(0.9), FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		FlipbookStartRandom = false, Size = NumberSequence.new(s * 1.6), Rotation = NumberRange.new(0, 360), LockedToPart = true }):Emit(1)
	HofVFX.Emitter(h, TEX.Ring, { Color = seq(WHITE, ICE), Lifetime = NumberRange.new(0.7), FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		FlipbookStartRandom = false, Size = nseq({ { 0, s * 0.6 }, { 1, s * 2.2 } }), Transparency = nseq({ { 0, 0.1 }, { 1, 1 } }), LockedToPart = true }):Emit(1)
	local disc = Instance.new("Part")
	disc.Name = "FrostWave"
	disc.Anchored, disc.CanCollide, disc.CanQuery, disc.CanTouch, disc.CastShadow = true, false, false, false, false
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	disc.Color = ICE
	disc.Transparency = 0.35
	disc.Size = Vector3.new(0.15, s * 0.3, s * 0.3)
	disc.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	disc.Parent = h
	tween(disc, 0.6, { Size = Vector3.new(0.05, s * 3.2, s * 3.2), Transparency = 1 }, Enum.EasingStyle.Quart)
	-- 3 frost sparks: fast, then dragged to a stop and falling like ice dust
	HofVFX.Emitter(h, TEX.Sparkle, { Color = seq(WHITE, color), Lifetime = NumberRange.new(0.9, 1.7), FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
		FlipbookStartRandom = false, Speed = NumberRange.new(s * 2.2, s * 4), SpreadAngle = Vector2.new(180, 180), Drag = 3.2, Acceleration = Vector3.new(0, -9, 0),
		Size = nseq({ { 0, s * 0.09 }, { 1, s * 0.03 } }) }):Emit(if lo then 26 else 60)
	-- 4 rolling snow mist (lit by the scene, so it reads as real cold air, not a glow)
	smoke(h, { Color = seq(Color3.fromHex("#F4FBFF"), Color3.fromHex("#CFE6F5")), Lifetime = NumberRange.new(1.6, 2.6),
		Size = nseq({ { 0, s * 0.5 }, { 1, s * 1.5 } }), Transparency = nseq({ { 0, 1 }, { 0.15, 0.55 }, { 1, 1 } }),
		Speed = NumberRange.new(s * 0.6, s * 1.2), SpreadAngle = Vector2.new(180, 180), Drag = 2.2, Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-30, 30), Acceleration = Vector3.new(0, 1.5, 0) }):Emit(if lo then 8 else 16)
	-- 5 the cold wisp swirling out, and slow glints drifting down after
	HofVFX.Emitter(h, TEX.Wisp, { Color = seq(ICE, DEEP), Lifetime = NumberRange.new(1, 1.4), Size = nseq({ { 0, s * 0.5 }, { 1, s * 1.3 } }),
		Transparency = nseq({ { 0, 0.5 }, { 1, 1 } }), Speed = NumberRange.new(s * 0.3, s * 0.6), SpreadAngle = Vector2.new(180, 180),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90), Drag = 1.5 }):Emit(if lo then 3 else 6)
	task.delay(0.35, function()
		if not h.Parent then return end
		local g = HofVFX.Emitter(h, TEX.Sparkle, { Color = seq(WHITE, ICE), Lifetime = NumberRange.new(1.8, 2.6), Size = NumberSequence.new(s * 0.035),
			Transparency = nseq({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }), Speed = NumberRange.new(1, s * 0.5), SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -3, 0), Drag = 1, Shape = Enum.ParticleEmitterShape.Sphere })
		h.Size = Vector3.one * s * 1.2
		g:Emit(if lo then 14 else 34)
	end)
	if opts.shake then FrostFX.Shake(opts.shake, opts.shakeTime or 0.45, opts.externalShake) end
	if opts.flash then FrostFX.Flash(WHITE, opts.flash, 0.5) end
	return h
end

function FrostFX.GroundWave(pos: Vector3, radius: number?)
	local r = radius or 16
	local h = holder(pos + Vector3.new(0, 0.6, 0), 4, Vector3.new(r * 0.3, 0.2, r * 0.3))
	smoke(h, { Color = seq(WHITE, Color3.fromHex("#D6ECF8")), Lifetime = NumberRange.new(1.4, 2.2), Size = nseq({ { 0, 2.5 }, { 1, 7 } }),
		Transparency = nseq({ { 0, 1 }, { 0.2, 0.45 }, { 1, 1 } }), Speed = NumberRange.new(r * 0.9, r * 1.3), Drag = 2.4,
		Shape = Enum.ParticleEmitterShape.Cylinder, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward,
		ShapePartial = 1, EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(4, 4), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-25, 25), Acceleration = Vector3.new(0, 0.6, 0) }):Emit(if low() then 14 else 32)
	HofVFX.Emitter(h, TEX.Sparkle, { Color = seq(WHITE, ICE), Lifetime = NumberRange.new(0.8, 1.3), Size = NumberSequence.new(0.35), Speed = NumberRange.new(r, r * 1.6),
		Drag = 2.5, Shape = Enum.ParticleEmitterShape.Cylinder, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward, SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(0, -2, 0) }):Emit(if low() then 16 else 40)
end

-- snow past the lens: a box of flakes that rides in front of the camera
function FrostFX.Snowfall(camera: Camera, time: number)
	local h = holder(camera.CFrame.Position, time + 3, Vector3.new(40, 1, 40))
	local e = HofVFX.Emitter(h, TEX.Sparkle, { Color = seq(WHITE), LightEmission = 0.2, Rate = if low() then 40 else 110, Lifetime = NumberRange.new(2, 3),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22, 0.12), NumberSequenceKeypoint.new(1, 0.22, 0.12) }),
		Transparency = nseq({ { 0, 1 }, { 0.15, 0.15 }, { 0.85, 0.15 }, { 1, 1 } }), Speed = NumberRange.new(5, 8), EmissionDirection = Enum.NormalId.Bottom,
		SpreadAngle = Vector2.new(18, 18), Acceleration = Vector3.new(2.5, 0, 0), RotSpeed = NumberRange.new(-60, 60), FlipbookMode = Enum.ParticleFlipbookMode.Loop })
	local conn = RunService.RenderStepped:Connect(function()
		local cf = camera.CFrame
		h.CFrame = CFrame.new(cf.Position + cf.LookVector * 18 + Vector3.new(0, 12, 0))
	end)
	task.delay(time, function()
		conn:Disconnect()
		e.Enabled = false
	end)
end

-- a lasting cold aura on a statue / NPC (the model's bounding box bottom is where the mist pools)
function FrostFX.Aura(model: Model)
	local lo = low()
	local cf, size = model:GetBoundingBox()
	local feet = cf.Position - Vector3.new(0, size.Y / 2, 0)
	local h = Instance.new("Part")
	h.Name = "FrostAura"
	h.Anchored, h.CanCollide, h.CanQuery, h.CanTouch, h.CastShadow = true, false, false, false, false
	h.Transparency = 1
	h.Size = Vector3.new(size.X * 0.9, 0.2, size.Z * 0.9)
	h.CFrame = CFrame.new(feet + Vector3.new(0, 0.4, 0))
	h.Parent = Workspace
	-- 1 cold mist pooling and creeping off the base (lit, low, slow)
	smoke(h, { Name = "Mist", Color = seq(WHITE, Color3.fromHex("#D8EEFA")), Rate = if lo then 3 else 7, Lifetime = NumberRange.new(3.5, 5),
		Size = nseq({ { 0, 3 }, { 1, 7 } }), Transparency = nseq({ { 0, 1 }, { 0.3, 0.72 }, { 1, 1 } }), Speed = NumberRange.new(0.8, 1.8),
		SpreadAngle = Vector2.new(80, 80), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -0.15, 0), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-10, 10), Drag = 0.4 })
	-- 2 frost motes rising off the body
	local body = Instance.new("Part")
	body.Name = "FrostAuraBody"
	body.Anchored, body.CanCollide, body.CanQuery, body.CanTouch, body.CastShadow = true, false, false, false, false
	body.Transparency = 1
	body.Size = Vector3.new(size.X * 0.7, size.Y * 0.7, size.Z * 0.6)
	body.CFrame = CFrame.new(cf.Position)
	body.Parent = h
	HofVFX.Emitter(body, TEX.Sparkle, { Name = "Motes", Color = seq(WHITE, CYAN), Rate = if lo then 4 else 10, Lifetime = NumberRange.new(2.2, 3.4),
		Size = nseq({ { 0, 0.1 }, { 0.5, 0.35 }, { 1, 0.05 } }), Transparency = nseq({ { 0, 1 }, { 0.2, 0.1 }, { 1, 1 } }), Speed = NumberRange.new(0.6, 1.6),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(25, 25), Acceleration = Vector3.new(0, 0.6, 0),
		Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume })
	-- 3 a faint cold wisp hugging the body
	HofVFX.Emitter(body, TEX.Wisp, { Name = "Wisp", Color = seq(ICE, DEEP), Rate = if lo then 0.6 else 1.4, Lifetime = NumberRange.new(2.4, 3),
		Size = nseq({ { 0, size.X * 0.4 }, { 1, size.X * 0.75 } }), Transparency = nseq({ { 0, 1 }, { 0.4, 0.82 }, { 1, 1 } }), Speed = NumberRange.new(0.2, 0.6),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-25, 25), LightEmission = 0.6 })
	-- 4 a breathing cyan light and the armour's glow pieces pulsing with it
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range, light.Shadows = CYAN, 1.2, size.Y * 0.9, false
	light.Parent = body
	local glows = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Material == Enum.Material.Neon and d:GetAttribute("FrostFx") then table.insert(glows, d) end
	end
	local alive = true
	task.spawn(function()
		while alive and h.Parent do
			local k = 0.5 + 0.5 * math.sin(os.clock() * 1.6)
			light.Brightness = 0.8 + 1.2 * k
			for _, g in ipairs(glows) do g.LocalTransparencyModifier = 0.35 * (1 - k) end
			task.wait(1 / 20)
		end
	end)
	return function()
		alive = false
		for _, g in ipairs(glows) do g.LocalTransparencyModifier = 0 end
		h:Destroy()
	end
end

return FrostFX
