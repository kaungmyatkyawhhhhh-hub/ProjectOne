-- MEGA BITE ability VFX (10 Nov night shift). Sprites: ChatGPT VFX sheet 1 (black bg, keyed to alpha), Art/VFX/abilities.
-- AbilityVFX.OnMarker(shark, clip, marker) is called from MB_SharkKeys on every animation marker (same cues as the sounds).
-- Also: AbilityVFX.Evolve(model), .Bank(position), .EatPop(position, size).
local Debris = game:GetService("Debris")
local T = {
	ring_thin = 83866332610588, ring_thick = 87458996729789, star4 = 109154755081516, orb = 128302474559829,
	speedlines = 116188251198483, streak = 83479264930084, splash = 134231021554173, bubbles = 125800378157946,
	impact = 88743497712648, slash = 134821009910681, foam = 88139446405144, swirl = 77893868392128,
	beam = 73004657985963, sparkletrail = 86182420537127, ripple = 128865738794532, flare = 119101480444141,
}
local function id(n) return "rbxassetid://" .. n end
task.spawn(function()
	local list = {}
	for _, n in pairs(T) do table.insert(list, id(n)) end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(list) end)
end)
local NS, NR, KP = NumberSequence.new, NumberRange.new, NumberSequenceKeypoint.new
local CS = ColorSequence.new

local M = {}

-- one anchored invisible holder per effect, cleaned up by Debris
local function holder(cf, life)
	local p = Instance.new("Part")
	p.Name = "MB_FX"; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2); p.CFrame = cf
	p.Parent = workspace
	Debris:AddItem(p, life or 3)
	return p
end

-- emit n sprites from an attachment. o: tex, size {a,b} (start,end studs), life {min,max}, speed {min,max},
-- color, light (LightEmission), trans {start,end}, rot (random start rotation), spin, spread, accel, orient, drag, n, delay, squash
local function emit(parent, o)
	local a = Instance.new("Attachment"); a.Parent = parent
	if o.offset then a.Position = o.offset end
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false; e.Rate = 0; e.LightInfluence = 0; e.LockedToPart = o.locked or false
	e.Texture = id(T[o.tex])
	local s0, s1 = o.size[1], o.size[2]
	local sm = o.sizeMid
	e.Size = sm and NS({KP(0, s0), KP(sm[1], sm[2]), KP(1, s1)}) or NS({KP(0, s0), KP(1, s1)})
	local t0, t1 = (o.trans or {0, 1})[1], (o.trans or {0, 1})[2]
	e.Transparency = NS({KP(0, t0), KP(o.hold or 0.55, t0 + (t1 - t0) * 0.25), KP(1, t1)})
	e.Lifetime = NR((o.life or {0.5})[1], (o.life or {0.5, 0.5})[2] or (o.life or {0.5})[1])
	e.Speed = NR((o.speed or {0})[1], (o.speed or {0, 0})[2] or (o.speed or {0})[1])
	e.Color = o.color and (typeof(o.color) == "ColorSequence" and o.color or CS(o.color)) or CS(Color3.new(1, 1, 1))
	e.LightEmission = o.light or 0.5
	e.Rotation = o.rot and NR(0, 360) or NR(0, 0)
	e.RotSpeed = o.spin and NR(-o.spin, o.spin) or NR(0, 0)
	e.SpreadAngle = Vector2.new(o.spread or 0, o.spread or 0)
	e.Acceleration = o.accel or Vector3.zero
	e.Drag = o.drag or 0
	e.EmissionDirection = o.dir or Enum.NormalId.Front
	e.Orientation = o.orient or Enum.ParticleOrientation.FacingCamera
	if o.squash then e.Squash = NS(o.squash) end
	e.ZOffset = o.z or 0
	e.Parent = a
	local function go() e:Emit(o.n or 1) end
	if o.delay and o.delay > 0 then task.delay(o.delay, go) else go() end
	return e
end

