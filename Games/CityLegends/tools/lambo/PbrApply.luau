--[[
	After the Import 3D: the real surfaces on a new import's parts, from tools/lambo/pbr/<car id>.json
	(Studio's importer leaves them out). Run in Studio's command bar or through MCP on the edit side,
	with the json served by a local http server: a script can't set these maps in a live game, so
	they are saved in ReplicatedStorage.CarModels.

	    local PbrApply = loadstring(source)()
	    PbrApply.run(car, HttpService:JSONDecode(HttpService:GetAsync(url)))

	A part's own texture stays its colour map. Parts named with Blender's .001 endings are matched
	without them. Steering wheel pieces are matched by size: cars with the same tilt in one pack share
	a name, so their endings shift.
]]

local PbrApply = {}

local function id(n: string?): string?
	return if n then "rbxassetid://" .. n else nil
end

function PbrApply.run(car: Instance, data: any): { applied: number, missing: { string } }
	local missing = {}
	local applied = 0
	for _, d in car:GetDescendants() do
		if not d:IsA("MeshPart") then
			continue
		end
		local e = data.parts[d.Name]
		if d.Name:sub(1, 13) == "SteeringWheel" then
			local size = { d.Size.X, d.Size.Y, d.Size.Z }
			table.sort(size)
			local best = math.huge
			for name, row in data.parts do
				if name:sub(1, 13) == "SteeringWheel" and row.dim then
					local gap = 0
					for i = 1, 3 do
						gap += math.abs(row.dim[i] - size[i])
					end
					if gap < best then
						best, e = gap, row
					end
				end
			end
		elseif not e then
			local base = d.Name:match("^(.-)%.%d%d%d$")
			e = if base then data.parts[base] else nil
		end
		if not e then
			if d.Name:sub(1, 10) ~= "Body_Paint" and d.Name:sub(1, 10) ~= "SeeThrough" then
				table.insert(missing, d.Name)
			end
			continue
		end
		local old = d:FindFirstChildOfClass("SurfaceAppearance")
		local color = d.TextureID
		if old and old.ColorMap ~= "" then
			color = old.ColorMap
		end
		if old then
			old:Destroy()
		end
		local sa = Instance.new("SurfaceAppearance")
		sa.Name = "Pbr"
		sa.ColorMap = if color ~= "" then color else (id(data.white) :: string)
		sa.RoughnessMap = id(e.r) :: string
		sa.MetalnessMap = id(e.m) :: string
		if e.n then
			sa.NormalMap = id(e.n) :: string
		end
		if color == "" then
			sa.Color = d.Color -- a plain part: its colour tints the white map
		end
		if e.tint then
			sa.Color = Color3.fromRGB(e.tint[1], e.tint[2], e.tint[3])
		end
		if e.two then
			d.DoubleSided = true
		end
		if e.e then
			sa.EmissiveMaskContent = Content.fromUri(id(data.white) :: string)
			sa.EmissiveStrength = e.g or 0.7
		end
		sa.Parent = d
		applied += 1
	end
	return { applied = applied, missing = missing }
end

return PbrApply
