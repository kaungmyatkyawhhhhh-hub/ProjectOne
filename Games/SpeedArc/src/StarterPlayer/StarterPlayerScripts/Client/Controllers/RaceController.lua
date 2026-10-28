-- RaceController: JOIN window, 3-2-1-GO, drawing the runners smoothly from server progress,
-- BOOST taps, the live position bar, FINAL STRETCH, the LIVE RACE card and the podium (GDD 8;
-- races are the star of the game, owner 28 Oct).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Race = require(Shared.Config.Race)
local Areas = require(Shared.Config.Areas)
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local TrackPath = require(Shared.Util.TrackPath)

local P = UIKit.Palette
local F = UIKit.Fonts
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RaceController = {}

local ctx
local state -- ReplicatedStorage.RaceState.<your area>
local stateRoot
local phaseConn
local ui = {}
local joinedRaceId = nil

-- current race (everyone draws the runners; only racers get the race HUD)
local race = nil -- { raceId, laps, runners = { {id,name,lane,model,root,npc,userId} }, me = index or nil }
local privateConn = nil
local lastCount = nil
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
local camCF = nil -- our own camera state, so the default camera can't pull it back each frame
local camFov = 72

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
		Position = UDim2.fromScale(0.5, 0.3), -- above the runner's head in the race camera
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
	local line = UIKit.sprite("bar_track", {
		Name = "Line",
		Position = UDim2.new(0, 22, 0, 33),
		Size = UDim2.new(1, -72, 0, 12),
		Height = 12,
		Parent = bar,
	})
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
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -22, 1, -18),
		Size = UDim2.fromOffset(120, 128),
		Visible = false,
		Parent = canvas,
	})
	UIKit.sprite("round_blue", { Name = "Art", Size = UDim2.fromScale(1, 1), Parent = boost })
	UIKit.icon("speed", 34, boost, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), ZIndex = 2 })
	UIKit.text({ Text = "BOOST", TextSize = 24, StrokeColor = P.Navy, StrokeThickness = 2.5, StrokeTransparency = 0, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 44), ZIndex = 2, Parent = boost })
	ui.boostScale = UIKit.make("UIScale", { Parent = boost })
	ui.pips = {}
	for i = 1, Race.Boost.Charges do
		local pip = UIKit.sprite("badge_white", {
			Color = P.Gold,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, (i - 2) * 22, 0, 86),
			Size = UDim2.fromOffset(20, 20),
			ZIndex = 2,
			Parent = boost,
		})
		ui.pips[i] = pip
	end
	ui.boost = boost

	-- JUMP button with a timing ring (hurdle races)
	local jump = UIKit.make("TextButton", {
		Name = "Jump", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -152, 1, -22), Size = UDim2.fromOffset(96, 102),
		Visible = false, Parent = canvas,
	})
	UIKit.sprite("round_yellow", { Name = "Art", Size = UDim2.fromScale(1, 1), Parent = jump })
	UIKit.text({ Text = "JUMP", TextSize = 24, Color = P.Navy, Stroke = false, Size = UDim2.new(1, 0, 0.84, 0), ZIndex = 2, Parent = jump })
	ui.jumpScale = UIKit.make("UIScale", { Parent = jump })
	local ring = UIKit.make("Frame", { Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.8, 1.8), Visible = false, Parent = jump })
	UIKit.corner(ring, UDim.new(0.5, 0))
	ui.ringStroke = UIKit.make("UIStroke", { Color = P.Gold, Thickness = 4, Parent = ring })
	ui.ring = ring
	ui.jump = jump

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
	ui.pbBanner = UIKit.pill({ Kind = "gold", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -60, 0, 44), Size = UDim2.fromOffset(116, 34), ZIndex = 13, Parent = card })
	ui.pbBanner.Rotation = 10
	UIKit.text({ Text = "NEW PB!", TextSize = 20, Color = P.Navy, Stroke = false, ZIndex = 14, Parent = ui.pbBanner })
	ui.continue = cont

	-- confetti (pooled UI pieces, only for a win)
	ui.confetti = {}
	local layer = UIKit.make("Frame", { Name = "Confetti", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 45, Parent = canvas })
	local colors = { P.Gold, P.ElectricBlue, P.White, P.BrightBlue, P.DeepGold }
	for i = 1, 36 do
		local c = UIKit.make("Frame", {
			BackgroundColor3 = colors[(i - 1) % #colors + 1],
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(8, 14),
			Visible = false,
			ZIndex = 45,
			Parent = layer,
		})
		ui.confetti[i] = c
	end
end

----------------------------------------------------------------------------
-- Races are the star (owner, 28 Oct): the LIVE RACE card during the join window and the podium
----------------------------------------------------------------------------
local headCache = {} -- [userId] = headshot image (or "" while it loads)
local headCount = 0
local function headImage(userId)
	if headCache[userId] ~= nil then
		return headCache[userId]
	end
	if headCount > 120 then -- capped cache
		table.clear(headCache)
		headCount = 0
	end
	headCache[userId] = ""
	headCount += 1
	task.spawn(function()
		local ok, img = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		headCache[userId] = if ok then img else ""
	end)
	return ""
end

-- a round head: a real player's headshot, or an NPC's initial on a coloured disc
local function headIcon(parent, size, userId, name, ring, z)
	local f = UIKit.make("Frame", { Name = "Head", BackgroundColor3 = P.Carbon, Size = UDim2.fromOffset(size, size), ZIndex = z or 1, Parent = parent })
	UIKit.corner(f, UDim.new(0.5, 0))
	UIKit.stroke(f, ring or P.White, if size > 40 then 3 else 2, 0)
	if userId then
		local img = UIKit.make("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = headImage(userId), ZIndex = (z or 1) + 1, Parent = f })
		UIKit.corner(img, UDim.new(0.5, 0))
		if img.Image == "" then
			task.delay(1.2, function()
				if img.Parent then
					img.Image = headCache[userId] or ""
				end
			end)
		end
	else
		f.BackgroundColor3 = (ring or P.Sky):Lerp(P.SpeedBlack, 0.35)
		UIKit.text({ Text = string.upper(string.sub(name or "?", 1, 1)), TextSize = math.floor(size * 0.55), Size = UDim2.fromScale(1, 1), ZIndex = (z or 1) + 1, Parent = f })
	end
	return f
end

local function buildLive(canvas)
	local live = UIKit.panel({ Name = "LiveRace", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 106), Size = UDim2.fromOffset(300, 136), StrokeColor = P.Gold, StrokeThickness = 3, Accent = false, ZIndex = 8, Parent = canvas })
	live.Visible = false
	ui.live = live
	ui.liveScale = UIKit.make("UIScale", { Parent = live })
	local pill = UIKit.pill({ Kind = "red", Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(70, 28), ZIndex = 9, Parent = live })
	ui.liveDot = UIKit.make("Frame", { BackgroundColor3 = P.White, Position = UDim2.new(0, 11, 0.5, -4), Size = UDim2.fromOffset(8, 8), ZIndex = 10, Parent = pill })
	UIKit.corner(ui.liveDot, UDim.new(0.5, 0))
	UIKit.text({ Text = "LIVE", TextSize = 15, StrokeColor = P.Navy, StrokeThickness = 2, StrokeTransparency = 0, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -26, 1, 0), ZIndex = 10, Parent = pill })
	ui.liveType = UIKit.text({ Text = "RACE", TextSize = 20, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(90, 8), Size = UDim2.fromOffset(140, 30), ZIndex = 9, Parent = live })
	ui.liveTime = UIKit.text({ Text = "0:10", TextSize = 26, Color = P.Gold, XAlign = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(70, 32), ZIndex = 9, Parent = live })
	ui.liveHeads = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 40), Size = UDim2.fromOffset(280, 26), ZIndex = 9, Parent = live })
	UIKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = ui.liveHeads })
	ui.liveWho = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 14, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(180, 26), ZIndex = 9 })
	local prize = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 70), Size = UDim2.fromOffset(280, 20), ZIndex = 9, Parent = live })
	local ci = UIKit.coinIcon(18, prize)
	ci.Position = UDim2.fromOffset(0, 1)
	ui.livePrize = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 14, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), ZIndex = 9, Parent = prize })
	-- the HUD's JOIN button moves into the card
	local join = ctx.Hud.refs.join
	join.Parent = live
	join.AnchorPoint = Vector2.new(0, 0)
	join.Position = UDim2.fromOffset(10, 94)
	join.Size = UDim2.fromOffset(280, 38)
	join.ZIndex = 9
	for _, d in join:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = d.ZIndex + 8
		end
	end
	ctx.Hud.refs.joinLabel.TextSize = 20
	-- the LIVE dot blinks while the card is up
	task.spawn(function()
		while true do
			if live.Visible then
				ui.liveDot.BackgroundTransparency = if ui.liveDot.BackgroundTransparency == 0 then 0.7 else 0
			end
			task.wait(0.5)
		end
	end)
