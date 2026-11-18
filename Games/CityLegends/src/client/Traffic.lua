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
local RACER = TrafficMix.Racer
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
	plan: { CityLayout.Segment }?, -- the way chosen past nextSeg (racers brake for bends far ahead)
	holdMerge: boolean?, -- a racer waiting to merge back before a junction
}

type Obstacle = { pos: Vector3, fwd: Vector3, speed: number, halfLen: number, width: number, self: Npc? }

local Traffic = {}
local bumpAhead: (Npc) -> boolean
Traffic.cars = {} :: { Npc }

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
local function lanesNear(lanes: { CityLayout.Segment }, center: Vector3, maxDist: number): { CityLayout.Segment }
	table.clear(nearby)
	for _, seg in lanes do
		local b = laneBox[seg]
		local dx = math.max(b[1].X - center.X, 0, center.X - b[2].X)
		local dz = math.max(b[1].Z - center.Z, 0, center.Z - b[2].Z)
		if dx * dx + dz * dz <= maxDist * maxDist then
			table.insert(nearby, seg)
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
	local gap = if highway then T.HighwayGap else 22
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
	for _, j in (model.PrimaryPart :: BasePart):GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
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
	}
	local racerMph = model:GetAttribute("RacerMph")
	if type(racerMph) == "number" then
		npc.racer = Config.mphToSps(racerMph)
		npc.maxSpeed = npc.racer :: number
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

function Traffic.start(count: number?, focus: (() -> Vector3?)?)
	if running then
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

local function lookAheadGap(npc: Npc, obstacles: { Obstacle }, reach: number?): (number, number, number, boolean)
	-- returns the bumper-to-bumper gap to the nearest thing in our path and its speed along our heading
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	local best, bestSpeed, bestAlign, bestPlayer = math.huge, 0, 1, false
	local look = reach or T.LookAhead
	-- (2026-11-04) a car changing lanes (a route's outer lane merging before its end) gives way to
	-- the cars in the lane it moves into; they don't wait for it while it is beside them
	local meChanging = (npc.seg :: any).laneChange == true
	for _, o in obstacles do
		if o.self ~= npc then
			local rel = o.pos - npc.pos
			local f = rel:Dot(fwd)
			-- (a car on a road above or below, a bridge or a tunnel, isn't in our way)
			if f > 0 and f < look and math.abs(rel.Y) < 12 then
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
						bestAlign = o.fwd:Dot(fwd)
						bestPlayer = o.self == nil
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
-- the safe speed through a piece from its bend (a quadratic bezier: its turn angle over its length = 1 / radius)
local bendCache: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local function bendSpeed(q: CityLayout.Segment): number
	local v = bendCache[q]
	if v == nil then
		local a = (q.p1 - q.p0) * Vector3.new(1, 0, 1)
		local b = (q.p2 - q.p1) * Vector3.new(1, 0, 1)
		local th = if a.Magnitude > 0.1 and b.Magnitude > 0.1 then math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)) else 0
		v = if th < 0.02 then math.huge else math.sqrt(RACER.LatAccel * q.length / th)
		bendCache[q] = v
	end
	return v :: number
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
		q = chooseNext(prev)
		if q then
			(plan :: any)[i] = q
		end
	end
	return q
end

-- the highest speed now that still lets a racer slow for every bend, turn and red light within braking distance
local function racerCap(npc: Npc, now: number): number
	local seg = npc.seg
	local cap = bendSpeed(seg)
	local d = seg.length - npc.s
	local reach = npc.speed * npc.speed / (2 * RACER.Brake) + 80
	local q = npc.nextSeg
	local prev = seg
	local i = 0
	while q and d < reach and i < 14 do
		local v = bendSpeed(q)
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
					if f > -side - closing * 1.5 and f < side then
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

-- another racer beside this one on the side it would slide to (the two yield: neither slides into the other)
local function racerBeside(npc: Npc, dir: number): boolean
	local fwd = npc.fwd
	local right = fwd:Cross(Vector3.yAxis)
	for _, o in Traffic.cars do
		if o ~= npc and o.racer then
			local rel = o.pos - npc.pos
			local lat = rel:Dot(right)
			if math.abs(rel.Y) < 12 and math.abs(rel:Dot(fwd)) < npc.halfLen + o.halfLen + 8 and lat * dir > 0 and math.abs(lat) < 16 then
				return true
			end
		end
	end
	return false
