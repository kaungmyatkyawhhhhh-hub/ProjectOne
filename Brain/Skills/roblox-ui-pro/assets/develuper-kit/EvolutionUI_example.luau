-- HUD + Shop (Upgrades / Robux cards) + Diet + Family Index, drawn in Develuper's "UI 10x" style (values measured off his frames;
-- generator + params in the vault: EVOLVE/Assets/UI art/develuper-exact).
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

---------------------------------------------------------------- art (uploaded 18 Nov, Develuper "Neon kit" skin: kitgen.html?skin=neon)
-- every PNG is drawn at 2 px per design point with a transparent margin: rect = {x, y, w, h} trims it (ImageRect),
-- slice = {left, top, right, bottom} insets in px inside that rect; SliceScale 0.5 turns px back into points
local PX = 0.5
local ART = {
	btnGreen = { id = 99152619942938, rect = { 4, 4, 200, 104 }, slice = { 24, 24, 24, 45 } },
	btnGreenW = { id = 122607256932016, rect = { 4, 4, 224, 100 }, slice = { 23, 23, 23, 43 } },
	btnGreenSq = { id = 134991785436106, rect = { 2, 2, 132, 132 }, slice = { 30, 30, 30, 56 } },
	btnYellowW = { id = 101786149004135, rect = { 4, 4, 224, 100 }, slice = { 23, 23, 23, 43 } },
	btnYellowSq = { id = 127397210538281, rect = { 2, 2, 132, 132 }, slice = { 30, 30, 30, 56 } },
	tab = { id = 103209281537164, rect = { 5, 5, 262, 86 }, slice = { 20, 20, 20, 37 } },
	close = { id = 99979308862490, rect = { 4, 5, 208, 94 }, slice = { 22, 22, 22, 41 } },
	header = { id = 86356717734007, rect = { 2, 2, 480, 124 }, slice = { 28, 28, 28, 53 } },
	window = { id = 71497684952255, rect = { 4, 4, 416, 296 }, slice = { 46, 46, 46, 46 } },
	dnaPill = { id = 114080700329192, rect = { 3, 3, 370, 110 }, slice = { 25, 25, 25, 47 } },
	status = { id = 110219725577619, rect = { 2, 2, 652, 204 }, slice = { 29, 29, 29, 49 } },
	row = { id = 113152138086851, rect = { 6, 6, 972, 128 }, slice = { 19, 19, 19, 31 } },
	toast = { id = 107751349187669, rect = { 6, 6, 772, 116 }, slice = { 17, 17, 17, 28 } },
	barTrack = { id = 95750994020821, rect = { 8, 8, 520, 52 }, slice = { 13, 13, 13, 23 } },
	cardYellow = { id = 92349994686051, rect = { 7, 7, 230, 402 }, slice = { 18, 18, 18, 31 } },
	cardMagenta = { id = 125816991334707, rect = { 7, 7, 230, 402 }, slice = { 18, 18, 18, 31 } },
	cardPurple = { id = 78767308581492, rect = { 7, 7, 230, 402 }, slice = { 18, 18, 18, 31 } },
	cardGreen = { id = 117491775654576, rect = { 7, 7, 230, 402 }, slice = { 18, 18, 18, 31 } },
	cardCyan = { id = 124570689040785, rect = { 7, 7, 230, 402 }, slice = { 18, 18, 18, 31 } },
	cardHero = { id = 88565839554030, rect = { 4, 4, 356, 408 }, slice = { 27, 27, 27, 47 } },
	shop = { id = 121083340817415, rect = { 25, 35, 174, 171 } },
	diet = { id = 140061570538941, rect = { 33, 21, 158, 187 } },
	index = { id = 122362092196907, rect = { 39, 34, 146, 174 } },
	dna = { id = 121018262359959, rect = { 52, 16, 120, 194 } },
	dna2 = { id = 88562094120605, rect = { 52, 16, 163, 194 } },
	brain = { id = 95410346968628, rect = { 27, 34, 170, 168 } },
	hourglass = { id = 96754064179147, rect = { 43, 23, 138, 187 } },
	cradle = { id = 88315436635336, rect = { 31, 38, 162, 172 } },
	asteroid = { id = 78866937695851, rect = { 25, 31, 164, 159 } },
	stopwatch = { id = 75626916184309, rect = { 36, 12, 152, 207 } },
	crown = { id = 117822713580440, rect = { 27, 43, 170, 159 } },
	moon = { id = 118256929964343, rect = { 34, 30, 149, 168 } },
	skip = { id = 101437450811165, rect = { 30, 50, 172, 152 } },
	jar = { id = 123272377840378, rect = { 46, 35, 132, 175 } },
	clover = { id = 110098495099896, rect = { 50, 50, 124, 158 } },
	shield = { id = 96363517409622, rect = { 34, 21, 156, 189 } },
	-- HUD in the owner's ChatGPT-mock look (hud.html, uploaded 18 Nov)
	hudPlate = { id = 99387855322055, rect = { 7, 7, 670, 266 } },
	dnaPlate = { id = 131431574744300, rect = { 7, 7, 362, 102 } },
	plate9 = { id = 102036198893418, rect = { 7, 7, 250, 130 }, slice = { 41, 41, 41, 45 } },
	slot = { id = 88980806970695, rect = { 11, 12, 242, 48 }, slice = { 21, 20, 21, 20 } },
	miniTrack = { id = 80304283470164, rect = { 12, 12, 160, 28 }, slice = { 14, 14, 14, 14 } },
	fillGold = { id = 110420409866117, rect = { 12, 12, 80, 28 }, slice = { 14, 14, 14, 14 } },
	titleBand = { id = 127097984147022, rect = { 12, 12, 460, 64 } },
	sqGreen = { id = 95825050705850, rect = { 7, 7, 130, 130 } },
	sqBlue = { id = 140649401825975, rect = { 7, 7, 130, 130 } },
	sqPurple = { id = 83791679223440, rect = { 7, 7, 130, 130 } },
	chevron = { id = 130338925901928, rect = { 18, 34, 148, 156 } },
	stall = { id = 90821629593898, rect = { 26, 26, 172, 182 } },
	magnet = { id = 134837634359789, rect = { 47, 10, 130, 198 } },
	port1 = { id = 83511662512157, rect = { 7, 7, 138, 150 } },
	port2 = { id = 101610475812861, rect = { 7, 7, 138, 150 } },
	port3 = { id = 139949073882603, rect = { 7, 7, 138, 150 } },
	port4 = { id = 74015997624824, rect = { 7, 7, 138, 150 } },
	port5 = { id = 116672581162680, rect = { 7, 7, 138, 150 } },
	port6 = { id = 125623672238165, rect = { 7, 7, 138, 150 } },
	port7 = { id = 122085693687516, rect = { 7, 7, 138, 150 } },
	port8 = { id = 89985532690390, rect = { 7, 7, 138, 150 } },
	port9 = { id = 71216777393119, rect = { 7, 7, 138, 150 } },
	port10 = { id = 87728832487266, rect = { 7, 7, 138, 150 } },
	port11 = { id = 112027057344929, rect = { 7, 7, 138, 150 } },
	port12 = { id = 98207495064814, rect = { 7, 7, 138, 150 } },
}
local INK = Color3.new(0, 0, 0)
local CREAM = Color3.new(1, 1, 1) -- his text is pure white with a black stroke
local MUTED = Color3.fromRGB(205, 205, 215)
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
	o.ImageRectOffset, o.ImageRectSize = Vector2.new(a.rect[1], a.rect[2]), Vector2.new(a.rect[3], a.rect[4])
	if a.slice then
		o.ScaleType = Enum.ScaleType.Slice
		o.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.rect[3] - a.slice[3], a.rect[4] - a.slice[4])
		o.SliceScale = PX
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
	l:GetPropertyChangedSignal("Text"):Connect(function() shadow.Text = (l.Text:gsub("<[^>]+>", "")) end)
	l:GetPropertyChangedSignal("Visible"):Connect(function() shadow.Visible = l.Visible end)
	return l
