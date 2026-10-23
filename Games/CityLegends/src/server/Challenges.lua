--[[
	Challenges (server)
	Free-roam challenges (owner, 2026-10-23: "make the game 1000000000x better and cooler"):
	  * drift scoring: the client builds a drift run and banks it; the server caps the points by
	    how long the run lasted and pays cash and XP
	  * speed traps (ChallengeData.traps): gantries across fast roads; driving through records your
	    speed, a bronze / silver / gold medal and your personal best (saved). Not the police's
	    cameras: they never give stars
	  * jump ramps (ChallengeData.ramps): air time and distance pay a bonus
	  * the leaderboard: top speed (best trap) and best drift, from an OrderedDataStore when it
	    works (published games), else from the players in this server; on a board on a city-centre
	    corner and in the client's panel (B)
	Remotes: ChallengeReport (client -> server), ChallengeEvent (server -> client), ChallengeBoard
	(RemoteFunction: the leaderboard).
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local ChallengeData = require(Shared:WaitForChild("ChallengeData"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local K = Config.Challenges

local Challenges = {}

type Data = { traps: { [string]: number }, drift: number, air: number }
type Session = { lastBank: number, lastStunt: number, trapAt: { [string]: number }, pushed: { [string]: number } }

local ctx: any = nil
local event: RemoteEvent? = nil
local sessions: { [Player]: Session } = {}
local trapBoards: { [string]: { TextLabel } } = {}
local boardLabels: { speed: TextLabel?, drift: TextLabel? } = {}
local records: { [string]: { mph: number, name: string } } = {}

local YELLOW = Color3.fromRGB(255, 204, 40)
local INK = Color3.fromRGB(14, 14, 18)
local CHROME = Color3.fromRGB(196, 200, 206)

---------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------
local function data(player: Player): Data?
	local profile = PlayerData.get(player) :: any
	if not profile then
		return nil
	end
	local raw = profile.Challenges
	if type(raw) ~= "table" then
		raw = {}
	end
	local traps = {}
	if type(raw.traps) == "table" then
		for id, v in raw.traps do
			if type(id) == "string" and ChallengeData.trapById[id] and type(v) == "number" then
				traps[id] = math.clamp(math.floor(v), 0, 400)
			end
		end
	end
	local clean: Data = {
		traps = traps,
		drift = if type(raw.drift) == "number" then math.max(0, math.floor(raw.drift)) else 0,
		air = if type(raw.air) == "number" then math.clamp(raw.air, 0, 10) else 0,
	}
	profile.Challenges = clean
	return clean
end

local function session(player: Player): Session
	local s = sessions[player]
	if not s then
		s = { lastBank = os.clock(), lastStunt = 0, trapAt = {}, pushed = {} }
		sessions[player] = s
	end
	return s
end

local function bestSpeed(d: Data): number
	local best = 0
	for _, v in d.traps do
		best = math.max(best, v)
	end
	return best
end

local function fire(player: Player, info: { [string]: any })
	if event then
		event:FireClient(player, info)
	end
end

local function speedOf(car: Model): number
	local root = car.PrimaryPart
	if not root then
		return 0
	end
	local v = root.AssemblyLinearVelocity
	return Config.spsToMph(Vector3.new(v.X, 0, v.Z).Magnitude)
end

---------------------------------------------------------------------
-- Global leaderboard (OrderedDataStore when it works)
---------------------------------------------------------------------
local stores: { [string]: OrderedDataStore? } = {}
local function store(name: string): OrderedDataStore?
	if stores[name] == nil then
		local ok, st = pcall(function()
			return DataStoreService:GetOrderedDataStore(name)
		end)
		stores[name] = if ok then st else nil
	end
	return stores[name]
end

-- send a new best up (at most once every 20 seconds per board per player)
local function push(player: Player, board: string, value: number)
	local s = session(player)
	if os.clock() - (s.pushed[board] or 0) < 20 then
		return
	end
	s.pushed[board] = os.clock()
	task.spawn(function()
		local st = store(board)
		if st then
			pcall(function()
				(st :: OrderedDataStore):SetAsync(tostring(player.UserId), math.floor(value))
			end)
		end
	end)
end

type Row = { name: string, value: number }
local top: { speed: { Row }, drift: { Row } } = { speed = {}, drift = {} }
local nameCache: { [number]: string } = {}

local function nameOf(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	nameCache[userId] = if ok and type(name) == "string" then name else ("Player " .. userId)
	return nameCache[userId]
end

local function readTop(board: string, field: string): { Row }
	local rows: { [string]: Row } = {}
	local st = store(board)
	if st then
		pcall(function()
			local pages = (st :: OrderedDataStore):GetSortedAsync(false, 10)
			for _, entry in pages:GetCurrentPage() do
				local id = tonumber(entry.key)
				if id and type(entry.value) == "number" then
					rows[tostring(id)] = { name = nameOf(id), value = entry.value }
				end
			end
		end)
	end
	-- the players here (also what's shown when the store can't be read, e.g. in Studio)
	for _, p in Players:GetPlayers() do
		local d = data(p)
		if d then
			local v = if field == "speed" then bestSpeed(d) else d.drift
			local key = tostring(p.UserId)
			if v > 0 and (not rows[key] or rows[key].value < v) then
				rows[key] = { name = p.Name, value = v }
			end
		end
	end
	local list = {}
	for _, r in rows do
		table.insert(list, r)
	end
	table.sort(list, function(a, b)
		return a.value > b.value
	end)
	while #list > 10 do
		table.remove(list)
	end
	return list
end

local function boardText(title: string, rows: { Row }, unit: string): string
	local lines = { title }
	for i, r in rows do
		if i > 5 then
			break
		end
		table.insert(lines, string.format("%d. %s  %d%s", i, r.name, r.value, unit))
	end
	if #rows == 0 then
		table.insert(lines, "no one yet: be the first")
	end
	return table.concat(lines, "\n")
end

local function refreshTop()
	top.speed = readTop("CL_TopSpeed", "speed")
	top.drift = readTop("CL_DriftBest", "drift")
	if boardLabels.speed then
		boardLabels.speed.Text = boardText("TOP SPEED", top.speed, " mph")
	end
	if boardLabels.drift then
		boardLabels.drift.Text = boardText("BEST DRIFT", top.drift, "")
	end
end

---------------------------------------------------------------------
-- Results
---------------------------------------------------------------------
local function medalFor(mph: number): (number, string?)
	local rank, name = 0, nil
	for i, m in K.TrapMedals do
		if mph >= m.mph then
			rank, name = i, m.name
		end
	end
	return rank, name
end

local function onTrap(player: Player, id: any, clientMph: any)
	local trap = if type(id) == "string" then ChallengeData.trapById[id] else nil
	local car = ctx.getCar(player)
	local d = data(player)
	if not (trap and car and car.PrimaryPart and d and type(clientMph) == "number") then
		return
	end
	local s = session(player)
	local now = os.clock()
	if now - (s.trapAt[trap.id] or 0) < K.TrapCooldown then
		return
	end
	-- really at the gate (a little slack for lag at speed)
	if (car.PrimaryPart.Position - trap.pos).Magnitude > 140 then
		return
	end
	s.trapAt[trap.id] = now
	local spec = Cars.get(car:GetAttribute("CarId") :: string)
	local mph = math.min(clientMph, spec.TopSpeed * 1.3, speedOf(car) * 1.25 + 15)
	mph = math.floor(math.max(0, mph))
	local old = d.traps[trap.id] or 0
	local newBest = mph > old
	local oldRank = medalFor(old)
	local rank, medal = medalFor(mph)
	local cash = 0
	if newBest then
		d.traps[trap.id] = mph
		-- pay for each medal you reach for the first time on this trap
		for i = oldRank + 1, rank do
			cash += K.TrapMedals[i].cash
		end
		if cash > 0 then
			PlayerData.addCash(player, cash)
		end
		ctx.grantXp(player, K.TrapXp, "speed trap")
		push(player, "CL_TopSpeed", bestSpeed(d))
		task.spawn(PlayerData.save, player)
	end
	-- the gantry's record
	local rec = records[trap.id]
	if not rec or mph > rec.mph then
		records[trap.id] = { mph = mph, name = player.DisplayName }
		local labels: { TextLabel } = trapBoards[trap.id] or {}
		for _, label in labels do
			label.Text = string.format("SPEED TRAP\n%s\nRECORD %d MPH  %s", trap.name, mph, string.upper(player.DisplayName))
		end
	end
	fire(player, { kind = "trap", name = trap.name, mph = mph, medal = medal, best = math.max(old, mph), newBest = newBest, cash = cash })
end

local function onDrift(player: Player, score: any, seconds: any)
	local car = ctx.getCar(player)
	local d = data(player)
	if not (car and d and type(score) == "number" and type(seconds) == "number") then
		return
	end
	local s = session(player)
	local now = os.clock()
	-- a run can't be longer than the time since the last one was banked
	local secs = math.clamp(seconds, 0, math.min(120, now - s.lastBank + 1))
	s.lastBank = now
	if secs < 1 then
		return
	end
	local points = math.floor(math.clamp(score, 0, secs * K.DriftMaxPerSecond))
	if points <= 0 then
		return
	end
	local cash = math.min(math.floor(points * K.DriftCashPerPoint), K.DriftCashMax)
	PlayerData.addCash(player, cash)
	ctx.grantXp(player, math.clamp(math.floor(points * K.DriftXpPerPoint), 1, K.DriftXpMax), "drift")
	local newBest = points > d.drift
	if newBest then
		d.drift = points
		push(player, "CL_DriftBest", points)
		task.spawn(PlayerData.save, player)
	end
	fire(player, { kind = "drift", score = points, cash = cash, best = d.drift, newBest = newBest })
end

local function onStunt(player: Player, air: any, dist: any)
	local car = ctx.getCar(player)
	local d = data(player)
	if not (car and d and type(air) == "number" and type(dist) == "number") then
		return
	end
	local s = session(player)
	local now = os.clock()
	if now - s.lastStunt < 2 then
		return
	end
	local a = math.clamp(air, 0, 6)
	if a < K.StuntMinAir or now - s.lastStunt < a then
		return
	end
	s.lastStunt = now
	local studs = math.clamp(dist, 0, a * 330)
	local cash = math.min(math.floor(a * K.StuntCashPerSecond + studs * K.StuntCashPerStud), K.StuntCashMax)
	PlayerData.addCash(player, cash)
	ctx.grantXp(player, K.StuntXp, "jump")
	local newBest = a > d.air
	if newBest then
		d.air = math.floor(a * 100) / 100
		task.spawn(PlayerData.save, player)
	end
	fire(player, { kind = "stunt", air = a, dist = studs, cash = cash, newBest = newBest })
end

---------------------------------------------------------------------
-- The world: gantries, ramps, the board (CityBuilder calls buildWorld)
---------------------------------------------------------------------
local function screen(part: BasePart, face: Enum.NormalId, text: string, size: Vector2): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.CanvasSize = size
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = INK
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = YELLOW
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.06, 0)
	pad.PaddingBottom = UDim.new(0.06, 0)
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.Parent = label
	return label
end

-- a speed trap gantry: chrome posts striped yellow and black at the foot, a lattice beam, a big
-- LED board both ways, and a chequered line across the road (not the police's grey camera poles)
local function gantry(kit: any, parent: Instance, trap: ChallengeData.Trap)
	local model = Instance.new("Model")
	model.Name = "SpeedTrap_" .. trap.id
	model.Parent = parent
	local side = trap.dir:Cross(Vector3.yAxis)
	local base = CFrame.lookAt(trap.pos, trap.pos + trap.dir)
	local reach = trap.half + 3
	local top = 24
	for _, s in { -1, 1 } do
		local foot = trap.pos + side * s * reach
		kit.mk(model, Vector3.new(1.6, top, 1.6), CFrame.new(foot + Vector3.new(0, top / 2, 0)), CHROME, Enum.Material.Metal, { reflectance = 0.2, name = "TrapPost" })
		for k = 0, 2 do
			kit.deco(model, Vector3.new(1.8, 1.2, 1.8), CFrame.new(foot + Vector3.new(0, 1 + k * 2.4, 0)), if k % 2 == 0 then YELLOW else INK, Enum.Material.SmoothPlastic)
		end
	end
	-- the beam: two rails with cross braces
	local span = reach * 2
	for _, dy in { 0, 3 } do
		kit.deco(model, Vector3.new(span, 0.6, 0.6), base * CFrame.new(0, top - dy, 0), CHROME, Enum.Material.Metal) -- (X runs across the road)
	end
	local n = math.floor(span / 6)
	for k = 0, n - 1 do
		local x = -reach + (k + 0.5) * span / n
		kit.deco(model, Vector3.new(0.3, 3.6, 0.3), base * CFrame.new(x, top - 1.5, 0) * CFrame.Angles(0, 0, if k % 2 == 0 then 0.8 else -0.8), CHROME, Enum.Material.Metal)
	end
	-- the board (facing both ways)
	local board = kit.mk(model, Vector3.new(26, 8, 0.8), base * CFrame.new(0, top + 4.6, 0) * CFrame.Angles(0, math.pi, 0), INK, Enum.Material.SmoothPlastic, { name = "TrapBoard", collide = false })
	local labels = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		table.insert(labels, screen(board, face, "SPEED TRAP\n" .. trap.name .. "\nRECORD --", Vector2.new(520, 160)))
	end
	trapBoards[trap.id] = labels
	-- the chequered line on the road
	local sq = 6
	local count = math.floor(span / sq)
	for k = 0, count - 1 do
		local x = -reach + (k + 0.5) * span / count
		for row = 0, 1 do
			local white = (k + row) % 2 == 0
			kit.deco(model, Vector3.new(span / count, 0.05, sq), base * CFrame.new(x, 0.06, (row - 0.5) * sq), if white then Color3.fromRGB(235, 235, 230) else INK, Enum.Material.SmoothPlastic)
		end
	end
end

-- a jump ramp: a sloped kicker with yellow and black chevrons and a JUMP sign beside it
local function ramp(kit: any, parent: Instance, r: ChallengeData.Ramp)
	local model = Instance.new("Model")
	model.Name = "JumpRamp_" .. r.id
	model.Parent = parent
	local size = r.size
	local dir = r.cf.LookVector
	local foot = r.cf.Position
	local mid = foot + dir * (size.Z / 2) + Vector3.new(0, size.Y / 2, 0)
	-- (a wedge's slope faces its -Z: its back points the way you jump)
	kit.mk(model, size, CFrame.lookAt(mid, mid - dir), Color3.fromRGB(70, 72, 78), Enum.Material.DiamondPlate, { class = "Wedge", name = "Ramp" })
	-- chevrons up the slope and edge stripes
	local slopeLen = math.sqrt(size.Y * size.Y + size.Z * size.Z)
	local pitch = math.atan2(size.Y, size.Z)
	local slope = CFrame.lookAt(foot + Vector3.new(0, 0.1, 0), foot + Vector3.new(0, 0.1, 0) + dir) * CFrame.Angles(pitch, 0, 0)
	for k = 1, 4 do
		local along = slopeLen * k / 5
		for _, sx in { -1, 1 } do
			kit.deco(model, Vector3.new(size.X * 0.32, 0.08, 1.2), slope * CFrame.new(sx * size.X * 0.16, 0.08, -along) * CFrame.Angles(0, sx * 0.6, 0), YELLOW, Enum.Material.SmoothPlastic)
		end
	end
	for _, sx in { -1, 1 } do
		kit.deco(model, Vector3.new(0.8, 0.1, slopeLen), slope * CFrame.new(sx * (size.X / 2 - 0.4), 0.06, -slopeLen / 2), YELLOW, Enum.Material.SmoothPlastic)
	end
	-- the sign beside the foot
	local sp = foot + r.cf.RightVector * (size.X / 2 + 5)
	kit.mk(model, Vector3.new(0.6, 8, 0.6), CFrame.new(sp + Vector3.new(0, 4, 0)), CHROME, Enum.Material.Metal)
	local sign = kit.deco(model, Vector3.new(7, 3.4, 0.4), CFrame.lookAt(sp + Vector3.new(0, 8.6, 0), sp + Vector3.new(0, 8.6, 0) - dir), INK, Enum.Material.SmoothPlastic)
	screen(sign, Enum.NormalId.Front, "JUMP", Vector2.new(200, 100))
end

-- the leaderboard board on the city-centre corner
local function leaderboard(kit: any, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Leaderboard"
	model.Parent = parent
	local p = ChallengeData.boardPos
	-- facing the junction (diagonally back towards the city's middle)
	local face = Vector3.new(-1, 0, 1).Unit
	local cf = CFrame.lookAt(p + Vector3.new(0, 9, 0), p + Vector3.new(0, 9, 0) + face)
	for _, sx in { -1, 1 } do
		kit.mk(model, Vector3.new(0.8, 18, 0.8), cf * CFrame.new(sx * 9.5, -0.5, 0.4), CHROME, Enum.Material.Metal)
	end
	local panel = kit.mk(model, Vector3.new(20, 11, 0.6), cf * CFrame.new(0, 3, 0), INK, Enum.Material.SmoothPlastic, { name = "LeaderboardPanel" })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 440)
	gui.LightInfluence = 0
	gui.Parent = panel
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = INK
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.16, 0)
	title.BackgroundColor3 = YELLOW
	title.BorderSizePixel = 0
	title.Font = Enum.Font.GothamBlack
	title.Text = "CITY LEGENDS  ·  LEADERBOARD"
	title.TextScaled = true
	title.TextColor3 = INK
	title.Parent = bg
	for k, key in { "speed", "drift" } do
		local l = Instance.new("TextLabel")
		l.Position = UDim2.new((k - 1) * 0.5 + 0.02, 0, 0.2, 0)
		l.Size = UDim2.new(0.46, 0, 0.76, 0)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.GothamBold
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.TextColor3 = Color3.fromRGB(240, 240, 236)
		l.Text = if key == "speed" then "TOP SPEED\nno one yet" else "BEST DRIFT\nno one yet"
		l.Parent = bg
		boardLabels[key] = l
	end
end

function Challenges.buildWorld(kit: any, parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Challenges"
	folder.Parent = parent
	for _, t in ChallengeData.traps do
		gantry(kit, folder, t)
	end
	for _, r in ChallengeData.ramps do
		ramp(kit, folder, r)
	end
	leaderboard(kit, folder)
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
function Challenges.init(c: any)
	ctx = c
	event = ctx.remote("RemoteEvent", "ChallengeEvent")
	local report: RemoteEvent = ctx.remote("RemoteEvent", "ChallengeReport")
	report.OnServerEvent:Connect(function(player: Player, kind: any, a: any, b: any)
		if kind == "trap" then
			onTrap(player, a, b)
		elseif kind == "drift" then
			onDrift(player, a, b)
		elseif kind == "stunt" then
			onStunt(player, a, b)
		end
	end)
	local boardCall: RemoteFunction = ctx.remote("RemoteFunction", "ChallengeBoard")
	boardCall.OnServerInvoke = function(player: Player)
		local d = data(player)
		return { speed = top.speed, drift = top.drift, mine = if d then { speed = bestSpeed(d), drift = d.drift, air = d.air, traps = d.traps } else nil }
	end
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
	task.spawn(function()
		while true do
			refreshTop()
			task.wait(K.BoardRefresh)
		end
	end)
end

return Challenges
