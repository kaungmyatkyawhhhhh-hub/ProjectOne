-- UIKitStarter (roblox-ui-pro skill): a small, complete UI kit for a game that has no kit yet.
-- Put it in ReplicatedStorage as a ModuleScript (e.g. ReplicatedStorage.UI.Kit), then change the TOKENS
-- block to the game's own art. If the game already has a kit, DON'T add this one: borrow the pieces you need.
-- Style: "kid simulator / chunky glossy" (ink outline, coloured face, darker base, shine line, press pop).
-- Everything respects GuiService.ReducedMotionEnabled, works with touch/mouse/gamepad, and cleans up after itself.

local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Kit = {}

---------------------------------------------------------------- TOKENS (change these per game)
Kit.Colors = {
	Ink = Color3.fromHex("0A1424"),          -- outlines and text strokes
	Surface = Color3.fromHex("12233F"),      -- panel plates
	SurfaceRaised = Color3.fromHex("1B3460"),-- tiles, rows
	Text = Color3.fromHex("F5FAFF"),
	TextMuted = Color3.fromHex("A9B8CC"),
	Primary = Color3.fromHex("3DDC84"),      -- the one main action (BUY / PLAY / CLAIM)
	Secondary = Color3.fromHex("3D8BFF"),
	Currency = Color3.fromHex("FFC93C"),
	Danger = Color3.fromHex("FF4D5E"),
	Locked = Color3.fromHex("8A97A8"),
	Backdrop = Color3.fromHex("050A14"),
}
Kit.Rarity = {
	Common = Color3.fromHex("B8C4D4"), Rare = Color3.fromHex("3D8BFF"), Epic = Color3.fromHex("B65CFF"),
	Legendary = Color3.fromHex("FFC93C"), Mythic = Color3.fromHex("FF5FA8"),
}
Kit.Font = Font.fromEnum(Enum.Font.FredokaOne)
Kit.Space = { XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32 }
Kit.TextSize = { Caption = 14, Body = 16, Button = 20, Counter = 24, Title = 28, Hero = 48 }
Kit.Radius = { S = 8, M = 12, L = 18 }
Kit.Outline = 3          -- plate / button outline
Kit.TextOutline = 2      -- text stroke
Kit.Depth = 4            -- chunky button base height
Kit.MinTouch = 44
Kit.Motion = { Hover = 0.1, Press = 0.07, Release = 0.15, Open = 0.22, Close = 0.14, Toast = 0.2, Tick = 0.6 }
-- Scale factors are relative to the element's normal size (a UIScale), so they look the same on phone and TV.
-- Calm: 1.05 / 0.95. Juicy kid-sim feel (Develuper's numbers): Hover = 1.1, Press = 0.92.
Kit.Scale = { Hover = 1.05, Press = 0.95 }
Kit.TextDepth = 3        -- px of the darker copy under display text ("depth" text); 0 = off
Kit.EdgeHighlight = 0.65 -- transparency of the thin light line just inside plates and buttons; 1 = off

---------------------------------------------------------------- helpers
local function new(className: string, props: { [string]: any }?, parent: Instance?): any
	local o = Instance.new(className)
	if props then
		for k, v in props do
			(o :: any)[k] = v
		end
	end
	if parent then o.Parent = parent end
	return o
end
Kit.new = new

function Kit.reducedMotion(): boolean
	local ok, v = pcall(function() return GuiService.ReducedMotionEnabled end)
	return ok and v == true
end

function Kit.usesGamepadFocus(): boolean
	local p = UserInputService.PreferredInput
	return p == Enum.PreferredInput.Gamepad or p == Enum.PreferredInput.MicroGamepad
end

function Kit.tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

function Kit.darker(c: Color3, f: number?): Color3
	local k = f or 0.62
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

function Kit.corner(o: Instance, r: number)
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

function Kit.stroke(o: Instance, color: Color3, thickness: number, mode: Enum.ApplyStrokeMode?)
	return new("UIStroke", {
		Color = color, Thickness = thickness, LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
	}, o)
end

-- 1.2K, 3.4M ... the same everywhere
function Kit.abbrev(n: number): string
	local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	local v = math.abs(n)
	while v >= 1000 and i < #units do
		v /= 1000
		i += 1
	end
	if i == 1 then return tostring(math.floor(n)) end
	local s = if v < 10 then string.format("%.2f", v) elseif v < 100 then string.format("%.1f", v) else string.format("%d", math.floor(v))
	s = s:gsub("%.?0+$", "")
	return (if n < 0 then "-" else "") .. s .. units[i]
end

-- A cleanup bin: everything a screen creates or connects goes in here; :clean() undoes it all.
function Kit.bin()
	local items = {}
	local b = {}
	function b:add(x: any): any
		table.insert(items, x)
		return x
	end
	function b:clean()
		for i = #items, 1, -1 do
			local x = items[i]
			if typeof(x) == "RBXScriptConnection" then
				x:Disconnect()
			elseif typeof(x) == "Instance" then
				if x:IsA("Tween") then x:Cancel() end
				x:Destroy()
			elseif type(x) == "function" then
				x()
			end
		end
		table.clear(items)
	end
	return b
end

---------------------------------------------------------------- containers
-- One ScreenGui per screen. Safe defaults: survives respawn, sibling z-order, stays clear of topbar/notch.
function Kit.screen(name: string, displayOrder: number?, parent: Instance?): ScreenGui
	return new("ScreenGui", {
		Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder or 15, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		IgnoreGuiInset = false,
	}, parent)
end

-- props are TextLabel properties, plus one extra key: depth (px). depth > 0 gives "depth text":
-- a darker copy sits under the text, like a 3D button. Use it on display text (titles, button labels,
-- big numbers), not on small body text.
function Kit.label(parent: Instance, text: string, size: number?, props: { [string]: any }?): TextLabel
	local l = new("TextLabel", {
		Name = "Label", BackgroundTransparency = 1, FontFace = Kit.Font, Text = text,
		TextSize = math.max(size or Kit.TextSize.Body, Kit.TextSize.Caption), TextColor3 = Kit.Colors.Text,
		Size = UDim2.fromScale(1, 1),
	}, parent)
	local depth = 0
	if props then
		for k, v in props do
			if k == "depth" then depth = v else (l :: any)[k] = v end
		end
	end
	Kit.stroke(l, Kit.Colors.Ink, Kit.TextOutline, Enum.ApplyStrokeMode.Contextual)
	if depth > 0 then Kit.depthText(l, depth) end
	return l
end

-- Turns a label into depth text. In Sibling z-order a child always draws over its parent, so the
-- label itself becomes the dark copy and a child "Face" draws the real text `depth` px higher.
-- Code can keep setting label.Text / TextColor3 / TextTransparency as usual: they're forwarded to
-- the face, and the label's own colour is kept as the darker shade. The copy is tagged UIDecor so
-- ui_audit.luau doesn't report it as low-contrast text.
function Kit.depthText(l: TextLabel, depth: number)
	l:SetAttribute("UIDecor", true)
	local face = new("TextLabel", {
		Name = "Face", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, -depth),
		ZIndex = l.ZIndex,
	}, l)
	Kit.stroke(face, Kit.Colors.Ink, Kit.TextOutline, Enum.ApplyStrokeMode.Contextual)
	local mirrored = { "Text", "TextSize", "FontFace", "TextXAlignment", "TextYAlignment", "TextScaled", "TextWrapped",
		"TextTruncate", "TextTransparency", "RichText", "LineHeight" }
	for _, p in mirrored do
		(face :: any)[p] = (l :: any)[p]
		l:GetPropertyChangedSignal(p):Connect(function() (face :: any)[p] = (l :: any)[p] end)
	end
	local shade: Color3
	local function recolour()
		if shade and l.TextColor3 == shade then return end -- our own write below
		face.TextColor3 = l.TextColor3
		shade = l.TextColor3:Lerp(Kit.Colors.Ink, 0.55)
		l.TextColor3 = shade
	end
	recolour()
	l:GetPropertyChangedSignal("TextColor3"):Connect(recolour)
	l:GetPropertyChangedSignal("ZIndex"):Connect(function() face.ZIndex = l.ZIndex end)
	return face
