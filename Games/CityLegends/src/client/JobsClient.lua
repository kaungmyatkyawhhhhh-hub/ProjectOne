--[[
	JobsClient (see server/Jobs.lua; owner approved 18 Nov 2026: jobs with ranks and paychecks)
	  * (19 Nov) the job list is the main menu's JOBS tab (E at the kiosk, the job bar or the HUD's
	    JOBS icon open it); this module gives it the state and the calls
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
local refreshAsk: () -> () = function() end -- (the shift card, below)
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
		local why = if job.kind == "post" then (if state.asleep then "Off duty: keep working?" else "Go to your post") else "Off duty: drive the job"
		r.Text = why
		r.TextColor3 = Theme.SubText
	else
		local left = (state.payIn or 0) - (os.clock() - stateAt)
		r.Text = "ON DUTY · " .. UI.formatCash(state.paycheck or 0) .. " in " .. clock(left)
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
	refreshAsk()
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
-- (19 Nov, owner: jobs like Southwest Florida) the job list is the main menu's JOBS tab now
-- (MainMenu buildJobs); the old JOB CENTER screen is gone. The kiosk, the job bar and the HUD's
-- JOBS icon open that tab through UI.onJobsButton (set in Main.client)
---------------------------------------------------------------------
function JobsClient.open()
	if UI.onJobsButton then
		UI.onJobsButton()
	end
end

function JobsClient.getState(): { [string]: any }
	return state
end

-- a JobCall from the JOBS tab (take / quit / vehicle / keep); its new state goes on the bar too
function JobsClient.call(what: string, arg: any?): any
	local res = invoke(what, arg)
	if type(res) == "table" and res.state then
		setState(res.state)
	end
	return res
end

-- "Still on shift?" under the job bar: the AFK post check (no tap in JobsData.ShiftAnswer: off duty)
local askCard: Frame? = nil
refreshAsk = function()
	local show = state.ask == true or state.asleep == true
	if not show then
		if askCard then
			askCard.Visible = false
		end
		return
	end
	local card = askCard
	if not card then
		local hud = UI.screen():FindFirstChild("HUD")
		if not hud then
			return
		end
		local c: Frame = new("Frame", {
			Name = "JobShiftCheck",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, if UI.isTouch then 82 else 92),
			Size = UDim2.fromOffset(if UI.isTouch then 250 else 300, 44),
			BackgroundColor3 = Theme.Panel,
			BackgroundTransparency = 0.08,
			ZIndex = 20,
			Parent = hud,
		}, { corner(12), stroke(GOLD, 1, 0.4) })
		label({ Name = "Q", Text = "", TextSize = 13, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -140, 1, 0), ZIndex = 21, Parent = c })
		local b = button("KEEP WORKING", Theme.Money, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(124, 34), TextSize = 13, TextColor3 = Theme.Money, ZIndex = 21, Parent = c })
		b.Activated:Connect(function()
			Audio.click()
			JobsClient.call("keep")
		end)
		askCard, card = c, c
	end
	local f = card :: Frame
	f.Visible = true
	local q = f:FindFirstChild("Q") :: TextLabel
	q.Text = if state.asleep then "OFF DUTY · STILL ON SHIFT?" else "STILL ON SHIFT?"
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
				JobsClient.open()
			elseif msg.kind == "toast" then
				UI.toast(tostring(msg.text), GOLD)
			elseif msg.kind == "stillthere" then
				UI.toast("Still on shift? Tap KEEP WORKING within " .. math.floor((tonumber(msg.seconds) or 300) / 60) .. " min, or you go off duty", GOLD)
				Audio.play("tick", 0.7, 1.2)
			elseif msg.kind == "offshift" then
				UI.toast("Off duty: no answer. Tap KEEP WORKING to start again", Theme.Warning)
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
	-- (21 Nov, "make the loading screen load fast") asked in the background: this round trip held the start 0.4-0.8 s
	task.spawn(function()
		setState(invoke("state"))
	end)
	RunService.Heartbeat:Connect(update)
	-- (19 Nov) Roblox kicks after 20 idle minutes: a player on duty at a post is rejoined first (the
	-- server decides and teleports; not officially approved by Roblox: watch moderation)
	player.Idled:Connect(function(seconds: number)
		local job = JobRules.byId(J, state.job)
		if job and job.kind == "post" and state.onDuty then
			invoke("idle", seconds)
		end
	end)
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
