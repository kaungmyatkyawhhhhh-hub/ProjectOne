-- GalaxyHUD (Galaxy Incremental, friends test 8 Nov): the screen, copied from the approved v12 UI
-- (Celestial Incremental\UI\galaxy_ui_v12_animated.html):
--  * top centre: the Stardust counter (diamond badge + slanted plate, the number counts up, "+x/s")
--  * bottom: the v6 hotbar U / F / T / E / Q (U = Upgrades; the others aren't in this test and say so)
--  * the UPGRADES window: header + Essence chip + close, the category list (STARDUST, COMETS, PLANETS; FORGE and BLACK
--    HOLE greyed with what opens them), rows with the multiplier chip and BUY / can't afford / OWNED buttons
--    PLANETS = the bodies (locked ones show UNLOCK = the ring-1 node), STARDUST = First Light + Orbit Speed,
--    COMETS = Comet Lure (owner 2 Nov; the Constellation Tree takes the ring-1 nodes in the alpha, same Config table)
--  * tutorial steps 1-4: the target glows + an arrow at once, the hint line after 5 s idle, a step counter "n/4",
--    +1 Essence per step, then TUTORIAL COMPLETE
-- Numbers all come from EconConfig; the server decides every buy (EconRequest).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local A = Kit.A
local hex = Kit.hex
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local event = Galaxy:WaitForChild("EconEvent") :: RemoteEvent
local fmt = Econ.Format

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Studio phone check (Workspace attribute TestPhone = true, Studio only): the whole HUD laid out inside a 667x375 frame in
-- the middle of the screen, exactly as on a 667x375 phone (the 3D view around it is the normal one)
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local root: GuiObject | ScreenGui = gui
if PHONE_TEST then
	local f = Instance.new("Frame")
	f.Name = "PhoneTest"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	local st = Instance.new("UIStroke")
	st.Color = Color3.new(1, 1, 1)
	st.Thickness = 2
	st.Parent = f
	f.Parent = gui
	root = f
end
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end

------------------------------------------------------------------------ state from the server's attributes
local function owned(): { number }
	local t = {}
	for k = 1, #Econ.Tiers do t[k] = player:GetAttribute("Own" .. k) or 0 end
	return t
end
local function nodes()
	local t = {}
	for _, n in ipairs(Econ.Ring1) do t[n.id] = player:GetAttribute("Node_" .. n.id) == true end
	return t
end
local function stardust(): number return player:GetAttribute("Stardust") or 0 end

------------------------------------------------------------------------ screen scale (v12 is 1280x720; phones get a bit
-- bigger so the small text stays readable)
local small = false
local function screenScale(): number
	local vp = viewport()
	small = vp.Y < 500
	if small then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end
local scaled = {} -- { frame, UIScale, baseOffsetFn }
local function scaledRoot(name, anchor: Vector2, w, h)
	local f = Kit.box(root, 0, 0, w, h, { Name = name, AnchorPoint = anchor })
	local s = Instance.new("UIScale")
	s.Parent = f
	table.insert(scaled, { f = f, s = s })
	return f, s
end

------------------------------------------------------------------------ TOP COUNTER (v12 top: badge 504,18; plate 548,36)
local top, topScale = scaledRoot("Counter", Vector2.new(0.5, 0), 280, 84)
do
	local outer = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, ImageColor3 = Kit.INK, Position = UDim2.fromOffset(44, 22), Size = UDim2.fromOffset(230, 40), ZIndex = 2 }, top)
	local inner = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, Position = UDim2.fromOffset(46, 24), Size = UDim2.fromOffset(224, 36), ZIndex = 3 }, top)
	Kit.grad(inner, hex("#2a2433"), hex("#121016"), 90)
	Kit.box(top, 52, 56, 208, 2.5, { BackgroundTransparency = 0, BackgroundColor3 = hex("#ff9a2a"), ZIndex = 4 })
	local _ = outer
	-- diamond badge (svg: ink diamond, inner #241a14 with an orange rim)
	local d1 = Kit.box(top, 37 - 25, 41 - 25, 50, 50, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, Rotation = 45, ZIndex = 5 })
	local d2 = Kit.box(top, 37 - 20.5, 41 - 20.5, 41, 41, { BackgroundTransparency = 0, BackgroundColor3 = hex("#241a14"), Rotation = 45, ZIndex = 6 })
	Kit.stroke(d2, hex("#ff9a2a"), 2)
	local _2 = d1
	Kit.icon(top, "stardust", 2, 3, 72, Color3.fromRGB(255, 170, 60), { ZIndex = 8 })
	Kit.sparkle(top, -4, 6, 12, 0.2)
	Kit.sparkle(top, 66, 58, 9, 0.9)
	Kit.sparkle(top, 76, 10, 8, 1.3)
end
local counterText = Kit.text(top, 96, 26, 100, 30, "0", 24, { ZIndex = 9 })
local rateText = Kit.text(top, 186, 35, 90, 16, "+0/s", 12, { ZIndex = 9, TextColor3 = hex("#ffc35a"), stroke = 1.2 })
counterText.ZIndex = 9
rateText.ZIndex = 9

