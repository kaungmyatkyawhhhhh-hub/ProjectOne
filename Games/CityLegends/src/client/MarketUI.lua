--[[
	MarketUI (client): the car stock market screen (owner, 2026-10-22, styled after the Flip Rush
	market): dark cards, monospace numbers, green / red moves, purple buttons.
	  header:  Leave · Market · cash
	  ticker:  ● LIVE  Lambrini ▲ New hypercar reveal
	  tabs:    Requests (3 a day) · Stalls (sell to the market) · Flip-off (vs Slick Vinny)
	  offer:   an NPC buyer's offer on a car in your stash: PASS / SELL
	  left:    Listings: tap BUY, hold BUY to lowball
	  right:   Stash: what you hold, its value, your profit and a sparkline; tap a card to sell
	           or take delivery
	The server decides everything (Market.lua); this only asks and shows. Open with K or the
	MARKET button on the HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local player = Players.LocalPlayer
local M = Config.Market

local MarketUI = {}
MarketUI.isOpen = false

-- the look (Flip Rush market)
local C = {
	bg = Color3.fromRGB(12, 13, 17),
	card = Color3.fromRGB(23, 25, 31),
	cardHi = Color3.fromRGB(31, 34, 42),
	stroke = Color3.fromRGB(42, 45, 55),
	text = Color3.fromRGB(236, 238, 245),
	sub = Color3.fromRGB(138, 144, 160),
	green = Color3.fromRGB(74, 222, 128),
	red = Color3.fromRGB(248, 113, 113),
	purple = Color3.fromRGB(110, 106, 246),
	orange = Color3.fromRGB(251, 146, 60),
	live = Color3.fromRGB(255, 72, 88),
}
local MONO = Enum.Font.RobotoMono
local HOLD = 0.7 -- seconds to hold BUY for a lowball

local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function stroke(color: Color3, t: number?, tr: number?): UIStroke
	return new("UIStroke", { Color = color, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function text(props: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base)
end
local function money(n: number): string
	return UI.formatCash(n)
end
local function pct(x: number): string
	local v = math.floor(x * 100 + (if x >= 0 then 0.5 else -0.5))
	return (if v >= 0 then "+" else "") .. v .. "%"
end

local COND: { [string]: any } = {}
for _, c in M.Conditions do
	COND[c.Id] = c
end

local function carName(id: string): string
	local spec = Cars.ById[id]
	return if spec then spec.Name else id
end
local function initials(id: string): string
	local words = {}
	for w in carName(id):gmatch("%S+") do
		table.insert(words, w)
	end
	local a = (words[1] or "?"):sub(1, 1)
	local b = (words[2] or words[1] or "?"):sub(1, 1)
	return string.upper(a .. b)
end
local function brandColor(id: string): Color3
	local brand = carName(id):match("^(%S+)") or id
	local h = 0
	for i = 1, #brand do
		h = (h * 31 + brand:byte(i)) % 360
	end
	return Color3.fromHSV(h / 360, 0.55, 0.95)
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local call: RemoteFunction? = nil
local gui: ScreenGui? = nil
local canvas: Frame? = nil
local scaler: UIScale? = nil
local st: { [string]: any }? = nil
local stAt = 0 -- os.clock() when st arrived (for the countdowns)
local holding = false
local dirty = false
local busy = false
local render: () -> ()
local modal: Frame? = nil

local function toast(msg: string, good: boolean?)
	local c = canvas
	if not c or msg == "" then
		return
	end
	local t = text({
		Text = msg,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = if good == false then C.red elseif good then C.green else C.text,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(460, 40),
		BackgroundTransparency = 0.05,
		BackgroundColor3 = C.cardHi,
		ZIndex = 50,
		Parent = c,
	})
	corner(10).Parent = t
	stroke(if good == false then C.red elseif good then C.green else C.stroke, 1, 0.3).Parent = t
	task.delay(2.4, function()
		TweenService:Create(t, TweenInfo.new(0.3), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		task.wait(0.35)
		t:Destroy()
	end)
end

local function ask(action: string, args: any?): { [string]: any }?
	local r = call
	if not r or busy then
		return nil
	end
	busy = true
	local ok, res = pcall(function()
		return r:InvokeServer(action, args)
	end)
	busy = false
	if not ok or type(res) ~= "table" then
		toast("The market isn't answering, try again", false)
		return nil
	end
	if type(res.state) == "table" then
		st = res.state
		stAt = os.clock()
	end
	if res.msg then
		toast(res.msg, res.ok)
	end
	if res.ok then
		Audio.click()
	end
	render()
	return res
end

---------------------------------------------------------------------
-- Pieces
---------------------------------------------------------------------
local function tile(parent: Instance, id: string, size: number, x: number, y: number): Frame
	local col = brandColor(id)
	local f = new("Frame", {
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = col:Lerp(C.bg, 0.72),
		Parent = parent,
	}, { corner(8), stroke(col, 1, 0.65) })
	text({ Text = initials(id), Font = Enum.Font.GothamBlack, TextSize = math.floor(size * 0.38), TextColor3 = col, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = f })
	return f
end

local function condTag(parent: Instance, cond: string, x: number, y: number): number
	local c = COND[cond]
	local name = if c then c.Name else cond
	local w = 10 + #name * 6.4
	local f = new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 16), BackgroundColor3 = C.bg, Parent = parent }, { corner(4), stroke(if c then c.Color else C.sub, 1, 0.55) })
	text({ Text = name, Font = MONO, TextSize = 11, TextColor3 = if c then c.Color else C.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = f })
	return w
end

local function spark(parent: Instance, values: { number }, mult: number, x: number, y: number, w: number, h: number)
	local n = #values
	if n < 2 then
		return
	end
	local stepN = math.max(1, math.floor(n / 22))
	local pts = {}
	for i = 1, n, stepN do
		table.insert(pts, values[i] * mult)
	end
	if pts[#pts] ~= values[n] * mult then
		table.insert(pts, values[n] * mult)
	end
	local lo, hi = math.huge, -math.huge
	for _, v in pts do
		lo = math.min(lo, v)
		hi = math.max(hi, v)
	end
	local span = math.max(hi - lo, 1e-6)
	local col = if pts[#pts] >= pts[1] then C.green else C.red
	local holder = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ClipsDescendants = false, Parent = parent })
	local function at(i: number): Vector2
		return Vector2.new((i - 1) / (#pts - 1) * w, h - (pts[i] - lo) / span * h)
	end
	for i = 1, #pts - 1 do
		local a, b = at(i), at(i + 1)
		local d = b - a
		local m = (a + b) / 2
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(m.X, m.Y),
			Size = UDim2.fromOffset(d.Magnitude + 1, 1.6),
			Rotation = math.deg(math.atan2(d.Y, d.X)),
			BackgroundColor3 = col,
			BorderSizePixel = 0,
			Parent = holder,
		})
		-- soft fill under the line
		new("Frame", {
			Position = UDim2.fromOffset(a.X, math.max(a.Y, b.Y)),
			Size = UDim2.fromOffset(d.X + 1, h - math.max(a.Y, b.Y)),
			BackgroundColor3 = col,
			BackgroundTransparency = 0.9,
			BorderSizePixel = 0,
			Parent = holder,
		})
	end
end

local function pill(parent: Instance, label: string, color: Color3, filled: boolean, props: { [string]: any }): TextButton
	local b: TextButton = new("TextButton", {
		AutoButtonColor = false,
		Text = label,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = if filled then Color3.new(1, 1, 1) else C.text,
		BackgroundColor3 = if filled then color else C.card,
		Parent = parent,
	}, { corner(7), stroke(color, 1, if filled then 1 else 0.35) })
	for k, v in props do
		(b :: any)[k] = v
	end
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = if filled then color:Lerp(Color3.new(1, 1, 1), 0.12) else C.cardHi
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = if filled then color else C.card
	end)
	return b
end

local function closeModal()
	if modal then
		modal:Destroy()
		modal = nil
	end
end

local function openModal(title: string, height: number): Frame
	closeModal()
	local c = canvas :: Frame
	local shade = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = c })
	shade.Activated:Connect(closeModal)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(520, height),
		BackgroundColor3 = C.card,
		ZIndex = 21,
		Parent = shade,
	}, { corner(12), stroke(C.stroke, 1.5, 0) })
	-- clicks inside the box don't close it
	new("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 21, Parent = box })
	text({ Text = title, TextSize = 18, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(18, 14), Size = UDim2.new(1, -70, 0, 24), ZIndex = 22, Parent = box })
	local x = pill(box, "×", C.stroke, false, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(30, 30), ZIndex = 23 })
	x.Activated:Connect(closeModal)
	modal = shade
	return box
