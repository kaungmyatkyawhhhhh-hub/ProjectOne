-- UIKit (Galaxy Incremental): the v12 UI pieces (Celestial Incremental\UI\galaxy_ui_v12_animated.html, owner-approved),
-- built the same way everywhere. Sizes are the v12 pixels (a 1280x720 screen); each screen part has a UIScale.
--  * textures never move (button stripes, header texture); VFX move ON TOP: shine sweeps, sparkles, motes, embers,
--    breathing window glow, pulsing icon glows, pulsing selected outline; icons themselves stay still
--  * no blur glow on buttons; can't-afford buttons have no VFX (calm = "not yet")
--  * Reduced Motion: the moving VFX stop (GuiService.ReducedMotionEnabled)
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local A = require(ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("UIAssets"))
local Kit = {}
Kit.A = A

local INK = Color3.fromRGB(8, 6, 12)
Kit.INK = INK
Kit.FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic)
Kit.FONT_HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
Kit.FONT_BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)

function Kit.calm(): boolean
	return GuiService.ReducedMotionEnabled
end
-- a phone-size screen (overnight part 5): the windows' small texts get their phone sizes so they read at >= 12 px
-- (Studio: the Workspace attribute TestPhone = the 667x375 phone frame)

-- size `desktop`, or `phone` on a phone-size screen
function Kit.ps(desktop: number, phone: number): number
	return if Kit.phone() then phone else desktop
end
function Kit.hex(h: string): Color3
	return Color3.fromHex(h)
end

local function new(class: string, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
Kit.new = new
-- DEVICES (7 Nov, live: "the phone HUD overlaps everywhere"). Studio only: Workspace TestDevice = "android" / "se" /
-- "pro14" / "ipad" / "pc" lays every HUD out inside that device's screen (logical px, landscape) in the middle of the
-- window: its safe area (the notch, the home bar), and a mock of Roblox's own top-left buttons (the topbar). A device
-- bigger than the window is drawn smaller (a UIScale); the layout still uses its real size. TestPhone = true = "se".
-- (topbar.left = where the free top row starts, from the device's left edge; safe = { left, right, bottom } insets)
Kit.Devices = {
	android = { size = Vector2.new(800, 360), topbar = { left = 200, height = 44 }, safe = { 0, 0, 0 } },
	se = { size = Vector2.new(667, 375), topbar = { left = 200, height = 44 }, safe = { 0, 0, 0 } },
	pro14 = { size = Vector2.new(852, 393), topbar = { left = 259, height = 44 }, safe = { 59, 59, 21 } },
	ipad = { size = Vector2.new(1180, 820), topbar = { left = 220, height = 58 }, safe = { 0, 0, 20 } },
	pc = { size = Vector2.new(1920, 1080), topbar = { left = 220, height = 58 }, safe = { 0, 0, 0 } },
}
function Kit.testDevice()
	if not game:GetService("RunService"):IsStudio() then return nil, nil end
	local d = workspace:GetAttribute("TestDevice")
	if type(d) == "string" and Kit.Devices[d] then return Kit.Devices[d], d end
	if workspace:GetAttribute("TestPhone") == true then return Kit.Devices.se, "se" end
	return nil, nil
end
-- the HUD's root in this ScreenGui: the gui itself (real devices: the safe area, Roblox puts it there with
-- DeviceSafeInsets), or in Studio the emulated device's safe area
function Kit.testRoot(gui: ScreenGui): GuiObject | ScreenGui
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	local dev = Kit.testDevice()
	if not dev then return gui end
	gui.ScreenInsets = Enum.ScreenInsets.None
	local outer = new("Frame", { Name = "TestDevice", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(dev.size.X, dev.size.Y), BackgroundTransparency = 1 }, gui)
	-- (drawn to fit the window; the camera has no size yet when the scripts start: refit when it does)
	local cam = workspace.CurrentCamera
	local us = new("UIScale", { Scale = 1 }, outer)
	local function refit()
		local vp = cam.ViewportSize
		if vp.X > 100 then us.Scale = math.min(1, (vp.X - 16) / dev.size.X, (vp.Y - 16) / dev.size.Y) end
	end
	refit()
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)
	if gui.Name == "GalaxyHUD" then
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, outer)
		-- (the notch / the home-bar strip, and Roblox's top-left buttons, drawn so the screenshots show them)
		if dev.safe[1] > 0 then new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, Size = UDim2.fromOffset(dev.safe[1], dev.size.Y), ZIndex = 99 }, outer) end
		local tb = new("Frame", { Name = "MockTopbar", BackgroundColor3 = Color3.fromRGB(20, 20, 24), BackgroundTransparency = 0.25,
			Position = UDim2.fromOffset(dev.safe[1] + 6, 4), Size = UDim2.fromOffset(dev.topbar.left - dev.safe[1] - 12, dev.topbar.height - 8), ZIndex = 99 }, outer)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, tb)
		new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "ROBLOX BUTTONS", TextColor3 = Color3.new(1, 1, 1),
			TextSize = 12, Font = Enum.Font.GothamBold, ZIndex = 99 }, tb)
	end
	local safe = new("Frame", { Name = "SafeArea", Position = UDim2.fromOffset(dev.safe[1], 0),
		Size = UDim2.fromOffset(dev.size.X - dev.safe[1] - dev.safe[2], dev.size.Y - dev.safe[3]), BackgroundTransparency = 1, ClipsDescendants = true }, outer)
	return safe
end
-- the room the HUD has (logical px): the emulated safe area, or the gui's (the safe area on a phone with a notch)
function Kit.viewport(root): Vector2
	local dev = Kit.testDevice()
	if dev then return Vector2.new(dev.size.X - dev.safe[1] - dev.safe[2], dev.size.Y - dev.safe[3]) end
	if root and root.AbsoluteSize.X > 10 then return root.AbsoluteSize end
	return workspace.CurrentCamera.ViewportSize
end
-- Roblox's top-left buttons, in the root's coordinates: { left = where the free top row starts, height = their row }
function Kit.topbar(root): { left: number, height: number }
	local dev = Kit.testDevice()
	if dev then return { left = dev.topbar.left - dev.safe[1], height = dev.topbar.height } end
	local r = GuiService.TopbarInset
	local ap = if root then root.AbsolutePosition else Vector2.zero
	return { left = math.max(0, r.Min.X - ap.X), height = math.max(0, r.Max.Y - ap.Y) }
end
-- (7 Nov, phone HUD) a BillboardGui sized in STUDS, so it shrinks with distance like the world (a pixel-sized one is the
-- same size on a 360-px phone as on a 1080-px PC: on phones they covered the screen). Its content is drawn at design pixels
-- (designW x designH) in the returned frame and scaled to the billboard's real size
function Kit.studsBillboard(bb: BillboardGui, designW: number, designH: number, studsW: number): Frame
	bb.Size = UDim2.fromScale(studsW, studsW * designH / designW)
	local inner = new("Frame", { Name = "Design", BackgroundTransparency = 1, Size = UDim2.fromOffset(designW, designH) }, bb)
	local us = new("UIScale", {}, inner)
	local function fit()
		if bb.AbsoluteSize.X > 0 then us.Scale = bb.AbsoluteSize.X / designW end
	end
	bb:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return inner
