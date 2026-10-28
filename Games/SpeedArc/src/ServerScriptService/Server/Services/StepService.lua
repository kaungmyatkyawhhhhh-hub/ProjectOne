-- StepService (28 Oct pivot: "+1 SPEED every step"). The server measures how far each player runs
-- and turns every Course.StudsPerStep into one step: Formulas.stepBase x all boosts SPEED, plus a
-- small share of coins. Only real running counts: no teleports (too far for one tick), no races, no
-- AFK machines (TrainingService pays those), nothing while anchored, at most MaxStepsPerSecond.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Course = require(Shared.Config.Course)
local Formulas = require(Shared.Util.Formulas)
local Boosts = require(Shared.Util.Boosts)
local PlayerData = require(script.Parent.PlayerData)
local SessionBoosts = require(script.Parent.SessionBoosts)

local StepService = {}
StepService.Stepped = Instance.new("BindableEvent") -- (player, totalSteps, steps)

local TICK = 0.2
local state = {} -- [player] = { pos = Vector3?, acc = studs, coinFrac = n }

-- SPEED one step is worth for this player right now
function StepService.gain(player, data)
	return Formulas.stepBase(data) * Boosts.compute(data).Train * SessionBoosts.trainMult(player, data)
end

-- pay n steps (running or an AFK machine); mult = the machine's Mult
function StepService.pay(player, data, n, mult)
	if n <= 0 then
		return
	end
	local b = Boosts.compute(data)
	local gain = Formulas.stepBase(data) * b.Train * SessionBoosts.trainMult(player, data) * (mult or 1)
	PlayerData.set(player, "Speed", data.Speed + gain * n)
	data.Stats.Steps = (data.Stats.Steps or 0) + n
	local s = state[player]
	if s then
		s.coinFrac += Formulas.coinsPerTap(data.League) * b.Coins * n
		if s.coinFrac >= 1 then
			local whole = math.floor(s.coinFrac)
			s.coinFrac -= whole
			PlayerData.set(player, "Coins", data.Coins + whole)
		end
	end
	StepService.Stepped:Fire(player, data.Stats.Steps, n)
end

local function sample(player, s)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or root.Anchored or player:GetAttribute("InRace") then
		s.pos = nil
		return
	end
	local p = root.Position
	local last = s.pos
	s.pos = p
	if not last then
		return
	end
	local d = Vector3.new(p.X - last.X, 0, p.Z - last.Z).Magnitude
	-- a teleport or a fling is never steps: at most a bit more than walking for one tick
	if d > hum.WalkSpeed * TICK * 1.6 + 1 then
		return
	end
	s.acc += d
	local steps = math.floor(s.acc / Course.StudsPerStep)
	if steps <= 0 then
		return
	end
	s.acc -= steps * Course.StudsPerStep
	steps = math.min(steps, math.ceil(Course.MaxStepsPerSecond * TICK))
	local data = PlayerData.get(player)
	if data then
		StepService.pay(player, data, steps)
	end
end

function StepService.start()
	local function add(player)
		state[player] = { pos = nil, acc = 0, coinFrac = 0 }
		player.CharacterAdded:Connect(function()
			local s = state[player]
			if s then
				s.pos = nil
			end
		end)
	end
	Players.PlayerAdded:Connect(add)
	for _, p in Players:GetPlayers() do
		add(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		state[p] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for player, s in state do
				if player.Parent then
					sample(player, s)
				end
			end
		end
	end)
end

return StepService
