--[[
	FarCity (Studio, Edit mode): the Riviera's far stand-in (owner 2026-11-02: "on the summit make it
	so that u can see the city lights"; building problem 1: far buildings turned into plain boxes
	with no windows and no lights).

	Roblox streams parts and terrain out past ~1500 studs and the buildings' window detail is hidden
	past ~800, so from the summit the far city was gone and the near-far one was blank boxes. This
	builds ReplicatedStorage.RivieraFar, a light copy every client always has (WorldFx moves it into
	the world and shows each piece only FAR away; see WorldFx startLod, attribute Far):
	  * ground: a 128-stud triangle grid over the land, a little under the real terrain, in its
	    colours (from build/riviera/far.json, made by tools/map_plan/export_far.py)
	  * roads: flat asphalt strips (far.json)
	  * street lamps: their glowing heads (tag LampGlow: lit at night like the real ones)
	  * buildings: each body / roof copied a little smaller (so it hides inside the real one when both
	    are there) plus its windows in clusters of two, only the ones that can be lit at night (the
	    same position hash as WorldFx.setWindow, max share 0.45): tag Window, so they glow warm at
	    night like the real ones and show as dark glass by day
	Ground, roads and lamps go in 256-stud chunks; each building is its own group with an
	ObjectValue "Real" (shown while the real one is streamed out, too).

	FarCity.build(riviera: Model, far: any) -> { [string]: number }
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FarCity = {}

local CHUNK = 256
local GROUND_RANGE = 1250 -- the real terrain and roads are there to ~1500
local BUILDING_RANGE = 950 -- (the real buildings' small detail shows to 650-700)
local MAX_SHARE = 0.45 -- DayCycle's most windows lit (dusk)
local ASPHALT = Color3.fromRGB(54, 54, 57)

local function part(props, parent): BasePart
	local p = Instance.new(props.Class or "Part")
	props.Class = nil
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

-- a triangle out of two wedges (thickness t, centred on the plane)
local function tri(a: Vector3, b: Vector3, c: Vector3, t: number, color: Color3, parent: Instance)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-6 then
		return 0
	end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	part({ Class = "WedgePart", Size = Vector3.new(t, height, math.abs(ab:Dot(back))), CFrame = CFrame.fromMatrix((a + b) / 2, right, up, back), Color = color, Material = Enum.Material.SmoothPlastic }, parent)
	part({ Class = "WedgePart", Size = Vector3.new(t, height, math.abs(ac:Dot(back))), CFrame = CFrame.fromMatrix((a + c) / 2, -right, up, -back), Color = color, Material = Enum.Material.SmoothPlastic }, parent)
	return 2
end

-- same as WorldFx.setWindow's pick
local function hash(pos: Vector3): number
	return math.abs(math.sin(pos.X * 12.9898 + pos.Y * 78.233 + pos.Z * 37.719) * 43758.5453) % 1
end

function FarCity.build(riviera: Model, far: any): { [string]: number }
	local n = { ground = 0, roads = 0, lamps = 0, buildings = 0, bodyParts = 0, windows = 0 }
	local old = ReplicatedStorage:FindFirstChild("RivieraFar")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "RivieraFar"

	local chunks: { [string]: Model } = {}
	local function chunkAt(p: Vector3): Model
		local cx, cz = math.floor(p.X / CHUNK), math.floor(p.Z / CHUNK)
		local key = cx .. "," .. cz
		local m = chunks[key]
		if not m then
			m = Instance.new("Model")
			m.Name = "Ground"
			m:SetAttribute("Center", Vector3.new((cx + 0.5) * CHUNK, p.Y, (cz + 0.5) * CHUNK))
			m:SetAttribute("Range", GROUND_RANGE)
			m:SetAttribute("Far", true)
			m:SetAttribute("NoScale", true)
			CollectionService:AddTag(m, "LOD")
			m.Parent = root
			chunks[key] = m
		end
		return m
	end

	-- ground
	local colors = {}
	for i, name in far.mats do
		local mat = Enum.Material[(
			{ W = "Water", S = "Sand", R = "Rock", L = "Limestone", G = "Grass", F = "LeafyGrass", D = "Ground", A = "Asphalt", P = "Pavement", C = "Concrete", M = "Mud" }
		)[name] or "Grass"]
		local ok, c = pcall(function()
			return workspace.Terrain:GetMaterialColor(mat)
		end)
		colors[i] = (if ok then c else Color3.fromRGB(96, 110, 66)):Lerp(Color3.new(0, 0, 0), 0.12)
	end
	local gx, step = far.gx, far.step
	local function vert(vi: number, vj: number): Vector3
		return Vector3.new(far.x0 + vi * step, far.verts[vj * gx + vi + 1], far.z0 + vj * step)
	end
	for k, c in far.cells do
		local vi, vj = c[1], c[2]
		local a, b, d, e = vert(vi, vj), vert(vi + 1, vj), vert(vi, vj + 1), vert(vi + 1, vj + 1)
		local col = colors[c[3] + 1]
		local parent = chunkAt((a + e) / 2)
		if math.abs(e.Y - (b.Y + d.Y - a.Y)) < 2.5 then
			-- (nearly) flat: one slab
			local x = (b - a + e - d) / 2
			local z = (d - a + e - b) / 2
			local up = z:Cross(x).Unit
			if up.Y < 0 then
				up = -up
			end
			local centre = (a + b + d + e) / 4 - up * 0.5
			part({ Size = Vector3.new(x.Magnitude + 1, 1, z.Magnitude + 1), CFrame = CFrame.fromMatrix(centre, x.Unit, up), Color = col, Material = Enum.Material.SmoothPlastic }, parent)
			n.ground += 1
		else
			n.ground += tri(a, b, e, 1, col, parent)
			n.ground += tri(a, e, d, 1, col, parent)
		end
		if k % 300 == 0 then
			task.wait()
		end
	end

	-- roads (a stud under the real road, so it hides where both are there)
	for k, r in far.roads do
		local a = Vector3.new(r[1], r[2] - 0.9, r[3])
		local b = Vector3.new(r[4], r[5] - 0.9, r[6])
		local len = (b - a).Magnitude
		if len > 0.5 then
			part({ Name = "Road", Size = Vector3.new(r[7] + 4, 1, len + 6), CFrame = CFrame.lookAt((a + b) / 2, b), Color = ASPHALT, Material = Enum.Material.SmoothPlastic }, chunkAt((a + b) / 2))
			n.roads += 1
		end
		if k % 400 == 0 then
			task.wait()
		end
	end

	-- street lamp heads
	for _, m in riviera:GetDescendants() do
		if m.Name == "StreetLamp" and m:IsA("Model") then
			local head = m:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local p = part({ Name = "Lamp", Size = Vector3.new(4, 1.6, 6), CFrame = head.CFrame, Color = head.Color, Material = head.Material }, chunkAt(head.Position))
				CollectionService:AddTag(p, "LampGlow")
				n.lamps += 1
			end
		end
	end

	-- buildings
	local buildings = riviera:FindFirstChild("Buildings")
	-- (and the landmarks: the Old Rock palace, cathedral and old-town houses carry the same attributes)
	local list = if buildings then buildings:GetChildren() else {}
	local oldRock = riviera:FindFirstChild("OldRock")
	for _, d in (if oldRock then oldRock:GetDescendants() else {}) do
		if d:IsA("Model") and d:GetAttribute("Shell") then
			table.insert(list, d)
		end
	end
	for k, b in list do
		if not b:IsA("Model") or not b:FindFirstChild("Body") then
			continue
		end
		local g = Instance.new("Model")
		g.Name = "Building"
		local body = b:FindFirstChild("Body") :: BasePart
		local shell = b:GetAttribute("Shell")
		g:SetAttribute("Center", if typeof(shell) == "CFrame" then shell.Position else body.Position)
		g:SetAttribute("Range", BUILDING_RANGE)
		g:SetAttribute("Far", true)
		local real = Instance.new("ObjectValue")
		real.Name = "Real"
		real.Value = b
		real.Parent = g
		-- the shell: one box in the wall colour (v2 buildings: attributes Shell, ShellSize, Wall) and
		-- the roof; v1: every big part outside the Detail group. All 0.4 smaller on each side.
		local recess = b:GetAttribute("Recess") or 0
		if typeof(shell) == "CFrame" then
			local size = b:GetAttribute("ShellSize") :: Vector3
			part({ Name = "Shell", Size = size - Vector3.new(0.8, 0.8, 0.8), CFrame = shell, Color = b:GetAttribute("Wall"), Material = Enum.Material.SmoothPlastic }, g)
			n.bodyParts += 1
		end
		for _, p in b:GetChildren() do
			local keep = if typeof(shell) == "CFrame" then (p.Name == "Roof" or p.Name == "Cornice" or p.Name == "PlantRoom") else true
			if keep and p:IsA("BasePart") and p.Transparency < 0.9 then
				local c = p:Clone()
				c:ClearAllChildren()
				for _, t in c:GetTags() do
					c:RemoveTag(t)
				end
				c.Size = Vector3.new(math.max(0.2, c.Size.X - 0.8), math.max(0.2, c.Size.Y - 0.8), math.max(0.2, c.Size.Z - 0.8))
				c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = false, false, false, false
				c.Parent = g
				n.bodyParts += 1
			end
		end
		-- windows: rows of glass on each face, in clusters of two; a band of glass (the 1970s
		-- blocks' balconies) in pieces about 11 studs wide. v2 panes sit in the recess: the far ones
		-- go just in front of the face.
		local rows: { [string]: { BasePart } } = {}
		if recess > 0 then
			-- v2: a few of the panes that can be lit (up to about a third, 6-24 a building) stand in
			-- for the rest; WorldFx lights twice the share of them
			local panes = {}
			for _, w in b:GetDescendants() do
				if w:IsA("BasePart") and w:HasTag("Window") then
					table.insert(panes, { w, hash(w.Position + Vector3.new(1.7, 2.3, 0.9)) })
				end
			end
			table.sort(panes, function(p, q)
				return p[2] < q[2]
			end)
			local cap = math.clamp(math.floor(#panes * 0.35), math.min(6, #panes), 24)
			for i = 1, cap do
				local w = panes[i][1]
				local p = part({ Name = "Glass", Size = Vector3.new(w.Size.X + 0.6, w.Size.Y, 0.2), CFrame = w.CFrame * CFrame.new(0, 0, -(recess + 0.18)), Color = Color3.fromRGB(46, 42, 38), Material = Enum.Material.SmoothPlastic }, g)
				CollectionService:AddTag(p, "Window")
				CollectionService:AddTag(p, "FarWindow")
				n.windows += 1
			end
		end
		for _, w in (if recess > 0 then {} else b:GetDescendants()) do
			if w:IsA("BasePart") and w:HasTag("Window") then
				local look = w.CFrame.LookVector
				local key = string.format("%d,%d,%d", math.round(look.X * 4), math.round(look.Z * 4), math.round(w.Position.Y))
				rows[key] = rows[key] or {}
				table.insert(rows[key], w)
			end
		end
		for _, row in rows do
			local rightV = row[1].CFrame.RightVector
			table.sort(row, function(p, q)
				return p.Position:Dot(rightV) < q.Position:Dot(rightV)
			end)
			local slots = {} -- { cframe, width, height }
			for _, w in row do
				if w.Size.X > 14 then
					local pieces = math.max(2, math.round(w.Size.X / 11))
					local pw = w.Size.X / pieces
					for s = 1, pieces do
						table.insert(slots, { w.CFrame * CFrame.new(-w.Size.X / 2 + (s - 0.5) * pw, 0, 0), pw - 1.6, w.Size.Y })
					end
				else
					table.insert(slots, { w.CFrame, w.Size.X, w.Size.Y })
				end
			end
			local s = 1
			while s <= #slots do
				local a = slots[s]
				local nb = slots[s + 1]
				local cf, wdt, hgt = a[1], a[2], a[3]
				if nb and a[2] < 10 and nb[2] < 10 and (nb[1].Position - a[1].Position).Magnitude < 9 then
					-- two windows side by side: one cluster spanning both
					local l = a[1] * CFrame.new(-a[2] / 2, 0, 0)
					local r = nb[1] * CFrame.new(nb[2] / 2, 0, 0)
					cf = a[1].Rotation + (l.Position + r.Position) / 2
					wdt = (r.Position - l.Position).Magnitude
					hgt = math.max(a[3], nb[3])
					s += 2
				else
					s += 1
				end
				local place = cf * CFrame.new(0, 0, -(recess + 0.18))
				if recess > 0 or hash(place.Position) < MAX_SHARE then
					local p = part({ Name = "Glass", Size = Vector3.new(wdt, hgt, 0.2), CFrame = place, Color = Color3.fromRGB(44, 52, 58), Material = Enum.Material.SmoothPlastic }, g)
					CollectionService:AddTag(p, "Window")
					CollectionService:AddTag(p, "FarWindow")
					n.windows += 1
				end
			end
		end
		CollectionService:AddTag(g, "LOD")
		g.Parent = root
		n.buildings += 1
		if k % 20 == 0 then
			task.wait()
		end
	end

	-- night lights that survive low graphics: Roblox stops drawing parts past ~500 studs on low and
	-- medium graphics (most phones), but billboards still show. One billboard of lit windows per
	-- building, at its centre (on high graphics the building around it hides it), switched on at night
	-- and far away by WorldFx (folder Lights, tag FarLight)
	local lights = Instance.new("Folder")
	lights.Name = "Lights"
	lights.Parent = root
	local WARM = { Color3.fromRGB(255, 196, 120), Color3.fromRGB(255, 176, 96), Color3.fromRGB(255, 214, 150) }
	for k, b in list do
		local shell = b:GetAttribute("Shell")
		local size = b:GetAttribute("ShellSize")
		if typeof(shell) ~= "CFrame" or typeof(size) ~= "Vector3" then
			continue
		end
		local floorY = (shell * CFrame.new(0, -size.Y / 2, 0)).Position.Y
		local wdt = math.min(size.X, size.Z) * 0.85
		-- (the part of the building above the street: windows are from the floor up)
		local top = shell.Position.Y + size.Y / 2
		local ground = math.max(floorY, top - 160)
		local hgt = (top - ground) * 0.85
		local a = part({ Name = "Light", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(shell.Position.X, (top + ground) / 2, shell.Position.Z), Transparency = 1 }, lights)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(wdt, hgt)
		bb.LightInfluence = 0
		bb.MaxDistance = 100000
		bb.AlwaysOnTop = false
		bb.Enabled = false
		bb.ResetOnSpawn = false
		local cols = math.max(2, math.floor(wdt / 12)) -- a dot stands for two windows
		local rows = math.max(3, math.floor(hgt / 9))
		local count = 0
		for r = 1, rows do
			for c = 1, cols do
				local h = hash(shell.Position + Vector3.new(c * 3.7, r * 9.1, 0))
				if h < 0.35 and count < 16 then
					local f = Instance.new("Frame")
					f.BorderSizePixel = 0
					f.BackgroundColor3 = if h < 0.03 then Color3.fromRGB(230, 236, 240) else WARM[(c + r) % #WARM + 1]
					f.Size = UDim2.fromScale(0.6 / cols, 0.5 / rows)
					f.Position = UDim2.fromScale((c - 1) / cols + 0.2 / cols, (r - 1) / rows + 0.25 / rows)
					f.Parent = bb
					count += 1
				end
			end
		end
		bb.Parent = a
		CollectionService:AddTag(bb, "FarLight")
		n.lights = (n.lights or 0) + 1
		if k % 50 == 0 then
			task.wait()
		end
	end

	root.Parent = ReplicatedStorage
	return n
end

return FarCity
