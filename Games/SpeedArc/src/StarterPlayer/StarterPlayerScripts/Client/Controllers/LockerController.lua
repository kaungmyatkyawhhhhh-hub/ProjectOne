-- LockerController: the LOCKER window (SHOES and TRAILS tabs for M2; more tabs in M5).
-- Owned forever, one worn of each; locked items show as dark silhouettes with how to get them.
-- The Shoe Shop and Trail Booth open the same window on their tab (BUY + TRY ON).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Boosts = require(Shared.Util.Boosts)
local Format = require(Shared.Util.Format)
local Cosmetics = require(Shared.Config.Cosmetics)
local Retention = require(Shared.Config.Retention)
local Formulas = require(Shared.Util.Formulas)
local Shoes = require(Shared.Config.Shoes)
local Trails = require(Shared.Config.Trails)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local Locker = {}

local ctx, win, grid, setTab, header
local tab = "SHOES"
local coll = nil -- latest collection snapshot
local tryOn = nil

local function dataView()
	return {
		Speed = player:GetAttribute("Speed") or 0,
		League = coll and coll.League or 1,
		BestLeague = coll and coll.BestLeague or 1,
		BestRank = coll and coll.BestRank,
	}
end

local function statText(item, isShoe)
	if isShoe then
		local pace = item.Pace > 0 and ("  +%d%% pace"):format(math.floor(item.Pace * 100 + 0.5)) or ""
		return ("x%s SPEED%s"):format(tostring(item.Train), pace)
	end
	if item.Train then
		return ("+%d%% SPEED"):format(math.floor(item.Train * 100 + 0.5))
	elseif item.Coins then
		return ("+%d%% coins"):format(math.floor(item.Coins * 100 + 0.5))
	end
	return "Looks only"
end

----------------------------------------------------------------------------
-- try on: a local-only preview of a pair on your own feet for a few seconds
----------------------------------------------------------------------------
local function clearTryOn()
	if tryOn then
		for _, m in tryOn do
			m:Destroy()
		end
		tryOn = nil
	end
	local char = player.Character
	if char then
		for _, d in char:GetChildren() do
			if d:GetAttribute("SpeedArcShoe") then
				for _, p in d:GetDescendants() do
					if p:IsA("BasePart") then
						p.LocalTransparencyModifier = 0
					end
				end
			end
		end
	end
end

local function doTryOn(shoe)
	clearTryOn()
	local char = player.Character
	if not char then
		return
	end
	-- hide the real shoes locally while trying on
	for _, d in char:GetChildren() do
		if d:GetAttribute("SpeedArcShoe") then
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = 1
				end
			end
		end
	end
	tryOn = {}
	for _, side in { "LeftFoot", "RightFoot" } do
		local foot = char:FindFirstChild(side)
		if foot then
			local m = Art.shoeModel(shoe, foot.Size.X / 1.0 * 0.95)
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored = false
					p.Massless = true
					local rel = m.PrimaryPart.CFrame:ToObjectSpace(p.CFrame)
					p.CFrame = foot.CFrame * CFrame.new(0, -foot.Size.Y / 2 - 0.05, -0.1) * rel
					local w = Instance.new("WeldConstraint")
					w.Part0 = foot
					w.Part1 = p
					w.Parent = p
				end
			end
			m.Parent = char
			table.insert(tryOn, m)
		end
	end
	ctx.Sound.play("Equip")
	ctx.Hud.toast(("Trying on %s"):format(shoe.Name))
	local mine = tryOn
	task.delay(6, function()
		if tryOn == mine then
			clearTryOn()
		end
	end)
end

----------------------------------------------------------------------------
-- cards
----------------------------------------------------------------------------
local function viewport(shoe, parent, dark)
	local vp = make("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 74),
		Ambient = Color3.fromRGB(170, 175, 190),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-1, -1.5, -1),
		Parent = parent,
	})
	local m = Art.shoeModel(shoe, 1, dark)
	m:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-28), 0))
	m.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.CFrame = CFrame.lookAt(Vector3.new(4.6, 2.0, 0.6), Vector3.new(0, 0.45, 0)) -- the side of the shoe, toe to the left
	cam.Parent = vp
	vp.CurrentCamera = cam
	return vp
