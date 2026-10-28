-- TrainingController: AFK step machines (28 Oct pivot; tapping is gone). On a machine your runner
-- jogs by itself and the server pays the steps (TrainingService); the SPEED number ticks up with
-- +N popups (StepController). STOP, or W/A/S/D, takes you off.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Race = require(Shared.Config.Race)
local Stations = require(Shared.Config.Stations)
local Formulas = require(Shared.Util.Formulas)

local player = Players.LocalPlayer

local Training = {}

local ctx
local station = nil
local track = nil
local controls = nil

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

local function startAnim(speed)
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
	track:AdjustSpeed(speed)
end

-- the treadmill canopy fades while you train under it (it covered the top of the view)
local function setCanopyFade(on)
	local hub = workspace:FindFirstChild("Hub")
	local tread = hub and hub:FindFirstChild("Training") and hub.Training:FindFirstChild("Treadmill")
	if not tread then
		return
	end
	for _, p in tread:GetDescendants() do
		if p:IsA("BasePart") and string.find(p.Name, "^Canopy") then
			p.LocalTransparencyModifier = if on then 0.85 else 0
		end
	end
end

local function animSpeed(s)
	return s.AnimSpeed * (if player:GetAttribute("AutoTrain") then 1.6 else 1)
end

local function enter(stationId)
	local s = Formulas.station(stationId)
	if not s then
		return
	end
	setCanopyFade(stationId == "Treadmill")
	station = s
	ctx.Hud.setTraining(s)
	ctx.Hud.setHint(true, "STEPPING FOR YOU!  RUN THE COURSE FOR MORE")
	ctx.Sound.play("StationEnter")
	Training.setControls(false)
	startAnim(animSpeed(s))
end

local function exit()
	if not station then
		return
	end
	station = nil
	setCanopyFade(false)
	ctx.Hud.setTraining(nil)
	ctx.Hud.setHint(false)
	stopAnim()
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
		if input.UserInputType == Enum.UserInputType.Keyboard and (input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D) then
			ctx.Net.get("TrainLeave"):FireServer() -- walking away leaves the machine
		end
	end)
	player:GetAttributeChangedSignal("AutoTrain"):Connect(function()
		if station and track then
			track:AdjustSpeed(animSpeed(station))
		end
	end)

	player.CharacterAdded:Connect(function()
		exit()
	end)

	-- machine unlocked moments
	local lastSpeed = player:GetAttribute("Speed") or 0
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		local v = player:GetAttribute("Speed") or 0
		for _, s in Stations do
			if s.MinSpeed > 0 and s.League == (player:GetAttribute("League") or 1) and lastSpeed < s.MinSpeed and v >= s.MinSpeed then
				ctx.Hud.toast(("%s UNLOCKED!  x%g per step"):format(string.upper(s.Name), s.Mult), "Unlock")
			end
		end
		lastSpeed = v
	end)
end

return Training
