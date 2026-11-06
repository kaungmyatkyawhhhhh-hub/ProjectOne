-- GalaxyLive (LocalScript, StarterPlayerScripts; 7 Nov, "MONETIZATION + RETENTION BEFORE THE ALPHA"): the live-ops HUD.
--  * the GIFT chip (right side): the next PLAYTIME GIFT's real countdown (minutes played today, from the server's GiftPlayed,
--    ticking in between) or "GIFT READY!"; a tap opens DAILY. Hidden once today's gifts are all claimed.
--  * the EVENT banner (top): the running event (GalaxyLiveService's EventTitle / EventEnds) and its real time left.
--  * WHAT'S NEW (GameConfig.WhatsNew): opens once per new version, after the tutorial, when nothing else is open.
--  * "UPDATE INCOMING!" (a restart for an update is scheduled; everything is saved) + the update gift's message.
--  * FAVOURITE: Roblox's favourite prompt once, right after your FIRST Supernova (never again once answered).
--  * NOTIFICATIONS: Roblox's opt-in prompt once, after your 3rd session (13+ only; Roblox decides who can see it).
--  * the VIP chat tag ([VIP] in gold before a VIP player's name).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Config = require(Galaxy:WaitForChild("GameConfig"))
local WM = require(Galaxy:WaitForChild("WindowManager"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local liveEvent = Galaxy:WaitForChild("LiveEvent") :: RemoteEvent
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

------------------------------------------------------------------------ the VIP chat tag (works before the save loads)
TextChatService.OnIncomingMessage = function(msg: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	local src = msg.TextSource
	local p = src and Players:GetPlayerByUserId(src.UserId)
	if p and p:GetAttribute("Pass_VIP") == true then
		props.PrefixText = '<font color="#FFD84A"><b>[VIP]</b></font> ' .. msg.PrefixText
	end
	return props
end

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local function makeGui(name: string, order: number)
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = order
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = playerGui
	return g
end
local gui = makeGui("GalaxyLive", 1)
local winGui = makeGui("GalaxyWhatsNew", 4)
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local function rootOf(g: ScreenGui): GuiObject | ScreenGui
	if not PHONE_TEST then return g end
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	f.Parent = g
	return f
end
local root, winRoot = rootOf(gui), rootOf(winGui)
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end
local function mmss(t: number): string
	t = math.max(0, math.floor(t))
	if t >= 3600 then return string.format("%d:%02d:%02d", t // 3600, t % 3600 // 60, t % 60) end
	return string.format("%d:%02d", t // 60, t % 60)
end
local function toast(text: string, colour: Color3)
	if shared.GalaxyToast then shared.GalaxyToast(text, colour) end
end
-- the kit's chip (the BOOSTS chip's look: shadow, dark plate, coloured edge, shine, icon breaking out, heavy text)
local function chip(parent: Instance, w: number, h: number, colour: Color3, icon: string)
	local c = Kit.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(w, h), ZIndex = 9 }, parent)
	local sh = Kit.box(c, 0, 3, w, h, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(sh, 8)
	local plate = Kit.box(c, 0, 0, w, h, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 8)
	Kit.stroke(plate, Kit.INK, 2)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(c, 3, 3, w - 6, h - 6, { ZIndex = 3 })
	Kit.corner(edge, 6)
	local edgeStroke = Kit.stroke(edge, colour, 1.5, 0.3)
	Kit.box(c, 8, 4, w - 16, 2, { BackgroundTransparency = 0.55, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.icon(c, icon, -4, -4, h + 8, colour, { ZIndex = 5 })
	local text = Kit.text(c, h + 4, Kit.ps(9, 8), w - h - 10, 22, "", Kit.ps(16, 17), { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = colour })
	return c, text, edgeStroke
end

------------------------------------------------------------------------ the GIFT chip (right side)
local giftRoot = Kit.box(root, 0, 0, 220, 40, { Name = "GiftChip", AnchorPoint = Vector2.new(1, 0.5) })
local giftScale = Instance.new("UIScale")
giftScale.Parent = giftRoot
local giftBtn, giftText, giftEdge = chip(giftRoot, 220, 40, hex("#ffd84a"), "playtimeGift")
local lastPlayed, playedAt = player:GetAttribute("GiftPlayed") or 0, os.clock()
player:GetAttributeChangedSignal("GiftPlayed"):Connect(function()
	lastPlayed, playedAt = player:GetAttribute("GiftPlayed") or 0, os.clock()
end)
local function giftState(): (string, number?)
	local played = lastPlayed + math.min(os.clock() - playedAt, 2)
	local got = "," .. (player:GetAttribute("GiftsGot") or "") .. ","
	local nextLeft
	for _, m in ipairs(Econ.Gifts) do
		if not got:find("," .. m .. ",", 1, true) then
			if played >= m * 60 then return "ready" end
			nextLeft = nextLeft or (m * 60 - played)
		end
	end
	return if nextLeft then "wait" else "done", nextLeft
end
giftBtn.MouseButton1Click:Connect(function()
	Kit.sound("click")
	if not WM.isOpen("J") and shared.GalaxyDailyToggle then shared.GalaxyDailyToggle() end
end)

------------------------------------------------------------------------ the EVENT banner (top) + "UPDATE INCOMING!"
local function banner(colour1: string, colour2: string, icon: string)
	local b = Kit.box(root, 0, 0, 420, 44, { AnchorPoint = Vector2.new(0.5, 0), Visible = false })
	local sc = Instance.new("UIScale")
	sc.Parent = b
	local sh = Kit.box(b, 0, 4, 420, 44, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(sh, 10)
	local plate = Kit.box(b, 0, 0, 420, 44, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 10)
	Kit.stroke(plate, Kit.INK, 2.5)
	Kit.grad(plate, hex(colour1), hex(colour2), 90)
	Kit.box(b, 10, 4, 400, 3, { BackgroundTransparency = 0.5, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.icon(b, icon, -10, -10, 62, nil, { ZIndex = 5 })
	local t = Kit.text(b, 50, Kit.ps(10, 9), 360, 26, "", Kit.ps(20, 21), { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 2, TextXAlignment = CENTRE })
	return b, t, sc
end
local eventBar, eventText, eventScale = banner("#ffb02a", "#a8380a", "stardust")
local updateBar, updateText, updateScale = banner("#5ad1ff", "#1f4fd1", "ui:reset")
local updateUntil = 0

------------------------------------------------------------------------ layout + the 1 s tick
local function layout()
	local s = screenScale()
	local vp = viewport()
	giftScale.Scale = s
	giftRoot.Position = UDim2.fromOffset(vp.X - math.floor(10 * s), math.floor(vp.Y * 0.42))
	eventScale.Scale, updateScale.Scale = s, s
	-- (under the counter's SUPERNOVA bar + NEXT line)
	eventBar.Position = UDim2.fromOffset(vp.X / 2, math.floor(152 * s))
	updateBar.Position = UDim2.fromOffset(vp.X / 2, math.floor((152 + 52) * s))
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()
local function tick()
	local busy = WM.anyOpen() or shared.GalaxyCinematic == true
	-- gift chip
	local state, left = giftState()
	giftRoot.Visible = state ~= "done" and not busy
	if state == "ready" then
		Kit.setText(giftText, "GIFT READY!")
		giftText.TextColor3 = hex("#7dff7a")
		giftEdge.Color = hex("#7dff7a")
	elseif state == "wait" and left then
		Kit.setText(giftText, "NEXT GIFT " .. mmss(left))
		giftText.TextColor3 = hex("#ffd84a")
		giftEdge.Color = hex("#ffd84a")
	end
	-- event banner (the real time left)
	local now = workspace:GetServerTimeNow()
	local ends = Galaxy:GetAttribute("EventEnds") or 0
	local on = ends > now and (Galaxy:GetAttribute("EventId") or "") ~= ""
	eventBar.Visible = on and not busy
	if on then Kit.setText(eventText, tostring(Galaxy:GetAttribute("EventTitle")) .. "  ·  " .. mmss(ends - now) .. " LEFT") end
	-- update banner
	updateBar.Visible = updateUntil > 0 and not busy
	if updateUntil > 0 then
		local l = updateUntil - os.clock()
		Kit.setText(updateText, if l > 0 then "UPDATE INCOMING! " .. mmss(l) .. " · SAVED" else "UPDATE INCOMING! YOUR PROGRESS IS SAVED")
	end
end
task.spawn(function()
	while true do
		tick()
		task.wait(1)
	end
end)
for _, a in ipairs({ "GiftsGot" }) do player:GetAttributeChangedSignal(a):Connect(tick) end

liveEvent.OnClientEvent:Connect(function(kind, a, b)
	if kind == "UpdateIncoming" then
		updateUntil = os.clock() + (tonumber(a) or 0)
		Kit.sound("milestone")
		tick()
	elseif kind == "UpdateGift" then
		Kit.sound("milestone")
		toast("UPDATE GIFT: +" .. tostring(b) .. " ESSENCE. Thanks for playing!", hex("#7dffe9"))
	end
end)

------------------------------------------------------------------------ WHAT'S NEW
local WN = Config.WhatsNew
local WW, WH = 560, 100 + #WN.lines * 44 + 76
local wHolder = Kit.box(winRoot, 0, 0, WW, WH, { Name = "WhatsNewWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local wScale = Instance.new("UIScale")
wScale.Parent = wHolder
local wWin, wClose = Kit.window(wHolder, WW, WH, { title = WN.title, icon = "stardust", iconGlow = Color3.fromRGB(90, 200, 255),
	c1 = hex("#123a7a"), c2 = hex("#5ad1ff"), lip = hex("#1f6fd1"), glow = Color3.fromRGB(70, 170, 255), line = hex("#9be4ff") })
local wPanel = Kit.panel(wWin, 16, 72, WW - 32, #WN.lines * 44 + 20, 4)
Kit.stroke(wPanel, hex("#5ad1ff"), 2, 0.2)
for i, line in ipairs(WN.lines) do
	local y = 82 + (i - 1) * 44
	Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = Kit.A.sparkle, ImageColor3 = Color3.fromRGB(255, 216, 74),
		Position = UDim2.fromOffset(28, y + 4), Size = UDim2.fromOffset(28, 28), ZIndex = 8 }, wWin)
	Kit.text(wWin, 64, y + 1, WW - 92, 40, line, Kit.ps(16, 17), { ZIndex = 8, FontFace = Kit.FONT_BOLD, stroke = 1.3, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Center })
end
local okBtn, okInner = Kit.button(wWin, WW / 2 - 110, WH - 72, 220, 52, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
Kit.text(okInner, 0, Kit.ps(12, 10), 220, 30, "GOT IT", Kit.ps(22, 24), { ZIndex = okInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local wOpen = false
local function wPlace()
	local s = screenScale()
	local vp = viewport()
	local top = 124 * s
	local room = (if vp.Y < 500 then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.95), room / (WH + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (WW + 40))
	wHolder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + (if vp.Y < 500 then 0 else 15 * want))
	return want
end
local function wCloseFn()
	if not wOpen then return end
	wOpen = false
	Kit.sound("close")
	Kit.tween(wScale, { Scale = wScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not wOpen then wHolder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("W", false) end
	task.spawn(function() request:InvokeServer("Settings", { seenVersion = WN.version }) end)
end
local function wOpenFn()
	if wOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("W") end
	wOpen = true
	Kit.sound("open")
	wHolder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("W", true) end
	local want = wPlace()
	wScale.Scale = want * 0.8
	Kit.tween(wScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyWhatsNewClose = wCloseFn
WM.register("W", wHolder, wCloseFn)
wClose.MouseButton1Click:Connect(wCloseFn)
okBtn.MouseButton1Click:Connect(wCloseFn)
-- (opens once per version: after the tutorial, when no window / cutscene is up; the server marks a brand-new player as seen)
local function tutorialDone(): boolean return (player:GetAttribute("TutStep") or 0) >= #Econ.Tutorial end
local function calm(): boolean return not WM.anyOpen() and shared.GalaxyCinematic ~= true end
task.spawn(function()
	task.wait(5)
	-- (Studio: TestWhatsNew = true opens it again)
	local force = RunService:IsStudio() and workspace:GetAttribute("TestWhatsNew") == true
	while force or (player:GetAttribute("SeenVersion") or 0) < WN.version do
		if tutorialDone() and calm() then
			wOpenFn()
			return
		end
		task.wait(2)
	end
end)

------------------------------------------------------------------------ FAVOURITE (once, right after the first Supernova)
local AvatarEditorService = game:GetService("AvatarEditorService")
local favPending = false
local lastNovas = player:GetAttribute("Supernovas") or 0
player:GetAttributeChangedSignal("Supernovas"):Connect(function()
	local n = player:GetAttribute("Supernovas") or 0
	if lastNovas == 0 and n >= 1 and player:GetAttribute("FavAsked") ~= true and not favPending then
		favPending = true
		task.spawn(function()
			-- (after the Supernova's moment: no cutscene, no window)
			task.wait(3)
			while not calm() do task.wait(1) end
			task.wait(1.5)
			pcall(function() AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true) end)
		end)
	end
	lastNovas = n
end)
AvatarEditorService.PromptSetFavoriteCompleted:Connect(function()
	-- (any answer counts: it never asks again)
	request:InvokeServer("Settings", { favAsked = true })
end)

------------------------------------------------------------------------ NOTIFICATIONS (once, after the 3rd session)
task.spawn(function()
	if (player:GetAttribute("Sessions") or 0) < 3 or player:GetAttribute("NotifAsked") == true then return end
	local ENS = game:GetService("ExperienceNotificationService")
	-- (90 s into the session, after the tutorial, when nothing else is up)
	task.wait(90)
	while not (tutorialDone() and calm()) do task.wait(3) end
	local ok, can = pcall(function() return ENS:CanPromptOptInAsync() end)
	if not ok then return end
	if not can then
		-- (already opted in, or not allowed for this account: never ask)
		request:InvokeServer("Settings", { notifAsked = true })
		return
	end
	ENS.OptInPromptClosed:Once(function()
		request:InvokeServer("Settings", { notifAsked = true })
	end)
	pcall(function() ENS:PromptOptIn() end)
end)
