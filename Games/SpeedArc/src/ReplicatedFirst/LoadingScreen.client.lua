-- SPEED ARC loading screen (M4, GDD 21 at 0:00): shows at once, preloads the hub's meshes and
-- sounds (so nothing freezes later), then a short menu with one big PLAY button. PLAY starts the
-- tutorial for new runners and fires the "menu_play" funnel step.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
ReplicatedFirst:RemoveDefaultLoadingScreen()

local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local BODY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local BLACK, CARBON, BLUE, GOLD, WHITE = Color3.fromHex("#0B0D12"), Color3.fromHex("#161A22"), Color3.fromHex("#1E7BFF"), Color3.fromHex("#FFC83D"), Color3.fromHex("#F4F6FA")

local gui = Instance.new("ScreenGui")
gui.Name = "SpeedArcLoading"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = WHITE
bg.Parent = gui
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(CARBON, BLACK)
grad.Rotation = 90
grad.Parent = bg

-- speed streaks
for i = 1, 6 do
	local s = Instance.new("Frame")
	s.BackgroundColor3 = if i % 2 == 0 then GOLD else BLUE
	s.BackgroundTransparency = 0.75
	s.BorderSizePixel = 0
	s.AnchorPoint = Vector2.new(0.5, 0.5)
	s.Position = UDim2.fromScale(0.5, 0.18 + i * 0.1)
	s.Size = UDim2.new(1.4, 0, 0, 3 + i % 3 * 2)
	s.Rotation = -8
	s.Parent = bg
end

local scale = Instance.new("UIScale")
local holder = Instance.new("Frame")
holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.fromOffset(600, 300)
holder.Parent = bg
scale.Parent = holder
local function fit()
	local s = math.min(gui.AbsoluteSize.X / 700, gui.AbsoluteSize.Y / 390)
	scale.Scale = math.clamp(s, 0.6, 1.6)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()

local function label(text, font, size, color, y, h)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = text
	t.FontFace = font
	t.TextSize = size
	t.TextColor3 = color
	t.Position = UDim2.fromOffset(0, y)
	t.Size = UDim2.new(1, 0, 0, h)
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = BLACK
	st.Parent = t
	t.Parent = holder
	return t
end
label("SPEED ARC", MONTSERRAT, 86, GOLD, 10, 100)
local tip = label("Everyone starts slow.", BODY, 22, WHITE, 112, 30)

local barBack = Instance.new("Frame")
barBack.BackgroundColor3 = BLACK
barBack.Position = UDim2.fromOffset(100, 170)
barBack.Size = UDim2.fromOffset(400, 16)
barBack.Parent = holder
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0.5, 0)
local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromHex("#2A303C")
barStroke.Thickness = 2
barStroke.Parent = barBack
local bar = Instance.new("Frame")
bar.BackgroundColor3 = BLUE
bar.Size = UDim2.fromScale(0, 1)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5, 0)

local play = Instance.new("TextButton")
play.Name = "Play"
play.Text = "PLAY"
play.FontFace = MONTSERRAT
play.TextSize = 40
play.TextColor3 = BLACK
play.BackgroundColor3 = GOLD
play.AutoButtonColor = true
play.AnchorPoint = Vector2.new(0.5, 0)
play.Position = UDim2.new(0.5, 0, 0, 205)
play.Size = UDim2.fromOffset(240, 74)
play.Visible = false
play.Parent = holder
Instance.new("UICorner", play).CornerRadius = UDim.new(0, 16)
local playStroke = Instance.new("UIStroke")
playStroke.Color = Color3.fromHex("#C99A1E")
playStroke.Thickness = 3
playStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
playStroke.Parent = play

-- preload (never more than ~10 s, so a slow phone still gets in)
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local assets = {}
local function collect(root)
	if not root then
		return
	end
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") or d:IsA("Sound") or d:IsA("Decal") then
			table.insert(assets, d)
		end
	end
end
collect(workspace:WaitForChild("Hub", 10))
collect(game:GetService("ReplicatedStorage"):FindFirstChild("Assets"))
collect(game:GetService("SoundService"))
local total = math.max(1, #assets)
local done = 0
local started = os.clock()
local batch = 20
for i = 1, #assets, batch do
	if os.clock() - started > 10 then
		break
	end
	local slice = {}
	for j = i, math.min(#assets, i + batch - 1) do
		table.insert(slice, assets[j])
	end
	pcall(function()
		ContentProvider:PreloadAsync(slice)
	end)
	done += #slice
	bar.Size = UDim2.fromScale(done / total, 1)
end
bar.Size = UDim2.fromScale(1, 1)
while not player:GetAttribute("DataLoaded") do
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end
tip.Text = "Train. Race. Go Pro."
play.Visible = true
task.spawn(function()
	while play.Parent and play.Visible do
		TweenService:Create(play, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(256, 78) }):Play()
		task.wait(0.45)
		TweenService:Create(play, TweenInfo.new(0.45, Enum.EasingStyle.Sine), { Size = UDim2.fromOffset(240, 74) }):Play()
		task.wait(0.45)
	end
end)

-- Studio test switch: Workspace TestAutoPlay = true presses PLAY by itself
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("TestAutoPlay") then
	task.wait(0.5)
else
	play.Activated:Wait()
end
play.Visible = false
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
remotes:WaitForChild("Funnel"):FireServer("menu_play")
task.spawn(function()
	pcall(function()
		remotes:WaitForChild("Action"):InvokeServer("Tutorial", "play")
	end)
end)
local fade = TweenService:Create(bg, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
for _, d in bg:GetDescendants() do
	if d:IsA("TextLabel") or d:IsA("TextButton") then
		TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	end
end
fade:Play()
fade.Completed:Wait()
gui:Destroy()
