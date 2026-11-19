-- (19 Nov) BUILT deck-feet check: POINTS = roads05_deckfeet_points.py lines "name|end|x y z x y z ...".
-- Each point: ray from data y + 12 down onto Workspace.Yangon1to1.Roads.Collide; off = hit top - data y.
-- Only points over an existing Roads.Meshes Cell_<cx>x<cz> (1536) are checked. A foot is BAD when |off| > 0.6 at any sample.
return function(POINTS: string)
	local R = workspace.Yangon1to1.Roads
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Include
	p.FilterDescendantsInstances = { R.Collide }
	local bad, ok, skipped, out = 0, 0, 0, {}
	for line in POINTS:gmatch("[^\n]+") do
		local name, e, rest = line:match("^(.-)|(%a+)|(.*)$")
		local v = {}
		for w in rest:gmatch("%S+") do
			table.insert(v, tonumber(w))
		end
		local x0, z0 = v[1], v[3]
		if not (x0 and R.Meshes:FindFirstChild(string.format("Cell_%dx%d", x0 // 1536, z0 // 1536))) then
			skipped += 1
		else
			local offs, worst = {}, 0
			for i = 1, #v, 3 do
				local x, y, z = v[i], v[i + 1], v[i + 2]
				local h = workspace:Raycast(Vector3.new(x, y + 12, z), Vector3.new(0, -60, 0), p)
				local off = if h then h.Position.Y - y else -99
				table.insert(offs, string.format("%.1f", off))
				if math.abs(off) > math.abs(worst) then
					worst = off
				end
			end
			if math.abs(worst) > 0.6 then
				bad += 1
				table.insert(out, string.format("%s %s (%.0f, %.0f) cell %dx%d: %s", name, e, x0, z0, x0 // 1536, z0 // 1536, table.concat(offs, " ")))
			else
				ok += 1
			end
		end
	end
	return string.format("deck feet: %d ok, %d BAD, %d not in the game\n%s", ok, bad, skipped, table.concat(out, "\n"))
end
