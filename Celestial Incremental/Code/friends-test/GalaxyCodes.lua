-- GalaxyCodes (Galaxy Incremental, overnight part 2, 3 Nov): the CODES window (design additions 3: "Codes window: in the
-- Store (E) + Settings"). The v12 frame (Kit.window, the Store's red), a code box, a green REDEEM, the result line.
-- shared.GalaxyCodesOpen() opens it (the Settings window's CODES button; the Store's from part 4). Codes: GalaxyCodeService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local codesRemote = Galaxy:WaitForChild("Codes") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyCodes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 4
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

------------------------------------------------------------------------ the window (520 x 300)
local W, H = 520, 300
local holder = Kit.box(root, 0, 0, W, H, { Name = "CodesWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "CODES", icon = "essence", iconGlow = Color3.fromRGB(60, 230, 210),
	c1 = hex("#7a1424"), c2 = hex("#ff5a6a"), lip = hex("#c22a3e"), glow = Color3.fromRGB(255, 70, 90), line = hex("#ff8a9a") })
Kit.text(win, 0, 74, W, 24, "Type a code for free Essence and potions!", 18, { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0") })
-- the code box: a dark inset with the ink outline and a red inner edge
local boxBg = Kit.panel(win, 40, 108, W - 80, 58, 5)
Kit.stroke(boxBg, hex("#ff5a6a"), 2, 0.35)
local box = Kit.new("TextBox", { Name = "CodeBox", BackgroundTransparency = 1, Position = UDim2.fromOffset(52, 112), Size = UDim2.fromOffset(W - 104, 50),
	FontFace = Kit.FONT_HEAVY, TextSize = 28, TextColor3 = Color3.new(1, 1, 1), PlaceholderText = "ENTER CODE", PlaceholderColor3 = hex("#6a6474"),
	Text = "", ClearTextOnFocus = false, ZIndex = 8 }, win)
local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Kit.INK
boxStroke.Thickness = 2
boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
boxStroke.Parent = box
local result = Kit.text(win, 20, 176, W - 40, 22, "", 17, { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_BOLD, stroke = 1.4 })
local redeem, redeemInner = Kit.button(win, (W - 220) / 2, 214, 220, 60, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
Kit.text(redeemInner, 0, 13, 220, 34, "REDEEM", 28, { ZIndex = redeemInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
Kit.tagVfx(Kit.shine(redeem, 2.4))

local busy = false
local function show(text: string, good: boolean)
	Kit.setText(result, text)
	result.TextColor3 = if good then hex("#7dff6b") else hex("#ff8a7a")
end
local function submit()
	if busy then return end
	busy = true
	Kit.sound("click")
	local ok, msg, line = codesRemote:InvokeServer(box.Text)
	busy = false
	if ok then
		Kit.sound("milestone")
		show(msg .. "  " .. (line or ""), true)
		box.Text = ""
		if shared.GalaxyToast then shared.GalaxyToast(line or "Redeemed!", hex("#7dff6b")) end
	else
		Kit.sound("error")
		show(msg or "Try again.", false)
	end
end
redeem.MouseButton1Click:Connect(submit)
box.FocusLost:Connect(function(enter) if enter then submit() end end)

------------------------------------------------------------------------ open / close (a side window, like the guide and settings)
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 84 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(s, room / (H + 34), (vp.X - 24) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end
local function close()
	if not isOpen then return end
	isOpen = false
	Kit.sound("close")
	box:ReleaseFocus()
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("E", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("E") end
	isOpen = true
	Kit.sound("open")
	show("", true)
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("E", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyCodesOpen = open
shared.GalaxyCodesClose = close
shared.GalaxyCodesToggle = function() if isOpen then close() else open() end end
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)
