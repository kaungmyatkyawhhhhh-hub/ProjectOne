-- GalaxyMapClient (Galaxy Incremental, 2 Nov): what each screen draws over the map (all client-side, nothing replicated):
--  * every owned island's STAR SYSTEM above it: a thin violet light beam (fading out at the bottom), a rock (new player) or a star, one planet per body tier owned on
--    its own orbit ring, stardust motes rising; others' systems simplified past MapConfig.LodDistance (star only)
--  * the NAME PLATE over each island: the player's name in their colour + their rank ("Supernova 3"), readable from the centre
--  * new island pieces POP in with a sparkle; islands whose Supernova is ready sparkle
--  * the Core pulses and its gyroscope rings turn; when anyone goes Supernova it BURSTS and a shockwave ring sweeps across
--    every island
--  * COMETS: the server sends them (MapEvent "CometSpawn": every 45 s, 30 s with Comet Lure); click / tap one to catch it
--    (the server pays it). The tutorial's comet crosses your view slowly, slows down more for 0.5 s and has a ring on it
--  * the ASTEROID BELT round each system: one small rock per body owned (max 20), so it grows with every buy
--  * the Sector 2 bridge: its segments light up one by one as YOUR Ignition checklist fills (the sign shows the list); all
--    done = all lit and the gate lets you through
--  * the island TERMINALS (Upgrades, from tier 1): click / tap the screen (ClickDetector, ~40 studs) or E at the prompt ->
--    ReplicatedStorage.Galaxy.OpenWindow(id) (the HUD opens the window), on the island OWNER's screen only (others see it,
--    nothing opens: their click range and prompt are switched off on this screen); hover brightens the beacon, a click bounces it
-- Sizes from MapConfig (redone to scale against the R15 character, 2 Nov night).
--  * the Black Hole's disk swirls; the leaderboard wall's PLAYERS NEAR YOU side shows YOUR neighbours (BoardEvent "Near")
-- Reduced Motion: no core pulse scale, no pop scale; the rest stays (it's information).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("Kit"))
local remote = Galaxy:WaitForChild("MapEvent", 30) :: RemoteEvent

local C = MapConfig.Colors
local O = MapConfig.Origin
local root = workspace:WaitForChild("Galaxy", 60)
if not root then return end
local islands = root:WaitForChild("Islands")
local calm = function(): boolean return GuiService.ReducedMotionEnabled end

local localFolder = Instance.new("Folder")
localFolder.Name = "GalaxyLocal"
localFolder.Parent = workspace

local openWindow = Galaxy:FindFirstChild("OpenWindow") or Instance.new("BindableEvent")
openWindow.Name = "OpenWindow"
openWindow.Parent = Galaxy

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local FONT_B = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)

