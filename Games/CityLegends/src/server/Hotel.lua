--[[
	Hotel
	The Legends Grand Hotel, Downtown on Ocean Drive (owner, 2026-10-22: "add a large skyscraper
	hotel with valets and you can buy a penthouse on the hotel"; "Downtown penthouse suites pay out
	money every minute to their owners").

	  * the forecourt: a porte-cochere driveway off the street under a lit canopy with the hotel's
	    name, a fountain island with palms and the name stone, the valet stand and valets in uniform
	  * the grand lobby: marble and gold, columns, chandeliers, reception with a concierge, a lounge
	    with a grand piano, the suite upgrades gallery, the residents' board and the suite lifts
	  * the tower (remodel 2026-11-03): cream Riviera stone in two setbacks, punched windows, black
	    iron balconies, carved cornices with balustrades, the name in gold letters round the top and
	    warm floodlights; the podium in the same stone with an iron-and-glass marquise, a stone
	    balustrade and balconettes; no neon. Chandeliers, leather sofas, potted palms and luggage
	    carts come from ServerStorage.VenueKit (cleaned Creator Store models saved in the place)
	  * the crown: the suites (Config.Hotel.Suites), full penthouse floors built by Towers.suite,
	    with stone piers and lanterns rising past the roof
	One suite you upgrade (owner, 2026-11-03): you own one tier at a time (Skyline, Ocean, Royal,
	the Penthouse). The gallery's plinths buy the first and upgrade to the next (paying the
	difference); the lifts take you up to your own tier only. Each tier is its own floor, furnished
	better than the one below (Towers.suite's tier, and VenueKit leather and chandeliers on the
	Royal and the Penthouse); the roof terrace (sky pool, telescope, helipad) is the Penthouse's.

	Valets: stop your car in the valet bay under the canopy and press Y ("VALET"): you step out at
	the door and a valet drives the car round into the valet garage. At the valet stand, "Get my
	car" brings it back to the bay (the next spawn of that car starts there, see ctx.setSpawnAt).
	Your suite pays you every full minute in the game (Config.Hotel.IncomeEvery, the tier's
	perMinute); time offline doesn't pay.

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
local EntranceRamp = require(script.Parent:WaitForChild("EntranceRamp"))

local Hotel = {}

local H = Config.Hotel
local GOLD = H.Accent
-- the remodel (2026-11-03, "Remodel the venues"): a Belle Époque grand hotel in cream Riviera stone
-- with black iron balconies, an iron-and-glass marquise and gold letters; no neon (gold and warm
-- white light only)
local RIV_LIGHT = Color3.fromRGB(230, 208, 168)
local RIV_DARK = Color3.fromRGB(186, 152, 106)
local IRON = Color3.fromRGB(22, 22, 24)
local MARBLE = Color3.fromRGB(232, 228, 220)
local MARBLE_DARK = Color3.fromRGB(36, 36, 40)
local STONE = Color3.fromRGB(214, 182, 132) -- warm cream Riviera limestone (was 214, 204, 186)
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

-- a ready-made piece from ServerStorage.VenueKit (cleaned Creator Store models saved in the place,
-- facing -Z, pivot at the bottom middle), or nil (Lune tests, a fresh Rojo build)
local function kitPiece(name: string, cf: CFrame, scale: number?, parent: Instance): Model?
	local ss = game:GetService("ServerStorage")
	local vk = ss:FindFirstChild("VenueKit")
	local src = vk and vk:FindFirstChild(name)
	if not (src and src:IsA("Model")) then
		return nil
	end
	local m = src:Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

-- one of the map's own dressing pieces (workspace.Riviera.Dressing), or nil
local function mapPiece(name: string): Model?
	local riv = workspace:FindFirstChild("Riviera")
	local dressing = riv and riv:FindFirstChild("Dressing")
	local m = dressing and dressing:FindFirstChild(name, true)
	return if m and m:IsA("Model") then m:Clone() else nil
end

-- big gold serif letters on a part's face, lit warm (a self-lit SurfaceGui, not neon)
local function goldLetters(p: BasePart, face: Enum.NormalId, text: string, perStud: number?, glow: number?)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = perStud or 10
	g.LightInfluence = 0.4
	g.Brightness = glow or 1.4
	g.MaxDistance = 1400
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Text = text
	t.TextScaled = true
	t.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
	t.TextColor3 = Color3.fromRGB(222, 178, 84)
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(120, 86, 30)
	s.Thickness = 1.5
	s.Parent = t
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
---------------------------------------------------------------------
-- The suite: one tier at a time
---------------------------------------------------------------------
-- the tier a profile owns (0: none; older saves keep only their best, see PlayerData)
local function tierOf(profile: any): number
	local best = 0
	for k, s in H.Suites do
		if profile.Penthouses[s.id] then
			best = k
		end
	end
	return best
end

-- what moving up to tier k costs (from the tier below)
local function upgradeCost(k: number): number
	return H.Suites[k].price - (if k > 1 then H.Suites[k - 1].price else 0)
end

-- the suites' ready-made furniture (cleaned Creator Store models in ServerStorage.VenueKit; see
-- the credits in the vault): when it's in the place, Towers.suite leaves out its own sofas, bed and
-- plants and dressSuite furnishes each tier
local function suiteKit(): boolean
	local vk = game:GetService("ServerStorage"):FindFirstChild("VenueKit")
	return vk ~= nil and vk:FindFirstChild("SuiteBed") ~= nil and vk:FindFirstChild("SuiteSectional") ~= nil
end

-- each tier, in the suite's own frame (x right, y up, -z towards the sea; pieces face -z):
--   all: lounge chairs by the coffee table, a wood and marble kitchen island, plants, a rug under
--     the dining table
--   1 Skyline: a white corner sofa facing the TV, a hotel bed, a dining table by the window
--   2 Ocean: the leather corner sofa, the dining table in the middle of the room
--   3 Royal: + a glass fireplace, the tufted sofa and armchairs facing the view, a chandelier
--   4 Penthouse: a round bed, a freestanding bath, a glass dining table, a concert grand piano at
--     the window, two chandeliers and palms
local function dressSuite(kit: any, parent: Instance, frame: CFrame, yP: number, k: number)
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local fl = yP + 0.3
	local par = kit.lodGroup(parent, "SuiteDressing", (frame * CFrame.new(0, yP + 15, 0)).Position, 380)
	local turn = CFrame.Angles(0, math.pi, 0) -- (facing +z)
	if suiteKit() then
		-- the TV lounge: a corner sofa with its back to the window, facing the TV wall
		kitPiece(if k == 1 then "SuiteSofa" else "SuiteSectional", at(-26, fl, -28) * turn, nil, par)
		-- the bed, its head against the back glass
		if k >= 4 then
			kitPiece("SuiteBedRound", at(30, fl, 33.4), nil, par)
		else
			kitPiece("SuiteBed", at(30, fl, 34.8), nil, par)
		end
		-- two lounge chairs either side of the coffee table, facing each other
		kitPiece("SuiteChair", at(-37, fl, -13) * CFrame.Angles(0, -math.pi / 2, 0), 1.2, par)
		kitPiece("SuiteChair", at(-13, fl, -13) * CFrame.Angles(0, math.pi / 2, 0), 1.2, par)
		-- the kitchen island (wood and marble), the stools in front of it
		kitPiece("SuiteIsland", at(-26, fl, 18), nil, par)
		-- dining on a rug: by the window on the Skyline, in the middle of the room above it
		local dx, dz = if k == 1 then 24 else 0, if k == 1 then -24 else -12
		kitPiece("SuiteRug", at(dx, fl, dz), 1.4, par)
		kitPiece(if k >= 4 then "SuiteDiningGlass" else "SuiteDining", at(dx, fl + 0.3, dz), nil, par)
		-- the Penthouse: a freestanding bath by the bedroom's glass
		if k >= 4 then
			kitPiece("SuiteBath", at(31.5, fl, 19.5), nil, par)
		end
		-- plants in the corners
		kitPiece("SuiteFig", at(-39.5, fl, -39.5), 1.4, par)
		kitPiece("SuitePlant", at(10, fl, 24), 1.2, par)
		if k < 4 then
			kitPiece("SuitePlant", at(-13, fl, 32), 1.2, par)
			kitPiece("SuiteFig", at(39, fl, -39), 1.4, par)
		end
		-- the Royal and the Penthouse: a glass fireplace on the left wall, facing the room
		if k >= 3 then
			local fire = kitPiece("SuiteFireplace", at(-36.6, fl, 4.1) * CFrame.Angles(0, -math.pi / 2, 0), nil, par)
			if fire then
				local glow = kit.deco(par, Vector3.new(1, 1, 1), at(-36, fl + 3, 4.1), WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
				kit.addLight("PointLight", glow, Color3.fromRGB(255, 160, 80), 18, 1.4)
			end
		end
		-- the Penthouse: a concert grand at the window (the bench on the room side)
		if k >= 4 then
			kitPiece("SuitePiano", at(0, fl, -30), nil, par)
		end
	end
	if k < 3 then
		return
	end
	-- the Royal Suite: the lobby's tufted sofa and armchairs facing the view
	if k == 3 and kitPiece("Chesterfield", at(0, fl, -31), 1.15, par) then
		kitPiece("Armchair", at(-10, fl, -33) * CFrame.Angles(0, math.rad(-25), 0), 1.15, par)
		kitPiece("Armchair", at(10, fl, -33) * CFrame.Angles(0, math.rad(25), 0), 1.15, par)
	end
	local hang = { { 0, 8 } }
	if k >= 4 then
		table.insert(hang, { -24, -18 })
		kitPiece("PottedPalm", at(39, fl, -39), 1.5 * 1.7, par)
		kitPiece("PottedPalm", at(-13, fl, 32), 1.5 * 1.7, par)
	end
	for _, h in hang do
		if kitPiece("Chandelier", at(h[1], yP + 30 - 14.92 * 0.75, h[2]), 0.75, par) then
			local bulb = kit.deco(par, Vector3.new(1, 1, 1), at(h[1], yP + 23, h[2]), WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
			kit.addLight("PointLight", bulb, WARM, 34, 1.2)
		end
	end
end

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
	-- the map's own palm (a real-looking tree), scaled to h; the built one if the map has none
	local function realPalm(par: Instance, x: number, z: number, h: number, y0: number?)
		local m = mapPiece("Palm")
		if not m then
			palm(par, x, z, h, y0)
			return
		end
		local tree = m :: Model
		tree:ScaleTo(tree:GetScale() * (h / tree:GetExtentsSize().Y))
		local spin = (x * 0.37 + z * 0.11) % 6.28
		local cf, size = tree:GetBoundingBox()
		local base = at(x, y0 or 0, z) * CFrame.Angles(0, spin, 0)
		tree:PivotTo(base * (CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)):Inverse() * tree:GetPivot()))
		tree.Parent = par
	end
	-- a potted palm (VenueKit) on a stone base; the built plant if the kit is missing
	local function pottedPalm(par: Instance, x: number, y: number, z: number, s: number)
		if not kitPiece("PottedPalm", at(x, y, z) * CFrame.Angles(0, (x + z) % 3, 0), s * 1.7, par) then
			dbox(par, 2.6 * s, 3 * s, 2.6 * s, x, y + 1.5 * s, z, CHARCOAL, Enum.Material.Slate)
			for k = 0, 2 do
				local a = k * 2.1
				deco(par, Vector3.one * 3 * s, at(x + math.cos(a) * 0.6 * s, y + (4 + k) * s, z + math.sin(a) * 0.6 * s), Color3.fromRGB(46, 92, 52), Enum.Material.Grass, { shape = Enum.PartType.Ball })
			end
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
	-- the driveways from the street up onto the forecourt: paved ramps fitted to the real ground
	-- (EntranceRamp: over the pavement, the kerb and the site's stone ledge)
	for _, sx in { -1, 1 } do
		local inner = at(sx * LANE_X, 0.2, -half + 0.5)
		task.defer(function()
			EntranceRamp.build(court, inner, { width = 20, color = PAVER, material = Enum.Material.Cobblestone, keep = { model } })
		end)
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
	local glow = dbox(court, 1, 0.4, 1, 0, 3.2, fz, WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
	light(glow, WARM, 24, 1.2)
	for _, sx in { -1, 1 } do
		realPalm(court, sx * (islandW / 2 - 10), islandZ0 + 12, 34, 1)
		realPalm(court, sx * (islandW / 2 - 14), islandZ1 - 9, 30, 1)
		realPalm(court, sx * 34, fz, 38, 1)
	end
	-- the name stone at the front of the island, lit from below
	local stone = box(court, 46, 7, 3, 0, 4.4, islandZ0 + 4, STONE, Enum.Material.Limestone)
	local stoneText = dbox(court, 42, 5, 0.2, 0, 4.6, islandZ0 + 2.4, BLACK, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(stoneText, Enum.NormalId.Front, H.Name .. "\nHOTEL  ·  SUITES", GOLD, nil, nil, Enum.Font.Garamond, Vector2.new(800, 170))
	dbox(court, 46.4, 0.3, 0.3, 0, 1.1, islandZ0 + 2.3, GOLD, Enum.Material.Metal)
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
	-- (a Belle Époque marquise: a black iron frame, a glass roof on iron ribs, a gold-lettered fascia)
	box(model, 124, 1.6, canopyD, 0, 19.8, canopyZ, IRON, Enum.Material.Metal, { shadow = true, name = "Canopy" })
	local roofGlass = dbox(model, 122, 0.3, canopyD - 2, 0, 21.4, canopyZ, Color3.fromRGB(196, 214, 222), Enum.Material.Glass, { transparency = 0.45, reflectance = 0.2 })
	roofGlass.CFrame = at(0, 21.6, canopyZ) * CFrame.Angles(math.rad(-4), 0, 0)
	for x = -60, 60, 10 do
		dbox(model, 0.5, 0.9, canopyD, x, 21.2, canopyZ, IRON, Enum.Material.Metal).CFrame = at(x, 21.8, canopyZ) * CFrame.Angles(math.rad(-4), 0, 0)
	end
	dbox(model, 125, 0.5, 0.5, 0, 20.75, cz0 - 0.1, GOLD, Enum.Material.Metal, { reflectance = 0.2 })
	dbox(model, 125, 0.3, 0.3, 0, 18.95, cz0 - 0.1, GOLD, Enum.Material.Metal, { reflectance = 0.2 })
	-- the fascia: a black iron board with the name in gold letters, an iron crest on top
	local fascia = dbox(model, 100, 5.4, 0.6, 0, 24.2, cz0 + 0.6, IRON, Enum.Material.Metal)
	goldLetters(fascia, Enum.NormalId.Front, "LEGENDS GRAND HOTEL", 10, 1.5)
	dbox(model, 101, 0.4, 0.8, 0, 21.4, cz0 + 0.6, GOLD, Enum.Material.Metal, { reflectance = 0.2 })
	dbox(model, 101, 0.4, 0.8, 0, 27.0, cz0 + 0.6, GOLD, Enum.Material.Metal, { reflectance = 0.2 })
	for k = -3, 3 do
		dbox(model, 0.3, 3, 0.3, k * 2.2, 28.4, cz0 + 0.6, IRON, Enum.Material.Metal).CFrame = at(0, 27.2, cz0 + 0.6) * CFrame.Angles(0, 0, k * 0.32) * CFrame.new(0, 1.6, 0)
	end
	-- black iron columns with gold collars, and iron brackets under the glass
	for _, sx in { -1, 1 } do
		column(model, true, 1.8, 19, sx * 58, 0.9, cz0 + 2, IRON, Enum.Material.Metal)
		column(model, false, 2.8, 1.2, sx * 58, 0.9, cz0 + 2, IRON, Enum.Material.Metal)
		column(model, false, 2.4, 0.6, sx * 58, 5.5, cz0 + 2, GOLD, Enum.Material.Metal)
		column(model, false, 2.6, 0.8, sx * 58, 18.2, cz0 + 2, GOLD, Enum.Material.Metal)
		dbox(model, 0.5, 0.5, 14, sx * 58, 16, cz0 + 7, IRON, Enum.Material.Metal).CFrame = at(sx * 58, 15.6, cz0 + 7) * CFrame.Angles(math.rad(38), 0, 0)
	end
	-- warm lanterns under the canopy (a small glass lamp each)
	for _, x in { -48, -24, 0, 24, 48 } do
		dbox(court, 0.25, 1.6, 0.25, x, 18.2, canopyZ - 4, IRON, Enum.Material.Metal)
		local dl = dbox(court, 1.6, 2, 1.6, x, 16.4, canopyZ - 4, WARM, Enum.Material.Neon, { transparency = 0.2, name = "Lantern" })
		dbox(court, 2.2, 0.4, 2.2, x, 17.5, canopyZ - 4, GOLD, Enum.Material.Metal)
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
			dbox(court, 1.2, 1.2, 1.2, x, 3.5, BAY_Z + 10.5, BRASS, Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.3 })
		end
	end

	-- the valet stand (left of the doors): a walnut lectern with a key cabinet behind it
	local standX, standZ = -34, PODIUM_Z0 - 6
	box(court, 6, 4.2, 3, standX, 2.1, standZ, WALNUT, Enum.Material.Wood)
	dbox(court, 6.4, 0.3, 3.4, standX, 4.35, standZ, MARBLE, Enum.Material.Marble)
	dbox(court, 6.2, 0.2, 0.2, standX, 0.6, standZ - 1.55, GOLD, Enum.Material.Metal)
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
	-- potted palms either side of the doors and along the carpet, a brass luggage cart by the door
	for _, sx in { -1, 1 } do
		pottedPalm(court, sx * 11, 0.2, PODIUM_Z0 - 3, 1.3)
		pottedPalm(court, sx * 9, 0.2, BAY_Z + 13, 1.1)
	end
	kitPiece("LuggageCart", at(16, 0.2, PODIUM_Z0 - 5) * CFrame.Angles(0, math.rad(200), 0), 1, court)

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
	local gSign = dbox(model, doorW + 2, 3, 0.4, LANE_X, doorH + 2.6, PODIUM_Z0 - 0.3, IRON, Enum.Material.Metal)
	goldLetters(gSign, Enum.NormalId.Front, "VALET GARAGE", 20, 1.2)
	dbox(model, doorW + 1, 0.4, 0.4, LANE_X, doorH + 0.4, PODIUM_Z0 - 0.4, GOLD, Enum.Material.Metal)
	-- boutique windows in the left wing: dark glass in bronze frames, lit warm from inside, black
	-- awnings with gold names
	local wingW = WING_X - LOBBY_X
	for k, name in { "ATELIER", "THE SPA" } do
		local x = -LOBBY_X - wingW * (if k == 1 then 0.28 else 0.72)
		local w = wingW * 0.4
		local back = dbox(model, w, 13, 0.3, x, 7.8, PODIUM_Z0 + 0.6, Color3.fromRGB(236, 206, 160), Enum.Material.SmoothPlastic)
		light(back, WARM, 14, 0.8)
		dbox(model, w, 13, 0.2, x, 7.8, PODIUM_Z0 - 0.2, Color3.fromRGB(40, 44, 50), Enum.Material.Glass, { transparency = 0.55, reflectance = 0.2 })
		dbox(model, w + 1.2, 0.8, 0.6, x, 14.6, PODIUM_Z0 - 0.3, Color3.fromRGB(60, 48, 34), Enum.Material.Metal)
		dbox(model, 0.6, 13, 0.6, x, 7.8, PODIUM_Z0 - 0.3, Color3.fromRGB(60, 48, 34), Enum.Material.Metal)
		local aw = dbox(model, w + 2, 1.4, 4, x, 16.6, PODIUM_Z0 - 2, IRON, Enum.Material.Fabric)
		aw.CFrame = at(x, 16.6, PODIUM_Z0 - 2) * CFrame.Angles(math.rad(-14), 0, 0)
		local s = dbox(model, w, 1.3, 0.1, x, 16, PODIUM_Z0 - 4.05, IRON, Enum.Material.Fabric, { transparency = 1 })
		goldLetters(s, Enum.NormalId.Front, name, 20, 1.1)
	end
	-- the stone fronts above the wings: two floors of tall windows with
	-- carved hoods and black iron balconettes, as on the old Riviera hotels
	local function wingFront(xa: number, xb: number, fromY: number)
		local w = xb - xa
		local bays = math.max(1, math.floor(w / 9))
		local bay = w / bays
		for _, fy in { 18, 27.5 } do
			if fy < fromY - 1 then
				continue
			end
			for b = 0, bays - 1 do
				local bx = xa + (b + 0.5) * bay
				local pane = dbox(model, bay - 3.4, 6.4, 0.3, bx, fy + 3.2, PODIUM_Z0 - 0.1, Color3.fromRGB(28, 32, 40), Enum.Material.Glass, { reflectance = 0.15 })
				CollectionService:AddTag(pane, "Window")
				dbox(model, bay - 2.2, 0.5, 1.2, bx, fy + 6.9, PODIUM_Z0 - 0.5, RIV_LIGHT, Enum.Material.Limestone)
				dbox(model, 1, 1.2, 0.6, bx, fy + 7.4, PODIUM_Z0 - 0.4, RIV_LIGHT, Enum.Material.Limestone)
				dbox(model, bay - 2.4, 0.4, 2.2, bx, fy - 0.1, PODIUM_Z0 - 1.1, RIV_LIGHT, Enum.Material.Limestone)
				dbox(model, bay - 2.4, 0.18, 0.18, bx, fy + 2.6, PODIUM_Z0 - 2.1, IRON, Enum.Material.Metal)
				for s = 0, 3 do
					dbox(model, 0.14, 2.6, 0.14, bx - (bay - 2.6) / 2 + s * (bay - 2.6) / 3, fy + 1.3, PODIUM_Z0 - 2.1, IRON, Enum.Material.Metal)
				end
			end
		end
	end
	wingFront(-WING_X, -LOBBY_X, 18)
	wingFront(LOBBY_X, WING_X, doorH + 6)
	-- the wings' long outer sides: two rows of windows with stone hoods
	for _, sx in { -1, 1 } do
		local xf = sx * WING_X
		for z = PODIUM_Z0 + 8, PODIUM_Z1 - 6, 11 do
			for _, fy in { 18, 27.5 } do
				local pane = dbox(model, 0.3, 6.4, 6, xf + sx * 0.1, fy + 3.2, z, Color3.fromRGB(28, 32, 40), Enum.Material.Glass, { reflectance = 0.15 })
				CollectionService:AddTag(pane, "Window")
				dbox(model, 1.2, 0.5, 7.2, xf + sx * 0.5, fy + 6.9, z, RIV_LIGHT, Enum.Material.Limestone)
				dbox(model, 1.6, 0.4, 6.8, xf + sx * 0.7, fy - 0.1, z, RIV_LIGHT, Enum.Material.Limestone)
			end
		end
		dbox(model, 1, 1.2, PODIUM_Z1 - PODIUM_Z0, xf + sx * 0.4, 16.6, (PODIUM_Z0 + PODIUM_Z1) / 2, RIV_LIGHT, Enum.Material.Limestone)
	end
	-- the lobby's front: tall glass between stone piers, dark bronze mullions, a carved stone band
	-- with an iron balconette at the mezzanine line, the doors in the middle
	local BRONZE = Color3.fromRGB(60, 48, 34)
	box(model, LOBBY_X * 2, PODIUM_TOP - 30, 2, 0, 30 + (PODIUM_TOP - 30) / 2, PODIUM_Z0 + 1, STONE, Enum.Material.Limestone) -- transom
	for _, seg in { { -LOBBY_X, -10 }, { 10, LOBBY_X } } do
		local len = seg[2] - seg[1]
		local mid = (seg[1] + seg[2]) / 2
		box(model, len, 29.5, 0.5, mid, 0.5 + 14.75, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.75, reflectance = 0.15, shadow = false })
		for x = seg[1], seg[2], 8 do
			if math.abs(x) % 32 == 0 then
				dbox(model, 4.2, 29.5, 1.6, x, 0.5 + 14.75, PODIUM_Z0 + 0.2, STONE, Enum.Material.Limestone)
				dbox(model, 5, 1.2, 2, x, 1.1, PODIUM_Z0 + 0.2, RIV_DARK, Enum.Material.Limestone)
				dbox(model, 5, 1.2, 2, x, 29.4, PODIUM_Z0 + 0.2, RIV_LIGHT, Enum.Material.Limestone)
			else
				dbox(model, 0.5, 29.5, 0.8, x, 0.5 + 14.75, PODIUM_Z0 + 0.4, BRONZE, Enum.Material.Metal)
			end
		end
		dbox(model, len, 1.4, 1.6, mid, 17, PODIUM_Z0 + 0.2, RIV_LIGHT, Enum.Material.Limestone)
		dbox(model, len - 1, 0.18, 0.18, mid, 20.4, PODIUM_Z0 - 0.5, IRON, Enum.Material.Metal)
		dbox(model, len - 1, 0.12, 0.12, mid, 18.4, PODIUM_Z0 - 0.5, IRON, Enum.Material.Metal)
		for x = seg[1] + 1, seg[2] - 1, 1.6 do
			dbox(model, 0.12, 2.6, 0.12, x, 19.1, PODIUM_Z0 - 0.5, IRON, Enum.Material.Metal)
		end
	end
	-- the doors: a revolving door (walk straight through) in a stone frame under a gold sunburst
	column(model, false, 14, 13, 0, 0.5, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.85 })
	for k = 0, 3 do
		dbox(model, 0.2, 13, 6.5, 0, 7, PODIUM_Z0 + 1, GLASS, Enum.Material.Glass, { transparency = 0.7 }).CFrame = at(0, 7, PODIUM_Z0 + 1) * CFrame.Angles(0, k * math.pi / 2 + 0.4, 0) * CFrame.new(0, 0, 3.25)
	end
	disc(model, false, 15, 0.6, 0, 13.5, PODIUM_Z0 + 1, BRASS, Enum.Material.Metal)
	for k = -4, 4 do
		dbox(model, 0.3, 10, 0.3, 0, 19, PODIUM_Z0 + 0.2, GOLD, Enum.Material.Metal, { reflectance = 0.25 }).CFrame = at(0, 14.2, PODIUM_Z0 + 0.2) * CFrame.Angles(0, 0, k * 0.3) * CFrame.new(0, 5, 0)
	end
	for _, sx in { -1, 1 } do
		dbox(model, 2.4, 29.5, 1.8, sx * 9.6, 0.5 + 14.75, PODIUM_Z0 + 0.1, STONE, Enum.Material.Limestone)
	end
	dbox(model, 21.6, 1.6, 2.2, 0, 26, PODIUM_Z0 + 0.1, RIV_LIGHT, Enum.Material.Limestone)
	dbox(model, 3, 3, 1.2, 0, 27.4, PODIUM_Z0 - 0.4, RIV_LIGHT, Enum.Material.Limestone) -- the keystone
	-- the podium roof: a slab behind a carved cornice and a stone balustrade, planters and palms
	box(model, WING_X * 2 + 2, 2, PODIUM_Z1 - PODIUM_Z0 + 2, 0, PODIUM_TOP - 1, (PODIUM_Z0 + PODIUM_Z1) / 2, CHARCOAL, Enum.Material.Concrete, { name = "PodiumRoof" })
	dbox(model, WING_X * 2 + 4, 1.6, 3.4, 0, PODIUM_TOP - 0.8, PODIUM_Z0 - 0.7, RIV_LIGHT, Enum.Material.Limestone)
	dbox(model, WING_X * 2 + 3, 0.7, 2.4, 0, PODIUM_TOP - 2.2, PODIUM_Z0 - 0.4, RIV_DARK, Enum.Material.Limestone)
	local roofDeco = kit.lodGroup(model, "PodiumTerrace", at(0, PODIUM_TOP, 0).Position, 700)
	dbox(roofDeco, WING_X * 2 + 2, 0.8, 1.6, 0, PODIUM_TOP + 0.4, PODIUM_Z0 + 0.2, RIV_LIGHT, Enum.Material.Limestone)
	dbox(roofDeco, WING_X * 2 + 2, 0.7, 1.8, 0, PODIUM_TOP + 3.75, PODIUM_Z0 + 0.2, RIV_LIGHT, Enum.Material.Limestone)
	for x = -WING_X + 1, WING_X - 1, 2.2 do
		column(roofDeco, false, 0.9, 2.6, x, PODIUM_TOP + 0.8, PODIUM_Z0 + 0.2, STONE, Enum.Material.Limestone)
	end
	for _, sx in { -1, 1 } do
		for _, z in { PODIUM_Z0 + 8, PODIUM_Z1 - 8 } do
			box(roofDeco, 8, 3, 8, sx * (WING_X - 8), PODIUM_TOP + 1.5, z, STONE, Enum.Material.Limestone)
			realPalm(roofDeco, sx * (WING_X - 8), z, 24, PODIUM_TOP + 3)
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
	-- (owner, 2026-11-03: "the hotel roof is bugging") its underside sat exactly on the podium
	-- roof's underside, and the two flickered (cream / charcoal): it hangs 0.15 lower now
	box(model, LOBBY_X * 2, 1.5, PODIUM_Z1 - PODIUM_Z0, 0, LH + 0.75 - 0.15, (PODIUM_Z0 + PODIUM_Z1) / 2, CREAM, Enum.Material.SmoothPlastic, { name = "LobbyCeiling" })
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
	-- chandeliers: crystal chandeliers (VenueKit), or tiers of glowing rings with crystal drops
	for _, z in { -10, 24, 58 } do
		local ch = kitPiece("Chandelier", at(0, LH - 0.6 - 14.92 * 1.5, z), 1.5, lobby)
		if ch then
			local bulb = dbox(lobby, 1, 1, 1, 0, LH - 12, z, WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
			light(bulb, WARM, 46, 1.5)
			continue
		end
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
	dbox(lobby, 0.2, 0.25, 40, rxD + 2.15, 1, 18, GOLD, Enum.Material.Metal)
	local wall = box(lobby, 1.4, 22, 48, -LOBBY_X + 0.7, 11.5, 18, WALNUT, Enum.Material.Wood)
	local wallSign = dbox(lobby, 0.3, 6, 40, -LOBBY_X + 1.6, 15, 18, BLACK, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.surfaceText(wallSign, Enum.NormalId.Right, H.Name, GOLD:Lerp(Color3.new(1, 1, 1), 0.2), nil, nil, Enum.Font.Garamond, Vector2.new(1100, 140))
	dbox(lobby, 0.3, 0.3, 40, -LOBBY_X + 1.6, 11, 18, GOLD, Enum.Material.Metal)
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
		-- tufted leather sofas facing each other and two armchairs (VenueKit), or our own sofas
		local a = kitPiece("Chesterfield", at(60, 0.5, z - 6.5) * CFrame.Angles(0, math.pi, 0), 1.15, lobby)
		if a then
			kitPiece("Chesterfield", at(60, 0.5, z + 6.5), 1.15, lobby)
			kitPiece("Armchair", at(51, 0.5, z) * CFrame.Angles(0, -math.pi / 2, 0), 1.15, lobby)
			kitPiece("Armchair", at(69, 0.5, z) * CFrame.Angles(0, math.pi / 2, 0), 1.15, lobby)
		else
			sofa(lobby, at(60, 0.5, z - 7) * CFrame.Angles(0, 0, 0), 16, CREAM)
			sofa(lobby, at(60, 0.5, z + 7) * CFrame.Angles(0, math.pi, 0), 16, CREAM)
		end
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
	pottedPalm(lobby, 70, 0.5, -34, 1.5)
	pottedPalm(lobby, 70, 0.5, 40, 1.5)
	pottedPalm(lobby, -70, 0.5, -34, 1.5)
	kitPiece("LuggageCart", at(-52, 0.5, -8) * CFrame.Angles(0, math.rad(70), 0), 1, lobby)

	-- the suite upgrades gallery (right, at the back): a glowing model of each tier on a plinth;
	-- the first plinth buys the Skyline Suite, each next one upgrades to its tier
	local suites = H.Suites
	for k, s in suites do
		local z = 44 + (k - 1) * 10
		box(lobby, 4, 4, 4, 66, 2.5, z, BLACK, Enum.Material.SmoothPlastic)
		dbox(lobby, 4.2, 0.2, 4.2, 66, 4.6, z, GOLD, Enum.Material.Metal)
		local mini = dbox(lobby, 1.6, 2 + k * 0.8, 1.6, 66, 5.7 + k * 0.4, z, Color3.fromRGB(30, 40, 56), Enum.Material.Glass, { reflectance = 0.3 })
		dbox(lobby, 1.7, 0.3, 1.7, 66, 4.7 + 2 + k * 0.8 + 0.2, z, GOLD, Enum.Material.Metal)
		local cost = upgradeCost(k)
		local card = dbox(lobby, 0.2, 3.2, 3.6, 63.9, 2.8, z, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(card, Enum.NormalId.Left, s.name .. "\n" .. money(cost) .. "\n" .. money(s.perMinute) .. " / MIN\n" .. s.adds, GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(300, 260))
		local buy = prompt(mini, if k == 1 then "Buy suite" else "Upgrade", titleCase(s.name) .. "  " .. money(cost), Enum.KeyCode.E, 1.5, 9)
		CollectionService:AddTag(buy, "HotelTier") -- (HotelClient words it for this player)
		buy:SetAttribute("Tier", k)
		buy.Triggered:Connect(function(player: Player)
			Hotel.upgrade(player, k)
		end)
	end
	local gallerySign = dbox(lobby, 0.3, 2.4, 20, 69, 11, 59, BLACK, Enum.Material.SmoothPlastic)
	kit.surfaceText(gallerySign, Enum.NormalId.Left, "SUITE UPGRADES", GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(600, 70))

	-- the suite lifts under the residents' board: each takes you up to your own suite (owners only)
	box(model, 108, LH, PODIUM_Z1 - 2 - ELEVATOR_Z, 0, LH / 2, (ELEVATOR_Z + PODIUM_Z1 - 2) / 2, MARBLE_DARK, Enum.Material.Marble, { name = "ElevatorCore" })
	local lobbyStop = at(0, 3.7, ELEVATOR_Z - 6) -- facing out of the middle lift's doors
	for _, x in { -20, 0, 20 } do
		dbox(lobby, 12, 15, 0.6, x, 7.5 + 0.5, ELEVATOR_Z - 0.3, MARBLE, Enum.Material.Marble)
		for _, sx in { -1, 1 } do
			dbox(lobby, 3.6, 11.5, 0.3, x + sx * 1.85, 6.25, ELEVATOR_Z - 0.7, BRASS, Enum.Material.Metal, { reflectance = 0.35 })
		end
		dbox(lobby, 0.1, 11.5, 0.32, x, 6.25, ELEVATOR_Z - 0.72, BLACK, Enum.Material.SmoothPlastic)
		local plate = dbox(lobby, 10, 1.8, 0.2, x, 13.6, ELEVATOR_Z - 0.75, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(plate, Enum.NormalId.Front, "SUITES", GOLD, nil, nil, Enum.Font.GothamMedium, Vector2.new(400, 70))
		local panel = dbox(lobby, 1, 2.4, 0.3, x + 5.2, 5.5, ELEVATOR_Z - 0.75, BRASS, Enum.Material.Metal, { reflectance = 0.3 })
		dbox(lobby, 0.5, 0.5, 0.1, x + 5.2, 6, ELEVATOR_Z - 0.95, WARM, Enum.Material.Neon)
		local p = prompt(panel, "Up to my suite", "Elevator", Enum.KeyCode.E, 0, 10)
		CollectionService:AddTag(p, "HotelSuiteLift") -- (HotelClient words it for this player)
		p.Triggered:Connect(function(player: Player)
			Hotel.goUp(player)
		end)
	end
	-- the residents' board above the elevators
	local boardPart = dbox(lobby, 70, 11, 0.3, 0, 25, ELEVATOR_Z - 0.5, BLACK, Enum.Material.SmoothPlastic)
	dbox(lobby, 70.6, 11.6, 0.2, 0, 25, ELEVATOR_Z - 0.35, BRASS, Enum.Material.Metal)
	local _, _, boardLabel = kit.surfaceText(boardPart, Enum.NormalId.Front, "", GOLD:Lerp(Color3.new(1, 1, 1), 0.35), nil, nil, Enum.Font.GothamMedium, Vector2.new(1200, 190))

	---------------------------------------------------------------- the tower
	-- warm Riviera stone with punched windows and floor ledges (BuildingSkin paints the stone), black
	-- iron balconies on every other floor front and back, carved cornices with balustrades at the
	-- setbacks, the name in gold letters round the top and warm floodlights; no neon
	local pal = kit.randomPalette("stone")
	pal.body = STONE
	pal.fin = RIV_LIGHT
	pal.finMat = Enum.Material.Limestone
	pal.warm = true
	pal.lit = 0.5
	-- iron balconies across a face: a stone slab, top and bottom rails, posts on the window grid
	local function balconies(par: Instance, tier: { w: number, d: number, y0: number, y1: number })
		local floors = math.floor((tier.y1 - tier.y0 - 3) / 11)
		local cols = math.min(12, math.max(2, math.floor((tier.w - 2) / pal.module)))
		local module = (tier.w - 2) / cols
		local len = tier.w - 4
		for f = 2, floors, 2 do
			local ySlab = tier.y0 + 1.5 + (f - 0.5) * 11 - pal.winH / 2 - 0.3
			for _, face in { -1, 1 } do
				local zf = TOWER_Z + face * (tier.d / 2)
				dbox(par, len, 0.7, 3, 0, ySlab - 0.35, zf + face * 1.5, RIV_LIGHT, Enum.Material.Limestone)
				dbox(par, len, 0.22, 0.22, 0, ySlab + 3.2, zf + face * 2.9, IRON, Enum.Material.Metal)
				dbox(par, len, 0.14, 0.14, 0, ySlab + 0.5, zf + face * 2.9, IRON, Enum.Material.Metal)
				for c = 0, cols do
					dbox(par, 0.16, 3.1, 0.16, -(tier.w - 2) / 2 + c * module, ySlab + 1.6, zf + face * 2.9, IRON, Enum.Material.Metal)
				end
			end
		end
	end
	-- a carved cornice and a stone balustrade round a setback
	local function cornice(par: Instance, tier: { w: number, d: number, y0: number, y1: number })
		box(model, tier.w + 3, 1.6, tier.d + 3, 0, tier.y1 + 0.8, TOWER_Z, RIV_LIGHT, Enum.Material.Limestone, { name = "Terrace" })
		dbox(par, tier.w + 1.6, 0.9, tier.d + 1.6, 0, tier.y1 - 0.6, TOWER_Z, RIV_DARK, Enum.Material.Limestone)
		for _, face in { -1, 1 } do
			dbox(par, tier.w + 2.4, 0.6, 1, 0, tier.y1 + 4.4, TOWER_Z + face * (tier.d / 2 + 1), RIV_LIGHT, Enum.Material.Limestone)
			dbox(par, 1, 0.6, tier.d + 2.4, face * (tier.w / 2 + 1), tier.y1 + 4.4, TOWER_Z, RIV_LIGHT, Enum.Material.Limestone)
			for x = -tier.w / 2, tier.w / 2, 4 do
				dbox(par, 0.8, 2.6, 0.8, x, tier.y1 + 2.9, TOWER_Z + face * (tier.d / 2 + 1), STONE, Enum.Material.Limestone)
			end
		end
	end
	local fine1 = kit.lodGroup(model, "Facade1", at(0, (BODY1.y0 + BODY1.y1) / 2, TOWER_Z).Position, 900)
	local bx, bz, bw, bd = worldBox(0, TOWER_Z, BODY1.w, BODY1.d)
	kit.facadeTier(model, bx, bz, bw, bd, groundY + BODY1.y0, groundY + BODY1.y1, pal, true, nil, fine1)
	balconies(fine1, BODY1)
	cornice(fine1, BODY1)
	local fine2 = kit.lodGroup(model, "Facade2", at(0, (BODY2.y0 + BODY2.y1) / 2, TOWER_Z).Position, 1000)
	local b2x, b2z, b2w, b2d = worldBox(0, TOWER_Z, BODY2.w, BODY2.d)
	kit.facadeTier(model, b2x, b2z, b2w, b2d, groundY + BODY2.y0, groundY + BODY2.y1, pal, true, nil, fine2)
	balconies(fine2, { w = BODY2.w, d = BODY2.d, y0 = BODY2.y0, y1 = BODY2.y1 - 14 })
	cornice(fine2, BODY2)
	-- the landmark from far away: the stone body, its window strips, cornices and name band always
	-- stream to every player (about 250 parts); the finer stone, balconies and lit rooms stream
	-- in near
	local shell = Instance.new("Model")
	shell.Name = "TowerShell"
	shell.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	shell.Parent = model
	for _, g in { model, fine1, fine2 } do
		for _, p in g:GetChildren() do
			if p:IsA("BasePart") and (p.Name == "Tower" or p.Name == "Pane" or p.Name == "Fin" or p.Name == "Terrace") then
				p.Parent = shell
			end
		end
	end
	-- warm floodlights on the first setback, washing the upper stone
	for _, x in { -40, 0, 40 } do
		for _, face in { -1, 1 } do
			local up = dbox(fine2, 2, 1, 2, x, BODY1.y1 + 2, TOWER_Z + face * (BODY2.d / 2 + 4), CHARCOAL, Enum.Material.Metal)
			kit.addLight("SpotLight", up, WARM, 60, 2, Enum.NormalId.Top, 45)
		end
	end
	-- the name round the top of the tower, under the crown: a stone band with gold letters
	local band = deco(shell, Vector3.new(b2w + 0.8, 10, b2d + 0.8), CFrame.new(b2x, groundY + BODY2.y1 - 6, b2z), RIV_LIGHT, Enum.Material.Limestone)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		goldLetters(band, face, "LEGENDS GRAND HOTEL", 10, 1.6)
	end
	dbox(shell, BODY2.w + 1.6, 0.6, BODY2.d + 1.6, 0, BODY2.y1 - 11.3, TOWER_Z, GOLD, Enum.Material.Metal)
	dbox(shell, BODY2.w + 1.6, 0.6, BODY2.d + 1.6, 0, BODY2.y1 - 0.7, TOWER_Z, GOLD, Enum.Material.Metal)

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
		local yP = CROWN_Y + (k - 1) * SUITE_STEP
		stops[k] = Towers.suite(kit, model, spec, { frame = suiteFrame, yP = yP, roof = k == #suites, tier = k, kitFurniture = suiteKit() })
		stops[k].lobby = lobbyStop
		dressSuite(kit, model, suiteFrame, yP, k)
	end
	-- the crown: stone corner piers rising past the glass suites to lanterns with gold caps (red
	-- aviation lights on top), a carved stone ring at the suites' foot and round the roof
	local roofTop = CROWN_Y + (#suites - 1) * SUITE_STEP + 30 + 1.5
	local finTop = roofTop + 18
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * 44.2, TOWER_Z + sz * 44.2
			box(model, 3.4, finTop - CROWN_Y + 2, 3.4, x, (CROWN_Y - 2 + finTop) / 2, z, RIV_LIGHT, Enum.Material.Limestone)
			dbox(model, 4.6, 1.2, 4.6, x, finTop + 0.6, z, RIV_LIGHT, Enum.Material.Limestone)
			dbox(model, 3, 3, 3, x, finTop + 2.7, z, GOLD, Enum.Material.Metal, { reflectance = 0.3 })
			column(model, false, 1.2, 4, x, finTop + 4.2, z, GOLD, Enum.Material.Metal, { reflectance = 0.3 })
			local tip = dbox(model, 1.2, 1.2, 1.2, x, finTop + 8.8, z, Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
			CollectionService:AddTag(tip, "Blink")
		end
	end
	for _, y in { CROWN_Y - 1.4, roofTop + 0.6 } do
		for _, face in { -1, 1 } do
			dbox(model, 92, 1.2, 1.6, 0, y, TOWER_Z + face * 45.2, RIV_LIGHT, Enum.Material.Limestone)
			dbox(model, 1.6, 1.2, 92, face * 45.2, y, TOWER_Z, RIV_LIGHT, Enum.Material.Limestone)
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
	local k = tierOf(profile)
	return if k > 0 then H.Suites[k].perMinute else 0
end

local function refreshBoard()
	local s = site
	if not (s and s.board) then
		return
	end
	local lines = { "THE SUITES" }
	for k, suite in H.Suites do
		local names = {}
		for _, p in Players:GetPlayers() do
			local profile = PlayerData.get(p)
			if profile and profile.Penthouses[suite.id] then
				table.insert(names, p.DisplayName)
			end
		end
		table.insert(lines, string.format("%s   %s   %s / MIN   %s", suite.name, money(upgradeCost(k)), money(suite.perMinute), if #names > 0 then table.concat(names, ", ") else "AVAILABLE"))
	end
	local board = s.board :: TextLabel
	board.Text = table.concat(lines, "\n")
end

-- for Legends Rewards: the suite you own and what it pays a minute (nil: none; it pays on its own)
function Hotel.incomeOf(player: Player): { name: string, perMinute: number }?
	local profile = PlayerData.get(player)
	local k = if profile then tierOf(profile) else 0
	if k == 0 then
		return nil
	end
	return { name = titleCase(H.Suites[k].name), perMinute = H.Suites[k].perMinute }
end

-- the lifts: up to your own suite
function Hotel.goUp(player: Player)
	local profile = PlayerData.get(player)
	if not (profile and profile.Loaded) then
		return
	end
	local k = tierOf(profile)
	if k == 0 then
		Towers.send(player, { kind = "toast", text = "The lifts are for suite owners: buy a suite at Suite Upgrades", color = "warning" })
		return
	end
	Towers.travel(player, H.Suites[k].id, "penthouse")
end

-- a gallery plinth: buy the first tier, or upgrade to the next one (paying the difference); the
-- home and the showcase car move up with you
function Hotel.upgrade(player: Player, k: number)
	local profile = PlayerData.get(player)
	local s = H.Suites[k]
	if not (s and profile and profile.Loaded) then
		return
	end
	local cur = tierOf(profile)
	if k <= cur then
		Towers.send(player, { kind = "toast", text = if k == cur then "This is your suite" else "Your suite is already better", color = "accent" })
		return
	end
	if k > cur + 1 then
		Towers.send(player, { kind = "toast", text = "Upgrade to the " .. titleCase(H.Suites[cur + 1].name) .. " first", color = "warning" })
		return
	end
	local cost = upgradeCost(k)
	if profile.Cash < cost then
		Towers.send(player, { kind = "toast", text = "Not enough cash: this costs " .. money(cost), color = "danger" })
		return
	end
	PlayerData.addCash(player, -cost)
	profile.Penthouses[s.id] = true
	if cur > 0 then
		local old = H.Suites[cur].id
		profile.Penthouses[old] = nil
		if profile.Home == old then
			profile.Home = s.id
		end
		if profile.Showcase[old] then
			profile.Showcase[s.id] = profile.Showcase[old]
			profile.Showcase[old] = nil
		end
	end
	if profile.Home == "" then
		profile.Home = s.id
	end
	Towers.refresh(player)
	refreshBoard()
	task.spawn(PlayerData.save, player)
	Towers.send(player, { kind = "bought", text = (if cur == 0 then "Welcome to the " else "Upgraded to the ") .. titleCase(s.name), amount = -cost })
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
