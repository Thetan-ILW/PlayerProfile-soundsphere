local SelectView = require("ui.views.SelectView")
local Layout = require("ui.views.SelectView.Layout")
local gfx_util = require("gfx_util")

local base_draw = SelectView.draw

function SelectView:draw()
	base_draw(self)

	local w, h = Layout:move("footer")
	love.graphics.setColor(1, 1, 1)

	local profile = self.game.playerProfileModel

	local chartview = self.game.selectModel.chartview
	local regular, ln = "-", "-"

	if chartview then
		regular, ln = profile:getDanClears(chartview.chartdiff_inputmode)
	end

	local label = ("Regular dan: %s | LN dan: %s"):format(regular, ln)
	gfx_util.printFrame(label, 0, 0, w, h, "center", "center")
end
