local GameController = require("sphere.controllers.GameController")

local PlayerProfileModel = require("player_profile")

local base_new = GameController.new

function GameController:new()
	base_new(self)
	self.playerProfileModel = PlayerProfileModel(self)
	self.gameplayController.playerProfileModel = self.playerProfileModel
end
