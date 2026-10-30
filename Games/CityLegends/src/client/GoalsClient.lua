--[[
	GoalsClient (see server/Goals.lua; owner, 2026-10-30, from the driving games research)
	  * the Legends Path tracker on the HUD: the next goal, how far you are, what it pays (tap it
	    for the full list)
	  * the GOALS screen (the GOALS side button): PATH (every goal), DAILY (today's 3 tasks and
	    when new ones come), STREAK (the 7 days, CLAIM)
	  * a popup and a sound when a goal or task is done
	Same look as the other screens (UI.kit).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local GoalsClient = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local kit = UI.kit
local new, label, button, corner, stroke, tween = kit.new, kit.label, kit.button, kit.corner, kit.stroke, kit.tween

local GOLD = Theme.Accent2
local call: RemoteFunction? = nil
local state: { [string]: any }? = nil
local stateAt = 0 -- os.clock() when the state came (for the countdowns)

local tracker: TextButton? = nil
local trackerTitle: TextLabel? = nil
local trackerText: TextLabel? = nil
local trackerFill: Frame? = nil
local trackerSub: TextLabel? = nil

local screen: Frame? = nil
local screenTab = "path"
local refreshScreen: (() -> ())? = nil

local function clock(secs: number): string
	secs = math.max(0, math.floor(secs))
	local h = math.floor(secs / 3600)
	local m = math.floor(secs % 3600 / 60)
	local s = secs % 60
	return if h > 0 then string.format("%d:%02d:%02d", h, m, s) else string.format("%d:%02d", m, s)
end

local function count(have: number, need: number): string
	local function n(x: number): string
		return if x == math.floor(x) then tostring(x) else string.format("%.1f", x)
	end
	return n(have) .. " / " .. n(need)
end

local function invoke(what: string): any
	if not call then
		return nil
	end
	local ok, result = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what)
	end)
	return if ok then result else nil
end

---------------------------------------------------------------------
-- The HUD tracker (under the minimap; on a phone under the streak card)
---------------------------------------------------------------------
local function placeTracker()
	local t = tracker
	if not t then
		return
	end
	local map = player.PlayerGui:FindFirstChild("Minimap")
	local bottom = if map then map:GetAttribute("Bottom") else nil
	local top = (if type(bottom) == "number" then bottom else 190) + 10
	if UI.isTouch then
		top += 78 -- (the streak card sits right under the minimap on a phone)
	end
	t.Position = UDim2.new(1, -14, 0, top)
end

local function buildTracker()
	local hud = UI.screen():FindFirstChild("HUD")
	if not hud then
		return
	end
	local w = if UI.isTouch then 196 else 248
	local h = if UI.isTouch then 54 else 64
	local t: TextButton = new("TextButton", {
		Name = "GoalTracker",
		AutoButtonColor = false,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.12,
		Parent = hud,
	}, { corner(12), stroke(GOLD, 1.2, 0.45) })
	tracker = t
	trackerTitle = label({ Text = "LEGENDS PATH", TextSize = if UI.isTouch then 10 else 11, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 13), Parent = t })
	trackerText = label({ Text = "", TextSize = if UI.isTouch then 12 else 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, if UI.isTouch then 19 else 21), Size = UDim2.new(1, -24, 0, 17), Parent = t })
	local back = new("Frame", { Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(0.5, -12, 0, 4), BackgroundColor3 = Theme.Stroke, BorderSizePixel = 0, Parent = t }, { corner(2) })
	trackerFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = back }, { corner(2) })
	trackerSub = label({ Text = "", TextSize = if UI.isTouch then 10 else 11, Font = Enum.Font.GothamBold, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -5), Size = UDim2.new(0.5, -8, 0, 13), Parent = t })
	t.Activated:Connect(function()
		Audio.click()
		GoalsClient.open("path")
	end)
	placeTracker()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(placeTracker)
	task.spawn(function()
		local map = player.PlayerGui:WaitForChild("Minimap", 60)
		if map then
			placeTracker()
			map:GetAttributeChangedSignal("Bottom"):Connect(placeTracker)
		end
	end)
end

