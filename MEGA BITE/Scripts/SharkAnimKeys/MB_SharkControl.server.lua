-- MB_SharkControl (server): E prompt on the Reef Shark gives one player control; keys 1-6 play clips for everyone.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local folder = RS:WaitForChild("MB_Anim")
local remote = folder:WaitForChild("PlayClip")
local Clips = require(folder:WaitForChild("ReefSharkClips"))

local shark = workspace:WaitForChild("MB_ImportTest"):WaitForChild("MB_ReefShark_v11")
local body = shark:WaitForChild("ReefShark")
for _, d in ipairs(shark:GetDescendants()) do
	if d:IsA("BasePart") then d.Anchored = true end
end

local prompt = body:FindFirstChild("ControlPrompt") or Instance.new("ProximityPrompt")
prompt.Name = "ControlPrompt"
prompt.ActionText = "Control shark"
prompt.ObjectText = "Reef Shark"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 30
prompt.RequiresLineOfSight = false
prompt.Parent = body

shark:SetAttribute("ControllerId", 0)
local function setController(id)
	shark:SetAttribute("ControllerId", id)
	prompt.ActionText = (id == 0) and "Control shark" or "Stop controlling"
end

prompt.Triggered:Connect(function(plr)
	local cur = shark:GetAttribute("ControllerId")
	if cur == plr.UserId then setController(0)
	elseif cur == 0 then setController(plr.UserId) end
end)

Players.PlayerRemoving:Connect(function(plr)
	if shark:GetAttribute("ControllerId") == plr.UserId then setController(0) end
end)

local last = {}
remote.OnServerEvent:Connect(function(plr, name)
	if plr.UserId ~= shark:GetAttribute("ControllerId") then return end
	if type(name) ~= "string" or not Clips[name] then return end
	local now = os.clock()
	if last[plr] and now - last[plr] < 0.1 then return end
	last[plr] = now
	remote:FireAllClients(name)
end)
