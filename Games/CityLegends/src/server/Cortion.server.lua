--[[
	Cortion (server, 2026-11-27; owner: "in that myitta nyunt house, in the room, add an npc character with a nametag
	named cortion and he has a fat belly and he wanders around the house like playing games on pc (the pc has to turn
	on when he sits down and turns off once he stops playing) and watch tv, sleeps, showers (rarely), prays to pagoda
	statue, goes near the windows and unblurs the window and stares outside. make it so that u can kick any activity
	hes doing ... by pressing E on him (proximityprompt) and only show that proximityprompt once he starts doing an
	activity ... and most importantly, add an animation to everything he does").

	A Roblox R15 Blocky avatar (default body parts, classic face, a Roblox catalog hair from ReplicatedStorage.PedKit,
	wider / deeper body scale + a belly sphere on the upper torso), name tag "Cortion", in Workspace.Cortion
	(Atomic streaming). The server walks him (Humanoid:MoveTo along hand waypoints in the Myittar Nyunt flat, doors
	opened through Openables' OpenableOpen) and runs a weighted random day: PC (monitor on with a racing game),
	TV (picture on, scenes change), sleep (yellow room bed), shower (rare; water, sound), pray at the shrine's
	pagodas, stare out of a window (it clears through FlatWindows' FlatWindowSet, frosts again when he leaves).
	His poses are drawn on every client by client/Cortion from attributes (Act, ActT, Pose, Pose2, Look, KickDir).
	The "Kick" prompt (E / X) exists only while he is in an activity; a kick plays the kicker's kick on every client
	(remote CortionFx), stops the activity (devices off), he stumbles, complains, and picks another one.
	Runs only while a player is within NEAR of the flat. Points are in the block's local frame (tools/yangon/
	MyittarNyuntBlock.luau M.FRAME, x along the road face, floor of the flat at y 30).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local FRAME = CFrame.fromMatrix(Vector3.new(44660.2, 18.9, 35594.8), Vector3.new(65.5, 0, -45.6).Unit, Vector3.yAxis)
local FLOOR = 30
local NEAR = 160 -- studs from the flat's middle
local MIDDLE = FRAME * Vector3.new(15, FLOOR, 11)
local WALK = 7

local block = workspace:WaitForChild("Yangon1to1", 60)
block = block and block:WaitForChild("Walkable", 60)
block = block and block:WaitForChild("MyittarNyuntBlock", 60)
local inside = block and block:WaitForChild("Inside", 60)
if not inside then
	warn("Cortion: Myittar Nyunt flat not found")
	return
end

---------------------------------------------------------------------
-- the flat: waypoints (x, z), edges, activity spots
---------------------------------------------------------------------
local N = {
	H1 = Vector2.new(-6, 12.4), H2 = Vector2.new(0, 12.4), H3 = Vector2.new(11.1, 12.4), H4 = Vector2.new(14.4, 12.4),
	H5 = Vector2.new(22, 12.4), H6 = Vector2.new(27.3, 12.4),
	S1 = Vector2.new(-8, 19), Y0 = Vector2.new(14.4, 14.6), Y1 = Vector2.new(14.4, 17.6), Y2 = Vector2.new(8, 21.0),
	-- Y3: round the yellow room's open door leaf (x 12.2..12.8, z 15.9..20.3)
	Y3 = Vector2.new(13.6, 21.0),
	L1 = Vector2.new(24.4, 15), L2 = Vector2.new(24.6, 24.4), D1 = Vector2.new(27.3, 7.6), D2 = Vector2.new(35.4, 7.4),
	B1 = Vector2.new(38.7, 5.4),
	-- activity spots (he stands here, then the pose moves his body onto the seat / bed)
	PC = Vector2.new(15.1, 22.3), TV = Vector2.new(23.2, 20.4), BED = Vector2.new(3.0, 20.4), PRAY = Vector2.new(-9.4, 23.0),
	SHOWER = Vector2.new(40.3, 5.9), WIN_S = Vector2.new(24.8, 26.9), WIN_W = Vector2.new(-10.7, 19.6),
}
local EDGES = {
	{ "H1", "H2" }, { "H2", "H3" }, { "H3", "H4" }, { "H4", "H5" }, { "H5", "H6" },
	{ "H1", "S1" }, { "S1", "PRAY" }, { "S1", "WIN_W" },
	{ "H4", "Y0" }, { "Y0", "Y1" }, { "Y1", "PC" }, { "Y1", "Y3" }, { "Y3", "Y2" }, { "Y2", "BED" },
	{ "H5", "L1" }, { "L1", "TV" }, { "L1", "L2" }, { "L2", "WIN_S" },
	{ "H6", "D1" }, { "D1", "D2" }, { "D2", "B1" }, { "B1", "SHOWER" },
}
-- doors on an edge (opened before he walks through)
local DOORS = { ["H4|Y0"] = "YellowDoor", ["D2|B1"] = "BathDoor" }
local NEXT: { [string]: { string } } = {}
for _, e in EDGES do
	NEXT[e[1]] = NEXT[e[1]] or {}
	NEXT[e[2]] = NEXT[e[2]] or {}
	table.insert(NEXT[e[1]], e[2])
	table.insert(NEXT[e[2]], e[1])
end

-- breadth-first: fewest legs (the flat is small)
local function route(from: string, to: string): { string }
	local prev, q, head = { [from] = from }, { from }, 1
	while head <= #q do
		local n = q[head]
		head += 1
		if n == to then
			break
		end
		for _, m in NEXT[n] do
			if not prev[m] then
				prev[m] = n
				table.insert(q, m)
			end
		end
	end
	local path = {}
	local n = to
	while n and n ~= from do
		table.insert(path, 1, n)
		n = prev[n]
	end
	return path
end

-- yaw facing: local +x = 1, -x, +z, -z
local FACE = { px = Vector3.new(1, 0, 0), nx = Vector3.new(-1, 0, 0), pz = Vector3.new(0, 0, 1), nz = Vector3.new(0, 0, -1) }

---------------------------------------------------------------------
-- Cortion himself
---------------------------------------------------------------------
local SKIN = Color3.fromRGB(204, 142, 105)
local SINGLET = Color3.fromRGB(236, 236, 230)
local PANTS = Color3.fromRGB(52, 86, 72)

local function build(): Model
	local d = Instance.new("HumanoidDescription")
	d.HeadColor, d.LeftArmColor, d.RightArmColor = SKIN, SKIN, SKIN
	d.TorsoColor, d.LeftLegColor, d.RightLegColor = SINGLET, PANTS, PANTS
	d.WidthScale, d.DepthScale, d.HeightScale, d.HeadScale = 1.18, 1.3, 0.95, 1
	local m = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	m.Name = "Cortion"
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	local animate = m:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local an = hum:FindFirstChildOfClass("Animator")
	if an then
		an:Destroy() -- poses come from client/Cortion's Transforms
	end
	-- new avatars come with AnimationConstraint joints: swap them for classic Motor6Ds, whose Transform the client sets
	for _, j in m:GetDescendants() do
		if j:IsA("AnimationConstraint") and j.Attachment0 and j.Attachment1 then
			local mo = Instance.new("Motor6D")
			mo.Name = j.Name
			mo.Part0, mo.Part1 = j.Attachment0.Parent :: BasePart, j.Attachment1.Parent :: BasePart
			mo.C0, mo.C1 = j.Attachment0.CFrame, j.Attachment1.CFrame
			mo.Parent = j.Parent
			j:Destroy()
		end
	end
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = WALK
	hum.BreakJointsOnDeath = false
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	hum.MaxHealth, hum.Health = math.huge, math.huge
	-- the belly: a sphere on the front of the upper torso, singlet white
	local ut = m:FindFirstChild("UpperTorso") :: BasePart
	local s = ut.Size
	local belly = Instance.new("Part")
	belly.Name = "Belly"
	belly.Size = Vector3.new(s.X * 0.9, s.Y * 0.95, s.Z * 1.25)
	belly.Color = SINGLET
	belly.Material = Enum.Material.SmoothPlastic
	belly.CanCollide, belly.CanQuery, belly.CanTouch, belly.Massless = false, false, false, true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = belly
	local w = Instance.new("Weld")
	w.Part0, w.Part1 = ut, belly
	w.C0 = CFrame.new(0, -s.Y * 0.28, -s.Z * 0.45) -- (the Blocky torso tapers: further back it poked out behind)
	w.Parent = belly
	belly.CFrame = ut.CFrame * w.C0
	belly.Parent = m
	-- Roblox hair from the street people's kit (short black)
	local kit = ReplicatedStorage:FindFirstChild("PedKit")
	local hairs = kit and kit:FindFirstChild("Hair")
	local head = m:FindFirstChild("Head") :: BasePart
	if hairs then
		local pick = hairs:FindFirstChild("Brown") -- Roblox's Brown Hair (short)
		for _, h in hairs:GetChildren() do
			if not pick and h:IsA("BasePart") and not h:GetAttribute("Long") then
				pick = h
			end
		end
		if pick then
			local hair = pick:Clone()
			hair.Name = "Hair"
			hair.Anchored, hair.CanCollide, hair.CanQuery, hair.CanTouch, hair.Massless = false, false, false, false, true
			hair.Color = Color3.fromRGB(28, 24, 22)
			local off = (pick:GetAttribute("Off") :: CFrame?) or CFrame.new(0, 0.6, 0)
			local hw = Instance.new("Weld")
			hw.Part0, hw.Part1, hw.C0 = head, hair, off
			hw.Parent = hair
			hair.CFrame = head.CFrame * off
			hair.Parent = m
		end
	end
	-- name tag
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.fromScale(4, 0.8)
	bb.StudsOffset = Vector3.new(0, 2.4, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Text = "Cortion"
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.TextStrokeTransparency = 0.3
	l.Parent = bb
	bb.Parent = head
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.CanCollide = false
		end
	end
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return m
end

local model = build()
local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
local standY = hum.HipHeight + root.Size.Y / 2

-- joint sizes for the poses (the same sums the client uses)
local function motor(part: string, name: string): Motor6D
	return (model:FindFirstChild(part) :: BasePart):FindFirstChild(name) :: Motor6D
end
local hip, knee, ankle = motor("LeftUpperLeg", "LeftHip"), motor("LeftLowerLeg", "LeftKnee"), motor("LeftFoot", "LeftAnkle")
local thigh = (hip.C1.Position - knee.C0.Position).Magnitude
local shin = (knee.C1.Position - ankle.C0.Position).Magnitude
local foot = ankle.C1.Position.Y + (model:FindFirstChild("LeftFoot") :: BasePart).Size.Y / 2
local legHalf = (model:FindFirstChild("LeftUpperLeg") :: BasePart).Size.Z / 2

-- pose = where the body goes from the standing root (root space: -Z ahead, +X right)
local function sitPose(seatTop: number, ahead: number): CFrame
	-- seated, the hip sits at shin + foot (knee height) over the floor; the thigh's underside should touch the seat
	return CFrame.new(0, seatTop + legHalf - (shin + foot), -ahead)
end
local function kneelPose(): CFrame
	return CFrame.new(0, legHalf - (shin * math.cos(1.45) + foot), 0)
end

local fx = Instance.new("RemoteEvent")
fx.Name = "CortionFx"
fx.Parent = ReplicatedStorage

---------------------------------------------------------------------
-- devices
---------------------------------------------------------------------
local function part(name: string, near: Vector3?): BasePart?
	local best, bd = nil, math.huge
	for _, p in inside:GetDescendants() do
		if p.Name == name and p:IsA("BasePart") then
			local d = if near then (FRAME:PointToObjectSpace(p.Position) - near).Magnitude else 0
			if d < bd then
				best, bd = p, d
			end
		end
	end
	return best
end
local function model_(name: string): Model?
	local m = inside:FindFirstChild(name, true)
	return if m and m:IsA("Model") then m else nil
end

local function frame(parent: Instance, pos: UDim2, size: UDim2, color: Color3, z: number?): Frame
	local f = Instance.new("Frame")
	f.Position, f.Size, f.BackgroundColor3, f.BorderSizePixel = pos, size, color, 0
	f.ZIndex = z or 1
	f.Parent = parent
	return f
end
local function label(parent: Instance, pos: UDim2, size: UDim2, text: string, color: Color3, z: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Position, l.Size, l.BackgroundTransparency = pos, size, 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled, l.Text, l.TextColor3 = true, text, color
	l.ZIndex = z or 3
	l.Parent = parent
	return l
end
local function screenGui(p: BasePart): SurfaceGui
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.LightInfluence = 0
	g.Brightness = 1.6
	g.PixelsPerStud = 120
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.Enabled = false
	g.Parent = p
	return g
end
local OFF_LOOK = { Color = Color3.fromRGB(14, 14, 16), Material = Enum.Material.SmoothPlastic }

-- the PC: a racing game on the monitor, lane dashes running, keys clicking
local pc = { screen = part("MonitorScreen"), on = false }
do
	local p = pc.screen
	if p then
		pc.look = { Color = p.Color, Material = p.Material }
		local g = screenGui(p)
		frame(g, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.42), Color3.fromRGB(28, 34, 70))
		frame(g, UDim2.fromScale(0, 0.3), UDim2.fromScale(1, 0.12), Color3.fromRGB(20, 22, 40), 2) -- far city
		frame(g, UDim2.fromScale(0, 0.42), UDim2.fromScale(1, 0.58), Color3.fromRGB(46, 48, 54))
		frame(g, UDim2.fromScale(0.08, 0.42), UDim2.fromScale(0.02, 0.58), Color3.fromRGB(230, 222, 114), 2)
		frame(g, UDim2.fromScale(0.9, 0.42), UDim2.fromScale(0.02, 0.58), Color3.fromRGB(230, 222, 114), 2)
		pc.dashes = {}
		for i = 0, 3 do
			table.insert(pc.dashes, frame(g, UDim2.fromScale(0.49, 0.42 + i * 0.16), UDim2.fromScale(0.02, 0.08), Color3.fromRGB(240, 240, 240), 2))
		end
		local car = frame(g, UDim2.fromScale(0.36, 0.7), UDim2.fromScale(0.28, 0.2), Color3.fromRGB(200, 30, 36), 4)
		Instance.new("UICorner", car).CornerRadius = UDim.new(0.2, 0)
		frame(car, UDim2.fromScale(0.15, 0.1), UDim2.fromScale(0.7, 0.3), Color3.fromRGB(30, 34, 44), 5)
		frame(car, UDim2.fromScale(0.05, 0.7), UDim2.fromScale(0.2, 0.18), Color3.fromRGB(255, 60, 60), 5)
		frame(car, UDim2.fromScale(0.75, 0.7), UDim2.fromScale(0.2, 0.18), Color3.fromRGB(255, 60, 60), 5)
		label(g, UDim2.fromScale(0.03, 0.03), UDim2.fromScale(0.3, 0.12), "LAP 2/3", Color3.new(1, 1, 1))
		pc.speed = label(g, UDim2.fromScale(0.66, 0.03), UDim2.fromScale(0.31, 0.12), "142 km/h", Color3.fromRGB(255, 214, 90))
		pc.gui = g
		local light = Instance.new("SurfaceLight")
		light.Face, light.Range, light.Brightness, light.Angle = Enum.NormalId.Front, 9, 0.9, 120
		light.Color, light.Enabled = Color3.fromRGB(150, 170, 255), false
		light.Parent = p
		pc.light = light
		local snd = Instance.new("Sound")
		snd.SoundId, snd.Volume, snd.Looped = "rbxassetid://9116157899", 0.22, true -- Keyboard Typing 42 (Pro Sound Effects)
		snd.RollOffMode, snd.RollOffMinDistance, snd.RollOffMaxDistance = Enum.RollOffMode.InverseTapered, 4, 30
		snd.Parent = p
		pc.sound = snd
		-- the screen is off until he plays (it used to glow all the time)
		p.Color, p.Material = OFF_LOOK.Color, OFF_LOOK.Material
	end
end
local function setPC(on: boolean)
	local p = pc.screen
	if not p or pc.on == on then
		return
	end
	pc.on = on
	p.Color = if on then Color3.fromRGB(28, 34, 70) else OFF_LOOK.Color
	p.Material = if on then Enum.Material.Neon else OFF_LOOK.Material
	pc.gui.Enabled, pc.light.Enabled = on, on
	if on then
		pc.sound:Play()
		task.spawn(function()
			local k = 0
			while pc.on do
				k += 1
				for i, d in pc.dashes do
					d.Position = UDim2.fromScale(0.49, 0.42 + ((i - 1) * 0.16 + (k % 4) * 0.04) % 0.6)
				end
				if k % 3 == 0 then
					pc.speed.Text = (128 + math.random(0, 40)) .. " km/h"
				end
				task.wait(0.25)
			end
		end)
	else
		pc.sound:Stop()
	end
end

-- the TV: scenes (football, news, cartoon) every 6 s on the two screen halves
local tv = { sky = part("TVScreenSky"), land = part("TVScreenLand"), on = false }
local SCENES = {
	{ sky = Color3.fromRGB(60, 70, 96), land = Color3.fromRGB(40, 130, 60), text = "MYA 2 - 1 THA", light = Color3.fromRGB(140, 220, 150) },
	{ sky = Color3.fromRGB(30, 60, 140), land = Color3.fromRGB(90, 50, 40), text = "LIVE  NEWS", light = Color3.fromRGB(140, 170, 255) },
	{ sky = Color3.fromRGB(110, 190, 240), land = Color3.fromRGB(110, 200, 80), text = "", light = Color3.fromRGB(200, 240, 255) },
}
if tv.sky and tv.land then
	tv.gSky, tv.gLand = screenGui(tv.sky), screenGui(tv.land)
	tv.skyBg = frame(tv.gSky, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), SCENES[1].sky)
	tv.text = label(tv.gSky, UDim2.fromScale(0.15, 0.25), UDim2.fromScale(0.7, 0.5), SCENES[1].text, Color3.new(1, 1, 1))
	tv.sun = frame(tv.gSky, UDim2.fromScale(0.75, 0.15), UDim2.fromScale(0.13, 0.6), Color3.fromRGB(255, 220, 80), 2)
	Instance.new("UICorner", tv.sun).CornerRadius = UDim.new(1, 0)
	tv.landBg = frame(tv.gLand, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), SCENES[1].land)
	tv.line = frame(tv.gLand, UDim2.fromScale(0.495, 0), UDim2.fromScale(0.01, 1), Color3.new(1, 1, 1), 2)
	tv.ball = frame(tv.gLand, UDim2.fromScale(0.3, 0.4), UDim2.fromScale(0.05, 0.22), Color3.new(1, 1, 1), 3)
	Instance.new("UICorner", tv.ball).CornerRadius = UDim.new(1, 0)
	tv.guy = frame(tv.gLand, UDim2.fromScale(0.6, 0.1), UDim2.fromScale(0.08, 0.7), Color3.fromRGB(245, 205, 48), 3) -- a little Roblox guy
	frame(tv.guy, UDim2.fromScale(0, 0.45), UDim2.fromScale(1, 0.55), Color3.fromRGB(30, 90, 200), 4)
	tv.light = Instance.new("SurfaceLight")
	tv.light.Face, tv.light.Range, tv.light.Brightness, tv.light.Angle, tv.light.Enabled = Enum.NormalId.Front, 14, 1, 120, false
	tv.light.Parent = tv.sky
	for _, p in { tv.sky, tv.land } do
		p.Color, p.Material = OFF_LOOK.Color, OFF_LOOK.Material
	end
end
local function setTV(on: boolean)
	if not tv.sky or tv.on == on then
		return
	end
	tv.on = on
	tv.gSky.Enabled, tv.gLand.Enabled, tv.light.Enabled = on, on, on
	for _, p in { tv.sky, tv.land } do
		p.Material = if on then Enum.Material.Neon else OFF_LOOK.Material
		p.Color = OFF_LOOK.Color
	end
	if on then
		task.spawn(function()
			local i, k = 1, 0
			while tv.on do
				local s = SCENES[i]
				tv.skyBg.BackgroundColor3, tv.landBg.BackgroundColor3 = s.sky, s.land
				tv.text.Text = s.text
				tv.sun.Visible = i == 3
				tv.line.Visible, tv.ball.Visible = i == 1, i == 1
				tv.guy.Visible = i ~= 1
				tv.light.Color = s.light
				tv.sky.Color, tv.land.Color = s.sky:Lerp(Color3.new(), 0.6), s.land:Lerp(Color3.new(), 0.6)
				for _ = 1, 12 do -- 6 s a scene, the ball / guy moving
					if not tv.on then
						break
					end
					k += 1
					tv.ball.Position = UDim2.fromScale(0.2 + 0.6 * (0.5 + 0.5 * math.sin(k * 0.7)), 0.3 + 0.3 * math.abs(math.sin(k * 1.3)))
					tv.guy.Position = UDim2.fromScale(0.3 + 0.4 * (0.5 + 0.5 * math.sin(k * 0.45)), 0.1)
					task.wait(0.5)
				end
				i = i % #SCENES + 1
			end
		end)
	end
end

-- the shower: spray under the head + running water
local shower = { head = part("ShowerHead") }
if shower.head then
	local sp = Instance.new("Part")
	sp.Name = "CortionShowerSpray"
	sp.Size = Vector3.new(0.4, 0.1, 0.4)
	sp.Transparency, sp.Anchored, sp.CanCollide, sp.CanQuery, sp.CanTouch = 1, true, false, false, false
	-- aimed down and out from the wall, so the water lands on him (he stands 1.4 studs out from the pipe)
	local hp = shower.head.Position - Vector3.new(0, 0.15, 0)
	sp.CFrame = CFrame.lookAt(hp, hp + FRAME:VectorToWorldSpace(Vector3.new(-0.35, -1, 0.75)))
	sp.Parent = shower.head
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = Enum.NormalId.Front
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(200, 225, 255))
	e.LightEmission, e.LightInfluence = 0.2, 0.6
	e.Size = NumberSequence.new(0.1, 0.06)
	e.Transparency = NumberSequence.new(0.15, 0.55)
	e.Lifetime = NumberRange.new(0.45, 0.6)
	e.Speed = NumberRange.new(4, 5.5)
	e.SpreadAngle = Vector2.new(12, 12)
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Rate, e.Enabled = 240, false
	e.Parent = sp
	shower.emit = e
	local snd = Instance.new("Sound")
	snd.SoundId, snd.Volume, snd.Looped = "rbxassetid://365551014", 0.45, true -- BathRunning (Roblox)
	snd.RollOffMode, snd.RollOffMinDistance, snd.RollOffMaxDistance = Enum.RollOffMode.InverseTapered, 4, 30
	snd.Parent = sp
	shower.sound = snd
end
local function setShower(on: boolean)
	if shower.emit then
		shower.emit.Enabled = on
		if on then
			shower.sound:Play()
		else
			shower.sound:Stop()
		end
	end
end

local winSet = ServerStorage:WaitForChild("FlatWindowSet", 30) :: BindableFunction?
local openDoor = ServerStorage:WaitForChild("OpenableOpen", 30) :: BindableFunction?
local function window(id: string, frost: boolean)
	if winSet then
		pcall(winSet.Invoke, winSet, id, frost)
	end
end

---------------------------------------------------------------------
-- the activities
---------------------------------------------------------------------
type Act = { name: string, spot: string, face: string, weight: number, dur: NumberRange, pose: CFrame?, pose2: CFrame?, look: number?,
	start: (() -> ())?, stop: (() -> ())?, lines: { string } }

local MATTRESS_TOP = 1.8
local LIE = CFrame.fromMatrix(Vector3.new(0.3, MATTRESS_TOP + 0.5 - standY, -3.5), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0), Vector3.new(0, -1, 0))
local ACTS: { Act } = {
	{ name = "pc", spot = "PC", face = "pz", weight = 30, dur = NumberRange.new(30, 45), pose = sitPose(1.85, 1.7),
		start = function() setPC(true) end, stop = function() setPC(false) end,
		lines = { "HEY! I was about to win!", "My game! Noooo!", "Bro I was on the last lap!" } },
	{ name = "tv", spot = "TV", face = "px", weight = 24, dur = NumberRange.new(30, 45), pose = sitPose(1.6, -2.3),
		start = function() setTV(true) end, stop = function() setTV(false) end,
		lines = { "Ow! My show!", "It was the best part!", "Can't a guy watch TV?!" } },
	{ name = "sleep", spot = "BED", face = "pz", weight = 12, dur = NumberRange.new(35, 50), pose = sitPose(MATTRESS_TOP, 1.2), pose2 = LIE,
		lines = { "Let me SLEEP!", "Huh?! Who kicked me?!", "I was dreaming about noodles..." } },
	{ name = "shower", spot = "SHOWER", face = "px", weight = 5, dur = NumberRange.new(16, 22),
		start = function() setShower(true) end, stop = function() setShower(false) end,
		lines = { "HEY! I'm showering!", "Can't I shower in peace?!", "GET OUT!" } },
	{ name = "pray", spot = "PRAY", face = "pz", weight = 12, dur = NumberRange.new(18, 24), pose = kneelPose(),
		lines = { "I was praying!", "Not at the shrine, bro!", "Ow! Have some respect!" } },
	{ name = "window", spot = "WIN_S", face = "pz", weight = 9, dur = NumberRange.new(14, 20), win = "BC_27.75",
		lines = { "Ow! I was looking outside!", "Hey! The street was interesting!" } },
	{ name = "window", spot = "WIN_W", face = "nx", weight = 7, dur = NumberRange.new(14, 20), win = "AB_19.6",
		lines = { "Ow! I was looking outside!", "Hey! The street was interesting!" } },
} :: any
local WANDER = { "H2", "H5", "L1", "Y1", "S1", "D1", "H3" }
local winOf = {}
for _, a in ACTS :: any do
	if a.win then
		window(a.win, true) -- his windows start frosted: he clears one to look out
		winOf[a] = a.win
	end
end

---------------------------------------------------------------------
-- moving him
---------------------------------------------------------------------
local at = "H4"
local kicked = false
local forced = nil -- the Studio test hook's next act (ends the current one early)
local prompt: ProximityPrompt? = nil

local function world(p: Vector2, y: number?): Vector3
	return FRAME * Vector3.new(p.X, FLOOR + (y or standY), p.Y)
end

local function setAct(name: string, pose: CFrame?, pose2: CFrame?, look: number?)
	model:SetAttribute("Act", name)
	model:SetAttribute("ActT", workspace:GetServerTimeNow())
	model:SetAttribute("Pose", pose)
	model:SetAttribute("Pose2", pose2)
	model:SetAttribute("Look", look or 0)
end

local function playersNear(): boolean
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if r and (r.Position - MIDDLE).Magnitude < NEAR then
			return true
		end
	end
	return false
end

-- waits t seconds of "players near" time; false if he got kicked
local function hold(t: number): boolean
	local left = t
	while left > 0 do
		if kicked or forced then
			return false
		end
		local dt = task.wait(0.2)
		if playersNear() then
			left -= dt
		end
	end
	return not kicked
end

local function unanchor()
	if root.Anchored then
		local p = root.Position
		local look = root.CFrame.LookVector
		look = Vector3.new(look.X, 0, look.Z)
		root.CFrame = CFrame.lookAt(p, p + (if look.Magnitude > 0.01 then look else Vector3.zAxis))
		root.Anchored = false
	end
	pcall(root.SetNetworkOwner, root, nil)
end

-- glide (anchored) to a CFrame over t seconds: the last step onto a spot, turning to face it
local function glide(target: CFrame, t: number)
	root.Anchored = true
	local from = root.CFrame
	local t0 = os.clock()
	while true do
		local a = math.min(1, (os.clock() - t0) / t)
		a = a * a * (3 - 2 * a)
		root.CFrame = from:Lerp(target, a)
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
end

local function walkTo(dest: string)
	local path = route(at, dest)
	if #path == 0 then
		return
	end
	setAct("walk")
	unanchor()
	local prev = at
	for _, n in path do
		local door = DOORS[prev .. "|" .. n] or DOORS[n .. "|" .. prev]
		if door and openDoor then
			local m = model_(door)
			if m and m:GetAttribute("Open") ~= true then
				pcall(openDoor.Invoke, openDoor, m)
				task.wait(0.7)
			end
		end
		local goal = world(N[n])
		local t0 = os.clock()
		while true do
			while not playersNear() do -- nobody here: stand still
				hum:MoveTo(root.Position)
				task.wait(1)
				t0 = os.clock()
			end
			hum:MoveTo(goal)
			local d = root.Position - goal
			if Vector2.new(d.X, d.Z).Magnitude < 1.1 then
				break
			end
			if os.clock() - t0 > 6 then -- stuck on something: step there
				root.CFrame = CFrame.lookAt(goal, goal + root.CFrame.LookVector * Vector3.new(1, 0, 1))
				break
			end
			task.wait(0.1)
		end
		prev = n
		at = n
	end
end

local function spotCF(a): CFrame
	local p = world(N[a.spot])
	local dir = FRAME:VectorToWorldSpace(FACE[a.face])
	return CFrame.lookAt(p, p + dir)
end

local function removePrompt()
	if prompt then
		prompt:Destroy()
		prompt = nil
	end
end

local kickCooldown = 0
local function addPrompt()
	removePrompt()
	local p = Instance.new("ProximityPrompt")
	p.Name = "KickPrompt"
	p.ActionText = "Kick"
	p.ObjectText = "Cortion"
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.GamepadKeyCode = Enum.KeyCode.ButtonX
	p.HoldDuration = 0
	p.MaxActivationDistance = 8
	p.RequiresLineOfSight = false
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	p.Triggered:Connect(function(player: Player)
		if kicked or os.clock() < kickCooldown then
			return
		end
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not r or (r.Position - root.Position).Magnitude > 12 then
			return
		end
		kickCooldown = os.clock() + 1
		kicked = true
		local back = (r.Position - root.Position):Dot(root.CFrame.LookVector) < 0
		model:SetAttribute("KickDir", if back then 1 else -1)
		removePrompt()
		fx:FireAllClients("kick", player)
	end)
	p.Parent = root
	prompt = p
end

-- his speech bubble and the Zzz: made here (server) so every player sees them, like his name tag; client/Cortion
-- makes the Zzz letters rise
local function sayBubble(text: string)
	local head = model:FindFirstChild("Head") :: BasePart
	local old = head:FindFirstChild("CortionSays")
	if old then
		old:Destroy()
	end
	local b = Instance.new("BillboardGui")
	b.Name = "CortionSays"
	b.Size = UDim2.fromScale(5.2, 1.3)
	b.StudsOffset = Vector3.new(0, 3.5, 0) -- (StudsOffsetWorldSpace turns with the head: lying down it went into the wall)
	b.MaxDistance = 60
	b.LightInfluence = 0
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.Parent = b
	Instance.new("UICorner", f).CornerRadius = UDim.new(0.3, 0)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(0.92, 0.8)
	l.Position = UDim2.fromScale(0.04, 0.1)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(30, 30, 34)
	l.Text = text
	l.Parent = f
	b.Parent = head
	task.delay(3.4, function()
		b:Destroy()
	end)
end

local function setZzz(on: boolean)
	local head = model:FindFirstChild("Head") :: BasePart
	local z = head:FindFirstChild("CortionZzz")
	if not on then
		if z then
			z:Destroy()
		end
		return
	end
	if z then
		return
	end
	local b = Instance.new("BillboardGui")
	b.Name = "CortionZzz"
	b.Size = UDim2.fromScale(2.6, 3.4)
	b.StudsOffset = Vector3.new(1.2, 2.3, 0)
	b.MaxDistance = 50
	b.LightInfluence = 0
	for i = 1, 3 do
		local l = Instance.new("TextLabel")
		l.Name = "Z" .. i
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(0.4, 0.3)
		l.Position = UDim2.fromScale(0.1 + 0.15 * i, 0.75 - 0.25 * i)
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.Text = "z"
		l.TextColor3 = Color3.fromRGB(60, 80, 190)
		l.TextStrokeColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.15
		l.Parent = b
	end
	b.Parent = head
end

local function oof()
	for _, id in { "rbxasset://sounds/uuhhh.mp3", "rbxasset://sounds/action_jump_land.mp3" } do
		local s = Instance.new("Sound")
		s.SoundId, s.Volume = id, 0.6
		s.RollOffMode, s.RollOffMinDistance, s.RollOffMaxDistance = Enum.RollOffMode.InverseTapered, 4, 40
		s.Parent = root
		s:Play()
		task.delay(3, function()
			s:Destroy()
		end)
	end
end

local function pick(last)
	local total = 0
	for _, a in ACTS :: any do
		if a ~= last then
			total += a.weight
		end
	end
	local r = math.random() * total
	for _, a in ACTS :: any do
		if a ~= last then
			r -= a.weight
			if r <= 0 then
				return a
			end
		end
	end
	return ACTS[1]
end

-- one activity: walk there, settle, do it (prompt on), stop (devices off, prompt off), get up
local function run(a)
	kicked = false
	walkTo(a.spot)
	glide(spotCF(a), 0.45)
	setAct(a.name, a.pose, a.pose2, a.look)
	addPrompt()
	task.wait(0.9) -- sitting down / kneeling first, then the screen comes on
	if a.start then
		a.start()
	end
	if winOf[a] then
		window(winOf[a], false)
	end
	if a.name == "sleep" then
		task.delay(2, function()
			if model:GetAttribute("Act") == "sleep" then
				setZzz(true)
			end
		end)
	end
	local done = hold(a.dur.Min + math.random() * (a.dur.Max - a.dur.Min)) or not kicked
	removePrompt()
	setZzz(false)
	if a.stop then
		a.stop()
	end
	if not done then
		-- kicked: the kicker's foot lands ~0.5 s after the press, then he reacts
		task.wait(0.5)
		oof()
		setAct("kicked")
		sayBubble(a.lines[math.random(#a.lines)])
		task.wait(2.6)
	else
		if a.pose2 then -- off the bed: sit up on the edge first
			setAct("getup", a.pose)
			task.wait(1.3)
		end
		setAct("idle")
		task.wait(1)
	end
	if winOf[a] then
		window(winOf[a], true)
	end
	kicked = false
	model:SetAttribute("KickDir", nil)
end

model:PivotTo(CFrame.new(world(N[at])))
setAct("idle")
model.Parent = workspace
pcall(root.SetNetworkOwner, root, nil)

task.spawn(function()
	local last = nil
	while true do
		while not playersNear() do
			task.wait(2)
		end
		local a = forced or pick(last)
		forced = nil
		if RunService:IsStudio() then
			print("Cortion: " .. a.name .. " (" .. a.spot .. ")")
		end
		local ok, err = pcall(run, a)
		if not ok then
			warn("Cortion: " .. tostring(err))
			removePrompt()
			setPC(false)
			setTV(false)
			setShower(false)
			task.wait(2)
		end
		last = a
		if not forced and math.random() < 0.4 then -- now and then he just wanders a bit
			walkTo(WANDER[math.random(#WANDER)])
			setAct("idle")
			hold(2 + math.random() * 3)
		end
	end
end)

-- Studio test hook (Play only): ServerStorage.CortionTest:Invoke(name) runs that activity next ("kick" kicks him)
if RunService:IsStudio() then
	local f = Instance.new("BindableFunction")
	f.Name = "CortionTest"
	f.OnInvoke = function(name: string)
		for _, a in ACTS :: any do
			if a.name == name or a.spot == name then
				forced = a
				return "ok"
			end
		end
		return "unknown"
	end
	f.Parent = ServerStorage
end