local function refreshTracker()
	local st = state
	if not (tracker and st) then
		return
	end
	local nxt = st.next
	local title, text, fill, sub = trackerTitle :: TextLabel, trackerText :: TextLabel, trackerFill :: Frame, trackerSub :: TextLabel
	title.Text = string.format("LEGENDS PATH  %d/%d", st.done or 0, st.total or 0)
	if nxt then
		text.Text = nxt.text
		local k = if nxt.need > 0 then math.clamp(nxt.have / nxt.need, 0, 1) else 0
		tween(fill, 0.3, { Size = UDim2.fromScale(k, 1) })
		sub.Text = count(nxt.have, nxt.need) .. "   +" .. UI.formatCash(nxt.cash)
	else
		text.Text = "Every goal done: a true legend"
		fill.Size = UDim2.fromScale(1, 1)
		sub.Text = ""
	end
end

---------------------------------------------------------------------
-- The GOALS screen
---------------------------------------------------------------------
local function closeScreen()
	if screen then
		screen:Destroy()
		screen = nil
	end
	refreshScreen = nil
end

local function row(parent: Instance, y: number, h: number, done: boolean): Frame
	return new("Frame", {
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, -8, 0, h),
		BackgroundColor3 = if done then Theme.Background else Theme.PanelLight,
		BackgroundTransparency = if done then 0.4 else 0.1,
		ZIndex = 73,
		Parent = parent,
	}, { corner(10), stroke(if done then Theme.Money else Theme.Stroke, 1, if done then 0.55 else 0.4) })
end

local function bar(parent: Instance, k: number, color: Color3, props: { [string]: any })
	local back = new("Frame", props, { corner(3) })
	back.BackgroundColor3 = Theme.Stroke
	back.BorderSizePixel = 0
	back.ZIndex = 74
	back.Parent = parent
	new("Frame", { Size = UDim2.fromScale(math.clamp(k, 0, 1), 1), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 75, Parent = back }, { corner(3) })
end

local function buildPath(body: Frame)
	local st = state :: any
	local list = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Stroke,
		CanvasSize = UDim2.fromOffset(0, #st.path * 56),
		ZIndex = 72,
		Parent = body,
	})
	local firstOpen: number? = nil
	for i, g in st.path do
		local r = row(list, (i - 1) * 56, 50, g.done)
		local mark = label({ Text = if g.done then "✓" else tostring(i), TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = if g.done then Theme.Money else GOLD, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(30, 50), ZIndex = 74, Parent = r })
		mark.TextTransparency = 0
		label({ Text = g.text, TextSize = 14, Font = Enum.Font.GothamBold, TextColor3 = if g.done then Theme.SubText else Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(44, 7), Size = UDim2.new(1, -160, 0, 18), ZIndex = 74, Parent = r })
		if not g.done then
			bar(r, if g.need > 0 then g.have / g.need else 0, GOLD, { Position = UDim2.fromOffset(44, 32), Size = UDim2.new(1, -230, 0, 5) })
			label({ Text = count(g.have, g.need), TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -116, 0, 26), Size = UDim2.fromOffset(70, 16), ZIndex = 74, Parent = r })
			firstOpen = firstOpen or i
		end
		label({ Text = "+" .. UI.formatCash(g.cash), TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = if g.done then Theme.SubText else Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(100, 20), ZIndex = 74, Parent = r })
	end
	-- show the next goal near the top
	if firstOpen then
		list.CanvasPosition = Vector2.new(0, math.max(0, (firstOpen - 2) * 56))
	end
end

local function buildDaily(body: Frame)
	local st = state :: any
	local resetLabel = label({ Text = "", TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 18), ZIndex = 73, Parent = body })
	for i, t in st.tasks do
		local r = row(body, 26 + (i - 1) * 84, 76, t.done)
		label({ Text = t.text, TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = if t.done then Theme.SubText else Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -150, 0, 20), ZIndex = 74, Parent = r })
		bar(r, if t.need > 0 then t.have / t.need else 0, if t.done then Theme.Money else Theme.Accent, { Position = UDim2.fromOffset(16, 46), Size = UDim2.new(1, -170, 0, 7) })
		label({ Text = if t.done then "DONE" else count(t.have, t.need), TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = if t.done then Theme.Money else Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 40), Size = UDim2.fromOffset(90, 18), ZIndex = 74, Parent = r })
		label({ Text = "+" .. UI.formatCash(t.cash), TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = if t.done then Theme.SubText else Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12), Size = UDim2.fromOffset(110, 20), ZIndex = 74, Parent = r })
	end
	local function tick()
		resetLabel.Text = "NEW TASKS IN " .. clock((st.tasksIn or 0) - (os.clock() - stateAt))
	end
	tick()
	return tick
