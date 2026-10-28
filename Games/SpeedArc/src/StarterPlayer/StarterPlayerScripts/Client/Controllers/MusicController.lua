-- MusicController (Audio note): each area's music, crossfaded 1.5 s when you change area; race music
-- from GO to the finish; music ducks to 40% during the countdown; the Stadium has a crowd bed under it.
-- A track you come back to within 5 s resumes where it left off.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local SoundConfig = require(Shared.Config.Sounds)
local Areas = require(Shared.Config.Areas)

local player = Players.LocalPlayer
local Music = {}
local M = SoundConfig.Music
local tracks = {} -- [key] = Sound
local current = nil
local duck = 1

local function sound(key)
	local def = M[key]
	if not def then
		return nil
	end
	local s = tracks[key]
	if not s then
		s = Instance.new("Sound")
		s.Name = "Music_" .. key
		s.SoundId = def.Id
		s.Looped = true
		s.Volume = 0
		s.SoundGroup = SoundService:FindFirstChild("Music")
		s.Parent = SoundService
		tracks[key] = s
		if def.Bed then
			local bed = Instance.new("Sound")
			bed.Name = "Bed"
			bed.SoundId = def.Bed
			bed.Looped = true
			bed.Volume = 0
			bed.SoundGroup = SoundService:FindFirstChild("Crowd")
			bed.Parent = s
		end
	end
	return s
end

local function fadeTo(s, vol)
	TweenService:Create(s, TweenInfo.new(M.Fade), { Volume = vol }):Play()
	local bed = s:FindFirstChild("Bed")
	if bed then
		TweenService:Create(bed, TweenInfo.new(M.Fade), { Volume = if vol > 0 then 0.25 else 0 }):Play()
	end
end

function Music.play(key)
	if current == key then
		return
	end
	local old = current and tracks[current]
	if old then
		fadeTo(old, 0)
		local stopping = old
		task.delay(M.Fade + 5, function()
			if tracks[current] ~= stopping and stopping.Volume < 0.01 then
				stopping:Pause() -- paused, so coming back soon resumes it
			end
		end)
	end
	current = key
	local s = sound(key)
	if s then
		if not s.IsPlaying then
			if s.IsPaused then
				s:Resume()
			else
				s:Play()
			end
			local bed = s:FindFirstChild("Bed")
			if bed and not bed.IsPlaying then
				bed:Play()
			end
		end
		fadeTo(s, M[key].Volume * duck * SoundConfig.norm(M[key].Id, "Music"))
	end
end

local function areaKey()
	local id = player:GetAttribute("Area") or "Hub"
	return Areas[id] and Areas[id].Music or "Hub"
end

-- FINAL STRETCH: the race music swells (louder, a touch faster) until the finish
function Music.swell()
	local s = current == "Race" and tracks.Race
	if s then
		TweenService:Create(s, TweenInfo.new(1.2), { Volume = M.Race.Volume * 1.3 * SoundConfig.norm(M.Race.Id, "Music"), PlaybackSpeed = 1.04 }):Play()
	end
end

function Music.start(ctx)
	ctx.Music = Music
	Music.play(areaKey())
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if not player:GetAttribute("InRace") then
			Music.play(areaKey())
		end
	end)
	-- race: duck during the countdown, race music from GO, back to the area at the end
	ctx.Net.get("RaceEvent").OnClientEvent:Connect(function(kind, info)
		if kind == "start" then
			local mine = false
			for _, r in info.runners do
				if r.userId == player.UserId then
					mine = true
				end
			end
			if mine then
				duck = M.Duck
				local s = current and tracks[current]
				if s then
					fadeTo(s, M[current].Volume * duck * SoundConfig.norm(M[current].Id, "Music"))
				end
				task.delay(3, function()
					duck = 1
					Music.play("Race")
				end)
			end
		elseif kind == "results" or kind == "ended" then
			duck = 1
			if tracks.Race then
				tracks.Race.PlaybackSpeed = 1
			end
			if current == "Race" then
				Music.play(areaKey())
			end
		end
	end)
end

return Music
