-- SPEED ARC: League 3 Big Stadium (World note section 3). Run as loadstring(this)(builder_lib).
-- Pro athletics stadium at golden hour: 8-lane oval, stands all round with a big crowd, a giant
-- scoreboard, 4 floodlight towers (the only lights), and a dark players' tunnel into the bright bowl.
local L = ...
local P, W = L.Palette, L.W
local area = L.Areas.Stadium
local T = area.Track
local C = T.Center
local rng = L.rng
local block, cyl, ball, part = L.block, L.cyl, L.ball, L.part

local m, tmp = L.begin("Stadium")
local ground = L.folder("Ground", m, true)
local track = L.folder("Track", m, true)
local stands = L.folder("Stands", m, true)
local training = L.folder("Training", m, true)
local props = L.folder("Props", m, true)
local life = L.folder("Life", m, true)
local crowdF = L.folder("Crowd", life)
local flags = L.folder("Flags", life)

local outerR = T.InnerRadius + T.LaneWidth * T.Lanes -- 66
block(ground, "Base", Vector3.new(360, 4, 400), C + Vector3.new(0, -2, 20), Color3.fromHex("#8E97A8"))
block(ground, "Outskirts", Vector3.new(900, 4, 900), C + Vector3.new(0, -2.25, 0), Color3.fromHex("#4E9446"))
local infield = L.stadium(T, T.InnerRadius - 0.3, 0.12, 0, Color3.fromHex("#4FA34A"), tmp)
infield.Name = "Infield"
infield.Parent = ground
for i = 0, 9 do
	if i % 2 == 0 then
		block(ground, "InfieldStripe", Vector3.new(10, 0.04, (T.InnerRadius - 0.5) * 2), C + Vector3.new(-50 + i * 10 + 5, 0.14, 0), Color3.fromHex("#5DB357"), { CanCollide = false })
	end
end
L.ring(T, "OuterGrass", ground, outerR + 3.6, outerR + 12, 0.1, 0, Color3.fromHex("#4FA34A"), tmp)
L.paintTrack(T, track, tmp)
L.arch(track, T)

-- stands: straight stands along both sides (south has the tunnel gap) and curved ends (sections round the bends)
local seatLines = {}
local function section(cfToTrack)
	-- the bleacher mesh's front (rail) is its +Z side: turn so +Z points at the track
	local cf = cfToTrack * CFrame.Angles(0, math.pi, 0)
	local s = L.mesh("Bleacher_Section", stands, cf, { Offset = Vector3.new(0, 0, 0.75 - (L.meshTemplate("Bleacher_Section") and L.meshTemplate("Bleacher_Section").Size.Z or 18.75) / 2) })
	if not s then
		for k = 1, 6 do
			local h = 1 + 1.3 * k
			part({ Parent = stands, Name = "Step", Size = Vector3.new(20, h, 3), CFrame = cf * CFrame.new(0, h / 2, -1.5 - 3 * (k - 1)), Color = if k % 2 == 0 then P.Graphite else P.Carbon })
		end
	end
	for k = 1, 6, 2 do -- every other row has fans (the far crowd uses the light v1 fans)
		local h = 1 + 1.3 * k + 0.5
		local z = -1.5 - 3 * (k - 1) + 0.2
		table.insert(seatLines, { (cf * CFrame.new(-9.5, h, z)).Position, (cf * CFrame.new(9.5, h, z)).Position, cfToTrack.LookVector })
	end
end
local frontN = -(outerR + 14)
for i = 0, 9 do
	local x = C.X - 90 + i * 20
	section(CFrame.lookAt(Vector3.new(x, 0, C.Z + frontN), Vector3.new(x, 0, C.Z + frontN + 10)))
end
for i = 0, 9 do
	local x = C.X - 90 + i * 20
	if math.abs(x - C.X) > 20 then -- leave the tunnel gap in the middle
		section(CFrame.lookAt(Vector3.new(x, 0, C.Z - frontN), Vector3.new(x, 0, C.Z - frontN - 10)))
	end
end
for _, side in { -1, 1 } do
	local bendC = C + Vector3.new(side * T.Straight / 2, 0, 0)
	for k = -2, 2 do
		local a = k * math.rad(32)
		local dir = Vector3.new(side * math.cos(a), 0, math.sin(a))
		local pos = bendC + dir * (outerR + 14)
		section(CFrame.lookAt(pos, pos - dir))
	end
end
local fanCount = L.fans(crowdF, seatLines, 0.55, "MeshesV1_Backup")

