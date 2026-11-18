-- Lune test for src/server/Store.lua's ProcessReceipt: idempotent, rolls back a failed save,
-- waits for the save to load, Starter Pack once.
--   lune run tools/store_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local function load(path: string, env: { [string]: any }): any
	return luau.load(fs.readFile(root .. "/" .. path), { debugName = path, environment = env })()
end

local baseEnv = { Color3 = roblox.Color3, Vector3 = roblox.Vector3, Vector2 = roblox.Vector2, UDim2 = roblox.UDim2, Enum = roblox.Enum, CFrame = roblox.CFrame }
local Config = load("src/shared/Config.lua", baseEnv)

local player = { UserId = 7, Name = "T", attrs = {} }
function player:GetAttribute(k) return self.attrs[k] end
function player:SetAttribute(k, v) self.attrs[k] = v end
local profile = { Loaded = false, Cash = 0, Owned = {}, Rewards = { Receipts = {}, Spins = {}, StarterPack = false, StarterPick = false } }
local saveOk = true
local saves = 0
local PlayerData = {
	get = function() return profile end,
	addCash = function(_, n) profile.Cash += n end,
	save = function() saves += 1 return saveOk end,
}

local function waitFor(_, name) return { name = name } end
local game = {
	GetService = function(_, name)
		if name == "Players" then
			return { GetPlayerByUserId = function(_, id) return if id == 7 then player else nil end }
		elseif name == "ReplicatedStorage" then
			return { WaitForChild = function() return { WaitForChild = waitFor } end }
		end
		return {}
	end,
}
local env = table.clone(baseEnv)
env.game = game
env.script = { Parent = { WaitForChild = waitFor } }
env.require = function(x)
	if x.name == "Config" then return Config elseif x.name == "PlayerData" then return PlayerData end
	error("require " .. tostring(x.name))
end
env.task = { spawn = function(f) f() end }
env.warn = function() end
local notes = {}
local deps = {
	Rewards = { data = function(p) return p.Rewards end, send = function(_, m) table.insert(notes, m.what) end, refresh = function() end },
	Houses = { bayRoom = function() return nil end, rebuild = function() end },
	Cars = { forSale = function() return true end, ById = {} },
	notify = function(_, m) table.insert(notes, m) end,
}
-- Store.init needs these services too
game.GetService = (function(old)
	return function(self, name)
		if name == "MarketplaceService" then
			return { PromptGamePassPurchaseFinished = { Connect = function() end } }
		elseif name == "RunService" then
			return { IsStudio = function() return false end }
		elseif name == "Players" then
			local p = old(self, name)
			p.PlayerMembershipChanged = { Connect = function() end }
			p.PlayerAdded = { Connect = function() end }
			p.GetPlayers = function() return {} end
			return p
		end
		return old(self, name)
	end
end)(game.GetService)
local Store = load("src/server/Store.lua", env)
Store.init({}, deps)

local D = roblox.Enum.ProductPurchaseDecision
local fails = 0
local function check(name, ok)
	print((if ok then "PASS " else "FAIL ") .. name)
	if not ok then fails += 1 end
end
local function receipt(pid, product)
	return Store.processReceipt({ PlayerId = 7, PurchaseId = pid, ProductId = product })
end

check("waits while the save is not loaded", receipt("a1", Config.Products.Spin) == D.NotProcessedYet and (profile.Rewards.Spins.wheel or 0) == 0)
profile.Loaded = true
check("spin granted", receipt("a1", Config.Products.Spin) == D.PurchaseGranted and profile.Rewards.Spins.wheel == 1)
check("same receipt again grants nothing", receipt("a1", Config.Products.Spin) == D.PurchaseGranted and profile.Rewards.Spins.wheel == 1)
saveOk = false
check("failed save rolls back", receipt("a2", Config.Products.Spin) == D.NotProcessedYet and profile.Rewards.Spins.wheel == 1 and not table.find(profile.Rewards.Receipts, "a2"))
saveOk = true
check("retry after the failed save", receipt("a2", Config.Products.Spin) == D.PurchaseGranted and profile.Rewards.Spins.wheel == 2)
check("starter pack", receipt("s1", Config.Products.StarterPack) == D.PurchaseGranted and profile.Cash == Config.StarterPackCash and profile.Rewards.StarterPack and profile.Rewards.StarterPick)
check("starter pack once: a second buy pays its cash only", receipt("s2", Config.Products.StarterPack) == D.PurchaseGranted and profile.Cash == 2 * Config.StarterPackCash and profile.Rewards.StarterPick)
check("garage space with no house pays the space's cash", receipt("g1", Config.Products.GarageSpace) == D.PurchaseGranted and profile.Cash == 2 * Config.StarterPackCash + Config.Houses.BayPrices[1])
check("unknown product waits", receipt("x1", 1) == D.NotProcessedYet)
player.attrs.Cash2x = true
player.attrs.Vip = true
check("2x Cash + VIP on cut-ups", math.abs(Store.earnMult(player, "cut") - 2 * Config.VipCutBonus) < 1e-9)
check("VIP not on jobs", Store.earnMult(player, "job") == 2)
if fails > 0 then
	process.exit(1)
end
print("store_test: all passed")
