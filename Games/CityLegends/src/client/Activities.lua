--[[
	Activities (client)
	Time-trial races, delivery jobs and Legends chips on screen and in the world:
	  * orange rings on the road are race starts, blue rings are delivery dispatch points: stop in
	    one for a moment to begin
	  * races: 3-2-1-GO, then drive through every checkpoint (a tall yellow column, the one after
	    it fainter); the clock and the checkpoint count are on screen; a medal by time
	  * jobs: a drop point somewhere across town against a time limit
	  * Legends chips: spinning gold chips hidden on the sidewalks; touch one (on foot or driving)
	  * racing other players (owner, 2026-10-30): stopping in a race ring joins its lobby (the ring's
	    sign shows who's waiting); it starts for everyone in it together, and with 2+ racers the
	    places share a pot. Next to another driver, U (or the RACE pill) challenges them to a duel:
	    a sprint to a junction across town
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local A = Config.Activities
local Theme = Config.Theme
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Activities = {}

local call: RemoteFunction
local folder: Folder
local state: string = "idle" -- idle | countdown | race | job | lobby | duel
local still = 0
local race: ActivityData.Race? = nil
local cp = 1
local t0 = 0
local job: { dest: number, deadline: number }? = nil
local bests: { [string]: number } = {}
local collected: { [number]: boolean } = {}
local chipParts: { [number]: BasePart } = {}
local startLabels: { [string]: TextLabel } = {}
local busy = false
-- racing other players
local lobbies: { [string]: { count: number, startsIn: number, racing: boolean } } = {}
local lobbiesAt = 0 -- os.clock() when `lobbies` came
local lobbyRace: ActivityData.Race? = nil
local lobbyStartsAt = 0
local racers = 1
local duel: { finish: Vector3, vs: string }? = nil
local duelPill: TextButton? = nil
local duelTarget: Player? = nil
local askFrame: Frame? = nil

local gui: ScreenGui
local card: Frame
local cardTitle: TextLabel
local cardTime: TextLabel
local cardSub: TextLabel
local big: TextLabel
local arrow: TextLabel
local cpNow: BasePart
local cpNext: BasePart

local function fmtTime(t: number): string
	return string.format("%d:%05.2f", math.floor(t / 60), t % 60)
end

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

local function ring(pos: Vector3, color: Color3, diameter: number): BasePart
	return part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, diameter, diameter),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.35, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.55,
	})
end

local function billboard(adornee: BasePart, title: string, sub: string, color: Color3): TextLabel
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 64)
	bb.StudsOffset = Vector3.new(0, 9, 0)
	bb.MaxDistance = 450
	bb.LightInfluence = 0
	bb.Parent = adornee
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, 30)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 22
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Text = title
	t.Parent = bb
	local s = Instance.new("TextLabel")
	s.BackgroundTransparency = 1
	s.Position = UDim2.fromOffset(0, 30)
	s.Size = UDim2.new(1, 0, 0, 30)
	s.Font = Enum.Font.GothamBold
	s.TextSize = 14
	s.TextColor3 = Color3.new(1, 1, 1)
	s.TextStrokeTransparency = 0.4
	s.Text = sub
	s.Parent = bb
	return s
end

local function buildWorld()
	folder = Instance.new("Folder")
	folder.Name = "Activities"
	folder.Parent = workspace
	for _, r in ActivityData.races do
		local p = ring(r.start, Color3.fromRGB(255, 140, 20), 30)
		startLabels[r.id] = billboard(p, "RACE · " .. string.upper(r.name), "", Color3.fromRGB(255, 160, 40))
	end
	for _, d in ActivityData.dispatch do
		local p = ring(d.pos - Vector3.new(0, Config.City.CurbHeight, 0), Color3.fromRGB(40, 150, 255), 24)
		billboard(p, "DELIVERY JOBS", d.name .. " · stop here", Color3.fromRGB(90, 180, 255))
	end
	for k, pos in ActivityData.chips do
		local chip = part({
			Name = "LegendsChip",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.5, 3.2, 3.2),
			CFrame = CFrame.new(pos),
			Color = Color3.fromRGB(255, 196, 40),
			Material = Enum.Material.Neon,
		})
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 200, 80)
		l.Range = 10
		l.Brightness = 1.2
		l.Parent = chip
		chipParts[k] = chip
	end
	cpNow = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, A.CheckpointRadius * 2, A.CheckpointRadius * 2), Color = Color3.fromRGB(255, 220, 40), Material = Enum.Material.Neon, Transparency = 1 })
	cpNext = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, A.CheckpointRadius * 2, A.CheckpointRadius * 2), Color = Color3.fromRGB(255, 220, 40), Material = Enum.Material.Neon, Transparency = 1 })