end

local lastJoined = nil
local function fillHeads(joined)
	if joined == lastJoined then
		return
	end
	lastJoined = joined
	for _, c in ui.liveHeads:GetChildren() do
		if c:IsA("GuiObject") then
			c.Parent = nil
			if c ~= ui.liveWho then
				c:Destroy()
			end
		end
	end
	local ids = {}
	for id in string.gmatch(joined or "", "%d+") do
		table.insert(ids, tonumber(id))
	end
	for i, id in ids do
		if i > 6 then
			break
		end
		local h = headIcon(ui.liveHeads, 26, id, nil, if id == player.UserId then P.Gold else P.White, 10)
		h.LayoutOrder = i
	end
	ui.liveWho.Text = if #ids == 0 then "BE THE FIRST TO JOIN!" elseif #ids > 6 then ("+%d  RACING REAL PLAYERS"):format(#ids - 6) else (if #ids == 1 then "1 RUNNER IN" else ("%d RUNNERS IN"):format(#ids))
	ui.liveWho.Size = UDim2.fromOffset(if #ids == 0 then 270 else 280 - math.min(#ids, 6) * 30, 26)
	ui.liveWho.LayoutOrder = 99
	ui.liveWho.Parent = ui.liveHeads
end

local function liveSuppressed()
	-- the tutorial has its own race card until its podium
	return ctx.Tutorial ~= nil and ctx.Tutorial.active() and (player:GetAttribute("Tut") or 0) < 5
end

local function winPrize()
	local league = player:GetAttribute("League") or 1
	local cpm = (require(Shared.Config.GameConfig).Economy.CoinsPerMinute)[league] or 60
	return math.floor(cpm * (Race.RewardMinutes[1] + Race.FinishMinutes) + 0.5)
end

-- the podium: 2nd, 1st, 3rd on blocks with heads, your place big, coins, medal, the SPEED boost
local PODIUM = { { place = 2, x = -140, h = 82, color = Color3.fromHex("#C9D1DD"), sprite = "btn_grey" }, { place = 1, x = 0, h = 116, color = Color3.fromHex("#FFD21F"), sprite = "btn_yellow" }, { place = 3, x = 140, h = 58, color = Color3.fromHex("#FF7A1A"), sprite = "btn_orange" } }

local function buildPodium(canvas)
	local pod = UIKit.make("TextButton", { Name = "Podium", Text = "", AutoButtonColor = false, BackgroundColor3 = P.SpeedBlack, BackgroundTransparency = 0.08, Position = UDim2.fromOffset(0, -80), Size = UDim2.new(1, 0, 1, 80), Visible = false, ZIndex = 30, Parent = canvas })
	-- a soft spotlight from the top so the podium glows
	UIKit.make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("#3557E8"), P.SpeedBlack), Parent = pod })
	ui.podium = pod
	ui.podiumContent = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -80), ZIndex = 31, Parent = pod })
