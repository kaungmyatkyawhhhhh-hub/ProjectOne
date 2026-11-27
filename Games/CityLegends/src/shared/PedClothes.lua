-- PedClothes (2026-11-27): the street people's clothes (YangonStreetLife). Owner, 27 Nov: Roblox characters, never
-- realistic people; Yangon shows only in the clothes. tools/people/roblox_clothes.py draws Roblox Shirt / Pants
-- templates (imports/people/clothes) and packs their faces at half size into two 1024 atlases (imports/people/
-- atlas_shirts.png, atlas_pants.png; Decals 108837918839483 / 127064658584205 in group 33151111). Each body face
-- wears a Texture cropped to its slot (no Humanoid: its clothing composite cost ~1.4 MB a person).
return {
	atlas = { shirt = 95156362837878, pants = 83307406615981 },
	size = 1024, cellW = 341, cellH = 256, cols = 3, gutter = 4,
	-- garment -> cell number (0-based, 3 a row), as SHIRTS / PANTS in roblox_clothes.py
	shirt = {
		shirt_white = 0, shirt_blue = 1, shirt_cream = 2, shirt_navy = 3, tee_red = 4, tee_black = 5,
		blouse_white = 6, blouse_pink = 7, blouse_yellow = 8, blouse_lilac = 9, uniform_shirt = 10, robe_shirt = 11,
	},
	pants = {
		longyi_green = 0, longyi_blue = 1, longyi_brown = 2, longyi_grey = 3, longyi_maroon = 4, htamein_pink = 5,
		htamein_teal = 6, htamein_purple = 7, htamein_gold = 8, uniform_longyi = 9, robe_pants = 10, jeans_blue = 11,
	},
	-- face slots in a cell: { x, y, w, h } of the face itself (the gutter is round it); T torso, R / L right / left limb
	slots = {
		T = { F = { 4, 4, 64, 64 }, B = { 76, 4, 64, 64 }, L = { 148, 4, 32, 64 }, R = { 188, 4, 32, 64 }, U = { 228, 4, 64, 32 } },
		R = { F = { 4, 76, 32, 64 }, B = { 44, 76, 32, 64 }, L = { 84, 76, 32, 64 }, R = { 124, 76, 32, 64 }, U = { 4, 148, 32, 32 } },
		L = { F = { 164, 76, 32, 64 }, B = { 204, 76, 32, 64 }, L = { 244, 76, 32, 64 }, R = { 284, 76, 32, 64 }, U = { 44, 148, 32, 32 } },
	},
}
