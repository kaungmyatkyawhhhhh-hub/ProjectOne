--[[
	CareClient (owner, 2026-11-07): the driver's side of mileage, wear and fuel. The server keeps the books
	(server/Care.lua); the car carries the numbers as attributes. Here:
	  * the gauges: fuel on the HUD and on the cluster, the check engine light, the odometer on the cluster
	  * what the car's health does: Driving.setCare when it changes
	  * what only this game can see goes to the server every two seconds (Driving.takeReport)
	  * the action pill: SERVICE in the bay, FUEL at a pump, ROADSIDE HELP when the tank is dry
	  * the screens for those three, in the game's own style (UI.kit)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CarCare = require(Shared:WaitForChild("CarCare"))

local Audio = require(script.Parent:WaitForChild("Audio"))
local DashGauges = require(script.Parent:WaitForChild("DashGauges"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local UI = require(script.Parent:WaitForChild("UI"))

local Theme = Config.Theme
local kit = UI.kit
local new, label, button, corner, stroke = kit.new, kit.label, kit.button, kit.corner, kit.stroke
local money = CarCare.money
local F = Config.Fuel
local S = Config.Service
local player = Players.LocalPlayer

local CareClient = {}

local call: RemoteFunction? = nil
local sg: ScreenGui? = nil

local function ask(what: string, arg: any?): any
	if not call then
		return nil
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	return if ok and type(res) == "table" then res else nil
end

function CareClient.sell(id: string, cb: (any) -> ())
	task.spawn(function()
		cb(ask("sell", id))
	end)
end

function CareClient.info(id: string, cb: (any) -> ())
	task.spawn(function()
		cb(ask("state", id))
	end)
end

-- a nearest-station miles figure on the same scale as the odometer
local function milesTo(pos: Vector3, at: Vector3): number
	return (pos - at).Magnitude * 0.35 / 1609 * Config.Wear.OdoScale
end

local function nearestStation(at: Vector3): any
	local best, bestD = nil, math.huge
	for _, st in F.Stations do
		local d = (st.pumps[1] - at).Magnitude
		if d < bestD then
			best, bestD = st, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- The screens
---------------------------------------------------------------------
local function close()
	if sg then
		sg:Destroy()
		sg = nil
	end
	UI.modalOpen = false
	Driving.inputEnabled = true
end

local function sheet(w: number, h: number, titleText: string, subText: string): (Frame, TextLabel)
	close()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CareScreen"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = player:WaitForChild("PlayerGui")
	sg = gui
	UI.modalOpen = true
	Driving.inputEnabled = false
	local cam = workspace.CurrentCamera
	local vs = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	local scale = math.min(1, (vs.X - 24) / w, (vs.Y - 24) / h)
	new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), Active = true, Parent = gui })
	local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(w, h), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.04, Parent = gui }, { corner(14), stroke(Theme.Stroke, 1.5, 0.3), new("UIScale", { Scale = scale }) })
	label({ Text = titleText, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = Theme.Accent2, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 12), Size = UDim2.new(1, -90, 0, 28), Parent = card })
	local sub = label({ Text = subText, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 40), Size = UDim2.new(1, -90, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = card })
	local x = button("X", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(40, 40), Parent = card })
	x.Activated:Connect(close)
	return card, sub
end

