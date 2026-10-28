-- StoreController (M5, GDD 20): the STORE window (PASSES / COINS / BOOSTS), the small offer card,
-- the AUTO button on the training panel (+ the Auto Train AFK check) and the VIP chat tag.
-- Fair rules: offers only at calm moments (after a race's results, never during one, never in the
-- tutorial), at most one card per 10 min, prices = Roblox's real prices.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local Formulas = require(Shared.Util.Formulas)
local Store = require(Shared.Config.Store)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local StoreUI = {}
local ctx, canvas
local win, grid, setTab, header
local tab = "PASSES"
local st = nil -- { Passes, Purchases, StarterEligible, Prices }
local offer, offerTitle, offerText, offerBuy, offerBuyLabel, offerKey
local lastOfferAt = -math.huge
local afkCard
local autoBtn, autoLabel
local tapStartedAt = nil
local tapSeconds = 0
local autoOffered = false

local function price(item)
	return (st and st.Prices and st.Prices[item.Key]) or item.Price
end

local function owned(key)
	return st ~= nil and st.Passes[key] == true
end

local function icon(parent, spec, size)
	local c = make("Frame", { BackgroundColor3 = P.White, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(size, size), Parent = parent })
	UIKit.corner(c, UDim.new(0.5, 0))
	local color = Color3.fromHex(spec[2])
	UIKit.gradient(c, color:Lerp(P.White, 0.3), color:Lerp(P.SpeedBlack, 0.35), 135)
	UIKit.stroke(c, P.White, 2, 0.3)
	UIKit.text({ Text = spec[1], TextSize = if #spec[1] > 4 then 13 else 22, Color = P.White, StrokeThickness = 2, StrokeTransparency = 0, Parent = c })
	return c
end

----------------------------------------------------------------------------
-- buying
----------------------------------------------------------------------------
local function buy(item, isPass)
	local ok, why = ctx.Net.call(if isPass then "BuyPass" else "BuyProduct", item.Key)
	if not ok then
		ctx.Hud.toast(if why == "soon" then "Coming very soon!" elseif why == "owned" then "You already own this" elseif why == "needs" then "Get EXTRA COACH SLOT first" elseif why == "gone" then "The Starter Pack is gone for you" else "Can't buy that right now", "Denied")
	end
end

local function card(item, isPass)
	local c = make("Frame", { Name = item.Key, BackgroundColor3 = P.White, Size = UDim2.fromOffset(160, 196) })
	UIKit.corner(c, 12)
	local isOwned = isPass and owned(item.Key)
	UIKit.gradient(c, if item.Hero then P.DeepBlue else P.Graphite, P.Carbon, 90)
	UIKit.stroke(c, if isOwned then P.ElectricBlue elseif item.Hero or item.Key == "StarterPack" then P.Gold else P.Graphite, 2)
	if isPass then
		icon(c, item.Icon, 54)
	elseif item.Tab == "COINS" then
		local ci = UIKit.coinIcon(50, c)
		ci.Position = UDim2.new(0.5, -25, 0, 8)
	else
		icon(c, if item.Key == "StarterPack" then { "START", "#FFC83D" } else { "2x", "#1E7BFF" }, 54)
	end
	UIKit.text({ Text = item.Name, TextSize = 15, Wrapped = true, Position = UDim2.fromOffset(6, 64), Size = UDim2.new(1, -12, 0, 20), Parent = c })
	local desc = item.Desc
	if item.Tab == "COINS" then
		desc = ("%s coins (%s)"):format(Format.short(Formulas.minutesOfCoins(item.Minutes, player:GetAttribute("League") or 1)), item.Desc)
	end
	UIKit.text({ Text = desc, Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, Wrapped = true, YAlign = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(8, 86), Size = UDim2.new(1, -16, 0, 62), Parent = c })
	local soon = item.Id <= 0
	local label
	if isOwned then
		label = "OWNED"
	elseif item.Key == "StarterPack" and st and not st.StarterEligible then
		label = "GONE"
	elseif soon then
		label = ("SOON  R$ %d"):format(price(item)) -- not created in Creator Hub yet
	else
		label = ("R$ %d"):format(price(item))
	end
	local style = if isOwned or label == "GONE" or soon then "Dark" else "Gold"
	UIKit.button({ Name = "Buy", Style = style, Text = label, TextSize = 16, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -14, 0, 36), Parent = c, OnClick = function()
		if not isOwned and label ~= "GONE" then
			buy(item, isPass)
		end
	end })
	return c
end

local function rebuild()
	if not win then
		return
	end
	for _, ch in grid:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local i = 0
	if tab == "PASSES" then
		for _, p in Store.Passes do
			i += 1
			local c = card(p, true)
			c.LayoutOrder = i
			c.Parent = grid
		end
		header.Text = "Passes are forever. They never win a race for you."
	else
		for _, p in Store.Products do
			if p.Tab == tab and not (p.Key == "StarterPack" and st and not st.StarterEligible and (st.Purchases.StarterPack or 0) == 0) then
				i += 1
				local c = card(p, false)
				c.LayoutOrder = i
				c.Parent = grid
			end
		end
		header.Text = if tab == "COINS" then "Coin packs grow with your league." else "Boosts count down only while you play."
	end
end

local function refresh()
	local ok, s = ctx.Net.call("StoreState")
	if ok and s then
		st = s
		player:SetAttribute("StarterEligible", s.StarterEligible)
	end
	if win.isOpen() then
		rebuild()
	end
end

function StoreUI.open(which)
	tab = which or tab
	win.show()
	setTab(tab)
	task.spawn(refresh)
end

----------------------------------------------------------------------------
-- the small offer card (bottom centre), at calm moments only
----------------------------------------------------------------------------
local function calm()
	if player:GetAttribute("InRace") or ctx.Training.isTraining() then
		return false
	end
	if ctx.Tutorial and ctx.Tutorial.active() then
		return false
	end
	for _, ch in canvas:GetChildren() do
		if (ch.Name:match("Backdrop$") or ch.Name == "CoachReveal" or ch.Name == "GoProScene" or ch.Name == "RankUp" or ch.Name == "RetentionPopup") and ch.Visible then
			return false
		end
	end
	return os.clock() - lastOfferAt >= Store.OfferGapSeconds
end

local function showOffer(key)
	local item
	for _, p in Store.Products do
		if p.Key == key then
			item = p
		end
	end
	for _, p in Store.Passes do
		if p.Key == key then
			item = p
		end
	end
	if not item or item.Id <= 0 and not RunService:IsStudio() then
		return false -- nothing to buy yet (Studio still shows it so it can be checked)
	end
	lastOfferAt = os.clock()
	offerKey = key
	offerTitle.Text = item.Name
	offerText.Text = item.Desc
	offerBuyLabel.Text = if item.Id > 0 then ("R$ %d"):format(price(item)) else "SOON"
	offer.Visible = true
	ctx.Sound.play("Toast")
	task.spawn(ctx.Net.call, "OfferShown", key)
	task.delay(9, function()
		if offerKey == key then
			offer.Visible = false
			offerKey = nil
		end
	end)
	return true
end
StoreUI.showOffer = showOffer

local function buildOffer()
	offer = UIKit.panel({ Name = "Offer", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.fromOffset(400, 86), AccentColor = P.Gold, StrokeColor = P.Gold, ZIndex = 14, Parent = canvas })
	offer.Visible = false
	offerTitle = UIKit.text({ Text = "", TextSize = 17, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -180, 0, 22), ZIndex = 15, Parent = offer })
	offerText = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 13, Wrapped = true, XAlign = Enum.TextXAlignment.Left, YAlign = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(18, 30), Size = UDim2.new(1, -180, 0, 50), ZIndex = 15, Parent = offer })
	offerBuy, offerBuyLabel = UIKit.button({ Style = "Gold", Text = "BUY", TextSize = 16, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -58, 0.5, 0), Size = UDim2.fromOffset(104, 44), ZIndex = 15, Parent = offer, OnClick = function()
		local key = offerKey
		offer.Visible = false
		offerKey = nil
		for _, p in Store.Passes do
			if p.Key == key then
				return buy(p, true)
			end
		end
		for _, p in Store.Products do
			if p.Key == key then
				return buy(p, false)
			end
		end
	end })
	UIKit.button({ Style = "Dark", Text = "X", TextSize = 16, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(42, 42), ZIndex = 15, Parent = offer, OnClick = function()
		offer.Visible = false
		offerKey = nil
	end })
