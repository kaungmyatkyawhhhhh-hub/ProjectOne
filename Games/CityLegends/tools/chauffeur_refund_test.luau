-- Lune test (20 Nov 2026) for the old-model leftovers:
--   1. src/server/Chauffeur.lua: a paid contract on a put-away car (Cars.OLD_MODELS) is served by a stand-in fleet
--      car, the save is not changed, no money moves, and the car comes back by itself when it leaves the list.
--   2. src/shared/TrafficMix.lua: traffic copies of old-model cars don't spawn; prints the mix before / after.
--   lune run tools/chauffeur_refund_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local failures = 0
local function check(ok: any, msg: string)
	if not ok then
		failures += 1
		print("FAIL: " .. msg)
	end
end
local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local Config = load("src/shared/Config.lua", baseEnv)
local carsEnv = table.clone(baseEnv)
carsEnv.script = { Parent = { WaitForChild = function(_, n) return n end } }
carsEnv.require = function(n) return load("src/shared/" .. n .. ".lua", baseEnv) end
local Cars = load("src/shared/Cars.lua", carsEnv)

---------------------------------------------------------------------
-- 1. Chauffeur
---------------------------------------------------------------------
local profile = { Cash = 1000000, Chauffeur = {} :: { [string]: boolean } }
local saves = 0
local PlayerData = {
	get = function() return profile end,
	addCash = function(_, n) profile.Cash = math.max(0, math.floor(profile.Cash + n)) end,
	save = function() saves += 1 end,
}
local stubs = { Config = Config, Cars = Cars, PlayerData = PlayerData }
local function waitFor(_, name)
	return { name = name, WaitForChild = waitFor }
end
local senv = table.clone(baseEnv)
senv.script = { Parent = { WaitForChild = waitFor } }
senv.game = { GetService = function(_, n) return { name = n, WaitForChild = waitFor } end }
senv.require = function(x) return stubs[x.name] or {} end
senv.task = { spawn = function(f, ...) f(...) end }
local Chauffeur = load("src/server/Chauffeur.lua", senv)
local H = Chauffeur._handlers
local Fleet, OLD = Config.Chauffeur.Fleet, Cars.OLD_MODELS
local player = {}

for _, id in Config.Chauffeur.Order do
	check(not OLD[Cars.modelOf(id)], "phone lists a put-away car: " .. id)
end

-- no contracts: nothing callable; a normal contract covers exactly its own car
check(count(Chauffeur.covered({})) == 0, "no contract, but something is callable")
local cov = Chauffeur.covered({ bentz_gls = true })
check(cov.bentz_gls and count(cov) == 1, "a normal contract must cover exactly its car")