end

-- one sound per moment (kid sim: 5-6-year-olds read too slowly, a sound tells them big news landed)
local SoundService = game:GetService("SoundService")
local SFX = {}
for _, k in { "click", "pickup", "evolve", "news" } do -- inserted in SoundService (Creator Store audio must be in the place to load)
	SFX[k] = SoundService:WaitForChild("SFX_" .. k, 10)
end
local function play(k) if SFX[k] then SoundService:PlayLocalSound(SFX[k]) end end

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
	b.Activated:Connect(function() if enabled then play("click") onClick() end end)
	return {
		Button = b, Label = l,
		SetText = function(t) l.Text = t end,
		SetEnabled = function(on, t)
			enabled = on
			b.ImageColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 128)
			l.TextColor3 = on and CREAM or MUTED
			if t then l.Text = t end
		end,
		SetArt = function(key)
			local a = ART[key]
			b.Image, b.ImageRectOffset, b.ImageRectSize = uri(a), Vector2.new(a.rect[1], a.rect[2]), Vector2.new(a.rect[3], a.rect[4])
			if a.slice then b.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.rect[3] - a.slice[3], a.rect[4] - a.slice[4]) end
		end,
	}
end

---------------------------------------------------------------- root: a 720x360 design scaled to fit the screen
local function scaledRoot(gui)
	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1 }, gui)
	local s = new("UIScale", {}, root)
	local function fit()
		local v = gui.AbsoluteSize
		local k = math.clamp(math.min(v.X / 760, v.Y / 400), 0.72, 1.2) -- owner on PC: "i cannot see at all" at 1.7x; big screens get more game, not bigger UI
		s.Scale = k
		root.Size = UDim2.fromOffset(v.X / k, v.Y / k)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return root