local function meter(parent: Instance, y: number, name: string, share: number, right: string?)
	share = math.clamp(share, 0, 1)
	local color = if share < 0.3 then Theme.Danger elseif share < 0.6 then Theme.Warning else Color3.fromRGB(70, 230, 110)
	label({ Text = name, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, y), Size = UDim2.new(0.5, 0, 0, 18), Parent = parent })
	label({ Text = right or (math.floor(share * 100 + 0.5) .. "%"), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y), Size = UDim2.new(0.6, 0, 0, 18), Parent = parent })
	local back = new("Frame", { Position = UDim2.fromOffset(0, y + 20), Size = UDim2.new(1, 0, 0, 7), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = parent }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	new("Frame", { Size = UDim2.fromScale(share, 1), BackgroundColor3 = color, BorderSizePixel = 0, Parent = back }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
end

local JOBS = { { "oil", "OIL SERVICE" }, { "engine", "ENGINE REPAIR" }, { "tyres", "NEW TYRES" }, { "brakes", "BRAKES" }, { "body", "BODY REPAIR" } }

local openService: () -> ()

local function drawService(st: any)
	local card, sub = sheet(660, 400, S.Name, st.name .. "  ·  " .. CarCare.milesText(st.miles))
	sub.Text = st.name .. "  ·  " .. CarCare.milesText(st.miles) .. "  ·  You have " .. money(st.cash)
	local left = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 70), Size = UDim2.new(0.5, -34, 1, -86), Parent = card })
	meter(left, 0, "Engine", st.e / 100)
	meter(left, 40, "Service", st.oil, if st.due >= 0 then "due in " .. st.due .. " mi" else "overdue " .. -st.due .. " mi")
	meter(left, 80, "Tyres", st.t / 100)
	meter(left, 120, "Brakes", st.b / 100)
	meter(left, 160, "Body", st.h / 100, if st.marks > 0 then st.marks .. " marks" else nil)
	local last = st.book[1]
	label({ Text = if last then string.format("Service book: %s at %s", string.lower(last.k), CarCare.milesText(last.m)) else "Service book: empty", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 206), Size = UDim2.new(1, 0, 0, 18), Parent = left })
	label({ Text = st.breakdown, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Position = UDim2.fromOffset(0, 228), Size = UDim2.new(1, 0, 0, 36), Parent = left })
	local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 70), Size = UDim2.new(0.5, -14, 1, -86), Parent = card })
	local busy = false
	local function row(y: number, id: string, name: string, price: number, color: Color3)
		local free = id == "oil" and st.freeService
		local b = button(name .. "   " .. (if price <= 0 then "OK" elseif free then "FREE" else money(price)), color, { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 42), TextSize = 15, Parent = right })
		if price <= 0 then
			b.TextColor3 = Theme.SubText
			b.AutoButtonColor = false
			return
		end
		b.Activated:Connect(function()
			if busy then
				return
			end
			if not free and price > st.cash then
				UI.toast("Not enough cash", Theme.Warning)
				return
			end
			busy = true
			b.Text = "ON THE LIFT..."
			local res = ask("service", id)
			busy = false
			if res and res.ok then
				Audio.click()
				UI.toast(name .. " done" .. (if res.paid and res.paid > 0 then ": " .. money(res.paid) else ""))
				if sg then
					drawService(res)
				end
			else
				UI.toast((res and res.message) or "Try again", Theme.Warning)
				if sg then
					openService()
				end
			end
		end)
	end
	local y = 0
	for _, job in JOBS do
		row(y, job[1], job[2], st.prices[job[1]], Theme.Accent)
		y += 48
	end
	row(y + 4, "full", "FULL SERVICE", st.prices.full, Theme.Accent2)
end

openService = function()
	local st = ask("state")
	if st and st.ok then
		drawService(st)
	else
		UI.toast((st and st.message) or "Try again", Theme.Warning)
	end
end

