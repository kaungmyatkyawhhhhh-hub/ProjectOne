--[[
	RewardsClient (see server/Rewards.lua; owner, 2026-11-03: "Replace the casino with a rewards
	centre", "add wheel spin and super wheel spins too")
	  * the REWARDS pill on the HUD (under the goal tracker): how many things are ready, the time to
	    the next playtime gift; tap it for the rewards screen
	  * the rewards screen: a page per desk (DAILY, GIFTS, LEVELS, FRIENDS, CODES, PROPERTY,
	    ACHIEVEMENTS, SPIN, SUPER SPIN). The desks in Legends Rewards open their page; away from
	    the desks you can look, use a code, and set a waypoint to Legends Rewards
	  * the spins: reels of prize cards that roll and stop on the prizes (SPIN one reel, SUPER SPIN
	    three, brighter), the odds (ODDS), BUY WITH CASH / BUY WITH ROBUX (hidden where Roblox
	    restricts paid random items, or until the owner adds the Robux products)
	  * a popup, a sound and the amount on every claim
	Same look as the other screens (UI.kit). The server decides everything.
]]

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local TravelSpots = require(Shared:WaitForChild("TravelSpots"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local RewardsClient = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local kit = UI.kit
local new, label, button, corner, stroke, tween = kit.new, kit.label, kit.button, kit.corner, kit.stroke, kit.tween

local GOLD = Theme.Accent2
local call: RemoteFunction? = nil
local state: { [string]: any }? = nil
local stateAt = 0

local pill: TextButton? = nil
local pillText: TextLabel? = nil
local pillDot: Frame? = nil

local screen: Frame? = nil
local screenTab = "daily"
local refreshScreen: (() -> ())? = nil
local spinning = false
local previewSpin: (() -> ())? = nil -- (Studio previews: the open spin page's SPIN)

local TABS = {
	{ "daily", "DAILY" },
	{ "gifts", "GIFTS" },
	{ "levels", "LEVELS" },
	{ "friends", "FRIENDS" },
	{ "codes", "CODES" },
	{ "property", "PROPERTY" },
	{ "achievements", "ACHIEVE" },
	{ "wheel", "SPIN" },
	{ "super", "SUPER SPIN" },
}

local function clock(secs: number): string
	secs = math.max(0, math.floor(secs))
	local d = math.floor(secs / 86400)
	local h = math.floor(secs % 86400 / 3600)
	local m = math.floor(secs % 3600 / 60)
	local s = secs % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	end
	return if h > 0 then string.format("%d:%02d:%02d", h, m, s) else string.format("%d:%02d", m, s)
end

local function left(secs: number?): number
	return (secs or 0) - (os.clock() - stateAt)
end

local function invoke(what: string, arg: any?): any
	if not call then
		return nil
	end
	local ok, result = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	return if ok then result else nil
end

local function goThere()
	local spot = TravelSpots.get("rewards")
	if spot then
		Minimap.setWaypoint(spot.cf.Position)
		UI.toast("Waypoint set: Legends Rewards", GOLD)
	end
end

local setState: (any) -> ()

-- a claim: ask, then a popup, a sound and the amount (or why not)
local function claim(what: string, arg: any?): any
	local result = invoke(what, arg)
	if type(result) ~= "table" then
		UI.toast("Couldn't reach the server: try again", Theme.Danger)
		return nil
	end
	if type(result.state) == "table" then
		setState(result.state)
	end
	if not result.ok then
		UI.toast(tostring(result.message or "Not ready yet"), Theme.Warning)
		if result.far then
			goThere()
		end
		return result
	end
	if not result.quiet then
		local title = if type(result.what) == "string" then result.what elseif what == "daily" then "DAY " .. tostring(result.day) .. " STREAK" else "REWARD"
		if type(result.car) == "string" then
			UI.popup(title, 0, GOLD)
			UI.toast("The " .. result.car .. " is yours! It's in your CARS", GOLD)
		else
			UI.popup(title, tonumber(result.amount) or 0, GOLD)
		end
		Audio.cutUp(if result.big then 12 else 6, "REWARD")
		if result.big then
			UI.flash(GOLD)
		end
	end
	return result
end

---------------------------------------------------------------------
-- The HUD pill
---------------------------------------------------------------------
local function placePill()
	local p = pill
	if not p then
		return
	end
	local hud = p.Parent
	local tracker = hud and hud:FindFirstChild("GoalTracker") :: GuiObject?
	if UI.isTouch then
		-- (2026-11-04) on a phone with the tracker, left of the minimap, and only on foot: under it this
		-- button sat on the pedals and Roblox's jump button
		p.Visible = not Driving.isDriving()
		p.Position = UDim2.new(1, -154, 0, if tracker and tracker.Visible then 110 else 52)
	elseif tracker and tracker.Visible then
		p.Position = UDim2.new(1, -14, 0, tracker.AbsolutePosition.Y - (hud :: GuiObject).AbsolutePosition.Y + tracker.AbsoluteSize.Y + 8)
	else
		local map = player.PlayerGui:FindFirstChild("Minimap")
		local bottom = if map then map:GetAttribute("Bottom") else nil
		p.Position = UDim2.new(1, -14, 0, (if type(bottom) == "number" then bottom else 190) + 10)
	end
end

local function buildPill()
	local hud = UI.screen():FindFirstChild("HUD")
	if not hud then
		return
	end
	local w = if UI.isTouch then 196 else 248
	local p: TextButton = new("TextButton", {
		Name = "RewardsPill",
		AutoButtonColor = false,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(w, 34),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.12,
		Parent = hud,
	}, { corner(12), stroke(GOLD, 1.2, 0.45) })
	pill = p
	local area = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(28, 28), Parent = p })
	kit.icon("gift", area, 22, GOLD)
	pillText = label({ Text = "REWARDS", TextSize = if UI.isTouch then 11 else 13, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -60, 1, 0), Parent = p })
	pillDot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Money, Visible = false, Parent = p }, { corner(6) })
	p.Activated:Connect(function()
		Audio.click()
		RewardsClient.open(nil)
	end)
	placePill()
