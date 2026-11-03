--[[
	Reshape (Studio, Edit mode; 2026-11-04, smooth roads): moves the corners of road triangles up or
	down and rebuilds them, so a ledge where two road surfaces meet can be ramped out. The road tools
	build each triangle from two WedgeParts; here every wedge is one right triangle whose top face is
	read back (`corners`), given new heights by `fn`, and built again as a triangle (two wedges, same
	look, attributes and thickness, attribute `Reshaped`). Corners that `fn` leaves alone stay put, so
	a wedge next to an untouched one keeps the seam closed. The old wedges go to
	ServerStorage.ReshapeBackup (undo puts them back).

	Reshape.corners(w) -> { Vector3 } (the 3 corners of a wedge's top face)
	Reshape.apply(parts, fn) -> wedges rebuilt, tag; fn(corner: Vector3, part) -> new Y (nil keeps it)
	Reshape.markings(marks, tag, roadsFolder) -> lines / dashes moved onto the new road (tilted along
	  a long line; old place in the attribute ReshapedFrom)
	Reshape.undo() (every pass)
]]

local Reshape = {}

local function backupFolder(): Folder
	local ss = game:GetService("ServerStorage")
	local f = ss:FindFirstChild("ReshapeBackup")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ReshapeBackup"
		f.Parent = ss
	end
	return f :: Folder
end

function Reshape.corners(w: BasePart): { Vector3 }
	local cf, s = w.CFrame, w.Size
	local x = if cf.RightVector.Y >= 0 then s.X / 2 else -s.X / 2
	return {
		cf * Vector3.new(x, -s.Y / 2, -s.Z / 2),
		cf * Vector3.new(x, -s.Y / 2, s.Z / 2),
		cf * Vector3.new(x, s.Y / 2, s.Z / 2),
	}
end

-- the triangle a, b, c as two wedges like the road tools make (top face through the corners)
local function triangle(a: Vector3, b: Vector3, c: Vector3, th: number, like: BasePart, tag: number): { BasePart }
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local cr = ac:Cross(ab)
	if cr.Magnitude < 1e-6 then
		return {}
	end
	local right = cr.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local nUp = if right.Y >= 0 then right else -right
	local drop = -nUp * (th / 2)
	local out = {}
	local specs = {
		{ Vector3.new(th, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2 + drop, right, up, back) },
		{ Vector3.new(th, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2 + drop, -right, up, -back) },
	}
	for _, sp in specs do
		if sp[1].Y < 0.01 or sp[1].Z < 0.01 then
			continue
		end
		local w = like:Clone()
		for _, ch in w:GetChildren() do
			ch:Destroy()
		end
		w.Size = sp[1]
		w.CFrame = sp[2]
		w:SetAttribute("Reshaped", tag)
		table.insert(out, w)
	end
	return out
end

local function key(v: Vector3): string
	return string.format("%d,%d,%d", math.round(v.X * 50), math.round(v.Y * 50), math.round(v.Z * 50))
end

-- the road tools' triangles: two wedges that share the right-angle corner (the altitude's foot, on
-- the long side) and the top corner (the apex). The foot isn't a corner of the road mesh, so a
-- triangle is moved by its 3 real corners only (moving the foot on its own would crack the long
-- side open against the next triangle).
local function triangles(parts: { BasePart }): { { wedges: { BasePart }, pts: { Vector3 } } }
	local byKey: { [string]: { BasePart } } = {}
	local order = {}
	for _, w in parts do
		if w:IsA("WedgePart") then
			local cs = Reshape.corners(w)
			local k = key(cs[2]) .. "|" .. key(cs[3])
			if not byKey[k] then
				byKey[k] = {}
				table.insert(order, k)
			end
			table.insert(byKey[k], w)
		end
	end
	local out = {}
	for _, k in order do
		local ws = byKey[k]
		if #ws == 2 then
			local c1, c2 = Reshape.corners(ws[1]), Reshape.corners(ws[2])
			table.insert(out, { wedges = ws, pts = { c1[3], c1[1], c2[1] } })
		else
			for _, w in ws do
				table.insert(out, { wedges = { w }, pts = Reshape.corners(w) })
			end
		end
	end
	return out
end

function Reshape.apply(parts: { BasePart }, fn: (Vector3, BasePart) -> number?): (number, number)
	local bk = backupFolder()
	local tag = os.time()
	local n = 0
	for _, tri in triangles(parts) do
		local like = tri.wedges[1]
		local cs = table.clone(tri.pts)
		local moved = false
		for i, c in cs do
			local y = fn(c, like)
			if y and math.abs(y - c.Y) > 0.005 then
				cs[i] = Vector3.new(c.X, y, c.Z)
				moved = true
			end
		end
		if moved then
			local parent = like.Parent
			local made = triangle(cs[1], cs[2], cs[3], like.Size.X, like, tag)
			for _, m in made do
				m.Parent = parent
			end
			for _, w in tri.wedges do
				local ref = Instance.new("ObjectValue")
				ref.Name = "WasIn"
				ref.Value = w.Parent
				ref.Parent = w
				w:SetAttribute("ReshapedAway", tag)
				w.Parent = bk
				n += 1
			end
		end
	end
	return n, tag
