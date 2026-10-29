--[[
	ChauffeurClient
	The luxury chauffeur service on the client (server side: src/server/Chauffeur.lua).

	  * the phone (H, the CHAUFFEUR side button, D-pad right on a controller, or a chauffeur
	    stand): sign a contract for a fleet car, pick a destination, call the car
	  * the called car is driven here, by the rider's own machine: along the lane graph
	    (ChauffeurRoute), at city / highway speeds, slowing for turns, stopping at red lights and
	    behind traffic, easing over for lane changes. The server gave this machine the car's
	    physics, so moving its rigid align targets every frame shows the car gliding for everyone
	  * the ride: cinematic cameras (V or Y on a controller cycles them; they also change on their
	    own), a ride card with SKIP RIDE (fade, arrive) and STOP HERE
	  * every chauffeur car in view gets its smooth body, a driver in a black suit and cap, and
	    spinning, steering wheels
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local ChauffeurRoute = require(Shared:WaitForChild("ChauffeurRoute"))

local UI = require(script.Parent:WaitForChild("UI"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Traffic = require(script.Parent:WaitForChild("Traffic"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local CH = Config.Chauffeur
local Theme = Config.Theme
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ChauffeurClient = {}

local GOLD = Color3.fromRGB(214, 178, 98)
local GOLD_DARK = Color3.fromRGB(120, 96, 50)
local INK = Color3.fromRGB(8, 8, 11)

local remotes: Folder
local callRemote: RemoteFunction
local folder: Folder? = nil

local contracts: { [string]: boolean } = {}
local places: { WestLayout.Place } = WestLayout.places()
local placeById: { [string]: WestLayout.Place } = {}
for _, p in places do
	placeById[p.id] = p
end

---------------------------------------------------------------------
-- My ride
---------------------------------------------------------------------
type Ride = {
	carName: string,
	carId: string,
	placeId: string,
	phase: string, -- "coming" | "waiting" | "riding" | "arriving" | "leaving"
	car: Model?,
	route: ChauffeurRoute.Route?,
	legStart: { number },
	d: number,
	v: number,
	stopAt: number?, -- "stop here": brake to a halt at this distance
	pickup: ChauffeurRoute.Spot,
	dest: ChauffeurRoute.Spot,
	fwd: Vector3,
	leaveSeg: CityLayout.Segment?,
	leaveS: number,
	leaveT: number,
	marker: BillboardGui?,
	split: number?, -- studs off the lane's centre while lane splitting (+ right)
	splitTo: number?,
}
local ride: Ride? = nil

local function invoke(what: string, a: any?, b: any?): any
	local ok, result = pcall(function()
		return callRemote:InvokeServer(what, a, b)
	end)
	if not ok or type(result) ~= "table" then
		return { ok = false, message = "The service didn't answer, try again" }
	end
	return result
end

local function spotFrom(ids: any): ChauffeurRoute.Spot?
	if type(ids) ~= "table" then
		return nil
	end
	local seg = CityLayout.buildGraph().all[ids[1]]
	if not seg then
		return nil
	end
	return { seg = seg, s = tonumber(ids[2]) or 0, dist = 0 }
end

local function setRoute(r: Ride, route: ChauffeurRoute.Route)
	r.route = route
	r.d = 0
	r.stopAt = nil
	local starts = {}
	local acc = 0
	for k, leg in route.legs do
		starts[k] = acc
		acc += math.max(0, leg.s1 - leg.s0)
	end
	r.legStart = starts
end

local function fmtTime(t: number): string
	t = math.max(0, math.floor(t + 0.5))
	return string.format("%d:%02d", t // 60, t % 60)
end

local function fmtDist(studs: number): string
	-- 1 stud ~= 0.35 m (the same scale as the speedometer)
	local miles = studs * 0.35 / 1609
	if miles < 0.1 then
		return string.format("%d ft", math.floor(studs * 0.35 * 3.28 / 10 + 0.5) * 10)
	end
	return string.format("%.1f mi", miles)
end

---------------------------------------------------------------------
-- The phone
---------------------------------------------------------------------
local gui: ScreenGui
local phone: Frame
local screen: Frame
local rideCard: Frame
local rideTitle: TextLabel
local rideSub: TextLabel
local rideBar: Frame
local skipBtn: TextButton
local phoneOpen = false
local view = "fleet" -- "fleet" | "contract" | "places" | "status"
local pickedCar: string? = nil
local statusText = ""

local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		for k, v in props do
			if k ~= "Parent" then
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function stroke(color: Color3, thickness: number, transparency: number?): UIStroke
	return new("UIStroke", { Color = color, Thickness = thickness, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base)
end

local function pill(caption: string, color: Color3, props: { [string]: any }): TextButton
	local base = {
		AutoButtonColor = false,
		Text = caption,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = INK,
		BackgroundColor3 = color,
		Size = UDim2.new(1, -32, 0, 44),
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(22) })
	b.Activated:Connect(Audio.click)
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.12 }):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
	end)
	return b
end

local refresh: () -> ()

local function clearScreen()
	for _, c in screen:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function header(title: string, sub: string?, back: (() -> ())?)
	local h = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, if sub then 58 else 40), LayoutOrder = 0, Parent = screen })
	local x = 16
	if back then
		local b: TextButton = new("TextButton", {
			AutoButtonColor = false,
			Text = "‹",
			Font = Enum.Font.GothamBlack,
			TextSize = 26,
			TextColor3 = GOLD,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(30, 36),
			Position = UDim2.fromOffset(6, 0),
			Parent = h,
		})
		local cb = back
		b.Activated:Connect(function()
			Audio.click()
			cb()
		end)
		x = 36
	end
	text({ Text = title, TextSize = 19, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(x, 4), Size = UDim2.new(1, -x - 12, 0, 26), Parent = h })
	if sub then
		text({ Text = sub, TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(x, 32), Size = UDim2.new(1, -x - 12, 0, 18), Parent = h })
	end
end

local function scroller(order: number, height: number): ScrollingFrame
	local sf: ScrollingFrame = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, height),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = GOLD_DARK,
		LayoutOrder = order,
		Selectable = false,
		Parent = screen,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
		new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8) }),
	})
	return sf
end

