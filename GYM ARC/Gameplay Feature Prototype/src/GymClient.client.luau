--[[
	GymClient
	Client side: HUD (Strength, Cash, rank progress), the weight upgrade panel,
	and the timing mini-game while training. All rewards come from the server;
	the client only shows them and sends the moment the player tapped.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Util = require(ReplicatedStorage:WaitForChild("GymUtil"))
local remotes = ReplicatedStorage:WaitForChild("GymRemotes")

local player = Players.LocalPlayer

---------------------------------------------------------------------------
-- UI helpers
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GymUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local DARK = Color3.fromRGB(28, 30, 40)

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function text(parent: Instance, props): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextScaled = true
	for k, v in pairs(props) do
		(l :: any)[k] = v
	end
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.new(0, 0, 0)
	s.Parent = l
	l.Parent = parent
	return l
end

local function button(parent: Instance, props, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBlack
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	for k, v in pairs(props) do
		(b :: any)[k] = v
	end
	corner(b, 10)
	stroke(b, Color3.new(0, 0, 0), 3)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.Parent = b
	b.Parent = parent
	return b
end

local function sfx(id: string, volume: number, pitch: number?)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch or 1
	SoundService:PlayLocalSound(s)
	task.delay(3, function()
		s:Destroy()
	end)
end

local function pop(obj: GuiObject)
	local scale = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = obj
	scale.Scale = 1.25
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

---------------------------------------------------------------------------
-- HUD: stats card (top-left)
---------------------------------------------------------------------------
local card = Instance.new("Frame")
card.Size = UDim2.fromScale(0.24, 0.17)
card.Position = UDim2.fromScale(0.015, 0.03)
card.BackgroundColor3 = DARK
card.BackgroundTransparency = 0.15
corner(card, 14)
stroke(card, Color3.new(0, 0, 0), 3)
local cardRatio = Instance.new("UIAspectRatioConstraint")
cardRatio.AspectRatio = 2.6
cardRatio.Parent = card
card.Parent = gui

local strengthLabel = text(card, { Size = UDim2.fromScale(0.92, 0.3), Position = UDim2.fromScale(0.04, 0.05),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 200, 40), Text = "💪 0" })
local cashLabel = text(card, { Size = UDim2.fromScale(0.92, 0.24), Position = UDim2.fromScale(0.04, 0.36),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(110, 230, 120), Text = "$0" })

local rankBar = Instance.new("Frame")
rankBar.Size = UDim2.fromScale(0.92, 0.24)
rankBar.Position = UDim2.fromScale(0.04, 0.68)
rankBar.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
corner(rankBar, 8)
rankBar.Parent = card
local rankFill = Instance.new("Frame")
rankFill.Size = UDim2.fromScale(0, 1)
rankFill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
corner(rankFill, 8)
rankFill.Parent = rankBar
local rankLabel = text(rankBar, { Size = UDim2.fromScale(0.96, 0.8), Position = UDim2.fromScale(0.02, 0.1),
	Font = Enum.Font.GothamBold, Text = "Twig", ZIndex = 2 })

---------------------------------------------------------------------------
-- Weights upgrade panel (bottom-right)
---------------------------------------------------------------------------
local weightsButton = button(gui, { Size = UDim2.fromScale(0.16, 0.08), Position = UDim2.fromScale(0.82, 0.88),
	AnchorPoint = Vector2.new(0, 0.5), Text = "🏋 WEIGHTS" }, Color3.fromRGB(70, 140, 255))

local panel = Instance.new("Frame")
panel.Size = UDim2.fromScale(0.3, 0.32)
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.fromScale(0.98, 0.82)
panel.BackgroundColor3 = DARK
panel.Visible = false
corner(panel, 16)
stroke(panel, Color3.new(0, 0, 0), 3)
local panelRatio = Instance.new("UIAspectRatioConstraint")
panelRatio.AspectRatio = 1.5
panelRatio.Parent = panel
panel.Parent = gui

text(panel, { Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.05), Text = "UPGRADE WEIGHTS" })
local currentLabel = text(panel, { Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.05, 0.25),
	Font = Enum.Font.GothamBold, Text = "" })
local nextLabel = text(panel, { Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.42),
	TextColor3 = Color3.fromRGB(110, 230, 120), Text = "" })
local effectLabel = text(panel, { Size = UDim2.fromScale(0.9, 0.11), Position = UDim2.fromScale(0.05, 0.6),
	Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(200, 200, 210), Text = "" })
local buyButton = button(panel, { Size = UDim2.fromScale(0.8, 0.2), Position = UDim2.fromScale(0.1, 0.75), Text = "BUY" },
	Color3.fromRGB(60, 190, 80))

weightsButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		pop(panel)
	end
	sfx("rbxasset://sounds/button.wav", 0.5)
