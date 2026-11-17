-- HUD + Shop (Upgrades / Robux cards) + Diet + Family Index, drawn with the game's ChatGPT art (sandstone + fossils).
-- Art is 9-sliced ImageLabels; code only places images, text and motion. Sizes are phone points: the Root frame is
-- a 720x360 design that UIScale fits to the screen, so text stays >= ~13 pt on a phone and grows on PC.
-- Reads state from player attributes set by ServerScriptService.Evolution; the server validates every request.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")

local Kit = require(ReplicatedStorage:WaitForChild("UI"):WaitForChild("Kit"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("EvolutionRemotes")

if RunService:IsStudio() then -- test key: [ unlocks everything (the server only makes this remote in Studio)
	game:GetService("UserInputService").InputBegan:Connect(function(input, typing)
		local r = remotes:FindFirstChild("TestUnlockAll")
		if not typing and r and input.KeyCode == Enum.KeyCode.LeftBracket then r:FireServer() end
	end)
end

---------------------------------------------------------------- art (uploaded 18 Nov; source sheets in the vault)
-- slice = {left, top, right, bottom} insets in image px; scale = SliceScale in design points
local ART = {
	status = { id = 85047550391207 }, -- drawn whole: its crest would smear in a 9-slice
	pill = { id = 129184827451314, w = 529, h = 215, slice = { 175, 70, 60, 70 }, scale = 0.19 },
	green = { id = 93568833703046, w = 376, h = 229, slice = { 60, 60, 60, 65 }, scale = 0.16 },
	amber = { id = 91232997575427, w = 377, h = 229, slice = { 60, 60, 60, 65 }, scale = 0.16 },
	close = { id = 120631533939054 },
	window = { id = 136582912915809, w = 564, h = 373, slice = { 70, 115, 70, 75 }, scale = 0.56 },
	row = { id = 120415667377266, w = 795, h = 199, slice = { 60, 55, 60, 55 }, scale = 0.21 },
	bar = { id = 82455533752749, w = 810, h = 119, slice = { 50, 45, 50, 45 }, scale = 0.19 },
	cardBrown = { id = 79800944653271, w = 452, h = 591, slice = { 90, 90, 90, 90 }, scale = 0.21 },
	cardGold = { id = 86374205025766, w = 456, h = 595, slice = { 90, 90, 90, 90 }, scale = 0.21 },
	cardTeal = { id = 99603068148329, w = 459, h = 592, slice = { 90, 90, 90, 90 }, scale = 0.21 },
	tab = { id = 75713343472009, w = 906, h = 229, slice = { 130, 70, 130, 70 }, scale = 0.19 },
	iconShop = { id = 84740887022585 }, iconDiet = { id = 122438632943803 }, iconIndex = { id = 137810853551545 },
	brain = { id = 117432550574038 }, hourglass = { id = 74464036005413 }, cradle = { id = 131960657761337 },
	asteroid = { id = 104163766579401 }, dna2 = { id = 130457498968000 }, stopwatch = { id = 132145357276404 },
	crown = { id = 95631665044809 }, moon = { id = 109592388054789 }, skip = { id = 82169164163750 }, jar = { id = 125315930034398 },
}
local INK = Color3.fromRGB(26, 15, 8)
local CREAM = Color3.fromRGB(255, 244, 224)
local MUTED = Color3.fromRGB(225, 205, 175)
local GOLD = Color3.fromRGB(255, 225, 150)
local DNA_C = Color3.fromRGB(140, 245, 192)
local FONT = Font.fromEnum(Enum.Font.FredokaOne)
local ROBUX = utf8.char(0xE002) -- Roblox's own Robux glyph

local function uri(a) return "rbxassetid://" .. a.id end
do -- preload so a window never opens with blank art
	local list = {}
	for _, a in ART do table.insert(list, uri(a)) end
	task.spawn(function() pcall(ContentProvider.PreloadAsync, ContentProvider, list) end)
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in props do o[k] = v end
	o.Parent = parent
	return o
end

-- ImageLabel/ImageButton from ART; sliced when the art has slice data, fitted otherwise
local function img(parent, key, props, button)
	local a = ART[key]
	local o = new(button and "ImageButton" or "ImageLabel", { BackgroundTransparency = 1, Image = uri(a), Name = key }, parent)
	if a.slice then
		o.ScaleType = Enum.ScaleType.Slice
		o.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.w - a.slice[3], a.h - a.slice[4])
		o.SliceScale = a.scale
	else
		o.ScaleType = Enum.ScaleType.Fit
	end
	for k, v in props or {} do o[k] = v end
	return o
end

-- outlined display text with a dark copy under it for depth (the mockup look)
local function label(parent, text, size, props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Text = text, TextSize = size, FontFace = FONT, TextColor3 = CREAM,
		Size = UDim2.fromScale(1, 1), ZIndex = 3,
	}, parent)
	new("UIStroke", { Color = INK, Thickness = math.max(1.5, size / 9), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, l)
	for k, v in props or {} do l[k] = v end
	local shadow = l:Clone()
	shadow.TextColor3, shadow.ZIndex, shadow.Name = INK, l.ZIndex - 1, "Depth"
	shadow.Position = l.Position + UDim2.fromOffset(0, math.max(1, size / 12))
	shadow.Parent = parent
	l:GetPropertyChangedSignal("Text"):Connect(function() shadow.Text = l.Text end)
	l:GetPropertyChangedSignal("Visible"):Connect(function() shadow.Visible = l.Visible end)
	return l
end

local function pressable(b) -- squish on press = the tap is felt
	local s = new("UIScale", {}, b)
	b.MouseButton1Down:Connect(function() TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.93 }):Play() end)
	local function up() TweenService:Create(s, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play() end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
end

-- art button with a label; SetEnabled greys the art (no padlock stretched across a wide button)
local function button(parent, key, text, size, props, onClick)
	local b = img(parent, key, props, true)
	b.AutoButtonColor = false
	local l = label(b, text, size, { ZIndex = (b.ZIndex or 1) + 2 })
	pressable(b)
	local enabled = true
	b.Activated:Connect(function() if enabled then onClick() end end)
	return {
		Button = b, Label = l,
		SetText = function(t) l.Text = t end,
		SetEnabled = function(on, t)
			enabled = on
			b.ImageColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(95, 88, 82)
			l.TextColor3 = on and CREAM or MUTED
			if t then l.Text = t end
		end,
		SetArt = function(key) b.Image = uri(ART[key]) end,
	}
end

---------------------------------------------------------------- root: a 720x360 design scaled to fit the screen
local function scaledRoot(gui)
	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1 }, gui)
	local s = new("UIScale", {}, root)
	local function fit()
		local v = gui.AbsoluteSize
		local k = math.clamp(math.min(v.X / 720, v.Y / 360), 0.75, 1.8)
		s.Scale = k
		root.Size = UDim2.fromOffset(v.X / k, v.Y / k)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return root
