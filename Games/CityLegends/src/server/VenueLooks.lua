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

-- (owner, 2026-11-22, a photo of the real workshop: "build optima werkz to look exactly like this") the compact
-- Optima Werkz front: a red fascia with gold OPTIMA WERKZ YANGON and a chequered flag, a grey band under it, a yellow
-- canopy over the bays, grey concrete pillars and walls, a tan paved forecourt. Numbers follow Customs.block's compact
-- frame (lot 110 deep, 80 wide: half width 32, front wall 29 towards the street, 26 high, doors 18).
local function optima(model: Instance)
	local site = (Config.YangonVenues and Config.YangonVenues.Sites or {}).customs
	if not site or not site.size or site.size >= 150 then
		return
	end
	local c = Vector3.new(site.x, site.y, site.z)
	local base = CFrame.lookAt(c, c + Vector3.new(site.fx, 0, site.fz).Unit)
	local half, wide = site.size / 2, site.w or site.size
	local W, Z0, H = math.min(wide / 2 - 8, 86), -half + 26, 26
	local look = Instance.new("Model")
	look.Name = "RealLookOptima"
	local function box(name: string, size: Vector3, x: number, y: number, z: number, color: Color3, material: Enum.Material?): Part
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.Size, p.CFrame, p.Color = name, true, size, base * CFrame.new(x, y, z), color
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CastShadow = false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = look
		return p
	end
	local GREY, RED, YELLOW = Color3.fromRGB(146, 150, 148), Color3.fromRGB(214, 44, 30), Color3.fromRGB(240, 170, 34)
	-- the old name band and the dark walls
	for _, d in model:GetDescendants() do
		if d:IsA("TextLabel") and string.find(string.upper(d.Text), "OPTIMA", 1, true) then
			local g = d:FindFirstAncestorWhichIsA("SurfaceGui")
			if g then
				g.Enabled = false
			end
		elseif d:IsA("BasePart") and d.Transparency < 0.2 and (d.Size.Y > 12 or (d.Size.Y > 3 and math.max(d.Size.X, d.Size.Z) > 30)) and d.Color.R < 0.26 and d.Color.G < 0.26 and d.Color.B < 0.28 then
			d.Color, d.Material = GREY, Enum.Material.Concrete
		elseif d:IsA("BasePart") and d.Name == "Forecourt" then
			d.Color, d.Material = Color3.fromRGB(176, 150, 118), Enum.Material.Pavement
		end
	end
	local full = W * 2 + 4
	box("GreyBand", Vector3.new(full, 6, 0.8), 0, 23.4, Z0 - 0.75, GREY, Enum.Material.Concrete)
	local fascia = box("Fascia", Vector3.new(full, 9.4, 1.2), 0, 31, Z0 - 0.95, RED)
	box("Canopy", Vector3.new(full + 3, 1.5, 5.4), 0, 19.3, Z0 - 3.2, YELLOW)
	box("CanopyLip", Vector3.new(full + 3, 0.5, 5.6), 0, 20.25, Z0 - 3.2, Color3.fromRGB(226, 150, 24))
	for _, x in { -W * 0.31, W * 0.31 } do
		box("Pillar", Vector3.new(2.2, 18.6, 1.3), x, 9.3, Z0 - 0.7, GREY, Enum.Material.Concrete)
	end
	for _, x in { -(W + 0.2), W + 0.2 } do
		box("Pillar", Vector3.new(3.8, 18.6, 1.3), x, 9.3, Z0 - 0.7, GREY, Enum.Material.Concrete)
	end
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 30, 1
	gui.Parent = fascia
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency, name.Size, name.Position = 1, UDim2.fromScale(0.62, 0.42), UDim2.fromScale(0.19, 0.1)
	name.Text, name.TextScaled, name.Font, name.TextColor3 = "OPTIMA WERKZ YANGON", true, Enum.Font.GothamBlack, Color3.fromRGB(250, 206, 60)
	name.Parent = gui
	local flag = Instance.new("Frame")
	flag.BackgroundTransparency, flag.Size, flag.Position = 1, UDim2.fromScale(0.16, 0.26), UDim2.fromScale(0.42, 0.6)
	flag.Rotation = -4
	flag.Parent = gui
	for i = 0, 7 do
		for j = 0, 2 do
			local sq = Instance.new("Frame")
			sq.BorderSizePixel, sq.Size, sq.Position = 0, UDim2.fromScale(1 / 8, 1 / 3), UDim2.fromScale(i / 8, j / 3)
			sq.BackgroundColor3 = if (i + j) % 2 == 0 then Color3.fromRGB(20, 20, 22) else Color3.fromRGB(245, 245, 245)
			sq.Parent = flag
		end
	end
	look.Parent = model
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
	local customs = city:FindFirstChild("LegendsCustoms", true)
	if customs and not customs:FindFirstChild("RealLookOptima") then
		optima(customs)
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
