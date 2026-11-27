--[[
	TrafficMix (2026-11-19, owner: "it should be the cars that are common irl in yangon"; "they should use the cars
	from the cars that i already made by hand")
	Which NPC car spawns how often. Every entry is a template in ReplicatedStorage.TrafficModels named
	Traffic_<kind>_<id>: the roster's own cars as light copies (tools/yangon/TrafficLOD.luau: exterior only, no cabin,
	no textures, plain colours) and our own low-poly Probox / Hiace / Carry / YBS bus (tools/yangon_traffic_cars.py).
	Research: vault City Legends/2026-11-19 Research - Yangon common traffic cars.md.

	len = real length in studs (3 a metre); w = weight in the everyday mix; paint = the livery colours picked from;
	main = only on main roads (lanes with a lane beside them); rare = cap group (Rare below) for the supercars, which
	drive as racers (Traffic.lua) at top mph on straights.
	(Config.lua is at its 199k sync limit: traffic tables live here.)
]]

local Cars = require(script.Parent:WaitForChild("Cars"))

local TrafficMix = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Yangon's colour mix (photos + sources): white ~45%, silver ~25%, black ~10%, dark grey 5%, the rest 15%
local WHITE, PEARL, SILVER, GREY, BLACK = rgb(236, 237, 238), rgb(226, 224, 216), rgb(176, 179, 184), rgb(92, 95, 100), rgb(22, 23, 26)
local RED, BLUE, CHAMP, GREEN = rgb(150, 24, 28), rgb(34, 58, 110), rgb(196, 182, 150), rgb(40, 74, 58)
local EVERYDAY = { WHITE, WHITE, WHITE, PEARL, WHITE, SILVER, SILVER, SILVER, BLACK, BLACK, GREY, RED, BLUE, CHAMP, GREEN }
local LIGHT = { WHITE, WHITE, WHITE, SILVER, SILVER, PEARL } -- taxis, vans, kei trucks
-- YBS route-group colours (Myanmore guide) + the newer yellow / white Chinese fleet
local YBS = { rgb(28, 82, 168), rgb(186, 32, 36), rgb(36, 132, 64), rgb(110, 50, 140), rgb(122, 76, 44), rgb(236, 186, 30), rgb(236, 186, 30) }
local SUPER = { rgb(200, 14, 22), rgb(240, 170, 10), rgb(240, 240, 240), rgb(20, 20, 22), rgb(30, 90, 200), rgb(120, 190, 40) }

export type Entry = {
	id: string,
	kind: string,
	len: number,
	w: number,
	paint: { Color3 },
	main: boolean?,
	rare: string?,
	mph: number?,
	trim: string?, -- a rare car's fixed trim (TrimSpeed)
}