-- a list row: title, sub line, a tag on the right
local function row(parent: Instance, order: number, title: string, sub: string, tag: string, tagColor: Color3, onClick: () -> ()): TextButton
	local b: TextButton = new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.fromRGB(22, 22, 28),
		Size = UDim2.new(1, -24, 0, 58),
		LayoutOrder = order,
		Parent = parent,
	}, { corner(14), stroke(Color3.fromRGB(48, 46, 52), 1, 0.2) })
	text({ Text = title, TextSize = 14, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -120, 0, 20), Parent = b })
	text({ Text = sub, TextSize = 11, Font = Enum.Font.Gotham, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(14, 31), Size = UDim2.new(1, -120, 0, 16), Parent = b })
	text({ Text = tag, TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = tagColor, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(100, 20), Parent = b })
	b.Activated:Connect(function()
		Audio.click()
		onClick()
	end)
	b.SelectionGained:Connect(function()
		b.BackgroundColor3 = Color3.fromRGB(36, 34, 40)
	end)
	b.SelectionLost:Connect(function()
		b.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	end)
	return b
end

local function myPosition(): Vector3?
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	return if hrp then hrp.Position else nil
end

local function selectFirst()
	if not (phoneOpen and UserInputService.GamepadEnabled) then
		return
	end
	local last = UserInputService:GetLastInputType()
	if last.Name:sub(1, 7) ~= "Gamepad" then
		return
	end
	for _, d in screen:GetDescendants() do
		if d:IsA("TextButton") and d.Visible then
			GuiService.SelectedObject = d
			return
		end
	end
end

local function showFleet()
	view = "fleet"
	clearScreen()
	header("LEGENDS CHAUFFEUR", "Your private driver, anywhere in the city")
	local list = scroller(1, 400)
	for k, id in CH.Order do
		local spec = Cars.ById[id]
		local price = CH.Fleet[id]
		if spec and price then
			local on = contracts[id] == true
			row(list, k, spec.Name, if on then "On contract · rides are free" else "Chauffeur contract", if on then "CALL ›" else UI.formatCash(price), if on then GOLD else Theme.Money, function()
				pickedCar = id
				if on then
					view = "places"
				else
					view = "contract"
				end
				refresh()
			end)
		end
	end
end

local function showContract()
	local id = pickedCar :: string
	local spec = Cars.get(id)
	local price = CH.Fleet[id]
	clearScreen()
	header(spec.Name, "Chauffeur contract", function()
		view = "fleet"
		refresh()
	end)
	local card = new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 19, 24), Size = UDim2.new(1, -24, 0, 210), LayoutOrder = 1, Parent = screen }, { corner(16), stroke(GOLD_DARK, 1, 0.3) })
	text({ Text = "★", TextSize = 40, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, 8), Parent = card })
	text({
		Text = "A driver in a black suit and this car, whenever you call. Pay once, ride free for good.",
		TextSize = 13,
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
		Position = UDim2.fromOffset(16, 66),
		Size = UDim2.new(1, -32, 0, 60),
		Parent = card,
	})
	text({ Text = UI.formatCash(price), TextSize = 30, Font = Enum.Font.GothamBlack, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 0, 40), Parent = card })
	local sign = pill("SIGN CONTRACT", GOLD, { LayoutOrder = 2, Parent = screen })
	sign.Activated:Connect(function()
		sign.Text = "..."
		local result = invoke("buy", id)
		if result.ok then
			contracts[id] = true
			if type(result.cash) == "number" then
				UI.setCash(result.cash)
			end
			UI.toast(result.message or "Contract signed", Theme.Money)
			view = "places"
		else
			UI.toast(result.message or "Couldn't sign", Theme.Danger)
		end
		refresh()
	end)
end

local callCar: (carId: string, placeId: string) -> ()

local function showPlaces()
	local id = pickedCar :: string
	clearScreen()
	header("WHERE TO?", Cars.get(id).Name, function()
		view = "fleet"
		refresh()
	end)
	local list = scroller(1, 400)
	local here = myPosition()
	local sorted = table.clone(places)
	if here then
		local h = here :: Vector3
		table.sort(sorted, function(a, b)
			return (a.cf.Position - h).Magnitude < (b.cf.Position - h).Magnitude
		end)
	end
	for k, place in sorted do
		local dist = if here then fmtDist((place.cf.Position - here).Magnitude) else ""
		row(list, k, place.name, dist, "GO ›", GOLD, function()
			callCar(id, place.id)
		end)
	end
end

local function showStatus()
	clearScreen()
	header("YOUR CHAUFFEUR", if ride then Cars.get(ride.carId).Name else nil)
	local card = new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 19, 24), Size = UDim2.new(1, -24, 0, 170), LayoutOrder = 1, Parent = screen }, { corner(16), stroke(GOLD_DARK, 1, 0.3) })
	text({ Text = "★", TextSize = 36, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 50), Position = UDim2.fromOffset(0, 10), Parent = card })
	text({
		Name = "Status",
		Text = statusText,
		TextSize = 15,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(16, 64),
		Size = UDim2.new(1, -32, 0, 90),
		Parent = card,
	})
	local cancel = pill("CANCEL", Color3.fromRGB(60, 58, 66), { TextColor3 = Theme.Text, LayoutOrder = 2, Parent = screen })
	cancel.Activated:Connect(function()
		invoke("cancel")
		ChauffeurClient.stop()
	end)
end

function refresh()
	if not phoneOpen then
		return
	end
	if ride and (ride.phase == "coming" or ride.phase == "waiting") then
		view = "status"
	elseif view == "status" then
		view = "fleet"
	end
	if view == "contract" and pickedCar then
		showContract()
	elseif view == "places" and pickedCar then
		showPlaces()
	elseif view == "status" then
		showStatus()
	else
		showFleet()
	end
	task.defer(selectFirst)
end

local function setStatus(s: string)
	statusText = s
	if phoneOpen and view == "status" then
		local label = screen:FindFirstChild("Status", true)
		if label and label:IsA("TextLabel") then
			label.Text = s
		end
	end
end

local function syncState()
	local st = invoke("state")
	if type(st.contracts) == "table" then
		table.clear(contracts)
		for _, id in st.contracts do
			contracts[id] = true
		end
	end
end

