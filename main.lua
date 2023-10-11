local timer = require("timer")
local fs = require("fs")
local json = require("json")

local lpeg = require("lpeg")
local patt_uri = require("lpeg_patterns/uri")

local config = assert(require("./config.lua"), "cannot find config.lua!")
local status = assert(require("./status.lua"), "cannot find status.json!")

---@type discordia
local discordia = require("discordia")
local slash_tools = require("discordia-slash").util.tools()
local Embed = require("util/embed")
---@module 'libs.util.discord-request'
local DR = require("util/discord-request")
local ext = discordia.extensions
ext.string()

---@diagnostic disable-next-line:need-check-nil
local api = DR:new(config.token, 9)

local function dict_length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---@diagnostic disable-next-line:undefined-field
local client = discordia.Client():useApplicationCommands()
---@diagnostic disable-next-line:undefined-field
client:enableIntents(discordia.enums.gatewayIntent.messageContent)

local env = setmetatable({ require = require }, { __index = _G })

local cmds = {}
for path in fs.scandirSync("commands") do
    ---@diagnostic disable-next-line:param-type-mismatch
    local cmd, err = load(assert(fs.readFileSync("commands/" .. path)), "@commands/" .. path, "t", env)

    if cmd and not err then
        local cmd_obj = cmd()
        cmd_obj.description = cmd_obj.owner_only and cmd_obj.description .. " (Owner only)" or cmd_obj.description

        cmds[#cmds + 1] = cmd_obj
        client:info("Command loaded: %s", cmd_obj.name)
    else
        client:error("Failed to load Lua file: %s", path)
        client:error(err or "")
    end
end

-----------------------------------------------------------------
---@cast client Client
---@diagnostic disable:need-check-nil
---@diagnostic disable:undefined-field

local showcase_chann = config.dev and "1118815871276687522" or "712954974983684137"
local modlogs_chann = "810521091973840957"
local whitelist_role = {
    "977060375180738570",
    "804014473080864829",
    "650683641936084993",
}

local embed_color = 0x00aaff

local function verify_message(msg)
    return not (
        msg.content:find("```.+```")
        or msg.attachment
        or lpeg.P({ patt_uri.uri + 1 * lpeg.V(1) }):match(msg.content)
    )
end

local function make_thread(msg, username)
    client:info("Created thread for %s", username)
    client:info("User: %s", msg.author.id)
    client:info("Thread/Message: %s", msg.id)

    local body = json.encode {
        name = username .. "'s thread post",
    }

    api:request("POST", ("/channels/%s/messages/%s/threads"):format(msg.channel.id, msg.id), {}, {
        { "Content-Length", tostring(#body) },
        { "Content-Type", "application/json" },
    }, body)

    ---@diagnostic disable-next-line:redundant-parameter
    local modlogs_textchann = msg.guild.textChannels:find(function(c)
        ---@diagnostic disable-next-line:redundant-return-value
        return c.id == modlogs_chann
    end)
    ---@cast modlogs_textchann TextChannel

    local embed = Embed:new()
        :setAuthor({
            name = username,
            icon_url = msg.author.avatarURL,
        })
        :setFooter({
            text = ("User: %s | Thread/Message: %s"):format(msg.author.id, msg.id),
        })
        :setDescription(
            ("**Created thread for <@%s>!**\nhttps://discord.com/channels/%s/%s/%s"):format(
                msg.author.id,
                msg.guild.id,
                msg.channel.id,
                msg.id
            )
        )
        :setColor(embed_color)
        :setTimestamp(discordia.Date():toISO("T", "Z"))

    modlogs_textchann:send {
        embed = embed:returnEmbed(),
    }
end

local function filter_message(msg, username)
    msg:delete()
    client:info("Caught %s's message!", username)
    client:info("Author: %s", msg.author.id)
    client:info("Message content: %s", msg.content)
    local bot_msg = msg:reply(("Send message into the post thread <@%s>! >:3"):format(msg.author.id))
    timer.setTimeout(3000, function()
        coroutine.wrap(bot_msg.delete)(bot_msg)
    end)

    ---@diagnostic disable-next-line:redundant-parameter
    local modlogs_textchann = msg.guild.textChannels:find(function(c)
        ---@diagnostic disable-next-line:redundant-return-value
        return c.id == modlogs_chann
    end)
    ---@cast modlogs_textchann TextChannel

    local embed = Embed:new()
        :setAuthor({
            name = username,
            icon_url = msg.author.avatarURL,
        })
        :setFooter({
            text = "Author: " .. msg.author.id,
        })
        :setDescription(("**Caught <@%s>'s message!**\n%s"):format(msg.author.id, msg.content))
        :setColor(embed_color)
        :setTimestamp(discordia.Date():toISO("T", "Z"))

    modlogs_textchann:send {
        embed = embed:returnEmbed(),
    }
end

cmds[#cmds + 1] = {
    name = "help",
    description = "Show list of commands.",
    options = {
        slash_tools.boolean("internal", "Display internal commands."):setRequired(false),
    },
    cb = function(ia, args)
        local embed = Embed:new():setTitle("Help"):setDescription("List of all commands."):setColor(embed_color)

        for _, v in ipairs(cmds) do
            if not v.internal or v.internal and args.internal then
                embed:addField {
                    name = v.name,
                    value = v.description,
                    inline = true,
                }
            end
        end

        ia:reply {
            embed = embed:returnEmbed(),
        }
    end,
}

cmds[#cmds + 1] = {
    internal = true,
    owner_only = true,
    name = "shutdown",
    description = "Shutdown the bot completely. (Owner only)",
    options = {},
    cb = function(ia)
        ia:reply("Successfully shutdown the bot.")
        client:stop()
        os.exit(0, true)
    end,
}

local function catch_err(ia, err)
    local pp = require("pretty-print")

    if err then
        ia:reply(("**ERROR**\n```\n%s```"):format(pp.strip(pp.dump(err))))
        return true
    end
end

cmds[#cmds + 1] = {
    internal = true,
    owner_only = true,
    name = "update",
    description = "Fetch and pull commits to local repo. (Owner only)",
    options = {
        slash_tools.boolean("rebase", "Rebase instead fast-forward."):setRequired(false),
    },
    cb = function(ia, args)
        ia:replyDeferred()

        local cp = require("childprocess")
        cp.exec(
            "git pull --" .. (args.rebase and "rebase" or "no-rebase"),
            coroutine.wrap(function(err, stdout, stderr)
                if catch_err(ia, err) then
                    return
                end
                ia:reply(("**STDOUT**\n```\n%s```\n**STDERR**\n```\n%s```"):format(stdout, stderr))
            end)
        )
    end,
}

table.sort(cmds, function(a, b)
    return b.owner_only and not a.owner_only
end)

client:on("ready", function()
    client:info("Purr~... Watching messages in the server :3")

    math.randomseed(os.time())
    client:setActivity(status[math.random(#status)])
    timer.setInterval(120 * 1000, function()
        math.randomseed(os.time())
        coroutine.wrap(client.setActivity)(client, status[math.random(#status)])
    end)

    local commands = client:getGlobalApplicationCommands()
    if dict_length(commands) ~= #cmds then
        client:info("Cleaning cached commands")
        for cmdid in pairs(commands) do
            client:deleteGlobalApplicationCommand(cmdid)
        end
    end

    for _, cmd_obj in pairs(cmds) do
        local slash_cmd = slash_tools.slashCommand(cmd_obj.name, cmd_obj.description)
        for _, option in pairs(cmd_obj.options) do
            slash_cmd:addOption(option)
        end
        client:createGlobalApplicationCommand(slash_cmd)
    end
end)

---@diagnostic disable-next-line:redundant-parameter
client:on("slashCommand", function(ia, cmd, args)
    for _, cmd_obj in pairs(cmds) do
        if cmd_obj.name == cmd.name then
            if cmd_obj.owner_only and ia.user.id ~= config.ownerid then
                break
            end
            client:info(
                "%s ran /%s command",
                ia.user.username
                    .. (
                        (tostring(ia.user.discriminator) == "0" or not ia.user.discriminator) and ""
                        or "#" .. ia.user.discriminator
                    ),
                cmd.name
            )
            client:info("User: %s", ia.user.id)
            cmd_obj.cb(ia, args or {}, config)
        end
    end
end)

client:on("messageCreate", function(msg)
    local username = msg.author.username
        .. (
            (tostring(msg.author.discriminator) == "0" or not msg.author.discriminator) and ""
            or "#" .. msg.author.discriminator
        )
    ---@diagnostic disable-next-line:redundant-parameter
    local a_maxwell = msg.guild.emojis:find(function(e)
        ---@diagnostic disable-next-line:redundant-return-value
        return e.name == "Maxwell"
    end)

    ---@diagnostic disable-next-line:redundant-parameter
    if
        msg.mentionedUsers:find(function(m)
            ---@diagnostic disable-next-line:redundant-return-value
            return m.id == client.user.id
        end)
    then
        client:info("Sending Kot to %s!", username)
        msg:addReaction(a_maxwell)
    end
end)

client:on("messageCreate", function(msg)
    local username = msg.author.username
        .. (
            (tostring(msg.author.discriminator) == "0" or not msg.author.discriminator) and ""
            or "#" .. msg.author.discriminator
        )
    local has_no_thread = msg.content:match("||no thread||$") ~= nil

    if msg.author.bot or msg.channel.id ~= showcase_chann then
        return
    end

    if verify_message(msg) then
        for _, id in pairs(whitelist_role) do
            if (config.dev and msg.content:match("^%$test")) or msg.member.roles:get(id) then
                return
            end
        end

        filter_message(msg, username)
    elseif not has_no_thread then
        make_thread(msg, username)
    end
end)

client:on("messageUpdate", function(msg)
    local username = msg.author.username
        .. (
            (tostring(msg.author.discriminator) == "0" or not msg.author.discriminator) and ""
            or "#" .. msg.author.discriminator
        )
    local has_no_thread = msg.content:match("||no thread||$") ~= nil

    if msg.author.bot or msg.channel.id ~= showcase_chann then
        return
    end

    if verify_message(msg) then
        for _, id in pairs(whitelist_role) do
            if (config.dev and msg.content:match("^%$test")) or msg.member.roles:get(id) then
                return
            end
        end

        filter_message(msg, username)
    else
        if has_no_thread and api:request("GET", ("/channels/%s"):format(msg.id), {}) ~= 404 then
            client:info("Deleted %s's thread", username)
            client:info("User: ", msg.author.id)
            client:info("Thread/Message: %s", msg.id)
            api:request("DELETE", ("/channels/%s"):format(msg.id), {})
        elseif not has_no_thread then
            make_thread(msg, username)
        end
    end
end)

client:run("Bot " .. config.token)
