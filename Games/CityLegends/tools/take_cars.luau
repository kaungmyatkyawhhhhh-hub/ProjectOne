--[[
Copies cars the owner brought in with Studio's Import 3D (a tools/pack_cars.py .fbx, saved in their
place) into assets/CarModels.rbxm, replacing the old models of the same car ids.

	lune run tools/take_cars.luau <place .rbxl, Tags chunks stripped> <car id> [<car id> ...]

  * a copy inside an imported group wins over one sitting straight in CarModels (the old one)
  * Blender's ".001" name endings come off (Wheels.001 -> Wheels, FL.001 -> FL)
  * windows (SeeThrough_*) are made double-sided
Run it from Games/CityLegends.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1]
local wanted: { [string]: boolean } = {}
for i = 2, #process.args do
	wanted[process.args[i]] = true
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local assetsPath = "assets/CarModels.rbxm"
local folder = roblox.deserializeModel(fs.readFile(assetsPath))[1]

local found = {}
for _, d in game:GetDescendants() do
	if d:IsA("Model") and wanted[d.Name] then
		local imported = d.Parent ~= nil and d.Parent.Name ~= "CarModels"
		if not found[d.Name] or imported then
			found[d.Name] = d
		end
	end
end

for id in wanted do
	local m = found[id]
	if not m then
		print("not in the place:", id)
		continue
	end
	local copy = m:Clone()
	local parts = 0
	for _, d in copy:GetDescendants() do
		d.Name = (d.Name:gsub("%.%d+$", ""))
		if d:IsA("MeshPart") then
			parts += 1
			if d.Name:sub(1, 11) == "SeeThrough_" then
				d.DoubleSided = true
			end
		end
	end
	local old = folder:FindFirstChild(id)
	if old then
		old.Parent = nil
	end
	copy.Parent = folder
	print(if old then "replaced" else "added", id, parts, "parts")
end

fs.writeFile(assetsPath, roblox.serializeModel({ folder }))
print("models now:", #folder:GetChildren())
