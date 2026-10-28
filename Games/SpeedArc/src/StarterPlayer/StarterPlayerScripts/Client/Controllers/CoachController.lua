-- CoachController: MY COACHES (inventory, anywhere) and the COACH AGENCY (rolls, at the agency stand
-- in each world), the roll reveal (name roller with rising ticks, a hit scaled by rarity, themed
-- cutscenes for Legendary and up), portrait chips on the HUD.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Boosts = require(Shared.Util.Boosts)
local Format = require(Shared.Util.Format)
local Store = require(Shared.Config.Store)
local Coaches = require(Shared.Config.Coaches)
local CoachView = require(Shared.Util.CoachView)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local CoachUI = {}

local ctx, chips
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
		table.insert(parts, ("+%d%% SPEED"):format(math.floor(t * 100 + 0.5)))
	end
	if c > 0 then
		table.insert(parts, ("+%d%% COINS"):format(math.floor(c * 100 + 0.5)))
	end
	if p > 0 then
		table.insert(parts, ("+%g%% RACE PACE"):format(math.floor(p * 1000 + 0.5) / 10))
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
	local bust = make("Frame", { Name = "Bust", BackgroundColor3 = rc:Lerp(P.White, 0.3), BackgroundTransparency = 0.55, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(130, 126), Parent = card })
	UIKit.corner(bust, UDim.new(0.5, 0))
	CoachView.make(bust, coach.Id, { Zoom = 1.1 })
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
-- windows (28 Oct, owner: like GYM ARC's Trainer Agency + My Trainers)
--   MY COACHES (the COACHES button, anywhere): every coach you own as a 3D tile, a detail panel
--   with EQUIP / EVOLVE, pages of 8.
--   COACH AGENCY (only at the agency stand in each world): the 8 coaches as rarity tiles (black
--   silhouettes until you own one), the chance, the pity line, ROLL / X3 / MY COACHES.
----------------------------------------------------------------------------
local agencyWin, myWin, agencyPage, myPage, fasterRolls
local selectedUid = nil
local myPageIndex = 1
local PER_PAGE = 8

local function clear(f)
	for _, ch in f:GetChildren() do
		ch:Destroy()
	end
end

local function rarityIndex(r)
	return table.find(Coaches.Rarities, r) or 1
end

local function stageColor(stage)
	return Color3.fromHex(Coaches.StageColors[stage] or Coaches.StageColors[1])
end

-- a small gold check badge (two white bars, no font glyph needed)
local function checkBadge(parent)
	local b = make("Frame", { Name = "Check", BackgroundColor3 = P.Gold, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(20, 20), ZIndex = 6, Parent = parent })
	UIKit.corner(b, UDim.new(0.5, 0))
	UIKit.stroke(b, P.SpeedBlack, 2, 0)
	make("Frame", { BackgroundColor3 = P.SpeedBlack, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.36, 0.58), Size = UDim2.fromOffset(7, 3), Rotation = 45, ZIndex = 7, Parent = b })
	make("Frame", { BackgroundColor3 = P.SpeedBlack, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.6, 0.48), Size = UDim2.fromOffset(12, 3), Rotation = -50, ZIndex = 7, Parent = b })
	return b
end

