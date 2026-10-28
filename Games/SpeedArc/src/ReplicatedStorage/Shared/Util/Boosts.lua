-- Every multiplier in one place, worked out from a player's save. Server uses it for real gains;
-- the HUD uses the same maths to show "+x per tap" and the Locker / Coaches numbers.
local Shared = script.Parent.Parent
local Shoes = require(Shared.Config.Shoes)
local Trails = require(Shared.Config.Trails)
local Coaches = require(Shared.Config.Coaches)
local Ranks = require(Shared.Config.Ranks)
local Store = require(Shared.Config.Store)
local GameConfig = require(Shared.Config.GameConfig)

local Boosts = {}

local shoeById, trailById, coachById = {}, {}, {}
for _, s in Shoes.List do
	shoeById[s.Id] = s
end
for _, t in Trails.List do
	trailById[t.Id] = t
end
for _, c in Coaches.List do
	coachById[c.Id] = c
end
Boosts.shoe = function(id)
	return shoeById[id]
end
Boosts.trail = function(id)
	return trailById[id]
end
Boosts.coach = function(id)
	return coachById[id]
end

function Boosts.coachValues(coachId, stage)
	local c = coachById[coachId]
	local m = Coaches.StageMult[stage or 1] or 1
	return (c.Train or 0) * m, (c.Pace or 0) * m, (c.Coins or 0) * m
end

function Boosts.slotCount(data)
	local n = Coaches.FreeSlots
	for _, pass in Coaches.SlotPasses do
		if data.Passes and data.Passes[pass] then
			n += 1
		end
	end
	return n
end

local function coachTotals(data)
	local train, pace, coins = 0, 0, 0
	local byUid = {}
	for _, e in data.Coaches or {} do
		byUid[e.Uid] = e
	end
	for i, uid in data.EquippedCoaches or {} do
		if i > Boosts.slotCount(data) then
			break
		end
		local e = byUid[uid]
		if e and coachById[e.Id] then
			local t, p, c = Boosts.coachValues(e.Id, e.Stage)
			train += t
			pace += p
			coins += c
		end
	end
	local cap = Coaches.Caps
	return math.min(train, cap.Train), math.min(pace, cap.Pace), math.min(coins, cap.Coins)
end

-- returns { Train = x, Pace = x, Coins = x } (all multipliers, 1 = none)
function Boosts.compute(data)
	local shoe = shoeById[data.Shoe] or shoeById[Shoes.Default]
	local trail = trailById[data.Trail] or trailById[Trails.Default]
	local cTrain, cPace, cCoins = coachTotals(data)
	local leagueMult = (GameConfig.LeagueTrainMult or 8) ^ ((data.League or 1) - 1)
	-- passes (M5): 2x Speed doubles training, 2x Coins doubles coins, VIP +10% coins. Nothing for races.
	local passes = data.Passes or {}
	local passTrain = if passes.Speed2x then 2 else 1
	local passCoins = (if passes.Coins2x then 2 else 1) * (if passes.VIP then 1 + Store.VIP.Coins else 1)
	return {
		Train = shoe.Train * (1 + cTrain) * (1 + (trail.Train or 0)) * leagueMult * passTrain,
		Pace = 1 + shoe.Pace + cPace,
		Coins = math.min(GameConfig.Economy.CoinMultCap or 8, (1 + cCoins) * (1 + (trail.Coins or 0)) * passCoins),
		CoachTrain = cTrain,
		CoachPace = cPace,
		CoachCoins = cCoins,
	}
end

-- rank index inside a league for a speed
function Boosts.rankIndex(league, speed)
	local t = Ranks.Thresholds[league or 1]
	local idx = 1
	for i, v in t do
		if speed >= v then
			idx = i
		end
	end
	return idx
end

-- has the player reached what an item needs? Unlock = { League = n, Rank = "Silver" }
function Boosts.unlocked(data, unlock)
	if not unlock then
		return true
	end
	local need = unlock.League or 1
	local best = data.BestLeague or 1
	if best > need then
		return true
	end
	if (data.League or 1) < need then
		return false
	end
	if not unlock.Rank then
		return true
	end
	local want = table.find(Ranks.Names, unlock.Rank) or 1
	local have = math.max(Boosts.rankIndex(need, data.Speed or 0), data.BestRank and data.BestRank[tostring(need)] or 1)
	return have >= want
end

function Boosts.unlockText(unlock)
	if not unlock then
		return ""
	end
	if unlock.Rank then
		return ("UNLOCKS AT LEAGUE %d %s"):format(unlock.League or 1, string.upper(unlock.Rank))
	end
	return ("UNLOCKS IN LEAGUE %d"):format(unlock.League or 1)
end

return Boosts
