-- MB_HUD (client): the phone-first HUD, built ONLY from UIKit (COUNTER / BUTTON / TILE). Values come from player attributes.
-- SIZE + EXP + CARRYING (top-left) · NEXT bar + toasts (top-centre) · minimap + quest (top-right) · STORE (left) · DART + ability (bottom-right)
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
local TL = corner("TopLeft", Vector2.new(0, 0), UDim2.fromOffset(10, 6), UDim2.fromOffset(200, 170))
local TC = corner("TopCentre", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 6), UDim2.fromOffset(330, 200))
local TR = corner("TopRight", Vector2.new(1, 0), UDim2.new(1, -10, 0, 6), UDim2.fromOffset(130, 130))
local LM = corner("LeftMid", Vector2.new(0, 0), UDim2.fromOffset(10, 6), UDim2.fromOffset(110, 260))
local BR = corner("BottomRight", Vector2.new(1, 1), UDim2.new(1, -14, 1, -12), UDim2.fromOffset(150, 250))

------------------------------------------------------------ COUNTERS
local sizeC = K.Counter(TL, {name = "Size", icon = "Size", label = "SIZE", value = "0.1 m", accent = "Turquoise", pos = UDim2.fromOffset(18, 4)})
local expC = K.Counter(TL, {name = "Exp", icon = "Exp", label = "EXP", value = "0", accent = "Gold", pos = UDim2.fromOffset(18, 62)})
local carryC = K.Counter(TL, {name = "Carry", icon = "Carry", label = "CARRYING", value = "0 / 30", accent = "Kelp", pos = UDim2.fromOffset(18, 120)})

------------------------------------------------------------ NEXT bar (a COUNTER plate with a bar inside)
local nextShell, nextFace = K.Plate(TC, UDim2.fromOffset(310, 50), UDim2.new(0.5, 0, 0, 0), {name = "Next", edge = Col.Kelp, anchor = Vector2.new(0.5, 0)})
local nextLabel = K.Text(nextFace, {Text = "NEXT: PIRANHA", TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.fromOffset(12, 3)})
local nextPct = K.Text(nextFace, {Text = "0%", TextSize = 17, TextColor3 = Col.Kelp, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -72, 0, 3)})
local track = K.new("Frame", {Name = "Track", Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 1, -19), BackgroundColor3 = Col.Ink, BorderSizePixel = 0}, nextFace)
K.corner(track, 7)
local fill = K.new("Frame", {Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Col.Kelp, BorderSizePixel = 0}, track)
K.corner(fill, 7)
K.new("UIGradient", {Color = ColorSequence.new(Col.Turquoise, Col.Kelp)}, fill)
local fillShine = K.new("Frame", {Size = UDim2.new(1, -6, 0, 3), Position = UDim2.fromOffset(3, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.5, BorderSizePixel = 0}, fill)
K.corner(fillShine, 2)

------------------------------------------------------------ TOASTS
local toastHolder = K.new("Frame", {Name = "Toasts", Size = UDim2.fromOffset(310, 60), Position = UDim2.new(0.5, 0, 0, 128), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1}, TC)
local toastQ, toastBusy = {}, false
local function runToast()
	if toastBusy or #toastQ == 0 then return end
	toastBusy = true
	local item = table.remove(toastQ, 1)
	local accent = Col[item.colour or "Turquoise"] or Col.Turquoise
	local shell, face = K.Plate(toastHolder, UDim2.fromOffset(290, 42), UDim2.new(0.5, 0, 0, 0), {edge = accent, anchor = Vector2.new(0.5, 0)})
	local t = K.Text(face, {Text = item.text, TextSize = 18, TextColor3 = Col.Foam, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(6, 0), TextWrapped = true})
	local sc = K.new("UIScale", {Scale = 0.6}, shell)
	TS:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	Sounds.Play("UIPop")
	task.delay(item.hold or 2.6, function()
		local tw = TS:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.01})
		tw:Play(); tw.Completed:Wait()
		shell:Destroy()
		toastBusy = false
		runToast()
	end)
end
Bus.ToastEvent.Event:Connect(function(text, colour, hold)
	for i = #toastQ, 1, -1 do if toastQ[i].colour == colour then table.remove(toastQ, i) end end
	if #toastQ >= 2 then table.remove(toastQ, 1) end
	table.insert(toastQ, {text = text, colour = colour, hold = hold}); runToast()
end)

------------------------------------------------------------ MINIMAP (TILE) + QUEST panel
local mapTile = K.Tile(TR, {name = "Minimap", size = 118, pos = UDim2.new(1, 0, 0, 0), anchor = Vector2.new(1, 0), accent = "Turquoise", radius = 20})
local canvas = K.new("CanvasGroup", {Name = "Map", Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Col.NavyLight, BorderSizePixel = 0}, mapTile.face)
K.corner(canvas, 14)
local MAP_RANGE = 190   -- studs from the centre to the edge
local mapPx = 52
local function ringFrame(colour, th, transp)
	local f = K.new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1}, canvas)
	K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, f)
	local s = K.stroke(f, colour, th); s.Transparency = transp or 0
	return f
