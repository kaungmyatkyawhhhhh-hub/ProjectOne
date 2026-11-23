--[[
	WaterRescue (2026-11-21, owner: "make it so that when a car goes in water, they get teleported back to the
	nearest road near the water, facing the roads direction"). The decision parts only (no engine calls), so
	tools/water_rescue_test.luau can run them; client/Driving does the water test, the raycasts and the move.

	  local st = WaterRescue.new()
	  local from = WaterRescue.step(st, wet, pos, dt, now)   -- the point where it went in, once, when it's time
	  local list = WaterRescue.candidates(lanes, CityLayout.sample, from, 8, 24)   -- nearest first
	  (the caller sets c.dry on each)   local c = WaterRescue.pick(list)
]]
local WaterRescue = {}

WaterRescue.Every = 0.2 -- seconds between water checks (not every frame)
WaterRescue.Hold = 1 -- seconds in the water before the car goes back
WaterRescue.Cooldown = 4 -- seconds after a rescue with no new one (it can't loop)
WaterRescue.Reach = 300 -- studs past the nearest lane that still count as "near the water"

export type State = { t: number, at: any, coolUntil: number }
export type Candidate = { p: any, dir: any, d: number, dry: boolean? }

function WaterRescue.new(): State
	return { t = 0, at = nil, coolUntil = 0 }
end

-- one water check: `wet` = the car is in the water now, `dt` = seconds since the last check. Returns the place
-- the car was when it went in (the road nearest to THAT is wanted, not to where it drifted to) once it has
-- been wet for Hold seconds, else nil
function WaterRescue.step(st: State, wet: boolean, pos: any, dt: number, now: number): any
	if not wet or now < st.coolUntil then
		st.t, st.at = 0, nil
		return nil
	end
	if not st.at then
		st.at = pos
	end
	st.t += dt
	if st.t < WaterRescue.Hold then
		return nil
	end
	local at = st.at
	st.t, st.at, st.coolUntil = 0, nil, now + WaterRescue.Cooldown
	return at
end

-- the `n` lane points nearest to `pos`, nearest first, at least `gap` studs apart (so the next choice is a
-- different stretch of road, not 3 studs further along the same wet one). segs: { p1, length };
-- sample(seg, s) -> position, forward (CityLayout.sample)
function WaterRescue.candidates(segs: { any }, sample: (any, number) -> (any, any), pos: any, n: number, gap: number): { Candidate }
	-- (92k lane pieces on the 1:1 map) a cheap pass for the nearest piece, then only the pieces near that
	local near = math.huge
	for _, seg in segs do
		near = math.min(near, (seg.p1 - pos).Magnitude)
	end
	local found: { Candidate } = {}
	for _, seg in segs do
		if (seg.p1 - pos).Magnitude < seg.length + near + WaterRescue.Reach then
			local k = math.max(2, math.ceil(seg.length / 3))
			local best: Candidate? = nil
			for i = 0, k do
				local p, dir = sample(seg, seg.length * i / k)
				local d = (p - pos).Magnitude
				if not best or d < best.d then
					best = { p = p, dir = dir, d = d }
				end
			end
			table.insert(found, best :: Candidate)
		end
	end
	table.sort(found, function(a, b)
		return a.d < b.d
	end)
	local out: { Candidate } = {}
	for _, c in found do
		if #out >= n then
			break
		end
		local apart = true
		for _, o in out do
			if (o.p - c.p).Magnitude < gap then
				apart = false
				break
			end
		end
		if apart then
			table.insert(out, c)
		end
	end
	return out
end

-- the nearest candidate on a dry road; when none is (road boxes not streamed in yet), the nearest one anyway:
-- a doubtful road beats staying in the water
function WaterRescue.pick(list: { Candidate }): Candidate?
	for _, c in list do
		if c.dry then
			return c
		end
	end
	return list[1]
end

return WaterRescue