local function tween(o, goal, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function sparkleBurst(at: Vector3, count: number, color: Color3?, size: number?)
	local host = Instance.new("Part")
	host.Anchored, host.CanCollide, host.CanQuery, host.CanTouch, host.Transparency = true, false, false, false, 1
	host.Size = Vector3.new(1, 1, 1)
	host.CFrame = CFrame.new(at)
	host.Parent = localFolder
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(color or Color3.fromRGB(255, 230, 160))
	e.LightEmission = 0.8
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, size or 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Speed = NumberRange.new(6, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Drag = 3
	e.Rate = 0
	e.Parent = host
	e:Emit(count)
	task.delay(1.6, function() host:Destroy() end)
end

------------------------------------------------------------------------
-- star systems + name plates
------------------------------------------------------------------------
local systems = {} -- [island] = { folder, star, planets = { {piece, parts, r, speed, angle} }, rings, motes, plate, h, near }
local seenTiers = {} -- [island] = BodyTiers last built (a new tier's planet flies in)
local loaded = false -- (true 2 s after start: pops and fly-ins only for changes after the map has loaded)

local SY = MapConfig.System
local function systemHeight(island): number
	return SY.Height
end

local function clearSystem(island)
	local s = systems[island]
	if not s then return end
	if s.folder then s.folder:Destroy() end
	if s.plate then s.plate:Destroy() end
	systems[island] = nil
end

local function buildPlate(island, s)
	local anchor = island:FindFirstChild("Anchor")
	if not anchor then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Plate_" .. island.Name
	gui.Adornee = anchor
	-- (sized in studs: readable from the centre, ~60 studs, and far plates shrink instead of piling up)
	gui.Size = UDim2.fromScale(SY.Plate.Width, SY.Plate.Height) -- (letters ~2.5 studs: readable from the plaza)
	gui.StudsOffsetWorldSpace = Vector3.new(0, s.h + SY.Plate.Above, 0)
	gui.MaxDistance = 600
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	local color = island:GetAttribute("Color") or C.Brass
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.56)
	name.FontFace = FONT
	name.TextScaled = true
	name.Text = island:GetAttribute("OwnerName") or ""
	name.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.15)
	name.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromRGB(16, 8, 24), 2.5
	stroke.Parent = name
	local rank = Instance.new("TextLabel")
	rank.BackgroundTransparency = 1
	rank.Position = UDim2.fromScale(0, 0.56)
	rank.Size = UDim2.fromScale(1, 0.38)
	rank.FontFace = FONT_B
	rank.TextScaled = true
	rank.Text = string.upper(island:GetAttribute("Rank") or "")
	rank.TextColor3 = Color3.fromRGB(240, 230, 255)
	rank.Parent = gui
	local stroke2 = stroke:Clone()
	stroke2.Thickness = 2
	stroke2.Parent = rank
	s.plate = gui
end

local function buildSystem(island)
	clearSystem(island)
	if (island:GetAttribute("Owner") or 0) == 0 then return end
	local c = island:GetAttribute("Center") :: Vector3
	if not c then return end
	local tiers, novas = island:GetAttribute("BodyTiers") or 0, island:GetAttribute("Supernovas") or 0
	local sys = MapConfig.SystemOf(tiers, novas)
	local h = systemHeight(island)
	local top = c + Vector3.new(0, h, 0)
	local folder = Instance.new("Folder")
	folder.Name = "System_" .. island.Name
	folder.Parent = localFolder
	local s = { folder = folder, planets = {}, rings = {}, h = h, top = top, near = true }
	-- the light beam from the island up to the system: thin, violet, fading to nothing at the bottom (owner, pass 3: the old
	-- white neon bar was too thick right in front of the camera on a phone)
	local beamHost = Instance.new("Part")
	beamHost.Name = "Beam"
	beamHost.Anchored, beamHost.CanCollide, beamHost.CanQuery, beamHost.CanTouch, beamHost.Transparency = true, false, false, false, 1
	beamHost.Size = Vector3.new(0.2, 0.2, 0.2)
	beamHost.CFrame = CFrame.new(c)
	beamHost.Parent = folder
	local b0, b1 = Instance.new("Attachment"), Instance.new("Attachment")
	b0.Position, b1.Position = Vector3.new(0, 0.3, 0), Vector3.new(0, h - 1.2, 0)
	b0.Parent, b1.Parent = beamHost, beamHost
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = b0, b1
	beam.Color = ColorSequence.new(Color3.fromRGB(175, 120, 255))
	beam.LightEmission = 1
	beam.Width0, beam.Width1 = 0.25, 0.25
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.55), NumberSequenceKeypoint.new(1, 0.15) })
	beam.Parent = beamHost
	if sys.star then
		local d = SY.StarMin + (SY.StarMax - SY.StarMin) * math.clamp((island:GetAttribute("Tier") or 0) / MapConfig.MaxTier, 0, 1)
		s.star = Kit.Make("CoreOrb", { Name = "Star", Fit = { "Y", d }, CFrame = CFrame.new(top), Color = C.Star, Material = Enum.Material.Neon, Parent = folder })
	else
		s.star = Kit.Make("RockBare", { Name = "Rock", Fit = { "X", SY.Rock }, CFrame = CFrame.new(top), Color = C.BareRock, Parent = folder })
	end
	local slot = island:GetAttribute("Slot") or 1
	local span = math.max(SY.MaxPlanets - 1, 1)
	for k = 1, sys.planets do
		local r = SY.OrbitMin + (SY.OrbitMax - SY.OrbitMin) * (k - 1) / span
		local tilt = CFrame.Angles(math.rad(8 * k), 0, math.rad(4 * k))
		local ring = Kit.Make("OrbitRing", { Name = "Orbit", Fit = { "X", r * 2 }, CFrame = CFrame.new(top) * tilt, Color = C.Orbit, Parent = folder })
		table.insert(s.rings, ring)
		local pd = SY.PlanetMin + (SY.PlanetMax - SY.PlanetMin) * (k - 1) / span
		local planet = Kit.Make("Planet", { Name = "Planet", Fit = { "Y", pd }, CFrame = CFrame.new(top), Color = MapConfig.PlanetColors[(k - 1) % #MapConfig.PlanetColors + 1],
			Reflectance = 0.1, Parent = folder })
		table.insert(s.planets, { piece = planet, parts = Kit.Parts(planet), r = r, tilt = tilt, speed = 0.9 / k, angle = k * 1.9 + slot })
	end
	-- a body tier that just appeared: its planet flies in from high up and snaps into its orbit, with a sparkle
	local before = seenTiers[island]
	seenTiers[island] = tiers
	if before and tiers > before and #s.planets > 0 and loaded then
		local pl = s.planets[math.min(tiers, #s.planets)]
		pl.flyFrom = top + Vector3.new(0, 40, 0) + (workspace.CurrentCamera.CFrame.RightVector * 30)
		pl.flyAt = os.clock()
	end
	-- the asteroid belt: one rock per body owned (island attribute Belt, max 20), outside the planets' orbits; each new
	-- rock keeps its place (golden-angle spacing), so a buy adds one instead of reshuffling them
	s.belt = {}
	local beltN = island:GetAttribute("Belt") or 0
	if beltN > 0 then
		local rb = SY.Belt
		local beltTilt = CFrame.Angles(math.rad(10), 0, math.rad(-6))
		for b = 1, beltN do
			local sz = SY.BeltRock[1] + (SY.BeltRock[2] - SY.BeltRock[1]) * ((b * 7) % 5) / 4
			local rock = Kit.Make("RockBare", { Name = "BeltRock", Fit = { "X", sz }, CFrame = CFrame.new(top), Color = C.BareRock, Parent = folder })
			table.insert(s.belt, { piece = rock, parts = Kit.Parts(rock), r = rb + ((b * 3) % 4) * 0.5, angle = b * 2.39996, tilt = beltTilt, dy = ((b * 5) % 3 - 1) * 0.5 })
		end
	end
	-- stardust motes rising from the island to the system
	local moteHost = Instance.new("Part")
	moteHost.Anchored, moteHost.CanCollide, moteHost.CanQuery, moteHost.CanTouch, moteHost.Transparency = true, false, false, false, 1
	moteHost.Size = Vector3.new(10, 0.2, 10)
	moteHost.CFrame = CFrame.new(c + Vector3.new(0, 0.6, 0))
	moteHost.Parent = folder
	local e = Instance.new("ParticleEmitter")
	e.Texture = SPARK
	e.Color = ColorSequence.new(C.Mote)
	e.LightEmission = 0.7
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(2.4, 3)
	e.Speed = NumberRange.new(h / 3, h / 2.5)
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(6, 6)
	e.Rate = 3 + 2 * sys.planets
	e.Parent = moteHost
	s.motes = e
	-- sparkles when the Supernova is ready
	if island:GetAttribute("Ready") then
		local r2 = e:Clone()
		r2.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200))
		r2.Speed = NumberRange.new(1, 3)
		r2.SpreadAngle = Vector2.new(180, 180)
		r2.Lifetime = NumberRange.new(0.8, 1.4)
		r2.Rate = 8
		local host = moteHost:Clone()
		host:ClearAllChildren()
		host.Size = Vector3.new(40, 6, 40)
		host.CFrame = CFrame.new(c + Vector3.new(0, 2, 0))
		host.Parent = folder
		r2.Parent = host
	end
	systems[island] = s
	buildPlate(island, s)
end

-- new pieces pop in (scale from nothing) with a sparkle; only after this screen has loaded the map
local function popIn(piece: Instance)
	if not loaded or not piece:GetAttribute("Pop") then return end
	task.defer(function()
		local parts = Kit.Parts(piece)
		if #parts == 0 then return end
		local cf, size
		if piece:IsA("Model") then cf, size = piece:GetBoundingBox() else cf, size = parts[1].CFrame, parts[1].Size end
		if not calm() then
			for _, p in ipairs(parts) do
				local full = p.Size
				p.Size = full * 0.05
				tween(p, { Size = full }, 0.45, Enum.EasingStyle.Back)
			end
		end
		sparkleBurst(cf.Position + Vector3.new(0, size.Y / 2, 0), 18 + math.floor(size.Magnitude), nil, 0.7)
	end)
end

local function watchIsland(island)
	if not island:IsA("Model") then return end
	buildSystem(island)
	for _, name in ipairs({ "Owner", "OwnerName", "Tier", "BodyTiers", "Supernovas", "Rank", "Ready", "Color", "Belt" }) do
		island:GetAttributeChangedSignal(name):Connect(function() buildSystem(island) end)
	end
	local pieces = island:WaitForChild("Pieces", 10)
	if pieces then pieces.ChildAdded:Connect(popIn) end
end
for _, island in ipairs(islands:GetChildren()) do task.spawn(watchIsland, island) end
islands.ChildAdded:Connect(watchIsland)
islands.ChildRemoved:Connect(clearSystem)
task.delay(2, function() loaded = true end)

------------------------------------------------------------------------
-- the Core: pulse, gyroscopes, and the Supernova burst + shockwave
------------------------------------------------------------------------
local centre = root:WaitForChild("Centre")
local core = centre:WaitForChild("Core")
local coreOrb = core:WaitForChild("CoreOrb")
local coreLightHost = core:FindFirstChild("CoreLight")
local coreLight = coreLightHost and coreLightHost:FindFirstChildOfClass("PointLight")
local orbSize = {}
for _, p in ipairs(Kit.Parts(coreOrb)) do orbSize[p] = p.Size end
local gyros = {}
for _, g in ipairs(core:GetChildren()) do
	if g:GetAttribute("Spin") then
		local parts = Kit.Parts(g)
		local pivot = CFrame.new(O + Vector3.new(0, MapConfig.Centre.CoreHeight, 0))
		local rel = {}
		for _, p in ipairs(parts) do rel[p] = pivot:ToObjectSpace(p.CFrame) end
		table.insert(gyros, { parts = parts, rel = rel, pivot = pivot, spin = g:GetAttribute("Spin") })
	end
end
local burstUntil = 0
local coreBase = if coreLight then coreLight.Brightness else 1.4
local coreRange = if coreLight then coreLight.Range else 24
local spawnComet -- (defined in the comets section; the remote handler below calls it)

local function shockwave()
	local n = 72
	local segs = {}
	for i = 1, n do
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 190, 110)
		p.Size = Vector3.new(0.5, 0.5, 1)
		p.Parent = localFolder
		segs[i] = p
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = (os.clock() - t0) / 1.9
		if t >= 1 then
			conn:Disconnect()
			for _, p in ipairs(segs) do p:Destroy() end
			return
		end
		local r = 14 + (MapConfig.Islands.Ring + MapConfig.Islands.Radius + 10) * (1 - (1 - t) ^ 2)
		local thick = 2.4 * (1 - t) + 0.5
		for i, p in ipairs(segs) do
			local a = (i - 0.5) / n * math.pi * 2
			p.Size = Vector3.new(thick, thick, 2 * math.pi * r / n * 1.05)
			p.CFrame = CFrame.new(O + Vector3.new(0, 3 + 4 * t, 0)) * CFrame.Angles(0, -a, 0) * CFrame.new(r, 0, 0)
		end
	end)
