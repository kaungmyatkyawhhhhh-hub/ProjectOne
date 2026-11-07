-- VfxLibrary (Galaxy Incremental, VFX pass 6 Nov; vault "VFX map (every effect) + new prompts + Claude Code prompt";
-- checklist #264-#318): EVERY world + screen effect in one client-side module, all with our own textures (VfxTextures).
-- The server only fires the event; this draws. One function per moment (V.Supernova, V.ForgeReveal, V.PadBuild, ...).
--  * 3 beats on every moment (#277): wind-up -> a 1-3 frame IMPACT (the flash / ring / burst on frame 0) -> a 0.4-1 s fade
--    (+ a slow layer that lingers); bigger moments add layers, not just size (escalation, #278).
--  * POOLED: a free emitter (its last particles gone) is re-dressed for the next burst; everything is Emit(n) with Rate 0,
--    except the few timed streams (a handle with :Stop()); nothing is left running (#276, #282).
--  * BUDGET: at most 300 particles alive from here; a burst past ~140 studs from the camera is skipped (unless it's yours);
--    phones get half the particles, same timing (#188, #304); 1 Highlight at a time; at most 3 screen flashes a second;
--    Reduced Motion = no shake, no flash (#315).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local T = require(script.Parent:WaitForChild("VfxTextures"))
local V = {}
V.T = T
V.TimeScale = 1 -- (Studio frame-strip tests slow every particle down; the game never changes it)

local MAX_PARTICLES = 300
local FAR = 140
local MAX_FLASHES = 3 -- (a second)
local WHITE = Color3.new(1, 1, 1)

local player = Players.LocalPlayer
local function calm(): boolean return GuiService.ReducedMotionEnabled end
V.calm = calm
-- a phone: touch, no keyboard (the Studio test frame too)
local function phone(): boolean
	if RunService:IsStudio() and (workspace:GetAttribute("TestPhone") == true or (workspace:GetAttribute("TestDevice") ~= nil and workspace:GetAttribute("TestDevice") ~= "pc")) then return true end
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end
V.phone = phone

local function tween(o, goal, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function seq(a, b, c)
	if c then return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.5, b), NumberSequenceKeypoint.new(1, c) }) end
	return NumberSequence.new(a, b or a)
end
V.seq = seq
local function cseq(a: Color3, b: Color3?) return ColorSequence.new(a, b or a) end
-- the rainbow (Celestial, the aura_mythic ring)
V.RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 80)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 255, 120)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(170, 110, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 110, 220)),
})

------------------------------------------------------------------------ the pool + the budget
local folder = workspace:FindFirstChild("GalaxyVfx") or Instance.new("Folder")
folder.Name = "GalaxyVfx"
folder.Parent = workspace
local pool = {} -- { part, em, freeAt }
local live = {} -- { expire, n }
local function liveCount(): number
	local now, n = os.clock(), 0
	for i = #live, 1, -1 do
		if live[i][1] <= now then table.remove(live, i) else n += live[i][2] end
	end
	return n
end
V.liveCount = liveCount
local function acquire()
	local now = os.clock()
	for _, e in ipairs(pool) do
		if e.freeAt <= now and not e.stream then return e end
	end
	local part = Instance.new("Part")
	part.Name = "Vfx"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch, part.CastShadow = true, false, false, false, false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Parent = folder
	local em = Instance.new("ParticleEmitter")
	em.Rate = 0
	em.Parent = part
	local e = { part = part, em = em, freeAt = 0 }
	table.insert(pool, e)
	return e
end
-- how many of `n` may go out now (phones half; never past the 300 alive)
local function allow(n: number, life: number): number
	local want = if phone() then math.ceil(n * 0.5) else n
	local room = MAX_PARTICLES - liveCount()
	local k = math.max(0, math.min(want, room))
	if k > 0 then table.insert(live, { os.clock() + life, k }) end
	return k
end
local function far(at: Vector3, mine: boolean?): boolean
	if mine then return false end
	local cam = workspace.CurrentCamera
	return cam ~= nil and (cam.CFrame.Position - at).Magnitude > FAR
end
V.far = far

-- dress an emitter. o: tex (a VfxTextures name), alpha (true = the _alpha file, tinted; default the _add file + LightEmission
-- 1), color (Color3 / ColorSequence), size (number = the peak; or sizeSeq), transp, life {min, max}, speed {min, max},
-- spread (degrees; default 180), dir (NormalId; default Top), drag, accel, rot (spin speed), rotation {min, max},
-- orient ("vel" = faces where it flies, "flat" = lies flat, "up" = stands up), flip ("once" / "loop"), fps, light,
-- brightness, shape { size = Vector3, kind = "Sphere" / "Box" / "Disc", inward = bool }, z (ZOffset), locked, squash
local function dress(e, o)
	local em: ParticleEmitter = e.em
	local add = not o.alpha
	-- (7 Nov, owner: "black boxes again": every particle / beam / trail texture is the _alpha file now (transparent background),
	-- so no LightEmission value can show the _add file's black square. Tools/VfxTextureAudit checks it)
	local tex, mustAdd = T.fx(o.tex)
	em.Texture = tex or T.alpha.sparkle_star
	-- (the textures are coloured art: a tint multiplies it, so an _add texture keeps 35% white to stay bright)
	local c = o.color or WHITE
	em.Color = if typeof(c) == "ColorSequence" then c else cseq(if add then (c :: Color3):Lerp(WHITE, 0.35) else c)
	em.LightEmission = if mustAdd then 1 else o.light or (if add then 1 else 0)
	em.LightInfluence = 0
	em.Brightness = o.brightness or 1
	local sz = o.size or 1
	em.Size = o.sizeSeq or NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 0.4), NumberSequenceKeypoint.new(0.2, sz), NumberSequenceKeypoint.new(1, sz * 0.2) })
	em.Squash = o.squash or NumberSequence.new(0)
	em.Transparency = o.transp or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	local life = o.life or { 0.6, 1.2 }
	em.Lifetime = NumberRange.new(life[1], life[2])
	local sp = o.speed or { 6, 14 }
	em.Speed = NumberRange.new(sp[1], sp[2])
	local spread = o.spread or 180
	em.SpreadAngle = Vector2.new(spread, spread)
	em.EmissionDirection = o.dir or Enum.NormalId.Top
	em.Drag = o.drag or 0
	em.Acceleration = o.accel or Vector3.zero
	em.RotSpeed = NumberRange.new(-(o.rot or 0), o.rot or 0)
	local r = o.rotation or { 0, 360 }
	em.Rotation = NumberRange.new(r[1], r[2])
	em.Orientation = if o.orient == "vel" then Enum.ParticleOrientation.VelocityParallel
		elseif o.orient == "flat" then Enum.ParticleOrientation.VelocityPerpendicular
		elseif o.orient == "up" then Enum.ParticleOrientation.FacingCameraWorldUp
		else Enum.ParticleOrientation.FacingCamera
	if o.flip then
		em.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		em.FlipbookMode = if o.flip == "loop" then Enum.ParticleFlipbookMode.Loop else Enum.ParticleFlipbookMode.OneShot
		local fps = o.fps or 20
		em.FlipbookFramerate = NumberRange.new(fps, fps)
		em.FlipbookStartRandom = o.flip == "loop"
	else
		em.FlipbookLayout = Enum.ParticleFlipbookLayout.None
	end
	em.ZOffset = o.z or 0
	em.LockedToPart = o.locked == true
	em.TimeScale = V.TimeScale
	local sh = o.shape
	if sh then
		e.part.Size = sh.size
		em.Shape = Enum.ParticleEmitterShape[sh.kind or "Sphere"]
		em.ShapeInOut = if sh.inward then Enum.ParticleEmitterShapeInOut.Inward else Enum.ParticleEmitterShapeInOut.Outward
		em.ShapeStyle = if sh.surface then Enum.ParticleEmitterShapeStyle.Surface else Enum.ParticleEmitterShapeStyle.Volume
	else
		e.part.Size = Vector3.new(0.2, 0.2, 0.2)
		em.Shape = Enum.ParticleEmitterShape.Box
		em.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		em.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end
	return life