------------------------------------------------------------------------ toasts + floating numbers (one at a time)
local toastRoot = scaledRoot("Toasts", Vector2.new(0.5, 0), 420, 120)
local function toast(str: string, colour: Color3?)
	for _, c in ipairs(toastRoot:GetChildren()) do
		if c:GetAttribute("Toast") then c:Destroy() end
	end
	local plate = Kit.box(toastRoot, 40, 0, 340, 34, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0f0d13"), ZIndex = 30 })
	plate:SetAttribute("Toast", true)
	Kit.corner(plate, 5)
	Kit.stroke(plate, colour or hex("#ff9a2a"), 2)
	local t = Kit.text(plate, 0, 7, 340, 20, str, 15, { ZIndex = 31, TextXAlignment = Enum.TextXAlignment.Center })
	local _ = t
	plate.Position = UDim2.fromOffset(40, -10)
	Kit.tween(plate, { Position = UDim2.fromOffset(40, 0) }, 0.3, Enum.EasingStyle.Back)
	task.delay(2.3, function()
		if plate.Parent then
			Kit.tween(plate, { Position = UDim2.fromOffset(40, -10), BackgroundTransparency = 1 }, 0.25)
			task.wait(0.25)
			plate:Destroy()
		end
	end)
end
local function floatText(parent, x, y, str, colour: Color3, size)
	local main, _, holder = Kit.text(parent, x, y, 220, 30, str, size or 18, { ZIndex = 40, TextColor3 = colour })
	local _2 = main
	Kit.tween(holder, { Position = UDim2.fromOffset(x, y - 26) }, 1.1, Enum.EasingStyle.Quad)
	task.delay(0.7, function()
		for _, l in ipairs(holder:GetChildren()) do
			if l:IsA("TextLabel") then
				Kit.tween(l, { TextTransparency = 1 }, 0.4)
				local st = l:FindFirstChildOfClass("UIStroke")
				if st then Kit.tween(st, { Transparency = 1 }, 0.4) end
			end
		end
	end)
	task.delay(1.2, function() holder:Destroy() end)
end

------------------------------------------------------------------------ HOTBAR (v6, v12 bottom: keys at 480 + i*70, y 650)
local hot, hotScale = scaledRoot("Hotbar", Vector2.new(0.5, 1), 360, 110)
local KEYS = {
	{ key = "U", colour = hex("#ff9a3a"), icon = "stardust", name = "UPGRADES", window = "Upgrades" },
	{ key = "F", colour = hex("#ffd84a"), icon = "forge", name = "STAR FORGE", note = "STAR FORGE: opens at SUPERNOVA 3" },
	{ key = "T", colour = hex("#7dff8a"), icon = "planet", name = "TREE", note = "CONSTELLATION TREE: not in this test" },
	{ key = "E", colour = hex("#ff5a6a"), icon = "shard", name = "STORE", note = "STORE: not in this test" },
	{ key = "Q", colour = hex("#c9c4d2"), icon = "gear", name = "SETTINGS", note = "SETTINGS: not in this test" },
}
local keyUI = {}
for i, k in ipairs(KEYS) do
	local x, y = 32 + (i - 1) * 70, 50
	local d = Kit.box(hot, x, y, 46, 46, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Rotation = 45, ZIndex = 2 })
	Kit.grad(d, hex("#2c2735"), hex("#121016"), 90)
	Kit.stroke(d, hex("#0a070d"), 2)
	local ring = Kit.box(d, 2, 2, 42, 42, { ZIndex = 3 })
	Kit.stroke(ring, if k.note then Color3.fromRGB(110, 104, 120) else k.colour, 2)
	local img = Kit.icon(hot, k.icon, x - 4, y - 6, if k.icon == "forge" then 54 else 52, nil, { ZIndex = 5 })
	if k.note then img.ImageTransparency = 0.45 end
	if k.note then Kit.icon(hot, "lock", x + 30, y + 26, 22, nil, { ZIndex = 7 }) end
	Kit.text(hot, x - 8, y - 18, 20, 16, k.key, 12, { ZIndex = 8, stroke = 1.5 })
	local label = Kit.text(hot, x - 24, y - 38, 96, 18, k.name, 15, { ZIndex = 8, TextColor3 = k.colour, TextXAlignment = Enum.TextXAlignment.Center })
	local line = Kit.box(hot, x - 24, y - 19, 96, 2, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 })
	label.Parent.Visible = false
	line.Visible = false
	local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(x - 8, y - 8), Size = UDim2.fromOffset(62, 62), ZIndex = 10 }, hot)
	keyUI[k.key] = { label = label.Parent, line = line, hit = hit, diamond = d, x = x, y = y, sparkles = {} }
end

