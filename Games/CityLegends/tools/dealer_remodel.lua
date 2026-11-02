--[[
	dealer_remodel (Studio tool, a ModuleScript run from the command bar / MCP)
	Legends Motors, venue remodel 1 (owner, 2026-11-03, "Remodel the venues"): the showroom becomes
	the ground floor of a cream Belle Époque Riviera block, like the owner's Monaco showroom photos
	(imports/refs/dealership): carved stone floors above with arched windows, stone balconies and black
	iron railings; a curved light-grey band over the glass with big gold serif LEGENDS MOTORS letters;
	a black awning with a thin gold line and name; a light stone base with metal vents. Inside: a
	pale terrazzo floor, a white ceiling with black light tracks running on the diagonal (small warm
	spots), warm wood-slat back wall with gold letters, beige curtains, light stone outside walls.
	The street: light paving, steel bollards with red bands, white stone cubes, planters with palms
	(the map's own dressing pieces). No neon signs, no logos.

	It edits ServerStorage.DealerBody (front +Z, pivot at the bottom middle, the showroom box from
	x -47.5 to 68.5, z -78 to 57.5, roof at y 25). Every new part goes in DealerBody.Remodel (run it
	again and that folder is rebuilt); the parts it recolours keep their old look in attributes
	(Orig*), so `M.undo(body)` puts them back. Gameplay pieces (Markers, prompts, the entrance, the
	drive-out bay) are not touched; the indoor display spots get turned to angles.

	require(module).run(game.ServerStorage.DealerBody)
]]

local CollectionService = game:GetService("CollectionService")

local M = {}

local STONE = Color3.fromRGB(214, 180, 128) -- cream / ochre Riviera stone (warm: the sky light is blue)
local STONE_LIGHT = Color3.fromRGB(228, 206, 166)
local STONE_DARK = Color3.fromRGB(184, 150, 104)
local GLASS = Color3.fromRGB(28, 32, 40)
local IRON = Color3.fromRGB(22, 22, 24)
local GOLD = Color3.fromRGB(214, 168, 72)
local BAND = Color3.fromRGB(204, 204, 200) -- the light-grey concrete band
local WOOD = Color3.fromRGB(150, 100, 62)
local WOOD_DARK = Color3.fromRGB(96, 62, 38)
local CURTAIN = Color3.fromRGB(214, 200, 176)
local TERRAZZO = Color3.fromRGB(238, 236, 230)
local CEILING = Color3.fromRGB(238, 238, 234)
local WARM = Color3.fromRGB(255, 220, 170)

-- the showroom box
local X0, X1 = -47.5, 68.5
local ZF, ZB = 57.5, -78
local ROOF = 25

local folder: Model

local function part(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = size.Magnitude > 12
	for k, v in (props or {}) :: { [string]: any } do
		(p :: any)[k] = v
	end
	p.Parent = (props and props.Parent) or folder
	return p
end

local function deco(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, props: { [string]: any }?): Part
	local p = part(size, cf, color, material, props)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

-- big gold serif letters on a part's front, lit warm (no neon: a self-lit SurfaceGui)
local function letters(p: BasePart, text: string, color: Color3, face: Enum.NormalId?, glow: number?)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 10 -- (TextScaled stops at 100 px: 10 a stud lets letters reach 10 studs)
	g.LightInfluence = 0.4
	g.Brightness = glow or 1.4
	g.MaxDistance = 900
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
	t.TextColor3 = color
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(120, 86, 30)
	s.Thickness = 1.5
	s.Parent = t
end

-- remember a part's look before recolouring it (undo)
local function restyle(p: BasePart, color: Color3, material: Enum.Material?, reflect: number?)
	if p:GetAttribute("OrigColor") == nil then
		p:SetAttribute("OrigColor", p.Color)
		p:SetAttribute("OrigMaterial", p.Material.Name)
		p:SetAttribute("OrigReflectance", p.Reflectance)
	end
	p.Color = color
	if material then
		p.Material = material
	end
	if reflect then
		p.Reflectance = reflect
	end
end

---------------------------------------------------------------------
-- Outside: the Belle Époque block over the showroom
---------------------------------------------------------------------
local FLOOR_H = 9
local FLOORS = 5
local DEPTH = 40 -- the block's depth (from the front back)
local BAY = 9.5 -- one window bay

local function facadeFloor(k: number, zFront: number)
	local y0 = ROOF + (k - 1) * FLOOR_H
	local width = X1 - X0
	local bays = math.floor(width / BAY)
	local pier = 2.6
	local cx = (X0 + X1) / 2
	-- the spandrel under the windows and the floor band (a thin cornice)
	part(Vector3.new(width, 2.6, 1.2), CFrame.new(cx, y0 + 1.3, zFront - 0.6), STONE, Enum.Material.Limestone)
	deco(Vector3.new(width + 0.8, 0.7, 1.9), CFrame.new(cx, y0 + 0.35, zFront - 0.3), STONE_LIGHT, Enum.Material.Limestone)
	local wy0, wy1 = y0 + 2.6, y0 + FLOOR_H
	local winH = wy1 - wy0
	local used = bays * BAY
	local x = cx - used / 2
	-- end piers
	part(Vector3.new(x - X0 + pier / 2, winH, 1.2), CFrame.new((X0 + x + pier / 2) / 2, (wy0 + wy1) / 2, zFront - 0.6), STONE, Enum.Material.Limestone)
	local xEnd = cx + used / 2
	part(Vector3.new(X1 - xEnd + pier / 2, winH, 1.2), CFrame.new((X1 + xEnd - pier / 2) / 2, (wy0 + wy1) / 2, zFront - 0.6), STONE, Enum.Material.Limestone)
	for b = 0, bays - 1 do
		local bx = x + b * BAY + BAY / 2
		if b > 0 then
			part(Vector3.new(pier, winH, 1.2), CFrame.new(x + b * BAY, (wy0 + wy1) / 2, zFront - 0.6), STONE, Enum.Material.Limestone)
		end
		local openW = BAY - pier
		-- the window: recessed dark glass, a stone head with an arch, a sill
		local paneH = winH - 2.2
		local pane = part(Vector3.new(openW, paneH, 0.3), CFrame.new(bx, wy0 + paneH / 2, zFront - 1.4), GLASS, Enum.Material.SmoothPlastic, { Reflectance = 0.08, CastShadow = false })
		CollectionService:AddTag(pane, "Window")
		part(Vector3.new(openW, winH - paneH, 1.2), CFrame.new(bx, wy0 + paneH + (winH - paneH) / 2, zFront - 0.6), STONE, Enum.Material.Limestone)
		-- a carved stone hood over the window (a ledge with a keystone)
		deco(Vector3.new(openW + 1.4, 0.5, 0.9), CFrame.new(bx, wy0 + paneH + 0.45, zFront + 0.3), STONE_LIGHT, Enum.Material.Limestone)
		deco(Vector3.new(openW + 1.2, 0.5, 1.6), CFrame.new(bx, wy0 + 0.25, zFront - 0.2), STONE_LIGHT, Enum.Material.Limestone)
		-- a keystone over the arch
		deco(Vector3.new(1, 1.4, 0.6), CFrame.new(bx, wy0 + paneH + 1.2, zFront + 0.2), STONE_LIGHT, Enum.Material.Limestone)
		-- balconies on the 2nd and 4th floors: a carved stone slab and black iron railings
		if k == 2 or k == 4 then
			local bw, bd = openW + 1.6, 3.2
			deco(Vector3.new(bw, 0.8, bd), CFrame.new(bx, wy0 - 0.2, zFront + bd / 2), STONE_LIGHT, Enum.Material.Limestone)
			deco(Vector3.new(bw - 0.6, 0.6, bd - 0.6), CFrame.new(bx, wy0 - 0.9, zFront + bd / 2 - 0.2), STONE_DARK, Enum.Material.Limestone)
			local ry = wy0 + 0.2
			deco(Vector3.new(bw, 0.22, 0.22), CFrame.new(bx, ry + 3.2, zFront + bd - 0.15), IRON, Enum.Material.Metal)
			deco(Vector3.new(0.22, 0.22, bd), CFrame.new(bx - bw / 2 + 0.1, ry + 3.2, zFront + bd / 2), IRON, Enum.Material.Metal)
			deco(Vector3.new(0.22, 0.22, bd), CFrame.new(bx + bw / 2 - 0.1, ry + 3.2, zFront + bd / 2), IRON, Enum.Material.Metal)
			for s = 0, 4 do
				local sx = bx - bw / 2 + 0.3 + s * (bw - 0.6) / 4
				deco(Vector3.new(0.14, 3.1, 0.14), CFrame.new(sx, ry + 1.6, zFront + bd - 0.15), IRON, Enum.Material.Metal)
			end
			deco(Vector3.new(bw, 0.16, 0.16), CFrame.new(bx, ry + 0.5, zFront + bd - 0.15), IRON, Enum.Material.Metal)
		end
	end
	-- the top floor: one long iron balcony
	if k == FLOORS then
		deco(Vector3.new(width - 4, 0.7, 2.4), CFrame.new(cx, wy0 - 0.1, zFront + 1.2), STONE_LIGHT, Enum.Material.Limestone)
		deco(Vector3.new(width - 4, 0.22, 0.22), CFrame.new(cx, wy0 + 3.3, zFront + 2.3), IRON, Enum.Material.Metal)
		for s = 0, math.floor((width - 4) / 3) do
			deco(Vector3.new(0.14, 3.2, 0.14), CFrame.new(X0 + 2 + s * 3, wy0 + 1.7, zFront + 2.3), IRON, Enum.Material.Metal)
		end
	end
end

local function sideWall(x: number, zFront: number, zBack: number, faceOut: number)
	local top = ROOF + FLOORS * FLOOR_H
	part(Vector3.new(1.2, top - ROOF, zFront - zBack), CFrame.new(x, (ROOF + top) / 2, (zFront + zBack) / 2), STONE, Enum.Material.Limestone)
	-- a few windows on the side (two per floor)
	for k = 1, FLOORS do
		local y0 = ROOF + (k - 1) * FLOOR_H
		for _, dz in { 10, 24 } do
			local pane = part(Vector3.new(0.3, 5.6, 4), CFrame.new(x + faceOut * 0.62, y0 + 5, zFront - dz), GLASS, Enum.Material.SmoothPlastic, { Reflectance = 0.08, CastShadow = false })
			CollectionService:AddTag(pane, "Window")
			deco(Vector3.new(0.6, 0.5, 5.2), CFrame.new(x + faceOut * 0.8, y0 + 2, zFront - dz), STONE_LIGHT, Enum.Material.Limestone)
		end
	end
end

local function upperBlock()
	local zFront = ZF
	local zBack = ZF - DEPTH
	local top = ROOF + FLOORS * FLOOR_H
	for k = 1, FLOORS do
		facadeFloor(k, zFront)
	end
	sideWall(X0 + 0.6, zFront, zBack, -1)
	sideWall(X1 - 0.6, zFront, zBack, 1)
	-- back and roof
	part(Vector3.new(X1 - X0, top - ROOF, 1.2), CFrame.new((X0 + X1) / 2, (ROOF + top) / 2, zBack + 0.6), STONE, Enum.Material.Limestone)
	part(Vector3.new(X1 - X0, 1, DEPTH), CFrame.new((X0 + X1) / 2, top + 0.5, (zFront + zBack) / 2), Color3.fromRGB(120, 112, 104), Enum.Material.Slate)
	-- the big top cornice and parapet
	deco(Vector3.new(X1 - X0 + 2.4, 1.4, 3), CFrame.new((X0 + X1) / 2, top + 0.7, zFront + 0.6), STONE_LIGHT, Enum.Material.Limestone)
	deco(Vector3.new(X1 - X0 + 1.2, 2.2, 1.2), CFrame.new((X0 + X1) / 2, top + 2.5, zFront - 0.2), STONE, Enum.Material.Limestone)
	-- a slate mansard with dormers behind the parapet
	part(Vector3.new(X1 - X0 - 4, 6, 10), CFrame.new((X0 + X1) / 2, top + 4, zFront - 10) * CFrame.Angles(math.rad(-30), 0, 0), Color3.fromRGB(70, 74, 82), Enum.Material.Slate)
	for d = 0, 5 do
		local dx = X0 + 12 + d * ((X1 - X0 - 24) / 5)
		part(Vector3.new(4, 4.5, 4), CFrame.new(dx, top + 4.5, zFront - 6), STONE_LIGHT, Enum.Material.Limestone)
		local pane = part(Vector3.new(2.6, 3, 0.3), CFrame.new(dx, top + 4.3, zFront - 3.9), GLASS, Enum.Material.SmoothPlastic, { Reflectance = 0.08, CastShadow = false })
		CollectionService:AddTag(pane, "Window")
	end
	-- chimneys
	for _, cx in { X0 + 6, X1 - 6 } do
		part(Vector3.new(3, 7, 3), CFrame.new(cx, top + 4.5, zBack + 6), STONE_DARK, Enum.Material.Brick)
	end
end

---------------------------------------------------------------------
-- Outside: the showroom front
---------------------------------------------------------------------
local function showroomFront()
	local cx = (X0 + X1) / 2
	local width = X1 - X0
	-- the curved light-grey band over the glass (a slab and a rounded nose)
	local bandY0, bandY1 = 18.6, ROOF
	local bh = bandY1 - bandY0
	part(Vector3.new(width + 1, bh, 3), CFrame.new(cx, (bandY0 + bandY1) / 2, ZF + 1.5), BAND, Enum.Material.Concrete)
	part(Vector3.new(width + 1, 3, 3), CFrame.new(cx, bandY0 + 1.5, ZF + 3) * CFrame.Angles(0, 0, math.pi / 2), BAND, Enum.Material.Concrete, { Shape = Enum.PartType.Cylinder })
	-- the gold letters on it
	local face = deco(Vector3.new(width - 16, bh - 1.4, 0.2), CFrame.new(cx, (bandY0 + bandY1) / 2 + 0.3, ZF + 3.12), BAND, Enum.Material.Concrete, { Transparency = 1 })
	face.Name = "NameLetters"
	letters(face, "LEGENDS MOTORS", GOLD, Enum.NormalId.Back, 1.6)
	-- the black awning with a thin gold line and the name
	local aw = deco(Vector3.new(width - 8, 1.6, 3.6), CFrame.new(cx, 17.2, ZF + 1.8), IRON, Enum.Material.Fabric)
	deco(Vector3.new(width - 8, 0.12, 0.08), CFrame.new(cx, 16.6, ZF + 3.62), GOLD, Enum.Material.Metal)
	local awFace = deco(Vector3.new(width - 40, 1.1, 0.1), CFrame.new(cx, 17.3, ZF + 3.65), IRON, Enum.Material.Fabric, { Transparency = 1 })
	letters(awFace, "LEGENDS  MOTORS   ·   RIVIERA", GOLD, Enum.NormalId.Back, 1.1)
	local _ = aw
	-- the light stone base with metal vents under the glass (not across the doors)
	for _, seg in { { X0, 0 }, { 20, X1 } } do
		local a, b = seg[1], seg[2]
		local w = b - a
		part(Vector3.new(w, 2.4, 1), CFrame.new((a + b) / 2, 3.2, ZF + 0.5), STONE_LIGHT, Enum.Material.Limestone)
		for v = 0, math.floor(w / 8) - 1 do
			local vx = a + 4 + v * 8
			deco(Vector3.new(5, 1.2, 0.1), CFrame.new(vx, 3.2, ZF + 1.02), Color3.fromRGB(120, 122, 126), Enum.Material.DiamondPlate)
		end
	end
	-- warm floodlights at the foot of the facade, aimed up at the stone
	for _, fx in { X0 + 12, cx, X1 - 12 } do
		local lamp = deco(Vector3.new(1.2, 0.8, 1.2), CFrame.new(fx, ROOF + 0.4, ZF + 4.6), IRON, Enum.Material.Metal)
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Top
		l.Angle = 70
		l.Range = 46
		l.Brightness = 1.6
		l.Color = WARM
		l.Parent = lamp
	end
end

---------------------------------------------------------------------
-- Inside
---------------------------------------------------------------------
local function interior()
	-- black light tracks running on the diagonal, each with small warm spots
	local cxi, czi = (X0 + X1) / 2, (ZF + ZB) / 2 + 6
	local ang = math.rad(32)
	local dir = Vector3.new(math.sin(ang), 0, math.cos(ang))
	local across = Vector3.new(dir.Z, 0, -dir.X)
	local lit = 0
	for t = -3, 3 do
		local mid = Vector3.new(cxi, ROOF - 0.5, czi) + across * (t * 16)
		local len = 120
		-- clip to the room (roughly): shorter near the corners
		len -= math.abs(t) * 18
		deco(Vector3.new(1, 0.5, len), CFrame.lookAt(mid, mid + dir), IRON, Enum.Material.Metal)
		local n = math.floor(len / 9)
		for s = 0, n - 1 do
			local p = mid + dir * (-len / 2 + 4.5 + s * 9) - Vector3.new(0, 0.6, 0)
			if p.X > X0 + 2 and p.X < X1 - 2 and p.Z > ZB + 2 and p.Z < ZF - 2 then
				local spot = deco(Vector3.new(0.9, 0.9, 0.9), CFrame.new(p) * CFrame.Angles(math.rad(-20), 0, 0), IRON, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
				if (s + t) % 4 == 0 and lit < 14 then
					lit += 1
					local l = Instance.new("SpotLight")
					l.Face = Enum.NormalId.Bottom
					l.Angle = 50
					l.Range = 26
					l.Brightness = 1.4
					l.Color = WARM
					l.Parent = spot
				end
			end
		end
	end
	-- the back wall: warm wood slats and gold letters
	local wz = ZB + 0.9
	local wy0, wy1 = 2.5, ROOF - 1
	local width = X1 - X0 - 2
	local cx = (X0 + X1) / 2
	part(Vector3.new(width, wy1 - wy0, 0.3), CFrame.new(cx, (wy0 + wy1) / 2, wz), WOOD, Enum.Material.Wood)
	for s = 0, math.floor(width / 2.2) do
		deco(Vector3.new(0.22, wy1 - wy0, 0.12), CFrame.new(X0 + 1 + s * 2.2, (wy0 + wy1) / 2, wz + 0.2), WOOD_DARK, Enum.Material.Wood)
	end
	local sign = deco(Vector3.new(40, 4, 0.2), CFrame.new(cx, 17, wz + 0.4), WOOD, Enum.Material.Wood, { Transparency = 1 })
	letters(sign, "LEGENDS MOTORS", GOLD, Enum.NormalId.Back, 1.2)
	-- beige floor-length curtains along the left wall, in folds
	for c = 0, 13 do
		local z = ZB + 8 + c * 4.2
		if z < ZF - 6 then
			deco(Vector3.new(0.5, wy1 - wy0, 2.2), CFrame.new(X0 + 2.2 + (c % 2) * 0.35, (wy0 + wy1) / 2, z), CURTAIN:Lerp(Color3.new(0, 0, 0), (c % 2) * 0.08), Enum.Material.Fabric)
			deco(Vector3.new(0.5, wy1 - wy0, 2.2), CFrame.new(X0 + 2.2 + ((c + 1) % 2) * 0.35, (wy0 + wy1) / 2, z + 2.1), CURTAIN, Enum.Material.Fabric)
		end
	end
end

---------------------------------------------------------------------
-- The street in front
---------------------------------------------------------------------
local function street()
	local riviera = workspace:FindFirstChild("Riviera")
	local dressing = riviera and riviera:FindFirstChild("Dressing")
	local function take(name: string): Model?
		local m = dressing and dressing:FindFirstChild(name, true)
		return if m and m:IsA("Model") then m:Clone() else nil
	end
	local paveZ0, paveZ1 = ZF + 4, ZF + 9
	local cx = (X0 + X1) / 2
	-- light stone paving with a darker border
	part(Vector3.new(X1 - X0 + 12, 0.15, paveZ1 - paveZ0), CFrame.new(cx, 2.0, (paveZ0 + paveZ1) / 2), Color3.fromRGB(214, 204, 186), Enum.Material.Pavement)
	deco(Vector3.new(X1 - X0 + 12, 0.16, 0.6), CFrame.new(cx, 2.01, paveZ1), Color3.fromRGB(150, 140, 126), Enum.Material.Pavement)
	-- steel bollards with red bands along the edge (not in front of the doors)
	for bx = X0 + 4, X1 - 2, 9 do
		if bx < -2 or bx > 22 then
			local m = take("BollardBlack")
			if m then
				m:PivotTo(CFrame.new(bx, 2.05 + m:GetExtentsSize().Y / 2, paveZ1 - 0.6))
				m.Parent = folder
			else
				part(Vector3.new(0.8, 3.6, 0.8), CFrame.new(bx, 3.85, paveZ1 - 0.6), Color3.fromRGB(150, 152, 156), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
			end
			deco(Vector3.new(0.86, 0.35, 0.86), CFrame.new(bx, 5.1, paveZ1 - 0.6), Color3.fromRGB(196, 30, 36), Enum.Material.SmoothPlastic)
		end
	end
	-- white stone cubes by the door
	for _, sx in { -6, -2.5, 23, 26.5 } do
		part(Vector3.new(2.6, 2.4, 2.6), CFrame.new(sx, 3.2, paveZ0 + 1.4), Color3.fromRGB(240, 238, 232), Enum.Material.Marble)
	end
	-- wooden-slat planters with palms at the corners
	for _, px in { X0 + 7, X1 - 7 } do
		part(Vector3.new(9, 2.6, 4), CFrame.new(px, 3.3, (paveZ0 + paveZ1) / 2), Color3.fromRGB(140, 96, 60), Enum.Material.WoodPlanks)
		local palm = take("Palm")
		if palm then
			local s = palm:GetExtentsSize()
			palm:ScaleTo(palm:GetScale() * (22 / s.Y))
			palm:PivotTo(CFrame.new(px, 4.6 + palm:GetExtentsSize().Y / 2, (paveZ0 + paveZ1) / 2))
			palm.Parent = folder
		end
	end
end

---------------------------------------------------------------------
-- Recolours (remembered for undo)
---------------------------------------------------------------------
local function recolour(body: Model)
	for _, d in body:GetDescendants() do
		if d:IsA("BasePart") and not d:IsDescendantOf(folder) and d.Parent and d.Parent.Name ~= "Markers" then
			local c = d.Color
			local key = string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
			local s = d.Size
			if d.Material == Enum.Material.Marble and key == "226,221,212" and math.max(s.X, s.Z) > 60 then
				restyle(d, TERRAZZO, Enum.Material.Marble, 0.16) -- the floor: pale terrazzo
			elseif d.Material == Enum.Material.Metal and key == "58,60,64" and math.max(s.X, s.Z) > 40 then
				restyle(d, CEILING, Enum.Material.SmoothPlastic, 0) -- the roof plates: a white ceiling
			elseif key == "44,46,52" and s.Y > 12 then
				-- the outside walls: light stone; the glass fronts' frames (unions on the front) dark bronze
				if d:IsA("UnionOperation") and math.abs(d.Position.Z - ZF) < 2 then
					restyle(d, Color3.fromRGB(34, 32, 30), nil, nil)
				else
					restyle(d, STONE_LIGHT, Enum.Material.Limestone, 0)
				end
			end
			-- the old SIGN boxes on the side (their text is on the band now)
			if d.Name == "SignFace" or d.Name == "SignFrame" then
				if d:GetAttribute("OrigTransparency") == nil then
					d:SetAttribute("OrigTransparency", d.Transparency)
				end
				d.Transparency = 1
				if d:GetAttribute("Text") ~= nil then
					d:SetAttribute("OrigText", d:GetAttribute("Text"))
					d:SetAttribute("Text", nil)
				end
			end
		end
	end
	-- the indoor display spots at angles (owner's photo: cars parked close, noses out, angled)
	local markers = body:FindFirstChild("Markers")
	if markers and not body:GetAttribute("SpotsAngled") then
		body:SetAttribute("SpotsAngled", true)
		for _, m in markers:GetChildren() do
			if m:IsA("BasePart") and m.Name == "Indoor" then
				local i = (m:GetAttribute("Index") :: number?) or 1
				m.CFrame = m.CFrame * CFrame.Angles(0, math.rad(if i % 2 == 1 then 24 else -24), 0)
			end
		end
	end
end

function M.run(body: Model)
	local old = body:FindFirstChild("Remodel")
	if old then
		old:Destroy()
	end
	folder = Instance.new("Model")
	folder.Name = "Remodel"
	folder.Parent = body
	upperBlock()
	showroomFront()
	interior()
	street()
	recolour(body)
	body:SetAttribute("Remodel", "2026-11-03")
	local n = 0
	for _, d in body:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

function M.undo(body: Model)
	local old = body:FindFirstChild("Remodel")
	if old then
		old:Destroy()
	end
	for _, d in body:GetDescendants() do
		if d:IsA("BasePart") then
			local c = d:GetAttribute("OrigColor")
			if typeof(c) == "Color3" then
				d.Color = c
				d.Material = (Enum.Material :: any)[d:GetAttribute("OrigMaterial")]
				d.Reflectance = d:GetAttribute("OrigReflectance") :: number
				d:SetAttribute("OrigColor", nil)
				d:SetAttribute("OrigMaterial", nil)
				d:SetAttribute("OrigReflectance", nil)
			end
			local txt = d:GetAttribute("OrigText")
			if txt ~= nil then
				d:SetAttribute("Text", txt)
				d:SetAttribute("OrigText", nil)
			end
			local t = d:GetAttribute("OrigTransparency")
			if type(t) == "number" then
				d.Transparency = t
				d:SetAttribute("OrigTransparency", nil)
			end
		end
	end
end

return M
