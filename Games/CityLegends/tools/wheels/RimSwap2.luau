--[[
	Wheel kit v2 on the new models (Studio, Edit; 2026-11-08, Prompts/A million times better wheels (new models).md).
	The meshes come from tools/wheels/wheel_library_v2.py (one Open Cloud model, ServerStorage.WheelsV2Holding), the
	pictures from tools/wheels/wheel_textures.py and the bakes (ids in tools/wheels/kit2_ids.json, passed in as IDS).

	RimSwap2.buildKit(IDS)            -> ServerStorage.RimKit2: every mesh with its role (attribute WheelRole)
	RimSwap2.apply(id, cfg, IDS)      -> a line for the log. cfg: design, finish, tyre ("sport" ...), ratioF / ratioR
	                                     ("66" / "71" / "75"), brakes ("drilled" ...), caliper (Color3), deepRear (bool)
	RimSwap2.undo(id)

	In the kit's meshes (Studio's importer turns them round): the outer face looks along -X, up is +Y, CaliperA sits
	towards +Z and CaliperB towards -Z. Every rim-frame mesh fills the same box, so they all take one CFrame and Size.
	A model's old wheel pieces go to ServerStorage.OldCarModels/<id>_wheels2 (attribute OldParent), and the same
	is done to its scissor-door twin (<id>@doors) if there is one.
]]
local RimSwap2 = {}

local CORNERS = { "FL", "FR", "RL", "RR" }
local BACKUP = "_wheels2"

-- finishes: tint, metal, roughness (the colour picture is the baked shade, the tint gives the colour)
RimSwap2.FINISH = {
	gloss_black = { Color3.fromRGB(26, 26, 28), 0.15, 0.22 },
	satin_black = { Color3.fromRGB(30, 30, 32), 0.25, 0.55 },
	gunmetal = { Color3.fromRGB(74, 76, 80), 0.8, 0.33 },
	dark_grey = { Color3.fromRGB(54, 56, 60), 0.65, 0.4 },
	silver = { Color3.fromRGB(184, 186, 190), 0.85, 0.28 },
	polished = { Color3.fromRGB(214, 216, 220), 1, 0.12 },
}
RimSwap2.CALIPER = {
	black = Color3.fromRGB(28, 28, 30),
	silver = Color3.fromRGB(170, 172, 176),
	grey = Color3.fromRGB(92, 94, 98),
	red = Color3.fromRGB(186, 24, 24),
	yellow = Color3.fromRGB(232, 186, 22),
	blue = Color3.fromRGB(28, 70, 168),
	orange = Color3.fromRGB(228, 108, 22),
	green = Color3.fromRGB(36, 134, 60),
	gold = Color3.fromRGB(196, 156, 58),
	bronze = Color3.fromRGB(148, 98, 52),
}

local function id(IDS, name: string): string
	local v = IDS[name]
	assert(v, "no image id for " .. name)
	return "rbxassetid://" .. tostring(v)
end

local function metalId(IDS, v: number): string
	-- the nearest one-value picture
	local best, bd = "v000", 2
	for _, k in { 0, 15, 25, 35, 45, 55, 70, 85, 100 } do
		local d = math.abs(k / 100 - v)
		if d < bd then
			best, bd = string.format("v%03d", k), d
		end
	end
	return id(IDS, best)
end

local function sa(part: MeshPart, maps: { [string]: any })
	for _, c in part:GetChildren() do
		if c:IsA("SurfaceAppearance") then
			c:Destroy()
		end
	end
	local s = Instance.new("SurfaceAppearance")
	for k, v in maps do
		(s :: any)[k] = v
	end
	s.Parent = part
	return s
end

