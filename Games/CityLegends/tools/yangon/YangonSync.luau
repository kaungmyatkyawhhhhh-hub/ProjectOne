-- Takes the ModuleScripts out of ServerStorage.YangonToolsIn (a pack made by tools/yangon/pack_tools.py and
-- brought in with insert_asset), puts their Source into ServerStorage.ClaudeTools and deletes the pack.
-- Returns each module's length and checksum: they must equal what pack_tools.py printed.
return function(): string
	local SS = game:GetService("ServerStorage")
	local inF = SS:FindFirstChild("YangonToolsIn")
	if not inF then
		return "no ServerStorage.YangonToolsIn"
	end
	local CT = SS.ClaudeTools
	local out = {}
	for _, m in inF:GetChildren() do
		if m:IsA("ModuleScript") then
			local old = CT:FindFirstChild(m.Name)
			local src = m.Source
			if not old then
				old = Instance.new("ModuleScript")
				old.Name = m.Name
				old.Parent = CT
			end
			local ok = pcall(function()
				old.Source = src
			end)
			if not ok then
				game:GetService("ScriptEditorService"):UpdateSourceAsync(old, function()
					return src
				end)
			end
			local h = 0
			for i = 1, #old.Source do
				h = (h * 31 + string.byte(old.Source, i)) % 2147483647
			end
			table.insert(out, string.format("%s: %d chars, checksum %d", m.Name, #old.Source, h))
		end
	end
	inF:Destroy()
	return table.concat(out, "\n")
end
