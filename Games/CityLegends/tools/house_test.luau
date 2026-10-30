-- Lune test for the house blueprints (Config.Houses.Designs) and HouseBuilder: every design
-- builds on a lot of its tier without errors, stays on the lot, has its garage bays and driveway
-- spots, and the list itself is sane (31+ designs, $150K to $100M, levels and prices rising).
--   lune run tools/house_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]

-- Lune's CFrame.lookAt is transposed; Roblox's is right (as in world_test)
local CFrameFixed = setmetatable({
	lookAt = function(at, target, up)
		local look = (target - at).Unit
		local upV = up or roblox.Vector3.new(0, 1, 0)
		if math.abs(look:Dot(upV)) > 0.9999 then
			upV = roblox.Vector3.new(0, 0, 1)
		end
		local right = look:Cross(upV).Unit
		return roblox.CFrame.fromMatrix(at, right, right:Cross(look), -look)
	end,
}, { __index = roblox.CFrame })

local env = {
	Color3 = roblox.Color3,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	UDim2 = roblox.UDim2,
	UDim = roblox.UDim,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	NumberSequence = roblox.NumberSequence,
	NumberRange = roblox.NumberRange,
	Enum = roblox.Enum,
	CFrame = CFrameFixed,
	Instance = roblox.Instance,
	math = math,
	string = string,
	table = table,
	print = print,
	warn = warn,
	error = error,
	type = type,
	pairs = pairs,
	ipairs = ipairs,
	tostring = tostring,
	tonumber = tonumber,
}
local modules = {}
local function load(name: string): any
	if modules[name] then
		return modules[name]
	end
	local src = fs.readFile(root .. "/src/shared/" .. name .. ".lua")
	local e = table.clone(env)
	e.script = { Parent = setmetatable({}, { __index = function(_, k)
		return { name = k }
	end }) }
	e.require = function(x)
		return load(x.name)
	end
	modules[name] = luau.load(src, { debugName = name, environment = e })()
	return modules[name]
end

