-- PlazaBoardsUI (Galaxy Incremental): how the plaza's boards LOOK, in one place (7 Nov): FREE REWARDS and the leaderboard
-- plaques (TOP SUPERNOVAS, PLAYERS NEAR YOU). The game draws them on each player's screen (GalaxyDaily, GalaxyMapClient);
-- Tools/BoardPreview draws the very same thing in Edit mode, so the owner sees the boards' design without pressing Play.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local RankPlate = require(Galaxy:WaitForChild("RankPlate"))
local Art = require(Galaxy:WaitForChild("ArtIds"))
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local FONT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local P = {}

-- FREE REWARDS (Workspace.Galaxy.Centre.FreeBoard's Screen): the board's look (6 Nov / Phase 2.4); returns the SurfaceGui + its
-- rows { [id] = { button, label, panel } } (GalaxyDaily wires the CLAIM buttons + the GOT state)
function P.freeBoard(screen: BasePart, parent: Instance)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "FreeRewardsBoard"
	sg.Adornee = screen
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(440, 300)
	sg.LightInfluence = 0
	sg.Brightness = 1.8
	sg.MaxDistance = 140
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = parent
	local bg = Kit.box(sg, 0, 0, 440, 300, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1 })
	Kit.grad(bg, hex("#1d1a2a"), hex("#0e0c14"), 90)
	Kit.text(sg, 0, 14, 440, 40, "FREE REWARDS", 34, { ZIndex = 5, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2.4,
		gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	-- (6 Nov: the board's own icon either side of the title)
	Kit.icon(sg, "freeRewards", 34, 6, 54, nil, { ZIndex = 5 })
	Kit.icon(sg, "freeRewards", 440 - 34 - 54, 6, 54, nil, { ZIndex = 5 })
	local rows = {}
	for i, f in ipairs(Econ.FreeRewards) do
		local y = 70 + (i - 1) * 92
		local p = Kit.panel(sg, 20, y, 400, 80, 2)
		Kit.text(sg, 34, y + 10, 230, 30, f.text, 24, { ZIndex = 5, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
		Kit.icon(sg, "essence", 30, y + 40, 34, nil, { ZIndex = 5 })
		Kit.text(sg, 66, y + 46, 200, 26, "+" .. f.essence .. " ESSENCE", 20, { ZIndex = 5, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#7dffe9") })
		local b, inner = Kit.button(sg, 280, y + 16, 128, 48, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 4 })
		local bt = Kit.text(inner, 0, 11, 128, 26, "CLAIM", 22, { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
		rows[f.id] = { button = b, label = bt, panel = p }
	end
	Kit.text(sg, 20, 258, 400, 30, "Likes can't be checked by a game: we trust you!", 15, { ZIndex = 5, TextXAlignment = CENTRE, TextColor3 = hex("#a99fb8"), stroke = 1.1 })
	return sg, rows
end

local LB_FONT = Font.fromEnum(Enum.Font.LuckiestGuy)
local ROW_SLICE = Rect.new(140, 30, 970, 62)
local RANK_ART = { "gold", "silver", "bronze" }
local function lbText(parent: Instance, text: string, x: number, y: number, w: number, h: number, colour: Color3, align: Enum.TextXAlignment, z: number, font: Font?)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(x, y)
	t.Size = UDim2.fromOffset(w, h)
	t.FontFace = font or FONT
	t.Text = text
	t.TextScaled = true
	t.TextColor3 = colour
	t.TextXAlignment = align
	t.ZIndex = z
	local st = Instance.new("UIStroke")
	st.Color, st.Thickness = Color3.fromRGB(20, 10, 34), math.max(1.5, h / 14)
	st.Parent = t
	t.Parent = parent
	return t
end
-- one row: rank r (1..), entry { u, name, value, you }; x, y, w, h in the canvas' pixels
local function lbRow(parent: Instance, r: number, e, x: number, y: number, w: number, h: number)
	local row = Instance.new("Frame")
	row.Name = "Row" .. r
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(x, y)
	row.Size = UDim2.fromOffset(w, h)
	row.ZIndex = 52
	row.Parent = parent
	local k = h / 95
	if e.empty then
		-- (an empty board: one plain row, "Be the first!" in the middle)
		local plain = Instance.new("Frame")
		plain.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
		plain.BackgroundTransparency = 0.15
		plain.Size = UDim2.fromScale(1, 1)
		plain.ZIndex = 52
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = plain
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness = Color3.fromRGB(255, 200, 70), 3
		st.Parent = plain
		plain.Parent = row
		lbText(row, "Be the first!", 0, h * 0.2, w, h * 0.6, Color3.fromRGB(255, 220, 120), Enum.TextXAlignment.Center, 54, LB_FONT)
		return row
	end -- (the row art is 95 px high: its round slot's middle is at x 92, ~72 across)
	if r <= 3 then
		local art = Instance.new("ImageLabel")
		art.BackgroundTransparency = 1
		art.Image = Art.ui.row[RANK_ART[r]]
		art.ScaleType = Enum.ScaleType.Slice
		art.SliceCenter = ROW_SLICE
		art.SliceScale = 1 -- (tested 7 Nov: at the row's own scale (~0.46) the bar didn't draw at all; at 1 it draws, Roblox fits the ends)
		art.Size = UDim2.fromScale(1, 1)
		art.ZIndex = 52
		art.Parent = row
	else
		local plain = Instance.new("Frame")
		plain.BackgroundColor3 = Color3.fromRGB(26, 18, 40)
		plain.BackgroundTransparency = 0.15
		plain.Size = UDim2.new(1, -h * 0.4, 0.8, 0)
		plain.Position = UDim2.new(0, h * 0.2, 0.1, 0)
		plain.ZIndex = 52
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = plain
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness, st.Transparency = if e.you then Color3.fromRGB(255, 200, 70) else Color3.fromRGB(90, 70, 130), 2, 0.2
		st.Parent = plain
		plain.Parent = row
		if not e.noNum then lbText(row, tostring(r), h * 0.3, h * 0.25, h * 0.7, h * 0.5, Color3.fromRGB(200, 190, 220), Enum.TextXAlignment.Center, 54, LB_FONT) end
	end
	-- the headshot in the round slot (rows 1-3: the art's slot; 4+: the same place)
	local slotX = if r <= 3 then 92 * k elseif e.noNum then h * 0.8 else h * 1.45
	local d = (if r <= 3 then 70 else 60) * k
	local head = Instance.new("ImageLabel")
	head.BackgroundColor3 = Color3.fromRGB(30, 22, 44)
	head.AnchorPoint = Vector2.new(0.5, 0.5)
	head.Position = UDim2.fromOffset(slotX, h / 2)
	head.Size = UDim2.fromOffset(d, d)
	head.Image = if (tonumber(e.u) or 0) > 0 then "rbxthumb://type=AvatarHeadShot&id=" .. tostring(e.u) .. "&w=150&h=150" else ""
	head.ZIndex = 53
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(0.5, 0)
	hc.Parent = head
	head.Parent = row
	-- the rank emblem by Supernovas (#396), the name, the Supernovas
	local def = MapConfig.RankDef(tonumber(e.value) or 0)
	local em = RankPlate.emblem(row, if def then RankPlate.keyOf(def.name) else "new_star", h * 0.62, true)
	em.Position = UDim2.fromOffset(slotX + d / 2 + h * 0.42, h / 2)
	em.ZIndex = 54
	local nameX = slotX + d / 2 + h * 0.8
	local valueW = h * 1.6
	local medalW = if r <= 3 then h * 1.15 else 0
	local textH = h * 0.5
	lbText(row, tostring(e.name), nameX, (h - textH) / 2, w - nameX - valueW - medalW - h * 0.4, textH,
		if e.you then Color3.fromRGB(255, 220, 120) else Color3.new(1, 1, 1), Enum.TextXAlignment.Left, 54, LB_FONT)
	lbText(row, tostring(tonumber(e.value) or 0), w - valueW - medalW - h * 0.35, (h - textH) / 2, valueW, textH,
		Color3.fromRGB(255, 230, 150), Enum.TextXAlignment.Right, 54, LB_FONT)
	if r <= 3 then
		local medal = Instance.new("ImageLabel")
		medal.BackgroundTransparency = 1
		medal.Image = Art.ui.medal[r]
		medal.ScaleType = Enum.ScaleType.Fit
		medal.AnchorPoint = Vector2.new(0.5, 0.5)
		medal.Position = UDim2.fromOffset(w - medalW * 0.5 - h * 0.25, h / 2)
		medal.Size = UDim2.fromOffset(h * 1.25, h * 1.25)
		medal.ZIndex = 55
		medal.Parent = row
	end
	return row
end
-- the plaque on one SurfaceGui (its old text hidden); returns the list frame (the dark screen) + its size
local function lbPlaque(gui: SurfaceGui, title: string, tall: boolean)
	gui.Enabled = true -- (Tools/BoardPreview switches the plain Edit board off while it's on: a save then can't hide it)
	local old = gui:FindFirstChild("Plaque")
	if old then return old:FindFirstChild("List") end
	for _, c in ipairs(gui:GetChildren()) do if c:IsA("GuiObject") then c.Visible = false end end
	local cw, ch = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
	-- (everything is laid out in the ART's pixels (the plaque is 920 x 436) inside a frame shrunk with a UIScale: Roblox
	-- skipped / repeated 9-slices drawn at a small SliceScale (tested 7 Nov), at scale 1 they draw right)
	local k = (if tall then cw / 920 else math.min(cw / 920, ch / 436)) * 0.95 -- (a small margin: the banner's star kept touching the edge)
	local ah = if tall then ch * 0.95 / k else 436
	local pl = Instance.new("Frame")
	pl.Name = "Plaque"
	pl.BackgroundTransparency = 1
	pl.AnchorPoint = Vector2.new(0.5, 0.5)
	pl.Position = UDim2.fromScale(0.5, 0.5)
	pl.Size = UDim2.fromOffset(920, ah)
	pl.ZIndex = 50
	local sc = Instance.new("UIScale")
	sc.Scale = k
	sc.Parent = pl
	pl.Parent = gui
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Image = Art.ui.plaque
	img:SetAttribute("HasOwnFrame", true) -- (rule 8: this art is the board's only frame)
	img.ZIndex = 50
	img.Size = UDim2.fromScale(1, 1)
	-- (PLAYERS NEAR YOU is tall: the plaque is 9-sliced through a strip of its dark screen, so the frame keeps its look)
	img.ScaleType = Enum.ScaleType.Slice
	img.SliceCenter = Rect.new(150, 156, 770, 184) -- (y 144-190: the sides are plain frame there; the wings start at ~192)
	img.Parent = pl
	-- the title on the top banner (x 215-705, y 92-152 of the art)
	lbText(pl, title, 230, 96, 460, 52, Color3.new(1, 1, 1), Enum.TextXAlignment.Center, 51, LB_FONT)
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(100, 172)
	list.Size = UDim2.fromOffset(720, ah - 172 - (if tall then 70 else 56))
	list.ZIndex = 51
	list.Parent = pl
	return list
end
local function lbFill(list: Frame, entries, columns: number, rows: number)
	for _, c in ipairs(list:GetChildren()) do c:Destroy() end
	local w, h = list.Size.X.Offset, list.Size.Y.Offset
	local gap = 8
	local cw = (w - gap * (columns - 1)) / columns
	local rh = math.min(h / rows, cw * 0.13)
	if #entries == 0 then
		lbRow(list, 1, { empty = true }, 0, (h / rows - rh) / 2, cw, rh)
		return
	end
	for i, e in ipairs(entries) do
		if i > columns * rows then break end
		local col, r = (i - 1) // rows, (i - 1) % rows
		lbRow(list, e.rank or i, e, col * (cw + gap), r * (h / rows) + (h / rows - rh) / 2, cw, rh)
	end
end
P.plaque = lbPlaque
P.fill = lbFill

return P
