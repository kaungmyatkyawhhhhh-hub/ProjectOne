--[[
	Houses
	Housing like Driving Empire's, with our own look (owner, 2026-10-29). You buy a house's
	blueprint at Legends Realty (it stays yours), then claim a FOR SALE lot of its tier on Legends
	Isle and the house builds there (HouseBuilder). One house stands at a time: claiming another
	lot, or changing the house on yours, packs the old one away first. The lot you had is
	remembered: when you join and it's free, your last house goes back on it.

	  * every empty lot shows a Legends Properties FOR SALE sign (LOW / MID / HIGH tier, its number
	    and the tier's price range); walk up and press E to claim it with a house of that tier
	  * a placed house has a mailbox with "[Name]'s Home" in place of the sign: the owner and
	    roommates press E there for the house menu, anyone else rings the bell
	  * the house menu: teleport home, who can enter (Nobody / Friends / Everyone), roommates,
	    change house (same tier), remove, extra garage spaces
	  * the garage bays and driveway spots show the owner's cars (Garage setup, as before); E on one
	    drives it out onto the driveway
	  * leaving the game takes your house down (the lot goes back to FOR SALE); anyone standing in
	    a house that comes down is put outside on the driveway first
	Server-checked: prices, levels, cash, owning the blueprint, the lot's tier, the cooldown.

	Legends Realty (Realty.lua) opens the catalogue; its buy / sell calls come here (HouseCall).
	CityBuilder calls Houses.buildWorld (nothing to build ahead now: houses build when claimed).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))
local HouseBuilder = require(Shared:WaitForChild("HouseBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Customs = require(script.Parent:WaitForChild("Customs"))

local Houses = {}

local H = Config.Houses
local TIER_NAME = { [0] = "LOW", [1] = "MID", [2] = "HIGH" }
-- the sign's colours per tier (owner, 2026-10-29: teal / deep blue / black and gold)
local TIER_BAND = { [0] = Color3.fromRGB(14, 140, 134), [1] = Color3.fromRGB(31, 79, 163), [2] = Color3.fromRGB(17, 17, 17) }
local TIER_INK = { [0] = Color3.fromRGB(255, 255, 255), [1] = Color3.fromRGB(255, 255, 255), [2] = Color3.fromRGB(212, 175, 55) }
local POST = Color3.fromRGB(40, 42, 46)

type Rec = {
	lot: IsleLayout.Lot,
	sign: Model,
	owner: Player?,
	design: string?,
	model: Model?,
	info: any?,
	slotCars: { [number]: Model? },
	slotIds: { [number]: string },
	guests: { [number]: number }, -- user id -> until when the owner let them in (the doorbell)
	gateOpen: boolean,
	gateSeen: number, -- last time someone allowed was at the gate
}

local friendCache: { [string]: { at: number, yes: boolean } } = {}

local ctx: any
local fx: RemoteEvent? = nil
local recs: { [string]: Rec } = {}
local order: { Rec } = {}
local placed: { [Player]: string } = {} -- player -> lot id
local lastClaim: { [Player]: number } = {}
local houseFolder: Folder
local signFolder: Folder

local function money(n: number): string
	if n >= 1e6 then
		local m = n / 1e6
		return "$" .. (if m == math.floor(m) then tostring(m) else string.format("%.1f", m)) .. "M"
	elseif n >= 1e3 then
		return "$" .. math.floor(n / 1e3) .. "K"
	end
	return "$" .. tostring(math.floor(n))
end

local function send(player: Player, info: { [string]: any })
	if fx then
		fx:FireClient(player, info)
	end
end

local function toast(player: Player, text: string, color: string?)
	send(player, { kind = "toast", text = text, color = color or "accent" })
end

local function prompt(parent: Instance, action: string, object: string, hold: number?, dist: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = dist or 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

-- the price range of a tier, for its signs
local function tierRange(tier: number): string
	local lo, hi = math.huge, 0
	for _, d in H.Designs do
		if d.tier == tier then
			lo = math.min(lo, d.price)
			hi = math.max(hi, d.price)
		end
	end
	return money(lo) .. " – " .. money(hi)
end

---------------------------------------------------------------------
-- The FOR SALE signs (Legends Properties: our own design, owner 2026-10-29)
---------------------------------------------------------------------
local function signFace(board: BasePart, face: Enum.NormalId, lot: IsleLayout.Lot)
	local tier = lot.tier
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.CanvasSize = Vector2.new(600, 300)
	sg.LightInfluence = 0.35
	sg.MaxDistance = 260
	sg.Parent = board
	local function frame(y: number, h: number, color: Color3): Frame
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = color
		f.Position = UDim2.fromOffset(0, y)
		f.Size = UDim2.new(1, 0, 0, h)
		f.Parent = sg
		return f
	end
	local function text(parent: Instance, t: string, y: number, h: number, size: number, color: Color3, font: Enum.Font, x: number?)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Text = t
		l.TextColor3 = color
		l.Font = font
		l.TextSize = size
		l.TextXAlignment = if x then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
		l.Position = UDim2.fromOffset(x or 0, y)
		l.Size = UDim2.new(1, -(x or 0) * 2, 0, h)
		l.Parent = parent
		return l
	end
	local band, ink = TIER_BAND[tier], TIER_INK[tier]
	local top = frame(0, 96, band)
	text(top, "FOR SALE", 4, 88, 74, ink, Enum.Font.Oswald, 32)
	-- a plain roof line on the right (no logo)
	for _, s in { -1, 1 } do
		local r = Instance.new("Frame")
		r.BorderSizePixel = 0
		r.BackgroundColor3 = ink
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Size = UDim2.fromOffset(46, 7)
		r.Position = UDim2.fromOffset(520 + s * 19, 50)
		r.Rotation = s * 32
		r.Parent = top
	end
	local mid = frame(96, 150, Color3.fromRGB(250, 250, 247))
	local tierLabel = text(mid, TIER_NAME[tier] .. " TIER", 6, 66, 52, if tier == 2 then Color3.fromRGB(150, 118, 30) else band, Enum.Font.GothamBlack)
	tierLabel.RichText = true
	text(mid, "Walk up to claim this lot", 74, 34, 26, Color3.fromRGB(60, 62, 68), Enum.Font.GothamMedium)
	text(mid, "Lot " .. lot.number .. "  ·  " .. tierRange(tier), 110, 30, 22, Color3.fromRGB(110, 112, 118), Enum.Font.GothamBold)
	local bottom = frame(246, 54, band)
	text(bottom, "LEGENDS PROPERTIES", 6, 42, 30, ink, Enum.Font.GothamBlack)
	-- the thin white keyline inside the board's edge
	local key = Instance.new("Frame")
	key.BackgroundTransparency = 1
	key.Position = UDim2.fromOffset(8, 8)
	key.Size = UDim2.new(1, -16, 1, -16)
	key.Parent = sg
	local st = Instance.new("UIStroke")
	st.Color = if tier == 2 then Color3.fromRGB(212, 175, 55) else Color3.fromRGB(255, 255, 255)
	st.Thickness = 3
	st.Transparency = 0.15
	st.Parent = key
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 14)
	kc.Parent = key
end

local function buildSign(lot: IsleLayout.Lot): Model
	local m = Instance.new("Model")
	m.Name = "ForSale_" .. lot.id
	-- by the front edge of the lot, beside where its drive comes in, facing the road
	local base = lot.frame * CFrame.new(-lot.width / 2 + 9, 0, -lot.depth / 2 + 3)
	local function part(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): BasePart
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	for _, s in { -1, 1 } do
		part(Vector3.new(0.5, 7, 0.5), base * CFrame.new(s * 4.6, 3.5, 0), POST, Enum.Material.Metal)
		part(Vector3.new(1.4, 0.2, 1.4), base * CFrame.new(s * 4.6, 0.1, 0), POST, Enum.Material.Metal)
	end
	local board = part(Vector3.new(12, 6, 0.3), base * CFrame.new(0, 8, 0), Color3.fromRGB(250, 250, 247), Enum.Material.SmoothPlastic)
	board.Name = "Board"
	signFace(board, Enum.NormalId.Front, lot)
	signFace(board, Enum.NormalId.Back, lot)
	if lot.tier == 2 then
		-- two small ground lights shining up at the board at night
		for _, s in { -1, 1 } do
			local l = part(Vector3.new(0.8, 0.4, 0.8), base * CFrame.new(s * 2.6, 0.2, -2.4), Color3.fromRGB(255, 226, 170), Enum.Material.Neon)
			l.CanCollide = false
			local spot = Instance.new("SpotLight")
			spot.Face = Enum.NormalId.Top
			spot.Angle = 50
			spot.Range = 14
			spot.Brightness = 2.2
			spot.Color = Color3.fromRGB(255, 226, 170)
			spot.Parent = l
		end
	end
	local p = prompt(board, "Claim this lot", "Lot " .. lot.number .. " · " .. TIER_NAME[lot.tier] .. " tier", 0.4, 14)
	p.Name = "ClaimLot"
	p:SetAttribute("Lot", lot.id)
	p:SetAttribute("Tier", lot.tier)
	CollectionService:AddTag(p, "HouseClaim")
	p.Triggered:Connect(function(player: Player)
		Houses.offer(player, lot.id)
	end)
	m:SetAttribute("Lot", lot.id)
	m:SetAttribute("Tier", lot.tier)
	m.Parent = signFolder
	return m
end

---------------------------------------------------------------------
-- Owned blueprints, garage slots
---------------------------------------------------------------------
local function owns(profile: any, id: string): boolean
	return profile ~= nil and profile.Houses ~= nil and profile.Houses[id] == true
end

-- how many garage bays a placed house uses: the free ones plus the extra ones bought
local function usableBays(profile: any, id: string): number
	local d = H.ById[id]
	local extra = (profile.HouseExtraBays and profile.HouseExtraBays[id]) or 0
	return math.min(d.maxBays, d.bays + extra)
end

-- the car in each slot: the bays first, then the driveway spots ("" = empty)
local function slotList(profile: any, id: string): { string }
	local d = H.ById[id]
	local n = usableBays(profile, id) + d.drive
	local list = profile.HouseBays[id]
	if type(list) ~= "table" then
		list = {}
		profile.HouseBays[id] = list
	end
	for k = 1, n do
		if type(list[k]) ~= "string" then
			list[k] = ""
		end
	end
	for k = #list, n + 1, -1 do
		list[k] = nil
	end
	return list
end

local function fillSlots(profile: any, id: string)
	-- a new house starts with your cars in it: the one you drive first, then the dearest
	local list = slotList(profile, id)
	local ids = {}
	for carId in profile.Owned do
		table.insert(ids, carId)
	end
	table.sort(ids, function(a, b)
		if a == profile.Selected or b == profile.Selected then
			return a == profile.Selected and b ~= profile.Selected
		end
		return Cars.get(a).Price > Cars.get(b).Price
	end)
	local used = {}
	for _, c in list do
		used[c] = true
	end
	local k = 1
	for slot = 1, #list do
		if list[slot] == "" then
			while ids[k] and used[ids[k]] do
				k += 1
			end
			if ids[k] then
				list[slot] = ids[k]
				used[ids[k]] = true
				k += 1
			end
		end
	end
end

---------------------------------------------------------------------
-- Show cars in the bays and on the driveway
---------------------------------------------------------------------
local function slotFrame(rec: Rec, k: number): CFrame?
	local info = rec.info
	if not info then
		return nil
	end
	if info.bays[k] then
		return info.bays[k]
	end
	return info.drive[k - #info.bays]
end

local function displayCar(rec: Rec, k: number, carId: string)
	local spec = Cars.ById[carId]
	local at = slotFrame(rec, k)
	if not (spec and at and rec.model) then
		return
	end
	local ok, car = pcall(CarBuilder.build, spec, { interior = false, lights = true, anchored = true })
	if not ok or not car then
		warn("[CityLegends] house show car could not be built:", car)
		return
	end
	local h = (car:GetAttribute("Height") :: number?) or 4
	car:PivotTo(at + Vector3.new(0, h / 2 + 0.05, 0))
	for _, d in car:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	car.Name = "SlotCar" .. k
	local owner = rec.owner
	local ownerProfile = if owner then PlayerData.get(owner) else nil
	if ownerProfile then
		Customs.setOn(car, Customs.lookOf(ownerProfile, carId))
	end
	car:SetAttribute("Plot", rec.lot.id)
	car:SetAttribute("Bay", k)
	car:SetAttribute("CarId", car:GetAttribute("CarId") or carId)
	car.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	car.Parent = rec.model
	CollectionService:AddTag(car, "HouseShowcase")
	local root = car.PrimaryPart or car:FindFirstChildWhichIsA("BasePart")
	if root then
		local p = prompt(root, "Drive", spec.Name, 0.4, 12)
		p:SetAttribute("Plot", rec.lot.id)
		CollectionService:AddTag(p, "HouseOwner")
		p.Triggered:Connect(function(player: Player)
			Houses.drive(player, rec.lot.id, k)
		end)
	end
	rec.slotCars[k] = car
	rec.slotIds[k] = carId
end

local function refreshCars(rec: Rec)
	local owner = rec.owner
	local profile = if owner then PlayerData.get(owner) else nil
	if not (profile and rec.design and rec.model) then
		return
	end
	local want = slotList(profile, rec.design)
	for k = 1, math.max(#want, #rec.slotIds) do
		local id = want[k] or ""
		local valid = id ~= "" and profile.Owned[id] == true
		if not valid or rec.slotIds[k] ~= id or not (rec.slotCars[k] and (rec.slotCars[k] :: Model).Parent) then
			if rec.slotCars[k] then
				(rec.slotCars[k] :: Model):Destroy()
			end
			rec.slotCars[k] = nil
			rec.slotIds[k] = nil :: any
			if valid then
				displayCar(rec, k, id)
			end
		end
	end
end

---------------------------------------------------------------------
-- Placing and removing houses
---------------------------------------------------------------------
-- anyone standing in or driving through a house that is about to come down goes out to its drive
local function clearOut(rec: Rec)
	local info = rec.info
	if not info then
		return
	end
	local lot = rec.lot
	local out = info.spawn
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			local rel = lot.frame:PointToObjectSpace(root.Position)
			if math.abs(rel.X) < lot.width / 2 and math.abs(rel.Z) < lot.depth / 2 and rel.Y < 60 and rel.Y > -6 then
				char:PivotTo(out * CFrame.new(6, 3, 0))
			end
		end
	end
	local cars = workspace:FindFirstChild("PlayerCars")
	for _, car in (if cars then cars:GetChildren() else {}) do
		if car:IsA("Model") and car.PrimaryPart then
			local rel = lot.frame:PointToObjectSpace(car.PrimaryPart.Position)
			if math.abs(rel.X) < lot.width / 2 and math.abs(rel.Z) < lot.depth / 2 and rel.Y < 60 and rel.Y > -6 then
				local h = (car:GetAttribute("Height") :: number?) or 4
				car:PivotTo(out * CFrame.new(0, h / 2 + 0.6, -8))
			end
		end
	end
end

local function publish(player: Player)
	local profile = PlayerData.get(player)
	if not profile then
		return
	end
	local list = {}
	for id in profile.Houses do
		table.insert(list, id)
	end
	table.sort(list)
	player:SetAttribute("Houses", table.concat(list, ","))
	player:SetAttribute("HouseLot", placed[player])
	local rec = if placed[player] then recs[placed[player]] else nil
	player:SetAttribute("HouseDesign", if rec then rec.design else nil)
end

local function takeDown(rec: Rec)
	clearOut(rec)
	if rec.model then
		rec.model:Destroy()
	end
	rec.model = nil
	rec.info = nil
	rec.slotCars = {}
	rec.slotIds = {}
	local owner = rec.owner
	rec.owner = nil
	rec.design = nil
	rec.sign.Parent = signFolder
	if owner and placed[owner] == rec.lot.id then
		placed[owner] = nil
		publish(owner)
	end
end

-- the name over the mailbox, the house menu (owner and roommates) and the doorbell (others)
local function mailbox(rec: Rec, player: Player)
	local info = rec.info
	local model = rec.model :: Model
	local post = Instance.new("Part")
	post.Name = "MailboxPrompt"
	post.Anchored = true
	post.CanCollide = false
	post.Transparency = 1
	post.Size = Vector3.new(2, 4, 2)
	post.CFrame = info.mailbox * CFrame.new(0, 3, 0)
	post.Parent = model
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 46)
	bb.StudsOffset = Vector3.new(0, 4.6, 0)
	bb.MaxDistance = 70
	bb.Parent = post
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.62)
	name.Text = player.DisplayName .. "'s Home"
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.Font = Enum.Font.GothamBlack
	name.TextScaled = true
	name.TextStrokeTransparency = 0.5
	name.Parent = bb
	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.62)
	sub.Size = UDim2.fromScale(1, 0.38)
	sub.Text = string.upper(H.ById[rec.design :: string].name) .. "  ·  LOT " .. rec.lot.number
	sub.TextColor3 = Color3.fromRGB(220, 224, 232)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextStrokeTransparency = 0.6
	sub.Parent = bb
	local menu = prompt(post, "Your house", player.DisplayName .. "'s Home", 0, 10)
	menu.Name = "HouseMenu"
	menu:SetAttribute("Plot", rec.lot.id)
	CollectionService:AddTag(menu, "HouseOwner")
	menu.Triggered:Connect(function(who: Player)
		if Houses.mayUse(who, rec.lot.id) then
			send(who, { kind = "menu", lot = rec.lot.id })
		end
	end)
	local bell = prompt(post, "Ring the bell", player.DisplayName .. "'s Home", 0, 10)
	bell.Name = "Doorbell"
	bell.UIOffset = Vector2.new(0, 60)
	bell:SetAttribute("Plot", rec.lot.id)
	CollectionService:AddTag(bell, "HouseVisitor")
	bell.Triggered:Connect(function(who: Player)
		local owner = rec.owner
		if owner and owner ~= who then
			if Houses.mayEnter(who, rec.lot.id) then
				toast(who, "Come in: the gate and the door open for you")
				return
			end
			-- the owner gets a pop-up: LET IN or IGNORE (the intercom)
			send(owner, { kind = "bell", lot = rec.lot.id, from = who.UserId, name = who.DisplayName })
			toast(who, "You rang " .. owner.DisplayName .. "'s bell: wait for an answer")
		end
	end)
end

---------------------------------------------------------------------
-- Things in the house you can use (HouseBuilder's "Use" prompts)
---------------------------------------------------------------------
local Luxe: any = nil

local function setLights(folder: Instance, on: boolean)
	folder:SetAttribute("LightsOff", not on)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "CeilingLight" then
			d.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			d.Color = if on then Color3.fromRGB(255, 214, 160) else Color3.fromRGB(70, 68, 64)
		elseif d:IsA("Light") and d.Parent and d.Parent.Name ~= "TVScreen" and not d.Parent:FindFirstChildOfClass("Fire") then
			-- (every lamp in this floor, or in a ready-made house; not a fireplace's or a TV's glow)
			d.Enabled = on
		end
	end
end

-- a door or the fridge's door: between its closed and open CFrames
local function swing(part: BasePart, open: boolean, time: number, solid: boolean)
	local target = part:GetAttribute(if open then "OpenCF" else "ClosedCF")
	if typeof(target) ~= "CFrame" then
		return
	end
	part:SetAttribute("Open", open)
	part.CanCollide = solid or not open
	TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = target }):Play()
end

local USE: { [string]: (Rec, ProximityPrompt, Player) -> () } = {}
USE.door = function(_rec, p, _who)
	local leaf = p.Parent :: BasePart
	local open = not leaf:GetAttribute("Open")
	swing(leaf, open, 0.45, false)
	-- (its handle is a separate part that stays: hide it while the door is open)
	local model = leaf.Parent
	if model then
		for _, h in model:GetChildren() do
			if h:IsA("BasePart") and h.Name == "Handle" and (h.Position - (leaf:GetAttribute("ClosedCF") :: CFrame).Position).Magnitude < 3.2 then
				h.Transparency = if open then 1 else 0
			end
		end
	end
	p.ActionText = if open then "Close" else "Open"
end
USE.fridge = function(_rec, p, _who)
	local leaf = p.Parent :: BasePart
	local open = not leaf:GetAttribute("Open")
	swing(leaf, open, 0.35, true)
	p.ActionText = if open then "Close" else "Open"
end
USE.light = function(_rec, p, _who)
	-- (the floor's group, or the whole ready-made body)
	local folder: Instance? = p.Parent
	while folder and not (folder:IsA("Model") and (folder.Name == "Body" or folder.Name:match("^Floor%d"))) do
		folder = folder.Parent
	end
	if folder then
		local on = folder:GetAttribute("LightsOff") == true
		setLights(folder, on)
		p.ActionText = if on then "Lights off" else "Lights on"
	end
end
USE.tv = function(_rec, p, _who)
	local screen = p.Parent :: BasePart
	local on = not screen:GetAttribute("On")
	screen:SetAttribute("On", on)
	for _, pic in screen:GetDescendants() do
		if pic.Name == "Picture" and pic:IsA("GuiObject") then
			pic.Visible = on
		elseif pic:IsA("SurfaceLight") then
			pic.Enabled = on -- (a ready-made TV's glow)
		end
	end
	p.ActionText = if on then "Turn off" else "Turn on"
end
local WATER_TEXT = { tap = { "Tap on", "Tap off" }, shower = { "Shower on", "Shower off" }, bath = { "Run a bath", "Turn off" } }
local function waterUse(kind: string)
	return function(_rec: Rec, p: ProximityPrompt, _who: Player)
		local part = p.Parent :: BasePart
		local e = part:FindFirstChild("Water") :: ParticleEmitter?
		if not e then
			return
		end
		e.Enabled = not e.Enabled
		p.ActionText = WATER_TEXT[kind][if e.Enabled then 2 else 1]
		if kind == "bath" then
			-- the bath fills up after a moment, and empties when turned off
			local folder = p:FindFirstAncestorWhichIsA("Model")
			local bw = folder and folder:FindFirstChild("BathWater", true) :: BasePart?
			if bw and e.Enabled then
				task.delay(2.5, function()
					if e.Enabled then
						TweenService:Create(bw, TweenInfo.new(2), { Transparency = 0.3 }):Play()
					end
				end)
			elseif bw then
				TweenService:Create(bw, TweenInfo.new(2), { Transparency = 1 }):Play()
			end
		end
	end
end
USE.tap = waterUse("tap")
USE.shower = waterUse("shower")
USE.bath = waterUse("bath")
USE.stove = function(_rec, p, _who)
	local stove = p.Parent :: BasePart
	local on = not stove:GetAttribute("On")
	stove:SetAttribute("On", on)
	stove.Color = if on then Color3.fromRGB(255, 80, 30) else Color3.fromRGB(20, 20, 22)
	stove.Material = if on then Enum.Material.Neon else Enum.Material.Glass
	p.ActionText = if on then "Turn off" else "Turn on"
end
USE.fireplace = function(_rec, p, _who)
	local box = p.Parent :: BasePart
	local fire = box:FindFirstChildOfClass("Fire")
	local glow = box:FindFirstChildOfClass("PointLight")
	local on = not (fire and fire.Enabled)
	if fire then
		fire.Enabled = on
	end
	if glow then
		glow.Enabled = on
	end
	p.ActionText = if on then "Put it out" else "Light the fire"
end
USE.curtain = function(_rec, p, _who)
	local folder = p:FindFirstAncestorWhichIsA("Model")
	if not folder then
		return
	end
	local closing = p.ActionText == "Close curtains"
	for _, c in folder:GetDescendants() do
		if c:IsA("BasePart") and c.Name == "Curtain" then
			TweenService:Create(c, TweenInfo.new(0.6), { Transparency = if closing then 0 else 1 }):Play()
		end
	end
	p.ActionText = if closing then "Open curtains" else "Close curtains"
end
USE.bed = function(_rec, _p, who)
	send(who, { kind = "sleep" })
end
USE.wardrobe = function(_rec, _p, who)
	-- your outfit: the Flex pieces you own, worn or taken off (the Gem Showcase's screen)
	if Luxe == nil then
		local ok, m = pcall(function()
			return require(script.Parent:WaitForChild("Luxe")) :: any
		end)
		Luxe = if ok then m else false
	end
	if Luxe then
		Luxe.fire(who, { kind = "openShop" })
	end
end

local function bindUses(rec: Rec, model: Model)
	local last: { [ProximityPrompt]: number } = {}
	for _, p in model:GetDescendants() do
		if p:IsA("ProximityPrompt") and p:GetAttribute("Use") then
			local kind = p:GetAttribute("Use") :: string
			local fn = USE[kind]
			if fn then
				p.Triggered:Connect(function(who: Player)
					if last[p] and os.clock() - last[p] < 0.3 then
						return
					end
					last[p] = os.clock()
					if not Houses.mayEnter(who, rec.lot.id) then
						toast(who, if kind == "door" then "Locked: ring the bell at the gate" else "You need to be let in first", "warning")
						return
					end
					fn(rec, p, who)
				end)
			end
		end
	end
end

---------------------------------------------------------------------
-- The house gates: open for the owner, roommates, let-in guests and the owner's access setting;
-- they close again about 5 s after the last of them has gone through
---------------------------------------------------------------------
local GATE_RANGE = 30
local GATE_TIME = 3

local function moveGate(rec: Rec, open: boolean)
	local info = rec.info
	if not info or rec.gateOpen == open then
		return
	end
	rec.gateOpen = open
	for _, g in info.gates do
		local part = g.part
		if part.Parent then
			for _, c in part:GetDescendants() do
				if c:IsA("BasePart") and c.Name == "GatePanel" then
					c.CanCollide = not open
				end
			end
			part.CanCollide = not open
			TweenService:Create(part, TweenInfo.new(GATE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = if open then g.open else g.closed }):Play()
		end
	end
	-- a motor hum while they move
	local first = info.gates[1] and info.gates[1].part
	if first then
		local motor = first:FindFirstChild("GateMotor") :: Sound?
		if not motor then
			local m = Instance.new("Sound")
			m.Name = "GateMotor"
			m.SoundId = "rbxasset://sounds/action_falling.ogg"
			m.PlaybackSpeed = 0.3
			m.Volume = 0.5
			m.Looped = true
			m.RollOffMaxDistance = 120
			m.Parent = first
			motor = m
		end
		local snd = motor :: Sound
		snd:Play()
		task.delay(GATE_TIME, function()
			snd:Stop()
		end)
	end
end

local function gateStep()
	local cars = workspace:FindFirstChild("PlayerCars")
	for _, rec in order do
		local info = rec.info
		if rec.owner and info and info.gateAt and #info.gates > 0 then
			local at = info.gateAt.Position
			local allowed = false
			-- people on foot
			for _, p in Players:GetPlayers() do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and (root.Position - at).Magnitude < GATE_RANGE and Houses.mayEnter(p, rec.lot.id) then
					allowed = true
					break
				end
			end
			-- cars: the driver (the owner of a car nobody has got out of) and riders
			if not allowed and cars then
				for _, car in cars:GetChildren() do
					local root = car:IsA("Model") and car.PrimaryPart
					if root and (root.Position - at).Magnitude < GATE_RANGE + 10 then
						local owner = Players:GetPlayerByUserId((car:GetAttribute("Owner") :: number?) or 0)
						if owner and not owner.Character and Houses.mayEnter(owner, rec.lot.id) then
							allowed = true
						end
						for _, s in car:GetChildren() do
							if s:IsA("Seat") and s.Occupant then
								local rider = Players:GetPlayerFromCharacter(s.Occupant.Parent)
								if rider and Houses.mayEnter(rider, rec.lot.id) then
									allowed = true
								end
							end
						end
					end
					if allowed then
						break
					end
				end
			end
			if allowed then
				rec.gateSeen = os.clock()
				moveGate(rec, true)
			elseif rec.gateOpen and os.clock() - rec.gateSeen > 5 then
				moveGate(rec, false)
			end
		end
	end
end

local function build(rec: Rec, player: Player, id: string)
	local d = H.ById[id]
	local model, info = HouseBuilder.build(d, rec.lot.frame, rec.lot.width, rec.lot.depth, { interior = true })
	model.Name = "House_" .. rec.lot.id
	model:SetAttribute("Plot", rec.lot.id)
	model:SetAttribute("Design", id)
	model:SetAttribute("Owner", player.UserId)
	model:SetAttribute("OwnerName", player.DisplayName)
	rec.model = model
	rec.info = info
	rec.owner = player
	rec.design = id
	rec.sign.Parent = nil
	mailbox(rec, player)
	-- the owner's garage setup, at the first bay
	local first = info.bays[1]
	if first then
		local anchor = Instance.new("Part")
		anchor.Name = "GarageSetup"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(2, 2, 2)
		anchor.CFrame = first * CFrame.new(0, 3, 6)
		anchor.Parent = model
		local setup = prompt(anchor, "Garage setup", d.name, 0, 14)
		setup.Name = "GarageSetup"
		setup:SetAttribute("Plot", rec.lot.id)
		CollectionService:AddTag(setup, "HouseOwner")
		setup.Triggered:Connect(function(who: Player)
			if rec.owner == who then
				send(who, { kind = "garage", plot = rec.lot.id })
			end
		end)
	end
	bindUses(rec, model)
	rec.guests = {}
	rec.gateOpen = false
	rec.gateSeen = 0
	model.Parent = houseFolder
	CollectionService:AddTag(model, "IslandHouse")
	refreshCars(rec)
end

-- put `id` on `lotId` for `player` (taking down whatever they had placed)
local function place(player: Player, lotId: string, id: string): (boolean, string?)
	local rec = recs[lotId]
	local profile = PlayerData.get(player)
	local d = H.ById[id]
	if not (rec and profile and d) then
		return false, "Something went wrong"
	end
	if not owns(profile, id) then
		return false, "You don't own that house yet: buy it at Legends Realty"
	end
	if d.tier ~= rec.lot.tier then
		return false, TIER_NAME[d.tier] .. " houses need a " .. TIER_NAME[d.tier] .. " lot"
	end
	if rec.owner and rec.owner ~= player then
		return false, "This lot belongs to " .. rec.owner.DisplayName
	end
	local mine = placed[player]
	if mine ~= lotId and lastClaim[player] and os.clock() - lastClaim[player] < H.ClaimCooldown then
		return false, "Wait " .. math.ceil(H.ClaimCooldown - (os.clock() - lastClaim[player])) .. " s before claiming another lot"
	end
	if mine then
		takeDown(recs[mine])
	end
	if mine ~= lotId then
		lastClaim[player] = os.clock()
	end
	fillSlots(profile, id)
	build(rec, player, id)
	placed[player] = lotId
	profile.HomeLot = lotId
	profile.HomeDesign = id
	publish(player)
	task.spawn(PlayerData.save, player)
	return true, nil
end

-- when you join (or own a house again): your last house back on your lot if it's free
local function settle(player: Player)
	local profile = PlayerData.get(player)
	if not profile or placed[player] then
		publish(player)
		return
	end
	local id = profile.HomeDesign
	local lotId = profile.HomeLot
	if type(id) == "string" and owns(profile, id) and type(lotId) == "string" then
		local rec = recs[lotId]
		if rec and not rec.owner and rec.lot.tier == H.ById[id].tier then
			place(player, lotId, id)
			return
		end
		send(player, { kind = "toast", text = "Your lot is taken in this server: claim another FOR SALE lot (House menu)", color = "warning" })
	end
	publish(player)
end

---------------------------------------------------------------------
-- Who may use a house
---------------------------------------------------------------------
function Houses.mayUse(player: Player, lotId: string): boolean
	local rec = recs[lotId]
	local owner = rec and rec.owner
	if not owner then
		return false
	end
	if owner == player then
		return true
	end
	local profile = PlayerData.get(owner)
	local mates = profile and profile.Roommates
	return type(mates) == "table" and table.find(mates, player.UserId) ~= nil
end

-- may this player come in (the house gates, later): owner, roommates, then the owner's setting
function Houses.mayEnter(player: Player, lotId: string): boolean
	if Houses.mayUse(player, lotId) then
		return true
	end
	local rec = recs[lotId]
	local owner = rec and rec.owner
	local profile = owner and PlayerData.get(owner)
	if rec and rec.guests and (rec.guests[player.UserId] or 0) > os.clock() then
		return true -- let in at the doorbell
	end
	local access = profile and profile.HouseAccess or "friends"
	if access == "everyone" then
		return true
	elseif access == "friends" and owner then
		-- (asked once a minute: the gates check several times a second)
		local key = player.UserId .. ":" .. owner.UserId
		local hit = friendCache[key]
		if hit and os.clock() - hit.at < 60 then
			return hit.yes
		end
		local ok, friends = pcall(function()
			return player:IsFriendsWithAsync(owner.UserId)
		end)
		local yes = ok and friends == true
		friendCache[key] = { at = os.clock(), yes = yes }
		return yes
	end
	return false
end

---------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------
-- E on a FOR SALE sign: the houses you own that fit this lot (or where to buy one)
function Houses.offer(player: Player, lotId: string)
	local rec = recs[lotId]
	local profile = PlayerData.get(player)
	if not (rec and profile) then
		return
	end
	if rec.owner then
		toast(player, "This lot belongs to " .. rec.owner.DisplayName, "warning")
		return
	end
	local fits = {}
	for _, d in H.Designs do
		if d.tier == rec.lot.tier and owns(profile, d.id) then
			table.insert(fits, d.id)
		end
	end
	send(player, { kind = "claim", lot = lotId, tier = rec.lot.tier, options = fits, last = profile.HomeDesign })
end

function Houses.drive(player: Player, lotId: string, slot: number)
	local rec = recs[lotId]
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player and rec.info) then
		return
	end
	local id = rec.slotIds[slot]
	if not (id and profile.Owned[id]) then
		return
	end
	if ctx and ctx.spawnAt then
		local at = rec.info.spawn
		ctx.spawnAt[player] = at
		task.delay(H.DriveTimeout, function()
			if ctx.spawnAt[player] == at then
				ctx.spawnAt[player] = nil
			end
		end)
	end
	send(player, { kind = "drive", id = id })
end

-- teleport home: the car (when driving) onto the drive, or you to the front door
local function goHome(player: Player): boolean
	local lotId = placed[player]
	local rec = lotId and recs[lotId]
	if not (rec and rec.info) then
		return false
	end
	local cars = workspace:FindFirstChild("PlayerCars")
	local car = cars and cars:FindFirstChild(player.Name)
	local target = if car and not player.Character then rec.info.spawn else rec.info.door
	pcall(function()
		player:RequestStreamAroundAsync(target.Position, 6)
	end)
	if car and car:IsA("Model") and not player.Character then
		local h = (car:GetAttribute("Height") :: number?) or 4
		car:PivotTo(target + Vector3.new(0, h / 2 + 0.8, 0))
		local root = car.PrimaryPart
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	elseif player.Character then
		player.Character:PivotTo(target + Vector3.new(0, 3, 0))
	end
	return true
end

-- the calls from the client (RemoteFunction HouseCall)
local handlers: { [string]: (Player, any) -> any } = {}

handlers.garage = function(player, lotId)
	local rec = if type(lotId) == "string" then recs[lotId] else nil
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player and rec.design) then
		return { ok = false }
	end
	local owned = {}
	for id in profile.Owned do
		table.insert(owned, id)
	end
	local d = H.ById[rec.design]
	return { ok = true, kind = rec.design, name = d.name, bays = table.clone(slotList(profile, rec.design)), garage = usableBays(profile, rec.design), owned = owned }
end

handlers.setBay = function(player, arg)
	if type(arg) ~= "table" or type(arg.plot) ~= "string" or type(arg.bay) ~= "number" or type(arg.car) ~= "string" then
		return { ok = false }
	end
	local rec = recs[arg.plot]
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.owner == player and rec.design) then
		return { ok = false }
	end
	local list = slotList(profile, rec.design)
	local bay = math.floor(arg.bay)
	if bay < 1 or bay > #list then
		return { ok = false }
	end
	if arg.car ~= "" and not profile.Owned[arg.car] then
		return { ok = false, message = "You don't own that car" }
	end
	if arg.car ~= "" then
		for k = 1, #list do
			if k ~= bay and list[k] == arg.car then
				list[k] = list[bay]
			end
		end
	end
	list[bay] = arg.car
	refreshCars(rec)
	task.spawn(PlayerData.save, player)
	return { ok = true, bays = table.clone(list) }
end

-- claim a lot with one of your houses (after the ghost preview)
handlers.place = function(player, arg)
	if type(arg) ~= "table" or type(arg.lot) ~= "string" or type(arg.design) ~= "string" then
		return { ok = false }
	end
	local ok, why = place(player, arg.lot, arg.design)
	if ok then
		send(player, { kind = "placed", lot = arg.lot, design = arg.design, text = "Welcome home: " .. H.ById[arg.design].name })
	end
	return { ok = ok, message = why }
end

-- the house menu
handlers.menu = function(player, lotId)
	local rec = if type(lotId) == "string" then recs[lotId] else nil
	if not (rec and Houses.mayUse(player, lotId)) then
		return { ok = false }
	end
	local owner = rec.owner :: Player
	local profile = PlayerData.get(owner)
	local mates = {}
	for _, uid in (profile and profile.Roommates or {}) do
		local p = Players:GetPlayerByUserId(uid)
		table.insert(mates, { id = uid, name = if p then p.DisplayName else ("Player " .. uid) })
	end
	local fits = {}
	if owner == player and profile then
		for _, d in H.Designs do
			if d.tier == rec.lot.tier and owns(profile, d.id) then
				table.insert(fits, d.id)
			end
		end
	end
	local d = H.ById[rec.design :: string]
	local extra = if profile then usableBays(profile, d.id) - d.bays else 0
	local nextPrice = if usableBays(profile, d.id) < d.maxBays then H.BayPrices[math.min(#H.BayPrices, extra + 1)] else nil
	return {
		ok = true,
		owner = owner == player,
		design = d.id,
		lot = rec.lot.number,
		access = profile and profile.HouseAccess or "friends",
		roommates = mates,
		fits = fits,
		garage = if profile then usableBays(profile, d.id) else d.bays,
		maxGarage = d.maxBays,
		bayPrice = nextPrice,
	}
end

-- the owner answers the doorbell: let them in for two minutes
handlers.letIn = function(player, arg)
	if type(arg) ~= "table" or type(arg.from) ~= "number" then
		return { ok = false }
	end
	local lotId = placed[player]
	local rec = lotId and recs[lotId]
	if not rec then
		return { ok = false }
	end
	local guest = Players:GetPlayerByUserId(arg.from)
	if arg.yes then
		rec.guests[arg.from] = os.clock() + 120
		if guest then
			toast(guest, player.DisplayName .. " let you in: the gate and the door open for you")
		end
	elseif guest then
		toast(guest, player.DisplayName .. " did not answer the door", "warning")
	end
	return { ok = true }
end

handlers.access = function(player, value)
	local profile = PlayerData.get(player)
	if not profile or (value ~= "nobody" and value ~= "friends" and value ~= "everyone") then
		return { ok = false }
	end
	profile.HouseAccess = value
	task.spawn(PlayerData.save, player)
	return { ok = true, access = value }
end

handlers.roommate = function(player, arg)
	local profile = PlayerData.get(player)
	if not profile or type(arg) ~= "table" or type(arg.id) ~= "number" then
		return { ok = false }
	end
	profile.Roommates = profile.Roommates or {}
	local list = profile.Roommates
	local at = table.find(list, arg.id)
	if arg.add then
		local other = Players:GetPlayerByUserId(arg.id)
		if not other or other == player then
			return { ok = false, message = "They need to be in this server" }
		end
		if not at and #list < 6 then
			table.insert(list, arg.id)
			toast(other, player.DisplayName .. " made you a roommate: you can use their house")
		end
	elseif at then
		table.remove(list, at)
	end
	task.spawn(PlayerData.save, player)
	return { ok = true }
end

handlers.remove = function(player)
	local lotId = placed[player]
	if lotId then
		takeDown(recs[lotId])
	end
	return { ok = true }
end

handlers.home = function(player)
	if goHome(player) then
		return { ok = true }
	end
	-- no house standing: put the last one back if its lot is free
	local profile = PlayerData.get(player)
	if profile and type(profile.HomeDesign) == "string" and type(profile.HomeLot) == "string" then
		local rec = recs[profile.HomeLot]
		if rec and not rec.owner then
			local ok, why = place(player, profile.HomeLot, profile.HomeDesign)
			if ok then
				goHome(player)
				return { ok = true }
			end
			return { ok = false, message = why }
		end
	end
	return { ok = false, message = "You have no house standing: buy one at Legends Realty, then claim a FOR SALE lot" }
end

handlers.buyBay = function(player)
	local lotId = placed[player]
	local rec = lotId and recs[lotId]
	local profile = PlayerData.get(player)
	if not (rec and profile and rec.design) then
		return { ok = false }
	end
	local d = H.ById[rec.design]
	local have = usableBays(profile, d.id)
	if have >= d.maxBays then
		return { ok = false, message = "This garage is full size" }
	end
	local price = H.BayPrices[math.min(#H.BayPrices, have - d.bays + 1)]
	if profile.Cash < price then
		return { ok = false, message = "You need " .. money(price) }
	end
	PlayerData.addCash(player, -price)
	profile.HouseExtraBays = profile.HouseExtraBays or {}
	profile.HouseExtraBays[d.id] = (profile.HouseExtraBays[d.id] or 0) + 1
	-- the house is rebuilt on the same lot with the new space (cars come back in it)
	takeDown(rec)
	build(rec, player, d.id)
	placed[player] = lotId :: string
	publish(player)
	task.spawn(PlayerData.save, player)
	return { ok = true }
end

-- Legends Realty: the catalogue's data, buying and selling blueprints
handlers.catalog = function(player)
	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false }
	end
	local mine = {}
	for id in profile.Houses do
		table.insert(mine, id)
	end
	return { ok = true, owned = mine, cash = profile.Cash, level = profile.Level, placed = if placed[player] then recs[placed[player]].design else nil }
end

handlers.buy = function(player, id)
	local profile = PlayerData.get(player)
	local d = if type(id) == "string" then H.ById[id] else nil
	if not (profile and profile.Loaded and d) then
		return { ok = false, message = "Something went wrong" }
	end
	if owns(profile, d.id) then
		return { ok = false, message = "You own this house already" }
	end
	if (profile.Level or 1) < d.level then
		return { ok = false, message = "Unlocks at level " .. d.level }
	end
	if profile.Cash < d.price then
		return { ok = false, message = "You need " .. money(d.price) }
	end
	PlayerData.addCash(player, -d.price)
	profile.Houses[d.id] = true
	publish(player)
	task.spawn(PlayerData.save, player)
	return { ok = true, cash = profile.Cash }
end

handlers.sell = function(player, id)
	local profile = PlayerData.get(player)
	local d = if type(id) == "string" then H.ById[id] else nil
	if not (profile and d and owns(profile, d.id)) then
		return { ok = false, message = "You don't own that house" }
	end
	local lotId = placed[player]
	if lotId and recs[lotId].design == d.id then
		takeDown(recs[lotId])
	end
	profile.Houses[d.id] = nil
	if profile.HomeDesign == d.id then
		profile.HomeDesign = nil
	end
	local back = math.floor(d.price * H.SellBack)
	PlayerData.addCash(player, back)
	publish(player)
	task.spawn(PlayerData.save, player)
	return { ok = true, cash = profile.Cash, refund = back }
end

-- after an unlock from the console, or buying: put the last house back
function Houses.refresh(player: Player)
	settle(player)
end

-- the lot a player's house stands on (other systems)
function Houses.placedLot(player: Player): string?
	return placed[player]
end

function Houses.buildWorld(_kit: any, _parent: Instance)
	-- (houses build when a lot is claimed; the lots and their signs come up in init)
end

function Houses.init(c: any)
	ctx = c
	ctx.spawnAt = ctx.spawnAt or {}
	fx = ctx.remote("RemoteEvent", "HouseFx")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "HouseCall")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	houseFolder = Instance.new("Folder")
	houseFolder.Name = "IslandHouses"
	houseFolder.Parent = workspace
	signFolder = Instance.new("Folder")
	signFolder.Name = "IslandLots"
	signFolder.Parent = workspace
	for _, lot in IsleLayout.lots() do
		local rec: Rec = { lot = lot, sign = buildSign(lot), owner = nil, design = nil, model = nil, info = nil, slotCars = {}, slotIds = {}, guests = {}, gateOpen = false, gateSeen = 0 }
		recs[lot.id] = rec
		table.insert(order, rec)
	end
	local function watch(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 30
			while not PlayerData.get(player) and os.clock() < deadline and player.Parent do
				task.wait(0.25)
			end
			if player.Parent then
				settle(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	task.spawn(function()
		while true do
			task.wait(0.3)
			local ok, err = pcall(gateStep)
			if not ok then
				warn("[CityLegends] house gates:", err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		local lotId = placed[player]
		if lotId then
			takeDown(recs[lotId])
		end
		placed[player] = nil
		lastClaim[player] = nil
		ctx.spawnAt[player] = nil
	end)
end

return Houses