local function drawFuel(st: any)
	local unit = if st.electric then "kWh" else "L"
	local have = math.floor(st.f * st.tank + 0.5)
	local card = sheet(460, 300, if st.electric then "RIVIERA FUEL · CHARGER" else "RIVIERA FUEL", st.name)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 70), Size = UDim2.new(1, -40, 1, -86), Parent = card })
	meter(body, 0, if st.electric then "Battery" else "Tank", st.f, string.format("%d / %d %s", have, st.tank, unit))
	local price = if st.freeFill then "FREE" else money(st.fill)
	local fill = button((if st.electric then "CHARGE   " else "FILL UP   ") .. (if st.fill <= 0 then "FULL" else price), Theme.Accent2, { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 48), TextSize = 18, Parent = body })
	local busy = false
	local function pay(dollars: number?)
		if busy or st.fill <= 0 then
			return
		end
		busy = true
		local seconds = if st.electric then F.ChargeSeconds else F.FillSeconds
		fill.Text = if st.electric then "CHARGING..." else "FILLING..."
		task.wait(seconds)
		local res = ask("fill", dollars)
		busy = false
		if res and res.ok then
			Audio.click()
			UI.toast((if st.electric then "Charged" else "Filled up") .. (if res.paid > 0 then ": " .. money(res.paid) else ": free"))
			close()
		else
			UI.toast((res and res.message) or "Try again", Theme.Warning)
			close()
		end
	end
	fill.Activated:Connect(function()
		pay(nil)
	end)
	local half = UDim2.new(0.5, -5, 0, 40)
	local add20 = button("ADD $20", Theme.Accent, { Position = UDim2.fromOffset(0, 100), Size = half, TextSize = 15, Parent = body })
	local add50 = button("ADD $50", Theme.Accent, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 100), Size = half, TextSize = 15, Parent = body })
	add20.Activated:Connect(function()
		pay(20)
	end)
	add50.Activated:Connect(function()
		pay(50)
	end)
	local wash = button("CAR WASH   " .. money(S.Wash), Theme.Accent, { Position = UDim2.fromOffset(0, 148), Size = UDim2.new(1, 0, 0, 40), TextSize = 15, Parent = body })
	wash.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		wash.Text = "WASHING..."
		task.wait(2.5)
		local res = ask("wash")
		busy = false
		UI.toast(if res and res.ok then "Clean" else (res and res.message) or "Try again", if res and res.ok then nil else Theme.Warning)
		close()
	end)
end

local function drawRoadside(st: any)
	local card = sheet(460, 230, "ROADSIDE HELP", if st.electric then "The battery is empty" else "Out of fuel")
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 76), Size = UDim2.new(1, -40, 1, -92), Parent = card })
	local can = button((if st.electric then "A QUICK CHARGE   " else "FUEL CAN   ") .. money(F.CanPrice), Theme.Accent2, { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 48), TextSize = 17, Parent = body })
	local tow = button("TOW TO THE NEAREST STATION   " .. money(F.TowPrice), Theme.Accent, { Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 48), TextSize = 15, Parent = body })
	can.Activated:Connect(function()
		local res = ask("roadside", "can")
		close()
		UI.toast(if res and res.ok then "Enough to reach a station" else (res and res.message) or "Try again")
	end)
	tow.Activated:Connect(function()
		local res = ask("roadside", "tow")
		close()
		UI.toast(if res and res.ok then "Towed to the station" else (res and res.message) or "Try again")
	end)
end

---------------------------------------------------------------------
-- What the car's health does, and the gauges
---------------------------------------------------------------------
local lastKey = ""
local emptyNow = false

