-- Lune test for the 1:1 Yangon frame's traffic lanes (src/shared/YangonLanes1to1_*.lua, tools/yangon/city/lanes_1to1.py)
-- through the game's own RivieraTraffic.build (graph_test style):
--   * the 1:1 lanes alone: no piece dead (pruned for leading nowhere), every link inside the set, the biggest
--     strongly connected part holds nearly every piece (cars don't get stuck in a corner of the network);
--   * the whole game graph: the old maps' lanes are the same with and without the 1:1 modules (old traffic unchanged),
--     every 1:1 piece lies in the 1:1 area (Config.isYangon1to1At) and no old piece does.
--   lune run tools/lanes1to1_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local env0 = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum,
	CFrame = roblox.CFrame, math = math, string = string, table = table, print = print, warn = function() end, error = error,
	pcall = pcall, type = type, tostring = tostring, tonumber = tonumber, pairs = pairs, ipairs = ipairs, select = select,
	setmetatable = setmetatable, getmetatable = getmetatable, rawget = rawget, rawset = rawset, next = next, os = os,
	unpack = table.unpack, typeof = typeof, assert = assert, workspace = nil, game = nil }

-- a loader whose script.Parent sees only the shared modules `allow(name)` lets through
local function loader(allow: (string) -> boolean)
	local modules = {}
	local load
	local function desc(name)
		if not allow(name) or not fs.isFile(root .. "/src/shared/" .. name .. ".lua") then
			return nil
		end
		return { name = name }
	end
	local parent = setmetatable({
		WaitForChild = function(_, name)
			return desc(name)
		end,
		FindFirstChild = function(_, name)
			return desc(name)
		end,
	}, { __index = function(_, k)
		return desc(k)
	end })
	load = function(name: string): any
		if modules[name] then
			return modules[name]
		end
		local src = fs.readFile(root .. "/src/shared/" .. name .. ".lua")
		local e = table.clone(env0)
		e.script = { Parent = parent }
		e.require = function(x)
			if type(x) ~= "table" or not x.name then
				error("no module")
			end
			return load(x.name)
		end
		modules[name] = luau.load(src, { debugName = name, environment = e })()
		return modules[name]
	end
	return load
end

local fails = 0
local function check(cond, msg)
	print(if cond then "ok  " else "FAIL", msg)
	if not cond then
		fails += 1
	end
end