end

local function refreshPill()
	local st = state
	if not (pill and st) then
		return
	end
	local text = pillText :: TextLabel
	local ready = st.ready or 0
	local nextIn = st.gifts and st.gifts.nextPlayIn
	if ready > 0 then
		text.Text = string.format("REWARDS READY  ·  %d", ready)
	elseif nextIn then
		text.Text = "NEXT GIFT IN " .. clock(left(nextIn))
	else
		text.Text = "REWARDS"
	end
	(pillDot :: Frame).Visible = ready > 0
end

---------------------------------------------------------------------
-- The screen's pages
---------------------------------------------------------------------
local function row(parent: Instance, y: number, h: number, done: boolean): Frame
	return new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, -8, 0, h),
		BackgroundColor3 = if done then Theme.Background else Theme.PanelLight,
		BackgroundTransparency = if done then 0.4 else 0.1,
		ZIndex = 73,
		Parent = parent,
	}, { corner(10), stroke(if done then Theme.Money else Theme.Stroke, 1, if done then 0.55 else 0.4) })
end

local function text(parent: Instance, t: string, size: number, color: Color3?, props: { [string]: any }?): TextLabel
	local base = { Text = t, TextSize = size, Font = Enum.Font.GothamBold, TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, ZIndex = 74, Parent = parent }
	if props then
		for k, v in props do
			base[k] = v
		end
	end
	return label(base)
end

-- a row with a title, a line under it, the amount and a CLAIM button (or why it's not ready)
local function claimRow(parent: Instance, y: number, title: string, sub: string, amount: string, isReady: boolean, done: boolean, onClaim: () -> ())
	local r = row(parent, y, 64, done)
	text(r, title, 16, if done then Theme.SubText else Theme.Text, { Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -260, 0, 20) })
	text(r, sub, 12, Theme.SubText, { Position = UDim2.fromOffset(14, 32), Size = UDim2.new(1, -260, 0, 26) })
	text(r, amount, 16, if done then Theme.SubText else Theme.Money, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -132, 0.5, 0), Size = UDim2.fromOffset(110, 20) })
	local b = button(if done then "TAKEN" elseif isReady then "CLAIM" else "WAIT", if isReady then Theme.Money else Theme.Stroke, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(110, 42), TextSize = 16, ZIndex = 74, Parent = r })
	b.TextColor3 = if isReady and not done then Theme.Money else Theme.SubText
	if isReady and not done then
		b.Activated:Connect(onClaim)
	end
end

