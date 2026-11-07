-- GalaxyMapService (Galaxy Incremental, 2 Nov): the PERSONAL ISLANDS.
--  * Join: you claim the first free island (of 8); leave: it's freed (your save keeps your progress, not the island).
--  * You spawn ON your island, facing the Core (and come back there if you fall into the void).
--  * Your island GROWS with the PADS you buy (feel pass, 5 Nov: EconConfig.Pads, the owner's attribute Pads): each pad builds
--    its pieces (PAD_BUILD; the client pops them in with a sparkle) and the next pad appears, lit, on the floor. A bare rock
--    until pad 1. Its bridge to the centre is lit while it's owned.
--  * The island carries what the clients draw over it: Owner, OwnerName, Color, Tier, BodyTiers, Supernovas, Rank, Ready
--    (Rank = MapConfig.RankOf: NEW STAR, RISING STAR, SUPERNOVA n).
--  * A Supernova (your Supernovas count going up) = the shared moment: every client sees the Core burst and the shockwave.
--  * Comets: GalaxyEconService sends them and pays them (MapEvent "CometSpawn" / "Comet").
--  * Belt: one small rock per body owned (max 20) in the island's star system, so it grows with every buy.
--  * Every owned island has its four live BOARDS, like Regrowth's plot (MapConfig.Boards): CONSTELLATION TREE + INFO on the
--    far edge, BODIES on the left, STAR UPGRADES on the right; GalaxyBoards draws their screens.
-- Every size and place comes from MapConfig.Islands (redone to scale against the R15 character, 2 Nov night).
-- Reads the PLAYER's attributes (set by the economy): Bodies, BodyTiers, Supernovas, SupernovaReady.
-- Studio test switches (Workspace attributes, Studio only): TestIslands = true (the empty islands get fake owners at every
-- tier), TestBodies / TestBodyTiers / TestSupernovas (numbers, set on every real player), TestIgnition (0..4 checklist done).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy.MapConfig)
local Kit = require(Galaxy.Kit)
local Builder = require(ServerStorage:WaitForChild("GalaxyMapBuilder"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))

local C = MapConfig.Colors
local O = MapConfig.Origin

