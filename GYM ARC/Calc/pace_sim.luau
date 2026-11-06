-- GYM ARC pace sim (3 Nov; 6 Nov: setup.repSpeed = reps this much faster (MONSTER MIX), out.spurtTimes = each Growth Spurt). Put this in ServerStorage as a ModuleScript "_PaceSim", then in Studio's Edit command bar:
--   game.ReplicatedStorage:SetAttribute("LaunchDone_Gem", true) -- (the Gem Mine counts as open; remove it after!)
--   local r = require(game.ServerStorage._PaceSim).Run({ stars = 3, gains = 3.08, progress = 0.55 })
--   game.ReplicatedStorage:SetAttribute("LaunchDone_Gem", nil)
-- setup = { stars, gains (trainer EXP, 0.77 = +77%), progress, genetics (a Genetics table, default the starter's B), aura,
-- pass (2 = the 2x EXP pass), gear (0.10 = Pro belt + wraps, from Alter 1), noGemEarly (what-if: the Gem Mine only from Alter 15) }
-- -> { spurts = s, alters = { [1..20] = s }, hof = s } (seconds of pure lifting)
-- The rules (the 1 Nov calibration's): one rep every 1.05 s, the heaviest weight the level allows, the best open machine
-- for the weakest muscle of the group furthest from the goal, Balanced +10%, each gym's bonus (Pro x1.1, Powerlifting
-- x1.2, Golden Era club, Gem Mine club), alters one by one (no skip), each alter keeps 25%. Not counted: Muscle of the
-- Day, PUMPED, BIG REP, Run Cards, auras (except a given one), boosts bought, walking / menus.
local C = game.ReplicatedStorage.Shared.Config
local Muscles = require(C.Muscles)
local Machines = require(C.Machines)
local Gains = require(C.Gains)
local GrowthSpurts = require(C.GrowthSpurts)
local Alters = require(C.Alters)
local HallOfFame = require(C.HallOfFame)
local Genetics = require(C.Genetics)
local GoldenEra = require(C.GoldenEra)
local GemMine = require(C.GemMine)

local Sim = {}
local REP = 1.05

local function newData(setup)
	local d = { muscles = {}, growthSpurts = 0, alter = { highest = 0 }, fame = { stars = setup.stars or 0 },
		genetics = setup.genetics or Genetics.Starter(), runCards = {}, trainers = { bonus = { progress = setup.progress or 0 } },
		auras = { equipped = setup.aura }, gymAccess = {}, cosmetics = {}, settings = {} }
	for _, m in ipairs(Muscles.List) do d.muscles[m.id] = { level = 0, xp = 0 } end
	if (setup.stars or 0) > 0 then
		d.growthSpurts = HallOfFame.Perks(setup.stars).startSpurts
		for _, g in ipairs(HallOfFame.KeepGyms) do d.gymAccess[g] = true end
		d.fame.peak = { spurts = 6, alter = 15 }
	end
	return d
end

local total = {} -- [muscleId] = cumulative EXP
local function setXp(d, id, t)
	total[id] = t
	local lv = math.floor(Muscles.LevelFromXp(t))
	d.muscles[id] = { level = lv, xp = t - Muscles.CumXp(lv) }
end

local function open(d, setup, machine): boolean
	if machine.trains == "Stamina" or machine.gym == "Seasonal" then return false end
	if machine.gym == "GemMine" then
		if setup.noGemEarly and (d.alter.highest or 0) < GemMine.UnlockAlter then return false end
		return GemMine.Unlocked(d)
	end
	if d.growthSpurts >= Machines.OpenAt(machine) then return true end
	return (setup.stars or 0) > 0 and table.find(HallOfFame.KeepGyms, machine.gym) ~= nil
end

local function quality(d, setup, machine): number
	local q = Machines.GymGains[machine.gym] or 1
	if machine.gym == "Powerlifting" and GoldenEra.Unlocked(d) then q *= GoldenEra.Gains end
	if machine.gym == "GemMine" then q *= GemMine.Gains end
	return q * (setup.pass or 1)
end

-- one rep's EXP for a muscle entry (Gains.PerRep's formula without Muscle of the Day / Run Cards)
local function repXp(d, setup, machine, tierIndex, entry, q, balanced)
	local tier = machine.tiers[tierIndex]
	local spurt = GrowthSpurts.GetBonus(d.growthSpurts)
	local alterBonus = Alters.Bonus(d.alter.highest or 0) * (1 + HallOfFame.Perks(setup.stars or 0).exp)
	-- (owner, 3 Nov: "everyone starting from alter 1 has pro gear") Pro belt + Pro wraps add setup.gear (0.10) to the boost,
	-- like MachineService (BoostService.Gains + gear - 1), from the alters on (a starred run keeps its gear: the whole run)
	local gear = if setup.gear and (d.gearOn or (setup.stars or 0) > 0) then setup.gear else 0
	local mult = Gains.Total(1, spurt, 1 + (setup.gains or 0) + gear, balanced, 1) * Genetics.GetMultiplier(d.genetics, entry.id)
	local dim = 1 / (1 + math.min(d.muscles[entry.id].level, Gains.DiminishCap) / Gains.DiminishLevel)
	return Gains.BaseXp * tier.gains * (entry.share or 1) * mult * dim * q * (machine.gainScale or 1) * alterBonus
