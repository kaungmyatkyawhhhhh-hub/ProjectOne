-- SPEED ARC: League 2 City Park Run (World note section 2). Run as loadstring(this)(builder_lib).
-- Bright morning park: a looping running path round a lake with a big fountain, a stone bridge the
-- race runs under, food carts, a gazebo, ducks, and a city skyline behind. 4 training stations.
local L = ...
local P, W = L.Palette, L.W
local area = L.Areas.Park
local T = area.Track
local C = T.Center
local rng = L.rng
local block, cyl, ball, part = L.block, L.cyl, L.ball, L.part

local m, tmp = L.begin("Park")
local ground = L.folder("Ground", m, true)
local track = L.folder("Track", m, true)
local training = L.folder("Training", m, true)
local props = L.folder("Props", m, true)
local life = L.folder("Life", m, true)
local crowd = L.folder("Crowd", life) -- the ducks bob like a crowd
local flags = L.folder("Flags", life)

-- ground, outskirts, path ring under the lanes
block(ground, "Grass", Vector3.new(330, 4, 340), C + Vector3.new(0, -2, 10), Color3.fromHex("#66B85A"))
block(ground, "Outskirts", Vector3.new(900, 4, 900), C + Vector3.new(0, -2.25, 0), Color3.fromHex("#55A24C"))
for i = 0, 15 do
	if i % 2 == 0 then
		block(ground, "Stripe", Vector3.new(10, 0.06, 320), C + Vector3.new(-160 + i * 20 + 5, 0.03, 0), Color3.fromHex("#5DAE52"), { CanCollide = false })
	end
end
local outerR = T.InnerRadius + T.LaneWidth * T.Lanes
L.ring(T, "PathEdge", ground, T.InnerRadius - 3, outerR + 5, 0.3, 0, Color3.fromHex("#C9CFD9"), tmp)

-- the lake inside the loop, a shore, and the fountain island (landmark)
local lake = L.stadium(T, T.InnerRadius - 8, 0.25, -0.05, Color3.fromHex("#3C8FD8"), tmp)
lake.Name = "Lake"
lake.Material = Enum.Material.SmoothPlastic
lake.Transparency = 0.12
lake.CanCollide = false
lake.Parent = ground
L.ring(T, "Shore", ground, T.InnerRadius - 8, T.InnerRadius - 3, 0.22, 0, Color3.fromHex("#E8D9A8"), tmp)
cyl(ground, "LakeBed", T.InnerRadius - 8, 0.2, C + Vector3.new(0, -0.6, 0), Color3.fromHex("#22507F"), { CanCollide = false })
local fountain = L.folder("Fountain", props, true)
cyl(fountain, "Island", 11, 0.8, C + Vector3.new(0, 0.2, 0), Color3.fromHex("#9DA6B5"))
cyl(fountain, "Basin", 8.5, 1.6, C + Vector3.new(0, 1.2, 0), Color3.fromHex("#E6E8EE"))
cyl(fountain, "BasinWater", 7.8, 1.7, C + Vector3.new(0, 1.25, 0), Color3.fromHex("#4FC3FF"), { Transparency = 0.25, CanCollide = false })
cyl(fountain, "Column", 1.6, 7, C + Vector3.new(0, 5, 0), Color3.fromHex("#E6E8EE"))
cyl(fountain, "Bowl", 4.2, 0.8, C + Vector3.new(0, 7.2, 0), Color3.fromHex("#E6E8EE"))
cyl(fountain, "BowlGold", 4.35, 0.25, C + Vector3.new(0, 7.65, 0), P.Gold)
cyl(fountain, "TopColumn", 0.8, 3, C + Vector3.new(0, 9.1, 0), Color3.fromHex("#E6E8EE"))
ball(fountain, "TopBall", 1.6, C + Vector3.new(0, 10.8, 0), P.Gold)
for i = 0, 5 do
	local a = i / 6 * math.pi * 2
	local jet = cyl(fountain, "Jet", 0.25, 5, C + Vector3.new(math.cos(a) * 5.5, 3.6, math.sin(a) * 5.5), P.BrightBlue, { Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false })
	jet.CFrame = CFrame.new(C + Vector3.new(math.cos(a) * 5.5, 3.6, math.sin(a) * 5.5)) * CFrame.Angles(math.cos(a) * 0.25, 0, math.pi / 2 + math.sin(a) * 0.25)