end

-- depth for a text size: 16 -> 2, 20 -> 3, 28 -> 4, 48 -> 6. 0 when Kit.TextDepth is 0.
function Kit.depthFor(size: number): number
	if Kit.TextDepth <= 0 or size < 16 then return 0 end
	return math.clamp(math.floor(size / 8 + 0.5), 1, Kit.TextDepth + 3)
end

-- A thin light line just inside the edge of `o` (Develuper's "edge highlighting"). Cheap, and it makes
-- flat plates read as glossy. The line sits on an inset frame so the stroke lands inside the shape.
function Kit.edgeHighlight(o: GuiObject, radius: number, transparency: number?)
	local t = transparency or Kit.EdgeHighlight
	if t >= 1 then return nil end
	local inset = 2
	local edge = new("Frame", {
		Name = "EdgeHighlight", BackgroundTransparency = 1, Active = false,
		Position = UDim2.fromOffset(inset, inset), Size = UDim2.new(1, -inset * 2, 1, -inset * 2), ZIndex = o.ZIndex + 1,
	}, o)
	Kit.corner(edge, math.max(radius - inset, 2))
	new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = t, Thickness = 1.5, LineJoinMode = Enum.LineJoinMode.Round }, edge)
	return edge
end

-- Ink shell -> face (subtle top-to-bottom shading) -> optional coloured edge -> shine line.
-- Returns shell, face. Put content inside `face`.
function Kit.plate(parent: Instance, opts: { [string]: any }): (Frame, Frame)
	local r = opts.radius or Kit.Radius.L
	local shell = new("Frame", {
		Name = opts.name or "Plate", Size = opts.size or UDim2.fromScale(1, 1),
		Position = opts.position or UDim2.new(), AnchorPoint = opts.anchor or Vector2.zero,
		BackgroundColor3 = Kit.Colors.Ink, BorderSizePixel = 0, ZIndex = opts.zIndex or 1,
	}, parent)
	Kit.corner(shell, r)
	local face = new("Frame", {
		Name = "Face", Size = UDim2.new(1, -Kit.Outline * 2, 1, -Kit.Outline * 2),
		Position = UDim2.fromOffset(Kit.Outline, Kit.Outline),
		BackgroundColor3 = opts.fill or Kit.Colors.Surface, BorderSizePixel = 0,
	}, shell)
	Kit.corner(face, math.max(r - Kit.Outline, 2))
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 220)) }, face)
	if opts.edge then Kit.stroke(face, opts.edge, 2) end
	if opts.shine ~= false then
		local shine = new("Frame", {
			Name = "Shine", Size = UDim2.new(1, -r * 2, 0, 4), Position = UDim2.fromOffset(r, 4),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 2,
		}, face)
		Kit.corner(shine, 2)
	end
	if opts.highlight ~= false then Kit.edgeHighlight(face, math.max(r - Kit.Outline, 2)) end
	return shell, face
