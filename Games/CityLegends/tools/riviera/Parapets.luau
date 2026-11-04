--[[
	Parapets (Studio, Edit mode; 2026-11-04, the Summit Pass): low cream stone walls along both edges of
	a narrow mountain road, like the Stelvio's. Each piece runs from one sample's edge point to the next
	and leans with the road (its top stays 2.4 over the road edge: no stair steps where the road
	climbs). Neighbouring pieces overlap a little at the joints and differ by a hair in width and
	height, so no two faces lie in one plane (owner, 2026-11-04: "the side is glitching out a
	little": the old wall pieces' tops met in one plane and flickered). Left out within reach of the
	other roads (the junction mouths).

	Parapets.build(data, name, opts?) -> parts made   (opts.skip = { Vector3 } mouth points, opts.clear radius)
]]

local Parapets = {}

local COLOR = Color3.fromRGB(222, 214, 196)
local TOP = 2.4 -- over the road edge
local DEPTH = 3.4 -- under it (into the bank)

function Parapets.build(data, name: string, opts): number
	opts = opts or {}
	local road
	for _, r in data.roads do
		if r.name == name then
			road = r
		end
	end
	assert(road, "no road " .. name)
	local folder = workspace.Riviera.Roads:FindFirstChild(name)
	local old = folder:FindFirstChild("Parapets")
	if old then
		old:Destroy()
	end
	local out = Instance.new("Folder")
	out.Name = "Parapets"
	local skip = opts.skip or {}
	local clear = opts.clear or 46
	local function nearMouth(p: Vector3): boolean
		for _, q in skip do
			if Vector2.new(p.X - q.X, p.Z - q.Z).Magnitude < clear then
				return true
			end
		end
		return false
	end
	local s = road.s
	local count = 0
	for _, side in { -1, 1 } do
		local prev: Vector3? = nil
		local k = 0
		for i = 1, #s do
			local q = s[i]
			local dir = Vector3.new(q[4], 0, q[5]).Unit
			local right = Vector3.new(-dir.Z, 0, dir.X)
			local half = if side < 0 then q[7] else q[8]
			local edge = Vector3.new(q[1], q[2], q[3]) + right * side * (half + 0.75)
			if nearMouth(edge) then
				prev = nil
				continue
			end
			if prev then
				local a, b = prev, edge
				local len = (b - a).Magnitude
				if len > 0.2 and len < 12 then
					k += 1
					local alt = k % 2
					local w = 1.4 + alt * 0.06
					local h = TOP + DEPTH + alt * 0.04
					local mid = (a + b) / 2
					local cf = CFrame.lookAt(mid, b) * CFrame.new(0, TOP + alt * 0.04 - h / 2, 0)
					local p = Instance.new("Part")
					p.Name = "Parapet"
					p.Anchored = true
					p.Size = Vector3.new(w, h, len + 0.25)
					p.CFrame = cf
					p.Material = Enum.Material.Limestone
					p.Color = COLOR
					p.TopSurface = Enum.SurfaceType.Smooth
					p.BottomSurface = Enum.SurfaceType.Smooth
					p.CastShadow = false
					p.Parent = out
					count += 1
				end
			end
			prev = edge
			if i % 300 == 0 then
				task.wait()
			end
		end
	end
	out.Parent = folder
	return count
end

return Parapets