end

local function actionButton(card, text, style, onClick)
	local b = UIKit.button({
		Style = style,
		Text = text,
		TextSize = 15,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -14, 0, 34),
		OnClick = onClick,
		ClickSound = if style == "Dark" then "Denied" else "Click",
		Parent = card,
	})
	return b
end

local function card(item, isShoe)
	local owned = if isShoe then coll.OwnedShoes[item.Id] else coll.OwnedTrails[item.Id]
	local equipped = if isShoe then coll.Shoe == item.Id else coll.Trail == item.Id
	local unlocked
	if isShoe then
		unlocked = Boosts.unlocked(dataView(), item.Unlock)
	else
		unlocked = item.Price ~= nil and (not item.League or (coll.BestLeague or 1) >= item.League)
	end
	local c = make("Frame", { Name = item.Id, BackgroundColor3 = P.White, Size = UDim2.fromOffset(150, 178) })
	UIKit.corner(c, 12)
	UIKit.gradient(c, if equipped then P.DeepBlue else P.Graphite, P.Carbon, 90)
	UIKit.stroke(c, if equipped then P.Gold elseif owned then P.ElectricBlue else P.Graphite, 2)
	local art = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 74), Parent = c })
	local dark = not owned and not unlocked
	if isShoe then
		viewport(item, art, dark)
	else
		Art.trailSwatch(item, art, dark)
	end
	UIKit.text({ Text = string.upper(item.Name), TextSize = 15, Position = UDim2.fromOffset(6, 80), Size = UDim2.new(1, -12, 0, 18), Parent = c })
	UIKit.text({ Text = statText(item, isShoe), Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, Position = UDim2.fromOffset(6, 99), Size = UDim2.new(1, -12, 0, 16), Parent = c })

	if equipped then
		actionButton(c, "EQUIPPED", "Blue", nil)
	elseif owned then
		actionButton(c, "EQUIP", "Blue", function()
			local ok = ctx.Net.call(if isShoe then "EquipShoe" else "EquipTrail", item.Id)
			if ok then
				ctx.Sound.play(if isShoe then "Equip" else "TrailEquip")
			end
		end)
	elseif not unlocked then
		local why = if isShoe then Boosts.unlockText(item.Unlock) elseif item.Pass then "TRAIL PACK (SOON)" elseif item.Price == nil and item.Source then item.Source else ("UNLOCKS IN LEAGUE %d"):format(item.League or 1)
		UIKit.text({ Text = why, Font = F.BodyBold, TextSize = 13, Color = P.Gold, Wrapped = true, Position = UDim2.fromOffset(6, 116), Size = UDim2.new(1, -12, 0, 30), Parent = c })
		local lock = actionButton(c, "LOCKED", "Dark", function()
			ctx.Hud.toast(why, "Denied")
		end)
		lock.Size = UDim2.new(1, -14, 0, 26)
	else
		local price = item.Price or 0
		local row = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 116), Size = UDim2.new(1, 0, 0, 22), Parent = c })
		local ci = UIKit.coinIcon(18, row)
		ci.Position = UDim2.new(0.5, -46, 0, 2)
		UIKit.text({ Text = Format.short(price), TextSize = 17, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.new(0.5, -24, 0, 0), Size = UDim2.fromOffset(90, 22), Parent = row })
		local buy = actionButton(c, "BUY", "Gold", function()
			local ok, why = ctx.Net.call(if isShoe then "BuyShoe" else "BuyTrail", item.Id)
			if ok then
				ctx.Sound.play("KaChing")
				task.delay(0.25, function()
					ctx.Sound.play(if isShoe then "Equip" else "TrailEquip")
				end)
				ctx.Hud.toast(("%s are yours!"):format(item.Name), "Gold")
			elseif why == "coins" then
				ctx.Hud.toast("Not enough coins yet: win races to earn more", "Denied")
			end
		end)
		if isShoe then
			buy.Size = UDim2.new(0.62, -8, 0, 34)
			buy.AnchorPoint = Vector2.new(0, 1)
			buy.Position = UDim2.new(0, 7, 1, -6)
			local try = UIKit.button({ Style = "Dark", Text = "TRY", TextSize = 14, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -7, 1, -6), Size = UDim2.new(0.38, -6, 0, 34), Parent = c,
				OnClick = function()
					doTryOn(item)
				end })
			try.Name = "TryOn"
		end
	end
	return c