-- 1. the 1:1 lanes alone (the old maps' modules hidden, RivieraLanes an empty stub)
local n1 = 0
while fs.isFile(root .. "/src/shared/YangonLanes1to1_" .. (n1 + 1) .. ".lua") do
	n1 += 1
end
check(n1 > 0, "YangonLanes1to1 modules: " .. n1)
-- the 1:1-only build: a loader whose RivieraLanes is empty
local only
do
	local modules = {}
	local load
	local function desc(name)
		if name == "RivieraLanes" then
			return { name = name }
		end
		if string.find(name, "^YangonLanes") and not string.find(name, "^YangonLanes1to1_") then
			return nil
		end
		if name == "RivieraLanesHighway" then
			return nil
		end
		if not fs.isFile(root .. "/src/shared/" .. name .. ".lua") then
			return nil
		end
		return { name = name }
	end
	local parent = setmetatable({
		WaitForChild = function(_, n)
			return desc(n)
		end,
		FindFirstChild = function(_, n)
			return desc(n)
		end,
	}, { __index = function(_, k)
		return desc(k)
	end })
	load = function(name)
		if modules[name] then
			return modules[name]
		end
		if name == "RivieraLanes" then
			modules[name] = { lanes = {}, links = {} }
			return modules[name]
		end
		local e = table.clone(env0)
		e.script = { Parent = parent }
		e.require = function(x)
			if type(x) ~= "table" or not x.name then
				error("no module")
			end
			return load(x.name)
		end
		modules[name] = luau.load(fs.readFile(root .. "/src/shared/" .. name .. ".lua"), { debugName = name, environment = e })()
		return modules[name]
	end
	only = { riv = load("RivieraTraffic").build(), Config = load("Config") }
end
local riv = only.riv
check(riv ~= nil, "RivieraTraffic.build with only the 1:1 lanes")
local nLanes = #riv.lanesData
local deadN, allN = 0, #riv.all
for _ in riv.dead do
	deadN += 1
end
print(string.format("     1:1 lanes %d, pieces %d (live %d), links %d", nLanes, allN, #riv.lanes, #riv.links))
check(deadN == 0, "1:1 pieces leading nowhere (pruned): " .. deadN)
local badLink = 0
for _, l in riv.links do
	if l[1] < 1 or l[1] > nLanes or l[3] < 1 or l[3] > nLanes then
		badLink += 1
	end
end
check(badLink == 0, "1:1 links inside the set: " .. badLink .. " out")
-- strongly connected parts (iterative Tarjan) over the live pieces
local live = {}
for _, s in riv.all do
	if not riv.dead[s] then
		table.insert(live, s)
	end
end
local index, low, onStack, stack, idx = {}, {}, {}, {}, 0
local biggest = 0
for _, v0 in live do
	if index[v0] then
		continue
	end
	local work = { { v0, 1 } }
	index[v0] = idx
	low[v0] = idx
	idx += 1
	table.insert(stack, v0)
	onStack[v0] = true
	while #work > 0 do
		local top = work[#work]
		local v, i = top[1], top[2]
		local nx = v.next[i]
		if nx then
			top[2] = i + 1
			if riv.dead[nx] then
				continue
			end
			if index[nx] == nil then
				index[nx] = idx
				low[nx] = idx
				idx += 1
				table.insert(stack, nx)
				onStack[nx] = true
				table.insert(work, { nx, 1 })
			elseif onStack[nx] then
				low[v] = math.min(low[v], index[nx])
			end
		else
			table.remove(work)
			if #work > 0 then
				local u = work[#work][1]
				low[u] = math.min(low[u], low[v])
			end
			if low[v] == index[v] then
				local size = 0
				while true do
					local w = table.remove(stack)
					onStack[w] = nil
					size += 1
					if w == v then
						break
					end
				end
				biggest = math.max(biggest, size)
			end
		end
	end
end
local share = biggest / math.max(1, #live)
print(string.format("     biggest strongly connected part: %d of %d live pieces (%.1f%%)", biggest, #live, share * 100))
check(share >= 0.9, "a car can reach (nearly) every 1:1 piece from every other")
local outside = 0
for _, s in live do
	if not only.Config.isYangon1to1At(s.p0) then
		outside += 1
	end
end
check(outside == 0, "1:1 pieces outside Config.Areas.Yangon1to1Areas: " .. outside)

-- 2. the whole game graph, with and without the 1:1 modules
local function fullBuild(with1to1: boolean)
	local load = loader(function(n)
		return with1to1 or not string.find(n, "^YangonLanes1to1_")
	end)
	return load("RivieraTraffic").build(), load("Config")
end
local a, C = fullBuild(false)
local b = fullBuild(true)
check(a ~= nil and b ~= nil, "the whole graph builds with and without the 1:1 modules")
if a and b then
	local deadA, deadB = 0, 0
	for _ in a.dead do
		deadA += 1
	end
	for _ in b.dead do
		deadB += 1
	end
	print(string.format("     old maps: %d lanes, %d live pieces, %d dead | with 1:1: %d lanes, %d live, %d dead",
		#a.lanesData, #a.lanes, deadA, #b.lanesData, #b.lanes, deadB))
	check(#b.lanesData == #a.lanesData + nLanes, "the 1:1 lanes come after the old ones (" .. #b.lanesData .. " = " .. #a.lanesData .. " + " .. nLanes .. ")")
	check(#b.lanes == #a.lanes + #riv.lanes, "old maps' live pieces unchanged, 1:1's added")
	check(deadB == deadA, "no new dead pieces")
	local oldIn = 0
	for _, s in a.lanes do
		if C.isYangon1to1At(s.p0) then
			oldIn += 1
		end
	end
	check(oldIn == 0, "old map pieces inside the 1:1 area: " .. oldIn)
end
print(if fails == 0 then "ALL OK" else (fails .. " FAILED"))
process.exit(if fails == 0 then 0 else 1)
