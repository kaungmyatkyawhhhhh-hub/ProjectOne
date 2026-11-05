--[[
	BendKerbs (Studio, Edit mode; overnight step 7, 2026-11-06): red-and-white kerbs on the sharp bends.
	Works from the kerb pieces themselves: a piece is on a sharp bend when the kerb's direction turns
	fast round it (radius under RADIUS). Marked pieces next to each other make a run, walked from one
	end; a run of at least MIN pieces that turns at least TURN degrees gets alternating colours.
	That leaves out junction corners (too short) and gentle road. Each piece keeps its colour in the
	attribute OldKerbColor.

	BendKerbs.run(roads: Folder) -> runs, pieces
	BendKerbs.undo(roads: Folder)
]]

local BendKerbs = {}

local RADIUS = 75
local REACH = 14 -- neighbours on one kerb line
local MIN = 6
local TURN = 50
local RED = Color3.fromRGB(186, 34, 34)
local WHITE = Color3.fromRGB(232, 230, 224)

local function flat(v: Vector3): Vector2
	return Vector2.new(v.X, v.Z)
end

local function angle(a: Vector2, b: Vector2): number
	-- kerb pieces can point either way along the road
	return math.acos(math.clamp(math.abs(a.Unit:Dot(b.Unit)), 0, 1))
end

function BendKerbs.run(roads: Instance): (number, number)
	local runs, painted = 0, 0
	for _, road in roads:GetChildren() do
		local kerbs = {}
		for _, k in road:GetChildren() do
			if k.Name == "Kerb" and k:IsA("Part") and k.Size.Z > 2 then
				table.insert(kerbs, { p = k, at = flat(k.Position), dir = flat(k.CFrame.LookVector) })
			end
		end
		-- neighbours (a small grid)
		local G = 20
		local grid = {}
		for i, k in kerbs do
			local key = math.floor(k.at.X / G) * 100000 + math.floor(k.at.Y / G)
			grid[key] = grid[key] or {}
			table.insert(grid[key], i)
		end
		for i, k in kerbs do
			k.near = {}
			local cx, cz = math.floor(k.at.X / G), math.floor(k.at.Y / G)
			for gx = cx - 1, cx + 1 do
				for gz = cz - 1, cz + 1 do
					for _, j in grid[gx * 100000 + gz] or {} do
						local o = kerbs[j]
						local d = (o.at - k.at).Magnitude
						if j ~= i and d < REACH and angle(k.dir, o.dir) < math.rad(35) then
							table.insert(k.near, { j = j, d = d })
						end
					end
				end
			end
			local best = math.huge
			for _, n in k.near do
				local o = kerbs[n.j]
				local turn = angle(k.dir, o.dir)
				if turn > 0.01 then
					best = math.min(best, n.d / turn)
				end
			end
			k.sharp = best < RADIUS
		end
		-- runs of sharp pieces
		local seen = {}
		for i, k in kerbs do
			if k.sharp and not seen[i] then
				local run, stack = {}, { i }
				seen[i] = true
				while #stack > 0 do
					local a = table.remove(stack)
					table.insert(run, a)
					for _, n in kerbs[a].near do
						if kerbs[n.j].sharp and not seen[n.j] then
							seen[n.j] = true
							table.insert(stack, n.j)
						end
					end
				end
				if #run >= MIN then
					-- walk it from the piece furthest from the middle
					local mid = Vector2.zero
					for _, a in run do
						mid += kerbs[a].at
					end
					mid /= #run
					local start, far = run[1], -1
					for _, a in run do
						local d = (kerbs[a].at - mid).Magnitude
						if d > far then
							start, far = a, d
						end
					end
					local left = {}
					for _, a in run do
						left[a] = true
					end
					local order, now = {}, start
					while now do
						left[now] = nil
						table.insert(order, now)
						local nxt, nd = nil, math.huge
						for a in left do
							local d = (kerbs[a].at - kerbs[now].at).Magnitude
							if d < nd then
								nxt, nd = a, d
							end
						end
						if nd > REACH * 1.5 then
							nxt = nil
						end
						now = nxt
					end
					local total = 0
					for n = 2, #order do
						total += angle(kerbs[order[n - 1]].dir, kerbs[order[n]].dir)
					end
					if math.deg(total) >= TURN and #order >= MIN then
						runs += 1
						for n, a in order do
							local p = kerbs[a].p
							if p:GetAttribute("OldKerbColor") == nil then
								p:SetAttribute("OldKerbColor", p.Color)
							end
							p.Color = if n % 2 == 0 then RED else WHITE
							painted += 1
						end
					end
				end
			end
		end
		task.wait()
	end
	return runs, painted
end

function BendKerbs.undo(roads: Instance)
	for _, d in roads:GetDescendants() do
		local c = d:GetAttribute("OldKerbColor")
		if typeof(c) == "Color3" and d:IsA("BasePart") then
			d.Color = c
			d:SetAttribute("OldKerbColor", nil)
		end
	end
end

return BendKerbs
