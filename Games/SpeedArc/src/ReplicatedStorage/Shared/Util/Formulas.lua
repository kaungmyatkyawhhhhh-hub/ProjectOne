-- Game formulas (GDD 6). Shared so the HUD can predict what the server will do.
local Shared = script.Parent.Parent
local GameConfig = require(Shared.Config.GameConfig)
local Race = require(Shared.Config.Race)
local Stations = require(Shared.Config.Stations)
local Course = require(Shared.Config.Course)
local Ranks = require(Shared.Config.Ranks)
local Areas = require(Shared.Config.Areas)

local Formulas = {}

function Formulas.walkSpeed(mph)
	local w = GameConfig.Walk
	return math.min(w.Cap, w.Base + w.Factor * math.log10(1 + math.max(0, mph) / w.Divider))
end

function Formulas.pace(speed, league)
	local mid = Race.LeagueMid[league or 1] or Race.LeagueMid[1]
	local x = math.log(math.max(speed, 1) / mid, 2)
	x = math.clamp(x, Race.PaceClampLow, Race.PaceClampHigh)
	return Race.BasePace * (1 + Race.PaceFactor * x)
end

function Formulas.coinsPerMinute(league)
	return GameConfig.Economy.CoinsPerMinute[league or 1]
end

-- Coins for `minutes` of play at this league
function Formulas.minutesOfCoins(minutes, league)
	return math.floor(Formulas.coinsPerMinute(league) * minutes + 0.5)
end

-- coins for one step (steps give about StepShare of the coins)
function Formulas.coinsPerStep(league)
	local e = GameConfig.Economy
	return Formulas.coinsPerMinute(league) * e.StepShare / (60 * e.AssumedStepsPerSecond)
end

-- walls smashed in a league (best ever, the save keeps them per league)
function Formulas.wallsIn(data, league)
	return (data.Walls or {})[tostring(league or data.League or 1)] or 0
end

-- SPEED per step before Boosts.compute(...).Train and the session boosts: the league's base gain x
-- the wall bonus of the walls you've smashed in your league
function Formulas.stepBase(data)
	local league = data.League or 1
	return (Course.StepGain[league] or 1) * Course.WallBonus ^ Formulas.wallsIn(data, league)
end

-- SPEED wall k of a league needs (rounded to 2 significant figures so the number reads well)
function Formulas.wallNeed(league, k)
	local list = Course.Walls[league]
	if list and list[k] then
		return list[k]
	end
	local champ = (Ranks.Thresholds[league] or Ranks.Thresholds[1])[#Ranks.Names]
	local v = champ * (Course.WallShares[k] or 1)
	local p = 10 ^ math.max(0, math.floor(math.log10(math.max(v, 1))) - 1)
	return math.floor(v / p + 0.5) * p
end

function Formulas.wallCount()
	return #Course.WallShares
end

-- does this league's area have a wall course yet? (Park and Stadium get theirs later)
function Formulas.hasCourse(league)
	for _, id in Areas.Order do
		if Areas[id].League == league and Course.Areas[id] then
			return true
		end
	end
	return false
end

function Formulas.station(id)
	for i, s in Stations do
		if s.Id == id then
			return s, i
		end
	end
	return nil
end

-- The next station of your league you can't use yet (the HUD goal), or nil
function Formulas.nextStation(speed, league)
	league = league or 1
	for _, s in Stations do
		if s.League == league and speed < s.MinSpeed then
			return s
		end
	end
	return nil
end

-- The best station of your league you can use
function Formulas.bestStation(speed, league)
	league = league or 1
	local best = nil
	for _, s in Stations do
		if s.League == league and speed >= s.MinSpeed then
			best = s
		end
	end
	return best
end

-- previous threshold of the league's stations below speed (for the HUD progress bar)
function Formulas.stationFloor(speed, league)
	local v = 0
	for _, s in Stations do
		if s.League == (league or 1) and s.MinSpeed <= speed then
			v = s.MinSpeed
		end
	end
	return v
end

return Formulas
