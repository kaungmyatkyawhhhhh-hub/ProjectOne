-- MEGA BITE shop UI, built 1:1 on the layout/style of the reference shop (owner 9 Nov 23:10).
-- Native Roblox UI (UICorner/UIStroke/UIGradient + FredokaOne), icons are placeholders until the ChatGPT icon sheet.
local SG = game:GetService("StarterGui")
local old = SG:FindFirstChild("MB_Shop"); if old then old:Destroy() end

local C = {
	navy = Color3.fromRGB(38, 24, 84), navyDeep = Color3.fromRGB(24, 14, 58), outline = Color3.fromRGB(20, 10, 46),
	green1 = Color3.fromRGB(196, 255, 40), green2 = Color3.fromRGB(96, 200, 20), greenLine = Color3.fromRGB(28, 90, 10),
	gold1 = Color3.fromRGB(255, 214, 60), gold2 = Color3.fromRGB(255, 150, 20), goldLine = Color3.fromRGB(120, 60, 0),
	red1 = Color3.fromRGB(255, 92, 80), red2 = Color3.fromRGB(205, 18, 30), redLine = Color3.fromRGB(90, 0, 10),
	grey1 = Color3.fromRGB(236, 238, 242), grey2 = Color3.fromRGB(180, 186, 196), white = Color3.new(1, 1, 1),
	text = Color3.new(1, 1, 1), dark = Color3.fromRGB(30, 22, 50),
}
local F = Enum.Font.FredokaOne

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 16)}, o) end
local function stroke(o, col, th, mode)
	return new("UIStroke", {Color = col, Thickness = th or 3, ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round}, o)
end
local function grad(o, cols, rot)
	local kp = {}
	for i, c in ipairs(cols) do kp[i] = ColorSequenceKeypoint.new((i - 1) / (#cols - 1), c) end
	return new("UIGradient", {Color = ColorSequence.new(kp), Rotation = rot or 90}, o)
end
local function label(parent, txt, size, pos, sz, col, xa, strokeTh)
	local l = new("TextLabel", {BackgroundTransparency = 1, Text = txt, Font = F, TextScaled = true, TextColor3 = col or C.text,
		Position = pos, Size = sz, TextXAlignment = xa or Enum.TextXAlignment.Left}, parent)
	new("UITextSizeConstraint", {MaxTextSize = size}, l)
	if strokeTh ~= 0 then stroke(l, C.outline, strokeTh or 2, Enum.ApplyStrokeMode.Contextual) end
	return l
end
-- chunky pill button: gradient body, dark outline, white top shine, label
local function button(parent, txt, pos, sz, kind, textSize)
	local cols = ({green = {C.green1, C.green2, C.greenLine}, gold = {C.gold1, C.gold2, C.goldLine}, red = {C.red1, C.red2, C.redLine},
		grey = {C.grey1, C.grey2, Color3.fromRGB(90, 96, 110)}})[kind or "green"]
	local b = new("TextButton", {Text = "", AutoButtonColor = true, BackgroundColor3 = C.white, Position = pos, Size = sz}, parent)
	corner(b, 14); stroke(b, cols[3], 3); grad(b, {cols[1], cols[2]}, 90)
	local shine = new("Frame", {BackgroundColor3 = C.white, BackgroundTransparency = 0.55, BorderSizePixel = 0,
		Position = UDim2.new(0.06, 0, 0.1, 0), Size = UDim2.new(0.88, 0, 0.22, 0)}, b); corner(shine, 8)
	local l = label(b, txt, textSize or 30, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), kind == "grey" and Color3.fromRGB(70, 74, 86) or C.text, Enum.TextXAlignment.Center, kind == "grey" and 0 or 2)
	new("UIPadding", {PaddingTop = UDim.new(0.12, 0), PaddingBottom = UDim.new(0.12, 0), PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.06, 0)}, l)
	return b, l
end
local function badge(parent, txt, pos, sz, kind)
	local f = new("Frame", {Position = pos, Size = sz, BackgroundColor3 = C.white}, parent); corner(f, 10); stroke(f, C.outline, 2)
	grad(f, kind == "gold" and {C.gold1, C.gold2} or {Color3.fromRGB(255, 70, 90), Color3.fromRGB(200, 20, 60)}, 90)
	local l = label(f, txt, 20, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), kind == "gold" and C.dark or C.text, Enum.TextXAlignment.Center, kind == "gold" and 0 or 1.5)
	new("UIPadding", {PaddingTop = UDim.new(0.15, 0), PaddingBottom = UDim.new(0.15, 0)}, l)
	return f
