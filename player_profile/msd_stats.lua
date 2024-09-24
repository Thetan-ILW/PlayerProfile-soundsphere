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

---@param ssr table<string, number>[]
---@return table<string, number>
local function ssrAverage(ssr)
	local avg_count = 20

	local overall_sum = 0
	local stream_sum = 0
	local jumpstream_sum = 0
	local handstream_sum = 0
	local stamina_sum = 0
	local jackspeed_sum = 0
	local chordjack_sum = 0
	local technical_sum = 0

	for i, v in ipairs(ssr) do
		if i > avg_count then
			break
		end

		overall_sum = overall_sum + v.overall
		stream_sum = stream_sum + v.stream
		jumpstream_sum = jumpstream_sum + v.jumpstream
		handstream_sum = handstream_sum + v.handstream
		stamina_sum = stamina_sum + v.stamina
		jackspeed_sum = jackspeed_sum + v.jackspeed
		chordjack_sum = chordjack_sum + v.chordjack
		technical_sum = technical_sum + v.technical
	end

	return {
		overall = overall_sum / avg_count,
		stream = stream_sum / avg_count,
		jumpstream = jumpstream_sum / avg_count,
		handstream = handstream_sum / avg_count,
		stamina = stamina_sum / avg_count,
		jackspeed = jackspeed_sum / avg_count,
		chordjack = chordjack_sum / avg_count,
		technical = technical_sum / avg_count,
	}
end

---@param self PlayerProfileModel
return function(self)
	local ssr_sorted = {}
	local live_ssr_sorted = {}

	for _, v in pairs(self.topScores) do
		if v.overall then
			table.insert(ssr_sorted, {
				overall = v.overall,
				stream = v.stream,
				jumpstream = v.jumpstream,
				handstream = v.handstream,
				stamina = v.stamina,
				jackspeed = v.jackspeed,
				chordjack = v.chordjack,
				technical = v.technical,
			})

			local weight = getLiveRatingWeight(v.time)

			table.insert(live_ssr_sorted, {
				overall = v.overall * weight,
				stream = v.stream * weight,
				jumpstream = v.jumpstream * weight,
				handstream = v.handstream * weight,
				stamina = v.stamina * weight,
				jackspeed = v.jackspeed * weight,
				chordjack = v.chordjack * weight,
				technical = v.technical * weight,
			})
		end
	end

	table.sort(ssr_sorted, function(a, b)
		return a.overall > b.overall
	end)

	table.sort(live_ssr_sorted, function(a, b)
		return a.overall > b.overall
	end)

	self.ssr = ssrAverage(ssr_sorted)
	self.liveSsr = ssrAverage(live_ssr_sorted)
end