-- one tile (both windows): a colour glow, the coach's 3D bust, the name on top, a big label and a
-- small line under it, a gold check when owned / equipped, "x2" for copies
local function tile(parent, o)
	local t = make("TextButton", { Name = "Tile", Text = "", AutoButtonColor = false, BackgroundColor3 = P.White, Size = o.Size, Position = o.Position or UDim2.new(), LayoutOrder = o.LayoutOrder or 0, Parent = parent })
	UIKit.corner(t, 12)
	UIKit.gradient(t, o.Color:Lerp(P.White, 0.08), o.Color:Lerp(P.SpeedBlack, 0.66), 90)
	UIKit.stroke(t, if o.Selected then P.White else o.Color:Lerp(P.White, 0.25), if o.Selected then 4 else 3, 0)
	local glow = make("Frame", { Name = "Glow", BackgroundColor3 = o.Color:Lerp(P.White, 0.45), BackgroundTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.8, 0.62), ZIndex = 2, Parent = t })
	UIKit.corner(glow, UDim.new(0.5, 0))
	if o.Rays then
		for i = 1, 6 do
			local ray = make("Frame", { BackgroundColor3 = o.Color:Lerp(P.White, 0.5), BackgroundTransparency = 0.78, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.new(0, 6, 0.9, 0), Rotation = i * 30, ZIndex = 2, Parent = t })
			UIKit.corner(ray, 3)
		end
	end
	local holder = make("Frame", { Name = "Bust", BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.13), Size = UDim2.fromScale(0.88, 0.6), ZIndex = 3, Parent = t })
	CoachView.make(holder, o.CoachId, { Silhouette = o.Silhouette, ZIndex = 3 })
	if o.Hidden then
		UIKit.text({ Text = "?", TextSize = 40, Color = o.Color, StrokeTransparency = 0, Position = UDim2.fromScale(0, 0.13), Size = UDim2.fromScale(1, 0.6), ZIndex = 4, Parent = t })
	end
	local nameLabel = UIKit.text({ Text = o.Name, TextSize = o.NameSize or 13, StrokeThickness = 2, StrokeTransparency = 0, Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 16), ZIndex = 5, Parent = t })
	-- long names shrink to fit instead of being cut
	nameLabel.TextScaled = true
	make("UITextSizeConstraint", { MaxTextSize = o.NameSize or 13, MinTextSize = 8, Parent = nameLabel })
	UIKit.text({ Text = o.Big, TextSize = o.BigSize or 17, Color = o.BigColor or P.White, StrokeThickness = 2.5, StrokeTransparency = 0, Position = UDim2.fromScale(0, 0.66), Size = UDim2.new(1, 0, 0.17, 0), ZIndex = 5, Parent = t })
	if o.Small then
		UIKit.text({ Text = o.Small, TextSize = o.SmallSize or 13, StrokeThickness = 2, StrokeTransparency = 0, Position = UDim2.fromScale(0, 0.82), Size = UDim2.new(1, 0, 0.15, 0), ZIndex = 5, Parent = t })
	end
	if o.Check then
		checkBadge(t)
	end
	if o.Count then
		UIKit.text({ Text = o.Count, TextSize = 13, XAlign = Enum.TextXAlignment.Right, StrokeThickness = 2, StrokeTransparency = 0, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -4), Size = UDim2.fromOffset(40, 16), ZIndex = 6, Parent = t })
	end
	if o.OnClick then
		t.Activated:Connect(o.OnClick)
	end
	return t
end

-- a dark pill in a window header: a coloured dot and a line of text
local function headerPill(parent, text, dot, x, w)
	local p = make("Frame", { BackgroundColor3 = P.SpeedBlack, BackgroundTransparency = 0.1, Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 30), Parent = parent })
	UIKit.corner(p, UDim.new(0.5, 0))
	UIKit.stroke(p, P.Graphite, 2, 0)
	local d = make("Frame", { BackgroundColor3 = dot, Position = UDim2.new(0, 12, 0.5, -5), Size = UDim2.fromOffset(10, 10), Parent = p })
	UIKit.corner(d, UDim.new(0.5, 0))
	UIKit.text({ Text = text, TextSize = 15, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0), Parent = p })
	return p
end

-- boost lines of one coach at a stage: { text, colour }
local function boostLines(id, stage)
	local t, p, c = Boosts.coachValues(id, stage)
	local out = {}
	if t > 0 then
		table.insert(out, { ("+%d%% SPEED"):format(math.floor(t * 100 + 0.5)), P.Sky })
	end
	if c > 0 then
		table.insert(out, { ("+%d%% COINS"):format(math.floor(c * 100 + 0.5)), P.Gold })
	end
	if p > 0 then
		table.insert(out, { ("+%g%% RACE PACE"):format(math.floor(p * 1000 + 0.5) / 10), P.Mint })
	end
	return out
end

local function coachCounts()
	local byId, byStage = {}, {}
	for _, e in (coll and coll.Coaches) or {} do
		byId[e.Id] = (byId[e.Id] or 0) + 1
		local k = e.Id .. "_" .. e.Stage
		byStage[k] = (byStage[k] or 0) + 1
	end
	return byId, byStage
end

