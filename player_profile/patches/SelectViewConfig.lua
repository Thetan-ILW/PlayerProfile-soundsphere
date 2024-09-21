local just = require("just")
local spherefonts = require("sphere.assets.fonts")
local icons = require("sphere.assets.icons")
local time_util = require("time_util")
local loop = require("loop")
local imgui = require("imgui")

local UserInfoView = require("ui.views.UserInfoView")
local LogoImView = require("ui.imviews.LogoImView")

local Layout = require("ui.views.SelectView.Layout")

---@param w number
---@param h number
---@param _r number?
local function drawFrameRect(w, h, _r)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(0, 0, 0, 0.8)
	love.graphics.rectangle("fill", 0, 0, w, h, _r or 36)
	love.graphics.setColor(r, g, b, a)
end

---@param self table
local function Frames(self)
	local w, h = Layout:move("base", "header")
	drawFrameRect(w, h, 0)

	local w, h = Layout:move("base", "footer")
	drawFrameRect(w, h, 0)
end

local pp_mode = "pp"

---@param self table
local function Header(self)
	local w, h = Layout:move("column1", "header")

	local username = self.game.configModel.configs.online.user.name or "Not logged in"
	local session = self.game.configModel.configs.online.session
	just.row(true)
	if UserInfoView:draw(w, h, username, not not (session and next(session))) then
		self.gameView:setModal(require("ui.views.OnlineView"))
	end
	just.offset(0)

	LogoImView("logo", h, 0.5)
	if imgui.IconOnlyButton("quit game", icons("clear"), h, 0.5) then
		love.event.quit()
	end
	just.row()

	local w, h = Layout:move("column2", "header")

	local profile = self.game.playerProfileModel
	local pp_str

	if profile.error then
		pp_str = profile.error
	else
		if pp_mode == "pp" then
			pp_str = ("%ipp"):format(profile.pp)
		elseif pp_mode == "msd" then
			pp_str = ("%0.02f MSD"):format(profile.ssr.overall)
		elseif pp_mode == "live_msd" then
			pp_str = ("%0.02f Live MSD"):format(profile.liveSsr.overall)
		end
	end

	local font = spherefonts.get("Noto Sans", 20)
	love.graphics.setFont(font)

	just.indent(15)
	if imgui.TextOnlyButton("pp", pp_str, font:getWidth(pp_str), h) then
		if pp_mode == "pp" then
			pp_mode = "msd"
		elseif pp_mode == "msd" then
			pp_mode = "live_msd"
		elseif pp_mode == "live_msd" then
			pp_mode = "pp"
		end
	end
	just.sameline()

	just.indent(30)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.circle("fill", 0, 44, 8)
	love.graphics.circle("line", 0, 44, 8)
	just.indent(30)
	imgui.Label("SessionTime", time_util.format(loop.time - loop.startTime), h)
end

package.preload["ui.views.SelectView.SelectViewConfig"] = function()
	return function(self)
		Frames(self)
		Header(self)
	end
end