end

-- road markings (lines, dashes, zebras) over moved road: each one follows the road under it.
-- oldY(x, z) gives the old road height there (Reshape.oldSurface), the new one is raycast.
function Reshape.oldSurface(tag: number): (number, number) -> number?
	local tris = {}
	for _, w in backupFolder():GetChildren() do
		if w:GetAttribute("ReshapedAway") == tag and w:IsA("WedgePart") then
			table.insert(tris, Reshape.corners(w))
		end
	end
	return function(x: number, z: number): number?
		for _, t in tris do
			local a, b, c = t[1], t[2], t[3]
			local d = (b.Z - c.Z) * (a.X - c.X) + (c.X - b.X) * (a.Z - c.Z)
			if math.abs(d) > 1e-9 then
				local l1 = ((b.Z - c.Z) * (x - c.X) + (c.X - b.X) * (z - c.Z)) / d
				local l2 = ((c.Z - a.Z) * (x - c.X) + (a.X - c.X) * (z - c.Z)) / d
				local l3 = 1 - l1 - l2
				if l1 >= -0.001 and l2 >= -0.001 and l3 >= -0.001 then
					return l1 * a.Y + l2 * b.Y + l3 * c.Y
				end
			end
		end
		return nil
	end
end

function Reshape.markings(marks: { BasePart }, tag: number, roads: Instance): number
	local oldY = Reshape.oldSurface(tag)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { roads }
	-- how far the road moved at (x, z) (nil: not over moved road)
	local function moved(p: Vector3): number?
		local was = oldY(p.X, p.Z)
		if not was then
			return nil
		end
		-- only road pieces count as the new surface
		local hit
		local from = Vector3.new(p.X, p.Y + 3, p.Z)
		for _ = 1, 4 do
			hit = workspace:Raycast(from, Vector3.new(0, -8, 0), params)
			if not hit or hit.Instance.Name == "Road" then
				break
			end
			from = hit.Position - Vector3.new(0, 0.01, 0)
		end
		if hit and hit.Instance.Name == "Road" then
			return hit.Position.Y - was
		end
		return nil
	end
	local n = 0
	for _, m in marks do
		-- the long axis: a long line is tilted to follow the road along it
		local cf, s = m.CFrame, m.Size
		local axis = if s.X >= s.Z then cf.RightVector * s.X else cf.LookVector * s.Z
		local e1, e2 = cf.Position - axis / 2, cf.Position + axis / 2
		local d1, d2 = moved(e1), moved(e2)
		local dm = moved(cf.Position)
		if not dm then
			continue
		end
		d1, d2 = d1 or dm, d2 or dm
		if math.abs(d1) + math.abs(d2) + math.abs(dm) < 0.015 then
			continue
		end
		local n1, n2 = e1 + Vector3.new(0, d1, 0), e2 + Vector3.new(0, d2, 0)
		local dir, newDir = (e2 - e1).Unit, (n2 - n1).Unit
		local turn = CFrame.identity
		local cr = dir:Cross(newDir)
		if cr.Magnitude > 1e-5 then
			turn = CFrame.fromAxisAngle(cr.Unit, math.asin(math.clamp(cr.Magnitude, -1, 1)))
		end
		local was = m.CFrame
		m.CFrame = CFrame.new((n1 + n2) / 2) * turn * cf.Rotation
		if not m:GetAttribute("ReshapedFrom") then
			m:SetAttribute("ReshapedFrom", was)
		end
		n += 1
	end
	return n
end

function Reshape.undo()
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Reshaped") then
			d:Destroy()
		elseif d:IsA("BasePart") and typeof(d:GetAttribute("ReshapedFrom")) == "CFrame" then
			d.CFrame = d:GetAttribute("ReshapedFrom")
			d:SetAttribute("ReshapedFrom", nil)
		end
	end
	for _, w in backupFolder():GetChildren() do
		local ref = w:FindFirstChild("WasIn")
		if w:GetAttribute("Reshaped") then
			-- made by an earlier pass: its original is in here too
			w:Destroy()
		elseif ref and ref.Value then
			w.Parent = ref.Value
			w:SetAttribute("ReshapedAway", nil)
			ref:Destroy()
		end
	end
end

return Reshape
