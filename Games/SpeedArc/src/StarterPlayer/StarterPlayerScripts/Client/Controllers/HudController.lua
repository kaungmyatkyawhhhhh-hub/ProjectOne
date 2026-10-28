-- HudController: the main HUD (GDD 22). Coins top left, SPEED big top centre with the goal line,
-- race timer pill + JOIN top right, one toast lane, pooled "+N" popups, the AFK machine bar bottom right.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)
local Stations = require(Shared.Config.Stations)
local Ranks = require(Shared.Config.Ranks)

local P = UIKit.Palette
local F = UIKit.Fonts
local player = Players.LocalPlayer

local Hud = {}

local canvas
local refs = {}
local popupPool = {}
local popupIndex = 1
local toastQueue = {}
local toastBusy = false
local shownSpeed = 0
local shownCoins = 0

----------------------------------------------------------------------------
-- Build
----------------------------------------------------------------------------
local function buildCoins()
	local pill = UIKit.pill({ Name = "Coins", Size = UDim2.fromOffset(172, 44), Position = UDim2.fromOffset(14, 10), Parent = canvas })
	local icon = UIKit.coinIcon(48, pill)
	icon.Position = UDim2.fromOffset(-8, -2)
	refs.coinsText = UIKit.text({
		Text = "0",
		TextSize = 24,
		Color = P.Gold,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -52, 1, 0),
		Position = UDim2.fromOffset(46, 0),
		Parent = pill,
	})
	refs.coinsScale = UIKit.make("UIScale", { Parent = pill })
	refs.coins = pill
	-- rank badge (league + rank) under the coins (next to them it hid behind the speed plate on phones)
	local rank = UIKit.pill({ Name = "Rank", Size = UDim2.fromOffset(150, 44), Position = UDim2.fromOffset(14, 60), Parent = canvas })
	local dot = UIKit.sprite("badge_white", { Name = "Dot", Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(40, 40), Parent = rank })
	refs.rankDot = dot
	refs.rankLetter = UIKit.text({ Text = "B", TextSize = 16, Color = P.SpeedBlack, Stroke = false, Parent = dot })
	refs.rankText = UIKit.text({ Text = "BRONZE", TextSize = 15, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 4), Size = UDim2.new(1, -46, 0, 20), Parent = rank })
	refs.leagueText = UIKit.text({ Text = "LEAGUE 1", Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 22), Size = UDim2.new(1, -46, 0, 16), Parent = rank })
	refs.rank = rank
end

local function buildSpeed()
	local block = UIKit.make("Frame", {
		Name = "Speed",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(320, 96),
		Parent = canvas,
	})
	refs.speedBlock = block
	-- dark plate behind the number: busy world text behind (stand screens) never mixes into it
	UIKit.panel({ Name = "Plate", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.new(1, 0, 0, 98), Parent = block })

	local row = UIKit.make("Frame", { Name = "Row", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 54), Parent = block })
	UIKit.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local icon = UIKit.speedIcon(40, row)
	icon.LayoutOrder = 1
	local num = UIKit.text({
		Name = "Number",
		Text = "0",
		TextSize = 46,
		Color = P.White,
		StrokeColor = P.Navy,
		StrokeThickness = 3,
		StrokeTransparency = 0,
		Size = UDim2.fromOffset(0, 54),
		Parent = row,
	})
	num.AutomaticSize = Enum.AutomaticSize.X
	num.LayoutOrder = 2
	refs.speedText = num
	refs.speedScale = UIKit.make("UIScale", { Parent = row })
	local unit = UIKit.text({
		Name = "Unit",
		Text = "SPEED",
		TextSize = 20,
		Color = P.BrightBlue,
		StrokeColor = P.SpeedBlack,
		Size = UDim2.fromOffset(46, 40),
		Parent = row,
	})
	unit.LayoutOrder = 3

	-- progress to the next station
	local _, fill = UIKit.bar({ Name = "Bar", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(256, 14), Parent = block })
	refs.barFill = fill

	refs.goalText = UIKit.text({
		Name = "Goal",
		Text = "",
		Font = F.BodyBold,
		TextSize = 16,
		Color = P.White,
		StrokeTransparency = 0.2,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.fromOffset(420, 20),
		RichText = true,
		Parent = block,
	})