end

local function supernova(slot: number?)
	burstUntil = os.clock() + 1.2
	if coreLight then
		coreLight.Brightness = 8
		coreLight.Range = 60
		tween(coreLight, { Brightness = coreBase, Range = coreRange }, 1.4)
	end
	sparkleBurst(O + Vector3.new(0, MapConfig.Centre.CoreHeight, 0), 80, Color3.fromRGB(255, 210, 140), 1.4)
	shockwave()
	-- a burst over the player's island too
	local island = slot and islands:FindFirstChild("Island_" .. slot)
	local s = island and systems[island]
	if s then sparkleBurst(s.top, 60, Color3.fromRGB(255, 220, 150), 1.1) end
end
if remote then
	remote.OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "Supernova" then
			supernova(a)
		elseif kind == "CometSpawn" then
			spawnComet(a, b, c)
		end
	end)
end

------------------------------------------------------------------------
-- comets: streak past now and then; click / tap to catch
------------------------------------------------------------------------
local comets = {}
function spawnComet(id: number, seed: number, tutorial: boolean?)
	local rnd = Random.new(seed)
	local from, through
	local cam = workspace.CurrentCamera
	if tutorial and cam then
		-- the tutorial's comet: across the player's view, close and slow
		local cf = cam.CFrame
		local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
		local right = Vector3.new(-flat.Z, 0, flat.X)
		through = cf.Position + flat * 40 + Vector3.new(0, 4, 0)
		from = through - right * (if rnd:NextNumber() < 0.5 then -70 else 70) + Vector3.new(0, 12, 0)
	else
		local CM = MapConfig.Comets
		local a = rnd:NextNumber(0, math.pi * 2)
		from = O + Vector3.new(math.cos(a) * CM.From, rnd:NextNumber(CM.Low, CM.High), math.sin(a) * CM.From)
		through = O + Vector3.new(rnd:NextNumber(-CM.Through, CM.Through), rnd:NextNumber(CM.Low * 0.6, CM.Low * 1.2), rnd:NextNumber(-CM.Through, CM.Through))
	end
	local dir = (through - from).Unit
	local head = Kit.Make("LampOrb", { Name = "Comet", Fit = { "Y", MapConfig.Comets.Head }, CFrame = CFrame.new(from), Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, Parent = localFolder })
	local parts = Kit.Parts(head)
	local hit = Instance.new("Part")
	hit.Name = "CometHit"
	hit.Shape = Enum.PartType.Ball
	hit.Size = Vector3.new(1, 1, 1) * (if tutorial then MapConfig.Comets.TutorialHit else MapConfig.Comets.Hit)
	hit.Anchored, hit.CanCollide, hit.CanTouch, hit.CanQuery, hit.Transparency = true, false, false, true, 1
	hit.CFrame = CFrame.new(from)
	hit.Parent = localFolder
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 1.6, 0), Vector3.new(0, -1.6, 0)
	a0.Parent, a1.Parent = hit, hit
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(Color3.fromRGB(170, 235, 255), Color3.fromRGB(120, 140, 255))
	trail.LightEmission = 1
	trail.Lifetime = 1.1
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.FaceCamera = true
	trail.Parent = hit
	comets[hit] = { id = id, head = head, parts = parts, hit = hit, pos = from, dir = dir, born = os.clock(), through = through,
		speed = if tutorial then 22 else 60, life = if tutorial then 10 else 9, tutorial = tutorial, slowUntil = 0, slowed = false }
	if tutorial then
		-- a ring on it (first time only)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(9, 9)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Adornee = hit
		bb.Parent = hit
		local ring = Instance.new("Frame")
		ring.BackgroundTransparency = 1
		ring.Size = UDim2.fromScale(1, 1)
		ring.Parent = bb
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = ring
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(255, 216, 74)
		st.Thickness = 4
		st.Parent = ring
		tween(st, { Transparency = 0.6 }, 0.5)
		task.spawn(function()
			while st.Parent do
				tween(st, { Transparency = 0 }, 0.45)
				task.wait(0.45)
				tween(st, { Transparency = 0.6 }, 0.45)
				task.wait(0.45)
			end
		end)
	end
