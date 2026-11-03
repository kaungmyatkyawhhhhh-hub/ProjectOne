--[[
	CarUpgrades (client) (owner, 2026-11-03: "car class grades and car levels")
	  * keeps each owned car's level, XP, Car Points and parts (CarCall "state", then the server's
	    CarProgress pushes); UI.carInfo reads them for the garage, the HUD strip over the speedometer
	    shows the driven car's class and level
	  * a level-up pops up "CAR LEVEL n" with the CP it gave
	  * the parts screen (CarUpgrades.open, from the garage's UPGRADE and Legends Customs): the 8
	    performance parts (Config.CarParts), each Street / Sport / Race, bought with the car's CP or
	    cash (the server checks and saves first); the class badge and the numbers move as you buy
	The look is the dealer menu's: dark glass panels, the showroom red, white type.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))

local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local CarUpgrades = {}

export type Info = { level: number, xp: number, need: number, cp: number, parts: CarStats.Parts }

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local kit = UI.kit
local new, label, corner, stroke = kit.new, kit.label, kit.corner, kit.stroke
local P = Config.CarParts
local L = Config.CarLevels

-- the dealer menu's look
local PANEL = Color3.fromRGB(14, 15, 19)
local PANEL2 = Color3.fromRGB(26, 27, 33)
local LINE = Color3.fromRGB(58, 60, 70)
local RED = Color3.fromRGB(226, 52, 58)
local GOLD = Color3.fromRGB(255, 196, 92)
local WHITE = Color3.fromRGB(244, 244, 246)
local GREY = Color3.fromRGB(150, 152, 162)
local GREEN = Color3.fromRGB(110, 224, 150)

local call: RemoteFunction? = nil
local cache: { [string]: { [string]: any } } = {}
local listeners: { () -> () } = {}
local gui: ScreenGui? = nil

local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. out:gsub("^,", "")
end

local function changed()
	for _, f in listeners do
		task.spawn(f)
	end
end

-- a car's level, XP, CP and parts (level 1 and nothing for a car the server hasn't told us about)
function CarUpgrades.get(carId: string): Info
	local st = cache[carId]
	if not st then
		return { level = 1, xp = 0, need = Config.carXpFor(1), cp = 0, parts = {} }
	end
	return {
		level = tonumber(st.level) or 1,
		xp = tonumber(st.xp) or 0,
		need = tonumber(st.need) or 0,
		cp = tonumber(st.cp) or 0,
		parts = CarStats.decodeParts(st.partsText),
	}
end

function CarUpgrades.onChange(fn: () -> ())
	table.insert(listeners, fn)
end

function CarUpgrades.refresh()
	if not call then
		return
	end
	local ok, res = pcall(function()
		return (call :: RemoteFunction):InvokeServer("state")
	end)
	if ok and type(res) == "table" and res.ok and type(res.cars) == "table" then
		cache = res.cars
		changed()
	end
end

---------------------------------------------------------------------
-- the HUD strip over the speedometer (the car you're driving)
---------------------------------------------------------------------
local function hudUpdate()
	local model = Driving.getModel()
	local id = model and model:GetAttribute("CarId")
	if type(id) ~= "string" or (model and (model:GetAttribute("Stolen") or model:GetAttribute("TestEnds"))) then
		UI.setCarHud(nil)
		return
	end
	local info = CarUpgrades.get(id)
	local parts = CarStats.decodeParts((model :: Model):GetAttribute("Parts"))
	local letter, _, pi = CarStats.classOf(id, parts)
	UI.setCarHud({ letter = letter, pi = pi, level = info.level, xp = info.xp, need = info.need })
end

---------------------------------------------------------------------
-- the parts screen
---------------------------------------------------------------------
local function panel(props: { [string]: any }): Frame
	local f = new("Frame", props, { corner(10), stroke(LINE, 1, 0.35) })
	f.BackgroundColor3 = props.BackgroundColor3 or PANEL
	f.BackgroundTransparency = if props.BackgroundTransparency ~= nil then props.BackgroundTransparency else 0.08
	return f
end

local function flatButton(text: string, props: { [string]: any }): TextButton
	local base = {
		AutoButtonColor = false,
		BackgroundColor3 = PANEL2,
		BackgroundTransparency = 0.05,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = WHITE,
		TextSize = 16,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(8), stroke(LINE, 1, 0.2) })
	b.Activated:Connect(Audio.click)
	return b
end

local modalBefore = false
function CarUpgrades.close()
	if gui then
		gui:Destroy()
		gui = nil
		UI.modalOpen = modalBefore -- (driving keys back, unless another screen still holds them)
	end
end

function CarUpgrades.isOpen(): boolean
	return gui ~= nil
end

function CarUpgrades.open(carId: string)
	CarUpgrades.close()
	if not Cars.ById[carId] then
		return
	end
	local spec = Cars.get(carId)
	local g = Instance.new("ScreenGui")
	g.Name = "CarUpgrades"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 60 -- over the garage, the main menu and Legends Customs
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	modalBefore = UI.modalOpen == true
	UI.modalOpen = true -- (driving keys off while it's open)
	local dim = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), Active = true, Parent = g })
	-- one design size, scaled to the screen (a phone gets the same layout, smaller)
	local W, H = 900, 560
	local root = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 0.04, Parent = dim })
	local scale = new("UIScale", { Parent = root })
	local function fit()
		local vp = camera.ViewportSize
		scale.Scale = math.clamp(math.min((vp.X - 24) / W, (vp.Y - 24) / H), 0.42, 1.25)
	end
	fit()
	local fitConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	g.Destroying:Connect(function()
		fitConn:Disconnect()
	end)

	-- header: the name, the class badge (live), the car level and CP
	label({ Text = "PERFORMANCE PARTS", TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, 14), Size = UDim2.fromOffset(400, 16), Parent = root })
	label({ Text = Cars.upper(spec.Name), TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(22, 30), Size = UDim2.fromOffset(520, 30), Parent = root })
	local _, setBadge = kit.classBadge({ Height = 34, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -74, 0, 18), Parent = root })
	local closeBtn = flatButton("×", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(42, 38), TextSize = 22, BackgroundColor3 = RED, Parent = root })
	local lvlRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 66), Size = UDim2.new(1, -44, 0, 22), Parent = root })
	local lvlText = label({ Text = "", TextSize = 15, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(130, 22), Parent = lvlRow })
	local xpBack = new("Frame", { Position = UDim2.new(0, 132, 0.5, -4), Size = UDim2.fromOffset(260, 8), BackgroundColor3 = Color3.fromRGB(60, 60, 68), BorderSizePixel = 0, Parent = lvlRow }, { corner(4) })
	local xpFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = xpBack }, { corner(4) })
	local xpText = label({ Text = "", TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(402, 0), Size = UDim2.fromOffset(150, 22), Parent = lvlRow })
	local cpPill = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(150, 26), BackgroundColor3 = Color3.fromRGB(70, 22, 26), Parent = lvlRow }, { corner(13), stroke(RED, 1, 0.2) })
	local cpText = label({ Text = "", TextSize = 14, Font = Enum.Font.GothamBlack, Size = UDim2.fromScale(1, 1), Parent = cpPill })

	-- left: the parts
	local left = panel({ Position = UDim2.fromOffset(16, 100), Size = UDim2.new(0, 560, 1, -150), BackgroundColor3 = PANEL2, BackgroundTransparency = 0.35, Parent = root })
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = LINE,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = left,
	}, { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- right: the numbers, stock and now
	local right = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 100), Size = UDim2.new(0, 292, 1, -150), BackgroundColor3 = PANEL2, BackgroundTransparency = 0.35, Parent = root })
	label({ Text = "STOCK  →  NOW", TextSize = 12, TextColor3 = GREY, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = right })
	local statRows: { [string]: TextLabel } = {}
	for i, name in { "PI", "0-60 MPH", "TOP SPEED", "HANDLING", "BRAKING", "WEIGHT", "POWER" } do
		local row = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 32 + (i - 1) * 40), Size = UDim2.new(1, -28, 0, 36), Parent = right })
		label({ Text = name, TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 14), Parent = row })
		statRows[name] = label({ Text = "", TextSize = 16, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 20), RichText = true, Parent = row })
	end

	-- footer: how it works, and a message line
	local msg = label({ Text = "", TextSize = 14, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -26), Size = UDim2.new(1, -44, 0, 18), Parent = root })
	label({
		Text = string.format("Car Points: %d per car level, for this car's parts or Legends Customs. Every car of a brand at level %d: %d%% off that brand (max %d%%).", L.CpPerLevel, L.Max, math.floor(L.BrandOff * 100 + 0.5), math.floor(L.BrandMax * 100 + 0.5)),
		TextSize = 11,
		TextColor3 = GREY,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 22, 1, -8),
		Size = UDim2.new(1, -44, 0, 14),
		Parent = root,
	})
	local function showMsg(text: string, color: Color3?)
		msg.Text = text
		msg.TextColor3 = color or GOLD
		task.delay(3, function()
			if msg.Text == text then
				msg.Text = ""
			end
		end)
	end

	local busy = false
	local openGroup: string? = nil -- a group's page is open (the engine's parts)
	local refresh: () -> ()
	local function buy(key: string, pay: string)
		if busy or not call then
			return
		end
		busy = true
		local ok, res = pcall(function()
			return (call :: RemoteFunction):InvokeServer("buyPart", { car = carId, part = key, pay = pay })
		end)
		busy = false
		if ok and type(res) == "table" and res.ok then
			local st = cache[carId] or { level = 1, xp = 0, need = Config.carXpFor(1), cp = 0 }
			st.partsText = res.partsText
			st.cp = res.cp
			cache[carId] = st
			if type(res.cash) == "number" then
				UI.setCash(res.cash)
			end
			Audio.cutUp(4, "UPGRADE")
			showMsg(P.Parts[key].name .. ": " .. P.Stages[res.stage] .. " fitted", GREEN)
			changed()
			refresh()
		else
			showMsg(if ok and type(res) == "table" and res.message then res.message else "Couldn't fit that part", Theme.Danger)
		end
	end

	refresh = function()
		local info = CarUpgrades.get(carId)
		local parts = info.parts
		local letter, _, pi = CarStats.classOf(carId, parts)
		setBadge(letter, pi)
		lvlText.Text = if info.level >= L.Max then "CAR LV MAX" else "CAR LV " .. info.level
		xpFill.Size = UDim2.fromScale(if info.need > 0 then math.clamp(info.xp / info.need, 0, 1) else 1, 1)
		xpText.Text = if info.need > 0 then string.format("%d / %d XP", info.xp, info.need) else "Brand bonus earned"
		cpText.Text = info.cp .. " CP"
		-- the numbers: stock, then with the parts
		local stock, now = Cars.get(carId), CarStats.tunedSpec(carId, parts)
		local s0, t = CarStats.of(carId), CarStats.tuneOf(parts)
		local stockLetter, _, stockPi = CarStats.classOf(carId)
		local function pair(a: string, b: string, better: boolean): string
			return if a == b then a else a .. "  →  <font color=\"#6ee096\">" .. b .. "</font>" .. (if better then "" else "")
		end
		statRows["PI"].Text = pair(stockLetter .. " " .. stockPi, letter .. " " .. pi, true)
		statRows["0-60 MPH"].Text = pair(string.format("%.1f s", stock.ZeroToSixty), string.format("%.1f s", now.ZeroToSixty), true)
		statRows["TOP SPEED"].Text = pair(stock.TopSpeed .. " mph", now.TopSpeed .. " mph", true)
		statRows["HANDLING"].Text = pair(math.floor(stock.Handling * 100 + 0.5) .. " / 100", math.floor(now.Handling * 100 + 0.5) .. " / 100", true)
		statRows["BRAKING"].Text = pair(math.floor(s0.braking * 100 + 0.5) .. " / 100", math.floor(math.min(1.2, s0.braking * (1 + t.brake * 0.6) + t.grip * 0.5) * 100 + 0.5) .. " / 100", true)
		statRows["WEIGHT"].Text = pair(s0.weightKg .. " kg", math.floor(s0.weightKg * (1 - t.weight) / 5 + 0.5) * 5 .. " kg", true)
		statRows["POWER"].Text = pair(s0.hp .. " hp", math.floor(s0.hp * (1 / math.max(1 - t.accel, 0.3)) ^ 1.18 + 0.5) .. " hp", true)
		-- the part rows: the main list, or a group's own parts (the engine) with a Back row
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		local order = 0
		local function partRow(key: string)
			local def = P.Parts[key]
			local allowed = CarStats.partAllowed(carId, key)
			local stage = if allowed then parts[key] or 0 else 0
			order += 1
			local h = if def.hint then 62 else 50
			local row = new("Frame", { BackgroundColor3 = PANEL, BackgroundTransparency = 0.15, Size = UDim2.new(1, -6, 0, h), LayoutOrder = order, Parent = list }, { corner(8) })
			label({ Text = def.icon, TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(28, 50), Parent = row })
			label({ Text = def.name, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(42, 7), Size = UDim2.fromOffset(230, 18), Parent = row })
			label({ Text = if stage > 0 then P.Stages[stage] else "STOCK", TextSize = 11, TextColor3 = if stage > 0 then GREEN else GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 27), Size = UDim2.fromOffset(120, 14), Parent = row })
			if def.hint then
				label({ Text = def.hint, TextSize = 11, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(42, 44), Size = UDim2.new(1, -56, 0, 14), Parent = row })
			end
			-- three pips, one per stage
			for k = 1, #P.Stages do
				new("Frame", { BackgroundColor3 = if k <= stage then RED else Color3.fromRGB(60, 60, 68), BorderSizePixel = 0, Position = UDim2.fromOffset(160 + (k - 1) * 22, 30), Size = UDim2.fromOffset(18, 6), Parent = row }, { corner(3) })
			end
			if not allowed then
				-- (stock S2 / R / X: only tyres, gearbox, suspension and exhaust)
				label({ Text = "🔒 Not on S2 / R / X cars", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = GREY, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 15), Size = UDim2.fromOffset(220, 20), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
			elseif stage >= #P.Stages then
				label({ Text = "MAXED", TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = GREEN, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 15), Size = UDim2.fromOffset(120, 20), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
			else
				local nextStage = stage + 1
				local cp, cash = Config.partCp(nextStage, key), Config.partCash(nextStage, spec.Price, key)
				label({ Text = P.Stages[nextStage], TextSize = 12, Font = Enum.Font.GothamBlack, TextColor3 = GREY, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -236, 0, 17), Size = UDim2.fromOffset(60, 16), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
				local cpBtn = flatButton(cp .. " CP", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -128, 0, 7), Size = UDim2.fromOffset(96, 36), TextSize = 14, BackgroundColor3 = if info.cp >= cp then RED else PANEL2, TextColor3 = if info.cp >= cp then WHITE else GREY, Parent = row })
				local cashBtn = flatButton(money(cash), { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 7), Size = UDim2.fromOffset(110, 36), TextSize = 14, TextColor3 = GREEN, Parent = row })
				cpBtn.Activated:Connect(function()
					buy(key, "cp")
				end)
				cashBtn.Activated:Connect(function()
					buy(key, "cash")
				end)
			end
		end
		local group = if openGroup then P.Groups[openGroup] else nil
		if group then
			-- a group's page: Back, then its parts
			order += 1
			local back: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = PANEL, BackgroundTransparency = 0.15, Size = UDim2.new(1, -6, 0, 36), LayoutOrder = order, Parent = list }, { corner(8) })
			label({ Text = "‹  Back to all parts   ·   " .. string.upper(group.name), TextSize = 14, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Parent = back })
			back.Activated:Connect(function()
				Audio.click()
				openGroup = nil
				refresh()
			end)
			for _, key in group.parts do
				partRow(key)
			end
		else
			for _, key in P.Menu do
				local g = P.Groups[key]
				if not g then
					partRow(key)
					continue
				end
				-- a group row (the engine): its parts fitted so far, and OPEN
				order += 1
				local fitted, total, anyAllowed = 0, #g.parts * #P.Stages, false
				for _, k in g.parts do
					if CarStats.partAllowed(carId, k) then
						anyAllowed = true
						fitted += parts[k] or 0
					end
				end
				local row = new("Frame", { BackgroundColor3 = PANEL, BackgroundTransparency = 0.15, Size = UDim2.new(1, -6, 0, 50), LayoutOrder = order, Parent = list }, { corner(8), stroke(GOLD, 1, 0.55) })
				label({ Text = g.icon, TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(28, 50), Parent = row })
				label({ Text = g.name, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 7), Size = UDim2.fromOffset(190, 18), Parent = row })
				label({ Text = string.format("%d parts  ·  %d / %d stages fitted", #g.parts, fitted, total), TextSize = 11, TextColor3 = if fitted > 0 then GREEN else GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(42, 27), Size = UDim2.fromOffset(240, 14), Parent = row })
				if anyAllowed then
					local openBtn = flatButton("OPEN  ›", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(120, 36), TextSize = 14, TextColor3 = GOLD, Parent = row })
					openBtn.Activated:Connect(function()
						openGroup = key
						refresh()
					end)
				else
					label({ Text = "🔒 Not on S2 / R / X cars", TextSize = 12, Font = Enum.Font.GothamBold, TextColor3 = GREY, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(220, 20), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
				end
			end
		end
		list.CanvasPosition = Vector2.zero
	end
	refresh()
	closeBtn.Activated:Connect(CarUpgrades.close)
	local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
		-- (Esc is always "processed": Roblox's own menu sees it too)
		if input.KeyCode == Enum.KeyCode.Escape or (not processed and input.KeyCode == Enum.KeyCode.Backspace) then
			CarUpgrades.close()
		end
	end)
	g.Destroying:Connect(function()
		keyConn:Disconnect()
	end)
end

---------------------------------------------------------------------
-- start
---------------------------------------------------------------------
function CarUpgrades.init()
	UI.carInfo = CarUpgrades.get
	UI.onUpgrade = CarUpgrades.open
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		call = remotes:WaitForChild("CarCall", 120) :: RemoteFunction?
		local progress = remotes:WaitForChild("CarProgress", 120) :: RemoteEvent?
		if progress then
			progress.OnClientEvent:Connect(function(st: any)
				if type(st) ~= "table" or type(st.carId) ~= "string" then
					return
				end
				cache[st.carId] = st
				if st.levelUp then
					local name = Cars.get(st.carId).Name
					UI.popup("CAR LEVEL " .. tostring(st.level), 0, GOLD)
					UI.toast(string.format("+%d CP for the %s: spend it on parts (garage: UPGRADE) or Legends Customs", tonumber(st.gainedCp) or 0, name), GOLD)
					if (tonumber(st.level) or 0) >= L.Max then
						task.delay(2.5, function()
							UI.toast(Cars.upper(Cars.makeOf(name)) .. " brand bonus: cheaper at Legends Motors", GREEN)
						end)
					end
				end
				changed()
			end)
		end
		CarUpgrades.refresh()
	end)
	-- the HUD strip: the car you're in (also when its parts change)
	CarUpgrades.onChange(hudUpdate)
	local lastKey = ""
	task.spawn(function()
		while true do
			task.wait(0.5)
			local model = Driving.getModel()
			local key = if model then tostring(model:GetAttribute("CarId")) .. "|" .. tostring(model:GetAttribute("Parts")) else ""
			if key ~= lastKey then
				lastKey = key
				if model and cache[tostring(model:GetAttribute("CarId"))] == nil then
					CarUpgrades.refresh() -- a car just bought: its level from the server
				end
				hudUpdate()
			end
		end
	end)
end

return CarUpgrades
