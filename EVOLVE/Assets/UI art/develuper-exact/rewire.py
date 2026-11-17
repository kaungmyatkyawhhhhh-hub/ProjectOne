"""Rewire EvolutionUI_new.luau from the ChatGPT sandstone art to the Develuper-style kit (art_table.lua).
Usage: python -I rewire.py   (run inside develuper-kit/)"""
import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
p = 'EvolutionUI_new.luau'
s = open(p, encoding='utf8').read().replace('\r\n', '\n')
art = open('art_table.lua', encoding='utf8').read().rstrip('\n')


def R(a, b):
    global s
    assert a in s, 'miss: ' + a[:90]
    s = s.replace(a, b, 1)


def cut(a, b, new):
    global s
    i = s.index(a); j = s.index(b, i); s = s[:i] + new + s[j:]


R("-- HUD + Shop (Upgrades / Robux cards) + Diet + Family Index, drawn with the game's ChatGPT art (sandstone + fossils).",
  "-- HUD + Shop (Upgrades / Robux cards) + Diet + Family Index, drawn in Develuper's \"UI 10x\" style (values measured off his frames;\n"
  "-- generator + params in the vault: EVOLVE/Assets/UI art/develuper-exact).")
cut("---------------------------------------------------------------- art (uploaded 18 Nov; source sheets in the vault)", "local INK =",
    "---------------------------------------------------------------- art (uploaded 18 Nov, Develuper style)\n"
    "-- every PNG is drawn at 2 px per design point with a transparent margin: rect = {x, y, w, h} trims it (ImageRect),\n"
    "-- slice = {left, top, right, bottom} insets in px inside that rect; SliceScale 0.5 turns px back into points\n"
    "local PX = 0.5\nlocal ART = {\n" + art + "\n}\n")
R("local INK = Color3.fromRGB(26, 15, 8)\nlocal CREAM = Color3.fromRGB(255, 244, 224)\nlocal MUTED = Color3.fromRGB(225, 205, 175)",
  "local INK = Color3.new(0, 0, 0)\nlocal CREAM = Color3.new(1, 1, 1) -- his text is pure white with a black stroke\nlocal MUTED = Color3.fromRGB(205, 205, 215)")
R("""	local o = new(button and "ImageButton" or "ImageLabel", { BackgroundTransparency = 1, Image = uri(a), Name = key }, parent)
	if a.slice then
		o.ScaleType = Enum.ScaleType.Slice
		o.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.w - a.slice[3], a.h - a.slice[4])
		o.SliceScale = a.scale
	else""", """	local o = new(button and "ImageButton" or "ImageLabel", { BackgroundTransparency = 1, Image = uri(a), Name = key }, parent)
	o.ImageRectOffset, o.ImageRectSize = Vector2.new(a.rect[1], a.rect[2]), Vector2.new(a.rect[3], a.rect[4])
	if a.slice then
		o.ScaleType = Enum.ScaleType.Slice
		o.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.rect[3] - a.slice[3], a.rect[4] - a.slice[4])
		o.SliceScale = PX
	else""")
R("b.ImageColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(95, 88, 82)",
  "b.ImageColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 128)")
R("""		SetArt = function(key) b.Image = uri(ART[key]) end,""", """		SetArt = function(key)
			local a = ART[key]
			b.Image, b.ImageRectOffset, b.ImageRectSize = uri(a), Vector2.new(a.rect[1], a.rect[2]), Vector2.new(a.rect[3], a.rect[4])
			if a.slice then b.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.rect[3] - a.slice[3], a.rect[4] - a.slice[4]) end
		end,""")
# HUD
R("""local pill = img(hud, "pill", { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(176, 46) })""",
  """local pill = img(hud, "dnaPill", { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(176, 46) })
img(pill, "dna", { Position = UDim2.fromOffset(8, 3), Size = UDim2.fromOffset(30, 36), ZIndex = 2 })""")
R("""local status = img(hud, "status", { Size = UDim2.fromOffset(316, 92), ScaleType = Enum.ScaleType.Stretch })""",
  """local status = img(hud, "status", { Size = UDim2.fromOffset(316, 92) })""")
