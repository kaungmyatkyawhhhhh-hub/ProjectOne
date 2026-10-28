-- MomentController: the big moments (GDD 9): rank up (popup + rising sound + gold ring on the ground),
-- the GO PRO button + confirm screen (YOU KEEP / YOU RESET / YOU GET), the Go Pro cutscene (~4 s,
-- SKIP after the first time) and the arrival banner in a new area (the Stadium's tunnel reveal).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local Areas = require(Shared.Config.Areas)
local Ranks = require(Shared.Config.Ranks)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local Moment = {}
local ctx, canvas
local goProBtn, confirmWin
local queue, busy = {}, false

----------------------------------------------------------------------------
-- rank up
----------------------------------------------------------------------------
local function groundRing(color)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local ring = Instance.new("Part")
	ring.Name = "RankRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.15, 4, 4)
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Transparency = 0.1
	ring.Parent = workspace.Runtime or workspace
	UIKit.tween(ring, 1.1, { Size = Vector3.new(0.15, 22, 22), Transparency = 1 })
	task.delay(1.2, function()
		ring:Destroy()
	end)
end

local function rankUp(info)
	local color = Ranks.Colors[info.Rank] or P.Gold
	local card = UIKit.panel({ Name = "RankUp", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 156), Size = UDim2.fromOffset(380, 120), AccentColor = color, StrokeColor = color, StrokeThickness = 3, ZIndex = 30, Parent = canvas })
	local s = make("UIScale", { Scale = 0.4, Parent = card })
	local badge = make("Frame", { BackgroundColor3 = P.White, Position = UDim2.fromOffset(24, 18), Size = UDim2.fromOffset(84, 84), Parent = card })
	UIKit.corner(badge, UDim.new(0.5, 0))
	UIKit.gradient(badge, color:Lerp(P.White, 0.35), color:Lerp(P.SpeedBlack, 0.35), 135)
	UIKit.stroke(badge, P.White, 3, 0.2)
	UIKit.text({ Text = string.sub(info.Rank, 1, 1), TextSize = 44, Color = P.SpeedBlack, Stroke = false, Parent = badge })
	UIKit.text({ Text = "RANK UP!", TextSize = 16, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(124, 14), Size = UDim2.fromOffset(240, 20), Parent = card })
	UIKit.text({ Text = string.upper(info.Rank), TextSize = 40, Color = color, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(124, 34), Size = UDim2.fromOffset(240, 46), Parent = card })
	if info.Coins and info.Coins > 0 then
		local ci = UIKit.coinIcon(20, card)
		ci.Position = UDim2.fromOffset(126, 86)
		UIKit.text({ Text = "+" .. Format.short(info.Coins), TextSize = 18, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(152, 82), Size = UDim2.fromOffset(160, 26), Parent = card })
	end
	UIKit.tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	ctx.Sound.play("RankUp")
	groundRing(color)
	task.wait(2.6)
	UIKit.tween(s, 0.2, { Scale = 0.6 })
	task.wait(0.2)
	card:Destroy()
end

----------------------------------------------------------------------------
-- go pro
----------------------------------------------------------------------------
local function block(parent, x, title, color, lines)
	local b = UIKit.panel({ Size = UDim2.new(1 / 3, -10, 1, -60), Position = UDim2.new(x / 3, 5, 0, 0), AccentColor = color, StrokeColor = color, Parent = parent })
	UIKit.text({ Text = title, TextSize = 22, Color = color, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 28), Parent = b })
	for i, line in lines do
		UIKit.text({ Text = line, Font = F.BodyBold, TextSize = 15, Wrapped = true, Position = UDim2.fromOffset(16, 40 + (i - 1) * 24), Size = UDim2.new(1, -28, 0, 22), XAlign = Enum.TextXAlignment.Left, Parent = b })
	end
	return b
end

