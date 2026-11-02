--[[
	Stadium (Studio, Edit mode): Riviera Bay Stadium in the north-west block of the Riviera Bay loop
	(owner 2026-11-02: "last will be the stadium"). Fictional name only.

	A football ground in the new-build bay: a striped pitch with its markings and goals; red and white
	stands stepped up on all four sides (the west one split by the players' tunnel, which cars can
	drive through onto the pitch); white outer walls with a row of tall round-topped arches along the
	south side and the name over them; roofs over the long stands; four floodlight masts that light
	the pitch at night; a scoreboard. The ordinary buildings that stood in the block go.

	Stadium.build(parent, buildings, rng) -> counts
]]

local CollectionService = game:GetService("CollectionService")

local Stadium = {}

local BLOCK = { 11862, 944, 12012, 1072 } -- x0, z0, x1, z1 (clear of the roads)
local WHITE = Color3.fromRGB(236, 234, 228)
local RED = Color3.fromRGB(186, 30, 40)
local CONCRETE = Color3.fromRGB(196, 192, 184)
local GRASS_A = Color3.fromRGB(70, 132, 58)
local GRASS_B = Color3.fromRGB(80, 146, 64)
local LINE = Color3.fromRGB(240, 240, 236)

local function part(props, parent): BasePart
	local p = Instance.new(props.Class or "Part")
	props.Class = nil
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function flat(p: BasePart): BasePart
	p.CastShadow = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

