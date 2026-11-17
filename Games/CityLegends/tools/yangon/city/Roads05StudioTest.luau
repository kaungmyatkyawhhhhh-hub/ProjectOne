--[[
	Roads05StudioTest (Studio, Edit; J16, 18 Nov 2026): builds the roads05 Studio test spots one at a time, with the paint.
	Data: tools/yangon/city/roads05_studiotest.py -> imports/sync/roads05_studiotest.rbxmx -> PATCH of asset 133014134133489
	(open_cloud_invoke, content type model/x-rbxm). Then, in execute_luau calls (each under ~5 s; long work is spawned):

		-- 1. load (spawned; poll _G.RT.state until "loaded ..." or "ERR ...")
		local m = game:GetService("InsertService"):LoadAsset(133014134133489)
		local T = require(m:FindFirstChild("Roads05StudioTest", true):Clone())
		_G.RT = T  T.install(m)          -- moves the modules, makes the no-terrain copy, Y.load(), reads spots + paint
		-- 2. one spot (spawned; poll T.log[name] until not "running")
		_G.RT.run("ycentral")            -- workspace.Roads05Test.<name>: roads (lifted T.LIFT), then the paint
		-- 3. cameras for screen_capture (lift added): _G.RT.cam("ycentral", "overview" | "closeup" | "driver")
		-- 4. _G.RT.clean() (spawned): scratch folder, YangonScraps, data modules, the copy; poll _G.RT.state == "clean ..."

	Terrain: the copy of YangonRoads has every `workspace.Terrain:Fill*` call swapped for a no-op (counted in T.fills),
	so the place's terrain is never written. Paint: triangles rayed onto the built surface (40 studs above the data
	height ... 40 under it, the hit nearest the data height), laid T.PAINT_LIFT over it as two WedgeParts each; a vertex with no surface within 6 studs of its data height
	is counted and its triangle left out (T.log[name]).
]]

local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")

local T = {}
T.LIFT = 400
T.PAINT_LIFT = 0.08
T.PAINT_T = 0.04
T.log = {}
T.state = "new"
T.fills = 0
T.COLOR = {
	LW = Color3.fromRGB(232, 232, 226),
	LY = Color3.fromRGB(232, 184, 52),
	LZ = Color3.fromRGB(230, 190, 110),
}

local function sum(t)
	local h = 0
	for i = 1, #t do
		h = (h * 31 + string.byte(t, i)) % 2147483647
	end
	return h
end
T.sum = sum