end

local cosmeticCard, titleList, bibRefresh, rebuild
----------------------------------------------------------------------------
-- M5: kits, headwear, name styles, bib, titles
----------------------------------------------------------------------------
local bibPage, bibBox, bibColor, bibOn, bibColorButtons = nil, nil, nil, true, {}

local function isWorn(kind, item)
	if kind == "Kit" then
		return coll.Kit and coll.Kit[item.Slot] == item.Id
	elseif kind == "Head" then
		return coll.Head == item.Id
	elseif kind == "Name" then
		return coll.NameStyle == item.Id
	elseif kind == "Skin" then
		return coll.ShoeSkin and coll.ShoeSkin.CanvasRunners == item.Id
	end
end

local function isOwned(kind, item)
	if item.Pass then
		return coll.Passes and coll.Passes[item.Pass] == true
	end
	if kind == "Kit" then
		return coll.OwnedKits and coll.OwnedKits[item.Id]
	elseif kind == "Head" then
		return coll.OwnedHead and coll.OwnedHead[item.Id]
	elseif kind == "Name" then
		return coll.OwnedNameStyles and coll.OwnedNameStyles[item.Id]
	elseif kind == "Skin" then
		return true
	end
end

function cosmeticCard(item, kind, order)
	local owned = isOwned(kind, item)
	local worn = isWorn(kind, item)
	local c = make("Frame", { Name = item.Id, BackgroundColor3 = P.White, Size = UDim2.fromOffset(132, 168), LayoutOrder = order, Parent = grid })
	UIKit.corner(c, 12)
	UIKit.gradient(c, if worn then P.DeepBlue else P.Graphite, P.Carbon, 90)
	UIKit.stroke(c, if worn then P.Gold elseif owned then P.ElectricBlue else P.Graphite, 2)
	-- the swatch: the item's colour (a name style shows your name in it)
	local sw = make("Frame", { BackgroundColor3 = P.White, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(if kind == "Name" then 116 else 64, 52), Parent = c })
	UIKit.corner(sw, 10)
	if kind == "Name" then
		sw.BackgroundColor3 = P.SpeedBlack
		local nameText = UIKit.text({ Text = player.DisplayName, TextSize = 18, Color = P.White, Parent = sw })
		make("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex(item.Colors[1]), Color3.fromHex(item.Colors[2])), Parent = nameText })
	else
		local col = Color3.fromHex(item.Color)
		UIKit.gradient(sw, col:Lerp(P.White, 0.25), col:Lerp(P.SpeedBlack, 0.3), 90)
		UIKit.stroke(sw, P.White, 2, 0.4)
		UIKit.text({ Text = if kind == "Kit" then string.upper(item.Slot) elseif kind == "Skin" then "SHOES" else "HEAD", TextSize = 13, Color = P.White, Parent = sw })
	end
	UIKit.text({ Text = string.upper(item.Name), TextSize = 14, Wrapped = true, Position = UDim2.fromOffset(6, 64), Size = UDim2.new(1, -12, 0, 34), Parent = c })
	local function act(text, style, fn)
		UIKit.button({ Style = style, Text = text, TextSize = 14, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -14, 0, 34), Parent = c, OnClick = fn })
	end
	if owned then
		act(if worn then "WEARING" else "WEAR", if worn then "Gold" else "Blue", function()
			if ctx.Net.call("EquipCosmetic", kind, item.Id) then
				ctx.Sound.play("Equip")
			end
		end)
	elseif item.Pass then
		UIKit.text({ Text = item.Pass .. " PASS", Font = F.BodyBold, TextSize = 13, Color = P.Gold, Position = UDim2.fromOffset(6, 100), Size = UDim2.new(1, -12, 0, 18), Parent = c })
		act("STORE", "Dark", function()
			if ctx.Store then
				ctx.Store.open("PASSES")
			end
		end)
	else
		local price = Formulas.minutesOfCoins(item.Minutes or 0, player:GetAttribute("League") or 1)
		local row = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 22), Parent = c })
		local ci = UIKit.coinIcon(18, row)
		ci.Position = UDim2.new(0.5, -40, 0, 2)
		UIKit.text({ Text = Format.short(price), TextSize = 16, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.new(0.5, -18, 0, 0), Size = UDim2.fromOffset(80, 22), Parent = row })
		act("BUY", "Gold", function()
			local ok, why = ctx.Net.call("BuyCosmetic", kind, item.Id)
			if ok then
				ctx.Sound.play("KaChing")
				ctx.Hud.toast(item.Name .. " is yours!", "Gold")
			elseif why == "coins" then
				ctx.Hud.toast("Not enough coins yet: win races to earn more", "Denied")
			end
		end)
	end
	return c
