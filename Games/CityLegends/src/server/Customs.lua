--[[
	Customs
	Legends Customs, the city's tuning garage (owner, 2026-10-23: "make the game ... cooler"):
	  * a drive-in workshop on its own city block (Config.Customs): a paved forecourt, three bays
	    behind roll-up door openings (the middle one is the tuning bay with a two-post lift and a
	    turntable plate), tool walls, tyre racks, a parts counter, warm workshop lights, the name over
	    the doors; a kerb ramp off the road in front of the tuning bay
	  * stop your car in the tuning bay and press Y (CustomsClient): paint, finish, second colour,
	    window tint, underglow, rim colour, number plate and headlight colour, priced per change and
	    by the car's tier, saved per car (PlayerData.Customs)
	The look rides on the car model as a "Custom" attribute (JSON) and the "Plate" attribute; every
	client paints it on (CustomsClient), so everyone sees it. Penthouse and house showcase cars get
	their owner's look too (Customs.setOn).
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local EntranceRamp = require(script.Parent:WaitForChild("EntranceRamp"))

local Customs = {}

local CU = Config.Customs

export type Look = {
	paint: { number }?,
	finish: string?,
	accent: { number }?,
	tint: number?,
	glow: { number }?,
	rim: { number }?,
	plate: string?,
	head: string?,
}

local FINISHES = { gloss = true, matte = true, metallic = true }
local KEYS = { "paint", "finish", "accent", "tint", "glow", "rim", "plate", "head" }

local ctx: any = nil
local bayCF: CFrame? = nil -- ground level in the middle of the tuning bay, facing out of the door

---------------------------------------------------------------------
-- Looks: checked, compared, put on a car
---------------------------------------------------------------------
local function rgb(v: any): { number }?
	if type(v) ~= "table" then
		return nil
	end
	local r, g, b = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
	if not (r and g and b) then
		return nil
	end
	return { math.clamp(math.floor(r), 0, 255), math.clamp(math.floor(g), 0, 255), math.clamp(math.floor(b), 0, 255) }
end

local function plateText(v: any): string?
	if type(v) ~= "string" then
		return nil
	end
	local t = string.upper(v):gsub("[^%w ]", ""):sub(1, 8)
	t = t:gsub("^%s+", ""):gsub("%s+$", "")
	return if #t > 0 then t else nil
end

-- a look from anywhere (a save, a client) with only valid fields left
function Customs.clean(raw: any): Look
	local out: Look = {}
	if type(raw) ~= "table" then
		return out
	end
	out.paint = rgb(raw.paint)
	out.finish = if type(raw.finish) == "string" and FINISHES[raw.finish] then raw.finish else nil
	out.accent = rgb(raw.accent)
	local tint = tonumber(raw.tint)
	out.tint = if tint and tint >= 1 and tint <= #CU.TintLevels - 1 then math.floor(tint) else nil
	out.glow = rgb(raw.glow)
	out.rim = rgb(raw.rim)
	out.plate = plateText(raw.plate)
	out.head = if type(raw.head) == "string" and CU.Headlights[raw.head] and raw.head ~= "white" then raw.head else nil
	return out
end

function Customs.lookOf(profile: any, carId: string): Look
	local all = profile and profile.Customs
	if type(all) ~= "table" then
		return {}
	end
	return Customs.clean(all[carId])
end

local function same(a: any, b: any): boolean
	if type(a) == "table" and type(b) == "table" then
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
	end
	return a == b
end

-- puts a look on a car model (the clients paint it from the attributes)
function Customs.setOn(model: Model, look: Look)
	if next(look) then
		model:SetAttribute("Custom", HttpService:JSONEncode(look))
	else
		model:SetAttribute("Custom", nil)
	end
	if look.plate then
		model:SetAttribute("Plate", look.plate)
	end
end

-- a player's car as it spawns: its saved look
function Customs.applyTo(player: Player, model: Model, carId: string)
	local profile = PlayerData.get(player)
	if profile then
		Customs.setOn(model, Customs.lookOf(profile, carId))
	end
end

-- the car's class price and, for this player, their brand level's discount (Brands)
local function tierMult(carId: string, player: Player?): number
	local spec = Cars.ById[carId]
	local base = (if spec then CU.TierMult[spec.Tier] else nil) or 1
	if player then
		local Brands = require(script.Parent:WaitForChild("Brands")) :: any
		base *= Config.brandCustomsMult(Brands.levelFor(player, carId))
	end
	return base
end

-- what changing `from` into `to` costs on this car, and which parts changed
function Customs.cost(carId: string, from: Look, to: Look, player: Player?): (number, { string })
	local total, changed = 0, {}
	for _, k in KEYS do
		if not same((from :: any)[k], (to :: any)[k]) then
			total += CU.Prices[k]
			table.insert(changed, k)
		end
	end
	return math.floor(total * tierMult(carId, player)), changed
end

---------------------------------------------------------------------
-- Remote: the client's tuning screen
---------------------------------------------------------------------
local function inBay(car: Model): boolean
	local b = bayCF
	if not b then
		return false
	end
	local d = car:GetPivot().Position - b.Position
	return Vector3.new(d.X, 0, d.Z).Magnitude <= CU.BayRadius + 6
end

local handlers: { [string]: (Player, any, any) -> any } = {}

handlers.state = function(player)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player)
	if not (car and profile) then
		return { ok = false, message = "Drive in with your car" }
	end
	local carId = car:GetAttribute("CarId")
	if type(carId) ~= "string" then
		return { ok = false }
	end
	local CarLevels = require(script.Parent:WaitForChild("CarLevels")) :: any
	local cp = if profile.Owned[carId] then CarLevels.stateOf(profile, carId).cp else 0
	return { ok = true, carId = carId, look = Customs.lookOf(profile, carId), mult = tierMult(carId, player), cash = profile.Cash, cp = cp, inBay = inBay(car) }
end

-- the CP the changes cost (owner, 2026-11-03: looks can be paid with the car's Car Points too)
function Customs.cpCost(changed: { string }): number
	local n = 0
	for _, k in changed do
		n += Config.CarLevels.LookCp[k] or 1
	end
	return n
end

-- (`pay`: "cp" pays with the car's Car Points, otherwise cash)
handlers.buy = function(player, raw, pay)
	local car = ctx.getCar(player)
	local profile = PlayerData.get(player)
	if not (car and profile) then
		return { ok = false, message = "Drive in with your car" }
	end
	if not inBay(car) then
		return { ok = false, message = "Park in the tuning bay first" }
	end
	local carId = car:GetAttribute("CarId")
	if type(carId) ~= "string" or not profile.Owned[carId] then
		return { ok = false }
	end
	local old = Customs.lookOf(profile, carId)
	local new = Customs.clean(raw)
	-- a new plate goes through Roblox's text filter (anything it hides is refused)
	if new.plate and new.plate ~= old.plate then
		local ok, filtered = pcall(function()
			local result = TextService:FilterStringAsync(new.plate :: string, player.UserId, Enum.TextFilterContext.PublicChat)
			return result:GetNonChatStringForBroadcastAsync()
		end)
		if not ok or filtered ~= new.plate then
			return { ok = false, message = "That plate isn't allowed" }
		end
	end
	local cost, changed = Customs.cost(carId, old, new, player)
	if #changed == 0 then
		return { ok = false, message = "Nothing changed" }
	end
	local cpCost = 0
	if pay == "cp" then
		cpCost = Customs.cpCost(changed)
		local CarLevels = require(script.Parent:WaitForChild("CarLevels")) :: any
		if not CarLevels.spendCp(player, carId, cpCost) then
			return { ok = false, message = "Not enough CP: level this car up" }
		end
		cost = 0
	elseif profile.Cash < cost then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -cost)
	ctx.note(player, "customs", 1)
	local all = (profile :: any).Customs
	if type(all) ~= "table" then
		all = {}
		;(profile :: any).Customs = all
	end
	all[carId] = if next(new) then new else nil
	Customs.setOn(car, new)
	if not new.plate then
		-- back to the player's own name plate
		car:SetAttribute("Plate", string.upper(player.Name):gsub("[^%w]", ""):sub(1, 7))
	end
	task.spawn(PlayerData.save, player)
	return { ok = true, cost = cost, cpCost = cpCost, cash = profile.Cash, look = new }
end

function Customs.init(c: any)
	ctx = c
	local call: RemoteFunction = ctx.remote("RemoteFunction", "CustomsCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any, arg2: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg, arg2)
	end
end

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
local CONCRETE = Color3.fromRGB(70, 72, 78)
local DARK = Color3.fromRGB(32, 34, 38)
local STEEL = Color3.fromRGB(120, 124, 130)
local FLOOR = Color3.fromRGB(96, 98, 102)
local LINE = Color3.fromRGB(226, 226, 220)
local WARM = Color3.fromRGB(255, 236, 210)
local BLUE = Color3.fromRGB(28, 52, 92) -- tool chests

-- (CityBuilder asks this when baking the map: this block stays empty and is built at start)
---------------------------------------------------------------------
-- The remodel (2026-11-04, owner-away run, `Prompts/Remodel the venues.md`: "a clean modern workshop:
-- a glass-and-steel front, a polished grey epoxy floor, 3 bays with lifts, tool walls, tyre racks, a
-- paint booth with soft lights; the TUNING bay lit like a stage; a lounge with a window onto the
-- bays"). Looks only: the tuning bay, its turntable plate, the walls and the drive stay as before.
---------------------------------------------------------------------
local GLASS_C = Color3.fromRGB(70, 92, 110)
local YELLOW_C = Color3.fromRGB(236, 186, 36)
local WHITE_C = Color3.fromRGB(238, 238, 234)

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

function Customs.dress(kit: any, model: Model, at: (number, number, number) -> CFrame, d: { [string]: any })
	local mk, deco = kit.mk, kit.deco
	local W, Z0, Z1, H = d.W, d.Z0, d.Z1, d.H
	local DOOR_W, DOOR_H = d.DOOR_W, d.DOOR_H
	local bays: { number } = d.bays
	local bayZ = d.bayZ
	local detail = kit.lodGroup(model, "Remodel", at(0, 10, 0).Position, 480)
	local face = Z0 - 0.8 -- the front wall's outer face

	-------------------------------------------------------------------
	-- outside: a glass-and-steel front
	-------------------------------------------------------------------
	-- dark steel cladding with vertical fins over the solid parts of the front
	local edges = { -W }
	for _, bx in bays do
		table.insert(edges, bx - DOOR_W / 2)
		table.insert(edges, bx + DOOR_W / 2)
	end
	table.insert(edges, W)
	for k = 1, #edges, 2 do
		local x0, x1 = edges[k], edges[k + 1]
		local w = x1 - x0
		if w > 1 then
			deco(model, Vector3.new(w, H - 6, 0.3), at((x0 + x1) / 2, (H - 6) / 2, face - 0.15), Color3.fromRGB(46, 48, 54), Enum.Material.Metal)
			local n = math.max(1, math.floor(w / 3))
			for j = 0, n do
				deco(detail, Vector3.new(0.4, H - 6, 1), at(x0 + j * w / n, (H - 6) / 2, face - 0.6), Color3.fromRGB(84, 88, 96), Enum.Material.Metal)
			end
		end
	end
	-- a band of tinted glass over each door (in front of the lintel), steel mullions
	for _, bx in bays do
		local gh = H - 6 - DOOR_H - 1
		local gy = DOOR_H + 1 + gh / 2
		deco(model, Vector3.new(DOOR_W + 1, gh, 0.3), at(bx, gy, face - 0.2), GLASS_C, Enum.Material.Glass, { reflectance = 0.25 })
		for j = -3, 3 do
			deco(detail, Vector3.new(0.3, gh, 0.5), at(bx + j * DOOR_W / 6, gy, face - 0.4), STEEL, Enum.Material.Metal)
		end
		-- the door: a glass sectional door rolled up (its lower edge shows under the drum)
		deco(detail, Vector3.new(DOOR_W, 1.2, 0.3), at(bx, DOOR_H - 0.6, face + 0.6), GLASS_C:Lerp(STEEL, 0.4), Enum.Material.Glass)
		deco(detail, Vector3.new(DOOR_W, 0.25, 0.4), at(bx, DOOR_H - 1.3, face + 0.6), STEEL, Enum.Material.Metal)
	end
	-- a thin steel canopy blade over the doors with downlights
	deco(model, Vector3.new(W * 2 + 2, 0.6, 6), at(0, DOOR_H + 0.9, face - 3), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	deco(detail, Vector3.new(W * 2 + 2, 0.3, 0.4), at(0, DOOR_H + 1.3, face - 6), STEEL, Enum.Material.Metal)
	for x = -W + 6, W - 6, 12 do
		local dl = deco(detail, Vector3.new(1, 0.15, 1), at(x, DOOR_H + 0.55, face - 3), Color3.fromRGB(255, 244, 226), Enum.Material.Glass)
		local l = kit.addLight("SpotLight", dl, WARM, 20, 1.2, Enum.NormalId.Bottom, 80)
		game:GetService("CollectionService"):AddTag(l, "DayOff")
	end

	-------------------------------------------------------------------
	-- inside
	-------------------------------------------------------------------
	-- the polished epoxy floor (laid over the concrete) and yellow safety lines round each bay
	deco(model, Vector3.new(W * 2 - 2, 0.04, Z1 - Z0 - 2), at(0, 0.16, (Z0 + Z1) / 2), Color3.fromRGB(104, 108, 114), Enum.Material.SmoothPlastic, { reflectance = 0.14 })
	for _, bx in bays do
		local bw, bd = DOOR_W - 4, Z1 - Z0 - 26
		for _, sx in { -1, 1 } do
			deco(model, Vector3.new(0.5, 0.05, bd), at(bx + sx * bw / 2, 0.2, bayZ), YELLOW_C, Enum.Material.SmoothPlastic)
		end
		deco(model, Vector3.new(bw, 0.05, 0.5), at(bx, 0.2, bayZ + bd / 2), YELLOW_C, Enum.Material.SmoothPlastic)
	end
	-- two-post lifts in bays 1 and 3 (the tuning bay has its own)
	for i, bx in bays do
		if i ~= 2 then
			for _, sx in { -1, 1 } do
				mk(model, Vector3.new(1.6, 15, 1.6), at(bx + sx * 13.5, 7.5, bayZ), Color3.fromRGB(196, 40, 40), Enum.Material.Metal, { name = "LiftPost" })
				deco(detail, Vector3.new(2.4, 0.5, 2.4), at(bx + sx * 13.5, 15.25, bayZ), DARK, Enum.Material.Metal)
				deco(detail, Vector3.new(2.6, 0.4, 2.6), at(bx + sx * 13.5, 0.4, bayZ), DARK, Enum.Material.Metal)
				for _, dz in { -4, 4 } do
					deco(detail, Vector3.new(6, 0.5, 0.8), at(bx + sx * 10.5, 2.4, bayZ + dz) * CFrame.Angles(0, sx * math.rad(if dz < 0 then 12 else -12), 0), DARK, Enum.Material.Metal)
				end
			end
			-- an overhead beam with the hoses
			deco(detail, Vector3.new(28.6, 1, 1), at(bx, 15.8, bayZ), Color3.fromRGB(196, 40, 40), Enum.Material.Metal)
		end
	end
	-- the TUNING bay lit like a stage: a dark ring round the plate, a light truss with spots
	local tb = bays[2]
	deco(model, Vector3.new(0.1, 25, 25), at(tb, 0.12, bayZ) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(26, 26, 30), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
	deco(model, Vector3.new(0.12, 23, 23), at(tb, 0.14, bayZ) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 152, 156), Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder })
	local trussY = H - 4
	for _, sz in { -1, 1 } do
		deco(detail, Vector3.new(26, 1, 1), at(tb, trussY, bayZ + sz * 12), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	end
	for _, sx in { -1, 1 } do
		deco(detail, Vector3.new(1, 1, 25), at(tb + sx * 12.5, trussY, bayZ), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	end
	for _, c in { { -9, -9 }, { 9, -9 }, { -9, 9 }, { 9, 9 }, { 0, -12 }, { 0, 12 } } do
		local pos = at(tb + c[1], trussY - 1.2, bayZ + c[2]).Position
		local lamp = deco(detail, Vector3.new(1.2, 1.2, 1.8), CFrame.lookAt(pos, at(tb, 2, bayZ).Position), Color3.fromRGB(22, 22, 24), Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 246, 232), 34, 1.6, Enum.NormalId.Front, 36)
	end
	-- a paint booth at the back of bay 3: white walls, glass front, soft light panels
	local pb = bays[3]
	local pz0, pz1 = Z1 - 30, Z1 - 1
	for _, sx in { -1, 1 } do
		deco(model, Vector3.new(0.4, 16, pz1 - pz0), at(pb + sx * 13, 8, (pz0 + pz1) / 2), WHITE_C, Enum.Material.SmoothPlastic)
	end
	deco(model, Vector3.new(26.4, 0.4, pz1 - pz0), at(pb, 16.2, (pz0 + pz1) / 2), WHITE_C, Enum.Material.SmoothPlastic)
	for _, sx in { -1, 1 } do
		deco(detail, Vector3.new(0.8, 16, 0.8), at(pb + sx * 13, 8, pz0), STEEL, Enum.Material.Metal)
		deco(detail, Vector3.new(4.5, 15, 0.2), at(pb + sx * 10.5, 8.5, pz0), GLASS_C:Lerp(WHITE_C, 0.6), Enum.Material.Glass, { transparency = 0.5 })
	end
	deco(detail, Vector3.new(26, 3, 0.4), at(pb, 14.4, pz0), WHITE_C, Enum.Material.SmoothPlastic)
	local signBooth = deco(detail, Vector3.new(10, 1.6, 0.2), at(pb, 14.4, pz0 - 0.3), DARK, Enum.Material.SmoothPlastic)
	kit.surfaceText(signBooth, Enum.NormalId.Front, "PAINT BOOTH", WHITE_C, nil, nil, Enum.Font.GothamBold, Vector2.new(400, 64))
	for _, z in { pz0 + 7, pz0 + 15, pz0 + 23 } do
		for _, sx in { -1, 1 } do
			local panel = deco(detail, Vector3.new(0.2, 10, 4), at(pb + sx * 12.7, 8, z), Color3.fromRGB(252, 250, 244), Enum.Material.Glass)
			kit.addLight("SurfaceLight", panel, Color3.fromRGB(255, 250, 240), 14, 0.8, if sx < 0 then Enum.NormalId.Right else Enum.NormalId.Left, 120)
		end
	end
	-- the lounge: in the front corner beside bay 1 (between the side wall and the door), behind a
	-- glass wall that looks onto the bays
	local x0, x1 = -W + 1, bays[1] - DOOR_W / 2 - 0.8
	local lz0, lz1 = Z0 + 1, Z0 + 15
	local lx = (x0 + x1) / 2
	deco(model, Vector3.new(0.3, 12, lz1 - lz0), at(x1, 6, (lz0 + lz1) / 2), GLASS_C:Lerp(WHITE_C, 0.5), Enum.Material.Glass, { transparency = 0.6 })
	deco(model, Vector3.new(x1 - x0, 12, 0.3), at(lx, 6, lz1), GLASS_C:Lerp(WHITE_C, 0.5), Enum.Material.Glass, { transparency = 0.6 })
	for z = lz0, lz1, 3.5 do
		deco(detail, Vector3.new(0.4, 12, 0.4), at(x1, 6, z), STEEL, Enum.Material.Metal)
	end
	for x = x0, x1, 4 do
		deco(detail, Vector3.new(0.4, 12, 0.4), at(x, 6, lz1), STEEL, Enum.Material.Metal)
	end
	deco(detail, Vector3.new(0.6, 0.5, lz1 - lz0), at(x1, 12.2, (lz0 + lz1) / 2), STEEL, Enum.Material.Metal)
	deco(detail, Vector3.new(x1 - x0, 0.5, 0.6), at(lx, 12.2, lz1), STEEL, Enum.Material.Metal)
	deco(model, Vector3.new(x1 - x0, 0.06, lz1 - lz0), at(lx, 0.2, (lz0 + lz1) / 2), Color3.fromRGB(120, 86, 58), Enum.Material.WoodPlanks)
	-- a sofa against the side wall looking at the bays, an armchair, a low table, a palm
	if not kitPiece("Chesterfield", at(x0 + 2.5, 0.25, lz0 + 8) * CFrame.Angles(0, math.rad(-90), 0), nil, detail) then
		mk(detail, Vector3.new(3, 3, 9), at(x0 + 2, 1.5, lz0 + 8), Color3.fromRGB(60, 40, 30), Enum.Material.Fabric)
	end
	kitPiece("Armchair", at(x1 - 3, 0.25, lz0 + 11) * CFrame.Angles(0, math.rad(130), 0), nil, detail)
	kitPiece("PottedPalm", at(x1 - 2, 0.25, lz0 + 2), nil, detail)
	mk(detail, Vector3.new(3, 1.4, 5), at(x0 + 7.5, 0.7, lz0 + 8), Color3.fromRGB(30, 30, 34), Enum.Material.Marble)
	-- a coffee counter against the front wall, a machine and a board over it
	mk(detail, Vector3.new(9, 3.6, 2.4), at(x0 + 6, 1.8, lz0 + 1.4), Color3.fromRGB(44, 46, 52), Enum.Material.SmoothPlastic)
	deco(detail, Vector3.new(9.4, 0.3, 2.8), at(x0 + 6, 3.75, lz0 + 1.4), Color3.fromRGB(220, 218, 212), Enum.Material.Marble)
	deco(detail, Vector3.new(1.8, 2, 1.6), at(x0 + 8, 4.9, lz0 + 1.2), Color3.fromRGB(150, 152, 158), Enum.Material.Metal)
	deco(detail, Vector3.new(0.6, 0.8, 0.6), at(x0 + 8, 4.3, lz0 + 2.1), Color3.fromRGB(240, 238, 232), Enum.Material.SmoothPlastic)
	local menuBoard = deco(detail, Vector3.new(6, 2.4, 0.2), at(x0 + 6, 8, lz0 + 0.1) * CFrame.Angles(0, math.pi, 0), DARK, Enum.Material.SmoothPlastic)
	kit.surfaceText(menuBoard, Enum.NormalId.Front, "COFFEE  ·  JUICE", WARM, nil, nil, Enum.Font.GothamBold, Vector2.new(300, 120))
	local loungeLight = deco(detail, Vector3.new(8, 0.3, 8), at(lx, 12.6, (lz0 + lz1) / 2), Color3.fromRGB(255, 244, 228), Enum.Material.Glass)
	deco(detail, Vector3.new(x1 - x0, 0.4, lz1 - lz0), at(lx, 12.9, (lz0 + lz1) / 2), Color3.fromRGB(40, 42, 46), Enum.Material.SmoothPlastic)
	kit.addLight("SurfaceLight", loungeLight, WARM, 16, 1, Enum.NormalId.Bottom, 120)
end

function Customs.isBlock(bi: number, bj: number): boolean
	return bi == CU.Block[1] and bj == CU.Block[2]
end

function Customs.block(kit: any, parent: Instance, bi: number, bj: number, _cx: number, _cz: number, lot: number): boolean
	if not (bi == CU.Block[1] and bj == CU.Block[2]) then
		return false
	end
	local mk, deco = kit.mk, kit.deco
	local base = WestLayout.customs()
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the street the bay doors face
	end
	local model = Instance.new("Model")
	model.Name = "LegendsCustoms"
	model.Parent = parent
	local half = lot / 2
	local W = math.min(half - 20, 86) -- the workshop's half width
	local Z0, Z1 = -half + 72, half - 30 -- front wall, back wall
	local H = 26
	local DOOR_W, DOOR_H = 30, 18
	local bays = { -W * 0.62, 0, W * 0.62 } -- door middles (the tuning bay is the middle one)
	local bayZ = (Z0 + Z1) / 2 - 4
	local detail = kit.lodGroup(model, "Detail", (base * CFrame.new(0, 10, 0)).Position, 480)

	-- forecourt: dark pavers with white lines leading into each bay
	mk(model, Vector3.new(lot, 0.12, Z0 + half), at(0, 0.06, (-half + Z0) / 2), Color3.fromRGB(58, 60, 64), Enum.Material.Pavement, { name = "Forecourt" })
	for _, bx in bays do
		for _, sx in { -1, 1 } do
			deco(model, Vector3.new(0.5, 0.05, Z0 + half - 8), at(bx + sx * (DOOR_W / 2 - 1), 0.13, (-half + Z0) / 2 + 4), LINE, Enum.Material.SmoothPlastic)
		end
	end
	-- the workshop floor: sealed concrete, a lighter square in each bay
	deco(model, Vector3.new(W * 2, 0.1, Z1 - Z0), at(0, 0.06, (Z0 + Z1) / 2), FLOOR, Enum.Material.Concrete, { reflectance = 0.06 })
	for _, bx in bays do
		deco(model, Vector3.new(DOOR_W - 4, 0.12, Z1 - Z0 - 26), at(bx, 0.07, bayZ), Color3.fromRGB(118, 120, 124), Enum.Material.Concrete, { reflectance = 0.08 })
	end

	-- walls: front between and over the doors, sides, back; a roof slab
	local edges = { -W }
	for _, bx in bays do
		table.insert(edges, bx - DOOR_W / 2)
		table.insert(edges, bx + DOOR_W / 2)
	end
	table.insert(edges, W)
	for k = 1, #edges, 2 do
		local x0, x1 = edges[k], edges[k + 1]
		mk(model, Vector3.new(x1 - x0, H, 1.6), at((x0 + x1) / 2, H / 2, Z0), CONCRETE, Enum.Material.Concrete, { name = "FrontWall" })
	end
	for _, bx in bays do
		mk(model, Vector3.new(DOOR_W, H - DOOR_H, 1.6), at(bx, DOOR_H + (H - DOOR_H) / 2, Z0), CONCRETE, Enum.Material.Concrete, { name = "Lintel" })
		-- the rolled-up door's drum and its steel frame
		deco(detail, Vector3.new(DOOR_W + 1, 1.6, 1.6), at(bx, DOOR_H + 0.8, Z0 + 1.4), STEEL, Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			deco(detail, Vector3.new(0.8, DOOR_H, 1.9), at(bx + sx * (DOOR_W / 2 + 0.2), DOOR_H / 2, Z0), DARK, Enum.Material.Metal)
		end
	end
	for _, sx in { -1, 1 } do
		mk(model, Vector3.new(1.6, H, Z1 - Z0), at(sx * W, H / 2, (Z0 + Z1) / 2), CONCRETE, Enum.Material.Concrete, { name = "SideWall" })
	end
	mk(model, Vector3.new(W * 2, H, 1.6), at(0, H / 2, Z1), CONCRETE, Enum.Material.Concrete, { name = "BackWall" })
	mk(model, Vector3.new(W * 2 + 4, 1.6, Z1 - Z0 + 4), at(0, H + 0.8, (Z0 + Z1) / 2), DARK, Enum.Material.Concrete, { name = "Roof" })
	-- a dark band along the top of the facade, the name on it (plain white letters, no neon)
	local band = mk(model, Vector3.new(W * 2 + 4, 5.5, 0.8), at(0, H - 2.6, Z0 - 1.2), DARK, Enum.Material.Metal, { name = "SignBand" })
	kit.surfaceText(band, Enum.NormalId.Front, CU.Name, Color3.fromRGB(240, 240, 236), nil, nil, Enum.Font.GothamBlack, Vector2.new(1600, 110))
	for _, x in { -W * 0.7, -W * 0.25, W * 0.25, W * 0.7 } do
		local lamp = deco(detail, Vector3.new(1.4, 0.6, 1.6), at(x, H + 0.6, Z0 - 2.6), DARK, Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, WARM, 24, 1.6, Enum.NormalId.Bottom, 70)
	end
	-- bay numbers over the doors
	for k, bx in bays do
		local tag = deco(detail, Vector3.new(6, 2.4, 0.3), at(bx, DOOR_H + 3.4, Z0 - 1), Color3.fromRGB(230, 230, 226), Enum.Material.SmoothPlastic)
		kit.surfaceText(tag, Enum.NormalId.Front, if k == 2 then "TUNING" else "BAY " .. k, DARK, nil, nil, Enum.Font.GothamBold, Vector2.new(240, 96))
	end

	-- workshop lights: long ceiling bars, warm white
	for _, bx in bays do
		for _, dz in { -14, 6 } do
			local bar = deco(model, Vector3.new(DOOR_W - 6, 0.4, 1.4), at(bx, H - 1.2, bayZ + dz), Color3.fromRGB(250, 246, 236), Enum.Material.SmoothPlastic)
			kit.addLight("SurfaceLight", bar, WARM, 26, 1.4, Enum.NormalId.Bottom, 120)
		end
	end

	-- the tuning bay: a two-post lift either side and a turntable plate the car stops on
	local tb = bays[2]
	for _, sx in { -1, 1 } do
		mk(model, Vector3.new(1.6, 15, 1.6), at(tb + sx * 13.5, 7.5, bayZ), STEEL, Enum.Material.Metal, { name = "LiftPost" })
		deco(detail, Vector3.new(2.2, 0.5, 2.2), at(tb + sx * 13.5, 15.25, bayZ), DARK, Enum.Material.Metal)
		deco(detail, Vector3.new(6, 0.5, 0.8), at(tb + sx * 10.5, 2.4, bayZ - 4), DARK, Enum.Material.Metal)
		deco(detail, Vector3.new(6, 0.5, 0.8), at(tb + sx * 10.5, 2.4, bayZ + 4), DARK, Enum.Material.Metal)
	end
	-- a camera rig and soft boxes for the "photo" look of the tuning screen
	for _, a in { -0.8, 0.8 } do
		local p = at(tb + math.sin(a) * 17, 0, bayZ + math.cos(a) * 14)
		deco(detail, Vector3.new(0.3, 9, 0.3), p * CFrame.new(0, 4.5, 0), DARK, Enum.Material.Metal)
		local box = deco(detail, Vector3.new(4, 3, 0.6), CFrame.lookAt((p * CFrame.new(0, 9.5, 0)).Position, (at(tb, 3, bayZ)).Position), Color3.fromRGB(248, 246, 240), Enum.Material.SmoothPlastic)
		kit.addLight("SurfaceLight", box, Color3.fromRGB(255, 248, 238), 20, 1.2, Enum.NormalId.Front, 80)
	end

	-- tool walls: pegboard panels with tool shapes, rolling tool chests, a workbench
	for _, sx in { -1, 1 } do
		local wx = sx * (W - 1.2)
		deco(detail, Vector3.new(0.3, 9, Z1 - Z0 - 30), at(wx, 8, (Z0 + Z1) / 2), Color3.fromRGB(54, 56, 60), Enum.Material.Wood)
		local z = Z0 + 18
		while z < Z1 - 16 do
			for k = 0, 3 do
				deco(detail, Vector3.new(0.2, 2.6 - k * 0.4, 0.35), at(wx - sx * 0.25, 9 + k * 0.2, z + k * 1.2) * CFrame.Angles(math.rad(12 * k), 0, 0), STEEL, Enum.Material.Metal)
			end
			z += 9
		end
		for _, cz in { Z0 + 22, Z1 - 24 } do
			mk(model, Vector3.new(3, 4.2, 6), at(wx - sx * 2.5, 2.1, cz), BLUE, Enum.Material.Metal, { name = "ToolChest" })
			for d = 0, 3 do
				deco(detail, Vector3.new(0.1, 0.12, 5.4), at(wx - sx * 4.05, 0.8 + d, cz), STEEL, Enum.Material.Metal)
			end
		end
	end
	mk(model, Vector3.new(14, 3.2, 3), at(-W + 12, 1.6, Z1 - 3), Color3.fromRGB(80, 62, 44), Enum.Material.WoodPlanks, { name = "Workbench" })
	-- tyre racks along the back wall
	for k = 0, 5 do
		for row = 0, 1 do
			deco(detail, Vector3.new(1.1, 3.2, 3.2), at(W - 10 - k * 3.4, 2 + row * 3.6, Z1 - 2.6) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(22, 22, 24), Enum.Material.Rubber, { shape = Enum.PartType.Cylinder })
		end
	end
	deco(detail, Vector3.new(22, 0.4, 2), at(W - 18.5, 5.4, Z1 - 2.6), STEEL, Enum.Material.Metal)
	-- the parts counter in the left bay's corner, a wheel display on the right
	mk(model, Vector3.new(16, 3.6, 3), at(bays[1], 1.8, Z1 - 12), Color3.fromRGB(44, 46, 52), Enum.Material.SmoothPlastic, { name = "Counter" })
	deco(detail, Vector3.new(16.4, 0.3, 3.4), at(bays[1], 3.75, Z1 - 12), Color3.fromRGB(196, 196, 192), Enum.Material.Marble)
	for k = 0, 3 do
		deco(detail, Vector3.new(0.8, 3.4, 3.4), at(bays[3] - 6 + k * 4, 4 + (k % 2) * 4, Z1 - 1.8) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(176, 180, 186), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	end

	Customs.dress(kit, model, at, { W = W, Z0 = Z0, Z1 = Z1, H = H, DOOR_W = DOOR_W, DOOR_H = DOOR_H, bays = bays, bayZ = bayZ })

	-- the drive from the road onto the lot in front of the tuning bay, fitted to the real ground
	-- (EntranceRamp)
	local rampIn = at(tb, 0.2, -half + 0.5)
	task.defer(function()
		EntranceRamp.build(model, rampIn, { width = DOOR_W, color = Color3.fromRGB(70, 70, 74), material = Enum.Material.Concrete, keep = { model } })
	end)

	bayCF = at(tb, 0, bayZ)
	workspace:SetAttribute("CustomsBay", bayCF)
	return true
end

return Customs
