--!nocheck
-- SUPERSEDED 25 Nov 2026: the deck it laid (Roads.HledanDeckFix) stacked over the baked deck (double deck). The data
-- now has one Pyay Road deck (city/roads05_hledan_fix.py), cells 17x17..17x19 rebuilt, HledanDeckFix deleted. Do not run.
--[[ The Hledan flyover (Pyay Road, by Novotel): one continuous deck (owner, 22 Nov: "fix the pyay road bridge near novotel").
	Real: one bridge of about 860 m (OSM). The baked map has a high hump (deck top 73, z 27496-28240), a ramp down to the
	ground (z 28517-28710) and a low hump (58.3, z 28834-29142). The road meshes are whole 1536-stud cells, so the dip
	cannot be taken out here: this tool lays a NEW deck over it, level at the high hump's height and down a 6.8% ramp onto
	the low hump's south end. The old dipped road stays underneath as the ground road.
	Studio (Edit):  local H = require(ServerStorage.ClaudeTools.HledanDeck:Clone())  print(H.build())  |  H.undo()
	H.build() returns the stations "x,z,old top,new top;..." for src/shared/YangonDeckFix.lua (the traffic lanes' heights). ]]
local H = {}
local Z0, Z1 = 28200, 29240
local GRADE = 0.068
local ASPH, CONC, WHITE, YELLOW = Color3.fromRGB(46, 47, 50), Color3.fromRGB(176, 172, 164), Color3.fromRGB(236, 236, 232), Color3.fromRGB(230, 222, 114)

local function part(parent, name, size, cf, color, mat, collide)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.Size, p.CFrame, p.Color, p.Material = name, true, size, cf, color, mat
	p.CanCollide = collide ~= false
	p.CastShadow = size.Y >= 2 and size.X > 8
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function H.stations()
	local list = {}
	local n = 0
	for _, p in workspace.Yangon1to1.Roads.Collide:GetChildren() do
		n += 1
		if n % 20000 == 0 then task.wait() end
		if p:GetAttribute("RoadBox") == "D" and p.Position.Z > Z0 and p.Position.Z < Z1 and p.Position.X > 27100 and p.Position.X < 27470 then
			local top = (p.CFrame * CFrame.new(0, p.Size.Y / 2, 0)).Position
			table.insert(list, { x = top.X, z = top.Z, e = top.Y, w = p.Size.X, right = p.CFrame.RightVector })
		end
	end
	table.sort(list, function(a, b) return a.z < b.z end)
	-- one station per ~14 studs of z (two boxes can share a spot at a seam)
	local out = {}
	for _, s in list do
		local last = out[#out]
		if not last or s.z - last.z > 9 then table.insert(out, s) end
	end
	local d = 0
	for i, s in out do
		if i > 1 then d += (Vector3.new(s.x, 0, s.z) - Vector3.new(out[i - 1].x, 0, out[i - 1].z)).Magnitude end
		s.s = d
	end
	return out
end

function H.profile(S)
	-- level at the high hump's height from the last level station, then down GRADE onto the low hump's south end
	local top, iA = -1e9, 1
	for i, s in S do if s.z < 28300 and s.e > top - 0.05 then top = math.max(top, s.e) iA = i end end
	local iB = #S
	for i = #S, 1, -1 do if S[i].z < 29150 then iB = i break end end
	local sD = S[iB].s - (top - S[iB].e) / GRADE
	for i, s in S do
		if i <= iA or i > iB then
			s.n = s.e
		elseif s.s <= sD then
			s.n = top
		else
			s.n = math.max(top - (s.s - sD) * GRADE, s.e)
		end
	end
	return iA, iB, top
end

function H.build()
	local Y = workspace.Yangon1to1
	local old = Y.Roads:FindFirstChild("HledanDeckFix")
	if old then old:Destroy() end
	local S = H.stations()
	local iA, iB, top = H.profile(S)
	local m = Instance.new("Model")
	m.Name = "HledanDeckFix"
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Terrain }
	local made = 0
	for i = iA, iB - 1 do
		local a, b = S[i], S[i + 1]
		if math.max(a.n - a.e, b.n - b.e) < 0.25 then continue end
		local pa, pb = Vector3.new(a.x, a.n, a.z), Vector3.new(b.x, b.n, b.z)
		local cf = CFrame.lookAt((pa + pb) / 2, pb)
		local len = (pb - pa).Magnitude
		local w = math.max(a.w, b.w) + 2
		local slab = part(m, "Deck", Vector3.new(w, 3.6, len + 0.4), cf * CFrame.new(0, -1.8, 0), ASPH, Enum.Material.Asphalt)
		slab:SetAttribute("RoadBox", "D")
		for _, sx in { -1, 1 } do
			part(m, "Parapet", Vector3.new(1.2, 3.4, len + 0.4), cf * CFrame.new(sx * (w / 2 + 0.6), -0.3, 0), CONC, Enum.Material.Concrete)
			part(m, "EdgeLine", Vector3.new(0.45, 0.1, len + 0.4), cf * CFrame.new(sx * (w / 2 - 2.2), 0.06, 0), WHITE, Enum.Material.SmoothPlastic, false)
			part(m, "CentreLine", Vector3.new(0.45, 0.1, len + 0.4), cf * CFrame.new(sx * 0.6, 0.06, 0), YELLOW, Enum.Material.SmoothPlastic, false)
			if i % 2 == 0 then
				part(m, "LaneDash", Vector3.new(0.4, 0.1, len * 0.7), cf * CFrame.new(sx * (w / 4 - 0.4), 0.06, 0), WHITE, Enum.Material.SmoothPlastic, false)
			end
		end
		-- a portal pier every 6th span where the deck is well over the ground: columns outside the old road
		if i % 6 == 0 then
			local g = workspace:Raycast(pa + a.right * (w / 2 + 12) + Vector3.new(0, 200, 0), Vector3.new(0, -500, 0), rp)
			local gy = g and g.Position.Y or (a.n - 16)
			local h = a.n - 3.6 - gy
			if h > 5 then
				local base = CFrame.lookAt(Vector3.new(a.x, a.n - 3.6, a.z), Vector3.new(b.x, a.n - 3.6, b.z))
				part(m, "PierBeam", Vector3.new(w + 12, 3, 5), base * CFrame.new(0, -1.5, 0), CONC, Enum.Material.Concrete)
				for _, sx in { -1, 1 } do
					part(m, "PierColumn", Vector3.new(4.5, h + 2, 4.5), base * CFrame.new(sx * (w / 2 + 3.4), -(h + 2) / 2, 0), CONC, Enum.Material.Concrete)
				end
			end
		end
		made += 1
		if made % 10 == 0 then task.wait() end
	end
	m.Parent = Y.Roads
	local rows = {}
	for i = iA, iB + 1 do
		local s = S[i]
		if s then table.insert(rows, string.format("%.1f,%.1f,%.2f,%.2f", s.x, s.z, s.e, s.n)) end
	end
	return string.format("spans %d parts %d top %.2f from z %.0f to %.0f|", made, #m:GetChildren(), top, S[iA].z, S[iB].z) .. table.concat(rows, ";")
end

function H.undo()
	local old = workspace.Yangon1to1.Roads:FindFirstChild("HledanDeckFix")
	if old then old:Destroy() end
end
return H
