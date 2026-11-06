-- RankPlate (Galaxy Incremental, 6 Nov; prompt "LUMI EXPRESSIONS + RANK TITLE ART", checklist #271 #290 #339 #396): the
-- RANK TITLE as a kit component: the rank's banner plate (ArtIds.plate) as the background, the rank emblem (ArtIds.rank) in
-- the plate's left slot, the title on top in Luckiest Guy, white with a dark outline. The plate is 9-SLICED (SliceCenter =
-- a plain strip of its bar): a long title widens the bar, the ends + the slot never stretch.
-- RankPlate.keyOf(text) -> the art key of a rank / title ("FLARE III · ✦12" -> "flare"; HYPERGIANT + QUASAR -> "supergiant",
--   the top art; NEW STAR / RISING STAR -> "new_star"; anything else, e.g. an Ignition or special title -> RankPlate.KEYS by tier)
-- RankPlate.build(parent, text, key, h) -> holder Frame (pixel sizes; h = the plate's height in px), holder.Size is its size;
--   holder:GetAttribute("W") = its width. Parts: holder.Plate, holder.Emblem, holder.Title
-- RankPlate.emblem(parent, key, size) -> an ImageLabel of the emblem (the leaderboard's, the far view)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Art = require(Galaxy:WaitForChild("ArtIds"))

local R = {}
R.FONT = Font.fromEnum(Enum.Font.LuckiestGuy)
R.INK = Color3.fromRGB(26, 14, 40)
-- each plate (1024 x 320): x0 / x1 = where the drawing starts / ends; slice = the plain strip that stretches; slot = the
-- left diamond's centre (the emblem's place); t0 / t1 = the bar's text room, right of the emblem (measured on the files, 6 Nov;
-- the slice strip sits inside the text room, so the room is what grows)
R.GEOM = {
	new_star = { x0 = 104, x1 = 924, slice = { 560, 600 }, slot = 242, t0 = 432, t1 = 850 },
	spark = { x0 = 143, x1 = 879, slice = { 520, 560 }, slot = 276, t0 = 466, t1 = 815 },
	flare = { x0 = 170, x1 = 851, slice = { 500, 530 }, slot = 290, t0 = 480, t1 = 790 },
	blaze = { x0 = 194, x1 = 833, slice = { 640, 680 }, slot = 296, t0 = 486, t1 = 775 },
	nova = { x0 = 208, x1 = 815, slice = { 640, 670 }, slot = 306, t0 = 496, t1 = 760 },
	supergiant = { x0 = 239, x1 = 781, slice = { 650, 680 }, slot = 320, t0 = 510, t1 = 730 },
}
-- the tiers, low to high (special titles pick by their tier: 1 = new_star .. 6 = supergiant)
R.KEYS = { "new_star", "spark", "flare", "blaze", "nova", "supergiant" }
local WORD = { SPARK = "spark", FLARE = "flare", BLAZE = "blaze", NOVA = "nova", SUPERGIANT = "supergiant", HYPERGIANT = "supergiant",
	QUASAR = "supergiant", NEW = "new_star", RISING = "new_star" }

function R.keyOf(text: string?): string
	local first = string.match(string.upper(text or ""), "^(%a+)")
	return WORD[first or ""] or "new_star"
end
-- the key of a tier number 1..6 (Ignition 1 = "spark" .. ; special titles)
function R.keyOfTier(t: number): string
	return R.KEYS[math.clamp(math.floor(t), 1, #R.KEYS)]
end

-- the title's width in px at text height `th` (GetTextSize: no yield, so two quick rebuilds can't both add a plate)
local function textW(text: string, th: number): number
	local ok, v = pcall(function() return TextService:GetTextSize(text, 100, Enum.Font.LuckiestGuy, Vector2.new(100000, 1000)) end)
	local w100 = if ok and v then v.X else #text * 62
	return w100 / 100 * th
end

function R.emblem(parent: Instance, key: string, size: number, small: boolean?): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = "Emblem"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Size = UDim2.fromOffset(size, size)
	img.Image = (if small then Art.rank128[key] else Art.rank[key]) or Art.rank.new_star
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	return img
end

-- the plate: `h` px high; the title fits (the bar widens through the slice; the text never shrinks under 46% of h)
function R.build(parent: Instance, text: string, key: string, h: number, z: number?)
	local g = R.GEOM[key] or R.GEOM.new_star
	local k = h / 320
	local th = h * 0.3 -- (the bar's inner height is ~38% of the plate)
	local room = (g.t1 - g.t0) * k
	local need = textW(text, th) * 1.15 + h * 0.2
	local extra = math.max(0, need - room) -- (px the bar grows by)
	local w = (g.x1 - g.x0) * k + extra
	local z0 = z or 1
	local holder = Instance.new("Frame")
	holder.Name = "RankPlate"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(w, h)
	holder:SetAttribute("W", w)
	holder.Parent = parent
	local plate = Instance.new("ImageLabel")
	plate.Name = "Plate"
	plate.BackgroundTransparency = 1
	plate.Image = Art.plate[key] or Art.plate.new_star
	plate.ScaleType = Enum.ScaleType.Slice
	plate.SliceCenter = Rect.new(g.slice[1], 100, g.slice[2], 220) -- (a full-height centre doesn't draw: the middle band only)
	plate.SliceScale = k
	plate.Position = UDim2.fromOffset(-g.x0 * k, 0)
	plate.Size = UDim2.fromOffset(1024 * k + extra, h)
	plate.ZIndex = z0
	plate.Parent = holder
	local em = R.emblem(holder, key, h * 1.1)
	em.Position = UDim2.fromOffset((g.slot - g.x0) * k, h * 0.5)
	em.ZIndex = z0 + 2
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset((g.t0 - g.x0) * k, h * 0.5 - th * 0.62)
	t.Size = UDim2.fromOffset(room + extra, th * 1.24)
	t.FontFace = R.FONT
	t.Text = text
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Center
	t.ZIndex = z0 + 1
	local st = Instance.new("UIStroke")
	st.Color = R.INK
	st.Thickness = math.max(1.5, h / 20)
	st.Parent = t
	t.Parent = holder
	holder:SetAttribute("Key", key)
	return holder
end

return R