-- shark geometry from its bones (works for every MBShark rig: Root/Spine0..7/Jaw)
local function geo(shark)
	local function bone(n) return shark:FindFirstChild(n, true) end
	local head, tail, jaw = bone("Spine0"), bone("Spine7"), bone("Jaw")
	local mesh = shark:FindFirstChildWhichIsA("MeshPart", true)
	local size = mesh and mesh.Size.X or 10
	if not (head and tail) then
		local cf = shark:GetPivot()
		return {pos = cf.Position, fwd = cf.LookVector, nose = cf.Position + cf.LookVector * size * 0.4, tail = cf.Position - cf.LookVector * size * 0.4, size = size, mouth = cf.Position}
	end
	local fwd = (head.WorldPosition - tail.WorldPosition).Unit
	local nose = head.WorldPosition + fwd * size * 0.22
	local mouth = (jaw and jaw.WorldPosition or head.WorldPosition) + fwd * (shark:GetAttribute("BiteReach") or size * 0.19)
	return {pos = head.WorldPosition, fwd = fwd, nose = nose, mouth = mouth, tail = tail.WorldPosition - fwd * size * 0.12, size = size}
end
-- a CFrame whose Front (look) points along d
local function along(p, d) return CFrame.lookAt(p, p + d) end

local GOLD = Color3.fromRGB(255, 214, 90)
local CYAN = Color3.fromRGB(110, 240, 255)
local ORANGE = Color3.fromRGB(255, 150, 60)

local FX = {}
-- DART (Minnow): a quick white speed streak + bubbles off the tail, tiny speed lines at the nose
function FX.Whoosh(g)
	local h = holder(along(g.tail, -g.fwd), 2)
	emit(h, {tex = "streak", n = 3, size = {g.size * 0.5, g.size * 0.2}, life = {0.25, 0.4}, speed = {g.size * 1.2, g.size * 2}, spread = 8,
		orient = Enum.ParticleOrientation.VelocityParallel, color = Color3.fromRGB(200, 235, 255), light = 0.6, trans = {0.1, 1}})
	emit(h, {tex = "bubbles", n = 4, size = {g.size * 0.12, g.size * 0.22}, life = {0.6, 1.0}, speed = {g.size * 0.3, g.size * 0.8}, spread = 35, rot = true,
		accel = Vector3.new(0, g.size * 0.8, 0), drag = 2, light = 0.2, trans = {0.1, 1}})
	local n = holder(along(g.nose, g.fwd), 1)
	emit(n, {tex = "speedlines", n = 1, size = {g.size * 0.35, g.size * 0.6}, life = {0.18}, light = 0.6, trans = {0.2, 1}, rot = true})
end
-- FRENZY (Piranha): every chomp = an orange bite crescent + comic impact star at the mouth
local function chomp(g, k)
	local h = holder(along(g.mouth, g.fwd), 1.5)
	emit(h, {tex = "slash", n = 1, size = {g.size * 0.45, g.size * 0.7}, life = {0.22}, rot = true, light = 0.55, trans = {0, 1}, hold = 0.4})
	emit(h, {tex = "impact", n = 1, size = {g.size * 0.25, g.size * 0.55}, life = {0.2}, rot = true, spin = 90, light = 0.6, trans = {0, 1}, delay = 0.03})
	emit(h, {tex = "star4", n = 5, size = {g.size * 0.12, 0}, life = {0.25, 0.45}, speed = {g.size * 0.8, g.size * 1.6}, spread = 70, rot = true,
		color = ORANGE, light = 0.8, drag = 4, trans = {0, 1}})
end
FX.Snap = function(g, clip) if clip == "Frenzy" then chomp(g) end end
FX.Gulp = function(g, clip) if clip == "Frenzy" then chomp(g) end end
FX.Chomp = function(g) chomp(g) end
-- TORPEDO (Barracuda): ring punched at the nose, radial speed lines, a long blue streak trail behind
function FX.Launch(g)
	local h = holder(along(g.nose, g.fwd), 2.5)
	emit(h, {tex = "ring_thick", n = 1, size = {g.size * 0.2, g.size * 0.9}, life = {0.35}, speed = {0.01}, orient = Enum.ParticleOrientation.VelocityPerpendicular,
		color = Color3.fromRGB(150, 210, 255), light = 0.6, trans = {0, 1}, hold = 0.3})
	emit(h, {tex = "speedlines", n = 1, size = {g.size * 0.5, g.size * 1.1}, life = {0.3}, rot = true, light = 0.6, trans = {0.1, 1}})
	local t = holder(along(g.tail, -g.fwd), 2.5)
	for i = 0, 4 do
		emit(t, {tex = "streak", n = 2, size = {g.size * 0.6, g.size * 0.25}, life = {0.3, 0.45}, speed = {g.size * 0.4, g.size * 0.9}, spread = 4,
			orient = Enum.ParticleOrientation.VelocityParallel, color = Color3.fromRGB(120, 190, 255), light = 0.7, trans = {0.1, 1}, delay = i * 0.07})
	end
	emit(t, {tex = "bubbles", n = 6, size = {g.size * 0.08, g.size * 0.16}, life = {0.7, 1.1}, speed = {g.size * 0.2, g.size * 0.6}, spread = 40, rot = true,
		accel = Vector3.new(0, g.size * 0.6, 0), drag = 2, light = 0.2, trans = {0.1, 1}})
