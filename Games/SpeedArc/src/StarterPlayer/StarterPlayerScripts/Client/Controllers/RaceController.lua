-- RaceController: JOIN window, 3-2-1-GO, drawing the runners smoothly from server progress,
-- BOOST taps, the live position bar, FINAL STRETCH, and the results / medal popup (GDD 8).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Race = require(Shared.Config.Race)
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local TrackPath = require(Shared.Util.TrackPath)

local P = UIKit.Palette
local F = UIKit.Fonts
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RaceController = {}

local ctx
local state -- ReplicatedStorage.RaceState
local ui = {}
local joinedRaceId = nil

-- current race (everyone draws the runners; only racers get the race HUD)
local race = nil -- { raceId, laps, runners = { {id,name,lane,model,root,npc,userId} }, me = index or nil }
local prog = {} -- [i] = { prev, cur }
local tickAt, tickGap = 0, 1 / Race.TickRate
local renderConn = nil
local charges = Race.Boost.Charges
local chargeClock = 0
local lastPlace = 0
local lastBurst = 0
local stretchShown = false
local finishedShown = false
local fovKickUntil = 0

local function now()
	return workspace:GetServerTimeNow()
end

-- Runner models may stream in after the race starts: find them lazily
local function resolveRoot(r)
	if r.root and r.root.Parent then
		return r.root
	end
	local model = r.model
	if not (model and model.Parent) then
		if r.npc then
			local runtime = workspace:FindFirstChild("Runtime")
			model = runtime and runtime:FindFirstChild(r.modelName or "")
		else
			local p = r.userId and Players:GetPlayerByUserId(r.userId)
			model = p and p.Character
		end
		r.model = model
	end
	r.root = model and model:FindFirstChild("HumanoidRootPart")
	return r.root
end

