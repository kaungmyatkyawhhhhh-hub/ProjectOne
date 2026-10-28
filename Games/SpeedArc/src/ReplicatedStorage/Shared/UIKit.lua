-- SPEED ARC UI kit (decided in M1, reuse everywhere). Mobile first: layouts are built in
-- 844 x 390 "design pixels" (a landscape phone) and scaled by one UIScale on the root.
-- Prompt 12 (owner OK, 28 Oct): the kit is ART. Buttons, panels, tiles, pills, bars, badges and icons
-- are 9-slice PNG sprites (tools/make_ui_kit.py -> 3 sheets, Config/UIArt + UIArtSprites). LOCKED:
-- every new screen reuses these functions; never build a coded rectangle + gradient + stroke button.
-- Button colours mean something: Green = buy / go / equip, Blue = normal, Gold = claim / reward,
-- Red = close, Grey = locked, Dark = tabs off and small HUD buttons.
-- One chunky display font (italic, numbers/titles/buttons) with a navy stroke + one clean body font.
local TweenService = game:GetService("TweenService")

local Palette = require(script.Parent.Config.Palette)
local UIArt = require(script.Parent.Config.UIArt)
local Sprites = require(script.Parent.Config.UIArtSprites)

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
	Green = { Sprite = "btn_green", Text = Palette.White, TextStroke = Palette.Navy }, -- buy / go / equip
	Blue = { Sprite = "btn_blue", Text = Palette.White, TextStroke = Palette.Navy }, -- normal, tab on
	Gold = { Sprite = "btn_yellow", Text = Palette.Navy, TextStroke = nil }, -- claim / reward
	Red = { Sprite = "btn_red", Text = Palette.White, TextStroke = Palette.Navy }, -- close
	Grey = { Sprite = "btn_grey", Text = Palette.White, TextStroke = Palette.Navy }, -- locked
	Dark = { Sprite = "btn_navy", Text = Palette.White, TextStroke = Palette.Navy }, -- tab off, small HUD buttons
}

----------------------------------------------------------------------------
-- Sprites (the art kit)
----------------------------------------------------------------------------
local function sheetImage(sheet)
	local id = UIArt.Ids[sheet]
	if id and id ~= "" then
		return "rbxassetid://" .. id
	end
	return UIArt.LocalFolder .. UIArt.Files[sheet]
end

-- Point an ImageLabel / ImageButton at a sprite. `height` (design px) sizes "auto" slices (pills, bars).
function UIKit.applySprite(img, name, height)
	local sp = Sprites[name]
	assert(sp, "UIKit: no sprite " .. tostring(name))
	img.Image = sheetImage(sp[1])
	img.ImageRectOffset = Vector2.new(sp[2], sp[3])
	img.ImageRectSize = Vector2.new(sp[4], sp[5])
	if sp.Slice then
		img.ScaleType = Enum.ScaleType.Slice
		img.SliceCenter = Rect.new(sp.Slice[1], sp.Slice[2], sp.Slice[3], sp.Slice[4])
		img.SliceScale = if sp.SliceScale == "auto" then math.max(0.05, (height or sp[5]) / sp[5]) else sp.SliceScale
	else
		img.ScaleType = Enum.ScaleType.Fit
	end
end

function UIKit.sprite(name, props)
	props = props or {}
	local img = Instance.new("ImageLabel")
	img.Name = props.Name or name
	img.BackgroundTransparency = 1
	img.Size = props.Size or UDim2.fromOffset(40, 40)
	img.Position = props.Position or UDim2.new()
	img.AnchorPoint = props.AnchorPoint or Vector2.zero
	img.ZIndex = props.ZIndex or 1
	img.ImageTransparency = props.ImageTransparency or 0
	if props.Color then
		img.ImageColor3 = props.Color
	end
	local h = props.Height or (img.Size.Y.Scale == 0 and img.Size.Y.Offset) or nil
	UIKit.applySprite(img, name, h)
	img.Parent = props.Parent
	return img
end

-- An icon from the kit (store, locker, coaches, codes, invite, daily, quests, top, settings, close,
-- coin, speed, crown, race, shoe2x)
function UIKit.icon(name, size, parent, props)
	props = props or {}
	props.Size = props.Size or UDim2.fromOffset(size, size)
	props.Parent = parent
	props.Name = props.Name or "Icon"
	return UIKit.sprite("icon_" .. name, props)
end

-- nearest colour-glow tile for any colour (Color3 or hex)
function UIKit.tileKey(color)
	if typeof(color) == "string" then
		if UIArt.TileColors[color] then
			return color
		end
		color = Color3.fromHex(color)
	end
	local best, bd = "blue", math.huge
	for k, hex in UIArt.TileColors do
		local c = Color3.fromHex(hex)
		local d = (c.R - color.R) ^ 2 + (c.G - color.G) ^ 2 + (c.B - color.B) ^ 2
		if d < bd then
			best, bd = k, d
		end
	end
	return best
end

-- A tile / card with a colour glow rising from the bottom (Store, Locker, Quests, Coaches, Daily)
function UIKit.tile(props)
	local img = UIKit.sprite("tile_" .. UIKit.tileKey(props.Color or "blue"), props)
	img.Name = props.Name or "Tile"
	return img
end

function UIKit.setTileColor(tile, color)
	UIKit.applySprite(tile, "tile_" .. UIKit.tileKey(color))
