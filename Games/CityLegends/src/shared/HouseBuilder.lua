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

	HouseBuilder.build(design, lotFrame, lotWidth, lotDepth, opts) -> (Model, info)
	  opts.ghost: see-through, no collisions (the claim preview)
	  info.bays: a CFrame per garage bay (where a car stands, facing out of its door)
	  info.drive: CFrames of the driveway spots for show cars
	  info.door: just outside the front door, facing in; info.mailbox: by the drive at the front
	  info.spawn: where a car driven out of the garage appears (on the driveway, facing the road)
	The rooms inside come later (housing Part 5); the ground floor already has an open front door.
]]

local HouseBuilder = {}

local FLOOR = 11 -- storey height
local BAY_W = 11 -- garage bay width
local BAY_D = 20 -- garage bay depth
local WINDOW = Color3.fromRGB(70, 92, 110)
local WARM = Color3.fromRGB(255, 214, 160)
local LAWN = Color3.fromRGB(64, 112, 52)
local PAVERS = Color3.fromRGB(196, 190, 178)
local WATER = Color3.fromRGB(40, 170, 215)
local DARK = Color3.fromRGB(32, 32, 36)

export type Info = {
	bays: { CFrame },
	drive: { CFrame },
	door: CFrame,
	mailbox: CFrame,
	spawn: CFrame,
	size: Vector3,
}

-- a part maker bound to one model (ghost: see-through and not solid)
local function maker(model: Model, ghost: boolean)
	return function(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, opts: { [string]: any }?): BasePart
		local o = opts or {}
		local p: BasePart
		if o.wedge then
			p = Instance.new("WedgePart")
		elseif o.corner then
			p = Instance.new("CornerWedgePart")
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
		p.Parent = model
		return p
	end
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

-- a storey's walls with a band of windows on each side and a door gap on the front
local function storey(mk: any, cf: CFrame, w: number, d: number, look: any, ground: boolean, glassy: boolean)
	local wall = look.wall
	local t = 1 -- wall thickness
	local sill, head = 2.5, 8.6 -- the window band
	local function side(len: number, at: CFrame, isFront: boolean)
		-- solid below and above the windows
		mk(Vector3.new(len, sill, t), at * CFrame.new(0, sill / 2, 0), wall, Enum.Material.Concrete)
		mk(Vector3.new(len, FLOOR - head, t), at * CFrame.new(0, (head + FLOOR) / 2, 0), wall, Enum.Material.Concrete)
		-- windows between piers (a big glass wall on glassy designs)
		local panes = math.max(1, math.floor(len / (if glassy then 9 else 7)))
		local pier = if glassy then 0.5 else 1.6
		local pane = (len - pier * (panes + 1)) / panes
		for k = 0, panes do
			local x = -len / 2 + pier / 2 + k * (pane + pier)
			mk(Vector3.new(pier, head - sill, t), at * CFrame.new(x, (sill + head) / 2, 0), if glassy then look.trim else wall, Enum.Material.Concrete)
		end
		for k = 1, panes do
			local x = -len / 2 + pier + (k - 0.5) * pane + (k - 1) * pier
			if isFront and ground and k == math.ceil(panes / 2) then
				-- the front door: an opening with a dark frame
				mk(Vector3.new(0.4, head, t + 0.2), at * CFrame.new(x - 2.6, head / 2, 0), look.trim, Enum.Material.Wood)
				mk(Vector3.new(0.4, head, t + 0.2), at * CFrame.new(x + 2.6, head / 2, 0), look.trim, Enum.Material.Wood)
				mk(Vector3.new((pane - 5.2) / 2 + 0.1, head - sill, t), at * CFrame.new(x - 2.6 - (pane - 5.2) / 4, (sill + head) / 2, 0), WINDOW, Enum.Material.Glass, { transparency = 0.35 })
				mk(Vector3.new((pane - 5.2) / 2 + 0.1, head - sill, t), at * CFrame.new(x + 2.6 + (pane - 5.2) / 4, (sill + head) / 2, 0), WINDOW, Enum.Material.Glass, { transparency = 0.35 })
			else
				mk(Vector3.new(pane, head - sill, t * 0.4), at * CFrame.new(x, (sill + head) / 2, 0), WINDOW, Enum.Material.Glass, { transparency = 0.35 })
			end
		end
	end
	side(w, cf * CFrame.new(0, 0, -d / 2 + 0.5), true) -- front
	side(w, cf * CFrame.new(0, 0, d / 2 - 0.5) * CFrame.Angles(0, math.pi, 0), false) -- back
	side(d - 2, cf * CFrame.new(-w / 2 + 0.5, 0, 0) * CFrame.Angles(0, math.pi / 2, 0), false)
	side(d - 2, cf * CFrame.new(w / 2 - 0.5, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), false)
	-- the floor, and a warm light inside (lit windows at night)
	mk(Vector3.new(w - 1, 0.6, d - 1), cf * CFrame.new(0, 0.3, 0), Color3.fromRGB(206, 196, 180), Enum.Material.WoodPlanks)
	local lamp = mk(Vector3.new(1, 0.2, 1), cf * CFrame.new(0, FLOOR - 0.6, 0), WARM, Enum.Material.Neon, { collide = false, shadow = false, name = "CeilingLight" })
	local light = Instance.new("PointLight")
	light.Color = WARM
	light.Range = math.min(40, math.max(w, d) * 0.7)
	light.Brightness = 0.9
	light.Shadows = false
	light.Parent = lamp
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

