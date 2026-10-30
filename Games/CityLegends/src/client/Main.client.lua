--[[
	CITY LEGENDS - client entry point
	loading -> intro cutscene -> main menu (orbiting city camera) -> garage -> drive
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))

local UI = require(script.Parent:WaitForChild("UI"))
local Traffic = require(script.Parent:WaitForChild("Traffic"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Cutscene = require(script.Parent:WaitForChild("Cutscene"))
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
UI.showLoading("Shaping the cars...")
CarSkin.preload({ Cars.CutsceneId })
UI.showLoading("Starting engines...")
task.wait(1) -- let the world finish replicating

---------------------------------------------------------------------
-- World effects: lights, searchlights, billboards, monorail
---------------------------------------------------------------------
if city then
	UI.showLoading("Painting the skyline...")
	BuildingSkin.apply(city)
	-- our own far stand-ins for streamed-out buildings (Roblox's showed as black shapes)
	require(script.Parent:WaitForChild("Standins")).init(city)
end
-- knockable street lights, trees and traffic poles (scanned before the LOD system hides far ones)
require(script.Parent:WaitForChild("Knockables")).init()
WorldFx.start()
Weather.init() -- rain cycle (starts raining), wet roads, mist, rain sound
require(script.Parent:WaitForChild("DayCycle")).start() -- morning, day, sunset, night

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
-- Intro cutscene
---------------------------------------------------------------------
Cutscene.play()

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
	require(script.Parent:WaitForChild("LuxeClient")).init() -- casino VIP, the gem shop, heist messages
end)
startStep("Minimap", function()
	require(script.Parent:WaitForChild("Minimap")).start() -- round minimap, top right (N toggles)
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
				local trims = Config.brandTrimBonus(lvl)
				UI.popup(brand .. " BRAND LV " .. lvl, 0, Config.Theme.Accent2)
				UI.toast(off .. "% off at Legends Customs" .. (if trims > 0 then ", its trims " .. trims .. " level" .. (if trims > 1 then "s" else "") .. " sooner" else ""), Config.Theme.Accent2)
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

DealerOpen.OnClientEvent:Connect(function(carId: any)
	openGarage(false, true, if type(carId) == "string" then carId else nil)
end)

showMenu = function()
	UI.showHud(false)
	startOrbit()
	UI.showMainMenu(data.Cash, function()
		UI.hideMainMenu()
		openGarage(true)
	end)
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
