--[[
	CustomsClient
	Legends Customs on the client (owner, 2026-10-23: "make the game ... cooler"):
	  * paints every car that carries a "Custom" look (Customs.lua puts it on as JSON): paint and
	    finish on the body's paint parts, a second colour, window tint, an underglow under the car,
	    rim colour, headlight colour and the number plate. It works on the skin CarSkin builds: the
	    procedural bodies' Paint / Accent / Glass / Rim layers, and on imported models the parts
	    whose names say paint or colour (SrcName), their windows and their wheels. Everyone's
	    client does this, so everyone sees everyone's look.
	  * the tuning screen: stop in the tuning bay and the action pill says CUSTOMISE (Y). The camera
	    circles the car, every pick shows on the car at once, the total is worked out per change
	    and by the car's tier, BUY saves it (CustomsCall), CLOSE puts the saved look back.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))

local CustomsClient = {}

local CU = Config.Customs
local Theme = Config.Theme
local player = Players.LocalPlayer

type Look = { [string]: any }

---------------------------------------------------------------------
-- Painting a car
---------------------------------------------------------------------
local function rgb(v: any): Color3?
	if type(v) ~= "table" then
		return nil
	end
	return Color3.fromRGB(tonumber(v[1]) or 0, tonumber(v[2]) or 0, tonumber(v[3]) or 0)
end

local function decode(model: Model): Look
	local raw = model:GetAttribute("Custom")
	if type(raw) ~= "string" then
		return {}
	end
	local ok, look = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	return if ok and type(look) == "table" then look else {}
end

-- which kind of part a skin part is: "paint", "accent", "glass", "rim" or nil
local function isInterior(n: string): boolean
	return n:find("interior") ~= nil or n:find("^int[%s%._]") ~= nil or n:find("[%s%._]int[%s%._]") ~= nil
end
local function kindOf(p: BasePart): string?
	local name = p.Name
	if name:sub(1, 9) == "SkinPaint" then
		return "paint"
	elseif name:sub(1, 10) == "SkinAccent" then
		return "accent"
	elseif name:sub(1, 9) == "SkinGlass" then
		return "glass"
	elseif name:sub(1, 7) == "SkinRim" or name:sub(1, 9) == "SkinWheel" then
		return "rim"
	end
	if p:GetAttribute("Window") then
		return "glass"
	end
	local src = p:GetAttribute("SrcName")
	if type(src) ~= "string" then
		return nil
	end
	local n = src:lower()
	if n:sub(1, 10) == "seethrough" or (n:find("window") and not isInterior(n)) then
		return "glass"
	end
	if isInterior(n) then
		return nil
	end
	if n:find("kuzov") then
		return "paint"
	end
	for _, w in { "caliper", "disc", "inner", "spoke", "engine", "trim", "plastic", "glass", "badge", "chrome", "black", "metal", "neon", "light", "lamp", "seat" } do
		if n:find(w, 1, true) then
			return nil
		end
	end
	if n:find("color_2") or n:find("colour_2") or n:find("paint_2") or n:find("paint2") or n:find("paintb") or n:find("stripe") then
		return "accent"
	end
	if n:find("paint") or n:find("color") or n:find("colour") then
		return "paint"
	end
	return nil
end

-- what each part looked like before any look was put on (to go back)
type Orig = { color: Color3, material: Enum.Material, reflectance: number, transparency: number, texture: string?, sa: Instance? }
local originals: { [BasePart]: Orig } = setmetatable({}, { __mode = "k" }) :: any

local function remember(p: BasePart): Orig
	local o = originals[p]
	if not o then
		local tex: string? = nil
		if p:IsA("MeshPart") then
			local ok, t = pcall(function()
				return (p :: MeshPart).TextureID
			end)
			tex = if ok then t else nil
		end
		o = {
			color = p.Color,
			material = p.Material,
			reflectance = p.Reflectance,
			transparency = p.Transparency,
			texture = tex,
			sa = p:FindFirstChildOfClass("SurfaceAppearance"),
		}
		originals[p] = o
	end
	return o
end

local function restore(p: BasePart)
	local o = originals[p]
	if not o then
		return
	end
	p.Color = o.color
	p.Material = o.material
	p.Reflectance = o.reflectance
	p.Transparency = o.transparency
	if p:IsA("MeshPart") and o.texture then
		pcall(function()
			(p :: MeshPart).TextureID = o.texture :: string
		end)
	end
	if o.sa and o.sa.Parent ~= p then
		o.sa.Parent = p
	end
end

-- a solid colour on a part (its texture and surface look come off; they come back on restore)
local function solid(p: BasePart, c: Color3)
	local o = remember(p)
	p.Color = c
	if p:IsA("MeshPart") and o.texture and o.texture ~= "" then
		pcall(function()
			(p :: MeshPart).TextureID = ""
		end)
	end
	if o.sa then
		o.sa.Parent = nil
	end
end

local FINISH = {
	gloss = { Enum.Material.SmoothPlastic, 0.14 },
	matte = { Enum.Material.SmoothPlastic, 0 },
	metallic = { Enum.Material.SmoothPlastic, 0.32 },
}

-- the wheel parts that are rims: on an imported model the biggest piece of each wheel is the tyre
local function rimParts(skin: Instance): { BasePart }
	local out = {}
	local byTire: { [Instance]: { BasePart } } = {}
	for _, d in skin:GetChildren() do
		if d:IsA("BasePart") then
			if d.Name:sub(1, 7) == "SkinRim" then
				table.insert(out, d)
			elseif d.Name:sub(1, 9) == "SkinWheel" then
				local w = d:FindFirstChildOfClass("WeldConstraint")
				local tire = if w then w.Part0 else nil
				if tire then
					byTire[tire] = byTire[tire] or {}
					table.insert(byTire[tire], d)
				end
			end
		end
	end
	for _, list in byTire do
		local biggest, size = nil, -1
		for _, p in list do
			local m = math.max(p.Size.X, p.Size.Y, p.Size.Z)
			if m > size then
				biggest, size = p, m
			end
		end
		for _, p in list do
			if p ~= biggest then
				table.insert(out, p)
			end
		end
	end
	return out
end

local function underglow(model: Model, color: Color3?)
	local root = model.PrimaryPart
	local glow = model:FindFirstChild("CustomGlow") :: BasePart?
	if not color or not root then
		if glow then
			glow:Destroy()
		end
		return
	end
	if not glow then
		local width = (model:GetAttribute("Width") :: number?) or 6
		local length = (model:GetAttribute("Length") :: number?) or 14
		local height = (model:GetAttribute("Height") :: number?) or 4
		local g = Instance.new("Part")
		g.Name = "CustomGlow"
		g.Size = Vector3.new(math.max(1, width - 1.4), 0.08, math.max(2, length - 3))
		g.Material = Enum.Material.Neon
		g.Transparency = 0.25
		g.CanCollide = false
		g.CanQuery = false
		g.CanTouch = false
		g.Massless = true
		g.CastShadow = false
		g.CFrame = root.CFrame * CFrame.new(0, -height / 2 + 0.25, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = g
		w.Parent = g
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 2.4
		light.Shadows = false
		light.Parent = g
		g.Parent = model
		glow = g
	end
	local gl = glow :: BasePart
	gl.Color = color
	local light = gl:FindFirstChildOfClass("PointLight")
	if light then
		light.Color = color
	end
end

-- puts a look on a car (an empty look puts the car back as it came)
local function paintCar(model: Model, look: Look)
	local skin = model:FindFirstChild("Skin")
	local paint = rgb(look.paint)
	local accent = rgb(look.accent)
	local rim = rgb(look.rim)
	local finish = FINISH[look.finish or ""]
	local tint = CU.TintLevels[(tonumber(look.tint) or 0) + 1] or 0
	if skin then
		local rims: { [BasePart]: boolean } = {}
		for _, p in rimParts(skin) do
			rims[p] = true
		end
		for _, d in skin:GetDescendants() do
			if not d:IsA("BasePart") then
				continue
			end
			local kind = if rims[d] then "rim" else kindOf(d)
			if kind == nil or (kind == "rim" and not rims[d]) then
				continue
			end
			restore(d)
			if kind == "paint" then
				if paint then
					solid(d, paint)
				end
				if finish then
					remember(d)
					d.Material = finish[1]
					d.Reflectance = finish[2]
				end
			elseif kind == "accent" and accent then
				solid(d, accent)
			elseif kind == "glass" and tint > 0 then
				local o = remember(d)
				d.Color = o.color:Lerp(Color3.fromRGB(8, 10, 12), tint)
				d.Transparency = math.clamp(o.transparency - tint * 0.5, 0.08, 1)
			elseif kind == "rim" and rim then
				solid(d, rim)
				d.Reflectance = 0.25
			end
		end
	end
	-- the number plate's text
	local plate = model:GetAttribute("Plate")
	local plateText = model:FindFirstChild("PlateText", true)
	if plateText and type(plate) == "string" then
		local label = plateText:FindFirstChildWhichIsA("TextLabel", true)
		if label then
			label.Text = plate
		end
	end
	-- headlights
	local head = CU.Headlights[look.head or "white"] or CU.Headlights.white
	local hc = Color3.fromRGB(head[1], head[2], head[3])
	for _, d in model:GetDescendants() do
		if d:IsA("SpotLight") or (d:IsA("SurfaceLight") and d.Parent and d.Parent.Name:lower():find("head")) then
			(d :: Light).Color = hc
		end
	end
	underglow(model, rgb(look.glow))
end

-- every car with a look: painted once its skin is on, again when the look changes
local watched: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local preview: { [Model]: Look } = setmetatable({}, { __mode = "k" }) :: any -- the tuning screen's look

local function refresh(model: Model)
	if model.Parent then
		paintCar(model, preview[model] or decode(model))
	end
end

local function watch(model: Model)
	if watched[model] then
		return
	end
	watched[model] = true
	model:GetAttributeChangedSignal("Custom"):Connect(function()
		refresh(model)
	end)
	model:GetAttributeChangedSignal("Plate"):Connect(function()
		refresh(model)
	end)
end

local function onSkin(skin: Instance)
	local model = skin.Parent
	if not (model and model:IsA("Model")) then
		return
	end
	-- (the skin fills in over a moment; paint it then, and again in case it was slow)
	task.delay(0.6, function()
		if model:GetAttribute("CarId") ~= nil then
			watch(model) -- (a look bought later shows straight away)
		end
		if model:GetAttribute("Custom") ~= nil or preview[model] then
			watch(model)
			refresh(model)
		end
	end)
	task.delay(2.5, function()
		if model:GetAttribute("Custom") ~= nil then
			watch(model)
			refresh(model)
		end
	end)
end

---------------------------------------------------------------------
-- The tuning screen
---------------------------------------------------------------------
local call: RemoteFunction? = nil
local gui: ScreenGui? = nil

local function bayCF(): CFrame?
	local b = workspace:GetAttribute("CustomsBay")
	return if typeof(b) == "CFrame" then b else nil
end

local function inBay(car: Model): boolean
	local b = bayCF()
	if not b then
		return false
	end
	local d = car:GetPivot().Position - b.Position
	return Vector3.new(d.X, 0, d.Z).Magnitude <= CU.BayRadius
end

local function copy(look: Look): Look
	return HttpService:JSONDecode(HttpService:JSONEncode(look))
end

local function same(a: any, b: any): boolean
	if type(a) == "table" and type(b) == "table" then
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
	end
	return a == b
end

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. out:gsub("^,", "")
end

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(parent: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function close()
	if gui then
		gui:Destroy()
		gui = nil
	end
end

local function open()
	if gui or not call then
		return
	end
	local car = Driving.getModel()
	local root = Driving.getRoot()
	if not (car and root) then
		return
	end
	local state = (call :: RemoteFunction):InvokeServer("state")
	if type(state) ~= "table" or not state.ok then
		UI.toast(if type(state) == "table" and state.message then state.message else "Can't open Legends Customs now", Theme.Warning)
		return
	end
	local saved: Look = if type(state.look) == "table" then state.look else {}
	local look: Look = copy(saved)
	local mult = tonumber(state.mult) or 1
	local cash = tonumber(state.cash) or 0
	preview[car] = look
	watch(car)
	refresh(car)

	-- hold the car and turn the camera round it
	local conns: { RBXScriptConnection } = {}
	local finish: () -> ()
	Driving.inputEnabled = false
	Driving.cameraHold = true
	local camera = workspace.CurrentCamera
	local angle = 0.6
	local dragging = false
	local camConn = RunService.RenderStepped:Connect(function(dt)
		if not car.Parent or not root.Parent then
			finish()
			return
		end
		if not dragging then
			angle += dt * 0.22
		end
		local c = root.Position + Vector3.new(0, 1.5, 0)
		local pos = c + Vector3.new(math.sin(angle) * 17, 5.5, math.cos(angle) * 17)
		camera.CFrame = CFrame.lookAt(pos, c)
		camera.FieldOfView = 55
	end)
	local dragConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			angle -= input.Delta.X * 0.008
		elseif input.UserInputType == Enum.UserInputType.Touch and dragging then
			angle -= input.Delta.X * 0.01
		end
	end)
	local downConn = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = true
		end
	end)
	local upConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	local screen = new("ScreenGui", { Name = "LegendsCustoms", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40 }, player:WaitForChild("PlayerGui"))
	gui = screen
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(if touch then 0.46 else 0, if touch then 0 else 360, 1, -40),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.06,
	}, screen)
	corner(panel, 14)
	new("UIStroke", { Color = Theme.Stroke, Thickness = 1.5 }, panel)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -36, 0, 28),
		Font = Enum.Font.GothamBlack,
		Text = CU.Name,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
	}, panel)
	local carName = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 38),
		Size = UDim2.new(1, -36, 0, 18),
		Font = Enum.Font.Gotham,
		Text = "Drag to turn the car",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.SubText,
	}, panel)
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 62),
		Size = UDim2.new(1, -24, 1, -148),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, panel)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local order = 0

	-- footer: the total, BUY, RESET, CLOSE
	local total = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 18, 1, -52),
		Size = UDim2.new(1, -36, 0, 26),
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Money,
	}, panel)
	local function button(text: string, x: number, w: number, color: Color3, textColor: Color3): TextButton
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(x, if x == 0 then 14 else 4, 1, -12),
			Size = UDim2.new(w, -18, 0, 36),
			BackgroundColor3 = color,
			Font = Enum.Font.GothamBlack,
			Text = text,
			TextSize = 15,
			TextColor3 = textColor,
			AutoButtonColor = true,
		}, panel)
		corner(b, 8)
		return b
	end
	local buyBtn = button("BUY", 0, 0.42, Theme.Money, Theme.Background)
	local resetBtn = button("RESET", 0.42, 0.29, Theme.PanelLight, Theme.Text)
	local closeBtn = button("CLOSE", 0.71, 0.29, Theme.PanelLight, Theme.Text)

	local function cost(): number
		local sum = 0
		for k, price in CU.Prices do
			if not same(look[k], saved[k]) then
				sum += price
			end
		end
		return math.floor(sum * mult)
	end
	local refreshers: { () -> () } = {}
	local function changed()
		preview[car] = look
		refresh(car)
		local c = cost()
		total.Text = if c > 0 then "TOTAL  " .. money(c) else "NO CHANGES"
		total.TextColor3 = if c > cash then Theme.Danger else Theme.Money
		for _, f in refreshers do
			f()
		end
	end

	local function section(title: string, price: number?): Frame
		order += 1
		local f = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, list)
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, f)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamBlack,
			Text = title .. (if price then "   " .. money(price * mult) else ""),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.SubText,
			LayoutOrder = 0,
		}, f)
		return f
	end
	-- a wrap of choices; isOn tells which one is picked
	local function choices(parent: Frame, items: { { label: string?, color: Color3?, pick: () -> (), isOn: () -> boolean } })
		local grid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, parent)
		new("UIGridLayout", { CellSize = UDim2.fromOffset(if items[1] and items[1].label then 74 else 34, 34), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		for k, it in items do
			local b = new("TextButton", {
				LayoutOrder = k,
				BackgroundColor3 = it.color or Theme.PanelLight,
				Font = Enum.Font.GothamBold,
				Text = it.label or "",
				TextSize = 12,
				TextColor3 = Theme.Text,
				AutoButtonColor = true,
			}, grid)
			corner(b, 8)
			local st = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
			local function show()
				local on = it.isOn()
				st.Color = if on then Theme.Accent else Theme.Stroke
				st.Transparency = if on then 0 else 0.4
			end
			table.insert(refreshers, show)
			b.Activated:Connect(function()
				it.pick()
				changed()
			end)
		end
	end
	local function paletteItems(key: string, withNone: string?): { any }
		local items = {}
		if withNone then
			table.insert(items, { label = withNone, pick = function()
				look[key] = nil
			end, isOn = function()
				return look[key] == nil
			end })
		end
		for _, c in CU.Palette do
			local v = { c[2], c[3], c[4] }
			table.insert(items, { color = Color3.fromRGB(c[2], c[3], c[4]), pick = function()
				look[key] = { v[1], v[2], v[3] }
			end, isOn = function()
				return same(look[key], v)
			end })
		end
		return items
	end
	-- a slider 0..1 (hue / saturation / brightness of a custom paint)
	local function slider(parent: Frame, label: string, get: () -> number, set: (number) -> ())
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2 }, parent)
		new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0, 34, 1, 0), Font = Enum.Font.GothamBold, Text = label, TextSize = 12, TextColor3 = Theme.SubText }, row)
		local track = new("Frame", { Position = UDim2.new(0, 40, 0.5, -4), Size = UDim2.new(1, -48, 0, 8), BackgroundColor3 = Theme.PanelLight }, row)
		corner(track, 4)
		local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(get(), 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Text }, track)
		corner(knob, 8)
		local held = false
		local function at(x: number)
			local f = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
			set(f)
			changed()
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				held = true
				at(input.Position.X)
			end
		end)
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if held and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				at(input.Position.X)
			end
		end))
		table.insert(conns, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				held = false
			end
		end))
		table.insert(refreshers, function()
			knob.Position = UDim2.fromScale(get(), 0.5)
		end)
	end

	-- PAINT: palette, then a custom colour
	local paintSec = section("PAINT", CU.Prices.paint)
	choices(paintSec, paletteItems("paint", "STOCK"))
	local function hsv(): (number, number, number)
		local c = rgb(look.paint) or Color3.fromRGB(180, 30, 30)
		return c:ToHSV()
	end
	local function setHsv(h: number?, s: number?, v: number?)
		local h0, s0, v0 = hsv()
		local c = Color3.fromHSV(h or h0, s or s0, math.max(0.05, v or v0))
		look.paint = { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
	end
	slider(paintSec, "HUE", function()
		local h = hsv()
		return h
	end, function(f)
		setHsv(f, nil, nil)
	end)
	slider(paintSec, "SAT", function()
		local _, s = hsv()
		return s
	end, function(f)
		setHsv(nil, f, nil)
	end)
	slider(paintSec, "LUM", function()
		local _, _, v = hsv()
		return v
	end, function(f)
		setHsv(nil, nil, f)
	end)

	local finishSec = section("FINISH", CU.Prices.finish)
	local finishItems = {}
	for _, f in { { "STOCK", nil }, { "GLOSS", "gloss" }, { "MATTE", "matte" }, { "METALLIC", "metallic" } } do
		local id = f[2]
		table.insert(finishItems, { label = f[1], pick = function()
			look.finish = id
		end, isOn = function()
			return look.finish == id
		end })
	end
	choices(finishSec, finishItems)

	choices(section("SECOND COLOUR", CU.Prices.accent), paletteItems("accent", "STOCK"))

	local tintItems = {}
	for k, name in { "NONE", "LIGHT", "DARK", "LIMO" } do
		local level = k - 1
		table.insert(tintItems, { label = name, pick = function()
			look.tint = if level > 0 then level else nil
		end, isOn = function()
			return (look.tint or 0) == level
		end })
	end
	choices(section("WINDOW TINT", CU.Prices.tint), tintItems)

	local glowItems = { { label = "OFF", pick = function()
		look.glow = nil
	end, isOn = function()
		return look.glow == nil
	end } }
	for _, c in { { 0, 200, 255 }, { 140, 60, 255 }, { 255, 40, 60 }, { 40, 255, 120 }, { 255, 255, 255 }, { 255, 70, 170 }, { 255, 140, 30 }, { 40, 90, 255 } } do
		table.insert(glowItems, { color = Color3.fromRGB(c[1], c[2], c[3]), pick = function()
			look.glow = { c[1], c[2], c[3] }
		end, isOn = function()
			return same(look.glow, c)
		end })
	end
	choices(section("UNDERGLOW", CU.Prices.glow), glowItems)

	local rimItems = { { label = "STOCK", pick = function()
		look.rim = nil
	end, isOn = function()
		return look.rim == nil
	end } }
	for _, c in { { 200, 204, 210 }, { 20, 20, 22 }, { 70, 74, 80 }, { 200, 160, 70 }, { 160, 100, 60 }, { 236, 236, 232 }, { 176, 16, 20 }, { 24, 70, 160 } } do
		table.insert(rimItems, { color = Color3.fromRGB(c[1], c[2], c[3]), pick = function()
			look.rim = { c[1], c[2], c[3] }
		end, isOn = function()
			return same(look.rim, c)
		end })
	end
	choices(section("RIMS", CU.Prices.rim), rimItems)

	local headItems = {}
	for _, h in { { "WHITE", nil }, { "WARM", "warm" }, { "ICE", "ice" } } do
		local id = h[2]
		table.insert(headItems, { label = h[1], pick = function()
			look.head = id
		end, isOn = function()
			return look.head == id
		end })
	end
	choices(section("HEADLIGHTS", CU.Prices.head), headItems)

	local plateSec = section("NUMBER PLATE", CU.Prices.plate)
	local box = new("TextBox", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Color3.fromRGB(236, 236, 230),
		Font = Enum.Font.GothamBlack,
		PlaceholderText = "YOUR PLATE",
		Text = if type(look.plate) == "string" then look.plate else "",
		TextSize = 20,
		TextColor3 = Color3.fromRGB(20, 26, 60),
		ClearTextOnFocus = false,
	}, plateSec)
	corner(box, 6)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = string.upper(box.Text):gsub("[^%w ]", ""):sub(1, 8)
		if t ~= box.Text then
			box.Text = t
			return
		end
		look.plate = if #t > 0 then t else nil
		changed()
	end)

	local busy = false
	local finished = false
	finish = function()
		if finished then
			return
		end
		finished = true
		camConn:Disconnect()
		dragConn:Disconnect()
		downConn:Disconnect()
		upConn:Disconnect()
		for _, c in conns do
			c:Disconnect()
		end
		preview[car] = nil
		refresh(car)
		Driving.inputEnabled = true
		Driving.cameraHold = false
		close()
	end
	buyBtn.Activated:Connect(function()
		if busy then
			return
		end
		if cost() <= 0 then
			UI.toast("Nothing changed", Theme.Warning)
			return
		end
		busy = true
		local result = (call :: RemoteFunction):InvokeServer("buy", look)
		busy = false
		if type(result) == "table" and result.ok then
			saved = if type(result.look) == "table" then result.look else copy(look)
			look = copy(saved)
			cash = tonumber(result.cash) or cash
			UI.toast("Legends Customs: " .. money(tonumber(result.cost) or 0), Theme.Money)
			finish()
		else
			UI.toast(if type(result) == "table" and result.message then result.message else "Couldn't save that", Theme.Warning)
		end
	end)
	resetBtn.Activated:Connect(function()
		look = copy(saved)
		box.Text = if type(look.plate) == "string" then look.plate else ""
		changed()
	end)
	closeBtn.Activated:Connect(finish)
	carName.Text = "Drag to turn the car  ·  prices for this car's class"
	changed()
end

-- (the dealer menu paints its preview car in the colour picked before buying)
CustomsClient.paintCar = paintCar

function CustomsClient.init()
	task.spawn(function()
		call = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CustomsCall", 120) :: RemoteFunction?
	end)
	-- paint every car that has a look (and the ones already there)
	workspace.DescendantAdded:Connect(function(d)
		if d.Name == "Skin" and d:IsA("Model") then
			onSkin(d)
		end
	end)
	for _, d in workspace:GetDescendants() do
		if d.Name == "Skin" and d:IsA("Model") then
			onSkin(d)
		end
	end
	-- the action pill: CUSTOMISE in the tuning bay (the hotel's valet keeps its own)
	local prev = OnFoot.driveAction
	OnFoot.driveAction = function(): (string?, (() -> ())?)
		local car = Driving.getModel()
		if car and not gui and inBay(car) then
			return "CUSTOMISE", function()
				task.spawn(open)
			end
		end
		if prev then
			return prev()
		end
		return nil, nil
	end
end

return CustomsClient
