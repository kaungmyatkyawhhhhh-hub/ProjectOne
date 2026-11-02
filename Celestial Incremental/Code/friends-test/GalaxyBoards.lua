-- GalaxyBoards (Galaxy Incremental): the LIVE island boards, like Regrowth's (owner, 2 Nov; vault "Boards like Regrowth").
-- Every owned island has two panels on its far edge (GalaxyMapService builds them): UPGRADES (left) and CONSTELLATION TREE
-- (right). Here each panel's screen gets a SurfaceGui in PlayerGui (Adornee = the panel, canvas 745 x 512, LightInfluence 0)
-- with the approved v12 window rebuilt 1:1 and LIVE: UpgradesPanel / TreePanel, the same modules as the 2D windows, the same
-- data (EconConfig + the island OWNER's attributes) and the same remote (EconRequest, + the island slot: the server checks the
-- owner and the distance). Visitors see the owner's numbers; their buttons are grey "VISIT".
--  * built only for your own island and islands within MapConfig.Boards.DrawRange (others are dropped again)
--  * the beacon on top of a panel shows only while something on it can be bought
--  * the frame edge's light runs round (rotating UIGradient); textures never move; icons never move
--  * the rows scroll (owner, boards fix 2: no pages): mouse wheel, touch and a mouse drag on the screen (the drag needs
--    the mouse ray projected onto the screen part: pointerFor). A refresh never resets where a list is scrolled to.
--  * shared.GalaxyBoardTarget(key) -> the world position of a button on YOUR Upgrades board (the tutorial arrow points there)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local UpgradesPanel = require(Galaxy:WaitForChild("UpgradesPanel"))
local TreePanel = require(Galaxy:WaitForChild("TreePanel"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local B = MapConfig.Boards

local root = workspace:WaitForChild("Galaxy", 60)
if not root then return end
local islands = root:WaitForChild("Islands")

local sound = Kit.sound

-- an island owner that isn't a Player (Studio test islands): no numbers
local NOBODY = { GetAttribute = function() return nil end }
local function partsOf(x: Instance): { BasePart }
	if x:IsA("BasePart") then return { x } end
	local list = {}
	for _, d in ipairs(x:GetDescendants()) do if d:IsA("BasePart") then table.insert(list, d) end end
	return list
end

local boards = {} -- [island] = { guis, panels = { Upgrades = panel, Tree = panel }, beacons, conns, subject }

-- a screen position (mouse / finger) -> the point on a board's canvas in pixels, or nil if it isn't on that screen
local function pointerFor(screen: BasePart)
	return function(pos: Vector2): Vector2?
		local cam = workspace.CurrentCamera
		if not cam or not screen.Parent then return nil end
		local ray = cam:ScreenPointToRay(pos.X, pos.Y)
		local cf = screen.CFrame
		local n = -cf.LookVector -- (the Back face, +Z, faces the island)
		local den = ray.Direction:Dot(n)
		if den > -1e-4 then return nil end
		local t = (cf.Position + n * (screen.Size.Z / 2) - ray.Origin):Dot(n) / den
		if t <= 0 then return nil end
		local p = cf:PointToObjectSpace(ray.Origin + ray.Direction * t)
		local u, v = p.X / screen.Size.X + 0.5, 0.5 - p.Y / screen.Size.Y
		if u < 0 or u > 1 or v < 0 or v > 1 then return nil end
		return Vector2.new(u * B.Canvas.X, v * B.Canvas.Y)
	end
end

local function clear(island)
	local b = boards[island]
	if not b then return end
	for _, c in ipairs(b.conns) do c:Disconnect() end
	for _, g in ipairs(b.guis) do g:Destroy() end
	for _, beacon in pairs(b.beacons) do
		for _, p in ipairs(partsOf(beacon)) do p.LocalTransparencyModifier = 0 end
	end
	boards[island] = nil
end

local function build(island)
	clear(island)
	local model = island:FindFirstChild("Boards")
	local ownerId = island:GetAttribute("Owner") or 0
	if not model or ownerId == 0 then return end
	local slot = island:GetAttribute("Slot")
	local subject = Players:GetPlayerByUserId(ownerId) or NOBODY
	local mine = subject == player
	local b = { guis = {}, panels = {}, beacons = {}, conns = {}, subject = subject }
	boards[island] = b
	for _, spec in ipairs(B.Panels) do
		local panelModel = model:FindFirstChild("Board_" .. spec.id)
		local screen = panelModel and panelModel:FindFirstChild("Screen")
		if not screen then continue end
		b.beacons[spec.id] = panelModel:FindFirstChild("Beacon")
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board_" .. spec.id .. "_" .. island.Name
		gui.Adornee = screen
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = B.Canvas
		gui.LightInfluence = 0
		gui.MaxDistance = B.DrawRange + 40
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.ClipsDescendants = true
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BorderSizePixel = 0
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		bg.Parent = gui
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = if spec.id == "Tree" then ColorSequence.new(Kit.hex("#0f2a16"), Kit.hex("#08100a")) else ColorSequence.new(Kit.hex("#3a1a0c"), Kit.hex("#120a08"))
		g.Parent = bg
		local opts = {
			subject = subject, origin = B.Window, chip = "SHARDS", close = false, edgeGlow = true, pointer = pointerFor(screen),
			canAct = function() return mine end,
			buy = function(kind, arg) return request:InvokeServer(kind, arg, slot) end,
			sound = sound,
		}
		b.panels[spec.id] = if spec.id == "Tree" then TreePanel.new(gui, opts) else UpgradesPanel.new(gui, opts)
		table.insert(b.guis, gui)
	end
	-- live numbers: the owner's attributes (Stardust changes every half second: refresh at most 4 times a second)
	local dirty = true
	local function mark() dirty = true end
	if subject ~= NOBODY then
		table.insert(b.conns, subject.AttributeChanged:Connect(mark))
	end
	b.mark = mark
	b.dirty = function()
		local d = dirty
		dirty = false
		return d
	end
end

local function wanted(island): boolean
	if (island:GetAttribute("Owner") or 0) == 0 or not island:FindFirstChild("Boards") then return false end
	if island:GetAttribute("Owner") == player.UserId then return true end
	local cam = workspace.CurrentCamera
	local c = island:GetAttribute("Center")
	return cam ~= nil and c ~= nil and (cam.CFrame.Position - c).Magnitude <= B.DrawRange
end

local function watch(island)
	if not island:IsA("Model") then return end
	island:GetAttributeChangedSignal("Owner"):Connect(function() clear(island) end)
	island.ChildAdded:Connect(function(c) if c.Name == "Boards" then clear(island) end end)
end
for _, island in ipairs(islands:GetChildren()) do watch(island) end
islands.ChildAdded:Connect(watch)

-- every frame: build / drop by distance, refresh the numbers, the edge glow, the beacons
local acc, accScan = 0, 0
RunService.RenderStepped:Connect(function(dt)
	accScan += dt
	if accScan > 0.5 then
		accScan = 0
		for _, island in ipairs(islands:GetChildren()) do
			local want = wanted(island)
			local b = boards[island]
			if want and (not b or not b.guis[1] or not b.guis[1].Adornee or not b.guis[1].Adornee.Parent) then
				build(island)
			elseif not want and b then
				clear(island)
			end
		end
	end
	acc += dt
	local doRefresh = acc > 0.25
	if doRefresh then acc = 0 end
	for _, b in pairs(boards) do
		for _, p in pairs(b.panels) do p:step(dt) end
		if doRefresh and b.dirty() then
			for id, p in pairs(b.panels) do
				p:refresh()
				-- the beacon: only while something on this panel can be bought (by its owner)
				local beacon = b.beacons[id]
				if beacon then
					local on = b.subject == player and (if id == "Tree" then p.buyKey ~= nil and p.buyKey:sub(1, 4) == "buy|" else p:anyBuyable())
					for _, part in ipairs(partsOf(beacon)) do part.LocalTransparencyModifier = if on then 0 else 1 end
				end
			end
		end
	end
end)

-- the tutorial: the world position of a button on YOUR Upgrades board (switches the board to the tab it's on)
shared.GalaxyBoardTarget = function(key: string, tab: string?): (Vector3?, Vector3?)
	for island, b in pairs(boards) do
		if island:GetAttribute("Owner") == player.UserId then
			local panel = b.panels.Upgrades
			if not panel then return nil end
			if tab and panel.currentTab ~= tab then panel:selectTab(tab) end
			local btn = panel.targets[key]
			panel:reveal(btn)
			local gui = b.guis[1]
			local screen = gui and gui.Adornee
			if not btn or not btn.Parent or not screen then return nil end
			local u = (btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2) / B.Canvas.X
			local v = (btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2) / B.Canvas.Y
			local topV = btn.AbsolutePosition.Y / B.Canvas.Y
			local face = screen.Size.Z / 2 + 0.05
			return (screen.CFrame * CFrame.new((u - 0.5) * screen.Size.X, (0.5 - v) * screen.Size.Y, face)).Position,
				(screen.CFrame * CFrame.new((u - 0.5) * screen.Size.X, (0.5 - topV) * screen.Size.Y, face)).Position
		end
	end
	return nil
end
