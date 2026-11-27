--[[
	PedMotion (client, 2026-11-27)
	Owner: "ANIMATION MUST LOOK LIKE AN ACTUAL HUMAN GOING AROUND, NOT JUST ROTATING CHARACTER", "the npc characters
	walking animation is unnatural too", kicks / pushes / slams "ULTRA REALISTIC". Study: vault `City Legends/2026-11-27
	Research - realistic NPC animation (walk, run, push, kick).md`.

	Poses YangonStreetLife's people (Roblox's Blocky body: R15 pieces per R6 limb, anchored, moved with BulkMoveTo) from
	a set of joint angles P: a procedural walk (cadence from speed, hip swing from the stride so the planted foot doesn't
	slide, knee bend at loading and in swing, ankle roll heel to toe, pelvis bob / sway / turn, chest counter-turn, arms
	opposite with a bent elbow, head level), a run (flight phase, lean, high knee fold, bent pumping arms), a standing
	idle (weight on one leg, breathing), phone poses, and keyed actions (kick, push, shoulder slam: anticipation, strike,
	contact, follow-through, recovery; eased keys, the head and arms a little behind the body).

	Angles: pitch about X (+ = a hanging limb swings forward; + on the chest / pelvis = leans BACK), yaw about Y
	(+ = turns left), roll about Z (+ = the right side rises). Knees: + = bent (the shin goes back). Elbows: + = bent.
	Abduction ab*: + = the arm / leg out to its own side.
]]

local PedMotion = {}

local cos, sin, exp, clamp, pi = math.cos, math.sin, math.exp, math.clamp, math.pi
local TAU = 2 * pi
local KNEE_MAX, ELBOW_MAX = 1.45, 1.6

-- wrapped bump round c (t in cycles)
local function bump(t: number, c: number, w: number): number
	local d = ((t - c + 0.5) % 1) - 0.5
	return exp(-(d / w) ^ 2)
end

local CH = {
	"hipL", "kneeL", "ankleL", "abL", "hipR", "kneeR", "ankleR", "abR", "shL", "elL", "sabL", "shR", "elR", "sabR",
	"pelYaw", "pelRoll", "pelPitch", "chYaw", "chPitch", "chRoll", "nkYaw", "nkPitch", "nkRoll", "bx", "by", "bz",
}
PedMotion.CH = CH

local function blank(): { [string]: number }
	local P = {}
	for _, c in CH do
		P[c] = 0
	end
	return P
end
PedMotion.blank = blank

---------------------------------------------------------------------
-- gaits (t = cycle 0..1, the left heel strikes at 0; L = leg length in studs; v = speed studs/s)
---------------------------------------------------------------------
-- walk: 1.75-2.1 steps a second; stance 60% of the cycle; the stance foot sweeps back speed x stance time
function PedMotion.walkCadence(v: number, s: number): number
	return clamp(1.55 + 0.1 * v / s, 1.6, 2.15) -- steps a second (shorter people step a little faster: v / s)
end
function PedMotion.runCadence(v: number, s: number): number
	return clamp(2.45 + 0.03 * v / s, 2.5, 3.0)
end

local function walkP(P, t: number, v: number, cad: number, L: number, look: number)
	-- the stance foot sweeps from +A (contact) to cos(1.2 pi) A: 1.81 A x L in 0.6 of a cycle
	local cyc = cad / 2
	local A = clamp(v * 0.6 / (cyc * 1.81 * L), 0.05, 0.62)
	local k = A / 0.3 -- how big this stride is against a normal one (scales the upper body)
	for side = 0, 1 do
		local u = (t + side * 0.5) % 1
		local hip = 0.05 + A * cos(TAU * u)
		local knee = 0.3 * k * bump(u, 0.13, 0.07) + (0.75 + 0.45 * k) * bump(u, 0.72, 0.11) + 0.04
		-- the foot's own pitch: heel first (toes up) at contact, flat in stance, pointed at toe-off, up in swing
		local foot = 0.25 * bump(u, 0.0, 0.045) - 0.55 * k * bump(u, 0.6, 0.06) + 0.12 * bump(u, 0.84, 0.07)
		local ankle = foot - (hip - knee)
		if side == 0 then
			P.hipL, P.kneeL, P.ankleL = hip, knee, ankle
		else
			P.hipR, P.kneeR, P.ankleR = hip, knee, ankle
		end
	end
	local c = cos(TAU * t)
	local sn = sin(TAU * t)
	-- arms a little behind the legs (overlap), opposite to them; the elbow bends more on the forward swing
	local ca = cos(TAU * t - 0.35)
	local arm = 0.16 + 0.28 * k
	P.shL, P.shR = -arm * ca + 0.04, arm * ca + 0.04
	P.elL = 0.22 + 0.22 * math.max(0, -ca) * k
	P.elR = 0.22 + 0.22 * math.max(0, ca) * k
	P.sabL, P.sabR = 0.06, 0.06
	-- pelvis turns with the forward leg, sways over the stance foot and drops on the swing side; chest counter-turns
	P.pelYaw = -0.07 * k * c
	P.chYaw = 0.12 * k * c
	P.pelRoll = -0.045 * sn
	P.chRoll = 0.025 * sn
	P.bx = -0.045 * sn
	P.pelPitch = -0.03 * k
	P.chPitch = -0.04
	-- the head stays level and looks where it's going (it cancels the chest's turn)
	P.nkYaw = look - (P.pelYaw + P.chYaw)
	P.nkPitch = 0.02
end

local function runP(P, t: number, v: number, cad: number, L: number, look: number)
	local cyc = cad / 2
	local A = clamp(v * 0.35 / (cyc * 1.6 * L), 0.3, 0.95)
	for side = 0, 1 do
		local u = (t + side * 0.5) % 1
		local hip = 0.22 + A * cos(TAU * u)
		local knee = 0.25 + 0.55 * bump(u, 0.12, 0.07) + 1.75 * bump(u, 0.62, 0.13)
		local foot = 0.12 * bump(u, 0.0, 0.04) - 0.75 * bump(u, 0.33, 0.05) + 0.25 * bump(u, 0.75, 0.08)
		local ankle = foot - (hip - knee) - 0.2
		if side == 0 then
			P.hipL, P.kneeL, P.ankleL = hip, knee, ankle
		else
			P.hipR, P.kneeR, P.ankleR = hip, knee, ankle
		end
	end
	local c = cos(TAU * t)
	local sn = sin(TAU * t)
	local ca = cos(TAU * t - 0.45)
	P.shL, P.shR = -0.7 * ca + 0.1, 0.7 * ca + 0.1
	P.elL = 1.45 + 0.3 * math.max(0, -ca)
	P.elR = 1.45 + 0.3 * math.max(0, ca)
	P.sabL, P.sabR = 0.12, 0.12
	P.pelYaw = -0.12 * c
	P.chYaw = 0.2 * c
	P.pelRoll = -0.05 * sn
	P.bx = -0.035 * sn
	-- forward lean from the hips and the chest
	P.pelPitch = -0.14
	P.chPitch = -0.1
	P.nkYaw = look - (P.pelYaw + P.chYaw)
	P.nkPitch = 0.18 -- the head comes up against the lean
end

-- standing: weight on one leg (that knee straight, the other a little bent), breathing, a slow drift
local function idleP(P, t: number, look: number, side: number)
	local br = sin(t * 1.9)
	P.kneeL = if side > 0 then 0.18 else 0.02
	P.kneeR = if side > 0 then 0.02 else 0.18
	P.hipL = if side > 0 then 0.08 else 0
	P.hipR = if side > 0 then 0 else 0.08
	P.ankleL = -(P.hipL - P.kneeL)
	P.ankleR = -(P.hipR - P.kneeR)
	P.pelRoll = 0.05 * side
	P.chRoll = -0.03 * side
	P.bx = 0.07 * side
	P.shL = 0.04 + 0.02 * br
	P.shR = 0.04 + 0.02 * sin(t * 1.9 + 0.7)
	P.elL, P.elR = 0.18, 0.18
	P.sabL, P.sabR = 0.08, 0.08
	P.chPitch = -0.015 * br
	P.nkYaw = look
end

---------------------------------------------------------------------
-- actions: keys { time, { channel = value } }; channels not named are 0 (stand straight)
---------------------------------------------------------------------
local ACTIONS = {
	-- a kick with the right foot at a bin ~1.9 studs ahead: wind-up, strike, contact at 0.52, follow-through, settle
	kick = { dur = 1.45, contact = 0.52, keys = {
		{ 0.0, {} },
		{ 0.4, { hipR = -0.5, kneeR = 1.15, ankleR = -0.2, kneeL = 0.24, hipL = 0.06, chPitch = 0.08, pelPitch = 0.06,
			shL = 0.35, shR = -0.4, elL = 0.5, elR = 0.4, sabL = 0.25, sabR = 0.22, bz = 0.18, by = -0.14, nkPitch = -0.2 } },
		{ 0.52, { hipR = 1.15, kneeR = 0.12, ankleR = -0.45, kneeL = 0.32, hipL = 0.1, chPitch = 0.22, pelPitch = 0.1,
			shL = -0.35, shR = 0.45, elL = 0.6, elR = 0.5, sabL = 0.5, sabR = 0.4, bz = 0.05, by = -0.16, nkPitch = -0.15 } },
		{ 0.7, { hipR = 1.4, kneeR = 0.25, ankleR = -0.4, kneeL = 0.28, chPitch = 0.26, pelPitch = 0.1, shL = -0.25,
			shR = 0.3, elL = 0.5, sabL = 0.45, sabR = 0.35, by = -0.12, nkPitch = -0.05 } },
		{ 1.05, { hipR = 0.25, kneeR = 0.55, ankleR = -0.2, kneeL = 0.15, chPitch = 0.06, sabL = 0.15, sabR = 0.12,
			elL = 0.3, elR = 0.3, by = -0.05 } },
		{ 1.45, {} },
	} },
	-- a two-hand shove: sink and draw the hands to the chest, drive forward, lean in past it, arms drop, a shrug
	push = { dur = 1.75, contact = 0.47, keys = {
		{ 0.0, {} },
		{ 0.36, { by = -0.2, bz = 0.14, chPitch = 0.06, shL = 0.35, shR = 0.35, elL = 1.95, elR = 1.95, sabL = 0.18,
			sabR = 0.18, kneeL = 0.38, kneeR = 0.38, hipL = 0.18, hipR = -0.08, ankleL = 0.2, ankleR = 0.3 } },
		{ 0.48, { by = -0.12, bz = -0.38, chPitch = -0.32, pelPitch = -0.12, shL = 1.5, shR = 1.5, elL = 0.12,
			elR = 0.12, hipL = 0.38, kneeL = 0.42, ankleL = 0.05, hipR = -0.38, kneeR = 0.06, ankleR = 0.3 } },
		{ 0.72, { by = -0.1, bz = -0.42, chPitch = -0.26, pelPitch = -0.1, shL = 1.3, shR = 1.3, elL = 0.2, elR = 0.2,
			hipL = 0.32, kneeL = 0.36, hipR = -0.32, ankleR = 0.28 } },
		{ 1.05, { bz = -0.2, shL = 0.25, shR = 0.25, elL = 0.4, elR = 0.4, chPitch = -0.04, hipL = 0.12, kneeL = 0.12 } },
		-- the shrug: shoulders up, hands open out, a small head shake
		{ 1.3, { by = 0.05, shL = 0.2, shR = 0.2, elL = 1.25, elR = 1.25, sabL = 0.32, sabR = 0.32, nkYaw = 0.22 } },
		{ 1.45, { by = 0.04, shL = 0.2, shR = 0.2, elL = 1.2, elR = 1.2, sabL = 0.3, sabR = 0.3, nkYaw = -0.2 } },
		{ 1.75, {} },
	} },
	-- a shoulder / hip barge into a bin on the right while passing: lean away and dip, throw the shoulder and hip into
	-- it with the near arm swinging out, a stagger step to catch the balance
	slam = { dur = 1.35, contact = 0.4, keys = {
		{ 0.0, {} },
		{ 0.28, { pelRoll = 0.12, chRoll = 0.1, bx = -0.28, by = -0.12, sabR = 0.18, shR = -0.25, elR = 0.4, kneeL = 0.32,
			kneeR = 0.22, abL = 0.06, nkRoll = -0.06 } },
		{ 0.4, { pelRoll = -0.2, chRoll = -0.18, bx = 0.38, by = -0.14, sabR = 1.05, elR = 0.35, shR = 0.25, sabL = 0.35,
			kneeR = 0.35, hipR = 0.15, abR = 0.12, nkRoll = 0.08, nkYaw = -0.25 } },
		{ 0.65, { pelRoll = -0.1, chRoll = -0.08, bx = 0.3, sabR = 0.7, hipL = 0.38, kneeL = 0.62, ankleL = -0.2,
			abL = 0.12, sabL = 0.3, by = -0.1, nkYaw = -0.4 } },
		{ 0.95, { hipL = 0.12, kneeL = 0.22, sabR = 0.2, by = -0.04, nkYaw = -0.3 } },
		{ 1.35, {} },
	} },
}
PedMotion.ACTIONS = ACTIONS

local function ease(a: number): number
	return a * a * (3 - 2 * a)
end

-- the value of every channel at time t (seconds) of an action, eased between keys
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
	local a = ease(clamp((t - k0[1]) / (k1[1] - k0[1]), 0, 1))
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

-- overlap: the head and the arms run a little behind the body
local LAG = { nkYaw = 0.07, nkPitch = 0.07, nkRoll = 0.07, shL = 0.035, shR = 0.035, elL = 0.05, elR = 0.05, sabL = 0.035, sabR = 0.035 }
local function actionP(P, act, t: number)
	local body = blank()
	keyed(body, act, t)
	local late = blank()
	keyed(late, act, t - 0.06)
	for c, v in body do
		P[c] += if LAG[c] then late[c] else v
	end
end

---------------------------------------------------------------------
-- the skeleton (per body layout, cached) and the CFrames
---------------------------------------------------------------------
type Seg = { idx: number, c: Vector3, j: Vector3 } -- part number, rest centre, pivot to its parent (figure space, scale 1)

-- f.parts: 1 torso (upper), 2 head, 3 hair, 4 / 7 legs, 5 / 6 arms (each limb's first piece), 8+ the other pieces
-- (f.extraOf[i] = { k, i }); geo.cen / size / extra (rel = centre from the first piece), joints shoulder / hip / neck
local function rigOf(f): any
	local g = f.geo
	local r = f.rig
	if r and f.rigGeo == g then -- (one per figure, rebuilt when dress() gives it another build)
		return r
	end
	local byLimb = {}
	for idx, ex in f.extraOf do
		byLimb[ex.k] = byLimb[ex.k] or {}
		byLimb[ex.k][ex.i] = idx
	end
	local function chain(k: number): { Seg }
		local out = { { idx = k, c = g.cen[k], j = Vector3.zero } }
		local ex = byLimb[k]
		if ex and g.extra and g.extra[k] then
			for i = 2, 3 do
				local idx = ex[i]
				if idx then
					local e = g.extra[k][i]
					local c = g.cen[k] + e.rel
					-- (27 Nov, owner: "i can see their skin between the joints") the elbow / knee hinge sits on the
					-- edge the bend opens (elbow: back, knee: front), so the pieces stay joined there and only
					-- overlap inside the bend; a hand / foot hinges on its middle
					local z = if i ~= 2 then 0 elseif k == 5 or k == 6 then e.size.Z / 2 else -e.size.Z / 2
					table.insert(out, { idx = idx, c = c, j = c + Vector3.new(0, e.size.Y / 2, z) })
				end
			end
		end
		return out
	end
	local shR = g.shoulder
	local hipR = g.hip
	local torso = chain(1)
	r = {
		extraOf = f.extraOf,
		torso = torso,
		-- the pelvis: the lower torso piece if there is one (its top = the waist), else the torso block itself
		pelvis = torso[2],
		legL = chain(4), legR = chain(7), armL = chain(5), armR = chain(6),
		hipL = Vector3.new(-hipR.X, hipR.Y, hipR.Z), hipR = hipR,
		shL = Vector3.new(-shR.X, shR.Y, shR.Z), shR = shR,
		neck = g.neck, headC = g.cen[2], hipC = Vector3.new(0, hipR.Y, 0),
	}
	-- leg lengths for the stride and the body height (hip -> knee -> ankle -> sole)
	local lg = r.legL
	r.legLen = hipR.Y
	r.thigh = if lg[2] then hipR.Y - lg[2].j.Y else hipR.Y
	r.shin = if lg[3] then lg[2].j.Y - lg[3].j.Y elseif lg[2] then lg[2].j.Y else 0
	r.foot = if lg[3] then lg[3].j.Y else 0
	f.rig, f.rigGeo = r, g
	return r
end
PedMotion.rigOf = rigOf

-- the leg's reach down from the hip (studs, scale 1) for these angles
local function reach(r, hip: number, knee: number): number
	return r.thigh * cos(hip) + r.shin * cos(hip - knee) + r.foot
end

local function limb(cfs, parentCF: CFrame, parentC: Vector3, segs: { Seg }, root: Vector3, s: number, angles: { CFrame })
	-- segs[1] hangs from `root` (shoulder / hip) on the parent; each next piece from its own pivot j
	local prevCF, prevC = parentCF, parentC
	for n, sg in segs do
		local j = if n == 1 then root else sg.j
		local cf = prevCF * CFrame.new((j - prevC) * s) * angles[n] * CFrame.new((sg.c - j) * s)
		cfs[sg.idx] = cf
		prevCF, prevC = cf, sg.c
	end
end

-- P -> every part's CFrame; root = the ground point under the figure (yaw in it); hairCF = the hair from the head
function PedMotion.build(f, P, root: CFrame, s: number, hairCF: CFrame)
	local r = rigOf(f)
	local cfs = f.cfs
	local A = CFrame.Angles
	-- body: the pelvis turns about the hip centre; the legs set how high it rides
	local drop = r.legLen - math.max(reach(r, P.hipL, P.kneeL), reach(r, P.hipR, P.kneeR))
	local body = root * CFrame.new(P.bx * s, (P.by - drop) * s, P.bz * s)
	local hc = r.hipC
	local pelCF = body * CFrame.new(hc * s) * A(P.pelPitch, P.pelYaw, P.pelRoll) * CFrame.new(-hc * s)
	-- (pelCF is the pelvis frame in rest coordinates: a point x at rest sits at pelCF * x)
	local pel = r.pelvis
	local chestCF
	if pel then
		cfs[pel.idx] = pelCF * CFrame.new(pel.c * s)
		local w = pel.j
		chestCF = pelCF * CFrame.new(w * s) * A(P.chPitch, P.chYaw, P.chRoll) * CFrame.new(-w * s)
	else
		local w = Vector3.new(0, r.hipC.Y, 0)
		chestCF = pelCF * CFrame.new(w * s) * A(P.chPitch, P.chYaw, P.chRoll) * CFrame.new(-w * s)
	end
	local tc = r.torso[1].c
	cfs[r.torso[1].idx] = chestCF * CFrame.new(tc * s)
	-- head (the neck on the chest) and hair
	local n = r.neck
	local head = chestCF * CFrame.new(n * s) * A(P.nkPitch, P.nkYaw, P.nkRoll) * CFrame.new((r.headC - n) * s)
	cfs[2] = head
	cfs[3] = head * hairCF
	-- legs from the pelvis, arms from the chest (frames in rest coordinates: parent C = origin)
	limb(cfs, pelCF, Vector3.zero, r.legL, r.hipL, s, { A(P.hipL, 0, -P.abL), A(-P.kneeL, 0, 0), A(P.ankleL, 0, 0) })
	limb(cfs, pelCF, Vector3.zero, r.legR, r.hipR, s, { A(P.hipR, 0, P.abR), A(-P.kneeR, 0, 0), A(P.ankleR, 0, 0) })
	limb(cfs, chestCF, Vector3.zero, r.armL, r.shL, s, { A(P.shL, 0, -P.sabL), A(P.elL, 0, 0), A(0, 0, 0) })
	limb(cfs, chestCF, Vector3.zero, r.armR, r.shR, s, { A(P.shR, 0, P.sabR), A(P.elR, 0, 0), A(0, 0, 0) })
	workspace:BulkMoveTo(f.parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
end

-- the joint angles for a walker this frame
-- w.gait "walk" / "run" / nil (standing), w.phase (cycles), w.speed, w.look (head yaw), w.t (seconds), w.act
-- { kind, t }, w.phone "ear" / "hand" / nil, w.lean (into a turn, rad), w.twist (chest ahead into a turn)
function PedMotion.angles(w, moving: boolean): { [string]: number }
	local f = w.fig
	local r = rigOf(f)
	local P = blank()
	local look = w.look or 0
	local s = f.scale
	if w.act then
		actionP(P, ACTIONS[w.act.kind], w.act.t)
		P.nkYaw += look
	elseif moving and w.gait == "run" then
		local v = w.speedNow or w.speed
		runP(P, w.phase % 1, v, PedMotion.runCadence(v, s), r.legLen * s, look)
	elseif moving then
		local v = w.speedNow or w.speed
		walkP(P, w.phase % 1, v, PedMotion.walkCadence(v, s), r.legLen * s, look)
	else
		idleP(P, w.t or 0, look, if (w.lat or 0) > 0 then 1 else -1)
	end
	-- a phone: at the ear (right hand up, elbow folded) or in the hand (looking down at it)
	if w.phone == "ear" and not w.act then
		P.shR, P.elR, P.sabR = 0.55, 2.55, -0.32
		P.nkRoll += 0.08
	elseif w.phone == "hand" and not w.act then
		P.shR, P.elR, P.sabR = 0.38, 1.35, -0.12
		P.shL, P.elL, P.sabL = 0.3, 1.2, -0.1
		P.nkPitch -= 0.38
	end
	-- turning: the chest leads the hips, the body leans into the curve
	P.chYaw += w.twist or 0
	P.pelRoll += w.lean or 0
	-- past about 90 degrees a hinged block pokes out of the piece above it (Roblox's own walk / run bend about
	-- this far); the phone-at-ear elbow keeps its fold
	P.kneeL, P.kneeR = clamp(P.kneeL, 0, KNEE_MAX), clamp(P.kneeR, 0, KNEE_MAX)
	P.elL = clamp(P.elL, 0, ELBOW_MAX)
	if w.phone ~= "ear" or w.act then
		P.elR = clamp(P.elR, 0, ELBOW_MAX)
	end
	return P
end

return PedMotion