end
-- SHARK SENSE (Reef Shark): two flat cyan sonar rings sweep out around the shark + a glint at the eye
function FX.Ping(g)
	local h = holder(CFrame.new(g.pos) * CFrame.Angles(math.rad(90), 0, 0), 3)   -- Front = up: rings lie flat
	for i = 0, 1 do
		emit(h, {tex = "ring_thin", n = 1, size = {g.size * 0.3, g.size * 6}, life = {1.1}, speed = {0.01}, orient = Enum.ParticleOrientation.VelocityPerpendicular,
			dir = Enum.NormalId.Front, color = CYAN, light = 0.8, trans = {0, 1}, hold = 0.2, delay = i * 0.35})
	end
	emit(holder(along(g.pos, g.fwd), 1), {tex = "star4", n = 1, size = {g.size * 0.1, g.size * 0.35}, sizeMid = {0.3, g.size * 0.4}, life = {0.35}, color = CYAN, light = 1, trans = {0, 1}})
end
-- HAMMER RAM: a big comic impact + thick shock ring + foam at the hammer
function FX.Ram(g)
	local h = holder(along(g.nose + g.fwd * g.size * 0.05, g.fwd), 2.5)
	emit(h, {tex = "impact", n = 1, size = {g.size * 0.3, g.size * 0.9}, life = {0.28}, rot = true, spin = 60, color = Color3.fromRGB(255, 230, 120), light = 0.7, trans = {0, 1}})
	emit(h, {tex = "ring_thick", n = 1, size = {g.size * 0.25, g.size * 1.2}, life = {0.4}, speed = {0.01}, orient = Enum.ParticleOrientation.VelocityPerpendicular,
		color = Color3.fromRGB(255, 240, 170), light = 0.6, trans = {0, 1}, hold = 0.3})
	emit(h, {tex = "foam", n = 3, size = {g.size * 0.25, g.size * 0.5}, life = {0.5, 0.8}, speed = {g.size * 0.3, g.size * 0.8}, spread = 60, rot = true, drag = 3, light = 0.1, trans = {0.1, 1}})
	emit(h, {tex = "star4", n = 6, size = {g.size * 0.12, 0}, life = {0.3, 0.5}, speed = {g.size, g.size * 2}, spread = 80, color = GOLD, light = 0.9, drag = 5, trans = {0, 1}})
end
-- BREACH (Great White): a splash crown + foam + bubble column + a white flash, around the head
function FX.Burst(g)
	local h = holder(CFrame.new(g.nose), 3)
	emit(h, {tex = "splash", n = 1, size = {g.size * 0.4, g.size * 1.1}, life = {0.55}, light = 0.25, trans = {0, 1}, hold = 0.5})
	emit(h, {tex = "flare", n = 1, size = {g.size * 0.6, g.size * 0.1}, life = {0.25}, light = 0.9, trans = {0, 1}})
	emit(h, {tex = "foam", n = 5, size = {g.size * 0.2, g.size * 0.45}, life = {0.6, 1.0}, speed = {g.size * 0.3, g.size * 0.9}, spread = 180, rot = true, drag = 3, light = 0.1, trans = {0.1, 1}})
	emit(holder(along(g.pos, Vector3.yAxis), 3), {tex = "bubbles", n = 10, size = {g.size * 0.06, g.size * 0.14}, life = {0.8, 1.4}, speed = {g.size * 0.4, g.size * 1.2}, spread = 30, rot = true,
		accel = Vector3.new(0, g.size * 0.5, 0), drag = 1.5, light = 0.2, trans = {0.1, 1}})
