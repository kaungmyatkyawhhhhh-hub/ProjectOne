--[[
	SurfaceFix (owner, 2026-11-06, pictures of a drive and a wall: "FIND IT ALL"): two visible faces in the
	same place flicker and show patches of each other's texture. This finds every such pair under a
	root and gives each group of them its own planes, GAP studs apart; the biggest face stays put.

	Two faces fight when they look the same way, overlap at least MIN_OVER studs both ways and their
	planes are under FIGHT apart (the flicker rule in Games/CityLegends/CLAUDE.md).

	Runs on the server once the venues are built (they are built by code), and in Studio's Edit mode on
	the saved map (tools/riviera/SurfaceCheck.luau lists the same pairs and the near ones).

	SurfaceFix.run(root, opts?) -> pieces moved, rounds, fights left
	opts: { rounds: number?, keepOld: boolean?, onlyUp: boolean? } (keepOld: each moved piece keeps its first
	CFrame in the attribute OldFixCFrame, for SurfaceFix.undo; onlyUp: faces looking up only: a kerb stands
	0.05 in front of its pavement on purpose)
]]

local SurfaceFix = {}

local FIGHT = 0.06
local GAP = 0.08
local MIN_OVER = 0.7 -- (a wall piece's 0.6 end at a corner is too thin to see)
local MIN_AREA = 1
local MOST = 0.45 -- no piece moves further than this
local TOTAL_WAIT = 20000 -- faces between yields

type Face = {
	part: BasePart,
	n: Vector3,
	c: Vector3,
	u: Vector3,
	v: Vector3,
	hu: number,
	hv: number,
	area: number,
}

local function axis(cf: CFrame, name: string): Vector3
	if name == "X" then
		return cf.RightVector
	elseif name == "Y" then
		return cf.UpVector
	end
	return -cf.LookVector
end

local AXES = { { "X", "Y", "Z" }, { "Y", "Z", "X" }, { "Z", "X", "Y" } }

local function addFaces(p: BasePart, out: { Face }, onlyUp: boolean?)
	local s, cf = p.Size, p.CFrame
	for _, a in AXES do
		local hu, hv = (s :: any)[a[2]] / 2, (s :: any)[a[3]] / 2
		local area = 4 * hu * hv
		if area >= MIN_AREA then
			local nv = axis(cf, a[1])
			local h = (s :: any)[a[1]] / 2
			local u, v = axis(cf, a[2]), axis(cf, a[3])
			for _, sign in { 1, -1 } do
				local n = nv * sign
				if n.Y > -0.9 and (not onlyUp or n.Y > 0.9) then
					table.insert(out, { part = p, n = n, c = p.Position + n * h, u = u, v = v, hu = hu, hv = hv, area = area })
				end
			end
		end
	end
end

local function spread(f: Face, ax: Vector3): number
	return f.hu * math.abs(f.u:Dot(ax)) + f.hv * math.abs(f.v:Dot(ax))
end

local function overlaps(a: Face, b: Face): boolean
	local dc = b.c - a.c
	local ou = math.min(a.hu + spread(b, a.u) - math.abs(dc:Dot(a.u)), 2 * a.hu, 2 * spread(b, a.u))
	if ou < MIN_OVER then
		return false
	end
	local ov = math.min(a.hv + spread(b, a.v) - math.abs(dc:Dot(a.v)), 2 * a.hv, 2 * spread(b, a.v))
	if ov < MIN_OVER then
		return false
	end
	local pu = b.hu + spread(a, b.u) - math.abs(dc:Dot(b.u))
	local pv = b.hv + spread(a, b.v) - math.abs(dc:Dot(b.v))
	return pu > 0 and pv > 0
end

-- the pieces this may move: anchored blocks that nothing swings or slides
local function usable(p: Instance): boolean
	return p:IsA("Part")
		and p.Anchored
		and p.Shape == Enum.PartType.Block
		and p.Transparency < 0.9
		and not p:HasTag("HouseGate")
		and p:GetAttribute("NoSurfaceFix") == nil
end

local function scan(root: Instance, onlyUp: boolean?): { { a: Face, b: Face, gap: number } }
	local faces: { Face } = {}
	local n = 0
	for _, p in root:GetDescendants() do
		n += 1
		if n % TOTAL_WAIT == 0 then
			task.wait()
		end
		if usable(p) then
			addFaces(p :: BasePart, faces, onlyUp)
		end
	end
	local buckets: { [string]: { Face } } = {}
	for i, f in faces do
		local d = f.n:Dot(f.c)
		local key = math.round(f.n.X * 40) .. "," .. math.round(f.n.Y * 40) .. "," .. math.round(f.n.Z * 40) .. ":" .. math.floor(d / FIGHT)
		local b = buckets[key]
		if not b then
			b = {}
			buckets[key] = b
		end
		table.insert(b, f)
		if i % TOTAL_WAIT == 0 then
			task.wait()
		end
	end
	local found = {}
	local checks = 0
	local function compare(l1: { Face }, l2: { Face }, same: boolean)
		for i, a in l1 do
			for j = if same then i + 1 else 1, #l2 do
				local b = l2[j]
				checks += 1
				if checks % 2000000 == 0 then
					task.wait()
				end
				if a.part ~= b.part and a.n:Dot(b.n) > 0.9995 and (b.c - a.c).Magnitude < a.hu + a.hv + b.hu + b.hv then
					local gap = a.n:Dot(b.c - a.c)
					if math.abs(gap) < FIGHT and overlaps(a, b) then
						table.insert(found, { a = a, b = b, gap = gap })
					end
				end
			end
		end
	end
	for key, list in buckets do
		compare(list, list, true)
		local head, tail = string.match(key, "^(.*):(.-)$")
		local nextList = buckets[(head :: string) .. ":" .. ((tonumber(tail) :: number) + 1)]
		if nextList then
			compare(list, nextList, false)
		end
	end
	return found
end

function SurfaceFix.run(root: Instance, opts: { rounds: number?, keepOld: boolean?, onlyUp: boolean? }?): (number, number, number)
	local o = opts or {}
	local moved: { [BasePart]: boolean } = {}
	local total: { [BasePart]: number } = {}
	local rounds, left = 0, 0
	for round = 1, o.rounds or 4 do
		rounds = round
		local fights = scan(root, o.onlyUp)
		left = #fights
		if left == 0 then
			break
		end
		-- faces that fight, joined up: each group gets planes GAP apart, the biggest face stays
		local links: { [Face]: { Face } } = {}
		for _, f in fights do
			links[f.a] = links[f.a] or {}
			links[f.b] = links[f.b] or {}
			table.insert(links[f.a], f.b)
			table.insert(links[f.b], f.a)
		end
		local seen: { [Face]: boolean } = {}
		local shift: { [BasePart]: Vector3 } = {}
		for first in links do
			if not seen[first] then
				seen[first] = true
				local group, stack = {}, { first }
				while #stack > 0 do
					local f = table.remove(stack) :: Face
					table.insert(group, f)
					for _, g in links[f] do
						if not seen[g] then
							seen[g] = true
							table.insert(stack, g)
						end
					end
				end
				table.sort(group, function(x, y)
					return x.area > y.area
				end)
				local n = group[1].n
				local placed: { { f: Face, d: number } } = {}
				for _, f in group do
					local d = n:Dot(f.c)
					local near = {}
					for _, q in placed do
						if overlaps(f, q.f) then
							table.insert(near, q.d)
						end
					end
					local function free(s: number): boolean
						for _, qd in near do
							if math.abs(d + s - qd) < GAP - 0.002 then
								return false
							end
						end
						return true
					end
					local best = 0
					if not free(0) then
						best = math.huge
						for _, qd in near do
							-- (dead level: forward, behind is often taken)
							for _, s in { qd + GAP - d, qd - GAP - d } do
								local cost = math.abs(s) + (if s < 0 then 0.001 else 0)
								if free(s) and cost < math.abs(best) + (if best < 0 then 0.001 else 0) then
									best = s
								end
							end
						end
					end
					if best ~= 0 and best < math.huge then
						if not shift[f.part] then
							shift[f.part] = n * best
						end
					end
					table.insert(placed, { f = f, d = d + (if best < math.huge then best else 0) })
				end
			end
		end
		for p, s in shift do
			local sum = (total[p] or 0) + s.Magnitude
			if sum <= MOST then
				total[p] = sum
				if o.keepOld and p:GetAttribute("OldFixCFrame") == nil then
					p:SetAttribute("OldFixCFrame", p.CFrame)
				end
				p.CFrame += s
				moved[p] = true
			end
		end
		task.wait()
	end
	local count = 0
	for _ in moved do
		count += 1
	end
	return count, rounds, left
end

function SurfaceFix.undo(root: Instance): number
	local n = 0
	for _, p in root:GetDescendants() do
		local cf = p:GetAttribute("OldFixCFrame")
		if typeof(cf) == "CFrame" and p:IsA("BasePart") then
			p.CFrame = cf
			p:SetAttribute("OldFixCFrame", nil)
			n += 1
		end
	end
	return n
end

return SurfaceFix
