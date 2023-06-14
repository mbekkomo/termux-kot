local fs = require("fs")
local slash_tools = require("discordia-slash").util.tools()

return {
    internal = true,
    owner_only = true,
    name = "logs",
    description = "Retrieve log from 'discordia.log'.",
    options = {
        slash_tools.integer("from_line", "Start line of reading the log file.")
            :setRequired(false),
        slash_tools.integer("to_line", "End line of reading the log file.")
            :setRequired(false)
    },
    cb = function(ia, args)
        local content_lines = fs.readFileSync("discordia.log"):split("\n")

        args.from_line = args.from_line or 1
        args.to_line = args.to_line or #content_lines

        local concat_lines = table.concat(content_lines, "\n", args.from_line, args.to_line)

        if #concat_lines > 2000 then
            ia:reply({
                content = (args.from_line > 1 and "...\n" or "")..
                    table.concat(content_lines, "\n", args.from_line, args.from_line + 10)..
                    (args.to_line > (args.from_line + 10) and "\n..." or ""),
                code = "txt",
                file = "discordia.log"
            })
        else
            ia:reply({
                content = concat_lines,
                code = "txt"
            })
        end
    end
}