end
local reefRing = ringFrame(Col.Turquoise, 2, 0.25)
local borderRing = ringFrame(Col.Danger, 3, 0)
local ventDots = {}
for i in ipairs(C.Map.Vents) do
	local d = K.new("Frame", {Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Col.Kelp}, canvas)
	K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, d); K.stroke(d, Col.Ink, 2)
	ventDots[i] = d
end
local me = K.new("Frame", {Name = "Me", Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4}, canvas)
local body = K.new("Frame", {Size = UDim2.fromOffset(11, 11), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.58), Rotation = 45, BackgroundColor3 = Col.Gold, ZIndex = 4}, me)
K.stroke(body, Col.Ink, 2)
local noseDot = K.new("Frame", {Size = UDim2.fromOffset(7, 7), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.12), BackgroundColor3 = Col.Foam, ZIndex = 4}, me)
K.new("UICorner", {CornerRadius = UDim.new(1, 0)}, noseDot); K.stroke(noseDot, Col.Ink, 1.5)
local north = K.Text(canvas, {Text = "N", TextSize = 17, TextColor3 = Col.Gold, Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5})

local questShell, questFace = K.Plate(TC, UDim2.fromOffset(262, 58), UDim2.new(0.5, 18, 0, 58), {name = "Quest", edge = Col.Gold, anchor = Vector2.new(0.5, 0)})
K.Icon(questShell, "Quest", UDim2.fromOffset(62, 62), UDim2.new(0, 4, 0.5, 0))
K.Text(questFace, {Text = "QUEST", TextSize = 17, TextColor3 = Col.Gold, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -90, 0, 15), Position = UDim2.fromOffset(40, 3), InkThickness = 1.5})
local questDist = K.Text(questFace, {Text = "", TextSize = 17, TextColor3 = Col.Kelp, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 70, 0, 15), Position = UDim2.new(1, -78, 0, 3), InkThickness = 1.5})
local questText = K.Text(questFace, {Text = "", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Size = UDim2.new(1, -46, 0, 34), Position = UDim2.fromOffset(40, 19)})

------------------------------------------------------------ STORE (BUTTON, gold = rewards/shop)
local store = K.Button(LM, {name = "Store", icon = "Store", text = "STORE", color = "Gold", width = 92, height = 74, pos = UDim2.fromOffset(18, 184), iconScale = 0.6})
store.root.Activated:Connect(function()
	Sounds.Play("UIOpen")
	local shop = lp.PlayerGui:FindFirstChild("MB_Shop")
	local req = shop and shop:FindFirstChild("OpenRequest")
	if req then req:Fire() end
end)

------------------------------------------------------------ DART + ability (BUTTON family, bottom-right; DART is the biggest thing on the right)
local dart = K.Button(BR, {name = "Dart", icon = "Dart", text = "DART", state = "READY", color = "Turquoise", width = 126, height = 118,
	pos = UDim2.new(1, 0, 1, 0), anchor = Vector2.new(1, 1), radius = 28, iconScale = 0.58, textSize = 22})
local ability = K.Button(BR, {name = "Ability", icon = "Lock", text = "FRENZY", state = "AT PIRANHA", color = "Coral", width = 100, height = 92,
	pos = UDim2.new(1, -13, 1, -134), anchor = Vector2.new(1, 1), radius = 24, iconScale = 0.55, textSize = 17})
dart.root.Activated:Connect(function() Bus.Dart:Fire() end)
ability.root.Activated:Connect(function() Bus.Ability:Fire() end)
local abilityReady = 0
Bus.Ability.Event:Connect(function()
	local e = lp:GetAttribute("Evo") or 1
	if e < 2 then Sounds.Play("UIError"); Bus.Toast("FRENZY unlocks when you become a PIRANHA", "Locked"); return end
	if os.clock() < abilityReady then Sounds.Play("UIError"); return end
	abilityReady = os.clock() + 8
	Action:FireServer("Ability")
end)

------------------------------------------------------------ binding
local function fmtNum(n)
	n = math.floor(n + 0.5)
	local s = tostring(n)
	while true do local k; s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2"); if k == 0 then break end end
	return s
