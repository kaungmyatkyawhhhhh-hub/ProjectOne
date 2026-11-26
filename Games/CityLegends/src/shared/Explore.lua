--!strict
--[[
	Explore (2026-11-26, owner: "Yes, build them" -> the driving-game study's "roads not driven yet" idea, Forza
	Horizon's orange roads). The 1:1 Yangon map in 512-stud cells; a player's visited cells are a bitset saved as
	one short string (6 bits a character) in profile.Activities.explored. The server marks cells (server/Explore),
	the map draws the cells not yet visited darker (client/Minimap). Pure: no instances.
	Vault: City Legends/2026-11-27 Map explore, speed effects, HUD toggles, motion.md
]]
local Explore = {}

-- the minimap art's box (client/YangonMapArt map): x 16273..55554, z 15108..48704
Explore.X0 = 16273
Explore.Z0 = 15108
Explore.CELL = 512
Explore.COLS = 77
Explore.ROWS = 66
Explore.COUNT = Explore.COLS * Explore.ROWS

local CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local VALUE: { [string]: number } = {}
for i = 1, #CHARS do
	VALUE[string.sub(CHARS, i, i)] = i - 1
end

-- the cell index (0-based) of a world position, or nil outside the map
function Explore.cellOf(x: number, z: number): number?
	local cx = math.floor((x - Explore.X0) / Explore.CELL)
	local cz = math.floor((z - Explore.Z0) / Explore.CELL)
	if cx < 0 or cz < 0 or cx >= Explore.COLS or cz >= Explore.ROWS then
		return nil
	end
	return cz * Explore.COLS + cx
end

-- a cell's box in world studs: x0, z0, x1, z1
function Explore.box(i: number): (number, number, number, number)
	local cx, cz = i % Explore.COLS, i // Explore.COLS
	local x0, z0 = Explore.X0 + cx * Explore.CELL, Explore.Z0 + cz * Explore.CELL
	return x0, z0, x0 + Explore.CELL, z0 + Explore.CELL
end

-- bitset <-> string (6 cells a character, trailing "A"s dropped)
function Explore.decode(s: any): { boolean }
	local bits = table.create(Explore.COUNT, false)
	if type(s) ~= "string" then
		return bits
	end
	for k = 1, math.min(#s, math.ceil(Explore.COUNT / 6)) do
		local v = VALUE[string.sub(s, k, k)] or 0
		for b = 0, 5 do
			local i = (k - 1) * 6 + b
			if i < Explore.COUNT and v // 2 ^ b % 2 == 1 then
				bits[i + 1] = true
			end
		end
	end
	return bits
end
function Explore.encode(bits: { boolean }): string
	local out = table.create(math.ceil(Explore.COUNT / 6))
	for k = 0, math.ceil(Explore.COUNT / 6) - 1 do
		local v = 0
		for b = 0, 5 do
			if bits[k * 6 + b + 1] then
				v += 2 ^ b
			end
		end
		out[k + 1] = string.sub(CHARS, v + 1, v + 1)
	end
	return (string.gsub(table.concat(out), "A+$", ""))
end
function Explore.count(bits: { boolean }): number
	local n = 0
	for i = 1, Explore.COUNT do
		if bits[i] then
			n += 1
		end
	end
	return n
end

function Explore.selfTest()
	local bits = table.create(Explore.COUNT, false)
	for _, i in { 0, 1, 5, 6, 77, 2000, Explore.COUNT - 1 } do
		bits[i + 1] = true
	end
	local s = Explore.encode(bits)
	local back = Explore.decode(s)
	for i = 1, Explore.COUNT do
		assert(back[i] == bits[i], "explore bit " .. i)
	end
	assert(Explore.count(back) == 7)
	assert(Explore.cellOf(Explore.X0 + 1, Explore.Z0 + 1) == 0)
	assert(Explore.cellOf(Explore.X0 + Explore.CELL * 2 + 5, Explore.Z0 + Explore.CELL + 5) == Explore.COLS + 2)
	assert(Explore.cellOf(0, 0) == nil)
	assert(Explore.decode(nil)[1] == false and Explore.encode(Explore.decode("")) == "")
	return true
end

return Explore