end
local function icon(parent, emoji, pos, sz) -- placeholder until the ChatGPT icon sheet
	return new("TextLabel", {BackgroundTransparency = 1, Text = emoji, TextScaled = true, Font = F, Position = pos, Size = sz, Name = "Icon"}, parent)
end
local function card(parent, pos, sz, cols, rot, line)
	local f = new("Frame", {Position = pos, Size = sz, BackgroundColor3 = C.white}, parent); corner(f, 22); stroke(f, line or C.outline, 4); grad(f, cols, rot or 0)
	return f
end

-- ScreenGui + 16:9 canvas
local gui = new("ScreenGui", {Name = "MB_Shop", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = true}, SG)
new("Frame", {Name = "Dim", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0}, gui)
local root = new("Frame", {Name = "Root", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.94, 0.94)}, gui)
new("UIAspectRatioConstraint", {AspectRatio = 1350 / 720}, root)
local function P(x, y) return UDim2.new(x / 1350, 0, y / 720, 0) end  -- reference-screenshot pixels -> scale

-- header
label(root, "Shop", 80, P(10, 10), P(190, 80), C.text, nil, 4).Name = "Title"
local tabs = new("Frame", {Name = "Tabs", BackgroundColor3 = C.navy, Position = P(205, 22), Size = P(650, 60)}, root); corner(tabs, 30); stroke(tabs, C.outline, 3)
local tabNames = {{"Featured", "🏷️"}, {"Skins", "🦈"}, {"Passes", "🎫"}, {"Boosts", "⚡"}, {"Gems", "💎"}}
for i, t in ipairs(tabNames) do
	local tb, tl = button(tabs, "", UDim2.new((i - 1) / 5 + 0.006, 0, 0.12, 0), UDim2.new(1 / 5 - 0.012, 0, 0.76, 0), i == 1 and "green" or "grey", 26)
	tb.Name = t[1]
	if i ~= 1 then tb.BackgroundTransparency = 1; tb.UIGradient.Enabled = false; tb.UIStroke.Enabled = false; tb:FindFirstChildOfClass("Frame").Visible = false end
	icon(tb, t[2], UDim2.new(0.04, 0, 0.12, 0), UDim2.new(0.22, 0, 0.76, 0))
	local l = label(tb, t[1], 24, UDim2.new(0.28, 0, 0.18, 0), UDim2.new(0.7, 0, 0.64, 0), i == 1 and C.text or Color3.fromRGB(205, 200, 235), Enum.TextXAlignment.Left, i == 1 and 2 or 0)
	tl:Destroy()
end
local cur = new("Frame", {Name = "Currency", BackgroundColor3 = C.navy, Position = P(905, 22), Size = P(260, 60)}, root); corner(cur, 30); stroke(cur, C.outline, 3)
icon(cur, "💎", UDim2.new(0.03, 0, 0.1, 0), UDim2.new(0.22, 0, 0.8, 0))
label(cur, "222", 34, UDim2.new(0.27, 0, 0.15, 0), UDim2.new(0.45, 0, 0.7, 0), C.text, Enum.TextXAlignment.Left, 2).Name = "Amount"
local plus = button(cur, "+", UDim2.new(0.76, 0, 0.12, 0), UDim2.new(0.2, 0, 0.76, 0), "green", 36); plus.UICorner.CornerRadius = UDim.new(1, 0)
local close = button(root, "X", P(1185, 12), P(80, 76), "red", 54); close.Name = "Close"

-- scrolling page
local page = new("ScrollingFrame", {Name = "Page", BackgroundTransparency = 1, Position = P(10, 100), Size = P(1300, 615), CanvasSize = UDim2.new(0, 0, 3.2, 0),
	ScrollBarThickness = 6, ScrollBarImageColor3 = C.white, BorderSizePixel = 0}, root)
local function Q(x, y, w, h) -- pixel rect inside the page (1300 px wide, canvas 3.2 x 615 px tall)
	local H = 615 * 3.2
	return UDim2.new(x / 1300, 0, y / H, 0), UDim2.new(w / 1300, 0, h / H, 0)
end

