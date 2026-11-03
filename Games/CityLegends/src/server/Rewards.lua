--[[
	Rewards (server)
	Legends Rewards, on the casino square (owner, 2026-11-03: "Replace the casino with a rewards
	centre"): a Belle Epoque palace in cream stone where players claim what they've earned. No
	gambling with bets: the spins (SPIN: one reel of prize cards, SUPER SPIN: three) come free on a
	timer, extra spins are bought with cash or Robux, the odds are shown before every spin and
	buying is hidden where Roblox restricts paid random items.
	  * Outside: a marble plaza with palms, fountains and clipped hedge gardens either side of the
	    red carpet; an iron-and-glass marquise; the front in cream stone with round-headed windows, a
	    grand arched entrance, paired pilasters, a frieze with the name in gold letters and a
	    balustrade; two corner towers with copper-green domes and a big copper dome over the hall;
	    floodlit gold at night.
	  * Inside: a grand hall with a gilded coffered ceiling, cream walls with gold pilasters, crystal
	    chandeliers (VenueKit), and the claim desks (each a ProximityPrompt that opens its page of
	    the rewards screen, RewardsClient): DAILY REWARD (the 7-day streak, Goals.claimStreak) in
	    the middle, GIFTS (playtime, weekly, welcome back), LEVEL REWARDS, ACHIEVEMENTS (the Legends
	    Path, shown only: it pays when each goal is done), FRIENDS (a friend in your server, invites,
	    the group gift), CODES, PROPERTY (penthouse rent, the hotel suite's income) and the two prize
	    spin cabinets on the back wall.
	The server decides everything: what's owed and when, one claim at a time per player (a lock),
	rate limits, the player standing at a desk (codes and the screen's view work anywhere), and the
	claim is saved before it's paid. Saved as profile.Rewards.

	CityBuilder calls Rewards.buildWorld(kit, parent) once Downtown is built; Main.server calls
	Rewards.init(ctx, deps).
]]

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Garden = require(script.Parent:WaitForChild("Garden"))

local R = Config.Rewards

local Rewards = {}

local MARBLE = Color3.fromRGB(236, 232, 224)
local GOLD = Color3.fromRGB(226, 180, 78)
local GLASS = Color3.fromRGB(22, 24, 36)
local VELVET = Color3.fromRGB(120, 12, 40)
local WARM = Color3.fromRGB(255, 214, 160)
local WALNUT = Color3.fromRGB(74, 50, 36)
local STONE = Color3.fromRGB(228, 208, 172) -- cream Riviera limestone
local STONE_DARK = Color3.fromRGB(196, 170, 130)
local COPPER = Color3.fromRGB(88, 146, 124) -- weathered copper roofs
local IRON = Color3.fromRGB(22, 22, 24)
local CREAM = Color3.fromRGB(236, 224, 200)

local FLOOR = 1.6 -- the hall's floor above the plaza
local H = 40 -- hall height
local HX = 85 -- half the building's width
-- the front wall and the hall's back wall (that follows the lot's size at build time)
local Z_FRONT = -40
local Z_HALL = 80

-- the claim desks' prompt parts (the server checks a claimer stands near one)
local deskParts: { BasePart } = {}

---------------------------------------------------------------------
-- Small builders
---------------------------------------------------------------------
-- a ready-made piece from ServerStorage.VenueKit (cleaned Creator Store models saved in the place,
-- facing -Z, pivot at the bottom middle), or nil
local function kitPiece(name: string, cf: CFrame, scale: number?, parent: Instance): Model?
	local vk = game:GetService("ServerStorage"):FindFirstChild("VenueKit")
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
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(120, 86, 30)
	st.Thickness = 1.5
	st.Parent = t
end

local function prompt(parent: Instance, action: string, object: string, hold: number, range: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = hold
	p.MaxActivationDistance = range or 10
	p.RequiresLineOfSight = false
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.Parent = parent
	return p
end

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
local function build(kit: any, parent: Instance, base: CFrame, lot: number)
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = "LegendsRewards"
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the front (the street)
	end
	local half = lot / 2
	Z_HALL = math.min(84, half - 20)
	local inside = kit.lodGroup(model, "RewardsInterior", base.Position, 700)

	-------------------------------------------------------------
	-- Plaza: marble, the red carpet, palms, fountains, bollards
	-------------------------------------------------------------
	mk(model, Vector3.new(lot, 0.3, lot), at(0, 0.15, 0), Color3.fromRGB(200, 194, 184), Enum.Material.Marble, { name = "Plaza" })
	deco(model, Vector3.new(16, 0.06, half + Z_FRONT + 2), at(0, 0.33, (-half + Z_FRONT) / 2 - 1), VELVET, Enum.Material.Fabric)
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(0.5, 0.07, half + Z_FRONT + 2), at(s * 8.2, 0.34, (-half + Z_FRONT) / 2 - 1), GOLD, Enum.Material.Metal)
	end
	-- steps up to the hall
	mk(model, Vector3.new(70, 0.65, 4), at(0, 0.62, Z_FRONT - 4), MARBLE, Enum.Material.Marble)
	mk(model, Vector3.new(70, 1.3, 2.2), at(0, 0.95, Z_FRONT - 1.1), MARBLE, Enum.Material.Marble)
	-- gold bollards across the doors: people walk through, cars don't
	for x = -12, 12, 4 do
		mk(model, Vector3.new(2.4, 1.4, 1.4), at(x, 1.5, Z_FRONT - 7) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Bollard" })
	end
	for _, s in { -1, 1 } do
		Garden.fountain(kit, model, at(s * 66, 0.3, -half + 26), 11)
		for k, z in { -half + 8, -half + 46, Z_FRONT - 4, -2, 36, 74 } do
			Garden.palm(kit, model, at(s * (half - 9), 0.3, z).Position, 30 + (k % 3) * 4, k * 31 + (if s > 0 then 7 else 0))
		end
		-- palms flanking the carpet
		Garden.palm(kit, model, at(s * 48, 0.3, -half + 6).Position, 26, 90 + s)
		-- gold floodlights washing the stone front
		for _, x in { 24, 50, 74 } do
			local lamp = deco(model, Vector3.new(1.6, 1, 1.6), at(s * x, 0.8, Z_FRONT - 6), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
			kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 196, 120), 70, 2.6, Enum.NormalId.Top, 50)
		end
		-- the gardens either side of the marquise: clipped box hedges round lawns, flower beds, topiary
		local gx = s * 50
		local gz0, gz1 = -68, Z_FRONT - 10
		local gl, gw = gz1 - gz0, 10
		deco(model, Vector3.new(gw, 0.2, gl), at(gx, 0.4, (gz0 + gz1) / 2), Color3.fromRGB(70, 118, 52), Enum.Material.Grass)
		for _, e in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
			local size = if e[1] == 0 then Vector3.new(gw, 1.6, 1.6) else Vector3.new(1.6, 1.6, gl)
			mk(model, size, at(gx + e[1] * (gw / 2 - 0.8), 1.1, (gz0 + gz1) / 2 + e[2] * (gl / 2 - 0.8)), Color3.fromRGB(42, 84, 40), Enum.Material.Grass, { name = "Hedge" })
		end
		for k = 0, 1 do
			local fz = gz0 + 5 + k * 8
			deco(model, Vector3.new(gw - 4, 0.5, 2.4), at(gx, 0.6, fz), Color3.fromRGB(150, 40, 60), Enum.Material.Grass)
			deco(model, Vector3.new(gw - 5, 0.55, 0.8), at(gx, 0.65, fz), Color3.fromRGB(240, 200, 90), Enum.Material.Grass)
			-- a clipped ball of box on a stem
			deco(model, Vector3.new(0.6, 2.4, 0.6), at(gx, 1.7, fz + 4), Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
			deco(model, Vector3.one * 3.2, at(gx, 4.2, fz + 4), Color3.fromRGB(46, 92, 44), Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
	end

	-------------------------------------------------------------
	-- Floors, walls, roof
	-------------------------------------------------------------
	mk(model, Vector3.new(HX * 2, FLOOR, Z_HALL - Z_FRONT), at(0, FLOOR / 2, (Z_FRONT + Z_HALL) / 2), MARBLE, Enum.Material.Marble, { name = "Floor" })
	-- the lobby's marble with a gold star inlay
	deco(model, Vector3.new(HX * 2 - 6, 0.06, 22), at(0, FLOOR + 0.03, Z_FRONT + 12), MARBLE, Enum.Material.Marble)
	for k = 0, 3 do
		deco(model, Vector3.new(14, 0.07, 1.2), at(0, FLOOR + 0.05, Z_FRONT + 12) * CFrame.Angles(0, math.rad(k * 45), 0), GOLD, Enum.Material.Metal)
	end
	-- side walls in cream stone: a darker plinth, paired pilasters,
	-- blind arched windows and a cornice
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(3, H, Z_HALL - Z_FRONT), at(s * (HX - 1.5), FLOOR + H / 2, (Z_FRONT + Z_HALL) / 2), STONE, Enum.Material.Limestone, { name = "Wall" })
		deco(model, Vector3.new(0.8, 4, Z_HALL - Z_FRONT), at(s * (HX + 0.3), FLOOR + 2, (Z_FRONT + Z_HALL) / 2), STONE_DARK, Enum.Material.Limestone)
		deco(model, Vector3.new(1.6, 2.4, Z_HALL - Z_FRONT + 2), at(s * (HX + 0.6), FLOOR + H - 1.2, (Z_FRONT + Z_HALL) / 2), STONE_DARK, Enum.Material.Limestone)
		local bays = math.floor((Z_HALL - Z_FRONT - 20) / 22)
		for k = 0, bays do
			local z = Z_FRONT + 14 + k * 22
			if z < Z_HALL - 4 then
				for _, dz in { -1.6, 1.6 } do
					deco(model, Vector3.new(0.8, H - 6.4, 1.6), at(s * (HX + 0.3), FLOOR + 4 + (H - 6.4) / 2, z + dz), STONE, Enum.Material.Limestone)
				end
				-- a blind arched window between this pair and the next
				local wz = z + 11
				if wz < Z_HALL - 8 then
					deco(model, Vector3.new(0.4, 18, 8), at(s * (HX + 0.15), FLOOR + 6 + 9, wz), GLASS, Enum.Material.Glass, { reflectance = 0.25 })
					deco(model, Vector3.new(0.5, 8, 8), at(s * (HX + 0.15), FLOOR + 24, wz) * CFrame.Angles(0, 0, math.rad(90)), GLASS, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, reflectance = 0.25 })
					deco(model, Vector3.new(0.6, 1, 10), at(s * (HX + 0.35), FLOOR + 5.6, wz), STONE_DARK, Enum.Material.Limestone)
				end
			end
		end
	end
	-- the hall's back wall: stone outside, cream panelling inside
	mk(model, Vector3.new(HX * 2, H, 2), at(0, FLOOR + H / 2, Z_HALL), STONE, Enum.Material.Limestone, { name = "Wall" })
	deco(inside, Vector3.new(HX * 2 - 6, H - 6, 0.4), at(0, FLOOR + (H - 6) / 2 + 0.5, Z_HALL - 1.2), CREAM, Enum.Material.Plaster)
	-- the front in cream stone: round-headed windows between paired pilasters, a grand arched
	-- entrance in the middle (open, its glass doors pushed to the sides), a frieze with the name in
	-- gold letters, a cornice and a balustrade
	local doorHalf, doorH = 14, 24
	local fz = Z_FRONT
	-- a round head over an opening: glass strips filling the half circle, stone voussoirs round it
	-- and a gold keystone
	local function archHead(cx: number, y0: number, w: number, z: number)
		local r = w / 2
		local n = 6
		for k = 0, n - 1 do
			local x0 = -r + k * w / n
			local xm = x0 + w / (2 * n)
			local hgt = math.sqrt(math.max(r * r - xm * xm, 0))
			deco(model, Vector3.new(w / n + 0.05, hgt, 0.6), at(cx + xm, y0 + hgt / 2, z), GLASS, Enum.Material.Glass, { reflectance = 0.3 })
		end
		for k = 0, 8 do
			local a = math.rad(k * 22.5)
			local px, py = math.cos(a) * (r + 0.9), math.sin(a) * (r + 0.9)
			deco(model, Vector3.new(2.2, 1.6, 1.6), at(cx + px, y0 + py, z - 0.4) * CFrame.Angles(0, 0, a + math.pi / 2), STONE_DARK, Enum.Material.Limestone)
		end
		deco(model, Vector3.new(2, 2.6, 1.8), at(cx, y0 + r + 1.2, z - 0.6), GOLD, Enum.Material.Metal, { reflectance = 0.2 })
	end
	-- the wall itself: stone above the openings, the openings glazed (windows) or open (the door)
	local winW, winH = 14, 20
	local bays = { -70, -50, -30, 30, 50, 70 }
	-- the stone face behind everything (holes are where the glass and the door go)
	local cuts = { { -doorHalf, doorHalf, 0, doorH } }
	for _, x in bays do
		table.insert(cuts, { x - winW / 2, x + winW / 2, 4, 4 + winH })
	end
	-- the wall in vertical strips between the openings, and the pieces above / below each
	local edges = { -HX }
	for _, c in cuts do
		table.insert(edges, c[1])
		table.insert(edges, c[2])
	end
	table.insert(edges, HX)
	table.sort(edges)
	for i = 1, #edges - 1 do
		local x0, x1 = edges[i], edges[i + 1]
		if x1 - x0 > 0.05 then
			local mid = (x0 + x1) / 2
			local hole: { number }? = nil
			for _, c in cuts do
				if mid > c[1] and mid < c[2] then
					hole = c
				end
			end
			if hole then
				-- below and above the opening
				if hole[3] > 0 then
					mk(model, Vector3.new(x1 - x0, hole[3], 2), at(mid, FLOOR + hole[3] / 2, fz), STONE, Enum.Material.Limestone, { name = "Facade" })
				end
				mk(model, Vector3.new(x1 - x0, H - hole[4], 2), at(mid, FLOOR + (hole[4] + H) / 2, fz), STONE, Enum.Material.Limestone, { name = "Facade" })
			else
				mk(model, Vector3.new(x1 - x0, H, 2), at(mid, FLOOR + H / 2, fz), STONE, Enum.Material.Limestone, { name = "Facade" })
			end
		end
	end
	-- the windows: glass, iron mullions and transom, a round head, a sill
	for _, x in bays do
		mk(model, Vector3.new(winW, winH, 0.6), at(x, FLOOR + 4 + winH / 2, fz - 0.6), GLASS, Enum.Material.Glass, { transparency = 0.35, reflectance = 0.25, name = "Window" })
		deco(model, Vector3.new(0.5, winH, 0.4), at(x, FLOOR + 4 + winH / 2, fz - 1), IRON, Enum.Material.Metal)
		deco(model, Vector3.new(winW, 0.5, 0.4), at(x, FLOOR + 4 + winH * 0.7, fz - 1), IRON, Enum.Material.Metal)
		archHead(x, FLOOR + 4 + winH, winW, fz - 1.1)
		deco(model, Vector3.new(winW + 2, 0.8, 2), at(x, FLOOR + 3.6, fz - 1.4), STONE_DARK, Enum.Material.Limestone)
		-- a little iron balconette in front of each window
		deco(model, Vector3.new(winW, 0.3, 0.3), at(x, FLOOR + 7.4, fz - 2.2), IRON, Enum.Material.Metal)
		for k = -3, 3 do
			deco(model, Vector3.new(0.2, 3.2, 0.2), at(x + k * 2, FLOOR + 5.8, fz - 2.2), IRON, Enum.Material.Metal)
		end
	end
	-- the grand entrance: a deep stone surround, the round glass fan above it, gold rays
	archHead(0, FLOOR + doorH, doorHalf * 2, fz - 1.1)
	for _, sx in { -1, 1 } do
		deco(model, Vector3.new(2.4, doorH, 3), at(sx * (doorHalf + 1.2), FLOOR + doorH / 2, fz - 0.6), STONE_DARK, Enum.Material.Limestone)
		-- open glass doors pushed to the sides
		deco(model, Vector3.new(6, doorH - 2, 0.4), at(sx * (doorHalf - 3.4), FLOOR + (doorH - 2) / 2, fz + 1.6), Color3.fromRGB(220, 200, 150), Enum.Material.Glass, { transparency = 0.6 })
	end
	for k = 0, 6 do
		local a = math.rad(15 + k * 25)
		deco(model, Vector3.new(0.4, doorHalf - 2, 0.3), at(math.cos(a) * (doorHalf - 2) / 2, FLOOR + doorH + math.sin(a) * (doorHalf - 2) / 2, fz - 1.6) * CFrame.Angles(0, 0, a - math.pi / 2), GOLD, Enum.Material.Metal)
	end
	-- paired pilasters with gold capitals between the bays and at the corners
	for _, x in { -60, -40, -20, 20, 40, 60 } do
		for _, dx in { -1.3, 1.3 } do
			deco(model, Vector3.new(1.8, H - 8, 1.2), at(x + dx, FLOOR + 4 + (H - 8) / 2, fz - 1.4), STONE, Enum.Material.Limestone)
			deco(model, Vector3.new(2.4, 1.2, 1.6), at(x + dx, FLOOR + H - 4.6, fz - 1.5), GOLD, Enum.Material.Metal)
		end
		deco(model, Vector3.new(6, 4, 2.4), at(x, FLOOR + 2, fz - 1.4), STONE_DARK, Enum.Material.Limestone)
	end
	-- the plinth, the frieze with the name, the cornice, the balustrade
	deco(model, Vector3.new(HX * 2 + 2, 1.2, 2.6), at(0, FLOOR + 0.6, fz - 1.3), STONE_DARK, Enum.Material.Limestone)
	local frieze = mk(model, Vector3.new(HX * 2 + 2, 6, 2.4), at(0, FLOOR + H + 1, fz - 0.4), STONE, Enum.Material.Limestone, { name = "Frieze" })
	local nameBand = deco(model, Vector3.new(96, 4.4, 0.2), at(0, FLOOR + H + 1, fz - 1.7), STONE, Enum.Material.Limestone)
	goldLetters(nameBand, Enum.NormalId.Front, "LEGENDS  REWARDS", 10, 1.6)
	kit.addLight("SpotLight", frieze, WARM, 30, 1.2, Enum.NormalId.Front, 70)
	for _, y in { FLOOR + H - 2.2, FLOOR + H + 4.2 } do
		deco(model, Vector3.new(HX * 2 + 4, 1.2, 4), at(0, y, fz - 1), STONE_DARK, Enum.Material.Limestone)
	end
	deco(model, Vector3.new(HX * 2 + 4, 0.4, 0.5), at(0, FLOOR + H - 1.4, fz - 3), GOLD, Enum.Material.Metal)
	local by = FLOOR + H + 4.8
	deco(model, Vector3.new(HX * 2, 0.8, 1.6), at(0, by + 3.2, fz - 0.6), STONE, Enum.Material.Limestone)
	for x = -HX + 2, HX - 2, 3.4 do
		deco(model, Vector3.new(2.8, 1.1, 1.1), at(x, by + 1.4, fz - 0.6) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
	end
	-- the hall's roof (copper), a gilded coffered ceiling and warm coves inside
	mk(model, Vector3.new(HX * 2, 2, Z_HALL - Z_FRONT), at(0, FLOOR + H + 1, (Z_FRONT + Z_HALL) / 2), COPPER, Enum.Material.Metal, { name = "Roof" })
	deco(inside, Vector3.new(HX * 2 - 6, 0.6, Z_HALL - Z_FRONT - 4), at(0, FLOOR + H - 1.6, (Z_FRONT + Z_HALL) / 2), CREAM, Enum.Material.Plaster)
	for x = -HX + 10, HX - 10, 16 do
		deco(inside, Vector3.new(1.2, 1.4, Z_HALL - Z_FRONT - 6), at(x, FLOOR + H - 2.4, (Z_FRONT + Z_HALL) / 2), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
	end
	for z = Z_FRONT + 8, Z_HALL - 6, 16 do
		deco(inside, Vector3.new(HX * 2 - 8, 1.4, 1.2), at(0, FLOOR + H - 2.4, z), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
	end
	for _, s in { -1, 1 } do
		local cove = deco(inside, Vector3.new(0.6, 0.4, Z_HALL - Z_FRONT - 8), at(s * (HX - 6), FLOOR + H - 3.4, (Z_FRONT + Z_HALL) / 2), WARM, Enum.Material.Neon, { transparency = 0.25 })
		kit.addLight("SurfaceLight", cove, WARM, 18, 0.6, Enum.NormalId.Top, 120)
		-- the hall's walls: cream panels, gold pilasters, sconces
		deco(inside, Vector3.new(0.4, H - 6, Z_HALL - Z_FRONT - 4), at(s * (HX - 3.2), FLOOR + (H - 6) / 2 + 0.5, (Z_FRONT + Z_HALL) / 2), CREAM, Enum.Material.Plaster)
		for z = Z_FRONT + 14, Z_HALL - 10, 22 do
			deco(inside, Vector3.new(0.6, H - 8, 1.4), at(s * (HX - 3.6), FLOOR + (H - 8) / 2 + 0.5, z), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
			local sconce = deco(inside, Vector3.new(0.8, 1.6, 0.8), at(s * (HX - 4.2), FLOOR + 12, z + 11), WARM, Enum.Material.Neon, { transparency = 0.2 })
			kit.addLight("PointLight", sconce, WARM, 16, 0.6)
		end
	end
	for _, z in { Z_FRONT + 2, Z_HALL - 6 } do
		deco(inside, Vector3.new(HX * 2 - 12, 0.4, 0.6), at(0, FLOOR + H - 3.4, z), WARM, Enum.Material.Neon, { transparency = 0.25 })
	end

	-------------------------------------------------------------
	-- The corner towers and the dome
	-------------------------------------------------------------
	for _, s in { -1, 1 } do
		local tx, tz2 = s * (HX + 3), Z_FRONT + 6
		local tTop = FLOOR + H + 22
		mk(model, Vector3.new(16, tTop - FLOOR, 16), at(tx, FLOOR + (tTop - FLOOR) / 2, tz2), STONE, Enum.Material.Limestone, { name = "CornerTower" })
		-- round-headed openings on the outside faces, a cornice, the copper dome and a gold finial
		for _, face in { { 0, -1 }, { s, 0 } } do
			local ox, oz = face[1] * 8.15, face[2] * 8.15
			local c = at(tx + ox, FLOOR + H + 10, tz2 + oz)
			local rot = if face[1] ~= 0 then CFrame.Angles(0, math.pi / 2, 0) else CFrame.identity
			deco(model, Vector3.new(5, 10, 0.4), c * rot, GLASS, Enum.Material.Glass, { reflectance = 0.3 })
			deco(model, Vector3.new(0.5, 5, 5), c * rot * CFrame.new(0, 5, 0) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, 0), GLASS, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, reflectance = 0.3 })
		end
		deco(model, Vector3.new(18, 1.4, 18), at(tx, tTop - 0.7, tz2), STONE_DARK, Enum.Material.Limestone)
		deco(model, Vector3.new(17, 3, 17), at(tx, tTop + 1.5, tz2), STONE, Enum.Material.Limestone)
		mk(model, Vector3.one * 16, at(tx, tTop + 3, tz2), COPPER, Enum.Material.Metal, { shape = Enum.PartType.Ball, name = "Dome" })
		deco(model, Vector3.new(2.4, 4, 2.4), at(tx, tTop + 12.6, tz2), GOLD, Enum.Material.Metal, { reflectance = 0.25 })
		deco(model, Vector3.one * 1.8, at(tx, tTop + 15.4, tz2), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.25 })
		local flood = deco(model, Vector3.new(1.2, 1, 1.2), at(tx, FLOOR + H + 3.2, tz2 - 10), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", flood, Color3.fromRGB(255, 200, 120), 50, 2.2, Enum.NormalId.Top, 40)
	end
	-- the great dome over the hall: a stone drum with round windows, the copper dome, a lantern
	local dz = (Z_FRONT + Z_HALL) / 2 + 6
	local dTop = FLOOR + H + 2
	mk(model, Vector3.new(12, 46, 46), at(0, dTop + 6, dz) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder, name = "Drum" })
	deco(model, Vector3.new(1.4, 48, 48), at(0, dTop + 12.5, dz) * CFrame.Angles(0, 0, math.rad(90)), STONE_DARK, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
	for k = 0, 11 do
		local a = k / 12 * math.pi * 2
		deco(model, Vector3.new(0.4, 3.6, 3.6), at(math.cos(a) * 23.05, dTop + 6, dz + math.sin(a) * 23.05) * CFrame.Angles(0, -a, 0), GLASS, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, reflectance = 0.3 })
	end
	mk(model, Vector3.one * 44, at(0, dTop + 12, dz), COPPER, Enum.Material.Metal, { shape = Enum.PartType.Ball, name = "Dome" })
	mk(model, Vector3.new(8, 6, 6), at(0, dTop + 36, dz) * CFrame.Angles(0, 0, math.rad(90)), STONE, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
	deco(model, Vector3.new(1, 7, 7), at(0, dTop + 40.4, dz) * CFrame.Angles(0, 0, math.rad(90)), COPPER, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	deco(model, Vector3.new(1.2, 6, 1.2), at(0, dTop + 44, dz), GOLD, Enum.Material.Metal, { reflectance = 0.25 })
	deco(model, Vector3.one * 2.2, at(0, dTop + 47.6, dz), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.25 })
	local lanternGlow = deco(model, Vector3.new(1, 1, 1), at(0, dTop + 36, dz - 4), WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
	kit.addLight("PointLight", lanternGlow, WARM, 20, 1)
	for _, p in { { -26, -1 }, { 26, -1 }, { 0, 1 } } do
		local wash = deco(model, Vector3.new(1.4, 1, 1.4), at(p[1], dTop + 1, dz + p[2] * 30), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", wash, Color3.fromRGB(255, 196, 110), 70, 2.4, Enum.NormalId.Top, 50)
	end
	-- a copper mansard round the roof's edge behind the balustrade
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(4, 4, Z_HALL - Z_FRONT - 4), at(s * (HX - 4), FLOOR + H + 4, (Z_FRONT + Z_HALL) / 2 + 2) * CFrame.Angles(0, 0, s * math.rad(20)), COPPER, Enum.Material.Metal)
	end

	-------------------------------------------------------------
	-- The marquise: an iron-and-glass canopy over the carpet, gold letters on its fascia, lanterns
	-------------------------------------------------------------
	local cz = Z_FRONT - 24
	local canopy = mk(model, Vector3.new(84, 0.6, 44), at(0, 21, cz), IRON, Enum.Material.Metal, { name = "Canopy", transparency = 1 })
	canopy.CanCollide = true
	-- the glass roof on iron ribs, tipped gently towards the street
	local tilt = CFrame.Angles(math.rad(-4), 0, 0)
	deco(model, Vector3.new(82, 0.3, 43), at(0, 21.6, cz) * tilt, Color3.fromRGB(180, 200, 210), Enum.Material.Glass, { transparency = 0.55, reflectance = 0.2 })
	for x = -40, 40, 8 do
		deco(model, Vector3.new(0.5, 0.8, 44), at(x, 21.2, cz) * tilt, IRON, Enum.Material.Metal)
	end
	deco(model, Vector3.new(85, 0.6, 0.6), at(0, 22.4, cz + 21.8) * tilt, GOLD, Enum.Material.Metal)
	-- the fascia with the name and a gold crest of rays
	mk(model, Vector3.new(86, 3.6, 1), at(0, 20.4, cz - 22.2), IRON, Enum.Material.Metal, { name = "Fascia" })
	deco(model, Vector3.new(86.4, 0.4, 1.2), at(0, 22.4, cz - 22.2), GOLD, Enum.Material.Metal)
	deco(model, Vector3.new(86.4, 0.4, 1.2), at(0, 18.4, cz - 22.2), GOLD, Enum.Material.Metal)
	local fl = deco(model, Vector3.new(60, 3, 0.2), at(0, 20.4, cz - 22.8), IRON, Enum.Material.Metal)
	goldLetters(fl, Enum.NormalId.Front, "LEGENDS  REWARDS", 12, 1.6)
	for k = 0, 6 do
		local a = math.rad(15 + k * 25)
		deco(model, Vector3.new(0.3, 3.4, 0.3), at(math.cos(a) * 1.7, 24 + math.sin(a) * 1.7, cz - 22.2) * CFrame.Angles(0, 0, a - math.pi / 2), GOLD, Enum.Material.Metal)
	end
	deco(model, Vector3.one * 1.4, at(0, 23.6, cz - 22.2), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	for _, s in { -1, 1 } do
		deco(model, Vector3.new(1, 3.6, 44), at(s * 42.5, 20.4, cz), IRON, Enum.Material.Metal)
		-- iron columns with gold collars and lanterns on top
		for _, z in { cz - 18, cz + 14 } do
			mk(model, Vector3.new(20, 1.6, 1.6), at(s * 36, 10.5, z) * CFrame.Angles(0, 0, math.rad(90)), IRON, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "Column" })
			deco(model, Vector3.new(0.6, 2.4, 2.4), at(s * 36, 1.4, z) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
			deco(model, Vector3.new(0.6, 2.2, 2.2), at(s * 36, 19.6, z) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		end
		local lantern = deco(model, Vector3.new(1.6, 2.4, 1.6), at(s * 30, 18.4, cz - 22.8), Color3.fromRGB(255, 226, 170), Enum.Material.Neon, { transparency = 0.15, name = "Lantern" })
		deco(model, Vector3.new(2.2, 0.4, 2.2), at(s * 30, 19.8, cz - 22.8), IRON, Enum.Material.Metal)
		kit.addLight("PointLight", lantern, WARM, 18, 1)
	end
	for _, x in { -24, 0, 24 } do
		local down = deco(model, Vector3.new(4, 0.3, 4), at(x, 20.4, cz), Color3.fromRGB(255, 236, 200), Enum.Material.Neon, { transparency = 0.2 })
		kit.addLight("SpotLight", down, WARM, 30, 2.2, Enum.NormalId.Bottom, 90)
	end

	-------------------------------------------------------------
	-- Inside: the lobby chandelier and rope lines
	-------------------------------------------------------------
	-- crystal chandeliers (VenueKit): the lobby, down the middle of the hall; tiers of glass drops
	-- round a gold hub if the kit isn't in the place
	for _, p in { { 0, Z_FRONT + 16, 1.6 }, { 0, 14, 1.8 }, { -40, 30, 1.4 }, { 40, 30, 1.4 } } do
		local top = FLOOR + H - 2.4
		local cf = at(p[1], top - 14.92 * p[3], p[2])
		if kitPiece("Chandelier", cf, p[3], inside) then
			local bulb = deco(inside, Vector3.new(1, 1, 1), at(p[1], top - 9, p[2]), WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
			kit.addLight("PointLight", bulb, WARM, 50, 1.6)
		else
			local ch = at(p[1], FLOOR + H - 10, p[2])
			local hub = deco(inside, Vector3.new(3, 4, 4), ch * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
			deco(inside, Vector3.new(0.3, 7, 0.3), ch * CFrame.new(0, 5, 0), GOLD, Enum.Material.Metal)
			for ring = 1, 2 do
				local r = 4 + ring * 3
				local n = 10 + ring * 6
				for k = 0, n - 1 do
					local a = k / n * math.pi * 2
					deco(inside, Vector3.new(0.6, 1.8 + ring * 0.6, 0.6), ch * CFrame.new(math.cos(a) * r, -ring * 1.6, math.sin(a) * r), Color3.fromRGB(240, 248, 255), Enum.Material.Glass, { transparency = 0.2, reflectance = 0.4 })
				end
			end
			kit.addLight("PointLight", hub, WARM, 50, 1.8)
		end
	end
	for _, s in { -1, 1 } do
		for k = 0, 3 do
			local z = Z_FRONT + 6 + k * 6
			deco(inside, Vector3.new(0.5, 3.2, 0.5), at(s * 9, FLOOR + 1.6, z), GOLD, Enum.Material.Metal)
			deco(inside, Vector3.one * 0.8, at(s * 9, FLOOR + 3.4, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
			if k < 3 then
				deco(inside, Vector3.new(0.3, 0.3, 6), at(s * 9, FLOOR + 2.8, z + 3), VELVET, Enum.Material.Fabric)
			end
		end
	end

	-------------------------------------------------------------
	-- The hall: a red runner to the daily desk, the claim desks, the two spin cabinets
	-------------------------------------------------------------
	deco(inside, Vector3.new(12, 0.06, Z_HALL - Z_FRONT - 24), at(0, FLOOR + 0.03, (Z_FRONT + 22 + Z_HALL - 2) / 2), VELVET, Enum.Material.Fabric)
	for _, s in { -1, 1 } do
		deco(inside, Vector3.new(0.4, 0.07, Z_HALL - Z_FRONT - 24), at(s * 6.2, FLOOR + 0.04, (Z_FRONT + 22 + Z_HALL - 2) / 2), GOLD, Enum.Material.Metal)
	end
	-- a claim desk: a walnut counter with a marble top and gold trim, a stone board above it with
	-- the desk's name in gold letters, a warm lamp, and the prompt that opens its page
	local function desk(cf: CFrame, w: number, title: string, tab: string, action: string)
		mk(inside, Vector3.new(w, 3.8, 4), cf * CFrame.new(0, 1.9, 0), WALNUT, Enum.Material.Wood, { name = "RewardsDesk" })
		deco(inside, Vector3.new(w + 0.4, 0.4, 4.4), cf * CFrame.new(0, 4, 0), MARBLE, Enum.Material.Marble)
		deco(inside, Vector3.new(w + 0.2, 0.3, 0.2), cf * CFrame.new(0, 0.9, -2.1), GOLD, Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			deco(inside, Vector3.new(0.4, 3.8, 0.4), cf * CFrame.new(sx * (w / 2 - 0.3), 1.9, -2.1), GOLD, Enum.Material.Metal)
		end
		mk(inside, Vector3.new(w + 2, 4, 1), cf * CFrame.new(0, 11, 4), STONE, Enum.Material.Limestone, { name = "DeskBoard" })
		deco(inside, Vector3.new(w + 2.4, 0.4, 1.2), cf * CFrame.new(0, 13.2, 4), GOLD, Enum.Material.Metal)
		deco(inside, Vector3.new(w + 2.4, 0.4, 1.2), cf * CFrame.new(0, 8.8, 4), GOLD, Enum.Material.Metal)
		local face = deco(inside, Vector3.new(w + 1, 3, 0.2), cf * CFrame.new(0, 11, 3.4), STONE, Enum.Material.Limestone)
		goldLetters(face, Enum.NormalId.Front, title, 14, 1.4)
		for _, sx in { -1, 1 } do
			deco(inside, Vector3.new(1.2, 8, 1.2), cf * CFrame.new(sx * (w / 2 + 0.4), 4.8, 4), STONE_DARK, Enum.Material.Limestone)
		end
		local lamp = deco(inside, Vector3.new(2.4, 0.3, 2.4), cf * CFrame.new(0, 16, 0), WARM, Enum.Material.Neon, { transparency = 0.2 })
		kit.addLight("SpotLight", lamp, WARM, 22, 1.8, Enum.NormalId.Bottom, 80)
		deco(inside, Vector3.new(0.2, H - 17, 0.2), cf * CFrame.new(0, 16 + (H - 17) / 2, 0), GOLD, Enum.Material.Metal)
		-- the prompt sits on the room side of the counter
		local spot = deco(inside, Vector3.new(2, 2, 2), cf * CFrame.new(0, 3, -3.4), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "DeskPrompt" })
		local p = prompt(spot, action, title, 0, 12)
		p:SetAttribute("Tab", tab)
		CollectionService:AddTag(p, "RewardsDesk")
		table.insert(deskParts, spot)
		-- a palm either side
		for _, sx in { -1, 1 } do
			if not kitPiece("PottedPalm", cf * CFrame.new(sx * (w / 2 + 4), 0, 1.5), 1.6, inside) then
				deco(inside, Vector3.new(2.4, 3, 2.4), cf * CFrame.new(sx * (w / 2 + 4), 1.5, 1.5), STONE_DARK, Enum.Material.Limestone)
			end
		end
	end
	-- the daily desk in the middle of the back wall, three desks down each side wall
	local fy = FLOOR
	desk(at(0, fy, Z_HALL - 14), 26, "DAILY REWARD", "daily", "Daily reward")
	local sideZ = { Z_FRONT + 38, Z_FRONT + 38 + (Z_HALL - Z_FRONT - 58) / 2, Z_HALL - 20 }
	local left = { { "GIFTS", "gifts", "Gifts" }, { "LEVEL REWARDS", "levels", "Level rewards" }, { "ACHIEVEMENTS", "achievements", "Achievements" } }
	local right = { { "FRIENDS", "friends", "Friends" }, { "CODES", "codes", "Enter a code" }, { "PROPERTY", "property", "Rent and income" } }
	for k, z in sideZ do
		-- (a desk's front is its -z: turned to face the middle of the hall)
		desk(at(-HX + 14, fy, z) * CFrame.Angles(0, -math.pi / 2, 0), 16, left[k][1], left[k][2], left[k][3])
		desk(at(HX - 14, fy, z) * CFrame.Angles(0, math.pi / 2, 0), 16, right[k][1], right[k][2], right[k][3])
	end
	-- the two spin cabinets on the back wall either side of the daily desk: a lit board with the
	-- name, one reel (SPIN) or three (SUPER SPIN) of prize cards, gold frames; a podium with the
	-- prompt in front (the spin itself plays in the rewards screen)
	for _, cdef in { { -40, "wheel", "SPIN", 1 }, { 40, "super", "SUPER SPIN", 3 } } do
		local x, id, title, n = cdef[1], cdef[2], cdef[3], cdef[4]
		local bw = 6 + n * 7
		local bh = 22
		local c = at(x, fy + 4 + bh / 2, Z_HALL - 1.8)
		mk(inside, Vector3.new(bw + 1.2, bh + 1.2, 1), c, GOLD, Enum.Material.Metal, { reflectance = 0.2, name = "SpinCabinet" })
		local face = deco(inside, Vector3.new(bw, bh, 0.2), c * CFrame.new(0, 0, -0.6), Color3.fromRGB(26, 10, 16), Enum.Material.SmoothPlastic)
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 20
		sg.LightInfluence = 0.2
		sg.Brightness = 1.3
		sg.MaxDistance = 300
		sg.Parent = face
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = if n > 1 then Color3.fromRGB(120, 20, 50) else Color3.fromRGB(30, 50, 110)
		bg.Parent = sg
		local grad = Instance.new("UIGradient")
		grad.Color = if n > 1 then ColorSequence.new(Color3.fromRGB(255, 120, 60), Color3.fromRGB(150, 20, 90)) else ColorSequence.new(Color3.fromRGB(60, 140, 255), Color3.fromRGB(20, 40, 120))
		grad.Rotation = 90
		grad.Parent = bg
		local head = Instance.new("TextLabel")
		head.BackgroundTransparency = 1
		head.Size = UDim2.fromScale(1, 0.16)
		head.Position = UDim2.fromScale(0, 0.02)
		head.TextScaled = true
		head.Font = Enum.Font.GothamBlack
		head.Text = title
		head.TextColor3 = Color3.fromRGB(255, 230, 140)
		head.Parent = bg
		local hs = Instance.new("UIStroke")
		hs.Thickness = 3
		hs.Color = Color3.fromRGB(80, 30, 0)
		hs.Parent = head
		local prizes = R.Wheels[id].prizes
		for r = 1, n do
			local col = Instance.new("Frame")
			col.BackgroundColor3 = Color3.fromRGB(40, 16, 26)
			col.Position = UDim2.new((r - 1) / n, 8, 0.2, 0)
			col.Size = UDim2.new(1 / n, -16, 0.76, 0)
			col.Parent = bg
			local cc = Instance.new("UICorner")
			cc.CornerRadius = UDim.new(0, 10)
			cc.Parent = col
			for k = 1, 3 do
				-- (a car on the middle row of the middle reel, the rest a spread of prizes)
				local pz = if k == 2 and r == math.ceil(n / 2) then prizes[#prizes] else prizes[((r * 4 + k * 3) % #prizes) + 1]
				local card = Instance.new("Frame")
				card.BackgroundColor3 = if pz.car then Color3.fromRGB(110, 210, 255) elseif pz.flex then Color3.fromRGB(200, 140, 255) elseif pz.spin then Color3.fromRGB(255, 130, 190) elseif pz.weight <= 2 then Color3.fromRGB(255, 210, 80) else Color3.fromRGB(200, 240, 90)
				card.Position = UDim2.new(0, 6, (k - 1) / 3, 6)
				card.Size = UDim2.new(1, -12, 1 / 3, -12)
				card.Parent = col
				local kc = Instance.new("UICorner")
				kc.CornerRadius = UDim.new(0, 8)
				kc.Parent = card
				local t = Instance.new("TextLabel")
				t.BackgroundTransparency = 1
				t.Size = UDim2.fromScale(1, 1)
				t.TextScaled = true
				t.Font = Enum.Font.GothamBlack
				t.TextColor3 = Color3.fromRGB(30, 20, 10)
				t.Text = if pz.car then "CAR" elseif pz.flex then "JEWEL" elseif pz.spin then "+1 SPIN" elseif pz.cash >= 1000000 then string.format("$%gM", pz.cash / 1000000) else string.format("$%gK", pz.cash / 1000)
				t.Parent = card
				local tp = Instance.new("UIPadding")
				tp.PaddingTop = UDim.new(0.18, 0)
				tp.PaddingBottom = UDim.new(0.18, 0)
				tp.Parent = t
				if k == 2 then
					local ks = Instance.new("UIStroke")
					ks.Thickness = 4
					ks.Color = Color3.new(1, 1, 1)
					ks.Parent = card
				end
			end
		end
		local glow = deco(inside, Vector3.new(bw, 0.4, 0.4), c * CFrame.new(0, -bh / 2 - 0.6, -0.6), WARM, Enum.Material.Neon, { transparency = 0.2 })
		kit.addLight("SurfaceLight", glow, WARM, 12, 0.8, Enum.NormalId.Top, 90)
		mk(inside, Vector3.new(6, 3.4, 4), at(x, fy + 1.7, Z_HALL - 10), WALNUT, Enum.Material.Wood, { name = "WheelPodium" })
		deco(inside, Vector3.new(6.4, 0.4, 4.4), at(x, fy + 3.6, Z_HALL - 10), MARBLE, Enum.Material.Marble)
		local spot = deco(inside, Vector3.new(2, 2, 2), at(x, fy + 3, Z_HALL - 13), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "DeskPrompt" })
		local p = prompt(spot, "Spin", title, 0, 12)
		p:SetAttribute("Tab", id)
		CollectionService:AddTag(p, "RewardsDesk")
		table.insert(deskParts, spot)
		local wl = deco(inside, Vector3.new(2, 0.3, 2), at(x, fy + H - 6, Z_HALL - 8), WARM, Enum.Material.Neon, { transparency = 0.2 })
		kit.addLight("SpotLight", wl, WARM, 40, 2, Enum.NormalId.Bottom, 40)
	end
	-- benches down the middle (people wait their turn)
	for _, s in { -1, 1 } do
		for _, z in { Z_FRONT + 44, Z_FRONT + 70 } do
			if not kitPiece("Chesterfield", at(s * 22, fy, z) * CFrame.Angles(0, s * math.pi / 2, 0), 1.1, inside) then
				deco(inside, Vector3.new(4, 2, 12), at(s * 22, fy + 1, z), VELVET, Enum.Material.Fabric)
			end
		end
	end
end

-- builds Legends Rewards on its Downtown site
function Rewards.buildWorld(kit: any, parent: Instance)
	local frame, lot = WestLayout.site("rewards")
	build(kit, parent, frame, lot)
end

---------------------------------------------------------------------
-- What each player has earned (saved as profile.Rewards)
---------------------------------------------------------------------
type Data = {
	PlayDate: string, -- the UTC day the playtime counts for
	PlaySecs: number, -- seconds played that day
	PlayGot: { [string]: boolean }, -- playtime gifts taken that day ("1".."4")
	WeekLast: number, -- os.time() of the last weekly gift (0 = never)
	LevelPaid: number, -- the highest level whose level reward was taken
	Codes: { [string]: boolean },
	Group: boolean,
	FriendDate: string, -- the UTC day the friend gift was last taken
	InviteGot: boolean, -- the gift for joining from a friend's invite
	Invited: { [string]: boolean }, -- user ids whose invite gift this player took
	ReturnReady: boolean, -- the welcome back gift is waiting
	Spins: { [string]: number }, -- bought spins left, per wheel
	FreeLast: { [string]: number }, -- os.time() of each wheel's last free spin
	Receipts: { string }, -- the last Robux purchase ids granted (never twice)
}

local deps: any = {} -- Goals, Towers, Hotel (from Main: no require loops)
local push: RemoteEvent? = nil
local session: { [Player]: { friend: boolean, inviter: { number }, invitee: boolean, group: boolean?, paidOk: boolean, busy: boolean, last: number } } = {}
local cleaned: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function today(): string
	return os.date("!%Y-%m-%d") :: string
end

local function int(v: any, lo: number, hi: number): number
	return if type(v) == "number" and v == v then math.clamp(math.floor(v), lo, hi) else lo
end

-- the profile's Rewards table, cleaned up (older saves: the level reward starts from the level
-- they have, so nobody is paid for levels from before)
local function data(profile: any): Data
	local raw = profile.Rewards
	if type(raw) ~= "table" then
		raw = {}
	end
	if cleaned[raw] then
		return raw
	end
	local function set(v: any): { [string]: boolean }
		local out = {}
		if type(v) == "table" then
			for k, on in v do
				if type(k) == "string" and on == true then
					out[k] = true
				end
			end
		end
		return out
	end
	local function nums(v: any, hi: number): { [string]: number }
		local out = {}
		if type(v) == "table" then
			for k, n in v do
				if type(k) == "string" and R.Wheels[k] then
					out[k] = int(n, 0, hi)
				end
			end
		end
		return out
	end
	local receipts = {}
	if type(raw.Receipts) == "table" then
		for _, id in raw.Receipts do
			if type(id) == "string" and #receipts < 50 then
				table.insert(receipts, id)
			end
		end
	end
	local level = profile.Level or 1
	local d: Data = {
		PlayDate = if type(raw.PlayDate) == "string" then raw.PlayDate else today(),
		PlaySecs = int(raw.PlaySecs, 0, 86400),
		PlayGot = set(raw.PlayGot),
		WeekLast = int(raw.WeekLast, 0, os.time()),
		LevelPaid = if type(raw.LevelPaid) == "number" then int(raw.LevelPaid, 1, 10000) elseif profile.IsNew then 1 else level,
		Codes = set(raw.Codes),
		Group = raw.Group == true,
		FriendDate = if type(raw.FriendDate) == "string" then raw.FriendDate else "",
		InviteGot = raw.InviteGot == true,
		Invited = set(raw.Invited),
		ReturnReady = raw.ReturnReady == true or (not profile.IsNew and (profile.Away or 0) >= R.ReturnAway),
		Spins = nums(raw.Spins, 100000),
		FreeLast = nums(raw.FreeLast, os.time()),
		Receipts = receipts,
	}
	-- (the welcome back gift is decided once, when the save loads)
	profile.Away = 0
	cleaned[d] = true
	profile.Rewards = d
	return d
end

local function rollDay(d: Data)
	local t = today()
	if d.PlayDate ~= t then
		d.PlayDate = t
		d.PlaySecs = 0
		d.PlayGot = {}
	end
end

-- the level rewards waiting: { level, cash, chest } for each level reached since the last claim
local function pendingLevels(profile: any, d: Data): ({ { [string]: number } }, number)
	local list, total = {}, 0
	local level = profile.Level or 1
	for l = d.LevelPaid + 1, level do
		local cash = R.LevelCash * l
		local chest = if l % R.ChestEvery == 0 then R.ChestCash * l else 0
		table.insert(list, { level = l, cash = cash, chest = chest })
		total += cash + chest
	end
	return list, total
end

local function wheelOdds(w: any): { { [string]: any } }
	local total = 0
	for _, p in w.prizes do
		total += p.weight
	end
	local out = {}
	for _, p in w.prizes do
		table.insert(out, { cash = p.cash, car = p.car == true, spin = p.spin == true, flex = p.flex == true, carCash = p.carCash, flexCash = p.flexCash, percent = math.floor(p.weight / total * 1000 + 0.5) / 10 })
	end
	return out
end

-- everything the rewards screen shows, and how many things are ready to take
local function state(player: Player): { [string]: any }?
	local profile = PlayerData.get(player) :: any
	if not (profile and profile.Loaded) then
		return nil
	end
	local d = data(profile)
	rollDay(d)
	local s = session[player]
	local now = os.time()
	local ready = 0
	local st: { [string]: any } = {}
	-- the daily streak
	local goals = deps.Goals and deps.Goals.state(player)
	if goals then
		st.daily = goals.streak
		if (goals.streak.readyIn or 0) <= 0 then
			ready += 1
		end
		st.achievements = { path = goals.path, done = goals.done, total = goals.total }
	end
	-- gifts: playtime, weekly, welcome back
	local play = {}
	local nextIn: number? = nil
	for i, g in R.Playtime do
		local got = d.PlayGot[tostring(i)] == true
		local left = g.minutes * 60 - d.PlaySecs
		table.insert(play, { minutes = g.minutes, cash = g.cash, got = got, readyIn = math.max(0, left) })
		if not got and left <= 0 then
			ready += 1
		elseif not got and left > 0 and not nextIn then
			nextIn = left
		end
	end
	local weekIn = math.max(0, d.WeekLast + R.WeeklyEvery - now)
	if weekIn <= 0 then
		ready += 1
	end
	if d.ReturnReady then
		ready += 1
	end
	st.gifts = { playSecs = d.PlaySecs, play = play, nextPlayIn = nextIn, weekly = R.Weekly, weeklyIn = weekIn, returnReady = d.ReturnReady, returnCash = R.Return }
	-- levels
	local levels, levelTotal = pendingLevels(profile, d)
	if #levels > 0 then
		ready += 1
	end
	st.levels = { list = levels, total = levelTotal, level = profile.Level or 1, cash = R.LevelCash, chest = R.ChestCash, every = R.ChestEvery }
	-- friends, invites, the group
	local friendReady = s ~= nil and s.friend and d.FriendDate ~= today()
	local inviteCount = (if s and s.invitee and not d.InviteGot then 1 else 0) + (if s then #s.inviter else 0)
	local groupShown = R.GroupId > 0
	local groupReady = groupShown and s ~= nil and s.group == true and not d.Group
	if friendReady then
		ready += 1
	end
	if inviteCount > 0 then
		ready += 1
	end
	if groupReady then
		ready += 1
	end
	st.friends = { friendReady = friendReady, friendTaken = d.FriendDate == today(), friendCash = R.FriendDaily, invites = inviteCount, inviteCash = R.Invite, group = groupShown, groupReady = groupReady, groupGot = d.Group, groupCash = R.Group }
	-- property
	local rent = if deps.Towers then deps.Towers.rentState(player) else {}
	for _, r in rent do
		if r.readyIn <= 0 then
			ready += 1
			break
		end
	end
	st.property = { rent = rent, suite = if deps.Hotel then deps.Hotel.incomeOf(player) else nil }
	-- the wheels
	local wheels = {}
	for id, w in R.Wheels do
		local freeIn = math.max(0, (d.FreeLast[id] or 0) + w.freeEvery - now)
		if freeIn <= 0 or (d.Spins[id] or 0) > 0 then
			ready += 1
		end
		wheels[id] = {
			name = w.name,
			freeIn = freeIn,
			spins = d.Spins[id] or 0,
			cashPrice = w.cashPrice,
			productId = if s and s.paidOk then w.productId else 0,
			canBuy = s ~= nil and s.paidOk,
			odds = wheelOdds(w),
		}
	end
	st.wheels = wheels
	st.ready = ready
	st.cash = profile.Cash
	return st
end

local function send(player: Player, info: { [string]: any })
	if push then
		push:FireClient(player, info)
	end
end

local function refresh(player: Player)
	local st = state(player)
	if st then
		send(player, { kind = "state", state = st })
	end
end

-- is the player standing at one of the desks?
local function atDesk(player: Player): boolean
	local char = player.Character
	if not char then
		return false
	end
	local p = char:GetPivot().Position
	for _, part in deskParts do
		if (part.Position - p).Magnitude <= R.DeskRange then
			return true
		end
	end
	return false
end

-- marks the claim, saves, then pays (nothing is paid if the save didn't go through)
local function settle(player: Player, mark: () -> (), undo: () -> (), pay: () -> ()): boolean
	mark()
	if not PlayerData.save(player) then
		undo()
		return false
	end
	pay()
	return true
end

---------------------------------------------------------------------
-- The claims
---------------------------------------------------------------------
local function pickCar(profile: any, maxPrice: number, tiers: { string }?): string?
	local pick = {}
	for _, spec in Cars.List do
		if table.find(tiers or { "Mid" }, spec.Tier) and spec.Price <= maxPrice and not profile.Owned[spec.Id] then
			table.insert(pick, spec.Id)
		end
	end
	return if #pick > 0 then pick[math.random(1, #pick)] else nil
end

local handlers: { [string]: (Player, any, Data, any) -> { [string]: any } } = {}
local DESK_ONLY = { daily = true, play = true, weekly = true, welcome = true, levels = true, friend = true, invite = true, group = true, rent = true, spin = true, buy = true }

handlers.daily = function(player)
	local result = deps.Goals.claimStreak(player)
	return result
end

handlers.play = function(player, arg, d)
	rollDay(d)
	local i = if type(arg) == "number" then math.floor(arg) else 0
	local g = R.Playtime[i]
	if not g then
		return { ok = false }
	end
	local key = tostring(i)
	if d.PlayGot[key] then
		return { ok = false, message = "Already taken today" }
	end
	if d.PlaySecs < g.minutes * 60 then
		return { ok = false, message = "Keep playing: this gift opens at " .. g.minutes .. " minutes" }
	end
	local ok = settle(player, function()
		d.PlayGot[key] = true
	end, function()
		d.PlayGot[key] = nil
	end, function()
		PlayerData.addCash(player, g.cash)
	end)
	return if ok then { ok = true, amount = g.cash, what = g.minutes .. " MINUTE GIFT" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.weekly = function(player, _arg, d)
	local now = os.time()
	if d.WeekLast + R.WeeklyEvery > now then
		return { ok = false, message = "The weekly gift isn't ready yet" }
	end
	local before = d.WeekLast
	local ok = settle(player, function()
		d.WeekLast = now
	end, function()
		d.WeekLast = before
	end, function()
		PlayerData.addCash(player, R.Weekly)
	end)
	return if ok then { ok = true, amount = R.Weekly, what = "WEEKLY GIFT" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.welcome = function(player, _arg, d)
	if not d.ReturnReady then
		return { ok = false, message = "Nothing waiting" }
	end
	local ok = settle(player, function()
		d.ReturnReady = false
	end, function()
		d.ReturnReady = true
	end, function()
		PlayerData.addCash(player, R.Return)
	end)
	return if ok then { ok = true, amount = R.Return, what = "WELCOME BACK" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.levels = function(player, _arg, d, profile)
	local list, total = pendingLevels(profile, d)
	if #list == 0 then
		return { ok = false, message = "No level rewards waiting: level up to earn more" }
	end
	local before = d.LevelPaid
	local level = profile.Level or 1
	local chest = false
	for _, l in list do
		chest = chest or l.chest > 0
	end
	local ok = settle(player, function()
		d.LevelPaid = level
	end, function()
		d.LevelPaid = before
	end, function()
		PlayerData.addCash(player, total)
	end)
	return if ok then { ok = true, amount = total, what = if chest then "LEVEL CHEST" else "LEVEL REWARDS", big = chest } else { ok = false, message = "Couldn't save: try again" }
end

handlers.friend = function(player, _arg, d)
	local s = session[player]
	if not (s and s.friend) then
		return { ok = false, message = "Play in the same server as a friend to get this" }
	end
	local t = today()
	if d.FriendDate == t then
		return { ok = false, message = "Already taken today" }
	end
	local before = d.FriendDate
	local ok = settle(player, function()
		d.FriendDate = t
	end, function()
		d.FriendDate = before
	end, function()
		PlayerData.addCash(player, R.FriendDaily)
	end)
	return if ok then { ok = true, amount = R.FriendDaily, what = "FRIEND BONUS" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.invite = function(player, _arg, d)
	local s = session[player]
	if not s then
		return { ok = false }
	end
	local count = 0
	local took: { number } = {}
	local selfGift = s.invitee and not d.InviteGot
	if selfGift then
		count += 1
	end
	for _, uid in s.inviter do
		if not d.Invited[tostring(uid)] then
			table.insert(took, uid)
			count += 1
		end
	end
	if count == 0 then
		return { ok = false, message = "Invite a friend: when they join for the first time, you both get a gift" }
	end
	local amount = R.Invite * count
	local ok = settle(player, function()
		if selfGift then
			d.InviteGot = true
		end
		for _, uid in took do
			d.Invited[tostring(uid)] = true
		end
	end, function()
		if selfGift then
			d.InviteGot = false
		end
		for _, uid in took do
			d.Invited[tostring(uid)] = nil
		end
	end, function()
		PlayerData.addCash(player, amount)
	end)
	if ok then
		s.inviter = {}
		s.invitee = false
	end
	return if ok then { ok = true, amount = amount, what = "INVITE GIFT" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.group = function(player, _arg, d)
	local s = session[player]
	if R.GroupId <= 0 then
		return { ok = false }
	end
	if d.Group then
		return { ok = false, message = "Already taken" }
	end
	if not (s and s.group) then
		-- (check again: they may have joined since)
		local okCall, inGroup = pcall(function()
			return player:IsInGroupAsync(R.GroupId)
		end)
		if s then
			s.group = okCall and inGroup == true
		end
		if not (okCall and inGroup) then
			return { ok = false, message = "Join the game's group on Roblox to get this" }
		end
	end
	local ok = settle(player, function()
		d.Group = true
	end, function()
		d.Group = false
	end, function()
		PlayerData.addCash(player, R.Group)
	end)
	return if ok then { ok = true, amount = R.Group, what = "GROUP GIFT" } else { ok = false, message = "Couldn't save: try again" }
end

handlers.code = function(player, arg, d)
	if type(arg) ~= "string" or #arg > 40 then
		return { ok = false, message = "Type a code" }
	end
	local code = string.upper((string.gsub(arg, "%s", "")))
	if not string.match(code, "^%w+$") or #code < 4 or #code > 20 then
		return { ok = false, message = "That code doesn't work" }
	end
	local spec = nil
	for _, c in R.Codes do
		if c.code == code and c.on and today() <= c.ends then
			spec = c
		end
	end
	if not spec then
		return { ok = false, message = "That code doesn't work" }
	end
	if d.Codes[code] then
		return { ok = false, message = "You've used this code" }
	end
	local ok = settle(player, function()
		d.Codes[code] = true
	end, function()
		d.Codes[code] = nil
	end, function()
		PlayerData.addCash(player, spec.cash)
	end)
	return if ok then { ok = true, amount = spec.cash, what = "CODE " .. code } else { ok = false, message = "Couldn't save: try again" }
end

handlers.rent = function(player)
	local total = 0
	for _, r in deps.Towers.rentState(player) do
		if r.readyIn <= 0 then
			deps.Towers.collectRent(player, r.id) -- (it checks, saves and pays on its own)
			total += r.rent
		end
	end
	if total == 0 then
		return { ok = false, message = "No safe is ready yet" }
	end
	return { ok = true, amount = total, what = "RENT COLLECTED", quiet = true }
end

-- a spin: each reel lands on a prize, by weight (the WHEEL has 1 reel, the SUPER WHEEL 3: three
-- prizes). At most one car a spin (a second car on the same spin pays its carCash instead)
handlers.spin = function(player, arg, d, profile)
	local w = if type(arg) == "string" then R.Wheels[arg] else nil
	if not w then
		return { ok = false }
	end
	local id = arg :: string
	local now = os.time()
	local free = (d.FreeLast[id] or 0) + w.freeEvery <= now
	if not free and (d.Spins[id] or 0) <= 0 then
		return { ok = false, message = "No spins left: buy one, or wait for the free spin" }
	end
	local total = 0
	for _, p in w.prizes do
		total += p.weight
	end
	local reels = {}
	local amount = 0
	local carId: string? = nil
	local flexIds: { string } = {}
	local extraSpins = 0
	local big = false
	for _ = 1, (w.reels or 1) do
		local roll = math.random() * total
		local index = #w.prizes
		for i, p in w.prizes do
			roll -= p.weight
			if roll <= 0 then
				index = i
				break
			end
		end
		local prize = w.prizes[index]
		big = big or prize.weight <= 2
		local reel: { [string]: any } = { index = index }
		if prize.car then
			local pick = if carId then nil else pickCar(profile, prize.carMax or 120000, prize.carTiers)
			if pick then
				carId = pick
				reel.car = Cars.ById[pick].Name
			else
				reel.cash = prize.carCash
				amount += prize.carCash
			end
		elseif prize.flex then
			local pick = if deps.Luxe then deps.Luxe.pickItem(player, prize.flexMax or 100000) else nil
			if pick and not table.find(flexIds, pick) then
				table.insert(flexIds, pick)
				reel.flex = deps.Luxe.itemName(pick)
			else
				reel.cash = prize.flexCash
				amount += prize.flexCash
			end
		elseif prize.spin then
			extraSpins += 1
			reel.spin = true
		else
			reel.cash = prize.cash
			amount += prize.cash
		end
		table.insert(reels, reel)
	end
	local beforeFree, beforeSpins = d.FreeLast[id], d.Spins[id]
	local won = carId
	local ok = settle(player, function()
		if free then
			d.FreeLast[id] = now
		else
			d.Spins[id] = (d.Spins[id] or 0) - 1
		end
		d.Spins[id] = (d.Spins[id] or 0) + extraSpins
		if won then
			profile.Owned[won] = true
		end
		for _, f in flexIds do
			deps.Luxe.give(player, f, true)
		end
	end, function()
		d.FreeLast[id], d.Spins[id] = beforeFree, beforeSpins
		if won then
			profile.Owned[won] = nil
		end
		for _, f in flexIds do
			deps.Luxe.give(player, f, false)
		end
	end, function()
		if amount > 0 then
			PlayerData.addCash(player, amount)
		end
	end)
	if not ok then
		return { ok = false, message = "Couldn't save: try again" }
	end
	return { ok = true, wheel = id, reels = reels, amount = amount, car = if won then Cars.ById[won].Name else nil, what = w.name, quiet = true, big = big }
end

handlers.buy = function(player, arg, d, profile)
	local w = if type(arg) == "string" then R.Wheels[arg] else nil
	local s = session[player]
	if not (w and s) then
		return { ok = false }
	end
	if not s.paidOk then
		return { ok = false, message = "Buying spins isn't available for you" }
	end
	if profile.Cash < w.cashPrice then
		return { ok = false, message = "Not enough cash" }
	end
	local id = arg :: string
	local before = d.Spins[id]
	local ok = settle(player, function()
		d.Spins[id] = (d.Spins[id] or 0) + 1
		PlayerData.addCash(player, -w.cashPrice)
	end, function()
		d.Spins[id] = before
		PlayerData.addCash(player, w.cashPrice)
	end, function() end)
	return if ok then { ok = true, amount = -w.cashPrice, what = "1 " .. w.name .. " SPIN", quiet = true } else { ok = false, message = "Couldn't save: try again" }
end

handlers.state = function(player)
	return { ok = true, state = state(player) }
end

local function call(player: Player, what: any, arg: any): { [string]: any }
	local h = if type(what) == "string" then handlers[what] else nil
	local s = session[player]
	local profile = PlayerData.get(player) :: any
	if not (h and s and profile and profile.Loaded) then
		return { ok = false, message = "Your data is still loading" }
	end
	if what == "state" then
		return h(player, arg, data(profile), profile)
	end
	local now = os.clock()
	if now - s.last < 0.35 then
		return { ok = false, message = "One moment..." }
	end
	s.last = now
	if s.busy then
		return { ok = false, message = "One moment..." }
	end
	if DESK_ONLY[what] and not atDesk(player) then
		return { ok = false, message = "Claim this at a desk in Legends Rewards", far = true }
	end
	s.busy = true
	local ok, result = pcall(h, player, arg, data(profile), profile)
	s.busy = false
	if not ok then
		warn("[CityLegends] rewards claim failed:", what, result)
		return { ok = false, message = "Something went wrong: try again" }
	end
	result.state = state(player)
	return result
end

---------------------------------------------------------------------
-- Robux spins (developer products; Config.Rewards.Wheels[...].productId)
---------------------------------------------------------------------
local function wheelForProduct(productId: number): string?
	for id, w in R.Wheels do
		if w.productId ~= 0 and w.productId == productId then
			return id
		end
	end
	return nil
end

local function processReceipt(info: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local id = wheelForProduct(info.ProductId)
	local profile = player and PlayerData.get(player) :: any
	if not (player and id and profile and profile.Loaded) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local d = data(profile)
	local pid = tostring(info.PurchaseId)
	if table.find(d.Receipts, pid) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	d.Spins[id] = (d.Spins[id] or 0) + 1
	table.insert(d.Receipts, pid)
	while #d.Receipts > 50 do
		table.remove(d.Receipts, 1)
	end
	if not PlayerData.save(player) then
		d.Spins[id] -= 1
		table.remove(d.Receipts, table.find(d.Receipts, pid) or #d.Receipts)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	send(player, { kind = "bought", what = "1 " .. R.Wheels[id].name .. " SPIN" })
	refresh(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
local function onReady(player: Player)
	local profile = PlayerData.get(player) :: any
	if not profile then
		return
	end
	local s = { friend = false, inviter = {}, invitee = false, group = nil, paidOk = false, busy = false, last = 0 }
	session[player] = s
	local d = data(profile)
	-- paid random items (the wheels' bought spins) only where Roblox allows them
	local okPolicy, policy = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	s.paidOk = okPolicy and type(policy) == "table" and policy.ArePaidRandomItemsRestricted == false
	if R.GroupId > 0 then
		local okGroup, inGroup = pcall(function()
			return player:IsInGroupAsync(R.GroupId)
		end)
		s.group = okGroup and inGroup == true
	end
	-- friends here (both get the daily friend bonus)
	for _, other in Players:GetPlayers() do
		if other ~= player and session[other] then
			local okF, isFriend = pcall(function()
				return player:IsFriendsWithAsync(other.UserId)
			end)
			if okF and isFriend then
				s.friend = true
				session[other].friend = true
				refresh(other)
			end
		end
	end
	-- joined for the first time from a friend's invite: a gift for both
	local okJoin, join = pcall(function()
		return player:GetJoinData()
	end)
	local ref = if okJoin and type(join) == "table" then join.ReferredByPlayerId else nil
	if profile.IsNew and type(ref) == "number" and ref > 0 and ref ~= player.UserId then
		s.invitee = not d.InviteGot
		local inviter = Players:GetPlayerByUserId(ref)
		local is = inviter and session[inviter]
		local ip = inviter and PlayerData.get(inviter) :: any
		if is and ip and not data(ip).Invited[tostring(player.UserId)] then
			table.insert(is.inviter, player.UserId)
			refresh(inviter :: Player)
		end
	end
	if player.Parent then
		refresh(player)
	end
end

function Rewards.init(ctx: any, d: any)
	deps = d or {}
	local fn: RemoteFunction = ctx.remote("RemoteFunction", "RewardsCall")
	push = ctx.remote("RemoteEvent", "RewardsPush")
	fn.OnServerInvoke = call
	MarketplaceService.ProcessReceipt = processReceipt
	local function watch(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 60
			while player.Parent and os.clock() < deadline do
				local profile = PlayerData.get(player) :: any
				if profile and profile.Loaded then
					onReady(player)
					return
				end
				task.wait(0.5)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		session[player] = nil
	end)
	-- playtime: counted on the server every few seconds; a gift opening sends the new state
	local STEP = 5
	task.spawn(function()
		while true do
			task.wait(STEP)
			for player in session do
				local profile = PlayerData.get(player) :: any
				if profile and profile.Loaded and player.Parent then
					local dd = data(profile)
					rollDay(dd)
					local before = dd.PlaySecs
					dd.PlaySecs = math.min(86400, dd.PlaySecs + STEP)
					for _, g in R.Playtime do
						if before < g.minutes * 60 and dd.PlaySecs >= g.minutes * 60 then
							send(player, { kind = "gift", minutes = g.minutes })
							refresh(player)
						end
					end
				end
			end
		end
	end)
	-- a fresh state now and then (levels gained, rent coming due, the daily streak)
	task.spawn(function()
		while true do
			task.wait(30)
			for player in session do
				if player.Parent then
					refresh(player)
				end
			end
		end
	end)
end

-- (for the rest of the game: a level gained or a property change may open something)
function Rewards.refresh(player: Player)
	refresh(player)
end

return Rewards
