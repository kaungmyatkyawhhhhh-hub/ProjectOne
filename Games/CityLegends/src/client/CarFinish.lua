--[[
	Real surfaces on the new imports only (owner, 2026-11-04: "make the car exterior looks better and
	the interior also better", "I meant the new imports only"). Parts carry plain names from
	tools/lambo/finish_car.py. Paint: a glossy MaterialVariant, so the colour stays true and the shine
	comes at the edges (Reflectance washes it with the sky). Everything else already has its own
	SurfaceAppearance in ReplicatedStorage.CarModels (tools/lambo/PbrApply.luau). Lenses: tinted see-through
	covers, so the lamps inside show. The variants are in MaterialService, saved in the place.
]]

local Players = game:GetService("Players")

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
} :: { [string]: boolean }

-- Legends Customs' finishes on these cars
CarFinish.VARIANT = {
	gloss = "CL_PaintGloss",
	matte = "CL_PaintMatte",
	metallic = "CL_PaintMetal",
} :: { [string]: string }

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
	light.Range = 7
	light.Shadows = false
	light.Parent = at
end

function CarFinish.apply(id: string, skin: Instance)
	if not CarFinish.CARS[id] then
		return
	end
	cabinLight(skin)
	for _, d in skin:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		local src = d:GetAttribute("SrcName")
		if type(src) ~= "string" then
			continue
		end
		if src:sub(1, 10) == "Body_Paint" then
			d.Material = Enum.Material.SmoothPlastic
			d.MaterialVariant = CarFinish.VARIANT.gloss
			d.Reflectance = 0
			d:SetAttribute("PbrPaint", true)
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
