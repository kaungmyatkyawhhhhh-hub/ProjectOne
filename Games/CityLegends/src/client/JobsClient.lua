--[[
	JobsClient (see server/Jobs.lua; owner approved 18 Nov 2026: jobs with ranks and paychecks)
	  * the Job Center screen (E at the kiosk on Myanmar Plaza's forecourt, or tap the job bar):
	    every job with your rank in it, TAKE / QUIT
	  * the job bar under the level bar: job, rank title, progress to the next rank, the next
	    paycheck (it ticks only while you're on duty)
	  * the target of an active job (bus stop, fare, patrol point) or your post: a ring on the
	    ground, the minimap waypoint; stopping in the ring reports it (the server checks and pays)
	Same look as the other screens (UI.kit, the GOALS screen's panel and rows).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local JobRules = require(Shared:WaitForChild("JobRules"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local Activities = require(script.Parent:WaitForChild("Activities"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))

local JobsClient = {}

local J = Config.Jobs
local Theme = Config.Theme
local kit = UI.kit
local new, label, button, corner, stroke, tween = kit.new, kit.label, kit.button, kit.corner, kit.stroke, kit.tween
local GOLD = Theme.Accent2
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local call: RemoteFunction? = nil
local state: { [string]: any } = {}
local stateAt = 0
local bar: TextButton? = nil
local barLeft: TextLabel? = nil
local barRight: TextLabel? = nil
local barFill: Frame? = nil
local screen: Frame? = nil
local ring: BasePart? = nil
local ringLabel: TextLabel? = nil
local targetKey = ""
local myWaypoint = false
local held = 0
local asking = false

local function invoke(what: string, arg: any?): any
	if not call then
		return nil
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	return if ok then res else nil
end

local function clock(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

---------------------------------------------------------------------
-- The job bar (under the level bar: the same pill, gold fill)
---------------------------------------------------------------------
local function buildBar()
	local hud = UI.screen():FindFirstChild("HUD")
	if not hud then
		return
	end
	local w = if UI.isTouch then 250 else 360
	local h = if UI.isTouch then 22 else 24
	local b: TextButton = new("TextButton", {
		Name = "JobBar",
		AutoButtonColor = false,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if UI.isTouch then 54 else 60),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.18,
		ClipsDescendants = true,
		Visible = false,
		Parent = hud:FindFirstChild("TopBars") or hud, -- (19 Nov: with the level bar, hidden on a phone while driving)
	}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(GOLD, 1, 0.55) })
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BackgroundTransparency = 0.78, BorderSizePixel = 0, Parent = b })
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 214, 110), GOLD), Parent = fill })
	barFill = fill
	local size = if UI.isTouch then 10 else 12
	barLeft = label({ Text = "", TextSize = size, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.62, -12, 1, 0), Parent = b })
	barRight = label({ Text = "", TextSize = size, Font = Enum.Font.GothamBold, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.38, -4, 1, 0), Parent = b })
	b.Activated:Connect(function()
		Audio.click()
		JobsClient.open()
	end)
	bar = b
end

local function refreshBar()
	local b, l, r, f = bar, barLeft, barRight, barFill
	if not (b and l and r and f) then
		return
	end
	local job = JobRules.byId(J, state.job)
	b.Visible = job ~= nil
	if not job then
		return
	end
	l.Text = string.upper(job.name) .. " · " .. string.upper(state.title or "") .. "  R" .. tostring(state.rank or 1) .. "/5"
	local k = if (state.span or 0) > 0 then math.clamp((state.into or 0) / state.span, 0, 1) else 1
	tween(f, 0.3, { Size = UDim2.fromScale(k, 1) })
	if not state.onDuty then
		local why = if job.kind == "post" then (if (state.postLeft or 1) <= 0 then "Shift done today" else "Go to your post") else "Off duty: drive the job"
		r.Text = why
		r.TextColor3 = Theme.SubText
	else
		local left = (state.payIn or 0) - (os.clock() - stateAt)
		r.Text = UI.formatCash(state.paycheck or 0) .. " in " .. clock(left)
		r.TextColor3 = Theme.Money
	end
end

---------------------------------------------------------------------
-- The target ring (stop / fare / patrol point / post) and the minimap waypoint
---------------------------------------------------------------------
local function target(): (Vector3?, string?)
	local job = JobRules.byId(J, state.job)
	if not job then
		return nil, nil
	end
	if job.kind == "post" then
		return job.post, string.upper(job.name) .. " · stand here"
	end
	local t = state.task
	if type(t) == "table" and typeof(t.pos) == "Vector3" then
		local what = if t.kind == "stop" then "BUS STOP" elseif t.kind == "pickup" then "PICK UP" elseif t.kind == "fare" then "DROP OFF" else "PATROL · stop for radar"
		return t.pos, what .. " · " .. tostring(t.name)
	end
	-- delivery: the nearest dispatch ring until a run starts (then Activities shows the drop)
	if job.id == "delivery" and not Activities.getTarget() then
		local root = Driving.getRoot()
		local here = if root then root.Position else camera.CFrame.Position
		local best, bestD = nil, math.huge
		for _, d in ActivityData.dispatch do
			local dd = (d.pos - here).Magnitude
			if dd < bestD then
				best, bestD = d, dd
			end
		end
		if best then
			return best.pos, "DELIVERY · stop in the blue ring"
		end
	end
	return nil, nil