------------------------------------------------------------------------ the UPGRADES window (v12 window at 300,120, 700x470)
local win, winScale = scaledRoot("Upgrades", Vector2.new(0.5, 0.5), 700, 470)
win.Visible = false
local ess -- the Essence number in the header chip
do
	-- breathing neon glow (v12 'breathe' 2.6 s)
	local glow = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow9, ImageColor3 = Color3.fromRGB(255, 100, 20), ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(48, 48, 80, 80), Position = UDim2.fromOffset(-34, -34), Size = UDim2.fromOffset(768, 538), ImageTransparency = 0.25, ZIndex = 1 }, win)
	task.spawn(function()
		if not Kit.calm() then
			Kit.tween(glow, { ImageTransparency = 0, Position = UDim2.fromOffset(-44, -44), Size = UDim2.fromOffset(788, 558) }, 1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		end
	end)
	local frame = Kit.box(win, 0, 0, 700, 470, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 2 })
	Kit.corner(frame, 10)
	local body = Kit.box(win, 3, 3, 694, 464, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.corner(body, 8)
	Kit.grad(body, hex("#1a1620"), hex("#0f0d13"), 90)
	Kit.stroke(body, Color3.fromRGB(255, 106, 26), 1.5, 0.45)
	-- header: the texture at 1:1 (v12: background 0 50% / 900px 80px), the bottom corners squared by a second strip
	local header = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.header, ImageRectOffset = Vector2.new(0, 12), ImageRectSize = Vector2.new(694, 56),
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(694, 56), ZIndex = 4, ClipsDescendants = true }, win)
	Kit.corner(header, 8)
	Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.header, ImageRectOffset = Vector2.new(0, 58), ImageRectSize = Vector2.new(694, 10),
		Position = UDim2.fromOffset(3, 49), Size = UDim2.fromOffset(694, 10), ZIndex = 4 }, win)
	Kit.box(win, 9, 4, 682, 2, { BackgroundTransparency = 0.4, BackgroundColor3 = Color3.fromRGB(255, 208, 160), ZIndex = 5 })
	local sweep = Kit.shine(header, 4.5, 0.16, 0.35)
	sweep.ZIndex = 5
	for i, ex in ipairs({ 20, 90, 170, 260, 350, 430, 520, 610, 660 }) do
		Kit.ember(win, ex + 3, 3 + 44 + ((i - 1) % 3) * 4, ((i - 1) * 0.41) % 3)
	end
	Kit.box(win, 3, 59, 694, 2, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 5 })
	Kit.icon(win, "stardust", -22, -30, 92, Color3.fromRGB(255, 170, 60), { ZIndex = 9 })
	Kit.sparkle(win, -26, -24, 12, 0.5)
	Kit.sparkle(win, 60, 34, 9, 1.1)
	Kit.text(win, 80, 13, 300, 34, "UPGRADES", 28, { ZIndex = 8, stroke = 1.8 })
	-- the Essence chip (v12's currency chip; the friends test's currency is Essence)
	local chip = Kit.box(win, 438, 13, 150, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 })
	Kit.corner(chip, 4)
	Kit.stroke(chip, Kit.INK, 2)
	Kit.grad(chip, hex("#0f5a5a"), hex("#22c7b8"), 0)
	ess = Kit.text(win, 470, 12, 70, 24, "0", 20, { ZIndex = 8, stroke = 1.5, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(win, 470, 33, 70, 12, "ESSENCE", 9, { ZIndex = 8, stroke = 1, TextColor3 = hex("#dcfffb"), TextXAlignment = Enum.TextXAlignment.Center })
	Kit.icon(win, "essence", 548, 2, 50, Color3.fromRGB(60, 230, 210), { ZIndex = 8 })
end
-- close (pink, white rim, white X)
local closeBtn
do
	closeBtn = Kit.new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(648, 13), Size = UDim2.fromOffset(34, 34),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, win)
	Kit.corner(closeBtn, 6)
	Kit.stroke(closeBtn, Color3.new(1, 1, 1), 2, 0.1)
	Kit.grad(closeBtn, hex("#ff7d8e"), hex("#e2334c"), 90)
	for _, r in ipairs({ 45, -45 }) do
		local bar = Kit.box(closeBtn, 0, 0, 20, 4, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = r, ZIndex = 9 })
		bar.Position = UDim2.fromScale(0.5, 0.5)
		Kit.corner(bar, 2)
	end
	Kit.box(win, 648, 15, 34, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 7 }).Name = "CloseShadow"
	Kit.corner(win.CloseShadow, 6)
end

