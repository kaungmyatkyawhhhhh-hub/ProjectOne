--[[
	PedHits (client, 2026-11-26)
	Owner: "when u hit npcs, they get flinged, realism physics too". Cars knock YangonStreetLife's walkers over.

	  * every car in workspace.PlayerCars (yours and other players') is checked against this screen's walkers each
	    frame. The walkers are client-only (each player has their own), so each player's game flings its own people
	    when any car drives into them: nothing goes over the network, and everyone sees a fling.
	  * slower than RAG_KMH: the walker stumbles (pushed aside out of the car's way, a short stop).
	  * faster: the walker's 8 parts become a ragdoll (BallSocketConstraints with limits at neck, shoulders and
	    hips, hair welded to the head, sandals to the longyi), thrown with the car's speed at the contact point plus
	    some lift and a tumble, so a faster hit throws them further. A soft thud plays; your own car loses a little
	    speed. After GET_UP seconds, once still, the joints go and the walker stands up where they landed and walks
	    back to its path; if they landed somewhere bad (off the pavement level, far away, nothing under them) they
	    fade out and the walker system puts someone new elsewhere.
	  * kept in Roblox's Mild violence band (lead's decision, vault note 2026-11-26): no blood, no injury, no
	    screams, no numbers, and no "dragged under the car" (the body never collides with the car that hit it,
	    and is thrown off to the side, so it is never caught and pushed along by it).
	  * at most MAX_RAGDOLLS at once (the oldest gets up early); everything a ragdoll makes is destroyed after.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local IS_STUDIO = RunService:IsStudio()

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local StreetLife = require(script.Parent:WaitForChild("YangonStreetLife"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local PedHits = {}

-- tuning (not in Config: its size limit)
local KMH = 1 / 1.609344 -- km/h -> mph
local STUMBLE_KMH = 3 -- slower than this a car just stands against them
local RAG_KMH = 10 -- faster than this: a ragdoll
local MAX_RAGDOLLS = 6
local THROW = 1.05 -- share of the car's speed the body leaves with
local LIFT_K, LIFT_MIN, LIFT_MAX = 0.4, 10, 45 -- upward speed: x car speed, studs/s floor and cap
local SIDE_K = 0.3 -- thrown off to the side the car hit them on, clear of its path
local SPIN_K, SPIN_MAX = 0.18, 14 -- tumble (rad/s per stud/s, cap)
local MAX_THROW = 100 -- studs/s, whatever the car's speed
-- Roblox's gravity (196 studs/s2) is ~6.7x real at 3 studs a metre: a body thrown with real speeds dropped and stopped
-- in half a second (tested). Lifting part of it gives real-looking throws: about 6 m at 30 km/h, 20 m at 60 km/h.
local FLOAT = 0.6 -- share of gravity taken off the ragdoll
-- the body never touches the car that hit it (no "dragged along by the car": Mild band, lead's decision 26 Nov)
local GET_UP, GIVE_UP = 3.5, 7 -- seconds: earliest stand-up (once still), latest
local STILL = 3 -- studs/s: "still"
local STAND_TIME = 0.55 -- seconds of the stand-up blend
local FADE_TIME = 0.6
local BAD_DROP, BAD_FAR = 4, 120 -- studs from the walker's height / start that count as "landed somewhere bad"
local CAR_KEEP = 0.94 -- your car keeps this share of its speed per ragdoll hit
local CHECK_R = 320 -- only cars this near the camera are checked

-- part numbers in a YangonStreetLife figure: 1 shirt, 2 head, 3 hair, 4 longyi, 5 / 6 arms, 7 / 8 feet
local COLLIDE = { [1] = true, [2] = true, [4] = true, [5] = true, [6] = true }

type Rag = { w: any, t0: number, made: { Instance }, nocol: { Instance }, start: Vector3, phase: string, pt: number, from: { CFrame }?, to: { CFrame }? }
local rags: { Rag } = {}
local physics = PhysicalProperties.new(0.8, 0.35, 0.05, 1, 1)

local function attach(p: BasePart, at: Vector3, axis: number, made: { Instance }): Attachment
	local a = Instance.new("Attachment")
	-- the attachment's X axis (a ball socket's cone axis) along the limb: up for the neck, down for arms and hips
	a.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, axis * math.pi / 2)
	a.Parent = p
	table.insert(made, a)
	return a
end

local function socket(a: BasePart, aAt: Vector3, b: BasePart, bAt: Vector3, axis: number, cone: number, twist: number, made: { Instance })
	local s = Instance.new("BallSocketConstraint")
	s.Attachment0 = attach(a, aAt, axis, made)
	s.Attachment1 = attach(b, bAt, axis, made)
	s.LimitsEnabled = true
	s.UpperAngle = cone
	s.TwistLimitsEnabled = true
	s.TwistLowerAngle = -twist
	s.TwistUpperAngle = twist
	s.Parent = a
	table.insert(made, s)
	local n = Instance.new("NoCollisionConstraint")
	n.Part0, n.Part1 = a, b
	n.Parent = a
	table.insert(made, n)
end

local function weld(a: BasePart, b: BasePart, made: { Instance })
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = a, b
	w.Parent = a
	table.insert(made, w)
end

-- the car's own colliding parts (the physics box; skins are non-colliding), at most 12
local function carColliders(car: Model): { BasePart }
	local out = {}
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") and d.CanCollide then
			table.insert(out, d)
			if #out >= 12 then
				break
			end
		end
	end
	return out
end

local function stopRag(r: Rag)
	for _, i in r.nocol do
		i:Destroy()
	end
	table.clear(r.nocol)
	for _, i in r.made do
		i:Destroy()
	end
	table.clear(r.made)
	for _, p in r.w.fig.parts do
		p.Anchored = true
		p.CanCollide = false
		p.Massless = false
		p.CustomPhysicalProperties = nil
		p.AssemblyLinearVelocity = Vector3.zero
		p.AssemblyAngularVelocity = Vector3.zero
	end
end

local function ragdoll(w: any, car: Model, root: BasePart, at: Vector3, v: Vector3, speed: number)
	-- room for one more: the oldest gets up now
	if #rags >= MAX_RAGDOLLS then
		local old = rags[1]
		if old.phase == "rag" then
			old.t0 -= GIVE_UP
		end
		return false
	end
	local f = w.fig
	local P = f.parts
	local s = f.scale
	local made: { Instance } = {}
	-- neck, shoulders, hip; hair and sandals ride along
	socket(P[1], Vector3.new(0, 1 * s, 0), P[2], Vector3.new(0, -0.5 * s, 0), 1, 35, 40, made)
	socket(P[1], Vector3.new(-1.5 * s, 0.5 * s, 0), P[5], Vector3.new(0, 0.5 * s, 0), -1, 100, 70, made)
	socket(P[1], Vector3.new(1.5 * s, 0.5 * s, 0), P[6], Vector3.new(0, 0.5 * s, 0), -1, 100, 70, made)
	socket(P[1], Vector3.new(0, -1 * s, 0), P[4], Vector3.new(0, 0.775 * s, 0), -1, 40, 30, made)
	weld(P[2], P[3], made)
	weld(P[4], P[7], made)
	weld(P[4], P[8], made)
	-- arms clear of the longyi
	for _, k in { 5, 6 } do
		local n = Instance.new("NoCollisionConstraint")
		n.Part0, n.Part1 = P[k], P[4]
		n.Parent = P[k]
		table.insert(made, n)
	end
	-- thrown clear of the car that hit them (it often overlaps them already)
	local nocol: { Instance } = {}
	for _, c in carColliders(car) do
		for k in COLLIDE do
			local n = Instance.new("NoCollisionConstraint")
			n.Part0, n.Part1 = P[k], c
			n.Parent = P[k]
			table.insert(nocol, n)
		end
	end
	for k, p in P do
		p.CanCollide = COLLIDE[k] == true
		p.Massless = not COLLIDE[k]
		p.CustomPhysicalProperties = physics
		p.Anchored = false
	end
	for k in COLLIDE do
		local p = P[k]
		local a = Instance.new("Attachment")
		a.Parent = p
		local f = Instance.new("VectorForce")
		f.Attachment0 = a
		f.RelativeTo = Enum.ActuatorRelativeTo.World
		f.ApplyAtCenterOfMass = true
		f.Force = Vector3.new(0, p.AssemblyMass * workspace.Gravity * FLOAT, 0)
		f.Parent = p
		table.insert(made, a)
		table.insert(made, f)
	end
	-- the throw: the car's velocity where it touched, some lift, a sideways share, a tumble (head back toward the car)
	local flat = Vector3.new(v.X, 0, v.Z)
	local dir = if flat.Magnitude > 0.01 then flat.Unit else root.CFrame.LookVector
	local right = dir:Cross(Vector3.yAxis)
	local off = (at - root.Position):Dot(right)
	local side = if math.abs(off) > 0.3 then math.sign(off) elseif math.random() < 0.5 then -1 else 1
	local throw = flat * THROW + right * side * speed * SIDE_K
	if throw.Magnitude > MAX_THROW then
		throw = throw.Unit * MAX_THROW
	end
	throw += Vector3.new(0, math.clamp(speed * LIFT_K, LIFT_MIN, LIFT_MAX), 0)
	local spin = dir:Cross(Vector3.yAxis) * math.min(speed * SPIN_K, SPIN_MAX) + Vector3.new(0, (math.random() - 0.5) * 4, 0)
	local centre = P[1].Position
	for k, p in P do
		if COLLIDE[k] then
			p.AssemblyLinearVelocity = throw + spin:Cross(p.Position - centre)
			p.AssemblyAngularVelocity = spin
		end
	end
	w.held = true
	if IS_STUDIO and Players.LocalPlayer then
		Players.LocalPlayer:SetAttribute("PedHitLog", string.format("rag %.0f kmh t=%.1f", speed / Config.mphToSps(KMH), os.clock()))
	end
	table.insert(rags, { w = w, t0 = os.clock(), made = made, nocol = nocol, start = w.pos, phase = "rag", pt = 0 })
	Audio.play("thud", math.clamp(0.35 + speed / 120, 0.35, 0.8), 0.75 + math.random() * 0.1, P[1])
	if car == Driving.getModel() and Driving.slowBy then
		Driving.slowBy(CAR_KEEP)
	end
	return true
end

-- a slow nudge: pushed out of the car's way, a short stop
local function stumble(w: any, root: BasePart, v: Vector3)
	local right = root.CFrame.RightVector
	local side = if (w.pos - root.Position):Dot(right) >= 0 then 1 else -1
	local push = Vector3.new(right.X, 0, right.Z).Unit * side * 1.6 + Vector3.new(v.X, 0, v.Z) * 0.08
	w.pos += push
	if w.mode == "walk" then
		w.mode = "pause"
		w.timer = 0.9
	end
	if StreetLife.pose then
		StreetLife.pose(w, false)
	end
	w.bumpT = os.clock()
	if IS_STUDIO and Players.LocalPlayer then
		Players.LocalPlayer:SetAttribute("PedHitLog", string.format("stumble t=%.1f", os.clock()))
	end
	Audio.play("thud", 0.18, 1.1, w.fig.parts[1])
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- after the throw: stand up where they lie, or fade out if they landed somewhere bad
local function settle(r: Rag)
	local w = r.w
	local P = w.fig.parts
	local p = P[1].Position
	local folder = P[1].Parent and P[1].Parent.Parent
	rayParams.FilterDescendantsInstances = { folder :: Instance, workspace:FindFirstChild("PlayerCars") :: Instance }
	local hit = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), rayParams)
	local flatFar = Vector3.new(p.X - r.start.X, 0, p.Z - r.start.Z).Magnitude
	local bad = not hit or p ~= p or math.abs(hit.Position.Y - r.start.Y) > BAD_DROP or flatFar > BAD_FAR
	if bad then
		r.phase = "fade"
		r.pt = 0
		for _, part in P do
			part.Anchored = true
		end
		return
	end
	local from = table.create(#P)
	for k, part in P do
		from[k] = part.CFrame
	end
	stopRag(r)
	w.pos = Vector3.new(p.X, hit.Position.Y, p.Z)
	w.yaw = math.random() * math.pi * 2
	StreetLife.pose(w, false) -- fills the figure's standing CFrames (and moves it there for a moment)
	local to = table.clone(w.fig.cfs)
	workspace:BulkMoveTo(P, from, Enum.BulkMoveMode.FireCFrameChanged)
	r.from, r.to, r.phase, r.pt = from, to, "stand", 0
end

local function finish(i: number)
	local r = rags[i]
	local w = r.w
	if r.phase ~= "done" then
		stopRag(r)
	end
	if r.phase == "fade" then
		for _, part in w.fig.parts do
			part.Transparency = 0 -- (dress() sets the hair again when the figure is reused)
		end
		w.gone = true -- the walker system takes it back and puts someone new elsewhere
	elseif w.mode == "walk" then
		w.mode = "pause"
		w.timer = 0.6
	end
	w.held = nil
	table.remove(rags, i)
end

local function step(dt: number)
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	local i = 1
	while i <= #rags do
		local r = rags[i]
		local age = now - r.t0
		local P = r.w.fig.parts
		if not P[1].Parent or (P[1].Position - camPos).Magnitude > 600 then
			r.phase = "fade"
			finish(i)
			continue
		end
		if r.phase == "rag" then
			if P[1].Position.Y < -500 then
				r.phase = "fade"
				finish(i)
				continue
			end
			if age > GIVE_UP or (age > GET_UP and P[1].AssemblyLinearVelocity.Magnitude < STILL) then
				settle(r)
			end
		elseif r.phase == "stand" then
			r.pt += dt
			local a = math.clamp(r.pt / STAND_TIME, 0, 1)
			a = a * a * (3 - 2 * a)
			local cfs = table.create(#P)
			for k = 1, #P do
				cfs[k] = (r.from :: { CFrame })[k]:Lerp((r.to :: { CFrame })[k], a)
			end
			workspace:BulkMoveTo(P, cfs, Enum.BulkMoveMode.FireCFrameChanged)
			if a >= 1 then
				r.phase = "done"
				finish(i)
				continue
			end
		elseif r.phase == "fade" then
			r.pt += dt
			local a = math.clamp(r.pt / FADE_TIME, 0, 1)
			for k, part in P do
				if not (k == 3 and r.w.fig.bald) then
					part.Transparency = a
				end
			end
			if a >= 1 then
				finish(i)
				continue
			end
		end
		i += 1
	end

	-- Studio test hook: player attribute TestPedAhead = studs puts the nearest free walker that far ahead of your car
	local lp = Players.LocalPlayer
	if IS_STUDIO and lp then
		lp:SetAttribute("PedRagdolls", #rags)
		local ahead = lp:GetAttribute("TestPedAhead")
		local model = Driving.getModel()
		local root = model and model.PrimaryPart
		if type(ahead) == "number" and root then
			lp:SetAttribute("TestPedAhead", nil)
			local best, bestD = nil, math.huge
			for _, w in StreetLife.walkers() do
				local d = (w.pos - root.Position).Magnitude
				if not w.held and not w.gone and d < bestD then
					best, bestD = w, d
				end
			end
			if best then
				local fwd = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
				local at = root.Position + fwd * ahead
				rayParams.FilterDescendantsInstances = { workspace:FindFirstChild("PlayerCars") :: Instance, best.fig.model }
				local hit = workspace:Raycast(at + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), rayParams)
				best.pos = if hit then hit.Position else at - Vector3.new(0, 2, 0)
				if best.mode ~= "stand" then
					best.mode = "pause"
					best.timer = 20
				end
				StreetLife.pose(best, false)
			end
		end
	end

	-- cars against walkers
	local folder = workspace:FindFirstChild("PlayerCars")
	if not folder then
		return
	end
	local walkers = StreetLife.walkers()
	if #walkers == 0 then
		return
	end
	local stumbleSps = Config.mphToSps(STUMBLE_KMH * KMH)
	local ragSps = Config.mphToSps(RAG_KMH * KMH)
	for _, car in folder:GetChildren() do
		local root = car:IsA("Model") and car.PrimaryPart
		if root and (root.Position - camPos).Magnitude < CHECK_R then
			local v = root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			if speed >= stumbleSps then
				local cf = root.CFrame
				local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
				local right = fwd:Cross(Vector3.yAxis)
				local halfW = ((car:GetAttribute("Width") :: number?) or 7) / 2 + 0.7
				local halfL = ((car:GetAttribute("Length") :: number?) or 16) / 2 + 0.7
				for _, w in walkers do
					if not w.held and not w.gone then
						local rel = w.pos - cf.Position
						if math.abs(rel.Y) < 7 then
							local flat = Vector3.new(rel.X, 0, rel.Z)
							-- inside the car's footprint and in the way it is moving
							if math.abs(flat:Dot(fwd)) < halfL and math.abs(flat:Dot(right)) < halfW and flat:Dot(v) > 0 then
								local at = w.pos + Vector3.new(0, 2.5 * w.fig.scale, 0)
								local hv = root:GetVelocityAtPosition(at)
								local hs = Vector3.new(hv.X, 0, hv.Z).Magnitude
								if hs >= ragSps then
									if not ragdoll(w, car, root, at, hv, hs) then
										stumble(w, root, hv)
									end
								elseif not w.bumpT or os.clock() - w.bumpT > 0.6 then
									stumble(w, root, hv)
								end
							end
						end
					end
				end
			end
		end
	end
end

local started = false
function PedHits.start()
	if started or not StreetLife.walkers then
		return
	end
	started = true
	RunService.Heartbeat:Connect(step)
end

-- (for a look in Studio)
function PedHits.count(): number
	return #rags
end

return PedHits