local function buildConfirm()
	confirmWin = UIKit.window({ Name = "GoPro", Title = "GO PRO", Size = Vector2.new(700, 320), Accent = P.Gold, Parent = canvas })
	local body = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = confirmWin.content })
	confirmWin.onOpen = function()
		for _, c in body:GetChildren() do
			c:Destroy()
		end
		local league = player:GetAttribute("League") or 1
		local next_ = league + 1
		local area = nil
		for _, id in Areas.Order do
			if Areas[id].League == next_ then
				area = Areas[id]
			end
		end
		block(body, 0, "YOU KEEP", P.BrightBlue, { "Coins", "Shoes and trails", "Coaches", "Medals and titles", "Everything you bought" })
		block(body, 1, "YOU RESET", P.DangerRed, { "SPEED back to 0", "Rank back to Bronze" })
		block(body, 2, "YOU GET", P.Gold, {
			area and area.Name or ("League " .. next_),
			"x8 SPEED per step forever",
			"A free coach roll",
			"Title: " .. (Areas.GoPro.Titles[next_] or "PRO"),
		})
		local go = UIKit.button({ Name = "Confirm", Style = "Green", Text = "GO PRO!", TextSize = 26, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 90, 1, -2), Size = UDim2.fromOffset(220, 52), Parent = body })
		go.Activated:Connect(function()
			Moment.goPro()
		end)
		UIKit.button({ Name = "NotYet", Style = "Dark", Text = "NOT YET", TextSize = 18, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, -110, 1, -2), Size = UDim2.fromOffset(150, 52), Parent = body, OnClick = function()
			confirmWin.hide()
		end })
	end
end

local function cutscene(info)
	local stage = make("Frame", { Name = "GoProScene", BackgroundColor3 = P.White, Position = UDim2.fromOffset(0, -80), Size = UDim2.new(1, 0, 1, 80), ZIndex = 45, ClipsDescendants = true, Parent = canvas })
	UIKit.gradient(stage, Color3.fromHex("#FFE38C"), P.DeepBlue, 90)
	local rays = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(900, 900), Parent = stage })
	for i = 1, 14 do
		local ray = make("Frame", { BackgroundColor3 = P.White, BackgroundTransparency = 0.7, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 40, 1, 0), Rotation = i * (180 / 14), Parent = rays })
		UIKit.corner(ray, UDim.new(0.5, 0))
	end
	local title = UIKit.text({ Text = "GO PRO!", TextSize = 96, Color = P.Gold, StrokeColor = P.SpeedBlack, StrokeThickness = 4, StrokeTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromOffset(700, 110), ZIndex = 5, Parent = stage })
	local ts = make("UIScale", { Scale = 0.2, Parent = title })
	local sub = UIKit.text({ Text = ("NEXT: %s"):format(info.AreaName or ("LEAGUE " .. info.To)), TextSize = 30, StrokeColor = P.SpeedBlack, StrokeThickness = 2, StrokeTransparency = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.4, 66), Size = UDim2.fromOffset(700, 40), ZIndex = 5, Parent = stage })
	sub.TextTransparency = 1
	if info.Title then
		UIKit.text({ Text = "NEW TITLE: " .. info.Title, Font = F.BodyBold, TextSize = 18, Color = P.Gold, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.4, 112), Size = UDim2.fromOffset(500, 24), ZIndex = 5, Parent = stage })
	end
	local done = false
	if not info.FirstTime then
		UIKit.button({ Style = "Dark", Text = "SKIP", TextSize = 16, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(100, 42), Parent = stage, OnClick = function()
			done = true
		end })
	end
	ctx.Sound.play("GoPro")
	UIKit.tween(ts, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.6, function()
		UIKit.tween(sub, 0.4, { TextTransparency = 0 })
	end)
	local start = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		rays.Rotation = (os.clock() - start) * 25
	end)
	while not done and os.clock() - start < 4 do
		task.wait()
	end
	conn:Disconnect()
	stage:Destroy()
end

