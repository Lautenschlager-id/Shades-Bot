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
local disc = discordia.Client({
	cacheAllMembers = true
})
disc._options.routeDelay = 0
local tfm = transfromage.client:new()

-- Data
local object = { }
local channel = transfromage.enum({
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

local mapCategory = {
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

local roleColors = {
	ModuleTeam = 0x7AC9C4,
	FashionSquad = 0xEF98AA,
	Funcorp = 0xFF9C00,
	Sentinel = 0x2ECF73,
	Moderator = 0xBABD2F,
	Mapcrew = 0x2F7FCC,
	ShadesHelpers = 0xF3D165
}

local titleRequirements = {
	cheeses = {
		{ 0, 0 },
		{ 5, 5 },
		{ 6, 20 },
		{ 7, 100 },
		{ 8, 200 },
		{ 35, 300 },
		{ 36, 400 },
		{ 37, 500 },
		{ 26, 600 },
		{ 27, 700 },
		{ 28, 800 },
		{ 29, 900 },
		{ 30, 1000 },
		{ 31, 1100 },
		{ 32, 1200 },
		{ 33, 1300 },
		{ 34, 1400 },
		{ 38, 1500 },
		{ 39, 1600 },
		{ 40, 1700 },
		{ 41, 1800 },
		{ 72, 2000 },
		{ 73, 2300 },
		{ 74, 2700 },
		{ 75, 3200 },
		{ 76, 3800 },
		{ 77, 4600 },
		{ 78, 6000 },
		{ 79, 7000 },
		{ 80, 8000 },
		{ 81, 9001 },
		{ 82, 10000 },
		{ 83, 14000 },
		{ 84, 18000 },
		{ 85, 22000 },
		{ 86, 26000 },
		{ 87, 30000 },
		{ 88, 34000 },
		{ 89, 38000 },
		{ 90, 42000 },
		{ 91, 46000 },
		{ 92, 50000 },
		{ 234, 55000 },
		{ 235, 60000 },
		{ 236, 65000 },
		{ 237, 70000 },
		{ 238, 75000 },
		{ 93, 80000 }
	},
	firsts = {
		{ 9, 1 },
		{ 10, 10 },
		{ 11, 100 },
		{ 12, 200 },
		{ 42, 300 },
		{ 43, 400 },
		{ 44, 500 },
		{ 45, 600 },
		{ 46, 700 },
		{ 47, 800 },
		{ 48, 900 },
		{ 49, 1000 },
		{ 50, 1100 },
		{ 51, 1200 },
		{ 52, 1400 },
		{ 53, 1600 },
		{ 54, 1800 },
		{ 55, 2000 },
		{ 56, 2200 },
		{ 57, 2400 },
		{ 58, 2600 },
		{ 59, 2800 },
		{ 60, 3000 },
		{ 61, 3200 },
		{ 62, 3400 },
		{ 63, 3600 },
		{ 64, 3800 },
		{ 65, 4000 },
		{ 66, 4500 },
		{ 67, 5000 },
		{ 68, 5500 },
		{ 69, 6000 },
		{ 231, 7000 },
		{ 232, 8000 },
		{ 233, 9000 },
		{ 70, 10000 },
		{ 224, 12000 },
		{ 225, 14000 },
		{ 226, 16000 },
		{ 227, 18000 },
		{ 202, 20000 },
		{ 228, 25000 },
		{ 229, 30000 },
		{ 230, 35000 },
		{ 71, 40000 }
	},
	savesNormal = {
		{ 1, 10 },
		{ 2, 100 },
		{ 3, 1000 },
		{ 4, 2000 },
		{ 13, 3000 },
		{ 14, 4000 },
		{ 15, 5000 },
		{ 16, 6000 },
		{ 17, 7000 },
		{ 18, 8000 },
		{ 19, 9000 },
		{ 20, 10000 },
		{ 21, 11000 },
		{ 22, 12000 },
		{ 23, 13000 },
		{ 24, 14000 },
		{ 25, 15000 },
		{ 94, 16000 },
		{ 95, 18000 },
		{ 96, 20000 },
		{ 97, 22000 },
		{ 98, 24000 },
		{ 99, 26000 },
		{ 100, 28000 },
		{ 101, 30000 },
		{ 102, 35000 },
		{ 103, 40000 },
		{ 104, 45000 },
		{ 105, 50000 },
		{ 106, 55000 },
		{ 107, 60000 },
		{ 108, 65000 },
		{ 109, 70000 },
		{ 110, 75000 },
		{ 111, 80000 },
		{ 112, 85000 },
		{ 113, 90000 },
		{ 200, 100000 },
		{ 114, 140000 }
	},
	savesHard = {
		{ 213, 500 },
		{ 214, 2000 },
		{ 215, 4000 },
		{ 216, 7000 },
		{ 217, 10000 },
		{ 218, 14000 },
		{ 219, 18000 },
		{ 220, 22000 },
		{ 221, 26000 },
		{ 222, 30000 },
		{ 223, 34000 }
	},
	savesDivine = {
		{ 324, 500 },
		{ 325, 1000 },
		{ 326, 2000 },
		{ 327, 4000 },
		{ 328, 7000 },
		{ 329, 10000 },
		{ 330, 15000 },
		{ 331, 20000 },
		{ 332, 25000 },
		{ 333, 30000 },
		{ 334, 40000 }
	},
	bootcamps = {
		{ 256, 1 },
		{ 257, 3 },
		{ 258, 5 },
		{ 259, 7 },
		{ 260, 10 },
		{ 261, 15 },
		{ 262, 20 },
		{ 263, 25 },
		{ 264, 30 },
		{ 265, 40 },
		{ 266, 50 },
		{ 267, 60 },
		{ 268, 70 },
		{ 269, 80 },
		{ 270, 90 },
		{ 271, 100 },
		{ 272, 120 },
		{ 273, 140 },
		{ 274, 160 },
		{ 275, 180 },
		{ 276, 200 },
		{ 277, 250 },
		{ 278, 300 },
		{ 279, 350 },
		{ 280, 400 },
		{ 281, 500 },
		{ 282, 600 },
		{ 283, 700 },
		{ 284, 800 },
		{ 285, 900 },
		{ 286, 1000 }
	}
}
local titleFields = { "cheeses", "firsts", "savesNormal", "savesHard", "savesDivine", "bootcamps" }
local titleFieldsKeys = { "$cheese", "$first", "$svnormal", "$svhard", "$svdiv", "$boot" }

local translate = setmetatable({ }, {
	__newindex = function(this, index, value)
		transfromage.translation.download(transfromage.enum.language[index], function()
			-- Fix titles
			transfromage.translation.free(transfromage.enum.language[index], nil, "^T_%d+")
			transfromage.translation.set(transfromage.enum.language[index], "^T_%d+", function(titleName)
				titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
				titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
				return titleName
			end)

			rawset(this, index, value)
		end)
	end,
	__call = function(this, community, str, ...)
		community = community and this[community] or this.en
		if not community then
			return "Loading translations..."
		end

		str = string.gsub(str, "%$(%w+)", function(line)
			return community[line] or this.en[line] or ("$" .. line)
		end)
		return string.format(str, ...)
	end
})
translate.en = {
	-- Help
	hdoc = "Sends the link of the Transformice Lua Documentation.",
	faq = "Sends the link of the FAQ thread of a community.",
	commu = "community",
	happ = "Sends the application form link of a Transformice official team.",
	team = "team_name",
	help = "Displays the available commands / the commands descriptions.",
	info = "Displays cool bot informations.",
	helper = "Displays the Shades Helpers that are online on Discord.",
	dress = "Sends a link of your/someone's outfit. Accepts a nickname as parameter.",
	mt = "Displays the online public Module Team members.",
	fs = "Displays the online public Fashion Squad members.",
	fc = "Displays the online Funcorp members.",
	sent = "Displays the online Sentinels.",
	sh = "Displays the online Shades Helpers.",
	make = "Shows how to make a bot with Transfromage.",
	nocmd = "Command '%s' not found. :s", -- Name
	hlist = "Type '%s command_name' or '%scommand_name ?' to learn more. Available Commands → %s", -- "help"
	link = "Displays the final URL of shortened URLs. Receives an URL as parameter.",
	title = "Checks the next titles you or someone is about to unlock. Accepts a nickname as parameter.",
	-- Data
	doc = "Lua documentation: %s", -- URL
	nofaq = "This community doesn't have a FAQ yet. :(",
	acommu = "Available communities → %s", -- List
	app = "Apply to '%s': %s", -- Name, URL
	noapp = "The requested team was not found. :(",
	ateam = "Available teams → %s", -- List
	nohelp = "Whisper me with ',%s' to get the command list.", -- "help"
	about = "I'm a bot from the '%s' server ( %s ), maintained by %s. Shades Helpers is a group intended to help everyone, mostly about modules, lua, and technical stuff.", -- Name, URL, Name
	nohelper = "No Shades Helpers online on Discord. :(",
	onhelper = "Online Shades Helpers on Discord: %s",
	dmake = "To make a bot in Transformice you'll need: - one of our APIs, which are available in Lua and Python; - a token for the API to connect to Transformice. You can get it all by asking in our server: %s", -- URL
	-- Extra
	outfit = "%s's outfit: %s", -- Name, URL
	onteam = "Online%s members: %s", -- Name of the team (prefixed with a space), List
	noteam = "No%s online members.", -- Name of the team (prefixed with a space)
	spam = "Wow, %s; Hold on, cowboy! Don't spam me with commands.", -- Name
	checktitle = "%d %s for «%s»",
	notitle = "You already have all the titles from stats! :O",
	-- Fields
	cheese = "cheese",
	first = "firsts",
	svnormal = "saves in normal mode",
	svhard = "saves in hard mode",
	svdiv = "saves in divine mode",
	boot = "bootcamps"
}
translate.br = {
	hdoc = "Envia o link para a documentação Lua do Transformice.",
	faq = "Envia o link do tópico FAQ de uma comunidade.",
	commu = "comunidade",
	happ = "Envia o link de um formulário de aplicação de uma equipe oficial do Transformice.",
	team = "nome_equipe",
	help = "Mostra os comandos disponíveis / a descrição dos comandos.",
	info = "Mostra informações legais do bot.",
	helper = "Mostra os Shades Helpers que estão online no Discord.",
	dress = "Envia um link com seu visual, ou o de algum jogador. Aceita um nickname como parâmetro.",
	mt = "Mostra os membros públicos online da Module Team.",
	fs = "Mostra os membros públicos online da Fashion Squad.",
	fc = "Mostra os membros online da Funcorp.",
	sent = "Mostra os Sentinelas online.",
	sh = "Mostra os Shades Helper online.",
	make = "Mostra como fazer um bot com Transfromage.",
	nocmd = "Comando '%s' não encontrado. :s",
	hlist = "Digite '%s nome_comando' ou '%snome_comando ?' para ler mais. Comandos disponíveis → %s",
	link = "Mostra a URL final de URLs encurtadas. Recebe uma URL como parâmetro.",
	title = "Checa os próximos títulos que você ou alguém está próximo de desbloquear. Aceita um nickname como parâmetro.",
	doc = "Documentação Lua: %s",
	nofaq = "Essa comunidade ainda não tem uma FAQ. :(",
	acommu = "Comunidades disponíveis → %s",
	app = "Aplique para '%s': %s",
	noapp = "A equipe pedida não foi encontrada. :(",
	ateam = "Equipes disponíveis → %s",
	nohelp = "Me cochiche com ',%s' para obter a lista de comandos.",
	about = "Sou um bot do servidor '%s' ( %s ), mantido por %s. Shades Helpers é um grupo com a intenção de ajudar todo mundo, especialmente sobre módulos, lua e coisas técnicas.",
	nohelper = "Não há Shades Helpers online no Discord. :(",
	onhelper = "Shades Helpers Online no Discord: %s",
	dmake = "Para fazer um bot no Transformice será necessário: - uma de nossas APIs, disponível em Lua e Python; - um token para a API se conectar ao Transformice; Você pode conseguir isso tudo em nosso server: %s",
	outfit = "Visual de %s: %s",
	onteam = "Membros online da%s: %s",
	noteam = "Não há membros online da%s.",
	spam = "Wow, %s; Calma aí, parceiro! Não me spame com comandos.",
	checktitle = "%d %s para «%s»",
	notitle = "Você já tem todos os títulos de stats! :O",
	cheese = "queijos",
	first = "firsts",
	svnormal = "saves no modo normal",
	svhard = "saves no modo difícil",
	svdiv = "saves no modo divino",
	boot = "bootcamps"
}
translate.es = {
	hdoc = "Envía la dirección de la Documentación de Lua de Transformice",
	faq = "Muestra el tema de FAQ de una comunidad.",
	commu = "comunidad",
	happ = "Muestra el formulario de inscripción al equipo oficial de Transformice.",
	team = "nombre_equipo",
	help = "Muestra los comandos disponibles / las descripciones de los comandos.",
	info = "Muestra información genial del bot.",
	helper = "Muestra los Shades Helpers en línea en Discord.",
	dress = "Envía la dirección del aspecto de ti o de alguien. Acepta el nombre de usuario como parámetro.",
	mt = "Muestra los miembros en línea del Module Team.",
	fs = "Muestra los miembros en línea del Fashion Squad.",
	fc = "Muestra los miembros en línea del Funcorp.",
	sent = "Muestra los Centinelas en línea.",
	sh = "Muestra los Shades Helper en línea.",
	make = "Muestra como hacer un bot con Transfromage.",
	nocmd = "No se ha encontrado el comando '%s'. :s",
	hlist = "Escribe '%s nombre_comando' o ',%s nombre_comando' para saber más. Comandos Disponibles → %s",
	link = "Muestra la URL final de las URLs acortadas.",
	title = "Comprueba los siguientes títulos que usted o alguien va a desbloquear. Acepta el nombre de usuario como parámetro.",
	doc = "Documentación de Lua: %s",
	nofaq = "Esta comunidad no tiene FAQ todavía. :(",
	acommu = "Comunidades disponibles → %s",
	app = "Envía una solicitud para '%s': %s",
	noapp = "El equipo solicitado no ha sido encontrado. :(",
	ateam = "Equipos disponibles → %s",
	nohelp = "Susúrrame ',%s' para ver la lista de comandos.",
	about = "Soy un bot del servidor '%s' ( %s ), mantenido por %s. Shades Helpers es un grupo con la intención de ayudar a todos, mayormente sobre módulos, lua, y cosas técnicas.",
	nohelper = "No hay ningún Shade Helper en línea en Discord. :(",
	onhelper = "Shades Helpers en línea en Discord: %s",
	dmake = "Para crear un bot en Transformice necesitarás: - una de nuestras APIs, disponibles en Lua y en Python; - un token para que la API se conecte a Transformice; Puedes obtenerlo preguntando en nuestro servidor: %s",
	outfit = "Aspecto de %s: %s",
	onteam = "Miembros del%s en línea: %s",
	noteam = "No hay miembros del%s en línea.",
	spam = "Wow, %s; ¡Espera, cowboy! No me spamees con comandos.",
	checktitle = "%d %s para «%s»",
	notitle = "¡Usted ya tiene todos los títulos de stats! :O",
	cheese = "quesos",
	first = "firsts",
	svnormal = "salvados en modo normal",
	svhard = "salvados en modo difícil",
	svdiv = "salvados en modo divino",
	boot = "bootcamps"
}

-- Functions
do
	local err = error
	error = function(msg, lvl)
		coroutine.wrap(function()
			if lvl == transfromage.enum.errorLevel.low then
				disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, low level error.\n```\n" .. msg .. "```")
			else
				disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, disconnected with high level error.\n```\n" .. msg .. "```")
				err(msg, lvl)
			end
		end)
	end
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
		end
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

local formatServerMemberList = function(str, role)
	local title, data = string.match(str, "(.-): (.*)")
	title = title or str

	if data then
		data = string.gsub(data, "#%d+", "`%1`")
		data = string.gsub(data, ", ?", "\n")
	end

	return {
		embed = {
			color = (role and roleColors[role] or 0x36393F),
			title = title,
			description = data
		}
	}
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

local splitMsgByWord = function(user, msg, maxMsgs, countByByte)
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
		_onlineMembers = setmetatable({ state = 0, data = '', team = '' }, {
			__call = function(this, language)
				if this.state == 0 then
					return translate(language, "$noteam", this.team)
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
					return isDebugging:reply(formatServerMemberList(src._onlineMembers(playerCommunity), name))
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

-- Commands
local chatHelpSource, whisperHelpSource, memberHelpSource
local commandWrapper, chatCommand, whisperCommand, serverCommand
do
	local help = function(src, param, level, language, prefix)
		language = language or "en"
		prefix = prefix or ','

		if param then
			param = string.lower(param)
			if string.sub(param, 1, 1) == prefix then
				param = string.sub(param, 2)
			end

			local cmdList = (level == 0 and chatCommand or level == 1 and whisperCommand or (level == 2 or level == 3) and serverCommand)
			if commandWrapper[param] then
				return "'" .. prefix .. param .. "' → " .. translate(language, tostring(commandWrapper[param]))
			elseif cmdList[param] and (level ~= 3 or cmdList[param].pb) then
				return "'" .. prefix .. param .. "' → " .. translate(language, tostring(cmdList[param]))
			end
			return translate(language, "$nocmd", prefix .. param)
		end
		return translate(language, "$hlist", prefix .. "help", prefix, prefix .. table.concat(src, (" | " .. prefix)))
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
		mt = { "Module Team", "https://goo.gl/ZJcnhZ" },
		fs = { "Fashion Squad", "http://bit.ly/2I1FY4d" },
		sh = { "Shades Helper", "https://discord.gg/quch83R" }
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
	teamAliases.fashionsquad = "fs"
	teamAliases["fashion squad"] = "fs"
	teamAliases.fashion = "fs"
	-- SH
	teamAliases.helper = "sh"
	teamAliases.shades = "sh"
	teamAliases.shelper = "sh"
	teamAliases["shades helper"] = "sh"
	teamAliases["shade helper"] = "sh"

	-- Whisper, Server
	local c_mt = {
		pb = true,
		h = "$mt",
		f = createListCommand(" module_team")
	}
	local c_fs = {
		pb = true,
		h = "$fs",
		f = createListCommand(" fashion_squad")
	}
	local c_fc = {
		pb = true,
		h = "$fc",
		f = createListCommand(" funcorp")
	}
	local c_sent = {
		pb = true,
		h = "$sent",
		f = createListCommand(" sentinel")
	}
	local c_sh = {
		h = "$sh",
		f = createListCommand(" shades_helpers")
	}

	commandWrapper = { -- playerCommunity, param, target, isChatCommand
		["luadoc"] = {
			link = true,
			h = "$hdoc",
			f = function()
				return translate(playerCommunity, "$doc", "https://atelier801.com/topic?f=5&t=451587&p=1#m3")
			end
		},
		["faq"] = {
			link = true,
			h = "$faq ',faq $commu'",
			f = function(playerCommunity, param)
				if param then
					param = string.upper(param)
					return faqThread[param] or translate(playerCommunity, "$nofaq")
				else
					return translate(playerCommunity, "$acommu", table.concat(table.map(faqThread, function(_, key)
						return key
					end), " | "))
				end
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
					return translate(playerCommunity, "$ateam", table.concat(table.map(teams, function(value)
						return value[1]
					end), " | "))
				end
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
				local t = help(whisperHelpSource, parameters, 1, playerCommunity)
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["about"] = {
			h = "$info",
			f = function(playerCommunity, isDebugging, playerName)
				local t = translate(playerCommunity, "$about", "Fifty Shades of Lua", "discord.gg/quch83R", "Bolodefchoco#0000")
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["dischelpers"] = {
			h = "$helper",
			f = function(playerCommunity, isDebugging, playerName)
				local online, counter = { }, 0
				for member in settingchannel.discussion.members:findAll(function(member) return member.status ~= "offline" end) do
					if helper[member.id] then
						counter = counter + 1
						online[counter] = "[" .. helper._commu[member.id] .. "] " .. member.fullname .. " (" .. helper[member.id] .. ")"
					end
				end
				table.sort(online, function(m1, m2)
					return string.match(m1, "%b()$") < string.match(m2, "%b()$")
				end)

				local t = (#online == 0 and translate(playerCommunity, "$nohelper") or translate(playerCommunity, "$onhelper", table.concat(online, ", ")))
				if isDebugging then
					return t, true
				else
					tfm:sendWhisper(playerName, t, nil, true) -- Counts by bytes because of Blank's nickname that is handled wrong by TFM.
				end
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
				local t = translate(playerCommunity, "$dmake", "discord.gg/quch83R")
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh,
		["link"] = {
			link = true,
			h = "$link",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if not parameters then return end
				if not string.find(parameters, "^https?://") then
					parameters = "http://" .. parameters
				end

				local final

				local isLink, head = pcall(http.request, "GET", parameters)
				if isLink then
					local redir = parameters

					while head.code == 301 do
						for i = 1, #head do
							if head[i][1] == "Location" then
								redir = head[i][2]
								head = http.request("GET", redir)
								break
							end
						end
					end

					final = "The final link is: " .. redir
				else
					final = "Invalid or unavailable link."
				end

				if isDebugging then
					return final
				else
					tfm:sendWhisper(playerName, final)
				end
			end
		},
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
		}
	}
	serverCommand = { -- message. param
		["help"] = {
			pb = true,
			h = "Displays the available commands / the commands descriptions.",
			f = function(message, parameters)
				local isPb = (message.channel.category and message.channel.category.id ~= categoryId)
				message:reply((string.gsub(help((isPb and serverHelpSource or memberHelpSource), parameters, (isPb and 3 or 2), "en", '/'), '\'', '`')))
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
			h = "Displays the list of online Mapcrew.",
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
				onlinePlayer[parameters] = message.channel.id
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
		["clear"] = {
			h = "[Admin only] Clears the cache of the tables.",
			f = function(message)
				if message.author.id == disc.owner.id then
					message:reply("Clearing cache")
					xml = { queue = { } }
					onlinePlayer = { }
					for k, v in next, srcMemberListCmd do
						v._loading = ''
						v._queue = { }
						v._timer = 0
					end
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
		["rank"] = {
			h = "[Admin only] Updates the database of #bolodefchoco0ranking.",
			f = function(message)
				if message.author.id == disc.owner.id then
					local msg = message:reply("Saving leaderboard")

					-- Updates the module #bolodefchoco.ranking
					local head, body = http.request("GET", "https://club-mice.com/ranking/mice/")

					local ranking, counter, semicounter = { { } }, 1, 0
					for value in string.gmatch(body, "<td>(.-)</td>") do
						semicounter = semicounter + 1

						ranking[counter][semicounter] = string.gsub(string.gsub(string.gsub(value, " *<.->", ''), "%(.-%)", ''), ',', '')

						if semicounter == 7 then
							ranking[counter] = table.concat(ranking[counter], ']', 2)

							semicounter = 0
							counter = counter + 1
							ranking[counter] = { }
						end
					end
					ranking = table.concat(ranking, '[', 1, 100)

					-- player]values[player2]values
					tfm.bulle:send({ 29, 21 }, transfromage.byteArray:new():write32(666):writeUTF(ranking)) -- Calls eventTextAreaCallback
					msg:setContent("Leaderboard updated!")
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["mem"] = {
			h = "[Admin only] Checks the current memory usage.",
			f = function(message)
				if message.author.id == disc.owner.id then
					message:reply(tostring(collectgarbage("count")))
					collectgarbage()
					message:reply(tostring(collectgarbage("count")))
				else
					message:reply("You are not a bot admin.")
				end
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh
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

local executeCommand = function(isChatCommand, content, target, playerName, isDebugging, playerCommunity)
	local returnValue, countByByte
	local cmd, param = getCommandParameters(content)

	if param == '?' then
		param = cmd
		cmd = "help"
	end

	if commandWrapper[cmd] then
		returnValue = userAntiSpam(commandWrapper[cmd], target, playerCommunity)
		if not returnValue then -- if because "a, b = c() or d()" doesn't apply for multiple values. :s
			returnValue, countByByte = commandWrapper[cmd](playerCommunity, param, target, isChatCommand)
		end
		if returnValue then
			if isChatCommand or isDebugging then
				tfm:sendChatMessage(target, returnValue, nil, countByByte)
			else
				tfm:sendWhisper(target, returnValue, nil, countByByte)
			end
		end
		return true
	else
		if isChatCommand then
			if chatCommand[cmd] then
				returnValue = userAntiSpam(chatCommand[cmd], playerName, playerCommunity)
				if not returnValue then
					returnValue, countByByte = chatCommand[cmd](playerCommunity, target, playerName, param)
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
					returnValue, countByByte = whisperCommand[cmd](playerCommunity, isDebugging, playerName, param)
				end
				if returnValue then
					if isDebugging then
						tfm:sendChatMessage(target, returnValue, nil, countByByte)
					else
						tfm:sendWhisper(target, returnValue, nil, countByByte)
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
		return error("[Heartbeat] Failed to connect.", transfromage.enum.errorLevel.high)
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
		if param == '?' then
			param = cmd
			cmd = "help"
		end

		if serverCommand[cmd] then
			if serverCommand[cmd].pb or isMember then
				return serverCommand[cmd](message, param)
			end
		end
	end

	if not isMember then return end

	if not string.find(message.content, "^,") then return end

	local cutSlice
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

		cutSlice = tfm:sendWhisper(target, formatSendText(content), helper[message.author.id])
	else
		if message.channel.id == channel.shadestest then
			-- Whisper comes first because of ',help'
			local executed = executeCommand(false, message.content, channel(message.channel.id), helper[message.author.id], true)
			executed = executed or executeCommand(true, message.content, channel(message.channel.id), helper[message.author.id])
			if executed then return end
		end

		cutSlice = tfm:sendChatMessage(channel(message.channel.id), formatSendText(string.sub(message.content, 2)), helper[message.author.id])
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
	lastServerPing = timer.setTimeout(22 * 1000, error, "[Ping] Lost connection.", transfromage.enum.errorLevel.high)
end))

tfm:on("disconnection", protect(function(connection)
	error("[Connection] Disconnected from " .. connection.name .. ".", transfromage.enum.errorLevel[(connection.name == "main" and "high" or "low")])
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
		isWorking = true
		print("Working")
	end)
end))

tfm:on("chatMessage", protect(function(channelName, playerName, message, playerCommunity)
	if not channel[channelName] then return end
	if channelName == "whisper" then return end -- :P
	p(channelName, playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	playerCommunity = getCommunityCode(playerCommunity)
	local content = string.format("[%s] [%s] [%s] %s", os.date("%H:%M"), playerCommunity, playerName, message)
	content = formatReceiveText(content)

	object[channelName]:send(content)

	executeCommand(true, message, channelName, playerName, nil, playerCommunity)
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

	executeCommand(false, message, playerName, playerName, nil, playerCommunity)
end))

tfm:on("profileLoaded", protect(function(data)
	if dressroom[data.playerName] then
		local look = translate(dressroom[data.playerName].playerCommunity, "$outfit", data.playerName, dressroomLink(data.look))

		if dressroom[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(look))
		else
			tfm:sendWhisper(dressroom[data.playerName].playerName, look)
		end

		dressroom[data.playerName] = nil
	elseif profile[data.playerName] then
		local title, hasGender = transfromage.translation.get(transfromage.enum.language.en, "T_" .. data.titleId)
		title = (title and (hasGender and title[(data.gender % 2 + 1)] or title) or data.titleId)

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
					"\n**Current Title :** «" .. title .. "»" ..
					"\n**Adventure points :** " .. data.adventurePoints ..

					"\n\n<:shaman:512015935989612544> " .. data.saves.normal .. " / " .. data.saves.hard .. " / " .. data.saves.divine ..
					"\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. data.shamanCheese ..

					"\n\n<:racing:512016668038266890> **Firsts :** " .. data.firsts ..
					"\n<:tfm_cheese:458404666926039053> **Cheeses :** " .. data.cheeses ..
					"\n<:bootcamp:512017071031451654> **Bootcamps :** " .. data.bootcamps ..

					"\n\n<:dance:468937918115741718> **[Outfit](" .. dressroomLink(data.look) .. ")**\n\n" ..

					"<:wheel:456198795768889344> **Total titles :** " .. data.totalTitles ..
					"\n<:wheel:456198795768889344> **Total badges :** " .. data.totalBadges ..
					"\n<:wheel:456198795768889344> **Total cartouches :** " .. data.totalOrbs ..

					"\n\n<:wheel:456198795768889344> **ID :** " .. data.id
				,
				thumbnail = { url = "http://avatars.atelier801.com/" .. (data.id % 10000) .. "/" .. data.id .. ".jpg" }
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
		local title, hasGender, field, stars, skip
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
				for i = 1, #titleRequirements[field] do
					if data[field] < titleRequirements[field][i][2] then
						title, hasGender = transfromage.translation.get(transfromage.enum.language[commu], "T_" .. titleRequirements[field][i][1])
						title = (title and (hasGender and title[gender] or title) or titleRequirements[field][i][1])

						counter = counter + 1
						out[counter] = translate(commu, titleFieldsKeys[f]) 
						out[counter] = translate(commu, "$checktitle", (titleRequirements[field][i][2] - data[field]), out[counter], title .. stars)
						break
					end
				end
			end
		end

		if #out == 0 then
			out = translate(commu, "$notitle")
		else
			out = table.concat(out, " | ")
		end
		out = "'" .. data.playerName .. "': " .. out

		if checkTitles[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(out))
		else
			tfm:sendWhisper(checkTitles[data.playerName].playerName, out)
		end

		checkTitles[data.playerName] = nil
	end
end))

tfm:insertPacketListener(6, 9, protect(function(self, packet, connection, C_CC) -- Chat message from #bolodefchoco.*\3Editeur
	local text = packet:readUTF()
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
			local out, counter = { }, 0
			for k, v in next, json.decode(l._loading).members do
				if v then
					counter = counter + 1
					out[counter] = remDefaultDiscriminator(k)
				end
			end
			if #out > 0 then
				table.sort(out)
				l._onlineMembers.state = 1 -- Online
				l._onlineMembers.data = table.concat(out, ", ") -- Data is sent together (text%data) because of %u→ %l
			else
				l._onlineMembers.state = 0 -- Online
				l._onlineMembers.data = ''
			end
			l._onlineMembers.team = team
			l._loading = ''

			for i = 1, #l._queue do
				if l._queue[i].isDebugging then
					if l._queue[i].isServerCmd then
						l._queue[i].isDebugging:reply(formatServerMemberList(l._onlineMembers(), _team))
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

tfm:on("staffList", protect(function(list)
	local isMod = false
	local hasOnline = true
	local title

	list = string.gsub(list, "%$(%S+)", function(line)
		if line == "ModoEnLigne" then
			isMod = true
			title = "Online Moderators"
		elseif line == "ModoPasEnLigne" then
			isMod = true
			hasOnline = false
			title = "No Moderators online :("
		elseif line == "MapcrewEnLigne" then
			title = "Online Mapcrew"
		elseif line == "MapcrewPasEnLigne" then
			hasOnline = false
			title = "No Mapcrew online :("
		else
			title = line
		end
		return ''
	end, 1)

	if hasOnline then
		list = string.gsub(list, "<.->", '')

		list = string.gsub(list, "%[..%]", function(commu)
			return "`" .. string.upper(commu) .. "`"
		end)

		list = string.gsub(list, "#%d+", "`%1`")
	end

	local embed = {
		embed = {
			color = roleColors[(isMod and "Moderator" or "Mapcrew")],
			title = tostring(title),
			description = list
		}
	}

	for channel in next, (isMod and modList or mapcrewList) do
		disc:getChannel(channel):send(embed)
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

					local perm = (mapCategory[map.perm] or mapCategory.default)
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