end
local spray = Instance.new("ParticleEmitter")
spray.Texture = "rbxasset://textures/particles/smoke_main.dds"
spray.Color = ColorSequence.new(Color3.fromHex("#DDF3FF"))
spray.Size = NumberSequence.new(0.8, 2.2)
spray.Transparency = NumberSequence.new(0.4, 1)
spray.Lifetime = NumberRange.new(0.8, 1.2)
spray.Rate = 14
spray.Speed = NumberRange.new(6, 9)
spray.SpreadAngle = Vector2.new(18, 18)
spray.Acceleration = Vector3.new(0, -12, 0)
spray.Parent = fountain:FindFirstChild("TopBall")

-- ducks (they bob with the "crowd")
for i = 1, 6 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(16, T.InnerRadius - 12)
	local pos = C + Vector3.new(math.cos(a) * r + (if i % 2 == 0 then 30 else -30), 0.3, math.sin(a) * r * 0.5)
	local duck = Instance.new("Model")
	duck.Name = "Duck"
	duck:SetAttribute("Phase", rng:NextNumber(0, 6))
	block(duck, "Body", Vector3.new(1.4, 0.8, 0.9), pos + Vector3.new(0, 0.4, 0), Color3.fromHex("#F4F6FA"), { CanCollide = false })
	ball(duck, "Head", 0.7, pos + Vector3.new(0.6, 1.0, 0), Color3.fromHex("#3FA34D"), { CanCollide = false })
	block(duck, "Beak", Vector3.new(0.35, 0.15, 0.3), pos + Vector3.new(1.0, 0.95, 0), P.Gold, { CanCollide = false })
	duck.Parent = crowd
end

-- the running path (blue lanes painted on it) + start/finish arch with countdown screens
L.paintTrack(T, track, tmp, { Color = Color3.fromHex("#2A6BD9") })
L.arch(track, T)

-- stone bridge over the back straight (the race runs under it)
local bridge = L.folder("Bridge", props, true)
local bx = C.X - 30
local zA, zB = -(T.InnerRadius - 6), -(outerR + 8)
local deckZ = (zA + zB) / 2
block(bridge, "Deck", Vector3.new(12, 1.4, math.abs(zB - zA) + 6), Vector3.new(bx, 10.5, deckZ), Color3.fromHex("#B9AE98"))
for _, s in { -1, 1 } do
	block(bridge, "Rail", Vector3.new(0.6, 1.6, math.abs(zB - zA) + 6), Vector3.new(bx + s * 5.7, 12, deckZ), Color3.fromHex("#9C917C"))
	for _, z in { zA, zB } do
		block(bridge, "Pier", Vector3.new(12, 10, 3), Vector3.new(bx, 5, z), Color3.fromHex("#A89D86"))
	end
end
part({ Class = "WedgePart", Parent = bridge, Name = "RampA", Size = Vector3.new(10, 10, 16), CFrame = CFrame.new(bx, 5, zA + 9.5) * CFrame.Angles(0, math.pi, 0), Color = Color3.fromHex("#B9AE98") })
part({ Class = "WedgePart", Parent = bridge, Name = "RampB", Size = Vector3.new(10, 10, 16), CFrame = CFrame.new(bx, 5, zB - 9.5), Color = Color3.fromHex("#B9AE98") })