local function pageDaily(body: Frame): (() -> ())?
	local st = state :: any
	local s = st.daily
	if not s then
		text(body, "Loading...", 14, Theme.SubText, { Size = UDim2.new(1, 0, 0, 20) })
		return nil
	end
	local w = (body.AbsoluteSize.X > 0 and body.AbsoluteSize.X or 440)
	local gap = 6
	local box = math.floor((w - gap * 6) / 7)
	for d = 1, 7 do
		local reward = s.rewards[d]
		local isNext = d == s.day
		local past = d < s.day
		local f = new("Frame", {
			Position = UDim2.fromOffset((d - 1) * (box + gap), 4),
			Size = UDim2.fromOffset(box, 112),
			BackgroundColor3 = if isNext then GOLD:Lerp(Theme.Panel, 0.78) else Theme.PanelLight,
			BackgroundTransparency = if past then 0.5 else 0.08,
			ZIndex = 73,
			Parent = body,
		}, { corner(10), stroke(if isNext then GOLD elseif past then Theme.Money else Theme.Stroke, if isNext then 2 else 1, if past then 0.5 else 0.2) })
		text(f, "DAY " .. d, 11, if isNext then GOLD else Theme.SubText, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 14) })
		local area = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 46), ZIndex = 74, Parent = f })
		kit.icon(if reward == "car" then "car" else "gift", area, math.min(36, box - 14), if past then Theme.Money elseif reward == "car" then GOLD else Theme.Text)
		text(f, if reward == "car" then "FREE CAR" else UI.formatCash(reward :: number), 11, if reward == "car" then GOLD else Theme.Money, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, TextScaled = box < 56, Position = UDim2.new(0, 2, 1, -30), Size = UDim2.new(1, -4, 0, 16) })
	end
	text(body, "Come back every day. Day 7 gives you a free car you don't own yet.\nMiss more than 2 days and the streak starts again at day 1.", 13, Theme.SubText, { Position = UDim2.fromOffset(0, 128), Size = UDim2.new(1, 0, 0, 40) })
	local b = button("CLAIM", Theme.Money, { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	local busy = false
	local function tick()
		local l = left(s.readyIn)
		if busy then
			b.Text = "..."
		elseif l > 0 then
			b.Text = "DAY " .. s.day .. " READY IN " .. clock(l)
			b.TextColor3 = Theme.SubText
		else
			b.Text = "CLAIM DAY " .. s.day
			b.TextColor3 = Theme.Money
		end
	end
	b.Activated:Connect(function()
		if busy or left(s.readyIn) > 0 then
			return
		end
		busy = true
		tick()
		claim("daily")
		busy = false
	end)
	tick()
	return tick
end

local function pageGifts(body: Frame): (() -> ())?
	local g = (state :: any).gifts
	local y = 0
	text(body, "PLAYTIME TODAY: " .. clock(g.playSecs) .. "  ·  the gifts start again every day", 12, Theme.SubText, { Size = UDim2.new(1, 0, 0, 18) })
	y = 24
	for i, p in g.play do
		local isReady = not p.got and left(p.readyIn) <= 0
		claimRow(body, y, p.minutes .. " MINUTES PLAYED", if p.got then "Taken today" elseif isReady then "Ready" else "Opens in " .. clock(left(p.readyIn)), "+" .. UI.formatCash(p.cash), isReady, p.got, function()
			claim("play", i)
		end)
		y += 70
	end
	local weekReady = left(g.weeklyIn) <= 0
	claimRow(body, y, "WEEKLY GIFT", if weekReady then "Ready: once every 7 days" else "Next in " .. clock(left(g.weeklyIn)), "+" .. UI.formatCash(g.weekly), weekReady, false, function()
		claim("weekly")
	end)
	y += 70
	if g.returnReady then
		claimRow(body, y, "WELCOME BACK", "For coming back after a week away", "+" .. UI.formatCash(g.returnCash), true, false, function()
			claim("welcome")
		end)
	end
	return nil
end

local function pageLevels(body: Frame): (() -> ())?
	local lv = (state :: any).levels
	text(body, string.format("Every level you reach pays %s x the level here, and every %dth level opens a chest of %s x the level.", UI.formatCash(lv.cash), lv.every, UI.formatCash(lv.chest)), 13, Theme.SubText, { Size = UDim2.new(1, 0, 0, 36) })
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -104), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, #lv.list * 48), ZIndex = 72, Parent = body })
	for i, l in lv.list do
		local r = row(list, (i - 1) * 48, 42, false)
		text(r, "LEVEL " .. l.level .. (if l.chest > 0 then "   ·   CHEST" else ""), 15, if l.chest > 0 then GOLD else Theme.Text, { Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -150, 1, 0), TextYAlignment = Enum.TextYAlignment.Center })
		text(r, "+" .. UI.formatCash(l.cash + l.chest), 15, Theme.Money, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(130, 42), TextYAlignment = Enum.TextYAlignment.Center })
	end
	if #lv.list == 0 then
		text(body, "Nothing waiting. Level up to earn level rewards (you're level " .. lv.level .. ").", 14, Theme.SubText, { Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 40) })
	end
	local b = button(if #lv.list > 0 then "CLAIM " .. UI.formatCash(lv.total) else "NOTHING TO CLAIM", if #lv.list > 0 then Theme.Money else Theme.Stroke, { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	b.TextColor3 = if #lv.list > 0 then Theme.Money else Theme.SubText
	if #lv.list > 0 then
		b.Activated:Connect(function()
			claim("levels")
		end)
	end
	return nil
end

local function pageFriends(body: Frame): (() -> ())?
	local f = (state :: any).friends
	local y = 0
	claimRow(body, y, "FRIEND BONUS", if f.friendTaken then "Taken today" elseif f.friendReady then "A friend is in your server" else "Play in the same server as a friend (once a day)", "+" .. UI.formatCash(f.friendCash), f.friendReady, f.friendTaken, function()
		claim("friend")
	end)
	y += 70
	claimRow(body, y, "INVITE GIFT", if f.invites > 0 then "Your friend joined from your invite" else "Invite a friend: when they join for the first time, you both get this", "+" .. UI.formatCash(f.inviteCash), f.invites > 0, false, function()
		claim("invite")
	end)
	y += 70
	if f.group then
		claimRow(body, y, "GROUP GIFT", if f.groupGot then "Taken" elseif f.groupReady then "Thanks for joining the group" else "Join the game's group on Roblox (one time)", "+" .. UI.formatCash(f.groupCash), f.groupReady, f.groupGot, function()
			claim("group")
		end)
		y += 70
	end
	local inv = button("INVITE FRIENDS", Theme.Accent, { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	inv.Activated:Connect(function()
		local ok, can = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok and can then
			pcall(function()
				SocialService:PromptGameInvite(player)
			end)
		else
			UI.toast("Invites aren't available right now", Theme.Warning)
		end
	end)
	return nil
end

local function pageCodes(body: Frame): (() -> ())?
	text(body, "Got a code? Type it here (it works once). New codes come with updates.", 13, Theme.SubText, { Size = UDim2.new(1, 0, 0, 36) })
	local box: TextBox = new("TextBox", {
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = Theme.PanelLight,
		Text = "",
		PlaceholderText = "ENTER CODE",
		PlaceholderColor3 = Theme.SubText,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		ClearTextOnFocus = false,
		ZIndex = 74,
		Parent = body,
	}, { corner(10), stroke(GOLD, 1.5, 0.3) })
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = string.upper((string.gsub(box.Text, "[^%w]", "")))
		if #clean > 20 then
			clean = string.sub(clean, 1, 20)
		end
		if clean ~= box.Text then
			box.Text = clean
		end
	end)
	local b = button("REDEEM", Theme.Money, { Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	b.TextColor3 = Theme.Money
	local busy = false
	b.Activated:Connect(function()
		if busy or #box.Text < 4 then
			return
		end
		busy = true
		local r = claim("code", box.Text)
		if type(r) == "table" and r.ok then
			box.Text = ""
		end
		busy = false
	end)
	return nil
end

local function pageProperty(body: Frame): (() -> ())?
	local p = (state :: any).property
	local y = 0
	local anyReady = false
	if #p.rent == 0 then
		text(body, "No penthouse yet. A penthouse's wall safe pays rent every day: collect it here or at the safe.", 13, Theme.SubText, { Size = UDim2.new(1, 0, 0, 36) })
		y = 44
	end
	for _, r in p.rent do
		local isReady = left(r.readyIn) <= 0
		anyReady = anyReady or isReady
		local rr = row(body, y, 52, false)
		text(rr, r.name, 15, Theme.Text, { Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -170, 0, 20) })
		text(rr, if isReady then "The safe is full" else "Refills in " .. clock(left(r.readyIn)), 12, Theme.SubText, { Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -170, 0, 18) })
		text(rr, "+" .. UI.formatCash(r.rent), 15, if isReady then Theme.Money else Theme.SubText, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(140, 52), TextYAlignment = Enum.TextYAlignment.Center })
		y += 58
	end
	local suite = p.suite
	local sr = row(body, y, 52, false)
	text(sr, "HOTEL SUITE", 15, Theme.Text, { Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -20, 0, 20) })
	text(sr, if suite then suite.name .. " pays " .. UI.formatCash(suite.perMinute) .. " every minute you play, straight into your cash" else "Buy a suite at the Legends Grand Hotel: it pays every minute you play", 12, Theme.SubText, { Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -20, 0, 18) })
	local b = button(if anyReady then "COLLECT RENT" else "NO SAFE READY", if anyReady then Theme.Money else Theme.Stroke, { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	b.TextColor3 = if anyReady then Theme.Money else Theme.SubText
	if anyReady then
		b.Activated:Connect(function()
			claim("rent")
		end)
	end
	return nil
end

local function pageAchievements(body: Frame): (() -> ())?
	local a = (state :: any).achievements
	if not a then
		return nil
	end
	text(body, string.format("LEGENDS PATH: %d OF %d DONE  ·  each goal pays the moment you finish it", a.done, a.total), 12, Theme.SubText, { Size = UDim2.new(1, 0, 0, 18) })
	local list = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 1, -24), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, #a.path * 48), ZIndex = 72, Parent = body })
	local first: number? = nil
	for i, g in a.path do
		local r = row(list, (i - 1) * 48, 42, g.done)
		text(r, (if g.done then "✓  " else "") .. g.text, 14, if g.done then Theme.SubText else Theme.Text, { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -150, 1, 0), TextYAlignment = Enum.TextYAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
		text(r, "+" .. UI.formatCash(g.cash), 14, if g.done then Theme.SubText else Theme.Money, { Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0), Size = UDim2.fromOffset(120, 42), TextYAlignment = Enum.TextYAlignment.Center })
		if not g.done and not first then
			first = i
		end
	end
	if first then
		list.CanvasPosition = Vector2.new(0, math.max(0, (first - 2) * 48))
	end
	return nil
end

-- the spins (owner, 2026-11-03: reels of prize cards like a wheelspin, the SUPER one more exciting):
-- columns of cards that roll and stop one after the other on the prizes the server picked
local CARD_H, CARD_GAP = 92, 8
local STRIP = 34 -- cards in a rolling strip (the prize is the last but two)

local function cashText(n: number): string
	if n >= 1000000 then
		return string.format("$%gM", n / 1000000)
	elseif n >= 1000 then
		return string.format("$%gK", n / 1000)
	end
	return UI.formatCash(n)
end

-- one prize card: cash (green, gold for the rare ones), a car (blue), a jewel (purple), an extra
-- spin (pink); `name` is the won car's or jewel's name
local function card(parent: Instance, y: number, o: any, name: string?)
	local isCar = o.car == true
	local isPart = o.part ~= nil
	local isFlex = o.flex == true or isPart
	local isSpin = o.spin == true
	local bigOne = not isCar and not isFlex and not isSpin and (o.percent or 100) <= 2
	local top = if isCar then Color3.fromRGB(120, 220, 255) elseif isFlex then Color3.fromRGB(220, 170, 255) elseif isSpin then Color3.fromRGB(255, 160, 210) elseif bigOne then Color3.fromRGB(255, 220, 90) else Color3.fromRGB(214, 250, 96)
	local bottom = if isCar then Color3.fromRGB(40, 140, 230) elseif isFlex then Color3.fromRGB(140, 60, 220) elseif isSpin then Color3.fromRGB(230, 60, 140) elseif bigOne then Color3.fromRGB(240, 150, 40) else Color3.fromRGB(150, 220, 40)
	local c = new("Frame", { Position = UDim2.new(0, 6, 0, y), Size = UDim2.new(1, -12, 0, CARD_H), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 76, Parent = parent }, {
		corner(10),
		new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = 90 }),
		stroke(Color3.new(1, 1, 1), 2, 0.3),
	})
	local plate = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -16, 0, 50), BackgroundColor3 = Color3.fromRGB(250, 250, 246), ZIndex = 77, Parent = c }, { corner(8) })
	if isCar or isFlex or isSpin then
		local area = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(44, 44), ZIndex = 78, Parent = plate })
		kit.icon(if isCar then "car" else "gift", area, 34, if isCar then Color3.fromRGB(30, 60, 110) elseif isFlex then Color3.fromRGB(110, 40, 170) else Color3.fromRGB(170, 30, 100))
		label({ Text = name or (if isCar then "FREE CAR" elseif isPart then string.upper(tostring(o.part)) .. " PART" elseif isFlex then "JEWEL" else "+1 SPIN"), TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(20, 30, 50), Position = UDim2.fromOffset(50, 8), Size = UDim2.new(1, -56, 1, -16), ZIndex = 78, Parent = plate })
	else
		local area = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(44, 44), ZIndex = 78, Parent = plate })
		kit.icon("gift", area, 30, if bigOne then Color3.fromRGB(200, 120, 20) else Color3.fromRGB(60, 120, 30))
		label({ Text = cashText(o.cash or 0), TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(20, 24, 20), Position = UDim2.fromOffset(44, 6), Size = UDim2.new(1, -50, 1, -12), ZIndex = 78, Parent = plate })
	end
	return c
