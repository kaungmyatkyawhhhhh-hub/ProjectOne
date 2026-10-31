--[[
	Penthouse (client) - the luxury towers' effects (see server/Towers.lua)
	  * elevator fades, toasts and cash popups from the server (remote TowerFX)
	  * prompts worded for this player (owned penthouses, residents-only features)
	  * party mode: coloured lights sweeping the penthouse and a spinning mirror ball
	  * the car showcase: the resident's car, skinned and turning on its turntable
	  * the TV: a news channel, a car-stocks ticker and a music visualiser
	  * the telescope on the roof (zoomed look over the city) and the helicopter tour (a flight
	    round the city with the camera)
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme

local COLORS = { money = Theme.Money, accent = Theme.Accent, warning = Theme.Warning, danger = Theme.Danger }

---------------------------------------------------------------------
-- Prompt wording for this player
---------------------------------------------------------------------
local function ownedSet(): { [string]: boolean }
	local set = {}
	local raw = player:GetAttribute("Penthouses")
	if type(raw) == "string" then
		for id in raw:gmatch("[^,]+") do
			set[id] = true
		end
	end
	return set
end

local function word(p: Instance)
	if not p:IsA("ProximityPrompt") then
		return
	end
	local owned = ownedSet()
	local id = p:GetAttribute("Tower")
	if type(id) ~= "string" then
		return
	end
	if p:GetAttribute("BaseAction") == nil then
		p:SetAttribute("BaseAction", p.ActionText)
		p:SetAttribute("BaseObject", p.ObjectText)
	end
	local baseAction = p:GetAttribute("BaseAction") :: string
	local baseObject = p:GetAttribute("BaseObject") :: string
	if p:HasTag("TowerBuy") then
		p.ActionText = if owned[id] then "Owned" else baseAction
		p.HoldDuration = if owned[id] then 0 else 1.5
	elseif p:HasTag("TowerOwner") then
		p.ObjectText = if owned[id] then baseObject else baseObject .. " (residents only)"
	end
end

local function rewordAll()
	for _, tag in { "TowerBuy", "TowerOwner" } do
		for _, p in CollectionService:GetTagged(tag) do
			word(p)
		end
	end
end
for _, tag in { "TowerBuy", "TowerOwner" } do
	CollectionService:GetInstanceAddedSignal(tag):Connect(word)
end
player:GetAttributeChangedSignal("Penthouses"):Connect(rewordAll)
task.defer(rewordAll)

---------------------------------------------------------------------
-- Telescope and helicopter tour: the camera leaves the character for a while
---------------------------------------------------------------------
local viewing = false
local overlay: ScreenGui? = nil

local function makeOverlay(title: string, hint: string, scope: boolean): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "TowerView"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	for _, top in { true, false } do
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = Color3.new(0, 0, 0)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.fromScale(1, if scope then 0.08 else 0.11)
		bar.Position = if top then UDim2.fromScale(0, 0) else UDim2.fromScale(0, if scope then 0.92 else 0.89)
		bar.Parent = gui
	end
	if scope then
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromScale(0.8, 0.8)
		ring.BackgroundTransparency = 1
		ring.Parent = gui
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.Parent = ring
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = ring
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 900 -- everything outside the lens goes dark
		stroke.Transparency = 0.08
		stroke.Parent = ring
		for _, horiz in { true, false } do
			local hair = Instance.new("Frame")
			hair.AnchorPoint = Vector2.new(0.5, 0.5)
			hair.Position = UDim2.fromScale(0.5, 0.5)
			hair.Size = if horiz then UDim2.new(0.12, 0, 0, 1) else UDim2.new(0, 1, 0.12, 0)
			hair.BackgroundColor3 = Color3.new(1, 1, 1)
			hair.BackgroundTransparency = 0.5
			hair.BorderSizePixel = 0
			hair.Parent = gui
		end
	end
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -14)
	label.Size = UDim2.new(1, 0, 0, 44)
	label.Font = Enum.Font.GothamMedium
	label.RichText = true
	label.Text = string.format('<font size="20"><b>%s</b></font>\n<font size="14" color="#AAB0C0">%s</font>', title, hint)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.ZIndex = 3
	label.Parent = gui
	local exit = Instance.new("TextButton")
	exit.AnchorPoint = Vector2.new(1, 0)
	exit.Position = UDim2.new(1, -16, 0, 16)
	exit.Size = UDim2.fromOffset(96, 36)
	exit.BackgroundColor3 = Theme.Panel
	exit.BackgroundTransparency = 0.1
	exit.Font = Enum.Font.GothamBold
	exit.Text = "EXIT"
	exit.TextSize = 15
	exit.TextColor3 = Theme.Text
	exit.ZIndex = 4
	exit.Name = "Exit"
	exit.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = exit
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

local function humanoid(): Humanoid?
	local char = player.Character
	return if char then char:FindFirstChildOfClass("Humanoid") else nil
end

local function endView()
	if not viewing then
		return
	end
	viewing = false
	if overlay then
		overlay:Destroy()
		overlay = nil
	end
	local hum = humanoid()
	if hum then
		hum.WalkSpeed = 16
		camera.CameraSubject = hum
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

local function startView(title: string, hint: string, scope: boolean): ScreenGui
	viewing = true
	local hum = humanoid()
	if hum then
		hum.WalkSpeed = 0
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local gui = makeOverlay(title, hint, scope)
	overlay = gui;
	(gui:FindFirstChild("Exit") :: TextButton).Activated:Connect(endView)
	return gui
end

local EXIT_KEYS = { [Enum.KeyCode.X] = true, [Enum.KeyCode.Escape] = true, [Enum.KeyCode.Backspace] = true, [Enum.KeyCode.ButtonB] = true, [Enum.KeyCode.Space] = true }
UserInputService.InputBegan:Connect(function(input, processed)
	if viewing and (EXIT_KEYS[input.KeyCode] or (not processed and input.KeyCode == Enum.KeyCode.W)) then
		endView()
	end
end)

local function telescope(eye: Vector3, dir: Vector3)
	if viewing then
		return
	end
	startView("TELESCOPE", "Drag to look  ·  scroll to zoom  ·  X to stop", true)
	local yaw = math.atan2(-dir.X, -dir.Z)
	local pitch = math.asin(math.clamp(dir.Y, -1, 1))
	local yaw0 = yaw
	local fov = 16
	local dragging = false
	local conns: { RBXScriptConnection } = {}
	table.insert(conns, UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			fov = math.clamp(fov - input.Position.Z * 2, 5, 35)
		elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local k = fov / 900
			yaw = math.clamp(yaw - input.Delta.X * k, yaw0 - 1.4, yaw0 + 1.4)
			pitch = math.clamp(pitch - input.Delta.Y * k, -0.6, 0.25)
		end
	end))
	table.insert(conns, RunService.RenderStepped:Connect(function()
		if not viewing then
			for _, c in conns do
				c:Disconnect()
			end
			return
		end
		camera.FieldOfView = fov
		camera.CFrame = CFrame.new(eye) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	end))
