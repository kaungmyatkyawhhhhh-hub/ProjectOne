-- MB_FishClient: renders the server's food fish (pooled models, smoothed, tail wag in code), outlines the nearest
-- ones by meaning (green = you can eat it, white = about your size, red = danger), and eats on contact with your mouth.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local K = require(MB:WaitForChild("UIKit"))
local Bus = require(MB:WaitForChild("ClientBus"))
local F = C.Fish
local Remotes = MB:WaitForChild("Remotes")
local Snap, Eat, Gone, Fx = Remotes:WaitForChild("FishSnap"), Remotes:WaitForChild("FishEat"), Remotes:WaitForChild("FishGone"), Remotes:WaitForChild("Fx")
local Sounds = require(RS:WaitForChild("MB_Sounds"))
local okVFX, AbilityVFX = pcall(function() return require(RS:WaitForChild("MB_VFX", 5):WaitForChild("AbilityVFX", 5)) end)
local ORDER = {"Sardine", "Damsel", "Puffer", "Mackerel"}
local folder = Instance.new("Folder"); folder.Name = "MB_FishLocal"; folder.Parent = workspace

local function damp(rate, dt) return 1 - math.exp(-rate * dt) end
local function wrap(a) return (a + math.pi) % (2 * math.pi) - math.pi end

-- per species: template + the rotation that turns its head to -Z + the bend axis per bone
local SPEC = {}
for i, name in ipairs(ORDER) do
	local tpl = MB:WaitForChild("Fish"):WaitForChild(name)
	local h, t = tpl:FindFirstChild("Spine0", true), tpl:FindFirstChild("Spine3", true)
	local pv = tpl:GetPivot()
	local hd = (h and t) and pv:VectorToObjectSpace(h.WorldPosition - t.WorldPosition) or Vector3.new(-1, 0, 0)
	hd = Vector3.new(hd.X, 0, hd.Z).Unit
	SPEC[i] = {name = name, tpl = tpl, fix = CFrame.lookAt(Vector3.zero, hd):Inverse(), len = F.Species[name].len, pool = {}}
end
local function getModel(spi)
	local sp = SPEC[spi]
	local m = table.remove(sp.pool)
	if not m then
		m = sp.tpl:Clone()
		local bones = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("Bone") and d.Name:match("^Spine[123]$") then bones[tonumber(d.Name:sub(6))] = d end
		end
		m:SetAttribute("_b", true)
		sp.bones = sp.bones or {}
		sp.bones[m] = bones
		m.Parent = folder
	end
	return m
end
local function freeModel(spi, m)
	m:PivotTo(CFrame.new(0, -500, 0))
	table.insert(SPEC[spi].pool, m)
end

local live = {}   -- id -> {spi, m, pos, target, yaw, tyaw, seen, phase}
local eaten = {}  -- id -> time we ate it (predicted), ignore snaps for a bit
Snap.OnClientEvent:Connect(function(b)
	local now = os.clock()
	local n = buffer.len(b) // 10
	for i = 0, n - 1 do
		local o = i * 10
		local id = buffer.readu16(b, o)
		if not (eaten[id] and now - eaten[id] < 2) then
			local spi = buffer.readu8(b, o + 2)
			local p = Vector3.new(buffer.readi16(b, o + 3) / 8, buffer.readi16(b, o + 5) / 8, buffer.readi16(b, o + 7) / 8)
			local yaw = buffer.readu8(b, o + 9) / 255 * 2 * math.pi - math.pi
			local e = live[id]
			if not e then
				e = {spi = spi, m = getModel(spi), pos = p, yaw = yaw, phase = math.random() * 6}
				live[id] = e
			end
			e.target = p; e.tyaw = yaw; e.seen = now
		end
	end
	for id, e in pairs(live) do
		if now - e.seen > 1.2 then freeModel(e.spi, e.m); live[id] = nil end
	end
end)

local function pop(pos, spi, mine)
	if okVFX and AbilityVFX and AbilityVFX.EatPop then pcall(AbilityVFX.EatPop, pos, SPEC[spi] and SPEC[spi].len or 3) end
	if mine then Sounds.Play("EatPop"); Sounds.Play("Gulp") end
