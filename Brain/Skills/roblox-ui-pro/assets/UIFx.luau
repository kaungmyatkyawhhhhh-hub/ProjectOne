-- UIFx (roblox-ui-pro): small design helpers from the 16 Nov watch study. Live in MM Outfit Catalog
-- (ReplicatedStorage.OutfitShowcase.UIFx), audited 0 errors on phone / tablet / PC / console.
-- oklch(L,C,h)      perceptual colour -> Color3 (equal L = equal perceived brightness)
-- toOklch(c) / atLightness(c, L)  re-tint an existing brand colour at a new lightness, same hue + chroma
-- edgeFade(sf, px)  fades a ScrollingFrame's top/bottom edge ONLY when there is more content that way
--                   (re-parents sf into a CanvasGroup "<Name>Fade"; moves UIFlexItem/UISizeConstraint onto it)
-- heart(parent, px, color, name)  drawn heart icon in a CanvasGroup (no font glyph)
-- swap(outIcon, inIcon)     crossfade + scale icon swap (Roblox UI has no blur, so scale stands in)
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local UIFx = {}

function UIFx.oklch(L, C, hDeg)
	local h = math.rad(hDeg)
	local a, b = C * math.cos(h), C * math.sin(h)
	local l = (L + 0.3963377774 * a + 0.2158037573 * b) ^ 3
	local m = (L - 0.1055613458 * a - 0.0638541728 * b) ^ 3
	local s = (L - 0.0894841775 * a - 1.2914855480 * b) ^ 3
	local function enc(x)
		x = math.clamp(x, 0, 1)
		return x <= 0.0031308 and 12.92 * x or 1.055 * x ^ (1 / 2.4) - 0.055
	end
	return Color3.new(
		enc(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
		enc(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
		enc(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
	)
end

function UIFx.toOklch(c)
	local function dec(x) return x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4 end
	local r, g, b = dec(c.R), dec(c.G), dec(c.B)
	local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
	l, m, s = l ^ (1 / 3), m ^ (1 / 3), s ^ (1 / 3)
	local L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
	local A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
	local B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
	return L, math.sqrt(A * A + B * B), math.deg(math.atan2(B, A)) % 360
end

function UIFx.atLightness(c, L)
	local _, C, h = UIFx.toOklch(c)
	return UIFx.oklch(L, C, h)
end

function UIFx.edgeFade(sf, px)
	px = px or 18
	local cg = Instance.new("CanvasGroup")
	cg.Name = sf.Name .. "Fade"
	cg.BackgroundTransparency = 1
	cg.BorderSizePixel = 0
	cg.Position, cg.Size, cg.AnchorPoint = sf.Position, sf.Size, sf.AnchorPoint
	cg.LayoutOrder, cg.ZIndex, cg.Visible = sf.LayoutOrder, sf.ZIndex, sf.Visible
	for _, child in sf:GetChildren() do
		if child:IsA("UIFlexItem") or child:IsA("UISizeConstraint") then child.Parent = cg end
	end
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Parent = cg
	cg.Parent = sf.Parent
	sf.AnchorPoint = Vector2.zero
	sf.Position = UDim2.fromScale(0, 0)
	sf.Size = UDim2.fromScale(1, 1)
	sf.Parent = cg
	local function update()
		local view = sf.AbsoluteWindowSize.Y
		local canvas = sf.AbsoluteCanvasSize.Y
		local y = sf.CanvasPosition.Y
		local f = math.clamp(px / math.max(view, 1), 0.02, 0.3)
		local top = y > 1 and 1 or 0
		local bottom = (y + view < canvas - 1) and 1 or 0
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, top),
			NumberSequenceKeypoint.new(f, 0),
			NumberSequenceKeypoint.new(1 - f, 0),
			NumberSequenceKeypoint.new(1, bottom),
		})
	end
	sf:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
	sf:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
	sf:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(update)
	update()
	return cg
end

function UIFx.heart(parent, px, color, name)
	local cg = Instance.new("CanvasGroup")
	cg.Name = name or "Heart"
	cg.BackgroundTransparency = 1
	cg.AnchorPoint = Vector2.new(0.5, 0.5)
	cg.Size = UDim2.fromOffset(px, px)
	local scale = Instance.new("UIScale")
	scale.Parent = cg
	local function block(x, y, w, h, rot, round)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(x, y)
		f.Size = UDim2.fromScale(w, h)
		f.Rotation = rot or 0
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(round, 0)
		c.Parent = f
		f.Parent = cg
	end
	block(0.31, 0.36, 0.44, 0.44, 0, 0.5)
	block(0.69, 0.36, 0.44, 0.44, 0, 0.5)
	block(0.5, 0.56, 0.5, 0.5, 45, 0.12)
	cg.Parent = parent
	return cg
end

function UIFx.swap(outIcon, inIcon)
	local reduced = GuiService.ReducedMotionEnabled
	if outIcon then
		if reduced then outIcon.GroupTransparency = 1 else
			TweenService:Create(outIcon, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
			local s = outIcon:FindFirstChildOfClass("UIScale")
			if s then TweenService:Create(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 0.8 }):Play() end
		end
	end
	if inIcon then
		local s = inIcon:FindFirstChildOfClass("UIScale")
		if reduced then
			inIcon.GroupTransparency = 0
			if s then s.Scale = 1 end
		else
			inIcon.GroupTransparency = 1
			if s then
				s.Scale = 0.8
				TweenService:Create(s, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			end
			TweenService:Create(inIcon, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
		end
	end
end

return UIFx
