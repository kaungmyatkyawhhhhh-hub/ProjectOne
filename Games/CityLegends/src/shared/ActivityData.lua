--[[
	ActivityData
	Where the things to do are (shared by server and client, all worked out from the city grid):
	  * time-trial races: routes through the street grid, a checkpoint at every junction, with
	    gold / silver / bronze times from the route length
	  * delivery jobs: two dispatch points and the drop points they send you to
	  * Legends chips: 25 hidden collectibles on the sidewalks, round the landmarks and the bank
]]

local Config = require(script.Parent.Config)
local CityLayout = require(script.Parent.CityLayout)

local C = Config.City
local N = C.Blocks
local A = Config.Activities

local ActivityData = {}

export type Race = {
	id: string,
	name: string,
	start: Vector3,
	startDir: Vector3,
	checkpoints: { Vector3 },
	length: number,
	gold: number,
	silver: number,
	bronze: number,
}

-- a corner-to-corner route through the grid: a checkpoint at every junction passed
local function route(id: string, name: string, corners: { { number } }): Race
	local cps: { Vector3 } = {}
	local length = 0
	for k = 1, #corners - 1 do
		local a, b = corners[k], corners[k + 1]
		local di = if b[1] > a[1] then 1 elseif b[1] < a[1] then -1 else 0
		local dj = if b[2] > a[2] then 1 elseif b[2] < a[2] then -1 else 0
		local i, j = a[1], a[2]
		while i ~= b[1] or j ~= b[2] do
			i += di
			j += dj
			local p = CityLayout.intersectionPos(i, j)
			if #cps > 0 then
				length += (p - cps[#cps]).Magnitude
			end
			table.insert(cps, p)
		end
	end
	local first = CityLayout.intersectionPos(corners[1][1], corners[1][2])
	local dir = (cps[1] - first).Unit
	-- the start line: a little before the first junction, in the right-hand lane
	local right = dir:Cross(Vector3.yAxis)
	local start = first + dir * (C.RoadWidth / 2 + 30) + right * (C.LaneWidth * 1.5)
	length += (cps[1] - start).Magnitude
	return {
		id = id,
		name = name,
		start = start,
		startDir = dir,
		checkpoints = cps,
		length = length,
		gold = length / Config.mphToSps(A.GoldMph),
		silver = length / Config.mphToSps(A.SilverMph),
		bronze = length / Config.mphToSps(A.BronzeMph),
	}
end

ActivityData.races = {
	route("downtown", "Downtown Sprint", { { 0, 1 }, { 3, 1 }, { 3, 4 }, { 6, 4 } }),
	route("ring", "City Ring", { { 0, 0 }, { N, 0 }, { N, N }, { 0, N }, { 0, 1 } }),
	route("zigzag", "Zigzag", { { 1, N }, { 1, 2 }, { 3, 2 }, { 3, 5 }, { 5, 5 }, { 5, 0 } }),
	route("cross", "Crosstown", { { N, 2 }, { 2, 2 }, { 2, 6 }, { 4, 6 }, { 4, 0 } }),
} :: { Race }

ActivityData.raceById = {} :: { [string]: Race }
for _, r in ActivityData.races do
	ActivityData.raceById[r.id] = r
end

-- the sidewalk at a junction's corner (on the block at +i / +j when si, sj = 1)
local function corner(i: number, j: number, si: number, sj: number): Vector3
	local p = CityLayout.intersectionPos(i, j)
	local off = C.RoadWidth / 2 + C.SidewalkWidth / 2
	return p + Vector3.new(si * off, C.CurbHeight, sj * off)
end
ActivityData.corner = corner

-- delivery jobs: where you pick them up, and where they send you
ActivityData.dispatch = {
	{ name = "Dockside Dispatch", pos = corner(1, 0, 1, 1) },
	{ name = "Uptown Dispatch", pos = corner(5, 6, -1, -1) },
}
ActivityData.dropPoints = {} :: { { name: string, pos: Vector3 } }
do
	local names = { "Marina Lofts", "Neon Arcade", "Skyline Plaza", "Old Market", "Crown Hotel", "Harbour Gate", "Ironworks", "Midtown Mall", "Station Square", "Riverside", "Glass Quarter", "Night Market" }
	local spots = { { 0, 3 }, { 2, 6 }, { 6, 2 }, { 3, 0 }, { 4, 4 }, { 6, 6 }, { 0, 6 }, { 2, 2 }, { 5, 1 }, { 1, 4 }, { 6, 0 }, { 3, 5 } }
	for k, s in spots do
		local si = if s[1] >= N then -1 else 1
		local sj = if s[2] >= N then -1 else 1
		table.insert(ActivityData.dropPoints, { name = names[k], pos = corner(s[1], s[2], si, sj) })
	end
end

-- Legends chips: a fixed scatter over the sidewalks (same for everyone)
ActivityData.chips = {} :: { Vector3 }
do
	local seed = 7
	local function rnd(n: number): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n
	end
	local used: { [string]: boolean } = {}
	while #ActivityData.chips < A.ChipCount do
		local i, j = rnd(N) , rnd(N)
		local si = if rnd(2) == 0 then 1 else -1
		local sj = if rnd(2) == 0 then 1 else -1
		-- along the block edge, not right at the corner
		local key = `{i},{j},{si},{sj}`
		if not used[key] then
			used[key] = true
			local base = corner(i + (if si < 0 then 1 else 0), j + (if sj < 0 then 1 else 0), si, sj)
			local along = 40 + rnd(160)
			local p = if rnd(2) == 0 then base + Vector3.new(si * along, 0, 0) else base + Vector3.new(0, 0, sj * along)
			table.insert(ActivityData.chips, p + Vector3.new(0, 2.6, 0))
		end
	end
end

return ActivityData
