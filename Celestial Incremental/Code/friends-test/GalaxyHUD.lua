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
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Art = require(Galaxy:WaitForChild("ArtIds")) -- (LUMI's expressions + effects, 6 Nov)
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: one place that opens / closes the 2D windows)
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
local PHONE_TEST = Kit.testDevice() ~= nil -- (Studio: Workspace TestDevice / TestPhone, UIKit)
local root: GuiObject | ScreenGui = Kit.testRoot(gui) -- (7 Nov: the safe area; Studio: the emulated device)
local function viewport(): Vector2
	return Kit.viewport(root)
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
-- (7 Nov, live: the phone HUD overlapped everywhere: the PC HUD shrunk to 0.67 put text at 3-12 px and chips over each other
-- and under Roblox's buttons. A PHONE (short side < 500 logical px) gets its own arrangement (layout(), PH below): the
-- counter + shards + NEXT at the top centre; LVL then IGNITION at the top left UNDER Roblox's buttons (Kit.topbar); the chip
-- column under them (GalaxyPotions); the event pill under NEXT (GalaxyLive); LUMI's compact card above the hotbar; text >= 14)
local PH = Kit.phone()
local function screenScale(): number
	local vp = viewport()
	small = vp.Y < 500
	if small then return math.min(vp.X / 1000, vp.Y / 540) end
	-- (7 Nov, phone HUD: a TABLET (touch, short side >= 500) never under 1: at 0.92 an iPad drew texts under 14 px. A PC
	-- window keeps 0.6: at 1 a small window's HUD ran into itself)
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), if Kit.touch() then 1 else 0.6, 1.4)
end
-- (7 Nov, phone HUD) the phone's scale for its HUD pieces (they're drawn ~0.85 so the text stays >= 14 px) and LUMI's card
local function phoneScale(): number
	return math.clamp(viewport().Y / 375, 0.9, 1.05) * 0.85
end
function cardScaleNow(): number
	return if PH then 1 else screenScale() -- (phone: the art panel is made at phone size (72 px high): drawn 1:1, its text stays >= 14)
end
local function chipScale(): number
	return if PH then phoneScale() else screenScale()
end
local scaled = {} -- { frame, UIScale, baseOffsetFn }
local function scaledRoot(name, anchor: Vector2, w, h)
	local f = Kit.box(root, 0, 0, w, h, { Name = name, AnchorPoint = anchor })
	local s = Instance.new("UIScale")
	s.Parent = f
	table.insert(scaled, { f = f, s = s })
	return f, s
end