end)
buyButton.Activated:Connect(function()
	remotes.BuyWeight:FireServer()
end)

---------------------------------------------------------------------------
-- Training panel (bottom-center): timing bar
---------------------------------------------------------------------------
local train = Instance.new("Frame")
train.Size = UDim2.fromScale(0.5, 0.2)
train.AnchorPoint = Vector2.new(0.5, 1)
train.Position = UDim2.fromScale(0.5, 0.97)
train.BackgroundTransparency = 1
train.Visible = false
train.Parent = gui

text(train, { Size = UDim2.fromScale(1, 0.22), Text = "TAP / CLICK / SPACE when the line is in the green!" ,
	Font = Enum.Font.GothamBold })
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(1, 0.26)
bar.Position = UDim2.fromScale(0, 0.26)
bar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
corner(bar, 10)
stroke(bar, Color3.new(0, 0, 0), 3)
bar.ClipsDescendants = true
bar.Parent = train
local zone = Instance.new("Frame")
zone.AnchorPoint = Vector2.new(0.5, 0)
zone.Size = UDim2.fromScale(Config.Rep.zoneWidth, 1)
zone.BackgroundColor3 = Color3.fromRGB(70, 220, 90)
zone.Parent = bar
local needle = Instance.new("Frame")
needle.AnchorPoint = Vector2.new(0.5, 0)
needle.Size = UDim2.new(0, 6, 1, 0)
needle.BackgroundColor3 = Color3.new(1, 1, 1)
needle.ZIndex = 3
needle.Parent = bar

local comboLabel = text(train, { Size = UDim2.fromScale(0.5, 0.2), Position = UDim2.fromScale(0, 0.56),
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 150, 40), Text = "" })
local leaveButton = button(train, { Size = UDim2.fromScale(0.22, 0.24), Position = UDim2.fromScale(0.78, 0.56), Text = "LEAVE" },
	Color3.fromRGB(220, 60, 60))

local tapButton -- big TAP button for touch screens
if UserInputService.TouchEnabled then
	tapButton = button(gui, { Size = UDim2.fromScale(0.16, 0.16), AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.97, 0.72), Text = "LIFT!", Visible = false }, Color3.fromRGB(255, 170, 40))
	local r = Instance.new("UIAspectRatioConstraint")
	r.Parent = tapButton
end

---------------------------------------------------------------------------
-- Feedback: floating +gains, PERFECT text, rank-up feed
---------------------------------------------------------------------------
local function floatText(msg: string, color: Color3, size: number)
	local l = text(gui, { Text = msg, TextColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.2 * size, 0.07 * size), Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.12, 0.7) })
	pop(l)
	local tween = TweenService:Create(l, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = l.Position - UDim2.fromScale(0, 0.14),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		l:Destroy()
	end)
end

local feed = Instance.new("Frame")
feed.Size = UDim2.fromScale(0.5, 0.2)
feed.AnchorPoint = Vector2.new(0.5, 0)
feed.Position = UDim2.fromScale(0.5, 0.02)
feed.BackgroundTransparency = 1
feed.Parent = gui
local feedLayout = Instance.new("UIListLayout")
feedLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
feedLayout.Padding = UDim.new(0, 4)
feedLayout.Parent = feed

remotes.Announce.OnClientEvent:Connect(function(name: string, rankName: string, color: Color3, userId: number)
	local mine = userId == player.UserId
	local l = text(feed, { Size = UDim2.fromScale(1, mine and 0.36 or 0.24),
		Text = (mine and "🏆 YOU reached " or ("🏆 " .. name .. " reached ")) .. string.upper(rankName) .. "!",
		TextColor3 = color })
	pop(l)
	if mine then
		sfx("rbxasset://sounds/electronicpingshort.wav", 0.8, 0.7)
	end
	task.delay(3.5, function()
		local t = TweenService:Create(l, TweenInfo.new(0.5), { TextTransparency = 1 })
		t:Play()
		t.Completed:Once(function()
			l:Destroy()
		end)
	end)
end)

---------------------------------------------------------------------------
-- Stats updates
---------------------------------------------------------------------------
local stats = { strength = 0, cash = 0, tier = 1 }