end

local function showPodium(info)
	local root = ui.podiumContent
	for _, c in root:GetChildren() do
		c:Destroy()
	end
	local place = info.place
	local title = if place == 1 then "YOU WON!" elseif place == 2 then "2ND PLACE!" elseif place == 3 then "3RD PLACE!" else Format.place(place) .. "  -  SO CLOSE!"
	local titleColor = if place == 1 then P.Gold elseif place <= 3 then P.White else P.BrightBlue
	local banner = UIKit.text({ Text = title, TextSize = 52, Color = titleColor, StrokeThickness = 4, StrokeTransparency = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(600, 60), ZIndex = 33, Parent = root })
	local bs = UIKit.make("UIScale", { Scale = 0.3, Parent = banner })
	UIKit.tween(bs, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	local humans = 0
	for _, r in info.rows do
		if not r.npc then
			humans += 1
		end
	end
	UIKit.text({ Text = ("%s  -  %d RUNNERS  -  %d REAL PLAYER%s"):format(info.raceName or "LIVE RACE", info.total, humans, if humans == 1 then "" else "S"), Font = F.BodyBold, TextSize = 15, Color = P.BrightBlue, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(600, 20), ZIndex = 33, Parent = root })
	-- the stage
	local stage = UIKit.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 94), Size = UDim2.fromOffset(420, 192), ZIndex = 32, Parent = root })
	for i, spot in PODIUM do
		local r = info.rows[spot.place]
		if r then
			local isMe = r.id == info.youId
			-- the podium blocks are the kit's button art (gold / silver / bronze), stretched tall
			local block = UIKit.sprite(spot.sprite, { Name = "Block", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, spot.x, 1, 0), Size = UDim2.fromOffset(124, 0), ZIndex = 33, Parent = stage })
			if isMe then
				local ring = UIKit.make("Frame", { Name = "You", BackgroundTransparency = 1, Position = UDim2.fromOffset(-2, -2), Size = UDim2.new(1, 4, 1, -2), ZIndex = 33, Parent = block })
				UIKit.corner(ring, 12)
				UIKit.stroke(ring, P.White, 4, 0)
			end
			UIKit.text({ Text = tostring(spot.place), TextSize = 40, StrokeThickness = 3, StrokeTransparency = 0, Size = UDim2.new(1, 0, 0, 50), ZIndex = 34, Parent = block })
			task.delay(0.15 * i, function()
				UIKit.tween(block, 0.4, { Size = UDim2.fromOffset(124, spot.h) }, Enum.EasingStyle.Back)
			end)
			-- head + name above the block
			local holder = UIKit.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, spot.x, 1, -spot.h - 4), Size = UDim2.fromOffset(124, 92), ZIndex = 34, Parent = stage })
			local hs = UIKit.make("UIScale", { Scale = 0, Parent = holder })
			local head = headIcon(holder, if spot.place == 1 then 62 else 52, r.userId, r.name, if isMe then P.Gold else spot.color, 35)
			head.AnchorPoint = Vector2.new(0.5, 1)
			head.Position = UDim2.new(0.5, 0, 1, 0)
			UIKit.text({ Text = (if isMe then "YOU" else r.name), TextSize = 14, Color = if isMe then P.Gold else P.White, StrokeThickness = 2, StrokeTransparency = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -(if spot.place == 1 then 64 else 54)), Size = UDim2.fromOffset(124, 18), ZIndex = 36, Parent = holder })
			task.delay(0.35 + 0.15 * i, function()
				UIKit.tween(hs, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			end)
		end
	end
	-- the rest of the field, small, left of the stage
	local rest = UIKit.make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(0.5, -230, 0, 120), Size = UDim2.fromOffset(150, 150), ZIndex = 33, Parent = root })
	UIKit.make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = rest })
	for p = 4, math.min(8, #info.rows) do
		local r = info.rows[p]
		local isMe = r.id == info.youId
		local l = UIKit.text({ Text = ("%s  %s"):format(Format.place(p), if isMe then "YOU" else r.name), Font = if isMe then F.BodyBold else F.Body, TextSize = 14, Color = if isMe then P.Gold else P.White, XAlign = Enum.TextXAlignment.Right, Size = UDim2.new(1, 0, 0, 18), ZIndex = 33, Parent = rest })
		l.LayoutOrder = p
	end
	-- your rewards, right of the stage: coins, medal, the SPEED boost, PB
	local rw = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.5, 230, 0, 112), Size = UDim2.fromOffset(170, 170), ZIndex = 33, Parent = root })
	local medalSlot = UIKit.make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(56, 72), ZIndex = 34, Parent = rw })
	if info.medal then
		UIKit.medalIcon(info.medal, 52, medalSlot, info.place)
	end
	local coinRow = UIKit.make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 76), Size = UDim2.fromOffset(170, 34), ZIndex = 34, Parent = rw })
	local ci = UIKit.coinIcon(28, coinRow)
	ci.Position = UDim2.fromOffset(0, 3)
	local coins = UIKit.text({ Text = "+0", TextSize = 28, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(34, 0), Size = UDim2.fromOffset(136, 34), ZIndex = 35, Parent = coinRow })
	local y = 112
	if info.winBoost then
		UIKit.text({ Text = ("2x SPEED  %s"):format(Format.clock(info.winBoost)), TextSize = 17, Color = P.Orange, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(170, 22), ZIndex = 34, Parent = rw })
		y += 24
	end
	if info.pb then
		UIKit.text({ Text = "NEW PB!", TextSize = 17, Color = P.Lime, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(170, 22), ZIndex = 34, Parent = rw })
		y += 24
	end
	if info.firstOfDay then
		UIKit.text({ Text = "First race today: +50%", Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(170, 18), ZIndex = 34, Parent = rw })
	end
	UIKit.text({ Text = if info.time then ("TIME  %s"):format(Format.seconds(info.time)) else "Placed by distance", Font = F.BodyBold, TextSize = 14, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(62, 24), Size = UDim2.fromOffset(110, 20), ZIndex = 34, Parent = rw })
	UIKit.button({ Style = if place == 1 then "Gold" else "Blue", Text = "CONTINUE", TextSize = 20, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 294), Size = UDim2.fromOffset(200, 44), ZIndex = 36, Parent = root, OnClick = function()
		RaceController.hideResults()
	end })
	ui.podium.Visible = true
	-- coins tick up, then fly to the counter
	task.delay(0.6, function()
		ctx.Sound.play("Coins")
		local nv = Instance.new("NumberValue")
		nv.Changed:Connect(function(v)
			coins.Text = "+" .. Format.short(v)
		end)
		local t = UIKit.tween(nv, 0.9, { Value = info.coins })
		t.Completed:Once(function()
			coins.Text = "+" .. Format.short(info.coins)
			nv:Destroy()
			ctx.Hud.coinFly(if place == 1 then 8 elseif place <= 3 then 5 else 3)
			if place <= 3 then
				ctx.Sound.play("CoinShower", { Volume = if place == 1 then 1 else 0.6 })
			end
		end)
	end)
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
		pip.ImageColor3 = if i <= charges then P.Gold else P.Graphite
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
	if ctx.SpeedFeel then
		ctx.SpeedFeel.boost()
	end
	ctx.Net.get("RaceBoost"):FireServer()
