-- (25 Nov 2026, DECK OVERLAP FIX agent) _G.RBXPRINT(label, marker): print a finished RBXJob's slices into the Studio log
-- as "P8SM <label> <k> <n> <i> <m> <chunk>" lines of 900 chars (the log cuts lines at ~1,020) and "P8SMEND <label> <n> np
-- <pages>", after a marker line; read them with `roads05_loggrab.py <tag> <copy of the log after the marker>`.
-- Paste after RebuildCell.luau. Returns the number of lines printed (spawned: poll _G.RBXP[label]).
_G.RBXP = _G.RBXP or {}
_G.RBXPRINT = function(label, marker)
	_G.RBXP[label] = "printing"
	task.spawn(function()
		local s = _G.RBX.slices[label]
		print(marker or ("RBXPRINT " .. label))
		local lines = 0
		for k, sl in s.sl do
			local m = math.ceil(#sl / 900)
			for i = 1, m do
				print(string.format("P8SM %s %d %d %d %d %s", label, k, #s.sl, i, m, sl:sub((i - 1) * 900 + 1, i * 900)))
				lines += 1
				if lines % 150 == 0 then
					task.wait()
				end
			end
		end
		print(string.format("P8SMEND %s %d np %d", label, #s.sl, s.np))
		_G.RBXP[label] = "done " .. lines
	end)
	return "started"
end
