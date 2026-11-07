--[[ BoardPreview (Galaxy Incremental, 7 Nov): see the boards' real DESIGN in Edit mode, without pressing Play.

In the Command Bar:   require(game.ServerStorage.Tools.BoardPreview)()      -- run again to switch it off

What it draws (the same code the game uses: PlazaBoardsUI, IslandBoardsUI, BoardsFx, GalaxyMapBuilder.IslandBoards):
  - the plaza: FREE REWARDS, TOP SUPERNOVAS (both faces) and PLAYERS NEAR YOU, with sample rows;
  - one sample island (Island_1 by default, or opts.island = n) as a NEW player sees it: the lit rock + walkway, and all its
    boards (BODIES, PERKS, CONSTELLATION TREE, INFO) with their frames, titles, glow and flames.

Safe: everything lives in Workspace.GalaxyPreview, which is Archivable = false: it is never saved, never published and never
copied into Play. While it's on, the island's Edit rock is hidden (LocalTransparencyModifier, not saved) and the two
leaderboards' plain Edit text is switched off (the game switches it back on by itself); switching the preview off undoes both. Move the real boards as usual, then run it twice (off, on) to redraw.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FOLDER = "GalaxyPreview"

-- a fresh copy of a module (Studio keeps a required module's first result: a clone picks up your latest edits)
local function fresh(m: ModuleScript)
	local c = m:Clone()
	local ok, res = pcall(require, c)
	if not ok then error("BoardPreview: " .. m:GetFullName() .. " failed: " .. tostring(res)) end
	return res
end

local function clear(): boolean
	local f = workspace:FindFirstChild(FOLDER)
	if not f then return false end
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("BasePart") and p:GetAttribute("PreviewHidden") then
			p.LocalTransparencyModifier = 0
			p:SetAttribute("PreviewHidden", nil)
		elseif p:IsA("SurfaceGui") and p:GetAttribute("PreviewDisabled") then
			p.Enabled = true
			p:SetAttribute("PreviewDisabled", nil)
		end
	end
	f:Destroy()
	return true
end

local function surfaceLike(src: SurfaceGui, adornee: BasePart, parent: Instance): SurfaceGui
	local g = Instance.new("SurfaceGui")
	g.Name = "Preview_" .. src.Name
	g.Adornee = adornee
	g.Face = src.Face
	g.SizingMode = src.SizingMode
	g.CanvasSize = src.CanvasSize
	g.PixelsPerStud = src.PixelsPerStud
	g.LightInfluence = 0
	g.Parent = parent
	-- the plain Edit board under it: off while the preview is on (as the game hides it); back on when it's off. (If the place
	-- is saved with the preview on, the game switches it on again anyway: PlazaBoardsUI.plaque)
	if src.Enabled then
		src.Enabled = false
		src:SetAttribute("PreviewDisabled", true)
	end
	-- (the game makes the screen part see-through and drops its brass edge (MapService, rule 8 ONE FRAME): hidden here too)
	local model = adornee.Parent
	for _, p in ipairs({ adornee, model and model:FindFirstChild(adornee.Name == "Wall" and "WallEdge" or "BoardEdge") }) do
		if p and p:IsA("BasePart") and p.Transparency < 1 then
			p.LocalTransparencyModifier = 1
			p:SetAttribute("PreviewHidden", true)
		end
	end
	return g
end

local SAMPLE_NAMES = { "StarFox", "NovaKid", "Comet_Rider", "LunaBeam", "AstroAce", "OrbitQueen", "Pulsar77", "DustDevil", "SolarFlare", "VoidWalker", "Meteorite" }

local function preview(opts)
	opts = opts or {}
	if clear() then return "BoardPreview OFF (Workspace.GalaxyPreview removed)" end
	local G = workspace:FindFirstChild("Galaxy")
	if not G then return "BoardPreview: no Workspace.Galaxy" end
	local Gal = ReplicatedStorage:WaitForChild("Galaxy")
	local MapConfig = fresh(Gal.MapConfig)
	local Plaza = fresh(Gal.PlazaBoardsUI)
	local BoardsUI = fresh(Gal.IslandBoardsUI)
	local Fx = fresh(Gal.BoardsFx)
	local Builder = fresh(ServerStorage.GalaxyMapBuilder)

	local folder = Instance.new("Folder")
	folder.Name = FOLDER
	folder.Archivable = false
	folder.Parent = workspace
	local out = {}

	------------------------------------------------------------------ the plaza
	local centre = G:FindFirstChild("Centre")
	local fb = centre and centre:FindFirstChild("FreeBoard")
	local screen = fb and fb:FindFirstChild("Screen")
	if screen then
		Plaza.freeBoard(screen, folder)
		table.insert(out, "FREE REWARDS")
	end
	local wall = centre and centre:FindFirstChild("Leaderboard") and centre.Leaderboard:FindFirstChild("Wall")
	if wall then
		local entries = {}
		for i = 1, 10 do entries[i] = { u = 0, name = SAMPLE_NAMES[i], value = 120 - i * 11 } end
		for _, src in ipairs(wall:GetChildren()) do
			if src:IsA("SurfaceGui") then
				local g = surfaceLike(src, wall, folder)
				local list = Plaza.plaque(g, "TOP SUPERNOVAS", false)
				if list then Plaza.fill(list, entries, 2, 5) end
			end
		end
		table.insert(out, "TOP SUPERNOVAS")
	end
	local nb = centre and centre:FindFirstChild("NearBoard") and centre.NearBoard:FindFirstChild("Board")
	if nb then
		local rows = MapConfig.NearBoard.Rows
		local entries = {}
		for i = 1, rows do entries[i] = { u = 0, name = if i == 6 then "You" else SAMPLE_NAMES[i], value = 40 - i * 3, you = i == 6, rank = 4, noNum = true } end
		for _, src in ipairs(nb:GetChildren()) do
			if src:IsA("SurfaceGui") then
				local g = surfaceLike(src, nb, folder)
				local list = Plaza.plaque(g, "PLAYERS NEAR YOU", true)
				if list then Plaza.fill(list, entries, 1, rows) end
			end
		end
		table.insert(out, "PLAYERS NEAR YOU")
	end

	------------------------------------------------------------------ one sample island, as a new player's
	local slot = opts.island or 1
	local island = G:FindFirstChild("Islands") and G.Islands:FindFirstChild("Island_" .. slot)
	if island and island:GetAttribute("Center") then
		local c = island:GetAttribute("Center")
		local a = island:GetAttribute("Angle")
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		-- the owned (lit) rock + walkway in place of the Edit's dim free-slot rock (hidden, not changed)
		local pieces = island:FindFirstChild("Pieces")
		if pieces then
			for _, p in ipairs(pieces:GetDescendants()) do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = 1
					p:SetAttribute("PreviewHidden", true)
				end
			end
			folder:SetAttribute("Hidden", true)
		end
		local rock = Builder.RockPieces(island, c, dir, slot, true)
		rock.Parent = folder
		local boards = Builder.IslandBoards(island, folder)
		local fxFolder = Instance.new("Folder")
		fxFolder.Name = "BoardFx"
		fxFolder.Parent = folder
		local B = MapConfig.Boards
		local nobody = { GetAttribute = function() return nil end }
		local ctx = { subject = nobody, picked = false, sel = { kind = "none" }, sound = function() end }
		ctx.canAct = function() return true end
		ctx.buy = function() return false end
		ctx.select = function() end
		ctx.bought = function() end
		local drawn = 0
		for _, spec in ipairs(B.List) do
			local panel = boards:FindFirstChild("Board_" .. spec.id)
			local scr = panel and panel:FindFirstChild("Screen")
			if scr then
				local canvas = Vector2.new(spec.Width, spec.Height) * (spec.Px or B.PxPerStud)
				local gui = Instance.new("SurfaceGui")
				gui.Name = "Board_" .. spec.id
				gui.Adornee = scr
				gui.Face = Enum.NormalId.Back
				gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
				gui.CanvasSize = canvas
				gui.LightInfluence = 0
				gui.Brightness = B.Brightness
				gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				gui.ClipsDescendants = true
				gui.Parent = folder
				local ok, p = pcall(function()
					return BoardsUI.new(spec.id, gui, spec, setmetatable({ pointer = function() return nil end, size = canvas, world = true }, { __index = ctx }))
				end)
				if ok and p then
					pcall(function() p:refresh() end)
					drawn += 1
				else
					warn("BoardPreview: board " .. spec.id .. ": " .. tostring(p))
				end
				Fx.decorate(spec, scr, fxFolder)
			end
		end
		table.insert(out, "Island_" .. slot .. " (" .. drawn .. " boards)")
	end
	return "BoardPreview ON: " .. table.concat(out, ", ") .. ". Run it again to switch it off."
end

return preview
