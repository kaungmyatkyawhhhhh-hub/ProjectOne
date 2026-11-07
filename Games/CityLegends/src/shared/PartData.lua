--[[
	PartData (owner, 2026-11-06: "make the upgrading area way better ... add a part shop")
	The workshop's parts: slots by category, every part with its rarity, brand, icon, list price and
	what it does, and the 43 engine swaps. CarStats works the numbers out from this, server/CarLevels
	sells them, client/Workshop shows them.

	A car has one part per slot: { slot key = part id } (profile.CarParts, the "Parts" attribute).
	Part brands are our own (Ferrolux, Kestrel Works, Tachyon, Steelvein, Pulsewerk, Nightcoil, Draxa,
	Corvin Motorsport). Engine names are codes only, never a maker's word.

	fx (shares, like the old stages): accel off the 0-60, speed onto the top speed, grip onto Handling,
	brake onto the braking force, weight off the weight, pi onto the PI; shift off the shift time,
	steer onto the wheel lock, drift easier slides, launch a harder launch, redline onto the rev limit.
	Sound and feel: pop ("pop", "crackle", "burble", "antilag"), loud (0-3), decat, bov, downpipe,
	spool (a turbo's whistle), nitro (the bottle: 0.6 small, 1 big), air (lowers when parked).
	needs: "turbo", "super" or "forced" (a part that only works on one).
	list: the real aftermarket price in dollars (PartData.Real, by slot and rarity; the old sheet's numbers
	are in the tables below and no longer used). A car pays list * Config.Economy.PartPriceMult, and big
	parts on the dearest cars a little more (Config.partCash).
	Rarity: Common a little over stock, Uncommon today's Street, Rare Sport, Epic Race, Legendary a
	little over Race with a perk (`perk`, a real effect in fx).
]]

local PartData = {}

local rgb = Color3.fromRGB

PartData.Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
PartData.Rarity = {
	Common = { order = 1, name = "COMMON", color = rgb(93, 99, 108), dark = rgb(42, 46, 52), text = rgb(214, 218, 224), cp = 1 },
	Uncommon = { order = 2, name = "UNCOMMON", color = rgb(47, 174, 90), dark = rgb(15, 74, 36), text = rgb(126, 240, 164), cp = 2 },
	Rare = { order = 3, name = "RARE", color = rgb(47, 123, 234), dark = rgb(15, 47, 110), text = rgb(132, 190, 255), cp = 5 },
	Epic = { order = 4, name = "EPIC", color = rgb(155, 69, 228), dark = rgb(61, 19, 102), text = rgb(214, 160, 255), cp = 10 },
	Legendary = { order = 5, name = "LEGENDARY", color = rgb(255, 154, 31), dark = rgb(122, 51, 0), text = rgb(255, 208, 120) }, -- (no CP: cash or a rare reward)
}
local BY_LETTER = { C = "Common", U = "Uncommon", R = "Rare", E = "Epic", L = "Legendary" }

-- the workshop's rail and the shop's tabs. zoom: where the camera goes
PartData.Cats = {
	{ key = "engine", name = "ENGINE", icon = "block", zoom = "engine", slots = { "intake", "airfilter", "cams", "head", "injectors", "fuelpump", "internals", "block", "ignition", "ecu", "swap", "oilcooler", "radiator" } },
	{ key = "boost", name = "BOOST", icon = "turbo", zoom = "engine", slots = { "induction", "intercooler", "bov", "wastegate", "boostctl", "nitrous" } },
	{ key = "exhaust", name = "EXHAUST", icon = "straight", zoom = "rear", slots = { "downpipe", "catalyst", "midpipe", "muffler", "tips" } },
	{ key = "drive", name = "DRIVE", icon = "gear", zoom = "side", slots = { "gearbox", "shifter", "clutch", "flywheel", "diff", "final", "shaft" } },
	{ key = "grip", name = "GRIP", icon = "tyre", zoom = "wheel", slots = { "tyres", "wheels", "brakes" } },
	{ key = "chassis", name = "CHASSIS", icon = "coil", zoom = "wheel", slots = { "springs", "arb", "camber", "strut", "bushings", "steering" } },
	{ key = "body", name = "BODY", icon = "wing", zoom = "side", slots = { "weight", "bonnet", "roof", "battery", "seats", "cage", "wing" } },
}

-- name, and: top = allowed on stock S2 / R / X cars (tyres, gearbox, suspension, exhaust), ice = needs
-- a petrol engine
PartData.Slots = {
	intake = { name = "Intake", icon = "intake", ice = true },
	airfilter = { name = "Air Filter", icon = "filter", ice = true },
	cams = { name = "Camshaft", icon = "cam", ice = true },
	head = { name = "Cylinder Head", icon = "head", ice = true },
	injectors = { name = "Fuel Injectors", icon = "inj", ice = true },
	fuelpump = { name = "Fuel Pump", icon = "pump", ice = true },
	internals = { name = "Pistons & Internals", short = "Internals", icon = "piston", ice = true },
	block = { name = "Engine Block", short = "Block", icon = "block", ice = true },
	ignition = { name = "Ignition", icon = "coils", ice = true },
	ecu = { name = "ECU Tune", short = "ECU", icon = "ecu" },
	swap = { name = "Engine Swap", short = "Swap", icon = "swap", ice = true },
	oilcooler = { name = "Oil Cooler", icon = "oil", ice = true },
	radiator = { name = "Radiator", icon = "radiator", ice = true },
	induction = { name = "Turbo or Supercharger", short = "Turbo / SC", icon = "turbo", ice = true },
	intercooler = { name = "Intercooler", icon = "ic", ice = true },
	bov = { name = "Blow-Off Valve", short = "Blow-Off", icon = "bov", ice = true },
	wastegate = { name = "Wastegate", icon = "wastegate", ice = true },
	boostctl = { name = "Boost Control", icon = "boost", ice = true },
	nitrous = { name = "Nitrous", icon = "nos", ice = true },
	downpipe = { name = "Downpipe", icon = "down", ice = true, top = true },
	catalyst = { name = "Catalyst", icon = "decat", ice = true, top = true },
	midpipe = { name = "Mid-Pipe", icon = "straight", ice = true, top = true },
	muffler = { name = "Muffler", icon = "mdelete", ice = true, top = true },
	tips = { name = "Exhaust Tips", short = "Tips", icon = "tips", ice = true, top = true },
	gearbox = { name = "Gearbox", icon = "gear", ice = true, top = true },
	shifter = { name = "Short Shifter", short = "Shifter", icon = "shifter", ice = true, top = true },
	clutch = { name = "Clutch", icon = "clutch", ice = true },
	flywheel = { name = "Flywheel", icon = "fly", ice = true },
	diff = { name = "Differential", short = "Diff", icon = "lsd" },
	final = { name = "Final Drive", icon = "final" },
	shaft = { name = "Driveshaft", icon = "shaft" },
	tyres = { name = "Tyres", icon = "tyre", top = true },
	wheels = { name = "Wheels", icon = "forged", top = true },
	brakes = { name = "Brakes", icon = "brake" },
	springs = { name = "Springs", icon = "springs", top = true },
	arb = { name = "Anti-Roll Bars", short = "Anti-Roll", icon = "arb", top = true },
	camber = { name = "Camber Kit", short = "Camber", icon = "camber", top = true },
	strut = { name = "Strut Brace", icon = "strut", top = true },
	bushings = { name = "Bushings", icon = "bush", top = true },
	steering = { name = "Steering", icon = "angle", top = true },
	weight = { name = "Weight Reduction", short = "Weight", icon = "weight" },
	bonnet = { name = "Bonnet", icon = "bonnet" },
	roof = { name = "Roof", icon = "bonnet" },
	battery = { name = "Battery", icon = "battery" },
	seats = { name = "Seats", icon = "seat" },
	cage = { name = "Roll Cage", icon = "cage" },
	wing = { name = "Rear Wing", icon = "wing" },
}
for _, cat in PartData.Cats do
	for _, slot in cat.slots do
		PartData.Slots[slot].cat = cat.key
	end
end

-- the slots that make engine power (a swapped engine climbs from its stock power to its tuned max
-- with these)
PartData.PowerCats = { engine = true, boost = true, exhaust = true }

export type Part = {
	id: string,
	slot: string,
	name: string,
	brand: string,
	rarity: string,
	icon: string,
	list: number,
	fx: { [string]: any },
	needs: string?,
	perk: string?,
	desc: string?,
	ev: boolean?, -- fits an electric car in an `ice` slot
	sound: boolean?, -- a sound part: it goes on stock S2 / R / X cars too
	cp: number?, -- CP, when not the rarity's
	engine: Engine?,
}
export type Engine = {
	code: string,
	hp: number,
	tuned: number,
	group: string, -- the swap filter: Japanese, American, BMW, German, Other
	layout: string, -- I4, I5, I6, V6, V8, V10, R (rotary), F4, F6
	forced: string?, -- "turbo", "super"
	redline: number, -- x1000 rpm
	kg: number, -- weight added to (or off) the car
	curve: string, -- the dyno's shape: "na", "highrev", "turbo", "bigv8", "rotary"
}

PartData.Parts = {} :: { [string]: Part }
PartData.BySlot = {} :: { [string]: { Part } }

-- real aftermarket prices (owner, 2026-11-07: "make the part shop cheaper since a B58 is like over a
-- million"): each slot's cheapest and dearest in US dollars; a rarity sits at this share of the way
PartData.Real = {
	intake = { 100, 800 }, airfilter = { 100, 400 }, cams = { 1000, 4000 }, head = { 2000, 8000 },
	injectors = { 300, 2500 }, fuelpump = { 200, 2000 }, internals = { 3000, 12000 }, block = { 4000, 12000 },
	ignition = { 200, 1500 }, ecu = { 500, 3000 }, oilcooler = { 300, 1500 }, radiator = { 300, 1500 },
	induction = { 3000, 20000 }, intercooler = { 300, 2500 }, bov = { 200, 800 }, wastegate = { 200, 1000 },
	boostctl = { 200, 900 }, nitrous = { 500, 2500 },
	downpipe = { 200, 1500 }, catalyst = { 200, 1500 }, midpipe = { 300, 2000 }, muffler = { 300, 6000 }, tips = { 100, 500 },
	gearbox = { 2000, 40000 }, shifter = { 100, 800 }, clutch = { 500, 3000 }, flywheel = { 400, 1500 },
	diff = { 800, 4000 }, final = { 500, 2000 }, shaft = { 500, 3000 },
	tyres = { 600, 2500 }, wheels = { 1500, 8000 }, brakes = { 500, 8000 },
	springs = { 150, 2500 }, arb = { 200, 1000 }, camber = { 150, 800 }, strut = { 150, 800 }, bushings = { 150, 900 }, steering = { 300, 6000 },
	weight = { 300, 6000 }, bonnet = { 800, 3500 }, roof = { 1500, 6000 }, battery = { 300, 1200 }, seats = { 800, 5000 }, cage = { 1000, 4000 }, wing = { 500, 4000 },
} :: { [string]: { number } }
PartData.RealShare = { Common = 0, Uncommon = 0.2, Rare = 0.5, Epic = 0.8, Legendary = 1 }

local function add(slot: string, brand: string, rows: { { any } })
	for _, r in rows do
		local extra = r[7]
		local part: Part = {
			id = r[2],
			slot = slot,
			name = r[3],
			brand = brand,
			rarity = BY_LETTER[r[1]],
			icon = r[4],
			list = r[5],
			fx = r[6] or {},
		}
		local real = PartData.Real[slot]
		if real then
			local rough = real[1] + (real[2] - real[1]) * PartData.RealShare[part.rarity]
			part.list = math.floor(rough / 10 + 0.5) * 10
		end
		if extra then
			for k, v in extra do
				(part :: any)[k] = v
			end
		end
		assert(PartData.Parts[part.id] == nil, part.id)
		PartData.Parts[part.id] = part
		PartData.BySlot[slot] = PartData.BySlot[slot] or {}
		table.insert(PartData.BySlot[slot], part)
	end
end

-- ENGINE
add("intake", "Kestrel Works", {
	{ "C", "in_panel", "Panel Intake Kit", "intake", 3000, { accel = 0.005 } },
	{ "U", "in_cold", "Cold Air Intake", "intake", 12500, { accel = 0.01, speed = 0.005 } },
	{ "R", "in_short", "Short Ram Intake", "intake", 40000, { accel = 0.02, speed = 0.01 } },
	{ "E", "in_ram", "Carbon Ram Intake", "intake", 100000, { accel = 0.035, speed = 0.015 } },
	{ "L", "in_stack", "Velocity Stack Intake", "intake", 600000, { accel = 0.04, speed = 0.022 }, { perk = "Pulls harder at the very top of the revs" } },
})
add("airfilter", "Kestrel Works", {
	{ "C", "af_race", "Race Air Filter", "filter", 4000, { accel = 0.003 } },
	{ "U", "af_cotton", "Cotton Air Filter", "filter", 9000, { accel = 0.005 } },
	{ "R", "af_foam", "Foam Air Filter", "filter", 24000, { accel = 0.008 } },
	{ "E", "af_carbon", "Carbon Air Box", "filter", 70000, { accel = 0.012 } },
})
add("cams", "Steelvein", {
	{ "C", "cam_mild", "Mild Camshaft", "cam", 3500, { accel = 0.005 } },
	{ "U", "cam_1", "Stage 1 Camshaft", "cam", 12000, { accel = 0.01, speed = 0.005 } },
	{ "R", "cam_2", "Stage 2 Camshaft", "cam", 38000, { accel = 0.02, speed = 0.01 } },
	{ "E", "cam_3", "Stage 3 Camshaft", "cam", 110000, { accel = 0.035, speed = 0.02 } },
	{ "L", "cam_billet", "Billet Race Camshaft", "cam", 700000, { accel = 0.04, speed = 0.022, redline = 0.04 }, { perk = "Revs 4% higher" } },
})
add("head", "Steelvein", {
	{ "U", "hd_street", "Street Ported Head", "head", 30000, { accel = 0.006 } },
	{ "R", "hd_valve", "Big-Valve Head", "head", 60000, { accel = 0.012 } },
	{ "E", "hd_ported", "Ported Cylinder Head", "head", 120000, { accel = 0.02, speed = 0.005 } },
	{ "L", "hd_cnc", "CNC Race Head", "head", 800000, { accel = 0.025, speed = 0.01, redline = 0.02 }, { perk = "Revs 2% higher" } },
})
add("injectors", "Tachyon", {
	{ "C", "inj_street", "Street Injectors", "inj", 2500, { accel = 0.003 } },
	{ "U", "inj_up", "Uprated Injectors", "inj", 7000, { accel = 0.005 } },
	{ "R", "inj_flow", "High-Flow Injectors", "inj", 26000, { accel = 0.01 } },
	{ "E", "inj_race", "Race Injectors", "inj", 80000, { accel = 0.02 } },
})
add("fuelpump", "Tachyon", {
	{ "U", "fp_up", "Uprated Fuel Pump", "pump", 7000, { accel = 0.003 } },
	{ "R", "fp_flow", "High-Flow Fuel Pump", "pump", 21000, { accel = 0.006 } },
	{ "E", "fp_twin", "Twin Fuel Pumps", "pump", 60000, { accel = 0.01 } },
})
add("internals", "Corvin Motorsport", {
	{ "U", "pi_rods", "Uprated Rods", "piston", 22000, { accel = 0.005 } },
	{ "R", "pi_cast", "Hypereutectic Pistons", "piston", 55000, { accel = 0.01 } },
	{ "E", "pi_forged", "Forged Pistons", "piston", 140000, { accel = 0.018 } },
	{ "L", "pi_billet", "Billet Internals", "piston", 900000, { accel = 0.023, redline = 0.03 }, { perk = "Revs 3% higher" } },
})
add("block", "Corvin Motorsport", {
	{ "U", "bl_bored", "Bored Block", "block", 30000, { accel = 0.02, speed = 0.01 }, { cp = 4 } },
	{ "R", "bl_crank", "Stroked Crank", "block", 80000, { accel = 0.04, speed = 0.015 }, { cp = 8 } },
	{ "E", "bl_bigbore", "Big-Bore Block", "block", 200000, { accel = 0.06, speed = 0.025 }, { cp = 15 } },
	{ "L", "bl_stroker", "Stroker Block", "block", 900000, { accel = 0.07, speed = 0.03, launch = 0.04 }, { perk = "More torque off the line" } },
})
add("ignition", "Tachyon", {
	{ "C", "ig_plugs", "Iridium Spark Plugs", "plug", 2000, { accel = 0.002 } },
	{ "U", "ig_coils", "Performance Coils", "coils", 8500, { accel = 0.004 } },
	{ "R", "ig_race", "Race Coil Packs", "coils", 22000, { accel = 0.007 } },
})
add("ecu", "Tachyon", {
	{ "U", "ecu_1", "Stage 1 ECU", "ecu", 15000, { accel = 0.01, speed = 0.005 }, { ev = true } },
	{ "U", "ecu_burble", "Burble Tune ECU", "ecuBurble", 20000, { accel = 0.005, pop = "burble" }, { sound = true, desc = "Soft burbles at low revs" } },
	{ "R", "ecu_pop", "Pop Tune ECU", "ecuPop", 45000, { accel = 0.01, pop = "pop" }, { sound = true, desc = "Pops when you lift off" } },
	{ "R", "ecu_2", "Stage 2 ECU", "ecu", 60000, { accel = 0.02, speed = 0.01 }, { ev = true } },
	{ "R", "ecu_limiter", "Rev Limiter Raise", "limiter", 30000, { accel = 0.006, redline = 0.08 }, { desc = "Revs 8% higher" } },
	{ "E", "ecu_crackle", "Crackle Tune ECU", "ecuCrackle", 95000, { accel = 0.015, pop = "crackle" }, { sound = true, desc = "Long crackles when you lift off and on downshifts" } },
	{ "E", "ecu_3", "Stage 3 ECU", "ecu", 150000, { accel = 0.03, speed = 0.012 }, { ev = true } },
	{ "L", "ecu_antilag", "Anti-Lag Map", "antilag", 700000, { accel = 0.035, speed = 0.014, pop = "antilag" }, { needs = "turbo", perk = "The boost stays up through gear changes, with bangs and flames" } },
})
add("oilcooler", "Kestrel Works", {
	{ "U", "oc_cooler", "Oil Cooler", "oil", 9500, { accel = 0.002 }, { desc = "Keeps the power on long runs" } },
	{ "R", "oc_race", "Race Oil Cooler", "oil", 26000, { accel = 0.003, speed = 0.002 }, { desc = "Keeps the power on long runs" } },
})
add("radiator", "Kestrel Works", {
	{ "U", "rad_alloy", "Alloy Radiator", "radiator", 8000, { accel = 0.002 }, { desc = "Keeps the power on long runs" } },
	{ "R", "rad_race", "Race Radiator", "radiator", 18000, { accel = 0.003, speed = 0.002 }, { desc = "Keeps the power on long runs" } },
})

-- BOOST
add("induction", "Pulsewerk", {
	{ "U", "tb_street", "Street Turbo Kit", "turbo", 25000, { accel = 0.02, speed = 0.01, spool = 0.7 }, { desc = "A turbo: spool whistle" } },
	{ "R", "tb_ball", "Ball-Bearing Turbo", "turbo", 90000, { accel = 0.04, speed = 0.02, spool = 0.85 }, { desc = "A turbo: spool whistle" } },
	{ "E", "tb_scroll", "Twin-Scroll Turbo", "turbo", 220000, { accel = 0.06, speed = 0.03, spool = 1 }, { desc = "A turbo: spool whistle" } },
	{ "E", "tb_twin", "Twin-Turbo Kit", "twinTurbo", 380000, { accel = 0.065, speed = 0.032, spool = 1 }, { desc = "Two turbos: spool whistle" } },
	{ "E", "sc_centri", "Centrifugal Supercharger", "centri", 310000, { accel = 0.06, speed = 0.03 }, { desc = "A supercharger: no lag" } },
	{ "L", "tb_big", "Big Single Turbo", "bigTurbo", 950000, { accel = 0.08, speed = 0.04, spool = 1.2 }, { perk = "The most power of any turbo, a huge whistle" } },
	{ "L", "sc_screw", "Twin-Screw Supercharger", "sc", 1200000, { accel = 0.08, speed = 0.035, launch = 0.04 }, { perk = "Instant power, no lag" } },
})
add("intercooler", "Pulsewerk", {
	{ "U", "ic_side", "Side-Mount Intercooler", "ic", 12000, { accel = 0.005 }, { needs = "forced" } },
	{ "R", "ic_front", "Front-Mount Intercooler", "ic", 32000, { accel = 0.01 }, { needs = "forced" } },
	{ "E", "ic_water", "Water-Air Intercooler", "ic", 90000, { accel = 0.015 }, { needs = "forced" } },
})
add("bov", "Pulsewerk", {
	{ "U", "bov_std", "Blow-Off Valve", "bov", 9000, { accel = 0.002, bov = true }, { needs = "turbo", sound = true, desc = "The pssh on gear changes" } },
	{ "R", "bov_race", "Race Blow-Off Valve", "bov", 25000, { accel = 0.004, bov = true }, { needs = "turbo", sound = true, desc = "A bigger pssh on gear changes" } },
})
add("wastegate", "Pulsewerk", {
	{ "U", "wg_ext", "External Wastegate", "wastegate", 11000, { accel = 0.004 }, { needs = "turbo" } },
	{ "R", "wg_race", "Race Wastegate", "wastegate", 30000, { accel = 0.008 }, { needs = "turbo" } },
})
add("boostctl", "Tachyon", {
	{ "U", "bc_pulley", "Smaller Pulley", "pulley", 12000, { accel = 0.008 }, { needs = "super", desc = "More boost from a supercharger" } },
	{ "R", "bc_ctrl", "Boost Controller", "boost", 24000, { accel = 0.01, speed = 0.004 }, { needs = "turbo", desc = "More boost from a turbo" } },
})
add("nitrous", "Tachyon", {
	{ "R", "nos_small", "Small Nitrous Bottle", "nos", 180000, { pi = 6, nitro = 0.6 }, { desc = "Hold the nitro key: a short boost, then it refills slowly" } },
	{ "L", "nos_big", "Nitrous Kit", "nos", 650000, { pi = 10, nitro = 1 }, { perk = "The big bottle: the longest boost" } },
})

-- EXHAUST
add("downpipe", "Nightcoil", {
	{ "U", "dp_sport", "Sport Downpipe", "down", 14000, { accel = 0.002, turboAccel = 0.004, downpipe = true }, { desc = "More power with a turbo, and a louder turbo" } },
	{ "R", "dp_catless", "Catless Downpipe", "down", 40000, { accel = 0.003, turboAccel = 0.008, downpipe = true }, { desc = "More power with a turbo, and a louder turbo" } },
})
add("catalyst", "Nightcoil", {
	{ "C", "cat_flow", "High-Flow Catalyst", "decat", 6000, { accel = 0.003 } },
	{ "E", "cat_decat", "Decat Pipe", "decat", 70000, { accel = 0.01, decat = true }, { sound = true, desc = "More power, louder crackles" } },
})
add("midpipe", "Nightcoil", {
	{ "U", "mp_sport", "Sport Mid-Pipe", "straight", 15000, { accel = 0.01, speed = 0.005 } },
	{ "R", "mp_race", "Race Mid-Pipe", "straight", 40000, { accel = 0.02, speed = 0.01 } },
	{ "E", "mp_titanium", "Titanium Mid-Pipe", "straight", 100000, { accel = 0.035, speed = 0.015 } },
})
add("muffler", "Nightcoil", {
	{ "C", "mf_sport", "Sport Muffler", "tips", 5000, { accel = 0.002, loud = 1 }, { sound = true, desc = "A bit louder" } },
	{ "U", "mf_delete", "Muffler Delete", "mdelete", 8000, { accel = 0.003, loud = 2 }, { sound = true, desc = "Louder and rawer" } },
	{ "R", "mf_straight", "Straight Pipe", "straight", 30000, { accel = 0.006, loud = 3 }, { sound = true, desc = "The loudest and rawest, a tiny bit more power" } },
})
add("tips", "Nightcoil", {
	{ "C", "tp_quad", "Quad Burnt Tips", "tips", 3500, { accel = 0.001 } },
	{ "U", "tp_ti", "Titanium Tips", "tips", 9000, { accel = 0.002 } },
})

-- DRIVE
add("gearbox", "Draxa", {
	{ "U", "gb_street", "Street Gear Set", "gear", 15000, { accel = 0.015, speed = 0.01 } },
	{ "R", "gb_sport", "Sport Gear Set", "gear", 40000, { accel = 0.03, speed = 0.02, shift = 0.1 } },
	{ "E", "gb_close", "Close-Ratio Gearbox", "gear", 180000, { accel = 0.05, speed = 0.03, shift = 0.15 } },
	{ "E", "gb_dct", "Dual-Clutch Gearbox", "dct", 260000, { accel = 0.052, speed = 0.03, shift = 0.35 }, { desc = "Very quick shifts" } },
	{ "L", "gb_seq", "Sequential Gearbox", "seq", 1100000, { accel = 0.06, speed = 0.035, shift = 0.5 }, { perk = "The quickest shifts" } },
})
add("shifter", "Draxa", {
	{ "C", "sh_short", "Short Shifter", "shifter", 3500, { shift = 0.05 } },
})
add("clutch", "Draxa", {
	{ "U", "cl_sport", "Sport Clutch", "clutch", 10000, { accel = 0.003 } },
	{ "R", "cl_twin", "Twin-Plate Clutch", "clutch", 28000, { accel = 0.005, launch = 0.02 } },
})
add("flywheel", "Draxa", {
	{ "U", "fw_light", "Lightweight Flywheel", "fly", 11000, { accel = 0.005, weight = 0.003, pi = -3 }, { desc = "Revs quicker, lowers the PI a little" } },
	{ "R", "fw_chromoly", "Chromoly Flywheel", "fly", 30000, { accel = 0.01, weight = 0.006, pi = -6 }, { desc = "Revs quicker, lowers the PI a little" } },
	{ "E", "fw_alloy", "Alloy Flywheel", "fly", 70000, { accel = 0.015, weight = 0.01, pi = -10 }, { desc = "Revs quicker, lowers the PI a little" } },
})
add("diff", "Draxa", {
	{ "U", "df_clutch", "Clutch-Type LSD", "lsd", 13000, { grip = 0.003, accel = 0.002 } },
	{ "R", "df_plated", "Plated LSD", "lsd", 36000, { grip = 0.006, accel = 0.005 } },
	{ "E", "df_active", "Active Diff", "lsd", 110000, { grip = 0.01, accel = 0.008 } },
})
add("final", "Draxa", {
	{ "U", "fd_short", "Short Final Drive", "final", 10000, { accel = 0.008, speed = -0.004 }, { desc = "More pull, a little less top speed" } },
	{ "U", "fd_tall", "Tall Final Drive", "final", 10000, { accel = -0.004, speed = 0.008 }, { desc = "More top speed, a little less pull" } },
})
add("shaft", "Draxa", {
	{ "R", "ds_carbon", "Carbon Driveshaft", "shaft", 29000, { accel = 0.004, weight = 0.002 }, { desc = "Not on front-wheel drive cars" } },
})

-- GRIP
add("tyres", "Ferrolux", {
	{ "C", "ty_street", "Street Tyres", "tyreStreet", 4000, { grip = 0.01, brake = 0.015 } },
	{ "U", "ty_road", "Fast Road Tyres", "tyreStreet", 12000, { grip = 0.02, brake = 0.03 } },
	{ "U", "ty_drift", "Drift Tyres", "tyreDrift", 8000, { grip = -0.01, brake = 0.02, drift = 0.3 }, { desc = "Slide easily, less grip" } },
	{ "R", "ty_sport", "Sport Tyres", "tyre", 26000, { grip = 0.04, brake = 0.06 } },
	{ "R", "ty_rally", "Rally Tyres", "tyreRally", 22000, { grip = 0.025, brake = 0.04, rally = 0.5 }, { desc = "Grip on dirt and grass" } },
	{ "E", "ty_slick", "Semi-Slick Tyres", "tyre", 90000, { grip = 0.07, brake = 0.1 } },
	{ "E", "ty_drag", "Drag Radials", "tyreDrag", 75000, { grip = 0.02, brake = 0.03, launch = 0.12 }, { desc = "The hardest launch, less cornering grip" } },
	{ "L", "ty_full", "Full Slicks", "tyre", 750000, { grip = 0.085, brake = 0.115, launch = 0.04 }, { perk = "The most grip there is" } },
})
add("wheels", "Corvin Motorsport", {
	{ "U", "wh_cast", "Flow-Formed Wheels", "forged", 18000, { grip = 0.002, accel = 0.002, weight = 0.001 } },
	{ "E", "wh_forged", "Forged Light Wheels", "forged", 95000, { grip = 0.005, accel = 0.006, weight = 0.004 } },
})
add("brakes", "Ferrolux", {
	{ "C", "br_lines", "Braided Lines", "brake", 3000, { brake = 0.04 } },
	{ "U", "br_pads", "Sport Pads", "brake", 15000, { brake = 0.08 } },
	{ "R", "br_big", "Big Brake Kit", "brake", 48000, { brake = 0.16 } },
	{ "E", "br_ceramic", "Carbon-Ceramic Kit", "brake", 120000, { brake = 0.25 } },
	{ "L", "br_race", "Race Brake Kit", "brake", 800000, { brake = 0.32, grip = 0.005 }, { perk = "The shortest stops in the game" } },
})

-- CHASSIS
add("springs", "Ferrolux", {
	{ "U", "sp_low", "Lowering Springs", "springs", 9000, { grip = 0.015 } },
	{ "R", "sp_coil", "Adjustable Coilovers", "coil", 42000, { grip = 0.03 } },
	{ "E", "sp_race", "Race Coilovers", "coil", 120000, { grip = 0.05 } },
	{ "E", "sp_air", "Air Suspension", "air", 130000, { grip = 0.045, air = true }, { desc = "Lowers the car when parked" } },
})
add("arb", "Ferrolux", {
	{ "C", "ar_stiff", "Stiff Anti-Roll Bars", "arb", 5000, { grip = 0.004 } },
	{ "R", "ar_race", "Race Anti-Roll Bars", "arb", 25000, { grip = 0.008 } },
})
add("camber", "Ferrolux", {
	{ "U", "cb_kit", "Camber Kit", "camber", 7500, { grip = 0.005 } },
})
add("strut", "Ferrolux", {
	{ "C", "st_carbon", "Carbon Strut Brace", "strut", 3000, { grip = 0.003 } },
})
add("bushings", "Ferrolux", {
	{ "C", "bs_poly", "Poly Bushings", "bush", 2500, { grip = 0.003 } },
})
add("steering", "Ferrolux", {
	{ "R", "sr_angle", "Drift Angle Kit", "angle", 34000, { steer = 0.3, drift = 0.15 }, { desc = "More steering lock for bigger slides" } },
})

-- BODY
add("weight", "Corvin Motorsport", {
	{ "U", "wr_1", "Weight Reduction I", "weight", 12000, { weight = 0.03 } },
	{ "R", "wr_2", "Weight Reduction II", "weight", 40000, { weight = 0.06 } },
	{ "E", "wr_3", "Weight Reduction III", "weight", 85000, { weight = 0.1 } },
	{ "L", "wr_4", "Race Shell", "weight", 700000, { weight = 0.125 }, { perk = "Everything you can live without is gone" } },
})
add("bonnet", "Corvin Motorsport", {
	{ "R", "bn_carbon", "Carbon Bonnet", "bonnet", 35000, { weight = 0.008 } },
})
add("roof", "Corvin Motorsport", {
	{ "R", "rf_carbon", "Carbon Roof", "bonnet", 45000, { weight = 0.008 } },
})
add("battery", "Corvin Motorsport", {
	{ "C", "bt_light", "Lightweight Battery", "battery", 3000, { weight = 0.003 } },
})
add("seats", "Corvin Motorsport", {
	{ "U", "se_bucket", "Bucket Seats", "seat", 14000, { weight = 0.006 } },
})
add("cage", "Corvin Motorsport", {
	{ "E", "cg_roll", "Roll Cage", "cage", 70000, { grip = 0.006, weight = -0.004 }, { desc = "A stiffer car, a little heavier" } },
})
add("wing", "Corvin Motorsport", {
	{ "R", "wg_duck", "Ducktail Spoiler", "wing", 30000, { grip = 0.003 }, { desc = "A little grip at speed. Unlocks Downforce in TUNE" } },
	{ "E", "wg_gt", "GT Rear Wing", "wing", 110000, { grip = 0.006 }, { desc = "Grip at speed. Unlocks Downforce in TUNE" } },
})

-- ENGINE SWAPS (owner, 2026-11-06: the 25 most popular tuning engines, the top BMW and German ones).
-- name, group, layout, forced, stock hp, tuned max hp, rarity, redline, kg, curve
local SWAPS = {
	{ "2jz", "2JZ 3.0 I6 Twin-Turbo", "Japanese", "I6", "turbo", 320, 900, "L", 6.8, 40, "turbo" },
	{ "rb26", "RB26 2.6 I6 Twin-Turbo", "Japanese", "I6", "turbo", 276, 800, "L", 8.0, 30, "turbo" },
	{ "vr38", "VR38 3.8 V6 Twin-Turbo", "Japanese", "V6", "turbo", 565, 1000, "L", 7.0, 30, "turbo" },
	{ "barra", "Barra 4.0 I6 Turbo", "Other", "I6", "turbo", 362, 900, "L", 6.0, 60, "turbo" },
	{ "v8sc", "6.2 Supercharged V8", "American", "V8", "super", 707, 1000, "L", 6.2, 120, "bigv8" },
	{ "ls7", "LS7 7.0 V8", "American", "V8", nil, 505, 800, "L", 7.0, 60, "bigv8" },
	{ "20b", "20B 3-Rotor Twin-Turbo", "Japanese", "R", "turbo", 300, 800, "L", 8.5, -40, "rotary" },
	{ "ls3", "LS3 6.2 V8", "American", "V8", nil, 430, 750, "E", 6.6, 50, "bigv8" },
	{ "454", "454 7.4 Big-Block V8", "American", "V8", nil, 450, 900, "E", 5.5, 150, "bigv8" },
	{ "50v8", "5.0 V8 32-Valve", "American", "V8", nil, 460, 800, "E", 7.5, 60, "na" },
	{ "4g63", "4G63 2.0 I4 Turbo", "Japanese", "I4", "turbo", 280, 650, "E", 7.5, -40, "turbo" },
	{ "1jz", "1JZ 2.5 I6 Turbo", "Japanese", "I6", "turbo", 280, 650, "E", 7.0, 30, "turbo" },
	{ "13b", "13B 2-Rotor Twin-Turbo", "Japanese", "R", "turbo", 276, 600, "E", 8.5, -70, "rotary" },
	{ "n54", "N54 3.0 I6 Twin-Turbo", "BMW", "I6", "turbo", 300, 650, "E", 7.0, 20, "turbo" },
	{ "b58", "B58 3.0 I6 Turbo", "BMW", "I6", "turbo", 382, 750, "E", 7.0, 20, "turbo" },
	{ "350", "350 5.7 Small-Block V8", "American", "V8", nil, 300, 600, "R", 5.5, 60, "bigv8" },
	{ "sr20", "SR20 2.0 I4 Turbo", "Japanese", "I4", "turbo", 250, 550, "R", 7.5, -50, "turbo" },
	{ "3s", "3S 2.0 I4 Turbo", "Japanese", "I4", "turbo", 255, 550, "R", 7.2, -50, "turbo" },
	{ "4b11", "4B11 2.0 I4 Turbo", "Japanese", "I4", "turbo", 291, 550, "R", 7.0, -40, "turbo" },
	{ "ej25", "EJ25 2.5 Flat-4 Turbo", "Japanese", "F4", "turbo", 300, 550, "R", 7.0, -30, "turbo" },
	{ "k20", "K20 2.0 I4", "Japanese", "I4", nil, 220, 450, "R", 8.6, -60, "highrev" },
	{ "f20", "F20 2.0 I4 High-Rev", "Japanese", "I4", nil, 240, 350, "R", 9.0, -60, "highrev" },
	{ "b18", "B18 1.8 I4 High-Rev", "Japanese", "I4", nil, 195, 400, "U", 8.4, -70, "highrev" },
	{ "ca18", "CA18 1.8 I4 Turbo", "Japanese", "I4", "turbo", 170, 400, "U", 7.0, -70, "turbo" },
	{ "ea888", "EA888 2.0 I4 Turbo", "German", "I4", "turbo", 220, 500, "U", 6.8, -40, "turbo" },
	{ "s58", "S58 3.0 I6 Twin-Turbo", "BMW", "I6", "turbo", 473, 900, "L", 7.2, 30, "turbo" },
	{ "s63", "S63 4.4 V8 Twin-Turbo", "BMW", "V8", "turbo", 600, 1000, "L", 7.2, 100, "turbo" },
	{ "s55", "S55 3.0 I6 Twin-Turbo", "BMW", "I6", "turbo", 425, 800, "E", 7.6, 20, "turbo" },
	{ "s85", "S85 5.0 V10 High-Rev", "BMW", "V10", nil, 500, 650, "E", 8.25, 80, "highrev" },
	{ "s65", "S65 4.0 V8 High-Rev", "BMW", "V8", nil, 414, 550, "R", 8.4, 30, "highrev" },
	{ "s54", "S54 3.2 I6 High-Rev", "BMW", "I6", nil, 333, 450, "R", 8.0, 20, "highrev" },
	{ "n55", "N55 3.0 I6 Turbo", "BMW", "I6", "turbo", 300, 550, "R", 7.0, 10, "turbo" },
	{ "m52", "M52 2.8 I6", "BMW", "I6", nil, 190, 500, "U", 6.5, 0, "na" },
	{ "m177", "M177 4.0 V8 Twin-Turbo", "German", "V8", "turbo", 603, 1000, "L", 7.0, 90, "turbo" },
	{ "ea825", "4.0 V8 Twin-Turbo (EA825)", "German", "V8", "turbo", 591, 1000, "L", 6.8, 90, "turbo" },
	{ "v10", "5.2 V10 High-Rev", "German", "V10", nil, 602, 1000, "L", 8.7, 80, "highrev" },
	{ "f6tt", "3.8 Flat-6 Twin-Turbo", "German", "F6", "turbo", 640, 900, "L", 7.2, 30, "turbo" },
	{ "i5", "2.5 I5 Turbo", "German", "I5", "turbo", 400, 800, "E", 7.0, 0, "turbo" },
	{ "m156", "M156 6.2 V8", "German", "V8", nil, 507, 650, "E", 7.2, 80, "bigv8" },
	{ "f6na", "4.0 Flat-6 High-Rev", "German", "F6", nil, 500, 600, "E", 9.0, 20, "highrev" },
	{ "m139", "M139 2.0 I4 Turbo", "German", "I4", "turbo", 416, 550, "R", 7.2, -40, "turbo" },
	{ "vr32", "3.2 Narrow-V6", "German", "V6", nil, 250, 650, "R", 6.8, 10, "na" },
	{ "18t", "1.8 I4 Turbo 20V", "German", "I4", "turbo", 180, 450, "U", 6.5, -50, "turbo" },
}
PartData.SwapGroups = { "All", "Japanese", "American", "BMW", "German", "Other" }
PartData.SwapList = {} :: { Part }
-- (real engine + fitting, US dollars: a B58 about $20K, a 2JZ about $40K, the biggest about $50K)
PartData.SwapPrice = { U = 10000, R = 14000, E = 20000 }
for _, s in SWAPS do
	local tuned: number = s[7]
	-- (Legendary: $28K at 800 hp tuned, $52K at 1,000)
	local price = PartData.SwapPrice[s[8]] or (28000 + (tuned - 800) * 120)
	add("swap", "Corvin Motorsport", {
		{ s[8], "sw_" .. s[1], s[2], "swap_" .. s[4], price, {}, {
			cp = 0,
			engine = { code = s[1], hp = s[6], tuned = tuned, group = s[3], layout = s[4], forced = s[5], redline = s[9], kg = s[10], curve = s[11] },
		} },
	})
	table.insert(PartData.SwapList, PartData.Parts["sw_" .. s[1]])
end

-- each car's old Street / Sport / Race part (the 12 parts before 2026-11-06) as the new part
-- (Uncommon, Rare, Epic), installed, in the same slot it now lives in. The exhaust goes to the
-- mid-pipe: same numbers, and a car doesn't get louder by itself
PartData.OldParts = {
	intake = { slot = "intake", "in_cold", "in_short", "in_ram" },
	fuel = { slot = "injectors", "inj_up", "inj_flow", "inj_race" },
	flywheel = { slot = "flywheel", "fw_light", "fw_chromoly", "fw_alloy" },
	cams = { slot = "cams", "cam_1", "cam_2", "cam_3" },
	displacement = { slot = "block", "bl_bored", "bl_crank", "bl_bigbore" },
	turbo = { slot = "induction", "tb_street", "tb_ball", "tb_scroll" },
	exhaust = { slot = "midpipe", "mp_sport", "mp_race", "mp_titanium" },
	gearbox = { slot = "gearbox", "gb_street", "gb_sport", "gb_close" },
	tyres = { slot = "tyres", "ty_road", "ty_sport", "ty_slick" },
	brakes = { slot = "brakes", "br_pads", "br_big", "br_ceramic" },
	suspension = { slot = "springs", "sp_low", "sp_coil", "sp_race" },
	weight = { slot = "weight", "wr_1", "wr_2", "wr_3" },
}

-- an old save's { part = stage } as { slot = part id }
function PartData.migrate(old: { [string]: any }): { [string]: string }
	local out: { [string]: string } = {}
	for key, value in old do
		local map = PartData.OldParts[key]
		if map and type(value) == "number" and map[value] then
			out[map.slot] = map[value]
		elseif type(value) == "string" and PartData.Parts[value] and PartData.Parts[value].slot == key then
			out[key] = value
		end
	end
	return out
end

-- TUNE tab: small effects, saved per car (CarStats.applyTune). `def` is the stock setting, `wing`
-- shows only with a rear wing
PartData.Tune = {
	{ key = "launch", name = "Launch Control RPM", help = "The revs held before a launch. A good value gives the best start", min = 0.3, max = 0.95, def = 0.6, step = 0.05, low = "Low", high = "High", rpm = true },
	{ key = "final", name = "Final Drive", help = "Acceleration or top speed", min = -1, max = 1, def = 0, step = 0.1, low = "Acceleration", high = "Top speed" },
	{ key = "ride", name = "Ride Height", help = "Lower is more grip, but it scrapes on bumps", min = -1, max = 1, def = 0, step = 0.1, low = "Lower", high = "Higher" },
	{ key = "bias", name = "Brake Bias", help = "Front stops straight, rear turns in", min = 0.4, max = 0.8, def = 0.6, step = 0.02, low = "Rear", high = "Front" },
	{ key = "press", name = "Tyre Pressure", help = "Low grips more, high slides more", min = -1, max = 1, def = 0, step = 0.1, low = "Grip", high = "Drift" },
	{ key = "down", name = "Downforce", help = "More grip at speed, a little less top speed", min = 0, max = 1, def = 0, step = 0.1, low = "Less", high = "More", wing = true },
}
PartData.TuneByKey = {}
for _, t in PartData.Tune do
	PartData.TuneByKey[t.key] = t
end

-- builds: up to this many per car
PartData.MaxBuilds = 3
PartData.BuildNames = { "STREET", "RACE", "DRIFT" }

return PartData
