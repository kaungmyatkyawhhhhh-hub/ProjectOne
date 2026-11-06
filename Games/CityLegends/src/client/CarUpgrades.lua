--[[
	CarUpgrades (client) (owner, 2026-11-03: "car class grades and car levels")
	  * keeps each owned car's level, XP, Car Points, parts, settings and builds, and the spare parts
	    (CarCall "state", then the server's CarProgress pushes); UI.carInfo reads them for the garage,
	    the HUD strip over the speedometer shows the driven car's class and level
	  * a level-up pops up "CAR LEVEL n" with the CP it gave, a free part pops up too
	The parts screen itself is client/Workshop (2026-11-06): it sets CarUpgrades.screen.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local PartData = require(Shared:WaitForChild("PartData"))

local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local CarUpgrades = {}

export type Info = { level: number, xp: number, need: number, cp: number, parts: CarStats.Parts, setup: CarStats.Setup, builds: any, look: any }

local _player = Players.LocalPlayer
local L = Config.CarLevels
local GOLD = Color3.fromRGB(255, 196, 92)
local GREEN = Color3.fromRGB(110, 224, 150)

local call: RemoteFunction? = nil
local cache: { [string]: { [string]: any } } = {}
local bag: { [string]: { number } } = {} -- the spare parts: part id = { price factor of each }
local listeners: { () -> () } = {}

-- the parts screen, once Workshop has started: { open, close, isOpen }
CarUpgrades.screen = nil :: { open: (string) -> (), close: () -> (), isOpen: () -> boolean }?

local function changed()
	for _, f in listeners do
		task.spawn(f)
	end
end

-- a car's level, XP, CP and parts (level 1 and nothing for a car the server hasn't told us about)
function CarUpgrades.get(carId: string): Info
	local st = cache[carId]
	if not st then
		return { level = 1, xp = 0, need = Config.carXpFor(1), cp = 0, parts = {}, setup = {}, builds = nil, look = nil }
	end
	return {
		level = tonumber(st.level) or 1,
		xp = tonumber(st.xp) or 0,
		need = tonumber(st.need) or 0,
		cp = tonumber(st.cp) or 0,
		parts = CarStats.decodeParts(st.partsText),
		setup = CarStats.decodeSetup(st.setupText),
		builds = st.builds,
		look = st.look,
	}
end

-- the spare parts
function CarUpgrades.bag(): { [string]: { number } }
	return bag
end

function CarUpgrades.onChange(fn: () -> ())
	table.insert(listeners, fn)
end

-- the same, for a screen that goes away: returns something with Disconnect
function CarUpgrades.onChangeConn(fn: () -> ()): any
	table.insert(listeners, fn)
	return {
		Disconnect = function()
			local at = table.find(listeners, fn)
			if at then
				table.remove(listeners, at)
			end
		end,
	}
end

function CarUpgrades.refresh()
	if not call then
		return
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer("state")
	end)
	if ok and type(res) == "table" and res.ok and type(res.cars) == "table" then
		cache = res.cars
		bag = if type(res.bag) == "table" then res.bag else {}
		changed()
	end
end

-- a call to the server (the Workshop's buy, install ...): the answer also updates what we keep
function CarUpgrades.ask(what: string, arg: any): { [string]: any }
	if not call then
		return { ok = false, message = "Try again" }
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	if not (ok and type(res) == "table") then
		return { ok = false, message = "Try again" }
	end
	if res.ok then
		if type(res.bag) == "table" then
			bag = res.bag
		end
		local carId = if type(arg) == "table" then arg.car else nil
		if type(carId) == "string" then
			local st = cache[carId] or { level = 1, xp = 0, need = Config.carXpFor(1), cp = 0 }
			if res.partsText ~= nil then
				st.partsText = res.partsText
			end
			if res.setupText ~= nil then
				st.setupText = res.setupText
			end
			if res.cp ~= nil then
				st.cp = res.cp
			end
			if res.builds ~= nil then
				st.builds = res.builds
			end
			cache[carId] = st
		end
		if type(res.cash) == "number" then
			UI.setCash(res.cash)
		end
		changed()
	end
	return res
end

---------------------------------------------------------------------
-- the HUD strip over the speedometer (the car you're driving)
---------------------------------------------------------------------
local function hudUpdate()
	local model = Driving.getModel()
	local id = model and model:GetAttribute("CarId")
	if type(id) ~= "string" or (model and (model:GetAttribute("Stolen") or model:GetAttribute("TestEnds"))) then
		UI.setCarHud(nil)
		return
	end
	local info = CarUpgrades.get(id)
	local parts = CarStats.decodeParts((model :: Model):GetAttribute("Parts"))
	local letter, _, pi = CarStats.classOf(id, parts)
	UI.setCarHud({ letter = letter, pi = pi, level = info.level, xp = info.xp, need = info.need })
end

-- the screen is shut or shutting (the key that shut it mustn't go on to shut the main menu)
function CarUpgrades.isOpen(): boolean
	local sc = CarUpgrades.screen
	return sc ~= nil and sc.isOpen()
end

function CarUpgrades.close()
	local sc = CarUpgrades.screen
	if sc then
		sc.close()
	end
end

---------------------------------------------------------------------
-- start
---------------------------------------------------------------------
function CarUpgrades.init()
	UI.carInfo = CarUpgrades.get
	UI.onUpgrade = function(carId: string)
		local sc = CarUpgrades.screen
		if sc then
			sc.open(carId)
		end
	end
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		call = remotes:WaitForChild("CarCall", 120) :: RemoteFunction?
		local progress = remotes:WaitForChild("CarProgress", 120) :: RemoteEvent?
		if progress then
			progress.OnClientEvent:Connect(function(st: any)
				if type(st) ~= "table" then
					return
				end
				-- a free part
				if type(st.drop) == "string" then
					if type(st.bag) == "table" then
						bag = st.bag
					end
					local def = PartData.Parts[st.drop]
					if def then
						local rarity = PartData.Rarity[def.rarity]
						UI.popup(rarity.name .. " PART", 0, rarity.text)
						UI.toast("Free part: " .. def.name .. ". It's in My Parts at the workshop", rarity.text)
					end
					changed()
					return
				end
				if type(st.carId) ~= "string" then
					return
				end
				local old = cache[st.carId]
				if old then
					-- (a push doesn't carry these)
					st.builds = st.builds or old.builds
					st.look = st.look or old.look
				end
				cache[st.carId] = st
				if st.levelUp then
					local name = Cars.get(st.carId).Name
					UI.popup("CAR LEVEL " .. tostring(st.level), 0, GOLD)
					UI.toast(string.format("+%d CP for the %s: spend it on parts (garage: UPGRADE) or Legends Customs", tonumber(st.gainedCp) or 0, name), GOLD)
					if (tonumber(st.level) or 0) >= L.Max then
						task.delay(2.5, function()
							UI.toast(Cars.upper(Cars.makeOf(name)) .. " brand bonus: cheaper at Legends Motors", GREEN)
						end)
					end
				end
				changed()
			end)
		end
		CarUpgrades.refresh()
	end)
	-- the HUD strip: the car you're in (also when its parts change)
	CarUpgrades.onChange(hudUpdate)
	local lastKey = ""
	task.spawn(function()
		while true do
			task.wait(0.5)
			local model = Driving.getModel()
			local key = if model then tostring(model:GetAttribute("CarId")) .. "|" .. tostring(model:GetAttribute("Parts")) else ""
			if key ~= lastKey then
				lastKey = key
				if model and cache[tostring(model:GetAttribute("CarId"))] == nil then
					CarUpgrades.refresh() -- a car just bought: its level from the server
				end
				hudUpdate()
			end
		end
	end)
end

return CarUpgrades
