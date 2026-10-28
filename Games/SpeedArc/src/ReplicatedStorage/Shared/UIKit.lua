-- SPEED ARC UI kit (decided in M1, reuse everywhere). Mobile first: layouts are built in
-- 844 x 390 "design pixels" (a landscape phone) and scaled by one UIScale on the root.
-- Dark navy panels (GYM ARC-style windows, 28 Oct), candy tiles and buttons, GOLD for coins/rewards/premium, white text.
-- One chunky display font (italic, numbers/titles/buttons) + one clean body font.
local TweenService = game:GetService("TweenService")

local Palette = require(script.Parent.Config.Palette)

local UIKit = {}

UIKit.Palette = Palette
UIKit.DesignSize = Vector2.new(844, 390)

UIKit.Fonts = {
	Display = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
	DisplayUpright = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal),
	Body = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
	BodyBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

UIKit.MinTextSize = 13 -- smallest HUD label; nothing smaller anywhere

UIKit.ButtonStyles = {
	Blue = { Base = Palette.ElectricBlue, Light = Palette.BrightBlue, Edge = Palette.DeepBlue, Text = Palette.White, TextStroke = Palette.DeepBlue },
	Gold = { Base = Palette.Gold, Light = Color3.fromHex("#FFE38C"), Edge = Palette.DeepGold, Text = Palette.SpeedBlack, TextStroke = nil },
	Dark = { Base = Palette.Graphite, Light = Color3.fromHex("#4A5596"), Edge = Palette.SpeedBlack, Text = Palette.White, TextStroke = Palette.SpeedBlack },
	Green = { Base = Color3.fromHex("#34C759"), Light = Color3.fromHex("#7CF08F"), Edge = Color3.fromHex("#1D7A35"), Text = Palette.White, TextStroke = Color3.fromHex("#145227") },
	Pink = { Base = Palette.Pink, Light = Color3.fromHex("#FFA6D2"), Edge = Color3.fromHex("#B8306F"), Text = Palette.White, TextStroke = Color3.fromHex("#7A1E4A") },
}

local clickHook = nil
function UIKit.setClickHook(fn)
	clickHook = fn
end