end

----------------------------------------------------------------------------
-- Hurdles: you JUMP; everyone else (and NPCs) is drawn clearing them
----------------------------------------------------------------------------
local function myShown()
	local p = race and race.me and prog[race.me]
	return p and p.shown or 0
end

function RaceController.jump()
	if not race or not race.me or not race.hurdles or state:GetAttribute("Phase") ~= "Running" then
		return
	end
	local v = myShown()
	table.insert(race.jumps, v)
	ctx.Net.get("RaceBoost"):FireServer("jump")
	ctx.Sound.play("Jump")
	ui.jumpScale.Scale = 0.88
	UIKit.tween(ui.jumpScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- height above the lane for runner i at progress v (a smooth arc over each hurdle)
function RaceController.hurdleLift(i, v)
	local H = Race.Hurdle
	local len = race.length or 400
	for _, hp in race.hurdles do
		local u = (v - hp) * len -- studs past the hurdle (negative = before it)
		if u > -3.5 and u < 3 then
			if i == race.me then
				local jumped = false
				for _, j in race.jumps do
					if j >= hp - H.Window / len and j <= hp + H.LateWindow / len then
						jumped = true
					end
				end
				if not jumped then
					return 0
				end
			end
			local t = (u + 3.5) / 6.5
			return H.JumpHeight * math.sin(math.pi * t)
		end
	end
	return 0
end

local function updateRing()
	if not race or not race.me or not race.hurdles then
		return
	end
	local v = myShown()
	local len = race.length or 400
	local nextD = nil
	for _, hp in race.hurdles do
		local d = (hp - v) * len
		if d > -0.5 then
			nextD = d
			break
		end
	end
	if nextD and nextD < 16 then
		ui.ring.Visible = true
		local s = 1 + math.clamp((nextD - Race.Hurdle.Window * 0.5) / 12, 0, 1) * 0.9
		ui.ring.Size = UDim2.fromScale(s, s)
		ui.ringStroke.Color = if nextD <= Race.Hurdle.Window then P.Gold else P.White
	else
		ui.ring.Visible = false
	end
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
			local lift = 0
			if race.hurdles then
				lift = RaceController.hurdleLift(i, v)
			end
			root.CFrame = race.path.runnerCFrame(r.lane, v, race.laps, lift)
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

	updateRing()
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
		if ctx.RaceFx then
			ctx.RaceFx.onOvertake(place, lastPlace)
		end
	end
	lastPlace = place

	local mine = prog[race.me]
	local myShown = mine and mine.shown or 0
	if not stretchShown and myShown >= Race.FinalStretch then
		stretchShown = true
		showCenter("FINAL STRETCH", P.Gold, 1.0)
		ctx.Sound.play("FinalStretch")
		if ctx.RaceFx then
			ctx.RaceFx.onFinalStretch()
		end
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
		local want = CFrame.lookAt(pos, target)
		camCF = if camCF then camCF:Lerp(want, 0.25) else want
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camCF
		local mid = Race.LeagueMid[player:GetAttribute("League") or 1] or Race.LeagueMid[1]
		local paceNorm = math.clamp(((player:GetAttribute("Speed") or 0) / mid) ^ 0.3, 0.6, 1.5)
		local fov = 70 + 10 * paceNorm + (if os.clock() < fovKickUntil then 5 else 0)
		fov = math.min(fov, 90)
		if ctx.Settings and ctx.Settings.reduced() then
			fov = 74 -- reduced motion: no FOV swings or kicks
		end
		camFov += (fov - camFov) * 0.15
		camera.FieldOfView = camFov
	end
end

local function clearMarkers()
	for _, m in ui.markers do
		m:Destroy()
	end
	table.clear(ui.markers)
end

local function onStart(info)
	local mine = false
	for _, r in info.runners do
		if r.userId == player.UserId then
			mine = true
		end
	end
	if not mine and info.areaId ~= (player:GetAttribute("Area") or "Hub") then
		return -- someone else's race in another area
	end
	local area = Areas[info.areaId] or Areas.Hub
	race = {
		-- private races (tutorial, RACE THEM) count down on their own state folder
		state = if info.private then stateRoot:WaitForChild(info.stateName, 5) else nil,
		kind = info.kind,
		areaId = info.areaId,
		raceId = info.raceId,
		laps = info.laps,
		runners = {},
		me = nil,
		path = TrackPath.for_(area.Track),
		hurdles = info.hurdles,
		length = info.length,
		jumps = {},
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
		camCF = nil
		camFov = 72
		ui.raceName.Text = info.name
		clearMarkers()
		for i, r in race.runners do
			ui.markers[i] = marker(r, i == race.me)
		end
		ui.bar.Visible = true
		ui.boost.Visible = true
		ui.jump.Visible = race.hurdles ~= nil
		charges = Race.Boost.Charges
		updatePips()
		lastPlace = 0
		stretchShown = false
		finishedShown = false
		ctx.Sound.stop("CrowdMurmur")
		if race.state then
			privateConn = race.state:GetAttributeChangedSignal("Phase"):Connect(function()
				if race and race.state and race.state:GetAttribute("Phase") == "Running" then
					lastCount = nil
					showCenter("GO!", P.Gold, 0.8)
					ctx.Sound.play("StartGun")
					if ctx.RaceFx then
						ctx.RaceFx.onGo(race)
					end
				end
			end)
		end
		if RaceController.onMyStart then
			RaceController.onMyStart(info)
		end
	end
end

local function endRace()
	if privateConn then
		privateConn:Disconnect()
		privateConn = nil
	end
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
		ui.jump.Visible = false
		clearMarkers()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		ctx.Hud.setRaceMode(false)
		if not ctx.Training.isTraining() then
			ctx.Training.setControls(true)
		end
		if RaceController.rebind then
			task.defer(RaceController.rebind)
		end
	end
end

function RaceController.hideResults()
	if ui.podium.Visible then
		ui.podium.Visible = false
	end
	if ui.card.Visible then
		ui.card.Visible = false
	end
end

local function onResults(info)
	if ctx.RaceFx and race and race.me then
		ctx.RaceFx.onFinish(info.place, race)
	end
	-- the podium is the big moment (the old results card stays built but hidden)
	showPodium(info)
	if info.place == 1 then
		ctx.Sound.play("Fanfare")
		ctx.Sound.play("FinishCheer")
		confetti()
		task.delay(0.8, confetti)
	elseif info.place <= 3 then
		ctx.Sound.play("Fanfare", { Volume = 0.6, Pitch = 0.94 })
		ctx.Sound.play("FinishCheer", { Volume = 0.6 })
		confetti()
	else
		ctx.Sound.play("FinishCheer", { Volume = 0.35 })
	end
	local shownFor = info.raceId
	task.delay(Race.ResultsSeconds + 4, function()
		if ui.podium.Visible and shownFor == info.raceId then
			RaceController.hideResults()
		end
	end)
	if true then
		return
	end
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
		local show = not race and not liveSuppressed()
		if show and not ui.live.Visible then
			ui.live.Visible = true
			ui.liveScale.Scale = 0.6
			UIKit.tween(ui.liveScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			ctx.Sound.play("Toast")
			ctx.Sound.play("CrowdMurmur", { Volume = 0.5 })
		elseif not show then
			ui.live.Visible = false
		end
		if ui.live.Visible then
			ui.liveType.Text = string.upper(state:GetAttribute("TypeName") or "RACE")
			ui.liveTime.Text = Format.clock(left)
			ui.liveTime.TextColor3 = if left <= 3 then P.DangerRed else P.Gold
			fillHeads(state:GetAttribute("Joined"))
			ui.livePrize.Text = ("WIN  +%s COINS  +  2x SPEED"):format(Format.short(winPrize()))
		end
		if joinedRaceId == id then
			refs.joinLabel.Text = ("JOINED!  %d"):format(math.max(0, math.ceil(left)))
		else
			refs.joinLabel.Text = ("JOIN RACE  %d"):format(math.max(0, math.ceil(left)))
		end
	else
		refs.join.Visible = false
		ui.live.Visible = false
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

local function countdownTick()
	if not race or not race.me then
		return
	end
	local st = race.state or state
	local phase = st:GetAttribute("Phase")
	if phase == "Countdown" then
		local left = math.ceil((st:GetAttribute("EndsAt") or 0) - now())
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
	stateRoot = ReplicatedStorage:WaitForChild("RaceState")
	state = stateRoot:WaitForChild(player:GetAttribute("Area") or "Hub")
	buildUI()
	buildLive(ctx.Hud.canvas)
	buildPodium(ctx.Hud.canvas)

	ctx.Hud.refs.join.Activated:Connect(function()
		if state:GetAttribute("Phase") == "Join" and joinedRaceId ~= state:GetAttribute("RaceId") then
			ctx.Net.get("RaceJoin"):FireServer()
		end
	end)

	ui.boost.Activated:Connect(boost)
	ui.jump.Activated:Connect(RaceController.jump)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not race or not race.me then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
			or (t == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space) then
			boost()
		elseif t == Enum.UserInputType.Keyboard and (input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.Up) then
			RaceController.jump()
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
		elseif kind == "hurdle" then
			if info.clean then
				ctx.Sound.play("HurdleLand")
			else
				ctx.Sound.play("HurdleKnock")
				showCenter("CLIP!", P.White, 0.4)
			end
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

	local function onPhase()
		local phase = state:GetAttribute("Phase")
		if phase == "Join" then
			UIKit.setButtonStyle(ctx.Hud.refs.join, "Green")
			-- not during the tutorial before its own race (no toasts over a tutorial hint)
			-- the LIVE RACE card is the call (no toast on top of it)
		elseif phase == "Running" and race and race.me and not race.state then
			lastCount = nil
			showCenter("GO!", P.Gold, 0.8)
			ctx.Sound.play("StartGun")
			if ctx.RaceFx then
				ctx.RaceFx.onGo(race)
			end
		end
	end
	-- follow the race of the area you're in (not while you're racing)
	local function bindArea()
		if race and race.me then
			return
		end
		local s2 = stateRoot:WaitForChild(player:GetAttribute("Area") or "Hub", 10)
		if not s2 then
			return
		end
		state = s2
		if phaseConn then
			phaseConn:Disconnect()
		end
		phaseConn = state:GetAttributeChangedSignal("Phase"):Connect(onPhase)
	end
	bindArea()
	player:GetAttributeChangedSignal("Area"):Connect(bindArea)
	RaceController.rebind = bindArea

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