end

local function buildHud()
	gui = Instance.new("ScreenGui")
	gui.Name = "ActivitiesHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 11
	gui.Parent = player:WaitForChild("PlayerGui")
	card = Instance.new("Frame")
	card.Name = "RunCard" -- (GoalsClient hides its tracker while this shows: same spot)
	card.AnchorPoint = Vector2.new(1, 0)
	card.Position = UDim2.new(1, -24, 0, 170)
	card.Size = UDim2.fromOffset(250, 86)
	card.BackgroundColor3 = Theme.Panel
	card.BackgroundTransparency = 0.1
	card.Visible = false
	card.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = card
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 160, 40)
	st.Thickness = 1.5
	st.Parent = card
	local function lbl(y: number, h: number, size: number, font: Enum.Font, color: Color3): TextLabel
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(14, y)
		t.Size = UDim2.new(1, -28, 0, h)
		t.Font = font
		t.TextSize = size
		t.TextColor3 = color
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = card
		return t
	end
	cardTitle = lbl(6, 18, 13, Enum.Font.GothamBlack, Color3.fromRGB(255, 170, 60))
	cardTime = lbl(24, 36, 32, Enum.Font.GothamBlack, Color3.new(1, 1, 1))
	cardSub = lbl(60, 20, 13, Enum.Font.GothamBold, Theme.SubText)
	-- closeable (owner, 2026-10-23): hides the card; the run carries on (the arrow still points)
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -4, 0, 4)
	close.Size = UDim2.fromOffset(24, 24)
	close.BackgroundColor3 = Theme.Panel
	close.Font = Enum.Font.GothamBlack
	close.Text = "X"
	close.TextSize = 12
	close.TextColor3 = Color3.fromRGB(255, 120, 120)
	close.Parent = card
	local ck = Instance.new("UICorner")
	ck.CornerRadius = UDim.new(0.5, 0)
	ck.Parent = close
	close.Activated:Connect(function()
		card.Visible = false
	end)
	big = Instance.new("TextLabel")
	big.AnchorPoint = Vector2.new(0.5, 0.5)
	big.Position = UDim2.fromScale(0.5, 0.35)
	big.Size = UDim2.fromOffset(600, 140)
	big.BackgroundTransparency = 1
	big.Font = Enum.Font.GothamBlack
	big.TextSize = 96
	big.TextColor3 = Color3.new(1, 1, 1)
	big.TextStrokeTransparency = 0.3
	big.Text = ""
	big.Parent = gui
	arrow = Instance.new("TextLabel")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(44, 44)
	arrow.BackgroundTransparency = 1
	arrow.Font = Enum.Font.GothamBlack
	arrow.Text = "▲"
	arrow.TextSize = 40
	arrow.TextColor3 = Color3.fromRGB(255, 200, 40)
	arrow.TextStrokeTransparency = 0.3
	arrow.Visible = false
	arrow.Parent = gui
end

