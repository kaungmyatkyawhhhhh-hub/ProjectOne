-- MB_HUD v3 "FREE OCEAN" (11 Nov 2026). Owner as a player: the boxed HUD "feels like a trap, not freedom".
-- Rule now: THE OCEAN IS THE GAME. At rest the screen is almost empty; the HUD speaks only when it has news, then gets out of the way.
--  * no dark boxes: icons + numbers float over the water (thick ink outline keeps them readable)
--  * top-left: SIZE + EXP readout; under it the NEXT bar + CARRYING fade IN when they change and fade OUT after a few seconds
--  * top-right: a small round minimap; the quest is a quiet chip under it (its text slides out only when it's new)
--  * STORE + INDEX: a small quiet pair of bubbles; the store never shouts
--  * DART is the one hero button; abilities stay hidden until you earn them, then arrive as a celebration
--  * toasts = floating words, mostly rewards and discoveries, never orders
-- Backup of the boxed v2 HUD: ServerStorage.MB_HUD_v2_boxed_backup
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService")
local lp = Players.LocalPlayer
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local K = require(MB:WaitForChild("UIKit"))
local Bus = require(MB:WaitForChild("ClientBus"))
local Action = MB:WaitForChild("Remotes"):WaitForChild("SwimAction")
local Sounds = require(RS:WaitForChild("MB_Sounds"))
local Col = K.Colors

local gui = K.new("ScreenGui", {Name = "MB_HUD", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets}, lp:WaitForChild("PlayerGui"))

local function corner(name, anchor, pos, size)
	local f = K.new("Frame", {Name = name, AnchorPoint = anchor, Position = pos, Size = size, BackgroundTransparency = 1}, gui)
	K.AttachScale(f)
	return f
end
local TL = corner("TopLeft", Vector2.new(0, 0), UDim2.fromOffset(12, 6), UDim2.fromOffset(300, 150))
local TC = corner("TopCentre", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6), UDim2.fromOffset(360, 60))
local TR = corner("TopRight", Vector2.new(1, 0), UDim2.new(1, -12, 0, 6), UDim2.fromOffset(300, 140))
local LM = corner("LeftMid", Vector2.new(0, 0), UDim2.fromOffset(12, 6), UDim2.fromOffset(150, 160))
local BR = corner("BottomRight", Vector2.new(1, 1), UDim2.new(1, -16, 1, -14), UDim2.fromOffset(150, 230))

-- floating text: no plate, a thick ink outline does the work
local function ftext(parent, props)
	props.InkThickness = props.InkThickness or 3
	return K.Text(parent, props)
end
-- a group that fades in/out as one (CanvasGroup), starting hidden
local function fadeGroup(parent, name, size, pos)
	local g = K.new("CanvasGroup", {Name = name, Size = size, Position = pos, BackgroundTransparency = 1, GroupTransparency = 1, Visible = false}, parent)
	local st = {g = g, shownUntil = 0, on = false}
	function st:show(secs, sticky)
		if sticky then self.shownUntil = math.huge
		elseif self.shownUntil ~= math.huge then self.shownUntil = math.max(self.shownUntil, os.clock() + (secs or 3)) end
		if not self.on then
			self.on = true; g.Visible = true
			TS:Create(g, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {GroupTransparency = 0}):Play()
		end
	end
	function st:hide()
		self.shownUntil = 0
		if self.on then
			self.on = false
			local tw = TS:Create(g, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {GroupTransparency = 1}); tw:Play()
			tw.Completed:Connect(function() if not self.on then g.Visible = false end end)
		end
	end
	function st:tick(now) if self.on and now > self.shownUntil then self:hide() end end
	return st
end

------------------------------------------------------------ TOP-LEFT: SIZE + EXP readout (always), NEXT + CARRYING (when they change)
local sizeIcon = K.Icon(TL, "Size", UDim2.fromOffset(46, 46), UDim2.fromOffset(22, 24))
local sizeT = ftext(TL, {Name = "Size", Text = "0.1 m", TextSize = 27, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(96, 30), Position = UDim2.fromOffset(48, 9)})
local expIcon = K.Icon(TL, "Exp", UDim2.fromOffset(40, 40), UDim2.fromOffset(166, 24))
local expT = ftext(TL, {Name = "Exp", Text = "0", TextSize = 27, TextColor3 = Col.Gold, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(110, 30), Position = UDim2.fromOffset(190, 9)})
local expPop = K.new("UIScale", {}, expT)
local sizePop = K.new("UIScale", {}, sizeT)

