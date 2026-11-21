--[[
	CITY LEGENDS - client entry point
	loading (over the whole map) -> main menu (orbiting city camera) -> garage -> drive
	(the intro film is off since 2026-10-30, owner: "remove the intro")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- (21 Nov, owner: "make the loading screen ingame load fast") each startup phase's time since this script
-- started, printed with the menu: "startup phases: requires 0.4, sounds 0.4, ..."
local startT0 = os.clock()
local phaseLog: { string } = {}
local function phase(name: string)
	table.insert(phaseLog, string.format("%s %.2f", name, os.clock() - startT0))
end

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
require(script.Parent:WaitForChild("LangUI")).init() -- (19 Nov) every screen in the player's language (Strings)
UI.init()

-- the loading screen films the Monaco city (the Riviera) in slow cinematic shots, like the main menu
-- (owner, 2026-11-02: "switch the loading screen to those city cinematic photos like the start
-- menu", "by the city i meant the monaco city"). The player stands in the old city while loading, so
-- the Riviera's streets aren't streamed in yet: the shots are wide ones from the sea and the hills,
-- filmed on the far-city stand-in (ReplicatedStorage.RivieraFar: every building, its lit windows,
-- the ground, the roads and the lamps, always on every client). A short dip to black between
-- shots; the menu camera takes over when loading is done. Without the Riviera: the old city.
UI.setLoadingCinematic(true)
UI.setLoadingHold(true) -- (owner, 2026-11-21: "i am stuck in black screen after skipping loading": SKIP can't bare the view before the menu exists)
require(script.Parent:WaitForChild("DayCycle")).start() -- (early: the loading shots get the game's light)
require(script.Parent:WaitForChild("LookFx")).start()
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
	local far = if workspace:FindFirstChild("Riviera") and not workspace:FindFirstChild("Yangon") then ReplicatedStorage:WaitForChild("RivieraFar", 3) else nil
	local ready: { (() -> boolean)? } = {} -- (Yangon: a shot is cut to only once its ground has streamed in)
	if Config.activeMap() == "Yangon" then
		-- (owner, 19 Nov: "the scenes are inside of the buildings") the 1:1 shots live in Shared.MenuShots:
		-- the server checks each one in open air at start and the server streams their spots in for us
		local MenuShots = require(Shared:WaitForChild("MenuShots"))
		local function fill()
			table.clear(shots)
			table.clear(ready)
			for _, s in MenuShots.good() do
				table.insert(shots, { s.from, s.at, s.drift, s.fov })
				table.insert(ready, function()
					return MenuShots.streamed(s)
				end)
			end
		end
		fill() -- (the fallback until the server's check is in: a first player in a fresh server)
		workspace:GetAttributeChangedSignal("MenuShots"):Connect(fill)
	elseif workspace:FindFirstChild("Riviera") and far then
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
	local at = 1 -- the shot on screen
	camera.CameraType = Enum.CameraType.Scriptable
	loadingShotsConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local k = math.floor(t / SHOT)
		local shotT = t - k * SHOT
		if k ~= lastShot then
			lastShot = k
			-- the next shot whose spot has streamed in (the first, by the spawn, always has)
			for n = 1, #shots do
				local i = (at + n - 1) % #shots + 1
				if not ready[i] or (ready[i] :: () -> boolean)() or n == #shots then
					at = i
					break
				end
			end
			-- (a quick dip to black between shots, under the title)
			task.spawn(function()
				UI.fade(true, 0.01)
				UI.fade(false, 0.45)
			end)
		end
		local shot = shots[at] or shots[1]
		local drift = shot[3] * shotT
		camera.CFrame = CFrame.lookAt(shot[1] + drift, shot[2] + drift)
		camera.FieldOfView = shot[4]
	end)
end
phase("requires")
UI.showLoading("Loading sounds...")
Audio.musicKeyBlocked = Driving.isDriving -- in a car M is the gearbox
Audio.init() -- test-loads the Creator Store sounds (falls back to built-in ones)
phase("sounds")
UI.showLoading("Building the city...")

local pendingAttach = false
local attaching = false -- (the watchdog waits while a car is being put on)
local showMenu: () -> ()
local MainMenu: any = nil
-- Watchdog (19 Nov, owner: "the loading screen sometimes doesnt load in and i get stuck with no GUI
-- after pressing skip / waiting a while"): once nothing is loading or on its way, there must be
-- something to use on screen: the HUD, the main menu or a full screen (garage, dealer, customs,
-- workshop; photo mode hides everything on purpose). Nothing for 6 s: the black fade goes and the HUD
-- (in a car or on foot) or the main menu comes back.
-- (owner, 2026-11-21: "i am stuck in black screen after skipping loading") started here, before the long
-- waits, so it covers startup too: until the menu can open, a bare view gets the loading screen back
task.spawn(function()
	local Guard = require(Shared:WaitForChild("StartupGuard"))
	local idle = 0
	while true do
		task.wait(1)
		local hud = UI.screen():FindFirstChild("HUD") :: Frame?
		local action = Guard.watch({
			startup = UI.loadingHeld(),
			loading = UI.loadingVisible(),
			busy = pendingAttach or attaching,
			gui = (hud ~= nil and hud.Visible) or (MainMenu ~= nil and MainMenu.isOpen()) or UI.isGarageOpen() or not UI.screen().Enabled,
			inGame = Driving.isDriving() or (OnFoot.active and player.Character ~= nil),
		})
		idle = if action == "ok" then 0 else idle + 1
		if action ~= "ok" and idle >= Guard.After[action] then
			idle = 0
			warn("[CityLegends] watchdog: no GUI for " .. Guard.After[action] .. " s, showing the " .. action)
			if action == "loading" then
				UI.showLoading("Still loading the city...")
			else
				task.spawn(UI.fade, false, 0.3)
				if action == "hud" then
					UI.showHud(true)
				else
					showMenu()
				end
			end
		end
	end
end)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
-- (19 Nov, owner: "stuck with no GUI after pressing skip") a remote the server never made (one of its
-- systems failed at start) used to hold this script forever, before the main menu: wait 10 s at
-- most, report it, and go on with a stand-in that never fires
local function remote(name: string, className: string): any
	local r = remotes:WaitForChild(name, 10)
	if not r then
		warn("[CityLegends] startup: remote " .. name .. " missing after 10 s, going on without it")
		r = Instance.new(className)
		r.Name = name
	end
	return r
end
local GetData = remotes:WaitForChild("GetData") :: RemoteFunction
local BuyCar = remotes:WaitForChild("BuyCar") :: RemoteFunction
local SpawnCar = remotes:WaitForChild("SpawnCar") :: RemoteEvent
local Progress = remotes:WaitForChild("Progress") :: RemoteEvent
local ClaimDaily = remotes:WaitForChild("ClaimDaily") :: RemoteFunction

phase("remotes")
-- (21 Nov) the profile is asked for now and picked up after the world setup below (it waits on the DataStore load)
local dataAsked: any, dataIn = nil, false
task.spawn(function()
	local ok, got = pcall(GetData.InvokeServer, GetData)
	dataAsked = if ok then got else nil
	if not ok then
		warn("[CityLegends] GetData failed:", got)
	end
	dataIn = true
end)
Driving.init()
OnFoot.init()

-- wait for the server to finish building the city
local city = workspace:WaitForChild("City", 60)
local readyBy = os.clock() + 60
while city and not city:GetAttribute("Ready") and os.clock() < readyBy do
	task.wait(0.2)
end
phase("city")
if not city then
	warn("[CityLegends] no City in Workspace after 60 s, going on without it")
end
-- Loading the map (owner, 2026-11-03: "add a loading screen to finish loading the map so that
-- players dont need to play with loading map and lag"): with streaming on, the map round the
-- player arrives over a few seconds. The loading screen stays up (the car held) until parts have
-- stopped arriving for a moment, then the game starts. SKIP (after 5 s, Playbook) still works.
local streamedIn = 0
-- (21 Nov) the start waits only for the part of the map the menu camera looks at (parts arriving within NEAR_R of
-- nearAt): the whole streaming radius took ~7 s in Studio Play (8,000 parts), the menu's view is in well before
local NEAR_R = 800
local nearAt: Vector3? = nil
local streamedNear = 0
for _, root in { workspace:FindFirstChild("Riviera"), Config.mapRoot(), city } do
	if root then
		root.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				streamedIn += 1
				local at = nearAt
				if at and (d.Position - at).Magnitude < NEAR_R then
					streamedNear += 1
				end
			end
		end)
	end
end
local MAP_QUIET_PARTS = 6 -- at most this many parts arriving per quarter second...
local MAP_QUIET_TIME = 1 -- ...for this long counts as loaded after a jump (was 1.5 behind a fixed 1 s wait)
local MAP_QUIET_STAY = 0.5 -- (21 Nov) no jump (the start, under the menu's own streamed spot): this long
local MAP_MAX_WAIT = 30
-- (21 Nov) a spot within this of where the camera just was is no jump: its terrain is already drawn up close
local JUMP_FAR = 600
-- (21 Nov, owner: "the map loading is bugged and sometimes it dont fully load") after a jump the terrain's data
-- is in within ~1 s, but its fine meshes are drawn seconds later: until then a coarse terrain sheet lies 15+ studs
-- over the roads (only kerbs and tall things show). Studio Play on a PC: covered at 1.5 s, clear by ~3.5 s, while the
-- parts go quiet at ~2.6 s. So a jump keeps the screen up a little longer; phones mesh terrain slower.
-- (21 Nov, "make the loading screen ingame load fast") the terrain time now runs from the jump itself, alongside the
-- parts wait (it used to start only after the parts went quiet: 1.5 / 4 s on top), and a spot near where the camera
-- just was is no jump at all (the menu orbits 420+ studs up, so the first car out still counts as one). The values
-- are from the jump: PC 4 s = the measured "clear at 3.5-4 s" (the old end was 4.1 s); phones = the old 2.6 s parts
-- wait + its 4 s guess. (Terrain graphics memory never settles soon after a jump: no usable "meshes done" signal.)
local TERRAIN_SETTLE = 4
local TERRAIN_SETTLE_PHONE = 6.5 -- shortcut: a guess (not measured on a phone), tune from a phone test
-- is `to` far from where the camera is now (call before moving the car or the camera there)
local function isJump(to: Vector3): boolean
	return (to - camera.CFrame.Position).Magnitude > JUMP_FAR
end
local function waitForMap(status: string, jumped: boolean?, near: Vector3?)
	if not workspace.StreamingEnabled or not Config.activeMap() then
		return
	end
	UI.showLoading(status)
	local t0 = os.clock()
	local parts0 = streamedIn
	nearAt = near
	streamedNear = 0
	local function arrived(): number
		return if near then streamedNear else streamedIn
	end
	local settleBy = 0
	if jumped then
		local phone = UI.isTouch or require(script.Parent:WaitForChild("LowEnd")).on
		settleBy = t0 + (if phone then TERRAIN_SETTLE_PHONE else TERRAIN_SETTLE)
		task.wait(0.5) -- (streaming round the new spot gets going)
	end
	local need = if jumped then MAP_QUIET_TIME else MAP_QUIET_STAY
	local last, quiet = arrived(), 0
	local tQuiet = nil
	while os.clock() - t0 < MAP_MAX_WAIT and UI.loadingWaiting() do
		task.wait(0.25)
		local added = arrived() - last
		last = arrived()
		if added <= MAP_QUIET_PARTS and not player.GameplayPaused then
			quiet += 0.25
			-- (a quiet spot must also have its city in: 300 parts within 400 studs, MenuShots' own test)
			if quiet >= need and (not near or #workspace:GetPartBoundsInRadius(near, 400) >= 300) then
				tQuiet = tQuiet or os.clock() - t0
				if os.clock() >= settleBy then
					break
				end
			end
		else
			quiet = 0
			tQuiet = nil
		end
	end
	nearAt = nil
	print(string.format("[CityLegends] map wait '%s'%s: parts quiet %.2fs (%d parts, %s), total %.2fs", status, if jumped then " (jump)" else "", tQuiet or -1, streamedIn - parts0, if near then streamedNear .. " near" else "all", os.clock() - t0))
end

UI.showLoading("Shaping the cars...")
UI.showLoading("Starting engines...")
-- (21 Nov) the old 1 s "let the world finish replicating" wait is gone: the City's Ready flag is in by now, and the
-- map round the menu is waited for in waitForMap

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
	phase("skin")
	require(script.Parent:WaitForChild("Standins")).init(city)
	phase("standins")
end
-- knockable street lights, trees and traffic poles (scanned before the LOD system hides far ones)
require(script.Parent:WaitForChild("Knockables")).init()
phase("knock")
WorldFx.start()
phase("worldfx")
Weather.init() -- rain cycle (rare showers, starts clear), wet roads, mist, rain sound
-- (the day / night cycle runs since the loading screen: morning, day, sunset, night)
phase("world")
-- (21 Nov) the map round the menu settles while the profile is still on its way (it used to wait after the steps)
waitForMap("Loading the map...", false, if Config.activeMap() == "Yangon" then require(Shared:WaitForChild("MenuShots")).orbit().centre else nil)
phase("map")

---------------------------------------------------------------------
-- Data
---------------------------------------------------------------------
while not dataIn do
	task.wait()
end
local data = dataAsked
phase("data")
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
-- (2026-11-19) low-end mode, decided before traffic / pedestrians start so their counts follow it
require(script.Parent:WaitForChild("LowEnd")).init(settings)
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Strings")).setLang(settings.Lang or "auto") -- (19 Nov) Settings > Language
local SaveSettings = remote("SaveSettings", "RemoteEvent") :: RemoteEvent
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
		if Driving.cameraHold then
			return -- (another screen has the shot: the workshop, opened from the menu)
		end
		-- Studio previews (Claude's lighting screenshots): a test script parks the menu camera
		local preview = workspace:GetAttribute("PreviewCam")
		if typeof(preview) == "CFrame" and RunService:IsStudio() then
			camera.CFrame = preview
			camera.Focus = preview * CFrame.new(0, 0, -40)
			camera.FieldOfView = 70
			return
		end
		if Config.activeMap() == "Yangon" then
			-- Yangon: a slow circle round Myanmar Plaza, where players start (the server streams it in:
			-- MenuFocus). (19 Nov) The old 150-stud circle ran through the 1:1 Myanmar Centre: the circle is
			-- Shared.MenuShots' ORBIT, checked in open air by the server (a higher one if it fails)
			travel += dt
			local MS = require(Shared:WaitForChild("MenuShots"))
			local o = MS.orbit()
			local pos, centre = MS.orbitAt(o, travel * (math.pi * 2 / o.period))
			camera.CFrame = CFrame.lookAt(pos + Vector3.new(0, math.sin(travel / 9) * 6, 0), centre)
			camera.FieldOfView = 60
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

phase("settings")
stopLoadingShots()
startOrbit()
UI.showLoading("Filling the streets with traffic...")
UI.fade(false, 0.01)
phase("fade")
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
	-- (owner, 2026-11-21: "put more traffic": CarCount 28 -> 46; the low-end 0.5 keeps its 14 cars, TrafficMix.LowEndCars)
	local q = WorldFx.qualityScale()
	local lowCars = require(Shared:WaitForChild("TrafficMix")).LowEndCars
	-- (21 Nov, "make the loading screen load fast") the cars are put out a few a frame behind the menu: placing them
	-- held the start 0.4-2.5 s in Studio Play (a frame every 10 cars at loading-time frame rates)
	task.spawn(function()
		local t0 = os.clock()
		local ok, err = pcall(Traffic.start, if q <= 0.5 then lowCars else math.floor(Config.Traffic.CarCount * math.min(q, 1)), focusPoint)
		if ok then
			print(string.format("[CityLegends] startup: Traffic cars out in %.2fs (in the background)", os.clock() - t0))
		else
			warn("[CityLegends] startup: Traffic failed: " .. tostring(err))
		end
	end)
	-- a phone found low-end after the start drops to the low-end count too (Play test 21 Nov: it kept 46)
	require(script.Parent:WaitForChild("LowEnd")).changed(function(on)
		if on then
			Traffic.trim(lowCars)
		end
	end)
end)
startStep("Police", Police.init)
startStep("Bank", BankClient.init)
startStep("Activities", Activities.init)
startStep("Pedestrians", function()
	Pedestrians.start(WorldFx.qualityScale())
end)
startStep("YangonStreetLife", function()
	require(script.Parent:WaitForChild("YangonStreetLife")).start(WorldFx.qualityScale) -- parked cars and people (Yangon only)
end)
startStep("YangonSignals", function()
	require(script.Parent:WaitForChild("YangonSignals")).start() -- (21 Nov) traffic light poles at the junctions
end)
startStep("YangonMedians", function()
	require(script.Parent:WaitForChild("YangonMedians")).start() -- (21 Nov) the planted middle strip of Pyay Road / Kabar Aye
end)
startStep("Chauffeur", ChauffeurClient.init)
startStep("Luxe", function()
	require(script.Parent:WaitForChild("LuxeClient")).init() -- the gem shop and VIP cards, smash-and-grab messages
	-- (18 Nov) the VIP pass's chat tag (the server sets the speaker's "Vip" attribute: Store.lua)
	local TextChatService = game:GetService("TextChatService")
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")
		local src = message.TextSource
		local who = src and Players:GetPlayerByUserId(src.UserId)
		if who and who:GetAttribute("Vip") == true then
			props.PrefixText = '<font color="#FFD66E">[VIP]</font> ' .. message.PrefixText
		end
		return props
	end
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
startStep("Jobs", function()
	require(script.Parent:WaitForChild("JobsClient")).init() -- the Job Center screen, the job bar, job targets (2026-11-18)
end)
startStep("Offers", function()
	require(script.Parent:WaitForChild("OffersClient")).init() -- (19 Nov) Starter Pack card, Double Pay link, store measuring
end)
startStep("Housing", function()
	require(script.Parent:WaitForChild("HousingClient")).init() -- Legends Realty, claiming lots, the house menu
end)
startStep("Challenges", function()
	require(script.Parent:WaitForChild("ChallengesClient")).init() -- drifts, speed traps, jumps, leaderboard (B)
end)
startStep("Trailers", function()
	require(script.Parent:WaitForChild("TrailerClient")).init()
end)
startStep("Doors", function()
	require(script.Parent:WaitForChild("CarDoors")).init() -- (2026-11-08) scissor doors (Config.Doors)
end)
startStep("Care", function()
	require(script.Parent:WaitForChild("CareClient")).init()
	require(script.Parent:WaitForChild("DamageFx")).init()
end)
print("[CityLegends] startup: " .. table.concat(stepTimes, ", "))
phase("steps")
-- (owner, 2026-11-21: the loading screen now stays up until the main menu opens, at the end of this script)

---------------------------------------------------------------------
-- Spawning / garage
---------------------------------------------------------------------
-- (2026-11-04) is this my car, to get straight into? Asked for here, or brought out by the server on
-- its own (a test drive starting or ending). SpawnedAt is when it came out, so a car of yours
-- streaming back in later doesn't pull you into it
local function driveNow(model: Instance): boolean
	if model:GetAttribute("Owner") ~= player.UserId then
		return false
	end
	local at = model:GetAttribute("SpawnedAt")
	return pendingAttach or (type(at) == "number" and workspace:GetServerTimeNow() - at < 20)
end
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
	if not driveNow(model) then
		skinPlayerCar(model)
	end
end)

local arrivedYet = false
local driveAskedAt = 0 -- (os.clock of the last drive request: the spawn's load time is printed)
local function tryAttach(model: Instance)
	if model:IsA("Model") and driveNow(model) then
		pendingAttach = false
		attaching = true
		local tArrived = os.clock()
		local jumped = isJump(model:GetPivot().Position)
		waitWhole(model)
		local okSkin, errSkin = pcall(CarSkin.apply, model, false)
		if not okSkin then
			warn("[CityLegends] car skin failed:", errSkin)
		end
		stopOrbit()
		OnFoot.reset()
		Traffic.clearAround(model:GetPivot().Position, 35)
		Audio.waitReady(5) -- (the sound check runs in the background since 21 Nov: the engine's id comes from it)
		local okAttach, errAttach = pcall(Driving.attach, model)
		if not okAttach then
			attaching = false
			warn("[CityLegends] getting into the car failed:", errAttach)
			UI.hideLoading()
			UI.fade(false, 0.3)
			UI.toast("Could not get into the car, try again", Config.Theme.Danger)
			return -- (the watchdog brings the menu back)
		end
		-- (the streets round the car finish loading behind the loading screen, the car held)
		Driving.loadHold = true
		waitForMap("Loading the streets...", jumped)
		Driving.loadHold = false
		-- (the first car of a visit: you start on foot in the casino's garden)
		if not arrivedYet then
			arrivedYet = true
			if not player:GetAttribute("TestDrive") then
				OnFoot.arrive()
			end
		end
		UI.hideLoading()
		print(string.format("[CityLegends] car spawn: asked -> car %.2fs, car -> driving %.2fs", tArrived - driveAskedAt, os.clock() - tArrived))
		UI.showHud(true)
		attaching = false
		UI.setCameraLabel(Driving.cameraMode)
		UI.fade(false, 0.5)
	end
end
playerCars.ChildAdded:Connect(tryAttach)

-- stealFrom: a parked car in a tower garage (Parking): the server swaps it for a drivable one
local driveRequest = 0
local function requestDrive(id: string, stealFrom: Model?)
	driveRequest += 1
	local my = driveRequest
	pendingAttach = true
	driveAskedAt = os.clock()
	-- (21 Nov) asked first, then the fade: the server's spawn runs while the screen goes black
	if stealFrom then
		(remotes:WaitForChild("StealCar") :: RemoteEvent):FireServer(stealFrom)
	else
		data.Selected = id
		SpawnCar:FireServer(id)
	end
	UI.fade(true, 0.3)
	-- safety: if the car is already there (rare race) attach to it
	task.delay(0.5, function()
		if pendingAttach then
			local existing = playerCars:FindFirstChild(player.Name)
			if existing then
				tryAttach(existing)
			end
		end
	end)
	-- (2026-11-04) longer than the server's streaming wait (6 s, Main.server's spawnFor): this used to
	-- give up first on a slow phone. With no car and no avatar there's nothing left on screen to try
	-- again with, so the menu comes back
	task.delay(15, function()
		if pendingAttach and my == driveRequest then
			pendingAttach = false
			UI.fade(false, 0.3)
			UI.toast("Could not spawn the car, try again", Config.Theme.Danger)
			if not Driving.isDriving() and not player.Character then
				showMenu()
			end
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
startStep("Hotel", function()
	require(script.Parent:WaitForChild("HotelClient")).init(requestDrive)
end)
startStep("Customs", function()
	require(script.Parent:WaitForChild("CustomsClient")).init() -- Legends Customs (after the hotel: it chains the drive action)
end)
-- car levels, Car Points and the parts screen (2026-11-03; the garage's UPGRADE, the HUD strip)
startStep("Plates", function()
	require(script.Parent:WaitForChild("PlateClient")).init() -- (2026-11-19) Myanmar number plates, the Plate Office
end)
startStep("CarUpgrades", function()
	require(script.Parent:WaitForChild("CarUpgrades")).init()
end)
startStep("Workshop", function()
	require(script.Parent:WaitForChild("Workshop")).init() -- the parts screen, its room and the Part Shop (2026-11-06)
end)

-- island houses: a bay car's "Drive" spawns it on the driveway (the server picks the spot)
task.spawn(HouseClient.init, function(id: string)
	UI.closeGarage()
	requestDrive(id)
end)

-- Legends Motors, the dealership: its prompts open the buy screen, and cars leave by its bay
local DealerOpen = remote("DealerOpen", "RemoteEvent") :: RemoteEvent
local DealerCall = remote("DealerCall", "RemoteFunction") :: RemoteFunction

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
				-- (the server starts it at the drive-out bay itself; driveNow gets you in)
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
local function openDealer(carId: any)
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
			-- (the server starts it at the drive-out bay itself; driveNow gets you in)
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
end
DealerOpen.OnClientEvent:Connect(openDealer)
-- (19 Nov, owner: easy to find) the HUD's DEALER button: the same screen from anywhere (buying and
-- test drives are allowed away from the showroom; the server still checks them)
UI.onDealerButton = function()
	openDealer(nil)
end

-- the main menu (owner, 2026-11-02: big tiles, CAMPAIGN / CARS / STORE): the start screen, and
-- from the HUD's MENU button (it replaced SETTINGS) while you play
MainMenu = require(script.Parent:WaitForChild("MainMenu"))
local FastTravel = remote("FastTravel", "RemoteFunction") :: RemoteFunction
local ClaimStarter = remote("ClaimStarter", "RemoteFunction") :: RemoteFunction
local menuApi = {
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
			UI.fade(true, 0.25) -- (it returns once black: the extra 0.3 s wait after it is gone, 21 Nov)
			if not settle() then
				UI.fade(false, 0.3)
				UI.toast("Can't put the car there right now, try again", Config.Theme.Danger)
				return result
			end
			local jumped = isJump(cf.Position)
			Driving.teleport(cf)
			Traffic.clearAround(cf.Position, 35)
			Driving.loadHold = true
			waitForMap("Loading the streets...", jumped)
			Driving.loadHold = false
			UI.hideLoading()
			UI.fade(false, 0.4)
		elseif OnFoot.active and player.Character then
			UI.fade(true, 0.25) -- (it returns once black: the extra 0.3 s wait after it is gone, 21 Nov)
			if settle() and player.Character then
				local jumped = isJump(cf.Position)
				player.Character:PivotTo(cf + Vector3.new(0, 3, 0))
				waitForMap("Loading the streets...", jumped)
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
}
MainMenu.init(menuApi)
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
	-- TestTravel = a fast travel spot id (TravelSpots): the menu's fast travel, timed in the Output ("map wait")
	player:GetAttributeChangedSignal("TestTravel"):Connect(function()
		local id = player:GetAttribute("TestTravel")
		if type(id) == "string" and id ~= "" then
			player:SetAttribute("TestTravel", nil)
			local t0 = os.clock()
			local result = menuApi.travel(id)
			print(string.format("[CityLegends] fast travel %s: %.2fs (%s)", id, os.clock() - t0, tostring(result and result.ok)))
		end
	end)
end

if settings.HideKeys then
	UI.toggleControls(false)
end
UI.onMenuButton = MainMenu.toggle
-- (19 Nov) the HUD's SHOP button: the same as the cash pill's +
UI.onShopButton = function()
	UI.onCashPlus()
end
UI.onCashPlus = function()
	if not MainMenu.isOpen() then
		MainMenu.open(false)
	end
	MainMenu.show("STORE")
end
-- (19 Nov, owner: jobs like Southwest Florida) the HUD's JOBS icon, the job bar and the Job Center kiosk
UI.onJobsButton = function()
	if not MainMenu.isOpen() then
		MainMenu.open(false)
	end
	MainMenu.show("JOBS")
end

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
if Config.Market.Enabled then
	local MarketUI = require(script.Parent:WaitForChild("MarketUI"))
	startStep("Market", MarketUI.init)
	UI.onMarketButton = MarketUI.toggle
end

-- put your car away (owner, 2026-10-23: "add a function to despawn car"): out of it first if
-- you're in it, then the server removes it; G brings one back from the garage
local despawnRemote = remote("DespawnCar", "RemoteEvent") :: RemoteEvent
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

-- (19 Nov) back from the idle rejoin at a job post (server/Jobs.lua stood you at your post, on duty):
-- no start menu, the on-foot HUD
local function rejoinedAtPost()
	arrivedYet = true
	MainMenu.close()
	stopOrbit()
	OnFoot.footMode()
	UI.hideLoading()
	UI.showHud(true)
	UI.fade(false, 0.3)
	UI.toast("Back at your post: still on duty", Config.Theme.Accent2)
end
player:GetAttributeChangedSignal("JobRejoined"):Connect(function()
	if player:GetAttribute("JobRejoined") then
		task.spawn(rejoinedAtPost)
	end
end)
-- startup is over (owner, 2026-11-21): SKIP hides the loading screen again; the menu opens under it first, so
-- there is never a bare view in between (the watchdog started near the top of this script)
UI.setLoadingHold(false)
if player:GetAttribute("JobRejoined") then
	task.spawn(rejoinedAtPost)
else
	showMenu()
	UI.hideLoading()
end
phase("menu")
print("[CityLegends] startup phases: " .. table.concat(phaseLog, ", "))
