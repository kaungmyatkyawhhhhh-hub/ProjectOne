--[[
	RoadTerrainPoke (Studio, Edit; 25 Nov 2026, road bug sweep): counts terrain lying over the road surface (grass
	patches on the asphalt, owner shots 3 and 4). For every carriageway collision box (attribute RoadBox "R") it casts
	rays onto the terrain at a 6-stud grid over the box top; a hit more than 0.12 over the top is terrain showing
	through the road mesh. Prints one "TPOKE x y z over material" line per box (its worst point) and a TPOKEEND total
	to the Studio log (read the log after the TPOKESTART marker).

	Fix: RoadVerge05 trim (its 5-point test, 25 Nov) over the area, then run this again (0 lines over 0.3 expected).

	_G.TPOKE_DONE = false; require(game.ServerStorage.ClaudeTools.RoadTerrainPoke:Clone())()
]]
return function(minOver: number?)
	minOver = minOver or 0.12
	_G.TPOKE_DONE = false
	task.spawn(function()
		local C = workspace.Yangon1to1.Roads.Collide
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { workspace.Terrain }
		print("TPOKESTART")
		local n, hits, boxes = 0, 0, 0
		local t0 = os.clock()
		for bi, b in C:GetChildren() do
			if b:IsA("BasePart") and b:GetAttribute("RoadBox") == "R" then
				boxes += 1
				local s, cf = b.Size, b.CFrame
				local nx, nz = math.max(1, math.floor(s.X / 6)), math.max(1, math.floor(s.Z / 6))
				local worst, wp = 0, nil
				for i = 0, nx do
					for j = 0, nz do
						local top = cf * Vector3.new(-s.X / 2 + 0.5 + (s.X - 1) * i / nx, s.Y / 2, -s.Z / 2 + 0.5 + (s.Z - 1) * j / nz)
						n += 1
						local r = workspace:Raycast(top + Vector3.new(0, 4, 0), Vector3.new(0, -5, 0), rp)
						if r and r.Position.Y > top.Y + minOver and r.Position.Y - top.Y > worst then
							worst, wp = r.Position.Y - top.Y, r
						end
					end
				end
				if wp then
					hits += 1
					print(string.format("TPOKE %.1f %.2f %.1f %.2f %s", wp.Position.X, wp.Position.Y, wp.Position.Z, worst, wp.Material.Name))
				end
			end
			if bi % 400 == 0 then
				task.wait()
			end
		end
		print(string.format("TPOKEEND boxes %d rays %d boxes_hit %d %.1fs", boxes, n, hits, os.clock() - t0))
		_G.TPOKE_DONE = true
	end)
end