end

-- ONE burst: `count` particles of one texture at `at` (a Vector3 or a CFrame: a CFrame turns the emission direction).
-- o as in dress, + count, mine (yours: never skipped for distance), delay
function V.Burst(at: Vector3 | CFrame, o)
	if o.delay and o.delay > 0 then
		task.delay(o.delay, function() o.delay = nil V.Burst(at, o) end)
		return
	end
	local cf = if typeof(at) == "CFrame" then at else CFrame.new(at)
	if far(cf.Position, o.mine) then return end
	local life = o.life or { 0.6, 1.2 }
	local n = allow(o.count or 10, life[2])
	if n <= 0 then return end
	local e = acquire()
	dress(e, o)
	e.part.CFrame = cf
	e.freeAt = os.clock() + life[2] + 0.1
	e.em:Emit(n)
end
-- a ring flashing out: the shockwave_ring texture (or `o.tex`) growing from 15% to `radius` and fading. flat = lies on the
-- ground (a shockwave across the floor); otherwise it faces the camera
function V.Ring(at: Vector3, radius: number, colour: Color3 | ColorSequence, t: number?, o)
	o = o or {}
	t = t or 0.5
	V.Burst(at, { tex = o.tex or "shockwave_ring", alpha = o.alpha, count = 1, color = colour, speed = { 0.01, 0.01 }, spread = 0, life = { t, t },
		orient = if o.flat then "flat" else nil, rotation = { 0, 360 }, rot = o.rot, mine = o.mine, delay = o.delay, light = o.light, brightness = o.brightness,
		sizeSeq = NumberSequence.new({ NumberSequenceKeypoint.new(0, radius * 0.15), NumberSequenceKeypoint.new(1, radius) }),
		transp = o.transp or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.25), NumberSequenceKeypoint.new(1, 1) }) })
end
-- one big still image that pops (scale in fast, hold, fade): a flash, a starburst, a crown, an aura flare
function V.Pop(at: Vector3, tex: string, size: number, colour: Color3 | ColorSequence, t: number?, o)
	o = o or {}
	t = t or 0.5
	V.Burst(at, { tex = tex, alpha = o.alpha, count = o.count or 1, color = colour, speed = { 0.01, 0.01 }, spread = 0, life = { t, t }, rot = o.rot,
		rotation = o.rotation or { 0, 0 }, orient = o.orient, mine = o.mine, delay = o.delay, z = o.z, brightness = o.brightness, light = o.light,
		sizeSeq = o.sizeSeq or NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.35), NumberSequenceKeypoint.new(0.12, size), NumberSequenceKeypoint.new(1, size * 1.1) }),
		transp = o.transp or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }) })
end
-- a TIMED STREAM (Rate > 0) for a wind-up or a loop; returns a handle: h:Stop() (the particles alive finish), h:Move(at)
function V.Stream(at: Vector3 | CFrame, rate: number, o)
	local cf = if typeof(at) == "CFrame" then at else CFrame.new(at)
	local e = acquire()
	local life = dress(e, o)
	e.part.CFrame = cf
	e.stream = true
	local r = if phone() then rate * 0.5 else rate
	-- (the budget: what this stream keeps alive, counted while it runs)
	local cost = math.ceil(r * (life[1] + life[2]) / 2)
	local slot = { math.huge, cost }
	table.insert(live, slot)
	e.em.Rate = r
	local h = {}
	function h:Stop()
		if not e.stream then return end
		e.em.Rate = 0
		e.stream = nil
		e.freeAt = os.clock() + life[2] + 0.1
		slot[1] = os.clock() + life[2]
	end
	function h:Move(to: Vector3 | CFrame)
		e.part.CFrame = if typeof(to) == "CFrame" then to else CFrame.new(to)
	end
	function h:Emit(n: number) e.em:Emit(n) end
	h.em = e.em
	if o.duration then task.delay(o.duration, function() h:Stop() end) end
	return h
end

------------------------------------------------------------------------ the screen: flash + shake, the Highlight
local screen: ScreenGui? = nil
local function screenGui(): ScreenGui
	if screen and screen.Parent then return screen end
	local g = Instance.new("ScreenGui")
	g.Name = "GalaxyVfxScreen"
	g.IgnoreGuiInset = true
	g.ResetOnSpawn = false
	g.DisplayOrder = 20
	g.Parent = player:WaitForChild("PlayerGui")
	screen = g
	return g
end
local flashes = {}
-- a screen flash (Reduced Motion: none; at most 3 a second)
function V.Flash(colour: Color3?, peak: number?, t: number?)
	if calm() then return end
	local now = os.clock()
	for i = #flashes, 1, -1 do if now - flashes[i] > 1 then table.remove(flashes, i) end end
	if #flashes >= MAX_FLASHES then return end
	table.insert(flashes, now)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = colour or WHITE
	f.BackgroundTransparency = 1 - (peak or 0.6)
	f.ZIndex = 50
	f.Parent = screenGui()
	tween(f, { BackgroundTransparency = 1 }, t or 0.35)
	task.delay((t or 0.35) + 0.05, function() f:Destroy() end)
end
-- a short camera shake (Reduced Motion: none)
local shakeN = 0
function V.Shake(amp: number, t: number)
	if calm() then return end
	shakeN += 1
	local name = "GalaxyVfxShake" .. shakeN
	local t0 = os.clock()
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 3, function()
		local k = (os.clock() - t0) / t
		if k > 1 then RunService:UnbindFromRenderStep(name) return end
		local cam = workspace.CurrentCamera
		local a = amp * (1 - k)
		cam.CFrame = cam.CFrame * CFrame.new(math.noise(k * 30, 1) * a, math.noise(k * 30, 2) * a, 0)
	end)
