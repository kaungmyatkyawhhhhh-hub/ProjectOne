--[[
	Our own rims on a car in CarModels (Studio, Edit; Prompts/Small design changes on famous new cars.md). The designs are in
	ServerStorage.RimKit (tools/wheels/wheel_library.py). What spins at each corner goes to ServerStorage.OldCarModels/
	<id>_rims_2026-11-08; "static" pieces (calipers) stay. Many models have tyre and rim in one mesh: those get our tyre and
	disc too, with the rim at 76% of the tyre. A corner's parts are told apart by size: the biggest is the tyre when a part
	of 70-92% of its size is there too.

	RimSwap.apply(id, design, faceColour) -> a line for the log
	RimSwap.undo(id)
]]
local RimSwap = {}

local CORNERS = { "FL", "FR", "RL", "RR" }
local LIP = Color3.fromRGB(196, 198, 204)
local RUBBER = Color3.fromRGB(26, 26, 28)
local STEEL = Color3.fromRGB(122, 124, 128)

local function dia(p: BasePart): number
	return math.max(p.Size.Y, p.Size.Z)
end

local function putIn(kit: Instance, name: string, parent: Instance, cf: CFrame, size: Vector3, color: Color3, mat: Enum.Material, newName: string): MeshPart
	local p = (kit:FindFirstChild(name, true) :: MeshPart):Clone()
	p.Name = newName
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.TextureID = ""
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	for _, c in p:GetChildren() do
		c:Destroy()
	end
	p.Parent = parent
	return p
end

function RimSwap.apply(id: string, design: string, color: Color3): string
	local model = game.ReplicatedStorage.CarModels:FindFirstChild(id) :: Model
	local kit = game.ServerStorage.RimKit
	local wheels = model:FindFirstChild("Wheels", true) :: Model
	local cf0, size0 = model:GetBoundingBox()
	local back = game.ServerStorage.OldCarModels:FindFirstChild(id .. "_rims_2026-11-08") or Instance.new("Folder")
	back.Name = id .. "_rims_2026-11-08"
	back.Parent = game.ServerStorage.OldCarModels
	local log = {}
	for _, corner in CORNERS do
		local group = wheels:FindFirstChild(corner) :: Instance
		local spin: { BasePart } = {}
		local all = if group:IsA("BasePart") then { group } else group:GetDescendants()
		for _, d in all do
			if d:IsA("BasePart") and not string.find(string.lower(d.Name), "static", 1, true) then
				table.insert(spin, d)
			end
		end
		table.sort(spin, function(a, b)
			return dia(a) > dia(b)
		end)
		local big = spin[1]
		local rim: BasePart? = nil
		for i = 2, #spin do
			local k = dia(spin[i]) / dia(big)
			if k >= 0.7 and k < 0.93 then
				rim = spin[i]
				break
			end
		end
		local c = big.Position
		local outer = if (cf0:PointToObjectSpace(c)).X < 0 then -1 else 1
		local ow = big.Size.X
		local disc: BasePart? = nil
		for _, p in spin do
			local n = string.lower(p.Name)
			if p ~= big and p ~= rim and (string.find(n, "disc", 1, true) or string.find(n, "disk", 1, true) or string.find(n, "brake", 1, true)) and dia(p) > dia(big) * 0.4 then
				disc = p
			end
		end
		local rimD, tyreBig = dia(big) * 0.76, false
		if rim then
			rimD, tyreBig = dia(rim), true
		end
		local turn = CFrame.Angles(0, if outer > 0 then math.pi else 0, 0) -- the mesh's outer face looks along -X
		local at = CFrame.new(c) * turn
		for _, p in spin do
			if not (tyreBig and p == big) and p ~= disc then
				p:SetAttribute("OldParent", p.Parent:GetFullName())
				p.Parent = back
			end
		end
		local parent = if group:IsA("BasePart") then wheels else group
		local width = ow * (if tyreBig then 0.9 else 0.92)
		putIn(kit, "Rim_" .. design .. "_Face", parent, at, Vector3.new(width, rimD, rimD), color, Enum.Material.Metal, corner .. "_Rim")
		putIn(kit, "Rim_" .. design .. "_Lip", parent, at, Vector3.new(width, rimD, rimD), LIP, Enum.Material.Metal, corner .. "_RimLip")
		if not tyreBig then
			putIn(kit, "Rim_Tyre", parent, at, Vector3.new(ow, dia(big), dia(big)), RUBBER, Enum.Material.SmoothPlastic, corner .. "_Tyre")
		end
		if not disc then
			local d = rimD * 0.78
			putIn(kit, "Rim_Disc", parent, CFrame.new(c - cf0.RightVector * outer * (ow * -0.02)) * turn, Vector3.new(ow * 0.11, d, d), STEEL, Enum.Material.Metal, corner .. "_Disc")
		end
		table.insert(log, string.format("%s %s d%.2f w%.2f%s%s", corner, if tyreBig then "ownTyre" else "newTyre", rimD, width, if disc then " ownDisc" else "", ""))
	end
	return id .. " " .. design .. ": " .. table.concat(log, " | ")
end

function RimSwap.undo(id: string)
	local model = game.ReplicatedStorage.CarModels:FindFirstChild(id) :: Model
	local back = game.ServerStorage.OldCarModels:FindFirstChild(id .. "_rims_2026-11-08")
	local wheels = model:FindFirstChild("Wheels", true) :: Model
	for _, corner in CORNERS do
		local group = wheels:FindFirstChild(corner)
		for _, n in { "_Rim", "_RimLip", "_Disc" } do
			local p = group and group:FindFirstChild(corner .. n)
			if p and not p:GetAttribute("OldParent") then
				p:Destroy()
			end
		end
	end
	if back then
		for _, p in back:GetChildren() do
			local at: Instance? = game
			for name in string.gmatch(p:GetAttribute("OldParent") or "", "[^%.]+") do
				at = at and at:FindFirstChild(name)
			end
			if at then
				p.Parent = at
			end
		end
		back:Destroy()
	end
end

return RimSwap