-- giant scoreboard above the west end
local sbX = C.X - T.Straight / 2 - outerR - 40
local screen = block(props, "Scoreboard", Vector3.new(2, 22, 56), Vector3.new(sbX, 30, C.Z), P.SpeedBlack)
block(props, "ScoreboardGlow", Vector3.new(1.2, 23.2, 57.2), Vector3.new(sbX - 0.9, 30, C.Z), P.ElectricBlue, { Material = Enum.Material.Neon })
block(props, "ScoreboardGold", Vector3.new(2.4, 1, 57.6), Vector3.new(sbX, 41.8, C.Z), P.Gold)
for _, z in { -18, 18 } do
	block(props, "ScoreboardLeg", Vector3.new(2.4, 20, 2.4), Vector3.new(sbX - 1, 10, C.Z + z), P.Graphite)
end
L.surfaceText(screen, Enum.NormalId.Right, {
	{ Text = "BIG STADIUM", Height = 0.3, Color = P.Gold },
	{ Name = "RaceTimerText", Text = "NEXT RACE 3:00", Height = 0.35, Color = P.White },
	{ Text = "LEAGUE 3  -  HURDLES TODAY", Height = 0.14, Color = P.BrightBlue, Font = L.BODY },
}, { PPS = 10, Brightness = 2.4, MaxDistance = 600 })

-- floodlight towers: Neon heads + 4 SpotLights (no shadows), the only lights in this area
for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
	local base = C + Vector3.new(corner.X * (T.Straight / 2 + outerR + 18), 0, corner.Z * (outerR + 40))
	-- the Blender lattice mast (blender/areas_kit.py) when it's imported; its lamps face -Z (the track)
	local faceTrack = CFrame.lookAt(base, Vector3.new(C.X, base.Y, C.Z))
	local tower = L.mesh("Stadium_FloodTower", props, faceTrack, { Name = "FloodTower" })
	if not tower then
		cyl(props, "TowerPole", 1.4, 46, base + Vector3.new(0, 23, 0), P.Graphite)
	end
	local head = block(props, "FloodHead", Vector3.new(10, 5, 2), base + Vector3.new(0, 47, 0), P.SpeedBlack, { Transparency = if tower then 1 else 0 })
	head.CFrame = CFrame.lookAt(head.Position, C + Vector3.new(0, 0, 0)) * CFrame.Angles(math.rad(-20), 0, 0)
	local lamps = block(props, "FloodLamps", Vector3.new(9, 4, 0.3), head.Position, Color3.fromHex("#FFF4D6"), { Material = Enum.Material.Neon, CanCollide = false })
	lamps.CFrame = head.CFrame * CFrame.new(0, 0, -1.1)
	local spot = Instance.new("SpotLight")
	spot.Brightness = 2.2
	spot.Range = 60
	spot.Angle = 70
	spot.Shadows = false
	spot.Color = Color3.fromHex("#FFF1D6")
	spot.Face = Enum.NormalId.Front
	spot.Parent = lamps
end

-- the players' tunnel (south, through the gap in the stands): dark inside, bright bowl ahead
local tunnel = L.folder("Tunnel", props, true)
local tz0, tz1 = C.Z - frontN - 2, C.Z + 182
local tlen = tz1 - tz0
local tmid = (tz0 + tz1) / 2
block(tunnel, "Floor", Vector3.new(16, 0.4, tlen), Vector3.new(C.X, 0.2, tmid), P.Graphite)
for _, s in { -1, 1 } do
	block(tunnel, "Wall", Vector3.new(1.5, 11, tlen), Vector3.new(C.X + s * 8.6, 5.5, tmid), P.Carbon)
	block(tunnel, "EdgeGlow", Vector3.new(0.3, 0.2, tlen - 2), Vector3.new(C.X + s * 7.6, 0.45, tmid), P.ElectricBlue, { Material = Enum.Material.Neon, CanCollide = false })
