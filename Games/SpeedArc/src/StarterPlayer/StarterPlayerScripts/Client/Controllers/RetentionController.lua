-- RetentionController (M4, GDD 15): DAILY / QUESTS / TOP buttons under the race timer, CODES +
-- INVITE under the left menu, the Daily, Quests and Settings (codes, music, sounds) windows, playtime
-- gift popups and the timed-boost badge on the MPH plate.
-- Popups wait in one queue and show one at a time, only when you're off a station, not racing, no
-- window is open and no tutorial hint is up (lesson: a popup that can't show waits, never skipped).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ExperienceNotificationService = game:GetService("ExperienceNotificationService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)
local Retention = require(Shared.Config.Retention)
local Trails = require(Shared.Config.Trails)
local SoundConfig = require(Shared.Config.Sounds)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local R = {}
local ctx, canvas
local state = nil
local dailyWin, questsWin, settingsWin
local dailyGrid, dailyClaim, dailyClaimLabel, dailyNote
local questRows, questBonus
local dots = {}
local badge, badgeText
local queue = {}
local showing = false
local dailyShownThisSession = false

----------------------------------------------------------------------------
-- popup queue
----------------------------------------------------------------------------
local function free()
	if player:GetAttribute("InRace") or ctx.Training.isTraining() then
		return false
	end
	if ctx.Tutorial and ctx.Tutorial.hintShowing() then
		return false
	end
	for _, ch in canvas:GetChildren() do
		if (ch.Name:match("Backdrop$") or ch.Name == "CoachReveal" or ch.Name == "GoProScene" or ch.Name == "RankUp") and ch.Visible then
			return false
		end
	end
	return true
end

function R.queue(fn)
	table.insert(queue, fn)
end

local function card(title, text, sub, color)
	local c = UIKit.panel({ Name = "RetentionPopup", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 156), Size = UDim2.fromOffset(400, 104), AccentColor = color or P.Gold, StrokeColor = color or P.Gold, StrokeThickness = 3, ZIndex = 30, Parent = canvas })
	local s = make("UIScale", { Scale = 0.5, Parent = c })
	UIKit.text({ Text = title, TextSize = 24, Color = color or P.Gold, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 30), ZIndex = 31, Parent = c })
	UIKit.text({ Text = text, Font = F.BodyBold, TextSize = 16, Wrapped = true, Position = UDim2.fromOffset(16, 40), Size = UDim2.new(1, -32, 0, 36), ZIndex = 31, Parent = c })
	if sub then
		UIKit.text({ Text = sub, Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, Position = UDim2.fromOffset(16, 78), Size = UDim2.new(1, -32, 0, 18), ZIndex = 31, Parent = c })
	end
	UIKit.tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	ctx.Sound.play("Unlock")
	task.wait(3.2)
	UIKit.tween(s, 0.2, { Scale = 0.6 })
	task.wait(0.2)
	c:Destroy()
end

----------------------------------------------------------------------------
-- small top buttons with a red dot
----------------------------------------------------------------------------
local function smallButton(name, text, style, parent, pos, size)
	local b = UIKit.button({ Name = name, Style = style or "Dark", Text = text, TextSize = 14, Position = pos, Size = size or UDim2.fromOffset(62, 36), EdgeHeight = 4, Radius = 10, Parent = parent })
	local dot = make("Frame", { Name = "Dot", BackgroundColor3 = P.DangerRed, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(14, 14), Visible = false, ZIndex = 5, Parent = b })
	UIKit.corner(dot, UDim.new(0.5, 0))
	UIKit.stroke(dot, P.White, 1.5)
	dots[name] = dot
	return b
end

----------------------------------------------------------------------------
-- DAILY
----------------------------------------------------------------------------
local function rewardText(r)
	local parts = {}
	if r.Minutes then
		table.insert(parts, ("%s coins"):format(Format.short(Formulas.minutesOfCoins(r.Minutes, player:GetAttribute("League") or 1))))
	end
	if r.Rolls then
		table.insert(parts, if r.Rolls == 1 then "coach roll" else ("%d rolls"):format(r.Rolls))
	end
	if r.Trail then
		for _, t in Trails.List do
			if t.Id == r.Trail then
				table.insert(parts, t.Name .. " trail")
			end
		end
	end
	return table.concat(parts, " + ")
