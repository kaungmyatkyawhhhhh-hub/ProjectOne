--[[
	VenueLooks (server): gives the code-built venues that stand beside a real Yangon place that place's colours
	(owner, 2026-11-21: "for the venues make it look like the actual real life ... as close as possible").
	Only colours, materials and a roof crown are changed, after the venues are built; nothing a venue's own code
	looks up by name is touched. Yangon map only.

	  the hotel (beside Novotel Yangon Max): white walls, red trim, the green tiered Myanmar roof with a gold edge
	  Tower "aurum" (beside Lotte Hotel Yangon, on Inya Lake): white bands and blue-green glass

	VenueLooks.apply()
]]

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local VenueLooks = {}

local function near(c: Color3, r: number, g: number, b: number): boolean
	return math.abs(c.R * 255 - r) < 3 and math.abs(c.G * 255 - g) < 3 and math.abs(c.B * 255 - b) < 3
end

-- rules: { r, g, b, fromMaterial or nil, toColor, toMaterial or nil, reflectance or nil }
local function recolour(model: Instance, rules: { any }): number
	local n = 0
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			for _, rule in rules do
				if near(p.Color, rule[1], rule[2], rule[3]) and (rule[4] == nil or p.Material == rule[4]) then
					p.Color = rule[5]
					if rule[6] then
						p.Material = rule[6]
					end
					if rule[7] then
						p.Reflectance = rule[7]
					end
					n += 1
					break
				end
			end
		end
		if n % 1500 == 1499 then
			task.wait()
		end
	end
	return n
end

local function slab(parent: Instance, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- the Novotel's roof line: a green eave with a gold edge round each roof slab of the tower (rings: the roof decks,
-- the pool and the suites on top stay open)
local function novotelCrown(hotel: Instance)
	local crown = Instance.new("Model")
	crown.Name = "RealLookCrown"
	local GREEN, GOLD = Color3.fromRGB(36, 104, 66), Color3.fromRGB(226, 182, 64)
	for _, r in hotel:GetDescendants() do
		if r:IsA("BasePart") and r.Name == "Roof" and r.Size.X > 60 and r.Size.Z > 60 then
			local c, w, d = r.Position, r.Size.X, r.Size.Z
			local out, th = 7, 2.2
			local y = c.Y - r.Size.Y / 2 - th / 2 - 0.1
			for side = -1, 1, 2 do
				slab(crown, Vector3.new(w + 2 * out, th, out), Vector3.new(c.X, y, c.Z + side * (d + out) / 2), GREEN, Enum.Material.Slate)
				slab(crown, Vector3.new(out, th, d), Vector3.new(c.X + side * (w + out) / 2, y, c.Z), GREEN, Enum.Material.Slate)
				slab(crown, Vector3.new(w + 2 * out + 0.6, 0.6, 0.5), Vector3.new(c.X, y - th / 2 - 0.3, c.Z + side * (d / 2 + out)), GOLD, Enum.Material.SmoothPlastic)
				slab(crown, Vector3.new(0.5, 0.6, d + 2 * out + 0.6), Vector3.new(c.X + side * (w / 2 + out), y - th / 2 - 0.3, c.Z), GOLD, Enum.Material.SmoothPlastic)
			end
		end
	end
	crown.Parent = hotel
end

function VenueLooks.apply()
	if Config.activeMap() ~= "Yangon" then
		return
	end
	local city = workspace:FindFirstChild("City")
	if not city then
		return
	end
	local hotel = city:FindFirstChild("LegendsGrandHotel")
	if hotel and not hotel:FindFirstChild("RealLookCrown") then
		recolour(hotel, {
			{ 214, 182, 132, Enum.Material.Limestone, Color3.fromRGB(240, 238, 232), Enum.Material.SmoothPlastic },
			{ 230, 208, 168, Enum.Material.Limestone, Color3.fromRGB(250, 248, 244), Enum.Material.SmoothPlastic },
			{ 186, 152, 106, Enum.Material.Limestone, Color3.fromRGB(178, 44, 40), Enum.Material.SmoothPlastic },
		})
		novotelCrown(hotel)
	end
	local tower = city:FindFirstChild("Tower_aurum", true)
	if tower and not tower:GetAttribute("RealLook") then
		tower:SetAttribute("RealLook", true)
		recolour(tower, {
			{ 204, 170, 122, Enum.Material.Sandstone, Color3.fromRGB(236, 238, 240), Enum.Material.SmoothPlastic },
			{ 224, 204, 168, Enum.Material.Sandstone, Color3.fromRGB(214, 220, 226), Enum.Material.SmoothPlastic },
			{ 16, 22, 32, Enum.Material.Glass, Color3.fromRGB(52, 104, 140), nil, 0.22 },
		})
	end
end

return VenueLooks