end

local function buildStreak(body: Frame)
	local st = state :: any
	local s = st.streak
	local w = (body.AbsoluteSize.X > 0 and body.AbsoluteSize.X or 480)
	local gap = 8
	local box = math.floor((w - gap * 6) / 7)
	for d = 1, 7 do
		local reward = s.rewards[d]
		local isNext = d == s.day
		local past = d < s.day
		local f = new("Frame", {
			Position = UDim2.fromOffset((d - 1) * (box + gap), 10),
			Size = UDim2.fromOffset(box, 120),
			BackgroundColor3 = if isNext then GOLD:Lerp(Theme.Panel, 0.78) else Theme.PanelLight,
			BackgroundTransparency = if past then 0.5 else 0.08,
			ZIndex = 73,
			Parent = body,
		}, { corner(10), stroke(if isNext then GOLD elseif past then Theme.Money else Theme.Stroke, if isNext then 2 else 1, if past then 0.5 else 0.2) })
		label({ Text = "DAY " .. d, TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = if isNext then GOLD else Theme.SubText, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 14), ZIndex = 74, Parent = f })
		local area = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 50), ZIndex = 74, Parent = f })
		kit.icon(if reward == "car" then "car" else "gift", area, math.min(40, box - 16), if past then Theme.Money elseif reward == "car" then GOLD else Theme.Text)
		label({ Text = if reward == "car" then "FREE CAR" else UI.formatCash(reward :: number), TextSize = if box < 60 then 10 else 12, Font = Enum.Font.GothamBlack, TextColor3 = if reward == "car" then GOLD else Theme.Money, Position = UDim2.new(0, 2, 1, -32), Size = UDim2.new(1, -4, 0, 16), TextScaled = box < 60, ZIndex = 74, Parent = f })
		if past then
			label({ Text = "✓", TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = Theme.Money, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(16, 16), ZIndex = 75, Parent = f })
		end
	end
	label({ Text = "Come back every day. Day 7 gives you a free Mid car you don't own yet.\nMiss more than 2 days and the streak starts again at day 1.", TextSize = 13, TextColor3 = Theme.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(0, 142), Size = UDim2.new(1, 0, 0, 40), ZIndex = 73, Parent = body })
	local claim = button("CLAIM", Theme.Money, { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 50), TextSize = 20, ZIndex = 74, Parent = body })
	local busy = false
	local function tick()
		local left = (s.readyIn or 0) - (os.clock() - stateAt)
		if busy then
			claim.Text = "..."
		elseif left > 0 then
			claim.Text = "DAY " .. s.day .. " READY IN " .. clock(left)
			claim.TextColor3 = Theme.SubText
		else
			claim.Text = "CLAIM DAY " .. s.day
			claim.TextColor3 = Theme.Money
		end
	end
	claim.Activated:Connect(function()
		if busy or (s.readyIn or 0) - (os.clock() - stateAt) > 0 then
			return
		end
		busy = true
		tick()
		GoalsClient.claimStreak()
		busy = false
	end)
	tick()
	return tick
end