function HouseBuilder.build(design: any, lot: CFrame, lotW: number, lotD: number, opts: { ghost: boolean? }?): (Model, Info)
	local o = opts or {}
	local look = design.look
	local model = Instance.new("Model")
	model.Name = "House_" .. design.id
	local mk = maker(model, o.ghost == true)
	local tier = design.tier
	local floors = design.floors

	-- the garage: in the front of the ground floor on Low houses; a wing on bigger ones
	local maxBays = design.maxBays
	local integrated = tier == 0
	local cols = if integrated then maxBays elseif maxBays > 5 then math.ceil(maxBays / 2) else maxBays
	local rows = math.ceil(maxBays / cols)
	local garageW = cols * BAY_W + 2
	local garageD = rows * BAY_D + 2

	local w = look.w
	local d = look.d
	if integrated then
		w = math.max(w, garageW + 2)
	end
	-- wing beside the house if it fits, else in front of it
	local wingBeside = not integrated and (w + garageW + 10) <= lotW - 6
	if not integrated and not wingBeside then
		w = math.min(w, lotW - 10)
	end
	local houseX = if wingBeside then garageW / 2 + 3 else 0
	-- towards the back, leaving a garden behind for the pool where there is one
	local backGarden = if look.pool or look.hottub then 20 else 6
	local houseZ = lotD / 2 - d / 2 - math.min(backGarden, math.max(6, lotD - d - (if integrated then 16 elseif wingBeside then 24 else garageD + 24)))
	local hcf = lot * CFrame.new(houseX, 0, houseZ)

	-- the lot: lawn, a path to the door, the driveway to the garage
	mk(Vector3.new(lotW, 0.4, lotD), lot * CFrame.new(0, 0.2, 0), LAWN, Enum.Material.Grass, { name = "Lawn" })

	-- the house, floor by floor (a cantilever shifts the top floor over)
	for f = 1, floors do
		local fw, fd, shift = w, d, 0
		if look.cantilever and f == floors and floors > 1 then
			-- (it hangs out towards the middle of the lot, over the garage wing, never off the lot)
			shift = (if houseX > 0 then -1 else 1) * w * 0.18
		end
		if integrated and f == 1 then
			-- the garage takes the front of the ground floor
			fd = d - BAY_D - 1
			local gcf = hcf * CFrame.new(0, 0.4, -d / 2 + (BAY_D + 1) / 2)
			mk(Vector3.new(fw, FLOOR, 1), gcf * CFrame.new(0, FLOOR / 2, (BAY_D + 1) / 2), look.wall, Enum.Material.Concrete)
			for _, s in { -1, 1 } do
				mk(Vector3.new(1, FLOOR, BAY_D + 1), gcf * CFrame.new(s * (fw / 2 - 0.5), FLOOR / 2, 0), look.wall, Enum.Material.Concrete)
			end
			mk(Vector3.new(fw, 0.6, BAY_D + 1), gcf * CFrame.new(0, 0.3, 0), Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
			mk(Vector3.new(fw, 1.6, 1), gcf * CFrame.new(0, FLOOR - 0.8, -(BAY_D + 1) / 2), look.wall, Enum.Material.Concrete)
			storey(mk, hcf * CFrame.new(0, 0.4, (BAY_D + 1) / 2), fw, fd, look, true, look.glassy == true)
		else
			storey(mk, hcf * CFrame.new(shift, 0.4 + (f - 1) * FLOOR, 0), fw, fd, look, f == 1 and not integrated, look.glassy == true)
		end
		-- a slab between floors (and the roof deck on top)
		mk(Vector3.new(fw + 1, 0.8, fd + 1), hcf * CFrame.new(shift, 0.4 + f * FLOOR, if integrated and f == 1 then (BAY_D + 1) / 2 else 0), look.trim, Enum.Material.Concrete)
		if integrated and f == 1 then
			mk(Vector3.new(fw + 1, 0.8, BAY_D + 2), hcf * CFrame.new(0, 0.4 + FLOOR, -d / 2 + (BAY_D + 1) / 2), look.trim, Enum.Material.Concrete)
		end
	end
	local topY = 0.4 + floors * FLOOR + 0.4
	local roofBase = hcf * CFrame.new(if look.cantilever and floors > 1 then (if houseX > 0 then -1 else 1) * w * 0.18 else 0, topY, 0)

	-- the roof
	local roof = look.roof
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
		gable(mk, hcf * CFrame.new(0, 0.4 + FLOOR * 0.6, 0), w, d, topY + 8, rc, 2)
	end

	-- extras
	local front = hcf * CFrame.new(0, 0, -d / 2)
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

	-- the garage wing (or the bays in the house's front on small houses)
	local bays: { CFrame } = {}
	local gcf: CFrame
	if integrated then
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
		for _, s in { -1, 1 } do
			mk(Vector3.new(1, gh, garageD), gcf * CFrame.new(s * (garageW / 2 - 0.5), gh / 2 + 0.4, 0), look.wall, Enum.Material.Concrete)
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

	-- the driveway: from the lot's front edge to the garage doors, and the show-car spots on it
	local doorZ = (lot:ToObjectSpace(gcf)).Position.Z - (if integrated then (BAY_D + 1) / 2 else garageD / 2)
	local gxLocal = (lot:ToObjectSpace(gcf)).Position.X
	local driveLen = doorZ + lotD / 2
	local driveW = math.max(14, if integrated then garageW else math.min(garageW, 24))
	if driveLen > 1 then
		mk(Vector3.new(driveW, 0.3, driveLen), lot * CFrame.new(gxLocal, 0.55, -lotD / 2 + driveLen / 2), PAVERS, Enum.Material.Pavement, { name = "Driveway" })
	end
	local drive: { CFrame } = {}
	for k = 1, design.drive do
		-- side by side on the drive near the front
		local z = -lotD / 2 + math.max(6, math.min(driveLen - 8, 10))
		local x = gxLocal + (k - (design.drive + 1) / 2) * math.max(7, driveW / design.drive)
		if design.drive >= 3 then
			-- a front court for three: across the yard beside the drive
			x = gxLocal + driveW / 2 + 6 + (k - 1) * 10
			z = -lotD / 2 + 12
			mk(Vector3.new(9, 0.3, 16), lot * CFrame.new(x, 0.56, z), PAVERS, Enum.Material.Pavement)
		end
		table.insert(drive, lot * CFrame.new(x, 0.75, z))
	end
	-- the path from the front edge to the door
	local doorLocal = (lot:ToObjectSpace(front)).Position
	mk(Vector3.new(4, 0.3, math.max(1, doorLocal.Z + lotD / 2)), lot * CFrame.new(doorLocal.X, 0.55, (-lotD / 2 + doorLocal.Z) / 2), PAVERS, Enum.Material.Pavement)

	-- the front court's fountain on the grand houses
	if look.fountain or look.carCourt then
		local fc = lot * CFrame.new(gxLocal + driveW / 2 + 22, 0, -lotD / 2 + 26)
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
		for _, x in { -0.45, 0.45 } do
			palm(mk, lot * CFrame.new(x * lotW, 0.4, -lotD / 2 + 6), 18)
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

	-- the mailbox at the front, by the drive
	local mailbox = lot * CFrame.new(gxLocal + driveW / 2 + 3, 0.4, -lotD / 2 + 2)
	mk(Vector3.new(0.4, 3.6, 0.4), mailbox * CFrame.new(0, 1.8, 0), DARK, Enum.Material.Metal)
	mk(Vector3.new(1.4, 1.1, 2), mailbox * CFrame.new(0, 4, 0), Color3.fromRGB(38, 40, 46), Enum.Material.Metal, { name = "Mailbox" })

	local info: Info = {
		bays = bays,
		drive = drive,
		door = front * CFrame.new(0, 0.4, -3) * CFrame.Angles(0, math.pi, 0),
		mailbox = mailbox,
		spawn = lot * CFrame.new(gxLocal, 0.6, -lotD / 2 + 8),
		size = Vector3.new(lotW, topY + 12, lotD),
	}
	return model, info
end

return HouseBuilder
