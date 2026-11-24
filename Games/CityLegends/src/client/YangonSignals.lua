--[[
	YangonSignals (client): traffic light poles at the 1:1 Yangon's signalled junctions (owner, 2026-11-21: "put
	traffic lights too"). The junctions and their phases come from RivieraTraffic.build().signals (the same lane
	pieces Traffic / Chauffeur / Police stop at), so the poles and the cars agree. Each approach (one junction, one
	heading) gets a slim pole on its right-hand pavement with a long thin arm over its lanes and one head on its side
	facing the cars, as in Yangon (the owner's photo, 21 Nov), with a countdown. The lenses carry the old city's tag and attributes (TrafficLamp, I / J / Axis / State), so
	WorldFx lights them on the shared clock. Built only within LOAD studs of the camera, taken down past DROP.

	YangonSignals.start()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))

local YangonSignals = {}

local LOAD, DROP = 650, 850
-- (owner, 2026-11-21, with a photo of a real Yangon signal: "Make the traffic lights like this") a slim pale-grey
-- pole on the pavement, a long thin arm out over the lanes, and at its end one black head lying on its side: a
-- countdown box, then red / yellow / green in a row
local POLE = Color3.fromRGB(196, 198, 200)
local HOUSING = Color3.fromRGB(18, 19, 21)
local LENS_OFF = { R = Color3.fromRGB(52, 8, 8), Y = Color3.fromRGB(56, 38, 4), G = Color3.fromRGB(6, 40, 22) }
local COUNT_COLOR = { R = Color3.fromRGB(255, 60, 50), Y = Color3.fromRGB(255, 200, 40), G = Color3.fromRGB(60, 255, 120) }
local POLE_H = 21
local SIDE = 9 -- studs from the outer lane's middle to the pole (the pavement)

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

-- the countdown read-outs of the heads that are built: { label, junction, axis }
local counters: { { label: TextLabel, i: number, axis: string } } = {}