end

local hudGui = Kit.screen("EvolutionHUD", 10, playerGui)
local hud = scaledRoot(hudGui)

-- DNA counter
local pill = img(hud, "pill", { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(176, 46) })
local dnaText = label(pill, "", 21, { Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -86, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = DNA_C })
local multText = label(pill, "", 15, { Position = UDim2.new(1, -46, 0, 0), Size = UDim2.fromOffset(36, 46), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GOLD })

-- status plate
local status = img(hud, "status", { Size = UDim2.fromOffset(316, 92), ScaleType = Enum.ScaleType.Stretch })
local title = label(status, "", 18, { Position = UDim2.fromOffset(0, 9), Size = UDim2.new(1, 0, 0, 24) })
local function bar(y, color)
	local track = img(status, "bar", { Position = UDim2.new(0, 30, 0, y), Size = UDim2.new(1, -60, 0, 22) })
	local inner = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(7, 5), Size = UDim2.new(1, -14, 1, -10), ClipsDescendants = true }, track)
	local fill = new("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, inner)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(185, 185, 185)) }, fill)
	local t = label(track, "", 13, { ZIndex = 5 })
	return fill, t
end
local ageFill, ageText = bar(36, Color3.fromRGB(245, 170, 50))
local evoFill, evoText = bar(61, Color3.fromRGB(110, 205, 60))

local menuRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 56), Size = UDim2.fromOffset(176, 56) }, hud)
local menus = {}
local function menuButton(i, key, icon, text, menuName)
	local b = button(menuRow, key, "", 13, { Position = UDim2.fromOffset((i - 1) * 60, 0), Size = UDim2.fromOffset(56, 56) }, function()
		menus[menuName].Open()
	end)
	img(b.Button, icon, { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(32, 30), ZIndex = 3 })
	b.Label.Position, b.Label.Size = UDim2.fromOffset(0, 33), UDim2.new(1, 0, 0, 18)
	b.Label.Parent:FindFirstChild("Depth").Position = UDim2.fromOffset(0, 35)
	b.Label.Parent:FindFirstChild("Depth").Size = b.Label.Size
	b.SetText(text)
	return b
