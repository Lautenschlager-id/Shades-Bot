local f = string.format

local tools = require("../tools")

local meta = {
	xx = {
		default = {
			MINIMUM_MESSAGES_TO_CHECK = 4,
			MINIMUM_LONG_MESSAGE_IN_CHARACTERS = 100,
			WHITELIST_TIME = 5
		},

		karma = {
			MINIMUM_MESSAGES_TO_CHECK = 4,
			MINIMUM_LONG_MESSAGE_IN_CHARACTERS = 60,
			WHITELIST_TIME = 5
		},
	}
}

local areLastMessagesTooLong = function(parameters)
	p(f("[RP] Executing rule AF004 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]
	local ruleMeta = meta[parameters.playerCommunity] or meta.xx
	ruleMeta = ruleMeta[parameters.channelName] or ruleMeta.default

	local totalStoredMessages = #playerMeta
	if totalStoredMessages < ruleMeta.MINIMUM_MESSAGES_TO_CHECK then
		return false
	end

	local tmpMessage
	for m = totalStoredMessages - (ruleMeta.MINIMUM_MESSAGES_TO_CHECK - 1), totalStoredMessages do
		tmpMessage = playerMeta[m].message
		if #tmpMessage < ruleMeta.MINIMUM_LONG_MESSAGE_IN_CHARACTERS then
			p(f("[AF004] The message %q is NOT long!", tmpMessage))
			return false
		end
		p(f("[AF004] The message %q is long!", tmpMessage))
	end

	p("[AF004] Big messages found. Suspect!")
	tools.reportSuspect(parameters, playerMeta, ruleMeta.MINIMUM_MESSAGES_TO_CHECK,
		f("[AF004 - 🌪️ Spam] [%s-#%s] Suspect spam.", parameters.playerCommunity,
			parameters.channelName))

	tools.whiteListSuspectPlayer(playerMeta, ruleMeta.WHITELIST_TIME, parameters.playerName)

	return true
end

return {
	name = "AF004",
	description = "Checks whether the last messages received from the player are too long.",
	execute = areLastMessagesTooLong,
	expect = false
}