end

local function setZ(root: Instance, z: number)
	for _, d in root:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = z
		end
	end
end

local function itemModal(it: { [string]: any })
	local s = st
	if not s then
		return
	end
	local box = openModal(carName(it.car), 250)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 50), Size = UDim2.new(1, -36, 1, -60), Parent = box })
	tile(body, it.car, 64, 0, 0)
	condTag(body, it.cond, 78, 0)
	local profit = it.value - it.paid
	text({ Text = money(it.value), Font = MONO, TextSize = 26, Position = UDim2.fromOffset(78, 20), Size = UDim2.new(1, -78, 0, 30), Parent = body })
	text({
		Text = ("%s · paid %s"):format(if it.paid > 0 then pct(profit / it.paid) else "+0%", money(it.paid)),
		Font = MONO,
		TextSize = 13,
		TextColor3 = if profit >= 0 then C.green else C.red,
		Position = UDim2.fromOffset(78, 50),
		Size = UDim2.new(1, -78, 0, 18),
		Parent = body,
	})
	local net = math.floor(it.value * (1 - s.fee))
	text({
		Text = ("Market sale pays %s after the %d%% fee.%s"):format(money(net), math.floor(s.fee * 100 + 0.5), if it.cond == "Showroom" and not it.owned then "\nShowroom units can be delivered: the car joins your garage." else ""),
		TextSize = 12,
		Font = Enum.Font.GothamMedium,
		TextColor3 = C.sub,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(0, 80),
		Size = UDim2.new(1, 0, 0, 40),
		Parent = body,
	})
	local sellB = pill(body, "SELL " .. money(net), C.purple, true, { Position = UDim2.new(0, 0, 1, -44), Size = UDim2.new(0.5, -6, 0, 40), TextSize = 14 })
	sellB.Activated:Connect(function()
		closeModal()
		ask("sell", { u = it.u })
	end)
	if it.cond == "Showroom" and not it.owned then
		local del = pill(body, "TAKE DELIVERY", C.green, false, { Position = UDim2.new(0.5, 6, 1, -44), Size = UDim2.new(0.5, -6, 0, 40), TextSize = 14 })
		del.Activated:Connect(function()
			closeModal()
			ask("redeem", { u = it.u })
		end)
	end
	setZ(box, 22)
