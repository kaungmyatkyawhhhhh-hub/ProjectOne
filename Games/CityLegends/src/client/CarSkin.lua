--[[
	CarSkin (client)
	Replaces the part-built bodywork of a car with its generated meshes
	(CarMesh -> EditableMesh -> MeshPart): one MeshPart per material layer
	(paint, accent, black trim, chrome, glass, LED lamps, tail lamps, plate,
	interior) plus real wheels: tyre + spoked rim spinning on the wheel
	joint, and a brake caliper on a steering knuckle (it steers but does not
	spin).

	Meshes are generated once per car design and cloned, so a city of traffic
	costs one set per design. Traffic uses the lighter "lite" versions.

	Imported models: if ReplicatedStorage has a "CarModels" folder holding a
	model named after a car id (made by tools/make_glb.py and brought in with
	Studio's 3D Importer), that car uses those MeshParts instead of runtime
	meshes. The "Mark_*" parts in it give the car's frame and scale, so it
	doesn't matter where the importer put it. Player cars, the garage and the
	cutscene prefer imported models; traffic keeps the cheap runtime "lite"
	meshes and falls back to the imported ones when runtime meshes are not
	allowed. With neither, apply() returns false and the part bodies stay.
]]

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarMesh = require(Shared:WaitForChild("CarMesh"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local Cars = require(Shared:WaitForChild("Cars"))

local CarSkin = {}

-- cars with their own dashboard design (DashGauges styles), built from the owner's reference photos
CarSkin.CLUSTER_STYLE = {
	lambrini_lp700 = "Aventador",
	ferrara_458 = "Ferrari",
	bnw_330i_g20 = "BMWLive",
	bnw_m3_e92 = "BMWClassic",
	bnw_m5_e60 = "BMWClassic",
	bnw_m6_v10 = "BMWClassic",
	bentz_cla45 = "AMG",
	toyoka_supra_mk4 = "SupraTRD",
	toyoka_camri = "Toyota",
	toyoka_crown = "Toyota",
	toyoka_lc200 = "Toyota",
	toyoka_alfard = "Toyota",
	bnw_x6 = "BMWClassic", -- same cabin as the M5
	bentz_cls63s = "AMGBiturbo",
	bentz_g63 = "AMGBiturbo",
	bentz_e200 = "W212",
	bentz_e300 = "W212",
	bentz_e400 = "W213",
	lambrini_lp560 = "Gallardo",
	lambrini_lp570 = "Gallardo",
	kio_ev6 = "EV6",
	astin_db9 = "Aston",
	astin_vantage = "Aston",
	bentz_sls = "AMGSls",
	lambrini_urus = "Urus",
	lambrini_lp640 = "Murcielago",
	chevo_c6 = "C6",
	chevo_c7 = "C7",
} :: { [string]: string }

-- cars that take another model's cabin (dash, seats, steering wheel, gauges), lined up on the
-- driver's eye; rear: how far behind the eye the swap reaches (studs: front seats only, or rear too)
CarSkin.INTERIOR_DONOR = {
	porsha_gt3 = { from = "porsha_panamera", rear = 1.8 },
	bnw_x6 = { from = "bnw_m5_e60", rear = 3.6 },
	lambrini_lp560 = { from = "lambrini_lp570", rear = 1.8 },
} :: { [string]: { from: string, rear: number } }

type Template = { part: MeshPart, offset: CFrame }
type GenericWheel = { x: number, parts: { Template } }
type Imported = {
	body: { [string]: Template },
	wheel: { [string]: Template },
	plate: CFrame?,
	exhausts: { Vector3 },
	-- set for any other car model (Creator Store, bought, hand-made): parts keep
	-- their own look and each corner's wheel parts ride on our wheel
	generic: { [string]: GenericWheel }?,
	-- the model's own steering wheel (turns with the steering) and driver's eye, in ground space
	steer: { mount: CFrame, parts: { Template }, radius: number }?,
	eye: Vector3?,
	-- where the live gauges go: on the dash surface behind the wheel, facing the driver (ground space)
	cluster: CFrame?,
	-- the model's own gauge needles (parts), turned by Driving; ownGauges also counts on-screen needles
	gauges: { { kind: string, pivot: CFrame, parts: { Template } } }?,
	ownGauges: boolean?,
	clusterSize: Vector2?,
}
type Look = { material: Enum.Material, color: Color3?, reflectance: number, transparency: number, shadow: boolean }

local TRIM = Color3.fromRGB(16, 16, 18)
local LOOKS: { [string]: Look } = {
	Paint = { material = Enum.Material.SmoothPlastic, reflectance = 0.2, transparency = 0, shadow = true },
	Accent = { material = Enum.Material.SmoothPlastic, reflectance = 0.2, transparency = 0, shadow = true },
	Trim = { material = Enum.Material.SmoothPlastic, color = TRIM, reflectance = 0.05, transparency = 0, shadow = true },
	Chrome = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(196, 200, 208), reflectance = 0.45, transparency = 0, shadow = false },
	Glass = { material = Enum.Material.Glass, color = Color3.fromRGB(12, 16, 22), reflectance = 0.25, transparency = 0.25, shadow = false },
	Lamp = { material = Enum.Material.Neon, color = Color3.fromRGB(236, 243, 255), reflectance = 0, transparency = 0, shadow = false },
	Tail = { material = Enum.Material.Neon, color = Color3.fromRGB(150, 0, 6), reflectance = 0, transparency = 0, shadow = false },
	Drl = { material = Enum.Material.Neon, reflectance = 0, transparency = 0, shadow = false },
	Plate = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(232, 232, 228), reflectance = 0, transparency = 0, shadow = false },
	Interior = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(22, 22, 26), reflectance = 0, transparency = 0, shadow = false },
	Tire = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(20, 20, 22), reflectance = 0, transparency = 0, shadow = true },
	Rim = { material = Enum.Material.SmoothPlastic, reflectance = 0.3, transparency = 0, shadow = true },
	Caliper = { material = Enum.Material.SmoothPlastic, reflectance = 0.1, transparency = 0, shadow = false },
}

local bodyCache: { [string]: { [string]: Template } | false } = {}
local bodyMeta: { [string]: { [string]: any } } = {}
local importCache: { [string]: Imported | false } = {}
local wheelCache: { [string]: { [string]: Template } | false } = {}
local keepAlive: { any } = {} -- EditableMeshes must stay alive while their MeshParts render
local warned = false

local function build(layer: CarMesh.Layer): Template
	local minV = Vector3.one * math.huge
	local maxV = -Vector3.one * math.huge
	for _, v in layer.verts do
		minV = minV:Min(v)
		maxV = maxV:Max(v)
	end
	local center = (minV + maxV) / 2
	local em = AssetService:CreateEditableMesh()
	local vids = table.create(#layer.verts, 0)
	local nids = table.create(#layer.verts, 0)
	for i, v in layer.verts do
		vids[i] = em:AddVertex(v - center)
		nids[i] = em:AddNormal(layer.normals[i])
	end
	local tris = layer.tris
	for i = 1, #tris, 3 do
		local a, b, c = tris[i], tris[i + 1], tris[i + 2]
		local face = em:AddTriangle(vids[a], vids[b], vids[c])
		em:SetFaceNormals(face, { nids[a], nids[b], nids[c] })
	end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em))
	part.Size = (maxV - minV):Max(Vector3.one * 0.05)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	table.insert(keepAlive, em)
	return { part = part, offset = CFrame.new(center) }
end

local function fail(err: any)
	if not warned then
		warned = true
		warn("[CityLegends] Runtime car meshes unavailable (allow Mesh / Image APIs, or import CarModels):", err)
	end
end

