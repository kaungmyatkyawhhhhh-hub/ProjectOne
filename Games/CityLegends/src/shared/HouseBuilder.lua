--[[
	HouseBuilder (shared)
	Builds a house blueprint (Config.Houses.Designs) on a lot: the real house on the server, a
	see-through ghost on the client before you claim a lot, and the turning preview in the Legends
	Realty catalogue. The same code everywhere, so what you preview is what you get.

	A lot's frame looks out of its front (towards its road or driveway): local -Z is the front,
	+Z the back. The house stands towards the back of the lot with a front yard; the garage is in
	the front of the ground floor on small houses, a wing beside the house on bigger ones (or in
	front of it when the lot is too narrow), with its doors facing the driveway. Each design's
	`look` picks the footprint, colours, roof and extras (porch, balcony, pool, fountain, tower...).

	Housing Part 5 (owner, 2026-10-29: "every house is a real house you walk into"):
	  * a front door that opens (and a door from the garage into the house), stairs up to every
	    floor through a stairwell, a rail round the stairwell
	  * furnished rooms: kitchen (fridge, stove, sink, island and stools), living room (sofa, TV,
	    rug, coffee table), dining table, fireplace on the bigger houses, bedrooms (bed, nightstands,
	    wardrobe), a bathroom (shower, sink, a bath on Mid and High), curtains on Mid and High, a
	    gym or a cinema on the third floor of the big ones, a light switch on every floor
	  * a fence or wall round the lot with a gate where the drive comes in: Low a picket front and
	    hedges (an open drive), Mid a rendered wall with a sliding steel gate between lamp pillars,
	    High a stone wall with big iron gates that swing open between lantern pillars and the
	    house's name on the wall
	Things you can use carry a ProximityPrompt with a "Use" attribute (door, light, tv, tap,
	shower, stove, fridge, fireplace, curtain, bed, wardrobe); Houses.lua makes them work.

	HouseBuilder.build(design, lotFrame, lotWidth, lotDepth, opts) -> (Model, info)
	  opts.ghost: see-through, no collisions (the claim preview)
	  opts.interior: build the rooms and the prompts (the real house; not the ghost or preview)
	  info.bays: a CFrame per garage bay (where a car stands, facing out of its door)
	  info.drive: CFrames of the driveway spots for show cars
	  info.door: just outside the front door, facing in; info.mailbox: by the gate, outside
	  info.spawn: where a car driven out of the garage appears (on the driveway, facing the road)
	  info.gates: the gate leaves ({ part, closed, open }) and info.gateAt where they are
]]

local HouseBuilder = {}

-- a ready-made house body (owner, 2026-10-30: "import some houses from the toolbox to get better
-- quality"): Creator Store houses kept in ReplicatedStorage.HouseBodies, cleaned (no scripts, no
-- brand names), facing -Z with their pivot at the bottom middle, FootW / FootD / Height attributes,
-- and door panels marked BodyDoor (HingeSide -1 / 1). A design with look.body uses one in place of
-- the walls, rooms and roof built here; the lot, garage, drive, fence, gate and mailbox stay ours.
-- (None in the Lune tests: the house is then built the usual way.)
local function bodyTemplate(name: string?): Model?
	if not name then
		return nil
	end
	local ok, found = pcall(function()
		local folder = (game :: any):GetService("ReplicatedStorage"):FindFirstChild("HouseBodies")
		return if folder then folder:FindFirstChild(name) else nil
	end)
	return if ok and found and found:IsA("Model") then found else nil
end

-- see-through and not solid, like the rest of the ghost
local function ghostify(m: Instance)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = math.max(d.Transparency, 0.55)
			d.CanCollide = false
			d.CanQuery = false
			d.CastShadow = false
			d.Material = Enum.Material.SmoothPlastic
		elseif d:IsA("Light") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
end

local FLOOR = 11 -- storey height
local BAY_W = 11 -- garage bay width
local BAY_D = 20 -- garage bay depth
local STEP_RISE = 1 -- stairs: 11 steps a floor
local STEP_RUN = 1.5
local STAIR_W = 5
local RUN = FLOOR / STEP_RISE * STEP_RUN -- 16.5: the length of one flight
local SILL, HEAD = 2.5, 8.6 -- the window band
local DOOR_W = 5.2

local WINDOW = Color3.fromRGB(70, 92, 110)
local WARM = Color3.fromRGB(255, 214, 160)
local LAWN = Color3.fromRGB(64, 112, 52)
local PAVERS = Color3.fromRGB(196, 190, 178)
local WATER = Color3.fromRGB(40, 170, 215)
local DARK = Color3.fromRGB(32, 32, 36)
local HEDGE = Color3.fromRGB(46, 92, 46)
local IRON = Color3.fromRGB(28, 29, 32)
local STONE = Color3.fromRGB(176, 168, 152)
local SOFA = Color3.fromRGB(96, 98, 104)
local OAK = Color3.fromRGB(150, 112, 76)
local COUNTER = Color3.fromRGB(232, 230, 224)
local CABINET = Color3.fromRGB(64, 66, 72)
local LINEN = Color3.fromRGB(238, 234, 226)
local STEEL = Color3.fromRGB(196, 198, 202)
local CURTAIN = Color3.fromRGB(214, 204, 186)

export type Gate = { part: BasePart, closed: CFrame, open: CFrame }
export type Info = {
	bays: { CFrame },
	drive: { CFrame },
	door: CFrame,
	mailbox: CFrame,
	spawn: CFrame,
	size: Vector3,
	gates: { Gate },
	gateAt: CFrame?,
	-- boxes of ground to clear for an underground garage (the server digs them out of the terrain)
	dig: { { cf: CFrame, size: Vector3 } },
}

-- the underground garage on High lots (owner, 2026-10-30: "make the garage under ground"):
-- a ramp UG_RUN long down the lot's left side from just inside the gate, to a basement hall
-- UG_DEEP below the lot with the cars on show in two rows beside its aisle
local UG_W = 14
local UG_DEEP = 9.5
local UG_RUN = 50
local UG_APRON = 14

-- a part maker bound to one model (ghost: see-through and not solid)
local function maker(model: Model, ghost: boolean)
	return function(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, opts: { [string]: any }?): BasePart
		local o = opts or {}
		local p: BasePart
		if o.wedge then
			p = Instance.new("WedgePart")
		elseif o.corner then
			p = Instance.new("CornerWedgePart")
		elseif o.seat and not ghost then
			p = Instance.new("Seat")
		else
			local part = Instance.new("Part")
			if o.shape then
				part.Shape = o.shape
			end
			p = part
		end
		p.Name = o.name or "Part"
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Transparency = o.transparency or 0
		p.CastShadow = o.shadow ~= false
		p.CanCollide = o.collide ~= false
		p.CanTouch = false
		if ghost then
			p.Transparency = math.max(p.Transparency, 0.55)
			p.CanCollide = false
			p.CanQuery = false
			p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic
		end
		p.Parent = o.parent or model
		return p
	end
end

-- something you can use: a prompt with a "Use" kind (Houses.lua answers it)
local function use(part: Instance, kind: string, action: string, object: string, dist: number?)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Use"
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = dist or 8
	p.RequiresLineOfSight = false
	p:SetAttribute("Use", kind)
	p.Parent = part
	return p
end

-- a gable (or A-frame) roof over a box of width w (along X) and depth d, ridge along X
local function gable(mk: any, base: CFrame, w: number, d: number, rise: number, color: Color3, overhang: number)
	local half = d / 2 + overhang
	for _, s in { -1, 1 } do
		-- a wedge's slope runs from its top-back edge down to its front-bottom edge
		mk(Vector3.new(w + overhang * 2, rise, half), base * CFrame.new(0, rise / 2, s * half / 2) * CFrame.Angles(0, if s > 0 then 0 else math.pi, 0), color, Enum.Material.Slate, { wedge = true })
	end
end

-- a hip roof: a gable whose ends slope in too (end pieces as corner wedges)
local function hip(mk: any, base: CFrame, w: number, d: number, rise: number, color: Color3, overhang: number)
	local half = d / 2 + overhang
	local inset = math.min(half, w / 2)
	local ridge = math.max(0.5, w + overhang * 2 - inset * 2)
	for _, s in { -1, 1 } do
		mk(Vector3.new(ridge, rise, half), base * CFrame.new(0, rise / 2, s * half / 2) * CFrame.Angles(0, if s > 0 then 0 else math.pi, 0), color, Enum.Material.Slate, { wedge = true })
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x = sx * (ridge / 2 + inset / 2)
			local z = sz * half / 2
			-- a corner wedge: its high corner points at the ridge's end
			local turn = if sx > 0 and sz > 0 then 0 elseif sx < 0 and sz > 0 then math.pi / 2 elseif sx < 0 and sz < 0 then math.pi else -math.pi / 2
			mk(Vector3.new(inset, rise, half), base * CFrame.new(x, rise / 2, z) * CFrame.Angles(0, turn + math.pi, 0), color, Enum.Material.Slate, { corner = true })
		end
	end
end

-- a flat slab of size w x d at cf, with an optional rectangular hole (local x0..x1, z0..z1)
local function plate(mk: any, cf: CFrame, w: number, d: number, thick: number, color: Color3, material: Enum.Material, hole: { number }?, parent: Instance?)
	local function rect(x0: number, x1: number, z0: number, z1: number)
		if x1 - x0 > 0.05 and z1 - z0 > 0.05 then
			mk(Vector3.new(x1 - x0, thick, z1 - z0), cf * CFrame.new((x0 + x1) / 2, 0, (z0 + z1) / 2), color, material, { parent = parent })
		end
	end
	if not hole then
		rect(-w / 2, w / 2, -d / 2, d / 2)
		return
	end
	local hx0, hx1 = math.max(-w / 2, hole[1]), math.min(w / 2, hole[2])
	local hz0, hz1 = math.max(-d / 2, hole[3]), math.min(d / 2, hole[4])
	rect(-w / 2, hx0, -d / 2, d / 2)
	rect(hx1, w / 2, -d / 2, d / 2)
	rect(hx0, hx1, -d / 2, hz0)
	rect(hx0, hx1, hz1, d / 2)
end

-- a door leaf in a wall frame `at` (local +Z is inside), hinged at its left edge, swinging in
local function door(mk: any, at: CFrame, x: number, color: Color3, interior: boolean, parent: Instance?, label: string)
	local leafCF = at * CFrame.new(x, HEAD / 2 + 0.05, 0)
	local leaf = mk(Vector3.new(DOOR_W - 0.5, HEAD - 0.1, 0.3), leafCF, color, Enum.Material.Wood, { name = "Door", parent = parent })
	if not interior then
		return
	end
	local hinge = at * CFrame.new(x - DOOR_W / 2 + 0.25, HEAD / 2 + 0.05, 0)
	local open = hinge * CFrame.Angles(0, -math.pi / 2, 0) * hinge:ToObjectSpace(leafCF)
	leaf:SetAttribute("ClosedCF", leafCF)
	leaf:SetAttribute("OpenCF", open)
	-- a handle
	mk(Vector3.new(0.3, 0.3, 0.7), leafCF * CFrame.new(DOOR_W / 2 - 1, -0.4, 0), STEEL, Enum.Material.Metal, { collide = false, name = "Handle", parent = parent })
	use(leaf, "door", "Open", label, 9)
