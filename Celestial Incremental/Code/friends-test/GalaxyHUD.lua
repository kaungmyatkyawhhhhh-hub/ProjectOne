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
-- Alpha part 1 (3 Nov): the SUPERNOVA goal bar under the counter ("SUPERNOVA 63%"), the SHARDS counter next to it (once you
-- have any; shared.GalaxyShardsTarget() = where flying shards land), hotbar T = the 2D TREE window (the island's Constellation
-- Tree + Info screens, IslandBoardsUI), tutorial steps 5-7 (the bar to 50%, the SUPERNOVA button, STARFIRE in the tree).
-- The SUPERNOVA button, card and cinematic are GalaxySupernova's.
-- Overnight (3 Nov): hotbar E = the STORE (GalaxyStore; its CODES button opens GalaxyCodes, side key "C").
-- Alpha part 2 (3 Nov): hotbar G = the GUIDE BOOK (GalaxyGuide, with its red dot), Q = SETTINGS (GalaxySettings); the window
-- open / close, new body and x2 milestone sounds (Galaxy.Sounds); at TUTORIAL COMPLETE the Star Forge glows in the world.
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
local UpgradesPanel = require(Galaxy:WaitForChild("UpgradesPanel"))
local BoardsUI = require(Galaxy:WaitForChild("IslandBoardsUI"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
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
local rateText = Kit.text(top, 186, Kit.ps(35, 33), 90, 20, "+0/s", Kit.ps(12, 18), { ZIndex = 9, TextColor3 = hex("#ffc35a"), stroke = 1.2 })
counterText.ZIndex = 9
rateText.ZIndex = 9

-- the SUPERNOVA goal bar under the counter (design step 5: "SUPERNOVA 0% -> 100%"): shown from tutorial step 5 on; full = gold
local goal = Kit.box(top, 56, 64, 204, 16, { BackgroundTransparency = 0, BackgroundColor3 = hex("#16131b"), ZIndex = 4, Visible = false })
Kit.corner(goal, 8)
Kit.stroke(goal, Kit.INK, 2)
local goalFill = Kit.box(goal, 0, 0, 0, 16, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
Kit.corner(goalFill, 8)
local goalGrad = Kit.grad(goalFill, hex("#ffe08a"), hex("#ff9a1a"), 90)
local goalText = Kit.text(goal, 0, 1, 204, 14, "", 11, { ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.3 })
local _g = goalGrad

-- the SHARDS counter (alpha part 1), right of the stardust counter: shown once you've earned shards
local shardsRoot, shardsScale = scaledRoot("Shards", Vector2.new(0, 0), 170, 64)
shardsRoot.Visible = false
do
	local outer = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, ImageColor3 = Kit.INK, Position = UDim2.fromOffset(30, 14), Size = UDim2.fromOffset(136, 36), ZIndex = 2 }, shardsRoot)
	local inner = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, Position = UDim2.fromOffset(32, 16), Size = UDim2.fromOffset(130, 32), ZIndex = 3 }, shardsRoot)
	Kit.grad(inner, hex("#2a2240"), hex("#120f1c"), 90)
	Kit.box(shardsRoot, 38, 44, 118, 2.5, { BackgroundTransparency = 0, BackgroundColor3 = hex("#a77bff"), ZIndex = 4 })
	local _ = outer
	local d1 = Kit.box(shardsRoot, 26 - 21, 32 - 21, 42, 42, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, Rotation = 45, ZIndex = 5 })
	local d2 = Kit.box(shardsRoot, 26 - 17, 32 - 17, 34, 34, { BackgroundTransparency = 0, BackgroundColor3 = hex("#1d1430"), Rotation = 45, ZIndex = 6 })
	Kit.stroke(d2, hex("#a77bff"), 2)
	local _2 = d1
	Kit.icon(shardsRoot, "shard", -2, 3, 58, Color3.fromRGB(170, 110, 255), { ZIndex = 8 })
	Kit.text(shardsRoot, 74, 3, 80, 14, "SHARDS", 10, { ZIndex = 9, TextColor3 = hex("#d9c2ff"), stroke = 1 })
end
local shardsText = Kit.text(shardsRoot, 66, 17, 96, 28, "0", 22, { ZIndex = 9 })