-- the kit: one MeshPart per mesh with its role and its fixed pictures (finish-dependent ones are set by apply)
function RimSwap2.buildKit(IDS)
	local src = game.ServerStorage.WheelsV2Holding:FindFirstChildWhichIsA("Model") :: Model
	local kit = game.ServerStorage:FindFirstChild("RimKit2") or Instance.new("Folder")
	kit.Name = "RimKit2"
	kit:ClearAllChildren()
	kit.Parent = game.ServerStorage
	local n = 0
	for _, d in src:GetDescendants() do
		if not d:IsA("MeshPart") then
			continue
		end
		local p = d:Clone()
		for _, c in p:GetChildren() do
			c:Destroy()
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.new(1, 1, 1)
		local name = p.Name
		local design, part = string.match(name, "^R2_(%w+)_(%a+)$")
		local role
		if name == "R2_Lip" then
			role = "Lip"
		elseif name == "R2_Barrel" then
			role = "Barrel"
		elseif name == "R2_Disc" then
			role = "Disc"
			p.CastShadow = false
		elseif string.match(name, "^R2_Caliper") then
			role = "Caliper"
			sa(p, { ColorMap = id(IDS, "ao_caliper" .. string.sub(name, -1)), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, 0.1), RoughnessMap = metalId(IDS, 0.3) })
		elseif name == "R2_Shield" then
			role = "Shield"
			p.Color = Color3.fromRGB(18, 18, 20)
		elseif string.match(name, "^R2_Tyre") then
			role = "Tyre"
			p:SetAttribute("TyreK", tonumber(string.sub(name, 8)))
		elseif design then
			local deep = string.sub(part, -1) == "D"
			local base = if deep then string.sub(part, 1, -2) else part
			role = base
			p:SetAttribute("Design", design)
			p:SetAttribute("Deep", deep)
			if base == "Nuts" then
				sa(p, { ColorMap = id(IDS, "v100"), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = id(IDS, "v100"), RoughnessMap = metalId(IDS, 0.2) })
			elseif base == "Blur" then
				local s = sa(p, { ColorMap = id(IDS, "blur_" .. design .. (if deep then "D" else "")), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, 0.4), RoughnessMap = metalId(IDS, 0.45) })
				s.AlphaMode = Enum.AlphaMode.Transparency
			end
		end
		p:SetAttribute("WheelRole", role or "?")
		p.Parent = kit
		n += 1
	end
	return "kit: " .. n .. " meshes"
end

local function dia(p: BasePart): number
	return math.max(p.Size.X, p.Size.Y, p.Size.Z)
end

local function backupFolder(id: string): Folder
	local f = game.ServerStorage.OldCarModels:FindFirstChild(id .. BACKUP)
	if not f then
		f = Instance.new("Folder")
		f.Name = id .. BACKUP
		f.Parent = game.ServerStorage.OldCarModels
	end
	return f :: Folder
end

