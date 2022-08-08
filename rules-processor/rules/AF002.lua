local f = string.format

local isWhiteListed = function(parameters)
	p(f("[RP] Executing rule AF002 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]

	local remainingWhiteLisTime = parameters.time - playerMeta.lastMessageTime

	return remainingWhiteLisTime < 0
end

return {
	name = "AF002",
	description = "Checks whether player is still whitelisted in that channel.",
	execute = isWhiteListed,
	expect = false
}