end

local function buildRacePill()
	local holder = UIKit.make("Frame", {
		Name = "Race",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(196, 112),
		Parent = canvas,
	})
	local pill = UIKit.pill({ Name = "Timer", Size = UDim2.fromOffset(196, 44), Parent = holder })
	UIKit.icon("race", 38, pill, { Position = UDim2.fromOffset(4, 3) })
	refs.raceLabel = UIKit.text({
		Text = "NEXT RACE",
		Font = F.BodyBold,
		TextSize = 14,
		Color = P.White,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.fromOffset(44, 0),
		Parent = pill,
	})
	refs.raceTime = UIKit.text({
		Text = "0:00",
		TextSize = 22,
		Color = P.Gold,
		XAlign = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 70, 1, 0),
		Position = UDim2.new(1, -84, 0, 0),
		Parent = pill,
	})
	refs.racePill = pill

	local join, joinLabel = UIKit.button({
		Name = "Join",
		Style = "Gold",
		Text = "JOIN RACE",
		TextSize = 22,
		Size = UDim2.fromOffset(196, 58),
		Position = UDim2.fromOffset(0, 52),
		ClickSound = "Join",
	})
	join.Parent = holder
	join.Visible = false
	refs.join = join
	refs.joinLabel = joinLabel
	refs.raceHolder = holder
end

local function buildToast()
	local toast = UIKit.panel({
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 144), -- under the wall strip (prompt 11)
		Size = UDim2.fromOffset(360, 40),
		Accent = true,
		Parent = canvas,
	})
	toast.Visible = false
	toast.AutomaticSize = Enum.AutomaticSize.X
	toast.Size = UDim2.fromOffset(0, 40)
	UIKit.make("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 18), Parent = toast })
	toast.Accent.Position = UDim2.fromOffset(-16, 8) -- padding moves children; keep the accent on the edge
	refs.toast = toast
	refs.toastText = UIKit.text({
		Font = F.BodyBold,
		TextSize = 17,
		Size = UDim2.fromOffset(200, 40),
		Parent = toast,
	})
	refs.toastText.AutomaticSize = Enum.AutomaticSize.X
end

local function buildPopups()
	local layer = UIKit.make("Frame", { Name = "Popups", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = canvas })
	for i = 1, 16 do
		local label = UIKit.text({
			Name = "Popup" .. i,
			TextSize = 30,
			Color = P.White,
			StrokeColor = P.DeepBlue,
			StrokeThickness = 2.5,
			StrokeTransparency = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(160, 40),
			ZIndex = 5,
			Parent = layer,
		})
		label.Visible = false
		popupPool[i] = label
	end
end

local function buildTraining()
	local holder = UIKit.make("Frame", {
		Name = "Training",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -14),
		Size = UDim2.fromOffset(220, 150),
		Visible = false,
		Parent = canvas,
	})
	refs.training = holder

	local card = UIKit.panel({ Name = "Card", Size = UDim2.fromOffset(220, 86), Parent = holder })
	refs.stationName = UIKit.text({
		Text = "SPRINT LANE",
		TextSize = 18,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 24),
		Position = UDim2.fromOffset(18, 8),
		Parent = card,
	})
	refs.stationGain = UIKit.text({
		Text = "AFK STEPS",
		Font = F.BodyBold,
		TextSize = 14,
		Color = P.BrightBlue,
		XAlign = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 18),
		Position = UDim2.fromOffset(18, 31),
		Parent = card,
	})
	-- combo meter
	local _, fill = UIKit.bar({ Name = "Combo", Kind = "gold", Position = UDim2.fromOffset(18, 56), Size = UDim2.new(1, -94, 0, 14), Parent = card })
	refs.comboFill = fill
	refs.comboText = UIKit.text({
		Text = "x1.0",
		TextSize = 20,
		Color = P.Gold,
		XAlign = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 50),
		Size = UDim2.fromOffset(64, 26),
		Parent = card,
	})
	refs.comboScale = UIKit.make("UIScale", { Parent = refs.comboText })

	local stop = UIKit.button({
		Name = "Stop",
		Style = "Dark",
		Text = "STOP",
		TextSize = 20,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, 0),
		Size = UDim2.fromOffset(120, 50),
		ClickSound = "StationLeave",
		Parent = holder,
	})
	refs.stop = stop

	refs.hint = UIKit.text({
		Name = "Hint",
		Text = "STEPPING FOR YOU!",
		TextSize = 30,
		Color = P.White,
		StrokeColor = P.DeepBlue,
		StrokeThickness = 3,
		StrokeTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -34),
		Size = UDim2.fromOffset(460, 40),
		Parent = canvas,
	})
	refs.hint.Visible = false
	refs.hintScale = UIKit.make("UIScale", { Parent = refs.hint })
