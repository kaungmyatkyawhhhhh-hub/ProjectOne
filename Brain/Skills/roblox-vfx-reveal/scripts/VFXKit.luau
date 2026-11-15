--!strict
-- VFXKit: client-side hit VFX and rarity-reveal building blocks (roblox-vfx-reveal skill).
-- Put in ReplicatedStorage. Call ONLY from LocalScripts: the server fires a RemoteEvent, each client plays the VFX.
-- Everything is made from engine parts, Highlights, ColorCorrection and UI: no texture uploads needed to start.
-- Every effect cleans itself up (Debris / task.delay) and honours GuiService.ReducedMotionEnabled
-- (no shake, no FOV punch, flashes become short fades).
-- Tested 16 Nov 2026 in Studio Play (Client) on the MM Outfit Catalog place.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Debris = game:GetService("Debris")

local VFXKit = {}

local function reduced(): boolean
	local ok, v = pcall(function() return GuiService.ReducedMotionEnabled end)
	return ok and v == true
end

local function tween(obj: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function fxFolder(): Folder
	local f = workspace:FindFirstChild("ClientVFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ClientVFX"
		f.Parent = workspace
	end
	return f :: Folder
end

local function overlayGui(): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sg = pg:FindFirstChild("VFXOverlay") :: ScreenGui?
	if not sg then
		local s = Instance.new("ScreenGui")
		s.Name = "VFXOverlay"
		s.ResetOnSpawn = false
		s.IgnoreGuiInset = true
		s.ScreenInsets = Enum.ScreenInsets.None
		s.DisplayOrder = 900 -- full-screen reveals sit above menus and toasts
		s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		s.Parent = pg
		sg = s
	end
	return sg :: ScreenGui
end

-- OKLCH -> Color3 (equal L = equal perceived brightness; use it for rarity palettes and multi-key gradients)
function VFXKit.oklch(L: number, C: number, hDeg: number): Color3
	local h = math.rad(hDeg)
	local a, b = C * math.cos(h), C * math.sin(h)
	local l_ = L + 0.3963377774 * a + 0.2158037573 * b
	local m_ = L - 0.1055613458 * a - 0.0638541728 * b
	local s_ = L - 0.0894841775 * a - 1.2914855480 * b
	local l, m, s = l_ ^ 3, m_ ^ 3, s_ ^ 3
	local r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	local g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	local bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
	local function enc(x: number): number
		x = math.clamp(x, 0, 1)
		return if x <= 0.0031308 then 12.92 * x else 1.055 * x ^ (1 / 2.4) - 0.055
	end
	return Color3.new(enc(r), enc(g), enc(bb))
end

------------------------------------------------------------------ camera
-- Camera shake: decaying random offset, applied after the camera scripts (RenderPriority.Camera + 1).
function VFXKit.shake(intensity: number?, duration: number?)
	if reduced() then return end
	local amp, dur = intensity or 0.6, duration or 0.35
	local cam = workspace.CurrentCamera
	local name = "VFXShake" .. tostring(math.random(1, 1e6))
	local t0 = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local k = 1 - (os.clock() - t0) / dur
		if k <= 0 then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local a = amp * k * k
		cam.CFrame = cam.CFrame * CFrame.new(math.random(-100, 100) / 100 * a * 0.3, math.random(-100, 100) / 100 * a * 0.3, 0)
			* CFrame.Angles(0, 0, math.rad(math.random(-100, 100) / 100 * a * 2))
	end)
end

-- FOV punch: snap out, ease back (sells impact and "zoom-in" moments).
function VFXKit.fovPunch(delta: number?, back: number?)
	if reduced() then return end
	local cam = workspace.CurrentCamera
	local base = cam.FieldOfView
	cam.FieldOfView = base + (delta or 8)
	tween(cam, back or 0.35, {FieldOfView = base}, Enum.EasingStyle.Quint)
end

------------------------------------------------------------------ screen
VFXKit.overlay = overlayGui

-- Full-screen flash. White = power, rarity colour = reveal. Short in, short hold, longer out.
-- peak = the most opaque it gets (0 = solid; 0.7 = a gentle wash for frequent moments like purchases).
function VFXKit.flash(color: Color3?, inT: number?, hold: number?, outT: number?, peak: number?)
	local f = Instance.new("Frame")
	f.Name = "Flash"
	f.Size = UDim2.fromScale(1, 1)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color or Color3.new(1, 1, 1)
	f.BackgroundTransparency = 1
	f.ZIndex = 50
	f.Parent = overlayGui()
	local i, h, o = inT or 0.05, hold or 0.05, outT or 0.35
	if reduced() then i, h, o = 0.05, 0, 0.1 end
	tween(f, i, {BackgroundTransparency = peak or 0})
	task.delay(i + h, function() tween(f, o, {BackgroundTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end)
	Debris:AddItem(f, i + h + o + 0.1)
end

-- Impact frame (the anime/"HA HA" look): 2-4 frames where the world goes one flat colour and fighters become
-- black silhouettes with a white rim. Built from ColorCorrection + Highlight, so it works on any map.
-- style "red" = red world, black silhouettes; "white" = white world, black silhouettes; "invert" = black world, white silhouettes.
function VFXKit.impactFrame(models: {Model}, style: string?, duration: number?)
	local dur = duration or 0.09 -- ~5 frames at 60 fps; longer than 0.15 s stops reading as a "frame"
	if reduced() then dur = 0.05 end
	local st = style or "red"
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VFXImpactCC"
	cc.Saturation = -1
	cc.Contrast = 1
	if st == "red" then
		cc.TintColor = Color3.fromRGB(255, 40, 40)
		cc.Brightness = 0.25
	elseif st == "white" then
		cc.Brightness = 0.9
	else
		cc.Brightness = -0.9
	end
	cc.Parent = Lighting
	local hl: {Highlight} = {}
	for _, m in models do
		local h = Instance.new("Highlight")
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = 0
		h.OutlineTransparency = 0
		h.FillColor = if st == "invert" then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
		h.OutlineColor = if st == "invert" then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
		h.Adornee = m
		h.Parent = fxFolder()
		table.insert(hl, h)
	end
	task.delay(dur, function()
		cc:Destroy()
		for _, h in hl do h:Destroy() end
	end)
end

-- UI starburst: rays + a soft glow ring drawn in the overlay ScreenGui. Use it when the moment
-- happens over UI (a ViewportFrame stage, a menu) where world parts would be hidden.
-- center = screen position (UDim2), length in px.
function VFXKit.uiBurst(center: UDim2, color: Color3?, rays: number?, length: number?, time: number?)
	local n, len, t = rays or 14, length or 160, time or 0.55
	local c = color or Color3.fromRGB(255, 220, 140)
	local holder = Instance.new("Frame")
	holder.Name = "UIBurst"
	holder.BackgroundTransparency = 1
	holder.Position = center
	holder.Size = UDim2.fromOffset(0, 0)
	holder.ZIndex = 55
	holder.Parent = overlayGui()
	local glow = Instance.new("Frame")
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Size = UDim2.fromOffset(20, 20)
	glow.BackgroundColor3 = c
	glow.BackgroundTransparency = 0.35
	glow.ZIndex = 55
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0.5, 0)
	gc.Parent = glow
	glow.Parent = holder
	tween(glow, t, {Size = UDim2.fromOffset(len * 1.3, len * 1.3), BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
	if not reduced() then
		for i = 1, n do
			local a = (i / n) * math.pi * 2 + math.random() * 0.15
			local l = len * (0.6 + math.random() * 0.4)
			local w = 4 + math.random() * 3
			local ray = Instance.new("Frame")
			ray.AnchorPoint = Vector2.new(0.5, 0.5)
			ray.Rotation = math.deg(a)
			ray.BackgroundColor3 = c
			ray.BorderSizePixel = 0
			ray.Size = UDim2.fromOffset(w, 0)
			ray.ZIndex = 56
			local g = Instance.new("UIGradient") -- soft tips
			g.Rotation = 90
			g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.35, 0), NumberSequenceKeypoint.new(1, 1)})
			g.Parent = ray
			ray.Parent = holder
			local dx, dy = math.sin(a), -math.cos(a)
			tween(ray, t * 0.5, {Size = UDim2.fromOffset(w, l), Position = UDim2.fromOffset(dx * l * 0.6, dy * l * 0.6)}, Enum.EasingStyle.Quint)
			task.delay(t * 0.5, function()
				tween(ray, t * 0.5, {Size = UDim2.fromOffset(1, l * 1.1), Position = UDim2.fromOffset(dx * l * 0.85, dy * l * 0.85), BackgroundTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end)
		end
	end
	Debris:AddItem(holder, t + 0.1)
end

------------------------------------------------------------------ world
local function neon(size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cf
	if shape then p.Shape = shape end
	p.Parent = fxFolder()
	return p
end

-- Shockwave ring on the ground: flat neon cylinder that grows and fades.
function VFXKit.shockwave(pos: Vector3, color: Color3?, radius: number?, time: number?)
	local r, t = radius or 18, time or 0.45
	local p = neon(Vector3.new(0.3, 1, 1), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color or Color3.new(1, 1, 1), Enum.PartType.Cylinder)
	p.Transparency = 0.1
	tween(p, t, {Size = Vector3.new(0.15, r * 2, r * 2), Transparency = 1}, Enum.EasingStyle.Quint)
	Debris:AddItem(p, t + 0.05)
end

-- Starburst: thin neon spikes that shoot out from a point (the RNG "LEGENDARY" burst, made in 3D).
function VFXKit.starburst(pos: Vector3, color: Color3?, spikes: number?, length: number?, time: number?)
	local n, len, t = spikes or 14, length or 14, time or 0.5
	local cam = workspace.CurrentCamera
	local face = CFrame.lookAt(pos, cam.CFrame.Position) -- spikes lie in the plane facing the camera
	for i = 1, n do
		local ang = (i / n) * math.pi * 2 + math.random() * 0.2
		local l = len * (0.55 + math.random() * 0.45)
		local dir = face * CFrame.Angles(0, 0, ang)
		local p = neon(Vector3.new(0.25, 0.25, 0.25), dir * CFrame.new(0, 0.2, 0), color or Color3.new(1, 0.9, 0.5))
		tween(p, t * 0.45, {Size = Vector3.new(0.35, l, 0.35), CFrame = dir * CFrame.new(0, l / 2, 0)}, Enum.EasingStyle.Quint)
		task.delay(t * 0.45, function()
			tween(p, t * 0.55, {Size = Vector3.new(0.05, l * 1.15, 0.05), Transparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		Debris:AddItem(p, t + 0.05)
	end
	local core = neon(Vector3.one * 0.5, CFrame.new(pos), Color3.new(1, 1, 1), Enum.PartType.Ball)
	tween(core, t * 0.3, {Size = Vector3.one * 4}, Enum.EasingStyle.Back)
	task.delay(t * 0.3, function() tween(core, t * 0.7, {Size = Vector3.one * 0.2, Transparency = 1}) end)
	Debris:AddItem(core, t + 0.05)
end

-- Debris burst (ground slam): chunks that fly up and fall, matching the floor colour.
function VFXKit.debris(pos: Vector3, color: Color3?, count: number?)
	for _ = 1, count or 10 do
		local s = 0.4 + math.random() * 0.8
		local p = Instance.new("Part")
		p.Size = Vector3.new(s, s, s)
		p.Color = color or Color3.fromRGB(90, 90, 95)
		p.Material = Enum.Material.Slate
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CFrame = CFrame.new(pos + Vector3.new(math.random(-2, 2), 0.5, math.random(-2, 2)))
		p.Parent = fxFolder()
		p.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), math.random(25, 45), math.random(-20, 20))
		p.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
		task.delay(0.9, function() tween(p, 0.3, {Transparency = 1, Size = Vector3.zero}) end)
		Debris:AddItem(p, 1.3)
	end
end

------------------------------------------------------------------ reveal card
-- Rarity title card: big tier word (depth text), a subtitle in [ brackets ], the odds line. Pops in, holds, fades.
-- center (optional) moves the card, e.g. over the outfit when a side panel takes the right of the screen.
function VFXKit.titleCard(tier: string, color: Color3, subtitle: string?, odds: string?, hold: number?, center: UDim2?)
	local root = Instance.new("CanvasGroup")
	root.Name = "TitleCard"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = center or UDim2.fromScale(0.5, 0.42)
	root.Size = UDim2.fromScale(0.9, 0.4)
	root.GroupTransparency = 1
	root.ZIndex = 60
	local scale = Instance.new("UIScale")
	scale.Scale = 1.35
	scale.Parent = root
	local function text(t: string, y: number, h: number, c: Color3, weight: Enum.FontWeight, z: number, off: number?)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.AnchorPoint = Vector2.new(0.5, 0)
		l.Position = UDim2.new(0.5, 0, y, off or 0)
		l.Size = UDim2.fromScale(1, h)
		l.Text = t
		l.TextScaled = true
		l.TextColor3 = c
		l.FontFace = Font.fromName("BuilderSans", weight)
		l.ZIndex = z
		local k = Instance.new("UITextSizeConstraint")
		k.MinTextSize = 14
		k.MaxTextSize = 96
		k.Parent = l
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = Color3.fromRGB(20, 16, 40)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		s.Parent = l
		l.Parent = root
		return l
	end
	local h, s, v = color:ToHSV()
	text(string.upper(tier), 0, 0.42, Color3.fromHSV(h, s, v * 0.45), Enum.FontWeight.Heavy, 61, 5) -- depth copy
	text(string.upper(tier), 0, 0.42, color, Enum.FontWeight.Heavy, 62)
	if subtitle then text("[ " .. string.upper(subtitle) .. " ]", 0.46, 0.16, Color3.new(1, 1, 1), Enum.FontWeight.Bold, 62) end
	if odds then text(odds, 0.68, 0.14, Color3.fromRGB(255, 236, 160), Enum.FontWeight.Bold, 62) end
	root.Parent = overlayGui()
	local r = reduced()
	if r then scale.Scale = 1 else tween(scale, 0.35, {Scale = 1}, Enum.EasingStyle.Back) end
	tween(root, 0.15, {GroupTransparency = 0})
	local hd = hold or 2.2
	task.delay(hd, function() tween(root, 0.3, {GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end)
	Debris:AddItem(root, hd + 0.4)
	return root
end

------------------------------------------------------------------ recipes
-- One heavy hit: impact frame -> shockwave + debris + shake + FOV punch, in that order (the hit lands on frame 0).
function VFXKit.heavyHit(attacker: Model?, victim: Model, color: Color3?)
	local root = victim:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local models = {victim}
	if attacker then table.insert(models, attacker) end
	VFXKit.impactFrame(models, "red", 0.09)
	task.delay(0.09, function()
		local hum = victim:FindFirstChildOfClass("Humanoid")
		local down = (if hum then hum.HipHeight else 2) + root.Size.Y / 2 - 0.1 -- feet level, works for R6 and R15
		local floor = root.Position - Vector3.new(0, down, 0)
		VFXKit.shockwave(floor, color or Color3.fromRGB(255, 90, 90), 14, 0.4)
		VFXKit.debris(floor, nil, 8)
		VFXKit.shake(0.8, 0.35)
		VFXKit.fovPunch(6, 0.3)
	end)
end

-- Rarity tiers: each tier escalates on ONE axis more than the last (colour -> burst -> flash -> shake -> cutscene).
-- L stays 0.75 so every tier colour reads equally bright; only the hue changes.
VFXKit.Tiers = {
	{name = "Common", color = VFXKit.oklch(0.80, 0.02, 250), burst = 0, flash = false, shake = 0, hold = 1.0},
	{name = "Rare", color = VFXKit.oklch(0.75, 0.15, 250), burst = 8, flash = false, shake = 0, hold = 1.2},
	{name = "Epic", color = VFXKit.oklch(0.75, 0.17, 305), burst = 12, flash = false, shake = 0.2, hold = 1.4},
	{name = "Legendary", color = VFXKit.oklch(0.80, 0.16, 85), burst = 16, flash = true, shake = 0.4, hold = 1.8},
	{name = "Secret", color = VFXKit.oklch(0.70, 0.20, 25), burst = 20, flash = true, shake = 0.6, hold = 2.0},
	{name = "Transcendent", color = VFXKit.oklch(0.85, 0.12, 95), burst = 24, flash = true, shake = 0.8, hold = 2.6},
}

-- Reveal one roll result at a world point (above the player's head). tierIndex into VFXKit.Tiers.
function VFXKit.reveal(pos: Vector3, tierIndex: number, itemName: string?, odds: string?)
	local tier = VFXKit.Tiers[math.clamp(tierIndex, 1, #VFXKit.Tiers)]
	if tier.burst > 0 then VFXKit.starburst(pos, tier.color, tier.burst, 8 + tier.burst * 0.5, 0.6) end
	if tier.flash then VFXKit.flash(tier.color, 0.04, 0.04, 0.4) end
	if tier.shake > 0 then VFXKit.shake(tier.shake, 0.4) end
	VFXKit.titleCard(tier.name, tier.color, itemName, odds, tier.hold)
end

return VFXKit