local function render()
	strengthLabel.Text = "💪 " .. Util.format(stats.strength)
	cashLabel.Text = "$" .. Util.format(stats.cash)
	local index, rank = Util.rankFor(stats.strength)
	local nextRank = Config.Ranks[index + 1]
	rankFill.BackgroundColor3 = rank.color
	if nextRank then
		local p = (stats.strength - rank.min) / (nextRank.min - rank.min)
		rankFill.Size = UDim2.fromScale(math.clamp(p, 0, 1), 1)
		rankLabel.Text = rank.name .. " → " .. nextRank.name .. "  " .. Util.format(stats.strength) .. "/" .. Util.format(nextRank.min)
	else
		rankFill.Size = UDim2.fromScale(1, 1)
		rankLabel.Text = rank.name .. " (MAX RANK)"
	end

	local current = Config.Weights[stats.tier]
	local nextWeight = Config.Weights[stats.tier + 1]
	currentLabel.Text = "Now: " .. current.name .. "  (x" .. current.mult .. " per rep)"
	if nextWeight then
		nextLabel.Text = "Next: " .. nextWeight.name .. "  (x" .. nextWeight.mult .. " per rep)"
		effectLabel.Text = "Every rep gives " .. (nextWeight.mult // current.mult) .. "x more. Timing gets faster!"
		buyButton.Text = "BUY  $" .. Util.format(nextWeight.cost)
		local affordable = stats.cash >= nextWeight.cost
		buyButton.BackgroundColor3 = if affordable then Color3.fromRGB(60, 190, 80) else Color3.fromRGB(90, 90, 100)
		weightsButton.Text = if affordable then "🏋 WEIGHTS  ⬆" else "🏋 WEIGHTS"
	else
		nextLabel.Text = "MAX WEIGHT!"
		effectLabel.Text = "You lift the heaviest weight."
		buyButton.Text = "MAXED"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
		weightsButton.Text = "🏋 WEIGHTS"
	end
end

remotes.StatsChanged.OnClientEvent:Connect(function(data)
	local boughtWeight = data.tier > stats.tier
	stats = data
	render()
	if boughtWeight then
		pop(panel)
		floatText("NEW WEIGHT: " .. Config.Weights[stats.tier].name .. "!", Config.Weights[stats.tier].color, 1.4)
		sfx("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.3)
	end
end)
remotes.RequestStats:FireServer()
render()

---------------------------------------------------------------------------
-- Training mini-game
---------------------------------------------------------------------------
local training = nil -- { startTime, speed, zone }
local lastTap = 0
local renderConn: RBXScriptConnection? = nil

local function setTraining(info)
	training = info
	train.Visible = info ~= nil
	if tapButton then
		tapButton.Visible = info ~= nil
	end
	comboLabel.Text = ""
	if info then
		zone.Position = UDim2.fromScale(info.zone, 0)
		zone.Size = UDim2.fromScale(info.zoneWidth, 1)
		if not renderConn then
			renderConn = RunService.RenderStepped:Connect(function()
				if training then
					local x = Util.needle(workspace:GetServerTimeNow() - training.startTime, training.speed)
					needle.Position = UDim2.fromScale(x, 0)
				end
			end)
		end
	elseif renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

local function tap()
	if not training then
		return
	end
	local t = os.clock()
	if t - lastTap < Config.Rep.cooldown then
		return
	end
	lastTap = t
	remotes.Rep:FireServer(workspace:GetServerTimeNow())
end

remotes.StartTraining.OnClientEvent:Connect(function(info)
	setTraining(info)
	pop(train)
end)
remotes.StopTraining.OnClientEvent:Connect(function()
	setTraining(nil)
end)

remotes.RepResult.OnClientEvent:Connect(function(result)
	if not training then
		return
	end
	training.zone = result.zone
	TweenService:Create(zone, TweenInfo.new(0.15), { Position = UDim2.fromScale(result.zone, 0) }):Play()
	floatText("+" .. Util.format(result.gain) .. " 💪", if result.perfect then Color3.fromRGB(255, 220, 60) else Color3.new(1, 1, 1),
		if result.perfect then 1.2 else 0.9)
	if result.perfect then
		floatText("PERFECT!", Color3.fromRGB(110, 255, 120), 1.5)
		sfx("rbxasset://sounds/electronicpingshort.wav", 0.4, 1 + math.min(result.combo, 10) * 0.05)
	else
		sfx("rbxasset://sounds/clickfast.wav", 0.4)
	end
	comboLabel.Text = if result.combo >= 2 then ("🔥 COMBO x" .. result.combo .. "  (+" .. math.floor(math.min(Config.Rep.comboMax, (result.combo - 1) * Config.Rep.comboStep) * 100 + 0.5) .. "%)") else ""
	if result.combo >= 2 then
		pop(comboLabel)
	end
	-- small camera kick
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.CameraOffset = Vector3.new(0, -0.25, 0)
		TweenService:Create(humanoid, TweenInfo.new(0.15), { CameraOffset = Vector3.zero }):Play()
	end
end)

leaveButton.Activated:Connect(function()
	remotes.StopTraining:FireServer()
end)
if tapButton then
	tapButton.Activated:Connect(tap)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not training then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		tap()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
		tap()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonB then
		remotes.StopTraining:FireServer()
	end
end)