end
-- the ONE Highlight (an outline glow round a model for `t` s; a new one moves it)
local hl: Highlight? = nil
function V.Highlight(target: Instance, colour: Color3, t: number?)
	if not hl or not hl.Parent then
		hl = Instance.new("Highlight")
		hl.Name = "GalaxyVfxHighlight"
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = folder
	end
	local h = hl :: Highlight
	h.Adornee = target
	h.FillColor, h.OutlineColor = colour, colour:Lerp(WHITE, 0.4)
	h.FillTransparency, h.OutlineTransparency = 0.45, 0
	h.Enabled = true
	tween(h, { FillTransparency = 1, OutlineTransparency = 1 }, t or 1.2, Enum.EasingStyle.Sine)
end

------------------------------------------------------------------------ small world moments
-- a sparkle pop (the base layer of many moments)
function V.Sparkles(at: Vector3, n: number, colour: Color3?, size: number?, o)
	o = o or {}
	-- (sparkle_star is a cyan star: cool colours use it; warm ones the white-cored starburst_twinkle, which takes any tint)
	local col = colour or Color3.fromRGB(255, 230, 160)
	local cool = col.B > col.R
	V.Burst(at, { tex = o.tex or (if cool then "sparkle_star" else "starburst_twinkle"), count = n, color = col, size = size or 0.7, speed = o.speed or { 6, 14 },
		life = { 0.6, 1.2 }, drag = 3, rot = 90, mine = o.mine, delay = o.delay })
end
-- #287/#307: a comet caught: a burst of 16 stardust motes + a small ring + the head flaring
function V.CometCatch(at: Vector3, colour: Color3?, golden: boolean?)
	local col = colour or Color3.fromRGB(170, 235, 255)
	V.Pop(at, "comet_head", if golden then 7 else 5, col:Lerp(WHITE, 0.3), 0.25, { mine = true })
	V.Burst(at, { tex = "stardust_mote", count = 16, color = col, size = 0.9, speed = { 8, 18 }, life = { 0.5, 1 }, drag = 3, mine = true })
	V.Ring(at, if golden then 10 else 6, col, 0.35, { mine = true })
	if golden then V.Burst(at, { tex = "gold_coin_sparkle", count = 8, color = Color3.fromRGB(255, 220, 120), size = 1.4, speed = { 6, 12 }, life = { 0.6, 1 }, drag = 2, rot = 120, mine = true }) end
end
-- #285: a new body arrives (a ring flash where it lands; the streak is its Trail: V.StreakTrail)
function V.BodyArrive(at: Vector3, colour: Color3, k: number?)
	V.Ring(at, 5 * (k or 1), colour, 0.45)
	V.Sparkles(at, math.floor(14 * (k or 1)), colour:Lerp(WHITE, 0.5), 0.6 * (k or 1))
end
-- a light_streak Trail on a moving part (a body flying in, a comet, a shard): returns the Trail
function V.StreakTrail(part: BasePart, colour: Color3, width: number?, life: number?, tex: string?): Trail
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	local w = width or 1
	a0.Position, a1.Position = Vector3.new(0, w / 2, 0), Vector3.new(0, -w / 2, 0)
	a0.Parent, a1.Parent = part, part
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Texture = T.alpha[tex or "light_streak"]
	tr.TextureMode = Enum.TextureMode.Stretch
	tr.LightEmission, tr.LightInfluence = 1, 0
	tr.Lifetime = life or 0.35
	tr.FaceCamera = true
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Color = ColorSequence.new(colour:Lerp(WHITE, 0.5), colour)
	tr.Parent = part
	return tr
end
-- #286: a body type's x2 tier (every 10 levels): a gold ring + small rays
function V.Milestone(at: Vector3, radius: number)
	local gold = Color3.fromRGB(255, 205, 90)
	V.Ring(at, radius, gold, 0.6)
	V.Pop(at, "rays_burst", radius * 0.8, gold, 0.6, { rot = 40 })
end
-- #284: a tree node bought (on its board): a glow, a line up and 8-12 sparkles
function V.NodeBought(at: Vector3, colour: Color3?)
	local col = colour or Color3.fromRGB(190, 140, 255)
	V.Pop(at, "glow_dot", 4, col, 0.45, { mine = true })
	V.Burst(at, { tex = "light_streak", count = 3, color = col:Lerp(WHITE, 0.4), size = 3, speed = { 14, 20 }, spread = 15, life = { 0.3, 0.45 }, orient = "vel", mine = true })
	V.Sparkles(at, 10, col:Lerp(WHITE, 0.5), 0.5, { mine = true })
end
-- #291: a Lost Star twinkles / is found
function V.LostStar(at: Vector3, found: boolean?)
	local col = Color3.fromRGB(220, 230, 255)
	if found then
		V.Pop(at, "starburst_twinkle", 6, col, 0.5, { mine = true, rot = 60 })
		V.Sparkles(at, 14, col, 0.6, { mine = true })
	else
		V.Burst(at, { tex = "sparkle_star", count = 2, color = col, size = 0.8, speed = { 0.2, 0.6 }, life = { 0.8, 1.2 }, rot = 40 })
	end
end
-- #288: Star Surge full: a gold wave across the plaza + the Core's rays
function V.StarSurge(core: Vector3)
	local gold = Color3.fromRGB(255, 205, 90)
	V.Pop(core, "core_light_rays", 30, gold, 1.6, { rot = 20, mine = true })
	V.Ring(core - Vector3.new(0, 6, 0), 90, gold, 1.4, { tex = "star_surge_wave", flat = true, mine = true })
	V.Sparkles(core, 30, gold, 1.2, { mine = true, speed = { 10, 24 } })
end
-- #305/#306: the Core's beat (a ring + a glow) and its standing rays: V.CoreRays returns a stream handle
function V.CorePulse(core: Vector3, colour: Color3)
	V.Ring(core, 22, colour, 0.8, { mine = true })
	V.Pop(core, "glow_dot", 16, colour, 0.6, { mine = true })
end
function V.CoreRays(core: Vector3, colour: Color3)
	return V.Stream(core, 0.6, { tex = "core_light_rays", color = colour, size = 26, speed = { 0.01, 0.01 }, spread = 0, life = { 5, 5 }, rot = 6,
		sizeSeq = seq(20, 28, 22), transp = seq(1, 0.55, 1), z = -4 })
