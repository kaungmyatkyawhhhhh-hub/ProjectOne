-- MB_Swim (client): the custom swim controller + chase camera + every player shark's animation.
-- Phone first: a floating thumbstick (left side) swims, let go = glide to a stop; drag anywhere else to look (pinch = zoom), DART button (HUD).
-- PC: WASD/arrows, right-mouse drag to look, wheel to zoom, Shift/Space = DART, F = ability. Gamepad: sticks, R2/A = DART.
-- Steering is camera-relative (like walking in Roblox); the camera swings behind the heading with a lag.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CS = game:GetService("CollectionService")
local lp = Players.LocalPlayer
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local Bus = require(MB:WaitForChild("ClientBus"))
local UIKit = require(MB:WaitForChild("UIKit"))
local Remotes = MB:WaitForChild("Remotes")
local Action, Correct = Remotes:WaitForChild("SwimAction"), Remotes:WaitForChild("SwimCorrect")
local BonePlayer = require(RS:WaitForChild("MB_Anim"):WaitForChild("BonePlayer"))
local Sounds = require(RS:WaitForChild("MB_Sounds"))
local okVFX, AbilityVFX = pcall(function() return require(RS:WaitForChild("MB_VFX", 5):WaitForChild("AbilityVFX", 5)) end)
local SW, CAM = C.Swim, C.Camera
local camera = workspace.CurrentCamera

-- no default walking controls: we are a shark
task.spawn(function()
	local ok, pm = pcall(function() return require(lp:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)) end)
	if ok and pm then pcall(function() pm:GetControls():Disable() end) end
end)

local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end
local function damp(rate, dt) return 1 - math.exp(-rate * dt) end
local function yawOf(v) return math.atan2(-v.X, -v.Z) end

------------------------------------------------------------------ animation for EVERY player shark
local anims = {}
local CUE = {SwishA = "Swish", SwishB = "Swish", Whoosh = "DartWhoosh", Snap = "Bite", Gulp = "Gulp", Ram = "HammerRam", Burst = "Breach", Roar = "TidalRoar", Chomp = "Frenzy", Launch = "Torpedo", Ping = "SensePing"}
local function setupAnim(model)
	if anims[model] then return end
	local clips = model:GetAttribute("MB_Clips") or "ReefSharkClips"
	local a = BonePlayer.new(model, "Idle", clips)
	local rec = {anim = a, bend = 0, lastDart = model:GetAttribute("DartAt") or 0, lastAb = model:GetAttribute("AbilityAt") or 0, mine = model:GetAttribute("Owner") == lp.UserId}
	anims[model] = rec
	local emitter = model:FindFirstChild("Spine0", true) or model.PrimaryPart
	a:OnMarker(function(clip, marker)
		if okVFX and AbilityVFX then pcall(AbilityVFX.OnMarker, model, clip, marker) end
		local snd = CUE[marker]
		if snd and (clip ~= "Swim" or rec.mine) then Sounds.Play(snd, emitter) end
	end)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then a:Destroy(); anims[model] = nil end
	end)
end
for _, m in ipairs(CS:GetTagged("MBPlayerShark")) do setupAnim(m) end
CS:GetInstanceAddedSignal("MBPlayerShark"):Connect(setupAnim)
CS:GetInstanceRemovedSignal("MBPlayerShark"):Connect(function(m) local r = anims[m]; if r then r.anim:Destroy(); anims[m] = nil end end)

