local class = require("class")

local json = require("json")
local dans = require("player_profile.dans")

local getPP = require("player_profile.osu_pp")

local DiffcalcContext = require("sphere.models.DifficultyModel.DiffcalcContext")
local has_minacalc, etterna_msd = pcall(require, "libchart.etterna_msd")
local _, minacalc = pcall(require, "libchart.minacalc")

---@class PlayerProfileModel
---@operator call: PlayerProfileModel
---@field topScores {[string]: ProfileTopScore}
---@field scores {[integer]: ProfileScore}
---@field pp number
---@field accuracy number
---@field ssr table<string, number>
---@field liveSsr table<string, number>
---@field danClears table<string, table<string, string>>
---@field danInfos { name: string, hash: string, category: string, ss: string?, accuracy: number? }[]
local PlayerProfileModel = class()

---@class ProfileTopScore
---@field mode string
---@field time number
---@field rate number
---@field danClear boolean?
---@field osuAccuracy number
---@field osuScore number
---@field osuPP number
---@field overall number?
---@field stream number?
---@field jumpstream number?
---@field handstream number?
---@field stamina number?
---@field jackspeed number?
---@field chordjack number?
---@field technical number?

---@class ProfileScore
---@field osuAccuracy number
---@field osuv2Accuracy number
---@field osuScore number
---@field etternaAccuracy number
---@field quaverAccuracy number

local db_path = "userdata/player_profile"

PlayerProfileModel.danChars = {
	Alpha = "α",
	Beta = "β",
	Gamma = "γ",
	Delta = "δ",
	Epsilon = "ε",
	Zeta = "ζ",
	Eta = "η",
	Theta = "θ",
}

---@param notification_model sphere.NotificationModel
function PlayerProfileModel:new(notification_model)
	self.notificationModel = notification_model
	self.topScores = {}
	self.scores = {}

	self.pp = 0
	self.accuracy = 0
	self.osuLevel = 0
	self.osuLevelPercent = 0
	self.rank = 0

	self.ssr = {
		overall = 0,
		stream = 0,
		jumpstream = 0,
		handstream = 0,
		stamina = 0,
		jackspeed = 0,
		chordjack = 0,
		technical = 0,
	}

	self.liveSsr = {
		overall = 0,
		stream = 0,
		jumpstream = 0,
		handstream = 0,
		stamina = 0,
		jackspeed = 0,
		chordjack = 0,
		technical = 0,
	}

	self.osuLevels = { 0 }

	---TODO: Add levels above 100
	for i = 1, 100 do
		table.insert(self.osuLevels, 5000 / 3 * (4 * i^3 - 3 * i^2 - i) + 1.25 * 1.8^(i - 60))
	end

	self.danInfos = {}
	self.danClears = {}

	for input_mode_name, input_mode in pairs(dans) do
		self.danClears[input_mode_name] = {}
		for category_name, category in pairs(input_mode) do
			for i, item in ipairs(category) do
				item.category = category_name
				self.danInfos[item.hash] = item
			end
		end
	end

	local err = self:loadScores()

	if err then
		self:error(err)
		return
	end

	self:findDanClears()
end

function PlayerProfileModel:error(err)
	self.pp = -1
	self.writeScores = function () end
	self.loadScores = function () end
	self.notificationModel:notify("!Critical error:\nFailed to load local profile scores!\nCheck the console for details.")
	print(err)
end

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
function PlayerProfileModel:getRank(pp)
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

---@param chartdiff table
---@param chart ncdk2.Chart
---@param accuracy number
---@return table<string, number>
function PlayerProfileModel:getMsd(chartdiff, chart, accuracy)
	if not has_minacalc or chartdiff.inputmode ~= "4key" then
		return {}
	end

	local rate = chartdiff.rate
	local diff_context = DiffcalcContext(chartdiff, chart, rate)

	local notes = diff_context:getSimplifiedNotes()
	local rows, row_count = etterna_msd.getRows(notes)
	local status, result = pcall(minacalc.getSsr, rows, row_count, rate, accuracy)

	return result
end

