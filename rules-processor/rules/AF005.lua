local f = string.format

local tools = require("../tools")

local meta = {
	xx = {
		MAXIMUM_CHARACTERS_WITH_MORE_THAN_3_BYTES = 20,
		WHITELIST_TIME = 10
	}
}

local wouldLastMessageBreakClient = function(parameters)
	p(f("[RP] Executing rule AF005 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]
	local ruleMeta = meta[parameters.playerCommunity] or meta.xx

	local lastMessage = playerMeta[#playerMeta].message
	lastMessage = string.utf8(lastMessage)

	local totalCharactersWithMoreThan3Bytes = 0
	for c = 1, #lastMessage do
		if #lastMessage[c] == 3 then
			totalCharactersWithMoreThan3Bytes = totalCharactersWithMoreThan3Bytes + 1
		end
	end

	if totalCharactersWithMoreThan3Bytes <= ruleMeta.MAXIMUM_CHARACTERS_WITH_MORE_THAN_3_BYTES then
		p(f("[AF005] Message only has %s characters.", totalCharactersWithMoreThan3Bytes))
		return false
	end

	p(f("[AF005] Message with %s characters with 3 bytes found. Suspect!",
		totalCharactersWithMoreThan3Bytes))
	tools.reportSuspect(parameters, playerMeta, 1,
		f("[AF005 - ⛓️ Breaking Characters] [%s-#%s] Suspect message with breaking characters.",
			parameters.playerCommunity, parameters.channelName))

	tools.whiteListSuspectPlayer(playerMeta, ruleMeta.WHITELIST_TIME, parameters.playerName)

	return true
end

return {
	name = "AF005",
	description = "Checks whether the last messages received from the player are too long.",
	execute = wouldLastMessageBreakClient,
	expect = false
}