end
block(tunnel, "Ceiling", Vector3.new(18.6, 1.2, tlen), Vector3.new(C.X, 11.4, tmid), P.SpeedBlack)
local mouth = block(tunnel, "MouthSign", Vector3.new(16, 3, 0.6), Vector3.new(C.X, 13.4, tz0), P.SpeedBlack)
L.surfaceText(mouth, Enum.NormalId.Back, { { Text = "PLAYERS' TUNNEL", Height = 0.8, Color = P.Gold } }, { PPS = 24, MaxDistance = 200 })
local inner = block(tunnel, "WelcomeSign", Vector3.new(14, 2.4, 0.4), Vector3.new(C.X, 9, tz0 + 20), P.SpeedBlack, { CanCollide = false })
L.surfaceText(inner, Enum.NormalId.Back, { { Text = "WELCOME TO THE BIG STADIUM", Height = 0.7, Color = P.White } }, { PPS = 24, MaxDistance = 120 })
L.gate(props, "BackToHub", CFrame.lookAt(Vector3.new(C.X, 0, tz1 - 2), Vector3.new(C.X, 0, tz1 - 30)), P.ElectricBlue, "BACK TO HUB", "HOMETOWN TRACK", "Hub")

-- training in the infield: Block Starts, Hurdles, Parachute Run, Bungee Sprint
local iz = C.Z
local bstart = L.folder("BlockStarts", training)
for i = 1, 3 do
	local z = iz + 14 + (i - 1) * 4
	block(bstart, "Lane", Vector3.new(20, 0.2, 3.6), Vector3.new(C.X - 30, 0.25, z), W.TrackBlue)
	if not L.mesh("Starting_Block", bstart, CFrame.new(C.X - 38.5, 0.35, z) * CFrame.Angles(0, math.pi / 2, 0), { Name = "Block" }) then
		block(bstart, "Block", Vector3.new(1.6, 0.7, 1.2), Vector3.new(C.X - 38.5, 0.7, z), P.SpeedBlack)
	end
	L.slot(bstart, "BlockStarts", CFrame.lookAt(Vector3.new(C.X - 36.5, 0.35, z), Vector3.new(C.X - 20, 0.35, z)), i)
end
L.sign(bstart, L.station("BlockStarts"), CFrame.lookAt(Vector3.new(C.X - 30, 0, iz + 27), Vector3.new(C.X - 30, 0, iz + 40)))
local hrow = L.folder("HurdlesRow", training)
block(hrow, "Lane", Vector3.new(22, 0.2, 8), Vector3.new(C.X + 4, 0.25, iz + 18), W.TrackBlue)
for i = 0, 3 do
	local x = C.X - 4 + i * 5
	block(hrow, "HurdleBar", Vector3.new(0.25, 0.35, 7), Vector3.new(x, 2.7, iz + 18), P.White)
	for _, s in { -1, 1 } do
		block(hrow, "HurdleLeg", Vector3.new(0.25, 2.6, 0.25), Vector3.new(x, 1.4, iz + 18 + s * 3.3), P.SpeedBlack)
	end
end
for i = 1, 2 do
	L.slot(hrow, "HurdlesRow", CFrame.lookAt(Vector3.new(C.X - 9, 0.35, iz + 16 + (i - 1) * 4), Vector3.new(C.X + 10, 0.35, iz + 16 + (i - 1) * 4)), i)
end
L.sign(hrow, L.station("HurdlesRow"), CFrame.lookAt(Vector3.new(C.X + 4, 0, iz + 27), Vector3.new(C.X + 4, 0, iz + 40)))
local para = L.folder("ParachuteRun", training)
block(para, "Lane", Vector3.new(24, 0.2, 8), Vector3.new(C.X - 20, 0.25, iz - 18), W.TrackBlue)
for i = 1, 2 do
	local z = iz - 20 + (i - 1) * 4
	L.slot(para, "ParachuteRun", CFrame.lookAt(Vector3.new(C.X - 26, 0.35, z), Vector3.new(C.X - 10, 0.35, z)), i)
	local chute = ball(para, "Chute", 6, Vector3.new(C.X - 32, 4, z), if i == 1 then P.Gold else P.ElectricBlue, { CanCollide = false })
	chute.Size = Vector3.new(3, 6, 6)
	for _, dz in { -1.8, 1.8 } do
		part({ Parent = para, Name = "Line", Size = Vector3.new(0.08, 0.08, 6.6), CFrame = CFrame.lookAt(Vector3.new(C.X - 30.4, 4, z + dz), Vector3.new(C.X - 26, 3.4, z)) * CFrame.new(0, 0, -3.3), Color = P.White, CanCollide = false })
	end