end

local function requestsModal()
	local s = st
	if not s then
		return
	end
	local box = openModal("Requests", 120 + #s.requests * 70)
	local hours = math.floor((s.resetIn or 0) / 3600)
	text({ Text = ("Buyers pay a premium for these. New ones in %dh."):format(hours), TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 18), Parent = box })
	for i, r in s.requests do
		local row = new("Frame", { Position = UDim2.fromOffset(18, 66 + (i - 1) * 70), Size = UDim2.new(1, -36, 0, 62), BackgroundColor3 = C.bg, Parent = box }, { corner(10), stroke(C.stroke, 1, 0.2) })
		tile(row, r.car, 42, 10, 10)
		text({ Text = carName(r.car), TextSize = 14, Position = UDim2.fromOffset(62, 9), Size = UDim2.new(1, -190, 0, 18), Parent = row })
		local cw = condTag(row, r.cond, 62, 33)
		text({ Text = "or better · pays " .. money(r.pay) .. " (x" .. string.format("%.2f", r.premium) .. ")", Font = MONO, TextSize = 11, TextColor3 = C.green, Position = UDim2.fromOffset(68 + cw, 32), Size = UDim2.new(1, -200 - cw, 0, 18), Parent = row })
		local have = false
		for _, it in s.stash do
			if it.car == r.car and (COND[it.cond] and COND[r.cond]) then
				local ri, ii = 0, 0
				for k, c in M.Conditions do
					if c.Id == r.cond then
						ri = k
					end
					if c.Id == it.cond then
						ii = k
					end
				end
				if ii >= ri then
					have = true
				end
			end
		end
		if r.done then
			text({ Text = "DONE", Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = C.green, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(110, 30), Parent = row })
		else
			local b = pill(row, if have then "FILL" else "NEED IT", if have then C.purple else C.stroke, have, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(100, 32) })
			if have then
				b.Activated:Connect(function()
					closeModal()
					ask("fulfil", { i = r.i })
				end)
			end
		end
	end
	setZ(box, 22)
end

