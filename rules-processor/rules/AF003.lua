local f = string.format

local tools = require("../tools")

local meta = {
	xx = {
		MINIMUM_MESSAGES_TO_CHECK = 4,
		WHITELIST_TIME = 5
	}
}

local areLastMessagesSimilar = function(parameters)
	p(f("[RP] Executing rule AF003 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]
	local ruleMeta = meta[parameters.playerCommunity] or meta.xx

	local totalStoredMessages = #playerMeta
	if totalStoredMessages < ruleMeta.MINIMUM_MESSAGES_TO_CHECK then
		return false
	end

	local sourceMessage, messageForComparison =
		playerMeta[totalStoredMessages - (ruleMeta.MINIMUM_MESSAGES_TO_CHECK - 1)].message
	p(f("[AF003] The following message will be used as source: %q", sourceMessage))
	for m = totalStoredMessages - (ruleMeta.MINIMUM_MESSAGES_TO_CHECK - 2), totalStoredMessages do
		messageForComparison = playerMeta[m].message
		if not string.isSimilar(sourceMessage, messageForComparison) then
			p(f("[AF003] The message %q is NOT similar!", messageForComparison))
			return false
		end
		p(f("[AF003] The message %q is similar!", messageForComparison))
	end

	p("[AF003] Similar messages found. Suspect!")
	tools.reportSuspect(parameters, playerMeta, ruleMeta.MINIMUM_MESSAGES_TO_CHECK,
		f("[AF003 - 🌊 Flood] [%s-#%s] Suspect flood.", parameters.playerCommunity,
			parameters.channelName))

	tools.whiteListSuspectPlayer(playerMeta, ruleMeta.WHITELIST_TIME, parameters.playerName)

	return true
end

return {
	name = "AF003",
	description = "Checks whether the last messages received from the player are too similar.",
	execute = areLastMessagesSimilar,
	expect = false
}