function Stadium.build(parent: Instance, buildings: Instance, rng: Random): { [string]: number }
	local n = { removed = 0, parts = 0 }
	local old = parent:FindFirstChild("Stadium")
	if old then
		old:Destroy()
	end
	-- the block's buildings go
	for _, m in buildings:GetChildren() do
		local s = m:GetAttribute("Shell")
		if typeof(s) == "CFrame" then
			local p = s.Position
			if p.X > BLOCK[1] - 20 and p.X < BLOCK[3] + 20 and p.Z > BLOCK[2] - 20 and p.Z < BLOCK[4] + 20 then
				m:Destroy()
				n.removed += 1
			end
		end
	end

	local W, D = BLOCK[3] - BLOCK[1], BLOCK[4] - BLOCK[2]
	local cx, cz = (BLOCK[1] + BLOCK[3]) / 2, (BLOCK[2] + BLOCK[4]) / 2
	-- the floor: the roads' height on the west side (the tunnel opens onto the loop road there)
	local roads = parent:FindFirstChild("Roads")
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { roads }
	local hit = workspace:Raycast(Vector3.new(BLOCK[1] - 30, 300, cz), Vector3.new(0, -400, 0), rp)
	local Y = if hit then hit.Position.Y else 14
	local C = CFrame.new(cx, Y, cz)
	local T = workspace.Terrain
	-- (terrain is 4-stud voxels: its top is kept 2 studs under the floor so it never shows through)
	T:FillBlock(C * CFrame.new(0, -9, 0), Vector3.new(W + 6, 14, D + 6), Enum.Material.Concrete)
	T:FillBlock(C * CFrame.new(0, 38, 0), Vector3.new(W + 6, 80, D + 6), Enum.Material.Air)

	local root = Instance.new("Model")
	root.Name = "Stadium"
	local det = Instance.new("Model")
	det.Name = "Detail"
	det:SetAttribute("Center", C.Position)
	det:SetAttribute("Range", 700)
	CollectionService:AddTag(det, "LOD")

	-- concourse floor and the pitch (stripes across its length), markings, goals
	part({ Name = "Floor", Size = Vector3.new(W, 1, D), CFrame = C * CFrame.new(0, -0.5, 0), Material = Enum.Material.Concrete, Color = CONCRETE }, root)
	local PW, PD = 92, 56
	local stripes = 10
	for k = 1, stripes do
		local x = -PW / 2 + (k - 0.5) * PW / stripes
		flat(part({ Name = "Pitch", Size = Vector3.new(PW / stripes, 0.4, PD), CFrame = C * CFrame.new(x, 0.2, 0), Material = Enum.Material.Grass, Color = if k % 2 == 0 then GRASS_A else GRASS_B }, root))
	end
	local function line(x: number, z: number, sx: number, sz: number)
		flat(part({ Name = "Marking", Size = Vector3.new(sx, 0.05, sz), CFrame = C * CFrame.new(x, 0.43, z), Material = Enum.Material.SmoothPlastic, Color = LINE }, det))
	end
	line(0, -PD / 2 + 0.3, PW, 0.5)
	line(0, PD / 2 - 0.3, PW, 0.5)
	line(-PW / 2 + 0.3, 0, 0.5, PD)
	line(PW / 2 - 0.3, 0, 0.5, PD)
	line(0, 0, 0.5, PD)
	-- the centre circle as a ring of short dashes
	for k = 0, 23 do
		local a = k / 24 * math.pi * 2
		local p = C * CFrame.new(math.cos(a) * 8, 0.43, math.sin(a) * 8) * CFrame.Angles(0, -a, 0)
		flat(part({ Name = "Marking", Size = Vector3.new(0.5, 0.05, 2.2), CFrame = p, Material = Enum.Material.SmoothPlastic, Color = LINE }, det))
	end
	for _, side in { -1, 1 } do
		local gx = side * PW / 2
		-- penalty box and the goal box
		line(gx - side * 14, 0, 0.5, 34)
		line(gx - side * 7, -17 + 0.25, 14, 0.5)
		line(gx - side * 7, 17 - 0.25, 14, 0.5)
		line(gx - side * 5, 0, 0.5, 16)
		line(gx - side * 2.5, -8 + 0.25, 5, 0.5)
		line(gx - side * 2.5, 8 - 0.25, 5, 0.5)
		-- the goal: posts, bar and a net
		for _, z in { -6, 6 } do
			part({ Name = "Post", Size = Vector3.new(0.5, 7, 0.5), CFrame = C * CFrame.new(gx, 3.5, z), Material = Enum.Material.SmoothPlastic, Color = LINE }, det)
		end
		part({ Name = "Bar", Size = Vector3.new(0.5, 0.5, 12.5), CFrame = C * CFrame.new(gx, 7, 0), Material = Enum.Material.SmoothPlastic, Color = LINE }, det)
		flat(part({ Name = "Net", Size = Vector3.new(4, 7, 12), CFrame = C * CFrame.new(gx + side * 2, 3.5, 0), Material = Enum.Material.Fabric, Color = LINE, Transparency = 0.7, CanCollide = false }, det))
	end

	-- the stands: rows stepping up and back from the pitch to the outer wall
	local ROW_H, ROW_D = 3.2, 3.4
	local function stand(along: number, from: number, to: number, axis: string, gapHalf: number?)
		-- along: length of the stand; from / to: distance of its front / back from the centre
		local rows = math.floor((to - from) / ROW_D)
		for k = 1, rows do
			local d = from + (k - 0.5) * ROW_D
			local h = 2 + k * ROW_H
			local col = if k % 5 == 0 then WHITE else RED
			for _, sgn in { -1, 1 } do
				-- (the players' tunnel cuts the west end: sgn -1 on the x axis)
				local gap = gapHalf ~= nil and axis == "x" and sgn == -1
				local pieces = if gap then { { -along / 2, -(gapHalf :: number) }, { gapHalf :: number, along / 2 } } else { { -along / 2, along / 2 } }
				for _, pc in pieces do
					local len = pc[2] - pc[1]
					local mid = (pc[1] + pc[2]) / 2
					local cf = if axis == "z" then C * CFrame.new(mid, h / 2, sgn * d) else C * CFrame.new(sgn * d, h / 2, mid)
					local size = if axis == "z" then Vector3.new(len, h, ROW_D + 0.05) else Vector3.new(ROW_D + 0.05, h, len)
					part({ Name = "Stand", Size = size, CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = col }, root)
				end
			end
		end
		return rows
	end
	-- long sides (north and south) and the ends (west, with the tunnel, and east)
	local sideRows = stand(PW + 8, PD / 2 + 4, D / 2 - 3, "z")
	stand(PD + 8, PW / 2 + 5, W / 2 - 3, "x", 12)
	local standTop = 2 + sideRows * ROW_H

	-- the outer walls: plain on three sides, arches along the south
	local WALL_H = standTop + 6
	local function wall(len: number, cf: CFrame)
		part({ Name = "Wall", Size = Vector3.new(len, WALL_H, 2), CFrame = cf * CFrame.new(0, WALL_H / 2, 0), Material = Enum.Material.Concrete, Color = WHITE }, root)
	end
	wall(W, C * CFrame.new(0, 0, -D / 2 + 1)) -- north
	-- west: the tunnel opening in the middle
	for _, sgn in { -1, 1 } do
		local len = D / 2 - 12
		part({ Name = "Wall", Size = Vector3.new(2, WALL_H, len), CFrame = C * CFrame.new(-W / 2 + 1, WALL_H / 2, sgn * (12 + len / 2)), Material = Enum.Material.Concrete, Color = WHITE }, root)
	end
	part({ Name = "Wall", Size = Vector3.new(2, WALL_H - 14, 24), CFrame = C * CFrame.new(-W / 2 + 1, 14 + (WALL_H - 14) / 2, 0), Material = Enum.Material.Concrete, Color = WHITE }, root)
	-- the tunnel itself: a roof over the gap in the west stand
	part({ Name = "TunnelRoof", Size = Vector3.new(W / 2 - PW / 2 - 4, 2, 26), CFrame = C * CFrame.new(-(PW / 2 + 4 + (W / 2 - PW / 2 - 4) / 2), 15, 0), Material = Enum.Material.Concrete, Color = CONCRETE }, root)
	part({ Name = "Wall", Size = Vector3.new(2, WALL_H, D), CFrame = C * CFrame.new(W / 2 - 1, WALL_H / 2, 0), Material = Enum.Material.Concrete, Color = WHITE }, root) -- east
	-- south: piers between tall arches, a band over them with the name
	local arches = 9
	local step = W / arches
	local openW = step * 0.62
	local openH = WALL_H - 9
	local south = C * CFrame.new(0, 0, D / 2 - 1)
	for k = 0, arches do
		local x = -W / 2 + k * step
		local pw = step - openW
		local wdt = if k == 0 or k == arches then pw / 2 else pw
		local px = if k == 0 then x + wdt / 2 elseif k == arches then x - wdt / 2 else x
		part({ Name = "Pier", Size = Vector3.new(wdt, openH, 2.4), CFrame = south * CFrame.new(px, openH / 2, 0), Material = Enum.Material.Concrete, Color = WHITE }, root)
	end
	part({ Name = "Band", Size = Vector3.new(W, WALL_H - openH, 2.4), CFrame = south * CFrame.new(0, openH + (WALL_H - openH) / 2, 0), Material = Enum.Material.Concrete, Color = WHITE }, root)
	for k = 1, arches do
		local x = -W / 2 + (k - 0.5) * step
		-- the dark concourse behind, and the round top (two wedges filling the corners)
		flat(part({ Name = "ArchShade", Size = Vector3.new(openW, openH, 0.4), CFrame = south * CFrame.new(x, openH / 2, -1.6), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 44, 42) }, root))
		-- the round top: wall across the top of the opening, a dark half disc cut into it
		part({ Name = "ArchFill", Size = Vector3.new(openW, openW / 2, 2.4), CFrame = south * CFrame.new(x, openH - openW / 4, 0), Material = Enum.Material.Concrete, Color = WHITE }, root)
		flat(part({ Name = "ArchTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, openW, openW), CFrame = south * CFrame.new(x, openH - openW / 2, 1.3) * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 44, 42) }, root))
	end
	local sign = part({ Name = "NameBoard", Size = Vector3.new(W * 0.6, 4, 0.4), CFrame = south * CFrame.new(0, openH + (WALL_H - openH) / 2, 1.4) * CFrame.Angles(0, math.pi, 0), Transparency = 1, CanCollide = false }, det)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(1200, 80)
	gui.LightInfluence = 0.6
	gui.MaxDistance = 600
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = "RIVIERA BAY STADIUM"
	t.TextColor3 = RED
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Parent = gui
	gui.Parent = sign

	-- roofs over the long stands, a little sloped toward the pitch
	for _, sgn in { -1, 1 } do
		local depth = D / 2 - PD / 2 - 6
		local cf = C * CFrame.new(0, WALL_H + 2, sgn * (D / 2 - depth / 2)) * CFrame.Angles(sgn * 0.08, 0, 0)
		part({ Name = "StandRoof", Size = Vector3.new(W - 10, 1.2, depth), CFrame = cf, Material = Enum.Material.Metal, Color = Color3.fromRGB(226, 228, 228) }, root)
		for k = -3, 3 do
			part({ Name = "RoofTruss", Size = Vector3.new(0.8, 2.4, depth), CFrame = cf * CFrame.new(k * (W - 14) / 6, -1.6, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 202, 204) }, det)
		end
	end

	-- floodlight masts at the corners, lighting the pitch at night
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local base = C * CFrame.new(sx * (W / 2 - 4), 0, sz * (D / 2 - 4))
			local H = WALL_H + 26
			part({ Name = "Mast", Shape = Enum.PartType.Cylinder, Size = Vector3.new(H, 2, 2), CFrame = base * CFrame.new(0, H / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(180, 182, 184) }, root)
			local headPos = (base * CFrame.new(0, H + 3, 0)).Position
			local head = part({ Name = "Floodlight", Size = Vector3.new(9, 5, 1.2), CFrame = CFrame.lookAt(headPos, C.Position + Vector3.new(0, 0, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(236, 240, 244), CanCollide = false }, root)
			CollectionService:AddTag(head, "LampGlow")
			local l = Instance.new("SpotLight")
			l.Face = Enum.NormalId.Front
			l.Range = 140
			l.Angle = 70
			l.Brightness = 3
			l.Color = Color3.fromRGB(236, 240, 255)
			l.Shadows = false
			l.Parent = head
			CollectionService:AddTag(l, "LODLight")
			CollectionService:AddTag(l, "DayOff")
		end
	end

	-- the scoreboard over the east stand
	local sb = part({ Name = "Scoreboard", Size = Vector3.new(1.4, 12, 30), CFrame = C * CFrame.new(W / 2 - 4, WALL_H + 9, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(20, 22, 26) }, root)
	part({ Name = "ScoreboardLegs", Size = Vector3.new(1, 10, 1), CFrame = C * CFrame.new(W / 2 - 4, WALL_H + 1, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 150) }, root)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Left
	sg.CanvasSize = Vector2.new(500, 200)
	sg.LightInfluence = 0
	sg.MaxDistance = 600
	local tl = Instance.new("TextLabel")
	tl.BackgroundTransparency = 1
	tl.Size = UDim2.fromScale(1, 1)
	tl.Text = "BAY  0 - 0  VISITORS"
	tl.TextColor3 = Color3.fromRGB(255, 196, 80)
	tl.Font = Enum.Font.Arcade
	tl.TextScaled = true
	tl.Parent = sg
	sg.Parent = sb

	-- for the far city: the outline of the stadium
	root:SetAttribute("Shell", C * CFrame.new(0, WALL_H / 2, 0))
	root:SetAttribute("ShellSize", Vector3.new(W, WALL_H, D))
	root:SetAttribute("Wall", WHITE)
	det.Parent = root
	root.Parent = parent
	local _ = rng
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			n.parts += 1
		end
	end
	return n
end

return Stadium
