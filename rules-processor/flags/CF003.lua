local f = string.format

local meta = {
	xx = {
		SECONDS_BEFORE_RESET = 10
	}
}

local isLastMessageOld = function(parameters)
	p(f("[RP] Executing flag CF003 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local _playerMeta = parameters.policyMeta[parameters.channelName]

	local playerMeta = _playerMeta[parameters.playerName]
	local ruleMeta = meta[parameters.playerCommunity] or meta.xx

	local remainingWhiteLisTime = parameters.time - playerMeta.lastMessageTime

	if remainingWhiteLisTime >= ruleMeta.SECONDS_BEFORE_RESET then
		_playerMeta[parameters.playerName] = {

		}
	end
	_playerMeta[parameters.playerName].lastMessageTime = parameters.time
end

return {
	name = "CF003",
	description = "Checks whether the last message is too old, and if so resets the player meta table",
	execute = isLastMessageOld
}