end

local function tour(from: Vector3)
	if viewing then
		return
	end
	UI.fade(true, 0.35)
	task.wait(0.4)
	startView("HELICOPTER TOUR", "X to land", false)
	UI.fade(false, 0.6)
	local t0 = os.clock()
	local DUR = 32
	local center = Vector3.new(0, 0, 0)
	local startAngle = math.atan2(from.Z - center.Z, from.X - center.X)
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if not viewing or t > DUR then
			conn:Disconnect()
			if viewing then
				UI.fade(true, 0.35)
				task.wait(0.4)
				endView()
				UI.fade(false, 0.5)
			end
			return
		end
		-- lift off from the helipad, then a wide slow circle round the skyline, dipping lower
		-- over the far side
		local lift = math.clamp(t / 5, 0, 1)
		local a = startAngle + t / DUR * math.pi * 2 * 0.85
		local r = 520 + 260 * math.sin(t / DUR * math.pi)
		local orbit = center + Vector3.new(math.cos(a) * r, 230 + 60 * math.sin(t * 0.35), math.sin(a) * r)
		local pos = from:Lerp(orbit, lift ^ 2 * (3 - 2 * lift))
		local look = center + Vector3.new(0, 90, 0)
		local ahead = center + Vector3.new(math.cos(a + 0.5) * r * 0.6, 120, math.sin(a + 0.5) * r * 0.6)
		local target = look:Lerp(ahead, 0.35)
		camera.FieldOfView = 62
		camera.CFrame = CFrame.lookAt(pos, target) * CFrame.Angles(0, 0, math.sin(t * 0.6) * 0.04)
	end)