R("""	local track = img(status, "bar", { Position = UDim2.new(0, 30, 0, y), Size = UDim2.new(1, -60, 0, 22) })
	local inner = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 5), Size = UDim2.new(1, -14, 1, -10), ClipsDescendants = true }, track)""",
  """	local track = img(status, "barTrack", { Position = UDim2.new(0, 30, 0, y), Size = UDim2.new(1, -60, 0, 22) })
	local inner = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 1, -10), ClipsDescendants = true }, track)""")
R("""local shopButton = menuButton(1, "green", "iconShop", "Shop", "Shop")
menuButton(2, "amber", "iconDiet", "Diet", "Diet")
menuButton(3, "amber", "iconIndex", "Index", "Index")""", """local shopButton = menuButton(1, "btnGreenSq", "shop", "Shop", "Shop")
menuButton(2, "btnYellowSq", "diet", "Diet", "Diet")
menuButton(3, "btnYellowSq", "index", "Index", "Index")""")
R("""	img(b.Button, icon, { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(32, 30), ZIndex = 3 })
	b.Label.Position, b.Label.Size = UDim2.fromOffset(0, 33), UDim2.new(1, 0, 0, 18)
	b.Label.Parent:FindFirstChild("Depth").Position = UDim2.fromOffset(0, 35)""", """	img(b.Button, icon, { Position = UDim2.fromOffset(11, 3), Size = UDim2.fromOffset(34, 30), ZIndex = 3 })
	b.Label.Position, b.Label.Size = UDim2.fromOffset(0, 29), UDim2.new(1, 0, 0, 18)
	b.Label.Parent:FindFirstChild("Depth").Position = UDim2.fromOffset(0, 30)""")
# window: white panel, green title bar overlapping top-left with icon, red Close text button top-right
R("local function window(name, titleText)", "local function window(name, titleText, iconKey)")
R("""	label(w, titleText, 26, { Position = UDim2.fromOffset(30, 14), Size = UDim2.fromOffset(300, 40), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 231, 168), ZIndex = 4 })
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 72), Size = UDim2.new(1, -56, 1, -100), ZIndex = 3 }, w)""",
  """	-- his "STORE!" bar: green, overlapping the panel's top-left, big title + icon after the text
	local bar = img(w, "header", { Position = UDim2.fromOffset(-10, -22), Size = UDim2.fromOffset(230, 52), ZIndex = 4 })
	local t = label(bar, titleText .. "!", 28, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -60, 1, -10), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
	local ic = img(bar, iconKey, { Position = UDim2.new(0, 22 + t.TextBounds.X, 0, -4), Size = UDim2.fromOffset(42, 42), ZIndex = 7 })
	t:GetPropertyChangedSignal("TextBounds"):Connect(function() ic.Position = UDim2.new(0, 22 + t.TextBounds.X, 0, -4) end)
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 42), Size = UDim2.new(1, -40, 1, -58), ZIndex = 3 }, w)""")
R("""	local close = img(w, "close", { Position = UDim2.new(1, -60, 0, 12), Size = UDim2.fromOffset(44, 44), ZIndex = 5 }, true)
	pressable(close)
	close.Activated:Connect(m.Close)""", """	-- his red "Close" text button, top-right, overlapping like the title bar
	button(w, "close", "Close", 20, { Position = UDim2.new(1, -86, 0, -20), Size = UDim2.fromOffset(96, 40), ZIndex = 5 }, m.Close)""")