----------------------------------------------------------------------------
-- Basics
----------------------------------------------------------------------------
function UIKit.make(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in props or {} do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	inst.Parent = parent
	return inst
end
local make = UIKit.make

function UIKit.corner(parent, radius)
	return make("UICorner", { CornerRadius = if typeof(radius) == "UDim" then radius else UDim.new(0, radius or 12), Parent = parent })
end

function UIKit.stroke(parent, color, thickness, transparency)
	return make("UIStroke", {
		Color = color or Palette.Graphite,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UIKit.gradient(parent, top, bottom, rotation)
	return make("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

function UIKit.tween(obj, time, props, style, direction)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- Text with a soft dark outline so it reads on any background
function UIKit.text(props)
	local font = props.Font or UIKit.Fonts.Display
	local label = make("TextLabel", {
		Name = props.Name or "Text",
		BackgroundTransparency = 1,
		FontFace = font,
		Text = props.Text or "",
		TextColor3 = props.Color or Palette.White,
		TextSize = math.max(UIKit.MinTextSize, props.TextSize or 18),
		TextScaled = false,
		TextWrapped = props.Wrapped or false,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		RichText = props.RichText or false,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	if props.Stroke ~= false then
		make("UIStroke", {
			Color = props.StrokeColor or Palette.SpeedBlack,
			Thickness = props.StrokeThickness or 1.5,
			Transparency = props.StrokeTransparency or 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Parent = label,
		})
	end
	return label
end

----------------------------------------------------------------------------
-- Panels and pills
----------------------------------------------------------------------------
-- Dark carbon panel: gradient, graphite border, a thin electric-blue accent on the left edge
function UIKit.panel(props)
	local frame = make("Frame", {
		Name = props.Name or "Panel",
		BackgroundColor3 = Palette.White,
		BackgroundTransparency = props.Transparency or 0.04,
		Size = props.Size or UDim2.fromOffset(200, 100),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	UIKit.corner(frame, props.Radius or 14)
	UIKit.gradient(frame, Palette.Carbon, Palette.SpeedBlack, 90)
	UIKit.stroke(frame, props.StrokeColor or Palette.Graphite, props.StrokeThickness or 2)
	if props.Accent ~= false then -- windows switch it off (Accent = false)
		local accent = make("Frame", {
			Name = "Accent",
			BackgroundColor3 = props.AccentColor or Palette.ElectricBlue,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 4, 1, -16),
			Position = UDim2.fromOffset(6, 8),
			ZIndex = (props.ZIndex or 1) + 1,
			Parent = frame,
		})
		UIKit.corner(accent, 2)
	end
	return frame
end

-- Rounded pill used on the top bar (coins, race timer)
function UIKit.pill(props)
	local frame = make("Frame", {
		Name = props.Name or "Pill",
		BackgroundColor3 = Palette.White,
		BackgroundTransparency = 0.08,
		Size = props.Size or UDim2.fromOffset(160, 40),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Parent = props.Parent,
	})
	UIKit.corner(frame, UDim.new(0.5, 0))
	UIKit.gradient(frame, Palette.Carbon, Palette.SpeedBlack, 90)
	UIKit.stroke(frame, props.StrokeColor or Palette.Graphite, 2)
	return frame
end

----------------------------------------------------------------------------
-- Chunky button with a darker bottom edge and a press animation
----------------------------------------------------------------------------
UIKit.sweeps = {} -- the gold buttons' shine sweeps (HudController runs them)

function UIKit.button(props)
	local style = UIKit.ButtonStyles[props.Style or "Blue"]
	local edgeH = props.EdgeHeight or 5
	local radius = props.Radius or 14

	local root = make("TextButton", {
		Name = props.Name or "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.fromOffset(160, 52),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	local scale = make("UIScale", { Parent = root })

	local edge = make("Frame", {
		Name = "Edge",
		BackgroundColor3 = style.Edge,
		Size = UDim2.new(1, 0, 1, -2),
		Position = UDim2.fromOffset(0, 2),
		ZIndex = root.ZIndex,
		Parent = root,
	})
	UIKit.corner(edge, radius)

	local face = make("Frame", {
		Name = "Face",
		BackgroundColor3 = Palette.White,
		Size = UDim2.new(1, 0, 1, -edgeH),
		Position = UDim2.fromOffset(0, 0),
		ZIndex = root.ZIndex + 1,
		Parent = root,
	})
	UIKit.corner(face, radius)
	UIKit.gradient(face, style.Light, style.Base, 90)
	make("UIStroke", {
		Color = style.Light,
		Thickness = 2,
		Transparency = 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = face,
	})
	-- glossy top highlight
	local shine = make("Frame", {
		Name = "Shine",
		BackgroundColor3 = Palette.White,
		BackgroundTransparency = 0.82,
		Size = UDim2.new(1, -12, 0.42, 0),
		Position = UDim2.fromOffset(6, 3),
		ZIndex = root.ZIndex + 2,
		Parent = face,
	})
	UIKit.corner(shine, radius - 4)
	-- primary (gold) buttons: a light sweep runs across now and then (VFX note); one loop drives all
	if (props.Style or "Blue") == "Gold" then
		face.ClipsDescendants = true
		local sweep = make("Frame", {
			Name = "Sweep",
			BackgroundColor3 = Palette.White,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(-0.3, 0, 0.5, 0),
			Size = UDim2.new(0, 18, 1.6, 0),
			Rotation = 20,
			ZIndex = root.ZIndex + 2,
			Parent = face,
		})
		make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 1) }), Parent = sweep })
		table.insert(UIKit.sweeps, sweep)
	end

	local label = UIKit.text({
		Name = "Label",
		Text = props.Text or "",
		TextSize = props.TextSize or 22,
		Color = style.Text,
		Font = props.Font or UIKit.Fonts.Display,
		Stroke = style.TextStroke ~= nil,
		StrokeColor = style.TextStroke,
		StrokeTransparency = 0.5,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		ZIndex = root.ZIndex + 3,
		Parent = face,
	})

	local function press(down)
		if down then
			UIKit.tween(face, 0.06, { Position = UDim2.fromOffset(0, edgeH - 1) })
			UIKit.tween(scale, 0.06, { Scale = 0.96 })
		else
			UIKit.tween(face, 0.12, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
			UIKit.tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	root.MouseButton1Down:Connect(function()
		press(true)
	end)
	root.MouseButton1Up:Connect(function()
		press(false)
	end)
	root.MouseLeave:Connect(function()
		press(false)
	end)
	root.Activated:Connect(function()
		if clickHook and props.Silent ~= true then
			clickHook(props.ClickSound)
		end
		if props.OnClick then
			props.OnClick()
		end
	end)

	return root, label, face
end

-- Restyle a button made by UIKit.button
function UIKit.setButtonStyle(button, styleName)
	local style = UIKit.ButtonStyles[styleName]
	button.Edge.BackgroundColor3 = style.Edge
	local face = button.Face
	face.UIGradient.Color = ColorSequence.new(style.Light, style.Base)
	face.UIStroke.Color = style.Light
	face.Label.TextColor3 = style.Text
	local s = face.Label:FindFirstChildOfClass("UIStroke")
	if s then
		s.Enabled = style.TextStroke ~= nil
		if style.TextStroke then
			s.Color = style.TextStroke
		end
	end
end

----------------------------------------------------------------------------
-- Icons (built from shapes: no emoji, no clip art)
----------------------------------------------------------------------------
function UIKit.coinIcon(size, parent)
	local coin = make("Frame", {
		Name = "Coin",
		BackgroundColor3 = Palette.White,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
	UIKit.corner(coin, UDim.new(0.5, 0))
	UIKit.gradient(coin, Color3.fromHex("#FFE38C"), Palette.DeepGold, 135)
	make("UIStroke", { Color = Color3.fromHex("#9C6508"), Thickness = math.max(1, size / 14), Parent = coin })
	local inner = make("Frame", {
		Name = "Inner",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.64, 0.64),
		Parent = coin,
	})
	UIKit.corner(inner, UDim.new(0.5, 0))
	make("UIStroke", { Color = Color3.fromHex("#FFF1BF"), Thickness = math.max(1, size / 16), Transparency = 0.15, Parent = inner })
	-- slanted speed bars in the middle
	for i = 0, 1 do
		local bar = make("Frame", {
			BackgroundColor3 = Color3.fromHex("#A86A06"),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.42 + i * 0.18, 0.5),
			Size = UDim2.fromScale(0.1, 0.42),
			Rotation = 18,
			Parent = coin,
		})
		UIKit.corner(bar, 2)
	end
	-- highlight
	local hl = make("Frame", {
		BackgroundColor3 = Palette.White,
		BackgroundTransparency = 0.45,
		Position = UDim2.fromScale(0.2, 0.12),
		Size = UDim2.fromScale(0.3, 0.14),
		Rotation = -30,
		Parent = coin,
	})
	UIKit.corner(hl, UDim.new(0.5, 0))
	return coin
end

local MEDAL_COLORS = {
	Gold = { Color3.fromHex("#FFE38C"), Palette.DeepGold, Color3.fromHex("#9C6508") },
	Silver = { Color3.fromHex("#F4F6FA"), Color3.fromHex("#9AA6B8"), Color3.fromHex("#5E6878") },
	Bronze = { Color3.fromHex("#F2B98A"), Color3.fromHex("#B5652E"), Color3.fromHex("#6E3A18") },
}

function UIKit.medalIcon(kind, size, parent, number)
	local c = MEDAL_COLORS[kind] or MEDAL_COLORS.Gold
	local holder = make("Frame", {
		Name = "Medal",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size * 1.3),
		Parent = parent,
	})
	-- ribbon
	for i, rot in { -18, 18 } do
		local strip = make("Frame", {
			BackgroundColor3 = if i == 1 then Palette.ElectricBlue else Palette.DeepBlue,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5 + (i == 1 and -0.13 or 0.13), 0),
			Size = UDim2.fromScale(0.26, 0.5),
			Rotation = rot,
			Parent = holder,
		})
		UIKit.corner(strip, 2)
	end
	local disc = make("Frame", {
		Name = "Disc",
		BackgroundColor3 = Palette.White,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(size, size),
		Parent = holder,
	})
	UIKit.corner(disc, UDim.new(0.5, 0))
	UIKit.gradient(disc, c[1], c[2], 135)
	make("UIStroke", { Color = c[3], Thickness = math.max(1.5, size / 14), Parent = disc })
	local ring = make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		Parent = disc,
	})
	UIKit.corner(ring, UDim.new(0.5, 0))
	make("UIStroke", { Color = c[1], Thickness = math.max(1, size / 18), Transparency = 0.2, Parent = ring })
	if number then
		UIKit.text({
			Text = tostring(number),
			TextSize = math.floor(size * 0.48),
			Color = c[3],
			Stroke = false,
			Parent = disc,
		})
	end
	return holder
end

-- Two slanted chevrons: the "speed" mark next to MPH
function UIKit.speedIcon(size, parent, color)
	local holder = make("Frame", { Name = "SpeedIcon", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Parent = parent })
	for i = 0, 2 do
		local bar = make("Frame", {
			BackgroundColor3 = color or Palette.BrightBlue,
			BackgroundTransparency = i * 0.3,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.75 - i * 0.28, 0.5),
			Size = UDim2.fromScale(0.16, 0.9),
			Rotation = 22,
			Parent = holder,
		})
		UIKit.corner(bar, 2)
	end
	return holder