end
local function removeComet(comet, caught: boolean)
	comets[comet.hit] = nil
	if caught then
		sparkleBurst(comet.pos, 40, Color3.fromRGB(170, 235, 255), 1)
		if remote then remote:FireServer("Comet", comet.id) end
	end
	comet.head:Destroy()
	comet.hit:Destroy()
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local list = {}
	for hit in pairs(comets) do table.insert(list, hit) end
	if #list == 0 then return end
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = list
	local result = workspace:Raycast(ray.Origin, ray.Direction * 700, params)
	if result and comets[result.Instance] then removeComet(comets[result.Instance], true) end
end)

------------------------------------------------------------------------
-- the Sector 2 bridge: lit one segment at a time as YOUR Ignition checklist fills
------------------------------------------------------------------------
local nextS = root:WaitForChild("NextSector")
local NS = MapConfig.NextSector
-- (looked up every time: with StreamingEnabled the parts can arrive after this script starts)
local function segParts(i: number): { BasePart }
	local bridge = nextS:FindFirstChild("Bridge")
	if not bridge then return {} end
	for _, seg in ipairs(bridge:GetChildren()) do
		if seg:GetAttribute("Index") == i then
			local parts = Kit.Parts(seg)
			for _, p in ipairs(parts) do
				if not p:GetAttribute("FullSize") then p:SetAttribute("FullSize", p.Size) end
			end
			return parts
		end
	end
	return {}
