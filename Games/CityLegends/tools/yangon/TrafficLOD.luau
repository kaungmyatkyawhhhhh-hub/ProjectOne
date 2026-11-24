--[[
	TrafficLOD (Studio, Edit; ServerStorage.ClaudeTools.TrafficLOD) 2026-11-19
	Light traffic copies of the roster's own cars (owner: "they should use the cars from the cars that i already made
	by hand") for ReplicatedStorage.TrafficModels, read by client/TrafficBodies + shared/TrafficMix.
	  T.make(id, kind)  -> Model "Traffic_<kind>_<id>" (not parented): exterior only (no cabin, seats, plates, lamp
	                       shells, scripts, lights, decals, SurfaceAppearances), glass made opaque and dark, parts by
	                       role in plain colours, paint parts marked TrafficPaint, everything RenderFidelity
	                       Performance / no shadows / no collision; front +Z, wheels' bottom at y 0 (TrafficBodies'
	                       import convention). Body + FL / FR / RL / RR.
	  T.newSet(holding) -> readies the uploaded Probox / Hiace / Carry / YBS models (tools/yangon_traffic_cars.py)
	  T.install(list)   -> old TrafficModels to ServerStorage.TrafficModels_old (kept until tested), new folder in
	                       ReplicatedStorage. list = { {id, kind}, ... }; returns a report.
	  T.undo()          -> the old folder back.
	Badges (2026-11-19): MarkPatch parts in CarModels (tools/brand_marks/RobloxBuiltPatches.luau) are always kept, and a
	converted car's BrandMarks covers / wheel caps / hidden badge parts (what CarSkin does at run time, which a traffic copy
	never goes through) are baked in as MarkPatch parts; cars in CarFinish.CARS have their logos out of the model already.
	Mesh triangles can't be read (the place has no permission to load these meshes), so it drops by name, by
	being inside the cabin box, and by size.
]]

local T = {}

local CM = game:GetService("ReplicatedStorage"):WaitForChild("CarModels")
-- (2026-11-24) the roster's old bodies were put away on 19 Nov (ServerStorage.OldModelCars) but traffic still uses them
local function sourceModel(id: string): Instance?
	local old = game:GetService("ServerStorage"):FindFirstChild("OldModelCars")
	return CM:FindFirstChild(id) or (old and old:FindFirstChild(id))
end
local CORNERS = { "FL", "FR", "RL", "RR" }

-- whole groups that are never seen from outside (any ancestor with one of these names, lower case)
-- (2026-11-24, owner: traffic copies missing their rear doors) no "misc": A-Chassis kits keep the four doors in
-- Misc/FL..RR/Door (the Belta and Alfard copies had no doors); the steering wheel there is dropped by its SW group
local DROP_GROUPS = {
	interior = true, int = true, seats = true, seat = true, stuffs = true, suitcase = true, engine = true,
	sw = true, cam = true, tk = true, hitbox = true, plates = true, ["malaysian car plate"] = true,
	accessories = true, lns = true, ["liftgate hydraulic arm part"] = true,
}
-- part names (lower case patterns)
local DROP_PARTS = { "cabin", "leather", "suede", "^steeringwheel", "_engine", "^engine", "^lampfx_", "plate", "seat", "^drag$", "^downforce", "^smoke$",
	"^hitbox", "^cam$", "^engine", "screenlit", "^tk$", "handle", "pedal", "^body_exhausthole",
	"badge", "logo", "emblem", "lettering" }

-- a badge cover (MarkPatch, MarkPatch_Paint: tools/brand_marks/RobloxBuiltPatches.luau)
local function isPatch(n: string): boolean
	return string.sub(n, 1, 9) == "MarkPatch"
end

local function lower(s: string): string
	return string.lower(s)
end

local function dropped(p: Instance, root: Instance): boolean
	if isPatch(p.Name) then
		return false -- (badge covers from tools/brand_marks/RobloxBuiltPatches.luau: always kept)
	end
	local n = lower(p.Name)
	for _, pat in DROP_PARTS do
		if string.find(n, pat) then
			return true
		end
	end
	local a = p.Parent
	while a and a ~= root do
		if DROP_GROUPS[lower(a.Name)] then
			return true
		end
		a = a.Parent
	end
	return false
end

local function under(p: Instance, root: Instance, word: string): boolean
	local a: Instance? = p
	while a and a ~= root do
		if string.find(lower(a.Name), word) then
			return true
		end
		a = a.Parent
	end
	return false