end

function titleList()
	local titles = {}
	for _, t in Retention.Titles.Order do
		if coll.Titles and coll.Titles[t] then
			table.insert(titles, t)
		end
	end
	for t in coll.Titles or {} do
		if not table.find(titles, t) then
			table.insert(titles, t)
		end
	end
	if #titles == 0 then
		UIKit.text({ Text = "No titles yet - win your first race!", TextSize = 16, Size = UDim2.fromOffset(400, 40), Parent = grid })
		return
	end
	for i, t in titles do
		local worn = coll.Title == t
		local b = UIKit.button({ Style = if worn then "Gold" else "Dark", Text = t, TextSize = 14, Size = UDim2.fromOffset(150, 46), Parent = grid, OnClick = function()
			if ctx.Net.call("SetTitle", if worn then "" else t) then
				ctx.Sound.play("Equip")
				task.spawn(function()
					local ok, snap = ctx.Net.call("GetCollection")
					if ok then
						coll = snap
						rebuild()
					end
				end)
			end
		end })
		b.LayoutOrder = i
	end
end

local function buildBibPage()
	bibPage = make("Frame", { Name = "BibPage", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66), Visible = false, Parent = win.content })
	-- the preview card
	local preview = make("Frame", { Name = "Preview", BackgroundColor3 = P.White, Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(150, 150), Parent = bibPage })
	UIKit.corner(preview, 10)
	local band = make("Frame", { Name = "Band", BackgroundColor3 = P.ElectricBlue, Size = UDim2.new(1, 0, 0, 36), Parent = preview })
	UIKit.corner(band, 10)
	local num = UIKit.text({ Name = "Num", Text = "7", TextSize = 64, Color = P.SpeedBlack, Stroke = false, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), Parent = preview })
	UIKit.text({ Text = "NUMBER (1-999)", TextSize = 14, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(180, 4), Size = UDim2.fromOffset(200, 20), Parent = bibPage })
	local boxFrame = make("Frame", { BackgroundColor3 = P.SpeedBlack, Position = UDim2.fromOffset(180, 26), Size = UDim2.fromOffset(120, 42), Parent = bibPage })
	UIKit.corner(boxFrame, 10)
	UIKit.stroke(boxFrame, P.Graphite, 2)
	bibBox = make("TextBox", { BackgroundTransparency = 1, Text = "7", PlaceholderText = "7", TextColor3 = P.White, FontFace = F.BodyBold, TextSize = 22, Size = UDim2.fromScale(1, 1), ClearTextOnFocus = false, Parent = boxFrame })
	bibBox:GetPropertyChangedSignal("Text"):Connect(function()
		local clean = bibBox.Text:gsub("%D", ""):sub(1, 3)
		if clean ~= bibBox.Text then
			bibBox.Text = clean
		end
		num.Text = if clean == "" then "-" else clean
	end)
	UIKit.text({ Text = "COLOUR", TextSize = 14, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(180, 76), Size = UDim2.fromOffset(200, 20), Parent = bibPage })
	for i, c in Cosmetics.Bib.Colors do
		local b, l = UIKit.button({ Name = c.Id, Style = "Dark", Text = c.Name, TextSize = 13, Position = UDim2.fromOffset(180 + (i - 1) * 118, 98), Size = UDim2.fromOffset(112, 40), Parent = bibPage, OnClick = function()
			if (coll.BestLeague or 1) < c.League then
				ctx.Hud.toast(("Unlocks in League %d"):format(c.League), "Denied")
				return
			end
			bibColor = c.Id
			band.BackgroundColor3 = Color3.fromHex(c.Color)
			for id, bb in bibColorButtons do
				UIKit.setButtonStyle(bb.button, if id == bibColor then "Blue" else "Dark")
			end
		end })
		bibColorButtons[c.Id] = { button = b, label = l, def = c }
	end
	local onBtn, onLabel
	onBtn, onLabel = UIKit.button({ Name = "On", Style = "Blue", Text = "BIB ON", TextSize = 15, Position = UDim2.fromOffset(180, 152), Size = UDim2.fromOffset(130, 44), Parent = bibPage, OnClick = function()
		bibOn = not bibOn
		onLabel.Text = if bibOn then "BIB ON" else "BIB OFF"
		UIKit.setButtonStyle(onBtn, if bibOn then "Blue" else "Dark")
	end })
	UIKit.button({ Name = "Save", Style = "Gold", Text = "SAVE", TextSize = 16, Position = UDim2.fromOffset(320, 152), Size = UDim2.fromOffset(130, 44), Parent = bibPage, OnClick = function()
		local ok, why = ctx.Net.call("SetBib", tonumber(bibBox.Text) or 0, bibColor, bibOn)
		if ok then
			ctx.Sound.play("Equip")
			ctx.Hud.toast("Bib saved!", "Gold")
		else
			ctx.Hud.toast(if why == "number" then "Pick a number from 1 to 999" else "That colour isn't open yet", "Denied")
		end
	end })
	bibPage:SetAttribute("Built", true)
