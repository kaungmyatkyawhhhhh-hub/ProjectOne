--[[
	Guide (client; owner approved 24 Nov 2026: "the first 5 minutes for new players"; vault
	"City Legends/2026-11-24 First 5 minutes for new players.md"; server/Guide.lua keeps the step)
	Runs only while the player attribute "Guide" is set (a new save). One hint pill at a time, in the
	StartPrompt's style (UI kit: panel, accent outline, pulsing accent badge) at the top middle under the
	level / job bars (the road and the car stay clear), never over a menu, a screen, the start-up
	prompt, a popup or a toast:
	  1  the menu's own "Pick your first car" does the talking (no pill)
	  2  car out -> the Delivery job is taken for you (JobsClient then shows the dispatch label, the
	     beam and the minimap blip); pill: "Drive to the green beam ..." with an arrow that turns
	     toward the dispatch, "Stop next to the DELIVERY sign ..." when close
	  3  a run started (Activities) -> "Deliver the parcel to <drop> ...", the beam on the drop
	  4  paid -> after the pay popups: "Next goal: <the next Legends Path goal> · +$X" (tap: GOALS)
	The X on the pill skips the whole guide (saved). Kid-sim numbers: tools/kidsim_first5.py.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Activities = require(script.Parent:WaitForChild("Activities"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local MainMenu = require(script.Parent:WaitForChild("MainMenu")) :: any
local GoalsClient = require(script.Parent:WaitForChild("GoalsClient")) :: any

local player = Players.LocalPlayer
local Theme = Config.Theme
local kit = UI.kit

local Guide = {}

local DONE = 99
local NEAR = 90 -- studs: "stop here" instead of "drive to"
local GOAL_SECONDS = 12 -- the next-goal pill stays this long (or until tapped / closed)

local call: RemoteFunction? = nil
local pill: Frame? = nil
local pillText: TextLabel
local arrow: Frame
local goalMark: Frame
local badge: Frame
local tapArea: TextButton
local onTap: (() -> ())? = nil
local topSlot = UDim2.new()

local function ask(what: string, arg: any?): any
	if not call then
		return nil
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	return if ok then res else nil
end

local function step(): number
	return tonumber(player:GetAttribute("Guide")) or DONE
end

-- the pill (built once)
local function build()
	local new, label, corner, stroke = kit.new, kit.label, kit.corner, kit.stroke
	local touch = UI.isTouch
	local h = if touch then 40 else 50
	topSlot = UDim2.new(0.5, 0, 0, if touch then 134 else 150)
	local f = new("Frame", {
		Name = "GuideHint",
		AnchorPoint = Vector2.new(0.5, 0),
		-- (first test: in the StartPrompt's slot it hid the road, the dispatch sign and met the toasts)
		Position = topSlot,
		Size = UDim2.fromOffset(if touch then 470 else 560, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.12,
		Visible = false,
		Parent = UI.screen(),
	}, { corner(12), stroke(Theme.Accent, 1.5, 0.15) })
	badge = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(h - 14, h - 14),
		BackgroundColor3 = Theme.Accent,
		Parent = f,
	}, { corner(8) })
	-- the arrow: a chevron in the kit icons' way (rounded bars), turned toward the target
	arrow = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Parent = badge })
	local s = h - 14
	for _, side in { -1, 1 } do
		new("Frame", {
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, side * s * 0.167, 0.5, s * 0.07), -- (the two tops meet at the point)
			Size = UDim2.fromOffset(s * 0.17, s * 0.52),
			Rotation = -side * 40, -- (a ^: each bar's top leans in)
			Parent = arrow,
		}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	goalMark = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = badge })
	kit.icon("flag", goalMark, s - 8, Theme.Panel) -- (the GOALS button's icon)
	pillText = label({
		Text = "",
		TextSize = if touch then 16 else 19,
		TextScaled = true, -- (a long drop name: smaller, never cut)
		TextWrapped = false, -- (one line: wrapped it went to two small lines)
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(h + 2, 0),
		Size = UDim2.new(1, -(h + 2) - 40, 1, 0),
		Parent = f,
	}, { new("UITextSizeConstraint", { MaxTextSize = if touch then 16 else 19, MinTextSize = 10 }) })
	tapArea = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -38, 1, 0), Parent = f })
	tapArea.Activated:Connect(function()
		if onTap then
			onTap()
		end
	end)
	-- X (red = close): skips the whole guide
	local x = new("TextButton", {
		Name = "Skip",
		Text = "",
		AutoButtonColor = true,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Theme.Danger,
		Parent = f,
	}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	for _, r in { 45, -45 } do
		new("Frame", { BackgroundColor3 = Theme.Text, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(13, 3), Rotation = r, Parent = x }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	x.Activated:Connect(function()
		f.Visible = false
		player:SetAttribute("GuideSkipped", true) -- (hides it at once; the server's answer clears "Guide")
		task.spawn(function()
			for _ = 1, 5 do
				if ask("skip") ~= nil then
					break
				end
				task.wait(0.5)
			end
		end)
	end)
	pill = f
end

-- nothing over a menu, a screen, the start-up prompt or while walking
local function blocked(): boolean
	local screen = UI.screen()
	local hud = screen and screen:FindFirstChild("HUD")
	return not Driving.isDriving()
		or (MainMenu.isOpen and MainMenu.isOpen())
		or UI.isGarageOpen()
		or (hud ~= nil and hud:FindFirstChild("StartPrompt") ~= nil)
		or UI.messageShowing()
end

local function show(text: string, target: Vector3?, tap: (() -> ())?, low: boolean?)
	if not pill then
		build()
	end
	-- (third test: close to the dispatch the top slot hid the DELIVERY sign it talks about: when you are
	-- stopping there, the pill drops to the start-up prompt's slot over the bottom buttons)
	local pp = pill :: Frame
	pp.AnchorPoint = if low then Vector2.new(0.5, 1) else Vector2.new(0.5, 0)
	pp.Position = if low then UDim2.new(0.5, 0, 0.66, 0) else topSlot
	pillText.Text = text
	onTap = tap
	arrow.Visible = target ~= nil
	goalMark.Visible = target == nil
	local cam = Workspace.CurrentCamera
	if target and cam then
		-- (0 = straight ahead, turning as the target goes round the camera)
		local v = cam.CFrame:VectorToObjectSpace(target - cam.CFrame.Position)
		arrow.Rotation = math.deg(math.atan2(v.X, -v.Z))
	end
	badge.BackgroundTransparency = 0.25 - 0.25 * math.cos(os.clock() * 4) -- (the StartPrompt's pulse)
	local p = pill :: Frame
	p.Visible = player:GetAttribute("GuideSkipped") ~= true and not blocked()
end

local function hide()
	if pill then
		pill.Visible = false
	end
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function nearestDispatch(from: Vector3): Vector3?
	local best, bestD = nil, math.huge
	for _, d in ActivityData.dispatch do
		local dd = flat(d.pos, from)
		if dd < bestD then
			best, bestD = d.pos, dd
		end
	end
	return best
end

-- the drop of the delivery run on now (Activities' target is a race checkpoint in a race)
local function dropName(pos: Vector3?): string?
	if pos then
		for _, p in ActivityData.dropPoints do
			if flat(p.pos, pos) < 1 then
				return p.name
			end
		end
	end
	return nil
end

local tookJob = false
local goalShown = false
-- (second test: setting the waypoint again after the minimap cleared it on arrival brought "You've
-- arrived" back every check, and the hint waited behind it for good) once per target
local wpFor: Vector3? = nil
local function waypoint(pos: Vector3, here: Vector3?)
	-- (again only when something else cleared it while you are still far: the minimap's arrival is 40)
	if wpFor ~= pos or (Minimap.getWaypoint() == nil and here ~= nil and flat(here, pos) > NEAR) then
		wpFor = pos
		Minimap.setWaypoint(pos)
	end
end
local asked: { [number]: boolean } = {}
local function report(n: number)
	if not asked[n] then
		asked[n] = true
		task.spawn(function()
			if ask("step", n) == nil then
				asked[n] = nil -- (no answer: the server's 0.2 s limit or not loaded yet; try again next check)
			end
		end)
	end
end

local function tick()
	local s = step()
	if s >= DONE or s <= 1 then
		if s == 1 and Driving.isDriving() then
			report(2) -- the first car is out
		end
		hide()
		return
	end
	if not tookJob then
		tookJob = true
		local jobCall = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("JobCall")
		if jobCall then
			task.spawn(function()
				pcall(function()
					(jobCall :: RemoteFunction):InvokeServer("take", "delivery")
				end)
			end)
		end
	end
	local root = Driving.getRoot()
	local here = if root then root.Position else nil
	if s == 4 then
		if not goalShown then
			goalShown = true
			hide()
			task.spawn(function()
				task.wait(2.5) -- (after the DELIVERED / LEVEL popups)
				-- (first test: "the cheapest dealer car" was $110,000, hours away: the Legends Path's next
				-- goal is minutes away, pays, and the GOALS screen shows the ones after it)
				local _, _, goal = GoalsClient.getState()
				if type(goal) ~= "table" or type(goal.text) ~= "string" then
					report(DONE)
					return
				end
				local text = string.format("Next goal: %s · +%s", goal.text, UI.formatCash(tonumber(goal.cash) or 0))
				local t0 = os.clock()
				local tapped = false
				while step() == 4 and os.clock() - t0 < GOAL_SECONDS and not tapped do
					show(text, nil, function()
						tapped = true
						GoalsClient.open()
					end)
					task.wait()
				end
				hide()
				report(DONE)
			end)
		end
		return
	end
	-- (step 4 "paid" is the server's: a delivery that pays notes "jobs"; a late one doesn't)
	local drop = Activities.getTarget()
	local name = dropName(drop)
	if drop and name then
		-- a delivery run is on
		if s < 3 then
			report(3)
		end
		waypoint(drop, here) -- (the beam on the drop; JobsClient clears its own when a run starts)
		local close = here ~= nil and flat(here, drop) < NEAR
		show(if close then "Stop at the beam to deliver" else string.format("Deliver to %s: follow the arrow", name), drop, nil, close)
		return
	end
	local target = if here then nearestDispatch(here) else nil
	if not target then
		hide()
		return
	end
	if Minimap.getWaypoint() == nil then
		waypoint(target, here) -- (JobsClient puts it there once the Delivery job is on; this covers a slow answer)
	end
	local close = flat(here :: Vector3, target) < NEAR
	show(if close then "Stop next to the DELIVERY sign to load the parcel" else "Drive to the green beam: your first delivery job", target, nil, close)
end

function Guide.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
	call = remotes and remotes:WaitForChild("GuideCall", 20) :: RemoteFunction?
	if not call then
		warn("[CityLegends] Guide: no GuideCall remote")
		return
	end
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		if step() >= DONE then
			if pill and pill.Visible then
				pill.Visible = false
			end
			return
		end
		-- the arrow turns every frame; the rest is checked 5 times a second
		acc += dt
		if acc < 0.2 then
			if pill and pill.Visible and arrow.Visible then
				local cam = Workspace.CurrentCamera
				local drop = Activities.getTarget()
				local root = Driving.getRoot()
				local target = if dropName(drop) then drop else (root and nearestDispatch(root.Position))
				if cam and target then
					local v = cam.CFrame:VectorToObjectSpace(target - cam.CFrame.Position)
					arrow.Rotation = math.deg(math.atan2(v.X, -v.Z))
				end
				badge.BackgroundTransparency = 0.25 - 0.25 * math.cos(os.clock() * 4)
			end
			return
		end
		acc = 0
		local ok, err = pcall(tick)
		if not ok then
			warn("[CityLegends] Guide:", err)
		end
	end)
end

return Guide
