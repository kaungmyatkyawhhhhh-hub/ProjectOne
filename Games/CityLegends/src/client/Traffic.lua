--[[
	Traffic (client)
	Smart NPC traffic simulated locally on every client for buttery-smooth motion.
	Each car:
	  * follows the lane graph (lanes + bezier turns through intersections)
	  * stops on red, decides whether it can stop on yellow, resumes on green
	    (lights are computed from synced server time so all clients agree)
	  * keeps a safe following distance to NPCs *and* player cars, brakes hard
	    when you cut in front of it, shows brake lights
	  * slows for turns, and un-sticks itself if it ever gets gridlocked
	Far-away cars are recycled to just out of sight around the player so the
	streets near you always feel busy.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local RivieraTraffic = require(Shared:WaitForChild("RivieraTraffic"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local TrafficBodies = require(script.Parent:WaitForChild("TrafficBodies"))
local TrafficMix = require(Shared:WaitForChild("TrafficMix"))
local ChauffeurRoute = require(Shared:WaitForChild("ChauffeurRoute"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local LowEnd = require(script.Parent:WaitForChild("LowEnd"))
local TrafficSounds = require(script.Parent:WaitForChild("TrafficSounds"))
local RACER = TrafficMix.Racer
local RACE = TrafficMix.Race
local besideOf: (any) -> { any }?

local T = Config.Traffic
local TURN_SPEED = Config.mphToSps(T.TurnSpeedMph)
local BRAKE_ON = Color3.fromRGB(255, 25, 25)
local BRAKE_OFF = Color3.fromRGB(150, 0, 6)

export type Npc = {
	model: Model,
	root: BasePart,
	seg: CityLayout.Segment,
	nextSeg: CityLayout.Segment?,
	s: number,
	speed: number,
	maxSpeed: number,
	halfLen: number,
	width: number,
	height: number,
	pos: Vector3,
	fwd: Vector3,
	stuck: number,
	ghost: number,
	braking: boolean,
	wanderPhase: number, -- the speed drift (Config.Traffic.Wander)
	wanderRate: number,
	tails: { BasePart },
	wheels: { Motor6D },
	spin: number,
	highway: boolean, -- a highway car: spawns and comes back on the highways, with wider gaps
	deadEnd: boolean?, -- stopped at the end of a lane with no way on: recycled next
	-- (2026-11-19) profile "racer": the rare supercars (TrafficMix); top speed in studs/s, nil for everyday cars
	racer: number?,
	off: number, -- sideways offset from the lane's middle (+ = right): lane changes and splits in progress
	offTo: number,
	sideT: number, -- time to the next overtaking look
	offFrom: number?, -- where the slide under way began (it eases back there if its target strip fills)
	plan: { CityLayout.Segment }?, -- the way chosen past nextSeg (racers brake for bends far ahead)
	holdMerge: boolean?, -- a racer waiting to merge back before a junction
	-- (2026-11-21) a race of rare cars that met (TrafficMix.Race): its number, and the way its cars share (piece ->
	-- the piece taken after it)
	race: number?,
	way: { [any]: any }?,
	-- (2026-11-21) two racers that saw each other: the faster one's chase (the car it goes after, the time left, the
	-- time left to look for a U-turn, the U-turn under way), the other's chaser, and when either may chase again
	chase: any?,
	chaseT: number?,
	wantU: number?,
	uturn: any?,
	chasedBy: any?,
	noRace: number?,
	-- (27 Nov, owner: "the cars rn are unnatural") the look of a real car: acc = the pull / braking now (studs/s^2,
	-- eased by Config.Traffic.Jerk), the body's roll / pitch springs on BodyTilt, the front wheels' steer, the last
	-- heading drawn (its change = the yaw rate), a racer's lane move (lc: an S-curve) and the time a car has been held
	-- by the no-overlap check
	acc: number,
	body: Motor6D?,
	fronts: { [Motor6D]: boolean },
	wheelR: number,
	held: number,
}

type Obstacle = { pos: Vector3, fwd: Vector3, speed: number, halfLen: number, width: number, self: Npc?, ped: boolean? }

local Traffic = {}
local bumpAhead: (Npc) -> boolean
Traffic.cars = {} :: { Npc }
-- (27 Nov, owner: people cross on the lights) street people on the road, filled every frame by YangonStreetLife:
-- cars stop for them like for a stopped car (never the gridlock breaker, racers don't weave round them)
Traffic.peds = {} :: { Obstacle }

local rng = Random.new()
local graph = CityLayout.buildGraph()
local folder: Folder? = nil
local running = false
local recycleTimer = 0
local focusGetter: (() -> Vector3?)? = nil

-- (the gated community's lanes are private: traffic never turns in; graph_test checks there is
-- always a public way on)
local function isPrivate(s: CityLayout.Segment): boolean
	return s.private == true or (s.kind == "turn" and s.next[1] ~= nil and s.next[1].private == true)
end

-- Legends Isle's mountain roads (the climbs and the mid ring): only a few cars at a time
-- (owner, 2026-10-30: "reduce traffic on the mountain"; Config.Traffic.Mountain*)
local mountainCars = 0
-- the Riviera Highway (2026-11-04): at most Config.Traffic.RivieraHighwayMax cars on it
local rivHighwayCars = 0
local HIGHWAY_SPEED = Config.mphToSps(T.RivieraHighwayMph)
-- the busy stretches: Config.Traffic.BusyZones
local zoneCars: { number } = {}
for i in T.BusyZones do
	zoneCars[i] = 0
end
local function zoneOf(p: Vector3): number?
	for i, z in T.BusyZones do
		local dx, dz = p.X - z.at.X, p.Z - z.at.Z
		if dx * dx + dz * dz <= z.radius * z.radius then
			return i
		end
	end
	return nil
end
local function isRivHighway(s: CityLayout.Segment): boolean
	return (s :: any).rivHighway == true or (s.kind == "turn" and s.next[1] ~= nil and (s.next[1] :: any).rivHighway == true)
end
local function isMountain(s: CityLayout.Segment): boolean
	return s.mountain == true or (s.kind == "turn" and s.next[1] ~= nil and s.next[1].mountain == true)
end
local publicNext: { [CityLayout.Segment]: { CityLayout.Segment } } = {}

-- the angle (degrees) between the way into a junction and the way out through option o
local angleCache: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local function turnAngle(from: CityLayout.Segment, o: CityLayout.Segment): number
	if o.kind ~= "turn" then
		return 0
	end
	local a = angleCache[o]
	if a == nil then
		local after = o.next[1]
		local fin = (from.p2 - from.p0) * Vector3.new(1, 0, 1)
		local fout = if after then (after.p2 - after.p0) * Vector3.new(1, 0, 1) else (o.p2 - o.p1) * Vector3.new(1, 0, 1)
		a = if fin.Magnitude > 0.1 and fout.Magnitude > 0.1 then math.deg(math.acos(math.clamp(fin.Unit:Dot(fout.Unit), -1, 1))) else 0
		angleCache[o] = a
	end
	return a :: number
end

local function chooseNext(seg: CityLayout.Segment): CityLayout.Segment?
	local options = publicNext[seg]
	if not options then
		options = {}
		for _, o in seg.next do
			if seg.private or not isPrivate(o) then
				table.insert(options, o)
			end
		end
		publicNext[seg] = options
	end
	if #options == 0 then
		return nil
	end
	if seg.kind == "turn" then
		return options[1]
	end
	-- (owner, 2026-11-03: "some traffic cars would do a unnecessary U turn or J turn just to turn
	-- right or left"): a turn that doubles back (more than 135 degrees between the way in and the way
	-- out) is only taken where there is no other way on (a dead end)
	local hasOther = false
	for _, o in options do
		if turnAngle(seg, o) <= 135 then
			hasOther = true
			break
		end
	end
	-- prefer going straight (weight 3) over turning (weight 1); onto the mountain seldom, and not
	-- at all while it already has its few cars
	local function weight(o: CityLayout.Segment): number
		local w = if o.dir == seg.dir then 3 else 1
		-- (cars stay on the yellow routes: seldom off them onto a street, back onto them gladly)
		if (seg :: any).riviera then
			local fromRoute, toRoute = (seg :: any).route == true, (o :: any).route == true
			if fromRoute and not toRoute then
				local dest = if o.kind == "turn" and o.next[1] then o.next[1] else o
				w *= T.SplitTurnK[(dest :: any).road] or T.LeaveRouteK
			elseif not fromRoute and toRoute then
				w *= 4
			end
		end
		local ang = turnAngle(seg, o)
		if ang > 135 and hasOther then
			return 0
		elseif ang > 110 then
			w *= 0.3 -- sharp turns back up a hill: seldom
		end
		if not seg.mountain and isMountain(o) then
			w *= if mountainCars >= T.MountainMax then 0 else T.MountainTurnK
		end
		if not (seg :: any).rivHighway and isRivHighway(o) and rivHighwayCars >= (T.RivieraHighwayMax or 10) then
			w = 0
		end
		return w
	end
	local total = 0
	for _, o in options do
		total += weight(o)
	end
	if total <= 0 then
		return options[rng:NextInteger(1, #options)]
	end
	local r = rng:NextNumber() * total
	for _, o in options do
		r -= weight(o)
		if r <= 0 then
			return o
		end
	end
	return options[#options]
end

local function placeNpc(npc: Npc, seg: CityLayout.Segment, s: number)
	npc.seg = seg
	npc.s = s
	npc.nextSeg = chooseNext(seg)
	npc.stuck = 0
	npc.ghost = 0
	npc.deadEnd = nil
	npc.off = 0
	npc.offTo = 0
	npc.plan = nil
	npc.uturn = nil;
	(npc :: any).prevSeg = nil
	npc.acc = 0
	npc.held = 0
	local u = npc :: any
	u.lc, u.offV, u.offA, u.lastLook = nil, 0, 0, nil
	local pos, fwd = CityLayout.sample(seg, s)
	npc.pos = pos
	npc.fwd = fwd
end

local function isFree(pos: Vector3, radius: number, ignore: Npc?): boolean
	for _, other in Traffic.cars do
		if other ~= ignore and (other.pos - pos).Magnitude < radius then
			return false
		end
	end
	for _, car in Traffic.playerCars() do
		if (car.pos - pos).Magnitude < radius + 10 then
			return false
		end
	end
	return true
end

-- each lane's bounding box (its three control points), to pick lanes near a point quickly: the
-- highway lanes are few but very long, so a plain random pick rarely lands near a driver out there
-- (city cars and highway cars keep to their own lanes when placed: fewer cars in the city's
-- streets, and well spaced cars on the highways to split and race past; owner, 2026-10-29)
local laneBox: { [CityLayout.Segment]: { Vector3 } } = {}
local cityLanes: { CityLayout.Segment } = {}
local highwayLanes: { CityLayout.Segment } = {}
for _, seg in graph.lanes do
	laneBox[seg] = { seg.p0:Min(seg.p1):Min(seg.p2), seg.p0:Max(seg.p1):Max(seg.p2) }
	if not seg.private then
		table.insert(if seg.speedK >= Config.City.HighwaySpeedK - 0.01 then highwayLanes else cityLanes, seg)
	end
end
-- the Riviera's lanes (the new map), when it is in the place: city lanes, but only a few cars
-- there at once (owner, 2026-11-02: "traffic on the new map (reduce traffic)"; Config.Traffic.RivieraMax)
-- (Monaco only: nothing on the old city's lanes)
if Config.monacoOnly() then
	table.clear(cityLanes)
	table.clear(highwayLanes)
end
-- (2026-11-13: the Yangon map's lanes come in the same graph, so either map in the place turns it on)
-- (2026-11-16: or the 1:1 Yangon frame, Workspace.Yangon1to1; its lanes are marked oneToOne)
if workspace:FindFirstChild("Riviera") or Config.mapRoot() then
	local riv = RivieraTraffic.build()
	if riv then
		for _, seg in riv.lanes do
			laneBox[seg] = { seg.p0:Min(seg.p1):Min(seg.p2), seg.p0:Max(seg.p1):Max(seg.p2) }
			if Config.isYangon1to1At(seg.p0) then
				(seg :: any).oneToOne = true
			end
			table.insert(cityLanes, seg)
		end
	end
end
local rivieraCars = 0
local nearby: { CityLayout.Segment } = {}
-- (2026-11-19, owner: "lag spikes", mostly on the small roads) the 1:1 lanes are 92k segments: one full scan was ~20 ms,
-- and on a street with no lane near, the recycler's findSpot failed for every car (~28 scans, ~500 ms in one frame,
-- twice a second). Segments are kept in a 512-stud grid; the same box test, only on the cells round the point.
local GRID = 512
local laneGrids: { [any]: { n: number, cells: { [number]: { CityLayout.Segment } } } } = {}
local seen: { [any]: number } = {}
local stamp = 0
local function gridOf(lanes: { CityLayout.Segment })
	local g = laneGrids[lanes]
	if g and g.n == #lanes then
		return g
	end
	g = { n = #lanes, cells = {} }
	for _, seg in lanes do
		local b = laneBox[seg]
		for cx = math.floor(b[1].X / GRID), math.floor(b[2].X / GRID) do
			for cz = math.floor(b[1].Z / GRID), math.floor(b[2].Z / GRID) do
				local k = cx * 100003 + cz
				local cell = g.cells[k]
				if not cell then
					cell = {}
					g.cells[k] = cell
				end
				table.insert(cell, seg)
			end
		end
	end
	laneGrids[lanes] = g
	return g
end
local function lanesNear(lanes: { CityLayout.Segment }, center: Vector3, maxDist: number): { CityLayout.Segment }
	table.clear(nearby)
	local g = gridOf(lanes)
	stamp += 1
	for cx = math.floor((center.X - maxDist) / GRID), math.floor((center.X + maxDist) / GRID) do
		for cz = math.floor((center.Z - maxDist) / GRID), math.floor((center.Z + maxDist) / GRID) do
			local cell = g.cells[cx * 100003 + cz]
			if cell then
				for _, seg in cell do
					if seen[seg] ~= stamp then
						seen[seg] = stamp
						local b = laneBox[seg]
						local dx = math.max(b[1].X - center.X, 0, center.X - b[2].X)
						local dz = math.max(b[1].Z - center.Z, 0, center.Z - b[2].Z)
						if dx * dx + dz * dz <= maxDist * maxDist then
							table.insert(nearby, seg)
						end
					end
				end
			end
		end
	end
	return nearby
end

-- (2026-11-16) "anywhere" means anywhere in the player's own area: the 1:1 Yangon frame or the rest (the maps lie
-- tens of thousands of studs apart, so a car placed in the other one would only be recycled later)
local areaPools: { [any]: { [boolean]: { CityLayout.Segment } } } = {}
local function areaPool(lanes: { CityLayout.Segment }): { CityLayout.Segment }
	local focus = if focusGetter then focusGetter() else nil
	if not focus then
		return lanes
	end
	local want = Config.isYangon1to1At(focus)
	local byArea = areaPools[lanes]
	if not byArea or byArea.n ~= #lanes then
		byArea = { n = #lanes } :: any
		areaPools[lanes] = byArea
	end
	local pool = byArea[want]
	if not pool then
		pool = {}
		for _, seg in lanes do
			if ((seg :: any).oneToOne == true) == want then
				table.insert(pool, seg)
			end
		end
		byArea[want] = pool
	end
	return if #pool > 0 then pool else lanes
end

-- Lane position near "center" (or anywhere in the player's area if center == nil)
local function findSpot(center: Vector3?, minDist: number, maxDist: number, ignore: Npc?, avoidView: boolean?, highway: boolean?): (CityLayout.Segment?, number)
	local camera = workspace.CurrentCamera
	local lanes = if highway then highwayLanes else cityLanes
	local pool = if center and maxDist < 5000 then lanesNear(lanes, center, maxDist) else areaPool(lanes)
	-- (21 Nov, owner: a 1-car gap between cars; was 22) (27 Nov: 40, two buses' half lengths and a margin: a bus placed
	-- 30 from another's middle sat inside it)
	local gap = if highway then T.HighwayGap else 40
	if #pool == 0 then
		return nil, 0
	end
	for _ = 1, 40 do
		local seg = pool[rng:NextInteger(1, #pool)]
		if seg.mountain and (mountainCars >= T.MountainMax or rng:NextNumber() > T.MountainShare) then
			continue
		end
		if (seg :: any).riviera and rivieraCars >= T.RivieraMax then
			continue
		end
		-- (a car that is moved doesn't count against itself: with the highway full of cars far away, none
		-- could be brought to a player up there, and the road round you stayed empty)
		local own = if ignore and (ignore.seg :: any).rivHighway then 1 else 0
		if (seg :: any).rivHighway and rivHighwayCars - own >= (T.RivieraHighwayMax or 10) then
			continue
		end
		-- (owner, 2026-11-03: "only make it so that there is traffic on the yellow roads ... remove the
		-- cars on the roads which isn't yellow"): the three long routes get the traffic, the other
		-- streets only a rare car
		if (seg :: any).riviera and not (seg :: any).route and rng:NextNumber() > (T.StreetShareBy[(seg :: any).road] or T.StreetShare) then
			continue
		end
		local s = rng:NextNumber(8, math.max(9, seg.length - 25))
		local pos = CityLayout.sample(seg, s)
		local ok = true
		if center then
			local d = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude
			ok = d >= minDist and d <= maxDist
			if ok and avoidView and camera then
				local toPos = (pos - camera.CFrame.Position).Unit
				if toPos:Dot(camera.CFrame.LookVector) > 0.55 and d < 380 then
					ok = false
				end
			end
		end
		local zone = if ok then zoneOf(pos) else nil
		if zone and zoneCars[zone] - (if ignore and zoneOf(ignore.pos) == zone then 1 else 0) >= T.BusyZones[zone].max then
			ok = false
		end
		if ok and isFree(pos, if (seg :: any).rivHighway then T.HighwayGap else gap, ignore) then
			if zone then
				zoneCars[zone] += 1
			end
			if seg.mountain then
				mountainCars += 1 -- (counted again each frame; this covers several placed at once)
			end
			if (seg :: any).riviera then
				rivieraCars += 1
			end
			if (seg :: any).rivHighway then
				rivHighwayCars += 1
			end
			return seg, s
		end
	end
	return nil, 0
end

local function setBrake(npc: Npc, on: boolean)
	if npc.braking == on then
		return
	end
	npc.braking = on
	for _, t in npc.tails do
		t.Color = if on then BRAKE_ON else BRAKE_OFF
	end
end

-- parallel lanes (same road and way, a lane apart: ChauffeurRoute's table, built once in the background)
local besideMap: { [any]: { CityLayout.Segment } }? = nil
task.spawn(function()
	local ok, g = pcall(ChauffeurRoute.graph)
	if ok and g then
		besideMap = g.lanesBeside
	end
end)
besideOf = function(seg: CityLayout.Segment): { CityLayout.Segment }?
	return if besideMap then besideMap[seg] else nil
end

-- live rare supercars per cap group (TrafficMix.Rare)
function Traffic.rareCounts(): { [string]: number }
	local counts = {}
	for _, npc in Traffic.cars do
		local g = npc.model:GetAttribute("RareTraffic")
		if type(g) == "string" then
			counts[g] = (counts[g] or 0) + 1
		end
	end
	return counts
end

local function spawnNpc(center: Vector3?, highway: boolean): Npc?
	local seg, s = findSpot(center, 0, if center then 700 else math.huge, nil, false, highway)
	if not seg and center then
		seg, s = findSpot(nil, 0, math.huge, nil, false, highway) -- none near: anywhere on its roads
	end
	if not seg then
		return nil
	end
	-- the imported low-poly traffic cars when the place has them, else our own built ones
	-- (2026-11-19: the Yangon mix, rare supercars under their caps, buses on main roads only)
	local model = TrafficBodies.build(rng, Traffic.rareCounts(), besideMap == nil or besideOf(seg) ~= nil)
	if not model then
		local spec = CarBuilder.randomTrafficSpec(rng)
		local color = Cars.TrafficColors[rng:NextInteger(1, #Cars.TrafficColors)]
		model = CarBuilder.build(spec, { anchored = true, driver = true, simpleWheels = true, lite = true, color = color })
		CarSkin.apply(model :: Model, true, true)
	end
	assert(model)
	local tails = {}
	local wheels: { Motor6D } = {}
	local fronts: { [Motor6D]: boolean } = {}
	for _, j in (model.PrimaryPart :: BasePart):GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
			if j.Name:sub(7, 7) == "F" then
				fronts[j] = true
			end
		end
	end
	-- no lights on traffic cars (owner, 2026-11-02: "you can remove car lights for traffic cars"):
	-- their brake lamps stay plain painted lamps, never glowing
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("TailLight") then
			d.Material = Enum.Material.SmoothPlastic
			d.Color = BRAKE_OFF
		elseif d:IsA("Light") then
			d:Destroy()
		end
	end
	local npc: Npc = {
		model = model,
		root = model.PrimaryPart :: BasePart,
		seg = seg,
		nextSeg = nil,
		s = s,
		speed = 0,
		maxSpeed = Config.mphToSps(rng:NextNumber(T.MinSpeedMph, T.MaxSpeedMph)),
		halfLen = (model:GetAttribute("Length") :: number) / 2,
		width = model:GetAttribute("Width") :: number,
		height = model:GetAttribute("Height") :: number,
		pos = Vector3.zero,
		fwd = Vector3.zAxis,
		stuck = 0,
		ghost = 0,
		braking = false,
		wanderPhase = rng:NextNumber(0, math.pi * 2),
		wanderRate = math.pi * 2 / rng:NextNumber(T.WanderPeriod[1], T.WanderPeriod[2]),
		tails = tails,
		wheels = wheels,
		spin = 0,
		highway = highway,
		off = 0,
		offTo = 0,
		sideT = 0,
		acc = 0,
		body = (model.PrimaryPart :: BasePart):FindFirstChild("BodyTilt") :: Motor6D?,
		fronts = fronts,
		wheelR = (model:GetAttribute("WheelR") :: number?) or 1.1,
		held = 0,
	}
	local racerMph = model:GetAttribute("RacerMph")
	if type(racerMph) == "number" then
		npc.racer = Config.mphToSps(racerMph)
		npc.maxSpeed = npc.racer :: number
	end
	-- (owner, 2026-11-21: "sometimes the ybs and taxis need to be fast") some buses and Probox taxis hurry: a higher
	-- top speed only, everything else (gaps, lights, turns) as everyday traffic
	local hurry = TrafficMix.Hurry
	if not npc.racer and hurry.ids[model:GetAttribute("TrafficId") :: string] and rng:NextNumber() < hurry.chance then
		npc.maxSpeed = Config.mphToSps(rng:NextNumber(hurry.mph[1], hurry.mph[2]))
	end
	placeNpc(npc, seg, s)
	npc.speed = npc.maxSpeed * 0.7
	model:PivotTo(CFrame.lookAt(npc.pos, npc.pos + npc.fwd) + Vector3.new(0, npc.height / 2, 0))
	model.Parent = folder
	table.insert(Traffic.cars, npc)
	return npc
end

-- Player cars as obstacles (replicated models in workspace.PlayerCars)
local playerCarCache: { Obstacle } = {}
function Traffic.playerCars(): { Obstacle }
	return playerCarCache
end

local function refreshPlayerCars()
	table.clear(playerCarCache)
	-- (and the chauffeur service's cars: traffic yields to them too)
	local list = {}
	for _, name in { "PlayerCars", "Chauffeurs" } do
		local f = workspace:FindFirstChild(name)
		if f then
			for _, m in f:GetChildren() do
				table.insert(list, m)
			end
		end
	end
	for _, model in list do
		if model:IsA("Model") and model.PrimaryPart then
			local root = model.PrimaryPart
			local v = root.AssemblyLinearVelocity
			local flatV = Vector3.new(v.X, 0, v.Z)
			local look = root.CFrame.LookVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			-- (at its real height, like the traffic cars' own positions: flattened to y 0 it was
			-- hundreds of studs below a mountain road's cars, so out there traffic didn't wait for
			-- players at junctions and could be placed on top of them; 2026-11-04)
			table.insert(playerCarCache, {
				pos = root.Position,
				fwd = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.zAxis,
				speed = flatV.Magnitude,
				halfLen = ((model:GetAttribute("Length") :: number?) or 14) / 2,
				width = (model:GetAttribute("Width") :: number?) or 6,
			})
		end
	end
	-- (2026-11-07) trailers: parked or towed, traffic waits for them or goes round. Anchored, so their
	-- speed comes from TrailerClient
	local trailers = workspace:FindFirstChild("Trailers")
	if trailers then
		for _, model in trailers:GetChildren() do
			local root = if model:IsA("Model") then model.PrimaryPart else nil
			if root then
				local look = root.CFrame.LookVector
				local flatLook = Vector3.new(look.X, 0, look.Z)
				local fwd = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.zAxis
				local T = Config.Towing.Trailer
				table.insert(playerCarCache, {
					pos = root.Position + fwd * ((T.AxleToHitch - T.DeckBack) / 2),
					fwd = fwd,
					speed = (model:GetAttribute("LiveSpeed") :: number?) or 0,
					halfLen = ((model:GetAttribute("Length") :: number?) or 22) / 2,
					width = (model:GetAttribute("Width") :: number?) or 8,
				})
			end
		end
	end
end

-- (owner, 2026-11-21: "add a function to disable traffic") Settings > Traffic OFF sets player attribute TrafficOff:
-- the cars go at once and come back (same count and focus as the start) when it is switched on again
local startArgs: { any }? = nil
local watching = false
local function watchToggle()
	if watching then
		return
	end
	watching = true
	local plr = game:GetService("Players").LocalPlayer
	plr:GetAttributeChangedSignal("TrafficOff"):Connect(function()
		if plr:GetAttribute("TrafficOff") then
			Traffic.stop()
		elseif startArgs and not running then
			task.spawn(Traffic.start, startArgs[1], startArgs[2])
		end
	end)
end

function Traffic.start(count: number?, focus: (() -> Vector3?)?)
	startArgs = { count, focus }
	watchToggle()
	if running or game:GetService("Players").LocalPlayer:GetAttribute("TrafficOff") then
		return
	end
	running = true
	focusGetter = focus
	local f = Instance.new("Folder")
	f.Name = "Traffic"
	f.Parent = workspace
	folder = f
	refreshPlayerCars()
	local center = if focus then focus() else nil
	local total = count or T.CarCount
	-- the highways get their share at the same quality scale
	local highway = if Config.monacoOnly() then 0 else math.floor(T.HighwayCars * total / T.CarCount + 0.5)
	for k = 1, total + highway do
		-- most cars around the player, some spread through the city; then the highway cars
		local onHighway = k > total
		spawnNpc(if k % 4 ~= 0 then center else nil, onHighway)
		if k % 10 == 0 then
			task.wait()
		end
	end
end

-- fewer cars once a phone is found to be low-end after the start: the farthest go first (same removal as a far racer)
-- shortcut: never adds cars back if the phone leaves low-end; add a grow step if players ask
function Traffic.trim(count: number)
	local keep = count + (if Config.monacoOnly() then 0 else math.floor(T.HighwayCars * count / T.CarCount + 0.5))
	while #Traffic.cars > keep do
		local far, fd = 1, -1
		for i, npc in Traffic.cars do
			local d = (npc :: any).camDist or 0
			if d > fd then
				far, fd = i, d
			end
		end
		local npc = Traffic.cars[far]
		Traffic.cars[far] = Traffic.cars[#Traffic.cars]
		table.remove(Traffic.cars)
		npc.model:Destroy()
	end
end

function Traffic.stop()
	running = false
	for _, npc in Traffic.cars do
		npc.model:Destroy()
	end
	table.clear(Traffic.cars)
	if folder then
		folder:Destroy()
		folder = nil
	end
end

-- (27 Nov) `path` = the pieces ahead on this car's way -> where each starts, measured from the car's middle (Traffic.update
-- fills it): a car on one of them is followed by its distance along the lanes, round any bend (a straight look missed a car
-- ahead in a curve and drove into it), and one in the lane beside is never taken for ours
local function lookAheadGap(npc: Npc, obstacles: { Obstacle }, reach: number?, path: { [any]: number }?): (number, number, number, boolean)
	-- returns the bumper-to-bumper gap to the nearest thing in our path and its speed along our heading
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	local best, bestSpeed, bestAlign, bestPlayer = math.huge, 0, 1, false
	local look = reach or T.LookAhead
	-- (2026-11-04) a car changing lanes (a route's outer lane merging before its end) gives way to
	-- the cars in the lane it moves into; they don't wait for it while it is beside them
	local meChanging = (npc.seg :: any).laneChange == true
	local look2 = look * look
	for _, o in obstacles do
		local me = o.self
		local dp = o.pos - npc.pos
		if dp.X * dp.X + dp.Z * dp.Z > look2 then
			continue -- (farther than we look, along the lanes too)
		end
		local start = if me and path then path[me.seg] else nil
		if start and me ~= npc and not (me :: Npc).uturn and math.abs((me :: Npc).off) < ((me :: Npc).width + npc.width) / 2 then
			local f = start + (me :: Npc).s
			if f > 0 and f < look and f - npc.halfLen - o.halfLen < best then
				best = f - npc.halfLen - o.halfLen
				bestSpeed = math.max(0, o.speed * o.fwd:Dot(fwd))
				bestAlign = 1
				bestPlayer = false
			end
		elseif me ~= npc then
			local rel = o.pos - npc.pos
			local f = rel:Dot(fwd)
			-- (a car on a road above or below, a bridge or a tunnel, isn't in our way; 27 Nov: with a path, other cars
			-- are looked for straight ahead only near: far off, on a bend, the lane beside runs across that line)
			if f > 0 and f < (if path and me then math.min(look, T.LookAhead + 30) else look) and math.abs(rel.Y) < 12 then
				local lat = math.abs(rel:Dot(right))
				-- (owner, 2026-11-04: "the cars are bugging here", the Mountain Road's hairpin into the
				-- West Switchbacks) where a road narrows its two lanes run closer than a car's width
				-- (58 spots); two cars side by side each saw the other a little ahead and both stopped
				-- for good, with the queue piling up behind. A car going the same way whose middle is
				-- not ahead of our front half is beside us, not in front. (Only off to the side: one
				-- straight ahead in our own lane, however close, is in front; ignoring it let two
				-- cars drive on inside each other.)
				local beside = f < npc.halfLen * 0.6 and o.fwd:Dot(fwd) > 0.7 and lat > 2.5
				if meChanging then
					beside = false
				elseif o.self and (o.self.seg :: any).laneChange == true then
					beside = f < npc.halfLen and o.fwd:Dot(fwd) > 0.5
				end
				if lat < (npc.width + o.width) / 2 + 0.9 and not beside then
					local gap = f - npc.halfLen - o.halfLen
					if gap < best then
						best = gap
						bestSpeed = math.max(0, o.speed * o.fwd:Dot(fwd))
						bestAlign = if o.ped then 1 else o.fwd:Dot(fwd)
						bestPlayer = o.self == nil and not o.ped
					end
				end
			end
		end
	end
	return best, bestSpeed, bestAlign, bestPlayer
end

---------------------------------------------------------------------
-- Racers (2026-11-19, owner: rare supercars "swimming" through traffic at 100-220 mph; TrafficMix.Racer)
---------------------------------------------------------------------
-- a racer's speed through a piece from its bend (a quadratic bezier): the heading change of that piece in degrees,
-- 3% of its top speed off per degree (owner, 2026-11-21: TrafficMix.racerTurnSpeed), never under the junction turn speed
local bendCache: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local function endDir(q: CityLayout.Segment): Vector3
	local d = q.p2 - q.p1
	return if d.Magnitude > 0.01 then d.Unit else (q.p2 - q.p0).Unit
end
local function startDir(q: CityLayout.Segment): Vector3
	local d = q.p1 - q.p0
	return if d.Magnitude > 0.01 then d.Unit else (q.p2 - q.p0).Unit
end
-- (2026-11-24, racers bumping and hopping) the 1:1 lanes are straight pieces (p1 = the middle), so a piece's own bend
-- was always 0: on a curve, a crest or a dip a racer kept its top speed and its nose snapped at every lane point. The
-- corner where `prev` meets `q` counts now too, up and down included (a crest is a bend); 1 degree of it is chord noise
-- and free, so straights keep their speed
local JOINT_FREE = 1
local function bendSpeed(npc: Npc, q: CityLayout.Segment, prev: CityLayout.Segment?): number
	local deg = bendCache[q]
	if deg == nil then
		local a = (q.p1 - q.p0) * Vector3.new(1, 0, 1)
		local b = (q.p2 - q.p1) * Vector3.new(1, 0, 1)
		deg = if a.Magnitude > 0.1 and b.Magnitude > 0.1 then math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1))) else 0
		bendCache[q] = deg
	end
	local total = deg :: number
	if prev and (prev.p2 - q.p0).Magnitude < 1 then
		total += math.max(0, math.deg(math.acos(math.clamp(endDir(prev):Dot(startDir(q)), -1, 1))) - JOINT_FREE)
	end
	return TrafficMix.racerTurnSpeed(npc.racer or npc.maxSpeed, total, if q.turnSpeed then Config.mphToSps(q.turnSpeed) else TURN_SPEED)
end

-- a racer's place and heading on its way: near a joint of two pieces it runs a short curve round the corner (a
-- quadratic from `w` before the joint to `w` after it, the joint its control point) instead of snapping its heading
-- there; the height stays the lane's own (on the built road) and only the nose eases up or down
local function racerSample(npc: Npc, seg: CityLayout.Segment, s: number): (Vector3, Vector3)
	local pos, fwd = CityLayout.sample(seg, s)
	local a, b, d = nil, nil, 0
	local prev = (npc :: any).prevSeg
	if npc.nextSeg and seg.length - s < 12 then
		a, b, d = seg, npc.nextSeg, s - seg.length
	elseif prev and s < 12 then
		a, b, d = prev, seg, s
	end
	if not a or not b or (a.p2 - b.p0).Magnitude > 1 then
		return pos, fwd
	end
	-- (27 Nov: 12 studs each side for every car at any speed, the curve jointSpeed brakes for; was 0.05 s of travel)
	local w = math.min(12, a.length / 2, b.length / 2)
	if math.abs(d) >= w then
		return pos, fwd
	end
	local A = CityLayout.sample(a, a.length - w)
	local B = CityLayout.sample(b, w)
	local C = (a.p2 + b.p0) / 2
	local t = (d + w) / (2 * w)
	local q = A * (1 - t) ^ 2 + C * (2 * t * (1 - t)) + B * t * t
	local tan = (C - A) * (2 * (1 - t)) + (B - C) * (2 * t)
	if tan.Magnitude < 1e-3 then
		return pos, fwd
	end
	return Vector3.new(q.X, pos.Y, q.Z), tan.Unit
end

-- (owner, 2026-11-21: "also make it so that rare cars can race with each other") the piece a car takes after
-- `prev`: in a race the first car to look decides and the others take the same when they get there, so a race stays
-- together through junctions. In the lane beside that car's: the way on that ends nearest its way on.
local function raceNext(npc: Npc, prev: CityLayout.Segment): CityLayout.Segment?
	local way = npc.way
	-- (2026-11-21) chasing another racer: at a junction the way out that points most at it (a turn back too)
	local t = npc.chase
	if t then
		local q = chooseNext(prev)
		local function toward(o: CityLayout.Segment): number
			return (o.p2 - o.p0).Unit:Dot((t.pos - o.p2).Unit)
		end
		for _, o in publicNext[prev] or {} do
			if q and toward(o) > toward(q) then
				q = o
			end
		end
		return q
	end
	if not way then
		return chooseNext(prev)
	end
	local q = way[prev]
	if q == nil then
		q = chooseNext(prev)
		local ref = nil
		for _, b in besideOf(prev) or {} do
			ref = ref or way[b]
		end
		if ref and q then
			for _, o in publicNext[prev] or {} do
				if (o.p2 - ref.p2).Magnitude < (q.p2 - ref.p2).Magnitude then
					q = o
				end
			end
		end
		way[prev] = q or false
	end
	return q or nil
end

-- (owner, 2026-11-21: "no dont spawn as pairs i mean like when they meet each other coincidencely") a racer's
-- rival: the nearest car of its race. Two racers that meet going the same way on one road (TrafficMix.raceMeets)
-- become a race, a third that meets them joins; with no car of its race within Race.Split (far apart, or taken
-- off the road) a racer drives on alone.
local raceId = 0
-- a chase is over: caught (the race began), or given up (`cool`: neither chases again for Race.Cooldown)
local function endChase(npc: Npc, cool: boolean)
	local o = npc.chase
	for _, c in { npc, o } do
		if cool then
			c.noRace = os.clock() + RACE.Cooldown
		end
	end
	if o and o.chasedBy == npc then
		o.chasedBy = nil
	end
	npc.chase, npc.chaseT, npc.wantU = nil, nil, nil
end
local function raceRival(npc: Npc): Npc?
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	local best: Npc?, bestD = nil, RACE.Split
	for _, o in Traffic.cars do
		if o ~= npc and o.racer then
			local rel = o.pos - npc.pos
			if not (npc.race and o.race) and math.abs(rel.Y) < 12 and TrafficMix.raceMeets(rel:Dot(fwd), rel:Dot(right), fwd:Dot(o.fwd)) then
				local a, b = npc, o -- a = the one ahead: its way is the race's
				if rel:Dot(fwd) > 0 then
					a, b = o, npc
				end
				local way = a.way or b.way or {}
				if not a.way then
					local prev: CityLayout.Segment? = a.seg
					for _, q in { a.nextSeg, table.unpack(a.plan or {}) } do
						if way[prev] == nil then
							way[prev] = q
						end
						prev = q
					end
				end
				raceId += if a.race or b.race then 0 else 1
				local id = a.race or b.race or raceId
				for _, c in { a, b } do
					if c.chase then
						endChase(c, false)
					end
					local joins = c.way ~= way
					c.race, c.way = id, way
					c.model:SetAttribute("Race", id)
					if joins and c == b then
						b.plan = nil
						b.nextSeg = raceNext(b, b.seg)
					end
				end
			elseif not (npc.race or o.race or npc.chase or o.chase or npc.chasedBy or o.chasedBy)
				and math.max(npc.noRace or 0, o.noRace or 0) < os.clock() and TrafficMix.raceSees(rel.Magnitude, rel.Y) then
				-- (owner, 2026-11-21: "the faster car will go around and make an u turn and go near the other rare car")
				-- they see each other but are not on one road the same way: the faster one chases (oncoming: a U-turn
				-- first), the other waits; the race itself begins above once the chaser is within MeetGap on its road
				local c, t = o, npc
				if TrafficMix.raceTurns(npc.racer :: number, o.racer :: number, rel:Dot(o.fwd), -rel:Dot(fwd)) then
					c, t = npc, o
				end
				c.chase, c.chaseT, t.chasedBy = t, RACE.ChaseTime, c
				c.wantU = if c.fwd:Dot(t.fwd) < -0.5 then RACE.UTurnTry else nil
				c.plan = nil
			end
			if npc.race and o.race == npc.race and rel.Magnitude < bestD then
				best, bestD = o, rel.Magnitude
			end
		end
	end
	if npc.race and not best then
		npc.race, npc.way = nil, nil
		npc.model:SetAttribute("Race", nil)
	end
	return best
end

-- the i-th piece after nextSeg on a racer's way (chosen once and kept, so the braking plan is the way it drives)
local function planNext(npc: Npc, i: number, prev: CityLayout.Segment): CityLayout.Segment?
	local plan = npc.plan
	if not plan then
		plan = {}
		npc.plan = plan
	end
	local q = (plan :: any)[i]
	if not q then
		q = raceNext(npc, prev)
		if q then
			(plan :: any)[i] = q
		end
	end
	return q
end

-- the highest speed now that still lets a racer slow for every bend, turn and red light within braking distance
local function racerCap(npc: Npc, now: number): number
	local seg = npc.seg
	local cap = bendSpeed(npc, seg, (npc :: any).prevSeg)
	local d = seg.length - npc.s
	local reach = npc.speed * npc.speed / (2 * RACER.Brake) + 80
	local q = npc.nextSeg
	local prev = seg
	local i = 0
	-- (27 Nov: 14 -> 50 pieces: at a real 1.4 g a racer's braking distance runs past 14 of the 24-stud 1:1 pieces)
	while q and d < reach and i < 50 do
		local v = bendSpeed(npc, q, prev)
		if q.kind == "turn" and q.turning then
			v = math.min(v, if q.turnSpeed then Config.mphToSps(q.turnSpeed) else TURN_SPEED)
		end
		-- a light at the end of a piece ahead (the one we're on: the normal stop logic)
		if prev ~= seg and prev.signal and CityLayout.lightState(prev.i, prev.j, prev.axis, now) ~= "G" then
			cap = math.min(cap, math.sqrt(2 * RACER.Brake * math.max(0, d - npc.halfLen - T.StopLineMargin)))
		end
		cap = math.min(cap, math.sqrt(v * v + 2 * RACER.Brake * math.max(0, d)))
		d += q.length
		prev = q
		i += 1
		q = planNext(npc, i, q)
	end
	return cap
end

-- the nearest thing ahead in a strip `off` studs to the side of the racer's lane middle, and whether the strip
-- beside the racer (its length plus a margin, further back for faster cars coming up) is clear to move into
local function stripGap(npc: Npc, off: number, obstacles: { Obstacle }, reach: number): (number, boolean, number)
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	local base = npc.pos - right * npc.off
	local best, clear, bestV = math.huge, true, 0
	for _, o in obstacles do
		if o.self ~= npc then
			local rel = o.pos - base
			if math.abs(rel.Y) < 12 then
				local f = rel:Dot(fwd)
				local lat = math.abs(rel:Dot(right) - off)
				if lat < (npc.width + o.width) / 2 + 0.5 and f > -reach and f < reach then
					local side = npc.halfLen + o.halfLen + 4
					local closing = math.max(0, o.speed * o.fwd:Dot(fwd) - npc.speed)
					-- (27 Nov: a whole lane move takes Racer.LaneChangeS now, so a faster car must be that far back)
					if f > -side - closing * (RACER.LaneChangeS + 0.5) and f < side then
						clear = false
					elseif f > 0 and f - npc.halfLen - o.halfLen < best then
						best = f - npc.halfLen - o.halfLen
						bestV = math.max(0, o.speed * o.fwd:Dot(fwd))
					end
				end
			end
		end
	end
	return best, clear, bestV
end

-- (2026-11-19, racer crashes -> 0) the gap a racer needs ahead to move into a strip: its braking distance down
-- to the car ahead's speed plus a second of the closing speed, never under the old speed-only rule
local function racerRoom(v: number, vo: number): number
	local c = math.max(0, v - vo)
	return math.max(v * v / (2 * RACER.Brake) * 0.6 + 12, c + c * c / (2 * RACER.Brake * 0.7) + 6 + v * 0.15)
end

-- the nearest car in the strip a racer covers over the next second (its lane middle offset `off` to `offTo`,
-- so a lane change in progress sees both lanes): bumper gap and that car's speed along our way
local function racerSweep(npc: Npc, obstacles: { Obstacle }): (number, number)
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	local base = npc.pos - right * npc.off
	local lo, hi = math.min(npc.off, npc.offTo), math.max(npc.off, npc.offTo)
	local reach = npc.speed * 1 + npc.halfLen * 2 + 40
	local best, bestV = math.huge, 0
	for _, o in obstacles do
		if o.self ~= npc then
			local rel = o.pos - npc.pos
			local f = rel:Dot(fwd)
			if f > 0 and f < reach and math.abs(rel.Y) < 12 then
				local lat = (o.pos - base):Dot(right)
				local half = (npc.width + o.width) / 2 + 0.6
				if lat > lo - half and lat < hi + half then
					local gap = f - npc.halfLen - o.halfLen
					if gap < best then
						best, bestV = gap, math.max(0, o.speed * o.fwd:Dot(fwd))
					end
				end
			end
		end
	end
	return best, bestV
end

-- another racer beside this one on the side it would slide to, level or ahead along the two's mean heading: this
-- one yields (the one ahead has the way, so two side by side never both wait)
local function racerBeside(npc: Npc, dir: number): boolean
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	for _, o in Traffic.cars do
		if o ~= npc and o.racer then
			local rel = o.pos - npc.pos
			local lat = rel:Dot(right)
			if math.abs(rel.Y) < 12 and math.abs(rel:Dot(fwd)) < npc.halfLen + o.halfLen + 8 and lat * dir > 0 and math.abs(lat) < 16
				and rel:Dot(fwd + o.fwd) >= 0 then
				return true
			end
		end
	end
	return false
end

-- the car a racer's box (plus m x a hair) would overlap at pos / fwd, using each car's latest place this frame.
-- mode "ahead": only cars ahead; "prio": all but racers behind. Between two racers "ahead" is along their mean
-- heading, so of two side by side at a merge exactly one has the way (each saw the other ahead and both stood)
local function racerHit(npc: Npc, pos: Vector3, fwd: Vector3, obstacles: { Obstacle }, m: number, mode: string?): (Obstacle?, number)
	local r = fwd:Cross(Vector3.yAxis)
	local hl, hw = npc.halfLen + 0.4 * m, npc.width / 2 + 0.25 * m
	for _, o in obstacles do
		local me = o.self
		if me ~= npc then
			local op = if me then me.pos else o.pos
			local of = if me then me.fwd else o.fwd
			local d = op - pos
			local skip = false
			if mode then
				local along = if me and me.racer then d:Dot(fwd + of) else (if mode == "ahead" then d:Dot(fwd) else 1)
				skip = along <= 0
			end
			if not skip and math.abs(d.Y) < 8 and d.Magnitude < hl + o.halfLen + 12 then
				local orr = of:Cross(Vector3.yAxis)
				local ol, ow = o.halfLen + 0.4 * m, o.width / 2 + 0.25 * m
				local sep = false
				for _, ax in { fwd, r, of, orr } do
					local ra = hl * math.abs(fwd:Dot(ax)) + hw * math.abs(r:Dot(ax))
					local rb = ol * math.abs(of:Dot(ax)) + ow * math.abs(orr:Dot(ax))
					if math.abs(d:Dot(ax)) > ra + rb then
						sep = true
						break
					end
				end
				if not sep then
					return o, d.Magnitude
				end
			end
		end
	end
	return nil, 0
end

-- (owner, 2026-11-21: "the faster car will go around and make an u turn") start a U-turn if it can be made here:
-- the lane graph has no link to the oncoming lane, so it is found by place: the nearest lane piece abreast of the
-- car (within Race.UTurnWidth sideways, 3 studs of height) that runs the other way. No kerb, median, rail or wall
-- between the two lanes (rays), no car in or near the half circle, none coming up the lane it turns into.
local uParams = RaycastParams.new()
uParams.RespectCanCollide = true
local function tryUTurn(npc: Npc, obstacles: { Obstacle })
	local seg = npc.seg
	if seg.kind ~= "lane" or math.abs(npc.off) > 0.5 or math.abs(npc.offTo) > 0.5 then
		return
	end
	local pos, fwd = CityLayout.sample(seg, npc.s)
	local best: CityLayout.Segment?, bestS, bestP, bestD = nil, 0, pos, RACE.UTurnWidth
	for _, q in lanesNear(if (seg :: any).oneToOne or not npc.highway then cityLanes else highwayLanes, pos, RACE.UTurnWidth) do
		if q.kind == "lane" and not isPrivate(q) then
			local qs = math.clamp((pos - q.p0):Dot((q.p2 - q.p0).Unit), 0, q.length)
			local p, f = CityLayout.sample(q, qs)
			local rel = p - pos
			local d = (rel * Vector3.new(1, 0, 1)).Magnitude
			if f:Dot(fwd) < -0.95 and math.abs(rel.Y) < 3 and math.abs(rel:Dot(fwd)) < 4 and d > 8 and d < bestD then
				best, bestS, bestP, bestD = q, qs, p, d
			end
		end
	end
	if not best then
		return
	end
	uParams.FilterDescendantsInstances = { folder :: Instance, workspace:FindFirstChild("PlayerCars") :: Instance }
	for _, h in { 0.8, 2.5 } do
		if workspace:Raycast(pos + Vector3.yAxis * h, bestP - pos, uParams) then
			return
		end
	end
	local side = ((bestP - pos) * Vector3.new(1, 0, 1)).Unit
	local r = bestD / 2
	local centre = (pos + bestP) / 2
	for _, o in obstacles do
		if o.self ~= npc and math.abs(o.pos.Y - pos.Y) < 12 then
			if (o.pos - centre).Magnitude < r + npc.halfLen + o.halfLen + 6 then
				return
			end
			local e = o.pos - bestP
			local along = e:Dot(fwd) -- (+ = it has yet to reach the spot we come out at)
			if o.fwd:Dot(fwd) < -0.5 and along > 0 and along < o.speed * RACE.UTurnTime * 1.3 + 30
				and math.abs(e:Dot(side)) < (npc.width + o.width) / 2 + 1 then
				return
			end
		end
	end
	npc.uturn = { p0 = pos, fwd = side:Cross(Vector3.yAxis) * math.sign(side:Cross(Vector3.yAxis):Dot(fwd)), side = side, r = r,
		dy = bestP.Y - pos.Y, t = 0, seg = best, s = bestS }
end

-- the car a racer's step from (op, of) to (pos, fwd) runs into: a new car within a hair (a straight step: only
-- cars ahead, the car behind keeps its own gap), or a deeper real overlap (a hair less: the counted box) with any
-- car but a racer behind
local function racerBlocked(npc: Npc, pos: Vector3, fwd: Vector3, op: Vector3, of: Vector3, obstacles: { Obstacle }, slid: boolean): Obstacle?
	local mode = if slid then nil else "ahead"
	local hit = racerHit(npc, pos, fwd, obstacles, 1, mode)
	if hit and racerHit(npc, op, of, obstacles, 1, mode) ~= hit then
		return hit
	end
	local real, d = racerHit(npc, pos, fwd, obstacles, 0.4, "prio")
	if real then
		local was, d0 = racerHit(npc, op, of, obstacles, 0.4, "prio")
		if was ~= real or d < d0 then
			return real
		end
	end
	return nil
end

-- where a racer can be sideways: its lane, the same-way lanes beside it (by their real offsets) and the line
-- between two of them (a split); never an oncoming lane (lanesBeside keeps the same way only)
local function racerSpots(npc: Npc): { { lat: number, seg: CityLayout.Segment? } }
	local seg = npc.seg
	local spots: { { lat: number, seg: CityLayout.Segment? } } = { { lat = 0, seg = seg } }
	if seg.kind == "turn" then
		return spots
	end
	local right = npc.fwd:Cross(Vector3.yAxis)
	local base = npc.pos - right * npc.off
	local seen = { [seg] = true }
	local frontier = { seg }
	for _ = 1, 3 do
		local nextF = {}
		for _, f in frontier do
			for _, o in besideOf(f) or {} do
				if not seen[o] then
					seen[o] = true
					local p = CityLayout.sample(o, math.clamp(npc.s * o.length / seg.length, 0, o.length))
					table.insert(spots, { lat = (p - base):Dot(right), seg = o })
					table.insert(nextF, o)
				end
			end
		end
		frontier = nextF
	end
	table.sort(spots, function(a, b)
		return a.lat < b.lat
	end)
	-- (owner, 2026-11-22: "make the npcs cars drive on their lane. some cars drive between both lanes taking up
	-- space") no more splits: the line between two lanes is not a place to be, only whole lanes
	return spots
end

-- (27 Nov) a sideways move from x0 (moving at v0, accelerating a0) to `to`, at rest there: a quintic (minimum jerk) over
-- T s, long enough that the nose never turns more than about 8 degrees off the lane (lateral speed <= 0.14 x speed)
local function laneMove(x0: number, v0: number, a0: number, to: number, speed: number): any
	local h = to - x0
	local w = math.abs(h)
	local T0 = math.clamp(math.max(RACER.LaneChangeS * math.sqrt(math.min(w / 12, 1.5)), 13.4 * w / math.max(speed, 1)), 0.6, 8)
	local T2, T3, T4, T5 = T0 * T0, T0 ^ 3, T0 ^ 4, T0 ^ 5
	return {
		x0 = x0, to = to, t = 0, T = T0, v0 = v0, a2 = a0 / 2,
		a3 = (20 * h - 12 * v0 * T0 - 3 * a0 * T2) / (2 * T3),
		a4 = (-30 * h + 16 * v0 * T0 + 3 * a0 * T2) / (2 * T4),
		a5 = (12 * h - 6 * v0 * T0 - a0 * T2) / (2 * T5),
	}
end
-- place, sideways speed and sideways acceleration t s into a move
local function laneAt(m: any, t: number): (number, number, number)
	local x = m.x0 + t * (m.v0 + t * (m.a2 + t * (m.a3 + t * (m.a4 + t * m.a5))))
	local v = m.v0 + t * (2 * m.a2 + t * (3 * m.a3 + t * (4 * m.a4 + t * 5 * m.a5)))
	local a = 2 * m.a2 + t * (6 * m.a3 + t * (12 * m.a4 + t * 20 * m.a5))
	return x, v, a
end

-- pick where to be sideways (overtake, weave, split) a few times a second, slide there, take the new lane over
local function racerSide(npc: Npc, dt: number, obstacles: { Obstacle })
	local seg = npc.seg
	-- junctions and roundabouts as everyone else: back in a lane's middle before the next junction (a turn piece
	-- or a light ahead; the 1:1 lanes come in short pieces, so the end of this piece is no junction)
	local toJunction = seg.length - npc.s
	local need = 30 + npc.speed * 0.9
	if seg.kind ~= "turn" and not seg.signal then
		local q, i = npc.nextSeg, 0
		while q and q.kind ~= "turn" and toJunction < need and i < 12 do
			i += 1
			if q.signal then
				toJunction += q.length
				break
			end
			toJunction += q.length
			q = planNext(npc, i, q)
		end
	end
	local settle = seg.kind == "turn" or toJunction < need or besideMap == nil
	npc.sideT -= dt
	if npc.sideT <= 0 then
		npc.model:SetAttribute("RacerSpeed", math.floor(npc.speed / Config.mphToSps(1)))
	end
	if settle then
		npc.offTo = 0
		if npc.sideT <= 0 then
			npc.sideT = 0.2
		end
	elseif npc.sideT <= 0 and math.abs(npc.offTo - npc.off) > 0.01 then
		npc.sideT = 0.2 -- (owner, 2026-11-21: a slide under way finishes; a new target only once it has arrived: no wobble)
	elseif npc.sideT <= 0 then
		npc.sideT = 0.2
		local was = npc.offTo
		local reach = math.max(T.LookAhead, npc.speed * RACER.LookAheadS)
		local here = stripGap(npc, npc.off, obstacles, reach)
		if here < npc.speed * 1.6 + 20 then
			local bestLat, bestGap = npc.offTo, here + 25 -- (only for a clearly better gap)
			for _, sp in racerSpots(npc) do
				local gap, clear = stripGap(npc, sp.lat, obstacles, reach)
				-- a split only when no whole lane is better (the squeeze between two queues)
				local score = if sp.seg then gap else gap - 30
				if clear and score > bestGap then
					bestLat, bestGap = sp.lat, score
				end
			end
			npc.offTo = bestLat
		elseif math.abs(npc.offTo) > 0.01 then
			-- the way is open: settle into the nearest whole lane
			local near, nd = 0, math.huge
			for _, sp in racerSpots(npc) do
				if sp.seg and math.abs(sp.lat - npc.off) < nd then
					near, nd = sp.lat, math.abs(sp.lat - npc.off)
				end
			end
			npc.offTo = near
		end
		if npc.offTo ~= was then
			npc.offFrom = npc.off
			npc.sideT = RACER.SideHold -- (a minimum time before the next choice)
		end
	end
	-- slide, but only into a strip that is clear beside us and has room ahead to brake in (sliding in at speed
	-- right behind a slow car rear-ended it in the first test); if a merge back before a junction can't be made,
	-- hold back (holdMerge) until it can
	-- (27 Nov, owner: "the cut up is just a car rotated") the move is an S-curve (laneMove): steer in, then counter-steer,
	-- Racer.LaneChangeS for a whole lane at speed; a new target starts from where the car is and how it is moving
	local delta = npc.offTo - npc.off
	npc.holdMerge = nil
	local u = npc :: any
	if math.abs(delta) > 0.01 then
		local lc = u.lc
		if not lc or lc.to ~= npc.offTo then
			lc = laneMove(npc.off, u.offV or 0, u.offA or 0, npc.offTo, npc.speed)
			u.lc = lc
		end
		local t2 = math.min(lc.t + dt, lc.T)
		local to, v2, a2 = laneAt(lc, t2)
		if t2 >= lc.T then
			to, v2, a2 = lc.to, 0, 0
		end
		local reach = math.max(T.LookAhead, npc.speed * RACER.LookAheadS)
		local ahead, clear, aheadV = stripGap(npc, npc.offTo, obstacles, reach)
		local nowAhead, clearNow, nowV = stripGap(npc, to, obstacles, T.LookAhead)
		-- (gap scaled by the closing speed, in the lane we go to and on the way there; a racer beside yields)
		if clear and clearNow and ahead > racerRoom(npc.speed, aheadV) and nowAhead > racerRoom(npc.speed, nowV) * 0.5
			and not racerBeside(npc, math.sign(delta)) then
			npc.off = to
			lc.t, u.offV, u.offA = t2, v2, a2
			if t2 >= lc.T then
				u.lc = nil
			end
		elseif settle then
			npc.holdMerge = true
			u.lc, u.offV, u.offA = nil, 0, 0 -- (it waits beside the line; the move starts afresh once the lane is free)
		else
			-- (owner, 2026-11-21) that gap closed: ease back to where the slide began (the way back shut too: stay),
			-- and no new choice for a moment (it used to stop mid-lane and re-pick 0.2 s later: a wobble)
			-- (2026-11-22: never "stay" between two lanes: keep heading for a whole lane, the one it came from)
			npc.offTo = if npc.offFrom then npc.offFrom else npc.offTo
			npc.sideT = math.max(npc.sideT, RACER.SideHold)
		end
	end
	-- over another lane's middle: that lane is ours now (its way on through the next junction)
	if not settle and math.abs(npc.off) > 2 then
		for _, sp in racerSpots(npc) do
			local o = sp.seg
			if o and o ~= seg and math.abs(sp.lat - npc.off) < 0.5 then
				npc.off -= sp.lat
				npc.offTo -= sp.lat
				npc.offFrom = if npc.offFrom then npc.offFrom - sp.lat else nil
				u.prevOff = if u.prevOff then u.prevOff - sp.lat else nil
				if u.lc then
					u.lc.x0 -= sp.lat
					u.lc.to -= sp.lat
				end
				npc.s = math.clamp(npc.s * o.length / seg.length, 0, o.length)
				npc.seg = o
				npc.nextSeg = raceNext(npc, o)
				npc.plan = nil
				npc.model:SetAttribute("LaneSwaps", (npc.model:GetAttribute("LaneSwaps") or 0) + 1)
				break
			end
		end
	end
end

-- Left turns cross oncoming traffic: wait at the line until the oncoming lanes are clear
local function leftOf(dir: number): number
	return ((dir + 2) % 4) + 1
end

local function mustYieldLeft(npc: Npc, seg: CityLayout.Segment): boolean
	local oncoming = ((seg.dir + 1) % 4) + 1
	for _, o in Traffic.cars do
		if o ~= npc and o.seg.i == seg.i and o.seg.j == seg.j then
			local os = o.seg
			if os.kind == "lane" and os.dir == oncoming and os.length - o.s < 75 and o.speed > 2 then
				local oNext = o.nextSeg
				-- an oncoming car that is also turning left does not conflict
				if not (oNext and oNext.turning and oNext.dir == leftOf(oncoming)) then
					return true
				end
			elseif os.kind == "turn" and not os.turning and os.dir == oncoming then
				return true -- oncoming car already crossing the junction
			end
		end
	end
	local center = CityLayout.intersectionPos(seg.i, seg.j)
	for _, pc in playerCarCache do
		if (pc.pos - center).Magnitude < 45 and pc.speed > 3 then
			return true
		end
	end
	return false
end

-- Crossing traffic (owner, 2026-11-03: "make the traffic cars smarter, they're bumping into each
-- other at the intersection"): lookAheadGap only sees what is straight ahead, so cars turning at a
-- junction ran into cars crossing or turning into the same lane. Each turn through a junction knows
-- which other paths cross it or merge with it (worked out once, from the curves themselves). A car
-- about to take a turn waits at the junction's edge while a car is on one of those paths, or is
-- coming up to one and nearer the junction (on a tie, the lower number goes first). Cars already in
-- the junction carry on and clear it. A player's car always has the way.
local npcIndex: { [Npc]: number } = setmetatable({}, { __mode = "k" }) :: any
local nextIndex = 0
local function indexOf(n: Npc): number
	local k = npcIndex[n]
	if not k then
		nextIndex += 1
		k = nextIndex
		npcIndex[n] = k
	end
	return k
end
local conflictCache: { [any]: { [any]: Vector3 } } = {}
-- (2026-11-04, "optimize, a little glitchy") every piece of road a car reached for the first time scanned
-- all the Riviera's pieces, and the map has grown: a hitch each time, worst on the long highways. Pieces are
-- found through a grid now, built once.
local GRID_CELL = 96
local rivGrid: { [number]: { CityLayout.Segment } }? = nil
local function rivCells(lo: Vector3, hi: Vector3, visit: (number) -> ())
	for cx = math.floor(lo.X / GRID_CELL), math.floor(hi.X / GRID_CELL) do
		for cz = math.floor(lo.Z / GRID_CELL), math.floor(hi.Z / GRID_CELL) do
			visit(cx * 65536 + cz)
		end
	end
end
local function nearPieces(lo: Vector3, hi: Vector3): { CityLayout.Segment }
	if not rivGrid then
		local grid: { [number]: { CityLayout.Segment } } = {}
		local riv = RivieraTraffic.build()
		for _, other in (if riv then riv.all else {}) :: { CityLayout.Segment } do
			rivCells(other.p0:Min(other.p1):Min(other.p2), other.p0:Max(other.p1):Max(other.p2), function(key)
				local cell = grid[key]
				if not cell then
					cell = {}
					grid[key] = cell
				end
				table.insert(cell, other)
			end)
		end
		rivGrid = grid
	end
	local out, seen = {}, {}
	rivCells(lo, hi, function(key)
		for _, other in (rivGrid :: any)[key] or {} do
			if not seen[other] then
				seen[other] = true
				table.insert(out, other)
			end
		end
	end)
	return out
end
local function conflictsOf(turn: CityLayout.Segment): { [any]: Vector3 }
	local c = conflictCache[turn]
	if c then
		return c
	end
	c = {}
	conflictCache[turn] = c
	local lo = turn.p0:Min(turn.p1):Min(turn.p2) - Vector3.new(8, 8, 8)
	local hi = turn.p0:Max(turn.p1):Max(turn.p2) + Vector3.new(8, 8, 8)
	local mine = {}
	for k = 0, 6 do
		mine[k + 1] = (CityLayout.sample(turn, turn.length * k / 6))
	end
	for _, other in nearPieces(lo, hi) do
		if other ~= turn then
			local olo = other.p0:Min(other.p1):Min(other.p2)
			local ohi = other.p0:Max(other.p1):Max(other.p2)
			if olo.X <= hi.X and ohi.X >= lo.X and olo.Z <= hi.Z and ohi.Z >= lo.Z then
				local sameStart = (other.p0 - turn.p0).Magnitude < 1
				local sameEnd = (other.p2 - turn.p2).Magnitude < 1
				local feeds = (other.p2 - turn.p0).Magnitude < 1 or (other.p0 - turn.p2).Magnitude < 1
				local sameRoad = turn.kind == "lane" and other.kind == "lane" and (turn :: any).road == (other :: any).road
				if sameRoad then
					-- (a road's own lanes never cross each other)
				elseif sameEnd and not sameStart then
					c[other] = turn.p2 -- both end in the same lane: a merge
				elseif not sameStart and not feeds then
					-- where the two paths come closest (within 6 studs)
					local bestD, bestP = 6, nil
					for k = 0, 6 do
						local q = (CityLayout.sample(other, other.length * k / 6))
						for _, p in mine do
							local d = Vector3.new(p.X - q.X, 0, p.Z - q.Z).Magnitude
							if d < bestD and math.abs(p.Y - q.Y) < 6 then
								bestD, bestP = d, (p + q) / 2
							end
						end
					end
					if bestP then
						c[other] = bestP
					end
				end
			end
		end
	end
	return c
end
-- the distance to stop in before the junction, or nil
-- (27 Nov: the pieces ahead within a comfortable stop, up to the first junction turn, not only the next one: the 1:1
-- lane pieces are ~24 studs, so a car saw a crossing car one piece before the junction, too late to stop gently, and
-- ran into it)
local crossC: { { [any]: Vector3 } } = {}
local crossEnd: { number } = {}
local function crossConflict(npc: Npc, obstacles: { Obstacle }): number?
	local seg = npc.seg
	if seg.kind ~= "lane" or not npc.nextSeg then
		return nil
	end
	local window = math.max(30, npc.speed * npc.speed / (2 * T.PlanBrake) + 12)
	local n = 0
	local d = seg.length - npc.s
	local q: CityLayout.Segment?, k = npc.nextSeg, 0
	local jp: Vector3?, jpEnd = nil, 0
	while q and k < 4 do
		local toEnd = d - npc.halfLen - T.StopLineMargin
		if toEnd > window then
			break
		end
		-- (the next piece: a turn through the junction, or a lane piece that runs across another road)
		if (q :: any).riviera and toEnd >= -1 then
			local C = conflictsOf(q)
			if next(C) ~= nil then -- (most 1:1 lane pieces cross nothing: no car loop for them)
				n += 1
				crossC[n], crossEnd[n] = C, toEnd
			end
			if q.kind == "turn" and not jp then
				jp, jpEnd = q.p1, toEnd
			end
		end
		if q.kind == "turn" then
			break -- (past the junction)
		end
		d += q.length
		k += 1
		q = planNext(npc, k, q)
	end
	if n == 0 and not jp then
		return nil
	end
	local me = indexOf(npc)
	local vMe = math.max(npc.speed, 5)
	for _, o in (if n > 0 then Traffic.cars else {}) :: { Npc } do
		if o ~= npc and (o.pos - npc.pos).Magnitude < 120 + window then
			local o1 = if o.plan then o.plan[1] else nil
			for i = 1, n do
				local C = crossC[i]
				local P = C[o.seg] or (if o.nextSeg then C[o.nextSeg] else nil) or (if o1 then C[o1] else nil)
				if P then
					local toEnd = crossEnd[i]
					local toP = P - o.pos
					local ahead = toP:Dot(o.fwd) -- how far the spot is ahead of that car's middle
					local dist = Vector3.new(toP.X, 0, toP.Z).Magnitude
					if dist < o.halfLen + 4 and (o.speed > 0.5 or ahead < o.halfLen * 0.5) then
						-- it is on the spot right now (a car stopped short of it, waiting its turn, isn't)
						return math.max(0, toEnd)
					elseif ahead > 0 and dist < 40 + o.speed * 1.5 and o.speed > 0.5 then
						-- it is heading for the spot: whoever gets there first goes (and clears it by a car length)
						local tO = ahead / math.max(o.speed, 0.5)
						local myP = P - npc.pos
						local tMe = math.max(myP:Dot(npc.fwd), 0) / vMe
						if tO < tMe - 0.2 or (math.abs(tO - tMe) <= 0.2 and indexOf(o) < me) then
							return math.max(0, toEnd)
						end
					end
				end
			end
		end
	end
	-- a player's car near the junction: wait for it
	if jp then
		for _, pc in playerCarCache do
			if (pc.pos - jp).Magnitude < 40 and pc.speed > 3 then
				return math.max(0, jpEnd)
			end
		end
	end
	local _ = obstacles
	return nil
end

-- speed bumps (tag "SpeedBump", tools/riviera/SpeedBumps.luau) in 64-stud cells; they stream in,
-- so the list is refreshed every few seconds
local bumpCells: { [string]: { { pos: Vector3, dir: Vector3 } } } = {}
local bumpRefresh = 0
local function refreshBumps()
	table.clear(bumpCells)
	for _, m in CollectionService:GetTagged("SpeedBump") do
		if m:IsA("Model") and m.Parent then
			local pos = m:GetPivot().Position
			local key = math.floor(pos.X / 64) .. "," .. math.floor(pos.Z / 64)
			bumpCells[key] = bumpCells[key] or {}
			table.insert(bumpCells[key], { pos = pos, dir = (m:GetAttribute("Dir") :: Vector3?) or Vector3.zAxis })
		end
	end
end
bumpAhead = function(npc: Npc): boolean
	local cx, cz = math.floor(npc.pos.X / 64), math.floor(npc.pos.Z / 64)
	for dx = -1, 1 do
		for dz = -1, 1 do
			local cell = bumpCells[(cx + dx) .. "," .. (cz + dz)]
			for _, b in cell or {} :: { { pos: Vector3, dir: Vector3 } } do
				local rel = b.pos - npc.pos
				local ahead = rel:Dot(npc.fwd)
				if ahead > -npc.halfLen and ahead < T.BumpLook and math.abs(rel:Dot(Vector3.new(-npc.fwd.Z, 0, npc.fwd.X))) < 34 then
					return true
				end
			end
		end
	end
	return false
end

local obstacleList: { Obstacle } = {}
local npcObstacle: { [Npc]: Obstacle } = setmetatable({}, { __mode = "k" }) :: any
local frameCount = 0
local movedParts: { BasePart } = {}
local movedCFrames: { CFrame } = {}

-- (owner, 2026-11-21: "the rare car sounds too") the nearest racers play their own car's engine set from the
-- car (Audio.engine, 3D), revs from their speed through made-up gears; at most RACER_VOICES (1 on a low-end
-- phone), none past RACER_EAR studs; a racer taken off the road loses its sound the same frame
local RACER_VOICES, RACER_EAR, RACER_GEARS = 2, 220, 6
local voices: { [Npc]: { eng: any, distT: number } } = {}
local function racerSounds(dt: number)
	local cam = workspace.CurrentCamera
	local near: { { npc: Npc, d: number } } = {}
	if cam and running then
		for _, npc in Traffic.cars do
			if npc.racer and npc.model.Parent then
				local d = (npc.pos - cam.CFrame.Position).Magnitude
				if d < RACER_EAR then
					table.insert(near, { npc = npc, d = d })
				end
			end
		end
		table.sort(near, function(a, b)
			return a.d < b.d
		end)
	end
	local keep: { [Npc]: number } = {}
	for i = 1, math.min(#near, if LowEnd.on then 1 else RACER_VOICES) do
		keep[near[i].npc] = near[i].d
	end
	for npc, v in voices do
		if not keep[npc] then
			v.eng:destroy()
			voices[npc] = nil
		end
	end
	for npc, d in keep do
		local v = voices[npc]
		if not v then
			local id = npc.model:GetAttribute("TrafficId")
			local spec = if type(id) == "string" then Cars.ById[id] else nil
			if not spec or spec.Electric then
				continue
			end
			local ok, eng = pcall(Audio.engine, spec.Class, npc.root, spec.Id)
			if not ok then
				continue
			end
			v = { eng = eng, distT = 0 }
			voices[npc] = v
		end
		local frac = math.clamp(npc.speed / (npc.racer :: number), 0, 1)
		local inGear = math.min(frac * RACER_GEARS, RACER_GEARS - 0.001) % 1
		local rpm = if frac < 1 / RACER_GEARS then 0.15 + 0.8 * inGear else 0.45 + 0.5 * inGear
		v.eng:update(rpm, if npc.braking then 0 else 1, frac, 0, nil, nil)
		v.distT -= dt
		if v.distT <= 0 then
			v.distT = 0.25
			v.eng:setDistance(d)
		end
	end
end

---------------------------------------------------------------------
-- Real car motion (27 Nov 2026, owner: "the cars rn are unnatural too, they go through each other sometimes, the cut up
-- is just a car rotated and it looks like there is none of our good car physics like the player car physics")
---------------------------------------------------------------------
local pathOff: { [any]: number } = {}
local holds = 0 -- steps the no-overlap check refused (Traffic folder attribute Holds: should stay rare)
local DF = Config.DrivingFeel

-- the speed an everyday car takes the joint between two straight lane pieces at: about 0.3 g sideways round the curve
-- racerSample draws there (12 studs each side), no limit under 1 degree
local jointCache: { [any]: { any } } = setmetatable({}, { __mode = "k" }) :: any
local function jointSpeed(prev: CityLayout.Segment, q: CityLayout.Segment): number
	local c = jointCache[q]
	if c and c[1] == prev then
		return c[2]
	end
	local v = math.huge
	if (prev.p2 - q.p0).Magnitude <= 1 then
		local deg = math.deg(math.acos(math.clamp(endDir(prev):Dot(startDir(q)), -1, 1)))
		if deg >= 1 then
			v = math.sqrt(0.3 * DF.G * 2 * math.min(12, prev.length / 2, q.length / 2) / math.rad(deg))
		end
	end
	jointCache[q] = { prev, v }
	return v
end

-- speed from target: the pull fades near the target and at the car's top speed, braking grows with how much too fast
-- the car is (normal, then up to the emergency stop), and either builds up at Jerk (x4 for a hard stop)
local function driveSpeed(npc: Npc, target: number, dt: number)
	local v = npc.speed
	local racer = npc.racer ~= nil
	local norm = if racer then RACER.Brake else T.Brake
	local want
	if target > v then
		local up = if racer then RACER.Accel else T.Accel
		want = math.min(up * (1 - 0.45 * math.min(v / math.max(npc.maxSpeed, 1), 1)), (target - v) * 1.2)
	else
		local over = v - target
		local hard = if racer then RACER.MaxBrake else T.EmergencyBrake
		want = -math.min(over * 3, if over > 6 then math.min(hard, norm + (over - 6) * 3) else norm)
	end
	local jerk = if want < -norm * 0.9 then T.Jerk * 4 else T.Jerk
	npc.acc += math.clamp(want - npc.acc, -jerk * dt, jerk * dt)
	local nv = v + npc.acc * dt
	-- (it never pulls past the speed it wants, nor brakes below it)
	if npc.acc > 0 and nv > target and v <= target then
		nv = target
	elseif npc.acc < 0 and nv < target and v >= target then
		nv = target
	end
	if nv <= 0 then
		nv = 0
		npc.acc = math.max(npc.acc, 0)
	end
	npc.speed = nv
end

-- the obstacle an everyday car's step would run into: its box (a hair round it) overlapping another's deeper after the
-- step than before. Of two traffic cars the one ahead along their mean heading has the way, so exactly one waits (dead
-- level: the lower number goes); a player's car has the way unless it is behind
-- how deep two flat boxes overlap (the least push along the four axes that would part them; under 0 = apart)
local function boxDepth(p: Vector3, f: Vector3, hl: number, hw: number, q: Vector3, g: Vector3, ol: number, ow: number): number
	local r, gr = f:Cross(Vector3.yAxis), g:Cross(Vector3.yAxis)
	local d = q - p
	local depth = math.huge
	for _, ax in { f, r, g, gr } do
		local ra = hl * math.abs(f:Dot(ax)) + hw * math.abs(r:Dot(ax))
		local rb = ol * math.abs(g:Dot(ax)) + ow * math.abs(gr:Dot(ax))
		depth = math.min(depth, ra + rb - math.abs(d:Dot(ax)))
		if depth < 0 then
			return depth
		end
	end
	return depth
end
-- (np, nf = the place and heading the step would give: a long bus swinging round a corner sweeps its tail sideways)
local function stepBlocked(npc: Npc, np: Vector3, nf: Vector3, obstacles: { Obstacle }): Obstacle?
	local pos, fwd = npc.pos, npc.fwd
	local hl, hw = npc.halfLen + 0.4, npc.width / 2 + 0.25
	for _, o in obstacles do
		local me = o.self
		if me ~= npc then
			local op = if me then me.pos else o.pos
			local d = op - np
			if math.abs(d.X) < 44 and math.abs(d.Z) < 44 and math.abs(d.Y) < 8 then
				local of = if me then me.fwd else o.fwd
				local ol, ow = o.halfLen + 0.4, o.width / 2 + 0.25
				local depth = boxDepth(np, nf, hl, hw, op, of, ol, ow)
				if depth > 0 then
					local rel = op - pos
					local prio
					if me then
						-- (27 Nov, measured: "whose middle is ahead along my own heading" and "never drive into a waiting
						-- car" both made standoffs that ended in overlaps at merges; the mean heading alone does not)
						local along = rel:Dot(fwd + of)
						prio = if math.abs(along) > 0.5 then along > 0 else indexOf(me) < indexOf(npc)
					else
						prio = rel:Dot(fwd) > -npc.halfLen
					end
					-- (only a step that makes the overlap deeper is refused: one that eases two cars apart always goes)
					if prio and depth > boxDepth(pos, fwd, hl, hw, op, of, ol, ow) + 0.005 then
						return o
					end
				end
			end
		end
	end
	return nil
end

-- where an everyday car would be after ds studs more (no state changed): its own piece, or the start of the next
local function peekPose(npc: Npc, ds: number): (Vector3, Vector3)
	local s2 = npc.s + ds
	local seg, nxt = npc.seg, npc.nextSeg
	if s2 <= seg.length or not nxt then
		return racerSample(npc, seg, math.min(s2, seg.length))
	end
	return CityLayout.sample(nxt, math.min(s2 - seg.length, nxt.length))
end

-- the body on its springs, the way the player's car does it (DrivingFeel BodyRoll / BodyPitch and their springs, times
-- Config.Traffic.BodyRollK / BodyPitchK): the yaw rate comes from the heading drawn (corners, lane changes), lonA from
-- the speed change; the front wheels steer to the path's curve (a bicycle model on the car's wheelbase)
local function bodyMotion(npc: Npc, look: Vector3, lonA: number, dt: number)
	local u = npc :: any
	local last = u.lastLook
	u.lastLook = look
	local yawRate = 0
	if last and dt > 0 then
		yawRate = math.clamp(math.atan2(last:Cross(look).Y, last:Dot(look)) / dt, -1.5, 1.5)
	end
	local tall = npc.height > npc.width * 0.95 -- (vans and buses lean more)
	local rk = if npc.racer then 0.6 elseif tall then 1.45 else 1
	local pk = if npc.racer then 0.7 elseif tall then 1.3 else 1
	local latG = math.clamp(npc.speed * yawRate / DF.G, -0.7, 0.7)
	local lonG = math.clamp(lonA / DF.G, -1, 1)
	u.pitchV = (u.pitchV or 0) + ((math.rad(DF.BodyPitch) * pk * T.BodyPitchK * lonG - (u.pitch or 0)) * 70 - (u.pitchV or 0) * 10) * dt
	u.pitch = (u.pitch or 0) + u.pitchV * dt
	u.rollV = (u.rollV or 0) + ((math.rad(DF.BodyRoll) * rk * T.BodyRollK * latG - (u.roll or 0)) * 90 - (u.rollV or 0) * 12) * dt
	u.roll = (u.roll or 0) + u.rollV * dt
	if npc.body then
		-- (+ pitch = nose up, so braking dips it; a turn to the left leans the top to the right)
		npc.body.Transform = CFrame.Angles(math.clamp(u.pitch, -0.08, 0.08), 0, -math.clamp(u.roll, -0.09, 0.09))
	end
	local want = math.atan(npc.halfLen * 1.2 * yawRate / math.max(npc.speed, 3))
	u.steer = (u.steer or 0) + (math.clamp(want, -0.6, 0.6) - (u.steer or 0)) * math.min(1, dt * 12)
	local spinCF = CFrame.Angles(npc.spin, 0, 0)
	local steerCF = CFrame.Angles(0, u.steer, 0) * spinCF
	for _, w in npc.wheels do
		w.Transform = if npc.fronts[w] then steerCF else spinCF
	end
end

function Traffic.update(dt: number)
	if not running or #Traffic.cars == 0 then
		racerSounds(0)
		TrafficSounds.step(0, {}, false)
		return
	end
	dt = math.min(dt, 0.1)
	racerSounds(dt)
	-- (27 Nov) pass-by roar on the nearest cars and honks (TrafficSounds)
	TrafficSounds.step(dt, Traffic.cars, true, (Traffic :: any).peds)
	local dt0 = dt
	refreshPlayerCars()
	bumpRefresh -= dt
	if bumpRefresh <= 0 then
		bumpRefresh = 3
		refreshBumps()
	end
	local now = workspace:GetServerTimeNow()

	mountainCars = 0
	rivieraCars = 0
	rivHighwayCars = 0
	for i in zoneCars do
		zoneCars[i] = 0
	end
	for _, npc in Traffic.cars do
		if (npc.seg :: any).rivHighway then
			rivHighwayCars += 1
		end
		local zone = zoneOf(npc.pos)
		if zone then
			zoneCars[zone] += 1
		end
		if npc.seg.mountain then
			mountainCars += 1
		end
		if (npc.seg :: any).riviera then
			rivieraCars += 1
		end
	end

	-- reuse one obstacle record per NPC instead of allocating every frame
	table.clear(obstacleList)
	for _, npc in Traffic.cars do
		local o = npcObstacle[npc]
		if not o then
			o = { pos = npc.pos, fwd = npc.fwd, speed = 0, halfLen = npc.halfLen, width = npc.width, self = npc }
			npcObstacle[npc] = o
		end
		o.pos = npc.pos
		o.fwd = npc.fwd
		o.speed = npc.speed
		table.insert(obstacleList, o)
	end
	for _, pc in playerCarCache do
		table.insert(obstacleList, pc)
	end
	for _, o in Traffic.peds do
		table.insert(obstacleList, o)
	end

	table.clear(movedParts)
	table.clear(movedCFrames)
	frameCount += 1
	local camCF = if workspace.CurrentCamera then workspace.CurrentCamera.CFrame else CFrame.identity
	local camPos, camLook = camCF.Position, camCF.LookVector

	for _idx, npc in Traffic.cars do
		-- (2026-11-06, FPS: a car far from the camera thinks every 3rd frame, with the time saved up)
		local dt = dt0
		if not npc.racer and ((npc :: any).camDist or 0) > 380 then
			(npc :: any).bank = ((npc :: any).bank or 0) + dt0
			if (frameCount + _idx) % 3 ~= 0 then
				-- (27 Nov, owner: "the npcs from far away are laggy") the think waits, but a car in view still slides
				-- along at its speed every frame (corrected on its next think), instead of jumping every 3rd frame
				local p = npc.pos + npc.fwd * (npc.speed * (npc :: any).bank)
				if (p - camPos):Dot(camLook) > 0 then
					local up = Vector3.new(0, npc.height / 2, 0)
					table.insert(movedParts, npc.root)
					table.insert(movedCFrames, CFrame.lookAt(p + up, p + up + npc.fwd))
				end
				continue
			end
			dt = (npc :: any).bank;
			(npc :: any).bank = 0
		end
		-- (owner, 2026-11-21: "make an u turn") a U-turn under way: the car drives the half circle
		-- (TrafficMix.uTurnPose) into the oncoming lane, waiting where the next step would touch a car
		local u = npc.uturn
		if u then
			local v = math.min(Config.mphToSps(RACE.UTurnMph), math.pi * u.r / RACE.UTurnTime)
			-- (blocked mid-arc for 4 s: it backs out the way it came and gives the turn up; it never sits across the road)
			local back = ((u :: any).stall or 0) > 4
			local t = math.clamp(u.t + (if back then -1 else 1) * v * dt / (math.pi * u.r), 0, 1)
			local pos, fwd = TrafficMix.uTurnPose(u.p0, u.fwd, u.side, u.r, t)
			pos += Vector3.yAxis * (u.dy * t)
			if back then
				u.t, npc.pos, npc.fwd, npc.speed = t, pos, fwd, 0
				if t <= 0 then
					npc.uturn, npc.wantU = nil, nil
				end
			elseif racerHit(npc, pos, fwd, obstacleList, 1, nil) then
				npc.speed = 0;
				(u :: any).stall = ((u :: any).stall or 0) + dt
				if u.t == 0 then
					npc.uturn = nil -- (not begun: look again)
				end
			else
				u.t, npc.pos, npc.fwd, npc.speed = t, pos, fwd, v;
				(u :: any).stall = 0
			end
			if u.t >= 1 then
				npc.seg, npc.s, npc.off, npc.offTo, npc.plan, npc.uturn, npc.wantU = u.seg, u.s, 0, 0, nil, nil, nil
				npc.nextSeg = raceNext(npc, u.seg)
			end
			local up = Vector3.new(0, npc.height / 2, 0)
			table.insert(movedParts, npc.root)
			table.insert(movedCFrames, CFrame.lookAt(npc.pos + up, npc.pos + up + npc.fwd))
			continue
		end
		local seg = npc.seg
		-- (the highway is driven faster, the inside lane too; each car drifts a little)
		local laneK = if seg.kind == "turn" then 1 else T.LaneSpeedK[math.clamp(seg.lane or 1, 1, #T.LaneSpeedK)]
		local target = npc.maxSpeed * seg.speedK * laneK * (1 + T.Wander * math.sin(now * npc.wanderRate + npc.wanderPhase))
		if (seg :: any).rivHighway and (seg :: any).route then
			target = HIGHWAY_SPEED * (1 + 0.03 * math.sin(now * npc.wanderRate + npc.wanderPhase)) -- (a hair of drift, or they'd run in step)
		end
		if npc.racer then
			-- top speed on straights, slowed in time for every bend, turn and red light ahead
			-- (owner, 2026-11-21: "rare cars can race with each other") in a race the one behind is towed along (x Race.Tow
			-- within TowGap) and the one well in front eases to the slower car's pace (x Race.Ease), so they trade
			-- places; passing is the normal strip logic and every no-touch rule holds between them
			local top = npc.racer
			local rival = raceRival(npc)
			if rival then
				local k = TrafficMix.raceFactor((npc.pos - rival.pos):Dot(npc.fwd + rival.fwd) / 2)
				top = (if k < 1 then math.min(top, rival.racer or top) else top) * k
			end
			-- (owner, 2026-11-21: "the faster car will go around and make an u turn") a chaser runs x Race.Chase, the
			-- car it is after waits at x Race.Wait; given up after Race.ChaseTime, beyond Split or when one is gone
			local t = npc.chase
			if t then
				npc.chaseT = (npc.chaseT or 0) - dt
				if (npc.chaseT :: number) <= 0 or t.model.Parent == nil or (t.pos - npc.pos).Magnitude > RACE.Split then
					endChase(npc, true)
				else
					top *= RACE.Chase
				end
			end
			local by = npc.chasedBy
			if by and (by.chase ~= npc or by.model.Parent == nil) then
				npc.chasedBy = nil
			elseif by then
				top *= RACE.Wait
			end
			target = math.min(top * (1 + 0.03 * math.sin(now * npc.wanderRate + npc.wanderPhase)), racerCap(npc, now))
			if npc.wantU then
				-- slow right down and turn round where the oncoming lane can be reached and all is clear
				local slow = Config.mphToSps(RACE.UTurnMph)
				target = math.min(target, slow)
				npc.wantU -= dt
				if npc.wantU <= 0 then
					npc.wantU = nil
				elseif npc.speed < slow * 1.5 and (frameCount + _idx) % 15 == 0 then
					tryUTurn(npc, obstacleList)
				end
			end
			if (npc :: any).holdMerge then
				target = math.min(target, math.max(npc.speed * 0.9, 4)) -- (let the lane we must merge into go by; creep, never stand for good)
			end
		end
		local remaining = seg.length - npc.s
		local v0 = npc.speed

		-- (27 Nov) the way ahead, walked once: where each piece starts (lookAheadGap follows cars along it), and for
		-- everyday cars the next turn and the bends at the lane joints, braked for in time at PlanBrake (the 1:1 pieces
		-- are ~24 studs: one piece of warning was a jolt)
		table.clear(pathOff)
		pathOff[seg] = -npc.s
		local pathReach = math.max(T.LookAhead, v0 * T.Headway + v0 * v0 / (2 * T.PlanBrake) + 40)
		do
			local d, q, prev, k = remaining, npc.nextSeg, seg, 0
			local turnDone = npc.racer ~= nil or seg.kind == "turn"
			-- (turns and bends only matter within a comfortable stop; joint bends only for cars in sight)
			local brakeReach = v0 * v0 / (2 * T.PlanBrake) + 30
			local bends = ((npc :: any).camDist or 0) < 380
			while q and d < pathReach and k < 24 do
				if pathOff[q] == nil then
					pathOff[q] = d
				end
				if not turnDone and d < brakeReach then
					local v: number? = nil
					if q.kind == "turn" and q.dir ~= prev.dir then
						v = if q.turnSpeed then Config.mphToSps(q.turnSpeed) else TURN_SPEED
						turnDone = true
					elseif bends and q.kind ~= "turn" and prev.kind ~= "turn" then
						v = jointSpeed(prev, q)
					end
					if v and v < target then
						target = math.min(target, math.sqrt(v * v + 2 * T.PlanBrake * math.max(d, 0)))
					end
				end
				d += q.length
				prev = q
				k += 1
				q = planNext(npc, k, q)
			end
		end
		if not npc.racer then
			local prev = (npc :: any).prevSeg
			if prev and npc.s < 12 and seg.kind ~= "turn" and prev.kind ~= "turn" then
				target = math.min(target, jointSpeed(prev, seg)) -- (in the bend now)
			end
		end

		if seg.kind == "turn" then
			if seg.turning then
				target = math.min(target, if seg.turnSpeed then Config.mphToSps(seg.turnSpeed) else TURN_SPEED)
			end
		else
			-- traffic light at the end of this lane: the front bumper stops behind the stop line
			-- (owner, 2026-10-30: some cars stopped past it; the lane ends at the line's near edge)
			-- (owner, 2026-11-21: "npc cars doesnt wait for traffic lights, sometime") the 1:1 lane pieces are ~24 studs: a
			-- car that only saw the light once on its last piece could not stop from speed (a bus never could) and ran it.
			-- Look up to 4 pieces ahead for the next light, so braking starts in time
			local sigSeg, sigDist = nil, remaining
			if seg.signal then
				sigSeg = seg
			else
				-- (27 Nov: as far as a comfortable stop needs, not 160 studs)
				local q, k = npc.nextSeg, 0
				local sigReach = math.max(160, v0 * v0 / (2 * T.PlanBrake) + 40)
				while q and k < 16 and sigDist < sigReach do
					k += 1
					sigDist += q.length
					if q.signal then
						sigSeg = q
						break
					end
					if q.kind == "turn" then
						break -- (past a junction: that light is someone else's)
					end
					q = planNext(npc, k, q)
				end
			end
			local state = if sigSeg then CityLayout.lightState(sigSeg.i, sigSeg.j, sigSeg.axis, now) else "G"
			if state ~= "G" then
				local stopDist = sigDist - npc.halfLen - T.StopLineMargin
				local mustStop = state == "R"
				if state == "Y" then
					-- stop only if we can do it comfortably, otherwise clear the junction
					local needed = (npc.speed * npc.speed) / (2 * T.Brake)
					mustStop = stopDist > needed
				end
				if mustStop and stopDist > -2 then
					if stopDist < 0.3 then
						target = 0
					else
						target = math.min(target, math.sqrt(2 * T.PlanBrake * stopDist))
					end
				end
			end
		end

		-- speed bumps ahead (owner, 2026-11-03): ease down to BumpMph for them
		if bumpAhead(npc) then
			target = math.min(target, Config.mphToSps(T.BumpMph))
		end

		-- yield before turning left across oncoming traffic
		if seg.kind == "lane" then
			local nxt = npc.nextSeg
			if nxt and nxt.turning and nxt.dir == leftOf(seg.dir) and remaining < 30 + npc.halfLen and mustYieldLeft(npc, seg) then
				local stopDist = remaining - npc.halfLen - T.StopLineMargin
				target = if stopDist < 0.3 then 0 else math.min(target, math.sqrt(2 * T.PlanBrake * stopDist))
			end
		end

		-- cars / players ahead
		local crossBlocked = false
		if npc.ghost <= 0 then
			-- crossing traffic at a junction: give way to whoever gets there first
			-- (only where it can be seen: cars far from the camera skip it, it is the costliest check)
			local stopAt = if (npc.pos - camPos).Magnitude < 500 then crossConflict(npc, obstacleList) else nil
			if stopAt then
				target = if stopAt < 0.5 then 0 else math.min(target, math.sqrt(2 * T.PlanBrake * stopAt))
				crossBlocked = true -- (a true standoff still gets broken by the gridlock breaker)
			end
			local reach = if npc.racer then math.max(T.LookAhead, npc.speed * RACER.LookAheadS) else pathReach
			-- (a racer off its lane's middle has no lane path: its strip checks see for it)
			local gap, otherSpeed, align, isPlayer = lookAheadGap(npc, obstacleList, reach, if math.abs(npc.off) < 2 then pathOff else nil)
			-- (what it is waiting behind, for the honks: TrafficSounds)
			local ahead: any = npc
			ahead.gapNow, ahead.gapPlayer, ahead.gapAlign = gap, isPlayer, align
			-- (and a car already overlapping the one ahead, gap under 0, isn't a normal queue either:
			-- the gridlock breaker may take it through)
			crossBlocked = crossBlocked or (gap < math.huge and align < 0.7) or gap < 0
			if gap < math.huge then
				-- (owner, 2026-10-29: "NPC cars on each other's tail, make space for at least one
				-- car"): once moving, keep a car length plus a time gap; a stopped queue closes up
				-- (27 Nov: a real time gap, Headway 1.5 s; racers keep Racer.Headway)
				local keep = T.StopGap + (T.FollowGap - T.StopGap) * math.min(npc.speed / 8, 1) + npc.speed * (if npc.racer then RACER.Headway else T.Headway)
				local safe = gap - keep
				local brake = if npc.racer then RACER.Brake * 0.7 else T.PlanBrake
				if npc.racer and isPlayer then
					-- (owner, 2026-11-21: racers don't stop for a player's car, they move over and pass; was a 1 s wider gap and a full stop)
					target = TrafficMix.racerBehindPlayer(target, gap, keep, otherSpeed, math.abs(npc.offTo - npc.off) > 0.01)
				elseif safe <= 0 then
					-- (27 Nov) inside the gap (a car cut in, or it slowed): drop back a little under its pace, never a full
					-- stop for a car that is moving; a stop only right behind one that stops
					local floor = T.StopGap * 0.5
					target = math.min(target, otherSpeed * math.clamp((gap - floor) / math.max(keep - floor, 1), 0, 1))
				else
					target = math.min(target, math.sqrt(2 * brake * safe + otherSpeed * otherSpeed))
				end
			end
		else
			npc.ghost -= dt
		end

		-- racers: the strip swept over the next second (both lanes while changing) keeps a gap it can brake in
		if npc.racer then
			local gap, ov = racerSweep(npc, obstacleList)
			if gap < math.huge then
				local safe = gap - 3 - npc.speed * 0.15
				target = if safe <= 0 then math.min(target, ov * 0.9) else math.min(target, math.sqrt(2 * RACER.Brake * 0.7 * safe + ov * ov))
			end
		end

		-- integrate speed: the pull and the braking build up and ease off (no speed change in one frame)
		driveSpeed(npc, target, dt)
		setBrake(npc, npc.acc < -2 or npc.speed < 0.5)

		-- gridlock breaker: only for a true deadlock with crossing traffic,
		-- never for a normal queue or a car waiting at a light
		if npc.speed < 0.5 and crossBlocked then
			npc.stuck += dt
			if npc.stuck > T.StuckTime then
				npc.ghost = 2.5
				npc.stuck = 0
			end
		else
			npc.stuck = 0
		end

		-- advance along the path
		-- (a few hops at most: a run of very short connectors can't spin this forever)
		local snap = if npc.racer
			then { npc.seg, npc.s, npc.nextSeg, npc.plan and table.clone(npc.plan :: any), npc.off, npc.offTo, npc.pos, npc.fwd, (npc :: any).prevSeg }
			else nil
		-- (27 Nov, owner: "they go through each other sometimes") the last check before an everyday car moves: a step
		-- that would put its box into another car's is not taken (stepBlocked); it takes that car's pace instead
		local peekS, peekP, peekF = nil, nil, nil
		if not snap and npc.speed > 0 then
			local np, nf = peekPose(npc, npc.speed * dt)
			peekS, peekP, peekF = npc.s + npc.speed * dt, np, nf
			local hit = stepBlocked(npc, np, nf, obstacleList)
			if hit then
				npc.speed = math.min(npc.speed, math.max(0, hit.speed * hit.fwd:Dot(npc.fwd)) * 0.9)
				npc.acc = math.min(npc.acc, 0)
				np, nf = peekPose(npc, npc.speed * dt)
				if npc.speed > 0 and stepBlocked(npc, np, nf, obstacleList) then
					npc.speed = 0
				end
				npc.held += dt
				holds += 1
			else
				npc.held = 0
			end
		end
		npc.s += npc.speed * dt
		local hops = 0
		while npc.s >= npc.seg.length do
			hops += 1
			if hops > 8 then
				npc.s = npc.seg.length
				break
			end
			npc.s -= npc.seg.length
			local nxt = npc.nextSeg
			if nxt then
				(npc :: any).prevSeg = npc.seg
			end
			if not nxt then
				-- a lane with no way on (owner, 2026-11-04: "the cars are bugging here"): the car used
				-- to jump back to the start of its last piece, into the car behind, and the queue
				-- piled up on top of itself. Now it waits at the end and the next recycle moves it
				-- out of sight.
				npc.s = npc.seg.length
				npc.speed = 0
				npc.deadEnd = true
				break
			end
			npc.seg = nxt
			local plan = npc.plan
			npc.nextSeg = if plan and plan[1] then table.remove(plan, 1) else raceNext(npc, nxt)
		end
		if npc.racer then
			racerSide(npc, dt, obstacleList)
		end

		-- (27 Nov: every car rounds the lane joints now, not only racers: the nose snapped there, and the body roll and
		-- steering read it as a jolt)
		local pos, fwd
		if peekS == npc.s and peekS <= npc.seg.length then
			pos, fwd = peekP, peekF -- (the step's own pose, already sampled by the check)
		else
			pos, fwd = racerSample(npc, npc.seg, npc.s)
		end
		if npc.racer then
			-- a racer beside its lane's middle (sliding over, or on the line between two lanes)
			local right = fwd:Cross(Vector3.yAxis)
			pos += right * npc.off
		end
		-- racers never move into another car: a step that comes within a hair of a new car, or deeper into a real
		-- overlap, is undone and the racer takes that car's speed; a slide sideways is checked all round, and when
		-- only the slide touches the racer drives on straight while the slide waits
		if snap then
			local slid = npc.off ~= snap[5]
			local hit = racerBlocked(npc, pos, fwd, snap[7], snap[8], obstacleList, slid)
			if hit and slid then
				local p2, f2 = racerSample(npc, npc.seg, npc.s)
				p2 += f2:Cross(Vector3.yAxis) * (snap[5] :: number)
				if not racerBlocked(npc, p2, f2, snap[7], snap[8], obstacleList, false) then
					npc.off, npc.offTo = snap[5], snap[5];
					(npc :: any).lc, (npc :: any).offV, (npc :: any).offA = nil, 0, 0
					npc.sideT = math.max(npc.sideT, RACER.SideHold) -- (no new slide try 0.2 s later: a wobble)
					pos, fwd, hit = p2, f2, nil
				end
			end
			if hit then
				npc.seg, npc.s, npc.nextSeg, npc.plan, npc.off, npc.offTo = snap[1], snap[2], snap[3], snap[4], snap[5], snap[5];
				(npc :: any).prevSeg = snap[9];
				(npc :: any).lc, (npc :: any).offV, (npc :: any).offA = nil, 0, 0
				pos, fwd = snap[7], snap[8]
				npc.sideT = math.max(npc.sideT, RACER.SideHold)
				npc.speed = math.min(npc.speed, math.max(0, hit.speed * hit.fwd:Dot(fwd)) * 0.9)
				npc.model:SetAttribute("RacerHolds", (npc.model:GetAttribute("RacerHolds") or 0) + 1)
			end
		end
		npc.pos = pos
		npc.fwd = fwd
		-- (owner, 2026-11-21: racers behind a car swung their nose ~45 degrees side to side while going straight) the
		-- nose follows only the sideways move that really happened this frame, eased, at most 19 degrees at any speed;
		-- it used to lean toward the wanted lane even while the slide was blocked and undone
		local look = fwd
		if npc.racer then
			local u = npc :: any
			local lastOff = u.prevOff or npc.off
			u.prevOff = npc.off
			local cap = npc.speed * 0.35
			local want = math.clamp((npc.off - lastOff) / math.max(dt, 1 / 240), -cap, cap)
			local sv = (u.slideV or 0) + math.clamp(want - (u.slideV or 0), -RACER.YawRate * dt, RACER.YawRate * dt)
			sv = math.clamp(sv, -cap, cap)
			u.slideV = sv
			if math.abs(sv) > 0.05 and npc.speed > 1 then
				look = (fwd * npc.speed + fwd:Cross(Vector3.yAxis) * sv).Unit
			end
		end
		-- (far cars think every 3rd frame; their transform goes every frame, see the top of the loop)
		local dist = (pos - camPos).Magnitude;
		(npc :: any).camDist = dist
		-- (27 Nov) cars close enough to notice: wheels spin at the real speed for their size, the front ones steer by the
		-- path's turn, and the body rolls out of a corner or lane change, dips braking and squats pulling away
		npc.spin = (npc.spin - npc.speed * dt / npc.wheelR) % (math.pi * 2)
		if dist < 160 and not (dist > 40 and (pos - camPos):Dot(camLook) < 0) then
			bodyMotion(npc, look, (npc.speed - v0) / math.max(dt, 1 / 240), dt)
		else
			(npc :: any).lastLook = nil
		end
		-- cars near you tell the physics how fast they're going (moved by CFrame they'd count as
		-- standing still, and a touch at speed flung the player's car: owner, 2026-10-24)
		if dist < 140 then
			npc.root.AssemblyLinearVelocity = fwd * npc.speed
		end
		-- (2026-11-26, FPS: BulkMoveTo was over half of this function) a car behind the camera and not right
		-- beside it is out of view: its transform goes every 3rd frame too, like a far one
		local unseen = dist > 40 and (pos - camPos):Dot(camLook) < 0
		if not unseen or (frameCount + _idx) % 3 == 0 then
			local up = Vector3.new(0, npc.height / 2, 0)
			table.insert(movedParts, npc.root)
			table.insert(movedCFrames, CFrame.lookAt(pos + up, pos + up + look))
		end
	end

	workspace:BulkMoveTo(movedParts, movedCFrames, Enum.BulkMoveMode.FireCFrameChanged)

	-- recycle far cars to just out of sight around the focus point
	recycleTimer += dt
	if recycleTimer > 0.5 and focusGetter then
		recycleTimer = 0
		if folder then
			folder:SetAttribute("Holds", holds)
		end
		local focus = focusGetter()
		if focus then
			local flatFocus = Vector3.new(focus.X, 0, focus.Z)
			local moved = 0
			for i, npc in Traffic.cars do
				if moved >= 3 then
					break
				end
				-- (flat: with the car's height in it, a mountain road 215 up counted as 215 further
				-- away, and cars turning off a route there were whisked away right in front of you;
				-- owner, 2026-11-04: "the cars are bugging here")
				local away = Vector3.new(npc.pos.X - flatFocus.X, 0, npc.pos.Z - flatFocus.Z).Magnitude
				-- (a car that wandered off the routes goes back to one once it's out of the way)
				local offRoute = (npc.seg :: any).riviera and not (npc.seg :: any).route
				-- (a busy stretch over its number sends a car out of your sight somewhere else round you)
				local zone = zoneOf(npc.pos)
				local crowded = false
				if zone and zoneCars[zone] > T.BusyZones[zone].max and away > T.RespawnMin then
					local cam = workspace.CurrentCamera
					crowded = not cam or (npc.pos - cam.CFrame.Position).Unit:Dot(cam.CFrame.LookVector) < 0.55
				end
				local limit = if npc.racer then RACER.Recycle else T.RecycleDistance
				if npc.racer and away > limit then
					-- (owner, 2026-11-21: "i keep on spotting them") a racer that has gone is taken off the road, not
					-- moved back near the player; a fresh car takes its place in the list, out of sight (the
					-- normal spawn roll, TrafficMix.RareChance under the caps, decides if it is a rare one)
					local new = spawnNpc(flatFocus, npc.highway)
					if new then
						Traffic.cars[i] = table.remove(Traffic.cars) :: Npc
						npc.model:Destroy()
						local seg, s = findSpot(flatFocus, T.RespawnMin, T.RespawnMax, new, true, new.highway)
						if seg then
							placeNpc(new, seg, s)
							new.model:PivotTo(CFrame.lookAt(new.pos, new.pos + new.fwd) + Vector3.new(0, new.height / 2, 0))
						end
						moved += 1
					end
				elseif away > limit or (offRoute and away > T.StreetRecycle) or npc.deadEnd or crowded
					or (npc.held > 12 and ((npc :: any).camDist or 0) > 150) then -- (held 12 s by the no-overlap check: a knot, untied out of view)
					local seg, s = findSpot(flatFocus, T.RespawnMin, T.RespawnMax, npc, true, npc.highway)
					if seg then
						placeNpc(npc, seg, s)
						npc.speed = npc.maxSpeed * 0.8
						moved += 1
					end
				end
			end
		end
	end
end

-- Move NPCs out of the way (used when a player car spawns)
-- (2026-11-04: these two measured from y 0 against the cars' real heights, so above ~40 studs, most
-- of the Riviera, nothing was ever near: no cut-ups up there, and a car brought out on a hill
-- road wasn't cleared of traffic. Now flat distance, and within a storey of the given height.)
local function nearXZ(npc: Npc, pos: Vector3, radius: number): boolean
	local dx, dz = npc.pos.X - pos.X, npc.pos.Z - pos.Z
	return dx * dx + dz * dz < radius * radius and math.abs(npc.pos.Y - pos.Y) < 15
end

function Traffic.clearAround(pos: Vector3, radius: number)
	local flat = Vector3.new(pos.X, 0, pos.Z)
	for _, npc in Traffic.cars do
		if nearXZ(npc, pos, radius) then
			local seg, s = findSpot(flat, T.RespawnMin, T.RespawnMax, npc, true, npc.highway)
			if seg then
				placeNpc(npc, seg, s)
			end
		end
	end
end

-- Cars currently near a point (used for cut-up detection): pos at its real height
function Traffic.near(pos: Vector3, radius: number): { Npc }
	local out = {}
	for _, npc in Traffic.cars do
		if nearXZ(npc, pos, radius) then
			table.insert(out, npc)
		end
	end
	return out
end

-- (2026-11-26) a traffic lane passes within r studs (flat) of pos, at pos's height give or take dy: Driving's safety
-- floor asks it when the road under a fast car hasn't streamed in (the lanes are data, always there)
function Traffic.laneAt(pos: Vector3, r: number, dy: number): boolean
	for _, lanes in { cityLanes, highwayLanes } do
		if #lanes > 0 then
			for _, seg in lanesNear(lanes, pos, r) do
				local b = laneBox[seg]
				if pos.Y >= b[1].Y - dy and pos.Y <= b[2].Y + dy then
					return true
				end
			end
		end
	end
	return false
end

return Traffic
