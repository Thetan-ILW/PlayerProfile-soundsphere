local class = require("class")

---@class SsrTable
---@operator call: SsrTable
local SsrTable = class()

SsrTable.patterns = { "stream", "jumpstream", "handstream", "stamina", "jackspeed", "chordjack", "technical" }

---@param scores {[string]: ProfileTopScore}
---@param mode string
function SsrTable:new(scores, mode)
	self.scores = scores
	self.mode = mode
	self:calculate()
end

local function sortfunc(a, b)
	return a > b
end

function SsrTable:calculate()
	local ssr_sorted = {} ---@type {[string]: number[]}

	for _, pattern in ipairs(self.patterns) do
		ssr_sorted[pattern] = {}
	end

	for _, score in pairs(self.scores) do
		if score.overall and score.mode == self.mode then
			for _, pattern in ipairs(self.patterns) do
				table.insert(ssr_sorted[pattern], score[pattern])
			end
		end
	end

	for _, pattern in ipairs(self.patterns) do
		table.sort(ssr_sorted[pattern], sortfunc)
	end

	local avg_count = 20
	local ssr_sum = {} ---@type {[string]: number}
	local ssr = {} ---@type {[string]: number}

	for pattern, values in pairs(ssr_sorted) do
		ssr_sum[pattern] = 0
		for i, v in ipairs(values) do
			if i > avg_count then
				break
			end
			ssr_sum[pattern] = ssr_sum[pattern] + v
		end
		ssr[pattern] = ssr_sum[pattern] / avg_count
	end

	self.ssr = ssr
end

return SsrTable