end

local function bestMachine(d, setup, muscleId)
	local best, bestScore, bestTier = nil, -1, 1
	for _, machine in ipairs(Machines.List) do
		if open(d, setup, machine) then
			for _, entry in ipairs(machine.muscles) do
				if entry.id == muscleId then
					local tierIndex = Machines.UsableTier(machine, nil, d.muscles[machine.muscles[1].id].level)
					local score = machine.tiers[tierIndex].gains * (entry.share or 1) * quality(d, setup, machine) * (machine.gainScale or 1)
					if score > bestScore then best, bestScore, bestTier = machine, score, tierIndex end
				end
			end
		end
	end
	return best, bestTier
end

local function train(d, setup, progressFn, cap)
	local reps, choice = 0, {}
	local trainable = Machines.TrainableMuscles(d.growthSpurts)
	while true do
		local progress = progressFn(d, trainable)
		if progress.ready then return reps * REP end
		if reps >= cap then return reps * REP, true end
		local target, low = nil, math.huge
		for _, g in ipairs(Muscles.Groups) do
			local lv = progress.groups[g.id] or 0
			local req = progress.required or 0
			if lv < req and lv < low then low, target = lv, g end
		end
		if not target then return reps * REP end
		local muscleId, lowXp = nil, math.huge
		for _, m in ipairs(target.muscles) do
			if trainable[m.id] and (total[m.id] or 0) < lowXp then muscleId, lowXp = m.id, total[m.id] or 0 end
		end
		local key = muscleId .. ":" .. math.floor(d.muscles[muscleId].level / 5)
		local pick = choice[key]
		if not pick then
			local machine, tierIndex = bestMachine(d, setup, muscleId)
			pick = { machine = machine, tier = tierIndex }
			choice[key] = pick
		end
		local machine = pick.machine
		if not machine then return reps * REP, true end
		local tierIndex = Machines.UsableTier(machine, nil, d.muscles[machine.muscles[1].id].level)
		local q = quality(d, setup, machine)
		local balanced = if Gains.IsBalanced(d) then Gains.BalancedBonus else 1
		for _ = 1, 8 do
			for _, entry in ipairs(machine.muscles) do
				setXp(d, entry.id, (total[entry.id] or 0) + repXp(d, setup, machine, tierIndex, entry, q, balanced))
			end
			reps += 1
		end
		if reps % 400 == 0 then task.wait() end
	end
end

local function spurtProgress(d, trainable) return GrowthSpurts.Progress(d, Muscles.Groups, trainable) end
local function alterProgress(d, trainable)
	local p = Alters.Progress(d, Muscles.Groups, trainable)
	p.ready = p.met == p.total
	return p
end
local function hofProgress(d, _trainable)
	local p = HallOfFame.GoalProgress(d)
	p.ready = p.met == p.total
	return p
end

function Sim.Run(setup)
	table.clear(total)
	local d = newData(setup)
	for _, m in ipairs(Muscles.List) do total[m.id] = 0 end
	local out = { name = setup.name, alters = {} }
	local t = 0
	local rs = setup.repSpeed or 1
	out.spurtTimes = {}
	while not GrowthSpurts.IsMaxed(d.growthSpurts) do
		local one = train(d, setup, spurtProgress, 60000) / rs
		table.insert(out.spurtTimes, one)
		t += one
		d.growthSpurts += 1
	end
	out.spurts = t
	d.gearOn = true
	for n = 1, 20 do
		local s, capped = train(d, setup, alterProgress, 80000)
		s /= (setup.repSpeed or 1)
		out.alters[n] = s
		if capped then out.capped = n break end
		d.alter = { highest = n }
		for _, m in ipairs(Muscles.List) do
			local kept = Alters.Kept(d.muscles[m.id])
			setXp(d, m.id, Muscles.CumXp(kept.level) + kept.xp)
		end
		if n == 15 then
			local keep15 = { muscles = table.clone(d.muscles), total = table.clone(total) }
			out.hof = train(d, setup, hofProgress, 80000)
			d.muscles, total = keep15.muscles, keep15.total
		end
	end
	return out
end

return Sim
