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
	{ id = "ybs", kind = "D", len = 33.0, w = 6, paint = YBS, main = true }, -- YBS buses, main roads only
	{ id = "toyoka_lc200", kind = "F", len = 14.9, w = 4, paint = { WHITE, BLACK, SILVER, PEARL } }, -- Land Cruiser / Hilux Surf / Prado
	{ id = "byt_seal", kind = "E", len = 14.4, w = 3, paint = { WHITE, SILVER, BLUE, GREY } }, -- BYD: top new-car brand 2024-25
	{ id = "kio_ev6", kind = "F", len = 14.0, w = 2, paint = { WHITE, GREY, SILVER } },
	{ id = "toyoka_lc300", kind = "F", len = 15.0, w = 2, paint = { WHITE, BLACK, PEARL } }, -- the few luxury SUVs
	{ id = "lexis_lx700", kind = "F", len = 15.3, w = 1, paint = { BLACK, WHITE, PEARL } },
	-- rare supercars (owner, 19 Nov): racers, capped per group (Rare)
	{ id = "nisun_gtr", kind = "R", len = 14.1, w = 0, paint = { WHITE, SILVER, BLACK, rgb(200, 90, 20) }, rare = "gtr", mph = 150 },
	{ id = "nisun_r34", kind = "R", len = 13.8, w = 0, paint = { rgb(40, 60, 150), SILVER, WHITE }, rare = "r34", mph = 130 },
	{ id = "ferrara_599", kind = "R", len = 14.0, w = 0, paint = SUPER, rare = "ferrari", mph = 185 },
	{ id = "ferrara_california", kind = "R", len = 13.9, w = 0, paint = SUPER, rare = "ferrari", mph = 170 },
	{ id = "lambrini_huracan", kind = "R", len = 13.4, w = 0, paint = SUPER, rare = "lambo", mph = 185 },
	{ id = "lambrini_lp570", kind = "R", len = 13.1, w = 0, paint = SUPER, rare = "lambo", mph = 190 },
	{ id = "bugotti_chiron", kind = "R", len = 13.6, w = 0, paint = { rgb(20, 40, 90), BLACK, rgb(200, 200, 205) }, rare = "bugatti", mph = 220 },
} :: { Entry }

-- the most of each rare group on the road at once (counted over all live traffic: traffic is per client, so this is
-- per player's view of the map)
TrafficMix.Rare = { ferrari = 2, lambo = 2, gtr = 10, r34 = 3, bugatti = 1 }
TrafficMix.RareChance = 0.07 -- of each spawn, the share that tries a rare car (a group under its cap)

-- racer driving (Traffic.lua profile "racer")
TrafficMix.Racer = {
	MinMph = 100, -- cruise at least this on a lane whose bends allow it
	Accel = 40, -- studs/s^2 (about 1.3 g)
	Brake = 95, -- studs/s^2 used for planning (about 1.1 g x 0.95 margin)
	LatAccel = 26, -- studs/s^2 in a bend (about 0.9 g): v = sqrt(LatAccel * radius)
	LookAheadS = 2.6, -- seconds of travel looked ahead for cars (at least Config.Traffic.LookAhead)
	PlayerGap = 1.0, -- extra seconds kept behind a player's car
	Recycle = 1500, -- flat studs from the focus before a racer is moved (everyday cars: RecycleDistance)
	SideRate = 0.14, -- lateral studs/s per stud/s of speed (lane change speed), clamped 7..22
}

TrafficMix.byName = {} :: { [string]: Entry }
for _, e in TrafficMix.Entries do
	TrafficMix.byName["Traffic_" .. e.kind .. "_" .. e.id] = e
end

-- the template name to spawn: a rare car now and then (group under its cap), else the everyday mix. `have` = the
-- names that exist in TrafficModels, `counts` = live cars per rare group, `main` = the spot is on a main road
function TrafficMix.pick(rng: Random, have: { [string]: boolean }, counts: { [string]: number }, main: boolean): string?
	-- (Studio test hook: workspace attribute TestRareChance, e.g. 1 to fill every rare cap)
	local chance = workspace:GetAttribute("TestRareChance")
	if rng:NextNumber() < (if type(chance) == "number" then chance else TrafficMix.RareChance) then
		local open = {}
		for name, e in TrafficMix.byName do
			if e.rare and have[name] and (counts[e.rare] or 0) < (TrafficMix.Rare[e.rare] or 0) then
				table.insert(open, name)
			end
		end
		if #open > 0 then
			table.sort(open) -- (pairs order differs between runs: keep the pick seeded)
			return open[rng:NextInteger(1, #open)]
		end
	end
	local total = 0
	for name, e in TrafficMix.byName do
		if have[name] and e.w > 0 and (main or not e.main) then
			total += e.w
		end
	end
	if total <= 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	local last = nil
	for _, e in TrafficMix.Entries do
		local name = "Traffic_" .. e.kind .. "_" .. e.id
		if have[name] and e.w > 0 and (main or not e.main) then
			r -= e.w
			last = name
			if r <= 0 then
				return name
			end
		end
	end
	return last
end

return TrafficMix
