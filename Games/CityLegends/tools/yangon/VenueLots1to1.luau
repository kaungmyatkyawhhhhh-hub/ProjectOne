--[[
	VenueLots1to1 (Studio, Edit; 2026-11-17, the switch to the 1:1 map): checks candidate lots and gets the venue lots,
	the Racing Hub and the house lots ready on Workspace.Yangon1to1 with YangonSites (S.root = Yangon1to1).

	local V = require(ServerStorage.ClaudeTools.VenueLots1to1:Clone())
	V.check(str) -> "<id> <ok 0/1> <y>" rows. str = "id x y z fx fz w d;..." (tools/yangon/city/venues_1to1.py candidates).
	    ok: no water, road or landmark under a 7 x 7 grid of the lot, and a road surface within 40 studs in front of it;
	    y = the highest road / pavement top found in front (the lot's floor, level with the pavement).
	V.prepare(sites, names?) = YangonSites.prepare on the 1:1 root
]]

local ServerStorage = game:GetService("ServerStorage")

local V = {}

function V.check(str: string): string
	local Y = workspace.Yangon1to1
	local all = RaycastParams.new()
	all.FilterType = Enum.RaycastFilterType.Exclude
	all.FilterDescendantsInstances = { workspace.Camera }
	all.IgnoreWater = false
	local roads = RaycastParams.new()
	roads.FilterType = Enum.RaycastFilterType.Include
	roads.FilterDescendantsInstances = { Y.Roads }
	local out = {}
	local n = 0
	for row in string.gmatch(str, "[^;]+") do
		local id, x, y, z, fx, fz, w, d = string.match(row, "^(%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+)$")
		x, y, z, fx, fz, w, d = tonumber(x), tonumber(y), tonumber(z), tonumber(fx), tonumber(fz), tonumber(w), tonumber(d)
		local f = Vector3.new(fx, 0, fz).Unit
		local a = Vector3.new(-f.Z, 0, f.X)
		local c = Vector3.new(x, y + 250, z)
		local ok = true
		for u = -3, 3 do
			for v = -3, 3 do
				local r = workspace:Raycast(c + a * (u * w / 7) + f * (v * d / 7), Vector3.new(0, -500, 0), all)
				if not r then
					ok = false
				elseif r.Instance == workspace.Terrain then
					ok = ok and r.Material ~= Enum.Material.Water
				else
					ok = ok and r.Instance:IsDescendantOf(Y.Buildings)
				end
			end
		end
		local top = nil
		for k = 2, 40, 4 do
			local r = workspace:Raycast(c + f * (d / 2 + k), Vector3.new(0, -500, 0), roads)
			if r then
				top = math.max(top or -1e9, r.Position.Y)
				break
			end
		end
		ok = ok and top ~= nil
		table.insert(out, string.format("%s %d %.2f", id, if ok then 1 else 0, top or 0))
		n += 1
		if n % 25 == 0 then
			task.wait()
		end
	end
	return table.concat(out, "\n")
end

function V.prepare(sites: { [string]: any }, names: { string }?): string
	local S = require(ServerStorage.ClaudeTools.YangonSites:Clone())
	S.root = workspace.Yangon1to1
	return S.prepare(sites, names)
end

return V