local function stallsModal()
	local s = st
	if not s then
		return
	end
	local n = math.min(#s.stash, 6)
	local box = openModal("Stalls · sell to the market", 120 + math.max(n, 1) * 58)
	text({ Text = ("Instant sale at the market value, minus the %d%% fee (more hype, lower fee)."):format(math.floor(s.fee * 100 + 0.5)), TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -36, 0, 18), Parent = box })
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(18, 66),
		Size = UDim2.new(1, -36, 1, -78),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.stroke,
		CanvasSize = UDim2.fromOffset(0, #s.stash * 58),
		BorderSizePixel = 0,
		Parent = box,
	})
	if #s.stash == 0 then
		text({ Text = "Your stash is empty: buy something in Listings.", TextColor3 = C.sub, Size = UDim2.new(1, 0, 0, 30), Parent = list })
	end
	for i, it in s.stash do
		local row = new("Frame", { Position = UDim2.fromOffset(0, (i - 1) * 58), Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = C.bg, Parent = list }, { corner(10), stroke(C.stroke, 1, 0.2) })
		tile(row, it.car, 36, 8, 8)
		text({ Text = carName(it.car), TextSize = 13, Position = UDim2.fromOffset(52, 7), Size = UDim2.new(1, -200, 0, 18), Parent = row })
		local profit = it.value - it.paid
		text({ Text = (COND[it.cond] and COND[it.cond].Name or it.cond) .. " · " .. (if it.paid > 0 then pct(profit / it.paid) else ""), Font = MONO, TextSize = 11, TextColor3 = if profit >= 0 then C.green else C.red, Position = UDim2.fromOffset(52, 27), Size = UDim2.new(1, -200, 0, 16), Parent = row })
		local b = pill(row, "SELL " .. money(math.floor(it.value * (1 - s.fee))), C.purple, true, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(136, 32) })
		b.Activated:Connect(function()
			ask("sell", { u = it.u })
			task.defer(function()
				if modal then
					stallsModal()
				end
			end)
		end)
	end
	setZ(box, 22)
end

local function flipModal()
	local s = st
	if not s then
		return
	end
	local box = openModal("Flip-off vs Slick Vinny", 230)
	text({
		Text = "Three minutes. Whoever makes the most profit from flips wins. Vinny is fast, but he gets greedy. Beat him for a cash prize and a hype point.",
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextColor3 = C.sub,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(18, 46),
		Size = UDim2.new(1, -36, 0, 60),
		Parent = box,
	})
	text({ Text = ("Record: %d wins · lifetime profit %s"):format(s.wins or 0, money(s.profit or 0)), Font = MONO, TextSize = 12, TextColor3 = C.text, Position = UDim2.fromOffset(18, 112), Size = UDim2.new(1, -36, 0, 18), Parent = box })
	local label = if s.flip then "RUNNING" elseif (s.flipReadyIn or 0) > 0 then ("READY IN %ds"):format(s.flipReadyIn) else "START FLIP-OFF"
	local can = not s.flip and (s.flipReadyIn or 0) <= 0
	local b = pill(box, label, if can then C.purple else C.stroke, can, { Position = UDim2.new(0, 18, 1, -60), Size = UDim2.new(1, -36, 0, 44), TextSize = 15 })
	if can then
		b.Activated:Connect(function()
			closeModal()
			ask("flipoff")
		end)
	end
	setZ(box, 22)
end

---------------------------------------------------------------------
-- The screen
---------------------------------------------------------------------
local refs: { [string]: any } = {}