local function flashBig(text: string, color: Color3, seconds: number)
	big.Text = text
	big.TextColor3 = color
	big.TextTransparency = 0
	big.Size = UDim2.fromOffset(700, 170)
	TweenService:Create(big, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(600, 140) }):Play()
	task.delay(seconds, function()
		if big.Text == text then
			TweenService:Create(big, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		end
	end)
end

local function pointArrow(at: Vector3?)
	if not at then
		arrow.Visible = false
		return
	end
	local here = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local to = Vector3.new(at.X - here.X, 0, at.Z - here.Z)
	if flatLook.Magnitude < 0.01 or to.Magnitude < 1 then
		arrow.Visible = false
		return
	end
	flatLook, to = flatLook.Unit, to.Unit
	local ang = math.atan2(flatLook:Cross(to).Y, flatLook:Dot(to))
	arrow.Visible = true
	arrow.Rotation = -math.deg(ang)
	arrow.Position = UDim2.new(0.5 + math.sin(-ang) * 0.12, 0, 0.42 - math.cos(ang) * 0.18, 0)
end

local function refreshLabels()
	for _, r in ActivityData.races do
		local b = bests[r.id]
		local label = startLabels[r.id]
		local l = lobbies[r.id]
		if label then
			if l and l.racing then
				label.Text = "RACING NOW · " .. l.count .. " racers"
			elseif l then
				label.Text = l.count .. " waiting · starts in " .. math.max(0, math.ceil(l.startsIn - (os.clock() - lobbiesAt))) .. " · stop here to join"
			else
				label.Text = (if b then "Best " .. fmtTime(b) .. " · " else "") .. "Gold " .. fmtTime(r.gold) .. " · stop here"
			end
		end
	end
	for k, chip in chipParts do
		chip.Transparency = if collected[k] then 1 else 0
		local l = chip:FindFirstChildOfClass("PointLight")
		if l then
			l.Enabled = not collected[k]
		end
	end
end

local function showCheckpoints()
	local r = race
	if not r then
		cpNow.Transparency = 1
		cpNext.Transparency = 1
		return
	end
	local function place(p: BasePart, k: number, transparency: number)
		local pos = r.checkpoints[k]
		if pos then
			p.CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
			p.Transparency = transparency
		else
			p.Transparency = 1
		end
	end
	place(cpNow, cp, 0.72)
	place(cpNext, cp + 1, 0.9)
end

local function endRun()
	state = "idle"
	race = nil
	job = nil
	duel = nil
	lobbyRace = nil
	racers = 1
	card.Visible = false
	arrow.Visible = false
	showCheckpoints()
end

local function cancel(reason: string)
	if state == "idle" then
		return
	end
	endRun()
	task.spawn(function()
		pcall(function()
			call:InvokeServer("cancel")
		end)
	end)
	UI.toast(reason, Theme.Warning)
end

-- the race / delivery card sits under the minimap (top right), and on touch under the daily gift too
local function showCard()
	local map = player.PlayerGui:FindFirstChild("Minimap")
	local bottom = if map then map:GetAttribute("Bottom") else nil
	local y = (if type(bottom) == "number" then bottom else 230) + 12
	if UI.isTouch then
		y += 80
	end
	card.Position = UDim2.new(1, -24, 0, y)
	card.Visible = true
end

-- 3-2-1-GO, the last beat on the server's start time
local function countdown(t0in: number, onGo: () -> ())
	local goAt = os.clock() + t0in
	task.spawn(function()
		for k, n in { "3", "2", "1" } do
			if state ~= "countdown" then
				return
			end
			flashBig(n, Color3.new(1, 1, 1), 0.7)
			Audio.play("tick", 0.6, 1)
			local beat = goAt - (3 - k)
			task.wait(math.max(0, beat - os.clock() - 1 + 0.001))
		end
		task.wait(math.max(0, goAt - os.clock()))
		if state ~= "countdown" then
			return
		end
		flashBig("GO!", Theme.Money, 0.8)
		Audio.play("tick", 0.8, 1.6)
		t0 = os.clock()
		onGo()
	end)
end

local function startRace(r: ActivityData.Race, t0in: number, count: number)
	state = "countdown"
	race = r
	cp = 1
	racers = count
	showCard()
	cardTitle.Text = (if count >= 2 then "RACE · " .. count .. " RACERS · " else "RACE · ") .. string.upper(r.name)
	cardTime.Text = fmtTime(0)
	cardSub.Text = `Gold {fmtTime(r.gold)} · Silver {fmtTime(r.silver)}`
	showCheckpoints()
	countdown(t0in, function()
		state = "race"
	end)
end

-- stopped in a race ring: join its lobby and wait for the start
local function joinLobby(r: ActivityData.Race)
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("raceJoin", r.id)
		end)
		busy = false
		if not (ok and type(res) == "table" and res.ok) then
			UI.toast(if ok and type(res) == "table" and res.message then res.message else "Couldn't join the race", Theme.Warning)
			return
		end
		state = "lobby"
		lobbyRace = r
		lobbyStartsAt = os.clock() + (tonumber(res.startsIn) or A.LobbySeconds)
		showCard()
		cardTitle.Text = "RACE · " .. string.upper(r.name)
		cardTime.TextColor3 = Color3.new(1, 1, 1)
		Audio.play("tick", 0.6, 1.2)
	end)
