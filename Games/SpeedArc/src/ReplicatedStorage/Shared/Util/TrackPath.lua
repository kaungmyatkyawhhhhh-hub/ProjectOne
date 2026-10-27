-- Positions along the oval School Track. Shared by the server (race), the client (drawing runners)
-- and the world builder (painting lanes), so they always agree.
local Race = require(script.Parent.Parent.Config.Race)

local T = Race.Track
local TrackPath = {}

function TrackPath.laneRadius(lane)
	return T.InnerRadius + T.LaneWidth * (lane - 0.5)
end

function TrackPath.lapLength(radius)
	return 2 * T.Straight + 2 * math.pi * radius
end

-- Point and forward direction at distance s (studs) from the start line, running anticlockwise
-- seen from above: +X on the home straight (+Z side), then round the east bend, back along -X.
function TrackPath.at(radius, s, y)
	local half = T.Straight / 2
	local perim = TrackPath.lapLength(radius)
	s = s % perim
	y = y or 0
	local c = T.Center

	local a = half - T.StartX -- rest of the home straight
	if s < a then
		return c + Vector3.new(T.StartX + s, y, radius), Vector3.new(1, 0, 0)
	end
	s -= a
	local bend = math.pi * radius
	if s < bend then
		local th = s / radius
		return c + Vector3.new(half + radius * math.sin(th), y, radius * math.cos(th)), Vector3.new(math.cos(th), 0, -math.sin(th))
	end
	s -= bend
	if s < T.Straight then
		return c + Vector3.new(half - s, y, -radius), Vector3.new(-1, 0, 0)
	end
	s -= T.Straight
	if s < bend then
		local th = s / radius
		return c + Vector3.new(-half - radius * math.sin(th), y, -radius * math.cos(th)), Vector3.new(-math.cos(th), 0, math.sin(th))
	end
	s -= bend
	return c + Vector3.new(-half + s, y, radius), Vector3.new(1, 0, 0)
end

-- CFrame of a runner in a lane at race progress p (0..1) for a race of `laps` laps.
-- Every lane uses the same progress, so all lanes finish on the same line at the same time.
-- A fractional race (1.5 laps) starts part-way round so it still ends on the gold line.
function TrackPath.runnerCFrame(lane, progress, laps)
	local r = TrackPath.laneRadius(lane)
	local startOffset = (-laps) % 1
	local s = (startOffset + progress * laps) * TrackPath.lapLength(r)
	local pos, dir = TrackPath.at(r, s, T.SurfaceY + T.HipY)
	return CFrame.lookAt(pos, pos + dir)
end

-- Race length in studs, measured on lane 1 (used for pace and slipstream).
function TrackPath.raceLength(laps)
	return laps * TrackPath.lapLength(TrackPath.laneRadius(1))
end

return TrackPath
