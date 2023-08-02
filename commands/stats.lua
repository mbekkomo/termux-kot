local discordia = require("discordia")
local Embed = require("util/embed")

local os = require("os")
local round = discordia.extensions.math.round
local uptime = os.time()

return {
    name = "stats",
    description = "Show statistics of the bot.",
    options = {},
    cb = function(ia)
        local memory = round(process:memoryUsage().heapUsed / 1024 / 1024, 2)
        local time = discordia.Time.fromSeconds(os.time() - uptime):toString()

        local embed = Embed:new():setTitle("Bot Statistics"):setColor(0x00aaff)
        for _, v in ipairs {
            { "Uptime", time },
            { "Memory Usage", memory .. " MB" },
            { "Operating System", jit.os },
            { "Architecture", jit.arch },
            { "Luvit version", require("bundle:/package.lua").version },
            { "Luvi version", require("luvi").version },
            { "LuaJIT version", jit.version },
            { "Discordia version", discordia.package.version },
        } do
            embed:addField {
                name = v[1],
                value = v[2],
                inline = true,
            }
        end

        ia:reply {
            embed = embed:returnEmbed(),
        }
    end,
}
