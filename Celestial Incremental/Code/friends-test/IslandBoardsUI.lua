-- IslandBoardsUI (Galaxy Incremental): the screens of the four LIVE island boards, a 1:1 copy of Regrowth's boards in form,
-- layout and behaviour (owner, 2 Nov: "1:1 direct copy boards from regrowth"; vault "Island boards like Regrowth 1to1" = the
-- law; references Map\screens\regrowth_boards). Our own art: v12 kit pieces (UIKit), our icons, our words, galaxy colours.
-- One source of truth: EconConfig + the island OWNER's attributes; buys go through ctx.buy (EconRequest + the island slot:
-- the server checks the owner and the distance). Visitors see the owner's numbers; their buttons are grey "VISIT".
--  * Tree   (Regrowth's PERKS TREE): a grid of rounded node tiles (icon, value, cost under it); a node whose `requires` you
--           don't have is a dark silhouette, like the nodes not in the game yet; a tap shows the node on INFO
--  * Info   (Regrowth's INFO): the selected thing: icon, name, LEVEL / TIER, value + green step, the TIER line, progress,
--           the 10x toggle (bodies), the big UPGRADE with its cost under it
--  * Bodies (Regrowth's MACHINES): rows: name, LEVEL, TIER, +x/s, UPGRADE (cost above it), M (max), the boost ("x4");
--           locked rows UNLOCK; a tap on a row shows it on INFO
--  * Stars  (Regrowth's FACTORY UPGRADES): cards: name, short text, icon, value + step, star level badge, UPGRADE + price
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
--   ctx.sel = the shared selection { kind = "node" | "node2" | "body" | "supernova", key = id | k }, ctx.select(kind, key),
--   ctx.bought(kind, arg), ctx.supernova() (opens the Supernova card; nil = none here)
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

-- the CONSTELLATION TREE's tiles (Regrowth's perks grid, boards pass 3): every ring-1 node in the tree's order (EconConfig.Ring1),
-- 3 a row, left to right, top to bottom; no empty slots (a node you can't buy yet is a dark silhouette). Under it RING 2
-- (shards, alpha part 1): the STELLAR nodes, then the branches not in the game yet ("?" + what opens them).
local TILE_W, TILE_H, PITCH_X, PITCH_Y = 142, 136, 159, 186
local HEAD = 44 -- (a ring's heading)
local TREE_GRID = {}
local TREE_HEADS = {}
do
	local y = 0
	local function section(title: string, list)
		table.insert(TREE_HEADS, { title = title, y = y })
		y += HEAD
		for i, e in ipairs(list) do
			e.x, e.y = 8 + ((i - 1) % 3) * PITCH_X, y + ((i - 1) // 3) * PITCH_Y
			table.insert(TREE_GRID, e)
		end
		y += math.ceil(#list / 3) * PITCH_Y + 6
	end
	local r1, r2 = {}, {}
	for _, n in ipairs(Econ.Ring1) do table.insert(r1, { ring = 1, id = n.id }) end
	for _, n in ipairs(Econ.Ring2) do table.insert(r2, { ring = 2, id = n.id }) end
	for _, l in ipairs(Econ.Ring2Later) do table.insert(r2, { ring = 2, later = l }) end
	section("RING 1 · STARDUST", r1)
	section("RING 2 · SHARDS", r2)
	TREE_GRID.height = y
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
	return if lv >= 1 then "OPEN" else "LOCKED", if maxed then "MAX" else "opens the " .. Econ.Tiers[e.tier + 1].name
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
local STAR_NODES = {}
for _, n in ipairs(Econ.Ring1) do
	if n.effect.kind ~= "unlockTier" then table.insert(STAR_NODES, n) end
end

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
-- a Kit.icon's picture (the icon and its shadow)
local function iconImage(img: ImageLabel, name: string)
	for _, c in ipairs(img.Parent:GetChildren()) do
		if c.Name == "Icon" or c.Name == "Shadow" then c.Image = A.icon[name] or "" end
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

------------------------------------------------------------------------ CONSTELLATION TREE (Regrowth's PERKS TREE)
function UI:buildTree()
	local W, H = self.size.X, self.size.Y
	local sf, scroll = Kit.scroller(self.gui, 28, 96, W - 56, H - 126, "Y", { ZIndex = 4, pointer = self.ctx.pointer })
	self.scroll = scroll
	self.tiles = {}
	-- the rings' headings (ring 2's shows how many shards you have)
	for i, h in ipairs(TREE_HEADS) do
		local label = Kit.text(sf, 10, h.y + 6, W - 90, 32, h.title, 26, { ZIndex = 8, stroke = 2, FontFace = Kit.FONT_HEAVY,
			TextColor3 = if i == 2 then hex("#d9c2ff") else hex("#ffd27a") })
		Kit.box(sf, 10, h.y + 38, W - 90, 2, { BackgroundTransparency = 0.6, BackgroundColor3 = WHITE, ZIndex = 6 })
		if i == 2 then
			Kit.icon(sf, "shard", W - 180, h.y + 2, 36, nil, { ZIndex = 7 })
			self.shardsText = Kit.text(sf, W - 146, h.y + 6, 80, 32, "0", 26, { ZIndex = 8, stroke = 2, FontFace = Kit.FONT_HEAVY })
		end
		local _ = label
	end
	for _, spec in ipairs(TREE_GRID) do
		local node = if spec.ring == 1 then Econ.Ring1ById[spec.id] elseif spec.id then Econ.Ring2ById[spec.id] else nil
		local x, y = spec.x, spec.y
		-- a dark tile with a soft rounded border; the icon centred, the value at the bottom right, the cost under the tile
		local tile = Kit.box(sf, x, y, TILE_W, TILE_H, { BackgroundTransparency = 0.05, BackgroundColor3 = hex("#130f1e"), ZIndex = 5 })
		Kit.corner(tile, 20)
		local st = Kit.stroke(tile, hex("#4b4170"), 3, 0.25)
		local img = Kit.icon(sf, if node then node.icon else spec.later.icon, x + (TILE_W - 92) / 2, y + 12, 92, nil, { ZIndex = 6 })
		local value = Kit.text(sf, x, y + TILE_H - 42, TILE_W - 12, 38, "", 32, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 2.4, FontFace = Kit.FONT_HEAVY })
		local costIcon = Kit.icon(sf, if spec.ring == 2 then "shard" else "stardust", x + 26, y + TILE_H + 6, 28, nil, { ZIndex = 6 })
		local cost = Kit.text(sf, x + 58, y + TILE_H + 4, 110, 32, "", 26, { ZIndex = 6, stroke = 1.8 })
		local t = { node = node, ring = spec.ring, later = spec.later, tile = tile, stroke = st, img = img, value = value, costIcon = costIcon, cost = cost, x = x }
		if node and spec.ring == 2 and #node.costs > 1 then
			-- (a node with levels: "2/5" in the top-left corner)
			t.level = Kit.text(sf, x + 10, y + 6, 60, 26, "", 20, { ZIndex = 8, stroke = 1.8, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#d9c2ff") })
		end
		if spec.later then
			-- (a branch not in the game yet: a big "?" over the silhouette)
			Kit.text(sf, x, y + 22, TILE_W, 80, "?", 64, { ZIndex = 8, TextXAlignment = CENTRE, stroke = 2.4, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#8a8296") })
		end
		if node then
			local kind = if spec.ring == 2 then "node2" else "node"
			local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(x, y),
				Size = UDim2.fromOffset(TILE_W, TILE_H + 40), ZIndex = 9 }, sf)
			tap(hit, function()
				self.ctx.sound("tab")
				self.ctx.select(kind, node.id)
			end, function() return scroll.moved end)
			hit.MouseEnter:Connect(function() tile.BackgroundColor3 = hex("#251f3a") end)
			hit.MouseLeave:Connect(function() tile.BackgroundColor3 = hex("#130f1e") end)
			self.targets[(if spec.ring == 2 then "R2_" else "Node_") .. node.id] = hit
		end
		table.insert(self.tiles, t)
	end
	sf.CanvasSize = UDim2.fromOffset(0, TREE_GRID.height + 4)
end
function UI:refreshTree()
	local n, sd = self:nodes(), self:stardust()
	local r2, sh, novas = self:ring2(), self:shards(), self:novas()
	local sel = self.ctx.sel
	if self.shardsText then Kit.setText(self.shardsText, fmt(sh)) end
	for _, t in ipairs(self.tiles) do
		if t.ring == 2 then
			self:refreshTile2(t, r2, sh, novas, sel)
			continue
		end
		local node = t.node
		local locked = not node or (node.requires ~= nil and not n[node.requires])
		local bought = node ~= nil and n[node.id]
		t.img.ImageColor3 = if locked then Color3.new(0, 0, 0) else WHITE
		local shadow = t.img.Parent:FindFirstChild("Shadow")
		if shadow then shadow.Visible = not locked end
		shown(t.value, not locked)
		shown(t.cost, not locked)
		t.costIcon.Parent.Visible = not locked and not bought
		if not locked then
			Kit.setText(t.value, tileValue(node))
			if bought then
				Kit.setText(t.cost, "OWNED")
				t.cost.TextColor3 = GREEN_TEXT
			else
				Kit.setText(t.cost, if node.cost == 0 then "FREE" else fmt(node.cost))
				t.cost.TextColor3 = if sd >= node.cost then WHITE else RED_TEXT
			end
		end
		local selected = node ~= nil and sel.kind == "node" and sel.key == node.id
		t.stroke.Color = if selected then WHITE elseif bought then hex("#7dff9a") elseif locked then hex("#2e2840")
			elseif sd >= node.cost then GOLD_TEXT else hex("#4b4170")
		t.stroke.Thickness = if selected then 4.5 else 3
		t.stroke.Transparency = if selected then 0 else 0.25
		t.tile.BackgroundTransparency = if locked then 0.4 else 0.05
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
		textSize(t.cost, if #reason > 11 then 17 else 22)
		t.cost.Parent.Position = UDim2.fromOffset(t.x + 4, t.tile.Position.Y.Offset + TILE_H + 6)
	elseif maxed then
		Kit.setText(t.cost, "MAX")
		t.cost.TextColor3 = GREEN_TEXT
	else
		Kit.setText(t.cost, fmt(cost))
		t.cost.TextColor3 = if sh >= cost then WHITE else RED_TEXT
	end
	if not locked then
		textSize(t.cost, 26)
		t.cost.Parent.Position = UDim2.fromOffset(t.x + (if maxed then 36 else 58), t.tile.Position.Y.Offset + TILE_H + 4)
	end
	local selected = node ~= nil and sel.kind == "node2" and sel.key == node.id
	t.stroke.Color = if selected then WHITE elseif maxed then hex("#7dff9a") elseif locked then hex("#2e2840")
		elseif sh >= cost then GOLD_TEXT else hex("#6a4fa8")
	t.stroke.Thickness = if selected then 4.5 else 3
	t.stroke.Transparency = if selected then 0 else 0.25
	t.tile.BackgroundTransparency = if locked then 0.4 else 0.05
end

------------------------------------------------------------------------ INFO (Regrowth's INFO)
function UI:buildInfo()
	local W = self.size.X
	local gui = self.gui
	local ui = {}
	self.ui = ui
	-- (550 x 650: the big title sits over the top edge, so the page starts lower)
	ui.icon, ui.iconHolder = Kit.icon(gui, "sun", 26, 104, 200, WHITE, { ZIndex = 6 })
	ui.name = Kit.text(gui, 236, 112, W - 266, 62, "", 56, { ZIndex = 8, TextScaled = true, FontFace = Kit.FONT_HEAVY, stroke = 3, gradient = ColorSequence.new(WHITE, WHITE) })
	ui.level = Kit.text(gui, 238, 176, W - 266, 32, "", 27, { ZIndex = 8, stroke = 2 })
	ui.value = Kit.text(gui, 238, 212, W - 266, 58, "", 52, { ZIndex = 8, stroke = 3, FontFace = Kit.FONT_HEAVY })
	ui.step = Kit.text(gui, 240, 270, W - 266, 34, "", 30, { ZIndex = 8, TextColor3 = GREEN_TEXT, stroke = 2 })
	ui.desc = Kit.text(gui, 36, 322, W - 72, 64, "", 25, { ZIndex = 8, TextColor3 = GREY_TEXT, FontFace = Kit.FONT_BOLD, TextWrapped = true, stroke = 1.4 })
	ui.tier = Kit.text(gui, 36, 390, W - 72, 34, "", 29, { ZIndex = 8, stroke = 2 })
	ui.prog = Kit.text(gui, 36, 424, W - 72, 30, "", 26, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.8 })
	local bar = Kit.box(gui, 36, 458, W - 72, 24, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(bar, 12)
	Kit.stroke(bar, Kit.INK, 2)
	ui.fill = Kit.box(bar, 0, 0, 0, 24, { BackgroundTransparency = 0, BackgroundColor3 = WHITE, ZIndex = 7 })
	Kit.corner(ui.fill, 12)
	Kit.grad(ui.fill, self.spec.Neon:Lerp(WHITE, 0.45), self.spec.Neon, 90)
	ui.barW, ui.barH = W - 72, 24
	-- 10x (bodies: buy 10 at once) + UPGRADE; nodes have one level, so they use the wide UPGRADE
	ui.ten = action(gui, 36, 500, 100, 78, 34)
	ui.up = action(gui, 148, 500, W - 184, 78, 42)
	ui.upWide = action(gui, 36, 500, W - 72, 78, 42)
	ui.costX, ui.costY = 80, 584
	ui.costIcon = Kit.icon(gui, "stardust", 40, ui.costY + 2, 34, nil, { ZIndex = 6 })
	ui.cost = Kit.text(gui, ui.costX, ui.costY, W - 120, 38, "", 32, { ZIndex = 6, stroke = 2 })
	self.ten = false
	tap(ui.ten.button, function()
		self.ten = not self.ten
		self.ctx.sound("tab")
		self:refresh()
	end, function() return false end)
	local function once(): boolean
		local sel = self.ctx.sel
		if sel.kind == "body" then return self:bodyOnce(sel.key, if self.ten then "BuyBody10" else "BuyBody") end
		if sel.kind == "supernova" then
			if self:can() and self.ctx.supernova then self.ctx.sound("tab") self.ctx.supernova() else self.ctx.sound("no") end
			return false
		end
		if sel.kind == "node2" then
			local node2 = Econ.Ring2ById[sel.key]
			if node2 then self:node2Once(node2) end
			return false
		end
		local node = Econ.Ring1ById[sel.key]
		if node then self:nodeOnce(node) end
		return false
	end
	holdBuy(ui.up.button, once, function() return false end)
	tap(ui.upWide.button, once, function() return false end)
	self.targets.Upgrade = ui.up.button
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
	local n, sd = self:nodes(), self:stardust()
	local r2 = self:ring2()
	local can = self:can()
	local fill, progress = 0, ""
	if sel.kind == "supernova" then
		-- SUPERNOVA (ready): what you get now and what waiting gives; the button opens the confirm card
		local earned = tonumber(self:attr("EarnedRun")) or 0
		local got = Econ.ShardsFor(earned, n)
		local later = Econ.ShardsFor(earned * 2, n)
		setIcon(ui, "sun", Color3.fromRGB(255, 200, 80))
		Kit.setText(ui.name, "SUPERNOVA")
		setGradient(ui.name, hex("#fff1c0"), hex("#ffb02a"))
		Kit.setText(ui.level, "READY · SUPERNOVA " .. (self:novas() + 1))
		Kit.setText(ui.value, got .. " SHARDS")
		Kit.setText(ui.step, "+" .. (later - got) .. " if you earn 2x first")
		Kit.setText(ui.desc, "Resets stardust, bodies and ring 1. Keeps shards, ring 2 and your rank.")
		Kit.setText(ui.tier, "EARNED THIS RUN " .. fmt(earned))
		progress, fill = "100%", 1
		ui.up.show(false)
		ui.ten.show(false)
		ui.upWide.show(true)
		ui.upWide.set(if can then "buy" else "no", if can then "SUPERNOVA" else "VISIT")
		self:infoCost(nil, false)
	elseif sel.kind == "node2" then
		-- a ring-2 node (shards)
		local node = Econ.Ring2ById[sel.key] or Econ.Ring2[1]
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
		Kit.setText(ui.tier, "RING 2 [SHARDS]")
		progress, fill = lv .. "/" .. #node.costs, lv / #node.costs
		ui.up.show(false)
		ui.ten.show(false)
		ui.upWide.show(true)
		local costText, costCan = nil, false
		local sh = self:shards()
		if not can then
			ui.upWide.set("no", "VISIT")
		elseif not cost then
			ui.upWide.set("owned", "MAX")
		elseif reason then
			ui.upWide.set("no", "LOCKED")
			costText = reason
		else
			ui.upWide.set(if sh >= cost then "buy" else "no", "UPGRADE")
			costText, costCan = fmt(cost), sh >= cost
		end
		self:infoCost(costText, costCan, "shard")
	elseif sel.kind == "body" then
		local k = sel.key
		local tier = Econ.Tiers[k + 1]
		local own = self:owned(k)
		local mt = Econ.MilestoneTier(own)
		setIcon(ui, tier.icon, tier.colour)
		Kit.setText(ui.name, tier.name)
		setGradient(ui.name, hex(TIER_TITLE[k + 1][1]), hex(TIER_TITLE[k + 1][2]))
		Kit.setText(ui.level, "LEVEL " .. own .. " / TIER " .. mt)
		local playable = unlockNode(k) ~= nil or k == 0 or Econ.Unlocked(k, n, r2) -- (false = a Star tier ring 2 hasn't opened)
		local open = Econ.Unlocked(k, n, r2)
		local add = if self.ten then 10 else 1
		local now = Econ.TierIncomeWith(k, own, n, r2) * Econ.AllMult(n, r2)
		local after = Econ.TierIncomeWith(k, own + add, n, r2) * Econ.AllMult(n, r2)
		Kit.setText(ui.value, fmt(now) .. "/s")
		Kit.setText(ui.step, if open then "+" .. fmt(after - now) .. "/s" else "")
		local nextM = Econ.NextMilestone(own)
		local each = Econ.TierIncomeWith(k, 1, n, r2) * Econ.AllMult(n, r2)
		Kit.setText(ui.desc, if not playable then "Opens at " .. tier.lockedText .. ", in the tree's ring 2."
			elseif open then "Earns " .. fmt(each) .. "/s each" .. (if nextM then ", x2 at " .. nextM .. "." else ".")
			else "Opens with " .. unlockNode(k).name .. ".")
		Kit.setText(ui.tier, "TIER " .. mt .. " [" .. Econ.MilestoneNames[mt] .. "]")
		if nextM then
			local prev = Econ.Milestones[mt] or 0
			progress, fill = own .. "/" .. nextM, (own - prev) / (nextM - prev)
		else
			progress, fill = "MAX", 1
		end
		ui.upWide.show(false)
		ui.up.show(true)
		ui.ten.show(can and open)
		ui.ten.set(if self.ten then "blue" else "no", "10x")
		local costText, costCan = nil, false
		if not can then
			ui.up.set("no", "VISIT")
		elseif not playable then
			ui.up.set("no", "LOCKED")
			costText = "ring 2: " .. Econ.Ring2ById[tier.unlockR2].name
		elseif not open then
			local node = unlockNode(k)
			if node.requires and not n[node.requires] then
				ui.up.set("no", "LOCKED")
				costText = "unlock the " .. Econ.Tiers[k].name .. " first"
			else
				ui.up.set(if sd >= node.cost then "buy" else "no", "UNLOCK")
				costText, costCan = fmt(node.cost), sd >= node.cost
			end
		else
			local total = 0
			for i = 0, add - 1 do total += Econ.Cost(k, own + i) end
			ui.up.set(if sd >= Econ.Cost(k, own) then "buy" else "no", "UPGRADE")
			costText, costCan = fmt(total), sd >= total
		end
		self:infoCost(costText, costCan)
	else
		local node = Econ.Ring1ById[sel.key] or Econ.Ring1[1]
		local bought = n[node.id] == true
		setIcon(ui, node.icon, NODE_GLOW[node.tab] or WHITE)
		Kit.setText(ui.name, node.name)
		setGradient(ui.name, hex("#fff1c0"), hex("#ffb02a"))
		Kit.setText(ui.level, "LEVEL " .. (if bought then 1 else 0) .. " / 1")
		local v, s = nodeValue(node, bought)
		Kit.setText(ui.value, v)
		Kit.setText(ui.step, s)
		Kit.setText(ui.desc, node.desc:sub(1, 1):upper() .. node.desc:sub(2) .. ".")
		Kit.setText(ui.tier, "RING 1 [CONSTELLATION]")
		local got = 0
		for _, x in ipairs(Econ.Ring1) do if n[x.id] then got += 1 end end
		progress, fill = got .. "/" .. #Econ.Ring1, got / #Econ.Ring1
		ui.up.show(false)
		ui.ten.show(false)
		ui.upWide.show(true)
		local costText, costCan = nil, false
		if not can then
			ui.upWide.set("no", "VISIT")
		elseif bought then
			ui.upWide.set("owned", "OWNED")
		elseif node.requires and not n[node.requires] then
			ui.upWide.set("no", "LOCKED")
			costText = "needs " .. Econ.Ring1ById[node.requires].name
		else
			ui.upWide.set(if sd >= node.cost then "buy" else "no", "UPGRADE")
			costText, costCan = if node.cost == 0 then "FREE" else fmt(node.cost), sd >= node.cost
		end
		self:infoCost(costText, costCan)
	end
	Kit.setText(ui.prog, progress)
	ui.fill.Size = UDim2.fromOffset(math.floor(ui.barW * math.clamp(fill, 0, 1)), ui.barH)
	ui.fill.Visible = fill > 0
end
-- the cost under UPGRADE (a number = with the currency's icon, stardust or shards; words = grey, no icon)
function UI:infoCost(text: string?, can: boolean, currency: string?)
	local ui = self.ui
	local isNumber = text ~= nil and not text:find(" ")
	if ui.currency ~= (currency or "stardust") then
		ui.currency = currency or "stardust"
		iconImage(ui.costIcon, ui.currency)
	end
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
		tap(hit, function()
			self.ctx.sound("tab")
			self.ctx.select("body", k)
		end, dragged)
		Kit.icon(row, tier.icon, 8, 8, 80, tier.colour, { ZIndex = 6 })
		Kit.text(row, 96, 2, 200, 32, tier.name, 28, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, gradient = ColorSequence.new(hex(TIER_TITLE[k + 1][1]), hex(TIER_TITLE[k + 1][2])) })
		local r = { st = st }
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
	local sel = self.ctx.sel
	for k, r in pairs(self.rows) do
		local tier = Econ.Tiers[k + 1]
		local own = self:owned(k)
		local mt = Econ.MilestoneTier(own)
		local open = Econ.Unlocked(k, n, r2)
		local playable = open or unlockNode(k) ~= nil -- (false = a Star tier: ring 2 opens it)
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
				costText = "unlock the " .. Econ.Tiers[k].name .. " first"
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
		local selected = sel.kind == "body" and sel.key == k
		r.st.Thickness = if selected then 3 else 1.5
		r.st.Transparency = if selected then 0 else 0.5
		r.st.Color = if selected then WHITE else self.spec.Neon
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
		tap(hit, function()
			self.ctx.sound("tab")
			self.ctx.select("node", node.id)
		end, dragged)
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
	local sel = self.ctx.sel
	for _, c in ipairs(self.cards) do
		local node = c.node
		local bought = n[node.id] == true
		Kit.setText(c.badge, if bought then "1" else "0")
		local v, s = nodeValue(node, bought)
		Kit.setText(c.value, v)
		Kit.setText(c.step, s)
		c.priceIcon.Parent.Visible = not bought
		shown(c.price, not bought)
		Kit.setText(c.price, if node.cost == 0 then "FREE" else fmt(node.cost))
		c.price.TextColor3 = if sd >= node.cost then WHITE else RED_TEXT
		if not can then c.up.set("no", "VISIT")
		elseif bought then c.up.set("owned", "OWNED")
		else c.up.set(if sd >= node.cost then "buy" else "no", "UPGRADE") end
		local selected = sel.kind == "node" and sel.key == node.id
		c.st.Thickness = if selected then 3.5 else 2
		c.st.Transparency = if selected then 0 else 0.35
		c.st.Color = if selected then WHITE else self.spec.Neon
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