end

local hudGui = Kit.screen("EvolutionHUD", 10, playerGui)
local hud = scaledRoot(hudGui)

-- DNA counter: the helix breaks out of the plate (mock look)
local pill = img(hud, "dnaPlate", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(181, 51) })
img(pill, "dna", { Position = UDim2.fromOffset(-4, -9), Size = UDim2.fromOffset(42, 62), ZIndex = 3 })
local dnaText = label(pill, "", 22, { Position = UDim2.fromOffset(44, 0), Size = UDim2.fromOffset(62, 47), TextXAlignment = Enum.TextXAlignment.Left })
local multText = label(pill, "", 15, { Position = UDim2.fromOffset(104, 0), Size = UDim2.fromOffset(36, 47), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GOLD })
local pillScale = new("UIScale", {}, pill)
local menus = {}
button(pill, "sqGreen", "+", 22, { Position = UDim2.fromOffset(145, 9), Size = UDim2.fromOffset(30, 30), ZIndex = 4 }, function()
	menus.Shop.Open()
	menus.Shop.ShowTab("Robux")
end)

-- status plate: gold hex portrait of your species, title on a brush band, two slot rows with icons
local status = img(hud, "hudPlate", { Size = UDim2.fromOffset(335, 133) })
local statusScale = new("UIScale", {}, status) -- 0.8 on big screens (PC), 1 on phones so row text stays >= 13 px
local toastX, toastY = 214, 118 -- news sits under the status plate in the top-left corner; set by layout()
local portrait = img(status, "port1", { Position = UDim2.fromOffset(-8, -8), Size = UDim2.fromOffset(66, 72), ZIndex = 4 })
img(status, "titleBand", { Position = UDim2.fromOffset(62, 12), Size = UDim2.fromOffset(250, 34), ZIndex = 2 })
local title = label(status, "", 22, { Position = UDim2.fromOffset(62, 12), Size = UDim2.fromOffset(250, 32), RichText = true })
local function slotRow(y, icon)
	local r = img(status, "slot", { Position = UDim2.fromOffset(20, y), Size = UDim2.fromOffset(298, 26), ZIndex = 2 })
	img(r, icon, { Position = UDim2.fromOffset(5, 2), Size = UDim2.fromOffset(22, 22), ZIndex = 3 })
	return r
end
local ageRow, evoRow = slotRow(62, "hourglass"), slotRow(90, "chevron")
local ageTrack = img(ageRow, "miniTrack", { Position = UDim2.fromOffset(32, 6), Size = UDim2.fromOffset(110, 14), ZIndex = 3 })
local ageFill = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1), ClipsDescendants = true, ZIndex = 4 }, ageTrack)
img(ageFill, "fillGold", { Size = UDim2.fromOffset(110, 14), ZIndex = 4 })
local ageText = label(ageRow, "", 14, { Position = UDim2.fromOffset(146, 0), Size = UDim2.new(1, -150, 1, 0), ZIndex = 5 })
local evoText = label(evoRow, "", 15, { Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -40, 1, 0), ZIndex = 5, RichText = true })
local function portraitKey(g) return "port" .. math.clamp(tonumber(g) or 1, 1, 12) end -- species group 1..12 (server "Portrait")

-- one colour per menu button, like the mock: green shop, blue diet, purple index
local menuRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 66), Size = UDim2.fromOffset(194, 65) }, hud)
local function menuButton(i, key, icon, text, menuName)
	local b = button(menuRow, key, "", 15, { Position = UDim2.fromOffset((i - 1) * 66, 0), Size = UDim2.fromOffset(62, 62) }, function()
		menus[menuName].Open()
	end)
	img(b.Button, icon, { Position = UDim2.fromOffset(9, 2), Size = UDim2.fromOffset(44, 38), ZIndex = 3 })
	b.Label.Position, b.Label.Size = UDim2.fromOffset(0, 36), UDim2.new(1, 0, 0, 20)
	b.Label.Parent:FindFirstChild("Depth").Position = UDim2.fromOffset(0, 37)
	b.Label.Parent:FindFirstChild("Depth").Size = b.Label.Size
	b.SetText(text)
	return b
end
local shopButton = menuButton(1, "sqGreen", "stall", "Shop", "Shop")
menuButton(2, "sqBlue", "diet", "Diet", "Diet")
menuButton(3, "sqPurple", "index", "Index", "Index")

-- wide: status centred; narrow: status sits right of the left column so they never touch
local function layout()
	local left = 8 + 194 + 12
	statusScale.Scale = hud:FindFirstChildOfClass("UIScale").Scale >= 1.1 and 0.8 or 1
	toastX, toastY = left, 6 + math.ceil(133 * statusScale.Scale) + 6
	-- top-left corner, never centred: the owner's friends found a big plate in the middle of the screen annoying
	status.AnchorPoint, status.Position = Vector2.zero, UDim2.fromOffset(left, 6)