local function refresh()
	local car = Driving.getModel()
	if not car then
		UI.setFuel(nil)
		UI.setCheckEngine(0)
		lastKey = ""
		DashGauges.fuelShare = 0.8
		DashGauges.odoMiles = nil
		DashGauges.checkEngine = 0
		emptyNow = false
		return
	end
	local fuel = car:GetAttribute("Fuel") :: number?
	if fuel == nil then
		return
	end
	local electric = car:GetAttribute("Electric") == true
	UI.setFuel(fuel, electric)
	local check = (car:GetAttribute("CheckEngine") :: number?) or 0
	UI.setCheckEngine(check)
	DashGauges.fuelShare = fuel
	DashGauges.odoMiles = car:GetAttribute("Odo") :: number?
	DashGauges.checkEngine = check
	emptyNow = fuel <= 0.0005
	local e, t, b, h = (car:GetAttribute("Eng") :: number?) or 100, (car:GetAttribute("Tyre") :: number?) or 100, (car:GetAttribute("Brk") :: number?) or 100, (car:GetAttribute("Body") :: number?) or 100
	local key = string.format("%d|%d|%d|%d|%s", e, t // 5, b // 5, h // 5, tostring(emptyNow))
	if key ~= lastKey then
		lastKey = key
		local fx = CarCare.effects({ e = e, t = t, b = b, h = h } :: any) :: any
		fx.empty = emptyNow
		Driving.setCare(fx)
	end
end

local function pill()
	local prev = OnFoot.driveAction
	OnFoot.driveAction = function(): (string?, (() -> ())?)
		local car = Driving.getModel()
		if car and not sg then
			if emptyNow then
				return "ROADSIDE HELP", function()
					local st = ask("state")
					if st and st.ok then
						drawRoadside(st)
					end
				end
			end
			local p = car:GetPivot().Position
			local d = p - S.Bay
			if Vector3.new(d.X, 0, d.Z).Magnitude <= S.BayRadius then
				return "SERVICE", function()
					task.spawn(openService)
				end
			end
			for _, st in F.Stations do
				for _, pump in st.pumps do
					if (p - pump).Magnitude <= F.PumpRange then
						return if car:GetAttribute("Electric") == true then "CHARGE" else "FUEL", function()
							task.spawn(function()
								local s2 = ask("state")
								if s2 and s2.ok then
									drawFuel(s2)
								else
									UI.toast((s2 and s2.message) or "Your own cars only", Theme.Warning)
								end
							end)
						end
					end
				end
			end
		end
		if prev then
			return prev()
		end
		return nil, nil
	end
end

function CareClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("CareCall", 30) :: RemoteFunction?
	local report = remotes:WaitForChild("CareReport", 30) :: RemoteEvent?
	local push = remotes:WaitForChild("CarePush", 30) :: RemoteEvent?
	pill()
	-- no cruise control in a race, a time trial or on a job
	local Activities = require(script.Parent:WaitForChild("Activities")) :: any
	Driving.noCruise = function(): boolean
		return Activities.getTarget ~= nil and Activities.getTarget() ~= nil
	end
	UI.onCruise = Driving.toggleCruise
	UI.onCruiseStep = Driving.cruiseStep
	-- the puff of smoke of a misfire
	Driving.onMisfire = function()
		local root = Driving.getRoot()
		if not root then
			return
		end
		local a = Instance.new("Attachment")
		a.Position = Vector3.new(0, -1, (((root.Parent :: Model):GetAttribute("Length") :: number?) or 15) / 2)
		a.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = NumberRange.new(2, 5)
		e.Color = ColorSequence.new(Color3.fromRGB(60, 60, 62))
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.6) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = a
		e:Emit(5)
		task.delay(1.2, function()
			a:Destroy()
		end)
	end
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) ~= "table" then
				return
			end
			if msg.kind == "lowfuel" then
				local root = Driving.getRoot()
				local st = root and nearestStation(root.Position)
				if root and st then
					UI.toast(string.format("Low fuel: nearest station %.1f mi", milesTo(root.Position, st.pumps[1])), Theme.Warning)
					Minimap.setWaypoint(st.pumps[1])
				else
					UI.toast("Low fuel", Theme.Warning)
				end
			elseif msg.kind == "service" then
				UI.toast(tostring(msg.text), Theme.Warning)
				Minimap.setWaypoint(S.Bay)
			elseif msg.kind == "tow" then
				if typeof(msg.cf) == "CFrame" then
					Driving.teleport(msg.cf)
				end
			elseif msg.text then
				UI.toast(tostring(msg.text))
			end
		end)
	end
	task.spawn(function()
		local t = 0
		while true do
			task.wait(0.25)
			pcall(refresh)
			t += 0.25
			if t >= 2 and report then
				t = 0
				local r = Driving.takeReport()
				if r then
					(report :: RemoteEvent):FireServer(r)
				end
			end
		end
	end)
end

return CareClient