end
-- a REWARD claim (offline / daily / a quest / a gift) in the world over your head (#claims): coins + confetti + small rays
function V.Claim(at: Vector3)
	local gold = Color3.fromRGB(255, 210, 110)
	V.Pop(at, "rays_burst", 8, gold, 0.6, { mine = true, rot = 50 })
	V.Burst(at, { tex = "gold_coin_sparkle", count = 10, color = WHITE, size = 1.2, speed = { 8, 14 }, life = { 0.7, 1.1 }, drag = 2, rot = 140,
		accel = Vector3.new(0, -14, 0), mine = true })
	V.Burst(at, { tex = "confetti_burst", flip = "once", count = 1, color = WHITE, size = 9, speed = { 0.01, 0.01 }, spread = 0, life = { 1, 1 },
		rotation = { 0, 0 }, transp = seq(0, 0, 0.4), mine = true })
end

------------------------------------------------------------------------ (a) SUPERNOVA (#266-#268, #294-#298)
-- the wind-up on YOUR island (`dur` s): stardust pulled into the star from all round + electric arcs crackling round it,
-- faster at the end. Returns a handle: h:Stop() (the impact calls it)
function V.SupernovaWindup(star: Vector3, colour: Color3, dur: number)
	local motes = V.Stream(star, 26, { tex = "stardust_mote", color = colour:Lerp(WHITE, 0.4), size = 1, speed = { 9, 13 }, life = { 1.2, 1.5 },
		shape = { size = Vector3.new(36, 36, 36), kind = "Sphere", inward = true, surface = true }, transp = seq(1, 0, 0.2) })
	local arcs = V.Stream(star, 3, { tex = "electric_arc", flip = "loop", fps = 22, color = colour:Lerp(WHITE, 0.5), size = 6, speed = { 0.01, 0.01 },
		life = { 0.3, 0.5 }, shape = { size = Vector3.new(7, 7, 7), kind = "Sphere", surface = true }, rotation = { 0, 360 } })
	local h = {}
	local stopped = false
	function h:Stop()
		if stopped then return end
		stopped = true
		motes:Stop()
		arcs:Stop()
	end
	-- (the last third: more arcs, faster)
	task.delay(dur * 0.66, function()
		if stopped then return end
		arcs.em.Rate = if phone() then 4 else 8
		motes.em.Rate = if phone() then 20 else 40
	end)
	task.delay(dur + 1.5, function() h:Stop() end)
	return h
end
-- the IMPACT + the fade. at = the star's spot over the island; colour = the rank's (#298); grow = 1 .. 1.8 with Supernovas;
-- mine = your own (always drawn; shake + flash)
function V.Supernova(at: Vector3, colour: Color3, grow: number, mine: boolean?)
	local hot = colour:Lerp(WHITE, 0.5)
	-- IMPACT (frame 0): the flash flipbook, the starburst, the rays; your screen flashes + shakes
	V.Burst(at, { tex = "supernova_flash", flip = "once", count = 1, color = WHITE, size = 30 * grow, speed = { 0.01, 0.01 }, spread = 0,
		life = { 0.9, 0.9 }, rotation = { 0, 0 }, sizeSeq = seq(20 * grow, 27 * grow, 30 * grow), transp = seq(0, 0.1, 0.4), mine = mine, z = 2 })
	V.Pop(at, "starburst_twinkle", 26 * grow, hot, 0.35, { mine = mine, z = 3 })
	V.Pop(at, "rays_burst", 34 * grow, colour, 0.9, { mine = mine, rot = 30, transp = seq(0.15, 0.35, 1) })
	if mine then
		V.Flash(hot, 0.55, 0.35)
		V.Shake(0.35, 0.45)
	end
	-- the fast layer: two rings across the floor (a beat apart), shards ripping out, the explosion
	V.Ring(at, 70 * grow, colour, 0.75, { flat = true, mine = mine })
	V.Ring(at, 50 * grow, hot, 0.6, { flat = true, mine = mine, delay = 0.25 })
	V.Ring(at, 34 * grow, colour, 0.5, { mine = mine })
	V.Burst(at, { tex = "crystal_shard", count = math.floor(30 * grow), color = hot, size = 1.8 * grow, speed = { 45, 85 }, life = { 0.7, 1.2 },
		drag = 1.5, orient = "vel", mine = mine })
	V.Burst(at, { tex = "explosion_burst", flip = "once", count = 3, color = colour:Lerp(WHITE, 0.2), size = 16 * grow, speed = { 2, 6 },
		life = { 1, 1 }, sizeSeq = seq(10 * grow, 18 * grow, 22 * grow), transp = seq(0, 0, 0.5), mine = mine })
	V.Sparkles(at, math.floor(40 * grow), hot, 1.4 * grow, { mine = mine, speed = { 14, 30 } })
	-- the slow layer: embers drifting up for seconds, the nebula blooming in, violet smoke (fast + slow together, #295)
	V.Burst(at, { tex = "glow_dot", count = 34, color = colour, size = 0.9, speed = { 2, 7 }, life = { 3.5, 6 }, drag = 0.4,
		accel = Vector3.new(0, 1.2, 0), mine = mine })
	V.Burst(at, { tex = "nebula_wisp", count = 4, color = colour:Lerp(Color3.fromRGB(190, 110, 255), 0.4), size = 30 * grow, speed = { 0.5, 2 },
		life = { 3.5, 4.5 }, rot = 8, sizeSeq = seq(10 * grow, 30 * grow, 36 * grow), transp = seq(1, 0.45, 1), mine = mine, delay = 0.15 })
	V.Burst(at, { tex = "smoke_puff", alpha = true, flip = "once", fps = 5, count = 5, color = colour:Lerp(Color3.fromRGB(60, 30, 90), 0.5),
		size = 14 * grow, speed = { 1, 4 }, life = { 3, 3.2 }, transp = seq(0.35, 0.6, 1), mine = mine, delay = 0.1 })
end

------------------------------------------------------------------------ (b) THE STAR FORGE / ANVIL (#275, #289, #301, #318)
-- 1. STRIKE (every roll): the anvil glows hot, the hammer hit (the anvil_impact flipbook), sparks shoot up, molten drops,
-- a puff of smoke. at = the anvil's top face
function V.ForgeStrike(at: Vector3, mine: boolean?)
	local hot = Color3.fromRGB(255, 160, 60)
	V.Pop(at, "forge_glow", 9, WHITE, 0.7, { mine = mine })
	V.Pop(at, "glow_dot", 6, hot, 0.5, { mine = mine })
	V.Pop(at + Vector3.new(0, 0.6, 0), "hammer_impact_star", 6, WHITE, 0.22, { mine = mine, z = 2 })
	V.Burst(at + Vector3.new(0, 1.5, 0), { tex = "anvil_impact", flip = "once", fps = 22, count = 1, color = WHITE, size = 9, speed = { 0.01, 0.01 }, spread = 0,
		life = { 0.72, 0.72 }, rotation = { 0, 0 }, sizeSeq = seq(9), transp = seq(0, 0, 0.2), mine = mine, z = 1 })
	V.Burst(at, { tex = "forge_sparks", flip = "loop", fps = 20, count = 3, color = WHITE, size = 4, speed = { 6, 12 }, spread = 25, life = { 0.6, 0.9 },
		accel = Vector3.new(0, -10, 0), mine = mine })
	V.Burst(at, { tex = "molten_droplet", count = 10, color = WHITE, size = 0.7, speed = { 10, 20 }, spread = 60, life = { 0.6, 1 }, orient = "vel",
		accel = Vector3.new(0, -40, 0), mine = mine })
	V.Burst(at, { tex = "smoke_puff", alpha = true, flip = "once", fps = 14, count = 2, color = Color3.fromRGB(120, 110, 120), size = 5, speed = { 1, 3 },
		life = { 1.15, 1.15 }, transp = seq(0.3, 0.5, 1), mine = mine, delay = 0.08 })
end
-- 2. BUILD-UP (Rare and up, the whole cutscene): the rune circle turns on the anvil, electric arcs round it, stardust pulled
-- in; faster as it goes. Returns a handle: h:Stop()
function V.ForgeBuild(at: Vector3, colour: Color3, len: number)
	local rune = V.Stream(at + Vector3.new(0, 0.3, 0), 0.0001, { tex = "rune_circle", color = colour:Lerp(WHITE, 0.3), size = 14, speed = { 0.01, 0.01 },
		spread = 0, life = { len + 0.4, len + 0.4 }, orient = "flat", rot = 0, rotation = { 0, 0 },
		sizeSeq = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(0.1, 12), NumberSequenceKeypoint.new(0.9, 15), NumberSequenceKeypoint.new(1, 22) }),
		transp = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.08, 0.1), NumberSequenceKeypoint.new(0.92, 0), NumberSequenceKeypoint.new(1, 1) }) })
	rune.em.RotSpeed = NumberRange.new(70, 70)
	rune:Emit(1)
	local arcs = V.Stream(at + Vector3.new(0, 2, 0), 2.5, { tex = "electric_arc", flip = "loop", fps = 20, color = colour:Lerp(WHITE, 0.5), size = 4,
		speed = { 0.01, 0.01 }, life = { 0.3, 0.5 }, shape = { size = Vector3.new(7, 4, 7), kind = "Sphere", surface = true } })
	local motes = V.Stream(at + Vector3.new(0, 2, 0), 18, { tex = "stardust_mote", color = colour:Lerp(WHITE, 0.4), size = 0.8, speed = { 7, 10 },
		life = { 1, 1.3 }, shape = { size = Vector3.new(24, 16, 24), kind = "Sphere", inward = true, surface = true }, transp = seq(1, 0, 0.2) })
	local stopped = false
	task.delay(len * 0.6, function()
		if stopped then return end
		arcs.em.Rate = if phone() then 3 else 6
		motes.em.Rate = if phone() then 16 else 32
	end)
	local h = {}
	function h:Stop()
		if stopped then return end
		stopped = true
		rune:Stop()
		arcs:Stop()
		motes:Stop()
	end
	return h