end

-- a plain colour by role for a part that drew its look from a SurfaceAppearance / picture
local function roleColor(n: string): (Color3?, Enum.Material?)
	if string.find(n, "chrome") then
		return Color3.fromRGB(170, 172, 176), Enum.Material.SmoothPlastic
	elseif string.find(n, "lamptail") or string.find(n, "lens_red") or string.find(n, "tail") then
		return Color3.fromRGB(150, 12, 16), Enum.Material.SmoothPlastic
	elseif string.find(n, "lens_orange") or string.find(n, "turn") then
		return Color3.fromRGB(220, 120, 20), Enum.Material.SmoothPlastic
	elseif string.find(n, "lens_clear") or n == "body_lamp" or string.find(n, "headl") then
		return Color3.fromRGB(205, 208, 210), Enum.Material.SmoothPlastic
	elseif string.find(n, "rim") then
		return Color3.fromRGB(150, 152, 156), Enum.Material.SmoothPlastic
	elseif string.find(n, "tyre") or string.find(n, "tire") then
		return Color3.fromRGB(24, 24, 25), Enum.Material.SmoothPlastic
	elseif string.find(n, "mirror") then
		return nil, nil -- (the mirror shell keeps its colour: paint or black)
	end
	return Color3.fromRGB(28, 28, 30), Enum.Material.SmoothPlastic -- trim, base, grille, carbon, exhaust
end

local function isGlass(p: BasePart, n: string): boolean
	return string.find(n, "window") ~= nil or string.find(n, "glass") ~= nil or string.find(n, "windshield") ~= nil
		or p.Material == Enum.Material.Glass or (p.Transparency > 0.05 and p.Transparency < 0.95)
end

-- a flat little part wearing a picture: a badge, a name plate or a number plate (no real lettering in traffic)
local function badgeLike(p: BasePart, length: number): boolean
	local sz = p.Size
	local mn, mx = math.min(sz.X, sz.Y, sz.Z), math.max(sz.X, sz.Y, sz.Z)
	local mesh = p:FindFirstChildWhichIsA("SpecialMesh")
	local tex = (p:IsA("MeshPart") and p.TextureID ~= "") or p:FindFirstChildWhichIsA("Decal") ~= nil
		or (mesh ~= nil and mesh.TextureId ~= "")
	return tex and mn < 0.09 * length / 15 and mx < 0.16 * length
end

-- (2026-11-19) the game's runtime badge covers for converted cars (client BrandMarks, as CarSkin lays them; cars in
-- CarFinish.CARS have their logos out of the model and get none), baked into the traffic copy as MarkPatch parts
local function clientModule(name: string): any
	local m = game:GetService("StarterPlayer"):FindFirstChild(name, true)
	if not m then
		return nil
	end
	local ok, v = pcall(require, m:Clone())
	return if ok then v else nil
end

local function marksFor(id: string): any
	local finish = clientModule("CarFinish")
	if finish and finish.CARS and finish.CARS[id] then
		return nil
	end
	local bm = clientModule("BrandMarks")
	return bm and bm[id]
end

