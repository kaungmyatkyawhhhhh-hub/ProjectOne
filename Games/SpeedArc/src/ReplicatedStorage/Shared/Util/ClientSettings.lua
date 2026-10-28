-- ClientSettings (M6): the player's settings on the client - Music and Sounds volume, Low graphics
-- (Auto = Roblox graphics quality 1-3), Reduced motion. Saved in the player's data by the server.
-- Every controller asks here instead of reading the graphics quality itself.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local Shared = script.Parent.Parent
local SoundConfig = require(Shared.Config.Sounds)

local ClientSettings = {}
ClientSettings.Changed = Instance.new("BindableEvent") -- (key, value)

local values = { Music = 0.8, Sounds = 0.8, Low = "Auto", Reduced = false }
local saveQueued = false
local net = nil

function ClientSettings.get(key)
	return values[key]
end

-- low graphics: fewer particles, no bloom / sun rays, simpler trails
function ClientSettings.low()
	if values.Low == "On" then
		return true
	elseif values.Low == "Off" then
		return false
	end
	local ok, q = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	return ok and q ~= 0 and q <= 3
end

-- reduced motion: no camera kicks or shakes, fewer speed lines, no flashes
function ClientSettings.reduced()
	return values.Reduced == true
end

function ClientSettings.applyVolumes()
	for name, base in SoundConfig.Groups do
		local g = SoundService:FindFirstChild(name)
		if g and g:IsA("SoundGroup") then
			local mult = if name == "Music" then values.Music else values.Sounds
			g.Volume = base * mult
		end
	end
end

function ClientSettings.set(key, value)
	if values[key] == value then
		return
	end
	values[key] = value
	if key == "Music" or key == "Sounds" then
		ClientSettings.applyVolumes()
	end
	ClientSettings.Changed:Fire(key, value)
	if net and not saveQueued then
		saveQueued = true
		task.delay(2, function()
			saveQueued = false
			pcall(net.call, "SaveSettings", values)
		end)
	end
end

function ClientSettings.load(Net)
	net = Net
	local ok, got, saved = pcall(Net.call, "GetSettings")
	if ok and got and type(saved) == "table" then
		for k, v in saved do
			if values[k] ~= nil and type(v) == type(values[k]) then
				values[k] = v
			end
		end
	end
	ClientSettings.applyVolumes()
	for k, v in values do
		ClientSettings.Changed:Fire(k, v)
	end
end

ClientSettings.player = Players.LocalPlayer
return ClientSettings
