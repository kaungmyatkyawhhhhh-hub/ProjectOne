-- LockerController: the LOCKER window (SHOES and TRAILS tabs for M2; more tabs in M5).
-- Owned forever, one worn of each; locked items show as dark silhouettes with how to get them.
-- The Shoe Shop and Trail Booth open the same window on their tab (BUY + TRY ON).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Boosts = require(Shared.Util.Boosts)
local Format = require(Shared.Util.Format)
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
		return ("x%s training%s"):format(tostring(item.Train), pace)
	end
	if item.Train then
		return ("+%d%% training"):format(math.floor(item.Train * 100 + 0.5))
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

local function rebuild()
	if not win or not coll then
		return
	end
	for _, ch in grid:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local list = if tab == "SHOES" then Shoes.List else Trails.List
	for i, item in list do
		local c = card(item, tab == "SHOES")
		c.LayoutOrder = i
		c.Parent = grid
	end
	header.Text = if tab == "SHOES" then "Shoes boost your training. Wear one pair." else "Trails show when you run fast and in races. Small bonus each."
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
	setTab = UIKit.tabs(win.content, { "SHOES", "TRAILS" }, function(name)
		tab = name
		rebuild()
	end)
	header = UIKit.text({ Text = "", Font = F.Body, TextSize = 14, Color = P.White, XAlign = Enum.TextXAlignment.Right, Position = UDim2.new(1, -400, 0, 8), Size = UDim2.fromOffset(400, 22), Parent = win.content })
	grid = make("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
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