end

-- one wall with its band of windows; doorAt (local x) puts a door in the pane nearest it.
-- Returns the door's local x (nil without a door).
local function wall(mk: any, len: number, at: CFrame, look: any, glassy: boolean, doorAt: number?, interior: boolean, parent: Instance?, doorLabel: string?): number?
	local wallC = look.wall
	local t = 1
	local pier = if glassy then 0.5 else 1.6
	local panes = math.max(1, math.floor(len / (if glassy then 9 else 7)))
	if doorAt then
		-- (a wall with a door gets panes wide enough for it)
		panes = math.max(1, math.min(panes, math.floor((len - pier) / (DOOR_W + 0.8 + pier))))
	end
	local pane = (len - pier * (panes + 1)) / panes
	local doorK: number? = nil
	if doorAt then
		local best = math.huge
		for k = 1, panes do
			local x = -len / 2 + pier + (k - 0.5) * pane + (k - 1) * pier
			if math.abs(x - doorAt) < best and pane >= DOOR_W + 0.4 then
				best = math.abs(x - doorAt)
				doorK = k
			end
		end
	end
	local doorX: number? = if doorK then -len / 2 + pier + (doorK - 0.5) * pane + (doorK - 1) * pier else nil
	-- solid below the windows (split round the door), and above them
	if doorX then
		local a, b = doorX - DOOR_W / 2, doorX + DOOR_W / 2
		mk(Vector3.new(a + len / 2, SILL, t), at * CFrame.new((-len / 2 + a) / 2, SILL / 2, 0), wallC, Enum.Material.Concrete, { parent = parent })
		mk(Vector3.new(len / 2 - b, SILL, t), at * CFrame.new((b + len / 2) / 2, SILL / 2, 0), wallC, Enum.Material.Concrete, { parent = parent })
	else
		mk(Vector3.new(len, SILL, t), at * CFrame.new(0, SILL / 2, 0), wallC, Enum.Material.Concrete, { parent = parent })
	end
	mk(Vector3.new(len, FLOOR - HEAD, t), at * CFrame.new(0, (HEAD + FLOOR) / 2, 0), wallC, Enum.Material.Concrete, { parent = parent })
	for k = 0, panes do
		local x = -len / 2 + pier / 2 + k * (pane + pier)
		mk(Vector3.new(pier, HEAD - SILL, t), at * CFrame.new(x, (SILL + HEAD) / 2, 0), if glassy then look.trim else wallC, Enum.Material.Concrete, { parent = parent })
	end
	for k = 1, panes do
		local x = -len / 2 + pier + (k - 0.5) * pane + (k - 1) * pier
		if k == doorK then
			-- the door's frame, glass either side of it, and the door
			for _, s in { -1, 1 } do
				mk(Vector3.new(0.4, HEAD, t + 0.2), at * CFrame.new(x + s * DOOR_W / 2, HEAD / 2, 0), look.trim, Enum.Material.Wood, { parent = parent })
				local gw = (pane - DOOR_W) / 2 - 0.1
				if gw > 0.2 then
					mk(Vector3.new(gw, HEAD - SILL, t * 0.4), at * CFrame.new(x + s * (DOOR_W / 2 + 0.2 + gw / 2), (SILL + HEAD) / 2, 0), WINDOW, Enum.Material.Glass, { transparency = 0.35, parent = parent })
				end
			end
			door(mk, at, x, look.trim, interior, parent, doorLabel or "Door")
		else
			mk(Vector3.new(pane, HEAD - SILL, t * 0.4), at * CFrame.new(x, (SILL + HEAD) / 2, 0), WINDOW, Enum.Material.Glass, { transparency = 0.35, parent = parent })
		end
	end
	return doorX
end

-- a storey: four walls (doors where asked), its floor (with the stairwell's hole) and a ceiling
-- light. doors.front / doors.left are local x / z positions; returns where they went
local function storey(mk: any, cf: CFrame, w: number, d: number, look: any, glassy: boolean, doors: { front: number?, left: number? }, hole: { number }?, interior: boolean, parent: Instance?): { front: number?, left: number? }
	local out = {}
	out.front = wall(mk, w, cf * CFrame.new(0, 0, -d / 2 + 0.5), look, glassy, doors.front, interior, parent, "Front door")
	wall(mk, w, cf * CFrame.new(0, 0, d / 2 - 0.5) * CFrame.Angles(0, math.pi, 0), look, glassy, nil, interior, parent)
	-- the left wall's local x runs along -Z of the storey (its +Z faces in)
	local left = wall(mk, d - 2, cf * CFrame.new(-w / 2 + 0.5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), look, glassy, if doors.left then -doors.left else nil, interior, parent, "Garage door")
	out.left = if left then -left else nil
	wall(mk, d - 2, cf * CFrame.new(w / 2 - 0.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), look, glassy, nil, interior, parent)
	plate(mk, cf * CFrame.new(0, 0.3, 0), w - 1, d - 1, 0.6, Color3.fromRGB(206, 196, 180), Enum.Material.WoodPlanks, hole, parent)
	local lamp = mk(Vector3.new(1.4, 0.2, 1.4), cf * CFrame.new(0, FLOOR - 0.6, 0), WARM, Enum.Material.Neon, { collide = false, shadow = false, name = "CeilingLight", parent = parent })
	local light = Instance.new("PointLight")
	light.Color = WARM
	light.Range = math.min(40, math.max(w, d) * 0.7)
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = lamp
	return out
end

local function palm(mk: any, base: CFrame, h: number)
	for k = 0, 3 do
		mk(Vector3.new(1.2 - k * 0.15, h / 4 + 0.2, 1.2 - k * 0.15), base * CFrame.new(k * 0.25, h / 8 + k * h / 4, 0) * CFrame.Angles(0, 0, -0.06), Color3.fromRGB(122, 96, 70), Enum.Material.Wood)
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		mk(Vector3.new(0.4, 0.3, 7), base * CFrame.new(1, h, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(-22), 0, 0) * CFrame.new(0, 0, -3.2), Color3.fromRGB(56, 112, 52), Enum.Material.Grass, { collide = false })
	end
end

---------------------------------------------------------------------
-- Inside: the rooms (only on the real house)
---------------------------------------------------------------------
-- a TV on a wall: a dark frame and a screen that Houses turns on (HouseClient moves its picture)
local function tvPicture(screen: BasePart, face: Enum.NormalId)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.CanvasSize = Vector2.new(320, 180)
	sg.LightInfluence = 0
	sg.MaxDistance = 90
	sg.Parent = screen
	local pic = Instance.new("Frame")
	pic.Name = "Picture"
	pic.Size = UDim2.fromScale(1, 1)
	pic.BorderSizePixel = 0
	pic.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	pic.Visible = false
	pic.Parent = sg
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 60, 140)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 120, 80)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 190, 110)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 70)),
	})
	g.Parent = pic
	local cap = Instance.new("TextLabel")
	cap.BackgroundTransparency = 1
	cap.Size = UDim2.new(1, 0, 0.22, 0)
	cap.Position = UDim2.fromScale(0, 0.74)
	cap.Text = "LEGENDS TV  ·  NIGHT DRIVE"
	cap.TextColor3 = Color3.fromRGB(255, 255, 255)
	cap.Font = Enum.Font.GothamBlack
	cap.TextScaled = true
	cap.Parent = pic
	screen:AddTag("HouseTV")
	use(screen, "tv", "Turn on", "TV", 14)
end

local function tv(mk: any, cf: CFrame, w: number, parent: Instance)
	mk(Vector3.new(w + 0.4, w * 0.58 + 0.4, 0.3), cf, DARK, Enum.Material.SmoothPlastic, { parent = parent })
	local screen = mk(Vector3.new(w, w * 0.58, 0.1), cf * CFrame.new(0, 0, -0.2), Color3.fromRGB(10, 12, 16), Enum.Material.Glass, { name = "TVScreen", parent = parent })
	tvPicture(screen, Enum.NormalId.Front)
end

-- water from a tap or a shower head (off until used)
local function water(part: BasePart, spread: number, rate: number)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Water"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(190, 225, 255))
	e.LightEmission = 0.3
	e.Size = NumberSequence.new(0.12)
	e.Transparency = NumberSequence.new(0.2, 0.8)
	e.Speed = NumberRange.new(10, 14)
	e.Acceleration = Vector3.new(0, -60, 0)
	e.Lifetime = NumberRange.new(0.25, 0.4)
	e.SpreadAngle = Vector2.new(spread, spread)
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Rate = rate
	e.Enabled = false
	e.Parent = part
end

-- the floor's light switch (all its lights)
local function switch(mk: any, cf: CFrame, parent: Instance)
	local s = mk(Vector3.new(0.6, 0.9, 0.15), cf, Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, { collide = false, name = "LightSwitch", parent = parent })
	use(s, "light", "Lights", "Light switch", 7)
end

local function chair(mk: any, cf: CFrame, color: Color3, parent: Instance)
	-- a Seat you can sit on, its back behind it (cf faces the way you sit)
	mk(Vector3.new(2, 0.4, 2), cf * CFrame.new(0, 1.8, 0), color, Enum.Material.Fabric, { seat = true, name = "Chair", parent = parent })
	mk(Vector3.new(2, 2.2, 0.3), cf * CFrame.new(0, 3, 0.9), color, Enum.Material.Fabric, { parent = parent })
	mk(Vector3.new(0.3, 1.6, 0.3), cf * CFrame.new(0, 0.8, 0), DARK, Enum.Material.Metal, { parent = parent })
end