local function build()
	local g = new("ScreenGui", { Name = "MarketUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	gui = g
	local bg = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.02, Size = UDim2.fromScale(1, 1), Parent = g })
	local c = new("Frame", { Name = "Canvas", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Parent = bg })
	canvas = c
	scaler = new("UIScale", { Parent = c })

	-- header
	local leave = pill(c, "", C.stroke, false, { Position = UDim2.fromOffset(16, 14), Size = UDim2.fromOffset(112, 36) })
	text({ Text = "←  Leave", TextSize = 14, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -40, 1, 0), Parent = leave })
	local key = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(22, 18), BackgroundColor3 = C.cardHi, Parent = leave }, { corner(4) })
	text({ Text = if UI.isTouch then "×" else "K", Font = MONO, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = key })
	leave.Activated:Connect(function()
		MarketUI.close()
	end)
	new("Frame", { Position = UDim2.fromOffset(142, 25), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = C.purple, Parent = c }, { corner(3) })
	text({ Text = "Market", TextSize = 20, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(164, 14), Size = UDim2.fromOffset(200, 36), Parent = c })
	refs.cash = text({ Text = "$0", Font = MONO, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 12), Size = UDim2.fromOffset(260, 30), Parent = c })
	new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 44), Size = UDim2.fromOffset(110, 4), BackgroundColor3 = C.green, Parent = c }, { corner(2) })
	local help = pill(c, "?", C.stroke, false, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -290, 0, 14), Size = UDim2.fromOffset(28, 28), TextSize = 13 })
	help.Activated:Connect(function()
		local box = openModal("How the market works", 260)
		text({
			Text = "• Cars trade like stocks. Prices move every " .. M.TickSeconds .. " s and jump on news.\n• Tap BUY for the asking price. Hold BUY to lowball: a cheaper deal, or the seller walks.\n• Sell to the market in Stalls (minus fees), or to a buyer's offer (no fee).\n• Requests pay a premium for a car in a condition or better.\n• Good flips raise your hype: better offers, lower fees.\n• Showroom units can be delivered to your garage.",
			TextSize = 13,
			Font = Enum.Font.GothamMedium,
			TextColor3 = C.text,
			TextWrapped = true,
			TextTruncate = Enum.TextTruncate.None,
			TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(18, 48),
			Size = UDim2.new(1, -36, 1, -60),
			Parent = box,
		})
		setZ(box, 22)
	end)

	-- live ticker
	local tick = new("Frame", { Position = UDim2.fromOffset(16, 60), Size = UDim2.new(1, -32, 0, 26), BackgroundColor3 = C.card, Parent = c }, { corner(6) })
	new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = C.live, Parent = tick }, { corner(3) })
	text({ Text = "LIVE", Font = MONO, TextSize = 11, TextColor3 = C.live, Position = UDim2.fromOffset(21, 0), Size = UDim2.fromOffset(40, 26), Parent = tick })
	refs.newsTag = text({ Text = "", Font = Enum.Font.GothamBlack, TextSize = 13, Position = UDim2.fromOffset(62, 0), Size = UDim2.fromOffset(150, 26), TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.X, Parent = tick })
	refs.newsText = text({ Text = "", TextSize = 13, Font = Enum.Font.GothamMedium, Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -180, 0, 26), Parent = tick })

	-- tabs
	local tabs = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 94), Size = UDim2.new(1, -32, 0, 52), Parent = c })
	local function tabCard(i: number, title: string): (TextButton, TextLabel)
		local b: TextButton = new("TextButton", {
			AutoButtonColor = false,
			Text = "",
			Position = UDim2.new((i - 1) / 3, if i > 1 then 4 else 0, 0, 0),
			Size = UDim2.new(1 / 3, -6, 1, 0),
			BackgroundColor3 = C.card,
			Parent = tabs,
		}, { corner(8), stroke(C.stroke, 1, 0.2) })
		text({ Text = title, TextSize = 13, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -20, 0, 18), Parent = b })
		local sub = text({ Text = "", TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Position = UDim2.fromOffset(12, 27), Size = UDim2.new(1, -20, 0, 16), Parent = b })
		b.MouseEnter:Connect(function()
			b.BackgroundColor3 = C.cardHi
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundColor3 = C.card
		end)
		b.Activated:Connect(Audio.click)
		return b, sub
	end
	local reqB, reqSub = tabCard(1, "Requests")
	local stallB, stallSub = tabCard(2, "Stalls")
	local flipB, flipSub = tabCard(3, "Flip-off")
	refs.reqSub, refs.stallSub, refs.flipSub = reqSub, stallSub, flipSub
	reqB.Activated:Connect(requestsModal)
	stallB.Activated:Connect(stallsModal)
	flipB.Activated:Connect(flipModal)

	-- offer banner
	local offer = new("Frame", { Position = UDim2.fromOffset(16, 154), Size = UDim2.new(1, -32, 0, 50), BackgroundColor3 = C.card, Parent = c }, { corner(8) })
	refs.offerStroke = stroke(C.purple, 1.5, 0)
	refs.offerStroke.Parent = offer
	refs.offer = offer

	-- columns
	refs.listHead = text({ Text = "Listings", TextSize = 16, Font = Enum.Font.GothamBlack, Parent = c })
	refs.listHint = text({ Text = if UI.isTouch then "Tap to buy · hold to lowball" else "Click to buy · hold to lowball", Font = MONO, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Right, Parent = c })
	refs.list = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.stroke, Parent = c })
	refs.stashHead = text({ Text = "Stash", TextSize = 16, Font = Enum.Font.GothamBlack, TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.X, Parent = c })
	refs.stashChips = new("Frame", { BackgroundTransparency = 1, Parent = c })
	refs.stash = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.stroke, Parent = c })
end

