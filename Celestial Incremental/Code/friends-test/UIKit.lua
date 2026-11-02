-- UIKit (Galaxy Incremental): the v12 UI pieces (Celestial Incremental\UI\galaxy_ui_v12_animated.html, owner-approved),
-- built the same way everywhere. Sizes are the v12 pixels (a 1280x720 screen); each screen part has a UIScale.
--  * textures never move (button stripes, header texture); VFX move ON TOP: shine sweeps, sparkles, motes, embers,
--    breathing window glow, pulsing icon glows, pulsing selected outline; icons themselves stay still
--  * no blur glow on buttons; can't-afford buttons have no VFX (calm = "not yet")
--  * Reduced Motion: the moving VFX stop (GuiService.ReducedMotionEnabled)
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
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
function Kit.corner(parent, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
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
function Kit.icon(parent, name, x, y, w, glowColor: Color3?, props)
	local holder = Kit.box(parent, x, y, w, w, { ZIndex = (props and props.ZIndex) or 8 })
	if glowColor then
		local g = new("ImageLabel", { BackgroundTransparency = 1, Image = A.softglow, ImageColor3 = glowColor, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(1.05, 1.05), ImageTransparency = 0.45, ZIndex = holder.ZIndex }, holder)
		glowN += 1
		local d = (glowN % 7) * 0.37
		task.spawn(function()
			task.wait(d)
			if not Kit.calm() and alive(g) then
				Kit.tween(g, { ImageTransparency = 0.05, Size = UDim2.fromScale(1.35, 1.35) }, 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			end
		end)
	end
	local img = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = A.icon[name] or "", Size = UDim2.fromScale(1, 1), ZIndex = holder.ZIndex + 1,
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
	new("ImageLabel", { Name = "Stripes", BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.87, Size = UDim2.fromOffset(512, 128),
		ZIndex = b.ZIndex, ScaleType = Enum.ScaleType.Stretch }, b)
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

return Kit
