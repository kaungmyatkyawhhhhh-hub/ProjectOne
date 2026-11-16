--[[
	YangonKitCheck (2026-11-16, compact building data): Python == Luau check of the FORMAT=2 layout.

	tools/yangon/city/kit_layout.py `expect <tag> <dir>` writes the old fixed-width strings Python expands sample tiles
	of Data_<tag> into; this module expands the same tiles with YangonKitData.expand and compares record by record
	(same kinds, pids and codes; every number within one unit of its field: x / z 1/500 stud, y 1/200, yaw 1/262144 turn,
	stretch 1/50000).

	local C = require(ServerStorage.ClaudeTools.YangonKitCheck:Clone())
	print(C.run(KD, dataFolder, expectFolder))   -- expectFolder: StringValues named "i_j" (the Python strings)
]]

local C = {}

local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
local VAL = {}
for i = 1, 64 do
	VAL[string.byte(B64, i)] = i - 1
end
local function num(s, a, n)
	local v = 0
	for k = a, a + n - 1 do
		v = v * 64 + VAL[string.byte(s, k)]
	end
	return v
end

-- kind -> fields { start, width, "c" categorical | "n" number | "y" yaw }
local SPEC = {
	P = { { 2, 2, "c" }, { 4, 4, "n" }, { 8, 3, "n" }, { 11, 4, "n" }, { 15, 3, "y" }, { 18, 3, "n" }, { 21, 1, "c" } },
	B = { { 2, 4, "n" }, { 6, 3, "n" }, { 9, 4, "n" }, { 13, 3, "y" }, { 16, 3, "n" }, { 19, 3, "n" }, { 22, 3, "n" }, { 25, 1, "c" } },
}
SPEC.Q = table.clone(SPEC.P)
table.insert(SPEC.Q, { 22, 3, "n" })
table.insert(SPEC.Q, { 25, 3, "n" })
local LEN = { P = 21, Q = 27, B = 25 }

local function split(s)
	local out, p = {}, 1
	while p <= #s do
		local k = string.sub(s, p, p)
		local L = LEN[k]
		if not L then
			table.insert(out, "?" .. k)
			break
		end
		table.insert(out, string.sub(s, p, p + L - 1))
		p += L
	end
	return out
end

function C.run(KD, data: Instance, expect: Instance)
	local meta = KD.meta(data)
	local tiles, recs, same, bad, maxd, missing = 0, 0, 0, 0, 0, 0
	local examples = {}
	for _, e in expect:GetChildren() do
		local i, j = string.match(e.Name, "^(%-?%d+)_(%-?%d+)$")
		local v = data:FindFirstChild(e.Name)
		if i and v then
			tiles += 1
			local got, miss = KD.expand(v.Value, tonumber(i), tonumber(j), meta)
			missing += miss
			local A, Bv = split(got), split(e.Value)
			if #A ~= #Bv then
				bad += 1
				table.insert(examples, string.format("%s: %d records (Luau) vs %d (Python)", e.Name, #A, #Bv))
			end
			for k = 1, math.min(#A, #Bv) do
				recs += 1
				local a, b = A[k], Bv[k]
				if a == b then
					same += 1
				else
					local kind = string.sub(a, 1, 1)
					local ok = kind == string.sub(b, 1, 1) and SPEC[kind] ~= nil
					if ok then
						for _, f in SPEC[kind] do
							local x, y = num(a, f[1], f[2]), num(b, f[1], f[2])
							local d = math.abs(x - y)
							if f[3] == "y" then
								d = math.min(d, 262144 - d)
							end
							if f[3] == "c" and d > 0 or d > 1 then
								ok = false
							end
							maxd = math.max(maxd, if f[3] == "c" then 0 else d)
						end
					end
					if not ok then
						bad += 1
						if #examples < 8 then
							table.insert(examples, string.format("%s #%d: %s vs %s", e.Name, k, a, b))
						end
					end
				end
			end
		end
	end
	return string.format("tiles %d, records %d (identical %d), mismatches %d, missing pids %d, max unit diff %d\n%s",
		tiles, recs, same, bad, missing, maxd, table.concat(examples, "\n"))
end

return C
