--[[
	YccInterior21Nov.luau (Studio, Edit; owner 21 Nov: "do these: ... the YCC interior"; references fix 13).
	Real interior photo: the owner's own City Legends/refs_21nov/0793_photo.jpg (inside the GG Gaming Fest hall, 21 Nov):
	dark grey steel roof structure and deck, bare grey concrete floor, black banner walls with a yellow / black hazard
	stripe on top. The built hall (tools/yangon/landmarks3d/ycc_ggfest.py) had a pale metal deck, light steel, white-grey
	inner walls, a polished floor and red carpet aisles. This re-colours only the interior groups of
	Landmarks.YangonConventionCentre.Visual (no geometry, no new parts; the white vault roof outside RFW stays white).
	Each part keeps its old colour / reflectance as attributes Color_before_21Nov / Refl_before_21Nov; M.undo() restores.
	Not done: the yellow / black hazard stripe on top of the banner walls (the GG banners themselves are in .Signs).
]]
local M = {}
M.LOOK = {
	DCK = { Color3.fromRGB(78, 86, 92), 0 }, -- metal deck ceiling: dark grey-blue as in the photo
	STL = { Color3.fromRGB(54, 60, 68), 0 }, -- arch trusses, columns: dark steel
	INW = { Color3.fromRGB(34, 35, 40), 0 }, -- inside wall lining: the black banner walls
	FLR = { Color3.fromRGB(128, 126, 120), 0 }, -- bare concrete floor (matte)
	RCP = { Color3.fromRGB(116, 114, 108), 0 }, -- the red carpet aisles become worn concrete, a shade darker
}

local function visual()
	return workspace.Yangon1to1.Landmarks.YangonConventionCentre.Visual
end

function M.apply()
	local n = 0
	for _, p in visual():GetDescendants() do
		local l = p:IsA("BasePart") and M.LOOK[p.Name]
		if l then
			if p:GetAttribute("Color_before_21Nov") == nil then
				p:SetAttribute("Color_before_21Nov", p.Color)
				p:SetAttribute("Refl_before_21Nov", p.Reflectance)
			end
			p.Color = l[1]
			p.Reflectance = l[2]
			n += 1
		end
	end
	return n
end

function M.undo()
	for _, p in visual():GetDescendants() do
		local c = p:IsA("BasePart") and p:GetAttribute("Color_before_21Nov")
		if c then
			p.Color = c
			p.Reflectance = p:GetAttribute("Refl_before_21Nov") or 0
			p:SetAttribute("Color_before_21Nov", nil)
			p:SetAttribute("Refl_before_21Nov", nil)
		end
	end
end

return M
