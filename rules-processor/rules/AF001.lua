local f = string.format

local boundChannels = {
	xx = {
		["karma"] = true,
		["event"] = true
	},

	br = {
		["karma"] = true,
		["event"] = true,
		["evento"] = true,
		["br"] = true,
		["pt"] = true
	}
}

local isBoundChannel = function(parameters)
	p(f("[RP] Executing rule AF001 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local communityChannels = boundChannels[parameters.playerCommunity] or boundChannels.xx
	return communityChannels[parameters.channelName]
end

return {
	name = "AF001",
	description = "Checks whether the channel in which the message was received is bound to execute the next rules",
	execute = isBoundChannel,
	expect = true
}