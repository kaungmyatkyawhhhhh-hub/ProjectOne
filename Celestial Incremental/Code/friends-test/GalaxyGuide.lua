-- GalaxyGuide (Galaxy Incremental, alpha part 2, 3 Nov): the GUIDE BOOK (key G + the hotbar's G). Design additions 1
-- (Regrowth lesson): one page per feature, a picture + 3 short lines; a page unlocks when its feature does ("?" until then);
-- a red dot on every new page you haven't opened (and on the hotbar's G while there is one). Which pages you've opened is
-- in your save (EconRequest "GuideSeen", id -> the "GuideSeen" attribute, comma-separated).
-- The window is the v12 frame (Kit.window, the UPGRADES window's look and size): the page list on the left (the UPGRADES
-- window's category list), the page on the right. Pictures = screenshots of the real game taken in Studio (UIAssets.guide).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: closes only by X, Esc / B, outside)
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local A = Kit.A
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local function attr(n: string) return player:GetAttribute(n) or 0 end
local function ranksLine(): string
	local t = {}
	for _, r in ipairs(MapConfig.Ranks) do table.insert(t, r.name .. " " .. r.at) end
	return table.concat(t, ", ")
end

-- the pages, in the order they unlock. unlocked() = the feature is open; lockedText = what opens it
local PAGES = {
	{ id = "Stardust", tab = "STARDUST", title = "STARDUST & BODIES", icon = "stardust", glow = Color3.fromRGB(255, 170, 60), c1 = "#ff9a3a", c2 = "#c2410c",
		lines = { "Your bodies orbit your star and earn STARDUST.",
			"Buy more on the BODIES board or in UPGRADES.",
			"25, 50, 100... of one body = x2 its income!" },
		unlocked = function() return true end },
	{ id = "Island", tab = "ISLAND", title = "ISLAND & BOARDS", icon = "planet", glow = Color3.fromRGB(170, 130, 255), c1 = "#b49bff", c2 = "#5a3ad8",
		lines = { "This island is yours: your system grows here.",
			"Walk up to its boards to buy and upgrade.",
			"Every new body pops in for all to see." },
		unlocked = function() return true end },
	{ id = "Tree", tab = "TREE", title = "CONSTELLATION TREE", icon = "sun", glow = Color3.fromRGB(125, 255, 138), c1 = "#7dff7a", c2 = "#1fa83a",
		lines = { "Ring 1 costs stardust: new bodies, boosts.",
			"Ring 2 costs SHARDS and is never reset.",
			"Open it with T or on your TREE board." },
		unlocked = function() return attr("TutStep") >= 2 end, lockedText = "PERK: FIRST LIGHT" },
	{ id = "Comets", tab = "COMETS", title = "COMETS", icon = "comet", glow = Color3.fromRGB(90, 200, 255), c1 = "#5ad1ff", c2 = "#1f6fd1",
		lines = { "A comet flies past every " .. Econ.Comet.Every .. " s. Tap it!",
			"A catch pays " .. Econ.Comet.ValueMin .. "-" .. Econ.Comet.ValueMax .. " s of your income.",
			"The COMET LURE perk brings them sooner." },
		unlocked = function() return attr("TutStep") >= 5 or attr("CometsCaught") >= 1 end, lockedText = "CATCH A COMET" },
	{ id = "Supernova", tab = "SUPERNOVA", title = "SUPERNOVA & SHARDS", icon = "shard", glow = Color3.fromRGB(170, 110, 255), c1 = "#ffe27a", c2 = "#e08a0a",
		lines = { "Earn " .. Econ.Format(Econ.NeedFor(0)) .. " in your first run: SUPERNOVA is ready.",
			"It resets your run and gives SHARDS.",
			"Earn more before you go = more shards." },
		unlocked = function() return attr("TutStep") >= 8 or attr("Supernovas") >= 1 end, lockedText = "TUTORIAL STEP 9" },
	{ id = "Surge", tab = "STAR SURGE", title = "STAR SURGE", icon = "stardust", glow = Color3.fromRGB(255, 120, 30), c1 = "#ff9a3a", c2 = "#c2410c",
		lines = { "Each Supernova fills the plaza's bar " .. MapConfig.Surge.PerSupernova .. "%.",
			"Full bar: x" .. MapConfig.Surge.Mult .. " stardust for ALL for " .. math.floor(MapConfig.Surge.Duration / 60) .. " min.",
			"More Supernovas = more surges." },
		unlocked = function() return attr("Supernovas") >= 1 end, lockedText = "SUPERNOVA 1" },
	{ id = "Ranks", tab = "RANKS", title = "RANKS", icon = "sun", glow = Color3.fromRGB(255, 200, 90), c1 = "#ffe27a", c2 = "#e08a0a",
		lines = { "Supernovas give you a RANK over your head.",
			ranksLine(),
			"Everyone sees it on you and your island." },
		unlocked = function() return attr("Supernovas") >= 1 end, lockedText = "SUPERNOVA 1" },
}

------------------------------------------------------------------------ screen
local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyGuide"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
-- (Studio phone check: the same 667x375 frame as GalaxyHUD)
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local root: GuiObject | ScreenGui = gui
if PHONE_TEST then
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	f.Parent = gui
	root = f
end
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end

------------------------------------------------------------------------ the window (700 x 470, like UPGRADES)
local holder = Kit.box(root, 0, 0, 700, 470, { Name = "GuideWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, 700, 470, { title = "GUIDE BOOK", icon = "book", iconGlow = Color3.fromRGB(170, 120, 255),
	c1 = hex("#3a1f7a"), c2 = hex("#7a4cff"), lip = hex("#5a34c8"), glow = Color3.fromRGB(140, 80, 255), line = hex("#a77bff") })
Kit.panel(win, 16, 74, 190, 380)
Kit.panel(win, 218, 74, 466, 380)

-- the page list (the UPGRADES window's category buttons, 166 x 42 here so all 7 fit)
local tabs = {}
local current = "Stardust"
local seen = {}
local function readSeen()
	table.clear(seen)
	for id in string.gmatch(tostring(player:GetAttribute("GuideSeen") or ""), "[^,]+") do seen[id] = true end
end
readSeen()

-- the page
local pic = Kit.new("ImageLabel", { Name = "Picture", BackgroundColor3 = hex("#05040a"), BackgroundTransparency = 0, Position = UDim2.fromOffset(251, 86),
	Size = UDim2.fromOffset(400, 225), ScaleType = Enum.ScaleType.Crop, ZIndex = 6 }, win)
Kit.corner(pic, 6)
Kit.stroke(pic, Kit.INK, 2)
local picEdge = Kit.box(win, 249, 84, 404, 229, { ZIndex = 5 })
Kit.corner(picEdge, 7)
local picStroke = Kit.stroke(picEdge, hex("#a77bff"), 2, 0.2)
local unknown = Kit.text(win, 251, 140, 400, 110, "?", 110, { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 4,
	gradient = ColorSequence.new(hex("#e9e2f5"), hex("#8a8296")) })
local pageTitle = Kit.text(win, 232, 318, 440, 28, "", 24, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
local lineLabels = {}
for i = 1, 3 do
	lineLabels[i] = Kit.text(win, 232, 350 + (i - 1) * 32, 444, 26, "", 18, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0"), stroke = 1.3 })
end
local function isNew(p): boolean return p.unlocked() and not seen[p.id] end

local function showPage(id: string)
	current = id
	local p
	for _, q in ipairs(PAGES) do if q.id == id then p = q end end
	if not p then return end
	local open = p.unlocked()
	for _, t in pairs(tabs) do
		t.sel.Visible = t.page.id == id
	end
	pic.Image = if open then (A.guide and A.guide[p.id]) or "" else ""
	pic.ImageTransparency = 0
	unknown.Parent.Visible = not open
	picStroke.Color = if open then hex(p.c1) else hex("#5a5562")
	Kit.setText(pageTitle, if open then p.title else "???")
	pageTitle.TextColor3 = if open then hex(p.c1) else hex("#a99fb8")
	-- the 3 lines share one size: 18, or smaller until the longest fits on its row
	local size = 18
	local params = Instance.new("GetTextBoundsParams")
	params.Font = Kit.FONT_BOLD
	params.Width = 10000
	while size > 12 do
		local fits = true
		for i = 1, 3 do
			params.Text = if open then p.lines[i] else ""
			params.Size = size
			local ok, b = pcall(function() return TextService:GetTextBoundsAsync(params) end)
			if ok and b.X > 440 then fits = false end
		end
		if fits then break end
		size -= 1
	end
	for i = 1, 3 do
		Kit.setText(lineLabels[i], if open then p.lines[i] elseif i == 1 then "Unlocks at: " .. p.lockedText else "")
		for _, l in ipairs(lineLabels[i].Parent:GetChildren()) do
			if l:IsA("TextLabel") then l.TextSize = size end
		end
	end
	if open and not seen[p.id] then
		seen[p.id] = true
		task.spawn(function() request:InvokeServer("GuideSeen", p.id) end)
	end
end

local function refreshTabs()
	local anyNew = false
	for _, t in pairs(tabs) do
		local p = t.page
		local open = p.unlocked()
		Kit.recolour(t.button, if open then hex(p.c1) else hex("#6a6474"), if open then hex(p.c2) else hex("#3f3a48"))
		Kit.setText(t.label, if open then p.tab else "?")
		t.label.TextColor3 = if open then Color3.new(1, 1, 1) else hex("#cfc6dd")
		t.icon.ImageTransparency = if open then 0 else 0.6
		t.lock.Parent.Visible = not open
		t.dot.Visible = isNew(p)
		if isNew(p) then anyNew = true end
	end
	if shared.GalaxyHotbarDot then shared.GalaxyHotbarDot("G", anyNew) end
end

for i, p in ipairs(PAGES) do
	local x, y = 28, 82 + (i - 1) * 52
	local b, inner = Kit.button(win, x, y, 166, 42, hex(p.c1), hex(p.c2), { ZIndex = 6 })
	local label = Kit.text(inner, 30, Kit.ps(9, 8), 132, 26, p.tab, Kit.ps(17, 20), { ZIndex = inner.ZIndex, stroke = 1.6, TextXAlignment = CENTRE })
	local icon = Kit.icon(win, p.icon, x - 12, y - 6, 50, nil, { ZIndex = 9 })
	local lockIcon = Kit.icon(win, "lock", x + 138, y + 18, 24, nil, { ZIndex = 10 })
	-- the selected page: a pulsing gold outline round its button
	local sel = Kit.box(win, x - 3, y - 3, 172, 48, { ZIndex = 5, Visible = false })
	Kit.corner(sel, 7)
	local st = Kit.stroke(sel, hex("#ffd84a"), 3)
	if not Kit.calm() then Kit.tween(st, { Transparency = 0.6 }, 0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) end
	local dot = Kit.redDot(win, x + 162, y + 4, 16, 12)
	tabs[p.id] = { page = p, button = b, label = label, icon = icon, lock = lockIcon, sel = sel, dot = dot }
	b.MouseButton1Click:Connect(function()
		Kit.sound("tab")
		showPage(p.id)
		refreshTabs()
	end)
end

------------------------------------------------------------------------ open / close (GalaxyHUD hides the phone hotbar while it's open)
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s -- (6 Nov overlap check: under the GALAXY LIT bar + the counter's SUPERNOVA bar)
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (470 + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (700 + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end
local function close()
	if not isOpen then return end
	isOpen = false
	Kit.sound("close")
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("G", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("G") end
	isOpen = true
	Kit.sound("open")
	-- the newest page you haven't opened yet, else the last one you looked at
	for _, p in ipairs(PAGES) do
		if isNew(p) then current = p.id break end
	end
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("G", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
	showPage(current)
	refreshTabs()
end
shared.GalaxyGuideToggle = function() if isOpen then close() else open() end end
shared.GalaxyGuideRefresh = refreshTabs -- (GalaxyHUD calls it once its hotbar's red dot exists)
shared.GalaxyGuideClose = close
WM.register("G", holder, close)
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)

-- pages unlock as you play: the red dots follow
for _, n in ipairs({ "TutStep", "Supernovas", "CometsCaught" }) do
	player:GetAttributeChangedSignal(n):Connect(refreshTabs)
end
player:GetAttributeChangedSignal("GuideSeen"):Connect(function()
	readSeen()
	refreshTabs()
end)
task.defer(refreshTabs)
