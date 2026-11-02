-- GalaxyMapService (Galaxy Incremental, 2 Nov): the PERSONAL ISLANDS.
--  * Join: you claim the first free island (of 8); leave: it's freed (your save keeps your progress, not the island).
--  * You spawn ON your island, facing the Core (and come back there if you fall into the void).
--  * Your island GROWS with your progress (MapConfig.Tiers: bodies owned in the first run, then Supernovas): each new tier's
--    pieces appear (the client pops them in with a sparkle). Its bridge to the centre is lit at every tier.
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

local C = MapConfig.Colors
local O = MapConfig.Origin

-- the map (built in Studio; rebuilt here when it still has stand-ins and the owner's kit has been imported since)
local root = workspace:FindFirstChild("Galaxy")
if not root or (root:GetAttribute("StandIns") == true and Kit.AllImported()) then
	root = Builder.Build()
end
local islandsFolder = root:WaitForChild("Islands")

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
local function makeBoards(island: Model)
	local old = island:FindFirstChild("Boards")
	if old then return old end
	local c, dir = centerOf(island)
	local cfs = Builder.BoardCFrames(c, dir)
	local model = Instance.new("Model")
	model.Name = "Boards"
	for _, spec in ipairs(MapConfig.Boards.List) do
		local panel = Instance.new("Model")
		panel.Name = "Board_" .. spec.id
		panel:SetAttribute("Board", spec.id)
		Builder.BoardFrame(panel, cfs[spec.id], spec, c.Y, island:GetAttribute("OwnerName"))
		panel.Screen:SetAttribute("Board", spec.id)
		panel.Parent = model
	end
	-- the ledge runs on through the gap between the pair (Regrowth's low wall)
	local P = MapConfig.Boards.Pair
	local ledgeTop = P.Bottom - P.Lip - P.BarLow
	local gap = at(island, P.At.X + 0.3, P.At.Z, ledgeTop / 2)
	local face = Builder.faceTo(gap, c)
	Builder.part({ Name = "GapLedge", Size = Vector3.new(P.Gap + 1.2, ledgeTop, P.LedgeDepth - 0.4), CFrame = face, Color = MapConfig.Boards.Stone, CanCollide = true, Parent = model })
	Builder.part({ Name = "GapLedgeCap", Size = Vector3.new(P.Gap + 1.5, 0.3, P.LedgeDepth - 0.1), CFrame = face * CFrame.new(0, ledgeTop / 2 - 0.1, 0), Color = MapConfig.Boards.StoneLight, CanCollide = true, Parent = model })
	model.Parent = island
	return model
end

local TIER_BUILD = {}
TIER_BUILD[1] = function(island, folder)
	local c, dir, a = centerOf(island)
	local slot = island:GetAttribute("Slot") or 1
	local floorH = Kit.Fit("IslandTop", "X", I.Floor.Fit).Y
	local under = Kit.Fit("IslandUnder", "X", I.Under.Fit)
	Kit.Make("IslandTop", { Name = "Disc", Fit = { "X", I.Floor.Fit }, CFrame = CFrame.new(c - UP * (floorH / 2)) * CFrame.Angles(0, -a, 0), Color = C.Stone, Collide = true, Parent = folder })
	-- the floating island's rock cone (turned a little per slot) + crystals hanging from it
	local rnd = Random.new(slot * 31)
	Kit.Make("IslandUnder", { Name = "Under", Fit = { "X", I.Under.Fit }, CFrame = CFrame.new(c - UP * (floorH + under.Y / 2 - 0.3)) * CFrame.Angles(rnd:NextNumber(-0.05, 0.05), rnd:NextNumber(0, 6.28), rnd:NextNumber(-0.05, 0.05)),
		Color = C.Rock, Parent = folder })
	Kit.HangingCrystals(folder, c - UP * floorH, R, under.Y, C.Crystal, slot)
	Kit.TileRing(folder, c, R * I.Tiles.From, R * I.Tiles.To, I.Tiles.Count, C.Stone2, a)
	local _ = dir
end
TIER_BUILD[2] = function(island, folder)
	local c = centerOf(island)
	local rimTube = Kit.Fit("RimRing", "X", I.RimFit).Y
	Kit.Make("RimRing", brass({ Name = "Rim", Fit = { "X", I.RimFit }, CFrame = CFrame.new(c + UP * (rimTube / 2)), Collide = true, Parent = folder }))
	local inlayTube = Kit.Fit("RimRing", "X", I.InlayFit).Y
	Kit.Make("RimRing", brass({ Name = "Inlay", Fit = { "X", I.InlayFit }, CFrame = CFrame.new(c + UP * (0.1 - inlayTube / 2)), Parent = folder }))
end
TIER_BUILD[3] = function(island, folder)
	local L = I.Lamps
	for _, deg in ipairs(L.Angles) do
		local p = angled(island, deg, L.Radius)
		Kit.Make("Pillar", brass({ Name = "Pillar", Fit = { "Y", L.Pillar }, CFrame = CFrame.new(p + UP * (L.Pillar / 2)), Collide = true, Parent = folder }))
		Kit.Make("LampOrb", { Name = "Lamp", Fit = { "Y", L.Orb }, CFrame = CFrame.new(p + UP * (L.Pillar + L.Orb / 2)), Color = C.Lamp, Material = Enum.Material.Neon, Parent = folder })
	end
end
TIER_BUILD[4] = function(island, folder)
	local K = I.Crystals
	local rnd = Random.new((island:GetAttribute("Slot") or 1) * 97)
	for _, deg in ipairs(K.Angles) do
		local h = rnd:NextNumber(K.Low, K.High)
		local p = angled(island, deg + rnd:NextNumber(-8, 8), rnd:NextNumber(K.From, K.To))
		Kit.Make("Crystal", { Name = "Crystal", Fit = { "Y", h }, CFrame = CFrame.new(p + UP * (h / 2 - 0.3)) * CFrame.Angles(rnd:NextNumber(-0.2, 0.2), rnd:NextNumber(0, 6), rnd:NextNumber(-0.2, 0.2)),
			Color = C.Crystal, Reflectance = 0.15, Parent = folder })
	end
	local g = at(island, I.Garden.At.X, I.Garden.At.Z)
	local gs = Kit.Fit("GrassPatch", "X", I.Garden.Fit)
	Kit.Make("GrassPatch", { Name = "Garden", Fit = { "X", I.Garden.Fit }, CFrame = CFrame.new(g + UP * (gs.Y / 2 - 0.1)), Color = C.Grass, Parent = folder })
end
TIER_BUILD[5] = function(island, folder)
	local c = centerOf(island)
	local BN = I.Banner
	local pole = at(island, BN.At.X, BN.At.Z)
	local toCentre = Vector3.new(c.X - pole.X, 0, c.Z - pole.Z).Unit
	local poleSize = Kit.Fit("Pillar", "Y", BN.Pole)
	Kit.Make("Pillar", brass({ Name = "BannerPole", Fit = { "Y", BN.Pole }, CFrame = CFrame.new(pole + UP * (BN.Pole / 2)), Collide = true, Parent = folder }))
	-- the kit's cloth Banner hanging in front of the pole, facing the island's centre
	local cloth = pole + toCentre * (poleSize.X / 2 + 0.4) + UP * (BN.Pole - BN.Cloth / 2 - 0.3)
	local flag = Kit.Make("Banner", { Name = "Banner", Fit = { "Y", BN.Cloth }, CFrame = CFrame.lookAt(cloth, cloth + toCentre), Color = island:GetAttribute("Color") or C.Brass, Parent = folder })
	flag:SetAttribute("PlayerColor", true)
	-- a brass halo ring above the island (clear of the boards' tops)
	Kit.Make("RimRing", brass({ Name = "CrownRing", Fit = { "X", I.CrownRing }, CFrame = CFrame.new(c + UP * I.CrownHeight), Parent = folder }))
end
TIER_BUILD[6] = function(island, folder)
	local c = centerOf(island)
	local ds = Kit.Fit("Dais", "X", I.Dais)
	Kit.Make("Dais", brass({ Name = "Dais", Fit = { "X", I.Dais }, CFrame = CFrame.new(c + UP * (ds.Y / 2)), Collide = true, Parent = folder }))
	local TS = I.Telescope
	local t = at(island, TS.At.X, TS.At.Z)
	Kit.Make("Telescope", brass({ Name = "Telescope", Fit = { "Y", TS.Height }, CFrame = CFrame.lookAt(t + UP * (TS.Height / 2), Vector3.new(O.X, t.Y + TS.Height / 2, O.Z)), Collide = true, Parent = folder }))
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

-- builds / removes pieces so the island shows `tier` (pop: the new ones are announced to the clients)
local function applyTier(island: Model, tier: number, pop: boolean)
	local pieces = island:FindFirstChild("Pieces") :: Folder
	local owned = (island:GetAttribute("Owner") or 0) ~= 0
	-- tier 0 (and a free slot): the bare asteroid + its landing (Builder.RockPieces); from tier 1 the island replaces it
	local rock = pieces:FindFirstChild("T0")
	if rock and rock:GetAttribute("Owned") ~= owned then
		rock:Destroy()
		rock = nil
	end
	if tier == 0 and not rock then
		local c, dir = centerOf(island)
		rock = Builder.RockPieces(island, c, dir, island:GetAttribute("Slot") or 1, owned)
		rock.Parent = pieces
	elseif tier > 0 and rock then
		rock:Destroy()
		rock = nil
	end
	for t = 1, MapConfig.MaxTier do
		local folder = pieces:FindFirstChild("T" .. t)
		if t <= tier and not folder then
			folder = Instance.new("Model")
			folder.Name = "T" .. t
			TIER_BUILD[t](island, folder)
			if pop then folder:SetAttribute("Pop", os.clock()) end
			folder.Parent = pieces
		elseif t > tier and folder then
			folder:Destroy()
		end
	end
	-- the player's colour on the banner
	for _, d in ipairs(pieces:GetDescendants()) do
		if d:GetAttribute("PlayerColor") then Kit.SetColor(d, island:GetAttribute("Color") or C.Brass) end
	end
	island:SetAttribute("Tier", tier)
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
		island:SetAttribute("Rank", "")
		island:SetAttribute("Ready", false)
		setBridge(island, false)
		applyTier(island, 0, false)
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
	island:SetAttribute("Belt", math.min(bodies, 20))
	island:SetAttribute("Supernovas", novas)
	island:SetAttribute("Ready", (if isPlayer then owner:GetAttribute("SupernovaReady") else owner.Ready) == true)
	setBridge(island, true)
	makeBoards(island)
	local tier = MapConfig.TierOf(bodies, novas)
	island:SetAttribute("Rank", MapConfig.RankOf(tier, novas))
	applyTier(island, tier, pop and tier > (island:GetAttribute("Tier") or 0))
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

local WATCH = { "Bodies", "BodyTiers", "Supernovas", "SupernovaReady" }
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

------------------------------------------------------------------------
-- Studio test switches
------------------------------------------------------------------------
if RunService:IsStudio() then
	local function testIslands()
		local on = workspace:GetAttribute("TestIslands") == true
		local tier = 0
		for slot = 1, MapConfig.Islands.Count do
			if typeof(owners[slot]) ~= "Instance" then
				if on then
					local novas = ({ 0, 0, 0, 0, 1, 3, 8 })[tier + 1] or 8
					local bodies = ({ 0, 5, 25, 75, 0, 0, 0 })[tier + 1] or 0
					owners[slot] = { Name = "Tester " .. slot, Bodies = bodies, BodyTiers = math.min(tier, 6), Supernovas = novas, Ready = tier >= 5 }
					tier = (tier + 1) % (MapConfig.MaxTier + 1)
				else
					owners[slot] = nil
				end
				refresh(slot, true)
			end
		end
	end
	workspace:GetAttributeChangedSignal("TestIslands"):Connect(testIslands)
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
