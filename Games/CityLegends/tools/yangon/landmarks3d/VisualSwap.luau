--!nocheck
-- VisualSwap (2026-11-16, ornament kit pass): swaps a placed landmark's Visual meshes for a re-exported upload with the
-- SAME part names (Kaba Aye: Blender object names), keeping the Collision folder and every look.
--   * the new upload is lined up on the old one by a reference part whose mesh did not change (exact box match)
--   * each new part copies its look from the old part of the same name, else from an old part with the same
--     material suffix (the text after the last "_Ygn" / "_" in the name)
--   * CollisionFidelity Box (after parenting), CanCollide / CanQuery / CanTouch off, anchored
-- Paste as the body of an execute_luau call with ASSET, LANDMARK, REF set; runs in task.spawn, status in
-- workspace attribute "VisualSwap_<LANDMARK>".
local ASSET, LANDMARK, REF = 0, "", ""
local IS = game:GetService("InsertService")
local SS = game:GetService("ServerStorage")
local key = "VisualSwap_" .. LANDMARK
workspace:SetAttribute(key, "running")
task.spawn(function()
	local ok, err = pcall(function()
		local lm = workspace.Yangon1to1.Landmarks[LANDMARK]
		local oldVis = lm.Visual
		local hold = Instance.new("Folder")
		hold.Name = "_Swap_" .. LANDMARK
		hold.Parent = SS
		local m = IS:LoadAsset(ASSET)
		m.Parent = hold
		local new, old = {}, {}
		for _, d in m:GetDescendants() do
			if d:IsA("MeshPart") then
				new[d.Name] = d
			end
		end
		local suffix = {}
		for _, d in oldVis:GetDescendants() do
			if d:IsA("MeshPart") then
				old[d.Name] = d
				local sfx = string.match(d.Name, "_(Ygn[%w_]+)$") or string.match(d.Name, "_([%w]+)$")
				if sfx and not suffix[sfx] then
					suffix[sfx] = d
				end
			end
		end
		local rn, ro = new[REF], old[REF]
		assert(rn and ro, "reference part missing: " .. REF)
		assert((rn.Size - ro.Size).Magnitude < 0.05, "reference size differs")
		local delta = ro.CFrame * rn.CFrame:Inverse()
		local vis = Instance.new("Folder")
		vis.Name = "Visual"
		local n, copied, bySfx = 0, 0, 0
		for name, p in new do
			p.CFrame = delta * p.CFrame
			local src = old[name]
			if src then
				copied += 1
			else
				local sfx = string.match(name, "_(Ygn[%w_]+)$") or string.match(name, "_([%w]+)$")
				src = sfx and suffix[sfx]
				if src then
					bySfx += 1
				end
			end
			if src then
				p.Material = src.Material
				p.MaterialVariant = src.MaterialVariant
				p.Color = src.Color
				p.Reflectance = src.Reflectance
				p.Transparency = src.Transparency
				p.CastShadow = src.CastShadow
				pcall(function()
					p.DoubleSided = src.DoubleSided
				end)
			end
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Parent = vis
			n += 1
		end
		oldVis.Name = "Visual_old"
		vis.Parent = lm
		oldVis:Destroy()
		hold:Destroy()
		workspace:SetAttribute(key, string.format("placed %d (looks by name %d, by material %d), fidelity...", n, copied, bySfx))
		local k = 0
		for _, p in vis:GetChildren() do
			p.CollisionFidelity = Enum.CollisionFidelity.Box
			k += 1
			if k % 10 == 0 then
				task.wait()
			end
		end
		lm:SetAttribute("AssetId", ASSET)
		workspace:SetAttribute(key, string.format("done %d parts (looks by name %d, by material %d)", n, copied, bySfx))
	end)
	if not ok then
		workspace:SetAttribute(key, "ERR " .. tostring(err))
	end
end)
return "started"
