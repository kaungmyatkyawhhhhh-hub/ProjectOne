--[[
	Police (server)
	Wanted level (0-5 stars, the player's "Wanted" attribute), speed cameras, fines and bounties
	(owner, 2026-10-22: "add speed camera around the map and if you go faster than the speed limit
	which will be 120kmh the police will chase you").
	  * speed cameras stand along the city avenues and the Legends Loop: passing one above the
	    limit flashes you, fines you and calls the police (1 star at least)
	  * the police cars themselves are driven on each player's own client (smooth, like traffic);
	    the client reports when they catch you (busted: fine, stars cleared, loot lost) or when you
	    get away (escaped: a bounty and XP)
	  * hitting a police car or speeding past a patrol raises the stars; a long chase escalates
	  * other systems (the bank) raise the level with Police.setWanted
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local P = Config.Police
local C = Config.City

local Police = {}

export type Camera = { pos: Vector3, face: Vector3, id: number }
Police.cameras = {} :: { Camera }

type Track = { since: number, lastRaise: number, lastFlash: { [number]: number }, escalate: number }
local tracks: { [Player]: Track } = {}
local ctx: any
local PoliceEvent: RemoteEvent
-- called when a player is busted (the bank takes back the loot)
Police.onBusted = {} :: { (player: Player) -> () }

local function track(player: Player): Track
	local t = tracks[player]
	if not t then
		t = { since = 0, lastRaise = 0, lastFlash = {}, escalate = 0 }
		tracks[player] = t
	end
	return t
end

function Police.getWanted(player: Player): number
	return (player:GetAttribute("Wanted") :: number?) or 0
end

function Police.setWanted(player: Player, level: number, reason: string?)
	level = math.clamp(math.floor(level), 0, 5)
	local old = Police.getWanted(player)
	if level == old then
		return
	end
	local t = track(player)
	if old == 0 and level > 0 then
		t.since = os.clock()
	end
	t.lastRaise = os.clock()
	t.escalate = 0
	player:SetAttribute("Wanted", level)
	PoliceEvent:FireClient(player, { kind = "wanted", level = level, old = old, reason = reason })
end

local function kmhOf(part: BasePart): number
	local v = part.AssemblyLinearVelocity
	return Config.spsToMph(Vector3.new(v.X, 0, v.Z).Magnitude) * 1.609
end

---------------------------------------------------------------------
-- Speed cameras: where they stand (deterministic) and how they look
---------------------------------------------------------------------
local function cameraSpots(): { Camera }
	local spots: { Camera } = {}
	local graph = CityLayout.buildGraph()
	local halfRoad = C.RoadWidth / 2
	-- city: every few long straight lanes, on the sidewalk at the right of the travel direction
	local k = 0
	for _, seg in graph.lanes do
		if seg.kind == "lane" and seg.signal and seg.i >= 0 and seg.length > 180 and seg.lane == C.LanesPerSide then
			k += 1
			if k % P.CityCameraEvery == 0 then
				local pos, dir = CityLayout.sample(seg, seg.length * 0.45)
				local right = dir:Cross(Vector3.yAxis)
				local edge = halfRoad - CityLayout.laneOffset(seg.lane)
				table.insert(spots, { pos = pos + right * (edge + 3.5), face = -dir, id = #spots + 1 })
			end
		end
	end
	-- the Legends Loop: both shoulders at even steps round the ring
	local L = CityLayout.loopLength()
	local half = C.HighwayWidth / 2
	for i = 0, P.LoopCameras - 1 do
		local s = (i + 0.3) * L / P.LoopCameras
		local outer, dir = CityLayout.loopSample(s, half + 6)
		local inner = CityLayout.loopSample(s + 40, -(half + 6))
		table.insert(spots, { pos = outer, face = -dir, id = #spots + 1 })
		table.insert(spots, { pos = inner, face = dir, id = #spots + 1 })
	end
	return spots
end

local function buildCamera(parent: Instance, cam: Camera)
	local model = Instance.new("Model")
	model.Name = "SpeedCamera" .. cam.id
	local base = CFrame.lookAt(cam.pos, cam.pos + cam.face)
	local function part(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.CastShadow = false
		p.Parent = model
		return p
	end
	local poleColor = Color3.fromRGB(70, 72, 78)
	local pole = part(Vector3.new(14, 0.9, 0.9), base * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.rad(90)), poleColor, Enum.Material.Metal, Enum.PartType.Cylinder)
	pole.Name = "Pole"
	-- the housing: a yellow box with a dark lens facing the traffic coming at it
	local housing = part(Vector3.new(2.4, 2.2, 3.2), base * CFrame.new(0, 13.2, 0), Color3.fromRGB(235, 190, 30), Enum.Material.SmoothPlastic)
	housing.Name = "Housing"
	part(Vector3.new(2.6, 0.25, 3.6), base * CFrame.new(0, 14.4, 0.2), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	local lens = part(Vector3.new(1.3, 1.3, 0.3), base * CFrame.new(0, 13.2, -1.65), Color3.fromRGB(15, 15, 20), Enum.Material.Glass)
	lens.Name = "Lens"
	local led = part(Vector3.new(0.3, 0.3, 0.1), base * CFrame.new(0.8, 14, -1.62), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	led.Name = "Led"
	local flash = Instance.new("PointLight")
	flash.Name = "Flash"
	flash.Color = Color3.fromRGB(255, 250, 235)
	flash.Range = 40
	flash.Brightness = 0
	flash.Shadows = false
	flash.Enabled = false -- on only for the flash itself (60 dark lights still cost frames)
	flash.Parent = lens
	-- the limit sign below it: a white disc with a red ring and "120"
	local sign = part(Vector3.new(0.2, 3.4, 3.4), base * CFrame.new(0, 9.2, -0.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(245, 245, 245), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	sign.Name = "LimitSign"
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right -- the disc's face towards the oncoming traffic
	gui.CanvasSize = Vector2.new(200, 200)
	gui.LightInfluence = 0.4
	gui.Parent = sign
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	ring.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(210, 20, 20)
	stroke.Thickness = 22
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = ring
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = tostring(P.SpeedLimitKmh)
	txt.Font = Enum.Font.GothamBlack
	txt.TextScaled = true
	txt.TextColor3 = Color3.fromRGB(15, 15, 15)
	txt.Parent = ring
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.22, 0)
	pad.PaddingBottom = UDim.new(0.22, 0)
	pad.PaddingLeft = UDim.new(0.16, 0)
	pad.PaddingRight = UDim.new(0.16, 0)
	pad.Parent = txt
	model:SetAttribute("CameraId", cam.id)
	model.Parent = parent
end

---------------------------------------------------------------------
-- Busted / escaped
---------------------------------------------------------------------
local function busted(player: Player)
	if Police.getWanted(player) <= 0 then
		return
	end
	local profile = PlayerData.get(player)
	local cash = if profile then profile.Cash else 0
	local fine = math.clamp(math.floor(cash * P.BustedFineFrac), P.BustedFineMin, P.BustedFineMax)
	fine = math.min(fine, cash)
	PlayerData.addCash(player, -fine)
	Police.setWanted(player, 0, "busted")
	for _, f in Police.onBusted do
		task.spawn(f, player)
	end
	PoliceEvent:FireClient(player, { kind = "busted", fine = fine })
end

local function escaped(player: Player)
	local stars = Police.getWanted(player)
	if stars <= 0 then
		return
	end
	local t = track(player)
	if os.clock() - t.since < P.MinChaseSeconds then
		return -- too quick to be real
	end
	local reward = P.EscapeBounty[stars] or 0
	PlayerData.addCash(player, reward)
	ctx.grantXp(player, P.EscapeXp * stars, "escape")
	ctx.note(player, "escapes", 1)
	Police.setWanted(player, 0, "escaped")
	PoliceEvent:FireClient(player, { kind = "escaped", reward = reward, stars = stars })
end

function Police.init(c: any)
	ctx = c
	PoliceEvent = ctx.remote("RemoteEvent", "PoliceEvent")
	local PoliceReport: RemoteEvent = ctx.remote("RemoteEvent", "PoliceReport")

	-- the cameras
	Police.cameras = cameraSpots()
	local folder = Instance.new("Folder")
	folder.Name = "SpeedCameras"
	for _, cam in Police.cameras do
		buildCamera(folder, cam)
	end
	folder.Parent = workspace

	PoliceReport.OnServerEvent:Connect(function(player: Player, kind: any)
		local t = track(player)
		local stars = Police.getWanted(player)
		if kind == "busted" then
			busted(player)
		elseif kind == "escaped" then
			escaped(player)
		elseif kind == "spotted" then
			-- speeding past a patrol car
			if stars == 0 then
				Police.setWanted(player, 1, "spotted")
			end
		elseif kind == "rammed" then
			if os.clock() - t.lastRaise > P.RamCooldown then
				Police.setWanted(player, math.max(stars + 1, 2), "rammed")
			end
		end
	end)

	-- cameras + escalation
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local car = ctx.getCar(player)
				local root = if car and not car:GetAttribute("Parked") then car.PrimaryPart else nil
				local t = track(player)
				if root then
					local pos = root.Position
					for _, cam in Police.cameras do
						local d = Vector3.new(pos.X - cam.pos.X, 0, pos.Z - cam.pos.Z).Magnitude
						if d < P.CameraRange and now - (t.lastFlash[cam.id] or -1e9) > P.CameraCooldown then
							local kmh = kmhOf(root)
							if kmh > P.SpeedLimitKmh + P.CameraGraceKmh then
								t.lastFlash[cam.id] = now
								local fine = P.CameraFine + math.floor((kmh - P.SpeedLimitKmh) * P.FinePerKmh)
								local profile = PlayerData.get(player)
								fine = math.min(fine, if profile then profile.Cash else 0)
								PlayerData.addCash(player, -fine)
								local stars = Police.getWanted(player)
								if stars < P.CameraStars then
									Police.setWanted(player, P.CameraStars, "camera")
								end
								PoliceEvent:FireAllClients({ kind = "flash", id = cam.id, pos = cam.pos })
								PoliceEvent:FireClient(player, { kind = "camera", kmh = math.floor(kmh), fine = fine, limit = P.SpeedLimitKmh })
							end
						end
					end
				end
				-- a long chase draws more units
				local stars = Police.getWanted(player)
				if stars > 0 and stars < P.EscalateMax then
					t.escalate += 0.1
					if t.escalate > P.EscalateSeconds then
						Police.setWanted(player, stars + 1, "escalate")
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		tracks[player] = nil
	end)
end

return Police
