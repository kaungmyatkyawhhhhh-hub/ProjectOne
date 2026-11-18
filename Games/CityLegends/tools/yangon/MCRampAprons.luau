--[[
	MCRampAprons (Studio, Edit; 18 Nov 2026, owner: "the myanmar plaza underground parking is gone, its blocked off by road"):
	the driveway aprons from Kabar Aye Pagoda Road's carriageway up to the top of the Myanmar Centre basement ramps
	(ramp_in, ramp_out). The roads05 data keeps the mouths open (build/city_1to1/ramp_mouths.json: the basement aisles
	Lane #4080 / #4081 dropped, no kerb and no pavement across each mouth); this lays the slope between the J37
	carriageway (~1.4 under the site's pavement plane) and the ramp top. Measured at run time from the road boxes, so
	run it again after any rebuild of the road cells 22x17 / 22x18.

	Each apron: a quad A B C D (A, B on the carriageway edge at +-HW along the road from the mouth point; C, D where the
	road's normals through A, B meet the ramp's top line), two triangles of WedgeParts, top flush with the road at
	A B and with the ramp floor at C D (butt joins, no shared faces: no flicker), 0.8 thick under it.
	Into Workspace.Yangon1to1.Landmarks.MyanmarCentre.RampAprons (replaced on each run). Collision on, query on.

	local A = require(game.ServerStorage.ClaudeTools.MCRampAprons:Clone()); A.run() -> report
]]

local M = {}
M.HW = 12.5 -- half the opening along the road (= ramp_mouths.json mouth hw)
M.THICK = 0.8
M.RAMPS = {
	{ name = "ramp_in", top = Vector3.new(34625.9, 0, 27605.3), axis = Vector3.new(0.990, 0, 0.138), mouth = Vector3.new(34620.0, 0, 27604.5) },
	{ name = "ramp_out", top = Vector3.new(34630.8, 0, 27567.3), axis = Vector3.new(0.993, 0, 0.120), mouth = Vector3.new(34624.8, 0, 27566.6) },
}

local COLOR = Color3.fromRGB(96, 96, 98)

-- one triangle as two right-angle wedges (the usual split at the foot of the apex), top face = the triangle a b c,
-- th thick below it
local function wedge(parent: Instance, name: string)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Anchored = true
	w.Material = Enum.Material.Concrete
	w.Color = COLOR
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.CastShadow = false
	w.Parent = parent
	return w
end
local function tri(parent: Instance, a: Vector3, b: Vector3, c: Vector3, th: number, name: string)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local n = if right.Y > 0 then right else -right
	local w1 = wedge(parent, name)
	w1.Size = Vector3.new(th, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a + b) / 2 - n * th / 2, right, up, back)
	local w2 = wedge(parent, name)
	w2.Size = Vector3.new(th, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix((a + c) / 2 - n * th / 2, -right, up, -back)
end
M.tri = tri

function M.run(): string
	local Y = workspace.Yangon1to1
	local mc = Y.Landmarks.MyanmarCentre
	local old = mc:FindFirstChild("RampAprons")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Model")
	folder.Name = "RampAprons"
	local pR = RaycastParams.new()
	pR.FilterType = Enum.RaycastFilterType.Include
	pR.FilterDescendantsInstances = { Y.Roads.Collide }
	local pM = RaycastParams.new()
	pM.FilterType = Enum.RaycastFilterType.Include
	pM.FilterDescendantsInstances = { mc.Collide }
	local log = {}
	for _, r in M.RAMPS do
		-- the road's direction at the mouth: the carriageway box under the mouth point, its long axis across the ramp
		local h = workspace:Raycast(r.mouth - r.axis * 8 + Vector3.new(0, 100, 0), Vector3.new(0, -150, 0), pR)
		assert(h and h.Instance:GetAttribute("RoadBox") == "R", r.name .. ": no carriageway box 8 studs out")
		local cf = h.Instance.CFrame
		local dir = if math.abs(cf.RightVector:Dot(r.axis)) < math.abs(cf.LookVector:Dot(r.axis)) then cf.RightVector else cf.LookVector
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		local inward = Vector3.new(-dir.Z, 0, dir.X)
		if inward:Dot(r.axis) < 0 then
			inward = -inward
		end
		local function edgeAt(s: number): Vector3
			-- march from the carriageway toward the ramp until the R box ends
			local base = r.mouth + dir * s - inward * 10
			local last
			for k = 0, 120 do
				local p = base + inward * (k * 0.1)
				local q = workspace:Raycast(p + Vector3.new(0, 100, 0), Vector3.new(0, -150, 0), pR)
				if not q or q.Instance:GetAttribute("RoadBox") ~= "R" then
					break
				end
				last = q.Position
			end
			assert(last, r.name .. ": no road edge")
			return last
		end
		local nrm = Vector3.new(-r.axis.Z, 0, r.axis.X)
		local function topAt(e: Vector3): Vector3
			-- along the road normal from e to the ramp's top line (t = 0), then the ramp floor's height there
			local t0 = (e - r.top):Dot(r.axis)
			local k = -t0 / inward:Dot(r.axis)
			local p = e + inward * k
			local q = workspace:Raycast(Vector3.new(p.X, 100, p.Z) + r.axis * 0.3, Vector3.new(0, -150, 0), pM)
			assert(q, r.name .. ": no ramp floor")
			return Vector3.new(p.X, q.Position.Y, p.Z)
		end
		local A, B = edgeAt(-M.HW), edgeAt(M.HW)
		local D, C = topAt(A), topAt(B)
		tri(folder, A, B, C, M.THICK, "Apron_" .. r.name)
		tri(folder, A, C, D, M.THICK, "Apron_" .. r.name)
		table.insert(log, string.format("%s: road edge y %.2f / %.2f, ramp top y %.2f / %.2f, depth %.1f / %.1f, grade %.0f%%",
			r.name, A.Y, B.Y, D.Y, C.Y, (D - A).Magnitude, (C - B).Magnitude, 100 * (D.Y - A.Y) / (D - A).Magnitude))
	end
	folder.Parent = mc
	return table.concat(log, "\n")
end

return M