end

---------------------------------------------------------------- button
-- opts: text, role ("Primary"|"Secondary"|"Currency"|"Danger"|"Locked"), size, position, anchor,
--       textSize, name, layoutOrder, onActivated(), icon (asset id, optional)
-- returns api: Instance (holder), Hit (TextButton, for gamepad selection), SetEnabled(on, reasonText?),
--              SetRole(role), SetText(text), Destroy()
function Kit.button(parent: Instance, opts: { [string]: any })
	local bin = Kit.bin()
	local role = opts.role or "Primary"
	local holder = new("Frame", {
		Name = opts.name or "Button", BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(160, 56), Position = opts.position or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero, LayoutOrder = opts.layoutOrder or 0,
	}, parent)
	-- the tappable face is the holder minus the chunky base, so the holder needs MinTouch + Depth of height
	new("UISizeConstraint", { MinSize = Vector2.new(Kit.MinTouch, Kit.MinTouch + Kit.Depth) }, holder)
	local scale = new("UIScale", {}, holder)
	local base = new("Frame", {
		Name = "Base", BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -Kit.Depth),
		Position = UDim2.fromOffset(0, Kit.Depth),
	}, holder)
	Kit.corner(base, Kit.Radius.M)
	Kit.stroke(base, Kit.Colors.Ink, Kit.Outline)
	local hit = new("TextButton", {
		Name = "Hit", AutoButtonColor = false, Text = "", BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -Kit.Depth), ZIndex = 2,
	}, holder)
	Kit.corner(hit, Kit.Radius.M)
	Kit.stroke(hit, Kit.Colors.Ink, Kit.Outline)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(215, 220, 225)) }, hit)
	local shine = new("Frame", {
		Name = "Shine", Size = UDim2.new(1, -Kit.Radius.M * 2, 0, 3), Position = UDim2.fromOffset(Kit.Radius.M, 4),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 3,
	}, hit)
	Kit.corner(shine, 2)
	Kit.edgeHighlight(hit, Kit.Radius.M)
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, hit)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, Kit.Space.S), SortOrder = Enum.SortOrder.LayoutOrder,
	}, content)
	if opts.icon then
		local icon = new("ImageLabel", {
			Name = "Icon", BackgroundTransparency = 1, Image = opts.icon, ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(0.62, 0.62), LayoutOrder = 1, ZIndex = 3,
		}, content)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, icon)
	end
	local labelSize = opts.textSize or Kit.TextSize.Button
	local label = Kit.label(content, opts.text or "", labelSize, {
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, ZIndex = 3,
		depth = Kit.depthFor(labelSize),
	})
	if (opts.text or "") == "" then label.Visible = false end

	local enabled = true
	local api = { Instance = holder, Hit = hit, Label = label }
	local function paint()
		local c = if enabled then (Kit.Colors[role] or Kit.Colors.Primary) else Kit.Colors.Locked
		hit.BackgroundColor3 = c
		base.BackgroundColor3 = Kit.darker(c, 0.55)
		label.TextTransparency = if enabled then 0 else 0.15
	end
	paint()

	local function to(s: number, t: number, style: Enum.EasingStyle?)
		if Kit.reducedMotion() then scale.Scale = 1 return end
		bin:add(Kit.tween(scale, t, { Scale = s }, style))
	end
	local function pressDown()
		hit.Position = UDim2.fromOffset(0, Kit.Depth - 1)
		to(Kit.Scale.Press, Kit.Motion.Press)
	end
	local function release()
		hit.Position = UDim2.fromOffset(0, 0)
		to(1, Kit.Motion.Release, Enum.EasingStyle.Back)
	end
	bin:add(hit.MouseEnter:Connect(function()
		if enabled and UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then to(Kit.Scale.Hover, Kit.Motion.Hover) end
	end))
	bin:add(hit.MouseLeave:Connect(function() release() end))
	bin:add(hit.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if enabled and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then pressDown() end
	end))
	bin:add(hit.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then release() end
	end))
	bin:add(hit.Activated:Connect(function()
		if not enabled then return end
		if UserInputService.PreferredInput ~= Enum.PreferredInput.Touch and UserInputService.PreferredInput ~= Enum.PreferredInput.KeyboardAndMouse then
			pressDown()
			task.delay(Kit.Motion.Press, release)
		end
		if opts.onActivated then task.spawn(opts.onActivated) end
	end))

	function api.SetEnabled(on: boolean, reasonText: string?)
		enabled = on
		hit.Interactable = on
		if reasonText then label.Text = reasonText; label.Visible = true end
		paint()
	end
	function api.SetRole(r: string)
		role = r
		paint()
	end
	function api.SetText(t: string)
		label.Text = t
		label.Visible = t ~= ""
	end
	function api.Destroy()
		bin:clean()
		holder:Destroy()
	end
	return api
