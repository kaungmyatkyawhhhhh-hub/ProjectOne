-- MEGA BITE quality-nerd measurement on the LIVE map, WORLD v2 radii (13 Nov). Run in Studio (Edit). Same kid as nerd_live.lua:
-- swims 32 studs per 2 s view, 14 studs above the floor, notices ~1/3 of the map meshes in a ~125 deg cone;
-- tell "same prop" = one mesh is 9+ of the last 40 noticed; wow = a 40+ stud piece comes into view after 8 s without one.
-- swapFrac / addLandmarks = the forecast: that share of the open-sea flora becomes one of the 8 new kit props, and the three
-- landmarks that wait for upload stand at their planned places.
local function build(swapFrac, addLandmarks)
	local keys, nk, P = {}, 0, {}
	local rs = Random.new(99)
	for _, d in ipairs(workspace.MB_Map:GetDescendants()) do
		if d:IsA("MeshPart") and d.Transparency < 0.9 and d.Parent.Name ~= "FX" then
			if not keys[d.MeshId] then nk += 1; keys[d.MeshId] = nk end
			local s = d.Size; local k = keys[d.MeshId]
			local r = Vector3.new(d.Position.X, 0, d.Position.Z).Magnitude
			local nm = d.Name
			if swapFrac > 0 and r > 300 and r < 1200 and (nm == "Kelp" or nm == "SeaFan" or nm == "BubbleCoral" or nm == "BrainCoral" or nm == "Starfish" or nm == "TableCoral" or nm == "BranchCoral") and rs:NextNumber() < swapFrac then
				k = 1000 + rs:NextInteger(1, 8)
			end
			P[#P + 1] = {k = k, p = d.Position, s = math.max(s.X, s.Y, s.Z)}
		end
	end
	if addLandmarks then
		for i, q in ipairs({Vector3.new(-90, -30, 700), Vector3.new(-560, -10, -60), Vector3.new(-880, -60, 520)}) do
			for j = 1, 5 do P[#P + 1] = {k = 2000 + i * 10 + j, p = q + Vector3.new(j * 8 - 20, 0, 0), s = 120} end
		end
	end
	return P
end
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.Terrain, workspace.MB_Map}
local function floorAt(x, z) local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -1200, 0), params); return r and r.Position.Y or -30 end
local function run(P, rmin, rmax, steps, seed)
	local rng = Random.new(seed)
	local ang = rng:NextNumber(0, 6.28); local pos = Vector3.new(math.cos(ang), 0, math.sin(ang)) * (rmin + rmax) / 2; local yaw = ang + 1.57
	local recent, same, emptyRun, empty, wows, sinceBig, sum = {}, 0, 0, 0, 0, 999, 0
	for i = 1, steps do
		yaw += rng:NextNumber(-0.5, 0.5)
		local dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw)); local np = pos + dir * 32
		local fr = Vector3.new(np.X, 0, np.Z).Magnitude
		if fr < rmin or fr > rmax then yaw += 1.9; dir = Vector3.new(math.cos(yaw), 0, math.sin(yaw)); np = pos + dir * 32 end
		pos = np; local cam = Vector3.new(pos.X, floorAt(pos.X, pos.Z) + 14, pos.Z)
		local n, big = 0, false
		for _, o in ipairs(P) do
			local v = o.p - cam; local d = v.Magnitude
			if d < 70 + o.s * 2.5 then
				local fl = Vector3.new(v.X, 0, v.Z)
				if fl.Magnitude < 1 or fl.Unit:Dot(dir) > 0.45 then
					n += 1; if o.s >= 40 and d < 200 then big = true end
					if rng:NextNumber() < 0.35 then table.insert(recent, o.k) end
				end
			end
		end
		while #recent > 40 do table.remove(recent, 1) end
		local cnt, most = {}, 0; for _, k in ipairs(recent) do cnt[k] = (cnt[k] or 0) + 1; most = math.max(most, cnt[k]) end
		if most >= 9 and rng:NextNumber() < 0.25 then same += 1 end
		if n <= 2 then emptyRun += 2 else emptyRun = 0 end
		if emptyRun >= 6 then empty += 1; emptyRun = 0 end
		if big then if sinceBig >= 4 then wows += 1 end; sinceBig = 0 else sinceBig += 1 end
		sum += n
		if i % 40 == 0 then task.wait() end
	end
	return sum / steps, same, empty, wows
end
local out = {}
for _, v in ipairs({{0, false, "live"}}) do
	local P = build(v[1], v[2])
	for _, z in ipairs({{"Reef (2 min)", 20, 290, 60}, {"r300-720 (3 min)", 320, 720, 90}, {"r720-1150 (3 min)", 720, 1150, 90}, {"Trench r1250-1690 (2 min)", 1250, 1690, 60}}) do
		local a, b, c, d = 0, 0, 0, 0
		for seed = 1, 5 do local p, s, e, w = run(P, z[2], z[3], z[4], seed * 7); a += p; b += s; c += e; d += w end
		out[#out + 1] = string.format("%s | %s: props/view %.1f, same-prop %.1f, empty %.1f, wows %.1f", v[3], z[1], a / 5, b / 5, c / 5, d / 5)
	end
end
return table.concat(out, "\n")