end
local litNow = -1
local function styleSeg(i: number, lit: boolean)
	for _, p in ipairs(segParts(i)) do
		p.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
		p.Color = if lit then C.Bridge else C.BridgeDim
		local full = p:GetAttribute("FullSize") :: Vector3
		-- dashed while dim: every other dim segment is short
		p.Size = if lit or i % 2 == 1 then full else Vector3.new(full.X, full.Y, full.Z * 0.5)
	end
end
local function refreshIgnition(animate: boolean?)
	local done, total = MapConfig.IgnitionDone(player)
	local lit = NS.LitAtStart + math.floor((NS.BridgeSegments - NS.LitAtStart) * done / math.max(total, 1))
	if done >= total then lit = NS.BridgeSegments end
	local sign = nextS:FindFirstChild("IgnitionSign")
	for _, signGui in ipairs(sign and sign:GetChildren() or {}) do
		if not signGui:IsA("SurfaceGui") then continue end
		for i, item in ipairs(MapConfig.Ignition) do
			local row = signGui:FindFirstChild("Row" .. i)
			local v = player:GetAttribute(item.attribute)
			local n = if type(v) == "boolean" then (if v then 1 else 0) else (tonumber(v) or 0)
			if row then
				local ok = n >= item.need
				row.Text = (if ok then "[X]  " else "[  ]  ") .. item.text
				row.TextColor3 = if ok then Color3.fromRGB(120, 240, 150) else Color3.fromRGB(200, 190, 220)
			end
		end
	end
	local barrier = nextS:FindFirstChild("Barrier")
	if barrier then barrier.CanCollide = done < total end
	if litNow < 0 or not animate then
		for i = 1, NS.BridgeSegments do styleSeg(i, i <= lit) end
	elseif lit ~= litNow then
		-- light the new ones one by one (or dim them back)
		local from, to, step = litNow + 1, lit, 1
		if lit < litNow then from, to, step = litNow, lit + 1, -1 end
		task.spawn(function()
			for i = from, to, step do
				styleSeg(i, step > 0)
				local p = segParts(i)[1]
				if step > 0 and p then sparkleBurst(p.Position + Vector3.new(0, 1, 0), 10, C.Bridge, 0.5) end
				task.wait(0.12)
			end
		end)
	end
	litNow = lit
