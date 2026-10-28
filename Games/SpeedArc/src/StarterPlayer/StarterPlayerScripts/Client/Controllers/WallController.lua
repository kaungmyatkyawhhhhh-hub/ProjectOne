-- WallController (28 Oct pivot, prompt 11): the wall course on your screen. Walls are solid for
-- everyone; your own client opens the next wall when you run into it with enough SPEED.
-- The next wall shows live how close you are ("214 / 420", a bar, "about 40 more steps"), cracks
-- when you're close, glowing edges + SMASH IT! when you have enough. SMASH = chunky pooled pieces,
-- a camera kick + FOV punch, a layered sound, the crowd cheers, "+X COINS" flies to the counter (a
-- bigger moment the first time ever). Too slow = a soft bounce. A strip under the SPEED panel shows
-- walls 1-10 while you're on the course. Walls are Models "Wall<k>" in <Area>.Course (builder_lib L.course).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Config.Areas)
local Course = require(Shared.Config.Course)
local Palette = require(Shared.Config.Palette)
local UIKit = require(Shared.UIKit)
local Formulas = require(Shared.Util.Formulas)
local Format = require(Shared.Util.Format)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Wall = {}

local CHECK = 0.08
local PIECES = 24
local CLOSE = 0.7 -- cracks show from 70% of the need

local ctx
local walls = {} -- [index] = { model, parts = { {part, solid} }, block, glow = {}, guis = {}, need, open, ready, color }
local wallsArea = nil
local opened = {} -- [index] = true: opened by you in this run
local pool = {}
local lastBounce = 0
local strip, stripCells = nil, {}
local shakeUntil, shakeAmp = 0, 0

----------------------------------------------------------------------------
-- pieces, camera kick
----------------------------------------------------------------------------
local function makePool()
	local folder = Instance.new("Folder")
	folder.Name = "WallPieces"
	folder.Parent = workspace
	for i = 1, PIECES do
		local p = Instance.new("Part")
		p.Name = "Piece"
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Size = Vector3.new(3, 3, 1.4)
		p.CFrame = CFrame.new(0, -500, 0)
		p.Parent = folder
		pool[i] = p
	end
end

local function burst(w, dir, big)
	local cf = w.block.CFrame
	local size = w.block.Size
	local n = if big then PIECES else math.floor(PIECES * 0.65)
	for i = 1, n do
		local p = pool[i]
		local x = (math.random() - 0.5) * size.X * 0.9
		local y = math.random() * size.Y * 0.9 - size.Y * 0.45
		p.Color = w.color:Lerp(Palette.White, math.random() * 0.35)
		local s = if big then 2.4 + math.random() * 2.6 else 1.8 + math.random() * 2.2
		p.Size = Vector3.new(s, s * (0.7 + math.random() * 0.6), 1.4)
		p.CFrame = cf * CFrame.new(x, y, 0) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
		p.Anchored = false
		p.AssemblyLinearVelocity = dir * (35 + math.random() * 45) + Vector3.new((math.random() - 0.5) * 50, 22 + math.random() * 34, (math.random() - 0.5) * 50)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 12, math.random() * 12, math.random() * 12)
		task.delay(1.5 + i * 0.01, function()
			p.Anchored = true
			p.CFrame = CFrame.new(0, -500, 0)
		end)
	end
end

local function kick(big)
	if ctx.Settings and ctx.Settings.reduced and ctx.Settings.reduced() then
		return
	end
	shakeUntil = os.clock() + (if big then 0.45 else 0.3)
	shakeAmp = if big then 0.9 else 0.55
	local base = camera.FieldOfView
	camera.FieldOfView = base + (if big then 12 else 8)
	TweenService:Create(camera, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base }):Play()
end

----------------------------------------------------------------------------
-- walls in your area
----------------------------------------------------------------------------
local function setOpen(w, open)
	if w.open == open then
		return
	end
	w.open = open
	for _, e in w.parts do
		e[1].LocalTransparencyModifier = if open then 1 else 0
		e[1].CanCollide = if open then false else e[2]
	end
	for _, g in w.guis do
		g.gui.Enabled = not open
	end
	if open then
		for _, g in w.glow do
			g.Transparency = 1
		end
	end
end