end

function bibRefresh()
	if not bibPage then
		buildBibPage()
	end
	bibPage.Visible = true
	local b = coll.Bib or { Number = 0, Color = "Blue", On = false }
	bibColor = b.Color
	bibOn = b.On or b.Number == 0
	if b.Number > 0 then
		bibBox.Text = tostring(b.Number)
	end
	for id, bb in bibColorButtons do
		local open = (coll.BestLeague or 1) >= bb.def.League
		UIKit.setButtonStyle(bb.button, if id == bibColor then "Blue" else "Dark")
		bb.label.Text = if open then bb.def.Name else ("LEAGUE %d"):format(bb.def.League)
	end
	local preview = bibPage.Preview
	for _, c in Cosmetics.Bib.Colors do
		if c.Id == bibColor then
			preview.Band.BackgroundColor3 = Color3.fromHex(c.Color)
		end
	end
end

function rebuild()
	if not win or not coll then
		return
	end
	for _, ch in grid:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	if bibPage then
		bibPage.Visible = tab == "BIB"
	end
	grid.Visible = tab ~= "BIB"
	if tab == "SHOES" or tab == "TRAILS" then
		local list = if tab == "SHOES" then Shoes.List else Trails.List
		for i, item in list do
			local c = card(item, tab == "SHOES")
			c.LayoutOrder = i
			c.Parent = grid
		end
		header.Text = if tab == "SHOES" then "Shoes make every step worth more. Wear one pair." else "Trails show when you run fast and in races. Small bonus each."
	elseif tab == "KITS" then
		for i, item in Cosmetics.Kits do
			cosmeticCard(item, "Kit", i)
		end
		local n = #Cosmetics.Kits
		for id, skin in Cosmetics.ShoeSkins do
			if coll.ShoeSkins and coll.ShoeSkins[id] then
				n += 1
				cosmeticCard({ Id = id, Name = skin.Name .. " Canvas Runners", Color = skin.Color, Skin = true }, "Skin", n)
			end
		end
		header.Text = "Kits are just for looks: one top + one bottom. Tap WEARING to take it off."
	elseif tab == "HEAD" then
		for i, item in Cosmetics.Headwear do
			cosmeticCard(item, "Head", i)
		end
		header.Text = "Headwear is just for looks. One at a time."
	elseif tab == "NAME" then
		for i, item in Cosmetics.NameStyles do
			cosmeticCard(item, "Name", i)
		end
		header.Text = "The colour of your name over your head. Long coin goals!"
	elseif tab == "TITLE" then
		titleList()
		header.Text = "Titles you earned. Win races, rank up and Go Pro for more."
	elseif tab == "BIB" then
		bibRefresh()
		header.Text = "Your race number on your chest. Free! More colours unlock in new leagues."
	end
