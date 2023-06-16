local slash_tools = require("discordia-slash").util.tools()
---@type Embed
local Embed = require("util/embed")
---@type DiscordRequest
local DiscordRequest = require("util/discord-request")

local json = require("json")
local uri_patt = require("lpeg_patterns/uri")

return {
    name = "showcase",
    description = "Create a showcase post.",
    options = {
        slash_tools.string("title", "Title of your creation.")
            :setRequired(true),
        slash_tools.string("description", "Description of your creation.")
            :setRequired(true),
        slash_tools.string("source", "Source to your creation.")
            :setRequired(false),
    },
    cb = function(ia, args, config)
        local showcase_chann = "1118815871276687522"
        if ia.channelId ~= showcase_chann then
            ia:reply(("You need to run this command in <#%s> channel!"):format(showcase_chann), true)
            return
        end

        local embed_obj = Embed:new()
            :setTitle(args.title)
            :setTimestamp(require("discordia").Date():toISO("T", "Z"))
            :setAuthor({
                name = ia.member.user.username .. "#" .. ia.member.user.discriminator,
                icon_url = ia.member.user.avatarURL
            })
            :setColor(0x00aaff)

        if args.description then
            embed_obj:setDescription(args.description)
        end

        if args.source then
            if not uri_patt.uri:match(args.source) then
                ia:reply(("Invalid URI: `%s`"):format(args.source), true)
                return
            end
            embed_obj:addField({
                name = "Source",
                value = args.source
            })
            embed_obj:setUrl(args.source)
        end

        ---@type Message
        local msg = ia.channel:send({
            embed = embed_obj:returnEmbed()
        })

        local body = json.encode({
            name = args.title
        })

        DiscordRequest:new(config.token, 9)
            :request("POST", ("/channels/%s/messages/%s/threads"):format(ia.channelId, msg.id), {}, {
                { "Content-Length", tostring(#body) },
                { "Content-Type", "application/json" }
            }, body)

        ia:reply("Successfully created the message, you can now close this.", true)
    end
}
