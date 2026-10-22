-- Lune test for the casino, the Gem Showcase and the wearables: builds both buildings with real
-- Roblox instances, checks they stay inside their lots, puts every item on an R15 and an R6
-- stand-in, and runs the shop's buy / wear / VIP calls.
--   lune run tools/luxe_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1]
local Instance = roblox.Instance

local modules: { [string]: any } = {}
local env: { [string]: any } = {
	Color3 = roblox.Color3,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	UDim2 = roblox.UDim2,
	UDim = roblox.UDim,
	Enum = roblox.Enum,
	CFrame = roblox.CFrame,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	NumberSequence = roblox.NumberSequence,
	NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
	NumberRange = roblox.NumberRange,
	Instance = Instance,
	Random = { new = function(seed)
		local r = { s = seed or 1 }
		function r.NextNumber(_, a, b)
			a = a or 0
			b = b or 1
			return a + math.random() * (b - a)
		end
		function r.NextInteger(_, a, b)
			return math.random(a, b)
		end
		return r
	end },
	-- (no background loops in the test)
	task = { spawn = function() end, wait = function() end },
	os = os,
}

local tags: { [string]: { any } } = {}
local services = {
	CollectionService = {
		AddTag = function(_, inst, tag)
			tags[tag] = tags[tag] or {}
			table.insert(tags[tag], inst)
		end,
	},
	TweenService = { Create = function()
		return { Play = function() end }
	end },
	Players = { GetPlayers = function()
		return {}
	end, PlayerAdded = { Connect = function() end } },
	ReplicatedStorage = { WaitForChild = function()
		return { WaitForChild = function(_, n)
			return { name = n }
		end }
	end },
}
env.game = { GetService = function(_, n)
	return services[n] or error("service " .. n)
end }
env.script = { Parent = { WaitForChild = function(_, n)
	return { name = n }
end } }

-- PlayerData stub
local profiles = {}
local PlayerData = {}
function PlayerData.get(p)
	return profiles[p]
end
function PlayerData.addCash(p, n)
	profiles[p].Cash = math.max(0, math.floor(profiles[p].Cash + n))
end
function PlayerData.save() end
modules.PlayerData = PlayerData

local paths = {
	Config = "src/shared/Config.lua",
	CityLayout = "src/shared/CityLayout.lua",
	WestLayout = "src/shared/WestLayout.lua",
	Flex = "src/shared/Flex.lua",
	Casino = "src/server/Casino.lua",
	GemShowcase = "src/server/GemShowcase.lua",
	Luxe = "src/server/Luxe.lua",
}
env.require = function(x)
	local name = x.name
	if modules[name] then
		return modules[name]
	end
	local path = paths[name] or error("require " .. tostring(name))
	local menv = table.clone(env)
	menv.script = { Parent = { Config = { name = "Config" }, CityLayout = { name = "CityLayout" }, WestLayout = { name = "WestLayout" }, WaitForChild = function(_, n)
		return { name = n }
	end } }
	local m = luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = menv })()
	modules[name] = m
	return m
end

local Config = env.require({ name = "Config" })
-- `wide` as a second argument: try 16-stud lanes (smaller lots)
if process.args[2] == "wide" then
	Config.City.LaneWidth = 16
	Config.City.RoadWidth = 16 * Config.City.LanesPerSide * 2
	Config.City.HalfExtent = Config.City.Blocks * Config.City.BlockSize / 2
end
local WestLayout = env.require({ name = "WestLayout" })
local Casino = env.require({ name = "Casino" })
local GemShowcase = env.require({ name = "GemShowcase" })
local Flex = env.require({ name = "Flex" })
local Luxe = env.require({ name = "Luxe" })