end

local function renderDaily()
	if not state or not dailyGrid then
		return
	end
	for _, ch in dailyGrid:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local d = state.Daily
	for i, r in state.DailyRewards do
		local isNext = i == d.Day
		local done = (not d.Claimable and i <= d.Streak) or (d.Claimable and not d.Broken and i < d.Day)
		local tile = make("Frame", { Name = "Day" .. i, BackgroundColor3 = P.White, Size = UDim2.fromOffset(84, 150), LayoutOrder = i, Parent = dailyGrid })
		UIKit.corner(tile, 12)
		UIKit.gradient(tile, if isNext then P.DeepBlue elseif done then P.Graphite else P.Carbon, P.SpeedBlack, 90)
		UIKit.stroke(tile, if isNext then P.Gold elseif done then P.ElectricBlue else P.Graphite, if isNext then 3 else 2)
		UIKit.text({ Text = "DAY " .. i, TextSize = 16, Color = if isNext then P.Gold else P.White, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 20), Parent = tile })
		if r.Trail or r.Rolls then
			UIKit.text({ Text = if r.Trail then "TRAIL" else "ROLL", TextSize = 18, Color = P.Gold, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 24), Parent = tile })
		else
			local ci = UIKit.coinIcon(30, tile)
			ci.Position = UDim2.new(0.5, -15, 0, 36)
		end
		UIKit.text({ Text = rewardText(r), Font = F.BodyBold, TextSize = 13, Wrapped = true, Position = UDim2.fromOffset(4, 74), Size = UDim2.new(1, -8, 0, 46), Parent = tile })
		if done then
			UIKit.text({ Text = "GOT IT", TextSize = 14, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 124), Size = UDim2.new(1, 0, 0, 18), Parent = tile })
		end
	end
	dailyClaim.Visible = d.Claimable
	dailyClaimLabel.Text = ("CLAIM DAY %d"):format(d.Day)
	if d.Claimable then
		dailyNote.Text = if d.Broken then "Your streak restarted. One missed day is OK - two is too many!" else "Come back every day. Missing one day is OK!"
	else
		local nextR = state.DailyRewards[d.Day]
		dailyNote.Text = ("Tomorrow: DAY %d - %s"):format(d.Day, nextR and rewardText(nextR) or "")
	end
end

local function claimDaily()
	local ok, res = ctx.Net.call("ClaimDaily")
	if ok and res then
		ctx.Sound.play("KaChing")
		ctx.Hud.toast(("Day %d: %s"):format(res.Day, res.Text), "Gold")
		-- after the first daily claim: ask about notifications (once)
		task.delay(1.5, function()
			local can = false
			pcall(function()
				can = ExperienceNotificationService:CanPromptOptInAsync()
			end)
			if can then
				pcall(function()
					ExperienceNotificationService:PromptOptIn()
				end)
			end
		end)
	end
end

----------------------------------------------------------------------------
-- QUESTS
----------------------------------------------------------------------------
local function renderQuests()
	if not state or not questRows then
		return
	end
	local q = state.Quests
	for i, row in questRows do
		local e = q.List[i]
		row.frame.Visible = e ~= nil
		if e then
			row.text.Text = e.Text
			row.count.Text = ("%s / %s"):format(Format.short(e.Progress), Format.short(e.Goal))
			row.fill.Size = UDim2.fromScale(math.clamp(e.Progress / e.Goal, 0, 1), 1)
			local done = e.Progress >= e.Goal
			row.claim.Visible = done and not e.Claimed
			row.got.Visible = e.Claimed
			row.reward.Visible = not done and not e.Claimed
			row.reward.Text = "+" .. Format.short(Formulas.minutesOfCoins(Retention.Quests.RewardMinutes, player:GetAttribute("League") or 1))
		end
	end
	questBonus.Visible = q.BonusReady