local nextG = fadeGroup(TL, "Next", UDim2.fromOffset(250, 36), UDim2.fromOffset(4, 50))
local nextLabel = ftext(nextG.g, {Text = "NEXT: PIRANHA", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(2, 0), InkThickness = 2.5})
local nextPct = ftext(nextG.g, {Text = "0%", TextSize = 15, TextColor3 = Col.Kelp, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 48, 0, 16), Position = UDim2.new(1, -50, 0, 0), InkThickness = 2.5})
local track = K.new("Frame", {Name = "Track", Size = UDim2.new(1, -4, 0, 9), Position = UDim2.fromOffset(2, 21), BackgroundColor3 = Col.Ink, BackgroundTransparency = 0.35, BorderSizePixel = 0}, nextG.g)
K.corner(track, 5)
local fill = K.new("Frame", {Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Col.Kelp, BorderSizePixel = 0}, track)
K.corner(fill, 5)
K.new("UIGradient", {Color = ColorSequence.new(Col.Turquoise, Col.Kelp)}, fill)

local carryG = fadeGroup(TL, "Carry", UDim2.fromOffset(170, 34), UDim2.fromOffset(4, 88))
K.Icon(carryG.g, "Carry", UDim2.fromOffset(34, 34), UDim2.fromOffset(17, 17))
local carryPulse = K.new("UIScale", {}, carryG.g)
local carryT = ftext(carryG.g, {Text = "0/30", TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(70, 26), Position = UDim2.fromOffset(38, 4)})
local carryHint = ftext(carryG.g, {Text = "FULL", TextSize = 16, TextColor3 = Col.Gold, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(60, 20), Position = UDim2.fromOffset(104, 7), InkThickness = 2.5, Visible = false})

------------------------------------------------------------ TOASTS: floating words at the top centre (rewards + discoveries)
local toastHolder = K.new("Frame", {Name = "Toasts", Size = UDim2.fromOffset(360, 40), Position = UDim2.new(0.5, 0, 0, 6), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1}, TC)
-- rules kept from the UX research: one at a time, short, fit to one line (no TextScaled), same text within 4 s dropped,
-- waiting > 3 s = stale, nothing under a centre pop, danger cuts in.
local toastQ, toastBusy, toastToken, curToast = {}, false, 0, nil
local runToast
local function endToast(my, fast)
	if my ~= toastToken or not curToast then return end
	local t, stroke = curToast.t, curToast.stroke
	curToast = nil
	local d = fast and 0.08 or 0.3
	TS:Create(t, TweenInfo.new(d), {TextTransparency = 1, Position = t.Position - UDim2.fromOffset(0, 8)}):Play()
	TS:Create(stroke, TweenInfo.new(d), {Transparency = 1}):Play()
	task.delay(d, function()
		t:Destroy()
		if my == toastToken then toastBusy = false; runToast() end
	end)
end
runToast = function()
	if toastBusy then return end
	while #toastQ > 0 and os.clock() - (toastQ[1].t or 0) > 3 do table.remove(toastQ, 1) end
	if #toastQ == 0 then return end
	local pu = (Bus.State.popUntil or 0) - os.clock()
	if pu > 0 and toastQ[1].colour ~= "Danger" then task.delay(pu + 0.05, runToast); return end
	toastBusy = true
	toastToken += 1
	local my = toastToken
	local item = table.remove(toastQ, 1)
	local colour = item.colour == "Locked" and Col.Foam or (Col[item.colour or "Foam"] or Col.Foam)
	local t = ftext(toastHolder, {Text = item.text, TextSize = 25, TextColor3 = colour, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 10), TextTransparency = 1})
	while not t.TextFits and t.TextSize > 15 do t.TextSize -= 1 end
	local stroke = t:FindFirstChildOfClass("UIStroke"); stroke.Transparency = 1
	TS:Create(t, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextTransparency = 0, Position = UDim2.fromOffset(0, 0)}):Play()
	TS:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
	if item.colour == "Gold" or item.colour == "Kelp" then Sounds.Play("UIPop") end   -- rewards chime; info stays quiet
	curToast = {t = t, stroke = stroke, item = item}
	task.delay(math.clamp(item.hold or 2.2, 1.5, 2.6), function() endToast(my, false) end)