end
for _, item in ipairs(MapConfig.Ignition) do
	player:GetAttributeChangedSignal(item.attribute):Connect(function() refreshIgnition(true) end)
end
refreshIgnition(false)
-- (parts streamed in later: style them too)
local pending = false
nextS.DescendantAdded:Connect(function(d)
	if pending or not d:IsA("BasePart") then return end
	pending = true
	task.delay(0.5, function() pending = false refreshIgnition(false) end)
end)
local padlock = nextS:FindFirstChild("Padlock")
local padBase = {}
for _, p in ipairs(padlock and Kit.Parts(padlock) or {}) do padBase[p] = p.CFrame end

------------------------------------------------------------------------
-- the boards: "Open" -> the window (the UI listens to Galaxy.OpenWindow)
------------------------------------------------------------------------
local function ownsSlot(slot): boolean
	local island = slot and islands:FindFirstChild("Island_" .. tostring(slot))
	return island ~= nil and island:GetAttribute("Owner") == player.UserId
end
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local id = prompt:GetAttribute("Window")
	if not id or not prompt:IsDescendantOf(root) then return end
	if prompt:GetAttribute("Slot") and not ownsSlot(prompt:GetAttribute("Slot")) then return end
	openWindow:Fire(id)
end)

------------------------------------------------------------------------
-- the island terminals: click / tap (ClickDetector) or the prompt -> the window, the owner's screen only; hover brightens
-- the beacon; a click bounces the terminal
------------------------------------------------------------------------
local hooked = {}
local function hookTerminal(term: Model)
	if hooked[term] then return end
	hooked[term] = true
	local id = term:GetAttribute("Window")
	local slot = term:GetAttribute("Slot")
	local beacon = term:WaitForChild("Beacon", 20)
	if not id or not beacon then return end
	local bParts = Kit.Parts(beacon)
	local base = {}
	for _, p in ipairs(bParts) do base[p] = { size = p.Size, colour = p.Color } end
	local function hover(on: boolean)
		for _, p in ipairs(bParts) do
			tween(p, { Size = base[p].size * (if on then 1.35 else 1), Color = if on then base[p].colour:Lerp(Color3.new(1, 1, 1), 0.4) else base[p].colour }, 0.15)
		end
	end
	local busy = false
	local function bounce()
		if busy or calm() then return end
		busy = true
		local moving = {}
		for _, d in ipairs(term:GetDescendants()) do
			if d:IsA("BasePart") then moving[d] = d.CFrame end
		end
		for p, cf in pairs(moving) do tween(p, { CFrame = cf * CFrame.new(0, -0.4, 0) }, 0.07) end
		task.wait(0.07)
		for p, cf in pairs(moving) do tween(p, { CFrame = cf }, 0.3, Enum.EasingStyle.Back) end
		task.wait(0.3)
		busy = false
	end
	-- (owner only: on everyone else's screen the click range and the prompt are switched off, here, locally)
	local function apply()
		local mine = ownsSlot(slot)
		for _, d in ipairs(term:GetDescendants()) do
			if d:IsA("ClickDetector") then d.MaxActivationDistance = if mine then MapConfig.Terminal.ClickRange else 0 end
			if d:IsA("ProximityPrompt") then d.Enabled = mine end
		end
	end
	for _, click in ipairs(term:GetDescendants()) do
		if click:IsA("ClickDetector") then
			click.MouseHoverEnter:Connect(function() if ownsSlot(slot) then hover(true) end end)
			click.MouseHoverLeave:Connect(function() hover(false) end)
			click.MouseClick:Connect(function()
				if not ownsSlot(slot) then return end
				task.spawn(bounce)
				openWindow:Fire(id)
			end)
		end
	end
	apply()
	local island = islands:FindFirstChild("Island_" .. tostring(slot))
	if island then island:GetAttributeChangedSignal("Owner"):Connect(apply) end
end
local function scanTerminal(d: Instance)
	if d:IsA("Model") and d:GetAttribute("Window") and d.Name:match("^Terminal_") then task.spawn(hookTerminal, d) end
end
for _, d in ipairs(islands:GetDescendants()) do scanTerminal(d) end
islands.DescendantAdded:Connect(scanTerminal)

-- the Black Hole's disk, inner glow and 3 spiral arms (they turn round the ring's axis, each at its own speed)
local swirls = {}
task.spawn(function()
	local hole = centre:WaitForChild("BlackHoleGate", 20)
	if not hole then return end
	local ringCf = hole:GetAttribute("RingCF")
	if not ringCf then return end
	for _, name in ipairs({ "Disk", "InnerGlow", "Arms" }) do
		local piece = hole:WaitForChild(name, 20)
		if piece then
			local speed = piece:GetAttribute("Swirl") or 1
			for _, p in ipairs(Kit.Parts(piece)) do swirls[p] = { rel = ringCf:ToObjectSpace(p.CFrame), ring = ringCf, speed = speed } end
		end
	end
end)

