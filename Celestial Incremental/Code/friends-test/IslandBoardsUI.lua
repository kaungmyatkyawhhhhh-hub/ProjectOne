-- IslandBoardsUI (Galaxy Incremental): the screens of the four LIVE island boards, a 1:1 copy of Regrowth's boards in form,
-- layout and behaviour (owner, 2 Nov: "1:1 direct copy boards from regrowth"; vault "Island boards like Regrowth 1to1" = the
-- law; references Map\screens\regrowth_boards). Our own art: v12 kit pieces (UIKit), our icons, our words, galaxy colours.
-- One source of truth: EconConfig + the island OWNER's attributes; buys go through ctx.buy (EconRequest + the island slot:
-- the server checks the owner and the distance). Visitors see the owner's numbers; their buttons are grey "VISIT".
-- ONE JOB EACH (5 Nov, vault "Prompt - Boards one job each", checklist #219-#221):
--  * Tree   the SHARD TREE (ring 2 only) as a node graph: your star (the hub) -> the ring-2 nodes, a line per link (bright
--           once bought); the branches not in the game yet are "?" with what opens them. A tap SELECTS a node (no buy)
--  * Info   the Tree's partner only: the node selected on the TREE (icon, name, LEVEL, value + green step, what it does,
--           progress, BUY with its shard cost under it); nothing selected: "Tap a node on the TREE"
--  * Bodies buying bodies only (Regrowth's MACHINES): rows: name, LEVEL, TIER, +x/s, UPGRADE (cost above it), M (max), the
--           boost ("x4"); a tier you haven't opened is "???" (a silhouette) with its UNLOCK price
--  * Stars  ring 1 only, all 7 nodes (Regrowth's FACTORY UPGRADES): cards: name, short text, icon, value + step, star level
--           badge, UPGRADE + price
-- Every screen: rounded corners in its frame's colour, a dark screen, an animated neon edge in the board's colour; the stand
-- boards have their title inside (centred, a rule under it); the pair's huge titles sit over the frame (GalaxyBoards).
-- Lists scroll (Kit.scroller); a refresh (4x a second) only changes words and colours, never rebuilds, so what you
-- scrolled to stays put. Pass 2 (owner): the pair's screens are 11 x 13 studs (550 x 650), the tree tiles 3 a row.
-- Alpha part 1 (3 Nov): the tree's RING 2 (shards: Starfire, Star, Heavy Elements, Binary Star; the other branches "?" with
-- what opens them), INFO pages for a ring-2 node and for the SUPERNOVA when it's ready, the Star / Binary Star rows opened
-- by ring 2. The 2D Tree window (hotbar T) builds the same Tree + Info screens (GalaxyHUD).
-- IslandBoardsUI.new(id, gui, spec, ctx) -> board: :refresh(), :step(dt), .targets[key] (tutorial "Body0", "R2_Starfire"),
--   :reveal(button)
--   ctx.subject, ctx.canAct(), ctx.buy(kind, arg) -> ok, ctx.sound(name), ctx.pointer(screenPos), ctx.size (canvas),
--   ctx.sel = the TREE's selection { kind = "node2", key = id } or { kind = "none" }, ctx.select(kind, key),
--   ctx.bought(kind, arg)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local A = Kit.A
local hex = Kit.hex
local fmt = Econ.Format

local UI = {}
UI.__index = UI

local WHITE = Color3.new(1, 1, 1)
local GREY_TEXT, GREEN_TEXT, RED_TEXT, GOLD_TEXT = hex("#a99fb8"), hex("#7dff6b"), hex("#ff6b6b"), hex("#ffd84a")
local LOOK = { -- the v12 kit's button colours
	buy = { hex("#7dff7a"), hex("#1fa83a") }, no = { hex("#6a6474"), hex("#3f3a48") }, owned = { hex("#b49bff"), hex("#5a3ad8") },
	blue = { hex("#5ad1ff"), hex("#1f6fd1") },
}
local TIER_TITLE = { { "#f3eaff", "#b9a8cc" }, { "#ffffff", "#bfe9ff" }, { "#efe8ff", "#b49bff" }, { "#fff1c0", "#ffb02a" }, { "#fff1c0", "#ffc83a" },
	{ "#ffe8d8", "#ff8a6a" } }
local SHARD_GLOW = Color3.fromRGB(170, 110, 255)
local NODE_GLOW = { STARDUST = Color3.fromRGB(255, 170, 60), COMETS = Color3.fromRGB(90, 200, 255), PLANETS = Color3.fromRGB(170, 130, 255) }
local LEFT, RIGHT, CENTRE = Enum.TextXAlignment.Left, Enum.TextXAlignment.Right, Enum.TextXAlignment.Center

-- the SHARD TREE's graph (5 Nov, #220): 3 rows x 3 columns on the 550 x 650 screen, under the heading; the hub (your star)
-- bottom centre; each node links to `from`. (A ring-2 node not listed here isn't drawn: add it to GRAPH.)
local TILE_W, TILE_H = 120, 112
local COL_X = { 110, 275, 440 } -- (tile centres)
local ROW_Y = { 150, 308, 466 } -- (tile tops)
local GRAPH = {
	{ id = "Starfire", col = 1, row = 2, from = "hub" },
	{ id = "StarTier", col = 2, row = 2, from = "hub" },
	{ id = "HeavyElements", col = 1, row = 1, from = "StarTier" },
	{ id = "BinaryStar", col = 3, row = 1, from = "StarTier" },
	{ later = 3, col = 3, row = 2, from = "hub" }, -- (Econ.Ring2Later: AUTOMATION)
	{ later = 1, col = 1, row = 3, from = "hub" }, -- (COMETS)
	{ later = 2, col = 3, row = 3, from = "hub" }, -- (FORGE)
}
local HUB = { col = 2, row = 3 }
local function cellCentre(col: number, row: number): Vector2
	return Vector2.new(COL_X[col], ROW_Y[row] + TILE_H / 2)
end

------------------------------------------------------------------------ what a node / body shows
local function unlockNode(k: number)
	local id = Econ.Tiers[k + 1].unlock
	return id and Econ.Ring1ById[id]
end
-- the value now (bought or not) and the green step it adds
local function nodeValue(node, bought: boolean): (string, string)
	local e = node.effect
	if e.kind == "tierMult" or e.kind == "allMult" then
		return if bought then "x" .. e.mult else "x1", if bought then "MAX" else "+x" .. (e.mult - 1)
	elseif e.kind == "cometEvery" then
		return (if bought then e.seconds else Econ.Comet.Every) .. "s", if bought then "MAX" else "-" .. (Econ.Comet.Every - e.seconds) .. "s"
	elseif e.kind == "shardBonus" then
		return "+" .. (if bought then e.pct else 0) .. "%", if bought then "MAX" else "+" .. e.pct .. "% shards"
	end
	return if bought then "OPEN" else "LOCKED", if bought then "MAX" else "opens the " .. Econ.Tiers[e.tier + 1].name
end
-- a multiplier with up to 2 decimals under 10 (Starfire x1.75 must not read "x1.7"), then the number format
local function multFmt(n: number): string
	if n >= 10 then return fmt(n) end
	local s = string.format("%.2f", math.floor(n * 100 + 0.5) / 100)
	s = s:gsub("0+$", ""):gsub("%.$", "")
	return s
end
-- a ring-2 node at level lv: its value now and the green step of the next level
local function node2Value(node, lv: number): (string, string)
	local e = node.effect
	local maxed = lv >= #node.costs
	if e.kind == "allMult" then
		local now = e.mult ^ lv
		return "x" .. multFmt(now), if maxed then "MAX" else "x" .. multFmt(now * e.mult) .. " next"
	elseif e.kind == "heavy" then
		return if lv >= 1 then "x" .. (1 + e.per) .. "-x" .. (1 + e.per * #Econ.Tiers) else "x1", if maxed then "MAX" else "x1.25 per tier number"
	end
	return if lv >= 1 then "OPEN" else "NEW", if maxed then "MAX" else "opens the " .. Econ.Tiers[e.tier + 1].name
end
-- the short value on a tree tile (Regrowth's "1.2x")
local function tileValue(node): string
	local e = node.effect
	if e.kind == "tierMult" or e.kind == "allMult" then return "x" .. e.mult end
	if e.kind == "cometEvery" then return e.seconds .. "s" end
	if e.kind == "shardBonus" then return "+" .. e.pct .. "%" end
	if e.kind == "heavy" then return "x" .. (1 + e.per) .. "+" end
	return "NEW"
end
-- why a ring-2 node can't be bought yet (nil = it can, shards allowing)
local function node2Lock(node, r2, novas: number): string?
	if novas < (node.novas or 0) then return "SUPERNOVA " .. node.novas end
	if node.requires and (r2[node.requires] or 0) < 1 then return "needs " .. Econ.Ring2ById[node.requires].name end
	return nil
end
local STAR_NODES = Econ.Ring1 -- (all of ring 1, #219: the tier unlocks too)

------------------------------------------------------------------------ pieces
-- a v12 kit button whose look and words change in place (never rebuilt: hold-to-buy and the scroll stay put)
local function action(parent, x, y, w, h, size: number, z: number?)
	local b, inner, _, shadow = Kit.button(parent, x, y, w, h, LOOK.no[1], LOOK.no[2], { ZIndex = z or 6 })
	local label = Kit.text(inner, 0, 0, w, h, "", size, { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Kit.FONT_HEAVY })
	local o = { button = b, shadow = shadow, label = label }
	function o.set(state: string, text: string)
		if o.state ~= state then
			o.state = state
			local c = LOOK[state] or LOOK.no
			Kit.recolour(b, c[1], c[2])
			Kit.clearVfx(b)
			if state == "buy" then Kit.tagVfx(Kit.shine(b, 2.4)) end
			label.TextColor3 = if state == "no" then hex("#cfc6dd") else WHITE
		end
		Kit.setText(label, text)
	end
	function o.show(on: boolean)
		b.Visible = on
		shadow.Visible = on
	end
	return o
end

-- hold-to-buy (bodies): a tap buys once (on release); held 0.4 s it buys every 0.12 s until let go. A press that turns into
-- a scroll of the list (drag) buys nothing.
local function holdBuy(b: GuiButton, buyOnce: () -> boolean, dragged: () -> boolean)
	local holding, repeated, presses = false, false, 0
	b.MouseButton1Down:Connect(function()
		presses += 1
		local id = presses
		holding, repeated = true, false
		local released
		released = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if id == presses then holding = false end
				released:Disconnect()
			end
		end)
		task.wait(0.4)
		if not holding or id ~= presses or dragged() then return end
		repeated = true
		while holding and id == presses and not dragged() do
			if not buyOnce() then break end
			task.wait(0.12)
		end
	end)
	b.MouseButton1Click:Connect(function()
		if not repeated and not dragged() then buyOnce() end
	end)
end
local function tap(b: GuiButton, fn: () -> (), dragged: () -> boolean)
	b.MouseButton1Click:Connect(function()
		if not dragged() then fn() end
	end)
end
local function setGradient(main: TextLabel, c1: Color3, c2: Color3)
	local g = main:FindFirstChildOfClass("UIGradient")
	if g then g.Color = ColorSequence.new(c1, c2) end
end
local function shown(main: GuiObject, on: boolean)
	main.Parent.Visible = on
end
-- a Kit.text's size (the text and its shadow)
local function textSize(main: TextLabel, size: number)
	for _, l in ipairs(main.Parent:GetChildren()) do
		if l:IsA("TextLabel") then l.TextSize = size end
	end
end
-- a Kit.icon as a black silhouette (its shadow and glow hidden) or back to normal
local function silhouette(img: ImageLabel, on: boolean)
	img.ImageColor3 = if on then Color3.new(0, 0, 0) else WHITE
	for _, c in ipairs(img.Parent:GetChildren()) do
		if c:IsA("ImageLabel") and c ~= img then c.Visible = not on end
	end
end

------------------------------------------------------------------------ the board
function UI.new(id: string, gui: SurfaceGui, spec, ctx)
	local self = setmetatable({ id = id, gui = gui, spec = spec, ctx = ctx, size = ctx.size, targets = {}, sparks = 0 }, UI)
	self:shell()
	if id == "Tree" then self:buildTree()
	elseif id == "Info" then self:buildInfo()
	elseif id == "Bodies" then self:buildBodies()
	else self:buildStars() end
	self:refresh()
	return self
end

function UI:attr(name: string) local s = self.ctx.subject return s and s:GetAttribute(name) end
function UI:stardust(): number return tonumber(self:attr("Stardust")) or 0 end
function UI:owned(k: number): number return tonumber(self:attr("Own" .. (k + 1))) or 0 end
function UI:nodes()
	local t = {}
	for _, n in ipairs(Econ.Ring1) do t[n.id] = self:attr("Node_" .. n.id) == true end
	return t
end
function UI:ring2()
	local t = {}
	for _, n in ipairs(Econ.Ring2) do t[n.id] = tonumber(self:attr("R2_" .. n.id)) or 0 end
	return t
end
function UI:shards(): number return tonumber(self:attr("Shards")) or 0 end
function UI:novas(): number return tonumber(self:attr("Supernovas")) or 0 end
function UI:can(): boolean return self.ctx.canAct == nil or self.ctx.canAct() end
function UI:dragged(): boolean return self.scroll ~= nil and self.scroll.moved end
-- a buy through the island's remote (+ the sound; the boards refresh from the owner's attributes)
function UI:buy(kind: string, arg): boolean
	if not self:can() or self.busy then return false end
	self.busy = true
	local ok = self.ctx.buy(kind, arg)
	self.busy = false
	self.ctx.sound(if ok then "buy" else "no")
	if ok and self.ctx.bought then self.ctx.bought(kind, arg) end
	return ok == true
end
-- a body: UPGRADE (or UNLOCK while it's locked) once; false = stop a hold
function UI:bodyOnce(k: number, kind: string?): boolean
	local n = self:nodes()
	if not Econ.Unlocked(k, n, self:ring2()) then
		local node = unlockNode(k)
		if node and (not node.requires or n[node.requires]) and self:stardust() >= node.cost then self:buy("BuyNode", node.id) else self.ctx.sound("no") end
		return false
	end
	if self:stardust() < Econ.Cost(k, self:owned(k)) then self.ctx.sound("no") return false end
	return self:buy(kind or "BuyBody", k)
end
function UI:nodeOnce(node)
	local n = self:nodes()
	if n[node.id] or (node.requires and not n[node.requires]) or self:stardust() < node.cost then self.ctx.sound("no") return end
	self:buy("BuyNode", node.id)
end
function UI:node2Once(node)
	local r2 = self:ring2()
	local cost = Econ.R2Cost(node.id, r2[node.id] or 0)
	if not cost or node2Lock(node, r2, self:novas()) or self:shards() < cost then self.ctx.sound("no") return end
	self:buy("BuyRing2", node.id)
end

-- the screen's shell: stone-coloured corners round a dark rounded screen, the neon edge (a glow in from every side + a bright
-- line whose light runs round), the big white title (top-left on the pair, centred with a rule under it on the stands)
function UI:shell()
	local W, H = self.size.X, self.size.Y
	local neon = self.spec.Neon
	local B = MapConfig.Boards
	local corners = if self.spec.pair then B.StoneLight elseif self.spec.Style == "Neon" then B.Screen else B.Stone
	Kit.box(self.gui, 0, 0, W, H, { BackgroundTransparency = 0, BackgroundColor3 = corners, ZIndex = 1 })
	local bg = Kit.box(self.gui, 0, 0, W, H, { BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 1 })
	Kit.corner(bg, 40)
	Kit.grad(bg, hex("#151026"), hex("#06050b"), 90)
	local tex = Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.95, ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(256, 64), Size = UDim2.fromScale(1, 1), ZIndex = 1 }, bg)
	Kit.corner(tex, 40)
	self.glows = {}
	for _, s in ipairs({ { 0, 0, W, 44, 90 }, { 0, H - 44, W, 44, 270 }, { 0, 0, 44, H, 0 }, { W - 44, 0, 44, H, 180 } }) do
		local f = Kit.box(self.gui, s[1], s[2], s[3], s[4], { BackgroundTransparency = 0, BackgroundColor3 = neon, ZIndex = 2 })
		Kit.corner(f, 40)
		Kit.new("UIGradient", { Rotation = s[5], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }) }, f)
		table.insert(self.glows, f)
	end
	local line = Kit.box(self.gui, 9, 9, W - 18, H - 18, { ZIndex = 3 })
	Kit.corner(line, 32)
	local st = Kit.stroke(line, WHITE, 5)
	self.edge = Kit.new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, neon), ColorSequenceKeypoint.new(0.42, neon),
		ColorSequenceKeypoint.new(0.5, neon:Lerp(WHITE, 0.8)), ColorSequenceKeypoint.new(0.58, neon), ColorSequenceKeypoint.new(1, neon) }) }, st)
	if not self.spec.pair then
		Kit.text(self.gui, 0, 12, W, 44, self.spec.title, 34, { ZIndex = 9, stroke = 2.6, FontFace = Kit.FONT_HEAVY, TextXAlignment = CENTRE })
		Kit.box(self.gui, W / 2 - 130, 58, 260, 2, { BackgroundTransparency = 0.35, BackgroundColor3 = WHITE, ZIndex = 9 })
	end
