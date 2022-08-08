local f = string.format

local upsertPlayerMeta = function(parameters)
	p(f("[RP] Executing flag CF002 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	if not parameters.policyMeta[parameters.channelName][parameters.playerName] then

		parameters.policyMeta[parameters.channelName][parameters.playerName] = {
			lastMessageTime = parameters.time
		}
	end
end

return {
	name = "CF002",
	description = "Checks if the policy meta of the player who sent the received message in the channel exists, and creates one if not.",
	execute = upsertPlayerMeta
}