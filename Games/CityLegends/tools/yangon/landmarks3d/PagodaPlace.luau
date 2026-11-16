--!nocheck
-- PagodaPlace.luau (2026-11-16): places a 1:1 pagoda landmark (sule3d.py / bota3d.py) in Studio.
-- Use from execute_luau: local P = loadstring(<this file>)() is not available, so the caller pastes this file's body
-- as a function and calls P.place(holding, root, name, data) where data = build/landmarks/<x>/place.json (decoded).
--
-- Mesh names: "<GRP>_<id>_<cx>_<cy>_<cz>_<sx>_<sy>_<sz>" (hundredths of a stud, "n" = minus). id "T<template><k>" =
-- a template mesh (centre in LOCAL studs), cloned per instance in data.places {name, x, y, z, yaw}; anything else is
-- placed at its world centre. The glb was written x/z negated so it lands straight: keep the rotation it came in with.
local P = {}

P.LOOK = {
	GLD = { "Metal", { 255, 187, 84 }, 0, 0, false, true, "" },   -- v2 look pass: plain Metal (the leaf texture read blotchy)
	GWF = { "Metal", { 255, 187, 84 }, 0.45, 0, true, false, "" },
	GWR = { "Metal", { 255, 187, 84 }, 0, 0, true, true, "" },
	GLT = { "Foil", { 230, 160, 50 }, 0, 0.1, false, true, "" },          -- gilded trim / frames (reads as crinkled leaf)
	GLC = { "Metal", { 255, 206, 130 }, 0, 0, false, false, "YgnGoldPlate" }, -- embossed gold panel tiles (corridor)
	SG5 = { "SmoothPlastic", { 246, 244, 236 }, 0, 0, false, true, "" },
	SG6 = { "SmoothPlastic", { 226, 112, 34 }, 0, 0, false, true, "" },
	AW1 = { "SmoothPlastic", { 44, 92, 168 }, 0, 0, true, true, "" },
	AW2 = { "SmoothPlastic", { 40, 120, 84 }, 0, 0, true, true, "" },
	AW3 = { "SmoothPlastic", { 190, 52, 44 }, 0, 0, true, true, "" },
	SHT = { "Metal", { 168, 168, 166 }, 0, 0, false, true, "YgnCorrugatedZinc" },
	WD1 = { "Wood", { 176, 92, 40 }, 0, 0.05, false, false, "" },
	WD2 = { "Wood", { 146, 72, 30 }, 0, 0.05, false, false, "" },
	WHT = { "SmoothPlastic", { 255, 255, 250 }, 0, 0, false, true, "" },
	CRM = { "SmoothPlastic", { 236, 219, 148 }, 0, 0, false, true, "" },
	MAR = { "SmoothPlastic", { 236, 234, 228 }, 0, 0.03, false, false, "" },
	PAV = { "SmoothPlastic", { 178, 176, 170 }, 0, 0, false, false, "" },
	DRK = { "SmoothPlastic", { 52, 44, 38 }, 0, 0, false, false, "" },
	SG1 = { "SmoothPlastic", { 186, 40, 36 }, 0, 0, false, true, "" },
	SG2 = { "SmoothPlastic", { 34, 76, 156 }, 0, 0, false, true, "" },
	SG3 = { "SmoothPlastic", { 236, 186, 36 }, 0, 0, false, true, "" },
	SG4 = { "SmoothPlastic", { 34, 124, 74 }, 0, 0, false, true, "" },
	BLU = { "SmoothPlastic", { 44, 116, 196 }, 0, 0, false, true, "" },
	GLW = { "Glass", { 120, 132, 134 }, 0, 0.2, false, true, "" },
	ROF = { "SmoothPlastic", { 196, 196, 190 }, 0, 0, false, false, "" },
	TEL = { "SmoothPlastic", { 156, 206, 176 }, 0, 0, false, false, "" },
	GRN = { "SmoothPlastic", { 58, 112, 84 }, 0, 0, false, true, "" },
	RRF = { "SmoothPlastic", { 96, 42, 32 }, 0, 0, false, true, "" },
	RWD = { "SmoothPlastic", { 112, 40, 36 }, 0, 0, false, true, "" },
	YRL = { "SmoothPlastic", { 238, 204, 40 }, 0.25, 0, true, false, "" },
	WAT = { "Glass", { 62, 96, 58 }, 0.1, 0.1, false, false, "" },
	WOD = { "WoodPlanks", { 150, 78, 38 }, 0, 0.05, false, false, "" },
	STL = { "Metal", { 150, 150, 152 }, 0, 0, false, true, "" },
	CON = { "SmoothPlastic", { 168, 166, 158 }, 0, 0, false, true, "" },
	RED = { "SmoothPlastic", { 180, 36, 36 }, 0, 0, false, true, "" },
	GLS = { "Glass", { 196, 214, 222 }, 0.6, 0.1, true, false, "" },
	FNC = { "DiamondPlate", { 214, 176, 70 }, 0.35, 0, true, false, "" },
	MOS = { "Foil", { 150, 160, 140 }, 0, 0.2, false, false, "" },
	ZNC = { "Metal", { 70, 120, 140 }, 0, 0, false, true, "YgnCorrugatedZinc" },
}

local function num(s)
	if s:sub(1, 1) == "n" then
		return -tonumber(s:sub(2)) / 100
	end
	return tonumber(s) / 100
end

