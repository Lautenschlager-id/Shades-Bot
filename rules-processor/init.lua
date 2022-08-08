local f = string.format

local rules = {
	AF001 = require("./rules/AF001"),
	AF002 = require("./rules/AF002"),
	AF003 = require("./rules/AF003"),
	AF004 = require("./rules/AF004"),
	AF005 = require("./rules/AF005")
}

local flags = {
	CF001 = require("./flags/CF001"),
	CF002 = require("./flags/CF002"),
	CF003 = require("./flags/CF003"),
	CF004 = require("./flags/CF004"),
	CF005 = require("./flags/CF005"),
}

local policy = {
	xx = {
		default = {
			--[[ Group: setup ]]--
			rules.AF001, -- isBoundChannel
			flags.CF001, -- upsertChannelMeta
			flags.CF002, -- upsertPlayerMeta
			rules.AF002, -- isPlayerWhiteListed
			flags.CF003, -- isLastMessageOld
			flags.CF004, -- insertMessage

			--[[ Group: anti-spam ]]--
			rules.AF003, -- areLastMessagesSimilar
			rules.AF004, -- areLastMessagesTooLong
			rules.AF005, -- wouldLastMessageBreakClient
		},
		karma = {
			--[[ Group: setup ]]--
			rules.AF001, -- isBoundChannel
			flags.CF001, -- upsertChannelMeta
			flags.CF002, -- upsertPlayerMeta
			rules.AF002, -- isPlayerWhiteListed
			flags.CF003, -- isLastMessageOld
			flags.CF004, -- insertMessage

			--[[ Group: anti-spam ]]--
			rules.AF003, -- areLastMessagesSimilar
			rules.AF004, -- areLastMessagesTooLong
			rules.AF005, -- wouldLastMessageBreakClient

			--[[ Group: anti-phishing ]]--
			flags.CF005, -- hasLink
		},
	},
}

local meta = { }

local execute = function(channelName, playerCommunity, playerName, message, currentTime)
	local communityPolicy = policy[playerCommunity] or policy.xx
	local channelPolicy = communityPolicy[channelName] or communityPolicy.default

	local parameters = {
		policyMeta = meta,

		playerCommunity = playerCommunity,
		playerName = playerName,

		channelName = channelName,
		message = message,
		messageTime = currentTime,

		time = os.time()
	}

	local ruleOrFlag
	for e = 1, #channelPolicy do
		ruleOrFlag = channelPolicy[e]

		local result = ruleOrFlag.execute(parameters)
		if ruleOrFlag.expect ~= nil then
			if result ~= ruleOrFlag.expect then
				p(f("[RP] Breaking process at %q for [%s-%s] at #%s. Got %q, expected %q.",
					ruleOrFlag.name, parameters.playerCommunity, parameters.playerName,
					parameters.channelName, result, ruleOrFlag.expect))
				return
			end
		end
	end
end

return execute