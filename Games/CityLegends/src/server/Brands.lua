--[[
	Brands (owner, 2026-10-30, from the research: Midnight Racing's manufacturer levels)
	Driving a brand's cars levels that brand up (miles and cut-ups, Config.Brands). A higher brand
	level makes Legends Customs cheaper on its cars and opens its top trims a few levels sooner.
	Saved as profile.Brands ({ BRAND = xp }); the levels are on the player as the "BrandLevels"
	attribute (JSON { BRAND = level }) for the garage and the level-up toast.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Brands = {}

function Brands.brandOf(carId: string): string?
	local at = Cars.SeriesOf[carId]
	return if at then at.series.Brand else nil
end

local function xpTable(profile: any): { [string]: number }
	if type(profile.Brands) ~= "table" then
		profile.Brands = {}
	end
	return profile.Brands
end

-- this player's level with the brand of `carId` (1 when unknown)
function Brands.levelFor(player: Player, carId: string): number
	local profile = PlayerData.get(player) :: any
	local brand = Brands.brandOf(carId)
	if not profile or not brand then
		return 1
	end
	return Config.brandLevel(xpTable(profile)[brand] or 0)
end

function Brands.publish(player: Player)
	local profile = PlayerData.get(player) :: any
	if not profile then
		return
	end
	local levels = {}
	for brand, xp in xpTable(profile) do
		if type(xp) == "number" then
			local lvl = Config.brandLevel(xp)
			if lvl > 1 then
				levels[brand] = lvl
			end
		end
	end
	player:SetAttribute("BrandLevels", HttpService:JSONEncode(levels))
end

-- brand XP for driving `carId` (miles, cut-ups)
function Brands.add(player: Player, carId: string, xp: number)
	local profile = PlayerData.get(player) :: any
	local brand = Brands.brandOf(carId)
	if not profile or not profile.Loaded or not brand or xp <= 0 then
		return
	end
	local t = xpTable(profile)
	local before = Config.brandLevel(t[brand] or 0)
	t[brand] = (t[brand] or 0) + xp
	if Config.brandLevel(t[brand]) > before then
		Brands.publish(player)
	end
end

return Brands