end
local shownExp = 0
local function refresh()
	local e = lp:GetAttribute("Evo") or 1
	local evo = C.Evolutions[e]
	local exp = lp:GetAttribute("EXP") or 0
	sizeC.value.Text = string.format(evo.size < 10 and "%.1f m" or "%.0f m", evo.size)
	local carry, cmax = lp:GetAttribute("Carry") or 0, lp:GetAttribute("CarryMax") or 30
	carryC.value.Text = carry .. " / " .. cmax
	local nxt = C.Evolutions[e + 1]
	if nxt then
		local p = math.clamp((exp - evo.exp) / (nxt.exp - evo.exp), 0, 1)
		nextLabel.Text = "NEXT: " .. string.upper(nxt.name)
		nextPct.Text = math.floor(p * 100) .. "%"
		TS:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(math.max(p, 0.04), 1)}):Play()
	else
		nextLabel.Text = "APEX: MEGALODON"; nextPct.Text = "MAX"; fill.Size = UDim2.fromScale(1, 1)
	end
	-- ability button
	if e < 2 then
		ability:SetColor(Col.Locked); ability.icon.Image = K.Icons.Lock; ability.label.Text = "FRENZY"; ability.state.Text = "AT PIRANHA"
	else
		local ab = evo.ability
		ability:SetColor(Col[C.AbilityColor[ab]] or Col.Coral)
		ability.icon.Image = K.Icons[K.AbilityIcon[ab]] or ""
		ability.label.Text = ab; ability.label.TextSize = #ab > 8 and 15 or 18
		ability.state.Text = "READY"
	end
	-- quest
	local q = C.Quests[lp:GetAttribute("QuestIndex") or 1]
	questShell.Visible = q ~= nil
	if q then questText.Text = q.text end
end
for _, a in ipairs({"Evo", "EXP", "Carry", "CarryMax", "QuestIndex"}) do lp:GetAttributeChangedSignal(a):Connect(refresh) end
lp:GetAttributeChangedSignal("EXP"):Connect(function()
	local new = lp:GetAttribute("EXP") or 0
	if new > shownExp then
		local sc = expC.root:FindFirstChild("Pop") or K.new("UIScale", {Name = "Pop"}, expC.root)
		sc.Scale = 1.15; TS:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
	end
	local from = shownExp
	task.spawn(function()   -- count up
		for i = 1, 12 do shownExp = from + (new - from) * i / 12; expC.value.Text = fmtNum(shownExp); task.wait(0.025) end
	end)
end)
lp:GetAttributeChangedSignal("Evo"):Connect(function()
	local evo = C.Evolutions[lp:GetAttribute("Evo") or 1]
	Bus.Toast("You are a " .. string.upper(evo.name) .. "!", "Gold")
end)
refresh()

------------------------------------------------------------ per-frame: cooldowns, minimap, quest distance, zones
local inReef = true
local questSent = false
task.delay(1.5, function() Bus.Toast("Welcome to the SAFE REEF!", "Turquoise", 3) end)
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local st = Bus.State
	-- DART cooldown
	local left = st.dartReadyAt - now
	if left > 0 then
		dart.veil.Size = UDim2.fromScale(1, math.clamp(left / st.dartCooldown, 0, 1))
		dart.state.Text = string.format("%.1fs", left)
	else
		dart.veil.Size = UDim2.fromScale(1, 0); dart.state.Text = "READY"
	end
	local al = abilityReady - now
	if (lp:GetAttribute("Evo") or 1) >= 2 then
		ability.veil.Size = UDim2.fromScale(1, al > 0 and math.clamp(al / 8, 0, 1) or 0)
		ability.state.Text = al > 0 and string.format("%.1fs", al) or "READY"
	end
	-- minimap (camera-up)
	local pos = st.pos
	local yaw = st.camYaw
	local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
	local fwd = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local k = (canvas.AbsoluteSize.X * 0.5) / MAP_RANGE
	local w = canvas.AbsoluteSize.X / (canvas:FindFirstAncestorWhichIsA("Frame") and 1 or 1)
	local function toMap(p)
		local rel = Vector3.new(p.X - pos.X, 0, p.Z - pos.Z)
		return UDim2.new(0.5, rel:Dot(right) * k, 0.5, -rel:Dot(fwd) * k)
	end
	local centre = C.Swim.MapCentre
	reefRing.Position = toMap(centre); reefRing.Size = UDim2.fromOffset(C.Zones.SafeReefRadius * 2 * k, C.Zones.SafeReefRadius * 2 * k)
	borderRing.Position = toMap(centre); borderRing.Size = UDim2.fromOffset(C.Swim.BorderHard * 2 * k, C.Swim.BorderHard * 2 * k)
	for i, v in ipairs(C.Map.Vents) do ventDots[i].Position = toMap(v) end
	me.Rotation = -math.deg(st.heading - yaw)
	-- N marker on the rim
	local nDir = Vector3.new(0, 0, -1)
	local nx, ny = nDir:Dot(right), -nDir:Dot(fwd)
	north.Position = UDim2.new(0.5, nx * canvas.AbsoluteSize.X * 0.42, 0.5, ny * canvas.AbsoluteSize.Y * 0.42)
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
	end
	-- zones
	local r = Vector3.new(pos.X - centre.X, 0, pos.Z - centre.Z).Magnitude
	local nowReef = r < C.Zones.SafeReefRadius
	if nowReef ~= inReef and pos.Magnitude > 0 then
		inReef = nowReef
		if nowReef then Bus.Toast("Back in the SAFE REEF", "Turquoise") else Bus.Toast("OPEN SEA:  x2 EXP, watch out!", "Coral") end
	end
	carryC.root.Visible = true
	carryC.face.UIStroke.Color = inReef and Col.Locked or Col.Kelp
	carryC.label.TextColor3 = inReef and Col.Locked or Col.Kelp
end)