local function parse(name)
	local t = string.split(name, "_")
	if #t < 8 then
		return nil
	end
	local n = #t
	return t[1], t[2], Vector3.new(num(t[n - 5]), num(t[n - 4]), num(t[n - 3]))
end

local function look(part, grp)
	local L = P.LOOK[grp]
	if not L then
		return
	end
	part.Material = Enum.Material[L[1]]
	part.Color = Color3.fromRGB(L[2][1], L[2][2], L[2][3])
	part.Transparency = L[3]
	part.Reflectance = L[4]
	pcall(function()
		part.DoubleSided = L[5]
	end)
	part.CastShadow = L[6]
	part.MaterialVariant = L[7]
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part:SetAttribute("Group", grp)
end

-- holding: the LoadAsset model; root: the Landmarks.<Name> model (made here)
function P.place(holding, parent, name, data)
	local root = parent:FindFirstChild(name)
	if root then
		root:Destroy()
	end
	root = Instance.new("Model")
	root.Name = name
	local visual = Instance.new("Folder")
	visual.Name = "Visual"
	visual.Parent = root
	local coll = Instance.new("Folder")
	coll.Name = "Collision"
	coll.Parent = root
	local tpls = {}
	local nWorld, nInst = 0, 0
	for _, d in ipairs(holding:GetDescendants()) do
		if d:IsA("MeshPart") then
			local grp, id, c = parse(d.Name)
			if grp then
				if id:sub(1, 1) == "T" then
					local tname = id:sub(2):gsub("%d+$", "")
					tpls[tname] = tpls[tname] or {}
					table.insert(tpls[tname], { part = d, grp = grp, c = c, rot = d.CFrame.Rotation })
				else
					local p = d:Clone()
					for _, ch in ipairs(p:GetChildren()) do
						ch:Destroy()
					end
					p.CFrame = CFrame.new(c) * d.CFrame.Rotation
					p.Name = grp .. "_" .. id
					look(p, grp)
					p.Parent = visual
					nWorld += 1
				end
			end
		end
	end
	for i, pl in ipairs(data.places) do
		local list = tpls[pl[1]]
		if list then
			local m = Instance.new("Model")
			m.Name = pl[1] .. "_" .. i
			local base = CFrame.new(pl[2], pl[3], pl[4]) * CFrame.Angles(0, pl[5], 0)
			for _, t in ipairs(list) do
				local p = t.part:Clone()
				for _, ch in ipairs(p:GetChildren()) do
					ch:Destroy()
				end
				p.CFrame = base * CFrame.new(t.c) * t.rot
				p.Name = t.grp
				look(p, t.grp)
				p.Parent = m
				nInst += 1
			end
			m.Parent = visual
		end
	end
	local nColl = 0
	for _, c in ipairs(data.coll) do
		local p
		if c[1] == "W" then
			p = Instance.new("WedgePart")
		else
			p = Instance.new("Part")
		end
		p.Size = Vector3.new(c[5], c[6], c[7])
		-- yaw: plan angle CCW from east; Roblox: CFrame.Angles(0, yaw, 0) turns local +X the same way (Z = -north)
		p.CFrame = CFrame.new(c[2], c[3], c[4]) * CFrame.Angles(0, c[8], 0)
		if c[1] == "C" then
			-- vertical cylinder: Size (height, d, d), axis turned from X to Y
			p.Shape = Enum.PartType.Cylinder
			p.CFrame = CFrame.new(c[2], c[3], c[4]) * CFrame.Angles(0, 0, math.pi / 2)
		end
		if c[1] == "W" then
			-- ramp along local X rising toward -X (inward, to the platform): a WedgePart rises toward +Z,
			-- so turn it so its +Z points along local -X, and swap the sizes
			p.Size = Vector3.new(c[7], c[6], c[5])
			p.CFrame = p.CFrame * CFrame.Angles(0, -math.pi / 2, 0)
		end
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = true
		p.CastShadow = false
		p.Name = c[1] == "W" and "Ramp" or (c[1] == "C" and "Drum" or "Block")
		p.Parent = coll
		nColl += 1
	end
	for i, l in ipairs(data.lights or {}) do
		local a = Instance.new("Part")
		a.Name = "Light" .. i
		a.Size = Vector3.new(0.2, 0.2, 0.2)
		a.Transparency = 1
		a.Anchored = true
		a.CanCollide = false
		a.CanQuery = false
		a.CanTouch = false
		a.CFrame = CFrame.new(l[1], l[2], l[3])
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 206, 140)
		pl.Range = l[4]
		pl.Brightness = l[5]
		pl.Shadows = false
		pl.Parent = a
		a.Parent = root
	end
	root.Parent = parent
	return nWorld, nInst, nColl
end

-- set CollisionFidelity after parenting (a clone's setting doesn't stick unparented), a few per frame
function P.fidelity(root)
	local n = 0
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("MeshPart") then
			pcall(function()
				d.CollisionFidelity = Enum.CollisionFidelity.Box
			end)
			n += 1
			if n % 20 == 0 then
				task.wait()
			end
		end
	end
	return n
end

function P.plate(parent, pl, material, color)
	local old = parent:FindFirstChild(pl.name)
	if old then
		old:Destroy()
	end
	local p = Instance.new("Part")
	p.Name = pl.name
	p.Anchored = true
	p.Size = Vector3.new(pl.sx, 6, pl.sz)
	p.CFrame = CFrame.new(pl.cx, pl.top - 3, pl.cz)
	p.Material = material or Enum.Material.Concrete
	p.Color = color or Color3.fromRGB(120, 120, 116)
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

return P