end

---------------------------------------------------------------- counter (HUD currency etc.)
-- opts: icon, value, color, size, position, anchor, name. api.Set(value, animate?)
function Kit.counter(parent: Instance, opts: { [string]: any })
	local shell, face = Kit.plate(parent, {
		name = opts.name or "Counter", size = opts.size or UDim2.fromOffset(150, 48), position = opts.position,
		anchor = opts.anchor, radius = Kit.Radius.M, edge = opts.color,
	})
	local scale = new("UIScale", {}, shell)
	if opts.icon then
		local icon = new("ImageLabel", {
			Name = "Icon", BackgroundTransparency = 1, Image = opts.icon, ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(46, 46), ZIndex = 4,
		}, shell)
		new("UIAspectRatioConstraint", { AspectRatio = 1 }, icon)
	end
	local number = Kit.label(face, Kit.abbrev(opts.value or 0), Kit.TextSize.Counter, {
		Name = "Value", TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = opts.color or Kit.Colors.Text,
		Position = UDim2.fromOffset(opts.icon and 26 or 8, 0), Size = UDim2.new(1, (opts.icon and -26 or -8) - Kit.Space.S, 1, 0), ZIndex = 3,
		depth = Kit.depthFor(Kit.TextSize.Counter),
	})
	local holder = new("NumberValue", { Value = opts.value or 0 })
	holder.Changed:Connect(function(v) number.Text = Kit.abbrev(v) end)
	local current: Tween? = nil
	local api = { Instance = shell }
	function api.Set(v: number, animate: boolean?)
		if current then current:Cancel() end
		local up = v > holder.Value
		if animate == false or Kit.reducedMotion() then
			holder.Value = v
			return
		end
		local t = math.clamp(Kit.Motion.Tick * (1 + math.log10(1 + math.abs(v - holder.Value)) / 6), 0.3, 1.2)
		current = Kit.tween(holder, t, { Value = v })
		if up then
			scale.Scale = 1.12
			Kit.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	return api