-- FEATURED hero (carousel)
local p, s = Q(5, 10, 790, 245)
local hero = card(page, p, s, {Color3.fromRGB(40, 120, 255), Color3.fromRGB(140, 64, 255), Color3.fromRGB(255, 92, 220)}, 0, Color3.fromRGB(26, 50, 150)); hero.Name = "Hero"
badge(hero, "FEATURED PASS", UDim2.fromScale(0.04, 0.08), UDim2.fromScale(0.16, 0.1), "gold")
label(hero, "Megalodon Skin!", 64, UDim2.fromScale(0.04, 0.2), UDim2.fromScale(0.6, 0.24), C.text, nil, 3)
label(hero, "A glowing prehistoric look for your shark - cosmetic only", 22, UDim2.fromScale(0.04, 0.45), UDim2.fromScale(0.56, 0.1), C.text, nil, 1.5)
button(hero, "R$ 449", UDim2.fromScale(0.04, 0.66), UDim2.fromScale(0.19, 0.24), "green", 40)
button(hero, "💎 1,250", UDim2.fromScale(0.25, 0.68), UDim2.fromScale(0.17, 0.2), "gold", 30)
icon(hero, "🦈", UDim2.fromScale(0.56, 0.08), UDim2.fromScale(0.36, 0.78))
local nav = new("Frame", {BackgroundColor3 = C.navyDeep, BackgroundTransparency = 0.2, Position = UDim2.fromScale(0.78, 0.78), Size = UDim2.fromScale(0.2, 0.17)}, hero); corner(nav, 20)
button(nav, "<", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.25, 0.84), "grey", 28)
button(nav, ">", UDim2.fromScale(0.72, 0.08), UDim2.fromScale(0.25, 0.84), "grey", 28)
for i = 1, 2 do new("Frame", {BackgroundColor3 = C.white, BackgroundTransparency = i == 1 and 0.4 or 0, Position = UDim2.fromScale(0.36 + (i - 1) * 0.12, 0.38), Size = UDim2.fromScale(i == 1 and 0.06 or 0.16, 0.24)}, nav).Name = "Dot" end

-- side promo cards
local function promo(y, title, sub, cols, price, old, emoji, sale)
	local pp, ss = Q(812, y, 470, 115)
	local f = card(page, pp, ss, cols, 0)
	icon(f, emoji, UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.24, 0.84))
	label(f, title, 36, UDim2.fromScale(0.3, 0.08), UDim2.fromScale(0.66, 0.34), C.text, nil, 2.5)
	label(f, sub, 18, UDim2.fromScale(0.3, 0.42), UDim2.fromScale(0.66, 0.16), C.text, nil, 1.5)
	button(f, price, UDim2.fromScale(0.3, 0.62), UDim2.fromScale(0.28, 0.3), "green", 26)
	if old then local o = label(f, old, 22, UDim2.fromScale(0.62, 0.66), UDim2.fromScale(0.16, 0.24), Color3.fromRGB(255, 70, 70), nil, 1.5)
		new("Frame", {BackgroundColor3 = Color3.fromRGB(255, 70, 70), BorderSizePixel = 0, Position = UDim2.fromScale(0, 0.48), Size = UDim2.fromScale(0.9, 0.08)}, o) end
	if sale then badge(f, "SALE!", UDim2.fromScale(0.01, -0.08), UDim2.fromScale(0.15, 0.24), "red").Rotation = -8 end
	return f
end
promo(10, "x2 EXP", "Grow twice as fast - forever", {Color3.fromRGB(120, 14, 24), Color3.fromRGB(60, 8, 14)}, "R$ 349", nil, "⭐")
promo(140, "Shark Radar!", "See prey near you on the map", {Color3.fromRGB(110, 40, 190), Color3.fromRGB(60, 20, 120)}, "R$ 199", "R$ 299", "📡", true)

