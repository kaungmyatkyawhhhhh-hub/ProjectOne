--[[
	Sites (Studio, Edit mode): clears and levels the venue lots in Monaco (owner 2026-11-02: "Move the
	venues"). The venues themselves are built at start by their own scripts, at the frames
	WestLayout.rivieraSite gives (Config.RivieraVenues.Sites); this only gets the ground ready.

	For each site: the Riviera buildings, street furniture, trees and lamps standing in the lot go;
	the terrain is cut away above the lot's floor and filled up to it below; a flat pad (VenuePad, in
	Workspace.Riviera.Sites) is the floor, level with the pavement in front.

	Sites.prepare(riviera, config, names?) -> { [string]: number }
]]

local Sites = {}

local LOT = 216
local MARGIN = 8

-- front: how far past the lot's front edge (towards the road) also counts
local function inside(cf: CFrame, p: Vector3, grow: number, front: number?, lot: number?): boolean
	local l = cf:PointToObjectSpace(p)
	local L = lot or LOT
	return math.abs(l.X) < L / 2 + grow and l.Z > -L / 2 - (front or 2) and l.Z < L / 2 + grow
end

function Sites.prepare(riviera: Model, config, names: { string }?): { [string]: number }
	local n = { buildings = 0, furniture = 0, sites = 0 }
	local folder = riviera:FindFirstChild("Sites") or Instance.new("Folder")
	folder.Name = "Sites"
	folder.Parent = riviera
	local T = workspace.Terrain
	for name, s in config.Sites do
		if names and not table.find(names, name) then
			continue
		end
		local c = Vector3.new(s.x, s.y, s.z)
		-- (the frame's LookVector points out of the entrance; local -Z is the front)
		local cf = CFrame.lookAt(c, c + Vector3.new(s.fx, 0, s.fz).Unit)
		local lot = s.size or LOT
		-- buildings with any corner in the lot
		for _, m in riviera.Buildings:GetChildren() do
			local sh, sz = m:GetAttribute("Shell"), m:GetAttribute("ShellSize")
			if typeof(sh) == "CFrame" and typeof(sz) == "Vector3" then
				local hit = false
				for _, ox in { -0.5, 0, 0.5 } do
					for _, oz in { -0.5, 0, 0.5 } do
						if inside(cf, (sh * CFrame.new(sz.X * ox, 0, sz.Z * oz)).Position, MARGIN, nil, lot) then
							hit = true
						end
					end
				end
				if hit then
					m:Destroy()
					n.buildings += 1
				end
			end
		end
		-- street furniture, lamps, trees, walls (not the pavement in front: that is Roads)
		for _, g in riviera.Dressing:GetChildren() do
			-- (on the pavement in front too: the balustrade, bollards, lamps and trees across the way in)
			if g.Name == "StreetLamp" or g.Name == "Tree" then
				if inside(cf, g:GetPivot().Position, MARGIN, 12, lot) then
					g:Destroy()
					n.furniture += 1
				end
			elseif g:IsA("Model") or g:IsA("Folder") then
				-- (the balustrade and walls are runs of plain parts: each part on its own)
				for _, item in (if g.Name == "Balustrade" or g.Name == "Walls" then g:GetDescendants() else g:GetChildren()) do
					local ok, p = pcall(function()
						return if item:IsA("BasePart") then item.Position else (item :: any):GetPivot().Position
					end)
					if ok and inside(cf, p, MARGIN, 12, lot) then
						item:Destroy()
						n.furniture += 1
					end
				end
			end
		end
		-- terrain: air above the floor, ground below it
		local span = Vector3.new(lot + MARGIN * 2, 0, lot + MARGIN + 2)
		local mid = cf * CFrame.new(0, 0, (MARGIN - 2) / 2)
		T:FillBlock(mid * CFrame.new(0, 80, 0), Vector3.new(span.X, 160, span.Z), Enum.Material.Air)
		T:FillBlock(mid * CFrame.new(0, -26, 0), Vector3.new(span.X, 40, span.Z), Enum.Material.Rock)
		-- (terrain keeps a full 4-stud cell under the floor: its cells would show through the paving)
		T:FillBlock(mid * CFrame.new(0, -1, 0), Vector3.new(span.X + 2, 9, span.Z + 2), Enum.Material.Air)
		-- the pad
		local old = folder:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local pad = Instance.new("Part")
		pad.Name = name
		pad.Anchored = true
		pad.Size = Vector3.new(span.X, 4, span.Z)
		pad.CFrame = mid * CFrame.new(0, -2, 0)
		pad.Material = Enum.Material.Pavement
		pad.Color = Color3.fromRGB(168, 160, 150)
		pad.TopSurface = Enum.SurfaceType.Smooth
		pad.BottomSurface = Enum.SurfaceType.Smooth
		pad.CastShadow = false
		pad:SetAttribute("Venue", name)
		pad.Parent = folder
		n.sites += 1
		task.wait()
	end
	return n
end

return Sites
