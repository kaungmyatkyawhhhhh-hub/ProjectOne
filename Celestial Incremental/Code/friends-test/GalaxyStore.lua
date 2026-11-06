-- GalaxyStore (Galaxy Incremental, overnight part 4, 3 Nov): the STORE window (hotbar E / key E). The v12 frame in the
-- Store's red (Kit.window, the design's window mock-up `UI\windows\galaxy_window_store.png`), for now:
--  * the PASS cards (7 Nov: x2 STARDUST, VIP, +1 CORE SLOT, AUTO ROLL; the ones with an id): icon, name, what it does, the
--    price read live from Roblox (GetProductInfo; the config's until it loads), a green BUY (the server prompts:
--    StoreEvent "Prompt", key) or OWNED
--  * CODES: opens the Codes window (design additions 3: codes in the Store + Settings)
-- Calm wording, no countdowns, no fake "was" prices (Playbook 3). Ids: GameConfig.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: closes only by X, Esc / B, outside)
local Config = require(Galaxy:WaitForChild("GameConfig"))
local storeEvent = Galaxy:WaitForChild("StoreEvent") :: RemoteEvent
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyStore"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local root: GuiObject | ScreenGui = gui
if PHONE_TEST then
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	f.Parent = gui
	root = f
end
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end

------------------------------------------------------------------------ the window: the PASS cards (2 columns) + CODES
-- (7 Nov: one card per GameConfig.Passes entry that has an id, in `order`: x2 STARDUST, VIP, +1 CORE SLOT, AUTO ROLL. A pass
-- with id 0 isn't created yet: no card. Studio: Workspace TestShowPasses = true shows them all, to check the layout.)
local SHOW_ALL = RunService:IsStudio() and workspace:GetAttribute("TestShowPasses") == true
local passes = {}
for key, p in pairs(Config.Passes) do
	if p.id ~= 0 or SHOW_ALL then table.insert(passes, { key = key, p = p }) end
end
table.sort(passes, function(a, b) return (a.p.order or 9) < (b.p.order or 9) end)
local CW, CHt = 286, 176
local rows = math.max(1, math.ceil(#passes / 2))
local W, H = 620, 76 + rows * (CHt + 12) + 104
local holder = Kit.box(root, 0, 0, W, H, { Name = "StoreWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
-- (phones: the window fits the width (text >= 14 px) and scrolls, like STATS / UPGRADES)
local sHolder: GuiObject = holder
if Kit.phone() then
	sHolder = Kit.new("ScrollingFrame", { Name = "PhoneScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(W, H),
		CanvasSize = UDim2.fromOffset(0, H), ScrollBarThickness = 8, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarImageColor3 = hex("#ffd84a") }, holder)
end
local win, closeBtn = Kit.window(sHolder, W, H, { title = "STORE", icon = "shard", iconGlow = Color3.fromRGB(255, 90, 110),
	c1 = hex("#7a1424"), c2 = hex("#ff5a6a"), lip = hex("#c22a3e"), glow = Color3.fromRGB(255, 70, 90), line = hex("#ff8a9a") })

-- a pass card (the UPGRADES rows' look: dark card, coloured edge, the icon breaking out top-left, the green buy button)
local EDGE = { X2Stardust = "#ff9a3a", VIP = "#ffd84a", CoreSlot = "#b49bff", AutoRoll = "#5ad1ff" }
local cards = {}
local refresh
for i, e in ipairs(passes) do
	local x = 16 + ((i - 1) % 2) * (CW + 16)
	local y = 76 + ((i - 1) // 2) * (CHt + 12)
	local panel = Kit.panel(win, x, y, CW, CHt, 4)
	Kit.stroke(panel, hex(EDGE[e.key] or "#ff9a3a"), 2, 0.2)
	local iconName = if Kit.A.icon[e.p.icon] then e.p.icon else "ui:" .. e.p.icon
	Kit.icon(win, iconName, x - 4, y - 6, 92, Color3.fromRGB(255, 170, 60), { ZIndex = 8 })
	if e.key == "X2Stardust" then
		local x2 = Kit.box(win, x + 22, y + CHt - 46, 46, 30, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 10, Rotation = -8 })
		Kit.corner(x2, 6)
		Kit.stroke(x2, Kit.INK, 2.5)
		Kit.grad(x2, hex("#ffe27a"), hex("#e08a0a"), 90)
		Kit.text(x2, 0, 2, 46, 26, "x2", 22, { ZIndex = 11, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
	end
	Kit.text(win, x + 92, y + 14, CW - 102, 32, e.p.title, Kit.ps(24, 26), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2,
		gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	Kit.text(win, x + 14, y + 62, CW - 28, 60, e.p.desc, Kit.ps(15, 17), { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0"),
		stroke = 1.2, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
	local buy, buyInner = Kit.button(win, x + CW - 160, y + CHt - 52, 146, 42, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	local buyText = Kit.text(buyInner, 0, Kit.ps(8, 7), 146, 28, "R$ " .. e.p.price, Kit.ps(21, 23), { ZIndex = buyInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
	local shine = Kit.tagVfx(Kit.shine(buy, 2.6))
	cards[e.key] = { p = e.p, buy = buy, text = buyText, shine = shine }
	buy.MouseButton1Click:Connect(function()
		if player:GetAttribute("Pass_" .. e.key) == true or e.p.id == 0 then Kit.sound("error") return end
		Kit.sound("click")
		storeEvent:FireServer("Prompt", e.key)
	end)
	-- the live price (Managed Pricing can change it: never typed in, Playbook 7)
	task.spawn(function()
		if e.p.id == 0 then return end
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(e.p.id, Enum.InfoType.GamePass) end)
		if ok and info and info.PriceInRobux then e.p.price = info.PriceInRobux end
		if refresh then refresh() end
	end)
end

-- CODES
local codesY = 76 + rows * (CHt + 12) + 8
local codes, codesInner = Kit.button(win, 16, codesY, W - 32, 72, hex("#ff7d8e"), hex("#c22a3e"), { ZIndex = 6 })
Kit.text(codesInner, 0, 18, W - 32, 36, "CODES", 30, { ZIndex = codesInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
Kit.icon(win, "essence", 200, codesY - 2, 74, Color3.fromRGB(60, 230, 210), { ZIndex = 9 })
codes.MouseButton1Click:Connect(function()
	if shared.GalaxyCodesOpen then shared.GalaxyCodesOpen() end
end)

function refresh()
	for key, c in pairs(cards) do
		local owned = player:GetAttribute("Pass_" .. key) == true
		if owned then
			Kit.recolour(c.buy, hex("#6a6474"), hex("#3f3a48"))
			Kit.setText(c.text, "OWNED")
			c.shine.Visible = false
		elseif c.p.id == 0 then
			-- (Studio layout check only: no id yet, the price shows, the button is grey and does nothing)
			Kit.recolour(c.buy, hex("#6a6474"), hex("#3f3a48"))
			Kit.setText(c.text, "R$ " .. c.p.price)
			c.shine.Visible = false
		else
			Kit.recolour(c.buy, hex("#7dff7a"), hex("#1fa83a"))
			Kit.setText(c.text, "R$ " .. c.p.price)
			c.shine.Visible = true
		end
	end
end
for key in pairs(cards) do player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh) end
refresh()

------------------------------------------------------------------------ open / close (a side window)
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s -- (6 Nov overlap check: under the GALAXY LIT bar + the counter's SUPERNOVA bar)
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	if sHolder ~= holder then
		want = math.min(1, (vp.X - 12) / (W + 16))
		local h = math.min(H, math.floor(room / want))
		sHolder.Size = UDim2.fromOffset(W, h)
		holder.Size = UDim2.fromOffset(W, h)
	end
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + (if sHolder ~= holder then 0 else 15 * want))
	return want
end
local function close()
	if not isOpen then return end
	isOpen = false
	Kit.sound("close")
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("E", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("E") end
	isOpen = true
	Kit.sound("open")
	refresh()
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("E", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyStoreToggle = function() if isOpen then close() else open() end end
shared.GalaxyStoreClose = close
WM.register("E", holder, close)
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)
