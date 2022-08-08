local f = string.format

local settingchannel = require("../data/settingChannel")
p(tostring(settingchannel))

local reportSuspect = function(parameters, playerMeta, totalDisplayMessages, title)
	local totalPlayerMessages = #playerMeta

	local msgs, tmpMsg = { }
	for m = totalPlayerMessages - (totalDisplayMessages - 1), totalPlayerMessages do
		tmpMsg = playerMeta[m]

		msgs[#msgs + 1] = f("``%s [%s] [%s] %s``", tmpMsg.time, parameters.playerCommunity,
			parameters.playerName, tmpMsg.message)
	end

	msgs = table.concat(msgs, '\n')

	settingchannel.bridgeVon:send({
		content = f("%s,%s,false", parameters.channelName, parameters.playerCommunity),
		embed = {
			title = title,
			description = msgs,
			color = 0xC95F5F
		}
	})
end

local reportSuspectURLs
do
	local displayEmbedForDomains = {
		"imgur.com/",
		"prnt.sc/",
		"youtube.com/",
		"youtu.be/",
		"cdn.discordapp.com/"
	}
	local totalEmbeddableDomains = #displayEmbedForDomains

	reportSuspectURLs = function(parameters, playerMeta, totalDisplayMessages)
		local totalPlayerMessages = #playerMeta

		local msgs = { }
		for m = totalPlayerMessages - (totalDisplayMessages - 1), totalPlayerMessages do
			msgs[#msgs + 1] = playerMeta[m].message
		end
		msgs = table.concat(msgs, '\n')

		local urls, shouldEmbedURL = { }
		for url in string.gmatch(msgs, "https?://%S+") do
			shouldEmbedURL = false

			for d = 1, totalEmbeddableDomains do
				if string.find(url, displayEmbedForDomains[d], 1, true) then
					shouldEmbedURL = true
					break
				end
			end

			if shouldEmbedURL then
				url = "|| " .. url .. " ||"
			else
				url = "<" .. url .. ">"
			end

			urls[#urls + 1] = url
		end

		if #urls == 0 then
			return false
		end

		urls = table.concat(urls, '\n')

		settingchannel.bridgeVon:send({
			content = f("%s,%s,true", parameters.channelName, parameters.playerCommunity),
			embed = {
				description = "⚠️ **The following links might risk your safety.**\n\n" .. urls,
			}
		})
	end
end

local whiteListSuspectPlayer = function(playerMeta, time, playerName)
	p(f("[RP] %s whitelisted for %s minutes.", playerName, time))
	playerMeta.lastMessageTime = playerMeta.lastMessageTime + (time * 60)
end

return {
	reportSuspect = reportSuspect,
	reportSuspectURLs = reportSuspectURLs,
	whiteListSuspectPlayer = whiteListSuspectPlayer
}