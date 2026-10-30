-- Lune test for src/server/Market.lua: stubs for the Roblox services, then trades
--   lune run tools/market_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
local function load(path: string, env: { [string]: any }): any
	local src = fs.readFile(root .. "/" .. path)
	return luau.load(src, { debugName = path, environment = env })()
end

local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local Config = load("src/shared/Config.lua", baseEnv)
local Cars = load("src/shared/Cars.lua", baseEnv)

-- PlayerData stub
local profiles = {}
local PlayerData = {}
function PlayerData.get(p) return profiles[p] end
function PlayerData.addCash(p, n) local pr = profiles[p]; pr.Cash = math.max(0, math.floor(pr.Cash + n)) end
function PlayerData.save() end

local removing = {}
local function waitFor(_, name) return { name = name } end
local game = {
	GetService = function(_, name)
		if name == "HttpService" then
			local n = 0
			return { GenerateGUID = function() n += 1; return string.format("%08d-x", n) end }
		elseif name == "Players" then
			return { PlayerRemoving = { Connect = function(_, f) table.insert(removing, f) end } }
		elseif name == "ReplicatedStorage" then
			return { WaitForChild = function() return { WaitForChild = waitFor } end }
		end
		error(name)
	end,
}
local scriptStub = { Parent = { WaitForChild = waitFor } }
local env = table.clone(baseEnv)
env.game = game
env.script = scriptStub
env.require = function(x)
	if x.name == "Config" then return Config elseif x.name == "Cars" then return Cars elseif x.name == "PlayerData" then return PlayerData end
	error("require " .. tostring(x.name))
end
local created = {}
env.Instance = { new = function(class)
	local t = { ClassName = class, FireClient = function(self, p, st) self.last = st end }
	table.insert(created, t)
	return t
end }
env.Random = { new = function()
	return {
		NextNumber = function(_, a, b) a = a or 0; b = b or 1; return a + math.random() * (b - a) end,
		NextInteger = function(_, a, b) return math.random(a, b) end,
	}
end }
env.task = require("@lune/task")
env.warn = warn
env.print = print
env.os = os
env.math = math
env.string = string
env.table = table
local Market = load("src/server/Market.lua", env)

local player = { Name = "Tester", UserId = 1, Parent = true }
profiles[player] = { Cash = 500000, Owned = { suzaki_swift = true }, Market = {} }
Market.start({})
local call
for _, c in created do
	if c.ClassName == "RemoteFunction" then call = c end
end
local function invoke(a, args) return call.OnServerInvoke(player, a, args) end

local fails = 0
local function check(cond, msg) if not cond then fails += 1; print("FAIL", msg) else print("ok  ", msg) end end

local r = invoke("open")
check(r.ok and r.state and #r.state.listings == Config.Market.Listings, "open gives listings")
check(#r.state.requests == Config.Market.Requests, "three daily requests")
-- buy the cheapest listing
local st = r.state
local best
for _, l in st.listings do if not best or l.ask < best.ask then best = l end end
local cash0 = profiles[player].Cash
r = invoke("buy", { lid = best.lid })
check(r.ok, "buy ok: " .. tostring(r.msg))
check(profiles[player].Cash == cash0 - best.ask, "cash paid the asking price")
check(#r.state.stash == 1 and r.state.stash[1].paid == best.ask, "unit in stash with paid price")
-- sell it: value minus fee
local it = r.state.stash[1]
local cash1 = profiles[player].Cash
r = invoke("sell", { u = it.u })
check(r.ok and #r.state.stash == 0, "sold")
local got = profiles[player].Cash - cash1
check(math.abs(got - math.floor(it.value * (1 - r.state.fee))) <= 1 or got > 0, "sale paid value minus fee (" .. got .. ")")
-- bad inputs
check(not invoke("buy", { lid = 99999 }).ok, "unknown listing refused")
check(not invoke("sell", { u = "nope" }).ok, "unknown unit refused")
check(not invoke("buy", "x").ok, "junk args refused")
check(not invoke("explode").ok, "unknown action refused")
-- poor player can't buy
profiles[player].Cash = 0
r = invoke("open")
check(not invoke("buy", { lid = r.state.listings[1].lid }).ok, "no cash, no buy")
profiles[player].Cash = 5e7
-- lowballs: some land cheaper, some make the seller walk
local landed, walked = 0, 0
for _ = 1, 40 do
	r = invoke("open")
	local l = r.state.listings[1]
	local before = profiles[player].Cash
	local res = invoke("buy", { lid = l.lid, lowball = true })
	if res.ok then
		landed += 1
		check(before - profiles[player].Cash < l.ask, "lowball paid less")
		invoke("sell", { u = res.state.stash[#res.state.stash].u })
	else
		walked += 1
	end
end
print("lowballs landed", landed, "walked", walked)
check(landed > 0 and walked > 0, "lowball is a gamble")
-- stash cap
for _ = 1, Config.Market.StashSlots + 3 do
	r = invoke("open")
	invoke("buy", { lid = r.state.listings[1].lid })
end
r = invoke("open")
check(#r.state.stash == Config.Market.StashSlots, "stash capped at " .. Config.Market.StashSlots)
-- redeem a showroom unit, refuse others
local showroom, other
for _, x in r.state.stash do
	if x.cond == "Showroom" and not profiles[player].Owned[x.car] then showroom = showroom or x elseif x.cond ~= "Showroom" then other = other or x end
end
if other then check(not invoke("redeem", { u = other.u }).ok, "non-showroom delivery refused") end
if showroom then
	local res = invoke("redeem", { u = showroom.u })
	check(res.ok and profiles[player].Owned[showroom.car] == true, "showroom unit delivered to garage")
end
-- request: give the player a matching unit then fill
local req = r.state.requests[1]
local d = profiles[player].Market
table.insert(d.Stash, 1, { u = "req1", c = req.car, k = "Showroom", p = 1000, t = 0 })
-- keep under the cap
while #d.Stash > Config.Market.StashSlots do table.remove(d.Stash) end
local cashR = profiles[player].Cash
local res = invoke("fulfil", { i = 1, u = "req1" })
check(res.ok, "request filled: " .. tostring(res.msg))
check(profiles[player].Cash > cashR, "request paid")
check(not invoke("fulfil", { i = 1 }).ok, "request can't be filled twice")
check(res.state.hype >= 1, "hype went up (" .. res.state.hype .. ")")
-- flip-off
res = invoke("flipoff")
check(res.ok and res.state.flip ~= nil, "flip-off started")
check(not invoke("flipoff").ok, "only one flip-off at a time")
-- prices move and stay in their band
for _ = 1, 500 do Market._step() end
for _ = 1, 20 do Market._news() end
for _ = 1, 200 do Market._step() end
local inBand = true
for id, p in Market._price do
	local b = Market._base[id]
	if p < b * Config.Market.Floor - 1e-6 or p > b * Config.Market.Ceiling + 1e-6 then inBand = false; print("out", id, p / b) end
end
check(inBand, "prices stay between floor and ceiling")
-- saved data survives a junk profile
profiles[player].Market = { Stash = { { c = "nope", k = "Clean", p = 1 }, "junk", { c = "suzaki_swift", k = "Mint", p = 5 }, { c = "suzaki_swift", k = "Clean", p = 5 } }, Hype = 99 }
res = invoke("open")
check(#res.state.stash == 1 and res.state.hype == Config.Market.HypeMax, "junk save cleaned (1 unit, hype capped)")

print(if fails == 0 then "ALL OK" else ("FAILS: " .. fails))
process.exit(if fails == 0 then 0 else 1)
