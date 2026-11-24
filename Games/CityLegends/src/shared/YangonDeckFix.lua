-- (2026-11-22) the Hledan flyover's continuous deck (tools/yangon/HledanDeck.luau lays a new deck over the baked road's
-- dip): the traffic lanes on that stretch are lifted from the old surface to the new one. Stations along the deck:
-- x, z, old top, new top (from HledanDeck.build's output). RivieraTraffic.build calls apply on the 1:1 lanes.
local D = {}
D.S = {
	{ 27146.6, 28239.5, 73.00, 73.00 },
	{ 27150.6, 28255.0, 72.92, 73.02 },
	{ 27154.7, 28270.4, 72.72, 73.02 },
	{ 27158.8, 28285.8, 72.33, 73.02 },
	{ 27162.9, 28301.3, 71.72, 73.02 },
	{ 27167.0, 28316.7, 70.89, 73.02 },
	{ 27171.0, 28332.1, 69.91, 73.02 },
	{ 27175.1, 28347.5, 68.84, 73.02 },
	{ 27179.2, 28363.0, 67.72, 73.02 },
	{ 27183.3, 28378.4, 66.61, 73.02 },
	{ 27187.3, 28393.8, 65.49, 73.02 },
	{ 27191.4, 28409.3, 64.37, 73.02 },
	{ 27195.5, 28424.7, 63.26, 73.02 },
	{ 27199.6, 28440.1, 62.14, 73.02 },
	{ 27203.6, 28455.5, 61.02, 73.02 },
	{ 27207.7, 28471.0, 59.91, 73.02 },
	{ 27211.8, 28486.4, 58.82, 73.02 },
	{ 27215.9, 28501.8, 57.81, 73.02 },
	{ 27220.0, 28517.3, 56.94, 73.02 },
	{ 27224.0, 28532.7, 56.25, 73.02 },
	{ 27228.1, 28548.1, 55.70, 73.02 },
	{ 27266.9, 28694.7, 54.81, 73.02 },
	{ 27270.9, 28710.1, 55.32, 73.02 },
	{ 27275.0, 28725.6, 55.95, 73.02 },
	{ 27279.1, 28741.0, 56.67, 73.02 },
	{ 27283.2, 28756.4, 57.34, 73.02 },
	{ 27287.2, 28771.9, 57.83, 73.02 },
	{ 27291.3, 28787.3, 58.12, 73.02 },
	{ 27295.4, 28802.7, 58.24, 73.02 },
	{ 27299.5, 28818.2, 58.27, 73.02 },
	{ 27303.6, 28833.6, 58.27, 73.02 },
	{ 27307.7, 28849.0, 58.27, 73.02 },
	{ 27311.8, 28864.4, 58.27, 73.02 },
	{ 27315.8, 28879.8, 58.27, 73.02 },
	{ 27319.9, 28895.3, 58.27, 73.02 },
	{ 27324.0, 28910.7, 58.27, 73.02 },
	{ 27328.1, 28926.1, 58.27, 73.02 },
	{ 27332.3, 28941.5, 58.27, 72.32 },
	{ 27336.4, 28956.9, 58.27, 71.23 },
	{ 27340.6, 28972.3, 58.27, 70.15 },
	{ 27344.7, 28987.8, 58.27, 69.06 },
	{ 27348.9, 29003.2, 58.27, 67.98 },
	{ 27353.0, 29018.6, 58.27, 66.89 },
	{ 27357.2, 29034.0, 58.27, 65.81 },
	{ 27361.3, 29049.4, 58.27, 64.72 },
	{ 27365.5, 29064.8, 58.27, 63.64 },
	{ 27369.7, 29080.2, 58.27, 62.55 },
	{ 27373.8, 29095.6, 58.27, 61.47 },
	{ 27378.0, 29111.0, 58.27, 60.38 },
	{ 27382.1, 29126.4, 58.27, 59.30 },
	{ 27386.3, 29141.8, 58.21, 58.21 },
	{ 27390.5, 29157.3, 58.05, 58.05 },
}
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

function D.apply(lanes)
	local S = D.S
	local z0, z1 = S[1][2], S[#S][2]
	local n = 0
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
					if top > e + 0.05 and math.abs(p[k] - cx) < 21 and math.abs(p[k + 1] - e) < 3.5 then
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
