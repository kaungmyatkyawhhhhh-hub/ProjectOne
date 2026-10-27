-- Positions along an oval track. Shared by the server (races), the client (drawing runners)
-- and the world builders (painting lanes), so they always agree.
-- TrackPath.for(track) gives the functions for one area's track; the module functions use the hub's.
local Race = require(script.Parent.Parent.Config.Race)

local TrackPath = {}

local function make(T)
	local api = {}

	function api.laneRadius(lane)
		return T.InnerRadius + T.LaneWidth * (lane - 0.5)
	end

	function api.lapLength(radius)
		return 2 * T.Straight + 2 * math.pi * radius
	end

	-- Point and forward direction at distance s from the start line, anticlockwise seen from above:
	-- +X on the home straight (+Z side), round the east bend, back along -X.
	function api.at(radius, s, y)
		local half = T.Straight / 2
		local perim = api.lapLength(radius)
		s = s % perim
		y = y or 0
		local c = T.Center
		local a = half - T.StartX
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

	-- Runner CFrame in a lane at progress p (0..1) for a race of `laps` laps. Every lane uses the
	-- same progress, so all lanes finish together; fractional races start part-way round.
	function api.runnerCFrame(lane, progress, laps, lift)
		local r = api.laneRadius(lane)
		local startOffset = (-laps) % 1
		local s = (startOffset + progress * laps) * api.lapLength(r)
		local pos, dir = api.at(r, s, T.SurfaceY + T.HipY + (lift or 0))
		return CFrame.lookAt(pos, pos + dir)
	end

	-- Race length in studs, measured on lane 1 (pace and slipstream)
	function api.raceLength(laps)
		return laps * api.lapLength(api.laneRadius(1))
	end

	api.track = T
	return api
end

local cache = {}
function TrackPath.for_(track)
	local api = cache[track]
	if not api then
		api = make(track)
		cache[track] = api
	end
	return api
end
TrackPath["for"] = TrackPath.for_

-- the hub's track (prompt 1 callers)
local hub = make(Race.Track)
for k, v in hub do
	TrackPath[k] = v
end

return TrackPath