end

---------------------------------------------------------------------
-- The showcase turntable's car picker (owner, 2026-10-23: "add a function to change car")
---------------------------------------------------------------------
local pickerGui: ScreenGui? = nil
local function pickShowcase(towerId: string, cars: { any }, current: any)
	if pickerGui then
		pickerGui:Destroy()
	end
	local Cars = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cars"))
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShowcasePicker"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	pickerGui = gui
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(360, 420)
	panel.BackgroundColor3 = Theme.Panel
	panel.BackgroundTransparency = 0.05
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Stroke
	stroke.Thickness = 1.5
	stroke.Parent = panel
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(18, 12)
	title.Size = UDim2.new(1, -70, 0, 30)
	title.Font = Enum.Font.GothamBlack
	title.Text = "CAR ON SHOW"
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Parent = panel
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(30, 30)
	close.BackgroundColor3 = Theme.PanelLight
	close.Font = Enum.Font.GothamBlack
	close.Text = "X"
	close.TextSize = 16
	close.TextColor3 = Theme.Text
	close.Parent = panel
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = close
	close.Activated:Connect(function()
		gui:Destroy()
	end)
	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(14, 52)
	list.Size = UDim2.new(1, -28, 1, -66)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	local pickRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TowerShowcase") :: RemoteEvent
	for _, id in cars do
		local spec = if type(id) == "string" then Cars.ById[id] else nil
		if spec then
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -6, 0, 40)
			b.BackgroundColor3 = if id == current then Theme.Accent else Theme.PanelLight
			b.Font = Enum.Font.GothamBold
			b.Text = spec.Name
			b.TextSize = 15
			b.TextColor3 = if id == current then Theme.Background else Theme.Text
			b.Parent = list
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 8)
			bc.Parent = b
			b.Activated:Connect(function()
				pickRemote:FireServer(towerId, id)
				UI.toast(spec.Name .. " is on show", Theme.Accent)
				gui:Destroy()
			end)
		end
	end
end

---------------------------------------------------------------------
-- Server messages
---------------------------------------------------------------------
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local towerFx = remotes:WaitForChild("TowerFX", 120) :: RemoteEvent?
if towerFx then
	towerFx.OnClientEvent:Connect(function(info)
		if type(info) ~= "table" then
			return
		end
		local kind = info.kind
		if kind == "pickShowcase" and type(info.cars) == "table" and type(info.tower) == "string" then
			pickShowcase(info.tower, info.cars, info.current)
		elseif kind == "travel" then
			UI.fade(true, 0.25)
			task.delay(0.55, function()
				UI.fade(false, 0.4)
				if type(info.label) == "string" then
					UI.toast(info.label, Theme.Accent)
				end
			end)
		elseif kind == "toast" then
			UI.toast(tostring(info.text), COLORS[info.color] or Theme.Accent)
		elseif kind == "cash" then
			UI.popup(tostring(info.text), tonumber(info.amount) or 0, Theme.Money)
		elseif kind == "bought" then
			UI.toast(tostring(info.text), Theme.Money)
			local hum = humanoid()
			if hum then
				pcall(function()
					hum:PlayEmote("cheer")
				end)
			end
		elseif kind == "cheer" or kind == "outfit" then
			local hum = humanoid()
			if hum then
				pcall(function()
					hum:PlayEmote(if kind == "cheer" then "cheer" else "dance")
				end)
			end
			if kind == "outfit" then
				UI.toast("Looking sharp", Theme.Accent)
			end
		elseif kind == "scope" and typeof(info.eye) == "Vector3" and typeof(info.dir) == "Vector3" then
			telescope(info.eye, info.dir)
		elseif kind == "tour" and typeof(info.from) == "Vector3" then
			task.spawn(tour, info.from)
		end
	end)
end

player.CharacterRemoving:Connect(endView)

---------------------------------------------------------------------
-- Party lights, the showcase car and the TV (only near the camera)
---------------------------------------------------------------------
local TICKERS = { "BNW", "MERCER", "LAMBRINI", "FERRARA", "TOYOKA", "NISUN", "PORSHA", "BUGOTTI", "ASTIN", "LEXIS" }
local HEADLINES = {
	"SPEED CAMERAS GO LIVE ON THE LEGENDS LOOP",
	"LUXURY TOWERS: PENTHOUSE PRICES HIT RECORD HIGHS",
	"NIGHT RACERS SPOTTED CUTTING UP TRAFFIC DOWNTOWN",
	"RAIN EXPECTED TO CONTINUE ALL NIGHT",
	"NEW HYPERCAR SPOTTED AT THE HARBOUR",
	"CITY LEGENDS BANK RAISES SECURITY",
}