-- canvas size in logical px (the UIScale shrinks it on small screens)
local function layout(): (number, number)
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local scale = math.clamp(math.min(vp.X / 1000, vp.Y / 600), 0.72, 1)
	local w = math.min(vp.X / scale, 1180)
	local h = vp.Y / scale
	local c = canvas :: Frame
	;(scaler :: UIScale).Scale = scale
	c.Size = UDim2.fromOffset(w, h)
	local top = 214
	local narrow = w < 760
	local leftW = if narrow then w - 32 else math.floor((w - 32 - 16) * 0.47)
	local rightX = if narrow then 16 else 16 + leftW + 16
	local rightW = if narrow then w - 32 else w - 32 - leftW - 16
	local listH = if narrow then math.floor((h - top - 40) * 0.42) else h - top - 40
	refs.listHead.Position = UDim2.fromOffset(16, top)
	refs.listHead.Size = UDim2.fromOffset(120, 22)
	refs.listHint.Position = UDim2.fromOffset(16 + leftW - 240, top + 3)
	refs.listHint.Size = UDim2.fromOffset(240, 18)
	refs.list.Position = UDim2.fromOffset(16, top + 28)
	refs.list.Size = UDim2.fromOffset(leftW, listH)
	local stashTop = if narrow then top + 28 + listH + 10 else top
	refs.stashHead.Position = UDim2.fromOffset(rightX, stashTop)
	refs.stashHead.Size = UDim2.fromOffset(60, 22)
	refs.stashChips.Position = UDim2.fromOffset(rightX + 100, stashTop + 2)
	refs.stashChips.Size = UDim2.fromOffset(rightW - 100, 18)
	refs.stash.Position = UDim2.fromOffset(rightX, stashTop + 28)
	refs.stash.Size = UDim2.fromOffset(rightW, h - stashTop - 28 - 12)
	return leftW, rightW
end

local function clear(f: Instance)
	for _, ch in f:GetChildren() do
		if not ch:IsA("UIListLayout") then
			ch:Destroy()
		end
	end
end

local function chip(parent: Instance, x: number, label: string, color: Color3): number
	local w = 14 + #label * 6.6
	local f = new("Frame", { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 18), BackgroundColor3 = color:Lerp(C.bg, 0.8), Parent = parent }, { corner(5) })
	text({ Text = label, Font = MONO, TextSize = 11, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = f })
	return w
end

