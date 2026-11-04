-- UpgradesPanel (Galaxy Incremental): the approved v12 UPGRADES window, built once here and used twice (one source of truth):
--  * the 2D window (GalaxyHUD, hotbar U) and
--  * the live island board (GalaxyBoards: a SurfaceGui on the island's UPGRADES panel, canvas 745 x 512 = the v12 board
--    PNG / 2, the window at (30, 32) like in Map\images\board_upgrades_v12.png).
-- Layout = Celestial Incremental\UI\galaxy_ui_v12_animated.html (700 x 470 window; every x / y below is that file's).
-- The numbers come from EconConfig + the SUBJECT player's attributes (the island owner on a board: visitors see the owner's
-- numbers); buying goes through opts.buy (EconRequest). Textures never move; only glows / sparkles / shines do.
--
-- UpgradesPanel.new(parent, opts) -> panel
--   opts.subject      Player (or anything with :GetAttribute) whose numbers are shown
--   opts.origin       Vector2: the window's top-left inside `parent` (default 0, 0)
--   opts.chip         "ESSENCE" | "SHARDS" (the header currency pill)
--   opts.close        true = the pink X (2D window only)
--   opts.pointer      a SurfaceGui (boards): screen position -> the point in the gui's pixels (Kit.scroller's mouse drag)
--   opts.edgeGlow     true = a rotating UIGradient on the frame edge (boards); false = the breathing 9-slice glow
--   opts.canAct()     false = a visitor: every buy button grey "VISIT"
--   opts.buy(kind, arg) -> ok     ("BuyBody", k | "BuyNode", id)
--   opts.onBought(rowFrame, incomeBefore), opts.toast(text, colour), opts.sound(name)
-- panel: .root, .tabUI, .targets (tutorial: "Body0", "Unlock1", "Node_FirstLight" -> the button), .currentTab,
--        :selectTab(id), :refresh(), :reveal(button), .closeButton, .chipText, :destroy()
-- The rows are ONE scrolling list per tab, on the boards too (owner, boards fix 2: no pages). A refresh only updates the
-- rows' text and buttons; the list (and where it is scrolled to) is rebuilt only when the tab changes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local A = Kit.A
local hex = Kit.hex
local fmt = Econ.Format

local Panel = {}
Panel.__index = Panel

Panel.TABS = {
	-- (feel pass, 5 Nov: BODIES = the BODIES board's rows; PERKS = the PERKS board's perks, bought with XP)
	{ id = "BODIES", c1 = "#b49bff", c2 = "#5a3ad8", icon = "planet", glow = Color3.fromRGB(170, 130, 255) },
	{ id = "PERKS", c1 = "#5ad1ff", c2 = "#1f6fd1", icon = "sun", glow = Color3.fromRGB(90, 200, 255) },
	{ id = "FORGE", c1 = "#6a6474", c2 = "#3f3a48", icon = "forge", glow = nil, locked = "IGNITION 1",
		lockedTitle = "STAR FORGE", lockedText = "Roll Star Cores with Essence: hotbar F once IGNITION 1 opens Sector 2." },
	{ id = "BLACK HOLE", c1 = "#5a5562", c2 = "#38343f", icon = "gear", glow = nil, locked = "100K SHARDS",
		lockedTitle = "BLACK HOLE", lockedText = "Collapse your shards into Dark Matter. Opens at 100K shards." },
}
local GREEN1, GREEN2 = hex("#7dff7a"), hex("#1fa83a")
local GREY1, GREY2 = hex("#6a6474"), hex("#3f3a48")
local VIO1, VIO2 = hex("#b49bff"), hex("#5a3ad8")
local TIER_LOOK = { -- border, title gradient, icon glow
	{ "#9a8cb0", "#f3eaff", "#b9a8cc", Color3.fromRGB(200, 180, 230) },
	{ "#3a8acc", "#ffffff", "#bfe9ff", Color3.fromRGB(90, 200, 255) },
	{ "#8a6cff", "#efe8ff", "#b49bff", Color3.fromRGB(170, 130, 255) },
	{ "#ff9a3a", "#fff1c0", "#ffb02a", Color3.fromRGB(255, 120, 30) },
	{ "#5a5562", "#cfc6dd", "#8a8296", nil },
	{ "#ff7a5a", "#fff1c0", "#ff9a7a", Color3.fromRGB(255, 140, 110) },
}
local TAB_LOOK = {
	STARDUST = { "#ff9a3a", "#fff1c0", "#ffb02a", Color3.fromRGB(255, 120, 30) },
	COMETS = { "#3a8acc", "#ffffff", "#bfe9ff", Color3.fromRGB(90, 200, 255) },
}