end

local function refreshTarget()
	local pos, text = target()
	local key = if pos then tostring(pos) else ""
	if key == targetKey then
		return
	end
	targetKey = key
	held = 0
	if not pos then
		if ring then
			ring.Transparency = 1
		end
		if ringLabel then
			ringLabel.Text = ""
		end
		if myWaypoint then
			myWaypoint = false
			Minimap.setWaypoint(nil)
		end
		return
	end
	local p = ring
	if not p then
		p = Instance.new("Part")
		p.Name = "JobTarget"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		p.Color = GOLD
		p.Parent = workspace
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(260, 40)
		bb.StudsOffset = Vector3.new(0, 9, 0)
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.Parent = p
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.GothamBlack
		t.TextSize = 20
		t.TextColor3 = GOLD
		t.TextStrokeTransparency = 0.3
		t.Parent = bb
		ring, ringLabel = p, t
	end
	local job = JobRules.byId(J, state.job)
	local d = if job and job.kind == "post" then J.PostRadius * 2 else J.ArriveRadius * 1.4
	p.Size = Vector3.new(0.3, d, d)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Transparency = 0.6
	if ringLabel then
		ringLabel.Text = text or ""
	end
	myWaypoint = true
	Minimap.setWaypoint(pos)
end

local function setState(st: any)
	if type(st) ~= "table" then
		return
	end
	state = st
	stateAt = os.clock()
	refreshBar()
	refreshTarget()
end

-- stopped in the ring: report it (police hold still RadarSeconds: the radar check)
local function update(dt: number)
	local t = state.task
	local root = Driving.getRoot()
	if asking or type(t) ~= "table" or typeof(t.pos) ~= "Vector3" or not root or not Driving.isDriving() then
		held = 0
		return
	end
	local d = Vector3.new(root.Position.X - t.pos.X, 0, root.Position.Z - t.pos.Z).Magnitude
	if d > J.ArriveRadius * 0.85 or Driving.getSpeed() > J.StopSps * 0.8 then
		held = 0
		return
	end
	held += dt
	if held < (if t.kind == "patrol" then J.RadarSeconds else 0.5) then
		return
	end
	held = 0
	asking = true
	task.spawn(function()
		local res = invoke("arrive")
		if type(res) == "table" and res.ok then
			if (res.cash or 0) > 0 then
				UI.popup(tostring(res.what), res.cash, Theme.Money)
				Audio.cutUp(3, "JOB")
			else
				UI.popup(tostring(res.what), 0, GOLD)
				Audio.play("tick", 0.7, 1.2)
			end
		end
		task.wait(1)
		asking = false
	end)
end

