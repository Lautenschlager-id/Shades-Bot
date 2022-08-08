local f = string.format

local insertMessage = function(parameters)
	p(f("[RP] Executing flag CF004 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]

	playerMeta[#playerMeta + 1] = {
		message = parameters.message,
		time = parameters.messageTime
	}
end

return {
	name = "CF004",
	description = "Inserts the received message the player meta table.",
	execute = insertMessage
}