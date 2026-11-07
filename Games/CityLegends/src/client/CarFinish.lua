--[[
	Real surfaces on the new imports only (owner, 2026-11-04: "make the car exterior looks better and
	the interior also better", "I meant the new imports only"). Parts carry plain names from
	tools/lambo/finish_car.py. Paint: a glossy MaterialVariant, so the colour stays true and the shine
	comes at the edges (Reflectance washes it with the sky). Everything else already has its own
	SurfaceAppearance in ReplicatedStorage.CarModels (tools/lambo/PbrApply.luau). Lenses: tinted see-through
	covers, so the lamps inside show. The variants are in MaterialService, saved in the place.
]]

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local CarFinish = {}

CarFinish.CARS = {
	lambrini_lp700 = true,
	lambrini_lp750 = true,
	lambrini_lp570 = true,
	lambrini_lp560 = true,
	lambrini_huracan = true,
	lambrini_performante = true,
	lambrini_sto = true,
	lambrini_sterrato = true,
	lambrini_revuelto = true,
	lambrini_lp640 = true,
	lambrini_lp670 = true,
	lambrini_urusp = true,
	ferrara_california = true,
	ferrara_458spider = true,
	ferrara_458speciale = true,
	dearb_focus_rs = true,
	lexis_lfa = true,
	lexis_lfa_circuit = true,
	lambrini_countach = true,
	bentz_s680 = true,
	bentz_gls = true,
	mclaran_12c = true,
	bentz_sls = true,
	ferrara_599 = true,
	bentz_sl65bs = true,
} :: { [string]: boolean }

-- Legends Customs' finishes on these cars
CarFinish.VARIANT = {
	gloss = "CL_PaintGloss",
	matte = "CL_PaintMatte",
	metallic = "CL_PaintMetal",
	satin = "CL_PaintSatin",
} :: { [string]: string }

-- (2026-11-06, the Ghost Driver look: new models only, never the older ones) the new models that came
-- before the list above: they get the contact shadow and the carbon too, and the two SVJs the paint
CarFinish.NEW = table.clone(CarFinish.CARS)
for _, id in { "lambrini_svj", "lambrini_svj63", "bugotti_veyron", "bugotti_veyron_sport", "bugotti_veyron_top", "bugotti_chiron", "bugotti_chiron_pursport", "bugotti_chiron_supersport" } do
	CarFinish.NEW[id] = true
end
local PLAIN_PAINT = { Body_A_CAR_PAINT = true, Body_MAIN_PAINT = true } -- (the SVJs' paint: a plain colour, no picture)
local CARBON_TINT = Color3.fromRGB(150, 150, 156) -- darker than its picture, less shine than the paint

-- can Customs give this car a real satin?
function CarFinish.hasPaint(id: string): boolean
	return CarFinish.CARS[id] == true or id == "lambrini_svj" or id == "lambrini_svj63"
end

local GLASS = "CL_GlassGloss"
local LENS = {
	Red = { color = Color3.fromRGB(150, 12, 14), transparency = 0.32 },
	Orange = { color = Color3.fromRGB(226, 110, 18), transparency = 0.4 },
	Clear = { color = Color3.fromRGB(14, 16, 20), transparency = 0.72 }, -- (a smoked cover: the models' own is dark glass)
} :: { [string]: { color: Color3, transparency: number } }

local function bare(p: BasePart)
	local sa = p:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa:Destroy()
	end
	if p:IsA("MeshPart") then
		pcall(function()
			(p :: MeshPart).TextureID = ""
		end)
	end
end

-- the game's shade is blue and a cabin is all shade: a soft warm light inside your own car, so black
-- leather reads black and not navy (only yours: one light, and only where you sit)
local function cabinLight(skin: Instance)
	local model = skin.Parent
	if not model or not model:IsA("Model") or model.Name ~= Players.LocalPlayer.Name then
		return
	end
	local root = model.PrimaryPart
	local eye = model:GetAttribute("Eye")
	if not root or typeof(eye) ~= "Vector3" then
		return
	end
	local at = Instance.new("Attachment")
	at.Name = "CabinLight"
	at.Position = Vector3.new(0, eye.Y + 0.1, eye.Z + 0.2) -- (between the seats, under the roof: nearer the dash it burns a patch on it)
	at.Parent = root
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 246, 236)
	light.Brightness = 0.55
	light.Range = 3.2 -- (2026-11-06: 7 reached the road under the car and lit a patch there)
	light.Shadows = false
	light.Parent = at
end

-- a soft dark shadow right under the car, on top of the real one, so it never looks like it floats
local function contactShadow(skin: Instance)
	local model = skin.Parent
	local root = if model and model:IsA("Model") then model.PrimaryPart else nil
	if not (model and root) or model:FindFirstChild("ContactShadow") then
		return
	end
	local box, size = (model :: Model):GetBoundingBox()
	local bottom = root.CFrame:ToObjectSpace(box).Position.Y - size.Y / 2 + 0.12
	local p = Instance.new("Part")
	p.Name = "ContactShadow"
	p.Size = Vector3.new(size.X * 1.3, 0.05, size.Z * 1.2)
	p.CFrame = root.CFrame * CFrame.new(0, bottom, 0)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Anchored = root.Anchored
	local d = Instance.new("Decal")
	d.Face = Enum.NormalId.Top
	d.Texture = Config.Look.ShadowImage
	d.Parent = p
	if not root.Anchored then
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = model
end

local function gloss(d: BasePart)
	d.Material = Enum.Material.SmoothPlastic
	d.MaterialVariant = CarFinish.VARIANT.gloss
	d.Reflectance = 0
	d:SetAttribute("PbrPaint", true)
end

function CarFinish.apply(id: string, skin: Instance)
	if not CarFinish.NEW[id] then
		return
	end
	contactShadow(skin)
	local full = CarFinish.CARS[id]
	if full then
		cabinLight(skin)
	end
	for _, d in skin:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		local src = d:GetAttribute("SrcName")
		if type(src) ~= "string" then
			continue
		end
		local low = src:lower()
		if low:find("carbon", 1, true) and not low:find("cabin", 1, true) and d:IsA("MeshPart") and d.TextureID ~= "" then
			d.Color = CARBON_TINT
			d.Reflectance = 0
		end
		if PLAIN_PAINT[src] then
			gloss(d)
		end
		if not full then
			continue
		end
		if src:sub(1, 10) == "Body_Paint" then
			gloss(d)
		elseif src:sub(1, 16) == "SeeThrough_Lens_" then
			local lens = LENS[src:sub(17):match("^%a+") or ""]
			if lens then
				bare(d)
				d.Color = lens.color
				d.Material = Enum.Material.SmoothPlastic
				d.MaterialVariant = GLASS
				d.Transparency = lens.transparency
				d.Reflectance = 0
				d.CastShadow = false
			end
		elseif src:sub(1, 17) == "SeeThrough_Window" then
			d.MaterialVariant = GLASS
		end
	end
end

return CarFinish