-- section: Skins showcase (in place of the reference's paid egg)
local p2, s2 = Q(5, 280, 1278, 300)
local show = card(page, p2, s2, {Color3.fromRGB(10, 70, 140), Color3.fromRGB(6, 30, 80)}, 0); show.Name = "SkinShowcase"
badge(show, "LIMITED!", UDim2.fromScale(0.015, 0.05), UDim2.fromScale(0.11, 0.12), "red").Rotation = -8
label(show, "Abyss Skins", 60, UDim2.fromScale(0.2, 0.06), UDim2.fromScale(0.3, 0.2), C.text, nil, 3)
badge(show, "THIS WEEK", UDim2.fromScale(0.45, 0.1), UDim2.fromScale(0.1, 0.11), "gold")
label(show, "Glow-in-the-dark looks - pick the one you want, no luck involved", 22, UDim2.fromScale(0.2, 0.27), UDim2.fromScale(0.5, 0.09), C.text, nil, 1.5)
for i, sk in ipairs({{"Lantern", "🔦"}, {"Ghost", "👻"}, {"Coral", "🪸"}, {"Ember", "🔥"}}) do
	local x = 0.17 + (i - 1) * 0.135
	icon(show, sk[2], UDim2.fromScale(x, 0.42), UDim2.fromScale(0.11, 0.36))
	label(show, sk[1], 22, UDim2.fromScale(x, 0.8), UDim2.fromScale(0.11, 0.1), C.text, Enum.TextXAlignment.Center, 1.5)
end
local box = new("Frame", {BackgroundColor3 = C.navyDeep, BackgroundTransparency = 0.15, Position = UDim2.fromScale(0.76, 0.06), Size = UDim2.fromScale(0.22, 0.88)}, show); corner(box, 18)
for i, r in ipairs({{"1 Skin", "R$ 199"}, {"2 Skins", "R$ 349"}, {"All 4", "R$ 449"}}) do
	local row = new("Frame", {BackgroundColor3 = C.white, Position = UDim2.fromScale(0.04, 0.06 + (i - 1) * 0.31), Size = UDim2.fromScale(0.92, 0.26)}, box); corner(row, 14); stroke(row, C.outline, 2)
	label(row, r[1], 28, UDim2.fromScale(0.07, 0.2), UDim2.fromScale(0.45, 0.6), C.dark, nil, 0)
	button(row, r[2], UDim2.fromScale(0.52, 0.12), UDim2.fromScale(0.44, 0.76), "green", 24)
	if i == 3 then badge(row, "BEST VALUE", UDim2.fromScale(0.04, -0.28), UDim2.fromScale(0.42, 0.34), "gold") end
end

-- section: Gamepasses (white panel with coloured cards)
local p3, s3 = Q(5, 610, 1278, 330)
label(page, "Gamepasses", 48, select(1, Q(60, 600, 340, 50)), select(2, Q(60, 600, 340, 50)), C.text, nil, 3)
local panel = new("Frame", {Name = "Passes", BackgroundColor3 = C.white, Position = p3 + UDim2.new(0, 0, 0.02, 0), Size = s3}, page); corner(panel, 26); stroke(panel, C.outline, 4)
local passes = {
	{"x2 EXP", "Grow 2x faster", "R$ 349", {Color3.fromRGB(150, 70, 255), Color3.fromRGB(100, 30, 200)}, "⭐"},
	{"x2 Shells", "Double shells", "R$ 299", {Color3.fromRGB(90, 200, 255), Color3.fromRGB(40, 130, 230)}, "🐚"},
	{"Megalodon Skin", "Cosmetic", "R$ 449", {Color3.fromRGB(255, 110, 210), Color3.fromRGB(200, 40, 160)}, "🦈"},
	{"VIP", "Tag + gold trail", "R$ 249", {Color3.fromRGB(120, 230, 90), Color3.fromRGB(50, 170, 60)}, "👑"},
	{"Shark Radar", "Prey on map", "R$ 199", {Color3.fromRGB(255, 230, 80), Color3.fromRGB(240, 170, 20)}, "📡"},
	{"Extra Bank", "+1 bank slot", "R$ 149", {Color3.fromRGB(80, 40, 140), Color3.fromRGB(30, 10, 70)}, "🏦"},
}
for i, ps in ipairs(passes) do
	local f = card(panel, UDim2.fromScale(0.015 + (i - 1) * 0.163, 0.08), UDim2.fromScale(0.15, 0.84), ps[4], 90)
	new("Frame", {BackgroundColor3 = C.white, BackgroundTransparency = 0.85, Position = UDim2.fromScale(0.08, 0.04), Size = UDim2.fromScale(0.84, 0.38)}, f).Name = "ArtBack"
	icon(f, ps[5], UDim2.fromScale(0.2, 0.05), UDim2.fromScale(0.6, 0.36))
	label(f, ps[1], 26, UDim2.fromScale(0.05, 0.44), UDim2.fromScale(0.9, 0.13), C.text, Enum.TextXAlignment.Center, 2)
	local tag = new("Frame", {BackgroundColor3 = C.navyDeep, BackgroundTransparency = 0.25, Position = UDim2.fromScale(0.12, 0.58), Size = UDim2.fromScale(0.76, 0.09)}, f); corner(tag, 10)
	label(tag, ps[2], 18, UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.8), C.gold1, Enum.TextXAlignment.Center, 1)
	button(f, ps[3], UDim2.fromScale(0.08, 0.72), UDim2.fromScale(0.84, 0.17), "green", 26)
	local gift = button(f, "🎁", UDim2.fromScale(0.78, 0.02), UDim2.fromScale(0.2, 0.12), "grey", 22); gift.Name = "Gift"
