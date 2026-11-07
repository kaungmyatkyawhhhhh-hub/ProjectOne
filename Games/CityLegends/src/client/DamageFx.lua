--[[
	DamageFx (owner, 2026-11-07: "add car scrapes and etc"): what a car has been through, on every player's screen. The
	server keeps the marks (the car's "Dmg" attribute, JSON, and "Dirt"); here they are drawn as Textures on the car's
	own body meshes, so they follow the real surface on old and new models alike and show over any paint.

	A model is many pieces, and the door may not be in the piece with the big box, so a mark goes on every outer piece
	under it. All of them use one scale, the same for every car: a picture (tools/damage/make_marks.py) is a clear square
	with the mark in the middle, a tile is bigger than any piece, so the mark never repeats, and the offset puts its middle
	on the spot. A car's marks are limited (CarCare.MaxMarks), nothing is drawn on traffic, and only cars near the camera
	get them.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cars"))
local Windscreens = require(script.Parent:WaitForChild("Windscreens"))

local DamageFx = {}

local PICTURES = {
	s = { "rbxassetid://95199303996128", "rbxassetid://71455338738784", "rbxassetid://99420669845226" },
	t = { "rbxassetid://76546089071589", "rbxassetid://119146799951255" },
	d = { "rbxassetid://123717521148047", "rbxassetid://107789539849416", "rbxassetid://105575178731960" },
}
local CRACK_GLASS = "rbxassetid://126770966916561"
local CRACK_LAMP = "rbxassetid://126056100366872"
local RASH = "rbxassetid://126058456617827"
local DIRT = "rbxassetid://113835073290873"

local RANGE = 150
local TILE_SIDE, TILE_END, TILE_V = 24, 12, 8 -- studs a picture covers: bigger than any car piece
local MAX_PIECES = 7 -- pieces one mark goes on
local SKIP_NAMES = { "SkinWheel", "SkinCaliper", "Knuckle", "SkinSteer", "SkinMark", "SkinTail", "DashCluster", "LampFx" }

type Piece = { p: BasePart, lo: Vector3, hi: Vector3, size: number, name: string }
type Rec = {
	json: string?,
	dirt: number,
	skin: Instance?,
	body: { Piece },
	glass: { Piece },
	lamps: { Piece },
	mirrors: { Piece },
	rims: { BasePart },
	wheelMid: Vector3?,
	wheelbase: number,
	lo: Vector3,
	hi: Vector3,
	made: { Instance },
	dirtT: { Texture },
	tilted: { { w: Instance, made: Instance } },
}
local recs: { [Model]: Rec } = setmetatable({}, { __mode = "k" }) :: any

-- which face of a part looks the way a world direction does
local function faceFor(part: BasePart, world: Vector3): Enum.NormalId
	local best, bestD = Enum.NormalId.Front, -2
	for _, n in Enum.NormalId:GetEnumItems() do
		local d = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(n)):Dot(world)
		if d > bestD then
			best, bestD = n, d
		end
	end
	return best
end

-- where a world point lies on a mesh's face, in studs from the mesh's middle, right and down as you look at the face
-- (measured in Studio: a Texture on a MeshPart starts at the middle, not at a corner as it does on a block)
local function faceAB(part: BasePart, face: Enum.NormalId, world: Vector3): (number, number)
	local q = part.CFrame:PointToObjectSpace(world)
	if face == Enum.NormalId.Left then
		return q.Z, -q.Y
	elseif face == Enum.NormalId.Right then
		return -q.Z, -q.Y
	elseif face == Enum.NormalId.Front then
		return -q.X, -q.Y
	elseif face == Enum.NormalId.Back then
		return q.X, -q.Y
	elseif face == Enum.NormalId.Top then
		return q.Z, q.X
	end
	return q.Z, -q.X
end

local function stamp(rec: Rec, part: BasePart, dir: Vector3, world: Vector3, image: string, tileU: number, tileV: number): Texture
	local face = faceFor(part, dir)
	local a, b = faceAB(part, face, world)
	local t = Instance.new("Texture")
	t.Texture = image
	t.Face = face
	t.StudsPerTileU = tileU
	t.StudsPerTileV = tileV
	t.OffsetStudsU = tileU / 2 - a
	t.OffsetStudsV = tileV / 2 - b
	t.ZIndex = 2
	t.Parent = part
	table.insert(rec.made, t)
	return t
end

local function boxOf(rootCF: CFrame, part: BasePart): (Vector3, Vector3)
	local c = rootCF:ToObjectSpace(part.CFrame)
	local s = part.Size / 2
	local x, y, z = c.XVector, c.YVector, c.ZVector
	local e = Vector3.new(math.abs(x.X) * s.X + math.abs(y.X) * s.Y + math.abs(z.X) * s.Z, math.abs(x.Y) * s.X + math.abs(y.Y) * s.Y + math.abs(z.Y) * s.Z, math.abs(x.Z) * s.X + math.abs(y.Z) * s.Y + math.abs(z.Z) * s.Z)
	return c.Position - e, c.Position + e
end

local function skipped(name: string): boolean
	for _, s in SKIP_NAMES do
		if string.find(name, s, 1, true) then
			return true
		end
	end
	return false
end

local function isLamp(src: string): boolean
	return string.find(src, "light", 1, true) ~= nil or string.find(src, "ligt", 1, true) ~= nil or string.find(src, "lamp", 1, true) ~= nil or string.find(src, "lens", 1, true) ~= nil or string.find(src, "drl", 1, true) ~= nil
end

local function collect(car: Model, rec: Rec, rootCF: CFrame)
	rec.body, rec.glass, rec.lamps, rec.mirrors, rec.rims = {}, {}, {}, {}, {}
	local skin = rec.skin
	if not skin then
		return
	end
	local lo, hi = Vector3.one * 1e5, Vector3.one * -1e5
	local corners: { [number]: { BasePart } } = {}
	for _, d in skin:GetDescendants() do
		if d:IsA("BasePart") then
			if string.find(d.Name, "SkinWheel", 1, true) then
				local q = rootCF:PointToObjectSpace(d.Position)
				local key = (if q.Z < 0 then 0 else 2) + (if q.X < 0 then 1 else 2)
				corners[key] = corners[key] or {}
				table.insert(corners[key], d)
			elseif not skipped(d.Name) and d:IsA("MeshPart") then
				local src = string.lower((d:GetAttribute("SrcName") :: string?) or "")
				local a, b = boxOf(rootCF, d)
				local piece: Piece = { p = d, lo = a, hi = b, size = d.Size.X * d.Size.Y * d.Size.Z, name = src }
				local clear = string.sub(src, 1, 10) == "seethrough" or d.Transparency > 0.02 or d.Material == Enum.Material.Glass
				if isLamp(src) then
					table.insert(rec.lamps, piece)
				elseif string.find(src, "mirror", 1, true) then
					table.insert(rec.mirrors, piece)
				end
				if clear then
					if d:GetAttribute("Window") then
						table.insert(rec.glass, piece)
					end
				elseif math.max(d.Size.X, d.Size.Z) >= 1.4 then
					table.insert(rec.body, piece)
					lo, hi = lo:Min(a), hi:Max(b)
				end
			end
		end
	end
	table.sort(rec.body, function(a, b)
		return a.size > b.size
	end)
	rec.lo, rec.hi = lo, hi
	-- the wheels' middle and the wheelbase: a windscreen's place is measured from them
	if corners[1] and corners[2] and corners[3] and corners[4] then
		local function middle(list: { BasePart }): Vector3
			return rootCF:PointToObjectSpace(list[1].Position)
		end
		local front = (middle(corners[1]) + middle(corners[2])) / 2
		local rear = (middle(corners[3]) + middle(corners[4])) / 2
		rec.wheelMid = (front + rear) / 2
		rec.wheelbase = (front - rear).Magnitude
	end
	-- the rim: under the tyre, the biggest pieces of the corner
	for key, list in corners do
		table.sort(list, function(a, b)
			return a.Size.Y > b.Size.Y
		end)
		local tyre = list[1].Size.Y
		local n = 0
		for _, p in list do
			if p.Size.Y < tyre * 0.95 and p.Size.Y > tyre * 0.6 and n < 2 then
				n += 1
				p:SetAttribute("RimCorner", key)
				table.insert(rec.rims, p)
			end
		end
	end
end

-- the outer pieces under a spot. side: which way the car's side looks in the root's space
local function under(rec: Rec, list: { Piece }, spot: Vector3, side: Vector3, reachU: number, reachV: number): { Piece }
	local out: { Piece } = {}
	local axisZ = math.abs(side.Z) > 0.5
	for _, piece in list do
		local lo, hi = piece.lo, piece.hi
		local inU = if axisZ then (spot.X > lo.X - reachU and spot.X < hi.X + reachU) else (spot.Z > lo.Z - reachU and spot.Z < hi.Z + reachU)
		local inV = spot.Y > lo.Y - reachV and spot.Y < hi.Y + reachV
		local outer = if side.X < -0.5 then lo.X < rec.lo.X + 0.8 elseif side.X > 0.5 then hi.X > rec.hi.X - 0.8 elseif side.Z < -0.5 then lo.Z < rec.lo.Z + 1.6 else hi.Z > rec.hi.Z - 1.6
		if inU and inV and outer then
			table.insert(out, piece)
			if #out >= MAX_PIECES then
				break
			end
		end
	end
	return out
end

local SIDES = { L = Vector3.new(-1, 0, 0), R = Vector3.new(1, 0, 0), F = Vector3.new(0, 0, -1), B = Vector3.new(0, 0, 1) }

local function spotOn(rec: Rec, f: string, u: number, v: number): Vector3
	local lo, hi = rec.lo, rec.hi
	local y = lo.Y + v * (hi.Y - lo.Y)
	if f == "L" then
		return Vector3.new(lo.X, y, lo.Z + u * (hi.Z - lo.Z))
	elseif f == "R" then
		return Vector3.new(hi.X, y, lo.Z + u * (hi.Z - lo.Z))
	elseif f == "F" then
		return Vector3.new(lo.X + u * (hi.X - lo.X), y, lo.Z)
	end
	return Vector3.new(lo.X + u * (hi.X - lo.X), y, hi.Z)
end

local function tiltMirror(car: Model, rec: Rec, sign: number)
	local width = rec.hi.X - rec.lo.X
	for _, piece in rec.mirrors do
		-- only a mirror of its own: one mesh with both mirrors stays
		local mid = (piece.lo.X + piece.hi.X) / 2
		if piece.hi.X - piece.lo.X < width * 0.4 and mid * sign > 0 then
			local part = piece.p
			for _, j in part:GetChildren() do
				if j:IsA("WeldConstraint") and (j.Part0 == part or j.Part1 == part) then
					local other = if j.Part0 == part then j.Part1 else j.Part0
					if other then
						local weld = Instance.new("Weld")
						weld.Part0 = other
						weld.Part1 = part
						weld.C0 = other.CFrame:ToObjectSpace(part.CFrame * CFrame.Angles(0, math.rad(14) * sign, math.rad(-24) * sign))
						j.Enabled = false
						weld.Parent = part
						table.insert(rec.tilted, { w = j, made = weld })
					end
				end
			end
		end
	end
	local _ = car
end

-- a Texture fades with its mesh, so glass can't carry one: the crack is a clear plate lying on the windscreen, on the
-- passenger's side, measured per model (tools/damage/windscreens.luau)
local function crackGlass(car: Model, rec: Rec, rootCF: CFrame)
	local id = car:GetAttribute("CarId") :: string?
	local spec = id and (Windscreens[Cars.modelOf(id)] or Windscreens[id])
	local mid = rec.wheelMid
	local root = car.PrimaryPart
	local eye = car:GetAttribute("Eye") :: Vector3?
	if not root or not ((spec and mid) or eye) then
		return
	end
	local side = if eye and eye.X > 0 then -1 else 1
	local c: Vector3, n: Vector3, size: number
	if spec and mid then
		local wb = rec.wheelbase
		local width = spec[5] * wb
		size = math.clamp(math.min(width * 0.5, spec[6] * wb * 0.9), 1.6, 3.2)
		n = Vector3.new(0, spec[4], -spec[3]).Unit
		c = mid + Vector3.new(side * width * 0.22, spec[2] * wb, -spec[1] * wb) + n * 0.06
	else
		local e = eye :: Vector3
		size = 2
		n = Vector3.new(0, 0.87, -0.5).Unit
		c = Vector3.new(side * 0.8, e.Y + 0.5, e.Z - 3.1)
	end
	local p = Instance.new("Part")
	p.Name = "CrackPlate"
	p.Size = Vector3.new(size, size, 0.05)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = rootCF * CFrame.lookAt(c, c + n)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		-- (a Decal fades with its part too; a SurfaceGui doesn't)
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.LightInfluence = 0.7
		g.CanvasSize = Vector2.new(512, 512)
		g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		g.Parent = p
		local im = Instance.new("ImageLabel")
		im.BackgroundTransparency = 1
		im.Size = UDim2.fromScale(1, 1)
		im.Image = CRACK_GLASS
		im.Parent = g
	end
	local w = Instance.new("Weld")
	w.Part0 = root
	w.Part1 = p
	w.C0 = CFrame.lookAt(c, c + n)
	w.Parent = p
	p.Parent = car
	table.insert(rec.made, p)
end

local function draw(car: Model, rec: Rec, json: string, rootCF: CFrame)
	for _, m in rec.made do
		m:Destroy()
	end
	table.clear(rec.made)
	for _, t in rec.tilted do
		t.made:Destroy();
		(t.w :: any).Enabled = true
	end
	table.clear(rec.tilted)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" or rec.lo.X > rec.hi.X then
		return
	end
	for i, mark in data.m or {} do
		local pics = PICTURES[mark.k]
		local side = SIDES[mark.f]
		if pics and side then
			local image = pics[(i - 1) % #pics + 1]
			local spot = spotOn(rec, mark.f, mark.u, mark.v)
			local scale = math.clamp((tonumber(mark.n) or 1) ^ 0.5, 0.85, 1.4)
			local tileU = (if math.abs(side.X) > 0.5 then TILE_SIDE else TILE_END) * scale
			for _, piece in under(rec, rec.body, spot, side, tileU * 0.14, 1) do
				stamp(rec, piece.p, rootCF:VectorToWorldSpace(side), rootCF:PointToWorldSpace(spot), image, tileU, TILE_V * scale)
			end
		end
	end
	local cracks: { [string]: boolean } = {}
	for _, k in data.c or {} do
		cracks[k] = true
	end
	if cracks.glass then
		crackGlass(car, rec, rootCF)
	end
	for key, at in { headL = { "F", -1 }, headR = { "F", 1 }, tailL = { "B", -1 }, tailR = { "B", 1 } } do
		if cracks[key] then
			local side = SIDES[at[1]]
			local lamps: { Piece } = {}
			local reach, height = 0, 0
			for _, piece in rec.lamps do
				local z = (piece.lo.Z + piece.hi.Z) / 2
				if z * side.Z > (rec.hi.Z - rec.lo.Z) * 0.25 and (piece.hi.X * at[2] > 0 or piece.lo.X * at[2] > 0) then
					table.insert(lamps, piece)
					reach = math.max(reach, math.max(math.abs(piece.lo.X), math.abs(piece.hi.X)))
					height += (piece.lo.Y + piece.hi.Y) / 2
				end
			end
			local spot: Vector3
			if #lamps > 0 then
				spot = Vector3.new(at[2] * reach * 0.72, height / #lamps, if side.Z < 0 then rec.lo.Z else rec.hi.Z)
			else
				spot = spotOn(rec, at[1], 0.5 + at[2] * 0.33, 0.5)
				lamps = under(rec, rec.body, spot, side, 1.5, 1)
			end
			for _, piece in lamps do
				stamp(rec, piece.p, rootCF:VectorToWorldSpace(side), rootCF:PointToWorldSpace(spot), CRACK_LAMP, TILE_END, TILE_V)
			end
		end
	end
	for key, at in { bumperF = { "F", 0.68 }, bumperB = { "B", 0.32 } } do
		if cracks[key] then
			local side = SIDES[at[1]]
			local spot = spotOn(rec, at[1], at[2], 0.2)
			for _, piece in under(rec, rec.body, spot, side, 1.5, 0.8) do
				stamp(rec, piece.p, rootCF:VectorToWorldSpace(side), rootCF:PointToWorldSpace(spot), CRACK_LAMP, TILE_END, TILE_V)
			end
		end
	end
	if cracks.mirrorL then
		tiltMirror(car, rec, -1)
	end
	if cracks.mirrorR then
		tiltMirror(car, rec, 1)
	end
	-- curb rash on the rim's lip
	local rash = tonumber(data.r) or 0
	if rash > 0 then
		for _, p in rec.rims do
			local corner = (p:GetAttribute("RimCorner") :: number?) or 1
			if math.floor(rash / 2 ^ (corner - 1)) % 2 == 1 then
				local q = rootCF:PointToObjectSpace(p.Position)
				local dec = Instance.new("Decal")
				dec.Texture = RASH
				dec.Face = faceFor(p, if q.X < 0 then -rootCF.RightVector else rootCF.RightVector)
				dec.Parent = p
				table.insert(rec.made, dec)
			end
		end
	end
end

local function drawDirt(rec: Rec, dirt: number, rootCF: CFrame)
	rec.dirt = dirt
	if #rec.dirtT == 0 and dirt > 0.02 and rec.lo.X < rec.hi.X then
		local mid = (rec.lo + rec.hi) / 2
		local height = rec.hi.Y - rec.lo.Y + 0.2
		for _, f in { "L", "R", "B" } do
			local side = SIDES[f]
			for _, piece in under(rec, rec.body, Vector3.new(if f == "B" then mid.X else 0, mid.Y, mid.Z), side, 8, 3) do
				local part = piece.p
				local dir = rootCF:VectorToWorldSpace(side)
				local face = faceFor(part, dir)
				local a, b = faceAB(part, face, rootCF:PointToWorldSpace(mid))
				local t = Instance.new("Texture")
				t.Texture = DIRT
				t.Face = face
				t.StudsPerTileU = TILE_SIDE
				t.StudsPerTileV = height
				t.OffsetStudsU = TILE_SIDE / 2 - a
				t.OffsetStudsV = height / 2 - b
				t.ZIndex = 1
				t.Parent = part
				table.insert(rec.dirtT, t)
			end
		end
	end
	for _, t in rec.dirtT do
		t.Transparency = 1 - math.clamp(dirt, 0, 1) * 0.85
	end
end

local function visit(car: Instance, camPos: Vector3)
	if not car:IsA("Model") or not car.PrimaryPart or not car:GetAttribute("Skinned") then
		return
	end
	local json = car:GetAttribute("Dmg") :: string?
	local dirt = (car:GetAttribute("Dirt") :: number?) or 0
	if not json and dirt <= 0 then
		return
	end
	if (car:GetPivot().Position - camPos).Magnitude > RANGE then
		return
	end
	local rootCF = car.PrimaryPart.CFrame
	local rec = recs[car]
	local skin = car:FindFirstChild("Skin")
	if not rec or rec.skin ~= skin then
		rec = { json = nil, dirt = -1, skin = skin, body = {}, glass = {}, lamps = {}, mirrors = {}, rims = {}, wheelMid = nil, wheelbase = 0, lo = Vector3.one, hi = Vector3.zero, made = {}, dirtT = {}, tilted = {} }
		collect(car, rec, rootCF)
		recs[car] = rec
	end
	if json and json ~= rec.json then
		rec.json = json
		draw(car, rec, json, rootCF)
	end
	if math.abs(dirt - rec.dirt) > 0.02 then
		drawDirt(rec, dirt, rootCF)
	end
end

function DamageFx.init()
	task.spawn(function()
		while true do
			task.wait(1)
			local cam = workspace.CurrentCamera
			local camPos = if cam then cam.CFrame.Position else Vector3.zero
			local cars = workspace:FindFirstChild("PlayerCars")
			if cars then
				for _, car in cars:GetChildren() do
					pcall(visit, car, camPos)
				end
			end
			local trailers = workspace:FindFirstChild("Trailers")
			if trailers then
				for _, t in trailers:GetChildren() do
					local load = t:FindFirstChild("LoadedCar")
					if load then
						pcall(visit, load, camPos)
					end
				end
			end
		end
	end)
end

return DamageFx