end

----------------------------------------------------------------------------
-- AUTO button + AFK check
----------------------------------------------------------------------------
local function updateAuto()
	if not autoBtn then
		return
	end
	local has = owned("AutoTrain")
	local on = player:GetAttribute("AutoTrain") == true
	autoLabel.Text = if not has then "AUTO" elseif on then "AUTO ON" else "AUTO OFF"
	UIKit.setButtonStyle(autoBtn, if on then "Gold" else "Blue")
end

local function buildAuto()
	local holder = ctx.Hud.refs.training
	if not holder then
		return
	end
	autoBtn, autoLabel = UIKit.button({ Name = "Auto", Style = "Blue", Text = "AUTO", TextSize = 16, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.fromOffset(92, 50), Parent = holder, OnClick = function()
		if not owned("AutoTrain") then
			StoreUI.open("PASSES")
			return
		end
		local ok, on = ctx.Net.call("SetAutoTrain", player:GetAttribute("AutoTrain") ~= true)
		if ok then
			ctx.Hud.toast(if on then "Auto Train ON: it taps for you" else "Auto Train OFF", "Gold")
		end
	end })
	player:GetAttributeChangedSignal("AutoTrain"):Connect(updateAuto)

	afkCard = UIKit.panel({ Name = "AfkCheck", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(360, 110), AccentColor = P.Gold, StrokeColor = P.Gold, ZIndex = 35, Parent = canvas })
	afkCard.Visible = false
	UIKit.text({ Text = "STILL TRAINING?", TextSize = 22, Color = P.Gold, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 28), ZIndex = 36, Parent = afkCard })
	UIKit.button({ Style = "Gold", Text = "YES, KEEP GOING", TextSize = 16, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 46), Size = UDim2.fromOffset(220, 48), ZIndex = 36, Parent = afkCard, OnClick = function()
		afkCard.Visible = false
		task.spawn(ctx.Net.call, "AfkOk")
	end })
