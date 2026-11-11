-- MB_Anim.BonePlayer: plays a shark's Blender clips by driving Bone.Transform (no Animation assets needed). Client-side.
-- BonePlayer.new(model, defaultClip, clipsModuleName)  -- clips module: ReefSharkClips (translations already in studs)
-- or {SEG=metres per spine bone, clips={...}} (translations in Blender metres, scaled by the model's real bone spacing).
local RunService = game:GetService("RunService")

local function toCF(v, ts)
	if not v then return CFrame.identity end
	local w, x, y, z = v[1], v[2], v[3], v[4]
	local n = math.sqrt(w*w + x*x + y*y + z*z)
	return CFrame.new((v[5] or 0) * ts, (v[6] or 0) * ts, (v[7] or 0) * ts, x/n, y/n, z/n, w/n)
end
local cache = {}
local function build(modName, ts)
	local key = modName .. "|" .. ts
	if cache[key] then return cache[key] end
	local raw = require(script.Parent:WaitForChild(modName))
	local clips = raw.clips or raw
	local B = {}
	for name, clip in pairs(clips) do
		local keys = {}
		for _, k in ipairs(clip.keys) do
			local pose = {}
			for b, v in pairs(k[2]) do pose[b] = toCF(v, ts) end
			table.insert(keys, {t = k[1], pose = pose})
		end
		B[name] = {loop = clip.loop, keys = keys, length = keys[#keys].t}
	end
	cache[key] = B
	return B
end

local P = {}
P.__index = P
P.Markers = {   -- seconds into the clip (sound + VFX cues)
	Swim = {SwishA = 0.02, SwishB = 0.5},
	Dart = {Whoosh = 0.033},
	Bite = {Snap = 0.28, Gulp = 0.48},
	SharkSense = {Ping = 0.067},
	Hurt = {Bonk = 0},
	HammerRam = {Ram = 0.42},
	Breach = {Burst = 0.5, Gulp = 0.62},
	TidalRoar = {Roar = 0.32},
	Frenzy = {Snap = 0.1, Gulp = 0.43, Chomp = 0.76},
	Torpedo = {Launch = 0.24},
}
P.ClipNames = {"Idle", "Swim", "Dart", "Bite", "SharkSense", "Hurt"}

function P.new(model, default, modName)
	local self = setmetatable({}, P)
	self.model = model; self.modName = modName or "ReefSharkClips"
	self.bones = {}
	self.default = default or "Idle"
	self.listeners = {}
	self:_scan()
	self.name = self.default; self.t = 0; self.loops = 0; self.fired = {}; self.fade = 0; self.fadeT = 0
	self.conn = RunService.RenderStepped:Connect(function(dt) self:_step(dt) end)
	return self
end

-- (re)collect the bones: with streaming, a model's bones can arrive after the script starts
function P:_scan()
	local n = 0
	for _, d in ipairs(self.model:GetDescendants()) do
		if d:IsA("Bone") then self.bones[d.Name] = d; n += 1 end
	end
	self.nbones = n
	if n == 0 then return false end
	local raw = require(script.Parent:WaitForChild(self.modName))
	local ts = 1
	if raw.SEG and self.bones.Spine0 and self.bones.Spine1 then
		ts = (self.bones.Spine0.WorldPosition - self.bones.Spine1.WorldPosition).Magnitude / raw.SEG
	end
	self.built = build(self.modName, math.floor(ts * 1000 + 0.5) / 1000)
	return true
end

function P:OnMarker(fn) table.insert(self.listeners, fn) end

function P:_sample(clip, t)
	local keys = clip.keys
	if t <= keys[1].t then return keys[1].pose, keys[1].pose, 0 end
	for i = 1, #keys - 1 do
		local a, b = keys[i], keys[i + 1]
		if t <= b.t then return a.pose, b.pose, (t - a.t) / (b.t - a.t) end
	end
	return keys[#keys].pose, keys[#keys].pose, 0
end

function P:_pose(name)
	local cur = {}
	local a, b, alpha = self:_sample(self.built[name], self.t)
	for bn in pairs(self.bones) do
		cur[bn] = (a[bn] or CFrame.identity):Lerp(b[bn] or CFrame.identity, alpha)
	end
	return cur
end

function P:Play(name, fade)
	if self.built and not self.built[name] then return end
	self.from = self.lastPose
	self.fade = fade or 0.15
	self.fadeT = 0
	self.name = name
	self.t = 0
	self.loops = 0
	self.fired = {}
end

function P:_step(dt)
	if not self.built or self.nbones == 0 then
		self.scanT = (self.scanT or 0) + dt
		if self.scanT > 0.5 then self.scanT = 0; self:_scan() end
		return
	end
	local clip = self.built[self.name]
	self.t += dt * (self.rate or 1)
	if self.t >= clip.length then
		if clip.loop then
			self.t %= clip.length
			self.fired = {}
			self.loops += 1
		else
			self:Play(self.default, 0.2)
		end
	end
	local marks = P.Markers[self.name]
	if marks then
		for m, mt in pairs(marks) do
			if not self.fired[m] and self.t >= mt then
				self.fired[m] = true
				for _, fn in ipairs(self.listeners) do task.spawn(fn, self.name, m, self.loops) end
			end
		end
	end
	local pose = self:_pose(self.name)
	if self.from and self.fadeT < self.fade then
		self.fadeT += dt
		local a = math.clamp(self.fadeT / self.fade, 0, 1)
		a = a * a * (3 - 2 * a)
		for bn, c in pairs(pose) do pose[bn] = (self.from[bn] or CFrame.identity):Lerp(c, a) end
	end
	-- turning = a spine bend in code (not a clip): self.bend radians spread over Spine1..Spine7 (more toward the tail)
	local bend = self.bend or 0
	if math.abs(bend) > 1e-3 then
		for i = 1, 7 do
			local bn = "Spine" .. i
			if pose[bn] then pose[bn] = pose[bn] * CFrame.Angles(0, 0, bend * (i / 28)) end
		end
	end
	for bn, bone in pairs(self.bones) do bone.Transform = pose[bn] or CFrame.identity end
	self.lastPose = pose
end

function P:Destroy() if self.conn then self.conn:Disconnect() end end
return P