TrafficMix.Entries = {
	-- everyday Yangon (shares in the vault note; w = per cent of spawns)
	{ id = "probox", kind = "A", len = 12.7, w = 18, paint = LIGHT }, -- Probox / Succeed: the taxi and van of Yangon
	{ id = "suzaki_swift", kind = "A", len = 11.6, w = 12, paint = EVERYDAY }, -- Swift: most common private car
	{ id = "toyoka_belta", kind = "E", len = 12.9, w = 12, paint = EVERYDAY }, -- Belta / Vios / Corolla saloons
	{ id = "toyoka_chaser", kind = "E", len = 14.1, w = 9, paint = EVERYDAY }, -- Mark II / Chaser ("shwe nga")
	{ id = "toyoka_camri", kind = "E", len = 14.6, w = 7, paint = EVERYDAY }, -- Camry / Axio-size saloons
	{ id = "toyoka_crown", kind = "E", len = 14.7, w = 4, paint = { WHITE, BLACK, BLACK, SILVER, PEARL } },
	{ id = "toyoka_alfard", kind = "B", len = 14.6, w = 6, paint = { WHITE, PEARL, BLACK, SILVER } }, -- Alphard / Wish / Noah
	{ id = "hiace", kind = "C", len = 14.5, w = 6, paint = LIGHT }, -- Hiace vans and line ferries
	{ id = "carry", kind = "H", len = 10.2, w = 6, paint = LIGHT }, -- Carry / Hijet kei trucks
	{ id = "ybs", kind = "D", len = 33.0, w = 2, paint = YBS, main = true }, -- YBS buses, main roads only (owner, 2026-11-21: "spawn less ybs bus"; was 6)
	{ id = "toyoka_lc200", kind = "F", len = 14.9, w = 4, paint = { WHITE, BLACK, SILVER, PEARL } }, -- Land Cruiser / Hilux Surf / Prado
	{ id = "byt_seal", kind = "E", len = 14.4, w = 5, paint = { WHITE, SILVER, BLUE, GREY } }, -- BYD and the other EVs: top new-car brand 2024-25 (the EV6 copy came out with holes: left out)
	{ id = "toyoka_lc300", kind = "F", len = 15.0, w = 2, paint = { WHITE, BLACK, PEARL } }, -- the few luxury SUVs
	{ id = "lexis_lx700", kind = "F", len = 15.3, w = 1, paint = { BLACK, WHITE, PEARL } },
	-- rare supercars (owner, 19 Nov): racers, capped per group (Rare)
	-- (owner, 2026-11-21: "make all the rare car not have the same color or trim and set color,trim ... for every
	-- server and game") one fixed colour and one fixed trim each, no two the same pair; the trim scales its top speed
	-- (TrimSpeed)
	{ id = "nisun_gtr", kind = "R", len = 14.1, w = 0, paint = { rgb(200, 90, 20) }, trim = "TOP", rare = "gtr", mph = 150 },
	{ id = "nisun_r34", kind = "R", len = 13.8, w = 0, paint = { rgb(40, 60, 150) }, trim = "SPORT", rare = "r34", mph = 130 },
	{ id = "ferrara_599", kind = "R", len = 14.0, w = 0, paint = { rgb(200, 14, 22) }, trim = "BASE", rare = "ferrari", mph = 185 },
	{ id = "ferrara_california", kind = "R", len = 13.9, w = 0, paint = { rgb(240, 240, 240) }, trim = "SPORT", rare = "ferrari", mph = 170 },
	{ id = "lambrini_huracan", kind = "R", len = 13.4, w = 0, paint = { rgb(120, 190, 40) }, trim = "TOP", rare = "lambo", mph = 185 },
	{ id = "lambrini_lp570", kind = "R", len = 13.1, w = 0, paint = { rgb(240, 170, 10) }, trim = "SPORT", rare = "lambo", mph = 190 },
	{ id = "bugotti_chiron", kind = "R", len = 13.6, w = 0, paint = { rgb(20, 20, 22) }, trim = "BASE", rare = "bugatti", mph = 220 },
} :: { Entry }

-- the most of each rare group on the road at once (counted over all live traffic: traffic is per client, so this is
-- per player's view of the map)
TrafficMix.Rare = { ferrari = 2, lambo = 2, gtr = 2, r34 = 1, bugatti = 1 } -- (owner, 21 Nov evening: "make rare cars more common"; was 1 each after "i keep on spotting them"; before that 2 / 2 / 10 / 3 / 1)
TrafficMix.TrimSpeed = { BASE = 1, SPORT = 1.05, TOP = 1.1 } -- (a rare car's top speed by its trim: the dealer's trim steps)
TrafficMix.RareChance = 0.03 -- (21 Nov evening, owner: "make rare cars more common"; was 0.01, and 0.07 before that) of each spawn, the share that tries a rare car (a group under its cap)
-- (owner, 2026-11-21: "sometimes the ybs and taxis need to be fast") the share of YBS buses and Probox taxis that
-- hurry, and their top speed in mph (everyday cars: Config.Traffic 24..54)
TrafficMix.Hurry = { ids = { ybs = true, probox = true }, chance = 0.3, mph = { 62, 80 } }

-- racer driving (Traffic.lua profile "racer")
TrafficMix.Racer = {
	MinMph = 100, -- cruise at least this on a lane whose bends allow it
	Accel = 24, -- studs/s^2 (about 0.85 g, a supercar's launch; 27 Nov: was 40)
	Brake = 40, -- studs/s^2 used for planning (about 1.4 g at G = 28; 27 Nov: was 95, 3.4 g)
	MaxBrake = 48, -- the hardest a racer really brakes (Config.Traffic.EmergencyBrake for everyday cars)
	Headway = 0.6, -- s of travel kept behind a car ahead (everyday cars: Config.Traffic.Headway)
	LaneChangeS = 2.4, -- (27 Nov, owner: "the cut up is just a car rotated") seconds a whole-lane move takes at speed: an S-curve
	TurnSlowPerDeg = 0.03, -- (owner, 2026-11-21: "rare cars slow down on turn every 1 degree = 3% slower ... 10 degrees = 30% slower so 100 mph to 70 mph"; was a 0.9 g bend rule)
	LookAheadS = 2.6, -- seconds of travel looked ahead for cars (at least Config.Traffic.LookAhead)
	PassGap = 4, -- studs: closer than this behind a player's car a racer never rolls forward
	PassCreep = 6, -- studs/s it keeps rolling while it moves over to pass a slow or stopped player
	Recycle = 1500, -- flat studs from the focus before a racer is taken off the road (owner, 2026-11-21: "i keep on spotting them": it used to be moved back near the player; a fresh car from the normal spawn roll takes its place now)
	SideHold = 1, -- s after choosing a sideways target before choosing another (owner, 2026-11-21: no wobble from a slide re-picked 0.2 s later)
	SideRate = 0.14, -- lateral studs/s per stud/s of speed (lane change speed), clamped 7..22
	YawRate = 60, -- studs/s^2 the sideways lean of a lane change eases in and out at
}

-- (owner, 2026-11-21: "dont make the rare car ai stop for players cars, make them cut up by merging into another
-- lane if the lane is open") a racer's speed limit behind a player's car: brake only down to the player's speed at
-- the normal gap (never to a stop the player isn't making), and keep rolling while it is moving over to a free strip
function TrafficMix.racerBehindPlayer(target: number, gap: number, keep: number, playerSpeed: number, movingOver: boolean): number
	local R = TrafficMix.Racer
	local safe = gap - keep
	local t = if safe > 0 then math.sqrt(2 * R.Brake * 0.7 * safe + playerSpeed * playerSpeed) else playerSpeed
	if movingOver and gap > R.PassGap then
		t = math.max(t, R.PassCreep)
	end
	return math.min(target, t)
end

-- a racer's speed limit through a bend or turn piece of `degrees` heading change: 3% of its top speed off per degree
-- (Racer.TurnSlowPerDeg), never under `floor` (the junction turn speed)
function TrafficMix.racerTurnSpeed(top: number, degrees: number, floor: number): number
	return math.min(top, math.max(floor, top * (1 - TrafficMix.Racer.TurnSlowPerDeg * degrees)))
end

-- (owner, 2026-11-21: "put more traffic, it dont feel like yangon rn cuz it needs more traffic") Config.Traffic.CarCount
-- 28 -> 46 (HighwayCars 18 -> 30, the same share); low-end devices keep their 14
TrafficMix.LowEndCars = 14

TrafficMix.byName = {} :: { [string]: Entry }
for _, e in TrafficMix.Entries do
	TrafficMix.byName["Traffic_" .. e.kind .. "_" .. e.id] = e
end

-- (20 Nov 2026, owner 19 Nov: "only new model cars are supposed to be in the game") a traffic copy of a car whose
-- model is put away (Cars.OLD_MODELS) does not spawn, moving or parked. It comes back by itself when the car's id
-- leaves that list. Probox / Hiace / Carry / YBS are traffic-only bodies, never on the list. Templates that are not
-- in this mix (the old low-poly pack) are not touched.
function TrafficMix.spawns(name: string): boolean
	local e = TrafficMix.byName[name]
	return not (e and Cars.OLD_MODELS[e.id])
end

-- the everyday weight of every template that can spawn here, and their sum. `main`-only entries (the YBS bus) keep
-- the share of the street they have in the full mix when other cars are missing (old model, or template not in the
-- place): with half the mix away a plain re-share doubled the buses (6% -> 13% of main-road traffic).
function TrafficMix.weights(have: { [string]: boolean }, main: boolean): ({ [string]: number }, number)
	local all, present = 0, 0
	for name, e in TrafficMix.byName do
		if not e.main then
			all += e.w
			if have[name] and TrafficMix.spawns(name) then
				present += e.w
			end
		end
	end
	local k = if all > 0 then present / all else 1
	local out, total = {}, 0
	for name, e in TrafficMix.byName do
		local w = if e.main then e.w * k else e.w
		if w > 0 and have[name] and TrafficMix.spawns(name) and (main or not e.main) then
			out[name] = w
			total += w
		end
	end
	return out, total
end

-- the template name to spawn: a rare car now and then (group under its cap), else the everyday mix. `have` = the
-- names that exist in TrafficModels, `counts` = live cars per rare group, `main` = the spot is on a main road
function TrafficMix.pick(rng: Random, have: { [string]: boolean }, counts: { [string]: number }, main: boolean): string?
	-- (Studio test hook: workspace attribute TestRareChance, e.g. 1 to fill every rare cap)
	local chance = workspace:GetAttribute("TestRareChance")
	if rng:NextNumber() < (if type(chance) == "number" then chance else TrafficMix.RareChance) then
		local open = {}
		for name, e in TrafficMix.byName do
			if e.rare and have[name] and TrafficMix.spawns(name) and (counts[e.rare] or 0) < (TrafficMix.Rare[e.rare] or 0) then
				table.insert(open, name)
			end
		end
		if #open > 0 then
			table.sort(open) -- (pairs order differs between runs: keep the pick seeded)
			return open[rng:NextInteger(1, #open)]
		end
	end
	local weights, total = TrafficMix.weights(have, main)
	if total <= 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	local last = nil
	for _, e in TrafficMix.Entries do
		local name = "Traffic_" .. e.kind .. "_" .. e.id
		local w = weights[name]
		if w then
			r -= w
			last = name
			if r <= 0 then
				return name
			end
		end
	end
	return last
end

-- (owner, 2026-11-21: "also make it so that rare cars can race with each other"; "no dont spawn as pairs i mean
-- like when they meet each other coincidencely") two rare cars that happen to meet going the same way race: they
-- share a way (Traffic.lua raceNext) and trade places. Nothing is spawned for it.
TrafficMix.Race = {
	MeetGap = 120, -- studs along the road within which two racers going the same way become a race
	MeetSide = 30, -- studs sideways at most (the same road, not a crossing or parallel one)
	Split = 900, -- studs apart at which the race is over and each drives on alone
	Tow = 1.08, -- top speed x this for the one behind, within TowGap of its rival (slipstream)
	TowGap = 90,
	Ease = 0.92, -- top speed x this for the one in front, more than LeadGap ahead (so the other catches up)
	LeadGap = 70,
	-- (owner, 2026-11-21: "if two rare cars happen to meet, the faster car will go around and make an u turn and go
	-- near the other rare car and they will start racing") two racers that see each other, whatever their ways: the
	-- faster one turns round and chases, the other waits for it
	SeeGap = 250, -- studs apart (straight line) at which two racers meet
	SeeHeight = 12, -- studs of height apart at most (a flyover over a street is no meeting)
	Chase = 1.15, -- the chaser's top speed x this until it is within MeetGap on the other's road
	Wait = 0.4, -- the chased car's top speed x this (the chaser brakes, turns and gets back up to speed: 8 s or more)
	ChaseTime = 25, -- s before the chase is given up (or beyond Split); then both drive on alone
	Cooldown = 30, -- s before either starts another chase
	UTurnMph = 10, -- the U-turn's speed at most
	UTurnTime = 2.5, -- s the half circle takes at least
	UTurnWidth = 48, -- studs sideways at most to the oncoming lane it turns into
	UTurnTry = 10, -- s it looks for a clear U-turn; after that only junction turns lead it back
}

-- do two racers meet? `along` / `side` = the other car's place ahead (+) / beside this one in studs, `dot` = the
-- dot of their headings (1 the same way, -1 oncoming, 0 crossing)
function TrafficMix.raceMeets(along: number, side: number, dot: number): boolean
	local R = TrafficMix.Race
	return dot > 0.7 and math.abs(along) <= R.MeetGap and math.abs(side) <= R.MeetSide
end

-- do two racers see each other (any directions)? `dist` = studs apart, `dy` = their height difference
function TrafficMix.raceSees(dist: number, dy: number): boolean
	return dist <= TrafficMix.Race.SeeGap and math.abs(dy) <= TrafficMix.Race.SeeHeight
end

-- which of the two turns round and chases: the faster one (top speed with its trim); the same speed: the one
-- further behind the other along the other's heading
function TrafficMix.raceTurns(myTop: number, otherTop: number, myBehind: number, otherBehind: number): boolean
	return myTop > otherTop or (myTop == otherTop and myBehind > otherBehind)
end

-- a U-turn's place and heading at t = 0..1: a half circle of radius r from `p0` heading `fwd` (t = 0) round to the
-- oncoming lane 2 r to the `side`, heading back (t = 1). fwd and side are flat unit vectors square to each other.
function TrafficMix.uTurnPose(p0: Vector3, fwd: Vector3, side: Vector3, r: number, t: number): (Vector3, Vector3)
	local a = math.pi * math.clamp(t, 0, 1)
	return p0 + side * (r * (1 - math.cos(a))) + fwd * (r * math.sin(a)), fwd * math.cos(a) + side * math.sin(a)
end

-- a race car's top speed factor from how far it is ahead of its rival along the road (studs, negative = behind)
function TrafficMix.raceFactor(ahead: number): number
	local R = TrafficMix.Race
	if ahead < 0 and ahead >= -R.TowGap then
		return R.Tow
	elseif ahead > R.LeadGap then
		return R.Ease
	end
	return 1
end

return TrafficMix