end
-- a touch screen with no keyboard (Studio: an emulated phone / iPad)
function Kit.touch(): boolean
	local _, name = Kit.testDevice()
	if name then return name ~= "pc" end
	local UIS = game:GetService("UserInputService")
	return UIS.TouchEnabled and not UIS.KeyboardEnabled
end
-- a phone: the short side under 500 logical px
function Kit.phone(): boolean
	local dev = Kit.testDevice()
	if dev then return math.min(dev.size.X, dev.size.Y - dev.safe[3]) < 500 end
	local cam = workspace.CurrentCamera
	return cam ~= nil and cam.ViewportSize.Y > 10 and math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
end

function Kit.tween(o, goal, t, style, dir, rep, rev, delay)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false, delay or 0), goal)
	tw:Play()
	return tw
end

-- a frame at v12 pixel coordinates
function Kit.box(parent, x, y, w, h, props)
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BorderSizePixel = 0, BackgroundTransparency = 1 }, parent)
	if props then for k, v in pairs(props) do f[k] = v end end
	return f
end
-- (7 Nov, owner: "UI corners: square layers poking out of rounded windows") THE one rounding helper: every visible layer
-- (fill / image) gets its own UICorner; a nested layer's radius = the outer radius - its inset (never bigger than its
-- parent's). One UICorner per object (an old one is reused). Kit.corner = Kit.Round (all the old calls go through it).
function Kit.Round(frame: GuiObject, radius: number): UICorner
	local c = frame:FindFirstChildOfClass("UICorner") or new("UICorner", {}, frame)
	c.CornerRadius = UDim.new(0, radius)
	-- (a stroke on a rounded layer follows its border)
	local st = frame:FindFirstChildOfClass("UIStroke")
	if st then st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border end
	return c
end
-- the inner radius for a layer inset `inset` px inside a parent rounded `outer` (rule: outer - inset, at least 2)
function Kit.InnerRadius(outer: number, inset: number): number
	return math.max(2, outer - inset)
end
function Kit.corner(parent, r)
	return Kit.Round(parent, r)
end
function Kit.stroke(parent, color, thick, transp)
	return new("UIStroke", { Color = color or INK, Thickness = thick or 2, Transparency = transp or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end
function Kit.grad(parent, c1: Color3, c2: Color3, rot: number?)
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90 }, parent)
end

-- text in the v12 ".t" style: white, thin ink stroke + a hard 2 px drop shadow below
function Kit.text(parent, x, y, w, h, str, size, props)
	local holder = Kit.box(parent, x, y, w, h, { ZIndex = (props and props.ZIndex) or 1 })
	local function label(dy, colour, stroke)
		local l = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, dy), Text = str,
			FontFace = Kit.FONT, TextSize = size, TextColor3 = colour, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}, holder)
		new("UIStroke", { Color = INK, Thickness = stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, l)
		return l
	end
	local shadow = label(2, Color3.new(0, 0, 0), (props and props.stroke) or 2)
	shadow.TextTransparency = 0
	local main = label(0, Color3.new(1, 1, 1), (props and props.stroke) or 2)
	if props then
		for k, v in pairs(props) do
			if k ~= "stroke" and k ~= "gradient" then
				main[k] = v
				if k ~= "TextColor3" then shadow[k] = v end
			end
		end
		if props.gradient then
			-- gradient-filled title (v12 row titles): the colours ride on white text
			main.TextColor3 = Color3.new(1, 1, 1)
			new("UIGradient", { Color = props.gradient, Rotation = 90 }, main)
		end
	end
	return main, shadow, holder
end
-- sets the text and its shadow
function Kit.setText(main, str)
	for _, l in ipairs(main.Parent:GetChildren()) do
		if l:IsA("TextLabel") then l.Text = str end
	end
end
function Kit.setColour(main, c: Color3)
	main.TextColor3 = c
end

------------------------------------------------------------------------ VFX (all loops stop when the object goes)
local function alive(o) return o.Parent ~= nil end

-- 4-point sparkle: scale 0.2 -> 1 -> 0.6 while turning 0 -> 90 deg, fading in and out (v12 'spark', 1.6 s)
function Kit.sparkle(parent, x, y, size, delay)
	size = size or 12
	local img = new("ImageLabel", { BackgroundTransparency = 1, Image = A.sparkle, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x + size / 2, y + size / 2), Size = UDim2.fromOffset(size, size), ImageTransparency = 1, ZIndex = 20 }, parent)
	img:SetAttribute("AllowOverlap", true) -- (decoration that breaks out on purpose: UIAudit leaves it out)
	local scale = new("UIScale", { Scale = 0.2 }, img)
	task.spawn(function()
		task.wait(delay or 0)
		while alive(img) do
			if Kit.calm() then img.ImageTransparency = 1 task.wait(1.6) continue end
			img.Rotation = 0
			scale.Scale = 0.2
			Kit.tween(img, { ImageTransparency = 0, Rotation = 45 }, 0.72, Enum.EasingStyle.Sine)
			Kit.tween(scale, { Scale = 1 }, 0.72, Enum.EasingStyle.Sine)
			task.wait(0.72)
			if not alive(img) then break end
			Kit.tween(img, { ImageTransparency = 1, Rotation = 90 }, 0.4, Enum.EasingStyle.Sine)
			Kit.tween(scale, { Scale = 0.6 }, 0.4, Enum.EasingStyle.Sine)
			task.wait(0.88)
		end
	end)
	return img
end

