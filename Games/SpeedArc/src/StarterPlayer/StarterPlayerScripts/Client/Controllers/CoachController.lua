-- CoachController: the COACHES window (ROLL / MY COACHES), the roll reveal (name roller with rising
-- ticks, a hit scaled by rarity, themed cutscenes for Legendary and up), portrait chips on the HUD.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Boosts = require(Shared.Util.Boosts)
local Format = require(Shared.Util.Format)
local Coaches = require(Shared.Config.Coaches)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local CoachUI = {}

local ctx, win, setTab, page, chips
local tab = "ROLL"
local coll = nil
local rolling = false
local price = 50

local function pct(x)
	if x >= 1 then
		return string.format("%g%%", x)
	end
	return string.format("%.2g%%", x)
end

local function boostText(id, stage)
	local t, p, c = Boosts.coachValues(id, stage)
	local parts = {}
	if t > 0 then
		table.insert(parts, ("+%d%% training"):format(math.floor(t * 100 + 0.5)))
	end
	if c > 0 then
		table.insert(parts, ("+%d%% coins"):format(math.floor(c * 100 + 0.5)))
	end
	if p > 0 then
		table.insert(parts, ("+%g%% pace"):format(math.floor(p * 1000 + 0.5) / 10))
	end
	return table.concat(parts, "  ")
end

----------------------------------------------------------------------------
-- reveal overlay
----------------------------------------------------------------------------
local overlay
local function buildOverlay()
	overlay = make("Frame", { Name = "CoachReveal", BackgroundColor3 = P.SpeedBlack, BackgroundTransparency = 0.15, Position = UDim2.fromOffset(0, -80), Size = UDim2.new(1, 0, 1, 80), Visible = false, ZIndex = 40, Parent = ctx.Hud.canvas })
	overlay.Active = true
end

local function clearOverlay()
	for _, ch in overlay:GetChildren() do
		ch:Destroy()
	end
end

-- themed cutscenes (UI only, under ~4 s). Each draws its world, then the coach steps in.
local Cutscenes = {}

function Cutscenes.Storm(stage, t)
	UIKit.gradient(stage, Color3.fromHex("#2C5FA8"), Color3.fromHex("#0A1426"), 90) -- stage stays white so the gradient shows
	local lines = {}
	for i = 1, 26 do
		local l = make("Frame", { BackgroundColor3 = P.White, BackgroundTransparency = 0.4 + math.random() * 0.4, BorderSizePixel = 0, Size = UDim2.new(0, math.random(80, 220), 0, math.random(2, 4)), Position = UDim2.fromScale(math.random(), math.random()), Parent = stage })
		lines[i] = l
	end
	ctx.Sound.play("Wind")
	return function(dt, age)
		for _, l in lines do
			local x = l.Position.X.Scale - dt * (1.6 + l.Size.X.Offset / 200)
			if x < -0.3 then
				x = 1.1
			end
			l.Position = UDim2.new(x, 0, l.Position.Y.Scale, 0)
		end
		stage.BackgroundTransparency = if math.floor(age * 6) % 7 == 0 and age < 2.5 then 0.6 else 0 -- a lightning flash now and then
	end
end

function Cutscenes.Sunrise(stage)
	UIKit.gradient(stage, Color3.fromHex("#FFB35C"), Color3.fromHex("#2A4E8F"), 90)
	local sun = make("Frame", { BackgroundColor3 = Color3.fromHex("#FFE38C"), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromOffset(170, 170), Parent = stage })
	UIKit.corner(sun, UDim.new(0.5, 0))
	for i, h in { 0.38, 0.3, 0.22 } do
		local hill = make("Frame", { BackgroundColor3 = Color3.fromHex("#1F3B2B"):Lerp(Color3.fromHex("#3F6B4A"), i / 3), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.15 + i * 0.35, 1.1), Size = UDim2.fromScale(0.8, h * 0.9), Parent = stage })
		UIKit.corner(hill, UDim.new(0.5, 0))
	end
	return function(_, age)
		sun.Position = UDim2.fromScale(0.5, 0.95 - math.min(1, age / 2.6) * 0.5)
	end
end