end
local shopButton = menuButton(1, "green", "iconShop", "Shop", "Shop")
menuButton(2, "amber", "iconDiet", "Diet", "Diet")
menuButton(3, "amber", "iconIndex", "Index", "Index")

-- wide: status centred; narrow: status sits right of the left column so they never touch
local function layout()
	local w = hud.AbsoluteSize.X / hud:FindFirstChildOfClass("UIScale").Scale
	local left = 8 + 176 + 10
	if w / 2 - 158 >= left then
		status.AnchorPoint, status.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 4)
	else
		status.AnchorPoint, status.Position = Vector2.zero, UDim2.fromOffset(left, 4)
	end
end
hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

---------------------------------------------------------------- windows (one open at a time, dim behind)
local menuGui = Kit.screen("EvolutionMenus", 20, playerGui)
local menuRoot = scaledRoot(menuGui)
local openName = nil
local function window(name, titleText)
	local dim = new("TextButton", { Name = name .. "Backdrop", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1 }, menuRoot)
	local w = img(menuRoot, "window", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 340), Visible = false, ZIndex = 2 })
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 340) }, w)
	local sc = new("UIScale", {}, w)
	label(w, titleText, 26, { Position = UDim2.fromOffset(30, 14), Size = UDim2.fromOffset(300, 40), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 231, 168), ZIndex = 4 })
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(28, 72), Size = UDim2.new(1, -56, 1, -100), ZIndex = 3 }, w)
	local m = { Window = w, Content = content }
	function m.Close()
		if openName ~= name then return end
		openName = nil
		dim.Visible, w.Visible = false, false
	end
	function m.Open()
		if openName == name then return end
		if openName then menus[openName].Close() end
		openName = name
		dim.Visible, w.Visible = true, true
		sc.Scale = 0.9
		TweenService:Create(sc, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or 0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if m.OnOpen then m.OnOpen() end
	end
	local close = img(w, "close", { Position = UDim2.new(1, -60, 0, 12), Size = UDim2.fromOffset(44, 44), ZIndex = 5 }, true)
	pressable(close)
	close.Activated:Connect(m.Close)
	dim.Activated:Connect(m.Close)
	menus[name] = m
	return m
end
GuiService.MenuOpened:Connect(function() if openName then menus[openName].Close() end end)

local function hscroll(parent, props)
	local sf = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 4,
		ScrollBarImageColor3 = MUTED, ZIndex = 3, Selectable = false }, parent)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	for k, v in props or {} do sf[k] = v end
	return sf
end
local function vscroll(parent, props)
	local sf = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 4,
		ScrollBarImageColor3 = MUTED, ZIndex = 3, Selectable = false }, parent)
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	for k, v in props or {} do sf[k] = v end
	return sf
end

-- item card: frame art, big item art, name, one-line benefit, green price button
local function card(parent, order, frameKey, itemKey, name, info, onBuy)
	local c = img(parent, frameKey, { LayoutOrder = order, Size = UDim2.fromOffset(110, 196), ZIndex = 3 })
	local art = img(c, itemKey, { Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(74, 66), ZIndex = 4 })
	local n = label(c, name, 15, { Position = UDim2.fromOffset(4, 82), Size = UDim2.new(1, -8, 0, 20), ZIndex = 5, TextScaled = false, TextTruncate = Enum.TextTruncate.AtEnd })
	local i = label(c, info, 13, { Position = UDim2.fromOffset(4, 103), Size = UDim2.new(1, -8, 0, 32), ZIndex = 5, TextColor3 = MUTED, TextWrapped = true })
	local b = button(c, "green", "", 15, { Position = UDim2.fromOffset(9, 140), Size = UDim2.fromOffset(92, 44), ZIndex = 4 }, onBuy)
	return { Card = c, Art = art, Name = n, Info = i, Buy = b }
end

---------------------------------------------------------------- Shop: Upgrades tab (DNA) and Robux tab
local shop = window("Shop", "Shop")
local pages, tabs = {}, {}
local function showTab(which)
	for k, p in pages do p.Visible = k == which end
	for k, t in tabs do t.Button.ImageColor3 = k == which and Color3.new(1, 1, 1) or Color3.fromRGB(140, 125, 110) end