end

----------------------------------------------------------------------------
-- Updates
----------------------------------------------------------------------------
local function goalFor(speed)
	local league = player:GetAttribute("League") or 1
	local thresholds = Ranks.Thresholds[league] or Ranks.Thresholds[1]
	local rankIdx = math.max(player:GetAttribute("Rank") or 1, 1)
	local nextRankMin = thresholds[rankIdx + 1]
	local candidates = {}
	-- the next wall you haven't smashed yet (28 Oct pivot: the main goal)
	local best = player:GetAttribute("BestWall") or 0
	local hasCourse = Formulas.hasCourse(league)
	if hasCourse and best < Formulas.wallCount() then
		local need = Formulas.wallNeed(league, best + 1)
		local floor = if best > 0 then Formulas.wallNeed(league, best) else 0
		if speed < need then
			table.insert(candidates, { at = need, floor = floor, text = ('Reach <font color="#FFC83D">%s SPEED</font> to smash wall %d'):format(Format.short(need), best + 1) })
		else
			return ('<font color="#7ED957">SMASH WALL %d!</font>  Run down the course'):format(best + 1), 1
		end
	end
	if nextRankMin and nextRankMin > speed then
		table.insert(candidates, { at = nextRankMin, floor = thresholds[rankIdx] or 0, text = ('Reach <font color="#FFC83D">%s SPEED</font> for %s rank'):format(Format.short(nextRankMin), string.upper(Ranks.Names[rankIdx + 1])) })
	end
	table.sort(candidates, function(a, b)
		return a.at < b.at
	end)
	local c = candidates[1]
	if c then
		return c.text, (speed - c.floor) / math.max(1, c.at - c.floor)
	end
	-- the Go Pro goal
	if player:GetAttribute("GoProReady") then
		return '<font color="#FFC83D">GO PRO</font> is ready!', 1
	elseif league >= (player:GetAttribute("MaxLeague") or 3) then
		return 'Top league for now: win races for <font color="#FFC83D">coins</font>', 1
	end
	return ('Smash the <font color="#FFC83D">last wall</font> to GO PRO'), best / Formulas.wallCount()
end

local function renderRank()
	local name = player:GetAttribute("RankName") or "Bronze"
	local color = Ranks.Colors[name] or P.White
	refs.rankText.Text = string.upper(name)
	refs.rankText.TextColor3 = color
	refs.rankDot.ImageColor3 = color
	refs.rankLetter.Text = string.sub(name, 1, 1)
	refs.leagueText.Text = ("LEAGUE %d"):format(player:GetAttribute("League") or 1)
end

local function renderSpeed(v)
	refs.speedText.Text = Format.short(v)
	local text, frac = goalFor(v)
	refs.goalText.Text = text
	refs.barFill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
end

local function renderCoins(v)
	refs.coinsText.Text = Format.short(v)
end

local function animateNumber(fromV, toV, time, render)
	local nv = Instance.new("NumberValue")
	nv.Value = fromV
	nv.Changed:Connect(render)
	local t = UIKit.tween(nv, time, { Value = toV })
	t.Completed:Once(function()
		render(toV)
		nv:Destroy()
	end)