end
hud:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()

---------------------------------------------------------------- windows (one open at a time, dim behind)
local menuGui = Kit.screen("EvolutionMenus", 20, playerGui)
local menuRoot = scaledRoot(menuGui)
local openName = nil
local news = {} -- set by the toast queue below: windows pause news so it never plays hidden behind them
local function window(name, titleText, iconKey)
	local dim = new("TextButton", { Name = name .. "Backdrop", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 1 }, menuRoot)
	local w = img(menuRoot, "plate9", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 300), Visible = false, ZIndex = 2 }) -- 300 + the 22 pt title overhang fits a 360-pt-tall phone
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 300) }, w)
	local sc = new("UIScale", {}, w)
	-- his "STORE!" bar: green, overlapping the panel's top-left, big title + icon after the text
	local bar = img(w, "header", { Position = UDim2.fromOffset(-10, -22), Size = UDim2.fromOffset(230, 52), ZIndex = 4 })
	local t = label(bar, titleText .. "!", 28, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -60, 1, -10), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
	local ic = img(bar, iconKey, { Position = UDim2.new(0, 22 + t.TextBounds.X, 0, -4), Size = UDim2.fromOffset(42, 42), ZIndex = 7 })
	t:GetPropertyChangedSignal("TextBounds"):Connect(function() ic.Position = UDim2.new(0, 22 + t.TextBounds.X, 0, -4) end)
	local content = new("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 42), Size = UDim2.new(1, -40, 1, -58), ZIndex = 3 }, w)
	local m = { Window = w, Content = content }
	function m.Close()
		if openName ~= name then return end
		openName = nil
		dim.Visible, w.Visible = false, false
		task.defer(news.resume) -- deferred: switching windows re-opens one before this runs
	end
	function m.Open()
		if openName == name then return end
		if openName then menus[openName].Close() end
		openName = name
		news.pause()
		dim.Visible, w.Visible = true, true
		sc.Scale = 0.9
		TweenService:Create(sc, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or 0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		if m.OnOpen then m.OnOpen() end
	end
	-- his red "Close" text button, top-right, overlapping like the title bar
	button(w, "close", "Close", 20, { Position = UDim2.new(1, -86, 0, -20), Size = UDim2.fromOffset(96, 40), ZIndex = 5 }, m.Close)
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
	local wide = frameKey == "cardHero"
	local c = img(parent, frameKey, { LayoutOrder = order, Size = UDim2.fromOffset(wide and 170 or 110, 196), ZIndex = 3 })
	local n = label(c, name, wide and 18 or 15, { Position = UDim2.fromOffset(4, 5), Size = UDim2.new(1, -8, 0, 22), ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
	local art = img(c, itemKey, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), Size = UDim2.fromOffset(wide and 110 or 76, 70), ZIndex = 4 })
	local i = label(c, info, 13, { Position = UDim2.fromOffset(5, 100), Size = UDim2.new(1, -10, 0, 34), ZIndex = 5, TextWrapped = true })
	local b = button(c, wide and "btnGreenW" or "btnGreen", "", 15, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.fromOffset(wide and 140 or 92, 44), ZIndex = 4 }, onBuy)
	return { Card = c, Art = art, Name = n, Info = i, Buy = b }
end

---------------------------------------------------------------- Shop: Upgrades tab (DNA) and Robux tab
local shop = window("Shop", "Shop", "stall")
local pages, tabs = {}, {}
local function showTab(which)
	for k, p in pages do p.Visible = k == which end
	for k, t in tabs do t.Button.ImageColor3 = k == which and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 160) end
end
for i, t in { { "Upgrades", "Upgrades" }, { "Robux", "Robux" } } do
	tabs[t[1]] = button(shop.Content, "tab", t[2], 17, { Position = UDim2.fromOffset((i - 1) * 132, 0), Size = UDim2.fromOffset(124, 36), ZIndex = 4 }, function() showTab(t[1]) end)
	pages[t[1]] = hscroll(shop.Content, { Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -38), Visible = false })
end
showTab("Upgrades")
shop.ShowTab = showTab

local UPGRADES = {
	{ id = "Brain", name = "Bigger Brain", info = "+1 DNA every second", art = "brain" },
	{ id = "Aging", name = "Faster Aging", info = "Shorter lives, faster gens", art = "hourglass" },
	{ id = "Family", name = "Big Family", info = "+1 evolution each gen", art = "cradle" },
	{ id = "Luck", name = "Lucky Genes", short = "Luck", info = "+4% mutation chance", art = "clover" },
	{ id = "Immunity", name = "Immunity", info = "Less disease each level", art = "shield" },
}
local upgradeCards = {}
for i, u in UPGRADES do
	upgradeCards[u] = card(pages.Upgrades, i + 1, "cardCyan", u.art, u.name, u.info, function() remotes.Buy:FireServer(u.id) end)
