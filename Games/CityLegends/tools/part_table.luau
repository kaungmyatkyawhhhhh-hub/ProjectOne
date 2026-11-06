-- The part list with rarities and prices, as a note: lune run tools/part_table.luau . > "../../City Legends/Parts list.md"
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local root = process.args[1] or "."
local PD = luau.load(fs.readFile(root .. "/src/shared/PartData.lua"), { debugName = "PartData", environment = { Color3 = roblox.Color3, assert = assert, table = table, type = type, string = string, math = math, pairs = pairs } })()
local function money(n)
	local s = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. s
end
print("# City Legends parts list\n")
print("Made by `tools/part_table.luau` from `src/shared/PartData.lua`. A car pays the list price x 0.1 x its price factor ((car price / $50,000) ^ 0.5, from 1 to 10), so the list price is what the dearest cars pay. Engine swaps pay the list price x the factor.\n")
for _, cat in PD.Cats do
	print("## " .. cat.name .. "\n")
	print("| Slot | Part | Rarity | Brand | List price | Cheapest car | What it does |")
	print("|---|---|---|---|---|---|---|")
	for _, slot in cat.slots do
		if slot ~= "swap" then
			local list = table.clone(PD.BySlot[slot] or {})
			table.sort(list, function(a, b)
				return if a.list ~= b.list then a.list < b.list else a.id < b.id
			end)
			for _, def in list do
				local fx = {}
				for _, k in { "accel", "speed", "grip", "brake", "weight" } do
					if def.fx[k] then
						table.insert(fx, string.format("%s %+.1f%%", k, def.fx[k] * 100))
					end
				end
				local note = def.perk and ("Perk: " .. def.perk) or def.desc or ""
				print(string.format("| %s | %s | %s | %s | %s | %s | %s %s |", PD.Slots[slot].name, def.name, def.rarity, def.brand, money(def.list), money(math.floor(def.list * 0.1 / 100 + 0.5) * 100), table.concat(fx, ", "), note))
			end
		end
	end
	print("")
end
print("## ENGINE SWAPS\n")
print("| Engine | Group | Layout | Stock hp | Tuned max hp | Rarity | Rev limit | Price on the cheapest car |")
print("|---|---|---|---|---|---|---|---|")
for _, def in PD.SwapList do
	local e = def.engine
	print(string.format("| %s | %s | %s | %d | %d | %s | %.1fk | %s |", def.name, e.group, e.layout, e.hp, e.tuned, def.rarity, e.redline, money(def.list)))
end