end
L.sign(para, L.station("ParachuteRun"), CFrame.lookAt(Vector3.new(C.X - 20, 0, iz - 9), Vector3.new(C.X - 20, 0, iz + 20)))
local bungee = L.folder("BungeeSprint", training)
for i = 1, 2 do
	local z = iz - 20 + (i - 1) * 4
	local px = C.X + 12
	block(bungee, "Pole", Vector3.new(0.6, 5, 0.6), Vector3.new(px, 2.5, z), P.Graphite)
	part({ Parent = bungee, Name = "Band", Size = Vector3.new(0.18, 0.18, 8), CFrame = CFrame.lookAt(Vector3.new(px, 3.6, z), Vector3.new(px + 8, 3.2, z)) * CFrame.new(0, 0, -4), Color = P.BrightBlue, Material = Enum.Material.Neon, CanCollide = false })
	L.slot(bungee, "BungeeSprint", CFrame.lookAt(Vector3.new(px + 8.5, 0.35, z), Vector3.new(px + 20, 0.35, z)), i)
end
block(bungee, "Lane", Vector3.new(18, 0.2, 8), Vector3.new(C.X + 20, 0.25, iz - 18), W.TrackBlue)
L.sign(bungee, L.station("BungeeSprint"), CFrame.lookAt(Vector3.new(C.X + 20, 0, iz - 9), Vector3.new(C.X + 20, 0, iz + 20)))

-- props: team tents, water coolers, a press box, a camera crane, flags of made-up nations
for i, x in { -40, 40 } do
	local tp = Vector3.new(C.X + x, 0, C.Z + outerR + 8)
	for _, dx in { -3, 3 } do
		for _, dz in { -2.5, 2.5 } do
			block(props, "TentLeg", Vector3.new(0.3, 7, 0.3), tp + Vector3.new(dx, 3.5, dz), W.Aluminium)
		end
	end
	block(props, "TentTop", Vector3.new(7, 0.5, 6), tp + Vector3.new(0, 7.2, 0), if i == 1 then P.ElectricBlue else P.Gold)
	cyl(props, "Cooler", 0.8, 1.6, tp + Vector3.new(0, 0.8, 0), P.ElectricBlue)
	cyl(props, "CoolerLid", 0.85, 0.3, tp + Vector3.new(0, 1.75, 0), P.White)
end
block(props, "PressBox", Vector3.new(30, 6, 8), Vector3.new(C.X, 13, C.Z + frontN - 22), P.Carbon)
block(props, "PressGlass", Vector3.new(28, 3, 0.3), Vector3.new(C.X, 13.5, C.Z + frontN - 17.9), W.Window, { Transparency = 0.3 })
local crane = Vector3.new(C.X + 60, 0, C.Z + outerR + 9)
block(props, "CraneBase", Vector3.new(4, 1, 4), crane + Vector3.new(0, 0.5, 0), P.Graphite)
cyl(props, "CraneMast", 0.5, 8, crane + Vector3.new(0, 5, 0), P.SpeedBlack)
local arm = block(props, "CraneArm", Vector3.new(0.6, 0.6, 16), crane + Vector3.new(0, 9, -6), P.SpeedBlack)
arm.CFrame = CFrame.lookAt(crane + Vector3.new(0, 9, 0), crane + Vector3.new(0, 11, -16)) * CFrame.new(0, 0, -8)
block(props, "Camera", Vector3.new(1.4, 1.2, 2), (arm.CFrame * CFrame.new(0, -0.6, -8)).Position, P.SpeedBlack)
local nations = { { "#1E7BFF", "#FFC83D" }, { "#FF4A4A", "#F4F6FA" }, { "#3FA34D", "#F4F6FA" }, { "#0E3A8A", "#FF4A4A" }, { "#FFC83D", "#0B0D12" }, { "#9B6BFF", "#F4F6FA" }, { "#4FC3FF", "#0E3A8A" }, { "#FF7A1F", "#3FA34D" } }
for i, n in nations do
	L.flag(flags, Vector3.new(C.X - 70 + (i - 1) * 20, 9.3, C.Z + frontN - 18.6), Color3.fromHex(n[1]), Color3.fromHex(n[2]), 7)
end
L.leaderboard(props, CFrame.lookAt(Vector3.new(C.X + 22, 0, C.Z - frontN - 6), Vector3.new(C.X + 22, 0, C.Z)), "STADIUM - FASTEST HERE")

-- the COACH AGENCY (28 Oct): inside the bowl by the tunnel, across from the leaderboard
L.agency(props, CFrame.lookAt(Vector3.new(C.X - 24, 0, C.Z - frontN - 8), Vector3.new(C.X - 24, 0, C.Z)))

local parts, lights = L.finish(m, tmp)
return ("Big Stadium built: %d parts, %d lights, %d fans"):format(parts, lights, fanCount)
