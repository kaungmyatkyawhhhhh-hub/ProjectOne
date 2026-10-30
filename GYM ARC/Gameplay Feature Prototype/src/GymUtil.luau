--[[
	GymUtil
	Small pure helpers shared by the server and the client.
	The needle function is shared on purpose: the server re-computes where the
	needle was when the player tapped, so "perfect" reps can't be faked.
]]

local Config = require(script.Parent:WaitForChild("GymConfig"))

local Util = {}

local SUFFIXES = { "", "K", "M", "B", "T" }

function Util.format(n: number): string
	n = math.floor(n)
	local i = 1
	local v = n
	while v >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(n)
	end
	return string.format(v < 10 and "%.2f%s" or (v < 100 and "%.1f%s" or "%.0f%s"), v, SUFFIXES[i])
end

-- Returns the rank index and the rank table for a Strength value.
function Util.rankFor(strength: number)
	local index = 1
	for i, rank in ipairs(Config.Ranks) do
		if strength >= rank.min then
			index = i
		end
	end
	return index, Config.Ranks[index]
end

-- Needle position 0..1 that ping-pongs across the timing bar.
function Util.needle(elapsed: number, speed: number): number
	local x = (elapsed * speed) % 2
	return if x <= 1 then x else 2 - x
end

function Util.needleSpeed(tier: number): number
	return Config.Rep.needleSpeed + (tier - 1) * Config.Rep.needleSpeedPerTier
end

-- Body scale values for a Strength value (log curve: fast early, slower later).
function Util.bodyScale(strength: number)
	local t = math.clamp(math.log10(1 + strength) / math.log10(1 + Config.Body.strengthForMax), 0, 1)
	return 1 + Config.Body.maxExtraWidth * t, 1 + Config.Body.maxExtraDepth * t, 1 + Config.Body.maxExtraHeight * t
end

return Util