-- the rooms of one storey. cf: the storey's floor level, w x d inside it; s: the stairs' side
-- (they run along the back wall there); role: "ground", "upper", "third", "fourth", "single"
local function furnish(mk: any, cf: CFrame, w: number, d: number, s: number, role: string, design: any, look: any, parent: Instance, stairs: boolean)
	local fs = -s -- the free side, away from the stairs
	local y = 0.6 -- the floor's top, from the storey's base
	local base = cf * CFrame.new(0, y, 0)
	local tier = design.tier
	local accent = look.accent or OAK
	local compact = d < 18
	-- the light switch: by the front door on the ground, at the top of the stairs above
	if role == "ground" or role == "single" then
		switch(mk, base * CFrame.new(fs * 3.6, 4.5, -d / 2 + 1.1), parent)
	else
		switch(mk, base * CFrame.new(s * (w / 2 - 1 - RUN - 1.2), 4.5, d / 2 - 1.1) * CFrame.Angles(0, math.pi, 0), parent)
	end
	local backZ = d / 2 - 1 -- the back wall's inner face
	local frontZ = -d / 2 + 1

	local function kitchen()
		-- cabinets along the back wall on the free side, the fridge at the end
		local x0, x1 = fs * 3, fs * (w / 2 - 4.5)
		local len = math.abs(x1 - x0)
		local cx = (x0 + x1) / 2
		mk(Vector3.new(len, 3.1, 2.6), base * CFrame.new(cx, 1.55, backZ - 1.3), CABINET, Enum.Material.Wood, { parent = parent })
		mk(Vector3.new(len, 0.3, 2.8), base * CFrame.new(cx, 3.25, backZ - 1.4), COUNTER, Enum.Material.Marble, { parent = parent })
		mk(Vector3.new(len, 2.6, 1.4), base * CFrame.new(cx, 7.4, backZ - 0.7), CABINET, Enum.Material.Wood, { parent = parent })
		-- the stove (its rings glow when it's on) and the sink with a tap
		local sx = x0 + (x1 - x0) * 0.3
		local stove = mk(Vector3.new(2.6, 0.1, 2), base * CFrame.new(sx, 3.45, backZ - 1.4), Color3.fromRGB(20, 20, 22), Enum.Material.Glass, { name = "Stove", parent = parent })
		use(stove, "stove", "Turn on", "Stove")
		local kx = x0 + (x1 - x0) * 0.72
		mk(Vector3.new(2.4, 0.15, 1.6), base * CFrame.new(kx, 3.42, backZ - 1.4), STEEL, Enum.Material.Metal, { parent = parent })
		local tap = mk(Vector3.new(0.3, 1.2, 0.3), base * CFrame.new(kx, 4, backZ - 0.5), STEEL, Enum.Material.Metal, { name = "Tap", parent = parent })
		water(tap, 4, 60)
		use(tap, "tap", "Tap on", "Kitchen sink")
		-- the fridge
		local fz = backZ - 1.5
		local fx = fs * (w / 2 - 2.6)
		mk(Vector3.new(3, 7.6, 3), base * CFrame.new(fx, 3.8, fz), STEEL, Enum.Material.Metal, { parent = parent })
		local fd = mk(Vector3.new(2.9, 7.4, 0.25), base * CFrame.new(fx, 3.8, fz - 1.6), Color3.fromRGB(214, 216, 220), Enum.Material.Metal, { name = "FridgeDoor", parent = parent })
		local hingeSide = fs
		local hinge = base * CFrame.new(fx + hingeSide * 1.45, 3.8, fz - 1.6)
		fd:SetAttribute("ClosedCF", fd.CFrame)
		fd:SetAttribute("OpenCF", hinge * CFrame.Angles(0, hingeSide * math.pi * 0.55, 0) * hinge:ToObjectSpace(fd.CFrame))
		use(fd, "fridge", "Open", "Fridge")
		-- the island and two stools
		if not compact then
			local iw = math.min(10, len)
			mk(Vector3.new(iw, 3.2, 3), base * CFrame.new(cx, 1.6, backZ - 8), CABINET, Enum.Material.Wood, { parent = parent })
			mk(Vector3.new(iw + 0.6, 0.3, 3.6), base * CFrame.new(cx, 3.35, backZ - 8), COUNTER, Enum.Material.Marble, { parent = parent })
			for _, k in { -0.25, 0.25 } do
				chair(mk, base * CFrame.new(cx + k * iw, 0.6, backZ - 10.6) * CFrame.Angles(0, math.pi, 0), DARK, parent)
			end
		end
	end

	local function living()
		-- the sofa faces the TV on the free side wall; a rug and a low table between
		local tvX = fs * (w / 2 - 1.3)
		local z = if compact then frontZ + 3 else -d / 4
		local sofaX = fs * math.max(3.5, w / 2 - 13)
		local face = CFrame.Angles(0, fs * math.pi / 2, 0) -- looking at the TV
		local sofa = base * CFrame.new(sofaX, 0, z) * face
		mk(Vector3.new(8, 1.6, 3), sofa * CFrame.new(0, 1.2, 0), SOFA, Enum.Material.Fabric, { seat = true, name = "Sofa", parent = parent })
		mk(Vector3.new(8, 2.4, 0.8), sofa * CFrame.new(0, 2.2, 1.5), SOFA, Enum.Material.Fabric, { parent = parent })
		for _, a in { -1, 1 } do
			mk(Vector3.new(0.8, 2, 3), sofa * CFrame.new(a * 4.2, 1.4, 0), SOFA, Enum.Material.Fabric, { parent = parent })
		end
		local mid = (sofaX + tvX) / 2
		mk(Vector3.new(math.abs(tvX - sofaX) - 2, 0.1, 9), base * CFrame.new(mid, 0.05, z), accent:Lerp(Color3.new(1, 1, 1), 0.55), Enum.Material.Fabric, { collide = false, parent = parent })
		mk(Vector3.new(2.6, 1.2, 4.4), base * CFrame.new(mid, 0.6, z), OAK, Enum.Material.Wood, { parent = parent })
		tv(mk, base * CFrame.new(tvX, 5, z) * CFrame.Angles(0, -fs * math.pi / 2, 0), if tier == 2 then 7 else 5, parent)
	end

	local function dining()
		local cx = s * math.min(w / 4 + 1, w / 2 - 8)
		local z = -d / 4 + 1
		mk(Vector3.new(7, 0.3, 3.6), base * CFrame.new(cx, 3, z), OAK, Enum.Material.Wood, { parent = parent })
		mk(Vector3.new(1, 2.8, 1), base * CFrame.new(cx, 1.45, z), DARK, Enum.Material.Metal, { parent = parent })
		for _, k in { -2, 2 } do
			chair(mk, base * CFrame.new(cx + k, 0, z - 2.6), accent, parent)
			chair(mk, base * CFrame.new(cx + k, 0, z + 2.6) * CFrame.Angles(0, math.pi, 0), accent, parent)
		end
		-- a pendant light over it
		mk(Vector3.new(2.4, 0.6, 2.4), base * CFrame.new(cx, FLOOR - 3, z), WARM, Enum.Material.Neon, { collide = false, shadow = false, name = "CeilingLight", parent = parent })
	end

	local function fireplace()
		local at = base * CFrame.new(s * (w / 2 - 1.8), 0, -d / 4 - 4) * CFrame.Angles(0, s * math.pi / 2, 0)
		mk(Vector3.new(7, 6, 1.6), at * CFrame.new(0, 3, 0), STONE, Enum.Material.Slate, { parent = parent })
		local box = mk(Vector3.new(3.6, 2.4, 1), at * CFrame.new(0, 1.6, -0.4), Color3.fromRGB(18, 16, 14), Enum.Material.Slate, { name = "Fireplace", parent = parent })
		local fire = Instance.new("Fire")
		fire.Heat = 4
		fire.Size = 3
		fire.Enabled = false
		fire.Parent = box
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 150, 70)
		glow.Range = 14
		glow.Brightness = 1.5
		glow.Enabled = false
		glow.Parent = box
		use(box, "fireplace", "Light the fire", "Fireplace")
	end

	local function bedroom(side: number, z: number)
		-- the bed's head against the back wall
		local bx = side * math.min(w / 4 + 1, w / 2 - 6)
		local bed = base * CFrame.new(bx, 0, z)
		mk(Vector3.new(6.4, 1.6, 8.6), bed * CFrame.new(0, 0.8, 0), OAK, Enum.Material.Wood, { parent = parent })
		local mattress = mk(Vector3.new(6, 1, 8), bed * CFrame.new(0, 2, -0.2), LINEN, Enum.Material.Fabric, { name = "Bed", parent = parent })
		mk(Vector3.new(6.6, 3.6, 0.6), bed * CFrame.new(0, 2.6, 4.2), accent, Enum.Material.Fabric, { parent = parent })
		mk(Vector3.new(5, 0.6, 1.4), bed * CFrame.new(0, 2.8, 3), Color3.fromRGB(250, 250, 248), Enum.Material.Fabric, { parent = parent })
		use(mattress, "bed", "Sleep", "Bed", 9)
		for _, k in { -1, 1 } do
			mk(Vector3.new(1.8, 2.2, 1.8), bed * CFrame.new(k * 4.4, 1.1, 3.2), OAK, Enum.Material.Wood, { parent = parent })
			local lamp = mk(Vector3.new(0.8, 1, 0.8), bed * CFrame.new(k * 4.4, 2.8, 3.2), WARM, Enum.Material.Neon, { collide = false, shadow = false, parent = parent })
			lamp.Name = "CeilingLight"
		end
	end

	local function wardrobe(z: number)
		local wx = fs * (w / 2 - 2.6)
		local wd = mk(Vector3.new(3, 8, 6), base * CFrame.new(wx, 4, z), OAK:Lerp(DARK, 0.4), Enum.Material.Wood, { name = "Wardrobe", parent = parent })
		use(wd, "wardrobe", "Change outfit", "Wardrobe")
	end

	local function bathroom()
		-- the front corner on the stairs' side, walled off with a doorway
		local x0 = s * (w / 2 - 1)
		local x1 = s * (w / 2 - 12)
		local z1 = frontZ + 11
		local wallC = look.wall:Lerp(Color3.new(1, 1, 1), 0.3)
		-- the wall along x (with a 4-stud doorway at its inner end) and the wall along z
		mk(Vector3.new(7, FLOOR - 0.6, 0.6), base * CFrame.new(x0 - s * 3.5, (FLOOR - 0.6) / 2, z1), wallC, Enum.Material.Plaster, { parent = parent })
		mk(Vector3.new(0.6, FLOOR - 0.6, 11), base * CFrame.new(x1, (FLOOR - 0.6) / 2, frontZ + 5.5), wallC, Enum.Material.Plaster, { parent = parent })
		mk(Vector3.new(11, 0.1, 10), base * CFrame.new((x0 + x1) / 2, 0.06, frontZ + 5.5), Color3.fromRGB(226, 228, 230), Enum.Material.Marble, { collide = false, parent = parent })
		-- the shower in the outer front corner: a tray, two glass sides, a head with water
		local sx, sz = x0 - s * 2.1, frontZ + 2.1
		mk(Vector3.new(4, 0.3, 4), base * CFrame.new(sx, 0.15, sz), Color3.fromRGB(240, 240, 240), Enum.Material.Marble, { parent = parent })
		mk(Vector3.new(0.2, 7, 4), base * CFrame.new(sx - s * 2, 3.5, sz), Color3.fromRGB(200, 225, 235), Enum.Material.Glass, { transparency = 0.6, parent = parent })
		mk(Vector3.new(2.2, 7, 0.2), base * CFrame.new(sx - s * 0.9, 3.5, sz + 2), Color3.fromRGB(200, 225, 235), Enum.Material.Glass, { transparency = 0.6, parent = parent })
		local head = mk(Vector3.new(1, 0.2, 1), base * CFrame.new(sx, 7.6, sz), STEEL, Enum.Material.Metal, { collide = false, name = "ShowerHead", parent = parent })
		water(head, 18, 140)
		use(head, "shower", "Shower on", "Shower", 9)
		-- the basin with a tap on the front wall
		local bx = x0 - s * 7.5
		mk(Vector3.new(3.6, 3, 1.8), base * CFrame.new(bx, 1.5, frontZ + 0.9), CABINET, Enum.Material.Wood, { parent = parent })
		mk(Vector3.new(2.4, 0.3, 1.4), base * CFrame.new(bx, 3.15, frontZ + 1), Color3.fromRGB(248, 248, 248), Enum.Material.Marble, { parent = parent })
		local btap = mk(Vector3.new(0.25, 0.9, 0.25), base * CFrame.new(bx, 3.6, frontZ + 0.4), STEEL, Enum.Material.Metal, { name = "Tap", parent = parent })
		water(btap, 4, 50)
		use(btap, "tap", "Tap on", "Basin")
		mk(Vector3.new(3, 4, 0.15), base * CFrame.new(bx, 5.6, frontZ + 0.1), Color3.fromRGB(200, 214, 220), Enum.Material.Glass, { parent = parent })
		-- a bath on the Mid and High houses
		if tier >= 1 then
			local tx = x0 - s * 2.4
			local tz = frontZ + 7.4
			mk(Vector3.new(4, 2.2, 6), base * CFrame.new(tx, 1.1, tz), Color3.fromRGB(248, 248, 246), Enum.Material.Marble, { parent = parent })
			local bw = mk(Vector3.new(3.2, 0.2, 5.2), base * CFrame.new(tx, 1.9, tz), WATER, Enum.Material.Glass, { transparency = 0.3, collide = false, name = "BathWater", parent = parent })
			bw.Transparency = 1
			local spout = mk(Vector3.new(0.3, 0.6, 0.6), base * CFrame.new(tx, 2.6, tz + 2.7), STEEL, Enum.Material.Metal, { name = "Tap", parent = parent })
			water(spout, 6, 80)
			use(spout, "bath", "Run a bath", "Bath")
		end
	end

	local function curtains()
		if tier < 1 then
			return
		end
		for _, k in { -1, 1 } do
			local c = mk(Vector3.new(w / 2 - 3, HEAD - SILL + 0.6, 0.2), base * CFrame.new(k * (w / 4), (SILL + HEAD) / 2 - 0.6, frontZ + 0.5), CURTAIN, Enum.Material.Fabric, { name = "Curtain", parent = parent })
			c.Transparency = 1
			c.CanCollide = false
			if k == 1 then
				use(c, "curtain", "Close curtains", "Curtains", 12)
			end
		end
	end

	local function gym()
		-- a treadmill and a bench you can sit on, weights on a rack
		local gx = fs * (w / 4)
		mk(Vector3.new(3, 0.8, 7), base * CFrame.new(gx, 0.4, -d / 4), DARK, Enum.Material.Metal, { parent = parent })
		mk(Vector3.new(2.6, 0.1, 6.4), base * CFrame.new(gx, 0.85, -d / 4), Color3.fromRGB(40, 40, 44), Enum.Material.Rubber, { seat = true, name = "Treadmill", parent = parent })
		mk(Vector3.new(3, 4, 0.4), base * CFrame.new(gx, 2.8, -d / 4 - 3.4), DARK, Enum.Material.Metal, { parent = parent })
		mk(Vector3.new(1.6, 1.8, 5), base * CFrame.new(gx + fs * 5, 0.9, -d / 4), DARK, Enum.Material.Metal, { seat = true, name = "WeightBench", parent = parent })
		mk(Vector3.new(4, 4, 1), base * CFrame.new(fs * (w / 2 - 2.5), 2, -d / 4 + 6), STEEL, Enum.Material.Metal, { parent = parent })
	end

	local function cinema()
		-- a big screen on the free side wall and two rows of recliners facing it
		tv(mk, base * CFrame.new(fs * (w / 2 - 1.3), 5.5, -d / 4) * CFrame.Angles(0, -fs * math.pi / 2, 0), 12, parent)
		for row = 0, 1 do
			for k = -1, 1 do
				local at = base * CFrame.new(fs * (w / 2 - 14 - row * 5), 0, -d / 4 + k * 3.4) * CFrame.Angles(0, fs * math.pi / 2, 0)
				mk(Vector3.new(2.8, 1.4, 2.8), at * CFrame.new(0, 1.2 + row * 0.6, 0), Color3.fromRGB(70, 30, 36), Enum.Material.Fabric, { seat = true, name = "Recliner", parent = parent })
				mk(Vector3.new(2.8, 2.6, 0.7), at * CFrame.new(0, 2.6 + row * 0.6, 1.3), Color3.fromRGB(70, 30, 36), Enum.Material.Fabric, { parent = parent })
				if row == 1 then
					mk(Vector3.new(3, 0.6, 3), at * CFrame.new(0, 0.3, 0), DARK, Enum.Material.Wood, { parent = parent })
				end
			end
		end
	end

	if role == "ground" then
		kitchen()
		living()
		if not compact then
			dining()
		end
		if not compact and (tier == 2 or look.roof == "gable" or look.roof == "barn" or look.roof == "aframe") and w >= 40 then
			fireplace()
		end
	elseif role == "single" then
		-- one floor: kitchen, living room, the bedroom at the back and the bathroom at the front
		kitchen()
		living()
		bedroom(s, backZ - 5)
		bathroom()
	elseif role == "third" and tier >= 1 then
		if tier == 2 then
			cinema()
		else
			gym()
		end
		bedroom(fs, backZ - 5)
		curtains()
	else
		-- a bedroom floor: the bed by the back wall on the free side, the wardrobe, the bathroom
		bedroom(fs, backZ - 5)
		wardrobe(-d / 4 + 1)
		bathroom()
		curtains()
	end
	local _ = stairs
