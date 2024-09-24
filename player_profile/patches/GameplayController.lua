local GameplayController = require("sphere.controllers.GameplayController")

local base_save_score = GameplayController.saveScore

function GameplayController:saveScore()
	base_save_score(self)

	local score_system = self.rhythmModel.scoreEngine.scoreSystem
	local chartdiff = self.playContext.chartdiff
	local chartview = self.selectModel.chartview
	local key = ("%s_%s"):format(chartdiff.hash, chartdiff.inputmode)
	local chart = self.rhythmModel.chart
	self.playerProfileModel:addScore(key, chart, chartdiff, chartview, score_system, self.playContext)
end
