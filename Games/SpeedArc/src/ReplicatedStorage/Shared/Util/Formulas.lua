-- Game formulas (GDD 6). Shared so the HUD can predict what the server will do.
local Shared = script.Parent.Parent
local GameConfig = require(Shared.Config.GameConfig)
local Race = require(Shared.Config.Race)
local Stations = require(Shared.Config.Stations)

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

function Formulas.coinsPerTap(league)
	local e = GameConfig.Economy
	return Formulas.coinsPerMinute(league) * e.TrainingShare / (60 * e.AssumedTapsPerSecond)
end

-- Combo multiplier from how long the player has tapped steadily
function Formulas.combo(steadySeconds)
	local c = GameConfig.Combo
	return 1 + (c.Max - 1) * math.clamp(steadySeconds / c.BuildSeconds, 0, 1)
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