-- the nearest pity line: "EPIC GUARANTEED IN 37 ROLLS" and how full its bar is
local function pityLine()
	local best, bestLeft, bestFrac = nil, math.huge, 0
	for _, p in Coaches.Pity do
		local done = (coll and coll.Pity and coll.Pity[p.Rarity]) or 0
		local left = math.max(1, p.Rolls - done)
		if left < bestLeft then
			best, bestLeft, bestFrac = p, left, done / p.Rolls
		end
	end
	return best, bestLeft, bestFrac
end

local function goAgency()
	myWin.hide(true)
	local ok = ctx.Net.call("GoTo", "CoachCorner")
	if ok then
		task.wait(0.3)
		agencyWin.show()
	end
end

----------------------------------------------------------------------------
-- COACH AGENCY
----------------------------------------------------------------------------
function agencyPage()
	local page = agencyWin.page
	clear(page)
	local byId = coachCounts()
	local grid = make("Frame", { Name = "Odds", BackgroundTransparency = 1, Size = UDim2.fromOffset(440, 216), Parent = page })
	make("UIGridLayout", { CellSize = UDim2.fromOffset(104, 104), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	local right = make("Frame", { Name = "Actions", BackgroundTransparency = 1, Position = UDim2.fromOffset(452, 0), Size = UDim2.fromOffset(152, 216), Parent = page })
	local info = UIKit.text({ Name = "Info", Text = "Tap a coach to see the boost.", Font = F.BodyBold, TextSize = 13, Wrapped = true, Color = P.BrightBlue, Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, 40), Parent = right })
	for i, c in Coaches.List do
		local n = byId[c.Id] or 0
		local rc = Coaches.RarityColors[c.Rarity]
		local hidden = n == 0 and rarityIndex(c.Rarity) >= rarityIndex("Secret")
		tile(grid, {
			Size = UDim2.fromOffset(104, 104), LayoutOrder = i, Color = rc, CoachId = c.Id,
			Silhouette = n == 0, Hidden = hidden, Rays = rarityIndex(c.Rarity) >= rarityIndex("Epic"),
			Name = if hidden then "???" else string.upper(c.Name), NameSize = 12,
			Big = string.upper(c.Rarity), BigColor = rc, BigSize = 15, Small = pct(c.Chance),
			Check = n > 0, Count = if n > 1 then "x" .. n else nil,
			OnClick = function()
				local lines = {}
				for _, l in boostLines(c.Id, 1) do
					table.insert(lines, l[1])
				end
				info.Text = (if hidden then "???" else string.upper(c.Name)) .. ":  " .. table.concat(lines, "  ")
				ctx.Sound.play("Tab")
			end,
		})
	end
	-- coins, the pity line, ROLL / X3 / MY COACHES
	local coinsRow = make("Frame", { BackgroundColor3 = P.SpeedBlack, BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 30), Parent = right })
	UIKit.corner(coinsRow, UDim.new(0.5, 0))
	UIKit.stroke(coinsRow, P.Graphite, 2, 0)
	local ci = UIKit.coinIcon(20, coinsRow)
	ci.Position = UDim2.fromOffset(8, 5)
	UIKit.text({ Name = "Coins", Text = Format.short(player:GetAttribute("Coins") or 0), TextSize = 17, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0), Parent = coinsRow })
	local tier, left, frac = pityLine()
	if tier then
		local pity = make("Frame", { BackgroundColor3 = P.SpeedBlack, BackgroundTransparency = 0.1, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 34), Parent = right })
		UIKit.corner(pity, 10)
		UIKit.text({ Text = ("%s IN %d ROLLS"):format(string.upper(tier.Rarity), left), Font = F.BodyBold, TextSize = 13, Color = Coaches.RarityColors[tier.Rarity], Position = UDim2.fromOffset(0, 2), Size = UDim2.new(1, 0, 0, 18), Parent = pity })
		local barBack = make("Frame", { BackgroundColor3 = P.Graphite, Position = UDim2.new(0, 10, 0, 22), Size = UDim2.new(1, -20, 0, 6), Parent = pity })
		UIKit.corner(barBack, 3)
		local fill = make("Frame", { BackgroundColor3 = Coaches.RarityColors[tier.Rarity], Size = UDim2.fromScale(math.clamp(frac, 0.03, 1), 1), Parent = barBack })
		UIKit.corner(fill, 3)
	end
	local roll, label = UIKit.button({ Name = "Roll", Style = "Gold", Text = "ROLL", TextSize = 24, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 0, 52), Parent = right, OnClick = function()
		CoachUI.rollNow(1)
	end })
	label.Text = if price == 0 then "FREE ROLL!" else "ROLL  " .. Format.short(price)
	label.Size = UDim2.new(1, -40, 1, 0)
	if price > 0 then
		local rci = UIKit.coinIcon(20, roll.Face)
		rci.Position = UDim2.new(1, -30, 0.5, -10)
	end
	UIKit.button({ Name = "Roll3", Style = if fasterRolls() then "Blue" else "Dark", Text = "X3", TextSize = 18, Position = UDim2.fromOffset(0, 134), Size = UDim2.fromOffset(60, 38), Parent = right, OnClick = function()
		if fasterRolls() then
			CoachUI.rollNow(Store.FasterRolls.Count)
		else
			ctx.Hud.toast("The Faster Rolls pass rolls 3 at once (same odds)", "Gold")
			agencyWin.hide(true)
			ctx.Store.open("PASSES")
		end
	end })
	UIKit.button({ Name = "Mine", Style = "Dark", Text = "MY COACHES", TextSize = 13, Position = UDim2.fromOffset(66, 134), Size = UDim2.fromOffset(86, 38), Parent = right, OnClick = function()
		agencyWin.hide(true)
		myWin.show()
	end })
