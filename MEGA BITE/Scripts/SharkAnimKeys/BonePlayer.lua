-- MB_Anim.BonePlayer: plays the Reef Shark's Blender clips by driving Bone.Transform
-- (works in Studio without uploaded Animation assets). Client-side only.
local RunService = game:GetService("RunService")
local Clips = require(script.Parent.ReefSharkClips)

local function toCF(v)
	if not v then return CFrame.identity end
	local w, x, y, z = v[1], v[2], v[3], v[4]
	local n = math.sqrt(w*w + x*x + y*y + z*z)
	return CFrame.new(v[5] or 0, v[6] or 0, v[7] or 0, x/n, y/n, z/n, w/n)
end

-- pre-build CFrames
local Built = {}
for name, clip in pairs(Clips) do
	local keys, bones = {}, {}
	for _, k in ipairs(clip.keys) do
		local pose = {}
		for b, v in pairs(k[2]) do pose[b] = toCF(v); bones[b] = true end
		table.insert(keys, {t = k[1], pose = pose})
	end
	Built[name] = {loop = clip.loop, keys = keys, length = keys[#keys].t, bones = bones}
end

local P = {}
P.__index = P
P.Markers = {Bite = {Snap = 0.28}}   -- seconds into the clip

function P.new(model, default)
	local self = setmetatable({}, P)
	self.bones = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Bone") then self.bones[d.Name] = d end
	end
	self.default = default or "Idle"
	self.listeners = {}
	self:Play(self.default, 0)
	self.conn = RunService.RenderStepped:Connect(function(dt) self:_step(dt) end)
	return self
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
	local clip = Built[name]
	if not clip then return cur end
	local a, b, alpha = self:_sample(clip, self.t)
	for bn in pairs(self.bones) do
		cur[bn] = (a[bn] or CFrame.identity):Lerp(b[bn] or CFrame.identity, alpha)
	end
	return cur
end

function P:Play(name, fade)
	if not Built[name] then return end
	self.from = self.lastPose          -- blend from whatever is on screen now
	self.fade = fade or 0.15
	self.fadeT = 0
	self.name = name
	self.t = 0
	self.fired = {}
end

function P:_step(dt)
	local clip = Built[self.name]
	self.t += dt
	if self.t >= clip.length then
		if clip.loop then
			self.t %= clip.length
			self.fired = {}
		else
			self:Play(self.default, 0.2)
			clip = Built[self.name]
		end
	end
	local marks = P.Markers[self.name]
	if marks then
		for m, mt in pairs(marks) do
			if not self.fired[m] and self.t >= mt then
				self.fired[m] = true
				for _, fn in ipairs(self.listeners) do task.spawn(fn, self.name, m) end
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
	for bn, bone in pairs(self.bones) do bone.Transform = pose[bn] or CFrame.identity end
	self.lastPose = pose
end

function P:Destroy() if self.conn then self.conn:Disconnect() end end

P.ClipNames = {"Idle", "Swim", "Dart", "Bite", "SharkSense", "Hurt"}
return P
