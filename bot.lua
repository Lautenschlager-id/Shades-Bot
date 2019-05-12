-- Consts
local CHAR_LIM = 255
local CHAT_MSG_LIM = 2
local WHISPER_MSG_LIM = 3
local ANTI_SPAM_TIME = 8
local DATA = { }
do
	local counter, account = 0, io.open("acc", 'r')
	repeat
		counter = counter + 1
		DATA[counter] = account:read("*l")
	until not DATA[counter]
	account:close()
end

-- Deps
local timer = require("timer")
local http = require("coro-http")
local json = require("json")

-- Libs
local discordia = require("discordia")
local transfromage = require("transfromage")

-- Init
discordia.extensions()
local disc = discordia.Client()
disc._options.routeDelay = 0
local tfm = transfromage.client:new()

-- Data
local object = { }
local channel = transfromage.enum._enum({
	-- Message
	help = "544935946290987009",
	lua = "544936074237968434",
	mapcrew = "565716126814830612",
	shadestest = "546429085451288577",
	whisper = "547882749348806673"
})
local settingchannel = {
	discussion = "544935729508253717",
	memberList = "544936174544748587"
}
local categoryId = "544935544975786014"

local helper = { }
local isConnected = false
local isWorking = false
local lastServerPing, lastUserReply, lastUserWhispered
local title = { }

local dressroom = { }
local onlinePlayers = { }
local modList, mapcrewList = { }, { }
local timeCmd = { }
local modulesCmd = { }
local xml = { queue = { } }
local userCache = { }
local profile = { }

-- Functions
do
	local err = error
	error = function(msg, lvl)
		return coroutine.wrap(function(msg, lvl)
			if isWorking then
				disc:getChannel('546429085451288577'):send("<@" .. disc.owner.id .. ">, disconnected.\n```\n" .. msg .. "```")
			end
			return err(msg, lvl)
		end)(msg, lvl)
	end
end
local protect = function(f)
	return function(...)
		return coroutine.wrap(function(...)
			local success, err = pcall(f, ...)
			if not success then
				object.shadestest:send({
					content = "<@" .. disc.owner.id .. ">",
					embed = {
						color = 0xFFAA00,
						title = "Error",
						description = "```\n" .. err .. "```",
						fields = {
							[1] = {
								name = "Traceback",
								value = "```\n" .. debug.traceback() .. "```",
								inline = false
							}
						},
						timestamp = discordia.Date():toISO()
					}
				})
			end
		end)(...)
	end
end

local setHelper, remHelper
do
	local parse = function(line)
		local id, nick, tag = string.match(line, "^<@!?(%d+)> += +([^#]+)(#?%d*)")
		tag = (tag == '' and "#0000" or tag)

		return id, nick, tag
	end

	setHelper = function(line)
		local id, nick, tag = parse(line)

		helper[nick] = id
		if tag ~= "#0000" then
			nick = nick .. tag
		end
		helper[id] = nick
		helper[nick] = id
	end

	remHelper = function(line)
		local id, nick, tag = parse(line)

		helper[id] = nil
		helper[nick] = nil
		helper[nick .. tag] = nil
	end
end

local removeSpaces = function(str)
	str = string.trim(tostring(str))
	str = string.gsub(str, " +", ' ')
	return str
end

local formatReceiveText = function(str)
	str = string.gsub(tostring(str), '`', '\'')

	str = string.gsub(str, "%S+", function(word)
		if #word > 1 then
			local value
			if string.sub(word, 1, 1) == '@' then
				value = string.match(string.sub(word, 2), "(.-)%p*$")
				value = string.toNickname(value)
				if helper[value] then
					return "<@" .. (tonumber(helper[value]) and helper[value] or value) .. ">"
				else
					value = string.lower(value)
					value = settingchannel.discussion.members:find(function(member)
						return string.lower(member.name) == value or string.lower(member.username) == value or (member.nickname and string.lower(member.nickname) == value) or string.lower(member.fullname) == value
					end)
					if value then
						return "<@" .. value.id .. ">"
					end
				end
			else
				value = string.match(word, "<@%d+>")
				if value then
					return value
				end
				value = string.match(word, "^https?://[%w]+%..+")
				if value then
					--if http.request("GET", value) then
						return value
					--end
				end
			end
		end
		return "`" .. word .. "`"
	end)

	return str
end

local formatSendText = function(str)
	str = string.gsub(tostring(str), "<(.)!?(%d+)>", function(t, id)
		if t == '#' then
			local channel = disc:getChannel(id)
			if channel then
				return "#" .. channel.name
			else
				return "#deleted-channel"
			end
		elseif t == '@' then
			if helper[id] then
				return "@" .. helper[id]
			else
				local user = disc:getUser(id)
				if user then
					return "@" .. tostring(user.fullname) 
				end
			end
			return "@invalid-user"
		end
	end)
	str = string.gsub(str, "<(:.-:)%d+>", "%1")

	return str
end

local formatServerText = function(str)
	local title, data = string.match(str, "(.-: )(.*)")
	if not title then
		return str
	end

	if data then
		data = string.gsub(data, "#%d+", "`%1`")
	end
	return "**" .. title .. "**\n" .. data
end

string.trim = function(str)
	return (string.gsub(tostring(str), "^ *(.*) *$", "%1"))
end

table.map = function(list, f)
	local newList, counter = { }, 0
	for k, v in next, list do
		counter = counter + 1
		newList[counter] = f(v, k)
	end
	return newList