local function bodyFor(id: string, class: string, lite: boolean): { [string]: Template }?
	local key = id .. (if lite then "/lite" else "")
	local cached = bodyCache[key]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, result = pcall(function()
		local layers, meta = CarMesh.build(id, class, CarBuilder.getDims(class, id) :: any, lite)
		bodyMeta[key] = meta
		local out = {}
		for name, layer in layers do
			out[name] = build(layer)
		end
		return out
	end)
	if ok then
		bodyCache[key] = result
		return result
	end
	bodyCache[key] = false
	fail(result)
	return nil
end

local function wheelFor(style: string, R: number, width: number, rimFrac: number, lite: boolean): { [string]: Template }?
	local key = string.format("%s/%.3f/%.3f/%.3f/%s", style, R, width, rimFrac, tostring(lite))
	local cached = wheelCache[key]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local ok, result = pcall(function()
		local out = {}
		for name, layer in CarMesh.wheel(style, R, width, rimFrac, lite) do
			out[name] = build(layer)
		end
		return out
	end)
	if ok then
		wheelCache[key] = result
		return result
	end
	wheelCache[key] = false
	fail(result)
	return nil
end

-- Imported model for a car (see header), read once
local readGeneric: (src: Instance, dims: { [string]: number }) -> Imported -- defined below
local transplantInterior: (out: Imported, donor: Imported, rear: number) -> () -- defined below
local MARK_REF = 4 -- Mark_RefX / Mark_RefZ sit this many studs from Mark_Origin
local function readImported(src: Instance): Imported
	local function mark(name: string): Vector3?
		local m = src:FindFirstChild(name, true)
		return if m and m:IsA("BasePart") then m.Position else nil
	end
	local o, rx, rz = mark("Mark_Origin"), mark("Mark_RefX"), mark("Mark_RefZ")
	if not (o and rx and rz) then
		local spec = Cars.get((src:GetAttribute("CarId") :: string?) or src.Name)
		local dims = CarBuilder.getDims(spec.Class, spec.Id) :: any
		local out = readGeneric(src, dims)
		-- another model's cabin (dash, seats, wheel, gauges) swapped in: see INTERIOR_DONOR
		local swap = CarSkin.INTERIOR_DONOR[src.Name]
		local folder = ReplicatedStorage:FindFirstChild("CarModels", true)
		local donorSrc = if swap and folder then folder:FindFirstChild(swap.from, true) else nil
		if swap and donorSrc then
			local dspec = Cars.ById[swap.from]
			local ok, err = pcall(function()
				local donorDims = if dspec then CarBuilder.getDims(dspec.Class, dspec.Id) :: any else dims
				transplantInterior(out, readGeneric(donorSrc :: Instance, donorDims), swap.rear)
			end)
			if not ok then
				warn("[CityLegends] interior from " .. swap.from .. " could not be used:", err)
			end
		end
		return out
	end
	local ex, ez = rx - o, rz - o
	local scale = MARK_REF / ex.Magnitude
	local frame = CFrame.fromMatrix(o, ex.Unit, ez.Unit:Cross(ex.Unit), ez.Unit)
	local function local_(p: Vector3): Vector3
		return frame:PointToObjectSpace(p) * scale
	end
	local hubW = mark("Mark_Hub")
	local hub = if hubW then local_(hubW) else Vector3.zero
	local out: Imported = { body = {}, wheel = {}, exhausts = {} }
	for _, d in src:GetDescendants() do
		if not d:IsA("MeshPart") or d.Name:sub(1, 5) == "Mark_" then
			continue
		end
		local rel = frame:ToObjectSpace(d.CFrame)
		local isWheel = d.Name:sub(1, 5) == "Wheel"
		local part = d:Clone()
		part:ClearAllChildren() -- importer SurfaceAppearances etc.; LOOKS styles the parts
		part.Size = d.Size * scale
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		local pos = rel.Position * scale - (if isWheel then hub else Vector3.zero)
		local t = { part = part, offset = CFrame.new(pos) * rel.Rotation }
		if isWheel then
			out.wheel[d.Name:sub(6)] = t
		else
			out.body[d.Name] = t
		end
	end
	local plate = mark("Mark_Plate")
	if plate then
		local p = local_(plate)
		out.plate = CFrame.lookAt(p, p + Vector3.zAxis)
	end
	local i = 1
	while true do
		local e = mark("Mark_Exhaust" .. i)
		if not e then
			break
		end
		table.insert(out.exhausts, local_(e))
		i += 1
	end
	if next(out.body) == nil then
		error("no body parts")
	end
	return out
end

--[[
	Any other car model (Toolbox / Creator Store, bought, made in Blender):
	  * forward = its VehicleSeat (A-Chassis "DriveSeat"), else its PrimaryPart,
	    else the longest side. Set a Reverse = true attribute on the model if
	    it comes out backwards.
	  * wheels = the FL / FR / RL / RR children of a "Wheels" folder (A-Chassis),
	    else parts named wheel / tire / tyre / rim, split into four corners
	  * scaled so its wheelbase matches ours; its wheels spin on our wheels
	  * only visible parts are used, and only their looks are copied (mesh,
	    colour, material, textures): scripts and everything else stay behind
]]
local KEEP_CHILD = { SurfaceAppearance = true, SpecialMesh = true, Decal = true, Texture = true, SurfaceGui = true }
local function visualClone(d: BasePart, scale: number): BasePart
	local p = d:Clone()
	for _, c in p:GetChildren() do
		if not KEEP_CHILD[c.ClassName] then
			c:Destroy()
		end
	end
	p.Size = d.Size * scale
	local sm = p:FindFirstChildOfClass("SpecialMesh")
	if sm then
		if sm.MeshType == Enum.MeshType.FileMesh then
			sm.Scale *= scale -- file meshes don't follow the part size
		end
		sm.Offset *= scale
	end
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	return p
end

