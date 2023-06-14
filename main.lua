local timer = require("timer")
local fs = require("fs")
local json = require("json")

local lpeg = require("lpeg")
local patt_uri = require("lpeg_patterns.uri")

local config = json.decode((assert(fs.readFileSync("config.json"), "cannot find config.json!")))
local status = json.decode((assert(fs.readFileSync("status.json"), "cannot find status.json!")))

---@type discordia
local discordia = require("discordia")
local discordia_ext = require("discordia").extensions
discordia_ext.string()

local client = discordia.Client()
---@diagnostic disable-next-line:undefined-field -- discordia meta doesn't support 2.11.0
client:enableIntents(discordia.enums.gatewayIntent.messageContent)

local env = setmetatable({ require = require }, { __index = _G })

local cmds = {}
for path in fs.scandirSync("commands") do
	---@diagnostic disable-next-line:param-type-mismatch
	local cmd, err = load(assert(fs.readFileSync("commands/" .. path)), "@commands/" .. path, "t", env)

	if cmd and not err then
		cmds[#cmds + 1] = cmd()
		client:info("Loaded successfully: %s", path)
	else
		client:error("Failed to load: %s", path)
		client:error(err or "")
	end
end

cmds[#cmds + 1] = {
	name = "help",
	description = "Show this message about usage of commands.",
	cb = function(msg, args)
		local cmd_helpstr = ""

		for _, v in ipairs(cmds) do
			if not v.internal or v.internal and (args[1] or ""):find("^[Yy]") then
				cmd_helpstr = cmd_helpstr .. ("%-7s \27[34m.. %s\27[0m\n"):format(v.name, v.description)
			end
		end

		msg:reply({
			content = ("\
\27[31m:: Commands ::\27[0m\n\
%s"):format(cmd_helpstr),
			code = "ansi",
			reference = {
				message = msg,
				mention = false,
			},
		})
	end,
}

---------------------------------------------------------------------------------

---@diagnostic disable:need-check-nil
client:on("ready", function()
	client:info("Purr~... Watching messages in the server :3")

	math.randomseed(os.time())
	client:setActivity(status[math.random(#status)]) ---@diagnostic disable-line:undefined-field
	timer.setInterval(60 * 1000, function()
		math.randomseed(os.time())
		coroutine.wrap(client.setActivity)(client, status[math.random(#status)]) ---@diagnostic disable-line:undefined-field
	end)
end)

client:once("error", function(errmsg)
	client:error("Hiss! An error has occured! >:(")
	client:error(errmsg)
end)

local prefix = "-"
local blacklist_chann = {
	["712954974983684137"] = true,
}

client:on("messageCreate", function(msg)
	if msg.author.bot then
		return
	end

	local showcase_chann = "712954974983684137"

	if msg.channel.id == showcase_chann and not (msg.content:find("```.+```") or msg.attachment) then
		for sub_s in msg.content:gmatch("([^ \n]+)") do
			if lpeg.P({ patt_uri.uri + 1 * lpeg.V(1) }):match(sub_s) then
				return
			end
		end

		msg:delete()
		client:info("Catched %s's message!", msg.author.username)

		local bot_msg = msg:reply({
			content = "Please open a thread and talk there meow x3",
			mention = msg.author,
		})
		timer.sleep(3000)
		bot_msg:delete()
		return
	end

	if msg.content:sub(1, 1) == prefix then
		local cmdstr = msg.content:match(prefix .. "(%S+)")
		local cmdargs = msg.content:split(" ")
		table.remove(cmdargs, 1)
		client:info("%s requested -%s", msg.author.username, cmdstr)

		for _, cmd in ipairs(cmds) do
			if cmd.name == cmdstr and not blacklist_chann[msg.channel.id] then
				cmd.cb(msg, cmdargs, config)
			end
		end
	end
end)

client:run("Bot " .. config.token)