local goBusy = false
function Moment.goPro()
	if goBusy then
		return
	end
	goBusy = true
	confirmWin.hide(true)
	local ok, info = ctx.Net.call("GoPro")
	if ok then
		goProBtn.Visible = false
		cutscene(info)
		if info.Area then
			ctx.Net.call("TeleportArea", info.Area)
		end
	else
		ctx.Hud.toast("Not ready to GO PRO yet", "Denied")
	end
	goBusy = false
end

local function arrive(info)
	local banner = make("Frame", { Name = "Arrive", BackgroundColor3 = P.White, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.34), Size = UDim2.fromOffset(520, 110), ZIndex = 30, Parent = canvas })
	UIKit.corner(banner, 14)
	UIKit.gradient(banner, P.Carbon, P.SpeedBlack, 90)
	UIKit.stroke(banner, P.Gold, 3)
	UIKit.text({ Text = ("LEAGUE %d"):format(info.League), TextSize = 18, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 22), Parent = banner })
	UIKit.text({ Text = info.Name, TextSize = 44, Color = P.Gold, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 56), Parent = banner })
	local s = make("UIScale", { Scale = 0.5, Parent = banner })
	UIKit.tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	ctx.Sound.play("Arrive")
	task.wait(2.8)
	UIKit.tween(s, 0.2, { Scale = 0.6 })
	task.wait(0.2)
	banner:Destroy()
end

----------------------------------------------------------------------------
local function run(kind, info)
	table.insert(queue, { kind, info })
	if busy then
		return
	end
	task.spawn(function()
		while #queue > 0 do
			local item = table.remove(queue, 1)
			busy = true
			if item[1] == "RankUp" then
				rankUp(item[2])
			elseif item[1] == "Arrive" then
				arrive(item[2])
			end
			busy = false
		end
	end)
end

local function updateGoProButton()
	local ready = player:GetAttribute("GoProReady") == true
	goProBtn.Visible = ready and not player:GetAttribute("InRace")
end

function Moment.start(c)
	ctx = c
	ctx.Moment = Moment
	canvas = ctx.Hud.canvas
	buildConfirm()
	goProBtn = UIKit.button({ Name = "GoProButton", Style = "Green", Text = "GO PRO!", TextSize = 24, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 164), Size = UDim2.fromOffset(196, 54), Parent = canvas, OnClick = function()
		confirmWin.show()
	end })
	goProBtn.Visible = false
	local pulse = make("UIScale", { Parent = goProBtn.Face })
	task.spawn(function()
		while true do
			if goProBtn.Visible then
				UIKit.tween(pulse, 0.45, { Scale = 1.07 }, Enum.EasingStyle.Sine)
				task.wait(0.45)
				UIKit.tween(pulse, 0.45, { Scale = 1 }, Enum.EasingStyle.Sine)
				task.wait(0.45)
			else
				task.wait(0.3)
			end
		end
	end)
	player:GetAttributeChangedSignal("GoProReady"):Connect(updateGoProButton)
	player:GetAttributeChangedSignal("InRace"):Connect(updateGoProButton)
	updateGoProButton()

	ctx.Net.get("Moment").OnClientEvent:Connect(function(kind, info)
		if kind == "GoProReady" then
			ctx.Hud.toast("Coach Benji: You're ready. Time to GO PRO!", "Gold")
		else
			run(kind, info)
		end
	end)

	-- COMING SOON gates: NOTIFY ME (Roblox experience notifications opt-in)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Opens") == "NotifyMe" then
			local ok, can = pcall(function()
				return ExperienceNotificationService:CanPromptOptInAsync()
			end)
			if ok and can then
				pcall(function()
					ExperienceNotificationService:PromptOptIn()
				end)
			else
				ctx.Hud.toast("We'll tell you when it opens!", "Gold")
			end
		end
	end)
	-- Studio test switch: Workspace TestOpenWindow = "GoPro"
	workspace:GetAttributeChangedSignal("TestOpenWindow"):Connect(function()
		if workspace:GetAttribute("TestOpenWindow") == "GoPro" and RunService:IsStudio() then
			confirmWin.show()
		end
	end)
end

return Moment
