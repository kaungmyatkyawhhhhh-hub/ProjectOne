--[[
	Police (client)
	Police cars driven on this client (smooth, like traffic) and the wanted HUD.
	  * Patrols drive the streets. Speed past one above the limit (120 km/h) and it calls you in.
	  * Wanted (the server's "Wanted" attribute, 1-5 stars): 1 + half the stars units hunt you,
	    sirens and light bars going. They stay on the roads like traffic, taking the turns that
	    lead to you, and never drive into you (owner, 2026-10-24).
	  * When one catches up (close and in sight), a red zone rings the spot you're at: get out of it
	    within ZoneSeconds or you're BUSTED (a fine, stars cleared). Get out of sight and far enough
	    away for long enough, or outlast the chase timer: ESCAPED (a bounty).
	  * Speed cameras flash (white screen, shutter) when they catch you; everyone sees the flash.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local P = Config.Police
local Theme = Config.Theme
local player = Players.LocalPlayer

local Police = {}

type Unit = {
	model: Model,
	root: BasePart,
	pos: Vector3, -- ground point under the car's middle
	fwd: Vector3,
	speed: number,
	seg: CityLayout.Segment?,
	s: number,
	nextSeg: CityLayout.Segment?,
	direct: boolean, -- off the lane graph, driving straight at the target
	chasing: boolean,
	side: number, -- which side it tries to come alongside
	halfLen: number,
	height: number,
	red: BasePart,
	blue: BasePart,
	redLight: PointLight,
	blueLight: PointLight,
	siren: Sound?,
	los: boolean,
	losT: number,
	wheels: { Motor6D },
	spin: number,
}

local units: { Unit } = {}
local graph = CityLayout.buildGraph()
local rng = Random.new()
local folder: Folder
local report: RemoteEvent
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local wanted = 0
local loseT = 0
-- the police zone round you: where it is and how long you have left to get out of it
local zone: { center: Vector3, left: number }? = nil
local zoneCooldown = 0
local zoneModel: Model
local zoneText: TextLabel
local showZone: (at: Vector3?) -> ()
local reported = false -- busted / escaped sent, waiting for the server
local chaseT = 0 -- seconds since this chase started
local chaseLabel: TextLabel
local spotCooldown, losTimer = 0, 0

---------------------------------------------------------------------
-- HUD: stars, the busted bar, banners, the camera flash
---------------------------------------------------------------------
local gui: ScreenGui
local stars: { TextLabel } = {}
local bustBar: Frame
local bustFill: Frame
local banner: Frame
local bannerTitle: TextLabel
local bannerSub: TextLabel
local flashFrame: Frame
local edgeGlow: Frame

local function formatCash(n: number): string
	local s = tostring(math.floor(n))
	local f = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if f:sub(1, 1) == "," then
		f = f:sub(2)
	end
	return "$" .. f
end

local function buildHud()
	gui = Instance.new("ScreenGui")
	gui.Name = "PoliceHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 12
	gui.Parent = player:WaitForChild("PlayerGui")

	local row = Instance.new("Frame")
	row.Name = "Stars"
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 58)
	row.Size = UDim2.fromOffset(5 * 34, 34)
	row.BackgroundTransparency = 1
	row.Visible = false
	row.Parent = gui
	for i = 1, 5 do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromOffset(34, 34)
		l.Position = UDim2.fromOffset((i - 1) * 34, 0)
		l.Font = Enum.Font.GothamBlack
		l.Text = "★"
		l.TextSize = 30
		l.TextColor3 = Color3.fromRGB(255, 255, 255)
		l.TextTransparency = 0.75
		l.TextStrokeTransparency = 0.4
		l.Parent = row
		stars[i] = l
	end

	-- the chase timer under the stars
	chaseLabel = Instance.new("TextLabel")
	chaseLabel.Name = "ChaseTimer"
	chaseLabel.AnchorPoint = Vector2.new(0.5, 0)
	chaseLabel.Position = UDim2.new(0.5, 0, 0, 92)
	chaseLabel.Size = UDim2.fromOffset(260, 20)
	chaseLabel.BackgroundTransparency = 1
	chaseLabel.Font = Enum.Font.GothamBlack
	chaseLabel.TextSize = 15
	chaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	chaseLabel.TextStrokeTransparency = 0.5
	chaseLabel.Visible = false
	chaseLabel.Parent = gui

	bustBar = Instance.new("Frame")
	bustBar.AnchorPoint = Vector2.new(0.5, 0)
	bustBar.Position = UDim2.new(0.5, 0, 0, 116)
	bustBar.Size = UDim2.fromOffset(220, 26)
	bustBar.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
	bustBar.BackgroundTransparency = 0.15
	bustBar.Visible = false
	bustBar.Parent = gui
	Instance.new("UICorner").Parent = bustBar
	bustFill = Instance.new("Frame")
	bustFill.Size = UDim2.fromScale(0, 1)
	bustFill.BackgroundColor3 = Theme.Danger
	bustFill.Parent = bustBar
	Instance.new("UICorner").Parent = bustFill
	local bustText = Instance.new("TextLabel")
	bustText.BackgroundTransparency = 1
	bustText.Size = UDim2.fromScale(1, 1)
	bustText.Font = Enum.Font.GothamBlack
	bustText.TextSize = 13
	bustText.TextColor3 = Color3.new(1, 1, 1)
	bustText.Text = "GET OUT OF THE ZONE"
	bustText.ZIndex = 2
	bustText.Parent = bustBar
	-- the zone's countdown over the bar
	zoneText = Instance.new("TextLabel")
	zoneText.AnchorPoint = Vector2.new(0.5, 1)
	zoneText.Position = UDim2.new(0.5, 0, 0, 114)
	zoneText.Size = UDim2.fromOffset(420, 40)
	zoneText.BackgroundTransparency = 1
	zoneText.Font = Enum.Font.GothamBlack
	zoneText.TextSize = 30
	zoneText.TextColor3 = Color3.fromRGB(255, 60, 60)
	zoneText.TextStrokeTransparency = 0.3
	zoneText.Visible = false
	zoneText.Parent = gui

	banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.3)
	banner.Size = UDim2.fromOffset(520, 110)
	banner.BackgroundTransparency = 1
	banner.Visible = false
	banner.Parent = gui
	bannerTitle = Instance.new("TextLabel")
	bannerTitle.BackgroundTransparency = 1
	bannerTitle.Size = UDim2.new(1, 0, 0, 64)
	bannerTitle.Font = Enum.Font.GothamBlack
	bannerTitle.TextSize = 58
	bannerTitle.TextStrokeTransparency = 0.3
	bannerTitle.Parent = banner
	bannerSub = Instance.new("TextLabel")
	bannerSub.BackgroundTransparency = 1
	bannerSub.Position = UDim2.fromOffset(0, 66)
	bannerSub.Size = UDim2.new(1, 0, 0, 30)
	bannerSub.Font = Enum.Font.GothamBold
	bannerSub.TextSize = 22
	bannerSub.TextColor3 = Color3.new(1, 1, 1)
	bannerSub.TextStrokeTransparency = 0.4
	bannerSub.Parent = banner

	flashFrame = Instance.new("Frame")
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	flashFrame.BackgroundTransparency = 1
	flashFrame.ZIndex = 20
	flashFrame.Parent = gui

	-- red / blue glow at the screen edges while police are close
	edgeGlow = Instance.new("Frame")
	edgeGlow.Size = UDim2.fromScale(1, 1)
	edgeGlow.BackgroundTransparency = 1
	edgeGlow.Parent = gui
	local st = Instance.new("UIStroke")
	st.Name = "Glow"
	st.Thickness = 18
	st.Transparency = 1
	st.Color = Color3.fromRGB(255, 30, 40)
	st.Parent = edgeGlow
end

local bannerToken = 0
local function showBanner(title: string, sub: string, color: Color3, seconds: number?)
	bannerToken += 1
	local my = bannerToken
	bannerTitle.Text = title
	bannerTitle.TextColor3 = color
	bannerSub.Text = sub
	banner.Visible = true
	banner.Size = UDim2.fromOffset(620, 130)
	TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(520, 110) }):Play()
	task.delay(seconds or 3, function()
		if bannerToken == my then
			banner.Visible = false
		end
	end)
