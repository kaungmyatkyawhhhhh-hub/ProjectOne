-- (2026-11-22) the Hledan flyover's continuous deck (tools/yangon/HledanDeck.luau lays a new deck over the baked road's
-- dip): the traffic lanes on that stretch are lifted from the old surface to the new one. Stations along the deck:
-- x, z, old top, new top (from HledanDeck.build's output). RivieraTraffic.build calls apply on the 1:1 lanes.
local D = {}
-- (2026-11-25) EMPTY: the Hledan deck is now one deck in the roads05 data (roads05_hledan_fix.py), rebuilt in cells
-- 17x17..17x19, and Roads.HledanDeckFix is deleted; the lanes come from the data at the right height. The 22 Nov
-- stations are in git history (commit before 25 Nov).
D.S = {}
-- (2026-11-24, racers hopping) a lane point the lane writer left at a deck's height over the ground road it runs on
-- (Arzani Street: four single points 12-25 studs up, the road built under them) is put back on the line between its
-- neighbours. Only a true spike: off BOTH neighbours by more than Spike studs the same way (a real step has one side flat).
D.Spike = 1.5
local function unspike(p): number
	local n, m = 0, #p // 3
	for i = 2, m - 1 do
		-- (in order, on the fixed heights: on Arzani a spike sits every second point, the ones between are right)
		local y0, y1, y2 = p[3 * i - 4], p[3 * i - 1], p[3 * i + 2]
		local a, b = y1 - y0, y1 - y2
		if a * b > 0 and math.min(math.abs(a), math.abs(b)) > D.Spike then
			local d1 = math.sqrt((p[3 * i - 2] - p[3 * i - 5]) ^ 2 + (p[3 * i] - p[3 * i - 3]) ^ 2)
			local d2 = math.sqrt((p[3 * i + 1] - p[3 * i - 2]) ^ 2 + (p[3 * i + 3] - p[3 * i]) ^ 2)
			p[3 * i - 1] = y0 + (y2 - y0) * d1 / math.max(d1 + d2, 0.01)
			n += 1
		end
	end
	return n
end
D.unspike = unspike

-- a piece no car can drive: the lane drops or climbs more than 6 studs at over 1 in 2 (a deck that ends in the air
-- over the road it was meant to come down to: Arzani Street at (32720, 36170), 129.6 -> 90.4 in 24 studs).
-- RivieraTraffic does not join such a piece to the one before it, so traffic never drives off the edge.
function D.cliff(a: Vector3, b: Vector3): boolean
	local dy = math.abs(b.Y - a.Y)
	return dy > 6 and dy > 0.5 * Vector2.new(b.X - a.X, b.Z - a.Z).Magnitude
end

-- (2026-11-24) only the deck road's own lanes are lifted, across its whole width: the old test (any lane within 21 of
-- the middle, within 3.5 of the old top) lifted 12 points of Pyay Road #12, the ground road under the deck, 16 studs up
-- onto it, and left Pyay Road #6's outer lane 3 at the old height where it ran 21-22 out (a step at each deck end)
D.ROAD = "Pyay Road #6"
D.HALF = 26
function D.apply(lanes)
	local S = D.S
	local n = 0
	if #S < 2 then
		for _, l in lanes do
			if l.yangon and not l.deckFix then
				l.deckFix = true
				unspike(l.pts)
			end
		end
		return 0
	end
	local z0, z1 = S[1][2], S[#S][2]
	for _, l in lanes do
		if l.yangon and not l.deckFix then
			l.deckFix = true
			local p = l.pts
			unspike(p)
			for k = 1, #p - 2, 3 do
				local z = p[k + 2]
				if z > z0 and z < z1 and p[k] > 27100 and p[k] < 27440 then
					local i = 1
					while i < #S - 1 and S[i + 1][2] < z do
						i += 1
					end
					local a, b = S[i], S[i + 1]
					local t = (z - a[2]) / (b[2] - a[2])
					local cx = a[1] + (b[1] - a[1]) * t
					local e = a[3] + (b[3] - a[3]) * t
					local top = a[4] + (b[4] - a[4]) * t
					if l.road == D.ROAD and top > e + 0.05 and math.abs(p[k] - cx) < D.HALF and math.abs(p[k + 1] - e) < 3.5 then
						p[k + 1] += top - e
						n += 1
					end
				end
			end
		end
	end
	return n
end
return D
