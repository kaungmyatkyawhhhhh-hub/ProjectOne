--[[
	ChallengesClient
	The client side of the free-roam challenges (owner, 2026-10-23: "make the game 1000000000x
	better and cooler"); the server (Challenges.lua) checks and pays:
	  * drift scoring: sliding (the car pointing away from where it's going) at speed builds
	    points; the multiplier grows while the drift stays linked; a short calm banks the run, a
	    crash loses it. A counter at the top of the screen
	  * speed traps: driving through a gantry (ChallengeData.traps) sends your speed; the result
	    (medal, personal best) pops up
	  * jumps: time in the air off a ramp (or anywhere) pays when you land
	  * the leaderboard panel: B
	Reads Driving through its getters only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ChallengeData = require(Shared:WaitForChild("ChallengeData"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local UI = require(script.Parent:WaitForChild("UI"))

local K = Config.Challenges
local Theme = Config.Theme
local player = Players.LocalPlayer

local ChallengesClient = {}

local GOLD = Color3.fromRGB(255, 204, 60)
local MEDAL_COLOR = {
	BRONZE = Color3.fromRGB(214, 140, 80),
	SILVER = Color3.fromRGB(210, 216, 226),
	GOLD = GOLD,
}

local function money(n: number): string
	local f = (UI :: any).formatCash
	return if type(f) == "function" then f(n) else ("$" .. tostring(math.floor(n)))
end

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

---------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------
local gui: ScreenGui
local driftFrame: Frame
local driftScore: TextLabel
local driftMult: TextLabel
local driftTitle: TextLabel
local popup: Frame
local popTitle: TextLabel
local popSub: TextLabel
local boardFrame: Frame
local boardCols: { TextLabel } = {}
local boardMine: TextLabel

local function buildHud()
	gui = new("ScreenGui", { Name = "Challenges", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 11 }, player:WaitForChild("PlayerGui"))
	-- drift counter (top middle, under the police stars)
	driftFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.fromOffset(260, 86), BackgroundTransparency = 1, Visible = false }, gui)
	driftTitle = new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "DRIFT", TextSize = 18, TextColor3 = GOLD, TextStrokeTransparency = 0.5 }, driftFrame)
	driftScore = new("TextLabel", { Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "0", TextSize = 44, TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 0.35 }, driftFrame)
	driftMult = new("TextLabel", { Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "x1.0", TextSize = 20, TextColor3 = Theme.Accent, TextStrokeTransparency = 0.5 }, driftFrame)
	-- result pop-up (speed traps, jumps, banked drifts)
	popup = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.26, 0), Size = UDim2.fromOffset(420, 78), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.15, Visible = false }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 12) }, popup)
	new("UIStroke", { Color = GOLD, Thickness = 2, Transparency = 0.2 }, popup)
	popTitle = new("TextLabel", { Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "", TextSize = 30, TextColor3 = GOLD }, popup)
	popSub = new("TextLabel", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "", TextSize = 16, TextColor3 = Theme.Text }, popup)
	-- leaderboard panel (B)
	boardFrame = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.fromOffset(420, 330), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.06, Visible = false }, gui)
	new("UICorner", { CornerRadius = UDim.new(0, 14) }, boardFrame)
	new("UIStroke", { Color = Theme.Stroke, Thickness = 1.5 }, boardFrame)
	new("TextLabel", { Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -36, 0, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, Text = "LEADERBOARD", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD }, boardFrame)
	new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 14), Size = UDim2.fromOffset(120, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "B to close", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Theme.SubText }, boardFrame)
	for k = 1, 2 do
		boardCols[k] = new("TextLabel", {
			Position = UDim2.new((k - 1) * 0.5, 18, 0, 48),
			Size = UDim2.new(0.5, -24, 1, -110),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = Theme.Text,
			Text = "",
		}, boardFrame)
	end
	boardMine = new("TextLabel", { Position = UDim2.new(0, 18, 1, -56), Size = UDim2.new(1, -36, 0, 44), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Accent, Text = "" }, boardFrame)
end