-- the COSMIC LEVEL (feel pass, 5 Nov, #84), LEFT of the stardust counter: the shards plate's look, the sun in a blue diamond,
-- "LVL 7" + the XP to the next level ("3.2/12") with a bar under it
local levelRoot, levelScale = scaledRoot("CosmicLevel", Vector2.new(1, 0), 170, 64)
local levelText, levelXpText, levelFill
do
	local outer = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, ImageColor3 = Kit.INK, Position = UDim2.fromOffset(30, 14), Size = UDim2.fromOffset(136, 36), ZIndex = 2 }, levelRoot)
	local inner = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.plate, Position = UDim2.fromOffset(32, 16), Size = UDim2.fromOffset(130, 32), ZIndex = 3 }, levelRoot)
	Kit.grad(inner, hex("#16283a"), hex("#0c121c"), 90)
	Kit.box(levelRoot, 38, 44, 118, 2.5, { BackgroundTransparency = 0, BackgroundColor3 = hex("#22303e"), ZIndex = 4 })
	levelFill = Kit.box(levelRoot, 38, 44, 0, 2.5, { BackgroundTransparency = 0, BackgroundColor3 = hex("#5ad1ff"), ZIndex = 5 })
	local _ = outer
	local d1 = Kit.box(levelRoot, 26 - 21, 32 - 21, 42, 42, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, Rotation = 45, ZIndex = 5 })
	local d2 = Kit.box(levelRoot, 26 - 17, 32 - 17, 34, 34, { BackgroundTransparency = 0, BackgroundColor3 = hex("#102030"), Rotation = 45, ZIndex = 6 })
	Kit.stroke(d2, hex("#5ad1ff"), 2)
	local _2 = d1
	Kit.icon(levelRoot, "sun", -2, 3, 58, Color3.fromRGB(90, 200, 255), { ZIndex = 8 })
	levelXpText = Kit.text(levelRoot, 74, 3, 84, 14, "0/8", 10, { ZIndex = 9, TextColor3 = hex("#bfe9ff"), stroke = 1 })
