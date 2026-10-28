-- RaceFxController (M6, VFX note): race moments on your screen only - a dust burst from every runner
-- at GO, a blue swoosh when you overtake, the music swell at FINAL STRETCH, and for a win: a gold
-- flash, a short "slow-mo" camera push-in, sparkles at your feet and 3 spotlights on the finish line.
-- One pooled emitter part, nothing made per frame. Low graphics = fewer particles; Reduced motion =
-- no flash and no camera push.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Areas = require(Shared.Config.Areas)
local TrackPath = require(Shared.Util.TrackPath)

local P = UIKit.Palette
local make = UIKit.make
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Fx = {}
local ctx
local emitPart, dust, sparkle, blue
local swoosh, flash
local lights = {}

local function emitter(name, texture, color, size, life, speed)
	return make("ParticleEmitter", {
		Name = name,
		Texture = texture,
		Color = ColorSequence.new(color),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 1.8) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(life * 0.7, life),
		Speed = NumberRange.new(speed * 0.5, speed),
		SpreadAngle = Vector2.new(80, 25),
		Acceleration = Vector3.new(0, -2, 0),
		Rate = 0,
		LockedToPart = false,
		Parent = emitPart,
	})
end

local function burst(e, pos, n)
	if ctx.Settings and ctx.Settings.low() then
		n = math.ceil(n / 2)
	end
	emitPart.Position = pos
	e:Emit(n)
end

local function rootOf(r)
	local m = r.model
	if not m or not m.Parent then
		local found = r.modelName and workspace:FindFirstChild(r.modelName, true)
		m = found
	end
	return m and m:FindFirstChild("HumanoidRootPart")
end

function Fx.onGo(race)
	for _, r in race.runners do
		local root = rootOf(r)
		if root then
			burst(dust, root.Position - Vector3.new(0, 2.6, 0), 10)
		end
	end
end

function Fx.onOvertake(newPlace, oldPlace)
	if newPlace >= oldPlace then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(blue, root.Position - Vector3.new(0, 1.5, 0), 14)
	end
	-- a blue streak across the screen
	swoosh.Position = UDim2.new(-0.4, 0, 0.62, 0)
	swoosh.Visible = true
	swoosh.BackgroundTransparency = 0.25
	UIKit.tween(swoosh, 0.35, { Position = UDim2.new(1.1, 0, 0.58, 0), BackgroundTransparency = 0.8 }, Enum.EasingStyle.Quad)
	task.delay(0.36, function()
		swoosh.Visible = false
	end)
end

function Fx.onFinalStretch()
	if ctx.Music and ctx.Music.swell then
		ctx.Music.swell()
	end
end

local function spotlights(race)
	local area = Areas[race.areaId or "Hub"] or Areas.Hub
	local path = race.path or TrackPath.for_(area.Track)
	for i, l in lights do
		local lane = math.clamp(i * 2, 1, area.Track.Lanes)
		local cf = path.runnerCFrame(lane, 0.999, race.laps or 1)
		l.part.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, 14, 0), cf.Position)
		l.part.Parent = workspace.CurrentCamera
		l.light.Enabled = true
		l.light.Brightness = 0
		UIKit.tween(l.light, 0.3, { Brightness = 6 })
	end
	task.delay(3.2, function()
		for _, l in lights do
			UIKit.tween(l.light, 0.5, { Brightness = 0 })
		end
		task.delay(0.55, function()
			for _, l in lights do
				l.light.Enabled = false
				l.part.Parent = nil
			end
		end)
	end)
end

function Fx.onFinish(place, race)
	if place ~= 1 then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(sparkle, root.Position, 30)
	end
	spotlights(race)
	if ctx.Settings and ctx.Settings.reduced() then
		return
	end
	-- the gold flash + the "slow-mo" push-in (the race camera eases back on its own)
	flash.Visible = true
	flash.BackgroundTransparency = 0.35
	UIKit.tween(flash, 0.6, { BackgroundTransparency = 1 })
	task.delay(0.62, function()
		flash.Visible = false
	end)
	local fov = camera.FieldOfView
	UIKit.tween(camera, 0.25, { FieldOfView = fov - 12 }, Enum.EasingStyle.Quad)
	task.delay(0.55, function()
		UIKit.tween(camera, 0.6, { FieldOfView = fov }, Enum.EasingStyle.Sine)
	end)
end

function Fx.start(c)
	ctx = c
	ctx.RaceFx = Fx
	emitPart = make("Part", { Name = "RaceFx", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1), Parent = workspace.CurrentCamera })
	dust = emitter("Dust", "rbxasset://textures/particles/smoke_main.dds", Color3.fromHex("#D9DEE6"), 1.2, 0.9, 6)
	blue = emitter("Blue", "rbxasset://textures/particles/sparkles_main.dds", P.BrightBlue, 0.6, 0.5, 10)
	blue.LightEmission = 0.8
	sparkle = emitter("Gold", "rbxasset://textures/particles/sparkles_main.dds", P.Gold, 0.7, 1.2, 14)
	sparkle.LightEmission = 1
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Acceleration = Vector3.new(0, 6, 0)
	for i = 1, 3 do
		local p = make("Part", { Name = "WinLight", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(0.5, 0.5, 0.5) })
		local l = make("SpotLight", { Face = Enum.NormalId.Front, Angle = 40, Range = 26, Brightness = 0, Color = Color3.fromHex("#FFE9B0"), Shadows = false, Enabled = false, Parent = p })
		lights[i] = { part = p, light = l }
	end
	local canvas = ctx.Hud.canvas
	swoosh = make("Frame", { Name = "Swoosh", BackgroundColor3 = P.BrightBlue, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0.5, 0, 0, 6), Rotation = -4, Visible = false, ZIndex = 9, Parent = canvas })
	make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = swoosh })
	flash = make("Frame", { Name = "WinFlash", BackgroundColor3 = P.Gold, BorderSizePixel = 0, Position = UDim2.fromOffset(0, -80), Size = UDim2.new(1, 0, 1, 80), Visible = false, ZIndex = 8, Parent = canvas })
end

return Fx
