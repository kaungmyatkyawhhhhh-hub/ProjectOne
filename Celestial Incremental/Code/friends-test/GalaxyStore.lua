-- GalaxyStore (Galaxy Incremental, overnight part 4, 3 Nov): the STORE window (hotbar E / key E). The v12 frame in the
-- Store's red (Kit.window, the design's window mock-up `UI\windows\galaxy_window_store.png`), for now:
--  * the x2 STARDUST pass card: icon, name, what it does, the price read live from Roblox (GetProductInfo; the config's
--    249 until it loads), a green BUY (the server prompts: StoreEvent "Prompt") or OWNED
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
local Config = require(Galaxy:WaitForChild("GameConfig"))
local storeEvent = Galaxy:WaitForChild("StoreEvent") :: RemoteEvent
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local X2 = Config.Passes.X2Stardust

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

------------------------------------------------------------------------ the window (620 x 350)
local W, H = 620, 350
local holder = Kit.box(root, 0, 0, W, H, { Name = "StoreWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "STORE", icon = "shard", iconGlow = Color3.fromRGB(255, 90, 110),
	c1 = hex("#7a1424"), c2 = hex("#ff5a6a"), lip = hex("#c22a3e"), glow = Color3.fromRGB(255, 70, 90), line = hex("#ff8a9a") })

-- the pass card (the UPGRADES window's row look: dark card, coloured edge, the icon breaking out on the left)
local card = Kit.panel(win, 16, 76, W - 32, 160, 4)
Kit.stroke(card, hex("#ff9a3a"), 2, 0.2)
Kit.icon(win, X2.icon, 18, 74, 150, Color3.fromRGB(255, 170, 60), { ZIndex = 8 })
local x2 = Kit.box(win, 112, 182, 62, 40, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 10, Rotation = -8 })
Kit.corner(x2, 6)
Kit.stroke(x2, Kit.INK, 2.5)
Kit.grad(x2, hex("#ffe27a"), hex("#e08a0a"), 90)
Kit.text(x2, 0, 4, 62, 32, "x2", 28, { ZIndex = 11, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
Kit.text(win, 186, 92, 400, 40, X2.title, 34, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2.2,
	gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
Kit.text(win, 188, 136, 400, 24, X2.desc, 19, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0"), stroke = 1.3 })
Kit.text(win, 188, 162, 400, 22, "Adds to potions and Star Surge (x2 + x2 = x3).", 16, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1.1 })
local buy, buyInner, buyGrad = Kit.button(win, W - 196, 176, 164, 50, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
local buyText = Kit.text(buyInner, 0, 10, 164, 30, "R$ " .. X2.price, 24, { ZIndex = buyInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local buyShine = Kit.tagVfx(Kit.shine(buy, 2.6))

-- CODES
local codes, codesInner = Kit.button(win, 16, 254, W - 32, 72, hex("#ff7d8e"), hex("#c22a3e"), { ZIndex = 6 })
Kit.text(codesInner, 0, 18, W - 32, 36, "CODES", 30, { ZIndex = codesInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
Kit.icon(win, "essence", 200, 252, 74, Color3.fromRGB(60, 230, 210), { ZIndex = 9 })
codes.MouseButton1Click:Connect(function()
	if shared.GalaxyCodesOpen then shared.GalaxyCodesOpen() end
end)

-- the live price (Managed Pricing can change it: never typed in, Playbook 7)
task.spawn(function()
	if X2.id == 0 then return end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(X2.id, Enum.InfoType.GamePass) end)
	if ok and info and info.PriceInRobux then X2.price = info.PriceInRobux end
end)
local function refresh()
	local owned = player:GetAttribute("Pass_X2Stardust") == true
	if owned then
		Kit.recolour(buy, hex("#6a6474"), hex("#3f3a48"))
		Kit.setText(buyText, "OWNED")
		buyShine.Visible = false
	elseif X2.id == 0 then
		-- (no pass id yet: the price shows, the button is grey and does nothing)
		Kit.recolour(buy, hex("#6a6474"), hex("#3f3a48"))
		Kit.setText(buyText, "R$ " .. X2.price)
		buyShine.Visible = false
	else
		Kit.recolour(buy, hex("#7dff7a"), hex("#1fa83a"))
		Kit.setText(buyText, "R$ " .. X2.price)
		buyShine.Visible = true
	end
end
player:GetAttributeChangedSignal("Pass_X2Stardust"):Connect(refresh)
refresh()
buy.MouseButton1Click:Connect(function()
	if player:GetAttribute("Pass_X2Stardust") == true or X2.id == 0 then Kit.sound("error") return end
	Kit.sound("click")
	storeEvent:FireServer("Prompt", "X2Stardust")
end)
local _ = buyGrad

------------------------------------------------------------------------ open / close (a side window)
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 84 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
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
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)