end

---------------------------------------------------------------- responsive grid inside a ScrollingFrame
-- opts: minCell (px), maxCell, gap, aspect (height/width), padding. Returns the ScrollingFrame and UIGridLayout.
function Kit.grid(parent: Instance, opts: { [string]: any })
	local gap = opts.gap or Kit.Space.S
	local pad = opts.padding or Kit.Space.S
	local sf = new("ScrollingFrame", {
		Name = opts.name or "Grid", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = opts.size or UDim2.fromScale(1, 1), Position = opts.position or UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6, ScrollBarImageColor3 = Kit.Colors.TextMuted, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Selectable = false,
	}, parent)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad),
		PaddingTop = UDim.new(0, pad), PaddingBottom = UDim.new(0, pad + Kit.Space.M),
	}, sf)
	local grid = new("UIGridLayout", {
		CellPadding = UDim2.fromOffset(gap, gap), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sf)
	local minCell, maxCell, aspect = opts.minCell or 96, opts.maxCell or 132, opts.aspect or 1.2
	local function apply()
		local w = sf.AbsoluteSize.X - pad * 2 - sf.ScrollBarThickness
		if w <= 0 then return end
		local cols = math.max(1, math.floor((w + gap) / (minCell + gap)))
		local cell = math.min(maxCell, math.floor((w - gap * (cols - 1)) / cols))
		grid.CellSize = UDim2.fromOffset(cell, math.floor(cell * aspect))
	end
	sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
	task.defer(apply)
	return sf, grid
end

-- A shop/index tile: plate + rarity edge + icon + name + price/state line + full-size hit button.
-- opts: name, icon, rarity, price (number), state ("buy"|"owned"|"equipped"|"locked"), onActivated, layoutOrder
function Kit.tile(parent: Instance, opts: { [string]: any })
	local rarity = Kit.Rarity[opts.rarity or "Common"] or Kit.Rarity.Common
	local shell, face = Kit.plate(parent, {
		name = opts.id or opts.name or "Tile", radius = Kit.Radius.M, fill = Kit.Colors.SurfaceRaised, edge = rarity,
	})
	shell.LayoutOrder = opts.layoutOrder or 0
	if opts.icon then
		new("ImageLabel", {
			Name = "Icon", BackgroundTransparency = 1, Image = opts.icon, ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, Kit.Space.S), Size = UDim2.new(0.8, 0, 0.5, 0), ZIndex = 3,
		}, face)
	end
	Kit.label(face, opts.name or "", Kit.TextSize.Caption, {
		Name = "Title", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.new(1, -8, 0, 18),
		TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3,
	})
	local state = opts.state or "buy"
	local text, color = "", Kit.Colors.Text
	if state == "buy" then text, color = Kit.abbrev(opts.price or 0), Kit.Colors.Currency
	elseif state == "owned" then text, color = "OWNED", Kit.Colors.TextMuted
	elseif state == "equipped" then text, color = "EQUIPPED", Kit.Colors.Primary
	elseif state == "locked" then text, color = "LOCKED", Kit.Colors.Locked end
	Kit.label(face, text, Kit.TextSize.Body, {
		Name = "Price", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -8, 0, 22),
		TextColor3 = color, ZIndex = 3,
	})
	local hit = new("TextButton", {
		Name = "Hit", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5,
	}, shell)
	local scale = new("UIScale", {}, shell)
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not Kit.reducedMotion() then Kit.tween(scale, Kit.Motion.Press, { Scale = Kit.Scale.Press }) end
		end
	end)
	hit.InputEnded:Connect(function()
		if not Kit.reducedMotion() then Kit.tween(scale, Kit.Motion.Release, { Scale = 1 }, Enum.EasingStyle.Back) end
	end)
	if opts.onActivated then hit.Activated:Connect(opts.onActivated) end
	return shell, hit
