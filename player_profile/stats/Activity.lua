local class = require("class")

---@alias DayStats { date: string, sessionTime: number, chartsPlayed: number, keysPressed: number, rageQuits: number }
---@alias ActivityRectangle { stats: DayStats, alphaColor: number, week: number, day: number } 

---@class Activity
---@operator call: Activity
---@field year number | string
---@field rectangles ActivityRectangle[]
---@field sessionCount number
---@field maxSessionTime number
---@field avgSessionTime number
local Activity = class()

---@param sessions ProfileSession[]
---@param year number?
function Activity:new(sessions, year)
	self.year = year or os.date("*t").year
	self.rectangles = self:getActivityRectangles(self:getDailyTotals(sessions))
end

local function emptyDayStats(date_string)
	return { date = date_string, sessionTime = 0, timePlayed = 0,
		chartsPlayed = 0, keysPressed = 0, rageQuits = 0,
		modes = {}
	}
end

---@param sessions ProfileSession[]
---@return {[string]: DayStats}
function Activity:getDailyTotals(sessions)
	---@type {[string]: DayStats}
	local totals = {}

	for _, session in ipairs(sessions) do
		local start_date = os.date("*t", session.startTime)
		if start_date.year == self.year then
			local date_string = tostring(os.date("%d-%m-%Y", session.startTime))
			if not totals[date_string] then
				totals[date_string] = emptyDayStats(date_string)
			end

			local t = totals[date_string]
			t.sessionTime = t.sessionTime + ((session.endTime or os.time()) - session.startTime) / 60
			t.timePlayed = t.timePlayed + session.timePlayed / 60
			t.chartsPlayed = t.chartsPlayed + session.chartsPlayed
			t.keysPressed = t.keysPressed + session.keysPressed
			t.rageQuits = t.rageQuits + session.rageQuits
		end
	end

	self.maxSessionTime = 0
	self.avgSessionTime = 0
	self.sessionCount = 0
	local total_session_time = 0.0

	for k, v in pairs(totals) do
		self.maxSessionTime = math.max(self.maxSessionTime, v.sessionTime)
		self.sessionCount = self.sessionCount + 1
		total_session_time = total_session_time + v.sessionTime
	end

	self.maxSessionTime = self.maxSessionTime

	if self.sessionCount > 1 then
		self.avgSessionTime = (total_session_time / (self.sessionCount))
	else
			self.avgSessionTime = 0
	end

	return totals
end

---@param minutes number 
function Activity:getAlphaPercent(minutes)
	return math.min(1, minutes / 90)
end

local weeks_in_year = 53
local days_in_week = 7

---@param day_stats {[string]: DayStats}
---@return ActivityRectangle[]
function Activity:getActivityRectangles(day_stats)
	---@type ActivityRectangle[]
	local rectangles = {}

	for week = 0, weeks_in_year - 1 do
		for day = 0, days_in_week - 1 do
			local date = os.time({ year = self.year, month = 1, day = 1 }) + (week * 7 + day) * 86400
			local date_string = os.date("%d-%m-%Y", date)

			if os.date("%Y", date) == tostring(self.year) then
				local stats = day_stats[date_string] or emptyDayStats(date_string)
				table.insert(rectangles, {
					stats = stats,
					alphaColor = self:getAlphaPercent(stats.sessionTime),
					week = week,
					day = day,
				})
			end
		end
	end

	return rectangles
end

return Activity
