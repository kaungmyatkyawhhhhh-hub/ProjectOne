--[[
	ChallengeData
	Where the free-roam challenges are (owner, 2026-10-23: "make the game 1000000000x better and
	cooler"), shared by server (builds them, checks results) and client (detects passes, minimap):
	  * speed traps: a gantry across a fast road; driving through records your speed (bronze /
	    silver / gold by mph, a personal best per trap)
	  * jump ramps: kickers off the traffic lanes (the beach, the riverside park, Legends Key)
	  * the leaderboard board on a city-centre corner
	Drift scoring needs no places: it runs anywhere.
]]

local Config = require(script.Parent.Config)
local CityLayout = require(script.Parent.CityLayout)
local ActivityData = require(script.Parent.ActivityData)

local C = Config.City
local W = Config.West

local ChallengeData = {}

export type Trap = {
	id: string,
	name: string,
	pos: Vector3, -- the middle of the road at the gate (road height)
	dir: Vector3, -- along the road (either way through counts)
	half: number, -- half the width the gate spans
}

export type Ramp = {
	id: string,
	cf: CFrame, -- the ramp's foot in the middle, LookVector = the way you jump
	size: Vector3, -- width, height, length
}

local HW = C.HighwayWidth / 2
local HALF_ROAD = C.RoadWidth / 2
local DECK_HALF = (C.HighwayWidth + 12) / 2

local function loopPoint(fraction: number): (Vector3, Vector3)
	-- a point on the Legends Loop's south straight (fraction 0..1 along it)
	local side = 2 * (C.LoopHalf - C.LoopCorner)
	local arc = math.pi / 2 * C.LoopCorner
	return CityLayout.loopSample(side + arc + side * fraction)
end

ChallengeData.traps = {} :: { Trap }
do
	local function add(id: string, name: string, pos: Vector3, dir: Vector3, half: number)
		table.insert(ChallengeData.traps, { id = id, name = name, pos = pos, dir = dir.Unit, half = half })
	end
	add("harbour", "HARBOUR RUN", Vector3.new(CityLayout.HighwayStartX + 600, 0, 0), Vector3.xAxis, HW + 2)
	local lp, ld = loopPoint(0.5)
	add("loop", "LEGENDS LOOP", lp, ld, HW + 8)
	add("viaduct", "HARBOUR VIADUCT", Vector3.new(-2300, CityLayout.westRoadY(-2300), 0), Vector3.xAxis, DECK_HALF - 2)
	add("canyon", "CANYON PASS", Vector3.new(-4860, CityLayout.westRoadY(-4860), 0), Vector3.xAxis, HW + 2)
	local bx = (W.BridgeTowers[1] + W.BridgeTowers[2]) / 2
	add("bridge", "LEGENDS BRIDGE", Vector3.new(bx, CityLayout.westRoadY(bx), 0), Vector3.xAxis, DECK_HALF - 2)
	add("ocean", "OCEAN DRIVE", Vector3.new(CityLayout.roadCoord(W.IndexBase), 0, C.BlockSize * 1.5), Vector3.zAxis, HALF_ROAD + 2)
end

ChallengeData.trapById = {} :: { [string]: Trap }
for _, t in ChallengeData.traps do
	ChallengeData.trapById[t.id] = t
end

-- jump ramps: open ground, never on a lane (tools/world_test checks lanes stay clear)
ChallengeData.ramps = {} :: { Ramp }
do
	local size = Vector3.new(24, 9, 34)
	local function add(id: string, foot: Vector3, dir: Vector3)
		table.insert(ChallengeData.ramps, { id = id, cf = CFrame.lookAt(foot, foot + dir), size = size })
	end
	local sand = W.BeachWest + 110 -- the middle of the beach
	add("beach_north", Vector3.new(sand, 0.2, -760), Vector3.zAxis)
	add("beach_south", Vector3.new(sand, 0.2, 940), -Vector3.zAxis)
	add("riverside", Vector3.new((W.River[2] + CityLayout.roadCoord(W.IndexBase + C.Blocks) + HALF_ROAD) / 2, 0.4, -620), Vector3.zAxis)
	local key = W.Islands[1]
	add("legends_key", Vector3.new(key.x + 90, 0.05, key.z - 190), Vector3.zAxis)
end

-- the leaderboard board: on the sidewalk corner by the city's middle junction
ChallengeData.boardPos = ActivityData.corner(C.Blocks / 2, C.Blocks / 2, 1, -1)

-- everything the minimap shows
function ChallengeData.points(): { { kind: string, pos: Vector3 } }
	local out = {}
	for _, t in ChallengeData.traps do
		table.insert(out, { kind = "trap", pos = t.pos })
	end
	for _, r in ChallengeData.ramps do
		table.insert(out, { kind = "ramp", pos = r.cf.Position })
	end
	table.insert(out, { kind = "board", pos = ChallengeData.boardPos })
	return out
end

return ChallengeData