end

------------------------------------------------------------------------ the SHARD TREE (ring 2 only, a node graph)
function UI:buildTree()
	local W = self.size.X
	local gui = self.gui
	local noDrag = function() return false end
	self.tiles = {}
	self.links = {}
	-- the heading + your shards
	Kit.text(gui, 40, 98, W - 220, 34, "RING 2 · SHARDS", 28, { ZIndex = 8, stroke = 2, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#d9c2ff") })
	Kit.icon(gui, "shard", W - 172, 92, 40, nil, { ZIndex = 7 })
	self.shardsText = Kit.text(gui, W - 134, 98, 96, 34, "0", 28, { ZIndex = 8, stroke = 2, FontFace = Kit.FONT_HEAVY })
	Kit.box(gui, 40, 136, W - 80, 2, { BackgroundTransparency = 0.6, BackgroundColor3 = WHITE, ZIndex = 6 })
	-- the links first (under the tiles): a rounded bar from centre to centre
	local centres = { hub = cellCentre(HUB.col, HUB.row) }
	for _, g in ipairs(GRAPH) do centres[g.id or g.later] = cellCentre(g.col, g.row) end
	for _, g in ipairs(GRAPH) do
		local a, b = centres[g.from], centres[g.id or g.later]
		local d = b - a
		local bar = Kit.box(gui, (a.X + b.X) / 2 - d.Magnitude / 2, (a.Y + b.Y) / 2 - 4, d.Magnitude, 8,
			{ BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 4, Rotation = math.deg(math.atan2(d.Y, d.X)) })
		Kit.corner(bar, 4)
		table.insert(self.links, { bar = bar, to = g.id })
	end
	-- the hub: your star, where every branch starts
	local hc = centres.hub
	local hub = Kit.box(gui, hc.X - 50, hc.Y - 50, 100, 100, { BackgroundTransparency = 0, BackgroundColor3 = hex("#1c1430"), ZIndex = 5 })
	Kit.corner(hub, 50)
	Kit.stroke(hub, hex("#ffd27a"), 4, 0)
	Kit.icon(gui, "sun", hc.X - 44, hc.Y - 44, 88, Color3.fromRGB(255, 200, 80), { ZIndex = 6 })
	-- the nodes: a dark rounded tile, the icon, the value bottom right, the shard cost under it
	for _, g in ipairs(GRAPH) do
		local node = g.id and Econ.Ring2ById[g.id]
		local later = g.later and Econ.Ring2Later[g.later]
		if not node and not later then continue end
		local x, y = COL_X[g.col] - TILE_W / 2, ROW_Y[g.row]
		local tile = Kit.box(gui, x, y, TILE_W, TILE_H, { BackgroundTransparency = 0.05, BackgroundColor3 = hex("#130f1e"), ZIndex = 5 })
		Kit.corner(tile, 18)
		local st = Kit.stroke(tile, hex("#4b4170"), 3, 0.25)
		local img = Kit.icon(gui, if node then node.icon else later.icon, x + (TILE_W - 76) / 2, y + 8, 76, nil, { ZIndex = 6 })
		local value = Kit.text(gui, x, y + TILE_H - 38, TILE_W - 10, 34, "", 28, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 2.2, FontFace = Kit.FONT_HEAVY })
		local costIcon = Kit.icon(gui, "shard", x + 12, y + TILE_H + 6, 26, nil, { ZIndex = 6 })
		local cost = Kit.text(gui, x + 40, y + TILE_H + 4, TILE_W + 40, 30, "", 24, { ZIndex = 6, stroke = 1.8 })
		local t = { node = node, later = later, tile = tile, stroke = st, img = img, value = value, costIcon = costIcon, cost = cost, x = x, y = y }
		if node and #node.costs > 1 then
			-- (a node with levels: "2/5" in the top-left corner)
			t.level = Kit.text(gui, x + 8, y + 4, 60, 26, "", Kit.ps(18, 22), { ZIndex = 8, stroke = 1.8, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#d9c2ff") })
		end
		if later then
			-- (a branch not in the game yet: a big "?" over the silhouette)
			Kit.text(gui, x, y + 18, TILE_W, 70, "?", 56, { ZIndex = 8, TextXAlignment = CENTRE, stroke = 2.4, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#8a8296") })
		end
		if node then
			-- a tap SELECTS the node (INFO shows it and buys it); it never buys and never opens a window
			local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(TILE_W, TILE_H + 34), ZIndex = 9 }, gui)
			tap(hit, function()
				self.ctx.sound("tab")
				self.ctx.select("node2", node.id)
			end, noDrag)
			hit.MouseEnter:Connect(function() tile.BackgroundColor3 = hex("#251f3a") end)
			hit.MouseLeave:Connect(function() tile.BackgroundColor3 = hex("#130f1e") end)
			self.targets["R2_" .. node.id] = hit
		end
		table.insert(self.tiles, t)
	end
end
function UI:refreshTree()
	local r2, sh, novas = self:ring2(), self:shards(), self:novas()
	local sel = self.ctx.sel
	Kit.setText(self.shardsText, fmt(sh))
	for _, t in ipairs(self.tiles) do self:refreshTile2(t, r2, sh, novas, sel) end
	-- a link: bright once its node is bought, half lit while you can buy it, dark while it's locked
	for _, l in ipairs(self.links) do
		local node = l.to and Econ.Ring2ById[l.to]
		local lv = if node then r2[node.id] or 0 else 0
		local open = node ~= nil and node2Lock(node, r2, novas) == nil
		l.bar.BackgroundColor3 = if lv > 0 then self.spec.Neon:Lerp(WHITE, 0.35) elseif open then self.spec.Neon else hex("#2e2840")
		l.bar.BackgroundTransparency = if lv > 0 then 0 elseif open then 0.45 else 0.15
	end
end
-- a ring-2 tile: a silhouette with what opens it while locked (and for the branches not in the game yet); else its value,
-- its level (2/5) and the next level's shard cost under it
function UI:refreshTile2(t, r2, sh: number, novas: number, sel)
	local node = t.node
	local lv = if node then r2[node.id] or 0 else 0
	local reason = if node then node2Lock(node, r2, novas) else t.later.lockedText
	local locked = reason ~= nil and lv == 0
	local cost = node and Econ.R2Cost(node.id, lv)
	local maxed = node ~= nil and cost == nil
	t.img.ImageColor3 = if locked then Color3.new(0, 0, 0) else WHITE
	local shadow = t.img.Parent:FindFirstChild("Shadow")
	if shadow then shadow.Visible = not locked end
	shown(t.value, not locked)
	if t.level then
		shown(t.level, not locked)
		Kit.setText(t.level, lv .. "/" .. #node.costs)
	end
	if not locked then Kit.setText(t.value, if lv > 0 then (node2Value(node, lv)) else tileValue(node)) end
	t.costIcon.Parent.Visible = not locked and not maxed
	shown(t.cost, true)
	if locked then
		Kit.setText(t.cost, reason)
		t.cost.TextColor3 = GREY_TEXT
		textSize(t.cost, if #reason > 11 then Kit.ps(16, 19) else Kit.ps(20, 22))
		t.cost.Parent.Position = UDim2.fromOffset(t.x - 6, t.y + TILE_H + 6)
	elseif maxed then
		Kit.setText(t.cost, "MAX")
		t.cost.TextColor3 = GREEN_TEXT
	else
		Kit.setText(t.cost, fmt(cost))
		t.cost.TextColor3 = if sh >= cost then WHITE else RED_TEXT
	end
	if not locked then
		textSize(t.cost, 24)
		t.cost.Parent.Position = UDim2.fromOffset(t.x + (if maxed then 30 else 40), t.y + TILE_H + 4)
	end
	local selected = node ~= nil and sel.kind == "node2" and sel.key == node.id
	t.stroke.Color = if selected then WHITE elseif maxed then hex("#7dff9a") elseif locked then hex("#2e2840")
		elseif sh >= cost then GOLD_TEXT else hex("#6a4fa8")
	t.stroke.Thickness = if selected then 4.5 else 3
	t.stroke.Transparency = if selected then 0 else 0.25
	t.tile.BackgroundTransparency = if locked then 0.4 else 0.05
end

------------------------------------------------------------------------ INFO (the TREE's partner only, #221)
function UI:buildInfo()
	local W, H = self.size.X, self.size.Y
	local gui = self.gui
	local ui = {}
	self.ui = ui
	-- (550 x 650: the big title sits over the top edge, so the page starts lower; the page hides while nothing is selected)
	local page = Kit.box(gui, 0, 0, W, H, { ZIndex = 4 })
	ui.page = page
	ui.icon, ui.iconHolder = Kit.icon(page, "sun", 26, 104, 200, WHITE, { ZIndex = 6 })
	ui.name = Kit.text(page, 236, 112, W - 266, 62, "", 56, { ZIndex = 8, TextScaled = true, FontFace = Kit.FONT_HEAVY, stroke = 3, gradient = ColorSequence.new(WHITE, WHITE) })
	ui.level = Kit.text(page, 238, 176, W - 266, 32, "", 27, { ZIndex = 8, stroke = 2 })
	ui.value = Kit.text(page, 238, 212, W - 266, 58, "", 52, { ZIndex = 8, stroke = 3, FontFace = Kit.FONT_HEAVY })
	ui.step = Kit.text(page, 240, 270, W - 266, 34, "", 30, { ZIndex = 8, TextColor3 = GREEN_TEXT, stroke = 2 })
	ui.desc = Kit.text(page, 36, 322, W - 72, 64, "", 25, { ZIndex = 8, TextColor3 = GREY_TEXT, FontFace = Kit.FONT_BOLD, TextWrapped = true, stroke = 1.4 })
	ui.tier = Kit.text(page, 36, 390, W - 72, 34, "RING 2 [SHARDS]", 29, { ZIndex = 8, stroke = 2 })
	ui.prog = Kit.text(page, 36, 424, W - 72, 30, "", 26, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.8 })
	local bar = Kit.box(page, 36, 458, W - 72, 24, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(bar, 12)
	Kit.stroke(bar, Kit.INK, 2)
	ui.fill = Kit.box(bar, 0, 0, 0, 24, { BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 7 })
	Kit.corner(ui.fill, 12)
	Kit.grad(ui.fill, self.spec.Neon:Lerp(WHITE, 0.45), self.spec.Neon, 90)
	ui.barW, ui.barH = W - 72, 24
	-- BUY (the selected node's next level) with its shard cost under it
	ui.buy = action(page, 36, 500, W - 72, 78, 42)
	ui.costX, ui.costY = 80, 584
	ui.costIcon = Kit.icon(page, "shard", 40, ui.costY + 2, 34, nil, { ZIndex = 6 })
	ui.cost = Kit.text(page, ui.costX, ui.costY, W - 120, 38, "", 32, { ZIndex = 6, stroke = 2 })
	tap(ui.buy.button, function()
		local node = if self.ctx.sel.kind == "node2" then Econ.Ring2ById[self.ctx.sel.key] else nil
		if node then self:node2Once(node) else self.ctx.sound("no") end
	end, function() return false end)
	self.targets.Buy = ui.buy.button
	-- nothing selected
	ui.empty = Kit.text(gui, 40, 250, W - 80, 130, "Tap a node on the TREE", 46, { ZIndex = 8, TextXAlignment = CENTRE, TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = true, FontFace = Kit.FONT_HEAVY, stroke = 2.6 })
end
local function setIcon(ui, name: string, glow: Color3)
	ui.icon.Image = A.icon[name] or ""
	for _, c in ipairs(ui.iconHolder:GetChildren()) do
		if c:IsA("ImageLabel") then
			if c.Name == "Shadow" then c.Image = ui.icon.Image elseif c.Name ~= "Icon" then c.ImageColor3 = glow end
		end
	end
end
function UI:refreshInfo()
	local ui = self.ui
	local sel = self.ctx.sel
	local node = if sel.kind == "node2" then Econ.Ring2ById[sel.key] else nil
	ui.page.Visible = node ~= nil
	shown(ui.empty, node == nil)
	if not node then return end
	local r2 = self:ring2()
	local lv = r2[node.id] or 0
	local cost = Econ.R2Cost(node.id, lv)
	local reason = node2Lock(node, r2, self:novas())
	setIcon(ui, node.icon, SHARD_GLOW)
	Kit.setText(ui.name, node.name)
	setGradient(ui.name, hex("#f3eaff"), hex("#b49bff"))
	Kit.setText(ui.level, "LEVEL " .. lv .. " / " .. #node.costs)
	local v, s = node2Value(node, lv)
	Kit.setText(ui.value, v)
	Kit.setText(ui.step, s)
	Kit.setText(ui.desc, node.desc:sub(1, 1):upper() .. node.desc:sub(2) .. ".")
	Kit.setText(ui.prog, lv .. "/" .. #node.costs)
	local fill = lv / #node.costs
	ui.fill.Size = UDim2.fromOffset(math.floor(ui.barW * math.clamp(fill, 0, 1)), ui.barH)
	ui.fill.Visible = fill > 0
	local costText, costCan = nil, false
	local sh = self:shards()
	if not self:can() then
		ui.buy.set("no", "VISIT")
	elseif not cost then
		ui.buy.set("owned", "MAX")
	elseif reason then
		ui.buy.set("no", "LOCKED")
		costText = reason
	else
		ui.buy.set(if sh >= cost then "buy" else "no", "BUY")
		costText, costCan = fmt(cost), sh >= cost
	end
	self:infoCost(costText, costCan)
end
-- the cost under BUY (a number = with the shard icon; words = grey, no icon)
function UI:infoCost(text: string?, can: boolean)
	local ui = self.ui
	local isNumber = text ~= nil and not text:find(" ")
	ui.costIcon.Parent.Visible = isNumber
	shown(ui.cost, text ~= nil)
	Kit.setText(ui.cost, text or "")
	ui.cost.TextColor3 = if not isNumber then GREY_TEXT elseif can then WHITE else RED_TEXT
	ui.cost.Parent.Position = UDim2.fromOffset(if isNumber then ui.costX else 40, ui.costY)
end

------------------------------------------------------------------------ BODIES (Regrowth's MACHINES)
function UI:buildBodies()
	local W, H = self.size.X, self.size.Y
	local sf, scroll = Kit.scroller(self.gui, 30, 72, W - 60, H - 96, "Y", { ZIndex = 4, pointer = self.ctx.pointer })
	self.scroll = scroll
	local dragged = function() return scroll.moved end
	local rw = W - 60 - 16
	self.rows = {}
	for k = 0, #Econ.Tiers - 1 do
		local tier = Econ.Tiers[k + 1]
		local row = Kit.box(sf, 4, 6 + k * 104, rw, 96, { BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 5 })
		Kit.corner(row, 10)
		Kit.grad(row, hex("#261d3b"), hex("#140f20"), 90)
		local st = Kit.stroke(row, self.spec.Neon, 1.5, 0.5)
		local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, row)
		local _ = hit -- (the row only takes the press, so a drag scrolls the list; a tap does nothing else)
		local r = { st = st }
		r.img = Kit.icon(row, tier.icon, 8, 8, 80, tier.colour, { ZIndex = 6 })
		r.name = Kit.text(row, 96, 2, 200, 32, tier.name, 28, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, gradient = ColorSequence.new(hex(TIER_TITLE[k + 1][1]), hex(TIER_TITLE[k + 1][2])) })
		r.level = Kit.text(row, 98, 34, 190, 20, "", 17, { ZIndex = 8, stroke = 1.4 })
		r.tier = Kit.text(row, 98, 53, 190, 18, "", 15, { ZIndex = 8, TextColor3 = GREY_TEXT, stroke = 1.3 })
		r.rateIcon = Kit.icon(row, "stardust", 95, 71, 22, nil, { ZIndex = 7 })
		r.rate = Kit.text(row, 119, 70, 170, 22, "", 18, { ZIndex = 8, TextColor3 = GREEN_TEXT, stroke = 1.5 })
		r.costIcon = Kit.icon(row, "stardust", 300, 6, 22, nil, { ZIndex = 7 })
		r.cost = Kit.text(row, 326, 6, 150, 22, "", 18, { ZIndex = 8, stroke = 1.5 })
		r.up = action(row, 300, 32, 170, 54, 22, 6)
		r.max = action(row, 478, 32, 54, 54, 26, 6)
		r.boost = Kit.text(row, rw - 92, 6, 80, 30, "", 26, { ZIndex = 8, TextXAlignment = RIGHT, TextColor3 = GOLD_TEXT, stroke = 2, FontFace = Kit.FONT_HEAVY })
		holdBuy(r.up.button, function() return self:bodyOnce(k) end, dragged)
		tap(r.max.button, function()
			if Econ.Unlocked(k, self:nodes(), self:ring2()) and self:stardust() >= Econ.Cost(k, self:owned(k)) then
				self:buy("BuyBodyMax", k)
			else
				self.ctx.sound("no")
			end
		end, dragged)
		self.targets["Body" .. k] = r.up.button
		self.rows[k] = r
	end
	sf.CanvasSize = UDim2.fromOffset(0, #Econ.Tiers * 104 + 8)
end
function UI:refreshBodies()
	local n, sd = self:nodes(), self:stardust()
	local r2, novas = self:ring2(), self:novas()
	local can = self:can()
	for k, r in pairs(self.rows) do
		local tier = Econ.Tiers[k + 1]
		local own = self:owned(k)
		local mt = Econ.MilestoneTier(own)
		local open = Econ.Unlocked(k, n, r2)
		local playable = open or unlockNode(k) ~= nil -- (false = a Star tier: ring 2 opens it)
		-- (a tier you haven't opened: "???" and a silhouette, its price on UNLOCK)
		silhouette(r.img, not open)
		Kit.setText(r.name, if open then tier.name else "???")
		shown(r.tier, open)
		shown(r.rate, open)
		r.rateIcon.Parent.Visible = open
		Kit.setText(r.level, if open then "LEVEL " .. own else "LOCKED")
		Kit.setText(r.tier, "TIER " .. mt .. " " .. Econ.MilestoneNames[mt])
		local now = Econ.TierIncomeWith(k, own, n, r2) * Econ.AllMult(n, r2)
		Kit.setText(r.rate, "+" .. fmt(now) .. "/s")
		local boost = Econ.Milestone(own) * (Econ.TierIncomeWith(k, 1, n, r2) / Econ.TierIncome(k, 1)) * Econ.AllMult(n, r2)
		Kit.setText(r.boost, if open and own > 0 then fmt(boost) .. "x" else "")
		local costText, costCan = nil, false
		r.max.show(can and open)
		if not can then
			r.up.set("no", "VISIT")
		elseif not playable then
			-- (before its Supernova: "SUPERNOVA 1"; after it: bought in the tree's ring 2)
			local r2node = Econ.Ring2ById[tier.unlockR2]
			r.up.set("no", if novas < (r2node.novas or 0) then tier.lockedText else "LOCKED")
			if novas >= (r2node.novas or 0) then costText = "ring 2: " .. r2node.name end
		elseif not open then
			local node = unlockNode(k)
			if node.requires and not n[node.requires] then
				r.up.set("no", "LOCKED")
				costText = "unlock the one above first" -- (its name stays "???" too)
			else
				r.up.set(if sd >= node.cost then "buy" else "no", "UNLOCK")
				costText, costCan = fmt(node.cost), sd >= node.cost
			end
		else
			local cost = Econ.Cost(k, own)
			r.up.set(if sd >= cost then "buy" else "no", "UPGRADE")
			r.max.set(if sd >= cost then "blue" else "no", "M")
			costText, costCan = fmt(cost), sd >= cost
		end
		local isNumber = costText ~= nil and not costText:find(" ")
		r.costIcon.Parent.Visible = isNumber
		shown(r.cost, costText ~= nil)
		Kit.setText(r.cost, costText or "")
		r.cost.TextColor3 = if not isNumber then GREY_TEXT elseif costCan then WHITE else RED_TEXT
		r.cost.Parent.Position = UDim2.fromOffset(if isNumber then 326 else 300, 6)
	end
end

------------------------------------------------------------------------ STAR UPGRADES (Regrowth's FACTORY UPGRADES)
function UI:buildStars()
	local W, H = self.size.X, self.size.Y
	local sf, scroll = Kit.scroller(self.gui, 30, 70, W - 60, H - 92, "X", { ZIndex = 4, pointer = self.ctx.pointer })
	self.scroll = scroll
	local dragged = function() return scroll.moved end
	self.cards = {}
	-- (two whole cards in view, like Factory Upgrades; the rest scroll sideways: the scrollbar + the < > arrows say so)
	local ch = H - 92 - 20
	local pitch = (W - 60 - 8) / 2
	for i, node in ipairs(STAR_NODES) do
		local card = Kit.box(sf, 8 + (i - 1) * pitch, 4, pitch - 16, ch, { BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 5 })
		Kit.corner(card, 14)
		Kit.grad(card, hex("#231a33"), hex("#110c1a"), 90)
		local st = Kit.stroke(card, self.spec.Neon, 2, 0.35)
		local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, card)
		local _ = hit -- (the card only takes the press, so a drag scrolls the cards; buying is on UPGRADE)
		Kit.text(card, 16, 8, 190, 34, node.name, 30, { ZIndex = 8, TextScaled = true, FontFace = Kit.FONT_HEAVY, gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
		Kit.text(card, 16, 44, 160, 40, node.desc:upper(), 12, { ZIndex = 8, TextColor3 = GREY_TEXT, FontFace = Kit.FONT_BOLD, TextWrapped = true, stroke = 1 })
		Kit.icon(card, node.icon, 150, 64, 126, NODE_GLOW[node.tab], { ZIndex = 6 })
		-- the star level badge (Regrowth's star with the level in it)
		Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.sparkle, ImageColor3 = hex("#ffb02a"), Position = UDim2.fromOffset(206, -6),
			Size = UDim2.fromOffset(86, 86), ZIndex = 9 }, card)
		local c = { st = st }
		c.badge = Kit.text(card, 206, 20, 86, 34, "0", 30, { ZIndex = 10, TextXAlignment = CENTRE, stroke = 2.4, FontFace = Kit.FONT_HEAVY })
		c.value = Kit.text(card, 16, 96, 140, 38, "", 32, { ZIndex = 8, stroke = 2, FontFace = Kit.FONT_HEAVY })
		c.step = Kit.text(card, 18, 134, 140, 20, "", 16, { ZIndex = 8, TextColor3 = GREEN_TEXT, stroke = 1.4 })
		c.priceIcon = Kit.icon(card, "stardust", 16, ch - 92, 26, nil, { ZIndex = 7 })
		c.price = Kit.text(card, 46, ch - 92, 200, 26, "", 22, { ZIndex = 8, stroke = 1.6 })
		c.priceY = ch - 92
		c.up = action(card, 14, ch - 62, 262, 54, 28, 6)
		tap(c.up.button, function() self:nodeOnce(node) end, dragged)
		c.node = node
		self.targets["Star_" .. node.id] = c.up.button
		table.insert(self.cards, c)
	end
	sf.CanvasSize = UDim2.fromOffset(#STAR_NODES * pitch + 8, 0)
	-- the < > arrows on the edges: shown while there are more cards that way; a tap scrolls one card
	self.arrows = {}
	for _, a in ipairs({ { -1, 8, "<" }, { 1, W - 50, ">" } }) do
		local o = action(self.gui, a[2], 70 + ch / 2 - 34, 42, 68, 34, 12)
		o.set("blue", a[3])
		tap(o.button, function()
			local room = sf.AbsoluteCanvasSize.X - sf.AbsoluteWindowSize.X
			local x = math.clamp(math.floor((sf.CanvasPosition.X + a[1] * pitch) / pitch + 0.5) * pitch, 0, math.max(0, room))
			self.ctx.sound("tab")
			Kit.tween(sf, { CanvasPosition = Vector2.new(x, 0) }, 0.25)
		end, function() return false end)
		self.arrows[a[1]] = o
	end
	local function arrows()
		local room = sf.AbsoluteCanvasSize.X - sf.AbsoluteWindowSize.X
		self.arrows[-1].show(sf.CanvasPosition.X > 2)
		self.arrows[1].show(sf.CanvasPosition.X < room - 2)
	end
	sf:GetPropertyChangedSignal("CanvasPosition"):Connect(arrows)
	sf:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(arrows)
	arrows()
end
function UI:refreshStars()
	local n, sd = self:nodes(), self:stardust()
	local can = self:can()
	for _, c in ipairs(self.cards) do
		local node = c.node
		local bought = n[node.id] == true
		Kit.setText(c.badge, if bought then "1" else "0")
		local needs = node.requires ~= nil and not n[node.requires]
		local v, s = nodeValue(node, bought)
		if node.effect.kind == "unlockTier" and not bought then v = "NEW" end
		Kit.setText(c.value, v)
		Kit.setText(c.step, s)
		c.priceIcon.Parent.Visible = not bought and not needs
		shown(c.price, not bought)
		Kit.setText(c.price, if needs then "needs " .. Econ.Ring1ById[node.requires].name elseif node.cost == 0 then "FREE" else fmt(node.cost))
		c.price.TextColor3 = if needs then GREY_TEXT elseif sd >= node.cost then WHITE else RED_TEXT
		c.price.Parent.Position = UDim2.fromOffset(if needs then 16 else 46, c.priceY)
		if not can then c.up.set("no", "VISIT")
		elseif bought then c.up.set("owned", "OWNED")
		elseif needs then c.up.set("no", "LOCKED")
		else c.up.set(if sd >= node.cost then "buy" else "no", "UPGRADE") end
	end
end

------------------------------------------------------------------------
function UI:refresh()
	if self.id == "Tree" then self:refreshTree()
	elseif self.id == "Info" then self:refreshInfo()
	elseif self.id == "Bodies" then self:refreshBodies()
	else self:refreshStars() end
end
-- scrolls a list so its button is on show (the tutorial arrow points at it)
function UI:reveal(button: GuiObject?)
	if button and self.scroll and button:IsDescendantOf(self.scroll.frame) then self.scroll.reveal(button) end
end
-- the neon edge: its light runs round, its glow breathes; now and then a spark on the edge (not with Reduced Motion)
function UI:step(dt: number)
	if Kit.calm() then return end
	self.edge.Rotation = (self.edge.Rotation + dt * 70) % 360
	local a = 0.42 + math.sin(os.clock() * 2.4) * 0.14
	for _, g in ipairs(self.glows) do g.BackgroundTransparency = a end
	self.sparks += dt
	if self.sparks > 0.6 then
		self.sparks = 0
		local W, H = self.size.X, self.size.Y
		local side = math.random(4)
		local x = if side == 1 then 2 elseif side == 2 then W - 22 else math.random(60, W - 80)
		local y = if side == 3 then 2 elseif side == 4 then H - 22 else math.random(60, H - 80)
		local s = Kit.sparkle(self.gui, x, y, math.random(14, 22), 0)
		s.ImageColor3 = self.spec.Neon:Lerp(WHITE, 0.5)
		task.delay(1.5, function() s:Destroy() end)
	end
end

return UI
