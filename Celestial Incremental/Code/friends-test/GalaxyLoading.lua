-- GalaxyLoading (Galaxy Incremental, purpose, 5 Nov: ReplicatedFirst; checklist #9 #477): the loading screen.
-- The premise in one line ("The galaxy went dark. Light it up again, one star at a time."), the game's name, a loading bar;
-- SKIP after 5 s (Playbook: preload only the first minute, keep loading behind). Built from plain instances (nothing else
-- has loaded yet), in the v12 look: the dark violet galaxy, Montserrat Heavy Italic, gold.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local HEAVY = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local STARDUST = "rbxassetid://93985102473923" -- (= UIAssets.icon.stardust)
local GLOW = "rbxassetid://113034099262576" -- (= UIAssets.softglow)
local INK = Color3.fromRGB(18, 10, 26)

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.new(1, 1, 1)
bg.BorderSizePixel = 0
bg.Parent = gui
local g = Instance.new("UIGradient")
g.Color = ColorSequence.new(Color3.fromRGB(34, 16, 58), Color3.fromRGB(6, 3, 14))
g.Rotation = 90
g.Parent = bg

local function label(text: string, size: number, y: number, font, color: Color3, stroke: number)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0.5, 0, y, 0)
	l.Size = UDim2.new(0.9, 0, 0, size * 1.3)
	l.FontFace = font
	l.Text = text
	l.TextSize = size
	l.TextScaled = false
	l.TextWrapped = true
	l.TextColor3 = color
	l.Parent = bg
	local st = Instance.new("UIStroke")
	st.Color = INK
	st.Thickness = stroke
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = l
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = size
	c.Parent = l
	return l
end
local small = workspace.CurrentCamera.ViewportSize.Y < 500
local glow = Instance.new("ImageLabel")
glow.BackgroundTransparency = 1
glow.Image = GLOW
glow.ImageColor3 = Color3.fromRGB(255, 170, 60)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.3)
glow.Size = UDim2.fromOffset(if small then 150 else 230, if small then 150 else 230)
glow.Parent = bg
local icon = glow:Clone()
icon.Image = STARDUST
icon.ImageColor3 = Color3.new(1, 1, 1)
icon.Size = UDim2.fromOffset(if small then 90 else 140, if small then 90 else 140)
icon.Parent = bg
local name = label("GALAXY INCREMENTAL", if small then 34 else 58, 0.5, HEAVY, Color3.new(1, 1, 1), 3)
local ng = Instance.new("UIGradient")
ng.Color = ColorSequence.new(Color3.fromRGB(255, 241, 192), Color3.fromRGB(255, 176, 42))
ng.Rotation = 90
ng.Parent = name
label("The galaxy went dark. Light it up again, one star at a time.", if small then 16 else 24, 0.61, BOLD, Color3.fromRGB(220, 212, 236), 1.6)

-- the bar (fills as the first assets load) + SKIP after 5 s
local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.74)
barBack.Size = UDim2.new(0.42, 0, 0, 14)
barBack.BackgroundColor3 = Color3.fromRGB(22, 19, 27)
barBack.BorderSizePixel = 0
barBack.Parent = bg
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bs = Instance.new("UIStroke")
bs.Color = INK
bs.Thickness = 2
bs.Parent = barBack
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.Parent = barBack
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local fg = Instance.new("UIGradient")
fg.Color = ColorSequence.new(Color3.fromRGB(255, 224, 138), Color3.fromRGB(255, 154, 26))
fg.Rotation = 90
fg.Parent = fill

local skip = Instance.new("TextButton")
skip.AnchorPoint = Vector2.new(0.5, 0.5)
skip.Position = UDim2.fromScale(0.5, 0.86)
skip.Size = UDim2.fromOffset(150, 48)
skip.BackgroundColor3 = Color3.new(1, 1, 1)
skip.AutoButtonColor = false
skip.FontFace = HEAVY
skip.Text = "SKIP"
skip.TextSize = 24
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Visible = false
skip.Parent = bg
Instance.new("UICorner", skip).CornerRadius = UDim.new(0, 6)
local ss = Instance.new("UIStroke")
ss.Color = INK
ss.Thickness = 2
ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ss.Parent = skip
local sg = Instance.new("UIGradient")
sg.Color = ColorSequence.new(Color3.fromRGB(106, 100, 116), Color3.fromRGB(63, 58, 72))
sg.Rotation = 90
sg.Parent = skip
local ts = Instance.new("UIStroke")
ts.Color = INK
ts.Thickness = 2
ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
ts.Parent = skip

local done = false
local function finish()
	if done then return end
	done = true
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("GuiObject") then
			TweenService:Create(d, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			if d:IsA("TextLabel") or d:IsA("TextButton") then TweenService:Create(d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play() end
			if d:IsA("ImageLabel") then TweenService:Create(d, TweenInfo.new(0.4), { ImageTransparency = 1 }):Play() end
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.45, function() gui:Destroy() end)
end
skip.MouseButton1Click:Connect(finish)
task.delay(5, function() if not done then skip.Visible = true end end)

-- the icon breathes while it loads
task.spawn(function()
	while not done do
		TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { ImageTransparency = 0.45 }):Play()
		task.wait(1.2)
		if done then break end
		TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { ImageTransparency = 0 }):Play()
		task.wait(1.2)
	end
end)
-- the bar: the game loaded + the economy says the save is in (Loaded); never longer than 20 s
task.spawn(function()
	local t0 = os.clock()
	while not done do
		local k = 0
		if game:IsLoaded() then k += 0.5 end
		if player:GetAttribute("Loaded") == true then k += 0.4 end
		k += math.min(0.1, (os.clock() - t0) / 60)
		TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(math.clamp(k, 0.04, 1), 1) }):Play()
		if (game:IsLoaded() and player:GetAttribute("Loaded") == true) or os.clock() - t0 > 20 then
			task.wait(0.5)
			finish()
			break
		end
		task.wait(0.25)
	end
end)
local _ = ContentProvider
