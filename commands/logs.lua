local Embed = require("util/embed")
local slash_tools = require("discordia-slash").util.tools()

local fs = require("fs")

return {
	internal = true,
	owner_only = true,
	name = "logs",
	description = "Retrieve log from 'discordia.log'.",
	options = {
		slash_tools.integer("from_line", "Start line of reading the log file."):setRequired(false),
		slash_tools.integer("to_line", "End line of reading the log file."):setRequired(false),
	},
	cb = function(ia, args)
		local content_lines = fs.readFileSync("discordia.log"):split("\n")

		args.from_line = args.from_line or 1
		args.to_line = args.to_line or #content_lines

		local concat_lines = table.concat(content_lines, "\n", args.from_line, args.to_line)

		local embed = Embed:new():setTitle("Logs"):setColor(0x00aaff)

		if #concat_lines > 2000 then
			embed:setDescription(
				"```"
					.. (args.from_line > 1 and "...\n" or "")
					.. table.concat(content_lines, "\n", args.from_line, args.from_line + 10)
					.. (args.to_line > (args.from_line + 10) and "\n..." or "")
					.. "```"
			)
			ia:reply({
				embed = embed:returnEmbed(),
				file = "discordia.log",
			})
		else
			embed:setDescription("```" .. concat_lines .. "```")
			ia:reply({
				embed = embed:returnEmbed(),
			})
		end
	end,
}
