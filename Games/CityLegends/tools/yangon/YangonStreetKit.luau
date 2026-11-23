--[[
	YangonStreetKit (Studio, Edit mode; ServerStorage.ClaudeTools pattern; 2026-11-16, rescale step 3: the 1:1 STREET
	DETAIL layer): turns the street-prop kit (tools/yangon/city/street_kit.py -> street_kit.glb, an Open Cloud Model) into
	templates in ReplicatedStorage.YgnKit.Templates, next to the building kit's. The placement data
	(street_1to1.py -> ReplicatedStorage.YgnKit.Data_<district>S) is built on each client near the camera by
	src/client/YangonKitStream.client.lua (decoder Shared.YangonKitData: P pieces, L / K cables, T name plates).

	Mesh names: CLASS_<pid>_<cx>_<cy>_<cz>_<sx>_<sy>_<sz> (hundredths of a stud, n = minus; the box in the piece's frame).
	Classes -> look (colours ride in the vertex colours, so every template is white):
	  SCO Concrete + YgnConcreteBare   SMT Metal + YgnSteelPainted   SPL SmoothPlastic   SFB Fabric + YgnCanvas
	  SGL Glass, 0.55 transparent      SNE lamp head: SmoothPlastic (236, 244, 255), tag LampGlow (Neon at night via
	                                   WorldFx), a white SpotLight down (range 42, brightness 5) tagged LODLight + DayOff

	local K = require(game.ServerStorage.ClaudeTools.YangonStreetKit:Clone())
	K.templates(holding)              -> n templates into ReplicatedStorage.YgnKit.Templates (CollisionFidelity Box)
	K.preview(centre, radius)         -> Edit only: builds the street tiles within radius into Workspace._StreetPreview
	K.unpreview()
]]

local RS = game:GetService("ReplicatedStorage")
local MS = game:GetService("MaterialService")
local CollectionService = game:GetService("CollectionService")

local K = {}

local LOOK = {
	SCO = { Enum.Material.Concrete, "YgnConcreteBare" },
	SMT = { Enum.Material.Metal, "YgnSteelPainted" },
	SPL = { Enum.Material.SmoothPlastic, "" },
	SFB = { Enum.Material.Fabric, "YgnCanvas" },
	SGL = { Enum.Material.Glass, "" },
	SNE = { Enum.Material.SmoothPlastic, "" },
}

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function K.parse(name: string)
	local kind, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%u+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not kind or not LOOK[kind] then
		return nil
	end
	return kind, id, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

function K.templates(holding: Instance): number
	local root = RS:FindFirstChild("YgnKit")
	if not root then
		root = Instance.new("Folder")
		root.Name = "YgnKit"
		root.Parent = RS
	end
	local store = root:FindFirstChild("Templates")
	if not store then
		store = Instance.new("Folder")
		store.Name = "Templates"
		store.Parent = root
	end
	local n = 0
	for _, d in holding:GetDescendants() do
		if not d:IsA("MeshPart") then
			continue
		end
		local kind, id, c, size = K.parse(d.Name)
		if not kind and d.Parent then
			kind, id, c, size = K.parse((string.gsub(d.Parent.Name, "_Node$", "")))
		end
		if not kind then
			continue
		end
		local name = kind .. "_" .. id
		local old = store:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local q = d:Clone()
		for _, ch in q:GetChildren() do
			ch:Destroy()
		end
		q.Name = name
		q.Size = size
		q.TextureID = ""
		q.Anchored = true
		q.CanCollide = false
		q.CanQuery = false
		q.CanTouch = false
		q.Massless = true
		q.CastShadow = kind ~= "SNE" and kind ~= "SGL"
		local look = LOOK[kind]
		q.Material = look[1]
		local mv = look[2] ~= "" and MS:FindFirstChild(look[2])
		q.MaterialVariant = if mv then look[2] else ""
		q.Color = Color3.new(1, 1, 1)
		q.Transparency = if kind == "SGL" then 0.55 else 0
		if kind == "SNE" then
			-- (owner, 2026-11-21: the videos overrule "Yangon lights are white") main-road lamps stay white LED; the
			-- plain side-street pole lamps (ppolel) are amber sodium as in the 0815 video, coil poles keep white
			local amber = id == "ppolel"
			q.Color = if amber then Color3.fromRGB(255, 176, 92) else Color3.fromRGB(236, 244, 255)
			CollectionService:AddTag(q, "LampGlow")
			local l = Instance.new("SpotLight")
			l.Face = Enum.NormalId.Bottom
			-- (21 Nov) main-road lamps (lamp1 / lamp2, about 30 studs up) light a wider pool: the videos' roads are lit
			-- end to end; 42 lit only a 29-stud circle under each post
			local main = id == "lamp1" or id == "lamp2"
			l.Angle = if main then 135 else 120
			l.Range = if main then 60 else 42
			l.Brightness = 5
			l.Color = if amber then Color3.fromRGB(255, 170, 96) else Color3.fromRGB(232, 240, 255)
			l.Shadows = false
			l.Parent = q
			CollectionService:AddTag(l, "LODLight")
			CollectionService:AddTag(l, "DayOff")
		end
		q:SetAttribute("C", c)
		q:SetAttribute("S", size)
		q.Parent = store
		pcall(function()
			q.CollisionFidelity = Enum.CollisionFidelity.Box
		end)
		pcall(function()
			(q :: any).RenderFidelity = Enum.RenderFidelity.Automatic
		end)
		n += 1
		if n % 10 == 0 then
			task.wait()
		end
	end
	return n
end

function K.preview(centre: Vector3, radius: number): number
	local KD = require((RS:WaitForChild("Shared"):WaitForChild("YangonKitData") :: ModuleScript):Clone())
	local root = RS:FindFirstChild("YgnKit")
	assert(root, "no ReplicatedStorage.YgnKit")
	local T = KD.index(root:FindFirstChild("Templates"))
	local out = workspace:FindFirstChild("_StreetPreview") or Instance.new("Folder")
	out.Name = "_StreetPreview"
	out.Parent = workspace
	local n = 0
	for _, f in root:GetChildren() do
		if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" and string.sub(f.Name, -1) == "S" then
			local meta = KD.meta(f)
			for _, v in f:GetChildren() do
				local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
				if i then
					local cx, cz = (tonumber(i) + 0.5) * meta.tile, (tonumber(j) + 0.5) * meta.tile
					if math.sqrt((cx - centre.X) ^ 2 + (cz - centre.Z) ^ 2) <= radius and not out:FindFirstChild(v.Name) then
						local tf = Instance.new("Folder")
						tf.Name = v.Name
						tf.Parent = out
						local job = KD.job((v :: StringValue).Value, tonumber(i) :: number, tonumber(j) :: number, meta, T, tf)
						while not job:step(400) do
							task.wait()
						end
						n += job.parts
					end
				end
			end
		end
	end
	return n
end

function K.unpreview()
	local out = workspace:FindFirstChild("_StreetPreview")
	if out then
		out:Destroy()
	end
end

return K