---------------------------------------------------------------------
-- The Job Center screen (the GOALS screen's panel, rows and buttons)
---------------------------------------------------------------------
local function closeScreen()
	if screen then
		screen:Destroy()
		screen = nil
	end
end

local function fill()
	local f = screen and screen:FindFirstChild("Panel")
	local body = f and f:FindFirstChild("Body")
	if not (f and body) then
		return
	end
	body:ClearAllChildren()
	local sub = f:FindFirstChild("Sub") :: TextLabel?
	if sub then
		sub.Text = if state.double then "DOUBLE PAY ON: x2 ALL JOB PAY" else "PAYCHECK EVERY MINUTE ON DUTY · 5 RANKS PER JOB"
		sub.TextColor3 = if state.double then GOLD else Theme.SubText
	end
	local list = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 73,
		Parent = body,
	})
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local order = 0
	local function heading(text: string)
		order += 1
		label({ Text = text, TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -8, 0, 18), LayoutOrder = order, ZIndex = 74, Parent = list })
	end
	local function row(job: any)
		order += 1
		local mine = state.job == job.id
		local r = (state.ranks and state.ranks[job.id]) or 1
		local f2 = new("Frame", {
			Size = UDim2.new(1, -8, 0, 62),
			BackgroundColor3 = if mine then GOLD:Lerp(Theme.PanelLight, 0.85) else Theme.PanelLight,
			BackgroundTransparency = 0.1,
			LayoutOrder = order,
			ZIndex = 73,
			Parent = list,
		}, { corner(10), stroke(if mine then GOLD else Theme.Stroke, 1, if mine then 0.2 else 0.4) })
		label({ Text = string.upper(job.name) .. "   ·   " .. job.ranks[r] .. "  R" .. r .. "/5", TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -130, 0, 18), ZIndex = 74, Parent = f2 })
		label({ Text = job.where, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -130, 0, 15), ZIndex = 74, Parent = f2 })
		local pay = UI.formatCash(JobRules.paycheck(J, job, r, state.double)) .. " a minute"
		pay ..= if job.kind == "post" then " at the post" else " + pay per " .. (if job.id == "bus" then "stop" elseif job.id == "taxi" then "fare" elseif job.id == "police" then "patrol / ticket" else "delivery")
		label({ Text = pay, TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 41), Size = UDim2.new(1, -130, 0, 15), ZIndex = 74, Parent = f2 })
		local b = button(if mine then "QUIT" else "TAKE", if mine then Theme.Danger else Theme.Money, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(104, 44),
			TextSize = 16,
			TextColor3 = if mine then Theme.Danger else Theme.Money,
			ZIndex = 74,
			Parent = f2,
		})
		b.Activated:Connect(function()
			local res = invoke(if mine then "quit" else "take", job.id)
			if type(res) == "table" and res.ok then
				setState(res.state)
				if not mine then
					UI.toast(string.upper(job.name) .. ": you're a " .. job.ranks[r] .. (if job.kind == "post" then ". Go to the gold ring" else ". Follow the gold ring"), GOLD)
					closeScreen()
					return
				end
				fill()
			else
				UI.toast(if type(res) == "table" and res.message then res.message else "Try again", Theme.Warning)
			end
		end)
	end
	heading("ACTIVE JOBS · PAID PER TASK, PLUS A PAYCHECK")
	for _, job in J.List do
		if job.kind == "active" then
			row(job)
		end
	end
	heading("POSTS · STAND AT YOUR POST · " .. math.floor((state.postLeft or J.PostCapSeconds) / 60) .. " MIN PAID TIME LEFT TODAY")
	for _, job in J.List do
		if job.kind == "post" then
			row(job)
		end
	end
end

function JobsClient.open()
	if screen then
		closeScreen()
		return
	end
	local root = UI.screen()
	local back = new("Frame", { Name = "JobCenter", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = root })
	screen = back
	local w, h = 560, 470
	local f = new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		ZIndex = 71,
		Parent = back,
	}, { corner(14), stroke(Theme.Stroke, 1.5, 0.1) })
	local sc = new("UIScale", { Parent = f })
	local vp = camera.ViewportSize
	sc.Scale = math.min(1, (vp.X - 24) / w, (vp.Y - 24) / h)
	label({ Text = "JOB CENTER", TextSize = 26, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -90, 0, 30), ZIndex = 72, Parent = f })
	label({ Name = "Sub", Text = "", TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -90, 0, 16), ZIndex = 72, Parent = f })
	local x = button("×", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44), TextSize = 20, ZIndex = 72, Parent = f })
	x.Activated:Connect(closeScreen)
	new("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 74), Size = UDim2.new(1, -40, 1, -90), ZIndex = 72, Parent = f })
	fill()
	task.spawn(function()
		local st = invoke("state")
		if type(st) == "table" and screen == back then
			setState(st)
			fill()
		end
	end)
end

function JobsClient.init()
	if not (J.On and Config.activeMap() == "Yangon") then
		return
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("JobCall", 30) :: RemoteFunction?
	local push = remotes:WaitForChild("JobPush", 30) :: RemoteEvent?
	buildBar()
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) ~= "table" then
				return
			end
			if msg.kind == "state" then
				setState(msg.state)
			elseif msg.kind == "open" then
				if not screen then
					JobsClient.open()
				end
			elseif msg.kind == "paid" then
				UI.popup(if msg.double then "PAYCHECK x2" else "PAYCHECK", tonumber(msg.cash) or 0, Theme.Money)
				Audio.cutUp(4, "PAY")
			elseif msg.kind == "promoted" then
				UI.popup("PROMOTED: " .. string.upper(tostring(msg.title)), 0, GOLD)
				UI.toast(tostring(msg.job) .. " rank " .. tostring(msg.rank) .. ": paycheck now " .. UI.formatCash(tonumber(msg.paycheck) or 0), GOLD)
				Audio.cutUp(8, "goal")
			elseif msg.kind == "task" then
				UI.popup(tostring(msg.what), tonumber(msg.cash) or 0, Theme.Money)
				UI.toast(tostring(msg.name), GOLD)
			elseif msg.kind == "ticketed" then
				UI.toast("Officer " .. tostring(msg.by) .. " clocked you at " .. tostring(msg.kmh) .. " km/h (limit " .. tostring(msg.limit) .. ")", Theme.Warning)
			end
		end)
	end
	setState(invoke("state"))
	RunService.Heartbeat:Connect(update)
	-- the paycheck countdown ticks between server updates
	task.spawn(function()
		while true do
			task.wait(1)
			refreshBar()
			refreshTarget()
		end
	end)
end

return JobsClient