end

----------------------------------------------------------------------------
function StoreUI.start(c)
	ctx = c
	ctx.Store = StoreUI
	canvas = ctx.Hud.canvas

	win = UIKit.window({ Name = "Store", Title = "STORE", Size = Vector2.new(720, 330), Accent = P.Gold, Parent = canvas })
	setTab = UIKit.tabs(win.content, { "PASSES", "COINS", "BOOSTS" }, function(name)
		tab = name
		rebuild()
	end)
	header = UIKit.text({ Text = "", Font = F.Body, TextSize = 14, XAlign = Enum.TextXAlignment.Right, Position = UDim2.new(1, -330, 0, 8), Size = UDim2.fromOffset(330, 22), Parent = win.content })
	grid = make("ScrollingFrame", { Name = "Grid", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 6, ScrollBarImageColor3 = P.Gold, Parent = win.content })
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	make("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = grid })

	-- the STORE button (left menu, under COACHES) and a "+" on the coins pill
	local menu = ctx.Hud.refs.menu
	if menu then
		local storeBtn = UIKit.button({ Name = "Store", Style = "Gold", Text = "STORE", TextSize = 18, Size = UDim2.fromOffset(124, 44), Parent = menu, OnClick = function()
			StoreUI.open("PASSES")
		end })
		storeBtn.LayoutOrder = 3
		local small = menu:FindFirstChild("Small")
		if small then
			small.LayoutOrder = 4
		end
		for _, b in menu:GetChildren() do
			if b:IsA("GuiButton") then
				b.Size = UDim2.fromOffset(124, 44)
			end
		end
		menu.Size = UDim2.fromOffset(124, 44 * 3 + 36 + 30)
		menu.AnchorPoint = Vector2.new(0, 0)
		menu.Position = UDim2.fromOffset(14, 154)
		local layout = menu:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.Padding = UDim.new(0, 8)
		end
	end
	local coins = ctx.Hud.refs.coins
	if coins then
		UIKit.button({ Name = "Plus", Style = "Gold", Text = "+", TextSize = 22, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -5, 0.5, 0), Size = UDim2.fromOffset(34, 34), Radius = 17, EdgeHeight = 3, Parent = coins, OnClick = function()
			StoreUI.open("COINS")
		end })
	end

	buildOffer()
	buildAuto()

	ctx.Net.get("StoreEvent").OnClientEvent:Connect(function(kind)
		if kind == "bought" then
			ctx.Sound.play("KaChing")
			task.spawn(refresh)
		elseif kind == "afk" then
			afkCard.Visible = true
			ctx.Sound.play("Join")
		elseif kind == "afkStopped" then
			afkCard.Visible = false
			ctx.Hud.toast("Auto Train stopped (no answer). Tap AUTO to start again.", "Denied")
		end
	end)
	ctx.Net.get("Collection").OnClientEvent:Connect(function(snap)
		if st then
			st.Passes = snap.Passes or st.Passes
		end
		updateAuto()
	end)
	task.spawn(function()
		refresh()
		updateAuto()
	end)

	-- calm-moment offers: the Starter Pack after a race WIN (results closed), Auto Train after 10 min of tapping
	local pending = nil
	ctx.Net.get("RaceEvent").OnClientEvent:Connect(function(kind, info)
		if kind == "results" and info.place == 1 and info.kind ~= "tutorial" and player:GetAttribute("StarterEligible") then
			pending = "StarterPack"
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if ctx.Training.isTraining() then
				tapSeconds += 1
			end
			if not pending and not autoOffered and tapSeconds >= Store.AutoTrainOfferAfter and not owned("AutoTrain") then
				autoOffered = true
				pending = "AutoTrain"
			end
			if pending and calm() then
				local key = pending
				pending = nil
				task.wait(1.5) -- let the results card go first
				if calm() then
					showOffer(key)
				end
			end
		end
	end)

	-- VIP: a gold [VIP] in chat
	pcall(function()
		TextChatService.OnIncomingMessage = function(message)
			local props = Instance.new("TextChatMessageProperties")
			local src = message.TextSource
			local who = src and Players:GetPlayerByUserId(src.UserId)
			if who and who:GetAttribute("VIP") then
				props.PrefixText = ("<font color='%s'>[VIP]</font> %s"):format(Store.VIP.ChatColor, message.PrefixText)
			end
			return props
		end
	end)

	-- Studio test switches: TestOpenWindow = "Store" / "Store:COINS"; TestOffer = "StarterPack" / "AutoTrain"
	if RunService:IsStudio() then
		workspace:GetAttributeChangedSignal("TestOpenWindow"):Connect(function()
			local v = workspace:GetAttribute("TestOpenWindow")
			if type(v) == "string" and v:sub(1, 5) == "Store" then
				StoreUI.open(if #v > 6 then v:sub(7) else "PASSES")
			end
		end)
		workspace:GetAttributeChangedSignal("TestOffer"):Connect(function()
			local v = workspace:GetAttribute("TestOffer")
			if type(v) == "string" and v ~= "" then
				lastOfferAt = -math.huge
				showOffer(v)
			end
		end)
	end
end

return StoreUI
