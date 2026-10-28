-- CosmeticsService (M5, Customization note): the rest of the Locker - KITS (top + bottom), HEADWEAR,
-- BIB (number + colour), NAME STYLE and shoe skins. Cosmetic only. Prices = minutes of coins at your
-- league. Worn items are welded onto the character on the server (everyone sees them); each is one
-- mesh from ServerStorage.Meshes ("Kit_*" / "Head_*") or a simple part until that's imported.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage").Shared
local Cosmetics = require(Shared.Config.Cosmetics)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local LockerService = require(script.Parent.LockerService)
local SocialService = require(script.Parent.SocialService)

local CosmeticsService = {}

-- Worn items live in workspace.Runtime.Cosmetics.<UserId>, welded to the body - NOT inside the
-- character: Roblox hides parts inside a character that sit under layered clothing (a jacket on the
-- avatar made our tee vanish). Cleaned up when the character goes and when the player leaves.
local function folderFor(player, create)
	local runtime = workspace:FindFirstChild("Runtime")
	local root = runtime and runtime:FindFirstChild("Cosmetics")
	if not root and create and runtime then
		root = Instance.new("Folder")
		root.Name = "Cosmetics"
		root.Parent = runtime
	end
	local f = root and root:FindFirstChild(tostring(player.UserId))
	if not f and create and root then
		f = Instance.new("Folder")
		f.Name = tostring(player.UserId)
		f:SetAttribute("UserId", player.UserId)
		f.Parent = root
	end
	return f
end

local byId = { Kit = {}, Head = {}, Name = {}, Bib = {} }
for _, k in Cosmetics.Kits do
	byId.Kit[k.Id] = k
end
for _, h in Cosmetics.Headwear do
	byId.Head[h.Id] = h
end
for _, n in Cosmetics.NameStyles do
	byId.Name[n.Id] = n
end
for _, b in Cosmetics.Bib.Colors do
	byId.Bib[b.Id] = b
end

-- how each mesh sits on the body: part it rides on, size as a multiple of that part, offset (x part size)
local FIT = { -- sizes match the Blender kit (blender/locker_kit.py) proportions
	Kit_Singlet = { On = "UpperTorso", Size = Vector3.new(1.085, 1.01, 1.255), Offset = Vector3.new(0, 0, 0) },
	Kit_Tee = { On = "UpperTorso", Size = Vector3.new(1.1, 1.05, 1.305), Offset = Vector3.new(0, 0.01, 0) },
	Kit_ZipTop = { On = "UpperTorso", Size = Vector3.new(1.11, 1.18, 1.37), Offset = Vector3.new(0, 0.07, 0) },
	Kit_Shorts = { On = "LowerTorso", Size = Vector3.new(1.135, 3.0, 1.385), Offset = Vector3.new(0, -0.85, 0) },
	Kit_SplitShorts = { On = "LowerTorso", Size = Vector3.new(1.135, 2.4, 1.385), Offset = Vector3.new(0, -0.6, 0) },
	Kit_Tights = { On = "LowerTorso", Size = Vector3.new(1.12, 3.6, 1.325), Offset = Vector3.new(0, -1.15, 0) },
	Head_Headband = { On = "Head", Size = Vector3.new(1.1, 0.24, 1.12), Offset = Vector3.new(0, 0.22, 0) },
	Head_Cap = { On = "Head", Size = Vector3.new(1.1, 0.62, 1.48), Offset = Vector3.new(0, 0.48, -0.22) },
	Head_Visor = { On = "Head", Size = Vector3.new(1.08, 0.21, 1.41), Offset = Vector3.new(0, 0.3, -0.22) },
	Head_Shades = { On = "Head", Size = Vector3.new(1.04, 0.24, 0.62), Offset = Vector3.new(0, 0.08, -0.3) },
	Head_BucketHat = { On = "Head", Size = Vector3.new(1.44, 0.49, 1.44), Offset = Vector3.new(0, 0.55, 0) },
	Head_Beanie = { On = "Head", Size = Vector3.new(1.12, 0.89, 1.12), Offset = Vector3.new(0, 0.48, 0) },
}

local function priceOf(item, data)
	return Formulas.minutesOfCoins(item.Minutes or 0, data.League)
end

