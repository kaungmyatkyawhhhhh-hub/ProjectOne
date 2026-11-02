-- TreePanel (Galaxy Incremental): the approved v12 CONSTELLATION TREE window, live (Map\images\board_tree_v12.png / 2: the
-- window 700 x 470 at (30, 32) of a 745 x 512 canvas). Used on the island's CONSTELLATION TREE board now; the 2D Tree window
-- (hotbar T, alpha) builds the same panel.
-- Ring 1 = EconConfig.Ring1 (the same table the Upgrades window sells; one source of truth). The node places are the v12
-- diamonds'. A node: bought = green edge, can be bought (its `requires` owned) = gold edge, locked = dark with "?". Click a
-- node -> the bottom bar shows it; its BUY button buys it (ring 1 is paid in STARDUST, design note section 2).
-- TreePanel.new(parent, opts): opts like UpgradesPanel (subject, origin, chip, canAct, buy, sound, toast).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local A = Kit.A
local hex = Kit.hex
local fmt = Econ.Format

local Tree = {}
Tree.__index = Tree

-- the v12 diamonds (window coordinates = the PNG / 2 - (30, 32)) and which ring-1 node sits on each
Tree.NODES = {
	{ id = "FirstLight", at = Vector2.new(106, 224) },
	{ id = "LunarPull", at = Vector2.new(246, 183) },
	{ id = "OrbitSpeed", at = Vector2.new(246, 273) },
	{ id = "PlanetSeed", at = Vector2.new(396, 224) },
	{ id = "GasGiant", at = Vector2.new(536, 173) },
	{ id = "CometLure", at = Vector2.new(536, 283) },
	{ id = nil, at = Vector2.new(646, 224) }, -- (Milestone Hunter: not priced yet)
}
Tree.LINKS = { { 1, 2 }, { 1, 3 }, { 2, 4 }, { 3, 4 }, { 4, 5 }, { 4, 6 }, { 5, 7 }, { 6, 7 } }
local GREEN, GOLD, DARK = hex("#7dff9a"), hex("#ffd84a"), hex("#4a4552")