end

-- a random prize by the odds (for the cards rolling past)
local function randomOdd(odds: { any }): any
	local roll = math.random() * 100
	for _, o in odds do
		roll -= o.percent
		if roll <= 0 then
			return o
		end
	end
	return odds[1]
end

local function pageWheel(body: Frame, id: string): (() -> ())?
	local w = (state :: any).wheels[id]
	if not w then
		return nil
	end
	local super = id == "super"
	local n = if super then 3 else 1
	-- the stage: a bright gradient that turns slowly (the super one hotter, with sparkles)
	local stage = new("Frame", { Size = UDim2.new(1, 0, 1, -58), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 73, Parent = body }, { corner(12) })
	local grad = new("UIGradient", {
		Color = if super then ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 160)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 60)) }) else ColorSequence.new(Color3.fromRGB(70, 160, 255), Color3.fromRGB(30, 60, 160)),
		Rotation = 30,
		Parent = stage,
	})
	-- sun rays behind everything
	for k = 0, 11 do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 34, 2, 0), Rotation = k * 15, BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 73, Parent = stage })
	end
	stage.ClipsDescendants = true
	-- the title and the spins counter on the left
	local leftW = if super then 128 else 150
	local title = label({ Text = if super then "SUPER\nSPIN" else "SPIN", TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.fromOffset(10, 14), Size = UDim2.fromOffset(leftW - 16, if super then 96 else 60), ZIndex = 80, Parent = stage })
	title.TextStrokeColor3 = Color3.fromRGB(90, 20, 60)
	title.TextStrokeTransparency = 0
	local counter = new("Frame", { Position = UDim2.fromOffset(16, if super then 128 else 96), Size = UDim2.fromOffset(leftW - 28, 70), BackgroundColor3 = Color3.fromRGB(250, 250, 246), ZIndex = 80, Parent = stage }, { corner(10), stroke(Color3.fromRGB(40, 40, 50), 2, 0) })
	local count = label({ Text = "0", TextSize = 34, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(20, 20, 26), Size = UDim2.new(1, 0, 0, 44), ZIndex = 81, Parent = counter })
	label({ Text = "SPINS LEFT", TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(80, 80, 90), Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 18), ZIndex = 81, Parent = counter })
	local freeLbl = label({ Text = "", TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true, Position = UDim2.fromOffset(10, if super then 204 else 172), Size = UDim2.fromOffset(leftW - 16, 34), ZIndex = 80, Parent = stage })
	local oddsBtn = button("ODDS", Color3.new(1, 1, 1), { Position = UDim2.fromOffset(16, if super then 244 else 212), Size = UDim2.fromOffset(leftW - 28, 32), TextSize = 13, ZIndex = 80, Parent = stage })
	-- the reels
	local reelsArea = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(leftW, 10), Size = UDim2.new(1, -leftW - 10, 1, -20), ZIndex = 74, Parent = stage })
	local columns: { Frame } = {}
	local strips: { Frame } = {}
	for r = 1, n do
		local col = new("Frame", {
			Position = UDim2.new((r - 1) / n, 4, 0, 0),
			Size = UDim2.new(1 / n, -8, 1, 0),
			BackgroundColor3 = Color3.fromRGB(70, 20, 50),
			BackgroundTransparency = 0.2,
			ClipsDescendants = true,
			ZIndex = 75,
			Parent = reelsArea,
		}, { corner(12), stroke(Color3.new(1, 1, 1), 3, 0.1) })
		table.insert(columns, col)
		local strip = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, STRIP * (CARD_H + CARD_GAP)), ZIndex = 75, Parent = col })
		table.insert(strips, strip)
	end
	-- the pointers either side of the middle line
	for _, side in { 0, 1 } do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(side, 0, 0.5, 0), Size = UDim2.fromOffset(18, 18), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 79, Parent = reelsArea }, { stroke(Color3.fromRGB(90, 20, 60), 2, 0) })
	end
	-- where a strip sits so its card i (1-based) is in the middle of the column
	local function offsetFor(col: Frame, i: number): number
		local h = col.AbsoluteSize.Y > 0 and col.AbsoluteSize.Y or 330
		return h / 2 - ((i - 1) * (CARD_H + CARD_GAP) + CARD_H / 2)
	end
	-- fill a strip with random cards, the given prize (if any) at slot `at`; returns the prize card
	local function fill(r: number, at: number?, prize: any?): Frame?
		local strip = strips[r]
		strip:ClearAllChildren()
		local won: Frame? = nil
		for i = 1, STRIP do
			local y = (i - 1) * (CARD_H + CARD_GAP)
			if at and i == at and prize then
				local o = w.odds[prize.index] or randomOdd(w.odds)
				local shown = if prize.car then { car = true } elseif prize.flex then { flex = true } elseif prize.part then { part = prize.part } elseif prize.spin then { spin = true } else { cash = prize.cash, percent = o.percent }
				won = card(strip, y, shown, prize.car or prize.flex or prize.part)
			else
				card(strip, y, randomOdd(w.odds), nil)
			end
		end
		return won
	end
	for r = 1, n do
		fill(r, nil, nil)
		strips[r].Position = UDim2.fromOffset(0, offsetFor(columns[r], 3))
	end
	-- the odds (Roblox's rule: shown before you spin)
	local oddsPanel: Frame? = nil
	oddsBtn.Activated:Connect(function()
		if oddsPanel then
			oddsPanel:Destroy()
			oddsPanel = nil
			return
		end
		local op = new("Frame", { Position = UDim2.fromOffset(leftW, 10), Size = UDim2.new(1, -leftW - 10, 1, -20), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.05, ZIndex = 90, Parent = stage }, { corner(12), stroke(GOLD, 2, 0) })
		oddsPanel = op
		label({ Text = "THE ODDS  ·  " .. (if n > 1 then "each of the 3 reels" else "the reel"), TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 18), ZIndex = 91, Parent = op })
		for k, o in w.odds do
			local prize = if o.car then "A free car (or " .. UI.formatCash(o.carCash or 0) .. ")" elseif o.flex then "A Gem Showcase jewel (or " .. UI.formatCash(o.flexCash or 0) .. ")" elseif o.part then "A free " .. tostring(o.part) .. " part" elseif o.spin then "One more spin" else UI.formatCash(o.cash)
			label({ Text = prize, TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 32 + (k - 1) * 21), Size = UDim2.new(1, -110, 0, 20), ZIndex = 91, Parent = op })
			label({ Text = tostring(o.percent) .. "%", TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 32 + (k - 1) * 21), Size = UDim2.fromOffset(80, 20), ZIndex = 91, Parent = op })
		end
	end)
	-- the buttons under the stage
	local spin = button("SPIN", Theme.Money, { Position = UDim2.new(0, 0, 1, -50), Size = UDim2.new(0.5, -4, 0, 48), TextSize = 20, ZIndex = 74, Parent = body })
	local buyRow = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 1, -50), Size = UDim2.new(0.5, -4, 0, 48), ZIndex = 74, Parent = body })
	if w.canBuy then
		local hasRobux = w.productId ~= 0
		local buyCash = button("BUY 1  ·  " .. cashText(w.cashPrice), GOLD, { Size = UDim2.new(if hasRobux then 0.5 else 1, if hasRobux then -3 else 0, 1, 0), TextSize = 13, ZIndex = 74, Parent = buyRow })
		buyCash.TextColor3 = GOLD
		buyCash.Activated:Connect(function()
			if not spinning then
				claim("buy", id)
			end
		end)
		if hasRobux then
			local buyRobux = button("BUY 1  ·  ROBUX", Theme.Accent, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.5, -3, 1, 0), TextSize = 13, ZIndex = 74, Parent = buyRow })
			buyRobux.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, w.productId)
			end)
		end
	else
		label({ Text = "Free spins only", TextSize = 13, TextColor3 = Theme.SubText, Size = UDim2.fromScale(1, 1), ZIndex = 74, Parent = buyRow })
	end
	local function tick()
		local freeIn = left(w.freeIn)
		local spins = (w.spins or 0) + (if freeIn <= 0 then 1 else 0)
		count.Text = tostring(spins)
		freeLbl.Text = if freeIn <= 0 then "A FREE SPIN IS READY" else "NEXT FREE SPIN\n" .. clock(freeIn)
		spin.Text = if spinning then "SPINNING..." elseif spins > 0 then (if freeIn <= 0 then "SPIN (FREE)" else "SPIN") else "NO SPINS LEFT"
		spin.TextColor3 = if spins > 0 and not spinning then Theme.Money else Theme.SubText
		if super then
			grad.Rotation = (os.clock() * 12) % 360
		end
	end
	local function doSpin()
		if spinning then
			return
		end
		if left(w.freeIn) > 0 and (w.spins or 0) <= 0 then
			UI.toast("No spins left: buy one, or wait for the free spin", Theme.Warning)
			return
		end
		if oddsPanel then
			oddsPanel:Destroy()
			oddsPanel = nil
		end
		spinning = true
		tick()
		local result = invoke("spin", id)
		if type(result) ~= "table" or not result.ok or type(result.reels) ~= "table" then
			spinning = false
			if type(result) == "table" then
				UI.toast(tostring(result.message or "Can't spin now"), Theme.Warning)
				if result.far then
					goThere()
				end
			end
			tick()
			return
		end
		-- each reel rolls from the top of a fresh strip down to its prize, stopping one by one
		local stopAt = STRIP - 2
		local done = 0
		for r = 1, n do
			local prize = result.reels[r]
			local won = fill(r, stopAt, prize)
			local strip = strips[r]
			strip.Position = UDim2.fromOffset(0, offsetFor(columns[r], 3))
			local last = 3
			local conn = strip:GetPropertyChangedSignal("Position"):Connect(function()
				local passed = math.floor((offsetFor(columns[r], 3) - strip.Position.Y.Offset) / (CARD_H + CARD_GAP))
				if passed ~= last then
					last = passed
					Audio.play("tick", 0.3, 1.3 + r * 0.1)
				end
			end)
			local t = tween(strip, 2.4 + r * 0.7, { Position = UDim2.fromOffset(0, offsetFor(columns[r], stopAt)) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			t.Completed:Connect(function()
				conn:Disconnect()
				done += 1
				-- the card that won pops
				if won then
					local sc = new("UIScale", { Scale = 1, Parent = won })
					tween(sc, 0.15, { Scale = 1.12 }).Completed:Connect(function()
						tween(sc, 0.25, { Scale = 1 })
					end)
				end
				Audio.cutUp(4 + r * 2, "REEL")
				if prize and (prize.car or prize.flex or prize.part or (w.odds[prize.index] and w.odds[prize.index].percent <= 2)) then
					UI.flash(GOLD)
				end
			end)
		end
		while done < n and screen do
			task.wait(0.1)
		end
		task.wait(0.4)
		if type(result.car) == "string" then
			UI.toast("You won the " .. result.car .. "! It's in your CARS", GOLD)
		end
		for _, rr in result.reels do
			if type(rr.flex) == "string" then
				UI.toast("You won the " .. rr.flex .. "! Wear it from the Gem Showcase", GOLD)
			elseif type(rr.part) == "string" then
				UI.toast("You won the " .. rr.part .. "! It's in My Parts at the workshop", GOLD)
			elseif rr.spin then
				UI.toast("+1 " .. (if super then "SUPER SPIN" else "SPIN"), GOLD)
			end
		end
		UI.popup(if super then "SUPER SPIN" else "SPIN", tonumber(result.amount) or 0, GOLD)
		Audio.cutUp(if result.big then 12 else 8, "SPIN")
		if result.big then
			UI.flash(GOLD)
		end
		spinning = false
		if type(result.state) == "table" then
			setState(result.state)
		end
	end
	spin.Activated:Connect(doSpin)
	previewSpin = doSpin
	tick()
	return tick
end

---------------------------------------------------------------------
-- The screen
---------------------------------------------------------------------
local function closeScreen()
	if screen then
		screen:Destroy()
		screen = nil
	end
	refreshScreen = nil
end

-- (2026-11-04) the pages with something you're in the middle of: a list you've scrolled, a code half
-- typed, the odds open. The server's push every 30 s leaves these as they are, unless what they show
-- changed. It keeps the old state, clocks included, so their countdowns stay right
local KEEP_PAGE = { codes = true, levels = true, achievements = true, wheel = true, super = true }
local function shownKey(st: any): string
	local w = st.wheels or {}
	return table.concat({
		tostring(st.ready),
		tostring(st.levels and st.levels.total),
		tostring(st.achievements and st.achievements.done),
		tostring(w.wheel and w.wheel.spins),
		tostring(w.super and w.super.spins),
	}, "|")
end

function RewardsClient.open(tab: string?)
	if screen then
		closeScreen()
		if not tab then
			return
		end
	end
	if not state then
		local r = invoke("state")
		if type(r) == "table" and type(r.state) == "table" then
			setState(r.state)
		else
			UI.toast("Rewards are still loading: try again", Theme.Warning)
			return
		end
	end
	screenTab = tab or screenTab
	local back = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = UI.screen() })
	screen = back
	local w, h = 700, 500
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		ZIndex = 71,
		Parent = back,
	}, { corner(14), stroke(Theme.Stroke, 1.5, 0.1) })
	local sc = new("UIScale", { Parent = f })
	local function fit()
		local vp = camera.ViewportSize
		sc.Scale = math.min(1, (vp.X - 24) / w, (vp.Y - 24) / h)
	end
	fit()
	label({ Text = "LEGENDS REWARDS", TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -260, 0, 30), ZIndex = 72, Parent = f })
	local sub = label({ Text = "", TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 44), Size = UDim2.new(1, -260, 0, 16), ZIndex = 72, Parent = f })
	local x = button("×", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44), TextSize = 20, ZIndex = 72, Parent = f })
	x.Activated:Connect(closeScreen)
	local go = button("WAYPOINT", GOLD, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -64, 0, 12), Size = UDim2.fromOffset(120, 44), TextSize = 14, ZIndex = 72, Parent = f })
	go.TextColor3 = GOLD
	go.Activated:Connect(goThere)
	-- the pages down the left
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(170, 72), Size = UDim2.new(1, -190, 1, -88), ZIndex = 72, Parent = f })
	local tabButtons: { [string]: TextButton } = {}
	local ticker: (() -> ())? = nil
	local function show(which: string)
		screenTab = which
		for id, b in tabButtons do
			b.TextColor3 = if id == which then GOLD else Theme.SubText
			b.BackgroundColor3 = if id == which then GOLD:Lerp(Theme.PanelLight, 0.82) else Theme.PanelLight
		end
		body:ClearAllChildren()
		ticker = nil
		local builders: { [string]: (Frame) -> (() -> ())? } = {
			daily = pageDaily,
			gifts = pageGifts,
			levels = pageLevels,
			friends = pageFriends,
			codes = pageCodes,
			property = pageProperty,
			achievements = pageAchievements,
			wheel = function(b2)
				return pageWheel(b2, "wheel")
			end,
			super = function(b2)
				return pageWheel(b2, "super")
			end,
		}
		local fn = builders[which]
		if fn then
			ticker = fn(body)
		end
		local st = state :: any
		sub.Text = string.format("%d READY  ·  claim at the desks in Legends Rewards (codes work anywhere)", st.ready or 0)
	end
	for i, t in TABS do
		local b = button(t[2], GOLD, { Position = UDim2.fromOffset(16, 72 + (i - 1) * 46), Size = UDim2.fromOffset(140, 40), TextSize = 13, ZIndex = 72, Parent = f })
		tabButtons[t[1]] = b
		b.Activated:Connect(function()
			show(t[1])
		end)
	end
	refreshScreen = function()
		-- (2026-11-04) CODES shows no state: a claim's answer wiped a mistyped code before you could fix it
		if not spinning and screenTab ~= "codes" then
			show(screenTab)
		end
	end
	show(screenTab)
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not back.Parent then
			conn:Disconnect()
			return
		end
		if ticker then
			ticker()
		end
	end)