local function collect(area)
	table.clear(walls)
	wallsArea = area
	local def = Areas[area]
	local model = def and workspace:FindFirstChild(def.Model)
	local course = model and model:FindFirstChild("Course")
	if not course then
		return
	end
	for _, m in course:GetChildren() do
		local k = m:GetAttribute("Index")
		if k and m:IsA("Model") then
			local w = { model = m, parts = {}, glow = {}, guis = {}, open = nil, ready = nil, live = nil, need = Formulas.wallNeed(m:GetAttribute("League") or def.League, k) }
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					-- remember the built collision once (an opened wall has CanCollide off locally)
					if d:GetAttribute("WallSolid") == nil then
						d:SetAttribute("WallSolid", d.CanCollide)
					end
					table.insert(w.parts, { d, d:GetAttribute("WallSolid") })
					if d.Name == "Block" then
						w.block = d
						w.color = d.Color
					elseif d.Name == "Glow" then
						table.insert(w.glow, d)
					end
				elseif d:IsA("SurfaceGui") and d.Name == "WallGui" then
					table.insert(w.guis, { gui = d, bar = d:FindFirstChild("Bar"), have = d:FindFirstChild("Have"), cracks = d:FindFirstChild("Cracks"), sub = d:FindFirstChild("Sub") })
				end
			end
			if w.block then
				walls[k] = w
			end
		end
	end
end

-- the next wall's face: progress, cracks, glow
local function updateFace(w, speed, isNext)
	local frac = math.clamp(speed / w.need, 0, 1)
	local ready = speed >= w.need
	if not isNext then
		if w.live ~= false then
			w.live = false
			w.ready = nil
			for _, g in w.guis do
				g.bar.Visible = false
				g.have.Visible = false
				g.cracks.Visible = false
				g.sub.Text = "SPEED NEEDED"
				g.sub.TextColor3 = Palette.White
			end
			for _, gl in w.glow do
				gl.Transparency = 1
			end
		end
		return
	end
	w.live = true
	local gain = player:GetAttribute("StepGain") or 1
	local steps = math.max(1, math.ceil((w.need - speed) / math.max(gain, 0.001)))
	for _, g in w.guis do
		g.bar.Visible = true
		g.bar.Fill.Size = UDim2.fromScale(frac, 1)
		g.have.Visible = true
		g.have.Text = if ready then "YOU HAVE ENOUGH!" else ("%s / %s   -   about %s more steps"):format(Format.short(speed), Format.short(w.need), Format.short(steps))
		g.cracks.Visible = frac >= CLOSE and not ready
		g.sub.Text = if ready then "SMASH IT!" else "SPEED NEEDED"
		g.sub.TextColor3 = if ready then Color3.fromHex("#7ED957") else Palette.White
	end
	if ready ~= w.ready then
		w.ready = ready
		for _, gl in w.glow do
			gl.Transparency = if ready then 0.1 else 1
		end
	end
end

