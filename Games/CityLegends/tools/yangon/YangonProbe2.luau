--[[
	YangonProbe2 (Studio, Edit mode; whole-Yangon city generator, 14 Nov 2026).

	Measures heights for the Python generator (tools/yangon/city/): for every point in a data string module
	ServerStorage.ClaudeTools.ProbePoints_<n> (lines "x z"), a ray straight down from y 600:
	  * the terrain's ground (water ignored),
	  * the first hit on the map's road parts (Workspace.Yangon.Roads / Decks / Sites / CarCare): its y and a one-letter kind
	    (R road / turning circle, P pavement, K kerb, D deck, S site plate, O other, - none).
	Writes the answers as lines "gy|ty|k" (one decimal) into StringValues ServerStorage.YangonData.ProbeOut.Page_<i>, each under
	95,000 characters, so execute_luau can return one page a call.

	local P = require(game.ServerStorage.ClaudeTools.YangonProbe2:Clone())
	P.spawn({ "ProbePoints_1", "ProbePoints_2" })   then P.status(), then P.page(i)
]]

local SS = game:GetService("ServerStorage")

local M = {}

local function kindOf(inst: Instance): string
	local n = inst.Name
	if n == "Road" or n == "TurningCircle" or n == "Island" then
		return "R"
	elseif n == "Pavement" or n == "PaveFill" then
		return "P"
	elseif n == "Kerb" or n == "MedianKerb" then
		return "K"
	end
	local a = inst:FindFirstAncestor("Decks")
	if a then
		return "D"
	end
	if inst:FindFirstAncestor("Sites") then
		return "S"
	end
	return "O"
end

function M.run(names: { string }): string
	local Y = workspace.Yangon
	local tp = RaycastParams.new()
	tp.FilterType = Enum.RaycastFilterType.Include
	tp.FilterDescendantsInstances = { workspace.Terrain }
	tp.IgnoreWater = true
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local inc = {}
	for _, n in { "Roads", "Decks", "Sites", "CarCare", "Barriers" } do
		local f = Y:FindFirstChild(n)
		if f then
			table.insert(inc, f)
		end
	end
	rp.FilterDescendantsInstances = inc
	local YD = SS.YangonData
	local out = YD:FindFirstChild("ProbeOut")
	if out then
		out:Destroy()
	end
	out = Instance.new("Folder")
	out.Name = "ProbeOut"
	out.Parent = YD
	local buf, size, page, count = {}, 0, 0, 0
	local function flush()
		page += 1
		local v = Instance.new("StringValue")
		v.Name = "Page_" .. page
		v.Value = table.concat(buf, "\n")
		v.Parent = out
		buf, size = {}, 0
	end
	local down = Vector3.new(0, -900, 0)
	for _, name in names do
		local data = require(SS.ClaudeTools[name]:Clone())
		for line in string.gmatch(data, "[^\n]+") do
			local x, z = string.match(line, "^(%S+)%s+(%S+)")
			x, z = tonumber(x), tonumber(z)
			if x and z then
				local o = Vector3.new(x, 600, z)
				local g = workspace:Raycast(o, down, tp)
				local h = workspace:Raycast(o, down, rp)
				local s = string.format("%s|%s|%s", g and string.format("%.1f", g.Position.Y) or "", h and string.format("%.2f", h.Position.Y) or "",
					h and kindOf(h.Instance) or "-")
				table.insert(buf, s)
				size += #s + 1
				count += 1
				if size > 94000 then
					flush()
				end
				if count % 4000 == 0 then
					task.wait()
				end
			end
		end
	end
	if #buf > 0 then
		flush()
	end
	return string.format("%d points, %d pages", count, page)
end

function M.spawn(names: { string })
	local YD = SS.YangonData
	YD:SetAttribute("Probe2Status", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(M.run, names)
		YD:SetAttribute("Probe2Status", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("Probe2Status"))
end

function M.page(i: number): string
	local v = SS.YangonData.ProbeOut:FindFirstChild("Page_" .. i)
	return v and v.Value or ""
end

return M
