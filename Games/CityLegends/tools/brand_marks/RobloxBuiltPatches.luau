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
	paint = true: the patch is named "MarkPatch_Paint", so Customs repaints it with the body (its SrcName says paint)
	and TrafficLOD marks it TrafficPaint. Anything named MarkPatch* is a patch (TrafficLOD keeps them all).
	P.PARTS (2026-11-19, Belta / Camry / Swift traffic + player cars): marks that are whole parts of their own, found
	by mesh or decal id: "delete" moves them to ServerStorage.BadgeRemovalBackup.<car>, "blank" takes the picture off
	(a plain plate). P.run does both after the patches.
]]

local P = {}

P.PATCHES = {
	{ car = "toyoka_alfard", covers = "grille emblem", parent = { "Body", "Model" }, cf = { 0.0000, -0.1192, -9.3496, 1.0000, 0.0000, 0.0000, 0.0000, 0.9968, -0.0797, 0.0000, 0.0797, 0.9968 }, size = { 0.5800, 0.4500, 0.0400 }, disc = false, color = { 17, 17, 17 }, refl = 0 },
	{ car = "toyoka_alfard", covers = "rear badge", parent = { "Misc", "TK" }, cf = { 0.0000, 0.8800, 9.0801, 0.0000, 0.0000, -1.0000, 0.0000, 1.0000, 0.0000, 1.0000, 0.0000, 0.0000 }, size = { 0.2000, 0.6400, 0.6400 }, disc = true, color = { 163, 161, 165 }, refl = 0.6 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "FL", "Parts", "OEM Alphard Rim" }, cf = { -3.2295, -2.3323, -6.0552, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "FR", "Parts", "OEM Alphard Rim" }, cf = { 3.2383, -2.3323, -6.0557, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "RL", "Parts", "OEM Alphard Rim" }, cf = { -3.2295, -2.3323, 5.2578, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_alfard", covers = "wheel cap", parent = { "Wheels", "RR", "Parts", "OEM Alphard Rim" }, cf = { 3.2383, -2.3323, 5.2573, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2800, 0.2800 }, disc = true, color = { 163, 162, 165 }, refl = 0.3 },
	{ car = "toyoka_crown", covers = "rear badge", paint = true, parent = { "Body", "Paint" }, cf = { -0.0049, 1.0070, 9.2529, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.5200, 0.3400, 0.0800 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "CROWN", paint = true, parent = { "Body", "Paint" }, cf = { -2.0776, 0.9362, 8.9370, -0.9414, 0.0391, 0.3349, 0.0000, 0.9932, -0.1160, -0.3372, -0.1092, -0.9351 }, size = { 0.5600, 0.1700, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "ATHLETE G", paint = true, parent = { "Body", "Paint" }, cf = { 2.0264, 0.9521, 8.9585, -0.9544, -0.0328, -0.2969, 0.0000, 0.9939, -0.1099, 0.2987, -0.1049, -0.9486 }, size = { 0.8200, 0.1900, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HSD", paint = true, parent = { "Body", "Paint" }, cf = { 1.7520, -0.0679, 9.1421, -0.9762, 0.0671, 0.2063, 0.0000, 0.9509, -0.3094, -0.2169, -0.3021, -0.9283 }, size = { 0.3800, 0.1800, 0.0600 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HYBRID left", paint = true, parent = { "Body", "Paint" }, cf = { -3.2896, 0.3918, -4.5005, 0.0407, 0.1803, 0.9828, 0.0000, 0.9836, -0.1805, -0.9992, 0.0073, 0.0400 }, size = { 0.6800, 0.1700, 0.0500 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "HYBRID right", paint = true, parent = { "Body", "Paint" }, cf = { 3.2896, 0.3918, -4.5005, 0.0407, -0.1803, -0.9828, 0.0000, 0.9836, -0.1805, 0.9992, 0.0073, 0.0400 }, size = { 0.6800, 0.1700, 0.0500 }, disc = false, color = { 248, 248, 248 }, refl = 0 },
	{ car = "toyoka_crown", covers = "grille emblem", parent = { "Body", "Model" }, cf = { 0.0000, -0.3309, -9.3086, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.5000, 0.5000, 0.0800 }, disc = false, color = { 59, 59, 59 }, refl = 0.2 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "FL", "Parts" }, cf = { -3.3408, -1.4893, -5.9155, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "FR", "Parts" }, cf = { 3.3408, -1.4893, -5.9155, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "RL", "Parts" }, cf = { -3.3408, -1.4893, 4.8442, -1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, -1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	{ car = "toyoka_crown", covers = "wheel cap", parent = { "Wheels", "RR", "Parts" }, cf = { 3.3408, -1.4893, 4.8442, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 0.0400, 0.2600, 0.2600 }, disc = true, color = { 196, 198, 202 }, refl = 0.5 },
	-- (2026-11-19) the Belta / Vios taxi: grille emblem inside the chrome bar mesh; TOYOTA / YARIS letters and the
	-- boot emblem inside the chrome / paint meshes (vault: City Legends/2026-11-19 Traffic badges - Belta*.jpg)
	{ car = "toyoka_belta", covers = "grille emblem", parent = { "Body", "Body", "Model", "Model", "Main Body" }, cf = { 0.0000, -0.6875, 9.6288, -1.0000, 0.0000, 0.0000, 0.0000, 0.9578, 0.2874, 0.0000, 0.2874, -0.9578 }, size = { 1.0500, 0.7200, 0.1000 }, disc = false, color = { 226, 226, 228 }, refl = 0.25 },
	{ car = "toyoka_belta", covers = "rear emblem", paint = true, parent = { "Body", "Body", "Model", "Model", "Main Body" }, cf = { 0.0000, 0.6951, -9.5496, 1.0000, 0.0000, 0.0000, 0.0000, 0.9806, -0.1960, 0.0000, 0.1960, 0.9806 }, size = { 0.6200, 0.4200, 0.1000 }, disc = false, color = { 239, 184, 56 }, refl = 0 },
	{ car = "toyoka_belta", covers = "TOYOTA", paint = true, parent = { "Body", "Body", "Model", "Model", "Main Body" }, cf = { 1.6538, 0.5950, -9.3792, 0.9806, -0.0377, -0.1924, 0.0000, 0.9813, -0.1924, 0.1961, 0.1886, 0.9623 }, size = { 0.8500, 0.2600, 0.1000 }, disc = false, color = { 239, 184, 56 }, refl = 0 },
	{ car = "toyoka_belta", covers = "YARIS", paint = true, parent = { "Body", "Body", "Model", "Model", "Main Body" }, cf = { -1.6739, 0.5950, -9.3792, 0.9806, 0.0377, 0.1924, 0.0000, 0.9813, -0.1924, -0.1961, 0.1886, 0.9623 }, size = { 0.8000, 0.2600, 0.1000 }, disc = false, color = { 239, 184, 56 }, refl = 0 },
	-- (2026-11-19) the Land Cruiser 200: grille emblem in the chrome mesh's picture, boot emblem / VX.R / V8 5.7 in the
	-- body paint's picture
	{ car = "toyoka_lc200", covers = "grille emblem", parent = { "Body", "Black" }, cf = { 0.0000, -0.0725, -10.8600, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000, 0.0000, 0.0000, 0.0000, 1.0000 }, size = { 1.3500, 0.9200, 0.0800 }, disc = false, color = { 30, 30, 32 }, refl = 0 },
	{ car = "toyoka_lc200", covers = "rear emblem", paint = true, parent = { "Body", "Color" }, cf = { 0.0000, 1.0781, 10.5650, -1.0000, 0.0000, -0.0000, 0.0000, 0.9987, -0.0500, 0.0000, -0.0500, -0.9987 }, size = { 0.9500, 0.6500, 0.0800 }, disc = false, color = { 178, 176, 180 }, refl = 0 },
	{ car = "toyoka_lc200", covers = "VX.R", paint = true, parent = { "Body", "Color" }, cf = { -2.6722, -0.0483, 10.5242, -0.9879, 0.0441, 0.1487, 0.0000, 0.9588, -0.2842, -0.1551, -0.2807, -0.9472 }, size = { 0.9000, 0.3000, 0.0800 }, disc = false, color = { 178, 176, 180 }, refl = 0 },
	{ car = "toyoka_lc200", covers = "V8 5.7", paint = true, parent = { "Body", "Color" }, cf = { 2.5202, -0.0200, 10.5348, -0.9999, -0.0023, -0.0128, 0.0000, 0.9842, -0.1772, 0.0130, -0.1772, -0.9841 }, size = { 0.8500, 0.3000, 0.0800 }, disc = false, color = { 178, 176, 180 }, refl = 0 },
}

P.PARTS = {
	{ car = "toyoka_camri", covers = "boot emblem + CAMRY + XSE (one mesh)", mesh = "1718586509", action = "delete" },
	{ car = "toyoka_camri", covers = "grille emblem", mesh = "1718475247", action = "delete" },
	{ car = "suzaki_swift", covers = "S badges (front, back)", decal = "1324215539", action = "delete" },
	{ car = "suzaki_swift", covers = "SWIFT name plates (front, back)", texture = "1324231466", action = "blank", color = { 236, 236, 232 } },
}

local function partMatches(d: Instance, s: any): boolean
	if not d:IsA("BasePart") then
		return false
	end
	if s.mesh then
		return d:IsA("MeshPart") and string.find(d.MeshId, s.mesh, 1, true) ~= nil
	elseif s.texture then
		return d:IsA("MeshPart") and string.find(d.TextureID, s.texture, 1, true) ~= nil
	elseif s.decal then
		for _, c in d:GetChildren() do
			if c:IsA("Decal") and string.find(c.Texture, s.decal, 1, true) then
				return true
			end
		end
	end
	return false
end

function P.runParts(): { string }
	local CM = game:GetService("ReplicatedStorage"):WaitForChild("CarModels")
	local SS = game:GetService("ServerStorage")
	local report = {}
	for _, s in P.PARTS do
		local m = CM:FindFirstChild(s.car)
		if not m then
			table.insert(report, s.car .. ": missing")
			continue
		end
		local n = 0
		for _, d in m:GetDescendants() do
			if partMatches(d, s) then
				n += 1
				if s.action == "delete" then
					local bk = SS:FindFirstChild("BadgeRemovalBackup") or Instance.new("Folder")
					bk.Name = "BadgeRemovalBackup"
					bk.Parent = SS
					local f = bk:FindFirstChild(s.car) or Instance.new("Folder")
					f.Name = s.car
					f.Parent = bk
					local c = d:Clone()
					c:SetAttribute("WasAt", d:GetFullName())
					c.Parent = f
					d:Destroy()
				else
					local mp = d :: MeshPart
					mp.TextureID = ""
					mp.Color = Color3.fromRGB(s.color[1], s.color[2], s.color[3])
					mp.Material = Enum.Material.SmoothPlastic
				end
			end
		end
		table.insert(report, string.format("%s %s: %s %d", s.car, s.covers, s.action, n))
	end
	return report
end

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
				if string.sub(d.Name, 1, 9) == "MarkPatch" then
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
		p.Name = if s.paint then "MarkPatch_Paint" else "MarkPatch"
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
	for _, line in P.runParts() do
		table.insert(report, line)
	end
	return table.concat(report, "\n")
end

return P