if OLD.brabos_g63 and OLD.rolls_wraith and OLD.rolls_cullinan then
	-- each paid old contract gets one stand-in that is on the phone, nearest in price
	for id, want in { brabos_g63 = "bentlee_contgt", rolls_wraith = "bentz_gls", rolls_cullinan = "bentlee_contgt" } do
		local c = Chauffeur.covered({ [id] = true })
		check(c[want] and not c[id], id .. " should be served by " .. want)
		check(count(c) == 1, id .. ": one contract must give one car, got " .. count(c))
		for car in c do
			check(Fleet[car] and not OLD[Cars.modelOf(car)], "stand-in not drivable: " .. car)
			check(table.find(Config.Chauffeur.Order, car) ~= nil, "stand-in not on the phone: " .. car)
		end
	end
	-- never a car the player already pays for; three old contracts give three different cars
	local c = Chauffeur.covered({ brabos_g63 = true, bentlee_contgt = true })
	check(count(c) == 2 and c.bentlee_contgt and not c.brabos_g63, "owning the stand-in already must still give a second car")
	c = Chauffeur.covered({ brabos_g63 = true, rolls_wraith = true, rolls_cullinan = true })
	check(count(c) == 3, "three paid contracts must give three cars, got " .. count(c))
	-- junk in the save gives nothing
	check(count(Chauffeur.covered({ not_a_car = true, brabos_g63 = false } :: any)) == 0, "junk contract gave a car")

	-- handlers: the phone sees the stand-in as on contract; the save is untouched; no money moves
	profile.Cash, profile.Chauffeur, saves = 1000000, { brabos_g63 = true }, 0
	local st = H.state(player)
	check(#st.contracts == 1 and st.contracts[1] == "bentlee_contgt", "state must list the stand-in")
	local r = H.buy(player, "bentlee_contgt")
	check(r.ok and profile.Cash == 1000000 and saves == 0, "the stand-in must not be charged for")
	r = H.buy(player, "rolls_wraith")
	check(not r.ok and profile.Cash == 1000000 and not profile.Chauffeur.rolls_wraith, "a put-away car must not be sold")
	r = H.buy(player, "nope")
	check(not r.ok and profile.Cash == 1000000, "unknown car sold")
	r = H.buy(player, 12 :: any)
	check(not r.ok and profile.Cash == 1000000, "non-string id sold")
	check(profile.Chauffeur.brabos_g63 == true and count(profile.Chauffeur) == 1, "the saved contracts changed")
	-- calling: the old car itself is refused before anything is built; the stand-in passes the contract check
	check(H.call(player, "brabos_g63", "x").message == "Sign a contract for that car first", "old car callable")
	check(H.call(player, "bentlee_contgt", "x").message == "Unknown place", "stand-in refused at the contract check")
	check(H.call(player, "bentz_gls", "x").message == "Sign a contract for that car first", "a car without contract callable")
	-- a normal buy still charges once and never without the cash
	r = H.buy(player, "bentz_gls")
	check(r.ok and profile.Cash == 1000000 - Fleet.bentz_gls and profile.Chauffeur.bentz_gls, "normal buy broken")
	H.buy(player, "bentz_gls")
	check(profile.Cash == 1000000 - Fleet.bentz_gls, "charged twice")
	profile.Cash = 10
	r = H.buy(player, "astin_dbx")
	check(not r.ok and profile.Cash == 10 and not profile.Chauffeur.astin_dbx, "sold without the cash")

	-- the car returns (its id leaves Cars.OLD_MODELS): the same saved contract calls it again, the stand-in ends
	OLD.brabos_g63 = nil
	c = Chauffeur.covered({ brabos_g63 = true })
	check(c.brabos_g63 and count(c) == 1, "returned car must drive again and the stand-in end")
	OLD.brabos_g63 = true
else
	print("note: the three chauffeur cars are no longer on Cars.OLD_MODELS: stand-in checks skipped")
end

---------------------------------------------------------------------
-- 2. Traffic mix
---------------------------------------------------------------------
local menv = table.clone(carsEnv)
menv.require = function(n) return if n == "Cars" then Cars else load("src/shared/" .. n .. ".lua", baseEnv) end
menv.workspace = { GetAttribute = function() return nil end }
local Mix = load("src/shared/TrafficMix.lua", menv)
local have = {}
for name in Mix.byName do
	have[name] = true
end

local function shares(main: boolean): { [string]: number }
	local w, total = Mix.weights(have, main)
	local out = {}
	for name, x in w do
		out[name] = 100 * x / total
	end
	return out
end
local function show(title: string, main: boolean)
	local s = shares(main)
	local line = {}
	for _, e in Mix.Entries do
		local x = s["Traffic_" .. e.kind .. "_" .. e.id]
		if x then
			table.insert(line, string.format("%s %.1f%%", e.id, x))
		end
	end
	print(title .. ": " .. table.concat(line, ", "))
end

-- before: nothing put away
local saved = table.clone(OLD)
table.clear(OLD)
show("before, main road", true)
show("before, street   ", false)
local busBefore = shares(true).Traffic_D_ybs
for k, v in saved do
	OLD[k] = v
end
show("after,  main road", true)
show("after,  street   ", false)

local w = Mix.weights(have, true)
for name, e in Mix.byName do
	check(Mix.spawns(name) == not OLD[e.id], name .. ": spawns must follow Cars.OLD_MODELS")
	check(not (OLD[e.id] and w[name]), name .. " is an old model but has a weight")
end
for _, id in { "probox", "hiace", "carry", "ybs", "toyoka_chaser" } do
	check(not OLD[id], id .. " must stay in traffic")
end
check(math.abs(shares(true).Traffic_D_ybs - busBefore) < 0.01, "the bus share moved")
check(shares(false).Traffic_D_ybs == nil, "a bus on a street")
check(Mix.spawns("Traffic_A1"), "a template outside the mix must be left alone")

-- pick: 20,000 spawns with every rare cap open: never an old model, rare cars stay at RareChance
local seed = 1
local rng = {}
function rng:NextNumber()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end
function rng:NextInteger(a, b)
	return a + math.floor(self:NextNumber() * (b - a + 1))
end
local rare, N = 0, 20000
for _ = 1, N do
	local name = Mix.pick(rng :: any, have, {}, true)
	local e = Mix.byName[name]
	check(e and not OLD[e.id], "picked an old model: " .. tostring(name))
	if e and e.rare then
		rare += 1
	end
end
print(string.format("rare cars: %.1f%% of %d spawns with every cap open (RareChance %.0f%%)", 100 * rare / N, N, 100 * Mix.RareChance))
check(rare / N < Mix.RareChance + 0.01, "rare cars are no longer rare")
-- the old templates moved out of the place: the same mix; only old templates, or none: nothing from the mix
local few = {}
for name in have do
	if Mix.spawns(name) then
		few[name] = true
	end
end
local _, ta = Mix.weights(few, true)
local _, tb = Mix.weights(have, true)
check(ta == tb, "absent old templates must give the same mix as skipped ones")
if OLD.suzaki_swift then
	check(Mix.pick(rng :: any, { Traffic_A_suzaki_swift = true, Traffic_R_nisun_r34 = true }, {}, true) == nil, "an old-only place spawned a car")
end
check(Mix.pick(rng :: any, {}, {}, true) == nil, "an empty place spawned a car")

print(if failures == 0 then "chauffeur_refund_test: all passed" else ("chauffeur_refund_test: " .. failures .. " FAILED"))
if failures > 0 then
	process.exit(1)
end