end

table.keys = function(list, f)
	local out, counter = { }, 0
	for k, v in next, list do
		if not f or f(k, v) then
			counter = counter + 1
			out[counter] = k
		end
	end
	return out
end

local splitMsgByWord
do
	local lastSpaceIndex = function(str)
		if not string.find(str, ' ') then return end
		local f = string.find(string.reverse(str), ' ')
		return (f and (#str - (f - 1)))
	end

	splitMsgByWord = function(user, msg, maxMsgs)
		user = (user and ("[" .. user .. "] ") or '')

		local maxLen = CHAR_LIM - #user
		local messages = { }
		msg = removeSpaces(msg)

		local msgLen = #msg

		local limMsg, lastSpace, j

		local i = 0
		while msgLen > maxLen and i < maxMsgs do
			i = i + 1
			if i > 1 then
				msg = string.trim(msg)
			end

			limMsg = string.sub(msg, 1, maxLen)
			lastSpace = lastSpaceIndex(limMsg)

			if not lastSpace then
				messages[i] = user .. limMsg
				j = maxLen + 1
			else
				messages[i] = user .. string.sub(msg, 1, lastSpace - 1)
				j = lastSpace + 1
			end

			msg = string.sub(msg, j)
			msgLen = #msg
		end

		msg = string.trim(msg)
		msgLen = #msg

		if msgLen > 0 and i < maxMsgs then
			i = i + 1
			messages[i] = user .. msg
			return messages
		end
		return messages, (msgLen > 0 and msg or nil)
	end
end

local encodeUrl = function(url)
	local out, counter = {}, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end

local srcMemberListCmd = {}
local createListCommand = function(code)
	local name = string.gsub(code, "[%s_](%l)", string.upper)
	local src = {
		_loading = '',
		_timer = 0,
		_onlineMembers = '',
		_queue = { }
	}
	srcMemberListCmd[name] = src

	return function(isDebugging, playerName, param)
		local isServerCmd = type(isDebugging) == "table"

		local request = false
		if src._loading == '' then
			if src._timer > os.time() then
				if isServerCmd then
					return isDebugging:reply(formatServerText(src._onlineMembers))
				else
					return src._onlineMembers
				end
			else
				request = true
			end
		end

		if isServerCmd then
			param = playerName
			playerName = nil
		end
		src._queue[#src._queue + 1] = { playerName = playerName, isDebugging = isDebugging, param = param, isServerCmd = isServerCmd }

		if request then
			tfm:sendRoomMessage(name .. " get_team" .. code)
		end
	end
end

local getCommunityCode = function(playerCommunity)
	local commu = transfromage.enum.chatCommunity(playerCommunity)
	return (commu ~= "az" and commu ~= "ch" and commu ~= "sk") and commu or "int"
end

-- Command Functions
do
	local sendWhisper = tfm.sendWhisper
	tfm.sendWhisper = function(self, playerName, message)
		lastUserWhispered = playerName
		return sendWhisper(self, playerName, message)
	end
end

local dressroomLink
do
	local getLook = function(look)
		local fur, items = string.match(look, "(%d+)(.+)")

		local out = { tonumber(fur) }

		local counter, colorCounter = 1, 0
		for item, colors in string.gmatch(items, "[;,](%d+)([_+%x]*)") do
			local tmp = { id = tonumber(item), colors = { } }

			colorCounter = 0
			for c in string.gmatch(colors, "[_+](%x+)") do
				colorCounter = colorCounter + 1
				tmp.colors[colorCounter] = c
			end
			counter = counter + 1
			out[counter] = tmp
		end

		return out
	end

	local dressRoomTags = { 's', 'h', 'y', 'e', 'm', 'n', 'd', 't', 'c', "hd" }
	dressroomLink = function(look)
		look = getLook(look)
		local url = "https://projects.fewfre.com/a801/transformice/dressroom/?"

		local data, uri = {
			{ dressRoomTags[1], look[1] }
		}, { }
		for i = 2, #dressRoomTags do
			data[i] = { dressRoomTags[i], look[i].id, look[i].colors }
		end

		local counter, colors = 0
		for i = 1, #data do
			if data[i][2] > 0 then
				if data[i][3] and #data[i][3] > 0 then
					colors = ";" .. table.concat(data[i][3], ';')
				else
					colors = ''
				end
				counter = counter + 1
				uri[counter] = data[i][1] .. "=" .. data[i][2] .. colors
			end
		end
		url = url .. table.concat(uri, '&')

		return url
	end
end

local secToDate = function(s)
	local m = (s / 60) % 60
	local h = (s / 3600) % 24
	local d = s / 86400
	s = s % 60

	return string.format("%02dd%02dh%02dm%02ds", d, h, m, s)
end

local remDefaultDiscriminator = function(playerName)
	return string.gsub(playerName, "#0000", '', 1)
end

local loadXmlQueue
do
	local failEmbed = {
		color = 0x36393F,
		title = "Fail"
	}
	local fail = function(mapCode)
		failEmbed.description = "Map **" .. mapCode .. "** doesn't exist or can't be loaded."
		xml[mapCode].message:reply({
			content = "<@" .. xml[mapCode].message.author.id .. ">",
			embed = failEmbed
		})

		if xml[mapCode].reply then
			xml[mapCode].reply:delete()
		end

		table.remove(xml.queue, 1)
		xml[mapCode] = nil

		loadXmlQueue()
	end

	loadXmlQueue = function()
		if #xml.queue > 0 then
			xml[xml.queue[1]].timer = timer.setTimeout(1500, coroutine.wrap(fail), xml.queue[1])

			tfm:sendCommand("np " .. xml.queue[1])
		end
	end
end

local mapCategories = {
	default = { "<:ground:506477349966053386>", 0x90B214 },
	[0] = { "<:p0:563096585982967808>", 0xE0DBCC, "Normal" },
	[1] = { "<:p1:563096585257615360>", 0xECB140, "Protected" },
	[3] = { "<:bootcamp:512017071031451654>", 0x575F24, "Bootcamp" },
	[4] = { "<:shaman:512015935989612544>", 0x94D8D5, "Shaman" },
	[5] = { "<:p5:468937377981923339>", 0xBA3D13, "Art" },
	[6] = { "<:p6:563096586394140682>", 0x908B86, "Mechanism" },
	[7] = { "<:racing:512016668038266890>", 0xE8E8E8, "No-shaman" },
	[8] = { "<:p8:563096583856586757>", 0x9585AC, "Dual shaman" },
	[9] = { "<:tfm_cheese:458404666926039053>", 0xFDD599, "Miscellaneous" },
	[10] = { "<:p10:563096585966452746>", 0x1B1919, "Survivor" },
	[11] = { "<:p11:565931891849428992>", 0xAA4444, "Vampire" },
	[17] = { "<:p17:565931895662051330>", 0xCC4F3A, "Racing" },
	[18] = { "<:p18:565931898858242074>", 0x73B32D, "Defilante" },
	[19] = { "<:p19:565931896979324958>", 0xD0CBCD, "Music" },
	[22] = { "<:tribe:458407729736974357>", 0x8B6C4E, "Tribe House" },
	[24] = { "<:p24:563098653036773389>", 0x1B1919, "Dual Shaman Survivor" },
	[43] = { "<:p44:563096584741585049>", 0xF40000, "High Deleted" },
	[44] = { "<:p44:563096584741585049>", 0xF40000, "Deleted" }
}

-- Commands
local chatHelpSource, whisperHelpSource, memberHelpSource
local commandWrapper, chatCommand, whisperCommand, serverCommand
do
	local help = function(src, param, level, prefix)
		prefix = prefix or ','

		if param then
			param = string.lower(param)
			if string.sub(param, 1, 1) == prefix then
				param = string.sub(param, 2)
			end

			local cmdList = (level == 0 and chatCommand or level == 1 and whisperCommand or (level == 2 or level == 3) and serverCommand)
			if commandWrapper[param] then
				return "'" .. prefix .. param .. "' → " .. tostring(commandWrapper[param])
			elseif cmdList[param] and (level ~= 3 or cmdList[param].pb) then
				return "'" .. prefix .. param .. "' → " .. tostring(cmdList[param])
			end
			return "Command '" .. prefix .. param .. "' not found. :s"
		end
		return "Type '" .. prefix .. "help command_name' to learn more. Available Commands → '" .. prefix .. table.concat(src, ("' | '" .. prefix)) .. "'"
	end

	local faqThread = {
		AR = "https://atelier801.com/topic?f=6&t=855915",
		BR = "https://atelier801.com/topic?f=5&t=918370",
		CZ = "https://atelier801.com/topic?f=6&t=802213",
		EN = "https://atelier801.com/topic?f=6&t=51414",
		ES = "https://atelier801.com/topic?f=5&t=807135",
		FI = "https://atelier801.com/topic?f=6&t=774915",
		FR = "https://atelier801.com/section?f=6&s=262",
		HR = "https://atelier801.com/topic?f=6&t=873492",
		HU = "https://atelier801.com/topic?f=5&t=859467",
		ID = "https://atelier801.com/topic?f=6&t=792769",
		NL = "https://atelier801.com/topic?f=6&t=66171",
		PL = "https://atelier801.com/topic?f=5&t=899050",
		RO = "https://atelier801.com/topic?f=5&t=815405",
		RU = "https://atelier801.com/topic?f=6&t=21566",
		TR = "https://atelier801.com/topic?f=6&t=880318",
		VK = "https://atelier801.com/topic?f=6&t=64966",
	}
	faqThread.GB = faqThread.EN
	faqThread.PT = faqThread.BR
	faqThread.SA = faqThread.AR

	local teams = {
		mt = { "Module Team", "https://goo.gl/ZJcnhZ" }
	}
	local teamAliases = { }
	-- MT
	teamAliases.moduleteam = "mt"
	teamAliases["module team"] = "mt"
	teamAliases.lua = "mt"
	teamAliases.luateam = "mt"
	teamAliases.luadev = "mt"
	teamAliases.dev = "mt"

	-- Whisper, Server
	local c_mt = {
		pb = true,
		h = "Displays the online public module team members.",
		f = createListCommand(" module_team")
	}
	local c_fs = {
		pb = true,
		h = "Displays the online public fashion squad members.",
		f = createListCommand(" fashion_squad")
	}
	local c_fc = {
		pb = true,
		h = "Displays the online public funcorp members.",
		f = createListCommand(" funcorp")
	}

	commandWrapper = { -- param, target, isChatCommand
		["luadoc"] = {
			link = true,
			h = "Sends a link of the Transformice Lua Documentation.",
			f = function()
				return "Lua documentation: https://atelier801.com/topic?f=5&t=451587&p=1#m3"
			end
		},
		["faq"] = {
			link = true,
			h = "Displays the FAQ thread of a community. ',faq community'",
			f = function(param)
				if param then
					param = string.upper(param)
					return faqThread[param] or "This community doesn't have a FAQ yet. :("
				else
					return "Available communities → " .. table.concat(table.map(faqThread, function(_, key)
						return key
					end), " | ")
				end
			end
		},
		["apply"] = {
			link = true,
			h = "Displays the application form link of a Transformice official team. ',apply team_name'",
			f = function(param)
				if param then
					param = string.lower(param)
					local d = teams[param] or (teamAliases[param] and teams[teamAliases[param]])
					return (d and ("Apply to '" .. d[1] .. "': " .. d[2]) or "The requested team was not found. :(")
				else
					return "Available teams → " .. table.concat(table.map(teams, function(value)
						return value[1]
					end), " | ")
				end
			end
		}
	}
	chatCommand = { -- target, playerName, param
		["help"] = {
			h = "Displays the available commands / the commands descriptions.",
			f = function(channelName, _, parameters)
				tfm:sendChatMessage(channelName, "Whisper me with ',help' to get the command list.")
			end
		}
	}
	whisperCommand = { -- isDebugging(4 #shadestest), playerName, Param
		["help"] = {
			h = "Displays the available commands / the commands descriptions.",
			f = function(isDebugging, playerName, parameters)
				local t = help(whisperHelpSource, parameters, 1)
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["about"] = {
			h = "Displays cool bot informations.",
			f = function(isDebugging, playerName)
				local t = "I'm a bot from the 'Fifty Shades of Lua' server ( discord.gg/quch83R ), maintained by Bolodefchoco#0000. We are not from the \"Helpers\" team, but a separated group intended to help everyone, mostly about modules, lua, and technical stuff."
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["shelpers"] = {
			h = "Displays the Shades Helpers that are online on Discord.",
			f = function(isDebugging, playerName)
				local online, counter = { }, 0
				for member in settingchannel.discussion.members:findAll(function(member) return member.status ~= "offline" end) do
					if helper[member.id] then
						counter = counter + 1
						online[counter] = helper[member.id]
					end
				end
				table.sort(online)

				local t = (#online == 0 and "No Shades Helpers online on Discord. :(" or ("Online Shades Helpers on Discord: " .. table.concat(online, ", ")))
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["dressroom"] = {
			link = true,
			h = "Sends a link of your/someone's outfit. Accepts a nickname parameter.",
			f = function(isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters)
				else
					parameters = playerName
				end

				dressroom[parameters] = { playerName = playerName, isDebugging = isDebugging }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["makebot"] = {
			link = true,
			h = "Displays the URLs of the bot APIs.",
			f = function(isDebugging, playerName)
				local t = "Use one of our marvelous APIs to make your bot. Languages: Lua → github.com/Lautenschlager-id/Transfromage | Python → github.com/Tocutoeltuco/transfromage | Python Async → github.com/Athesdrake/aiotfm. Support → discord.gg/quch83R"
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
	}
	serverCommand = {
		["help"] = {
			pb = true,
			h = "Displays the available commands / the commands descriptions.",
			f = function(message, parameters)
				local isPb = (message.channel.category and message.channel.category.id ~= categoryId)
				message:reply((string.gsub(help((isPb and serverHelpSource or memberHelpSource), parameters, (isPb and 3 or 2), '/'), '\'', '`')))
			end
		},
		["who"] = {
			h = "Displays a list of who is in the chat.",
			f = function(message)
				if message.channel.id == channel.whisper then
					 message:reply(":warning: This is not a #channel, but the environment used to whisper players.")
				else
					tfm:chatWho(channel(message.channel.id))
				end
			end
		},
		["mod"] = {
			pb = true,
			h = "Displays the list of online Moderators.",
			f = function(message)
				modList[message.channel.id] = true
				tfm:sendCommand("mod")
			end
		},
		["mapcrew"] = {
			pb = true,
			h = "Displays the list of online Mapcrews.",
			f = function(message)
				mapcrewList[message.channel.id] = true
				tfm:sendCommand("mapcrew")
			end
		},
		["time"] = {
			h = "Displays the connection and account's time.",
			f = function(message)
				timeCmd[message.channel.id] = true
				tfm:sendCommand("time")
			end
		},
		["modules"] = {
			pb = true,
			h = "Displays the room list of official modules",
			f = function(message)
				modulesCmd[message.channel.id] = true
				tfm:requestRoomList(transfromage.enum.roomMode.module)
			end
		},
		["bolo"] = {
			h = "[Admin only] Refreshes #bolodefchoco→\3*Editeur",
			f = function(message)
				if message.author.id == disc.owner.id then
					message:reply("Refreshing #bolodefchoco→\3*Editeur")
					tfm:sendCommand("module bolodefchoco")
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["isonline"] = {
			pb = true,
			h = "Checks whether a player is online or not.",
			f = function(message, parameters)
				if not parameters then return end
				parameters = string.toNickname(parameters, true)
				tfm:sendRoomMessage(parameters .. " get_user " .. parameters)
				onlinePlayers[parameters] = message.channel
			end
		},
		["map"] = {
			pb = true,
			h = "Gets the image of the map specified.",
			f = function(message, parameters, _xmlOnly)
				if not parameters or not string.find(parameters, "^@%d%d%d") or string.find(parameters, "[^@%d]") then return end

				if xml[parameters] then
					return message:reply("<@" .. message.author.id .. ">, the map **" .. parameters .. "** already is in the queue.")
				end

				local len = #xml.queue + 1
				xml.queue[len] = parameters
				xml[parameters] = { message = message, _xmlOnly = _xmlOnly }

				if len == 1 then
					loadXmlQueue()
				else
					local time = 3 * (len - 1)
					xml[parameters].reply = message:reply("<@" .. message.author.id .. ">, your request is in the position #" .. len .. " and will be executed in ~" .. time .. "seconds!")
				end
			end
		},
		["xml"] = {
			pb = true,
			h = "Gets the XML of the map specified. [<@&462329326600192010> role is required]",
			f = function(message, parameters)
				if (message.channel.category and message.channel.category.id ~= categoryId) and not message.member:hasRole("462329326600192010") then
					return message:reply("<@" .. message.author.id .. ">, you must have the role <@&462329326600192010> in order to use this command!")
				end

				serverCommand["map"].f(message, parameters, true)
			end
		},
		["clearxml"] = {
			h = "[Admin only] Clears the cache of the XML table.",
			f = function(message)
				if message.author.id == disc.owner.id then
					message:reply("Clearing cache")
					xml = { queue = { } }
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["invth"] = {
			h = "[Admin only] Invites Bolo to the tribe house.",
			f = function(message)
				if message.author.id == disc.owner.id then
					message:reply("Inviting")
					tfm:sendCommand("inv Bolodefchoco#0000")
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["goto"] = {
			h = "[Admin only] Changes the Bot room.",
			f = function(message, parameters)
				if not parameters then return end

				if message.author.id == disc.owner.id then
					if parameters == "tribe" then
						tfm:joinTribeHouse()
						message:reply("Joined *\3Editeur!")
					else
						tfm:enterRoom(parameters)
						message:reply("Joined room **" .. parameters .. "**")
					end
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["tfmprofile"] = {
			pb = true,
			h = "Displays the profile of a user in real time. (User required to be online)",
			f = function(message, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
					profile[parameters] = message.channel.id
					tfm:sendCommand("profile " .. parameters)
				else
					message:reply("Invalid nickname '" .. parameters .. "'")
				end
			end
		},
	}
end

chatHelpSource = table.fuse(table.keys(chatCommand), table.keys(commandWrapper))
whisperHelpSource = table.fuse(table.keys(whisperCommand), table.keys(commandWrapper))
memberHelpSource = table.keys(serverCommand)
serverHelpSource = table.keys(serverCommand, function(k, v) return v.pb end)
table.sort(chatHelpSource)
table.sort(whisperHelpSource)
table.sort(memberHelpSource)
table.sort(serverHelpSource)
do
	local setMeta = function(src)
		for k, v in next, src do
			if type(v) == "table" then
				v = setmetatable(v, {
					__call = function(this, ...)
						return this.f(...)
					end,
					__tostring = function(this)
						return this.h
					end
				})
			end
		end
	end

	setMeta(commandWrapper)
	setMeta(chatCommand)
	setMeta(whisperCommand)
	setMeta(serverCommand)
end

local getCommandParameters = function(message, prefix)
	if #message < 2 then return end
	local command, parameters = string.match(message, "^" .. (prefix or ',') .. "(%S+)[\n ]*(.*)")
	parameters = (parameters ~= '' and parameters or nil)
	return (command and string.lower(command)), parameters
end

local userAntiSpam = function(src, playerName)
	if src.link then
		local time = os.time()
		if (userCache[playerName] and userCache[playerName] > time) then
			return "Wow, " .. playerName .. "; Hold on, cowboy! Don't spam me with commands."
		else
			userCache[playerName] = time + ANTI_SPAM_TIME
		end
	end
end

local executeCommand = function(isChatCommand, content, target, playerName, isDebugging)
	local returnValue
	local cmd, param = getCommandParameters(content)

	if commandWrapper[cmd] then
		returnValue = userAntiSpam(commandWrapper[cmd], target) or commandWrapper[cmd](param, target, isChatCommand)
		if returnValue then
			if isChatCommand or isDebugging then
				tfm:sendChatMessage(target, returnValue)
			else
				tfm:sendWhisper(target, returnValue)
			end
		end
		return true
	else
		if isChatCommand then
			if chatCommand[cmd] then
				returnValue = userAntiSpam(chatCommand[cmd], playerName) or chatCommand[cmd](target, playerName, param)
				if returnValue then
					tfm:sendChatMessage(target, returnValue)
				end
				return true
			end
		else
			if whisperCommand[cmd] then
				returnValue = userAntiSpam(whisperCommand[cmd], playerName) or whisperCommand[cmd](isDebugging, playerName, param)
				if returnValue then
					if isDebugging then
						tfm:sendChatMessage(target, returnValue)
					else
						tfm:sendWhisper(target, returnValue)
					end
				end
				return true
			end
		end
	end
	return false
end

-- Discord emitters
disc:once("ready", function()
	for k, v in pairs(channel) do -- __pairs
		object[k] = disc:getChannel(v)
	end
	for k, v in next, settingchannel do
		settingchannel[k] = disc:getChannel(v)
	end

	for member in settingchannel.memberList:getMessages():iter() do
		setHelper(member.content)
	end

	disc:setGame("Prefix /")

	timer.setTimeout(25 * 1000, function()
		if isConnected then return end
		return error("[Heartbeat] Failed to connect.")
	end)
	protect(tfm.start)(tfm, DATA[3], DATA[4])
	DATA[3], DATA[4] = nil, nil
end)

disc:on("messageCreate", protect(function(message)
	if not isWorking then return end
	if message.author.bot then return end

	if message.channel.id == settingchannel.memberList.id then
		return setHelper(message.content)
	end

	local isMember = channel(message.channel.id) and helper[message.author.id]

	local cmd, param = getCommandParameters(message.content, '/')
	if cmd then
		if serverCommand[cmd] then
			if serverCommand[cmd].pb or isMember then
				return serverCommand[cmd](message, param)
			end
		end
	end

	if not isMember then return end

	if not string.find(message.content, "^,") then return end

	local messages, cutSlice
	if (channel.whisper == message.channel.id) then -- on whisper
		local target, content = string.match(message.content, "^,(.-) +(.+)")
		if target == 'r' then
			if not lastUserReply then
				message:reply({
					content = "<@" .. message.author.id .. ">, there's no `last_user_reply` definition yet.",
					embed = {
						color = 0xFFAA00,
						description = "Use `,target message` or `,r message` (← last_user_reply)"
					}
				})
			else
				target = lastUserReply
			end
		else
			target = string.toNickname(target)
		end

		messages, cutSlice = splitMsgByWord(helper[message.author.id], formatSendText(content), WHISPER_MSG_LIM)
		for m = 1, #messages do
			tfm:sendWhisper(target, messages[m])
		end
	else
		if message.channel.id == channel.shadestest then
			-- Whisper comes first because of ',help'
			local executed = executeCommand(false, message.content, channel(message.channel.id), helper[message.author.id], true)
			executed = executed or executeCommand(true, message.content, channel(message.channel.id), helper[message.author.id])
			if executed then return end
		end

		local content = string.sub(message.content, 2)
		messages, cutSlice = splitMsgByWord(helper[message.author.id], formatSendText(content), CHAT_MSG_LIM)
		for m = 1, #messages do
			tfm:sendChatMessage(channel(message.channel.id), messages[m])
		end
	end
	if cutSlice then
		message:reply({
			content = "<@" .. message.author.id .. ">, the part of the message written below was not sent due to message size limits.",
			embed = {
				color = 0xFFAA00,
				description = cutSlice
			}
		})
	end
end))

disc:on("messageDelete", protect(function(message)
	if message.channel.id == settingchannel.memberList.id then
		return remHelper(message.content)
	end
end))

disc:on("messageUpdate", protect(function(message)
	if message.channel.id == settingchannel.memberList.id then
		remHelper(message.content)
		setHelper(message.content)
	end
end))

-- Transformice emitters
tfm:once("ready", protect(function()
	print("Connecting")
	tfm:connect(DATA[1], DATA[2])
	DATA[2] = nil
end))

tfm:once("heartbeat", protect(function()
	isConnected = true
end))

tfm:on("ping", protect(function()
	if lastServerPing then
		timer.clearTimeout(lastServerPing)
	end
	lastServerPing = timer.setTimeout(22 * 1000, error, "[Ping] Lost connection.")
end))

tfm:once("connection", protect(function()
	print("Joining Tribe House")
	tfm:joinTribeHouse()

	print("Opening channels")
	for chat in pairs(channel) do
		if chat ~= "whisper" then
			tfm:joinChat(chat)
		end
	end

	-- Get title list
	local _, body = http.request("GET", "http://transformice.com/langues/tfz_en")
	body = require("miniz").inflate(body, 1) -- Decompress

	local male, female
	for titleId, titleName in string.gmatch(body, "¤T_(%d+)=([^¤]+)") do
		titleId = tonumber(titleId)

		titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
		titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
		if string.find(titleName, '|', nil, true) then -- Male / Female
			-- Male version
			male = string.gsub(titleName, "%((.-)|.-%)", function(s) return s end)
			-- Female version
			female = string.gsub(titleName, "%(.-|(.-)%)", function(s) return s end)

			titleName = { male, female } -- id % 2 + 1
		end
		title[titleId] = titleName
	end
end))

tfm:once("joinTribeHouse", protect(function()
	print("Joined Tribe House")
	print("Loading module")
	tfm:sendCommand("module bolodefchoco")
	timer.setInterval(60 * 60 * 1000 * 2, function()
		print("Reloading module")
		tfm:sendCommand("module bolodefchoco")
	end)

	timer.setTimeout(2500, function() -- Loading #bolodefchoco.*\3Editeur data.
		print("Working")
		isWorking = true
	end)
end))

tfm:on("chatMessage", protect(function(channelName, playerName, message, playerCommunity)
	if not channel[channelName] then return end
	if channelName == "whisper" then return end -- :P
	p(channelName, playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	local content = string.format("[%s] [%s] [%s] %s", os.date("%H:%M"), getCommunityCode(playerCommunity), playerName, message)
	content = formatReceiveText(content)

	object[channelName]:send(content)

	executeCommand(true, message, channelName, playerName)
end))

tfm:on("whisperMessage", protect(function(playerName, message, playerCommunity)
	p(playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	local isBot = playerName == DATA[1]
	if not isBot then
		lastUserReply = playerName
	end

	local content = string.format("%s [%s] [%s] [%s%s] %s", (isBot and '<' or '>'), os.date("%H:%M"), getCommunityCode(playerCommunity), playerName, ((isBot and lastUserWhispered) and (" → " .. lastUserWhispered) or ''), message)
	content = formatReceiveText(content)

	object.whisper:send(content)

	executeCommand(false, message, playerName, playerName)
end))

tfm:on("profileLoaded", protect(function(data)
	if dressroom[data.playerName] then
		local look = data.playerName .. "'s outfit: " .. dressroomLink(data.look)

		if dressroom[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(look))
		else
			tfm:sendWhisper(dressroom[data.playerName].playerName, look)
		end

		dressroom[data.playerName] = nil
	elseif profile[data.playerName] then
		local title = (type(title[data.titleId]) == "table" and title[data.titleId][(data.gender % 2 + 1)] or title[data.titleId])
		disc:getChannel(profile[data.playerName]):send({
			embed = {
				color = 0x2E565F,
				title = "<:tfm_cheese:458404666926039053> Transformice Profile - " .. data.playerName .. (data.gender == 2 and " <:male:456193580155928588>" or data.gender == 1 and " <:female:456193579308679169>" or ''),
				description =
					(data.role > 0 and ("**Role :** " .. string.gsub(transfromage.enum.role(data.role), "%a", string.upper, 1) .. "\n\n") or '') ..

					((data.soulmate and data.soulmate ~= '') and (":revolving_hearts: **" .. string.toNickname(data.soulmate) .. "**\n") or '') ..
					":calendar: " .. os.date("%d/%m/%Y", data.registrationDate) .. 
					((data.tribeName and data.tribeName ~= '') and ("\n<:tribe:458407729736974357> **Tribe :** " .. data.tribeName) or '') ..

					"\n\n**Level " .. data.level .. "**" ..
					"\n**Current Title :** «" .. (title or data.titleId) .. "»" ..
					"\n**Adventure points :** " .. data.adventurePoints ..

					"\n\n<:shaman:512015935989612544> " .. data.saves.normal .. " / " .. data.saves.hard .. " / " .. data.saves.divine ..
					"\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. data.shamanCheese ..

					"\n\n<:racing:512016668038266890> **Firsts :** " .. data.firsts ..
					"\n<:tfm_cheese:458404666926039053> **Cheeses :** " .. data.cheeses ..
					"\n<:bootcamp:512017071031451654> **Bootcamps :** " .. data.bootcamps ..

					"\n\n<:dance:468937918115741718> **[Outfit](" .. dressroomLink(data.look) .. ")**\n\n" ..

					"<:wheel:456198795768889344> **Total titles :** " .. data.totalTitles ..
					"\n<:wheel:456198795768889344> **Total badges :** " .. data.totalBadges ..
					"\n<:wheel:456198795768889344> **Total cartouches :** " .. data.totalOrbs
				,
				thumbnail = { url = "http://avatars.atelier801.com/" .. (data.id % 10000) .. "/" .. data.id .. ".jpg" }
			}
		})
		profile[data.playerName] = nil
	end
end))

tfm:insertPacketListener(6, 9, protect(function(self, connection, packet, C_CC) -- Chat message from #bolodefchoco.*\3Editeur
	local text = packet:readUTF()
	local team, missing, content = string.match(text, "^(%S+) (%d) (.+)")
	missing = tonumber(missing)

	if team then
		if onlinePlayers[team] then
			local isOnline = json.decode(content).isOnline
			onlinePlayers[team]:send((isOnline and "<:online:456197711356755980>" or "<:offline:456197711457419276>") .. team .. " is " .. (isOnline and "on" or "off") .. "line!")
			onlinePlayers[team] = nil
			return
		end

		local l = srcMemberListCmd[team]
		if not l then return end
		l._loading = l._loading .. content
		if missing == 0 then
			team = string.gsub(team, "%u", " %1")
			local out, counter = { }, 0
			for k, v in next, json.decode(l._loading).members do
				if v then
					counter = counter + 1
					out[counter] = remDefaultDiscriminator(k)
				end
			end
			if #out > 0 then
				table.sort(out)
				l._onlineMembers = "Online" .. team .. " members: " .. table.concat(out, ", ") -- Together because of %u→ %l
			else
				l._onlineMembers = "No" .. team .. " online members."
			end
			l._loading = ''

			for i = 1, #l._queue do
				if l._queue[i].isDebugging then
					if l._queue[i].isServerCmd then
						l._queue[i].isDebugging:reply(formatServerText(l._onlineMembers))
					else
						object.shadestest:send(formatReceiveText(l._onlineMembers))
					end
				else
					tfm:sendWhisper(l._queue[i].playerName, l._onlineMembers)
				end
			end
			l._queue = { }
		end
		l._timer = os.time() + 60
	end
end))

tfm:on("chatWho", protect(function(chatName, data)
	if not chatName then return end

	object[chatName]:send("Members in **#" .. chatName .. "** : " .. #data .. "\n" .. table.concat(table.mapArray(data, function(user)
		return "`" .. user .. "`"
	end), ", "))
end))

tfm:on("staffList", protect(function(list)
	local isMod = false
	local hasOnline = true

	list = string.gsub(list, "%$(%S+)", function(line)
		if line == "ModoEnLigne" then
			isMod = true
			return "**Online Moderators:**"
		elseif line == "MapcrewEnLigne" then
			return "**Online Mapcrews:**"
		elseif line == "ModoPasEnLigne" then
			return "**No Moderators online.**"
		elseif line == "MapcrewPasEnLigne" then
			return "**No Mapcrews online.**"
		end
	end)

	if hasOnline then
		list = string.gsub(list, "<.->", '')

		list = string.gsub(list, "%[..%]", function(commu)
			return "`" .. string.upper(commu) .. "`"
		end)

		list = string.gsub(list, "#%d+", "`%1`")
	end

	for channel in next, (isMod and modList or mapcrewList) do
		disc:getChannel(channel):send(list)
	end
	if isMod then
		modList = { }
	else
		mapcrewList = { }
	end
end))

tfm:on("time", protect(function(time)
	local r = string.format("**Connection time:** %s\n**Account time:** %d days, %d hours, %d minutes, and %d seconds.", secToDate(tfm:connectionTime()), time.day, time.hour, time.minute, time.second)

	for channel in next, timeCmd do
		disc:getChannel(channel):send(r)
	end

	timeCmd = { }
end))

tfm:on("roomList", protect(function(roomMode, rooms, pinned)
	if roomMode ~= transfromage.enum.roomMode.module then return end

	local totalModules, f = #pinned
	local halfModules = math.ceil(totalModules / 2)

	for i = 1, totalModules do
		pinned[i].totalPlayers = tonumber(pinned[i].totalPlayers) or -666 -- It's UTF
	end

	table.sort(pinned, function(m1, m2) return m1.totalPlayers > m2.totalPlayers end)

	local fields = { { }, { } }
	for i = 1, totalModules do
		f = (i <= halfModules and 1 or 2)
		fields[f][#fields[f] + 1] = "**" .. pinned[i].name .. "**\t`" .. pinned[i].totalPlayers .. "`"
	end

	local message = {
		embed = {
			color = 0x36393F,
			title = "Total modules: **" .. totalModules .. "**",
			fields = {
				[1] = {
					name = '‌',
					value = table.concat(fields[1], '\n'),
					inline = true
				},
				[2] = {
					name = '‌',
					value = table.concat(fields[2], '\n'),
					inline = true
				}
			}
		}
	}

	for channel in next, modulesCmd do
		disc:getChannel(channel):send(message)
	end
	modulesCmd = { }
end))

tfm:on("newGame", protect(function(map)
	map.code = "@" .. map.code
	if map.xml and map.xml ~= '' and xml[map.code] then
		timer.clearTimeout(xml[map.code].timer)

		if #map.xml <= 23000 then
			local err, head, body = false
			if xml[map.code]._xmlOnly then
				head, body = http.request("POST", "https://hastebin.com/documents", nil, map.xml)

				if head.code == 200 then
					body = json.decode(body)

					local m = xml[map.code].message:reply("<@" .. xml[map.code].message.author.id .. ">, the XML of the map **" .. map.code .. "** is **https://hastebin.com/" .. tostring(body.key) .. "**")
					timer.setTimeout(20000, function(m)
						m:delete()
					end, m)
				else
					err = true
				end
			else
				head, body = http.request("POST", "https://xml-drawer.herokuapp.com/", { { "content-type", "application/x-www-form-urlencoded" } }, "xml=" .. encodeUrl(map.xml))

				if head.code == 200 then
					local tmp = string.match(os.tmpname(), "([^/]+)$") .. ".png" -- Match needed so it doesn't glitch 'attachment://'
					local file = io.open(tmp, 'w')
					file:write(body)
					file:flush()
					file:close()

					local perm = (mapCategories[map.perm] or mapCategories.default)
					xml[map.code].message:reply({
						content = "<@" .. xml[map.code].message.author.id .. ">",
						embed = {
							color = perm[2],
							description = (perm[3] and ("`[" .. perm[3] .. "]` ") or '') .. perm[1] .. " - **P" .. map.perm .. "**\n" .. map.code .. " - **" .. remDefaultDiscriminator(map.author) .. "**",
							image = { url = "attachment://" .. tmp }
						},
						file = tmp
					})

					os.remove(tmp)
				else
					err = true
				end
			end

			if err then
				xml[map.code].message:reply({
					content = "<@" .. xml[map.code].message.author.id .. ">",
					embed = {
						color = 0x36393F,
						title = "Fail",
						description = "Internal error :( Try again later",
						fields = {
							[1] = {
								name = "Head code",
								value = tostring(head and head.code),
								inline = true
							},
							[2] = {
								name = "Body",
								value = tostring(body and string.sub(body, 1, 500)),
								inline = true
							},
						}
					}
				})
			end
		else
			xml[map.code].message:reply({
				content = "<@" .. xml[map.code].message.author.id .. ">",
				embed = {
					color = 0x36393F,
					title = "Fail",
					description = "The map XML size is too big :( (" .. math.ceil(#map.xml / 1000) .. "kb)"
				}
			})
		end

		if xml[map.code].reply then
			xml[map.code].reply:delete()
		end

		table.remove(xml.queue, 1)
		xml[map.code] = nil

		timer.setTimeout(1000, coroutine.wrap(loadXmlQueue))
	end
end))

-- Initialize
tfm:setCommunity(transfromage.enum.community.sk)
disc:run(DATA[5])
DATA[5] = nil