end

local function leaveLobby(reason: string?)
	if state ~= "lobby" then
		return
	end
	endRun()
	task.spawn(function()
		pcall(function()
			call:InvokeServer("raceLeave")
		end)
	end)
	if reason then
		UI.toast(reason, Theme.Warning)
	end
end

local function finishRace()
	local r = race :: ActivityData.Race
	local t = os.clock() - t0
	state = "idle"
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("raceFinish", t)
		end)
		busy = false
		endRun()
		if ok and type(res) == "table" and res.ok then
			bests[r.id] = res.best
			refreshLabels()
			local color = if res.medal == "Gold" then Color3.fromRGB(255, 205, 60) elseif res.medal == "Silver" then Color3.fromRGB(210, 215, 225) elseif res.medal == "Bronze" then Color3.fromRGB(205, 130, 70) else Color3.new(1, 1, 1)
			if type(res.place) == "number" and (tonumber(res.racers) or 1) >= 2 then
				-- a race against players: the place first
				local suffix = ({ "ST", "ND", "RD" })[res.place] or "TH"
				flashBig(res.place .. suffix .. " OF " .. res.racers, if res.place == 1 then Color3.fromRGB(255, 205, 60) else Color3.new(1, 1, 1), 3)
				UI.popup(string.upper(res.medal) .. " · " .. fmtTime(res.time) .. (if res.friend then "  · FRIEND BONUS" else ""), res.cash, Theme.Money)
			else
				flashBig(string.upper(res.medal), color, 3)
				UI.popup(fmtTime(res.time) .. (if res.newBest then "  NEW BEST" else ""), res.cash, Theme.Money)
			end
			Audio.cutUp(4, "RACE")
		else
			UI.toast(if ok and type(res) == "table" and res.message then res.message else "Race not counted", Theme.Warning)
		end
	end)
end

local function startJob(which: number)
	state = "countdown"
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("jobStart", which)
		end)
		busy = false
		if not (ok and type(res) == "table" and res.ok) then
			state = "idle"
			UI.toast(if ok and type(res) == "table" and res.message then res.message else "No job right now", Theme.Warning)
			return
		end
		job = { dest = res.dest, deadline = os.clock() + res.limit }
		state = "job"
		local drop = ActivityData.dropPoints[res.dest]
		showCard()
		cardTitle.Text = "DELIVERY"
		cardSub.Text = "Drop at " .. drop.name
		cpNow.CFrame = CFrame.new(drop.pos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
		cpNow.Color = Color3.fromRGB(60, 160, 255)
		cpNow.Transparency = 0.72
		flashBig("DELIVER", Color3.fromRGB(90, 180, 255), 1.2)
	end)
end

local function finishJob()
	state = "idle"
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("jobFinish")
		end)
		busy = false
		cpNow.Color = Color3.fromRGB(255, 220, 40)
		endRun()
		if ok and type(res) == "table" and res.ok then
			if res.late then
				UI.toast("Too late: no pay this time", Theme.Warning)
			else
				UI.popup("DELIVERED", res.cash, Theme.Money)
				Audio.cutUp(3, "JOB")
			end
		end
	end)
end

---------------------------------------------------------------------
-- Duels
---------------------------------------------------------------------
local function startDuel(finish: Vector3, vs: string, t0in: number)
	if askFrame then
		askFrame:Destroy()
		askFrame = nil
	end
	state = "countdown"
	duel = { finish = finish, vs = vs }
	showCard()
	cardTitle.Text = "DUEL · VS " .. string.upper(vs)
	cardTime.Text = fmtTime(0)
	cardSub.Text = "First to the yellow column wins " .. UI.formatCash(A.DuelPot)
	cpNow.CFrame = CFrame.new(finish + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90))
	cpNow.Transparency = 0.6
	countdown(t0in, function()
		state = "duel"
	end)
end