function GoalsClient.open(tab: string?)
	if screen then
		closeScreen()
		if not tab then
			return
		end
	end
	if not state then
		local st = invoke("state")
		if type(st) == "table" then
			state = st
			stateAt = os.clock()
		else
			UI.toast("Goals are still loading: try again", Theme.Warning)
			return
		end
	end
	screenTab = tab or screenTab
	local root = UI.screen()
	local back = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = root })
	screen = back
	local w, h = 560, 470
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		ZIndex = 71,
		Parent = back,
	}, { corner(14), stroke(Theme.Stroke, 1.5, 0.1) })
	local sc = new("UIScale", { Parent = f })
	local function fit()
		local vp = camera.ViewportSize
		sc.Scale = math.min(1, (vp.X - 24) / w, (vp.Y - 24) / h)
	end
	fit()
	label({ Text = "GOALS", TextSize = 26, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -90, 0, 30), ZIndex = 72, Parent = f })
	local x = button("×", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44), TextSize = 20, ZIndex = 72, Parent = f })
	x.Activated:Connect(closeScreen)
	-- tabs
	local tabs = { { "path", "PATH" }, { "daily", "DAILY" }, { "streak", "STREAK" } }
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 110), Size = UDim2.new(1, -40, 1, -126), ZIndex = 72, Parent = f })
	local tabButtons: { [string]: TextButton } = {}
	local ticker: (() -> ())? = nil
	local function show(which: string)
		screenTab = which
		for id, b in tabButtons do
			b.TextColor3 = if id == which then GOLD else Theme.SubText
			b.BackgroundColor3 = if id == which then GOLD:Lerp(Theme.PanelLight, 0.82) else Theme.PanelLight
		end
		body:ClearAllChildren()
		ticker = nil
		local st = state :: any
		if which == "path" then
			buildPath(body)
		elseif which == "daily" then
			ticker = buildDaily(body)
		else
			ticker = buildStreak(body)
		end
		local sub = f:FindFirstChild("Sub") :: TextLabel?
		if sub then
			sub.Text = if which == "path" then string.format("LEGENDS PATH: %d OF %d DONE", st.done, st.total) elseif which == "daily" then "3 NEW TASKS EVERY DAY" else "DAILY STREAK"
		end
	end
	label({ Name = "Sub", Text = "", TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -90, 0, 16), ZIndex = 72, Parent = f })
	for i, t in tabs do
		local b = button(t[2], GOLD, { Position = UDim2.new((i - 1) / 3, 20 - (i - 1) * 13.3, 0, 62), Size = UDim2.new(1 / 3, -26.6, 0, 40), TextSize = 15, ZIndex = 72, Parent = f })
		tabButtons[t[1]] = b
		b.Activated:Connect(function()
			show(t[1])
		end)
	end
	refreshScreen = function()
		show(screenTab)
	end
	show(screenTab)
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if not back.Parent then
			conn:Disconnect()
			return
		end
		if ticker then
			ticker()
		end
	end)
end

---------------------------------------------------------------------
-- The streak (also claimed from the streak card on the HUD: Main.client's UI.onDailyClaim)
---------------------------------------------------------------------
function GoalsClient.claimStreak()
	if UI.onDailyClaim then
		UI.onDailyClaim()
	end
end

-- the streak card and the GOALS dot follow the state
local function applyStreak()
	local st = state
	if not st then
		return
	end
	local s = st.streak
	local reward = s.rewards[s.day]
	UI.setStreak(s.day, if reward == "car" then "FREE CAR" else UI.formatCash(reward), (s.readyIn or 0) - (os.clock() - stateAt))
end

local function setState(st: any)
	local before = state
	state = st
	stateAt = os.clock()
	refreshTracker()
	applyStreak()
	-- (the open list is rebuilt only when something in it changed: no jumping while you scroll)
	if refreshScreen and screen then
		local changed = not before or before.done ~= st.done or screenTab ~= "path"
		if changed then
			refreshScreen()
		end
	end
end

function GoalsClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("GoalsCall", 30) :: RemoteFunction?
	local push = remotes:WaitForChild("GoalsPush", 30) :: RemoteEvent?
	buildTracker()
	UI.onGoalsButton = function()
		GoalsClient.open(nil)
	end
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) ~= "table" then
				return
			end
			if msg.kind == "state" and type(msg.state) == "table" then
				setState(msg.state)
			elseif msg.kind == "done" then
				local what = if msg.what == "task" then "DAILY TASK DONE" else "GOAL DONE"
				UI.popup(what, tonumber(msg.cash) or 0, GOLD)
				UI.toast(tostring(msg.text), GOLD)
				Audio.cutUp(8, "goal")
			end
		end)
	end
	task.spawn(function()
		local st = invoke("state")
		if type(st) == "table" then
			setState(st)
		end
	end)
	-- a race / delivery / duel card takes the tracker's spot under the minimap while it shows
	task.spawn(function()
		while true do
			task.wait(0.4)
			local t = tracker
			local hudGui = player.PlayerGui:FindFirstChild("ActivitiesHUD")
			local card = hudGui and hudGui:FindFirstChild("RunCard")
			if t then
				t.Visible = not (card and (card :: Frame).Visible)
			end
		end
	end)
end

return GoalsClient
