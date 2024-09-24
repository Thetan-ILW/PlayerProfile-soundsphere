local ranks = {
	{ pp = 29289, rank = 1 },
	{ pp = 28157, rank = 2 },
	{ pp = 27409, rank = 3 },
	{ pp = 27339, rank = 5 },
	{ pp = 25964, rank = 10 },
	{ pp = 23836, rank = 25 },
	{ pp = 22153, rank = 50 },
	{ pp = 21008, rank = 69 },
	{ pp = 20234, rank = 100 },
	{ pp = 18147, rank = 200 },
	{ pp = 16817, rank = 300 },
	{ pp = 15864, rank = 400 },
	{ pp = 15131, rank = 500 },
	{ pp = 14000, rank = 767 },
	{ pp = 12000, rank = 1632 },
	{ pp = 10000, rank = 3598 },
	{ pp = 9000, rank = 5293 },
	{ pp = 8000, rank = 8094 },
	{ pp = 7000, rank = 12127 },
	{ pp = 6000, rank = 18192 },
	{ pp = 5000, rank = 28575 },
	{ pp = 4000, rank = 47068 },
	{ pp = 3000, rank = 77256 },
	{ pp = 2000, rank = 129527 },
	{ pp = 1000, rank = 253335 },
	{ pp = 500, rank = 398207 },
	{ pp = 100, rank = 713591 },
	{ pp = 0, rank = 2270681 }
}

---@param pp number
---@return number
local function getRank(pp)
	for i = 1, #ranks do
		if pp >= ranks[i].pp then
			if i == 1 then
				return ranks[i].rank
			else
				local lower = ranks[i]
				local upper = ranks[i-1]
				local rank_diff = lower.rank - upper.rank
				local pp_diff = upper.pp - lower.pp
				local pp_above_lower = pp - lower.pp
				return lower.rank - math.floor((pp_above_lower / pp_diff) * rank_diff)
			end
		end
	end

	return ranks[#ranks].rank
end

---@param self PlayerProfileModel
return function(self)
	self.pp = 0

	---@type number[]
	local pp_sorted = {}
	local accuracy = 0
	local num_scores = 0
	local total_score = 0

	for _, v in pairs(self.topScores) do
		table.insert(pp_sorted, v.osuPP)

		accuracy = accuracy + v.osuAccuracy
		num_scores = num_scores + 1
		total_score = total_score + v.osuScore
	end

	table.sort(pp_sorted, function(a, b)
		return a > b
	end)

	for i, pp in pairs(pp_sorted) do
		self.pp = self.pp + (pp * math.pow(0.95, (i - 1)))
	end

	if num_scores > 0 then
		self.accuracy = accuracy / num_scores
	end
	self.rank = getRank(self.pp)

	local lvls = self.osuLevels

	for i = 2, 199 do
		local this = lvls[i - 1]
		local next = lvls[i]
		if total_score >= this and total_score < next then
			self.osuLevel = i - 1
			self.osuLevelPercent = (total_score - this) / (next - this)
			return
		end
	end

	self.osuLevel = 999
end
