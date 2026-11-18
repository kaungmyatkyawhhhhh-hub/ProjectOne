--[[
	MCLift (2026-11-19, owner: "make the escalators & elevators work when there is a player on it. also the one from
	underground parking elevator too"). The car-park lift of Myanmar Centre, from the basement's lift / stair core
	(tools/yangon/MCBasement.luau: its "LIFT MALL" door was a closed dummy on a solid core) up through the mall:
	stops B1, G, 1, 2, 3. No public plan of the real basement exists, so the shaft rises where the basement core stands
	(south-east, under tower B's edge), doors facing the aisle / the mall floor on the same side at every level.
	mc3d.py (LIFT_W) cuts the shaft out of the mall's floors, ceilings and floor collision (city/mc_escalator_patch.py
	PATCH=lift -> mc1_lift.glb, swapped in with MCEscalators.luau). This file builds the rest as Parts in
	Workspace.Yangon1to1.Landmarks.MyanmarCentre.Lift (tag "MallLift"; src/server/MallMovers.server.lua runs it,
	src/client/MallLift.client.lua is the floor picker):
	  shaft walls (white outside, grey inside) with a door opening per stop, sliding steel landing doors, a call panel
	  with a "Call lift" prompt and a LIFT sign at each stop, the car (granite floor, brushed walls, lit ceiling, sliding
	  car doors), invisible Stop<i> markers. M.cutBasement() splits the basement's Core and Ceiling round the shaft (old
	  parts kept in ServerStorage.MCLiftOld) and removes the dummy LiftDoor / LiftButton.
	All pieces butt or keep >= 0.02 between opposite faces; no coplanar visible faces. Run in Studio Edit:
	M.cutBasement(), M.build(); M.undo() puts it back.
]]
local M = {}
local CollectionService = game:GetService("CollectionService")
local MC = workspace.Yangon1to1.Landmarks.MyanmarCentre

-- the shaft (world, axis-aligned): outer rect = the hole mc3d.LIFT_W cuts (34895.2-34902.8, 27454.2-27461.8)
local X0, X1, Z0, Z1 = 34895.2, 34902.8, 27454.2, 27461.8
local ZB = 27462.02 -- the basement core's front face (the shaft's front wall comes out to it below BTOP)
local BTOP = 39.5 -- top of the basement ceiling slab
local TOP = 102.985 -- under the closed 4th-level slab (y0 43.36 + f(48.5))
local T = 0.3 -- wall thickness
local CX, CZ = (X0 + X1) / 2, (Z0 + Z1) / 2
local OPEN_W, OPEN_H = 3.6, 6.7
local STOPS = { { "B1", 29.66 }, { "G", 43.42 }, { "1", 59.86 }, { "2", 74.86 }, { "3", 89.86 } }
local CAR_W, CAR_H = 6.8, 8.0

local WHITE = Color3.fromRGB(236, 236, 232)
local GREY = Color3.fromRGB(196, 198, 200)
local STEEL = Color3.fromRGB(150, 154, 160)
local DARK = Color3.fromRGB(40, 40, 44)

local function part(parent: Instance, name: string, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number,
	color: Color3, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(x1 - x0, y1 - y0, z1 - z0)
	p.CFrame = CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	for k, v in props or {} do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function sign(p: Part, face: Enum.NormalId, text: string, size: number)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 50
	g.LightInfluence = 0.3
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextColor3 = Color3.fromRGB(40, 42, 46)
	t.Font = Enum.Font.GothamBold
	t.TextSize = size
	t.Text = text
	t.Parent = g
end

-- split an (optionally slightly tilted) part round the shaft's outer rect, in the part's own frame
local function splitAround(p: BasePart, x0: number, x1: number, z0: number, z1: number, keep: Instance)
	local cf, s = p.CFrame, p.Size
	local a = cf:PointToObjectSpace(Vector3.new(x0, cf.Y, z0))
	local b = cf:PointToObjectSpace(Vector3.new(x1, cf.Y, z1))
	local lx0, lx1 = math.min(a.X, b.X), math.max(a.X, b.X)
	local lz0, lz1 = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
	local hx, hz = s.X / 2, s.Z / 2
	lx0, lx1, lz0, lz1 = math.max(lx0, -hx), math.min(lx1, hx), math.max(lz0, -hz), math.min(lz1, hz)
	local pieces = {
		{ -hx, lx0, -hz, hz }, { lx1, hx, -hz, hz }, { lx0, lx1, -hz, lz0 }, { lx0, lx1, lz1, hz },
	}
	for i, r in pieces do
		if r[2] - r[1] > 1e-3 and r[4] - r[3] > 1e-3 then
			local q = p:Clone()
			q.Size = Vector3.new(r[2] - r[1], s.Y, r[4] - r[3])
			q.CFrame = cf * CFrame.new((r[1] + r[2]) / 2, 0, (r[3] + r[4]) / 2)
			q.Name = p.Name
			q:SetAttribute("LiftCut", i)
			for _, ch in q:GetChildren() do
				ch:Destroy() -- labels / lights stay on the original only
			end
			q.Parent = p.Parent
		end
	end
	p.Parent = keep
end

function M.cutBasement(): string
	local SS = game:GetService("ServerStorage")
	local keep = SS:FindFirstChild("MCLiftOld") or Instance.new("Folder")
	keep.Name = "MCLiftOld"
	keep.Parent = SS
	local B = MC.Basement
	local n = 0
	for _, name in { "Core", "Ceiling" } do
		for _, p in B:GetDescendants() do
			if p:IsA("BasePart") and p.Name == name and p:GetAttribute("LiftCut") == nil then
				local box = p.CFrame:PointToObjectSpace(Vector3.new(CX, p.Position.Y, CZ))
				if math.abs(box.X) < p.Size.X / 2 and math.abs(box.Z) < p.Size.Z / 2 then
					-- cut out to the core's front face (the shaft's basement front wall fills Z1-ZB up to BTOP)
					splitAround(p, X0, X1, Z0, ZB, keep)
					n += 1
				end
			end
		end
	end
	for _, name in { "LiftDoor", "LiftButton" } do
		local p = B:FindFirstChild(name, true)
		if p then
			p.Parent = keep
			n += 1
		end
	end
	return "cut / moved " .. n
