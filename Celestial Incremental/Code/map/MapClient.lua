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
--  * the island BOARDS are drawn by GalaxyBoards (live UI with buttons, like Regrowth's)
-- Sizes from MapConfig (redone to scale against the R15 character, 2 Nov night).
--  * the Black Hole's disk swirls; the leaderboard wall's PLAYERS NEAR YOU side shows YOUR neighbours (BoardEvent "Near")
-- Reduced Motion: no core pulse scale, no pop scale; the rest stays (it's information).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("Kit"))
local UIAssets = require(Galaxy:WaitForChild("UIAssets"))
local UIKit = require(Galaxy:WaitForChild("UIKit")) -- (alpha part 2: the comet / island-piece sounds, Galaxy.Sounds)
local Econ = require(Galaxy:WaitForChild("EconConfig"))
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

-- every effect: VfxLibrary (the VFX pass, 6 Nov: our own textures, VfxTextures; pooled, budgeted, Reduced Motion aware)
local Vfx = require(Galaxy:WaitForChild("VfxLibrary"))
local VT = Vfx.T
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local FONT_B = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)

local function tween(o, goal, t, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	tw:Play()
	return tw
end
local function sparkleBurst(at: Vector3, count: number, color: Color3?, size: number?)
	Vfx.Sparkles(at, count, color, size)
end
-- a ring that flashes out from `at` (a new body's arrival, a tier-up): the shockwave_ring texture growing and fading
local function ringFlash(at: Vector3, radius: number, color: Color3, t: number?)
	Vfx.Ring(at, radius, color, t or 0.45)
end
-- an island owner's rank colour (#298: the Supernova's colour changes with your rank): the band of the rank's first word
local function rankColour(island): Color3
	local rank = tostring(island and island:GetAttribute("Rank") or "")
	for _, b in ipairs(Econ.LevelBands) do
		if string.sub(rank, 1, #b.name) == b.name then return b.colour end
	end
	return Color3.fromRGB(255, 205, 90)
end

------------------------------------------------------------------------
-- star systems + name plates
------------------------------------------------------------------------
local systems = {} -- [island] = { folder, star, planets = { {piece, parts, r, speed, angle} }, rings, motes, plate, h, near }
local seenTiers = {} -- [island] = bodies in orbit last built (a new type's / copy's body flies in)
local seenSys = {} -- [island] = { [type] = named tier } last built (a tier-up pulses that type's bodies, #286)
local seenNovas = {} -- [island] = Supernovas last built (the newest nebula blooms in slowly, #295)
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

local RankPlate = require(Galaxy:WaitForChild("RankPlate"))
local Art = require(Galaxy:WaitForChild("ArtIds")) -- (7 Nov: the new UI art: plaques, checks)
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: no world clicks while a 2D window is open)
local PLATE_FAR = 140
-- (6 Nov, rank title art: the owner's name, then the RANK PLATE (RankPlate: the rank's banner, emblem, title), then a small
-- line "GALAXY 12% · ✦3"; sized in PIXELS so it reads from the plaza; past PLATE_FAR studs only the emblem)
local function buildPlate(island, s)
	local anchor = island:FindFirstChild("Anchor")
	if not anchor then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Plate_" .. island.Name
	gui.Adornee = anchor
	gui.StudsOffsetWorldSpace = Vector3.new(0, s.h + SY.Plate.Above, 0)
	gui.MaxDistance = 600
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	local h = if Vfx.phone() then 26 else 32
	local color = island:GetAttribute("Color") or C.Brass
	local full = Instance.new("Frame")
	full.Name = "Full"
	full.BackgroundTransparency = 1
	full.Parent = gui
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.FontFace = RankPlate.FONT
	name.TextSize = math.floor(h * 0.85)
	name.Text = island:GetAttribute("OwnerName") or ""
	name.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.15)
	name.Parent = full
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = Color3.fromRGB(16, 8, 24), 2.5
	stroke.Parent = name
	local nameH = math.floor(h * 0.95)
	local w = math.max(game:GetService("TextService"):GetTextSize(name.Text, name.TextSize, Enum.Font.LuckiestGuy, Vector2.new(10000, 1000)).X + 12, 60)
	local y = nameH
	local rankText = string.upper(island:GetAttribute("Rank") or "")
	local base = string.gsub(rankText, "%s*·%s*✦%d+$", "")
	local novasN = string.match(rankText, "✦(%d+)$")
	local key = RankPlate.keyOf(base)
	local plate
	if base ~= "" then
		plate = RankPlate.build(full, base, key, h)
		plate.Position = UDim2.fromOffset(0, y)
		w = math.max(w, plate:GetAttribute("W"))
		y += h + 2
	end
	local lit = island:GetAttribute("Lit") or 0
	local info = (if lit > 0 then "GALAXY " .. lit .. "%" else "") .. (if novasN then (if lit > 0 then " · " else "") .. "✦" .. novasN else "")
	if info ~= "" then
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Position = UDim2.fromOffset(0, y)
		line.Parent = full
		local lh = math.floor(h * 0.55)
		line.Size = UDim2.fromOffset(math.max(w, 10), lh)
		local labels = UIKit.rankLine(line, info, FONT_B)
		for _, l in ipairs(labels) do
			l.TextColor3 = Color3.fromRGB(240, 230, 255)
			local stroke2 = stroke:Clone()
			stroke2.Thickness = 2
			stroke2.Parent = l
		end
		-- (rankLine fills its frame: keep the line about as wide as its text)
		line.Size = UDim2.fromOffset(math.min(w, #info * lh * 0.62), lh)
		line.Position = UDim2.fromOffset((w - line.Size.X.Offset) / 2, y)
		y += lh
	end
	-- centre the name + the plate in the widest
	name.Size = UDim2.fromOffset(w, nameH)
	if plate then plate.Position = UDim2.fromOffset((w - plate:GetAttribute("W")) / 2, nameH) end
	full.Size = UDim2.fromOffset(w, y)
	full.Position = UDim2.fromOffset(0, h * 0.2)
	local far = RankPlate.emblem(gui, key, h * 1.3)
	far.Name = "Far"
	far.Position = UDim2.new(0.5, 0, 1, -h * 0.7)
	far.Visible = false
	gui.Size = UDim2.fromOffset(w, y + h * 0.2)
	gui.Parent = playerGui
	s.plate = gui
	s.plateFull, s.plateFar = full, far
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
	-- the light beam up to the system: thin, violet, fading to nothing at the bottom (owner, pass 3: the old white neon bar
	-- was too thick right in front of the camera on a phone). It starts at System.BeamFrom, above the boards' tops (boards
	-- pass 3: from the spawn it ran up across the INFO board)
	local beamHost = Instance.new("Part")
	beamHost.Name = "Beam"
	beamHost.Anchored, beamHost.CanCollide, beamHost.CanQuery, beamHost.CanTouch, beamHost.Transparency = true, false, false, false, 1
	beamHost.Size = Vector3.new(0.2, 0.2, 0.2)
	beamHost.CFrame = CFrame.new(c)
	beamHost.Parent = folder
	local b0, b1 = Instance.new("Attachment"), Instance.new("Attachment")
	b0.Position, b1.Position = Vector3.new(0, SY.BeamFrom, 0), Vector3.new(0, h - 1.2, 0)
	b0.Parent, b1.Parent = beamHost, beamHost
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = b0, b1
	-- (alpha part 1: GOLD and a bit wider while the island's owner is ready to go Supernova)
	local ready = island:GetAttribute("Ready") == true
	beam.Color = ColorSequence.new(if ready then Color3.fromRGB(255, 205, 90) else Color3.fromRGB(175, 120, 255))
	beam.LightEmission = 1
	beam.Texture = VT.alpha.light_streak
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Width0, beam.Width1 = if ready then 1.6 else 0.7, if ready then 1.6 else 0.7
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.55), NumberSequenceKeypoint.new(1, 0.15) })
	beam.Parent = beamHost
	-- the island's star lights its island a little, stronger by tier (lighting pass: "my star lights my island"); a light
	-- below the star, so its range reaches the floor; no shadows; none on a low-end device (GalaxyLighting)
	local tierK = math.clamp((island:GetAttribute("Tier") or 0) / MapConfig.MaxTier, 0, 1)
	if not shared.GalaxyLowEnd then
		local LS = MapConfig.Lighting.Star
		local lightHost = Instance.new("Part")
		lightHost.Name = "StarLightHost"
		lightHost.Anchored, lightHost.CanCollide, lightHost.CanQuery, lightHost.CanTouch, lightHost.Transparency = true, false, false, false, 1
		lightHost.Size = Vector3.new(0.2, 0.2, 0.2)
		lightHost.CFrame = CFrame.new(c + Vector3.new(0, LS.Height, 0))
		lightHost.Parent = folder
		local starLight = Instance.new("PointLight")
		starLight.Name = "StarLight"
		starLight.Color = C.Star
		starLight.Range = LS.RangeMin + (LS.RangeMax - LS.RangeMin) * tierK
		starLight.Brightness = LS.Brightness
		starLight.Shadows = false
		starLight.Parent = lightHost
	end
	if sys.star then
		local d = SY.StarMin + (SY.StarMax - SY.StarMin) * tierK
		s.star = Kit.Make("CoreOrb", { Name = "Star", Fit = { "Y", d }, CFrame = CFrame.new(top), Color = C.Star, Material = Enum.Material.Neon, Parent = folder })
	else
		s.star = Kit.Make("RockBare", { Name = "Rock", Fit = { "X", SY.Rock }, CFrame = CFrame.new(top), Color = C.BareRock, Parent = folder })
	end
	s.starSize = {}
	for _, p in ipairs(Kit.Parts(s.star)) do s.starSize[p] = p.Size end
	-- the nebula patches that stay in the sky over the island, one per Supernova (alpha part 1, VFX plan "the world remembers
	-- it"): soft glows, seeded by the island and the count so they never move
	local NB = MapConfig.Supernova
	for i = 1, math.min(novas, NB.Nebulae) do
		local rnd = Random.new((island:GetAttribute("Slot") or 1) * 101 + i * 7)
		local a = rnd:NextNumber(0, math.pi * 2)
		local host = Instance.new("Part")
		host.Name = "Nebula"
		host.Anchored, host.CanCollide, host.CanQuery, host.CanTouch, host.Transparency = true, false, false, false, 1
		host.Size = Vector3.new(0.2, 0.2, 0.2)
		host.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * rnd:NextNumber(15, 45), NB.NebulaHeight + rnd:NextNumber(-10, 20), math.sin(a) * rnd:NextNumber(15, 45)))
		host.Parent = folder
		local bb = Instance.new("BillboardGui")
		local size = NB.NebulaSize * rnd:NextNumber(0.7, 1.2)
		bb.Size = UDim2.fromScale(size, size * 0.6)
		bb.LightInfluence = 0
		bb.MaxDistance = 1000
		bb.Parent = host
		local hue = ({ Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 190), Color3.fromRGB(110, 170, 255), Color3.fromRGB(255, 190, 110) })[i % 4 + 1]
		for j = 1, 4 do
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = VT.alpha.nebula_wisp
			img.ImageColor3 = hue:Lerp(Color3.new(1, 1, 1), (j - 1) * 0.12)
			img.ImageTransparency = 0.55 + j * 0.08
			img.AnchorPoint = Vector2.new(0.5, 0.5)
			img.Position = UDim2.fromScale(rnd:NextNumber(0.3, 0.7), rnd:NextNumber(0.35, 0.65))
			img.Size = UDim2.fromScale(rnd:NextNumber(0.5, 1), rnd:NextNumber(0.5, 1))
			img.Rotation = rnd:NextNumber(0, 360)
			img.Parent = bb
			-- (#295: the newest nebula BLOOMS in over ~2 s instead of appearing; fast rings + slow cloud together)
			if i == novas and (seenNovas[island] or novas) < novas and loaded and not calm() then
				local goalT, goalS = img.ImageTransparency, img.Size
				img.ImageTransparency = 1
				img.Size = UDim2.fromScale(goalS.X.Scale * 0.3, goalS.Y.Scale * 0.3)
				task.delay(0.4 + j * 0.15, function()
					tween(img, { ImageTransparency = goalT, Size = goalS }, 2.2, Enum.EasingStyle.Sine)
				end)
			end
		end
	end
	seenNovas[island] = novas
	local slot = island:GetAttribute("Slot") or 1
	local span = math.max(SY.MaxPlanets - 1, 1)
	-- the BODIES (feel pass, 5 Nov): one orbit per body type you have, its copies (+BODY, max 5) spaced round it; each
	-- copy's surface = the type's named tier (MapConfig.BodyLooks). Island attribute Sys = "namedTier:copies," per type
	local types = {}
	for t, n in string.gmatch(island:GetAttribute("Sys") or "", "(%d+):(%d+)") do table.insert(types, { tier = tonumber(t), copies = tonumber(n) }) end
	local total = 0
	for k, ty in ipairs(types) do
		if ty.tier > 0 and ty.copies > 0 then
			local r = SY.OrbitMin + (SY.OrbitMax - SY.OrbitMin) * (k - 1) / span
			local tilt = CFrame.Angles(math.rad(8 * k), 0, math.rad(4 * k))
			local ring = Kit.Make("OrbitRing", { Name = "Orbit", Fit = { "X", r * 2 }, CFrame = CFrame.new(top) * tilt, Color = C.Orbit, Parent = folder })
			table.insert(s.rings, ring)
			local pd = SY.PlanetMin + (SY.PlanetMax - SY.PlanetMin) * (k - 1) / span
			local look = MapConfig.BodyLooks[math.clamp(ty.tier, 1, #MapConfig.BodyLooks)]
			local base = MapConfig.PlanetColors[(k - 1) % #MapConfig.PlanetColors + 1]
			for c = 1, ty.copies do
				local size = pd * (if c == 1 then 1 else 0.8)
				local body = Kit.Make(if k == 1 then "RockBare" else "Planet", { Name = "Body", Fit = { if k == 1 then "X" else "Y", size }, CFrame = CFrame.new(top),
					Color = base:Lerp(look.color, look.blend), Material = look.material, Reflectance = if look.material == Enum.Material.Ice then 0.15 else 0, Parent = folder })
				local parts = Kit.Parts(body)
				local sizes = {}
				for _, p in ipairs(parts) do sizes[p] = p.Size end
				table.insert(s.planets, { piece = body, parts = parts, sizes = sizes, r = r, tilt = tilt, speed = 0.9 / k, angle = k * 1.9 + slot + (c - 1) * (2 * math.pi / ty.copies),
					k = k, tier = ty.tier, colour = base:Lerp(look.color, look.blend) })
				total += 1
			end
		end
	end
	-- a new body type or copy: the newest one flies in from high up and snaps into its orbit, with a sparkle
	local before = seenTiers[island]
	seenTiers[island] = total
	if before and total > before and #s.planets > 0 and loaded then
		local pl = s.planets[#s.planets]
		pl.flyFrom = top + Vector3.new(0, 40, 0) + (workspace.CurrentCamera.CFrame.RightVector * 30)
		pl.flyAt = os.clock()
		-- (#285: a STREAK behind it while it flies in; wider for a bigger type: the escalation ladder, #278)
		local p0 = pl.parts[1]
		if p0 then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = Vector3.new(0, 0.5, 0), Vector3.new(0, -0.5, 0)
			a0.Parent, a1.Parent = p0, p0
			local tr = Instance.new("Trail")
			tr.Attachment0, tr.Attachment1 = a0, a1
			tr.Texture = VT.alpha.light_streak
			tr.TextureMode = Enum.TextureMode.Stretch
			tr.LightEmission, tr.LightInfluence = 1, 0
			tr.Lifetime = 0.35
			tr.WidthScale = NumberSequence.new(1 + 0.4 * (pl.k - 1), 0)
			tr.Color = ColorSequence.new(pl.colour:Lerp(Color3.new(1, 1, 1), 0.5), pl.colour)
			tr.Parent = p0
			pl.trail = tr
		end
	end
	-- (#286: a type that reached a new NAMED TIER (every 10 levels, x2): its bodies pulse, a gold ring, an "x2" pop)
	local prevSys = seenSys[island]
	local nowSys = {}
	for k, ty in ipairs(types) do nowSys[k] = ty.tier end
	seenSys[island] = nowSys
	if prevSys and loaded then
		for k, ty in ipairs(types) do
			if (prevSys[k] or 0) > 0 and ty.tier > prevSys[k] then
				for _, pl in ipairs(s.planets) do
					if pl.k == k then pl.pulseAt = os.clock() + 0.05 end
				end
				task.delay(0.1, function() Vfx.Milestone(top, 26 + 4 * k) end)
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.fromOffset(160, 60)
				bb.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
				bb.LightInfluence = 0
				bb.AlwaysOnTop = true
				bb.MaxDistance = 220
				local host = Instance.new("Part")
				host.Anchored, host.CanCollide, host.CanQuery, host.CanTouch, host.Transparency = true, false, false, false, 1
				host.Size = Vector3.new(0.2, 0.2, 0.2)
				host.CFrame = CFrame.new(top)
				host.Parent = localFolder
				bb.Adornee = host
				bb.Parent = playerGui
				local _, _, holder = UIKit.text(bb, 0, 0, 160, 60, "x2", 52, { TextXAlignment = Enum.TextXAlignment.Center, FontFace = UIKit.FONT_HEAVY, stroke = 3,
					gradient = ColorSequence.new(Color3.fromRGB(255, 241, 192), Color3.fromRGB(255, 176, 42)) })
				local _h = holder
				tween(bb, { StudsOffsetWorldSpace = Vector3.new(0, 9, 0) }, 1.3, Enum.EasingStyle.Quad)
				task.delay(1.4, function() bb:Destroy() host:Destroy() end)
			end
		end
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
	-- stardust motes rising up the beam to the system (from the beam's foot, above the boards)
	local moteHost = Instance.new("Part")
	moteHost.Anchored, moteHost.CanCollide, moteHost.CanQuery, moteHost.CanTouch, moteHost.Transparency = true, false, false, false, 1
	moteHost.Size = Vector3.new(6, 0.2, 6)
	moteHost.CFrame = CFrame.new(c + Vector3.new(0, SY.BeamFrom, 0))
	moteHost.Parent = folder
	local e = Instance.new("ParticleEmitter")
	-- (7 Nov, owner: "black boxes again": every particle / beam / trail texture is the _alpha file now (transparent background),
	-- so no LightEmission value can show the _add file's black square. Tools/VfxTextureAudit checks it)
	e.Texture = VT.alpha.stardust_mote
	e.Color = ColorSequence.new(C.Mote)
	e.LightEmission = 0.7
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.55), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(2.4, 3)
	e.Speed = NumberRange.new((h - SY.BeamFrom) / 3, (h - SY.BeamFrom) / 2.5)
	e.EmissionDirection = Enum.NormalId.Top
	e.SpreadAngle = Vector2.new(6, 6)
	e.Rate = 3 + 2 * sys.planets
	e.Parent = moteHost
	s.motes = e
	-- sparkles when the Supernova is ready
	if island:GetAttribute("Ready") then
		local r2 = e:Clone()
		r2.Texture = VT.alpha.starburst_twinkle -- (warm: the white-cored star takes the tint; sparkle_star is cyan)
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
		Vfx.PadBuild(cf.Position - Vector3.new(0, size.Y / 2, 0), math.max(size.X, size.Z))
		UIKit.sound("piecePop", { at = cf.Position })
	end)
end

local function watchIsland(island)
	if not island:IsA("Model") then return end
	buildSystem(island)
	for _, name in ipairs({ "Owner", "OwnerName", "Tier", "BodyTiers", "Supernovas", "Rank", "Ready", "Color", "Belt", "Sys", "Lit" }) do
		island:GetAttributeChangedSignal(name):Connect(function() buildSystem(island) end)
	end
	-- (the VFX pass (c): the island grows a TIER: the rune circle under it, a beam up, the crown burst, confetti)
	local tierSeen = island:GetAttribute("Tier") or 0
	island:GetAttributeChangedSignal("Tier"):Connect(function()
		local now = island:GetAttribute("Tier") or 0
		local c = island:GetAttribute("Center")
		if now > tierSeen and loaded and c then
			Vfx.IslandTierUp(c, rankColour(island), island:GetAttribute("Owner") == player.UserId)
		end
		tierSeen = now
	end)
	local pieces = island:WaitForChild("Pieces", 10)
	if pieces then pieces.ChildAdded:Connect(popIn) end
end
for _, island in ipairs(islands:GetChildren()) do task.spawn(watchIsland, island) end
islands.ChildAdded:Connect(watchIsland)
islands.ChildRemoved:Connect(clearSystem)
task.delay(2, function() loaded = true end)

------------------------------------------------------------------------
-- the ISLAND PADS (feel pass, 5 Nov): the next pad's label (name, price, a bonus star), green when you can buy it, grey when
-- not; a bobbing arrow over it while you can; a click / tap buys it (EconRequest "BuyPad" + the island slot). Visitors only see
-- the label.
local econRequest = Galaxy:WaitForChild("EconRequest", 30)
local padUI = {} -- [island] = { pad, gui, price, ... }
local function padLabel(island, pad: Model)
	local old = padUI[island]
	if old and old.gui then old.gui:Destroy() end
	padUI[island] = nil
	if not pad or not pad.Parent then return end
	local disc = pad:WaitForChild("Disc", 5)
	if not disc then return end
	local mine = island:GetAttribute("Owner") == player.UserId
	-- (7 Nov, owner: "the STAR DAIS arrow points at empty floor, beside the dais". The disc is a cylinder turned 90 deg on Z
	-- to lie flat, and a BillboardGui's offset follows its adornee's rotation: "+4.2 up" was 4.2 studs SIDEWAYS, at floor
	-- height. Now: an upright attachment on the pad is the adornee; the label's BOTTOM (the arrow's tip) sits the pad's
	-- half height + 3 studs straight above it (SizeOffset lifts the label by half its size), a 0.5-stud bob)
	local anchor = Instance.new("Attachment")
	anchor.Name = "LabelAnchor"
	anchor.Parent = disc
	anchor.WorldCFrame = CFrame.new(disc.Position)
	local lift = math.min(disc.Size.X, disc.Size.Y, disc.Size.Z) / 2 + 3
	local bb = Instance.new("BillboardGui")
	bb.Name = "PadLabel"
	bb.Adornee = anchor
	bb.SizeOffset = Vector2.new(0, 0.5)
	bb.StudsOffsetWorldSpace = Vector3.new(0, lift, 0)
	bb.MaxDistance = 30 -- (7 Nov, phone HUD: sized in studs, seen from 30)
	bb.LightInfluence = 0
	-- (not AlwaysOnTop: the prompt asked for it, but Studio's capture can't show always-on-top billboards, so it couldn't
	-- be checked before the launch; 3 studs over open floor nothing hides it)
	bb.AlwaysOnTop = false
	bb.Parent = playerGui
	-- (top to bottom: the name, the price, the bonus, then the arrow pointing DOWN at the pad)
	local holder = UIKit.studsBillboard(bb, 220, 124, 6.5)
	local name = UIKit.text(holder, 0, 0, 220, 30, pad:GetAttribute("PadName") or "", 24, { TextXAlignment = Enum.TextXAlignment.Center, FontFace = UIKit.FONT_HEAVY, stroke = 2.4 })
	local priceIcon = UIKit.icon(holder, "stardust", 58, 32, 30, nil, { ZIndex = 3 })
	local price = UIKit.text(holder, 90, 34, 120, 28, Econ.Format(pad:GetAttribute("Price") or 0), 24, { FontFace = UIKit.FONT_HEAVY, stroke = 2.2 })
	local bonus = if pad:GetAttribute("Bonus") then UIKit.text(holder, 0, 62, 220, 20, "x1.15 STARDUST", 15, { TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.fromRGB(255, 216, 74), stroke = 1.6 }) else nil
	local arrow = Instance.new("ImageLabel")
	arrow.BackgroundTransparency = 1
	arrow.Image = UIAssets.arrow
	arrow.Size = UDim2.fromOffset(40, 40)
	arrow.Position = UDim2.fromOffset(90, 84)
	arrow.Visible = false
	arrow.Parent = holder
	local ui = { pad = pad, gui = bb, name = name, price = price, priceIcon = priceIcon, arrow = arrow, disc = disc, mine = mine, bonus = bonus, lift = lift, deniedUntil = 0 }
	padUI[island] = ui
	-- (7 Nov, the TYCOON BUTTON: the server presses it when you walk onto it (EconService). Press: the disc sinks 0.25 studs
	-- in 0.12 s + a click, then the buy sound as it's bought (the build VFX follow, as for a click). Denied: a soft no, a red
	-- flash and "NEED x" for a moment, once per step-on)
	pad:GetAttributeChangedSignal("Press"):Connect(function()
		UIKit.sound("click")
		for _, part in ipairs({ disc, pad:FindFirstChild("Rim") }) do
			if part and part:IsA("BasePart") then tween(part, { CFrame = part.CFrame - Vector3.new(0, 0.25, 0) }, 0.12, Enum.EasingStyle.Quad) end
		end
		if mine then task.delay(0.15, function() UIKit.sound("buy") end) end
	end)
	pad:GetAttributeChangedSignal("Denied"):Connect(function()
		if not mine then return end
		UIKit.sound("no")
		ui.deniedUntil = os.clock() + 1.2
	end)
	if mine then
		local click = disc:FindFirstChildOfClass("ClickDetector")
		if click then
			click.MouseClick:Connect(function()
				if not econRequest or WM.anyOpen() then return end
				local ok = econRequest:InvokeServer("BuyPad", nil, island:GetAttribute("Slot"))
				UIKit.sound(if ok then "buy" else "no")
			end)
		end
	end
end
local function watchPads(island)
	if not island:IsA("Model") then return end
	island.ChildAdded:Connect(function(c) if c.Name == "NextPad" then padLabel(island, c) end end)
	island.ChildRemoved:Connect(function(c) if c.Name == "NextPad" and padUI[island] and padUI[island].pad == c then padLabel(island, nil) end end)
	local now = island:FindFirstChild("NextPad")
	if now then task.spawn(padLabel, island, now) end
end
for _, island in ipairs(islands:GetChildren()) do watchPads(island) end
islands.ChildAdded:Connect(watchPads)
-- the label's colour + the arrow: green / white when you can pay, grey / red when not (4 times a second)
task.spawn(function()
	while true do
		task.wait(0.25)
		local sd = player:GetAttribute("Stardust") or 0
		for island, ui in pairs(padUI) do
			-- (7 Nov hotfix: with streaming, an island's pad label can go away under us: skip it, never stop the loop)
			if ui.pad.Parent and ui.price.Parent and ui.disc.Parent then
				local cost = ui.pad:GetAttribute("Price") or math.huge
				local can = ui.mine and sd >= cost
				local denied = os.clock() < ui.deniedUntil
				ui.disc.Color = if denied then Color3.fromRGB(255, 80, 80) elseif can then Color3.fromRGB(90, 255, 140) elseif ui.mine then Color3.fromRGB(130, 215, 255) else Color3.fromRGB(120, 112, 140)
				ui.price.TextColor3 = if can or not ui.mine then Color3.new(1, 1, 1) else Color3.fromRGB(255, 107, 107)
				UIKit.setText(ui.price, if denied then "NEED " .. Econ.Format(math.max(0, cost - sd)) else Econ.Format(cost))
				ui.arrow.Visible = can
			end
		end
	end
end)

-- (the pad label bobs 0.5 studs, smoothly; Reduced Motion: still)
RunService.RenderStepped:Connect(function()
	local bob = if calm() then 0 else (math.sin(os.clock() * 3) + 1) * 0.25
	for _, ui in pairs(padUI) do
		if ui.gui and ui.gui.Parent then ui.gui.StudsOffsetWorldSpace = Vector3.new(0, ui.lift + bob, 0) end
	end
end)

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
local windupFx -- (your Supernova's wind-up effect, stopped at the impact)
local coreBase = if coreLight then coreLight.Brightness else 1.4
local coreRange = if coreLight then coreLight.Range else 24
local spawnComet -- (defined in the comets section; the remote handler below calls it)
-- (#305: the Core's slow turning rays, always on: 3 particles alive)
Vfx.CoreRays(O + Vector3.new(0, MapConfig.Centre.CoreHeight, 0), Color3.fromRGB(255, 200, 120))
-- (#288: the STAR SURGE fills: a gold wave rolls over the plaza from the Core + its rays flare, for everyone)
local surgeSeen = Galaxy:GetAttribute("SurgeUntil") or 0
Galaxy:GetAttributeChangedSignal("SurgeUntil"):Connect(function()
	local v = Galaxy:GetAttribute("SurgeUntil") or 0
	if v > surgeSeen and v > workspace:GetServerTimeNow() then Vfx.StarSurge(O + Vector3.new(0, MapConfig.Centre.CoreHeight, 0)) end
	surgeSeen = v
end)

local function shockwave(delay: number?)
	if delay and delay > 0 then task.wait(delay) end
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
	local coreAt = O + Vector3.new(0, MapConfig.Centre.CoreHeight, 0)
	Vfx.CorePulse(coreAt, Color3.fromRGB(255, 210, 140))
	sparkleBurst(coreAt, 50, Color3.fromRGB(255, 210, 140), 1.4)
	-- (alpha part 1: two rings across the plaza and the islands, the second a beat later)
	for i = 1, MapConfig.Supernova.Shockwaves do task.spawn(shockwave, (i - 1) * 0.3) end
	-- the burst over the player's island (everyone sees it; at the system's height: the system itself is rebuilt as the rock)
	local island = slot and islands:FindFirstChild("Island_" .. slot)
	local c = island and island:GetAttribute("Center")
	if c then
		local top = c + Vector3.new(0, systemHeight(island), 0)
		-- (#298: the colour is your rank's; it grows a little with every Supernova you've made)
		local col = rankColour(island)
		local grow = 1 + math.min(island:GetAttribute("Supernovas") or 0, 20) * 0.04
		-- (the VFX pass: the 3 beats from VfxLibrary: the flash flipbook + starburst + rays on frame 0, two rings across the
		-- floor, shards + the explosion, then embers, the nebula blooming and violet smoke; yours flashes + shakes)
		local mine = island:GetAttribute("Owner") == player.UserId
		if windupFx then windupFx:Stop() windupFx = nil end
		Vfx.Supernova(top, col, grow, mine)
	end
end

-- the SUPERNOVA wind-up on YOUR island (GalaxySupernova calls it): the bodies spiral into your star while it swells and
-- pulses faster and faster; `dur` seconds, then it holds until the system is rebuilt (the server's reset)
shared.GalaxyWindup = function(dur: number)
	for island, s in pairs(systems) do
		if island:GetAttribute("Owner") == player.UserId then
			s.windup = { t0 = os.clock(), dur = dur }
			-- (stardust pulled into the star + arcs crackling round it, faster at the end)
			if windupFx then windupFx:Stop() end
			windupFx = Vfx.SupernovaWindup(s.top, rankColour(island), dur)
		end
	end
end
shared.GalaxyWindupCancel = function()
	for _, s in pairs(systems) do s.windup = nil end
	if windupFx then windupFx:Stop() windupFx = nil end
end
if remote then
	remote.OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "Supernova" then
			supernova(a)
		elseif kind == "CometSpawn" then
			spawnComet(a, b, c, d)
		end
	end)
end

------------------------------------------------------------------------
-- comets: streak past now and then; click / tap to catch
------------------------------------------------------------------------
local comets = {}
function spawnComet(id: number, seed: number, tutorial: boolean?, golden: boolean?)
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
	-- (a GOLDEN comet, run 1 only, pays x5: gold head + gold trail, a bit bigger)
	local head = Kit.Make("LampOrb", { Name = "Comet", Fit = { "Y", MapConfig.Comets.Head * (if golden then 1.35 else 1) }, CFrame = CFrame.new(from),
		Color = if golden then Color3.fromRGB(255, 205, 70) else Color3.fromRGB(150, 230, 255), Material = Enum.Material.Neon, Parent = localFolder })
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
	trail.Color = if golden then ColorSequence.new(Color3.fromRGB(255, 230, 140), Color3.fromRGB(255, 150, 40)) else ColorSequence.new(Color3.fromRGB(170, 235, 255), Color3.fromRGB(120, 140, 255))
	trail.LightEmission = 1
	trail.Texture = VT.alpha.comet_tail
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.Lifetime = 1.1
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.FaceCamera = true
	trail.Parent = hit
	UIKit.sound("cometAppear")
	comets[hit] = { id = id, head = head, parts = parts, hit = hit, pos = from, dir = dir, born = os.clock(), through = through,
		speed = if tutorial then 22 else 60, life = if tutorial then 10 else 9, tutorial = tutorial, slowUntil = 0, slowed = false, golden = golden }
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
		Vfx.CometCatch(comet.pos, if comet.golden then Color3.fromRGB(255, 215, 110) else nil, comet.golden)
		UIKit.sound("cometCatch")
		if remote then remote:FireServer("Comet", comet.id) end
		-- (#287: 16 sparks FLY from the comet to YOUR star, each on its own arc, a short trail; a sparkle where they land)
		local mine
		for island, sys in pairs(systems) do
			if island:GetAttribute("Owner") == player.UserId then mine = sys end
		end
		if mine and not calm() then
			local from, to = comet.pos, mine.top
			for i = 1, 16 do
				task.delay(i * 0.03, function()
					local p = Instance.new("Part")
					p.Shape = Enum.PartType.Ball
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
					p.Material = Enum.Material.Neon
					p.Color = Color3.fromRGB(190, 240, 255)
					p.Size = Vector3.new(0.45, 0.45, 0.45)
					p.CFrame = CFrame.new(from)
					p.Parent = localFolder
					local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
					a0.Position, a1.Position = Vector3.new(0, 0.2, 0), Vector3.new(0, -0.2, 0)
					a0.Parent, a1.Parent = p, p
					local tr = Instance.new("Trail")
					tr.Attachment0, tr.Attachment1 = a0, a1
					tr.Lifetime = 0.25
					tr.LightEmission = 1
					tr.Texture = VT.alpha.light_streak
					tr.TextureMode = Enum.TextureMode.Stretch
					tr.Color = ColorSequence.new(Color3.fromRGB(170, 235, 255))
					tr.Parent = p
					local mid = (from + to) / 2 + Vector3.new(math.random(-14, 14), math.random(8, 22), math.random(-14, 14))
					local dur = 0.55 + math.random() * 0.3
					local t0 = os.clock()
					local conn
					conn = RunService.RenderStepped:Connect(function()
						local k = math.clamp((os.clock() - t0) / dur, 0, 1)
						local e = k * k
						p.CFrame = CFrame.new((1 - e) ^ 2 * from + 2 * (1 - e) * e * mid + e ^ 2 * to)
						if k >= 1 then
							conn:Disconnect()
							p:Destroy()
							if i % 4 == 0 then sparkleBurst(to, 4, Color3.fromRGB(190, 240, 255), 0.5) end
						end
					end)
				end)
			end
		end
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
				-- (7 Nov, the new UI art: a round check badge (done) / an empty one before each line, not "[X]" / "[ ]")
				local check = row:FindFirstChild("Check")
				if not check then
					check = Instance.new("ImageLabel")
					check.Name = "Check"
					check.BackgroundTransparency = 1
					check.ScaleType = Enum.ScaleType.Fit
					check.AnchorPoint = Vector2.new(1, 0.5)
					check.Size = UDim2.fromScale(1, 1)
					local ar = Instance.new("UIAspectRatioConstraint")
					ar.AspectRatio = 1
					ar.Parent = check
					check.Parent = row
					local pad = Instance.new("UIPadding")
					pad.Name = "CheckPad"
					pad.Parent = row
				end
				local h = row.AbsoluteSize.Y
				local pad = row:FindFirstChild("CheckPad") :: UIPadding
				if pad and h > 0 then pad.PaddingLeft = UDim.new(0, h * 1.25) end
				check.Position = UDim2.new(0, -h * 0.2, 0.5, 0)
				check.Image = if ok then Art.uiIcon.checkDone else Art.uiIcon.checkEmpty
				row.Text = item.text
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
				if step > 0 and p then Vfx.BridgeSegment(p.Position + Vector3.new(0, 1, 0), C.Bridge, math.max(p.Size.X, p.Size.Z) * 1.2) end
				task.wait(0.12)
			end
		end)
	end
	litNow = lit
end
for _, item in ipairs(MapConfig.Ignition) do
	player:GetAttributeChangedSignal(item.attribute):Connect(function() refreshIgnition(true) end)
end
player:GetAttributeChangedSignal("Ignition"):Connect(function() refreshIgnition(true) end)
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
-- (purpose: once YOUR Ignition 1 has opened Sector 2, its padlocks are gone for you: the sector's big one and the Forge's)
local function unlockSector()
	if (player:GetAttribute("Ignition") or 0) < 1 then return end
	for _, d in ipairs(nextS:GetDescendants()) do
		if d.Name == "Padlock" then
			for _, part in ipairs(Kit.Parts(d)) do part.LocalTransparencyModifier = 1 end
		end
	end
end
player:GetAttributeChangedSignal("Ignition"):Connect(unlockSector)
-- (the VFX pass (d): the moment YOUR Ignition 1 lands, the gate's portal swirls up, then rays + a ring + the flash)
local ignitionSeen = player:GetAttribute("Ignition") or 0
player:GetAttributeChangedSignal("Ignition"):Connect(function()
	local now = player:GetAttribute("Ignition") or 0
	if now > ignitionSeen then
		local arch = nextS:FindFirstChild("Arch")
		if arch then
			local cf, size = if arch:IsA("Model") then arch:GetBoundingBox() else arch.CFrame, arch.Size
			Vfx.IgnitionGate(cf.Position - Vector3.new(0, size.Y * 0.1, 0), cf.LookVector, C.Bridge, true)
		end
	end
	ignitionSeen = now
end)
nextS.DescendantAdded:Connect(function(d) if d.Name == "Padlock" or d.Name == "SectorForge" then task.defer(unlockSector) end end)
unlockSector()

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
	if WM.anyOpen() then return end -- (7 Nov: a window is open: world prompts are ignored)
	local at = prompt.Parent
	openWindow:Fire(id, nil, if at and at:IsA("BasePart") then at.Position elseif at and at:IsA("Attachment") then at.WorldPosition else nil)
end)

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

-- THE LEADERBOARD PLAQUES (7 Nov, the new UI art; #396 #403): TOP SUPERNOVAS (the wall, both faces) and PLAYERS NEAR YOU
-- are drawn here on the boards' SurfaceGuis: the galaxy_plaque art as the board (its title on the top banner, the list in its
-- dark screen). Rows 1-3: the gold / silver / bronze row art (9-sliced), the player's headshot in its round slot, the rank
-- emblem (#396), name, Supernovas, and the 1st / 2nd / 3rd medal at the row's end; rows 4+: a plain dark row, same height.
-- An empty board: "Be the first!". The server's lists: the wall's TopList attribute, BoardEvent "Near" (your own list).
-- (7 Nov: the plaque + rows are drawn by PlazaBoardsUI, shared with Tools/BoardPreview)
local PlazaBoardsUI = require(Galaxy:WaitForChild("PlazaBoardsUI"))
local lbPlaque, lbFill = PlazaBoardsUI.plaque, PlazaBoardsUI.fill
-- TOP SUPERNOVAS: both faces of the wall, from its TopList (the server writes it every minute)
task.spawn(function()
	local lb = centre:WaitForChild("Leaderboard", 30)
	local wall = lb and lb:WaitForChild("Wall", 30)
	if not wall then return end
	local function draw()
		local ok, list = pcall(function() return HttpService:JSONDecode(wall:GetAttribute("TopList") or "[]") end)
		local entries = {}
		for i, e in ipairs(ok and list or {}) do entries[i] = { u = e.u, name = e.n, value = e.v, you = e.u == player.UserId } end
		for _, gui in ipairs(wall:GetChildren()) do
			if gui:IsA("SurfaceGui") then
				local l = lbPlaque(gui, "TOP SUPERNOVAS", false)
				if l then lbFill(l, entries, 2, 5) end
			end
		end
	end
	wall:GetAttributeChangedSignal("TopList"):Connect(draw)
	task.wait(1)
	draw()
end)
-- PLAYERS NEAR YOU: your own list from the server (5 above you, you, 5 below); your row outlined gold. The server sends no
-- real ranks for it, so its rows are the plain ones, without numbers or medals.
local boardEvent = Galaxy:WaitForChild("BoardEvent", 30)
local function nearDraw(list)
	local nb = centre:FindFirstChild("NearBoard")
	local board = nb and nb:FindFirstChild("Board")
	for _, gui in ipairs(board and board:GetChildren() or {}) do
		if gui:IsA("SurfaceGui") then
			local l = lbPlaque(gui, "PLAYERS NEAR YOU", true)
			if l then
				local entries = {}
				for i, e in ipairs(list or {}) do entries[i] = { u = e.u, name = e.name, value = e.value, you = e.you, rank = 4, noNum = true } end
				lbFill(l, entries, 1, MapConfig.NearBoard.Rows)
			end
		end
	end
end
if boardEvent then
	boardEvent.OnClientEvent:Connect(function(kind, list)
		if kind ~= "Near" or type(list) ~= "table" then return end
		nearDraw(list)
	end)
end
task.delay(3, function() nearDraw({}) end) -- (until the server's list comes: "Be the first!")

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
		if s.plateFull then
			local isFar = (s.top - camPos).Magnitude > PLATE_FAR
			s.plateFull.Visible = not isFar
			s.plateFar.Visible = isFar
		end
		local near = (s.top - camPos).Magnitude <= MapConfig.LodDistance + s.h or (island:GetAttribute("Owner") == player.UserId)
		if near ~= s.near then
			s.near = near
			for _, ring in ipairs(s.rings) do ring.Parent = if near then s.folder else nil end
			for _, pl in ipairs(s.planets) do pl.piece.Parent = if near then s.folder else nil end
			for _, br in ipairs(s.belt or {}) do br.piece.Parent = if near then s.folder else nil end
			if s.motes then s.motes.Enabled = near end
		end
		if near then
			-- (the Supernova wind-up: k 0 -> 1; the orbits shrink into the star, which swells and pulses faster)
			local k = if s.windup then math.clamp((os.clock() - s.windup.t0) / s.windup.dur, 0, 1) else 0
			local pull = 1 - k * k
			if s.windup then
				local pulse = if calm() then 0 else math.sin(os.clock() * (6 + 26 * k)) * 0.08 * k
				local grow = 1 + (MapConfig.Supernova.Swell - 1) * k + pulse
				for p, size in pairs(s.starSize or {}) do p.Size = size * grow end
			end
			for _, pl in ipairs(s.planets) do
				pl.angle += dt * pl.speed * (1 + 6 * k)
				local cf = CFrame.new(s.top) * pl.tilt * CFrame.new(math.cos(pl.angle) * pl.r * pull, 0, math.sin(pl.angle) * pl.r * pull)
				if pl.pulseAt and os.clock() >= pl.pulseAt then
					local a = (os.clock() - pl.pulseAt) / 0.6
					local g = if a >= 1 or calm() then 1 else 1 + 0.55 * math.sin(math.pi * a)
					for _, p in ipairs(pl.parts) do if pl.sizes[p] then p.Size = pl.sizes[p] * g end end
					if a >= 1 then pl.pulseAt = nil end
				end
				if pl.flyAt then
					local a = math.clamp((os.clock() - pl.flyAt) / 0.7, 0, 1)
					if a >= 1 then
						pl.flyAt = nil
						-- (#285: on arrival a ring flash + sparkles, both bigger for a bigger type)
						local big = 1 + 0.35 * ((pl.k or 1) - 1)
						if pl.trail then pl.trail.Enabled = false end
						ringFlash(cf.Position, 5 * big, pl.colour or Color3.fromRGB(220, 230, 255), 0.45)
						sparkleBurst(cf.Position, math.floor(14 * big), Color3.fromRGB(220, 230, 255), 0.6 * big)
					else
						local e = 1 - (1 - a) ^ 3
						cf = CFrame.new(pl.flyFrom:Lerp(cf.Position, e))
					end
				end
				for _, p in ipairs(pl.parts) do p.CFrame = cf end
			end
			for _, br in ipairs(s.belt or {}) do
				br.angle += dt * 0.12 * (1 + 10 * k)
				local cf = CFrame.new(s.top) * br.tilt * CFrame.new(math.cos(br.angle) * br.r * pull, br.dy * pull, math.sin(br.angle) * br.r * pull) * CFrame.Angles(br.angle, br.angle * 0.7, 0)
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
