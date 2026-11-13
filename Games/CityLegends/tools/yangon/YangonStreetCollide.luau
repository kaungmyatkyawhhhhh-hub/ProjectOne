--[[
	YangonStreetCollide (Studio, Edit mode; whole-Yangon city generator, 14 Nov 2026).

	The new mesh streets (tools/yangon/city/streets.py) are drawn by MeshParts with no collision; this lays their invisible
	collision boxes and beds them into the terrain. Data: ServerStorage.ClaudeTools.StreetCollide_<tag>_<n> (one string, lines
	"cx cy cz dx dy dz width walk": a street piece's middle at road level, its direction and length (dx, dy, dz), the
	carriageway width and the pavement width each side).
	  * a carriageway box (width x 2 x length + 1), its top at road level, tilted with the street;
	  * a box under each pavement, 0.5 higher (the kerb);
	  * the terrain: air from 0.3 under the road up 14 studs over the whole width (no grass through the street).
	Boxes: Transparency 1, CanCollide / CanQuery true, CanTouch false, CastShadow false, into Workspace.Yangon.StreetCollide.

	local C = require(game.ServerStorage.ClaudeTools.YangonStreetCollide:Clone())
	C.spawn({ "StreetCollide_05_1", "StreetCollide_05_2" })   then C.status()       C.undo()
]]

local SS = game:GetService("ServerStorage")

local M = {}

local function box(name: string, size: Vector3, cf: CFrame, parent: Instance)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Transparency = 1
	p.CanCollide = true
	p.CanQuery = true
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
end

function M.build(names: { string }, noTerrain: boolean?): string
	local Y = workspace.Yangon
	local folder = Y:FindFirstChild("StreetCollide")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "StreetCollide"
		folder.Parent = Y
	end
	local n, i = 0, 0
	for _, name in names do
		local data = require(SS.ClaudeTools[name]:Clone())
		for line in string.gmatch(data, "[^\n]+") do
			local v = {}
			for w in string.gmatch(line, "%S+") do
				table.insert(v, tonumber(w))
			end
			if #v >= 8 then
				local c = Vector3.new(v[1], v[2], v[3])
				local d = Vector3.new(v[4], v[5], v[6])
				local len = d.Magnitude
				if len > 0.3 then
					local width, walk = v[7], v[8]
					local cf = CFrame.lookAt(c, c + d)
					local L = len + 1.5
					box("Street", Vector3.new(width, 2, L), cf * CFrame.new(0, -1, 0), folder)
					box("Walk", Vector3.new(walk, 2, L), cf * CFrame.new(width / 2 + walk / 2, -0.5, 0), folder)
					box("Walk", Vector3.new(walk, 2, L), cf * CFrame.new(-(width / 2 + walk / 2), -0.5, 0), folder)
					if not noTerrain then
						workspace.Terrain:FillBlock(cf * CFrame.new(0, 6.7, 0), Vector3.new(width + 2 * walk, 14, L), Enum.Material.Air)
					end
					n += 3
				end
			end
			i += 1
			if i % 300 == 0 then
				task.wait()
			end
		end
	end
	return string.format("%d boxes from %d pieces", n, i)
end

function M.spawn(names: { string }, noTerrain: boolean?)
	local YD = SS.YangonData
	YD:SetAttribute("StreetCollideStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(M.build, names, noTerrain)
		YD:SetAttribute("StreetCollideStatus", string.format("%s after %.0f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("StreetCollideStatus"))
end

function M.undo(): number
	local f = workspace.Yangon:FindFirstChild("StreetCollide")
	local n = f and #f:GetChildren() or 0
	if f then
		f:Destroy()
	end
	return n
end

return M
