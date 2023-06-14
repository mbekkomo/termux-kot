local discordia = require("discordia")
local os = require("os")
local round = discordia.extensions.math.round
local uptime = os.time()

return {
	name = "stats",
	description = "Show statistics of the bot.",
	cb = function(msg)
		local memory = round(process:memoryUsage().heapUsed / 1024 / 1024, 2)
		local time = discordia.Time.fromSeconds(os.time() - uptime):toString()

		msg:reply({
			content = ("\
\27[31m:: Bot Statistics ::\27[0m\
\
• Uptime            \27[34m.. %s\27[0m\
• Memory Usage      \27[34m.. %s MB\27[0m\
• Operating System  \27[34m.. %s\27[0m\
• Architecture      \27[34m.. %s\27[0m\
• Luvi version      \27[34m.. %s\27[0m\
• LuaJIT version    \27[34m.. %s\27[0m\
• Discordia version \27[34m.. %s\27[0m"):format(
				time,
				memory,
				jit.os,
				jit.arch,
				require("luvi").version,
				jit.version,
				discordia.package.version
			),
			code = "ansi",
			reference = {
				message = msg,
				mention = false,
			},
		})
	end,
}
