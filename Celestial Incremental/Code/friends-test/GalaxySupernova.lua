-- GalaxySupernova (Galaxy Incremental, alpha part 1, 3 Nov): YOUR Supernova, client side. Design sections 1 + 5, VFX plan
-- (SUPERNOVA row, the WOAH rules: contrast, layers, fast + slow, a wind-up you can feel, a mark that stays).
--  * the big gold SUPERNOVA button (right side, a glow pulsing behind it) while you're ready; the INFO board / tree window's
--    SUPERNOVA button opens the same card (shared.GalaxyOpenSupernova). Never pops up by itself.
--  * the confirm card (v12 window): YOU GET n SHARDS, KEEP / RESET, what waiting gives ("earn 2x first: m shards, +x%"),
--    GO SUPERNOVA / NOT YET
--  * the cinematic (MapConfig.Supernova; ~5 s the first time, ~2 s after, SKIP after the first): the world dims, the camera
--    looks up at your system, its bodies spiral into your star while it swells and pulses faster (GalaxyMapClient's wind-up);
--    impact = the server's Supernova (EconRequest "Supernova"): one white flash + an FOV punch (none with Reduced Motion), the
--    Core burst + 2 shockwave rings for the whole server (MapEvent, GalaxyMapClient), the "SUPERNOVA!" stamp with its rays,
--    the shards fly into the SHARDS counter, your rank lands over your head (GalaxyRankTags), a nebula patch stays in your
--    sky. Star Surge +5% (GalaxyStarSurgeService) comes with the count.
-- Alpha part 2 (3 Nov): the SOUND on the same beats (Galaxy.Sounds): the wind-up riser, the boom at the impact, a
-- crystal blip per shard landing (climbing in pitch); the MUSIC cuts at the wind-up (fades to silence in 0.3 s) and comes
-- back after the stamp.
-- Studio test switch: Workspace TestSlowMo = n -> the cinematic runs n times slower (for screenshots).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local A = Kit.A
local hex = Kit.hex
local fmt = Econ.Format
local SN = MapConfig.Supernova
local CENTRE = Enum.TextXAlignment.Center
local GOLD1, GOLD2 = hex("#ffe27a"), hex("#e08a0a")

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxySupernova"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- (Studio phone check: the same 667x375 frame as GalaxyHUD)
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local root: GuiObject | ScreenGui = gui
if PHONE_TEST then
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	f.Parent = gui
	root = f
end
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end
local function scaled(name: string, anchor: Vector2, w: number, h: number)
	local f = Kit.box(root, 0, 0, w, h, { Name = name, AnchorPoint = anchor })
	local s = Instance.new("UIScale")
	s.Parent = f
	return f, s
end

------------------------------------------------------------------------ the SUPERNOVA button (right side, while ready)
local btnRoot, btnScale = scaled("SupernovaButton", Vector2.new(1, 0.5), 260, 120)
btnRoot.Visible = false
local glow = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.softglow, ImageColor3 = Color3.fromRGB(255, 190, 60), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(130, 60), Size = UDim2.fromOffset(330, 190), ImageTransparency = 0.25, ZIndex = 1 }, btnRoot)
local button, inner = Kit.button(btnRoot, 20, 24, 220, 72, GOLD1, GOLD2, { ZIndex = 3 })
Kit.text(inner, 0, 6, 220, 36, "SUPERNOVA!", 32, { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2.4 })
Kit.icon(inner, "shard", 52, 40, 26, nil, { ZIndex = inner.ZIndex })
local btnShards = Kit.text(inner, 80, 42, 120, 22, "", 18, { ZIndex = inner.ZIndex, stroke = 1.6 })
Kit.tagVfx(Kit.shine(button, 2))
for _, s in ipairs({ { 8, 14, 0 }, { 226, 20, 0.6 }, { 216, 90, 1.2 }, { 14, 86, 0.9 } }) do Kit.sparkle(btnRoot, s[1], s[2], 16, s[3]) end
shared.GalaxySupernovaButton = button
if not Kit.calm() then
	Kit.tween(glow, { ImageTransparency = 0, Size = UDim2.fromOffset(380, 230) }, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
end

------------------------------------------------------------------------ the confirm card (v12 window style, like the Upgrades one)
local cardRoot, cardScale = scaled("SupernovaCard", Vector2.new(0.5, 0.5), 620, 430)
cardRoot.Visible = false
cardRoot.ZIndex = 5 -- (above the dim behind it)
local dim = Kit.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	Visible = false, ZIndex = 1 }, root)
local card = {}
do
	local win = cardRoot
	local edge = Kit.box(win, -4, -4, 628, 438, { ZIndex = 1 })
	Kit.corner(edge, 14)
	local st = Kit.stroke(edge, Color3.new(1, 1, 1), 6)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, hex("#ff9a1a")), ColorSequenceKeypoint.new(0.5, hex("#fff1b0")), ColorSequenceKeypoint.new(1, hex("#ff9a1a")) })
	g.Parent = st
	card.edge = g
	local frame = Kit.box(win, 0, 0, 620, 430, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 2 })
	Kit.corner(frame, 10)
	local body = Kit.box(win, 3, 3, 614, 424, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.corner(body, 8)
	Kit.grad(body, hex("#1d1626"), hex("#0f0d13"), 90)
	Kit.stroke(body, hex("#ffb02a"), 1.5, 0.45)
	local header = Kit.box(win, 3, 3, 614, 56, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, ClipsDescendants = true })
	Kit.corner(header, 8)
	Kit.grad(header, hex("#7a3a06"), hex("#e08a0a"), 0)
	Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.9, Size = UDim2.fromOffset(512, 128), ZIndex = 4 }, header)
	Kit.box(win, 3, 40, 614, 20, { BackgroundTransparency = 0, BackgroundColor3 = hex("#b86a08"), ZIndex = 4 })
	Kit.box(win, 9, 4, 602, 2, { BackgroundTransparency = 0.4, BackgroundColor3 = hex("#fff1b0"), ZIndex = 5 })
	local sweep = Kit.shine(header, 4.5, 0.16, 0.3)
	sweep.ZIndex = 5
	Kit.box(win, 3, 59, 614, 2, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 5 })
	Kit.icon(win, "sun", -24, -28, 92, Color3.fromRGB(255, 190, 70), { ZIndex = 9 })
	Kit.text(win, 80, 13, 360, 34, "SUPERNOVA", 30, { ZIndex = 8, stroke = 1.8, FontFace = Kit.FONT_HEAVY })
	-- YOU GET
	Kit.text(win, 0, 72, 620, 22, "YOU GET", 18, { ZIndex = 8, TextXAlignment = CENTRE, TextColor3 = hex("#cfc6dd") })
	Kit.icon(win, "shard", 170, 92, 70, Color3.fromRGB(170, 110, 255), { ZIndex = 8 })
	card.got = Kit.text(win, 246, 98, 260, 60, "0 SHARDS", 48, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2.6,
		gradient = ColorSequence.new(hex("#f3eaff"), hex("#b49bff")) })
	-- KEEP / RESET
	local function column(x: number, title: string, colour: Color3, lines)
		local box = Kit.box(win, x, 168, 280, 150, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 4 })
		Kit.corner(box, 6)
		Kit.stroke(box, colour, 2, 0.2)
		Kit.text(win, x + 14, 176, 252, 24, title, 20, { ZIndex = 8, TextColor3 = colour, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
		for i, l in ipairs(lines) do
			Kit.text(win, x + 16, 204 + (i - 1) * 27, 252, 22, l, 15, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0"), stroke = 1.2 })
		end
	end
	column(20, "KEEP", hex("#7dff6b"), { "Shards + ring 2 of the tree", "Supernova count + your rank", "Essence + the tutorial", "Your island's pieces" })
	column(320, "RESET", hex("#ff7a6b"), { "Stardust", "Bodies (the asteroid stays)", "Ring 1 of the tree", "Your star system: back to a rock" })
	-- what waiting gives
	card.wait = Kit.text(win, 20, 324, 580, 26, "", 18, { ZIndex = 8, TextXAlignment = CENTRE, TextColor3 = hex("#ffd84a"), stroke = 1.3 })
	-- GO / NOT YET
	local go, goInner = Kit.button(win, 330, 356, 270, 60, GOLD1, GOLD2, { ZIndex = 6 })
	Kit.text(goInner, 0, 12, 270, 36, "GO SUPERNOVA", 28, { ZIndex = goInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
	Kit.tagVfx(Kit.shine(go, 2.4))
	local no, noInner = Kit.button(win, 20, 356, 270, 60, hex("#6a6474"), hex("#3f3a48"), { ZIndex = 6 })
	Kit.text(noInner, 0, 12, 270, 36, "NOT YET", 28, { ZIndex = noInner.ZIndex, TextXAlignment = CENTRE, TextColor3 = hex("#e8e2f0"), FontFace = Kit.FONT_HEAVY, stroke = 2 })
	card.go, card.no = go, no
	shared.GalaxySupernovaGo = go
end

local busy = false
local function cardText()
	local earned = player:GetAttribute("EarnedRun") or 0
	local nodes = {}
	for _, n in ipairs(Econ.Ring1) do nodes[n.id] = player:GetAttribute("Node_" .. n.id) == true end
	local novas = player:GetAttribute("Supernovas") or 0
	local got = Econ.ShardsFor(earned, nodes, novas)
	local later = Econ.ShardsFor(earned * 2, nodes, novas)
	Kit.setText(card.got, got .. " SHARDS")
	Kit.setText(card.wait, "Wait to earn 2x first: " .. later .. " shards (+" .. math.floor((later / math.max(got, 1) - 1) * 100 + 0.5) .. "%)")
	return got
end
local function closeCard()
	if not cardRoot.Visible then return end
	Kit.tween(cardScale, { Scale = cardScale.Scale * 0.85 }, 0.12)
	Kit.tween(dim, { BackgroundTransparency = 1 }, 0.12)
	task.delay(0.12, function()
		cardRoot.Visible = false
		dim.Visible = false
	end)
end
local function openCard()
	if busy or not player:GetAttribute("SupernovaReady") then return end
	cardText()
	local s = screenScale()
	local vp = viewport()
	cardRoot.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
	local want = math.min(Kit.ps(s, 0.85), (vp.Y - 20) / 440, (vp.X - 20) / 630) -- (phones: as big as fits, for 12 px text)
	cardScale.Scale = want * 0.8
	cardRoot.Visible = true
	dim.Visible = true
	dim.BackgroundTransparency = 1
	Kit.tween(dim, { BackgroundTransparency = 0.45 }, 0.2)
	Kit.tween(cardScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
	Kit.sound("open")
end
shared.GalaxyOpenSupernova = openCard
button.MouseButton1Click:Connect(openCard)
card.no.MouseButton1Click:Connect(function()
	Kit.sound("close")
	closeCard()
end)
dim.MouseButton1Click:Connect(closeCard)

------------------------------------------------------------------------ the cinematic
-- (only shown during the cinematic: a screen-sized frame would take the taps meant for the HUD and the boards)
local fx = Kit.box(root, 0, 0, 0, 0, { Name = "SupernovaFx", Size = UDim2.fromScale(1, 1), ZIndex = 80, Visible = false })
local flash = Kit.box(fx, 0, 0, 0, 0, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 90 })
local skipRoot, skipScale = scaled("SupernovaSkip", Vector2.new(1, 1), 150, 60)
skipRoot.Visible = false
local skip, skipInner = Kit.button(skipRoot, 10, 6, 130, 46, hex("#6a6474"), hex("#3f3a48"), { ZIndex = 95 })
Kit.text(skipInner, 0, 9, 130, 28, "SKIP", 24, { ZIndex = skipInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local skipping = false
local showSkipToken = nil
skip.MouseButton1Click:Connect(function() skipping = true end)

-- the "SUPERNOVA!" stamp: hand-drawn feel (a slanted, outlined word on a burst of sharp gold rays), slammed in and held
local function stamp(quick: boolean)
	local s = screenScale()
	local vp = viewport()
	local f = Kit.box(fx, 0, 0, 700, 260, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(vp.X / 2, vp.Y * 0.42), ZIndex = 91 })
	local sc = Instance.new("UIScale")
	sc.Parent = f
	local rays = Kit.box(f, 350, 130, 0, 0, { ZIndex = 91 })
	for i = 0, 15 do
		local long = if i % 2 == 0 then 330 else 230
		local r = Kit.box(rays, -long / 2, -9, long, 18, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Rotation = i * 22.5 + (i % 3) * 3, ZIndex = 91 })
		Kit.grad(r, hex("#ffd36a"), hex("#ff8a1a"), 0)
		Kit.corner(r, 9)
		r.BackgroundTransparency = 0.15
	end
	local main = Kit.text(f, 0, 72, 700, 120, "SUPERNOVA!", 104, { ZIndex = 93, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 7,
		gradient = ColorSequence.new(hex("#fffbe6"), hex("#ffc23a")) })
	for _, l in ipairs(main.Parent:GetChildren()) do
		if l:IsA("TextLabel") then l.Rotation = -7 end
	end
	for i = 1, 8 do Kit.sparkle(f, math.random(60, 640), math.random(20, 230), math.random(18, 30), i * 0.05) end
	local want = s * 0.95
	if Kit.calm() then
		sc.Scale = want
	else
		sc.Scale = want * 2.4
		Kit.tween(sc, { Scale = want }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Kit.tween(rays, { Rotation = 25 }, 2.6, Enum.EasingStyle.Sine)
	end
	local slow = if RunService:IsStudio() then tonumber(workspace:GetAttribute("TestSlowMo")) or 1 else 1
	task.delay((if quick then 1 else 1.8) * slow, function()
		Kit.tween(sc, { Scale = want * 0.85 }, 0.3)
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("TextLabel") then Kit.tween(d, { TextTransparency = 1 }, 0.3) end
			if d:IsA("UIStroke") then Kit.tween(d, { Transparency = 1 }, 0.3) end
			if d:IsA("Frame") and d.BackgroundTransparency < 1 then Kit.tween(d, { BackgroundTransparency = 1 }, 0.3) end
		end
		task.wait(0.35)
		f:Destroy()
	end)
end

-- the shards fly from the middle of the screen into the SHARDS counter (one icon per shard, 12 at most)
local function flyShards(n: number, slow: number)
	local target = shared.GalaxyShardsTarget and shared.GalaxyShardsTarget()
	if not target then return end
	local vp = viewport()
	local from = Vector2.new(vp.X / 2, vp.Y * 0.45)
	if PHONE_TEST then target -= (workspace.CurrentCamera.ViewportSize - vp) / 2 end
	local s = screenScale()
	for i = 1, math.min(n, 12) do
		task.delay(i * 0.06 * slow, function()
			local img = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.icon.shard, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(44 * s, 44 * s),
				Position = UDim2.fromOffset(from.X + math.random(-140, 140) * s, from.Y + math.random(-60, 60) * s), Rotation = math.random(-30, 30), ZIndex = 94 }, fx)
			Kit.tween(img, { Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(26 * s, 26 * s), Rotation = 0 }, 0.55 * slow, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.55 * slow, function()
				img:Destroy()
				Kit.sound("shardIn", { pitch = 1 + (i - 1) * 0.05 })
				if shared.GalaxyShardsPop then shared.GalaxyShardsPop() end
			end)
		end)
	end
end

-- the camera looks up at your system from your island (and goes back to you after)
local function myIsland(): Model?
	local root = workspace:FindFirstChild("Galaxy")
	local islands = root and root:FindFirstChild("Islands")
	if not islands then return nil end
	for _, i in ipairs(islands:GetChildren()) do
		if i:GetAttribute("Owner") == player.UserId then return i end
	end
	return nil
end

local function cinematic()
	if busy then return end
	busy = true
	shared.GalaxyCinematic = true
	closeCard()
	btnRoot.Visible = false
	local first = (player:GetAttribute("Supernovas") or 0) == 0
	local T = table.clone(if first then SN.First else SN.Again)
	local slow = if RunService:IsStudio() then tonumber(workspace:GetAttribute("TestSlowMo")) or 1 else 1
	for k, v in pairs(T) do T[k] = v * slow end
	fx.Visible = true
	skipping = false
	-- SKIP after ~1 s, the first time too (#317): nothing you get needs the cinematic to finish
	skipRoot.Visible = false
	local skipToken = {}
	showSkipToken = skipToken
	task.delay(1 * slow, function()
		if showSkipToken == skipToken and busy then skipRoot.Visible = true end
	end)
	local cam = workspace.CurrentCamera
	local oldType, oldFov, oldCf = cam.CameraType, cam.FieldOfView, cam.CFrame
	local oldExposure = Lighting.ExposureCompensation
	local island = myIsland()
	local c = island and island:GetAttribute("Center")
	if c then
		-- (from the island's bridge side, low, looking up at the system and the boards behind it)
		local a = island:GetAttribute("Angle") or 0
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local top = c + Vector3.new(0, MapConfig.System.Height, 0)
		local from = cam.CFrame
		local to = CFrame.lookAt(c - dir * 26 + Vector3.new(0, 10, 0) + Vector3.new(-dir.Z, 0, dir.X) * 6, top - Vector3.new(0, 4, 0))
		local t0 = os.clock()
		cam.CameraType = Enum.CameraType.Scriptable
		RunService:BindToRenderStep("GalaxySupernovaCam", Enum.RenderPriority.Camera.Value + 1, function()
			local k = math.clamp((os.clock() - t0) / (0.6 * slow), 0, 1)
			k = 1 - (1 - k) ^ 3
			cam.CFrame = from:Lerp(to, k)
			-- (Camera.Focus every frame, #316: shadows and detail load around what the camera looks at)
			cam.Focus = CFrame.new(top)
		end)
	end
	-- WIND-UP: the music cuts, the world dims, the bodies pull into the star, it swells and pulses faster (the riser:
	-- the whole file the first time; only its last part when the wind-up is short, so its peak lands on the impact)
	Kit.musicFade(0, 0.3)
	local riser = Kit.sound("windup")
	if riser and not first then
		local len = if riser.TimeLength > 0 then riser.TimeLength else 3
		riser.TimePosition = math.max(0, len - (T.Windup + T.Hold) * riser.PlaybackSpeed)
	end
	if shared.GalaxyWindup then shared.GalaxyWindup(T.Windup) end
	if not Kit.calm() then
		game:GetService("TweenService"):Create(Lighting, TweenInfo.new(T.Windup, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ExposureCompensation = oldExposure - 0.7 }):Play()
	end
	local t0 = os.clock()
	while os.clock() - t0 < T.Windup + T.Hold and not skipping do task.wait() end
	-- IMPACT: the server's Supernova
	local ok, got = request:InvokeServer("Supernova")
	Lighting.ExposureCompensation = oldExposure
	if riser then riser:Stop() end
	if not ok then
		Kit.musicFade(1, 1)
		if shared.GalaxyWindupCancel then shared.GalaxyWindupCancel() end
		if c then RunService:UnbindFromRenderStep("GalaxySupernovaCam") end
		cam.CFrame = oldCf
		cam.CameraType = oldType
		skipRoot.Visible = false
		fx.Visible = false
		busy = false
		shared.GalaxyCinematic = false
		return
	end
	if not Kit.calm() and not skipping then
		flash.BackgroundTransparency = 0
		Kit.tween(flash, { BackgroundTransparency = 1 }, 0.45)
		cam.FieldOfView = oldFov + SN.FovPunch
		Kit.tween(cam, { FieldOfView = oldFov }, 0.6, Enum.EasingStyle.Quad)
	end
	Kit.sound("boom")
	if not skipping then stamp(not first) end
	-- the music comes back once the stamp has gone (it's held 1.8 s, 1 s after the first time)
	task.delay(if skipping then 0.3 else ((if first then 1.8 else 1) + 0.35) * slow, function() Kit.musicFade(1, 1.5) end)
	task.delay(if skipping then 0 else 0.5 * slow, function() flyShards(got, slow) end)
	task.delay(if skipping then 0.2 else 0.9 * slow, function() if shared.GalaxyRankLand then shared.GalaxyRankLand() end end)
	-- FADE: hold on the burst, then back to you
	local t1 = os.clock()
	while os.clock() - t1 < T.Fade and not skipping do task.wait() end
	if c then RunService:UnbindFromRenderStep("GalaxySupernovaCam") end
	-- (back to where your camera was, so the follow camera keeps its distance)
	cam.CFrame = oldCf
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = oldFov
	skipRoot.Visible = false
	busy = false
	shared.GalaxyCinematic = false
	-- (the stamp and the flying shards finish first, then the layer goes)
	task.delay(1.5 * slow, function() if not busy then fx.Visible = false end end)
end
card.go.MouseButton1Click:Connect(function()
	Kit.sound("click")
	cinematic()
end)

------------------------------------------------------------------------ layout + the button's live shard count
local function layout()
	local s = screenScale()
	local vp = viewport()
	btnScale.Scale = s
	skipScale.Scale = s
	btnRoot.Position = UDim2.fromOffset(vp.X - 8 * s, vp.Y * 0.5)
	skipRoot.Position = UDim2.fromOffset(vp.X - 12 * s, vp.Y - 120 * s)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()
local function onReady()
	btnRoot.Visible = player:GetAttribute("SupernovaReady") == true and not busy
	Kit.setText(btnShards, "+" .. fmt(player:GetAttribute("SupernovaShards") or 0) .. " SHARDS")
	if cardRoot.Visible then cardText() end
end
player:GetAttributeChangedSignal("SupernovaReady"):Connect(onReady)
player:GetAttributeChangedSignal("SupernovaShards"):Connect(onReady)
onReady()
RunService.Heartbeat:Connect(function(dt)
	if card.edge and cardRoot.Visible and not Kit.calm() then card.edge.Rotation = (card.edge.Rotation + dt * 60) % 360 end
end)
