-- GalaxyCutscene (Galaxy Incremental, 5 Nov; vault "Prompt - Cutscene template (Sols RNG style)"; checklist #266-#272,
-- #274, #275, #289, #294-#299, #301, #303, #316, #317): ONE reusable, client-only cutscene. Screen-space layers in front of the
-- camera (like Sol's RNG: clean, cheap on phones) + an optional world camera move, all in the moment's ONE colour.
--
-- Cutscene.play(cfg) -> (yields until done)
--   cfg.colour     Color3: every layer is tinted with it
--   cfg.symbol     image id (the big centre symbol; default the sun icon)
--   cfg.length     seconds (the whole thing)
--   cfg.drop       seconds from the start: the CLIMAX (white flash + starburst + boom + FOV punch, same frame); default 80%
--   cfg.words      { "WORD", ... }: one at a time on the build's beats; cfg.title: the climax title; cfg.sub: under it
--   cfg.mini       true = the 1.2 s version (no black frame, no world dim; for "NEW: <TIER>!")
--   cfg.lines      true = constellation lines draw across the screen (Ignition)
--   cfg.camera     function(k 0..1) -> (CFrame, focus Vector3) or nil: a world camera move (Camera.Focus every frame)
--   cfg.onClimax   function: the REWARD is given here, at the climax, never only at the end (#318)
--   cfg.skippable  true = SKIP after 1 s (default true); a skip jumps to the climax + tail
--   cfg.slow       a multiplier on every time (Studio frame-by-frame tests)
--   cfg.veil       how dark the backdrop gets (0-1): default 0.85 on screen-only moments, 0.45 with a world camera move
--   cfg.keepGuis   { ScreenGui names } that stay on (every other ScreenGui is hidden during a full cutscene, like Sol's)
--   cfg.audio      false = no riser / boom (the host plays its own, e.g. GalaxySupernova); Cutscene.skip() jumps to the climax
--   cfg.world      true = the moment is in the WORLD (cfg.camera shows it, e.g. the Forge's anvil): no centre symbol, rings
--                  or nebula on screen (they would cover it); the words, title, breath, flash and rays stay
-- BEATS (relative to `drop`): a. contrast opener (world dims, music out, near silence) -> b. build (symbol grows + turns,
-- rings speed up, glints, speed lines, words) -> c. held breath (0.3 s black frame, silence) -> d. CLIMAX on `drop` (flash,
-- starburst rays, boom, FOV punch + short shake; the riser is started so that its END lands exactly on `drop`) -> e. tail
-- (layers fade, the world is back, music returns). Reduced Motion: no flash, no shake, no punch. Max 1 white flash per cutscene.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local A = Kit.A
local VT = require(Galaxy:WaitForChild("VfxTextures")) -- (the VFX pass: our own ring + streak)

local Cutscene = {}
local player = Players.LocalPlayer
local gui -- the ScreenGui (made once)
local busy = false

local function ensureGui()
	if gui and gui.Parent then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "GalaxyCutscene"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end
local function image(parent, img: string, props)
	local l = Instance.new("ImageLabel")
	l.BackgroundTransparency = 1
	l.Image = img
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.ScaleType = Enum.ScaleType.Fit
	for k, v in pairs(props or {}) do l[k] = v end
	l.Parent = parent
	return l
end
local function frame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	for k, v in pairs(props or {}) do f[k] = v end
	f.Parent = parent
	return f
end

function Cutscene.busy(): boolean return busy end
local skipHook
function Cutscene.skip() if skipHook then skipHook() end end

function Cutscene.play(cfg)
	-- (a mini is dropped while another cutscene runs; a full one waits its turn, e.g. Ignition right after a NEW tier mini)
	if busy and cfg.mini then return end
	while busy do task.wait() end
	busy = true
	local slow = cfg.slow or 1
	local L = (cfg.length or 6) * slow
	local mini = cfg.mini == true
	local D = (cfg.drop or (cfg.length or 6) * 0.8) * slow
	local col: Color3 = cfg.colour or Color3.fromRGB(255, 200, 90)
	local calm = Kit.calm()
	local root = ensureGui()
	local layer = frame(root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 1 })
	local vp = workspace.CurrentCamera.ViewportSize
	local unit = math.min(vp.X, vp.Y) -- (layer sizes in screen units, so phones and PCs look the same)
	shared.GalaxyCinematic = true
	local skipping = false
	local veilMax = cfg.veil or (if cfg.camera then 0.45 else 0.85)
	-- (a full cutscene owns the screen: the HUD and windows hide, and come back after)
	local hidden = {}
	if not mini then
		local keep = {}
		for _, n in ipairs(cfg.keepGuis or {}) do keep[n] = true end
		for _, g in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
			if g:IsA("ScreenGui") and g ~= root and g.Enabled and not keep[g.Name] then
				g.Enabled = false
				table.insert(hidden, g)
			end
		end
	end

	-- a. the background: the moment's hue as a nebula (soft glows) over a dark veil
	local veil = frame(layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 2, 10), BackgroundTransparency = 1, ZIndex = 1 })
	local nebulae = {}
	if not mini then
		for i = 1, 4 do
			local n = image(layer, A.softglow, { ImageColor3 = col:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.1), ImageTransparency = 1, ZIndex = 2,
				Size = UDim2.fromOffset(unit * (0.9 + i * 0.25), unit * (0.6 + i * 0.2)), Position = UDim2.fromScale(0.5 + (i % 2 - 0.5) * 0.12, 0.5 + (i % 3 - 1) * 0.06),
				Rotation = i * 37 })
			table.insert(nebulae, n)
		end
	end
	-- b. the SYMBOL + 3 thin rings orbiting it + star glints + speed lines
	local symbol = image(layer, cfg.symbol or A.icon.sun, { Size = UDim2.fromOffset(unit * 0.12, unit * 0.12), ImageTransparency = 1, ZIndex = 6 })
	local rings = {}
	for i = 1, (if mini then 1 else 3) do
		table.insert(rings, image(layer, VT.alpha.shockwave_ring, { Size = UDim2.fromOffset(unit * (0.25 + i * 0.12), unit * (0.25 + i * 0.12) * (0.35 + i * 0.12)),
			ImageColor3 = col:Lerp(Color3.new(1, 1, 1), 0.4), ImageTransparency = 1, ZIndex = 5, Rotation = i * 30 }))
	end
	local glints = {}
	for i = 1, (if mini then 4 else 12) do
		table.insert(glints, image(layer, A.sparkle, { Size = UDim2.fromOffset(unit * 0.03, unit * 0.03), ImageColor3 = col:Lerp(Color3.new(1, 1, 1), 0.6),
			ImageTransparency = 1, ZIndex = 7, Position = UDim2.fromScale(math.random(), math.random()) }))
	end
	local speed = {}
	if not mini then
		for i = 1, 14 do
			local a = math.rad(i * (360 / 14) + math.random(-8, 8))
			table.insert(speed, { img = image(layer, VT.alpha.light_streak, { Size = UDim2.fromOffset(unit * 0.35, unit * 0.012), ImageColor3 = col:Lerp(Color3.new(1, 1, 1), 0.5),
				ImageTransparency = 1, ZIndex = 4, Rotation = math.deg(a), ScaleType = Enum.ScaleType.Stretch }), a = a })
		end
	end
	-- the constellation lines (Ignition): 7 star points, lines draw between them one by one
	local stars, links = {}, {}
	if cfg.lines and not mini then
		for i = 1, 7 do
			local p = Vector2.new(vp.X * (0.15 + 0.7 * (i - 1) / 6), vp.Y * (0.3 + 0.35 * math.abs(math.sin(i * 1.7))))
			table.insert(stars, { p = p, img = image(layer, A.sparkle, { Size = UDim2.fromOffset(unit * 0.035, unit * 0.035), Position = UDim2.fromOffset(p.X, p.Y),
				ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 1, ZIndex = 8 }) })
		end
		for i = 1, #stars - 1 do
			local a, b = stars[i].p, stars[i + 1].p
			local d = b - a
			table.insert(links, { a = a, d = d, f = frame(layer, { BackgroundColor3 = col:Lerp(Color3.new(1, 1, 1), 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(0, 3), Position = UDim2.fromOffset(a.X, a.Y), Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = 7, BackgroundTransparency = 0.1 }) })
		end
	end
	if cfg.world then
		symbol.Visible = false
		for _, r in ipairs(rings) do r.Visible = false end
		for _, n in ipairs(nebulae) do n.Visible = false end
	end
	-- the words (build), the title + sub (climax)
	local wordsHolder = frame(layer, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 9 })
	local function bigText(str: string, y: number, size: number, grad: boolean)
		local main, _, holder = Kit.text(wordsHolder, 0, 0, vp.X, size * 1.3, str, size, { ZIndex = 10, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY,
			stroke = math.max(2, size / 18), gradient = if grad then ColorSequence.new(Color3.new(1, 1, 1), col:Lerp(Color3.new(1, 1, 1), 0.3)) else nil })
		holder.Position = UDim2.fromOffset(0, vp.Y * y - size * 0.65)
		holder.Visible = false
		return main, holder
	end
	local scale = math.clamp(unit / 720, 0.55, 1.3)
	local wordLabels = {}
	for i, w in ipairs(cfg.words or {}) do
		local _, h = bigText(w, 0.72, math.floor(34 * scale), false)
		wordLabels[i] = h
	end
	local _, titleH = bigText(cfg.title or "", 0.36, math.floor((if mini then 46 else 70) * scale), true)
	local _, subH = bigText(cfg.sub or "", 0.36 + 0.11, math.floor(26 * scale), false)
	-- c./d. the black breath, the white flash, the starburst rays
	local black = frame(layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 20 })
	local flash = frame(layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 21 })
	local rays = {}
	for i = 1, (if mini then 8 else 16) do
		table.insert(rays, image(layer, VT.alpha.light_streak, { Size = UDim2.fromOffset(0, unit * 0.03), ImageColor3 = col:Lerp(Color3.new(1, 1, 1), 0.65),
			ImageTransparency = 1, ZIndex = 8, Rotation = i * (360 / (if mini then 8 else 16)), ScaleType = Enum.ScaleType.Stretch }))
	end
	-- the SKIP (after 1 s)
	local skipRoot = frame(layer, { Size = UDim2.fromOffset(150, 60), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -110), BackgroundTransparency = 1, ZIndex = 30, Visible = false })
	local skipBtn, skipInner = Kit.button(skipRoot, 10, 6, 130, 46, Kit.hex("#6a6474"), Kit.hex("#3f3a48"), { ZIndex = 31 })
	Kit.text(skipInner, 0, 9, 130, 28, "SKIP", 24, { ZIndex = skipInner.ZIndex, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 2 })
	skipBtn.MouseButton1Click:Connect(function() skipping = true end)
	skipHook = function() skipping = true end
	if cfg.skippable ~= false and not mini then task.delay(1 * slow, function() if busy then skipRoot.Visible = true end end) end

	-- the world camera (optional) + the world dim + the music
	local cam = workspace.CurrentCamera
	local oldType, oldCf, oldFov = cam.CameraType, cam.CFrame, cam.FieldOfView
	local oldExposure = Lighting.ExposureCompensation
	if cfg.camera then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	if not mini then
		Kit.musicFade(0, 0.4 * slow)
		if not calm then Kit.tween(Lighting, { ExposureCompensation = oldExposure - 0.6 }, math.min(1, D * 0.2)) end
	end
	-- the riser: started so that its END lands exactly on the drop (its own length, measured in Studio: Sounds.windup)
	local riser
	if not mini and cfg.audio ~= false then
		riser = Kit.sound("windup")
		if riser then
			local len = if riser.TimeLength > 0 then riser.TimeLength else 3
			local want = D - 0.3 * slow -- (it ends at the breath; the boom is the drop)
			if want < len then riser.TimePosition = len - want end
			if want > len then riser:Stop() task.delay(want - len, function() if busy and not skipping then riser.TimePosition = 0 riser:Play() end end) end
		end
	end

	local t0 = os.clock()
	local climaxed, wordI = false, 0
	local B = 0.3 * slow -- (the held breath)
	local function climax()
		if climaxed then return end
		climaxed = true
		if riser then riser:Stop() end
		if cfg.audio ~= false then Kit.sound(if mini then "milestone" else "boom") end
		if cfg.onClimax then task.spawn(cfg.onClimax) end
		black.BackgroundTransparency = 1
		if not calm then
			flash.BackgroundTransparency = if mini then 0.5 else 0
			Kit.tween(flash, { BackgroundTransparency = 1 }, 0.5 * slow)
			cam.FieldOfView = oldFov + (if mini then 3 else 8)
			Kit.tween(cam, { FieldOfView = oldFov }, 0.6 * slow)
		end
		titleH.Visible = (cfg.title or "") ~= ""
		subH.Visible = (cfg.sub or "") ~= ""
		for _, w in ipairs(wordLabels) do w.Visible = false end
		for _, r in ipairs(rays) do
			r.ImageTransparency = 0.1
			r.Size = UDim2.fromOffset(unit * 0.1, unit * 0.03)
			Kit.tween(r, { Size = UDim2.fromOffset(unit * 1.4, unit * 0.015), ImageTransparency = 1 }, 0.9 * slow)
		end
		Kit.tween(symbol, { Size = UDim2.fromOffset(unit * 0.55, unit * 0.55), ImageTransparency = 0.6 }, 0.5 * slow)
		if not calm and not mini then
			local s0 = os.clock()
			RunService:BindToRenderStep("GalaxyCutsceneShake", Enum.RenderPriority.Camera.Value + 4, function()
				local t = os.clock() - s0
				if t > 0.35 then RunService:UnbindFromRenderStep("GalaxyCutsceneShake") return end
				cam.CFrame = cam.CFrame * CFrame.new(math.noise(t * 45, 3) * 0.3 * (1 - t / 0.35), math.noise(t * 45, 4) * 0.3 * (1 - t / 0.35), 0)
			end)
		end
	end
	RunService:BindToRenderStep("GalaxyCutscene", Enum.RenderPriority.Camera.Value + 2, function()
		local t = os.clock() - t0
		if skipping and not climaxed then
			t0 = os.clock() - D
			t = D
		end
		-- the world camera
		if cfg.camera then
			local cf, focus = cfg.camera(math.clamp(t / L, 0, 1))
			if cf then cam.CFrame = cf end
			cam.Focus = CFrame.new(focus or cam.CFrame.Position + cam.CFrame.LookVector * 20)
		end
		local A0 = if mini then 0 else math.min(1.2 * slow, D * 0.15) -- (the opener)
		if t < D then
			-- a. opener: the veil comes in; b. build: everything grows and brightens toward the drop
			local k = math.clamp((t - A0) / math.max(D - B - A0, 0.01), 0, 1)
			veil.BackgroundTransparency = if mini then 1 else 1 - veilMax * math.clamp(t / math.max(A0, 0.01), 0, 1)
			for i, n in ipairs(nebulae) do
				n.ImageTransparency = 1 - (0.25 + 0.45 * k)
				n.Rotation += 0.05 * i
			end
			symbol.ImageTransparency = 1 - math.clamp(k * 1.6, 0, 1)
			local sz = unit * (0.12 + 0.2 * k * k)
			symbol.Size = UDim2.fromOffset(sz, sz)
			symbol.Rotation = t / slow * (12 + 60 * k)
			for i, r in ipairs(rings) do
				r.ImageTransparency = 1 - 0.75 * math.clamp(k * 1.5, 0, 1)
				r.Rotation += (0.3 + 2.5 * k) * (if i % 2 == 0 then -1 else 1)
			end
			for i, g in ipairs(glints) do
				local ph = (t / slow * (1.2 + i * 0.13)) % 1
				g.ImageTransparency = if k > 0.05 then 0.2 + 0.8 * ph else 1
				local s = unit * 0.03 * (1 - ph)
				g.Size = UDim2.fromOffset(s, s)
			end
			for i, s in ipairs(speed) do
				local ph = (t / slow * (0.6 + 1.6 * k) + i * 0.137) % 1
				local r = unit * (0.15 + 0.6 * ph)
				s.img.Position = UDim2.fromOffset(vp.X / 2 + math.cos(s.a) * r, vp.Y / 2 + math.sin(s.a) * r)
				s.img.ImageTransparency = if k > 0.3 then 0.4 + 0.6 * ph else 1
			end
			-- the constellation lines draw one after another through the build
			for i, l in ipairs(links) do
				local p = math.clamp(k * #links - (i - 1), 0, 1)
				l.f.Size = UDim2.fromOffset(l.d.Magnitude * p, 3)
				local c = l.a + l.d * (p / 2)
				l.f.Position = UDim2.fromOffset(c.X, c.Y)
				stars[i].img.ImageTransparency = if p > 0 then 0 else 1
				if p >= 1 then stars[i + 1].img.ImageTransparency = 0 end
			end
			-- the words, one at a time on the build's beats
			if #wordLabels > 0 then
				local wi = math.clamp(math.floor(k * #wordLabels) + 1, 1, #wordLabels)
				if wi ~= wordI then
					wordI = wi
					for i, w in ipairs(wordLabels) do w.Visible = i == wi end
				end
			end
			-- c. the held breath: black + silence just before the drop (not in the mini version)
			if not mini and t >= D - B then
				black.BackgroundTransparency = if calm then 0.3 else 0
				if riser then riser.Volume = 0 end
			end
		else
			climax()
			-- e. the tail: the layers fade, the world comes back
			local k = math.clamp((t - D) / math.max(L - D, 0.01), 0, 1)
			veil.BackgroundTransparency = (1 - veilMax) + veilMax * k
			for _, n in ipairs(nebulae) do n.ImageTransparency = 0.3 + 0.7 * k end
			for _, r in ipairs(rings) do r.ImageTransparency = 0.25 + 0.75 * k end
			for _, s in ipairs(speed) do s.img.ImageTransparency = 1 end
			for _, g in ipairs(glints) do g.ImageTransparency = 0.3 + 0.7 * k end
			for _, st in ipairs(stars) do st.img.ImageTransparency = k end
			for _, l in ipairs(links) do l.f.BackgroundTransparency = 0.1 + 0.9 * k end
			if t >= L then
				RunService:UnbindFromRenderStep("GalaxyCutscene")
				busy = false
			end
		end
	end)
	while busy do task.wait() end
	-- restore: the camera, the lighting, the music, the HUD flag
	if cfg.camera then
		cam.CFrame = oldCf
		cam.CameraType = if oldType == Enum.CameraType.Scriptable then Enum.CameraType.Custom else oldType
	end
	cam.FieldOfView = oldFov
	if not mini then
		Lighting.ExposureCompensation = oldExposure
		Kit.musicFade(1, 1.5)
	end
	layer:Destroy()
	for _, g in ipairs(hidden) do if g.Parent then g.Enabled = true end end
	skipHook = nil
	if not cfg.keepCinematic then shared.GalaxyCinematic = false end
end

-- the images this template needs from the owner's artist (white on transparent, tinted in code): see the vault note
-- "Cutscene template - art list"
return Cutscene
