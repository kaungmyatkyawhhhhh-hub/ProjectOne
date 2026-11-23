-- Lune test for Cars.oldTrim (owner, 2026-11-21: old trims leave every inventory)
--   lune run tools/old_trim_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local root = process.args[1]
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end
local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local carsEnv = table.clone(baseEnv)
carsEnv.script = { Parent = { WaitForChild = function(_, n) return n end } }
carsEnv.require = function(n) return load("src/shared/" .. n .. ".lua", baseEnv) end
local Cars = load("src/shared/Cars.lua", carsEnv)
local old, kept, names = 0, 0, {}
for _, spec in Cars.All do
	if Cars.oldTrim(spec.Id) then
		old += 1
		assert(spec.BaseId and spec.Retired, spec.Id)
		assert(not Cars.forSale(spec.Id), spec.Id .. " is on sale but counted old")
	elseif spec.BaseId then
		if Cars.forSale(spec.Id) then
			kept += 1
		end
		table.insert(names, spec.Id)
		assert(Cars.forSale(spec.Id) or spec.Pending, spec.Id)
	end
end
assert(not Cars.oldTrim("toyoka_ae86") and not Cars.oldTrim("no_such_car"))
assert(old > 0 and kept == 3, "old " .. old .. " kept " .. kept .. " " .. table.concat(names, ",")) -- (the Origine's two trims and the GT-R Nismo stay)
print("old_trim_test: ok, old trims " .. old .. ", trims kept " .. kept)