-- the kit (CityBuilder's helpers, simplified)
local kit = {}
function kit.mk(parent, size, cf, color, material, o)
	local opts = o or {}
	local p = Instance.new(if opts.class == "Wedge" then "WedgePart" else "Part")
	if opts.shape then
		p.Shape = opts.shape
	end
	p.Name = opts.name or "Part"
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Transparency = opts.transparency or 0
	p.CanCollide = opts.collide ~= false
	p.Parent = parent
	return p
end
function kit.deco(parent, size, cf, color, material, o)
	local opts = o or {}
	opts.collide = false
	return kit.mk(parent, size, cf, color, material, opts)
end
function kit.lodGroup(parent, name, center, range)
	local m = Instance.new("Model")
	m.Name = name
	m:SetAttribute("Center", center)
	m:SetAttribute("Range", range)
	m.Parent = parent
	return m
end
function kit.addLight(className, parent, color, range, brightness, face, angle)
	local l = Instance.new(className)
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	if face then
		l.Face = face
	end
	if angle then
		l.Angle = angle
	end
	l.Parent = parent
	return l
end
function kit.surfaceText(part, face, text, color, bg, bgT, font, canvas)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.Parent = part
	local frame = Instance.new("Frame")
	frame.Parent = gui
	local label = Instance.new("TextLabel")
	label.Text = text
	label.TextColor3 = color
	label.Parent = frame
	return gui, frame, label
end

local world = Instance.new("Model")
Casino.buildWorld(kit, world)
GemShowcase.buildWorld(kit, world)

-- every part of each building stays inside its lot (a little slack for signs on the edge)
local function check(name: string, site: string)
	local model = world:FindFirstChild(name)
	assert(model, "missing " .. name)
	local frame, lot = WestLayout.site(site)
	local count, worst = 0, 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			count += 1
			local l = frame:PointToObjectSpace(p.CFrame.Position)
			worst = math.max(worst, math.abs(l.X), math.abs(l.Z))
		end
	end
	print(string.format("%s: %d parts, furthest %.1f from the middle (lot half %.1f)", name, count, worst, lot / 2))
	assert(worst <= lot / 2 + 6, name .. " spills out of its lot")
end
check("HighRollersCasino", "casino")
check("LegendsGemShowcase", "gems")
for tag, list in tags do
	print("tag", tag, #list)
end

-- wear every item on an R15 and an R6 stand-in
local function rig(r15: boolean)
	local character = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = if r15 then roblox.Enum.HumanoidRigType.R15 else roblox.Enum.HumanoidRigType.R6
	humanoid.Parent = character
	local function part(name, size, y)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = roblox.CFrame.new(0, y, 0)
		p.Parent = character
	end
	if r15 then
		part("UpperTorso", roblox.Vector3.new(2, 1.6, 1), 4)
		part("LeftLowerArm", roblox.Vector3.new(1, 1.2, 1), 3)
		part("RightHand", roblox.Vector3.new(1, 0.3, 1), 2)
		part("Head", roblox.Vector3.new(1.2, 1.2, 1.2), 5.4)
	else
		part("Torso", roblox.Vector3.new(2, 2, 1), 4)
		part("Left Arm", roblox.Vector3.new(1, 2, 1), 4)
		part("Right Arm", roblox.Vector3.new(1, 2, 1), 4)
		part("Head", roblox.Vector3.new(2, 1, 1), 5.5)
	end
	return character
end
for _, r15 in { true, false } do
	local character = rig(r15)
	for _, it in Config.Luxe.Items do
		Flex.wear(character, it)
	end
	local n = 0
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Flex" then
			n += 1
		end
	end
	print((if r15 then "R15" else "R6") .. ": " .. n .. " flex parts on, slots " .. #character:GetChildren() - 5)
end

-- the shop: buy, wear, take off, VIP
local remotes = {}
local ctx = { remote = function(class, name)
	local r = { ClassName = class, Name = name, FireClient = function() end, FireAllClients = function() end }
	remotes[name] = r
	return r
end }
Luxe.init(ctx)
local player = { DisplayName = "Tester", Character = nil, attrs = {} }
function player.GetAttribute(self, k)
	return self.attrs[k]
end
function player.SetAttribute(self, k, v)
	self.attrs[k] = v
end
profiles[player] = { Cash = 40000000, Level = 10, Luxe = { items = { "rope_silver", "bogus" }, worn = { Neck = "rope_silver", Head = "bogus" }, vip = 9 } }
local invoke = remotes.LuxeCall.OnServerInvoke
local s = invoke(player, "state").state
assert(#s.owned == 1 and s.worn.Neck == "rope_silver" and s.worn.Head == nil and s.vip == 3, "save not cleaned up")
profiles[player].Luxe = {}
assert(invoke(player, "buy", "crown_gold").ok)
assert(profiles[player].Cash == 35000000, "price wrong: " .. profiles[player].Cash)
assert(not invoke(player, "buy", "crown_gold").ok, "bought twice")
assert(invoke(player, "vip", 2).ok and profiles[player].Cash == 32500000, "vip price")
assert(invoke(player, "buy", "watch_diver").ok and profiles[player].Cash == 32500000 - math.floor(18000 * 0.9), "discount")
local before = profiles[player].Cash
assert(invoke(player, "vip", 3).ok and profiles[player].Cash == before - 22500000, "upgrade should cost the difference")
assert(not invoke(player, "vip", 2).ok, "downgrade allowed")
profiles[player].Cash = 100
assert(not invoke(player, "buy", "crown_imperial").ok and profiles[player].Cash == 100, "bought without the cash")
assert(invoke(player, "remove", "Head").ok)
assert(invoke(player, "state").state.worn.Head == nil)
assert(invoke(player, "wear", "crown_gold").state.worn.Head == "crown_gold")
assert(not invoke(player, "wear", "crown_imperial").ok, "wore a piece not owned")
-- the bag
local total, added = Luxe.addLoot(player, 50000, 60000)
assert(total == 50000 and added == 50000)
total, added = Luxe.addLoot(player, 50000, 60000)
assert(total == 60000 and added == 10000)
print("ALL OK")
