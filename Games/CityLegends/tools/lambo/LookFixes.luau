--[[
	The last look pass on the new imports, after seeing them in Play (owner, 2026-11-04: "fix lp700 interior
	and headlight color, its gray also fix it all check for all cars"). Run once on the edit side, after
	PbrApply; everything lands in ReplicatedStorage.CarModels. Why each line:
	  * paint: a plain part colour (a TextureID hides the gloss), a shade under clipping;
	  * carbon and dark trim: rougher, or they mirror the blue sky under the roof;
	  * screens and lamps: a low glow (white Gallardo dials burn out and hide their needles at 0.7);
	  * grilles: their mesh pictures lost their cut-outs, so they read as pale floor mats;
	  * palettes: the mirror glass cell made dark; the LP560's cabin lives on its palette, so it goes dark;
	  * a tiny brake picture that won't load for the LP700 is swapped for a plain colour.
]]

local folder = game.ReplicatedStorage.CarModels
local WHITE = "rbxassetid://99576478960484"
local R80 = "rbxassetid://78236993981028"
local out = {}

local COL = {
	lambrini_lp700 = { 240, 82, 0 },
	lambrini_lp750 = { 222, 180, 0 },
	lambrini_revuelto = { 212, 214, 218 },
	lambrini_lp570 = { 150, 205, 42 },
	lambrini_lp560 = { 214, 190, 0 },
	lambrini_huracan = { 236, 64, 0 },
	lambrini_performante = { 186, 4, 34 },
	lambrini_sto = { 166, 8, 6 },
	lambrini_sterrato = { 78, 112, 60 },
}
local SCREEN = { lambrini_lp570 = 0.14, lambrini_lp560 = 0.14 }
local PALETTE = {
	lambrini_lp700 = "rbxassetid://122049309507945",
	lambrini_huracan = "rbxassetid://108458258933275",
	lambrini_lp560 = "rbxassetid://83559700463014",
}

for id, c in COL do
	local car = folder[id]
	local list = {}
	for _, d in car:GetDescendants() do
		if d:IsA("MeshPart") then
			table.insert(list, d)
		end
	end
	local oldPalette
	for _, d in list do
		local s = d:FindFirstChildOfClass("SurfaceAppearance")
		local n = d.Name
		if n:sub(1, 10) == "Body_Paint" and n:sub(1, 11) ~= "Body_Paint2" then
			d.Color = Color3.fromRGB(c[1], c[2], c[3])
		end
		if s then
			if n:sub(1, 9) == "Body_Lamp" then
				s.EmissiveStrength = if n:find("Glow") then 0.8 else 0.35
			elseif n:sub(1, 11) == "Body_Screen" then
				s.EmissiveStrength = SCREEN[id] or 0.7
			elseif n:sub(1, 11) == "Body_Carbon" or n:sub(1, 11) == "Body_Forged" then
				s.RoughnessMap = R80
			elseif n:sub(1, 9) == "Body_Trim" then
				s.RoughnessMap = R80
				if PALETTE[id] and n:find("^Body_Trim") and not oldPalette then
					oldPalette = s.ColorMap
				end
			elseif n:sub(1, 11) == "Body_Grille" then
				local t = s.Color
				s.Color = Color3.new(t.R * 0.45, t.G * 0.45, t.B * 0.47)
			end
		end
	end
	if PALETTE[id] and oldPalette then
		local swaps = 0
		for _, d in list do
			local s = d:FindFirstChildOfClass("SurfaceAppearance")
			if s and s.ColorMap == oldPalette then
				s.ColorMap = PALETTE[id]
				swaps += 1
				if id == "lambrini_lp560" then
					s.RoughnessMap = WHITE
				end
			end
		end
		table.insert(out, id .. " palette swaps " .. swaps)
	end
end

-- (a plain colour for the LP700's brake bits)
for _, d in folder.lambrini_lp700:GetDescendants() do
	if d:IsA("MeshPart") and d.Name:find("static_Trim") then
		local s = d:FindFirstChildOfClass("SurfaceAppearance")
		if s then
			s.ColorMap = WHITE
			s.Color = Color3.fromRGB(14, 14, 16)
		end
		d.TextureID = ""
	end
end

return table.concat(out, "\n")
