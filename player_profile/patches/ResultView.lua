local ResultView = require("ui.views.ResultView")
local Layout = require("ui.views.ResultView.Layout")
local getPP = require("player_profile.osu_pp")

local gfx_util = require("gfx_util")

function ResultView:calcPP()
	local score_systems = self.game.rhythmModel.scoreEngine.scoreSystem
	local chartview = self.game.selectModel.chartview

	if not score_systems.judgements then
		self.pp = -1
		return
	end

	local judge = score_systems.judgements["osu!legacy OD9"]
	local rate = self.game.playContext.rate
	self.pp = getPP(judge.notes, chartview.osu_diff * rate, 9, judge.score)
end

local base_draw = ResultView.draw

function ResultView:draw()
	base_draw(self)

	local w, h = Layout:move("column3row1")

	love.graphics.setColor(1, 1, 1)
	self:calcPP()
	gfx_util.printFrame(("osu! OD9 PP: %i"):format(self.pp), 0, 0, w, h, "center", "center")
end