-- a white band sweeping across (v12 'shine': left -50% -> 120% in the first 40% of the cycle)
function Kit.shine(parent, period, width, strength)
	period = period or 2.4
	local band = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(width or 0.3, 0, 1.2, 0),
		Position = UDim2.new(-0.5, 0, -0.1, 0), Rotation = 0, ZIndex = 6 }, parent)
	new("UIGradient", { Rotation = 0, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 1 - (strength or 0.6)), NumberSequenceKeypoint.new(1, 1) }) }, band)
	task.spawn(function()
		task.wait(math.random() * period)
		while alive(band) do
			if Kit.calm() then band.Visible = false task.wait(period) continue end
			band.Visible = true
			band.Position = UDim2.new(-0.5, 0, -0.1, 0)
			Kit.tween(band, { Position = UDim2.new(1.2, 0, -0.1, 0) }, period * 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(period)
		end
	end)
	return band
end

-- motes rising inside a button (v12 'rise': 1.8 s, 34 px up)
function Kit.mote(parent, x, y, delay)
	local m = new("ImageLabel", { BackgroundTransparency = 1, Image = A.mote, Size = UDim2.fromOffset(9, 9), Position = UDim2.fromOffset(x - 2, y - 2),
		ImageTransparency = 1, ZIndex = 7 }, parent)
	task.spawn(function()
		task.wait(delay or 0)
		while alive(m) do
			if Kit.calm() then m.ImageTransparency = 1 task.wait(1.8) continue end
			m.Position = UDim2.fromOffset(x - 2, y - 2)
			m.ImageTransparency = 1
			Kit.tween(m, { ImageTransparency = 0 }, 0.36)
			Kit.tween(m, { Position = UDim2.fromOffset(x - 2, y - 36) }, 1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.wait(0.36)
			Kit.tween(m, { ImageTransparency = 1 }, 1.44)
			task.wait(1.44)
		end
	end)
	return m
end

-- embers drifting up from the header (v12 'ember': 3 s, +30 px right, -46 px up)
function Kit.ember(parent, x, y, delay)
	local e = new("Frame", { BackgroundColor3 = Kit.hex("#ffd08a"), BorderSizePixel = 0, Size = UDim2.fromOffset(4, 4), Position = UDim2.fromOffset(x, y),
		BackgroundTransparency = 1, ZIndex = 5 }, parent)
	Kit.corner(e, 2)
	task.spawn(function()
		task.wait(delay or 0)
		while alive(e) do
			if Kit.calm() then e.BackgroundTransparency = 1 task.wait(3) continue end
			e.Position = UDim2.fromOffset(x, y)
			e.BackgroundTransparency = 1
			Kit.tween(e, { BackgroundTransparency = 0 }, 0.45)
			Kit.tween(e, { Position = UDim2.fromOffset(x + 30, y - 46) }, 3, Enum.EasingStyle.Linear)
			task.wait(0.45)
			Kit.tween(e, { BackgroundTransparency = 1 }, 2.55, Enum.EasingStyle.Linear)
			task.wait(2.55)
		end
	end)
	return e
end

-- a rendered icon with its own soft glow pulsing behind it (v12 'iglow', 2.2 s; the icon itself never moves)
local glowN = 0
-- (7 Nov, owner: the left-column chips "look like placeholders"; their art (U4) is coming) THE HUD CHIP: a DIAMOND icon tile in
-- the hotbar's look (dark navy inside, a coloured rim, a thick ink outline, the icon breaking out) overlapping a text PILL
-- that grows with its text (AutomaticSize). The art drops in HERE only (the tile + pill images). opts: name, colour, icon,
-- height (the chip's height: 34 on phones, 40 on PC), textSize, order (LayoutOrder in a UIListLayout).
-- Returns { button, text (Kit.setText works on it), tile, pill }
-- (7 Nov: THE HUD ART (owner, U4): Kit.HudArt = the image ids. opts.art = a chip image ({ id, w }, 194 px high, the diamond
-- icon baked in at the left, a dark pill at the right). It's 9-sliced through the pill's middle so the diamond keeps its
-- look and the pill grows with its text (at the art's fixed size the pill only fitted ~4 characters); the text sits in the
-- pill's dark inside (x from 56% of the art, y 28-72%), white, black stroke)
Kit.HudArt = {
	chipGift = { id = 106148395751692, w = 311 }, chipInvite = { id = 111001668126320, w = 307 }, chipGroup = { id = 116787686626945, w = 302 },
	chipPremium = { id = 83690963323861, w = 303 }, chipBoosts = { id = 92894565203951, w = 310 },
	lumiPanel = 126958034325257, barTrack = 136600884639828, barFill = 111345712527230, btnClose = 80656129796820, btnSkip = 132028182309118,
	tagStep = 72150251114770, slotReward = 106310280299667, btnGreen = 107063255385368, btnBlue = 92410784484864, btnRed = 78194072121960,
	tagGold = 135937216600796, pillViolet = 91919107705618,
}
-- (7 Nov) a HORIZONTAL 3-slice drawn by hand: the image's left part (0..x0) and right part (x1..imgW) at their own
-- proportions, the middle (x0..x1) stretched; all at the height h. (Roblox's SliceScale drew the art chips' corners almost
-- full size at small heights, squeezing the diamond: this never depends on it.) Returns the frame and resize(w)
function Kit.slice3(parent: Instance, id: number, imgW: number, imgH: number, x0: number, x1: number, x: number, y: number, w: number, h: number, z: number?)
	local f = new("Frame", { Name = "Art", BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = z or 1 }, parent)
	local k = h / imgH
	local L, R = x0 * k, (imgW - x1) * k
	local function piece(ox, ow)
		return new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://" .. id, ImageRectOffset = Vector2.new(ox, 0), ImageRectSize = Vector2.new(ow, imgH),
			ScaleType = Enum.ScaleType.Stretch, ZIndex = z or 1 }, f)
	end
	local left, mid, right = piece(0, x0), piece(x0, x1 - x0), piece(x1, imgW - x1)
	local function resize(newW: number)
		newW = math.max(newW, L + R)
		f.Size = UDim2.fromOffset(newW, h)
		left.Position, left.Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(math.floor(L + 0.5), h)
		mid.Position, mid.Size = UDim2.fromOffset(math.floor(L + 0.5), 0), UDim2.fromOffset(math.max(0, math.ceil(newW - L - R)), h)
		right.Position, right.Size = UDim2.fromOffset(math.floor(newW - R), 0), UDim2.fromOffset(math.ceil(R), h)
	end
	resize(w)
	return f, resize
end
function Kit.hudChip(parent: Instance, opts)
	local H = opts.height or 40
	local colour = opts.colour or Color3.new(1, 1, 1)
	local art = opts.art
	if art then
		local k = H / 194
		local btn = new("TextButton", { Name = opts.name or "Chip", Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
			Size = UDim2.fromOffset(math.floor(art.w * k), H), LayoutOrder = opts.order or 0, ZIndex = 5 }, parent)
		local _, resizeArt = Kit.slice3(btn, art.id, art.w, 194, math.floor(art.w * 0.64), math.floor(art.w * 0.8), 0, 0, math.floor(art.w * k), H, 5)
		local x0, capR = art.w * 0.56 * k, art.w * 0.07 * k
		local text = new("TextLabel", { Name = "Text", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.fromOffset(math.floor(x0), math.floor(H * 0.28)), Size = UDim2.fromOffset(0, math.floor(H * 0.44)),
			Text = "", FontFace = Kit.FONT_HEAVY, TextSize = opts.textSize or 18, TextColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, btn)
		new("UIStroke", { Color = INK, Thickness = 1.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, text)
		-- (the chip's width = the art's left part + the text + the art's right cap; never narrower than the art itself)
		local function fit()
			local per = if btn.AbsoluteSize.Y > 0 then btn.AbsoluteSize.Y / H else 1
			local tw = text.AbsoluteSize.X / per
			local w = math.max(math.floor(art.w * k), math.ceil(x0 + tw + capR + 4))
			btn.Size = UDim2.fromOffset(w, H)
			resizeArt(w)
		end
		text:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		return { button = btn, text = text, tile = nil, pill = btn }
	end
	local btn = new("TextButton", { Name = opts.name or "Chip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(H, H), LayoutOrder = opts.order or 0, ZIndex = 5 }, parent)
	local pillH = math.floor(H * 0.78)
	local pillY = math.floor((H - pillH) / 2)
	-- the pill: an ink drop shadow, a dark glossy plate with the chip's colour as its rim; the text pads past the tile's half
	local pill = new("Frame", { Name = "Pill", BackgroundColor3 = Color3.new(1, 1, 1), AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.fromOffset(math.floor(H * 0.5), pillY), Size = UDim2.fromOffset(0, pillH), ZIndex = 5 }, btn)
	Kit.corner(pill, math.floor(pillH / 2))
	Kit.stroke(pill, colour, 2.5, 0.05)
	Kit.grad(pill, Kit.hex("#2a2240"), Kit.hex("#0f0b18"), 90)
	new("UIPadding", { PaddingLeft = UDim.new(0, math.floor(H * 0.58)), PaddingRight = UDim.new(0, 12) }, pill)
	local text = new("TextLabel", { Name = "Text", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, pillH),
		Text = "", FontFace = Kit.FONT_HEAVY, TextSize = opts.textSize or 18, TextColor3 = opts.textColour or colour, ZIndex = 6 }, pill)
	new("UIStroke", { Color = INK, Thickness = 1.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, LineJoinMode = Enum.LineJoinMode.Round }, text)
	-- the diamond tile (the hotbar key's look), the icon breaking out of it
	local side = math.floor(H * 0.7)
	local tile = new("Frame", { Name = "Tile", BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45,
		Position = UDim2.fromOffset(math.floor(H / 2), math.floor(H / 2)), Size = UDim2.fromOffset(side, side), ZIndex = 7 }, btn)
	Kit.grad(tile, Kit.hex("#2c2735"), Kit.hex("#121016"), 90)
	Kit.stroke(tile, INK, 2)
	local ring = new("Frame", { Name = "Rim", BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(side - 4, side - 4), ZIndex = 8 }, tile)
	Kit.stroke(ring, colour, 2)
	if opts.icon then Kit.icon(btn, opts.icon, math.floor(H * 0.06), math.floor(H * 0.02), math.floor(H * 0.9), nil, { ZIndex = 9 }) end
	return { button = btn, text = text, tile = tile, pill = pill }
end
function Kit.icon(parent, name, x, y, w, glowColor: Color3?, props)
	local holder = Kit.box(parent, x, y, w, w, { ZIndex = (props and props.ZIndex) or 8 })
	if glowColor then
		local g = new("ImageLabel", { Name = "Glow", BackgroundTransparency = 1, Image = A.softglow, ImageColor3 = glowColor, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(1.05, 1.05), ImageTransparency = 0.45, ZIndex = holder.ZIndex }, holder)
		g:SetAttribute("AllowOverlap", true) -- (a breathing glow: decoration, UIAudit leaves it out)
		glowN += 1
		local d = (glowN % 7) * 0.37
		task.spawn(function()
			task.wait(d)
			if not Kit.calm() and alive(g) then
				Kit.tween(g, { ImageTransparency = 0.05, Size = UDim2.fromScale(1.35, 1.35) }, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			end
		end)
	end
	-- (7 Nov: "ui:<name>" = the new UI art icons, ArtIds.uiIcon)
	local image = A.icon[name]
	if not image and type(name) == "string" and string.sub(name, 1, 3) == "ui:" then
		image = require(ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("ArtIds")).uiIcon[string.sub(name, 4)]
	end
	local img = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = image or "", Size = UDim2.fromScale(1, 1), ZIndex = holder.ZIndex + 1,
		ScaleType = Enum.ScaleType.Fit }, holder)
	-- hard drop shadow (v12: drop-shadow 0 3px 0 rgba(0,0,0,.6))
	new("ImageLabel", { Name = "Shadow", BackgroundTransparency = 1, Image = img.Image, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.4,
		Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 3), ZIndex = holder.ZIndex, ScaleType = Enum.ScaleType.Fit }, holder)
	return img, holder
end

-- the v12 button: ink outline, gradient fill with a white top line, static stripes, hard 2 px drop shadow
function Kit.button(parent, x, y, w, h, c1: Color3, c2: Color3, props)
	local shadow = Kit.box(parent, x, y + 2, w, h, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = (props and props.ZIndex) or 3 })
	Kit.corner(shadow, 5)
	local b = new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = shadow.ZIndex + 1 }, parent)
	Kit.corner(b, 5)
	Kit.stroke(b, INK, 2)
	local g = Kit.grad(b, c1, c2, 90)
	-- stripes (static) + the white top line
	-- (7 Nov: the stripes are the button's size, tiled, and rounded like it: ClipsDescendants clips square, so a bigger
	-- image showed square corners outside the button's curve)
	local stripes = new("ImageLabel", { Name = "Stripes", BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.87, Size = UDim2.fromScale(1, 1),
		ZIndex = b.ZIndex, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(512, 128) }, b)
	Kit.Round(stripes, 5)
	new("Frame", { Name = "TopLine", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.55, BorderSizePixel = 0,
		Position = UDim2.fromOffset(2, 1), Size = UDim2.new(1, -4, 0, 2), ZIndex = b.ZIndex }, b)
	local inner = Kit.box(b, 0, 0, w, h, { Name = "Inner", ZIndex = b.ZIndex + 2 })
	inner.Size = UDim2.fromScale(1, 1)
	-- press: drop into the lip
	b.MouseButton1Down:Connect(function()
		b.Position = UDim2.fromOffset(x, y + 2)
	end)
	local function up() b.Position = UDim2.fromOffset(x, y) end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b, inner, g, shadow
end
-- a v12 scroll area (owner, boards fix 2: "a scrollingframe and not pages"): a see-through ScrollingFrame at x, y, w, h (put
-- the content inside it) with a 10 px gold thumb on a dark track (right edge for dir "Y", bottom for "X"; the track shows
-- only when there is something to scroll). The thumb is drawn here (gold gradient, ink outline): Roblox's own bar picture is
-- grey, so tinted gold it came out brown; it stays hidden. Mouse wheel and touch drag are Roblox's own; a MOUSE drag is
-- added here (Roblox has none). On a SurfaceGui pass props.pointer(screenPos) -> the point in the gui's own pixels (or nil if off it): Roblox
-- doesn't wheel-scroll a SurfaceGui, so then the wheel is handled here too (and the camera doesn't zoom while over the list).
-- Returns the ScrollingFrame and its state: state.moved = this press dragged (buttons inside skip their click then).
local scrollerN = 0
-- while the mouse is over a board's list the camera's zoom is held where it is (the wheel scrolls the list instead)
local zoomHeld = nil
local function holdZoom(on: boolean)
	local plr = game:GetService("Players").LocalPlayer
	if not plr then return end
	if on and not zoomHeld then
		zoomHeld = { plr.CameraMinZoomDistance, plr.CameraMaxZoomDistance }
		local cam = workspace.CurrentCamera
		local d = math.clamp(if cam then (cam.CFrame.Position - cam.Focus.Position).Magnitude else 15, zoomHeld[1], zoomHeld[2])
		plr.CameraMinZoomDistance = d
		plr.CameraMaxZoomDistance = d
	elseif not on and zoomHeld then
		plr.CameraMaxZoomDistance = zoomHeld[2]
		plr.CameraMinZoomDistance = zoomHeld[1]
		zoomHeld = nil
	end
end
local function shown(o: Instance): boolean
	while o and not o:IsA("LayerCollector") do
		if o:IsA("GuiObject") and not o.Visible then return false end
		o = o.Parent
	end
	return o ~= nil and (o :: any).Enabled ~= false
end
function Kit.scroller(parent, x, y, w, h, dir: string, props)
	local z = (props and props.ZIndex) or 4
	local vertical = dir ~= "X"
	local track = Kit.box(parent, if vertical then x + w - 10 else x, if vertical then y else y + h - 10, if vertical then 10 else w, if vertical then h else 10,
		{ Name = "ScrollTrack", BackgroundTransparency = 0, BackgroundColor3 = Kit.hex("#221d2a"), ZIndex = z + 2, Visible = false })
	Kit.corner(track, 5)
	Kit.stroke(track, INK, 1.5)
	local thumb = Kit.box(track, 0, 0, 10, 10, { Name = "Thumb", BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z + 3 })
	Kit.corner(thumb, 5)
	Kit.stroke(thumb, INK, 1)
	Kit.grad(thumb, Kit.hex("#ffe08a"), Kit.hex("#ff9a1a"), if vertical then 0 else 90)
	local sf = new("ScrollingFrame", { Name = "Scroll", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 10, ScrollBarImageTransparency = 1,
		ScrollingDirection = if vertical then Enum.ScrollingDirection.Y else Enum.ScrollingDirection.X, ElasticBehavior = Enum.ElasticBehavior.Always,
		VerticalScrollBarInset = Enum.ScrollBarInset.None, HorizontalScrollBarInset = Enum.ScrollBarInset.None,
		CanvasSize = UDim2.fromOffset(if vertical then 0 else w, if vertical then h else 0), ZIndex = z + 1 }, parent)
	local function canScroll(): boolean
		local c, win = sf.AbsoluteCanvasSize, sf.AbsoluteWindowSize
		return if vertical then c.Y > win.Y + 1 else c.X > win.X + 1
	end
	local function updateTrack()
		track.Visible = canScroll()
		if not track.Visible then return end
		local c, win, pos = sf.AbsoluteCanvasSize, sf.AbsoluteWindowSize, sf.CanvasPosition
		local len = if vertical then h else w
		local k = (if vertical then sf.AbsoluteSize.Y / math.max(1, h) else sf.AbsoluteSize.X / math.max(1, w))
		local full, seen = (if vertical then c.Y else c.X) / k, (if vertical then win.Y else win.X) / k
		local size = math.max(30, len * seen / full)
		local at = math.clamp((if vertical then pos.Y else pos.X) / math.max(1, full - seen), 0, 1) * (len - size)
		thumb.Size = if vertical then UDim2.fromOffset(10, size) else UDim2.fromOffset(size, 10)
		thumb.Position = if vertical then UDim2.fromOffset(0, at) else UDim2.fromOffset(at, 0)
	end
	sf:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateTrack)
	sf:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateTrack)
	sf:GetPropertyChangedSignal("CanvasPosition"):Connect(updateTrack)
	updateTrack()

	-- the mouse (and touch, if Roblox doesn't scroll it itself) drag
	local state = { moved = false, frame = sf, track = track }
	local pointer = (props and props.pointer) or function(p: Vector2) return p end
	local press, startAt, startCanvas, lastSet
	local function inside(q: Vector2?): boolean
		if not q then return false end
		local a, s = sf.AbsolutePosition, sf.AbsoluteSize
		return q.X >= a.X and q.X <= a.X + s.X and q.Y >= a.Y and q.Y <= a.Y + s.Y
	end
	local conns = {}
	table.insert(conns, UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then return end
		if not shown(sf) then return end
		local q = pointer(Vector2.new(input.Position.X, input.Position.Y))
		if not inside(q) then return end
		press, startAt, startCanvas, lastSet = input, q, sf.CanvasPosition, sf.CanvasPosition
		state.moved = false
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not press then return end
		if press.UserInputType == Enum.UserInputType.Touch then
			if input ~= press then return end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local q = pointer(Vector2.new(input.Position.X, input.Position.Y))
		if not q then return end
		-- Roblox is scrolling this touch itself: leave it to Roblox
		if (sf.CanvasPosition - lastSet).Magnitude > 1 then
			state.moved, press = true, nil
			return
		end
		-- (gui pixels -> canvas pixels: a UIScale on a 2D window)
		local k = if vertical then sf.AbsoluteSize.Y / math.max(1, sf.Size.Y.Offset) else sf.AbsoluteSize.X / math.max(1, sf.Size.X.Offset)
		local d = (q - startAt) / k
		if not state.moved and d.Magnitude < 6 then return end
		state.moved = true
		if not canScroll() then return end
		local room = (sf.AbsoluteCanvasSize - sf.AbsoluteWindowSize) / k
		sf.CanvasPosition = if vertical then Vector2.new(startCanvas.X, math.clamp(startCanvas.Y - d.Y, 0, math.max(0, room.Y)))
			else Vector2.new(math.clamp(startCanvas.X - d.X, 0, math.max(0, room.X)), startCanvas.Y)
		lastSet = sf.CanvasPosition
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if press and (input == press or (press.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			press = nil
		end
	end))
	-- the wheel on a SurfaceGui: bound (above the camera's zoom) only while the mouse is over the list
	local wheelAction, bound = nil, false
	if props and props.pointer then
		scrollerN += 1
		wheelAction = "KitScrollWheel" .. scrollerN
		local goal = nil
		local function hovering(p: Vector2): boolean return shown(sf) and canScroll() and inside(pointer(p)) end
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local want = hovering(Vector2.new(input.Position.X, input.Position.Y))
			if want == bound then return end
			bound = want
			holdZoom(want)
			if want then
				ContextActionService:BindActionAtPriority(wheelAction, function(_, _, input2)
					if not hovering(Vector2.new(input2.Position.X, input2.Position.Y)) then return Enum.ContextActionResult.Pass end
					local step = -input2.Position.Z * 90
					local k = if vertical then sf.AbsoluteSize.Y / math.max(1, h) else sf.AbsoluteSize.X / math.max(1, w)
					local room = (sf.AbsoluteCanvasSize - sf.AbsoluteWindowSize) / k
					local from = goal or sf.CanvasPosition
					goal = if vertical then Vector2.new(from.X, math.clamp(from.Y + step, 0, math.max(0, room.Y)))
						else Vector2.new(math.clamp(from.X + step, 0, math.max(0, room.X)), from.Y)
					local tw = Kit.tween(sf, { CanvasPosition = goal }, 0.15)
					tw.Completed:Connect(function(s) if s == Enum.PlaybackState.Completed then goal = nil end end)
					return Enum.ContextActionResult.Sink
				end, false, Enum.ContextActionPriority.High.Value + 10, Enum.UserInputType.MouseWheel)
			else
				ContextActionService:UnbindAction(wheelAction)
			end
		end))
	end
	sf.Destroying:Connect(function()
		for _, c in ipairs(conns) do c:Disconnect() end
		if wheelAction then ContextActionService:UnbindAction(wheelAction) end
		if wheelAction and bound then holdZoom(false) end
	end)
	-- scrolls so a child (a row's button) is fully on show
	function state.reveal(obj: GuiObject)
		local k = sf.AbsoluteSize.Y / math.max(1, sf.Size.Y.Offset)
		local top = (obj.AbsolutePosition.Y - sf.AbsolutePosition.Y) / k
		local bottom = top + obj.AbsoluteSize.Y / k
		local winH = sf.AbsoluteWindowSize.Y / k
		if top >= 0 and bottom <= winH then return end
		local room = (sf.AbsoluteCanvasSize.Y - sf.AbsoluteWindowSize.Y) / k
		local want = if top < 0 then sf.CanvasPosition.Y + top - 12 else sf.CanvasPosition.Y + bottom - winH + 12
		sf.CanvasPosition = Vector2.new(sf.CanvasPosition.X, math.clamp(want, 0, math.max(0, room)))
	end
	return sf, state
end

function Kit.recolour(button, c1: Color3, c2: Color3)
	local g = button:FindFirstChildOfClass("UIGradient")
	if g then g.Color = ColorSequence.new(c1, c2) end
end

-- clears the moving VFX inside a button (when its state changes)
function Kit.clearVfx(holder)
	for _, c in ipairs(holder:GetChildren()) do
		if c:GetAttribute("Vfx") then c:Destroy() end
	end
end
function Kit.tagVfx(o)
	o:SetAttribute("Vfx", true)
	return o
end

------------------------------------------------------------------------ SOUND (alpha part 2): every id is in Galaxy.Sounds.
-- Two SoundGroups carry the player's Settings sliders: GalaxySFX (every effect) and GalaxyMusic (the loop).
-- Kit.sound(name, opts?) -> Sound: pooled 2D, or 3D at opts.at (a Vector3); opts.pitch / opts.volume multiply the config's.
-- The old names still work: "buy" = the click, "no" = the error thud.
local SoundService = game:GetService("SoundService")
local SoundCfg = require(ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("Sounds"))
Kit.Sounds = SoundCfg
local groups = {}
local function soundGroup(name: string): SoundGroup
	if groups[name] then return groups[name] end
	local g = SoundService:FindFirstChild("Galaxy" .. name)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = "Galaxy" .. name
		g.Volume = if name == "Music" then SoundCfg.Default.music else SoundCfg.Default.sfx
		g.Parent = SoundService
	end
	groups[name] = g
	return g
end
local ALIAS = { buy = "click", no = "error" }
local pool, poolI = {}, 0
function Kit.sound(name: string, opts): Sound?
	local spec = SoundCfg.List[ALIAS[name] or name]
	if not spec then return nil end
	if SoundCfg.StingerDuck and SoundCfg.StingerDuck.names[ALIAS[name] or name] then Kit.musicStinger() end
	local s: Sound
	if opts and opts.at then
		-- 3D: heard near where it happens (an attachment in the terrain, gone when the sound ends)
		local a = Instance.new("Attachment")
		a.WorldPosition = opts.at
		a.Parent = workspace.Terrain
		s = Instance.new("Sound")
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = spec.range or 160
		s.Parent = a
		s.Ended:Once(function() a:Destroy() end)
		task.delay(8, function() if a.Parent then a:Destroy() end end)
	else
		if #pool == 0 then
			for i = 1, 12 do
				local p = Instance.new("Sound")
				p.Name = "KitSound" .. i
				p.Parent = SoundService
				pool[i] = p
			end
		end
		poolI = poolI % #pool + 1
		s = pool[poolI]
	end
	s.SoundGroup = soundGroup("SFX")
	s.SoundId = "rbxassetid://" .. spec.id
	s.Volume = spec.volume * ((opts and opts.volume) or 1)
	s.PlaybackSpeed = (spec.pitch or 1) * ((opts and opts.pitch) or 1) * (1 + (math.random() * 2 - 1) * (spec.vary or 0))
	s.TimePosition = spec.start or 0
	s:Play()
	-- (#242: a buy is a TWO-NOTE rising confirm: the click, then a major third up 70 ms later)
	if name == "buy" and not (opts and opts.second) then
		task.delay(0.07, function() Kit.sound("buy", { second = true, pitch = 1.26 * ((opts and opts.pitch) or 1), volume = 0.8 * ((opts and opts.volume) or 1) }) end)
	end
	return s
end
-- THE MUSIC PLAYLIST (5 Nov; Galaxy.Sounds.Playlist): Kit.music() starts it once. Shuffled each session; each track plays
-- once, then a new shuffle; never the same track twice in a row (also not across the reshuffle); 2 s crossfades; a track's
-- silent tail is cut (PlaybackRegion). A track that won't load (moderated / gone) is skipped, logged, and left out after.
-- A track's volume = MusicBus x its loudness match x the crossfade x Kit.musicFade x Kit.musicDuck (the MUSIC slider is
-- the GalaxyMusic SoundGroup on top).
-- Kit.musicFade(k, t): to k x in t seconds; at 0 the rotation PAUSES on the same track, and a fade back up RESUMES it there
-- (the Supernova wind-up: 0 in 0.3 s; after it: 1 in 1.5 s). Kit.musicDuck(on): quieter while a big window is open.
-- Studio test: Workspace TestMusicSkip = any new value -> the playing track jumps to 6 s before its crossfade.
local musicStarted = false
local musicFadeV = Instance.new("NumberValue")
musicFadeV.Value = 1
local musicDuckV = Instance.new("NumberValue")
musicDuckV.Value = 1
local musicDecks = {} -- the playing tracks (2 during a crossfade): { sound, env = NumberValue, spec, stop }
local musicNow = nil -- the current deck
local musicNext = nil -- the next deck, loaded in the background
local musicOrder, musicI, musicLast = {}, 0, nil
local musicBad = {} -- [id] = true: didn't load, left out
local musicPaused, musicSwitching = false, false
local musicEventOn = false -- (7 Nov: the 2x event's track plays instead of the playlist while an event runs)
local musicStingerV = Instance.new("NumberValue")
musicStingerV.Value = 1
local function musicReshuffle()
	local list = {}
	for _, spec in ipairs(SoundCfg.Playlist) do
		if not musicBad[spec.id] then table.insert(list, spec) end
	end
	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
	-- (never the same track twice in a row, also across the reshuffle)
	if #list > 1 and list[1].id == musicLast then list[1], list[2] = list[2], list[1] end
	musicOrder, musicI = list, 0
end
local function musicNextSpec()
	local ev = SoundCfg.EventTrack
	if musicEventOn and ev and not musicBad[ev.id] then return ev end
	if musicI >= #musicOrder then musicReshuffle() end
	if #musicOrder == 0 then return nil end
	musicI += 1
	return musicOrder[musicI]
end
-- loads the next track that works (skips + logs the ones that don't)
local function musicLoad()
	for _ = 1, #SoundCfg.Playlist + 1 do
		local spec = musicNextSpec()
		if not spec then return nil end
		local s = Instance.new("Sound")
		s.Name = "GalaxyMusic_" .. spec.id
		s:SetAttribute("Track", spec.name)
		s.SoundId = "rbxassetid://" .. spec.id
		s.SoundGroup = soundGroup("Music")
		s.Volume = 0
		s.Parent = SoundService
		local t = os.clock()
		while not s.IsLoaded and os.clock() - t < 10 do task.wait(0.1) end
		if s.IsLoaded and s.TimeLength > 5 then
			local stop = math.min(spec.stop or s.TimeLength, s.TimeLength)
			s.PlaybackRegionsEnabled = true
			s.PlaybackRegion = NumberRange.new(spec.start or 0, stop)
			return { sound = s, env = Instance.new("NumberValue"), spec = spec, stop = stop }
		end
		warn("[GalaxyMusic] skipped " .. spec.id .. " (" .. spec.name .. "): it didn't load (moderated or gone)")
		musicBad[spec.id] = true
		s:Destroy()
	end
	return nil
end
local function musicPlay(deck, fadeIn: number)
	deck.sound.TimePosition = deck.spec.start or 0
	deck.sound:Play()
	deck.env.Value = 0
	TweenService:Create(deck.env, TweenInfo.new(fadeIn, Enum.EasingStyle.Linear), { Value = 1 }):Play()
	table.insert(musicDecks, deck)
	musicNow, musicLast = deck, deck.spec.id
	-- (the next one loads while this one plays)
	musicNext = nil
	task.spawn(function() musicNext = musicLoad() end)
end
local function musicDrop(deck, t: number)
	TweenService:Create(deck.env, TweenInfo.new(t, Enum.EasingStyle.Linear), { Value = 0 }):Play()
	task.delay(t + 0.1, function()
		local i = table.find(musicDecks, deck)
		if i then table.remove(musicDecks, i) end
		deck.sound:Destroy()
	end)
end
local function musicSwitch()
	musicSwitching = true
	local old = musicNow
	local t = os.clock()
	while not musicNext and os.clock() - t < 12 do task.wait(0.2) end -- (still loading: wait, the old one plays on)
	local nextDeck = musicNext
	-- (the event started / ended while the next one was loading: load the right one)
	if nextDeck and (nextDeck.spec == SoundCfg.EventTrack) ~= musicEventOn then
		nextDeck.sound:Destroy()
		nextDeck = nil
	end
	if not nextDeck then nextDeck = musicLoad() end
	if nextDeck then
		musicPlay(nextDeck, SoundCfg.MusicCrossfade)
		if old then musicDrop(old, SoundCfg.MusicCrossfade) end
	end
	musicSwitching = false
end
function Kit.music()
	if musicStarted then return end
	musicStarted = true
	task.spawn(function()
		musicReshuffle()
		local first = musicLoad()
		if first then musicPlay(first, 1.5) end
	end)
	game:GetService("RunService").Heartbeat:Connect(function()
		for _, d in ipairs(musicDecks) do
			d.sound.Volume = SoundCfg.MusicBus * (d.spec.volume or 1) * d.env.Value * musicFadeV.Value * musicDuckV.Value * musicStingerV.Value
		end
		local now = musicNow
		if now and not musicPaused and not musicSwitching and now.sound.Parent
			and (now.sound.TimePosition >= now.stop - SoundCfg.MusicCrossfade or not now.sound.IsPlaying) then
			task.spawn(musicSwitch)
		end
	end)
	if game:GetService("RunService"):IsStudio() then
		workspace:GetAttributeChangedSignal("TestMusicSkip"):Connect(function()
			if musicNow then musicNow.sound.TimePosition = math.max(0, musicNow.stop - SoundCfg.MusicCrossfade - 6) end
		end)
	end
end
local musicFadeTween: Tween? = nil
function Kit.musicFade(k: number, t: number)
	Kit.music()
	if musicFadeTween then musicFadeTween:Cancel() end
	if k > 0 and musicPaused then
		-- (back from silence: the same track goes on where it stopped)
		musicPaused = false
		for _, d in ipairs(musicDecks) do d.sound:Resume() end
	end
	musicFadeTween = TweenService:Create(musicFadeV, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = k })
	musicFadeTween:Play()
	if k <= 0 then
		local tw = musicFadeTween
		task.delay(t, function()
			if musicFadeTween == tw and musicFadeV.Value <= 0.001 then
				musicPaused = true
				for _, d in ipairs(musicDecks) do d.sound:Pause() end
			end
		end)
	end
end
local musicDucked = false
function Kit.musicDuck(on: boolean)
	if on == musicDucked then return end
	musicDucked = on
	TweenService:Create(musicDuckV, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Value = if on then (SoundCfg.WindowDuck or 0.5) else 1 }):Play()
end
-- (7 Nov) a 2x event is running (GalaxyLive): its track crossfades in now, and back to the playlist when it ends
function Kit.musicEvent(on: boolean)
	if on == musicEventOn then return end
	musicEventOn = on
	if musicStarted and not musicSwitching and not musicPaused then task.spawn(musicSwitch) end
end
-- (7 Nov) a big stinger: the music dips (StingerDuck) and comes back
function Kit.musicStinger()
	local d = SoundCfg.StingerDuck
	if not d then return end
	local down = TweenService:Create(musicStingerV, TweenInfo.new(d.attack, Enum.EasingStyle.Linear), { Value = d.k })
	down:Play()
	down.Completed:Once(function()
		TweenService:Create(musicStingerV, TweenInfo.new(d.release, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 }):Play()
	end)
end
-- the Settings sliders (0..1)
function Kit.setVolumes(musicVol: number?, sfxVol: number?)
	if musicVol then soundGroup("Music").Volume = math.clamp(musicVol, 0, 1) end
	if sfxVol then soundGroup("SFX").Volume = math.clamp(sfxVol, 0, 1) end
end
-- loads every effect in the background (Sound objects: a plain id string would be preloaded as an image)
function Kit.preloadSounds()
	local t = {}
	for _, spec in pairs(SoundCfg.List) do
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. spec.id
		table.insert(t, s)
	end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(t) end)
	for _, s in ipairs(t) do s:Destroy() end
end

------------------------------------------------------------------------ WINDOW (alpha part 2): the v12 window frame as one piece
-- (the UPGRADES window's frame: breathing glow, ink frame, dark body, a header with stripes + its shine + embers, the icon
-- breaking the top-left corner, the title, the pink X). opts: title, icon, iconGlow, c1 / c2 (the header gradient), glow
-- (the breathing colour), line (the body's thin edge colour), lip (the header's lower band). Returns win, closeButton.
function Kit.window(parent, w: number, h: number, opts)
	local win = Kit.box(parent, 0, 0, w, h, { Name = opts.name or "Window" })
	local glow = new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow9, ImageColor3 = opts.glow or Color3.fromRGB(255, 100, 20), ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(48, 48, 80, 80), Position = UDim2.fromOffset(-34, -34), Size = UDim2.fromOffset(w + 68, h + 68), ImageTransparency = 0.25, ZIndex = 1 }, win)
	if not Kit.calm() then
		Kit.tween(glow, { ImageTransparency = 0, Position = UDim2.fromOffset(-44, -44), Size = UDim2.fromOffset(w + 88, h + 88) }, 1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	end
	-- (7 Nov, rounding rules: the outer frame 10; the body + header are inset 3, so 7; the accent stroke on the outermost
	-- layer, border mode; the header's stripes are its size, tiled and rounded like it)
	local OUTER, INSET = 10, 3
	local frame = Kit.box(win, 0, 0, w, h, { BackgroundTransparency = 0, BackgroundColor3 = INK, ZIndex = 2 })
	Kit.stroke(frame, opts.line or Color3.fromRGB(255, 106, 26), 1.5, 0.45)
	Kit.Round(frame, OUTER)
	local body = Kit.box(win, INSET, INSET, w - 2 * INSET, h - 2 * INSET, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.Round(body, Kit.InnerRadius(OUTER, INSET))
	Kit.grad(body, Kit.hex("#1a1620"), Kit.hex("#0f0d13"), 90)
	local header = Kit.box(win, INSET, INSET, w - 2 * INSET, 56, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, ClipsDescendants = true })
	Kit.Round(header, Kit.InnerRadius(OUTER, INSET))
	Kit.grad(header, opts.c1, opts.c2, 0)
	local hs = new("ImageLabel", { BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.9, Size = UDim2.fromScale(1, 1), ZIndex = 4,
		ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(512, 128) }, header)
	Kit.Round(hs, Kit.InnerRadius(OUTER, INSET))
	Kit.box(win, 3, 40, w - 6, 20, { BackgroundTransparency = 0, BackgroundColor3 = opts.lip or opts.c2, ZIndex = 4 })
	Kit.box(win, 9, 4, w - 18, 2, { BackgroundTransparency = 0.4, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	local sweep = Kit.shine(header, 4.5, 0.16, 0.3)
	sweep.ZIndex = 5
	for i = 1, math.floor(w / 80) do
		Kit.ember(win, 20 + (i - 1) * 80 + 3, 3 + 44 + ((i - 1) % 3) * 4, ((i - 1) * 0.41) % 3)
	end
	Kit.box(win, 3, 59, w - 6, 2, { BackgroundTransparency = 0, BackgroundColor3 = INK, ZIndex = 5 })
	Kit.icon(win, opts.icon, -22, -30, 92, opts.iconGlow, { ZIndex = 9 })
	Kit.sparkle(win, -26, -24, 12, 0.5)
	Kit.sparkle(win, 60, 34, 9, 1.1)
	Kit.text(win, 80, 13, w - 200, 34, opts.title, 28, { ZIndex = 8, stroke = 1.8 })
	-- the pink X (the UPGRADES window's)
	local closeBtn = new("TextButton", { Name = "Close", Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(w - 52, 13), Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, win)
	Kit.corner(closeBtn, 6)
	Kit.stroke(closeBtn, Color3.new(1, 1, 1), 2, 0.1)
	Kit.grad(closeBtn, Kit.hex("#ff7d8e"), Kit.hex("#e2334c"), 90)
	for _, r in ipairs({ 45, -45 }) do
		local bar = Kit.box(closeBtn, 0, 0, 20, 4, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = r, ZIndex = 9 })
		bar.Position = UDim2.fromScale(0.5, 0.5)
		Kit.corner(bar, 2)
	end
	local sh = Kit.box(win, w - 52, 15, 34, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 7 })
	Kit.corner(sh, 6)
	return win, closeBtn
end

-- a dark inset panel (the UPGRADES window's list / rows panels)
-- a RANK line ("FLARE III · ✦12") filling `parent` (scale sizes: billboards): the text before the ✦, our 4-point sparkle
-- image for the ✦ (Montserrat has no ✦ glyph: it drew a box), the number after it. Returns the labels (to tint) + the star.
function Kit.rankLine(parent: GuiObject, text: string, font: Font?, starColour: Color3?)
	local before, after = string.match(text, "^(.-)%s*✦(%d+)$")
	before = before or text
	local units = #before * 0.62 + (if after then 1.1 + #after * 0.62 else 0)
	local function label(str: string, x: number, w: number, align)
		local l = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(w, 1), FontFace = font or Kit.FONT_HEAVY,
			TextScaled = true, Text = str, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = align }, parent)
		return l
	end
	local labels = {}
	local wBefore = #before * 0.62 / units
	table.insert(labels, label(before, 0, wBefore, if after then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center))
	local star
	if after then
		local wStar = 1.1 / units
		star = new("ImageLabel", { BackgroundTransparency = 1, Image = A.sparkle, ImageColor3 = starColour or Color3.fromRGB(255, 216, 74),
			Position = UDim2.fromScale(wBefore + wStar * 0.08, 0.06), Size = UDim2.fromScale(wStar * 0.84, 0.88), ScaleType = Enum.ScaleType.Fit }, parent)
		table.insert(labels, label(after, wBefore + wStar, 1 - wBefore - wStar, Enum.TextXAlignment.Left))
	end
	return labels, star
end

function Kit.panel(parent, x, y, w, h, z)
	local p = Kit.box(parent, x, y, w, h, { BackgroundTransparency = 0, BackgroundColor3 = Kit.hex("#0b090e"), ZIndex = z or 4 })
	Kit.corner(p, 6)
	Kit.stroke(p, Kit.hex("#2a2433"), 1.5)
	return p
end

-- the red "new" dot (a v12 badge: red fill, ink outline, white top shine; it pulses unless Reduced Motion)
function Kit.redDot(parent, x, y, size, z)
	size = size or 16
	local d = Kit.box(parent, x, y, size, size, { Name = "RedDot", BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z or 12, AnchorPoint = Vector2.new(0.5, 0.5) })
	Kit.corner(d, size)
	Kit.stroke(d, INK, 2)
	Kit.grad(d, Kit.hex("#ff6a6a"), Kit.hex("#d11a2a"), 90)
	local shine = Kit.box(d, size * 0.25, size * 0.12, size * 0.5, size * 0.25, { BackgroundTransparency = 0.35, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = d.ZIndex })
	Kit.corner(shine, size)
	local sc = new("UIScale", { Scale = 1 }, d)
	if not Kit.calm() then Kit.tween(sc, { Scale = 1.18 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) end
	return d
end

-- SLIDER (alpha part 2, Settings): the goal bar's look (dark track, ink outline, gold fill) + a v12 diamond knob (the
-- hotbar's diamond: ink outline, dark fill, gold ring). value 0..1; onChange(v) while dragging, onDone(v) on release.
-- Returns { set = fn(v), get = fn() }. Drag with the mouse or a finger anywhere on the track.
function Kit.slider(parent, x, y, w, value: number, onChange, onDone, z)
	z = z or 6
	local h = 18
	local track = Kit.box(parent, x, y, w, h, { BackgroundTransparency = 0, BackgroundColor3 = Kit.hex("#16131b"), ZIndex = z })
	Kit.corner(track, 9)
	Kit.stroke(track, INK, 2)
	local fill = Kit.box(track, 0, 0, 0, h, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z + 1 })
	Kit.corner(fill, 9)
	Kit.grad(fill, Kit.hex("#ffe08a"), Kit.hex("#ff9a1a"), 90)
	local knob = Kit.box(track, 0, h / 2, 26, 26, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Rotation = 45, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z + 3 })
	Kit.grad(knob, Kit.hex("#2c2735"), Kit.hex("#121016"), 90)
	Kit.stroke(knob, Kit.hex("#0a070d"), 2)
	local ring = Kit.box(knob, 3, 3, 20, 20, { ZIndex = z + 4 })
	Kit.stroke(ring, Kit.hex("#ffd84a"), 2)
	local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(x - 14, y - 12), Size = UDim2.fromOffset(w + 28, h + 24), ZIndex = z + 5 }, parent)
	local v = math.clamp(value, 0, 1)
	local function show()
		fill.Size = UDim2.fromOffset(math.max(h, w * v), h)
		fill.Visible = v > 0
		knob.Position = UDim2.fromOffset(w * v, h / 2)
	end
	show()
	local dragging = nil
	local function setFrom(px: number)
		local k = track.AbsoluteSize.X / math.max(1, w)
		v = math.clamp((px - track.AbsolutePosition.X) / math.max(1, w * k), 0, 1)
		show()
		if onChange then onChange(v) end
	end
	hit.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = input
			setFrom(input.Position.X)
		end
	end)
	local c1 = UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
			setFrom(input.Position.X)
		end
	end)
	local c2 = UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragging or (dragging.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then
			dragging = nil
			if onDone then onDone(v) end
		end
	end)
	hit.Destroying:Connect(function() c1:Disconnect() c2:Disconnect() end)
	return {
		set = function(nv: number) v = math.clamp(nv, 0, 1) show() end,
		get = function() return v end,
	}
end

return Kit