local function finishDuel()
	state = "idle"
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("duelFinish")
		end)
		busy = false
		endRun()
		if ok and type(res) == "table" and res.ok then
			if res.place == 1 then
				flashBig("YOU WIN", Color3.fromRGB(255, 205, 60), 3)
				UI.popup("DUEL WON · " .. fmtTime(res.time), res.cash, Theme.Money)
				Audio.cutUp(10, "DUEL")
			else
				flashBig("2ND", Color3.new(1, 1, 1), 2.5)
				UI.popup("DUEL · " .. fmtTime(res.time), res.cash, Theme.Money)
			end
		end
	end)
end

-- someone challenged you: ACCEPT or NO (it goes after a few seconds)
local function showAsk(from: string, seconds: number)
	if askFrame then
		askFrame:Destroy()
	end
	local kit = UI.kit
	local f: Frame = kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 120),
		Size = UDim2.fromOffset(360, 132),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		ZIndex = 30,
		Parent = gui,
	}, { kit.corner(14), kit.stroke(Color3.fromRGB(255, 160, 40), 1.5, 0.1) })
	askFrame = f
	kit.label({ Text = "RACE CHALLENGE", TextSize = 13, Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(255, 170, 60), Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 16), ZIndex = 31, Parent = f })
	kit.label({ Text = string.upper(from) .. " WANTS TO RACE YOU", TextSize = 18, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 24), TextScaled = true, ZIndex = 31, Parent = f })
	local yes = kit.button("ACCEPT", Theme.Money, { Position = UDim2.new(0, 14, 1, -58), Size = UDim2.new(0.5, -20, 0, 46), TextSize = 17, ZIndex = 31, Parent = f })
	local no = kit.button("NO", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 1, -58), Size = UDim2.new(0.5, -20, 0, 46), TextSize = 17, ZIndex = 31, Parent = f })
	local function answer(v: boolean)
		if askFrame ~= f then
			return
		end
		f:Destroy()
		askFrame = nil
		task.spawn(function()
			local ok, res = pcall(function()
				return call:InvokeServer("duelAnswer", v)
			end)
			if v and not (ok and type(res) == "table" and res.ok) then
				UI.toast(if ok and type(res) == "table" and res.message then res.message else "The race couldn't start", Theme.Warning)
			end
		end)
	end
	yes.Activated:Connect(function()
		answer(true)
	end)
	no.Activated:Connect(function()
		answer(false)
	end)
	Audio.play("tick", 0.8, 1.4)
	task.delay(seconds, function()
		if askFrame == f then
			f:Destroy()
			askFrame = nil
		end
	end)
end

-- the nearest other driver close enough to challenge (nil: none)
local function nearestDriver(pos: Vector3): Player?
	local cars = workspace:FindFirstChild("PlayerCars")
	local best: Player? = nil
	local bestD = A.DuelRange
	for _, car in (if cars then cars:GetChildren() else {}) do
		local uid = car:GetAttribute("Owner")
		if car:IsA("Model") and type(uid) == "number" and uid ~= player.UserId and not car:GetAttribute("Stolen") then
			local d = (car:GetPivot().Position - pos).Magnitude
			local owner = Players:GetPlayerByUserId(uid)
			if d < bestD and owner and owner.Character == nil then
				best, bestD = owner, d
			end
		end
	end
	return best
end

local function challenge()
	local target = duelTarget
	if not target or state ~= "idle" or busy then
		return
	end
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("duelAsk", target.UserId)
		end)
		busy = false
		if ok and type(res) == "table" and res.ok then
			UI.toast("Challenge sent to " .. target.DisplayName, Color3.fromRGB(255, 170, 60))
		else
			UI.toast(if ok and type(res) == "table" and res.message then res.message else "Couldn't send the challenge", Theme.Warning)
		end
	end)
end

local function buildDuelPill()
	local kit = UI.kit
	local b: TextButton = kit.button("", Color3.fromRGB(255, 160, 40), {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -112),
		Size = UDim2.fromOffset(if UI.isTouch then 210 else 250, 40),
		TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 190, 90),
		Visible = false,
		ZIndex = 12,
		Parent = gui,
	})
	b.Activated:Connect(challenge)
	duelPill = b
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.U and b.Visible then
			challenge()
		end
	end)
end

local function myPos(): (Vector3?, number)
	local root = Driving.getRoot()
	if root then
		return root.Position, Driving.getSpeed()
	end
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		return hrp.Position, hrp.AssemblyLinearVelocity.Magnitude
	end
	return nil, 0
end