end
local refresh
local confirmUntil = 0
local rebirthCard = card(pages.Upgrades, 9, "cardMagenta", "asteroid", "Extinction", "Start over, keep Ancestor DNA", function()
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
	-- colour = tier, like his store: hero yellow, epic magenta, rare purple, cash-style cyan, common green
	DoubleDNA = { "cardMagenta", "dna2" }, FastLife = { "cardPurple", "stopwatch" }, VIP = { "cardHero", "crown" },
	OfflinePlus = { "cardPurple", "moon" }, Skip5 = { "cardCyan", "skip" }, Skip20 = { "cardCyan", "skip" }, DNAPack = { "cardGreen", "jar" },
	SuperGenes = { "cardMagenta", "clover" }, Magnet = { "cardCyan", "magnet" },
}
local SHORT = { DoubleDNA = "Double DNA forever", FastLife = "Lives 30% shorter", VIP = "+25% DNA, gold graves",
	OfflinePlus = "Evolve 24h offline", Skip5 = "5 lives right now", Skip20 = "20 lives, best value", DNAPack = "10 minutes of DNA",
	SuperGenes = "2x mutations, keep good genes", Magnet = "Pulls in orbs near you" }
local CARD_NAME = { FastLife = "Fast Life", OfflinePlus = "Long Nap", SuperGenes = "Super Genes", Magnet = "DNA Magnet", Skip5 = "Skip 5 Lives", Skip20 = "Skip 20 Lives" } -- cards fit ~12 letters at 15 pt
local robuxCards = {}
local VIP_FIRST = { VIP = 0 } -- hero item first
for i, entry in (remotes:GetAttribute("Store") or ""):split(";") do
	local key, kind, itemName = table.unpack(entry:split("|"))
	if key and key ~= "" then
		local a = ROBUX_ART[key] or { "cardGreen", "jar" }
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
		r.card.Card.ImageColor3 = owned and Color3.fromRGB(150, 150, 160) or Color3.new(1, 1, 1)
		r.card.Art.ImageTransparency = owned and 0.45 or 0
		r.card.Buy.SetEnabled(not owned, owned and "Owned" or (ROBUX .. " " .. (prices[key] or "?")))
	end
end
remotes:GetAttributeChangedSignal("Store"):Connect(refreshRobux)
player:GetAttributeChangedSignal("Passes"):Connect(refreshRobux)
refreshRobux()

---------------------------------------------------------------- Diet
local diet = window("Diet", "Diet", "diet")
local DIETS = {
	{ id = "Fruit", info = "Shorter kids. Risk: malnutrition", unlock = "Monkey" },
	{ id = "Meat", info = "Taller kids. Risk: parasites", unlock = "stage 9" },
	{ id = "Cooked", info = "Tallest kids. Low risk", unlock = "Homo erectus" },
	{ id = "Farmed", info = "Tall kids. Safest", unlock = "Farmer" },
	{ id = "Synthetic", info = "Giant kids. Risk: nanobot glitch", unlock = "stage 61" },
}
local dietList = vscroll(diet.Content)
local dietRows = {}
for i, d in DIETS do
	local r = img(dietList, "row", { LayoutOrder = i, Size = UDim2.new(1, -8, 0, 58), ZIndex = 3 })
	label(r, d.id, 17, { Position = UDim2.fromOffset(16, 7), Size = UDim2.new(1, -140, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local info = label(r, d.info, 13, { Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -140, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = MUTED, ZIndex = 5, TextTruncate = Enum.TextTruncate.AtEnd })
	local b = button(r, "btnGreenW", "Eat", 16, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(104, 42), ZIndex = 4 }, function()
		remotes.Diet:FireServer(d.id)
	end)
	dietRows[d] = { info = info, button = b }
end

---------------------------------------------------------------- Family Index
local index = window("Index", "Index", "index")
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
		if e.g then -- species: group portrait, a dark silhouette until found (dex-style "who's that?")
			e.port = img(tile, "port" .. e.g, { Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(34, 37), ZIndex = 4 })
		end
		e.label = label(tile, "", 13, { Position = UDim2.fromOffset(e.g and 40 or 8, 0), Size = UDim2.new(1, e.g and -44 or -16, 1, 0), ZIndex = 5, TextWrapped = true })
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
local speciesList = entries("AllSpecies", ",", "S:", Color3.fromRGB(150, 230, 110))
for i, g in (remotes:GetAttribute("SpeciesGroups") or ""):split(",") do
	if speciesList[i] then speciesList[i].g = math.clamp(tonumber(g) or 1, 1, 12) end
end
for i, p in (remotes:GetAttribute("SpeciesPaths") or ""):split(",") do -- locked tiles say which path to try
	if speciesList[i] and p ~= "" then speciesList[i].path = p end
end
local secretList = entries("AllSecrets", ";", "X:", Color3.fromRGB(255, 120, 220))
for _, e in secretList do e.secret = true end
section(1, "Species", speciesList, 4)
section(2, "Mutations", entries("AllTraits", ",", "T:", Color3.fromRGB(205, 150, 255)), 4)
section(3, "Diseases", entries("AllDiseases", ",", "D:", Color3.fromRGB(255, 130, 110)), 4)
section(4, "Badges", entries("AllBadges", ";", "B:", GOLD), 2)
section(5, "Secrets", secretList, 2) -- riddle clues only, until found

---------------------------------------------------------------- World pill: everyone, on every server, grows one world together
-- The bar fills with every life anyone lives; each World Age = +5% DNA for all players.
local worldPill = img(hud, "slot", { Position = UDim2.fromOffset(8, 134), Size = UDim2.fromOffset(194, 44), ZIndex = 2 })
local worldText = label(worldPill, "", 14, { Position = UDim2.fromOffset(8, 3), Size = UDim2.fromOffset(178, 20), RichText = true, ZIndex = 5 })
local worldTrack = img(worldPill, "miniTrack", { Position = UDim2.fromOffset(8, 24), Size = UDim2.fromOffset(178, 14), ZIndex = 3 })
local worldFill = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1), ClipsDescendants = true, ZIndex = 4 }, worldTrack)
img(worldFill, "fillGold", { Size = UDim2.fromOffset(178, 14), ZIndex = 4 })
local worldFirsts = {}
local function refreshWorld()
	local age, g = remotes:GetAttribute("WorldAge") or 0, remotes:GetAttribute("WorldGens") or 0
	local prev, nxt = remotes:GetAttribute("WorldPrev") or 0, remotes:GetAttribute("WorldNext") or -1
	worldText.Text = ('World Age %d   <font color="#FFD23F">+%d%% DNA</font>'):format(age, age * 5)
	worldFill.Size = UDim2.fromScale(nxt > prev and math.clamp((g - prev) / (nxt - prev), 0, 1) or 1, 1)
	pcall(function() worldFirsts = game:GetService("HttpService"):JSONDecode(remotes:GetAttribute("WorldFirsts") or "{}") end)