end
local lastToast = {}
Bus.ToastEvent.Event:Connect(function(text, colour, hold)
	local now = os.clock()
	if lastToast[text] and now - lastToast[text] < 4 then return end
	lastToast[text] = now
	for i = #toastQ, 1, -1 do if toastQ[i].colour == colour then table.remove(toastQ, i) end end
	local item = {text = text, colour = colour, hold = hold, t = now}
	if colour == "Danger" then
		table.insert(toastQ, 1, item)
		if curToast and curToast.item.colour ~= "Danger" then endToast(toastToken, true) else runToast() end
		return
	end
	if #toastQ >= 2 then table.remove(toastQ, 1) end
	table.insert(toastQ, item); runToast()
end)

------------------------------------------------------------ TOP-RIGHT: small round minimap + a quiet quest chip under it
local MAPD = 92
local mapRim = K.new("Frame", {Name = "Minimap", Size = UDim2.fromOffset(MAPD, MAPD), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = Col.Navy, BackgroundTransparency = 0.35, BorderSizePixel = 0}, TR)
K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, mapRim)
local rimStroke = K.stroke(mapRim, Col.Foam, 2.5); rimStroke.Transparency = 0.25
local canvas = K.new("CanvasGroup", {Name = "Map", Size = UDim2.new(1, -6, 1, -6), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 1, BorderSizePixel = 0}, mapRim)
K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, canvas)
local MAP_RANGE = 190   -- studs from the centre to the edge
local function ringFrame(colour, th, transp)
	local f = K.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1}, canvas)
	K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, f)
	local s = K.stroke(f, colour, th); s.Transparency = transp or 0
	return f
end
local reefRing = ringFrame(Col.Turquoise, 2, 0.2)
local borderRing = ringFrame(Col.Danger, 2.5, 0.15)
local ventDots = {}
for i in ipairs(C.Map.Vents) do
	local d = K.new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Col.Kelp}, canvas)
	K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, d); K.stroke(d, Col.Ink, 1.5)
	ventDots[i] = d
end
local me = K.new("Frame", {Name = "Me", Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4}, canvas)
local body = K.new("Frame", {Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Rotation = 45, BackgroundColor3 = Col.Gold, ZIndex = 4}, me)
K.stroke(body, Col.Ink, 2)
local noseDot = K.new("Frame", {Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.12), BackgroundColor3 = Col.Foam, ZIndex = 4}, me)
K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, noseDot); K.stroke(noseDot, Col.Ink, 1.5)
local north = ftext(mapRim, {Text = "N", TextSize = 15, TextColor3 = Col.Gold, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5, InkThickness = 2.5})

-- quest chip: the scroll + the distance; the full text slides out to the left only when the quest is new (or on tap)
local questBtn = K.new("TextButton", {Name = "Quest", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(92, 40),
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, MAPD + 6)}, TR)
K.Icon(questBtn, "Quest", UDim2.fromOffset(38, 38), UDim2.fromOffset(20, 20))
local questDist = ftext(questBtn, {Text = "", TextSize = 18, TextColor3 = Col.Foam, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(56, 22), Position = UDim2.fromOffset(38, 9), InkThickness = 2.5})
local questG = fadeGroup(TR, "QuestText", UDim2.fromOffset(200, 44), UDim2.new(1, -296, 0, MAPD + 4))
local questText = ftext(questG.g, {Text = "", TextSize = 17, TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = true, Size = UDim2.fromScale(1, 1), InkThickness = 2.5})
questBtn.Activated:Connect(function() Sounds.Play("UIClick"); questG:show(4) end)