---@param key string
---@param chart ncdk2.Chart
---@param chartdiff table
---@param score_system sphere.ScoreSystemContainer
---@param play_context sphere.PlayContext
function PlayerProfileModel:addScore(key, chart, chartdiff, score_system, play_context)
	local old_score = self.scores[key]
	local dan_info = self.danInfos[key]

	local score_id = play_context.scoreEntry.id
	local paused = play_context.scoreEntry.pauses > 0

	---@type sphere.Judge
	local osu_v1 = score_system.judgements["osu!legacy OD9"]

	---@type number
	local osu_score = osu_v1.score
	---@type number
	local j4_accuracy = score_system.judgements["Etterna J4"].accuracy

	local pp = getPP(chartdiff.notes_count, chartdiff.osu_diff, 9, osu_score)
	local msds = self:getMsd(chartdiff, chart, j4_accuracy)

	---@type number
	local rate = chartdiff.rate

	---@type boolean?
	local dan_clear = nil

	if dan_info then
		local score_system_name = dan_info.ss or "osu!legacy OD9"
		local clear_accuracy = dan_info.accuracy or 0.96

		---@type number
		local accuracy = score_system.judgements[score_system_name].accuracy

		dan_clear = accuracy >= clear_accuracy

		if rate < 1 then
			dan_clear = false
			self.notificationModel:notify("@Using music speed below 1.00x is not allowed on this chart.")
		end

		if paused then
			dan_clear = false
			self.notificationModel:notify("@Pausing is not allowed on this chart.")
		end
	end

	local should_count = true

	if old_score then
		if dan_info then
			if old_score.danClear and not dan_clear then
				should_count = false
			end
		end

		if pp <= old_score.osuPP then
			should_count = false
		end

		if dan_info then
			if not old_score.danClear and dan_clear then
				should_count = true
			end
		end
	end

	if not should_count then
		return
	end

	if dan_clear then
		self.notificationModel:notify("@Congratulations! You cleared this dan!")
	end

	self.topScores[key] = {
		time = os.time(),
		mode = chartdiff.inputmode,
		rate = chartdiff.rate,
		danClear = dan_clear,
		osuAccuracy = osu_v1.accuracy,
		osuPP = pp,
		osuScore = osu_score,
		overall = msds.overall,
		stream = msds.stream,
		jumpstream = msds.jumpstream,
		handstream = msds.handstream,
		stamina = msds.stamina,
		jackspeed = msds.jackspeed,
		chordjack = msds.chordjack,
		technical = msds.technical,
	}

	self.scores[score_id] = {
		osuScore = osu_score,
		osuAccuracy = osu_v1.accuracy,
		etternaAccuracy = j4_accuracy,
		osuv2Accuracy = score_system.judgements["osu!mania OD8"].accuracy,
		quaverAccuracy = score_system.judgements["Quaver standard"].accuracy,
	}

	local err = self:writeScores()

	if err then
		self:error(err)
		return
	end

	self:calculateOsuStats()
	self:calculateMsdStats()
	self:findDanClears()
end

---@param score_id integer
---@return ProfileScore
function PlayerProfileModel:getScore(score_id)
	return self.scores[score_id]
end

function PlayerProfileModel:calculateOsuStats()
	self.pp = 0

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
	self.rank = self:getRank(self.pp)

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

function PlayerProfileModel:findDanClears()
	for input_mode_name, input_mode in pairs(dans) do
		for category_name, category in pairs(input_mode) do
			for i, item in ipairs(category) do
				local score = self.scores[item.hash]

				if score and score.danClear then
					self.danClears[input_mode_name][category_name] = item.name
				end
			end
		end
	end
end

---@param hash string
---@param inputmode string
---@return boolean
---@return boolean
function PlayerProfileModel:isDanIsCleared(hash, inputmode)
	local key = ("%s_%s"):format(hash, inputmode)
	local info = self.danInfos[key]

	if not info then
		return false, false
	end

	local category = info.category
	local dan_name = info.name

	local cleared_dan = self.danClears[inputmode][category] or "not cleared"

	return true, cleared_dan == dan_name
end

---@param score_time number
function PlayerProfileModel:getLiveRatingWeight(score_time)
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

function PlayerProfileModel:calculateMsdStats()
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

			local weight = self:getLiveRatingWeight(v.time)

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

---@param inputmode string
---@return string, string
function PlayerProfileModel:getDanClears(inputmode)
	local dan_clears = self.danClears[inputmode]

	if dan_clears then
		local regular = dan_clears.regular or "-"
		local ln = dan_clears.ln or "-"

		return self.danChars[regular] or regular, ln
	end
	return "-", "-"
end

---@param text string
local function cipher(text)
	local key = "go away"
	local result = {}
	for i = 1, #text do
		local char = string.byte(text, i)
		local key_char = string.byte(key, (i - 1) % #key + 1)
		result[i] = string.char(bit.bxor(char, key_char))
	end
	return table.concat(result)
end

---@return string? error
---@nodiscard
function PlayerProfileModel:loadScores()
	if PlayerProfileModel.testing then
		return
	end

	if not love.filesystem.getInfo(db_path) then
		return self:writeScores()
	end

	local file = love.filesystem.newFile(db_path)
	local ok, err = file:open("r")

	if not ok then
		return err
	end

	---@type { version: number, topScores: {[string]: ProfileTopScore}, scores: {[string]: ProfileScore} }
	local t = json.decode(cipher(file:read()))

	---@type {[string]: ProfileScore}
	local scores

	if t.version ~= 1 then
		scores = {}
		self.topScores = t.scores
	else
		scores = t.scores
		self.topScores = t.topScores
	end

	for k, v in pairs(scores) do
		self.scores[tonumber(k)] = v
	end

	file:close()

	self:calculateOsuStats()
	self:calculateMsdStats()
end

---@return string? error
---@nodiscard
function PlayerProfileModel:writeScores()
	if PlayerProfileModel.testing then
		return
	end

	local file = love.filesystem.newFile(db_path)
	local ok, err = file:open("w")

	if not ok then
		return err
	end

	local scores = {}

	for k, v in pairs(self.scores) do
		scores[tostring(k)] = v
	end

	local t = {
		topScores = self.topScores,
		scores = scores,
		version = 1
	}

	local encoded = json.encode(t)
	file:write(cipher(encoded))
	file:close()
end

return PlayerProfileModel
