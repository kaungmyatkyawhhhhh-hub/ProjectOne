-- TutorialController (M4, GDD 21): draws the first 15 minutes. The server owns the step (attribute
-- "Tut"); this shows Coach Benji's hint card (bottom centre, above the TAP hint), a gold path on the
-- floor + a GO HERE marker, the GO TO buttons and the one big BOOST prompt in the tutorial race.
-- Rules (lessons): a hint never vanishes while its step is open (it comes back every 12 s if hidden),
-- it hides while a window or a race covers it, nothing else pops over it, and every step has a
-- safety timeout that only counts while the step is possible.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)
local Retention = require(Shared.Config.Retention)
local Coaches = require(Shared.Config.Coaches)
local Ranks = require(Shared.Config.Ranks)
local Shoes = require(Shared.Config.Shoes)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer
local T = Retention.Tutorial
local S = { Welcome = 1, FirstStep = 2, FirstWall = 3, Race = 4, Podium = 5, Shoes = 6, Silver = 7, Roll = 8, Done = 99 }

local Tutorial = {}
local ctx
local card, cardText, cardSub, cardBtn, cardBtnLabel, cardScale
local goTrain
local boostCallout
local pathFolder, marker
local step = 0
local stepStarted = 0 -- seconds the current step has been possible
local timeoutsUsed = 0
local lastPulse = 0
local inTutorialRace = false
local resultsAt = nil

local function benji()
	for _, c in Coaches.List do
		if c.Id == "Benji" then
			return c
		end
	end
	return Coaches.List[1]
end

local function shoePrice(id)
	for _, s in Shoes.List do
		if s.Id == id then
			return s.Price
		end
	end
	return 0
end

----------------------------------------------------------------------------
-- UI
----------------------------------------------------------------------------
local function buildCard(canvas)
	card = UIKit.panel({ Name = "TutorialCard", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -82), Size = UDim2.fromOffset(376, 78), AccentColor = P.Gold, StrokeColor = P.Gold, StrokeThickness = 2, ZIndex = 12, Parent = canvas })
	card.Visible = false
	cardScale = make("UIScale", { Parent = card })
	local face = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 9), Size = UDim2.fromOffset(60, 60), ZIndex = 13, Parent = card })
	pcall(Art.portrait, benji(), 60, face, false)
	cardText = UIKit.text({ Text = "", TextSize = 17, Wrapped = true, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(84, 8), Size = UDim2.new(1, -96, 0, 40), ZIndex = 13, Parent = card })
	cardSub = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 13, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(84, 50), Size = UDim2.new(1, -96, 0, 20), ZIndex = 13, Parent = card })
	cardBtn, cardBtnLabel = UIKit.button({ Name = "GoTo", Style = "Green", Text = "GO TO", TextSize = 17, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(104, 46), ZIndex = 14, Parent = card })
	cardBtn.Visible = false

	-- after the tutorial: a TO START button (bottom centre, back to the wall course) whenever you're not training or racing
	goTrain = UIKit.button({ Name = "GoTrain", Style = "Green", Text = "TO START", TextSize = 18, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(150, 46), Parent = canvas })
	goTrain.Visible = false
	goTrain.Activated:Connect(function()
		local ok, why = ctx.Net.call("GoTo", "Course") -- 28 Oct pivot: back to the start of the wall course
		if not ok and why == "full" then
			ctx.Hud.toast("Every spot is busy. Try again in a moment!", "Denied")
		end
	end)

	-- the one big BOOST prompt in the tutorial race (over the BOOST button, bottom right)
	boostCallout = UIKit.panel({ Name = "BoostCallout", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -130), Size = UDim2.fromOffset(230, 64), AccentColor = P.Gold, StrokeColor = P.Gold, StrokeThickness = 3, ZIndex = 30, Parent = canvas })
	boostCallout.Visible = false
	UIKit.text({ Text = "HIT BOOST!", TextSize = 26, Color = P.Gold, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 32), ZIndex = 31, Parent = boostCallout })
	UIKit.text({ Text = "a burst of speed - use it!", Font = F.BodyBold, TextSize = 13, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 20), ZIndex = 31, Parent = boostCallout })
	make("UIScale", { Name = "Pulse", Parent = boostCallout })
end