local function applyModel(model: Model, backupId: string, cfg, IDS): string
	local kit = game.ServerStorage.RimKit2
	local wheels = model:FindFirstChild("Wheels", true) :: Instance
	assert(wheels, model.Name .. ": no Wheels")
	local back = backupFolder(backupId)
	-- the car's frame from its wheels: forward, and which side is out
	local centres: { [string]: Vector3 } = {}
	local tyreOf: { [string]: BasePart } = {}
	for _, corner in CORNERS do
		local g = wheels:FindFirstChild(corner) :: Instance
		assert(g, model.Name .. ": no " .. corner)
		local best: BasePart? = nil
		local list = if g:IsA("BasePart") then { g } else {}
		for _, d in g:GetDescendants() do
			table.insert(list, d)
		end
		for _, d in list do
			if d:IsA("BasePart") and not string.find(string.lower(d.Name), "static", 1, true) and d:GetAttribute("WheelRole") ~= "Blur" then
				if not best or dia(d) > dia(best) then
					best = d
				end
			end
		end
		assert(best, model.Name .. " " .. corner .. ": no wheel part")
		tyreOf[corner] = best :: BasePart
		centres[corner] = (best :: BasePart).Position
	end
	local fwd = ((centres.FL + centres.FR) / 2 - (centres.RL + centres.RR) / 2)
	fwd = Vector3.new(fwd.X, 0, fwd.Z).Unit
	local mid = (centres.FL + centres.FR + centres.RL + centres.RR) / 4
	-- the model's ground: the lowest old tyre's bottom (a model's undersized wheel floats over it)
	local ground = math.huge
	for _, corner in CORNERS do
		ground = math.min(ground, centres[corner].Y - dia(tyreOf[corner]) / 2)
	end
	-- the model's size: its wheelbase against the real one (cfg.realWB, metres)
	local modelWB = ((centres.FL + centres.FR) / 2 - (centres.RL + centres.RR) / 2).Magnitude
	local perMetre = if cfg.realWB then modelWB / cfg.realWB else 1
	local log = {}
	for _, corner in CORNERS do
		local g = wheels:FindFirstChild(corner) :: Instance
		local tyre = tyreOf[corner]
		local front = string.sub(corner, 1, 1) == "F"
		-- the tyre: the real car's size (cfg.realF / realR: diameter and width in metres), sized so it stands on the
		-- model's ground under the model's own axle (that is what fills the arch as modelled), within 10% of real
		local oldD = dia(tyre)
		local oldW = math.min(tyre.Size.X, tyre.Size.Y, tyre.Size.Z)
		local c = centres[corner]
		local real = if front then cfg.realF else cfg.realR
		local D, W = oldD, oldW
		local note = ""
		if real then
			-- the diameter the model's own axle and ground give (what its arch was made for); the real width, scaled
			-- the same way when the model's wheels are off the real size
			local rD, rW = real[1] * perMetre, real[2] * perMetre
			local axleD = 2 * (c.Y - ground)
			D = axleD
			W = rW * math.clamp(axleD / rD, 0.8, 1.1)
			if math.abs(axleD / rD - 1) > 0.1 then
				note = string.format(" (model's wheel %.0f%% of real)", axleD / rD * 100)
			end
		end
		-- the wheel's axis points out of the car: the outward side
		local side = fwd:Cross(Vector3.yAxis) -- the car's right
		local outward = if (c - mid):Dot(side) > 0 then side else -side
		-- the outer face stays where the model had it (flush with the body); a wider tyre grows inwards
		c = c + outward * (oldW / 2 - W / 2)
		c = Vector3.new(c.X, ground + D / 2, c.Z)
		-- the kit's outer face is -X: point -X outward, +Y up
		local xAxis = -outward
		local at = CFrame.fromMatrix(c, xAxis, Vector3.yAxis)
		-- move the old pieces out (all of them: spinning and static)
		local moved = {}
		if g:IsA("BasePart") then
			-- a corner that is one part: becomes a group of the same name
			local grp = Instance.new("Model")
			grp.Name = corner
			grp.Parent = g.Parent
			for _, ch in g:GetChildren() do
				if ch:IsA("BasePart") then
					ch.Parent = grp
				end
			end
			g:SetAttribute("OldParent", (g.Parent :: Instance):GetFullName())
			g.Parent = back
			table.insert(moved, g.Name)
			g = grp
		end
		for _, d in g:GetDescendants() do
			if d:IsA("BasePart") then
				d:SetAttribute("OldParent", (d.Parent :: Instance):GetFullName())
				table.insert(moved, d.Name)
			end
		end
		for _, d in g:GetDescendants() do
			if d:IsA("BasePart") then
				d.Parent = back
			end
		end
		for _, d in g:GetChildren() do
			if not d:IsA("BasePart") then
				d:SetAttribute("OldParent", g:GetFullName())
				d.Parent = back
			end
		end
		-- the new wheel
		local ratio = if front then cfg.ratioF else cfg.ratioR
		local k = tonumber("0." .. ratio) :: number
		local rimD = D * k
		local rimW = W * 0.82
		local deep = cfg.deepRear and not front
		local suf = if deep then "D" else ""
		local fin = RimSwap2.FINISH[cfg.finish] or RimSwap2.FINISH.silver
		local function put(kitName: string, newName: string, size: Vector3, maps: { [string]: any }?, color: Color3?): MeshPart
			local src = kit:FindFirstChild(kitName) :: MeshPart
			assert(src, "kit has no " .. kitName)
			local p = src:Clone()
			p.Name = corner .. newName
			p.Size = size
			p.CFrame = at
			p.Anchored = true
			if maps then
				local s = sa(p, maps)
				if color then
					s.Color = color
				end
			end
			p.Parent = g
			return p
		end
		local rs = Vector3.new(rimW, rimD, rimD)
		local tyreKind = if cfg.tyre == "allseason" then "touring" else cfg.tyre
		put("R2_Tyre" .. ratio, "_Tyre", Vector3.new(W, D, D), {
			ColorMap = id(IDS, "tyre_" .. tyreKind .. "_col"),
			NormalMap = id(IDS, "tyre_" .. tyreKind .. "_nrm"),
			RoughnessMap = id(IDS, "tyre_" .. tyreKind .. "_rgh"),
			MetalnessMap = id(IDS, "v000"),
		})
		local faceMaps = { ColorMap = id(IDS, "ao_" .. cfg.design .. "_face" .. suf), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, fin[2]), RoughnessMap = metalId(IDS, fin[3]) }
		put("R2_" .. cfg.design .. "_Face" .. suf, "_RimFace", rs, faceMaps, fin[1])
		local capPart = kit:FindFirstChild("R2_" .. cfg.design .. "_Cap" .. suf)
		if capPart then
			put("R2_" .. cfg.design .. "_Cap" .. suf, "_RimCap", rs, { ColorMap = id(IDS, "v100"), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, fin[2]), RoughnessMap = metalId(IDS, fin[3]) }, fin[1])
		end
		local nuts = put("R2_" .. cfg.design .. "_Nuts" .. suf, "_RimNuts", rs)
		if cfg.design == "Centro6" then
			-- the centre-lock nut: dark anodised
			local s = nuts:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
			s.Color = Color3.fromRGB(60, 62, 66)
		end
		local lipFin = if cfg.design == "Disco5" then fin else RimSwap2.FINISH.polished
		put("R2_Lip", "_RimLip", rs, { ColorMap = id(IDS, "v100"), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, lipFin[2]), RoughnessMap = if cfg.design == "Disco5" then metalId(IDS, lipFin[3]) else id(IDS, "lip_machined_rgh") }, lipFin[1])
		put("R2_Barrel", "_RimBarrel", rs, { ColorMap = id(IDS, "ao_" .. cfg.design .. "_barrel" .. suf), NormalMap = id(IDS, "nrm_flat"), MetalnessMap = metalId(IDS, 0.5), RoughnessMap = metalId(IDS, 0.5) }, Color3.fromRGB(70, 72, 76))
		local blur = put("R2_" .. cfg.design .. "_Blur" .. suf, "_RimBlur", rs)
		local bs = blur:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
		bs.Color = fin[1]
		blur.Transparency = 0.95 -- (seen by CarSkin; the game hides it until the wheel spins fast)
		local brakes = cfg.brakes
		local disc = put("R2_Disc", "_Disc", rs, {
			ColorMap = id(IDS, "disc_" .. brakes .. "_col"),
			NormalMap = id(IDS, "disc_" .. brakes .. "_nrm"),
			RoughnessMap = id(IDS, "disc_" .. brakes .. "_rgh"),
			MetalnessMap = id(IDS, "disc_" .. brakes .. "_mtl"),
		})
		local ds = disc:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
		pcall(function()
			(ds :: any).EmissiveMaskContent = Content.fromUri(id(IDS, "disc_" .. brakes .. "_glow"))
			ds.EmissiveTint = Color3.fromRGB(255, 96, 24)
			ds.EmissiveStrength = 0
		end)
		-- the caliper behind the axle, high: the kit's +Z side is CaliperA
		local zWorld = at.ZVector
		local cal = if zWorld:Dot(fwd) < 0 then "A" else "B"
		local cp = put("R2_Caliper" .. cal, "_static_Caliper", rs)
		local cs = cp:FindFirstChildOfClass("SurfaceAppearance") :: SurfaceAppearance
		cs.Color = cfg.caliper
		put("R2_Shield", "_static_Shield", rs)
		table.insert(log, string.format("%s D%.3f(was %.3f) W%.3f(was %.3f) k%s %s%s moved %d%s", corner, D, oldD, W, oldW, ratio, cfg.design, suf, #moved, note))
	end
	-- (CarBuilder gives a kit-v2 car's physics wheels each axle's own radius, CarSkin stands it on its own ground)
	model:SetAttribute("WheelKit", 2)
	return model.Name .. ": " .. table.concat(log, " | ")
end

function RimSwap2.apply(id: string, cfg, IDS): string
	local CM = game.ReplicatedStorage.CarModels
	local out = {}
	for _, name in { id, id .. "@doors" } do
		local m = CM:FindFirstChild(name)
		if m then
			table.insert(out, applyModel(m :: Model, name, cfg, IDS))
		end
	end
	assert(#out > 0, "no model " .. id)
	return table.concat(out, "\n")
end

function RimSwap2.undo(id: string)
	local CM = game.ReplicatedStorage.CarModels
	for _, name in { id, id .. "@doors" } do
		local m = CM:FindFirstChild(name)
		local back = game.ServerStorage.OldCarModels:FindFirstChild(name .. BACKUP)
		if not (m and back) then
			continue
		end
		local wheels = m:FindFirstChild("Wheels", true) :: Instance
		for _, corner in CORNERS do
			local g = wheels:FindFirstChild(corner)
			if g then
				for _, d in g:GetDescendants() do
					if d:IsA("BasePart") and d:GetAttribute("WheelRole") then
						d:Destroy()
					end
				end
			end
		end
		-- groups first (a corner that was one part comes back as that part), then the pieces
		local items = back:GetChildren()
		table.sort(items, function(a, b)
			return #a:GetChildren() > #b:GetChildren()
		end)
		for _, p in items do
			local at: Instance? = game
			for nm in string.gmatch(p:GetAttribute("OldParent") or "", "[^%.]+") do
				at = at and at:FindFirstChild(nm)
			end
			if at then
				p.Parent = at
			end
		end
		for _, corner in CORNERS do
			local g = wheels:FindFirstChild(corner)
			if g and g:IsA("Model") and #g:GetChildren() == 0 then
				g:Destroy()
			end
		end
		back:Destroy()
		m:SetAttribute("WheelKit", nil)
	end
end

return RimSwap2
