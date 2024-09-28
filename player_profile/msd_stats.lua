---@param score_time number
local function getLiveRatingWeight(score_time)
	local current_time = os.time()
	local max_decay_time = 30 * 24 * 60 * 60 -- 30 days
	local time_difference = current_time - score_time

	if time_difference <= 0 then
		return 1
	end

	if time_difference >= max_decay_time then
		return 0.2
	end

	local decay_rate = 2 / max_decay_time
	local weight = math.exp(-decay_rate * time_difference)

	weight = 0.2 + (weight * 0.8)

	return weight
end

---@param ssr number[]
---@return number
local function ssrAverage(ssr)
	local avg_count = 20
	local sum = 0.0

	for i, v in ipairs(ssr) do
		if i > avg_count then
			break
		end

		sum = sum + v
	end

	return sum / avg_count
end

---@param self PlayerProfileModel
return function(self)
	local ssr_sorted = {} ---@type number[]
	local live_ssr_sorted = {} ---@type number[]

	for _, v in pairs(self.topScores) do
		if v.overall then
			local weight = getLiveRatingWeight(v.time)
			table.insert(ssr_sorted, v.overall)
			table.insert(live_ssr_sorted, v.overall * weight)
		end
	end

	table.sort(ssr_sorted, function(a, b)
		return a > b
	end)

	table.sort(live_ssr_sorted, function(a, b)
		return a > b
	end)

	self.ssr = ssrAverage(ssr_sorted)
	self.liveSsr = ssrAverage(live_ssr_sorted)
end
