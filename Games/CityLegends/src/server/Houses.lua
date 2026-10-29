--[[
	Houses
	Miami-style houses on the private islands (owner, 2026-10-22: "add houses which u can buy and
	show case your car garage"). Every plot in WestLayout.housePlots of a house type's tier gets one:
	villas on Legends Isle's mid terrace, mansions in the gated community on top.

	Each house: white walls, long glass, a cantilevered upper floor with warm cove lights, a roof
	terrace, a pool with a lit deck behind, palms, a walled front with an open sliding gate and a lit
	driveway. The ground floor is a glass car gallery facing the road: one lit bay per car.

	Owning: you buy a house type (Config.Houses.Types). In each server you get a free plot of that
	type, the one you had last time if it's free; it shows your name and your cars. An unclaimed
	plot shows FOR SALE: buy it there (or move your house there if you already own that type).
	Owner-only prompts in the gallery: "Garage setup" (pick the car in each bay, HouseClient's
	panel) and "Drive" on each bay car (the car spawns on the driveway, nose to the gate).

	CityBuilder calls Houses.buildWorld (the buildings); Main calls Houses.init(ctx) (players,
	remotes, the cars in the bays).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Customs = require(script.Parent:WaitForChild("Customs"))

local Houses = {}

local H = Config.Houses
local BAY = 12 -- bay width
local DOOR = 6 -- the walk-in door at the gallery's end

-- palette
local WHITE = Color3.fromRGB(236, 234, 228)
local STONE = Color3.fromRGB(196, 186, 168)
local TEAK = Color3.fromRGB(122, 84, 54)
local DARK = Color3.fromRGB(26, 28, 32)
local GLASS = Color3.fromRGB(96, 124, 146)
local GLOW = Color3.fromRGB(255, 208, 150)
local LED = Color3.fromRGB(255, 220, 170)
local LAWN = Color3.fromRGB(34, 62, 34)
local PAVING = Color3.fromRGB(176, 168, 156)
local POOL = Color3.fromRGB(30, 170, 220)
local TRUNK = Color3.fromRGB(110, 86, 62)
local FROND = Color3.fromRGB(46, 96, 46)

type Design = {
	W: number,
	D: number,
	galX0: number, -- the gallery's left end (bays from here, the door after them)
	galZ0: number, -- the gallery's front (glass, towards the road)
	galDepth: number,
	galH: number,
	wing: { number }, -- x0, x1, z0, z1, h (the ground floor beside the gallery)
	floor2: { number }, -- x0, x1, z0, z1, y1 (from galH up)
	floor3: { number }, -- x0, x1, z0, z1, h
	pool: { number }, -- x0, x1, z0, z1
}

local DESIGNS: { [string]: Design } = {
	villa = {
		W = 96, D = 70, galX0 = -46, galZ0 = -12, galDepth = 24, galH = 11,
		wing = { 9, 46, -9, 20, 11 },
		floor2 = { -47, 47, -15, 21, 21 },
		floor3 = { -8, 40, -8, 18, 9 },
		pool = { -30, 16, 24, 32 },
	},
	mansion = {
		W = 110, D = 95, galX0 = -54, galZ0 = -20, galDepth = 26, galH = 12,
		wing = { 25, 54, -16, 22, 24 },
		floor2 = { -55, 24, -25, 22, 24 },
		floor3 = { -36, 30, -12, 18, 11 },
		pool = { -42, 18, 27, 39 },
	},
}

type Rec = {
	plot: WestLayout.Plot,
	kind: string,
	design: Design,
	model: Model,
	frame: CFrame,
	bays: { CFrame }, -- each bay's floor point, facing the road
	bayCars: { Model? },
	bayIds: { string },
	signTitle: TextLabel,
	signSub: TextLabel,
	driveway: CFrame,
	owner: Player?,
}

local recs: { [string]: Rec } = {}
local order: { Rec } = {}
local claims: { [Player]: { [string]: string } } = {} -- player -> house type -> plot id
local ctx: any = nil
local fx: RemoteEvent? = nil

local function kindOf(plot: WestLayout.Plot): string
	return if plot.tier >= 2 then "mansion" else "villa"
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "$" .. out
end

local function send(player: Player, info: { [string]: any })
	if fx then
		fx:FireClient(player, info)
	end
end

---------------------------------------------------------------------
-- Building
---------------------------------------------------------------------
local function prompt(parent: Instance, action: string, object: string, hold: number?, dist: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = dist or 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

-- a palm: a gently curving trunk and drooping fronds
local function palm(kit: any, parent: Instance, base: Vector3, h: number, rng: Random)
	local lean = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
	lean = if lean.Magnitude > 0.01 then lean.Unit else Vector3.xAxis
	local prev = base
	local segs = 5
	for k = 1, segs do
		local t = k / segs
		local p = base + Vector3.new(0, h * t, 0) + lean * (t * t * h * 0.16)
		local d = 1.5 - 0.5 * t
		kit.deco(parent, Vector3.new(d, d, (p - prev).Magnitude + 0.25), CFrame.lookAt((prev + p) / 2, p), TRUNK, Enum.Material.Wood, { shadow = true })
		prev = p
	end
	kit.deco(parent, Vector3.one * 1.6, CFrame.new(prev), TRUNK:Lerp(FROND, 0.4), Enum.Material.Wood, { shape = Enum.PartType.Ball })
	local a0 = rng:NextNumber(0, math.pi * 2)
	for f = 0, 8 do
		local a = a0 + f / 9 * math.pi * 2
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p1 = prev + dir * 3.4 + Vector3.new(0, 0.9, 0)
		local p2 = p1 + dir * 3.8 + Vector3.new(0, -1.9, 0)
		local p3 = p2 + dir * 2.2 + Vector3.new(0, -1.8, 0)
		for _, seg in { { prev, p1, 2.4 }, { p1, p2, 2.1 }, { p2, p3, 1.2 } } do
			local a1, b1 = seg[1], seg[2]
			kit.deco(parent, Vector3.new(seg[3], 0.15, (b1 - a1).Magnitude + 0.3), CFrame.lookAt((a1 + b1) / 2, b1), FROND:Lerp(Color3.fromRGB(70, 120, 60), rng:NextNumber()), Enum.Material.Grass, { shadow = true })
		end
	end
end

local function buildHouse(kit: any, parent: Instance, plot: WestLayout.Plot)
	local kind = kindOf(plot)
	local d = DESIGNS[kind]
	local spec = H.Types[kind]
	local rng = Random.new(#order * 7919 + 17)
	local frame = plot.frame
	local hw, hd = d.W / 2, d.D / 2
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z) -- -z towards the road
	end

	local model = Instance.new("Model")
	model.Name = "House_" .. plot.id
	model:SetAttribute("Plot", plot.id)
	model:SetAttribute("Kind", kind)
	model:SetAttribute("Price", spec.price)
	model.Parent = parent

	local function box(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return kit.mk(par, Vector3.new(sx, sy, sz), at(x, y, z), color, mat, o)
	end
	local function dbox(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return kit.deco(par, Vector3.new(sx, sy, sz), at(x, y, z), color, mat, o)
	end
	-- an axis-aligned box from corner to corner (in the plot's frame)
	local function span(par: Instance, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return box(par, math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0), (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2, color, mat, o)
	end
	local function dspan(par: Instance, x0: number, x1: number, y0: number, y1: number, z0: number, z1: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return dbox(par, math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0), (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2, color, mat, o)
	end

	local center = frame.Position
	local detail = kit.lodGroup(model, "Detail", center, 650)
	local inside = kit.lodGroup(model, "Inside", center, 300)

	-- a glass ribbon on a face: a warm lit interior behind tinted glass and dark mullions.
	-- face: z of the face plane, out: +1 / -1 which way the face looks (along z)
	local function ribbonZ(x0: number, x1: number, y0: number, y1: number, z: number, out: number, lit: boolean)
		local w = x1 - x0
		if lit then
			dspan(detail, x0, x1, y0, y1, z + out * 0.15, z + out * 0.25, GLOW, Enum.Material.Neon, { transparency = 0.18 })
		else
			dspan(detail, x0, x1, y0, y1, z + out * 0.15, z + out * 0.25, Color3.fromRGB(20, 24, 30), Enum.Material.SmoothPlastic)
		end
		dspan(model, x0, x1, y0, y1, z + out * 0.35, z + out * 0.5, GLASS, Enum.Material.Glass, { transparency = 0.55, reflectance = 0.25 })
		local n = math.max(1, math.floor(w / 6))
		for k = 0, n do
			local x = x0 + w * k / n
			dbox(detail, 0.35, y1 - y0, 0.3, x, (y0 + y1) / 2, z + out * 0.6, DARK, Enum.Material.Metal)
		end
	end

	------------------------------------------------------------ the lot
	span(model, -hw, hw, -0.2, 0.3, -hd, hd, LAWN, Enum.Material.Grass, { name = "Lawn" })
	local bays = spec.bays
	local gx0, gx1 = d.galX0, d.galX0 + bays * BAY
	local gEnd = gx1 + DOOR
	local gz0, gz1 = d.galZ0, d.galZ0 + d.galDepth
	-- the driveway: pale paving from the gate to the gallery, lit bollards along it
	span(model, gx0, gx1, 0.3, 0.45, -hd, gz0, PAVING, Enum.Material.Pavement, { name = "Driveway" })
	dspan(model, gx1, gEnd, 0.3, 0.46, -hd, gz0, STONE, Enum.Material.Limestone) -- the footpath to the door
	for k = 0, 2 do
		local z = -hd + 4 + k * ((gz0 + hd - 6) / 2)
		for _, x in { gx0 + 1, gx1 - 1 } do
			dbox(detail, 0.7, 2.2, 0.7, x, 1.4, z, DARK, Enum.Material.Metal)
			local cap = dbox(detail, 0.5, 0.25, 0.5, x, 2.6, z, LED, Enum.Material.Neon)
			if k == 1 then
				kit.addLight("PointLight", cap, LED, 12, 0.8)
			end
		end
	end

	------------------------------------------------------------ front wall, gate and sign
	local gateC = (gx0 + gx1) / 2
	local gate0, gate1 = gateC - 9, gateC + 9
	local function wall(x0: number, x1: number)
		if x1 - x0 > 0.5 then
			span(model, x0, x1, 0.3, 3.8, -hd, -hd + 1.2, WHITE, Enum.Material.Plaster, { name = "Wall" })
			dspan(detail, x0, x1, 3.8, 4.1, -hd - 0.1, -hd + 1.3, STONE, Enum.Material.Limestone)
		end
	end
	wall(-hw, gate0 - 1.5)
	wall(gate1 + 1.5, hw)
	-- side walls (half height, so the lots read as separate)
	for _, x in { -hw, hw } do
		span(model, x - 0.6, x + 0.6, 0.3, 3.2, -hd, hd - 14, WHITE, Enum.Material.Plaster)
	end
	-- gate pillars with lanterns
	for _, x in { gate0 - 0.75, gate1 + 0.75 } do
		span(model, x - 1.5, x + 1.5, 0.3, 6.5, -hd - 0.4, -hd + 1.6, WHITE, Enum.Material.Plaster)
		dspan(detail, x - 1.7, x + 1.7, 6.5, 6.9, -hd - 0.6, -hd + 1.8, STONE, Enum.Material.Limestone)
		local lamp = dbox(detail, 1.1, 1.4, 1.1, x, 7.6, -hd + 0.6, LED, Enum.Material.Neon, { transparency = 0.1 })
		kit.addLight("PointLight", lamp, LED, 18, 1.1)
	end
	-- the sliding gate, parked open behind the wall beside the opening
	local slide = dspan(detail, gate1 + 2, gate1 + 19, 0.6, 4.6, -hd + 1.4, -hd + 1.8, DARK, Enum.Material.Metal)
	for k = 0, 8 do
		dbox(detail, 0.25, 3.6, 0.5, gate1 + 3 + k * 2, 2.6, -hd + 1.6, Color3.fromRGB(150, 128, 80), Enum.Material.Metal)
	end
	slide.Name = "Gate"
	-- the sign on the wall beside the gate: FOR SALE / the owner's name
	local signX = gate1 + 28
	local sign = box(model, 14, 4.2, 0.4, signX, 2.4, -hd - 0.2, Color3.fromRGB(14, 14, 18), Enum.Material.SmoothPlastic, { name = "Sign" })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = Vector2.new(560, 168)
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.MaxDistance = 260
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(0.92, 0, 0.5, 0)
	title.Position = UDim2.fromScale(0.04, 0.08)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 214, 140)
	title.Text = "FOR SALE"
	title.Parent = gui
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.new(0.92, 0, 0.3, 0)
	sub.Position = UDim2.fromScale(0.04, 0.6)
	sub.Font = Enum.Font.GothamMedium
	sub.TextScaled = true
	sub.TextColor3 = Color3.new(1, 1, 1)
	sub.Text = string.upper(spec.name) .. "  ·  " .. money(spec.price)
	sub.Parent = gui
	local signEdge = dbox(detail, 14.4, 0.25, 0.5, signX, 0.35, -hd - 0.2, LED, Enum.Material.Neon)
	signEdge.Name = "SignGlow"
	local buy = prompt(sign, "Buy", spec.name .. "  " .. money(spec.price), 1.5, 12)
	buy:SetAttribute("Plot", plot.id)
	CollectionService:AddTag(buy, "HouseBuy")
	buy.Triggered:Connect(function(player: Player)
		Houses.buy(player, plot.id)
	end)

	------------------------------------------------------------ the gallery (ground floor)
	local gh = d.galH
	-- floor: dark polished stone
	span(model, gx0, gEnd, 0.3, 0.6, gz0, gz1, Color3.fromRGB(34, 34, 38), Enum.Material.Marble, { reflectance = 0.12, name = "GalleryFloor" })
	-- back and end walls (white inside)
	span(model, gx0 - 1, gEnd + 1, 0.6, gh, gz1, gz1 + 1, WHITE, Enum.Material.Plaster)
	span(model, gx0 - 1, gx0, 0.6, gh, gz0, gz1, WHITE, Enum.Material.Plaster)
	span(model, gEnd, gEnd + 1, 0.6, gh, gz0, gz1, WHITE, Enum.Material.Plaster)
	-- front: a glass pane per bay between slim dark columns, then the door
	for k = 0, bays do
		local x = gx0 + k * BAY
		span(model, x - 0.4, x + 0.4, 0.6, gh, gz0 - 0.4, gz0 + 0.4, DARK, Enum.Material.Metal)
	end
	span(model, gEnd - 0.4, gEnd + 0.4, 0.6, gh, gz0 - 0.4, gz0 + 0.4, DARK, Enum.Material.Metal)
	for k = 1, bays do
		local x0 = gx0 + (k - 1) * BAY + 0.4
		span(model, x0, x0 + BAY - 0.8, 0.6, gh, gz0 - 0.15, gz0 + 0.15, Color3.fromRGB(170, 196, 214), Enum.Material.Glass, { transparency = 0.72, reflectance = 0.18, name = "GalleryGlass" })
	end
	-- the walk-in door: glass above the opening, a frame
	dspan(model, gx1 + 0.4, gEnd - 0.4, 8.6, gh, gz0 - 0.15, gz0 + 0.15, Color3.fromRGB(170, 196, 214), Enum.Material.Glass, { transparency = 0.7 })
	dspan(detail, gx1 + 0.4, gEnd - 0.4, 8.4, 8.6, gz0 - 0.3, gz0 + 0.3, DARK, Enum.Material.Metal)
	-- inside: bay lights, bay numbers, an LED line along the back wall, the setup console
	local bayCFs: { CFrame } = {}
	for k = 1, bays do
		local x = gx0 + (k - 0.5) * BAY
		local zc = (gz0 + gz1) / 2
		bayCFs[k] = CFrame.lookAt(at(x, 0.6, zc).Position, at(x, 0.6, zc).Position + frame.LookVector)
		local spot = dbox(inside, 3, 0.3, 3, x, gh - 0.2, zc, LED, Enum.Material.Neon)
		kit.addLight("SpotLight", spot, Color3.fromRGB(255, 236, 214), 18, 2.4, Enum.NormalId.Bottom, 100)
		-- floor outline of the bay
		for _, sx in { -1, 1 } do
			dbox(inside, 0.25, 0.05, d.galDepth - 3, x + sx * (BAY / 2 - 1), 0.63, zc, Color3.fromRGB(200, 200, 204), Enum.Material.SmoothPlastic)
		end
		local num = dbox(inside, 3, 3, 0.2, x, gh - 3.5, gz1 - 0.15, Color3.fromRGB(14, 14, 18), Enum.Material.SmoothPlastic)
		local ngui = Instance.new("SurfaceGui")
		ngui.Face = Enum.NormalId.Back
		ngui.CanvasSize = Vector2.new(100, 100)
		ngui.LightInfluence = 0
		ngui.Parent = num
		local nl = Instance.new("TextLabel")
		nl.BackgroundTransparency = 1
		nl.Size = UDim2.fromScale(1, 1)
		nl.Font = Enum.Font.GothamBlack
		nl.TextScaled = true
		nl.TextColor3 = Color3.fromRGB(255, 214, 140)
		nl.Text = string.format("%02d", k)
		nl.Parent = ngui
	end
	dspan(inside, gx0, gEnd, 1.4, 1.6, gz1 - 0.3, gz1 - 0.1, LED, Enum.Material.Neon)
	dspan(inside, gx0, gEnd, gh - 0.6, gh - 0.4, gz1 - 0.3, gz1 - 0.1, LED, Enum.Material.Neon)
	-- the console: a slim stand with a lit screen by the door
	local cx = (gx1 + gEnd) / 2
	box(inside, 2.4, 3.8, 1.2, cx, 2.5, gz1 - 3, DARK, Enum.Material.Metal)
	local screen = dbox(inside, 2.2, 1.4, 0.15, cx, 4.2, gz1 - 3.62, Color3.fromRGB(0, 200, 255), Enum.Material.Neon, { transparency = 0.15 })
	local setup = prompt(screen, "Garage setup", spec.name, 0, 9)
	setup:SetAttribute("Plot", plot.id)
	CollectionService:AddTag(setup, "HouseOwner")
	setup.Triggered:Connect(function(player: Player)
		local rec = recs[plot.id]
		if rec and rec.owner == player then
			send(player, { kind = "garage", plot = plot.id })
		end
	end)
	-- a leather bench facing the cars
	dspan(inside, cx - 2, cx + 2, 0.6, 2.2, gz1 - 9, gz1 - 6, Color3.fromRGB(70, 46, 34), Enum.Material.Leather)

	------------------------------------------------------------ the ground-floor wing
	local wg = d.wing
	span(model, wg[1], wg[2], 0.3, wg[5], wg[4] - 1, wg[4], WHITE, Enum.Material.Plaster)
	span(model, wg[1], wg[2], 0.3, wg[5], wg[3], wg[3] + 0.6, WHITE, Enum.Material.Plaster, { transparency = 1 }) -- (keeps you out; the glass shows)
	span(model, wg[2] - 1, wg[2], 0.3, wg[5], wg[3], wg[4], WHITE, Enum.Material.Plaster)
	ribbonZ(wg[1] + 1, wg[2] - 1, 1, wg[5] - 1, wg[3], -1, true)
	if wg[5] > gh + 1 then
		-- a tall wing (the mansion's double-height hall) has its own roof
		span(model, wg[1] - 0.5, wg[2] + 0.5, wg[5], wg[5] + 1, wg[3] - 0.5, wg[4] + 0.5, WHITE, Enum.Material.Plaster)
		dspan(detail, wg[1] - 0.5, wg[2] + 0.5, wg[5] - 0.15, wg[5], wg[3] - 0.4, wg[3], LED, Enum.Material.Neon)
	end
	-- interior hints behind the glass: a sofa and a lamp
	dspan(inside, wg[1] + 4, wg[1] + 16, 0.6, 2.6, wg[3] + 5, wg[3] + 8, Color3.fromRGB(220, 214, 200), Enum.Material.Fabric)
	local lamp = dbox(inside, 1.2, 1.2, 1.2, wg[1] + 20, 5, wg[3] + 6, LED, Enum.Material.Neon, { shape = Enum.PartType.Ball })
	kit.addLight("PointLight", lamp, GLOW, 16, 0.9)

	------------------------------------------------------------ the upper floors
	local f2 = d.floor2
	-- the slab between the floors (the gallery's ceiling), cantilevered out over the front
	span(model, f2[1], f2[2], gh, gh + 1, f2[3], f2[4], WHITE, Enum.Material.Plaster, { name = "Floor2" })
	span(model, f2[1], f2[2], gh + 1, f2[5], f2[3] + 1.5, f2[4] - 1.5, WHITE, Enum.Material.Plaster)
	span(model, f2[1] - 0.5, f2[2] + 0.5, f2[5], f2[5] + 1, f2[3] - 0.5, f2[4] + 0.5, WHITE, Enum.Material.Plaster, { name = "Roof2" })
	ribbonZ(f2[1] + 2, f2[2] - 2, gh + 2, f2[5] - 1, f2[3] + 1.5, -1, rng:NextNumber() < 0.85)
	ribbonZ(f2[1] + 2, f2[2] - 2, gh + 2, f2[5] - 1, f2[4] - 1.5, 1, true)
	-- warm cove light under the cantilever and along the roof edge
	dspan(detail, f2[1], f2[2], gh - 0.15, gh, f2[3] + 0.2, f2[3] + 0.6, LED, Enum.Material.Neon)
	dspan(detail, f2[1] - 0.5, f2[2] + 0.5, f2[5] + 1, f2[5] + 1.15, f2[3] - 0.3, f2[3] - 0.1, LED, Enum.Material.Neon, { transparency = 0.3 })
	-- a teak slat screen on part of the front (Miami modern)
	local slatX0 = f2[2] - 20
	for k = 0, 12 do
		dbox(detail, 0.4, f2[5] - gh - 1.5, 0.5, slatX0 + k * 1.5, (gh + 1 + f2[5]) / 2, f2[3] + 0.6, TEAK, Enum.Material.Wood)
	end
	-- top floor: a smaller white box with full-height glass, set back for a roof terrace
	local f3 = d.floor3
	local y3 = f2[5] + 1
	span(model, f3[1], f3[2], y3, y3 + f3[5], f3[3] + 1, f3[4] - 1, WHITE, Enum.Material.Plaster)
	span(model, f3[1] - 3, f3[2] + 3, y3 + f3[5], y3 + f3[5] + 0.8, f3[3] - 3, f3[4] + 2, WHITE, Enum.Material.Plaster, { name = "Roof3" })
	ribbonZ(f3[1] + 1, f3[2] - 1, y3 + 0.5, y3 + f3[5] - 0.5, f3[3] + 1, -1, true)
	ribbonZ(f3[1] + 1, f3[2] - 1, y3 + 0.5, y3 + f3[5] - 0.5, f3[4] - 1, 1, rng:NextNumber() < 0.7)
	dspan(detail, f3[1] - 3, f3[2] + 3, y3 + f3[5] - 0.15, y3 + f3[5], f3[3] - 2.8, f3[3] - 2.4, LED, Enum.Material.Neon)
	-- terrace: glass balustrade round the lower roof, loungers and a fire table
	for _, z in { f2[3] - 0.2, f2[4] + 0.2 } do
		dspan(model, f2[1] - 0.5, f2[2] + 0.5, f2[5] + 1, f2[5] + 4.2, z - 0.15, z + 0.15, Color3.fromRGB(190, 210, 224), Enum.Material.Glass, { transparency = 0.7 })
	end
	for _, x in { f2[1] - 0.2, f2[2] + 0.2 } do
		dspan(model, x - 0.15, x + 0.15, f2[5] + 1, f2[5] + 4.2, f2[3] - 0.5, f2[4] + 0.5, Color3.fromRGB(190, 210, 224), Enum.Material.Glass, { transparency = 0.7 })
	end
	local tx = (f2[1] + f3[1]) / 2
	for k = 0, 1 do
		dspan(detail, tx - 4 + k * 5, tx - 1 + k * 5, f2[5] + 1, f2[5] + 2, f2[3] + 3, f2[3] + 9, WHITE, Enum.Material.Fabric)
	end
	local fire = dspan(detail, tx - 2, tx + 2, f2[5] + 1, f2[5] + 2.4, f2[3] + 12, f2[3] + 15, DARK, Enum.Material.Slate)
	local flame = dbox(detail, 3, 0.5, 2, tx, f2[5] + 2.6, f2[3] + 13.5, Color3.fromRGB(255, 140, 40), Enum.Material.Neon, { transparency = 0.2 })
	kit.addLight("PointLight", flame, Color3.fromRGB(255, 150, 70), 14, 1)
	fire.Name = "FireTable"

	------------------------------------------------------------ the back: deck, pool, palms
	local pl = d.pool
	local deckZ0 = f2[4]
	span(model, -hw + 1, hw - 1, 0.3, 0.55, deckZ0, hd - 1, PAVING, Enum.Material.Limestone, { name = "Deck" })
	-- the pool: coping, a lit basin, the water
	span(model, pl[1] - 1.2, pl[2] + 1.2, 0.55, 0.9, pl[3] - 1.2, pl[4] + 1.2, WHITE, Enum.Material.Limestone)
	dspan(detail, pl[1], pl[2], 0.92, 0.95, pl[3], pl[4], Color3.fromRGB(0, 190, 255), Enum.Material.Neon, { transparency = 0.45 })
	local water = dspan(model, pl[1], pl[2], 0.95, 1.25, pl[3], pl[4], POOL, Enum.Material.Glass, { transparency = 0.3, reflectance = 0.2 })
	water.Name = "Pool"
	kit.addLight("PointLight", water, Color3.fromRGB(60, 200, 255), 22, 1.3)
	-- loungers beside the pool, facing it
	for k = 0, 3 do
		local x = pl[2] + 4 + k * 3.6
		local z = (pl[3] + pl[4]) / 2
		if x + 2 < hw - 2 then
			dspan(detail, x - 1.4, x + 1.4, 0.55, 1.6, z - 2.8, z + 2.8, WHITE, Enum.Material.Fabric)
			dbox(detail, 2.8, 1.2, 0.4, x, 2.1, z + 2.6, WHITE, Enum.Material.Fabric)
		end
	end
	-- uplights washing the white walls, and palms
	for k = 0, 3 do
		local x = -hw + 6 + k * (d.W - 12) / 3
		local up = dbox(detail, 0.8, 0.3, 0.8, x, 0.55, f2[3] - 1.4, LED, Enum.Material.Neon)
		kit.addLight("SpotLight", up, LED, 22, 1.2, Enum.NormalId.Top, 50)
	end
	for _, pos in { { -hw + 5, -hd + 6 }, { hw - 5, -hd + 6 }, { -hw + 4, hd - 5 }, { hw - 4, hd - 5 }, { pl[1] - 5, (pl[3] + pl[4]) / 2 } } do
		palm(kit, detail, at(pos[1], 0.3, pos[2]).Position, rng:NextNumber(20, 30), rng)
	end
	-- hedges along the front wall's inside
	for _, xr in { { -hw + 2, gate0 - 3 }, { gate1 + 20, hw - 2 } } do
		if xr[2] - xr[1] > 2 then
			dspan(detail, xr[1], xr[2], 0.3, 3, -hd + 1.4, -hd + 3.4, Color3.fromRGB(30, 64, 34), Enum.Material.Grass)
		end
	end

	------------------------------------------------------------ the record
	local drivePos = at(gateC, 0.45, -hd + 10).Position
	local rec: Rec = {
		plot = plot,
		kind = kind,
		design = d,
		model = model,
		frame = frame,
		bays = bayCFs,
		bayCars = {},
		bayIds = {},
		signTitle = title,
		signSub = sub,
		driveway = CFrame.lookAt(drivePos, drivePos + frame.LookVector),
		owner = nil,
	}
	recs[plot.id] = rec
	table.insert(order, rec)
	CollectionService:AddTag(model, "IslandHouse")
end

-- CityBuilder: build every house (the islands' ground and roads are built by CityBuilder itself)
function Houses.buildWorld(kit: any, parent: Instance)
	local root = kit.folder("IslandHouses", parent)
	for _, plot in WestLayout.housePlots() do
		-- (the low tier's lots wait for their house designs: only the villa and mansion types so far)
		if plot.tier >= 1 then
			buildHouse(kit, root, plot)
		end
	end
end

---------------------------------------------------------------------
-- Owners: claims, signs and the cars in the bays
---------------------------------------------------------------------
local function clearBays(rec: Rec)
	for k, car in rec.bayCars do
		if car then
			car:Destroy()
		end
		rec.bayCars[k] = nil
	end
	rec.bayIds = {}
end

local function displayCar(rec: Rec, k: number, carId: string)
	local spec = Cars.ById[carId]
	if not spec then
		return
	end
	local ok, car = pcall(CarBuilder.build, spec, { interior = false, lights = true, anchored = true })
	if not ok or not car then
		warn("[CityLegends] house showcase car could not be built:", car)
		return
	end
	local h = (car:GetAttribute("Height") :: number?) or 4
	car:PivotTo(rec.bays[k] + Vector3.new(0, h / 2 + 0.05, 0))
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	car.Name = "BayCar" .. k
	-- the owner's Legends Customs look on it
	local owner = rec.owner
	local ownerProfile = if owner then PlayerData.get(owner) else nil
	if ownerProfile then
		Customs.setOn(car, Customs.lookOf(ownerProfile, carId))
	end
	car:SetAttribute("Plot", rec.plot.id)
	car:SetAttribute("Bay", k)
	car:SetAttribute("CarId", car:GetAttribute("CarId") or carId)
	car.Parent = rec.model
	CollectionService:AddTag(car, "HouseShowcase")
	-- the owner drives it out: the car comes out on the driveway
	local root = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart")
	if root then
		local p = prompt(root, "Drive", spec.Name, 0.4, 12)
		p:SetAttribute("Plot", rec.plot.id)
		CollectionService:AddTag(p, "HouseOwner")
		p.Triggered:Connect(function(player: Player)
			Houses.drive(player, rec.plot.id, k)
		end)
	end
	rec.bayCars[k] = car
	rec.bayIds[k] = carId
end

local function bayList(profile: any, kind: string): { string }
	local n = H.Types[kind].bays
	local list = profile.HouseBays[kind]
	if type(list) ~= "table" then
		list = {}
		profile.HouseBays[kind] = list
	end
	for k = 1, n do
		if type(list[k]) ~= "string" then
			list[k] = ""
		end
	end
	return list
end

local function refresh(rec: Rec)
	local owner = rec.owner
	local spec = H.Types[rec.kind]
	if owner and owner.Parent then
		rec.model:SetAttribute("Owner", owner.UserId)
		rec.model:SetAttribute("OwnerName", owner.DisplayName)
		rec.signTitle.Text = string.upper(owner.DisplayName)
		rec.signSub.Text = string.upper(spec.name)
		local profile = PlayerData.get(owner)
		local want = if profile then bayList(profile, rec.kind) else {}
		for k = 1, spec.bays do
			local id = want[k] or ""
			local valid = id ~= "" and profile ~= nil and profile.Owned[id] == true
			local current = rec.bayIds[k]
			if not valid then
				if rec.bayCars[k] then
					(rec.bayCars[k] :: Model):Destroy()
					rec.bayCars[k] = nil
				end
				rec.bayIds[k] = nil :: any
			elseif current ~= id or not (rec.bayCars[k] and (rec.bayCars[k] :: Model).Parent) then
				if rec.bayCars[k] then
					(rec.bayCars[k] :: Model):Destroy()
					rec.bayCars[k] = nil
				end
				displayCar(rec, k, id)
			end
		end
	else
		rec.owner = nil
		rec.model:SetAttribute("Owner", nil)
		rec.model:SetAttribute("OwnerName", nil)
		rec.signTitle.Text = "FOR SALE"
		rec.signSub.Text = string.upper(spec.name) .. "  ·  " .. money(spec.price)
		clearBays(rec)
	end
end

local function publish(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local list = {}
	for id in profile.Houses do
		table.insert(list, id)
	end
	table.sort(list)
	player:SetAttribute("Houses", table.concat(list, ","))
	local mine = {}
	local held: { [string]: string } = claims[player] or {}
	for _, plotId in held do
		table.insert(mine, plotId)
	end
	table.sort(mine)
	player:SetAttribute("HousePlots", table.concat(mine, ","))
end

local function release(player: Player, kind: string)
	local mine = claims[player]
	local plotId = mine and mine[kind]
	if not plotId then
		return
	end
	mine[kind] = nil
	local rec = recs[plotId]
	if rec and rec.owner == player then
		rec.owner = nil
		refresh(rec)
	end
end

local function claim(player: Player, kind: string, rec: Rec)
	release(player, kind)
	claims[player] = claims[player] or {}
	claims[player][kind] = rec.plot.id
	rec.owner = player
	local profile = PlayerData.get(player)
	if profile then
		profile.HousePlots[kind] = rec.plot.id
	end
	refresh(rec)
	publish(player)
end

-- a free plot of this type: the one from last time if it's free, else the first free one
local function freePlot(kind: string, preferred: string?): Rec?
	local pref = if preferred then recs[preferred] else nil
	if pref and pref.kind == kind and not pref.owner then
		return pref
	end
	for _, rec in order do
		if rec.kind == kind and not rec.owner then
			return rec
		end
	end
	return nil
end

local function settle(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	for kind in profile.Houses do
		if not (claims[player] and claims[player][kind]) then
			local rec = freePlot(kind, profile.HousePlots[kind])
			if rec then
				claim(player, kind, rec)
			end
		end
	end
	publish(player)
end

---------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------
function Houses.buy(player: Player, plotId: string)
	local rec = recs[plotId]
	local profile = PlayerData.get(player)
	if not (rec and profile and profile.Loaded) then
		return
	end
	local spec = H.Types[rec.kind]
	if rec.owner == player then
		send(player, { kind = "toast", text = "This is your house", color = "accent" })
		return
	elseif rec.owner then
		send(player, { kind = "toast", text = "This house belongs to " .. rec.owner.DisplayName, color = "warning" })
		return
	end
	if profile.Houses[rec.kind] then
		-- already own this type: move in here
		claim(player, rec.kind, rec)
		task.spawn(PlayerData.save, player)
		send(player, { kind = "toast", text = "Moved in: your " .. spec.name .. " is here now", color = "money" })
		return
	end
	if profile.Cash < spec.price then
		send(player, { kind = "toast", text = "Not enough cash: this house costs " .. money(spec.price), color = "danger" })
		return
	end
	PlayerData.addCash(player, -spec.price)
	profile.Houses[rec.kind] = true
	-- start the bays off with your cars (the one you drive first)
	local list = bayList(profile, rec.kind)
	local ids = {}
	if profile.Owned[profile.Selected] then
		table.insert(ids, profile.Selected)
	end
	for id in profile.Owned do
		if id ~= profile.Selected then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		if a == profile.Selected or b == profile.Selected then
			return a == profile.Selected and b ~= profile.Selected
		end
		return Cars.get(a).Price > Cars.get(b).Price
	end)
	for k = 1, spec.bays do
		if list[k] == "" then
			list[k] = ids[k] or ""
		end
	end
	claim(player, rec.kind, rec)
	task.spawn(PlayerData.save, player)
	send(player, { kind = "bought", text = "Welcome home: " .. spec.name, amount = -spec.price })
end

function Houses.drive(player: Player, plotId: string, bay: number)
	local rec = recs[plotId]
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player) then
		return
	end
	local id = rec.bayIds[bay]
	if not (id and profile.Owned[id]) then
		return
	end
	if ctx and ctx.spawnAt then
		ctx.spawnAt[player] = rec.driveway
		task.delay(H.DriveTimeout, function()
			if ctx.spawnAt[player] == rec.driveway then
				ctx.spawnAt[player] = nil
			end
		end)
	end
	send(player, { kind = "drive", id = id })
end

-- the panel's calls (RemoteFunction HouseCall)
local handlers: { [string]: (Player, any) -> any } = {}

handlers.garage = function(player, plotId)
	local rec = if type(plotId) == "string" then recs[plotId] else nil
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player) then
		return { ok = false }
	end
	local owned = {}
	for id in profile.Owned do
		table.insert(owned, id)
	end
	return { ok = true, kind = rec.kind, name = H.Types[rec.kind].name, bays = table.clone(bayList(profile, rec.kind)), owned = owned }
end

handlers.setBay = function(player, arg)
	if type(arg) ~= "table" or type(arg.plot) ~= "string" or type(arg.bay) ~= "number" or type(arg.car) ~= "string" then
		return { ok = false }
	end
	local rec = recs[arg.plot]
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player) then
		return { ok = false }
	end
	local list = bayList(profile, rec.kind)
	local bay = math.floor(arg.bay)
	if bay < 1 or bay > #list then
		return { ok = false }
	end
	if arg.car ~= "" and not profile.Owned[arg.car] then
		return { ok = false, message = "You don't own that car" }
	end
	-- a car stands in one bay only: swap it out of any other
	if arg.car ~= "" then
		for k = 1, #list do
			if k ~= bay and list[k] == arg.car then
				list[k] = list[bay]
			end
		end
	end
	list[bay] = arg.car
	refresh(rec)
	task.spawn(PlayerData.save, player)
	return { ok = true, bays = table.clone(list) }
end

-- give the player plots for the house types they own (after an unlock from the console)
function Houses.refresh(player: Player)
	settle(player)
end

function Houses.init(c: any)
	ctx = c
	ctx.spawnAt = ctx.spawnAt or {}
	fx = ctx.remote("RemoteEvent", "HouseFx")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "HouseCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	local function watch(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 30
			while not PlayerData.get(player) and os.clock() < deadline and player.Parent do
				task.wait(0.25)
			end
			if player.Parent then
				settle(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		local held: { [string]: string } = claims[player] or {}
		for kind in held do
			release(player, kind)
		end
		claims[player] = nil
		ctx.spawnAt[player] = nil
		-- a free plot may now suit someone who had none
		task.defer(function()
			for _, p in Players:GetPlayers() do
				settle(p)
			end
		end)
	end)
end

return Houses