end

----------------------------------------------------------------------------
-- Windows: one modal panel over a dimmed screen, a title, tabs, a close button.
-- Only one is open at a time (UIKit.openWindow closes the last one).
----------------------------------------------------------------------------
local openWin = nil
UIKit.windowSound = nil -- set by the SoundController (open / close swoosh)

function UIKit.window(props)
	local canvas = props.Parent
	local backdrop = make("TextButton", {
		Name = (props.Name or "Window") .. "Backdrop",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Palette.SpeedBlack,
		BackgroundTransparency = 0.35,
		Position = UDim2.fromOffset(0, -80), -- also dims the strip under Roblox's top bar
		Size = UDim2.new(1, 0, 1, 80),
		Visible = false,
		ZIndex = 20,
		Parent = canvas,
	})
	local w, h = props.Size.X, props.Size.Y
	local panel = UIKit.panel({
		Name = props.Name or "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 30), -- under the top bar, and the bottom still fits a phone
		Size = UDim2.fromOffset(w, h),
		Accent = false,
		ZIndex = 21,
		Parent = backdrop,
	})
	local scale = make("UIScale", { Parent = panel })
	-- the title sits on the panel's top edge: big white italic letters with a dark outline and a
	-- short gold underline (GYM ARC window style, owner 28 Oct)
	local tab = make("Frame", {
		Name = "TitleTab",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, -24),
		Size = UDim2.fromOffset(math.max(170, #props.Title * 21 + 20), 40),
		ZIndex = 23,
		Parent = panel,
	})
	UIKit.text({ Text = props.Title, TextSize = 32, XAlign = Enum.TextXAlignment.Left, StrokeColor = Palette.SpeedBlack, StrokeThickness = 3, StrokeTransparency = 0, ZIndex = 24, Parent = tab })
	local underline = make("Frame", { Name = "Underline", BackgroundColor3 = props.Accent or Palette.Gold, BorderSizePixel = 0, Position = UDim2.fromOffset(2, 38), Size = UDim2.fromOffset(64, 5), ZIndex = 24, Parent = tab })
	UIKit.corner(underline, 3)
	local close = UIKit.button({
		Name = "Close",
		Style = "Dark",
		Text = "X",
		TextSize = 20,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 12, 0, -14),
		Size = UDim2.fromOffset(46, 44),
		ZIndex = 24,
		Parent = panel,
	})
	local content = make("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 30),
		Size = UDim2.new(1, -36, 1, -44),
		ZIndex = 22,
		Parent = panel,
	})
	local win = { backdrop = backdrop, panel = panel, content = content, onClose = nil }
	function win.show()
		if openWin and openWin ~= win then
			openWin.hide(true)
		end
		openWin = win
		backdrop.Visible = true
		scale.Scale = 0.86
		UIKit.tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		if UIKit.windowSound then
			UIKit.windowSound("open")
		end
		if win.onOpen then
			win.onOpen()
		end
	end
	function win.hide(silent)
		if not backdrop.Visible then
			return
		end
		backdrop.Visible = false
		if openWin == win then
			openWin = nil
		end
		if UIKit.windowSound and not silent then
			UIKit.windowSound("close")
		end
		if win.onClose then
			win.onClose()
		end
	end
	function win.isOpen()
		return backdrop.Visible
	end
	close.Activated:Connect(function()
		win.hide()
	end)
	return win