end
-- the aura flare of a rarity (index 2..7; aura_uncommon .. aura_mythic; Celestial = the mythic ring, rainbow)
local AURA = { [1] = "aura_common", [2] = "aura_uncommon", [3] = "aura_rare", [4] = "aura_epic", [5] = "aura_legendary", [6] = "aura_mythic", [7] = "aura_mythic" }
V.AuraTex = AURA
-- a beam of light up into the sky (forge_beam / island_beam / quasar_beam: tall images, `h` studs high)
function V.SkyBeam(base: Vector3, tex: string, h: number, colour: Color3 | ColorSequence, t: number, o)
	o = o or {}
	V.Burst(base + Vector3.new(0, h * 0.42, 0), { tex = tex, count = 1, color = colour, speed = { 0.01, 0.01 }, spread = 0, life = { t, t }, orient = "up",
		rotation = { 0, 0 }, sizeSeq = NumberSequence.new({ NumberSequenceKeypoint.new(0, h * 0.5), NumberSequenceKeypoint.new(0.15, h), NumberSequenceKeypoint.new(1, h) }),
		transp = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.15, o.base or 0), NumberSequenceKeypoint.new(0.7, math.min(1, (o.base or 0) + 0.1)), NumberSequenceKeypoint.new(1, 1) }),
		mine = o.mine, delay = o.delay, brightness = o.brightness })
end
-- a falling star from the sky onto `at` (the Celestial reveal): a comet head with its tail; calls back on landing
function V.FallingStar(at: Vector3, colour: Color3, t: number, onLand: (() -> ())?)
	local from = at + Vector3.new(-60, 120, -40)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(from)
	p.Parent = folder
	local tr = V.StreakTrail(p, colour, 3, 0.45, "comet_tail")
	tr.WidthScale = NumberSequence.new(1, 0.1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(8, 8)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = T.alpha.comet_head
	img.ImageColor3 = colour:Lerp(WHITE, 0.4)
	img.Parent = bb
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = math.min((os.clock() - t0) / t, 1)
		p.CFrame = CFrame.new(from:Lerp(at, k * k))
		img.Rotation = math.deg(math.atan2(at.Y - from.Y, at.X - from.X))
		if k >= 1 then
			conn:Disconnect()
			img.Visible = false
			if onLand then onLand() end
			task.delay(0.5, function() p:Destroy() end)
		end
	end)
