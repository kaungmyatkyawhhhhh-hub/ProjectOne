--[[
Copies cars the owner brought in with Studio's Import 3D (a tools/pack_cars.py .fbx, saved in their
place) into assets/CarModels.rbxm, replacing the old models of the same car ids.

	lune run tools/take_cars.luau <place .rbxl, Tags chunks stripped> [--colours <dir>] <car id> [<car id> ...]

  * a converted car (it has a SteeringWheel_t<tilt> part) wins over an older model of the same id
  * Blender's ".001" name endings come off (Wheels.001 -> Wheels, FL.001 -> FL)
  * windows (SeeThrough_*) are made double-sided
  * with --colours: a part that came in with no texture (Studio drops plain colours) gets its
    colour from <dir>/<car id>.colours.json (part name -> sRGB 0..1), written from the converted
    .blend files
Run it from Games/CityLegends.
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local serde = require("@lune/serde")

local placePath = process.args[1]
local wanted: { [string]: boolean } = {}
local colourDir: string? = nil
local i = 2
while i <= #process.args do
	if process.args[i] == "--colours" then
		colourDir = process.args[i + 1]
		i += 2
	else
		wanted[process.args[i]] = true
		i += 1
	end
end

local game = roblox.deserializePlace(fs.readFile(placePath))
local assetsPath = "assets/CarModels.rbxm"
local folder = roblox.deserializeModel(fs.readFile(assetsPath))[1]

-- one of our converted cars has a "SteeringWheel_t<tilt>" part; it wins over an older model of
-- the same id, and so does a copy inside an imported group over one straight in CarModels
local function rank(m: Instance): number
	local r = if m.Parent ~= nil and m.Parent.Name ~= "CarModels" then 1 else 0
	for _, d in m:GetDescendants() do
		if d.Name:match("^SteeringWheel_t%d+") then
			return r + 2
		end
	end
	return r
end
local found = {}
for _, d in game:GetDescendants() do
	if d:IsA("Model") and wanted[d.Name] then
		if not found[d.Name] or rank(d) > rank(found[d.Name]) then
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
	local colours = {}
	if colourDir and fs.isFile(colourDir .. "/" .. id .. ".colours.json") then
		colours = serde.decode("json", fs.readFile(colourDir .. "/" .. id .. ".colours.json"))
	end
	local parts, recoloured = 0, 0
	for _, d in copy:GetDescendants() do
		if d:IsA("MeshPart") and not d:FindFirstChildOfClass("SurfaceAppearance") and tostring(d.TextureContent):find("None") then
			local c = colours[d.Name] or colours[(d.Name:gsub("%.%d+$", ""))]
			if c then
				d.Color = roblox.Color3.new(c[1], c[2], c[3])
				recoloured += 1
			end
		end
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
	print(if old then "replaced" else "added", id, parts, "parts", recoloured, "recoloured")
end

fs.writeFile(assetsPath, roblox.serializeModel({ folder }))
print("models now:", #folder:GetChildren())
