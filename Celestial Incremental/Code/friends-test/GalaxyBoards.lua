-- GalaxyBoards (Galaxy Incremental): the LIVE island boards, a 1:1 copy of Regrowth's (owner, 2 Nov; vault "Island boards
-- like Regrowth 1to1"). Every owned island has four (GalaxyMapService builds the frames, MapConfig.Boards places them):
-- CONSTELLATION TREE + INFO (the pair on the far edge), BODIES (left), STAR UPGRADES (right). Here each board's screen gets a
-- SurfaceGui in PlayerGui (Adornee = the screen, MapConfig.Boards.PxPerStud pixels a stud, LightInfluence 0) drawn by
-- IslandBoardsUI with the same data (EconConfig + the island OWNER's attributes) and the same remote (EconRequest + the
-- island slot: the server checks the owner and the distance) as the 2D Upgrades window. Visitors see the owner's numbers;
-- their buttons are grey "VISIT".
--  * one job each (5 Nov, #219-#221): BODIES buys bodies, STAR UPGRADES buys ring 1, TREE selects a ring-2 node, INFO shows
--    the selected node and buys it ("Tap a node on the TREE" until you do; the selection stays after a buy)
--  * built only for your own island and islands within MapConfig.Boards.DrawRange (others are dropped again)
--  * lists scroll with the mouse wheel, a drag and touch (the drag needs the mouse ray projected onto the screen:
--    pointerFor); a refresh never moves a list
--  * shared.GalaxyBoardTarget(key) -> the world position of a button on YOUR BODIES board (the tutorial arrow points there)
--  * pass 2 (owner, "Boards 1to1 pass 2"): what spills OUTSIDE the screens is drawn here too, only for the boards built:
--    the pair's huge titles over the top frame edge, a glow halo behind the pair's frames and their crackling energy beams
--    along the frame, Star Upgrades' flame strip (small flames + a glow line, gold + violet, hugging its frame). Bodies' neon tubes glow by themselves
--    (a rectangular halo showed square corners round the other boards). Reduced Motion: no crackle.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local BoardsUI = require(Galaxy:WaitForChild("IslandBoardsUI"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: no board taps while a 2D window is open)
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

-- TOUCH (owner 5 Nov): on a phone / tablet the boards' small buttons are hard to hit from the spawn camera, so a TAP on any
-- of YOUR boards opens its 2D window instead (TREE / INFO -> the T window, BODIES -> U on BODIES, PERKS -> U on PERKS).
-- Studio: Workspace TestPhone = true makes a mouse click a tap.
local TOUCH = UserInputService.TouchEnabled or (RunService:IsStudio() and (workspace:GetAttribute("TestPhone") == true or (workspace:GetAttribute("TestDevice") ~= nil and workspace:GetAttribute("TestDevice") ~= "pc")))

local boards = {} -- [island] = { guis = { [id] = SurfaceGui }, panels = { [id] = board }, conns, ctx, fx = { { parts, step } } }

local function clear(island)
	local b = boards[island]
	if not b then return end
	for _, c in ipairs(b.conns) do c:Disconnect() end
	for _, g in pairs(b.guis) do g:Destroy() end
	for _, f in ipairs(b.fx or {}) do
		for _, p in ipairs(f.parts) do p:Destroy() end
	end
	boards[island] = nil
end

------------------------------------------------------------------------ what spills outside the screens (pass 2)
local fxFolder = Instance.new("Folder")
fxFolder.Name = "GalaxyBoardFx"
fxFolder.Parent = workspace
local Fx = require(Galaxy:WaitForChild("BoardsFx")) -- (7 Nov: the fx, outline + decorate live there, shared with Tools/BoardPreview)
local function fxPart(name: string, size: Vector3, cf: CFrame): Part return Fx.part(fxFolder, name, size, cf) end
local function decorate(spec, screen: BasePart) return Fx.decorate(spec, screen, fxFolder) end

-- INFO's default: nothing selected ("Tap a node on the TREE"; the Supernova lives on the HUD button and its card)
local function defaultSel(_subject)
	return { kind = "none" }
end

local function build(island)
	clear(island)
	local model = island:FindFirstChild("Boards")
	local ownerId = island:GetAttribute("Owner") or 0
	if not model or ownerId == 0 then return end
	local slot = island:GetAttribute("Slot")
	local subject = Players:GetPlayerByUserId(ownerId) or NOBODY
	local mine = subject == player
	local b = { guis = {}, panels = {}, conns = {}, fx = {} }
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
		dirty = true
		-- (#284: the TREE board celebrates a node bought from INFO)
		for _, p in pairs(b.panels) do p:celebrate(kind, arg) end
	end
	b.ctx = ctx
	for _, spec in ipairs(B.List) do
		local panelModel = model:FindFirstChild("Board_" .. spec.id)
		local screen = panelModel and panelModel:FindFirstChild("Screen")
		if not screen then continue end
		local canvas = Vector2.new(spec.Width, spec.Height) * (spec.Px or B.PxPerStud)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Board_" .. spec.id .. "_" .. island.Name
		gui.Adornee = screen
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		gui.CanvasSize = canvas
		gui.LightInfluence = 0
		gui.Brightness = B.Brightness
		gui.MaxDistance = B.DrawRange + 40
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.ClipsDescendants = true
		gui.ResetOnSpawn = false
		-- (touch devices: the board is the 3D look only; a tap opens its 2D window, below)
		gui.Active = not TOUCH
		gui.Parent = playerGui
		b.guis[spec.id] = gui
		-- (each board its own pointer + canvas; the rest is the island's shared ctx)
		b.panels[spec.id] = BoardsUI.new(spec.id, gui, spec, setmetatable({ pointer = pointerFor(screen, canvas), size = canvas, world = true }, { __index = ctx }))
		table.insert(b.fx, decorate(spec, screen))
		-- (#214, Phase 2.7: on YOUR boards a BEACON over the top lights up while something on it can be bought; Info has none)
		if mine and spec.id ~= "Info" then
			local up = screen.CFrame.UpVector
			local top = screen.Position + up * (screen.Size.Y / 2 + (if spec.pair then 4.2 else 2.2))
			local beam = fxPart("Beacon", Vector3.new(6, 0.6, 0.6), CFrame.new(top + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90)))
			beam.Shape = Enum.PartType.Cylinder
			beam.Material = Enum.Material.Neon
			beam.Color = spec.Neon or Color3.fromRGB(255, 220, 120)
			local orb = fxPart("BeaconOrb", Vector3.new(1.4, 1.4, 1.4), CFrame.new(top + Vector3.new(0, 6.4, 0)))
			orb.Shape = Enum.PartType.Ball
			orb.Material = Enum.Material.Neon
			orb.Color = beam.Color
			b.beacons = b.beacons or {}
			b.beacons[spec.id] = { beam = beam, orb = orb, on = false }
			table.insert(b.fx, { parts = { beam, orb }, step = function() end })
		end
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
		for _, f in ipairs(b.fx) do f.step(dt) end
		if doRefresh and b.dirty() then
			if not b.ctx.picked then b.ctx.sel = defaultSel(b.ctx.subject) end
			for _, p in pairs(b.panels) do p:refresh() end
			for id, bc in pairs(b.beacons or {}) do bc.on = b.panels[id] ~= nil and b.panels[id]:buyable() end
		end
		-- (the beacons breathe while lit; off = gone. Reduced Motion: steady)
		for _, bc in pairs(b.beacons or {}) do
			local a = if not bc.on then 1 elseif Kit.calm() then 0.3 else 0.3 + 0.25 * math.sin(os.clock() * 3)
			bc.beam.Transparency = a
			bc.orb.Transparency = if bc.on then a * 0.6 else 1
		end
	end
end)

-- the tutorial: the world position of a button on one of YOUR boards (scrolls it into view first), the top of it, its
-- width / height. key: "Body<k>" (BODIES), "Perk_<id>" (PERKS), "R2_<id>" (TREE; once that node is selected:
-- INFO's BUY)
-- (7 Nov: + the face's outward normal, so the guide's floor trail can end at the spot IN FRONT of the board)
shared.GalaxyBoardTarget = function(key: string): (Vector3?, Vector3?, number?, Vector3?)
	for island, b in pairs(boards) do
		if island:GetAttribute("Owner") == player.UserId then
			local boardId = if key:sub(1, 5) == "Perk_" then "Stars" elseif key:sub(1, 3) == "R2_" then "Tree" else "Bodies"
			if boardId == "Tree" and b.ctx.sel.kind == "node2" and "R2_" .. b.ctx.sel.key == key then
				boardId, key = "Info", "Buy"
			end
			local panel, gui = b.panels[boardId], b.guis[boardId]
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
				btn.AbsoluteSize.X / math.max(1, btn.AbsoluteSize.Y), screen.CFrame.ZVector
		end
	end
	return nil
end

-- the TAP (touch devices): a short press that barely moved, not on a 2D button -> a ray from the camera; the board it hits
-- (on YOUR island) opens its window through Galaxy.OpenWindow (GalaxyHUD)
if TOUCH then
	local opener = ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("OpenWindow", 30)
	local WINDOW = { Tree = { "Tree" }, Info = { "Tree" }, Bodies = { "Upgrades", "BODIES" }, Stars = { "Upgrades", "PERKS" }, ForgeLock = { "Forge" },
		BlackHoleLock = { "BlackHole" } }
	local downAt, downPos
	local function isTap(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.Touch
			or (input.UserInputType == Enum.UserInputType.MouseButton1 and RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not isTap(input) then return end
		downAt, downPos = os.clock(), input.Position
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		if processed or not isTap(input) or not downAt then return end
		local quick = os.clock() - downAt < 0.45 and (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(downPos.X, downPos.Y)).Magnitude < 14
		downAt = nil
		-- (7 Nov: while a 2D window is open, a tap never reaches the world: it's for the window)
		if not quick or shared.GalaxyCinematic or not opener or WM.anyOpen() then return end
		local mine
		for island in pairs(boards) do
			if island:GetAttribute("Owner") == player.UserId then mine = island:FindFirstChild("Boards") end
		end
		if not mine then return end
		local cam = workspace.CurrentCamera
		local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { mine }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 250, params)
		local node = hit and hit.Instance
		while node and node ~= mine and not (node:IsA("Model") and node:GetAttribute("Board")) do node = node.Parent end
		local id = node and node ~= mine and node:GetAttribute("Board")
		local w = id and WINDOW[id]
		if w then
			Kit.sound("open")
			opener:Fire(w[1], w[2], node:GetPivot().Position)
		end
	end)
end
