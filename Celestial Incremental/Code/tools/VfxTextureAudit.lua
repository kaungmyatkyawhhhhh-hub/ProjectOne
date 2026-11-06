--[[ VfxTextureAudit (P&L Studios, 7 Nov: "black boxes again")
Read-only. A ModuleScript in ReplicatedStorage.Tools (the client makes most emitters, so it must run there too):
  local report = require(game.ReplicatedStorage.Tools.VfxTextureAudit)()            -- the whole game
  local report = require(game.ReplicatedStorage.Tools.VfxTextureAudit)(workspace)   -- one root
It prints the report and returns it as text. Changes nothing.

Every ParticleEmitter, Beam and Trail must use an APPROVED _alpha texture (VfxTextures.alpha: transparent background,
processed and noise-floored). It FAILS on:
  ADD      an _add texture (black background): with LightEmission < 1 the black square shows on light floors.
           Fix: use VfxTextures.alpha.<same name> (every _add file has its _alpha twin).
  UNKNOWN  a texture that isn't in VfxTextures at all (an old or community upload). Fix: process it into Assets\vfx\ as
           an _alpha file, add it to VfxTextures, or use one that's there.
No texture ("") is fine: a Beam / Trail is then a plain colour, an emitter Roblox's default soft dot.
]]

return function(root: Instance?)
	local VT = require(game:GetService("ReplicatedStorage"):WaitForChild("Galaxy"):WaitForChild("VfxTextures"))
	local alphaName, addName = {}, {}
	for k, v in pairs(VT.alpha) do alphaName[v] = k end
	for k, v in pairs(VT.add) do addName[v] = k end
	-- (an _add file whose _alpha upload is broken (VfxTextures.brokenAlpha) is allowed ONLY at LightEmission 1)
	local allowedAdd = 0
	local fails, ok = {}, 0
	local counts = {}
	for _, d in ipairs((root or game):GetDescendants()) do
		local isFx = false
		pcall(function() isFx = d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") end)
		if not isFx then continue end
		local tex = d.Texture
		if tex == "" or alphaName[tex] then
			ok += 1
		elseif addName[tex] and VT.brokenAlpha and VT.brokenAlpha[addName[tex]] and d.LightEmission >= 1 then
			ok += 1
			allowedAdd += 1
		else
			local kind = if addName[tex] then "ADD" else "UNKNOWN"
			local what = if addName[tex] then ("_add " .. addName[tex] .. ", LightEmission " .. string.format("%.2f", d.LightEmission) .. " -> use alpha." .. addName[tex]) else tex
			local key = kind .. " " .. d.ClassName .. " " .. what .. " (" .. (d.Parent and d.Parent.Name or "?") .. ")"
			counts[key] = (counts[key] or 0) + 1
			if counts[key] == 1 then table.insert(fails, { key = key, path = d:GetFullName() }) end
		end
	end
	local lines = { string.format("==== VfxTextureAudit: %d effects OK, %d kinds failing ====", ok, #fails) }
	if #fails == 0 then table.insert(lines, "CLEAN: every effect uses an approved _alpha texture") end
	if allowedAdd > 0 and VT.brokenAlpha then
		local names = {}
		for k in pairs(VT.brokenAlpha) do table.insert(names, k) end
		table.sort(names)
		table.insert(lines, string.format("(%d effects use an _add file at LightEmission 1 because its _alpha upload is broken: %s. Re-upload those _alpha files)", allowedAdd, table.concat(names, ", ")))
	end
	for _, f in ipairs(fails) do table.insert(lines, string.format("[%s] x%d  e.g. %s", f.key, counts[f.key], f.path)) end
	table.insert(lines, "==== end VfxTextureAudit ====")
	local report = table.concat(lines, "\n")
	print(report)
	return report
end
