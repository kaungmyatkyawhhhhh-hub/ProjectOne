--[[
	P1Refit (Studio, Edit; 2026-11-16): places the 1:1 refit of Myanmar Centre (mc1: Myanmar Plaza, the towers, the
	Melia, the walkable mall and Melia lobby) and Sedona (sd1) in pilot P1 under Workspace.Yangon1to1.Landmarks.
	Data from tools/yangon/city/p1_refit_pack.py (Folder P1RefitData: this module + StringValues).

	local R = require(data.P1Refit:Clone())
	R.spawn("terrain", function() return R.terrain(data) end)   -- air above / ground below each site, ramp trenches
	R.spawn("place", function() return R.place(holding, "MyanmarCentre", "mc1") end)
	R.spawn("collide", function() return R.collide(data.mc1_collide.Value, "MyanmarCentre") end)
	R.spawn("lights", function() return R.lights(data.mc1_lights.Value, "MyanmarCentre") end)
	R.status() -> the last job's state (MCP calls must stay under ~5 s: every job runs in task.spawn)

	Meshes: MeshParts named "<GROUP>_<tag>s<k>_cx_cy_cz_sx_sy_sz" (hundredths, "n" = minus; world box, the .glb has
	x and z negated so CFrame.new(centre) with no turn). Visual only (CanCollide / CanQuery off, CollisionFidelity Box
	set after parenting); collision = invisible boxes (Collide folder). Night: "night" groups tagged FacadeNight,
	"glow" groups LandmarkGlow with NightColor.
]]
local CollectionService = game:GetService("CollectionService")

--@@GROUPS@@

local M = {}
M.GROUPS = GROUPS

local function root(name: string): Instance
	local y = workspace:FindFirstChild("Yangon1to1")
	local lm = y:FindFirstChild("Landmarks")
	if not lm then
		lm = Instance.new("Folder")
		lm.Name = "Landmarks"
		lm.Parent = y
	end
	local f = lm:FindFirstChild(name)
	if not f then
		f = Instance.new("Model")
		f.Name = name
		f.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		f.Parent = lm
	end
	return f
end
M.root = root

