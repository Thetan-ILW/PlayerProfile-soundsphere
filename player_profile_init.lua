if not arg then -- not in a thread we need to be
	return
end

local PlayerProfileModel = require("player_profile")
local UserInterfaceModel = require("sphere.models.UserInterfaceModel")
local base_load = UserInterfaceModel.load

function UserInterfaceModel:load()
	local model = PlayerProfileModel(self.game.notificationModel)
	self.game.playerProfileModel = model
	self.game.gameplayController.playerProfileModel = model
	require("player_profile.patches")
	base_load(self)
end
