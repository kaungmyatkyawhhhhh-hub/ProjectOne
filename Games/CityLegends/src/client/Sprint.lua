--!strict
--[[
	Sprint (client; owner, 2026-11-26: "make it so that we can sprint and add some fov changing while
	sprinting too and find ways to increase their dopamine"). On foot only, free for everyone.

	  * PC: hold Shift. Gamepad: L3 (toggle). Phone: the round SPRINT button left of Roblox's jump
	    button (UI.buildTouchControls; a tap toggles it, it switches off when you stop walking).
	  * Only while walking on the ground, never in a car, a menu (UI.modalOpen) or a frozen screen
	    (WalkSpeed 0: dealer, workshop).
	  * Walk speed eases from StarterPlayer.CharacterWalkSpeed up to x SPEED_MULT; the FOV widens by
	    FOV_ADD (added on top of whatever the camera has, so it never fights another camera's FOV);
	    a whoosh on start, faster footsteps, soft edge streaks (UI.setSpeedLines), a light head bob
	    (Humanoid.CameraOffset) and a dust puff per stride (not in low-end mode).
	OnFoot.init calls Sprint.init(OnFoot). Studio test hook: player attribute TestSprint = true holds it on.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local LowEnd = require(script.Parent:WaitForChild("LowEnd"))
local Frame = require(script.Parent:WaitForChild("Frame"))

local Sprint = {}

local SPEED_MULT = 1.6 -- 16 -> 25.6 studs/s
local FOV_ADD = 12 -- 70 -> 82
local RATE_UP = 7 -- per second (eases ~95% of the way in 0.43 s)
local RATE_DOWN = 9 -- (~0.33 s back)
local FOV_RATE_UP = 5 -- (~0.6 s)
local FOV_RATE_DOWN = 6 -- (~0.5 s)
local STEP_SPEED = 1.35 -- footstep sound playback while sprinting
local STRIDE = 0.27 -- seconds between dust puffs

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local keyHeld = false -- Shift
local toggled = false -- phone button / L3
local movedOn = false -- walked since it was toggled on (only then does stopping switch it off)
Sprint.k = 0 -- 0 = walking .. 1 = full sprint (eased)
local fovAdded = 0 -- what we've added to camera.FieldOfView right now
local wasOn = false
local bobT, strideT = 0, 0
local linesOn = false
local dust: ParticleEmitter? = nil
local onFoot: { active: boolean } = { active = false } -- (OnFoot itself, given to init: it requires us)

local function humanoid(): Humanoid?
	local c = player.Character
	return if c then c:FindFirstChildOfClass("Humanoid") else nil
end

local function onGround(h: Humanoid): boolean
	return h.FloorMaterial ~= Enum.Material.Air and h.SeatPart == nil and h.MoveDirection.Magnitude > 0.1
end

-- may sprint right now (on foot, walking, no menu, not frozen by a screen)
local function allowed(h: Humanoid?): boolean
	return h ~= nil
		and onFoot.active
		and not Driving.isDriving()
		and not UI.modalOpen
		and h.Health > 0
		and h.WalkSpeed > 0
		and camera.CameraType == Enum.CameraType.Custom
end

local function footsteps(h: Humanoid, speed: number)
	local root = h.Parent and h.Parent:FindFirstChild("HumanoidRootPart")
	local s = root and root:FindFirstChild("Running")
	if s and s:IsA("Sound") then
		s.PlaybackSpeed = speed
	end
end

local function puff(h: Humanoid)
	if LowEnd.on then
		return
	end
	local root = h.Parent and h.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if not dust or dust.Parent ~= root then
		local a = Instance.new("Attachment")
		a.Name = "SprintDust"
		a.Position = Vector3.new(0, -2.9, 0.6) -- (at the heels of an R15 / R6 avatar)
		a.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(200, 186, 160))
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.6) })
		e.Lifetime = NumberRange.new(0.35, 0.55)
		e.Speed = NumberRange.new(1, 3)
		e.SpreadAngle = Vector2.new(60, 20)
		e.Acceleration = Vector3.new(0, 2, 0)
		e.Rate = 0
		e.LightEmission = 0
		e.Parent = a
		dust = e
	end
	(dust :: ParticleEmitter):Emit(2)
