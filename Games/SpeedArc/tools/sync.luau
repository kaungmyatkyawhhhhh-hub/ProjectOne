-- Paste into the SPEED ARC Studio command bar (or run through MCP) while `serve.bat` is running.
-- Pulls every script listed in src/manifest.json from http://127.0.0.1:8765 and writes it into the place.
-- HTTP is switched on only for the sync and switched back off after.
local HttpService = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8765/"

local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local ok, result = pcall(function()
	local manifest = HttpService:JSONDecode(HttpService:GetAsync(BASE .. "manifest.json", true))
	local count = 0
	for _, e in manifest do
		local source = HttpService:GetAsync(BASE .. e.file, true)
		local parent = game:GetService(e.path[1])
		for i = 2, #e.path - 1 do
			local child = parent:FindFirstChild(e.path[i])
			if not child then
				child = Instance.new("Folder")
				child.Name = e.path[i]
				child.Parent = parent
			end
			parent = child
		end
		local name = e.path[#e.path]
		local inst = parent:FindFirstChild(name)
		if inst and inst.ClassName ~= e.class then
			inst:Destroy()
			inst = nil
		end
		if not inst then
			inst = Instance.new(e.class)
			inst.Name = name
			inst.Parent = parent
		end
		inst.Source = source
		count += 1
	end
	return count
end)
HttpService.HttpEnabled = was
print(if ok then ("[sync] %d scripts updated"):format(result) else "[sync] failed: " .. tostring(result))
return if ok then result else tostring(result)
