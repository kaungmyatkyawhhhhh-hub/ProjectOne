--[[
	Trailers on each player's screen (owner, 2026-11-07). A hitched trailer follows its car here, on every
	screen, from the car's own movement: the axle is dragged behind the hitch like a real trailer's, so it cuts
	corners going forward and turns the other way in reverse. Height and lean come from the road under the
	axle. It has no physics of its own, so it can't fling or sink. It sways a little at speed and stops
	folding at Config.Towing.Jackknife degrees.

	Also: the hitch on the towing car, the wheels, the ramps, the lamps, the car on the deck, the action pill
	(Config.Towing.Key or tap: HITCH, UNHITCH, STRAP, UNLOAD) and the tow's effect on Driving.
]]

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local UI = require(script.Parent:WaitForChild("UI"))

local T = Config.Towing
local TR = T.Trailer
local player = Players.LocalPlayer

local TrailerClient = {}
TrailerClient.owned = false -- (kept up by every call, the dealer's card reads it)

type Rec = {
	model: Model,
	root: BasePart,
	axle: Vector3?,
	y: number,
	roll: number,
	sway: number,
	spins: { Motor6D },
	turn: number,
	hinges: { Motor6D },
	ramp: number,
	rampDone: boolean,
	lamps: { BasePart },
	lit: { [BasePart]: number },
	hitch: Vector3?,
	hitchFor: Model?,
	hitchParts: { BasePart },
}

local recs: { [Instance]: Rec } = {}

local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.IgnoreWater = true
ray.RespectCanCollide = true
local rayAt = 0

local function refreshRay()
	local list: { Instance } = {}
	for _, name in { "PlayerCars", "Trailers", "Traffic", "Pedestrians", "Chauffeurs" } do
		local f = workspace:FindFirstChild(name)
		if f then
			table.insert(list, f)
		end
	end
	if workspace.CurrentCamera then
		table.insert(list, workspace.CurrentCamera)
	end
	ray.FilterDescendantsInstances = list
end

local function groundY(p: Vector3): number?
	local hit = workspace:Raycast(p + Vector3.new(0, 7, 0), Vector3.new(0, -24, 0), ray)
	return if hit then hit.Position.Y else nil
end

local function recFor(model: Model): Rec?
	local found = recs[model]
	if found then
		return found
	end
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local r: Rec = {
		model = model, root = root, axle = nil, y = root.Position.Y, roll = 0, sway = 0, spins = {}, turn = 0,
		hinges = {}, ramp = -1, rampDone = false, lamps = {}, lit = {}, hitch = nil, hitchFor = nil, hitchParts = {},
	}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") then
			table.insert(if d.Name == "Hinge" then r.hinges else r.spins, d)
		elseif d:IsA("BasePart") and d:GetAttribute("Lamp") then
			table.insert(r.lamps, d)
		end
	end
	recs[model] = r
	return r
end

-- where the ball sits on this car, in the root's frame: rear centre, under the bumper
local function hitchOf(car: Model): Vector3?
	local root = car.PrimaryPart
	local skin = car:FindFirstChild("Skin")
	if not root or not skin then
		return nil
	end
	local g = groundY(root.Position)
	local down = if g then root.Position.Y - g else 2.4
	local y = TR.CouplerHeight - down
	-- the rearmost body that comes down to bumper height (not a spare wheel up on the tailgate)
	local back = 0
	for _, d in skin:GetDescendants() do
		if d:IsA("BasePart") and d.Size.Magnitude > 0.2 and d.Transparency < 1 then
			local q = root.CFrame:ToObjectSpace(d.CFrame)
			local h = d.Size / 2
			local z = q.Position.Z + math.abs(q.RightVector.Z) * h.X + math.abs(q.UpVector.Z) * h.Y + math.abs(q.LookVector.Z) * h.Z
			local low = q.Position.Y - (math.abs(q.RightVector.Y) * h.X + math.abs(q.UpVector.Y) * h.Y + math.abs(q.LookVector.Y) * h.Z)
			if z > back and low < y + 1.6 then
				back = z
			end
		end
	end
	if back <= 0 then
		back = ((car:GetAttribute("Length") :: number?) or 15) / 2
	end
	return Vector3.new(0, y, back + 0.5 + (T.HitchReach[car:GetAttribute("CarId") :: string] or 0))
end

local function showHitch(r: Rec, car: Model?)
	if r.hitchFor == car then
		return
	end
	for _, p in r.hitchParts do
		p:Destroy()
	end
	table.clear(r.hitchParts)
	r.hitchFor = car
	r.hitch = nil
	if not car then
		return
	end
	local root = car.PrimaryPart :: BasePart
	local at = hitchOf(car)
	if not at then
		r.hitchFor = nil
		return
	end
	r.hitch = at
	local function bit(size: Vector3, offset: Vector3, shape: Enum.PartType, color: Color3)
		local p = Instance.new("Part")
		p.Name = "TowHitch"
		p.Shape = shape
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Metal
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CFrame = root.CFrame * CFrame.new(offset)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		p.Parent = car
		table.insert(r.hitchParts, p)
	end
	-- the receiver bar from under the bumper, and the ball
	bit(Vector3.new(0.26, 0.24, 1.3), at + Vector3.new(0, -0.17, -0.5), Enum.PartType.Block, Color3.fromRGB(26, 26, 30))
	bit(Vector3.new(0.3, 0.3, 0.3), at, Enum.PartType.Ball, Color3.fromRGB(170, 172, 178))
end

local function setLamp(r: Rec, p: BasePart, level: number)
	if r.lit[p] == level then
		return
	end
	r.lit[p] = level
	local c = p:GetAttribute("Lit") :: Color3
	p.Color = if level >= 2 then c else c:Lerp(Color3.new(0, 0, 0), 0.35)
	p.Transparency = if level >= 1 then 0 else 1 -- (off, the model's own lens shows)
end

local function lamps(r: Rec, car: Model?)
	local on = if car then car:GetAttribute("Lights") == true else false
	local brake = if car then car:GetAttribute("Brake") == true else false
	local rev = if car then car:GetAttribute("Rev") == true else false
	local blink = if car then (car:GetAttribute("Blinker") :: string?) or "" else ""
	local phase = (os.clock() % 0.8) < 0.4
	for _, p in r.lamps do
		local kind = p:GetAttribute("Lamp")
		if kind == "Tail" then
			setLamp(r, p, if brake then 2 elseif on then 1 else 0)
		elseif kind == "Turn" then
			setLamp(r, p, if phase and (blink == p:GetAttribute("Side") or blink == "H") then 2 else 0)
		else
			setLamp(r, p, if rev then 2 else 0)
		end
	end
end

local function follow(r: Rec, car: Model, dt: number)
	local root = car.PrimaryPart
	if not root then
		return
	end
	showHitch(r, car)
	if not r.hitch then
		return
	end
	local hw = root.CFrame * (r.hitch :: Vector3)
	local L = TR.AxleToHitch
	local look = root.CFrame.LookVector
	local ahead = Vector3.new(look.X, 0, look.Z)
	ahead = if ahead.Magnitude > 0.05 then ahead.Unit else Vector3.new(0, 0, -1)
	local flat = Vector3.new(hw.X, 0, hw.Z)
	-- the axle is dragged along the line to the hitch
	local rootPos = r.root.Position
	local axle = r.axle or Vector3.new(rootPos.X, 0, rootPos.Z) -- (hitching on: it stays as it stands)
	local jumped = (flat - axle).Magnitude > L * 1.6 -- (fast travel: straight behind it again)
	if jumped then
		axle = flat - ahead * L
	end
	local d = flat - axle
	d = if d.Magnitude > 0.1 then d.Unit else ahead
	-- no folding past the limit
	local ang = math.atan2(ahead:Cross(d).Y, ahead:Dot(d))
	local limit = math.rad(T.Jackknife)
	if math.abs(ang) > limit then
		d = CFrame.Angles(0, math.sign(ang) * limit, 0):VectorToWorldSpace(ahead)
	end
	axle = flat - d * L
	r.axle = axle
	-- a gentle sway at speed, more after a sharp move; the coupler stays on the ball
	local v = root.AssemblyLinearVelocity
	local speed = Vector3.new(v.X, 0, v.Z).Magnitude
	local mph = Config.spsToMph(speed)
	local atSpeed = math.clamp((mph - T.SwayFromMph) / 30, 0, 1)
	local want = T.SwayStuds * atSpeed * (0.4 + math.clamp(math.abs(ang) * 3, 0, 0.6)) * math.sin(os.clock() * T.SwayRate)
	r.sway += (want - r.sway) * math.min(1, dt * 4)
	local across = Vector3.new(d.Z, 0, -d.X)
	local axleNow = axle + across * r.sway
	-- the road under it
	local side = across * (TR.Width / 2)
	local up = Vector3.new(0, hw.Y, 0)
	local yM = groundY(axleNow + up)
	local yL = groundY(axleNow + side + up)
	local yR = groundY(axleNow - side + up)
	-- (a side over a kerb or a wall top is not the road)
	if yM then
		yL = if yL and math.abs(yL - yM) < 0.9 then yL else yM
		yR = if yR and math.abs(yR - yM) < 0.9 then yR else yM
	end
	local g = if yL and yR then (yL + yR) / 2 else (yL or yR or r.y)
	r.y = if jumped then g else r.y + math.clamp((g - r.y) * math.min(1, dt * 14), -T.ClimbRate * dt, T.ClimbRate * dt)
	local rollWant = if yL and yR then math.clamp(math.atan2(yR - yL, TR.Width), -T.MaxRoll, T.MaxRoll) else 0
	r.roll += (rollWant - r.roll) * math.min(1, dt * 8)
	-- the coupler on the ball, the trailer lying along the line from there to the axle
	local top = Vector3.new(axleNow.X, r.y + TR.CouplerHeight, axleNow.Z)
	local cf = CFrame.lookAt(top, hw) * CFrame.Angles(0, 0, r.roll) * CFrame.new(0, -TR.CouplerHeight, 0)
	r.root.CFrame = cf
	r.turn += v:Dot(cf.LookVector) * dt / TR.WheelRadius
	r.model:SetAttribute("LiveSpeed", speed)
end

local function park(r: Rec)
	showHitch(r, nil)
	r.axle = nil
	r.y = r.root.Position.Y
	r.model:SetAttribute("LiveSpeed", 0)
end

local function drawWheels(r: Rec)
	local spin = CFrame.Angles(-r.turn, 0, 0)
	for _, m in r.spins do
		m.Transform = spin
	end
end

-- the ramps slide out from under the deck and tip down to the road
local RAMP_TILT = math.asin(math.min(1, TR.DeckHeight / TR.RampLength))
local function drawRamps(r: Rec, dt: number)
	local want = if r.model:GetAttribute("RampsDown") == true then 1 else 0
	if r.rampDone and r.ramp == want then
		return
	end
	if r.ramp < 0 then
		r.ramp = want
	end
	r.ramp = if math.abs(want - r.ramp) < 0.02 then want else r.ramp + (want - r.ramp) * math.min(1, dt * 3.5)
	local a = r.ramp
	local slide = math.clamp(a / 0.7, 0, 1)
	local tip = math.clamp((a - 0.7) / 0.3, 0, 1)
	local t = CFrame.new(0, -0.4 * (1 - slide), -TR.RampLength * (1 - slide)) * CFrame.Angles(RAMP_TILT * tip, 0, 0)
	for _, m in r.hinges do
		m.Transform = t
	end
	r.rampDone = r.ramp == want
end

local poseT = 0
local mine: Rec? = nil
local towLamp = false
local remotes: Instance

local function step(dt: number)
	local folder = workspace:FindFirstChild("Trailers")
	if not folder then
		return
	end
	rayAt -= dt
	if rayAt <= 0 then
		rayAt = 2
		refreshRay()
	end
	local cars = workspace:FindFirstChild("PlayerCars")
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	mine = nil
	for _, model in folder:GetChildren() do
		local r = if model:IsA("Model") then recFor(model) else nil
		if r then
			local name = model:GetAttribute("OwnerName") :: string?
			local found = if cars and name then cars:FindFirstChild(name) else nil
			local car: Model? = if found and found:IsA("Model") and model:GetAttribute("Hitched") == true then found else nil
			if car then
				follow(r, car, dt)
			elseif r.axle or r.hitchFor then
				park(r)
			end
			if (r.root.Position - camPos).Magnitude < 420 then
				drawWheels(r)
				drawRamps(r, dt)
				lamps(r, car)
			end
			if model:GetAttribute("Owner") == player.UserId then
				mine = r
			end
		end
	end
	-- the tow on the driver's own car
	local m = mine
	local towing = m ~= nil and m.model:GetAttribute("Hitched") == true and Driving.isDriving()
	Driving.setTow(if m and towing then m.model:GetAttribute("TotalKg") :: number else nil)
	if towing ~= towLamp then
		towLamp = towing
		UI.setTowing(towing)
		if not towing then
			-- (out of the car or unhitched: the trailer's brake and reverse lamps go off)
			local signals = remotes:FindFirstChild("CarSignals")
			if signals then
				(signals :: RemoteEvent):FireServer({ brake = false, rev = false })
			end
		end
	end
	if m and towing then
		poseT -= dt
		if poseT <= 0 then
			poseT = 1
			local pose = remotes:FindFirstChild("TrailerPose")
			if pose then
				(pose :: RemoteEvent):FireServer(m.root.CFrame)
			end
		end
	end
end

---------------------------------------------------------------------
-- asking the server
---------------------------------------------------------------------
local busy = false

function TrailerClient.ask(what: string, arg: any?): any
	local rem = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TrailerCall", 10) :: RemoteFunction?
	if not rem then
		return nil
	end
	local ok, res = pcall(function()
		return rem:InvokeServer(what, arg)
	end)
	if ok and type(res) == "table" then
		TrailerClient.owned = res.owned == true
		return res
	end
	return nil
end

-- (cb gets the answer; with no cb the server's message shows as a toast)
function TrailerClient.call(what: string, arg: any?, cb: ((any) -> ())?)
	if busy then
		return
	end
	busy = true
	task.spawn(function()
		local res = TrailerClient.ask(what, arg)
		busy = false
		if cb then
			cb(res)
		elseif res and res.message then
			UI.toast(res.message, if res.ok then nil else Config.Theme.Warning)
		end
	end)
end

function TrailerClient.state(cb: (any) -> ())
	task.spawn(function()
		cb(TrailerClient.ask("state") or { owned = false, out = false, hitched = false })
	end)
end

-- the car asked for comes out, then the trailer hitches on
function TrailerClient.takeWhenIn(id: string)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 25 do
			local car = Driving.getModel()
			if car and car:GetAttribute("CarId") == id then
				task.wait(0.5)
				TrailerClient.call("take")
				return
			end
			task.wait(0.2)
		end
	end)
end

---------------------------------------------------------------------
-- the key / the pill: what you can do right now
---------------------------------------------------------------------
local function onDeck(r: Rec, car: Model): boolean
	local q = r.root.CFrame:PointToObjectSpace(car:GetPivot().Position)
	return math.abs(q.X) < TR.Width / 2 + 2 and q.Z > TR.DeckFront - 1 and q.Z < TR.DeckBack + TR.RampLength + 6 and q.Y < 10
end

local function current(): (string?, (() -> ())?)
	local m = mine
	if not m then
		return nil, nil
	end
	local model = m.model
	local hitched = model:GetAttribute("Hitched") == true
	local load = model:GetAttribute("Load") :: string?
	if Driving.isDriving() then
		local car = Driving.getModel()
		if not car or Config.spsToMph(Driving.getSpeed()) > T.ActionMph then
			return nil, nil
		end
		if hitched then
			return "UNHITCH", function()
				TrailerClient.call("unhitch", m.root.CFrame)
			end
		end
		if load == "" and onDeck(m, car) then
			return "STRAP", function()
				-- out of the car first: the server then puts it on the deck
				OnFoot.getOut()
				task.delay(0.8, function()
					TrailerClient.call("strap")
				end)
			end
		end
		local hitch = hitchOf(car)
		if hitch then
			local hw = car:GetPivot() * hitch
			local cw = m.root.CFrame * Vector3.new(0, TR.CouplerHeight, -TR.AxleToHitch)
			if (hw - cw).Magnitude < T.HitchRange then
				return "HITCH", function()
					TrailerClient.call("hitch")
				end
			end
		end
	else
		local character = player.Character
		if character and load ~= nil and load ~= "" and (character:GetPivot().Position - m.root.Position).Magnitude < T.UnloadRange then
			return "UNLOAD", function()
				TrailerClient.call("unload")
			end
		end
	end
	return nil, nil
end

local actionFn: (() -> ())? = nil
local dressing: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

function TrailerClient.init()
	remotes = ReplicatedStorage:WaitForChild("Remotes")
	refreshRay()
	RunService.RenderStepped:Connect(step)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local label, fn = current()
			actionFn = fn
			UI.setTowAction(label, T.Key.Name)
			-- the car on a trailer gets its body like a parked car (its parts may still be arriving)
			for _, car in CollectionService:GetTagged("TrailerLoad") do
				if car:IsA("Model") and car.PrimaryPart and not car:GetAttribute("Skinned") and os.clock() > (dressing[car] or 0) then
					dressing[car] = os.clock() + 8
					task.spawn(pcall, CarSkin.apply, car, false)
				end
			end
		end
	end)
	UI.onTowAction = function()
		if actionFn then
			actionFn()
		end
	end
	-- (on foot Roblox's own camera takes I to zoom: this comes first, only while there's something to do)
	ContextActionService:BindActionAtPriority("TrailerAction", function(_, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin or UI.modalOpen or not actionFn then
			return Enum.ContextActionResult.Pass
		end
		actionFn()
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, T.Key)
	-- a trailer gone: forget it, and take the hitch off the car
	task.spawn(function()
		local folder = workspace:WaitForChild("Trailers", 30)
		if folder then
			folder.ChildRemoved:Connect(function(model)
				local r = recs[model]
				if r then
					showHitch(r, nil)
					recs[model] = nil
				end
			end)
		end
	end)
	local note = remotes:WaitForChild("TrailerNote", 10) :: RemoteEvent?
	if note then
		note.OnClientEvent:Connect(function(text: any)
			if type(text) == "string" then
				UI.toast(text, Config.Theme.Warning)
			end
		end)
	end
	TrailerClient.state(function() end)
end

return TrailerClient