end

----------------------------------------------------------------------------
-- dots + badge
----------------------------------------------------------------------------
local function updateDots()
	if not state then
		return
	end
	dots.Daily.Visible = state.Daily.Claimable
	local any = state.Quests.BonusReady
	for _, e in state.Quests.List do
		if e.Progress >= e.Goal and not e.Claimed then
			any = true
		end
	end
	dots.Quests.Visible = any
end

local function updateBadge()
	local nr = player:GetAttribute("BoostNewRunner") or 0
	local gift = player:GetAttribute("BoostGift") or 0
	local secs = math.max(nr, gift)
	badge.Visible = secs > 0
	if secs > 0 then
		badgeText.Text = ("2x  %s"):format(Format.clock(secs))
	end
end

----------------------------------------------------------------------------
local function buildWindows()
	-- Daily
	dailyWin = UIKit.window({ Name = "Daily", Title = "DAILY STREAK", Size = Vector2.new(700, 300), Accent = P.Gold, Parent = canvas })
	dailyGrid = make("Frame", { Name = "Days", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 152), Parent = dailyWin.content })
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dailyGrid })
	dailyNote = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 15, Position = UDim2.fromOffset(0, 170), Size = UDim2.new(1, 0, 0, 22), Parent = dailyWin.content })
	dailyClaim, dailyClaimLabel = UIKit.button({ Name = "Claim", Style = "Gold", Text = "CLAIM", TextSize = 20, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 198), Size = UDim2.fromOffset(220, 50), Parent = dailyWin.content, OnClick = claimDaily })
	dailyWin.onOpen = renderDaily

	-- Quests
	questsWin = UIKit.window({ Name = "Quests", Title = "DAILY QUESTS", Size = Vector2.new(560, 300), Accent = P.ElectricBlue, Parent = canvas })
	UIKit.text({ Text = "3 new quests every day. Finish all 3 for a bonus + a free coach roll!", Font = F.BodyBold, TextSize = 13, Wrapped = true, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 30), Parent = questsWin.content })
	questRows = {}
	for i = 1, Retention.Quests.PerDay do
		local f = UIKit.panel({ Name = "Quest" .. i, Position = UDim2.fromOffset(0, 40 + (i - 1) * 58), Size = UDim2.new(1, 0, 0, 52), Accent = false, Parent = questsWin.content })
		local text = UIKit.text({ Text = "", TextSize = 16, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 4), Size = UDim2.new(1, -150, 0, 22), Parent = f })
		local bar = make("Frame", { BackgroundColor3 = P.SpeedBlack, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -230, 0, 12), Parent = f })
		UIKit.corner(bar, UDim.new(0.5, 0))
		local fill = make("Frame", { BackgroundColor3 = P.ElectricBlue, Size = UDim2.fromScale(0, 1), Parent = bar })
		UIKit.corner(fill, UDim.new(0.5, 0))
		local count = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.new(1, -208, 0, 26), Size = UDim2.fromOffset(80, 20), Parent = f })
		local claim = UIKit.button({ Name = "Claim", Style = "Gold", Text = "CLAIM", TextSize = 15, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(110, 40), Parent = f, OnClick = function()
			local ok, res = ctx.Net.call("ClaimQuest", i)
			if ok then
				ctx.Sound.play("KaChing")
				ctx.Hud.toast("Quest done! " .. res.Text, "Gold")
			end
		end })
		local got = UIKit.text({ Text = "DONE", TextSize = 16, Color = P.BrightBlue, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(90, 30), Parent = f })
		local reward = UIKit.text({ Text = "", TextSize = 16, Color = P.Gold, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(100, 30), XAlign = Enum.TextXAlignment.Right, Parent = f })
		questRows[i] = { frame = f, text = text, fill = fill, count = count, claim = claim, got = got, reward = reward }
	end
	questBonus = UIKit.button({ Name = "Bonus", Style = "Gold", Text = "ALL 3 DONE! CLAIM BONUS", TextSize = 16, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40 + 3 * 58), Size = UDim2.fromOffset(300, 40), Parent = questsWin.content, OnClick = function()
		local ok, res = ctx.Net.call("ClaimQuestBonus")
		if ok then
			ctx.Sound.play("KaChing")
			ctx.Hud.toast("Bonus! " .. res.Text, "Gold")
		end
	end })
	questsWin.onOpen = renderQuests

	-- Settings (codes, music, sounds)
	settingsWin = UIKit.window({ Name = "Settings", Title = "SETTINGS", Size = Vector2.new(520, 280), Parent = canvas })
	UIKit.text({ Text = "CODES", TextSize = 18, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(4, 8), Size = UDim2.fromOffset(200, 24), Parent = settingsWin.content })
	local boxFrame = make("Frame", { BackgroundColor3 = P.SpeedBlack, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, -150, 0, 46), Parent = settingsWin.content })
	UIKit.corner(boxFrame, 10)
	UIKit.stroke(boxFrame, P.Graphite, 2)
	local box = make("TextBox", { Name = "Code", BackgroundTransparency = 1, ClearTextOnFocus = false, PlaceholderText = "Type a code", PlaceholderColor3 = P.Graphite, Text = "", TextColor3 = P.White, FontFace = F.BodyBold, TextSize = 18, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = boxFrame })
	UIKit.button({ Name = "Redeem", Style = "Gold", Text = "REDEEM", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 36), Size = UDim2.fromOffset(138, 50), Parent = settingsWin.content, OnClick = function()
		local ok, res = ctx.Net.call("RedeemCode", box.Text)
		if ok then
			ctx.Sound.play("KaChing")
			ctx.Hud.toast("Code worked! " .. res.Text, "Gold")
			box.Text = ""
		else
			ctx.Hud.toast(if res == "used" then "You already used that code" else "That code doesn't work", "Denied")
		end
	end })
	UIKit.text({ Text = "New codes come with updates - check the game page!", Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(4, 90), Size = UDim2.new(1, 0, 0, 18), Parent = settingsWin.content })
	local function toggle(y, label, groupName)
		UIKit.text({ Text = label, TextSize = 18, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(4, y), Size = UDim2.fromOffset(200, 44), Parent = settingsWin.content })
		local on = true
		local b, l
		b, l = UIKit.button({ Name = groupName, Style = "Blue", Text = "ON", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y), Size = UDim2.fromOffset(110, 44), Parent = settingsWin.content, OnClick = function()
			on = not on
			l.Text = if on then "ON" else "OFF"
			UIKit.setButtonStyle(b, if on then "Blue" else "Dark")
			local groups = if groupName == "Music" then { "Music" } else { "SFX", "UI", "Crowd", "Voice" }
			for _, g in groups do
				local sg = SoundService:FindFirstChild(g)
				if sg and sg:IsA("SoundGroup") then
					sg.Volume = if on then (SoundConfig.Groups[g] or 0.5) else 0
				end
			end
		end })
	end
	toggle(124, "MUSIC", "Music")
	toggle(176, "SOUNDS", "Sounds")