------------------------------------------------------------------------ the GALAXY LIT BAR (Phase 2.1, 6 Nov; Depth's depth bar = the
-- one big "how far" number): a thin bar across the top centre, always on: your sector + "GALAXY LIT 7%", filling. A tap
-- opens the GALAXY window. Everything else at the top sits LIT_H lower to make room.
local LIT_H = 28
local litRoot = scaledRoot("GalaxyBar", Vector2.new(0.5, 0), 360, 26)
local litBar, litFill, litText
do
	local shadow = Kit.box(litRoot, 0, 2, 360, 24, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 2 })
	Kit.corner(shadow, 12)
	litBar = Kit.box(litRoot, 0, 0, 360, 24, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, ClipsDescendants = true })
	Kit.corner(litBar, 12)
	Kit.stroke(litBar, Kit.INK, 2)
	Kit.grad(litBar, hex("#1d1a2a"), hex("#0e0c14"), 90)
	litFill = Kit.box(litBar, 0, 0, 0, 24, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4 })
	Kit.corner(litFill, 12)
	Kit.grad(litFill, hex("#bfe9ff"), hex("#5a7dff"), 90)
	Kit.box(litBar, 10, 2, 340, 1.5, { BackgroundTransparency = 0.6, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	litText = Kit.text(litRoot, 0, Kit.ps(3, 2), 360, 20, "EMBER BELT  ·  GALAXY LIT 0%", Kit.ps(15, 16), { ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
	Kit.sparkle(litRoot, -8, -2, 16, 0.3).ZIndex = 8
	local hit = Kit.new("TextButton", { Name = "Open", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, litRoot)
	hit.MouseButton1Click:Connect(function()
		Kit.sound("click")
		if shared.GalaxySectorsToggle then shared.GalaxySectorsToggle() end
	end)
end
local function onLit()
	local lit = player:GetAttribute("GalaxyLit") or 0
	local sector = Econ.Sectors[if (player:GetAttribute("Ignition") or 0) >= 1 then 2 else 1]
	Kit.setText(litText, sector.name .. "  ·  GALAXY LIT " .. lit .. "%")
	Kit.tween(litFill, { Size = UDim2.fromOffset(math.floor(360 * math.clamp(lit / 100, 0, 1)), 24) }, 0.4)
end
player:GetAttributeChangedSignal("GalaxyLit"):Connect(onLit)
player:GetAttributeChangedSignal("Ignition"):Connect(onLit)
onLit()

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
local rateText = Kit.text(top, 186, Kit.ps(33, 33), 90, 20, "+0/s", Kit.ps(15, 18), { ZIndex = 9, TextColor3 = hex("#ffc35a"), stroke = 1.2 })
counterText.ZIndex = 9
rateText.ZIndex = 9

-- the SUPERNOVA goal bar under the counter (design step 5: "SUPERNOVA 0% -> 100%"): shown from tutorial step 5 on; full = gold
local goal = Kit.box(top, 56, 64, 204, if PH then 20 else 16, { BackgroundTransparency = 0, BackgroundColor3 = hex("#16131b"), ZIndex = 4, Visible = false })
Kit.corner(goal, 8)
Kit.stroke(goal, Kit.INK, 2)
local goalFill = Kit.box(goal, 0, 0, 0, if PH then 20 else 16, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
Kit.corner(goalFill, 8)
local goalGrad = Kit.grad(goalFill, hex("#ffe08a"), hex("#ff9a1a"), 90)
local goalText = Kit.text(goal, 0, 1, 204, if PH then 18 else 14, "", if PH then 17 else 11, { ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.3 })
local _g = goalGrad

-- the NEXT line (#223, Tutorial 2 C): always under the counter, the cheapest next NAMED thing ("NEXT: MOON · 80", "NEXT: PAD
-- STAR GATE · 1M", "NEXT: IRON ASTEROID · 2.1K"); refreshed twice a second
local nextRoot = scaledRoot("Next", Vector2.new(0.5, 0), 360, 24)
local nextText = Kit.text(nextRoot, 0, 2, 360, 20, "", Kit.ps(14, 17), { ZIndex = 9, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#ffd84a"), stroke = 1.5, FontFace = Kit.FONT_HEAVY })
local function nextGoal(): string?
	local sd = player:GetAttribute("Stardust") or 0
	local perks = Econ.PerksOf(player)
	local nodes = {}
	for _, n in ipairs(Econ.Ring1) do nodes[n.id] = player:GetAttribute("Node_" .. n.id) == true end
	local best, bestCost = nil, math.huge
	local function offer(text: string, cost: number)
		if cost > sd and cost < bestCost then best, bestCost = text, cost end
	end
	for k = 0, #Econ.Tiers - 1 do
		local tier = Econ.Tiers[k + 1]
		local lv = player:GetAttribute("Own" .. (k + 1)) or 0
		local node = tier.unlock and Econ.Ring1ById[tier.unlock]
		if lv == 0 and node and not nodes[node.id] and (not node.requires or nodes[node.requires]) then
			offer(tier.name, node.cost)
		elseif lv > 0 then
			local at = Econ.NextTierAt(lv)
			if at then
				local cost = 0
				for l = lv, at - 1 do cost += Econ.Cost(k, l, perks) end
				offer(Econ.TierNames[Econ.NamedTier(lv) + 1] .. " " .. tier.name, cost)
			end
		end
	end
	local pads = player:GetAttribute("Pads") or 0
	local pad = Econ.Pads[pads + 1]
	if pad then offer("PAD " .. pad.name, pad.price) end
	if not best then return nil end
	return "NEXT: " .. best .. " · " .. fmt(bestCost)
end
task.spawn(function()
	while true do
		local t = if shared.GalaxyCinematic then nil else nextGoal()
		nextText.Parent.Visible = t ~= nil
		if t then Kit.setText(nextText, t) end
		task.wait(0.5)
	end
end)

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
	local cap = Kit.text(shardsRoot, 74, 0, 84, 16, "SHARDS", 14, { ZIndex = 9, TextColor3 = hex("#d9c2ff"), stroke = 1 })
	if PH then cap.Parent.Visible = false end -- (phone: the shard icon says it; 10 px was unreadable)
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
	levelXpText = Kit.text(levelRoot, 74, 0, 84, 16, "0/8", 14, { ZIndex = 9, TextColor3 = hex("#bfe9ff"), stroke = 1 })
	if PH then levelXpText.Parent.Visible = false end -- (phone: the bar under LVL shows it; 10 px was unreadable)
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
		task.delay(0.08, function() Kit.tween(levelScale, { Scale = chipScale() }, 0.25, Enum.EasingStyle.Back) end)
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
	task.delay(0.06, function() Kit.tween(shardsScale, { Scale = chipScale() }, 0.18, Enum.EasingStyle.Back) end)
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

-- the SERVER BANNER (#392, Phase 1 social): 3 s across the top for everyone, on a player's FIRST Supernova and a CELESTIAL
-- Forge roll. The potion card's look, wider: shadow, dark plate, the moment's colour on the edge, shine, sparkles.
local bannerRoot = scaledRoot("Banner", Vector2.new(0.5, 0), 560, 70)
local function banner(str: string, colour: Color3)
	for _, c in ipairs(bannerRoot:GetChildren()) do
		if c:GetAttribute("Banner") then c:Destroy() end
	end
	local W, H = 540, 56
	local b = Kit.box(bannerRoot, 10, -80, W, H)
	b:SetAttribute("Banner", true)
	local shadow = Kit.box(b, 0, 4, W, H, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 40 })
	Kit.corner(shadow, 10)
	local plate = Kit.box(b, 0, 0, W, H, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 41 })
	Kit.corner(plate, 10)
	Kit.stroke(plate, Kit.INK, 2.5)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(b, 3, 3, W - 6, H - 6, { ZIndex = 42 })
	Kit.corner(edge, 8)
	Kit.stroke(edge, colour, 2, 0.15)
	Kit.box(b, 12, 5, W - 24, 2, { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 42 })
	Kit.text(b, 20, Kit.ps(14, 13), W - 40, 30, str, Kit.ps(22, 22), { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 2,
		TextXAlignment = Enum.TextXAlignment.Center, gradient = ColorSequence.new(colour:Lerp(Color3.new(1, 1, 1), 0.65), colour) })
	Kit.sparkle(b, 22, 14, 16, 0).ZIndex = 45
	Kit.sparkle(b, W - 24, 40, 14, 0.5).ZIndex = 45
	Kit.sparkle(b, W - 60, 10, 10, 0.9).ZIndex = 45
	Kit.tween(b, { Position = UDim2.fromOffset(10, 4) }, 0.35, Enum.EasingStyle.Back)
	task.delay(3, function()
		if not b.Parent then return end
		Kit.tween(b, { Position = UDim2.fromOffset(10, -80) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.3)
		b:Destroy()
	end)
end
-- the SYSTEM CHAT line (#392): "<name> went SUPERNOVA (12)!" in the player's rank colour, for everyone in the server
local function chatLine(str: string, colour: Color3)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if not general then return end
	local safe = str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	pcall(function() (general :: TextChannel):DisplaySystemMessage('<font color="#' .. colour:ToHex() .. '"><b>' .. safe .. "</b></font>") end)
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
local hot, hotScale = scaledRoot("Hotbar", Vector2.new(0.5, 1), 430, 110)
local KEYS = {
	{ key = "U", colour = hex("#ff9a3a"), icon = "stardust", name = "UPGRADES", window = "Upgrades" },
	{ key = "F", colour = hex("#ffd84a"), icon = "forge", name = "STAR FORGE", note = "STAR FORGE: opens at IGNITION 1 (Sector 2)", window = "Forge" },
	{ key = "T", colour = hex("#7dff8a"), icon = "planet", name = "TREE", window = "Tree" },
	-- (Phase 2.4, #142: the DAILY window: streak, quests, playtime gifts; a red dot when something can be claimed)
	{ key = "J", colour = hex("#5ae6d2"), icon = "quests", name = "QUESTS", window = "Daily" },
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
	-- (7 Nov, phone HUD: the grey gear on the dark tile read as an EMPTY slot: it gets a soft light glow behind it)
	local img = Kit.icon(hot, k.icon, x - 4, y - 6, if k.icon == "forge" then 54 else 52, if k.icon == "gear" then Color3.fromRGB(215, 210, 235) else nil, { ZIndex = 5 })
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
	if not Kit.touch() then Kit.text(hot, x - 10, y - 20, 22, 18, k.key, 14, { ZIndex = 8, stroke = 1.5 }) end
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
-- STORE hidden until tutorial step 14 is done (#448: no shop before Supernova 1 / during the tutorial's start); the other keys close the gap
local STORE_AT_STEP = 14 -- (Tutorial 2: after the first Supernova + Starfire, like the old step 7)
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
	local shift = (6 - #shownList) * 35 -- (keeps the row centred: the bar was drawn for 6 keys)
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
	task.delay(0.08, function() Kit.tween(topScale, { Scale = chipScale() }, 0.2, Enum.EasingStyle.Back) end)
end
-- (7 Nov, item 4: on a PHONE the window is as wide as the screen allows (~0.94, so every caption is >= 14 px) and it
-- scrolls up / down inside the room between the counter and the bottom, like the TREE. The scroll frame is always
-- there; layout() turns it on for phones only (`small` isn't known at load: the camera may not have its size yet))
local upScroll = Kit.new("ScrollingFrame", { Name = "PhoneScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(700, 470),
	CanvasSize = UDim2.fromOffset(0, 470), ScrollBarThickness = 0, ScrollingEnabled = false, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
	ScrollBarImageColor3 = hex("#ffd84a") }, win)
local panel = UpgradesPanel.new(upScroll, {
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
local treeScroll: ScrollingFrame? = nil -- (phones: the stacked TREE + INFO)
local function buildTreeWindow()
	if treeCtx then return end
	treeCtx = { subject = player, picked = false, sel = treeDefault(), sound = Kit.sound, size = Vector2.new(550, 650) }
	treeCtx.canAct = function() return true end
	treeCtx.buy = function(kind, arg) return request:InvokeServer(kind, arg) end
	treeCtx.select = function(kind, key)
		treeCtx.sel = { kind = kind, key = key }
		treeCtx.picked = true
		for _, p in pairs(treePanels) do p:refresh() end
		-- (phones: INFO is under the TREE: a tap on a node scrolls down to it)
		if treeScroll and kind ~= "none" then Kit.tween(treeScroll, { CanvasPosition = Vector2.new(0, 674) }, 0.3) end
	end
	treeCtx.bought = function(kind, arg) -- (the selection stays on the node you bought; #284: the tree celebrates it)
		for _, p in pairs(treePanels) do p:celebrate(kind, arg) end
	end
	-- (#138, Phase 2.7: on a PHONE the two screens side by side drew every caption at 7-12 px; there they stack in one
	-- column, TREE over INFO, in a scroll, big enough for 14 px captions)
	local holder = treeWin
	if Kit.phone() then
		treeScroll = Kit.new("ScrollingFrame", { Name = "PhoneScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(574, 650),
			CanvasSize = UDim2.fromOffset(0, 1324), ScrollBarThickness = 10, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
			ScrollBarImageColor3 = hex("#b49bff") }, treeWin)
		holder = treeScroll
	end
	for i, id in ipairs({ "Tree", "Info" }) do
		local board = MapConfig.Boards.ById[id]
		-- (no `pair`: the screen draws its own title, like the stand boards)
		local spec = { id = id, title = board.title, Neon = board.Neon, Width = board.Width, Height = board.Height }
		local canvas = Kit.box(holder, if treeScroll then 0 else (i - 1) * 574, if treeScroll then (i - 1) * 674 else 0, 550, 650, { ClipsDescendants = true, ZIndex = 2 })
		treePanels[id] = BoardsUI.new(id, canvas, spec, treeCtx)
	end
	-- the v12 close button (pink X) on the INFO screen's corner
	local closeTree = Kit.new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset((if treeScroll then 550 else 1124) - 64, 14), Size = UDim2.fromOffset(44, 44),
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
local cardRoot -- (Tutorial 2's card, made below)
local function openWindow(tab: string?)
	if open then
		if tab and tab ~= panel.currentTab then selectTab(tab) end
		return
	end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	open = true
	WM.opened("U")
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
	WM.closed("U")
	Kit.sound("close")
	setKeySelected(nil)
	Kit.tween(winScale, { Scale = winScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function()
		if not open then win.Visible = false end
	end)
	layout()
end
closeBtn.MouseButton1Click:Connect(closeWindow)
WM.register("U", win, closeWindow)
local function closeTree()
	if not treeOpen then return end
	treeOpen = false
	WM.closed("T")
	Kit.sound("close")
	setKeySelected(nil)
	Kit.tween(treeScale, { Scale = treeScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function()
		if not treeOpen then treeWin.Visible = false end
	end)
	layout()
end
shared.GalaxyCloseTree = closeTree
WM.register("T", treeWin, closeTree)
local function openTree()
	if open then closeWindow() end
	if treeOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	buildTreeWindow()
	treeOpen = true
	WM.opened("T")
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
		WM.opened(key)
		setKeySelected(key)
	elseif sideOpen == key then
		sideOpen = nil
		WM.closed(key)
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
	if sideOpen == "R" and keep ~= "R" and shared.GalaxyReturnClose then shared.GalaxyReturnClose() end
	if sideOpen == "J" and keep ~= "J" and shared.GalaxyDailyClose then shared.GalaxyDailyClose() end
	if sideOpen == "P" and keep ~= "P" and shared.GalaxyStatsClose then shared.GalaxyStatsClose() end
	if sideOpen == "B" and keep ~= "B" and shared.GalaxyBlackHoleClose then shared.GalaxyBlackHoleClose() end
	if sideOpen == "W" and keep ~= "W" and shared.GalaxyWhatsNewClose then shared.GalaxyWhatsNewClose() end
end
local function pressKey(k)
	if not keyAllowed(k) then return end
	-- (owner 7 Nov: a key TOGGLES its window: pressed again (button or keybind) while it's open, it closes; once more, it
	-- opens. Boards and other openers still only open, they never close a window)
	if WM.isOpen(k.key) then
		WM.closeCurrent()
		return
	end
	if k.window == "Guide" then
		if shared.GalaxyGuideToggle then shared.GalaxyGuideToggle() end
	elseif k.window == "Store" then
		if shared.GalaxyStoreToggle then shared.GalaxyStoreToggle() end
	elseif k.window == "Forge" then
		-- (the STAR FORGE opens at Ignition 1; until then the key says so)
		if (player:GetAttribute("Ignition") or 0) < 1 or not shared.GalaxyForgeToggle then toast(k.note, k.colour) else shared.GalaxyForgeToggle() end
	elseif k.window == "Settings" then
		if shared.GalaxySettingsToggle then shared.GalaxySettingsToggle() end
	elseif k.window == "Daily" then
		if shared.GalaxyDailyToggle then shared.GalaxyDailyToggle() end
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
	-- (7 Nov: `from` = the board's position: the window closes when you walk 25+ studs away from it. A board can't
	-- toggle an open window shut: Forge / Black Hole only open)
	opener.Event:Connect(function(id, tab, from)
		if id == "Forge" and WM.isOpen("F") then return end
		if id == "BlackHole" and WM.isOpen("B") then return end
		if id == "Tree" and WM.isOpen("T") then return end
		task.defer(function() if typeof(from) == "Vector3" and WM.anyOpen() then WM.fromBoard(from) end end)
		if id == "Upgrades" then
			-- (a tapped board names its tab: BODIES / PERKS; the tutorial's arrow then points at the right tab inside)
			if treeOpen then closeTree() end
			openWindow(tab or tutorialTab)
		elseif id == "Tree" then
			openTree()
		elseif id == "Forge" then
			if (player:GetAttribute("Ignition") or 0) >= 1 and shared.GalaxyForgeToggle then shared.GalaxyForgeToggle() else toast("STAR FORGE: opens at IGNITION 1", hex("#ffd84a")) end
		elseif id == "BlackHole" then
			-- (3.1: your island's BLACK HOLE board or the plaza's gate)
			if shared.GalaxyBlackHoleToggle then shared.GalaxyBlackHoleToggle() end
		end
	end)
end)

------------------------------------------------------------------------ #163 TAP OUTSIDE CLOSES: WindowManager's backdrop (7 Nov). It was one
-- full-screen button under the windows, and a click on a window's plain frame (a row, the tab column) reached it and closed
-- the window. Now: four dim strips AROUND the open window only (ZIndex 0: under the hotbar)
WM.backdrop(root, 0)

------------------------------------------------------------------------ layout (screen size)
-- the window sits between the counter and the hotbar (on phones the hotbar hides while it's open)
local function windowRoom(): (number, number)
	local s = screenScale()
	local vp = viewport()
	local topEdge = (96 + LIT_H) * s -- (6 Nov overlap check: under the counter's SUPERNOVA bar)
	-- (on phones: down to the bottom edge, or above the hint line while the tutorial runs)
	local tutorialOn = (player:GetAttribute("TutStep") or 0) < #Econ.Tutorial
	local bottomEdge = if small then vp.Y - (if tutorialOn then 50 * s else 6) else vp.Y - 104 * s
	return topEdge, bottomEdge - topEdge
end
function windowScale(): number
	local _, room = windowRoom()
	-- (phones: the window may use the glow's margin too, so its text is as big as the screen allows)
	-- (7 Nov: phones fit the WIDTH and scroll the height, so the text stays readable)
	if small then return math.min(1, (viewport().X - 12) / 712) end -- (700 + the 12 px scroll-bar margin)
	return math.min(screenScale(), room / (470 + Kit.ps(34, 6)), (viewport().X - 8) / 700)
end
function layout()
	local s = screenScale()
	local vp = viewport()
	for _, e in ipairs(scaled) do
		if e.f ~= win then e.s.Scale = s end
	end
	litRoot.Position = UDim2.new(0.5, 0, 0, math.floor(4 * s))
	top.Position = UDim2.new(0.5, 0, 0, math.floor((8 + LIT_H) * s))
	toastRoot.Position = UDim2.new(0.5, 0, 0, math.floor((132 + LIT_H) * s)) -- (under the hint line)
	bannerRoot.Position = UDim2.new(0.5, 0, 0, math.floor((92 + LIT_H) * s)) -- (the server banner: under the counter)
	hot.Position = UDim2.new(0.5, 0, 1, -math.floor(4 * s))
	local ws = windowScale()
	if open then winScale.Scale = ws end
	do
		local _, room0 = windowRoom()
		local hgt = if small then math.min(470, math.floor(room0 / ws)) else 470
		-- (7 Nov, corners: the scroll bar runs in a 12 px margin BESIDE the window; at the window's own width Roblox drew it over
		-- the rounded right edge, a square layer at the corners)
		local bar = if hgt < 470 then 12 else 0
		win.Size = UDim2.fromOffset(700 + bar, hgt)
		upScroll.Size = UDim2.fromOffset(700 + bar, hgt)
		upScroll.ScrollingEnabled = hgt < 470
		upScroll.ScrollBarThickness = if hgt < 470 then 8 else 0
		if hgt >= 470 then upScroll.CanvasPosition = Vector2.zero end
	end
	local topEdge, room = windowRoom()
	win.Position = UDim2.fromOffset(vp.X / 2, topEdge + room / 2 + 15 * ws)
	-- the tree window: as big as fits between the counter and the hotbar (and the screen's sides)
	-- (below the hint line while the tutorial runs)
	local hintRoom = 0 -- (Tutorial 2: the card is at the bottom and hides while a window is open)
	if treeScroll then
		-- (phones: one column at ~0.78, as tall as the room, scrolling)
		local ts = math.min(0.78, (vp.X - 24) / 574)
		treeScale.Scale = ts
		treeWin.Size = UDim2.fromOffset(574, math.floor(room / ts))
		treeScroll.Size = UDim2.fromOffset(574, math.floor(room / ts))
	else
		treeScale.Scale = math.min((room - hintRoom) / 650, (vp.X - 24) / 1124, s)
	end
	treeWin.Position = UDim2.fromOffset(vp.X / 2, topEdge + hintRoom + (room - hintRoom) / 2)
	hot.Visible = not (small and (open or treeOpen or sideOpen ~= nil))
	-- (the potion / FRIENDS / GROUP strip hides while a window is open: it covered the TREE window)
	if shared.GalaxyPotionsShow then shared.GalaxyPotionsShow(not (open or treeOpen or sideOpen ~= nil)) end
	-- (and the NEXT line + the GALAXY pill: a window covers that space, on phones most of all)
	nextRoot.Visible = not (open or treeOpen or sideOpen ~= nil)
	ignRoot.Visible = not (open or treeOpen or sideOpen ~= nil)
	-- (the music is quieter while a big window is open: UPGRADES, the TREE, the STORE, the FORGE, the GALAXY, the GUIDE BOOK)
	Kit.musicDuck(open or treeOpen or sideOpen == "E" or sideOpen == "F" or sideOpen == "S" or sideOpen == "G")
	-- the shards counter, right of the stardust counter; the Cosmic Level, left of it
	shardsRoot.Position = UDim2.new(0.5, math.floor(144 * s), 0, math.floor((16 + LIT_H) * s))
	levelRoot.Position = UDim2.new(0.5, -math.floor(144 * s), 0, math.floor((16 + LIT_H) * s))
	-- (6 Nov overlap check: 64 put its sun icon on the LVL badge's, 82 put NEXT on the SUPERNOVA bar)
	ignRoot.Position = UDim2.new(0.5, -math.floor(144 * s), 0, math.floor((82 + LIT_H) * s))
	nextRoot.Position = UDim2.new(0.5, 0, 0, math.floor((92 + LIT_H) * s))
	-- (LUMI's card: above the hotbar)
	if cardRoot then
		cardRoot.Position = UDim2.new(0.5, 0, 1, -math.floor(110 * s))
		local us = cardRoot:FindFirstChildOfClass("UIScale")
		if us then us.Scale = s end
	end
	if PH then
		-- THE PHONE ARRANGEMENT (7 Nov): nothing under Roblox's buttons (Kit.topbar), nothing over anything else, text >= 14
		local P = phoneScale()
		local tb = Kit.topbar(root)
		litRoot.Visible = false -- (the GALAXY LIT bar: the IGNITION / GALAXY chip says it on phones)
		topScale.Scale = P
		top.Position = UDim2.new(0.5, 0, 0, 4)
		shardsScale.Scale = P
		shardsRoot.Position = UDim2.new(0.5, math.floor(140 * P + 4), 0, 4 + math.floor(8 * P))
		-- LVL, then IGNITION under it, at the left, below Roblox's buttons (side by side they ran into the counter on 667 px)
		levelScale.Scale = P
		levelRoot.AnchorPoint = Vector2.zero
		levelRoot.Position = UDim2.fromOffset(6, tb.height + 2)
		ignScale.Scale = P
		ignRoot.AnchorPoint = Vector2.zero
		ignRoot.Position = UDim2.fromOffset(6, tb.height + 2 + math.floor(76 * P))
		local nextScale = nextRoot:FindFirstChildOfClass("UIScale")
		if nextScale then nextScale.Scale = P end
		local below = 8 + math.floor(86 * P) -- (under the counter + its SUPERNOVA bar, with room for the counter's tick pop)
		nextRoot.Position = UDim2.new(0.5, 0, 0, below)
		local bScale = bannerRoot:FindFirstChildOfClass("UIScale")
		if bScale then bScale.Scale = P end
		bannerRoot.Position = UDim2.new(0.5, 0, 0, below + 22)
		local tScale = toastRoot:FindFirstChildOfClass("UIScale")
		if tScale then tScale.Scale = 1 end
		toastRoot.Position = UDim2.new(0.5, 0, 0, below + 22 + 32)
		-- the hotbar at the bottom; LUMI's card right above its keys (the keys' tops are 21 design px into the 110 bar)
		local hs = P * 0.95
		hotScale.Scale = hs
		hot.Position = UDim2.new(0.5, 0, 1, -2)
		if cardRoot then
			local cs = cardRoot:FindFirstChildOfClass("UIScale")
			if cs then cs.Scale = cardScaleNow() end
			cardRoot.Position = UDim2.new(0.5, 0, 1, -math.floor((110 - 21) * hs) - 8)
		end
		-- (GalaxyPotions hangs its column under IGNITION; GalaxyLive puts the event pill under NEXT)
		shared.GalaxyColumnTop = function(): number return tb.height + 2 + math.floor((76 + 34) * P) + 8 end
		shared.GalaxyBannerTop = function(): number return below + 22 end
		if shared.GalaxyColumnLayout then shared.GalaxyColumnLayout() end
	end
end
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function() layout() end)
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
	goal.Visible = tutStep >= 8 or novas >= 1
	local need = player:GetAttribute("SupernovaNeed") or Econ.NeedFor(novas)
	local k = math.clamp((player:GetAttribute("EarnedRun") or 0) / need, 0, 1)
	goalFill.Size = UDim2.fromOffset(math.floor(204 * k), if PH then 20 else 16)
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
-- #283 + #239: every second the counter gives a tiny pop and a soft tick whose pitch climbs the pentatonic as income grows
-- (one step every x3 of income; quiet; none in a cinematic or with Reduced Motion for the pop)
local PENTA = { 1, 9 / 8, 5 / 4, 3 / 2, 5 / 3, 2, 9 / 4, 5 / 2, 3, 10 / 3, 4 }
task.spawn(function()
	while true do
		task.wait(1)
		local inc = player:GetAttribute("Income") or 0
		if inc > 0 and not shared.GalaxyCinematic then
			local step = math.clamp(math.floor(math.log(inc + 1, 3)), 0, 32)
			local pitch = PENTA[step % 10 + 1] * (if step >= 10 then 2 else 1) * 0.5
			Kit.sound("click", { volume = 0.16, pitch = math.min(pitch, 2.2) })
			if not Kit.calm() then
				Kit.tween(topScale, { Scale = chipScale() * 1.035 }, 0.06)
				task.delay(0.06, function() Kit.tween(topScale, { Scale = chipScale() }, 0.16) end)
			end
		end
	end
end)
player:GetAttributeChangedSignal("Income"):Connect(onIncome)
onIncome()
local function onEssence() Kit.setText(ess, fmt(player:GetAttribute("Essence") or 0)) end
player:GetAttributeChangedSignal("Essence"):Connect(onEssence)
onEssence()
-- the NEW moment (#222): "NEW: MOON!" / "NEW: ROCK ASTEROID!" for 1.5 s (skippable: any tap), a small FOV nudge (not with
-- Reduced Motion), sparkles; one at a time (a newer one replaces it)
local momentRoot, momentScale = scaledRoot("NewMoment", Vector2.new(0.5, 0.5), 620, 110)
momentRoot.Visible = false
local momentText = Kit.text(momentRoot, 0, 8, 620, 56, "", 46, { ZIndex = 60, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 3,
	gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
local momentSub = Kit.text(momentRoot, 0, 66, 620, 28, "", 22, { ZIndex = 60, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#7dff6b"), stroke = 2 })
local momentToken = 0
local function hideMoment() momentRoot.Visible = false end
UserInputService.InputBegan:Connect(function(input)
	if momentRoot.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then hideMoment() end
end)
local CutsceneMod
task.spawn(function() CutsceneMod = require(Galaxy:WaitForChild("GalaxyCutscene")) end)
local function newMoment(title: string, sub: string)
	if shared.GalaxyCinematic then return end
	-- (cutscene template, 5 Nov: the MINI version, 1.2 s, no black frame: the body's colour, the sparkle, a small starburst)
	if CutsceneMod and not CutsceneMod.busy() then
		task.spawn(CutsceneMod.play, { mini = true, length = 1.2, drop = 0.25, colour = Color3.fromRGB(255, 205, 90), symbol = Kit.A.sparkle, title = title, sub = sub })
		return
	end
	momentToken += 1
	local token = momentToken
	Kit.setText(momentText, title)
	Kit.setText(momentSub, sub)
	local vp = viewport()
	momentRoot.Position = UDim2.fromOffset(vp.X / 2, vp.Y * 0.3)
	momentRoot.Visible = true
	local s = screenScale()
	momentScale.Scale = s * 0.6
	Kit.tween(momentScale, { Scale = s }, 0.3, Enum.EasingStyle.Back)
	for i = 1, 8 do
		local sp = Kit.sparkle(momentRoot, math.random(60, 560), math.random(0, 90), math.random(12, 22), i * 0.05)
		task.delay(1.6, function() sp:Destroy() end)
	end
	Kit.sound("milestone")
	local cam = workspace.CurrentCamera
	if cam and not Kit.calm() then
		local fov = cam.FieldOfView
		Kit.tween(cam, { FieldOfView = fov + 3 }, 0.12)
		task.delay(0.12, function() Kit.tween(cam, { FieldOfView = fov }, 0.4) end)
	end
	task.delay(1.5, function() if momentToken == token then hideMoment() end end)
end
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
		local tierName = Econ.Tiers[k].name
		if was == 0 then
			newMoment("NEW: " .. tierName .. "!", "a new body in your sky")
		elseif crossed then
			newMoment("NEW: " .. Econ.TierName(now) .. " " .. tierName .. "!", tierName .. " income x2")
		else
			Kit.sound("buyBody")
		end
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
layout()
-- TUTORIAL 2 (5 Nov): LUMI's CARD, bottom centre above the hotbar (Regrowth's NPC card): the star spirit's portrait, her
-- name, "STEP 4/20", the goal, a segmented bar with the live counter ("3/5"), the reward (+Essence, +~20 s of stardust);
-- HIDE (shrinks it to the goal line) and SKIP (red, "not recommended": a second tap skips the whole tutorial)
local cardScale
-- (7 Nov, the owner's ART (U5, Kit.HudArt): LUMI's panel = hud_lumi_panel, 9-sliced (SliceCenter 311,89 - 962,200 of the
-- 1024x284 image) so its portrait RING (the left 30%) is never stretched; LUMI's portrait sits inside the ring. In the bar:
-- the goal line, then hud_bar_track + hud_bar_fill (the progress) and the counter. PC: hud_tag_step ("STEP 1/20") and
-- hud_slot_reward (+1 / +BONUS); both: hud_btn_close (hide) + hud_btn_skip as small round buttons on the top-right rim.
-- Phone: shorter, no STEP tag / reward)
local ART = Kit.HudArt
local PH_ = PH
local CH0 = if PH_ then 72 else 112 -- (the panel's height; the art is 284 high)
local K = CH0 / 284
local CW0 = if PH_ then 390 else 600
cardRoot, cardScale = scaledRoot("TutCard", Vector2.new(0.5, 1), CW0, CH0)
local card = {}
do
	local function img(parent, id, x, y, w, h, z, props)
		local i = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = "rbxassetid://" .. id, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = z }, parent)
		if props then for k, v in pairs(props) do i[k] = v end end
		return i
	end
	-- (the stored art is 1022x283; cut by hand (Kit.slice3): the ring part (0..311) and the right cap at their own shape)
	local panelF = Kit.slice3(cardRoot, ART.lumiPanel, 1022, 283, 311, 960, 0, 0, CW0, CH0, 20)
	card.panel = panelF
	-- the portrait inside the ring (the ring's inside: centre 137,148, ~190 across in the art)
	local PS = math.floor(176 * K)
	local ring = Kit.box(cardRoot, math.floor(137 * K - PS / 2), math.floor(148 * K - PS / 2), PS, PS, { ZIndex = 21 })
	card.halo = Kit.new("ImageLabel", { Name = "LumiHalo", BackgroundTransparency = 1, Image = Art.lumiFx.halo, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3), ImageTransparency = 0.35, ZIndex = 20 }, ring)
	card.halo:SetAttribute("AllowOverlap", true)
	if not Kit.calm() then
		Kit.tween(card.halo, { Size = UDim2.fromScale(1.45, 1.45), ImageTransparency = 0.55 }, 1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	end
	card.portrait = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Art.lumi.talking, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.08, 1.08), ZIndex = 22 }, ring)
	card.ring = ring
	card.slot = ring
	-- the bar's inside: from just past the ring to the right cap; the art's dark band is y 68-227 of 284
	local X0 = math.floor(330 * K)
	local X1 = CW0 - math.floor(70 * K) - (if PH_ then 0 else math.floor(CH0 * 0.62))
	local Y0, Y1 = math.floor(68 * K), math.floor(227 * K)
	local lineH = math.floor((Y1 - Y0) * 0.5)
	local _, _, lineHolder = Kit.text(cardRoot, X0, Y0 + 1, X1 - X0, lineH, "", if PH_ then 17 else 22, { ZIndex = 23, FontFace = Kit.FONT_HEAVY, stroke = 1.8, TextScaled = true })
	for _, l in ipairs(lineHolder:GetChildren()) do
		if l:IsA("TextLabel") then
			Kit.new("UITextSizeConstraint", { MaxTextSize = if PH_ then 17 else 22, MinTextSize = 14 }, l)
			card.line = l
		end
	end
	-- the progress: hud_bar_track + hud_bar_fill (5% inside), the counter right of it
	local countW = if PH_ then 44 else 56
	local barH = math.max(12, math.floor((Y1 - Y0) * 0.36))
	local barY = Y1 - barH - 1
	local barW = X1 - X0 - countW - 6
	local track = Kit.slice3(cardRoot, ART.barTrack, 584, 120, 60, 524, X0, barY, barW, barH, 22)
	-- (the fill is drawn full length inside a clipping frame; the progress = that frame's width)
	local fillHolder = Kit.box(track, math.floor(barW * 0.03), math.floor(barH * 0.18), math.floor(barW * 0.94), math.floor(barH * 0.64), { ZIndex = 23, ClipsDescendants = true })
	Kit.slice3(fillHolder, ART.barFill, 465, 92, 46, 419, 0, 0, math.floor(barW * 0.94), math.floor(barH * 0.64), 23)
	card.fill = fillHolder
	card.fillW = math.floor(barW * 0.94)
	card.segsF = track
	card.segs = {}
	local _, _, countHolder = Kit.text(cardRoot, X0 + barW + 6, barY + math.floor((barH - 20) / 2), countW, 20, "0/1", if PH_ then 16 else 18, { ZIndex = 23, FontFace = Kit.FONT_HEAVY, stroke = 1.5 })
	for _, l in ipairs(countHolder:GetChildren()) do if l:IsA("TextLabel") then card.count = l end end
	-- STEP tag (PC): on the top rim, over the bar's start
	local head = Kit.new("Frame", { Name = "Head", BackgroundTransparency = 1, Position = UDim2.fromOffset(X0, -math.floor(CH0 * 0.08)), Size = UDim2.fromOffset(96, 28), Visible = not PH_, ZIndex = 24 }, cardRoot)
	Kit.slice3(head, ART.tagStep, 437, 164, 82, 355, 0, 0, 96, 28, 24)
	card.step = Kit.text(head, 0, 5, 96, 18, "STEP 1/20", 14, { ZIndex = 25, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY, stroke = 0, TextColor3 = hex("#3a2205") })
	card.name = card.step
	card.chip = head
	card.head = head
	-- the reward slot (PC): right end of the bar
	local RS = math.floor(CH0 * 0.56)
	local reward = Kit.new("Frame", { Name = "Reward", BackgroundTransparency = 1, Position = UDim2.fromOffset(X1 + 6, math.floor((CH0 - RS) / 2)), Size = UDim2.fromOffset(RS, RS), Visible = not PH_, ZIndex = 22 }, cardRoot)
	img(reward, ART.slotReward, 0, 0, RS, RS, 22)
	Kit.icon(reward, "essence", math.floor(RS * 0.1), math.floor(RS * 0.04), math.floor(RS * 0.46), nil, { ZIndex = 23 })
	card.ess = Kit.text(reward, math.floor(RS * 0.5), math.floor(RS * 0.1), math.floor(RS * 0.46), 18, "+1", 16, { ZIndex = 24, TextColor3 = hex("#7dffe9"), FontFace = Kit.FONT_HEAVY, stroke = 1.5 })
	Kit.text(reward, 0, math.floor(RS * 0.58), RS, 16, "+BONUS", 14, { ZIndex = 24, TextColor3 = hex("#ffc35a"), FontFace = Kit.FONT_HEAVY, stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	card.reward = reward
	-- HIDE + SKIP: small round buttons on the top-right rim
	local BS = if PH_ then 26 else 32
	local function roundBtn(id, x)
		local b = Kit.new("ImageButton", { BackgroundTransparency = 1, Image = "rbxassetid://" .. id, AutoButtonColor = false, Position = UDim2.fromOffset(x, -math.floor(BS * 0.35)),
			Size = UDim2.fromOffset(BS, BS), ZIndex = 26 }, cardRoot)
		return b
	end
	local skipB = roundBtn(ART.btnSkip, CW0 - BS - math.floor(28 * K))
	local hideB = roundBtn(ART.btnClose, CW0 - BS * 2 - 4 - math.floor(28 * K))
	card.hideB, card.skipB, card.hideH, card.skipH = hideB, skipB, hideB, skipB
	-- (the old text labels on these buttons: kept as hidden labels so the rest of the code can set them)
	card.hideText = Kit.text(hideB, 0, 0, BS, BS, "", 14, { ZIndex = 27, Visible = false })
	card.skipText = Kit.text(skipB, 0, 0, BS, BS, "", 14, { ZIndex = 27, Visible = false })
	card.fitPanel = function() end
end
local cardHidden, skipArmed = false, false
local cardKeep = { [card.hideB] = true }
local function setCardHidden(h: boolean)
	cardHidden = h
	-- (hidden: only the round button stays, turned over (its chevron points up = show))
	for _, c in ipairs(cardRoot:GetChildren()) do
		if c:IsA("GuiObject") and not cardKeep[c] then
			if h then
				c:SetAttribute("WasVisible", c.Visible)
				c.Visible = false
			elseif c:GetAttribute("WasVisible") ~= nil then
				c.Visible = c:GetAttribute("WasVisible")
				c:SetAttribute("WasVisible", nil)
			end
		end
	end
	card.hideB.Rotation = if h then 180 else 0
end
card.hideB.MouseButton1Click:Connect(function()
	Kit.sound("tab")
	setCardHidden(not cardHidden)
end)
card.skipB.MouseButton1Click:Connect(function()
	if not skipArmed then
		skipArmed = true
		if shared.GalaxyToast then shared.GalaxyToast("TAP » AGAIN TO SKIP THE TUTORIAL (not advised)", hex("#ff7d8e")) end
		Kit.sound("error")
		task.delay(3, function() skipArmed = false end)
		return
	end
	skipArmed = false
	request:InvokeServer("SkipTutorial")
end)
local cardStep = -1
local cardGoneAt = 0 -- (when the card was last hidden: a card back after >0.6 s gets the poof)
local happyUntil = 0 -- (a step just done: LUMI is happy, with the heart star, for 0.6 s)
local function clearHint()
	if cardRoot.Visible then cardGoneAt = os.clock() end
	cardRoot.Visible = false
end
-- LUMI's face for the step (happy while a finished step is celebrated)
local function lumiFace(step: number): string
	if os.clock() < happyUntil then return "happy" end
	local def = Econ.Tutorial[step + 1]
	return def and def.face or "talking"
end
-- phones: the card is 0.8x, so the portrait grows inside it to stay at least 72 px on screen (it pops out above the card)
local function sizePortrait()
	do return end -- (7 Nov: the art's ring holds the portrait at a fixed size)
	local s = cardScale.Scale
	local p = if s > 0 then math.max(84, math.ceil(74 / s)) else 84
	card.ring.Size = UDim2.fromOffset(p, p)
	card.ring.Position = UDim2.fromOffset(8, 92 - p)
	local c = card.ring:FindFirstChildOfClass("UICorner")
	if c then c.CornerRadius = UDim.new(0.5, 0) end
end
-- the card opens: a poof where LUMI appears + a short sparkle trail flying in (Reduced Motion: none, she just shows)
local function lumiAppear()
	if Kit.calm() then return end
	local poof = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Art.lumiFx.appearPoof, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6), ZIndex = 26 }, card.ring)
	Kit.tween(poof, { Size = UDim2.fromScale(1.9, 1.9) }, 0.35, Enum.EasingStyle.Back)
	task.delay(0.25, function() Kit.tween(poof, { ImageTransparency = 1 }, 0.3) end)
	task.delay(0.6, function() poof:Destroy() end)
	local trail = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Art.lumiFx.sparkleTrail, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(-1.2, 0.2), Size = UDim2.fromScale(1.8, 1.1), ZIndex = 25 }, card.ring)
	Kit.tween(trail, { Position = UDim2.fromScale(0.2, 0.5) }, 0.35, Enum.EasingStyle.Quad)
	task.delay(0.3, function() Kit.tween(trail, { ImageTransparency = 1 }, 0.25) end)
	task.delay(0.6, function() trail:Destroy() end)
	local inS = card.portrait:FindFirstChild("PopIn") or Kit.new("UIScale", { Name = "PopIn" }, card.portrait)
	inS.Scale = 0.3
	Kit.tween(inS, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
end
-- a step done: the heart star pops (0.6 s) over a happy LUMI, then the next expression
local function lumiHeart(hold: number?)
	local t = hold or 0.6 -- (a Studio test can hold it longer for a screenshot)
	happyUntil = os.clock() + t
	card.portrait.Image = Art.lumi.happy
	if Kit.calm() then return end
	local heart = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Art.lumiFx.heartStar, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.82, 0.12), Size = UDim2.fromScale(0.2, 0.2), ZIndex = 27 }, card.ring)
	Kit.tween(heart, { Size = UDim2.fromScale(0.75, 0.75), Position = UDim2.fromScale(0.86, -0.05) }, 0.25, Enum.EasingStyle.Back)
	task.delay(t - 0.25, function() Kit.tween(heart, { ImageTransparency = 1, Position = UDim2.fromScale(0.9, -0.35) }, 0.25) end)
	task.delay(t + 0.02, function() heart:Destroy() end)
end
-- (Studio test switch: Workspace TestLumiHeart = any new value plays the step-done heart)
if RunService:IsStudio() then workspace:GetAttributeChangedSignal("TestLumiHeart"):Connect(function() lumiHeart(tonumber(workspace:GetAttribute("TestLumiHold"))) end) end
-- pointing steps: LUMI's pointer floats from her toward the board on screen, again and again
local pointerNext = 0
local function lumiPoint(at: Vector2?)
	if not at or Kit.calm() or not cardRoot.Visible or os.clock() < pointerNext then return end
	pointerNext = os.clock() + 1.6
	local r = card.ring
	local from = r.AbsolutePosition + r.AbsoluteSize / 2 + GuiService:GetGuiInset()
	local d = at - from
	if d.Magnitude < 40 then return end
	local u = d.Unit
	local size = math.max(48, r.AbsoluteSize.X * 0.8)
	local p = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Art.lumiFx.pointer, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(from.X + u.X * size * 0.6, from.Y + u.Y * size * 0.6), Size = UDim2.fromOffset(size, size),
		Rotation = math.deg(math.atan2(u.Y, u.X)), ImageTransparency = 0.1, ZIndex = 58 }, gui)
	local to = from + d * 0.45
	Kit.tween(p, { Position = UDim2.fromOffset(to.X, to.Y) }, 1.1, Enum.EasingStyle.Sine)
	task.delay(0.7, function() Kit.tween(p, { ImageTransparency = 1 }, 0.4) end)
	task.delay(1.15, function() p:Destroy() end)
end
local function showHint(step: number)
	local def = Econ.Tutorial[step + 1]
	if not def then cardRoot.Visible = false return end
	if not cardRoot.Visible then
		cardRoot.Visible = true
		sizePortrait()
		if os.clock() - cardGoneAt > 0.6 then lumiAppear() end
	end
	local face = Art.lumi[lumiFace(step)] or Art.lumi.talking
	if card.portrait.Image ~= face then card.portrait.Image = face end
	if cardStep ~= step then
		cardStep = step
		Kit.setText(card.step, "STEP " .. (step + 1) .. "/" .. #Econ.Tutorial)
		Kit.setText(card.line, def.hint)
		Kit.setText(card.ess, "+" .. def.essence)
		if not Kit.calm() then
			local cs = cardScaleNow()
			cardScale.Scale = cs * 0.9
			Kit.tween(cardScale, { Scale = cs }, 0.25, Enum.EasingStyle.Back)
			-- (the first frame's viewport can be 1x1: settle on the real scale after the pop)
			task.delay(0.3, function() cardScale.Scale = cardScaleNow() sizePortrait() end)
		end
	end
	-- the live counter + the segments
	local v = math.min(tonumber(player:GetAttribute(def.attr)) or 0, def.need)
	Kit.setText(card.count, (if def.attr == "SupernovaPct" then v .. "%" else v .. "/" .. def.need))
	if card.fill then
		card.fill.Size = UDim2.fromOffset(math.max(0, math.floor(card.fillW * math.clamp(v / def.need, 0, 1))), card.fill.Size.Y.Offset)
	end
	local n = math.min(def.need, 10)
	local lit = math.floor(v / def.need * n + 1e-6)
	for i, seg in ipairs(card.segs) do
		seg.Visible = i <= n and not cardHidden
		seg.BackgroundColor3 = if i <= lit then hex("#7dff6b") else hex("#2a2433")
		seg.Size = UDim2.fromOffset(math.floor(card.SEG_W / n) - 3, 14)
		seg.Position = UDim2.fromOffset((i - 1) * math.floor(card.SEG_W / n), 0)
	end
end
local arrow = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.arrow, Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0.5, 1), Visible = false, ZIndex = 60 }, gui)
local targetRing = Kit.new("Frame", { BackgroundTransparency = 1, Visible = false, ZIndex = 59, AnchorPoint = Vector2.new(0.5, 0.5) }, gui)
Kit.corner(targetRing, 8)
local ringStroke = Kit.stroke(targetRing, hex("#ffd84a"), 3)
Kit.tween(ringStroke, { Transparency = 0.7 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-- what the current step points at (in the windows; the boards / pads: boardKeyFor, below)
local function stepTarget(step: number): (GuiObject?, string?)
	local def = Econ.Tutorial[step + 1]
	if not def then return nil, nil end
	local id = def.id
	if id == "Ready" then return if open or treeOpen then nil else goal, nil end
	if id == "Supernova" or id == "Nova2" or id == "Nova6" then
		local b = shared.GalaxySupernovaButton
		return if b and b.Visible and not shared.GalaxyCinematic then b else nil, nil
	end
	if id == "Ignition" then return if shared.GalaxyCinematic then nil else ignBtn, nil end
	if id == "Starfire" or id == "StarTier" then
		if shared.GalaxyCinematic then return nil, nil end
		if not treeOpen then return keyUI.T.hit, nil end
		local tree = treePanels.Tree
		local tile = tree and tree.targets["R2_" .. id]
		if treeCtx.sel.kind == "node2" and treeCtx.sel.key == id then return treePanels.Info.targets.Buy, nil end
		if tile then tree:reveal(tile) end
		return tile, nil
	end
	local wantTab, rowKey
	local function unlockOr(k: number) return if (player:GetAttribute("Own" .. (k + 1)) or 0) > 0 then "Body" .. k else "Unlock" .. k end
	if id == "Asteroid3" or id == "Rock" then wantTab, rowKey = "BODIES", "Body0"
	elseif id == "FirstLight" then wantTab, rowKey = "PERKS", "Perk_FirstLight"
	elseif id == "Moon" then wantTab, rowKey = "BODIES", unlockOr(1)
	elseif id == "Copy" then wantTab, rowKey = "BODIES", "Copy0"
	elseif id == "Planet" then wantTab, rowKey = "BODIES", unlockOr(2)
	elseif id == "Giant" then wantTab, rowKey = "BODIES", unlockOr(3)
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
	Kit.text(f, 0, 94, 520, 22, "THE STAR FORGE IS OPEN: PRESS F", 16, { ZIndex = 71, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#ffd84a") })
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

event.OnClientEvent:Connect(function(kind, a, b, ...)
	if kind == "TutorialStep" then
		tut.step = a
		tut.idleSince = os.clock()
		clearHint()
		lumiHeart()
		-- the step's payout floats up from the counter: +Essence, +stardust (Tutorial 2)
		floatText(top, 120, 70, "+" .. b .. " ESSENCE", hex("#7dffe9"), 16)
		local pay = tonumber((...)) or 0
		if pay > 0 then task.delay(0.25, function() floatText(top, 120, 92, "+" .. fmt(pay), hex("#ffc35a"), 16) end) end
		Kit.sound("buy")
		if a >= #Econ.Tutorial then
			task.delay(0.4, tutorialComplete)
		elseif Econ.Tutorial[a + 1].id == "Comets" then
			-- the Moon flies in: close the window so the system and the comet are in view
			task.delay(1.2, closeWindow)
		end
	elseif kind == "ForgeGlobal" then
		-- (someone on the server rolled a MYTHIC or CELESTIAL core (#392): a chat line; a Celestial also the banner on every screen)
		local rar = Econ.ForgeRarityById[string.match(tostring(b), ":(%a+)$") or ""]
		local rname = rar and rar.name or "CELESTIAL"
		chatLine(tostring(a) .. " forged a " .. rname .. " core!", rar and rar.colour or hex("#96fff0"))
		if rname == "CELESTIAL" then
			banner(string.upper(tostring(a)) .. " FORGED A CELESTIAL CORE!", hex("#96fff0"))
			Kit.sound("milestone")
		end
	elseif kind == "BlackHoleGlobal" then
		-- (3.1: someone fell into a Black Hole: a chat line for everyone; the banner too (it's the big one))
		chatLine(tostring(a) .. " collapsed into BLACK HOLE " .. tostring(b) .. " (+" .. tostring((...)) .. " DARK MATTER)!", Color3.fromRGB(190, 140, 255))
		banner(string.upper(tostring(a)) .. ": BLACK HOLE " .. tostring(b) .. "!", Color3.fromRGB(190, 140, 255))
	elseif kind == "AutoSupernova" then
		-- (3.1 AUTO-SUPERNOVA went off by itself: the shards float up, the rank lands)
		floatText(top, 120, 70, "AUTO SUPERNOVA +" .. fmt(tonumber(a) or 0) .. " SHARDS", hex("#d7b8ff"), 16)
		if shared.GalaxyRankLand then shared.GalaxyRankLand() end
	elseif kind == "SupernovaGlobal" then
		-- (someone on the server went Supernova: a, count b, rank colour, first; the server sends max 1 per player per 30 s)
		local colour, first = ...
		colour = if typeof(colour) == "Color3" then colour else hex("#ffcd5a")
		chatLine(tostring(a) .. " went SUPERNOVA (" .. tostring(b) .. ")!", colour)
		if first then
			banner(string.upper(tostring(a)) .. "'S FIRST SUPERNOVA!", colour)
			Kit.sound("milestone")
		end
	elseif kind == "Automation" then
		-- (Phase 2.2: the AUTOMATION ONLINE beat, the cutscene template's short version, ending on a tease of what's next)
		local tease = ({ AutoBuy1 = "NEXT: KEEP RING 1 THROUGH A SUPERNOVA", KeepRing1 = "NEXT: AUTO-BUY EVERY BODY", AutoBuy2 = "NEXT: THE BLACK HOLE AUTOMATES THE SUPERNOVA" })[a] or ""
		local title = ({ AutoBuy1 = "AUTOMATION ONLINE", KeepRing1 = "RING 1 KEPT", AutoBuy2 = "FULL AUTOMATION" })[a] or "AUTOMATION ONLINE"
		task.spawn(function()
			require(Galaxy:WaitForChild("GalaxyCutscene")).play({ colour = Color3.fromRGB(125, 255, 150), symbol = Kit.A.icon.gear,
				length = 4, drop = 2.6, words = { "SYSTEMS", "LEARNING", "YOUR WAY" }, title = title, sub = tease })
		end)
	elseif kind == "CometChain" then
		-- (ring 2's COMET CHAIN: 3 in a row)
		floatText(top, 120, 40, "CHAIN x2  +" .. fmt(a), hex("#9be7ff"), 22)
		Kit.sound("milestone")
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
for i = 1, 6 do
	local pt = Instance.new("Part")
	pt.Anchored, pt.CanCollide, pt.CanQuery, pt.CanTouch, pt.CastShadow = true, false, false, false, false
	pt.Transparency = 1
	pt.Size = Vector3.new(4.2, 0.05, 4.2) -- (Tutorial 2: 6 bigger chevrons, a beam you can't miss)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = Kit.A.arrow
	decal.Color3 = Color3.fromRGB(255, 210, 90)
	decal.Parent = pt
	trail[i] = pt
end
-- (7 Nov, owner: "the arrow that points to the board's button points to the board's feet". `to` = where the trail ENDS
-- (a board: the free spot in front of its face, not under it); stopShort = studs short of it it stops; hideWithin = no
-- trail closer than this (at the board the arrow + ring sit on the button itself))
local function showTrail(to: Vector3?, stopShort: number?, hideWithin: number?)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local flat = if to and root then Vector3.new(to.X - root.Position.X, 0, to.Z - root.Position.Z) else Vector3.zero
	if not root or not hum or flat.Magnitude < (hideWithin or 9) then
		for _, pt in ipairs(trail) do pt.Parent = nil end
		return
	end
	local d = flat.Unit
	local floor = Vector3.new(root.Position.X, root.Position.Y - hum.HipHeight - root.Size.Y / 2 + 0.06, root.Position.Z)
	local drift = if Kit.calm() then 0 else (os.clock() * 3) % 3.6 -- (the arrows creep toward the board)
	for i, pt in ipairs(trail) do
		local s = 3 + (i - 1) * 3.6 + drift
		if s > flat.Magnitude - (stopShort or 5) then
			pt.Parent = nil
		else
			local at = floor + d * s
			pt.CFrame = CFrame.lookAt(at, at + d)
			pt.Parent = trailFolder
		end
	end
end

-- which board button a step points at: BODIES (bodies, +BODY, unlocks), PERKS, TREE then INFO; "PAD" = the next island pad
local function boardKeyFor(id: string): string?
	if id == "Asteroid3" or id == "Rock" then return "Body0" end
	if id == "FirstLight" then return "Perk_FirstLight" end
	if id == "Moon" then return "Body1" end
	if id == "Copy" then return "Copy0" end
	if id == "Planet" then return "Body2" end
	if id == "Giant" then return "Body3" end
	if id == "Pad1" or id == "Pads4" or id == "Pads12" then return "PAD" end
	if id == "Starfire" or id == "StarTier" then return if shared.GalaxyCinematic then nil else "R2_" .. id end
	return nil
end
-- the next island pad's place (world), its top, its aspect
local function padTarget(): (Vector3?, Vector3?, number?)
	local slot = player:GetAttribute("Island")
	local g = workspace:FindFirstChild("Galaxy")
	local island = g and slot and g.Islands:FindFirstChild("Island_" .. slot)
	local pad = island and island:FindFirstChild("NextPad")
	local disc = pad and pad:FindFirstChild("Disc")
	if not disc then return nil end
	return disc.Position, disc.Position + Vector3.new(0, 2.5, 0), 1
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
	-- LUMI's card: always there while the tutorial runs (phones: hidden while a window covers the screen)
	if open or treeOpen or sideOpen ~= nil or shared.GalaxyCinematic then clearHint() else showHint(step) end
	-- the steps done on YOUR island's boards point at the right board (like Regrowth; boards one job each, 5 Nov): the
	-- arrow + ring when the button is on screen, the floor trail while you're away from it. With a window open (or no
	-- island) the windows' own targets are used.
	local boardAt, boardTop, boardAspect, boardWorld
	local trailTo, trailShort, trailHide
	local boardKey = boardKeyFor(Econ.Tutorial[step + 1].id)
	if boardKey and not open and not treeOpen and (shared.GalaxyBoardTarget or boardKey == "PAD") then
		local c, t, aspect, normal
		if boardKey == "PAD" then c, t, aspect = padTarget() else c, t, aspect, normal = shared.GalaxyBoardTarget(boardKey) end
		-- (a board button: the trail ends at the free spot 6 studs out in front of the face, and stops showing within 12 studs
		-- of the button: there the arrow + ring on the button guide you)
		local nf = if normal then Vector3.new(normal.X, 0, normal.Z) else nil
		if c and nf and nf.Magnitude > 0.01 then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local near = hrp ~= nil and Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z).Magnitude < 12
			trailTo, trailShort, trailHide = if near then nil else c + nf.Unit * 6, 0.5, 3
		else
			trailTo = c
		end
		local cam = workspace.CurrentCamera
		if c and cam then
			boardWorld = c
			local sc, on = cam:WorldToViewportPoint(c)
			local st = cam:WorldToViewportPoint(t)
			if on and sc.Z > 0 then boardAt, boardTop, boardAspect = Vector2.new(sc.X, sc.Y), Vector2.new(st.X, st.Y), aspect end
		end
	end
	showTrail(if boardWorld then trailTo else nil, trailShort, trailHide)
	if Econ.Tutorial[step + 1].face == "pointing" then
		local at = boardAt
		if not at and not boardWorld and target and target.Parent and target.AbsoluteSize.X > 0 then
			at = target.AbsolutePosition + GuiService:GetGuiInset() + target.AbsoluteSize / 2
		end
		lumiPoint(at)
	end
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