function ChauffeurClient.open()
	if phoneOpen then
		return
	end
	if Driving.isDriving() then
		UI.toast("Get out of your car to call a chauffeur (Y)", Theme.Warning)
		return
	end
	if ride and ride.phase == "riding" then
		return
	end
	phoneOpen = true
	phone.Visible = true
	phone.Position = UDim2.new(1, -24, 1, 40)
	TweenService:Create(phone, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Position = UDim2.new(1, -24, 1, -24) }):Play()
	refresh()
	task.spawn(function()
		syncState()
		refresh()
	end)
end

function ChauffeurClient.close()
	if not phoneOpen then
		return
	end
	phoneOpen = false
	phone.Visible = false
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(phone) then
		GuiService.SelectedObject = nil
	end
end

function ChauffeurClient.toggle()
	if phoneOpen then
		ChauffeurClient.close()
	else
		ChauffeurClient.open()
	end
end

local function buildGui()
	gui = new("ScreenGui", { Name = "ChauffeurUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12, Parent = player:WaitForChild("PlayerGui") })
	local touch = UI.isTouch
	local w, h = if touch then 270 else 300, if touch then 500 else 580
	phone = new("Frame", {
		Name = "Phone",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = INK,
		Visible = false,
		Parent = gui,
	}, { corner(38), stroke(Color3.fromRGB(70, 66, 60), 3, 0) })
	new("UISizeConstraint", { MaxSize = Vector2.new(w, h), Parent = phone })
	-- the glass: a soft gold glow at the top
	local glass = new("Frame", { BackgroundColor3 = Color3.fromRGB(16, 15, 19), Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), Parent = phone }, { corner(32) })
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(46, 38, 24), Color3.fromRGB(14, 14, 18)), Rotation = 90, Parent = glass })
	-- status bar: the time, the notch, signal
	local bar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = glass })
	local clock = text({ Text = os.date("%H:%M") :: string, TextSize = 13, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(24, 8), Size = UDim2.fromOffset(60, 18), Parent = bar })
	new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(84, 22), Parent = bar }, { corner(11) })
	text({ Text = "•••  5G", TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 9), Size = UDim2.fromOffset(70, 16), Parent = bar })
	task.spawn(function()
		while gui.Parent do
			clock.Text = os.date("%H:%M") :: string
			task.wait(10)
		end
	end)
	local close: TextButton = new("TextButton", {
		AutoButtonColor = false,
		Text = "×",
		Font = Enum.Font.GothamBlack,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		BackgroundColor3 = Color3.fromRGB(32, 30, 36),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 38),
		Size = UDim2.fromOffset(28, 28),
		ZIndex = 3,
		Parent = glass,
	}, { corner(14) })
	close.Activated:Connect(function()
		Audio.click()
		ChauffeurClient.close()
	end)
	screen = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 1, -64), Parent = glass }, {
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	-- home bar
	new("Frame", { BackgroundColor3 = Color3.fromRGB(120, 116, 110), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8), Size = UDim2.fromOffset(96, 4), Parent = glass }, { corner(2) })

	-- the ride card (top centre while riding)
	rideCard = new("Frame", {
		Name = "RideCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, if touch then 12 else 22),
		Size = UDim2.fromOffset(if touch then 340 else 440, 112),
		BackgroundColor3 = INK,
		BackgroundTransparency = 0.12,
		Visible = false,
		Parent = gui,
	}, { corner(18), stroke(GOLD_DARK, 1.5, 0.15) })
	text({ Text = "★  LEGENDS CHAUFFEUR", TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -36, 0, 14), Parent = rideCard })
	rideTitle = text({ Text = "", TextSize = 19, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(18, 26), Size = UDim2.new(1, -36, 0, 24), Parent = rideCard })
	rideSub = text({ Text = "", TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = Theme.SubText, Position = UDim2.fromOffset(18, 50), Size = UDim2.new(1, -36, 0, 16), Parent = rideCard })
	local track = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 38, 44), Position = UDim2.fromOffset(18, 70), Size = UDim2.new(1, -36, 0, 3), Parent = rideCard }, { corner(2) })
	rideBar = new("Frame", { BackgroundColor3 = GOLD, Size = UDim2.fromScale(0, 1), Parent = track }, { corner(2) })
	local buttons = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 80), Size = UDim2.new(1, -36, 0, 24), Parent = rideCard }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right }),
	})
	local function small(caption: string, color: Color3, fg: Color3, order: number): TextButton
		local b: TextButton = new("TextButton", {
			AutoButtonColor = false,
			Text = caption,
			Font = Enum.Font.GothamBlack,
			TextSize = 11,
			TextColor3 = fg,
			BackgroundColor3 = color,
			Size = UDim2.fromOffset(if touch then 96 else 110, 24),
			LayoutOrder = order,
			Parent = buttons,
		}, { corner(12) })
		b.Activated:Connect(Audio.click)
		return b
	end
	local camBtn = small(if touch then "CAMERA" else "CAMERA [V]", Color3.fromRGB(40, 38, 44), Theme.Text, 1)
	local stopBtn = small("STOP HERE", Color3.fromRGB(40, 38, 44), Theme.Text, 2)
	skipBtn = small("SKIP RIDE", GOLD, INK, 3)
	camBtn.Activated:Connect(function()
		ChauffeurClient.nextShot(true)
	end)
	stopBtn.Activated:Connect(function()
		ChauffeurClient.stopHere()
	end)
	skipBtn.Activated:Connect(function()
		ChauffeurClient.skip()
	end)
end

---------------------------------------------------------------------
-- Every chauffeur car in view: body, driver, wheels
---------------------------------------------------------------------
type Look = {
	model: Model,
	root: BasePart,
	parts: { BasePart },
	offsets: { CFrame },
	wheels: { Motor6D },
	knuckles: { [Motor6D]: Motor6D },
	steerMotor: Motor6D?,
	steerMaxRot: number,
	spin: number,
	lastYaw: number?,
	steer: number,
}
local looks: { [Model]: Look } = {}

local OUR_DRIVER = {
	DriverTorso = true, DriverHead = true, DriverHair = true, DriverNeck = true, Thigh = true, Shin = true, Shoe = true,
	UpperArmL = true, UpperArmR = true, ForeArmL = true, ForeArmR = true, GloveL = true, GloveR = true, ThumbL = true, ThumbR = true,
}