local popToken = 0
local function showPopup(title: string, sub: string, color: Color3?)
	popToken += 1
	local my = popToken
	popTitle.Text = title
	popTitle.TextColor3 = color or GOLD
	popSub.Text = sub
	popup.Visible = true
	popup.Position = UDim2.new(0.5, 0, 0.24, 0)
	TweenService:Create(popup, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0.26, 0) }):Play()
	task.delay(3.2, function()
		if popToken == my then
			popup.Visible = false
		end
	end)
end

local function rowsText(title: string, rows: any, unit: string): string
	local lines = { title, "" }
	if type(rows) == "table" then
		for i, r in rows do
			if type(r) == "table" then
				table.insert(lines, string.format("%d. %s  %s%s", i, tostring(r.name), tostring(r.value), unit))
			end
		end
	end
	if #lines == 2 then
		table.insert(lines, "no one yet")
	end
	return table.concat(lines, "\n")
end

local function openBoard()
	boardFrame.Visible = not boardFrame.Visible
	if not boardFrame.Visible then
		return
	end
	local call = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("ChallengeBoard") :: RemoteFunction?
	if not call then
		return
	end
	task.spawn(function()
		local ok, res = pcall(function()
			return (call :: RemoteFunction):InvokeServer()
		end)
		if not (ok and type(res) == "table") then
			return
		end
		boardCols[1].Text = rowsText("TOP SPEED", res.speed, " mph")
		boardCols[2].Text = rowsText("BEST DRIFT", res.drift, "")
		local mine = res.mine
		if type(mine) == "table" then
			boardMine.Text = string.format("YOU  ·  top speed %d mph  ·  best drift %d  ·  longest jump %.1fs", tonumber(mine.speed) or 0, tonumber(mine.drift) or 0, tonumber(mine.air) or 0)
		end
	end)
end

---------------------------------------------------------------------
-- Detection
---------------------------------------------------------------------
local report: RemoteEvent? = nil

-- drift run
local drifting = false
local runOn = false
local runStart = 0
local points = 0
local mult = 1
local multTimer = 0
local calm = 0
-- crash detection: a big speed loss in a moment
local speedSample = 0
local sampleTimer = 0
-- air
local airT = 0
local takeoff: Vector3? = nil
-- traps: which side of each gate we were on
local trapSide: { [string]: number } = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function endRun(lost: boolean)
	if runOn and not lost and points >= 50 and report then
		report:FireServer("drift", math.floor(points), os.clock() - runStart)
	elseif runOn and lost and points >= 50 then
		showPopup("DRIFT LOST", "you crashed: " .. math.floor(points) .. " points gone", Theme.Danger)
	end
	runOn = false
	points = 0
	mult = 1
	multTimer = 0
	calm = 0
	driftFrame.Visible = false
end

