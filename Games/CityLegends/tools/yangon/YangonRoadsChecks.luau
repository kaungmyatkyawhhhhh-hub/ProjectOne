--[[
	YangonRoads checks (split out of YangonRoads.luau 18 Nov 2026, J35: Studio's 200,000-character Source limit).
	Lives next to YangonRoads in ServerStorage.ClaudeTools; YangonRoads requires it at load and it adds M.checkBumps,
	M.checkPoints, M.checkJunctions, M.checkMainMain, M.partCount, M.surfaceCheck, M.stepCell ... to the same M.
	L = the YangonRoads file locals these use. Read-only on terrain (no Fill calls: the test runner's no-terrain swap is not needed here).
]]
return function(M, L)
local SS, C, own, hyp, rightOf, edgeXZ, polyDist, setOf = L.SS, L.C, L.own, L.hyp, L.rightOf, L.edgeXZ, L.polyDist, L.setOf
------------------------------------------------------------------------------------------------
-- checks
------------------------------------------------------------------------------------------------

function M.checkBumps()
	local lanes = {}
	for _, o in M.list do
		lanes[o.name] = if o.half >= 32 then { -24, -8, 8, 24 } else { -8, 8 }
	end
	-- (v5: a road with per-sample lanes is driven here, each lane at its own offset at each sample:
	-- lane k of n at mL + w(k - 0.5), w = min(lane width, (half - mL) / n), as d9_lanes.py lays the traffic lanes)
	local v5, rest = {}, {}
	for _, name in M.MAIN do
		local o = M.R[name]
		if o and o.lanesV5 then
			table.insert(v5, o)
		else
			table.insert(rest, name)
		end
	end
	local bumps, checked = M.Roads.check(M.data, { parent = M.folder(), only = setOf(rest), cut = M.cut, lanes = lanes })
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { M.folder(), workspace.Terrain }
	local limit = 0.12
	local function offset(p, side: number, k: number): number?
		local n = p[10]
		if k > n then
			return nil
		end
		local h = if side > 0 then p[8] else p[7]
		local w = math.min(p[11], (h - p[12]) / n)
		return side * (p[12] + w * (k - 0.5))
	end
	for oi, o in v5 do
		local cut = M.cut[o.name]
		for _, side in { -1, 1 } do
			for k = 1, (o.lanes or 2) do
				local last: Vector3? = nil
				for i = 1, o.n - 1 do
					local a, b = o.s[i], o.s[i + 1]
					local oa, ob = offset(a, side, k), offset(b, side, k)
					if cut[i] or cut[i + 1] or not oa or not ob then
						last = nil
						continue
					end
					local A, Bv = Vector3.new(a[1], a[2], a[3]), Vector3.new(b[1], b[2], b[3])
					local rax, raz = rightOf(a)
					local rbx, rbz = rightOf(b)
					local steps = math.max(1, math.floor(hyp(b[1] - a[1], b[3] - a[3])))
					for q = (if cut[i - 1] then 1 else 0), steps - 1 do
						local u = q / steps
						local off = oa + (ob - oa) * u
						local rx, rz = rax + (rbx - rax) * u, raz + (rbz - raz) * u
						local p = A:Lerp(Bv, u) + Vector3.new(rx, 0, rz) * off
						local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), params)
						checked += 1
						if hit then
							local here = hit.Position
							if last then
								local dd = Vector2.new(here.X - last.X, here.Z - last.Z).Magnitude
								if dd < 2.5 and math.abs(here.Y - last.Y) > 0.17 * dd + limit then
									table.insert(bumps, { road = o.name, lane = side * k, at = p, step = here.Y - last.Y })
								end
							end
							last = here
						else
							last = nil
						end
					end
					if i % 50 == 0 then
						task.wait()
					end
				end
			end
		end
		if oi % 2 == 0 then
			task.wait()
		end
	end
	local lines = { string.format("Roads.check: %d bumps in %d points", #bumps, checked) }
	for i = 1, math.min(#bumps, 25) do
		local b = bumps[i]
		table.insert(lines, string.format("  %s lane %d at %.0f, %.1f, %.0f step %.2f", b.road, b.lane, b.at.X, b.at.Y, b.at.Z, b.step))
	end
	return table.concat(lines, "\n"), bumps
end

-- n random points on the built main roads: the first thing under each must be the road (no grass
-- through it), and just past the pavement the ground must stand against the pavement's side (no road
-- hanging in the air)
function M.checkPoints(n: number, seed: number?)
	local rng = Random.new(seed or 20261113)
	local roads = M.folder()
	local onRoad = RaycastParams.new()
	onRoad.FilterType = Enum.RaycastFilterType.Include
	onRoad.FilterDescendantsInstances = { roads, workspace.Terrain }
	local ground = RaycastParams.new()
	ground.FilterType = Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances = { workspace.Terrain }
	ground.IgnoreWater = false
	local pool = {}
	for _, name in M.MAIN do
		local o = M.R[name]
		for i = 1, o.n - 1 do
			if not M.cut[name][i] and not M.cut[name][i + 1] and not M.noSlab[name][i] then
				table.insert(pool, { o, i })
			end
		end
	end
	local grass, miss, off, float, water = 0, 0, 0, 0, 0
	local worstOff, worstGap, sumGap, gaps = 0, -math.huge, 0, 0
	local bad = {}
	for _ = 1, n do
		local pick = pool[rng:NextInteger(1, #pool)]
		local o, i = pick[1], pick[2]
		local a, b = o.s[i], o.s[i + 1]
		local t = rng:NextNumber()
		local rx, rz = rightOf(a)
		local oh = math.min(M.halfAt(o, i), M.halfAt(o, i + 1))
		local lat = rng:NextNumber(-(oh - 1), oh - 1)
		local x, z = a[1] + (b[1] - a[1]) * t + rx * lat, a[3] + (b[3] - a[3]) * t + rz * lat
		local want = a[2] + (b[2] - a[2]) * t
		local hit = workspace:Raycast(Vector3.new(x, want + 40, z), Vector3.new(0, -80, 0), onRoad)
		if not hit then
			miss += 1
			table.insert(bad, string.format("nothing under %.0f, %.0f (%s)", x, z, o.name))
		elseif hit.Instance == workspace.Terrain then
			grass += 1
			table.insert(bad, string.format("ground on top at %.0f, %.0f (%s) %.2f over the road", x, z, o.name, hit.Position.Y - want))
		else
			local d = math.abs(hit.Position.Y - want)
			-- (v5: a divided road's raised median is part of the road)
			local median = hit.Instance.Name == "Median" or hit.Instance.Name == "MedianKerb"
			if not median then
				worstOff = math.max(worstOff, d)
			end
			if not median and (hit.Instance.Name ~= "Road" or d > 0.6) then
				off += 1
				table.insert(bad, string.format("%s %.2f off at %.0f, %.0f (%s)", hit.Instance.Name, hit.Position.Y - want, x, z, o.name))
			end
		end
		-- the ground 1.5 studs past the pavement, on a random side
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local gx = a[1] + (b[1] - a[1]) * t + rx * side * (oh + M.WALK + 1.5)
		local gz = a[3] + (b[3] - a[3]) * t + rz * side * (oh + M.WALK + 1.5)
		local g = workspace:Raycast(Vector3.new(gx, want + 40, gz), Vector3.new(0, -120, 0), ground)
		if g then
			local gap = (want + M.CURB_UP) - g.Position.Y -- the pavement's top over the ground beside it
			if g.Material == Enum.Material.Water then
				water += 1
			end
			sumGap += gap
			gaps += 1
			worstGap = math.max(worstGap, gap)
			if gap > 5.5 then -- (the pavement is 6 deep: more than this and you see under it)
				float += 1
				table.insert(bad, string.format("pavement %.1f over the ground at %.0f, %.0f (%s)", gap, gx, gz, o.name))
			end
		else
			float += 1
			table.insert(bad, string.format("no ground beside the road at %.0f, %.0f (%s)", gx, gz, o.name))
		end
	end
	local head = string.format("%d points: ground through the road %d, nothing under %d, wrong part or height %d (worst %.3f off the sample height), floating %d, pavement top over the ground beside it: mean %.2f, most %.2f; water beside %d", n, grass, miss, off, worstOff, float, sumGap / math.max(gaps, 1), worstGap, water)
	for i = 1, math.min(#bad, 20) do
		head ..= "\n  " .. bad[i]
	end
	return head
end

-- every Pavement / Kerb under a spot (looks through the road slabs)
local function sidesUnder(x: number, y: number, z: number, folder: Instance): string?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local from = Vector3.new(x, y + 12, z)
	for _ = 1, 6 do
		local hit = workspace:Raycast(from, Vector3.new(0, -24, 0), params)
		if not hit then
			return nil
		end
		if hit.Instance.Name == "Pavement" or hit.Instance.Name == "Kerb" then
			return hit.Instance.Name
		end
		from = hit.Position - Vector3.new(0, 0.01, 0)
	end
	return nil
end

local function roadTop(x: number, y: number, z: number, folder: Instance): number?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local from = Vector3.new(x, y + 12, z)
	for _ = 1, 6 do
		local hit = workspace:Raycast(from, Vector3.new(0, -24, 0), params)
		if not hit then
			return nil
		end
		if hit.Instance.Name == "Road" then
			return hit.Position.Y
		end
		from = hit.Position - Vector3.new(0, 0.01, 0)
	end
	return nil
end

-- the 28 main-road junctions of the design: at each one outside the corridors, every mouth must be
-- open (no pavement, kerb or line of the main road inside the joining road's carriageway), the main
-- road's kerb and pavement must be there again right beside it, and the heights must match:
--   a joining road that is built: its own surface just outside the main road's edge against the main
--     road's surface just inside it;
--   a street that is not built yet: the height Roads.build will give it there (its samples after
--     alignJunctions) against the main road's surface. The street's raw data height is listed too.
function M.checkJunctions()
	local roads = M.folder()
	local lines = {}
	local total = { junctions = 0, corridor = 0, mouths = 0, crossing = 0, missing = 0, height = 0, lines = 0 }
	local worstH, worstRaw = 0, 0
	local aligned = {}
	for _, r in M.Roads.prepared(M.data, M.cut) do
		aligned[r.name] = r.pts
	end
	-- the main roads' Line parts, in a 48-stud grid
	local lineGrid = {}
	for _, name in M.MAIN do
		local f = roads:FindFirstChild(name)
		if f then
			for _, p in f:GetChildren() do
				if p.Name == "Line" then
					local key = math.floor(p.Position.X / 48) .. "," .. math.floor(p.Position.Z / 48)
					lineGrid[key] = lineGrid[key] or {}
					table.insert(lineGrid[key], p)
				end
			end
		end
	end
	for _, j in M.design.junctions do
		if not j.on_main then
			continue
		end
		total.junctions += 1
		local wx, wz = 30000 + j.pos_m[1] * M.SPM, -j.pos_m[2] * M.SPM
		local label = table.concat(j.roads, " + ")
		-- in a corridor: its main road's nearest sample is cut
		local corridor = false
		for _, name in j.roads do
			local o = M.R[name]
			if o and o.kind == "route" then
				local bi, bd = 1, math.huge
				for i = 1, o.n do
					local d = hyp(o.s[i][1] - wx, o.s[i][3] - wz)
					if d < bd then
						bi, bd = i, d
					end
				end
				if bd < 40 and M.cut[name][bi] then
					corridor = true
				end
			end
		end
		if corridor then
			total.corridor += 1
			table.insert(lines, "corridor (step 4): " .. label)
			continue
		end
		local notes, info = {}, {}
		for _, mainName in j.roads do
			local main = M.R[mainName]
			if not main or main.kind ~= "route" then
				continue
			end
			local mf = roads:FindFirstChild(mainName)
			for _, sName in j.roads do
				local S = M.R[sName]
				-- (step 5 split Inya Road and merged Lane 1 into U Tun Nyein Street: those names are gone)
				if not S or S.rank <= main.rank then
					continue
				end
				local sf = roads:FindFirstChild(sName)
				-- where S crosses main's edge line: one mouth each time
				for i = 1, S.n - 1 do
					local a, b = S.s[i], S.s[i + 1]
					if hyp(a[1] - wx, a[3] - wz) > 140 or M.cut[sName][i] or M.cut[sName][i + 1] then
						continue
					end
					local na, nb = M.near(a[1], a[3], 3)[main.index], M.near(b[1], b[3], 3)[main.index]
					if not na or not nb then
						continue
					end
					local da, db = polyDist(main, na[2], a[1], a[3]), polyDist(main, nb[2], b[1], b[3])
					if (da < main.half) == (db < main.half) then
						continue
					end
					-- Q: on main's edge; v: along S, away from main
					local t = (main.half - da) / (db - da)
					local qx, qz = a[1] + (b[1] - a[1]) * t, a[3] + (b[3] - a[3]) * t
					local qy = a[2] + (b[2] - a[2]) * t
					local vx, vz = b[1] - a[1], b[3] - a[3]
					if db < da then
						vx, vz = -vx, -vz
					end
					local L = hyp(vx, vz)
					vx, vz = vx / L, vz / L
					total.mouths += 1
					local h = S.half
					-- (a) the main road's kerb and pavement band on this side, 0.8 studs apart, as far along
					-- the main road as the mouth can reach (a slanted mouth is longer: h / sin of the angle).
					-- Inside S's carriageway: nothing of main's kerb or pavement. 1.2 to 1.8 past S's edge:
					-- they must be there again.
					local crossing, missing = 0, 0
					local iq = if da < db then nb[2] else na[2]
					local ms = main.s[iq]
					local mrx, mrz = rightOf(ms)
					local side = if (qx - ms[1]) * mrx + (qz - ms[3]) * mrz > 0 then 1 else -1
					local sinA = math.abs(vx * ms[5] - vz * ms[4]) / hyp(ms[4], ms[5])
					local reach = math.min(h / math.max(sinA, 0.2) + 14, 180)
					local span = math.ceil(reach / 6.4)
					for idx = math.max(1, iq - span), math.min(main.n - 1, iq + span) do
						if M.cut[mainName][idx] or M.cut[mainName][idx + 1] then
							continue
						end
						local p0, p1 = main.s[idx], main.s[idx + 1]
						local r0x, r0z = rightOf(p0)
						local r1x, r1z = rightOf(p1)
						for sub = 0, 7 do
							local u = (sub + 0.5) / 8 -- (never on a sample's own cross-section: pieces meet there, and a ray on a seam proves nothing)
							local axx, azz = p0[1] + (p1[1] - p0[1]) * u, p0[3] + (p1[3] - p0[3]) * u
							local rx, rz = r0x + (r1x - r0x) * u, r0z + (r1z - r0z) * u
							local lat = main.half + 0.3
							while lat < main.half + M.WALK - 0.3 do
								local x, z = axx + rx * side * lat, azz + rz * side * lat
								local near = M.near(x, z, 2)
								local ns = near[S.index]
								if ns then
									local ds = polyDist(S, ns[2], x, z)
									if ds < h - 0.4 then
										if mf and sidesUnder(x, qy, z, mf) then
											crossing += 1
										end
									elseif ds > h + 1.2 and ds < h + 1.8 then
										-- (any road's kerb or pavement: past a round corner the joining road's own)
										if not sidesUnder(x, qy, z, roads) then
											-- (another road's mouth, or the roundabout, right beside this one is no fault)
											local other = hyp(x - C.X, z - C.Z) < M.RING_V + M.WALK + 0.5 or M.inCorner(x, z)
											for oi, bb in near do
												local o2 = M.list[oi]
												if o2 ~= main and o2 ~= S and polyDist(o2, bb[2], x, z) < o2.half + (if o2.rank < main.rank then M.WALK else 0.3) then
													other = true
												end
											end
											if not other then
												missing += 1
											end
										end
									end
								end
								lat += 0.8
							end
						end
					end
					task.wait()
					-- (c) heights
					local top = mf and roadTop(qx - vx * 0.5, qy, qz - vz * 0.5, mf)
					local dh, how = math.huge, ""
					local sTop = sf and roadTop(qx + vx * 0.5, qy, qz + vz * 0.5, sf)
					if top and sTop then
						dh, how = math.abs(top - sTop), "built"
					elseif top then
						local pa, pb = aligned[sName][i].pos, aligned[sName][i + 1].pos
						dh, how = math.abs(top - (pa.Y + (pb.Y - pa.Y) * t)), "builder"
					end
					local raw = if top then math.abs(top - qy) else math.huge
					if dh ~= math.huge then
						worstH = math.max(worstH, dh)
					end
					if raw ~= math.huge then
						worstRaw = math.max(worstRaw, raw)
					end
					-- (d) no line of main inside S's carriageway
					local inMouth = 0
					local cx, cz = math.floor(qx / 48), math.floor(qz / 48)
					for dx = -2, 2 do
						for dz = -2, 2 do
							for _, p in lineGrid[(cx + dx) .. "," .. (cz + dz)] or {} do
								if p.Parent == mf then
									for u = -2, 2 do
										local q = p.Position + p.CFrame.LookVector * (p.Size.Z / 2 * u / 2)
										local near = M.near(q.X, q.Z, 2)
										local ns, nmq = near[S.index], near[main.index]
										if ns and nmq then
											-- (RoadLines' rule: the middle line is never broken by a smaller road, and
											-- a line off the middle is only in the way of the part of S on its own
											-- side of main's centre line, 4 studs or more out: at a T the far side's
											-- lines run on)
											local dq, fx, fz = polyDist(main, nmq[2], q.X, q.Z)
											local dS = math.huge
											if dq > 1 and fx and fz then
												local nx, nz = (q.X - fx) / dq, (q.Z - fz) / dq
												dS = polyDist(S, ns[2], q.X, q.Z, fx + nx * 4, fz + nz * 4, nx, nz)
											end
											if dS < h - 0.3 then
												inMouth += 1
												break
											end
										end
									end
								end
							end
						end
					end
					total.crossing += crossing
					total.missing += missing
					total.lines += inMouth
					if dh > 0.05 then
						total.height += 1
					end
					table.insert(info, string.format("%s %.3f (%s, raw %.2f)", sName, dh, how, raw))
					if crossing > 0 or missing > 0 or inMouth > 0 or dh > 0.05 then
						table.insert(notes, string.format("%s into %s at %.0f, %.0f: in the mouth %d, missing beside it %d, lines %d, height off %.3f (%s)", sName, mainName, qx, qz, crossing, missing, inMouth, dh, how))
					end
				end
			end
		end
		if #info == 0 then
			table.insert(notes, "no mouth found")
			total.missing += 1
		end
		table.insert(lines, (if #notes == 0 then "ok: " else "FAULT: ") .. label .. " | heights: " .. table.concat(info, "; ") .. (if #notes > 0 then "\n    " .. table.concat(notes, "\n    ") else ""))
	end
	local head = string.format("junctions on main roads %d: %d in a corridor, %d checked with %d mouths. Kerb or pavement in a mouth: %d spots. Missing right beside a mouth: %d spots. Lines in a mouth: %d. Heights more than 0.05 off: %d (worst %.3f; the streets' raw data is up to %.2f off before the builder eases them).", total.junctions, total.corridor, total.junctions - total.corridor, total.mouths, total.crossing, total.missing, total.lines, total.height, worstH, worstRaw)
	return head .. "\n" .. table.concat(lines, "\n")
end

-- every road slab under a spot, top first: { { road folder's name, height, the part } }. Looks through
-- kerbs and pavements, and sees two slabs lying in one plane (each hit is taken out and the ray cast again).
local function roadTops(x: number, y: number, z: number, roads: Instance)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	-- (step 4: a deck over the junction is not the junction's surface)
	local decks = (roads.Parent :: Instance):FindFirstChild("Decks")
	local skip = if decks then { decks } else {}
	local tops = {}
	for _ = 1, 10 do
		params.FilterDescendantsInstances = skip
		local hit = workspace:Raycast(Vector3.new(x, y + 30, z), Vector3.new(0, -60, 0), params)
		if not hit or not hit.Instance:IsDescendantOf(roads) then
			break
		end
		if hit.Instance.Name == "Road" then
			table.insert(tops, { hit.Instance.Parent.Name, hit.Position.Y, hit.Instance })
		end
		table.insert(skip, hit.Instance)
	end
	return tops
end

-- main road on main road: over each mouth, every spot on either road has one slab (never two roads'
-- slabs on one spot, never none), and the two roads' heights match
function M.checkMainMain()
	local roads = M.folder()
	local out = {}
	for _, m in M.mouths do
		local o = M.R[m.road]
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for i = math.min(m.i0, m.k), math.max(m.i0, m.k) do
			for _, side in { -1, 1 } do
				local ex, ez = edgeXZ(o, i, side)
				x0, x1 = math.min(x0, ex), math.max(x1, ex)
				z0, z1 = math.min(z0, ez), math.max(z1, ez)
			end
		end
		x0, x1, z0, z1 = x0 - 30, x1 + 30, z0 - 30, z1 + 30
		local spots, double, holes, worst = 0, 0, 0, 0
		local firstBad = nil
		local x = x0 + 0.37 -- (off the 6.4-stud sample grid: a ray on a seam between two wedges proves nothing)
		while x <= x1 do
			local z = z0 + 0.37
			while z <= z1 do
				-- on either road's carriageway (or the ring)?
				local on = false
				local near = M.near(x, z, 3)
				local nMe = near[o.index]
				-- (and not past the road's own end: polyDist would round its end off)
				local e = o.s[m.i0]
				local past = ((x - e[1]) * e[4] + (z - e[3]) * e[5]) * m.step < 0
				if nMe and not past and polyDist(o, nMe[2], x, z) < o.half - 0.4 then
					on = true
				end
				if m.big then
					local nb = near[m.big.index]
					if nb and polyDist(m.big, nb[2], x, z) < m.big.half - 0.4 then
						on = true
					end
				else
					local rr = hyp(x - C.X, z - C.Z)
					if rr < M.R_OUT - 0.4 and rr > M.R_IN + 0.4 then
						on = true
					elseif rr <= M.R_IN + 0.4 then
						on = false
					end
				end
				if on then
					spots += 1
					local tops = roadTops(x, o.s[m.k][2], z, roads)
					if #tops == 0 then
						holes += 1
						firstBad = firstBad or string.format("hole at %.0f, %.0f", x, z)
					else
						for q = 2, #tops do
							if tops[q][1] ~= tops[1][1] and math.abs(tops[q][2] - tops[1][2]) < 0.3 then
								double += 1
								worst = math.max(worst, math.abs(tops[q][2] - tops[1][2]))
								firstBad = firstBad or string.format("two slabs at %.0f, %.0f (%s and %s, %.3f apart)", x, z, tops[1][1], tops[q][1], math.abs(tops[q][2] - tops[1][2]))
								break
							end
						end
					end
				end
				z += 2
			end
			x += 2
		end
		-- heights where the two meet: the road's end sample against the bigger road's surface
		local s0 = o.s[m.i0]
		local hNote = ""
		if m.big then
			local f = roads:FindFirstChild(m.big.name)
			local top = f and roadTop(s0[1], s0[2], s0[3], f)
			hNote = string.format(", heights at the join: %s %.2f in the data, %s surface %s", m.road, s0[2], m.big.name, if top then string.format("%.2f", top) else "none")
		end
		table.insert(out, string.format("%s on %s: %d spots (2-stud grid), two roads' slabs on one spot %d, holes %d%s%s", m.road, m.on, spots, double, holes, hNote, if firstBad then " | first: " .. firstBad else ""))
	end
	return table.concat(out, "\n")
end

-- (J30) M.qaBuilt is gone: the built-surface check is T.qa in city/Roads05StudioTest.luau

function M.partCount()
	local roads = M.folder()
	local byName, perRoad, total = {}, {}, 0
	for _, f in roads:GetChildren() do
		local n = 0
		for _, p in f:GetDescendants() do
			if p:IsA("BasePart") then
				byName[p.Name] = (byName[p.Name] or 0) + 1
				n += 1
			end
		end
		perRoad[f.Name] = n
		total += n
	end
	local a, b = {}, {}
	for k, v in byName do
		table.insert(a, k .. " " .. v)
	end
	for k, v in perRoad do
		table.insert(b, k .. " " .. v)
	end
	table.sort(a)
	table.sort(b)
	local riv = workspace:FindFirstChild("Riviera")
	return string.format("Yangon.Roads: %d parts. By name: %s. By road: %s. Riviera descendants: %d", total, table.concat(a, ", "), table.concat(b, ", "), if riv then #riv:GetDescendants() else -1)
end

-- Doubled faces within `reach` studs of each spot.
--   blocks (pavement, kerb, line): SurfaceCheck's "fight" (two faces looking the same way, under 0.05
--     apart, lying over each other). Its "step" (under 0.3 apart) is listed apart: a kerb standing 0.1
--     over its own pavement is one by design, so kerb-on-pavement pairs are not counted.
--   road slabs (wedges, which SurfaceCheck does not read): a 2-stud grid of rays; two slab tops under
--     0.05 apart on one spot is a doubled face.
function M.surfaceCheck(spots: { { any } }, reach: number?)
	local SC = require(SS.ClaudeTools.SurfaceCheck:Clone())
	local roads = M.folder()
	local R = reach or 120
	local out = {}
	local fights, steps, slabs = 0, 0, 0
	for _, s in spots do
		local at = s[2] :: Vector3
		local found = SC.run(roads, {
			rows = 0,
			skip = function(p: BasePart)
				return hyp(p.Position.X - at.X, p.Position.Z - at.Z) > R
			end,
		})
		local f, st, eg = 0, 0, nil
		for _, e in found do
			if e.kind == "fight" then
				f += 1
				eg = eg or string.format("%s on %s at %.0f, %.0f gap %.3f", e.a.Name, e.b.Name, e.at.X, e.at.Z, e.gap)
			elseif not ((e.a.Name == "Kerb" and e.b.Name == "Pavement") or (e.a.Name == "Pavement" and e.b.Name == "Kerb")) then
				st += 1
				eg = eg or string.format("step: %s on %s at %.0f, %.0f gap %.3f", e.a.Name, e.b.Name, e.at.X, e.at.Z, e.gap)
			end
		end
		local dbl, rays, seams = 0, 0, 0
		local egSlab = nil
		local x = at.X - R + 0.37
		while x <= at.X + R do
			local z = at.Z - R + 0.37
			while z <= at.Z + R do
				if hyp(x - at.X, z - at.Z) <= R then
					local tops = roadTops(x, at.Y, z, roads)
					if #tops > 0 then
						rays += 1
					end
					for q = 2, #tops do
						if math.abs(tops[q][2] - tops[1][2]) < 0.05 then
							-- (a ray on the seam between two triangles sees both: a real doubled face is still
							-- double a hand's width to each side)
							local wide = true
							for _, d in { { 0.13, 0.07 }, { -0.07, 0.13 }, { -0.11, -0.09 } } do
								local t2 = roadTops(x + d[1], at.Y, z + d[2], roads)
								if not (t2[2] and math.abs(t2[2][2] - t2[1][2]) < 0.05) then
									wide = false
								end
							end
							if not wide then
								seams += 1
								break
							end
							dbl += 1
							egSlab = egSlab or string.format("two slabs at %.2f, %.2f (%s %.3f size %s, %s %.3f size %s)", x, z, tops[1][1], tops[1][2], tostring(tops[1][3].Size), tops[q][1], tops[q][2], tostring(tops[q][3].Size))
							break
						end
					end
				end
				z += 2
			end
			x += 2
		end
		fights += f
		steps += st
		slabs += dbl
		table.insert(out, string.format("%s: blocks fighting %d, other thin steps %d, doubled slab spots %d of %d (rays on a seam: %d)%s", s[1], f, st, dbl, rays, seams, (if eg then " | " .. eg else "") .. (if egSlab then " | " .. egSlab else "")))
		task.wait()
	end
	return string.format("doubled faces at %d spots: blocks fighting %d, thin steps %d, doubled slab spots %d\n%s", #spots, fights, steps, slabs, table.concat(out, "\n"))
end

------------------------------------------------------------------------------------------------
-- 1:1 cells (roads05, 2026-11-16): everything one cell owns, into root.Roads / root.Decks; no lines (the paint
-- is baked from roads05_paint.py), no map-edge barriers (district edges join the next district)
------------------------------------------------------------------------------------------------
function M.stepCell(box: { number }, root: Instance)
	M.box = box
	M.ROOT = root
	M.useRing(nil) -- (J30) no ring state carried over from the last cell
	-- (J30, QA: a cell's build depended on the cell built before it, bahan_ring after long_median vs after ycentral,
	-- Lane #3789: 199 parts) the leak is in the Roads module copy (a fresh copy alone made both orders equal): one per cell
	M.Roads = require(SS.ClaudeTools.Roads:Clone())
	M.noLines = true
	M.VERGE_W = 6
	local names = {}
	local mx = 140
	for _, o in M.list do
		for i = 1, o.n, 2 do
			local s = o.s[i]
			if s[1] > box[1] - mx and s[1] < box[3] + mx and s[3] > box[2] - mx and s[3] < box[4] + mx then
				table.insert(names, o.name)
				break
			end
		end
	end
	local log = { #names .. " roads near" }
	if #names == 0 then
		return log[1]
	end
	local t0 = os.clock()
	M.t0 = t0
	M.step("cell: buildRoads, " .. #names .. " roads")
	table.insert(log, M.buildRoads(names))
	table.insert(log, string.format("(%.0f s)", os.clock() - t0))
	M.step("cell: mendCutEnds")
	table.insert(log, M.mendCutEnds(names))
	M.step("cell: buildCorners")
	table.insert(log, "corners " .. tostring(M.buildCorners()))
	M.step("cell: islands")
	table.insert(log, M.buildIslands())
	table.insert(log, M.buildIslands("fills"))
	table.insert(log, M.endKerbs(names))
	M.step("cell: verge")
	table.insert(log, M.verge(names))
	M.step("cell: roundabouts")
	table.insert(log, M.buildRoundabout())
	M.step("cell: medians")
	table.insert(log, M.buildMedians(names))
	M.step("cell: decks")
	table.insert(log, M.buildDecks())
	M.step("cell: scrub")
	table.insert(log, M.scrub(true))
	M.step("cell: done")
	table.insert(log, string.format("(%.0f s in all)", os.clock() - t0))
	return table.concat(log, "\n")
end

end