----------------------------------------------------------------------------
-- UI
----------------------------------------------------------------------------
local function buildUI()
	local canvas = ctx.Hud.canvas

	-- big centre text: 3 / 2 / 1 / GO! / FINAL STRETCH
	ui.center = UIKit.text({
		Name = "RaceCenter",
		Text = "",
		TextSize = 96,
		Color = P.White,
		StrokeColor = P.DeepBlue,
		StrokeThickness = 4,
		StrokeTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(600, 110),
		ZIndex = 8,
		Parent = canvas,
	})
	ui.center.Visible = false
	ui.centerScale = UIKit.make("UIScale", { Parent = ui.center })

	-- position bar (top centre)
	local bar = UIKit.panel({
		Name = "PositionBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(470, 58),
		Accent = false,
		Parent = canvas,
	})
	bar.Visible = false
	ui.bar = bar
	ui.raceName = UIKit.text({
		Text = "LAP RACE",
		TextSize = 14,
		Color = P.BrightBlue,
		XAlign = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(14, 2),
		Size = UDim2.fromOffset(200, 18),
		Parent = bar,
	})
	local line = UIKit.make("Frame", {
		Name = "Line",
		BackgroundColor3 = P.Graphite,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 22, 0, 36),
		Size = UDim2.new(1, -72, 0, 6),
		Parent = bar,
	})
	UIKit.corner(line, UDim.new(0.5, 0))
	ui.line = line
	-- gold finish post
	local post = UIKit.make("Frame", {
		BackgroundColor3 = P.Gold,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(5, 22),
		Parent = line,
	})
	UIKit.corner(post, 2)
	ui.placeTag = UIKit.text({
		Name = "Place",
		Text = "1ST",
		TextSize = 24,
		Color = P.Gold,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0, 33),
		Size = UDim2.fromOffset(48, 30),
		Parent = bar,
	})
	ui.markers = {}

	-- BOOST button (bottom right) with 3 charge pips
	local boost = UIKit.make("TextButton", {
		Name = "Boost",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = P.White,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -22, 1, -22),
		Size = UDim2.fromOffset(118, 118),
		Visible = false,
		Parent = canvas,
	})
	UIKit.corner(boost, UDim.new(0.5, 0))
	UIKit.gradient(boost, P.BrightBlue, P.DeepBlue, 120)
	UIKit.stroke(boost, P.White, 3, 0.25)
	UIKit.text({ Text = "BOOST", TextSize = 26, StrokeColor = P.DeepBlue, StrokeTransparency = 0, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 30), Parent = boost })
	ui.boostScale = UIKit.make("UIScale", { Parent = boost })
	ui.pips = {}
	for i = 1, Race.Boost.Charges do
		local pip = UIKit.make("Frame", {
			BackgroundColor3 = P.Gold,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, (i - 2) * 20, 0, 82),
			Size = UDim2.fromOffset(14, 14),
			Parent = boost,
		})
		UIKit.corner(pip, UDim.new(0.5, 0))
		UIKit.stroke(pip, P.SpeedBlack, 1.5, 0.3)
		ui.pips[i] = pip
	end
	ui.boost = boost

	-- results card
	local card = UIKit.panel({
		Name = "Results",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 300),
		AccentColor = P.Gold,
		ZIndex = 10,
		Parent = canvas,
	})
	card.Visible = false
	ui.card = card
	ui.cardScale = UIKit.make("UIScale", { Parent = card })
	ui.cardTitle = UIKit.text({ Text = "RACE RESULTS", TextSize = 16, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 12), Size = UDim2.new(1, 0, 0, 20), ZIndex = 11, Parent = card })
	ui.cardPlace = UIKit.text({ Text = "1ST", TextSize = 64, Color = P.Gold, StrokeColor = P.SpeedBlack, StrokeTransparency = 0, Position = UDim2.fromOffset(120, 30), Size = UDim2.fromOffset(200, 72), ZIndex = 11, Parent = card })
	ui.medalSlot = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 34), Size = UDim2.fromOffset(60, 78), ZIndex = 11, Parent = card })
	ui.cardTime = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 16, Color = P.White, Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 20), ZIndex = 11, Parent = card })
	local coinRow = UIKit.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 124), Size = UDim2.fromOffset(220, 40), ZIndex = 11, Parent = card })
	local ci = UIKit.coinIcon(32, coinRow)
	ci.Position = UDim2.fromOffset(20, 4)
	ui.cardCoins = UIKit.text({ Text = "+0", TextSize = 32, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(62, 0), Size = UDim2.fromOffset(160, 40), ZIndex = 11, Parent = coinRow })
	ui.cardBonus = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 14, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 164), Size = UDim2.new(1, 0, 0, 18), ZIndex = 11, Parent = card })
	ui.rows = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(40, 186), Size = UDim2.new(1, -80, 0, 66), ZIndex = 11, Parent = card })
	UIKit.make("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 20), CellPadding = UDim2.fromOffset(12, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ui.rows })
	local cont = UIKit.button({
		Style = "Blue",
		Text = "CONTINUE",
		TextSize = 20,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(180, 46),
		ZIndex = 12,
		OnClick = function()
			RaceController.hideResults()
		end,
		Parent = card,
	})
	ui.pbBanner = UIKit.text({ Text = "NEW PB!", TextSize = 22, Color = P.SpeedBlack, Stroke = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -60, 0, 44), Size = UDim2.fromOffset(110, 30), ZIndex = 13, Parent = card })
	ui.pbBanner.BackgroundTransparency = 0
	ui.pbBanner.BackgroundColor3 = P.Gold
	ui.pbBanner.Rotation = 10
	UIKit.corner(ui.pbBanner, 6)
	ui.continue = cont

	-- confetti (pooled UI pieces, only for a win)
	ui.confetti = {}
	local layer = UIKit.make("Frame", { Name = "Confetti", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9, Parent = canvas })
	local colors = { P.Gold, P.ElectricBlue, P.White, P.BrightBlue, P.DeepGold }
	for i = 1, 36 do
		local c = UIKit.make("Frame", {
			BackgroundColor3 = colors[(i - 1) % #colors + 1],
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(8, 14),
			Visible = false,
			ZIndex = 9,
			Parent = layer,
		})
		ui.confetti[i] = c
	end
end

local function marker(runner, isMe)
	local size = if isMe then 30 else 24
	local m = UIKit.make("Frame", {
		Name = runner.id,
		BackgroundColor3 = if runner.npc then P.Graphite else P.ElectricBlue,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(size, size),
		ZIndex = if isMe then 4 else 3,
		Parent = ui.line,
	})
	UIKit.corner(m, UDim.new(0.5, 0))
	UIKit.stroke(m, if isMe then P.Gold else P.White, if isMe then 3 else 1.5, if isMe then 0 else 0.3)
	if runner.userId and runner.userId > 0 then
		local img = UIKit.make("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48"):format(runner.userId),
			ZIndex = m.ZIndex,
			Parent = m,
		})
		UIKit.corner(img, UDim.new(0.5, 0))
	else
		UIKit.text({ Text = string.sub(runner.name, 1, 1), TextSize = 14, Stroke = false, ZIndex = m.ZIndex, Parent = m })
	end
	return m