local fails = 0
local function check(cond: boolean, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

local Config = load("Config")
local HouseBuilder = load("HouseBuilder")
local H = Config.Houses
local designs = H.Designs

-- the list
check(#designs >= 30, `at least 30 designs ({#designs})`)
local lo, hi = math.huge, 0
local tiers = { [0] = 0, [1] = 0, [2] = 0 }
local seen = {}
local dupes = 0
for _, d in designs do
	lo = math.min(lo, d.price)
	hi = math.max(hi, d.price)
	tiers[d.tier] += 1
	if seen[d.id] or seen[d.name] then
		dupes += 1
	end
	seen[d.id] = true
	seen[d.name] = true
end
check(lo == 150000 and hi == 100000000, `prices $150K to $100M ({lo} to {hi})`)
check(tiers[0] >= 10 and tiers[1] >= 8 and tiers[2] >= 8, `designs per tier (low {tiers[0]}, mid {tiers[1]}, high {tiers[2]})`)
check(dupes == 0, "no two designs share an id or a name")
local rising = true
for k = 2, #designs do
	local a, b = designs[k - 1], designs[k]
	if a.tier == b.tier and (b.price < a.price or b.level < a.level) then
		rising = false
		print("  not rising:", a.id, b.id)
	end
end
check(rising, "prices and levels rise within each tier")
local minLevel = { [0] = math.huge, [1] = math.huge, [2] = math.huge }
for _, d in designs do
	minLevel[d.tier] = math.min(minLevel[d.tier], d.level)
end
check(minLevel[2] == 20, `High houses from level 20 (owner) ({minLevel[2]})`)
local top = table.clone(designs)
table.sort(top, function(a, b)
	return a.price > b.price
end)
local topOk = true
for k = 1, 5 do
	if top[k].bays < 10 or top[k].drive < 3 then
		topOk = false
	end
end
check(topOk, "the 5 most expensive houses have a 10-car garage and 3 driveway spots")

-- every design built on a lot of its tier
local LOT = { [0] = { 60, 72 }, [1] = { 104, 100 }, [2] = { 120, 130 } }
local worstSpill, worstId = 0, ""
local maxParts, maxId = 0, ""
local missing = {}
for _, d in designs do
	local size = LOT[d.tier]
	local lot = roblox.CFrame.new(1000, 50, -300) -- a lot looking out along -Z
	local ok, model, info = pcall(HouseBuilder.build, d, lot, size[1], size[2], { interior = true })
	if not ok then
		check(false, d.id .. " builds: " .. tostring(model))
		continue
	end
	local parts = 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			parts += 1
			-- its real outline along the lot's sides (a long thin part only counts its length one way)
			local rel = lot:ToObjectSpace(p.CFrame)
			local hs = p.Size / 2
			local ex = math.abs(rel.XVector.X) * hs.X + math.abs(rel.YVector.X) * hs.Y + math.abs(rel.ZVector.X) * hs.Z
			local ez = math.abs(rel.XVector.Z) * hs.X + math.abs(rel.YVector.Z) * hs.Y + math.abs(rel.ZVector.Z) * hs.Z
			local spill = math.max(math.abs(rel.Position.X) + ex - size[1] / 2, math.abs(rel.Position.Z) + ez - size[2] / 2)
			if spill > worstSpill then
				worstSpill, worstId = spill, d.id .. " " .. p.Name
			end
		end
	end
	if parts > maxParts then
		maxParts, maxId = parts, d.id
	end
	if #info.bays ~= d.maxBays or #info.drive ~= d.drive then
		table.insert(missing, `{d.id}: {#info.bays} bays (want {d.maxBays}), {#info.drive} drive spots (want {d.drive})`)
	end
	-- every bay on the lot, inside the garage's floor
	for _, b in info.bays do
		local rel = lot:PointToObjectSpace(b.Position)
		if math.abs(rel.X) > size[1] / 2 or math.abs(rel.Z) > size[2] / 2 then
			table.insert(missing, d.id .. ": a bay off the lot")
			break
		end
	end
	-- walking in (owner, 2026-10-29: every house is a real house you walk into)
	local solids: { BasePart } = {}
	local uses: { [string]: number } = {}
	local steps: { BasePart } = {}
	local doors: { BasePart } = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "Step" then
				table.insert(steps, p)
			elseif p.Name == "Door" then
				table.insert(doors, p)
			elseif p.CanCollide and p.Name ~= "Lawn" and p.Name ~= "Driveway" then
				table.insert(solids, p)
			end
		elseif p:IsA("ProximityPrompt") then
			local k = p:GetAttribute("Use")
			if k then
				uses[k] = (uses[k] or 0) + 1
			end
		end
	end
	-- is a point inside a solid part (other than the ones in `skip`)?
	local function blocked(pt: any, skip: { [BasePart]: boolean }?): BasePart?
		for _, q in solids do
			if not (skip and skip[q]) then
				local l = q.CFrame:PointToObjectSpace(pt)
				if math.abs(l.X) < q.Size.X / 2 and math.abs(l.Y) < q.Size.Y / 2 and math.abs(l.Z) < q.Size.Z / 2 then
					return q
				end
			end
		end
		return nil
	end
	local problems = {}
	if #doors == 0 then
		table.insert(problems, "no door")
	end
	for _, dr in doors do
		-- through the doorway: a line of points from 2 studs outside to 2 inside, 1 to 6 up
		local closed = dr:GetAttribute("ClosedCF") :: any
		for _, dz in { -2, -1, 0, 1, 2 } do
			for _, dy in { -3, 0, 2 } do
				local pt = (closed * roblox.CFrame.new(0, dy, dz)).Position
				local q = blocked(pt)
				if q then
					table.insert(problems, "door blocked by " .. q.Name .. string.format(" (%.1f up, %.1f through)", dy, dz))
					break
				end
			end
		end
	end
	if #steps < 11 * (d.floors - 1) then
		table.insert(problems, `{#steps} steps for {d.floors} floors`)
	end
	-- headroom over every step (a player is about 5 studs tall)
	for _, st in steps do
		local top = st.CFrame.Position + roblox.Vector3.new(0, st.Size.Y / 2, 0)
		for _, up in { 1, 3, 5 } do
			local q = blocked(top + roblox.Vector3.new(0, up, 0))
			if q then
				table.insert(problems, "no headroom on the stairs: " .. q.Name)
				break
			end
		end
		if #problems > 4 then
			break
		end
	end
	for _, k in { "door", "light", "tv", "tap", "bed", "fridge", "stove" } do
		if not uses[k] then
			table.insert(problems, "nothing to use: " .. k)
		end
	end
	if d.tier >= 1 and #info.gates == 0 then
		table.insert(problems, "no gate")
	end
	if #problems > 0 then
		table.insert(missing, d.id .. ": " .. table.concat(problems, ", "))
	end
	local ghostOk = pcall(HouseBuilder.build, d, lot, size[1], size[2], { ghost = true })
	if not ghostOk then
		table.insert(missing, d.id .. ": the ghost doesn't build")
	end
end
check(#missing == 0, "bays, drive spots, ghosts, doors, stairs, things to use, gates " .. table.concat(missing, "; "))
check(worstSpill <= 3, string.format("every house stays on its lot (worst %.1f studs over at %s)", worstSpill, worstId))
print(string.format("  most parts: %d (%s)", maxParts, maxId))
check(maxParts < 1500, "no house over 1,500 parts")

print(if fails == 0 then "ALL OK" else fails .. " FAILED")
if fails > 0 then
	process.exit(1)
end