end

function R.start(c)
	ctx = c
	ctx.Retention = R
	canvas = ctx.Hud.canvas

	-- buttons under the race timer (the JOIN button moves down under them)
	local row = make("Frame", { Name = "TopButtons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 58), Size = UDim2.fromOffset(196, 38), Parent = canvas })
	smallButton("Daily", "DAILY", "Gold", row, UDim2.fromOffset(0, 0)).Activated:Connect(function()
		dailyWin.show()
	end)
	smallButton("Quests", "QUESTS", "Blue", row, UDim2.fromOffset(67, 0)).Activated:Connect(function()
		questsWin.show()
	end)
	smallButton("Top", "TOP", "Dark", row, UDim2.fromOffset(134, 0)).Activated:Connect(function()
		if ctx.Leaderboards then
			ctx.Leaderboards.open()
		end
	end)
	local refs = ctx.Hud.refs
	refs.raceHolder.Size = UDim2.fromOffset(196, 160)
	refs.join.Position = UDim2.fromOffset(0, 92)

	-- CODES + INVITE under the left menu
	local menu = refs.menu
	if menu then
		menu.Size = UDim2.fromOffset(124, 152)
		menu.Position = UDim2.new(0, 14, 0.5, 30) -- stays clear of the coach chips under the rank badge
		local sub = make("Frame", { Name = "Small", BackgroundTransparency = 1, Size = UDim2.fromOffset(124, 36), LayoutOrder = 3, Parent = menu })
		smallButton("Codes", "CODES", "Dark", sub, UDim2.fromOffset(0, 0), UDim2.fromOffset(59, 36)).Activated:Connect(function()
			settingsWin.show()
		end)
		smallButton("Invite", "INVITE", "Dark", sub, UDim2.fromOffset(65, 0), UDim2.fromOffset(59, 36)).Activated:Connect(function()
			if ctx.Social then
				ctx.Social.invite()
			end
		end)
	end

	-- timed boost badge on the MPH plate
	badge = make("Frame", { Name = "BoostBadge", BackgroundColor3 = P.Gold, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 12), Size = UDim2.fromOffset(74, 22), Visible = false, ZIndex = 4, Parent = refs.speedBlock })
	UIKit.corner(badge, UDim.new(0.5, 0))
	badgeText = UIKit.text({ Text = "2x", TextSize = 13, Color = P.SpeedBlack, Stroke = false, ZIndex = 5, Parent = badge })

	buildWindows()

	ctx.Net.get("Retention").OnClientEvent:Connect(function(kind, info)
		if kind == "state" then
			state = info
			updateDots()
			if dailyWin.isOpen() then
				renderDaily()
			end
			if questsWin.isOpen() then
				renderQuests()
			end
			-- the daily window opens by itself once a session, when you're free (never in the tutorial)
			if info.Daily.Claimable and not dailyShownThisSession and (info.Tutorial or 0) >= 99 then
				dailyShownThisSession = true
				R.queue(function()
					dailyWin.show()
					while dailyWin.isOpen() do
						task.wait(0.3)
					end
				end)
			end
		elseif kind == "gift" then
			R.queue(function()
				card(("GIFT %d OF %d"):format(info.Index, info.Total), info.Text, if info.NextAt then ("Next gift at %d min of play today"):format(info.NextAt) else "That's every gift today. See you tomorrow!")
			end)
		elseif kind == "notice" then
			R.queue(function()
				card(info.Title, info.Text, nil)
			end)
		end
	end)
	task.spawn(function()
		local ok, st = ctx.Net.call("RetentionState")
		if ok and st then
			state = st
			updateDots()
		end
	end)

	-- one popup at a time, only when free
	task.spawn(function()
		while true do
			task.wait(0.4)
			updateBadge()
			row.Visible = not player:GetAttribute("InRace") -- the race HUD owns the top right
			if not showing and #queue > 0 and free() then
				showing = true
				local fn = table.remove(queue, 1)
				local ok, err = pcall(fn)
				if not ok then
					warn("[Retention] popup: " .. tostring(err))
				end
				showing = false
				task.wait(0.6)
			end
		end
	end)

	-- Studio test switch: TestOpenWindow = "Daily" / "Quests" / "Settings" / "Top" / "Profile"
	if RunService:IsStudio() then
		workspace:GetAttributeChangedSignal("TestOpenWindow"):Connect(function()
			local v = workspace:GetAttribute("TestOpenWindow")
			if v == "Daily" then
				dailyWin.show()
			elseif v == "Quests" then
				questsWin.show()
			elseif v == "Settings" then
				settingsWin.show()
			elseif v == "Top" and ctx.Leaderboards then
				ctx.Leaderboards.open()
			elseif v == "Profile" and ctx.Social then
				ctx.Social.openProfile(player.UserId)
			end
		end)
	end
end

return R
