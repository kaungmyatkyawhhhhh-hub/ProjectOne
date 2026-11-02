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
local UpgradesPanel = require(Galaxy:WaitForChild("UpgradesPanel"))
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
	subject = player, chip = "ESSENCE", close = true, paged = false, edgeGlow = false,
	buy = function(kind, arg) return request:InvokeServer(kind, arg) end,
	onBought = afterBuy, toast = toast, sound = Kit.sound,
})
local closeBtn = panel.closeButton
local tabUI = panel.tabUI
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
	open = true
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

-- the map's boards (click / tap / E at the prompt) fire Galaxy.OpenWindow(id)
task.spawn(function()
	local opener = Galaxy:WaitForChild("OpenWindow", 60)
	if not opener then return end
	opener.Event:Connect(function(id)
		if id == "Upgrades" then
			openWindow(tutorialTab)
		else
			for _, k in ipairs(KEYS) do
				if k.name == "TREE" and id == "Tree" then toast(k.note, k.colour) end
			end
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
	if panel.currentTab ~= wantTab then return tabUI[wantTab].button, wantTab end
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
	-- step 1 points at the BUY button on YOUR island's Upgrades board when it's on screen (like Regrowth); else the hotbar
	local boardAt, boardTop
	if Econ.Tutorial[step + 1].id == "BuyAsteroid" and not open and shared.GalaxyBoardTarget then
		local c, t = shared.GalaxyBoardTarget("Body0", "PLANETS")
		local cam = workspace.CurrentCamera
		if c and cam then
			local sc, on = cam:WorldToViewportPoint(c)
			local st = cam:WorldToViewportPoint(t)
			if on and sc.Z > 0 then boardAt, boardTop = Vector2.new(sc.X, sc.Y), Vector2.new(st.X, st.Y) end
		end
	end
	if boardAt then
		local h = math.max(12, (boardAt.Y - boardTop.Y) * 2)
		local bob = if Kit.calm() then 0 else math.sin(os.clock() * 5) * 6
		arrow.Visible = true
		arrow.Size = UDim2.fromOffset(44 * screenScale(), 44 * screenScale())
		arrow.Position = UDim2.fromOffset(boardAt.X, boardTop.Y - 4 + bob)
		targetRing.Visible = true
		targetRing.Position = UDim2.fromOffset(boardAt.X, boardAt.Y)
		targetRing.Size = UDim2.fromOffset(h * 146 / 52 + 8, h + 8)
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