end
refreshWorld()
remotes.AttributeChanged:Connect(function(k)
	if k:sub(1, 5) == "World" then
		refreshWorld()
		if k == "WorldFirsts" and refresh then refresh() end
	end
end)

---------------------------------------------------------------- Path picker: the forks of the evolution tree
-- Opens by itself (once per life) while you can pick, never over another window or the evolve banner.
local FORKS = {}
pcall(function() FORKS = game:GetService("HttpService"):JSONDecode(remotes:GetAttribute("Forks") or "[]") end)
local pathWin = window("Path", "Pick a path", "chevron")
local pathTitle = label(pathWin.Content, "", 18, { Size = UDim2.new(1, 0, 0, 26), TextColor3 = GOLD, ZIndex = 5 })
local pathList = hscroll(pathWin.Content, { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32) })
pathList:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Center
local LANE_FRAMES = { "cardGreen", "cardCyan", "cardPurple" }
local function showFork(id)
	for _, c in pathList:GetChildren() do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	for _, f in FORKS do
		if f.id == id then
			pathTitle.Text = f.title
			for i, l in f.lanes do
				local c = card(pathList, i, LANE_FRAMES[i] or "cardGreen", "port" .. l.g, l.name, l.info .. "\nFirst: " .. l.first, function()
					remotes.ChooseFork:FireServer(id, l.key)
					pathWin.Close()
				end)
				c.Art.Size = UDim2.fromOffset(64, 70)
				c.Buy.SetEnabled(true, "Pick!")
			end
		end
	end
end
local function openPath()
	local id = player:GetAttribute("ForkPending") or ""
	if id == "" then return false end
	showFork(id)
	pathWin.Open()
	return true
end
local evoTap = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6, Visible = false }, evoRow)
evoTap.Activated:Connect(openPath)
local pathShownFor
player:GetAttributeChangedSignal("Gen"):Connect(function() pathShownFor = nil end)
task.spawn(function()
	while true do
		task.wait(1.5)
		local id = player:GetAttribute("ForkPending") or ""
		if id ~= "" and pathShownFor ~= id and not openName and not news.banner then
			pathShownFor = id
			openPath()
		elseif id == "" and openName == "Path" then
			pathWin.Close()
		end
	end
end)