end

-- the car a racer's box (plus a hair) would overlap at pos / fwd, using each car's latest place this frame
local function racerHit(npc: Npc, pos: Vector3, fwd: Vector3, obstacles: { Obstacle }, m: number): (Obstacle?, number)
	local r = fwd:Cross(Vector3.yAxis)
	local hl, hw = npc.halfLen + 0.4 * m, npc.width / 2 + 0.25 * m
	for _, o in obstacles do
		local me = o.self
		if me ~= npc then
			local op = if me then me.pos else o.pos
			local of = if me then me.fwd else o.fwd
			local d = op - pos
			if math.abs(d.Y) < 8 and d.Magnitude < hl + o.halfLen + 12 then
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
	local n = #spots
	for k = 1, n - 1 do
		table.insert(spots, { lat = (spots[k].lat + spots[k + 1].lat) / 2, seg = nil })
	end
	return spots
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
	elseif npc.sideT <= 0 then
		npc.sideT = 0.2
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
	end
	-- slide, but only into a strip that is clear beside us and has room ahead to brake in (sliding in at speed
	-- right behind a slow car rear-ended it in the first test); if a merge back before a junction can't be made,
	-- hold back (holdMerge) until it can
	local delta = npc.offTo - npc.off
	npc.holdMerge = nil
	if math.abs(delta) > 0.01 then
		local step = math.clamp(npc.speed * RACER.SideRate, 7, 22) * dt
		local to = npc.off + math.clamp(delta, -step, step)
		local reach = math.max(T.LookAhead, npc.speed * RACER.LookAheadS)
		local ahead, clear, aheadV = stripGap(npc, npc.offTo, obstacles, reach)
		local nowAhead, clearNow, nowV = stripGap(npc, to, obstacles, T.LookAhead)
		-- (gap scaled by the closing speed, in the lane we go to and on the way there; a racer beside yields)
		if clear and clearNow and ahead > racerRoom(npc.speed, aheadV) and nowAhead > racerRoom(npc.speed, nowV) * 0.5
			and not racerBeside(npc, math.sign(delta)) then
			npc.off = to
		elseif settle then
			npc.holdMerge = true
		else
			npc.offTo = npc.off -- (that gap closed: stay)
		end
	end
	-- over another lane's middle: that lane is ours now (its way on through the next junction)
	if not settle and math.abs(npc.off) > 2 then
		for _, sp in racerSpots(npc) do
			local o = sp.seg
			if o and o ~= seg and math.abs(sp.lat - npc.off) < 0.5 then
				npc.off -= sp.lat
				npc.offTo -= sp.lat
				npc.s = math.clamp(npc.s * o.length / seg.length, 0, o.length)
				npc.seg = o
				npc.nextSeg = chooseNext(o)
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
local function crossConflict(npc: Npc, obstacles: { Obstacle }): number?
	local seg, nxt = npc.seg, npc.nextSeg
	-- (the next piece: a turn through the junction, or a lane piece that runs across another road)
	if seg.kind ~= "lane" or not nxt or not (nxt :: any).riviera then
		return nil
	end
	local toEnd = seg.length - npc.s - npc.halfLen - T.StopLineMargin
	if toEnd < -1 or toEnd > 30 then
		return nil
	end
	local C = conflictsOf(nxt)
	local me = indexOf(npc)
	local vMe = math.max(npc.speed, 5)
	for _, o in Traffic.cars do
		if o ~= npc and (o.pos - npc.pos).Magnitude < 120 then
			local P = C[o.seg] or (if o.nextSeg then C[o.nextSeg] else nil)
			if P then
				local toP = P - o.pos
				local ahead = toP:Dot(o.fwd) -- how far the spot is ahead of that car's middle
				local dist = Vector3.new(toP.X, 0, toP.Z).Magnitude
				if dist < o.halfLen + 4 and (o.speed > 0.5 or ahead < o.halfLen * 0.5) then
					-- it is on the spot right now (a car stopped short of it, waiting its turn, isn't)
					return math.max(0, toEnd)
				elseif ahead > 0 and dist < 40 and o.speed > 0.5 then
					-- it is heading for the spot: whoever gets there first goes
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
	-- a player's car near the junction: wait for it
	local jp = nxt.p1
	for _, pc in playerCarCache do
		if (pc.pos - jp).Magnitude < 40 and pc.speed > 3 then
			return math.max(0, toEnd)
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

function Traffic.update(dt: number)
	if not running or #Traffic.cars == 0 then
		return
	end
	dt = math.min(dt, 0.1)
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

	table.clear(movedParts)
	table.clear(movedCFrames)
	frameCount += 1
	local camPos = if workspace.CurrentCamera then workspace.CurrentCamera.CFrame.Position else Vector3.zero

	for _idx, npc in Traffic.cars do
		-- (2026-11-06, FPS: a car far from the camera thinks every 3rd frame, with the time saved up)
		local dt = dt0
		if not npc.racer and ((npc :: any).camDist or 0) > 380 then
			(npc :: any).bank = ((npc :: any).bank or 0) + dt0
			if (frameCount + _idx) % 3 ~= 0 then
				continue
			end
			dt = (npc :: any).bank;
			(npc :: any).bank = 0
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
			target = math.min(npc.racer * (1 + 0.03 * math.sin(now * npc.wanderRate + npc.wanderPhase)), racerCap(npc, now))
			if (npc :: any).holdMerge then
				target = math.min(target, npc.speed * 0.9) -- (let the lane we must merge into go by)
			end
		end
		local remaining = seg.length - npc.s

		if seg.kind == "turn" then
			if seg.turning then
				target = math.min(target, if seg.turnSpeed then Config.mphToSps(seg.turnSpeed) else TURN_SPEED)
			end
		else
			-- slow down before a turn
			local nxt = npc.nextSeg
			if nxt and nxt.dir ~= seg.dir then
				local turnV = if nxt.turnSpeed then Config.mphToSps(nxt.turnSpeed) else TURN_SPEED
				target = math.min(target, math.sqrt(turnV * turnV + 2 * T.Brake * 0.5 * math.max(remaining, 0)))
			end
			-- traffic light at the end of this lane: the front bumper stops behind the stop line
			-- (owner, 2026-10-30: some cars stopped past it; the lane ends at the line's near edge)
			local state = if seg.signal then CityLayout.lightState(seg.i, seg.j, seg.axis, now) else "G"
			if state ~= "G" then
				local stopDist = remaining - npc.halfLen - T.StopLineMargin
				local mustStop = state == "R"
				if state == "Y" then
					-- stop only if we can do it comfortably, otherwise clear the junction
					local needed = (npc.speed * npc.speed) / (2 * T.Brake * 0.6)
					mustStop = stopDist > needed
				end
				if mustStop and stopDist > -2 then
					if stopDist < 0.3 then
						target = 0
					else
						target = math.min(target, math.sqrt(2 * T.Brake * 0.6 * stopDist))
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
				target = if stopDist < 0.3 then 0 else math.min(target, math.sqrt(2 * T.Brake * 0.6 * stopDist))
			end
		end

		-- cars / players ahead
		local crossBlocked = false
		if npc.ghost <= 0 then
			-- crossing traffic at a junction: give way to whoever gets there first
			-- (only where it can be seen: cars far from the camera skip it, it is the costliest check)
			local stopAt = if (npc.pos - camPos).Magnitude < 500 then crossConflict(npc, obstacleList) else nil
			if stopAt then
				target = if stopAt < 0.5 then 0 else math.min(target, math.sqrt(2 * T.Brake * 0.7 * stopAt))
				crossBlocked = true -- (a true standoff still gets broken by the gridlock breaker)
			end
			local reach = if npc.racer then math.max(T.LookAhead, npc.speed * RACER.LookAheadS) else nil
			local gap, otherSpeed, align, isPlayer = lookAheadGap(npc, obstacleList, reach)
			-- (and a car already overlapping the one ahead, gap under 0, isn't a normal queue either:
			-- the gridlock breaker may take it through)
			crossBlocked = crossBlocked or (gap < math.huge and align < 0.7) or gap < 0
			if gap < math.huge then
				-- (owner, 2026-10-29: "NPC cars on each other's tail, make space for at least one
				-- car"): once moving, keep a car length plus a time gap; a stopped queue closes up
				local keep = T.StopGap + (T.FollowGap - T.StopGap) * math.min(npc.speed / 8, 1) + npc.speed * T.Headway
				if npc.racer and isPlayer then
					keep += npc.speed * RACER.PlayerGap -- (a wide berth: players always have the way)
				end
				local safe = gap - keep
				local brake = if npc.racer then RACER.Brake else T.Brake
				if safe <= 0 then
					target = 0
				else
					target = math.min(target, math.sqrt(2 * brake * 0.7 * safe + otherSpeed * otherSpeed))
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

		-- integrate speed
		if npc.speed < target then
			npc.speed = math.min(target, npc.speed + (if npc.racer then RACER.Accel else T.Accel) * dt)
		else
			local decel = if npc.speed - target > 18 then T.EmergencyBrake else T.Brake
			npc.speed = math.max(target, npc.speed - decel * dt)
		end
		setBrake(npc, target < npc.speed - 0.5 or npc.speed < 0.5)

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
			then { npc.seg, npc.s, npc.nextSeg, npc.plan and table.clone(npc.plan :: any), npc.off, npc.offTo, npc.pos, npc.fwd }
			else nil
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
			npc.nextSeg = if plan and plan[1] then table.remove(plan, 1) else chooseNext(nxt)
		end
		if npc.racer then
			racerSide(npc, dt, obstacleList)
		end

		local pos, fwd = CityLayout.sample(npc.seg, npc.s)
		if npc.off ~= 0 then
			-- a racer beside its lane's middle (sliding over, or on the line between two lanes)
			local right = fwd:Cross(Vector3.yAxis)
			pos += right * npc.off
			local slide = npc.offTo - npc.off
			if math.abs(slide) > 0.3 and npc.speed > 1 then
				fwd = (fwd * npc.speed + right * math.sign(slide) * math.clamp(npc.speed * RACER.SideRate, 7, 22)).Unit
			end
		end
		-- racers never move into another car: a step that comes within a hair of a new car, or into a real overlap
		-- with one already that close (two racers nose to nose at a turn may still creep apart), is undone and the
		-- racer takes that car's speed
		if snap then
			local hit = racerHit(npc, pos, fwd, obstacleList, 1)
			local block = false
			if hit then
				if racerHit(npc, snap[7], snap[8], obstacleList, 1) ~= hit then
					block = true
				else
					local real, d = racerHit(npc, pos, fwd, obstacleList, 0)
					if real then
						local was, d0 = racerHit(npc, snap[7], snap[8], obstacleList, 0)
						block = was ~= real or d < d0
						hit = real
					end
				end
			end
			if hit and block then
				npc.seg, npc.s, npc.nextSeg, npc.plan, npc.off, npc.offTo = snap[1], snap[2], snap[3], snap[4], snap[5], snap[5]
				pos, fwd = snap[7], snap[8]
				npc.speed = math.min(npc.speed, math.max(0, hit.speed * hit.fwd:Dot(fwd)) * 0.9)
				npc.model:SetAttribute("RacerHolds", (npc.model:GetAttribute("RacerHolds") or 0) + 1)
			end
		end
		npc.pos = pos
		npc.fwd = fwd
		-- far-away cars only need their transform pushed every 3rd frame
		local dist = (pos - camPos).Magnitude
		local far = dist > 380;
		(npc :: any).camDist = dist
		-- spin the wheels of cars close enough to notice
		npc.spin = (npc.spin - npc.speed * dt / 1.1) % (math.pi * 2)
		if dist < 160 then
			local spinCF = CFrame.Angles(npc.spin, 0, 0)
			for _, w in npc.wheels do
				w.Transform = spinCF
			end
		end
		-- cars near you tell the physics how fast they're going (moved by CFrame they'd count as
		-- standing still, and a touch at speed flung the player's car: owner, 2026-10-24)
		if dist < 140 then
			npc.root.AssemblyLinearVelocity = fwd * npc.speed
		end
		if not far or (frameCount + _idx) % 3 == 0 then
			local up = Vector3.new(0, npc.height / 2, 0)
			table.insert(movedParts, npc.root)
			table.insert(movedCFrames, CFrame.lookAt(pos + up, pos + up + fwd))
		end
	end

	workspace:BulkMoveTo(movedParts, movedCFrames, Enum.BulkMoveMode.FireCFrameChanged)

	-- recycle far cars to just out of sight around the focus point
	recycleTimer += dt
	if recycleTimer > 0.5 and focusGetter then
		recycleTimer = 0
		local focus = focusGetter()
		if focus then
			local flatFocus = Vector3.new(focus.X, 0, focus.Z)
			local moved = 0
			for _, npc in Traffic.cars do
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
				if away > limit or (offRoute and away > T.StreetRecycle) or npc.deadEnd or crowded then
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

return Traffic