type Tv = { gui: SurfaceGui, pages: { Frame }, prices: { number }, ticker: TextLabel, head: TextLabel, bars: { Frame }, t: number }
local tvs: { [BasePart]: Tv } = {}

local function buildTv(part: BasePart): Tv
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.CanvasSize = Vector2.new(640, 352)
	gui.Parent = part
	local pages: { Frame } = {}
	local function page(bg: Color3): Frame
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = bg
		f.BorderSizePixel = 0
		f.Visible = false
		f.Parent = gui
		table.insert(pages, f)
		return f
	end
	local function text(parent: Frame, t: string, size: number, pos: UDim2, sz: UDim2, color: Color3, font: Enum.Font?): TextLabel
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = pos
		l.Size = sz
		l.Text = t
		l.TextSize = size
		l.Font = font or Enum.Font.GothamBold
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextWrapped = true
		l.Parent = parent
		return l
	end
	-- 1: news
	local news = page(Color3.fromRGB(12, 14, 26))
	local strip = Instance.new("Frame")
	strip.BackgroundColor3 = Color3.fromRGB(200, 20, 40)
	strip.BorderSizePixel = 0
	strip.Size = UDim2.new(1, 0, 0, 46)
	strip.Position = UDim2.new(0, 0, 1, -46)
	strip.Parent = news
	text(news, "CITY LEGENDS NEWS", 30, UDim2.fromOffset(28, 22), UDim2.new(1, -56, 0, 40), Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	text(news, "LIVE", 18, UDim2.new(1, -90, 0, 28), UDim2.fromOffset(60, 24), Color3.fromRGB(255, 70, 90))
	local head = text(news, HEADLINES[1], 34, UDim2.fromOffset(28, 110), UDim2.new(1, -56, 0, 150), Color3.fromRGB(235, 238, 245), Enum.Font.GothamBlack)
	local ticker = text(strip, "", 20, UDim2.fromOffset(0, 10), UDim2.new(3, 0, 0, 26), Color3.new(1, 1, 1))
	ticker.TextWrapped = false
	-- 2: car stocks
	local market = page(Color3.fromRGB(8, 12, 16))
	text(market, "CAR STOCKS", 28, UDim2.fromOffset(28, 18), UDim2.new(1, -56, 0, 36), Theme.Money, Enum.Font.GothamBlack)
	local prices: { number } = {}
	for i, name in TICKERS do
		prices[i] = 50 + (i * 37) % 160
		local row = text(market, name, 20, UDim2.fromOffset(28 + ((i - 1) // 5) * 300, 70 + ((i - 1) % 5) * 52), UDim2.fromOffset(280, 40), Color3.fromRGB(220, 224, 235))
		row.Name = "Row" .. i
		row.RichText = true
	end
	-- 3: music visualiser
	local viz = page(Color3.fromRGB(6, 4, 14))
	text(viz, "NIGHT DRIVE FM", 26, UDim2.fromOffset(28, 18), UDim2.new(1, -56, 0, 36), Theme.Accent2, Enum.Font.GothamBlack)
	local bars: { Frame } = {}
	for i = 1, 24 do
		local b = Instance.new("Frame")
		b.AnchorPoint = Vector2.new(0, 1)
		b.BorderSizePixel = 0
		b.BackgroundColor3 = Theme.Accent:Lerp(Theme.Accent2, i / 24)
		b.Position = UDim2.new(0, 28 + (i - 1) * 24, 1, -30)
		b.Size = UDim2.fromOffset(16, 40)
		b.Parent = viz
		table.insert(bars, b)
	end
	return { gui = gui, pages = pages, prices = prices, ticker = ticker, head = head, bars = bars, t = 0 }
end

local function tickTv(part: BasePart, tv: Tv, dt: number)
	tv.t += dt
	local ch = math.clamp((part:GetAttribute("Channel") :: number?) or 1, 1, #tv.pages)
	for i, p in tv.pages do
		p.Visible = i == ch
	end
	if ch == 1 then
		tv.head.Text = HEADLINES[math.floor(tv.t / 6) % #HEADLINES + 1]
		local parts = {}
		for i, name in TICKERS do
			table.insert(parts, string.format("%s  %.2f", name, tv.prices[i]))
		end
		tv.ticker.Text = table.concat(parts, "     ·     ")
		tv.ticker.Position = UDim2.fromOffset(640 - (tv.t * 90) % 2600, 10)
	elseif ch == 2 then
		for i, name in TICKERS do
			local change = (math.noise(i * 3.1, tv.t * 0.05) * 6)
			tv.prices[i] = math.max(5, tv.prices[i] * (1 + change * dt * 0.02))
			local row = tv.pages[2]:FindFirstChild("Row" .. i) :: TextLabel?
			if row then
				local col = if change >= 0 then "#3DFF8F" else "#FF4D5E"
				row.Text = string.format('%s   <font color="%s">%.2f  %s%.1f%%</font>', name, col, tv.prices[i], if change >= 0 then "+" else "", change)
			end
		end
	else
		for i, b in tv.bars do
			local h = 30 + 220 * math.abs(math.noise(i * 0.7, tv.t * 2.2))
			b.Size = UDim2.fromOffset(16, h)
		end
	end
end

local skinned: { [Model]: boolean } = {}
local partyBase: { [Instance]: Color3 } = {}

RunService.RenderStepped:Connect(function(dt: number)
	local camPos = camera.CFrame.Position
	local now = os.clock()
	-- party mode: which towers are partying (and close enough to see)
	local partying: { [string]: boolean } = {}
	for _, m in CollectionService:GetTagged("TowerPenthouse") do
		if m:IsA("Model") and m:GetAttribute("Party") == true then
			local pivot = m:GetPivot().Position
			if (Vector3.new(pivot.X, camPos.Y, pivot.Z) - camPos).Magnitude < 400 then
				partying[m:GetAttribute("TowerId") :: string] = true
			end
		end
	end
	for _, holder in CollectionService:GetTagged("TowerPartyLamp") do
		local l = holder:FindFirstChild("PartyLight")
		if l and l:IsA("PointLight") then
			local i = (holder:GetAttribute("Index") :: number?) or 0
			if partying[holder:GetAttribute("Tower") :: string] then
				l.Color = Color3.fromHSV((now * 0.25 + i / 6) % 1, 0.85, 1)
				l.Brightness = 2 + math.sin(now * 8 + i) * 1.2
			elseif l.Brightness ~= 0 then
				l.Brightness = 0
			end
		end
	end
	for _, strip in CollectionService:GetTagged("TowerPartyStrip") do
		if strip:IsA("BasePart") then
			partyBase[strip] = partyBase[strip] or strip.Color
			strip.Color = if partying[strip:GetAttribute("Tower") :: string] then Color3.fromHSV((now * 0.4) % 1, 0.9, 1) else partyBase[strip]
		end
	end
	for _, ball in CollectionService:GetTagged("TowerMirrorBall") do
		if ball:IsA("BasePart") and partying[ball:GetAttribute("Tower") :: string] then
			ball.CFrame = ball.CFrame * CFrame.Angles(0, dt * 1.6, 0)
		end
	end
	-- showcase cars: skinned when you come close, turning slowly while you're near
	for _, car in CollectionService:GetTagged("TowerShowcase") do
		if not car:IsA("Model") or not car.Parent then
			continue
		end
		local d = (car:GetPivot().Position - camPos).Magnitude
		if d < 450 and not skinned[car] then
			skinned[car] = true
			task.spawn(function()
				local ok, err = pcall(CarSkin.apply, car, false)
				if not ok then
					warn("[CityLegends] showcase car skin failed:", err)
				end
			end)
		end
		if d < 260 and not car:GetAttribute("NoSpin") then
			car:PivotTo(car:GetPivot() * CFrame.Angles(0, dt * 0.25, 0))
		end
	end
	-- TVs
	for _, part in CollectionService:GetTagged("TowerTV") do
		if part:IsA("BasePart") and (part.Position - camPos).Magnitude < 160 then
			local tv = tvs[part]
			if not tv then
				tv = buildTv(part)
				tvs[part] = tv
			end
			tickTv(part, tv, dt)
		end
	end
end)