function Cutscenes.FilmGrain(stage)
	UIKit.gradient(stage, Color3.fromHex("#C9B38C"), Color3.fromHex("#4A3A28"), 90)
	local grain = {}
	for i = 1, 60 do
		grain[i] = make("Frame", { BackgroundColor3 = if i % 2 == 0 then Color3.fromHex("#F1E6CF") else Color3.fromHex("#1D150D"), BorderSizePixel = 0, Size = UDim2.fromOffset(2, 2), Parent = stage })
	end
	local scratch = make("Frame", { BackgroundColor3 = Color3.fromHex("#F1E6CF"), BackgroundTransparency = 0.5, BorderSizePixel = 0, Size = UDim2.new(0, 2, 1, 0), Parent = stage })
	make("TextLabel", { BackgroundTransparency = 1, FontFace = F.BodyBold, Text = "1924  -  A RACE AGAINST THE CLOCK", TextColor3 = Color3.fromHex("#F1E6CF"), TextSize = 18, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.1), Size = UDim2.fromOffset(500, 24), Parent = stage })
	return function()
		for _, g in grain do
			g.Position = UDim2.fromScale(math.random(), math.random())
		end
		scratch.Position = UDim2.fromScale(math.random() * 0.9 + 0.05, 0)
	end
end

function Cutscenes.Temple(stage)
	UIKit.gradient(stage, Color3.fromHex("#FFE38C"), Color3.fromHex("#B5730A"), 90)
	local cols = {}
	for i = 0, 5 do
		local c = make("Frame", { BackgroundColor3 = Color3.fromHex("#FFF4CC"), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.1 + i * 0.16, 1.4), Size = UDim2.fromScale(0.06, 0.62), Parent = stage })
		UIKit.gradient(c, Color3.fromHex("#FFFFFF"), Color3.fromHex("#E8C77A"), 0)
		cols[i + 1] = c
	end
	local ring = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(220, 220), Parent = stage })
	UIKit.corner(ring, UDim.new(0.5, 0))
	make("UIStroke", { Color = P.White, Thickness = 6, Transparency = 0.2, Parent = ring })
	return function(_, age)
		for i, c in cols do
			c.Position = UDim2.fromScale(c.Position.X.Scale, 1.4 - math.min(1, age / (1.2 + i * 0.12)) * 0.42)
		end
		ring.Rotation = age * 40
		local s = 1 + 0.08 * math.sin(age * 5)
		ring.Size = UDim2.fromOffset(220 * s, 220 * s)
	end
end

local function playCutscene(coach, canSkip)
	local stage = make("Frame", { Name = "Cutscene", BackgroundColor3 = P.White, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 41, Parent = overlay })
	local step = Cutscenes[coach.Cutscene](stage, 0)
	local done = false
	local skip
	if canSkip then
		skip = UIKit.button({ Style = "Dark", Text = "SKIP", TextSize = 16, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(100, 42), Parent = stage, OnClick = function()
			done = true
		end })
	end
	-- the coach steps in with their name
	local portrait = Art.portrait(coach, 150, stage)
	portrait.AnchorPoint = Vector2.new(0.5, 0.5)
	portrait.Position = UDim2.fromScale(0.5, 0.45)
	portrait.ZIndex = 10 -- always above the cutscene's world
	local ps = make("UIScale", { Scale = 0, Parent = portrait })
	local name = UIKit.text({ Text = string.upper(coach.Name), TextSize = 44, Color = Coaches.RarityColors[coach.Rarity], StrokeColor = P.SpeedBlack, StrokeThickness = 3, StrokeTransparency = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.45, 92), Size = UDim2.fromOffset(600, 50), Parent = stage })
	name.TextTransparency = 1
	name.ZIndex = 10
	local started = false
	local start = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local age = os.clock() - start
		step(dt, age)
		if age > 1.4 and not started then
			started = true
			UIKit.tween(ps, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			UIKit.tween(name, 0.4, { TextTransparency = 0 })
			ctx.Sound.play("RevealLegend")
		end
		if age > 3.6 then
			done = true
		end
	end)
	while not done do
		task.wait()
	end
	conn:Disconnect()
	stage:Destroy()
end