function T.install(model: Instance)
	T.state = "installing"
	task.spawn(function()
		local ok, err = pcall(function()
			local f = model:FindFirstChild("YangonToolsIn", true)
			local YD = SS.YangonData
			for _, c in YD:GetChildren() do
				if c.Name:match("^Roads05_") then
					c:Destroy()
				end
			end
			local paint, spots, n = {}, nil, 0
			for _, c in f:GetChildren() do
				if c.Name:match("^Roads05_%d") then
					c.Parent = YD
					n += 1
				elseif c.Name:match("^Roads05Paint_") then
					paint[tonumber(c.Name:match("%d+$"))] = require(c)
				elseif c.Name == "Roads05Spots" then
					spots = Http:JSONDecode(require(c))
				elseif c.Name == "YangonRoads" then
					local o = SS.ClaudeTools:FindFirstChild("YangonRoads")
					if o then
						o:Destroy()
					end
					c.Parent = SS.ClaudeTools
				end
			end
			model:Destroy()
			T.spots = spots
			T.paint = {}
			for _, chunk in paint do
				for line in chunk:gmatch("[^\n]+") do
					table.insert(T.paint, line)
				end
			end
			-- the no-terrain copy (never parented to the place: required from nil)
			_G.RTNoTerrain = {
				FillBlock = function() T.fills += 1 end,
				FillCylinder = function() T.fills += 1 end,
				FillBall = function() T.fills += 1 end,
				FillWedge = function() T.fills += 1 end,
			}
			local src, k = SS.ClaudeTools.YangonRoads.Source:gsub("workspace%.Terrain:Fill", "_G.RTNoTerrain:Fill")
			local j = SS.ClaudeTools.YangonRoads:Clone()
			j.Name = "YangonRoadsRT"
			j.Source = src
			T.yrSum = sum(SS.ClaudeTools.YangonRoads.Source)
			local Y = require(j)
			Y.load()
			T.Y = Y
			T.state = string.format("loaded %d roads, %d data modules, %d paint tris, %d fill calls swapped, YR %d", #Y.list, n, #T.paint, k, T.yrSum)
		end)
		if not ok then
			T.state = "ERR " .. tostring(err)
		end
	end)
	return "spawned"
end

-- two WedgeParts make a triangle (a, b, c world points)
local function tri(a, b, c, parent, color)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	if ab.Magnitude < 1e-3 or ac.Magnitude < 1e-3 or bc.Magnitude < 1e-3 then
		return 0
	end
	local right = ac:Cross(ab)
	if right.Magnitude < 1e-6 then
		return 0
	end
	right = right.Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local h = math.abs(ab:Dot(up))
	local n = 0
	for _, w in { { (a + b) / 2, right, math.abs(ab:Dot(back)) }, { (a + c) / 2, -right, math.abs(ac:Dot(back)) } } do
		if w[3] > 1e-3 and h > 1e-3 then
			local p = Instance.new("WedgePart")
			p.Name = "Paint"
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Material = Enum.Material.SmoothPlastic
			p.Color = color
			p.Size = Vector3.new(T.PAINT_T, h, w[3])
			local s = if w[2] == right then 1 else -1
			p.CFrame = CFrame.fromMatrix(w[1], w[2], up, back * s)
			p.Parent = parent
			n += 1
		end
	end
	return n
end

function T.layPaint(sp, folder)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { folder }
	local pf = Instance.new("Folder")
	pf.Name = "Paint"
	pf.Parent = folder
	T.far = 0
	local miss, skipped, parts, chunk = 0, 0, 0, Instance.new("Folder")
	chunk.Name = "c"
	for li = sp.paint[1], sp.paint[2] do
		local line = T.paint[li]
		local k, rest = line:match("^(%S+) (.*)$")
		local v = {}
		for u in rest:gmatch("%S+") do
			table.insert(v, tonumber(u))
		end
		local pts = {}
		for q = 0, 2 do
			local x, z, y = v[q * 3 + 1], v[q * 3 + 2], v[q * 3 + 3] + T.LIFT
			-- the surface nearest the data height (a ground line under a deck, a deck line over a road; up to 4 layers)
			local hit, o = nil, Vector3.new(x, y + 40, z)
			for _ = 1, 4 do
				local h = workspace:Raycast(o, Vector3.new(0, y - 40 - o.Y, 0), rp)
				if not h then
					break
				end
				if not hit or math.abs(h.Position.Y - y) < math.abs(hit.Position.Y - y) then
					hit = h
				end
				o = h.Position - Vector3.new(0, 0.05, 0)
			end
			if hit and math.abs(hit.Position.Y - y) > 6 then
				T.far = (T.far or 0) + 1 -- no surface within 6 studs of the data height (e.g. a deck not built in this box)
				hit = nil
			end
			if hit then
				pts[q + 1] = hit.Position + hit.Normal * (T.PAINT_LIFT + T.PAINT_T / 2)
			else
				miss += 1
			end
		end
		if pts[1] and pts[2] and pts[3] then -- paint never hangs in the air: a triangle with a vertex off every surface is left out
			parts += tri(pts[1], pts[2], pts[3], chunk, T.COLOR[k] or T.COLOR.LW)
		else
			skipped += 1
		end
		if (li - sp.paint[1]) % 400 == 399 then
			chunk.Parent = pf
			chunk = Instance.new("Folder")
			chunk.Name = "c"
			task.wait()
		end
	end
	chunk.Parent = pf
	return string.format("paint tris %d wedges %d, vertices off the surface %d (of them over 6 studs from the data height %d), tris left out %d", sp.paint[2] - sp.paint[1] + 1, parts, miss, T.far, skipped)
end

function T.run(name: string)
	local sp = T.spots[name]
	local root = workspace:FindFirstChild("Roads05Test") or Instance.new("Folder")
	root.Name = "Roads05Test"
	root.Parent = workspace
	for _, o in root:GetChildren() do
		o:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	T.log[name] = "running"
	task.spawn(function()
		local fills0 = T.fills
		local ok, res = pcall(function()
			return T.Y.stepCell(sp.box, f)
		end)
		local n = 0
		for _, d in f:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame += Vector3.new(0, T.LIFT, 0)
				n += 1
				if n % 3000 == 0 then
					task.wait()
				end
			end
		end
		local pr = if ok then T.layPaint(sp, f) else "no paint"
		T.log[name] = string.format("%s %s | parts lifted %d | terrain writes skipped %d | %s", ok and "OK" or "ERR", tostring(res), n, T.fills - fills0, pr)
	end)
	return "spawned " .. name
end

function T.cam(name: string, view: string)
	local c = T.spots[name].cams[view]
	return { c.pos[1], c.pos[2] + T.LIFT, c.pos[3] }, { c.at[1], c.at[2] + T.LIFT, c.at[3] }
end

-- what is under screen pixels (judging a shot): {{px, py}, ...}
function T.pick(campos: Vector3, target: Vector3, pts)
	local cam = workspace.CurrentCamera
	local old = cam.CFrame
	cam.CFrame = CFrame.lookAt(campos, target)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { workspace.Roads05Test }
	local out = {}
	for _, p in pts do
		local ray = cam:ViewportPointToRay(p[1], p[2])
		local h = workspace:Raycast(ray.Origin, ray.Direction * 3000, rp)
		table.insert(out, string.format("(%d,%d) -> %s", p[1], p[2], h and string.format("%.1f %.2f %.1f %s/%s", h.Position.X, h.Position.Y - T.LIFT, h.Position.Z, h.Instance.Parent.Name, h.Instance.Name) or "nothing"))
	end
	cam.CFrame = old
	return table.concat(out, "\n")
end

function T.clean()
	T.state = "cleaning"
	task.spawn(function()
		local root = workspace:FindFirstChild("Roads05Test")
		if root then
			for _, f in root:GetChildren() do
				local n = 0
				for _, c in f:GetDescendants() do
					if c:IsA("BasePart") then
						c:Destroy()
						n += 1
						if n % 2000 == 0 then
							task.wait()
						end
					end
				end
				f:Destroy()
			end
			root:Destroy()
		end
		local sc = SS:FindFirstChild("YangonScraps")
		if sc then
			sc:Destroy()
		end
		local d = 0
		for _, c in SS.YangonData:GetChildren() do
			if c.Name:match("^Roads05") then
				c:Destroy()
				d += 1
			end
		end
		T.Y, T.paint, _G.RTNoTerrain = nil, nil, nil
		T.state = "clean, data modules removed " .. d
	end)
	return "spawned"
end

return T