-- one head on its side, facing -look: seen from the road, the countdown on the left, then R, Y, G
local function head(parent: Instance, cf: CFrame, i: number, axis: string)
	part(parent, Vector3.new(7.6, 2.0, 1.0), cf, HOUSING, Enum.Material.SmoothPlastic)
	-- (the head's +X is the viewer's left)
	for idx, state in { "R", "Y", "G" } do
		local x = 0.9 - (idx - 1) * 1.75
		-- cylinder axis is X: turn it so the round face looks down the road
		local lamp = part(parent, Vector3.new(0.25, 1.4, 1.4), cf * CFrame.new(x, 0, -0.52) * CFrame.Angles(0, math.pi / 2, 0), LENS_OFF[state], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		lamp.Name = "Lamp"
		lamp:SetAttribute("I", i)
		lamp:SetAttribute("J", 0)
		lamp:SetAttribute("Axis", axis)
		lamp:SetAttribute("State", state)
		CollectionService:AddTag(lamp, "TrafficLamp")
		part(parent, Vector3.new(1.6, 0.08, 0.8), cf * CFrame.new(x, 0.78, -0.9), HOUSING, Enum.Material.SmoothPlastic) -- visor
	end
	local face = part(parent, Vector3.new(1.7, 1.6, 0.06), cf * CFrame.new(2.75, 0, -0.52), Color3.fromRGB(6, 6, 7), Enum.Material.SmoothPlastic)
	face.Name = "Countdown"
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.Brightness = 2
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(102, 96)
	sg.Parent = face
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.Code
	t.TextScaled = true
	t.Text = ""
	t.TextColor3 = COUNT_COLOR.R
	t.Parent = sg
	table.insert(counters, { label = t, i = i, axis = axis })
end

-- the approaches: one per junction and heading (30-degree buckets), with its lanes' stop points
local function approaches(signals): { any }
	local byKey, list = {}, {}
	for _, s in signals do
		local ang = math.atan2(s.dir.X, s.dir.Z)
		local key = s.i .. ":" .. (math.floor((ang + math.pi) / (math.pi / 6) + 0.5) % 12)
		local a = byKey[key]
		if not a then
			a = { i = s.i, axis = s.axis, dir = s.dir, pts = {}, center = s.center }
			byKey[key] = a
			table.insert(list, a)
		end
		table.insert(a.pts, s.pos)
	end
	for _, a in list do
		local right = a.dir:Cross(Vector3.yAxis)
		local outer, inner = a.pts[1], a.pts[1]
		for _, p in a.pts do
			if p:Dot(right) > outer:Dot(right) then
				outer = p
			end
			if p:Dot(right) < inner:Dot(right) then
				inner = p
			end
		end
		a.right = right
		a.outer = outer
		a.inner = inner
		a.mid = (outer + inner) / 2
	end
	return list
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

local function build(a, folder: Instance): Model
	local m = Instance.new("Model")
	m.Name = "YangonSignal"
	local base = a.outer + a.right * SIDE + a.dir * 4
	-- stand on the pavement (the map's collision), else just above the road
	local root = Config.mapRoot and Config.mapRoot()
	local y = a.outer.Y + 0.6
	if root then
		rayParams.FilterDescendantsInstances = { root }
		local hit = workspace:Raycast(base + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), rayParams)
		if hit then
			y = hit.Position.Y
		end
	end
	base = Vector3.new(base.X, y, base.Z)
	-- the pole: slim, pale grey, a small foot
	part(m, Vector3.new(0.5, 1.5, 1.5), CFrame.new(base + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), POLE, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, Vector3.new(POLE_H, 1.0, 1.0), CFrame.new(base + Vector3.new(0, POLE_H / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), POLE, Enum.Material.Metal, Enum.PartType.Cylinder)
	-- the arm: one long thin tube from the pole's top out over the lanes, to the middle of the approach
	local armStart = base + Vector3.new(0, POLE_H - 0.5, 0)
	local reach = math.clamp((base - a.mid):Dot(a.right), 8, 44)
	local armEnd = armStart - a.right * reach
	part(m, Vector3.new(reach, 0.62, 0.62), CFrame.lookAt((armStart + armEnd) / 2, armEnd) * CFrame.Angles(0, math.pi / 2, 0), POLE, Enum.Material.Metal, Enum.PartType.Cylinder)
	part(m, Vector3.new(1.15, 1.15, 1.15), CFrame.new(armStart), POLE, Enum.Material.Metal, Enum.PartType.Ball)
	-- the head at the arm's end, its middle on the arm
	local hp = armEnd - a.right * 3.2
	head(m, CFrame.lookAt(hp, hp - a.dir), a.i, a.axis)
	-- (2026-11-25, clips 0929 / 0931: "one blue lane-arrow sign on the mast arm") a blue panel hanging under the arm,
	-- one arrow per approach lane: left on the inner lane, straight, straight + right on the outer lane
	local lanes = math.clamp(#a.pts, 1, 5)
	local pw = lanes * 2.3
	if reach >= 14 and reach * 0.5 + pw / 2 < reach - 1 then
		local pc = armStart - a.right * (reach * 0.5) - Vector3.new(0, 0.31 + 1.3, 0)
		local panel = part(m, Vector3.new(pw, 2.6, 0.15), CFrame.lookAt(pc, pc - a.dir), Color3.fromRGB(16, 84, 168), Enum.Material.SmoothPlastic)
		panel.Name = "LaneArrows"
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.LightInfluence = 1
		sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		sg.CanvasSize = Vector2.new(lanes * 46, 52)
		sg.MaxDistance = 300
		sg.Parent = panel
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.Parent = sg
		for k = 1, lanes do
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.new(1 / lanes, 0, 1, 0)
			t.Font = Enum.Font.SourceSansBold
			t.TextScaled = true
			t.TextColor3 = Color3.new(1, 1, 1)
			-- (k = 1 is the viewer's left = the inner lane)
			t.Text = if lanes == 1 then "↑" elseif k == 1 then "←" elseif k == lanes then "↱" else "↑"
			t.LayoutOrder = k
			t.Parent = sg
			if k > 1 then
				local sep = Instance.new("Frame")
				sep.BorderSizePixel = 0
				sep.BackgroundColor3 = Color3.new(1, 1, 1)
				sep.Size = UDim2.new(0, 2, 0.8, 0)
				sep.Position = UDim2.new(0, -1, 0.1, 0)
				sep.Parent = t
			end
		end
	end
	m.Parent = folder
	return m
end

local started = false
function YangonSignals.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local g
		for _ = 1, 60 do
			g = RivieraTraffic.build()
			if g then
				break
			end
			task.wait(2)
		end
		if not g or not g.signals or #g.signals == 0 then
			return
		end
		local list = approaches(g.signals)
		local folder = Instance.new("Folder")
		folder.Name = "YangonSignals"
		folder.Parent = workspace
		local built: { [any]: Model } = {}
		-- the countdowns: seconds left in the light's state, in its colour (4 times a second)
		task.spawn(function()
			while true do
				local now = workspace:GetServerTimeNow()
				for k = #counters, 1, -1 do
					local c = counters[k]
					if not c.label.Parent then
						table.remove(counters, k)
					else
						local state = CityLayout.lightState(c.i, 0, c.axis, now)
						c.label.Text = tostring(math.clamp(math.ceil(CityLayout.lightTimeLeft(c.i, 0, c.axis, now)), 0, 99))
						c.label.TextColor3 = COUNT_COLOR[state] or COUNT_COLOR.R
					end
				end
				task.wait(0.25)
			end
		end)
		while true do
			local cam = workspace.CurrentCamera
			local at = if cam then cam.CFrame.Position else Vector3.zero
			local made = 0
			for _, a in list do
				local d = Vector3.new(a.mid.X - at.X, 0, a.mid.Z - at.Z).Magnitude
				if d < LOAD and not built[a] and made < 12 then
					built[a] = build(a, folder)
					made += 1
				elseif d > DROP and built[a] then
					built[a]:Destroy()
					built[a] = nil
				end
			end
			task.wait(if made >= 12 then 0.1 else 1)
		end
	end)
end

return YangonSignals
