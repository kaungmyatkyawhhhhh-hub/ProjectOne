--[[
	Swatches.luau (Studio, Edit): colour test panels for checking how the map's light renders colours.
	M.build() makes workspace.ClaudeSwatches: two panels of 8 materials x 10 greys (20..245), one facing the
	horizontal direction H (the "sun" side, centre SUN_C) and one facing away (the "shade" side, 90 studs lower).
	M.views() returns, per side, the camera (52 studs out) and each swatch's viewport fraction, as text lines
	"side cam x y z look x y z" and "name fx fy;..." for tools/yangon/city/swatch_measure.py.
	M.clear() deletes them. Never leave them in the place.
]]
local M = {}
M.MATS = { "SmoothPlastic", "Metal", "Glass", "Sandstone", "Concrete", "Marble", "Plastic", "Slate" }
M.GREYS = { 20, 45, 70, 95, 120, 145, 170, 195, 220, 245 }
M.SUN_C = Vector3.new(32380, 160, -1600)
M.H = Vector3.new(-0.5, 0, 0.11).Unit

local function panel(f, side, centre, nrm)
	local right = Vector3.yAxis:Cross(nrm).Unit
	for mi, mat in M.MATS do
		for gi, g in M.GREYS do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Size = Vector3.new(5, 5, 0.6)
			p.Material = Enum.Material[mat]
			p.Color = Color3.fromRGB(g, g, g)
			p.Name = side .. "_" .. mat .. "_" .. g
			local pos = centre + right * ((gi - 5.5) * 6) + Vector3.yAxis * ((4.5 - mi) * 6)
			p.CFrame = CFrame.lookAt(pos, pos + nrm)
			p.Parent = f
		end
	end
end

function M.build()
	M.clear()
	local f = Instance.new("Model")
	f.Name = "ClaudeSwatches"
	f.Parent = workspace
	panel(f, "sun", M.SUN_C, M.H)
	panel(f, "shade", M.SUN_C - Vector3.new(0, 90, 0), -M.H)
	return "built"
end

function M.views()
	local cam = workspace.CurrentCamera
	local out = {}
	for _, side in { "sun", "shade" } do
		local c = if side == "sun" then M.SUN_C else M.SUN_C - Vector3.new(0, 90, 0)
		local nrm = if side == "sun" then M.H else -M.H
		local cp = c + nrm * 52
		cam.CFrame = CFrame.lookAt(cp, c)
		local vs = cam.ViewportSize
		local rows = {}
		for _, p in workspace.ClaudeSwatches:GetChildren() do
			if string.sub(p.Name, 1, #side + 1) == side .. "_" then
				local v = cam:WorldToViewportPoint(p.Position)
				table.insert(rows, string.format("%s %.4f %.4f", p.Name, v.X / vs.X, v.Y / vs.Y))
			end
		end
		table.insert(out, string.format("%s cam %.2f %.2f %.2f look %.2f %.2f %.2f", side, cp.X, cp.Y, cp.Z, c.X, c.Y, c.Z))
		table.insert(out, table.concat(rows, ";"))
	end
	return table.concat(out, "\n")
end

function M.clear()
	local s = workspace:FindFirstChild("ClaudeSwatches")
	if s then
		s:Destroy()
	end
end

return M
