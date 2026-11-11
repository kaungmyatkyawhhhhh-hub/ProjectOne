-- MEGA BITE UIKit: the ONE UI kit (art style guide section 6). Palette tokens + the 3 families: COUNTER, BUTTON, TILE.
-- House style: navy plate + thick ink outline + a coloured edge + a shine line. FredokaOne for everything.
local K = {}
local function hex(h) return Color3.fromHex(h) end
K.Colors = {
	Navy = hex("12233F"), Ink = hex("0A1424"), Turquoise = hex("2EC4D6"), Kelp = hex("3DDC84"),
	Gold = hex("FFC93C"), Coral = hex("FF6F61"), Danger = hex("FF4D5E"), Locked = hex("8A97A8"),
	Foam = hex("F5FAFF"), Blue = hex("3D8BFF"), Cyan = hex("5FF3FF"),
	NavyLight = hex("1B3460"),
}
K.Font = Enum.Font.FredokaOne
K.Outline = 3
K.Icons = {   -- our own ChatGPT icon sheet (MEGA BITE/UI/icons), group 33151111
	Size = "rbxassetid://95887839246654", Exp = "rbxassetid://103817562812853", Carry = "rbxassetid://98288386542647", Dart = "rbxassetid://93646244318779", Frenzy = "rbxassetid://121738459641180", Torpedo = "rbxassetid://132373164400986", Sense = "rbxassetid://130012192441199", Ram = "rbxassetid://129195683437390", Breach = "rbxassetid://124841181652402", Roar = "rbxassetid://110612895195097", Quest = "rbxassetid://86368454820402", Store = "rbxassetid://123194289459019", Vent = "rbxassetid://125941276679270", Index = "rbxassetid://125449104848178", Lock = "rbxassetid://119860308577741", Crown = "rbxassetid://71225619206466"
}
K.AbilityIcon = {DART = "Dart", FRENZY = "Frenzy", TORPEDO = "Torpedo", ["SHARK SENSE"] = "Sense", ["HAMMER RAM"] = "Ram", BREACH = "Breach", ["TIDAL ROAR"] = "Roar"}

function K.darker(c, f) f = f or 0.62; return Color3.new(c.R * f, c.G * f, c.B * f) end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
K.new = new
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, color, th, mode)
	return new("UIStroke", {Color = color, Thickness = th, ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round}, o)
end
K.corner, K.stroke = corner, stroke

function K.Text(parent, props)
	local t = new("TextLabel", {BackgroundTransparency = 1, Font = K.Font, TextColor3 = K.Colors.Foam, TextScaled = false,
		TextSize = 18, Text = "", Size = UDim2.fromScale(1, 1)}, parent)
	for k, v in pairs(props or {}) do if k ~= "InkThickness" then t[k] = v end end
	stroke(t, K.Colors.Ink, props and props.InkThickness or 2, Enum.ApplyStrokeMode.Contextual)
	return t
end

-- ink shell -> navy (or face colour) plate with a coloured edge -> shine line
function K.Plate(parent, size, pos, opts)
	opts = opts or {}
	local r = opts.radius or 14
	local shell = new("Frame", {Name = opts.name or "Plate", Size = size, Position = pos or UDim2.new(), AnchorPoint = opts.anchor or Vector2.zero,
		BackgroundColor3 = K.Colors.Ink, BorderSizePixel = 0}, parent)
	corner(shell, r)
	local face = new("Frame", {Name = "Face", Size = UDim2.new(1, -K.Outline * 2, 1, -K.Outline * 2), Position = UDim2.fromOffset(K.Outline, K.Outline),
		BackgroundColor3 = opts.fill or K.Colors.Navy, BorderSizePixel = 0}, shell)
	corner(face, r - 2)
	if opts.edge then stroke(face, opts.edge, 2) end
	local shine = new("Frame", {Name = "Shine", Size = UDim2.new(1, -14, 0, 4), Position = UDim2.fromOffset(7, 4),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = opts.shineT or 0.72, BorderSizePixel = 0, ZIndex = 3}, face)
	corner(shine, 2)
	return shell, face
end

function K.Icon(parent, name, size, pos, anchor)
	local img = new("ImageLabel", {Name = "Icon", BackgroundTransparency = 1, Image = K.Icons[name] or "", Size = size, Position = pos,
		AnchorPoint = anchor or Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 5}, parent)
	return img
end

-- COUNTER: navy plate + an icon that pokes out on the left + a small label + a BIG number
function K.Counter(parent, opts)
	local accent = K.Colors[opts.accent or "Turquoise"]
	local w, h = opts.width or 160, opts.height or 52
	local shell, face = K.Plate(parent, UDim2.fromOffset(w, h), opts.pos, {name = opts.name, edge = accent, anchor = opts.anchor})
	local icon = K.Icon(shell, opts.icon, UDim2.fromOffset(h + 12, h + 12), UDim2.new(0, 6, 0.5, 0))
	local label = K.Text(face, {Name = "Label", Text = opts.label or "", TextSize = 17, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -(h + 10), 0, 17), Position = UDim2.fromOffset(h + 2, 2), InkThickness = 1.5})
	local value = K.Text(face, {Name = "Value", Text = opts.value or "0", TextSize = 29, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -(h + 10), 0, 30), Position = UDim2.new(0, h + 2, 1, -31), InkThickness = 2.5})
	return {root = shell, face = face, icon = icon, label = label, value = value}