end

-- section: Gems (premium currency packs, dev products)
label(page, "Gems", 48, select(1, Q(60, 975, 300, 50)), select(2, Q(60, 975, 300, 50)), C.text, nil, 3)
for i, g in ipairs({{"+200", "R$ 49"}, {"+500", "R$ 99"}, {"+1,200", "R$ 199"}, {"+3,000", "R$ 449"}}) do
	local pp, ss = Q(5 + (i - 1) * 322, 1030, 305, 160)
	local f = card(page, pp, ss, {Color3.fromRGB(170, 110, 255), Color3.fromRGB(120, 60, 230)}, 90)
	icon(f, "💎", UDim2.fromScale(0.04, 0.12), UDim2.fromScale(0.38, 0.76))
	label(f, g[1], 44, UDim2.fromScale(0.45, 0.1), UDim2.fromScale(0.52, 0.32), C.text, nil, 2.5)
	label(f, "Gems", 20, UDim2.fromScale(0.45, 0.4), UDim2.fromScale(0.5, 0.14), C.text, nil, 1.5)
	button(f, g[2], UDim2.fromScale(0.45, 0.6), UDim2.fromScale(0.5, 0.28), "green", 28)
	if i == 4 then badge(f, "MOST POPULAR", UDim2.fromScale(0.03, -0.06), UDim2.fromScale(0.42, 0.17), "red") end
end

-- popups (hidden): Buy-with and Gift
local function popup(name, w, h)
	local f = new("Frame", {Name = name, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(w, h), BackgroundColor3 = C.white, ZIndex = 10}, root)
	corner(f, 22); stroke(f, C.outline, 4); return f
end
local buy = popup("BuyPopup", 0.27, 0.27)
button(buy, "Buy with Robux", UDim2.fromScale(0.05, 0.07), UDim2.fromScale(0.9, 0.26), "green", 34)
button(buy, "Buy with 1,250 Gems", UDim2.fromScale(0.05, 0.37), UDim2.fromScale(0.9, 0.26), "gold", 30)
button(buy, "Cancel", UDim2.fromScale(0.05, 0.67), UDim2.fromScale(0.9, 0.26), "red", 34)
local giftp = popup("GiftPopup", 0.3, 0.55); grad(giftp, {Color3.fromRGB(190, 150, 255), Color3.fromRGB(150, 100, 240)}, 90)
label(giftp, "Gift", 60, UDim2.fromScale(0.3, -0.06), UDim2.fromScale(0.4, 0.14), C.gold1, Enum.TextXAlignment.Center, 3)
local gx = button(giftp, "X", UDim2.fromScale(0.86, -0.04), UDim2.fromScale(0.13, 0.11), "red", 34)
for i = 1, 4 do
	local row = new("Frame", {BackgroundColor3 = C.white, Position = UDim2.fromScale(0.04, 0.12 + (i - 1) * 0.21), Size = UDim2.fromScale(0.92, 0.18)}, giftp); corner(row, 14); stroke(row, C.outline, 2)
	new("Frame", {BackgroundColor3 = Color3.fromRGB(200, 205, 215), Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.15, 0.76)}, row):SetAttribute("Avatar", true)
	label(row, "PlayerName", 22, UDim2.fromScale(0.22, 0.15), UDim2.fromScale(0.45, 0.4), Color3.fromRGB(230, 150, 20), nil, 1)
	label(row, "@username", 16, UDim2.fromScale(0.22, 0.55), UDim2.fromScale(0.45, 0.3), Color3.fromRGB(40, 150, 60), nil, 0)
	button(row, "Gift", UDim2.fromScale(0.7, 0.15), UDim2.fromScale(0.27, 0.7), "green", 26)
end
return "MB_Shop built"
