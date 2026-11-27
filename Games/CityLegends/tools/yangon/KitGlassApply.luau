--[[
	KitGlassApply.luau (Studio, Edit; 2026-11-27, building fronts: real glass): puts the kit_glass.py meshes into
	ReplicatedStorage.YgnKit.Templates. Each listed asset (Open Cloud Model from imports/sync/kit_glass/kit_glass_<n>.glb)
	holds KGR_<pid>_<box> (the panel's metal / signs / shutters without the glass) and KGG_<pid>_<box> (the glass).
	The old KGR_<pid> template is replaced (same look, new mesh and box); KGG_<pid> is added with YangonKitPlace's glass
	look. YangonKitData clones every piece of a pid, so the client needs no change.
	(2026-11-27, buildings less blocky) KWX_<pid>_<box> meshes (kit_walls.py: the wall class rebuilt with the roof slab
	lip) replace the KWX_<pid> templates the same way (look copied from the old template; the client re-looks KWX).

	local A = require(ServerStorage.ClaudeTools.KitGlassApply:Clone())
	A.apply({ 117482044068796, ... })   -> "kgr replaced N, kgg added M, skipped ..."
]]
local InsertService = game:GetService("InsertService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local A = {}

function A.apply(ids: { number }): string
	local P = require(SS.ClaudeTools.YangonKitPlace:Clone())
	local store = RS.YgnKit.Templates
	local kgr, kgg, kwx, skipped = 0, 0, 0, {}
	for _, id in ids do
		local model = InsertService:LoadAsset(id)
		for _, d in model:GetDescendants() do
			if d:IsA("MeshPart") then
				local kind, pid, c, size = P.parse(d.Name)
				if not kind and d.Parent then
					kind, pid, c, size = P.parse((string.gsub(d.Parent.Name, "_Node$", "")))
				end
				local name = kind and (kind .. "_" .. pid)
				local old = name and store:FindFirstChild(name)
				if (kind == "KGR" or kind == "KWX") and old then
					local q = d:Clone()
					for _, ch in q:GetChildren() do
						ch:Destroy()
					end
					q.Name = name
					q.Size = size
					q.TextureID = ""
					q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.Massless = true, false, false, false, true
					q.CastShadow = old.CastShadow
					q.Material, q.MaterialVariant, q.Color = old.Material, old.MaterialVariant, old.Color
					pcall(function()
						(q :: any).RenderFidelity = Enum.RenderFidelity.Automatic
						;(q :: any).DoubleSided = false
					end)
					q:SetAttribute("C", c)
					q:SetAttribute("S", size)
					old:Destroy()
					q.Parent = store
					pcall(function()
						q.CollisionFidelity = Enum.CollisionFidelity.Box
					end)
					if kind == "KWX" then
						kwx += 1
					else
						kgr += 1
					end
				elseif kind == "KGG" and not old then
					local q = d:Clone()
					for _, ch in q:GetChildren() do
						ch:Destroy()
					end
					q.Name = name
					q.Size = size
					q.TextureID = ""
					q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.Massless = true, false, false, false, true
					q.CastShadow = false
					q.Material, q.MaterialVariant = P.GLASS.material, ""
					q.Color, q.Reflectance = P.GLASS.color, P.GLASS.reflectance
					pcall(function()
						(q :: any).RenderFidelity = Enum.RenderFidelity.Automatic
						;(q :: any).DoubleSided = false
					end)
					q:SetAttribute("C", c)
					q:SetAttribute("S", size)
					q.Parent = store
					pcall(function()
						q.CollisionFidelity = Enum.CollisionFidelity.Box
					end)
					kgg += 1
				else
					table.insert(skipped, d.Name)
				end
			end
		end
		model:Destroy()
		task.wait()
	end
	return string.format("kgr replaced %d, kgg added %d, kwx replaced %d, skipped %d %s", kgr, kgg, kwx, #skipped, table.concat(skipped, " ", 1, math.min(#skipped, 10)))
end

-- (2026-11-27 review) newer / villa-type panels keep the clean painted render: attribute MV on their KWX templates
-- (pids from city/kit_walls_clean.txt, written by kit_walls.py); YangonKitData uses MV over the code's variant
function A.clean(pids: { string }, variant: string?): string
	local store = RS.YgnKit.Templates
	local n, miss = 0, 0
	for _, pid in pids do
		local q = store:FindFirstChild("KWX_" .. pid)
		if q then
			q:SetAttribute("MV", variant or "YgnRenderPainted")
			n += 1
		else
			miss += 1
		end
	end
	return string.format("MV set on %d KWX templates, %d missing", n, miss)
end

return A