local function ownsItem(data, kind, item)
	if item.Pass then
		return data.Passes[item.Pass] == true
	end
	if kind == "Kit" then
		return data.OwnedKits[item.Id] == true
	elseif kind == "Head" then
		return data.OwnedHead[item.Id] == true
	elseif kind == "Name" then
		return data.OwnedNameStyles[item.Id] == true
	end
	return false
end
CosmeticsService.ownsItem = ownsItem

----------------------------------------------------------------------------
-- dressing
----------------------------------------------------------------------------
local function template(meshName)
	local lib = ServerStorage:FindFirstChild("Meshes")
	local m = lib and lib:FindFirstChild(meshName)
	return m and (if m:IsA("MeshPart") then m else m:FindFirstChildWhichIsA("MeshPart"))
end

local function weldTo(base, p, cf)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = base.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
end

-- a stand-in made of parts, so the item shows before its mesh is imported
local function standIn(meshName, size, color)
	local m = Instance.new("Model")
	local function part(name, sz, offset, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = sz
		if shape then
			p.Shape = shape
		end
		p:SetAttribute("Offset", offset)
		p.Parent = m
		return p
	end
	if meshName:find("^Kit_") then
		part("Body", size, Vector3.zero)
	elseif meshName == "Head_Headband" or meshName == "Head_Beanie" then
		part("Band", Vector3.new(size.Y, size.X, size.Z), Vector3.zero, Enum.PartType.Cylinder)
	elseif meshName == "Head_Cap" or meshName == "Head_Visor" then
		part("Crown", Vector3.new(size.X, size.Y * (if meshName == "Head_Cap" then 0.8 else 0.4), size.X * 0.92), Vector3.new(0, 0, size.Z * 0.12))
		part("Brim", Vector3.new(size.X * 0.8, 0.08, size.Z * 0.42), Vector3.new(0, -size.Y * 0.3, -size.Z * 0.36))
	elseif meshName == "Head_Shades" then
		part("Lens", size, Vector3.zero)
	elseif meshName == "Head_BucketHat" then
		part("Top", Vector3.new(size.Y * 0.8, size.X * 0.72, size.Z * 0.72), Vector3.new(0, size.Y * 0.15, 0), Enum.PartType.Cylinder)
		part("Brim", Vector3.new(0.08, size.X, size.Z), Vector3.new(0, -size.Y * 0.3, 0), Enum.PartType.Cylinder)
	end
	for _, p in m:GetChildren() do
		if p.Shape == Enum.PartType.Cylinder then
			p:SetAttribute("Upright", true)
		end
	end
	return m
end

local function wear(char, meshName, color, tag, into)
	local fit = FIT[meshName]
	local base = fit and char:FindFirstChild(fit.On)
	if not base then
		return
	end
	local holder = Instance.new("Model")
	holder.Name = tag
	holder:SetAttribute("SpeedArcCosmetic", true)
	local size = base.Size * fit.Size
	local offset = CFrame.new(base.Size * fit.Offset)
	local t = template(meshName)
	if t then
		local m = t:Clone()
		m.Size = size
		m.Color = color
		m.TextureID = ""
		weldTo(base, m, offset)
		m.Parent = holder
	else
		for _, p in standIn(meshName, size, color):GetChildren() do
			local o = p:GetAttribute("Offset") or Vector3.zero
			local rot = if p:GetAttribute("Upright") then CFrame.Angles(0, 0, math.pi / 2) else CFrame.new()
			weldTo(base, p, offset * CFrame.new(o) * rot)
			p.Parent = holder
		end
	end
	holder.Parent = into
end

----------------------------------------------------------------------------
-- classic clothing kits: the character's own Shirt / Pants is swapped for the kit's template (the
-- original id is kept on the instance and put back when the kit comes off). Layered clothing that
-- would cover the kit (a jacket over the top, layered pants over the bottom) is set aside while the
-- kit is worn, so you can see what you bought; it's back on the next respawn or when you take it off.
----------------------------------------------------------------------------
local LAYER_TYPES = {
	Top = { [Enum.AccessoryType.Shirt] = true, [Enum.AccessoryType.TShirt] = true, [Enum.AccessoryType.Jacket] = true, [Enum.AccessoryType.Sweater] = true },
	Bottom = { [Enum.AccessoryType.Pants] = true, [Enum.AccessoryType.Shorts] = true, [Enum.AccessoryType.DressSkirt] = true },
}
local setAside = {} -- [player] = Folder in ServerStorage

local function classic(player, char, slot, templateId)
	local className = if slot == "Top" then "Shirt" else "Pants"
	local prop = if slot == "Top" then "ShirtTemplate" else "PantsTemplate"
	local inst = char:FindFirstChildOfClass(className)
	if templateId then
		if not inst then
			inst = Instance.new(className)
			inst:SetAttribute("SpeedArcMade", true)
			inst.Parent = char
		end
		if inst:GetAttribute("Original") == nil then
			inst:SetAttribute("Original", inst[prop])
		end
		inst[prop] = "rbxassetid://" .. templateId
	elseif inst and inst:GetAttribute("Original") ~= nil then
		if inst:GetAttribute("SpeedArcMade") then
			inst:Destroy()
		else
			inst[prop] = inst:GetAttribute("Original")
			inst:SetAttribute("Original", nil)
		end
	end
	-- layered clothing on that part of the body
	local folder = setAside[player]
	if templateId then
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "SetAside_" .. player.UserId
			folder.Parent = ServerStorage
			setAside[player] = folder
		end
		for _, a in char:GetChildren() do
			if a:IsA("Accessory") and a:FindFirstChildWhichIsA("WrapLayer", true) and LAYER_TYPES[slot][a.AccessoryType] then
				a:SetAttribute("SetAsideSlot", slot)
				a.Parent = folder
			end
		end
	elseif folder then
		for _, a in folder:GetChildren() do
			if a:GetAttribute("SetAsideSlot") == slot then
				a.Parent = char
			end
		end
	end
end

local function bib(char, data, into)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso or not data.Bib.On or data.Bib.Number <= 0 then
		return
	end
	local c = byId.Bib[data.Bib.Color] or Cosmetics.Bib.Colors[1]
	local holder = Instance.new("Model")
	holder.Name = "Bib"
	holder:SetAttribute("SpeedArcCosmetic", true)
	local p = Instance.new("Part")
	p.Name = "BibCard"
	p.Material = Enum.Material.SmoothPlastic
	p.Color = Color3.fromHex("#F4F6FA")
	p.Size = Vector3.new(torso.Size.X * 0.5, torso.Size.Y * 0.42, 0.06)
	-- in front of whatever top you wear
	local depth = torso.Size.Z * (if data.Kit.Top ~= "" then 0.66 else 0.53)
	weldTo(torso, p, CFrame.new(0, -torso.Size.Y * 0.05, -depth))
	p.Parent = holder
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.MaxDistance = 60
	gui.Parent = p
	local band = Instance.new("Frame")
	band.BackgroundColor3 = Color3.fromHex(c.Color)
	band.BorderSizePixel = 0
	band.Size = UDim2.fromScale(1, 0.24)
	band.Parent = gui
	local n = Instance.new("TextLabel")
	n.BackgroundTransparency = 1
	n.Position = UDim2.fromScale(0, 0.24)
	n.Size = UDim2.fromScale(1, 0.76)
	n.TextScaled = true
	n.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
	n.TextColor3 = Color3.fromHex("#0B0D12")
	n.Text = tostring(data.Bib.Number)
	n.Parent = gui
	holder.Parent = into
end

function CosmeticsService.dress(player)
	local char = player.Character
	local data = PlayerData.get(player)
	if not char or not data then
		return
	end
	for _, d in char:GetChildren() do
		if d:GetAttribute("SpeedArcCosmetic") then
			d:Destroy() -- an older build put them inside the character
		end
	end
	local into = folderFor(player, true)
	if not into then
		return
	end
	into:ClearAllChildren()
	for _, slot in { "Top", "Bottom" } do
		local k = byId.Kit[data.Kit[slot] or ""]
		local worn = k and ownsItem(data, "Kit", k)
		local template = worn and (k.Template or 0) > 0 and k.Template or nil
		classic(player, char, slot, template)
		if worn and not template then
			wear(char, k.Mesh, Color3.fromHex(k.Color), "Kit_" .. slot, into)
		end
	end
	local h = byId.Head[data.Head]
	if h and ownsItem(data, "Head", h) then
		wear(char, h.Mesh, Color3.fromHex(h.Color), "Headwear", into)
	end
	bib(char, data, into)
	-- the name style is drawn in the tag over the head
	player:SetAttribute("NameStyle", data.NameStyle)
	SocialService.refreshTag(player)
end

----------------------------------------------------------------------------
-- actions
----------------------------------------------------------------------------
local function buy(player, kind, id)
	local data = PlayerData.get(player)
	local item = data and byId[kind] and byId[kind][id]
	if not item or kind == "Bib" then
		return false, "missing"
	end
	if ownsItem(data, kind, item) then
		return false, "owned"
	end
	if item.Pass then
		return false, "pass"
	end
	local price = priceOf(item, data)
	if data.Coins < price then
		return false, "coins"
	end
	PlayerData.set(player, "Coins", data.Coins - price)
	if kind == "Kit" then
		data.OwnedKits[id] = true
		data.Kit[item.Slot] = id
	elseif kind == "Head" then
		data.OwnedHead[id] = true
		data.Head = id
	elseif kind == "Name" then
		data.OwnedNameStyles[id] = true
		data.NameStyle = id
	end
	CosmeticsService.dress(player)
	LockerService.dressShoes(player) -- a kit bottom can change which feet show
	LockerService.push(player)
	return true
end

-- equip (id) or take off (id = "" / same id again)
local function equip(player, kind, id)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	if kind == "Kit" then
		local k = byId.Kit[id]
		if not k or not ownsItem(data, kind, k) then
			return false, "notowned"
		end
		data.Kit[k.Slot] = if data.Kit[k.Slot] == id then "" else id
	elseif kind == "Head" then
		local h = byId.Head[id]
		if id ~= "" and (not h or not ownsItem(data, kind, h)) then
			return false, "notowned"
		end
		data.Head = if data.Head == id then "" else id
	elseif kind == "Name" then
		local n = byId.Name[id]
		if id ~= "" and (not n or not ownsItem(data, kind, n)) then
			return false, "notowned"
		end
		data.NameStyle = if data.NameStyle == id then "" else id
	elseif kind == "Skin" then
		local skin = Cosmetics.ShoeSkins[id]
		if not skin or not data.ShoeSkins[id] then
			return false, "notowned"
		end
		data.ShoeSkin[skin.Shoe] = if data.ShoeSkin[skin.Shoe] == id then nil else id
		LockerService.dressShoes(player)
	else
		return false
	end
	CosmeticsService.dress(player)
	LockerService.dressShoes(player)
	LockerService.push(player)
	return true
end

local function setBib(player, number, colorId, on)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	number = math.floor(tonumber(number) or 0)
	if number < 1 or number > Cosmetics.Bib.MaxNumber then
		return false, "number"
	end
	local c = byId.Bib[colorId]
	if not c or (data.BestLeague or 1) < c.League then
		return false, "locked"
	end
	data.Bib = { Number = number, Color = colorId, On = on ~= false }
	CosmeticsService.dress(player)
	LockerService.push(player)
	return true
end

function CosmeticsService.start()
	Net.on("BuyCosmetic", buy)
	Net.on("EquipCosmetic", equip)
	Net.on("SetBib", setBib)
	local function onCharacter(player, char)
		char:WaitForChild("UpperTorso", 10)
		char:WaitForChild("Head", 10)
		task.wait(0.5) -- after the shoes
		if player.Parent and PlayerData.get(player) then
			CosmeticsService.dress(player)
		end
	end
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
		player.CharacterRemoving:Connect(function()
			local f = folderFor(player, false)
			if f then
				f:ClearAllChildren()
			end
			if setAside[player] then
				setAside[player]:ClearAllChildren() -- the new character gets its own clothes again
			end
		end)
		-- the avatar's clothes can arrive after CharacterAdded: dress again once they're in
		player.CharacterAppearanceLoaded:Connect(function()
			if player.Parent and PlayerData.get(player) then
				CosmeticsService.dress(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		local f = folderFor(player, false)
		if f then
			f:Destroy()
		end
		if setAside[player] then
			setAside[player]:Destroy()
			setAside[player] = nil
		end
	end)
	PlayerData.Loaded.Event:Connect(function(player)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end)
end

return CosmeticsService
