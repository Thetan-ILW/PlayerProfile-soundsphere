local SelectView = require("ui.views.SelectView")
local Layout = require("ui.views.SelectView.Layout")
local gfx_util = require("gfx_util")
local imgui = require("imgui")
local spherefonts = require("sphere.assets.fonts")

local base_draw = SelectView.draw

local pp_mode = "pp"

function SelectView:draw()
	base_draw(self)

	local w, h = Layout:move("footer")
	local font = spherefonts.get("Noto Sans", 20)
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(font)

	local profile = self.game.playerProfileModel

	local chartview = self.game.selectModel.chartview
	local regular, ln = "-", "-"

	if chartview then
		regular, ln = profile:getDanClears(chartview.chartdiff_inputmode)
	end

	local label = ("RG dan: %s | LN dan: %s"):format(regular, ln)
	gfx_util.printFrame(label, 0, 0, w, h, "center", "center")

	w, h = Layout:move("column1", "header")

	local pp_str

	if pp_mode == "pp" then
		pp_str = ("%ipp"):format(profile.pp)
	elseif pp_mode == "msd" then
		pp_str = ("%0.02f MSD"):format(profile.ssr)
	elseif pp_mode == "live_msd" then
		pp_str = ("%0.02f Live MSD"):format(profile.liveSsr)
	end

	love.graphics.translate(w / 2 - font:getWidth(pp_str) / 2, 0)
	if imgui.TextOnlyButton("pp", pp_str, font:getWidth(pp_str), h) then
		if pp_mode == "pp" then
			pp_mode = "msd"
		elseif pp_mode == "msd" then
			pp_mode = "live_msd"
		elseif pp_mode == "live_msd" then
			pp_mode = "pp"
		end
	end
end
