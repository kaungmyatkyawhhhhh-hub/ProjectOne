-- TrainingController: on a station, tap anywhere to run (GDD 7.1).
-- Each tap = stride (run animation speeds up), +MPH popup (pooled), layered sound with pitch rising
-- with the combo, a small bounce of the MPH number. The server decides the real gain.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Config.GameConfig)
local Palette = require(Shared.Config.Palette)
local Race = require(Shared.Config.Race)
local Stations = require(Shared.Config.Stations)
local Formulas = require(Shared.Util.Formulas)
local Format = require(Shared.Util.Format)

local player = Players.LocalPlayer

local Training = {}

local ctx
local station = nil
local track = nil
local heartbeat = nil
local lastTap = 0
local streakStart = 0
local recent = {}
local lastComboStep = 0
local tapsThisVisit = 0
local controls = nil
local enteredAt = 0
local leaving = false

-- The place may not have the default PlayerModule, so never wait for it. The server anchors you on a
-- station / in a race anyway. (Don't touch GuiService.TouchControlsEnabled: on phones it also froze the camera.)
local function getControls()
	if not controls then
		local module = player:FindFirstChild("PlayerScripts") and player.PlayerScripts:FindFirstChild("PlayerModule")
		if module then
			local ok, m = pcall(require, module)
			if ok then
				controls = m:GetControls()
			end
		end
	end
	return controls
end

function Training.setControls(enabled)
	local c = getControls()
	if c then
		if enabled then
			c:Enable()
		else
			c:Disable()
		end
	end
end

local function stopAnim()
	if track then
		track:Stop(0.25)
		track = nil
	end
end

local function startAnim()
	stopAnim()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = Race.RunAnimation
	track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.2)
	track:AdjustSpeed(0.15)
end

local function currentCombo(now)
	local c = GameConfig.Combo
	local steady = #recent >= c.MinTapsPerSecond and now - recent[1] <= 1 and now - lastTap <= c.MaxGap
	if not steady then
		return 1, 0
	end
	local secs = now - streakStart
	return Formulas.combo(secs), math.clamp(secs / c.BuildSeconds, 0, 1)
end

local function tap()
	if not station then
		return
	end
	local now = os.clock()
	local c = GameConfig.Combo
	if now - lastTap > c.MaxGap then
		streakStart = now
		table.clear(recent)
	end
	lastTap = now
	table.insert(recent, now)
	if #recent > c.MinTapsPerSecond then
		table.remove(recent, 1)
	end

	ctx.Net.get("TrainTap"):FireServer()

	local combo, frac = currentCombo(now)
	local gain = station.Gain * combo
	ctx.Hud.popup("+" .. Format.short(math.max(1, math.floor(gain + 0.5))), if combo >= 1.25 then Palette.Gold else nil)
	ctx.Hud.bounce()
	ctx.Sound.play("Tap", { Pitch = 1 + 0.16 * (combo - 1) })

	-- combo steps
	local step = 0
	for i, s in GameConfig.Combo.Steps do
		if combo >= s - 1e-6 then
			step = i
		end
	end
	if step > lastComboStep then
		ctx.Hud.pulseCombo()
		ctx.Sound.play(if step == #GameConfig.Combo.Steps then "ComboMax" else "ComboUp", { Pitch = 1 + step * 0.05 })
	end
	lastComboStep = step
	ctx.Hud.setCombo(combo, frac)

	tapsThisVisit += 1
	if tapsThisVisit == 4 then
		ctx.Hud.setHint(false)
	end
	if track then
		track:AdjustSpeed(station.AnimSpeed * (1.1 + 0.6 * (combo - 1)))
	end
end

local function onStep()
	if not station then
		return
	end
	local now = os.clock()
	local idle = now - lastTap
	-- combo breaks after a pause
	if lastComboStep > 0 and idle > GameConfig.Combo.MaxGap then
		lastComboStep = 0
		ctx.Hud.setCombo(1, 0)
		ctx.Sound.play("ComboBreak")
	end
	-- pushing the stick / keys walks you off the station (phones have no STOP key)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.MoveDirection.Magnitude > 0.5 and now - enteredAt > 0.6 and not leaving then
		leaving = true
		ctx.Net.get("TrainLeave"):FireServer()
	end
	-- the run slows to a jog when you stop tapping
	if track and idle > 0.35 then
		track:AdjustSpeed(math.max(0.15, track.Speed - 0.05))
	end
end

local function enter(stationId)
	local s = Formulas.station(stationId)
	station = s
	enteredAt = os.clock()
	leaving = false
	tapsThisVisit = 0
	lastComboStep = 0
	table.clear(recent)
	ctx.Hud.setTraining(s)
	ctx.Hud.setHint(true, "TAP ANYWHERE TO RUN!")
	ctx.Sound.play("StationEnter")
	Training.setControls(false)
	startAnim()
	if not heartbeat then
		heartbeat = RunService.Heartbeat:Connect(onStep)
	end
end

local function exit()
	if not station then
		return
	end
	station = nil
	ctx.Hud.setTraining(nil)
	ctx.Hud.setHint(false)
	stopAnim()
	if heartbeat then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	if not player:GetAttribute("InRace") then
		Training.setControls(true)
	end
end

function Training.isTraining()
	return station ~= nil
end

function Training.start(c)
	ctx = c
	ctx.Training = Training

	ctx.Net.get("TrainState").OnClientEvent:Connect(function(stationId)
		if stationId then
			enter(stationId)
		else
			exit()
		end
	end)

	ctx.Hud.refs.stop.Activated:Connect(function()
		ctx.Net.get("TrainLeave"):FireServer()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not station or processed then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
			or (t == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space) then
			tap()
		elseif t == Enum.UserInputType.Keyboard and (input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D) then
			ctx.Net.get("TrainLeave"):FireServer() -- walking away leaves the station
		end
	end)

	player.CharacterAdded:Connect(function()
		exit()
	end)

	-- station unlocked moments
	local lastSpeed = player:GetAttribute("Speed") or 0
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		local v = player:GetAttribute("Speed") or 0
		for _, s in Stations do
			if s.MinSpeed > 0 and lastSpeed < s.MinSpeed and v >= s.MinSpeed then
				ctx.Hud.toast(("%s UNLOCKED!  +%d MPH a tap"):format(string.upper(s.Name), s.Gain), "Unlock")
			end
		end
		lastSpeed = v
	end)
end

return Training