end
levelText = Kit.text(levelRoot, 66, 17, 96, 28, "LVL 1", 22, { ZIndex = 9 })
local ignRoot, ignScale = scaledRoot("Ignition", Vector2.new(1, 0), 170, 34)
local ignBtn, ignInner = Kit.button(ignRoot, 30, 2, 136, 28, hex("#ff9a3a"), hex("#c2410c"), { ZIndex = 6 })
local ignText = Kit.text(ignInner, 0, Kit.ps(4, 3), 136, 22, "IGNITION 0/4", Kit.ps(14, 17), { ZIndex = ignInner.ZIndex, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
Kit.icon(ignRoot, "sun", 4, -4, 40, Color3.fromRGB(255, 140, 40), { ZIndex = 8 })
local _is = ignScale
ignBtn.MouseButton1Click:Connect(function()
	if shared.GalaxySectorsToggle then shared.GalaxySectorsToggle() end
end)
local function onIgnition()
	if (player:GetAttribute("Ignition") or 0) >= 1 then
		Kit.setText(ignText, "GALAXY " .. (player:GetAttribute("GalaxyLit") or 0) .. "%")
		Kit.recolour(ignBtn, hex("#7dd8ff"), hex("#1f6fd1"))
		return
	end
	local done, total = MapConfig.IgnitionDone(player)
	Kit.setText(ignText, "IGNITION " .. done .. "/" .. total)
end
for _, item in ipairs(MapConfig.Ignition) do player:GetAttributeChangedSignal(item.attribute):Connect(onIgnition) end
player:GetAttributeChangedSignal("Ignition"):Connect(onIgnition)
player:GetAttributeChangedSignal("GalaxyLit"):Connect(onIgnition)
onIgnition()
local function onLevel()
	local total = player:GetAttribute("XPTotal") or 0
	local level = player:GetAttribute("CosmicLevel") or 1
	local from, to = Econ.XPForLevel(level), Econ.XPForLevel(level + 1)
	Kit.setText(levelText, "LVL " .. level)
	Kit.setText(levelXpText, fmt(math.floor((total - from) * 10) / 10) .. "/" .. fmt(math.floor((to - from) * 10) / 10))
	levelFill.Size = UDim2.fromOffset(math.floor(118 * math.clamp((total - from) / math.max(to - from, 1e-6), 0, 1)), 2.5)
end
player:GetAttributeChangedSignal("XPTotal"):Connect(onLevel)
local lastLevel = player:GetAttribute("CosmicLevel") or 1
player:GetAttributeChangedSignal("CosmicLevel"):Connect(function()
	local now = player:GetAttribute("CosmicLevel") or 1
	if now > lastLevel then
		Kit.sound("milestone")
		Kit.tween(levelScale, { Scale = levelScale.Scale * 1.2 }, 0.08)
		task.delay(0.08, function() Kit.tween(levelScale, { Scale = screenScale() }, 0.25, Enum.EasingStyle.Back) end)
	end
	lastLevel = now
	onLevel()
end)
onLevel()
shared.GalaxyShardsTarget = function(): Vector2
	return shardsRoot.AbsolutePosition + GuiService:GetGuiInset() + Vector2.new(26, 32) * shardsScale.Scale
end
shared.GalaxyShardsPop = function()
	Kit.tween(shardsScale, { Scale = shardsScale.Scale * 1.15 }, 0.06)
	task.delay(0.06, function() Kit.tween(shardsScale, { Scale = screenScale() }, 0.18, Enum.EasingStyle.Back) end)
end

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
shared.GalaxyToast = function(str: string, colour: Color3?) toast(str, colour) end
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
local hot, hotScale = scaledRoot("Hotbar", Vector2.new(0.5, 1), 430, 110)
local KEYS = {
	{ key = "U", colour = hex("#ff9a3a"), icon = "stardust", name = "UPGRADES", window = "Upgrades" },
	{ key = "F", colour = hex("#ffd84a"), icon = "forge", name = "STAR FORGE", note = "STAR FORGE: opens at IGNITION 1 (Sector 2)", window = "Forge" },
	{ key = "T", colour = hex("#7dff8a"), icon = "planet", name = "TREE", window = "Tree" },
	{ key = "G", colour = hex("#b49bff"), icon = "book", name = "GUIDE", window = "Guide" },
	{ key = "E", colour = hex("#ff5a6a"), icon = "shard", name = "STORE", window = "Store" },
	{ key = "Q", colour = hex("#c9c4d2"), icon = "gear", name = "SETTINGS", window = "Settings" },
}
local keyUI = {}
for i, k in ipairs(KEYS) do
	local x, y = 32 + (i - 1) * 70, 50
	local before = {}
	for _, c in ipairs(hot:GetChildren()) do before[c] = true end
	local d = Kit.box(hot, x, y, 46, 46, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), Rotation = 45, ZIndex = 2 })
	Kit.grad(d, hex("#2c2735"), hex("#121016"), 90)
	Kit.stroke(d, hex("#0a070d"), 2)
	local ring = Kit.box(d, 2, 2, 42, 42, { ZIndex = 3 })
	local ringStroke = Kit.stroke(ring, if k.note then Color3.fromRGB(110, 104, 120) else k.colour, 2)
	local img = Kit.icon(hot, k.icon, x - 4, y - 6, if k.icon == "forge" then 54 else 52, nil, { ZIndex = 5 })
	local lockImg
	if k.note then img.ImageTransparency = 0.45 end
	if k.note then lockImg = Kit.icon(hot, "lock", x + 30, y + 26, 22, nil, { ZIndex = 7 }) end
	-- (the STAR FORGE key unlocks at Ignition 1)
	if k.window == "Forge" then
		local function unlock()
			local on = (player:GetAttribute("Ignition") or 0) >= 1
			img.ImageTransparency = if on then 0 else 0.45
			ringStroke.Color = if on then k.colour else Color3.fromRGB(110, 104, 120)
			if lockImg then lockImg.Parent.Visible = not on end
		end
		player:GetAttributeChangedSignal("Ignition"):Connect(unlock)
		unlock()
	end
	-- (the key letter: only with a keyboard; phones have none)
	if not Kit.phone() then Kit.text(hot, x - 8, y - 18, 20, 16, k.key, 12, { ZIndex = 8, stroke = 1.5 }) end
	local label = Kit.text(hot, x - 24, y - 38, 96, 18, k.name, 15, { ZIndex = 8, TextColor3 = k.colour, TextXAlignment = Enum.TextXAlignment.Center })
	local line = Kit.box(hot, x - 24, y - 19, 96, 2, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 })
	label.Parent.Visible = false
	line.Visible = false
	local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(x - 8, y - 8), Size = UDim2.fromOffset(62, 62), ZIndex = 10 }, hot)
	-- (everything this key put on the hotbar, so a hidden key can go and the others slide together)
	local parts = {}
	for _, c in ipairs(hot:GetChildren()) do
		if not before[c] then table.insert(parts, { inst = c, pos = c.Position, vis = c.Visible }) end
	end
	keyUI[k.key] = { label = label.Parent, line = line, hit = hit, diamond = d, x = x, y = y, x0 = x, sparkles = {}, parts = parts, shown = true }