---------------------------------------------------------------- refresh (on attribute change, not every frame)
refresh = function()
	local a = player:GetAttributes()
	if not a.Species then return end
	title.Text = ('%s · <font color="#FFD23F">Gen %d</font>'):format(a.Species, a.Gen)
	local pk = ART[portraitKey(a.Portrait)]
	portrait.Image, portrait.ImageRectOffset, portrait.ImageRectSize = uri(pk), Vector2.new(pk.rect[1], pk.rect[2]), Vector2.new(pk.rect[3], pk.rect[4])
	evoTap.Visible = (a.ForkPending or "") ~= ""
	if evoTap.Visible then
		evoText.Text = 'Next: <font color="#FFD23F">tap to pick a path!</font>'
	elseif a.NextSpecies == "" then
		evoText.Text = "Fully evolved!"
	else
		evoText.Text = ('Next: %s   <font color="#5CF2FF">%d/%d</font>'):format(a.NextSpecies, a.Evo, a.NextAt)
	end
	dnaText.Text = Kit.abbrev(a.DNA or 0)
	local mult = a.DnaMult or 1
	multText.Text = mult > 1 and ("x%.2g"):format(mult) or ""

	local canBuy = false
	for u, c in upgradeCards do
		local cost = a[u.id .. "Cost"] or 0
		c.Name.Text = ("%s %d"):format(u.short or u.name:match("%S+$"), a[u.id] or 0) -- "Brain 3": short enough for the card
		if cost < 0 then
			c.Buy.SetEnabled(false, "MAX")
		elseif (a.DNA or 0) >= cost then
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
			r.button.SetArt(a.Diet == d.id and "btnYellowW" or "btnGreenW")
		end
	end

	for _, sec in sections do
		local found = 0
		for _, e in sec.tiles do
			local got = if e.key:sub(1, 2) == "B:" then has(a.Badges, e.name) else has(a.Index, e.key)
			if got then found += 1 end
			e.label.Text = if e.secret then (got and e.name or "???") .. "\n" .. e.desc
				elseif e.desc then e.name .. "\n" .. e.desc
				elseif got then (worldFirsts[e.key] and e.name .. "\n1st: " .. worldFirsts[e.key] or e.name)
				elseif e.path then "???\n" .. e.path .. " path"
				else "???"
			e.label.TextColor3 = got and e.color or MUTED
			if e.port then e.port.ImageColor3, e.port.ImageTransparency = got and Color3.new(1, 1, 1) or Color3.fromRGB(50, 60, 100), 0 end -- locked: navy shadow, face just visible
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
	ageText.Text = ("%s · %ds left"):format(phase, math.ceil(len * (1 - age)))
end)

---------------------------------------------------------------- news: one toast at a time, biggest news first
-- DisplayOrder 15: above the HUD, under open menus, so news never covers a menu you're using
local toastGui = Kit.screen("EvolutionToasts", 15, playerGui)
local toastRoot = scaledRoot(toastGui)
local STYLES = {
	{ find = "asteroid", priority = 10, color = Color3.fromRGB(255, 130, 110), hold = 3.5 },
	{ find = "evolved", priority = 10, color = GOLD, hold = 3.5 },
	{ find = "path", priority = 9, color = GOLD, hold = 3 },
	{ find = "SECRET", priority = 10, color = Color3.fromRGB(255, 120, 220), hold = 4 },
	{ find = "World first", priority = 8, color = Color3.fromRGB(140, 200, 255), hold = 3.5 },
	{ find = "world reached", priority = 9, color = Color3.fromRGB(140, 200, 255), hold = 4 },
	{ find = "Badge", priority = 9, color = GOLD, hold = 3 },
	{ find = "Thank you", priority = 9, color = DNA_C, hold = 3 },
	{ find = "Daily streak", priority = 8, color = DNA_C, hold = 3 },
	{ find = "entered the", priority = 7, color = Color3.fromRGB(140, 200, 255), hold = 3 },
	{ find = "Mutation", priority = 6, color = Color3.fromRGB(205, 150, 255) },
	{ find = "Caught", priority = 5, color = Color3.fromRGB(255, 130, 110) },
}
-- Overstimulated-kid sim (18 Nov, vault EVOLVE/Calc): news played behind open windows and left before a 7-year-old
-- could read it (~47% of evolve/era/badge news missed). Now: news waits while a window is open, a toast cut by a
-- window comes back after, big news stays words / 1.2 + 0.5 s, and it sits below the menu buttons (y 120).
local queue, showing, seq = {}, nil, 0
local function byPriority(x, y) return x.priority > y.priority or (x.priority == y.priority and x.seq < y.seq) end
local function showNext()
	if showing or #queue == 0 or openName or news.banner then return end
	table.sort(queue, byPriority)
	local item = table.remove(queue, 1)
	local t = img(toastRoot, "plate9", { Position = UDim2.new(0, toastX, 0, -70), Size = UDim2.fromOffset(300, 40), ZIndex = 10 })
	label(t, item.text, 15, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), TextColor3 = item.color or CREAM, ZIndex = 12, TextTruncate = Enum.TextTruncate.AtEnd })
	TweenService:Create(t, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or 0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0, toastX, 0, toastY) }):Play()
	local cur = {}
	function cur.hide(requeue)
		if showing ~= cur then return end
		showing = nil
		if requeue then table.insert(queue, item) end
		TweenService:Create(t, TweenInfo.new(0.2), { Position = UDim2.new(0, toastX, 0, -70) }):Play()
		task.delay(0.22, function() t:Destroy() showNext() end)
	end
	showing = cur
	if item.priority >= 7 then play("news") end
	local hold = item.hold or 2.2
	if item.priority >= 7 then hold = math.max(hold, #item.text:split(" ") / 1.2 + 0.5) end -- slowest 7-year-old: ~1.2 words/s
	task.delay(hold, cur.hide)
end
news.pause = function() if showing then showing.hide(true) end end
news.resume = showNext
remotes.Notify.OnClientEvent:Connect(function(msg)
	local lines = msg:split("\n")
	for i, line in lines do
		if i == 1 and #lines > 1 and line:find("^Generation") then continue end -- bigger news this life: skip the routine line
		if line:find("evolved into", 1, true) and os.clock() - (news.bannerAt or -99) < 3 then continue end -- the banner already said it
		local style = { priority = 1 }
		for _, s in STYLES do
			if line:find(s.find, 1, true) then style = s break end
		end
		seq += 1
		table.insert(queue, { text = line, priority = style.priority, color = style.color, hold = style.hold, seq = seq })
	end
	table.sort(queue, byPriority)
	while #queue > 6 do table.remove(queue) end -- sorted first, so this drops the least important, not the newest
	showNext()
end)

---------------------------------------------------------------- evolve banner: the biggest moment gets its own plate, news waits behind it
remotes:WaitForChild("Evolved").OnClientEvent:Connect(function(speciesName, stage, total, group)
	news.bannerAt = os.clock()
	news.pause()
	news.banner = true
	play("evolve")
	local b = img(toastRoot, "plate9", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.76), Size = UDim2.fromOffset(330, 112), ZIndex = 20 })
	img(b, portraitKey(group), { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(64, 70), ZIndex = 23 })
	label(b, "EVOLVED!", 30, { Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 36), TextColor3 = GOLD, ZIndex = 22 })
	label(b, speciesName, 22, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 28), ZIndex = 22, TextTruncate = Enum.TextTruncate.AtEnd })
	label(b, ("Stage %d / %d"):format(stage, total), 14, { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 20), TextColor3 = DNA_C, ZIndex = 22 })
	local sc = new("UIScale", { Scale = 0.6 }, b)
	TweenService:Create(sc, TweenInfo.new(GuiService.ReducedMotionEnabled and 0 or 0.25, Enum.EasingStyle.Back), { Scale = 0.85 }):Play() -- lower third, off the character: it fires most lives early on
	task.delay(math.max(3, #speciesName:split(" ") / 1.2 + 2), function() -- 2 words of title + the name, slowest 7-year-old
		TweenService:Create(sc, TweenInfo.new(0.15), { Scale = 0.01 }):Play()
		task.delay(0.16, function()
			b:Destroy()
			news.banner = false
			news.resume()
		end)
	end)
end)