local buttonAction = nil
-- corner = a small card top right under the NEXT RACE pill (the race card, prompt 11), else bottom centre
local function showCard(text, sub, btnText, action, corner)
	if corner then
		card.AnchorPoint = Vector2.new(1, 0)
		card.Position = UDim2.new(1, -14, 0, 142) -- under the DAILY row and clear of the wall strip
		card.Size = UDim2.fromOffset(300, 74)
	else
		card.AnchorPoint = Vector2.new(0.5, 1)
		card.Position = UDim2.new(0.5, 0, 1, -82)
		card.Size = UDim2.fromOffset(376, 78)
	end
	cardText.Text = text
	cardSub.Text = sub or ""
	buttonAction = action
	cardBtn.Visible = btnText ~= nil
	if btnText then
		cardBtnLabel.Text = btnText
	end
	cardText.Size = UDim2.new(1, if btnText then -206 else -96, 0, 40)
	cardSub.Size = UDim2.new(1, if btnText then -206 else -96, 0, 20)
	if not card.Visible then
		card.Visible = true
		cardScale.Scale = 0.6
		UIKit.tween(cardScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		ctx.Sound.play("Toast")
	end
end

local function hideCard()
	card.Visible = false
end

----------------------------------------------------------------------------
-- the gold path + GO HERE marker (local parts only)
----------------------------------------------------------------------------
local function clearPath()
	if pathFolder then
		pathFolder:Destroy()
		pathFolder = nil
	end
	if marker then
		marker:Destroy()
		marker = nil
	end
end

local targets = nil -- [name] = Vector3 from the server (parts far away may not be streamed in)
local anchors = {}
local function targetPart(which)
	if not targets then
		return nil
	end
	local pos = targets[which]
	if not pos then
		return nil
	end
	local a = anchors[which]
	if not a or not a.Parent then
		a = make("Part", { Name = "Target_" .. which, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(1, 1, 1), Position = pos, Parent = workspace.CurrentCamera })
		anchors[which] = a
	end
	return a
end

local function drawPath(target)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not target then
		clearPath()
		return
	end
	if not marker or marker.Adornee ~= target then
		if marker then
			marker:Destroy()
		end
		marker = make("BillboardGui", { Name = "GoHere", Adornee = target, Size = UDim2.fromOffset(120, 70), StudsOffset = Vector3.new(0, 5, 0), AlwaysOnTop = false, LightInfluence = 0, MaxDistance = 400, Parent = target })
		local tip = make("Frame", { BackgroundColor3 = P.Gold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(60, 38), Size = UDim2.fromOffset(18, 18), Rotation = 45, Parent = marker })
		UIKit.stroke(tip, P.Navy, 3)
		local pill = UIKit.pill({ Kind = "gold", Size = UDim2.fromOffset(120, 36), ZIndex = 2, Parent = marker })
		UIKit.text({ Text = "GO HERE", TextSize = 18, Color = P.Navy, Stroke = false, ZIndex = 3, Parent = pill })
		task.spawn(function()
			local m = marker
			while m and m.Parent do
				UIKit.tween(m, 0.5, { StudsOffset = Vector3.new(0, 6, 0) }, Enum.EasingStyle.Sine)
				task.wait(0.5)
				UIKit.tween(m, 0.5, { StudsOffset = Vector3.new(0, 5, 0) }, Enum.EasingStyle.Sine)
				task.wait(0.5)
			end
		end)
	end
	if not pathFolder then
		pathFolder = make("Folder", { Name = "TutorialPath", Parent = workspace.CurrentCamera })
		for i = 1, 24 do
			make("Part", { Name = "Dot", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = P.Gold, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.1, 1.1), Transparency = 1, Parent = pathFolder })
		end
	end
	local a = root.Position - Vector3.new(0, 2.9, 0)
	local b = Vector3.new(target.Position.X, a.Y, target.Position.Z)
	local dist = (b - a).Magnitude
	local dots = pathFolder:GetChildren()
	local spacing = math.max(2.5, dist / #dots)
	local phase = (os.clock() * 6) % spacing
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, pathFolder }
	for i, dot in dots do
		local d = phase + (i - 1) * spacing
		if d < dist - 1.5 then
			local pos = a:Lerp(b, d / dist)
			-- sit on whatever floor is there (plaza tiles, track, grass)
			local hit = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -10, 0), params)
			local y = if hit then hit.Position.Y else a.Y
			dot.CFrame = CFrame.new(pos.X, y + 0.08, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
			dot.Transparency = 0.15
		else
			dot.Transparency = 1
		end
	end
end

----------------------------------------------------------------------------
-- step logic
----------------------------------------------------------------------------
local function busyCover()
	-- things that cover the card: a window, a race, the coach reveal, the Go Pro scene
	if player:GetAttribute("InRace") then
		return true
	end
	if (ctx.Locker and ctx.Locker.isOpen and ctx.Locker.isOpen()) then
		return true
	end
	local canvas = ctx.Hud.canvas
	for _, ch in canvas:GetChildren() do
		if (ch.Name:match("Backdrop$") or ch.Name == "CoachReveal" or ch.Name == "GoProScene") and ch.Visible then
			return true
		end
	end
	return false
end

local function advance(from)
	task.spawn(function()
		ctx.Net.call("Tutorial", "advance", from)
	end)
end

local function goTo(where, after)
	task.spawn(function()
		local ok = ctx.Net.call("GoTo", where)
		if ok and after then
			task.wait(0.3)
			after()
		end
	end)
end

local function openShop()
	ctx.Locker.open("SHOES")
	task.delay(0.2, function()
		ctx.Locker.highlight(T.ShoeId)
	end)
end

local function openCoaches()
	ctx.Coaches.open("ROLL")
end

local function firstWallNeed()
	return Formulas.wallNeed(player:GetAttribute("League") or 1, 1)
end

local function silverMph()
	local league = player:GetAttribute("League") or 1
	return Ranks.Thresholds[league][2]
end

local function safety()
	-- first the GO TO is done for the player, then the step moves on (never stuck)
	timeoutsUsed += 1
	if timeoutsUsed == 1 then
		if step == S.FirstStep or step == S.FirstWall then
			goTo("Course")
		elseif step == S.Race then
			task.spawn(ctx.Net.call, "Tutorial", "race")
		elseif step == S.Shoes then
			goTo("ShoeShop", openShop)
		elseif step == S.Silver then
			goTo("Train")
		elseif step == S.Roll then
			goTo("CoachCorner", openCoaches)
		elseif step == S.Welcome or step == S.Podium then
			advance(step)
		end
	elseif step == S.Welcome or step == S.Podium then
		advance(step)
	else
		task.spawn(ctx.Net.call, "Tutorial", "skip", step)
	end
end

local function render(dt)
	local training = ctx.Training.isTraining()
	local cover = busyCover()
	local possible = not cover and player.Character ~= nil
	if possible then
		stepStarted += dt
	end
	local limit = T.StepTimeouts[step]
	if limit and stepStarted > limit * (timeoutsUsed + 1) then
		safety()
	end

	-- after the tutorial
	goTrain.Visible = step >= S.Done and not training and not player:GetAttribute("InRace") and not cover

	if step <= 0 or step >= S.Done or cover then
		hideCard()
		if step >= S.Done or step <= 0 then
			clearPath()
		end
		return
	end

	local target = nil
	if step == S.Welcome then
		showCard("Every step = +1 SPEED. Let's go!", "NEW RUNNER BOOST: 2x SPEED for 15 min!", nil)
	elseif step == S.FirstStep then
		showCard("Walk! Every step gives you SPEED.", "Use the stick (or W A S D) to run.", nil)
	elseif step == S.FirstWall then
		-- 28 Oct pivot: this step is "smash the first wall"
		target = targetPart("Course")
		showCard("Smash the first wall!", ("Walls need SPEED. Wall 1 needs %s."):format(Format.short(firstWallNeed())), "GO TO", function()
			goTo("Course")
		end)
	elseif step == S.Race then
		if stepStarted < T.RaceAfterSeconds and training then
			hideCard()
		else
			showCard("A RACE IS STARTING!", "Beat the other runners!", "RACE!", function()
				task.spawn(ctx.Net.call, "Tutorial", "race")
			end, true)
		end
	elseif step == S.Podium then
		showCard("GOLD MEDAL! You won your first race!", "Now let's get you some real shoes.", nil)
	elseif step == S.Shoes then
		target = targetPart("ShoeShop")
		showCard("Buy your first shoes!", ("%s coins - you have enough!"):format(Format.short(shoePrice(T.ShoeId))), "GO TO", function()
			goTo("ShoeShop", openShop)
		end)
	elseif step == S.Silver then
		if training then
			hideCard() -- the goal line on top says how far to Silver
		else
			showCard(("Run to %s SPEED for SILVER rank!"):format(Format.short(silverMph())), "Smash walls on the way. Silver gives a free coach roll.", "GO RUN", function()
				goTo("Course")
			end)
		end
	elseif step == S.Roll then
		target = targetPart("CoachCorner")
		showCard("SILVER! Here's a FREE coach roll!", "Coaches make you train faster.", "GO TO", function()
			goTo("CoachCorner", openCoaches)
		end)
	end
	if target then
		drawPath(target)
	else
		clearPath()
	end
	-- the hint comes back to your attention every 12 s
	if card.Visible and os.clock() - lastPulse > T.HintRepeat then
		lastPulse = os.clock()
		cardScale.Scale = 1.08
		UIKit.tween(cardScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	end
end

local function onStep(n)
	if n == step then
		return
	end
	step = n
	stepStarted = 0
	timeoutsUsed = 0
	lastPulse = os.clock()
	if n == S.Welcome then
		ctx.Sound.play("Unlock")
		task.delay(3.5, function()
			if step == S.Welcome then
				advance(S.Welcome)
			end
		end)
	elseif n == S.Podium then
		task.delay(4, function()
			if step == S.Podium then
				advance(S.Podium)
			end
		end)
	elseif n == S.Roll or n == S.Done then
		hideCard()
	end
end

function Tutorial.active()
	return step > 0 and step < S.Done
end

-- other popups wait while a hint card is up (lesson: nothing piles on top of a hint)
function Tutorial.hintShowing()
	return card ~= nil and card.Visible
end

function Tutorial.start(c)
	ctx = c
	ctx.Tutorial = Tutorial
	buildCard(ctx.Hud.canvas)
	cardBtn.Activated:Connect(function()
		if buttonAction then
			buttonAction()
		end
	end)

	task.spawn(function()
		local ok, t = ctx.Net.call("TutorialTargets")
		if ok then
			targets = t
		end
	end)
	ctx.Net.get("Tutorial").OnClientEvent:Connect(onStep)
	player:GetAttributeChangedSignal("Tut"):Connect(function()
		onStep(player:GetAttribute("Tut") or 0)
	end)
	onStep(player:GetAttribute("Tut") or 0)

	-- FIRST STEP!
	ctx.Net.get("Moment").OnClientEvent:Connect(function(kind, info)
		if kind == "FirstStep" then
			ctx.Hud.popup("FIRST STEP!", P.Gold)
			task.delay(0.35, function()
				ctx.Hud.popup(("+%d coins  +%d SPEED"):format(info.Coins, info.Speed), P.White)
			end)
			ctx.Sound.play("Unlock")
		end
	end)

	-- the tutorial race: the one BOOST prompt until the first boost
	ctx.Race.onMyStart = function(info)
		inTutorialRace = info.kind == "tutorial"
		if inTutorialRace then
			task.delay(4.2, function()
				if inTutorialRace then
					boostCallout.Visible = true
				end
			end)
		end
	end
	ctx.Net.get("RaceEvent").OnClientEvent:Connect(function(kind, info)
		if kind == "boost" and info.ok then
			boostCallout.Visible = false
		elseif kind == "results" or kind == "ended" or kind == "return" then
			boostCallout.Visible = false
			inTutorialRace = false
		end
	end)
	task.spawn(function()
		while true do
			if boostCallout.Visible then
				UIKit.tween(boostCallout.Pulse, 0.3, { Scale = 1.1 }, Enum.EasingStyle.Sine)
				task.wait(0.3)
				UIKit.tween(boostCallout.Pulse, 0.3, { Scale = 1 }, Enum.EasingStyle.Sine)
				task.wait(0.3)
			else
				task.wait(0.2)
			end
		end
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		local d = acc
		acc = 0
		if step < 0 then
			return -- waiting for the server to confirm a step
		end
		local ok, err = pcall(render, d)
		if not ok then
			warn("[Tutorial] " .. tostring(err))
		end
	end)
end

return Tutorial
