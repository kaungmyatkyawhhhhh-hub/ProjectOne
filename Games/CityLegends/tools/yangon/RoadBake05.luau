--[[
	RoadBake05 (Studio, Edit; ServerStorage.ClaudeTools.RoadBake05; 2026-11-16): the 1:1 roads built by the batch 0.5
	builder (YangonRoads.stepCell, parts) go out of Studio as compact pages for tools/yangon/city/roads05_bake.py,
	which turns them into meshes per 1536-stud cell; the parts are then deleted. Also places the bake's collision
	boxes.

	local B = require(game.ServerStorage.ClaudeTools.RoadBake05:Clone())
	B.collect(root, cell) -> "n parts, pages": every BasePart under root (not "Line" / "Zebra" paint: the paint is
	    roads05_paint.py's), encoded into pages of about 95,000 characters (kept in _G.RoadBake05Pages)
	B.page(k) -> "@P<cell>_<kk>@" .. data .. "@END@" padded with "#" (an MCP result this big lands in a file)
	B.clear(root) -> parts destroyed (a chunk at a time)
	B.collide(text, folder) -> boxes: one line per box "kind cx cy cz rx ry rz ux uy uz sx sy sz" (an oriented box:
	    right and up axes, size along right / up / back); Transparency 1, CanCollide, CanQuery, attribute RoadBox
	B.spawn(fn) / B.status()

	Part record: kind char, class char, then 12 numbers in 3 base-90 characters each (-364,499 .. 364,499; "~n~" past
	that): position delta from the page's previous part x100, the right (X) axis x100,000, the up (Y) axis x100,000,
	size x100.
	kinds: R asphalt (roads, mouths, ring, deck surface), P pavement, r red kerb band, w white kerb band, m median /
	island grass, B bridge concrete (parapets, ramp walls, girders, pier caps, piers), ? anything else (reported).
	classes: B block, W wedge, C cylinder, S sphere-mesh part.
]]

local SS = game:GetService("ServerStorage")
local M = {}

local BASE = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&()*+,-./:;<=>?@[]^_{|}"
local NB = #BASE
local HALF = (NB * NB * NB - 1) // 2
local CH = {}
for i = 1, NB do
	CH[i - 1] = string.sub(BASE, i, i)
end

local function enc(v: number): string
	local i = math.floor(v + 0.5)
	if i < -HALF or i > HALF then
		return "~" .. i .. "~"
	end
	i += HALF
	local a = i // (NB * NB)
	local b = (i // NB) % NB
	local c = i % NB
	return CH[a] .. CH[b] .. CH[c]
end

local SKIP = { Line = true, Zebra = true, Barrier = true }
local BRIDGE = { Parapet = true, RampWall = true, Girder = true, PierCap = true, Pier = true, LegWall = true }

local function kindOf(p: BasePart): string
	local n = p.Name
	if n == "Road" or n == "TurningCircle" then
		return "R"
	elseif n == "Pavement" or n == "Shoulder" then
		return "P"
	elseif n == "Kerb" or n == "MedianKerb" then
		local c = p.Color
		return if c.R > 0.6 and c.G < 0.45 then "r" else "w"
	elseif n == "Median" or n == "Island" or n == "IslandMound" then
		return "m"
	elseif BRIDGE[n] then
		return "B"
	end
	return "?"
end

local function classOf(p: BasePart): string
	if p:IsA("WedgePart") then
		return "W"
	elseif p:IsA("Part") then
		if p:FindFirstChildOfClass("SpecialMesh") then
			return "S"
		elseif (p :: Part).Shape == Enum.PartType.Cylinder then
			return "C"
		end
		return "B"
	end
	return "B"
end

function M.collect(root: Instance, cell: string): string
	local parts = {}
	local unknown = {}
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and not SKIP[d.Name] then
			local k = kindOf(d)
			if k == "?" then
				unknown[d.Name] = (unknown[d.Name] or 0) + 1
			end
			table.insert(parts, d)
		end
	end
	local pages = {}
	local buf = {}
	local len = 0
	local px, py, pz = 0, 0, 0
	local counts = {}
	for i, p in parts do
		local cf = p.CFrame
		local pos = cf.Position
		local r, u = cf.XVector, cf.YVector
		local s = p.Size
		local k = kindOf(p)
		counts[k] = (counts[k] or 0) + 1
		local x, y, z = math.floor(pos.X * 100 + 0.5), math.floor(pos.Y * 100 + 0.5), math.floor(pos.Z * 100 + 0.5)
		local rec = k .. classOf(p) .. enc(x - px) .. enc(y - py) .. enc(z - pz)
			.. enc(r.X * 100000) .. enc(r.Y * 100000) .. enc(r.Z * 100000)
			.. enc(u.X * 100000) .. enc(u.Y * 100000) .. enc(u.Z * 100000)
			.. enc(s.X * 100) .. enc(s.Y * 100) .. enc(s.Z * 100)
		px, py, pz = x, y, z
		table.insert(buf, rec)
		len += #rec
		if len > 94000 then
			table.insert(pages, table.concat(buf))
			buf, len = {}, 0
			px, py, pz = 0, 0, 0
		end
		if i % 5000 == 0 then
			task.wait()
		end
	end
	if #buf > 0 then
		table.insert(pages, table.concat(buf))
	end
	_G.RoadBake05Pages = pages
	_G.RoadBake05Cell = cell
	local c = {}
	for k, v in counts do
		table.insert(c, k .. " " .. v)
	end
	local u = {}
	for k, v in unknown do
		table.insert(u, k .. " " .. v)
	end
	return string.format("%d parts, %d pages (%s)%s", #parts, #pages, table.concat(c, ", "), if #u > 0 then " UNKNOWN: " .. table.concat(u, ", ") else "")
end

function M.page(k: number): string
	local pages = _G.RoadBake05Pages
	local body = pages and pages[k]
	if not body then
		return "no page " .. k
	end
	local s = string.format("@P%s_%02d@", _G.RoadBake05Cell, k) .. body .. "@END@"
	if #s < 95500 then
		s ..= string.rep("#", 95500 - #s)
	end
	return s
end

function M.clear(root: Instance): number
	local n = 0
	for _, f in root:GetChildren() do
		for i, c in f:GetDescendants() do
			if c:IsA("BasePart") then
				n += 1
			end
		end
		for i, c in f:GetChildren() do
			c:Destroy()
			if i % 2000 == 0 then
				task.wait()
			end
		end
	end
	return n
end

function M.collide(text: string, folder: Instance): number
	local n = 0
	for line in string.gmatch(text, "[^\n]+") do
		local k, rest = string.match(line, "^(%a+)%s+(.*)$")
		if k then
			local v = {}
			for w in string.gmatch(rest, "%S+") do
				table.insert(v, tonumber(w))
			end
			if #v == 12 then
				local r = Vector3.new(v[4], v[5], v[6]).Unit
				local u = Vector3.new(v[7], v[8], v[9]).Unit
				local p = Instance.new("Part")
				p.Name = "RCol"
				p.Anchored = true
				p.Size = Vector3.new(v[10], v[11], v[12])
				p.CFrame = CFrame.fromMatrix(Vector3.new(v[1], v[2], v[3]), r, u)
				p.Transparency = 1
				p.CanCollide = true
				p.CanQuery = true
				p.CanTouch = false
				p.CastShadow = false
				p.TopSurface = Enum.SurfaceType.Smooth
				p.BottomSurface = Enum.SurfaceType.Smooth
				p:SetAttribute("RoadBox", k)
				p.Parent = folder
				n += 1
				if n % 400 == 0 then
					task.wait()
				end
			end
		end
	end
	return n
end

function M.spawn(fn)
	SS:SetAttribute("RoadBakeStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		SS:SetAttribute("RoadBakeStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS:GetAttribute("RoadBakeStatus"))
end

return M
