--[[
	SurfaceCheck (Studio; owner, 2026-11-06, pictures of the Legends Rewards drive and of a wall: "FIND IT
	ALL"): finds every place where two pieces of what should be one clean surface fight or don't line up,
	over the whole map: buildings, venues, pavements, plates. Runs in Edit, or on the Server in Play to
	see the venues too (they are built when the server starts).

	Each visible flat face of every anchored block is looked at. Two faces are a problem when they look
	the same way, sit on top of each other (at least MIN_OVER studs both ways), and:
	  * fight: their planes are under FIGHT apart: the renderer flips between them
	  * step: under STEP apart: one lies on the other in a thin skin, with a hard line round it
	  * bent (run with bent = true): big faces meeting at an edge at a small angle, MIN_BEND to MAX_BEND
	    degrees, so one shows lighter than the other and the bands don't line up

	SurfaceCheck.run(root, opts?) -> list, summary text
	list entries: { kind, a, b, at, gap, over, nameA, nameB }
	opts: { bent: boolean?, minArea: number?, skip: (BasePart) -> boolean }
]]

local SurfaceCheck = {}

local FIGHT = 0.05
local STEP = 0.3
local MIN_OVER = 0.7 -- (a wall piece's 0.6 end at a corner is too thin to see)
local MIN_AREA = 4
local MIN_BEND, MAX_BEND = 0.4, 30
local BEND_AREA = 60 -- bent: faces at least this big
local BEND_GAP = 0.6

type Face = {
	part: BasePart,
	n: Vector3,
	c: Vector3,
	u: Vector3,
	v: Vector3,
	hu: number,
	hv: number,
	d: number,
}

local AXES = { { "X", "Y", "Z" }, { "Y", "Z", "X" }, { "Z", "X", "Y" } }

local function vec(cf: CFrame, name: string): Vector3
	if name == "X" then
		return cf.RightVector
	elseif name == "Y" then
		return cf.UpVector
	end
	return -cf.LookVector -- (+Z of the part)
end

local function faces(p: BasePart, minArea: number, out: { Face })
	local s, cf = p.Size, p.CFrame
	for _, a in AXES do
		local nv = vec(cf, a[1])
		local h = s[a[1]] / 2
		local hu, hv = s[a[2]] / 2, s[a[3]] / 2
		if 4 * hu * hv >= minArea then
			local u, v = vec(cf, a[2]), vec(cf, a[3])
			for _, sign in { 1, -1 } do
				local n = nv * sign
				-- (a floor's underside and faces pointing straight down are never seen from outside)
				if n.Y > -0.9 then
					local c = p.Position + n * h
					table.insert(out, { part = p, n = n, c = c, u = u, v = v, hu = hu, hv = hv, d = n:Dot(c) })
				end
			end
		end
	end
end

-- how far face b reaches along axis ax of the plane
local function spread(f: Face, ax: Vector3): number
	return f.hu * math.abs(f.u:Dot(ax)) + f.hv * math.abs(f.v:Dot(ax))
end

-- the overlap of two faces in their plane, both ways (0, 0 if none)
local function overlap(a: Face, b: Face): (number, number)
	local dc = b.c - a.c
	local ou = a.hu + spread(b, a.u) - math.abs(dc:Dot(a.u))
	local ov = a.hv + spread(b, a.v) - math.abs(dc:Dot(a.v))
	if ou <= 0 or ov <= 0 then
		return 0, 0
	end
	local pu = b.hu + spread(a, b.u) - math.abs(dc:Dot(b.u))
	local pv = b.hv + spread(a, b.v) - math.abs(dc:Dot(b.v))
	if pu <= 0 or pv <= 0 then
		return 0, 0
	end
	return math.min(ou, 2 * a.hu, 2 * spread(b, a.u)), math.min(ov, 2 * a.hv, 2 * spread(b, a.v))
end

local function group(p: Instance): string
	local q = p
	while q.Parent and q.Parent ~= workspace do
		local up = q.Parent
		if up.Name == "Buildings" or up.Name == "Roads" or up.Name == "Sites" or up.Name == "Dressing" or up.Name == "Blocks" or up.Name == "City" then
			return q.Name
		end
		q = up
	end
	return q.Name
end

local function label(p: BasePart): string
	return group(p) .. "/" .. p.Name
end

function SurfaceCheck.run(root: Instance, opts: any?): ({ any }, string)
	local o = opts or {}
	local minArea = o.minArea or MIN_AREA
	local all: { Face } = {}
	local count = 0
	for _, p in root:GetDescendants() do
		count += 1
		if count % 30000 == 0 then
			task.wait()
		end
		if p:IsA("Part") and p.Anchored and p.Shape == Enum.PartType.Block and p.Transparency < 0.9 and not (o.skip and o.skip(p)) then
			faces(p, minArea, all)
		end
	end
	-- same way, same plane: buckets of direction and plane height
	local buckets: { [string]: { Face } } = {}
	local function dirKey(n: Vector3): string
		return string.format("%d,%d,%d", math.round(n.X * 40), math.round(n.Y * 40), math.round(n.Z * 40))
	end
	for _, f in all do
		local key = dirKey(f.n) .. ":" .. math.floor(f.d / STEP)
		local b = buckets[key]
		if not b then
			b = {}
			buckets[key] = b
		end
		table.insert(b, f)
	end
	local found = {}
	local checks = 0
	local function compare(list1: { Face }, list2: { Face }, same: boolean)
		for i, a in list1 do
			local start = if same then i + 1 else 1
			for j = start, #list2 do
				local b = list2[j]
				checks += 1
				if checks % 2000000 == 0 then
					task.wait()
				end
				if a.part ~= b.part and a.n:Dot(b.n) > 0.9995 then
					local far = a.hu + a.hv + b.hu + b.hv
					if (b.c - a.c).Magnitude < far then
						local gap = math.abs(a.n:Dot(b.c - a.c))
						if gap < STEP then
							local ou, ov = overlap(a, b)
							if ou >= MIN_OVER and ov >= MIN_OVER then
								table.insert(found, {
									kind = if gap < FIGHT then "fight" else "step",
									a = a.part,
									b = b.part,
									at = (a.c + b.c) / 2,
									gap = gap,
									over = ou * ov,
									nameA = label(a.part),
									nameB = label(b.part),
								})
							end
						end
					end
				end
			end
		end
	end
	local done = 0
	for key, list in buckets do
		done += 1
		if done % 2000 == 0 then
			task.wait()
		end
		-- a big bucket is split by place, so a street of faces isn't compared with the far side of the map
		if #list > 600 then
			local sub: { [string]: { Face } } = {}
			for _, f in list do
				local g = 120
				local k = math.floor(f.c.X / g) .. "," .. math.floor(f.c.Y / g) .. "," .. math.floor(f.c.Z / g)
				sub[k] = sub[k] or {}
				table.insert(sub[k], f)
			end
			for _, s in sub do
				compare(s, s, true)
				task.wait()
			end
		else
			compare(list, list, true)
		end
		local head, tail = string.match(key, "^(.*):(.-)$")
		local next_ = buckets[head .. ":" .. (tonumber(tail) :: number + 1)]
		if next_ and #list <= 600 and #next_ <= 600 then
			compare(list, next_, false)
		end
	end
	-- bent: big faces meeting at a small angle
	if o.bent then
		local big = {}
		for _, f in all do
			if 4 * f.hu * f.hv >= BEND_AREA and math.abs(f.n.Y) < 0.5 then
				table.insert(big, f)
			end
		end
		local G = 120
		local grid: { [string]: { Face } } = {}
		for _, f in big do
			local k = math.floor(f.c.X / G) .. "," .. math.floor(f.c.Z / G)
			grid[k] = grid[k] or {}
			table.insert(grid[k], f)
		end
		local minDot, maxDot = math.cos(math.rad(MAX_BEND)), math.cos(math.rad(MIN_BEND))
		for key, list in grid do
			local gx, gz = string.match(key, "^(.-),(.-)$")
			for dx = -1, 1 do
				for dz = -1, 1 do
					local other = grid[(tonumber(gx) :: number + dx) .. "," .. (tonumber(gz) :: number + dz)]
					if other then
						for _, a in list do
							for _, b in other do
								local dot = a.n:Dot(b.n)
								if a.part ~= b.part and a.part:GetFullName() < b.part:GetFullName() and dot > minDot and dot < maxDot then
									-- do they meet? the two faces' nearest ends
									local dc = b.c - a.c
									local along = a.u
									if math.abs(a.u.Y) > 0.5 then
										along = a.v
									end
									local ha = if along == a.u then a.hu else a.hv
									local alongB = if math.abs(b.u.Y) > 0.5 then b.v else b.u
									local hb = if math.abs(b.u.Y) > 0.5 then b.hv else b.hu
									local sa = if dc:Dot(along) > 0 then 1 else -1
									local sb = if dc:Dot(alongB) > 0 then -1 else 1
									local ea = a.c + along * sa * ha
									local eb = b.c + alongB * sb * hb
									local flat = Vector3.new(ea.X - eb.X, 0, ea.Z - eb.Z).Magnitude
									if flat < BEND_GAP and math.abs(a.c.Y - b.c.Y) < a.hu + a.hv then
										table.insert(found, {
											kind = "bent",
											a = a.part,
											b = b.part,
											at = (ea + eb) / 2,
											gap = math.deg(math.acos(math.clamp(dot, -1, 1))),
											over = 0,
											nameA = label(a.part),
											nameB = label(b.part),
										})
									end
								end
							end
						end
					end
				end
			end
			task.wait()
		end
	end
	-- the summary: by kind and the two pieces' names
	local byName: { [string]: { n: number, at: Vector3, over: number, gap: number } } = {}
	for _, f in found do
		local n1, n2 = f.nameA, f.nameB
		-- (one line per kind of piece: the building's name, not its number)
		local k = f.kind .. " | " .. (if n1 < n2 then n1 .. " + " .. n2 else n2 .. " + " .. n1)
		local e = byName[k]
		if not e then
			e = { n = 0, at = f.at, over = 0, gap = f.gap }
			byName[k] = e
		end
		e.n += 1
		e.over = math.max(e.over, f.over)
	end
	local rows = {}
	for k, e in byName do
		table.insert(rows, { k = k, e = e })
	end
	table.sort(rows, function(x, y)
		return x.e.n > y.e.n
	end)
	local lines = { string.format("faces %d, compared %d, found %d, kinds %d", #all, checks, #found, #rows) }
	for i = 1, math.min(#rows, o.rows or 60) do
		local r = rows[i]
		table.insert(lines, string.format("%s x%d biggest %.1f e.g. %.0f,%.0f,%.0f gap %.3f", r.k, r.e.n, r.e.over, r.e.at.X, r.e.at.Y, r.e.at.Z, r.e.gap))
	end
	return found, table.concat(lines, "\n")
end

return SurfaceCheck
