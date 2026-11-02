-- GalaxyPotions (Galaxy Incremental, overnight part 2, 3 Nov): the BOOST POTIONS on the HUD (design additions 3).
-- Left side, one v12 card per potion you have or have running: the potion icon, its name, how many you have, a green USE,
-- and the timer while it runs (a second one adds 15 min to the timer: they stack by time). Numbers: the server's
-- Potion_<id> (count) and BoostEnd_<id> (server time the boost ends) attributes; USE = EconRequest "UsePotion", id.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyPotions"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1
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

local CW, CH, GAP = 214, 74, 10
local strip = Kit.box(root, 0, 0, CW, (CH + GAP) * #Econ.Potions, { Name = "Potions", AnchorPoint = Vector2.new(0, 0.5) })
local scale = Instance.new("UIScale")
scale.Parent = strip

local cards = {}
for i, p in ipairs(Econ.Potions) do
	local c = Kit.box(strip, 0, (i - 1) * (CH + GAP), CW, CH, { Name = p.id, Visible = false })
	local shadow = Kit.box(c, 0, 3, CW, CH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(shadow, 8)
	local plate = Kit.box(c, 0, 0, CW, CH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 8)
	Kit.stroke(plate, Kit.INK, 2)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(c, 3, 3, CW - 6, CH - 6, { ZIndex = 3 })
	Kit.corner(edge, 6)
	Kit.stroke(edge, p.colour, 1.5, 0.3)
	Kit.box(c, 8, 4, CW - 16, 2, { BackgroundTransparency = 0.55, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.icon(c, p.icon, -10, -6, 78, p.colour, { ZIndex = 5 })
	Kit.text(c, 66, 8, 140, 22, p.name, 17, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	-- how many you have: a small count chip on the icon
	local chip = Kit.box(c, 44, 46, 30, 22, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(chip, 5)
	Kit.stroke(chip, Kit.INK, 2)
	Kit.grad(chip, hex("#ffd84a"), hex("#c79a0a"), 90)
	local count = Kit.text(chip, 0, 2, 30, 18, "1", 15, { ZIndex = 8, TextXAlignment = CENTRE, stroke = 1.3 })
	-- the timer while it runs
	local timer = Kit.text(c, 66, 38, 80, 26, "", 21, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#ffd84a") })
	local use, useInner, _, useShadow = Kit.button(c, 146, 36, 58, 30, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	Kit.text(useInner, 0, 5, 58, 20, "USE", 17, { ZIndex = useInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	use.MouseButton1Click:Connect(function()
		Kit.sound("click")
		local ok = request:InvokeServer("UsePotion", p.id)
		if ok then
			Kit.sound("milestone")
			if shared.GalaxyToast then shared.GalaxyToast(p.name .. " ON: +" .. p.minutes .. " MIN", p.colour) end
		else
			Kit.sound("error")
		end
	end)
	cards[p.id] = { frame = c, count = count, chip = chip, timer = timer, use = use, useShadow = useShadow }
end

local function layout()
	local s = screenScale()
	local vp = viewport()
	scale.Scale = s
	strip.Position = UDim2.fromOffset(math.floor(10 * s), math.floor(vp.Y * 0.5))
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()

-- shown / hidden, counts, and the order (only the visible cards, packed from the top)
local function refresh()
	local y = 0
	for _, p in ipairs(Econ.Potions) do
		local c = cards[p.id]
		local n = player:GetAttribute("Potion_" .. p.id) or 0
		local running = (player:GetAttribute("BoostEnd_" .. p.id) or 0) > workspace:GetServerTimeNow()
		c.frame.Visible = n > 0 or running
		c.chip.Visible = n > 0
		Kit.setText(c.count, tostring(n))
		c.use.Visible = n > 0
		c.useShadow.Visible = n > 0
		if c.frame.Visible then
			c.frame.Position = UDim2.fromOffset(0, y)
			y += CH + GAP
		end
	end
end
for _, p in ipairs(Econ.Potions) do
	player:GetAttributeChangedSignal("Potion_" .. p.id):Connect(refresh)
	player:GetAttributeChangedSignal("BoostEnd_" .. p.id):Connect(refresh)
end
refresh()

-- the timers (mm:ss), and the card goes when a boost ends with none left
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	acc = 0
	local now = workspace:GetServerTimeNow()
	local changed = false
	for _, p in ipairs(Econ.Potions) do
		local c = cards[p.id]
		local left = (player:GetAttribute("BoostEnd_" .. p.id) or 0) - now
		if left > 0 then
			Kit.setText(c.timer, string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60)))
		else
			Kit.setText(c.timer, "")
			if c.frame.Visible and (player:GetAttribute("Potion_" .. p.id) or 0) == 0 then changed = true end
		end
	end
	if changed then refresh() end
end)
