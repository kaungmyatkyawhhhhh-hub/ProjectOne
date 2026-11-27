--[[
	YangonRoadSurface (Studio, Edit; ServerStorage.ClaudeTools pattern; 27 Nov 2026, owner: "the road textures dont look
	realistic ... not every small road is asphalt, the big roads & overhead roads are always asphalt"; vault
	`City Legends/2026-11-27 Roads - realistic surfaces by road type.md`).

	Road surface kinds from tools/road_surface/road_surface_split.py (R big asphalt + decks, RP patches, RT tar seams,
	RC small-street concrete, RA small-street asphalt, RU unpaved) replace the old RMeshR meshes of
	Workspace.Yangon1to1.Roads.Meshes.Cell_<cell>. Maps from road_textures.py (ids tools/road_surface/ids.json).

	local S = require(game.ServerStorage.ClaudeTools.YangonRoadSurface:Clone())
	S.variants()                 -> makes / updates MaterialVariants YgnRoadAsphalt, YgnRoadConcrete in MaterialService
	S.place(holding, rows)       -> new meshes from an inserted glb Model (holding) into each Cell_<cell> as RMesh<kind>
	                                (anchored, no collide / query / touch / shadow, as YangonRoadMeshes); the old RMeshR
	                                parts listed by cell in rows ({cell = true}) go to ServerStorage.RoadSurfaceOld
	S.look()                     -> LOOK on every RMeshR / RP / RT / RC / RA / RU in the map (re-run after a colour tune)
	S.undo()                     -> new meshes out, the old RMeshR back
]]

local MS = game:GetService("MaterialService")
local SS = game:GetService("ServerStorage")

local S = {}

S.IDS = {
	YgnRoadAsphalt = { color = 106420386734912, normal = 118937246156752, roughness = 119840276812247, base = Enum.Material.Asphalt, spt = 24 },
	YgnRoadConcrete = { color = 91186461247844, normal = 111294739232406, roughness = 74085596867182, base = Enum.Material.Concrete, spt = 32 },
}

-- kind -> { base material, variant, colour } (the maps are neutral grey: the colour sets the shade)
S.LOOK = {
	R = { Enum.Material.Asphalt, "YgnRoadAsphalt", Color3.fromRGB(150, 150, 152) },
	RP = { Enum.Material.Asphalt, "YgnRoadAsphalt", Color3.fromRGB(112, 112, 116) },
	RT = { Enum.Material.Asphalt, "YgnRoadAsphalt", Color3.fromRGB(62, 62, 66) },
	RA = { Enum.Material.Asphalt, "YgnRoadAsphalt", Color3.fromRGB(170, 168, 164) },
	RC = { Enum.Material.Concrete, "YgnRoadConcrete", Color3.fromRGB(205, 203, 196) },
	RU = { Enum.Material.Pebble, "YgnGravel", Color3.fromRGB(176, 160, 136) },
}

function S.variants()
	for name, d in S.IDS do
		local v = MS:FindFirstChild(name) or Instance.new("MaterialVariant")
		v.Name = name
		v.BaseMaterial = d.base
		v.ColorMap = "rbxassetid://" .. d.color
		v.NormalMap = "rbxassetid://" .. d.normal
		v.RoughnessMap = "rbxassetid://" .. d.roughness
		v.StudsPerTile = d.spt
		v.Parent = MS
	end
	return "variants ok"
end

local function root()
	return workspace.Yangon1to1.Roads.Meshes
end

local function style(p: BasePart, kind: string)
	local L = S.LOOK[kind]
	p.Material = L[1]
	p.MaterialVariant = L[2]
	p.Color = L[3]
end

function S.look()
	local n = 0
	for _, p in root():GetDescendants() do
		if p:IsA("MeshPart") then
			local kind = string.match(p.Name, "^RMesh(%u+)$")
			if kind and S.LOOK[kind] then
				style(p, kind)
				n += 1
			end
		end
	end
	return n
end

local function parse(name: string)
	local kind, id, cx, cy, cz =
		string.match(name, "^(%u+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_")
	if not kind then
		return nil
	end
	local function num(s)
		return string.sub(s, 1, 1) == "n" and -tonumber(string.sub(s, 2)) / 100 or tonumber(s) / 100
	end
	return kind, string.match(id, "^(.-)s%d+$") or id, Vector3.new(num(cx), num(cy), num(cz))
end

function S.place(holding: Instance, cells: { [string]: boolean })
	local old = SS:FindFirstChild("RoadSurfaceOld") or Instance.new("Folder")
	old.Name = "RoadSurfaceOld"
	old.Parent = SS
	local placed, moved = 0, 0
	for cell in cells do
		local c = root():FindFirstChild("Cell_" .. cell)
		if c then
			for _, p in c:GetChildren() do
				if p.Name == "RMeshR" and not p:GetAttribute("RSurf") then
					p:SetAttribute("OldCell", cell)
					p.Parent = old
					moved += 1
				end
			end
		end
	end
	for i, m in holding:GetDescendants() do
		if m:IsA("MeshPart") then
			local kind, cell, centre = parse(m.Name)
			local cm = kind and root():FindFirstChild("Cell_" .. cell)
			if cm and S.LOOK[kind] then
				local p = m:Clone()
				p.Name = "RMesh" .. kind
				p.CFrame = CFrame.new(centre)
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.CastShadow = false
				p.DoubleSided = false
				p:SetAttribute("RSurf", true)
				style(p, kind)
				p.Parent = cm
				placed += 1
			end
		end
		if i % 200 == 0 then
			task.wait()
		end
	end
	return placed .. " placed, " .. moved .. " old R meshes moved out"
end

function S.undo()
	local n = 0
	for _, p in root():GetDescendants() do
		if p:IsA("MeshPart") and p:GetAttribute("RSurf") then
			p:Destroy()
			n += 1
		end
	end
	local old = SS:FindFirstChild("RoadSurfaceOld")
	if old then
		for _, p in old:GetChildren() do
			p.Parent = root():FindFirstChild("Cell_" .. p:GetAttribute("OldCell"))
		end
	end
	return n .. " removed"
end

return S
