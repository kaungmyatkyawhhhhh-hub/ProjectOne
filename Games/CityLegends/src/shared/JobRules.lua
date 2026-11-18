--[[
	JobRules: the sums for jobs (Config.Jobs), pure so tools/jobs_test.luau can check them.
	J = Config.Jobs. Used by server/Jobs.lua (pays) and client/JobsClient.lua (the HUD bar).
]]

local JobRules = {}

-- rank (1..5) for this much job XP, the XP into that rank and the XP the rank spans (0 at the top)
function JobRules.rank(J: any, xp: number): (number, number, number)
	local r = 1
	for i, need in J.RankXp do
		if xp >= need then
			r = i
		end
	end
	local nextAt = J.RankXp[r + 1]
	if not nextAt then
		return r, 0, 0
	end
	return r, xp - J.RankXp[r], nextAt - J.RankXp[r]
end

function JobRules.mult(J: any, rank: number, double: boolean?): number
	return (J.RankMult[rank] or 1) * (if double then J.DoublePayMult else 1)
end

function JobRules.paycheck(J: any, job: any, rank: number, double: boolean?): number
	return math.floor(job.paycheck * JobRules.mult(J, rank, double) + 0.5)
end

-- a bus stop, taxi fare or patrol point: the job's base plus its rate per stud of the leg
function JobRules.taskPay(J: any, job: any, rank: number, dist: number, double: boolean?): number
	return math.floor(((job.base or 0) + (job.perStud or 0) * math.max(0, dist)) * JobRules.mult(J, rank, double) + 0.5)
end

-- a leg this long can't be driven quicker than this
function JobRules.minLegSeconds(J: any, dist: number): number
	return dist / J.MaxSps
end

-- the UTC day number (posts' daily cap)
function JobRules.day(t: number): number
	return math.floor(t / 86400)
end

function JobRules.byId(J: any, id: any): any
	for _, job in J.List do
		if job.id == id then
			return job
		end
	end
	return nil
end

return JobRules