----------------------------------------------------------------------------
-- the strip: walls 1-10 under the SPEED panel while you're on the course
----------------------------------------------------------------------------
local function buildStrip()
	local n = Formulas.wallCount()
	strip = UIKit.make("Frame", { Name = "WallStrip", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 100), Size = UDim2.fromOffset(n * 30, 26), Visible = false, Parent = ctx.Hud.canvas })
	UIKit.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = strip })
	for k = 1, n do
		local col = Color3.fromHex(Course.Colors[(k - 1) % #Course.Colors + 1])
		-- a small kit tile in the wall's colour; a ring marks the next wall (white) and your best (gold)
		local cell = UIKit.tile({ Name = "Wall" .. k, Color = col, Size = UDim2.fromOffset(26, 26), Parent = strip })
		cell.LayoutOrder = k
		local ring = UIKit.make("Frame", { Name = "Ring", BackgroundTransparency = 1, Position = UDim2.fromOffset(-2, -2), Size = UDim2.new(1, 4, 1, 4), Visible = false, Parent = cell })
		UIKit.corner(ring, 9)
		local stroke = UIKit.stroke(ring, Palette.White, 2, 0)
		local label = UIKit.text({ Text = tostring(k), TextSize = 14, StrokeColor = Palette.Navy, StrokeThickness = 2, StrokeTransparency = 0, ZIndex = 2, Parent = cell })
		stripCells[k] = { cell = cell, ring = ring, stroke = stroke, label = label, color = col }
	end
end

local function updateStrip(onCourse, stage)
	strip.Visible = onCourse
	if not onCourse then
		return
	end
	local best = player:GetAttribute("BestWall") or 0
	for k, c in stripCells do
		local passed = k <= stage
		c.cell.ImageTransparency = if passed then 0 else 0.45
		c.ring.Visible = k == best or k == stage + 1
		c.stroke.Color = if k == best then Palette.Gold else Palette.White
		c.stroke.Thickness = 3
		c.label.TextColor3 = if k == best then Palette.Gold else Palette.White
	end
end

----------------------------------------------------------------------------
local function tick()
	local area = player:GetAttribute("Area") or "Hub"
	if area ~= wallsArea then
		collect(area)
	end
	local c = Course.Areas[area]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not c or not root then
		updateStrip(false, 0)
		return
	end
	local stage = player:GetAttribute("RunStage") or 0
	local speed = player:GetAttribute("Speed") or 0
	local rel = root.Position - c.Start
	local along = rel:Dot(c.Dir)
	local side = rel - c.Dir * along
	local onCourse = along > -12 and Vector3.new(side.X, 0, side.Z).Magnitude < Course.Width / 2 + 10 and along < Formulas.wallCount() * Course.StageLength + 50
	updateStrip(onCourse and not player:GetAttribute("InRace"), stage)
	for k, w in walls do
		local open = k <= stage or opened[k] == true
		setOpen(w, open)
		if not open then
			updateFace(w, speed, k == stage + 1)
			local gap = k * Course.StageLength - along
			-- only the next wall of this run can be smashed (the server pays them in order)
			if k == stage + 1 and gap > -2 and gap < 9 then
				if speed >= w.need then
					opened[k] = true
					setOpen(w, true)
					burst(w, c.Dir, false)
					kick(false)
					ctx.Sound.play("WallSmash")
					if ctx.WorldLife then
						ctx.WorldLife.cheer(2.5, area)
					end
				elseif gap < 3.6 and os.clock() - lastBounce > 0.6 then
					-- a soft bounce: back a little, never a fling
					lastBounce = os.clock()
					root.AssemblyLinearVelocity = -c.Dir * Course.BounceSpeed + Vector3.new(0, 10, 0)
					ctx.Sound.play("WallBounce")
				end
			end
		end
	end
end

function Wall.start(c)
	ctx = c
	makePool()
	buildStrip()
	player:GetAttributeChangedSignal("RunStage"):Connect(function()
		if (player:GetAttribute("RunStage") or 0) == 0 then
			table.clear(opened) -- a new run: every wall stands again
		end
	end)
	ctx.Net.get("WallEvent").OnClientEvent:Connect(function(kind, info)
		if kind ~= "smash" then
			return
		end
		-- the server confirmed: coins fly to the counter (a bigger moment the first time ever)
		local w = walls[info.Index]
		if info.First then
			ctx.Hud.popup(("FIRST SMASH!  +%s COINS"):format(Format.short(info.Coins)), Palette.Gold)
			ctx.Hud.coinFly(8)
			ctx.Sound.play("CoinShower")
			kick(true)
			if w then
				burst(w, (Course.Areas[wallsArea or "Hub"] or Course.Areas.Hub).Dir, true)
			end
		else
			ctx.Hud.popup("+" .. Format.short(info.Coins) .. " COINS", Palette.Gold)
			ctx.Hud.coinFly(4)
			ctx.Sound.play("Coins")
		end
		if info.Last then
			ctx.Hud.toast("LAST WALL SMASHED!  GO PRO is ready", "Unlock")
		end
	end)
	-- the course can stream in late / be rebuilt in Studio: look again now and then
	task.spawn(function()
		while true do
			task.wait(5)
			wallsArea = nil
		end
	end)
	-- the camera kick runs after the camera moved
	RunService:BindToRenderStep("SpeedArcWallKick", Enum.RenderPriority.Camera.Value + 1, function()
		local left = shakeUntil - os.clock()
		if left > 0 then
			local a = shakeAmp * math.min(1, left * 3)
			camera.CFrame = camera.CFrame * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0) * CFrame.Angles(0, 0, (math.random() - 0.5) * a * 0.02)
		end
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < CHECK then
			return
		end
		acc = 0
		tick()
	end)
end

return Wall
