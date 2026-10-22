--[[
	Hotel
	The Legends Grand Hotel, Downtown on Ocean Drive (owner, 2026-10-22: "add a large skyscraper
	hotel with valets and you can buy a penthouse on the hotel"; "Downtown penthouse suites pay out
	money every minute to their owners").

	  * the forecourt: a porte-cochere driveway off the street under a lit canopy with the hotel's
	    name, a fountain island with palms and the name stone, the valet stand and valets in uniform
	  * the grand lobby: marble and gold, columns, chandeliers, reception with a concierge, a lounge
	    with a grand piano, the suite sales gallery, the residents' board and a bank of elevators
	    (one per suite, one to the roof)
	  * the tower: glass and champagne gold in two setbacks, Miami Art Deco neon (pink and teal), a
	    vertical HOTEL sign and the name round the top
	  * the crown: the suites (Config.Hotel.Suites), full penthouse floors built by Towers.suite
	    (lounge, kitchen, bedroom, car showcase, DJ booth and party mode), with the roof terrace (sky
	    pool, telescope, helipad) on the top one, and gold fins rising past the roof

	Valets: stop your car in the valet bay under the canopy and press Y ("VALET"): you step out at
	the door and a valet drives the car round into the valet garage. At the valet stand, "Get my
	car" brings it back to the bay (the next spawn of that car starts there, see ctx.setSpawnAt).
	Suites pay their owners every full minute in the game (Config.Hotel.IncomeEvery); time offline
	doesn't pay.

	CityBuilder calls Hotel.buildWorld(kit, parent) once Downtown is built (on the site
	WestLayout.site("hotel")); Main calls Hotel.init(ctx).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local Towers = require(script.Parent:WaitForChild("Towers"))

local Hotel = {}

local H = Config.Hotel
local GOLD = H.Accent
local PINK, TEAL = H.Neon[1], H.Neon[2]
local MARBLE = Color3.fromRGB(232, 228, 220)
local MARBLE_DARK = Color3.fromRGB(36, 36, 40)
local STONE = Color3.fromRGB(214, 204, 186) -- warm limestone
local BRASS = Color3.fromRGB(201, 162, 92)
local WALNUT = Color3.fromRGB(74, 50, 36)
local CREAM = Color3.fromRGB(226, 214, 192)
local BLACK = Color3.fromRGB(12, 12, 14)
local CHARCOAL = Color3.fromRGB(34, 34, 38)
local GLASS = Color3.fromRGB(150, 182, 205)
local WARM = Color3.fromRGB(255, 214, 160)
local PAVER = Color3.fromRGB(58, 56, 60)
local WATER = Color3.fromRGB(40, 150, 200)
local LEAF = Color3.fromRGB(52, 96, 44)
local BURGUNDY = Color3.fromRGB(122, 20, 34)
local CURB = Config.City.CurbHeight

-- sizes in the hotel's own frame (x right, y up from the lot, -z out of the entrance); the
-- podium and the driveway fit the lot, which shrinks when the roads get wider
local _, SITE_LOT = WestLayout.site("hotel")
local PODIUM_Z0 = -40 -- the podium's front
local PODIUM_Z1 = math.min(100, SITE_LOT / 2 - 6) -- and back
local LOBBY_X = 76 -- the lobby's half width (the wings are outside it)
local WING_X = math.clamp(SITE_LOT / 2 - 4, LOBBY_X + 24, 110) -- the podium's half width
local LH = 36 -- lobby ceiling
local PODIUM_TOP = 38
local TOWER_Z = 30 -- the tower's centre line, set back over the podium
local BODY1 = { w = 132, d = 104, y0 = PODIUM_TOP, y1 = 300 }
local BODY2 = { w = 112, d = 96, y0 = 301.4, y1 = 432 }
local CROWN_Y = 435 -- the first suite's floor
local SUITE_STEP = 33.2 -- one suite floor to the next (30 tall, slabs between)
local LANE_X = WING_X - 16 -- the driveway's entry (-) and exit (+) lanes (the exit runs into the valet garage)
local BAY_Z = -62 -- the cross lane under the canopy
local ELEVATOR_Z = 88 -- the elevator core's face

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
type Site = {
	frame: CFrame,
	bay: Vector3, -- the valet bay's middle (ground)
	bayCF: CFrame, -- where a returned car stands, facing the exit
	entrance: CFrame, -- where you step out, facing the doors
	garage: { Vector3 }, -- the valet's route from the bay into the garage
	board: TextLabel?,
}
local site: Site? = nil
local ctx: any = nil
local tickets: { [Player]: string } = {} -- car ids the valet is holding
local carry: { [Player]: number } = {} -- seconds towards the next suite payment
local fxRemote: RemoteEvent? = nil

local SUITE_BY_ID: { [string]: any } = {}
for _, s in H.Suites do
	SUITE_BY_ID[s.id] = s
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "$" .. out
end

local function titleCase(s: string): string
	local words = {}
	for w in string.gmatch(string.lower(s), "%S+") do
		table.insert(words, string.upper(string.sub(w, 1, 1)) .. string.sub(w, 2))
	end
	return table.concat(words, " ")
end

local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode?, hold: number?, dist: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = key or Enum.KeyCode.E
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = dist or 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

---------------------------------------------------------------------
-- Staff: valets and the concierge (Roblox's own default avatar in uniform colours, standing
-- still; a plain part figure if the avatar can't be made)
---------------------------------------------------------------------
type Look = { jacket: Color3, legs: Color3, skin: Color3, cap: boolean }

local function weldTo(part: BasePart, to: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function trim(kit: any, model: Model, head: BasePart?, torso: BasePart?, look: Look)
	if head and look.cap then
		-- a pillbox cap with a gold band and a black brim
		local cap = kit.deco(model, Vector3.new(0.7, 1.3, 1.3), head.CFrame * CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.pi / 2), look.jacket, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
		weldTo(cap, head)
		local band = kit.deco(model, Vector3.new(0.18, 1.34, 1.34), head.CFrame * CFrame.new(0, 0.38, 0) * CFrame.Angles(0, 0, math.pi / 2), BRASS, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		weldTo(band, head)
		local brim = kit.deco(model, Vector3.new(1.1, 0.1, 0.45), head.CFrame * CFrame.new(0, 0.32, -0.75), BLACK, Enum.Material.SmoothPlastic)
		weldTo(brim, head)
	end
	if torso then
		-- bow tie, gold buttons and a name badge on the jacket
		local tie = kit.deco(model, Vector3.new(0.7, 0.3, 0.12), torso.CFrame * CFrame.new(0, 0.82, -0.52), BLACK, Enum.Material.SmoothPlastic)
		weldTo(tie, torso)
		for k = 0, 2 do
			local b = kit.deco(model, Vector3.one * 0.16, torso.CFrame * CFrame.new(0, 0.35 - k * 0.42, -0.52), BRASS, Enum.Material.Metal, { shape = Enum.PartType.Ball })
			weldTo(b, torso)
		end
		local badge = kit.deco(model, Vector3.new(0.5, 0.18, 0.06), torso.CFrame * CFrame.new(-0.5, 0.45, -0.52), BRASS, Enum.Material.Metal)
		weldTo(badge, torso)
		-- the lapels: a slim gold edge either side
		for _, sx in { -0.28, 0.28 } do
			local lapel = kit.deco(model, Vector3.new(0.08, 1.2, 0.06), torso.CFrame * CFrame.new(sx, 0.2, -0.52) * CFrame.Angles(0, 0, sx * 0.5), BRASS, Enum.Material.Metal)
			weldTo(lapel, torso)
		end
	end
end

local function blockFigure(kit: any, model: Model, cf: CFrame, look: Look): (BasePart, BasePart)
	local function p(size: Vector3, off: CFrame, color: Color3, shape: Enum.PartType?): BasePart
		return kit.mk(model, size, cf * off, color, Enum.Material.SmoothPlastic, { shape = shape })
	end
	for _, sx in { -0.5, 0.5 } do
		p(Vector3.new(1, 2, 1), CFrame.new(sx, 1, 0), look.legs)
		p(Vector3.new(1, 2, 1), CFrame.new(sx * 3, 3, 0), look.jacket)
	end
	local torso = p(Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), look.jacket)
	local head = p(Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.7, 0), look.skin, Enum.PartType.Ball)
	return head, torso
end

-- a member of staff standing at cf (ground level, facing cf.LookVector)
local function staff(kit: any, parent: Instance, cf: CFrame, look: Look, name: string)
	task.spawn(function()
		local ok, rig = pcall(function()
			local d = Instance.new("HumanoidDescription")
			d.HeadColor = look.skin
			d.TorsoColor = look.jacket
			d.LeftArmColor = look.jacket
			d.RightArmColor = look.jacket
			d.LeftLegColor = look.legs
			d.RightLegColor = look.legs
			return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6)
		end)
		if ok and rig then
			local model = rig :: Model
			model.Name = name
			local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = model:FindFirstChildOfClass("Humanoid")
			if root then
				root.Anchored = true
			end
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			model:PivotTo(cf * CFrame.new(0, 3, 0))
			trim(kit, model, model:FindFirstChild("Head") :: BasePart?, model:FindFirstChild("Torso") :: BasePart?, look)
			model.Parent = parent
			-- Roblox's own standing idle
			if hum then
				pcall(function()
					local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
					animator.Parent = hum
					local anim = Instance.new("Animation")
					anim.AnimationId = "rbxassetid://180435571"
					local track = (animator :: Animator):LoadAnimation(anim)
					track.Looped = true
					track:Play()
				end)
			end
		else
			local model = Instance.new("Model")
			model.Name = name
			model.Parent = parent
			local head, torso = blockFigure(kit, model, cf, look)
			trim(kit, model, head, torso, look)
		end
	end)
end

---------------------------------------------------------------------
-- Building
---------------------------------------------------------------------
local function build(kit: any, parent: Instance, frame: CFrame, lot: number)
	local mk, deco = kit.mk, kit.deco
	local half = lot / 2
	local groundY = frame.Position.Y

	local model = Instance.new("Model")
	model.Name = "LegendsGrandHotel"
	model.Parent = parent

	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local function box(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return mk(par, Vector3.new(sx, sy, sz), at(x, y, z), color, mat, o)
	end
	local function dbox(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return deco(par, Vector3.new(sx, sy, sz), at(x, y, z), color, mat, o)
	end
	-- an upright cylinder (Roblox cylinders run along X)
	local function column(par: Instance, solid: boolean, d: number, h: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		local opts = o or {}
		opts.shape = Enum.PartType.Cylinder
		local f = if solid then mk else deco
		return f(par, Vector3.new(h, d, d), at(x, y + h / 2, z) * CFrame.Angles(0, 0, math.pi / 2), color, mat, opts)
	end
	local function disc(par: Instance, solid: boolean, d: number, t: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return column(par, solid, d, t, x, y, z, color, mat, o)
	end
	local function light(p: BasePart, color: Color3, range: number, brightness: number)
		kit.addLight("PointLight", p, color, range, brightness)
	end
	-- world centre and size of a box given in the hotel's frame (for axis-aligned helpers)
	local function worldBox(lx: number, lz: number, sx: number, sz: number): (number, number, number, number)
		local c = at(lx, 0, lz).Position
		local alongX = math.abs(frame.RightVector.X) > 0.5
		return c.X, c.Z, if alongX then sx else sz, if alongX then sz else sx
	end
	-- a Miami palm: a gently leaning ringed trunk, drooping fronds and coconuts
	local function palm(par: Instance, x: number, z: number, h: number, y0: number?)
		local base = y0 or 0
		local lean = (x * 0.37 + z * 0.11) % 1 * 0.5 - 0.25
		local top = at(x, base, z)
		local segs = 5
		for k = 0, segs - 1 do
			local a = top * CFrame.Angles(0, lean * 4, 0) * CFrame.new(0, (k + 0.5) * h / segs, 0) * CFrame.Angles(lean * 0.1 * k, 0, 0)
			deco(par, Vector3.new(h / segs + 0.2, 1.3 - k * 0.1, 1.3 - k * 0.1), a * CFrame.new(0, 0, -lean * k * 1.6) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 92, 70):Lerp(Color3.fromRGB(80, 66, 52), k / segs), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
		end
		local crown = top * CFrame.Angles(0, lean * 4, 0) * CFrame.new(0, h, -lean * segs * 1.6)
		for k = 0, 7 do
			local yaw = k * math.pi / 4 + lean
			deco(par, Vector3.new(1.6, 0.25, 11), crown * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(-28), 0, 0) * CFrame.new(0, 0, -5.2), LEAF:Lerp(Color3.fromRGB(70, 120, 56), (k % 3) / 3), Enum.Material.Grass, { shadow = true })
			deco(par, Vector3.new(1.2, 0.2, 6), crown * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(-28), 0, 0) * CFrame.new(0, 0, -10.5) * CFrame.Angles(math.rad(-30), 0, 0) * CFrame.new(0, 0, -2.6), LEAF, Enum.Material.Grass)
		end
		for k = 0, 2 do
			deco(par, Vector3.one * 0.9, crown * CFrame.Angles(0, k * 2.1, 0) * CFrame.new(0.7, -0.6, 0), Color3.fromRGB(90, 70, 40), Enum.Material.Wood, { shape = Enum.PartType.Ball })
		end
	end
	local function plant(par: Instance, x: number, y: number, z: number, s: number)
		dbox(par, 2.6 * s, 3 * s, 2.6 * s, x, y + 1.5 * s, z, CHARCOAL, Enum.Material.Slate)
		dbox(par, 2.8 * s, 0.25 * s, 2.8 * s, x, y + 3 * s, z, BRASS, Enum.Material.Metal)
		for k = 0, 2 do
			local a = k * 2.1
			deco(par, Vector3.one * 3 * s, at(x + math.cos(a) * 0.6 * s, y + (4 + k) * s, z + math.sin(a) * 0.6 * s), Color3.fromRGB(46, 92, 52), Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
	end
	-- a sofa facing local -z of cf, with seats you can sit on
	local function sofa(par: Instance, cf: CFrame, len: number, color: Color3)
		mk(par, Vector3.new(len, 2, 6), cf * CFrame.new(0, 1, 0), color:Lerp(BLACK, 0.35), Enum.Material.Fabric)
		deco(par, Vector3.new(len - 0.6, 1, 5), cf * CFrame.new(0, 2.4, -0.3), color, Enum.Material.Fabric)
		mk(par, Vector3.new(len, 4.2, 1.4), cf * CFrame.new(0, 3.1, 2.3), color, Enum.Material.Fabric)
		for _, sx in { -1, 1 } do
			mk(par, Vector3.new(1.2, 3.2, 6), cf * CFrame.new(sx * (len / 2 - 0.6), 1.6, 0), color, Enum.Material.Fabric)
		end
		local n = math.max(1, math.floor((len - 2) / 3.2))
		for k = 1, n do
			local s = Instance.new("Seat")
			s.Anchored = true
			s.Size = Vector3.new(2.6, 0.6, 2.6)
			s.CFrame = cf * CFrame.new(-(len - 2) / 2 + (k - 0.5) * (len - 2) / n, 2.8, -0.4)
			s.Transparency = 1
			s.CanCollide = false
			s.Parent = par
		end
	end
	---------------------------------------------------------------- the forecourt
	local court = kit.lodGroup(model, "Forecourt", at(0, 10, -80).Position, 600)
	-- granite paving over the whole front, darker pavers for the driveway
	dbox(court, lot, 0.12, half + PODIUM_Z0, 0, 0.06, (-half + PODIUM_Z0) / 2, Color3.fromRGB(70, 68, 72), Enum.Material.Granite)
	for _, sx in { -1, 1 } do
		dbox(court, 20, 0.16, half + BAY_Z + 10, sx * LANE_X, 0.08, (-half + BAY_Z + 10) / 2, PAVER, Enum.Material.Cobblestone)
	end
	dbox(court, LANE_X * 2 + 20, 0.16, 20, 0, 0.08, BAY_Z, PAVER, Enum.Material.Cobblestone)
	-- the right-hand lane's apron runs on into the valet garage
	dbox(court, 20, 0.16, BAY_Z - PODIUM_Z0 + 10, LANE_X, 0.09, (BAY_Z + PODIUM_Z0) / 2 + 5, PAVER, Enum.Material.Cobblestone)
	-- dropped kerbs: little ramps from the street up onto the driveway (they sit on the road)
	for _, sx in { -1, 1 } do
		mk(court, Vector3.new(20, CURB, 6), at(sx * LANE_X, -CURB / 2, -half - Config.City.SidewalkWidth - 3), Color3.fromRGB(110, 110, 116), Enum.Material.Concrete, { class = "Wedge", name = "KerbRamp" })
		-- arrows: in on the left, out on the right
		local arrow = dbox(court, 6, 0.05, 6, sx * LANE_X, 0.2, -half + 14, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Top
		g.CanvasSize = Vector2.new(100, 100)
		g.LightInfluence = 0.5
		g.Parent = arrow
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Text = if sx < 0 then "IN" else "OUT"
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.fromRGB(235, 235, 230)
		t.TextTransparency = 0.25
		t.Rotation = 180
		t.Parent = g
	end
	-- the island: lawn in a stone kerb, a fountain, palms and the name stone
	local islandW, islandZ0, islandZ1 = (LANE_X - 10) * 2, -half, BAY_Z - 10
	local islandD = islandZ1 - islandZ0
	box(court, islandW, 0.9, islandD, 0, 0.45, (islandZ0 + islandZ1) / 2, STONE, Enum.Material.Limestone)
	dbox(court, islandW - 3, 0.2, islandD - 3, 0, 0.95, (islandZ0 + islandZ1) / 2, Color3.fromRGB(40, 70, 40), Enum.Material.Grass)
	local fz = (islandZ0 + islandZ1) / 2 + 4
	disc(court, true, 24, 2.4, 0, 0.9, fz, MARBLE, Enum.Material.Marble)
	disc(court, false, 22, 0.4, 0, 2.9, fz, WATER, Enum.Material.Glass, { transparency = 0.25, reflectance = 0.3 })
	disc(court, false, 22.6, 0.3, 0, 2.6, fz, PINK, Enum.Material.Neon, { transparency = 0.5 })
	column(court, true, 3.6, 5, 0, 3.3, fz, MARBLE, Enum.Material.Marble)
	disc(court, true, 9, 0.8, 0, 8.3, fz, MARBLE, Enum.Material.Marble)
	local nozzle = dbox(court, 0.6, 0.6, 0.6, 0, 9.4, fz, MARBLE, Enum.Material.Marble)
	local jet = Instance.new("ParticleEmitter")
	jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	jet.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
	jet.LightEmission = 0.6
	jet.Size = NumberSequence.new(0.7, 0.2)
	jet.Transparency = NumberSequence.new(0.3, 1)
	jet.Speed = NumberRange.new(16, 20)
	jet.SpreadAngle = Vector2.new(10, 10)
	jet.Acceleration = Vector3.new(0, -30, 0)
	jet.Lifetime = NumberRange.new(1.1, 1.4)
	jet.Rate = 80
	jet.EmissionDirection = Enum.NormalId.Top
	jet.Parent = nozzle
	local glow = dbox(court, 1, 0.4, 1, 0, 3.2, fz, TEAL, Enum.Material.Neon)
	light(glow, TEAL, 24, 1.2)
	for _, sx in { -1, 1 } do
		palm(court, sx * (islandW / 2 - 10), islandZ0 + 12, 30, 1)
		palm(court, sx * (islandW / 2 - 14), islandZ1 - 9, 26, 1)
		palm(court, sx * 34, fz, 34, 1)
	end
	-- the name stone at the front of the island, lit from below
	local stone = box(court, 46, 7, 3, 0, 4.4, islandZ0 + 4, STONE, Enum.Material.Limestone)
	local stoneText = dbox(court, 42, 5, 0.2, 0, 4.6, islandZ0 + 2.4, BLACK, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(stoneText, Enum.NormalId.Front, H.Name .. "\nHOTEL  ·  SUITES", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(800, 170))
	dbox(court, 46.4, 0.3, 0.3, 0, 1.1, islandZ0 + 2.3, GOLD, Enum.Material.Neon)
	kit.addLight("SpotLight", stone, WARM, 18, 1.4, Enum.NormalId.Front, 70)
	-- art deco lamp posts along the island's sides
	for _, sx in { -1, 1 } do
		for _, z in { islandZ0 + 24, islandZ1 - 24 } do
			local x = sx * (islandW / 2 - 1.5)
			column(court, true, 0.7, 14, x, 0.9, z, BLACK, Enum.Material.Metal)
			local lamp = dbox(court, 1.6, 3, 1.6, x, 16.4, z, WARM, Enum.Material.Neon, { transparency = 0.15 })
			dbox(court, 2.2, 0.4, 2.2, x, 18.1, z, BRASS, Enum.Material.Metal)
			light(lamp, WARM, 30, 1.1)
		end
	end

	-- the porte-cochere canopy over the cross lane, with the name on its fascia
	local cz0, cz1 = BAY_Z - 18, PODIUM_Z0 - 0.5
	local canopyD = cz1 - cz0
	local canopyZ = (cz0 + cz1) / 2
	box(model, 124, 2.6, canopyD, 0, 20.3, canopyZ, BLACK, Enum.Material.Metal, { shadow = true, name = "Canopy" })
	dbox(court, 124.4, 0.3, canopyD + 0.4, 0, 18.9, canopyZ, GOLD, Enum.Material.Neon, { transparency = 0.55 })
	dbox(model, 125, 0.5, 0.5, 0, 21.85, cz0 - 0.1, GOLD, Enum.Material.Neon)
	dbox(model, 125, 0.4, 0.4, 0, 18.75, cz0 - 0.1, PINK, Enum.Material.Neon)
	local fascia = dbox(model, 96, 4.6, 0.4, 0, 24.6, cz0 + 1, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(fascia, Enum.NormalId.Front, H.Name, GOLD:Lerp(Color3.new(1, 1, 1), 0.25), nil, nil, Enum.Font.Garamond, Vector2.new(1400, 90))
	dbox(model, 96, 0.3, 0.5, 0, 22.2, cz0 + 0.8, GOLD, Enum.Material.Metal)
	for _, sx in { -1, 1 } do
		column(model, true, 2.2, 19, sx * 58, 0.9, cz0 + 2, BRASS, Enum.Material.Metal, { reflectance = 0.25 })
		column(model, false, 2.8, 1.2, sx * 58, 0.9, cz0 + 2, BLACK, Enum.Material.Metal)
	end
	-- warm downlights in the canopy's underside
	for _, x in { -48, -24, 0, 24, 48 } do
		local dl = dbox(court, 3.2, 0.2, 3.2, x, 18.85, canopyZ - 4, WARM, Enum.Material.Neon)
		kit.addLight("SpotLight", dl, WARM, 26, 1.5, Enum.NormalId.Bottom, 110)
	end
	-- the valet bay: box lines and VALET painted on the paving
	local bayCenter = at(0, 0, BAY_Z)
	for _, sx in { -1, 1 } do
		dbox(court, 0.4, 0.06, 18, sx * 13, 0.2, BAY_Z, Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
		dbox(court, 26.4, 0.06, 0.4, 0, 0.2, BAY_Z + sx * 9, Color3.fromRGB(240, 200, 60), Enum.Material.SmoothPlastic)
	end
	local bayWord = dbox(court, 16, 0.05, 5, 0, 0.21, BAY_Z + 5, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
	local bg = Instance.new("SurfaceGui")
	bg.Face = Enum.NormalId.Top
	bg.CanvasSize = Vector2.new(320, 100)
	bg.LightInfluence = 0.6
	bg.Parent = bayWord
	local bt = Instance.new("TextLabel")
	bt.BackgroundTransparency = 1
	bt.Size = UDim2.fromScale(1, 1)
	bt.Text = "VALET"
	bt.TextScaled = true
	bt.Font = Enum.Font.GothamBlack
	bt.TextColor3 = Color3.fromRGB(240, 200, 60)
	bt.Rotation = 180
	bt.Parent = bg
	local bay = dbox(model, 26, 1, 18, 0, 0.5, BAY_Z, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1, name = "ValetBay" })
	CollectionService:AddTag(bay, "HotelValetBay")

	-- the entrance apron: red carpet, brass bollards on the lane's edge
	dbox(court, 14, 0.2, PODIUM_Z0 - BAY_Z - 10, 0, 0.2, (PODIUM_Z0 + BAY_Z + 10) / 2, Color3.fromRGB(120, 18, 26), Enum.Material.Fabric)
	for x = -70, 70, 14 do
		if math.abs(x) > 10 then
			column(court, true, 0.9, 3, x, 0.1, BAY_Z + 10.5, BRASS, Enum.Material.Metal, { reflectance = 0.3 })
			disc(court, false, 1.1, 0.3, x, 3.1, BAY_Z + 10.5, WARM, Enum.Material.Neon)
		end
	end

	-- the valet stand (left of the doors): a walnut lectern with a key cabinet behind it
	local standX, standZ = -34, PODIUM_Z0 - 6
	box(court, 6, 4.2, 3, standX, 2.1, standZ, WALNUT, Enum.Material.Wood)
	dbox(court, 6.4, 0.3, 3.4, standX, 4.35, standZ, MARBLE, Enum.Material.Marble)
	dbox(court, 6.2, 0.2, 0.2, standX, 0.6, standZ - 1.55, GOLD, Enum.Material.Neon)
	local standTop = dbox(court, 2, 0.4, 1.4, standX, 4.7, standZ, BRASS, Enum.Material.Metal, { name = "ValetStand" })
	local keys = dbox(court, 8, 8, 1, standX, 6, PODIUM_Z0 - 1, WALNUT, Enum.Material.Wood)
	for r = 0, 2 do
		for c = 0, 4 do
			dbox(court, 0.3, 0.8, 0.2, standX - 3 + c * 1.5, 3.6 + r * 2.2, PODIUM_Z0 - 1.6, BRASS, Enum.Material.Metal)
		end
	end
	light(keys, WARM, 10, 0.6)
	dbox(court, 0.4, 9, 0.4, standX - 4.5, 4.5, standZ, BLACK, Enum.Material.Metal)
	local valetPlate = dbox(court, 6, 2, 0.3, standX - 4.5, 10, standZ, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(valetPlate, Enum.NormalId.Front, "VALET", GOLD, nil, nil, Enum.Font.GothamBold, Vector2.new(300, 100))
	local getCar = prompt(standTop, "Get my car", "Valet", Enum.KeyCode.E, 0.4, 12)
	CollectionService:AddTag(getCar, "HotelValetStand")
	getCar.Triggered:Connect(function(player: Player)
		Hotel.retrieve(player)
	end)

	-- the staff: two valets by the bay, one at the stand, the concierge at reception
	local valet: Look = { jacket = BURGUNDY, legs = Color3.fromRGB(20, 20, 24), skin = Color3.fromRGB(196, 150, 116), cap = true }
	local valet2: Look = { jacket = BURGUNDY, legs = Color3.fromRGB(20, 20, 24), skin = Color3.fromRGB(120, 84, 60), cap = true }
	local valet3: Look = { jacket = BURGUNDY, legs = Color3.fromRGB(20, 20, 24), skin = Color3.fromRGB(232, 196, 166), cap = true }
	staff(kit, court, at(standX, 0, PODIUM_Z0 - 2.6) * CFrame.Angles(0, 0, 0), valet, "Valet")
	staff(kit, court, at(18, 0.2, BAY_Z + 12) * CFrame.Angles(0, math.rad(-20), 0), valet2, "Valet")
	staff(kit, court, at(30, 0.2, BAY_Z + 13) * CFrame.Angles(0, math.rad(15), 0), valet3, "Valet")

	---------------------------------------------------------------- the podium
	-- wings either side of the lobby: boutiques on the left, the valet garage on the right
	box(model, WING_X - LOBBY_X, PODIUM_TOP, PODIUM_Z1 - PODIUM_Z0, -(WING_X + LOBBY_X) / 2, PODIUM_TOP / 2, (PODIUM_Z0 + PODIUM_Z1) / 2, STONE, Enum.Material.Limestone, { name = "WingLeft" })
	local gz0 = -10 -- the garage recess goes in to here
	box(model, WING_X - LOBBY_X, PODIUM_TOP, PODIUM_Z1 - gz0, (WING_X + LOBBY_X) / 2, PODIUM_TOP / 2, (gz0 + PODIUM_Z1) / 2, STONE, Enum.Material.Limestone, { name = "WingRight" })
	local doorW, doorH = 20, 15
	local gx0, gx1 = LANE_X - doorW / 2, LANE_X + doorW / 2
	box(model, WING_X - LOBBY_X, PODIUM_TOP - doorH, gz0 - PODIUM_Z0, (WING_X + LOBBY_X) / 2, doorH + (PODIUM_TOP - doorH) / 2, (PODIUM_Z0 + gz0) / 2, STONE, Enum.Material.Limestone)
	box(model, gx0 - LOBBY_X, doorH, gz0 - PODIUM_Z0, (gx0 + LOBBY_X) / 2, doorH / 2, (PODIUM_Z0 + gz0) / 2, STONE, Enum.Material.Limestone)
	box(model, WING_X - gx1, doorH, gz0 - PODIUM_Z0, (gx1 + WING_X) / 2, doorH / 2, (PODIUM_Z0 + gz0) / 2, STONE, Enum.Material.Limestone)
	dbox(model, doorW, doorH, 0.4, LANE_X, doorH / 2, gz0 - 0.4, BLACK, Enum.Material.SmoothPlastic) -- the dark inside
	dbox(model, doorW, 0.2, gz0 - PODIUM_Z0, LANE_X, 0.2, (PODIUM_Z0 + gz0) / 2, Color3.fromRGB(26, 26, 28), Enum.Material.Concrete)
	local gSign = dbox(model, doorW + 2, 3, 0.3, LANE_X, doorH + 2.6, PODIUM_Z0 - 0.3, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(gSign, Enum.NormalId.Front, "VALET GARAGE", TEAL, nil, nil, Enum.Font.GothamBold, Vector2.new(500, 80))
	dbox(model, doorW + 1, 0.4, 0.4, LANE_X, doorH + 0.4, PODIUM_Z0 - 0.4, TEAL, Enum.Material.Neon)
	-- boutique windows in the left wing
	local wingW = WING_X - LOBBY_X
	for k, name in { "ATELIER", "THE SPA" } do
		local x = -LOBBY_X - wingW * (if k == 1 then 0.28 else 0.72)
		dbox(model, wingW * 0.4, 14, 0.3, x, 8, PODIUM_Z0 - 0.2, Color3.fromRGB(160, 130, 96), Enum.Material.Neon, { transparency = 0.35 })
		local s = dbox(model, wingW * 0.4, 2.4, 0.3, x, 17, PODIUM_Z0 - 0.3, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(s, Enum.NormalId.Front, name, GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(400, 70))
	end
	-- the lobby's front: stone piers, gold mullions and tall glass, the doors in the middle
	box(model, LOBBY_X * 2, PODIUM_TOP - 30, 2, 0, 30 + (PODIUM_TOP - 30) / 2, PODIUM_Z0 + 1, STONE, Enum.Material.Limestone) -- transom
	for _, seg in { { -LOBBY_X, -10 }, { 10, LOBBY_X } } do
		local len = seg[2] - seg[1]
		box(model, len, 29.5, 0.5, (seg[1] + seg[2]) / 2, 0.5 + 14.75, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.75, reflectance = 0.15, shadow = false })
		for x = seg[1], seg[2], 8 do
			dbox(model, if math.abs(x) % 32 == 0 then 2.4 else 0.5, 29.5, 0.8, x, 0.5 + 14.75, PODIUM_Z0 + 0.4, if math.abs(x) % 32 == 0 then STONE else BRASS, if math.abs(x) % 32 == 0 then Enum.Material.Limestone else Enum.Material.Metal)
		end
	end
	-- the doors: a revolving door (walk straight through) under a gold sunburst
	column(model, false, 14, 13, 0, 0.5, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.85 })
	for k = 0, 3 do
		dbox(model, 0.2, 13, 6.5, 0, 7, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.7 }).CFrame = at(0, 7, PODIUM_Z0 + 1) * CFrame.Angles(0, k * math.pi / 2 + 0.4, 0) * CFrame.new(0, 0, 3.25)
	end
	disc(model, false, 15, 0.6, 0, 13.5, PODIUM_Z0 + 1, BRASS, Enum.Material.Metal)
	for k = -4, 4 do
		dbox(model, 0.3, 10, 0.3, 0, 19, PODIUM_Z0 + 0.2, GOLD, Enum.Material.Neon, { transparency = 0.2 }).CFrame = at(0, 14.2, PODIUM_Z0 + 0.2) * CFrame.Angles(0, 0, k * 0.3) * CFrame.new(0, 5, 0)
	end
	-- the podium roof: a slab, neon edge, planters and palms
	box(model, WING_X * 2 + 2, 2, PODIUM_Z1 - PODIUM_Z0 + 2, 0, PODIUM_TOP - 1, (PODIUM_Z0 + PODIUM_Z1) / 2, CHARCOAL, Enum.Material.Concrete, { name = "PodiumRoof" })
	local rx, rz, rw, rd = worldBox(0, (PODIUM_Z0 + PODIUM_Z1) / 2, WING_X * 2 + 2, PODIUM_Z1 - PODIUM_Z0 + 2)
	kit.neonOutline(model, rx, rz, rw, rd, groundY + PODIUM_TOP + 0.2, TEAL, 0.5)
	kit.neonOutline(model, rx, rz, rw + 0.6, rd + 0.6, groundY + PODIUM_TOP - 3, PINK, 0.35)
	local roofDeco = kit.lodGroup(model, "PodiumTerrace", at(0, PODIUM_TOP, 0).Position, 700)
	for _, sx in { -1, 1 } do
		for _, z in { PODIUM_Z0 + 8, PODIUM_Z1 - 8 } do
			box(roofDeco, 8, 3, 8, sx * (WING_X - 8), PODIUM_TOP + 1.5, z, STONE, Enum.Material.Limestone)
			palm(roofDeco, sx * (WING_X - 8), z, 22, PODIUM_TOP + 3)
		end
	end
	-- uplights washing the tower's front
	for _, x in { -54, -18, 18, 54 } do
		local up = dbox(roofDeco, 2, 1, 2, x, PODIUM_TOP + 0.5, TOWER_Z - BODY1.d / 2 - 4, CHARCOAL, Enum.Material.Metal)
		kit.addLight("SpotLight", up, WARM, 60, 2.2, Enum.NormalId.Top, 40)
	end

	---------------------------------------------------------------- the grand lobby
	local lobby = kit.lodGroup(model, "Lobby", at(0, LH / 2, 30).Position, 380)
	box(model, LOBBY_X * 2, 0.5, PODIUM_Z1 - PODIUM_Z0 - 2, 0, 0.25, (PODIUM_Z0 + PODIUM_Z1) / 2, MARBLE, Enum.Material.Marble, { name = "LobbyFloor" })
	box(model, LOBBY_X * 2, 1.5, PODIUM_Z1 - PODIUM_Z0, 0, LH + 0.75, (PODIUM_Z0 + PODIUM_Z1) / 2, CREAM, Enum.Material.SmoothPlastic, { name = "LobbyCeiling" })
	box(model, LOBBY_X * 2, LH, 2, 0, LH / 2, PODIUM_Z1 - 1, STONE, Enum.Material.Limestone) -- back wall
	box(model, 2, LH, gz0 - PODIUM_Z0, LOBBY_X - 1, LH / 2, (PODIUM_Z0 + gz0) / 2, STONE, Enum.Material.Limestone) -- beside the garage
	-- coffered ceiling: gold ribs
	for x = -64, 64, 32 do
		dbox(lobby, 0.8, 0.6, PODIUM_Z1 - PODIUM_Z0 - 4, x, LH - 0.3, (PODIUM_Z0 + PODIUM_Z1) / 2, BRASS, Enum.Material.Metal)
	end
	for z = PODIUM_Z0 + 10, PODIUM_Z1 - 10, 24 do
		dbox(lobby, LOBBY_X * 2 - 4, 0.6, 0.8, 0, LH - 0.3, z, BRASS, Enum.Material.Metal)
	end
	-- the floor: a black marble border and a compass star of gold in the middle
	dbox(lobby, 44, 0.06, 44, 0, 0.53, 20, MARBLE_DARK, Enum.Material.Marble)
	dbox(lobby, 40, 0.08, 40, 0, 0.55, 20, MARBLE, Enum.Material.Marble)
	disc(lobby, false, 30, 0.1, 0, 0.56, 20, MARBLE_DARK, Enum.Material.Marble)
	disc(lobby, false, 26, 0.12, 0, 0.57, 20, MARBLE, Enum.Material.Marble)
	for k = 0, 7 do
		dbox(lobby, 1.6, 0.14, if k % 2 == 0 then 24 else 14, 0, 0.6, 20, GOLD, Enum.Material.Metal).CFrame = at(0, 0.6, 20) * CFrame.Angles(0, k * math.pi / 4, 0)
	end
	-- a red runner from the doors to the star
	dbox(lobby, 10, 0.1, 32, 0, 0.55, PODIUM_Z0 + 17, Color3.fromRGB(120, 18, 26), Enum.Material.Fabric)
	-- marble columns with gold capitals
	for _, sx in { -1, 1 } do
		for _, z in { -18, 14, 46, 74 } do
			local x = sx * 38
			column(model, true, 6, LH - 1, x, 0.5, z, MARBLE, Enum.Material.Marble)
			column(lobby, false, 7.4, 1.6, x, 0.5, z, BRASS, Enum.Material.Metal)
			column(lobby, false, 7.6, 2.2, x, LH - 2.6, z, BRASS, Enum.Material.Metal)
			local sconce = dbox(lobby, 1.2, 2.4, 0.6, x, 12, z - sx * 0 - 3.4, WARM, Enum.Material.Neon, { transparency = 0.2 })
			light(sconce, WARM, 16, 0.6)
		end
	end
	-- chandeliers: tiers of glowing rings with crystal drops
	for _, z in { -10, 24, 58 } do
		for k, r in { 22, 15, 8 } do
			local ring = disc(lobby, false, r, 0.5, 0, LH - 5 - k * 2, z, WARM, Enum.Material.Neon, { transparency = 0.15 })
			if k == 2 then
				light(ring, WARM, 46, 1.5)
			end
		end
		dbox(lobby, 0.2, 4, 0.2, 0, LH - 2.5, z, BRASS, Enum.Material.Metal)
		for k = 0, 9 do
			local a = k * math.pi / 5
			deco(lobby, Vector3.new(0.5, 1.4, 0.5), at(math.cos(a) * 10.5, LH - 8.6, z + math.sin(a) * 10.5), Color3.fromRGB(230, 240, 255), Enum.Material.Glass, { transparency = 0.2, reflectance = 0.5 })
		end
	end
	-- reception (left): a long walnut desk with a marble top, the hotel's name on a lit wall
	local rxD = -60
	box(lobby, 4, 4.2, 40, rxD, 2.6, 18, WALNUT, Enum.Material.Wood)
	dbox(lobby, 4.6, 0.4, 40.6, rxD, 4.9, 18, MARBLE, Enum.Material.Marble)
	dbox(lobby, 0.2, 0.25, 40, rxD + 2.15, 1, 18, GOLD, Enum.Material.Neon)
	local wall = box(lobby, 1.4, 22, 48, -LOBBY_X + 0.7, 11.5, 18, WALNUT, Enum.Material.Wood)
	local wallSign = dbox(lobby, 0.3, 6, 40, -LOBBY_X + 1.6, 15, 18, BLACK, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(wallSign, Enum.NormalId.Right, H.Name, GOLD:Lerp(Color3.new(1, 1, 1), 0.2), nil, nil, Enum.Font.Garamond, Vector2.new(1100, 140))
	dbox(lobby, 0.3, 0.3, 40, -LOBBY_X + 1.6, 11, 18, GOLD, Enum.Material.Neon)
	light(wall, WARM, 26, 0.9)
	local recSign = dbox(lobby, 0.3, 2, 14, rxD + 2.4, 6.6, 18, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(recSign, Enum.NormalId.Right, "RECEPTION", GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(500, 70))
	for _, z in { 6, 30 } do
		dbox(lobby, 1, 1.6, 1, rxD, 5.9, z, BRASS, Enum.Material.Metal)
		local shade = dbox(lobby, 1.8, 1.2, 1.8, rxD, 7.2, z, CREAM, Enum.Material.Neon, { transparency = 0.15 })
		light(shade, WARM, 12, 0.7)
	end
	local concierge: Look = { jacket = Color3.fromRGB(26, 28, 36), legs = Color3.fromRGB(20, 20, 24), skin = Color3.fromRGB(160, 116, 86), cap = false }
	staff(kit, lobby, at(rxD - 5, 0.5, 18) * CFrame.Angles(0, -math.pi / 2, 0), concierge, "Concierge")
	-- the lounge (right): sofas round low tables, plants and a grand piano
	for _, z in { -24, 6 } do
		sofa(lobby, at(60, 0.5, z - 7) * CFrame.Angles(0, 0, 0), 16, CREAM)
		sofa(lobby, at(60, 0.5, z + 7) * CFrame.Angles(0, math.pi, 0), 16, CREAM)
		box(lobby, 9, 1.4, 5, 60, 1.2, z, MARBLE_DARK, Enum.Material.Marble)
		dbox(lobby, 9.2, 0.2, 5.2, 60, 1.95, z, BRASS, Enum.Material.Metal)
		dbox(lobby, 20, 0.08, 22, 60, 0.55, z, Color3.fromRGB(70, 58, 52), Enum.Material.Fabric)
	end
	local px, pz = 50, 32
	box(lobby, 7, 1.6, 9, px, 4.2, pz, BLACK, Enum.Material.SmoothPlastic, { reflectance = 0.3 })
	dbox(lobby, 7, 0.2, 8, px, 6.4, pz + 1.2, BLACK, Enum.Material.SmoothPlastic, { reflectance = 0.3 }).CFrame = at(px, 6.6, pz + 1.6) * CFrame.Angles(math.rad(-30), 0, 0)
	dbox(lobby, 6.4, 0.3, 1.2, px, 4.8, pz - 4.8, Color3.fromRGB(240, 240, 236), Enum.Material.SmoothPlastic)
	for _, o in { { -3, -3.6 }, { 3, -3.6 }, { 0, 4 } } do
		dbox(lobby, 0.7, 3.4, 0.7, px + o[1], 2.2, pz + o[2], BLACK, Enum.Material.SmoothPlastic)
	end
	box(lobby, 5, 1, 2, px, 2.3, pz - 7.2, BLACK, Enum.Material.Fabric)
	plant(lobby, 70, 0.5, -34, 1.3)
	plant(lobby, 70, 0.5, 40, 1.3)
	plant(lobby, -70, 0.5, -34, 1.3)
	plant(lobby, -26, 0.5, -34, 1.1)
	plant(lobby, 26, 0.5, -34, 1.1)

	-- the suite sales gallery (right, at the back): a glowing model of each suite on a plinth
	local suites = H.Suites
	for k, s in suites do
		local z = 44 + (k - 1) * 10
		box(lobby, 4, 4, 4, 66, 2.5, z, BLACK, Enum.Material.SmoothPlastic)
		dbox(lobby, 4.2, 0.2, 4.2, 66, 4.6, z, GOLD, Enum.Material.Metal)
		local mini = dbox(lobby, 1.6, 2 + k * 0.8, 1.6, 66, 5.7 + k * 0.4, z, Color3.fromRGB(30, 40, 56), Enum.Material.Glass, { reflectance = 0.3 })
		dbox(lobby, 1.7, 0.3, 1.7, 66, 4.7 + 2 + k * 0.8 + 0.2, z, GOLD, Enum.Material.Neon)
		local card = dbox(lobby, 0.2, 2.2, 3.6, 63.9, 3, z, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(card, Enum.NormalId.Left, s.name .. "\n" .. money(s.price) .. "  ·  " .. money(s.perMinute) .. "/min", GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(300, 120))
		local buy = prompt(mini, "Buy suite", titleCase(s.name) .. "  " .. money(s.price), Enum.KeyCode.E, 1.5, 9)
		CollectionService:AddTag(buy, "TowerBuy")
		buy:SetAttribute("Tower", s.id)
		buy:SetAttribute("Price", s.price)
		buy.Triggered:Connect(function(player: Player)
			Towers.buy(player, s.id)
		end)
	end
	local gallerySign = dbox(lobby, 0.3, 2.4, 20, 69, 11, 59, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(gallerySign, Enum.NormalId.Left, "SUITE SALES", GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(600, 70))

	-- the elevator bank: one car per suite and one to the roof, under the residents' board
	box(model, 108, LH, PODIUM_Z1 - 2 - ELEVATOR_Z, 0, LH / 2, (ELEVATOR_Z + PODIUM_Z1 - 2) / 2, MARBLE_DARK, Enum.Material.Marble, { name = "ElevatorCore" })
	local lobbyStops: { CFrame } = {}
	local doors = { -40, -20, 0, 20, 40 }
	for k, x in doors do
		local isRoof = k > #suites
		dbox(lobby, 12, 15, 0.6, x, 7.5 + 0.5, ELEVATOR_Z - 0.3, MARBLE, Enum.Material.Marble)
		for _, sx in { -1, 1 } do
			dbox(lobby, 3.6, 11.5, 0.3, x + sx * 1.85, 6.25, ELEVATOR_Z - 0.7, BRASS, Enum.Material.Metal, { reflectance = 0.35 })
		end
		dbox(lobby, 0.1, 11.5, 0.32, x, 6.25, ELEVATOR_Z - 0.72, BLACK, Enum.Material.SmoothPlastic)
		local label = if isRoof then "ROOF TERRACE" else suites[k].name
		local plate = dbox(lobby, 10, 1.8, 0.2, x, 13.6, ELEVATOR_Z - 0.75, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(plate, Enum.NormalId.Front, label, GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(400, 70))
		local panel = dbox(lobby, 1, 2.4, 0.3, x + 5.2, 5.5, ELEVATOR_Z - 0.75, BRASS, Enum.Material.Metal, { reflectance = 0.3 })
		dbox(lobby, 0.5, 0.5, 0.1, x + 5.2, 6, ELEVATOR_Z - 0.95, if isRoof then TEAL else GOLD, Enum.Material.Neon)
		local id = if isRoof then suites[#suites].id else suites[k].id
		local p = prompt(panel, if isRoof then "Up to the roof" else "Up to " .. titleCase(suites[k].name), "Elevator", Enum.KeyCode.E, 0, 10)
		p.Triggered:Connect(function(player: Player)
			Towers.travel(player, id, if isRoof then "roof" else "penthouse")
		end)
		lobbyStops[k] = at(x, 3.7, ELEVATOR_Z - 6) -- facing out of the doors
	end
	-- the residents' board above the elevators
	local boardPart = dbox(lobby, 70, 11, 0.3, 0, 25, ELEVATOR_Z - 0.5, BLACK, Enum.Material.SmoothPlastic)
	dbox(lobby, 70.6, 11.6, 0.2, 0, 25, ELEVATOR_Z - 0.35, BRASS, Enum.Material.Metal)
	local _, _, boardLabel = kit.surfaceText(boardPart, Enum.NormalId.Front, "", GOLD:Lerp(Color3.new(1, 1, 1), 0.35), nil, nil, Enum.Font.GothamMedium, Vector2.new(1200, 190))

	---------------------------------------------------------------- the tower
	local pal = kit.randomPalette("glass")
	pal.body = Color3.fromRGB(18, 26, 34)
	pal.fin = Color3.fromRGB(176, 146, 100)
	pal.finMat = Enum.Material.Metal
	pal.warm = true
	pal.lit = 0.55
	local fine1 = kit.lodGroup(model, "Facade1", at(0, (BODY1.y0 + BODY1.y1) / 2, TOWER_Z).Position, 900)
	local bx, bz, bw, bd = worldBox(0, TOWER_Z, BODY1.w, BODY1.d)
	kit.facadeTier(model, bx, bz, bw, bd, groundY + BODY1.y0, groundY + BODY1.y1, pal, true, nil, fine1)
	box(model, BODY1.w + 1, 1.4, BODY1.d + 1, 0, BODY1.y1 + 0.7, TOWER_Z, CHARCOAL, Enum.Material.Concrete, { name = "Terrace" })
	kit.neonOutline(model, bx, bz, bw + 1, bd + 1, groundY + BODY1.y1 + 1.5, GOLD, 0.5)
	local fine2 = kit.lodGroup(model, "Facade2", at(0, (BODY2.y0 + BODY2.y1) / 2, TOWER_Z).Position, 1000)
	local b2x, b2z, b2w, b2d = worldBox(0, TOWER_Z, BODY2.w, BODY2.d)
	kit.facadeTier(model, b2x, b2z, b2w, b2d, groundY + BODY2.y0, groundY + BODY2.y1, pal, true, nil, fine2)
	box(model, BODY2.w + 1, 1.4, BODY2.d + 1, 0, BODY2.y1 + 0.7, TOWER_Z, CHARCOAL, Enum.Material.Concrete, { name = "Terrace" })
	kit.neonOutline(model, b2x, b2z, b2w + 1, b2d + 1, groundY + BODY2.y1 + 1.5, GOLD, 0.5)
	-- art deco neon: pink and teal fins up the front and back, gold corner lines
	for _, face in { -1, 1 } do
		for k, x in { -48, -24, 24, 48 } do
			local c = if k % 2 == 0 then TEAL else PINK
			dbox(model, 0.7, BODY1.y1 - BODY1.y0 - 6, 0.7, x, (BODY1.y0 + BODY1.y1) / 2, TOWER_Z + face * (BODY1.d / 2 + 0.6), c, Enum.Material.Neon, { transparency = 0.1 })
		end
		for _, x in { -30, 30 } do
			dbox(model, 0.7, BODY2.y1 - BODY2.y0 - 16, 0.7, x, (BODY2.y0 + BODY2.y1) / 2 - 5, TOWER_Z + face * (BODY2.d / 2 + 0.6), PINK, Enum.Material.Neon, { transparency = 0.1 })
		end
		for _, sx in { -1, 1 } do
			dbox(model, 0.6, BODY1.y1 - BODY1.y0, 0.6, sx * (BODY1.w / 2 + 0.5), (BODY1.y0 + BODY1.y1) / 2, TOWER_Z + face * (BODY1.d / 2 + 0.5), GOLD, Enum.Material.Neon, { transparency = 0.15 })
		end
	end
	-- the vertical HOTEL sign on the front corner
	local bladeZ = TOWER_Z - BODY1.d / 2 - 9
	local blade = box(model, 3, 150, 18, -BODY1.w / 2 + 8, BODY1.y0 + 40 + 75, bladeZ, BLACK, Enum.Material.SmoothPlastic, { name = "HotelSign" })
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		local _, _, lbl = kit.surfaceText(blade, face, "H\nO\nT\nE\nL", PINK, nil, nil, Enum.Font.GothamBlack, Vector2.new(140, 1000))
		lbl.LineHeight = 0.9
	end
	for _, sx in { -1, 1 } do
		dbox(model, 3.4, 151, 0.5, -BODY1.w / 2 + 8, BODY1.y0 + 115, bladeZ + sx * 9, PINK, Enum.Material.Neon)
	end
	dbox(model, 3.4, 0.5, 18.4, -BODY1.w / 2 + 8, BODY1.y0 + 190.5, bladeZ, PINK, Enum.Material.Neon)
	dbox(model, 3.4, 0.5, 18.4, -BODY1.w / 2 + 8, BODY1.y0 + 39.5, bladeZ, PINK, Enum.Material.Neon)
	-- the name round the top of the tower, under the crown
	local band = deco(model, Vector3.new(b2w + 0.8, 10, b2d + 0.8), CFrame.new(b2x, groundY + BODY2.y1 - 6, b2z), BLACK, Enum.Material.SmoothPlastic)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local _, _, label = kit.surfaceText(band, face, H.Name, Color3.new(1, 1, 1), BLACK, 0, Enum.Font.Garamond, Vector2.new(1200, 110))
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, GOLD) })
		grad.Parent = label
	end

	---------------------------------------------------------------- the crown: the suites
	local suiteFrame = frame * CFrame.new(0, 0, TOWER_Z)
	local stops: { { [string]: CFrame } } = {}
	for k, s in suites do
		local spec = {
			id = s.id,
			name = s.name,
			block = { -1, -1 },
			height = 0,
			price = s.price,
			rent = 0,
			accent = GOLD,
			perMinute = s.perMinute,
			levelName = titleCase(s.name),
		}
		stops[k] = Towers.suite(kit, model, spec, { frame = suiteFrame, yP = CROWN_Y + (k - 1) * SUITE_STEP, roof = k == #suites })
	end
	local roofStop = stops[#suites].roof
	for k, st in stops do
		st.lobby = lobbyStops[k]
		if k < #suites then
			st.roof = roofStop
		end
	end
	-- gold fins at the crown's corners, rising past the roof with lit tips
	local roofTop = CROWN_Y + (#suites - 1) * SUITE_STEP + 30 + 1.5
	local finTop = roofTop + 44
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * 44.2, TOWER_Z + sz * 44.2
			box(model, 1.8, finTop - CROWN_Y + 2, 1.8, x, (CROWN_Y - 2 + finTop) / 2, z, BRASS, Enum.Material.Metal, { reflectance = 0.25 })
			dbox(model, 0.5, finTop - CROWN_Y + 2, 0.5, x + sx * 1, (CROWN_Y - 2 + finTop) / 2, z + sz * 1, GOLD, Enum.Material.Neon, { transparency = 0.1 })
			local tip = dbox(model, 2.2, 2.2, 2.2, x, finTop + 1.2, z, Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
			CollectionService:AddTag(tip, "Blink")
		end
	end

	site = {
		frame = frame,
		bay = bayCenter.Position,
		bayCF = CFrame.lookAt(at(-6, 0, BAY_Z).Position, at(-6, 0, BAY_Z).Position + frame.RightVector),
		entrance = CFrame.lookAt(at(-14, 3.2, PODIUM_Z0 - 5).Position, at(-14, 3.2, PODIUM_Z0 - 5).Position - frame.LookVector),
		garage = { at(LANE_X, 0, BAY_Z).Position, at(LANE_X, 0, PODIUM_Z0 - 4).Position, at(LANE_X, 0, gz0 - 4).Position },
		board = boardLabel,
	}
end

function Hotel.buildWorld(kit: any, parent: Instance)
	local frame, lot = WestLayout.site("hotel")
	local ok, err = pcall(build, kit, parent, frame, lot)
	if not ok then
		warn("[CityLegends] hotel build failed:", err)
	end
end

---------------------------------------------------------------------
-- Valets
---------------------------------------------------------------------
local function fx(player: Player, info: { [string]: any })
	if fxRemote then
		fxRemote:FireClient(player, info)
	end
end

-- the valet drives the car round into the garage, then it's gone
local function driveAway(car: Model, route: { Vector3 })
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	task.wait(1.4) -- (the valet gets in)
	local cf = car:GetPivot()
	local y = cf.Position.Y
	local pts = { cf.Position }
	for _, p in route do
		table.insert(pts, Vector3.new(p.X, y, p.Z))
	end
	local speed = 16
	for k = 2, #pts do
		local a, b = pts[k - 1], pts[k]
		local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local dist = flat.Magnitude
		if dist > 0.5 then
			local goal = CFrame.lookAt(Vector3.zero, flat.Unit)
			local t = 0
			while t < dist and car.Parent do
				local dt = RunService.Heartbeat:Wait()
				t += dt * speed
				local pos = a:Lerp(b, math.min(t / dist, 1))
				cf = CFrame.new(pos) * cf.Rotation:Lerp(goal, math.min(1, dt * 5))
				car:PivotTo(cf)
			end
		end
	end
	task.wait(0.5)
	if car.Parent then
		car:Destroy()
	end
end

-- hand your car to the valet (from the client, stopped in the bay)
local function handOver(player: Player): { ok: boolean, message: string? }
	local s = site
	if not s then
		return { ok = false }
	end
	local car = ctx.getCar(player)
	local root = if car then car.PrimaryPart else nil
	if not (car and root) or player.Character then
		return { ok = false }
	end
	local p = root.Position
	if Vector3.new(p.X - s.bay.X, 0, p.Z - s.bay.Z).Magnitude > H.ValetRange + 4 then
		return { ok = false, message = "Stop in the valet bay" }
	end
	local v = root.AssemblyLinearVelocity
	if Vector3.new(v.X, 0, v.Z).Magnitude > H.ValetSpeed + 2 then
		return { ok = false, message = "Stop the car first" }
	end
	if ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
		return { ok = false, message = "The valet won't take a car the police are after" }
	end
	local carId = car:GetAttribute("CarId")
	if type(carId) ~= "string" then
		return { ok = false }
	end
	-- park it and take it off the player
	local lv = root:FindFirstChild("Drive")
	if lv and lv:IsA("LinearVelocity") then
		lv.PlaneVelocity = Vector2.zero
	end
	car:SetAttribute("Parked", true)
	car.Name = "Valet_" .. car.Name
	ctx.releaseCar(player)
	tickets[player] = carId
	player:SetAttribute("ValetCar", carId)
	OnFoot.standUp(player, s.entrance)
	task.spawn(driveAway, car, s.garage)
	return { ok = true, message = "The valet is parking your " .. (if Cars.ById[carId] then Cars.ById[carId].Name else "car") }
end

-- "Get my car" at the stand: the car comes back to the bay and you get in
function Hotel.retrieve(player: Player)
	local s = site
	local carId = tickets[player]
	if not s then
		return
	end
	if not carId then
		Towers.send(player, { kind = "toast", text = "The valet isn't holding a car for you", color = "warning" })
		return
	end
	local profile = PlayerData.get(player)
	if not (profile and profile.Owned[carId]) then
		tickets[player] = nil
		player:SetAttribute("ValetCar", nil)
		return
	end
	tickets[player] = nil
	player:SetAttribute("ValetCar", nil)
	ctx.setSpawnAt(player, s.bayCF)
	fx(player, { kind = "retrieve", carId = carId })
end

---------------------------------------------------------------------
-- Suite income and the residents' board
---------------------------------------------------------------------
local function suiteIncome(profile: any): number
	local total = 0
	for id in profile.Penthouses do
		local s = SUITE_BY_ID[id]
		if s then
			total += s.perMinute
		end
	end
	return total
end

local function refreshBoard()
	local s = site
	if not (s and s.board) then
		return
	end
	local lines = { "THE SUITES" }
	for _, suite in H.Suites do
		local names = {}
		for _, p in Players:GetPlayers() do
			local profile = PlayerData.get(p)
			if profile and profile.Penthouses[suite.id] then
				table.insert(names, p.DisplayName)
			end
		end
		table.insert(lines, string.format("%s   %s   %s / MIN   %s", suite.name, money(suite.price), money(suite.perMinute), if #names > 0 then table.concat(names, ", ") else "AVAILABLE"))
	end
	local board = s.board :: TextLabel
	board.Text = table.concat(lines, "\n")
end

function Hotel.init(c: any)
	ctx = c
	fxRemote = ctx.remote("RemoteEvent", "HotelFX")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "HotelCall")
	call.OnServerInvoke = function(player: Player, what: any)
		if what == "valet" then
			return handOver(player)
		end
		return { ok = false }
	end
	Players.PlayerRemoving:Connect(function(player)
		tickets[player] = nil
		carry[player] = nil
		task.defer(refreshBoard)
	end)
	-- every full minute in the game, each suite pays its owner
	local STEP = 5
	task.spawn(function()
		while true do
			task.wait(STEP)
			for _, player in Players:GetPlayers() do
				local profile = PlayerData.get(player)
				if profile and profile.Loaded then
					local rate = suiteIncome(profile)
					if rate > 0 then
						carry[player] = (carry[player] or 0) + STEP
						if (carry[player] :: number) >= H.IncomeEvery then
							carry[player] = (carry[player] :: number) - H.IncomeEvery
							PlayerData.addCash(player, rate)
							Towers.send(player, { kind = "cash", text = "SUITE INCOME", amount = rate })
						end
					end
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			refreshBoard()
			task.wait(10)
		end
	end)
end

return Hotel
