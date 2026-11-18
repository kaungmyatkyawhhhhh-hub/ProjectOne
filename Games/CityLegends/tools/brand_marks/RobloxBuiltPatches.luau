--[[
	RobloxBuiltPatches (Studio, Edit; paste into the command bar or require a copy) 2026-11-19
	Covers the real makers' badges and lettering on the cars built in Roblox (not converted), whose
	badges are cut into big chrome / trim meshes, so BrandMarks' hide-by-name can't reach them.
	Each patch is a "MarkPatch" Part in the colour round the badge, saved in ReplicatedStorage.CarModels
	inside the group of the mesh it covers (it moves with the tailgate / wheel). CarSkin clones it like
	any other part (the name has no badge / logo word). Covers attribute = what it hides.
	Measured in Studio 2026-11-19 (vault: City Legends/2026-11-19 Badge removal - van and Regent Sport.md).
	cf = the patch's CFrame relative to the car model's pivot.
	  P.run()  -> removes old MarkPatch parts on these cars and lays them again; returns a report.
	The van's tailgate lettering (ALPHARD Executive Lounge) was its own part: deleted (backup in
	ServerStorage.BadgeRemovalBackup); BrandMarks.toyoka_alfard hides it if an old copy comes back.
]]

local P = {}

P.PATCHES = {
	{ car = "toyoka_alfard", covers = "grille emblem", parent = { "Body", "Model" }, cf = { 0.0000, -0.1192, -9.3496, 1.0000, 0.0000, 0.0000, 0.0000, 0.9968, -0.0797, 0.0000, 0.0797, 0.9968 }, size = { 0.5800, 0.4500, 0.0400 }, disc = false, color = { 17, 17, 17 }, refl = 0 },
	{ car = "toyoka_alfard", covers = "rear badge", parent = { "Misc", "TK" }, cf = { 0.0000, 0.8800, 9.0801, 0.0000, 0.0000, -1.0000, 0.0000, 1.0000, 0.0000, 1.0000, 0.0000, 0.0000 }, size = { 0.2000, 0.6400, 0.6400 }, disc = true, color = { 163, 161, 165 }, refl = 0.6 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "FL", "Parts", "OEM Alphard Rim" }, cf = { -3.2295, -2.3323, -6.0552, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "FR", "Parts", "OEM Alphard Rim" }, cf = { 3.2383, -2.3323, -6.0557, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "RL", "Parts", "OEM Alphard Rim" }, cf = { -3.2295, -2.3323, 5.2578, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "RR", "Parts", "OEM Alphard Rim" }, cf = { 3.2383, -2.3323, 5.2573, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_crown", covers = "rear badge", parent = { "Body", "Paint" }, cf = { -0.0049, 1.0070, 9.2529, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.5200, 0.3400, 0.0800 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "CROWN", parent = { "Body", "Paint" }, cf = { -2.0776, 0.9362, 8.9370, -0.9414, 0.0391, 0.3349, 0.0000, 0.9932, -0.1160, -0.3372, -0.1092, -0.9351 }, size = { 0.5600, 0.1700, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "ATHLETE G", parent = { "Body", "Paint" }, cf = { 2.0264, 0.9521, 8.9585, -0.9544, -0.0328, -0.2969, 0.0000, 0.9939, -0.1099, 0.2987, -0.1049, -0.9486 }, size = { 0.8200, 0.1900, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HSD", parent = { "Body", "Paint" }, cf = { 1.7520, -0.0679, 9.1421, -0.9762, 0.0671, 0.2063, 0.0000, 0.9509, -0.3094, -0.2169, -0.3021, -0.9283 }, size = { 0.3800, 0.1800, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HYBRID left", parent = { "Body", "Paint" }, cf = { -3.2896, 0.3918, -4.5005, 0.0407, 0.1803, 0.9828, 0.0000, 0.9836, -0.1805, -0.9992, 0.0073, 0.0400 }, size = { 0.6800, 0.1700, 0.0500 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HYBRID right", parent = { "Body", "Paint" }, cf = { 3.2896, 0.3918, -4.5005, 0.0407, -0.1803, -0.9828, 0.0000, 0.9836, -0.1805, 0.9992, 0.0073, 0.0400 }, size = { 0.6800, 0.1700, 0.0500 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "grille emblem", parent = { "Body", "Model" }, cf = { 0.0000, -0.3309, -9.3086, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.5000, 0.5000, 0.0800 }, disc = false, color = { 59, 59, 59 }, refl = 0.2 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "FL", "Parts" }, cf = { -3.3408, -1.4893, -5.9155, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "FR", "Parts" }, cf = { 3.3408, -1.4893, -5.9155, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "RL", "Parts" }, cf = { -3.3408, -1.4893, 4.8442, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "RR", "Parts" }, cf = { 3.3408, -1.4893, 4.8442, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
}

function P.run(): string
	local CM = game:GetService("ReplicatedStorage"):WaitForChild("CarModels")
	local report, cleared = {}, {}
	for _, s in P.PATCHES do
		local m = CM:FindFirstChild(s.car)
		if not m then
			table.insert(report, s.car .. ": missing")
			continue
		end
		if not cleared[s.car] then
			cleared[s.car] = true
			for _, d in m:GetDescendants() do
				if d.Name == "MarkPatch" then
					d:Destroy()
				end
			end
		end
		local g: Instance? = m
		for _, n in s.parent do
			g = g and g:FindFirstChild(n)
		end
		if not g then
			table.insert(report, s.car .. " " .. s.covers .. ": group missing")
			continue
		end
		local p = Instance.new("Part")
		p.Name = "MarkPatch"
		p:SetAttribute("Covers", s.covers)
		if s.disc then
			p.Shape = Enum.PartType.Cylinder -- axis along the part's X = out of the surface
		end
		p.Size = Vector3.new(s.size[1], s.size[2], s.size[3])
		p.CFrame = m:GetPivot() * CFrame.new(table.unpack(s.cf))
		p.Color = Color3.fromRGB(s.color[1], s.color[2], s.color[3])
		p.Reflectance = s.refl
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = g
		table.insert(report, s.car .. " " .. s.covers .. ": ok")
	end
	return table.concat(report, "\n")
end

return P