local myYawRate = 0
RunService.RenderStepped:Connect(function(dt)
	for model, rec in pairs(anims) do
		local root = model.PrimaryPart
		if root then
			local evo = C.Evolutions[model:GetAttribute("Evo") or 1]
			local v = root.AssemblyLinearVelocity
			local spd = v.Magnitude
			local a = rec.anim
			local dartAt = model:GetAttribute("DartAt") or 0
			if dartAt ~= rec.lastDart then rec.lastDart = dartAt; a:Play("Dart", 0.08) end
			local abAt = model:GetAttribute("AbilityAt") or 0
			if abAt ~= (rec.lastAb or 0) then
				rec.lastAb = abAt
				local keys = {}
				for k in string.gmatch(model:GetAttribute("MB_Keys") or "", "[^,]+") do table.insert(keys, k) end
				local clip = keys[5]
				if clip and clip ~= "Hurt" then a:Play(clip, 0.1); rec.busyUntil = os.clock() + 1.6 end
			end
			if (a.name == "Swim" or a.name == "Idle") and os.clock() > (rec.busyUntil or 0) then
				local want = spd > SW.SwimAnimSpeed and "Swim" or "Idle"
				if a.name ~= want then a:Play(want, 0.25) end
			end
			local backwards = v:Dot(root.CFrame.LookVector) < -1
			a.rate = (a.name == "Swim") and (backwards and 0.6 or math.clamp(spd / evo.cruise, 0.55, 2.1)) or 1
			local yr = rec.mine and myYawRate or root.AssemblyAngularVelocity.Y
			local target = math.clamp(yr / math.rad(evo.turn), -1, 1) * SW.BendMax * SW.BendSign
			rec.bend += (target - rec.bend) * damp(8, dt)
			a.bend = rec.bend
		end
	end
end)

------------------------------------------------------------------ input
local input = {keys = Vector2.zero, stick = Vector2.zero, pad = Vector2.zero, look = Vector2.zero, zoom = 1}
local lastLook = -100
local dartQueued = false
local KEYMAP = {[Enum.KeyCode.W] = Vector2.new(0, 1), [Enum.KeyCode.Up] = Vector2.new(0, 1), [Enum.KeyCode.S] = Vector2.new(0, -1), [Enum.KeyCode.Down] = Vector2.new(0, -1),
	[Enum.KeyCode.A] = Vector2.new(-1, 0), [Enum.KeyCode.Left] = Vector2.new(-1, 0), [Enum.KeyCode.D] = Vector2.new(1, 0), [Enum.KeyCode.Right] = Vector2.new(1, 0)}
local held = {}
local function keyVec()
	local v = Vector2.zero
	for k, d in pairs(KEYMAP) do if held[k] then v += d end end
	return v.Magnitude > 0 and v.Unit or v
end
UIS.InputBegan:Connect(function(io, gp)
	if io.UserInputType == Enum.UserInputType.Keyboard then
		if UIS:GetFocusedTextBox() then return end
		if KEYMAP[io.KeyCode] then held[io.KeyCode] = true end
		if io.KeyCode == Enum.KeyCode.LeftShift or io.KeyCode == Enum.KeyCode.Space then dartQueued = true end
		if io.KeyCode == Enum.KeyCode.F then Bus.Ability:Fire() end
		if RunService:IsStudio() and (io.KeyCode == Enum.KeyCode.RightBracket or io.KeyCode == Enum.KeyCode.LeftBracket) then
			Action:FireServer("DevEvo", io.KeyCode == Enum.KeyCode.LeftBracket and -1 or 1)
		end
	elseif io.UserInputType == Enum.UserInputType.MouseButton2 and not gp then
		UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	elseif io.KeyCode == Enum.KeyCode.ButtonR2 or io.KeyCode == Enum.KeyCode.ButtonA then
		dartQueued = true
	elseif io.KeyCode == Enum.KeyCode.ButtonX then
		Bus.Ability:Fire()
	end
end)
UIS.InputEnded:Connect(function(io)
	if io.UserInputType == Enum.UserInputType.Keyboard then held[io.KeyCode] = nil
	elseif io.UserInputType == Enum.UserInputType.MouseButton2 then UIS.MouseBehavior = Enum.MouseBehavior.Default end
end)
UIS.InputChanged:Connect(function(io, gp)
	if io.UserInputType == Enum.UserInputType.MouseMovement and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		input.look += Vector2.new(io.Delta.X, io.Delta.Y) * CAM.MouseSens; lastLook = os.clock()
	elseif io.UserInputType == Enum.UserInputType.MouseWheel and not gp then
		input.zoom = math.clamp(input.zoom * (1 - io.Position.Z * 0.12), 0.05, CAM.ZoomMax)
	elseif io.KeyCode == Enum.KeyCode.Thumbstick1 then
		local p = Vector2.new(io.Position.X, io.Position.Y)
		input.pad = p.Magnitude > 0.15 and p or Vector2.zero
	elseif io.KeyCode == Enum.KeyCode.Thumbstick2 then
		local p = Vector2.new(io.Position.X, -io.Position.Y)
		input.padLook = p.Magnitude > 0.15 and p or Vector2.zero
	end
end)
Bus.Dart.Event:Connect(function() dartQueued = true end)