end

local function setStars(level: number, blinking: boolean)
	local row = stars[1].Parent :: Frame
	row.Visible = level > 0
	local on = not blinking or (os.clock() * 3) % 1 < 0.6
	for i, l in stars do
		local lit = i <= level
		l.TextColor3 = if lit then Color3.fromRGB(255, 214, 64) else Color3.fromRGB(255, 255, 255)
		l.TextTransparency = if lit then (if on then 0 else 0.6) else 0.8
	end
end

---------------------------------------------------------------------
-- Units
---------------------------------------------------------------------
local function target(): (Vector3?, Vector3, number, number)
	-- the player's position, velocity, speed and half length (in a car or on foot)
	local root = Driving.getRoot()
	if root then
		local m = Driving.getModel()
		local half = if m then ((m:GetAttribute("Length") :: number?) or 14) / 2 else 7
		local v = root.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		return root.Position, flat, flat.Magnitude, half
	end
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		local v = hrp.AssemblyLinearVelocity
		local flat = Vector3.new(v.X, 0, v.Z)
		return hrp.Position, flat, flat.Magnitude, 1
	end
	return nil, Vector3.zero, 0, 0
end

local function lightBar(model: Model, root: BasePart, height: number, len: number): (BasePart, BasePart, PointLight, PointLight)
	local function piece(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material): Part
		local p = Instance.new("Part")
		p.Size = size
		p.CFrame = root.CFrame * offset
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		return p
	end
	local top = height * 0.42
	piece(Vector3.new(3.2, 0.35, 0.9), CFrame.new(0, top, len * 0.02), Color3.fromRGB(20, 20, 24), Enum.Material.SmoothPlastic)
	local red = piece(Vector3.new(1.4, 0.4, 0.7), CFrame.new(-0.8, top + 0.3, len * 0.02), Color3.fromRGB(90, 0, 0), Enum.Material.Glass)
	local blue = piece(Vector3.new(1.4, 0.4, 0.7), CFrame.new(0.8, top + 0.3, len * 0.02), Color3.fromRGB(0, 10, 90), Enum.Material.Glass)
	local rl = Instance.new("PointLight")
	rl.Color = Color3.fromRGB(255, 30, 30)
	rl.Range = 26
	rl.Brightness = 0
	rl.Parent = red
	local bl = Instance.new("PointLight")
	bl.Color = Color3.fromRGB(40, 80, 255)
	bl.Range = 26
	bl.Brightness = 0
	bl.Parent = blue
	-- "POLICE" on both doors
	for _, sx in { -1, 1 } do
		local panel = piece(Vector3.new(0.05, 0.9, len * 0.42), CFrame.new(sx * 3.05, -height * 0.05, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		panel.Transparency = 1
		local g = Instance.new("SurfaceGui")
		g.Face = if sx < 0 then Enum.NormalId.Left else Enum.NormalId.Right
		g.CanvasSize = Vector2.new(400, 80)
		g.LightInfluence = 0.5
		g.Parent = panel
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.GothamBlack
		t.TextScaled = true
		t.Text = "POLICE"
		t.TextColor3 = Color3.fromRGB(235, 240, 255)
		t.Parent = g
	end
	return red, blue, rl, bl
end

local function placeOnLane(u: Unit, seg: CityLayout.Segment, s: number)
	u.seg = seg
	u.s = s
	u.nextSeg = nil
	u.direct = false
	local pos, fwd = CityLayout.sample(seg, s)
	u.pos = pos
	u.fwd = fwd
end

-- a lane spot between minD and maxD from `center`, out of the camera's view when possible
local function laneSpot(center: Vector3, minD: number, maxD: number): (CityLayout.Segment?, number)
	local cam = workspace.CurrentCamera
	local best: CityLayout.Segment?, bestS = nil, 0
	for _ = 1, 60 do
		local seg = graph.lanes[rng:NextInteger(1, #graph.lanes)]
		local s = rng:NextNumber(5, math.max(6, seg.length - 5))
		local pos = CityLayout.sample(seg, s)
		local d = Vector3.new(pos.X - center.X, 0, pos.Z - center.Z).Magnitude
		if d >= minD and d <= maxD then
			best, bestS = seg, s
			if not cam or (pos - cam.CFrame.Position).Unit:Dot(cam.CFrame.LookVector) < 0.4 then
				return seg, s
			end
		end
	end
	return best, bestS
end

local function spawnUnit(near: Vector3, minD: number, maxD: number): Unit?
	local seg, s = laneSpot(near, minD, maxD)
	if not seg then
		return nil
	end
	local spec = Cars.ById[P.CarId] or Cars.get(Cars.StarterId)
	local model = CarBuilder.build(spec, { anchored = true, driver = true, simpleWheels = true, lite = true, color = Color3.fromRGB(16, 17, 22) })
	CarSkin.apply(model, true, true)
	model.Name = "PoliceCar"
	local root = model.PrimaryPart :: BasePart
	local len = (model:GetAttribute("Length") :: number?) or 15
	local height = (model:GetAttribute("Height") :: number?) or 4.6
	local red, blue, rl, bl = lightBar(model, root, height, len)
	local wheels: { Motor6D } = {}
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
		end
	end
	local u: Unit = {
		model = model,
		root = root,
		pos = Vector3.zero,
		fwd = Vector3.zAxis,
		speed = Config.mphToSps(P.PatrolMph) * 0.8,
		seg = nil,
		s = 0,
		nextSeg = nil,
		direct = false,
		chasing = false,
		side = if #units % 2 == 0 then 1 else -1,
		halfLen = len / 2,
		height = height,
		red = red,
		blue = blue,
		redLight = rl,
		blueLight = bl,
		siren = nil,
		los = false,
		losT = 0,
		wheels = wheels,
		spin = 0,
	}
	placeOnLane(u, seg, s)
	model:PivotTo(CFrame.lookAt(u.pos, u.pos + u.fwd) + Vector3.new(0, height / 2, 0))
	model.Parent = folder
	table.insert(units, u)
	return u
end

local function removeUnit(i: number)
	local u = units[i]
	u.model:Destroy()
	table.remove(units, i)
end

local function setChasing(u: Unit, on: boolean)
	if u.chasing == on then
		return
	end
	u.chasing = on
	if on then
		local id = Audio.pickCustom("Siren")
		if id then
			local snd = Instance.new("Sound")
			snd.SoundId = id
			snd.Looped = true
			snd.Volume = 0.55
			snd.RollOffMinDistance = 30
			snd.RollOffMaxDistance = 700
			snd.Parent = u.root
			snd:Play()
			u.siren = snd
		end
	else
		if u.siren then
			u.siren:Destroy()
			u.siren = nil
		end
		u.redLight.Brightness = 0
		u.blueLight.Brightness = 0
		u.red.Color = Color3.fromRGB(90, 0, 0)
		u.blue.Color = Color3.fromRGB(0, 10, 90)
		u.red.Material = Enum.Material.Glass
		u.blue.Material = Enum.Material.Glass
	end
end

-- the closest lane spot to a point (to get back onto the roads after driving straight)
local function nearestLane(pos: Vector3): (CityLayout.Segment?, number)
	local best: CityLayout.Segment?, bestS, bestD = nil, 0, math.huge
	for _, seg in graph.lanes do
		local a, b = seg.p0, seg.p2
		local mid = (a + b) / 2
		local reach = seg.length / 2 + 60
		if math.abs(mid.X - pos.X) < reach and math.abs(mid.Z - pos.Z) < reach then
			for k = 0, 8 do
				local s = seg.length * k / 8
				local p = CityLayout.sample(seg, s)
				local d = (Vector3.new(p.X - pos.X, 0, p.Z - pos.Z)).Magnitude
				if d < bestD then
					best, bestS, bestD = seg, s, d
				end
			end
		end
	end
	return best, bestS
end

local function chooseNext(u: Unit, goal: Vector3?): CityLayout.Segment?
	local seg = u.seg
	if not seg or #seg.next == 0 then
		return nil
	end
	if not goal then
		-- patrol: mostly straight on
		local options = seg.next
		if rng:NextNumber() < 0.6 then
			for _, o in options do
				if o.dir == seg.dir then
					return o
				end
			end
		end
		return options[rng:NextInteger(1, #options)]
	end
	-- hunting: the branch that ends closest to the target, looking one more step ahead
	local best, bestD = nil, math.huge
	for _, o in seg.next do
		local d = (o.p2 - goal).Magnitude
		for _, o2 in o.next do
			d = math.min(d, (o2.p2 - goal).Magnitude + 1)
		end
		if d < bestD then
			best, bestD = o, d
		end
	end
	return best
end

local function groundY(pos: Vector3, fallback: number): number
	local hit = workspace:Raycast(pos + Vector3.new(0, 18, 0), Vector3.new(0, -50, 0), rayParams)
	return if hit then hit.Position.Y else fallback
end

local function lineOfSight(a: Vector3, b: Vector3): boolean
	local from = a + Vector3.new(0, 3, 0)
	local dir = (b + Vector3.new(0, 3, 0)) - from
	return workspace:Raycast(from, dir, rayParams) == nil
end

local function stepUnit(u: Unit, dt: number, tPos: Vector3?, tVel: Vector3, tSpeed: number)
	local chasing = wanted > 0 and tPos ~= nil
	setChasing(u, chasing)
	local goal = if chasing and tPos then tPos + tVel * 0.5 else nil
	local dist = if tPos then Vector3.new(tPos.X - u.pos.X, 0, tPos.Z - u.pos.Z).Magnitude else math.huge

	-- (owner, 2026-10-24: like traffic, never off the roads, never into you)
	if u.direct then
		local seg, s = nearestLane(u.pos)
		if seg then
			placeOnLane(u, seg, s)
		end
		u.direct = false
	end
	local top = Config.mphToSps(P.ChaseMph[math.clamp(wanted, 1, 5)])
	local seg = u.seg
	if not seg then
		return
	end
	local want: number
	if chasing then
		-- catch up fast when far behind
		want = if dist > 400 then top * 1.35 else top
	else
		want = Config.mphToSps(P.PatrolMph) * seg.speedK
		-- stop on red like everyone else
		if seg.signal and seg.kind == "lane" then
			local state = CityLayout.lightState(seg.i, seg.j, seg.axis, workspace:GetServerTimeNow())
			local remaining = seg.length - u.s
			if state ~= "G" and remaining < 40 and remaining > -2 then
				want = math.min(want, math.max(0, (remaining - 1) * 1.2))
			end
		end
	end
	-- never drive into the player: hold back behind you (closer and slower the nearer you are)
	if tPos then
		local rel = Vector3.new(tPos.X - u.pos.X, 0, tPos.Z - u.pos.Z)
		local ahead = rel:Dot(u.fwd)
		if ahead > 0 and ahead < 60 and math.abs(rel:Dot(u.fwd:Cross(Vector3.yAxis))) < 9 then
			local gap = ahead - 22
			want = math.min(want, math.max(0, math.min(tSpeed + gap * 0.8, gap * 2.5)))
		end
	end
	local accel = if want > u.speed then (if chasing then 60 else 40) else 110
	u.speed += math.clamp(want - u.speed, -accel * dt, accel * dt)
	u.s += u.speed * dt
	while u.seg and u.s >= (u.seg :: CityLayout.Segment).length do
		local cur = u.seg :: CityLayout.Segment
		u.s -= cur.length
		local nxt = u.nextSeg or chooseNext(u, goal)
		if not nxt then
			u.s = cur.length
			u.speed = 0
			break
		end
		u.seg = nxt
		u.nextSeg = nil
	end
	if u.seg and not u.nextSeg and goal == nil then
		u.nextSeg = chooseNext(u, nil)
	end
	local pos, fwd = CityLayout.sample(u.seg :: CityLayout.Segment, u.s)
	u.pos = Vector3.new(pos.X, pos.Y, pos.Z)
	u.fwd = fwd

	-- light bar
	if chasing then
		local phase = (os.clock() * 4) % 1 < 0.5
		u.redLight.Brightness = if phase then 6 else 0
		u.blueLight.Brightness = if phase then 0 else 6
		u.red.Material = if phase then Enum.Material.Neon else Enum.Material.Glass
		u.blue.Material = if phase then Enum.Material.Glass else Enum.Material.Neon
		u.red.Color = if phase then Color3.fromRGB(255, 30, 30) else Color3.fromRGB(90, 0, 0)
		u.blue.Color = if phase then Color3.fromRGB(0, 10, 90) else Color3.fromRGB(40, 90, 255)
	end
	u.spin = (u.spin - u.speed * dt / 1.1) % (math.pi * 2)
	local spinCF = CFrame.Angles(u.spin, 0, 0)
	for _, w in u.wheels do
		w.Transform = spinCF
	end
end

---------------------------------------------------------------------
-- The police zone on the ground: a faint red disc, a glowing ring and a low wall of light
---------------------------------------------------------------------
local ZONE_SEGS = 40
local function buildZone()
	zoneModel = Instance.new("Model")
	zoneModel.Name = "PoliceZone"
	local function piece(name: string, size: Vector3, transparency: number, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 40, 40)
		p.Transparency = transparency
		p.Size = size
		if shape then
			p.Shape = shape
		end
		p.Parent = zoneModel
		return p
	end
	local R = P.ZoneRadius
	piece("Disc", Vector3.new(0.2, R * 2, R * 2), 0.88, Enum.PartType.Cylinder)
	for i = 1, ZONE_SEGS do
		piece("Ring", Vector3.new(2 * math.pi * R / ZONE_SEGS + 0.3, 0.6, 1.2), 0.2)
		piece("Wall", Vector3.new(2 * math.pi * R / ZONE_SEGS + 0.3, 6, 0.3), 0.75)
	end
end

-- shows the zone round `at` on the ground (nil hides it)
showZone = function(at: Vector3?)
	if not at then
		zoneModel.Parent = nil
		return
	end
	local y = groundY(at, at.Y - 2)
	local R = P.ZoneRadius
	local ring, wall = 0, 0
	for _, p in zoneModel:GetChildren() do
		local part = p :: BasePart
		if part.Name == "Disc" then
			part.CFrame = CFrame.new(at.X, y + 0.12, at.Z) * CFrame.Angles(0, 0, math.pi / 2)
		else
			local i = if part.Name == "Ring" then ring else wall
			local a = (i + 0.5) / ZONE_SEGS * 2 * math.pi
			local h = if part.Name == "Ring" then 0.3 else 3
			part.CFrame = CFrame.new(at.X + math.cos(a) * R, y + h, at.Z + math.sin(a) * R) * CFrame.Angles(0, -a + math.pi / 2, 0)
			if part.Name == "Ring" then
				ring += 1
			else
				wall += 1
			end
		end
	end
	zoneModel.Parent = workspace
end

---------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------
local function update(dt: number)
	dt = math.min(dt, 0.1)
	local tPos, tVel, tSpeed = target()
	local level = wanted
	local focus = tPos or (workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position) or Vector3.zero

	-- how many units, and get rid of far ones nobody needs
	local want = if level > 0 then math.min(math.floor(1 + level * P.UnitsPerStar), P.MaxUnits) else P.Patrols
	for i = #units, 1, -1 do
		local u = units[i]
		local d = Vector3.new(u.pos.X - focus.X, 0, u.pos.Z - focus.Z).Magnitude
		if #units > want and d > 260 then
			removeUnit(i)
		elseif level == 0 and d > 900 then
			-- recycle a patrol that drifted far away
			local seg, s = laneSpot(focus, 300, 600)
			if seg then
				placeOnLane(u, seg, s)
			end
		end
	end
	if #units < want then
		if level > 0 then
			spawnUnit(focus, 280, 450)
		else
			spawnUnit(focus, 250, 600)
		end
	end

	-- sight lines (5 times a second)
	losTimer += dt
	local checkLos = losTimer > 0.2
	if checkLos then
		losTimer = 0
		local ignore: { Instance } = { folder }
		local traffic = workspace:FindFirstChild("Traffic")
		local cars = workspace:FindFirstChild("PlayerCars")
		if traffic then
			table.insert(ignore, traffic)
		end
		if cars then
			table.insert(ignore, cars)
		end
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(ignore, p.Character)
			end
		end
		rayParams.FilterDescendantsInstances = ignore
	end

	local seen, closest = false, math.huge
	local closeNear: Unit? = nil
	for _, u in units do
		if tPos and checkLos then
			local d = (u.pos - tPos).Magnitude
			u.los = d < P.LoseRange and lineOfSight(u.pos, tPos)
		end
		if u.los then
			u.losT = 0
		else
			u.losT += dt
		end
		stepUnit(u, dt, tPos, tVel, tSpeed)
		if tPos then
			local d = Vector3.new(tPos.X - u.pos.X, 0, tPos.Z - u.pos.Z).Magnitude
			if d < closest then
				closest = d
				closeNear = u
			end
			if u.los and d < P.LoseRange then
				seen = true
			end
		end
	end

	-- move them all at once
	local parts, cfs = {}, {}
	for _, u in units do
		local up = Vector3.new(0, u.height / 2, 0)
		table.insert(parts, u.root)
		table.insert(cfs, CFrame.lookAt(u.pos + up, u.pos + up + u.fwd))
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	spotCooldown = math.max(0, spotCooldown - dt)
	local kmh = Config.spsToMph(tSpeed) * 1.609

	if level == 0 then
		loseT, reported = 0, false
		chaseT = 0
		if zone then
			zone = nil
			showZone(nil)
		end
		-- speeding past a patrol that can see you
		if tPos and Driving.isDriving() and kmh > P.SpeedLimitKmh + 5 and spotCooldown <= 0 and closeNear and closest < P.SpotRange and closeNear.los then
			spotCooldown = 8
			report:FireServer("spotted")
		end
	elseif tPos and not reported then
		-- the police zone: a unit that catches up rings you in; out of it in time or busted
		zoneCooldown = math.max(0, zoneCooldown - dt)
		if not zone then
			if zoneCooldown <= 0 and closeNear and closest < P.ZoneTrigger and closeNear.los then
				zone = { center = tPos, left = P.ZoneSeconds }
				showZone(tPos)
				Audio.play("CameraFlash", 0.4)
			end
		else
			local z = zone :: { center: Vector3, left: number }
			local off = Vector3.new(tPos.X - z.center.X, 0, tPos.Z - z.center.Z).Magnitude
			if off > P.ZoneRadius then
				zone = nil
				zoneCooldown = P.ZoneCooldown
				showZone(nil)
				showBanner("OUT OF THE ZONE", "Keep going!", Theme.Accent, 1.5)
			else
				z.left -= dt
				if z.left <= 0 then
					zone = nil
					showZone(nil)
					reported = true
					report:FireServer("busted")
				end
			end
		end
		-- escaped: no unit sees you for long enough
		if seen then
			loseT = 0
		else
			loseT += dt
		end
		-- ...or the chase runs out of time (owner: a timer when the police stop chasing)
		chaseT += dt
		local limit = P.ChaseSeconds[math.clamp(level, 1, 5)]
		if loseT >= P.LoseSeconds[math.clamp(level, 1, 5)] or chaseT >= limit then
			reported = true
			report:FireServer("escaped")
		end
	end

	-- HUD
	setStars(level, level > 0 and loseT > 0.6)
	if level > 0 then
		local left = math.max(0, math.ceil(P.ChaseSeconds[math.clamp(level, 1, 5)] - chaseT))
		chaseLabel.Text = string.format("POLICE GIVE UP IN %d:%02d", left // 60, left % 60)
		chaseLabel.Visible = true
	else
		chaseLabel.Visible = false
	end
	local z = zone
	bustBar.Visible = z ~= nil
	zoneText.Visible = z ~= nil
	if z then
		bustFill.Size = UDim2.fromScale(math.clamp(z.left / P.ZoneSeconds, 0, 1), 1)
		zoneText.Text = string.format("POLICE ZONE  ·  %d", math.ceil(z.left))
		local pulse = (os.clock() * 2) % 1 < 0.5
		for _, p in zoneModel:GetChildren() do
			if p:IsA("BasePart") and p.Name == "Ring" then
				p.Transparency = if pulse then 0.15 else 0.45
			end
		end
	end
	local glow = edgeGlow:FindFirstChild("Glow") :: UIStroke
	if level > 0 and closest < 140 then
		local phase = (os.clock() * 4) % 1 < 0.5
		glow.Color = if phase then Color3.fromRGB(255, 30, 40) else Color3.fromRGB(40, 90, 255)
		glow.Transparency = 0.55 + 0.4 * (closest / 140)
	else
		glow.Transparency = 1
	end
end

local function onEvent(info: any)
	if type(info) ~= "table" then
		return
	end
	if info.kind == "wanted" then
		local level = tonumber(info.level) or 0
		local old = wanted
		wanted = level
		reported = false
		loseT = 0
		if level == 0 and zone then
			zone = nil
			showZone(nil)
		end
		if level > old and level > 0 then
			local why = if info.reason == "camera" then "SPEED CAMERA"
				elseif info.reason == "spotted" then "SPOTTED SPEEDING"
				elseif info.reason == "rammed" then "ASSAULT ON POLICE"
				elseif info.reason == "bank" then "BANK ROBBERY"
				else "POLICE ARE COMING"
			showBanner(string.rep("★", level), why, Color3.fromRGB(255, 214, 64), 2.5)
		end
	elseif info.kind == "camera" then
		flashFrame.BackgroundTransparency = 0.05
		TweenService:Create(flashFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		Audio.play("CameraFlash", 0.8)
		showBanner("SPEED CAMERA", `{info.kmh} KM/H  ·  LIMIT {info.limit}  ·  FINE {formatCash(tonumber(info.fine) or 0)}`, Theme.Warning, 3)
	elseif info.kind == "flash" then
		local cams = workspace:FindFirstChild("SpeedCameras")
		local cam = if cams then cams:FindFirstChild("SpeedCamera" .. tostring(info.id)) else nil
		local lens = if cam then cam:FindFirstChild("Lens") else nil
		local light = if lens then lens:FindFirstChild("Flash") :: PointLight? else nil
		if light then
			light.Brightness = 12
			TweenService:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
		end
	elseif info.kind == "busted" then
		wanted = 0
		showBanner("BUSTED", `Fine {formatCash(tonumber(info.fine) or 0)}`, Theme.Danger, 4)
		Audio.crash(0.4)
	elseif info.kind == "escaped" then
		wanted = 0
		showBanner("ESCAPED", `Bounty +{formatCash(tonumber(info.reward) or 0)}`, Theme.Money, 4)
		Audio.cutUp(3, "ESCAPED")
	end
end

function Police.getWanted(): number
	return wanted
end

-- where the police cars are (the minimap's blips)
function Police.getUnitPositions(): { Vector3 }
	local out = {}
	for _, u in units do
		if u.model.Parent then
			table.insert(out, u.pos)
		end
	end
	return out
end

function Police.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	report = remotes:WaitForChild("PoliceReport") :: RemoteEvent
	local event = remotes:WaitForChild("PoliceEvent") :: RemoteEvent
	folder = Instance.new("Folder")
	folder.Name = "Police"
	folder.Parent = workspace
	buildHud()
	buildZone()
	wanted = (player:GetAttribute("Wanted") :: number?) or 0
	event.OnClientEvent:Connect(onEvent)
	player:GetAttributeChangedSignal("Wanted"):Connect(function()
		wanted = (player:GetAttribute("Wanted") :: number?) or 0
	end)
	RunService.Heartbeat:Connect(update)
end

return Police