end
-- STORE hidden until tutorial step 7 is done (#448: no shop during the tutorial); the other keys close the gap
local STORE_AT_STEP = 7
local function keyAllowed(k): boolean
	if k.window == "Store" then return (player:GetAttribute("TutStep") or 0) >= STORE_AT_STEP end
	return true
end
local keyDots -- (below)
local function layoutKeys()
	local shownList = {}
	for _, k in ipairs(KEYS) do
		if keyAllowed(k) then table.insert(shownList, k) end
	end
	local shift = (#KEYS - #shownList) * 35 -- (keeps the row centred)
	local slot = 0
	for _, k in ipairs(KEYS) do
		local ui = keyUI[k.key]
		local on = keyAllowed(k)
		if on then slot += 1 end
		local x = 32 + (math.max(slot, 1) - 1) * 70 + shift
		local dx = x - ui.x0
		for _, p in ipairs(ui.parts) do
			p.inst.Position = p.pos + UDim2.fromOffset(dx, 0)
			if not on then p.inst.Visible = false elseif not ui.shown then p.inst.Visible = p.vis end
		end
		if keyDots and keyDots[k.key] then
			keyDots[k.key].Position += UDim2.fromOffset(x - ui.x, 0)
			keyDots[k.key].Visible = on
		end
		ui.x = x
		ui.shown = on
	end
end
layoutKeys()
player:GetAttributeChangedSignal("TutStep"):Connect(layoutKeys)
-- the red "new" dot on a key (the GUIDE BOOK's new pages)
keyDots = {}
shared.GalaxyHotbarDot = function(key: string, on: boolean)
	local ui = keyUI[key]
	if not ui then return end
	if on and not keyDots[key] then
		keyDots[key] = Kit.redDot(hot, ui.x + 40, ui.y - 2, 16, 12)
	elseif not on and keyDots[key] then
		keyDots[key]:Destroy()
		keyDots[key] = nil
	end
end
if shared.GalaxyGuideRefresh then shared.GalaxyGuideRefresh() end

------------------------------------------------------------------------ the UPGRADES window: UpgradesPanel, the same v12 window
-- (and the same code) as the live island board
local win, winScale = scaledRoot("Upgrades", Vector2.new(0.5, 0.5), 700, 470)
win.Visible = false
local function afterBuy(_, incomeBefore: number)
	-- feedback on the HUD too: the counter pops, "+x/s" floats under it
	task.defer(function()
		local now = player:GetAttribute("Income") or 0
		if now > incomeBefore then floatText(top, 186, 52, "+" .. fmt(now - incomeBefore) .. "/s", hex("#7dff6b"), 14) end
	end)
	Kit.tween(topScale, { Scale = topScale.Scale * 1.08 }, 0.08)
	task.delay(0.08, function() Kit.tween(topScale, { Scale = screenScale() }, 0.2, Enum.EasingStyle.Back) end)
end
local panel = UpgradesPanel.new(win, {
	subject = player, chip = "ESSENCE", close = true, edgeGlow = false,
	buy = function(kind, arg) return request:InvokeServer(kind, arg) end,
	onBought = afterBuy, toast = toast, sound = Kit.sound,
})
local closeBtn = panel.closeButton
local tabUI = panel.tabUI

------------------------------------------------------------------------ the TREE window (hotbar T, alpha part 1): the island's
-- CONSTELLATION TREE + INFO screens side by side (IslandBoardsUI: the same code and look as the boards), your own numbers,
-- buys without an island slot (anywhere)
local treeWin, treeScale = scaledRoot("TreeWindow", Vector2.new(0.5, 0.5), 1124, 650)
treeWin.Visible = false
local treePanels, treeCtx = {}, nil
local treeOpen = false
-- (boards one job each, 5 Nov: INFO only shows the node picked on the TREE; nothing picked = "Tap a node on the TREE")
local function treeDefault()
	return { kind = "none" }
end
local function buildTreeWindow()
	if treeCtx then return end
	treeCtx = { subject = player, picked = false, sel = treeDefault(), sound = Kit.sound, size = Vector2.new(550, 650) }
	treeCtx.canAct = function() return true end
	treeCtx.buy = function(kind, arg) return request:InvokeServer(kind, arg) end
	treeCtx.select = function(kind, key)
		treeCtx.sel = { kind = kind, key = key }
		treeCtx.picked = true
		for _, p in pairs(treePanels) do p:refresh() end
	end
	treeCtx.bought = function() end -- (the selection stays on the node you bought)
	for i, id in ipairs({ "Tree", "Info" }) do
		local board = MapConfig.Boards.ById[id]
		-- (no `pair`: the screen draws its own title, like the stand boards)
		local spec = { id = id, title = board.title, Neon = board.Neon, Width = board.Width, Height = board.Height }
		local canvas = Kit.box(treeWin, (i - 1) * 574, 0, 550, 650, { ClipsDescendants = true, ZIndex = 2 })
		treePanels[id] = BoardsUI.new(id, canvas, spec, treeCtx)
	end
	-- the v12 close button (pink X) on the INFO screen's corner
	local closeTree = Kit.new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(1124 - 64, 14), Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 20 }, treeWin)
	Kit.corner(closeTree, 8)
	Kit.stroke(closeTree, Color3.new(1, 1, 1), 2, 0.1)
	Kit.grad(closeTree, hex("#ff7d8e"), hex("#e2334c"), 90)
	for _, r in ipairs({ 45, -45 }) do
		local bar = Kit.box(closeTree, 0, 0, 26, 5, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = r, ZIndex = 21 })
		bar.Position = UDim2.fromScale(0.5, 0.5)
		Kit.corner(bar, 2)
	end
	closeTree.MouseButton1Click:Connect(function() if shared.GalaxyCloseTree then shared.GalaxyCloseTree() end end)
