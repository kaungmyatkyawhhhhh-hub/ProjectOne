--[[
	WorldFx (client)
	Everything that makes the city feel alive, run locally for smoothness:
	  * traffic-light lamps (synced to server time) + blinking aviation beacons
	  * sweeping searchlight beams over the landmarks
	  * animated billboard gradients and flickering neon signs
	  * the monorail train gliding around the skyline loop
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local LookFx = require(script.Parent:WaitForChild("LookFx"))

local WorldFx = {}

-- 0 at night .. 1 in full day (DayCycle): street lamps (tag "DayOff") switch off by day and their
-- lamp heads (tag "LampGlow") stop glowing
WorldFx.daylight = 0
local lampsLit = true
function WorldFx.setDaylight(d: number)
	WorldFx.daylight = d
	local lit = d < 0.55
	if lit == lampsLit then
		return
	end
	lampsLit = lit
	task.spawn(function()
		for i, p in CollectionService:GetTagged("LampGlow") do
			if p:IsA("BasePart") then
				p.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
			if i % 400 == 0 then
				task.wait()
			end
		end
		for i, p in CollectionService:GetTagged("Window") do
			WorldFx.setWindow(p)
			if i % 600 == 0 then
				task.wait()
			end
		end
		for i, p in CollectionService:GetTagged("FacadeNight") do
			WorldFx.setFacadeNight(p)
			if i % 200 == 0 then
				task.wait()
			end
		end
	end)
end

-- (whole-Yangon mesh buildings, 14 Nov 2026) each 256-stud cell's night layer: a copy of its window walls just in front
-- (MeshPart tag "FacadeNight") with a SurfaceAppearance whose emissive mask lights some windows (tag "FacadeGlow").
-- Shown with the street lamps at night, hidden by day (tools/yangon/YangonBuildingMeshes.luau, glow(3) looked right).
local FACADE_GLOW = 3
function WorldFx.setFacadeNight(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	p.Transparency = if lampsLit then 0 else 1
	for _, sa in p:GetChildren() do
		if sa:IsA("SurfaceAppearance") then
			pcall(function()
				(sa :: any).EmissiveStrength = if lampsLit then FACADE_GLOW else 0
			end)
		end
	end
end
CollectionService:GetInstanceAddedSignal("FacadeNight"):Connect(function(p)
	WorldFx.setFacadeNight(p)
end)

-- (a lamp that streams in or is built by day must not glow: only a change of the light used to set it)
CollectionService:GetInstanceAddedSignal("LampGlow"):Connect(function(p)
	if p:IsA("BasePart") then
		p.Material = if lampsLit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end)

-- the Riviera's windows (tag "Window"): about 4 in 10 glow warm at night, picked by position so
-- every player sees the same ones; streamed-in windows are set as they arrive
-- (2026-11-02, realistic lighting: rooms lit from inside, not neon strips) soft warm interiors,
-- a few cool-white rooms and the odd blue TV glow; how many are lit follows the night (DayCycle
-- sets the share: most at dusk, fewer after midnight)
local WINDOW_DARK = Color3.fromRGB(46, 42, 38)
local SHOP_DAY = Color3.fromRGB(70, 64, 56) -- shop windows by day: a dim room behind the glass
local WINDOW_WARM_A = Color3.fromRGB(150, 110, 70)
local WINDOW_WARM_B = Color3.fromRGB(170, 132, 92)
local WINDOW_WHITE = Color3.fromRGB(150, 146, 134)
local WINDOW_TV = Color3.fromRGB(64, 84, 136)
local windowShare = 0.42
function WorldFx.setWindow(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	local pos = p.Position
	local h = math.abs(math.sin(pos.X * 12.9898 + pos.Y * 78.233 + pos.Z * 37.719) * 43758.5453) % 1
	local size = p.Size
	local shop = size.X * size.Y > 60 or size.Z * size.Y > 60
	-- shops stay lit later than homes; the far stand-in's panes stand for two windows each and only
	-- exist where a window can be lit, so more of them are
	local share = if shop then math.max(windowShare, 0.7) elseif p:HasTag("FarWindow") then math.min(0.95, windowShare * 2) else windowShare
	local on = lampsLit and h < share
	p.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if not on then
		p.Color = if not lampsLit and shop then SHOP_DAY else WINDOW_DARK
		return
	end
	local kind = (h * 97.31) % 1
	local long = math.max(size.X, size.Z) > 14 -- a whole balcony band of glass: dimmer, never one bright bar
	local big = shop -- shopfronts: always warm
	local c = if kind < 0.04 and not big and not long then WINDOW_TV elseif kind < 0.2 and not big then WINDOW_WHITE else WINDOW_WARM_A:Lerp(WINDOW_WARM_B, kind)
	p.Color = if long then c:Lerp(Color3.new(0, 0, 0), 0.3) elseif p:HasTag("FarWindow") then c:Lerp(Color3.fromRGB(255, 196, 120), 0.4) else c
end
-- the share of windows lit (0..1); re-sets them all, spread over frames, when it moves
local windowJob = 0
function WorldFx.setWindowShare(share: number)
	if math.abs(share - windowShare) < 0.02 then
		return
	end
	windowShare = share
	windowJob += 1
	local job = windowJob
	task.spawn(function()
		for i, p in CollectionService:GetTagged("Window") do
			if job ~= windowJob then
				return
			end
			WorldFx.setWindow(p)
			if i % 600 == 0 then
				task.wait()
			end
		end
	end)
end
CollectionService:GetInstanceAddedSignal("Window"):Connect(function(p)
	WorldFx.setWindow(p)
end)

---------------------------------------------------------------------
-- Quality: scales LOD distances + traffic density from the player's
-- Roblox graphics setting (and a little lower on phones/tablets)
---------------------------------------------------------------------
-- the main menu's Graphics setting (2026-11-02): Low / Medium / High / Ultra over Roblox's own
local qualityPick: number? = nil
local QUALITY = { Low = 0.6, Medium = 0.8, High = 1, Ultra = 1.15 }
-- (2026-11-14) the scale the light sweep uses; startLod sets it, a Graphics change in the menu updates it
local lightScale: number? = nil
function WorldFx.setQuality(name: string)
	qualityPick = QUALITY[name]
	if lightScale then
		lightScale = WorldFx.qualityScale()
	end
	-- the costly screen effects: depth of field off on Medium (the wind blur; a player's own is LookDof)
	local Lighting = game:GetService("Lighting")
	for _, e in Lighting:GetChildren() do
		if e:IsA("DepthOfFieldEffect") and e.Name ~= "LookDof" then
			e.Enabled = name == "High" or name == "Ultra"
		end
	end
	-- (overnight, 2026-11-06: shadows are the dearest thing left on a phone: off on Low) the level
	-- sets shadows, glow, sun rays, reflections and fog
	LookFx.preset(name)
	pcall(function()
		workspace.Terrain.Decoration = name == "High" or name == "Ultra"
	end)
end

-- a player with no saved choice: phones start on Medium, the rest on High
function WorldFx.defaultQuality(): string
	local UIS = game:GetService("UserInputService")
	return if UIS.TouchEnabled and not UIS.KeyboardEnabled then "Medium" else "High"
end

function WorldFx.qualityScale(): number
	if qualityPick then
		local touch = game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled
		return qualityPick * (if touch then 0.85 else 1)
	end
	local scale = 1
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if ok and level and level ~= Enum.SavedQualitySetting.Automatic then
		local n = tonumber(string.match(level.Name, "%d+")) or 10
		scale = 0.55 + 0.05 * n -- level 1 -> 0.6, level 10 -> 1.05
	end
	local UserInputService = game:GetService("UserInputService")
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		scale *= 0.8
	end
	return scale
end

---------------------------------------------------------------------
-- LOD: groups of small details (tag "LOD") are removed from the scene when
-- the camera is far away, and lights (tag "LODLight") are switched off.
-- Work is spread over frames so it never causes a hitch.
---------------------------------------------------------------------
-- (2026-11-02, owner: "on the summit make it so that u can see the city lights") groups with the
-- attribute Far are the far stand-ins (ReplicatedStorage.RivieraFar, see tools/riviera/FarCity.luau):
-- the other way round, shown only PAST their range, or while the real building they stand for
-- (ObjectValue "Real") is streamed out; NoScale keeps the range whatever the graphics level
type LodEntry = { inst: Instance, parent: Instance?, center: Vector3, range: number, shown: boolean, far: boolean, real: ObjectValue? }

local function startLod(scale: number)
	lightScale = scale
	local entries: { LodEntry } = {}
	local known: { [Instance]: boolean } = {}
	local function register(inst: Instance)
		if known[inst] then
			return
		end
		local center = inst:GetAttribute("Center")
		local range = inst:GetAttribute("Range")
		if typeof(center) ~= "Vector3" or type(range) ~= "number" then
			return
		end
		known[inst] = true
		local real = inst:FindFirstChild("Real")
		table.insert(entries, {
			inst = inst,
			parent = inst.Parent,
			center = center,
			range = if inst:GetAttribute("NoScale") then range else range * scale,
			shown = true,
			far = inst:GetAttribute("Far") == true,
			real = if real and real:IsA("ObjectValue") then real else nil,
		})
	end
	for _, inst in CollectionService:GetTagged("LOD") do
		register(inst)
	end
	CollectionService:GetInstanceAddedSignal("LOD"):Connect(register)

	local lights: { Light } = {}
	local knownLight: { [Instance]: boolean } = {}
	local function addLight(l: Instance)
		if l:IsA("Light") and not knownLight[l] then
			knownLight[l] = true
			table.insert(lights, l)
		end
	end
	for _, l in CollectionService:GetTagged("LODLight") do
		addLight(l)
	end
	-- (lights made later: house galleries, showcase cars, anything streamed in)
	CollectionService:GetInstanceAddedSignal("LODLight"):Connect(addLight)

	-- (2026-11-14, phones: on Yangon every venue stands near the start, so their ~150 always-on interior lights
	-- (showroom, palace, shops, the fuel and repair forecourts), 47 of them with shadows, were all on at once)
	-- the venues' own lights not already managed switch off past VENUE_LIGHT_RANGE and cast shadows only within
	-- VENUE_SHADOW_RANGE (none on phones or low graphics); a light that must stay as built sets attribute NoLod
	local VENUE_LIGHT_RANGE = 160
	local VENUE_SHADOW_RANGE = 80
	local function carLight(l: Instance): boolean
		-- (display / showcase cars keep their own lights: CarSkin switches a model's TailGlow off for good)
		local a = l.Parent
		while a and a ~= workspace do
			if a:HasTag("TowerShowcase") or a:FindFirstChild("Chassis") then
				return true
			end
			a = a.Parent
		end
		return false
	end
	local function venueLight(l: Instance)
		if not l:IsA("Light") or l:GetAttribute("NoLod") or l:GetAttribute("LodRange") then
			return
		end
		if l.Name == "TailGlow" or carLight(l) then
			return
		end
		-- (exterior floods and lamps, DayOff: they keep the 300 of the street lamps, seen from the road at night)
		if not l:HasTag("DayOff") then
			l:SetAttribute("LodRange", VENUE_LIGHT_RANGE)
		end
		if (l :: Light).Shadows or l:HasTag("ShadowLight") then
			l:SetAttribute("ShadowRange", VENUE_SHADOW_RANGE)
			l:AddTag("ShadowLight")
		end
		if not l:HasTag("LODLight") then
			l:AddTag("LODLight")
		end
	end
	local function watchVenues(root: Instance?)
		if not root then
			return
		end
		root.DescendantAdded:Connect(venueLight)
		task.spawn(function()
			for i, d in root:GetDescendants() do
				venueLight(d)
				if i % 2000 == 0 then
					task.wait()
				end
			end
		end)
	end
	task.spawn(function()
		watchVenues(workspace:WaitForChild("City", 30))
		local y = workspace:FindFirstChild("Yangon")
		watchVenues(y and y:WaitForChild("CarCare", 30))
	end)
	-- the light ranges (worked out each sweep from lightScale, which follows the menu's Graphics choice):
	-- 560 wide enough that lights never visibly pop on/off block by block (past that a lamp's own glowing
	-- head still shows, but its light on the street is too far to see; 900 kept ~360 lights on at once,
	-- owner 2026-10-24: optimise), 300 for the Riviera's and Yangon's dense lamps, and street lamps near
	-- the camera (170) cast shadows, none on low graphics or phones
	local camera = workspace.CurrentCamera

	local cursor, lightCursor = 1, 1
	RunService.Heartbeat:Connect(function()
		local camPos = camera.CFrame.Position
		-- ~1/16 of the groups per frame -> a full sweep about four times a second (owner, 2026-11-04: "optimize,
		-- a little glitchy"; driving hitched when many groups came in on one frame, up to 113 ms): at most
		-- 3 groups go in or out per frame, the rest on the next ones
		local budget = math.max(60, math.ceil(#entries / 16))
		local flips = 0
		for _ = 1, math.min(budget, #entries) do
			if cursor > #entries then
				cursor = 1
			end
			local e = entries[cursor]
			cursor += 1
			local want = (e.center - camPos).Magnitude < e.range
			if e.far then
				if want then
					local real = e.real and e.real.Value
					want = real ~= nil and real:FindFirstChild("Body") == nil
				else
					want = true -- (past its range: no need to look the real building up)
				end
			end
			if want ~= e.shown then
				e.shown = want
				e.inst.Parent = if want then e.parent else nil
				flips += 1
				if flips >= 3 then
					break
				end
			end
		end
		local s = lightScale or scale
		local lightRangeNow = 560 * s
		local rivieraLightRangeNow = 300 * s
		local shadowRangeNow = if s >= 0.85 then 170 else 0
		local lbudget = math.max(40, math.ceil(#lights / 20))
		for _ = 1, math.min(lbudget, #lights) do
			if #lights == 0 then
				break
			end
			if lightCursor > #lights then
				lightCursor = 1
			end
			local l = lights[lightCursor]
			-- (a light streamed out or destroyed: off the list, or the list grows all session; a light that
			-- streams back in is a new instance and is added again)
			if not l:IsDescendantOf(workspace) then
				knownLight[l] = nil
				lights[lightCursor] = lights[#lights]
				lights[#lights] = nil
				continue
			end
			lightCursor += 1
			local part = l.Parent
			if part and part:IsA("BasePart") and not l:GetAttribute("NoLod") then
				local dist = (part.Position - camPos).Magnitude
				-- the Riviera's dense lamps: only those near the camera light the street (phones)
				local own = l:GetAttribute("LodRange")
				local range = if type(own) == "number" then own * s elseif part.Position.X > 9000 then rivieraLightRangeNow else lightRangeNow
				local on = dist < range and (lampsLit or not l:HasTag("DayOff"))
				if l.Enabled ~= on then
					l.Enabled = on
				end
				-- (no shadows at all on phones and low graphics: shadowRange 0)
				if l:HasTag("ShadowLight") then
					local ownShade = l:GetAttribute("ShadowRange")
					local shade = shadowRangeNow > 0 and dist < (if type(ownShade) == "number" then ownShade else shadowRangeNow)
					if l.Shadows ~= shade then
						l.Shadows = shade
					end
				end
			end
		end
	end)
end

local LAMP_ON = {
	R = Color3.fromRGB(255, 35, 35),
	Y = Color3.fromRGB(255, 176, 0),
	G = Color3.fromRGB(40, 255, 120),
}
-- unlit lenses: dark, but still tinted their colour like real glass
local LAMP_OFF = {
	R = Color3.fromRGB(52, 8, 8),
	Y = Color3.fromRGB(56, 38, 4),
	G = Color3.fromRGB(6, 40, 22),
}

---------------------------------------------------------------------
-- Monorail train
---------------------------------------------------------------------
type TrainPart = { part: BasePart, offset: CFrame }
type TrainCar = { parts: { TrainPart }, back: number }

local function buildTrain(folder: Instance): { TrainCar }
	local M = Config.Monorail
	local cars: { TrainCar } = {}
	local function add(list: { TrainPart }, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, transparency: number?, shape: Enum.PartType?): BasePart
		local p = Instance.new("Part")
		if shape then
			p.Shape = shape
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Size = size
		p.Color = color
		p.Material = material
		p.Transparency = transparency or 0
		p.Reflectance = if material == Enum.Material.SmoothPlastic then 0.2 else 0
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CastShadow = false
		p.Parent = folder
		table.insert(list, { part = p, offset = offset })
		return p
	end
	local L = M.CarLength
	for k = 1, M.Cars do
		local list: { TrainPart } = {}
		-- body sits on top of the guideway; model origin = guideway centre line
		add(list, Vector3.new(4.6, 5, L - 1), CFrame.new(0, 4.3, 0), Color3.fromRGB(225, 228, 235), Enum.Material.SmoothPlastic)
		add(list, Vector3.new(4.7, 1.7, L - 4), CFrame.new(0, 4.9, 0), Color3.fromRGB(255, 226, 180), Enum.Material.Neon, 0.25)
		add(list, Vector3.new(4.75, 0.25, L - 2), CFrame.new(0, 3.2, 0), Config.Theme.Accent, Enum.Material.Neon)
		add(list, Vector3.new(4.2, 0.6, L - 2), CFrame.new(0, 7.05, 0), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
		-- straddle skirt wrapping the beam
		add(list, Vector3.new(5.2, 2.2, L - 3), CFrame.new(0, 1.0, 0), Color3.fromRGB(30, 32, 36), Enum.Material.Metal)
		local inside = add(list, Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 4.5, 0), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1)
		if k == 2 then
			-- low electric rumble you hear as the train passes overhead
			local hum = Instance.new("Sound")
			hum.SoundId = "rbxasset://sounds/action_falling.ogg"
			hum.Looped = true
			hum.Volume = 0.6
			hum.PlaybackSpeed = 0.5
			hum.RollOffMode = Enum.RollOffMode.InverseTapered
			hum.RollOffMinDistance = 20
			hum.RollOffMaxDistance = 260
			local eq = Instance.new("EqualizerSoundEffect")
			eq.LowGain = 6
			eq.MidGain = -4
			eq.HighGain = -24
			eq.Parent = hum
			hum.Parent = inside
			hum:Play()
		end
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 220, 180)
		glow.Range = 16
		glow.Brightness = 1.2
		glow.Shadows = false
		glow.Parent = inside
		if k == 1 then
			-- aerodynamic nose + headlights
			add(list, Vector3.new(4.3, 4.2, 3), CFrame.new(0, 4, -L / 2 - 1), Color3.fromRGB(225, 228, 235), Enum.Material.SmoothPlastic)
			add(list, Vector3.new(4, 1.4, 0.2), CFrame.new(0, 5.2, -L / 2 - 2.55), Color3.fromRGB(20, 26, 36), Enum.Material.Glass, 0.2)
			local head = add(list, Vector3.new(3.4, 0.6, 0.3), CFrame.new(0, 3.6, -L / 2 - 3), Color3.fromRGB(235, 245, 255), Enum.Material.Neon)
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Front
			spot.Range = 60
			spot.Angle = 50
			spot.Brightness = 3
			spot.Shadows = false
			spot.Parent = head
		elseif k == M.Cars then
			add(list, Vector3.new(3.4, 0.6, 0.3), CFrame.new(0, 3.6, L / 2 + 0.2), Color3.fromRGB(255, 20, 20), Enum.Material.Neon)
		end
		table.insert(cars, { parts = list, back = (k - 1) * (L + 1.2) })
	end
	return cars
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
-- Shadows only from things whose shadow you'd see (owner, 2026-10-24: "optimize the game to not
-- make it lag but still have the beautiful quality"). The shadow pass drew more than the scene
-- itself (~2,100 draw calls): flat pieces (roads, sidewalks, markings, slabs: their shadow is a thin
-- line under them), tiny decoration and the far skyline stop casting; walls, buildings, poles,
-- trees and cars keep theirs. Done here on this screen only, spread over frames.
local function trimShadows()
	local city = workspace:FindFirstChild("City")
	if not city then
		return
	end
	local far = { Skyline = true, DistantSkyline = true }
	local n = 0
	for _, top in city:GetChildren() do
		local farAway = far[top.Name] == true
		for _, d in top:GetDescendants() do
			if d:IsA("BasePart") and d.CastShadow then
				local cf, h = d.CFrame, d.Size / 2
				-- its height in the world, whatever way it's turned
				local ey = math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z
				local big = math.max(d.Size.X, d.Size.Y, d.Size.Z)
				if farAway or ey < 0.35 or big < 1.2 then
					d.CastShadow = false
				end
				n += 1
				if n % 4000 == 0 then
					task.wait()
				end
			end
		end
	end
end

function WorldFx.start()
	-- the Riviera's far stand-in lives in ReplicatedStorage (always on every client, never in the way
	-- in Studio's editor); here it moves into this player's world
	if workspace:FindFirstChild("Riviera") then
		task.spawn(function()
			-- (the loading screen may have moved it in already)
			local far = workspace:FindFirstChild("RivieraFar") or ReplicatedStorage:WaitForChild("RivieraFar", 60)
			if far then
				far.Parent = workspace
			end
		end)
	end
	-- the far city's night billboards (tag FarLight): on at night, past 450 studs, and only up on the
	-- hills (camera above 110), so phones on low graphics (which stop drawing parts far away) still
	-- see the city lights from the hills. They cost ~2.5 ms a frame, so not on high graphics (the
	-- real far city shows there) and not down in the streets (where buildings hide them anyway).
	local highGraphics = false
	pcall(function()
		local level = UserSettings():GetService("UserGameSettings").SavedQualityLevel
		highGraphics = level ~= Enum.SavedQualitySetting.Automatic and (tonumber(string.match(level.Name, "%d+")) or 0) >= 8
	end)
	task.spawn(function()
		local camera = workspace.CurrentCamera
		while true do
			task.wait(0.5)
			local camPos = camera.CFrame.Position
			local look = camera.CFrame.LookVector
			local cosHalf = math.cos(math.rad(math.min(89, camera.FieldOfView * 0.5 * camera.ViewportSize.X / math.max(1, camera.ViewportSize.Y) + 8)))
			-- (Studio preview: workspace attribute PreviewFarLights acts like a phone on low graphics)
			local up = camPos.Y > 110 and (not highGraphics or (RunService:IsStudio() and workspace:GetAttribute("PreviewFarLights") == true))
			for i, bb in CollectionService:GetTagged("FarLight") do
				local a = bb.Parent
				if bb:IsA("BillboardGui") and a and a:IsA("BasePart") and a:IsDescendantOf(workspace) then
					local rel = a.Position - camPos
					local dist = rel.Magnitude
					-- (only the ones in front of the camera: each costs a little every frame)
					local on = up and lampsLit and dist > 450 and rel:Dot(look) > dist * cosHalf
					if bb.Enabled ~= on then
						bb.Enabled = on
					end
				end
				if i % 400 == 0 then
					task.wait()
				end
			end
		end
	end)
	local lampCache: { [Instance]: boolean } = {}
	task.spawn(trimShadows)
	startLod(WorldFx.qualityScale())

	-- lamps + beacons (5 Hz is plenty)
	task.spawn(function()
		local blinkOn = true
		local blinkTimer = 0
		while true do
			local now = workspace:GetServerTimeNow()
			for _, lamp in CollectionService:GetTagged("TrafficLamp") do
				if lamp:IsA("BasePart") then
					local i = lamp:GetAttribute("I") :: number
					local j = lamp:GetAttribute("J") :: number
					local axis = lamp:GetAttribute("Axis") :: string
					local mine = lamp:GetAttribute("State") :: string
					local on = CityLayout.lightState(i, j, axis, now) == mine
					if lampCache[lamp] ~= on then
						lampCache[lamp] = on
						lamp.Color = if on then LAMP_ON[mine] else LAMP_OFF[mine] or LAMP_OFF.R
						lamp.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
					end
				end
			end
			-- each signal head's glow takes the colour of its lit lens
			for _, glow in CollectionService:GetTagged("SignalGlow") do
				if glow:IsA("PointLight") then
					local st = CityLayout.lightState(glow:GetAttribute("I") :: number, glow:GetAttribute("J") :: number, glow:GetAttribute("Axis") :: string, now)
					local c = LAMP_ON[st]
					if glow.Color ~= c then
						glow.Color = c
					end
				end
			end
			blinkTimer += 1
			if blinkTimer >= 4 then
				blinkTimer = 0
				blinkOn = not blinkOn
				for _, b in CollectionService:GetTagged("Blink") do
					if b:IsA("BasePart") then
						b.Transparency = if blinkOn then 0 else 0.9
					end
				end
			end
			-- random neon flicker
			for _, f in CollectionService:GetTagged("Flicker") do
				if f:IsA("BasePart") then
					f.Transparency = if math.random() < 0.18 then 0.85 else 0
				end
			end
			task.wait(0.2)
		end
	end)

	-- monorail
	local train: { TrainCar } = {}
	-- (2026-11-03, optimising) the monorail runs round the old city's skyline: not in Monaco only
	if Config.Graphics.Monorail and not Config.monacoOnly() then
		local folder = Instance.new("Folder")
		folder.Name = "MonorailTrain"
		folder.Parent = workspace
		train = buildTrain(folder)
	end
	local trainParts: { BasePart } = {}
	local trainCFrames: { CFrame } = {}
	local loopLen = CityLayout.monorailLength()

	local function tracked(tag: string): { Instance }
		local list = CollectionService:GetTagged(tag)
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			table.insert(list, inst)
		end)
		return list
	end
	local searchTargets = tracked("SearchTarget")
	local boards = tracked("AnimatedBoard")

	local boardTimer = 0
	RunService.Heartbeat:Connect(function(dt)
		local now = workspace:GetServerTimeNow()

		-- searchlights sweep in slow figure-eights
		for _, target in searchTargets do
			if target:IsA("BasePart") then
				local base = target:GetAttribute("Base") :: Vector3?
				local phase = (target:GetAttribute("Phase") :: number?) or 0
				if base then
					local t = now * 0.22 + phase
					local offset = Vector3.new(math.sin(t) * 520, 1050, math.cos(t * 0.73) * 520)
					target.CFrame = CFrame.new(base + offset)
				end
			end
		end

		-- billboards (10 Hz)
		boardTimer += dt
		if boardTimer > 0.1 then
			boardTimer = 0
			for _, g in boards do
				if g:IsA("UIGradient") then
					g.Rotation = (g.Rotation + 4) % 360
					g.Offset = Vector2.new(math.sin(now * 0.8 + g.Rotation * 0.01) * 0.25, 0)
				end
			end
		end

		-- monorail (synced to server time so every player sees it in the same place)
		if #train > 0 then
			table.clear(trainParts)
			table.clear(trainCFrames)
			local head = (now * Config.Monorail.Speed) % loopLen
			for _, car in train do
				local s = head - car.back
				local front = CityLayout.monorailSample(s + Config.Monorail.CarLength / 2)
				local rear = CityLayout.monorailSample(s - Config.Monorail.CarLength / 2)
				local center = (front + rear) / 2
				local cf = CFrame.lookAt(center, center + (front - rear))
				for _, tp in car.parts do
					table.insert(trainParts, tp.part)
					table.insert(trainCFrames, cf * tp.offset)
				end
			end
			workspace:BulkMoveTo(trainParts, trainCFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return WorldFx
