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

local Customs = {}

local CU = Config.Customs
local C = Config.City
local CURB = C.CurbHeight

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

local function tierMult(carId: string): number
	local spec = Cars.ById[carId]
	return (if spec then CU.TierMult[spec.Tier] else nil) or 1
end

-- what changing `from` into `to` costs on this car, and which parts changed
function Customs.cost(carId: string, from: Look, to: Look): (number, { string })
	local total, changed = 0, {}
	for _, k in KEYS do
		if not same((from :: any)[k], (to :: any)[k]) then
			total += CU.Prices[k]
			table.insert(changed, k)
		end
	end
	return math.floor(total * tierMult(carId)), changed
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

local handlers: { [string]: (Player, any) -> any } = {}

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
	return { ok = true, carId = carId, look = Customs.lookOf(profile, carId), mult = tierMult(carId), cash = profile.Cash, inBay = inBay(car) }
end

handlers.buy = function(player, raw)
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
	local cost, changed = Customs.cost(carId, old, new)
	if #changed == 0 then
		return { ok = false, message = "Nothing changed" }
	end
	if profile.Cash < cost then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -cost)
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
	return { ok = true, cost = cost, cash = profile.Cash, look = new }
end

function Customs.init(c: any)
	ctx = c
	local call: RemoteFunction = ctx.remote("RemoteFunction", "CustomsCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
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
	deco(model, Vector3.new(0.12, 22, 22), at(tb, 0.14, bayZ) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 152, 156), Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder })
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

	-- the ramp from the road onto the sidewalk in front of the tuning bay
	local rampZ = -half - C.SidewalkWidth - 2
	-- (a wedge's slope faces its -Z, which is the street here; its top meets the sidewalk)
	mk(model, Vector3.new(DOOR_W, CURB, 4), at(tb, -CURB / 2, rampZ), Color3.fromRGB(62, 62, 66), Enum.Material.Concrete, { class = "Wedge", name = "KerbRamp" })

	bayCF = at(tb, 0, bayZ)
	workspace:SetAttribute("CustomsBay", bayCF)
	return true
end

return Customs
