-- CodesConfig (Galaxy Incremental, overnight part 2, 3 Nov): the starting codes and their rules (design additions 3).
-- The LIVE list = these + the DataStore "GalaxyCodes" (key "list") on top, which the owner changes from the console
-- without publishing (GalaxyCodeService: ServerStorage.Admin:Invoke("code", ...)). Every server re-reads it every 5 min.
-- reward = { essence = n, potions = { Stardust = n, Comets = n }, boost = minutes of x2 stardust, starting at once }
-- ends = the last day, UTC "YYYY-MM-DD" (nil = never ends)
local Codes = {}

Codes.Start = {
	-- (owner, 7 Nov: the alpha's code: 2x stardust for 30 min (starts right away) + 2 Essence, until 21 Dec)
	ALPHA = { reward = { essence = 2, boost = 30 }, ends = "2026-12-21" },
	GALAXY = { reward = { potions = { Comets = 1 } } },
}

Codes.TriesPerMinute = 5
Codes.Refresh = 300 -- seconds between re-reads of the live list
Codes.MaxEssence = 1000 -- (a console typo can't hand out millions)
Codes.MaxPotions = 20

-- what the player typed -> the code's key: any case, spaces and symbols ignored
function Codes.Normalize(text: string): string
	return (string.upper(tostring(text or "")):gsub("[^%w]", "")):sub(1, 30)
end

-- "+3 ESSENCE, +1 x2 STARDUST" (the reward line; potion names from EconConfig)
function Codes.Describe(reward, potionsById): string
	local parts = {}
	if (reward.boost or 0) > 0 then table.insert(parts, "2x STARDUST " .. reward.boost .. " MIN") end
	if (reward.essence or 0) > 0 then table.insert(parts, "+" .. reward.essence .. " ESSENCE") end
	for id, n in pairs(reward.potions or {}) do
		local p = potionsById[id]
		if p and n > 0 then table.insert(parts, "+" .. n .. " " .. p.name .. (if n > 1 then " POTIONS" else " POTION")) end
	end
	return table.concat(parts, ", ")
end

return Codes