end
-- TIDAL ROAR (Megalodon): three huge cyan shock rings out of the jaws + a swirl and a flare at the mouth
function FX.Roar(g)
	local h = holder(along(g.mouth, g.fwd), 3.5)
	for i = 0, 2 do
		emit(h, {tex = i == 1 and "ring_thick" or "ring_thin", n = 1, size = {g.size * 0.3, g.size * (1.6 + i * 0.5)}, life = {0.7}, speed = {g.size * 0.6},
			orient = Enum.ParticleOrientation.VelocityPerpendicular, color = CYAN, light = 0.8, trans = {0, 1}, hold = 0.25, delay = i * 0.14, drag = 1})
	end
	emit(h, {tex = "swirl", n = 1, size = {g.size * 0.3, g.size * 0.8}, life = {0.6}, rot = true, spin = 360, color = CYAN, light = 0.7, trans = {0, 1}})
	emit(h, {tex = "flare", n = 1, size = {g.size * 0.8, g.size * 0.2}, life = {0.3}, light = 1, trans = {0, 1}})
	emit(h, {tex = "bubbles", n = 10, size = {g.size * 0.05, g.size * 0.12}, life = {0.6, 1.1}, speed = {g.size * 0.8, g.size * 2}, spread = 35, rot = true, drag = 2.5, light = 0.2, trans = {0.1, 1}})
end

function M.OnMarker(shark, clip, marker)
	local f = FX[marker]
	if not f then return end
	local ok, g = pcall(geo, shark)
	if ok and g then pcall(f, g, clip) end
end

-- EVOLVE: a cyan light column + rising sparkles + a gold ring at the model (call on the client that sees it)
function M.Evolve(model)
	local cf = model:GetPivot(); local mesh = model:FindFirstChildWhichIsA("BasePart", true)
	local s = mesh and math.max(mesh.Size.X, 6) or 8
	local h = holder(CFrame.new(cf.Position), 4)
	emit(h, {tex = "beam", n = 1, size = {s * 1.2, s * 1.6}, life = {1.2}, light = 0.8, trans = {0, 1}, hold = 0.6, offset = Vector3.new(0, s * 0.3, 0)})
	emit(holder(CFrame.new(cf.Position) * CFrame.Angles(math.rad(90), 0, 0), 3), {tex = "ring_thick", n = 1, size = {s * 0.2, s * 2.2}, life = {0.8}, speed = {0.01},
		orient = Enum.ParticleOrientation.VelocityPerpendicular, color = GOLD, light = 0.8, trans = {0, 1}})
	emit(h, {tex = "star4", n = 14, size = {s * 0.12, 0}, life = {0.8, 1.4}, speed = {s * 0.4, s}, spread = 180, accel = Vector3.new(0, s * 0.8, 0), drag = 1.5, color = GOLD, light = 1, trans = {0, 1}})
	emit(h, {tex = "flare", n = 1, size = {s * 1.5, s * 0.3}, life = {0.4}, light = 1, trans = {0, 1}})
end
-- BANK: gold glow pop + sparkle trail at a bank vent
function M.Bank(pos)
	local h = holder(CFrame.new(pos), 2.5)
	emit(h, {tex = "orb", n = 1, size = {2, 6}, life = {0.45}, light = 0.9, trans = {0, 1}})
	emit(h, {tex = "star4", n = 10, size = {1.2, 0}, life = {0.6, 1.0}, speed = {6, 14}, spread = 180, drag = 3, color = GOLD, light = 1, trans = {0, 1}, rot = true})
	emit(h, {tex = "sparkletrail", n = 2, size = {3, 5}, life = {0.8}, speed = {3, 6}, spread = 40, accel = Vector3.new(0, 6, 0), rot = true, light = 0.9, trans = {0, 1}})
end
-- EAT POP: bubbles + a little white star where food was eaten
function M.EatPop(pos, size)
	size = size or 2
	local h = holder(CFrame.new(pos), 1.5)
	emit(h, {tex = "bubbles", n = 3, size = {size * 0.4, size * 0.8}, life = {0.5, 0.8}, speed = {size, size * 2}, spread = 180, rot = true, drag = 3,
		accel = Vector3.new(0, size * 2, 0), light = 0.2, trans = {0.1, 1}})
	emit(h, {tex = "star4", n = 1, size = {size * 0.6, 0}, life = {0.25}, light = 1, trans = {0, 1}})
end
return M
