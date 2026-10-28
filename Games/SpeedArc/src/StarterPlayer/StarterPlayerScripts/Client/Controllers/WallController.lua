-- WallController (28 Oct pivot): the wall course on your screen. Walls are solid for everyone; your
-- own client opens a wall you're fast enough for when you run into it (SMASH: it bursts into pooled
-- pieces, a layered sound, the coins popup when the server confirms). Too slow = you bounce back
-- and see how much SPEED is missing. Back behind the start (RunStage 0) = every wall stands again.
-- Walls are Models "Wall<k>" in <Area>.Course with attributes Index / League (tools/build_hub.luau).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Config.Areas)
local Course = require(Shared.Config.Course)
local Palette = require(Shared.Config.Palette)
local Formulas = require(Shared.Util.Formulas)
local Format = require(Shared.Util.Format)

local player = Players.LocalPlayer

local Wall = {}

local CHECK = 0.08
local PIECES = 16

local ctx
local walls = {} -- [index] = { model, parts = { {part, collide} }, block, need, sub, broken, ready }
local wallsArea = nil
local opened = {} -- [index] = true: opened by you in this run
local pool = {}
local lastBounce = 0

local function makePool()
	local folder = Instance.new("Folder")
	folder.Name = "WallPieces"
	folder.Parent = workspace
	for i = 1, PIECES do
		local p = Instance.new("Part")
		p.Name = "Piece"
		p.Size = Vector3.new(3, 3, 1.2)
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.CFrame = CFrame.new(0, -500, 0)
		p.Parent = folder
		pool[i] = p
	end
end

local function burst(w, dir)
	local block = w.block
	if not block then
		return
	end
	local cf = block.CFrame
	local size = block.Size
	for i, p in pool do
		local x = (math.random() - 0.5) * size.X * 0.9
		local y = math.random() * size.Y * 0.9 - size.Y * 0.45
		p.Color = block.Color:Lerp(Palette.White, math.random() * 0.3)
		p.Size = Vector3.new(1.5 + math.random() * 2.5, 1.5 + math.random() * 2.5, 1)
		p.CFrame = cf * CFrame.new(x, y, 0) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
		p.Anchored = false
		p.AssemblyLinearVelocity = dir * (40 + math.random() * 40) + Vector3.new((math.random() - 0.5) * 40, 25 + math.random() * 30, (math.random() - 0.5) * 40)
		p.AssemblyAngularVelocity = Vector3.new(math.random() * 10, math.random() * 10, math.random() * 10)
		task.delay(1.4 + i * 0.01, function()
			p.Anchored = true
			p.CFrame = CFrame.new(0, -500, 0)
		end)
	end
end

local function setOpen(w, open)
	if w.broken == open then
		return
	end
	w.broken = open
	for _, e in w.parts do
		e[1].LocalTransparencyModifier = if open then 1 else 0
		e[1].CanCollide = if open then false else e[2]
	end
	for _, g in w.guis do
		g.Enabled = not open
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
			local w = { model = m, parts = {}, guis = {}, broken = nil, ready = nil, need = Formulas.wallNeed(m:GetAttribute("League") or def.League, k) }
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					-- remember the built collision once (an opened wall has CanCollide off locally)
					if d:GetAttribute("WallSolid") == nil then
						d:SetAttribute("WallSolid", d.CanCollide)
					end
					table.insert(w.parts, { d, d:GetAttribute("WallSolid") })
					if d.Name == "Block" then
						w.block = d
					end
				elseif d:IsA("SurfaceGui") then
					table.insert(w.guis, d)
				elseif d:IsA("TextLabel") and d.Name == "Sub" then
					w.subs = w.subs or {}
					table.insert(w.subs, d)
				end
			end
			walls[k] = w
		end
	end
end

local function refreshReady(w, speed)
	local ready = speed >= w.need
	if ready == w.ready then
		return
	end
	w.ready = ready
	for _, l in w.subs or {} do
		l.Text = if ready then "SMASH IT!" else "SPEED NEEDED"
		l.TextColor3 = if ready then Color3.fromHex("#7ED957") else Palette.White
	end
end

local function tick()
	local area = player:GetAttribute("Area") or "Hub"
	if area ~= wallsArea then
		collect(area)
	end
	local c = Course.Areas[area]
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not c or not root then
		return
	end
	local stage = player:GetAttribute("RunStage") or 0
	local speed = player:GetAttribute("Speed") or 0
	local rel = root.Position - c.Start
	local along = rel:Dot(c.Dir)
	for k, w in walls do
		local open = k <= stage or opened[k] == true
		setOpen(w, open)
		if not open then
			refreshReady(w, speed)
			local wallAt = k * Course.StageLength
			local gap = wallAt - along
			-- only the next wall of this run can be smashed (the server pays them in order)
			if k == stage + 1 and gap > -2 and gap < 9 then
				if speed >= w.need then
					opened[k] = true
					setOpen(w, true)
					burst(w, c.Dir)
					ctx.Sound.play("WallSmash")
				elseif gap < 3.6 and os.clock() - lastBounce > 0.6 then
					lastBounce = os.clock()
					root.AssemblyLinearVelocity = -c.Dir * Course.BounceSpeed + Vector3.new(0, 22, 0)
					ctx.Sound.play("WallBounce")
					ctx.Net.get("WallEvent"):FireServer("bounce", k)
				end
			end
		end
	end
end

function Wall.start(c)
	ctx = c
	makePool()
	player:GetAttributeChangedSignal("RunStage"):Connect(function()
		if (player:GetAttribute("RunStage") or 0) == 0 then
			table.clear(opened) -- a new run: every wall stands again
		end
	end)
	ctx.Net.get("WallEvent").OnClientEvent:Connect(function(kind, info)
		if kind ~= "smash" then
			return
		end
		ctx.Hud.popup("+" .. Format.short(info.Coins) .. " COINS", Palette.Gold)
		if info.Last then
			ctx.Hud.toast("LAST WALL SMASHED!  GO PRO is ready", "Unlock")
		elseif info.First then
			ctx.Hud.toast(("WALL %d SMASHED!  Every step is worth more now"):format(info.Index), "Unlock")
		end
		ctx.Sound.play("Coins")
	end)
	-- the course can stream in late / be rebuilt in Studio: look again now and then
	task.spawn(function()
		while true do
			task.wait(5)
			wallsArea = nil
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