end

-- a flight of stairs from a storey's floor up to the next, along the back wall on side s
-- (it starts by the side wall and climbs inwards); a rail along the stairwell above
local function stairsUp(mk: any, cf: CFrame, w: number, d: number, s: number, color: Color3, parent: Instance)
	local z = d / 2 - 1 - STAIR_W / 2
	local x0 = s * (w / 2 - 1)
	for i = 1, FLOOR / STEP_RISE do
		local h = i * STEP_RISE
		local x = x0 - s * (i - 0.5) * STEP_RUN
		mk(Vector3.new(STEP_RUN + 0.02, h, STAIR_W), cf * CFrame.new(x, 0.6 + h / 2, z), color, Enum.Material.WoodPlanks, { name = "Step", parent = parent })
	end
end

-- the stairwell's hole in a storey's floor (local coords of that storey), on side s
local function stairHole(w: number, d: number, s: number, shift: number): { number }
	local a = s * (w / 2 - 1) - shift
	local b = a - s * RUN
	return { math.min(a, b), math.max(a, b), d / 2 - 1 - STAIR_W, d / 2 }
end

local function stairRail(mk: any, cf: CFrame, w: number, d: number, s: number, shift: number, parent: Instance)
	local hole = stairHole(w, d, s, shift)
	local z = hole[3] - 0.2
	mk(Vector3.new(hole[2] - hole[1], 3.2, 0.3), cf * CFrame.new((hole[1] + hole[2]) / 2, 0.6 + 1.6, z), Color3.fromRGB(200, 220, 230), Enum.Material.Glass, { transparency = 0.4, name = "Rail", parent = parent })
	mk(Vector3.new(hole[2] - hole[1], 0.25, 0.4), cf * CFrame.new((hole[1] + hole[2]) / 2, 0.6 + 3.3, z), IRON, Enum.Material.Metal, { parent = parent })
end

