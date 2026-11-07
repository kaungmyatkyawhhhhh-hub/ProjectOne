--[[
	DamageFx (owner, 2026-11-07: "add car scrapes and etc"): what a car has been through, on every player's screen. The
	server keeps the marks (the car's "Dmg" attribute, JSON, and "Dirt"); here they are drawn as Textures on the car's
	own body meshes, so they follow the real surface on old and new models alike and show over any paint.

	A picture has its mark in the middle of a clear square (tools/damage/make_marks.py). A Texture as big as the side
	of the car shows the mark once, and its offset moves it along the side. A car's marks are limited (CarCare.MaxMarks),
	nothing is drawn on traffic, and only cars near the camera get them.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local DamageFx = {}

local player = Players.LocalPlayer

local PICTURES = {
	s = { "rbxassetid://71079397656664", "rbxassetid://140099113905817", "rbxassetid://121412440068704" },
	t = { "rbxassetid://96575339413396", "rbxassetid://93338775733503" },
	d = { "rbxassetid://140022887084030", "rbxassetid://135876108903543", "rbxassetid://92160608925226" },
}
local CRACK_GLASS = "rbxassetid://93721163308870"
local CRACK_LAMP = "rbxassetid://123464210276255"
local RASH = "rbxassetid://118428293539538"
local DIRT = "rbxassetid://133632990807953"

local RANGE = 260

type Rec = { json: string?, dirt: number, shells: { BasePart }, glass: { BasePart }, made: { Instance }, dirtT: { Texture } }
local recs: { [Model]: Rec } = setmetatable({}, { __mode = "k" }) :: any

-- which face of a part looks the way the car's side does
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

-- the car's big outer shells: the paint, and what else wraps the whole body
local function findShells(car: Model): ({ BasePart }, { BasePart })
	local skin = car:FindFirstChild("Skin")
	local W, L = (car:GetAttribute("Width") :: number?) or 6, (car:GetAttribute("Length") :: number?) or 15
	local list: { { p: BasePart, a: number } } = {}
	local glass: { BasePart } = {}
	if skin then
		for _, d in skin:GetDescendants() do
			if d:IsA("BasePart") then
				local s = d.Size
				local across, along = math.max(s.X, s.Z), math.min(s.X, s.Z)
				local wide = across >= L * 0.6 and along >= W * 0.65
				if wide and (d.Transparency > 0.02 or d.Material == Enum.Material.Glass) then
					table.insert(glass, d)
				elseif wide and d.Transparency <= 0.02 and not string.find(d.Name, "Wheel", 1, true) then
					table.insert(list, { p = d, a = s.X * s.Y * s.Z })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.a > b.a
	end)
	local shells: { BasePart } = {}
	for i = 1, math.min(3, #list) do
		shells[i] = list[i].p
	end
	return shells, glass
end

-- a picture on one side of a part, at u (0..1 along it) and v (0..1 up it)
local function stamp(rec: Rec, part: BasePart, world: Vector3, image: string, u: number, v: number, scale: number, flipU: boolean): Texture
	local face = faceFor(part, world)
	local size = part.Size
	local n = Vector3.FromNormalId(face)
	local w = if math.abs(n.X) > 0.5 then size.Z elseif math.abs(n.Z) > 0.5 then size.X else size.X
	local h = if math.abs(n.Y) > 0.5 then size.Z else size.Y
	local t = Instance.new("Texture")
	t.Texture = image
	t.Face = face
	t.StudsPerTileU = math.max(w * scale, w)
	t.StudsPerTileV = math.max(h * scale, h)
	t.OffsetStudsU = (if flipU then 1 - u - 0.5 else u - 0.5) * t.StudsPerTileU
	t.OffsetStudsV = (0.5 - v) * t.StudsPerTileV
	t.ZIndex = 2
	t.Parent = part
	table.insert(rec.made, t)
	return t
end

local function draw(car: Model, rec: Rec, json: string)
	for _, m in rec.made do
		m:Destroy()
	end
	table.clear(rec.made)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	local root = car.PrimaryPart
	if not root then
		return
	end
	local cf = root.CFrame
	local right, back = cf.RightVector, -cf.LookVector
	local dirs = { L = -right, R = right, F = -back, B = back }
	for i, mark in data.m or {} do
		local pics = PICTURES[mark.k]
		local world = dirs[mark.f]
		if pics and world then
			local image = pics[(i - 1) % #pics + 1]
			for _, part in rec.shells do
				-- u runs nose to tail on the sides, left to right on the ends
				stamp(rec, part, world, image, mark.u, mark.v, 1.05 / math.clamp(mark.n, 0.5, 1.6) ^ 0.3, false)
			end
		end
	end
	local cracks: { [string]: boolean } = {}
	for _, k in data.c or {} do
		cracks[k] = true
	end
	if cracks.glass then
		for _, part in rec.glass do
			local t = stamp(rec, part, dirs.F, CRACK_GLASS, 0.5, 0.5, 1, false)
			t.StudsPerTileU = part.Size.X * 0.9
			t.StudsPerTileV = part.Size.Y * 0.9
		end
	end
	for key, at in { headL = { "F", 0.2 }, headR = { "F", 0.8 }, tailL = { "B", 0.2 }, tailR = { "B", 0.8 } } do
		if cracks[key] then
			for _, part in rec.shells do
				stamp(rec, part, dirs[at[1]], CRACK_LAMP, at[2], 0.5, 1, false)
			end
		end
	end
	-- curb rash on the rim's lip: the biggest rim piece of that corner
	local rash = tonumber(data.r) or 0
	if rash > 0 then
		local skin = car:FindFirstChild("Skin")
		for _, d in if skin then skin:GetDescendants() else {} do
			if d:IsA("BasePart") and string.find(d.Name, "Wheel", 1, true) and math.max(d.Size.Y, d.Size.Z) > 1.2 then
				local q = cf:PointToObjectSpace(d.Position)
				local corner = (if q.Z < 0 then 0 else 2) + (if q.X < 0 then 1 else 2)
				if math.floor(rash / 2 ^ (corner - 1)) % 2 == 1 then
					local dec = Instance.new("Decal")
					dec.Texture = RASH
					dec.Face = faceFor(d, if q.X < 0 then -right else right)
					dec.Parent = d
					table.insert(rec.made, dec)
				end
			end
		end
	end
end

local function drawDirt(car: Model, rec: Rec, dirt: number)
	rec.dirt = dirt
	if #rec.dirtT == 0 and dirt > 0.02 then
		local root = car.PrimaryPart
		if not root then
			return
		end
		local right = root.CFrame.RightVector
		for _, part in rec.shells do
			for _, sd in { 1, -1 } do
				local face = faceFor(part, right * sd)
				local t = Instance.new("Texture")
				t.Texture = DIRT
				t.Face = face
				t.StudsPerTileU = part.Size.Z + 0.1
				t.StudsPerTileV = part.Size.Y + 0.1
				t.ZIndex = 1
				t.Parent = part
				table.insert(rec.dirtT, t)
			end
		end
	end
	for _, t in rec.dirtT do
		t.Transparency = 1 - math.clamp(dirt, 0, 1) * 0.72
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
	local rec = recs[car]
	if (car:GetPivot().Position - camPos).Magnitude > RANGE then
		return
	end
	if not rec then
		local shells, glass = findShells(car)
		rec = { json = nil, dirt = -1, shells = shells, glass = glass, made = {}, dirtT = {} }
		recs[car] = rec
	end
	if json and json ~= rec.json then
		rec.json = json
		draw(car, rec, json)
	end
	if math.abs(dirt - rec.dirt) > 0.02 then
		drawDirt(car, rec, dirt)
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
	local _ = player
end

return DamageFx
