local f = string.format

local tools = require("../tools")

local metaForPlayer = { }

local meta = {
	xx = {
		WHITELIST_TIME = 10
	}
}

local hasLink = function(parameters)
	p(f("[RP] Executing flag CF005 for [%s-%s] at #%s",
		parameters.playerCommunity, parameters.playerName, parameters.channelName))

	local thisPlayerMeta = metaForPlayer[parameters.channelName]
	if not thisPlayerMeta then
		metaForPlayer[parameters.channelName] = { }
		thisPlayerMeta = metaForPlayer[parameters.channelName]
	end

	if not thisPlayerMeta[parameters.playerName] then
		thisPlayerMeta[parameters.playerName] = {
			lastMessageTime = 0
		}
	end
	thisPlayerMeta = thisPlayerMeta[parameters.playerName]

	if parameters.time - thisPlayerMeta.lastMessageTime < 0 then
		return false
	end

	local messageLink = string.match(parameters.message, "https?://%S+")
	if not messageLink then
		return false
	end

	thisPlayerMeta.lastMessageTime = parameters.time

	local playerMeta = parameters.policyMeta[parameters.channelName][parameters.playerName]

	p(f("[CF005] Found link %q in the message. Suspect!", messageLink))
	tools.reportSuspectURLs(parameters, playerMeta, 1)
	tools.reportSuspect(parameters, playerMeta, 1,
		f("[CF005 - 🔗 Link] [%s-#%s] Suspect message containing an URL.",
			parameters.playerCommunity, parameters.channelName))

	local ruleMeta = meta[parameters.playerCommunity] or meta.xx
	tools.whiteListSuspectPlayer(thisPlayerMeta, ruleMeta.WHITELIST_TIME, parameters.playerName)
end

return {
	name = "CF005",
	description = "Checks if the received message contains a link.",
	execute = hasLink
}