local chipCooldown = 0
local function update(dt: number)
	local pos, speed = myPos()
	-- chips spin; touch one to collect it
	local spin = os.clock() * 2
	for k, chip in chipParts do
		if not collected[k] then
			local base = ActivityData.chips[k]
			chip.CFrame = CFrame.new(base + Vector3.new(0, math.sin(spin + k) * 0.4, 0)) * CFrame.Angles(0, spin + k, 0)
		end
	end
	chipCooldown = math.max(0, chipCooldown - dt)
	if pos and chipCooldown <= 0 then
		for k, base in ActivityData.chips do
			if not collected[k] and (base - pos).Magnitude < 9 then
				chipCooldown = 1
				collected[k] = true
				refreshLabels()
				task.spawn(function()
					local ok, res = pcall(function()
						return call:InvokeServer("chip", k)
					end)
					if ok and type(res) == "table" and res.ok then
						UI.popup(`LEGENDS CHIP {res.count}/{res.total}`, res.cash, Color3.fromRGB(255, 205, 60))
						Audio.cutUp(2, "CHIP")
					end
				end)
				break
			end
		end
	end

	local wanted = (player:GetAttribute("Wanted") :: number?) or 0
	local driving = Driving.isDriving()
	-- the duel pill: another driver close by, you free to race
	if duelPill then
		local who = if state == "idle" and driving and wanted == 0 and pos and not busy then nearestDriver(pos) else nil
		duelTarget = who
		duelPill.Visible = who ~= nil
		if who then
			duelPill.Text = (if UI.isTouch then "RACE " else "U   RACE ") .. string.upper(who.DisplayName)
		end
	end
	if state == "lobby" then
		local r = lobbyRace
		if not (r and driving and pos) or wanted > 0 then
			leaveLobby("You left the race lobby")
			return
		end
		if Vector3.new(pos.X - r.start.X, 0, pos.Z - r.start.Z).Magnitude > 28 then
			leaveLobby("You drove out of the race ring")
			return
		end
		local l = lobbies[r.id]
		local count = if l then l.count else 1
		cardTime.Text = fmtTime(math.max(0, lobbyStartsAt - os.clock()))
		cardSub.Text = (if count >= 2 then count .. " racers" else "Waiting for racers") .. " · stay in the ring"
		return
	end
	if state == "idle" then
		if not (pos and driving and wanted == 0 and speed < 5 and not busy) then
			still = 0
			return
		end
		-- stopped in a start ring or a dispatch ring
		local found: ActivityData.Race? = nil
		for _, r in ActivityData.races do
			if Vector3.new(pos.X - r.start.X, 0, pos.Z - r.start.Z).Magnitude < 15 then
				found = r
			end
		end
		local dispatch: number? = nil
		for k, d in ActivityData.dispatch do
			if Vector3.new(pos.X - d.pos.X, 0, pos.Z - d.pos.Z).Magnitude < 13 then
				dispatch = k
			end
		end
		if found or dispatch then
			still += dt
			if still > 1.2 then
				still = 0
				if found then
					joinLobby(found)
				elseif dispatch then
					startJob(dispatch)
				end
			end
		else
			still = 0
		end
		return
	end
	if not driving then
		cancel("You left the car")
		return
	end
	if wanted > 0 then
		cancel("The police are after you")
		return
	end
	local mode: string = state
	if mode == "race" and race and pos then
		local r = race
		local t = os.clock() - t0
		cardTime.Text = fmtTime(t)
		cardSub.Text = (if racers >= 2 then `{racers} RACERS · ` else "") .. `CP {cp - 1}/{#r.checkpoints} · Gold {fmtTime(r.gold)}`
		local target = r.checkpoints[cp]
		pointArrow(target)
		if target and Vector3.new(pos.X - target.X, 0, pos.Z - target.Z).Magnitude < A.CheckpointRadius then
			cp += 1
			Audio.play("tick", 0.7, 1.3)
			if cp > #r.checkpoints then
				finishRace()
				return
			end
			showCheckpoints()
		end
		if t > r.bronze * 3 then
			cancel("Race timed out")
		end
	elseif mode == "duel" and duel and pos then
		local d = duel
		cardTime.Text = fmtTime(os.clock() - t0)
		pointArrow(d.finish)
		if Vector3.new(pos.X - d.finish.X, 0, pos.Z - d.finish.Z).Magnitude < A.CheckpointRadius * 1.5 then
			finishDuel()
			return
		end
	elseif mode == "job" and job and pos then
		local drop = ActivityData.dropPoints[job.dest]
		local left = job.deadline - os.clock()
		cardTime.Text = fmtTime(math.max(0, left))
		cardTime.TextColor3 = if left < 15 then Theme.Danger else Color3.new(1, 1, 1)
		pointArrow(drop.pos)
		if Vector3.new(pos.X - drop.pos.X, 0, pos.Z - drop.pos.Z).Magnitude < 24 and speed < 10 then
			finishJob()
		elseif left < -10 then
			cancel("Delivery failed: out of time")
		end
	end