end

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
-- The window panel sprite (navy, bright rim, thick outline, soft shadow). `Accent` adds a small
-- coloured strip on the left (toasts use it for their colour).
function UIKit.panel(props)
	local frame = UIKit.sprite("panel", {
		Name = props.Name or "Panel",
		Size = props.Size or UDim2.fromOffset(200, 100),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex or 1,
		ImageTransparency = if props.Transparency and props.Transparency > 0.2 then props.Transparency else 0,
		Parent = props.Parent,
	})
	if props.Accent == true or props.AccentColor then
		local accent = make("Frame", {
			Name = "Accent",
			BackgroundColor3 = props.AccentColor or Palette.ElectricBlue,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 5, 1, -22),
			Position = UDim2.fromOffset(9, 10),
			ZIndex = (props.ZIndex or 1) + 1,
			Parent = frame,
		})
		UIKit.corner(accent, 3)
	end
	return frame
end

-- Rounded navy pill (coins, race timer, counters); Kind = "navy" | "red" | "lime"
function UIKit.pill(props)
	local size = props.Size or UDim2.fromOffset(160, 40)
	return UIKit.sprite("pill_" .. (props.Kind or "navy"), {
		Name = props.Name or "Pill",
		Size = size,
		Height = size.Y.Offset > 0 and size.Y.Offset or 40,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
end

-- Progress bar: a track sprite + a fill sprite (blue or gold). Returns track, fill; set fill.Size scale X.
function UIKit.bar(props)
	local size = props.Size or UDim2.fromOffset(200, 12)
	local h = size.Y.Offset > 0 and size.Y.Offset or 12
	local track = UIKit.sprite("bar_track", { Name = props.Name or "Bar", Size = size, Height = h, Position = props.Position, AnchorPoint = props.AnchorPoint, ZIndex = props.ZIndex or 1, Parent = props.Parent })
	local fill = UIKit.sprite("bar_" .. (props.Kind or "blue"), { Name = "Fill", Size = UDim2.fromScale(0, 1), Height = h, ZIndex = (props.ZIndex or 1) + 1, Parent = track })
	return track, fill
end

----------------------------------------------------------------------------
-- Chunky button with a darker bottom edge and a press animation
----------------------------------------------------------------------------
UIKit.sweeps = {} -- (the coded buttons' shine sweeps; the art buttons have their own highlight)

-- the face of the art sprite: the label sits on it, and drops with it when pressed
local LABEL_UP, LABEL_DOWN = 0.42, 0.49

-- Props: Style, Text, TextSize, Icon (kit icon name, drawn on the left), Size, Position, ...
function UIKit.button(props)
	local styleName = props.Style or "Blue"
	local style = UIKit.ButtonStyles[styleName] or UIKit.ButtonStyles.Blue

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
	root:SetAttribute("Style", styleName)
	local scale = make("UIScale", { Parent = root })

	local face = UIKit.sprite(style.Sprite, { Name = "Face", Size = UDim2.fromScale(1, 1), ZIndex = root.ZIndex + 1, Parent = root })

	local icon
	local h = root.Size.Y.Offset > 0 and root.Size.Y.Offset or 48
	local hasText = props.Text ~= nil and props.Text ~= ""
	if props.Icon then
		local isz = if hasText then math.floor(h * 0.78) else math.floor(h * 0.6)
		icon = UIKit.icon(props.Icon, isz, face, {
			AnchorPoint = if hasText then Vector2.new(0, 0.5) else Vector2.new(0.5, 0.5),
			Position = if hasText then UDim2.new(0, 2, LABEL_UP, 0) else UDim2.fromScale(0.5, LABEL_UP),
			ZIndex = root.ZIndex + 2,
		})
	end
	local inset = if icon and hasText then math.floor(h * 0.78) else 0
	local label = UIKit.text({
		Name = "Label",
		Text = props.Text or "",
		TextSize = props.TextSize or 22,
		Color = style.Text,
		Font = props.Font or UIKit.Fonts.Display,
		Stroke = style.TextStroke ~= nil,
		StrokeColor = style.TextStroke,
		StrokeThickness = 2,
		StrokeTransparency = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -16 - inset, 0.7, 0),
		Position = UDim2.new(0, 8 + inset, LABEL_UP, 0),
		ZIndex = root.ZIndex + 3,
		Parent = face,
	})

	local function press(down)
		local st = UIKit.ButtonStyles[root:GetAttribute("Style")] or style
		UIKit.applySprite(face, st.Sprite .. (if down then "_down" else ""))
		local y = if down then LABEL_DOWN else LABEL_UP
		label.Position = UDim2.new(0, 8 + inset, y, 0)
		if icon then
			icon.Position = UDim2.new(icon.Position.X.Scale, icon.Position.X.Offset, y, 0)
		end
		if down then
			UIKit.tween(scale, 0.06, { Scale = 0.97 })
		else
			UIKit.tween(scale, 0.12, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	local isDown = false
	root.MouseButton1Down:Connect(function()
		isDown = true
		press(true)
	end)
	local function up()
		if isDown then
			isDown = false
			press(false)
		end
	end
	root.MouseButton1Up:Connect(up)
	root.MouseLeave:Connect(up)
	root.Activated:Connect(function()
		up()
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
	button:SetAttribute("Style", styleName)
	local face = button.Face
	UIKit.applySprite(face, style.Sprite)
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
	return UIKit.icon("coin", size, parent, { Name = "Coin" })
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

-- the speed bolt (HUD SPEED panel, race cards); `color` is ignored (the art is gold)
function UIKit.speedIcon(size, parent, _color)
	return UIKit.icon("speed", size, parent, { Name = "SpeedIcon" })
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
		BackgroundColor3 = Color3.fromHex("#060C22"),
		BackgroundTransparency = 0.42,
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
	UIKit.sprite("bar_gold", { Name = "Underline", Position = UDim2.fromOffset(2, 38), Size = UDim2.fromOffset(64, 8), ZIndex = 24, Parent = tab })
	local close = UIKit.button({
		Name = "Close",
		Style = "Red",
		Icon = "close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 14, 0, -18),
		Size = UDim2.fromOffset(54, 50),
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