end

----------------------------------------------------------------------------
-- Moments
----------------------------------------------------------------------------
local function showCenter(text, color, hold)
	ui.center.Text = text
	ui.center.TextColor3 = color or P.White
	ui.center.TextTransparency = 0
	ui.center.Visible = true
	ui.centerScale.Scale = 1.6
	UIKit.tween(ui.centerScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	local token = {}
	ui.centerToken = token
	task.delay(hold or 0.8, function()
		if ui.centerToken == token then
			UIKit.tween(ui.center, 0.2, { TextTransparency = 1 })
			task.wait(0.2)
			if ui.centerToken == token then
				ui.center.Visible = false
			end
		end
	end)
end

local function confetti()
	local w = ctx.Hud.canvas.Size.X.Offset
	local h = ctx.Hud.canvas.Size.Y.Offset
	for _, c in ui.confetti do
		local x = math.random(0, w)
		c.Position = UDim2.fromOffset(x, -20)
		c.Rotation = math.random(0, 180)
		c.BackgroundTransparency = 0
		c.Visible = true
		local t = 1.4 + math.random() * 1.2
		UIKit.tween(c, t, { Position = UDim2.fromOffset(x + math.random(-80, 80), h + 20), Rotation = c.Rotation + math.random(180, 540) }, Enum.EasingStyle.Linear)
		task.delay(t, function()
			c.Visible = false
		end)
	end
end

local function updatePips()
	for i, pip in ui.pips do
		pip.BackgroundColor3 = if i <= charges then P.Gold else P.Graphite
	end
end

local function boost()
	if not race or not race.me or state:GetAttribute("Phase") ~= "Running" then
		return
	end
	local mine = prog[race.me]
	if mine and mine.cur >= 1 then
		return
	end
	ui.boostScale.Scale = 0.9
	UIKit.tween(ui.boostScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
	if charges <= 0 then
		ctx.Sound.play("BoostEmpty")
		return
	end
	if charges == Race.Boost.Charges then
		chargeClock = os.clock()
	end
	charges -= 1
	updatePips()
	ctx.Sound.play("Boost")
	fovKickUntil = os.clock() + Race.Boost.Seconds
	ctx.Net.get("RaceBoost"):FireServer()
end

----------------------------------------------------------------------------
-- Drawing runners
----------------------------------------------------------------------------
local function render()
	if not race then
		return
	end
	local alpha = math.clamp((os.clock() - tickAt) / tickGap, 0, 1.5)
	local order = {}
	for i, r in race.runners do
		local p = prog[i]
		local root = resolveRoot(r)
		if p and root then
			local v = math.min(1, p.cur + (p.cur - p.prev) * alpha)
			if p.cur >= 1 then
				v = 1
			end
			p.shown = v
			root.CFrame = TrackPath.runnerCFrame(r.lane, v, race.laps)
			table.insert(order, i)
		end
	end
	if not race.me then
		return
	end

	-- local charge refill (server confirms on each boost)
	if charges < Race.Boost.Charges and os.clock() - chargeClock >= Race.Boost.RefillSeconds then
		charges += 1
		chargeClock = os.clock()
		updatePips()
	end

	-- position bar + place
	table.sort(order, function(a, b)
		return (prog[a].shown or 0) > (prog[b].shown or 0)
	end)
	local place = table.find(order, race.me) or 1
	for i, r in race.runners do
		local m = ui.markers[i]
		local p = prog[i]
		if m and p then
			m.Position = UDim2.new(math.clamp(p.shown or 0, 0, 1), 0, 0.5, 0)
		end
	end
	ui.placeTag.Text = Format.place(place)
	ui.placeTag.TextColor3 = if place == 1 then P.Gold else P.White
	if lastPlace ~= 0 and place ~= lastPlace and os.clock() - lastBurst > 1.2 then
		lastBurst = os.clock()
		ctx.Sound.play("CrowdBurst")
	end
	lastPlace = place

	local mine = prog[race.me]
	local myShown = mine and mine.shown or 0
	if not stretchShown and myShown >= Race.FinalStretch then
		stretchShown = true
		showCenter("FINAL STRETCH", P.Gold, 1.0)
		ctx.Sound.play("FinalStretch")
	end
	if not finishedShown and myShown >= 1 then
		finishedShown = true
		showCenter("FINISH!", P.Gold, 1.2)
		ui.boost.Visible = false
	end

	-- camera: low side-follow, FOV kick on boost
	local me = race.runners[race.me]
	if me.root and me.root.Parent then
		local cf = me.root.CFrame
		local pos = cf.Position - cf.LookVector * 9 + cf.RightVector * 3 + Vector3.new(0, 4.5, 0)
		local target = cf.Position + cf.LookVector * 9 + Vector3.new(0, 0.5, 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(pos, target), 0.25)
		local fov = if os.clock() < fovKickUntil then 84 else 72
		camera.FieldOfView += (fov - camera.FieldOfView) * 0.15
	end
end

local function clearMarkers()
	for _, m in ui.markers do
		m:Destroy()
	end
	table.clear(ui.markers)
end

local function onStart(info)
	race = {
		raceId = info.raceId,
		laps = info.laps,
		runners = {},
		me = nil,
	}
	table.clear(prog)
	for i, r in info.runners do
		race.runners[i] = { id = r.id, name = r.name, lane = r.lane, model = r.model, modelName = r.modelName, npc = r.npc, userId = r.userId }
		prog[i] = { prev = 0, cur = 0, shown = 0 }
		if r.userId == player.UserId then
			race.me = i
		end
	end
	tickAt = os.clock()
	if not renderConn then
		RunService:BindToRenderStep("SpeedArcRace", Enum.RenderPriority.Camera.Value + 1, render)
		renderConn = true
	end

	if race.me then
		ctx.Hud.setRaceMode(true)
		ctx.Training.setControls(false)
		camera.CameraType = Enum.CameraType.Scriptable
		ui.raceName.Text = info.name
		clearMarkers()
		for i, r in race.runners do
			ui.markers[i] = marker(r, i == race.me)
		end
		ui.bar.Visible = true
		ui.boost.Visible = true
		charges = Race.Boost.Charges
		updatePips()
		lastPlace = 0
		stretchShown = false
		finishedShown = false
		ctx.Sound.stop("CrowdMurmur")
	end
end

local function endRace()
	if renderConn then
		RunService:UnbindFromRenderStep("SpeedArcRace")
		renderConn = nil
	end
	local wasRacing = race and race.me
	race = nil
	table.clear(prog)
	if wasRacing then
		ui.bar.Visible = false
		ui.boost.Visible = false
		clearMarkers()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		ctx.Hud.setRaceMode(false)
		if not ctx.Training.isTraining() then
			ctx.Training.setControls(true)
		end
	end
end

function RaceController.hideResults()
	if not ui.card.Visible then
		return
	end
	UIKit.tween(ui.cardScale, 0.15, { Scale = 0.85 })
	task.delay(0.15, function()
		ui.card.Visible = false
	end)
end

local function onResults(info)
	ui.cardPlace.Text = Format.place(info.place)
	ui.cardPlace.TextColor3 = if info.place == 1 then P.Gold elseif info.place <= 3 then P.White else P.BrightBlue
	ui.cardTitle.Text = ("RACE RESULTS  -  %s OF %d"):format(Format.place(info.place), info.total)
	for _, c in ui.medalSlot:GetChildren() do
		c:Destroy()
	end
	if info.medal then
		UIKit.medalIcon(info.medal, 56, ui.medalSlot, info.place)
	else
		local ri = UIKit.speedIcon(48, ui.medalSlot)
		ri.Position = UDim2.fromOffset(4, 16)
	end
	ui.cardTime.Text = if info.time then ("Time  %s"):format(Format.seconds(info.time)) else "Time's up! Placed by distance"
	ui.cardBonus.Text = if info.firstOfDay then "First race of the day: +50% coins" else ""
	ui.pbBanner.Visible = info.pb == true
	for _, c in ui.rows:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	for place, row in info.rows do
		if place > 8 then
			break
		end
		local isMe = row.id == info.youId
		local label = UIKit.text({
			Text = ("%s  %s%s"):format(Format.place(place), row.name, if row.time then "  " .. string.format("%.1f", row.time) else ""),
			Font = if isMe then F.BodyBold else F.Body,
			TextSize = 14,
			Color = if isMe then P.Gold else P.White,
			XAlign = Enum.TextXAlignment.Left,
			ZIndex = 11,
			Parent = ui.rows,
		})
		label.LayoutOrder = (place - 1) % 4 * 2 + (if place > 4 then 1 else 0)
	end

	ui.cardCoins.Text = "+0"
	ui.card.Visible = true
	ui.cardScale.Scale = 0.6
	UIKit.tween(ui.cardScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	-- sounds scale with the place
	if info.place == 1 then
		ctx.Sound.play("Fanfare")
		ctx.Sound.play("FinishCheer")
		confetti()
	elseif info.place <= 3 then
		ctx.Sound.play("Fanfare", { Volume = 0.6, Pitch = 0.94 })
		ctx.Sound.play("FinishCheer", { Volume = 0.6 })
	else
		ctx.Sound.play("FinishCheer", { Volume = 0.35 })
	end

	-- coins tick up
	task.delay(0.45, function()
		ctx.Sound.play("Coins")
		local nv = Instance.new("NumberValue")
		nv.Changed:Connect(function(v)
			ui.cardCoins.Text = "+" .. Format.short(v)
		end)
		local t = UIKit.tween(nv, 0.9, { Value = info.coins })
		t.Completed:Once(function()
			ui.cardCoins.Text = "+" .. Format.short(info.coins)
			nv:Destroy()
		end)
	end)

	local shownFor = info.raceId
	task.delay(Race.ResultsSeconds + 1, function()
		if ui.card.Visible and shownFor == info.raceId then
			RaceController.hideResults()
		end
	end)
end

----------------------------------------------------------------------------
-- Join pill / timers
----------------------------------------------------------------------------
local function updatePill()
	local refs = ctx.Hud.refs
	local phase = state:GetAttribute("Phase")
	local left = (state:GetAttribute("EndsAt") or 0) - now()
	local id = state:GetAttribute("RaceId")

	if phase == "Join" then
		refs.raceLabel.Text = "JOIN NOW"
		refs.raceTime.Text = Format.clock(left)
		refs.raceTime.TextColor3 = if left <= 3 then P.DangerRed else P.Gold
		refs.join.Visible = true
		if joinedRaceId == id then
			refs.joinLabel.Text = ("JOINED!  %d"):format(math.max(0, math.ceil(left)))
		else
			refs.joinLabel.Text = ("JOIN RACE  %d"):format(math.max(0, math.ceil(left)))
		end
	else
		refs.join.Visible = false
		refs.raceTime.TextColor3 = P.Gold
		if phase == "Waiting" then
			refs.raceLabel.Text = "NEXT RACE"
			refs.raceTime.Text = Format.clock(left)
		else
			refs.raceLabel.Text = "RACE ON"
			refs.raceTime.Text = "LIVE"
		end
	end
end

local lastCount = nil
local function countdownTick()
	if not race or not race.me then
		return
	end
	local phase = state:GetAttribute("Phase")
	if phase == "Countdown" then
		local left = math.ceil((state:GetAttribute("EndsAt") or 0) - now())
		if left ~= lastCount and left >= 1 and left <= 3 then
			lastCount = left
			showCenter(tostring(left), P.White, 0.7)
			ctx.Sound.play("Beep", { Pitch = 1 })
		end
	end
end

----------------------------------------------------------------------------
function RaceController.start(c)
	ctx = c
	ctx.Race = RaceController
	state = ReplicatedStorage:WaitForChild("RaceState")
	buildUI()

	ctx.Hud.refs.join.Activated:Connect(function()
		if state:GetAttribute("Phase") == "Join" and joinedRaceId ~= state:GetAttribute("RaceId") then
			ctx.Net.get("RaceJoin"):FireServer()
		end
	end)

	ui.boost.Activated:Connect(boost)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not race or not race.me then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
			or (t == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space) then
			boost()
		end
	end)

	local RaceEvent = ctx.Net.get("RaceEvent")
	RaceEvent.OnClientEvent:Connect(function(kind, info)
		if kind == "joined" then
			joinedRaceId = info.raceId
			ctx.Hud.toast("You're in! Get ready...", "Gold")
			UIKit.setButtonStyle(ctx.Hud.refs.join, "Blue")
		elseif kind == "start" then
			onStart(info)
		elseif kind == "boost" then
			charges = info.charges
			updatePips()
		elseif kind == "results" then
			onResults(info)
		elseif kind == "return" then
			endRace() -- stop drawing runners first, or the next frame puts us back on the track
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = info.cframe
			end
		elseif kind == "ended" then
			endRace()
		end
	end)

	ctx.Net.get("RaceTick").OnClientEvent:Connect(function(raceId, packed)
		if not race or race.raceId ~= raceId then
			return
		end
		local t = os.clock()
		tickGap = math.clamp(t - tickAt, 0.05, 0.3)
		tickAt = t
		for i, v in packed do
			local p = prog[i]
			if p then
				p.prev = p.shown or p.cur
				p.cur = v
			end
		end
	end)

	state:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = state:GetAttribute("Phase")
		if phase == "Join" then
			UIKit.setButtonStyle(ctx.Hud.refs.join, "Gold")
			if not race then
				ctx.Hud.toast("A RACE IS STARTING!  Tap JOIN", "Gold")
			end
		elseif phase == "Running" and race and race.me then
			lastCount = nil
			showCenter("GO!", P.Gold, 0.8)
			ctx.Sound.play("StartGun")
		end
	end)

	-- pill text + countdown checks a few times a second (cheap)
	task.spawn(function()
		while true do
			updatePill()
			countdownTick()
			task.wait(0.1)
		end
	end)

	-- the gold JOIN button gently pulses while it's open
	task.spawn(function()
		local scale = UIKit.make("UIScale", { Parent = ctx.Hud.refs.join.Face })
		while true do
			if ctx.Hud.refs.join.Visible and joinedRaceId ~= state:GetAttribute("RaceId") then
				UIKit.tween(scale, 0.4, { Scale = 1.06 }, Enum.EasingStyle.Sine)
				task.wait(0.4)
				UIKit.tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Sine)
				task.wait(0.4)
			else
				scale.Scale = 1
				task.wait(0.25)
			end
		end
	end)
end

return RaceController
