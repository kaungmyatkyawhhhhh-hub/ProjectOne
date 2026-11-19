--[[
	LaneHeights (2026-11-19, owner: "npc traffic cars falling inside a bridge"): measures every 1:1 lane point against the
	BUILT road collision (Workspace.Yangon1to1.Roads.Collide, RoadBox "R" carriageway / "D" deck only) and lists the points
	that are not on it, for tools/yangon/city/roads05_lanes.py (build/city_1to1/roads05_<tag>/lane_heights.txt).

	Run in Edit after the lanes are in ReplicatedStorage.Shared:
		local LH = require(game.ServerStorage.ClaudeTools.LaneHeights:Clone())
		LH.start()            -- background; LH.status() until "done"
		LH.page(1)            -- "x z y below above" lines (b / a = nearest R/D top below / above the point, "-" = none);
		                         about 2,400 lines a page, LH.pages() of them
	The Python side decides what to move (it knows which points are on a deck): a top <= 6 above lifts the point onto it
	(a car there is inside the slab), a ground point floating over a top drops onto it, a deck point over nothing stays
	(a hole in the deck collision: reported).
]]

local LH = {}
local RS = game:GetService("ReplicatedStorage")

local UP, DOWN = 8, 60 -- search window over / under each point
local OK = 0.6 -- a point within this over its surface is fine

local state = "idle"
local rows = {}
local stats = {}

local function tops(p: Vector3, rp: RaycastParams)
	-- every R / D top under p + UP down to p - DOWN, top first (a ray that starts inside a box doesn't see it)
	local out = {}
	local from = p + Vector3.new(0, UP, 0)
	local left = UP + DOWN
	for _ = 1, 8 do
		local h = workspace:Raycast(from, Vector3.new(0, -left, 0), rp)
		if not h then
			break
		end
		local k = h.Instance:GetAttribute("RoadBox")
		if (k == "R" or k == "D") and h.Normal.Y > 0.5 then
			table.insert(out, h.Position.Y)
		end
		local step = from.Y - h.Position.Y + 0.05
		from -= Vector3.new(0, step, 0)
		left -= step
		if left <= 0 then
			break
		end
	end
	return out
end

function LH.run()
	local col = workspace.Yangon1to1.Roads.Collide
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { col }
	table.clear(rows)
	stats = { points = 0, fine = 0, listed = 0, none = 0 }
	local c = 0
	for m = 1, 99 do
		local mod = RS.Shared:FindFirstChild("YangonLanes1to1_" .. m)
		if not mod then
			break
		end
		local L = require(mod:Clone())
		for _, lane in L.lanes do
			local pts = lane.pts
			for k = 1, #pts, 3 do
				local p = Vector3.new(pts[k], pts[k + 1], pts[k + 2])
				stats.points += 1
				local below, above
				for _, y in tops(p, rp) do
					if y <= p.Y + OK then
						if not below or y > below then
							below = y
						end
					elseif not above or y < above then
						above = y
					end
				end
				if below and p.Y - below <= OK and not above then
					stats.fine += 1
				elseif not below and not above then
					stats.none += 1
				else
					stats.listed += 1
					table.insert(rows, string.format("%.2f %.2f %.2f %s %s", pts[k], pts[k + 2], pts[k + 1],
						below and string.format("%.2f", below) or "-", above and string.format("%.2f", above) or "-"))
				end
				c += 1
				if c % 400 == 0 then
					task.wait()
				end
			end
		end
	end
	state = "done"
end

function LH.start()
	state = "running"
	task.spawn(function()
		local ok, e = pcall(LH.run)
		if not ok then
			state = "error: " .. tostring(e)
		end
	end)
	return state
end

function LH.status()
	return state, stats
end

local PER = 2400
function LH.pages(): number
	return math.ceil(#rows / PER)
end

function LH.page(n: number): string
	return table.concat(rows, "\n", (n - 1) * PER + 1, math.min(#rows, n * PER))
end

return LH