end

---------------------------------------------------------------- tabs (equal-width, flex)
-- returns api: Instance, Select(name), buttons[name]
function Kit.tabs(parent: Instance, names: { string }, onSelect: (string) -> (), opts: { [string]: any }?)
	opts = opts or {}
	local bar = new("Frame", {
		Name = "Tabs", BackgroundTransparency = 1, Size = opts.size or UDim2.new(1, 0, 0, Kit.MinTouch + Kit.Depth),
		Position = opts.position or UDim2.new(),
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalFlex = Enum.UIFlexAlignment.Fill,
		Padding = UDim.new(0, Kit.Space.S), SortOrder = Enum.SortOrder.LayoutOrder,
	}, bar)
	local api = { Instance = bar, buttons = {} }
	function api.Select(name: string)
		for n, b in api.buttons do b.SetRole(if n == name then "Primary" else "Secondary") end
		onSelect(name)
	end
	for i, n in names do
		api.buttons[n] = Kit.button(bar, {
			name = n, text = n, role = "Secondary", textSize = Kit.TextSize.Body, layoutOrder = i,
			size = UDim2.new(0, 60, 1, 0), onActivated = function() api.Select(n) end,
		})
	end
	return api
end

---------------------------------------------------------------- modal panel
-- opts: name, title, size (UDim2), maxSize (Vector2), firstSelection (function returning a GuiObject), onClose(),
--       transition ("pop" = scale 0.85 -> 1 with Back, the default; "slide" = rises 40 px while fading in, Quint 0.35 s,
--       Develuper's "fade slide", calmer for big panels), tapOutsideCloses (default true)
-- returns api: Root, Content (put your stuff here), Open(), Close(), IsOpen, Destroy()
local modalCount = 0
function Kit.modal(screenGui: ScreenGui, opts: { [string]: any })
	modalCount += 1
	local actionName = "KitModalClose" .. modalCount
	local backdrop = new("TextButton", {
		Name = "Backdrop", Text = "", AutoButtonColor = false, Selectable = false, BorderSizePixel = 0,
		BackgroundColor3 = Kit.Colors.Backdrop, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1,
	}, screenGui)
	local group = new("CanvasGroup", {
		Name = opts.name or "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = opts.size or UDim2.fromScale(0.94, 0.9), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false, ZIndex = 2,
		SelectionGroup = true, SelectionBehaviorUp = Enum.SelectionBehavior.Stop, SelectionBehaviorDown = Enum.SelectionBehavior.Stop,
		SelectionBehaviorLeft = Enum.SelectionBehavior.Stop, SelectionBehaviorRight = Enum.SelectionBehavior.Stop,
	}, screenGui)
	new("UISizeConstraint", { MaxSize = opts.maxSize or Vector2.new(860, 560) }, group)
	local scale = new("UIScale", {}, group)
	local _, face = Kit.plate(group, { name = "Plate" })
	local headerH = 44
	local title = Kit.label(face, opts.title or "", Kit.TextSize.Title, {
		Name = "Title", TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(Kit.Space.L, Kit.Space.S),
		Size = UDim2.new(1, -(Kit.Space.L * 2 + 52), 0, headerH), ZIndex = 3, depth = Kit.depthFor(Kit.TextSize.Title),
	})
	local api = { Root = group, Title = title, IsOpen = false }
	local close = Kit.button(face, {
		name = "Close", text = "X", role = "Danger", textSize = Kit.TextSize.Button,
		size = UDim2.fromOffset(48, 48), anchor = Vector2.new(1, 0), position = UDim2.new(1, -Kit.Space.S, 0, Kit.Space.S - 2),
		onActivated = function() api.Close() end,
	})
	api.CloseButton = close
	local content = new("Frame", {
		Name = "Content", BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Kit.Space.M, headerH + Kit.Space.M),
		Size = UDim2.new(1, -Kit.Space.M * 2, 1, -(headerH + Kit.Space.M * 2)),
	}, face)
	api.Content = content

	local slide = opts.transition == "slide"
	local home = group.Position
	local slideOffset = UDim2.fromOffset(0, 40)
	local running: { Tween } = {}
	local function stop()
		for _, t in running do t:Cancel() end
		table.clear(running)
	end
	local prevSelected: GuiObject? = nil

	function api.Open()
		if api.IsOpen then return end
		api.IsOpen = true
		stop()
		prevSelected = GuiService.SelectedObject
		local wasVisible = group.Visible -- re-opened mid-close: continue from where it is, don't jump
		backdrop.Visible = true
		group.Visible = true
		if Kit.reducedMotion() then
			scale.Scale, group.GroupTransparency, backdrop.BackgroundTransparency = 1, 0, 0.45
			group.Position = home
		elseif slide then
			scale.Scale = 1
			if not wasVisible then group.Position, group.GroupTransparency = home + slideOffset, 1 end
			table.insert(running, Kit.tween(group, 0.35, { Position = home, GroupTransparency = 0 }, Enum.EasingStyle.Quint))
			table.insert(running, Kit.tween(backdrop, 0.35, { BackgroundTransparency = 0.45 }))
		else
			if not wasVisible then scale.Scale, group.GroupTransparency = 0.85, 1 end
			table.insert(running, Kit.tween(scale, Kit.Motion.Open, { Scale = 1 }, Enum.EasingStyle.Back))
			table.insert(running, Kit.tween(group, Kit.Motion.Open * 0.8, { GroupTransparency = 0 }))
			table.insert(running, Kit.tween(backdrop, Kit.Motion.Open, { BackgroundTransparency = 0.45 }))
		end
		-- B on gamepad closes. (Escape belongs to the Roblox menu, so we don't bind it.)
		ContextActionService:BindAction(actionName, function(_, state)
			if state == Enum.UserInputState.Begin then api.Close() end
			return Enum.ContextActionResult.Sink
		end, false, Enum.KeyCode.ButtonB)
		task.spawn(function()
			RunService.RenderStepped:Wait()
			if api.IsOpen and Kit.usesGamepadFocus() then
				GuiService.SelectedObject = (opts.firstSelection and opts.firstSelection()) or close.Hit
			end
		end)
	end

	function api.Close()
		if not api.IsOpen then return end
		api.IsOpen = false
		stop()
		ContextActionService:UnbindAction(actionName)
		local sel = GuiService.SelectedObject
		if sel and sel:IsDescendantOf(group) then
			GuiService.SelectedObject = if prevSelected and prevSelected:IsDescendantOf(game) then prevSelected else nil
		end
		if Kit.reducedMotion() then
			group.Visible, backdrop.Visible = false, false
		else
			local t
			if slide then
				t = Kit.tween(group, 0.2, { Position = home + slideOffset, GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			else
				t = Kit.tween(group, Kit.Motion.Close, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				table.insert(running, Kit.tween(scale, Kit.Motion.Close, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
			end
			table.insert(running, t)
			table.insert(running, Kit.tween(backdrop, Kit.Motion.Close, { BackgroundTransparency = 1 }))
			t.Completed:Once(function(state)
				-- only hide if this close finished; a re-open cancels it and keeps the panel visible
				if state == Enum.PlaybackState.Completed and not api.IsOpen then
					group.Visible, backdrop.Visible = false, false
				end
			end)
		end
		if opts.onClose then task.spawn(opts.onClose) end
	end

	if opts.tapOutsideCloses ~= false then
		backdrop.Activated:Connect(function() api.Close() end)
	end

	function api.Destroy()
		stop()
		pcall(function() ContextActionService:UnbindAction(actionName) end)
		close.Destroy()
		group:Destroy()
		backdrop:Destroy()
	end
	return api
end

---------------------------------------------------------------- toast queue (one message at a time)
-- Stops popups from stacking: one toast on screen, higher priority first, duplicates within 1.5 s dropped,
-- at most `maxQueued` waiting (lowest priority dropped). push(text, {priority=0..10, hold=seconds, color=Color3})
function Kit.toasts(screenGui: ScreenGui, opts: { [string]: any }?)
	opts = opts or {}
	local maxQueued = opts.maxQueued or 4
	local queue = {}
	local showing = false
	local lastText, lastTime = "", 0
	local seq = 0
	local q = {}
	local function showNext()
		if showing or #queue == 0 then return end
		table.sort(queue, function(a, b)
			if a.priority ~= b.priority then return a.priority > b.priority end
			return a.seq < b.seq
		end)
		local item = table.remove(queue, 1)
		showing = true
		local shell, face = Kit.plate(screenGui, {
			name = "Toast", size = UDim2.new(0.6, 0, 0, 52), anchor = Vector2.new(0.5, 0),
			position = UDim2.new(0.5, 0, 0, -60), radius = Kit.Radius.M, edge = item.color, zIndex = 10,
		})
		new("UISizeConstraint", { MinSize = Vector2.new(240, 52), MaxSize = Vector2.new(440, 52) }, shell)
		Kit.label(face, item.text, Kit.TextSize.Button, {
			TextColor3 = item.color or Kit.Colors.Text, ZIndex = 3, TextTruncate = Enum.TextTruncate.AtEnd,
			depth = Kit.depthFor(Kit.TextSize.Button),
		})
		local y = opts.top or Kit.Space.M
		if Kit.reducedMotion() then
			shell.Position = UDim2.new(0.5, 0, 0, y)
		else
			Kit.tween(shell, Kit.Motion.Toast, { Position = UDim2.new(0.5, 0, 0, y) }, Enum.EasingStyle.Back)
		end
		task.delay(item.hold, function()
			local function done()
				shell:Destroy()
				showing = false
				showNext()
			end
			if Kit.reducedMotion() then done() return end
			Kit.tween(shell, Kit.Motion.Toast, { Position = UDim2.new(0.5, 0, 0, -60) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				.Completed:Once(done)
		end)
	end
	function q.push(text: string, o: { [string]: any }?)
		o = o or {}
		local now = os.clock()
		if text == lastText and now - lastTime < 1.5 then return end
		lastText, lastTime = text, now
		seq += 1
		table.insert(queue, { text = text, priority = o.priority or 0, hold = o.hold or 2.4, color = o.color, seq = seq })
		if #queue > maxQueued then
			table.sort(queue, function(a, b) return a.priority > b.priority end)
			table.remove(queue)
		end
		showNext()
	end
	return q
end

return Kit
