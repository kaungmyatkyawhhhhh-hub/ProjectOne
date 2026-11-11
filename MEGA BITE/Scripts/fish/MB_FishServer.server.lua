-- MB_FishServer: food fish live on the server as DATA (no parts): schools wander, flee from sharks that can eat them,
-- and are streamed to each client 6x/s (only the fish near that player). Eating is validated here: reach, size, cooldown.
-- EXP: Safe Reef bites go straight to EXP; Open Sea bites go in the CARRYING bag (x2) and must be banked at a vent.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local F = C.Fish
local Remotes = MB:WaitForChild("Remotes")
local Snap, Eat, Gone, Fx = Remotes:WaitForChild("FishSnap"), Remotes:WaitForChild("FishEat"), Remotes:WaitForChild("FishGone"), Remotes:WaitForChild("Fx")

local ORDER = {"Sardine", "Damsel", "Puffer", "Mackerel"}
local SPI = {}; for i, n in ipairs(ORDER) do SPI[n] = i end
local rng = Random.new()

local function zonePoint(zone)
	local r
	if zone == "open" then r = rng:NextNumber(F.OpenSeaMin, F.OpenSeaMax)
	elseif zone == "reef" then r = math.sqrt(rng:NextNumber()) * (C.Zones.SafeReefRadius - 30)
	else r = math.sqrt(rng:NextNumber()) * F.OpenSeaMax end
	local a = rng:NextNumber() * math.pi * 2
	return C.Swim.MapCentre + Vector3.new(math.cos(a) * r, rng:NextNumber(F.SwimMinY + 2, F.SwimMaxY - 8), math.sin(a) * r)
end

local fish, groups, nextId = {}, {}, 0
local function newFish(g, i)
	nextId += 1
	local sp = F.Species[g.species]
	local off = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 0.4), rng:NextNumber(-1, 1)) * sp.len * 1.6
	local f = {id = nextId, sp = g.species, spi = SPI[g.species], len = sp.len, g = g, off = off,
		pos = g.center + off, vel = Vector3.zero, alive = true}
	fish[f.id] = f
	return f
end
for _, def in ipairs(F.Spawn) do
	local sp = F.Species[def.species]
	for _ = 1, def.groups do
		local c = zonePoint(sp.zone)
		local g = {species = def.species, center = c, target = zonePoint(sp.zone), zone = sp.zone, members = {}}
		for i = 1, sp.school do table.insert(g.members, newFish(g, i)) end
		table.insert(groups, g)
	end
end

-- the sharks (cached each step)
local sharks = {}
local function refreshSharks()
	table.clear(sharks)
	for _, p in ipairs(Players:GetPlayers()) do
		local m = p.Character
		local root = m and m.PrimaryPart
		if root then table.insert(sharks, {plr = p, root = root, pos = root.Position, len = m:GetAttribute("Length") or 7}) end
	end
end

local STEP = 0.1
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < STEP then return end
	acc = 0
	refreshSharks()
	for _, g in ipairs(groups) do
		local sp = F.Species[g.species]
		local d = g.target - g.center
		if d.Magnitude < 6 then g.target = zonePoint(g.zone) else g.center += d.Unit * math.min(sp.speed * 0.45 * STEP, d.Magnitude) end
		for _, f in ipairs(g.members) do
			if f.alive then
				local want = (g.center + f.off) - f.pos
				local v = want.Magnitude > 0.5 and want.Unit * math.min(sp.speed, want.Magnitude * 2) or Vector3.zero
				-- flee from sharks that can eat me
				for _, s in ipairs(sharks) do
					if f.len <= s.len * F.EdibleFrac then
						local away = f.pos - s.pos
						local r = sp.flee * math.sqrt(s.len / 7)
						if away.Magnitude < r then
							v += away.Unit * sp.speed * 1.9 * (1 - away.Magnitude / r) * 1.6
						end
					end
				end
				f.vel = f.vel:Lerp(v, 0.35)
				local p = f.pos + f.vel * STEP
				p = Vector3.new(p.X, math.clamp(p.Y, F.SwimMinY, F.SwimMaxY), p.Z)
				local flat = Vector3.new(p.X, 0, p.Z)
				if flat.Magnitude > C.Swim.BorderSoft then p = p - flat.Unit * (flat.Magnitude - C.Swim.BorderSoft) end
				f.pos = p
			end
		end
	end
end)

-- snapshots: id u16, species u8, x/y/z i16 (x8), yaw u8
local function yawByte(v)
	if v.Magnitude < 0.05 then return nil end
	local a = math.atan2(-v.X, -v.Z)
	return math.floor(((a + math.pi) / (2 * math.pi)) * 255 + 0.5) % 256