-- floating thumbstick (phones): touch the left part of the screen; any other touch drags the camera
local stickGui = Instance.new("ScreenGui")
stickGui.Name = "MB_Thumbstick"; stickGui.ResetOnSpawn = false; stickGui.DisplayOrder = 5; stickGui.IgnoreGuiInset = true
stickGui.Parent = lp:WaitForChild("PlayerGui")
local K = UIKit.Colors
local base = UIKit.new("Frame", {Size = UDim2.fromOffset(132, 132), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = K.Navy, BackgroundTransparency = 0.45, Visible = false}, stickGui)
UIKit.new("UICorner", {CornerRadius = UDim.new(1, 0)}, base)
UIKit.stroke(base, K.Ink, 3)
local ring = UIKit.new("Frame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1}, base)
UIKit.new("UICorner", {CornerRadius = UDim.new(1, 0)}, ring); UIKit.stroke(ring, K.Turquoise, 2).Transparency = 0.35
local knob = UIKit.new("Frame", {Size = UDim2.fromOffset(60, 60), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = K.Turquoise}, base)
UIKit.new("UICorner", {CornerRadius = UDim.new(1, 0)}, knob); UIKit.stroke(knob, K.Ink, 3)
local shine = UIKit.new("Frame", {Size = UDim2.new(0.6, 0, 0, 6), Position = UDim2.new(0.2, 0, 0, 9), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.5}, knob)
UIKit.new("UICorner", {CornerRadius = UDim.new(1, 0)}, shine)
local stickTouch, stickOrigin, lookTouches = nil, nil, {}
local RADIUS = 52
UIS.TouchStarted:Connect(function(t, gp)
	if gp then return end
	Bus.State.isTouch = true
	local v = camera.ViewportSize
	local p = Vector2.new(t.Position.X, t.Position.Y)
	if not stickTouch and p.X < v.X * 0.42 and p.Y > v.Y * 0.35 then
		stickTouch, stickOrigin = t, p
		base.Position = UDim2.fromOffset(p.X, p.Y + 36 * 0) ; base.Visible = true
		knob.Position = UDim2.fromScale(0.5, 0.5)
	else
		lookTouches[t] = p
	end
end)
UIS.TouchMoved:Connect(function(t)
	if t == stickTouch then
		local d = Vector2.new(t.Position.X, t.Position.Y) - stickOrigin
		if d.Magnitude > RADIUS then
			stickOrigin += d.Unit * (d.Magnitude - RADIUS)  -- the stick follows the thumb
			base.Position = UDim2.fromOffset(stickOrigin.X, stickOrigin.Y)
			d = d.Unit * RADIUS
		end
		knob.Position = UDim2.new(0.5, d.X, 0.5, d.Y)
		input.stick = Vector2.new(d.X, -d.Y) / RADIUS
	elseif lookTouches[t] then
		local p = Vector2.new(t.Position.X, t.Position.Y)
		local other
		for o, op in pairs(lookTouches) do if o ~= t then other = op end end
		if other then   -- two fingers = pinch zoom
			local before, after = (lookTouches[t] - other).Magnitude, (p - other).Magnitude
			if before > 10 then input.zoom = math.clamp(input.zoom * before / math.max(after, 1), 0.05, CAM.ZoomMax) end
		else
			input.look += (p - lookTouches[t]) * CAM.TouchSens
		end
		lookTouches[t] = p; lastLook = os.clock()
	end
end)
UIS.TouchEnded:Connect(function(t)
	if t == stickTouch then stickTouch = nil; input.stick = Vector2.zero; base.Visible = false end
	lookTouches[t] = nil
end)

------------------------------------------------------------------ the controller
local ctl = nil   -- current shark state
local camYaw, camPitch = 0, math.rad(CAM.PitchDefault)
local camPos = nil
local shake = 0
local camYawKick = false

local function bind(model)
	local root = model:WaitForChild("SwimRoot", 10); if not root then return end
	local lv, ao = root:WaitForChild("SwimVel"), root:WaitForChild("SwimAlign")
	local look = root.CFrame.LookVector
	ctl = {model = model, root = root, lv = lv, ao = ao,
		yaw = yawOf(look), pitch = math.asin(math.clamp(look.Y, -1, 1)), roll = 0, yawRate = 0, pitchRate = 0,
		speed = 0, vel = Vector3.zero, dartT = 0, dartReady = 0,
		length = model:GetAttribute("Length") or 8, height = model:GetAttribute("Height") or 3}
	camYaw = ctl.yaw
	camPos = nil
	ctl.speed = 0; ctl.vel = Vector3.zero   -- spawn still: you swim when you want to
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = root
end
lp.CharacterAdded:Connect(function(m) task.defer(bind, m) end)
if lp.Character then task.defer(bind, lp.Character) end
Correct.OnClientEvent:Connect(function(cf)
	if ctl then   -- the server put us back: resync the heading so the controller doesn't fight it
		ctl.vel = Vector3.zero; ctl.speed = 0; ctl.yawRate = 0; ctl.pitchRate = 0
		local l = cf.LookVector
		ctl.yaw = yawOf(l); ctl.pitch = math.asin(math.clamp(l.Y, -1, 1))
	end
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true
local function refreshFilter()
	local list = {workspace:FindFirstChild("MB_Players")}
	if workspace:FindFirstChild("MB_ImportTest") then table.insert(list, workspace.MB_ImportTest) end
	rayParams.FilterDescendantsInstances = list
end
refreshFilter()

local function moveVector()
	local v = input.stick
	if v.Magnitude < 0.08 then v = input.pad end
	if v.Magnitude < 0.08 then v = keyVec() end
	if v.Magnitude > 1 then v = v.Unit end
	return v
end

RunService:BindToRenderStep("MB_Swim", Enum.RenderPriority.Input.Value + 1, function(dt)
	if not ctl or not ctl.root.Parent then return end
	dt = math.min(dt, 1 / 20)
	local c = ctl
	local root = c.root
	local evo = C.Evolutions[c.model:GetAttribute("Evo") or 1]
	local turn = math.rad(evo.turn)
	local now = os.clock()

	-- camera look input
	if RunService:IsStudio() and lp:GetAttribute("DebugCamTurn") then   -- Studio test hook: swing the camera N degrees
		camYaw += math.rad(lp:GetAttribute("DebugCamTurn")); lp:SetAttribute("DebugCamTurn", nil); lastLook = now
	end
	if input.padLook and input.padLook.Magnitude > 0 then input.look += input.padLook * CAM.PadSens * dt; lastLook = now end
	if input.look.Magnitude > 0 then
		camYaw -= math.rad(input.look.X)
		camPitch = math.clamp(camPitch - math.rad(input.look.Y), math.rad(CAM.PitchMin), math.rad(CAM.PitchMax))
		input.look = Vector2.zero
	end

	-- desired direction (camera-relative); no input = glide to a stop
	local mv = moveVector()
	local swimPitch = camPitch - math.rad(CAM.PitchDefault)     -- default camera = level swimming
	local dYaw, dPitch, throttle
	-- owner 10 Nov: input is CAMERA-relative. W = away from the camera, S = TOWARD the camera, A/D = camera left/right.
	-- If S points behind the shark (camera behind it) it is a BRAKE (then slow reverse), never a turn.
	-- If S points ahead of the shark (you look at its face) the shark just swims at you.
	local braking = false
	if mv.Magnitude > 0.1 then
		local basis = CFrame.fromEulerAnglesYXZ(swimPitch, camYaw, 0)
		local flatCam = CFrame.fromEulerAnglesYXZ(0, camYaw, 0)
		-- forward part follows the camera's tilt (look down = dive); the toward-camera part stays level
		local d = (mv.Y >= 0 and basis.LookVector * mv.Y or flatCam.LookVector * mv.Y) + flatCam.RightVector * mv.X
		if d.Magnitude < 1e-3 then d = basis.LookVector end
		d = d.Unit
		local head = Vector3.new(-math.sin(c.yaw), 0, -math.cos(c.yaw))
		local dFlat = Vector3.new(d.X, 0, d.Z)
		local along = dFlat.Magnitude > 1e-3 and dFlat.Unit:Dot(head) or 1
		if mv.Y < -0.3 and along < SW.BackDot then
			braking = true
			dYaw = c.yaw
			dPitch = c.pitch * 0.5
			throttle = 0
		else
			dYaw = yawOf(d); dPitch = math.asin(math.clamp(d.Y, -1, 1))
			throttle = math.clamp(mv.Magnitude, 0, 1)
		end
	else
		-- owner 10 Nov: no input = stop. Keep the heading, level out, glide to a halt (looking around doesn't move you)
		dYaw = c.yaw
		dPitch = 0
		throttle = 0
	end
	dPitch = math.clamp(dPitch, -math.rad(SW.PitchMax), math.rad(SW.PitchMax))

	-- turn with a rate limit + agility (small = twitchy, big = wide)
	local yawErr = wrap(dYaw - c.yaw)
	local tYawRate = math.clamp(yawErr * 5, -turn, turn)
	c.yawRate += (tYawRate - c.yawRate) * damp(evo.agility, dt)
	c.yaw = wrap(c.yaw + c.yawRate * dt)
	local pTurn = turn * SW.PitchTurnFrac
	local tPitchRate = math.clamp((dPitch - c.pitch) * 4, -pTurn, pTurn)
	c.pitchRate += (tPitchRate - c.pitchRate) * damp(evo.agility, dt)
	c.pitch = math.clamp(c.pitch + c.pitchRate * dt, -math.rad(SW.PitchMax), math.rad(SW.PitchMax))
	local tRoll = math.clamp(c.yawRate / turn, -1, 1) * math.rad(SW.BankMax)   -- bank INTO the turn
	c.roll += (tRoll - c.roll) * damp(6, dt)
	myYawRate = c.yawRate

	-- speed: cruise..top, DART burst
	if dartQueued then
		dartQueued = false
		if now >= c.dartReady then
			c.dartReady = now + SW.DartCooldown; c.dartT = SW.DartTime
			Bus.State.dartReadyAt = c.dartReady; Bus.State.dartCooldown = SW.DartCooldown
			Action:FireServer("Dart")
			shake = math.max(shake, 0.25)
		end
	end
	local target = 0
	if throttle > 0.05 then target = evo.cruise + (evo.top - evo.cruise) * math.clamp((throttle - 0.3) / 0.7, 0, 1) end
	if c.dartT > 0 then
		c.dartT -= dt
		local k = math.clamp(c.dartT / SW.DartTime, 0, 1)
		target = evo.top * (1 + (SW.DartMult - 1) * (k ^ 0.6))
		c.speed = math.max(c.speed, target)
	end
	-- owner 10 Nov: S brakes first; once you've stopped, keep holding S = swim slowly BACKWARDS (no turning)
	if braking and c.dartT <= 0 then
		if c.speed <= 0.6 then c.reversing = true end
		if c.reversing then target = -evo.cruise * SW.ReverseFrac end
	else
		c.reversing = false
	end
	local rate
	if c.reversing then rate = SW.ReverseAccel
	elseif target < c.speed then rate = braking and SW.BrakeDecel or SW.StopDecel
	else rate = evo.accel * 0.5 end
	c.speed += (target - c.speed) * damp(rate, dt)
	if target == 0 and math.abs(c.speed) < 0.3 then c.speed = 0 end

	local orient = CFrame.fromEulerAnglesYXZ(c.pitch, c.yaw, 0)
	local fwd = orient.LookVector
	-- momentum + glide: velocity bends toward where the nose points
	c.vel = c.vel:Lerp(fwd * c.speed, damp(evo.grip, dt))

	-- world: bounce off rocks (never stuck, never through), sea floor, surface, border current
	local pos = root.Position
	local radius = root.Size.X * 0.5
	local step = c.vel * dt
	local hit = workspace:Spherecast(pos, radius * 0.9, step + (step.Magnitude > 0 and step.Unit * radius * 0.2 or Vector3.zero), rayParams)
	local nose = workspace:Raycast(pos, fwd * (c.length * 0.5 + 0.5) + step, rayParams)
	local h = hit or nose
	if h then
		local n = h.Normal
		local vn = c.vel:Dot(n)
		if vn < 0 then
			if -vn > SW.BonkSpeed then shake = math.max(shake, math.clamp(-vn / 60, 0.15, 0.6)); Sounds.Play("HurtBonk", root) end
			c.vel = c.vel - (1 + SW.Restitution) * vn * n
			c.speed *= 0.75
			-- steer the nose away from the wall so we never grind along it
			local away = (fwd - 2 * fwd:Dot(n) * n)
			if away.Magnitude > 0.01 then
				local ay = yawOf(away)
				c.yaw = c.yaw + wrap(ay - c.yaw) * 0.35
				c.pitch = c.pitch + (math.asin(math.clamp(away.Y, -1, 1)) - c.pitch) * 0.35
			end
		end
	end
	local floor = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -300, 0), rayParams)
	if floor then
		local clear = c.height * 0.5 + SW.FloorClear
		local gap = pos.Y - floor.Position.Y
		if gap < clear then
			c.vel = Vector3.new(c.vel.X, math.max(c.vel.Y, (clear - gap) * 10), c.vel.Z)
			if c.pitch < 0 then c.pitch *= 0.85 end
		end
	end
	if pos.Y > SW.Ceiling then
		c.vel = Vector3.new(c.vel.X, math.min(c.vel.Y, -(pos.Y - SW.Ceiling) * 4), c.vel.Z)
		if c.pitch > 0 then c.pitch *= 0.85 end
	end
	local flat = Vector3.new(pos.X - SW.MapCentre.X, 0, pos.Z - SW.MapCentre.Z)
	local r = flat.Magnitude
	if r > SW.BorderSoft then
		local inward = -flat.Unit
		local k = math.clamp((r - SW.BorderSoft) / (SW.BorderHard - SW.BorderSoft), 0, 1.5)
		c.vel += inward * SW.BorderPush * k * dt * 4                -- the soft push-back current
		local out = c.vel:Dot(-inward)
		if r > SW.BorderHard and out > 0 then c.vel -= -inward * out end
		c.yaw = c.yaw + wrap(yawOf(inward) - c.yaw) * damp(0.6 * k, dt)  -- gently turn home
	end

	-- never stuck: if the body barely moves while we push, swing the heading away and lift a little
	local real = root.AssemblyLinearVelocity.Magnitude
	if c.vel.Magnitude > 6 and real < c.vel.Magnitude * 0.3 then c.stuckT = (c.stuckT or 0) + dt else c.stuckT = 0 end
	if c.stuckT > 0.45 then
		c.stuckT = 0
		c.yaw = wrap(c.yaw + math.pi * 0.75 * (math.random() < 0.5 and 1 or -1))
		c.pitch = math.rad(20)
		c.vel = CFrame.fromEulerAnglesYXZ(c.pitch, c.yaw, 0).LookVector * c.speed * 0.6 + Vector3.new(0, 6, 0)
		camYawKick = true
	end
	c.lv.VectorVelocity = c.vel
	c.ao.CFrame = CFrame.fromEulerAnglesYXZ(c.pitch, c.yaw, c.roll)
	Bus.State.heading = c.yaw; Bus.State.camYaw = camYaw; Bus.State.pos = pos; Bus.State.speed = c.vel.Magnitude
end)

-- the chase camera (after physics)
RunService:BindToRenderStep("MB_Camera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not ctl or not ctl.root.Parent then return end
	dt = math.min(dt, 1 / 20)
	local c = ctl
	local now = os.clock()
	camera.CameraType = Enum.CameraType.Scriptable
	local dbg = RunService:IsStudio() and lp:GetAttribute("DebugCam")
	if dbg and dbg ~= "" then   -- Studio-only check views (side / top / front / back) for screenshots
		local p, L = c.root.Position, c.length
		local r = c.root.CFrame
		local off = ({side = r.RightVector * L * 1.6, top = Vector3.new(0, L * 2.2, 0) + r.LookVector * 0.01, front = r.LookVector * L * 1.8, back = -r.LookVector * L * 1.8 + Vector3.new(0, L * 0.4, 0)})[dbg] or r.RightVector * L * 1.6
		camera.CFrame = CFrame.lookAt(p + off, p)
		return
	end
	-- swing behind the shark only when swimming forward-ish; holding S toward the camera (looking at its face) keeps the view (owner 10 Nov)
	if now - lastLook > CAM.RecenterDelay and c.speed > 2 and moveVector().Y > -0.3 then   -- (not while stopped or reversing)
		camYaw = camYaw + wrap(c.yaw - camYaw) * damp(CAM.YawLag, dt)
		if moveVector().Magnitude < 0.1 and now - lastLook > CAM.RecenterDelay * 2.5 then
			camPitch += (math.rad(CAM.PitchDefault) - camPitch) * damp(CAM.PitchReturn, dt)
		end
	end
	local L = c.length
	-- zoom is clamped in STUDS for this body: every size can zoom right up behind its tail (owner 10 Nov)
	local def = CAM.DistBase + CAM.DistPerStud * L
	local minD, maxD = L * CAM.ZoomInTail + CAM.ZoomInGap, def * CAM.ZoomMax
	input.zoom = math.clamp(input.zoom, minD / def, maxD / def)
	local dist = def * input.zoom
	-- aim at the BODY (owner 10 Nov: the camera sat high above big sharks because the aim point rose with length)
	local targetPt = c.root.Position + Vector3.new(0, c.height * CAM.Height, 0)
	local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
	local want = targetPt - rot.LookVector * dist
	-- close zoom: never put the camera INSIDE our own body (ellipsoid test in the shark's space, push back along the view)
	local rcf = c.root.CFrame
	local rad = Vector3.new(c.height * 0.6 + 1.2, c.height * 0.55 + 1.2, L * 0.5 + 1.2)
	for _ = 1, 24 do
		local p = rcf:PointToObjectSpace(want)
		if (p.X / rad.X) ^ 2 + (p.Y / rad.Y) ^ 2 + (p.Z / rad.Z) ^ 2 >= 1 then break end
		dist += math.max(0.6, L * 0.05)
		want = targetPt - rot.LookVector * dist
	end
	local block = workspace:Raycast(targetPt, want - targetPt, rayParams)
	if block then want = block.Position + block.Normal * 1.2 end
	if not camPos then camPos = want end
	camPos = camPos:Lerp(want, damp(CAM.PosLag, dt))
	local cf = CFrame.lookAt(camPos, targetPt)
	if shake > 0 then
		shake = math.max(0, shake - dt * 1.6)
		local s = shake * 0.5
		cf = cf * CFrame.Angles((math.random() - 0.5) * s * 0.1, (math.random() - 0.5) * s * 0.1, 0)
	end
	camera.CFrame = cf
	local fovT = CAM.Fov + (CAM.DartFov - CAM.Fov) * math.clamp(c.dartT / SW.DartTime, 0, 1)
	camera.FieldOfView += (fovT - camera.FieldOfView) * damp(10, dt)
end)
