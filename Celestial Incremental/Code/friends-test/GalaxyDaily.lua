-- GalaxyDaily (Galaxy Incremental, Phase 2, 6 Nov): the reasons to come back, client side.
--  * 2.3 the RETURN screen (#411): "WHILE YOU WERE AWAY" + what you earned (counts up), CLAIM (free) and x2 (a developer
--    product, server-granted in ProcessReceipt; hidden while GameConfig.Products.OfflineX2.id is 0). X also claims: it never
--    blocks play and never loses what you earned. Numbers: the server's OfflinePending / OfflineAway attributes.
--  * 2.4 the DAILY window (hotbar J): the 7-day streak, 3 daily quests, 4 playtime gifts; and the plaza's FREE REWARDS board
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: closes only by X, Esc / B, outside)
local Vfx = require(Galaxy:WaitForChild("VfxLibrary"))
local Art = require(Galaxy:WaitForChild("ArtIds")) -- (7 Nov: the stopwatch)
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Config = require(Galaxy:WaitForChild("GameConfig"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local event = Galaxy:WaitForChild("EconEvent") :: RemoteEvent
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local fmt = Econ.Format

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyDaily"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 4
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local PHONE_TEST = Kit.testDevice() ~= nil -- (Studio: Workspace TestDevice / TestPhone, UIKit)
local root: GuiObject | ScreenGui = Kit.testRoot(gui) -- (7 Nov: the safe area; Studio: the emulated device)
local function viewport(): Vector2
	return Kit.viewport(root)
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end
-- a window centred between the counter and the hotbar, as big as fits (the side windows' rule)
local function placeIn(holder: GuiObject, W: number, H: number): number
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end
local function away(seconds: number): string
	local h, m = seconds // 3600, (seconds % 3600) // 60
	if h > 0 then return h .. "h " .. m .. "m" end
	return math.max(m, 1) .. " min"
end

------------------------------------------------------------------------ 2.3 the RETURN screen (520 x 330)
local RW, RH = 520, 330
local ret = Kit.box(root, 0, 0, RW, RH, { Name = "ReturnWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local retScale = Instance.new("UIScale")
retScale.Parent = ret
local retWin, retClose = Kit.window(ret, RW, RH, { title = "WHILE YOU WERE AWAY", icon = "offlineEarnings", iconGlow = Color3.fromRGB(255, 170, 60),
	c1 = hex("#7a3a14"), c2 = hex("#ff9a3a"), lip = hex("#c2410c"), glow = Color3.fromRGB(255, 140, 40), line = hex("#ffc58a") })
local retAway = Kit.text(retWin, 0, 74, RW, 24, "", Kit.ps(18, 20), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#e8e2f0") })
local amtPanel = Kit.panel(retWin, 40, 106, RW - 80, 88, 5)
Kit.stroke(amtPanel, hex("#ff9a3a"), 2, 0.3)
Kit.icon(retWin, "stardust", 56, 108, 84, Color3.fromRGB(255, 170, 60), { ZIndex = 8 })
local retAmount = Kit.text(retWin, 146, 122, RW - 200, 56, "+0", 48, { ZIndex = 9, FontFace = Kit.FONT_HEAVY, stroke = 2.6,
	gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
local retRule = Kit.text(retWin, 0, 202, RW, 22, "", Kit.ps(15, 17), { ZIndex = 8, TextXAlignment = CENTRE, TextColor3 = hex("#a99fb8"), stroke = 1.2 })
local x2 = Config.Products and Config.Products.OfflineX2
local hasX2 = x2 ~= nil and x2.id ~= 0
local claimW = if hasX2 then 210 else 260
local claimBtn, claimInner = Kit.button(retWin, if hasX2 then 40 else (RW - claimW) / 2, 240, claimW, 64, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
Kit.text(claimInner, 0, Kit.ps(15, 13), claimW, 34, "CLAIM", 30, { ZIndex = claimInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
Kit.tagVfx(Kit.shine(claimBtn, 2.4))
local x2Btn, x2Inner
if hasX2 then
	x2Btn, x2Inner = Kit.button(retWin, RW - 40 - 230, 240, 230, 64, hex("#ffd84a"), hex("#e08a00"), { ZIndex = 6 })
	Kit.text(x2Inner, 0, Kit.ps(6, 4), 230, 32, "x2 CLAIM", 28, { ZIndex = x2Inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
	Kit.text(x2Inner, 0, Kit.ps(36, 34), 230, 22, "R$ " .. x2.price, Kit.ps(17, 19), { ZIndex = x2Inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
end

local retOpen, counting = false, nil
local function closeReturn()
	if not retOpen then return end
	retOpen = false
	Kit.tween(retScale, { Scale = retScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not retOpen then ret.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("R", false) end
end
local busy = false
local function claim()
	if busy then return end
	busy = true
	local ok, amount = request:InvokeServer("OfflineClaim")
	busy = false
	if ok then
		Kit.sound("milestone")
		Vfx.UiClaimAt(claimBtn) -- (the VFX pass: coins, small rays, confetti)
		if shared.GalaxyToast then shared.GalaxyToast("+" .. fmt(amount) .. " STARDUST", hex("#ffc35a")) end
	end
	closeReturn()
end
local function openReturn()
	local pending = player:GetAttribute("OfflinePending") or 0
	if retOpen or pending <= 0 then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("R") end
	retOpen = true
	ret.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("R", true) end
	local rate, cap = Econ.OfflineOf((function()
		local t = {}
		for _, n in ipairs(Econ.Ring2) do t[n.id] = player:GetAttribute("R2_" .. n.id) or 0 end
		return t
	end)())
	Kit.setText(retAway, "You were away " .. away(player:GetAttribute("OfflineAway") or 0))
	Kit.setText(retRule, math.floor(rate * 100 + 0.5) .. "% of your income, up to " .. math.floor(cap / 3600) .. " h")
	Kit.sound("open")
	local want = placeIn(ret, RW, RH)
	retScale.Scale = want * 0.8
	Kit.tween(retScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
	-- the amount counts up from 0 over 1.2 s, a tick sound every few frames
	local t0 = os.clock()
	if counting then counting:Disconnect() end
	local ticks = 0
	counting = RunService.Heartbeat:Connect(function()
		local k = math.clamp((os.clock() - t0) / 1.2, 0, 1)
		local eased = 1 - (1 - k) ^ 3
		Kit.setText(retAmount, "+" .. fmt(pending * eased))
		ticks += 1
		if k < 1 and ticks % 6 == 0 then Kit.sound("tab", { pitch = 0.8 + k * 0.6, volume = 0.5 }) end
		if k >= 1 then counting:Disconnect() counting = nil end
	end)
end
claimBtn.MouseButton1Click:Connect(function() Kit.sound("click") claim() end)
-- (X claims too: closing never loses what you earned)
retClose.MouseButton1Click:Connect(claim)
if x2Btn then
	x2Btn.MouseButton1Click:Connect(function()
		Kit.sound("click")
		request:InvokeServer("OfflineX2")
	end)
end
event.OnClientEvent:Connect(function(kind, key, amount)
	if kind == "ProductGranted" and key == "OfflineX2" then
		Kit.sound("milestone")
		if shared.GalaxyToast then shared.GalaxyToast("x2!  +" .. fmt(amount) .. " STARDUST", hex("#ffd84a")) end
		closeReturn()
	end
end)
-- (another window opening = claim + close, so nothing is lost)
shared.GalaxyReturnClose = function() if retOpen then claim() end end
WM.register("R", ret, shared.GalaxyReturnClose)
-- shown once the loading screen and any cinematic are done
task.spawn(function()
	task.wait(4)
	while shared.GalaxyCinematic do task.wait(0.5) end
	openReturn()
end)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if retOpen then retScale.Scale = placeIn(ret, RW, RH) end end)

------------------------------------------------------------------------ 2.4 the DAILY window (hotbar J "QUESTS"; #412-#414 #142)
-- top: the 7-day STREAK (claim today's); bottom left: today's 3 QUESTS (progress bar, CLAIM when done); bottom right: the
-- 4 PLAYTIME GIFTS (5 / 15 / 30 / 60 min today). All from the server's attributes; every claim is checked by the server.
local HttpService = game:GetService("HttpService")
local DW, DH = 700, 440
local daily = Kit.box(root, 0, 0, DW, DH, { Name = "DailyWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local dScale = Instance.new("UIScale")
dScale.Parent = daily
local dWin, dClose = Kit.window(daily, DW, DH, { title = "DAILY", icon = "dailyStreak", iconGlow = Color3.fromRGB(60, 230, 210),
	c1 = hex("#0f5a52"), c2 = hex("#38d6c0"), lip = hex("#14907f"), glow = Color3.fromRGB(60, 230, 210), line = hex("#8af5e6") })
local function heading(x, y, text)
	return Kit.text(dWin, x, y, 300, 26, text, Kit.ps(19, 21), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8,
		gradient = ColorSequence.new(hex("#e8fffb"), hex("#5ae6d2")) })
end
-- the STREAK
heading(24, 68, "DAILY STREAK")
local streakNote = Kit.text(dWin, 230, 72, DW - 254, 22, "", Kit.ps(14, 16), { ZIndex = 8, TextColor3 = hex("#a99fb8"), stroke = 1.1, TextXAlignment = Enum.TextXAlignment.Right })
local dayTiles = {}
for i = 1, 7 do
	local x = 24 + (i - 1) * 94
	local tile = Kit.box(dWin, x, 100, 84, 92, { BackgroundTransparency = 0, BackgroundColor3 = hex("#130f1e"), ZIndex = 5 })
	Kit.corner(tile, 10)
	local st = Kit.stroke(tile, hex("#2e2840"), 2.5)
	Kit.text(dWin, x, 104, 84, 20, "DAY " .. i, Kit.ps(14, 16), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
	Kit.icon(dWin, if i == 7 then "sun" else "essence", x + 20, 122, 44, nil, { ZIndex = 7 })
	local amt = Kit.text(dWin, x, 166, 84, 22, "+" .. Econ.Daily.Essence[i] .. (if i == 7 then " +1H" else ""), Kit.ps(15, 17), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.5, TextColor3 = hex("#7dffe9") })
	dayTiles[i] = { tile = tile, stroke = st, amt = amt }
end
local dayBtn, dayInner, _, dayShadow = Kit.button(dWin, DW - 24 - 200, 204, 200, 46, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
local dayText = Kit.text(dayInner, 0, Kit.ps(10, 8), 200, 28, "CLAIM", Kit.ps(21, 23), { ZIndex = dayInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
local dayCool = Kit.new("ImageLabel", { Name = "Cooldown", BackgroundTransparency = 1, Image = Art.uiIcon.cooldown, ScaleType = Enum.ScaleType.Fit,
	Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(32, 32), ZIndex = dayInner.ZIndex + 1, Visible = false }, dayInner)
local dayInfo = Kit.text(dWin, 24, 214, DW - 260, 26, "", Kit.ps(14, 16), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextWrapped = true })
-- the QUESTS
heading(24, 262, "TODAY'S QUESTS")
Kit.text(dWin, 220, 266, 220, 22, "+1 ESSENCE + 5 MIN OF INCOME", Kit.ps(12, 14), { ZIndex = 8, TextColor3 = hex("#7dffe9"), stroke = 1.1, TextXAlignment = Enum.TextXAlignment.Right })
local questRows = {}
for i = 1, 3 do
	local y = 292 + (i - 1) * 46
	local panel = Kit.panel(dWin, 24, y, 416, 40, 4)
	local text = Kit.text(dWin, 34, y + Kit.ps(3, 2), 290, 20, "", Kit.ps(14, 16), { ZIndex = 8, FontFace = Kit.FONT_BOLD, stroke = 1.2 })
	local bar = Kit.box(dWin, 34, y + 26, 200, 8, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(bar, 4)
	local fill = Kit.box(bar, 0, 0, 0, 8, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(fill, 4)
	Kit.grad(fill, hex("#bffff5"), hex("#2fc8b2"), 90)
	local count = Kit.text(dWin, 240, y + 20, 80, 18, "", Kit.ps(13, 15), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.2 })
	local b, inner, _, shadow = Kit.button(dWin, 330, y + 4, 102, 32, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	local bt = Kit.text(inner, 0, Kit.ps(5, 4), 102, 22, "CLAIM", Kit.ps(16, 18), { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.5 })
	questRows[i] = { text = text, fill = fill, count = count, button = b, label = bt, panel = panel, shadow = shadow }
end
-- the GIFTS (7 Nov: five, 5 / 10 / 20 / 40 / 60 min: 3 + 2 tiles)
heading(460, 262, "PLAYTIME GIFTS")
local giftTiles = {}
for i, m in ipairs(Econ.Gifts) do
	local x, y = 460 + ((i - 1) % 3) * 76, 292 + ((i - 1) // 3) * 70
	local panel = Kit.panel(dWin, x, y, 70, 62, 4)
	Kit.icon(dWin, "playtimeGift", x + 1, y + 2, 28, nil, { ZIndex = 7 })
	Kit.text(dWin, x + 28, y + 7, 40, 20, tostring(m), Kit.ps(15, 17), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.4, TextXAlignment = CENTRE })
	local b, inner = Kit.button(dWin, x + 4, y + 32, 62, 24, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	local bt = Kit.text(inner, 12, Kit.ps(2, 1), 50, 20, "", Kit.ps(12, 14), { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.3 })
	-- (7 Nov, item 5: a time-locked gift shows the stopwatch beside its countdown)
	local cool = Kit.new("ImageLabel", { Name = "Cooldown", BackgroundTransparency = 1, Image = Art.uiIcon.cooldown, ScaleType = Enum.ScaleType.Fit,
		Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(16, 16), ZIndex = inner.ZIndex + 1, Visible = false }, inner)
	giftTiles[i] = { m = m, button = b, label = bt, panel = panel, cool = cool }
end

local function quests()
	local ok, list = pcall(function() return HttpService:JSONDecode(player:GetAttribute("Quests") or "[]") end)
	return if ok and type(list) == "table" then list else {}
end
-- something to claim? (the hotbar's red dot)
local function claimable(): boolean
	if player:GetAttribute("DailyReady") == true then return true end
	for _, q in ipairs(quests()) do if not q.got and q.have >= q.need then return true end end
	local played = player:GetAttribute("GiftPlayed") or 0
	local got = "," .. (player:GetAttribute("GiftsGot") or "") .. ","
	for _, m in ipairs(Econ.Gifts) do if played >= m * 60 and not got:find("," .. m .. ",", 1, true) then return true end end
	return false
end
local function refreshDaily()
	local ready = player:GetAttribute("DailyReady") == true
	local day = player:GetAttribute("DailyDay") or 1
	for i, t in ipairs(dayTiles) do
		local got = i < day or (i == day and not ready)
		local now = i == day and ready
		t.stroke.Color = if now then hex("#ffd84a") elseif got then hex("#7dff9a") else hex("#2e2840")
		t.stroke.Thickness = if now then 4 else 2.5
		t.tile.BackgroundColor3 = if got then hex("#123326") else hex("#130f1e")
	end
	Kit.setText(streakNote, "Miss a day: back to day 1 (you keep what you got)")
	-- (7 Nov, item 5: claimed today = the button stays, grey, with the stopwatch: "TOMORROW")
	dayBtn.Visible = true
	dayShadow.Visible = true
	Kit.recolour(dayBtn, if ready then hex("#7dff7a") else hex("#6a6474"), if ready then hex("#1fa83a") else hex("#3f3a48"))
	dayCool.Visible = not ready
	Kit.setText(dayText, if ready then "CLAIM DAY " .. day else "TOMORROW")
	Kit.setText(dayInfo, if ready then "Day " .. day .. ": +" .. Econ.Daily.Essence[day] .. " Essence" .. (if day == 7 then " + a 1 h TIME WARP" else "")
		else "Come back tomorrow for day " .. (day % 7 + 1) .. "!")
	local list = quests()
	for i, r in ipairs(questRows) do
		local q = list[i]
		r.panel.Visible = q ~= nil
		r.text.Parent.Visible = q ~= nil
		r.fill.Parent.Visible = q ~= nil
		r.count.Parent.Visible = q ~= nil
		r.button.Visible = q ~= nil
		r.shadow.Visible = q ~= nil
		if q then
			Kit.setText(r.text, q.text)
			Kit.setText(r.count, math.max(q.have, 0) .. "/" .. q.need)
			r.fill.Size = UDim2.fromOffset(math.floor(200 * math.clamp(q.have / q.need, 0, 1)), 8)
			local done = q.have >= q.need
			Kit.recolour(r.button, if q.got then hex("#b49bff") elseif done then hex("#7dff7a") else hex("#6a6474"), if q.got then hex("#5a3ad8") elseif done then hex("#1fa83a") else hex("#3f3a48"))
			-- (7 Nov, item 5: a quest that isn't done shows its progress on the button, "3/5")
			Kit.setText(r.label, if q.got then "DONE" elseif done then "CLAIM" else math.max(q.have, 0) .. "/" .. q.need)
		end
	end
	local played = player:GetAttribute("GiftPlayed") or 0
	local got = "," .. (player:GetAttribute("GiftsGot") or "") .. ","
	for _, g in ipairs(giftTiles) do
		local have = got:find("," .. g.m .. ",", 1, true) ~= nil
		local ready2 = played >= g.m * 60
		Kit.recolour(g.button, if have then hex("#b49bff") elseif ready2 then hex("#7dff7a") else hex("#6a6474"), if have then hex("#5a3ad8") elseif ready2 then hex("#1fa83a") else hex("#3f3a48"))
		local left = math.max(0, g.m * 60 - played)
		Kit.setText(g.label, if have then "GOT" elseif ready2 then "CLAIM" else string.format("%d:%02d", left // 60, left % 60))
		g.cool.Visible = not have and not ready2
		-- (the label centres on the button; with the stopwatch it sits right of it)
		local h = g.label.Parent :: GuiObject
		h.Position = UDim2.new(0, if g.cool.Visible then 12 else 0, h.Position.Y.Scale, h.Position.Y.Offset)
		h.Size = UDim2.new(0, if g.cool.Visible then 50 else 62, h.Size.Y.Scale, h.Size.Y.Offset)
	end
	if shared.GalaxyHotbarDot then shared.GalaxyHotbarDot("J", claimable()) end
end
local function claimFx(text: string, from: GuiObject?)
	Kit.sound("milestone")
	if from then Vfx.UiClaimAt(from) end -- (the VFX pass: coins, small rays, confetti)
	if shared.GalaxyToast then shared.GalaxyToast(text, hex("#7dffe9")) end
end
dayBtn.MouseButton1Click:Connect(function()
	Kit.sound("click")
	local ok, day, ess, warp = request:InvokeServer("DailyClaim")
	if ok then claimFx("DAY " .. day .. ": +" .. ess .. " ESSENCE" .. (if warp and warp > 0 then "  +" .. fmt(warp) else ""), dayBtn) else Kit.sound("error") end
end)
for i, r in ipairs(questRows) do
	r.button.MouseButton1Click:Connect(function()
		local ok, ess, pay = request:InvokeServer("QuestClaim", i)
		if ok then claimFx("QUEST DONE: +" .. ess .. " ESSENCE  +" .. fmt(pay), r.button) else Kit.sound("error") end
	end)
end
for _, g in ipairs(giftTiles) do
	g.button.MouseButton1Click:Connect(function()
		local ok, what = request:InvokeServer("GiftClaim", g.m)
		if ok then claimFx("GIFT: " .. tostring(what or "+1 ESSENCE"), g.button) else Kit.sound("error") end
	end)
end
for _, a in ipairs({ "DailyReady", "DailyDay", "Quests", "GiftsGot" }) do player:GetAttributeChangedSignal(a):Connect(refreshDaily) end

local dOpen = false
-- (the gift timers tick while the window is open; the red dot is checked every 5 s)
task.spawn(function()
	while true do
		task.wait(if dOpen then 1 else 5)
		refreshDaily()
	end
end)
local function closeDaily()
	if not dOpen then return end
	dOpen = false
	Kit.sound("close")
	Kit.tween(dScale, { Scale = dScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not dOpen then daily.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("J", false) end
end
local function openDaily()
	if dOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("J") end
	dOpen = true
	Kit.sound("open")
	refreshDaily()
	daily.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("J", true) end
	local want = placeIn(daily, DW, DH)
	dScale.Scale = want * 0.8
	Kit.tween(dScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyDailyToggle = function() if dOpen then closeDaily() else openDaily() end end
shared.GalaxyDailyClose = closeDaily
WM.register("J", daily, closeDaily)
dClose.MouseButton1Click:Connect(closeDaily)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if dOpen then dScale.Scale = placeIn(daily, DW, DH) end end)
task.defer(refreshDaily)

------------------------------------------------------------------------ 2.4 the plaza's FREE REWARDS board (Workspace.Galaxy.Centre.FreeBoard,
-- built by GalaxyMapBuilder): its screen is drawn here (a SurfaceGui in PlayerGui so the buttons take clicks / taps)
task.spawn(function()
	local board = workspace:WaitForChild("Galaxy"):WaitForChild("Centre"):WaitForChild("FreeBoard", 60)
	local screen = board and board:WaitForChild("Screen", 10)
	if not screen then return end
	local sg = Instance.new("SurfaceGui")
	sg.Name = "FreeRewardsBoard"
	sg.Adornee = screen
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(440, 300)
	sg.LightInfluence = 0
	sg.Brightness = 1.8
	sg.MaxDistance = 140
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = playerGui
	local bg = Kit.box(sg, 0, 0, 440, 300, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1 })
	Kit.grad(bg, hex("#1d1a2a"), hex("#0e0c14"), 90)
	Kit.text(sg, 0, 14, 440, 40, "FREE REWARDS", 34, { ZIndex = 5, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2.4,
		gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	-- (6 Nov: the board's own icon either side of the title)
	Kit.icon(sg, "freeRewards", 34, 6, 54, nil, { ZIndex = 5 })
	Kit.icon(sg, "freeRewards", 440 - 34 - 54, 6, 54, nil, { ZIndex = 5 })
	local rows = {}
	for i, f in ipairs(Econ.FreeRewards) do
		local y = 70 + (i - 1) * 92
		local p = Kit.panel(sg, 20, y, 400, 80, 2)
		Kit.text(sg, 34, y + 10, 230, 30, f.text, 24, { ZIndex = 5, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
		Kit.icon(sg, "essence", 30, y + 40, 34, nil, { ZIndex = 5 })
		Kit.text(sg, 66, y + 46, 200, 26, "+" .. f.essence .. " ESSENCE", 20, { ZIndex = 5, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#7dffe9") })
		local b, inner = Kit.button(sg, 280, y + 16, 128, 48, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 4 })
		local bt = Kit.text(inner, 0, 11, 128, 26, "CLAIM", 22, { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
		rows[f.id] = { button = b, label = bt, panel = p }
		b.MouseButton1Click:Connect(function()
			Kit.sound("click")
			local ok, why = request:InvokeServer("FreeClaim", f.id)
			if ok then
				claimFx("+" .. f.essence .. " ESSENCE: thank you!")
			elseif why == "notmember" then
				Kit.sound("error")
				if shared.GalaxyToast then shared.GalaxyToast("Join P&L Studios XP first (tap GROUP on the left)", hex("#ffd84a")) end
			else
				Kit.sound("error")
			end
		end)
	end
	Kit.text(sg, 20, 258, 400, 30, "Likes can't be checked by a game: we trust you!", 15, { ZIndex = 5, TextXAlignment = CENTRE, TextColor3 = hex("#a99fb8"), stroke = 1.1 })
	local function refresh()
		local got = "," .. (player:GetAttribute("FreeGot") or "") .. ","
		for id, r in pairs(rows) do
			local have = got:find("," .. id .. ",", 1, true) ~= nil
			Kit.recolour(r.button, if have then hex("#b49bff") else hex("#7dff7a"), if have then hex("#5a3ad8") else hex("#1fa83a"))
			Kit.setText(r.label, if have then "GOT" else "CLAIM")
		end
	end
	player:GetAttributeChangedSignal("FreeGot"):Connect(refresh)
	refresh()
end)