end
for i, t in { { "Upgrades", "Upgrades" }, { "Robux", "Robux" } } do
	tabs[t[1]] = button(shop.Content, "tab", t[2], 16, { Position = UDim2.fromOffset((i - 1) * 132, 0), Size = UDim2.fromOffset(124, 36), ZIndex = 4 }, function() showTab(t[1]) end)
	pages[t[1]] = hscroll(shop.Content, { Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -38), Visible = false })
end
showTab("Upgrades")

local UPGRADES = {
	{ id = "Brain", name = "Bigger Brain", info = "+1 DNA every second", art = "brain" },
	{ id = "Aging", name = "Faster Aging", info = "Shorter lives, faster gens", art = "hourglass" },
	{ id = "Family", name = "Big Family", info = "+1 evolution each gen", art = "cradle" },
}
local upgradeCards = {}
for i, u in UPGRADES do
	upgradeCards[u] = card(pages.Upgrades, i + 1, "cardBrown", u.art, u.name, u.info, function() remotes.Buy:FireServer(u.id) end)
end
local refresh
local confirmUntil = 0
local rebirthCard = card(pages.Upgrades, 9, "cardBrown", "asteroid", "Extinction", "Start over, keep Ancestor DNA", function()
	if os.clock() < confirmUntil then -- second tap within 3 s confirms: this wipes the run
		confirmUntil = 0
		remotes.Rebirth:FireServer()
		shop.Close()
	else
		confirmUntil = os.clock() + 3
		refresh()
		task.delay(3, refresh)
	end
end)

local ROBUX_ART = {
	DoubleDNA = { "cardBrown", "dna2" }, FastLife = { "cardBrown", "stopwatch" }, VIP = { "cardGold", "crown" },
	OfflinePlus = { "cardBrown", "moon" }, Skip5 = { "cardTeal", "skip" }, Skip20 = { "cardTeal", "skip" }, DNAPack = { "cardTeal", "jar" },
}
local SHORT = { DoubleDNA = "Double DNA forever", FastLife = "Lives 30% shorter", VIP = "+25% DNA, gold graves",
	OfflinePlus = "Evolve 24h offline", Skip5 = "5 lives right now", Skip20 = "20 lives, best value", DNAPack = "10 minutes of DNA" }
local CARD_NAME = { FastLife = "Fast Life", OfflinePlus = "Long Nap" } -- cards fit ~12 letters at 15 pt
local robuxCards = {}
local VIP_FIRST = { VIP = 0 } -- hero item first
for i, entry in (remotes:GetAttribute("Store") or ""):split(";") do
	local key, kind, itemName = table.unpack(entry:split("|"))
	if key and key ~= "" then
		local a = ROBUX_ART[key] or { "cardBrown", "jar" }
		local c = card(pages.Robux, VIP_FIRST[key] or i, a[1], a[2], CARD_NAME[key] or itemName, SHORT[key] or "", function() remotes.BuyRobux:FireServer(key) end)
		robuxCards[key] = { kind = kind, card = c }
	end
end
local function refreshRobux()
	local prices = {}
	for _, entry in (remotes:GetAttribute("Store") or ""):split(";") do
		local parts = entry:split("|")
		prices[parts[1]] = parts[5]
	end
	local passes = "," .. (player:GetAttribute("Passes") or "") .. ","
	for key, r in robuxCards do
		local owned = r.kind == "pass" and passes:find("," .. key .. ",", 1, true) ~= nil
		r.card.Card.ImageColor3 = owned and Color3.fromRGB(150, 140, 130) or Color3.new(1, 1, 1)
		r.card.Art.ImageTransparency = owned and 0.45 or 0
		r.card.Buy.SetEnabled(not owned, owned and "Owned" or (ROBUX .. " " .. (prices[key] or "?")))
	end
end
remotes:GetAttributeChangedSignal("Store"):Connect(refreshRobux)
player:GetAttributeChangedSignal("Passes"):Connect(refreshRobux)
refreshRobux()