local function listingRow(parent: Instance, l: { [string]: any }, y: number, w: number)
	local row = new("Frame", { Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(w - 8, 56), BackgroundColor3 = C.card, Parent = parent }, { corner(8) })
	tile(row, l.car, 36, 10, 10)
	text({ Text = carName(l.car), TextSize = 13, Position = UDim2.fromOffset(56, 8), Size = UDim2.new(1, -230, 0, 18), Parent = row })
	text({ Text = ("★%.1f"):format(l.rating), Font = MONO, TextSize = 10, TextColor3 = C.sub, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -150, 0, 10), Size = UDim2.fromOffset(40, 14), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	local cw = condTag(row, l.cond, 56, 31)
	local diff = if l.mkt > 0 then l.ask / l.mkt - 1 else 0
	local mkt = "Mkt " .. money(l.mkt)
	text({ Text = mkt, Font = MONO, TextSize = 11, TextColor3 = C.sub, TextTruncate = Enum.TextTruncate.None, Position = UDim2.fromOffset(62 + cw, 30), Size = UDim2.fromOffset(#mkt * 6.7, 18), Parent = row })
	-- asking price vs market value: red when you'd pay over, green for a deal
	text({ Text = pct(diff), Font = MONO, TextSize = 11, TextColor3 = if diff > 0 then C.red else C.green, Position = UDim2.fromOffset(62 + cw + #mkt * 6.7 + 6, 30), Size = UDim2.fromOffset(60, 18), Parent = row })
	text({ Text = money(l.ask), Font = MONO, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(150, 22), Parent = row })
	local buy = pill(row, "BUY", C.text, true, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 31), Size = UDim2.fromOffset(48, 18), TextSize = 11, TextColor3 = C.bg })
	-- hold progress (the thin line under the row)
	local bar = new("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = C.purple, BorderSizePixel = 0, Parent = row })
	new("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(0.6, 0, 0, 2), BackgroundColor3 = C.stroke, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 0, Parent = row })
	local downAt: number? = nil
	local tw: Tween? = nil
	buy.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			downAt = os.clock()
			holding = true
			bar.Size = UDim2.new(0, 0, 0, 2)
			tw = TweenService:Create(bar, TweenInfo.new(HOLD, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 0, 2) })
			;(tw :: Tween):Play()
		end
	end)
	buy.InputEnded:Connect(function(input)
		if downAt and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			local held = os.clock() - downAt
			downAt = nil
			holding = false
			if tw then
				tw:Cancel()
			end
			bar.Size = UDim2.new(0, 0, 0, 2)
			ask("buy", { lid = l.lid, lowball = held >= HOLD })
		end
	end)
end

local function stashCard(parent: Instance, it: { [string]: any }, x: number, y: number, w: number, hist: { number }?)
	local card: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 92), BackgroundColor3 = C.card, Parent = parent }, { corner(8) })
	tile(card, it.car, 34, 10, 10)
	text({ Text = money(it.value), Font = MONO, TextSize = 16, Position = UDim2.fromOffset(52, 8), Size = UDim2.new(1, -60, 0, 20), Parent = card })
	local profit = it.value - it.paid
	text({
		Text = ("%s · paid %s"):format(if it.paid > 0 then pct(profit / it.paid) else "+0%", money(it.paid)),
		Font = MONO,
		TextSize = 11,
		TextColor3 = if profit >= 0 then C.green else C.red,
		Position = UDim2.fromOffset(52, 28),
		Size = UDim2.new(1, -60, 0, 14),
		Parent = card,
	})
	local c = COND[it.cond]
	text({ Text = carName(it.car) .. " · " .. (if c then c.Name else it.cond), TextSize = 11, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Position = UDim2.fromOffset(10, 48), Size = UDim2.new(1, -20, 0, 14), Parent = card })
	if hist then
		spark(card, hist, if c then c.Mult else 1, 10, 66, w - 20, 18)
	end
	card.MouseEnter:Connect(function()
		card.BackgroundColor3 = C.cardHi
	end)
	card.MouseLeave:Connect(function()
		card.BackgroundColor3 = C.card
	end)
	card.Activated:Connect(function()
		Audio.click()
		itemModal(it)
	end)
end

local function renderOffer(s: { [string]: any })
	local f = refs.offer :: Frame
	clear(f)
	refs.offerStroke = stroke(C.purple, 1.5, if s.offer then 0 else 0.7)
	refs.offerStroke.Parent = f
	corner(8).Parent = f
	local o = s.offer
	if not o then
		text({ Text = if #s.stash > 0 then "No offers right now: buyers drop by every so often." else "Buy a car in Listings: buyers will start making offers on your stash.", TextSize = 12, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Parent = f })
		return
	end
	tile(f, o.car, 30, 10, 10)
	text({ Text = ("Offer %s · %s"):format(money(o.amount), carName(o.car)), TextSize = 13, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(50, 7), Size = UDim2.new(1, -230, 0, 18), Parent = f })
	refs.offerSub = text({ Text = "", Font = MONO, TextSize = 11, TextColor3 = C.sub, Position = UDim2.fromOffset(50, 26), Size = UDim2.new(1, -230, 0, 16), Parent = f })
	refs.offerInfo = { rating = o.rating, worth = o.worth, left = o.left, amount = o.amount }
	local pass = pill(f, "PASS", C.stroke, false, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(62, 32) })
	local sell = pill(f, "SELL", C.purple, true, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(66, 32) })
	pass.Activated:Connect(function()
		ask("pass")
	end)
	sell.Activated:Connect(function()
		ask("accept")
	end)
end

render = function()
	local s = st
	if not s or not canvas then
		return
	end
	if holding then
		dirty = true
		return
	end
	dirty = false
	local leftW, rightW = layout()
	refs.cash.Text = money(s.cash)
	local n = s.news
	refs.newsTag.Text = (n.tag or "") .. (if n.up then " ▲" else " ▼")
	refs.newsTag.TextColor3 = if n.up then C.green else C.red
	local tagW = (#(n.tag or "") + 2) * 8.6
	refs.newsTag.Size = UDim2.fromOffset(tagW, 26)
	refs.newsText.Position = UDim2.fromOffset(62 + tagW + 8, 0)
	refs.newsText.Text = n.text or ""
	local open = 0
	for _, r in s.requests do
		if not r.done then
			open += 1
		end
	end
	refs.reqSub.Text = if open > 0 then ("%d open · new daily"):format(open) else ("all done · new in %dh"):format(math.floor((s.resetIn or 0) / 3600))
	refs.stallSub.Text = ("Sell to the market · %d%% fee"):format(math.floor(s.fee * 100 + 0.5))
	if not s.flip then
		refs.flipSub.Text = if (s.flipReadyIn or 0) > 0 then ("vs Slick Vinny · ready in %ds"):format(s.flipReadyIn) else "vs Slick Vinny · 3 min"
	end
	renderOffer(s)

	-- listings
	local list = refs.list :: ScrollingFrame
	clear(list)
	for i, l in s.listings do
		listingRow(list, l, (i - 1) * 62, leftW)
	end
	list.CanvasSize = UDim2.fromOffset(0, #s.listings * 62)

	-- stash
	refs.stashHead.Text = ("Stash  %d/%d"):format(#s.stash, s.slots)
	local chips = refs.stashChips :: Frame
	clear(chips)
	local x = 0
	x += chip(chips, x, ("%d%% fees"):format(math.floor(s.fee * 100 + 0.5)), C.red) + 8
	chip(chips, x, ("HYPE %d/%d"):format(s.hype, s.hypeMax), C.orange)
	chips.Position = UDim2.fromOffset(refs.stashHead.Position.X.Offset + #refs.stashHead.Text * 9.6 + 10, refs.stashHead.Position.Y.Offset + 2)
	local grid = refs.stash :: ScrollingFrame
	clear(grid)
	local cw = math.floor((rightW - 8 - 10) / 2)
	for i, it in s.stash do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		stashCard(grid, it, col * (cw + 10), row * 100, cw, s.hist[it.car])
	end
	if #s.stash == 0 then
		text({ Text = "Nothing here yet. Buy low in Listings, sell high.", TextSize = 13, Font = Enum.Font.GothamMedium, TextColor3 = C.sub, Size = UDim2.fromOffset(rightW, 30), Parent = grid })
	end
	grid.CanvasSize = UDim2.fromOffset(0, math.ceil(#s.stash / 2) * 100)
end

-- countdowns between server pushes (offer timer, flip-off clock)
local function tickLabels()
	local s = st
	if not s or not MarketUI.isOpen then
		return
	end
	local gone = os.clock() - stAt
	local info = refs.offerInfo
	if s.offer and info and refs.offerSub and refs.offerSub.Parent then
		local left = math.max(0, math.ceil(info.left - gone))
		refs.offerSub.Text = ("★%.1f buyer · worth %s · %ds"):format(info.rating, money(info.worth), left)
		if left <= 0 then
			s.offer = nil
			render()
		end
	end
	local f = s.flip
	if f then
		local left = math.max(0, math.ceil(f.left - gone))
		refs.flipSub.Text = ("You %s vs Vinny %s · %d:%02d"):format(money(f.mine), money(f.vinny), left // 60, left % 60)
	end
	if dirty and not holding then
		render()
	end
end

---------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------
function MarketUI.open()
	if MarketUI.isOpen or not gui then
		return
	end
	MarketUI.isOpen = true
	;(gui :: ScreenGui).Enabled = true
	layout()
	task.spawn(function()
		local res = ask("open")
		if not res then
			MarketUI.close()
		end
	end)
end

function MarketUI.close()
	if not MarketUI.isOpen then
		return
	end
	MarketUI.isOpen = false
	closeModal()
	if gui then
		gui.Enabled = false
	end
	local r = call
	if r then
		task.spawn(function()
			pcall(function()
				r:InvokeServer("close")
			end)
		end)
	end
end

function MarketUI.toggle()
	if MarketUI.isOpen then
		MarketUI.close()
	else
		MarketUI.open()
	end
end

function MarketUI.init()
	build()
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		call = remotes:WaitForChild("MarketCall") :: RemoteFunction
		local pushEv = remotes:WaitForChild("MarketPush") :: RemoteEvent
		pushEv.OnClientEvent:Connect(function(state: any)
			if type(state) ~= "table" then
				return
			end
			st = state
			stAt = os.clock()
			local fr = state.flipResult
			if type(fr) == "table" then
				if fr.won then
					toast(("You beat Slick Vinny! +%s"):format(money(fr.prize)), true)
				else
					toast(("Vinny wins this one: %s vs your %s"):format(money(fr.vinny), money(fr.mine)), false)
				end
			end
			if state.newOffer then
				Audio.click()
			end
			if MarketUI.isOpen then
				render()
			end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.K then
			MarketUI.toggle()
		end
	end)
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if MarketUI.isOpen then
				render()
			end
		end)
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.5 then
			acc = 0
			tickLabels()
		end
	end)
end

return MarketUI