end

function M.build(): string
	local old = MC:FindFirstChild("Lift")
	if old then
		old:Destroy()
	end
	local L = Instance.new("Model")
	L.Name = "Lift"
	L:SetAttribute("CarHeight", CAR_H)
	L:SetAttribute("DoorSlide", OPEN_W / 2 - 0.2)
	L:SetAttribute("At", 2)
	local shaft = Instance.new("Model")
	shaft.Name = "Shaft"
	shaft.Parent = L
	-- side and back walls, full height (white; the mall sees their outer faces)
	part(shaft, "WallBack", X0, X1, STOPS[1][2], TOP, Z0, Z0 + T, WHITE)
	part(shaft, "WallL", X0, X0 + T, STOPS[1][2], TOP, Z0 + T, Z1 - T, WHITE)
	part(shaft, "WallR", X1 - T, X1, STOPS[1][2], TOP, Z0 + T, Z1 - T, WHITE)
	-- the front wall: two jambs and the lintels between the door openings; out to the core face below BTOP
	local ox0, ox1 = CX - OPEN_W / 2, CX + OPEN_W / 2
	for _, seg in { { STOPS[1][2], BTOP, ZB }, { BTOP, TOP, Z1 } } do
		local y0, y1, zf = seg[1], seg[2], seg[3]
		part(shaft, "Jamb", X0, ox0, y0, y1, Z1 - T, zf, WHITE)
		part(shaft, "Jamb", ox1, X1, y0, y1, Z1 - T, zf, WHITE)
	end
	for i, s in STOPS do
		local yTop = s[2] + OPEN_H
		local yNext = STOPS[i + 1] and STOPS[i + 1][2] or TOP
		-- lintel from this opening's head to the next stop's floor (split at BTOP where the front wall steps back)
		local cuts = { yTop, yNext }
		if yTop < BTOP and yNext > BTOP then
			cuts = { yTop, BTOP, yNext }
		end
		for k = 1, #cuts - 1 do
			part(shaft, "Lintel", ox0, ox1, cuts[k], cuts[k + 1], Z1 - T, cuts[k] < BTOP and ZB or Z1, WHITE)
		end
		local zf = s[2] < BTOP and ZB or Z1
		-- landing doors (steel), 0.02 off the wall face, meeting in the middle
		local d0, d1 = zf + 0.02, zf + 0.14
		part(L, "DoorL" .. i, ox0, CX, s[2], s[2] + OPEN_H, d0, d1, STEEL, { Reflectance = 0.08 })
		part(L, "DoorR" .. i, CX, ox1, s[2], s[2] + OPEN_H, d0, d1, STEEL, { Reflectance = 0.08 })
		-- a LIFT sign over the door on the mall floors (the basement has its own "LIFT MALL" sign)
		-- call panel clear of the opened doors: in the basement on the core face right of the door, on the mall
		-- floors on the shaft's right side wall by the front corner
		local panel, lightCF
		if s[2] < BTOP then
			panel = part(L, "Call" .. i, ox1 + 2.2, ox1 + 2.8, s[2] + 3.4, s[2] + 4.4, zf, zf + 0.12, DARK)
			lightCF = { ox1 + 2.38, ox1 + 2.62, zf + 0.12, zf + 0.16 }
		else
			panel = part(L, "Call" .. i, X1, X1 + 0.12, s[2] + 3.4, s[2] + 4.4, Z1 - 1.0, Z1 - 0.4, DARK)
			lightCF = { X1 + 0.12, X1 + 0.16, Z1 - 0.82, Z1 - 0.58 }
		end
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Call lift"
		pr.ObjectText = "Lift " .. s[1]
		pr.HoldDuration = 0
		pr.MaxActivationDistance = 10
		pr.RequiresLineOfSight = false
		pr.Parent = panel
		local LIT = Color3.fromRGB(255, 214, 120)
		part(panel, "Light", lightCF[1], lightCF[2], s[2] + 3.78, s[2] + 4.02, lightCF[3], lightCF[4], LIT,
			{ Material = Enum.Material.Neon, CanCollide = false })
		if i > 1 then
			local sg = part(L, "Sign" .. i, ox0 - 0.4, ox1 + 0.4, s[2] + OPEN_H + 0.4, s[2] + OPEN_H + 1.2, zf, zf + 0.06, GREY,
				{ CanCollide = false })
			sign(sg, Enum.NormalId.Back, "LIFT  B1 · G · 1 · 2 · 3", 26)
		end
		local stop = Instance.new("Part")
		stop.Name = "Stop" .. i
		stop.Anchored, stop.CanCollide, stop.CanQuery, stop.CanTouch = true, false, false, false
		stop.Transparency = 1
		stop.Size = Vector3.new(1, 0.2, 1)
		stop.CFrame = CFrame.new(CX, s[2], CZ)
		stop:SetAttribute("Label", s[1])
		local stops = L:FindFirstChild("Stops") or Instance.new("Folder")
		stops.Name = "Stops"
		stops.Parent = L
		stop.Parent = stops
	end
	-- the car, parked at G (stop 2)
	local car = Instance.new("Model")
	car.Name = "Car"
	car.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local y = STOPS[2][2]
	local cx0, cx1, cz0, cz1 = CX - CAR_W / 2, CX + CAR_W / 2, CZ - CAR_W / 2, CZ + CAR_W / 2
	local floor = part(car, "Floor", cx0, cx1, y - 0.4, y, cz0, cz1, Color3.fromRGB(58, 58, 62), { Material = Enum.Material.Slate })
	part(car, "Roof", cx0, cx1, y + CAR_H, y + CAR_H + 0.3, cz0, cz1, WHITE)
	part(car, "Back", cx0, cx1, y, y + CAR_H, cz0, cz0 + 0.2, Color3.fromRGB(172, 174, 178), { Reflectance = 0.05 })
	part(car, "SideL", cx0, cx0 + 0.2, y, y + CAR_H, cz0 + 0.2, cz1, Color3.fromRGB(172, 174, 178), { Reflectance = 0.05 })
	part(car, "SideR", cx1 - 0.2, cx1, y, y + CAR_H, cz0 + 0.2, cz1, Color3.fromRGB(172, 174, 178), { Reflectance = 0.05 })
	part(car, "Front", cx0 + 0.2, ox0, y, y + CAR_H, cz1 - 0.2, cz1, Color3.fromRGB(172, 174, 178))
	part(car, "Front", ox1, cx1 - 0.2, y, y + CAR_H, cz1 - 0.2, cz1, Color3.fromRGB(172, 174, 178))
	part(car, "FrontHead", ox0, ox1, y + OPEN_H, y + CAR_H, cz1 - 0.2, cz1, Color3.fromRGB(172, 174, 178))
	local lamp = part(car, "Lamp", CX - 1.6, CX + 1.6, y + CAR_H - 0.06, y + CAR_H, CZ - 1.6, CZ + 1.6, Color3.fromRGB(255, 246, 228),
		{ Material = Enum.Material.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Range, light.Brightness, light.Shadows = 10, 1.2, false
	light.Parent = lamp
	-- car doors just inside the front wall, 0.1 behind it
	part(car, "CarDoorL", ox0, CX, y, y + OPEN_H, cz1 - 0.42, cz1 - 0.3, STEEL, { Reflectance = 0.08 })
	part(car, "CarDoorR", CX, ox1, y, y + OPEN_H, cz1 - 0.42, cz1 - 0.3, STEEL, { Reflectance = 0.08 })
	car.PrimaryPart = floor
	car.Parent = L
	L.Parent = MC
	CollectionService:AddTag(L, "MallLift")
	return "lift built: " .. #L:GetDescendants() .. " instances"
end

function M.undo(): string
	local L = MC:FindFirstChild("Lift")
	if L then
		L:Destroy()
	end
	local keep = game:GetService("ServerStorage"):FindFirstChild("MCLiftOld")
	if keep then
		for _, p in MC.Basement:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("LiftCut") then
				p:Destroy()
			end
		end
		for _, p in keep:GetChildren() do
			p.Parent = MC.Basement
		end
		keep:Destroy()
	end
	return "undone"
end

return M
