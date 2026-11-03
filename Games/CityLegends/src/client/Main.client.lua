--[[
	CITY LEGENDS - client entry point
	loading (over the whole map) -> main menu (orbiting city camera) -> garage -> drive
	(the intro film is off since 2026-10-30, owner: "remove the intro")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local UI = require(script.Parent:WaitForChild("UI"))
local Traffic = require(script.Parent:WaitForChild("Traffic"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local BuildingSkin = require(script.Parent:WaitForChild("BuildingSkin"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Weather = require(script.Parent:WaitForChild("Weather"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local Police = require(script.Parent:WaitForChild("Police"))
local BankClient = require(script.Parent:WaitForChild("BankClient"))
local Activities = require(script.Parent:WaitForChild("Activities"))
local Pedestrians = require(script.Parent:WaitForChild("Pedestrians"))
local HouseClient = require(script.Parent:WaitForChild("HouseClient"))
local ChauffeurClient = require(script.Parent:WaitForChild("ChauffeurClient"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

require(script.Parent:WaitForChild("UIStyle")).init() -- one studio finish for every screen
UI.init()

-- the loading screen films the Monaco city (the Riviera) in slow cinematic shots, like the main menu
-- (owner, 2026-11-02: "switch the loading screen to those city cinematic photos like the start
-- menu", "by the city i meant the monaco city"). The player stands in the old city while loading, so
-- the Riviera's streets aren't streamed in yet: the shots are wide ones from the sea and the hills,
-- filmed on the far-city stand-in (ReplicatedStorage.RivieraFar: every building, its lit windows,
-- the ground, the roads and the lamps, always on every client). A short dip to black between
-- shots; the menu camera takes over when loading is done. Without the Riviera: the old city.
UI.setLoadingCinematic(true)
require(script.Parent:WaitForChild("DayCycle")).start() -- (early: the loading shots get the game's light)
local loadingShotsConn: RBXScriptConnection? = nil
local function stopLoadingShots()
	if loadingShotsConn then
		loadingShotsConn:Disconnect()
		loadingShotsConn = nil
	end
end
do
	-- { from, look at, drift per second, field of view }
	local shots = {}
	local far = if workspace:FindFirstChild("Riviera") then ReplicatedStorage:WaitForChild("RivieraFar", 3) else nil
	if workspace:FindFirstChild("Riviera") and far then
		far.Parent = workspace -- (WorldFx's far-city switch picks it up from here later)
		shots = {
			-- (all from far off: the stand-in is made to be seen from a distance)
			{ Vector3.new(14600, 120, 2800), Vector3.new(14300, 50, 700), Vector3.new(-14, 0, 0), 58 }, -- from the sea
			{ Vector3.new(12600, 90, 2600), Vector3.new(13800, 40, 800), Vector3.new(12, 0, -3), 56 }, -- the harbour from the water
			{ Vector3.new(16800, 300, 2400), Vector3.new(14200, 30, 800), Vector3.new(-10, 0, 0), 60 }, -- high over the bay
			{ Vector3.new(11400, 420, -650), Vector3.new(14300, 0, 800), Vector3.new(10, 0, 4), 62 }, -- from above the summit
		}
	else
		local span = Config.City.HalfExtent * 1.7
		shots = {
			{ Vector3.new(-span * 0.42, 20, 5), Vector3.new(0, 10, 5), Vector3.new(16, 0, 0), 58 },
			{ Vector3.new(span * 0.42, 26, -4), Vector3.new(0, 10, 0), Vector3.new(-18, 0, 0), 55 },
		}
	end
	local SHOT = 4.6
	local t0 = os.clock()
	local lastShot = 0
	camera.CameraType = Enum.CameraType.Scriptable
	loadingShotsConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local k = math.floor(t / SHOT)
		local shot = shots[k % #shots + 1]
		local shotT = t - k * SHOT
		if k ~= lastShot then
			lastShot = k
			-- (a quick dip to black between shots, under the title)
			task.spawn(function()
				UI.fade(true, 0.01)
				UI.fade(false, 0.45)
			end)
		end
		local drift = shot[3] * shotT
		camera.CFrame = CFrame.lookAt(shot[1] + drift, shot[2] + drift)
		camera.FieldOfView = shot[4]
	end)
end
UI.showLoading("Loading sounds...")
Audio.musicKeyBlocked = Driving.isDriving -- in a car M is the gearbox
Audio.init() -- test-loads the Creator Store sounds (falls back to built-in ones)
UI.showLoading("Building the city...")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetData = remotes:WaitForChild("GetData") :: RemoteFunction
local BuyCar = remotes:WaitForChild("BuyCar") :: RemoteFunction
local SpawnCar = remotes:WaitForChild("SpawnCar") :: RemoteEvent
local Progress = remotes:WaitForChild("Progress") :: RemoteEvent
local ClaimDaily = remotes:WaitForChild("ClaimDaily") :: RemoteFunction

Driving.init()
OnFoot.init()

-- wait for the server to finish building the city
local city = workspace:WaitForChild("City", 60)
local readyBy = os.clock() + 60
while city and not city:GetAttribute("Ready") and os.clock() < readyBy do
	task.wait(0.2)
end
if not city then
	warn("[CityLegends] no City in Workspace after 60 s, going on without it")
end
-- Loading the map (owner, 2026-11-03: "add a loading screen to finish loading the map so that
-- players dont need to play with loading map and lag"): with streaming on, the map round the
-- player arrives over a few seconds. The loading screen stays up (the car held) until parts have
-- stopped arriving for a moment, then the game starts. SKIP (after 5 s, Playbook) still works.
local streamedIn = 0
for _, root in { workspace:FindFirstChild("Riviera"), city } do
	if root then
		root.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				streamedIn += 1
			end
		end)
	end
end
local MAP_QUIET_PARTS = 6 -- at most this many parts arriving per quarter second...
local MAP_QUIET_TIME = 1.5 -- ...for this long counts as loaded
local MAP_MAX_WAIT = 30
local function waitForMap(status: string)
	if not workspace.StreamingEnabled or not workspace:FindFirstChild("Riviera") then
		return
	end
	UI.showLoading(status)
	local t0 = os.clock()
	task.wait(1)
	local last, quiet = streamedIn, 0
	while os.clock() - t0 < MAP_MAX_WAIT and UI.loadingVisible() do
		task.wait(0.25)
		local added = streamedIn - last
		last = streamedIn
		if added <= MAP_QUIET_PARTS and not player.GameplayPaused then
			quiet += 0.25
			if quiet >= MAP_QUIET_TIME then
				break
			end
		else
			quiet = 0
		end
	end
end

UI.showLoading("Shaping the cars...")
UI.showLoading("Starting engines...")
task.wait(1) -- let the world finish replicating

---------------------------------------------------------------------
-- World effects: lights, searchlights, billboards, monorail
---------------------------------------------------------------------
if city then
	UI.showLoading("Painting the skyline...")
	-- a failed skin must never stop the start (2026-10-31: a locked Texture property did, and
	-- players were left with no menu and no character)
	local skinned, err = pcall(BuildingSkin.apply, city)
	if not skinned then
		warn("[CityLegends] BuildingSkin failed:", err)
	end
	-- our own far stand-ins for streamed-out buildings (Roblox's showed as black shapes)
	require(script.Parent:WaitForChild("Standins")).init(city)
end
-- knockable street lights, trees and traffic poles (scanned before the LOD system hides far ones)
require(script.Parent:WaitForChild("Knockables")).init()
WorldFx.start()
Weather.init() -- rain cycle (rare showers, starts clear), wet roads, mist, rain sound
-- (the day / night cycle runs since the loading screen: morning, day, sunset, night)

---------------------------------------------------------------------
-- Data
---------------------------------------------------------------------
local data = GetData:InvokeServer()
if not data then
	data = { Cash = Config.Economy.StartingCash, Owned = { "aurelia_s4" }, Selected = "aurelia_s4" }
end
UI.setCash(data.Cash, true)
UI.setProgress(tonumber(data.Level) or 1, tonumber(data.XP) or 0, tonumber(data.XPNeed) or Config.xpForLevel(tonumber(data.Level) or 1))
if type(data.DailyIn) == "number" then
	UI.setDaily(data.DailyIn)
end

-- settings kept with the profile: speed units (HUD + clusters) and the gearbox
local settings = if type(data.Settings) == "table" then data.Settings else {}
local SaveSettings = remotes:WaitForChild("SaveSettings") :: RemoteEvent
Driving.setUnits(if settings.Units == "kmh" then "kmh" else "mph")
Driving.setGearbox(if settings.Gearbox == "Manual" then "Manual" else "Auto")
UI.setGearboxLabel(Driving.gearbox)
UI.onUnitsChanged = function(units: string)
	settings.Units = units
	Driving.setUnits(units)
	SaveSettings:FireServer(settings)
end
UI.onGearboxChanged = function(mode: string)
	settings.Gearbox = mode
	Driving.setGearbox(mode)
	SaveSettings:FireServer(settings)
end
Driving.onGearboxChanged = function(mode: string) -- Q / E switched to manual
	settings.Gearbox = mode
	UI.setGearboxLabel(mode)
	SaveSettings:FireServer(settings)
end
-- Settings > Camera. A player with Reduced Motion on starts with shake and head movement off
-- (Playbook); what they pick is saved with the profile
do
	local calm = game:GetService("GuiService").ReducedMotionEnabled
	local saved = if type(settings.CamFx) == "table" then settings.CamFx else {}
	Driving.setCamFx({
		shake = if type(saved.shake) == "number" then saved.shake elseif calm then 0 else 1,
		head = if type(saved.head) == "number" then saved.head elseif calm then 0 else 1,
		blur = if type(saved.blur) == "boolean" then saved.blur else true,
		fov = if type(saved.fov) == "number" then saved.fov else nil,
	})
	UI.setCamFx(Driving.camFx)
	UI.onCamFxChanged = function(fx)
		Driving.setCamFx(fx)
		settings.CamFx = table.clone(Driving.camFx)
		SaveSettings:FireServer(settings)
	end
end

-- XP / level updates pushed by the server
Progress.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	local level = tonumber(info.level) or 1
	-- only cut-ups flash "+N XP"; driving XP trickles in quietly
	local gained = if info.source == "cut" then tonumber(info.gained) else nil
	UI.setProgress(level, tonumber(info.xp) or 0, tonumber(info.need) or Config.xpForLevel(level), gained)
	data.Level = level
	if info.levelUp then
		UI.levelUp(level, tonumber(info.reward) or 0)
	end
end)

-- daily gift (the server checks the 24h timer and pays it)
UI.onDailyClaim = function()
	local ok, result = pcall(function()
		return ClaimDaily:InvokeServer()
	end)
	if not ok or type(result) ~= "table" then
		UI.toast("Could not claim the gift, try again", Config.Theme.Danger)
		return
	end
	if type(result.readyIn) == "number" then
		UI.setDaily(result.readyIn)
	end
	if result.ok then
		-- the daily streak (Goals): day 1..6 cash, day 7 a free car
		if type(result.car) == "string" then
			UI.popup("DAY 7: FREE CAR", 0, Config.Theme.Accent2)
			UI.toast("Day " .. tostring(result.day) .. " streak: the " .. result.car .. " is yours! It's in your CARS", Config.Theme.Accent2)
		else
			UI.popup("DAY " .. tostring(result.day) .. " STREAK", tonumber(result.amount) or 0, Config.Theme.Accent2)
		end
	else
		UI.toast(tostring(result.message or "Your streak isn't ready yet"), Config.Theme.Warning)
	end
end

local function bindCash()
	local stats = player:WaitForChild("leaderstats", 30)
	local cash = stats and stats:WaitForChild("Cash", 10)
	if cash and cash:IsA("IntValue") then
		UI.setCash(cash.Value)
		cash.Changed:Connect(function(v)
			UI.setCash(v)
			data.Cash = v
		end)
	end
end
task.spawn(bindCash)

---------------------------------------------------------------------
-- Traffic (runs for the rest of the session)
---------------------------------------------------------------------
local function focusPoint(): Vector3?
	local root = Driving.getRoot()
	if root then
		return root.Position
	end
	return camera.CFrame.Position
end

RunService.Heartbeat:Connect(function(dt)
	Traffic.update(dt)
end)

---------------------------------------------------------------------
-- Menu camera: slow fly-through down the main avenue over the traffic
-- (the avenue is an open corridor, so the camera never clips a tower)
---------------------------------------------------------------------
local orbitConn: RBXScriptConnection? = nil
local function startOrbit()
	if orbitConn then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local travel = 0
	local span = Config.City.HalfExtent * 1.7
	orbitConn = RunService.RenderStepped:Connect(function(dt: number)
		-- Studio previews (Claude's lighting screenshots): a test script parks the menu camera
		local preview = workspace:GetAttribute("PreviewCam")
		if typeof(preview) == "CFrame" and RunService:IsStudio() then
			camera.CFrame = preview
			camera.Focus = preview * CFrame.new(0, 0, -40)
			camera.FieldOfView = 70
			return
		end
		if workspace:FindFirstChild("Riviera") then
			-- Monaco (owner, 2026-11-02: "switch it to monaco now"): a slow circle over the harbour
			-- basin (clear of every building up to 120 studs round it), looking across the water to the
			-- far shore as it turns: the harbour front, the Old Rock, the town on the hill; the server
			-- streams the Riviera in round the menu (StreamFocus)
			travel += dt
			local a = travel * (math.pi * 2 / 160)
			local centre = Vector3.new(13700, 0, 700)
			local off = Vector3.new(math.cos(a), 0, math.sin(a))
			local pos = centre + off * 105 + Vector3.new(0, 82 + math.sin(travel / 9) * 6, 0)
			local across = -(off + Vector3.new(-off.Z, 0, off.X) * 0.35).Unit
			camera.CFrame = CFrame.lookAt(pos, pos + across * 420 + Vector3.new(0, -55, 0))
			camera.FieldOfView = 64
			return
		end
		travel = (travel + dt * 22) % span
		local x = -span / 2 + travel
		local sway = math.sin(travel / 90) * 6
		local pos = Vector3.new(x, 46 + math.sin(travel / 140) * 8, sway)
		camera.CFrame = CFrame.lookAt(pos, Vector3.new(x + 140, 12, sway * 0.3))
		camera.FieldOfView = 62
	end)
end
local function stopOrbit()
	if orbitConn then
		orbitConn:Disconnect()
		orbitConn = nil
	end
end

stopLoadingShots()
startOrbit()
UI.showLoading("Filling the streets with traffic...")
UI.fade(false, 0.01)
-- each step runs on its own and is timed: one that errors or hangs is reported in the Output and
-- the rest still start (a crash in one of them used to leave the loading screen up for good)
local stepTimes = {}
local function startStep(name: string, fn: () -> ())
	local t0 = os.clock()
	local done, ok, err = false, true, nil
	task.spawn(function()
		ok, err = pcall(fn)
		done = true
	end)
	while not done and os.clock() - t0 < 8 do
		task.wait()
	end
	local took = os.clock() - t0
	table.insert(stepTimes, string.format("%s %.2fs", name, took))
	if not done then
		warn(string.format("[CityLegends] startup: %s still busy after %.1f s, going on", name, took))
	elseif not ok then
		warn(string.format("[CityLegends] startup: %s failed: %s", name, tostring(err)))
	end
end
startStep("Traffic", function()
	Traffic.start(math.floor(Config.Traffic.CarCount * math.clamp(WorldFx.qualityScale(), 0.6, 1)), focusPoint)
end)
startStep("Police", Police.init)
startStep("Bank", BankClient.init)
startStep("Activities", Activities.init)
startStep("Pedestrians", function()
	Pedestrians.start(WorldFx.qualityScale())
end)
startStep("Chauffeur", ChauffeurClient.init)
startStep("Luxe", function()
	require(script.Parent:WaitForChild("LuxeClient")).init() -- the gem shop and VIP cards, smash-and-grab messages
end)
startStep("Minimap", function()
	require(script.Parent:WaitForChild("Minimap")).start() -- round minimap, top right (N toggles)
end)
startStep("Rewards", function()
	require(script.Parent:WaitForChild("RewardsClient")).init() -- Legends Rewards: the REWARDS pill, the rewards screen, the wheels
end)
startStep("PhotoMode", function()
	require(script.Parent:WaitForChild("PhotoMode")).init()
end)
startStep("Goals", function()
	require(script.Parent:WaitForChild("GoalsClient")).init()
end)
startStep("Housing", function()
	require(script.Parent:WaitForChild("HousingClient")).init() -- Legends Realty, claiming lots, the house menu
end)
startStep("Challenges", function()
	require(script.Parent:WaitForChild("ChallengesClient")).init() -- drifts, speed traps, jumps, leaderboard (B)
end)
print("[CityLegends] startup: " .. table.concat(stepTimes, ", "))
waitForMap("Loading the map...")
UI.hideLoading()

---------------------------------------------------------------------
-- Spawning / garage
---------------------------------------------------------------------
local pendingAttach = false
-- (after loading; the cars need it, so keep asking, with a warning each time it's late)
local playerCars = workspace:WaitForChild("PlayerCars", 30) :: Folder?
while not playerCars do
	warn("[CityLegends] no PlayerCars folder in Workspace yet")
	playerCars = workspace:WaitForChild("PlayerCars", 30) :: Folder?
end

-- a car arrives in pieces: wait for all of them (the server counts them), or the body goes on
-- before the wheel joints are there and the car drives on without wheels
local function waitWhole(model: Instance)
	model:WaitForChild("Chassis", 5)
	local pieces = model:GetAttribute("Pieces")
	local deadline = os.clock() + 8
	while type(pieces) == "number" and #model:GetDescendants() < pieces and os.clock() < deadline do
		task.wait(0.05)
	end
	task.wait()
end

-- every player's car gets the smooth body locally
local function skinPlayerCar(model: Instance)
	if model:IsA("Model") then
		waitWhole(model)
		local okSkin, errSkin = pcall(CarSkin.apply, model, false)
		if not okSkin then
			warn("[CityLegends] car skin failed:", errSkin)
		end
	end
end
for _, existing in playerCars:GetChildren() do
	task.spawn(skinPlayerCar, existing)
end
playerCars.ChildAdded:Connect(function(model)
	if not (model:GetAttribute("Owner") == player.UserId and pendingAttach) then
		skinPlayerCar(model)
	end
end)

local function tryAttach(model: Instance)
	if model:IsA("Model") and model:GetAttribute("Owner") == player.UserId and pendingAttach then
		pendingAttach = false
		waitWhole(model)
		local okSkin, errSkin = pcall(CarSkin.apply, model, false)
		if not okSkin then
			warn("[CityLegends] car skin failed:", errSkin)
		end
		stopOrbit()
		OnFoot.reset()
		Traffic.clearAround(model:GetPivot().Position, 35)
		Driving.attach(model)
		-- (the streets round the car finish loading behind the loading screen, the car held)
		Driving.loadHold = true
		waitForMap("Loading the streets...")
		Driving.loadHold = false
		UI.hideLoading()
		UI.showHud(true)
		UI.setCameraLabel(Driving.cameraMode)
		UI.fade(false, 0.5)
	end
end
playerCars.ChildAdded:Connect(tryAttach)

-- stealFrom: a parked car in a tower garage (Parking): the server swaps it for a drivable one
local function requestDrive(id: string, stealFrom: Model?)
	pendingAttach = true
	UI.fade(true, 0.3)
	if stealFrom then
		(remotes:WaitForChild("StealCar") :: RemoteEvent):FireServer(stealFrom)
	else
		data.Selected = id
		SpawnCar:FireServer(id)
	end
	-- safety: if the car is already there (rare race) attach to it
	task.delay(0.5, function()
		if pendingAttach then
			local existing = playerCars:FindFirstChild(player.Name)
			if existing then
				tryAttach(existing)
			end
		end
	end)
	task.delay(6, function()
		if pendingAttach then
			pendingAttach = false
			UI.fade(false, 0.3)
			UI.toast("Could not spawn the car, try again", Config.Theme.Danger)
		end
	end)
end

-- the towers' garages: parked cars get their real bodies, and a finished "Steal" hold drives one off
local parkedFolder = workspace:WaitForChild("ParkedCars", 30)
if parkedFolder then
	local function skinParked(model: Instance)
		if model:IsA("Model") then
			task.delay(1, function()
				if model.Parent then
					pcall(CarSkin.apply, model, false, true)
				end
			end)
		end
	end
	for _, m in parkedFolder:GetChildren() do
		skinParked(m)
	end
	parkedFolder.ChildAdded:Connect(skinParked)
	-- the parked cars' bodies are only drawn near you (they're down in the towers' basements;
	-- 24 full car models drawn from across the city cost frames: owner 2026-10-24, optimise)
	task.spawn(function()
		local stored: { [Model]: Instance } = {}
		while true do
			task.wait(0.5)
			local cam = workspace.CurrentCamera.CFrame.Position
			for _, m in parkedFolder:GetChildren() do
				if m:IsA("Model") then
					local near = (m:GetPivot().Position - cam).Magnitude < 320
					local skin = m:FindFirstChild("Skin")
					if not near and skin then
						stored[m] = skin
						skin.Parent = nil
					elseif near and not skin and stored[m] then
						stored[m].Parent = m
						stored[m] = nil
					end
				end
			end
			for m in stored do
				if not m.Parent then
					stored[m] = nil
				end
			end
		end
	end)
end
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name ~= "StealCar" or not OnFoot.active then
		return
	end
	local model = prompt:FindFirstAncestorOfClass("Model")
	local id = if model then model:GetAttribute("CarId") else nil
	if model and type(id) == "string" then
		requestDrive(id, model)
	end
end)

-- the Legends Grand Hotel: the valet takes your car at the bay and brings it back to the door
require(script.Parent:WaitForChild("HotelClient")).init(requestDrive)
require(script.Parent:WaitForChild("CustomsClient")).init() -- Legends Customs (after the hotel: it chains the drive action)
-- car levels, Car Points and the parts screen (2026-11-03; the garage's UPGRADE, the HUD strip)
require(script.Parent:WaitForChild("CarUpgrades")).init()

local showMenu: () -> ()

-- island houses: a bay car's "Drive" spawns it on the driveway (the server picks the spot)
task.spawn(HouseClient.init, function(id: string)
	UI.closeGarage()
	requestDrive(id)
end)

-- Legends Motors, the dealership: its prompts open the buy screen, and cars leave by its bay
local DealerOpen = remotes:WaitForChild("DealerOpen") :: RemoteEvent
local DealerCall = remotes:WaitForChild("DealerCall") :: RemoteFunction

-- the garage: "my cars" from the HUD (CARS, G), or every car to buy at the dealership
local function openGarage(fromMenu: boolean, dealer: boolean?, focus: string?)
	local fresh = GetData:InvokeServer()
	if fresh then
		data = fresh
	end
	UI.openGarage(data, {
		buy = function(id: string)
			local result = BuyCar:InvokeServer(id)
			if result and result.data then
				data = result.data
			end
			return result or { ok = false, message = "Server did not respond" }
		end,
		testDrive = if dealer
			then function(id: string)
				pcall(function()
					DealerCall:InvokeServer("door")
				end)
				local ok, result = pcall(function()
					return (remotes:WaitForChild("TestDrive") :: RemoteFunction):InvokeServer(id)
				end)
				if ok and type(result) == "table" then
					return result
				end
				return { ok = false, message = "Server did not respond" }
			end
			else nil,
		drive = function(id: string)
			UI.hideMainMenu()
			if dealer then
				-- out of the dealership's drive-out bay
				pcall(function()
					DealerCall:InvokeServer("door")
				end)
			end
			requestDrive(id)
		end,
		close = function()
			if fromMenu and not Driving.isDriving() and not OnFoot.active then
				showMenu()
			end
		end,
		dealer = dealer,
		focus = focus,
	})
end

-- a brand level up (Brands): what it gives
do
	local HttpService = game:GetService("HttpService")
	local function read(): { [string]: number }
		local raw = player:GetAttribute("BrandLevels")
		local ok, t = pcall(function()
			return HttpService:JSONDecode(raw)
		end)
		return if ok and type(t) == "table" then t else {}
	end
	local known = read()
	player:GetAttributeChangedSignal("BrandLevels"):Connect(function()
		local now = read()
		for brand, lvl in now do
			if type(lvl) == "number" and lvl > (tonumber(known[brand]) or 1) then
				local off = math.floor((1 - Config.brandCustomsMult(lvl)) * 100 + 0.5)
				UI.popup(brand .. " BRAND LV " .. lvl, 0, Config.Theme.Accent2)
				UI.toast(off .. "% off at Legends Customs", Config.Theme.Accent2)
			end
		end
		known = now
	end)
end

-- a test drive's time running out: a word at 1 minute, 30 and 10 seconds, and when it's over
task.spawn(function()
	local said: { [number]: boolean } = {}
	local lastEnds: number? = nil
	while true do
		task.wait(0.5)
		local model = Driving.getModel()
		local ends = if model then model:GetAttribute("TestEnds") else nil
		if type(ends) == "number" then
			if ends ~= lastEnds then
				lastEnds = ends
				table.clear(said)
			end
			local left = ends - workspace:GetServerTimeNow()
			for _, mark in { 60, 30, 10 } do
				if left <= mark and left > mark - 2 and not said[mark] then
					said[mark] = true
					UI.toast("Test drive: " .. mark .. " seconds left", Config.Theme.Accent2)
				end
			end
			if left <= 0 and not said[0] then
				said[0] = true
				UI.toast("Test drive over: back in your own car", Config.Theme.Accent2)
			end
		end
	end
end)

-- the dealer menu (owner, 2026-10-31: like Midnight Racing's, DealerMenu)
local DealerMenu = require(script.Parent:WaitForChild("DealerMenu"))
DealerOpen.OnClientEvent:Connect(function(carId: any)
	if DealerMenu.isOpen() or UI.isGarageOpen() then
		return
	end
	local fresh = GetData:InvokeServer()
	if fresh then
		data = fresh
	end
	DealerMenu.open(data, {
		buy = function(id: string, colour: number?)
			local result = BuyCar:InvokeServer(id, colour)
			if result and result.data then
				data = result.data
			end
			return result or { ok = false, message = "Server did not respond" }
		end,
		testDrive = function(id: string)
			pcall(function()
				DealerCall:InvokeServer("door")
			end)
			local ok, result = pcall(function()
				return (remotes:WaitForChild("TestDrive") :: RemoteFunction):InvokeServer(id)
			end)
			if ok and type(result) == "table" then
				return result
			end
			return { ok = false, message = "Server did not respond" }
		end,
		drive = function(id: string)
			UI.hideMainMenu()
			-- out of the dealership's drive-out bay
			pcall(function()
				DealerCall:InvokeServer("door")
			end)
			requestDrive(id)
		end,
	}, if type(carId) == "string" then carId else nil)
end)

-- the main menu (owner, 2026-11-02: big tiles, CAMPAIGN / CARS / STORE): the start screen, and
-- from the HUD's MENU button (it replaced SETTINGS) while you play
local MainMenu = require(script.Parent:WaitForChild("MainMenu"))
local FastTravel = remotes:WaitForChild("FastTravel") :: RemoteFunction
local ClaimStarter = remotes:WaitForChild("ClaimStarter") :: RemoteFunction
MainMenu.init({
	getData = function()
		return data
	end,
	refresh = function()
		local fresh = GetData:InvokeServer()
		if fresh then
			data = fresh
		end
		return data
	end,
	drive = function(id: string)
		requestDrive(id)
	end,
	-- fast travel (the server checks it and says where): the car, or you on foot, onto the spot;
	-- from the start screen your car comes out there
	travel = function(spotId: string)
		local ok, result = pcall(function()
			return FastTravel:InvokeServer(spotId)
		end)
		if not ok or type(result) ~= "table" then
			return { ok = false, message = "The server didn't answer, try again" }
		end
		if not result.ok or typeof(result.cf) ~= "CFrame" then
			return result
		end
		local cf: CFrame = result.cf
		MainMenu.close()
		-- the ground there has to have reached this game first (streaming): wait for it, then sit
		-- the car or you on it
		local function ground(): RaycastResult?
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Exclude
			rp.FilterDescendantsInstances = { playerCars, player.Character :: any, workspace.CurrentCamera }
			-- (only solid ground: the far-city stand-in's ground is there before the real one streams in)
			rp.RespectCanCollide = true
			rp.IgnoreWater = true
			return workspace:Raycast(cf.Position + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rp)
		end
		local function settle(): boolean
			local deadline = os.clock() + 6
			local hit = ground()
			while not hit and os.clock() < deadline do
				task.wait(0.2)
				hit = ground()
			end
			-- (ground far under the spot: it's over water or a drop; don't put anyone there)
			if hit and hit.Position.Y > cf.Position.Y - 8 then
				cf = CFrame.new(hit.Position) * cf.Rotation
				return true
			end
			return false
		end
		if Driving.isDriving() then
			UI.fade(true, 0.25)
			task.wait(0.3)
			if not settle() then
				UI.fade(false, 0.3)
				UI.toast("Can't put the car there right now, try again", Config.Theme.Danger)
				return result
			end
			Driving.teleport(cf)
			Traffic.clearAround(cf.Position, 35)
			Driving.loadHold = true
			waitForMap("Loading the streets...")
			Driving.loadHold = false
			UI.hideLoading()
			UI.fade(false, 0.4)
		elseif OnFoot.active and player.Character then
			UI.fade(true, 0.25)
			task.wait(0.3)
			if settle() and player.Character then
				player.Character:PivotTo(cf + Vector3.new(0, 3, 0))
				waitForMap("Loading the streets...")
				UI.hideLoading()
			else
				UI.toast("Can't put you there right now, try again", Config.Theme.Danger)
				task.wait(0.5)
			end
			UI.fade(false, 0.4)
		elseif result.spawn and data.Selected then
			requestDrive(data.Selected)
		end
		return result
	end,
	claim = function(id: string)
		local ok, result = pcall(function()
			return ClaimStarter:InvokeServer(id)
		end)
		if not ok or type(result) ~= "table" then
			return { ok = false, message = "The server didn't answer, try again" }
		end
		if result.ok and type(result.data) == "table" then
			data = result.data
		end
		return result
	end,
	settings = settings,
	saveSettings = function()
		SaveSettings:FireServer(settings)
	end,
	openGoals = function()
		if UI.onGoalsButton then
			UI.onGoalsButton()
		end
	end,
	openMarket = function()
		require(script.Parent:WaitForChild("MarketUI")).open()
	end,
	openPhoto = function()
		if UI.onPhotoButton then
			UI.onPhotoButton()
		end
	end,
})
MainMenu.applySettings(settings)

-- Studio test hook (Claude's driving tests): player attribute TestCar = a car id drives it out
if RunService:IsStudio() then
	player:GetAttributeChangedSignal("TestCar"):Connect(function()
		local id = player:GetAttribute("TestCar")
		if type(id) == "string" and id ~= "" then
			if MainMenu.isOpen and MainMenu.isOpen() then
				MainMenu.close()
			end
			requestDrive(id)
		end
	end)
end

if settings.HideKeys then
	UI.toggleControls(false)
end
UI.onMenuButton = MainMenu.toggle

showMenu = function()
	UI.showHud(false)
	-- (the server streams the menu's part of the map in again: the Riviera)
	pcall(function()
		(remotes:WaitForChild("MenuFocus", 5) :: RemoteEvent):FireServer()
	end)
	startOrbit()
	MainMenu.open(true)
end

local function toggleGarage()
	if UI.isGarageOpen() then
		UI.closeGarage()
	else
		openGarage(false)
	end
end
UI.onGarageButton = toggleGarage
UI.onCameraButton = function()
	Driving.toggleCamera()
end

-- the car stock market (K or the MARKET button)
local MarketUI = require(script.Parent:WaitForChild("MarketUI"))
MarketUI.init()
UI.onMarketButton = MarketUI.toggle

-- put your car away (owner, 2026-10-23: "add a function to despawn car"): out of it first if
-- you're in it, then the server removes it; G brings one back from the garage
local despawnRemote = remotes:WaitForChild("DespawnCar") :: RemoteEvent
local function despawnCar()
	if Driving.isDriving() then
		OnFoot.getOut()
		if Driving.isDriving() then
			return -- couldn't get out (too fast): OnFoot said why
		end
	end
	if not OnFoot.active then
		return
	end
	despawnRemote:FireServer()
	UI.toast("Car put away · G for the garage", Config.Theme.Accent)
end
UI.onDespawnButton = despawnCar

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G and (Driving.isDriving() or OnFoot.active) then
		toggleGarage()
	elseif input.KeyCode == Enum.KeyCode.Delete then
		despawnCar()
	end
end)

showMenu()