-- a plain cover (CarSkin.coverParts' shape): `cf` on the surface looking out of it, the back face on the surface
local function coverPart(cf: CFrame, w: number, h: number, color: Color3, disc: boolean, covers: string): BasePart
	local thick = math.max(0.004, w * 0.04)
	local p = Instance.new("Part")
	p.Name = "MarkPatch"
	p:SetAttribute("Covers", covers)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	if disc then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(thick, w, w)
		p.CFrame = cf * CFrame.new(0, 0, -thick / 2) * CFrame.Angles(0, math.pi / 2, 0)
	else
		p.Size = Vector3.new(w, h, thick)
		p.CFrame = cf * CFrame.new(0, 0, -thick / 2)
	end
	return p
end

local function volume(p: BasePart): number
	return p.Size.X * p.Size.Y * p.Size.Z
end

local function centreOf(parts: { BasePart }): Vector3
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in parts do
		local h = p.Size / 2
		for _, c in { Vector3.new(-1, -1, -1), Vector3.new(1, 1, 1), Vector3.new(-1, 1, 1), Vector3.new(1, -1, -1) } do
			local w = p.CFrame:PointToWorldSpace(h * c)
			lo, hi = lo:Min(w), hi:Max(w)
		end
	end
	return (lo + hi) / 2
end

local function visible(inst: Instance): { BasePart }
	local out = {}
	local all = {}
	for _, d in inst:GetDescendants() do
		-- (2026-11-24) an A-Chassis corner's suspension arms (see-through physics boxes) are no wheel: the Belta's
		-- traffic copy had three of them for wheels
		if not (d:IsA("BasePart") and under(d, inst, "suspension")) then
			table.insert(all, d)
		end
	end
	-- (a kit wheel's own Part is the physics cylinder; its looks are the parts inside it)
	local inner = false
	for _, d in all do
		if d:IsA("BasePart") then
			inner = true
			break
		end
	end
	if not inner then
		table.insert(all, inst)
	end
	for _, d in all do
		if d:IsA("BasePart") and d.Transparency < 0.95 and not d:IsA("Seat") and not d:IsA("VehicleSeat") then
			table.insert(out, d)
		end
	end
	return out
end

local function tidy(p: BasePart, keepLook: boolean?)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	if p:IsA("MeshPart") then
		pcall(function()
			-- (Automatic: full detail close, Roblox's own lower levels far; Performance crumpled the kit cars' shells
			-- even up close)
			p.RenderFidelity = Enum.RenderFidelity.Automatic
			p.CollisionFidelity = Enum.CollisionFidelity.Box
		end)
	end
	for _, c in p:GetChildren() do
		-- (a kit car's shape is often a SpecialMesh / FileMesh child of a plain Part: always kept)
		if not (keepLook and c:IsA("SurfaceAppearance")) and not c:IsA("DataModelMesh") then
			c:Destroy() -- welds, decals, SurfaceAppearances, lights, attachments, meshes' extras
		end
	end
end

function T.make(id: string, kind: string, maxBody: number?): (Model?, string)
	local src = sourceModel(id)
	if not src then
		return nil, id .. ": not in CarModels"
	end
	src = src:Clone()
	-- wheels: the visible pieces of each corner (at most the 3 biggest: tyre, rim, disc)
	local wheelsFolder = src:FindFirstChild("Wheels")
	if not wheelsFolder then
		return nil, id .. ": no Wheels"
	end
	local wheel: { [string]: { BasePart } } = {}
	local hub: { [string]: Vector3 } = {}
	for _, c in CORNERS do
		local w = wheelsFolder:FindFirstChild(c)
		if not w then
			return nil, id .. ": no wheel " .. c
		end
		local parts = visible(w)
		table.sort(parts, function(a, b)
			return volume(a) > volume(b)
		end)
		while #parts > 3 do
			table.remove(parts)
		end
		for _, d in w:GetDescendants() do
			if isPatch(d.Name) and d:IsA("BasePart") and not table.find(parts, d) then
				table.insert(parts, d) -- (the wheel-cap badge covers)
			end
		end
		if #parts == 0 then
			return nil, id .. ": empty wheel " .. c
		end
		wheel[c] = parts
		hub[c] = centreOf(parts)
	end
	local front = ((hub.FL + hub.FR) / 2 - (hub.RL + hub.RR) / 2) * Vector3.new(1, 0, 1)
	local wb = front.Magnitude
	front = front.Unit
	local mid = (hub.FL + hub.FR + hub.RL + hub.RR) / 4
	local track = (hub.FL - hub.FR).Magnitude
	local frame = CFrame.lookAt(mid, mid + front) -- the car's own frame: -Z front
	local wheelR = 0
	for _, p in wheel.FL do
		wheelR = math.max(wheelR, math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2)
	end

	-- the converted car's measured badge spots (metres from the wheel centres' middle: right / up / back)
	local marks = marksFor(id)
	local spm = if marks then wb / marks.wb else 1
	local function markHidden(d: BasePart): boolean
		if not marks then
			return false
		end
		if marks.keep and table.find(marks.keep, d.Name) then
			return false
		end
		for _, h in marks.hide do
			if d.Name == h.name and (h.size == nil or (d.Size - h.size).Magnitude < 0.01) then
				return true
			end
		end
		return false
	end
	local addedCovers: { BasePart } = {}
	if marks then
		for _, cv in marks.covers do
			local face = (frame.Rotation * cv.face).Unit
			local pos = frame * (cv.at * spm) + face * 0.003 * spm
			local up = if math.abs(face.Y) > 0.95 then frame.LookVector else Vector3.yAxis
			-- (a fifth bigger than CarSkin's: the LC300's boot emblem peeked round the measured size)
			table.insert(addedCovers, coverPart(CFrame.lookAt(pos, pos + face, up), cv.w * spm * 1.2, cv.h * spm * 1.2, cv.color, cv.disc, "BrandMarks cover"))
		end
		for _, c in CORNERS do
			local cap = marks.caps and marks.caps[c]
			if cap then
				local side = if (hub[c] - mid):Dot(frame.RightVector) < 0 then -1 else 1
				local look = frame.RightVector * side
				local pos = hub[c] + look * (cap.surface + 0.003) * spm
				local p = coverPart(CFrame.lookAt(pos, pos + look), cap.r * 2 * spm, cap.r * 2 * spm, cap.color, true, "BrandMarks cap")
				p.Parent = src.Wheels:FindFirstChild(c)
				table.insert(wheel[c], p)
			end
		end
	end

	-- body: everything visible outside the wheels, minus the dropped groups / names
	local body: { BasePart } = {}
	for _, p in addedCovers do
		p.Parent = src
		table.insert(body, p)
	end
	for _, d in src:GetDescendants() do
		if d:IsA("BasePart") and not d:IsDescendantOf(wheelsFolder) and not d:IsA("Seat") and not d:IsA("VehicleSeat") and not markHidden(d)
			and not table.find(addedCovers, d) then
			local n = lower(d.Name)
			if d.Transparency < 0.95 or isGlass(d, n) then
				if not dropped(d, src) then
					table.insert(body, d)
				end
			end
		end
	end
	-- the box of the body: height and length for the cabin and size tests
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, p in body do
		local cf = frame:ToObjectSpace(p.CFrame)
		local h = p.Size / 2
		local e = Vector3.new(
			math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
			math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
			math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z)
		lo, hi = lo:Min(cf.Position - e), hi:Max(cf.Position + e)
	end
	local length = hi.Z - lo.Z
	local groundY = (mid.Y - wheelR) - mid.Y -- in the frame: the wheels' bottom
	local height = hi.Y - groundY
	local keep: { BasePart } = {}
	local droppedInside, droppedTiny = 0, 0
	for _, p in body do
		local cf = frame:ToObjectSpace(p.CFrame)
		local h = p.Size / 2
		local ex = math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z
		local ey = math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z
		local ez = math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
		local q = cf.Position
		local inside = math.abs(q.X) + ex < track * 0.42 and math.abs(q.Z) + ez < wb * 0.62
			and q.Y - ey > groundY + height * 0.22 and q.Y + ey < hi.Y - height * 0.06
		local n = lower(p.Name)
		if isPatch(p.Name) then
			table.insert(keep, p)
		elseif badgeLike(p, length) then
			droppedTiny += 1
		elseif inside and not isGlass(p, n) then
			droppedInside += 1
		elseif math.max(p.Size.X, p.Size.Y, p.Size.Z) < length * 0.02 then
			droppedTiny += 1
		else
			table.insert(keep, p)
		end
	end
	-- a door part in the paint parts' own colour and material is paint too (the Belta's door skins are named "H"; only
	-- doors: on a black car every black trim would take the livery)
	local paintLook: { [string]: boolean } = {}
	local function lookKey(p: BasePart): string
		return p.Material.Name .. tostring(p.Color)
	end
	local function isPaint(p: BasePart): boolean
		return string.find(lower(p.Name), "paint") ~= nil or under(p, src, "paint") or under(p, src, "^color$")
	end
	for _, p in keep do
		if isPaint(p) then
			paintLook[lookKey(p)] = true
		end
	end
	-- (2026-11-24) the body cap trimmed by size only and cut the Camry's / Crown's rear door skins and side windows
	-- (ties at the cut, one door of a pair kept): the shell (paint, glass, door parts) is never trimmed, only the rest
	local function shell(p: BasePart): boolean
		return isPatch(p.Name) or isPaint(p) or isGlass(p, lower(p.Name)) or under(p, src, "door")
	end
	if maxBody and #keep > maxBody then
		local rank: { [BasePart]: number } = {}
		for i, p in keep do
			rank[p] = i
		end
		table.sort(keep, function(a, b)
			local pa, pb = shell(a), shell(b)
			if pa ~= pb then
				return pa -- (badge covers and the shell first: never trimmed)
			end
			local va, vb = volume(a), volume(b)
			if math.abs(va - vb) > 1e-4 then
				return va > vb
			end
			return rank[a] < rank[b]
		end)
		while #keep > maxBody and not shell(keep[#keep]) do
			table.remove(keep)
		end
	end

	-- the new model: front +Z (half a turn from the frame's -Z), wheels' bottom on y 0
	local out = Instance.new("Model")
	out.Name = "Traffic_" .. kind .. "_" .. id
	local place = CFrame.new(0, wheelR, 0) * CFrame.Angles(0, math.pi, 0) * frame:Inverse()
	-- a rip with no paint parts by name (the R34, the Chiron) keeps its own pictures: plain colours by role would
	-- turn it black
	local keepLook = true
	for _, p in keep do
		if string.find(lower(p.Name), "paint") or under(p, src, "paint") or under(p, src, "^color$") then
			keepLook = false
			break
		end
	end
	local bodyM = Instance.new("Model")
	bodyM.Name = "Body"
	bodyM.Parent = out
	local paintN = 0
	for _, p in keep do
		local c = p:Clone()
		local n = lower(p.Name)
		local hadLook = p:FindFirstChildOfClass("SurfaceAppearance") ~= nil and not keepLook
		tidy(c, keepLook)
		c.CFrame = place * p.CFrame
		if isGlass(p, n) then
			c.Transparency = 0
			c.Material = Enum.Material.SmoothPlastic
			c.Reflectance = 0.12
			if string.find(n, "lens_red") then
				c.Color = Color3.fromRGB(150, 12, 16)
			elseif string.find(n, "lens_orange") then
				c.Color = Color3.fromRGB(220, 120, 20)
			elseif string.find(n, "lens") then
				c.Color = Color3.fromRGB(205, 208, 210)
			else
				c.Color = Color3.fromRGB(30, 34, 40)
			end
			if c:IsA("MeshPart") then
				c.TextureID = ""
			end
		elseif isPaint(p) or (paintLook[lookKey(p)] and under(p, src, "door")) then
			c:SetAttribute("TrafficPaint", true)
			c.Material = Enum.Material.SmoothPlastic
			c.Reflectance = 0.08
			if c:IsA("MeshPart") then
				c.TextureID = ""
			end
			paintN += 1
		elseif hadLook then
			local col, mat = roleColor(n)
			if col then
				c.Color = col
				c.Material = mat :: Enum.Material
			end
		end
		c.Parent = bodyM
	end
	for _, corner in CORNERS do
		local wm = Instance.new("Model")
		wm.Name = corner
		for _, p in wheel[corner] do
			local c = p:Clone()
			local hadLook = p:FindFirstChildOfClass("SurfaceAppearance") ~= nil and not keepLook
			tidy(c, keepLook)
			c.CFrame = place * p.CFrame
			if p == wheelsFolder:FindFirstChild(corner) then
				-- (an A-Chassis corner part is the wheel: a cylinder whose rim was a decal, gone with tidy) a dark tyre
				c.Color = Color3.fromRGB(24, 24, 25)
				c.Material = Enum.Material.SmoothPlastic
			elseif hadLook then
				local col, mat = roleColor(lower(p.Name))
				if col then
					c.Color = col
					c.Material = mat :: Enum.Material
				end
			end
			c.Parent = wm
		end
		wm.Parent = out
	end
	-- (a plain pivot: TrafficBodies' PivotTo(CFrame.new()) turned the cars with a half-turn pivot round, back first)
	out.WorldPivot = CFrame.new((out:GetBoundingBox()).Position)
	out:SetAttribute("KeepColors", true)
	out:SetAttribute("SourceCar", id)
	src:Destroy()
	local nParts = #keep
	for _, c in CORNERS do
		nParts += #wheel[c]
	end
	return out, string.format("%s: %d parts (body %d, paint %d; dropped inside %d, tiny %d), len %.1f",
		out.Name, nParts, #keep, paintN, droppedInside, droppedTiny, length)
end

-- the uploaded new set: each Traffic_<k>_<id> Model with Body / Detail / wheels (as `<name>_Node` Models after an
-- Open Cloud insert): paint marked, no shadows / collision, front +Z
function T.newSet(holding: Instance, turn: boolean?): { string }
	local report = {}
	for _, m in holding:GetDescendants() do
		if m:IsA("Model") and string.match(m.Name, "^Traffic_%a_") then
			local car = m:Clone()
			car.Name = string.gsub(car.Name, "_Node$", "")
			for _, d in car:GetDescendants() do
				if d:IsA("BasePart") then
					tidy(d)
					local isBody = string.find(d.Name, "^Body") or (d.Parent and string.find(d.Parent.Name, "^Body"))
					if isBody then
						d:SetAttribute("TrafficPaint", true)
						d.Material = Enum.Material.SmoothPlastic
						d.Color = Color3.fromRGB(236, 237, 238)
					else
						d.Material = Enum.Material.SmoothPlastic
						d.Color = Color3.new(1, 1, 1) -- (the vertex colours carry the look)
					end
				end
			end
			if turn then
				local cf = car:GetPivot()
				car:PivotTo(cf * CFrame.Angles(0, math.pi, 0))
			end
			car.WorldPivot = CFrame.new((car:GetBoundingBox()).Position)
			car:SetAttribute("KeepColors", true)
			table.insert(report, car.Name)
			car.Parent = holding
			m:Destroy()
		end
	end
	return report
end

function T.install(list: { { string } }, newSet: Instance?, maxBody: number?): string
	local RS = game:GetService("ReplicatedStorage")
	local SS = game:GetService("ServerStorage")
	local lines = {}
	local folder = Instance.new("Folder")
	folder.Name = "TrafficModels"
	for _, row in list do
		local m, msg = T.make(row[1], row[2], maxBody)
		table.insert(lines, msg)
		if m then
			m.Parent = folder
		end
	end
	if newSet then
		for _, m in newSet:GetChildren() do
			if m:IsA("Model") and string.match(m.Name, "^Traffic_%a_") then
				m:Clone().Parent = folder
			end
		end
	end
	local old = RS:FindFirstChild("TrafficModels")
	if old and not SS:FindFirstChild("TrafficModels_old") then
		old.Name = "TrafficModels_old"
		old.Parent = SS
	elseif old then
		old:Destroy()
	end
	folder.Parent = RS
	return table.concat(lines, "\n")
end

-- a check stage at (-2000, 2600, 2000): the cars in threes, each at its real length (TrafficMix), front +Z
T.LIST = {
	{ "suzaki_swift", "A" }, { "toyoka_belta", "E" }, { "toyoka_camri", "E" }, { "toyoka_lc200", "F" }, { "byt_seal", "E" },
	{ "kio_ev6", "F" }, { "toyoka_chaser", "E" }, { "toyoka_crown", "E" }, { "toyoka_alfard", "B" }, { "toyoka_lc300", "F" },
	{ "lexis_lx700", "F" }, { "nisun_gtr", "R" }, { "nisun_r34", "R" }, { "ferrara_599", "R" }, { "ferrara_california", "R" },
	{ "lambrini_huracan", "R" }, { "lambrini_lp570", "R" }, { "bugotti_chiron", "R" },
}
function T.stage(maxBody: number?, extra: Instance?): string
	local Mix = require(game:GetService("ReplicatedStorage").Shared.TrafficMix:Clone())
	local st = workspace:FindFirstChild("_TrafficStage")
	if st then
		st:Destroy()
	end
	st = Instance.new("Model")
	st.Name = "_TrafficStage"
	st.Parent = workspace
	local base = Instance.new("Part")
	base.Anchored = true
	base.Size = Vector3.new(420, 1, 120)
	base.Position = Vector3.new(-1830, 2599.5, 2000)
	base.Color = Color3.fromRGB(70, 70, 72)
	base.Material = Enum.Material.SmoothPlastic
	base.Parent = st
	local models, out = {}, {}
	for _, row in T.LIST do
		local m, msg = T.make(row[1], row[2], maxBody)
		table.insert(out, msg)
		if m then
			table.insert(models, m)
		end
	end
	if extra then
		for _, m in extra:GetChildren() do
			if m:IsA("Model") then
				table.insert(models, m:Clone())
			end
		end
	end
	for i, m in models do
		local e = Mix.byName[m.Name]
		local _, sz = m:GetBoundingBox()
		if e then
			m:ScaleTo(m:GetScale() * e.len / sz.Z)
		end
		local k, g = (i - 1) % 3, math.floor((i - 1) / 3)
		local cf, b = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + (Vector3.new(-2000 + g * 60 + k * 9, 2600 + b.Y / 2, 2000) - cf.Position))
		m.Parent = st
	end
	return table.concat(out, string.char(10))
end

function T.undo()
	local RS = game:GetService("ReplicatedStorage")
	local SS = game:GetService("ServerStorage")
	local old = SS:FindFirstChild("TrafficModels_old")
	if old then
		local cur = RS:FindFirstChild("TrafficModels")
		if cur then
			cur:Destroy()
		end
		old.Name = "TrafficModels"
		old.Parent = RS
	end
end

return T