end

local function step(dt: number)
	local h = humanoid()
	local ok = allowed(h)
	local tester = RunService:IsStudio() and player:GetAttribute("TestSprint") == true
	if toggled and h and h.MoveDirection.Magnitude > 0.1 then
		movedOn = true
	elseif toggled and movedOn and h and h.MoveDirection.Magnitude < 0.05 then
		toggled, movedOn = false, false -- (phone / pad: stopping switches it off; a tap while standing waits)
	end
	local want = ok and h ~= nil and (keyHeld or toggled or tester) and (onGround(h) or (wasOn and h.FloorMaterial == Enum.Material.Air))
	-- (a jump mid-sprint keeps the speed; a sprint only starts on the ground)
	local target = if want then 1 else 0
	local rate = if target > Sprint.k then RATE_UP else RATE_DOWN
	Sprint.k += (target - Sprint.k) * (1 - math.exp(-dt * rate))
	if math.abs(target - Sprint.k) < 0.002 then
		Sprint.k = target
	end
	local k = Sprint.k
	if want and not wasOn then
		Audio.whoosh(0.22, 2.3)
	end
	if h and ok then
		local base = StarterPlayer.CharacterWalkSpeed
		h.WalkSpeed = base * (1 + (SPEED_MULT - 1) * k)
		footsteps(h, 1 + (STEP_SPEED - 1) * k)
		bobT += dt * (6 + 5 * k)
		h.CameraOffset = if k > 0 and onGround(h) then Vector3.new(math.sin(bobT) * 0.05 * k, math.abs(math.sin(bobT)) * 0.12 * k, 0) else Vector3.zero
		if want and onGround(h) then
			strideT += dt
			if strideT >= STRIDE then
				strideT = 0
				puff(h)
			end
		end
	elseif h and (wasOn or k > 0) then
		-- (a car / menu / screen took over: drop the boost at once, its own code sets what it needs)
		Sprint.k, k = 0, 0
		if h.WalkSpeed > 0 then
			h.WalkSpeed = StarterPlayer.CharacterWalkSpeed
		end
		h.CameraOffset = Vector3.zero
		footsteps(h, 1)
	end
	wasOn = want
	-- FOV: only ever add our part on top (another screen's camera keeps its own FOV)
	-- (a menu that leaves the walking camera alone: ease back; a car or a screen's own camera: forget it)
	local fovTarget = if ok then FOV_ADD * k else 0
	if onFoot.active and not Driving.isDriving() and camera.CameraType == Enum.CameraType.Custom then
		local add = fovAdded + (fovTarget - fovAdded) * (1 - math.exp(-dt * (if fovTarget > fovAdded then FOV_RATE_UP else FOV_RATE_DOWN)))
		if math.abs(add - fovTarget) < 0.01 then
			add = fovTarget
		end
		camera.FieldOfView += add - fovAdded
		fovAdded = add
	else
		fovAdded = 0 -- (forget it: the new camera owner set its own FOV)
	end
	if k > 0 or linesOn then
		UI.setSpeedLines(k * 0.55) -- (one last 0 clears them; in a car Driving draws its own)
		linesOn = k > 0
	end
	UI.setSprintButton(ok, toggled or keyHeld)
end

function Sprint.init(owner: { active: boolean })
	onFoot = owner
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			keyHeld = true -- (Shift is only a modifier elsewhere on foot: Shift + F doors, Shift + P photo)
		elseif input.KeyCode == Enum.KeyCode.ButtonL3 and not processed then
			toggled, movedOn = not toggled, false
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			keyHeld = false
		end
	end)
	UI.onSprintTouch = function()
		toggled, movedOn = not toggled, false
	end
	player.CharacterAdded:Connect(function()
		Sprint.k, fovAdded, wasOn, toggled, movedOn, dust = 0, 0, false, false, false, nil
	end)
	Frame.Connect(step)
end

return Sprint