-- a driver in a black suit, white shirt, black tie and cap, white gloves on the wheel (root space)
local function driverFigure(model: Model, holder: Folder): ({ BasePart }, { CFrame })
	local parts, offsets = {}, {}
	local eye = (model:GetAttribute("Eye") :: Vector3?) or Vector3.new(-1, 1, -1)
	local function add(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		if shape then
			p.Shape = shape
		end
		p.Parent = holder
		table.insert(parts, p)
		table.insert(offsets, cf)
	end
	local suit, shirt, skin = CH.SuitColor, Color3.fromRGB(236, 236, 240), Color3.fromRGB(196, 150, 118)
	local headC = CFrame.new(eye + Vector3.new(0, 0.05, 0.2))
	local torsoCF = CFrame.new(eye + Vector3.new(0, -1.4, 0.55)) * CFrame.Angles(math.rad(12), 0, 0)
	add("Torso", Vector3.new(1.35, 1.75, 0.7), torsoCF, suit, Enum.Material.Fabric)
	add("Shirt", Vector3.new(0.42, 0.8, 0.05), torsoCF * CFrame.new(0, 0.42, -0.36), shirt, Enum.Material.SmoothPlastic)
	add("Tie", Vector3.new(0.13, 0.7, 0.06), torsoCF * CFrame.new(0, 0.38, -0.39), Color3.fromRGB(10, 10, 12), Enum.Material.SmoothPlastic)
	add("Neck", Vector3.new(0.4, 0.4, 0.4), CFrame.new(eye + Vector3.new(0, -0.45, 0.3)) * CFrame.Angles(0, 0, math.pi / 2), skin, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	add("Head", Vector3.new(0.85, 0.85, 0.85), headC, skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	add("Hair", Vector3.new(0.88, 0.5, 0.88), headC * CFrame.new(0, 0.16, 0.05), Color3.fromRGB(26, 20, 16), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	-- the cap: crown, gold band, peak
	add("Cap", Vector3.new(0.34, 0.92, 0.92), headC * CFrame.new(0, 0.38, 0.02) * CFrame.Angles(0, 0, math.pi / 2), suit, Enum.Material.Fabric, Enum.PartType.Cylinder)
	add("CapBand", Vector3.new(0.08, 0.94, 0.94), headC * CFrame.new(0, 0.25, 0.02) * CFrame.Angles(0, 0, math.pi / 2), GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
	add("CapPeak", Vector3.new(0.7, 0.05, 0.32), headC * CFrame.new(0, 0.24, -0.5) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(6, 6, 8), Enum.Material.SmoothPlastic)
	-- arms to the wheel (an elbow bend from the shared arm solver)
	for _, sx in { -1, 1 } do
		local shoulder = (torsoCF * CFrame.new(sx * 0.62, 0.68, 0)).Position
		local hand = eye + Vector3.new(sx * 0.46, -0.95, -1.5)
		local upperCF, foreCF = CarBuilder.solveArm(shoulder, hand, 1.05, 1.0, Vector3.new(sx * 0.8, -1, 0.2))
		add("UpperArm", Vector3.new(0.34, 0.34, 1.1), upperCF, suit, Enum.Material.Fabric)
		add("ForeArm", Vector3.new(0.3, 0.3, 1.05), foreCF, suit, Enum.Material.Fabric)
		add("Glove", Vector3.new(0.3, 0.4, 0.34), CFrame.new(hand), shirt, Enum.Material.Fabric)
	end
	return parts, offsets
end

local lookHolder: Folder
local settingUp: { [Model]: boolean } = {}

local function setupLook(model: Model)
	if looks[model] or settingUp[model] or not model.PrimaryPart then
		return
	end
	settingUp[model] = true
	local root = model.PrimaryPart :: BasePart
	-- the boarding prompt is the rider's alone, and only once the car has stopped
	local prompt = root:WaitForChild("ChauffeurBoard", 2)
	if prompt and prompt:IsA("ProximityPrompt") and not (ride and ride.car == model and ride.phase == "waiting") then
		prompt.Enabled = false
	end
	model:WaitForChild("Chassis", 5)
	task.wait() -- let the whole car replicate
	local ok, err = pcall(CarSkin.apply, model, false)
	if not ok then
		warn("[CityLegends] chauffeur car skin failed:", err)
	end
	if not model.Parent then
		settingUp[model] = nil
		return
	end
	-- our part-built driver goes (the chauffeur takes the wheel)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and OUR_DRIVER[d.Name] then
			d.LocalTransparencyModifier = 1
		end
	end
	local holder = Instance.new("Folder")
	holder.Name = model.Name
	holder.Parent = lookHolder
	local parts, offsets = driverFigure(model, holder)
	local wheels: { Motor6D } = {}
	local knuckles: { [Motor6D]: Motor6D } = {}
	for _, j in root:GetChildren() do
		if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
			table.insert(wheels, j)
			local knuckle = root:FindFirstChild("Knuckle" .. j.Name:sub(6))
			if knuckle and knuckle:IsA("Motor6D") then
				knuckles[j] = knuckle
			end
		end
	end
	local steerMotor = root:FindFirstChild("SteerMotor")
	looks[model] = {
		model = model,
		root = root,
		parts = parts,
		offsets = offsets,
		wheels = wheels,
		knuckles = knuckles,
		steerMotor = if steerMotor and steerMotor:IsA("Motor6D") then steerMotor else nil,
		steerMaxRot = (model:GetAttribute("SteerMaxRot") :: number?) or math.rad(115),
		spin = 0,
		lastYaw = nil,
		steer = 0,
	}
	settingUp[model] = nil
	model.Destroying:Connect(function()
		looks[model] = nil
		holder:Destroy()
	end)
end

local function updateLooks(dt: number)
	local camPos = camera.CFrame.Position
	local moved: { BasePart } = {}
	local cfs: { CFrame } = {}
	for model, look in looks do
		local root = look.root
		if not root.Parent then
			continue
		end
		local rcf = root.CFrame
		local dist = (rcf.Position - camPos).Magnitude
		local far = dist > 500
		for k, p in look.parts do
			-- (far away: parked under the car, out of sight)
			table.insert(moved, p)
			table.insert(cfs, if far then rcf * CFrame.new(0, -20, 0) else rcf * look.offsets[k])
		end
		if dist < 220 then
			-- wheels roll with the car's speed, the fronts steer with its turning
			local v = root.AssemblyLinearVelocity
			local fwdSpeed = v:Dot(rcf.LookVector)
			look.spin = (look.spin - fwdSpeed * dt / 1.1) % (math.pi * 2)
			local yaw = math.atan2(-rcf.LookVector.X, -rcf.LookVector.Z)
			local yawRate = 0
			if look.lastYaw then
				local dy = (yaw - look.lastYaw + math.pi) % (2 * math.pi) - math.pi
				yawRate = dy / math.max(dt, 1e-3)
			end
			look.lastYaw = yaw
			local wb = ((model:GetAttribute("Length") :: number?) or 15) * 0.6
			local target = if math.abs(fwdSpeed) > 1 then math.atan(yawRate * wb / fwdSpeed) else 0
			look.steer += (math.clamp(target, -0.5, 0.5) - look.steer) * math.min(1, dt * 8)
			for _, m in look.wheels do
				if m:GetAttribute("Front") then
					m.Transform = CFrame.Angles(0, look.steer, 0) * CFrame.Angles(look.spin, 0, 0)
					local knuckle = look.knuckles[m]
					if knuckle then
						knuckle.Transform = CFrame.Angles(0, look.steer, 0)
					end
				else
					m.Transform = CFrame.Angles(look.spin, 0, 0)
				end
			end
			if look.steerMotor then
				look.steerMotor.Transform = CFrame.Angles(0, 0, look.steer / math.rad(28) * look.steerMaxRot)
			end
		end
	end
	if #moved > 0 then
		workspace:BulkMoveTo(moved, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

---------------------------------------------------------------------
-- Driving my chauffeur's car
---------------------------------------------------------------------
local function smoothstep(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- where on the route the car is (with a lane change eased out over three lane widths)
local function routePose(r: Ride, d: number): (Vector3, Vector3, number)
	local route = r.route :: ChauffeurRoute.Route
	local p, dir, k = ChauffeurRoute.at(route, d)
	local leg = route.legs[k]
	if leg.shift then
		local into = d - r.legStart[k]
		p += leg.shift * (1 - smoothstep(into / (Config.City.LaneWidth * 3)))
	end
	return p, dir, k
end

-- how fast the driver wants to go here: the road ahead, red lights, traffic, the stop
local function targetSpeed(r: Ride, k: number, pos: Vector3, fwd: Vector3): number
	local route = r.route :: ChauffeurRoute.Route
	local B = CH.Brake
	local d = r.d
	local vt = ChauffeurRoute.speedOf(route.legs[k].seg)
	local now = workspace:GetServerTimeNow()
	for j = k, #route.legs do
		local leg = route.legs[j]
		local startD = r.legStart[j]
		local ahead = startD - d
		if ahead > 260 then
			break
		end
		if j > k then
			vt = math.min(vt, math.sqrt(ChauffeurRoute.speedOf(leg.seg) ^ 2 + 2 * B * math.max(0, ahead)))
		end
		-- a red (or a late yellow) at the end of a city lane
		local seg = leg.seg
		if seg.signal and leg.s1 >= seg.length - 0.5 then
			local endD = startD + (leg.s1 - leg.s0) - d - 1.5
			if endD > -0.5 and endD < 120 then
				local state = CityLayout.lightState(seg.i, seg.j, seg.axis, now)
				local go = state == "G" or (state == "Y" and endD < r.v * 1.0)
				if not go then
					vt = math.min(vt, math.sqrt(2 * B * math.max(0, endD)))
				end
			end
		end
	end
	-- the end of the ride (or "stop here")
	local stopD = r.stopAt or route.length
	vt = math.min(vt, math.sqrt(2 * B * math.max(0, stopD - d)))
	-- traffic in front
	local flatFwd = Vector3.new(fwd.X, 0, fwd.Z)
	if flatFwd.Magnitude > 0.01 then
		flatFwd = flatFwd.Unit
		local flatPos = Vector3.new(pos.X, 0, pos.Z)
		local myHalfW = ((r.car and r.car:GetAttribute("Width") :: number?) or 6) / 2
		for _, npc in Traffic.near(pos + flatFwd * 24, 30) do
			local rel = npc.pos - flatPos
			local along = rel:Dot(flatFwd)
			local side = (rel - flatFwd * along).Magnitude
			-- (only what's on the car's own line: lane splitting passes cars a half lane over)
			if along > 0 and side < myHalfW + npc.width / 2 + 0.8 then
				local gap = along - npc.halfLen - 9
				vt = math.min(vt, math.max(0, math.min(npc.speed + gap * 0.5, math.sqrt(2 * B * math.max(0, gap)))))
			end
		end
	end
	return vt
end

-- the car rides the lane itself, at the lane's own height, like the traffic cars (owner,
-- 2026-10-23: a ground ray could catch a bridge or a ramp and send it flying or under the road)
local function placeCar(r: Ride, pos: Vector3, fwd: Vector3)
	local car = r.car
	if not (car and car.PrimaryPart) then
		return
	end
	local root = car.PrimaryPart :: BasePart
	local h = (car:GetAttribute("Height") :: number?) or 5
	local cf = CFrame.lookAt(pos + Vector3.new(0, h / 2 + 0.05, 0), pos + Vector3.new(0, h / 2 + 0.05, 0) + fwd)
	local ap = root:FindFirstChild("ChauffeurPosition")
	local ao = root:FindFirstChild("ChauffeurOrientation")
	if ap and ap:IsA("AlignPosition") then
		ap.Position = cf.Position
	end
	if ao and ao:IsA("AlignOrientation") then
		ao.CFrame = cf.Rotation
	end
	-- if physics ever pulls it off the road (owner: it flew up or sank), put it straight back
	if (root.Position - cf.Position).Magnitude > 6 then
		car:PivotTo(cf)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

-- Lane splitting (owner, 2026-10-29: "make the chauffeur split lanes instead of going through npc
-- cars"): stuck behind slower traffic, the driver eases onto the line between two lanes (the left
-- one first, the centre line from the inside lane) and passes; back into the lane once it's clear
local SPLIT_RATE = 7 -- studs a second sideways

-- the nearest traffic car on the line `off` studs right of the lane, between `from` and `to` along
local function carOnLine(pos: Vector3, fwd: Vector3, right: Vector3, off: number, from: number, to: number, halfW: number): Traffic.Npc?
	local flatPos = Vector3.new(pos.X, 0, pos.Z)
	local best, bestA = nil, math.huge
	for _, npc in Traffic.near(flatPos + fwd * ((from + to) / 2), (to - from) / 2 + 16) do
		local rel = npc.pos - flatPos
		local along = rel:Dot(fwd)
		local lat = rel:Dot(right) - off
		if along > from and along < to and math.abs(lat) < halfW + npc.width / 2 + 0.8 and along < bestA then
			best, bestA = npc, along
		end
	end
	return best
end

-- where across the lane the driver wants to be (0 = its centre)
local function splitTarget(r: Ride, k: number, pos: Vector3, dir: Vector3): number
	local route = r.route :: ChauffeurRoute.Route
	local seg = route.legs[k].seg
	if seg.kind == "turn" or r.stopAt then
		return 0
	end
	local fwd = Vector3.new(dir.X, 0, dir.Z)
	if fwd.Magnitude < 0.01 then
		return 0
	end
	fwd = fwd.Unit
	local right = fwd:Cross(Vector3.yAxis)
	local car = r.car
	local halfW = ((car and car:GetAttribute("Width") :: number?) or 6) / 2
	local halfL = ((car and car:GetAttribute("Length") :: number?) or 14) / 2
	local cur = r.splitTo or 0
	if cur ~= 0 then
		-- someone still beside us in the lane: stay on the line (braking if it's blocked too)
		if carOnLine(pos, fwd, right, 0, -(halfL + 6), halfL + 8, halfW) then
			return cur
		end
		-- passed: back in, unless another slow car is just ahead and the line stays clear
		local ahead = carOnLine(pos, fwd, right, 0, 0, 45, halfW)
		if ahead and ahead.speed < r.v - 2 and not carOnLine(pos, fwd, right, cur, -6, 50, halfW) then
			return cur
		end
		return 0
	end
	local blocker = carOnLine(pos, fwd, right, 0, 0, 60, halfW)
	if not (blocker and blocker.speed < ChauffeurRoute.speedOf(seg) - 4) then
		return 0
	end
	local half = Config.City.LaneWidth / 2
	local hasRight = false
	local beside: { CityLayout.Segment } = ChauffeurRoute.graph().lanesBeside[seg] or {}
	for _, other in beside do
		if other.lane == seg.lane + 1 then
			hasRight = true
		end
	end
	local sides = if seg.lane > 1 then { -half, half } else { half, -half }
	for _, off in sides do
		if (off < 0 or hasRight) and not carOnLine(pos, fwd, right, off, -12, 60, halfW) then
			return off
		end
	end
	return 0
end

local function driveStep(r: Ride, dt: number)
	if not r.route then
		return
	end
	local route = r.route :: ChauffeurRoute.Route
	local pos, dir, k = routePose(r, r.d)
	r.splitTo = splitTarget(r, k, pos, dir)
	local split = r.split or 0
	split += math.clamp((r.splitTo or 0) - split, -SPLIT_RATE * dt, SPLIT_RATE * dt)
	r.split = split
	local right = Vector3.new(dir.X, 0, dir.Z):Cross(Vector3.yAxis)
	right = if right.Magnitude > 0.01 then right.Unit else Vector3.zero
	pos += right * split
	local vt = targetSpeed(r, k, pos, dir)
	if r.v < vt then
		r.v = math.min(vt, r.v + CH.Accel * dt)
	else
		r.v = math.max(vt, r.v - CH.Brake * 1.6 * dt)
	end
	r.d = math.min(r.d + r.v * dt, r.stopAt or route.length)
	pos, dir = routePose(r, r.d)
	right = Vector3.new(dir.X, 0, dir.Z):Cross(Vector3.yAxis)
	pos += (if right.Magnitude > 0.01 then right.Unit else Vector3.zero) * split
	r.fwd = r.fwd:Lerp(dir, 1 - math.exp(-9 * dt))
	if r.fwd.Magnitude < 0.01 then
		r.fwd = dir
	end
	r.fwd = r.fwd.Unit
	placeCar(r, pos, r.fwd)
end

-- after dropping you off: pull away along the road for a few seconds
local function leaveStep(r: Ride, dt: number)
	local seg = r.leaveSeg
	if not seg then
		return
	end
	r.v = math.min(Config.mphToSps(CH.CityMph), r.v + CH.Accel * 0.6 * dt)
	r.leaveS += r.v * dt
	while r.leaveS > seg.length do
		r.leaveS -= seg.length
		local nxt = seg.next[1]
		if not nxt then
			r.leaveS = seg.length
			r.v = 0
			break
		end
		seg = nxt
	end
	r.leaveSeg = seg
	local pos, dir = CityLayout.sample(seg, r.leaveS)
	local f = r.fwd:Lerp(dir, 1 - math.exp(-6 * dt))
	r.fwd = if f.Magnitude > 0.01 then f.Unit else dir
	placeCar(r, pos, r.fwd)
end

---------------------------------------------------------------------
-- The ride camera: cinematic shots that cycle, V / Y to change
---------------------------------------------------------------------
type Shot = { name: string, at: (Model, Vector3) -> (Vector3, Vector3), fov: number, inside: boolean? }
local SHOTS: { Shot } = {
	{
		name = "chase",
		fov = 62,
		at = function(_m, _eye)
			return Vector3.new(0, 7, 26), Vector3.new(0, 2, -12)
		end,
	},
	{
		name = "side",
		fov = 50,
		at = function(_m, _eye)
			return Vector3.new(15, 2.4, -5), Vector3.new(0, 1.6, 1)
		end,
	},
	{
		name = "rear seat",
		fov = 72,
		inside = true,
		at = function(_m, eye)
			local seat = Vector3.new(-eye.X * 0.9, eye.Y + 0.15, eye.Z + 2.7)
			return seat, Vector3.new(-eye.X * 0.3, eye.Y - 0.3, eye.Z - 24)
		end,
	},
	{
		name = "aerial",
		fov = 58,
		at = function(_m, _eye)
			return Vector3.new(-20, 34, 34), Vector3.new(0, 0, -14)
		end,
	},
	{
		name = "front",
		fov = 46,
		at = function(_m, _eye)
			return Vector3.new(6, 1.8, -24), Vector3.new(0, 1.8, 0)
		end,
	},
}
local shot = 1
local shotTimer = 0
local manualUntil = 0
local blend = 0 -- seconds of slow glide left after a change of shot
local camCF: CFrame? = nil

function ChauffeurClient.nextShot(manual: boolean?)
	local was = SHOTS[shot]
	shot = shot % #SHOTS + 1
	shotTimer = 0
	if manual then
		manualUntil = os.clock() + 25
	end
	local now = SHOTS[shot]
	-- in and out of the cabin is a cut; outside shots glide
	if was.inside or now.inside then
		camCF = nil
	else
		blend = 1.4
	end
end

local function cameraStep(r: Ride, dt: number)
	local car = r.car
	if not (car and car.PrimaryPart) then
		return
	end
	shotTimer += dt
	if shotTimer > 8 and os.clock() > manualUntil then
		ChauffeurClient.nextShot(false)
	end
	local root = car.PrimaryPart :: BasePart
	local eye = (car:GetAttribute("Eye") :: Vector3?) or Vector3.new(-1, 1, -1)
	local s = SHOTS[shot]
	local from, to = s.at(car, eye)
	local rcf = root.CFrame
	-- outside shots follow a level frame (no tilt on ramps), the cabin rides with the car
	local frame = if s.inside then rcf else CFrame.lookAt(rcf.Position, rcf.Position + Vector3.new(rcf.LookVector.X, 0, rcf.LookVector.Z))
	local target = CFrame.lookAt((frame * CFrame.new(from)).Position, (frame * CFrame.new(to)).Position)
	if not camCF or s.inside then
		camCF = target
	else
		blend = math.max(0, blend - dt)
		local rate = if blend > 0 then 2.2 else 10
		camCF = (camCF :: CFrame):Lerp(target, 1 - math.exp(-rate * dt))
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = camCF :: CFrame
	camera.FieldOfView += (s.fov - camera.FieldOfView) * math.min(1, dt * 3)
end

---------------------------------------------------------------------
-- The ride's steps
---------------------------------------------------------------------
local function clearMarker(r: Ride)
	if r.marker then
		r.marker:Destroy()
		r.marker = nil
	end
end

local function updateCard(r: Ride)
	local route = r.route
	if not route then
		return
	end
	local place = placeById[r.placeId]
	rideTitle.Text = "To " .. (if place then place.name else "your stop")
	local left = math.max(0, route.length - r.d)
	local eta = left / math.max(Config.mphToSps(CH.CityMph), route.length / math.max(route.time, 1))
	rideSub.Text = Cars.get(r.carId).Name .. "  ·  " .. fmtDist(left) .. "  ·  " .. fmtTime(eta)
	rideBar.Size = UDim2.fromScale(math.clamp(r.d / math.max(route.length, 1), 0, 1), 1)
end

-- back on your feet: the normal walking camera on your new avatar
local function walkingCamera()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		camera.FieldOfView = 70
	end
end

local arriving = false
local function arrive(r: Ride)
	if arriving or r.phase ~= "riding" then
		return
	end
	arriving = true
	r.phase = "arriving"
	local result = invoke("arrive")
	arriving = false
	rideCard.Visible = false
	if not result.ok then
		ChauffeurClient.stop()
		return
	end
	-- the car pulls away on its own for a few seconds
	r.phase = "leaving"
	local route = r.route :: ChauffeurRoute.Route
	local _, _, k = ChauffeurRoute.at(route, r.d)
	local leg = route.legs[k]
	r.leaveSeg = leg.seg
	r.leaveS = math.clamp(leg.s0 + (r.d - r.legStart[k]), 0, leg.seg.length)
	r.leaveT = os.clock()
	r.v = 0
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("Humanoid", 5)
	walkingCamera()
	local place = placeById[r.placeId]
	UI.toast(if place and r.stopAt == nil then "Welcome to " .. place.name else "Enjoy your stop", GOLD)
end

function ChauffeurClient.skip()
	local r = ride
	if not (r and r.phase == "riding" and r.route) then
		return
	end
	local route = r.route :: ChauffeurRoute.Route
	r.phase = "skipping"
	UI.fade(true, 0.35)
	r.d = r.stopAt or route.length
	r.v = 0
	local pos, dir = routePose(r, r.d)
	r.fwd = dir
	placeCar(r, pos, dir)
	local car = r.car
	if car then
		car:PivotTo(CFrame.lookAt(pos, pos + dir) + Vector3.new(0, ((car:GetAttribute("Height") :: number?) or 5) / 2 + 0.05, 0))
	end
	camCF = nil
	task.wait(0.5) -- the move replicates to the server
	r.phase = "riding"
	arrive(r)
	UI.fade(false, 0.5)
end

function ChauffeurClient.stopHere()
	local r = ride
	if not (r and r.phase == "riding") then
		return
	end
	-- a gentle halt from here
	r.stopAt = r.d + (r.v * r.v) / (2 * CH.Brake * 0.8) + 2
	UI.toast("Pulling over...", GOLD)
end

local needWalkCam = false
function ChauffeurClient.stop()
	local r = ride
	ride = nil
	if r then
		clearMarker(r)
	end
	rideCard.Visible = false
	if phoneOpen then
		refresh()
	end
	if r and (r.phase == "riding" or r.phase == "arriving" or r.phase == "skipping") and not Driving.isDriving() then
		if player.Character then
			walkingCamera()
		else
			needWalkCam = true -- the server stands you up in a moment
		end
	end
end

local function marker(r: Ride, car: Model)
	clearMarker(r)
	local b = Instance.new("BillboardGui")
	b.Name = "ChauffeurMarker"
	b.AlwaysOnTop = true
	b.Size = UDim2.fromOffset(170, 44)
	b.StudsOffsetWorldSpace = Vector3.new(0, ((car:GetAttribute("Height") :: number?) or 5) / 2 + 3.5, 0)
	b.LightInfluence = 0
	b.Adornee = car.PrimaryPart
	local f = new("Frame", { BackgroundColor3 = INK, BackgroundTransparency = 0.15, Size = UDim2.fromScale(1, 1), Parent = b }, { corner(12), stroke(GOLD, 1.5, 0) })
	text({ Text = "★ YOUR CHAUFFEUR", TextSize = 13, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = f })
	b.Parent = gui
	r.marker = b
end

callCar = function(carId: string, placeId: string)
	if ride then
		invoke("cancel")
		ChauffeurClient.stop()
	end
	statusText = "Calling your driver..."
	view = "status"
	local result = invoke("call", carId, placeId)
	if not result.ok then
		UI.toast(result.message or "No driver free", Theme.Danger)
		view = "places"
		refresh()
		return
	end
	local start, pickup, dest = spotFrom(result.start), spotFrom(result.pickup), spotFrom(result.dest)
	if not (start and pickup and dest) then
		invoke("cancel")
		UI.toast("No road there yet", Theme.Danger)
		return
	end
	local r: Ride = {
		carName = result.car,
		carId = carId,
		placeId = placeId,
		phase = "coming",
		car = nil,
		route = nil,
		legStart = {},
		d = 0,
		v = 0,
		pickup = pickup,
		dest = dest,
		fwd = Vector3.zAxis,
		leaveSeg = nil,
		leaveS = 0,
		leaveT = 0,
		marker = nil,
	}
	local approach = ChauffeurRoute.find(start, pickup)
	if approach then
		setRoute(r, approach)
	else
		-- (the server put it right at the kerb)
		setRoute(r, { legs = { { seg = pickup.seg, s0 = pickup.s, s1 = pickup.s, shift = nil } }, length = 0, time = 0 })
	end
	local _, dir = CityLayout.sample(start.seg, start.s)
	r.fwd = dir
	ride = r
	refresh()
	setStatus("Your " .. Cars.get(carId).Name .. " is on its way")
	local home = folder or workspace:WaitForChild("Chauffeurs", 10) :: Folder?
	local car = home and home:WaitForChild(result.car, 10)
	if not (car and car:IsA("Model")) or ride ~= r then
		if ride == r then
			ChauffeurClient.stop()
		end
		return
	end
	r.car = car
	task.spawn(setupLook, car)
	marker(r, car)
end

-- the server says I'm in
local function boarded()
	local r = ride
	if not (r and r.car) then
		return
	end
	clearMarker(r)
	ChauffeurClient.close()
	local route = ChauffeurRoute.find(r.pickup, r.dest)
	if not route then
		invoke("cancel")
		ChauffeurClient.stop()
		UI.toast("No road there yet", Theme.Danger)
		return
	end
	setRoute(r, route)
	r.v = 0
	r.phase = "riding"
	shot = 1
	shotTimer = 0
	camCF = nil
	rideCard.Visible = true
	updateCard(r)
	UserInputService.MouseIconEnabled = true
	if UserInputService:GetLastInputType().Name:sub(1, 7) == "Gamepad" then
		GuiService.SelectedObject = skipBtn
	end
end

---------------------------------------------------------------------
-- Frame loop
---------------------------------------------------------------------
local function step(dt: number)
	updateLooks(dt)
	local r = ride
	if not r then
		return
	end
	local car = r.car
	if not car then
		return
	end
	if not car.Parent then
		ChauffeurClient.stop()
		return
	end
	if Driving.isDriving() then
		-- a car from the garage ended it (the server tidies up)
		ChauffeurClient.stop()
		return
	end
	if r.phase == "coming" or r.phase == "waiting" or r.phase == "riding" then
		driveStep(r, dt)
	elseif r.phase == "leaving" then
		leaveStep(r, dt)
		if os.clock() - r.leaveT > 7 then
			ride = nil
		end
		return
	end
	local route = r.route :: ChauffeurRoute.Route
	local stopped = r.v < 0.5 and r.d >= (r.stopAt or route.length) - 0.5
	if r.phase == "coming" and stopped then
		r.phase = "waiting"
		setStatus("Your driver is here.\nWalk to the car and press E (or tap Get in).")
		local prompt = car.PrimaryPart and car.PrimaryPart:FindFirstChild("ChauffeurBoard")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = true
		end
		UI.toast("Your chauffeur has arrived", GOLD)
	elseif r.phase == "riding" then
		updateCard(r)
		if stopped then
			task.spawn(arrive, r)
		end
	end
end

---------------------------------------------------------------------
-- Init
---------------------------------------------------------------------
function ChauffeurClient.init()
	remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	callRemote = remotes:WaitForChild("ChauffeurCall") :: RemoteFunction
	local pushRemote = remotes:WaitForChild("ChauffeurPush") :: RemoteEvent
	lookHolder = Instance.new("Folder")
	lookHolder.Name = "ChauffeurDrivers"
	lookHolder.Parent = workspace
	buildGui()
	task.spawn(ChauffeurRoute.graph) -- the parallel-lane table, ready before the first call

	-- the server's car folder: waited for in the background, so loading never hangs on it
	task.spawn(function()
		local f = workspace:WaitForChild("Chauffeurs", 60) :: Folder?
		if not f then
			warn("[CityLegends] no Chauffeurs folder in Workspace")
			return
		end
		folder = f
		for _, car in f:GetChildren() do
			if car:IsA("Model") then
				task.spawn(setupLook, car)
			end
		end
		f.ChildAdded:Connect(function(car)
			if car:IsA("Model") then
				setupLook(car)
			end
		end)
	end)

	pushRemote.OnClientEvent:Connect(function(msg: any)
		if type(msg) ~= "table" then
			return
		end
		if msg.event == "openPhone" then
			ChauffeurClient.open()
		elseif msg.event == "boarded" then
			boarded()
		elseif msg.event == "ended" then
			if ride then
				ChauffeurClient.stop()
			end
			if type(msg.reason) == "string" then
				UI.toast(msg.reason, Theme.Warning)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		local riding = ride ~= nil and ride.phase == "riding"
		if riding and (input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.ButtonY) then
			ChauffeurClient.nextShot(true)
			return
		end
		if phoneOpen and input.KeyCode == Enum.KeyCode.ButtonB then
			ChauffeurClient.close()
			return
		end
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.H or input.KeyCode == Enum.KeyCode.DPadRight then
			ChauffeurClient.toggle()
		end
	end)
	UI.onChauffeurButton = ChauffeurClient.toggle
	player.CharacterAdded:Connect(function(character)
		if needWalkCam then
			needWalkCam = false
			character:WaitForChild("Humanoid", 5)
			if not Driving.isDriving() then
				walkingCamera()
			end
		end
	end)

	RunService.Heartbeat:Connect(step)
	-- the ride camera, after the car has moved this frame
	RunService:BindToRenderStep("ChauffeurCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local r = ride
		if r and r.phase == "riding" then
			cameraStep(r, dt)
		end
	end)
end

return ChauffeurClient