local function step(dt: number)
	if not Driving.isDriving() then
		if runOn then
			endRun(true)
		end
		airT = 0
		takeoff = nil
		table.clear(trapSide)
		return
	end
	local root = Driving.getRoot()
	local model = Driving.getModel()
	if not (root and model) then
		return
	end
	local v = root.AssemblyLinearVelocity
	local flat = Vector3.new(v.X, 0, v.Z)
	local sps = flat.Magnitude
	local mph = Config.spsToMph(sps)
	local look = model:GetPivot().LookVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	local pos = root.Position

	-- crash: lost a third of the speed in a fifth of a second
	sampleTimer += dt
	if sampleTimer >= 0.2 then
		if speedSample - sps > math.max(25, speedSample * 0.35) then
			if runOn then
				endRun(true)
			end
		end
		speedSample = sps
		sampleTimer = 0
	end

	-- drift
	local angle = 0
	if sps > 5 and fwd.Magnitude > 0.1 then
		local d = flat.Unit:Dot(fwd.Unit)
		if d > 0 then
			angle = math.deg(math.acos(math.clamp(d, -1, 1)))
		end
	end
	drifting = mph >= K.DriftMinMph and angle >= K.DriftMinAngle and angle <= 80
	if drifting then
		if not runOn then
			runOn = true
			runStart = os.clock()
			points = 0
			mult = 1
			multTimer = 0
		end
		calm = 0
		multTimer += dt
		if multTimer >= K.DriftMultEvery then
			multTimer = 0
			mult = math.min(mult + K.DriftMultStep, K.DriftMultMax)
		end
		points += dt * mph * (math.min(angle, 60) / 30) * mult
		driftFrame.Visible = true
		driftScore.Text = tostring(math.floor(points))
		driftMult.Text = string.format("x%.1f", mult)
		driftTitle.Text = if angle > 40 then "BIG DRIFT" else "DRIFT"
	elseif runOn then
		calm += dt
		driftScore.TextTransparency = math.clamp(calm / K.DriftLinkSeconds, 0, 0.6)
		if calm >= K.DriftLinkSeconds then
			driftScore.TextTransparency = 0
			endRun(false)
		end
	end

	-- air: nothing under the car
	rayParams.FilterDescendantsInstances = { model, player.Character :: Instance }
	local hit = workspace:Raycast(pos, Vector3.new(0, -9, 0), rayParams)
	if not hit then
		if airT == 0 then
			takeoff = pos
		end
		airT += dt
	elseif airT > 0 then
		if airT >= K.StuntMinAir and takeoff and report then
			local dist = Vector3.new(pos.X - takeoff.X, 0, pos.Z - takeoff.Z).Magnitude
			report:FireServer("stunt", airT, dist)
		end
		airT = 0
		takeoff = nil
	end

	-- speed traps: crossing a gate's line inside its width
	for _, t in ChallengeData.traps do
		local rel = pos - t.pos
		if math.abs(rel.Y) < 25 and rel.Magnitude < 200 then
			local along = rel:Dot(t.dir)
			local lateral = math.abs(rel:Dot(t.dir:Cross(Vector3.yAxis)))
			local side = if along >= 0 then 1 else -1
			local before = trapSide[t.id]
			if before and before ~= side and lateral <= t.half + 4 and report then
				report:FireServer("trap", t.id, mph)
			end
			trapSide[t.id] = side
		else
			trapSide[t.id] = nil
		end
	end
end

---------------------------------------------------------------------
-- Results from the server
---------------------------------------------------------------------
local function onResult(info: any)
	if type(info) ~= "table" then
		return
	end
	if info.kind == "trap" then
		local medal = info.medal
		local title = if medal then string.format("%s  ·  %d MPH", medal, info.mph) else string.format("%d MPH", info.mph)
		local sub = tostring(info.name) .. (if info.newBest then "  ·  NEW BEST" else "  ·  best " .. tostring(info.best) .. " mph")
		if (tonumber(info.cash) or 0) > 0 then
			sub ..= "  +" .. money(info.cash)
		end
		showPopup(title, sub, if medal then MEDAL_COLOR[medal] else Theme.Text)
		Audio.cutUp(if medal == "GOLD" then 10 elseif medal == "SILVER" then 6 else 2, "TRAP")
	elseif info.kind == "drift" then
		showPopup(string.format("DRIFT  %d", info.score), "+" .. money(info.cash) .. (if info.newBest then "  ·  NEW BEST" else ""), GOLD)
		Audio.cutUp(8, "DRIFT")
	elseif info.kind == "stunt" then
		showPopup(string.format("BIG AIR  %.1fs", info.air), string.format("%d studs  +%s%s", math.floor(info.dist), money(info.cash), if info.newBest then "  ·  NEW BEST" else ""), Theme.Accent)
		Audio.cutUp(6, "AIR")
	end
end

local warned = false
function ChallengesClient.init()
	buildHud()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	task.spawn(function()
		report = remotes:WaitForChild("ChallengeReport", 60) :: RemoteEvent?
		local ev = remotes:WaitForChild("ChallengeEvent", 60) :: RemoteEvent?
		if ev then
			ev.OnClientEvent:Connect(onResult)
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(step, math.min(dt, 0.1))
		if not ok and not warned then
			warned = true
			warn("[CityLegends] challenges:", err)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == K.BoardKey then
			openBoard()
		end
	end)
end

return ChallengesClient
