--[[
	Towers
	Luxury residential towers you can walk into (owner, 2026-10-22: "towers that u can go inside
	and penthouse stuffs like larping rich people", GTA 5 apartment style, no clubs or alcohol;
	then "add DJ booth and party mode").

	Each tower (Config.Towers.List) stands on its own city block:
	  * street level: a plaza with a fountain, a lit entrance canopy with the tower's name, and a
	    glass lobby you walk into (concierge, penthouse sales desk, lounge, elevators)
	  * the penthouse: real floors at the top of the tower, so the glass walls show the city. A TV
	    lounge with sofas you sit on, a kitchen, a bedroom with a wardrobe and mirror, a wall safe
	    (the owner's daily rent), a car showcase turntable (a resident's own car), a DJ booth with a
	    party mode (music and lights) and a confetti popper
	  * the roof: a sky pool with loungers, a telescope looking over the city and a helipad with a
	    parked helicopter (helicopter tour)
	Elevators (ProximityPrompts) move you between the lobby, the penthouse and the roof. Anyone can
	visit; buying a penthouse (in-game cash) gives the daily rent, a home spawn and your name on the
	residents' plaque. Effects, the telescope and the tour run on the client (Penthouse.client.lua).

	CityBuilder calls Towers.block for every city block; it returns true where it built a tower.
	Towers.suite builds just a penthouse floor (and optionally the roof terrace) on another
	building, for the Legends Grand Hotel's suites (Hotel.lua): same rooms, buying, home, party
	mode and showcase, with the elevator's lobby and roof stops set by that building.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Towers = {}

type TowerSpec = {
	id: string,
	name: string,
	block: { number },
	height: number,
	price: number,
	rent: number,
	accent: Color3,
	perMinute: number?, -- hotel suites: paid every minute instead of the safe's daily rent
	levelName: string?, -- what the elevators call the penthouse floor (default "Penthouse")
}
-- a penthouse floor on someone else's building (the hotel's suites)
export type SuiteOpts = {
	frame: CFrame, -- the building's frame at ground level, -Z out of the entrance; the floor is 84 x 84 round it
	yP: number, -- the suite's floor height above the frame
	roof: boolean, -- also build the roof terrace (pool, telescope, helipad) on top of this suite
}
type Built = {
	spec: TowerSpec,
	frame: CFrame, -- street level, -Z = the entrance side
	model: Model,
	stops: { [string]: CFrame }, -- where the elevator leaves you on each level
	home: CFrame, -- beside the bed
	plaques: { TextLabel },
	showcase: BasePart, -- turntable top
	showcaseCar: Model?,
	showcaseId: string?,
	speaker: BasePart,
	music: Sound?,
	confetti: ParticleEmitter,
	tv: BasePart,
}

local C = Config.City
local CURB = C.CurbHeight
local TOWERS = Config.Towers.List :: { TowerSpec }

-- the blocks the towers take (for anything else placed on city blocks)
Towers.BLOCKS = {} :: { { number } }
local byBlock: { [string]: TowerSpec } = {}
for _, t in TOWERS do
	byBlock[t.block[1] .. "," .. t.block[2]] = t
	table.insert(Towers.BLOCKS, { t.block[1], t.block[2] })
end

local built: { [string]: Built } = {}

-- sizes (studs; a character is about 5 tall)
local F = 84 -- footprint
local HF = F / 2
local LH = 26 -- lobby height
local PH = 30 -- penthouse height (double height living room)

-- palette
local MARBLE = Color3.fromRGB(226, 222, 214)
local MARBLE_DARK = Color3.fromRGB(40, 40, 44)
local GOLD = Color3.fromRGB(201, 162, 92)
local WALNUT = Color3.fromRGB(74, 50, 36)
local OAK = Color3.fromRGB(150, 116, 82)
local CREAM = Color3.fromRGB(214, 202, 182)
local CHARCOAL = Color3.fromRGB(34, 34, 38)
local BLACK = Color3.fromRGB(12, 12, 14)
local GLASS = Color3.fromRGB(150, 182, 205)
local WARM_LIGHT = Color3.fromRGB(255, 214, 160)
local WATER = Color3.fromRGB(40, 150, 200)
local BRONZE = Color3.fromRGB(70, 58, 44)

---------------------------------------------------------------------
-- Remotes and player state
---------------------------------------------------------------------
local fx: RemoteEvent? = nil
local function remoteFx(): RemoteEvent
	if fx then
		return fx
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local r = Instance.new("RemoteEvent")
	r.Name = "TowerFX" -- server -> client: fades, toasts, cash popups, telescope, tour, emotes
	r.Parent = remotes
	fx = r
	return r
end

local function send(player: Player, info: { [string]: any })
	remoteFx():FireClient(player, info)
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "$" .. out
end

-- the client reads these to word the prompts for this player
local function publish(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local list = {}
	for id in profile.Penthouses do
		table.insert(list, id)
	end
	table.sort(list)
	player:SetAttribute("Penthouses", table.concat(list, ","))
	player:SetAttribute("Home", profile.Home)
end

local refreshResidents: () -> () -- defined below

---------------------------------------------------------------------
-- Building helpers (everything in a tower's own frame: x right, y up, -z out of the entrance)
---------------------------------------------------------------------
local function prompt(parent: Instance, action: string, object: string, key: Enum.KeyCode?, hold: number?, dist: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = key or Enum.KeyCode.E
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = dist or 9
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function seat(parent: Instance, cf: CFrame, w: number, d: number): Seat
	local s = Instance.new("Seat")
	s.Anchored = true
	s.Size = Vector3.new(w, 0.6, d)
	s.CFrame = cf
	s.Transparency = 1
	s.CanCollide = false
	s.CanTouch = true
	s.Parent = parent
	return s
end

local function buildTower(kit: any, parent: Instance, t: TowerSpec, cx: number, cz: number, lot: number, suite: SuiteOpts?): Built
	local mk, deco = kit.mk, kit.deco
	local frame: CFrame
	if suite then
		frame = suite.frame
		cx, cz = frame.Position.X, frame.Position.Z
	else
		-- the entrance faces the city centre along the block's longer offset
		local front = if math.abs(cx) >= math.abs(cz) then Vector3.new(-math.sign(cx), 0, 0) else Vector3.new(0, 0, -math.sign(cz))
		if front.Magnitude < 0.5 then
			front = Vector3.new(0, 0, -1)
		end
		local b = Vector3.new(cx, CURB, cz)
		frame = CFrame.lookAt(b, b + front)
	end
	local base = frame.Position
	local groundY = base.Y -- (CURB for the towers)
	local accent = t.accent
	local yP = if suite then suite.yP else t.height - PH - 4 -- penthouse floor (local)
	local yR = yP + PH + 1.5 -- roof top
	local withStreet = suite == nil
	local withRoof = suite == nil or suite.roof

	local model = Instance.new("Model")
	model.Name = (if suite then "Suite_" else "Tower_") .. t.id
	model:SetAttribute("TowerId", t.id)
	model.Parent = parent

	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	-- a part centred at local (x, y, z); solid ones collide
	local function part(par: Instance, solid: boolean, sx: number, sy: number, sz: number, cf: CFrame, color: Color3, mat: Enum.Material, o: any?): BasePart
		local f = if solid then mk else deco
		return f(par, Vector3.new(sx, sy, sz), cf, color, mat, o)
	end
	local function box(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return part(par, true, sx, sy, sz, at(x, y, z), color, mat, o)
	end
	local function dbox(par: Instance, sx: number, sy: number, sz: number, x: number, y: number, z: number, color: Color3, mat: Enum.Material, o: any?): BasePart
		return part(par, false, sx, sy, sz, at(x, y, z), color, mat, o)
	end
	local function light(p: BasePart, color: Color3, range: number, brightness: number)
		kit.addLight("PointLight", p, color, range, brightness)
	end

	-- glass walls round a level: four sides, mullions outside, an optional doorway in the front
	local function glassBox(par: Instance, fine: Instance, y0: number, h: number, door: number?)
		local sides = {
			{ cf = function(o: number) return at(o, y0 + h / 2, -HF + 0.3) end, along = "x" },
			{ cf = function(o: number) return at(o, y0 + h / 2, HF - 0.3) end, along = "x" },
			{ cf = function(o: number) return at(-HF + 0.3, y0 + h / 2, o) end, along = "z" },
			{ cf = function(o: number) return at(HF - 0.3, y0 + h / 2, o) end, along = "z" },
		}
		for i, s in sides do
			local segs = { { -HF, HF } }
			if i == 1 and door then
				segs = { { -HF, -door / 2 }, { door / 2, HF } }
			end
			for _, seg in segs do
				local len = seg[2] - seg[1]
				local mid = (seg[1] + seg[2]) / 2
				local size = if s.along == "x" then Vector3.new(len, h, 0.4) else Vector3.new(0.4, h, len)
				mk(par, size, s.cf(mid), GLASS, Enum.Material.Glass, { transparency = 0.78, reflectance = 0.12, name = "Glass", shadow = false })
			end
			-- slim bronze mullions every 7 studs, outside the glass (none across the doorway)
			for k = -5, 5 do
				local o = k * 7
				if i == 1 and door and math.abs(o) < door / 2 + 0.5 then
					continue
				end
				local out = if i == 1 then -0.35 elseif i == 2 then 0.35 else 0
				local outX = if i == 3 then -0.35 elseif i == 4 then 0.35 else 0
				deco(fine, Vector3.new(if s.along == "x" then 0.35 else 0.5, h, if s.along == "x" then 0.5 else 0.35), s.cf(o) * CFrame.new(outX, 0, out), BRONZE, Enum.Material.Metal)
			end
		end
		-- head and sill bands
		for _, y in { y0 + 0.4, y0 + h - 0.4 } do
			for _, s in { { 0, -HF - 0.2, F + 1, 0.8 }, { 0, HF + 0.2, F + 1, 0.8 }, { -HF - 0.2, 0, 0.8, F + 1 }, { HF + 0.2, 0, 0.8, F + 1 } } do
				dbox(fine, s[3], 0.8, s[4], s[1], y, s[2], BRONZE, Enum.Material.Metal)
			end
		end
	end

	-- a sofa facing local -z of cf (seat height 2.4)
	local function sofa(par: Instance, cf: CFrame, len: number, color: Color3)
		part(par, true, len, 2, 6, cf * CFrame.new(0, 1, 0), color:Lerp(BLACK, 0.35), Enum.Material.SmoothPlastic)
		part(par, false, len - 0.6, 1, 5, cf * CFrame.new(0, 2.4, -0.3), color, Enum.Material.SmoothPlastic)
		part(par, true, len, 4.2, 1.4, cf * CFrame.new(0, 3.1, 2.3), color, Enum.Material.SmoothPlastic)
		for _, sx in { -1, 1 } do
			part(par, true, 1.2, 3.2, 6, cf * CFrame.new(sx * (len / 2 - 0.6), 1.6, 0), color, Enum.Material.SmoothPlastic)
		end
		local n = math.max(1, math.floor((len - 2) / 3.2))
		for k = 1, n do
			local x = -(len - 2) / 2 + (k - 0.5) * (len - 2) / n
			seat(par, cf * CFrame.new(x, 2.8, -0.4), 2.6, 2.6)
			-- throw pillow
			if k % 2 == 1 then
				part(par, false, 1.6, 1.6, 0.6, cf * CFrame.new(x, 3.6, 1.2) * CFrame.Angles(math.rad(-15), 0, 0), GOLD:Lerp(CREAM, 0.5), Enum.Material.SmoothPlastic)
			end
		end
	end

	-- a floor lamp with a warm glow
	local function floorLamp(par: Instance, x: number, y: number, z: number)
		dbox(par, 0.3, 9, 0.3, x, y + 4.5, z, GOLD, Enum.Material.Metal)
		dbox(par, 2.4, 0.2, 2.4, x, y + 0.1, z, GOLD, Enum.Material.Metal)
		local shade = part(par, false, 3, 2.2, 3, at(x, y + 9.6, z) * CFrame.Angles(0, 0, math.pi / 2), CREAM, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.15 })
		light(shade, WARM_LIGHT, 18, 1.1)
	end

	local function plant(par: Instance, x: number, y: number, z: number, s: number)
		dbox(par, 2.4 * s, 3 * s, 2.4 * s, x, y + 1.5 * s, z, CHARCOAL, Enum.Material.Slate)
		for k = 0, 2 do
			local a = k * 2.1
			part(par, false, 3 * s, 3 * s, 3 * s, at(x + math.cos(a) * 0.6 * s, y + (4 + k) * s, z + math.sin(a) * 0.6 * s), Color3.fromRGB(46, 92, 52), Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
	end

	-- framed art: a gradient canvas
	local function art(par: Instance, cf: CFrame, w: number, h: number, c1: Color3, c2: Color3)
		local frameP = part(par, false, w + 0.6, h + 0.6, 0.3, cf, GOLD, Enum.Material.Metal)
		local canvas = part(par, false, w, h, 0.1, cf * CFrame.new(0, 0, -0.2), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0.6
		gui.CanvasSize = Vector2.new(200, math.floor(200 * h / w))
		gui.Parent = canvas
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.Parent = gui
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.55, c1:Lerp(c2, 0.5)), ColorSequenceKeypoint.new(1, c2) })
		g.Rotation = 35
		g.Parent = f
		for k = 1, 3 do
			local stroke = Instance.new("Frame")
			stroke.BorderSizePixel = 0
			stroke.BackgroundColor3 = if k == 2 then GOLD else Color3.new(1, 1, 1)
			stroke.BackgroundTransparency = 0.25
			stroke.Size = UDim2.fromScale(0.5 + k * 0.1, 0.03)
			stroke.Position = UDim2.fromScale(0.1 * k, 0.25 * k)
			stroke.Rotation = -20 + k * 12
			stroke.Parent = f
		end
		return frameP
	end

	local stops: { [string]: CFrame } = {}
	local plaques: { TextLabel } = {}

	-- an elevator: golden doors in a stone surround on the face of a core, with the floor buttons
	local function elevator(par: Instance, x: number, y: number, z: number, level: string)
		dbox(par, 12, 14, 0.6, x, y + 7, z, MARBLE_DARK, Enum.Material.Marble)
		for _, sx in { -1, 1 } do
			dbox(par, 3.6, 11, 0.3, x + sx * 1.85, y + 5.5, z - 0.4, GOLD, Enum.Material.Metal, { reflectance = 0.35 })
		end
		dbox(par, 0.1, 11, 0.32, x, y + 5.5, z - 0.42, BLACK, Enum.Material.SmoothPlastic)
		local ind = dbox(par, 4, 1.2, 0.2, x, y + 12.3, z - 0.4, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(ind, Enum.NormalId.Front, if level == "lobby" then "L" elseif level == "penthouse" then "PH" else "R", accent, nil, nil, Enum.Font.GothamBold, Vector2.new(200, 60))
		local panel = dbox(par, 1, 2.4, 0.3, x + 5, y + 5, z - 0.45, GOLD, Enum.Material.Metal, { reflectance = 0.3 })
		dbox(par, 0.5, 0.5, 0.1, x + 5, y + 5.5, z - 0.62, accent, Enum.Material.Neon)
		local options = if level == "lobby" then { "penthouse", "roof" } elseif level == "penthouse" then { "lobby", "roof" } else { "penthouse", "lobby" }
		local labels = { lobby = "Lobby", penthouse = t.levelName or "Penthouse", roof = "Roof: sky pool & helipad" }
		for k, dest in options do
			local p = prompt(panel, labels[dest], "Elevator", if k == 1 then Enum.KeyCode.E else Enum.KeyCode.R, 0, 10)
			p.GamepadKeyCode = if k == 1 then Enum.KeyCode.ButtonX else Enum.KeyCode.ButtonY
			p:SetAttribute("Tower", t.id)
			p.Triggered:Connect(function(player: Player)
				Towers.travel(player, t.id, dest)
			end)
		end
		stops[level] = at(x, y + 3.2, z - 6) -- facing out of the doors
	end

	local function plaque(par: Instance, cf: CFrame)
		local p = part(par, false, 10, 3.4, 0.3, cf, BLACK, Enum.Material.SmoothPlastic)
		dbox(par, 10.4, 0.15, 0.32, 0, 0, 0, GOLD, Enum.Material.Neon).CFrame = cf * CFrame.new(0, -1.8, 0)
		local _, _, label = kit.surfaceText(p, Enum.NormalId.Front, t.name .. "\nRESIDENTS: none yet", GOLD:Lerp(Color3.new(1, 1, 1), 0.4), nil, nil, Enum.Font.GothamMedium, Vector2.new(500, 170))
		table.insert(plaques, label)
	end

	if withStreet then
		---------------------------------------------------------------- street level
		local plaza = kit.lodGroup(model, "Plaza", base + Vector3.new(0, 20, 0), 520)
		deco(plaza, Vector3.new(lot, 0.12, lot), CFrame.new(cx, CURB + 0.06, cz), Color3.fromRGB(56, 56, 62), Enum.Material.Granite)
		-- glowing paving lines leading to the door
		for _, sx in { -1, 1 } do
			dbox(plaza, 0.5, 0.14, lot / 2 - HF - 4, sx * 12, 0.08, -HF - (lot / 2 - HF) / 2 - 2, accent, Enum.Material.Neon, { transparency = 0.35 })
		end
		-- red carpet and steps
		dbox(plaza, 12, 0.2, 18, 0, 0.18, -HF - 9, Color3.fromRGB(120, 18, 26), Enum.Material.Fabric)
		-- the canopy over the entrance, with the tower's name
		local canopy = box(plaza, 34, 1.2, 18, 0, 16, -HF - 8, BLACK, Enum.Material.Metal, { shadow = true })
		dbox(plaza, 34.4, 0.2, 18.4, 0, 15.3, -HF - 8, WARM_LIGHT, Enum.Material.Neon, { transparency = 0.25 })
		light(canopy, WARM_LIGHT, 28, 1.6)
		for _, sx in { -1, 1 } do
			box(plaza, 0.8, 16, 0.8, sx * 15.5, 8, -HF - 16, GOLD, Enum.Material.Metal, { reflectance = 0.3 })
		end
		local sign = dbox(plaza, 32, 3, 0.4, 0, 18.3, -HF - 17, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(sign, Enum.NormalId.Front, t.name, GOLD:Lerp(Color3.new(1, 1, 1), 0.3), nil, nil, Enum.Font.GothamMedium, Vector2.new(800, 75))
		dbox(plaza, 32, 0.25, 0.3, 0, 16.7, -HF - 17.25, accent, Enum.Material.Neon)
		-- brass lanterns and planters either side of the door
		for _, sx in { -1, 1 } do
			plant(plaza, sx * 20, 0.1, -HF - 4, 1.4)
			local lantern = dbox(plaza, 1.6, 2.6, 1.6, sx * 10, 9, -HF - 0.6, WARM_LIGHT, Enum.Material.Neon, { transparency = 0.2 })
			light(lantern, WARM_LIGHT, 14, 1)
		end
		-- fountain in the forecourt
		local fz = -HF - (lot / 2 - HF) * 0.62
		part(plaza, true, 2.2, 22, 22, at(28, 1.1, fz) * CFrame.Angles(0, 0, math.pi / 2), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
		part(plaza, false, 0.4, 20, 20, at(28, 2.1, fz) * CFrame.Angles(0, 0, math.pi / 2), WATER, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.25, reflectance = 0.3 })
		part(plaza, false, 0.3, 20.5, 20.5, at(28, 1.9, fz) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.5 })
		part(plaza, true, 6, 3, 3, at(28, 4.5, fz) * CFrame.Angles(0, 0, math.pi / 2), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
		local jet = Instance.new("ParticleEmitter")
		jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		jet.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
		jet.LightEmission = 0.6
		jet.Size = NumberSequence.new(0.6, 0.2)
		jet.Transparency = NumberSequence.new(0.3, 1)
		jet.Speed = NumberRange.new(14, 18)
		jet.SpreadAngle = Vector2.new(8, 8)
		jet.Acceleration = Vector3.new(0, -30, 0)
		jet.Lifetime = NumberRange.new(1, 1.3)
		jet.Rate = 60
		jet.EmissionDirection = Enum.NormalId.Top
		local nozzle = dbox(plaza, 0.6, 0.6, 0.6, 28, 7.2, fz, MARBLE, Enum.Material.Marble)
		jet.Parent = nozzle
		-- palms at the corners of the plaza
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				kit.tree(plaza, (frame * CFrame.new(sx * (lot / 2 - 18), 0, sz * (lot / 2 - 18))).Position)
			end
		end

		---------------------------------------------------------------- lobby
		local lobby = kit.lodGroup(model, "Lobby", base + Vector3.new(0, LH / 2, 0), 360)
		box(model, F - 0.8, 0.5, F - 0.8, 0, 0.25, 0, MARBLE, Enum.Material.Marble, { name = "LobbyFloor" })
		box(model, F + 1, 1.2, F + 1, 0, LH + 0.6, 0, CHARCOAL, Enum.Material.Concrete, { name = "LobbyCeiling" })
		glassBox(model, lobby, 0.5, LH, 16)
		-- revolving door (decoration: you walk straight through)
		part(lobby, false, 11, 12, 12, at(0, 6, -HF + 0.3) * CFrame.Angles(0, 0, math.pi / 2), GLASS, Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.85 })
		for k = 0, 3 do
			part(lobby, false, 11, 0.2, 5.5, at(0, 6, -HF + 0.3) * CFrame.Angles(0, k * math.pi / 2 + 0.4, 0) * CFrame.new(0, 0, 2.75), GLASS, Enum.Material.Glass, { transparency = 0.7 })
		end
		dbox(lobby, 13, 0.6, 13, 0, 11.6, -HF + 0.3, GOLD, Enum.Material.Metal)
		-- floor inlay and a dark border
		dbox(lobby, 30, 0.06, 30, 0, 0.53, -8, MARBLE_DARK, Enum.Material.Marble)
		dbox(lobby, 26, 0.08, 26, 0, 0.55, -8, MARBLE, Enum.Material.Marble)
		part(lobby, false, 0.1, 10, 10, at(0, 0.6, -8) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		-- elevator core at the back
		box(model, 22, LH, 14, 0, LH / 2 + 0.5, HF - 7, MARBLE_DARK, Enum.Material.Marble, { name = "Core" })
		elevator(lobby, 0, 0.5, HF - 14.1, "lobby")
		-- chandelier: three glowing rings
		for k, r in { 18, 12, 6 } do
			local ring = part(lobby, false, 0.5, r, r, at(0, LH - 3 - k * 1.6, -8) * CFrame.Angles(0, 0, math.pi / 2), WARM_LIGHT, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.2 })
			if k == 2 then
				light(ring, WARM_LIGHT, 40, 1.4)
			end
		end
		-- concierge desk (left) and penthouse sales (right)
		for _, side in { -1, 1 } do
			local x = side * 24
			box(lobby, 16, 4, 4, x, 2.5, 6, WALNUT, Enum.Material.Wood)
			dbox(lobby, 16.4, 0.4, 4.4, x, 4.7, 6, MARBLE, Enum.Material.Marble)
			dbox(lobby, 16.2, 0.2, 0.2, x, 0.9, 3.9, accent, Enum.Material.Neon)
			local back = dbox(lobby, 18, 9, 0.6, x, 8, 13, WALNUT, Enum.Material.Wood)
			local signP = dbox(lobby, 14, 2, 0.2, x, 9.5, 12.6, BLACK, Enum.Material.SmoothPlastic)
			kit.surfaceText(signP, Enum.NormalId.Front, if side < 0 then "CONCIERGE" else "PENTHOUSE SALES", GOLD:Lerp(Color3.new(1, 1, 1), 0.3), nil, nil, Enum.Font.GothamMedium, Vector2.new(560, 80))
			light(back, WARM_LIGHT, 16, 0.8)
		end
		-- scale model of the tower on the sales desk, and the buy prompt
		local modelBase = dbox(lobby, 2.4, 0.3, 2.4, 24, 5.05, 6, BLACK, Enum.Material.SmoothPlastic)
		dbox(lobby, 1.4, 5, 1.4, 24, 7.7, 6, Color3.fromRGB(30, 40, 56), Enum.Material.Glass, { reflectance = 0.3 })
		dbox(lobby, 1.5, 0.15, 1.5, 24, 10.2, 6, accent, Enum.Material.Neon)
		local buy = prompt(modelBase, "Buy penthouse", t.name .. "  " .. money(t.price), Enum.KeyCode.E, 1.5, 10)
		CollectionService:AddTag(buy, "TowerBuy")
		buy:SetAttribute("Tower", t.id)
		buy:SetAttribute("Price", t.price)
		buy.Triggered:Connect(function(player: Player)
			Towers.buy(player, t.id)
		end)
		plaque(lobby, at(0, 17.5, HF - 14.25))
		-- lounge seating facing each other across a low table
		for _, sx in { -1, 1 } do
			sofa(lobby, at(sx * 22, 0.5, -18), 14, CREAM)
			sofa(lobby, at(sx * 22, 0.5, -32) * CFrame.Angles(0, math.pi, 0), 14, CREAM)
			dbox(lobby, 8, 1.4, 5, sx * 22, 1.2, -25, MARBLE_DARK, Enum.Material.Marble)
			plant(lobby, sx * 36, 0.5, -36, 1.2)
			plant(lobby, sx * 36, 0.5, 20, 1.2)
		end

		---------------------------------------------------------------- the tower body
		local fine = kit.lodGroup(model, "Facade", base + Vector3.new(0, t.height / 2, 0), 700 + t.height * 0.6)
		local pal = kit.randomPalette("glass")
		pal.body = Color3.fromRGB(16, 22, 32)
		pal.warm = true
		pal.lit = 0.5
		kit.facadeTier(model, cx, cz, F, F, CURB + LH + 1.2, CURB + yP - 1.6, pal, true, nil, fine)
		-- corner light columns in the tower's accent
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				dbox(model, 0.6, yP - LH - 4, 0.6, sx * (HF + 0.5), (LH + yP) / 2, sz * (HF + 0.5), accent, Enum.Material.Neon, { transparency = 0.15 })
			end
		end
		-- the tower's name in a band below the penthouse, on every side
		local band = deco(model, Vector3.new(F + 0.8, 9, F + 0.8), CFrame.new(cx, CURB + yP - 7, cz), BLACK, Enum.Material.SmoothPlastic)
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
			local _, _, label = kit.surfaceText(band, face, t.name, Color3.new(1, 1, 1), BLACK, 0, Enum.Font.GothamMedium, Vector2.new(1100, 120))
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, GOLD), ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(1, accent) })
			grad.Parent = label
		end
	end -- withStreet

	---------------------------------------------------------------- penthouse
	local ph = kit.lodGroup(model, "Penthouse", base + Vector3.new(0, yP + PH / 2, 0), 380)
	box(model, F + 1, 1.6, F + 1, 0, yP - 0.8, 0, CHARCOAL, Enum.Material.Concrete, { name = "PenthouseSlab" })
	box(model, F - 0.8, 0.3, F - 0.8, 0, yP + 0.15, 0, OAK:Lerp(WALNUT, 0.4), Enum.Material.WoodPlanks, { name = "PenthouseFloor" })
	box(model, F + 2, 1.5, F + 2, 0, yR - 0.75, 0, CHARCOAL, Enum.Material.Concrete, { name = "Roof" })
	glassBox(model, ph, yP + 0.3, PH)
	kit.neonOutline(model, cx, cz, F + 1, F + 1, groundY + yP - 0.2, accent, 0.5)
	kit.neonOutline(model, cx, cz, F + 2, F + 2, groundY + yR + 0.1, accent, 0.5)
	-- warm cove lights in the ceiling
	for _, sx in { -1, 1 } do
		dbox(ph, 0.6, 0.3, F - 8, sx * (HF - 4), yP + PH - 0.4, 0, WARM_LIGHT, Enum.Material.Neon, { transparency = 0.1 })
	end
	for _, p in { { -24, -18 }, { 22, -18 }, { -24, 16 }, { 26, 26 }, { 0, -2 } } do
		local l = dbox(ph, 3, 0.2, 3, p[1], yP + PH - 0.2, p[2], WARM_LIGHT, Enum.Material.Neon)
		light(l, WARM_LIGHT, 34, 0.9)
	end
	-- elevator core (back, middle)
	box(model, 18, PH, 14, 0, yP + PH / 2 + 0.3, HF - 7, MARBLE_DARK, Enum.Material.Marble, { name = "PenthouseCore" })
	elevator(ph, 0, yP + 0.3, HF - 14.1, "penthouse")
	plaque(ph, at(0, yP + 17, HF - 14.25))
	local buyHere = prompt(dbox(ph, 1, 1, 1, -7, yP + 4, HF - 14.6, GOLD, Enum.Material.Metal), "Buy this penthouse", t.name .. "  " .. money(t.price), Enum.KeyCode.F, 1.5, 9)
	CollectionService:AddTag(buyHere, "TowerBuy")
	buyHere:SetAttribute("Tower", t.id)
	buyHere:SetAttribute("Price", t.price)
	buyHere.Triggered:Connect(function(player: Player)
		Towers.buy(player, t.id)
	end)

	-- TV lounge (front left): a media wall with a big screen, an L-shaped sofa facing it
	box(ph, 28, 13, 1.6, -26, yP + 6.8, -4, WALNUT, Enum.Material.Wood)
	dbox(ph, 28.2, 0.3, 1.8, -26, yP + 13.4, -4, GOLD, Enum.Material.Metal)
	local tv = dbox(ph, 20, 11, 0.4, -26, yP + 7.5, -5, BLACK, Enum.Material.Glass, { reflectance = 0.2 })
	tv.Name = "TV"
	CollectionService:AddTag(tv, "TowerTV")
	local tvChannel = prompt(tv, "Change channel", "TV", Enum.KeyCode.E, 0, 14)
	tvChannel.Triggered:Connect(function()
		tv:SetAttribute("Channel", ((tv:GetAttribute("Channel") :: number?) or 1) % 3 + 1)
	end)
	tv:SetAttribute("Channel", 1)
	dbox(ph, 20, 0.2, 0.2, -26, yP + 1.6, -5.2, accent, Enum.Material.Neon) -- light under the console
	box(ph, 22, 2, 3, -26, yP + 1.3, -6.5, BLACK, Enum.Material.SmoothPlastic)
	dbox(ph, 26, 0.08, 18, -24, yP + 0.34, -20, Color3.fromRGB(60, 56, 54), Enum.Material.Fabric) -- rug
	sofa(ph, at(-24, yP + 0.3, -30) * CFrame.Angles(0, math.pi, 0), 20, Color3.fromRGB(70, 66, 64))
	sofa(ph, at(-38, yP + 0.3, -18) * CFrame.Angles(0, -math.pi / 2, 0), 12, Color3.fromRGB(70, 66, 64))
	box(ph, 10, 1.4, 6, -24, yP + 1, -18, MARBLE, Enum.Material.Marble)
	floorLamp(ph, -38, yP + 0.3, -34)
	art(ph, at(-26, yP + 8, -2.9) * CFrame.Angles(0, math.pi, 0), 14, 8, accent, Color3.fromRGB(255, 120, 60))

	-- car showcase (front right): a turntable with a resident's car under spotlights
	part(model, true, 1.2, 24, 24, at(22, yP + 0.9, -22) * CFrame.Angles(0, 0, math.pi / 2), CHARCOAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local turntable = part(model, true, 0.4, 23, 23, at(22, yP + 1.6, -22) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(56, 56, 62), Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder })
	turntable.Name = "Turntable"
	-- residents pick the car on show (owner, 2026-10-23: "add a function to change car")
	local showPrompt = Instance.new("ProximityPrompt")
	showPrompt.Name = "ChangeCar"
	showPrompt.ActionText = "Change car"
	showPrompt.ObjectText = "Car showcase"
	showPrompt.KeyboardKeyCode = Enum.KeyCode.E
	showPrompt.MaxActivationDistance = 18
	showPrompt.RequiresLineOfSight = false
	showPrompt.Parent = turntable
	showPrompt.Triggered:Connect(function(player: Player)
		Towers.pickShowcase(player, t.id)
	end)
	part(ph, false, 0.2, 24.4, 24.4, at(22, yP + 1.3, -22) * CFrame.Angles(0, 0, math.pi / 2), accent, Enum.Material.Neon, { shape = Enum.PartType.Cylinder, transparency = 0.3 })
	for k = 0, 2 do
		local a = k * math.pi * 2 / 3 + 0.5
		local spot = dbox(ph, 1, 1.4, 1, 22 + math.cos(a) * 9, yP + PH - 1.2, -22 + math.sin(a) * 9, CHARCOAL, Enum.Material.Metal)
		kit.addLight("SpotLight", spot, Color3.fromRGB(255, 244, 230), 30, 2.2, Enum.NormalId.Bottom, 55)
	end

	-- DJ booth (right side) with speakers; party mode lights live in the ceiling
	local djx, djz = 34, 4
	box(ph, 5, 4.4, 14, djx, yP + 2.5, djz, BLACK, Enum.Material.SmoothPlastic)
	local strip = dbox(ph, 0.2, 4, 13.6, djx - 2.6, yP + 2.4, djz, accent, Enum.Material.Neon, { transparency = 0.45, name = "PartyStrip" })
	strip:SetAttribute("Tower", t.id)
	CollectionService:AddTag(strip, "TowerPartyStrip")
	for _, dz in { -3.5, 3.5 } do
		part(ph, false, 0.3, 3, 3, at(djx, yP + 4.9, djz + dz) * CFrame.Angles(0, 0, math.pi / 2), CHARCOAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	end
	local speakers: { BasePart } = {}
	for _, dz in { -10.5, 10.5 } do
		local sp = box(ph, 4, 11, 4, djx, yP + 5.8, djz + dz, BLACK, Enum.Material.SmoothPlastic)
		for k, r in { 2.6, 1.6 } do
			-- cones facing into the room (a cylinder's axis is its X)
			part(ph, false, 0.2, r, r, at(djx - 2.05, yP + 3 + k * 3.2, djz + dz), CHARCOAL, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		end
		table.insert(speakers, sp)
	end
	local deck = dbox(ph, 1, 0.4, 1, djx - 1.6, yP + 5, djz, accent, Enum.Material.Neon)
	local djPrompt = prompt(deck, "Party mode", "DJ booth", Enum.KeyCode.E, 0, 9)
	djPrompt.Triggered:Connect(function(player: Player)
		Towers.toggleParty(player, t.id)
	end)
	-- party lights and a mirror ball (the client animates them while the party is on)
	local ball = part(ph, false, 3, 3, 3, at(0, yP + PH - 6, -12), Color3.fromRGB(200, 200, 210), Enum.Material.Glass, { shape = Enum.PartType.Ball, reflectance = 0.9 })
	ball.Name = "MirrorBall"
	ball:SetAttribute("Tower", t.id)
	CollectionService:AddTag(ball, "TowerMirrorBall")
	dbox(ph, 0.15, 4.5, 0.15, 0, yP + PH - 2.4, -12, CHARCOAL, Enum.Material.Metal)
	for k = 0, 5 do
		local a = k * math.pi / 3
		local holder = dbox(ph, 1, 0.6, 1, math.cos(a) * 22, yP + PH - 0.6, -6 + math.sin(a) * 22, CHARCOAL, Enum.Material.Metal, { name = "PartyLamp" })
		holder:SetAttribute("Tower", t.id)
		holder:SetAttribute("Index", k)
		CollectionService:AddTag(holder, "TowerPartyLamp")
		local pl = Instance.new("PointLight")
		pl.Brightness = 0
		pl.Range = 30
		pl.Shadows = false
		pl.Name = "PartyLight"
		pl.Parent = holder
	end
	-- confetti popper on a side table by the DJ (a celebration, no drinks)
	local gift = box(ph, 4, 3, 4, 30, yP + 1.8, -6, WALNUT, Enum.Material.Wood)
	local popper = part(ph, false, 2.2, 0.8, 0.8, at(30, yP + 4.4, -6) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	local confetti = Instance.new("ParticleEmitter")
	confetti.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	confetti.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 160)), ColorSequenceKeypoint.new(1, GOLD) })
	confetti.LightEmission = 0.5
	confetti.Size = NumberSequence.new(0.5, 0.3)
	confetti.Speed = NumberRange.new(16, 26)
	confetti.SpreadAngle = Vector2.new(35, 35)
	confetti.Acceleration = Vector3.new(0, -18, 0)
	confetti.Drag = 1.5
	confetti.Lifetime = NumberRange.new(2, 3)
	confetti.RotSpeed = NumberRange.new(-200, 200)
	confetti.Rate = 0
	confetti.EmissionDirection = Enum.NormalId.Top
	confetti.Parent = popper
	prompt(gift, "Pop confetti", "Celebration", Enum.KeyCode.E, 0, 8).Triggered:Connect(function(player: Player)
		confetti:Emit(90)
		local s = Instance.new("Sound")
		s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		s.Volume = 0.8
		s.PlayOnRemove = true
		s.Parent = popper
		s:Destroy()
		send(player, { kind = "cheer" })
	end)

	-- kitchen (back left): an island with stools and a run of tall cabinets
	box(ph, 18, 4, 7, -26, yP + 2.3, 18, Color3.fromRGB(28, 28, 32), Enum.Material.SmoothPlastic)
	dbox(ph, 18.6, 0.5, 7.6, -26, yP + 4.55, 18, MARBLE, Enum.Material.Marble)
	dbox(ph, 18.2, 0.15, 0.15, -26, yP + 0.6, 14.4, accent, Enum.Material.Neon, { transparency = 0.3 })
	for k = -1, 1 do
		local x = -26 + k * 5.5
		part(ph, false, 0.4, 2.2, 2.2, at(x, yP + 3.4, 12.4) * CFrame.Angles(0, 0, math.pi / 2), CREAM, Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
		dbox(ph, 0.3, 3, 0.3, x, yP + 1.8, 12.4, GOLD, Enum.Material.Metal)
		seat(ph, at(x, yP + 3.5, 12.4) * CFrame.Angles(0, math.pi, 0), 2, 2) -- facing the island
		local pend = part(ph, false, 1.6, 1.6, 1.6, at(x, yP + 13, 18), WARM_LIGHT, Enum.Material.Neon, { shape = Enum.PartType.Ball, transparency = 0.1 })
		dbox(ph, 0.1, PH - 13.5, 0.1, x, yP + 13 + (PH - 13) / 2, 18, BLACK, Enum.Material.Metal)
		if k == 0 then
			light(pend, WARM_LIGHT, 20, 0.9)
		end
	end
	box(ph, 22, 16, 3.5, -27, yP + 8.3, HF - 2.2, WALNUT, Enum.Material.Wood)
	dbox(ph, 22.2, 0.2, 0.2, -27, yP + 8.4, HF - 4, GOLD, Enum.Material.Metal)
	dbox(ph, 6, 14, 0.2, -34, yP + 7.4, HF - 4.05, Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { reflectance = 0.3 }) -- fridge
	plant(ph, -38, yP + 0.3, 30, 1.1)

	-- bedroom (back right) behind a walnut and frosted glass partition
	local bx0, bz0 = 12, 12
	box(ph, 24, PH, 0.8, 30, yP + PH / 2 + 0.3, bz0, WALNUT, Enum.Material.Wood) -- along z = 12, doorway at x 12..18
	box(ph, 0.8, PH, HF - bz0, bx0, yP + PH / 2 + 0.3, (bz0 + HF) / 2, Color3.fromRGB(200, 210, 220), Enum.Material.Glass, { transparency = 0.45 })
	art(ph, at(30, yP + 12, bz0 - 0.5), 12, 7, Color3.fromRGB(255, 120, 60), accent)
	-- bed against the back glass
	box(ph, 14, 2.2, 18, 30, yP + 1.4, 31, WALNUT, Enum.Material.Wood)
	dbox(ph, 13.4, 1.4, 17, 30, yP + 3.1, 31, Color3.fromRGB(236, 234, 228), Enum.Material.SmoothPlastic)
	dbox(ph, 13.6, 0.5, 8, 30, yP + 3.9, 26, Color3.fromRGB(60, 62, 70), Enum.Material.SmoothPlastic) -- throw
	for _, sx in { -3.5, 3.5 } do
		dbox(ph, 5, 1.4, 2.2, 30 + sx, yP + 4.4, 38, CREAM, Enum.Material.SmoothPlastic)
	end
	local headboard = box(ph, 16, 9, 1, 30, yP + 4.8, 40.6, WALNUT:Lerp(BLACK, 0.3), Enum.Material.Fabric)
	for _, sx in { -9.5, 9.5 } do
		box(ph, 3.6, 2.6, 3.6, 30 + sx, yP + 1.6, 38.5, WALNUT, Enum.Material.Wood)
		local lamp = part(ph, false, 1.6, 1.6, 1.6, at(30 + sx, yP + 4, 38.5), WARM_LIGHT, Enum.Material.Neon, { shape = Enum.PartType.Ball, transparency = 0.15 })
		light(lamp, WARM_LIGHT, 14, 0.8)
	end
	local homePrompt = prompt(headboard, "Set as home", "Bed", Enum.KeyCode.E, 0.6, 12)
	CollectionService:AddTag(homePrompt, "TowerOwner")
	homePrompt:SetAttribute("Tower", t.id)
	homePrompt.Triggered:Connect(function(player: Player)
		Towers.setHome(player, t.id)
	end)
	-- wardrobe and full-length mirror on the partition
	box(ph, 3.5, 15, 12, bx0 + 2.2, yP + 7.8, 25, WALNUT, Enum.Material.Wood)
	dbox(ph, 0.2, 14, 0.15, bx0 + 4, yP + 7.8, 25, GOLD, Enum.Material.Metal)
	local wardrobe = dbox(ph, 0.4, 0.4, 0.4, bx0 + 4.1, yP + 7.5, 25, GOLD, Enum.Material.Metal)
	prompt(wardrobe, "Get ready", "Wardrobe", Enum.KeyCode.E, 0.8, 8).Triggered:Connect(function(player: Player)
		send(player, { kind = "outfit" })
	end)
	box(ph, 0.4, 11, 4.5, bx0 + 0.7, yP + 6.3, 34.5, Color3.fromRGB(205, 215, 225), Enum.Material.Glass, { reflectance = 0.8, name = "Mirror" })
	dbox(ph, 0.5, 11.6, 5.1, bx0 + 0.6, yP + 6.3, 34.5, GOLD, Enum.Material.Metal)
	-- the wall safe: the owner's daily rent
	local safe = box(ph, 4, 4, 1.4, 36, yP + 7, bz0 + 1.1, Color3.fromRGB(46, 48, 54), Enum.Material.DiamondPlate)
	part(ph, false, 0.3, 1.6, 1.6, at(36, yP + 7, bz0 + 1.9) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	dbox(ph, 0.3, 0.3, 0.1, 37.4, yP + 8.4, bz0 + 1.85, Color3.fromRGB(60, 255, 120), Enum.Material.Neon)
	if t.perMinute then
		-- a hotel suite pays by the minute on its own: a card on the safe shows the rate
		local card = dbox(ph, 3.6, 1.2, 0.1, 36, yP + 9.8, bz0 + 1.85, BLACK, Enum.Material.SmoothPlastic)
		kit.surfaceText(card, Enum.NormalId.Back, money(t.perMinute) .. " / MIN", Color3.fromRGB(60, 255, 120), nil, nil, Enum.Font.GothamBold, Vector2.new(300, 100))
	else
		local rent = prompt(safe, "Open safe", "Daily rent " .. money(t.rent), Enum.KeyCode.E, 1, 9)
		CollectionService:AddTag(rent, "TowerOwner")
		rent:SetAttribute("Tower", t.id)
		rent.Triggered:Connect(function(player: Player)
			Towers.collectRent(player, t.id)
		end)
	end
	floorLamp(ph, 40, yP + 0.3, 18)

	if withRoof then
		---------------------------------------------------------------- roof terrace
		local roof = kit.lodGroup(model, "RoofTerrace", base + Vector3.new(0, yR, 0), 380)
		box(model, F + 2, 0.3, F + 2, 0, yR + 0.15, 0, Color3.fromRGB(96, 86, 74), Enum.Material.WoodPlanks, { name = "Deck" })
		-- glass balustrade with a handrail
		for i, s in { { 0, -HF - 0.6, F + 2.4, 0.4 }, { 0, HF + 0.6, F + 2.4, 0.4 }, { -HF - 0.6, 0, 0.4, F + 2.4 }, { HF + 0.6, 0, 0.4, F + 2.4 } } do
			box(model, s[3], 4.5, s[4], s[1], yR + 2.55, s[2], GLASS, Enum.Material.Glass, { transparency = 0.7, name = "Balustrade" })
			dbox(roof, s[3] + (if i <= 2 then 0 else 0.2), 0.35, s[4] + (if i <= 2 then 0.2 else 0), s[1], yR + 4.95, s[2], GOLD, Enum.Material.Metal)
		end
		-- sky pool along the front edge (wade in: 2 studs deep)
		local poolW, poolD, poolZ = 64, 20, -HF + 12
		box(roof, poolW + 2, 3, 1, 0, yR + 1.8, poolZ + poolD / 2 + 0.5, MARBLE, Enum.Material.Marble)
		for _, sx in { -1, 1 } do
			box(roof, 1, 3, poolD + 2, sx * (poolW / 2 + 0.5), yR + 1.8, poolZ, MARBLE, Enum.Material.Marble)
		end
		box(roof, poolW, 0.4, poolD, 0, yR + 0.5, poolZ, Color3.fromRGB(70, 160, 190), Enum.Material.SmoothPlastic)
		dbox(roof, poolW, 2.4, poolD, 0, yR + 1.9, poolZ, WATER, Enum.Material.Glass, { transparency = 0.45, reflectance = 0.25, name = "Water" })
		dbox(roof, poolW, 0.25, 0.25, 0, yR + 0.8, poolZ - poolD / 2 + 0.2, Color3.fromRGB(120, 230, 255), Enum.Material.Neon)
		local poolGlow = dbox(roof, poolW - 4, 0.2, poolD - 4, 0, yR + 0.75, poolZ, Color3.fromRGB(60, 200, 255), Enum.Material.Neon, { transparency = 0.6 })
		light(poolGlow, Color3.fromRGB(80, 200, 255), 26, 1.2)
		-- loungers facing the pool and the view
		for _, x in { -27, -15, 15, 27 } do
			local cf = at(x, yR + 0.3, -HF + 30) * CFrame.Angles(0, 0, 0)
			part(roof, true, 3.4, 1.2, 8, cf * CFrame.new(0, 1, 0), Color3.fromRGB(236, 234, 228), Enum.Material.SmoothPlastic)
			part(roof, false, 3.4, 0.6, 3.2, cf * CFrame.new(0, 2.3, 2.6) * CFrame.Angles(math.rad(35), 0, 0), Color3.fromRGB(236, 234, 228), Enum.Material.SmoothPlastic)
			seat(roof, cf * CFrame.new(0, 2.1, 0.5), 2.6, 2.6)
		end
		-- parasols
		for _, x in { -21, 21 } do
			dbox(roof, 0.3, 9, 0.3, x, yR + 4.5, -HF + 31, GOLD, Enum.Material.Metal)
			part(roof, false, 0.6, 11, 11, at(x, yR + 9, -HF + 31) * CFrame.Angles(0, 0, math.pi / 2), CREAM, Enum.Material.Fabric, { shape = Enum.PartType.Cylinder })
		end
		-- telescope at the corner, looking out over the city
		local scopeX, scopeZ = HF - 6, -HF + 6
		dbox(roof, 0.4, 4, 0.4, scopeX, yR + 2.3, scopeZ, GOLD, Enum.Material.Metal)
		local scope = part(roof, true, 4, 0.9, 0.9, at(scopeX, yR + 4.6, scopeZ) * CFrame.Angles(0, math.rad(45), 0) * CFrame.Angles(math.rad(8), 0, 0) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(60, 50, 40), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		local scopePrompt = prompt(scope, "Look through", "Telescope", Enum.KeyCode.E, 0, 8)
		scopePrompt.Triggered:Connect(function(player: Player)
			-- out over the corner of the roof, towards the city centre
			local eye = at(scopeX, yR + 5.4, scopeZ).Position
			local dir = (Vector3.new(0, eye.Y - 120, 0) - eye)
			dir = Vector3.new(dir.X, math.min(dir.Y * 0.15, 0), dir.Z).Unit
			send(player, { kind = "scope", eye = eye, dir = dir })
		end)
		-- helipad with a parked helicopter (back half of the roof)
		local hx, hz = 10, 18
		part(roof, true, 0.4, 34, 34, at(hx, yR + 0.5, hz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(40, 42, 46), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder })
		part(roof, false, 0.1, 30, 30, at(hx, yR + 0.72, hz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(230, 200, 60), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
		part(roof, false, 0.12, 28.6, 28.6, at(hx, yR + 0.74, hz) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(40, 42, 46), Enum.Material.Concrete, { shape = Enum.PartType.Cylinder })
		for k = 0, 11 do
			local a = k * math.pi / 6
			local l = dbox(roof, 0.6, 0.4, 0.6, hx + math.cos(a) * 16.4, yR + 0.9, hz + math.sin(a) * 16.4, Color3.fromRGB(80, 255, 120), Enum.Material.Neon)
			if k % 2 == 0 then
				CollectionService:AddTag(l, "Blink")
			end
		end
		local hLetter = dbox(roof, 10, 0.1, 12, hx, yR + 0.8, hz, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
		local hGui = Instance.new("SurfaceGui")
		hGui.Face = Enum.NormalId.Top
		hGui.CanvasSize = Vector2.new(100, 120)
		hGui.LightInfluence = 0.4
		hGui.Parent = hLetter
		local hText = Instance.new("TextLabel")
		hText.BackgroundTransparency = 1
		hText.Size = UDim2.fromScale(1, 1)
		hText.Text = "H"
		hText.Font = Enum.Font.GothamBlack
		hText.TextScaled = true
		hText.TextColor3 = Color3.new(1, 1, 1)
		hText.Rotation = 0
		hText.Parent = hGui
		-- the helicopter: body, cockpit glass, tail boom, rotors, skids
		local heli = Instance.new("Model")
		heli.Name = "Helicopter"
		heli.Parent = roof
		local hcf = at(hx, yR + 0.8, hz) * CFrame.Angles(0, math.rad(-30), 0)
		local body = part(heli, true, 7, 6, 12, hcf * CFrame.new(0, 4.6, 0), Color3.fromRGB(22, 24, 30), Enum.Material.SmoothPlastic, { reflectance = 0.15 })
		part(heli, false, 6.6, 4.4, 4.6, hcf * CFrame.new(0, 5.2, -6.2), Color3.fromRGB(40, 70, 90), Enum.Material.Glass, { transparency = 0.35, reflectance = 0.4 })
		part(heli, false, 7.1, 0.3, 12.1, hcf * CFrame.new(0, 3.4, 0), accent, Enum.Material.Neon)
		part(heli, true, 1.6, 1.8, 14, hcf * CFrame.new(0, 5.8, 12.5), Color3.fromRGB(22, 24, 30), Enum.Material.SmoothPlastic)
		part(heli, false, 0.4, 4, 3, hcf * CFrame.new(0, 7.4, 19), Color3.fromRGB(22, 24, 30), Enum.Material.SmoothPlastic)
		part(heli, false, 0.2, 5, 0.6, hcf * CFrame.new(0.4, 7.4, 19.4), Color3.fromRGB(80, 80, 86), Enum.Material.Metal)
		part(heli, false, 1, 1.2, 1, hcf * CFrame.new(0, 8.1, 0), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
		for k = 0, 3 do
			part(heli, false, 30, 0.2, 1.2, hcf * CFrame.new(0, 8.8, 0) * CFrame.Angles(0, k * math.pi / 4 + math.pi / 8, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		end
		for _, sx in { -1, 1 } do
			part(heli, true, 0.5, 0.5, 13, hcf * CFrame.new(sx * 3.4, 0.25, -0.5), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
			for _, sz in { -3.5, 3 } do
				part(heli, false, 0.3, 1.8, 0.3, hcf * CFrame.new(sx * 3.1, 1.2, sz) * CFrame.Angles(0, 0, sx * 0.3), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
			end
		end
		local nav = part(heli, false, 0.5, 0.5, 0.5, hcf * CFrame.new(0, 3.2, 19.8), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
		CollectionService:AddTag(nav, "Blink")
		prompt(body, "Helicopter tour", "Helicopter", Enum.KeyCode.E, 0.5, 12).Triggered:Connect(function(player: Player)
			send(player, { kind = "tour", from = body.Position })
		end)
		-- roof elevator: a small glass kiosk at the back corner
		local kx, kz = -HF + 9, HF - 9
		box(model, 14, 12, 0.6, kx, yR + 6, kz + 6.7, Color3.fromRGB(28, 28, 32), Enum.Material.Metal)
		for _, sx in { -1, 1 } do
			box(model, 0.6, 12, 13.4, kx + sx * 6.7, yR + 6, kz, GLASS, Enum.Material.Glass, { transparency = 0.6 })
		end
		box(model, 14.4, 0.8, 14.4, kx, yR + 12.4, kz, Color3.fromRGB(28, 28, 32), Enum.Material.Metal)
		kit.neonOutline(roof, (frame * CFrame.new(kx, 0, kz)).Position.X, (frame * CFrame.new(kx, 0, kz)).Position.Z, 14.4, 14.4, groundY + yR + 12.9, accent, 0.3)
		elevator(roof, kx, yR + 0.3, kz + 6.3, "roof")
		-- spire on the kiosk corner of the roof
		local spirePos = frame * CFrame.new(HF - 6, 0, HF - 6)
		kit.spire(model, spirePos.Position.X, spirePos.Position.Z, groundY + yR + 0.3, 0.9)
	end -- withRoof

	local rec: Built = {
		spec = t,
		frame = frame,
		model = model,
		stops = stops,
		home = at(20, yP + 3.2, 17) * CFrame.Angles(0, -math.pi / 2, 0), -- in the bedroom, facing the bed
		plaques = plaques,
		showcase = turntable,
		showcaseCar = nil,
		showcaseId = nil,
		speaker = speakers[1],
		music = nil,
		confetti = confetti,
		tv = tv,
	}
	model:SetAttribute("Party", false)
	CollectionService:AddTag(model, "TowerPenthouse")
	built[t.id] = rec
	return rec
end

---------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------
function Towers.travel(player: Player, id: string, level: string)
	local rec = built[id]
	local char = player.Character
	local stop = rec and rec.stops[level]
	if not (rec and char and stop) then
		return
	end
	local labels = { lobby = "LOBBY", penthouse = "PENTHOUSE", roof = "ROOF" }
	send(player, { kind = "travel", label = rec.spec.name .. "  ·  " .. (labels[level] or "") })
	task.delay(0.35, function()
		if char.Parent then
			char:PivotTo(stop)
		end
	end)
end

-- after penthouses were given from the console: the plaques and the player's own view
function Towers.refresh(player: Player)
	publish(player)
	refreshResidents()
end

function Towers.buy(player: Player, id: string)
	local rec = built[id]
	local profile = PlayerData.get(player)
	if not (rec and profile and profile.Loaded) then
		return
	end
	local t = rec.spec
	if profile.Penthouses[id] then
		send(player, { kind = "toast", text = "You already own this penthouse", color = "accent" })
		return
	end
	if profile.Cash < t.price then
		send(player, { kind = "toast", text = "Not enough cash: this penthouse costs " .. money(t.price), color = "danger" })
		return
	end
	PlayerData.addCash(player, -t.price)
	profile.Penthouses[id] = true
	if profile.Home == "" then
		profile.Home = id
	end
	publish(player)
	refreshResidents()
	task.spawn(PlayerData.save, player)
	send(player, { kind = "bought", text = "Welcome home: " .. t.name, amount = -t.price })
end

function Towers.collectRent(player: Player, id: string)
	local rec = built[id]
	local profile = PlayerData.get(player)
	if not (rec and profile and profile.Loaded) then
		return
	end
	if not profile.Penthouses[id] then
		send(player, { kind = "toast", text = "Only residents can open the safe", color = "warning" })
		return
	end
	local wait = (profile.Rent[id] or 0) + Config.Towers.RentCooldown - os.time()
	if wait > 0 then
		send(player, { kind = "toast", text = string.format("The safe refills in %dh %02dm", wait // 3600, (wait % 3600) // 60), color = "warning" })
		return
	end
	profile.Rent[id] = os.time()
	PlayerData.addCash(player, rec.spec.rent)
	task.spawn(PlayerData.save, player)
	send(player, { kind = "cash", text = "RENT COLLECTED", amount = rec.spec.rent })
end

function Towers.setHome(player: Player, id: string)
	local profile = PlayerData.get(player)
	if not (profile and profile.Loaded and built[id]) then
		return
	end
	if not profile.Penthouses[id] then
		send(player, { kind = "toast", text = "Buy this penthouse to make it your home", color = "warning" })
		return
	end
	profile.Home = id
	publish(player)
	task.spawn(PlayerData.save, player)
	send(player, { kind = "toast", text = built[id].spec.name .. " is now your home", color = "accent" })
end

function Towers.toggleParty(player: Player, id: string)
	local rec = built[id]
	if not rec then
		return
	end
	local on = not rec.model:GetAttribute("Party")
	rec.model:SetAttribute("Party", on)
	if on then
		local list = Config.Sounds.Music
		local s = Instance.new("Sound")
		s.Name = "PartyMusic"
		s.SoundId = list[math.random(1, #list)]
		s.Looped = true
		s.Volume = 0.55
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 20
		s.RollOffMaxDistance = 80
		s.Parent = rec.speaker
		s:Play()
		rec.music = s
		rec.confetti:Emit(60)
	elseif rec.music then
		rec.music:Destroy()
		rec.music = nil
	end
	send(player, { kind = "toast", text = if on then "Party mode ON" else "Party mode off", color = "accent" })
end

-- where a player who set a penthouse as home starts on foot (nil: no home)
function Towers.homeCFrame(player: Player): CFrame?
	local profile = PlayerData.get(player)
	local rec = profile and profile.Home ~= "" and built[profile.Home]
	return if rec then rec.home else nil
end

---------------------------------------------------------------------
-- Residents: plaques and the showcase car (a resident's own car, or a hypercar for show)
---------------------------------------------------------------------
local function setShowcase(rec: Built, carId: string)
	if rec.showcaseId == carId and rec.showcaseCar and rec.showcaseCar.Parent then
		return
	end
	if rec.showcaseCar then
		rec.showcaseCar:Destroy()
		rec.showcaseCar = nil
	end
	local spec = Cars.ById[carId] or Cars.get(Cars.CutsceneId)
	local ok, car = pcall(CarBuilder.build, spec, { interior = false, lights = true, anchored = true })
	if not ok or not car then
		warn("[CityLegends] showcase car could not be built:", car)
		return
	end
	local h = (car:GetAttribute("Height") :: number?) or 4
	local top = rec.showcase.Position + Vector3.new(0, rec.showcase.Size.X / 2, 0)
	car:PivotTo(CFrame.new(top + Vector3.new(0, h / 2 + 0.05, 0)) * rec.frame.Rotation * CFrame.Angles(0, math.rad(35), 0))
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	car.Name = "ShowcaseCar"
	car:SetAttribute("Tower", rec.spec.id)
	car.Parent = rec.model
	CollectionService:AddTag(car, "TowerShowcase")
	rec.showcaseCar = car
	rec.showcaseId = carId
end

refreshResidents = function()
	for id, rec in built do
		local names = {}
		local carId: string? = nil
		for _, p in Players:GetPlayers() do
			local profile = PlayerData.get(p)
			if profile and profile.Penthouses[id] then
				table.insert(names, p.DisplayName)
				carId = carId or profile.Showcase[id] or profile.Selected
			end
		end
		local text = rec.spec.name .. "\nRESIDENTS: " .. (if #names > 0 then table.concat(names, ", ") else "none yet")
		for _, label in rec.plaques do
			label.Text = text
		end
		setShowcase(rec, carId or Cars.CutsceneId)
	end
end

-- the turntable's "Change car": a resident gets the list of their cars to pick from
function Towers.pickShowcase(player: Player, id: string)
	local profile = PlayerData.get(player)
	if not (profile and built[id]) then
		return
	end
	if not profile.Penthouses[id] then
		send(player, { kind = "toast", text = "Only residents can change the car on show", color = "warning" })
		return
	end
	local cars = {}
	for carId in profile.Owned do
		table.insert(cars, carId)
	end
	table.sort(cars, function(a, b)
		local sa, sb = Cars.ById[a], Cars.ById[b]
		return (if sa then sa.Price else 0) > (if sb then sb.Price else 0)
	end)
	send(player, { kind = "pickShowcase", tower = id, cars = cars, current = profile.Showcase[id] or profile.Selected })
end

local function onShowcasePick(player: Player, id: any, carId: any)
	local profile = PlayerData.get(player)
	if not (profile and type(id) == "string" and type(carId) == "string" and built[id]) then
		return
	end
	if not (profile.Penthouses[id] and profile.Owned[carId]) then
		return
	end
	profile.Showcase[id] = carId
	-- this resident's pick goes on show now
	setShowcase(built[id], carId)
	task.spawn(PlayerData.save, player)
end

---------------------------------------------------------------------
-- City hook
---------------------------------------------------------------------
local started = false
local function start()
	if started then
		return
	end
	started = true
	remoteFx()
	local pick = Instance.new("RemoteEvent")
	pick.Name = "TowerShowcase" -- client -> server: the car picked for a turntable
	pick.Parent = ReplicatedStorage:WaitForChild("Remotes")
	pick.OnServerEvent:Connect(onShowcasePick)
	local function watch(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 30
			while not PlayerData.get(player) and os.clock() < deadline and player.Parent do
				task.wait(0.25)
			end
			publish(player)
			refreshResidents()
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function()
		task.defer(refreshResidents)
	end)
	task.defer(refreshResidents)
end

-- called by CityBuilder for every block; builds a tower where Config.Towers puts one
function Towers.block(kit: any, parent: Instance, bi: number, bj: number, cx: number, cz: number, lot: number): boolean
	local t = byBlock[bi .. "," .. bj]
	if not t then
		return false
	end
	buildTower(kit, parent, t, cx, cz, lot)
	start()
	return true
end

-- a penthouse floor on another building (the hotel's suites); returns its elevator stops, which
-- that building fills in for "lobby" (and "roof" when this suite has no roof terrace)
function Towers.suite(kit: any, parent: Instance, t: TowerSpec, opts: SuiteOpts): { [string]: CFrame }
	local rec = buildTower(kit, parent, t, 0, 0, 0, opts)
	start()
	return rec.stops
end

-- TowerFX messages for other modules (toasts, cash popups)
function Towers.send(player: Player, info: { [string]: any })
	send(player, info)
end

-- for code that wants the blocks without CityLayout maths
function Towers.blockCenter(bi: number, bj: number): Vector3
	return Vector3.new((CityLayout.roadCoord(bi) + CityLayout.roadCoord(bi + 1)) / 2, CURB, (CityLayout.roadCoord(bj) + CityLayout.roadCoord(bj + 1)) / 2)
end

return Towers
