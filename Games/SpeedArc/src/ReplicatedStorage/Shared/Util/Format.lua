-- Number formatting for the HUD (big numbers get K / M / B later in the game).
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.short(n)
	n = math.floor(n) -- round down: never show "150" while you're still at 149.6 and the goal says 150
	if n < 10000 then
		return Format.commas(n)
	end
	local i = 1
	local v = n
	while v >= 1000 and i < #SUFFIXES do
		v = v / 1000
		i += 1
	end
	if v >= 100 then
		return string.format("%d%s", math.floor(v), SUFFIXES[i])
	end
	return string.format("%.1f%s", math.floor(v * 10) / 10, SUFFIXES[i])
end

function Format.commas(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

function Format.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Format.place(n)
	local last = n % 10
	local lastTwo = n % 100
	if last == 1 and lastTwo ~= 11 then
		return n .. "ST"
	elseif last == 2 and lastTwo ~= 12 then
		return n .. "ND"
	elseif last == 3 and lastTwo ~= 13 then
		return n .. "RD"
	end
	return n .. "TH"
end

function Format.seconds(t)
	return string.format("%.1f s", t)
end

return Format
