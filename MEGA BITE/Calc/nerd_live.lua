-- MEGA BITE quality-nerd measurement on the LIVE map (13 Nov). Run in Studio (Edit, execute_luau / command bar).
-- A kid swims 32 studs per 2 s view, 14 studs above the floor, notices ~1/3 of the map meshes in a ~125 deg cone.
local keys, nk, P = {}, 0, {}
for _, d in ipairs(workspace.MB_Map:GetDescendants()) do
	if d:IsA("MeshPart") and d.Transparency < 0.9 and d.Parent.Name ~= "FX" then
		if not keys[d.MeshId] then nk += 1; keys[d.MeshId] = nk end
		local s = d.Size; P[#P + 1] = {k = keys[d.MeshId], p = d.Position, s = math.max(s.X, s.Y, s.Z)}
	end
end
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = {workspace.Terrain, workspace.MB_Map}
local function floorAt(x, z) local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -1200, 0), params); return r and r.Position.Y or -30 end
local rng = Random.new(7)
local function run(label, rmin, rmax, steps)
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
	end
	print(string.format("%s: props/view %.1f, same-prop %d, empty %d, wows %d", label, sum / steps, same, empty, wows))
end
run("Reef (2 min)", 20, 290, 60); run("Open Sea (5 min)", 320, 1050, 150); run("Outer ring (3 min)", 700, 1100, 90)