---------------------------------------------------------------- Diet
local diet = window("Diet", "Diet")
local DIETS = {
	{ id = "Fruit", info = "Shorter kids. Risk: malnutrition", unlock = "Monkey" },
	{ id = "Meat", info = "Taller kids. Risk: parasites", unlock = "Ape" },
	{ id = "Cooked", info = "Tallest kids. Low risk", unlock = "Homo erectus" },
	{ id = "Farmed", info = "Tall kids. Safest", unlock = "Homo sapiens" },
	{ id = "Synthetic", info = "Giant kids. Risk: nanobot glitch", unlock = "Cyborg" },
}
local dietList = vscroll(diet.Content)
local dietRows = {}
for i, d in DIETS do
	local r = img(dietList, "row", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 58), ZIndex = 3 })
	label(r, d.id, 17, { Position = UDim2.fromOffset(16, 7), Size = UDim2.new(1, -140, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local info = label(r, d.info, 13, { Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -140, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = MUTED, ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
	local b = button(r, "green", "Eat", 16, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(104, 42), ZIndex = 4 }, function()
		remotes.Diet:FireServer(d.id)
	end)
	dietRows[d] = { info = info, button = b }
end

---------------------------------------------------------------- Family Index
local index = window("Index", "Family Index")
local indexList = vscroll(index.Content)
local function has(list, item) return ("," .. (list or "") .. ","):find("," .. item .. ",", 1, true) ~= nil end
local sections = {}
local function section(order, titleText, entries, cellW)
	local holder = new("Frame", { BackgroundTransparency = 1, LayoutOrder = order * 2 - 1, Size = UDim2.new(1, -8, 0, 26), ZIndex = 3 }, indexList)
	local header = label(holder, titleText, 17, { TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 5 })
	local grid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order * 2, ZIndex = 3 }, indexList)
	new("UIGridLayout", { CellSize = UDim2.new(1 / cellW, -6, 0, 46), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
	local sec = { header = header, title = titleText, tiles = {} }
	for i, e in entries do
		local tile = img(grid, "row", { LayoutOrder = i, ZIndex = 3 })
		tile.SliceScale = 0.14
		e.label = label(tile, "", 13, { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), ZIndex = 5, TextWrapped = true })
		table.insert(sec.tiles, e)
	end
	table.insert(sections, sec)
end
local function entries(attr, sep, prefix, color)
	local out = {}
	for _, item in (remotes:GetAttribute(attr) or ""):split(sep) do
		local name, desc = table.unpack(item:split("|"))
		if name and name ~= "" then table.insert(out, { key = prefix .. name, name = name, desc = desc, color = color }) end
	end
	return out
end
section(1, "Species", entries("AllSpecies", ",", "S:", Color3.fromRGB(150, 230, 110)), 4)
section(2, "Mutations", entries("AllTraits", ",", "T:", Color3.fromRGB(205, 150, 255)), 4)
section(3, "Diseases", entries("AllDiseases", ",", "D:", Color3.fromRGB(255, 130, 110)), 4)
section(4, "Badges", entries("AllBadges", ";", "B:", GOLD), 2)

---------------------------------------------------------------- refresh (on attribute change, not every frame)
refresh = function()
	local a = player:GetAttributes()
	if not a.Species then return end
	title.Text = ("%s  ·  Gen %d"):format(a.Species, a.Gen)
	if a.NextSpecies == "" then
		evoFill.Size = UDim2.fromScale(1, 1)
		evoText.Text = "Fully evolved!"
	else
		evoFill.Size = UDim2.fromScale(math.clamp((a.Evo - a.PrevAt) / (a.NextAt - a.PrevAt), 0, 1), 1)
		evoText.Text = ("Next: %s  %d/%d"):format(a.NextSpecies, a.Evo, a.NextAt)
	end
	dnaText.Text = Kit.abbrev(a.DNA or 0)
	local mult = a.DnaMult or 1
	multText.Text = mult > 1 and ("x%.2g"):format(mult) or ""

	local canBuy = false
	for u, c in upgradeCards do
		local cost = a[u.id .. "Cost"] or 0
		c.Name.Text = ("%s %d"):format(u.name:match("%S+$"), a[u.id] or 0) -- "Brain 3": short enough for the card
		if (a.DNA or 0) >= cost then
			canBuy = true
			c.Buy.SetEnabled(true, Kit.abbrev(cost))
		else
			c.Buy.SetEnabled(false, Kit.abbrev(cost))
		end
	end
	if a.CanRebirth then
		rebirthCard.Info.Text = ("Restart, keep +%d Ancestor DNA"):format(a.RebirthGain or 0)
		rebirthCard.Buy.SetEnabled(true, os.clock() < confirmUntil and "Sure?" or "Rebirth")
	else
		rebirthCard.Info.Text = "Unlocks at Modern Human"
		rebirthCard.Buy.SetEnabled(false, "Locked")
	end
	shopButton.Label.TextColor3 = (canBuy or a.CanRebirth) and GOLD or CREAM -- gold label = something to buy

	local unlocked = "," .. (a.Diets or "") .. ","
	for d, r in dietRows do
		if not unlocked:find("," .. d.id .. ",", 1, true) then
			r.info.Text = "Unlocks at " .. d.unlock
			r.button.SetEnabled(false, "Locked")
		else
			r.info.Text = d.info
			r.button.SetEnabled(true, a.Diet == d.id and "Eating" or "Eat")
			r.button.SetArt(a.Diet == d.id and "amber" or "green")
		end
	end

	for _, sec in sections do
		local found = 0
		for _, e in sec.tiles do
			local got = if e.key:sub(1, 2) == "B:" then has(a.Badges, e.name) else has(a.Index, e.key)
			if got then found += 1 end
			e.label.Text = if e.desc then e.name .. "\n" .. e.desc else (got and e.name or "???")
			e.label.TextColor3 = got and e.color or MUTED
		end
		sec.header.Text = ("%s  %d/%d"):format(sec.title, found, #sec.tiles)
	end
end
player.AttributeChanged:Connect(refresh)
refresh()

-- only the age bar moves every frame
RunService.RenderStepped:Connect(function()
	local start, len = player:GetAttribute("LifeStart"), player:GetAttribute("LifeLen")
	if not (start and len) then return end
	local age = math.clamp((workspace:GetServerTimeNow() - start) / len, 0, 1)
	ageFill.Size = UDim2.fromScale(age, 1)
	local phase = age < 0.35 and "Child" or age < 0.8 and "Adult" or "Elder"
	ageText.Text = ("%s  ·  %ds left"):format(phase, math.ceil(len * (1 - age)))
end)

---------------------------------------------------------------- news: one toast at a time, biggest news first
-- DisplayOrder 15: above the HUD, under open menus, so news never covers a menu you're using
local toastGui = Kit.screen("EvolutionToasts", 15, playerGui)
local toastRoot = scaledRoot(toastGui)
local STYLES = {
	{ find = "asteroid", priority = 10, color = Color3.fromRGB(255, 130, 110), hold = 3.5 },
	{ find = "evolved", priority = 10, color = GOLD, hold = 3.5 },
	{ find = "Badge", priority = 9, color = GOLD, hold = 3 },
	{ find = "Thank you", priority = 9, color = DNA_C, hold = 3 },
	{ find = "entered the", priority = 7, color = Color3.fromRGB(140, 200, 255), hold = 3 },
	{ find = "Mutation", priority = 6, color = Color3.fromRGB(205, 150, 255) },
	{ find = "Caught", priority = 5, color = Color3.fromRGB(255, 130, 110) },
}
local queue, showing, seq = {}, false, 0
local function showNext()
	if showing or #queue == 0 then return end
	table.sort(queue, function(x, y) return x.priority > y.priority or (x.priority == y.priority and x.seq < y.seq) end)
	local item = table.remove(queue, 1)
	showing = true
	local t = img(toastRoot, "row", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -70), Size = UDim2.fromOffset(380, 52), ZIndex = 10 })
	label(t, item.text, 17, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), TextColor3 = item.color or CREAM, ZIndex = 12, TextTruncate = Enum.TextTruncate.AtEnd })
	TweenService:Create(t, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or 0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 104) }):Play()
	task.delay(item.hold or 2.2, function()
		TweenService:Create(t, TweenInfo.new(0.2), { Position = UDim2.new(0.5, 0, 0, -70) }):Play()
		task.wait(0.22)
		t:Destroy()
		showing = false
		showNext()
	end)
end
remotes.Notify.OnClientEvent:Connect(function(msg)
	for _, line in msg:split("\n") do
		local style = { priority = 1 }
		for _, s in STYLES do
			if line:find(s.find, 1, true) then style = s break end
		end
		seq += 1
		table.insert(queue, { text = line, priority = style.priority, color = style.color, hold = style.hold, seq = seq })
		while #queue > 6 do table.remove(queue) end -- drop the least important when news piles up
	end
	showNext()
end)
