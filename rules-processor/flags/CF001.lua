local f = string.format

local upsertChannelMeta = function(parameters)
	p(f("[RP] Executing flag CF001 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	if not parameters.policyMeta[parameters.channelName] then
		parameters.policyMeta[parameters.channelName] = { }
	end
end

return {
	name = "CF001",
	description = "Checks if the channel has a policy meta for the player who sent the received message, and creates one if not.",
	execute = upsertChannelMeta
}