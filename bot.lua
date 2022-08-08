local db_url = "https://discorddb.000webhostapp.com/" -- "http://fsoldb.rf.gd/"

-- Consts
local CHAR_LIM = 255
local CHAT_MSG_LIM = 3
local WHISPER_MSG_LIM = 4
local ANTI_SPAM_TIME = 5
local REWARDS_TIME = 10
local FAST_REPLY_TIME = 60
local AVATAR_TIME = 0
local DATA = { }
do
	local counter = 0
	for line in io.lines("acc") do
		counter = counter + 1
		DATA[counter] = line
	end
end

-- Deps
local timer = require("timer")
local http = require("coro-http")
local json = require("json")

-- Libs
local discordia = require("discordia")
local transfromage = require("transfromage")
local fromage = require("fromage")
local clock, totalMinutes = discordia.Clock(), 0

-- Init
local disc = discordia.Client({
	cacheAllMembers = true
})
disc._options.routeDelay = 0
local tfm = transfromage.Client:new()

-- Init methods
string.trim = function(str)
	return (string.gsub(tostring(str), "^ *(.*) *$", "%1"))
end

string.isSimilar = function(src, try, _perc)
	return discordia.extensions.string.levenshtein(string.lower(src), string.lower(try)) <= math.ceil(#src * (_perc or .3))
end

string.count = function(str, o)
	local count = 0
	local pos = 1
	local i, j
	while true do
		i, j = string.find(str, o, pos, true)
		if not i then break end
		count = count + 1
		pos = j + 1
	end
	return count
end

string.split2 = function(str, pat)
	local out, counter = { }, 0

	for v in string.gmatch(str, pat) do
		counter = counter + 1
		out[counter] = tonumber(v) or v
	end

	return out
end

table.map = function(list, f)
	local newList, counter = { }, 0
	for k, v in next, list do
		counter = counter + 1
		newList[counter] = f(v, k)
	end
	return newList
end
table.mapArray = function(arr, f)
	local newArray = { }
	for i = 1, #arr do
		newArray[i] = f(arr[i])
	end
	return newArray
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

table.set = function(arr)
	local set = { }
	for i = 1, #arr do
		set[arr[i]] = i
	end
	return set
end

local pairsByIndexes = function(list, f)
	local out = {}
	for index in next, list do
		out[#out + 1] = index
	end
	table.sort(out, f)

	local i = 0
	return function()
		i = i + 1
		if out[i] ~= nil then
			return out[i], list[out[i]]
		end
	end
end

local noShamanVanilla = {
	[8] = true,
	[10] = true,
	[14] = true,
	[22] = true,
	[23] = true,
	[28] = true,
	[42] = true,
	[55] = true,
	[57] = true,
	[58] = true,
	[61] = true,
	[70] = true,
	[77] = true,
	[78] = true,
	[87] = true,
	[88] = true,
	[109] = true,
	[122] = true,
	[123] = true,
	[124] = true,
	[125] = true,
	[126] = true,
	[144] = true,
	[148] = true,
	[149] = true,
	[150] = true,
	[151] = true,
	[170] = true,
	[171] = true,
	[172] = true,
	[173] = true,
	[174] = true,
	[175] = true,
	[178] = true,
	[179] = true,
	[180] = true,
	[188] = true,
	[189] = true,
	[190] = true,
	[200] = true,
	[201] = true,
	[202] = true,
	[203] = true,
	[204] = true,
	[205] = true,
	[206] = true,
	[207] = true,
	[208] = true,
	[209] = true,
	[210] = true,
}
local fixEvtInUse = false

-- Data
local object = { }
local channel = transfromage.enum({
	-- Message
	help = "544935946290987009",
	lua = "544936074237968434",
	mapcrew = "565716126814830612",
	shadestest = "546429085451288577",
	whisper = "547882749348806673",
	teamTool = "808159322885849100",
	modulesTool = "720287808002064467",
	avatars = "794605805860290581",
	br = "806679772562063391",
	es = "806679824348741633",
	pt = "806679793235001394",
	ar = "806681309841457203",
	co = "811743130672037908",
	cl = "811743185260380210",
	pe = "811743228105457686",
	mx = "811743255876075571",
	karma = "822204970517790800",
	evento = "930942509201383524",
	event = "935678263760662598"
})

local settingChannel = require("./data/settingChannel")
p(tostring(settingChannel))

local rulesProcessor = require("./rules-processor")

local miscChannel = {
	transfromage_tokens = "579687024219389954"
}
local categoryId = "544935544975786014"

local helper = { _commu = { } }
local isConnected = false
local isWorking = false
local lastServerPing, lastUserReply, lastUserWhispered

local dressroom = { }
local onlinePlayer = { }
local modList, mapcrewList = { }, { }
local timeCmd = { }
local modulesCmd = { }
local xml = { queue = { } }
local userCache = { }
local profile = { }
local checkTitles = { }
local friendRemoval
local displayBlacklist = { }
local checkAvailableRewards = { }
local rewardsCooldown = { }
local fastReplyCooldown = { }
local avatars = { }
local shopSales = { }

local shamanItemCategories = {
	[1] = "Small Box",
	[2] = "Big Box",
	[3] = "Small Plank",
	[4] = "Big Plank",
	[6] = "Ball",
	[7] = "Trampoline",
	[10] = "Anvil",
	[17] = "Cannon",
	[28] = "Balloon"
}

local mapCategory = require("data/mapCategory")
local roleColors = require("data/roleColors")
local countryFlags = require("data/countryFlags")

local titleRequirements = require("data/titleRequirements")

local titleFields = { "cheese", "firsts", "savesNormal", "savesHard", "savesDivine", "bootcamps" }
local titleFieldsKeys = { "$cheese", "$first", "$svnormal", "$svhard", "$svdiv", "$boot" }

local unavailableTitles = require("data/unavailableTitles")

local translate
do
	local normalizeTitles = function(titleName)
		titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
		--titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
		return titleName
	end

	local meta
	meta = {
		__newindex = function(this, index, value)
			local lang = transfromage.enum.language[index]

			local downloaded
			os.log("↑info↓[TRANSLATION]↑ Downloading the language ↑highlight↓" .. lang .. "↑")
			transfromage.Translation:new(lang, function(self)
				downloaded = true
				os.log("↑success↓[TRANSLATION]↑ Downloaded the language ↑highlight↓" .. lang .. "↑")
				-- Fix titles
				self:free(nil, "^T_%d+")
				self:set("^T_%d+", normalizeTitles)
			end)

			timer.setTimeout(2500, function()
				if not downloaded then
					meta.__newindex(this, index, value)
				end
			end)

			rawset(this, index, require("data/lang/" .. index))
		end,
		__call = function(this, community, str, ...)
			if type(this[community]) == "string" then
				community = this[community]
			end
			community = community and this[community] or this.en

			str = string.gsub(str, "%$(%w+)", function(line)
				return community[line] or this.en[line] or ("$" .. line)
			end)
			return string.format(str, ...)
		end
	}

	translate = setmetatable({ pt = "br" }, meta)
end

translate.en = true
translate.br = true
translate.es = true
translate.fr = true

local teamListAbbreviated = {
	mt = "ModuleTeam",
	fs = "FashionSquad",
	fc = "Funcorp",
	sent = "Sentinel",
	sh = "ShadesHelpers",
	st = "ShadesTranslators",
	fla = "FlashSquad",
	bot = "Bot",
	evt = "EventSquad",
	disc = "Discorderator",
}

local specialHeaders = {
	english = { { "Accept-Language", "en-US,en;q=0.9" } },
	json = { { "Content-Type", "application/json" } },
	urlencoded = { { "Content-Type", "application/x-www-form-urlencoded" } }
}

local countryCodeConverted = {
	AR = "SA",
	EN = "GB",
	HE = "IL",
	VK = "NO",
	XX = "EU"
}
local countryCodeConvertedReverse = { }
for k, v in next, countryCodeConverted do
	countryCodeConvertedReverse[v] = k
end

local cachedTeamListDisplay = { }

local teamList, mapcrewData
local mapcrewListByCategoryContent

local luaDoc
local typeConvertion = {
	str = "String",
	string = "String",
	float = "Float",
	num = "Number",
	number = "Number",
	int = "Integer",
	integer = "Integer",
	bool = "Boolean",
	boolean = "Boolean",
	tbl = "Table",
	table = "Table",
	f = "Function",
	func = "Function",
	["function"] = "Function",
	fn = "Function"
}

local teamListHasBeenChanged = false
local teamListFileTimer = 0

local modules

local commandActivity, saveActivity

local githubWebhook = {
	id = "649659668913717270",
	name = "Lautenschlager-id",
	actionName = "github-actions[bot]",
	embedType = "rich",
	waitingAction = false
}

local teamUpdaterWebhook = {
	id = "831950655555239977"
}

local ENV
local toDelete = setmetatable({}, {
	__newindex = function(list, index, value)
		if value then
			if value.channel then
				value = { value.id }
			else
				value = table.map(value, function(c)
					return c.id
				end)
			end

			rawset(list, index, value)
		end
	end
})

local stalk = {
}

local messageLogForPolicy = {
	karma = { },
	evento = { },
	--shadestest = { }
}

-- Functions
local saveCommandActivity, saveDatabase
do
	_G.error = function(msg, lvl)
		coroutine.wrap(function(msg, lvl)
			if lvl == transfromage.enum.errorLevel.low then
				if disc then
					disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, low level error.\n```\n" .. msg .. "```")
				else
					p(msg, lvl)
				end
			else
				if disc then
					disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, high level error.\n```\n" .. msg .. "```")
					if saveActivity then
						saveCommandActivity()
					end
				end
				os.exit(p(msg, lvl))
			end
		end)(msg, lvl)
	end
end

timer.setIntervalCoro = function(t, f, ...)
	return timer.setInterval(t, coroutine.wrap(f), ...)
end

timer.setTimeoutCoro = function(t, f, ...)
	return timer.setTimeout(t, coroutine.wrap(f), ...)
end

local protect = function(f)
	return function(...)
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
			return false
		end
		return true
	end
end

local setHelper, remHelper
do
	local parse = function(line)
		local id, nick, tag, commu = string.match(line, "^<@!?(%d+)> += +([^#]+)(#?%d*) += +(..)")
		tag = (tag == '' and "#0000" or tag)

		return id, nick, tag, commu
	end

	setHelper = function(line)
		local id, nick, tag, commu = parse(line)

		helper[nick] = id
		if tag ~= "#0000" then
			nick = nick .. tag
		end
		helper[id] = nick
		helper[nick] = id

		helper._commu[id] = commu
	end

	remHelper = function(line)
		local id, nick, tag, commu = parse(line)

		helper[id] = nil
		helper[nick] = nil
		helper[nick .. tag] = nil

		helper._commu[id] = nil
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
					value = settingChannel.discussion.members:find(function(member)
						return string.lower(member.name) == value or string.lower(member.username) == value or (member.nickname and string.lower(member.nickname) == value) or string.lower(member.tag) == value
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
					return "@" .. tostring(user.tag)
				end
			end
			return "@invalid-user"
		end
	end)
	str = string.gsub(str, "<(:.-:)%d+>", "%1")

	return str
end

local formatServerMemberList = function(str, role, requester)
	local title, data = string.match(str, "(.-): (.*)")
	title = title or str

	if data then
		data = string.gsub(data, "#%d+", "`%1`")
		data = string.gsub(data, "%[.-%]", "`%1`")
		data = string.gsub(data, "| ?", "\n")
	end

	return {
		embed = {
			color = (role and roleColors[role] or 0x36393F),
			title = title,
			description = data,
			footer = {
				text = "Requested by " .. requester
			}
		}
	}
end

local splitMsgByWord_old = function(user, msg, maxMsgs, countByByte)
	user = (user and ("[" .. user .. "] ") or '')

	local maxLen = CHAR_LIM - #user

	msg = string.trim(msg)
	local len
	if countByByte then
		len = #msg
	end
	msg = string.utf8(msg)
	local contentLen = #msg
	if len then
		maxLen = maxLen - (len - contentLen)
	end

	local messages, outputCounter = { }, 0

	local current = 1
	while current <= contentLen do
		if msg[current] == ' ' then -- Ignores the first space of the message
			current = current + 1
		end

		outputCounter = outputCounter + 1
		messages[outputCounter] = user .. table.concat(msg, nil, current, math.min(contentLen, current + (maxLen - 1)))

		current = current + maxLen
		if outputCounter == maxMsgs then break end
	end

	return messages, (contentLen >= current and table.concat(msg, nil, current) or nil) -- Messages, Missing
end

local splitMsgByWord = function(user, msg, maxMsgs, countByByte)
	user = (user and ("[" .. user .. "] ") or '')
	maxMsgs = maxMsgs + 1

	msg = string.trim(msg)
	local msgLenByByte = #msg

	msg = string.utf8(msg)
	local msgLenByChar = #msg

	local maxMessageLen = CHAR_LIM - #user
	if countByByte then
		maxMessageLen = maxMessageLen - (msgLenByByte - msgLenByChar)
	end

	local messages, totalMessages = { }, 1
	local messageLen, currentMessageLen = 0, 0

	local iniWord = 1
	local endWord
	local delimSpaceOnEndWord

	local currentChar, isLastChar = 0
	while currentChar <= msgLenByChar do
		currentChar = currentChar + 1
		isLastChar = currentChar == msgLenByChar

		if msg[currentChar] == ' ' then
			endWord = currentChar - 1
		end

		currentMessageLen = currentMessageLen + 1
		if currentMessageLen >= maxMessageLen or isLastChar then
			if not endWord or isLastChar then
				endWord = currentChar
				delimSpaceOnEndWord = 1
			else
				delimSpaceOnEndWord = 2
			end

			messages[totalMessages] = user .. table.concat(msg, nil, iniWord, endWord)
			totalMessages = totalMessages + 1

			messageLen = messageLen + (endWord - iniWord + 1)

			endWord = endWord + delimSpaceOnEndWord
			if totalMessages == maxMsgs or isLastChar then break end

			currentMessageLen = 0
			iniWord = endWord
			currentChar = iniWord
			endWord = nil
		end
	end

	return messages, (msgLenByChar > messageLen and (table.concat(msg, nil, endWord)) or nil) -- Messages, Missing
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
local createListCommand = function(code, __ADD_SH_COMPLEMENT)
	local name = string.gsub(code, "[%s_](%l)", string.upper)
	local src = {
		_loading = '',
		_timer = 0,
		_onlineMembers = setmetatable({ state = 0, data = '', team = '' }, {
			__call = function(this, language)
				if this.state == 0 then
					return translate(language, "$noteam" .. (__ADD_SH_COMPLEMENT and (" ',dischelpers' → $helper") or ''), this.team)
				elseif this.state == 1 then
					return translate(language, "$onteam", this.team, this.data)
				else
					return "$ERROR State=" .. tostring(this.state)
				end
			end
		}),
		_queue = { }
	}
	srcMemberListCmd[name] = src

	return function(playerCommunity, isDebugging, playerName, param)
		local isServerCmd = type(playerCommunity) == "table"
		if isServerCmd then
			playerCommunity, isDebugging, playerName, param = "en", playerCommunity, isDebugging, playerName
		end

		local request = false
		if src._loading == '' then
			if src._timer > os.time() then
				if isServerCmd then
					return isDebugging:reply(formatServerMemberList(src._onlineMembers(playerCommunity), name, isDebugging.author.tag))
				else
					return src._onlineMembers(playerCommunity)
				end
			else
				request = true
			end
		end

		if isServerCmd then
			param = playerName
			playerName = nil
		end
		src._queue[#src._queue + 1] = { playerName = playerName, isDebugging = isDebugging, param = param, isServerCmd = isServerCmd, language = playerCommunity }

		if request then
			tfm:sendRoomMessage(name .. " get_team" .. code)
		end
	end
end

local getCommunityCode = function(playerCommunity)
	local commu = transfromage.enum.chatCommunity(playerCommunity)
	return (commu ~= "az" and commu ~= "ch" and commu ~= "sk") and commu or "int"
end

local splitByLine = function(content, max)
	max = max or 1850

	local data = {}

	if content == '' or content == "\n" then return data end

	local current, tmp = 1, ''
	for line in string.gmatch(content, "([^\n]*)[\n]?") do
		tmp = tmp .. line .. "\n"

		if #tmp > max then
			data[current] = tmp
			tmp = ''
			current = current + 1
		end
	end
	if #tmp > 0 then data[current] = tmp end

	return data
end

local printf = function(...)
	local out = { }
	for arg = 1, select('#', ...) do
		out[arg] = tostring(select(arg, ...))
	end
	return table.concat(out, "\t")
end

local getDatabase = function(fileName, isRaw, ignoreError)
	local _, body = http.request("GET", db_url .. "get?k=" .. DATA[9] .. "&e=json&f=" .. fileName)

	if not isRaw then
		body = json.decode(body)
	end

	if not body and not ignoreError then
		return false, error("[Database] Failed to get data.", transfromage.enum.errorLevel.low)
	end

	return body
end

saveDatabase = function(fileName, data, isRaw)
	if not isRaw then
		data = json.encode(data)
	end

	p('Call save to ' .. fileName)
	local _, body = http.request("POST", db_url .. "set?k=" .. DATA[9] .. "&e=json&f=" .. fileName, specialHeaders.json, data)
	p(body)
	return body == "true"
end

local getRandomTmpRoom = function()
	return "*#bolodefchoco" .. math.random(6666, 9999) .. "d_shades"
end

local luaEventTime

saveCommandActivity = function()
	local tentative, saved = 0
	repeat
		tentative = tentative + 1
		saved = saveDatabase("shadesCommandsActivity", commandActivity)
	until saved or tentative > 5

	if tentative > 5 then
		object.shadestest:send("<@" .. disc.owner.id .. ">, could not save commandActivity data.")
	else
		print("Saved commandActivity data.")
		saveActivity = false
	end
end

-- Command Functions
do
	local sendWhisper = tfm.sendWhisper
	tfm.sendWhisper = function(self, playerName, message, appendMsg, countByByte)
		lastUserWhispered = playerName

		local messages, cutSlice = splitMsgByWord(appendMsg, message, WHISPER_MSG_LIM, countByByte)
		for m = 1, #messages do
			sendWhisper(self, playerName, messages[m])
		end
		return cutSlice
	end

	local sendChatMessage = tfm.sendChatMessage
	tfm.sendChatMessage = function(self, playerName, message, appendMsg, countByByte)
		local messages, cutSlice = splitMsgByWord(appendMsg, message, CHAT_MSG_LIM, countByByte)
		for m = 1, #messages do
			sendChatMessage(self, playerName, messages[m])
		end
		return cutSlice
	end
end

--[[local dressroomLink
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
end]]

local secToDate = function(s)
	local m = (s / 60) % 60
	local h = (s / 3600) % 24
	local d = s / 86400
	s = s % 60

	return string.format("%02dd %02dh %02dm %02ds", d, h, m, s)
end

local remDefaultDiscriminator = function(playerName, _ignoreLimit)
	return string.gsub(playerName, "#0000", '', (not _ignoreLimit and 1 or nil))
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
			xml[xml.queue[1]].timer = timer.setTimeoutCoro(3500, fail, xml.queue[1])
			tfm:sendCommand("np " .. xml.queue[1])
		end
	end
end

local serverCommand
local hostRanking = protect(function(data, pages, indexes, msg)
	local head, body
	local ranking, counter, semicounter = { { } }, 1, 0

	for i = 1, pages do
		head, body = http.request("GET", "https://cheese.formice.com/transformice/ranking/" .. data.uri .. "/?p=" .. i)

		for value in string.gmatch(body, "<td>(.-)</td>") do
			semicounter = semicounter + 1

			ranking[counter][semicounter] = string.gsub(string.gsub(string.gsub(value, " *<.->", ''), ',', ''), "&#(%d+);", string.char)

			if semicounter == indexes then
				ranking[counter] = table.concat(ranking[counter], '\001', 2)

				semicounter = 0
				counter = counter + 1
				ranking[counter] = { }
			end
		end
	end

	ranking = os.time() .. table.concat(ranking, '\002', 1, pages * 100)

	local len, reply = #ranking
	if len > 30000 then
		reply = msg:reply("Cannot save '#" .. data.name .. "' because the space has been exceeded.")
	else
		-- player]values[player2]values
		tfm.bulleConnection:send({ 29, 21 }, transfromage.ByteArray:new():write32(data.id):writeUTF(ranking)) -- Calls eventTextAreaCallback

		reply = msg:reply("'#" .. data.name .. "' leaderboard updated!")
	end
	reply:setContent(reply.content .. " (" .. len .. "/30000)")
end)

local isPlayer = function(playerName)
	local _, body = http.request("GET", "https://atelier801.com/profile?pr=" .. encodeUrl(playerName), specialHeaders.english)

	return not string.find(body, "The request contains one or more invalid parameters")
end

local encodeTeamList = function()
	return table.concat(table.map(teamList, function(list, teamName)
		return teamName .. "{" .. table.concat(table.map(list, function(community, playerName)
			return playerName .. ";" .. community
		end), ';') .. "}"
	end))
end

local getTitle = function(titleId, gender, community, _ignoreGenderIndex)
	gender = (_ignoreGenderIndex and gender or (gender % 2 + 1))

	if type(translate[community]) == "string" then
		community = translate[community]
	end

	local title, hasGender = transfromage.Translation.get(transfromage.enum.language[(community or "en")], "T_" .. titleId)
	title = (title and (hasGender and title[gender] or title) or titleId)

	return title, hasGender
end

local addCommandActivity = function(where, command)
	local today = os.date("%d/%m/%Y")
	if not commandActivity[today] then
		commandActivity[today] = {
			[1] = { }, -- Game
			[2] = { } -- Server
		}
	end

	where = (where == "game" and 1 or 2)
	where = commandActivity[today][where]
	where[command] = (where[command] or 0) + 1
	saveActivity = true
end

local generateModulesBbcode
do
	local header = "[font=monospace][size=13][table]\n[row][cel][color=#E6B57E][b]$bbcodeCommunity[/b][/color][p][/cel][cel]     [/cel][cel][color=#E6B57E][b]Module[/b][/color][/cel][cel]     [/cel][cel][color=#E6B57E][b]$bbcodeLevel[/b][/color][/cel][cel]     [/cel][cel][color=#E6B57E][b]$bbcodeHoster[/b][/color][/cel] 	[/row]"
	-- flag, module name, [/p], level, encoded hoster name, hoster
	local row = "[row][cel][img]https://atelier801.com/img/pays/%s.png[/img][/cel][cel]     [/cel][cel][color=#6C77C1]#%s[/color]%s[/cel][cel]     [/cel][cel][color=#CCCCDD]%s[/color][/cel][cel]     [/cel][cel]%s[/cel] 	[/row]"
	local hosterName = "[url=https://atelier801.com/profile?pr=%s[&&]%s][color=#8FE2D1]%s[size=11][color=#606090]#%s[/color][/size][/color][/url]"

	local getHosterName = function(name)
		local name, discriminator = string.sub(name, 1, -6), string.sub(name, -4)
		return string.format(hosterName, name, discriminator, name, discriminator)
	end

	generateModulesBbcode = function(listAll)
		-- Generates bbcode
		local index, bbcode = 1, { header }

		local srcData
		if not listAll then
			srcData = { }
			local index = 0

			for i = 1, #modules do
				moduleData = modules[i]

				if not moduleData.isPrivate then
					index = index + 1
					srcData[index] = moduleData
				end
			end
		else
			srcData = modules
		end

		local moduleData, community, isMtMember
		for i = 1, #srcData do
			moduleData = srcData[i]

			isMtMember = teamList.mt[moduleData.hoster]

			community = (not moduleData.isPrivate and isMtMember or "xx")
			community = countryCodeConverted[community] or community

			index = index + 1
			bbcode[index] = string.format(row, string.lower(community), moduleData.name,
				((srcData[i + 1] and string.sub(srcData[i + 1].name, 1, 1) ~= string.sub(moduleData.name, 1, 1)) and "[/p]" or ''),
				(moduleData.isDisabled and "$bbcodeDisabled" or moduleData.isOfficial and "$bbcodeOfficial" or "$bbcodeSemiOfficial"),
				((not isMtMember and not listAll) and '-' or getHosterName(moduleData.hoster))
			)
		end

		index = index + 1
		bbcode[index] = "[/table][/size][/font]"

		return table.concat(bbcode, "\n")
	end
end

local updateModulesForumMessage
do
	local forum
	updateModulesForumMessage = function(message, listName, location, newList, connect, disconnect, nickname, password)
		message:reply("Starting update: " .. listName)

		if connect then
			forum = fromage()
			forum.connect(nickname, password)
		end

		if forum.isConnected() then
			message:reply("[" .. listName .. "] Connected")

			local tentative, forumMsg, errMsg = 0
			repeat
				tentative = tentative + 1
				forumMsg, errMsg = forum.getMessage(1, location)
			until forumMsg or tentative > 5
			if errMsg then
				error("[" .. listName .. "] GET: " .. tostring(errMsg), transfromage.enum.errorLevel.low)
			end

			local i, e = string.find(forumMsg.content, "%[table%].-%[/table%]")
			forumMsg.content = string.sub(forumMsg.content, 1, i - 1) .. newList .. string.sub(forumMsg.content, e + 1)

			local editMessage
			tentative = 0
			repeat
				tentative = tentative + 1
				editMessage, errMsg = forum.editAnswer(forumMsg.id, forumMsg.content, location)
			until editMessage or tentative > 5
			if errMsg then
				error("[" .. listName .. "] POST: `" .. tostring(errMsg) .. "`", transfromage.enum.errorLevel.low)
			end

			message:reply(string.format("[%s] https://atelier801.com/topic?f=%d&t=%s `%s`", listName, location.f, location.t, tostring(editMessage)))
		else
			error("[" .. listName .. "] CONNECT: Connection failed.", transfromage.enum.errorLevel.low)
		end

		if disconnect then
			forum.disconnect()
			message:reply("[" .. listName .. "] Connection closed")
			forum = nil
		end
	end
end

-- Commands
local chatHelpSource, whisperHelpSource, memberHelpSource
local commandWrapper, chatCommand, whisperCommand, serverCommand, fastReplyCommand
do
	local help = function(src, param, level, language, prefix, includePriv)
		language = language or "en"
		prefix = prefix or ','

		local cmdList = (level == 0 and chatCommand or level == 1 and whisperCommand or (level == 2 or level == 3) and serverCommand)
		if param then
			param = string.lower(param)
			if string.sub(param, 1, 1) == prefix then
				param = string.sub(param, 2)
			end

			if commandWrapper[param] then
				return "'" .. prefix .. param .. "' → " .. translate(language, tostring(commandWrapper[param]))
			elseif cmdList[param] and (level ~= 3 or not cmdList[param].priv) then
				return "'" .. prefix .. param .. "' → " .. (cmdList[param].auth and ("[<@&" .. cmdList[param].auth .. "> only] ") or cmdList[param].owner and ("[Bot owner only] ") or '') .. translate(language, tostring(cmdList[param]))
			end
			return translate(language, "$nocmd", prefix .. param)
		end

		-- Lists all commands
		local cmds, counter = { }, 0
		for c = 1, #src do
			c = src[c]
			if includePriv or not cmdList[c] or (not cmdList[c].priv and not cmdList[c].maintenance) then -- there might be cmdWrap+other
				counter = counter + 1
				cmds[counter] = prefix .. c
			end
		end

		return translate(language, "$hlist", prefix .. "help", prefix, table.concat(cmds, " | "))
	end

	local teams = {
		mt = { "Module Team", "https://goo.gl/ZJcnhZ" },
		--fs = { "Fashion Squad", "http://bit.ly/2I1FY4d" },
		sh = { "Shades Helper", "https://discord.gg/quch83R" },
		mc = { "Mapcrew", "https://goo.gl/forms/V11VIzC68yCMzKSH3" }
	}
	local teamAliases = { }
	-- MT
	teamAliases.moduleteam = "mt"
	teamAliases["module team"] = "mt"
	teamAliases.lua = "mt"
	teamAliases.luateam = "mt"
	teamAliases.luadev = "mt"
	teamAliases.dev = "mt"
	-- FS
	--teamAliases.fashionsquad = "fs"
	--teamAliases["fashion squad"] = "fs"
	--teamAliases.fashion = "fs"
	-- SH
	teamAliases.helper = "sh"
	teamAliases.shades = "sh"
	teamAliases.shelper = "sh"
	teamAliases["shades helper"] = "sh"
	teamAliases["shade helper"] = "sh"
	-- MC
	teamAliases.mapcrew = "mc"
	teamAliases.map = "mc"

	-- Whisper, Server
	local c_mt = {
		h = "$mt",
		f = createListCommand(" module_team")
	}
	local c_fs = {
		h = "$fs",
		f = createListCommand(" fashion_squad")
	}
	local c_fc = {
		h = "$fc",
		f = createListCommand(" funcorp")
	}
	local c_sent = {
		h = "$sent",
		f = createListCommand(" sentinel")
	}
	local c_sh = {
		h = "$sh",
		f = createListCommand(" shades_helpers", true)
	}
	local c_fla = {
		h = "$fla",
		f = createListCommand(" flash_squad")
	}
	local c_bot = {
		h = "$bot",
		f = createListCommand(" bot")
	}
	local c_evt = {
		h = "$evt",
		f = createListCommand(" event_squad")
	}

	commandWrapper = { -- playerCommunity, param, target, isChatCommand
		["luadoc"] = {
			link = true,
			h = "$hdoc",
			f = function(playerCommunity)
				return translate(playerCommunity, "$doc", "https://atelier801.com/topic?f=5&t=451587&p=1#m3")
			end
		},
		["apply"] = {
			link = true,
			h = "$happ ',apply $team'",
			f = function(playerCommunity, param)
				if param then
					param = string.lower(param)
					local d = teams[param] or (teamAliases[param] and teams[teamAliases[param]])
					return (d and translate(playerCommunity, "$app", d[1], d[2]) or translate(playerCommunity, "$noapp"))
				else
					return translate(playerCommunity, "$ateam", "apply", table.concat(table.map(teams, function(value)
						return value[1]
					end), " | "))
				end
			end
		},
		["bgcolor"] = {
			h = "$hbgcolor",
			f = function(playerCommunity)
				return translate(playerCommunity, "$bgcolor", "#6A7495")
			end
		}
	}
	chatCommand = { -- playerCommunity, target, playerName, param
		["help"] = {
			h = "$help",
			f = function(playerCommunity, channelName, _, parameters)
				tfm:sendChatMessage(channelName, translate(playerCommunity, "$nohelp", "help"))
			end
		}
	}
	whisperCommand = { -- playerCommunity, isDebugging(4 #shadestest), playerName, Param
		["help"] = {
			h = "$help",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				return help(whisperHelpSource, parameters, 1, playerCommunity)
			end
		},
		["comando"] = {
			priv = true,
			h = "$help",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				return help(whisperHelpSource, parameters, 1, playerCommunity)
			end
		},
		["about"] = {
			h = "$info",
			f = function(playerCommunity, isDebugging, playerName)
				return translate(playerCommunity, "$about", "Fifty Shades of Lua", "discord.gg/quch83R", "Bolodefchoco#0015")
			end
		},
		["dischelpers"] = {
			h = "$helper",
			f = function(playerCommunity, isDebugging, playerName)
				local online, counter = { }, 0
				for member in settingChannel.discussion.members:findAll(function(member) return member.status ~= "offline" end) do
					if helper[member.id] then
						counter = counter + 1
						online[counter] = "[" .. helper._commu[member.id] .. "] " .. member.tag .. " (" .. helper[member.id] .. ")"
					end
				end
				table.sort(online, function(m1, m2)
					return string.match(m1, "%b()$") < string.match(m2, "%b()$")
				end)

				-- Counts by bytes because of Blank's nickname that is handled wrong by TFM.
				return (#online == 0 and translate(playerCommunity, "$nohelper") or translate(playerCommunity, "$onhelper", table.concat(online, ", "))), true
			end
		},
		["dressroom"] = {
			link = true,
			h = "$dress",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				dressroom[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["makebot"] = {
			link = true,
			h = "$make",
			f = function(playerCommunity, isDebugging, playerName)
				return translate(playerCommunity, "$dmake", "discord.gg/qmdryEB")
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh,
		["title"] = {
			h = "$title",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				checkTitles[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["rank"] = {
			h = "$hrank",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				local answer = translate(playerCommunity, "$interr")

				local head, body = http.request("GET", "https://cheese.formice.com/api/players/" .. parameters:gsub("#", "-", 1))
				if head.code ~= 200 then
					return answer
				end
				body = json.decode(body)

				head, body = http.request("GET", "https://cheese.formice.com/api/position/stats?value=" .. body.stats.score.stats)
				if head.code ~= 200 then
					return answer
				end
				body = json.decode(body)

				if not body.position then
					return translate(playerCommunity, "$norank", parameters)
				end

				return translate(playerCommunity, "$rank", parameters, body.position)
			end
		},
		--[[["rank"] = {
			priv = true,
			h = "$hrank",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				return translate(playerCommunity, "$hrank")
			end
		},]]
		["inv"] = {
			h = "$inv",
			f = function(playerCommunity, isDebugging, playerName)
				return "'Fifty Shades of Lua' discord server link → discord.gg/quch83R"
			end
		},
		["rewards"] = {
			h = "$rewards",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if (rewardsCooldown[playerName] and (rewardsCooldown[playerName] > os.time())) then
					return translate(playerCommunity, "$cooldown")
				end

				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				checkAvailableRewards[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["mapcrew"] = {
			h = "$mapcrew",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				mapcrewList[#mapcrewList + 1] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity, parameters = parameters }
				tfm:sendCommand("mapcrew")
			end
		},
		["mapcat"] = {
			priv = true,
			h = "Manages the map categories a Mapcrew currently reviews. [Mapcrew only]",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				local result

				if not mapcrewData[playerName] and playerName:sub(-4) ~= "0020" then
					return translate(playerCommunity, "$notmapcrew")
				end
				if not parameters then
					return "Syntax: \"mapcat [add/rem/set]* [nickname] [PX...]*\" | \"mapcat delmc [nickname]\". Your nickname is the default nickname argument."
				end

				parameters = string.lower(parameters)

				local method = string.match(parameters, "%f[%w]add%f[%W]") or string.match(parameters, "%f[%w]rem%f[%W]") or string.match(parameters, "%f[%w]set%f[%W]") or string.match(parameters, "%f[%w]delmc%f[%W]")
				if not method then
					return "You must use one of the following methods: add - rem - set - delmc"
				end
				local isDel = (method == "delmc")

				local list = string.split2(parameters, "p(%d%d?)[%-,/ ]?")
				local totalCategories = #list
				if not isDel and totalCategories == 0 then
					return "You must include at least one category (PX) in order to use the method " .. method
				end
				local set = table.set(list)

				local nickname = string.match(parameters, "%+?%a[%w_][%w_]+#%d%d%d%d")
				nickname = nickname and string.toNickname(nickname) or playerName

				local isNewMapcrew = false
				if not mapcrewData[nickname] then
					isNewMapcrew = true
					mapcrewData[nickname] = {
						set = { },
						arr = { }
					}
				end

				local effective = false
				if isDel then
					if nickname == "Bolodefchoco#0015" then
						result = "You cannot delete this member."
					else
						if not mapcrewData[nickname] then
							return "'" .. nickname .. "' is not a MapCrew."
						end

						effective = true
						mapcrewData[nickname] = nil

						result = nickname .. " has been deleted from the Mapcrew list."
					end
				elseif method == "set" then
					effective = true
					mapcrewData[nickname] = { set = set, arr = list }

					result = nickname .. "'s list has been updated to: P" .. table.concat(list, ", P")
				else
					local data = mapcrewData[nickname]

					if method == "add" then
						local initArrLen = #data.arr
						local arrLen = initArrLen

						for p = 1, totalCategories do
							p = list[p]
							if not data.set[p] then
								effective = true

								data.set[p] = true
								arrLen = arrLen + 1
								data.arr[arrLen] = p
							end
						end

						if effective then
							result = "Added the following categories to " .. nickname .. ": P" .. table.concat(data.arr, ", P", initArrLen + 1, arrLen)
						end
					elseif method == "rem" then
						local removed, counter = { }, 0
						local arrLen = #data.arr

						for p = 1, totalCategories do
							p = list[p]
							if data.set[p] then
								effective = true

								data.set[p] = nil

								for px = 1, arrLen do
									if data.arr[px] == p then
										counter = counter + 1
										removed[counter] = table.remove(data.arr, px)
										arrLen = arrLen - 1
										break
									end
								end
							end
						end

						if effective then
							result = "Removed the following categories from " .. nickname .. ": P" .. table.concat(removed, ", P")
						end
					end
				end

				if effective then
					if mapcrewData[nickname] then
						table.sort(mapcrewData[nickname].arr)
					end
					coroutine.wrap(function()
						object.shadestest:send("<@" .. disc.owner.id .. "> **" .. playerName .. "** → ,mapcat " .. parameters .. "\nsaved: " .. tostring(saveDatabase("mapcrewMembers", mapcrewData)))
					end)()
				else
					if isNewMapcrew then
						mapcrewData[nickname] = nil
					end
				end

				return result
			end
		},
		["newtitles"] = {
			h = "$hnewtitles",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				playerCommunity = transfromage.enum.language[(playerCommunity or "en")]
				if not translate[playerCommunity] then
					playerCommunity = "en"
				end

				local latestTitles, index, t = { }, 0
				for i = 999, 400, -1 do
					t = transfromage.Translation.get(playerCommunity, "T_" .. i)
					if t then
						index = index + 1
						latestTitles[index] = string.format("[%s] «%s»", i, t[1] or t)

						if index == 5 then break end
					end
				end
				return translate(playerCommunity, "$newtitles", table.concat(latestTitles, " - "))
			end
		},
		["@bolo"] = {
			priv = true,
			f = function(playerCommunity, isDebugging, playerName, parameters)
				local commu, room = parameters:match("room glitch (%S+) (.+)")
				if commu then
					commu = commu:lower()
					if commu == "xx" then
						commu = "int"
					end
					room = commu .. "-" .. room
					local msg = object.shadestest:send("/fixevt " .. room)
					serverCommand["fixevt"].f(msg, room)
					return "On my way!"
				end
			end
		},
		["flashsquad"] = c_fla,
		["bots"] = c_bot,
		["eventsquad"] = c_evt,
		["luaevent"] = {
			h = "$luaevent",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if not luaEventTime then return end
				return translate(playerCommunity, "$luaEventTime", luaEventTime)
			end
		}
	}
	whisperCommand["@bolodefchoco"]=whisperCommand["@bolo"]
	whisperCommand["@bolodefchoco#0015"]=whisperCommand["@bolo"]
	whisperCommand["@lautenschlager"]=whisperCommand["@bolo"]
	whisperCommand["@lautenschlager#2555"]=whisperCommand["@bolo"]
	serverCommand = { -- message, param
		["help"] = {
			h = "Displays the available commands / the commands descriptions.",
			f = function(message, parameters)
				local isPriv = (message.channel.category and message.channel.category.id == categoryId)
				toDelete[message.id] = message:reply({
					content = (string.gsub(help(memberHelpSource, parameters, (isPriv and 2 or 3), "en", ';', isPriv), '\'', '`')),
					allowed_mentions = { parse = { } }
				})
			end
		},
		["who"] = {
			priv = true,
			h = "Displays a list of who is in the chat.",
			f = function(message)
				if message.channel.id == channel.whisper then
					toDelete[message.id] = message:reply(":warning: This is not a #channel, but the environment used to whisper players.")
				else
					tfm:chatWho(channel(message.channel.id))
				end
			end
		},
		["mod"] = {
			h = "Displays the list of online Moderators.",
			f = function(message)
				modList[#modList + 1] = message
				tfm:sendCommand("mod")
			end
		},
		["mapcrew"] = {
			h = "Displays the list of online Mapcrew and their respective categories.",
			f = function(message)
				mapcrewList[#mapcrewList + 1] = message
				tfm:sendCommand("mapcrew")
			end
		},
		["time"] = {
			priv = true,
			h = "Displays the connection and account's time.",
			f = function(message)
				timeCmd[message.channel.id] = true
				tfm:sendCommand("time")
			end
		},
		["rooms"] = {
			h = "Displays the room list of official modules",
			f = function(message)
				modulesCmd[message.channel.id] = true
				tfm:requestRoomList(transfromage.enum.roomMode.module)
			end
		},
		["bolo"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Refreshes #bolodefchoco→\3*Editeur",
			f = function(message)
				message:reply("Refreshing #bolodefchoco→\3*Editeur")
				tfm:sendCommand("module bolodefchoco")
			end
		},
		["isonline"] = {
			h = "Checks whether a player is online or not.",
			f = function(message, parameters)
				if not parameters then return end
				parameters = string.toNickname(parameters, true)
				tfm:sendRoomMessage(parameters .. " get_user " .. parameters)
				onlinePlayer[parameters] = message.channel.id
			end
		},
		["map"] = {
			h = "Gets the image of the map specified.",
			f = function(message, parameters, _xmlOnly)
				if not parameters or not string.find(parameters, "^@?%d%d%d%d+$") then return end
				if parameters:sub(1,1) ~= '@' then
					parameters = "@" .. parameters
				end

				if xml[parameters] then
					toDelete[message.id] = message:reply("<@" .. message.author.id .. ">, the map **" .. parameters .. "** already is in the queue.")
					return
				end

				local len = #xml.queue + 1
				xml.queue[len] = parameters
				xml[parameters] = { message = message, _xmlOnly = _xmlOnly }

				if len == 1 then
					loadXmlQueue()
				else
					local time = 8 * (len - 1)
					xml[parameters].reply = message:reply("<@" .. message.author.id .. ">, your request is in the position #" .. len .. " and will be executed in ~" .. time .. " seconds!")
				end
			end
		},
		["xml"] = {
			auth = "462329326600192010",
			allowMember = true,
			h = "Gets the XML of the map specified.",
			f = function(message, parameters)
				serverCommand["map"].f(message, parameters, true)
			end
		},
		["clear"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Clears the cache of the tables.",
			f = function(message, _, ignoreFixEvt)
				xml = { queue = { } }
				onlinePlayer = { }
				for k, v in next, srcMemberListCmd do
					v._loading = ''
					v._queue = { }
					v._timer = 0
				end
				cachedTeamListDisplay = { }
				rewardsCooldown = { }
				avatars = { }
				if not ignoreFixEvt then
					fixEvtInUse = false
				end
				message:reply("Cleared cache")
			end
		},
		["invth"] = {
			priv = true,
			owner = true,
			h = "Invites Bolo to the tribe house.",
			f = function(message)
				message:reply("Inviting")
				tfm:sendCommand("inv Bolodefchoco#0015")
			end
		},
		["goto"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Changes the Bot room.",
			f = function(message, parameters)
				if not parameters then return end
				parameters = string.gsub(parameters, '`', '')

				if parameters == "tribe" then
					tfm:joinTribeHouse()
					message:reply("Joined *\3Editeur!")
				else
					tfm:enterRoom(parameters)
					message:reply("Joined room **" .. parameters .. "**")
				end
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["tfmprofile"] = {
			h = "Displays the profile of a user in real time. (User required to be online)",
			f = function(message, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
					profile[parameters] = message.channel.id
					tfm:sendCommand("profile " .. parameters)
				else
					toDelete[message.id] = message:reply("Invalid nickname '" .. tostring(parameters) .. "'")
				end
			end
		},
		["rank"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Updates the database of `#bolodefchoco0ranking` and `#bolodefchoco0triberanking`.",
			f = function(message, parameters)
				parameters = tonumber(parameters) or 2

				local msg = message:reply("Saving leaderboards")
				-- Updates the module #bolodefchoco.ranking
				if not hostRanking({
					uri = "mice",
					name = "ranking",
					id = 4
				}, parameters, 8, msg) then
					msg:reply("Failed to update '#ranking'")
				end

				timer.setTimeoutCoro(8000, tfm.sendCommand, tfm, "module bolodefchoco") -- resets to avoid the 1min limite

				-- Updates the module #bolodefchoco.ranking
				timer.setTimeoutCoro(12000, function(msg)
					if not hostRanking({
						uri = "tribes",
						name = "triberanking",
						id = 5
					}, parameters, 7, msg) then
						msg:reply("Failed to update '#triberanking'")
					end
				end, msg)
			end
		},
		["mem"] = {
			priv = true,
			owner = true,
			h = "Checks the current memory usage.",
			f = function(message)
				message:reply(tostring(collectgarbage("count")))
				collectgarbage()
				message:reply(tostring(collectgarbage("count")))
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh,
		["friend"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Adds a player.",
			f = function(message, parameters)
				tfm:addFriend(string.toNickname(parameters, true))
			end
		},
		["unfriend"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Adds a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				friendRemoval = parameters
				tfm:removeFriend(parameters)
			end
		},
		["block"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Blacklists a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				tfm:blacklistPlayer(parameters)
				settingChannel.discussion:send("@here " .. parameters .. " blacklisted.")
			end
		},
		["unblock"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Whitelists a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				tfm:whitelistPlayer(parameters)
				settingChannel.discussion:send("@here " .. parameters .. " whitelisted.")
			end
		},
		["lua"] = {
			priv = true,
			owner = true,
			h = "Executes lua using the bot environment.",
			f = function(message, parameters)
				-- Chunks from @Modulo
				if not parameters or #parameters < 3 then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end

				local foo
				foo, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

				if not parameters or #parameters == 0 then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end

				local lua_tag, final = string.find(string.lower(parameters), "^lua\n+")
				if lua_tag then
					parameters = string.sub(parameters, final + 1)
				end

				local data = { }
				ENV.print = function(...)
					local content = printf(...)
					data[#data + 1] = (content ~= '' and content ~= ' ' and content ~= '\t' and content ~= '\n') and content or nil
				end
				ENV.message = message
				ENV.me = message.member
				ENV.channel = message.channel
				ENV.guild = message.guild

				local func, syntaxErr = load(parameters, '', 't', ENV)
				if syntaxErr then
					toDelete[message.id] = message:reply("Syntax error:\n```\n" .. tostring(syntaxErr) .. "```")
					return
				end

				local success, runtimeErr = pcall(func)
				if not success then
					toDelete[message.id] = message:reply("Runtime error:\n```\n" .. tostring(runtimeErr) .. "```")
					return
				end

				data = splitByLine(table.concat(data, "\n"))
				for line = 1, #data do
					toDelete[message.id] = message:reply({
						embed = {
							color = 0xFFAA00,
							description = data[line]
						}
					})
				end
			end
		},
		["blacklist"] = {
			priv = true,
			h = "Displays the bot's blacklist.",
			f = function(message)
				displayBlacklist[#displayBlacklist + 1] = message
				tfm:requestBlackList()
			end
		},
		["team"] = {
			priv = true,
			owner = false,
			h = "Manages the #bolodefchoco's teams' lists.",
			f = function(message, parameters)
				if not message then return end
				if message.channel.id ~= channel.teamTool then
					toDelete[message.id] = message:reply("You can only use this command in the <#" .. channel.teamTool .. "> channel.")
					return
				end

				local action = (parameters and string.match(parameters, "^(%S+)"))
				action = action and string.lower(action)

				if action == "save" then
					if message.author.id ~= disc.owner.id then
						if not teamListHasBeenChanged then
							toDelete[message.id] = message:reply("Nothing has been edited in the teams' lists.")
							return
						end

						local time = os.time()
						if time < teamListFileTimer then
							toDelete[message.id] = message:reply("You can only save the teams' list once per minute. [" .. (time - teamListFileTimer) .. "].")
							return
						end
					end

					local hasSaved = saveDatabase("teamList", teamList)
					message:reply("Saved in database: " .. tostring(hasSaved))

					if not hasSaved then
						teamListHasBeenChanged = true
						message:reply("<@" .. disc.owner.id .. "> ↑")
						return
					end

					local teamListEncoded = encodeTeamList()
					-- team{name;commu;name;commu}
					tfm.bulleConnection:send({ 29, 21 }, transfromage.ByteArray:new():write32(3):writeUTF(teamListEncoded)) -- Calls eventTextAreaCallback

					message:reply("Sending data to #bolodefchoco (" .. #teamListEncoded .. "/30000)")

					teamListHasBeenChanged = false
					teamListFileTimer = os.time() + 65
				elseif action == "rename" then
					local oldName, newName = string.match(tostring(parameters), "^rename[\n ]+(%S+)[\n ]+(%S+)$")
					if not oldName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `rename [old_name] [new_name]`")
						return
					end

					oldName = string.toNickname(oldName, true)
					newName = string.toNickname(newName, true)

					local community
					for teamName, list in next, teamList do
						community = list[oldName]
						if community then
							if teamName == "sent" and newName:sub(-4)*1 > 15 then
								serverCommand["team"](message, "sent rem " .. oldName)
							else
								list[oldName] = nil
								list[newName] = community
								teamListHasBeenChanged = true

								message:reply("The player `" .. oldName .. "` has been renamed to `" .. newName .. "` in team `" .. teamName .. "`.")
							end
						end
					end
				else
					local teamName, method, names = string.match(tostring(parameters), "^(%S+)[\n ]+(...)[\n ]+(.+)")
					if not teamName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[team_name] [add] [name=community] [...]` | `[team_name] [rem] [name] [...]`")
						return
					end

					teamName = string.lower(teamName)
					if not teamList[teamName] then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `teamName` (Should be `" .. table.concat(table.keys(teamList), "`, `") .. "`).")
						return
					end

					method = string.lower(method)
					local isAdd = method == "add"
					local isRem = method == "rem"

					if not (isAdd or isRem) then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `method` (Should be `add`, `rem`).")
						return
					end

					if #names < 6 then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `names`.")
						return
					end

					local isContinue, community = false
					names = string.split(names, "%s")

					local validNames, counter = { }, 0

					for name = 1, #names do
						isContinue = true
						repeat
							if isRem then
								name = string.toNickname(names[name], true)

								if not teamList[teamName][name] then
									toDelete[message.id] = message:reply("The player `" .. name .. "` is not in the `" .. teamName .. "` members's list.")
									break
								end

								isContinue = false
								teamList[teamName][name] = nil

								message:reply("Player `" .. name .. "` removed from `" .. teamName .. "`.")
							else
								if string.sub(names[name], -3, -3) ~= '=' then
									toDelete[message.id] = message:reply("Invalid syntax. Player names should be followed by the community, as in `Bolo#0000=BR`.")
									break
								end

								community = string.upper(string.sub(names[name], -2))
								name = string.toNickname(string.sub(names[name], 1, -4), true)

								if not transfromage.enum.language[string.lower(community)] and message.author.id ~= disc.owner.id then
									toDelete[message.id] = message:reply("Invalid community `" .. community .. "` for the player `" .. name .. "`.")
									break
								end

								if teamList[teamName][name] then
									toDelete[message.id] = message:reply("The player `" .. name .. "` already is in the `" .. teamName .. "` members's list.")
									break
								end

								if not isPlayer(name) then
									toDelete[message.id] = message:reply("The player `" .. name .. "` could not be found.")
									break
								end

								isContinue = false
								teamList[teamName][name] = community

								message:reply("Player `" .. name .. " [" .. community .. "]` added to `" .. teamName .. "`.")
							end
						until true

						if not isContinue then
							counter = counter + 1

							if community then
								name = name .. " [" .. community .. "]"
							end

							validNames[counter] = name
						end
					end

					if counter > 0 then
						teamListHasBeenChanged = true
						cachedTeamListDisplay[teamName] = nil
						message:reply("**[Success]** " .. method .. " => `" .. table.concat(validNames, "`, `") .. "`")
					end
				end
			end
		},
		["ls"] = {
			h = "Displays all members of a specific team. You can also add a flag and/or pattern in the command for filtering.",
			f = function(message, parameters)
				parameters = string.gsub(tostring(parameters), "[\n ]........", countryFlags, 1)
				parameters = string.lower(parameters)

				local teamName = tostring(string.match(parameters, "^(%S+)"))
				local commu = string.match(parameters, "[\n ]+:f?l?a?g?_?(%S+):[\n ]*")
				local pattern = string.match(parameters, "[\n ]+([^:]+)[\n ]*")

				if not teamList[teamName] then
					toDelete[message.id] = message:reply("Invalid team name. The available teams are: `" .. table.concat(table.keys(teamList), "`, `") .. "`")
					return
				end

				if not cachedTeamListDisplay[parameters] then -- uses commu and pattern, not the best solution but it's faster
					local fields, fieldCounter = { { } }, 1

					local totalCounter = 0

					commu = (commu and string.lower(commu))

					local nameCounter, formatCommu = 0
					for playerName, community in pairsByIndexes(teamList[teamName]) do
						formatCommu = countryCodeConverted[community]
						formatCommu = (formatCommu and string.lower(formatCommu))
						community = string.lower(community)

						if (not commu or commu == community or commu == formatCommu) and (not pattern or string.find(string.lower(playerName), pattern)) then
							nameCounter = nameCounter + 1

							totalCounter = totalCounter + 1
							fields[fieldCounter][nameCounter] = ":flag_" .. (formatCommu or community) .. ": " .. " " .. playerName

							if nameCounter == 26 then
								nameCounter = 0
								fieldCounter = fieldCounter + 1
								fields[fieldCounter] = { }
							end
						end
					end

					if totalCounter == 0 then
						fieldCounter = 1
						fields[1][1] = "N/A"
					end

					for i = 1, fieldCounter do
						if #fields[i] == 0 then break end
						fields[i] = {
							name = '‌',
							value = string.gsub(remDefaultDiscriminator(table.concat(fields[i], "\n"), true), "#%d+", "`%1`"),
							inline = true
						}
					end

					cachedTeamListDisplay[parameters] = { }
					local abvAction = teamListAbbreviated[teamName]
					local title = (string.gsub(abvAction, "%u", " %1") .. " [" .. totalCounter .. "]")
					local description = (commu or '') .. "; " .. (pattern or '')
					description = (description ~= "; " and description or nil)

					local counter = 0
					for i = 1, fieldCounter, 6 do
						counter = counter + 1
						cachedTeamListDisplay[parameters][counter] = {
							embed = {
								color = roleColors[abvAction],
								title = (counter == 1 and title or nil),
								description = (counter == 1 and description or nil),
								fields = table.arrayRange(fields, i, i + 5)
							}
						}
					end
				end

				local messages = { }
				for i = 1, #cachedTeamListDisplay[parameters] do
					messages[i] = message:reply(cachedTeamListDisplay[parameters][i])
				end
				toDelete[message.id] = messages
			end
		},
		["fix"] = {
			priv = true,
			auth = "585148219395276801",
			h = "Fixes tribe house.",
			f = function(message, parameters, skipRoom)
				if not skipRoom then
					serverCommand["goto"](message, getRandomTmpRoom())
				end
				timer.setTimeoutCoro(4000, serverCommand["goto"].f, message, "tribe")
				timer.setTimeoutCoro(4000 + 2500, serverCommand["clear"].f, message, false, true)
				timer.setTimeoutCoro(4000 + 2500 + 500, serverCommand["bolo"].f, message, tribe)
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500, message.reply, message, "Checking fix:")
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500 + 2500, serverCommand["moduleteam"].f, message)
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500 + 2500 + 2500, serverCommand["clear"].f, message, false, false)
			end
		},
		["module"] = {
			owner = false,
			auth = "462279926532276225",
			h = "Manages the modules lists.",
			f = function(message, parameters)
				if message.channel.id ~= channel.modulesTool then
					toDelete[message.id] = message:reply("You can only use this command in the <#" .. channel.modulesTool .. "> channel.")
					return
				end

				local action = (parameters and string.match(parameters, "^(%S+)"))
				action = action and string.lower(action)

				if action == "help" then
					toDelete[message.id] = message:reply({
						embed = {
							color = 0x7AC9C4,
							title = "Modules management tool",
							fields = {
								[1] = {
									name = "Add new module hosted by a public member",
									value = "**/module add [`#?MODULE_NAME`] [HOSTER_NAME_WITH_DISCRIMINATOR] [IS\\_OFFICIAL] [IS\\_PRIVATE\\_MODULE]**\n- _IS\\_OFFICIAL_ → 0/1/2, default 0\n- _IS\\_PRIVATE\\_MODULE_ → 0/1, default 0\n\nExample: ``/module add `#shaman` Bolodefchoco 0 1``"
								},
								[2] = {
									name = "Add new module hosted by a private member",
									value = "**/module addpriv [`#?MODULE_NAME`] [HOSTER_NAME_WITH_DISCRIMINATOR] [IS\\_OFFICIAL] [IS\\_PRIVATE\\_MODULE]**\n- _IS\\_OFFICIAL_ → 0/1/2, default 0\n- _IS\\_PRIVATE\\_MODULE_ → 0/1, default 0\n\nExample: ``/module addpriv `satan` Meliberules#0001 0 1``"
								},
								[3] = {
									name = "Remove module [to recreate with new names, for example]",
									value = "**/module rem [`#?MODULE_NAME`]**\n\nExample: ``/module rem `#parkour` ``"
								},
								[4] = {
									name = "Rename a member",
									value = "**/module rename [old_name] [new_name]**\n\nExample: `/module rename Bolodefchoco Bolodefchoco#0010`"
								},
								[5] = {
									name = "Change module level",
									value = "**/module level [`#?module_name`] [IS\\_OFFICIAL]**\n- _IS\\_OFFICIAL_ → 0/1\n\nExample: ``/module level `#bolodefchoco` 1``"
								}
							}
						}
					})
				elseif action == "add" or action == "addpriv" then
					local privHoster, name, hoster, isOfficial, isPrivate = string.match(tostring(parameters), "^add(p?r?i?v?)[\n ]+`?#?([^`%s]+)`?[\n ]+(%S+)[\n ]*([012]?)[\n ]*([01]?)$")
					if not name then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[add[priv]] [module_name] [hoster_name] [is_official (0)|1|2] [is_private (0)|1]`")
						return
					end
					name = string.lower(name)

					for i = 1, #modules do
						if modules[i].name == name then
							message:reply("Module `#" .. name .. "` already is in the list.")
							return
						end
					end

					hoster = string.toNickname(hoster, true)
					if not teamList.mt[hoster] and privHoster == '' then
						message:reply("Player `" .. hoster .. "` is not a (public) module team member.")
						return
					end

					local isDisabled = isOfficial == '2'
					isOfficial = isOfficial == '1'
					isPrivate = isPrivate == '1'

					local moduleData = {
						isOfficial = isOfficial,
						isPrivate = isPrivate,
						isDisabled = isDisabled,
						name = name,
						hoster = hoster
					}

					-- Prevents a table.sort
					for i = 1, #modules do
						if modules[i].name > name then
							table.insert(modules, i, moduleData)
							moduleData = nil
							break
						end
					end
					if moduleData then
						modules[#modules + 1] = moduleData
					end

					message:reply("Module `[" .. (teamList.mt[hoster] or "xx") .. "]` `#" .. name .. "` - `" .. hoster .. "` added to the list. (" .. tostring(isOfficial) .. ", " .. tostring(isPrivate) .. ", " .. tostring(isDisabled) .. ")")
				elseif action == "rem" then
					local name = string.match(tostring(parameters), "^rem[\n ]+`?#?([^`%s]+)`?$")
					if not name then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[rem] [module_name]`")
						return
					end
					name = string.lower(name)

					for i = 1, #modules do
						if modules[i].name == name then
							table.remove(modules, i)
							message:reply("Module `#" .. name .. "` removed from the list.")
							return
						end
					end

					message:reply("Module `#" .. name .. "` not found.")
				elseif action == "rename" then
					local oldName, newName = string.match(tostring(parameters), "^rename[\n ]+(%S+)[\n ]+(%S+)$")
					if not oldName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[rename] [old_name] [new_name]`")
						return
					end
					oldName = string.toNickname(oldName, true)
					newName = string.toNickname(newName, true)

					local replaced = false
					for i = 1, #modules do
						if modules[i].hoster == oldName then
							replaced = true
							modules[i].hoster = newName
							message:reply("Updated `#" .. modules[i].name .. "`'s hoster to `" .. newName .. "`.")
						end
					end

					if not replaced then
						message:reply("No modules found to `" .. oldName .. "`.")
					end
				elseif action == "level" then
					local name, level = string.match(tostring(parameters), "^level[\n ]+`?#?([^`%s]+)`?[\n ]+([012])$")
					if not level then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[level] [module_name] [is_official]`")
						return
					end
					name = string.lower(name)
					level = tonumber(level)

					local edited = false
					for i = 1, #modules do
						if modules[i].name == name then
							edited = true
							modules[i].isOfficial = level == 1
							modules[i].isDsabled = level == 2
							message:reply("Updated `#" .. name .. "`'s is_official level to `" .. tostring(level) .. "`.")
						end
					end

					if not edited then
						message:reply("No modules found to `" .. name .. "`.")
					end
				elseif message.author.id == disc.owner.id then
					if action == "write" then -- Writes generated list in forum topics
						-- Generates bbcode
						local limitedBbcode = generateModulesBbcode()
						local nonPrivBbcode = generateModulesBbcode(true)

						local enOfficialBbcode = string.gsub(translate("en", nonPrivBbcode), "%[&&%]", "%%23")
						local enPlayerBbcode = string.gsub(translate("en", limitedBbcode), "%[&&%]", "%%23")
						local brPlayerBbcode = string.gsub(translate("br", limitedBbcode), "%[&&%]", "%%23")

						-- Update EN-Player
						updateModulesForumMessage(message, "EN-Player", { f = 6, t = 892566 }, enPlayerBbcode, true, false, DATA[6], DATA[7])
						updateModulesForumMessage(message, "BR-Player", { f = 6, t = 877916 }, brPlayerBbcode, false, true, DATA[6], DATA[7])
						updateModulesForumMessage(message, "EN-Official", { f = 6, t = 876591 }, enOfficialBbcode, true, true, DATA[6], DATA[7])
					elseif action == "save" then
						-- Saves in database
						message:reply("Saved in database: " .. tostring(saveDatabase("modules", modules)))
					end
				end
			end
		},
		--[=[["getavatar"] = {
			priv = true,
			owner = true,
			h = "Collects all avatars of players in a room.",
			f = function(message, parameters)
				if not parameters then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end
				parameters = string.gsub(parameters, '`', '')

				avatars = { }
				AVATAR_TIME = 0

				tfm:handlePlayers(true)
				tfm:enterRoom(parameters)
			end
		},]=]
		["triggerfor"] = {
			priv = true,
			h = "Triggers a whisper command for a player.",
			f = function(message, parameters)
				parameters = string.split(parameters, "%s")
				if not whisperCommand[parameters[2]] then return end
				whisperCommand[parameters[2]]("en", false, parameters[1], table.concat(parameters, " ", 3))
			end
		},
		["fixevt"] = {
			priv = true,
			owner = true,
			h = "/module stop in a room.",
			f = function(message, parameters)
				if fixEvtInUse then
					return timer.setTimeoutCoro(5000, serverCommand["fixevt"].f, message, parameters)
				end
				fixEvtInUse = true

				tfm:handlePlayers(true)

				message:reply("Going to " .. parameters)
				tfm:sendCommand("room* " .. parameters)

				local shamanName

				message:reply("Waiting for shaman")
				local received, list = tfm:waitFor("refreshPlayerList", 1000)

				if received then
					shamanName = false

					for _, player in pairs(list) do
						if player.isShaman then
							shamanName = player.playerName
							break
						end
					end

					if shamanName then
						message:reply("Shaman found: " .. shamanName)
					end
				end

				if shamanName == false then
					message:reply("Waiting for map info")
					local received, map = tfm:waitFor("newGame", 1000)

					if not received then
						map = tfm.room.map
					end

					if map then
						message:reply("Map info received. @" .. tostring(map.code) .. " - P" .. tostring(map.permCode))

						if map.permCode ~= 3 and map.permCode ~= 13
							and map.permCode ~= 7 and map.permCode ~= 17
							and map.permCode ~= 42
							and not noShamanVanilla[map.code:gsub("@", '')*1]
							and not (map.code == "@0" and map.permCode*1 == 1) then

							message:reply("Retrieving room info")
							timer.setTimeoutCoro(3000, function()
								tfm:sendCommand("roominfo")

								local received, data = tfm:waitFor("commandOutput", 1000, function(txt)
									return txt:find('\nBulle: ')
								end)

								if received then
									data = data
										:gsub("<V>(.-)</V>", "[•] %1")
										:gsub("(\n)(Bulle: )", "```\n```\n[•] %2")
									message:reply("```\n" .. data .. "```")
								end
							end)

							message:reply("Stopping module")
							timer.setTimeoutCoro(5000, tfm.sendCommand, tfm, "module stop")
						end
					end
				end

				tfm:handlePlayers(false)
				timer.setTimeoutCoro(10000, serverCommand["fix"].f, message, false, true)
			end
		},
		["doc"] = {
			owner = false,
			auth = "462279926532276225",
			h = "Manages the Lua API forum documentation.",
			f = function(message, parameters)
				if message.channel.id ~= channel.modulesTool then
					toDelete[message.id] = message:reply("You can only use this command in the <#" .. channel.modulesTool .. "> channel.")
					return
				end

				local save = false

				--[[
					doc[syntax] = {
						name = syntax,
						parameters? = { "", "" },
						description = {
							content = "",
							parameters? = {
								[n] = {
									[n] = {
										type = "",
										name = ""
									},
									description = "",
									default? = ?
								}
							},
							returns? = {
								type = "",
								description = ""
							}
						}
					}
				]]

				local action = (parameters and string.match(parameters, "^(%S+)"))
				if not action then return end
				action = string.lower(action)

				if action == "new" then
					local fName, fDesc, paramPos = string.match(parameters, "^new[\n ]+(%S+)[\n ]+(%b\"\")()")
					if not fName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `new function_name \"function_description\" [parameter_list [ type, name, default, description ] ] {return type, description}`")
						return
					end

					local fReturnType, fReturnDesc = parameters:match("{%s*(%S+)%s*,%s*([^}]+)%s*}")

					local struct = {
						name = fName,
						parameters = nil,
						description = {
							content = fDesc:sub(2, -2),
							parameters = nil,
							returns = fReturnType and {
								type = typeConvertion[fReturnType:lower()] or fReturnType,
								description = fReturnDesc
							} or nil
						}
					}

					local tmpParameter = parameters:match("%b[]")
					if tmpParameter then
						struct.parameters = { }
						struct.description.parameters = { }

						local parameter, counter = struct.description.parameters, 0

						local hasDefault, totalObj
						for object in tmpParameter:sub(2, -2):gmatch("%b[]") do
							object = string.split(object:sub(2, -2):gsub("^%s*(.-)%s*$", "%1"), "%s*,%s*")

							counter = counter + 1

							if object[2]:sub(1, 1) ~= "*" then
								struct.parameters[#struct.parameters + 1] = object[2]
							else
								object[2] = object[2]:sub(2)
							end

							totalObj = #object
							hasDefault = totalObj > 3 and not tostring(object[totalObj]):find(" ", 1, true)
							object[3] = table.concat(object, ", ", 3, totalObj - (hasDefault and 1 or 0))

							parameter[counter] = {
								[1] = {
									type = typeConvertion[object[1]:lower()] or object[1],
									name = object[2]
								},
								description = object[3],
								default = hasDefault and object[totalObj] or nil
							}
						end
					end

					luaDoc[fName] = struct

					save = true
				elseif action == "rem" then
					local fName = string.match(parameters, "^rem[\n ]+(%S+)$")
					if not fName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `rem function_name`")
						return
					end

					if not luaDoc[fName] then return end
					luaDoc[fName] = nil

					save = true
				elseif action == "cmd" then
					local fName = string.match(parameters, "^cmd[\n ]+(%S+)$")
					if not fName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `cmd function_name`")
						return
					end

					local object = luaDoc[fName]
					if not object then return end

					local p = ''
					if object.parameters then
						local realParameters = table.set(object.parameters)

						local parameters = object.description.parameters

						p = { }
						local tmp
						for param = 1, #parameters do
							tmp = parameters[param]
							p[param] = string.format("[%s, %s, %s%s]", tmp[1].type,
								(not realParameters[tmp[1].name] and "*" or "") .. tmp[1].name,
								tmp.description, tmp.default and (","..tmp.default) or "")
						end

						p = "[" .. table.concat(p, ", ") .. "]"
					end

					local r = ''
					if object.description.returns then
						r = "{ " .. object.description.returns.type .. ", " .. object.description.returns.description .. " }"
					end

					toDelete[message.id] = message:reply(string.format("/doc new %s %q %s %s", fName, object.description.content, p, r))
				elseif action == "get" then
					local fName = string.match(parameters, "^get[\n ]+(%S+)$")
					if not fName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `get function_name`")
						return
					end

					local object
					for name, data in next, luaDoc do
						if name:find(fName, 1, true) then
							object = data
							break
						end
					end
					if not object then return end

					local parameter = { }
					if object.parameters then
						local parameters = object.description.parameters
						local tmp, subParameters, subCounter = { }
						for i = 1, #parameters do
							tmp = parameters[i]

							subCounter = 0
							subParameters = { }

							for t = 1, #tmp do
								subCounter = subCounter + 1
								subParameters[subCounter] = string.format("`%s` **%s**", tmp[t].type, tmp[t].name)
							end

							parameter[i] = string.format("%s → %s%s", table.concat(subParameters, ", "), tmp.description,
								(tmp.default and ( " (default value = " .. tmp.default .. ")" ) or ""))
						end
						parameter = table.concat(parameter, "\n")
					end

					toDelete[message.id] = message:reply({
						embed = {
							color = 0x272792,
							title = string.format("<:atelier:458403092417740824> %s ( %s )", object.name, (object.parameters and table.concat(object.parameters, ", ") or '')),
							description = object.description.content ..
								(object.parameters and
									("\n\n**Arguments / Parameters**\n" .. parameter)
								or "") ..
								(object.description.returns and
									string.format("\n\n**Returns**\n`%s` : %s", object.description.returns.type, object.description.returns.description)
								or ""),
							footer = {
								text = "TFM API Documentation"
							}
						}
					})
				end

				if save then
					message:reply("Saved in database: " .. tostring(saveDatabase("luaDoc", luaDoc)))
				end
			end
		},
		["flashsquad"] = c_fla,
		["bots"] = c_bot,
		["eventsquad"] = c_evt,
		["sales"] = {
			h = "Displays the current sales in game.",
			f = function(message, parameters)
				if #shopSales == 0 then return end

				local time = os.time()

				local msgs, tmp = { }
				for s = 1, #shopSales do
					tmp = shopSales[s]
					tmp.content = tmp._rawContent .. string.format(tmp._rawTime, secToDate(tmp._time/1000 - time))
					msgs[s] = message:reply(tmp)
					tmp.content = nil
				end
				toDelete[message.id] = msgs
			end
		}
	}

	fastReplyCommand = {
		["%f[%w]L%W*U%W*A%W*%f[%W]"] = "$upperlua"
	}
end

chatHelpSource = table.fuse(table.keys(chatCommand), table.keys(commandWrapper))
whisperHelpSource = table.fuse(table.keys(whisperCommand), table.keys(commandWrapper))
memberHelpSource = table.keys(serverCommand)
table.sort(chatHelpSource)
table.sort(whisperHelpSource)
table.sort(memberHelpSource)
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

local outfitToString = function(data)
	local look = { }

	local obj, colors
	for i = 2, 10 do
		obj = data[i] or '0'
		colors = ''

		if obj.colors then
			colors = "_" .. table.concat(obj.colors, '+')
		end

		look[i] = (obj.id or obj) .. colors
	end

	return (data[1] or '1') .. ";" .. table.concat(look, ',', 2) ..
		(data[11] and (";" .. data[11]) or '')
end

local getCommandParameters = function(message, prefix)
	if #message < 2 then return end
	local messagePrefix, command, parameters = string.match(message, "^(" .. (prefix or ",?") .. ")(%S+)[\n ]*(.*)")
	parameters = (parameters ~= '' and parameters or nil)
	return (command and string.lower(command)), parameters, (messagePrefix ~= '')
end

local userAntiSpam = function(src, playerName, playerCommunity)
	if src.link then
		local time = os.time()
		if (userCache[playerName] and userCache[playerName] > time) then
			return translate(playerCommunity, "$spam", playerName)
		else
			userCache[playerName] = time + ANTI_SPAM_TIME
		end
	end
end

local chooseSendMethod = function(chatCond, target, returnValue, counutByByte)
	if chatCond then
		tfm:sendChatMessage(target, returnValue, nil, countByByte)
	else
		tfm:sendWhisper(target, returnValue, nil, countByByte)
	end
end

local executeCommand = function(isChatCommand, content, target, playerName, isDebugging, playerCommunity, checkCommandSimilarity)
	local returnValue, countByByte
	local cmd, param, hasPrefix = getCommandParameters(content)
	if isChatCommand and cmd == "help" and not hasPrefix then
		return false
	end

	if param == '?' and hasPrefix then
		param = cmd
		cmd = "help"
	end

	if commandWrapper[cmd] then
		returnValue = userAntiSpam(commandWrapper[cmd], playerName, playerCommunity)
		if not returnValue then -- if because "a, b = c() or d()" doesn't apply for multiple values. :s
			returnValue, countByByte = commandWrapper[cmd](playerCommunity, param, playerName, isChatCommand)
			addCommandActivity("game", cmd)
		end
		if returnValue then
			chooseSendMethod((isChatCommand or isDebugging), target, returnValue, countByByte)
		end
		return true
	else
		if isChatCommand then
			if chatCommand[cmd] then
				returnValue = userAntiSpam(chatCommand[cmd], playerName, playerCommunity)
				if not returnValue then
					returnValue, countByByte = chatCommand[cmd](playerCommunity, target, playerName, param)
					addCommandActivity("game", cmd)
				end
				if returnValue then
					tfm:sendChatMessage(target, returnValue, nil, countByByte)
				end
				return true
			end
		else
			if whisperCommand[cmd] then
				returnValue = userAntiSpam(whisperCommand[cmd], playerName, playerCommunity)
				if not returnValue then
					if whisperCommand[cmd].maintenance then
						returnValue = translate(playerCommunity, "$maintenance")
					else
						returnValue, countByByte = whisperCommand[cmd](playerCommunity, isDebugging, playerName, param)
						addCommandActivity("game", cmd)
					end
				end
				if returnValue then
					chooseSendMethod(isDebugging, target, returnValue, countByByte)
				end
				return true
			end
		end
	end

	if checkCommandSimilarity and (cmd and (hasPrefix or string.count(content, ' ') < 4)) then -- only for whisper
		local possibilities, counter = { }, 0
		for k = 1, #whisperHelpSource do
			k = whisperHelpSource[k]
			if (whisperCommand[k] and not whisperCommand[k].priv) and string.isSimilar(k, cmd) then
				counter = counter + 1
				possibilities[counter] = k
			end
		end

		if counter > 0 then
			returnValue = translate(playerCommunity, "$tryCommand", "'," .. table.concat(possibilities, "' | ',") .. "'")
			chooseSendMethod(isDebugging, target, returnValue)
		end
	end

	return false
end

local checkFastReply = function(isChatCommand, content, target, playerName, playerCommunity)
	if fastReplyCooldown[playerName] and (fastReplyCooldown[playerName] > os.time()) then return end

	for pat, value in next, fastReplyCommand do
		if string.find(content, pat) then
			chooseSendMethod(isChatCommand, target, translate(playerCommunity, value, playerName))
			fastReplyCooldown[playerName] = os.time() + FAST_REPLY_TIME
			return true
		end
	end
	return false
end

-- Discord emitters
disc:once("ready", function()
	for k, v in pairs(channel) do -- __pairs
		object[k] = disc:getChannel(v)
	end
	for k, v in next, settingChannel do
		settingChannel[k] = disc:getChannel(v)
	end

	for member in settingChannel.memberList:getMessages():iter() do
		setHelper(member.content)
	end

	disc:setGame("Prefix ;")

	local tentative = 0
	repeat
		tentative = tentative + 1
		print("Getting team list")
		teamList = getDatabase("teamList", nil, true)
	until teamList or tentative > 5
	ENV.teamList = teamList

	tentative = 0
	repeat
		tentative = tentative + 1
		print("Getting modules")
		modules = getDatabase("modules", nil, true)
	until modules or tentative > 5
	ENV.modules = modules

	tentative = 0
	repeat
		tentative = tentative + 1
		print("Getting commands activity")
		commandActivity = getDatabase("shadesCommandsActivity", nil, true)
	until commandActivity or tentative > 5
	ENV.commandActivity = commandActivity

	tentative = 0
	repeat
		tentative = tentative + 1
		print("Getting lua api doc")
		luaDoc = getDatabase("luaDoc", nil, true)
	until luaDoc or tentative > 5

	tentative = 0
	repeat
		tentative = tentative + 1
		print("Getting mapcrew list")
		mapcrewData = getDatabase("mapcrewMembers", nil, true)
	until mapcrewData or tentative > 5

	if not (teamList and modules and commandActivity and mapcrewData and luaDoc) then
		error(table.concat({ tostring(teamList), tostring(modules), tostring(commandActivity), tostring(mapcrewData), tostring(luaDoc) }, "~"), transfromage.enum.errorLevel.high)
	end

	-- Normalize string indexes
	for k, v in next, table.copy(mapcrewData) do
		for m, n in next, v.set do
			mapcrewData[k].set[m] = nil
			mapcrewData[k].set[tonumber(m)] = n
		end
		table.sort(mapcrewData[k].arr)
	end
	ENV.mapcrewData = mapcrewData

	for k, v in next, table.copy(luaDoc) do
		if v.description.parameters then
			for m, n in next, v.description.parameters do
				for i, j in next, n do
					if tonumber(i) then
						luaDoc[k].description.parameters[m][i] = nil
						luaDoc[k].description.parameters[m][tonumber(i)] = j
					end
				end
			end
		end
	end
	ENV.luaDoc = luaDoc

	timer.setTimeout(25 * 1000, function()
		if isConnected then return end
		return error("[Heartbeat] Failed to connect.", transfromage.enum.errorLevel.high)
	end)
	tfm:emit("connectionFailed")
end)

disc:on("messageCreate", protect(function(message)
	if not isWorking and message.author.id ~= disc.owner.id then return end
	if message.author.bot then
		if (message.author and message.embed and message.embed.author and message.embed.description)
			and message.author.id == githubWebhook.id
			and message.channel.id == channel.shadestest and message.embed.type == githubWebhook.embedType
			and (message.embed.author.name == githubWebhook.name or message.embed.author.name == githubWebhook.actionName)
		then
			local module = string.match(message.embed.title, "^%[(.-):")
			if not module then return end

			local isBolodefchoco = (module == "bolodefchoco")
			local hasHost = string.find(message.embed.description, "[host]", 1, true)

			if message.embed.author.name == githubWebhook.actionName then
				if not githubWebhook.waitingAction then return end
			elseif isBolodefchoco then -- is not action, is bolo
				githubWebhook.waitingAction = not not (hasHost and string.find(message.embed.description, "[build]", 1, true))
				return
			end

			if hasHost or githubWebhook.waitingAction then
				local url = "https://raw.githubusercontent.com/a801-luadev/" .. module .. "/master/"
				if isBolodefchoco then -- Has builds
					url = url .. "builds/" .. os.date("%d_%m_%y") .. ".lua"
				else
					url = url .. "module.lua"
				end

				local parameters = "#" .. module .. " " .. url

				message:reply("/host " .. parameters)
				serverCommand["host"](message, parameters)
			end
		elseif message.author.id == teamUpdaterWebhook.id then
			local data = json.decode(message.content)
			if data then
				for k, v in next, data do
					if type(v) == "string" then
						serverCommand["team"](message, "rename " .. k .. " " .. v)
					end
				end
				serverCommand["team"](message, "save")
			end
		end
		return
	end

	if message.channel.id == settingChannel.memberList.id then
		return setHelper(message.content)
	end

	local isMember = channel(message.channel.id) and helper[message.author.id]

	local cmd, param, hasPrefix = getCommandParameters(message.content, ';')
	if cmd then
		if param == '?' and hasPrefix then
			param = cmd
			cmd = "help"
		end

		if serverCommand[cmd] then
			if not serverCommand[cmd].priv or isMember then
				if message.author.id ~= disc.owner.id then
					if serverCommand[cmd].owner then
						toDelete[message.id] = message:reply("<@" .. message.author.id .. ">, you must be the bot owner in order to use this command!")
						return
					end
					if serverCommand[cmd].auth and not (serverCommand[cmd].allowMember and isMember) then
						if not message.member:hasRole(serverCommand[cmd].auth) then
							toDelete[message.id] = message:reply({
								content = "<@" .. message.author.id .. ">, you must have the role <@&" .. serverCommand[cmd].auth .. "> in order to use this command!",
								allowed_mentions = { parse = { "users" } }
							})
							return
						end
					end
				end

				addCommandActivity("server", cmd)
				return serverCommand[cmd](message, param)
			end
		end
	end

	if not isMember then return end

	local content = message.content
	if not string.find(content, "^,") then return end
	if message.attachment and message.attachment.url then
		content = content .. " " .. message.attachment.url
	end

	local cutSlice
	if (channel.whisper == message.channel.id) then -- on whisper
		local target, msgContent = string.match(content, "^,(.-) +(.+)")
		if not msgContent then return end

		if target == 'r' then
			if not lastUserReply then
				toDelete[message.id] = message:reply({
					content = "<@" .. message.author.id .. ">, there's no `last_user_reply` definition yet.",
					embed = {
						color = 0xFFAA00,
						description = "Use `,target message` or `,r message` (← last_user_reply)"
					}
				})
				return
			else
				target = lastUserReply
			end
		else
			target = string.toNickname(target)
		end

		cutSlice = tfm:sendWhisper(target, formatSendText(msgContent), helper[message.author.id])
	else
		if message.channel.id == channel.shadestest then
			-- Whisper comes first because of ',help'
			local target, playerName = channel(message.channel.id), string.toNickname(helper[message.author.id], true)
			local executed = executeCommand(false, content, target, playerName, true, true)
			executed = executed or executeCommand(true, content, target, playerName)
			if executed then return end
		end

		cutSlice = tfm:sendChatMessage(channel(message.channel.id), formatSendText(string.sub(content, 2)), helper[message.author.id])
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
	if message.channel.id == settingChannel.memberList.id then
		return remHelper(message.content)
	elseif toDelete[message.id] then
		message.channel:bulkDelete(toDelete[message.id])
		toDelete[message.id] = nil
	end
end))

disc:on("messageUpdate", protect(function(message)
	if message.channel.id == settingChannel.memberList.id then
		remHelper(message.content)
		setHelper(message.content)
	elseif toDelete[message.id] then
		disc:emit("messageDelete", message)
		disc:emit("messageCreate", message)
	end
end))

clock:on("min", protect(function()
	totalMinutes = totalMinutes + 1
	if totalMinutes % 5 == 0 and saveActivity then
		saveCommandActivity()
	end
end))

-- Transformice emitters
tfm:on("ready", protect(function()
	print("Connecting")
	tfm:connect(DATA[1], DATA[2], getRandomTmpRoom())

	local t = 30000
	for name in next, stalk do
		timer.setInterval(t, function()
			p("[stalk] profile " .. name)
			tfm:sendCommand("profile " .. name)
		end)
		t = t + 2500
	end
end))

tfm:once("heartbeat", protect(function()
	isConnected = true
end))

tfm:on("serverPing", protect(function()
	if lastServerPing then
		timer.clearTimeout(lastServerPing)
	end
	lastServerPing = timer.setTimeout(35 * 1000, error, "[Ping] Lost connection.", transfromage.enum.errorLevel.high)
end))

tfm:on("connectionFailed", protect(function()
	tfm:start(DATA[3], DATA[4])
end))

tfm:on("disconnection", protect(function(connection)
	if tfm._isConnected and connection.name == "main" then
		tfm._isConnected = false
		error("[Connection] Disconnected from main.", transfromage.enum.errorLevel.high)
	end
end))

tfm:once("connection", protect(function()
	error("Connected to the game with port " .. transfromage.enum.setting.port[tfm.mainConnection.portIndex], transfromage.enum.errorLevel.low)

	DATA[2] = nil

	print("Joining Tribe House")
	timer.setTimeout(3500, tfm.joinTribeHouse, tfm)

	print("Opening channels")
	for chat in pairs(channel) do
		if chat ~= "whisper" and chat ~= "teamTool" then
			print("Joining chat " .. chat)
			timer.setTimeout(500, tfm.joinChat, tfm, chat)
		end
	end

	timer.setTimeout(20000, function()
		if isWorking then return end
		isWorking = true
		print("Working forced")
	end)

	clock:start()
end))

tfm:once("joinTribeHouse", protect(function()
	print("Joined Tribe House")
	tfm:decryptXML()
	print("Loading module")
	tfm:sendCommand("module bolodefchoco")
	timer.setInterval(60 * 60 * 1000 * 1, function()
		print("Reloading module")
		tfm:sendCommand("module bolodefchoco")

		print("Getting lua time")
		tfm:sendRoomMessage("get_lua_event_time")
	end)

	timer.setTimeout(2500, function() -- Loading #bolodefchoco.*\3Editeur data.
		isWorking = true
		print("Working")
	end)

	timer.setTimeout(5000, function() -- Getting lua time
		print("Getting lua time")
		tfm:sendRoomMessage("get_lua_event_time")
	end)

	-- Check funcorp list
	local forum = fromage()
	forum.connect(DATA[6], DATA[7])
	if forum.isConnected() then
		local forumList = forum.getStaffList( forum.enumerations().listRole.funcorp )
		local dbList, message = teamList.fc

		local rem, countRem = { }, 0
		for name in next, dbList do
			if not forumList[name] then
				countRem = countRem + 1
				rem[countRem] = name
			end
		end

		if countRem > 0 then
			local parameters = "fc rem " .. table.concat(rem, " ")
			message = object.teamTool:send("/team " .. parameters)
			serverCommand["team"](message, parameters)
		end

		local add, countAdd = { }, 0
		for name, community in next, forumList do
			if not dbList[name] then
				community = countryCodeConvertedReverse[community] or community

				countAdd = countAdd + 1
				add[countAdd] = name .. "=" .. community
			end
		end

		if countAdd > 0 then
			local parameters = "fc add " .. table.concat(add, " ")
			message = object.teamTool:send("/team " .. parameters)
			serverCommand["team"](message, parameters)
		end

		if countRem + countAdd > 0 then
			serverCommand["team"](message, "save")
		end

		-- Remove non senti
		rem, countRem = { }, 0
		for name in next, teamList.sent do
			if name:sub(-4) * 1 > 15 then
				countRem = countRem + 1
				rem[countRem] = name
			end
		end

		if countRem > 0 then
			local parameters = "sent rem " .. table.concat(rem, " ")
			message = object.teamTool:send("/team " .. parameters)
			serverCommand["team"](message, parameters)
		end
	end
end))

tfm:on("chatMessage", protect(function(channelName, playerName, message, playerCommunity)
	if not object[channelName] then return end
	if channelName == "whisper" then return end -- :P
	p(channelName, playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	playerCommunity = getCommunityCode(playerCommunity)

	local currentTime = os.date("[%H:%M]")
	local content = string.format("%s [%s] [%s] %s", currentTime, playerCommunity, playerName, message)

	content = formatReceiveText(content)

	object[channelName]:send(content)

	if playerName ~= DATA[1] then
		if not executeCommand(true, message, channelName, playerName, nil, playerCommunity) then
			checkFastReply(true, message, channelName, playerName, playerCommunity)
		end
	end

	rulesProcessor(channelName, playerCommunity, playerName, message, currentTime)
end))

tfm:on("whisperMessage", protect(function(playerName, message, playerCommunity)
	p(playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	local isBot = playerName == DATA[1]
	if not isBot then
		lastUserReply = playerName
	end

	playerCommunity = getCommunityCode(playerCommunity)
	local content = string.format("%s [%s] [%s] [%s%s] %s", (isBot and '<' or '>'), os.date("%H:%M"), playerCommunity, playerName, ((isBot and lastUserWhispered) and (" → " .. lastUserWhispered) or ''), message)
	content = formatReceiveText(content)

	object.whisper:send(content)

	if not isBot then
		if not executeCommand(false, message, playerName, playerName, nil, playerCommunity, true) then
			checkFastReply(false, message, playerName, playerName, playerCommunity)
		end
	end
end))

tfm:on("profileLoaded", protect(function(data)
	if stalk[data.playerName] then
		object.shadestest:send("<@285878295759814656> " .. data.playerName .. " has connected!")
		return
	end

	if dressroom[data.playerName] then
		local look = translate(dressroom[data.playerName].playerCommunity, "$outfit", data.playerName, data.look)

		if dressroom[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(look))
		else
			tfm:sendWhisper(dressroom[data.playerName].playerName, look)
		end

		dressroom[data.playerName] = nil
	elseif profile[data.playerName] then
		local title = getTitle(data.titleId, data.gender)

		local modeStats = data.modeStats
		local profileStats = transfromage.enum.profileStats

		disc:getChannel(profile[data.playerName]):send((profile[data.playerName] == miscChannel.transfromage_tokens and ("<:wheel:456198795768889344> **" .. data.playerName .. "'s ID :** " .. data.id) or ({
			embed = {
				color = 0x2E565F,
				title = "<:tfm_cheese:458404666926039053> Transformice Profile - " .. data.playerName .. (data.gender == 2 and " <:male:456193580155928588>" or data.gender == 1 and " <:female:456193579308679169>" or ''),
				description =
					(data.role > 0 and ("**Role :** " .. string.gsub(transfromage.enum.role(data.role), "%a", string.upper, 1) .. "\n\n") or '') ..

					((data.soulmate and data.soulmate ~= '') and (":revolving_hearts: **" .. data.soulmate .. "**\n") or '') ..
					":calendar: " .. os.date("%d/%m/%Y", data.registrationDate) ..
					((data.tribeName and data.tribeName ~= '') and ("\n<:tribe:458407729736974357> **Tribe :** " .. data.tribeName) or '') ..

					"\n\n**Level " .. data.level .. "**" ..
					"\n**Current Title :** `«" .. title .. "»`" ..
					"\n**Adventure points :** " .. data.adventurePoints ..

					"\n\n<:shaman:512015935989612544> " .. data.saves.normal .. " / " .. data.saves.hard .. " / " .. data.saves.divine ..
					"\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. data.shamanCheese ..

					"\n\n<:racing:512016668038266890> **Firsts :** " .. data.firsts ..
					"\n<:tfm_cheese:458404666926039053> **Cheese :** " .. data.cheeses ..
					"\n<:bootcamp:512017071031451654> **Bootcamps :** " .. data.bootcamps ..

					"\n\n<:dance:468937918115741718> `" .. data.look .. "`" ..

					"\n\n<:p17:565931895662051330> **Played** / **Completed** / **Firsts** / **Podium**: " .. modeStats[profileStats.racingRoundsPlayed].progress .. " / " .. modeStats[profileStats.racingRoundsCompleted].progress .. " / " .. modeStats[profileStats.racingFirst].progress .. " / " .. modeStats[profileStats.racingPodium].progress ..
					"\n<:p10:563096585966452746> **Played** / **Shaman** / **Kills** / **Survived**: " .. modeStats[profileStats.survivorRoundsPlayed].progress .. " / " .. modeStats[profileStats.survivorShaman].progress .. " / " .. modeStats[profileStats.survivorKills].progress .. " / " .. modeStats[profileStats.survivorRoundsSurvived].progress ..
					"\n<:p18:565931898858242074> **Played** / **Completed** / **Points**: " .. modeStats[profileStats.defilanteRoundsPlayed].progress .. " / " .. modeStats[profileStats.defilanteRoundsCompleted].progress .. " / " .. modeStats[profileStats.defilantePoints].progress ..

					"\n\n<:wheel:456198795768889344> **Total titles :** " .. data.totalTitles ..
					"\n<:wheel:456198795768889344> **Total badges :** " .. data.totalBadges ..
					"\n<:wheel:456198795768889344> **Total cartouches :** " .. data.totalOrbs ..

					"\n\n<:wheel:456198795768889344> **ID :** " .. data.id
				,
				thumbnail = { url = "http://avatars.atelier801.com/" .. (data.id % 10000) .. "/" .. data.id .. ".jpg" },
				image = { url = "http://santanl.000webhostapp.com/badges.php?row_max=18&badges=" .. table.concat(table.keys(data.badges), ',') }
			}
		})))
		profile[data.playerName] = nil
	elseif checkTitles[data.playerName] then
		local gender = (data.gender % 2 + 1)

		local commu = checkTitles[data.playerName].playerCommunity
		if not translate[commu] then
			commu = "en"
		end

		data.savesNormal, data.savesHard, data.savesDivine = data.saves.normal, data.saves.hard, data.saves.divine -- comp

		local out, counter = { }, 0
		local title, field, stars, skip
		for f = 1, #titleFields do
			field = titleFields[f]

			skip = false
			stars = ''
			if field == "bootcamps" and data[field] < 9001 then -- Handle stars
				local totalStars = ((data[field] - 1) / 1000)
				if totalStars >= 1 then
					stars = " " .. string.rep('★', totalStars)
					data[field] = data[field] % 1000
				end
			elseif (field == "savesHard" and data.savesNormal < 1000) or (field == "savesDivine" and data.savesHard < 2000) then
				skip = true
			end

			if not skip then
				local missing
				for i = 1, #titleRequirements[field] do
					if data[field] < titleRequirements[field][i][2] then
						title = getTitle(titleRequirements[field][i][1], gender, commu, true)
						missing = (titleRequirements[field][i][2] - data[field])

						counter = counter + 1
						out[counter] = translate(commu, titleFieldsKeys[f], (missing > 1 and 's' or ''))
						out[counter] = translate(commu, "$checktitle", missing, out[counter], title .. stars)
						break
					end
				end
			end
		end

		if #out == 0 then
			out = translate(commu, "$notitle")
		else
			out = table.concat(out, ", ")
		end
		out = "'" .. data.playerName .. "': " .. out

		if checkTitles[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(out))
		else
			tfm:sendWhisper(checkTitles[data.playerName].playerName, out)
		end

		checkTitles[data.playerName] = nil
	elseif checkAvailableRewards[data.playerName] then
		local srcRewards = checkAvailableRewards[data.playerName]
		rewardsCooldown[srcRewards.playerName] = os.time() + (REWARDS_TIME * 60)

		local commu = srcRewards.playerCommunity
		if not translate[commu] then
			commu = "en"
		end

		-- Avoid json arrays
		data.badges._ignore = true
		data.orbs._ignore = true

		local rewards = {
			success = true,
			nickname = data.playerName,
			badges = data.badges,
			orbs = data.orbs
		}

		local titles, counter = { }, 0

		local title, hasGender
		for t = 0, 600 do -- Cannot know how many titles there are
			if not unavailableTitles[t] and not data.titles[t] then
				title = getTitle(t, data.gender, commu)
				if title ~= t then
					counter = counter + 1
					titles[counter] = title
				end
			end
		end
		rewards.titles = titles
		rewards = json.encode(rewards)
		rewards = string.gsub(rewards, "\\", '') -- Some titles use it

		local playerData
		local code = string.match(os.tmpname(), "(%w+)$")

		local saved = saveDatabase(code .. "&folder=bottmp", rewards, true)
		if not saved then
			playerData = translate(srcRewards.playerCommunity, "$norewards")
			rewardsCooldown[srcRewards.playerName] = 0 -- user can try again
		else
			playerData = translate(srcRewards.playerCommunity, "$rewardscode", code)
		end

		if srcRewards.isDebugging then
			object.shadestest:send(playerData)
		else
			tfm:sendWhisper(srcRewards.playerName, playerData)
		end

		checkAvailableRewards[data.playerName] = nil
	elseif avatars[data.playerName] then
		avatars[data.playerName] = nil
		if data.id == 0 then return end

		p('sending', data.playerName)
		object.avatars:send("https://atelier801.com/profile?pr=" .. string.gsub(string.gsub(data.playerName, "#", "%%23", 1), "%+", "%%43", 1) .. "\n\z
			http://avatars.atelier801.com/" .. (data.id % 10000) .. "/" .. data.id .. ".jpg")
	end
end))

tfm:insertModernListener(6, 9, protect(function(self, packet, connection, C_CC) -- Chat message from #bolodefchoco.*\3Editeur
	local text = packet:readUTF()

	if string.find(text, "[shades_id]", 1, true) then
		object.shadestest:send("<@" .. disc.owner.id .. ">\n" .. text)
		return
	end

	if string.find(text, "^evt_") then
		luaEventTime = string.match(text, "%d+%-%d+")
		return
	end

	local team, missing, content = string.match(text, "^(%S+) (%d) (.+)")
	missing = tonumber(missing)

	if team then
		if onlinePlayer[team] then
			local isOnline = json.decode(content).isOnline
			disc:getChannel(onlinePlayer[team]):send((isOnline and "<:online:456197711356755980>" or "<:offline:456197711457419276>") .. team .. " is " .. (isOnline and "on" or "off") .. "line!")
			onlinePlayer[team] = nil
			return
		end

		local l = srcMemberListCmd[team]
		if not l then return end

		l._loading = l._loading .. content

		if missing == 0 then
			local _team = team
			team = string.gsub(team, "%u", " %1")

			local commu, counter, commuList = { }, 0, { }
			for k, v in next, json.decode(l._loading).members do
				k = remDefaultDiscriminator(k)

				-- Adds each name to its respective community
				if not commuList[v] then
					counter = counter + 1
					commuList[v] = counter
					commu[commuList[v]] = { commu = v, list = { }, counter = 0 }
				end
				commu[commuList[v]].counter = commu[commuList[v]].counter + 1
				commu[commuList[v]].list[commu[commuList[v]].counter] = k
			end

			if counter > 0 then
				table.sort(commu, function(commu1, commu2)
					return commu1.commu < commu2.commu
				end)
				for i = 1, counter do
					table.sort(commu[i].list)
					commu[i] = "[" .. commu[i].commu .. "] " .. table.concat(commu[i].list, ", ")
				end

				l._onlineMembers.state = 1 -- Online
				l._onlineMembers.data = table.concat(commu, " | ") -- Data is sent together (text%data) because of %u→ %l
			else
				l._onlineMembers.state = 0 -- Offline
				l._onlineMembers.data = ''
			end
			l._onlineMembers.team = team
			l._loading = ''

			for i = 1, #l._queue do
				if l._queue[i].isDebugging then
					if l._queue[i].isServerCmd then
						l._queue[i].isDebugging:reply(formatServerMemberList(l._onlineMembers(), _team, l._queue[i].isDebugging.author.tag))
					else
						object.shadestest:send(formatReceiveText(l._onlineMembers()))
					end
				else
					tfm:sendWhisper(l._queue[i].playerName, l._onlineMembers(l._queue[i].language))
				end
			end
			l._queue = { }
		end
		l._timer = os.time() + 60
	end
end))

tfm:on("chatWho", protect(function(chatName, data)
	if not chatName then return end

	local data = "**#" .. chatName .. "** : " .. #data .. "\n" .. table.concat(table.mapArray(data, function(user)
		return "`" .. user .. "`"
	end), ", ")

	for i = 0, #data, 2000 do
		object[chatName]:send(string.sub(data, i + 1, i + 2000))
	end
end))

tfm:on("staffList", protect(function(isModList, namesByCommunity, individualNames)
	p("@@@@@@@@@@@@@ staff list 1")
	local hasOnline = #individualNames > 0
	local title, whisperTitle = ''

	if isModList then
		if hasOnline then
			title = "Online Moderators"
		else
			title = "No Moderators online :("
		end
	else
		if hasOnline then
			title = "Online Mapcrew"
		else
			whisperTitle = "$nomapcrew"
			title = translate("en", whisperTitle)
		end
	end

	local list

	local whisperList, discordList = (whisperTitle or title)
	if hasOnline then
		p("@@@@@@@@@@@@@ staff list 2")

		list = table.concat(table.map(namesByCommunity, function(names, community)
			return "`[" .. community:upper() .. "]` " .. table.concat(names, ", ")
		end), "\n")

		if not isModList then -- mapcrew
			discordList = string.gsub(list, "%S+#%d+", function(nickname)
				if mapcrewData[nickname] then
					return nickname .. " [" .. table.concat(table.map(mapcrewData[nickname].arr, function(v)
						return (mapCategory[v] and mapCategory[v][1] or ("P" .. v))
					end), ' ') .. "]"
				else
					return nickname
				end
			end)

			whisperList = string.gsub(list, "(%S+)(#%d+)", function(nickname, tag)
				local fullNickname = nickname .. tag
				nickname = (tag == "#0020" and nickname or (nickname .. tag))

				if mapcrewData[fullNickname] and #mapcrewData[fullNickname].arr > 0 then
					return nickname .. " (P" .. table.concat(mapcrewData[fullNickname].arr, "/P") .. ")"
				else
					return nickname
				end
			end)

			whisperList = string.gsub(whisperList, '`', '')
			whisperList = string.gsub(whisperList, "\n", " | ")
		end

		discordList = string.gsub((discordList or list), "#%d+", "`%1`")
		p("@@@@@@@@@@@@@ staff list 3")
	end

	local embed = {
		embed = {
			color = roleColors[(isModList and "Moderator" or "Mapcrew")],
			title = tostring(title),
			description = discordList,
			footer = {

			}
		}
	}

	local listSrc = (isModList and modList or mapcrewList)
	p("@@@@@@@@@@@@@ staff list 4 #" .. #listSrc)
	for i = 1, #listSrc do
		i = listSrc[i]
		if i.author then -- discord || mod
			embed.embed.footer.text = "Requested by " .. i.author.tag
			p("@@@@@@@@@@@@@ staff list 5 requesting [1]")
			local _, d = i:reply(embed)
			if not _ then
				p(d)
			end
			p("@@@@@@@@@@@@@ staff list 5 end requesting [1]")
		else -- whisper
			if not hasOnline then
				whisperList = translate(i.playerCommunity, whisperList)
			end
			if i.isDebugging then
				object.shadestest:send(formatReceiveText(whisperList))
			else
				tfm:sendWhisper(i.playerName, whisperList)
			end
		end
	end

	if isModList then
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
	if map.xml and map.xml ~= '' and map.code and xml[map.code] then
		timer.clearTimeout(xml[map.code].timer)

		if #map.xml <= 23000 then
			local head, body
			if xml[map.code]._xmlOnly then
				local m = xml[map.code].message:reply({
					content = "<@" .. xml[map.code].message.author.id .. ">, the XML of the map is in the attached file.",
					file = { map.code .. ".txt", map.xml }
				})
				timer.setTimeoutCoro(20000, m.delete, m)
			else
				local hasSpoiler = map.permCode == 43

				head, body = http.request("POST", "https://miceditor-map-preview.herokuapp.com/", specialHeaders.json, json.encode({ xml = map.xml, raw = hasSpoiler }), 10000)

				if head and head.code == 200 then
					local tmp
					if hasSpoiler then
						tmp = string.match(os.tmpname(), "([^/]+)$") .. ".png" -- Match needed so it doesn't glitch 'attachment://'
						if map.permCode == 43 then
							tmp = "SPOILER_" .. tmp
						end
						local file = io.open(tmp, "w+")
						file:write(body)
						file:flush()
						file:close()
					end

					local perm = (mapCategory[map.permCode] or mapCategory.default)
					p("@@@@@@@@@@@@@ posting ini " .. os.time())
					xml[map.code].message:reply({
						content = "<@" .. xml[map.code].message.author.id .. ">",
						embed = {
							color = perm[2],
							description = (perm[3] and ("`[" .. perm[3] .. "]` ") or '') .. perm[1] .. " - **P" .. map.permCode .. "**\n" .. map.code .. " - **" .. remDefaultDiscriminator(map.author) .. "**",
							image = not hasSpoiler and { url = body }
						},
						file = hasSpoiler and tmp
					})

					if tmp then
						os.remove(tmp)
					end
				else
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
		if not xml[map.code] then return error(map.code, xml, xml[map.code], xml[map.code:sub(2)], p(xml)) end -- potential bug fix?

		if xml[map.code].reply then
			xml[map.code].reply:delete()
		end

		table.remove(xml.queue, 1)
		xml[map.code] = nil

		timer.setTimeoutCoro(1000, loadXmlQueue)
	end
end))

tfm:on("newFriend", protect(function(friend)
	settingChannel.discussion:send("@here " .. friend.playerName .. " has been added to the friendlist.")
end))

tfm:on("removeFriend", protect(function(playerId)
	settingChannel.discussion:send("@here " .. tostring(friendRemoval) .. " (" .. playerId .. ") has been removed from the friendlist.")
	friendRemoval = nil
end))

tfm:on("blackList", protect(function(blacklist)
	local len = #blacklist
	local embed = {
		embed = {
			color = 0,
			description = "Total blacklisted players: **" .. len .. "**\n\n" .. (len > 0 and (":skull: **" .. table.concat(blacklist, "**\n:skull: **")) or "**None") .. "**"
		}
	}

	for i = 1, #displayBlacklist do
		embed.embed.timestamp = displayBlacklist[i].timestamp
		displayBlacklist[i]:reply(embed)
	end
	displayBlacklist = { }
end))

tfm:once("serverReboot", protect(function(t)
	object.shadestest:send("Rebooting server!")
end))

local lastSalesList
local waitingForShopTrigger = nil
tfm:on("saleLoad", function(sale)
	if waitingForShopTrigger then return end

	if waitingForShopTrigger == false then -- not nil
		if lastSalesList[sale.itemId] then return end -- Repeat?
	end

	waitingForShopTrigger = true

	print("Received new sales, loading shop.")
	timer.setTimeoutCoro(5000, tfm.openShop, tfm)
end)

local populateShopSales = protect(function(shop, v, authorizationHeader)
	p("[DEBUG] Sale item", v)

	if v.isShamanItem then
		item = shop:getShamanItem(v.itemId)
		p("[DEBUG] Got item", v.itemId, item)
		head, body = http.request("GET", "https://cheese.formice.com/api/dressroom/shaman/" .. item.uniqueId .. "?png", authorizationHeader)
	else
		item = shop:getItem(v.itemId)
		p("[DEBUG] Got item", v.itemId, item)
		look = outfitToString({
			[item.categoryId == 22 and 1 or (item.categoryId + 2)] = tostring(item.id)
		})

		head, body = http.request("GET", "https://cheese.formice.com/api/dressroom/mouse/" .. look .. "?png", authorizationHeader)
	end

	shopSales[#shopSales + 1] = {
		_rawContent = string.format("<:tfm_cheese:458404666926039053> **%s** or <:tfm_fraise:925488127206912051> ~~%s~~ **%s** (-%s%%)\n",
			item.cheesePrice, item.fraisePrice, item.fraisePriceWithDiscount, v.discountPercentage),
		_rawTime = "`Ends in %s`",
		_time = v.timestamp,
		file = {
			v.itemId .. ".png",
			body
		} or nil
	}
end)

tfm:on("shopLoad", protect(function(shop)
	waitingForShopTrigger = false
	print("Shop loaded")

	p("[DEBUG] Sales", shop.sales)
	p("[DEBUG] Collector", shop.collector)

	lastSalesList = { }
	for id in next, shop.sales do
		lastSalesList[id] = true
	end

	local head, body = http.request("POST", "https://cheese.formice.com/api/session", specialHeaders.json, "{\"client_id\": 4, \"token\": \"" .. DATA[10] .. "\", \"duration\": \"10m\"}")
	body = json.decode(body)
	if not (body and body.session) then
		return error("[CFM] Failed to get session bot token.", transfromage.enum.errorLevel.low)
	end
	local authorizationHeader = { { "Authorization", "Bot " .. body.session } }

	local counter = 0
	local item, look
	for k, v in next, shop.sales do
		counter = counter + 1
		timer.setTimeoutCoro(counter * 3500, populateShopSales, shop, v, authorizationHeader)
	end
end))

--tfm:on("newPlayer", protect(function(player)
--	if avatars[player.playerName] then
--		return p("Dup avatar", player.playerName)
--	end
--	p("Avatar", player.playerName)
--	avatars[player.playerName] = true
--
--	AVATAR_TIME = AVATAR_TIME + 1000
--	timer.setTimeout(AVATAR_TIME, tfm.sendCommand, tfm, "profile " .. player.playerName)
--end))

-- Initialize
tfm:setLanguage(transfromage.enum.language.br)

disc:run(DATA[5])
DATA[5] = nil

-- Env
ENV = setmetatable({
	bit32 = bit,
	CHAR_LIM = CHAR_LIM,
	CHAT_MSG_LIM = CHAT_MSG_LIM,
	WHISPER_MSG_LIM = WHISPER_MSG_LIM,
	ANTI_SPAM_TIME = ANTI_SPAM_TIME,
	REWARDS_TIME = REWARDS_TIME,
	AVATAR_TIME = AVATAR_TIME,
	timer = timer,
	http = http,
	json = json,
	discordia = discordia,
	transfromage = transfromage,
	disc = disc,
	tfm = tfm,
	object = object,
	channels = channel,
	settingChannel = settingChannel,
	miscChannel = miscChannel,
	categoryId = categoryId,
	helper = helper,
	hostRanking = hostRanking,
	isConnected = isConnected,
	isWorking = isWorking,
	dressroom = dressroom,
	onlinePlayer = onlinePlayer,
	timeCmd = timeCmd,
	modulesCmd = modulesCmd,
	xml = xml,
	userCache = userCache,
	profile = profile,
	checkTitles = checkTitles,
	displayBlacklist = displayBlacklist,
	mapCategory = mapCategory,
	roleColors = roleColors,
	titleRequirements = titleRequirements,
	titleFields = titleFields,
	titleFieldsKeys = titleFieldsKeys,
	translate = translate,
	toDelete = toDelete,
	protect = protect,
	removeSpaces = removeSpaces,
	formatReceiveText = formatReceiveText,
	formatSendText = formatSendText,
	formatServerMemberList = formatServerMemberList,
	splitMsgByWord = splitMsgByWord,
	encodeUrl = encodeUrl,
	srcMemberListCmd = srcMemberListCmd,
	createListCommand = createListCommand,
	getCommunityCode = getCommunityCode,
	splitByLine = splitByLine,
	printf = print,
	secToDate = secToDate,
	remDefaultDiscriminator = remDefaultDiscriminator,
	getCommandParameters = getCommandParameters,
	userAntiSpam = userAntiSpam,
	executeCommand = executeCommand,
	setHelper = setHelper,
	remHelper = remHelper,
	dressroomLink = dressroomLink,
	loadXmlQueue = loadXmlQueue,
	chatHelpSource = chatHelpSource,
	whisperHelpSource = whisperHelpSource,
	memberHelpSource = memberHelpSource,
	commandWrapper = commandWrapper,
	chatCommand = chatCommand,
	whisperCommand = whisperCommand,
	serverCommand = serverCommand,
	specialHeaders = specialHeaders,
	teamListAbbreviated = teamListAbbreviated,
	countryCodeConverted = countryCodeConverted,
	cachedTeamListDisplay = cachedTeamListDisplay,
	teamListHasBeenChanged = function()
		return teamListHasBeenChanged
	end,
	teamListFileTimer = function()
		return teamListFileTimer
	end,
	getDatabase = getDatabase,
	saveDatabase = saveDatabase,
	githubWebhook = githubWebhook,
	teamUpdaterWebhook = teamUpdaterWebhook,
	unavailableTitles = unavailableTitles,
	pairsByIndexes = pairsByIndexes,
	countryFlags = countryFlags,
	isPlayer = isPlayer,
	rewardsCooldown = rewardsCooldown,
	fastReplyCommand = fastReplyCommand,
	saveActivity = function()
		return saveActivity
	end,
	saveCommandActivity = saveCommandActivity,
	clock = clock,
	totalMinutes = function()
		return totalMinutes
	end,
	generateModulesBbcode = generateModulesBbcode,
	updateModulesForumMessage = updateModulesForumMessage,
	fastReplyCooldown = fastReplyCooldown,
	FAST_REPLY_TIME = FAST_REPLY_TIME,
	countryCodeConvertedReverse = countryCodeConvertedReverse,

	db_url = db_url,

	shopSales = shopSales,

	rulesProcessor = rulesProcessor,

	luaEventTime = function()
		return luaEventTime
	end
}, {
	__index = _G
})