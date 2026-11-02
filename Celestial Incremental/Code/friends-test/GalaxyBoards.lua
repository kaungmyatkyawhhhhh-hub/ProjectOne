-- GalaxyBoards (Galaxy Incremental): the LIVE island boards, a 1:1 copy of Regrowth's (owner, 2 Nov; vault "Island boards
-- like Regrowth 1to1"). Every owned island has four (GalaxyMapService builds the frames, MapConfig.Boards places them):
-- CONSTELLATION TREE + INFO (the pair on the far edge), BODIES (left), STAR UPGRADES (right). Here each board's screen gets a
-- SurfaceGui in PlayerGui (Adornee = the screen, MapConfig.Boards.PxPerStud pixels a stud, LightInfluence 0) drawn by
-- IslandBoardsUI with the same data (EconConfig + the island OWNER's attributes) and the same remote (EconRequest + the
-- island slot: the server checks the owner and the distance) as the 2D Upgrades window. Visitors see the owner's numbers;
-- their buttons are grey "VISIT".
--  * INFO shows what you last tapped (a tree tile, a body row, a star card); until then the first node you can buy (all
--    bought: the Asteroid). After you buy the node it shows, it moves on to the next one.
--  * built only for your own island and islands within MapConfig.Boards.DrawRange (others are dropped again)
--  * lists scroll with the mouse wheel, a drag and touch (the drag needs the mouse ray projected onto the screen:
--    pointerFor); a refresh never moves a list
--  * shared.GalaxyBoardTarget(key) -> the world position of a button on YOUR BODIES board (the tutorial arrow points there)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local BoardsUI = require(Galaxy:WaitForChild("IslandBoardsUI"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local B = MapConfig.Boards

local root = workspace:WaitForChild("Galaxy", 60)
if not root then return end
local islands = root:WaitForChild("Islands")

-- an island owner that isn't a Player (Studio test islands): no numbers
local NOBODY = { GetAttribute = function() return nil end }

-- a screen position (mouse / finger) -> the point on a board's canvas in pixels, or nil if it isn't on that screen
local function pointerFor(screen: BasePart, canvas: Vector2)
	return function(pos: Vector2): Vector2?
		local cam = workspace.CurrentCamera
		if not cam or not screen.Parent then return nil end
		local ray = cam:ScreenPointToRay(pos.X, pos.Y)
		local cf = screen.CFrame
		local n = -cf.LookVector -- (the Back face, +Z, faces the player)
		local den = ray.Direction:Dot(n)
		if den > -1e-4 then return nil end
		local t = (cf.Position + n * (screen.Size.Z / 2) - ray.Origin):Dot(n) / den
		if t <= 0 then return nil end
		local p = cf:PointToObjectSpace(ray.Origin + ray.Direction * t)
		local u, v = p.X / screen.Size.X + 0.5, 0.5 - p.Y / screen.Size.Y
		if u < 0 or u > 1 or v < 0 or v > 1 then return nil end
		return Vector2.new(u * canvas.X, v * canvas.Y)
	end
end

local boards = {} -- [island] = { guis = { [id] = SurfaceGui }, panels = { [id] = board }, conns, ctx }

local function clear(island)
	local b = boards[island]
	if not b then return end
	for _, c in ipairs(b.conns) do c:Disconnect() end
	for _, g in pairs(b.guis) do g:Destroy() end
	boards[island] = nil
end

-- INFO's default: the first ring-1 node you can buy (Regrowth shows its first perk); all bought: the Asteroid
local function defaultSel(subject)
	for _, n in ipairs(Econ.Ring1) do
		local ready = not n.requires or subject:GetAttribute("Node_" .. n.requires) == true
		if ready and subject:GetAttribute("Node_" .. n.id) ~= true then return { kind = "node", key = n.id } end
	end
	return { kind = "body", key = 0 }
end

local function build(island)
	clear(island)
	local model = island:FindFirstChild("Boards")
	local ownerId = island:GetAttribute("Owner") or 0
	if not model or ownerId == 0 then return end
	local slot = island:GetAttribute("Slot")
	local subject = Players:GetPlayerByUserId(ownerId) or NOBODY
	local mine = subject == player
	local b = { guis = {}, panels = {}, conns = {} }
	boards[island] = b
	local dirty = true
	local ctx = { subject = subject, picked = false, sel = defaultSel(subject), sound = Kit.sound }
	ctx.canAct = function() return mine end
	ctx.buy = function(kind, arg) return request:InvokeServer(kind, arg, slot) end
	ctx.select = function(kind, key)
		ctx.sel = { kind = kind, key = key }
		ctx.picked = true
		for _, p in pairs(b.panels) do p:refresh() end
	end
	ctx.bought = function(kind, arg)
		if kind == "BuyNode" and ctx.sel.kind == "node" and ctx.sel.key == arg then ctx.picked = false end
		dirty = true
	end
	b.ctx = ctx
	for _, spec in ipairs(B.List) do
		local panelModel = model:FindFirstChild("Board_" .. spec.id)
		local screen = panelModel and panelModel:FindFirstChild("Screen")
		if not screen then continue end
		local canvas = Vector2.new(spec.Width, spec.Height) * B.PxPerStud
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board_" .. spec.id .. "_" .. island.Name
		gui.Adornee = screen
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = canvas
		gui.LightInfluence = 0
		gui.MaxDistance = B.DrawRange + 40
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.ClipsDescendants = true
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
		b.guis[spec.id] = gui
		-- (each board its own pointer + canvas; the rest is the island's shared ctx)
		b.panels[spec.id] = BoardsUI.new(spec.id, gui, spec, setmetatable({ pointer = pointerFor(screen, canvas), size = canvas }, { __index = ctx }))
	end
	-- live numbers: the owner's attributes (Stardust changes every half second: refresh at most 4 times a second)
	if subject ~= NOBODY then
		table.insert(b.conns, subject.AttributeChanged:Connect(function() dirty = true end))
	end
	b.dirty = function()
		local d = dirty
		dirty = false
		return d
	end
end

local function alive(b): boolean
	if not b or next(b.guis) == nil then return false end
	for _, g in pairs(b.guis) do
		if not g.Adornee or not g.Adornee.Parent then return false end
	end
	return true
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

-- every frame: build / drop by distance, the neon edges; the numbers at most 4 times a second
local acc, accScan = 0, 0
RunService.RenderStepped:Connect(function(dt)
	accScan += dt
	if accScan > 0.5 then
		accScan = 0
		for _, island in ipairs(islands:GetChildren()) do
			local want = wanted(island)
			if want and not alive(boards[island]) then
				build(island)
			elseif not want and boards[island] then
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
			if not b.ctx.picked then b.ctx.sel = defaultSel(b.ctx.subject) end
			for _, p in pairs(b.panels) do p:refresh() end
		end
	end
end)

-- the tutorial: the world position of a button on YOUR BODIES board (scrolls it into view first), the top of it, its
-- width / height
shared.GalaxyBoardTarget = function(key: string): (Vector3?, Vector3?, number?)
	for island, b in pairs(boards) do
		if island:GetAttribute("Owner") == player.UserId then
			local panel, gui = b.panels.Bodies, b.guis.Bodies
			local btn = panel and panel.targets[key]
			local screen = gui and gui.Adornee
			if not btn or not btn.Parent or not screen then return nil end
			panel:reveal(btn)
			local canvas = gui.CanvasSize
			local u = (btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2) / canvas.X
			local v = (btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2) / canvas.Y
			local topV = btn.AbsolutePosition.Y / canvas.Y
			local face = screen.Size.Z / 2 + 0.05
			return (screen.CFrame * CFrame.new((u - 0.5) * screen.Size.X, (0.5 - v) * screen.Size.Y, face)).Position,
				(screen.CFrame * CFrame.new((u - 0.5) * screen.Size.X, (0.5 - topV) * screen.Size.Y, face)).Position,
				btn.AbsoluteSize.X / math.max(1, btn.AbsoluteSize.Y)
		end
	end
	return nil
end