local function sub(parent: Instance, name: string, class: string?): Instance
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new(class or "Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function number(s: string): number
	if string.sub(s, 1, 1) == "n" then
		return -(tonumber(string.sub(s, 2)) :: number) / 100
	end
	return (tonumber(s) :: number) / 100
end

function M.parse(name: string)
	local grp, id, cx, cy, cz, sx, sy, sz =
		string.match(name, "^(%w+)_(%w+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)_(n?%d+)")
	if not grp then
		return nil
	end
	return grp, id, Vector3.new(number(cx), number(cy), number(cz)), Vector3.new(number(sx), number(sy), number(sz))
end

M.state = {}
function M.spawn(name: string, fn)
	M.state = { job = name, done = false }
	task.spawn(function()
		local ok, res = pcall(fn)
		M.state = { job = name, done = true, ok = ok, res = res }
		workspace:SetAttribute("P1RefitJob", name .. ": " .. (ok and "ok " or "ERROR ") .. tostring(res))
	end)
	return "started " .. name
end
function M.status()
	return M.state
end

-- the meshes of one holding folder into <site>.Meshes (replaces the tag's earlier meshes)
function M.place(holding: Instance, site: string, tag: string): string
	local r = root(site)
	local mf = sub(r, "Meshes", "Model")
	local n, missing = 0, {}
	local made = {}
	for _, d in holding:GetDescendants() do
		if d:IsA("MeshPart") then
			local grp, id, c, size = M.parse(d.Name)
			if not grp and d.Parent then
				grp, id, c, size = M.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			local spec = grp and GROUPS[grp]
			if spec then
				local q = d:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = grp
				q.Size = size
				q.CFrame = CFrame.new(c)
				q.Anchored = true
				q.CanCollide = false
				q.CanQuery = false
				q.CanTouch = false
				q.TextureID = ""
				q.Material = Enum.Material[spec[1]]
				q.Color = Color3.fromRGB(spec[2], spec[3], spec[4])
				q.Transparency = spec[5]
				q.Reflectance = spec[6]
				q.DoubleSided = spec[7]
				q.CastShadow = spec[8]
				q:SetAttribute("Refit", tag)
				if spec[9] == "night" then
					q.Transparency = 1
					CollectionService:AddTag(q, "FacadeNight")
				elseif spec[9] == "glow" then
					q:SetAttribute("NightColor", Color3.fromRGB(spec[10], spec[11], spec[12]))
					q:SetAttribute("DayColor", q.Color)
					q:SetAttribute("DayMaterial", spec[1])
					CollectionService:AddTag(q, "LandmarkGlow")
				end
				q.Parent = mf
				table.insert(made, q)
				n += 1
				if n % 10 == 0 then
					task.wait()
				end
			elseif grp then
				missing[grp] = true
			end
		end
	end
	-- after parenting (an unparented clone drops it): box collision fidelity, automatic render fidelity
	for i, q in made do
		pcall(function()
			q.CollisionFidelity = Enum.CollisionFidelity.Box
			q.RenderFidelity = Enum.RenderFidelity.Automatic
		end)
		if i % 12 == 0 then
			task.wait()
		end
	end
	local ms = {}
	for k in missing do
		table.insert(ms, k)
	end
	return string.format("%d meshes, missing groups: %s", n, table.concat(ms, ","))
end

-- invisible collision boxes (one line "id|X Y Z sx sy sz yaw|...") into <site>.Collide
function M.collide(data: string, site: string): number
	local f = sub(root(site), "Collide", "Model")
	local n = 0
	for line in string.gmatch(data, "[^\n]+") do
		local parts = string.split(line, "|")
		for k = 2, #parts do
			local v = {}
			for w in string.gmatch(parts[k], "%S+") do
				table.insert(v, tonumber(w))
			end
			if #v == 7 then
				local p = Instance.new("Part")
				p.Name = "Col"
				p.Anchored = true
				p.Size = Vector3.new(math.max(v[4], 0.05), math.max(v[5], 0.05), math.max(v[6], 0.05))
				p.CFrame = CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[7], 0)
				p.Transparency = 1
				p.CanCollide = true
				p.CanQuery = true
				p.CanTouch = false
				p.CastShadow = false
				p.Parent = f
				n += 1
				if n % 150 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

local SPEC = {
	mall = { 22, 0.9, Color3.fromRGB(255, 250, 242) },
	atrium = { 30, 1.0, Color3.fromRGB(255, 252, 246) },
	shop = { 14, 0.7, Color3.fromRGB(250, 252, 255) },
	lobby = { 26, 1.2, Color3.fromRGB(255, 240, 214) },
	soffit = { 16, 0.8, Color3.fromRGB(255, 226, 180) },
	street = { 34, 1.0, Color3.fromRGB(236, 244, 255) },
	gate = { 18, 0.9, Color3.fromRGB(255, 236, 200) },
}

function M.lights(json: string, site: string): number
	local HttpService = game:GetService("HttpService")
	local list = HttpService:JSONDecode(json)
	local f = sub(root(site), "Lights", "Model")
	f:ClearAllChildren()
	local n = 0
	for _, l in list do
		local s = SPEC[l.kind] or SPEC.mall
		local p = Instance.new("Part")
		p.Name = "Light_" .. l.kind
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(0.2, 0.2, 0.2)
		p.Position = Vector3.new(l.w[1], l.w[2], l.w[3])
		local pl = Instance.new("PointLight")
		pl.Range = s[1]
		pl.Brightness = s[2]
		pl.Color = s[3]
		pl.Shadows = false
		pl.Parent = p
		p.Parent = f
		n += 1
	end
	return n
end

-- the ground under both sites: air from the run's top up 260 studs, ground from 10 under it to the top
function M.terrain(data: Instance): string
	local T = workspace.Terrain
	local n = 0
	for line in string.gmatch(data.terrain_mc.Value .. data.terrain_sd.Value, "[^\n]+") do
		local x0, z, x1, top = string.match(line, "(%S+) (%S+) (%S+) (%S+)")
		x0, z, x1, top = tonumber(x0), tonumber(z), tonumber(x1), tonumber(top)
		local cx, w = (x0 + x1) / 2, x1 - x0
		T:FillBlock(CFrame.new(cx, top + 130, z), Vector3.new(w, 260, 4), Enum.Material.Air)
		T:FillBlock(CFrame.new(cx, top - 6, z), Vector3.new(w, 12, 4), Enum.Material.Ground)
		n += 1
		if n % 60 == 0 then
			task.wait()
		end
	end
	local c = 0
	for line in string.gmatch(data.carve.Value, "[^\n]+") do
		local v = {}
		for w in string.gmatch(line, "%S+") do
			table.insert(v, tonumber(w))
		end
		if #v == 7 then
			T:FillBlock(CFrame.new(v[1], v[2], v[3]) * CFrame.Angles(0, v[7], 0), Vector3.new(v[4], v[5], v[6]), Enum.Material.Air)
			c += 1
		end
	end
	return string.format("terrain runs %d, carved %d", n, c)
end

function M.undo(site: string)
	local y = workspace:FindFirstChild("Yangon1to1")
	local lm = y and y:FindFirstChild("Landmarks")
	local f = lm and lm:FindFirstChild(site)
	if f then
		f:Destroy()
	end
end

return M