------------------------------------------------------------ STORE + INDEX: a small, quiet pair of bubbles (same blue base: nothing shouts)
local store = K.Button(LM, {name = "Store", icon = "Store", text = "STORE", color = "Blue", width = 60, height = 56, pos = UDim2.fromOffset(2, 128), iconScale = 0.66, textSize = 14})
store.root.Activated:Connect(function() Sounds.Play("UIOpen"); Bus.StoreOpen:Fire() end)
local FISH = C.Fish
local indexBtn = K.Button(LM, {name = "Index", icon = "Index", text = "INDEX", color = "Blue", width = 60, height = 56, pos = UDim2.fromOffset(72, 128), iconScale = 0.6, textSize = 14})
indexBtn.root.Activated:Connect(function() Sounds.Play("UIOpen"); Bus.IndexOpen:Fire() end)
-- red badge only for new fish you haven't looked at yet
local seenN = 0
local badge = K.new("ImageLabel", {Name = "Badge", BackgroundTransparency = 1, Image = K.Art and K.Art.Badge and K.Art.Badge.id or "", Size = UDim2.fromOffset(24, 24),
	Position = UDim2.new(1, -6, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 9, Visible = false}, indexBtn.root)
local badgeT = ftext(badge, {Text = "1", TextSize = 14, ZIndex = 10, InkThickness = 2})
local function updIndex()
	local idx = lp:GetAttribute("Index") or ""
	local n = idx == "" and 0 or #string.split(idx, ",")
	badge.Visible = n > seenN; badgeT.Text = tostring(n - seenN)
end
Bus.IndexOpen.Event:Connect(function() local idx = lp:GetAttribute("Index") or ""; seenN = idx == "" and 0 or #string.split(idx, ","); badge.Visible = false end)
lp:GetAttributeChangedSignal("Index"):Connect(updIndex); updIndex()

------------------------------------------------------------ DART (the one hero button) + the ability (hidden until earned)
local dart = K.Button(BR, {name = "Dart", icon = "Dart", text = "DART", color = "Turquoise", width = 112, height = 106,
	pos = UDim2.new(1, 0, 1, 0), anchor = Vector2.new(1, 1), iconScale = 0.6, textSize = 21})
local ability = K.Button(BR, {name = "Ability", icon = "Frenzy", text = "FRENZY", color = "Coral", width = 84, height = 78,
	pos = UDim2.new(1, -116, 1, -6), anchor = Vector2.new(1, 1), iconScale = 0.6, textSize = 16})
ability.root.Visible = false
-- cooldown seconds sit big in the middle of the bubble, only while recharging
local function cdLabel(b, size) return ftext(b.root, {Name = "CD", Text = "", TextSize = size, Size = UDim2.new(1, 0, 0, size + 4), Position = UDim2.new(0, 0, 0.4, -size / 2), ZIndex = 9}) end
local dartCD, abilityCD = cdLabel(dart, 30), cdLabel(ability, 24)
local abilityScale = K.new("UIScale", {}, ability.root)
dart.root.Activated:Connect(function() Bus.Dart:Fire() end)
ability.root.Activated:Connect(function() Bus.Ability:Fire() end)
local abilityReady = 0
Bus.Ability.Event:Connect(function()
	local e = lp:GetAttribute("Evo") or 1
	if e < 2 then return end   -- (keyboard F before unlocking: just nothing)
	if os.clock() < abilityReady then Sounds.Play("UIError"); return end
	abilityReady = os.clock() + 8
	Action:FireServer("Ability")
end)

------------------------------------------------------------ binding
local function fmtNum(n)
	n = math.floor(n + 0.5)
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) elseif n >= 1e4 then return string.format("%.1fK", n / 1e3) end
	local s = tostring(n)
	while true do local k; s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2"); if k == 0 then break end end
	return s
end
local function bump(sc, big) sc.Scale = big and 1.25 or 1.14; TS:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back), {Scale = 1}):Play() end
local shownExp = lp:GetAttribute("EXP") or 0
local lastCarry, lastQuest, lastSize = lp:GetAttribute("Carry") or 0, nil, nil
local function refresh()
	local e = lp:GetAttribute("Evo") or 1
	local evo = C.Evolutions[e]
	local exp = lp:GetAttribute("EXP") or 0
	local sz = evo.size * (lp:GetAttribute("SizeMult") or 1)
	local szText = string.format(sz < 10 and "%.1f m" or "%.0f m", sz)
	if lastSize and szText ~= lastSize then bump(sizePop, true) end
	lastSize = szText; sizeT.Text = szText
	-- CARRYING: shows when it changes, stays while the bag is full
	local carry, cmax = lp:GetAttribute("Carry") or 0, lp:GetAttribute("CarryMax") or 30
	carryT.Text = carry .. "/" .. cmax
	local full = carry >= cmax
	carryT.TextColor3 = full and Col.Gold or Col.Foam
	carryHint.Visible = full
	if carry ~= lastCarry then
		if carry > 0 then carryG:show(3, full) else carryG:hide() end
		lastCarry = carry
	end
	-- NEXT: shows when EXP moves; stays up when you are close (the last 20%) so the big moment is anticipated
	local nxt = C.Evolutions[e + 1]
	if nxt then
		local p = math.clamp((exp - evo.exp) / (nxt.exp - evo.exp), 0, 1)
		nextLabel.Text = "NEXT: " .. string.upper(nxt.name)
		nextPct.Text = math.floor(p * 100) .. "%"
		TS:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(math.max(p, 0.03), 1)}):Play()
		if p >= 0.8 then nextG:show(3, true) elseif nextG.shownUntil == math.huge then nextG:hide() end
	else
		nextLabel.Text = "APEX: MEGALODON"; nextPct.Text = "MAX"; fill.Size = UDim2.fromScale(1, 1)
	end
	-- ability: hidden until earned
	if e >= 2 then
		local ab = evo.ability
		ability:SetColor(Col[C.AbilityColor[ab]] or Col.Coral)
		ability.icon.Image = K.Icons[K.AbilityIcon[ab]] or ""
		ability.label.Text = ab; ability.label.TextSize = #ab > 8 and 13 or 16
		if not ability.root.Visible then
			ability.root.Visible = true
			abilityScale.Scale = 0.2
			TS:Create(abilityScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
		end
	else
		ability.root.Visible = false
	end
	-- quest: the chip stays; the words slide out only when the quest is new
	local qi = lp:GetAttribute("QuestIndex") or 1
	local q = C.Quests[qi]
	questBtn.Visible = q ~= nil
	if q then
		questText.Text = q.text
		if qi ~= lastQuest then questG:show(6) end
	else
		questG:hide()
	end
	lastQuest = qi
end
for _, a in ipairs({"Evo", "EXP", "Carry", "CarryMax", "QuestIndex", "SizeMult"}) do lp:GetAttributeChangedSignal(a):Connect(refresh) end
lp:GetAttributeChangedSignal("EXP"):Connect(function()
	local new = lp:GetAttribute("EXP") or 0
	if new > shownExp then bump(expPop, new - shownExp >= 50); nextG:show(3) end
	local from = shownExp
	task.spawn(function()   -- count up (fast for small gains, longer for big ones)
		local steps = (new - from) >= 50 and 24 or 10
		for i = 1, steps do shownExp = from + (new - from) * i / steps; expT.Text = fmtNum(shownExp); task.wait(0.025) end
	end)
end)
expT.Text = fmtNum(shownExp)
local lastEvo = lp:GetAttribute("Evo") or 1
lp:GetAttributeChangedSignal("Evo"):Connect(function()
	local e = lp:GetAttribute("Evo") or 1
	local up = e > lastEvo; lastEvo = e
	if not up then return end   -- spawning / resetting is not an evolution
	local evo = C.Evolutions[e]
	Bus.Toast("You are a " .. string.upper(evo.name) .. "!", "Gold")
	if e == 2 and evo.ability then task.delay(2.8, function() Sounds.Play("SizeUp"); Bus.Toast("NEW ABILITY: " .. evo.ability .. "!", "Gold") end) end
end)
refresh()

------------------------------------------------------------ per-frame: cooldowns, fades, minimap, quest distance, zones
local inReef = true
local questSent = false
local lastPopSeen = nil
task.delay(1.5, function() Bus.Toast("Welcome to the SAFE REEF!", "Turquoise", 2.6) end)
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local st = Bus.State
	toastHolder.Visible = now > (st.popUntil or 0)
	if st.popUntil and st.popUntil ~= lastPopSeen then
		lastPopSeen = st.popUntil
		for i = #toastQ, 1, -1 do if toastQ[i].colour ~= "Danger" then table.remove(toastQ, i) end end
	end
	nextG:tick(now); carryG:tick(now); questG:tick(now)
	-- DART: the number only while it recharges (no permanent READY label)
	local left = st.dartReadyAt - now
	if left > 0 then
		dart.veil.Size = UDim2.fromScale(1, math.clamp(left / st.dartCooldown, 0, 1))
		dartCD.Text = string.format("%.1f", left)
	else
		dart.veil.Size = UDim2.fromScale(1, 0); dartCD.Text = ""
	end
	if ability.root.Visible then
		local al = abilityReady - now
		ability.veil.Size = UDim2.fromScale(1, al > 0 and math.clamp(al / 8, 0, 1) or 0)
		abilityCD.Text = al > 0 and tostring(math.ceil(al)) or ""
	end
	-- minimap (camera-up)
	local pos = st.pos
	local yaw = st.camYaw
	local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
	local fwd = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local k = ((MAPD - 6) * 0.5) / MAP_RANGE   -- design px (the UIScale scales offsets itself)
	local function toMap(p)
		local rel = Vector3.new(p.X - pos.X, 0, p.Z - pos.Z)
		return UDim2.new(0.5, rel:Dot(right) * k, 0.5, -rel:Dot(fwd) * k)
	end
	local centre = C.Swim.MapCentre
	reefRing.Position = toMap(centre); reefRing.Size = UDim2.fromOffset(C.Zones.SafeReefRadius * 2 * k, C.Zones.SafeReefRadius * 2 * k)
	borderRing.Position = toMap(centre); borderRing.Size = UDim2.fromOffset(C.Swim.BorderHard * 2 * k, C.Swim.BorderHard * 2 * k)
	for i, v in ipairs(C.Map.Vents) do ventDots[i].Position = toMap(v) end
	me.Rotation = -math.deg(st.heading - yaw)
	local nDir = Vector3.new(0, 0, -1)
	local nx, ny = nDir:Dot(right), -nDir:Dot(fwd)
	north.Position = UDim2.new(0.5, nx * MAPD * 0.4, 0.5, ny * MAPD * 0.4)
	-- quest distance
	local qi = lp:GetAttribute("QuestIndex") or 1
	local q = C.Quests[qi]
	if q and q.target == "vent" then
		local best = math.huge
		for _, v in ipairs(C.Map.Vents) do best = math.min(best, (pos - v).Magnitude) end
		questDist.Text = math.floor(best / C.StudsPerMetre + 0.5) .. " m"
		if best < q.radius and not questSent then
			questSent = true
			Action:FireServer("Quest")
			Sounds.Play("BankDing")
			Bus.Toast("QUEST DONE!  +" .. q.reward .. " EXP", "Gold")
			task.delay(1, function() questSent = false end)
		end
	else
		questDist.Text = ""
	end
	-- zones: a calm word, not a warning
	local r = Vector3.new(pos.X - centre.X, 0, pos.Z - centre.Z).Magnitude
	local nowReef = inReef
	if r < C.Zones.SafeReefRadius - 8 then nowReef = true elseif r > C.Zones.SafeReefRadius + 8 then nowReef = false end
	if nowReef ~= inReef and pos.Magnitude > 0 then
		inReef = nowReef
		for i = #toastQ, 1, -1 do local tx = toastQ[i].text; if tx:find("OPEN SEA", 1, true) or tx:find("SAFE REEF", 1, true) then table.remove(toastQ, i) end end
		if nowReef then Bus.Toast("SAFE REEF", "Turquoise", 1.8) else Bus.Toast("OPEN SEA  ·  x2 EXP", "Turquoise", 2) end
	end
	-- full bag: a gentle 1 Hz pulse so it reads without colour
	carryPulse.Scale = carryHint.Visible and (1 + 0.05 * math.sin(now * 6.28)) or 1
end)

-- windows (Fish Index / Store) hide the touch buttons, like Roblox's TouchControlsEnabled = false
Bus.WindowChanged.Event:Connect(function(name)
	BR.Visible = name == nil
	LM.Visible = name == nil
end)