-- skyline backdrop to the north (cheap far blocks with lit windows)
local skyline = L.folder("Skyline", props, true)
for i = 0, 22 do
	local x = C.X - 240 + i * 22 + rng:NextNumber(-4, 4)
	local h = rng:NextNumber(40, 120)
	local w = rng:NextNumber(14, 22)
	local col = ({ Color3.fromHex("#2A3550"), Color3.fromHex("#33415F"), Color3.fromHex("#1F2A42"), Color3.fromHex("#3A4A6E") })[i % 4 + 1]
	local z = -230 - rng:NextNumber(0, 40)
	block(skyline, "Tower", Vector3.new(w, h, 16), Vector3.new(x, h / 2, z), col, { CanCollide = false })
	for k = 1, math.floor(h / 18) do
		if rng:NextNumber() < 0.7 then
			block(skyline, "Windows", Vector3.new(w - 3, 1.2, 0.2), Vector3.new(x, k * 16, z + 8.1), Color3.fromHex("#FFE3A0"), { Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false })
		end
	end
end

-- food carts, gazebo, picnic blankets
local function cart(pos, color, label)
	local c = Instance.new("Model")
	c.Name = "FoodCart"
	c.Parent = props
	block(c, "Body", Vector3.new(6, 3, 3.4), pos + Vector3.new(0, 2.5, 0), color)
	block(c, "Counter", Vector3.new(6.4, 0.3, 3.8), pos + Vector3.new(0, 4.15, 0), P.White)
	for _, s in { -1, 1 } do
		cyl(c, "Wheel", 0.9, 0.4, pos + Vector3.new(s * 2, 0.9, 1.8), P.SpeedBlack).CFrame = CFrame.new(pos + Vector3.new(s * 2, 0.9, 1.8)) * CFrame.Angles(0, math.pi / 2, 0)
	end
	cyl(c, "UmbrellaPole", 0.15, 5, pos + Vector3.new(0, 6.5, 0), W.Aluminium)
	part({ Parent = c, Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 8, 8), CFrame = CFrame.new(pos + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = P.Gold })
	local sign = block(c, "Sign", Vector3.new(5, 1.4, 0.2), pos + Vector3.new(0, 3.2, -1.8), P.SpeedBlack)
	L.surfaceText(sign, Enum.NormalId.Front, { { Text = label, Height = 0.8, Color = P.White } }, { PPS = 30, MaxDistance = 80 })
end
cart(C + Vector3.new(-60, 0.3, 90), Color3.fromHex("#FF8FB1"), "ICE CREAM")
cart(C + Vector3.new(60, 0.3, 90), Color3.fromHex("#79C25C"), "SMOOTHIES")
local gz = Instance.new("Model")
gz.Name = "Gazebo"
gz.Parent = props
local gzp = C + Vector3.new(115, 0, 100)
cyl(gz, "Floor", 9, 0.8, gzp + Vector3.new(0, 0.4, 0), Color3.fromHex("#E6E8EE"))
for i = 0, 5 do
	local a = i / 6 * math.pi * 2
	cyl(gz, "Post", 0.4, 8, gzp + Vector3.new(math.cos(a) * 7.5, 4.6, math.sin(a) * 7.5), P.White)
end
cyl(gz, "Roof", 9.5, 1, gzp + Vector3.new(0, 9, 0), P.ElectricBlue)
cyl(gz, "RoofTop", 6, 1.2, gzp + Vector3.new(0, 10, 0), P.DeepBlue)
ball(gz, "Finial", 1.2, gzp + Vector3.new(0, 11, 0), P.Gold)
for i, pos in { C + Vector3.new(-100, 0.32, 70), C + Vector3.new(-80, 0.32, -90), C + Vector3.new(95, 0.32, -95) } do
	block(props, "Blanket", Vector3.new(7, 0.1, 5), pos, if i % 2 == 0 then Color3.fromHex("#FF4A4A") else P.ElectricBlue, { CanCollide = false })
	block(props, "BlanketCheck", Vector3.new(7, 0.12, 1), pos, P.White, { CanCollide = false })
	block(props, "BlanketCheck", Vector3.new(1, 0.12, 5), pos, P.White, { CanCollide = false })
end

