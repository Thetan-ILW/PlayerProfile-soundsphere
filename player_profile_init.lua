if not arg then -- not in a thread we need to be
	return
end

local UserInterfaceModel = require("sphere.models.UserInterfaceModel")
local base_load = UserInterfaceModel.load

function UserInterfaceModel:load()
	local model = require("player_profile")(self.game)
	self.game.playerProfileModel = model
	self.game.gameplayController.playerProfileModel = model
	require("player_profile.patches")
	base_load(self)
end
