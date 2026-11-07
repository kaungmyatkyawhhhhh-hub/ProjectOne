--[[
	Pictures Roblox refuses in this place ("not approved"): the parts then show plain grey 163,162,165. Each part gets
	the plain colour of its picture (read from the 2026-10-23 packs where the car is in one). The old id stays on the
	part as BlockedTexture. Paste into execute_luau on the edit side; run once.
]]
local CM = game:GetService("ReplicatedStorage"):WaitForChild("CarModels")
local SS = game:GetService("ServerStorage")
local DARK = "rbxassetid://88253845057264" -- a plain dark picture of ours

-- { car, part name, r, g, b, material }
local PLAIN = {
	{ "bentz_g63", "Body_M_Plas_2", 30, 30, 32 },
	{ "bentz_g63", "Body_calip_C2", 40, 40, 42 },
	{ "bentz_g63", "Body_Mphong14SG1", 26, 26, 28 },
	{ "rolls_wraith", "Body_c78_Wraith_shared_3__chr", 200, 0, 0 },
	{ "bnw_m4_f82", "Body_ARm4_alcnt", 44, 44, 46 },
	{ "bnw_m4_f82", "Body_ARm4_common_engine", 58, 58, 60 },
	{ "bentz_s65_w221", "Body_sw221_interior", 50, 46, 43 },
	{ "bentz_sls", "SteeringWheel_t17", 52, 49, 48 },
	{ "bentz_sls", "Body_SLSinterior_Transp", 52, 49, 48 },
	{ "bentz_190e", "Body_Car_Plastic_Detail", 52, 52, 54 },
	{ "bentz_190e", "Body_rubber_trim_001", 40, 40, 42 },
	{ "lambrini_lp640", "Body_Exhaust", 120, 120, 124, "Metal" },
	{ "astin_dbx", "Body_Meshesgps1Mtl", 60, 60, 62 },
	{ "ferrara_599", "Body_Fphong13SG1", 30, 30, 32 },
	{ "ferrara_458s", "Body_Caliper_Color", 46, 46, 48 },
	{ "toyoka_lc300", "Body_MetalBlack", 56, 56, 58, "Metal" },
	{ "xiaomo_su7", "Body_Brilliant_Silver", 177, 177, 180, "Metal" },
	{ "maseroti_levante", "Body_mphong8", 58, 58, 60 },
	{ "mclaran_12c", "Body_Mphong10SG1", 20, 20, 22 },
}
-- keep the surface's other maps, only the colour map changes
local DARKEN = { { "ferrara_california", "Body_CabinTile" }, { "ferrara_458spider", "Body_Trim5" } }
-- pieces whose mesh is refused: nothing shows, only an error
local MESHES = { nisun_350z = "1363117601", audy_r8 = "1399745209", porsha_panamera = "1428598723", bnw_m3_e92 = "1464259109" }

local log = {}
for _, e in PLAIN do
	local p = CM[e[1]]:FindFirstChild(e[2], true)
	if p and p:IsA("MeshPart") then
		p:SetAttribute("BlockedTexture", p.TextureID)
		p.TextureID = ""
		for _, d in p:GetChildren() do
			if d:IsA("SurfaceAppearance") then
				p:SetAttribute("BlockedTexture", d.ColorMap)
				d:Destroy()
			end
		end
		p.Color = Color3.fromRGB(e[3], e[4], e[5])
		p.Material = if e[6] then Enum.Material[e[6]] else Enum.Material.SmoothPlastic
	else
		table.insert(log, "missing " .. e[1] .. "/" .. e[2])
	end
end
for _, e in DARKEN do
	local p = CM[e[1]]:FindFirstChild(e[2], true)
	local sa = p and p:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		p:SetAttribute("BlockedTexture", sa.ColorMap)
		sa.ColorMap = DARK
	end
end
-- the STO's trim picture
for _, d in CM.lambrini_sto:GetDescendants() do
	if d:IsA("MeshPart") and d.TextureID:find("84462166852270", 1, true) then
		d:SetAttribute("BlockedTexture", d.TextureID)
		d.TextureID = ""
		d.Color = Color3.fromRGB(24, 24, 26)
	elseif d:IsA("SurfaceAppearance") and d.ColorMap:find("84462166852270", 1, true) then
		d.ColorMap = DARK
	end
end
-- the M6's old Toolbox pieces
for _, d in CM.bnw_m6_v10:GetDescendants() do
	if d:IsA("MeshPart") and (d.TextureID:find("13529595251", 1, true) or d.TextureID:find("13532874927", 1, true)) then
		d:SetAttribute("BlockedTexture", d.TextureID)
		d.TextureID = ""
		d.Color = Color3.fromRGB(28, 28, 30)
	end
end
-- the plate with an empty picture id
for _, d in CM.toyoka_lc200:GetDescendants() do
	if d:IsA("MeshPart") and d.TextureID == "rbxassetid://0" then
		d.TextureID = ""
	end
end
local back = SS:FindFirstChild("OldCarModels")
for id, mesh in MESHES do
	for _, d in CM[id]:GetDescendants() do
		if d:IsA("MeshPart") and d.MeshId:find(mesh, 1, true) then
			d.Name = id .. "_" .. d.Name
			d.Parent = back
			table.insert(log, "moved " .. d.Name)
		end
	end
end
return table.concat(log, " | ")