-- the leaderboard wall: PLAYERS NEAR YOU (your own list from the server; you in gold)
local boardEvent = Galaxy:WaitForChild("BoardEvent", 30)
if boardEvent then
	boardEvent.OnClientEvent:Connect(function(kind, list)
		if kind ~= "Near" or type(list) ~= "table" then return end
		local lb = centre:FindFirstChild("Leaderboard")
		local wall = lb and lb:FindFirstChild("Wall")
		for _, gui in ipairs(wall and wall:GetChildren() or {}) do
			local near = gui:IsA("SurfaceGui") and gui:FindFirstChild("Near")
			if near then
				for r = 1, 11 do
					local row = near:FindFirstChild("Row" .. r)
					local e = list[r]
					if row then
						row.Text = if e then string.format("%s   %d", tostring(e.name), tonumber(e.value) or 0) else ""
						row.TextColor3 = if e and e.you then Color3.fromRGB(255, 214, 120) else Color3.fromRGB(225, 215, 240)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- every frame: planets orbit, near / far detail, the core, the comets
------------------------------------------------------------------------
local t0 = os.clock()
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock() - t0
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or O
	-- star systems
	for island, s in pairs(systems) do
		local near = (s.top - camPos).Magnitude <= MapConfig.LodDistance + s.h or (island:GetAttribute("Owner") == player.UserId)
		if near ~= s.near then
			s.near = near
			for _, ring in ipairs(s.rings) do ring.Parent = if near then s.folder else nil end
			for _, pl in ipairs(s.planets) do pl.piece.Parent = if near then s.folder else nil end
			for _, br in ipairs(s.belt or {}) do br.piece.Parent = if near then s.folder else nil end
			if s.motes then s.motes.Enabled = near end
		end
		if near then
			for _, pl in ipairs(s.planets) do
				pl.angle += dt * pl.speed
				local cf = CFrame.new(s.top) * pl.tilt * CFrame.new(math.cos(pl.angle) * pl.r, 0, math.sin(pl.angle) * pl.r)
				if pl.flyAt then
					local a = math.clamp((os.clock() - pl.flyAt) / 0.7, 0, 1)
					if a >= 1 then
						pl.flyAt = nil
						sparkleBurst(cf.Position, 24, Color3.fromRGB(220, 230, 255), 0.6)
					else
						local e = 1 - (1 - a) ^ 3
						cf = CFrame.new(pl.flyFrom:Lerp(cf.Position, e))
					end
				end
				for _, p in ipairs(pl.parts) do p.CFrame = cf end
			end
			for _, br in ipairs(s.belt or {}) do
				br.angle += dt * 0.12
				local cf = CFrame.new(s.top) * br.tilt * CFrame.new(math.cos(br.angle) * br.r, br.dy, math.sin(br.angle) * br.r) * CFrame.Angles(br.angle, br.angle * 0.7, 0)
				for _, p in ipairs(br.parts) do p.CFrame = cf end
			end
		end
	end
	-- the core: a slow pulse (a quick swell while bursting), the gyroscopes turn
	local burst = math.max(0, burstUntil - os.clock())
	local scale = 1 + (if calm() then 0 else 0.04 * math.sin(now * 2.2)) + burst * 0.5
	for p, size in pairs(orbSize) do p.Size = size * scale end
	if coreLight and burst <= 0 then coreLight.Brightness = coreBase * (1 + 0.18 * math.sin(now * 2.2)) end
	-- the Black Hole's disk swirls
	for p, s in pairs(swirls) do p.CFrame = s.ring * CFrame.Angles(0, now * s.speed, 0) * s.rel end
	for _, g in ipairs(gyros) do
		local rot = g.pivot * CFrame.Angles(0, now * g.spin, 0)
		for _, p in ipairs(g.parts) do p.CFrame = rot * g.rel[p] end
	end
	-- the next sector's padlock bobs and turns
	for p, base in pairs(padBase) do p.CFrame = base * CFrame.new(0, math.sin(now * 1.3) * 1.2, 0) * CFrame.Angles(0, now * 0.6, 0) end
	-- comets fly on, and go after a while
	for hit, comet in pairs(comets) do
		-- the tutorial comet slows right down for 0.5 s as it reaches the middle of your view (once)
		if comet.tutorial and not comet.slowed and (comet.pos - comet.through).Magnitude < 6 then
			comet.slowed = true
			comet.slowUntil = os.clock() + 0.5
		end
		local speed = comet.speed * (if os.clock() < comet.slowUntil then 0.15 else 1)
		comet.pos += comet.dir * speed * dt
		hit.CFrame = CFrame.lookAt(comet.pos, comet.pos + comet.dir)
		for _, p in ipairs(comet.parts) do p.CFrame = CFrame.new(comet.pos) end
		if os.clock() - comet.born > comet.life then removeComet(comet, false) end
	end
end)