---------------------------------------------------------------------
-- The lot's fence or wall, and its gate
---------------------------------------------------------------------
-- runs a fence along x at z from x0 to x1 (lot coords), leaving gaps; kind by tier
local function fenceRun(mk: any, lot: CFrame, tier: number, look: any, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	if len < 0.5 then
		return
	end
	local mid = (a + b) / 2
	local cf = lot * CFrame.lookAt(mid, b)
	if tier == 0 then
		mk(Vector3.new(2.4, 3.6, len), cf * CFrame.new(0, 1.8 + 0.4, 0), HEDGE, Enum.Material.LeafyGrass, { name = "Hedge" })
	elseif tier == 1 then
		mk(Vector3.new(1.2, 3.6, len), cf * CFrame.new(0, 1.8 + 0.4, 0), look.wall, Enum.Material.Plaster, { name = "LotWall" })
		mk(Vector3.new(1.6, 0.4, len + 0.4), cf * CFrame.new(0, 3.8 + 0.4, 0), look.trim, Enum.Material.Concrete)
	else
		mk(Vector3.new(1.6, 5, len), cf * CFrame.new(0, 2.5 + 0.4, 0), STONE, Enum.Material.Limestone, { name = "LotWall" })
		mk(Vector3.new(2, 0.5, len + 0.4), cf * CFrame.new(0, 5.15 + 0.4, 0), STONE:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Limestone)
	end
end

-- a white picket front for the Low houses (posts and two rails)
local function picket(mk: any, lot: CFrame, x0: number, x1: number, z: number)
	local len = x1 - x0
	if len < 1 then
		return
	end
	local cx = (x0 + x1) / 2
	for _, h in { 1.2, 2.6 } do
		mk(Vector3.new(len, 0.3, 0.2), lot * CFrame.new(cx, 0.4 + h, z), Color3.fromRGB(246, 246, 242), Enum.Material.Wood)
	end
	local n = math.max(1, math.floor(len / 2.4))
	for k = 0, n do
		mk(Vector3.new(0.35, 3.4, 0.35), lot * CFrame.new(x0 + k * len / n, 0.4 + 1.7, z), Color3.fromRGB(246, 246, 242), Enum.Material.Wood, { name = "Picket" })
	end
end

-- a pillar by a gate, with a lamp on Mid and a lantern on High
local function pillar(mk: any, at: CFrame, tier: number, look: any)
	if tier == 1 then
		mk(Vector3.new(2.4, 6, 2.4), at * CFrame.new(0, 3.4, 0), look.wall, Enum.Material.Plaster, { name = "GatePillar" })
		local lamp = mk(Vector3.new(1.2, 1.2, 1.2), at * CFrame.new(0, 7, 0), WARM, Enum.Material.Neon, { collide = false, shadow = false, name = "PillarLamp" })
		local l = Instance.new("PointLight")
		l.Color = WARM
		l.Range = 16
		l.Brightness = 1
		l.Parent = lamp
	else
		mk(Vector3.new(3.4, 8, 3.4), at * CFrame.new(0, 4.4, 0), STONE, Enum.Material.Limestone, { name = "GatePillar" })
		mk(Vector3.new(4, 0.8, 4), at * CFrame.new(0, 8.8, 0), STONE:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.Limestone)
		mk(Vector3.new(1.4, 2.2, 1.4), at * CFrame.new(0, 10.3, 0), IRON, Enum.Material.Metal)
		local lamp = mk(Vector3.new(1, 1.6, 1), at * CFrame.new(0, 10.3, 0), WARM, Enum.Material.Neon, { collide = false, shadow = false, name = "PillarLamp" })
		local l = Instance.new("PointLight")
		l.Color = WARM
		l.Range = 22
		l.Brightness = 1.3
		l.Parent = lamp
	end
end

-- a gate leaf: a solid (see-through) panel with bars, all welded to its bottom rail
local function leaf(mk: any, cf: CFrame, w: number, h: number, ghost: boolean): BasePart
	local rail = mk(Vector3.new(w, 0.6, 0.5), cf * CFrame.new(0, 0.7, 0), IRON, Enum.Material.Metal, { name = "GateLeaf" })
	local function bit(size: Vector3, at: CFrame, opts: { [string]: any }?)
		local p = mk(size, at, IRON, Enum.Material.Metal, opts)
		if not ghost then
			p.Anchored = false
			p.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rail
			weld.Part1 = p
			weld.Parent = p
		end
		p.Parent = rail
		return p
	end
	bit(Vector3.new(w, 0.5, 0.5), cf * CFrame.new(0, h, 0))
	bit(Vector3.new(w, 0.3, 0.4), cf * CFrame.new(0, h * 0.55, 0))
	for _, e in { -1, 1 } do
		bit(Vector3.new(0.5, h, 0.5), cf * CFrame.new(e * (w / 2 - 0.25), h / 2 + 0.4, 0))
	end
	local bars = math.max(2, math.floor(w / 1.2))
	for k = 1, bars - 1 do
		bit(Vector3.new(0.22, h - 0.6, 0.22), cf * CFrame.new(-w / 2 + k * w / bars, h / 2 + 0.6, 0))
	end
	-- (an invisible panel inside the bars stops cars and people)
	bit(Vector3.new(w, h, 0.3), cf * CFrame.new(0, h / 2 + 0.4, 0), { transparency = 1, name = "GatePanel" })
	return rail
end

local function fenceAndGate(mk: any, lot: CFrame, lotW: number, lotD: number, tier: number, look: any, design: any, entryX: number, gateW: number, pathX: number, ghost: boolean): ({ Gate }, CFrame?)
	local z = -lotD / 2 + 1
	local hw, hd = lotW / 2 - 1, lotD / 2 - 1
	local gates: { Gate } = {}
	local g0, g1 = entryX - gateW / 2, entryX + gateW / 2
	-- the walk-in gap by the path (merged with the drive's gap when they meet)
	local p0, p1 = pathX - 2.5, pathX + 2.5
	local gaps = { { g0, g1 } }
	if p1 < g0 - 1 or p0 > g1 + 1 then
		table.insert(gaps, { p0, p1 })
	end
	table.sort(gaps, function(a, b)
		return a[1] < b[1]
	end)
	-- the front, between the gaps
	local x = -hw
	for _, gp in gaps do
		if tier == 0 then
			picket(mk, lot, x, gp[1], z)
		else
			fenceRun(mk, lot, tier, look, Vector3.new(x, 0, z), Vector3.new(gp[1], 0, z))
		end
		x = gp[2]
	end
	if tier == 0 then
		picket(mk, lot, x, hw, z)
	else
		fenceRun(mk, lot, tier, look, Vector3.new(x, 0, z), Vector3.new(hw, 0, z))
	end
	-- the sides, and the back with a garden gap in the middle (the dock, the view)
	for _, s in { -1, 1 } do
		fenceRun(mk, lot, tier, look, Vector3.new(s * hw, 0, z), Vector3.new(s * hw, 0, hd))
		fenceRun(mk, lot, tier, look, Vector3.new(s * hw, 0, hd), Vector3.new(s * 4, 0, hd))
	end
	if tier == 0 then
		-- an open drive on the small houses (owner: a small gate or an open drive)
		return gates, nil
	end
	-- the pillars either side of the drive and the path
	for _, e in { g0, g1 } do
		pillar(mk, lot * CFrame.new(e, 0, z), tier, look)
	end
	local gateAt = lot * CFrame.new(entryX, 0, z)
	if tier == 1 then
		-- one sliding leaf, just inside the wall, sliding along it to open
		local closed = lot * CFrame.new(entryX, 0, z + 1.4)
		local part = leaf(mk, closed, gateW - 2.4, 6, ghost)
		local slide = if entryX <= 0 then 1 else -1
		table.insert(gates, { part = part, closed = part.CFrame, open = part.CFrame * CFrame.new(slide * (gateW - 1), 0, 0) })
	else
		-- two big leaves swinging in from the pillars, and the house's name on the wall beside
		local half = (gateW - 3.4) / 2
		for _, e in { -1, 1 } do
			local hingeX = entryX + e * (gateW / 2 - 1.7)
			local closed = lot * CFrame.new(hingeX - e * half / 2, 0, z)
			local part = leaf(mk, closed, half, 8, ghost)
			local hinge = lot * CFrame.new(hingeX, part.CFrame.Y - lot.Y, z)
			local rel = hinge:ToObjectSpace(part.CFrame)
			table.insert(gates, { part = part, closed = part.CFrame, open = hinge * CFrame.Angles(0, e * math.pi / 2, 0) * rel })
		end
		local plateX = entryX + gateW / 2 + 6
		if plateX + 4 < hw then
			local namePlate = mk(Vector3.new(9, 1.6, 0.2), lot * CFrame.new(plateX, 3.6, z - 0.9), STONE, Enum.Material.Limestone, { collide = false })
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Back
			sg.CanvasSize = Vector2.new(450, 80)
			sg.LightInfluence = 0.4
			sg.Parent = namePlate
			local t = Instance.new("TextLabel")
			t.BackgroundTransparency = 1
			t.Size = UDim2.fromScale(1, 1)
			t.Text = string.upper(design.name)
			t.Font = Enum.Font.GothamBold
			t.TextColor3 = Color3.fromRGB(70, 66, 58)
			t.TextScaled = true
			t.Parent = sg
		end
	end
	-- a small walk-in gate by the path
	if #gaps > 1 then
		local pl = lot * CFrame.new(pathX, 0, z)
		mk(Vector3.new(4.6, 0.3, 0.3), pl * CFrame.new(0, 0.4 + 3.6, 0), IRON, Enum.Material.Metal, { collide = false })
	end
	return gates, gateAt
end

---------------------------------------------------------------------
-- A ready-made body's things, made to work (owner, 2026-10-30: "make the house work too"):
-- its TV gets a picture, its light switches (or one of ours by the front door) switch all its
-- lights, its shower runs, a ring on its oven glows, its wardrobes open the outfit screen, its
-- beds let you sleep, its sinks run
---------------------------------------------------------------------
local function biggest(m: Instance): BasePart?
	local best: BasePart? = nil
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and (not best or p.Size.Magnitude > (best :: BasePart).Size.Magnitude) then
			best = p
		end
	end
	return best
end

-- the face of a flat part that looks into the house (where a TV's screen faces)
local function faceInto(p: BasePart, center: Vector3): Enum.NormalId
	local s = p.Size
	local axis = if s.X <= s.Y and s.X <= s.Z then "X" elseif s.Y <= s.Z then "Y" else "Z"
	local v = if axis == "X" then p.CFrame.RightVector elseif axis == "Y" then p.CFrame.UpVector else p.CFrame.LookVector
	local toward = (center - p.Position):Dot(v) > 0
	if axis == "X" then
		return if toward then Enum.NormalId.Right else Enum.NormalId.Left
	elseif axis == "Y" then
		return if toward then Enum.NormalId.Top else Enum.NormalId.Bottom
	end
	-- (LookVector is the Front face's normal)
	return if toward then Enum.NormalId.Front else Enum.NormalId.Back
end

local function wireBody(mk: any, bm: Model, hcf: CFrame, frontDoorX: number?, d: number)
	local center = hcf.Position + Vector3.new(0, 5, 0)
	local switches = 0
	for _, m in bm:GetDescendants() do
		if m:IsA("Model") then
			local nm = m.Name:lower()
			local part = biggest(m)
			if part then
				if nm == "tv" or nm:find("^tv[%s_]") or nm:find("television") or nm:find("led screen") then
					-- the screen is the glass with the TV's own picture decal on it (its face is the one
					-- you watch), or a part named Screen, or else the biggest part; on the side facing in
					local screen = part :: BasePart
					local face: Enum.NormalId? = nil
					for _, x in m:GetDescendants() do
						if x:IsA("Decal") and x.Parent and x.Parent:IsA("BasePart") then
							screen = x.Parent :: BasePart
							face = x.Face
							x:Destroy()
						elseif x:IsA("BasePart") and not face and x.Name:lower():find("screen") then
							screen = x
						elseif x:IsA("Sound") then
							x:Destroy() -- (a sound this game can't use)
						end
					end
					screen.Name = "TVScreen"
					tvPicture(screen, face or faceInto(screen, center))
				elseif nm:find("lightswitch") or nm:find("light switch") then
					switches += 1
					use(part, "light", "Lights", "Light switch", 7)
				elseif nm:find("shower") and not m:FindFirstAncestorWhichIsA("Model"):GetAttribute("Wired") then
					m:SetAttribute("Wired", true)
					local head: BasePart = part
					for _, x in m:GetDescendants() do
						if x:IsA("Sound") then
							x:Destroy() -- (a sound this game can't use)
						elseif x:IsA("BasePart") and x.Name:lower():find("head") then
							head = x
						end
					end
					water(head, 18, 140)
					use(head, "shower", "Shower on", "Shower", 9)
				elseif nm:find("stove") or nm:find("oven") then
					local cf, size = m:GetBoundingBox()
					local ring = mk(Vector3.new(math.min(2.6, size.X * 0.6), 0.08, math.min(2, size.Z * 0.6)), cf * CFrame.new(0, size.Y / 2 + 0.04, 0), Color3.fromRGB(20, 20, 22), Enum.Material.Glass, { name = "Stove", parent = m })
					use(ring, "stove", "Turn on", "Stove")
				elseif nm:find("wardrobe") or nm:find("closet") then
					use(part, "wardrobe", "Change outfit", "Wardrobe")
				elseif (nm:find("bed") and not nm:find("bedside")) or nm:find("blanket") then
					use(part, "bed", "Sleep", "Bed", 9)
				elseif nm:find("sink") or nm:find("faucet") then
					water(part, 4, 60)
					use(part, "tap", "Tap on", "Sink")
				end
			end
		end
	end
	-- no switches of its own: one of ours just inside the front door
	if switches == 0 then
		local x = (frontDoorX or 0) + 3.6
		switch(mk, hcf * CFrame.new(x, 0.4 + 4.6, -d / 2 + 1.6), bm)
	end
end

---------------------------------------------------------------------
-- The house
---------------------------------------------------------------------
function HouseBuilder.build(design: any, lot: CFrame, lotW: number, lotD: number, opts: { ghost: boolean?, interior: boolean? }?): (Model, Info)
	local o = opts or {}
	local ghost = o.ghost == true
	local interior = o.interior == true and not ghost
	local look = design.look
	local model = Instance.new("Model")
	model.Name = "House_" .. design.id
	local mk = maker(model, ghost)
	local tier = design.tier
	local floors = design.floors

	local body = bodyTemplate(look.body)
	-- the garage: in the front of the ground floor on Low houses; a wing on bigger ones
	local maxBays = design.maxBays
	local integrated = tier == 0 and not body
	local under = tier == 2 and lotW >= 110 and lotD >= 120
	local cols = if integrated then maxBays elseif maxBays > 5 then math.ceil(maxBays / 2) else maxBays
	local rows = math.ceil(maxBays / cols)
	local garageW = cols * BAY_W + 2
	local garageD = rows * BAY_D + 2

	local w = look.w
	local d = look.d
	local bodyScale = 1
	if body then
		-- scaled to fit the design's footprint
		local fw, fd = body:GetAttribute("FootW") :: number, body:GetAttribute("FootD") :: number
		bodyScale = math.min((look.fitW or look.w) / fw, (look.fitD or look.d) / fd, 1.2)
		w, d = fw * bodyScale, fd * bodyScale
	end
	if integrated then
		w = math.max(w, garageW + 2)
	end
	-- wing beside the house if it fits, else in front of it
	local wingBeside = not integrated and not under and (w + garageW + 10) <= lotW - 6
	if not integrated and not wingBeside then
		w = math.min(w, if under then lotW - 20 else lotW - 10)
	end
	local houseX = if wingBeside then garageW / 2 + 3 else 0
	-- towards the back, leaving a garden behind for the pool where there is one
	local backGarden = if look.pool or look.hottub then 20 else 6
	local houseZ = lotD / 2 - d / 2 - math.min(backGarden, math.max(6, lotD - d - (if integrated then 16 elseif wingBeside then 24 else garageD + 24)))
	-- the underground garage's ramp runs down the left side: the house keeps clear of it, at the back
	local ugX = -lotW / 2 + 2.5 + UG_W / 2
	local ugTop = -lotD / 2 + UG_APRON
	if under then
		houseX = math.clamp(w / 2 + ugX + UG_W / 2 + 1.5, 0, math.max(0, lotW / 2 - 2 - w / 2))
		houseZ = lotD / 2 - 3 - d / 2
	end
	local hcf = lot * CFrame.new(houseX, 0, houseZ)
	-- the stairs run up the back wall on this side (the side a cantilevered top floor hangs out to)
	local side = if houseX > 0 then -1 else 1
	local shiftTop = if look.cantilever and floors > 1 then side * w * 0.18 else 0

	-- the lot: lawn (round the open ramp down to an underground garage)
	if under then
		local rx1 = ugX + UG_W / 2 + 1
		local rz1 = ugTop + UG_RUN
		mk(Vector3.new(lotW, 0.4, UG_APRON), lot * CFrame.new(0, 0.2, -lotD / 2 + UG_APRON / 2), LAWN, Enum.Material.Grass, { name = "Lawn" })
		mk(Vector3.new(lotW / 2 - rx1, 0.4, UG_RUN), lot * CFrame.new((rx1 + lotW / 2) / 2, 0.2, ugTop + UG_RUN / 2), LAWN, Enum.Material.Grass, { name = "Lawn" })
		mk(Vector3.new(lotW, 0.4, lotD / 2 - rz1), lot * CFrame.new(0, 0.2, (rz1 + lotD / 2) / 2), LAWN, Enum.Material.Grass, { name = "Lawn" })
	else
		mk(Vector3.new(lotW, 0.4, lotD), lot * CFrame.new(0, 0.2, 0), LAWN, Enum.Material.Grass, { name = "Lawn" })
	end

	-- the passage door from a wing garage into the house: where the garage and house overlap
	local passageZ: number? = nil
	if wingBeside then
		passageZ = -d / 2 + math.min(garageD, d) / 2
	end

	-- the house, floor by floor (a cantilever shifts the top floor over)
	local doorsOut: { front: number?, left: number? } = {}
	local bodyTop: number? = nil
	if body then
		local bm = body:Clone()
		bm.Name = "Body"
		if bodyScale ~= 1 then
			bm:ScaleTo(bodyScale)
		end
		bm:PivotTo(hcf * CFrame.new(0, 0.4, 0))
		bodyTop = 0.4 + (body:GetAttribute("Height") :: number) * bodyScale
		if ghost then
			ghostify(bm)
		end
		-- its doors swing on a hinge with E; the front one (nearest the front) is the front door
		local frontZ = math.huge
		for _, p in bm:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("BodyDoor") then
				local closed = p.CFrame
				local hingeSide = (p:GetAttribute("HingeSide") :: number?) or -1
				local hinge = closed * CFrame.new(hingeSide * p.Size.X / 2, 0, 0)
				p:SetAttribute("ClosedCF", closed)
				p:SetAttribute("OpenCF", hinge * CFrame.Angles(0, hingeSide * math.pi / 2, 0) * hinge:ToObjectSpace(closed))
				p.Name = "Door"
				if interior then
					use(p, "door", "Open", "Door", 9)
				end
				local rel = hcf:PointToObjectSpace(p.Position)
				if rel.Z < frontZ then
					frontZ = rel.Z
					doorsOut.front = rel.X
				end
			end
		end
		if interior then
			wireBody(mk, bm, hcf, doorsOut.front, d)
		end
		bm.Parent = model
	end
	for f = 1, (if body then 0 else floors) do
		local folder = Instance.new("Model")
		folder.Name = "Floor" .. f
		folder.Parent = model
		local fw, fd, shift, zoff = w, d, 0, 0
		if f == floors then
			shift = shiftTop
		end
		if integrated and f == 1 then
			-- the garage takes the front of the ground floor: its back wall is the house's front wall
			-- (the door into the house from the garage); its sides and lintel round it
			fd = d - BAY_D - 1
			zoff = (BAY_D + 1) / 2
			local gcf = hcf * CFrame.new(0, 0.4, -d / 2 + (BAY_D + 1) / 2)
			for _, s in { -1, 1 } do
				mk(Vector3.new(1, FLOOR, BAY_D + 1), gcf * CFrame.new(s * (fw / 2 - 0.5), FLOOR / 2, 0), look.wall, Enum.Material.Concrete)
			end
			mk(Vector3.new(fw, 0.6, BAY_D + 1), gcf * CFrame.new(0, 0.3, 0), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
			mk(Vector3.new(fw, 1.6, 1), gcf * CFrame.new(0, FLOOR - 0.8, -(BAY_D + 1) / 2), look.wall, Enum.Material.Concrete)
		end
		local scf = hcf * CFrame.new(shift, 0.4 + (f - 1) * FLOOR, zoff)
		-- the hole for the stairs coming up from below
		local hole = if f > 1 then stairHole(fw, fd, side, shift) else nil
		local doors: { front: number?, left: number? } = {}
		if f == 1 then
			doors.front = if integrated then -side * (fw / 2 - 6) else 0
			if passageZ then
				doors.left = passageZ
			end
		end
		local got = storey(mk, scf, fw, fd, look, look.glassy == true, doors, hole, interior, folder)
		if f == 1 then
			doorsOut = got
		end
		if f < floors then
			stairsUp(mk, scf, fw, fd, side, look.accent or OAK, folder)
		end
		if f > 1 then
			stairRail(mk, scf, fw, fd, side, shift, folder)
		end
		-- the slab above this floor (with the next floor's stairwell hole)
		local above = hcf * CFrame.new(shift, 0.4 + f * FLOOR, zoff)
		local nextHole = if f < floors then stairHole(fw, fd, side, shift) else nil
		plate(mk, above, fw + 1, fd + 1, 0.8, look.trim, Enum.Material.Concrete, nextHole, folder)
		if integrated and f == 1 then
			mk(Vector3.new(fw + 1, 0.8, BAY_D + 2), hcf * CFrame.new(0, 0.4 + FLOOR, -d / 2 + (BAY_D + 1) / 2), look.trim, Enum.Material.Concrete)
		end
		if interior then
			local role = if floors == 1 then "single" elseif f == 1 then "ground" elseif f == 3 then "third" else "upper"
			furnish(mk, scf, fw, fd, side, role, design, look, folder, f < floors)
		end
	end
	local topY = bodyTop or (0.4 + floors * FLOOR + 0.4)
	local roofBase = hcf * CFrame.new(shiftTop, topY, 0)

	-- the roof (a ready-made body brings its own, and its porch and the rest)
	local roof = if body then "none" else look.roof
	local rc = look.roofColor
	if roof == "flat" then
		for _, s in { -1, 1 } do
			mk(Vector3.new(w + 1, 1.6, 0.6), roofBase * CFrame.new(0, 0.8, s * (d / 2 + 0.2)), look.trim, Enum.Material.Concrete)
			mk(Vector3.new(0.6, 1.6, d + 1), roofBase * CFrame.new(s * (w / 2 + 0.2), 0.8, 0), look.trim, Enum.Material.Concrete)
		end
		mk(Vector3.new(w, 0.3, d), roofBase * CFrame.new(0, 0.15, 0), rc, Enum.Material.Slate)
	elseif roof == "mono" then
		mk(Vector3.new(w + 2, 0.8, d + 3), roofBase * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(8), 0, 0), rc, Enum.Material.Metal)
	elseif roof == "hip" then
		hip(mk, roofBase, w, d, math.min(10, d * 0.32), rc, 1.5)
	elseif roof == "gable" or roof == "tile" then
		gable(mk, roofBase, w, d, math.min(12, d * 0.36), rc, 1.5)
	elseif roof == "barn" then
		-- a gambrel: steep lower slopes and a shallow top
		gable(mk, roofBase * CFrame.new(0, 5, 0), w, d * 0.6, 5, rc, 1)
		for _, s in { -1, 1 } do
			mk(Vector3.new(w + 2, 5, d * 0.2 + 1), roofBase * CFrame.new(0, 2.5, s * (d * 0.4 + 0.5)) * CFrame.Angles(0, if s > 0 then 0 else math.pi, 0), rc, Enum.Material.Metal, { wedge = true })
		end
	elseif roof == "aframe" then
		-- a steep roof (on top of the floors, so the rooms stay free under it)
		gable(mk, roofBase, w, d, d * 0.8, rc, 2.5)
	end

	-- extras
	local front = hcf * CFrame.new(0, 0, -d / 2)
	if body then
		look = table.clone(look)
		for _, k in { "porch", "balcony", "verandas", "columns", "towers", "tower", "dome", "cupola", "solar", "helipad", "deck", "pool", "hottub" } do
			look[k] = nil
		end
	end
	if under then
		-- (no room left in the front court for these: the ramp and the house fill it)
		look = table.clone(look)
		for _, k in { "pool", "hottub", "fountain", "carCourt", "palms", "gazebo" } do
			look[k] = nil
		end
	end
	if look.porch then
		mk(Vector3.new(w * 0.7, 0.8, 8), front * CFrame.new(0, 0.8, -4), look.accent or look.trim, Enum.Material.WoodPlanks)
		for _, x in { -0.33, 0, 0.33 } do
			mk(Vector3.new(0.8, FLOOR - 1, 0.8), front * CFrame.new(x * w, FLOOR / 2 + 0.4, -7.5), look.trim, Enum.Material.Wood)
		end
		mk(Vector3.new(w * 0.72, 0.6, 9), front * CFrame.new(0, FLOOR, -4.3), rc, Enum.Material.Slate)
	end
	if look.balcony and floors > 1 then
		mk(Vector3.new(w * 0.5, 0.6, 5), front * CFrame.new(w * 0.15, FLOOR + 0.7, -2.5), look.trim, Enum.Material.Concrete)
		mk(Vector3.new(w * 0.5, 3, 0.3), front * CFrame.new(w * 0.15, FLOOR + 2.4, -4.9), Color3.fromRGB(180, 210, 220), Enum.Material.Glass, { transparency = 0.5 })
	end
	if look.verandas then
		for f = 1, floors do
			mk(Vector3.new(w, 0.6, 8), front * CFrame.new(0, 0.4 + (f - 1) * FLOOR + 0.3, -4), look.wall, Enum.Material.WoodPlanks)
			mk(Vector3.new(w, 2.8, 0.4), front * CFrame.new(0, 0.4 + (f - 1) * FLOOR + 2, -7.8), look.trim, Enum.Material.SmoothPlastic)
			for k = 0, 6 do
				mk(Vector3.new(0.9, FLOOR, 0.9), front * CFrame.new(-w / 2 + 1 + k * (w - 2) / 6, 0.4 + (f - 0.5) * FLOOR, -7.6), look.trim, Enum.Material.SmoothPlastic)
			end
		end
		mk(Vector3.new(w + 1, 0.6, 9), front * CFrame.new(0, 0.4 + floors * FLOOR, -4.4), rc, Enum.Material.Slate)
	end
	if look.columns then
		-- a tall portico: columns up two floors and a pediment
		local h = FLOOR * math.min(2, floors)
		for k = -2, 2 do
			mk(Vector3.new(h, 2.2, 2.2), front * CFrame.new(k * 6, h / 2 + 0.4, -6) * CFrame.Angles(0, 0, math.pi / 2), look.wall, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
		end
		mk(Vector3.new(30, 1.4, 10), front * CFrame.new(0, h + 1.1, -5), look.trim, Enum.Material.Marble)
		gable(mk, front * CFrame.new(0, h + 1.8, -5), 30, 10, 3.5, look.wall, 0)
	end
	if look.towers or look.tower then
		local spots = if look.towers then { -1, 1 } else { 1 }
		for _, s in spots do
			local tc = hcf * CFrame.new(s * (w / 2 - 2), 0, -d / 2 + 2)
			local th = floors * FLOOR + 8
			mk(Vector3.new(th, 12, 12), tc * CFrame.new(0, th / 2 + 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), look.wall, Enum.Material.Concrete, { shape = Enum.PartType.Cylinder })
			mk(Vector3.new(7, 13, 13), tc * CFrame.new(0, th + 3.5, 0), rc, Enum.Material.Slate, { shape = Enum.PartType.Ball })
		end
	end
	if look.dome then
		mk(Vector3.new(16, 16, 16), roofBase * CFrame.new(w * 0.25, 0, d * 0.1), Color3.fromRGB(228, 232, 236), Enum.Material.Glass, { shape = Enum.PartType.Ball, transparency = 0.2 })
	end
	if look.cupola then
		mk(Vector3.new(5, 4, 5), roofBase * CFrame.new(0, (look.roof == "barn" and 10 or 6), 0), look.trim, Enum.Material.Wood)
	end
	if look.solar then
		for k = -1, 1 do
			mk(Vector3.new(w * 0.22, 0.3, d * 0.5), roofBase * CFrame.new(k * w * 0.27, 1.2, d * 0.1) * CFrame.Angles(math.rad(-12), 0, 0), Color3.fromRGB(28, 36, 58), Enum.Material.Glass)
		end
	end
	if look.helipad then
		mk(Vector3.new(1, 26, 26), roofBase * CFrame.new(-w * 0.2, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 48, 54), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder })
		mk(Vector3.new(10, 0.2, 1.4), roofBase * CFrame.new(-w * 0.2, 1.25, 0), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic)
	end

	-- the back garden: pool, deck, hot tub
	local back = hcf * CFrame.new(0, 0, d / 2)
	local behind = lotD / 2 - (houseZ + d / 2) -- room behind the house
	if look.pool or look.hottub then
		local pd = math.max(6, math.min(14, behind - 2))
		if behind < 10 then
			-- no room behind: the pool goes beside the house's front instead
			back = hcf * CFrame.new(w / 2 + 2, 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
			pd = 10
		end
		local pw = math.min(w * 0.6, 30)
		mk(Vector3.new(pw + 6, 0.6, pd + 4), back * CFrame.new(0, 0.5, pd / 2 + 2), Color3.fromRGB(224, 216, 200), Enum.Material.Limestone)
		mk(Vector3.new(pw, 0.3, pd), back * CFrame.new(0, 0.85, pd / 2 + 2), WATER, Enum.Material.Glass, { transparency = 0.15, collide = false, name = "PoolWater" })
	end
	if look.deck then
		mk(Vector3.new(w, 0.8, 8), front * CFrame.new(0, 1, -4), Color3.fromRGB(150, 120, 90), Enum.Material.WoodPlanks)
	end

	-- the garage wing (or the bays in the house's front on small houses, or underground on High lots)
	local bays: { CFrame } = {}
	local dig: { { cf: CFrame, size: Vector3 } } = {}
	local gcf: CFrame
	if under then
		local per = math.ceil(maxBays / 2)
		local x0 = ugX - UG_W / 2 -- the ramp's and the aisle's left edge
		local hallW = UG_W + 2 * BAY_D + 1
		local hallD = per * BAY_W + 2
		local hz0 = ugTop + UG_RUN -- where the ramp meets the floor and the hall begins
		local hcx, hcz = x0 + hallW / 2, hz0 + hallD / 2
		local fy = -UG_DEEP
		local wallC = Color3.fromRGB(196, 194, 188)
		local floorC = Color3.fromRGB(72, 74, 80)
		gcf = lot * CFrame.new(ugX, 0, ugTop + UG_APRON / 2)
		-- the ramp: one sloping slab between retaining walls, a low wall along the lawn side
		local rise = 0.4 - fy
		local slope = math.atan2(rise, UG_RUN)
		local len = math.sqrt(UG_RUN * UG_RUN + rise * rise)
		local mid = lot * CFrame.new(ugX, (0.4 + fy) / 2, ugTop + UG_RUN / 2) * CFrame.Angles(slope, 0, 0)
		mk(Vector3.new(UG_W, 1, len + 0.6), mid * CFrame.new(0, -0.5, 0), floorC, Enum.Material.Concrete, { name = "Ramp" })
		for _, s in { -1, 1 } do
			local top = if s == 1 then 1.8 else 0.4
			mk(Vector3.new(1, top - (fy - 3), UG_RUN), lot * CFrame.new(ugX + s * (UG_W / 2 + 0.5), (top + fy - 3) / 2, ugTop + UG_RUN / 2), wallC, Enum.Material.Concrete)
		end
		-- a soft strip of light down each side of the ramp
		for _, s in { -1, 1 } do
			mk(Vector3.new(0.2, 0.2, len), mid * CFrame.new(s * (UG_W / 2 - 0.3), 0.1, 0), Color3.fromRGB(120, 96, 70), Enum.Material.Neon, { collide = false, shadow = false })
		end
		-- the hall: floor (thick, so no ground shows through), ceiling (the lawn and the house stand on
		-- it), walls round it
		mk(Vector3.new(hallW, 2, hallD), lot * CFrame.new(hcx, fy - 1, hcz), floorC, Enum.Material.Concrete, { name = "GarageFloor" })
		mk(Vector3.new(hallW + 2, 1.4, hallD + 2), lot * CFrame.new(hcx, -0.5, hcz), wallC, Enum.Material.Concrete)
		local wh = UG_DEEP + 2.5
		local wy = (fy - 3 - 0.5) / 2
		mk(Vector3.new(1, wh, hallD + 2), lot * CFrame.new(x0 - 0.5, wy, hcz), wallC, Enum.Material.Concrete)
		mk(Vector3.new(1, wh, hallD + 2), lot * CFrame.new(x0 + hallW + 0.5, wy, hcz), wallC, Enum.Material.Concrete)
		mk(Vector3.new(hallW + 2, wh, 1), lot * CFrame.new(hcx, wy, hz0 + hallD + 0.5), wallC, Enum.Material.Concrete)
		mk(Vector3.new(hallW - UG_W, wh, 1), lot * CFrame.new(x0 + UG_W + (hallW - UG_W) / 2, wy, hz0 - 0.5), wallC, Enum.Material.Concrete)
		-- a lit header over the way in, and light strips along the ceiling
		mk(Vector3.new(UG_W, 0.4, 0.4), lot * CFrame.new(ugX, -1.5, hz0), WARM, Enum.Material.Neon, { collide = false, shadow = false })
		for _, sx in { UG_W / 2, UG_W + BAY_D / 2, UG_W + BAY_D * 1.5 } do
			local strip = mk(Vector3.new(0.5, 0.2, hallD - 4), lot * CFrame.new(x0 + sx, -1.3, hcz), Color3.fromRGB(150, 156, 172), Enum.Material.Neon, { collide = false, shadow = false })
			if sx == UG_W + BAY_D / 2 then
				local gl = Instance.new("PointLight")
				gl.Color = Color3.fromRGB(236, 240, 255)
				gl.Range = 40
				gl.Brightness = 1.2
				gl.Parent = strip
			end
		end
		-- the bays: two rows beside the aisle, the cars' noses to it
		for k = 1, maxBays do
			local col = if k <= per then 1 else 2
			local i = if col == 1 then k else k - per
			local x = x0 + UG_W + (col - 0.5) * BAY_D + 0.5
			local z = hz0 + 1 + (i - 0.5) * BAY_W
			table.insert(bays, lot * CFrame.new(x, fy, z) * CFrame.Angles(0, math.pi / 2, 0))
			mk(Vector3.new(BAY_D - 2, 0.05, 0.2), lot * CFrame.new(x, fy + 0.03, z - BAY_W / 2), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, { collide = false })
		end
		-- the ground to clear: the ramp's trench and the hall (well past the walls and the floor: the
		-- terrain's edge voxels are only partly cleared and would show through; and above the lot, for
		-- any bank or boulder reaching over its edge)
		local dy = (10 + fy - 6) / 2
		local dh = 10 - (fy - 6)
		table.insert(dig, { cf = lot * CFrame.new(ugX, dy, ugTop + UG_RUN / 2), size = Vector3.new(UG_W + 6, dh, UG_RUN + 2) })
		table.insert(dig, { cf = lot * CFrame.new(hcx, dy, hcz), size = Vector3.new(hallW + 8, dh, hallD + 8) })
	elseif integrated then
		gcf = hcf * CFrame.new(0, 0.4, -d / 2 + (BAY_D + 1) / 2)
		for k = 1, maxBays do
			local x = -(cols * BAY_W) / 2 + (k - 0.5) * BAY_W
			table.insert(bays, gcf * CFrame.new(x, 0.6, 0)) -- nose out, towards the road
			-- door: a dark panel up top (open below so cars fit)
			mk(Vector3.new(BAY_W - 1.2, 2.2, 0.4), gcf * CFrame.new(x, FLOOR - 2.2, -(BAY_D + 1) / 2), DARK, Enum.Material.Metal)
		end
	else
		local gx = if wingBeside then -(w / 2 + 3 + garageW / 2) + houseX else -lotW / 2 + garageW / 2 + 4
		local gz = if wingBeside then houseZ - d / 2 + garageD / 2 else houseZ - d / 2 - 4 - garageD / 2
		gcf = lot * CFrame.new(gx, 0, gz)
		local gh = FLOOR + 1
		mk(Vector3.new(garageW, 0.6, garageD), gcf * CFrame.new(0, 0.7, 0), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
		mk(Vector3.new(garageW, gh, 1), gcf * CFrame.new(0, gh / 2 + 0.4, garageD / 2 - 0.5), look.wall, Enum.Material.Concrete)
		-- the side walls; the one by the house has the doorway into the passage
		local passageG: number? = nil
		if wingBeside and doorsOut.left then
			passageG = gcf:PointToObjectSpace((hcf * CFrame.new(-w / 2, 0, doorsOut.left)).Position).Z
		end
		for _, s in { -1, 1 } do
			local wx = s * (garageW / 2 - 0.5)
			if s == 1 and passageG then
				local a, b = passageG - 3, passageG + 3
				local function seg(z0: number, z1: number)
					if z1 - z0 > 0.1 then
						mk(Vector3.new(1, gh, z1 - z0), gcf * CFrame.new(wx, gh / 2 + 0.4, (z0 + z1) / 2), look.wall, Enum.Material.Concrete)
					end
				end
				seg(-garageD / 2, a)
				seg(b, garageD / 2)
				mk(Vector3.new(1, gh - HEAD - 1, 6), gcf * CFrame.new(wx, (HEAD + 1 + gh) / 2 + 0.4, passageG), look.wall, Enum.Material.Concrete)
				-- the covered passage to the house's side door
				local px = garageW / 2 + 1.5
				mk(Vector3.new(4, 0.6, 6), gcf * CFrame.new(px, 0.7, passageG), Color3.fromRGB(206, 196, 180), Enum.Material.WoodPlanks)
				mk(Vector3.new(4, 0.6, 7), gcf * CFrame.new(px, gh - 0.4, passageG), look.trim, Enum.Material.Concrete)
				for _, e in { -1, 1 } do
					mk(Vector3.new(4, gh - 0.6, 0.6), gcf * CFrame.new(px, gh / 2 + 0.4, passageG + e * 3.3), look.wall, Enum.Material.Concrete)
				end
			else
				mk(Vector3.new(1, gh, garageD), gcf * CFrame.new(wx, gh / 2 + 0.4, 0), look.wall, Enum.Material.Concrete)
			end
		end
		mk(Vector3.new(garageW + 1, 1, garageD + 1), gcf * CFrame.new(0, gh + 0.9, 0), look.roofColor, Enum.Material.Slate)
		mk(Vector3.new(garageW, 1.8, 1), gcf * CFrame.new(0, gh - 0.5, -garageD / 2 + 0.5), look.wall, Enum.Material.Concrete)
		-- a light strip along the ceiling
		local strip = mk(Vector3.new(garageW - 2, 0.2, 0.6), gcf * CFrame.new(0, gh, 0), WARM, Enum.Material.Neon, { collide = false, shadow = false })
		local gl = Instance.new("PointLight")
		gl.Color = WARM
		gl.Range = math.max(garageW, garageD) * 0.7
		gl.Brightness = 0.8
		gl.Parent = strip
		for k = 1, maxBays do
			local col = (k - 1) % cols
			local row = math.floor((k - 1) / cols)
			local x = -(cols * BAY_W) / 2 + (col + 0.5) * BAY_W
			local z = -garageD / 2 + 1 + (row + 0.5) * BAY_D
			table.insert(bays, gcf * CFrame.new(x, 1, z))
			mk(Vector3.new(0.2, 0.05, BAY_D - 2), gcf * CFrame.new(x - BAY_W / 2, 1.03, z), Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic, { collide = false })
		end
	end

	-- the driveway: from the lot's front edge to the garage doors (or the ramp), and the show-car spots on it
	local doorZ = (lot:ToObjectSpace(gcf)).Position.Z - (if under then UG_APRON / 2 elseif integrated then (BAY_D + 1) / 2 else garageD / 2)
	local gxLocal = (lot:ToObjectSpace(gcf)).Position.X
	local driveLen = doorZ + lotD / 2
	local driveW = if under then UG_W else math.max(14, if integrated then garageW else math.min(garageW, 24))
	if driveLen > 1 then
		mk(Vector3.new(driveW, 0.3, driveLen), lot * CFrame.new(gxLocal, 0.55, -lotD / 2 + driveLen / 2), PAVERS, Enum.Material.Pavement, { name = "Driveway" })
	end
	-- the island's drive comes in at the middle of a Mid or High lot's front: an apron joins it
	local entryX = if tier == 0 then gxLocal else 0
	local gateW = if tier == 0 then driveW else 20
	if tier > 0 then
		local x0 = math.min(entryX - gateW / 2, gxLocal - driveW / 2)
		local x1 = math.max(entryX + gateW / 2, gxLocal + driveW / 2)
		mk(Vector3.new(x1 - x0, 0.3, 14), lot * CFrame.new((x0 + x1) / 2, 0.56, -lotD / 2 + 7), PAVERS, Enum.Material.Pavement, { name = "Driveway" })
	end
	local drive: { CFrame } = {}
	local houseFront = houseZ - d / 2
	for k = 1, design.drive do
		if under then
			-- in the front court if there is room before the house, else beside the gate, side on
			local spot: CFrame
			if houseFront - ugTop >= 20 then
				spot = lot * CFrame.new(ugX + UG_W / 2 + 9 + (k - 1) * 10, 0.75, ugTop + (houseFront - ugTop) / 2)
				mk(Vector3.new(9, 0.3, 16), spot * CFrame.new(0, -0.19, 0), PAVERS, Enum.Material.Pavement)
			else
				spot = lot * CFrame.new(lotW / 2 - 12 - (k - 1) * 17, 0.75, -lotD / 2 + UG_APRON / 2 + 0.5) * CFrame.Angles(0, math.pi / 2, 0)
				mk(Vector3.new(9, 0.3, 16), spot * CFrame.new(0, -0.19, 0), PAVERS, Enum.Material.Pavement)
			end
			table.insert(drive, spot)
			continue
		end
		-- side by side on the drive near the front
		local z = -lotD / 2 + math.max(6, math.min(driveLen - 8, 10))
		local x = gxLocal + (k - (design.drive + 1) / 2) * math.max(7, driveW / design.drive)
		if design.drive >= 3 then
			-- a front court for three: across the yard beside the drive
			x = gxLocal + driveW / 2 + 6 + (k - 1) * 10
			z = -lotD / 2 + 22
			mk(Vector3.new(9, 0.3, 16), lot * CFrame.new(x, 0.56, z), PAVERS, Enum.Material.Pavement)
		elseif tier > 0 then
			z = -lotD / 2 + math.max(18, math.min(driveLen - 8, 22))
		end
		table.insert(drive, lot * CFrame.new(x, 0.75, z))
	end
	-- the path from the front edge to the door
	local doorLocal = (lot:ToObjectSpace(hcf * CFrame.new(doorsOut.front or 0, 0, -d / 2))).Position
	mk(Vector3.new(4, 0.3, math.max(1, doorLocal.Z + lotD / 2)), lot * CFrame.new(doorLocal.X, 0.55, (-lotD / 2 + doorLocal.Z) / 2), PAVERS, Enum.Material.Pavement)

	-- the front court's fountain on the grand houses
	if look.fountain or look.carCourt then
		local fc = lot * CFrame.new(gxLocal + driveW / 2 + 22, 0, -lotD / 2 + 30)
		mk(Vector3.new(1, 26, 26), fc * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), PAVERS, Enum.Material.Pavement, { shape = Enum.PartType.Cylinder })
		if look.fountain then
			mk(Vector3.new(1.4, 12, 12), fc * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(226, 220, 206), Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
			mk(Vector3.new(0.4, 10.6, 10.6), fc * CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.pi / 2), WATER, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.2, collide = false })
			mk(Vector3.new(5, 1.4, 1.4), fc * CFrame.new(0, 4, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(226, 220, 206), Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
			mk(Vector3.new(1, 5, 5), fc * CFrame.new(0, 6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(226, 220, 206), Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
		else
			mk(Vector3.new(2, 9, 9), fc * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 140, 80), Enum.Material.Grass, { shape = Enum.PartType.Cylinder })
			palm(mk, fc * CFrame.new(0, 2.4, 0), 16)
		end
	end
	if look.palms then
		for _, x in { -0.42, 0.42 } do
			palm(mk, lot * CFrame.new(x * lotW, 0.4, -lotD / 2 + 8), 18)
		end
	end
	if look.gazebo then
		local gz = lot * CFrame.new(lotW / 2 - 12, 0.4, lotD / 2 - 12)
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				mk(Vector3.new(0.6, 8, 0.6), gz * CFrame.new(sx * 4, 4, sz * 4), Color3.fromRGB(246, 244, 238), Enum.Material.Wood)
			end
		end
		hip(mk, gz * CFrame.new(0, 8, 0), 10, 10, 3, look.roofColor, 0.5)
	end

	-- the fence or wall round the lot and the gate where the drive comes in
	local gates, gateAt = fenceAndGate(mk, lot, lotW, lotD, tier, look, design, entryX, gateW, doorLocal.X, ghost)

	-- the mailbox outside, beside the gate
	local mailbox = lot * CFrame.new(entryX + gateW / 2 + 3, 0.4, -lotD / 2 - 0.8)
	mk(Vector3.new(0.4, 3.6, 0.4), mailbox * CFrame.new(0, 1.8, 0), DARK, Enum.Material.Metal)
	mk(Vector3.new(1.4, 1.1, 2), mailbox * CFrame.new(0, 4, 0), Color3.fromRGB(38, 40, 46), Enum.Material.Metal, { name = "Mailbox" })

	local info: Info = {
		bays = bays,
		drive = drive,
		door = hcf * CFrame.new(doorsOut.front or 0, 0.4, -d / 2 - 3) * CFrame.Angles(0, math.pi, 0),
		mailbox = mailbox,
		spawn = lot * CFrame.new(gxLocal, 0.6, -lotD / 2 + 8),
		size = Vector3.new(lotW, topY + 12, lotD),
		gates = gates,
		gateAt = gateAt,
		dig = dig,
	}
	return model, info
end

return HouseBuilder
