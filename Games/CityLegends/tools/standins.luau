--[[
	standins.luau (owner, 2026-10-30: "fix that black thing throughout the map and on the roads")
	Roblox's own low-detail stand-ins (Model.LevelOfDetail = StreamingMesh) draw far, streamed-out
	buildings as flat black shapes, worst at night. This swaps them for our own: one plain copy of
	each building's big parts (towers, podiums, roofs) plus a few window strips, kept in
	City.Standins, which is always loaded (Persistent). client/Standins.lua hides a stand-in part
	while the real part it copies is streamed in. Then the buildings' LevelOfDetail goes to Disabled.

	Run it in the open City Legends place (Edit, command bar or the MCP's execute_luau). Running it
	again rebuilds City.Standins from scratch. It finds the buildings by City.Standins' "Sources"
	list too, so it still works after their LevelOfDetail was switched off.
]]

local CollectionService = game:GetService("CollectionService")

local city = workspace:FindFirstChild("City")
assert(city, "no City in Workspace")

local WARM = Color3.fromRGB(165, 138, 104)
local COOL = Color3.fromRGB(116, 134, 160)
-- (dark glass is lifted toward the far skyline's blue-grey so it never reads as a black block)
local FLOOR = Color3.fromRGB(62, 70, 82)
local rng = Random.new(20261030)

-- the buildings: everything still on StreamingMesh, plus the ones a previous run switched off
local sources: { Model } = {}
local seen: { [Model]: boolean } = {}
local function addSource(m: Instance?)
	if m and m:IsA("Model") and not seen[m] then
		seen[m] = true
		table.insert(sources, m)
	end
end
for _, m in city:GetDescendants() do
	if m:IsA("Model") and m.LevelOfDetail == Enum.ModelLevelOfDetail.StreamingMesh then
		addSource(m)
	end
end
local old = city:FindFirstChild("Standins")
if old then
	for _, s in old:GetChildren() do
		local ov = s:FindFirstChild("For")
		if ov and ov:IsA("ObjectValue") then
			addSource(ov.Value)
		end
	end
	old:Destroy()
end

local root = Instance.new("Model")
root.Name = "Standins"
root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

local function lum(c: Color3): number
	return 0.3 * c.R + 0.59 * c.G + 0.11 * c.B
end

local function plain(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

local parts, windows = 0, 0
for i, m in sources do
	local s = Instance.new("Model")
	s.Name = m.Name
	local ov = Instance.new("ObjectValue")
	ov.Name = "For"
	ov.Value = m
	ov.Parent = s
	for _, d in m:GetDescendants() do
		if not d:IsA("BasePart") or d.Transparency >= 0.5 then
			continue
		end
		local size = d.Size
		if math.min(size.X, size.Y, size.Z) < 6 or math.max(size.X, size.Y, size.Z) < 24 then
			continue
		end
		local color = d.Color
		if lum(color) < 0.22 then
			color = color:Lerp(FLOOR, 0.6)
		end
		local material = if d.Material == Enum.Material.Glass then Enum.Material.Glass else Enum.Material.SmoothPlastic
		local body = plain(s, size, d.CFrame, color, material)
		if d:IsA("Part") then
			body.Shape = d.Shape
		end
		-- which real part this copies (client/Standins.lua shows it only while that one is away)
		local link = Instance.new("ObjectValue")
		link.Name = "Real"
		link.Value = d
		link.Parent = body
		parts += 1
		-- a few lit floors on each side of the tall ones (LampGlow: neon at night, plain by day)
		if (not d:IsA("Part") or d.Shape == Enum.PartType.Block) and size.Y >= 50 then
			for _, face in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local alongX = face[2] ~= 0
				local width = if alongX then size.X else size.Z
				if width < 16 then
					continue
				end
				for _ = 1, math.clamp(math.floor(size.Y / 55), 1, 3) do
					local w = width * rng:NextNumber(0.3, 0.85)
					local y = rng:NextNumber(-size.Y / 2 + 10, size.Y / 2 - 6)
					local slide = rng:NextNumber(-(width - w) / 2, (width - w) / 2)
					local off = if alongX
						then Vector3.new(slide, y, face[2] * (size.Z / 2 + 0.15))
						else Vector3.new(face[1] * (size.X / 2 + 0.15), y, slide)
					local strip = plain(body, if alongX then Vector3.new(w, 2.6, 0.3) else Vector3.new(0.3, 2.6, w), d.CFrame * CFrame.new(off), if rng:NextNumber() < 0.6 then WARM else COOL, Enum.Material.Neon)
					strip.Transparency = 0.35
					CollectionService:AddTag(strip, "LampGlow")
					windows += 1
				end
			end
		end
	end
	s.Parent = root
	m.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
	if i % 40 == 0 then
		task.wait()
	end
end
root.Parent = city
return string.format("stand-ins: %d buildings, %d parts, %d window strips", #sources, parts, windows)
