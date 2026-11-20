--[[
	TrussBridge21Nov.luau (Studio, Edit; owner 21 Nov: "do these: the truss bridge ..."; reference frame
	City Legends/refs_21nov/0804_56s.jpg and 0804_81s.jpg): the white steel bowstring truss arches on both edges of
	the Sule Pagoda Road flyover over the railway (north of Yangon Central). The road deck itself is the road
	builder's and is NOT touched: the arches stand just outside its edges and follow its measured height.
	Deck: D boxes x 36052..36136 at the crown z ~42945 (deck top ~54, ground ~31). Span 150 studs (50 m), rise 30.
	Per side: 12 arch segments, 12 bottom-chord segments, 23 lattice members, 2 end posts = 49 parts (98 in all).
	Butt-jointed segments (exact node-to-node lengths), lattice members stop at the chord surfaces: no coplanar
	overlaps. CanCollide / CanQuery off (they sit outside the deck's own edge; the camera ray ignores them).
	M.build() -> Workspace.Yangon1to1.Landmarks.IrlBuild21Nov.SulePagodaRdTrussBridge; M.undo().
]]
local M = {}
M.Z0, M.SPAN, M.RISE, M.N = 42870, 150, 30, 12
M.EDGES = { 36047.5, 36141.5 } -- arch centre lines, 4.5 / 5.5 studs outside the deck edges (36052, 36136)
local WHITE = Color3.fromRGB(226, 228, 226)

local function deckY(x, z)
	-- the deck top just inside the edge (D box)
	local inside = if x < 36094 then x + 8 else x - 8
	local h = workspace:Raycast(Vector3.new(inside, 300, z), Vector3.new(0, -400, 0))
	if h and h.Instance:GetAttribute("RoadBox") == "D" then
		return h.Position.Y
	end
	return nil
end

local function beam(parent, a: Vector3, b: Vector3, w: number, h: number, trim: number)
	local d = b - a
	local len = d.Magnitude - 2 * trim
	if len <= 0.2 then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = "Steel"
	p.Size = Vector3.new(w, h, len)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	p.Color = WHITE
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function M.build()
	local lm = workspace.Yangon1to1.Landmarks
	local root = lm:FindFirstChild("IrlBuild21Nov") or Instance.new("Folder")
	root.Name = "IrlBuild21Nov"
	root.Parent = lm
	local old = root:FindFirstChild("SulePagodaRdTrussBridge")
	if old then
		old:Destroy()
	end
	local m = Instance.new("Model")
	m.Name = "SulePagodaRdTrussBridge"
	local n, missing = 0, 0
	for side, x in M.EDGES do
		local bot, top = {}, {}
		for i = 0, M.N do
			local t = i / M.N
			local z = M.Z0 + t * M.SPAN
			local y = deckY(x, z)
			if not y then
				missing += 1
				y = 50
			end
			local yb = y + 1.2 -- bottom chord sits on the deck edge line
			bot[i] = Vector3.new(x, yb, z)
			top[i] = Vector3.new(x, yb + 4 * M.RISE * t * (1 - t) + 2.5, z)
		end
		for i = 0, M.N - 1 do
			if beam(m, top[i], top[i + 1], 2.4, 2.4, 0) then n += 1 end -- arch (top chord)
			if beam(m, bot[i], bot[i + 1], 2.0, 2.0, 0) then n += 1 end -- bottom chord
		end
		-- lattice: verticals at the inner nodes, diagonals zig-zag (Warren with posts), trimmed to the chord surfaces
		for i = 1, M.N - 1 do
			if beam(m, bot[i], top[i], 1.2, 1.2, 1.25) then n += 1 end
		end
		for i = 0, M.N - 1 do
			local a, b = if i % 2 == 0 then bot[i] else top[i], if i % 2 == 0 then top[i + 1] else bot[i + 1]
			if (a - b).Magnitude > 4 then
				if beam(m, a, b, 1.0, 1.0, 1.4) then n += 1 end
			end
		end
		-- end posts (portal legs) down from the arch feet to the deck edge
		for _, i in { 0, M.N } do
			local p = beam(m, bot[i] - Vector3.new(0, 1.2, 0), top[i], 2.6, 2.6, 0)
			if p then
				p.Name = "EndPost"
				n += 1
			end
		end
	end
	m.Parent = root
	return n, missing
end

function M.undo()
	local f = workspace.Yangon1to1.Landmarks:FindFirstChild("IrlBuild21Nov")
	local m = f and f:FindFirstChild("SulePagodaRdTrussBridge")
	if m then
		m:Destroy()
	end
end

return M