end
-- 3. THE REVEAL by rarity (1 Common .. 7 Celestial) at the anvil; colour = the rarity's. Every step adds layers (#278)
function V.ForgeReveal(at: Vector3, i: number, colour: Color3, mine: boolean?, anvil: Instance?, noFlash: boolean?)
	local hot = colour:Lerp(WHITE, 0.45)
	local o = { mine = mine }
	-- Common: a small sparkle pop
	V.Sparkles(at + Vector3.new(0, 1, 0), 10 + i * 4, hot, 0.6 + i * 0.08, o)
	if i >= 2 then
		-- Uncommon +: the rarity's aura flares round the anvil
		-- (the aura's ring is low in its image: lifted so the ring sits on the anvil top, the flames above it)
		V.Pop(at + Vector3.new(0, (10 + i) * 0.3, 0), AURA[i], 9 + i, if i == 7 then V.RAINBOW else WHITE, 1.1, { mine = mine, sizeSeq = seq(7 + i, 10 + i, 11 + i), transp = seq(0, 0.1, 1) })
	end
	if i >= 3 then V.Ring(at + Vector3.new(0, 0.3, 0), 14 + i, colour, 0.55, { flat = true, mine = mine }) end
	if i >= 4 then
		V.Pop(at + Vector3.new(0, 2, 0), "rays_burst", 11 + i * 1.5, colour, 0.9, { mine = mine, rot = 40, transp = seq(0.3, 0.45, 1) })
		V.Burst(at + Vector3.new(0, 2, 0), { tex = "crystal_shard", count = 14 + i * 2, color = hot, size = 1.2, speed = { 20, 40 }, life = { 0.6, 1 },
			drag = 1.5, orient = "vel", mine = mine })
	end
	if i >= 5 then
		V.SkyBeam(at, "forge_beam", 44, if i == 7 then V.RAINBOW else colour, 2.2, { mine = mine, base = 0.35 })
		V.Burst(at + Vector3.new(0, 6, 0), { tex = "confetti_burst", flip = "once", fps = 16, count = 2, color = WHITE, size = 14, speed = { 0.5, 2 },
			spread = 60, life = { 1, 1 }, rotation = { -15, 15 }, transp = seq(0, 0, 0.3), mine = mine })
		V.Pop(at + Vector3.new(0, 3, 0), "starburst_twinkle", 12, hot, 0.4, { mine = mine, z = 2 })
		if anvil then V.Highlight(anvil, colour, 1.6) end
	end
	if i >= 6 then
		V.Ring(at + Vector3.new(0, 0.3, 0), 26, colour, 0.8, { flat = true, mine = mine, delay = 0.2 })
		if mine and not noFlash then V.Flash(hot, 0.5, 0.3) end
	end
	if i >= 7 then
		V.Burst(at + Vector3.new(0, 3, 0), { tex = "supernova_flash", flip = "once", count = 1, color = WHITE, size = 28, speed = { 0.01, 0.01 }, spread = 0,
			life = { 0.9, 0.9 }, rotation = { 0, 0 }, sizeSeq = seq(20, 30, 34), transp = seq(0, 0, 0.3), mine = mine, z = 3 })
		V.Pop(at + Vector3.new(0, 3, 0), "rays_burst", 26, V.RAINBOW, 1.6, { mine = mine, rot = 30, transp = seq(0.25, 0.4, 1) })
	end
end
-- the Celestial's SKY TURN: the sky tints violet for `t` s, then back (a Lighting tween; the old values are restored)
function V.SkyTurn(t: number)
	if calm() then return end
	-- (7 Nov: back to the lighting's own values (GalaxyLighting.Base), not the ones when this started)
	local base = require(game:GetService("ReplicatedStorage"):WaitForChild("Galaxy"):WaitForChild("GalaxyLighting")).Base()
	local old = { Ambient = base.Ambient, OutdoorAmbient = base.OutdoorAmbient, ColorShift_Top = base.ColorShift_Top }
	tween(Lighting, { Ambient = Color3.fromRGB(120, 70, 190), OutdoorAmbient = Color3.fromRGB(140, 90, 210), ColorShift_Top = Color3.fromRGB(200, 120, 255) }, 0.8, Enum.EasingStyle.Sine)
	task.delay(t, function() tween(Lighting, old, 1.2, Enum.EasingStyle.Sine) end)
end

------------------------------------------------------------------------ (c) THE ISLAND: a piece / pad builds, a tier up (#310)
-- a pad / piece builds: the pad_build_ring flashes out on the floor, a dust ring + puffs, sparkles rising
-- (build_sparkle_trail), confetti on the bigger ones. at = the pad's floor centre; size = its width
function V.PadBuild(at: Vector3, size: number, colour: Color3?, mine: boolean?)
	local col = colour or Color3.fromRGB(120, 200, 255)
	local s = math.clamp(size, 4, 30)
	V.Ring(at + Vector3.new(0, 0.3, 0), s * 1.6, WHITE, 0.6, { tex = "pad_build_ring", flat = true, mine = mine, rot = 90 })
	V.Pop(at + Vector3.new(0, s * 0.15, 0), "ground_dust_ring", s * 1.4, Color3.fromRGB(220, 215, 230), 0.8,
		{ alpha = true, mine = mine, orient = "up", sizeSeq = seq(s * 0.6, s * 1.4, s * 1.8), transp = seq(0.1, 0.4, 1) })
	V.Burst(at + Vector3.new(0, 0.5, 0), { tex = "smoke_puff", alpha = true, flip = "once", fps = 16, count = 3, color = Color3.fromRGB(200, 195, 210),
		size = s * 0.4, speed = { 3, 6 }, spread = 70, life = { 1, 1 }, transp = seq(0.25, 0.5, 1), mine = mine })
	V.Burst(at + Vector3.new(0, 0.5, 0), { tex = "build_sparkle_trail", count = 8, color = col:Lerp(WHITE, 0.4), size = 3, speed = { 10, 18 }, spread = 35,
		life = { 0.6, 0.9 }, orient = "vel", drag = 1, mine = mine })
	V.Sparkles(at + Vector3.new(0, s * 0.3, 0), math.floor(10 + s), Color3.fromRGB(255, 230, 160), 0.7, { mine = mine })
	if s >= 10 then
		V.Burst(at + Vector3.new(0, s * 0.4, 0), { tex = "confetti_burst", flip = "once", fps = 16, count = 1, color = WHITE, size = s * 0.9,
			speed = { 0.01, 0.01 }, spread = 0, life = { 1, 1 }, rotation = { 0, 0 }, transp = seq(0, 0, 0.3), mine = mine })
	end
end
-- an ISLAND TIER-UP: a rune circle opens under the island, a beam of light up, rays + the crown burst, confetti, a ring
-- across the floor. centre = the island's floor centre
function V.IslandTierUp(centre: Vector3, colour: Color3?, mine: boolean?)
	local col = colour or Color3.fromRGB(255, 205, 90)
	local o = { mine = mine }
	V.Burst(centre + Vector3.new(0, 0.4, 0), { tex = "rune_circle", count = 1, color = col:Lerp(WHITE, 0.3), speed = { 0.01, 0.01 }, spread = 0, life = { 2, 2 },
		orient = "flat", rot = 0, rotation = { 0, 0 }, mine = mine,
		sizeSeq = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(0.2, 40), NumberSequenceKeypoint.new(1, 46) }),
		transp = seq(0.2, 0, 1) })
	V.SkyBeam(centre, "island_beam", 80, col, 1.6, { mine = mine, delay = 0.15 })
	V.Pop(centre + Vector3.new(0, 14, 0), "tierup_crown_burst", 24, WHITE, 1, { mine = mine, delay = 0.2, sizeSeq = seq(14, 24, 26), transp = seq(0, 0, 1) })
	V.Pop(centre + Vector3.new(0, 14, 0), "rays_burst", 40, col, 1, { mine = mine, delay = 0.2, rot = 30 })
	V.Ring(centre + Vector3.new(0, 0.5, 0), 60, col, 0.8, { flat = true, mine = mine, delay = 0.2 })
	V.Burst(centre + Vector3.new(0, 18, 0), { tex = "confetti_burst", flip = "once", fps = 16, count = 3, color = WHITE, size = 16, speed = { 1, 4 },
		spread = 70, life = { 1, 1 }, rotation = { -20, 20 }, transp = seq(0, 0, 0.3), mine = mine, delay = 0.25 })
	V.Sparkles(centre + Vector3.new(0, 10, 0), 30, col:Lerp(WHITE, 0.4), 1.2, { mine = mine, speed = { 10, 22 }, delay = 0.2 })
	if mine then V.Flash(col:Lerp(WHITE, 0.6), 0.3, 0.3) end
	return o
end

------------------------------------------------------------------------ (d) IGNITION: the gate opens, the sector lights up
-- at = the gate's centre (in the arch), facing = the gate's look vector (the portal stands across it)
function V.IgnitionGate(at: Vector3, facing: Vector3, colour: Color3?, mine: boolean?)
	local col = colour or Color3.fromRGB(150, 200, 255)
	-- wind-up: the portal swirl spins up in the arch (3 s), the impact = rays + the ring + the flash, then it fades
	local cf = CFrame.lookAt(at, at + facing)
	local swirl = V.Stream(cf, 2, { tex = "portal_swirl", flip = "loop", fps = 20, color = col:Lerp(WHITE, 0.3), size = 16, speed = { 0.01, 0.01 },
		spread = 0, life = { 1.2, 1.2 }, sizeSeq = seq(6, 16, 18), transp = seq(1, 0.1, 1), rot = 60 })
	swirl:Emit(1)
	V.Burst(at, { tex = "stardust_mote", count = 40, color = col, size = 0.9, speed = { 8, 12 }, life = { 1.2, 1.5 },
		shape = { size = Vector3.new(30, 30, 30), kind = "Sphere", inward = true, surface = true }, transp = seq(1, 0, 0.2), mine = mine })
	task.delay(1.4, function()
		swirl:Stop()
		V.Pop(at, "rays_burst", 40, col, 1.1, { mine = mine, rot = 35, count = 2 })
		V.Pop(at, "starburst_twinkle", 24, col:Lerp(WHITE, 0.5), 0.4, { mine = mine, z = 2 })
		V.Ring(at - Vector3.new(0, 6, 0), 70, col, 0.9, { flat = true, mine = mine })
		V.Burst(cf, { tex = "portal_swirl", flip = "loop", fps = 24, count = 1, color = col:Lerp(WHITE, 0.4), size = 18, speed = { 0.01, 0.01 }, spread = 0,
			life = { 2.2, 2.2 }, rot = 90, sizeSeq = seq(18, 20, 4), transp = seq(0, 0.2, 1), mine = mine })
		V.Sparkles(at, 30, col:Lerp(WHITE, 0.5), 1.1, { mine = mine, speed = { 12, 26 } })
		if mine then V.Flash(col:Lerp(WHITE, 0.6), 0.45, 0.35) end
	end)
end
-- a bridge / Ring Nebula segment lighting up (#302): the bridge_segment glow + sparkles
function V.BridgeSegment(at: Vector3, colour: Color3, len: number)
	V.Pop(at, "bridge_segment", len, colour, 0.6, { orient = "up" })
	V.Sparkles(at, 8, colour:Lerp(WHITE, 0.4), 0.5)
end

------------------------------------------------------------------------ Phase 3 modules (built now, #299 #300 #302)
-- BLACK HOLE (#299, the "woah"): the swirl turning flat in the air, a dark pulse, stardust pulled in, violet smoke + the
-- portal. Returns a handle (h:Stop()); h:Pulse() = one dark pulse (an absorb)
function V.BlackHole(at: Vector3, scale: number?)
	local s = scale or 1
	local violet = Color3.fromRGB(150, 90, 255)
	local swirl = V.Stream(at, 0.5, { tex = "black_hole_swirl", color = WHITE, size = 22 * s, speed = { 0.01, 0.01 }, spread = 0, life = { 6, 6 }, rot = 0,
		rotation = { 0, 360 }, sizeSeq = seq(18 * s, 22 * s, 18 * s), transp = seq(1, 0.05, 1) })
	swirl.em.RotSpeed = NumberRange.new(-50, -50)
	swirl:Emit(2)
	local portal = V.Stream(at, 1, { tex = "portal_swirl", flip = "loop", fps = 18, color = violet, size = 14 * s, speed = { 0.01, 0.01 }, spread = 0,
		life = { 3, 3 }, rot = 0, sizeSeq = seq(12 * s, 15 * s, 12 * s), transp = seq(1, 0.3, 1), z = 1 })
	portal.em.RotSpeed = NumberRange.new(-80, -80)
	portal:Emit(1)
	local motes = V.Stream(at, 20, { tex = "stardust_mote", color = Color3.fromRGB(210, 180, 255), size = 0.9 * s, speed = { 10 * s, 14 * s },
		life = { 1.4, 1.8 }, shape = { size = Vector3.new(50, 30, 50) * s, kind = "Sphere", inward = true, surface = true }, transp = seq(1, 0, 0.3) })
	local smoke = V.Stream(at, 1.2, { tex = "smoke_puff", alpha = true, flip = "loop", fps = 8, color = Color3.fromRGB(70, 30, 110), size = 12 * s,
		speed = { 1, 3 }, life = { 3, 4 }, transp = seq(1, 0.55, 1), rot = 20 })
	local h = {}
	function h:Pulse()
		V.Pop(at, "dark_pulse", 30 * s, WHITE, 0.9, { sizeSeq = seq(10 * s, 30 * s, 38 * s), transp = seq(0, 0.2, 1) })
	end
	function h:Stop()
		swirl:Stop() portal:Stop() motes:Stop() smoke:Stop()
	end
	h:Pulse()
	return h
end
-- QUASAR (#300): two beams out of the poles (up + down), electric arcs round the core, a glow. Returns a handle
function V.Quasar(at: Vector3, scale: number?, colour: Color3?)
	local s = scale or 1
	local col = colour or Color3.fromRGB(140, 200, 255)
	local function beam(dy: number)
		-- (1.2 a second at 2.4 s each: always 2-3 overlapping, so the beam never blinks out)
		local h = V.Stream(at + Vector3.new(0, dy * 26 * s, 0), 1.2, { tex = "quasar_beam", color = col, size = 52 * s, speed = { 0.01, 0.01 }, spread = 0,
			life = { 2.4, 2.4 }, orient = "up", rotation = { 0, 0 }, sizeSeq = seq(50 * s, 54 * s, 50 * s), transp = seq(1, 0.05, 1) })
		h:Emit(1)
		return h
	end
	local up, down = beam(1), beam(-1)
	local glow = V.Stream(at, 2, { tex = "glow_dot", color = col, size = 12 * s, speed = { 0.01, 0.01 }, spread = 0, life = { 1.5, 1.5 }, transp = seq(1, 0.2, 1) })
	glow:Emit(1)
	local arcs = V.Stream(at, 4, { tex = "electric_arc", flip = "loop", fps = 22, color = col:Lerp(WHITE, 0.5), size = 6 * s, speed = { 0.01, 0.01 },
		life = { 0.3, 0.5 }, shape = { size = Vector3.new(8, 8, 8) * s, kind = "Sphere", surface = true } })
	local h = {}
	function h:Stop() up:Stop() down:Stop() glow:Stop() arcs:Stop() end
	return h
end
-- RING NEBULA (#302): a bridge of light from a to b (a Beam with the bridge_segment texture scrolling, light streaks
-- along it, sparkles at both ends). Returns a handle
function V.RingNebula(a: Vector3, b: Vector3, colour: Color3?)
	local col = colour or Color3.fromRGB(255, 150, 220)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(a)
	p.Parent = folder
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = p, p -- (parented first: WorldPosition is relative to the part)
	a0.WorldPosition = a
	a1.WorldPosition = b
	local function beam(tex: string, w: number, tr: number, speed: number)
		local bm = Instance.new("Beam")
		bm.Attachment0, bm.Attachment1 = a0, a1
		bm.Texture = T.alpha[tex]
		-- (stretched along the whole bridge: tiled, the panel image's padding left gaps)
		bm.TextureMode = Enum.TextureMode.Stretch
		bm.TextureLength = 1
		bm.TextureSpeed = speed
		bm.LightEmission, bm.LightInfluence = 1, 0
		bm.FaceCamera = true
		bm.Width0, bm.Width1 = w, w
		bm.Color = ColorSequence.new(col:Lerp(WHITE, 0.3), col)
		bm.Transparency = NumberSequence.new(tr)
		bm.Parent = p
		return bm
	end
	beam("bridge_segment", 9, 0.05, 0)
	beam("light_streak", 1.6, 0, 2)
	local d = (b - a)
	local streaks = V.Stream(CFrame.lookAt(a, b) * CFrame.Angles(-math.pi / 2, 0, 0), 4, { tex = "light_streak", color = col:Lerp(WHITE, 0.5), size = 3,
		speed = { d.Magnitude / 1.2, d.Magnitude / 1 }, spread = 0, life = { 1, 1.2 }, orient = "vel" })
	V.Sparkles(a, 16, col, 0.8)
	V.Sparkles(b, 16, col, 0.8, { delay = 0.5 })
	local h = {}
	function h:Stop()
		streaks:Stop()
		for _, bm in ipairs(p:GetChildren()) do
			if bm:IsA("Beam") then tween(bm, { Width0 = 0, Width1 = 0 }, 0.6) end
		end
		task.delay(0.7, function() p:Destroy() end)
	end
	return h
end

------------------------------------------------------------------------ SCREEN effects (the Forge card, the claims)
-- a 4x4 flipbook played on an ImageLabel (the _alpha file), once over `t` s (or looped while `loop`); returns the label
function V.UiFlip(parent: Instance, tex: string, centre: UDim2, size: number, t: number, colour: Color3?, z: number?, loop: boolean?)
	local img = Instance.new("ImageLabel")
	img.Name = "VfxFlip"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = centre
	img.Size = UDim2.fromOffset(size, size)
	img.Image = T.alpha[tex]
	img.ImageColor3 = colour or WHITE
	img.ImageRectSize = Vector2.new(256, 256)
	img.ZIndex = z or 1
	img.Parent = parent
	task.spawn(function()
		local t0 = os.clock()
		while img.Parent do
			local k = (os.clock() - t0) / t
			if k >= 1 and not loop then break end
			local f = math.floor((k % 1) * 16)
			img.ImageRectOffset = Vector2.new((f % 4) * 256, (f // 4) * 256)
			task.wait()
		end
		img:Destroy()
	end)
	return img
end
-- a still texture on screen that pops and fades (rays turning, a starburst, a coin)
function V.UiPop(parent: Instance, tex: string, centre: UDim2, size: number, t: number, colour: Color3?, z: number?, spin: number?)
	local img = Instance.new("ImageLabel")
	img.Name = "VfxPop"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = centre
	img.Size = UDim2.fromOffset(size * 0.4, size * 0.4)
	img.Image = T.alpha[tex]
	img.ImageColor3 = colour or WHITE
	img.ZIndex = z or 1
	img.Parent = parent
	tween(img, { Size = UDim2.fromOffset(size, size) }, 0.18, Enum.EasingStyle.Back)
	tween(img, { Rotation = spin or 0 }, t, Enum.EasingStyle.Sine)
	task.delay(t * 0.45, function() if img.Parent then tween(img, { ImageTransparency = 1 }, t * 0.55) end end)
	task.delay(t + 0.05, function() img:Destroy() end)
	return img
end
-- the Forge card's reveal on screen, by rarity (the same ladder as the anvil): the hit, the aura, rays, confetti
function V.UiForgeReveal(parent: Instance, i: number, colour: Color3, centre: UDim2, z: number)
	V.UiFlip(parent, "anvil_impact", centre, 220, 0.7, WHITE, z)
	if calm() then return end
	if i >= 2 then V.UiPop(parent, AURA[i], centre, 190 + i * 10, 1.1, if i == 7 then Color3.fromRGB(255, 200, 255) else WHITE, z - 1) end
	if i >= 3 then V.UiPop(parent, "shockwave_ring", centre, 280, 0.6, colour, z) end
	if i >= 4 then V.UiPop(parent, "rays_burst", centre, 320, 2.2, colour, z - 2, 90) end
	if i >= 5 then
		V.UiFlip(parent, "confetti_burst", centre, 420, 1.1, WHITE, z + 2)
		V.UiPop(parent, "starburst_twinkle", centre, 200, 0.45, colour:Lerp(WHITE, 0.4), z + 1)
	end
	if i >= 7 then V.UiFlip(parent, "supernova_flash", centre, 360, 0.9, WHITE, z + 1) end
end
-- a claim on screen (offline / daily / a quest / a gift): coins, small rays, confetti round `centre`
function V.UiClaim(parent: Instance, centre: UDim2, z: number)
	if calm() then return end
	V.UiPop(parent, "rays_burst", centre, 200, 0.8, Color3.fromRGB(255, 210, 110), z - 1, 60)
	V.UiFlip(parent, "confetti_burst", centre, 260, 1, WHITE, z + 1)
	for k = 1, 5 do
		local img = V.UiPop(parent, "gold_coin_sparkle", centre, 34, 0.9, WHITE, z + 1, math.random(-90, 90))
		local a = (k / 5) * math.pi * 2
		tween(img, { Position = UDim2.new(centre.X.Scale, centre.X.Offset + math.cos(a) * 90, centre.Y.Scale, centre.Y.Offset + math.sin(a) * 60) }, 0.6)
	end
end
-- the claim burst centred on a button (any ScreenGui): drawn on the VFX screen, over everything
function V.UiClaimAt(obj: GuiObject)
	local g = obj:FindFirstAncestorWhichIsA("ScreenGui")
	local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
	if g and not g.IgnoreGuiInset then pos += GuiService:GetGuiInset() end
	V.UiClaim(screenGui(), UDim2.fromOffset(pos.X, pos.Y), 30)
end

return V