end

-- BUTTON: chunky face in the meaning colour on a darker lip, ink outline, big icon, heavy text + a state line
function K.Button(parent, opts)
	local col = K.Colors[opts.color or "Turquoise"]
	local w, h = opts.width or 96, opts.height or 64
	local lip = 6
	local holder = new("TextButton", {Name = opts.name or "Button", Size = UDim2.fromOffset(w, h + lip), Position = opts.pos or UDim2.new(),
		AnchorPoint = opts.anchor or Vector2.zero, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Active = true}, parent)
	local base = new("Frame", {Name = "Lip", Size = UDim2.new(1, 0, 1, -lip), Position = UDim2.fromOffset(0, lip), BackgroundColor3 = K.Colors.Ink, BorderSizePixel = 0}, holder)
	corner(base, opts.radius or 16)
	new("Frame", {Name = "LipFace", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = K.darker(col), BorderSizePixel = 0}, base)
	corner(base.LipFace, (opts.radius or 16) - 2)
	local top = new("Frame", {Name = "Top", Size = UDim2.new(1, 0, 1, -lip), BackgroundTransparency = 1}, holder)
	local shell, face = K.Plate(top, UDim2.fromScale(1, 1), UDim2.new(), {fill = col, radius = opts.radius or 16, shineT = 0.45})
	local grad = new("UIGradient", {Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.82, 0.82, 0.82))}, face)
	local icon = K.Icon(face, opts.icon, UDim2.fromScale((opts.iconScale or 0.62) * (opts.state and 0.88 or 1), (opts.iconScale or 0.62) * (opts.state and 0.88 or 1)), UDim2.fromScale(0.5, opts.state and 0.34 or (opts.text and 0.4 or 0.5)))
	local text = K.Text(face, {Name = "Label", Text = opts.text or "", TextSize = opts.textSize or 17, Size = UDim2.new(1, -6, 0, 20),
		Position = UDim2.new(0, 3, 1, -(opts.state and 39 or 23)), InkThickness = 2.5})
	local state = K.Text(face, {Name = "State", Text = opts.state or "", TextSize = 17, Size = UDim2.new(1, -6, 0, 17), Position = UDim2.new(0, 3, 1, -20),
		TextColor3 = K.Colors.Foam, InkThickness = 1.5, Visible = opts.state ~= nil})
	-- cooldown veil (fills from the top, drains down)
	local veil = new("Frame", {Name = "Cooldown", BackgroundColor3 = K.Colors.Ink, BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 6}, face)
	corner(veil, (opts.radius or 16) - 2)
	-- press feel: the top drops onto the lip
	local TS = game:GetService("TweenService")
	local function press(down)
		TS:Create(top, TweenInfo.new(0.06), {Position = UDim2.fromOffset(0, down and lip - 1 or 0)}):Play()
	end
	holder.MouseButton1Down:Connect(function() press(true) end)
	holder.MouseButton1Up:Connect(function() press(false) end)
	holder.MouseLeave:Connect(function() press(false) end)
	local obj = {root = holder, face = face, shell = shell, icon = icon, label = text, state = state, veil = veil, lipFace = base.LipFace, color = col}
	function obj:SetColor(c) face.BackgroundColor3 = c; base.LipFace.BackgroundColor3 = K.darker(c) end
	return obj
end

-- TILE: rounded square icon tile with a label or number
function K.Tile(parent, opts)
	local accent = K.Colors[opts.accent or "Turquoise"]
	local s = opts.size or 64
	local shell, face = K.Plate(parent, UDim2.fromOffset(s, s), opts.pos, {name = opts.name, edge = accent, radius = opts.radius or 18, anchor = opts.anchor})
	local icon = opts.icon and K.Icon(face, opts.icon, UDim2.fromScale(0.72, 0.72), UDim2.fromScale(0.5, 0.45)) or nil
	local label = opts.label and K.Text(face, {Name = "Label", Text = opts.label, TextSize = 13, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -16), InkThickness = 1.5}) or nil
	return {root = shell, face = face, icon = icon, label = label}
end

-- phone-first scale: designed at 844x390 (landscape phone), clamped
function K.AttachScale(gui)
	local sc = new("UIScale", {}, gui)
	local sg = gui:FindFirstAncestorWhichIsA("ScreenGui") or gui
	local function upd()   -- the SAFE area (notch + Roblox top bar removed), not the raw viewport
		local v = sg.AbsoluteSize
		if v.X < 10 then v = workspace.CurrentCamera.ViewportSize end
		sc.Scale = math.clamp(math.min(v.X / 844, v.Y / 390), 0.74, 1.45)
	end
	sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(upd); upd()
	return sc
end
return K
