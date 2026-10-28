-- SPEED ARC loading screen + main menu (M4/M6, GDD 21 at 0:00).
-- Loading: logo, a moving bar with changing steps, a new tip every 3 s, preloads the hub's meshes,
-- textures and sounds. SKIP shows after 5 s (loading carries on in the background).
-- Menu: the screen clears to a slow camera fly over the hub, the logo stays, one big PLAY, the music
-- starts quietly. PLAY starts the tutorial for new runners and fires the "menu_play" funnel step.
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
ReplicatedFirst:RemoveDefaultLoadingScreen()
player:SetAttribute("InMenu", true) -- (local only) the music plays quietly while this is set

local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local BODY = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
-- sporty palette (prompt 12; same values as Config/Palette, which isn't loaded yet in ReplicatedFirst)
local BLACK, CARBON, BLUE, GOLD, WHITE = Color3.fromHex("#0F1E4A"), Color3.fromHex("#2152D9"), Color3.fromHex("#1E90FF"), Color3.fromHex("#FFD21F"), Color3.fromHex("#FFFFFF")
local STEPS = { "Painting the lanes...", "Lacing up the shoes...", "Filling the stands...", "Warming up the coaches...", "Starting the clock..." }
local TIPS = {
	"Every step = +1 SPEED. Keep running!",
	"A race starts every 3 minutes. Tap JOIN when you see it!",
	"Shoes make every step count for more.",
	"Coaches follow you and boost every step.",
	"Smash the last wall = GO PRO to a new world.",
	"Use BOOST in races - you get 3 and they refill.",
	"Come back every day for your streak reward!",
}

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

-- speed streaks that slide across while loading
local streaks = {}
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
	streaks[i] = s
end

local scale = Instance.new("UIScale")
local holder = Instance.new("Frame")
holder.BackgroundTransparency = 1
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.fromOffset(600, 300)
holder.Parent = gui
scale.Parent = holder
local function fit()
	local s = math.min(gui.AbsoluteSize.X / 700, gui.AbsoluteSize.Y / 390)
	scale.Scale = math.clamp(s, 0.6, 1.6)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
fit()

local function label(text, font, size, color, y, h, parent)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Text = text
	t.FontFace = font
	t.TextSize = size
	t.TextColor3 = color
	t.TextWrapped = true
	t.Position = UDim2.fromOffset(0, y)
	t.Size = UDim2.new(1, 0, 0, h)
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = BLACK
	st.Parent = t
	t.Parent = parent or holder
	return t
end
label("SPEED ARC", MONTSERRAT, 86, GOLD, 10, 100)
local stepText = label(STEPS[1], BODY, 20, WHITE, 112, 26)

local barBack = Instance.new("Frame")
barBack.BackgroundColor3 = BLACK
barBack.Position = UDim2.fromOffset(100, 146)
barBack.Size = UDim2.fromOffset(400, 16)
barBack.Parent = holder
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0.5, 0)
local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromHex("#2C4499")
barStroke.Thickness = 2
barStroke.Parent = barBack
local bar = Instance.new("Frame")
bar.BackgroundColor3 = BLUE
bar.Size = UDim2.fromScale(0.02, 1)
bar.Parent = barBack
Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5, 0)
local tipText = label(TIPS[math.random(1, #TIPS)], BODY, 16, Color3.fromHex("#5AB4FF"), 172, 40)

local function bigButton(text, y, w, h, color, textColor, textSize)
	local b = Instance.new("TextButton")
	b.Text = text
	b.FontFace = MONTSERRAT
	b.TextSize = textSize
	b.TextColor3 = textColor
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.AnchorPoint = Vector2.new(0.5, 0)
	b.Position = UDim2.new(0.5, 0, 0, y)
	b.Size = UDim2.fromOffset(w, h)
	b.Visible = false
	b.Parent = holder
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 16)
	local st = Instance.new("UIStroke")
	st.Color = BLACK
	st.Thickness = 3
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = b
	return b
end
local play = bigButton("PLAY", 218, 240, 74, GOLD, BLACK, 40)
play.Name = "Play"
local skip = bigButton("SKIP", 222, 140, 44, Color3.fromHex("#2C4499"), WHITE, 22)
skip.Name = "Skip"

-- moving bits: streaks slide, tips change every 3 s
local loading = true
task.spawn(function()
	local t = 0
	while gui.Parent do
		t += task.wait(0.03)
		for i, s in streaks do
			local x = ((t * (0.12 + i * 0.03)) % 1.6) - 0.3
			s.Position = UDim2.fromScale(x, 0.18 + i * 0.1)
		end
	end
end)
task.spawn(function()
	while gui.Parent do
		task.wait(3)
		tipText.Text = TIPS[math.random(1, #TIPS)]
	end
end)

----------------------------------------------------------------------------
-- preload (keeps going after SKIP)
----------------------------------------------------------------------------
local skipped = false
task.delay(5, function()
	if loading then
		skip.Visible = true
	end
end)
skip.Activated:Connect(function()
	skipped = true
	skip.Visible = false
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end
local assets = {}
local function collect(root)
	if not root then
		return
	end
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") or d:IsA("Sound") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("ParticleEmitter") then
			table.insert(assets, d)
		end
	end
end
collect(workspace:WaitForChild("Hub", 10))
collect(game:GetService("ReplicatedStorage"):FindFirstChild("Assets"))
collect(game:GetService("SoundService"))
local total = math.max(1, #assets)
local preloadDone = false
task.spawn(function()
	local done = 0
	local batch = 20
	for i = 1, #assets, batch do
		local slice = {}
		for j = i, math.min(#assets, i + batch - 1) do
			table.insert(slice, assets[j])
		end
		pcall(function()
			ContentProvider:PreloadAsync(slice)
		end)
		done += #slice
		local f = done / total
		TweenService:Create(bar, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.max(0.02, f), 1) }):Play()
		stepText.Text = STEPS[math.clamp(math.ceil(f * #STEPS), 1, #STEPS)]
	end
	preloadDone = true
end)
local t0 = os.clock()
while not (preloadDone or skipped or os.clock() - t0 > 12) do
	task.wait(0.1)
end
while not player:GetAttribute("DataLoaded") do
	player:GetAttributeChangedSignal("DataLoaded"):Wait()
end
loading = false
skip.Visible = false

----------------------------------------------------------------------------
-- main menu: the screen clears to a slow fly over the hub
----------------------------------------------------------------------------
local camera = workspace.CurrentCamera
local flyStart = os.clock()
RunService:BindToRenderStep("SpeedArcMenuCamera", Enum.RenderPriority.Camera.Value + 2, function()
	local a = (os.clock() - flyStart) * 0.06 + 2.2
	local pos = Vector3.new(math.cos(a) * 190, 78 + math.sin(a * 0.7) * 8, 150 + math.sin(a) * 170) -- high enough to clear the stands
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(pos, Vector3.new(0, 6, 150))
end)
TweenService:Create(bg, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
for _, s in streaks do
	TweenService:Create(s, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
end
TweenService:Create(barBack, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
TweenService:Create(bar, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
TweenService:Create(barStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
stepText.Text = "Run. Race. Go Pro."
local shade = Instance.new("Frame") -- a soft dark band behind the menu text so it reads over the world
shade.BackgroundColor3 = BLACK
shade.BackgroundTransparency = 1
shade.BorderSizePixel = 0
shade.Size = UDim2.fromScale(1, 1)
shade.ZIndex = 0
shade.Parent = gui
local shadeGrad = Instance.new("UIGradient")
shadeGrad.Rotation = 90
shadeGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.45, 0.85), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 0.2) })
shadeGrad.Parent = shade
TweenService:Create(shade, TweenInfo.new(1.2), { BackgroundTransparency = 0 }):Play()
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
if RunService:IsStudio() and workspace:GetAttribute("TestAutoPlay") then
	task.wait(0.5)
else
	play.Activated:Wait()
end
play.Visible = false
RunService:UnbindFromRenderStep("SpeedArcMenuCamera")
camera.CameraType = Enum.CameraType.Custom
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if hum then
	camera.CameraSubject = hum
end
player:SetAttribute("InMenu", nil)
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
remotes:WaitForChild("Funnel"):FireServer("menu_play")
task.spawn(function()
	pcall(function()
		remotes:WaitForChild("Action"):InvokeServer("Tutorial", "play")
	end)
end)
for _, d in gui:GetDescendants() do
	if d:IsA("TextLabel") or d:IsA("TextButton") then
		TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	end
end
TweenService:Create(shade, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
task.wait(0.4)
gui:Destroy()