---------------------------------------------------------------- DNA orb pickup: "+N" floats up where the orb was, the DNA pill pops
remotes:WaitForChild("Pickup").OnClientEvent:Connect(function(gain, pos, golden)
	local at = new("Attachment", { WorldPosition = pos }, workspace.Terrain)
	local bb = new("BillboardGui", { Adornee = at, Size = UDim2.fromOffset(golden and 200 or 120, golden and 56 or 40), AlwaysOnTop = true, LightInfluence = 0 }, playerGui)
	label(bb, (golden and "GOLDEN +" or "+") .. Kit.abbrev(gain) .. " DNA", golden and 28 or 22, { TextColor3 = golden and GOLD or DNA_C })
	TweenService:Create(bb, TweenInfo.new(0.9), { StudsOffset = Vector3.new(0, 4, 0) }):Play()
	task.delay(0.6, function()
		for _, o in bb:GetDescendants() do
			if o:IsA("TextLabel") then TweenService:Create(o, TweenInfo.new(0.3), { TextTransparency = 1 }):Play() end
			if o:IsA("UIStroke") then TweenService:Create(o, TweenInfo.new(0.3), { Transparency = 1 }):Play() end
		end
	end)
	task.delay(1, function() bb:Destroy() at:Destroy() end)
	play("pickup")
	if not GuiService.ReducedMotionEnabled then
		pillScale.Scale = 1.12
		TweenService:Create(pillScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end)

-- orbs bob and spin on each client (server keeps them still at BaseY, so touches stay fair)
local orbFolder = workspace:WaitForChild("DNAOrbs", 30)
if orbFolder then
	game:GetService("RunService").Heartbeat:Connect(function()
		local t = os.clock()
		for _, mine in orbFolder:GetChildren() do
			for _, orb in mine:GetChildren() do
				local y = orb:GetAttribute("BaseY")
				if y then
					local p = orb.Position
					local cf = CFrame.new(p.X, y + math.sin(t * 2.2 + p.X) * 0.45, p.Z) * CFrame.Angles(0, t * 1.5, 0)
					orb.CFrame = cf
					local core = orb:FindFirstChild("Core")
					if core then core.CFrame = cf end
				end
			end
		end
	end)
end