end
local tutorialTree -- (the tutorial's target in the tree window: "R2_Starfire")
local tutorialTargets = panel.targets
local ess = panel.chipText
local function selectTab(id: string) panel:selectTab(id) end
local function refreshRows() panel:refresh() end

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
		if tab and tab ~= panel.currentTab then selectTab(tab) end
		return
	end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	open = true
	Kit.sound("open")
	win.Visible = true
	setKeySelected("U")
	selectTab(tab or panel.currentTab)
	layout()
	local ws = windowScale()
	winScale.Scale = ws * 0.8
	Kit.tween(winScale, { Scale = ws }, 0.25, Enum.EasingStyle.Back)
end
local function closeWindow()
	if not open then return end
	open = false
	Kit.sound("close")
	setKeySelected(nil)
	Kit.tween(winScale, { Scale = winScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function()
		if not open then win.Visible = false end
	end)
	layout()
end
closeBtn.MouseButton1Click:Connect(closeWindow)
local function closeTree()
	if not treeOpen then return end
	treeOpen = false
	Kit.sound("close")
	setKeySelected(nil)
	Kit.tween(treeScale, { Scale = treeScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function()
		if not treeOpen then treeWin.Visible = false end
	end)
	layout()
end
shared.GalaxyCloseTree = closeTree
local function openTree()
	if open then closeWindow() end
	if treeOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	buildTreeWindow()
	treeOpen = true
	Kit.sound("open")
	treeWin.Visible = true
	setKeySelected("T")
	if not treeCtx.picked then treeCtx.sel = treeDefault() end
	for _, p in pairs(treePanels) do p:refresh() end
	layout()
	local ws = treeScale.Scale
	treeScale.Scale = ws * 0.8
	Kit.tween(treeScale, { Scale = ws }, 0.25, Enum.EasingStyle.Back)
end
local tutorialTab -- set by the tutorial: the tab the current step needs
-- the side windows (GUIDE BOOK, SETTINGS: their own scripts): one open at a time with U / T; the phone hotbar hides for them too
local sideOpen = nil
shared.GalaxySideWindow = function(key: string, on: boolean)
	if on then
		if open then closeWindow() end
		if treeOpen then closeTree() end
		sideOpen = key
		setKeySelected(key)
	elseif sideOpen == key then
		sideOpen = nil
		setKeySelected(nil)
	end
	layout()
end
-- closes whichever side window is open (except `keep`)
shared.GalaxyCloseSide = function(keep: string?)
	if sideOpen == "G" and keep ~= "G" and shared.GalaxyGuideClose then shared.GalaxyGuideClose() end
	if sideOpen == "Q" and keep ~= "Q" and shared.GalaxySettingsClose then shared.GalaxySettingsClose() end
	if sideOpen == "E" and keep ~= "E" and shared.GalaxyStoreClose then shared.GalaxyStoreClose() end
	if sideOpen == "C" and keep ~= "C" and shared.GalaxyCodesClose then shared.GalaxyCodesClose() end
	if sideOpen == "S" and keep ~= "S" and shared.GalaxySectorsClose then shared.GalaxySectorsClose() end
	if sideOpen == "F" and keep ~= "F" and shared.GalaxyForgeClose then shared.GalaxyForgeClose() end
end
local function pressKey(k)
	if not keyAllowed(k) then return end
	if k.window == "Guide" then
		if shared.GalaxyGuideToggle then shared.GalaxyGuideToggle() end
	elseif k.window == "Store" then
		if shared.GalaxyStoreToggle then shared.GalaxyStoreToggle() end
	elseif k.window == "Forge" then
		-- (the STAR FORGE opens at Ignition 1; until then the key says so)
		if (player:GetAttribute("Ignition") or 0) < 1 or not shared.GalaxyForgeToggle then toast(k.note, k.colour) else shared.GalaxyForgeToggle() end
	elseif k.window == "Settings" then
		if shared.GalaxySettingsToggle then shared.GalaxySettingsToggle() end
	elseif k.window == "Tree" then
		if treeOpen then closeTree() else openTree() end
	elseif k.window then
		if treeOpen then closeTree() end
		if open then closeWindow() else openWindow(tutorialTab) end
	else
		toast(k.note, k.colour)
	end
end
for _, k in ipairs(KEYS) do
	keyUI[k.key].hit.MouseButton1Click:Connect(function() pressKey(k) end)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	for _, k in ipairs(KEYS) do
		if input.KeyCode == Enum.KeyCode[k.key] then pressKey(k) end
	end
end)

-- the map's boards (click / tap / E at the prompt) fire Galaxy.OpenWindow(id)
task.spawn(function()
	local opener = Galaxy:WaitForChild("OpenWindow", 60)
	if not opener then return end
	opener.Event:Connect(function(id)
		if id == "Upgrades" then
			openWindow(tutorialTab)
		elseif id == "Tree" then
			openTree()
		elseif id == "Forge" then
			if (player:GetAttribute("Ignition") or 0) >= 1 and shared.GalaxyForgeToggle then shared.GalaxyForgeToggle() else toast("STAR FORGE: opens at IGNITION 1", hex("#ffd84a")) end
		end
	end)
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
	-- (phones: the window may use the glow's margin too, so its text is as big as the screen allows)
	return math.min(screenScale(), room / (470 + Kit.ps(34, 6)), (viewport().X - 8) / 700)
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
	-- the tree window: as big as fits between the counter and the hotbar (and the screen's sides)
	-- (below the hint line while the tutorial runs)
	local hintRoom = if not small and (player:GetAttribute("TutStep") or 0) < #Econ.Tutorial then 46 * s else 0
	treeScale.Scale = math.min((room - hintRoom) / 650, (vp.X - 24) / 1124, s)
	treeWin.Position = UDim2.fromOffset(vp.X / 2, topEdge + hintRoom + (room - hintRoom) / 2)
	hot.Visible = not (small and (open or treeOpen or sideOpen ~= nil))
	-- the shards counter, right of the stardust counter; the Cosmic Level, left of it
	shardsRoot.Position = UDim2.new(0.5, math.floor(144 * s), 0, math.floor(16 * s))
	levelRoot.Position = UDim2.new(0.5, -math.floor(144 * s), 0, math.floor(16 * s))
	ignRoot.Position = UDim2.new(0.5, -math.floor(144 * s), 0, math.floor(64 * s))
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
	if affordCheck > 0.25 then
		affordCheck = 0
		if open then refreshRows() end
		if treeOpen then
			if not treeCtx.picked then treeCtx.sel = treeDefault() end
			for _, p in pairs(treePanels) do p:refresh() end
		end
	end
	if treeOpen then
		for _, p in pairs(treePanels) do p:step(dt) end
	end
end)

-- the goal bar: % of the 1M stardust this run's Supernova needs (from tutorial step 5 on); the shards counter
local function onGoal()
	local tutStep = player:GetAttribute("TutStep") or 0
	local novas = player:GetAttribute("Supernovas") or 0
	goal.Visible = tutStep >= 4 or novas >= 1
	local need = player:GetAttribute("SupernovaNeed") or Econ.NeedFor(novas)
	local k = math.clamp((player:GetAttribute("EarnedRun") or 0) / need, 0, 1)
	goalFill.Size = UDim2.fromOffset(math.floor(204 * k), 16)
	goalFill.Visible = k > 0
	Kit.setText(goalText, if k >= 1 then "SUPERNOVA READY!" else "SUPERNOVA " .. math.floor(k * 100) .. "%")
end
player:GetAttributeChangedSignal("EarnedRun"):Connect(onGoal)
player:GetAttributeChangedSignal("SupernovaNeed"):Connect(onGoal)
player:GetAttributeChangedSignal("TutStep"):Connect(onGoal)
player:GetAttributeChangedSignal("Supernovas"):Connect(onGoal)
onGoal()
local function onShards()
	shardsRoot.Visible = (player:GetAttribute("ShardsEarned") or 0) > 0 or shardsRoot:GetAttribute("Force") == true
	Kit.setText(shardsText, fmt(player:GetAttribute("Shards") or 0))
end
player:GetAttributeChangedSignal("Shards"):Connect(onShards)
player:GetAttributeChangedSignal("ShardsEarned"):Connect(onShards)
shardsRoot:GetAttributeChangedSignal("Force"):Connect(onShards)
onShards()
local function onIncome()
	Kit.setText(rateText, "+" .. fmt(player:GetAttribute("Income") or 0) .. "/s")
end
player:GetAttributeChangedSignal("Income"):Connect(onIncome)
onIncome()
local function onEssence() Kit.setText(ess, fmt(player:GetAttribute("Essence") or 0)) end
player:GetAttributeChangedSignal("Essence"):Connect(onEssence)
onEssence()
-- a level: the body chime; a new NAMED TIER (every 10 levels, x2) = the milestone sound instead (one sound per buy, also MAX)
local lastOwn = owned()
for k = 1, #Econ.Tiers do
	player:GetAttributeChangedSignal("Own" .. k):Connect(function()
		if open then refreshRows() end
		local now = player:GetAttribute("Own" .. k) or 0
		local was = lastOwn[k] or 0
		lastOwn[k] = now
		if now <= was then return end
		local crossed = was > 0 and Econ.NamedTier(now) > Econ.NamedTier(was)
		Kit.sound(if crossed then "milestone" else "buyBody")
	end)
	-- +BODY: a new copy flies into orbit (the map shows it); the chime
	player:GetAttributeChangedSignal("Copies" .. k):Connect(function()
		if open then refreshRows() end
	end)
end
for _, n in ipairs(Econ.Ring1) do player:GetAttributeChangedSignal("Node_" .. n.id):Connect(function() if open then refreshRows() end end) end
for _, p in ipairs(Econ.Perks) do player:GetAttributeChangedSignal("Perk_" .. p.id):Connect(function() if open then refreshRows() end end) end
player:GetAttributeChangedSignal("CosmicLevel"):Connect(function() if open then refreshRows() end end)

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
	Kit.text(c, 0, Kit.ps(3, 2), 46, 22, (step + 1) .. "/" .. #Econ.Tutorial, Kit.ps(15, 18), { ZIndex = 22, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.5 })
	Kit.text(f, 60, Kit.ps(8, 7), 236, 24, def.hint, Kit.ps(16, 18), { ZIndex = 21 })
	Kit.icon(f, "essence", 300, 2, 32, Color3.fromRGB(60, 230, 210), { ZIndex = 22 })
	Kit.text(f, 326, Kit.ps(8, 7), 34, 24, "+" .. def.essence, Kit.ps(16, 18), { ZIndex = 22, TextColor3 = hex("#7dffe9") })
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
	-- steps 5-7 (alpha part 1): the goal bar, the SUPERNOVA button, STARFIRE in the tree window
	if def.id == "HalfSupernova" then return if open or treeOpen then nil else goal, nil end
	if def.id == "Supernova" then
		local b = shared.GalaxySupernovaButton
		return if b and b.Visible and not shared.GalaxyCinematic then b else nil, nil
	end
	if def.id == "Starfire" then
		if shared.GalaxyCinematic then return nil, nil end
		if not treeOpen then return keyUI.T.hit, nil end
		local tree = treePanels.Tree
		local tile = tree and tree.targets.R2_Starfire
		if treeCtx.sel.kind == "node2" and treeCtx.sel.key == "Starfire" then return treePanels.Info.targets.Buy, nil end
		if tile then tree:reveal(tile) end
		return tile, nil
	end
	local wantTab, rowKey
	if def.id == "BuyAsteroid" then wantTab, rowKey = "BODIES", "Body0"
	elseif def.id == "FirstLight" then wantTab, rowKey = "PERKS", "Perk_FirstLight"
	elseif def.id == "FirstMoon" then wantTab, rowKey = "BODIES", if player:GetAttribute("Node_LunarPull") then "Body1" else "Unlock1"
	else return nil, nil end
	if not open then return keyUI.U.hit, wantTab end
	if panel.currentTab ~= wantTab then return tabUI[wantTab].button, wantTab end
	return tutorialTargets[rowKey], wantTab
end

local function tutorialComplete()
	-- (the message and the glowing Forge need the screen: the windows close first)
	closeWindow()
	closeTree()
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	local f = Kit.box(root, 0, 0, 520, 120, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), ZIndex = 70 })
	local sc = Instance.new("UIScale")
	sc.Scale = screenScale() * 0.6
	sc.Parent = f
	Kit.text(f, 0, 10, 520, 50, "TUTORIAL COMPLETE", 42, { ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 2.5,
		gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	Kit.text(f, 0, 64, 520, 26, #Econ.Tutorial .. "/" .. #Econ.Tutorial .. "  ESSENCE " .. fmt(player:GetAttribute("Essence") or 0), 20,
		{ ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#7dffe9") })
	-- (design: the end of the tutorial teases the next big thing)
	Kit.text(f, 0, 94, 520, 22, "NEXT: STAR FORGE AT SUPERNOVA 3", 16, { ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#ffd84a") })
	for i = 1, 10 do Kit.sparkle(f, math.random(0, 500), math.random(-10, 100), math.random(10, 20), i * 0.12) end
	Kit.tween(sc, { Scale = screenScale() }, 0.35, Enum.EasingStyle.Back)
	Kit.sound("milestone")
	-- (design: "the Forge gate glows in the world"): the Star Forge glows gold and pulses for 20 s
	task.spawn(function()
		local g = workspace:FindFirstChild("Galaxy")
		local forge = g and g:FindFirstChild("StarForge", true)
		if not forge then return end
		local h = Instance.new("Highlight")
		h.Name = "TeaserGlow"
		h.FillColor = Color3.fromRGB(255, 200, 70)
		h.OutlineColor = Color3.fromRGB(255, 230, 140)
		h.FillTransparency = 1
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Adornee = forge
		h.Parent = forge
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 190, 80)
		light.Range = 30
		light.Brightness = 0
		local anvil = forge:FindFirstChild("Anvil", true)
		local lp = if anvil and anvil:IsA("BasePart") then anvil elseif anvil then anvil:FindFirstChildWhichIsA("BasePart", true) else nil
		light.Parent = lp
		Kit.tween(h, { OutlineTransparency = 0 }, 0.6)
		Kit.tween(light, { Brightness = 3 }, 0.6)
		if Kit.calm() then
			h.FillTransparency = 0.7
		else
			Kit.tween(h, { FillTransparency = 0.55 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		end
		task.wait(20)
		Kit.tween(h, { OutlineTransparency = 1, FillTransparency = 1 }, 1)
		Kit.tween(light, { Brightness = 0 }, 1)
		task.wait(1.1)
		h:Destroy()
		light:Destroy()
	end)
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

-- while the step's board button is off screen: gold arrows on the floor from you to the board (Regrowth's trail)
local trailFolder = Instance.new("Folder")
trailFolder.Name = "TutorialTrail"
trailFolder.Parent = workspace
local trail = {}
for i = 1, 3 do
	local pt = Instance.new("Part")
	pt.Anchored, pt.CanCollide, pt.CanQuery, pt.CanTouch, pt.CastShadow = true, false, false, false, false
	pt.Transparency = 1
	pt.Size = Vector3.new(3, 0.05, 3)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = Kit.A.arrow
	decal.Color3 = Color3.fromRGB(255, 210, 90)
	decal.Parent = pt
	trail[i] = pt
end
local function showTrail(to: Vector3?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local flat = if to and root then Vector3.new(to.X - root.Position.X, 0, to.Z - root.Position.Z) else Vector3.zero
	if not root or not hum or flat.Magnitude < 9 then
		for _, pt in ipairs(trail) do pt.Parent = nil end
		return
	end
	local d = flat.Unit
	local floor = Vector3.new(root.Position.X, root.Position.Y - hum.HipHeight - root.Size.Y / 2 + 0.06, root.Position.Z)
	local drift = if Kit.calm() then 0 else (os.clock() * 3) % 3.2 -- (the arrows creep toward the board)
	for i, pt in ipairs(trail) do
		local s = 3 + (i - 1) * 3.2 + drift
		if s > flat.Magnitude - 5 then
			pt.Parent = nil
		else
			local at = floor + d * s
			pt.CFrame = CFrame.lookAt(at, at + d)
			pt.Parent = trailFolder
		end
	end
end

-- which board button a step points at: BODIES (bodies + their unlocks), STAR UPGRADES (ring 1), TREE then INFO (ring 2)
local function boardKeyFor(id: string): string?
	if id == "BuyAsteroid" then return "Body0" end
	if id == "FirstLight" then return "Perk_FirstLight" end
	if id == "FirstMoon" then return "Body1" end -- (UNLOCK on the Moon's row, then its UPGRADE)
	if id == "Starfire" then return if shared.GalaxyCinematic then nil else "R2_Starfire" end
	return nil
end
RunService.Heartbeat:Connect(function()
	local step = player:GetAttribute("TutStep") or 0
	tut.step = step
	if step >= #Econ.Tutorial then
		showTrail(nil)
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
	-- the steps done on YOUR island's boards point at the right board (like Regrowth; boards one job each, 5 Nov): the
	-- arrow + ring when the button is on screen, the floor trail while you're away from it. With a window open (or no
	-- island) the windows' own targets are used.
	local boardAt, boardTop, boardAspect, boardWorld
	local boardKey = boardKeyFor(Econ.Tutorial[step + 1].id)
	if boardKey and not open and not treeOpen and shared.GalaxyBoardTarget then
		local c, t, aspect = shared.GalaxyBoardTarget(boardKey)
		local cam = workspace.CurrentCamera
		if c and cam then
			boardWorld = c
			local sc, on = cam:WorldToViewportPoint(c)
			local st = cam:WorldToViewportPoint(t)
			if on and sc.Z > 0 then boardAt, boardTop, boardAspect = Vector2.new(sc.X, sc.Y), Vector2.new(st.X, st.Y), aspect end
		end
	end
	showTrail(boardWorld)
	if boardWorld and not boardAt then
		arrow.Visible, targetRing.Visible = false, false
	elseif boardAt then
		local h = math.max(12, (boardAt.Y - boardTop.Y) * 2)
		local bob = if Kit.calm() then 0 else math.sin(os.clock() * 5) * 6
		arrow.Visible = true
		arrow.Size = UDim2.fromOffset(44 * screenScale(), 44 * screenScale())
		arrow.Position = UDim2.fromOffset(boardAt.X, boardTop.Y - 4 + bob)
		targetRing.Visible = true
		targetRing.Position = UDim2.fromOffset(boardAt.X, boardAt.Y)
		targetRing.Size = UDim2.fromOffset(h * (boardAspect or 146 / 52) + 8, h + 8)
		targetRing.Rotation = 0
	elseif target and target.Parent and target.AbsoluteSize.X > 0 then
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
