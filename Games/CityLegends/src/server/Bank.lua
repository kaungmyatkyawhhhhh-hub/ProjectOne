--[[
	Bank (server)
	The Legends Reserve Bank and its robbery (owner, 2026-10-22: "add a bank which u can rob").
	  * A stone bank on its own city block: steps, columns, a marble hall with chandeliers and
	    teller counters, and a round steel vault door at the back.
	  * On foot, hold E at the vault door to crack it: the alarm rings, the door swings open and
	    the robber gets 4 stars. Inside, cash carts: hold E to stuff a bag (up to a limit).
	  * The loot rides with you (on foot or in your car). Lose the police, then bring it to the
	    drop-off (a lock-up garage across town) to cash in. Busted: the loot is gone.
	  * The vault closes again after a while and stays locked for a cooldown.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local B = Config.Bank
local C = Config.City

local Bank = {}
Bank.BLOCK = B.Block -- { bi, bj }

local vault: {
	door: Model?,
	prompt: ProximityPrompt?,
	carts: { ProximityPrompt },
	alarm: Sound?,
	alarmLights: { Light },
	openUntil: number,
	lockedUntil: number,
	hinge: CFrame?,
} = { door = nil, prompt = nil, carts = {}, alarm = nil, alarmLights = {}, openUntil = 0, lockedUntil = 0, hinge = nil }
local dropoff: Vector3? = nil

local STONE = Color3.fromRGB(196, 186, 166)
local STONE_DARK = Color3.fromRGB(150, 140, 122)
local MARBLE = Color3.fromRGB(232, 228, 220)
local GOLD = Color3.fromRGB(214, 172, 74)
local WOOD = Color3.fromRGB(82, 52, 32)
local STEEL = Color3.fromRGB(150, 156, 164)

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
-- builds the bank when (bi, bj) is its block; returns true if it did
-- (CityBuilder asks this when baking the map: this block stays empty and is built at start)
function Bank.isBlock(bi: number, bj: number): boolean
	return bi == B.Block[1] and bj == B.Block[2]
end

function Bank.block(kit: any, parent: Instance, bi: number, bj: number, cx: number, cz: number, lot: number): boolean
	if not (bi == B.Block[1] and bj == B.Block[2]) then
		return false
	end
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = "LegendsReserveBank"
	model.Parent = parent
	local ground = C.CurbHeight
	-- the front looks at the city centre along X
	local front = if cx < 0 then Vector3.new(1, 0, 0) else Vector3.new(-1, 0, 0)
	local base = CFrame.lookAt(Vector3.new(cx, ground, cz), Vector3.new(cx, ground, cz) + front)
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the front
	end
	local W, D, H = 140, 100, 44 -- width, depth, wall height
	local FLOOR = 3.6
	local zFront, zBack = -D / 2, D / 2

	-- front plaza and steps
	mk(model, Vector3.new(W + 30, 0.4, lot / 2 - D / 2 + 10), at(0, 0.2, zFront - (lot / 2 - D / 2 + 10) / 2), Color3.fromRGB(120, 116, 110), Enum.Material.Pavement)
	for k = 1, 3 do
		local depth = 6
		mk(model, Vector3.new(W - 10, 1.2 * k, depth), at(0, 0.6 * k, zFront - 4 - (3 - k) * depth - depth / 2 + 2), STONE, Enum.Material.Limestone)
	end
	-- floor
	mk(model, Vector3.new(W, FLOOR, D), at(0, FLOOR / 2, 0), STONE_DARK, Enum.Material.Limestone)
	mk(model, Vector3.new(W - 4, 0.2, D - 4), at(0, FLOOR + 0.1, 0), MARBLE, Enum.Material.Marble, { name = "MarbleFloor" })
	-- marble floor inlay
	deco(model, Vector3.new(16, 0.05, 16), at(0, FLOOR + 0.22, -14) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(150, 130, 100), Enum.Material.Marble)

	local wallT = 3
	-- back and side walls
	mk(model, Vector3.new(W, H, wallT), at(0, FLOOR + H / 2, zBack - wallT / 2), STONE, Enum.Material.Limestone)
	for _, sx in { -1, 1 } do
		mk(model, Vector3.new(wallT, H, D), at(sx * (W / 2 - wallT / 2), FLOOR + H / 2, 0), STONE, Enum.Material.Limestone)
		-- tall windows on the sides
		for k = -1, 1 do
			deco(model, Vector3.new(0.3, 22, 10), at(sx * (W / 2 + 0.05), FLOOR + 18, k * 26), Color3.fromRGB(255, 214, 150), Enum.Material.Glass, { transparency = 0.25 })
			deco(model, Vector3.new(0.6, 24, 1.2), at(sx * (W / 2 + 0.2), FLOOR + 18, k * 26 - 5.6), STONE_DARK, Enum.Material.Limestone)
			deco(model, Vector3.new(0.6, 24, 1.2), at(sx * (W / 2 + 0.2), FLOOR + 18, k * 26 + 5.6), STONE_DARK, Enum.Material.Limestone)
		end
	end
	-- the front wall with three tall doorways
	local doorW, doorH = 14, 20
	local zf = zFront + 10
	local xs = { -W / 2, -doorW * 1.5 - 12, -doorW / 2 - 12, -doorW / 2, doorW / 2, doorW / 2 + 12, doorW * 1.5 + 12, W / 2 }
	-- solid pieces between the doorways
	local solid = { { -W / 2, -doorW * 1.5 - 12 }, { -doorW * 0.5 - 12, -doorW / 2 }, { doorW / 2, doorW / 2 + 12 }, { doorW * 1.5 + 12, W / 2 } }
	local _ = xs
	for _, r in solid do
		local w = r[2] - r[1]
		mk(model, Vector3.new(w, H, wallT), at((r[1] + r[2]) / 2, FLOOR + H / 2, zf), STONE, Enum.Material.Limestone)
	end
	for _, dx in { -(doorW + 12), 0, doorW + 12 } do
		mk(model, Vector3.new(doorW, H - doorH, wallT), at(dx, FLOOR + doorH + (H - doorH) / 2, zf), STONE, Enum.Material.Limestone)
		-- bronze door frames, warm light spilling out
		deco(model, Vector3.new(doorW + 1.5, 1.2, wallT + 0.4), at(dx, FLOOR + doorH + 0.6, zf), GOLD, Enum.Material.Metal)
		for _, s in { -1, 1 } do
			deco(model, Vector3.new(0.8, doorH, wallT + 0.4), at(dx + s * (doorW / 2 + 0.4), FLOOR + doorH / 2, zf), GOLD, Enum.Material.Metal)
		end
	end
	-- the portico: columns, beam and pediment
	local colZ = zFront + 2
	for k = 0, 5 do
		local x = -W / 2 + 14 + k * (W - 28) / 5
		mk(model, Vector3.new(H - 6, 5, 5), at(x, FLOOR + (H - 6) / 2, colZ) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
		deco(model, Vector3.new(7, 1.6, 7), at(x, FLOOR + 0.8, colZ), STONE, Enum.Material.Limestone)
		deco(model, Vector3.new(7, 1.6, 7), at(x, FLOOR + H - 6.8, colZ), STONE, Enum.Material.Limestone)
	end
	local beam = mk(model, Vector3.new(W + 6, 6, 14), at(0, FLOOR + H - 3, zFront + 4), STONE, Enum.Material.Limestone, { name = "Beam" })
	kit.surfaceText(beam, Enum.NormalId.Front, "LEGENDS RESERVE BANK", GOLD, nil, 1, Enum.Font.Garamond, Vector2.new(1400, 80))
	-- the attic above the beam, stepped back
	mk(model, Vector3.new(W + 2, 5, 10), at(0, FLOOR + H + 2.5, zFront + 6), STONE_DARK, Enum.Material.Limestone, { name = "Attic" })
	deco(model, Vector3.new(W + 8, 0.8, 15), at(0, FLOOR + H + 0.4, zFront + 4), STONE, Enum.Material.Limestone)
	-- roof
	mk(model, Vector3.new(W + 2, 2, D + 2), at(0, FLOOR + H + 1, 0), STONE_DARK, Enum.Material.Limestone)
	-- floodlights washing the facade
	for _, x in { -W / 2 + 14, 0, W / 2 - 14 } do
		local lamp = deco(model, Vector3.new(1.4, 1, 1.4), at(x, 1, zFront - 16), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 220, 170), 60, 3, Enum.NormalId.Back, 60)
	end

	-- inside: ceiling, chandeliers, counters
	deco(model, Vector3.new(W - 6, 1, D - 6), at(0, FLOOR + H - 6, 4), Color3.fromRGB(230, 222, 205), Enum.Material.SmoothPlastic)
	for _, z in { -14, 10 } do
		for _, x in { -36, 0, 36 } do
			local hub = deco(model, Vector3.new(4, 2.4, 4), at(x, FLOOR + H - 12, z), GOLD, Enum.Material.Metal)
			deco(model, Vector3.new(0.3, 5, 0.3), at(x, FLOOR + H - 9, z), GOLD, Enum.Material.Metal)
			deco(model, Vector3.new(5, 1.2, 5), at(x, FLOOR + H - 13.4, z), Color3.fromRGB(255, 236, 200), Enum.Material.Neon)
			kit.addLight("PointLight", hub, Color3.fromRGB(255, 220, 170), 34, 1.6)
		end
	end
	-- teller counter across the hall with glass screens
	local cz2 = 12
	mk(model, Vector3.new(W - 40, 4.6, 4), at(0, FLOOR + 2.3, cz2), WOOD, Enum.Material.Wood)
	deco(model, Vector3.new(W - 40, 0.4, 4.6), at(0, FLOOR + 4.8, cz2), MARBLE, Enum.Material.Marble)
	deco(model, Vector3.new(W - 40, 5, 0.2), at(0, FLOOR + 7.5, cz2 + 1), Color3.fromRGB(200, 220, 230), Enum.Material.Glass, { transparency = 0.7 })
	for k = -3, 3 do
		deco(model, Vector3.new(0.4, 5.4, 0.4), at(k * (W - 40) / 7, FLOOR + 7.5, cz2 + 1), GOLD, Enum.Material.Metal)
		local lampP = deco(model, Vector3.new(0.6, 0.6, 0.6), at(k * (W - 40) / 7 + 3, FLOOR + 5.3, cz2), Color3.fromRGB(40, 100, 60), Enum.Material.Glass)
		kit.addLight("PointLight", lampP, Color3.fromRGB(150, 255, 170), 8, 0.6)
	end
	-- the vault wall at the back with the round door
	local vz = zBack - 22
	for _, r in { { -W / 2 + 3, -12 }, { 12, W / 2 - 3 } } do
		mk(model, Vector3.new(r[2] - r[1], H - 6, 3), at((r[1] + r[2]) / 2, FLOOR + (H - 6) / 2, vz), STEEL:Lerp(STONE, 0.6), Enum.Material.Concrete)
	end
	mk(model, Vector3.new(24, H - 6 - 20, 3), at(0, FLOOR + 20 + (H - 26) / 2, vz), STEEL:Lerp(STONE, 0.6), Enum.Material.Concrete)
	-- the vault room behind it
	mk(model, Vector3.new(W - 6, 0.2, 19), at(0, FLOOR + 0.1, vz + 10.5), Color3.fromRGB(60, 62, 66), Enum.Material.DiamondPlate)
	-- gold and cash shelves
	for _, x in { -40, -24, 24, 40 } do
		deco(model, Vector3.new(12, 0.6, 5), at(x, FLOOR + 3, zBack - 6), STEEL, Enum.Material.Metal)
		deco(model, Vector3.new(12, 0.6, 5), at(x, FLOOR + 7, zBack - 6), STEEL, Enum.Material.Metal)
		for k = -2, 2 do
			deco(model, Vector3.new(1.6, 0.8, 0.9), at(x + k * 2, FLOOR + 3.7, zBack - 6), Color3.fromRGB(255, 200, 60), Enum.Material.Foil)
			deco(model, Vector3.new(1.8, 1.2, 1.2), at(x + k * 2, FLOOR + 7.9, zBack - 6), Color3.fromRGB(70, 140, 80), Enum.Material.SmoothPlastic)
		end
	end
	local vaultLamp = deco(model, Vector3.new(2, 0.4, 2), at(0, FLOOR + 20, zBack - 10), Color3.fromRGB(255, 240, 210), Enum.Material.Neon)
	kit.addLight("PointLight", vaultLamp, Color3.fromRGB(255, 230, 190), 30, 1.2)

	-- the vault door: a thick steel disc hinged on its left edge
	local door = Instance.new("Model")
	door.Name = "VaultDoor"
	local R = 9.5
	local doorCF = at(0, FLOOR + 10.2, vz) * CFrame.Angles(0, math.rad(90), 0)
	local disc = mk(door, Vector3.new(3.2, R * 2, R * 2), doorCF, STEEL, Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder, name = "Disc" })
	deco(door, Vector3.new(3.4, R * 2 - 3, R * 2 - 3), doorCF, Color3.fromRGB(120, 126, 134), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	-- the wheel and bolts on its face
	local face = at(0, FLOOR + 10.2, vz - 1.8)
	deco(door, Vector3.new(0.6, 6, 6), face * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	for k = 0, 2 do
		deco(door, Vector3.new(0.5, 9, 0.6), face * CFrame.Angles(0, 0, math.rad(k * 60)), GOLD, Enum.Material.Metal)
	end
	for k = 0, 11 do
		local a = k * math.pi / 6
		deco(door, Vector3.new(0.8, 0.8, 0.6), face * CFrame.new(math.cos(a) * (R - 1.4), math.sin(a) * (R - 1.4), 0), GOLD, Enum.Material.Metal)
	end
	door.PrimaryPart = disc
	door.Parent = model
	vault.door = door
	vault.hinge = at(-R, FLOOR + 10.2, vz - 1.6)
	-- frame ring around the door
	deco(model, Vector3.new(3.6, R * 2 + 2.4, R * 2 + 2.4), doorCF * CFrame.new(0.4, 0, 0), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })

	local promptPart = deco(model, Vector3.new(2, 2, 2), at(0, FLOOR + 5, vz - 5), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	promptPart.Name = "VaultPrompt"
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Crack the vault"
	prompt.ObjectText = "Legends Reserve Bank"
	prompt.HoldDuration = B.CrackSeconds
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = promptPart
	vault.prompt = prompt

	-- cash carts inside the vault
	for k, x in { -30, -10, 10, 30 } do
		local cart = deco(model, Vector3.new(5, 3.2, 3), at(x, FLOOR + 1.8, zBack - 12), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
		cart.Name = "CashCart" .. k
		for j = -1, 1 do
			deco(model, Vector3.new(1.4, 1, 2.4), at(x + j * 1.5, FLOOR + 3.9, zBack - 12), Color3.fromRGB(80, 160, 90), Enum.Material.SmoothPlastic)
		end
		local cp = Instance.new("ProximityPrompt")
		cp.ActionText = "Grab cash"
		cp.ObjectText = "Cash cart"
		cp.HoldDuration = B.GrabSeconds
		cp.MaxActivationDistance = 9
		cp.RequiresLineOfSight = false
		cp.Enabled = false
		cp.Parent = cart
		table.insert(vault.carts, cp)
	end

	-- alarm: a bell and red lights
	local alarmPart = deco(model, Vector3.new(1, 1, 1), at(0, FLOOR + 30, 0), Color3.fromRGB(150, 0, 0), Enum.Material.SmoothPlastic, { transparency = 1 })
	local alarm = Instance.new("Sound")
	alarm.Name = "Alarm"
	alarm.SoundId = Config.Sounds.Alarm
	alarm.Looped = true
	alarm.Volume = 0.9
	alarm.RollOffMaxDistance = 600
	alarm.Parent = alarmPart
	vault.alarm = alarm
	for _, x in { -W / 2 + 6, W / 2 - 6 } do
		local beacon = deco(model, Vector3.new(1.2, 1.2, 1.2), at(x, FLOOR + H - 8, zFront + 14), Color3.fromRGB(120, 0, 0), Enum.Material.Glass)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 20, 20)
		l.Range = 40
		l.Brightness = 0
		l.Parent = beacon
		table.insert(vault.alarmLights, l)
	end
	return true
end

---------------------------------------------------------------------
-- The drop-off: a lock-up garage at the far corner of the city
---------------------------------------------------------------------
local function buildDropoff(parent: Instance)
	local i, j = B.Dropoff[1], B.Dropoff[2]
	local corner = CityLayout.intersectionPos(i, j)
	-- on the sidewalk at the block's corner, inside the grid
	local inward = Vector3.new(if i == 0 then 1 else -1, 0, if j == 0 then 1 else -1)
	local pos = corner + inward * (C.RoadWidth / 2 + 14)
	dropoff = pos
	local m = Instance.new("Model")
	m.Name = "Dropoff"
	local ring = Instance.new("Part")
	ring.Name = "Marker"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 22, 22)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, C.CurbHeight + 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(61, 255, 143)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.55
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Parent = m
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(120, 3, 3)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Color = Color3.fromRGB(61, 255, 143)
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.7
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Parent = m
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.StudsOffset = Vector3.new(0, 14, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 2500
	bb.Parent = ring
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 22
	t.TextColor3 = Color3.fromRGB(61, 255, 143)
	t.TextStrokeTransparency = 0.3
	t.Text = "DROP-OFF"
	t.Parent = bb
	m:SetAttribute("Dropoff", true)
	m.Parent = parent
end

---------------------------------------------------------------------
-- The robbery
---------------------------------------------------------------------
local function setVaultOpen(open: boolean)
	local door = vault.door
	local hinge = vault.hinge
	if not (door and hinge) then
		return
	end
	-- swing the door round its hinge (each part tweened along the arc's end)
	local swing = if open then CFrame.Angles(0, math.rad(-100), 0) else CFrame.new()
	for _, p in door:GetDescendants() do
		if p:IsA("BasePart") then
			local home = p:GetAttribute("Home") :: CFrame?
			if not home then
				home = p.CFrame
				p:SetAttribute("Home", home)
			end
			local rel = hinge:ToObjectSpace(home :: CFrame)
			local goal = hinge * swing * rel
			TweenService:Create(p, TweenInfo.new(if open then 4 else 3, Enum.EasingStyle.Sine), { CFrame = goal }):Play()
		end
	end
	for _, cp in vault.carts do
		cp.Enabled = open
		cp:SetAttribute("Left", if open then B.GrabsPerCart else 0)
	end
	if vault.alarm then
		if open then
			vault.alarm:Play()
		else
			vault.alarm:Stop()
		end
	end
end

function Bank.init(ctx: any, Police: any)
	local BankEvent: RemoteEvent = ctx.remote("RemoteEvent", "BankEvent")
	buildDropoff(workspace:FindFirstChild("City") or workspace)
	workspace:SetAttribute("Dropoff", dropoff)

	local function setLoot(player: Player, amount: number)
		player:SetAttribute("Loot", if amount > 0 then amount else nil)
	end

	-- busted: the loot is gone
	table.insert(Police.onBusted, function(player: Player)
		if ((player:GetAttribute("Loot") :: number?) or 0) > 0 then
			setLoot(player, 0)
			BankEvent:FireClient(player, { kind = "lost" })
		end
	end)

	local prompt = vault.prompt
	if prompt then
		prompt.Triggered:Connect(function(who: Player)
			local now = os.clock()
			if now < vault.lockedUntil then
				return
			end
			vault.openUntil = now + B.OpenSeconds
			vault.lockedUntil = now + B.OpenSeconds + B.CooldownSeconds
			prompt.Enabled = false
			setVaultOpen(true)
			Police.setWanted(who, math.max(Police.getWanted(who), B.Stars), "bank")
			BankEvent:FireAllClients({ kind = "robbery", by = who.DisplayName })
		end)
	end
	for _, cp in vault.carts do
		cp.Triggered:Connect(function(who: Player)
			local left = (cp:GetAttribute("Left") :: number?) or 0
			if left <= 0 or os.clock() > vault.openUntil then
				return
			end
			local carried = (who:GetAttribute("Loot") :: number?) or 0
			if carried >= B.MaxLoot then
				BankEvent:FireClient(who, { kind = "full" })
				return
			end
			local grab = math.random(B.GrabMin, B.GrabMax)
			local profile = PlayerData.get(who)
			local level = if profile then (profile :: any).Level or 1 else 1
			grab = math.floor(grab * (1 + math.min(level, 50) * 0.02))
			local total = math.min(B.MaxLoot, carried + grab)
			setLoot(who, total)
			cp:SetAttribute("Left", left - 1)
			if left - 1 <= 0 then
				cp.Enabled = false
			end
			-- anyone grabbing is a robber too
			Police.setWanted(who, math.max(Police.getWanted(who), B.Stars), "bank")
			BankEvent:FireClient(who, { kind = "grab", amount = total - carried, total = total })
		end)
	end

	-- vault timers, the alarm lights and cashing in
	task.spawn(function()
		local blink = false
		while true do
			task.wait(0.25)
			local now = os.clock()
			local open = now < vault.openUntil
			if vault.openUntil > 0 and not open and vault.door and (vault.door :: any):GetAttribute("Open") then
				(vault.door :: any):SetAttribute("Open", false)
				setVaultOpen(false)
			elseif open and vault.door and not (vault.door :: any):GetAttribute("Open") then
				(vault.door :: any):SetAttribute("Open", true)
			end
			blink = not blink
			for _, l in vault.alarmLights do
				l.Brightness = if open and blink then 5 else 0
			end
			local p = vault.prompt
			if p then
				if now < vault.lockedUntil then
					p.Enabled = false
				else
					p.Enabled = true
				end
			end
			-- cashing in at the drop-off: in a car or on foot, with the police lost
			local drop = dropoff
			if drop then
				for _, player in Players:GetPlayers() do
					local loot = (player:GetAttribute("Loot") :: number?) or 0
					if loot > 0 then
						local pos: Vector3? = nil
						local car = ctx.getCar(player)
						local character = player.Character
						local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						if hrp then
							pos = hrp.Position
						elseif car and car.PrimaryPart then
							pos = car.PrimaryPart.Position
						end
						if pos and Vector3.new(pos.X - drop.X, 0, pos.Z - drop.Z).Magnitude < B.DropoffRadius then
							if Police.getWanted(player) > 0 then
								if not player:GetAttribute("DropWarned") then
									player:SetAttribute("DropWarned", true)
									BankEvent:FireClient(player, { kind = "losecops" })
								end
							else
								player:SetAttribute("DropWarned", nil)
								setLoot(player, 0)
								PlayerData.addCash(player, loot)
								ctx.grantXp(player, B.DeliverXp, "bank")
								task.spawn(PlayerData.save, player)
								BankEvent:FireClient(player, { kind = "paid", amount = loot })
							end
						else
							player:SetAttribute("DropWarned", nil)
						end
					end
				end
			end
		end
	end)
end

return Bank