function Panel.new(parent: Instance, opts)
	local self = setmetatable({}, Panel)
	self.opts = opts
	self.subject = opts.subject
	self.targets = {}
	self.rows = {}
	self.currentTab = opts.startTab or "BODIES"
	local o = opts.origin or Vector2.zero
	local win = Kit.box(parent, o.X, o.Y, 700, 470, { Name = "UpgradesWindow" })
	self.root = win

	------------------------------------------------------------------ frame, header, chip
	if opts.edgeGlow then
		-- a glowing edge whose light runs round the frame (UIGradient rotating on a thick stroke; the texture never moves)
		local edge = Kit.box(win, -4, -4, 708, 478, { BackgroundTransparency = 1, ZIndex = 1 })
		Kit.corner(edge, 14)
		local st = Kit.stroke(edge, Color3.new(1, 1, 1), 6)
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, hex("#ff6a1a")), ColorSequenceKeypoint.new(0.5, hex("#ffd27a")), ColorSequenceKeypoint.new(1, hex("#ff6a1a")) })
		g.Parent = st
		self.edgeGradient = g
	else
		local glow = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.glow9, ImageColor3 = Color3.fromRGB(255, 100, 20), ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(48, 48, 80, 80), Position = UDim2.fromOffset(-34, -34), Size = UDim2.fromOffset(768, 538), ImageTransparency = 0.25, ZIndex = 1 }, win)
		if not Kit.calm() then
			Kit.tween(glow, { ImageTransparency = 0, Position = UDim2.fromOffset(-44, -44), Size = UDim2.fromOffset(788, 558) }, 1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		end
	end
	local frame = Kit.box(win, 0, 0, 700, 470, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 2 })
	Kit.corner(frame, 10)
	local body = Kit.box(win, 3, 3, 694, 464, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.corner(body, 8)
	Kit.grad(body, hex("#1a1620"), hex("#0f0d13"), 90)
	Kit.stroke(body, Color3.fromRGB(255, 106, 26), 1.5, 0.45)
	local header = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.header, ImageRectOffset = Vector2.new(0, 12), ImageRectSize = Vector2.new(694, 56),
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(694, 56), ZIndex = 4, ClipsDescendants = true }, win)
	Kit.corner(header, 8)
	Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.header, ImageRectOffset = Vector2.new(0, 58), ImageRectSize = Vector2.new(694, 10),
		Position = UDim2.fromOffset(3, 49), Size = UDim2.fromOffset(694, 10), ZIndex = 4 }, win)
	Kit.box(win, 9, 4, 682, 2, { BackgroundTransparency = 0.4, BackgroundColor3 = Color3.fromRGB(255, 208, 160), ZIndex = 5 })
	local sweep = Kit.shine(header, 4.5, 0.16, 0.35)
	sweep.ZIndex = 5
	for i, ex in ipairs({ 20, 90, 170, 260, 350, 430, 520, 610, 660 }) do
		Kit.ember(win, ex + 3, 3 + 44 + ((i - 1) % 3) * 4, ((i - 1) * 0.41) % 3)
	end
	Kit.box(win, 3, 59, 694, 2, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 5 })
	Kit.icon(win, "stardust", -22, -30, 92, Color3.fromRGB(255, 170, 60), { ZIndex = 9 })
	Kit.sparkle(win, -26, -24, 12, 0.5)
	Kit.sparkle(win, 60, 34, 9, 1.1)
	Kit.text(win, 80, 13, 300, 34, "UPGRADES", 28, { ZIndex = 8, stroke = 1.8 })
	local chipName = opts.chip or "ESSENCE"
	local chip = Kit.box(win, 438, 13, 150, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 })
	Kit.corner(chip, 4)
	Kit.stroke(chip, Kit.INK, 2)
	if chipName == "SHARDS" then Kit.grad(chip, hex("#3a1f7a"), hex("#7a4cff"), 0) else Kit.grad(chip, hex("#0f5a5a"), hex("#22c7b8"), 0) end
	self.chipText = Kit.text(win, 470, 10, 70, 24, "0", 20, { ZIndex = 8, stroke = 1.5, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(win, 470, Kit.ps(33, 31), 70, Kit.ps(12, 16), chipName, Kit.ps(9, 14), { ZIndex = 8, stroke = 1, TextColor3 = if chipName == "SHARDS" then hex("#e6dcff") else hex("#dcfffb"), TextXAlignment = Enum.TextXAlignment.Center })
	if chipName == "SHARDS" then
		Kit.icon(win, "shard", 548, 2, 50, Color3.fromRGB(170, 110, 255), { ZIndex = 8 })
	else
		Kit.icon(win, "essence", 548, 2, 50, Color3.fromRGB(60, 230, 210), { ZIndex = 8 })
	end
	self.chipName = chipName
	if opts.close then
		local closeBtn = Kit.new("TextButton", { Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(648, 13), Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, win)
		Kit.corner(closeBtn, 6)
		Kit.stroke(closeBtn, Color3.new(1, 1, 1), 2, 0.1)
		Kit.grad(closeBtn, hex("#ff7d8e"), hex("#e2334c"), 90)
		for _, r in ipairs({ 45, -45 }) do
			local bar = Kit.box(closeBtn, 0, 0, 20, 4, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = r, ZIndex = 9 })
			bar.Position = UDim2.fromScale(0.5, 0.5)
			Kit.corner(bar, 2)
		end
		local sh = Kit.box(win, 648, 15, 34, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 7 })
		Kit.corner(sh, 6)
		self.closeButton = closeBtn
	end

	------------------------------------------------------------------ category list (panel 16,74 190x380; buttons 28, 88 + i*58)
	local listPanel = Kit.box(win, 16, 74, 190, 380, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 4 })
	Kit.corner(listPanel, 6)
	Kit.stroke(listPanel, hex("#2a2433"), 1.5)
	self.tabUI = {}
	for i, t in ipairs(Panel.TABS) do
		local x, y = 28, 88 + (i - 1) * 58
		local b, inner = Kit.button(win, x, y, 166, 46, hex(t.c1), hex(t.c2), { ZIndex = 6 })
		if t.locked then
			Kit.text(inner, 30, Kit.ps(5, 2), 136, 20, t.id, Kit.ps(15, 19), { ZIndex = inner.ZIndex, stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
			Kit.text(inner, 30, Kit.ps(26, 25), 136, Kit.ps(14, 20), t.locked, Kit.ps(10, 17), { ZIndex = inner.ZIndex, stroke = 1.1, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#a99fb8") })
			Kit.icon(win, "lock", x + 140, y + 22, 26, nil, { ZIndex = 10 })
		else
			Kit.text(inner, 30, Kit.ps(12, 10), 136, 26, t.id, Kit.ps(17, 20), { ZIndex = inner.ZIndex, stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Center })
		end
		local img = Kit.icon(win, t.icon, x - 12, y - 8, if t.icon == "forge" then 56 else 54, t.glow, { ZIndex = 9 })
		if t.locked then img.ImageTransparency = 0.35 end
		self.tabUI[t.id] = { button = b, inner = inner, x = x, y = y, def = t }
		b.MouseButton1Click:Connect(function()
			self:sound("tab")
			self:selectTab(t.id)
		end)
	end
	Kit.sparkle(win, 30, 82, 10, 0.4)
	Kit.sparkle(win, 180, 128, 8, 1.2)

	------------------------------------------------------------------ rows panel (218,74 466x380; rows 8, 12 + i*120, 446x110)
	-- one scrolling list (Kit.scroller: the gold thumb on its dark track at the right edge, 3 px in from top and bottom)
	local rowsBg = Kit.box(win, 218, 74, 466, 380, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 4 })
	Kit.corner(rowsBg, 6)
	Kit.stroke(rowsBg, hex("#2a2433"), 1.5)
	self.rowsPanel, self.scroll = Kit.scroller(win, 218, 77, 464, 374, "Y", { ZIndex = 4, pointer = opts.pointer })

	self.busy = false
	self:selectTab(self.currentTab)
	return self
end

------------------------------------------------------------------------ state
function Panel:attr(name: string)
	local s = self.subject
	return s and s:GetAttribute(name)
end
-- each body type's LEVEL and copies (feel pass)
function Panel:owned(): { number }
	local t = {}
	for k = 1, #Econ.Tiers do t[k] = self:attr("Own" .. k) or 0 end
	return t
end
function Panel:copies(): { number }
	local t = {}
	for k = 1, #Econ.Tiers do t[k] = self:attr("Copies" .. k) or 0 end
	return t
end
function Panel:nodes()
	local t = {}
	for _, n in ipairs(Econ.Ring1) do t[n.id] = self:attr("Node_" .. n.id) == true end
	return t
end
function Panel:stardust(): number return self:attr("Stardust") or 0 end
function Panel:canAct(): boolean
	return self.opts.canAct == nil or self.opts.canAct()
end
function Panel:sound(name: string)
	if self.opts.sound then self.opts.sound(name) end
end
-- ring 2 levels (shards; opens the Star tiers)
function Panel:ring2()
	local t = {}
	for _, n in ipairs(Econ.Ring2) do t[n.id] = self:attr("R2_" .. n.id) or 0 end
	return t
end
-- this press turned into a scroll (a drag on the list): its button must not buy
function Panel:dragged(): boolean
	return self.scroll.moved
end

------------------------------------------------------------------------ rows
-- the button area of a row (146x52 at 288,30): rebuilt when its state changes
function Panel:setButton(row, state: string, price: number?, label: string?)
	if not self:canAct() and state ~= "owned" and state ~= "locked" then state, label = "visit", nil end
	local key = state .. "|" .. (price and fmt(price) or "") .. "|" .. (label or "")
	if row.btnKey == key then return end
	row.btnKey = key
	if row.btn then row.btn:Destroy() row.btnShadow:Destroy() end
	if row.fx then row.fx:Destroy() end
	row.fx = Kit.box(row.frame, 0, 0, 446, 110, { ZIndex = 9 })
	local c1, c2 = GREEN1, GREEN2
	if state == "no" or state == "locked" or state == "visit" then c1, c2 = GREY1, GREY2 elseif state == "owned" then c1, c2 = VIO1, VIO2 end
	local b, inner, _, shadow = Kit.button(row.frame, 288, if row.copyRow then 14 else 30, 146, if row.copyRow then 62 else 52, c1, c2, { ZIndex = 6 })
	row.btn, row.btnShadow = b, shadow
	local z = inner.ZIndex
	if state == "owned" then
		Kit.text(inner, 0, 10, 146, 32, label or "OWNED", 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY })
		Kit.shine(b, 3.6)
		Kit.sparkle(row.fx, 288 + 134, 30 - 4, 10, 0.5)
		Kit.sparkle(row.fx, 288 - 4, 30 + 44, 8, 1.5)
	elseif state == "visit" then
		Kit.text(inner, 0, 10, 146, 32, "VISIT", 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
	elseif state == "locked" then
		local img = Kit.icon(inner, "lock", 10, 10, 30, nil, { ZIndex = z })
		img.ImageTransparency = 0.2
		Kit.text(inner, 38, Kit.ps(15, 12), 104, 28, label or "LOCKED", if #(label or "LOCKED") > 9 then Kit.ps(13, 18) else Kit.ps(18, 20), { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
	else
		local top = 10
		if label then
			Kit.text(inner, 0, 2, 146, Kit.ps(14, 20), label, Kit.ps(11, 18), { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, stroke = 1.2 })
			top = 16
		end
		local ic = Kit.icon(inner, row.currency or "stardust", 14, top + 2, if label then 22 else 26, nil, { ZIndex = z })
		if state == "no" then ic.ImageTransparency = 0.3 end
		local priceStr = if price == 0 then "FREE" else fmt(price or 0)
		Kit.text(inner, 40, top, 100, 30, priceStr, if label then 20 else 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if state == "no" then hex("#ff6b6b") else Color3.new(1, 1, 1) })
		if state == "buy" then
			Kit.shine(b, 2.4)
			for _, m in ipairs({ { 20, 40, 0 }, { 60, 44, 0.6 }, { 100, 42, 1.2 }, { 124, 40, 0.3 } }) do Kit.mote(b, m[1], m[2], m[3]) end
			Kit.sparkle(row.fx, 288 + 128, 30 - 6, 12, 0)
			Kit.sparkle(row.fx, 288 - 6, 30 + 40, 10, 0.8)
			Kit.sparkle(row.fx, 288 + 70, 30 - 8, 8, 1.3)
		end
	end
	-- hover: a light lift (press = Kit.button's own drop into the lip)
	b.MouseEnter:Connect(function() if row.btn == b then Kit.tween(b, { Size = UDim2.fromOffset(150, 54) }, 0.1) end end)
	b.MouseLeave:Connect(function() if row.btn == b then Kit.tween(b, { Size = UDim2.fromOffset(146, 52) }, 0.1) end end)
	if state ~= "visit" then row.onButton(b) end
end

function Panel:newRowFrame(i, borderHex)
	local y = 9 + (i - 1) * 120
	local f = Kit.box(self.rowsPanel, 8, y, 446, 110, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	Kit.corner(f, 5)
	Kit.stroke(f, hex(borderHex), 2)
	Kit.grad(f, hex("#17141c"), hex("#0e0c12"), 90)
	return f
end
function Panel:chip(row, from: string, to: string?)
	if row.chipKey == from .. "|" .. (to or "") then return end
	row.chipKey = from .. "|" .. (to or "")
	if row.chip then row.chip:Destroy() end
	local holder = Kit.box(row.frame, 86, Kit.ps(60, 74), 300, 32, { ZIndex = 6 })
	row.chip = holder
	-- sized to the text (v12: 160 wide with an arrow, 80 without, never smaller)
	local sz = Kit.ps(17, 19)
	local function width(str) return TextService:GetTextSize(str, sz, Enum.Font.GothamBlack, Vector2.new(400, 30)).X + 4 end
	local fromW = width(from)
	local w = if to then math.max(160, 10 + fromW + 20 + width(to) + 10) else math.max(80, fromW + 20)
	local c = Kit.box(holder, 0, 0, w, 32, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(c, 4)
	Kit.stroke(c, hex("#3a3346"), 1.5)
	Kit.text(holder, 10, 4, fromW, 24, from, sz, { ZIndex = 7, stroke = 1.5 })
	if to then
		Kit.text(holder, fromW + 12, 3, 16, 24, ">", 18, { ZIndex = 7, TextColor3 = hex("#9a90a8") })
		Kit.text(holder, fromW + 28, 4, w - fromW - 30, 24, to, sz, { ZIndex = 7, stroke = 1.5, TextColor3 = hex("#7dff6b") })
	end
end

-- hold-to-buy (bodies): a tap buys once (on release); held 0.4 s it buys every 0.12 s while held. A press that turns into
-- a scroll of the list (drag) buys nothing (the boards and phones scroll by dragging over the rows). The hold ends when the
-- mouse / finger is let go (not on the button: a buy changes the price, which rebuilds the button under the finger).
local function holdBuy(b: GuiButton, buyOnce: () -> boolean, dragged: () -> boolean)
	local holding, repeated, presses = false, false, 0
	local function stop() holding = false end
	b.MouseButton1Down:Connect(function()
		presses += 1
		local id = presses
		holding, repeated = true, false
		local released
		released = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if id == presses then stop() end
				released:Disconnect()
			end
		end)
		task.wait(0.4)
		if not holding or id ~= presses or dragged() then return end
		repeated = true
		while holding and id == presses and not dragged() do
			if not buyOnce() then break end
			task.wait(0.12)
		end
	end)
	b.MouseButton1Click:Connect(function()
		if not repeated and not dragged() then buyOnce() end
	end)
	b.MouseButton1Up:Connect(stop)
	b.MouseLeave:Connect(stop)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then stop() end
	end)
end

function Panel:bought(row, before: number)
	self:sound("buy")
	-- a number pop on the row: "+x/s" rising from the button
	task.defer(function()
		local now = self:attr("Income") or 0
		if now > before then
			local main, _, holder = Kit.text(row.frame, 280, 4, 160, 26, "+" .. fmt(now - before) .. "/s", 20, { ZIndex = 12, TextColor3 = hex("#7dff6b"), TextXAlignment = Enum.TextXAlignment.Center })
			local _2 = main
			Kit.tween(holder, { Position = UDim2.fromOffset(280, -22) }, 0.9, Enum.EasingStyle.Quad)
			task.delay(1, function() holder:Destroy() end)
		end
	end)
	for _ = 1, 5 do
		local s = Kit.sparkle(row.frame, math.random(250, 430), math.random(10, 80), math.random(8, 14), 0)
		task.delay(1.6, function() s:Destroy() end)
	end
	if self.opts.onBought then self.opts.onBought(row.frame, before) end
end
function Panel:try(row, kind: string, arg): boolean
	if self.busy or not self:canAct() then return false end
	self.busy = true
	local before = self:attr("Income") or 0
	local ok = self.opts.buy(kind, arg)
	self.busy = false
	if ok then self:bought(row, before) end
	return ok == true
end

function Panel:bodyRow(i, k: number)
	local tier = Econ.Tiers[k + 1]
	local look = TIER_LOOK[k + 1]
	local row = { frame = self:newRowFrame(i, look[1]), copyRow = true }
	Kit.icon(row.frame, tier.icon, -8, 2, if tier.icon == "comet" then 96 else 90, look[4], { ZIndex = 7 })
	local lv = Kit.text(row.frame, 16, Kit.ps(82, 80), 60, 18, "LV 0", Kit.ps(12, 20), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(row.frame, 86, Kit.ps(10, 4), 300, 28, tier.name, 22, { ZIndex = 8, gradient = ColorSequence.new(hex(look[2]), hex(look[3])) })
	-- (phones: 2 lines at 20, so it reads at 12 px on a 667x375 screen)
	local desc = Kit.text(row.frame, 88, Kit.ps(38, 30), 196, Kit.ps(16, 46), "", Kit.ps(11, 20), { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1, TextWrapped = Kit.phone() })
	local node = tier.unlock and Econ.Ring1ById[tier.unlock]
	row.onButton = function(b)
		holdBuy(b, function()
			local o, n = self:owned(), self:nodes()
			if not node and not Econ.Unlocked(k, n, self:ring2()) then
				-- (the Star tiers: opened with shards in the Constellation Tree, ring 2)
				if self.opts.toast then self.opts.toast(tier.name .. ": " .. (tier.lockedText or "") .. ", then ring 2 in the tree", hex("#8a8296")) end
				return false
			end
			if not Econ.Unlocked(k, n, self:ring2()) then
				if node.requires and not n[node.requires] then
					if self.opts.toast then self.opts.toast("Unlock the " .. Econ.Tiers[k].name .. " first", hex("#8a8296")) end
					return false
				end
				if self:stardust() < node.cost then self:sound("no") return false end
				if self:try(row, "BuyNode", node.id) and self.opts.toast then self.opts.toast(tier.name .. " UNLOCKED", hex("#7dff6b")) end
				return false -- (one unlock per press)
			end
			if self:stardust() < Econ.Cost(k, o[k + 1], Econ.PerksOf(self.subject)) then self:sound("no") return false end
			return self:try(row, "BuyBody", k)
		end, function() return self:dragged() end)
	end
	row.refresh = function()
		local o, n, r2 = self:owned(), self:nodes(), self:ring2()
		local own = o[k + 1] or 0
		if not node and not Econ.Unlocked(k, n, r2) then
			Kit.setText(lv, "LOCKED")
			Kit.setText(desc, "opens at " .. tier.lockedText .. " (ring 2)")
			self:chip(row, tier.lockedText)
			self:setButton(row, "locked", nil, tier.lockedText)
			return
		end
		local perks = Econ.PerksOf(self.subject)
		local each = Econ.TierIncomeWith(k, 1, 1, n, r2, perks) * Econ.AllMult(n, r2, perks)
		if row.copyBtn then row.copyBtn.Visible = Econ.Unlocked(k, n, r2) and own > 0 end
		if not Econ.Unlocked(k, n, r2) then
			Kit.setText(lv, "LOCKED")
			Kit.setText(desc, "opens with " .. node.name .. ", " .. fmt(each) .. "/s each")
			self:chip(row, "LOCKED", "OPEN")
			if node.requires and not n[node.requires] then
				self:setButton(row, "locked", nil, "UNLOCK " .. Econ.Tiers[k].name)
			else
				self:setButton(row, if self:stardust() >= node.cost then "buy" else "no", node.cost, "UNLOCK")
			end
			self.targets["Unlock" .. k] = row.btn
			return
		end
		local copies = math.max(self:copies()[k + 1] or 0, 1)
		Kit.setText(lv, "LV " .. own)
		local nextAt = Econ.NextTierAt(own)
		Kit.setText(desc, Econ.TierName(own) .. (if copies > 1 then " x" .. copies else "") .. (if nextAt then ", x2 at Lv " .. nextAt .. " (" .. Econ.TierNames[Econ.NamedTier(own) + 1] .. ")" else ""))
		local now = Econ.TierIncomeWith(k, own, copies, n, r2, perks) * Econ.AllMult(n, r2, perks)
		local after = Econ.TierIncomeWith(k, own + 1, copies, n, r2, perks) * Econ.AllMult(n, r2, perks)
		self:chip(row, fmt(now) .. "/s", fmt(after) .. "/s")
		local cost = Econ.Cost(k, own, perks)
		self:setButton(row, if self:stardust() >= cost then "buy" else "no", cost, if own > 0 then nil else "UNLOCK")
		self.targets["Body" .. k] = row.btn
		self:copyButton(row, k, own, copies)
	end
	return row
end

-- a PERK row (feel pass): icon, name, what it does, the chip "now > next", UPGRADE with its XP price (the sun icon); a perk
-- tier still shut = locked "LVL n"
function Panel:perkRow(i, p)
	local look = TAB_LOOK.COMETS
	local row = { frame = self:newRowFrame(i, look[1]), currency = "sun" }
	Kit.icon(row.frame, p.icon, -8, 2, if p.icon == "comet" then 96 else 90, look[4], { ZIndex = 7 })
	local lv = Kit.text(row.frame, 16, Kit.ps(82, 80), 60, 18, "LV 0", Kit.ps(12, 20), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(row.frame, 86, Kit.ps(10, 4), 300, 28, p.name, 22, { ZIndex = 8, gradient = ColorSequence.new(hex(look[2]), hex(look[3])) })
	Kit.text(row.frame, 88, Kit.ps(38, 30), 196, Kit.ps(16, 46), p.desc, Kit.ps(11, 20), { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1, TextWrapped = Kit.phone() })
	row.onButton = function(b)
		holdBuy(b, function()
			local level = self:attr("CosmicLevel") or 1
			local have = self:attr("Perk_" .. p.id) or 0
			if level < p.opens or have >= Econ.PerkMax then return false end
			if (self:attr("XP") or 0) < Econ.PerkCost(have) then self:sound("no") return false end
			return self:try(row, "BuyPerk", p.id)
		end, function() return self:dragged() end)
	end
	row.refresh = function()
		local level = self:attr("CosmicLevel") or 1
		local have = self:attr("Perk_" .. p.id) or 0
		Kit.setText(lv, "LV " .. have)
		if level < p.opens then
			self:chip(row, Econ.PerkValue(p, 0))
			self:setButton(row, "locked", nil, "LVL " .. p.opens)
		elseif have >= Econ.PerkMax then
			self:chip(row, Econ.PerkValue(p, have))
			self:setButton(row, "owned", nil, "MAX")
		else
			self:chip(row, Econ.PerkValue(p, have), Econ.PerkValue(p, have + 1))
			local cost = Econ.PerkCost(have)
			self:setButton(row, if (self:attr("XP") or 0) >= cost then "buy" else "no", cost)
		end
		self.targets["Perk_" .. p.id] = row.btn
	end
	return row
end

-- +BODY (feel pass): a small purple button under the row's main button; one tap = one more copy in orbit (max 5)
function Panel:copyButton(row, k: number, level: number, copies: number)
	local full = copies >= Econ.MaxCopies
	local cost = Econ.CopyCost(k, copies, Econ.PerksOf(self.subject))
	local state = if not self:canAct() then "visit" elseif full then "max" elseif self:stardust() >= cost then "buy" else "no"
	local key = state .. "|" .. fmt(cost)
	if row.copyKey == key and row.copyBtn then
		row.copyBtn.Visible = level > 0
		return
	end
	row.copyKey = key
	if row.copyBtn then row.copyBtn:Destroy() row.copyShadow:Destroy() end
	local c1, c2 = VIO1, VIO2
	if state == "no" or state == "visit" then c1, c2 = GREY1, GREY2 end
	local b, inner, _, shadow = Kit.button(row.frame, 288, 84, 146, 22, c1, c2, { ZIndex = 6 })
	row.copyBtn, row.copyShadow = b, shadow
	local label = if state == "max" then "MAX BODIES" elseif state == "visit" then "VISIT" else "+BODY  " .. fmt(cost)
	Kit.text(inner, 0, 1, 146, 18, label, Kit.ps(12, 14), { ZIndex = inner.ZIndex, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY,
		TextColor3 = if state == "no" then hex("#ff9a9a") else Color3.new(1, 1, 1) })
	b.Visible = level > 0
	self.targets["Copy" .. k] = b
	if state == "buy" then
		b.MouseButton1Click:Connect(function()
			if self:dragged() then return end
			self:try(row, "BuyCopy", k)
		end)
	end
end

function Panel:nodeRow(i, node, look)
	local row = { frame = self:newRowFrame(i, look[1]) }
	Kit.icon(row.frame, node.icon, -8, 2, if node.icon == "comet" then 96 else 90, look[4], { ZIndex = 7 })
	local lv = Kit.text(row.frame, 16, Kit.ps(82, 80), 60, 18, "LV 0", Kit.ps(12, 20), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(row.frame, 86, Kit.ps(10, 4), 300, 28, node.name, 22, { ZIndex = 8, gradient = ColorSequence.new(hex(look[2]), hex(look[3])) })
	Kit.text(row.frame, 88, Kit.ps(38, 30), 196, Kit.ps(16, 46), node.desc, Kit.ps(11, 20), { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1, TextWrapped = Kit.phone() })
	local e = node.effect
	local from, to
	if e.kind == "tierMult" or e.kind == "allMult" then
		from, to = "x1", "x" .. tostring(e.mult)
	elseif e.kind == "cometEvery" then
		from, to = Econ.Comet.Every .. "s", e.seconds .. "s"
	elseif e.kind == "shardBonus" then
		from, to = "+0%", "+" .. e.pct .. "%"
	end
	row.onButton = function(b)
		b.MouseButton1Click:Connect(function()
			if self:dragged() then return end
			local n = self:nodes()
			if n[node.id] then return end
			if node.requires and not n[node.requires] then return end
			if self:stardust() < node.cost then self:sound("no") return end
			self:try(row, "BuyNode", node.id)
		end)
	end
	row.refresh = function()
		local n = self:nodes()
		if n[node.id] then
			Kit.setText(lv, "LV 1")
			self:chip(row, to or "")
			self:setButton(row, "owned", nil, "OWNED")
		else
			Kit.setText(lv, "LV 0")
			self:chip(row, from or "", to)
			self:setButton(row, if self:stardust() >= node.cost then "buy" else "no", node.cost)
		end
		self.targets["Node_" .. node.id] = row.btn
	end
	return row
end

function Panel:lockedPanel(t)
	local f = Kit.box(self.rowsPanel, 8, 9, 446, 356, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
	Kit.corner(f, 5)
	Kit.stroke(f, hex("#5a5562"), 2)
	Kit.grad(f, hex("#17141c"), hex("#0e0c12"), 90)
	local img = Kit.icon(f, t.icon, 163, 40, 120, nil, { ZIndex = 7 })
	img.ImageTransparency = 0.35
	Kit.icon(f, "lock", 250, 120, 48, nil, { ZIndex = 9 })
	Kit.text(f, 0, 190, 446, 34, t.lockedTitle, 28, { ZIndex = 8, TextXAlignment = Enum.TextXAlignment.Center, gradient = ColorSequence.new(hex("#cfc6dd"), hex("#8a8296")) })
	Kit.text(f, 30, 232, 386, Kit.ps(40, 60), t.lockedText, Kit.ps(13, 19), { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1,
		TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true })
end

function Panel:buildTab(id: string)
	for _, c in ipairs(self.rowsPanel:GetChildren()) do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") then c:Destroy() end
	end
	table.clear(self.rows)
	table.clear(self.targets)
	local t = self.tabUI[id].def
	local list = {}
	if t.locked then
		self:lockedPanel(t)
	elseif id == "BODIES" then
		for k = 0, #Econ.Tiers - 1 do table.insert(list, function(i) return self:bodyRow(i, k) end) end
	else
		for _, p in ipairs(Econ.Perks) do table.insert(list, function(i) return self:perkRow(i, p) end) end
	end
	for i = 1, #list do
		local row = list[i](i)
		table.insert(self.rows, row)
		row.refresh()
	end
	-- all the tab's rows in one list (a new tab starts at the top)
	self.rowsPanel.CanvasSize = UDim2.fromOffset(0, math.max(374, 9 + #list * 120))
	self.rowsPanel.CanvasPosition = Vector2.zero
end
-- scrolls the list so a row's button is on show (the tutorial arrow points at it on the board)
function Panel:reveal(button: GuiObject?)
	if button and button:IsDescendantOf(self.rowsPanel) then self.scroll.reveal(button) end
end
function Panel:refresh()
	for _, row in ipairs(self.rows) do row.refresh() end
	local v = if self.chipName == "SHARDS" then self:attr("Shards") else self:attr("Essence")
	Kit.setText(self.chipText, fmt(tonumber(v) or 0))
end
-- is anything buyable right now (the board's beacon)
function Panel:anyBuyable(): boolean
	local o, n, sd = self:owned(), self:nodes(), self:stardust()
	local r2 = self:ring2()
	local perks = Econ.PerksOf(self.subject)
	for k = 0, #Econ.Tiers - 1 do
		if Econ.Unlocked(k, n, r2) and sd >= Econ.Cost(k, o[k + 1] or 0, perks) then return true end
	end
	for _, node in ipairs(Econ.Ring1) do
		if not n[node.id] and (not node.requires or n[node.requires]) and sd >= node.cost then return true end
	end
	return false
end

function Panel:selectTab(id: string)
	self.currentTab = id
	if self.selRing then self.selRing:Destroy() end
	if self.selPulse then self.selPulse:Cancel() end
	for tid, ui in pairs(self.tabUI) do
		Kit.clearVfx(ui.button)
		if tid == id and not ui.def.locked then Kit.tagVfx(Kit.shine(ui.button, 3)) end
	end
	local ui = self.tabUI[id]
	self.selRing = Kit.box(self.root, ui.x - 4, ui.y - 4, 174, 54, { ZIndex = 7 })
	Kit.corner(self.selRing, 7)
	local st = Kit.stroke(self.selRing, Color3.new(1, 1, 1), 2)
	if not Kit.calm() then self.selPulse = Kit.tween(st, { Transparency = 0.65 }, 0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) end
	self:buildTab(id)
	self:refresh()
end

-- the edge glow's light runs round the frame (boards)
function Panel:step(dt: number)
	if self.edgeGradient and not Kit.calm() then self.edgeGradient.Rotation = (self.edgeGradient.Rotation + dt * 60) % 360 end
end

function Panel:destroy()
	self.root:Destroy()
end

local _ = RunService
return Panel