end

function UIKit.closeWindows()
	if openWin then
		openWin.hide()
	end
end

-- a row of tab buttons; returns setTab(name)
function UIKit.tabs(parent, names, onPick, zindex, width)
	local row = make("Frame", { Name = "Tabs", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = zindex, Parent = parent })
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
	local buttons = {}
	local function set(name)
		for n, b in buttons do
			UIKit.setButtonStyle(b, if n == name then "Blue" else "Dark")
		end
		onPick(name)
	end
	for i, n in names do
		local b = UIKit.button({ Name = n, Style = "Dark", Text = n, TextSize = if width and width < 110 then 15 else 17, Size = UDim2.fromOffset(width or 130, 38), ZIndex = zindex, ClickSound = "Tab" })
		b.LayoutOrder = i
		b.Parent = row
		b.Activated:Connect(function()
			set(n)
		end)
		buttons[n] = b
	end
	return set, row
end

----------------------------------------------------------------------------
-- Root ScreenGui with one UIScale (design pixels -> real screen)
----------------------------------------------------------------------------
function UIKit.root(name, playerGui, displayOrder)
	local gui = make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder or 0,
		Parent = playerGui,
	})
	local canvas = make("Frame", {
		Name = "Canvas",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	local scale = make("UIScale", { Parent = canvas })
	local function update()
		local area = gui.AbsoluteSize
		if area.X < 2 then
			area = UIKit.DesignSize
		end
		local s = math.min(area.X / UIKit.DesignSize.X, area.Y / UIKit.DesignSize.Y)
		s = math.clamp(s, 0.7, 1.6)
		scale.Scale = s
		-- the canvas is sized in design pixels so offsets stay in design units
		canvas.Size = UDim2.fromOffset(area.X / s, area.Y / s)
	end
	update()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	return gui, canvas
end

return UIKit
