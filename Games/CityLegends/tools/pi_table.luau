-- Prints every car's Performance Index and class (CarStats.pi, Config.CarClasses), best first, and a
-- Markdown table for the notes with --md.
--   lune run tools/pi_table.luau . [--md] [--all]
-- (--all: the retired and pending cars too)
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local md = table.find(process.args, "--md") ~= nil
local all = table.find(process.args, "--all") ~= nil

local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local Config = load("src/shared/Config.lua", baseEnv)
local Cars = load("src/shared/Cars.lua", baseEnv)
local env = table.clone(baseEnv)
local function waitFor(_, name)
	return { name = name }
end
env.script = { Parent = { WaitForChild = waitFor } }
env.require = function(x)
	if x.name == "Config" then
		return Config
	elseif x.name == "Cars" then
		return Cars
	end
	error("require " .. tostring(x.name))
end
local CarStats = load("src/shared/CarStats.lua", env)

local rows = {}
for _, spec in (if all then Cars.All else Cars.List) do
	local letter, _, pi = CarStats.classOf(spec.Id)
	local full = {}
	for _, key in Config.CarParts.Keys do
		full[key] = 3
	end
	local maxPi = CarStats.pi(spec.Id, full)
	table.insert(rows, { spec = spec, pi = pi, letter = letter, maxPi = maxPi, maxLetter = (Config.carClass(maxPi)) })
end
table.sort(rows, function(a, b)
	return a.pi > b.pi
end)
local counts = {}
for _, r in rows do
	counts[r.letter] = (counts[r.letter] or 0) + 1
end
local function money(n: number): string
	local t = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. t:gsub("^,", "")
end
if md then
	print("| Car | Price | Class | PI | All parts (Race) |")
	print("|---|---|---|---|---|")
	for _, r in rows do
		print(string.format("| %s | %s | %s | %d | %s %d |", r.spec.Name, money(r.spec.Price), r.letter, r.pi, r.maxLetter, r.maxPi))
	end
else
	for _, r in rows do
		local st = CarStats.of(r.spec.Id)
		print(string.format("%-3s %4d  -> %-3s %4d  %-48s $%-9d %3dmph %4.1fs h%.2f %5dkg%s%s", r.letter, r.pi, r.maxLetter, r.maxPi, r.spec.Name, r.spec.Price, r.spec.TopSpeed, r.spec.ZeroToSixty, r.spec.Handling, st.weightKg, if r.spec.Retired then "  (retired)" else "", if r.spec.Pending then "  (pending)" else ""))
	end
end
local line = {}
for _, rg in Config.CarClasses.Ranges do
	table.insert(line, rg[1] .. " " .. (counts[rg[1]] or 0))
end
print(#rows .. " cars: " .. table.concat(line, ", "))