-- category list (v12: panel 16,74 190x380; buttons 28, 88 + i*58, 166x46)
local listPanel = Kit.box(win, 16, 74, 190, 380, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 4 })
Kit.corner(listPanel, 6)
Kit.stroke(listPanel, hex("#2a2433"), 1.5)
local TABS = {
	{ id = "STARDUST", c1 = "#ff9a3a", c2 = "#c2410c", icon = "stardust", glow = Color3.fromRGB(255, 170, 60) },
	{ id = "COMETS", c1 = "#5ad1ff", c2 = "#1f6fd1", icon = "comet", glow = Color3.fromRGB(90, 200, 255) },
	{ id = "PLANETS", c1 = "#b49bff", c2 = "#5a3ad8", icon = "planet", glow = Color3.fromRGB(170, 130, 255) },
	{ id = "FORGE", c1 = "#6a6474", c2 = "#3f3a48", icon = "forge", glow = nil, locked = "SUPERNOVA 3",
		lockedTitle = "STAR FORGE", lockedText = "Roll Star Cores with Essence. Opens at SUPERNOVA 3." },
	{ id = "BLACK HOLE", c1 = "#5a5562", c2 = "#38343f", icon = "gear", glow = nil, locked = "100K SHARDS",
		lockedTitle = "BLACK HOLE", lockedText = "Collapse your shards into Dark Matter. Opens at 100K shards." },
}
local tabUI = {}
local currentTab = "PLANETS"
local selRing
for i, t in ipairs(TABS) do
	local x, y = 28, 88 + (i - 1) * 58
	local b, inner = Kit.button(win, x, y, 166, 46, hex(t.c1), hex(t.c2), { ZIndex = 6 })
	if t.locked then
		Kit.text(inner, 30, 5, 136, 20, t.id, 15, { ZIndex = inner.ZIndex, stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
		Kit.text(inner, 30, 26, 136, 14, t.locked, 10, { ZIndex = inner.ZIndex, stroke = 1.1, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#a99fb8") })
	else
		Kit.text(inner, 30, 12, 136, 22, t.id, 17, { ZIndex = inner.ZIndex, stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center })
	end
	local img = Kit.icon(win, t.icon, x - 12, y - 8, if t.icon == "forge" then 56 else 54, t.glow, { ZIndex = 9 })
	if t.locked then img.ImageTransparency = 0.35 end
	tabUI[t.id] = { button = b, inner = inner, x = x, y = y, def = t }
end
Kit.sparkle(win, 30, 82, 10, 0.4)
Kit.sparkle(win, 180, 128, 8, 1.2)

-- rows panel (v12: 218,74 466x380; rows 10, 12 + i*120, 446x110)
local rowsPanel = Kit.new("ScrollingFrame", { Position = UDim2.fromOffset(218, 74), Size = UDim2.fromOffset(466, 380), BackgroundColor3 = hex("#0b090e"),
	BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = hex("#3a3346"), CanvasSize = UDim2.fromOffset(0, 380),
	ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 4, ElasticBehavior = Enum.ElasticBehavior.Never }, win)
Kit.corner(rowsPanel, 6)
Kit.stroke(rowsPanel, hex("#2a2433"), 1.5)

------------------------------------------------------------------------ rows
local GREEN1, GREEN2 = hex("#7dff7a"), hex("#1fa83a")
local GREY1, GREY2 = hex("#6a6474"), hex("#3f3a48")
local VIO1, VIO2 = hex("#b49bff"), hex("#5a3ad8")
local TIER_LOOK = { -- border, title gradient, icon glow
	{ "#9a8cb0", "#f3eaff", "#b9a8cc", Color3.fromRGB(200, 180, 230) },
	{ "#3a8acc", "#ffffff", "#bfe9ff", Color3.fromRGB(90, 200, 255) },
	{ "#8a6cff", "#efe8ff", "#b49bff", Color3.fromRGB(170, 130, 255) },
	{ "#ff9a3a", "#fff1c0", "#ffb02a", Color3.fromRGB(255, 120, 30) },
	{ "#5a5562", "#cfc6dd", "#8a8296", nil },
}
local TAB_LOOK = {
	STARDUST = { "#ff9a3a", "#fff1c0", "#ffb02a", Color3.fromRGB(255, 120, 30) },
	COMETS = { "#3a8acc", "#ffffff", "#bfe9ff", Color3.fromRGB(90, 200, 255) },
}

local rows = {} -- { refresh = fn }
local tutorialTargets = {} -- name -> GuiObject (for the arrow)

-- the button area of a row (146x52 at 288,30): rebuilt when its state changes
local function setButton(row, state: string, price: number?, label: string?)
	local key = state .. "|" .. (price and fmt(price) or "") .. "|" .. (label or "")
	if row.btnKey == key then return end
	row.btnKey = key
	if row.btn then row.btn:Destroy() row.btnShadow:Destroy() end
	if row.fx then row.fx:Destroy() end
	-- (the sparkles around the button live in their own layer, rebuilt with it)
	row.fx = Kit.box(row.frame, 0, 0, 446, 110, { ZIndex = 9 })
	local c1, c2 = GREEN1, GREEN2
	if state == "no" or state == "locked" then c1, c2 = GREY1, GREY2 elseif state == "owned" then c1, c2 = VIO1, VIO2 end
	local b, inner, _, shadow = Kit.button(row.frame, 288, 30, 146, 52, c1, c2, { ZIndex = 6 })
	row.btn, row.btnShadow = b, shadow
	local z = inner.ZIndex
	if state == "owned" then
		Kit.text(inner, 0, 10, 146, 32, label or "OWNED", 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY })
		Kit.shine(b, 3.6)
		Kit.sparkle(row.fx, 288 + 134, 30 - 4, 10, 0.5)
		Kit.sparkle(row.fx, 288 - 4, 30 + 44, 8, 1.5)
	elseif state == "locked" then
		local img = Kit.icon(inner, "lock", 10, 10, 30, nil, { ZIndex = z })
		img.ImageTransparency = 0.2
		Kit.text(inner, 38, 15, 104, 24, label or "LOCKED", if #(label or "LOCKED") > 9 then 13 else 18, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
	else
		local top = 10
		if label then
			Kit.text(inner, 0, 3, 146, 14, label, 11, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.2 })
			top = 16
		end
		local ic = Kit.icon(inner, "stardust", 14, top + 2, if label then 22 else 26, nil, { ZIndex = z })
		if state == "no" then ic.ImageTransparency = 0.3 end
		local priceStr = if price == 0 then "FREE" else fmt(price or 0)
		Kit.text(inner, 40, top, 100, 30, priceStr, if label then 20 else 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if state == "no" then hex("#ff6b6b") else Color3.new(1, 1, 1) })
		if state == "buy" then
			Kit.shine(b, 2.4)
			for _, m in ipairs({ { 20, 40, 0 }, { 60, 44, 0.6 }, { 100, 42, 1.2 }, { 124, 40, 0.3 } }) do Kit.mote(b, m[1], m[2], m[3]) end
			Kit.sparkle(row.fx, 288 + 128, 30 - 6, 12, 0)
			Kit.sparkle(row.fx, 288 - 6, 30 + 40, 10, 0.8)
			Kit.sparkle(row.fx, 288 + 70, 30 - 8, 8, 1.3)
		end
	end
	row.onButton(b)
end

local function newRowFrame(i, borderHex)
	local y = 12 + (i - 1) * 120
	local f = Kit.box(rowsPanel, 10, y, 446, 110, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	Kit.corner(f, 5)
	Kit.stroke(f, hex(borderHex), 2)
	Kit.grad(f, hex("#17141c"), hex("#0e0c12"), 90)
	return f
end
local function chip(row, from: string, to: string?)
	if row.chipKey == from .. "|" .. (to or "") then return end
	row.chipKey = from .. "|" .. (to or "")
	if row.chip then row.chip:Destroy() end
	local holder = Kit.box(row.frame, 86, 60, 300, 32, { ZIndex = 6 })
	row.chip = holder
	-- sized to the text (v12: 160 wide with an arrow, 80 without, never smaller)
	local function width(str) return TextService:GetTextSize(str, 17, Enum.Font.GothamBlack, Vector2.new(400, 30)).X + 4 end
	local fromW = width(from)
	local w = if to then math.max(160, 10 + fromW + 20 + width(to) + 10) else math.max(80, fromW + 20)
	local c = Kit.box(holder, 0, 0, w, 32, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(c, 4)
	Kit.stroke(c, hex("#3a3346"), 1.5)
	Kit.text(holder, 10, 5, fromW, 22, from, 17, { ZIndex = 7, stroke = 1.5 })
	if to then
		Kit.text(holder, fromW + 12, 3, 16, 24, ">", 18, { ZIndex = 7, TextColor3 = hex("#9a90a8") })
		Kit.text(holder, fromW + 28, 5, w - fromW - 30, 22, to, 17, { ZIndex = 7, stroke = 1.5, TextColor3 = hex("#7dff6b") })
	end
end

-- hold-to-buy (bodies): one buy at press, then every 0.12 s after 0.4 s while held
local function holdBuy(b: GuiButton, buyOnce: () -> boolean)
	local holding = false
	b.MouseButton1Down:Connect(function()
		holding = true
		if not buyOnce() then return end
		task.wait(0.4)
		while holding and b.Parent do
			if not buyOnce() then break end
			task.wait(0.12)
		end
	end)
	local function stop() holding = false end
	b.MouseButton1Up:Connect(stop)
	b.MouseLeave:Connect(stop)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then stop() end
	end)
end

local busy = false
local function afterBuy(row, incomeBefore: number)
	-- feedback: a sparkle burst on the row, the counter pops, "+x/s" floats under it
	for _ = 1, 5 do
		local s = Kit.sparkle(row.frame, math.random(250, 430), math.random(10, 80), math.random(8, 14), 0)
		task.delay(1.6, function() s:Destroy() end)
	end
	task.defer(function()
		local now = player:GetAttribute("Income") or 0
		if now > incomeBefore then floatText(top, 186, 52, "+" .. fmt(now - incomeBefore) .. "/s", hex("#7dff6b"), 14) end
	end)
	Kit.tween(topScale, { Scale = topScale.Scale * 1.08 }, 0.08)
	task.delay(0.08, function() Kit.tween(topScale, { Scale = screenScale() }, 0.2, Enum.EasingStyle.Back) end)
end

local function bodyRow(i, k: number)
	local tier = Econ.Tiers[k + 1]
	local look = TIER_LOOK[k + 1]
	local row = { frame = newRowFrame(i, look[1]) }
	Kit.icon(row.frame, tier.icon, -8, 2, if tier.icon == "comet" then 96 else 90, look[4], { ZIndex = 7 })
	local lv = Kit.text(row.frame, 16, 82, 60, 16, "LV 0", 12, { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(row.frame, 86, 10, 300, 28, tier.name, 22, { ZIndex = 8, gradient = ColorSequence.new(hex(look[2]), hex(look[3])) })
	local desc = Kit.text(row.frame, 88, 38, 196, 16, "", 11, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1 })
	local node = tier.unlock and Econ.Ring1ById[tier.unlock]
	row.onButton = function(b)
		holdBuy(b, function()
			if busy then return false end
			local o, n = owned(), nodes()
			local unlockedNow = Econ.Unlocked(k, n)
			if k >= Econ.PlayableTiers then
				toast(tier.name .. ": opens at " .. (tier.lockedText or ""), hex("#8a8296"))
				return false
			end
			if not unlockedNow then
				if node.requires and not n[node.requires] then
					toast("Unlock the " .. Econ.Tiers[k].name .. " first", hex("#8a8296"))
					return false
				end
				if stardust() < node.cost then return false end
				busy = true
				local before = player:GetAttribute("Income") or 0
				local ok = request:InvokeServer("BuyNode", node.id)
				busy = false
				if ok then afterBuy(row, before) toast(tier.name .. " UNLOCKED", hex("#7dff6b")) end
				return false -- (one unlock per press)
			end
			if stardust() < Econ.Cost(k, o[k + 1]) then return false end
			busy = true
			local before = player:GetAttribute("Income") or 0
			local ok = request:InvokeServer("BuyBody", k)
			busy = false
			if ok then afterBuy(row, before) end
			return ok == true
		end)
	end
	row.refresh = function()
		local o, n = owned(), nodes()
		local own = o[k + 1] or 0
		if k >= Econ.PlayableTiers then
			Kit.setText(lv, "LOCKED")
			Kit.setText(desc, "opens at " .. tier.lockedText)
			chip(row, tier.lockedText)
			setButton(row, "locked", nil, tier.lockedText)
			return
		end
		local unlockedNow = Econ.Unlocked(k, n)
		local each = Econ.TierIncomeWith(k, 1, n) * Econ.AllMult(n)
		if not unlockedNow then
			Kit.setText(lv, "LOCKED")
			Kit.setText(desc, "opens with " .. node.name .. ", " .. fmt(each) .. "/s each")
			chip(row, "LOCKED", "OPEN")
			if node.requires and not n[node.requires] then
				setButton(row, "locked", nil, "UNLOCK " .. Econ.Tiers[k].name)
			else
				setButton(row, if stardust() >= node.cost then "buy" else "no", node.cost, "UNLOCK")
			end
			tutorialTargets["Unlock" .. k] = row.btn
			return
		end
		Kit.setText(lv, "LV " .. own)
		local nextM = Econ.NextMilestone(own)
		Kit.setText(desc, "earns " .. fmt(each) .. "/s each" .. (if nextM then ", x2 at " .. nextM else ""))
		local now = Econ.TierIncomeWith(k, own, n) * Econ.AllMult(n)
		local after = Econ.TierIncomeWith(k, own + 1, n) * Econ.AllMult(n)
		chip(row, fmt(now) .. "/s", fmt(after) .. "/s")
		local cost = Econ.Cost(k, own)
		setButton(row, if stardust() >= cost then "buy" else "no", cost)
		tutorialTargets["Body" .. k] = row.btn
	end
	return row
end

local function nodeRow(i, node, look)
	local row = { frame = newRowFrame(i, look[1]) }
	Kit.icon(row.frame, node.icon, -8, 2, if node.icon == "comet" then 96 else 90, look[4], { ZIndex = 7 })
	local lv = Kit.text(row.frame, 16, 82, 60, 16, "LV 0", 12, { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(row.frame, 86, 10, 300, 28, node.name, 22, { ZIndex = 8, gradient = ColorSequence.new(hex(look[2]), hex(look[3])) })
	Kit.text(row.frame, 88, 38, 196, 16, node.desc, 11, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1 })
	local e = node.effect
	local from, to
	if e.kind == "tierMult" or e.kind == "allMult" then
		from, to = "x1", "x" .. tostring(e.mult)
	elseif e.kind == "cometEvery" then
		from, to = Econ.Comet.Every .. "s", e.seconds .. "s"
	end
	row.onButton = function(b)
		b.MouseButton1Click:Connect(function()
			if busy then return end
			local n = nodes()
			if n[node.id] then return end
			if node.requires and not n[node.requires] then return end
			if stardust() < node.cost then return end
			busy = true
			local before = player:GetAttribute("Income") or 0
			local ok = request:InvokeServer("BuyNode", node.id)
			busy = false
			if ok then afterBuy(row, before) end
		end)
	end
	row.refresh = function()
		local n = nodes()
		if n[node.id] then
			Kit.setText(lv, "LV 1")
			chip(row, to or "")
			setButton(row, "owned", nil, "OWNED")
		else
			Kit.setText(lv, "LV 0")
			chip(row, from or "", to)
			setButton(row, if stardust() >= node.cost then "buy" else "no", node.cost)
		end
		tutorialTargets["Node_" .. node.id] = row.btn
	end
	return row
end

local function lockedPanel(t)
	local f = Kit.box(rowsPanel, 10, 12, 446, 356, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	Kit.corner(f, 5)
	Kit.stroke(f, hex("#5a5562"), 2)
	Kit.grad(f, hex("#17141c"), hex("#0e0c12"), 90)
	local img = Kit.icon(f, t.icon, 163, 40, 120, nil, { ZIndex = 7 })
	img.ImageTransparency = 0.35
	Kit.icon(f, "lock", 250, 120, 48, nil, { ZIndex = 9 })
	Kit.text(f, 0, 190, 446, 34, t.lockedTitle, 28, { ZIndex = 8, TextXAlignment = Enum.TextXAlignment.Center, gradient = ColorSequence.new(hex("#cfc6dd"), hex("#8a8296")) })
	Kit.text(f, 30, 232, 386, 40, t.lockedText, 13, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1,
		TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
end

local function buildTab(id: string)
	for _, c in ipairs(rowsPanel:GetChildren()) do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") then c:Destroy() end
	end
	table.clear(rows)
	table.clear(tutorialTargets)
	local t = tabUI[id].def
	local list = {}
	if t.locked then
		lockedPanel(t)
		rowsPanel.CanvasSize = UDim2.fromOffset(0, 380)
		return
	elseif id == "PLANETS" then
		for k = 0, #Econ.Tiers - 1 do table.insert(list, function(i) return bodyRow(i, k) end) end
	else
		for _, node in ipairs(Econ.Ring1) do
			if node.tab == id and node.effect.kind ~= "unlockTier" then
				table.insert(list, function(i) return nodeRow(i, node, TAB_LOOK[id]) end)
			end
		end
	end
	for i, make in ipairs(list) do
		local row = make(i)
		table.insert(rows, row)
		row.refresh()
	end
	rowsPanel.CanvasSize = UDim2.fromOffset(0, math.max(380, 12 + #list * 120))
	rowsPanel.CanvasPosition = Vector2.zero
end
local function refreshRows()
	for _, row in ipairs(rows) do row.refresh() end
end

local selPulse
local function selectTab(id: string)
	currentTab = id
	if selRing then selRing:Destroy() end
	if selPulse then selPulse:Cancel() end
	for tid, ui in pairs(tabUI) do
		Kit.clearVfx(ui.button)
		if tid == id and not ui.def.locked then Kit.tagVfx(Kit.shine(ui.button, 3)) end
	end
	local ui = tabUI[id]
	selRing = Kit.box(win, ui.x - 4, ui.y - 4, 174, 54, { ZIndex = 7 })
	Kit.corner(selRing, 7)
	local st = Kit.stroke(selRing, Color3.new(1, 1, 1), 2)
	if not Kit.calm() then selPulse = Kit.tween(st, { Transparency = 0.65 }, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) end
	buildTab(id)
end
for id, ui in pairs(tabUI) do
	ui.button.MouseButton1Click:Connect(function() selectTab(id) end)
end

------------------------------------------------------------------------ open / close
local open = false
local function setKeySelected(key: string?)
	for k, ui in pairs(keyUI) do
		local on = k == key
		ui.label.Visible = on
		ui.line.Visible = on
		for _, s in ipairs(ui.sparkles) do s:Destroy() end
		table.clear(ui.sparkles)
		if on then
			table.insert(ui.sparkles, Kit.sparkle(hot, ui.x - 6, ui.y - 4, 9, 0.7))
			table.insert(ui.sparkles, Kit.sparkle(hot, ui.x + 44, ui.y + 40, 8, 1.4))
		end
	end
end
local layout, windowScale -- (defined below)
local function openWindow(tab: string?)
	if open then
		if tab and tab ~= currentTab then selectTab(tab) end
		return
	end
	open = true
	win.Visible = true
	setKeySelected("U")
	selectTab(tab or currentTab)
	layout()
	local ws = windowScale()
	winScale.Scale = ws * 0.8
	Kit.tween(winScale, { Scale = ws }, 0.25, Enum.EasingStyle.Back)
end
local function closeWindow()
	if not open then return end
	open = false
	setKeySelected(nil)
	Kit.tween(winScale, { Scale = winScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function()
		if not open then win.Visible = false end
	end)
	layout()
end
closeBtn.MouseButton1Click:Connect(closeWindow)
local tutorialTab -- set by the tutorial: the tab the current step needs
for _, k in ipairs(KEYS) do
	keyUI[k.key].hit.MouseButton1Click:Connect(function()
		if k.window then
			if open then closeWindow() else openWindow(tutorialTab) end
		else
			toast(k.note, k.colour)
		end
	end)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, k in ipairs(KEYS) do
		if input.KeyCode == Enum.KeyCode[k.key] then
			if k.window then
				if open then closeWindow() else openWindow(tutorialTab) end
			else
				toast(k.note, k.colour)
			end
		end
	end
end)

------------------------------------------------------------------------ layout (screen size)
-- the window sits between the counter and the hotbar (on phones the hotbar hides while it's open)
local function windowRoom(): (number, number)
	local s = screenScale()
	local vp = viewport()
	local topEdge = 84 * s
	-- (on phones: down to the bottom edge, or above the hint line while the tutorial runs)
	local tutorialOn = (player:GetAttribute("TutStep") or 0) < #Econ.Tutorial
	local bottomEdge = if small then vp.Y - (if tutorialOn then 50 * s else 6) else vp.Y - 104 * s
	return topEdge, bottomEdge - topEdge
end
function windowScale(): number
	local _, room = windowRoom()
	return math.min(screenScale(), room / (470 + 34))
end
function layout()
	local s = screenScale()
	local vp = viewport()
	for _, e in ipairs(scaled) do
		if e.f ~= win then e.s.Scale = s end
	end
	top.Position = UDim2.new(0.5, 0, 0, math.floor(8 * s))
	toastRoot.Position = UDim2.new(0.5, 0, 0, math.floor(132 * s)) -- (under the hint line)
	hot.Position = UDim2.new(0.5, 0, 1, -math.floor(4 * s))
	local ws = windowScale()
	if open then winScale.Scale = ws end
	local topEdge, room = windowRoom()
	win.Position = UDim2.fromOffset(vp.X / 2, topEdge + room / 2 + 15 * ws)
	hot.Visible = not (small and open)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()

------------------------------------------------------------------------ live numbers
local shown = stardust()
local lastServer, lastAt = stardust(), os.clock()
player:GetAttributeChangedSignal("Stardust"):Connect(function()
	lastServer, lastAt = stardust(), os.clock()
	if lastServer < shown then shown = lastServer end
end)
local lastText = ""
local affordCheck = 0
RunService.RenderStepped:Connect(function(dt)
	local income = player:GetAttribute("Income") or 0
	local target = lastServer + income * math.min(os.clock() - lastAt, 1)
	shown = if shown < target then math.min(target, shown + math.max((target - shown) * math.min(dt * 10, 1), income * dt)) else target
	local str = fmt(shown)
	if str ~= lastText then
		lastText = str
		Kit.setText(counterText, str)
	end
	affordCheck += dt
	if affordCheck > 0.25 and open then
		affordCheck = 0
		refreshRows()
	end
end)
local function onIncome()
	Kit.setText(rateText, "+" .. fmt(player:GetAttribute("Income") or 0) .. "/s")
end
player:GetAttributeChangedSignal("Income"):Connect(onIncome)
onIncome()
local function onEssence() Kit.setText(ess, fmt(player:GetAttribute("Essence") or 0)) end
player:GetAttributeChangedSignal("Essence"):Connect(onEssence)
onEssence()
for k = 1, #Econ.Tiers do player:GetAttributeChangedSignal("Own" .. k):Connect(function() if open then refreshRows() end end) end
for _, n in ipairs(Econ.Ring1) do player:GetAttributeChangedSignal("Node_" .. n.id):Connect(function() if open then refreshRows() end end) end

------------------------------------------------------------------------ the tutorial (steps 1-4 of the design)
local tut = { arrow = nil, glow = nil, hint = nil, idleSince = os.clock(), step = player:GetAttribute("TutStep") or 0, target = nil }
local hintRoot = scaledRoot("Hint", Vector2.new(0.5, 0), 420, 44)
layout()
local function clearHint()
	if tut.hint then tut.hint:Destroy() tut.hint = nil end
end
local function showHint(step: number)
	clearHint()
	local def = Econ.Tutorial[step + 1]
	if not def then return end
	local f = Kit.box(hintRoot, 30, 4, 360, 36, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0f0d13"), ZIndex = 20 })
	Kit.corner(f, 5)
	Kit.stroke(f, hex("#ff9a2a"), 2)
	local c = Kit.box(f, 6, 5, 46, 26, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 21 })
	Kit.corner(c, 4)
	Kit.stroke(c, Kit.INK, 2)
	Kit.grad(c, hex("#ffd84a"), hex("#c79a0a"), 90)
	Kit.text(c, 0, 3, 46, 20, (step + 1) .. "/" .. #Econ.Tutorial, 15, { ZIndex = 22, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.5 })
	Kit.text(f, 60, 8, 230, 22, def.hint, 16, { ZIndex = 21 })
	Kit.icon(f, "essence", 300, 2, 32, Color3.fromRGB(60, 230, 210), { ZIndex = 22 })
	Kit.text(f, 326, 8, 34, 22, "+" .. def.essence, 16, { ZIndex = 22, TextColor3 = hex("#7dffe9") })
	tut.hint = f
end
local arrow = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.arrow, Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0.5, 1), Visible = false, ZIndex = 60 }, gui)
local targetRing = Kit.new("Frame", { BackgroundTransparency = 1, Visible = false, ZIndex = 59, AnchorPoint = Vector2.new(0.5, 0.5) }, gui)
Kit.corner(targetRing, 8)
local ringStroke = Kit.stroke(targetRing, hex("#ffd84a"), 3)
Kit.tween(ringStroke, { Transparency = 0.7 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- what the current step points at
local function stepTarget(step: number): (GuiObject?, string?)
	local def = Econ.Tutorial[step + 1]
	if not def then return nil, nil end
	local wantTab, rowKey
	if def.id == "BuyAsteroid" then wantTab, rowKey = "PLANETS", "Body0"
	elseif def.id == "FirstLight" then wantTab, rowKey = "STARDUST", "Node_FirstLight"
	elseif def.id == "FirstMoon" then wantTab, rowKey = "PLANETS", if player:GetAttribute("Node_LunarPull") then "Body1" else "Unlock1"
	else return nil, nil end
	if not open then return keyUI.U.hit, wantTab end
	if currentTab ~= wantTab then return tabUI[wantTab].button, wantTab end
	return tutorialTargets[rowKey], wantTab
end

local function tutorialComplete()
	local f = Kit.box(root, 0, 0, 520, 120, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), ZIndex = 70 })
	local sc = Instance.new("UIScale")
	sc.Scale = screenScale() * 0.6
	sc.Parent = f
	Kit.text(f, 0, 10, 520, 50, "TUTORIAL COMPLETE", 42, { ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 2.5,
		gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	Kit.text(f, 0, 64, 520, 26, #Econ.Tutorial .. "/" .. #Econ.Tutorial .. "  ESSENCE " .. fmt(player:GetAttribute("Essence") or 0), 20,
		{ ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#7dffe9") })
	for i = 1, 10 do Kit.sparkle(f, math.random(0, 500), math.random(-10, 100), math.random(10, 20), i * 0.12) end
	Kit.tween(sc, { Scale = screenScale() }, 0.35, Enum.EasingStyle.Back)
	task.delay(2.8, function()
		Kit.tween(sc, { Scale = screenScale() * 0.9 }, 0.25)
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("TextLabel") then Kit.tween(d, { TextTransparency = 1 }, 0.25) end
			if d:IsA("UIStroke") then Kit.tween(d, { Transparency = 1 }, 0.25) end
			if d:IsA("ImageLabel") then d:Destroy() end
		end
		task.wait(0.3)
		f:Destroy()
	end)
end

event.OnClientEvent:Connect(function(kind, a, b)
	if kind == "TutorialStep" then
		tut.step = a
		tut.idleSince = os.clock()
		clearHint()
		-- +1 Essence flies up from the hint line
		floatText(top, 120, 70, "+" .. b .. " ESSENCE", hex("#7dffe9"), 16)
		if a >= #Econ.Tutorial then
			task.delay(0.4, tutorialComplete)
		elseif Econ.Tutorial[a + 1].id == "Comet" then
			-- the Moon flies in: close the window so the system and the comet are in view
			task.delay(1.2, closeWindow)
		end
	elseif kind == "CometPaid" then
		floatText(top, 120, 60, "+" .. fmt(b), hex("#9be7ff"), 20)
	end
end)
UserInputService.InputBegan:Connect(function() tut.idleSince = os.clock() end)

RunService.Heartbeat:Connect(function()
	local step = player:GetAttribute("TutStep") or 0
	tut.step = step
	if step >= #Econ.Tutorial then
		arrow.Visible, targetRing.Visible = false, false
		tutorialTab = nil
		clearHint()
		return
	end
	local target, wantTab = stepTarget(step)
	tutorialTab = wantTab
	-- the hint line: after 5 s without input, and then it stays until the step is done
	if not tut.hint and (os.clock() - tut.idleSince > Econ.HintAfter or Econ.Tutorial[step + 1].id == "Comet") then showHint(step) end
	if tut.hint then
		-- under the counter; on phones with the window open it goes to the bottom (the hotbar is hidden then)
		local s = screenScale()
		hintRoot.Position = if small and open then UDim2.new(0.5, 0, 0, viewport().Y - math.floor(46 * s)) else UDim2.new(0.5, 0, 0, math.floor(90 * s))
	end
	if target and target.Parent and target.AbsoluteSize.X > 0 then
		-- (AbsolutePosition is below the top bar even in an IgnoreGuiInset ScreenGui: add the inset back)
		local p, sz = target.AbsolutePosition + GuiService:GetGuiInset(), target.AbsoluteSize
		local centre = p + sz / 2
		local bob = if Kit.calm() then 0 else math.sin(os.clock() * 5) * 6
		arrow.Visible = true
		arrow.Size = UDim2.fromOffset(44 * screenScale(), 44 * screenScale())
		arrow.Position = UDim2.fromOffset(centre.X, p.Y - 6 + bob)
		targetRing.Visible = true
		targetRing.Position = UDim2.fromOffset(centre.X, centre.Y)
		targetRing.Size = UDim2.fromOffset(sz.X + 10, sz.Y + 10)
		targetRing.Rotation = target.AbsoluteRotation
	else
		arrow.Visible, targetRing.Visible = false, false
	end
end)

-- (the window gets the hint line's room back when the tutorial ends)
player:GetAttributeChangedSignal("TutStep"):Connect(layout)