end

function Hud.bounce()
	refs.speedScale.Scale = 1.12
	UIKit.tween(refs.speedScale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
end

function Hud.popup(text, color)
	local label = popupPool[popupIndex]
	popupIndex = popupIndex % #popupPool + 1
	local x = canvas.Size.X.Offset * 0.5 + math.random(-90, 90)
	local y = canvas.Size.Y.Offset * 0.56 + math.random(-12, 12)
	label.Text = text
	label.TextColor3 = color or P.White
	label.Position = UDim2.fromOffset(x, y)
	label.TextTransparency = 0
	label.Rotation = math.random(-6, 6)
	label.Visible = true
	local s = label:FindFirstChildOfClass("UIStroke")
	if s then
		s.Transparency = 0
		UIKit.tween(s, 0.65, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	UIKit.tween(label, 0.65, { Position = UDim2.fromOffset(x, y - 80), TextTransparency = 1 })
end

function Hud.toast(text, kind)
	table.insert(toastQueue, { text = text, kind = kind })
	if toastBusy then
		return
	end
	toastBusy = true
	task.spawn(function()
		while #toastQueue > 0 do
			local item = table.remove(toastQueue, 1)
			refs.toastText.Text = item.text
			refs.toast.Accent.BackgroundColor3 = if item.kind == "Denied"
				then P.DangerRed
				elseif item.kind == "Unlock" or item.kind == "Gold" then P.Gold
				else P.ElectricBlue
			refs.toast.Visible = true
			refs.toast.Position = UDim2.new(0.5, 0, 0, 90)
			UIKit.tween(refs.toast, 0.2, { Position = UDim2.new(0.5, 0, 0, 104) }, Enum.EasingStyle.Back)
			if Hud.ctx.Sound then
				Hud.ctx.Sound.play(if item.kind == "Denied" then "Denied" elseif item.kind == "Unlock" then "Unlock" else "Toast")
			end
			task.wait(2.6)
			refs.toast.Visible = false
			task.wait(0.15)
		end
		toastBusy = false
	end)
end

function Hud.setTraining(station)
	refs.training.Visible = station ~= nil
	if station then
		refs.stationName.Text = string.upper(station.Name)
		refs.stationGain.Text = ("AFK STEPS  x%g"):format(station.Mult or 1)
		-- no combo any more (prompt 11): the machine steps for you
		refs.comboText.Visible = false
		refs.comboFill.Parent.Visible = false
	end
end

function Hud.setCombo(combo, frac)
	refs.comboText.Text = string.format("x%.1f", combo)
	refs.comboFill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
end

function Hud.pulseCombo()
	refs.comboScale.Scale = 1.3
	UIKit.tween(refs.comboScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

function Hud.setHint(visible, text)
	refs.hint.Visible = visible
	if text then
		refs.hint.Text = text
	end
end

-- During a race the top centre belongs to the position bar
function Hud.setRaceMode(on)
	refs.speedBlock.Visible = not on
	refs.raceHolder.Visible = not on
	if refs.menu then
		refs.menu.Visible = not on
	end
	refs.rank.Visible = not on
	if on then
		refs.training.Visible = false
		refs.hint.Visible = false
	end
end

----------------------------------------------------------------------------
function Hud.start(ctx)
	ctx.Hud = Hud
	Hud.ctx = ctx
	Hud.refs = refs
	local gui
	gui, canvas = UIKit.root("SpeedArcHud", player:WaitForChild("PlayerGui"), 1)
	Hud.gui = gui
	Hud.canvas = canvas

	-- the HUD hides while the main menu is up
	gui.Enabled = not player:GetAttribute("InMenu")
	player:GetAttributeChangedSignal("InMenu"):Connect(function()
		gui.Enabled = not player:GetAttribute("InMenu")
	end)

	buildCoins()
	buildSpeed()
	buildRacePill()
	buildToast()
	buildPopups()
	buildTraining()

	-- data mirrors
	local function onSpeed()
		local v = player:GetAttribute("Speed") or 0
		local from = shownSpeed
		shownSpeed = v
		if math.abs(v - from) > 40 then
			animateNumber(from, v, 0.5, renderSpeed)
		else
			renderSpeed(v)
		end
	end
	local function onCoins()
		local v = player:GetAttribute("Coins") or 0
		local from = shownCoins
		shownCoins = v
		if v > from and v - from >= 10 then
			animateNumber(from, v, 0.8, renderCoins)
			if v - from >= 50 and Hud.coinFly then
				Hud.coinFly(if v - from >= 1000 then 8 else 5)
				task.delay(0.45, function()
					ctx.Sound.play("CoinShower", { Volume = 0.7 })
				end)
			end
			refs.coinsScale.Scale = 1.15
			UIKit.tween(refs.coinsScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		else
			renderCoins(v)
		end
	end
	player:GetAttributeChangedSignal("Speed"):Connect(onSpeed)
	for _, a in { "Rank", "RankName", "League", "GoProReady", "BestWall" } do
		player:GetAttributeChangedSignal(a):Connect(function()
			renderRank()
			renderSpeed(player:GetAttribute("Speed") or 0)
		end)
	end
	renderRank()
	player:GetAttributeChangedSignal("Coins"):Connect(onCoins)
	shownSpeed = player:GetAttribute("Speed") or 0
	shownCoins = player:GetAttribute("Coins") or 0
	renderSpeed(shownSpeed)
	renderCoins(shownCoins)

	-- coins fly to the counter when a reward lands (pooled icons)
	local flyers = {}
	for i = 1, 8 do
		local c = UIKit.coinIcon(22, canvas)
		c.Name = "CoinFly"
		c.Visible = false
		c.ZIndex = 40
		for _, d in c:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 41
			end
		end
		flyers[i] = c
	end
	Hud.coinFly = function(n)
		local target = refs.coins.AbsolutePosition - canvas.AbsolutePosition
		local scale = canvas.AbsoluteSize.X / math.max(1, canvas.Size.X.Offset)
		local tx, ty = target.X / scale + 24, target.Y / scale + 22
		local w, h = canvas.Size.X.Offset, canvas.Size.Y.Offset
		for i = 1, math.min(n, #flyers) do
			local c = flyers[i]
			local sx, sy = w * 0.5 + math.random(-70, 70), h * 0.55 + math.random(-30, 30)
			c.Position = UDim2.fromOffset(sx, sy)
			c.Visible = true
			task.delay((i - 1) * 0.05, function()
				UIKit.tween(c, 0.5, { Position = UDim2.fromOffset(tx, ty) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.5, function()
					c.Visible = false
				end)
			end)
		end
	end

	-- the gold buttons' shine sweep: every 3.5 s, only the ones on screen
	task.spawn(function()
		while true do
			task.wait(3.5)
			if not (ctx.Settings and ctx.Settings.reduced()) then
				for i = #UIKit.sweeps, 1, -1 do
					local s = UIKit.sweeps[i]
					if not s.Parent then
						table.remove(UIKit.sweeps, i)
					elseif s.Parent.AbsoluteSize.X > 0 and s:FindFirstAncestorWhichIsA("GuiObject").Visible then
						s.Position = UDim2.new(-0.3, 0, 0.5, 0)
						UIKit.tween(s, 0.7, { Position = UDim2.new(1.3, 0, 0.5, 0) }, Enum.EasingStyle.Sine)
					end
				end
			end
		end
	end)

	-- the hint gently pulses while it shows (only one tween loop, only while visible)
	task.spawn(function()
		while true do
			if refs.hint.Visible then
				UIKit.tween(refs.hintScale, 0.45, { Scale = 1.06 }, Enum.EasingStyle.Sine)
				task.wait(0.45)
				UIKit.tween(refs.hintScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Sine)
				task.wait(0.45)
			else
				task.wait(0.3)
			end
		end
	end)

	ctx.Net.get("Toast").OnClientEvent:Connect(Hud.toast)
end

return Hud
