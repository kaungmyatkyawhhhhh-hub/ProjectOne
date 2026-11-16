--[[
	YangonShellFacades (2026-11-16, owner: "why are the buildings just blocks"): puts a window-grid MaterialVariant on
	the light 1:1 shells (Workspace.Yangon1to1.Buildings.Shell: the Parts with attribute T), so far views and Edit read
	as buildings. Maps from tools/yangon/city/shell_facades.py (ids in city/shell_facades_ids.json).

	Variants YgnShell<Set><phase> (Set = Walkup / Shop / Villa, phase 0-3), BaseMaterial Plaster (the shells' own),
	StudsPerTile 60 (6 floors of 10 x whole bays), pattern Regular, neutral grey: each shell keeps its own Color.
	A Part's material texture hangs from its top face, so the phase (picture moved down 0 / 2.5 / 5 / 7.5 studs) is
	chosen per box to put a floor line nearest its base + ground floor height (base = box bottom + 1).

	Which set a box takes: city/shell_facades.py map -> build/shell_facades/keys_<k>.txt ('<set> <key> ...', key =
	round(x*10)_round(z*10) of the box middle; villa is the default, 'none' = sheds / halls / markets keep theirs).
	Roofs (no attribute T) are never touched. Undo puts back YangonKitPlace's variant for the shell's wall code (its
	Name): YgnRenderStained for KWG / KWD2 / KWC, else YgnRenderPainted.

	F.variants(ids)            ids = { Walkup = { {color, normal, rough} x4 }, ... } -> creates / updates the 12 variants
	F.apply(pages, folder)     pages = list of key-page strings; runs in chunks (task.wait), sets attribute
	                           workspace.YgnShellFacadesDone = count when done
	F.undo(folder)
]]

local F = {}
local MS = game:GetService("MaterialService")

F.SETS = { walkup = "Walkup", shop = "Shop", villa = "Villa" }
F.GF = { Walkup = 11.7, Shop = 13.0, Villa = 10.3 } -- studs: the archetypes' ground floors (kit_panels.ARCH)
F.FLOOR, F.PHASES, F.TILE = 10.0, 4, 60

function F.variants(ids)
	for set, list in ids do
		for ph, t in list do
			local name = "YgnShell" .. set .. (ph - 1)
			local v = MS:FindFirstChild(name) or Instance.new("MaterialVariant")
			v.Name = name
			v.BaseMaterial = Enum.Material.Plaster
			v.ColorMap = "rbxassetid://" .. t[1]
			v.NormalMap = "rbxassetid://" .. t[2]
			v.RoughnessMap = "rbxassetid://" .. t[3]
			v.StudsPerTile = F.TILE
			v.MaterialPattern = Enum.MaterialPattern.Regular
			v.Parent = MS
		end
	end
end

function F.phase(set: string, h: number): number
	local d = (h - 1 - F.GF[set]) % F.FLOOR
	return math.round(d / (F.FLOOR / F.PHASES)) % F.PHASES
end

function F.apply(pages, folder: Instance)
	local setOf = {}
	for _, page in pages do
		local w = string.split(page, " ")
		local set = w[1]
		for i = 2, #w do
			setOf[w[i]] = set
		end
	end
	workspace:SetAttribute("YgnShellFacadesDone", nil)
	task.spawn(function()
		local n, k = 0, 0
		local counts = {}
		for _, d in folder:GetDescendants() do
			if d.ClassName == "Part" and d:GetAttribute("T") then
				local p = d.Position
				local key = string.format("%d_%d", math.round(p.X * 10), math.round(p.Z * 10))
				local s = setOf[key] or "villa"
				if s ~= "none" then
					local set = F.SETS[s]
					d.Material = Enum.Material.Plaster
					d.MaterialVariant = "YgnShell" .. set .. F.phase(set, d.Size.Y)
					counts[set] = (counts[set] or 0) + 1
					n += 1
				end
				k += 1
				if k % 800 == 0 then
					task.wait()
				end
			end
		end
		workspace:SetAttribute("YgnShellFacadesDone", n)
		workspace:SetAttribute("YgnShellFacadesCounts", game:GetService("HttpService"):JSONEncode(counts))
	end)
end

function F.undo(folder: Instance)
	task.spawn(function()
		local k = 0
		local stained = { KWG = true, KWD2 = true, KWC = true }
		for _, d in folder:GetDescendants() do
			if d.ClassName == "Part" and d:GetAttribute("T") and string.sub(d.MaterialVariant, 1, 8) == "YgnShell" then
				d.MaterialVariant = if stained[d.Name] then "YgnRenderStained" else "YgnRenderPainted"
				k += 1
				if k % 800 == 0 then
					task.wait()
				end
			end
		end
		workspace:SetAttribute("YgnShellFacadesDone", -k)
	end)
end

return F
