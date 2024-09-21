local GameplayController = require("sphere.controllers.GameplayController")

local base_save_score = GameplayController.saveScore

function GameplayController:saveScore()
	base_save_score(self)

	local score_system = self.rhythmModel.scoreEngine.scoreSystem
	local osu = score_system.judgements["osu!legacy OD9"]

	if self.playContext.scoreEntry.pauses > 0 then
		return
	end

	if osu.accuracy < 0.85 then
		return
	end

	local chartdiff = self.playContext.chartdiff
	local key = ("%s_%s"):format(chartdiff.hash, chartdiff.inputmode)
	local chart = self.rhythmModel.chart

	self.playerProfileModel:addScore(key, chart, chartdiff, score_system)
end