end

----------------------------------------------------------------------------
-- MY COACHES
----------------------------------------------------------------------------
function myPage()
	local page = myWin.page
	clear(page)
	if not coll then
		return
	end
	local slots = coll.Slots or 2
	local equipped = coll.EquippedCoaches or {}
	local list = table.clone(coll.Coaches)
	table.sort(list, function(a, b)
		local ea, eb = table.find(equipped, a.Uid) ~= nil, table.find(equipped, b.Uid) ~= nil
		if ea ~= eb then
			return ea
		end
		local ra, rb = rarityIndex(Boosts.coach(a.Id).Rarity), rarityIndex(Boosts.coach(b.Id).Rarity)
		if ra ~= rb then
			return ra > rb
		end
		if a.Stage ~= b.Stage then
			return a.Stage > b.Stage
		end
		return a.Uid < b.Uid
	end)
	local _, byStage = coachCounts()
	-- header: EQUIPPED / OWNED, BEST EQUIP, the way to the agency
	local header = make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Parent = page })
	headerPill(header, ("EQUIPPED %d/%d"):format(math.min(#equipped, slots), slots), P.Mint, 0, 150)
	headerPill(header, ("OWNED %d"):format(#list), P.Sky, 158, 110)
	UIKit.button({ Name = "Best", Style = "Gold", Text = "BEST EQUIP", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -148, 0, -2), Size = UDim2.fromOffset(120, 34), Parent = header, OnClick = function()
		if ctx.Net.call("BestEquip") then
			ctx.Sound.play("Equip")
		end
	end })
	UIKit.button({ Name = "Agency", Style = "Pink", Text = "COACH AGENCY", TextSize = 13, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, -2), Size = UDim2.fromOffset(140, 34), Parent = header, OnClick = goAgency })
	if #list == 0 then
		UIKit.text({ Text = "No coaches yet.", TextSize = 24, Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 30), Parent = page })
		UIKit.text({ Text = "Roll your first coach at the COACH AGENCY. Coaches follow you and make every step count more.", Font = F.BodyBold, TextSize = 15, Wrapped = true, Color = P.BrightBlue, Position = UDim2.new(0.5, -220, 0, 116), Size = UDim2.fromOffset(440, 40), Parent = page })
		UIKit.button({ Style = "Pink", Text = "GO TO THE AGENCY", TextSize = 18, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 170), Size = UDim2.fromOffset(240, 50), Parent = page, OnClick = goAgency })
		return
	end
	local pages = math.max(1, math.ceil(#list / PER_PAGE))
	myPageIndex = math.clamp(myPageIndex, 1, pages)
	local selected = nil
	for _, e in list do
		if e.Uid == selectedUid then
			selected = e
		end
	end
	selected = selected or list[(myPageIndex - 1) * PER_PAGE + 1] or list[1]
	selectedUid = selected.Uid
	-- the grid (8 a page)
	local grid = make("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 40), Size = UDim2.fromOffset(424, 208), Parent = page })
	make("UIGridLayout", { CellSize = UDim2.fromOffset(100, 100), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for i = (myPageIndex - 1) * PER_PAGE + 1, math.min(#list, myPageIndex * PER_PAGE) do
		local e = list[i]
		local coach = Boosts.coach(e.Id)
		local lines = boostLines(e.Id, e.Stage)
		tile(grid, {
			Size = UDim2.fromOffset(100, 100), LayoutOrder = i, Color = stageColor(e.Stage), CoachId = e.Id,
			Name = string.upper(coach.Name), NameSize = 12, Big = Coaches.Stages[e.Stage], BigColor = P.White, BigSize = 16,
			Small = lines[1] and lines[1][1] or nil, Check = table.find(equipped, e.Uid) ~= nil, Selected = e.Uid == selectedUid,
			OnClick = function()
				selectedUid = e.Uid
				ctx.Sound.play("Tab")
				myPage()
			end,
		})
	end
	-- pages
	local pager = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 250), Size = UDim2.fromOffset(424, 28), Parent = page })
	UIKit.button({ Style = "Dark", Text = "PREV", TextSize = 14, Size = UDim2.fromOffset(90, 28), Parent = pager, OnClick = function()
		myPageIndex = math.max(1, myPageIndex - 1)
		selectedUid = nil
		myPage()
	end })
	UIKit.text({ Text = ("PAGE %d / %d"):format(myPageIndex, pages), TextSize = 16, Position = UDim2.fromOffset(100, 0), Size = UDim2.fromOffset(224, 28), Parent = pager })
	UIKit.button({ Style = "Dark", Text = "NEXT", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(90, 28), Parent = pager, OnClick = function()
		myPageIndex = math.min(pages, myPageIndex + 1)
		selectedUid = nil
		myPage()
	end })
	-- the detail panel
	local coach = Boosts.coach(selected.Id)
	local sc = stageColor(selected.Stage)
	local isEq = table.find(equipped, selected.Uid) ~= nil
	local detail = UIKit.panel({ Name = "Detail", Accent = false, Position = UDim2.fromOffset(436, 40), Size = UDim2.fromOffset(228, 238), Parent = page })
	tile(detail, {
		Size = UDim2.fromOffset(118, 112), Position = UDim2.new(0.5, -59, 0, 8), Color = sc, CoachId = selected.Id,
		Name = string.upper(coach.Name), Big = Coaches.Stages[selected.Stage], BigSize = 18, BigColor = P.White,
		Small = string.upper(coach.Rarity), Check = isEq, Rays = selected.Stage >= 3,
	})
	local y = 126
	for _, l in boostLines(selected.Id, selected.Stage) do
		local dot = make("Frame", { BackgroundColor3 = l[2], Position = UDim2.fromOffset(16, y + 4), Size = UDim2.fromOffset(10, 10), Parent = detail })
		UIKit.corner(dot, UDim.new(0.5, 0))
		UIKit.text({ Text = l[1], TextSize = 15, Color = l[2], XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(32, y), Size = UDim2.new(1, -40, 0, 18), Parent = detail })
		y += 18
	end
	-- the next stage: 3 of the same coach at the same stage
	local have = byStage[selected.Id .. "_" .. selected.Stage] or 0
	local maxed = selected.Stage >= #Coaches.Stages
	UIKit.text({ Text = if maxed then "MAX STAGE" else ("NEEDS 3x %s  %d/3"):format(Coaches.Stages[selected.Stage], math.min(have, 3)), Font = F.BodyBold, TextSize = 13, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 180), Size = UDim2.new(1, -90, 0, 18), Parent = detail })
	if not maxed then
		for k = 1, 3 do
			local sq = make("Frame", { BackgroundColor3 = if k <= have then sc else P.SpeedBlack, Position = UDim2.new(1, -78 + (k - 1) * 22, 0, 180), Size = UDim2.fromOffset(18, 18), Parent = detail })
			UIKit.corner(sq, 4)
			UIKit.stroke(sq, sc, 2, 0)
		end
	end
	UIKit.button({ Name = "Equip", Style = if isEq then "Dark" else "Green", Text = if isEq then "UNEQUIP" else "EQUIP", TextSize = 16, Position = UDim2.fromOffset(10, 202), Size = UDim2.fromOffset(100, 32), Parent = detail, OnClick = function()
		local ok, why = ctx.Net.call("EquipCoach", selected.Uid)
		if ok then
			ctx.Sound.play("Equip")
		elseif why == "slots" then
			ctx.Hud.toast("Your coach slots are full. Unequip one first.", "Denied")
		end
	end })
	local canEvolve = not maxed and have >= Coaches.EvolveCost
	UIKit.button({ Name = "Evolve", Style = if canEvolve then "Pink" else "Dark", Text = if maxed then "MAX" else "EVOLVE", TextSize = 16, Position = UDim2.fromOffset(118, 202), Size = UDim2.fromOffset(100, 32), Parent = detail, OnClick = function()
		if not canEvolve then
			ctx.Hud.toast(if maxed then "This coach is at the top stage." else ("Get 3 %s %s to evolve."):format(coach.Name, Coaches.Stages[selected.Stage]), "Denied")
			return
		end
		local ok, res = ctx.Net.call("EvolveCoach", selected.Id, selected.Stage)
		if ok then
			selectedUid = res and res.Uid or selectedUid
			ctx.Sound.play("RevealEpic")
			ctx.Hud.toast(("%s evolved to %s!"):format(coach.Name, Coaches.Stages[selected.Stage + 1]), "Gold")
		end
	end })
end

----------------------------------------------------------------------------
-- rolling (only at an agency: the server checks)
----------------------------------------------------------------------------
function fasterRolls()
	return coll ~= nil and coll.Passes ~= nil and coll.Passes.FasterRolls == true
end

function CoachUI.rollNow(count)
	if rolling then
		return
	end
	rolling = true
	count = count or 1
	local got = {}
	for i = 1, count do
		local ok, result = ctx.Net.call("RollCoach")
		if ok then
			table.insert(got, result)
			if not fasterRolls() then
				agencyWin.hide(true)
				CoachUI.reveal(result)
				agencyWin.show()
			end
		else
			ctx.Sound.play("Denied")
			if result == "coins" then
				ctx.Hud.toast(if i == 1 then "Not enough coins to roll yet" else ("Rolled %d - not enough coins for more"):format(i - 1), "Denied")
			elseif result == "agency" then
				ctx.Hud.toast("Rolls happen at the COACH AGENCY", "Denied")
			end
			break
		end
	end
	if #got > 0 and fasterRolls() then
		local names = {}
		local best = got[1]
		for _, r in got do
			local c = Boosts.coach(r.Id)
			table.insert(names, c and c.Name or r.Id)
			if rarityIndex(r.Rarity) > rarityIndex(best.Rarity) then
				best = r
			end
		end
		ctx.Sound.play("KaChing")
		ctx.Hud.toast("You got: " .. table.concat(names, ", "), "Gold")
		-- big pulls still get their moment
		if rarityIndex(best.Rarity) >= rarityIndex("Legendary") then
			agencyWin.hide(true)
			CoachUI.reveal(best)
			agencyWin.show()
		end
	end
	rolling = false
end

local function refresh()
	if agencyWin.isOpen() then
		agencyPage()
	end
	if myWin.isOpen() then
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

-- "ROLL" = the agency, anything else = MY COACHES
function CoachUI.open(which)
	if which == "ROLL" then
		agencyWin.show()
	else
		myWin.show()
	end
end

function CoachUI.start(c)
	ctx = c
	ctx.Coaches = CoachUI
	buildOverlay()
	agencyWin = UIKit.window({ Name = "CoachAgency", Title = "COACH AGENCY", Size = Vector2.new(640, 270), Accent = P.Pink, Parent = ctx.Hud.canvas })
	agencyWin.page = make("Frame", { Name = "Page", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 1, -4), Parent = agencyWin.content })
	myWin = UIKit.window({ Name = "Coaches", Title = "MY COACHES", Size = Vector2.new(700, 330), Accent = P.Gold, Parent = ctx.Hud.canvas })
	myWin.page = make("Frame", { Name = "Page", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 1, -4), Parent = myWin.content })
	agencyWin.onOpen = function()
		agencyPage()
		task.spawn(function()
			local ok, p = ctx.Net.call("RollPrice")
			if ok and p then
				price = p
				if agencyWin.isOpen() then
					agencyPage()
				end
			end
		end)
	end
	myWin.onOpen = function()
		myPage()
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
