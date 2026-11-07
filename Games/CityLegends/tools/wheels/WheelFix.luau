--[[
	Old imports' wheels came in as one part with one picture: white or black tyres and rims, on the Ecstasy
	Grandeur a real badge picture round the whole wheel. The fixed packs of 2026-10-23 hold each wheel one part per
	material. tools/wheels/split_wheels.py takes those wheels out, joins pieces of one colour per corner and writes
	small FBX files; this puts them on the cars in ReplicatedStorage.CarModels (edit side, saved in the place).

	require(ClaudeTools.WheelFix:Clone())(assetId)  -> a log. Old wheels go to ServerStorage.OldCarModels.
	A car is left alone if a corner has no tyre and rim as separate parts (its pack is one picture too).
]]
local HS = game:GetService("HttpService")
local IS = game:GetService("InsertService")
local SS = game:GetService("ServerStorage")
local CM = game:GetService("ReplicatedStorage"):WaitForChild("CarModels")

local Colours = HS:JSONDecode(require(SS.ClaudeTools.WheelTable:Clone()))

local TYRE = Color3.fromRGB(24, 24, 26)
local CAP = Color3.fromRGB(34, 34, 38)

local function clean(name: string): string
	return (name:gsub("%.%d+$", ""))
end

local function look(car: string, part: string): (Color3, Enum.Material)
	local t = Colours[car] or {}
	local corner, rest = part:match("^(%a%a)_(.+)$")
	local e = t[part] or t[(rest or part)] or nil
	if rest and rest:find("Tyre") then
		return TYRE, Enum.Material.Plastic
	end
	if rest and rest:find("Cap") then
		return CAP, Enum.Material.SmoothPlastic
	end
	if not e then
		return Color3.fromRGB(150, 152, 156), Enum.Material.Metal
	end
	local r, g, b = math.min(e[1], 215), math.min(e[2], 215), math.min(e[3], 215)
	local avg = (r + g + b) / 3
	if avg < 28 then
		r, g, b = 28, 28, 30
	end
	return Color3.fromRGB(r, g, b), if e[4] >= 0.45 then Enum.Material.Metal else Enum.Material.SmoothPlastic
end

local function tyreOf(group: Instance): BasePart?
	local best: BasePart? = nil
	for _, p in group:GetChildren() do
		if p:IsA("BasePart") and p.Name:find("Tyre") then
			if not best or p.Size.Magnitude > best.Size.Magnitude then
				best = p
			end
		end
	end
	return best
end

local function apply(id: string, src: Instance, log: { string }, target: string?): boolean
	local dest = target or id
	local car = CM:FindFirstChild(dest)
	local oldW = car and car:FindFirstChild("Wheels", true)
	local newW: Instance? = nil
	for _, c in src:GetDescendants() do
		if clean(c.Name) == "Wheels" then
			newW = c
		end
	end
	if not oldW or not newW then
		table.insert(log, dest .. ": no wheels")
		return false
	end
	local corners: { [string]: Instance } = {}
	for _, c in newW:GetChildren() do
		corners[clean(c.Name)] = c
	end
	for _, n in { "FL", "FR", "RL", "RR" } do
		local g = corners[n]
		if not g or not oldW:FindFirstChild(n) or not oldW[n]:IsA("BasePart") then
			table.insert(log, dest .. ": missing or already done " .. n)
			return false
		end
		for _, p in g:GetChildren() do
			p.Name = clean(p.Name)
		end
		-- some packs marked the rim or tyre as not spinning: round and on the axle, it spins
		local biggest = tyreOf(g)
		if biggest then
			local dia = math.max(biggest.Size.Y, biggest.Size.Z)
			for _, p in g:GetChildren() do
				if p:IsA("BasePart") and p.Name:find("static") then
					local d = math.max(p.Size.Y, p.Size.Z)
					local off = p.Position - biggest.Position
					if d >= dia * 0.35 and math.abs(p.Size.Y - p.Size.Z) < d * 0.04 and Vector3.new(0, off.Y, off.Z).Magnitude < dia * 0.04 then
						p:SetAttribute("Orig", p.Name)
						p.Name = p.Name:gsub("_static_", "_")
					end
				end
			end
		end
		local spin, tyre = 0, tyreOf(g)
		for _, p in g:GetChildren() do
			if p:IsA("BasePart") and not p.Name:find("static") and not p.Name:find("Tyre") and not p.Name:find("Cap") then
				spin += 1
			end
		end
		if not tyre or spin == 0 or tyre.Name:find("static") then
			table.insert(log, dest .. ": left alone (one picture in its pack too)")
			return false
		end
	end
	-- turned round?
	local a, b = tyreOf(corners.FL) :: BasePart, tyreOf(corners.RR) :: BasePart
	local va = a.Position - b.Position
	local vo = oldW.FL.Position - oldW.RR.Position
	local flip = Vector3.new(va.X, 0, va.Z):Dot(Vector3.new(vo.X, 0, vo.Z)) < 0
	local back = SS:FindFirstChild("OldCarModels") or Instance.new("Folder")
	back.Name = "OldCarModels"
	back.Parent = SS
	local keep = Instance.new("Folder")
	keep.Name = dest .. "_wheels_2026-11-07"
	keep.Parent = back
	for _, n in { "FL", "FR", "RL", "RR" } do
		local old = oldW[n] :: BasePart
		local g = corners[n]
		local tyre = tyreOf(g) :: BasePart
		local centre = tyre.Position
		local rotOld = 0
		local s = math.max(old.Size.X, old.Size.Y, old.Size.Z) / math.max(tyre.Size.X, tyre.Size.Y, tyre.Size.Z)
		local m = Instance.new("Model")
		m.Name = n
		for _, p in g:GetChildren() do
			if p:IsA("BasePart") then
				local q = p:Clone()
				local rel = (p.Position - centre) * s
				if flip then
					rel = Vector3.new(-rel.X, rel.Y, -rel.Z)
				end
				q.Size = p.Size * s
				q.CFrame = (CFrame.new(old.Position + rel) * (if flip then CFrame.Angles(0, math.pi, 0) else CFrame.new())) * p.CFrame.Rotation
				q.Anchored = old.Anchored
				q.CanCollide = old.CanCollide
				q.CanQuery = old.CanQuery
				q.CanTouch = old.CanTouch
				q.Massless = old.Massless
				for _, d in q:GetChildren() do
					d:Destroy()
				end
				q.TextureID = ""
				local c, mat = look(id, q:GetAttribute("Orig") or q.Name)
				q.Color = c
				q.Material = mat
				q.Parent = m
			end
		end
		m.Parent = oldW
		old.Parent = keep
		local _ = rotOld
	end
	table.insert(log, dest .. ": done" .. (if flip then " (turned)" else ""))
	return true
end

return function(assetId: number, also: { [string]: string }?)
	local log = {}
	local holder = IS:LoadAsset(assetId)
	local root = holder
	for _, c in holder:GetChildren() do
		if c:IsA("Model") and not Colours[clean(c.Name)] then
			root = c
		end
	end
	root:PivotTo(CFrame.new(root:GetPivot().Position))
	for _, c in root:GetChildren() do
		local id = clean(c.Name)
		if Colours[id] then
			if CM:FindFirstChild(id) then
				apply(id, c, log)
			end
			for from, to in also or {} do
				if from == id then
					apply(id, c, log, to)
				end
			end
		end
	end
	holder:Destroy()
	return table.concat(log, "\n")
end