end
local lastYaw = {}
task.spawn(function()
	while true do
		task.wait(1 / F.SendRate)
		for _, p in ipairs(Players:GetPlayers()) do
			local m = p.Character; local root = m and m.PrimaryPart
			if root then
				local list = {}
				for id, f in pairs(fish) do
					if f.alive and (f.pos - root.Position).Magnitude < F.SendRadius then table.insert(list, f) end
				end
				local b = buffer.create(#list * 10)
				for i, f in ipairs(list) do
					local o = (i - 1) * 10
					buffer.writeu16(b, o, f.id); buffer.writeu8(b, o + 2, f.spi)
					buffer.writei16(b, o + 3, math.clamp(math.floor(f.pos.X * 8), -32768, 32767))
					buffer.writei16(b, o + 5, math.clamp(math.floor(f.pos.Y * 8), -32768, 32767))
					buffer.writei16(b, o + 7, math.clamp(math.floor(f.pos.Z * 8), -32768, 32767))
					local yb = yawByte(f.vel) or lastYaw[f.id] or 0
					lastYaw[f.id] = yb
					buffer.writeu8(b, o + 9, yb)
				end
				Snap:FireClient(p, b)
			end
		end
	end
end)

-- eating
local lastBite = {}
local function evolveCheck(plr)
	local e = plr:GetAttribute("Evo") or 1
	local nxt = C.Evolutions[e + 1]
	if nxt and (plr:GetAttribute("EXP") or 0) >= nxt.exp and _G.MB_SpawnShark then
		local st = _G.MB_SwimState and _G.MB_SwimState[plr]
		local cf = st and st.root and (CFrame.new(st.root.Position + Vector3.new(0, 3, 0)) * st.root.CFrame.Rotation) or nil
		_G.MB_SpawnShark(plr, e + 1, cf)
		plr:SetAttribute("Bites", 0); plr:SetAttribute("SizeMult", 1)
		task.defer(function() Fx:FireAllClients("Evolve", plr.Character) end)
	end
end
Eat.OnServerEvent:Connect(function(plr, id)
	if type(id) ~= "number" then return end
	local f = fish[id]; if not f or not f.alive then return end
	local m = plr.Character; local root = m and m.PrimaryPart; if not root then return end
	local now = os.clock()
	if now - (lastBite[plr] or 0) < F.BiteCooldown then return end
	local L = m:GetAttribute("Length") or 7
	if f.len > L * F.EdibleFrac then return end
	local mouth = root.Position + root.CFrame.LookVector * L * 0.45
	if (mouth - f.pos).Magnitude > f.len * 0.6 + L * 0.3 + F.BiteSlack then return end
	lastBite[plr] = now
	f.alive = false
	Gone:FireAllClients(id, f.pos, plr.UserId, f.spi)
	m:SetAttribute("BiteAt", workspace:GetServerTimeNow())
	-- reward
	local sp = F.Species[f.sp]
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude
	local open = flat >= C.Zones.SafeReefRadius
	local amount = sp.exp * (open and F.ZoneMult.open or F.ZoneMult.reef)
	if open then
		local c, cm = plr:GetAttribute("Carry") or 0, plr:GetAttribute("CarryMax") or 30
		local add = math.min(amount, cm - c)
		plr:SetAttribute("Carry", c + add)
		if add < amount then Fx:FireClient(plr, "BagFull") end
	else
		plr:SetAttribute("EXP", (plr:GetAttribute("EXP") or 0) + amount)
	end
	local bites = (plr:GetAttribute("Bites") or 0) + 1
	plr:SetAttribute("Bites", bites)
	if bites % F.SizeUpEvery == 0 then
		local sm = math.min(1 + F.SizeUpMax, (plr:GetAttribute("SizeMult") or 1) + F.SizeUpStep)
		plr:SetAttribute("SizeMult", sm)
		Fx:FireClient(plr, "SizeUp")
	end
	evolveCheck(plr)
	-- respawn the fish back in its school
	task.delay(F.RespawnDelay, function()
		f.pos = zonePoint(f.g.zone); f.vel = Vector3.zero; f.alive = true
	end)
end)

-- banking at vents
task.spawn(function()
	while true do
		task.wait(0.4)
		for _, p in ipairs(Players:GetPlayers()) do
			local c = p:GetAttribute("Carry") or 0
			local m = p.Character; local root = m and m.PrimaryPart
			if c > 0 and root then
				for _, v in ipairs(C.Map.Vents) do
					if (root.Position - v).Magnitude < F.BankRadius then
						p:SetAttribute("Carry", 0)
						p:SetAttribute("EXP", (p:GetAttribute("EXP") or 0) + c)
						Fx:FireClient(p, "Banked", c)
						Fx:FireAllClients("BankFx", v)
						evolveCheck(p)
						break
					end
				end
			end
		end
	end
end)
