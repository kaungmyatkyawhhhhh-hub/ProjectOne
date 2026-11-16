--[[
	ShwedagonPlace (Studio, Edit; 2026-11-16): places the 1:1 Shwedagon made by tools/yangon/landmarks3d/shwedagon3d.py.

	Data (ShwData module = one string, lines):
	  H|axisX axisZ y0 yawDeg                      the complex frame: stupa axis on the platform, turned yawDeg about Y
	  G|grp|Material|Variant|r g b                 look per material group
	  M|name|piece|grp|cx cy cz|sx sy sz           one uploaded mesh: its box centre / size in the piece's local studs
	  I|piece|E N U yaw s                          one instance in the stupa frame (metres, yaw rad, uniform scale)
	  C|box|E N U sE sN sU yaw                     collision box (metres; U = centre)
	  C|cyl|E N U0 U1 r                            collision cylinder
	  C|ramp|E N U len w pitch yaw [h]             stair ramp (top surface on the nosing line) / side rail (h given)
	Local studs of a piece: x = 3E, y = 3U, z = -3N. Pieces with no I line are placed once at the origin.

	local P = require(ServerStorage.ClaudeTools.ShwedagonPlace:Clone())
	P.place(holding, require(dataModule), parentFolder) -> Model "Shwedagon" (Visual / Collision) + Model "Shwedagon_Hill_TEMP"
	  (runs in chunks with task.wait; status in the Model's attribute "Status")
]]

local M = {}

local SINGLE = { Halls = true, Platform = true, Hill_TEMP = true, Elevators = true, StairS = true, StairE = true, StairN = true, StairW = true }

local function split(s, sep)
	local out = {}
	for part in string.gmatch(s, "([^" .. sep .. "]+)") do
		table.insert(out, part)
	end
	return out
end

local function nums(s)
	local out = {}
	for v in string.gmatch(s, "%S+") do
		table.insert(out, tonumber(v))
	end
	return out
end

function M.parse(text)
	local d = { groups = {}, meshes = {}, byPiece = {}, inst = {}, coll = {} }
	for line in string.gmatch(text, "[^\n]+") do
		local f = split(line, "|")
		local k = f[1]
		if k == "H" then
			local n = nums(f[2])
			d.axisX, d.axisZ, d.y0, d.yaw = n[1], n[2], n[3], n[4]
		elseif k == "G" then
			local c = nums(f[5])
			d.groups[f[2]] = { mat = f[3], var = f[4] ~= "-" and f[4] or nil, color = Color3.fromRGB(c[1], c[2], c[3]) }
		elseif k == "M" then
			local c, s = nums(f[5]), nums(f[6])
			local row = { name = f[2], piece = f[3], grp = f[4], c = Vector3.new(c[1], c[2], c[3]), s = Vector3.new(s[1], s[2], s[3]) }
			table.insert(d.meshes, row)
			d.byPiece[row.piece] = d.byPiece[row.piece] or {}
			table.insert(d.byPiece[row.piece], row)
		elseif k == "I" then
			local n = nums(f[3])
			table.insert(d.inst, { piece = f[2], E = n[1], N = n[2], U = n[3], yaw = n[4], s = n[5] })
		elseif k == "C" then
			table.insert(d.coll, { kind = f[2], n = nums(f[3]) })
		end
	end
	return d
end

local function frameCF(d, E, N, U)
	return CFrame.new(d.axisX, d.y0, d.axisZ) * CFrame.Angles(0, math.rad(d.yaw), 0) * CFrame.new(3 * E, 3 * U, -3 * N)
end
M.frameCF = frameCF

function M.place(holding: Instance, text: string, parent: Instance)
	local d = M.parse(text)
	local src = {}
	for _, x in holding:GetDescendants() do
		if x:IsA("MeshPart") then
			local nm = x.Name
			if not string.match(nm, "^SHW_") and x.Parent then
				nm = string.gsub(x.Parent.Name, "_Node$", "")
			end
			src[nm] = x
		end
	end
	local missing = {}
	for _, row in d.meshes do
		if not src[row.name] then
			table.insert(missing, row.name)
		end
	end
	if #missing > 0 then
		return "missing meshes: " .. table.concat(missing, ", ")
	end
	local old = parent:FindFirstChild("Shwedagon")
	if old then
		old:Destroy()
	end
	local oldHill = parent:FindFirstChild("Shwedagon_Hill_TEMP")
	if oldHill then
		oldHill:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "Shwedagon"
	root:SetAttribute("Status", "placing")
	root:SetAttribute("Source", "tools/yangon/landmarks3d/shwedagon3d.py")
	root.Parent = parent
	local visual = Instance.new("Folder")
	visual.Name = "Visual"
	visual.Parent = root
	local hill = Instance.new("Model")
	hill.Name = "Shwedagon_Hill_TEMP"
	hill.Parent = parent
	local insts = table.clone(d.inst)
	local have = {}
	for _, i in insts do
		have[i.piece] = true
	end
	for piece in d.byPiece do
		if not have[piece] then
			table.insert(insts, { piece = piece, E = 0, N = 0, U = 0, yaw = 0, s = 1 })
		end
	end
	local folders = {}
	local placed = 0
	local toFix = {}
	for k, i in insts do
		local rows = d.byPiece[i.piece]
		if rows then
			local folder
			if i.piece == "Hill_TEMP" then
				folder = hill
			else
				folder = folders[i.piece]
				if not folder then
					folder = Instance.new("Model")
					folder.Name = i.piece
					folder.Parent = visual
					folders[i.piece] = folder
				end
			end
			local base = frameCF(d, i.E, i.N, i.U) * CFrame.Angles(0, i.yaw, 0)
			for _, row in rows do
				local q = src[row.name]:Clone()
				for _, ch in q:GetChildren() do
					ch:Destroy()
				end
				q.Name = row.name
				q.Size = row.s * i.s
				q.CFrame = base * CFrame.new(row.c * i.s)
				q.Anchored = true
				local isHill = row.grp == "HILL" and i.piece == "Hill_TEMP"
				q.CanCollide = isHill
				q.CanQuery = isHill
				q.CanTouch = false
				q.CastShadow = row.grp ~= "HILL"
				q.DoubleSided = false
				local g = d.groups[row.grp]
				q.Material = Enum.Material[g.mat]
				q.MaterialVariant = g.var or ""
				q.Color = g.color
				q:SetAttribute("Group", row.grp)
				q.Parent = folder
				table.insert(toFix, { q, isHill })
				placed += 1
			end
		end
		if k % 60 == 0 then
			root:SetAttribute("Status", "placed " .. placed)
			task.wait()
		end
	end
	for n, it in toFix do
		pcall(function()
			it[1].CollisionFidelity = it[2] and Enum.CollisionFidelity.PreciseConvexDecomposition or Enum.CollisionFidelity.Box
		end)
		if n % 40 == 0 then
			task.wait()
		end
	end
	-- collision
	local cf = Instance.new("Folder")
	cf.Name = "Collision"
	cf.Parent = root
	local nC = 0
	for k, c in d.coll do
		local p = Instance.new("Part")
		p.Anchored = true
		p.Transparency = 1
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		local n = c.n
		if c.kind == "box" then
			p.Size = Vector3.new(math.max(0.2, 3 * n[4]), math.max(0.2, 3 * n[6]), math.max(0.2, 3 * n[5]))
			p.CFrame = frameCF(d, n[1], n[2], n[3]) * CFrame.Angles(0, n[7], 0)
		elseif c.kind == "cyl" then
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(3 * (n[4] - n[3]), 6 * n[5], 6 * n[5])
			p.CFrame = frameCF(d, n[1], n[2], (n[3] + n[4]) / 2) * CFrame.Angles(0, 0, math.pi / 2)
		elseif c.kind == "ramp" then
			local h = n[8]
			local thick = h and 3 * h or 1.0
			p.Size = Vector3.new(3 * n[4], thick, 3 * n[5])
			local cfr = frameCF(d, n[1], n[2], n[3]) * CFrame.Angles(0, n[7], 0) * CFrame.Angles(0, 0, n[6])
			if not h then
				cfr *= CFrame.new(0, -thick / 2, 0)
			end
			p.CFrame = cfr
		end
		p.Name = "C_" .. c.kind
		p.Parent = cf
		nC += 1
		if k % 150 == 0 then
			task.wait()
		end
	end
	root:SetAttribute("Status", string.format("done: %d meshes, %d collision parts", placed, nC))
	return root:GetAttribute("Status")
end

return M