end

-- the race lobbies waiting or racing now (the minimap's live markers)
function Activities.getLive(): { { pos: Vector3, racing: boolean, count: number } }
	local list = {}
	for id, l in lobbies do
		local r = ActivityData.raceById[id]
		if r then
			table.insert(list, { pos = r.start, racing = l.racing, count = l.count })
		end
	end
	return list
end

-- where the current race checkpoint or delivery drop is (the minimap's target blip)
function Activities.getTarget(): Vector3?
	if state == "race" and race then
		return race.checkpoints[cp]
	elseif (state == "duel" or state == "countdown") and duel then
		return duel.finish
	elseif state == "job" and job then
		return ActivityData.dropPoints[job.dest].pos
	end
	return nil
end

function Activities.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("ActivityCall") :: RemoteFunction
	buildWorld()
	buildHud()
	buildDuelPill()
	local push = remotes:WaitForChild("RacePush", 30) :: RemoteEvent?
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) ~= "table" then
				return
			end
			if msg.kind == "lobbies" and type(msg.list) == "table" then
				-- a new race forming: say so (unless it's yours)
				for id, l in msg.list do
					local r = ActivityData.raceById[id]
					if r and not lobbies[id] and not l.racing and lobbyRace ~= r and state == "idle" then
						UI.toast("RACE FORMING · " .. string.upper(r.name) .. " · " .. math.ceil(l.startsIn) .. " s to join (orange R on the map)", Color3.fromRGB(255, 170, 60))
					end
				end
				lobbies = msg.list
				lobbiesAt = os.clock()
				refreshLabels()
			elseif msg.kind == "go" then
				local r = ActivityData.raceById[msg.id]
				if r and (state == "lobby" or state == "idle") then
					startRace(r, tonumber(msg.t0in) or 3, tonumber(msg.racers) or 1)
				end
			elseif msg.kind == "finished" then
				local suffix = ({ "st", "nd", "rd" })[msg.place] or "th"
				UI.toast(tostring(msg.name) .. " finished " .. tostring(msg.place) .. suffix, Color3.fromRGB(255, 170, 60))
			elseif msg.kind == "duelAsk" then
				showAsk(tostring(msg.from), tonumber(msg.seconds) or A.DuelAskSeconds)
			elseif msg.kind == "duelNo" then
				UI.toast(tostring(msg.name) .. " said no", Theme.SubText)
			elseif msg.kind == "duelGo" and typeof(msg.finish) == "Vector3" then
				startDuel(msg.finish, tostring(msg.vs), tonumber(msg.t0in) or 3)
			elseif msg.kind == "duelLost" then
				UI.toast(tostring(msg.name) .. " won the duel: finish for second place", Theme.Warning)
			elseif msg.kind == "duelEnd" then
				if duel then
					endRun()
					UI.toast("The duel timed out", Theme.Warning)
				end
			end
		end)
	end
	-- the lobby countdowns on the ring signs tick down
	task.spawn(function()
		while true do
			task.wait(1)
			if next(lobbies) then
				refreshLabels()
			end
		end
	end)
	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("state")
		end)
		if ok and type(res) == "table" then
			if type(res.races) == "table" then
				for id, t in res.races do
					if type(t) == "number" then
						bests[id] = t
					end
				end
			end
			if type(res.chips) == "table" then
				for _, k in res.chips do
					collected[k] = true
				end
			end
		end
		refreshLabels()
	end)
	refreshLabels()
	RunService.Heartbeat:Connect(update)
end

return Activities