-- trees, lamps and benches round the park
for i = 0, 27 do
	local a = i / 28 * math.pi * 2
	local pos = C + Vector3.new(math.cos(a) * 150 + rng:NextNumber(-6, 6), 0, math.sin(a) * 140 + 10 + rng:NextNumber(-6, 6))
	if pos.Z < C.Z + 120 or math.abs(pos.X - C.X) > 40 then
		L.tree(props, pos, rng:NextNumber(0.9, 1.3))
	end
end
for _, x in { -90, -30, 30, 90 } do
	L.mesh("Lamp_Post", props, CFrame.new(C.X + x, 0.3, C.Z + outerR + 9) * CFrame.Angles(0, math.pi, 0), { Offset = Vector3.new(0, 0, 0.6 - (L.meshTemplate("Lamp_Post") and L.meshTemplate("Lamp_Post").Size.Z or 2.98) / 2) })
	L.mesh("Bench", props, CFrame.new(C.X + x + 12, 0.3, C.Z + outerR + 10) * CFrame.Angles(0, math.pi, 0))
end
-- edges: railings and hedges show why the park ends
for _, z in { -165, 175 } do
	block(props, "Hedge", Vector3.new(330, 4, 4), C + Vector3.new(0, 2, z), W.TreeLeafDark)
end
for _, x in { -163, 163 } do
	block(props, "Hedge", Vector3.new(4, 4, 340), C + Vector3.new(x, 2, 5), W.TreeLeafDark)
	block(props, "Railing", Vector3.new(0.4, 0.4, 340), C + Vector3.new(x - math.sign(x) * 3, 3.2, 5), W.Aluminium)
end

-- training row south of the loop: Park Loop, Hill Sprint, Bench Step-Ups, Bike Drafting
local tz = C.Z + 100
-- Park Loop: a short path section with 3 lanes
local loop = L.folder("ParkLoop", training)
block(loop, "Strip", Vector3.new(26, 0.2, 12.4), Vector3.new(C.X - 28, 0.3, tz), Color3.fromHex("#2A6BD9"))
for i = 0, 3 do
	block(loop, "Line", Vector3.new(26, 0.22, 0.25), Vector3.new(C.X - 28, 0.32, tz - 6 + i * 4), W.LaneWhite)
end
for i = 1, 3 do
	L.slot(loop, "ParkLoop", CFrame.lookAt(Vector3.new(C.X - 36, 0.4, tz - 4 + (i - 1) * 4), Vector3.new(C.X - 20, 0.4, tz - 4 + (i - 1) * 4)), i)
end
L.sign(loop, L.station("ParkLoop"), CFrame.lookAt(Vector3.new(C.X - 28, 0, tz + 9), Vector3.new(C.X - 28, 0, tz + 30)))
-- Hill Sprint: a grassy hill with a rope line, runners face up the slope
local hill = L.folder("HillSprint", training)
local hp = Vector3.new(C.X - 85, 0, tz + 10)
ball(hill, "Hill", 36, hp + Vector3.new(0, -9, 0), Color3.fromHex("#5DAE52"))
local function surfaceY(dx)
	return -9 + math.sqrt(math.max(0, 18 * 18 - dx * dx)) -- top of the half-buried hill
end
local prev = nil
for i = 0, 4 do
	local dx = -13 + i * 3.2
	local top = Vector3.new(hp.X + dx, surfaceY(dx) + 2, hp.Z - 4)
	block(hill, "RopePost", Vector3.new(0.4, 2.2, 0.4), top - Vector3.new(0, 1, 0), W.Wood)
	if prev then
		part({ Parent = hill, Name = "Rope", Size = Vector3.new(0.15, 0.15, (top - prev).Magnitude), CFrame = CFrame.lookAt((top + prev) / 2, top), Color = P.Gold, CanCollide = false })
	end
	prev = top
end
for i = 1, 2 do
	local dx = -9 + (i - 1) * 4
	local x = hp.X + dx
	local y = surfaceY(dx) + 0.1
	L.slot(hill, "HillSprint", CFrame.lookAt(Vector3.new(x, y, hp.Z), Vector3.new(x + 10, y, hp.Z)), i)