function readGeneric(src: Instance, dims: { [string]: number }): Imported
	-- the model's steering wheel: an "SW" group (A-Chassis) or anything named steering wheel
	local steerRoots: { Instance } = {}
	local function isSteerName(n: string): boolean
		-- importer names like "Meshes/sw9 (1)" count too
		local k = n:lower():gsub("^meshes/", ""):gsub("%(%d+%)", ""):gsub("[%s_%-]", "")
		return k:match("^sw%d*$") ~= nil or k:find("steeringwheel") ~= nil
	end
	-- some kits call it just "Wheel", inside Misc (road wheels live in "Wheels")
	local function isMiscWheel(d: Instance): boolean
		return d.Name:lower() == "wheel" and d.Parent ~= nil and d.Parent.Name:lower() == "misc"
	end
	for _, d in src:GetDescendants() do
		if isSteerName(d.Name) or isMiscWheel(d) then
			local nested = false
			for _, r in steerRoots do
				if d:IsDescendantOf(r) then
					nested = true
					break
				end
			end
			if not nested then
				table.insert(steerRoots, d)
			end
		end
	end
	-- nothing named: the round, thin part right in front of the driver's seat
	if #steerRoots == 0 then
		local ds = src:FindFirstChild("DriveSeat", true)
		if ds and ds:IsA("BasePart") then
			local best: BasePart? = nil
			local bestScore = math.huge
			for _, d in src:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") then
					local rel = ds.CFrame:PointToObjectSpace(d.Position)
					local sz = { d.Size.X, d.Size.Y, d.Size.Z }
					table.sort(sz)
					-- a flat disc, or a disc joined to its column (two sides equal, the third different)
					local disc = sz[2] >= 0.8 and sz[3] <= 2.4 and sz[3] / sz[2] < 1.35 and sz[1] < sz[2] * 0.6
					local onColumn = sz[1] >= 0.9 and sz[2] <= 2.0 and sz[2] / sz[1] < 1.15 and sz[3] <= 2.6 and sz[3] > sz[2] * 1.2
					local round = disc or onColumn
					if round and math.abs(rel.X) < 0.8 and rel.Y > 0.6 and rel.Y < 3.5 and rel.Z < -0.5 and rel.Z > -3.5 then
						local score = math.abs(rel.X) + math.abs(rel.Z + 1.6) * 0.5
						if score < bestScore then
							best, bestScore = d, score
						end
					end
				end
			end
			if best then
				table.insert(steerRoots, best)
				-- the other pieces of the same wheel (spokes, centre, buttons) sit right around it
				local bigSide = math.max(best.Size.X, best.Size.Y, best.Size.Z)
				for _, d in src:GetDescendants() do
					if d ~= best and d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") then
						local close = (d.Position - best.Position).Magnitude < bigSide * 0.35
						if close and math.max(d.Size.X, d.Size.Y, d.Size.Z) <= bigSide * 1.1 then
							table.insert(steerRoots, d)
						end
					end
				end
			end
		end
	end
	local function inSteer(d: Instance): boolean
		for _, r in steerRoots do
			if d == r or d:IsDescendantOf(r) then
				return true
			end
		end
		return false
	end

	local visible: { BasePart } = {}
	for _, d in src:GetDescendants() do
		-- HideInGame: a piece we replace ourselves (e.g. a wheel centre fused with the gauge pod)
		if d:IsA("BasePart") and d.Transparency < 0.98 and not d:IsA("Seat") and not d:IsA("VehicleSeat") and not d:GetAttribute("HideInGame") then
			table.insert(visible, d)
		end
	end
	if #visible == 0 then
		error("no visible parts")
	end
	local minV, maxV = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in visible do
		minV = minV:Min(d.Position)
		maxV = maxV:Max(d.Position)
	end
	-- forward direction
	local driveSeat = src:FindFirstChild("DriveSeat", true)
	local seat = if driveSeat and driveSeat:IsA("VehicleSeat") then driveSeat else src:FindFirstChildWhichIsA("VehicleSeat", true)
	local primary = if src:IsA("Model") then src.PrimaryPart else nil
	local f: Vector3
	if seat then
		f = seat.CFrame.LookVector
	elseif primary then
		f = primary.CFrame.LookVector
	else
		-- chassis corner parts (FL / FR / RL / RR) tell the front from the back
		local function corner(n: string): Vector3?
			local p = src:FindFirstChild(n)
			return if p and p:IsA("BasePart") then p.Position else nil
		end
		local fl, fr, rl, rr = corner("FL"), corner("FR"), corner("RL"), corner("RR")
		if fl and fr and rl and rr then
			f = (fl + fr - rl - rr) / 2
		else
			local ext = maxV - minV
			f = if ext.X > ext.Z then Vector3.xAxis else -Vector3.zAxis
		end
	end
	f = Vector3.new(f.X, 0, f.Z)
	if f.Magnitude < 1e-3 then
		error("can't tell which way the car faces")
	end
	f = f.Unit
	if src:GetAttribute("Reverse") == true then
		f = -f
	end
	local right = f:Cross(Vector3.yAxis)

	-- wheel groups
	type Group = { parts: { BasePart }, center: Vector3 }
	local groups: { Group } = {}
	local inWheel: { [BasePart]: boolean } = {}
	local function centerOf(list: { BasePart }): Vector3
		local a, b = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in list do
			a = a:Min(d.Position - d.Size / 2)
			b = b:Max(d.Position + d.Size / 2)
		end
		return (a + b) / 2
	end
	local wheelsNode = src:FindFirstChild("Wheels", true)
	if wheelsNode then
		for _, c in wheelsNode:GetChildren() do
			local list: { BasePart } = {}
			for _, d in visible do
				if d == c or d:IsDescendantOf(c) then
					table.insert(list, d)
				end
			end
			if #list > 0 then
				table.insert(groups, { parts = list, center = if c:IsA("BasePart") then c.Position else centerOf(list) })
			end
		end
	end
	if #groups ~= 4 then
		groups = {}
		local cand: { BasePart } = {}
		for _, d in visible do
			local n = d.Name:lower():gsub("trim", "") -- "trims" is not a rim
			if (n:find("wheel") or n:find("tire") or n:find("tyre") or n:find("rim")) and not n:find("steer") and not inSteer(d) then
				table.insert(cand, d)
			end
		end
		if #cand >= 4 then
			local c0 = centerOf(cand)
			local quads: { [string]: { BasePart } } = {}
			for _, d in cand do
				local rel = d.Position - c0
				local key = (if rel:Dot(f) > 0 then "F" else "R") .. (if rel:Dot(right) > 0 then "R" else "L")
				quads[key] = quads[key] or {}
				table.insert(quads[key], d)
			end
			for _, list in quads do
				table.insert(groups, { parts = list, center = centerOf(list) })
			end
		end
	end
	if #groups ~= 4 then
		error("couldn't find 4 wheels: put them in a 'Wheels' folder as FL, FR, RL, RR")
	end
	for _, g in groups do
		for _, d in g.parts do
			inWheel[d] = true
		end
	end
	-- the rest of each wheel: a tyre found by name often shares its own small group with the rim
	-- and hub (named anything); those parts spin with it too
	for _, g in groups do
		local size = 0
		for _, d in g.parts do
			size = math.max(size, d.Size.X, d.Size.Y, d.Size.Z)
		end
		local seen: { [Instance]: boolean } = {}
		for _, d in table.clone(g.parts) do
			local holder = d.Parent
			if not holder or holder == src or seen[holder] or not (holder:IsA("Model") or holder:IsA("Folder")) then
				continue
			end
			seen[holder] = true
			local all: { BasePart } = {}
			local tight = true
			for _, x in visible do
				if x:IsDescendantOf(holder) then
					table.insert(all, x)
					if (x.Position - g.center).Magnitude > size * 0.75 then
						tight = false
					end
				end
			end
			if tight and #all <= 16 then
				for _, x in all do
					if not inWheel[x] then
						inWheel[x] = true
						table.insert(g.parts, x)
					end
				end
			end
		end
	end
	local mid = Vector3.zero
	for _, g in groups do
		mid += g.center / 4
	end
	local frontZ, rearZ, nf, nr = 0, 0, 0, 0
	for _, g in groups do
		local a = (g.center - mid):Dot(f)
		if a > 0 then
			frontZ += a
			nf += 1
		else
			rearZ += a
			nr += 1
		end
	end
	if nf ~= 2 or nr ~= 2 then
		error("wheels are not two at the front and two at the back")
	end
	local wheelbase = (frontZ - rearZ) / 2
	local scale = math.clamp(dims.wb / math.max(wheelbase, 1e-3), 0.02, 50)
	-- wheel radius in the model's own studs (dims.wheelR is the same wheel at our scale)
	local modelR = dims.wheelR / scale
	-- stray props shipped with some models (stands, spare parts beside the car): anything whose
	-- centre is well outside the body around the wheels is left out
	do
		local track = 0
		for _, g in groups do
			track = math.max(track, math.abs((g.center - mid):Dot(right)))
		end
		local kept: { BasePart } = {}
		for _, d in visible do
			local rel = d.Position - mid
			local along, side, up = math.abs(rel:Dot(f)), math.abs(rel:Dot(right)), rel.Y
			if inWheel[d] or (along <= wheelbase * 1.0 and side <= track + wheelbase * 0.25 and up <= wheelbase * 0.8 and up >= -wheelbase * 0.3) then
				table.insert(kept, d)
			end
		end
		visible = kept
	end
	-- ground frame: its wheel centres land at our wheel height
	local origin = Vector3.new(mid.X, mid.Y - modelR, mid.Z)
	local frame = CFrame.lookAt(origin, origin + f)
	local function tmpl(d: BasePart, about: Vector3): Template
		local rel = frame:ToObjectSpace(d.CFrame)
		return { part = visualClone(d, scale) :: any, offset = CFrame.new(rel.Position * scale - about) * rel.Rotation }
	end
	local out: Imported = { body = {}, wheel = {}, exhausts = {}, generic = {} }

	-- steering wheel: turns about its own thinnest axis, pointing into the dash
	local steerParts: { BasePart } = {}
	local biggest: BasePart? = nil
	for _, d in visible do
		if not inWheel[d] and inSteer(d) then
			table.insert(steerParts, d)
			if not biggest or d.Size.Magnitude > biggest.Size.Magnitude then
				biggest = d
			end
		end
	end
	if biggest then
		-- the whole wheel's extent along the biggest piece's own sides (one piece can be just part
		-- of the rim, e.g. the Urus's flat-bottomed wheel)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in steerParts do
			local h = d.Size / 2
			for _, c in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
				local q = biggest.CFrame:PointToObjectSpace(d.CFrame:PointToWorldSpace(h * c))
				lo = lo:Min(q)
				hi = hi:Max(q)
			end
		end
		local sz = hi - lo
		-- the turning axis is the side that differs most from the other two (thin disc, or long column)
		local ex = { sz.X, sz.Y, sz.Z }
		local vecs = { biggest.CFrame.RightVector, biggest.CFrame.UpVector, biggest.CFrame.LookVector }
		local odd, oddScore = 1, -1
		for i = 1, 3 do
			local a2, b2 = ex[i % 3 + 1], ex[(i + 1) % 3 + 1]
			local score = math.min(math.abs(ex[i] - a2), math.abs(ex[i] - b2))
			if score > oddScore then
				odd, oddScore = i, score
			end
		end
		local axis = vecs[odd]
		local discSize = math.max(ex[odd % 3 + 1], ex[(odd + 1) % 3 + 1])
		if axis:Dot(f) < 0 then
			axis = -axis
		end
		local a, b = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, d in steerParts do
			a = a:Min(d.Position)
			b = b:Max(d.Position)
		end
		local center = (a + b) / 2
		if ex[odd] > discSize and #steerParts == 1 then
			-- wheel and column in one piece: the rim is at the driver's end
			center -= axis * (ex[odd] / 2 - 0.2)
		end
		local mountWorld = CFrame.lookAt(center, center + axis)
		local mountRel = frame:ToObjectSpace(mountWorld)
		local mount = CFrame.new(mountRel.Position * scale) * mountRel.Rotation
		local parts = {}
		for _, d in steerParts do
			local t = tmpl(d, Vector3.zero)
			t.offset = mount:Inverse() * t.offset
			table.insert(parts, t)
		end
		local radius = discSize / 2 * scale * 0.9
		if src:GetAttribute("AddSteerHub") then
			-- the model's wheel centre is fused with something else and hidden: build one
			local function hubPiece(size: Vector3, color: Color3, material: Enum.Material, z: number): Template
				local p = Instance.new("Part")
				p.Shape = Enum.PartType.Cylinder
				p.Size = size
				p.Color = color
				p.Material = material
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.Massless = true
				p.CastShadow = false
				return { part = p, offset = CFrame.new(0, 0, z) * CFrame.Angles(0, math.pi / 2, 0) }
			end
			table.insert(parts, hubPiece(Vector3.new(0.18, radius * 0.95, radius * 0.95), Color3.fromRGB(16, 16, 18), Enum.Material.SmoothPlastic, 0.02))
			table.insert(parts, hubPiece(Vector3.new(0.04, radius * 0.2, radius * 0.2), Color3.fromRGB(235, 190, 20), Enum.Material.SmoothPlastic, 0.12)) -- small yellow dot, no glow
			for _, ang in { 0, math.pi } do
				local spoke = Instance.new("Part")
				spoke.Size = Vector3.new(radius * 0.75, 0.16, 0.08)
				spoke.Color = Color3.fromRGB(232, 232, 236)
				spoke.Material = Enum.Material.SmoothPlastic
				spoke.CanCollide = false
				spoke.CanQuery = false
				spoke.CanTouch = false
				spoke.Massless = true
				spoke.CastShadow = false
				table.insert(parts, { part = spoke, offset = CFrame.Angles(0, 0, ang) * CFrame.new(radius * 0.55, -0.04, 0) })
			end
		end
		out.steer = { mount = mount, parts = parts, radius = radius }
	end

	-- driver's eye: above the driver's seat, at 80% of the roof height there
	local seatPart = seat or src:FindFirstChildWhichIsA("Seat", true)
	local sp: Vector3? = if seatPart then frame:PointToObjectSpace(seatPart.Position) else nil
	if not sp then
		-- no seat in the model: put the driver where a real one sits, left of centre
		-- (left-hand drive) and a little behind the front axle (sports coupe: ~1.35 m)
		local m = 3 / scale -- model studs per metre (game is 3 studs per metre)
		local axleZ, n = 0, 0
		for _, g in groups do
			local c = frame:PointToObjectSpace(g.center)
			if c.Z < 0 then
				axleZ += c.Z
				n += 1
			end
		end
		if n > 0 then
			sp = Vector3.new(-0.37 * m, 0.35 * m, axleZ / n + 1.35 * m)
		end
	end
	if sp then
		local roof = 0
		for _, d in visible do
			if inWheel[d] then
				continue
			end
			local rel = frame:ToObjectSpace(d.CFrame)
			local h = d.Size / 2
			local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
			for _, c in { Vector3.new(1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(1, -1, 1), Vector3.new(1, -1, -1), Vector3.new(-1, 1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, -1, -1) } do
				local q = rel * (h * c)
				lo = lo:Min(q)
				hi = hi:Max(q)
			end
			if sp.X >= lo.X and sp.X <= hi.X and sp.Z >= lo.Z and sp.Z <= hi.Z then
				roof = math.max(roof, hi.Y)
			end
		end
		if roof > 0 then
			local lift = (src:GetAttribute("EyeHeight") :: number?) or 0 -- per-car tweak, in studs
			out.eye = Vector3.new(sp.X * scale, roof * scale * 0.8 + lift, sp.Z * scale + 0.3)
		end
	end

	-- no separate steering wheel in the model (fused into one interior mesh, or none at all):
	-- build our own round wheel where a real one sits, a short reach in front of the driver
	if not out.steer and out.eye then
		local R, tube = 0.56, 0.14 -- real wheel: ~37 cm across, ~4.5 cm thick grip
		local center = out.eye + Vector3.new(0, -1.05, -1.75)
		local tilt = math.rad(24)
		local mount = CFrame.lookAt(center, center + Vector3.new(0, -math.sin(tilt), -math.cos(tilt)))
		local function piece(shape: Enum.PartType, size: Vector3, color: Color3, material: Enum.Material): Part
			local p = Instance.new("Part")
			p.Shape = shape
			p.Size = size
			p.Color = color
			p.Material = material
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.CastShadow = false
			return p
		end
		local leather = Color3.fromRGB(24, 24, 27)
		local silver = Color3.fromRGB(196, 200, 208)
		-- Mercedes: AMG-style flat-bottomed rim, silver spokes and the three-pointed star
		local merc = src.Name:sub(1, 6) == "bentz_" or src.Name:sub(1, 7) == "brabos_"
		local parts: { Template } = {}
		local segs = 28
		for i = 0, segs - 1 do
			local ang = i / segs * math.pi * 2
			if merc and math.abs(ang - math.pi * 1.5) < math.rad(32) then
				continue -- the flat bottom goes here
			end
			local seg = piece(Enum.PartType.Cylinder, Vector3.new(2 * math.pi * R / segs * 1.18, tube, tube), leather, Enum.Material.SmoothPlastic)
			table.insert(parts, { part = seg :: any, offset = CFrame.new(R * math.cos(ang), R * math.sin(ang), 0) * CFrame.Angles(0, 0, ang + math.pi / 2) })
		end
		if merc then
			local half = R * math.sin(math.rad(36))
			local flat = piece(Enum.PartType.Cylinder, Vector3.new(half * 2, tube, tube), leather, Enum.Material.SmoothPlastic)
			table.insert(parts, { part = flat :: any, offset = CFrame.new(0, -R * math.cos(math.rad(36)), 0) })
		end
		-- three spokes (left, right, bottom) and a round airbag hub
		for _, ang in { 0, math.pi, -math.pi / 2 } do
			local spoke = piece(Enum.PartType.Block, Vector3.new(R * 0.9, 0.13, 0.07), if merc then silver else Color3.fromRGB(46, 46, 52), if merc then Enum.Material.Metal else Enum.Material.SmoothPlastic)
			table.insert(parts, { part = spoke :: any, offset = CFrame.Angles(0, 0, ang) * CFrame.new(R * 0.5, 0, 0.03) })
		end
		local hub = piece(Enum.PartType.Cylinder, Vector3.new(0.16, R * 0.78, R * 0.78), Color3.fromRGB(20, 20, 22), Enum.Material.SmoothPlastic)
		table.insert(parts, { part = hub :: any, offset = CFrame.new(0, 0, 0.06) * CFrame.Angles(0, math.pi / 2, 0) })
		if merc then
			-- the star: a thin silver ring with three points
			local ring = R * 0.13
			for i = 0, 15 do
				local ang = i / 16 * math.pi * 2
				local seg = piece(Enum.PartType.Block, Vector3.new(2 * math.pi * ring / 16 * 1.2, 0.012, 0.02), silver, Enum.Material.Metal)
				table.insert(parts, { part = seg :: any, offset = CFrame.new(ring * math.cos(ang), ring * math.sin(ang), 0.15) * CFrame.Angles(0, 0, ang + math.pi / 2) })
			end
			for _, ang in { math.pi / 2, math.pi / 2 + math.pi * 2 / 3, math.pi / 2 - math.pi * 2 / 3 } do
				local point = piece(Enum.PartType.Block, Vector3.new(ring, 0.014, 0.02), silver, Enum.Material.Metal)
				table.insert(parts, { part = point :: any, offset = CFrame.Angles(0, 0, ang) * CFrame.new(ring / 2, 0, 0.15) })
			end
		else
			local badge = piece(Enum.PartType.Cylinder, Vector3.new(0.02, R * 0.22, R * 0.22), silver, Enum.Material.Metal)
			table.insert(parts, { part = badge :: any, offset = CFrame.new(0, 0, 0.15) * CFrame.Angles(0, math.pi / 2, 0) })
		end
		local column = piece(Enum.PartType.Cylinder, Vector3.new(0.9, 0.26, 0.26), leather, Enum.Material.SmoothPlastic)
		table.insert(parts, { part = column :: any, offset = CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi / 2, 0) })
		out.steer = { mount = mount, parts = parts, radius = R * 0.95 }
	end

	-- the driver sits a real reach behind the wheel (~60 cm): some models' seats put the eye too close
	if out.steer and out.eye then
		local wz = out.steer.mount.Position.Z
		local eye = out.eye :: Vector3
		if eye.Z - wz < 1.4 then
			out.eye = Vector3.new(eye.X, eye.Y, math.min(wz + 1.4, eye.Z + 0.3))
		end
	end

	-- gauges: look from the eye through the top half of the wheel and stop at the first
	-- dash surface past it (that's where the car's own instrument cluster is)
	if out.eye then
		local eyeW = frame:PointToWorldSpace(out.eye / scale)
		local fwdW = frame.LookVector
		local target: Vector3
		local minDist: number
		local rm: number -- wheel radius, model studs
		if out.steer then
			local mountW = frame * CFrame.new(out.steer.mount.Position / scale)
			rm = out.steer.radius / scale
			target = mountW.Position + Vector3.yAxis * rm * 0.35
			minDist = (target - eyeW).Magnitude + 0.15 / scale
		else
			rm = 0.5 / scale
			target = eyeW + fwdW * (2.2 / scale) - Vector3.yAxis * (0.75 / scale)
			minDist = 1.2 / scale
		end
		local dir = (target - eyeW).Unit
		local best = math.huge
		for _, d in visible do
			if inWheel[d] or inSteer(d) then
				continue
			end
			local o = d.CFrame:PointToObjectSpace(eyeW)
			local h = d.Size / 2
			if math.abs(o.X) <= h.X and math.abs(o.Y) <= h.Y and math.abs(o.Z) <= h.Z then
				continue -- a shell around the driver (whole-cabin mesh): not a dash surface
			end
			local v = d.CFrame:VectorToObjectSpace(dir)
			local tmin, tmax = -math.huge, math.huge
			local hit = true
			for _, ax in { "X", "Y", "Z" } do
				local oa, va, ha = (o :: any)[ax], (v :: any)[ax], (h :: any)[ax]
				if math.abs(va) < 1e-6 then
					if math.abs(oa) > ha then
						hit = false
						break
					end
				else
					local t1, t2 = (-ha - oa) / va, (ha - oa) / va
					tmin = math.max(tmin, math.min(t1, t2))
					tmax = math.min(tmax, math.max(t1, t2))
				end
			end
			if hit and tmax >= tmin and tmin > minDist and tmin < best then
				best = tmin
			end
		end
		local ownDesign = CarSkin.CLUSTER_STYLE[src.Name] ~= nil
		-- how far past the wheel the car's real cluster sits (studs); the Aventador's is deep in its hood
		local depth = if src.Name == "lambrini_lp700" then 1.0 else 0.45
		local t = if best < 4 / scale * 3 and not ownDesign then best - 0.03 / scale else (target - eyeW).Magnitude + depth / scale
		local posW = eyeW + dir * t
		local pos = frame:PointToObjectSpace(posW) * scale
		local eyeG = out.eye
		out.cluster = CFrame.lookAt(pos, pos + (pos - eyeG).Unit) -- back face looks at the driver
		local r = rm * scale
		-- full-width clusters (rev counter + two side screens) are about as wide as the wheel
		out.clusterSize = if ownDesign then Vector2.new(r * 2.3, r * 0.85) else Vector2.new(r * 1.7, r * 0.62)
	end

	-- the model's own gauge needles: turned live by Driving (speed / revs)
	local gaugeOf: { [BasePart]: boolean } = {}
	if out.eye then
		local function kindOf(d: Instance): string?
			local a: Instance? = d.Parent
			while a and a ~= src do
				local n = a.Name:lower()
				if n == "spdn" or n == "tacn" then
					return nil -- tick marks, not needles
				end
				if n:find("speed") or n:find("spd") then
					return "speed"
				end
				if n:find("tach") or n:find("tac") or n:find("rpm") then
					return "rpm"
				end
				a = a.Parent
			end
			local n = d.Name:lower()
			return if n:find("speed") then "speed" elseif n:find("rpm") or n:find("tach") then "rpm" else nil
		end
		local gauges = {}
		local pivots: { { pos: Vector3, kind: string } } = {}
		for _, d in visible do
			local n = d.Name:lower()
			if not inWheel[d] and not inSteer(d) and (n:find("needle") or n:find("arrow")) and not n:find("blinker") then
				local kind = kindOf(d)
				-- one needle per dial: a second piece of the same dial only hides
				local dup = false
				if kind then
					for _, pv in pivots do
						if pv.kind == kind and (pv.pos - d.Position).Magnitude < 0.5 then
							dup = true
						end
					end
				end
				if dup or (kind and CarSkin.CLUSTER_STYLE[src.Name]) then
					gaugeOf[d] = true
				elseif kind then
					-- turns about the small hub part next to it, else about itself
					local pivotPos = d.Position
					for _, sib in (d.Parent :: Instance):GetChildren() do
						if sib ~= d and sib:IsA("BasePart") and not sib.Name:lower():find("needle") and (sib.Position - d.Position).Magnitude < 0.6 then
							pivotPos = sib.Position
							break
						end
					end
					table.insert(pivots, { pos = pivotPos, kind = kind })
					local pv = frame:PointToObjectSpace(pivotPos) * scale
					local eyeG = out.eye :: Vector3
					local pivot = CFrame.lookAt(pv, pv + (pv - eyeG).Unit) -- +Z looks at the driver
					-- a slim red needle from the hub, pointing where the model's needle rests
					local tip = pivot:PointToObjectSpace(frame:PointToObjectSpace(d.Position) * scale)
					local rest = Vector3.new(tip.X, tip.Y, 0)
					local len: number
					if rest.Magnitude > 0.02 then
						len = rest.Magnitude * 2
						rest = rest.Unit
					else
						len = math.max(d.Size.X, d.Size.Y, d.Size.Z) * scale
						rest = Vector3.new(-0.7, -0.7, 0).Unit -- needle at rest: about 7 o'clock
					end
					len = math.clamp(len, 0.2, 0.6)
					-- a thin red line (no neon glow: it made the needle look thick)
					local needle = Instance.new("Part")
					needle.Size = Vector3.new(0.016, 0.016, len)
					needle.Color = Color3.fromRGB(235, 30, 30)
					needle.Material = Enum.Material.SmoothPlastic
					needle.CanCollide = false
					needle.CanQuery = false
					needle.CanTouch = false
					needle.Massless = true
					needle.CastShadow = false
					local offset = CFrame.lookAt(rest * len / 2 + Vector3.new(0, 0, 0.01), rest * len + Vector3.new(0, 0, 0.01))
					gaugeOf[d] = true
					table.insert(gauges, { kind = kind, pivot = pivot, parts = { { part = needle, offset = offset } } })
				end
			end
		end
		-- the model's own static needles next to a dial we drive (e.g. "Gauge Arrows") are hidden
		for _, d in visible do
			local n = d.Name:lower()
			if not gaugeOf[d] and (n:find("needle") or n:find("arrow")) and not n:find("blinker") then
				for _, pv in pivots do
					if (pv.pos - d.Position).Magnitude < 0.6 then
						gaugeOf[d] = true
						break
					end
				end
			end
		end
		out.gauges = gauges
		out.ownGauges = #gauges > 0
		for _, d in visible do
			local gui = d:FindFirstChildWhichIsA("SurfaceGui")
			if gui and gui:FindFirstChild("Needle", true) then
				out.ownGauges = true
				break
			end
		end
	end

	-- every rough surface becomes smooth: Roblox's Sand / Fabric / Leather / Concrete etc. carry a
	-- bumpy pattern that makes interiors look grainy up close
	local ROUGH = {
		Sand = true, Fabric = true, Leather = true, Concrete = true, Granite = true, Slate = true,
		Cobblestone = true, Pebble = true, Brick = true, Wood = true, WoodPlanks = true, Marble = true,
		CorrodedMetal = true, DiamondPlate = true, Foil = true, Plastic = true, Rubber = true, Asphalt = true,
		Basalt = true, Rock = true, Ground = true,
	}
	local function cabinMaterial(d: BasePart, p: BasePart)
		if ROUGH[d.Material.Name] then
			p.Material = Enum.Material.SmoothPlastic
			p:SetAttribute("Trim", true) -- upholstery-like: a cabin swap can take out bigger pieces of it
		end
	end

	local k = 0
	for _, d in visible do
		if not inWheel[d] and not (out.steer and inSteer(d)) and not gaugeOf[d] then
			k += 1
			local t = tmpl(d, Vector3.zero)
			t.part:SetAttribute("SrcName", d.Name) -- on-screen gauges are found by these names
			cabinMaterial(d, t.part)
			out.body["Part" .. k] = t
		end
	end
	local generic = out.generic :: { [string]: GenericWheel }
	for _, g in groups do
		local c = frame:PointToObjectSpace(g.center) * scale
		local key = (if c.Z < 0 then "F" else "R") .. (if c.X < 0 then "L" else "R")
		local parts = {}
		for _, d in g.parts do
			table.insert(parts, tmpl(d, c))
		end
		generic[key] = { x = c.X, parts = parts }
	end
	return out
end

-- cabin parts: inside the body around the driver, not glass, and not a whole-body shell (big
-- upholstered shells narrower than the body are the old cabin's lining and seats: they go too)
local function inCabin(t: Template, eye: Vector3, halfW: number, rear: number): boolean
	local p, s = t.offset.Position, t.part.Size
	if t.part.Transparency >= 0.3 or t.part.Material == Enum.Material.Glass then
		return false
	end
	if math.max(s.X, s.Y, s.Z) > 9 then
		local cf = t.offset
		local width = math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z
		if not (t.part:GetAttribute("Trim") and width <= halfW * 2.64 and math.max(s.X, s.Y, s.Z) <= 12) then
			return false
		end
	end
	return math.abs(p.X) < halfW and p.Z > eye.Z - 3.4 and p.Z < eye.Z + rear and p.Y > 0.3 and p.Y < eye.Y + 0.4
end

local function cabinHalfWidth(out: Imported): number
	local w = math.huge
	local generic = out.generic
	if generic then
		for _, g in generic do
			w = math.min(w, math.abs(g.x))
		end
	end
	return if w < math.huge then w * 0.85 else 2
end

function transplantInterior(out: Imported, donor: Imported, rear: number)
	local eye, deye = out.eye, donor.eye
	if not (eye and deye) then
		error("no driver's seat to line the cabins up on")
	end
	local halfW = math.min(cabinHalfWidth(out), cabinHalfWidth(donor))
	-- lined up on the eye's height and seat position; sideways the donor's own layout is kept
	-- (both are centred on the car), and the camera moves to its driver's seat
	local shift = CFrame.new(0, eye.Y - deye.Y, eye.Z - deye.Z)
	out.eye = Vector3.new(deye.X, eye.Y, eye.Z)
	local body: { [string]: Template } = {}
	for name, t in out.body do
		if not inCabin(t, eye, halfW, rear) then
			body[name] = t
		end
	end
	local k = 0
	for _, t in donor.body do
		if inCabin(t, deye, halfW, rear) then
			k += 1
			body["Cabin" .. k] = { part = t.part, offset = shift * t.offset }
		end
	end
	out.body = body
	out.steer = if donor.steer then { mount = shift * donor.steer.mount, parts = donor.steer.parts, radius = donor.steer.radius } else nil
	local gauges = {}
	if donor.gauges then
		for _, gauge in donor.gauges do
			table.insert(gauges, { kind = gauge.kind, pivot = shift * gauge.pivot, parts = gauge.parts })
		end
	end
	out.gauges = gauges
	out.ownGauges = donor.ownGauges
	out.cluster = if donor.cluster then shift * donor.cluster else nil
	out.clusterSize = donor.clusterSize
end

local function importedFor(id: string): Imported?
	local cached = importCache[id]
	if cached ~= nil then
		return if cached then cached else nil
	end
	local folder = ReplicatedStorage:FindFirstChild("CarModels", true) -- anywhere in ReplicatedStorage
	local alias = CarBuilder.MODEL_ALIAS[id]
	local src = if folder then folder:FindFirstChild(id, true) or (if alias then folder:FindFirstChild(alias, true) else nil) else nil
	local result: Imported? = nil
	if src then
		local ok, res = pcall(readImported, src)
		if ok then
			result = res
		else
			warn("[CityLegends] CarModels/" .. id .. " could not be used:", res)
		end
	end
	importCache[id] = result or false
	return result
end

-- Build the meshes ahead of time (loading screen): every traffic design plus the given full ones
function CarSkin.preload(fullIds: { string }?)
	-- lite meshes only for the cars traffic uses (all 55 would exceed the mesh memory budget)
	for _, id in CarBuilder.TRAFFIC_POOL do
		local spec = Cars.get(id)
		bodyFor(spec.Id, spec.Class, true)
		task.wait()
	end
	-- read every imported model in the background, so opening one in the garage doesn't hitch
	task.spawn(function()
		for _, spec in Cars.List do
			importedFor(spec.Id)
			task.wait(0.05)
		end
	end)
	local full: { string } = fullIds or {}
	for _, id in full do
		local spec = Cars.get(id)
		if not importedFor(spec.Id) then
			bodyFor(spec.Id, spec.Class, false)
			task.wait()
		end
	end
end

-- The knuckle joint for a wheel joint (steer only), if the car is skinned
function CarSkin.knuckleFor(wheelMotor: Motor6D): Motor6D?
	local root = wheelMotor.Part0
	if not root then
		return nil
	end
	return root:FindFirstChild("Knuckle_" .. wheelMotor.Name:sub(7)) :: Motor6D?
end

local function place(t: Template, name: string, look: Look, color: Color3, cf: CFrame, weldTo: BasePart, parent: Instance, scale: number?): MeshPart
	local p = t.part:Clone()
	local k = scale or 1
	p.Name = name
	p.Material = look.material
	p.Color = look.color or color
	p.Reflectance = look.reflectance
	p.Transparency = look.transparency
	p.CastShadow = look.shadow
	if k ~= 1 then
		p.Size *= k
		p.CFrame = cf * CFrame.new(t.offset.Position * k) * t.offset.Rotation
	else
		p.CFrame = cf * t.offset
	end
	p.Parent = parent
	local w = Instance.new("WeldConstraint")
	w.Part0 = weldTo
	w.Part1 = p
	w.Parent = p
	return p
end

--[[
	destroyReplaced: true for local-only models (traffic, cutscene, garage
	preview) - the old bodywork is deleted. For replicated player cars it is
	hidden with LocalTransparencyModifier instead.
	lite: lighter meshes (traffic)
]]
function CarSkin.apply(model: Model, destroyReplaced: boolean?, lite: boolean?): boolean
	if model:GetAttribute("Skinned") then
		return true
	end
	local id = model:GetAttribute("CarId")
	local class = model:GetAttribute("Class")
	local root = model.PrimaryPart
	if type(id) ~= "string" or type(class) ~= "string" or not root then
		return false
	end
	local liteMode = lite == true
	-- imported models first for the cars you look at; runtime lite meshes first for traffic
	local imported = if liteMode then nil else importedFor(id)
	local body = if imported then imported.body else bodyFor(id, class, liteMode)
	if not body then
		imported = importedFor(id)
		body = if imported then imported.body else nil
	end
	if not body then
		return false
	end
	local meta = if imported then { plate = imported.plate, exhausts = imported.exhausts } else bodyMeta[id .. (if liteMode then "/lite" else "")]
	local spec = Cars.get(id)
	local dims = CarBuilder.getDims(class, id)
	local design = CarMesh.design(id, class, dims :: any)
	local height = (model:GetAttribute("Height") :: number?) or dims.H
	local groundCF = root.CFrame * CFrame.new(0, -height / 2, 0)

	-- paint comes from the built car (traffic gets random colours)
	local paintSrc = model:FindFirstChild("DoorL") or model:FindFirstChild("Tail")
	local paint = if paintSrc and paintSrc:IsA("BasePart") then paintSrc.Color else spec.Color
	local accent = spec.Accent or Color3.fromRGB(18, 18, 20)

	local skin = Instance.new("Model")
	skin.Name = "Skin"
	skin.Parent = model
	local drl = if design.drl then Color3.fromRGB(design.drl[1], design.drl[2], design.drl[3]) else Color3.new(1, 1, 1)
	local generic = if imported then imported.generic else nil
	for name, t in body do
		if generic then
			local p = t.part:Clone()
			p.Name = "Skin" .. name
			p.CFrame = groundCF * t.offset
			p.Parent = skin
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p
			continue
		end
		local base = name:match("^%a+") or name -- "Paint2" is the second half of a big layer
		local look = LOOKS[base] or LOOKS.Paint
		local color = if base == "Accent" then accent elseif base == "Drl" then drl else paint
		local p = place(t, "Skin" .. name, look, color, groundCF, root, skin)
		if base == "Tail" then
			p:SetAttribute("TailLight", true)
		end
	end

	if generic and imported then
		-- the model's own steering wheel: welded still here; Driving turns it on the local player's car
		local steer = imported.steer
		local eyeRoot = if imported.eye then imported.eye - Vector3.new(0, height / 2, 0) else nil
		if steer then
			local mountRoot = root.CFrame:Inverse() * groundCF * steer.mount
			model:SetAttribute("SteerMount", mountRoot)
			for i, t in steer.parts do
				local p = t.part:Clone()
				p.Name = "SkinSteer" .. i
				p.CFrame = groundCF * steer.mount * t.offset
				p:SetAttribute("SteerOffset", t.offset)
				p.Parent = skin
				local w = Instance.new("Weld")
				w.Part0 = root
				w.Part1 = p
				w.C0 = mountRoot * t.offset
				w.Parent = p
			end
			-- where Driving's arms grip (10 and 2) and where the shoulders sit
			if eyeRoot then
				local r = steer.radius
				model:SetAttribute("SteerRadius", r)
				for side, ang in { L = math.rad(160), R = math.rad(20) } do
					local sx = if side == "L" then -1 else 1
					model:SetAttribute("Grip" .. side, Vector3.new(r * 0.9 * math.cos(ang), r * 0.9 * math.sin(ang), 0.24))
					model:SetAttribute("Shoulder" .. side, eyeRoot + Vector3.new(sx * 0.62, -0.7, 0.43))
				end
				model:SetAttribute("ArmsFitted", true)
			end
		end
		-- the model's own needles: welded still here; Driving turns them on the local player's car
		for gi, gauge in imported.gauges or {} do
			local pivotRoot = root.CFrame:Inverse() * groundCF * gauge.pivot
			for i, t in gauge.parts do
				local p = t.part:Clone()
				p.Name = "SkinGauge" .. gi .. "_" .. i
				p.CFrame = groundCF * gauge.pivot * t.offset
				p:SetAttribute("GaugeKind", gauge.kind)
				p:SetAttribute("GaugePivot", pivotRoot)
				p:SetAttribute("GaugeOffset", t.offset)
				p.Parent = skin
				local w = Instance.new("Weld")
				w.Part0 = root
				w.Part1 = p
				w.C0 = pivotRoot * t.offset
				w.Parent = p
			end
		end
		-- live instrument cluster on the car's own gauge spot, when it has no working gauges of its own
		-- (cars with their own design here, like the Ferrari, always get it)
		local ownDesign = CarSkin.CLUSTER_STYLE[id] ~= nil
		if imported.cluster and imported.clusterSize and not liteMode and (ownDesign or not imported.ownGauges) then
			local cluster = Instance.new("Part")
			cluster.Name = "DashCluster"
			cluster.Size = Vector3.new(imported.clusterSize.X, imported.clusterSize.Y, 0.02)
			cluster.Transparency = 1
			cluster.CanCollide = false
			cluster.CanQuery = false
			cluster.CanTouch = false
			cluster.Massless = true
			cluster.CastShadow = false
			-- per-car nudges set in Studio on the model: ClusterUp / ClusterForward (studs), ClusterSize (x)
			local src = (ReplicatedStorage:FindFirstChild("CarModels", true) :: Instance):FindFirstChild(id, true)
			local up = if src then (src:GetAttribute("ClusterUp") :: number?) or 0 else 0
			local fwd = if src then (src:GetAttribute("ClusterForward") :: number?) or 0 else 0
			local k = if src then (src:GetAttribute("ClusterSize") :: number?) or 1 else 1
			cluster.Size = Vector3.new(cluster.Size.X * k, cluster.Size.Y * k, cluster.Size.Z)
			cluster.CFrame = groundCF * imported.cluster * CFrame.new(0, up, -fwd)
			cluster.Parent = skin
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = cluster
			w.Parent = cluster
			cluster:SetAttribute("Style", CarSkin.CLUSTER_STYLE[id] or (if id:sub(1, 8) == "lambrini" then "Lambo" else "Modern"))
			if ownDesign then
				model:SetAttribute("OwnCluster", true) -- the model's own gauge screens stay off
			end
		end
		-- the camera sits at the model's own driver's seat
		if imported.eye then
			model:SetAttribute("Eye", imported.eye - Vector3.new(0, height / 2, 0))
		end
		-- the model has its own cabin: ours (dash, seats, wheel, driver, arms) is hidden below
		model:SetAttribute("OwnInterior", true)
	end

	-- licence plate text (the plate itself is part of the mesh)
	if meta and meta.plate and not liteMode then
		local plate = Instance.new("Part")
		plate.Name = "PlateText"
		plate.Size = Vector3.new(1.16, 0.36, 0.02)
		plate.Transparency = 1
		plate.CanCollide = false
		plate.CanQuery = false
		plate.CanTouch = false
		plate.Massless = true
		plate.CastShadow = false
		plate.CFrame = groundCF * (meta.plate :: CFrame) -- front face looks out of the car
		plate.Parent = skin
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = plate
		weld.Parent = plate
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(232, 72)
		sg.LightInfluence = 1
		sg.MaxDistance = 90
		sg.Parent = plate
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(20, 26, 60)
		local plateText = model:GetAttribute("Plate")
		text.Text = if type(plateText) == "string" then plateText else "CTYLGND"
		text.Parent = sg
	end

	-- exhaust tips in root space (Driving puts the backfire flames there)
	if meta and meta.exhausts then
		for i, p in meta.exhausts :: { Vector3 } do
			model:SetAttribute("Exhaust" .. i, p - Vector3.new(0, height / 2, 0))
		end
	end

	-- wheels
	local rim = Color3.fromRGB(design.rim[1], design.rim[2], design.rim[3])
	local caliper = Color3.fromRGB(design.caliper[1], design.caliper[2], design.caliper[3])
	for _, j in root:GetChildren() do
		if not (j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_") then
			continue
		end
		local tire = j.Part1
		if not tire then
			continue
		end
		local R = (j:GetAttribute("Radius") :: number?) or dims.wheelR
		local front = j:GetAttribute("Front") == true
		if generic then
			-- the model's own wheel for this corner, spinning with ours (kept at its own track width)
			local gw = generic[(if front then "F" else "R") .. (if j.C0.Position.X < 0 then "L" else "R")]
			if gw then
				local base = tire.CFrame * CFrame.new(gw.x - j.C0.Position.X, 0, 0)
				for i, t in gw.parts do
					local p = t.part:Clone()
					p.Name = "SkinWheel" .. i
					p.CFrame = base * t.offset
					p.Parent = skin
					local w = Instance.new("WeldConstraint")
					w.Part0 = tire
					w.Part1 = p
					w.Parent = p
				end
			end
			continue
		end
		-- imported wheels were exported at the front radius: scale to this one
		local wheel = if imported and next(imported.wheel) then imported.wheel else wheelFor(design.wheel, R, dims.wheelW, design.rimFrac, liteMode)
		local wheelScale = if imported and wheel == imported.wheel then R / dims.wheelR else 1
		if not wheel then
			break
		end
		local rest = root.CFrame * j.C0
		local left = j.C0.Position.X < 0
		local turn = if left then CFrame.Angles(0, math.pi, 0) else CFrame.new()
		local spinCF = tire.CFrame * turn
		-- knuckle: follows steering only, carries the caliper
		local knuckle = Instance.new("Part")
		knuckle.Name = "Knuckle" .. j.Name:sub(6)
		knuckle.Size = Vector3.one * 0.2
		knuckle.Transparency = 1
		knuckle.CanCollide = false
		knuckle.CanQuery = false
		knuckle.CanTouch = false
		knuckle.Massless = true
		knuckle.CFrame = rest
		knuckle.Parent = skin
		local km = Instance.new("Motor6D")
		km.Name = "Knuckle" .. j.Name:sub(6)
		km.Part0 = root
		km.Part1 = knuckle
		km.C0 = j.C0
		km.Parent = root
		for name, t in wheel do
			local base = name:match("^%a+") or name
			local look = LOOKS[base] or LOOKS.Rim
			if base == "Caliper" then
				-- sit the caliper towards the middle of the car
				local towards = (if front then 1 else -1) * (if left then -1 else 1)
				local cf = rest * turn * (if towards < 0 then CFrame.Angles(math.rad(-86), 0, 0) else CFrame.new())
				place(t, "SkinCaliper", look, caliper, cf, knuckle, skin, wheelScale)
			else
				place(t, "Skin" .. name, look, if base == "Rim" then rim else look.color or rim, spinCF, tire, skin, wheelScale)
			end
		end
	end

	-- hide the part bodywork (and, under an imported model, our whole cabin)
	local ownInterior = generic ~= nil
	local function hide(d: Instance)
		if not d:IsA("BasePart") or d == root or d:IsDescendantOf(skin) or d.Name == "Underglow" then
			return
		end
		if not (d:GetAttribute("Ext") or ownInterior) then
			return
		end
		if ownInterior then
			-- screens drawn on our hidden dash (old cluster, infotainment) go too
			for _, g in d:GetChildren() do
				if g:IsA("SurfaceGui") then
					g.Enabled = false
				end
			end
		end
		local isWheel = d.Name:sub(1, 5) == "Wheel" and d.Parent == model
		if destroyReplaced and d:GetAttribute("Ext") and not isWheel and not d:FindFirstChildWhichIsA("Light") then
			d:Destroy()
		elseif destroyReplaced or ownInterior then
			-- a local change: the server never touches these parts again, so it sticks
			d.Transparency = 1
		else
			d.LocalTransparencyModifier = 1
		end
	end
	for _, d in model:GetDescendants() do
		hide(d)
	end
	-- parts that replicate after the skin went on
	model.DescendantAdded:Connect(function(d)
		task.defer(function()
			if d:IsA("SurfaceGui") and d.Parent and d.Parent:IsA("BasePart") and not d:IsDescendantOf(skin) then
				hide(d.Parent)
			else
				hide(d)
			end
		end)
	end)
	model:SetAttribute("Skinned", true)
	return true
end

return CarSkin