R('local shop = window("Shop", "Shop")', 'local shop = window("Shop", "Shop", "shop")')
R('local diet = window("Diet", "Diet")', 'local diet = window("Diet", "Diet", "diet")')
R('local index = window("Index", "Family Index")', 'local index = window("Index", "Index", "index")')
# cards: his layout = name on top, big art, short info, green price pill at the bottom; hero is wider
R("""local function card(parent, order, frameKey, itemKey, name, info, onBuy)
	local c = img(parent, frameKey, { LayoutOrder = order, Size = UDim2.fromOffset(110, 196), ZIndex = 3 })
	local art = img(c, itemKey, { Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(74, 66), ZIndex = 4 })
	local n = label(c, name, 15, { Position = UDim2.fromOffset(4, 82), Size = UDim2.new(1, -8, 0, 20), ZIndex = 5, TextScaled = false, TextTruncate = Enum.TextTruncate.AtEnd })
	local i = label(c, info, 13, { Position = UDim2.fromOffset(4, 103), Size = UDim2.new(1, -8, 0, 32), ZIndex = 5, TextColor3 = MUTED, TextWrapped = true })
	local b = button(c, "green", "", 15, { Position = UDim2.fromOffset(9, 140), Size = UDim2.fromOffset(92, 44), ZIndex = 4 }, onBuy)""",
  """local function card(parent, order, frameKey, itemKey, name, info, onBuy)
	local wide = frameKey == "cardHero"
	local c = img(parent, frameKey, { LayoutOrder = order, Size = UDim2.fromOffset(wide and 170 or 110, 196), ZIndex = 3 })
	local n = label(c, name, wide and 18 or 15, { Position = UDim2.fromOffset(4, 5), Size = UDim2.new(1, -8, 0, 22), ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
	local art = img(c, itemKey, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), Size = UDim2.fromOffset(wide and 110 or 76, 70), ZIndex = 4 })
	local i = label(c, info, 13, { Position = UDim2.fromOffset(5, 100), Size = UDim2.new(1, -10, 0, 34), ZIndex = 5, TextWrapped = true })
	local b = button(c, wide and "btnGreenW" or "btnGreen", "", 15, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.fromOffset(wide and 140 or 92, 44), ZIndex = 4 }, onBuy)""")
R('tabs[t[1]] = button(shop.Content, "tab", t[2], 16,', 'tabs[t[1]] = button(shop.Content, "tab", t[2], 17,')
R("for k, t in tabs do t.Button.ImageColor3 = k == which and Color3.new(1, 1, 1) or Color3.fromRGB(140, 125, 110) end",
  "for k, t in tabs do t.Button.ImageColor3 = k == which and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 160) end")
R('upgradeCards[u] = card(pages.Upgrades, i + 1, "cardBrown", u.art,', 'upgradeCards[u] = card(pages.Upgrades, i + 1, "cardCyan", u.art,')
R('local rebirthCard = card(pages.Upgrades, 9, "cardBrown", "asteroid",', 'local rebirthCard = card(pages.Upgrades, 9, "cardMagenta", "asteroid",')
R("""	DoubleDNA = { "cardBrown", "dna2" }, FastLife = { "cardBrown", "stopwatch" }, VIP = { "cardGold", "crown" },
	OfflinePlus = { "cardBrown", "moon" }, Skip5 = { "cardTeal", "skip" }, Skip20 = { "cardTeal", "skip" }, DNAPack = { "cardTeal", "jar" },""",
  """	-- colour = tier, like his store: hero yellow, epic magenta, rare purple, cash-style cyan, common green
	DoubleDNA = { "cardMagenta", "dna2" }, FastLife = { "cardPurple", "stopwatch" }, VIP = { "cardHero", "crown" },
	OfflinePlus = { "cardPurple", "moon" }, Skip5 = { "cardCyan", "skip" }, Skip20 = { "cardCyan", "skip" }, DNAPack = { "cardGreen", "jar" },""")
R('local a = ROBUX_ART[key] or { "cardBrown", "jar" }', 'local a = ROBUX_ART[key] or { "cardGreen", "jar" }')
R("r.card.Card.ImageColor3 = owned and Color3.fromRGB(150, 140, 130) or Color3.new(1, 1, 1)",
  "r.card.Card.ImageColor3 = owned and Color3.fromRGB(150, 150, 160) or Color3.new(1, 1, 1)")
# diet + index + toast
R('local b = button(r, "green", "Eat", 16,', 'local b = button(r, "btnGreenW", "Eat", 16,')
R('r.button.SetArt(a.Diet == d.id and "amber" or "green")', 'r.button.SetArt(a.Diet == d.id and "btnYellowW" or "btnGreenW")')
R("""		local tile = img(grid, "row", { LayoutOrder = i, ZIndex = 3 })
		tile.SliceScale = 0.14""", """		local tile = img(grid, "row", { LayoutOrder = i, ZIndex = 3 })""")
R('local t = img(toastRoot, "row", {', 'local t = img(toastRoot, "toast", {')

left = [x for x in ('cardBrown', 'cardGold', 'cardTeal', '"green"', '"amber"', 'iconShop', 'a.scale') if x in s]
assert not left, left
open(p, 'w', encoding='utf8', newline='\n').write(s)
print('ok', len(s))