end
Gone.OnClientEvent:Connect(function(id, pos, who, spi)
	local e = live[id]
	if e then freeModel(e.spi, e.m); live[id] = nil end
	if who ~= lp.UserId then pop(pos, spi, false) end
	eaten[id] = os.clock()
end)

-- outlines (nearest N fish)
local HL = {}
for i = 1, F.Outlines do
	local h = Instance.new("Highlight")
	h.FillTransparency = 1; h.OutlineTransparency = 0.15; h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Enabled = false; h.Parent = folder
	HL[i] = h
end
local function myShark()
	local m = lp.Character; local root = m and m.PrimaryPart
	return m, root, m and (m:GetAttribute("Length") or 7) or 7
end
task.spawn(function()
	while true do
		task.wait(0.2)
		local m, root, L = myShark()
		local list = {}
		if root then
			for id, e in pairs(live) do
				local d = (e.pos - root.Position).Magnitude
				if d < 90 then table.insert(list, {e = e, d = d}) end
			end
			table.sort(list, function(a, b) return a.d < b.d end)
		end
		for i, h in ipairs(HL) do
			local it = list[i]
			if it then
				local len = SPEC[it.e.spi].len
				h.Adornee = it.e.m
				h.OutlineColor = (len <= L * F.EdibleFrac) and K.Colors.Kelp or ((len <= L * F.SameFrac) and K.Colors.Foam or K.Colors.Danger)
				h.Enabled = true
			else
				h.Enabled = false; h.Adornee = nil
			end
		end
	end
end)

-- render + tail wag + eat on contact
local lastEat = 0
local UP = Vector3.yAxis
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local m, root, L = myShark()
	local mouth = root and (root.Position + root.CFrame.LookVector * L * 0.45)
	for id, e in pairs(live) do
		local prev = e.pos
		e.pos = e.pos:Lerp(e.target, damp(7, dt))
		e.yaw = e.yaw + wrap(e.tyaw - e.yaw) * damp(6, dt)
		local sp = SPEC[e.spi]
		e.m:PivotTo(CFrame.new(e.pos) * CFrame.Angles(0, e.yaw, 0) * sp.fix)
		-- tail wag: faster when it is fleeing
		local spd = (e.pos - prev).Magnitude / math.max(dt, 1e-3)
		e.phase += dt * (5 + spd * 0.9)
		local bones = sp.bones and sp.bones[e.m]
		if bones then
			for i = 1, 3 do
				local b = bones[i]
				if b then
					if not b:GetAttribute("_ax") then b:SetAttribute("_ax", b.WorldCFrame:VectorToObjectSpace(e.m:GetPivot():VectorToWorldSpace(sp.fix:VectorToObjectSpace(UP)))) end
					local ax = b:GetAttribute("_ax")
					b.Transform = CFrame.fromAxisAngle(ax, math.sin(e.phase - i * 0.9) * 0.18 * i)
				end
			end
		end
		-- eat on contact
		if mouth and now - lastEat > F.BiteCooldown and sp.len <= L * F.EdibleFrac then
			if (e.pos - mouth).Magnitude < sp.len * 0.5 + L * 0.22 then
				lastEat = now
				Eat:FireServer(id)
				eaten[id] = now
				pop(e.pos, e.spi, true)
				freeModel(e.spi, e.m); live[id] = nil
			end
		end
	end
end)

-- feedback from the server
local bagToastAt = 0
Fx.OnClientEvent:Connect(function(kind, a)
	if kind == "Evolve" and a then
		if okVFX and AbilityVFX and AbilityVFX.Evolve then pcall(AbilityVFX.Evolve, a) end
		if a == lp.Character then Sounds.Play("Evolve") end
	elseif kind == "Banked" then
		Sounds.Play("BankDing"); Bus.Toast("BANKED  +" .. tostring(a) .. " EXP", "Gold")
	elseif kind == "BankFx" then
		if okVFX and AbilityVFX and AbilityVFX.Bank then pcall(AbilityVFX.Bank, a) end
	elseif kind == "BagFull" then
		if os.clock() - bagToastAt > 6 then bagToastAt = os.clock(); Sounds.Play("UIError"); Bus.Toast("BAG FULL!  Bank it at a vent", "Coral") end
	elseif kind == "SizeUp" then
		Sounds.Play("SizeUp")
	end
end)
