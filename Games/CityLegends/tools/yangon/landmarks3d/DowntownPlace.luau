--[[
	DowntownPlace (Studio, Edit; 2026-11-16, step 6): places a downtown (P3) landmark made by
	tools/yangon/landmarks3d/dt_landmarks.py: the .glb Model (MeshParts named LOOK_<id>s<k>_cx_cy_cz_sx_sy_sz in world
	hundredths of a stud, "n" = minus) and its place.json (looks, collision boxes) as a StringValue.

	local D = require(ServerStorage.ClaudeTools.DowntownPlace:Clone())
	D.place(holding, placeJson, folder)   -> Model folder[<id>]: MeshParts with their look (Material, Color,
	                                         Transparency, Reflectance, MaterialVariant, CastShadow; night panes tagged
	                                         FacadeNight), invisible collision boxes; visual parts CollisionFidelity Box,
	                                         CanCollide / CanQuery / CanTouch off
]]
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local D = {}

local function num(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function D.parse(name: string)
	local look, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+%d*)_%w+_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not look then
		return nil
	end
	return look, Vector3.new(num(cx), num(cy), num(cz)), Vector3.new(num(sx), num(sy), num(sz))
end

function D.place(holding: Instance, placeJson: string, folder: Instance): number
	local data = HttpService:JSONDecode(placeJson)
	local old = folder:FindFirstChild(data.id)
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = data.id
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local vis = Instance.new("Model")
	vis.Name = "Visual"
	vis.Parent = model
	local col = Instance.new("Model")
	col.Name = "Collision"
	col.Parent = model
	local n = 0
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local look, c, size = D.parse(d.Name)
			if not look and d.Parent then
				look, c, size = D.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			local spec = look and data.looks[look]
			if spec then
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = look
				q.Size = size
				q.CFrame = CFrame.new(c)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.TextureID = ""
				q.Material = Enum.Material[spec[1]]
				q.Color = Color3.fromRGB(spec[2][1], spec[2][2], spec[2][3])
				q.Transparency = spec[3]
				q.Reflectance = spec[4]
				if spec[5] then
					q.MaterialVariant = spec[5]
				end
				q.CastShadow = spec[6]
				if spec[7] == "night" then
					q.Transparency = 1
					CollectionService:AddTag(q, "FacadeNight")
				end
				q.Parent = vis
				pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
					-- big flat pieces (the monument's paving) lost their faces at Automatic: few parts, so Precise
					q.RenderFidelity = Enum.RenderFidelity.Precise
				end)
				n += 1
			end
		end
	end
	for _, b in data.collide do
		local p = Instance.new("Part")
		p.Name = "Box"
		p.Anchored = true
		p.Transparency = 1
		p.CanTouch = false
		p.CastShadow = false
		p.Size = Vector3.new(b[4], b[5], b[6])
		p.CFrame = CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0)
		p.Parent = col
	end
	-- walkable interiors: the smooth terrain (and its grass bulge) is cleared out of these boxes (same form as collide)
	for _, b in data.clear or {} do
		workspace.Terrain:FillBlock(CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0), Vector3.new(b[4], b[5], b[6]),
			Enum.Material.Air)
	end
	-- warm PointLights (interiors: data.lights = { {x, y, z, range, brightness} })
	for _, l in data.lights or {} do
		local p = Instance.new("Part")
		p.Name = "Light"
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = Vector3.new(0.4, 0.4, 0.4)
		p.Position = Vector3.new(l[1], l[2], l[3])
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 226, 180)
		pl.Range = l[4]
		pl.Brightness = l[5]
		pl.Shadows = false
		pl.Parent = p
		p.Parent = vis
	end
	model.Parent = folder
	return n
end

return D