local function revealCard(coach, forced)
	local rc = Coaches.RarityColors[coach.Rarity]
	local rank = table.find(Coaches.Rarities, coach.Rarity)
	-- rays behind the card scale with rarity
	local rays = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(420, 420), Parent = overlay })
	for i = 1, 4 + rank * 2 do
		local ray = make("Frame", { BackgroundColor3 = rc, BackgroundTransparency = 0.65, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 26, 1, 0), Rotation = i * (180 / (4 + rank * 2)), Parent = rays })
		UIKit.corner(ray, UDim.new(0.5, 0))
	end
	local card = UIKit.panel({ Name = "RevealCard", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(300, 300), AccentColor = rc, StrokeColor = rc, StrokeThickness = 3, Parent = overlay })
	local cs = make("UIScale", { Scale = 0.3, Parent = card })
	local portrait = Art.portrait(coach, 120, card)
	portrait.AnchorPoint = Vector2.new(0.5, 0)
	portrait.Position = UDim2.new(0.5, 0, 0, 18)
	UIKit.text({ Text = string.upper(coach.Rarity), TextSize = 18, Color = rc, Position = UDim2.fromOffset(0, 146), Size = UDim2.new(1, 0, 0, 22), Parent = card })
	UIKit.text({ Text = string.upper(coach.Name), TextSize = 28, Position = UDim2.fromOffset(0, 170), Size = UDim2.new(1, 0, 0, 34), Parent = card })
	UIKit.text({ Text = boostText(coach.Id, 1), Font = F.BodyBold, TextSize = 15, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 0, 20), Parent = card })
	UIKit.text({ Text = '"' .. coach.Line .. '"', Font = F.Body, TextSize = 14, Wrapped = true, Position = UDim2.fromOffset(20, 228), Size = UDim2.new(1, -40, 0, 36), Parent = card })
	if forced then
		UIKit.text({ Text = "PITY: " .. string.upper(forced) .. " GUARANTEED", Font = F.BodyBold, TextSize = 13, Color = P.Gold, Position = UDim2.fromOffset(0, 266), Size = UDim2.new(1, 0, 0, 18), Parent = card })
	end
	UIKit.tween(cs, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	ctx.Sound.play(if rank >= 5 then "RevealLegend" elseif rank >= 4 then "RevealEpic" elseif rank >= 3 then "RevealRare" else "RevealCommon")
	task.spawn(function()
		while rays.Parent do
			rays.Rotation += 1
			task.wait(1 / 30)
		end
	end)
	local okBtn = UIKit.button({ Style = "Blue", Text = "NICE!", TextSize = 20, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.46, 160), Size = UDim2.fromOffset(170, 48), Parent = overlay })
	local closed = false
	okBtn.Activated:Connect(function()
		closed = true
	end)
	local t0 = os.clock()
	while not closed and os.clock() - t0 < 8 do
		task.wait(0.05)
	end
end

function CoachUI.reveal(result)
	local coach = Boosts.coach(result.Id)
	overlay.Visible = true
	clearOverlay()
	-- name roller: names flick past with rising ticks, slowing down, landing on the coach
	local roller = UIKit.text({ Text = "", TextSize = 40, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(600, 60), Parent = overlay })
	local glow = make("Frame", { BackgroundColor3 = P.ElectricBlue, BackgroundTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(460, 70), Parent = overlay })
	UIKit.corner(glow, 16)
	roller.ZIndex = 2
	local steps = 18
	for i = 1, steps do
		local c = Coaches.List[math.random(1, #Coaches.List)]
		if i == steps then
			c = coach
		end
		roller.Text = string.upper(c.Name)
		roller.TextColor3 = Coaches.RarityColors[c.Rarity]
		ctx.Sound.play("RollTick", { Pitch = 0.9 + i * 0.035 })
		task.wait(0.04 + (i / steps) ^ 3 * 0.25)
	end
	task.wait(0.35) -- the silent beat before the reveal
	clearOverlay()
	if coach.Cutscene then
		playCutscene(coach, not result.FirstCutscene)
	end
	revealCard(coach, result.Forced)
	clearOverlay()
	overlay.Visible = false
end

----------------------------------------------------------------------------
-- window pages
----------------------------------------------------------------------------
local function clearPage()
	for _, ch in page:GetChildren() do
		ch:Destroy()
	end
end

function CoachUI.rollNow()
	if rolling then
		return
	end
	rolling = true
	local ok, result = ctx.Net.call("RollCoach")
	if ok then
		win.hide(true)
		CoachUI.reveal(result)
		win.show()
		setTab("MY COACHES")
	elseif result == "coins" then
		ctx.Sound.play("Denied")
		ctx.Hud.toast("Not enough coins to roll yet", "Denied")
	end
	rolling = false
end

local function rollPage()
	clearPage()
	-- left: roll button + pity
	local left = UIKit.panel({ Name = "RollBox", Size = UDim2.fromOffset(250, 230), Position = UDim2.fromOffset(0, 4), Accent = false, Parent = page })
	UIKit.text({ Text = "ROLL A COACH", TextSize = 22, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 26), Parent = left })
	UIKit.text({ Text = "Coaches follow you and boost you.", Font = F.Body, TextSize = 13, Position = UDim2.fromOffset(10, 36), Size = UDim2.new(1, -20, 0, 18), Parent = left })
	local btn, label = UIKit.button({ Name = "Roll", Style = "Gold", Text = "ROLL", TextSize = 24, Position = UDim2.new(0.5, -95, 0, 62), Size = UDim2.fromOffset(190, 60), Parent = left })
	label.Text = if price == 0 then "FREE ROLL!" else "ROLL   " .. Format.short(price)
	if price > 0 then
		local ci = UIKit.coinIcon(22, btn.Face)
		ci.Position = UDim2.new(1, -36, 0.5, -11)
	end
	btn.Activated:Connect(function()
		CoachUI.rollNow()
	end)
	local y = 132
	for _, p in Coaches.Pity do
		local left_ = p.Rolls - ((coll and coll.Pity and coll.Pity[p.Rarity]) or 0)
		UIKit.text({ Text = ("%s GUARANTEED IN %d"):format(string.upper(p.Rarity), math.max(1, left_)), Font = F.BodyBold, TextSize = 13, Color = Coaches.RarityColors[p.Rarity], Position = UDim2.fromOffset(16, y), Size = UDim2.new(1, -32, 0, 18), XAlign = Enum.TextXAlignment.Left, Parent = left })
		y += 22
	end
	-- right: odds
	local right = UIKit.panel({ Name = "Odds", Size = UDim2.new(1, -262, 0, 230), Position = UDim2.fromOffset(262, 4), Accent = false, Parent = page })
	UIKit.text({ Text = "ODDS", TextSize = 18, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 22), Parent = right })
	for i, c in Coaches.List do
		local row = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 30 + (i - 1) * 24), Size = UDim2.new(1, -28, 0, 22), Parent = right })
		local dot = make("Frame", { BackgroundColor3 = Coaches.RarityColors[c.Rarity], Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(0, 5), Parent = row })
		UIKit.corner(dot, UDim.new(0.5, 0))
		UIKit.text({ Text = c.Name, Font = F.BodyBold, TextSize = 14, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = row })
		UIKit.text({ Text = c.Rarity, Font = F.Body, TextSize = 13, Color = Coaches.RarityColors[c.Rarity], XAlign = Enum.TextXAlignment.Left, Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.3, 0, 1, 0), Parent = row })
		UIKit.text({ Text = pct(c.Chance), TextSize = 14, Color = P.Gold, XAlign = Enum.TextXAlignment.Right, Position = UDim2.new(0.8, 0, 0, 0), Size = UDim2.new(0.2, 0, 1, 0), Parent = row })
	end
