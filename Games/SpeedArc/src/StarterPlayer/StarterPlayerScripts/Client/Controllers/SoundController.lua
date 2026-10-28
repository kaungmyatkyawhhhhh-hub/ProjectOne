-- SoundController: pooled, layered sounds with pitch variation (Audio note rules).
-- No new Sound per play; never the same clip twice in a row; everything from Config/Sounds.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local Shared = game:GetService("ReplicatedStorage").Shared
local SoundConfig = require(Shared.Config.Sounds)
local UIKit = require(Shared.UIKit)
local ClientSettings = require(Shared.Util.ClientSettings)

local SoundController = {}

local groups = {}
local pools = {} -- [key] = { ids = { [id] = { sounds, nextIndex } }, lastId }

local function makeGroup(name, volume)
	local g = Instance.new("SoundGroup")
	g.Name = name
	g.Volume = volume
	g.Parent = SoundService
	groups[name] = g
end

function SoundController.start(ctx)
	ctx.Sound = SoundController
	for name, vol in SoundConfig.Groups do
		makeGroup(name, vol)
	end

	local folder = Instance.new("Folder")
	folder.Name = "SpeedArcSounds"
	folder.Parent = SoundService
	local preload = {}

	for key, def in SoundConfig.Sounds do
		if def.Ids then
			local entry = { ids = {}, list = def.Ids, lastId = nil, def = def }
			for _, id in def.Ids do
				local copies = {}
				for i = 1, def.Pool or 1 do
					local s = Instance.new("Sound")
					s.Name = key .. "_" .. i
					s.SoundId = id
					s.Volume = def.Volume or 0.5
					s.SoundGroup = groups[def.Group or "SFX"]
					s.Parent = folder
					copies[i] = s
					if i == 1 then
						table.insert(preload, s)
					end
				end
				entry.ids[id] = { sounds = copies, nextIndex = 1 }
			end
			pools[key] = entry
		end
	end

	-- preload in the background so the first tap never stalls
	task.spawn(function()
		ContentProvider:PreloadAsync(preload)
	end)

	-- the player's saved volumes / graphics / motion settings (M6)
	ctx.Settings = ClientSettings
	task.spawn(ClientSettings.load, ctx.Net)

	UIKit.setClickHook(function(name)
		SoundController.play(name or "Click")
	end)
	UIKit.windowSound = function(kind)
		SoundController.play(if kind == "open" then "WindowOpen" else "WindowClose")
	end
end

-- opts: Pitch (multiplier), Volume (multiplier)
function SoundController.play(key, opts)
	local def = SoundConfig.Sounds[key]
	if not def then
		return
	end
	opts = opts or {}
	local entry = pools[key]
	if entry then
		local id = entry.list[1]
		if #entry.list > 1 then
			repeat
				id = entry.list[math.random(1, #entry.list)]
			until id ~= entry.lastId
		end
		entry.lastId = id
		local pool = entry.ids[id]
		local s = pool.sounds[pool.nextIndex]
		pool.nextIndex = pool.nextIndex % #pool.sounds + 1
		local lo, hi = def.Pitch[1], def.Pitch[2]
		s.PlaybackSpeed = (lo + (hi - lo) * math.random()) * (opts.Pitch or 1)
		s.Volume = (def.Volume or 0.5) * (opts.Volume or 1) * SoundConfig.norm(id, def.Group)
		s.TimePosition = 0
		s:Play()
	end
	if def.Layers then
		for _, layer in def.Layers do
			SoundController.play(layer, opts)
		end
	end
end

function SoundController.stop(key)
	local entry = pools[key]
	if not entry then
		return
	end
	for _, pool in entry.ids do
		for _, s in pool.sounds do
			s:Stop()
		end
	end
end

function SoundController.group(name)
	return groups[name]
end

return SoundController