end

setState = function(st: any)
	state = st
	stateAt = os.clock()
	refreshPill()
	if refreshScreen and screen then
		refreshScreen()
	end
end

function RewardsClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("RewardsCall", 30) :: RemoteFunction?
	local push = remotes:WaitForChild("RewardsPush", 30) :: RemoteEvent?
	buildPill()
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) ~= "table" then
				return
			end
			if msg.kind == "state" and type(msg.state) == "table" then
				local keep = screen ~= nil and state ~= nil and KEEP_PAGE[screenTab] == true and shownKey(msg.state) == shownKey(state)
				if not keep then
					setState(msg.state)
				end
			elseif msg.kind == "gift" then
				UI.toast(string.format("Playtime gift ready (%d minutes): claim it at Legends Rewards", tonumber(msg.minutes) or 0), GOLD)
				Audio.cutUp(4, "GIFT")
			elseif msg.kind == "bought" then
				UI.popup(tostring(msg.what or "SPIN"), 0, GOLD)
				Audio.cutUp(6, "BOUGHT")
			end
		end)
	end
	task.spawn(function()
		local r = invoke("state")
		if type(r) == "table" and type(r.state) == "table" then
			setState(r.state)
		end
	end)
	-- the desks open their page
	ProximityPromptService.PromptTriggered:Connect(function(p: ProximityPrompt)
		if CollectionService:HasTag(p, "RewardsDesk") then
			local tab = p:GetAttribute("Tab")
			RewardsClient.open(if type(tab) == "string" then tab else "daily")
		end
	end)
	-- Studio previews (Claude's screenshots): workspace attribute PreviewRewards = a page to open
	if RunService:IsStudio() then
		workspace:GetAttributeChangedSignal("PreviewRewards"):Connect(function()
			local t = workspace:GetAttribute("PreviewRewards")
			if type(t) == "string" then
				RewardsClient.open(t)
			end
		end)
		workspace:GetAttributeChangedSignal("PreviewSpin"):Connect(function()
			if workspace:GetAttribute("PreviewSpin") and previewSpin then
				task.spawn(previewSpin :: () -> ())
			end
		end)
	end
	-- the pill follows the goal tracker, and counts down
	task.spawn(function()
		while true do
			task.wait(0.5)
			placePill()
			refreshPill()
		end
	end)
end

return RewardsClient
