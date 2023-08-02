---@type Embed
local Embed = require("util/embed")

local cohttp = require("coro-http")
local json = require("json")

return {
    name = "cat",
    description = "Get random cat image.",
    options = {},
    cb = function(ia)
        local res, body = cohttp.request("GET", "https://api.thecatapi.com/v1/images/search")

        if res.code ~= 200 then
            ia:reply(("Failed to GET: %d %s"):format(res.code, res.reason), true)
            return
        end

        local cat_obj = assert(json.decode(body))
        local a_maxwell = ia.guild.emojis:find(function(e)
            return e.name == "Maxwell"
        end)

        local embed = Embed:new()
            :setTitle("Cat")
            :setDescription(("Here's your cat image <a:Maxwell:%s>"):format(a_maxwell.id))
            :setImage({
                url = cat_obj[1].url,
            })
            :setColor(0x00aaff)

        ia:reply {
            embed = embed:returnEmbed(),
        }
    end,
}