end
L.sign(hill, L.station("HillSprint"), CFrame.lookAt(Vector3.new(hp.X, 0, hp.Z + 16), Vector3.new(hp.X, 0, hp.Z + 40)))
-- Bench Step-Ups: two park benches to step onto
local bs = L.folder("BenchStepUps", training)
for i = 1, 2 do
	local x = C.X + 18 + (i - 1) * 9
	local b = L.mesh("Bench", bs, CFrame.new(x, 0.3, tz - 2) * CFrame.Angles(0, math.pi, 0))
	if not b then
		block(bs, "Bench", Vector3.new(6, 1.6, 1.6), Vector3.new(x, 1.1, tz - 2), W.Wood)
	end
	L.slot(bs, "BenchStepUps", CFrame.lookAt(Vector3.new(x, 0.4, tz + 1.5), Vector3.new(x, 0.4, tz - 10)), i)
end
L.sign(bs, L.station("BenchStepUps"), CFrame.lookAt(Vector3.new(C.X + 22, 0, tz + 9), Vector3.new(C.X + 22, 0, tz + 30)))
-- Bike Drafting: a bike lane with a pacer bike, runners tuck in behind it
local bike = L.folder("BikeDrafting", training)
block(bike, "BikeLane", Vector3.new(28, 0.2, 6), Vector3.new(C.X + 70, 0.3, tz), Color3.fromHex("#3FA34D"))
block(bike, "LaneLine", Vector3.new(28, 0.22, 0.3), Vector3.new(C.X + 70, 0.32, tz - 3), W.LaneWhite)
local bp = Vector3.new(C.X + 80, 0.3, tz)
for _, s in { -1, 1 } do
	cyl(bike, "Wheel", 1.3, 0.25, bp + Vector3.new(s * 2, 1.3, 0), P.SpeedBlack).CFrame = CFrame.new(bp + Vector3.new(s * 2, 1.3, 0)) * CFrame.Angles(0, math.pi / 2, 0)
end
block(bike, "Frame", Vector3.new(4.2, 0.3, 0.3), bp + Vector3.new(0, 2.2, 0), P.ElectricBlue)
block(bike, "Seat", Vector3.new(1, 0.3, 0.6), bp + Vector3.new(-1, 3.2, 0), P.SpeedBlack)
block(bike, "Bars", Vector3.new(0.3, 1.2, 1.6), bp + Vector3.new(1.8, 3.1, 0), W.Aluminium)
for i = 1, 2 do
	L.slot(bike, "BikeDrafting", CFrame.lookAt(Vector3.new(bp.X - 6 - (i - 1) * 4, 0.4, tz), Vector3.new(bp.X + 10, 0.4, tz)), i)
end
L.sign(bike, L.station("BikeDrafting"), CFrame.lookAt(Vector3.new(C.X + 70, 0, tz + 9), Vector3.new(C.X + 70, 0, tz + 30)))

-- spawn plaza, BACK TO HUB gate, leaderboard, flags
block(ground, "Plaza", Vector3.new(60, 0.3, 30), Vector3.new(C.X, 0.15, C.Z + 132), Color3.fromHex("#B8BFCB"))
L.gate(props, "BackToHub", CFrame.lookAt(Vector3.new(C.X + 34, 0, C.Z + 140), Vector3.new(C.X + 34, 0, C.Z + 120)), P.ElectricBlue, "BACK TO HUB", "HOMETOWN TRACK", "Hub")
L.leaderboard(props, CFrame.lookAt(Vector3.new(C.X - 34, 0, C.Z + 140), Vector3.new(C.X - 34, 0, C.Z + 120)), "CITY PARK - FASTEST HERE")
for i, x in { -20, 20 } do
	L.flag(flags, Vector3.new(C.X + x, 0, C.Z + 146), if i == 1 then P.ElectricBlue else Color3.fromHex("#3FA34D"), P.Gold, 9)
end

local parts, lights = L.finish(m, tmp)
return ("City Park built: %d parts, %d lights"):format(parts, lights)
