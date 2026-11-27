--[[
	Cortion (client, 2026-11-27; owner: "add an npc character with a nametag named cortion ... fat belly ... wanders
	around the house ... most importantly, add an animation to everything he does"). The server (server/Cortion)
	owns him and walks him; this script draws every pose on each client by setting his R15 Motor6D Transforms after
	the animation step (no Animator on him), from the model's attributes:
	  Act   = walk | idle | pc | tv | sleep | shower | pray | window | kicked | getup
	  ActT  = server time the act started, Pose / Pose2 = where the body lies against the standing root (sit on the
	  chair, lie on the bed; Pose2 takes over after 1.4 s), Look = head turn (rad), KickDir = 1 kicked from behind.
	Walk / idle / the player's kick come from PedMotion (the street people's procedural walk, idle and kick); the
	activity poses are below. Every channel eases toward its target, so nothing snaps between poses.
	Also: the rising Zzz while he sleeps (the server makes it) and the kicker's kick (remote CortionFx, every client).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PedMotion = require(script.Parent:WaitForChild("PedMotion"))

local cos, sin, exp, clamp, pi = math.cos, math.sin, math.exp, math.clamp, math.pi
local A = CFrame.Angles
local NEAR = 110 -- animate only when the camera is this close

-- PedMotion.angles reads only rig.legLen from the figure (rigOf returns f.rig when f.geo is nil)
local function fig(legLen: number)
	return { rig = { legLen = legLen }, scale = 1 }
end

type Rig = {
	model: Model, root: BasePart, m: { [string]: Motor6D }, c0: { [string]: CFrame },
	thigh: number, shin: number, foot: number, legLen: number,
}

local JOINTS = {
	Root = "LowerTorso", Waist = "UpperTorso", Neck = "Head",
	LeftShoulder = "LeftUpperArm", LeftElbow = "LeftLowerArm", LeftWrist = "LeftHand",
	RightShoulder = "RightUpperArm", RightElbow = "RightLowerArm", RightWrist = "RightHand",
	LeftHip = "LeftUpperLeg", LeftKnee = "LeftLowerLeg", LeftAnkle = "LeftFoot",
	RightHip = "RightUpperLeg", RightKnee = "RightLowerLeg", RightAnkle = "RightFoot",
}

local function rigOf(model: Model): Rig?
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local m, c0 = {}, {}
	for j, part in JOINTS do
		local p = model:FindFirstChild(part)
		local mo = p and p:FindFirstChild(j)
		if not (mo and mo:IsA("Motor6D")) then
			return nil
		end
		m[j] = mo
		c0[j] = mo.C0
	end
	local thigh = (m.LeftHip.C1.Position - m.LeftKnee.C0.Position).Magnitude
	local shin = (m.LeftKnee.C1.Position - m.LeftAnkle.C0.Position).Magnitude
	local footPart = model:FindFirstChild("LeftFoot") :: BasePart
	local foot = m.LeftAnkle.C1.Position.Y + footPart.Size.Y / 2
	return { model = model, root = root, m = m, c0 = c0, thigh = thigh, shin = shin, foot = foot, legLen = thigh + shin + foot }
end

local function reach(r: Rig, hip: number, knee: number): number
	return r.thigh * cos(hip) + r.shin * cos(hip - knee) + r.foot
end

-- joint angles -> Transforms (PedMotion's sign rules: + pitch swings a hanging limb forward, + knee bends it back)
local function apply(r: Rig, P, pose: CFrame)
	local m = r.m
	local drop = r.legLen - math.max(reach(r, P.hipL, P.kneeL), reach(r, P.hipR, P.kneeR))
	local c = r.c0.Root
	-- pose is in root space; Transform sits in the Root joint's C0 frame
	m.Root.Transform = c:Inverse() * pose * c * CFrame.new(P.bx, P.by - drop, P.bz) * A(P.pelPitch, P.pelYaw, P.pelRoll)
	m.Waist.Transform = A(P.chPitch, P.chYaw, P.chRoll)
	m.Neck.Transform = A(P.nkPitch, P.nkYaw, P.nkRoll)
	m.LeftHip.Transform = A(P.hipL, 0, -P.abL)
	m.RightHip.Transform = A(P.hipR, 0, P.abR)
	m.LeftKnee.Transform = A(-P.kneeL, 0, 0)
	m.RightKnee.Transform = A(-P.kneeR, 0, 0)
	m.LeftAnkle.Transform = A(P.ankleL, 0, 0)
	m.RightAnkle.Transform = A(P.ankleR, 0, 0)
	m.LeftShoulder.Transform = A(P.shL, 0, -P.sabL)
	m.RightShoulder.Transform = A(P.shR, 0, P.sabR)
	m.LeftElbow.Transform = A(P.elL, 0, 0)
	m.RightElbow.Transform = A(P.elR, 0, 0)
	m.LeftWrist.Transform = A(P.wrL or 0, 0, 0)
	m.RightWrist.Transform = A(P.wrR or 0, 0, 0)
end

local function blank()
	local P = PedMotion.blank()
	P.wrL, P.wrR = 0, 0
	return P
end

-- 0 -> 1 -> 0 over [a, b] (smooth both ends)
local function hump(t: number, a: number, b: number): number
	if t <= a or t >= b then
		return 0
	end
	return 0.5 - 0.5 * cos(2 * pi * (t - a) / (b - a))
end

local function mix(P, Q, e: number)
	if e <= 0 then
		return
	end
	for k, v in Q do
		P[k] = (P[k] or 0) + (v - (P[k] or 0)) * e
	end
end

local function sit(P)
	P.hipL, P.hipR, P.kneeL, P.kneeR = 1.5, 1.5, 1.45, 1.45
	P.ankleL, P.ankleR = -0.05, -0.05
	P.abL, P.abR = 0.1, 0.1
end

---------------------------------------------------------------------
-- activity poses (t = seconds into the act)
---------------------------------------------------------------------
local POSES = {}

-- gaming: lean in, forearms on the desk, fingers going, mouse hand out right; every 9 s a win: arms up, lean back
function POSES.pc(P, t)
	sit(P)
	P.hipL, P.hipR, P.kneeL, P.kneeR = 1.25, 1.25, 1.25, 1.25 -- thighs slope down under the desk top (server sitPose matches)
	P.ankleL, P.ankleR = 0, 0
	P.chPitch, P.pelPitch = -0.05, -0.02 -- (upright: his gut keeps him off the desk, his back off the chair)
	P.shL, P.elL, P.sabL = 0.8, 0.8, -0.04
	P.shR, P.elR, P.sabR = 0.62, 0.8, 0.14
	P.elL += 0.06 * sin(t * 17)
	P.wrL = 0.12 * sin(t * 21 + 0.5)
	P.elR += 0.03 * sin(t * 6)
	P.sabR += 0.04 * sin(t * 2.3)
	P.nkPitch = 0.04 + 0.03 * sin(t * 0.9)
	P.nkYaw = 0.06 * sin(t * 0.6)
	local u = t % 9
	mix(P, { shL = 2.75, shR = 2.75, elL = 0.35, elR = 0.35, sabL = 0.45, sabR = 0.45, chPitch = 0.16, nkPitch = 0.25, wrL = 0 }, hump(u, 6.0, 7.6))
	P.by = 0.04 * sin(t * 30) * hump(u, 6.0, 7.6)
end

-- watching TV: slumped back, hands on the belly, head to the screen; a laugh every 11 s
function POSES.tv(P, t, look)
	sit(P)
	P.kneeL, P.kneeR = 1.15, 1.15 -- shins slope forward, clear of the couch front (server sitPose matches)
	P.ankleL, P.ankleR = -0.3, -0.3
	P.pelPitch, P.chPitch = 0.04, 0.1 -- (a little slumped; more put his head through the wall behind the couch)
	-- hands resting on top of the gut (not in it)
	P.shL, P.shR, P.elL, P.elR = 0.55, 0.55, 0.95, 0.95
	P.sabL, P.sabR = -0.16, -0.16
	P.chYaw = look * 0.25
	P.nkYaw = look * 0.75 + 0.05 * sin(t * 0.4)
	P.chPitch += 0.012 * sin(t * 1.6) -- breathing
	local e = hump(t % 11, 7.0, 8.8)
	P.chPitch += e * (0.08 + 0.07 * sin(t * 19))
	P.nkPitch = e * 0.22
	P.elL += e * 0.15 * sin(t * 19)
	P.elR += e * 0.15 * sin(t * 19 + 0.6)
end

-- asleep on his back: arms folded on the belly, slow breathing, head rolled to one side, a foot twitch now and then
function POSES.sleep(P, t)
	if t < 1.4 then
		sit(P)
		P.shL, P.shR, P.elL, P.elR = 0.2, 0.2, 0.6, 0.6
		return
	end
	-- straight legs tilted up a little, resting on the folded blanket at the foot of the bed (top 0.37 over the
	-- mattress), not through it
	P.hipL, P.hipR, P.kneeL, P.kneeR = 0.24, 0.22, 0.02, 0.02
	P.ankleL, P.ankleR = 0.25, 0.3
	P.abL, P.abR = 0.08, 0.06
	P.shL, P.shR, P.elL, P.elR = 0.5, 0.45, 0.9, 0.85
	P.sabL, P.sabR = -0.1, -0.08
	local br = sin(t * 1.25)
	P.chPitch = 0.035 * br
	P.shL += 0.03 * br
	P.shR += 0.03 * br
	P.nkRoll = 0.3
	P.nkYaw = 0.25
	P.ankleR += 0.25 * hump(t % 13, 9.0, 9.6)
end

-- shower: 4 s scrubbing his head under the water, 4 s scrubbing the belly in circles
function POSES.shower(P, t)
	P.kneeL, P.kneeR = 0.06, 0.1
	P.nkPitch = -0.18
	local s = sin(t * 9)
	local head = { shL = 2.45, shR = 2.45, elL = 1.5, elR = 1.5, sabL = 0.22 + 0.1 * s, sabR = 0.22 - 0.1 * s } -- (narrow: the bathroom walls are close)
	local belly = {
		shL = 0.5 + 0.14 * sin(t * 7), elL = 1.4, sabL = -0.38 + 0.12 * cos(t * 7),
		shR = 0.45 + 0.14 * sin(t * 7 + 2), elR = 1.35, sabR = -0.3 + 0.12 * cos(t * 7 + 2),
	}
	local u = t % 8
	local e = clamp((u - 3.5) * 2, 0, 1) - clamp((u - 7.5) * 2, 0, 1)
	mix(P, head, 1)
	mix(P, belly, e)
	P.chYaw = 0.1 * sin(t * 2.1)
	P.pelRoll = 0.04 * sin(t * 2.1)
end

-- kneeling at the shrine, hands together at the chest; bows to the floor every 6 s (the shikoe)
function POSES.pray(P, t)
	P.hipL, P.hipR, P.kneeL, P.kneeR = 0, 0, 1.45, 1.45
	P.ankleL, P.ankleR = -0.75, -0.75
	P.abL, P.abR = 0.08, 0.08
	P.shL, P.shR, P.elL, P.elR, P.sabL, P.sabR = 0.78, 0.78, 1.6, 1.6, -0.42, -0.42
	P.nkPitch = -0.12
	local e = hump(t % 6, 1.4, 4.6)
	e = clamp(e * 1.25, 0, 1) -- hold at the bottom
	P.pelPitch = -0.75 * e
	P.chPitch = -0.25 * e
	P.nkPitch += -0.2 * e
	P.shL += 0.65 * e
	P.shR += 0.65 * e
	P.elL -= 1.25 * e
	P.elR -= 1.25 * e
	P.sabL += 0.26 * e
	P.sabR += 0.26 * e
	P.by = -0.12 * e
end

-- at the window: hands on the sill, leaning in, looking up and down the street, weight from foot to foot
function POSES.window(P, t)
	local side = if sin(t * 0.25) > 0 then 1 else -1
	P.kneeL = if side > 0 then 0.18 else 0.03
	P.kneeR = if side > 0 then 0.03 else 0.18
	P.ankleL, P.ankleR = P.kneeL, P.kneeR
	P.pelRoll = 0.04 * side
	P.chPitch, P.pelPitch = -0.12, -0.04
	P.shL, P.shR, P.elL, P.elR, P.sabL, P.sabR = 0.78, 0.78, 0.3, 0.3, -0.04, -0.04 -- (hands on the sill top, not in the wall)
	P.wrL, P.wrR = -0.5, -0.5
	P.nkYaw = 0.6 * sin(t * 0.33) + 0.12 * sin(t * 0.9)
	P.chYaw = 0.12 * sin(t * 0.33)
	P.nkPitch = 0.05 * sin(t * 0.21) - 0.08
	local lean = hump(t % 10, 5, 8)
	P.bz = -0.06 * lean
	P.chPitch -= 0.1 * lean
end

-- getting up off the bed: sat on its edge for a moment
function POSES.getup(P)
	sit(P)
	P.chPitch = -0.1
	P.shL, P.shR, P.elL, P.elR = 0.3, 0.3, 0.5, 0.5
end

-- kicked: lurch, a stagger step, hands to where it hurt, turn round and shake a fist (dir 1 = kicked from behind)
local STUMBLE = { dur = 2.6, keys = {
	{ 0.0, {} },
	{ 0.12, { pelPitch = -0.35, chPitch = -0.3, bz = -0.3, by = -0.08, shL = 1.1, shR = -0.5, sabL = 0.6, sabR = 0.7, elL = 0.6, elR = 0.4, nkPitch = 0.3 } },
	{ 0.42, { hipR = 0.7, kneeR = 0.6, hipL = -0.2, kneeL = 0.15, pelPitch = -0.2, chPitch = -0.15, bz = -0.55, shL = 0.8, shR = 0.6, sabL = 0.9, sabR = 0.9, elL = 0.5, elR = 0.5 } },
	{ 0.8, { hipR = 0.3, kneeR = 0.3, bz = -0.45, chPitch = 0.06, shL = -0.55, shR = -0.55, elL = 1.3, elR = 1.3, sabL = 0.22, sabR = 0.22 } },
	{ 1.5, { bz = -0.3, chYaw = 0.55, pelYaw = 0.2, nkYaw = 0.7, shL = -0.4, elL = 1.2, sabL = 0.2, shR = 1.2, elR = 1.6, sabR = 0.1 } },
	{ 1.75, { bz = -0.25, chYaw = 0.55, pelYaw = 0.2, nkYaw = 0.7, shL = -0.4, elL = 1.2, sabL = 0.2, shR = 1.5, elR = 1.3, sabR = 0.1 } },
	{ 2.0, { bz = -0.2, chYaw = 0.5, pelYaw = 0.2, nkYaw = 0.65, shL = -0.4, elL = 1.2, sabL = 0.2, shR = 1.2, elR = 1.6, sabR = 0.1 } },
	{ 2.6, {} },
} }

local function keyed(P, act, t: number)
	local keys = act.keys
	local n = #keys
	if t >= keys[n][1] then
		return
	end
	local i = 1
	while i < n and keys[i + 1][1] <= t do
		i += 1
	end
	local k0, k1 = keys[i], keys[i + 1]
	local a = clamp((t - k0[1]) / (k1[1] - k0[1]), 0, 1)
	a = a * a * (3 - 2 * a)
	for c, v1 in k1[2] do
		local v0 = k0[2][c] or 0
		P[c] = (P[c] or 0) + v0 + (v1 - v0) * a
	end
	for c, v0 in k0[2] do
		if k1[2][c] == nil then
			P[c] = (P[c] or 0) + v0 * (1 - a)
		end
	end
end

function POSES.kicked(P, t, _look, dir)
	keyed(P, STUMBLE, t)
	if dir < 0 then -- kicked from the front: he rocks backwards instead
		P.bz, P.pelPitch, P.chPitch = -P.bz, -P.pelPitch * 0.6, -P.chPitch * 0.6
	end
end

---------------------------------------------------------------------
-- Cortion's per-frame state
---------------------------------------------------------------------
type State = { rig: Rig, P: { [string]: number }, pose: CFrame, phase: number, act: string?, since: number, w: any }
local st: State? = nil
local cortion: Model? = nil

-- the Zzz (made by the server while he sleeps, so every client sees the same one): three letters rising in turn
local function stepZzz(head: BasePart?, now: number)
	local zzz = head and head:FindFirstChild("CortionZzz")
	if not zzz then
		return
	end
	for i = 1, 3 do
		local l = zzz:FindFirstChild("Z" .. i) :: TextLabel?
		if not l then
			continue
		end
		local u = ((now * 0.45) + (i - 1) / 3) % 1
		l.Position = UDim2.fromScale(0.1 + 0.35 * u + 0.07 * sin(u * 9), 0.75 - 0.72 * u)
		l.Size = UDim2.fromScale(0.25 + 0.3 * u, (0.25 + 0.3 * u) * 0.7)
		l.TextTransparency = 1 - math.min(1, u * 4) * (1 - u)
	end
end

local function attach(model: Model)
	local r = rigOf(model)
	if not r then
		return
	end
	cortion = model
	st = { rig = r, P = blank(), pose = CFrame.new(), phase = 0, act = nil, since = 0, w = { fig = fig(r.legLen), t = 0, speed = 0, look = 0 } }
end

local function find()
	local m = workspace:FindFirstChild("Cortion")
	if m and m:IsA("Model") and m ~= cortion then
		attach(m)
	end
end
workspace.ChildAdded:Connect(function(c)
	if c.Name == "Cortion" then
		task.defer(function()
			-- Atomic streaming: the parts come with the model, the joints a frame later at worst
			for _ = 1, 30 do
				if rigOf(c :: Model) then
					break
				end
				task.wait(0.1)
			end
			find()
		end)
	end
end)
find()

-- the server clock, so every client is at the same point of a pose
local function serverNow(): number
	return workspace:GetServerTimeNow()
end

---------------------------------------------------------------------
-- the player's kick (every client draws it on the kicker's own character)
---------------------------------------------------------------------
type KickRig = { m: { [string]: any }, t0: number, legLen: number }
local kicks: { [Model]: KickRig } = {}

local function kickOf(char: Model): KickRig?
	local m = {}
	for _, j in { "Root", "Waist", "Neck", "LeftHip", "RightHip", "LeftKnee", "RightKnee", "LeftAnkle", "RightAnkle", "LeftShoulder", "RightShoulder", "LeftElbow", "RightElbow" } do
		local mo = char:FindFirstChild(j, true)
		-- Motor6D or the new AnimationConstraint joints: both have a Transform the Animator writes
		if not (mo and (mo:IsA("Motor6D") or mo:IsA("AnimationConstraint"))) then
			return nil -- R6 or a custom rig: no kick drawn
		end
		m[j] = mo
	end
	return { m = m, t0 = os.clock(), legLen = 2 } -- (an action pose doesn't use the leg length)
end

local fx = ReplicatedStorage:WaitForChild("CortionFx", 60)
if fx then
	(fx :: RemoteEvent).OnClientEvent:Connect(function(kind: string, a: any, b: any)
		if kind == "kick" then
			local kicker = a :: Player?
			local char = kicker and kicker.Character
			if char then
				local k = kickOf(char)
				if k then
					kicks[char] = k
				end
				-- the kicker turns to face him (only his own client moves his character)
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local target = cortion and cortion:FindFirstChild("HumanoidRootPart") :: BasePart?
				if kicker == Players.LocalPlayer and hrp and target then
					local d = target.Position - hrp.Position
					d = Vector3.new(d.X, 0, d.Z)
					if d.Magnitude > 0.1 then
						hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + d)
					end
				end
			end
		end
	end)
end

local function stepKicks()
	for char, k in kicks do
		local t = os.clock() - k.t0
		if t > PedMotion.ACTIONS.kick.dur or not char.Parent then
			kicks[char] = nil
			continue
		end
		local P = PedMotion.angles({ fig = fig(k.legLen), act = { kind = "kick", t = t } }, false)
		local m = k.m
		m.Root.Transform = CFrame.new(P.bx, P.by, P.bz) * A(P.pelPitch, P.pelYaw, P.pelRoll)
		m.Waist.Transform = A(P.chPitch, P.chYaw, P.chRoll)
		m.Neck.Transform = A(P.nkPitch, P.nkYaw, P.nkRoll)
		m.LeftHip.Transform = A(P.hipL, 0, -P.abL)
		m.RightHip.Transform = A(P.hipR, 0, P.abR)
		m.LeftKnee.Transform = A(-P.kneeL, 0, 0)
		m.RightKnee.Transform = A(-P.kneeR, 0, 0)
		m.LeftAnkle.Transform = A(P.ankleL, 0, 0)
		m.RightAnkle.Transform = A(P.ankleR, 0, 0)
		m.LeftShoulder.Transform = A(P.shL, 0, -P.sabL)
		m.RightShoulder.Transform = A(P.shR, 0, P.sabR)
		m.LeftElbow.Transform = A(P.elL, 0, 0)
		m.RightElbow.Transform = A(P.elR, 0, 0)
	end
end

---------------------------------------------------------------------
-- every frame, after the animation step (so the player's own Animate tracks are overridden during a kick)
---------------------------------------------------------------------
RunService.PreSimulation:Connect(function(dt: number)
	stepKicks()
	local s = st
	local m = cortion
	if not (s and m and m.Parent and s.rig.root.Parent) then
		return
	end
	local cam = workspace.CurrentCamera
	if (cam.CFrame.Position - s.rig.root.Position).Magnitude > NEAR then
		return
	end
	local act = m:GetAttribute("Act") or "idle"
	local now = serverNow()
	local t = now - ((m:GetAttribute("ActT") :: number?) or now)
	if act ~= s.act then
		s.act = act
		s.since = os.clock()
	end
	local look = (m:GetAttribute("Look") :: number?) or 0
	local dir = (m:GetAttribute("KickDir") :: number?) or 1

	-- target pose
	local T
	local w = s.w
	w.t = now
	if act == "walk" then
		local v = s.rig.root.AssemblyLinearVelocity
		local speed = Vector3.new(v.X, 0, v.Z).Magnitude
		local moving = speed > 0.6
		w.speed, w.speedNow = speed, speed
		if moving then
			s.phase += dt * PedMotion.walkCadence(speed, 1) / 2
		end
		w.phase = s.phase
		T = PedMotion.angles(w, moving)
		T.wrL, T.wrR = 0, 0
	elseif POSES[act] then
		T = blank()
		POSES[act](T, t, look, dir)
	else -- idle / getup
		T = PedMotion.angles(w, false)
		T.wrL, T.wrR = 0, 0
		T.nkYaw += look
	end
	-- fat man's gait: a little wider stance, arms out round the belly
	T.abL += 0.04
	T.abR += 0.04
	T.sabL += 0.1
	T.sabR += 0.1

	-- ease toward it: quick in a steady act, gentle for 0.7 s after a change (no snapping)
	local fresh = os.clock() - s.since < 0.7
	local k = if fresh then 7 elseif act == "walk" then 22 else 14
	local a = 1 - exp(-dt * k)
	local P = s.P
	for c, v in T do
		local p = P[c] or 0
		P[c] = p + (v - p) * a
	end
	local pose = (m:GetAttribute(if t >= 1.4 and m:GetAttribute("Pose2") then "Pose2" else "Pose") :: CFrame?) or CFrame.new()
	local kp = if act == "kicked" then 9 else 3.2
	s.pose = s.pose:Lerp(pose, 1 - exp(-dt * kp))
	apply(s.rig, P, s.pose)

	local head = m:FindFirstChild("Head") :: BasePart?
	stepZzz(head, os.clock())
end)