function Tree.new(parent: Instance, opts)
	local self = setmetatable({}, Tree)
	self.opts = opts
	self.subject = opts.subject
	local o = opts.origin or Vector2.zero
	local win = Kit.box(parent, o.X, o.Y, 700, 470, { Name = "TreeWindow" })
	self.root = win

	-- frame + glowing edge (green), header (green with static stripes), title, the currency chip
	local edge = Kit.box(win, -4, -4, 708, 478, { ZIndex = 1 })
	Kit.corner(edge, 14)
	local st = Kit.stroke(edge, Color3.new(1, 1, 1), 6)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, hex("#1fae4a")), ColorSequenceKeypoint.new(0.5, hex("#b8ffc8")), ColorSequenceKeypoint.new(1, hex("#1fae4a")) })
	g.Parent = st
	self.edgeGradient = g
	local frame = Kit.box(win, 0, 0, 700, 470, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 2 })
	Kit.corner(frame, 10)
	local body = Kit.box(win, 3, 3, 694, 464, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.corner(body, 8)
	Kit.grad(body, hex("#101614"), hex("#0b0d0c"), 90)
	Kit.stroke(body, hex("#2fbf5a"), 1.5, 0.45)
	local header = Kit.box(win, 3, 3, 694, 56, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4, ClipsDescendants = true })
	Kit.corner(header, 8)
	Kit.grad(header, hex("#0d3a16"), hex("#1f8a38"), 0)
	Kit.new("ImageLabel", { BackgroundTransparency = 1, Image = A.stripes, ImageTransparency = 0.9, Size = UDim2.fromOffset(512, 128), ZIndex = 4 }, header)
	Kit.box(win, 3, 40, 694, 20, { BackgroundTransparency = 0, BackgroundColor3 = hex("#16702c"), ZIndex = 4 })
	Kit.box(win, 9, 4, 682, 2, { BackgroundTransparency = 0.4, BackgroundColor3 = hex("#b8ffc8"), ZIndex = 5 })
	local sweep = Kit.shine(header, 4.5, 0.16, 0.3)
	sweep.ZIndex = 5
	Kit.box(win, 3, 59, 694, 2, { BackgroundTransparency = 0, BackgroundColor3 = Kit.INK, ZIndex = 5 })
	Kit.icon(win, "planet", -20, -25, 90, Color3.fromRGB(170, 130, 255), { ZIndex = 9 })
	Kit.text(win, 80, 13, 360, 34, "CONSTELLATION TREE", 28, { ZIndex = 8, stroke = 1.8 })
	local chip = Kit.box(win, 438, 13, 150, 34, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 })
	Kit.corner(chip, 4)
	Kit.stroke(chip, Kit.INK, 2)
	Kit.grad(chip, hex("#3a1f7a"), hex("#7a4cff"), 0)
	self.chipText = Kit.text(win, 470, 12, 70, 24, "0", 20, { ZIndex = 8, stroke = 1.5, TextXAlignment = Enum.TextXAlignment.Center })
	Kit.text(win, 470, 33, 70, 12, "SHARDS", 9, { ZIndex = 8, stroke = 1, TextColor3 = hex("#e6dcff"), TextXAlignment = Enum.TextXAlignment.Center })
	Kit.icon(win, "shard", 548, 2, 50, Color3.fromRGB(170, 110, 255), { ZIndex = 8 })

	-- the constellation panel (17,75 666x298)
	local graph = Kit.box(win, 17, 75, 666, 298, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 4 })
	Kit.corner(graph, 6)
	Kit.stroke(graph, hex("#2a2433"), 1.5)
	self.links = {}
	for i, l in ipairs(Tree.LINKS) do
		local a, b = Tree.NODES[l[1]].at, Tree.NODES[l[2]].at
		local mid, d = (a + b) / 2, (b - a)
		local holder = Kit.box(win, mid.X, mid.Y, d.Magnitude - 40, 6, { AnchorPoint = Vector2.new(0.5, 0.5), Rotation = math.deg(math.atan2(d.Y, d.X)), ZIndex = 5 })
		self.links[i] = holder
	end
	self.nodeUI = {}
	for i, spec in ipairs(Tree.NODES) do
		local node = spec.id and Econ.Ring1ById[spec.id]
		local d = Kit.box(win, spec.at.X, spec.at.Y, 54, 54, { AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundTransparency = 0, BackgroundColor3 = hex("#16131b"), ZIndex = 6 })
		local stroke = Kit.stroke(d, DARK, 3)
		local _, icon = Kit.icon(win, node and node.icon or "lock", spec.at.X - 26, spec.at.Y - 26, 52, nil, { ZIndex = 7 })
		local q = Kit.text(win, spec.at.X - 20, spec.at.Y - 18, 40, 36, "?", 30, { ZIndex = 9, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#8a8296") })
		local name = Kit.text(win, spec.at.X - 80, spec.at.Y + 36, 160, 18, if node then node.name else "?", 13, { ZIndex = 8, TextXAlignment = Enum.TextXAlignment.Center })
		local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(spec.at.X - 36, spec.at.Y - 36), Size = UDim2.fromOffset(72, 72), ZIndex = 10 }, win)
		hit.MouseEnter:Connect(function() Kit.tween(d, { Size = UDim2.fromOffset(60, 60) }, 0.1) end)
		hit.MouseLeave:Connect(function() Kit.tween(d, { Size = UDim2.fromOffset(54, 54) }, 0.1) end)
		hit.MouseButton1Click:Connect(function()
			if node then
				if self.opts.sound then self.opts.sound("tab") end
				self.selected = node.id
				self:refresh()
			end
		end)
		self.nodeUI[i] = { diamond = d, stroke = stroke, icon = icon, q = q, name = name, node = node }
	end
	Kit.sparkle(win, 120, 196, 10, 0.3)
	Kit.sparkle(win, 410, 260, 8, 1.1)

	-- the bottom bar (17,385 666x70, gold edge): the selected node, its value chip, BUY
	local bar = Kit.box(win, 17, 385, 666, 70, { BackgroundTransparency = 0, BackgroundColor3 = hex("#14111a"), ZIndex = 4 })
	Kit.corner(bar, 6)
	Kit.stroke(bar, GOLD, 2.5)
	self.bar = bar
	local _, barIcon = Kit.icon(win, "sun", 30, 392, 56, Color3.fromRGB(255, 150, 60), { ZIndex = 7 })
	self.barIcon = barIcon
	self.barName = Kit.text(win, 100, 393, 240, 26, "", 20, { ZIndex = 8, gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
	self.barDesc = Kit.text(win, 100, 421, 240, 16, "", 11, { ZIndex = 8, FontFace = Kit.FONT_BOLD, TextColor3 = hex("#a99fb8"), stroke = 1 })
	local c = Kit.box(win, 345, 402, 90, 32, { BackgroundTransparency = 0, BackgroundColor3 = hex("#221d2a"), ZIndex = 6 })
	Kit.corner(c, 4)
	Kit.stroke(c, hex("#3a3346"), 1.5)
	self.barChip = Kit.text(win, 345, 406, 90, 24, "", 17, { ZIndex = 7, TextColor3 = hex("#7dff6b"), TextXAlignment = Enum.TextXAlignment.Center })
	self:refresh()
	return self
end

function Tree:attr(name: string)
	local s = self.subject
	return s and s:GetAttribute(name)
end
function Tree:nodes()
	local t = {}
	for _, n in ipairs(Econ.Ring1) do t[n.id] = self:attr("Node_" .. n.id) == true end
	return t
end
function Tree:canAct(): boolean
	return self.opts.canAct == nil or self.opts.canAct()
end
local function effectText(node): string
	local e = node.effect
	if e.kind == "tierMult" or e.kind == "allMult" then return "x" .. tostring(e.mult) end
	if e.kind == "cometEvery" then return e.seconds .. "s" end
	return "OPEN"
end

function Tree:setBuy(state: string, cost: number?)
	local key = state .. "|" .. tostring(cost)
	if self.buyKey == key then return end
	self.buyKey = key
	if self.buyBtn then self.buyBtn:Destroy() self.buyShadow:Destroy() end
	local c1, c2 = hex("#7dff7a"), hex("#1fa83a")
	if state == "no" or state == "visit" or state == "locked" then c1, c2 = hex("#6a6474"), hex("#3f3a48") elseif state == "owned" then c1, c2 = hex("#b49bff"), hex("#5a3ad8") end
	local b, inner, _, shadow = Kit.button(self.root, 522, 396, 148, 50, c1, c2, { ZIndex = 6 })
	self.buyBtn, self.buyShadow = b, shadow
	local z = inner.ZIndex
	if state == "owned" then
		Kit.text(inner, 0, 9, 148, 32, "OWNED", 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, FontFace = Kit.FONT_HEAVY })
	elseif state == "visit" then
		Kit.text(inner, 0, 9, 148, 32, "VISIT", 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
	elseif state == "locked" then
		Kit.icon(inner, "lock", 12, 10, 30, nil, { ZIndex = z })
		Kit.text(inner, 40, 12, 100, 26, "LOCKED", 18, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = hex("#cfc6dd") })
	else
		Kit.icon(inner, "stardust", 14, 12, 26, nil, { ZIndex = z })
		Kit.text(inner, 40, 9, 100, 30, if cost == 0 then "FREE" else fmt(cost or 0), 24, { ZIndex = z, TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if state == "no" then hex("#ff6b6b") else Color3.new(1, 1, 1) })
		if state == "buy" then
			Kit.shine(b, 2.4)
			Kit.sparkle(self.root, 522 + 130, 396 - 6, 12, 0)
			Kit.sparkle(self.root, 522 - 6, 396 + 40, 10, 0.8)
		end
	end
	b.MouseButton1Click:Connect(function()
		if state ~= "buy" or not self:canAct() or self.busy then
			if state == "no" and self.opts.sound then self.opts.sound("no") end
			return
		end
		self.busy = true
		local ok = self.opts.buy("BuyNode", self.selected)
		self.busy = false
		if ok then
			if self.opts.sound then self.opts.sound("buy") end
			local main, _, holder = Kit.text(self.root, 522, 370, 148, 26, "BOUGHT!", 20, { ZIndex = 12, TextColor3 = hex("#7dff6b"), TextXAlignment = Enum.TextXAlignment.Center })
			local _2 = main
			Kit.tween(holder, { Position = UDim2.fromOffset(522, 340) }, 0.9)
			task.delay(1, function() holder:Destroy() end)
			self:refresh()
		end
	end)
	self.targets = { Buy = b }
end

function Tree:refresh()
	local n = self:nodes()
	local sd = self:attr("Stardust") or 0
	local function state(node)
		if not node then return "locked" end
		if n[node.id] then return "bought" end
		if node.requires and not n[node.requires] then return "locked" end
		return "open"
	end
	-- the default selection: the first node you can buy, else the first not bought
	if not self.selected or (n[self.selected] and not self.userPicked) then
		self.selected = nil
		for _, spec in ipairs(Tree.NODES) do
			local node = spec.id and Econ.Ring1ById[spec.id]
			if node and state(node) == "open" then self.selected = node.id break end
		end
		self.selected = self.selected or "FirstLight"
	end
	for _, ui in ipairs(self.nodeUI) do
		local s = state(ui.node)
		ui.stroke.Color = if s == "bought" then GREEN elseif s == "open" then GOLD else DARK
		ui.icon.Visible = s ~= "locked"
		ui.q.Parent.Visible = s == "locked"
		Kit.setText(ui.name, if s == "locked" then "?" else ui.node.name)
		ui.name.TextColor3 = if s == "locked" then hex("#8a8296") else Color3.new(1, 1, 1)
		ui.stroke.Thickness = if ui.node and ui.node.id == self.selected then 5 else 3
	end
	for i, l in ipairs(Tree.LINKS) do
		local a, b = Tree.NODES[l[1]], Tree.NODES[l[2]]
		local lit = a.id and b.id and n[a.id] and n[b.id]
		local holder = self.links[i]
		holder.BackgroundTransparency = if lit then 0 else 1
		holder.BackgroundColor3 = GREEN
		if not lit and not holder:FindFirstChild("Dash") then
			for k = 0, 7 do
				local dash = Kit.box(holder, k * holder.Size.X.Offset / 8, 1, holder.Size.X.Offset / 16, 4, { Name = "Dash", BackgroundTransparency = 0, BackgroundColor3 = hex("#3a3346"), ZIndex = 5 })
				local _ = dash
			end
		elseif lit then
			for _, c in ipairs(holder:GetChildren()) do c:Destroy() end
		end
	end
	local node = Econ.Ring1ById[self.selected]
	if node then
		for _, c in ipairs(self.barIcon:GetChildren()) do
			if c.Name == "Icon" or c.Name == "Shadow" then c.Image = A.icon[node.icon] or "" end
		end
		Kit.setText(self.barName, node.name)
		Kit.setText(self.barDesc, node.desc)
		Kit.setText(self.barChip, effectText(node))
		local s = state(node)
		if s == "bought" then self:setBuy("owned")
		elseif s == "locked" then self:setBuy("locked")
		elseif not self:canAct() then self:setBuy("visit")
		else self:setBuy(if sd >= node.cost then "buy" else "no", node.cost) end
	end
	Kit.setText(self.chipText, fmt(tonumber(self:attr("Shards")) or 0))
end

function Tree:step(dt: number)
	if self.edgeGradient and not Kit.calm() then self.edgeGradient.Rotation = (self.edgeGradient.Rotation + dt * 60) % 360 end
end
function Tree:destroy() self.root:Destroy() end

return Tree