-- the map (built in Studio; rebuilt here when it still has stand-ins and the owner's kit has been imported since)
local root = workspace:FindFirstChild("Galaxy")
if not root or (root:GetAttribute("StandIns") == true and Kit.AllImported()) then
	root = Builder.Build()
end
local islandsFolder = root:WaitForChild("Islands")
if root:FindFirstChild("Centre") then Builder.FreeBoard(root.Centre) end -- (Phase 2.4: a place built before the board)
Builder.ClearDecor(root) -- (no crystal in front of a sign, 6 Nov)
-- (7 Nov, rule 8 ONE FRAME) a place built before it: the leaderboard wall + PLAYERS NEAR YOU lose their brass edge and the
-- screen part goes see-through (the plaque art is the frame; MapBuilder builds them this way now)
do
	local centre = root:FindFirstChild("Centre")
	for _, t in ipairs({ { "Leaderboard", "Wall", "WallEdge" }, { "NearBoard", "Board", "BoardEdge" } }) do
		local m = centre and centre:FindFirstChild(t[1])
		if m then
			local edge = m:FindFirstChild(t[3])
			if edge then edge:Destroy() end
			local scr = m:FindFirstChild(t[2])
			if scr then scr.Transparency = 1 end
		end
	end
end
-- (7 Nov) what MapAudit checks (ServerStorage.Tools.MapAudit): the plaza's pieces line the plaza facing in, at the Core
do
	local CORE = "Galaxy.Centre.Core"
	local function tag(inst: Instance?, attrs)
		if not inst then return end
		inst:SetAttribute("Placeable", true)
		for k, v in pairs(attrs or {}) do inst:SetAttribute(k, v) end
	end
	local centre = root:FindFirstChild("Centre")
	if centre then
		for _, n in ipairs({ "Leaderboard", "NearBoard", "StarForge", "BlackHoleGate", "StarSurge", "FreeBoard" }) do tag(centre:FindFirstChild(n), { FaceTarget = CORE }) end
		tag(centre:FindFirstChild("Core"), { Animated = true }) -- (the landmark: it hovers, tilts and spins on purpose)
		-- (the posts stand on the plaza's raised rim ring; the ground ray from their middle misses the ring and lands on the
		-- floor's bevelled edge 0.8-1.5 below: Floating, with that reason)
		for _, c in ipairs(centre:GetChildren()) do if c.Name == "LampPost" then tag(c, { Floating = true }) end end
		-- (MapAudit: the plaza's raised rim ring is floor: the lamps, the Black Hole gate and the boards' feet stand on it)
		local plazaRim = centre:FindFirstChild("Rim")
		if plazaRim then plazaRim:SetAttribute("Ground", true) end
		local det = centre:FindFirstChild("Details")
		if det then
			for _, c in ipairs(det:GetChildren()) do
				if c.Name == "CrystalCluster" and c:IsA("BasePart") then
					-- (the audit: they were turned 40 / 50 / 130 deg and sat 0.3-0.4 above the floor: snapped to 15 deg, set down)
					local _, ry, _ = c.CFrame:ToOrientation()
					local snap = math.rad(math.floor(math.deg(ry) / 15 + 0.5) * 15)
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.FilterDescendantsInstances = { c }
					local hit = workspace:Raycast(c.Position + Vector3.new(0, c.Size.Y, 0), Vector3.new(0, -60, 0), rp)
					local y = if hit then hit.Position.Y + c.Size.Y / 2 - 0.1 else c.Position.Y
					c.CFrame = CFrame.new(c.Position.X, y, c.Position.Z) * CFrame.Angles(0, snap, 0)
					tag(c)
				end
			end
		end
	end
	local ns = root:FindFirstChild("NextSector")
	if ns then
		-- (a gateway: its legs stand on the floor either side of the path; the audit's ground ray goes down its middle onto the
		-- path's ramp: Floating, with that reason)
		tag(ns:FindFirstChild("Arch"), { FaceTarget = CORE, Floating = true })
		tag(ns:FindFirstChild("IgnitionSign"), { FaceTarget = CORE, Floating = true }) -- (it hangs on its two posts)
		tag(ns:FindFirstChild("ArchSign"), { FaceTarget = CORE, Floating = true }) -- (on its post, over the arch)
		-- (the Barrier is the arch's door, not floor; the sector-2 Forge sign faces its own island)
		local bar = ns:FindFirstChild("Barrier")
		if bar then bar:SetAttribute("NotGround", true) end
		-- (a sign's brass edge is its own frame: part of that sign, for the audit)
		for _, n in ipairs({ "ArchSign", "IgnitionSign" }) do
			local e = ns:FindFirstChild(n .. "Edge")
			if e then e:SetAttribute("PartOf", n) end
		end
		-- (the Sector 2 Forge copy is made below, tagged by being a copy of the plaza's)
	end
end
-- (6 Nov: the place's Forge sign was built when the Forge opened at Supernova 3; the builder says IGNITION 1 now)
do
	local forgeSign = root:FindFirstChild("Centre") and root.Centre:FindFirstChild("StarForge") and root.Centre.StarForge:FindFirstChild("Sign")
	for _, l in ipairs(forgeSign and forgeSign:GetDescendants() or {}) do
		if l:IsA("TextLabel") and l.Text == "SUPERNOVA 3" then l.Text = "IGNITION 1" end
	end
	-- (3.1: the Black Hole opens at 100K shards now: its sign said LOCKED)
	local holeSign = root:FindFirstChild("Centre") and root.Centre:FindFirstChild("BlackHoleGate") and root.Centre.BlackHoleGate:FindFirstChild("Sign")
	for _, l in ipairs(holeSign and holeSign:GetDescendants() or {}) do
		if l:IsA("TextLabel") and l.Text == "LOCKED" then l.Text = "100K SHARDS" end
	end
end

local remote = Galaxy:FindFirstChild("MapEvent") or Instance.new("RemoteEvent")
remote.Name = "MapEvent"
remote.Parent = Galaxy

local owners = {} -- [slot] = Player or a fake owner table (Studio test)
local slotOf = {} -- [Player] = slot

local function islandOf(slot: number): Model
	return islandsFolder:FindFirstChild("Island_" .. slot) :: Model
end
local function centerOf(island: Model): (Vector3, Vector3, number)
	local c = island:GetAttribute("Center") :: Vector3
	local a = island:GetAttribute("Angle") :: number
	return c, Vector3.new(math.cos(a), 0, math.sin(a)), a
end

------------------------------------------------------------------------
-- the island's pieces, tier by tier (every size + place from MapConfig.Islands; kit meshes scaled uniformly)
------------------------------------------------------------------------
local I = MapConfig.Islands
local R = I.Radius
local UP = Vector3.new(0, 1, 0)
local function brass(props)
	props.Color = C.Brass
	props.Material = MapConfig.BrassMaterial
	props.Reflectance = MapConfig.BrassReflectance
	return props
end
-- island-local place (x = out from the Core, z = to the side)
local function at(island: Model, x: number, z: number, y: number?): Vector3
	local c, dir = centerOf(island)
	return Builder.IslandPoint(c, dir, Vector3.new(x, y or 0, z))
end
local function angled(island: Model, deg: number, r: number): Vector3
	local a = math.rad(deg)
	return at(island, math.cos(a) * r, math.sin(a) * r)
end

-- the island's four BOARDS (owner, 2 Nov: "1:1 direct copy boards from regrowth"): Regrowth's chunky stone frames round a
-- dark screen (GalaxyBoards draws the live UI on it). No prompt, no ClickDetector: the buttons are on the screens.
-- (7 Nov, the map placement rules) every island has an AREA (its walkable disc: BoardPlacer's centre + radius) with an
-- ISLANDSPAWN in it (where you step off the bridge: the boards face it). Made by code, invisible, not collidable.
local BoardPlacer = require(ServerStorage:WaitForChild("Tools"):WaitForChild("BoardPlacer"))
local function islandArea(island: Model): BasePart
	local name = island.Name .. "_Area"
	local area = island:FindFirstChild(name)
	if area then return area end
	local c = centerOf(island)
	area = Builder.part({ Name = name, Size = Vector3.new(2 * R, 1, 2 * R), CFrame = CFrame.new(c - UP * 0.5), Transparency = 1,
		CanCollide = false, CanQuery = false, Parent = island })
	Builder.part({ Name = "IslandSpawn", Size = Vector3.new(4, 1, 4), CFrame = CFrame.new(at(island, -(R - 6), 0, 0.5)), Transparency = 1,
		CanCollide = false, CanQuery = false, Parent = area })
	return area
end
-- the boards: built where the old geometry put them (so each frame is whole), given a bottom-centre pivot that looks at the
-- player (front = LookVector), then PLACED BY BoardPlacer from MapConfig.Boards.Layout. (The pair's old gap ledge is gone:
-- the pair now stands 30 deg apart round the rim.)
local function makeBoards(island: Model)
	local old = island:FindFirstChild("Boards")
	if old then return old end
	local c, dir = centerOf(island)
	local area = islandArea(island)
	local cfs = Builder.BoardCFrames(c, dir)
	local L = MapConfig.Boards.Layout
	local model = Instance.new("Model")
	model.Name = "Boards"
	model.Parent = island
	local placed = {}
	for _, spec in ipairs(MapConfig.Boards.List) do
		local panel = Instance.new("Model")
		panel.Name = "Board_" .. spec.id
		panel:SetAttribute("Board", spec.id)
		Builder.BoardFrame(panel, cfs[spec.id], spec, c.Y, island:GetAttribute("OwnerName"))
		local screen = panel.Screen
		screen:SetAttribute("Board", spec.id)
		-- (the screen's visible side is its Back face: -LookVector)
		local front = -screen.CFrame.LookVector
		front = Vector3.new(front.X, 0, front.Z).Unit
		local bottom = Vector3.new(screen.Position.X, c.Y, screen.Position.Z)
		panel.WorldPivot = CFrame.lookAt(bottom, bottom + front)
		panel.Parent = model
		local row = L[spec.id]
		if row then
			-- the rim angle in WORLD degrees (BoardPlacer: 0 = +X): the island's far side turned by the row's angle
			local a = math.rad(row.angle)
			local w = at(island, math.cos(a), math.sin(a)) - at(island, 0, 0)
			local worldDeg = math.deg(math.atan2(w.Z, w.X))
			BoardPlacer.place(panel, area, worldDeg, { margin = L.Margin, tiltBack = 0, groundY = c.Y })
			placed[spec.id] = { panel = panel, row = row, deg = worldDeg }
		end
		panel:SetAttribute("Placeable", true)
	end
	-- the pair turns `spread` deg toward each other (the side is worked out from where the other board stands)
	for _, pair in ipairs({ { "Tree", "Info" }, { "Info", "Tree" } }) do
		local me, other = placed[pair[1]], placed[pair[2]]
		if me and other and (me.row.spread or 0) ~= 0 then
			local look = me.panel:GetPivot().LookVector
			local to = other.panel:GetPivot().Position - me.panel:GetPivot().Position
			local side = if look:Cross(to).Y >= 0 then 1 else -1
			BoardPlacer.place(me.panel, area, me.deg, { margin = L.Margin, tiltBack = 0, groundY = c.Y, pairSpread = side * me.row.spread })
		end
	end
	return model
end

-- what each PAD builds (EconConfig.Pads order). 1-10 = the island's pieces that used to come by themselves; 11-20 new
local PAD_BUILD = {}
PAD_BUILD[1] = function(island, folder) -- STONE ISLAND: the disc, the rock cone, the crystals hanging under it
	local c, _, a = centerOf(island)
	local slot = island:GetAttribute("Slot") or 1
	local floorH = Kit.Fit("IslandTop", "X", I.Floor.Fit).Y
	local under = Kit.Fit("IslandUnder", "X", I.Under.Fit)
	Kit.Make("IslandTop", { Name = "Disc", Fit = { "X", I.Floor.Fit }, CFrame = CFrame.new(c - UP * (floorH / 2)) * CFrame.Angles(0, -a, 0), Color = C.Stone, Collide = true, Parent = folder })
	local rnd = Random.new(slot * 31)
	Kit.Make("IslandUnder", { Name = "Under", Fit = { "X", I.Under.Fit }, CFrame = CFrame.new(c - UP * (floorH + under.Y / 2 - 0.3)) * CFrame.Angles(rnd:NextNumber(-0.05, 0.05), rnd:NextNumber(0, 6.28), rnd:NextNumber(-0.05, 0.05)),
		Color = C.Rock, Parent = folder })
	Kit.HangingCrystals(folder, c - UP * floorH, R, under.Y, C.Crystal, slot)
end
PAD_BUILD[2] = function(island, folder) -- STAR TILES
	local c, _, a = centerOf(island)
	Kit.TileRing(folder, c, R * I.Tiles.From, R * I.Tiles.To, I.Tiles.Count, C.Stone2, a)
end
PAD_BUILD[3] = function(island, folder) -- BRASS RIM
	local c = centerOf(island)
	local rimTube = Kit.Fit("RimRing", "X", I.RimFit).Y
	Kit.Make("RimRing", brass({ Name = "Rim", Fit = { "X", I.RimFit }, CFrame = CFrame.new(c + UP * (rimTube / 2)), Collide = true, Parent = folder }))
	-- (MapAudit: the island's edge lip is floor; the boards' feet stand on it)
	local rimPart = folder:FindFirstChild("Rim", true)
	if rimPart then rimPart:SetAttribute("Ground", true) end
	local inlayTube = Kit.Fit("RimRing", "X", I.InlayFit).Y
	Kit.Make("RimRing", brass({ Name = "Inlay", Fit = { "X", I.InlayFit }, CFrame = CFrame.new(c + UP * (0.1 - inlayTube / 2)), Parent = folder }))
end
PAD_BUILD[4] = function(island, folder) -- LAMP PILLARS
	local L = I.Lamps
	for _, deg in ipairs(L.Angles) do
		local p = angled(island, deg, L.Radius)
		Kit.Make("Pillar", brass({ Name = "Pillar", Fit = { "Y", L.Pillar }, CFrame = CFrame.new(p + UP * (L.Pillar / 2)), Collide = true, Parent = folder }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", L.Orb }, CFrame = CFrame.new(p + UP * (L.Pillar + L.Orb / 2)), Color = C.Lamp, Material = Enum.Material.Neon, Parent = folder })
	end
end
PAD_BUILD[5] = function(island, folder) -- CRYSTALS
	local K = I.Crystals
	local rnd = Random.new((island:GetAttribute("Slot") or 1) * 97)
	for _, deg in ipairs(K.Angles) do
		local h = rnd:NextNumber(K.Low, K.High)
		local p = angled(island, deg + rnd:NextNumber(-8, 8), rnd:NextNumber(K.From, K.To))
		Kit.Make("Crystal", { Name = "Crystal", Fit = { "Y", h }, CFrame = CFrame.new(p + UP * (h / 2 - 0.3)) * CFrame.Angles(rnd:NextNumber(-0.2, 0.2), rnd:NextNumber(0, 6), rnd:NextNumber(-0.2, 0.2)),
			Color = C.Crystal, Reflectance = 0.15, Parent = folder })
	end
end
PAD_BUILD[6] = function(island, folder) -- MOON GARDEN
	local g = at(island, I.Garden.At.X, I.Garden.At.Z)
	local gs = Kit.Fit("GrassPatch", "X", I.Garden.Fit)
	Kit.Make("GrassPatch", { Name = "Garden", Fit = { "X", I.Garden.Fit }, CFrame = CFrame.new(g + UP * (gs.Y / 2 - 0.1)), Color = C.Grass, Parent = folder })
end
PAD_BUILD[7] = function(island, folder) -- YOUR BANNER
	local c = centerOf(island)
	local BN = I.Banner
	local pole = at(island, BN.At.X, BN.At.Z)
	local toCentre = Vector3.new(c.X - pole.X, 0, c.Z - pole.Z).Unit
	local poleSize = Kit.Fit("Pillar", "Y", BN.Pole)
	Kit.Make("Pillar", brass({ Name = "BannerPole", Fit = { "Y", BN.Pole }, CFrame = CFrame.new(pole + UP * (BN.Pole / 2)), Collide = true, Parent = folder }))
	local cloth = pole + toCentre * (poleSize.X / 2 + 0.4) + UP * (BN.Pole - BN.Cloth / 2 - 0.3)
	local flag = Kit.Make("Banner", { Name = "Banner", Fit = { "Y", BN.Cloth }, CFrame = CFrame.lookAt(cloth, cloth + toCentre), Color = island:GetAttribute("Color") or C.Brass, Parent = folder })
	flag:SetAttribute("PlayerColor", true)
end
PAD_BUILD[8] = function(island, folder) -- CROWN RING (a brass halo above the island, clear of the boards' tops)
	local c = centerOf(island)
	Kit.Make("RimRing", brass({ Name = "CrownRing", Fit = { "X", I.CrownRing }, CFrame = CFrame.new(c + UP * I.CrownHeight), Parent = folder }))
end
PAD_BUILD[9] = function(island, folder) -- STAR DAIS
	local c = centerOf(island)
	local ds = Kit.Fit("Dais", "X", I.Dais)
	Kit.Make("Dais", brass({ Name = "Dais", Fit = { "X", I.Dais }, CFrame = CFrame.new(c + UP * (ds.Y / 2)), Collide = true, Parent = folder }))
end
PAD_BUILD[10] = function(island, folder) -- TELESCOPE
	local TS = I.Telescope
	local t = at(island, TS.At.X, TS.At.Z)
	Kit.Make("Telescope", brass({ Name = "Telescope", Fit = { "Y", TS.Height }, CFrame = CFrame.lookAt(t + UP * (TS.Height / 2), Vector3.new(O.X, t.Y + TS.Height / 2, O.Z)), Collide = true, Parent = folder }))
end
-- (11-20: new pieces from the kit; every place from MapConfig.Islands.PadBuilds, clear of the boards, the bridge path and the spawn)
local PB = I.PadBuilds
PAD_BUILD[11] = function(island, folder) -- GYRO RING: a tilted brass gyroscope ring floating over the dais
	local c = centerOf(island)
	Kit.Make("GyroRing", brass({ Name = "Gyro", Fit = { "X", PB.Gyro.Fit }, CFrame = CFrame.new(c + UP * PB.Gyro.Height) * CFrame.Angles(math.rad(PB.Gyro.Tilt), 0, math.rad(PB.Gyro.Tilt / 2)), Parent = folder }))
end
PAD_BUILD[12] = function(island, folder) -- STAR GATE: an arch over the path where the bridge comes in
	local c = centerOf(island)
	local p = at(island, PB.Gate.X, 0)
	local gs = Kit.Fit("GateArch", "Y", PB.Gate.Height)
	Kit.Make("GateArch", brass({ Name = "Gate", Fit = { "Y", PB.Gate.Height }, CFrame = CFrame.lookAt(p + UP * (gs.Y / 2), Vector3.new(c.X, p.Y + gs.Y / 2, c.Z)), Collide = true, Parent = folder }))
end
PAD_BUILD[13] = function(island, folder) -- INNER LIGHTS: four short lamp posts round the dais
	for _, deg in ipairs(PB.Lights.Angles) do
		local p = angled(island, deg, PB.Lights.Radius)
		Kit.Make("Pillar", brass({ Name = "LightPost", Fit = { "Y", PB.Lights.Post }, CFrame = CFrame.new(p + UP * (PB.Lights.Post / 2)), Collide = true, Parent = folder }))
		Kit.Make("LampOrb", { Name = "Light", Fit = { "Y", PB.Lights.Orb }, CFrame = CFrame.new(p + UP * (PB.Lights.Post + PB.Lights.Orb / 2)), Color = C.Ice, Material = Enum.Material.Neon, Parent = folder })
	end
end
PAD_BUILD[14] = function(island, folder) -- FLOATING CRYSTALS round the rim
	local rnd = Random.new((island:GetAttribute("Slot") or 1) * 53)
	-- (6 Nov: out past the rim, Radius 34; at 26 they hung in front of / through the boards' screens)
	for _, deg in ipairs(PB.Floaters.Angles) do
		local p = angled(island, deg, PB.Floaters.Radius)
		local h = rnd:NextNumber(PB.Floaters.Size[1], PB.Floaters.Size[2])
		Kit.Make("CrystalCluster", { Name = "Floater", Fit = { "Y", h }, CFrame = CFrame.new(p + UP * rnd:NextNumber(PB.Floaters.Height[1], PB.Floaters.Height[2])) * CFrame.Angles(0, rnd:NextNumber(0, 6.28), 0),
			Color = C.Ice, Reflectance = 0.15, Parent = folder })
	end
end
PAD_BUILD[15] = function(island, folder) -- STAR ALTAR on the dais
	local c = centerOf(island)
	local ds = Kit.Fit("Dais", "X", I.Dais)
	local as = Kit.Fit("Altar", "Y", PB.Altar.Height)
	Kit.Make("Altar", brass({ Name = "Altar", Fit = { "Y", PB.Altar.Height }, CFrame = CFrame.new(c + UP * (ds.Y + as.Y / 2)), Collide = true, Parent = folder }))
	Kit.Make("CoreOrb", { Name = "AltarStar", Fit = { "Y", PB.Altar.Orb }, CFrame = CFrame.new(c + UP * (ds.Y + as.Y + PB.Altar.Orb / 2 + 0.3)), Color = C.Star, Material = Enum.Material.Neon, Parent = folder })
end
PAD_BUILD[16] = function(island, folder) -- ORBIT HALO: a wide thin ring round the whole island
	local c = centerOf(island)
	Kit.Make("OrbitRing", { Name = "Halo", Fit = { "X", PB.Halo.Fit }, CFrame = CFrame.new(c + UP * PB.Halo.Height) * CFrame.Angles(math.rad(PB.Halo.Tilt), 0, 0), Color = C.Orbit, Material = Enum.Material.Neon, Parent = folder })
end
PAD_BUILD[17] = function(island, folder) -- PLANET GLOBE on a pedestal
	local p = at(island, PB.Globe.At.X, PB.Globe.At.Z)
	Kit.Make("Pillar", brass({ Name = "GlobeStand", Fit = { "Y", PB.Globe.Stand }, CFrame = CFrame.new(p + UP * (PB.Globe.Stand / 2)), Collide = true, Parent = folder }))
	Kit.Make("Planet", { Name = "Globe", Fit = { "Y", PB.Globe.Size }, CFrame = CFrame.new(p + UP * (PB.Globe.Stand + PB.Globe.Size / 2)), Color = C.Ice, Reflectance = 0.1, Parent = folder })
end
PAD_BUILD[18] = function(island, folder) -- CRYSTAL SPIRES flanking the bridge
	for _, deg in ipairs(PB.Spires.Angles) do
		local p = angled(island, deg, PB.Spires.Radius)
		Kit.Make("Crystal", { Name = "Spire", Fit = { "Y", PB.Spires.Height }, CFrame = CFrame.new(p + UP * (PB.Spires.Height / 2 - 0.3)) * CFrame.Angles(0, math.rad(deg), 0), Color = C.Crystal, Reflectance = 0.2, Parent = folder })
	end
end
PAD_BUILD[19] = function(island, folder) -- LIGHT WALK: glowing strips along the path from the bridge
	for _, z in ipairs({ -PB.Walk.Half, PB.Walk.Half }) do
		local from, to = at(island, PB.Walk.From, z, 0.06), at(island, PB.Walk.To, z, 0.06)
		Builder.part({ Name = "WalkLight", Size = Vector3.new(0.5, 0.12, (to - from).Magnitude), CFrame = CFrame.lookAt((from + to) / 2, to), Color = C.Lamp, Material = Enum.Material.Neon, Parent = folder })
	end
end
PAD_BUILD[20] = function(island, folder) -- BEACON: a tall brass mast with a star light on top
	local p = at(island, PB.Beacon.At.X, PB.Beacon.At.Z)
	Kit.Make("Pillar", brass({ Name = "Beacon", Fit = { "Y", PB.Beacon.Height }, CFrame = CFrame.new(p + UP * (PB.Beacon.Height / 2)), Collide = true, Parent = folder }))
	Kit.Make("CoreOrb", { Name = "BeaconLight", Fit = { "Y", PB.Beacon.Orb }, CFrame = CFrame.new(p + UP * (PB.Beacon.Height + PB.Beacon.Orb / 2)), Color = C.Star, Material = Enum.Material.Neon, Parent = folder })
end

local function setBridge(island: Model, lit: boolean)
	local bridge = island:FindFirstChild("Bridge")
	if not bridge then return end
	for _, seg in ipairs(bridge:GetChildren()) do
		if seg:IsA("BasePart") then
			seg.Color = if lit then C.Bridge else C.BridgeDim
			seg.Material = if lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

-- is a pad at `p` (on the floor at y) clear of every piece, board and the landing? (6 Nov, owner: "buttons inside a platform":
-- the garden / crystals are CanQuery off, so a ray never saw them.) Each part's real box: the pad's column (floor + 0.3 to
-- + 6 studs) must stay PadClear studs away from it. Flat floor pieces (top under the pad's top) and things high overhead
-- don't count; the thin RINGS (Box collision = a solid disc) are measured as rings.
local RINGS = { Halo = true, Gyro = true, CrownRing = true, Rim = true, Inlay = true }
local function padClear(island: Model, p: Vector3, y: number): boolean
	local need = I.PadSize / 2 + 0.4 + I.PadClear
	for _, folder in ipairs({ island:FindFirstChild("Pieces"), island:FindFirstChild("Boards"), island:FindFirstChild("Landing") }) do
		for _, part in ipairs(folder and folder:GetDescendants() or {}) do
			if not part:IsA("BasePart") or part.Transparency >= 0.95 then continue end
			local cf, half = part.CFrame, part.Size / 2
			local reach = math.abs(cf.RightVector.Y) * half.X + math.abs(cf.UpVector.Y) * half.Y + math.abs(cf.LookVector.Y) * half.Z
			local top, bottom = cf.Position.Y + reach, cf.Position.Y - reach
			if top <= y + 0.3 or bottom >= y + 6 then continue end
			for _, h in ipairs({ 0.3, 2, 4, 6 }) do
				local q = cf:PointToObjectSpace(Vector3.new(p.X, y + h, p.Z))
				local d
				if RINGS[part.Name] then
					local tube = half.Y
					d = Vector2.new(Vector2.new(q.X, q.Z).Magnitude - (half.X - tube), q.Y).Magnitude - tube
				else
					d = Vector3.new(math.max(math.abs(q.X) - half.X, 0), math.max(math.abs(q.Y) - half.Y, 0), math.max(math.abs(q.Z) - half.Z, 0)).Magnitude
				end
				if d < need then return false end
			end
		end
	end
	return true
end

-- the next pad on the floor: a lit disc (the client draws its name, price and the arrow; a click buys it). On whatever floor
-- is there (the bare rock first), found with a ray; at its spot in I.PadSpots, or (if a piece is in the way there) the next
-- spot in the list that is clear
local function placePad(island: Model, pads: number)
	local old = island:FindFirstChild("NextPad")
	if old then old:Destroy() end
	if (island:GetAttribute("Owner") or 0) == 0 or pads >= #Econ.Pads then return end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { island:FindFirstChild("Pieces") }
	local p, y
	for k = 0, #I.PadSpots - 1 do
		local spot = I.PadSpots[((pads + k) % #I.PadSpots) + 1]
		local q = at(island, spot.X, spot.Z)
		local hit = workspace:Raycast(q + UP * 30, -UP * 60, params)
		local qy = if hit then hit.Position.Y else q.Y
		if k == 0 then p, y = q, qy end
		if padClear(island, q, qy) then
			p, y = q, qy
			break
		end
		if k == #I.PadSpots - 1 then warn("[GalaxyMap] no clear pad spot on " .. island.Name .. " for pad " .. (pads + 1)) end
	end
	local pad = Instance.new("Model")
	pad.Name = "NextPad"
	pad:SetAttribute("Index", pads + 1)
	pad:SetAttribute("Price", Econ.Pads[pads + 1].price)
	pad:SetAttribute("PadName", Econ.Pads[pads + 1].name)
	pad:SetAttribute("Bonus", Econ.Pads[pads + 1].bonus == true)
	local disc = Builder.part({ Name = "Disc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, I.PadSize, I.PadSize), CFrame = CFrame.new(Vector3.new(p.X, y + 0.15, p.Z)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Ice, Material = Enum.Material.Neon, CanCollide = false, Parent = pad })
	disc.CanQuery = true
	Builder.part({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, I.PadSize + 0.8, I.PadSize + 0.8), CFrame = CFrame.new(Vector3.new(p.X, y + 0.08, p.Z)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.Brass, Material = MapConfig.BrassMaterial, CanCollide = false, Parent = pad })
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = I.PadReach
	click.Parent = disc
	pad.PrimaryPart = disc
	pad.Parent = island
end

-- builds / removes pieces so the island shows `pads` pads (pop: the new ones are announced to the clients). Island attribute
-- Tier = the old island tier those pieces add up to (the star's light, the spawn on the rock, the rank before Supernova 1)
local PAD_TIER = { 1, 1, 2, 3, 3, 4, 4, 5, 5, 6 }
local function applyPads(island: Model, pads: number, pop: boolean)
	local pieces = island:FindFirstChild("Pieces") :: Folder
	local owned = (island:GetAttribute("Owner") or 0) ~= 0
	if not owned then pads = 0 end
	-- no pads (and a free slot): the bare asteroid + its landing (Builder.RockPieces); pad 1 (the stone island) replaces it
	local rock = pieces:FindFirstChild("T0")
	if rock and rock:GetAttribute("Owned") ~= owned then
		rock:Destroy()
		rock = nil
	end
	if pads == 0 and not rock then
		local c, dir = centerOf(island)
		rock = Builder.RockPieces(island, c, dir, island:GetAttribute("Slot") or 1, owned)
		rock.Parent = pieces
	elseif pads > 0 and rock then
		rock:Destroy()
		rock = nil
	end
	for i = 1, #Econ.Pads do
		local folder = pieces:FindFirstChild("P" .. i)
		if i <= pads and not folder then
			folder = Instance.new("Model")
			folder.Name = "P" .. i
			PAD_BUILD[i](island, folder)
			if pop then folder:SetAttribute("Pop", os.clock()) end
			folder.Parent = pieces
		elseif i > pads and folder then
			folder:Destroy()
		end
	end
	-- (the old tier models, from before the pads)
	for t = 1, 6 do
		local f = pieces:FindFirstChild("T" .. t)
		if f then f:Destroy() end
	end
	for _, d in ipairs(pieces:GetDescendants()) do
		if d:GetAttribute("PlayerColor") then Kit.SetColor(d, island:GetAttribute("Color") or C.Brass) end
	end
	island:SetAttribute("Pads", pads)
	island:SetAttribute("Tier", if pads == 0 then 0 else PAD_TIER[math.min(pads, #PAD_TIER)])
	placePad(island, pads)
end

------------------------------------------------------------------------
-- owners
------------------------------------------------------------------------
local function num(owner, name: string): number
	local v = if typeof(owner) == "Instance" then owner:GetAttribute(name) else owner[name]
	return tonumber(v) or 0
end
local function refresh(slot: number, pop: boolean)
	local island = islandOf(slot)
	local owner = owners[slot]
	if not owner then
		island:SetAttribute("Owner", 0)
		island:SetAttribute("OwnerName", "")
		for _, a in ipairs({ "BodyTiers", "Supernovas", "Belt" }) do island:SetAttribute(a, 0) end
		island:SetAttribute("Sys", "")
		island:SetAttribute("Rank", "")
		island:SetAttribute("Ready", false)
		setBridge(island, false)
		applyPads(island, 0, false)
		local boards = island:FindFirstChild("Boards")
		if boards then boards:Destroy() end
		return
	end
	local isPlayer = typeof(owner) == "Instance"
	island:SetAttribute("Owner", if isPlayer then owner.UserId else -slot)
	island:SetAttribute("OwnerName", if isPlayer then owner.DisplayName else owner.Name)
	island:SetAttribute("Color", MapConfig.PlayerColors[slot])
	local bodies, tiers, novas = num(owner, "Bodies"), num(owner, "BodyTiers"), num(owner, "Supernovas")
	island:SetAttribute("BodyTiers", tiers)
	-- (feel pass: the copies orbit as bodies now; the belt of one rock per body is gone)
	island:SetAttribute("Belt", 0)
	island:SetAttribute("Sys", if isPlayer then owner:GetAttribute("Sys") or "" else owner.Sys or "")
	island:SetAttribute("Lit", if isPlayer then owner:GetAttribute("GalaxyLit") or 0 else 0)
	island:SetAttribute("Supernovas", novas)
	island:SetAttribute("Ready", (if isPlayer then owner:GetAttribute("SupernovaReady") else owner.Ready) == true)
	setBridge(island, true)
	makeBoards(island)
	local pads = math.clamp(math.floor(num(owner, "Pads")), 0, #Econ.Pads)
	applyPads(island, pads, pop and pads > (island:GetAttribute("Pads") or 0))
	local _ = bodies
	island:SetAttribute("Rank", if isPlayer then owner:GetAttribute("Rank") or "" else MapConfig.RankOf(island:GetAttribute("Tier") or 0, novas))
end

local function spawnCFrame(slot: number): CFrame
	local island = islandOf(slot)
	local spot = if (island:GetAttribute("Tier") or 0) == 0 then I.SpawnRock else I.Spawn
	local pos = at(island, spot.X, spot.Z, 3.5)
	-- facing the pair of boards (the far edge, the gap between CONSTELLATION TREE and INFO)
	local boards = at(island, MapConfig.Boards.Pair.At.X, MapConfig.Boards.Pair.At.Z)
	return CFrame.lookAt(pos, Vector3.new(boards.X, pos.Y, boards.Z))
end
local function toIsland(player: Player)
	local slot = slotOf[player]
	local char = player.Character
	if not slot or not char then return end
	char:PivotTo(spawnCFrame(slot))
end

local function claim(player: Player)
	for slot = 1, MapConfig.Islands.Count do
		if not owners[slot] or typeof(owners[slot]) ~= "Instance" then
			owners[slot] = player
			slotOf[player] = slot
			player:SetAttribute("Island", slot)
			refresh(slot, false)
			return slot
		end
	end
	return nil -- (more than 8 players: no island, the centre spawn)
end

local WATCH = { "Bodies", "BodyTiers", "Supernovas", "SupernovaReady", "Sys", "Pads", "Rank", "GalaxyLit" }
local function onPlayer(player: Player)
	local slot = claim(player)
	local lastNovas = tonumber(player:GetAttribute("Supernovas")) or 0
	for _, name in ipairs(WATCH) do
		player:GetAttributeChangedSignal(name):Connect(function()
			local s = slotOf[player]
			if not s then return end
			refresh(s, true)
			if name == "Supernovas" then
				local now = tonumber(player:GetAttribute("Supernovas")) or 0
				if now > lastNovas then remote:FireAllClients("Supernova", s, player.UserId) end
				lastNovas = now
			end
		end)
	end
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart", 10)
		task.wait()
		toIsland(player)
	end)
	if player.Character then toIsland(player) end
	local _ = slot
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(player)
	local slot = slotOf[player]
	slotOf[player] = nil
	if slot and owners[slot] == player then
		owners[slot] = nil
		refresh(slot, false)
	end
end)

-- fell into the void: back to your island
task.spawn(function()
	while true do
		task.wait(1)
		for player, _ in pairs(slotOf) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < O.Y + MapConfig.VoidY then toIsland(player) end
		end
	end
end)


for slot = 1, MapConfig.Islands.Count do refresh(slot, false) end

-- the STAR FORGE stands on SECTOR 2 (purpose, 5 Nov: Ignition 1 opens Sector 2 = the Forge): a copy of the plaza's Forge
-- model on the Sector 2 island, with a prompt (Window = "Forge": GalaxyMapClient opens it for players past Ignition 1)
task.spawn(function()
	local centre = root:FindFirstChild("Centre")
	local src = centre and centre:FindFirstChild("StarForge")
	local nextS = root:FindFirstChild("NextSector")
	if not src or not nextS or nextS:FindFirstChild("SectorForge") then return end
	local forge = src:Clone()
	forge.Name = "SectorForge"
	local NS = MapConfig.NextSector
	local at = O + NS.Position + Vector3.new(0, 0.2, 0)
	local cf, size = forge:GetBoundingBox()
	-- (7 Nov, MapAudit FACING: its sign faced away from the plaza, the only place it's seen from: turned to face the Core)
	forge:PivotTo(CFrame.new(at + Vector3.new(0, size.Y / 2 - (cf.Position.Y - forge:GetPivot().Position.Y), 0)) * CFrame.Angles(0, math.rad(NS.Angle + 90 + 180), 0))
	forge:SetAttribute("FaceTarget", "Galaxy.Centre.Core")
	for _, p in ipairs(forge:GetDescendants()) do
		if p:IsA("ProximityPrompt") then p:Destroy() end
	end
	local host = forge.PrimaryPart or forge:FindFirstChildWhichIsA("BasePart", true)
	if host then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "STAR FORGE"
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Window", "Forge")
		prompt.Parent = host
	end
	forge.Parent = nextS
	-- (6 Nov: no crystal in front of the Forge's sign or any other sign: the island's crystals were placed before the Forge)
	Builder.ClearDecor(root)
	-- (7 Nov, "black boxes": the emitters / beams / trails SAVED in the place (built before the VFX pass) get their _alpha
	-- texture too: an _add id, or the old mote upload on the Black Hole's Pull)
	local VT = require(game:GetService("ReplicatedStorage"):WaitForChild("Galaxy"):WaitForChild("VfxTextures"))
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")) and d.Texture ~= "" then
			local a = VT.alphaOf(d.Texture)
			if a then d.Texture = a end
		end
	end
	-- (7 Nov, MapAudit v3 (real shapes; the crystals are CanQuery off, so rays never saw them):
	--  * Sector 2's random crystals stood inside the Forge's platform: any crystal on its footprint moves out to its side;
	--  * ClearDecor pushed a plaza crystal sideways off PLAYERS NEAR YOU's face into its neighbour: two clusters closer than
	--    their sizes allow, the bigger one steps away from the smaller (away from the face it was cleared from))
	local fcf, fsize = forge:GetBoundingBox()
	for _, cr in ipairs(nextS:GetChildren()) do
		if cr.Name == "Crystal" and cr:IsA("BasePart") then
			local q = fcf:PointToObjectSpace(cr.Position)
			local r = math.max(cr.Size.X, cr.Size.Z) / 2
			if math.abs(q.X) < fsize.X / 2 + r + 1 and math.abs(q.Z) < fsize.Z / 2 + r + 1 then
				local side = if q.X >= 0 then 1 else -1
				local to = fcf:PointToWorldSpace(Vector3.new(side * (fsize.X / 2 + r + 1.5), q.Y, q.Z))
				cr.CFrame = cr.CFrame + Vector3.new(to.X - cr.Position.X, 0, to.Z - cr.Position.Z)
			end
		end
	end
	local det = centre and centre:FindFirstChild("Details")
	local clusters = {}
	for _, d in ipairs(det and det:GetChildren() or {}) do
		if d.Name == "CrystalCluster" and d:IsA("BasePart") then table.insert(clusters, d) end
	end
	for i = 1, #clusters do
		for j = i + 1, #clusters do
			local a, b = clusters[i], clusters[j]
			local ra, rb = math.max(a.Size.X, a.Size.Z) / 2, math.max(b.Size.X, b.Size.Z) / 2
			local d = Vector3.new(b.Position.X - a.Position.X, 0, b.Position.Z - a.Position.Z)
			if d.Magnitude < ra + rb + 0.5 then
				local big, small = if a.Size.Y >= b.Size.Y then a else b, if a.Size.Y >= b.Size.Y then b else a
				local away = Vector3.new(big.Position.X - small.Position.X, 0, big.Position.Z - small.Position.Z)
				away = if away.Magnitude > 0.01 then away.Unit else Vector3.new(1, 0, 0)
				big.CFrame = big.CFrame + away * (ra + rb + 0.5 - d.Magnitude)
				-- (re-seated on what's under it now: it may have stepped onto the plaza's raised rim)
				local rp = RaycastParams.new()
				rp.FilterType = Enum.RaycastFilterType.Exclude
				rp.FilterDescendantsInstances = { big }
				local hit = workspace:Raycast(big.Position + Vector3.new(0, big.Size.Y, 0), Vector3.new(0, -big.Size.Y * 3, 0), rp)
				if hit then big.CFrame = big.CFrame + Vector3.new(0, hit.Position.Y + big.Size.Y / 2 - 0.1 - big.Position.Y, 0) end
			end
		end
	end
end)

-- (3.1: the plaza's Black Hole gate gets a prompt: "Open BLACK HOLE" -> the window, GalaxyMapClient -> Galaxy.OpenWindow)
task.spawn(function()
	local g = workspace:WaitForChild("Galaxy", 60)
	local centre = g and g:WaitForChild("Centre", 30)
	local hole = centre and centre:WaitForChild("BlackHoleGate", 30)
	if not hole or hole:FindFirstChildWhichIsA("ProximityPrompt", true) then return end
	hole:SetAttribute("Window", "BlackHole")
	local host = hole:FindFirstChild("Pull") or hole:FindFirstChildWhichIsA("BasePart", true)
	if not host then return end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "BLACK HOLE"
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Window", "BlackHole")
	prompt.Parent = host
end)

------------------------------------------------------------------------
-- Studio test switches
------------------------------------------------------------------------
if RunService:IsStudio() then
	local function testIslands()
		local on = workspace:GetAttribute("TestIslands") == true
		-- (TestIslandPads = n: every test island shows n pads, so the placement check can walk every next-pad spot)
		local forcePads = workspace:GetAttribute("TestIslandPads")
		local tier = 0
		for slot = 1, MapConfig.Islands.Count do
			if typeof(owners[slot]) ~= "Instance" then
				if on then
					local novas = ({ 0, 0, 0, 0, 1, 3, 8 })[tier + 1] or 8
					local bodies = ({ 0, 5, 25, 75, 0, 0, 0 })[tier + 1] or 0
					owners[slot] = { Name = "Tester " .. slot, Bodies = bodies, BodyTiers = math.min(tier, 6), Supernovas = novas, Ready = tier >= 5,
						Pads = if type(forcePads) == "number" then forcePads else ({ 0, 2, 5, 8, 11, 15, 20 })[tier + 1] or 20 }
					tier = (tier + 1) % (MapConfig.MaxTier + 1)
				else
					owners[slot] = nil
				end
				refresh(slot, true)
			end
		end
	end
	workspace:GetAttributeChangedSignal("TestIslands"):Connect(testIslands)
	workspace:GetAttributeChangedSignal("TestIslandPads"):Connect(function() if workspace:GetAttribute("TestIslands") then testIslands() end end)
	if workspace:GetAttribute("TestIslands") then testIslands() end
	local function testPlayers()
		for _, player in ipairs(Players:GetPlayers()) do
			for _, name in ipairs({ "Bodies", "BodyTiers", "Supernovas" }) do
				local v = workspace:GetAttribute("Test" .. name)
				if type(v) == "number" then player:SetAttribute(name, v) end
			end
			local ig = workspace:GetAttribute("TestIgnition")
			if type(ig) == "number" then
				for i, item in ipairs(MapConfig.Ignition) do
					if item.attribute ~= "Supernovas" then player:SetAttribute(item.attribute, if i <= ig then item.need else 0) end
				end
			end
		end
	end
	for _, name in ipairs({ "TestBodies", "TestBodyTiers", "TestSupernovas", "TestIgnition" }) do
		workspace:GetAttributeChangedSignal(name):Connect(testPlayers)
	end
	Players.PlayerAdded:Connect(function() task.wait(1) testPlayers() end)
	task.delay(1, testPlayers)
end