end

local function myPage()
	clearPage()
	if not coll then
		return
	end
	local slots = coll.Slots or 2
	local equipped = coll.EquippedCoaches or {}
	local top = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = page })
	UIKit.text({ Text = ("SLOTS  %d / %d"):format(math.min(#equipped, slots), slots), TextSize = 18, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(200, 40), Parent = top })
	UIKit.button({ Style = "Gold", Text = "BEST EQUIP", TextSize = 16, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(150, 40), Parent = top, OnClick = function()
		if ctx.Net.call("BestEquip") then
			ctx.Sound.play("Equip")
		end
	end })
	local grid = make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = P.ElectricBlue, Parent = page })
	make("UIGridLayout", { CellSize = UDim2.fromOffset(150, 176), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	if #coll.Coaches == 0 then
		UIKit.text({ Text = "No coaches yet. Roll one!", Font = F.BodyBold, TextSize = 16, Size = UDim2.fromOffset(300, 40), Parent = grid })
	end
	-- duplicates per coach + stage (for EVOLVE)
	local counts = {}
	for _, e in coll.Coaches do
		local k = e.Id .. "_" .. e.Stage
		counts[k] = (counts[k] or 0) + 1
	end
	local list = table.clone(coll.Coaches)
	table.sort(list, function(a, b)
		local ea, eb = table.find(equipped, a.Uid) ~= nil, table.find(equipped, b.Uid) ~= nil
		if ea ~= eb then
			return ea
		end
		local ra = table.find(Coaches.Rarities, Boosts.coach(a.Id).Rarity)
		local rb = table.find(Coaches.Rarities, Boosts.coach(b.Id).Rarity)
		if ra ~= rb then
			return ra > rb
		end
		return a.Stage > b.Stage
	end)
	for i, e in list do
		local coach = Boosts.coach(e.Id)
		local isEq = table.find(equipped, e.Uid) ~= nil
		local rc = Coaches.RarityColors[coach.Rarity]
		local c = make("Frame", { BackgroundColor3 = P.White, LayoutOrder = i, Parent = grid })
		UIKit.corner(c, 12)
		UIKit.gradient(c, if isEq then P.DeepBlue else P.Graphite, P.Carbon, 90)
		UIKit.stroke(c, if isEq then P.Gold else rc, 2)
		local portrait = Art.portrait(coach, 64, c)
		portrait.Position = UDim2.new(0.5, -32, 0, 6)
		UIKit.text({ Text = string.upper(coach.Name), TextSize = 14, Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 0, 18), Parent = c })
		UIKit.text({ Text = ("%s  -  %s"):format(string.upper(coach.Rarity), Coaches.Stages[e.Stage]), Font = F.BodyBold, TextSize = 13, Color = rc, Position = UDim2.fromOffset(4, 90), Size = UDim2.new(1, -8, 0, 16), Parent = c })
		UIKit.text({ Text = boostText(e.Id, e.Stage), Font = F.Body, TextSize = 13, Color = P.BrightBlue, Wrapped = true, Position = UDim2.fromOffset(4, 106), Size = UDim2.new(1, -8, 0, 28), Parent = c })
		local dup = counts[e.Id .. "_" .. e.Stage] or 0
		if dup >= Coaches.EvolveCost and e.Stage < #Coaches.Stages then
			UIKit.button({ Style = "Gold", Text = ("EVOLVE %d/%d"):format(math.min(dup, 3), Coaches.EvolveCost), TextSize = 13, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -12, 0, 32), Parent = c, OnClick = function()
				local ok = ctx.Net.call("EvolveCoach", e.Id, e.Stage)
				if ok then
					ctx.Sound.play("RevealEpic")
					ctx.Hud.toast(("%s evolved to %s!"):format(coach.Name, Coaches.Stages[e.Stage + 1]), "Gold")
				end
			end })
		else
			UIKit.button({ Style = if isEq then "Blue" else "Dark", Text = if isEq then "EQUIPPED" else "EQUIP", TextSize = 14, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -12, 0, 32), Parent = c, OnClick = function()
				local ok, why = ctx.Net.call("EquipCoach", e.Uid)
				if ok then
					ctx.Sound.play("Equip")
				elseif why == "slots" then
					ctx.Hud.toast("Your coach slots are full. Unequip one first.", "Denied")
				end
			end })
		end
	end
end

local function refresh()
	if not win.isOpen() then
		return
	end
	if tab == "ROLL" then
		rollPage()
	else
		myPage()
	end
end

-- portrait chips for equipped coaches under the coins pill
local function updateChips()
	for _, ch in chips:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	if not coll then
		return
	end
	local byUid = {}
	for _, e in coll.Coaches do
		byUid[e.Uid] = e
	end
	for i, uid in coll.EquippedCoaches or {} do
		local e = byUid[uid]
		if e and i <= (coll.Slots or 2) then
			local holder = make("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(38, 38), LayoutOrder = i, Parent = chips })
			Art.portrait(Boosts.coach(e.Id), 38, holder)
		end
	end
end

function CoachUI.open(which)
	tab = which or tab
	win.show()
	setTab(tab)
end

function CoachUI.start(c)
	ctx = c
	ctx.Coaches = CoachUI
	buildOverlay()
	win = UIKit.window({ Name = "Coaches", Title = "COACHES", Size = Vector2.new(700, 330), Accent = P.Gold, Parent = ctx.Hud.canvas })
	setTab = UIKit.tabs(win.content, { "ROLL", "MY COACHES" }, function(name)
		tab = name
		refresh()
	end)
	page = make("Frame", { Name = "Page", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -46), Parent = win.content })
	win.onOpen = function()
		task.spawn(function()
			local ok, p = ctx.Net.call("RollPrice")
			if ok and p then
				price = p
				if tab == "ROLL" then
					rollPage()
				end
			end
		end)
	end
	chips = make("Frame", { Name = "CoachChips", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 108), Size = UDim2.fromOffset(170, 40), Parent = ctx.Hud.canvas })
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = chips })
	ctx.Hud.refs.coachChips = chips

	ctx.Net.get("Collection").OnClientEvent:Connect(function(snap)
		coll = snap
		updateChips()
		-- free rolls (Go Pro, daily, quests, gifts) change the price
		if (snap.FreeRolls or 0) > 0 then
			price = 0
		elseif price == 0 then
			local ok, p = ctx.Net.call("RollPrice")
			if ok and p then
				price = p
			end
		end
		refresh()
	end)
	task.spawn(function()
		local ok, snap = ctx.Net.call("GetCollection")
		if ok and snap then
			coll = snap
			updateChips()
		end
	end)
end

return CoachUI
