--[[
	YccPlace (Studio, Edit; 2026-11-17): places the Yangon Convention Centre + GG Gaming Fest dressing made by
	tools/yangon/landmarks3d/ycc_ggfest.py into Workspace.Yangon1to1.Landmarks.YangonConventionCentre.

	local Y = require(ServerStorage.ClaudeTools.YccPlace:Clone())
	Y.place(placeJson, assetId)   -- run it in task.spawn: LoadAsset + terrain take a few seconds

	place.json: looks (Material, rgb, transparency, reflectance, variant, shadow, night), collide (boxes
	[x, y, z, sx, sy, sz, yaw, pitch?]), signs (SurfaceGui TextLabel "Text" on an invisible part; tag GGFestScreen =
	written by server/GGFest.lua), lights, fill (terrain Ground under the floor / forecourt), clear (terrain Air above).
	The meshes are named LOOK_<tag>s<k>_cx_cy_cz_sx_sy_sz (hundredths of a stud, "n" = minus), world positions.
]]
local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")

local Y = {}

local function num(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

local function parse(name: string)
	local look, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+%d*)_%w+_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not look then
		return nil
	end
	return look, Vector3.new(num(cx), num(cy), num(cz)), Vector3.new(num(sx), num(sy), num(sz))
end

function Y.place(placeJson: string, assetId: number): string
	local data = HttpService:JSONDecode(placeJson)
	local hold = Instance.new("Folder")
	hold.Name = "YccHolding"
	hold.Parent = game:GetService("ServerStorage")
	InsertService:LoadAsset(assetId).Parent = hold
	local L = workspace.Yangon1to1.Landmarks
	local old = L:FindFirstChild("YangonConventionCentre")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "YangonConventionCentre"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local vis = Instance.new("Model")
	vis.Name = "Visual"
	vis.Parent = model
	local col = Instance.new("Model")
	col.Name = "Collision"
	col.Parent = model
	local sg = Instance.new("Model")
	sg.Name = "Signs"
	sg.Parent = model
	local n = 0
	for _, d in hold:GetDescendants() do
		if d:IsA("MeshPart") then
			local look, c, size = parse(d.Name)
			if not look and d.Parent then
				look, c, size = parse((string.gsub(d.Parent.Name, "_Node$", "")))
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
				q.Parent = vis
				pcall(function()
					q.CollisionFidelity = Enum.CollisionFidelity.Box
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
		p.CFrame = CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0) * CFrame.Angles(0, 0, -(b[8] or 0))
		p.Parent = col
	end
	for _, s in data.signs do
		local nrm = Vector3.new(s.n[1], 0, s.n[2])
		local c = Vector3.new(s.p[1], s.p[2] + s.h / 2, s.p[3])
		local p = Instance.new("Part")
		p.Name = s.name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(s.w, s.h, 0.05)
		p.CFrame = CFrame.lookAt(c, c + nrm)
		local g = Instance.new("SurfaceGui")
		g.Face = Enum.NormalId.Front
		g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		g.PixelsPerStud = if s.w > 40 then 10 else 20
		g.LightInfluence = 0
		g.MaxDistance = 700
		local t = Instance.new("TextLabel")
		t.Name = "Text"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = if s.bg then 0 else 1
		if s.bg then
			t.BackgroundColor3 = Color3.fromRGB(s.bg[1], s.bg[2], s.bg[3])
		end
		t.Font = Enum.Font[s.font]
		t.TextScaled = true
		t.TextWrapped = true
		t.Text = s.text
		t.TextColor3 = Color3.fromRGB(s.fg[1], s.fg[2], s.fg[3])
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0.06, 0)
		pad.PaddingRight = UDim.new(0.06, 0)
		pad.PaddingTop = UDim.new(0.08, 0)
		pad.PaddingBottom = UDim.new(0.08, 0)
		pad.Parent = t
		t.Parent = g
		g.Parent = p
		p.Parent = sg
		if s.tag then
			CollectionService:AddTag(p, s.tag)
		end
	end
	for _, l in data.lights do
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
		pl.Color = Color3.fromRGB(255, 244, 228)
		pl.Range = l[4]
		pl.Brightness = l[5]
		pl.Shadows = false
		pl.Parent = p
		p.Parent = vis
	end
	-- terrain: Ground well under the floor and forecourt (smooth terrain bulges ~2 studs), then Air above it
	for _, b in data.fill do
		workspace.Terrain:FillBlock(CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0), Vector3.new(b[4], b[5], b[6]), Enum.Material.Ground)
	end
	for _, b in data.clear do
		workspace.Terrain:FillBlock(CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0), Vector3.new(b[4], b[5], b[6]), Enum.Material.Air)
	end
	-- the cut edges show bare Ground: grass on everything round the lot (the Ground under the floor stays hidden)
	local mid = Vector3.new(33700, 50, 21990)
	workspace.Terrain:ReplaceMaterial(Region3.new(mid - Vector3.new(380, 30, 330), mid + Vector3.new(380, 30, 330)):ExpandToGrid(4), 4,
		Enum.Material.Ground, Enum.Material.Grass)
	model:SetAttribute("Source", "tools/yangon/landmarks3d/ycc_ggfest.py, asset " .. assetId)
	model.Parent = L
	hold:Destroy()
	return string.format("ok meshes %d boxes %d signs %d", n, #data.collide, #data.signs)
end

return Y