end

function Locker.open(which)
	tab = which or tab
	win.show()
	setTab(tab)
end

function Locker.start(c)
	ctx = c
	ctx.Locker = Locker
	win = UIKit.window({ Name = "Locker", Title = "LOCKER", Size = Vector2.new(700, 330), Parent = ctx.Hud.canvas })
	setTab = UIKit.tabs(win.content, { "SHOES", "TRAILS", "KITS", "HEAD", "BIB", "NAME", "TITLE" }, function(name)
		tab = name
		rebuild()
	end, nil, 88)
	header = UIKit.text({ Text = "", Font = F.Body, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(2, 44), Size = UDim2.new(1, 0, 0, 18), Parent = win.content })
	grid = make("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -64),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = P.ElectricBlue,
		Parent = win.content,
	})
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	make("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = grid })
	win.onClose = clearTryOn

	ctx.Net.get("Collection").OnClientEvent:Connect(function(snap)
		coll = snap
		if win.isOpen() then
			rebuild()
		end
	end)
	task.spawn(function()
		local ok, snap = ctx.Net.call("GetCollection")
		if ok and snap then
			coll = snap
		end
	end)
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		-- a shoe may have just unlocked
		if win.isOpen() and tab == "SHOES" then
			local before = grid:GetAttribute("Unlocks") or 0
			local n = 0
			for _, s in Shoes.List do
				if Boosts.unlocked(dataView(), s.Unlock) then
					n += 1
				end
			end
			if n ~= before then
				grid:SetAttribute("Unlocks", n)
				rebuild()
			end
		end
	end)
end

-- the tutorial points at one card: a pulsing gold ring round it
function Locker.highlight(id)
	local c = grid and grid:FindFirstChild(id)
	if not c or c:FindFirstChild("Highlight") then
		return
	end
	local ring = make("UIStroke", { Name = "Highlight", Color = P.Gold, Thickness = 4, Parent = c })
	task.spawn(function()
		while ring.Parent and win.isOpen() do
			UIKit.tween(ring, 0.4, { Thickness = 7 }, Enum.EasingStyle.Sine)
			task.wait(0.4)
			UIKit.tween(ring, 0.4, { Thickness = 4 }, Enum.EasingStyle.Sine)
			task.wait(0.4)
		end
	end)
end

function Locker.isOpen()
	return win ~= nil and win.isOpen()
end

function Locker.collection()
	return coll
end

return Locker
